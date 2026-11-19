{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @website(https://www.gladir.com/networkkitp)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application Outlink en mode graphique

  ============================================================================
                         TODO - CLONE OUTLOOK EN PASCAL
  ============================================================================

  1.  [x] Interface graphique principale (fenetre principale VGA/SVGA)
      - Creer la fenetre principale avec barre de titre "Outlook"
      - Implementer les zones: menu, barre d'outils, panneau de navigation,
        liste des messages, volet de lecture
      - Gerer le redimensionnement des panneaux avec la souris

  2.  [x] Support complet de la souris (Turbo Pascal et Free Pascal)
      - Detecter et initialiser le pilote souris (INT 33h pour TP)
      - Utiliser PtcMouse pour Free Pascal
      - Gestion des evenements: clic gauche, clic droit, double-clic,
        glisser-deposer, molette de defilement

  3.  [x] Systeme de menus deroulants graphiques
      - Menu Fichier: Nouveau, Ouvrir, Enregistrer, Imprimer, Quitter
      - Menu Edition: Couper, Copier, Coller, Selectionner tout
      - Menu Affichage: Volet de lecture, Trier par, Colonnes
      - Menu Outils: Comptes, Options, Regles de messages
      - Menu Aide: A propos, Aide en ligne

  4.  [x] Barre d'outils graphique avec icones
      - Icones: Nouveau message, Repondre, Repondre a tous, Transferer
      - Icones: Envoyer/Recevoir, Supprimer, Imprimer, Carnet d'adresses
      - Etats visuels: normal, survol, appuye, desactive
      - Infobulles au survol de la souris

  5.  [x] Arbre de navigation multi-comptes (panneau gauche)
      - Structure hierarchique: Comptes -> Dossiers -> Sous-dossiers
      - Dossiers standards: Boite de reception, Elements envoyes,
        Brouillons, Elements supprimes, Courrier indesirable
      - Compteur de messages non lus entre parentheses
      - Icones de dossiers personnalisees
      - Glisser-deposer pour deplacer les messages entre dossiers

  6.  [x] Liste des messages avec colonnes triables
      - Colonnes: De, Objet, Date, Taille, Pieces jointes, Priorite
      - Tri ascendant/descendant par clic sur l'en-tete de colonne
      - Indicateurs visuels: lu/non lu (gras), drapeau, priorite haute/basse
      - Selection multiple avec Ctrl+clic et Shift+clic
      - Menu contextuel au clic droit

  7.  [x] Volet de previsualisation des messages
      - Affichage des en-tetes: De, A, Cc, Objet, Date
      - Zone de contenu avec defilement vertical et horizontal
      - Basculer entre affichage horizontal et vertical
      - Option pour masquer/afficher le volet de previsualisation

  8.  [x] Client IMAP complet (RFC 3501)
      - Connexion securisee TLS/SSL sur le port 993
      - Authentification LOGIN et PLAIN
      - Commandes: SELECT, EXAMINE, FETCH, STORE, COPY, UID
      - Synchronisation des dossiers et messages
      - Support IDLE pour les notifications push
      - Gestion des drapeaux: \Seen, \Answered, \Flagged, \Deleted, \Draft

  9.  [x] Client POP3 complet (RFC 1939)
      - Connexion securisee TLS/SSL sur le port 995
      - Authentification USER/PASS et APOP
      - Commandes: STAT, LIST, RETR, DELE, TOP, UIDL
      - Option: Laisser les messages sur le serveur
      - Telechargement des en-tetes seulement ou messages complets

  10. [x] Client SMTP complet (RFC 5321)
      - Connexion securisee TLS/SSL sur le port 465/587
      - Authentification PLAIN, LOGIN et CRAM-MD5
      - Support STARTTLS pour les connexions non chiffrees
      - Commandes: EHLO, MAIL FROM, RCPT TO, DATA, QUIT
      - Gestion des erreurs et codes de retour SMTP

  11. [x] Gestionnaire de comptes de messagerie
      - Assistant de configuration de nouveau compte
      - Parametres serveur entrant: IMAP/POP3, hote, port, SSL/TLS
      - Parametres serveur sortant: SMTP, hote, port, authentification
      - Test de connexion automatique
      - Stockage securise des mots de passe

  12. [x] Compositeur de messages graphique
      - Fenetre de redaction avec champs A, Cc, Cci, Objet
      - Zone d'edition de texte avec curseur clignotant
      - Formatage de base: gras, italique, souligne, couleur
      - Verification orthographique integree
      - Boutons: Envoyer, Enregistrer brouillon, Annuler

  13. [x] Support des pieces jointes
      - Ajouter des fichiers depuis le systeme de fichiers
      - Afficher les pieces jointes avec icones par type
      - Enregistrer les pieces jointes sur disque
      - Limite de taille configurable
      - Avertissement pour les extensions dangereuses

  14. [x] Moteur de rendu HTML pour courriels (HTMLRenderer)
      - Analyse et tokenisation du HTML (lexer/parser)
      - Support des balises: html, body, head, title, meta
      - Balises de structure: div, span, p, br, hr
      - Balises de formatage: b, i, u, strong, em, font
      - Balises de listes: ul, ol, li
      - Balises de tableaux: table, tr, td, th
      - Balises de liens: a (href), affichage souligne en bleu
      - Balises d'images: img (affichage placeholder ou telechargement)
      - Support du CSS inline (style="...")
      - Attributs: align, color, bgcolor, width, height, border

  15. [x] Decodage MIME multi-parties (RFC 2045-2049)
      - Detection du Content-Type et des limites
      - Decodage Base64 pour les pieces jointes
      - Decodage Quoted-Printable pour le texte
      - Support des jeux de caracteres: UTF-8, ISO-8859-1, Windows-1252
      - Gestion multipart/alternative (texte + HTML)
      - Gestion multipart/mixed (texte + pieces jointes)

  16. [x] Carnet d'adresses integre
      - Fenetre de gestion des contacts
      - Champs: Nom, Prenom, Courriel, Telephone, Adresse
      - Recherche et filtrage des contacts
      - Import/Export au format vCard et CSV
      - Auto-completion dans les champs A, Cc, Cci

  17. [x] Systeme de regles de filtrage des messages
      - Conditions: Expediteur, Objet, Corps, Taille, Date
      - Actions: Deplacer vers dossier, Marquer comme lu, Supprimer
      - Actions: Transferer, Repondre automatiquement
      - Ordre d'execution des regles configurable
      - Activation/desactivation des regles individuelles

  18. [x] Fonctionnalites de recherche avancee
      - Recherche dans: Objet, Corps, Expediteur, Destinataire
      - Filtres: Plage de dates, Taille, Avec pieces jointes
      - Recherche dans tous les dossiers ou dossier actuel
      - Mise en surbrillance des resultats
      - Historique des recherches recentes

  19. [x] Gestion des signatures de courriels
      - Editeur de signatures multiples
      - Signature par defaut par compte
      - Insertion automatique dans les nouveaux messages
      - Support du texte formate et images
      - Signature differente pour reponses/transferts

  20. [x] Notifications et alertes de nouveaux messages
      - Verification automatique a intervalle configurable
      - Alerte sonore parametrable (fichier WAV)
      - Notification visuelle dans la barre de titre
      - Icone de la barre d'etat systeme (si disponible)
      - Option de notification par dossier

  21. [x] Impression des messages et apercu avant impression
      - Fenetre d'apercu avant impression
      - Configuration des marges et en-tetes/pieds de page
      - Impression du message actuel ou selection
      - Support des imprimantes DOS (LPT1, LPT2)
      - Export en fichier texte ou HTML

  22. [x] Sauvegarde et export des messages
      - Export au format EML (RFC 822)
      - Export au format MBOX (Unix mailbox)
      - Sauvegarde complete des comptes et parametres
      - Restauration depuis une sauvegarde
      - Export de la liste des contacts

  23. [x] Configuration des preferences utilisateur
      - Onglet General: Langue, dossier par defaut, demarrage
      - Onglet Lecture: Police, taille, codage par defaut
      - Onglet Redaction: Format par defaut, correcteur, signature
      - Onglet Connexion: Delais, tentatives, mode hors ligne
      - Onglet Securite: Avertissements, blocage d'images externes

  24. [x] Mode hors ligne et synchronisation
      - Detection automatique de la connectivite
      - File d'attente des messages a envoyer
      - Cache local des messages et dossiers
      - Synchronisation a la reconnexion
      - Indicateur visuel du mode en ligne/hors ligne

  25. [x] Support multi-langue de l'interface
      - Francais (par defaut), English, Deutsch, Italiano
      - Espanol, Portugues, Svenska, Dansk, Nihongo (en r?maji)
      - Albanais (Shqip)
      - Fichiers de ressources de traduction externes
      - Detection automatique via variable LANGUAGE

  ============================================================================
                              ARCHITECTURE TECHNIQUE
  ============================================================================

  Unites Pascal requises:
  - Free Pascal: Crt, PtcGraph, PtcCrt, PtcMouse
  - Turbo Pascal: Crt, Graph, DOS
  - Fonctions utilitaires et declarations des API integrees au programme

  Structure des donnees principales:
  - TOutlookAccount: Configuration d'un compte de messagerie
  - TMailFolder: Representation d'un dossier (Inbox, Sent, etc.)
  - TMailMessage: Structure complete d'un message avec en-tetes et corps
  - TContact: Entree du carnet d'adresses
  - TFilterRule: Regle de filtrage automatique
  - THTMLElement: N?ud de l'arbre de rendu HTML

  Protocoles reseau:
  - Socket TCP/IP de base pour toutes les communications
  - Couche TLS/SSL pour les connexions securisees
  - Implementation IMAP4rev1 avec extensions
  - Implementation POP3 avec commandes optionnelles
  - Implementation SMTP avec ESMTP et authentification

  Rendu graphique:
  - Double buffering pour eviter le scintillement
  - Systeme de fenetres superposees avec focus
  - Police bitmap integree pour le rendu de texte
  - Palette de couleurs Windows 95/98 pour l'apparence

  ============================================================================
}

Program OUTLINK;

{$R-,S-}


{ ====================================================================== }
{        OS/2-0 : PRESENTATION MANAGER, GRAPH, CRT ET SOURIS EMULES        }
{ ====================================================================== }
{ La version DOS dessine avec l'unite Graph du BGI, lit la souris par    }
{ l'interruption 33h et le clavier par Crt, dans sa boucle d'evenements.  }
{ Ici :                                                                   }
{  - le dessin va dans une image en memoire (un octet par point, couleurs }
{    du BGI) de la taille de la zone client, montree par GpiDrawBits      }
{    (zones modifiees seulement) ; la barre de titre et la barre de menus }
{    dessinees par Outlink sont remplacees par celles de PM ;             }
{  - GetMouseState, KeyPressed, ReadKey et Delay vident la file de        }
{    messages de PM (WinPeekMsg) : souris (WM_BUTTON*, WM_MOUSEMOVE),     }
{    touches (WM_CHAR, en codes du BIOS) et commandes des menus de PM ;   }
{  - le reseau (IMAP, POP3, SMTP) passe par TCPIP32.DLL (sockets d'OS/2)  }
{    et TLS32.DLL (TLS 1.2 et 1.3, aussi pour STARTTLS).                  }

Type
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

{ --- TCPIP32.DLL (sockets d'OS/2) et TLS32.DLL --- }
Function OsSockInit : LongInt; External 'TCPIP32' Name 'sock_init';
Function OsSocket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function OsConnect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function OsSend(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function OsRecv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function OsSoClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function OsGetHostByName(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function OsTlsOpen(S, PHost : LongInt) : LongInt; External 'TLS32' Name 'TLSOPEN';
Function OsTlsSend(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSSEND';
Function OsTlsRecv(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSRECV';
Function OsTlsClose(H : LongInt) : LongInt; External 'TLS32' Name 'TLSCLOSE';
Function OsTlsError(B, Cb : LongInt) : LongInt; External 'TLS32' Name 'TLSERROR';

Const
 WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_CLOSE = $0029;
 WM_QUIT = $002A; WM_INITMENU = $0033; WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071;
 WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075;
 WM_BUTTON2DBLCLK = $0076; WM_CHAR = $007A;
 FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
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
 OsKeyMax = 128; OsCmdMax = 16;
 OS_MENUID = 9000;                     { identifiants des commandes : OS_MENUID + ItemID }

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
 OsHab, OsHmq, OsFrame, OsClient, OsDummy : LongInt;
 OsW, OsH : LongInt;                       { taille de l'image (zone client) }
 OsFb : PFbArr;                            { image, lignes de bas en haut }
 OsBmi : Array[0..16 + 256 * 4 - 1] Of Byte;
 OsDX1, OsDY1, OsDX2, OsDY2 : LongInt;     { zone modifiee }
 OsColor, OsFillColor, OsFillStyle, OsThick : LongInt;
 OsVX1, OsVY1, OsVX2, OsVY2 : LongInt;     { fenetre de dessin (SetViewPort) }
 OsClip : Boolean;
 { souris : etat, boutons relaches avant d'avoir ete vus }
 OsMX, OsMY, OsMB, OsPendUp, OsSeen : LongInt;
 OsKeys : Array[0..OsKeyMax - 1] Of Byte;  { file de touches (0 + code etendu) }
 OsKHead, OsKTail : LongInt;
 OsCmds : Array[0..OsCmdMax - 1] Of LongInt;
 OsCHead, OsCTail : LongInt;
 OsQuit : Boolean;
 OsZ, OsZ2 : Array[0..1023] Of Byte;
 OsTxt : Array[0..4095] Of Byte;
 OsMenuT : Array[0..16383] Of Byte;
 OsMenuLen, OsMenuSig : LongInt;
 OsQmsg : Array[0..7] Of LongInt;
 OsTitle : String;
 OsNetReady : Boolean;
 RandSeed : LongInt;

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

Function OsRdL(A : LongInt) : LongInt;
Begin
 OsRdL := OsPkB(A) Or (OsPkB(A + 1) Shl 8) Or (OsPkB(A + 2) Shl 16) Or (OsPkB(A + 3) Shl 24);
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

{ --- image et zone modifiee (coordonnees de l'ecran) --- }

Procedure OsTouch(X1, Y1, X2, Y2 : LongInt);
Begin
 If X1 < 0 Then X1 := 0;
 If Y1 < 0 Then Y1 := 0;
 If X2 > OsW - 1 Then X2 := OsW - 1;
 If Y2 > OsH - 1 Then Y2 := OsH - 1;
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 If OsDX1 < 0 Then
 Begin
  OsDX1 := X1; OsDY1 := Y1; OsDX2 := X2; OsDY2 := Y2;
 End
 Else
 Begin
  If X1 < OsDX1 Then OsDX1 := X1;
  If Y1 < OsDY1 Then OsDY1 := Y1;
  If X2 > OsDX2 Then OsDX2 := X2;
  If Y2 > OsDY2 Then OsDY2 := Y2;
 End;
End;

{ point dans la fenetre de dessin (origine et decoupage de SetViewPort) }
Procedure OsPlot(X, Y, C : LongInt);
Begin
 X := X + OsVX1; Y := Y + OsVY1;
 If OsClip Then
  If (X < OsVX1) Or (X > OsVX2) Or (Y < OsVY1) Or (Y > OsVY2) Then Exit;
 If (X < 0) Or (Y < 0) Or (X >= OsW) Or (Y >= OsH) Then Exit;
 OsFb^[(OsH - 1 - Y) * OsW + X] := C And 15;
End;

Procedure OsSpan(X1, X2, Y, C : LongInt);
Var A, X : LongInt;
Begin
 X1 := X1 + OsVX1; X2 := X2 + OsVX1; Y := Y + OsVY1;
 If OsClip Then
 Begin
  If (Y < OsVY1) Or (Y > OsVY2) Then Exit;
  If X1 < OsVX1 Then X1 := OsVX1;
  If X2 > OsVX2 Then X2 := OsVX2;
 End;
 If (Y < 0) Or (Y >= OsH) Then Exit;
 If X1 < 0 Then X1 := 0;
 If X2 > OsW - 1 Then X2 := OsW - 1;
 If X2 < X1 Then Exit;
 A := (OsH - 1 - Y) * OsW;
 For X := X1 To X2 Do OsFb^[A + X] := C And 15;
End;

Procedure OsTouchL(X1, Y1, X2, Y2 : LongInt);
Begin
 OsTouch(X1 + OsVX1, Y1 + OsVY1, X2 + OsVX1, Y2 + OsVY1);
End;

{ --- Graph (BGI) --- }

Procedure GInitGraph(Var Driver, Mode : Integer; Path : String);
Begin
End;

Function GGraphResult : Integer;
Begin
 GGraphResult := 0;
End;

Function GGraphErrorMsg(Code : Integer) : String;
Begin
 GGraphErrorMsg := 'Erreur graphique';
End;

Procedure GCloseGraph;
Begin
End;

Function GGetMaxX : Integer;
Begin
 GGetMaxX := OsW - 1;
End;

Function GGetMaxY : Integer;
Begin
 GGetMaxY := OsH - 1;
End;

Procedure GSetColor(C : Integer);
Begin
 OsColor := C And 15;
End;

Procedure GSetFillStyle(Pattern : Integer; Color : Integer);
Begin
 OsFillStyle := Pattern;
 OsFillColor := Color And 15;
End;

Procedure GSetLineStyle(Style : Integer; Pattern : Word; Thick : Integer);
Begin
 If Thick >= 3 Then OsThick := 3 Else OsThick := 1;
End;

Procedure GSetTextStyle(Font, Dir, Size : Integer);
Begin
End;

Procedure GSetViewPort(X1, Y1, X2, Y2 : Integer; Clip : Boolean);
Begin
 OsVX1 := X1; OsVY1 := Y1; OsVX2 := X2; OsVY2 := Y2; OsClip := Clip;
End;

Function GTextWidth(S : String) : Integer;
Begin
 GTextWidth := Length(S) * 8;
End;

Function GTextHeight(S : String) : Integer;
Begin
 GTextHeight := 8;
End;

Procedure OsLineThin(X1, Y1, X2, Y2 : LongInt);
Var Dx, Dy, Sx, Sy, E, E2 : LongInt;
Begin
 If Y1 = Y2 Then
 Begin
  If X1 <= X2 Then OsSpan(X1, X2, Y1, OsColor) Else OsSpan(X2, X1, Y1, OsColor);
  Exit;
 End;
 Dx := Abs(X2 - X1); Dy := -Abs(Y2 - Y1);
 If X1 < X2 Then Sx := 1 Else Sx := -1;
 If Y1 < Y2 Then Sy := 1 Else Sy := -1;
 E := Dx + Dy;
 While True Do
 Begin
  OsPlot(X1, Y1, OsColor);
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

Procedure GLine(X1, Y1, X2, Y2 : Integer);
Var A, B, C, D : LongInt;
Begin
 A := X1; B := Y1; C := X2; D := Y2;
 If A < C Then OsTouchL(A - 1, -1, C + 1, -1) Else OsTouchL(C - 1, -1, A + 1, -1);
 If B < D Then OsTouchL(A - 1, B - 1, A + 1, D + 1) Else OsTouchL(A - 1, D - 1, A + 1, B + 1);
 OsTouchL(C - 1, D - 1, C + 1, D + 1);
 If A < C Then OsTouchL(A, B, C, B) Else OsTouchL(C, B, A, B);
 If OsThick = 3 Then
 Begin
  If Abs(C - A) >= Abs(D - B) Then
  Begin
   OsLineThin(A, B - 1, C, D - 1); OsLineThin(A, B, C, D); OsLineThin(A, B + 1, C, D + 1);
  End
  Else
  Begin
   OsLineThin(A - 1, B, C - 1, D); OsLineThin(A, B, C, D); OsLineThin(A + 1, B, C + 1, D);
  End;
 End
 Else OsLineThin(A, B, C, D);
End;

Procedure GRectangle(X1, Y1, X2, Y2 : Integer);
Begin
 GLine(X1, Y1, X2, Y1); GLine(X2, Y1, X2, Y2);
 GLine(X2, Y2, X1, Y2); GLine(X1, Y2, X1, Y1);
End;

Procedure GBar(X1, Y1, X2, Y2 : Integer);
Var Y, T, A, B, C, D : LongInt;
Begin
 A := X1; B := Y1; C := X2; D := Y2;
 If A > C Then Begin T := A; A := C; C := T; End;
 If B > D Then Begin T := B; B := D; D := T; End;
 OsTouchL(A, B, C, D);
 If OsFillStyle = 0 Then Exit;
 For Y := B To D Do OsSpan(A, C, Y, OsFillColor);
End;

Procedure GEllipse(X, Y : Integer; StAngle, EndAngle : Word; XR, YR : Word);
Var A, A2, Steps, K, Px, Py, Qx, Qy : LongInt; T : Double;
Begin
 OsTouchL(X - XR - 2, Y - YR - 2, X + XR + 2, Y + YR + 2);
 If (XR = 0) And (YR = 0) Then
 Begin
  OsPlot(X, Y, OsColor);
  Exit;
 End;
 A := StAngle; A2 := EndAngle;
 If A2 <= A Then A2 := A2 + 360;
 Steps := ((A2 - A) * (XR + YR)) Div 60 + 8;
 If Steps > 720 Then Steps := 720;
 T := A * Pi / 180;
 Px := X + Round(XR * Cos(T)); Py := Y - Round(YR * Sin(T));
 For K := 1 To Steps Do
 Begin
  T := (A + (A2 - A) * K / Steps) * Pi / 180;
  Qx := X + Round(XR * Cos(T)); Qy := Y - Round(YR * Sin(T));
  If (Qx <> Px) Or (Qy <> Py) Then
  Begin
   OsLineThin(Px, Py, Qx, Qy);
   Px := Qx; Py := Qy;
  End;
 End;
End;

Procedure GCircle(X, Y : Integer; Radius : Word);
Begin
 GEllipse(X, Y, 0, 360, Radius, Radius);
End;

Procedure GFillEllipse(X, Y : Integer; XR, YR : Word);
Var Dy, W : LongInt; T : Double;
Begin
 OsTouchL(X - XR - 1, Y - YR - 1, X + XR + 1, Y + YR + 1);
 For Dy := -YR To YR Do
 Begin
  If YR = 0 Then W := XR
  Else
  Begin
   T := 1 - (Dy * Dy) / (YR * 1.0 * YR);
   If T < 0 Then T := 0;
   W := Round(XR * Sqrt(T));
  End;
  OsSpan(X - W, X + W, Y + Dy, OsFillColor);
 End;
 GEllipse(X, Y, 0, 360, XR, YR);
End;

{ texte : police 8 x 8, fond transparent }
Procedure GOutTextXY(X, Y : Integer; S : String);
Var I, R, K, B, C : LongInt;
Begin
 If S = '' Then Exit;
 OsTouchL(X, Y, X + Length(S) * 8 - 1, Y + 7);
 For I := 1 To Length(S) Do
 Begin
  C := Ord(S[I]);
  For R := 0 To 7 Do
  Begin
   B := Font8[C * 8 + R];
   If B <> 0 Then
    For K := 0 To 7 Do
     If (B And ($80 Shr K)) <> 0 Then OsPlot(X + (I - 1) * 8 + K, Y + R, OsColor);
  End;
 End;
End;

{ --- palette de l'image (couleurs du BGI) --- }

Procedure OsInitBmi;
Const
 Pal : Array[0..15] Of LongInt = (
  $000000, $0000AA, $00AA00, $00AAAA, $AA0000, $AA00AA, $AA5500, $AAAAAA,
  $555555, $5555FF, $55FF55, $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF);
Var I, A : LongInt;
Begin
 FillChar(OsBmi, SizeOf(OsBmi), 0);
 OsWrL(LongInt(@OsBmi), 16);
 OsWrL(LongInt(@OsBmi) + 4, OsW);
 OsWrL(LongInt(@OsBmi) + 8, OsH);
 OsWrW(LongInt(@OsBmi) + 12, 1);
 OsWrW(LongInt(@OsBmi) + 14, 8);
 For I := 0 To 15 Do
 Begin
  A := LongInt(@OsBmi) + 16 + I * 4;
  OsWrB(A, Pal[I] And 255);
  OsWrB(A + 1, (Pal[I] Shr 8) And 255);
  OsWrB(A + 2, (Pal[I] Shr 16) And 255);
 End;
 OsColor := 15; OsFillStyle := 1; OsFillColor := 15; OsThick := 1;
 OsVX1 := 0; OsVY1 := 0; OsVX2 := OsW - 1; OsVY2 := OsH - 1; OsClip := False;
 OsDX1 := -1;
End;

{ zone X1..X2, Y1..Y2 de l'image (Y vers le bas) dans la zone client }
Procedure OsBlit(Hps, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 P[0] := X1; P[1] := OsH - 1 - Y2; P[2] := X2 + 1; P[3] := OsH - Y1;
 P[4] := X1; P[5] := OsH - 1 - Y2; P[6] := X2 + 1; P[7] := OsH - Y1;
 OsDummy := GpiDrawBits(Hps, LongInt(OsFb), LongInt(@OsBmi), 4, LongInt(@P), $CC, 0);
End;

Procedure OsFlush;
Var Hps : LongInt;
Begin
 If (OsDX1 < 0) Or (OsClient = 0) Then Exit;
 Hps := WinGetPS(OsClient);
 If Hps <> 0 Then
 Begin
  OsBlit(Hps, OsDX1, OsDY1, OsDX2, OsDY2);
  OsDummy := WinReleasePS(Hps);
 End;
 OsDX1 := -1;
End;

{ --- clavier : file de touches (codes de ReadKey) --- }

Procedure OsKeyPush(C : LongInt);
Var N : LongInt;
Begin
 N := (OsKTail + 1) Mod OsKeyMax;
 If N = OsKHead Then Exit;
 OsKeys[OsKTail] := C And 255;
 OsKTail := N;
End;

{ touche de PM (WM_CHAR) -> codes de Crt.ReadKey (#0 + code etendu) }
Function OsKeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk, Sc, K : LongInt;
Begin
 OsKeyChar := False;
 Fl := OsLo16(Mp1); Ch := OsLo16(Mp2); Vk := OsHi16(Mp2); Sc := (Mp1 Shr 24) And 255;
 If (Fl And KC_KEYUP) <> 0 Then Exit;
 K := -1;
 If (Fl And KC_VIRTUALKEY) <> 0 Then
 Begin
  Case Vk Of
   VK_ESC : K := 27;
   VK_NEWLINE, VK_ENTER : K := 13;
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
 { Ctrl + lettre ou chiffre sans KC_CHAR }
 If (K < 0) And ((Fl And KC_CTRL) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  If (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then K := Ord(UpCase(Chr(Ch))) - 64
  Else If (Ch >= Ord('1')) And (Ch <= Ord('9')) Then K := 256 + 120 + Ch - Ord('1');
 End;
 If K < 0 Then Exit;
 If K >= 256 Then
 Begin
  OsKeyPush(0); OsKeyPush(K - 256);
 End
 Else OsKeyPush(K);
 OsKeyChar := True;
End;

{ --- fenetre --- }

Procedure OsMenuInit; Forward;

Function OsClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, B : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 OsClientProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    OsBlit(Hps, 0, 0, OsW - 1, OsH - 1);
    OsDummy := WinEndPaint(Hps);
   End;
  WM_CHAR :
   If OsKeyChar(Mp1, Mp2) Then OsClientProc := 1
   Else OsClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  WM_MOUSEMOVE :
   Begin
    OsMX := OsS16(Mp1); OsMY := OsH - 1 - OsS16(Mp1 Shr 16);
    OsClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_BUTTON1DOWN, WM_BUTTON1DBLCLK, WM_BUTTON2DOWN, WM_BUTTON2DBLCLK :
   Begin
    OsMX := OsS16(Mp1); OsMY := OsH - 1 - OsS16(Mp1 Shr 16);
    OsDummy := WinSetFocus(HWND_DESKTOP, H);
    OsDummy := WinSetCapture(HWND_DESKTOP, H);
    If (Msg = WM_BUTTON1DOWN) Or (Msg = WM_BUTTON1DBLCLK) Then B := 1 Else B := 2;
    OsMB := OsMB Or B; OsSeen := OsSeen And Not B; OsPendUp := OsPendUp And Not B;
    OsClientProc := 1;
   End;
  WM_BUTTON1UP, WM_BUTTON2UP :
   Begin
    OsMX := OsS16(Mp1); OsMY := OsH - 1 - OsS16(Mp1 Shr 16);
    If Msg = WM_BUTTON1UP Then B := 1 Else B := 2;
    { un clic plus court que la boucle d'Outlink reste vu une fois }
    If (OsSeen And B) <> 0 Then OsMB := OsMB And Not B Else OsPendUp := OsPendUp Or B;
    If OsMB = 0 Then OsDummy := WinSetCapture(HWND_DESKTOP, 0);
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
  WM_CLOSE : OsQuit := True;
 Else
  OsClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

{ fenetre ouverte depuis le bureau : PM l'invalide en l'affichant, avant
  le premier dessin d'Outlink, et les parties encore couvertes par les
  dossiers ne recoivent plus WM_PAINT ; l'image entiere est donc redemandee
  1 s puis 3 s apres l'ouverture }
Var
 OsOpenTick, OsRepaints : LongInt;

Procedure OsPump;
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
End;

{ --- souris (remplace l'interruption 33h) --- }

Function MouseDriverFound : Boolean;
Begin
 MouseDriverFound := True;
End;

Procedure ShowMouse;
Begin
End;

Procedure HideMouse;
Begin
End;

Procedure GetMouseState(Var X, Y, Button : Integer);
Begin
 OsFlush;
 OsPump;
 X := OsMX; Y := OsMY; Button := OsMB;
 OsSeen := OsSeen Or OsMB;
 If OsPendUp <> 0 Then
 Begin
  OsMB := OsMB And Not OsPendUp;
  OsPendUp := 0;
  If OsMB = 0 Then OsDummy := WinSetCapture(HWND_DESKTOP, 0);
 End;
End;

Procedure GetMouseWheel(Var WheelDelta : Integer);
Begin
 WheelDelta := 0;
End;

{ --- Crt --- }

Function PmKeyPressed : Boolean;
Begin
 OsFlush;
 OsPump;
 PmKeyPressed := OsKHead <> OsKTail;
End;

Function PmReadKey : Char;
Begin
 While (OsKHead = OsKTail) And Not OsQuit Do
 Begin
  OsFlush;
  OsPump;
  If OsKHead = OsKTail Then OsDummy := DosSleep(10);
 End;
 If OsKHead = OsKTail Then
 Begin
  PmReadKey := #27;
  Exit;
 End;
 PmReadKey := Chr(OsKeys[OsKHead]);
 OsKHead := (OsKHead + 1) Mod OsKeyMax;
End;

Procedure PmDelay(Ms : Word);
Begin
 OsFlush;
 OsPump;
 If Ms > 0 Then OsDummy := DosSleep(Ms);
End;

Var
 OsFreq : LongInt;

Procedure PmSound(Hz : Word);
Begin
 OsFreq := Hz;
End;

Procedure PmNoSound;
Begin
 OsFreq := 0;
End;

{ --- boites de message d'OS/2 --- }

Function OsBox(Title, Txt : String; Fl : LongInt) : LongInt;
Begin
 OsFlush;
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

{ --- reseau : TCPIP32.DLL et TLS32.DLL --- }

{ adresse IPv4 (ordre du reseau) d'un nom ou d'une adresse a points ; 0 : inconnue }
Function OsResolve(Host : String) : LongInt;
Var P, A, I, N, V, Code : LongInt; Part : String; Dotted : Boolean;
Begin
 OsResolve := 0;
 Dotted := Host <> '';
 For I := 1 To Length(Host) Do If Not (Host[I] In ['0'..'9', '.']) Then Dotted := False;
 If Dotted Then
 Begin
  A := 0; N := 0; Part := Host + '.';
  While (Part <> '') And (N < 4) Do
  Begin
   P := Pos('.', Part);
   Val(Copy(Part, 1, P - 1), V, Code);
   If (Code <> 0) Or (V < 0) Or (V > 255) Then Exit;
   A := A Or (V Shl (N * 8));
   Delete(Part, 1, P); Inc(N);
  End;
  If N = 4 Then OsResolve := A;
  Exit;
 End;
 P := OsGetHostByName(OsZs(Host));
 If P = 0 Then Exit;
 { hostent : h_name, h_aliases, h_addrtype (2+2), h_addr_list }
 A := OsRdL(P + 16);
 If A = 0 Then Exit;
 A := OsRdL(A);
 If A = 0 Then Exit;
 OsResolve := OsRdL(A);
End;

{ connexion TCP ; -1 : echec }
Function OsTcpOpen(Host : String; Port : LongInt) : LongInt;
Var S, Ip : LongInt; Sa : Array[0..15] Of Byte;
Begin
 OsTcpOpen := -1;
 If Not OsNetReady Then
 Begin
  If OsSockInit <> 0 Then Exit;
  OsNetReady := True;
 End;
 Ip := OsResolve(Host);
 If Ip = 0 Then Exit;
 S := OsSocket(2, 1, 0);
 If S < 0 Then Exit;
 FillChar(Sa, SizeOf(Sa), 0);
 Sa[0] := 16; Sa[1] := 2;
 Sa[2] := (Port Shr 8) And 255; Sa[3] := Port And 255;
 OsWrL(LongInt(@Sa) + 4, Ip);
 If OsConnect(S, LongInt(@Sa), 16) <> 0 Then
 Begin
  OsDummy := OsSoClose(S);
  Exit;
 End;
 OsTcpOpen := S;
End;

Function OsTlsMessage : String;
Var B : Array[0..255] Of Byte; N : LongInt; S : String;
Begin
 FillChar(B, SizeOf(B), 0);
 N := OsTlsError(LongInt(@B), 200);
 S := '';
 N := 0;
 While (N < 200) And (B[N] <> 0) Do
 Begin
  S := S + Chr(B[N]);
  Inc(N);
 End;
 OsTlsMessage := S;
End;

{ trace de mise au point (parametre /DEBUG) : D:\OL.LOG }
Var
 OlDebug : Boolean;

Procedure OlDbg(S : String);
Var F : Text;
Begin
 If Not OlDebug Then Exit;
 {$I-}
 Assign(F, 'D:\OL.LOG'); Append(F);
 If IOResult <> 0 Then Rewrite(F);
 If IOResult = 0 Then
 Begin
  WriteLn(F, S);
  Close(F);
 End;
 {$I+}
End;

{ --- fenetre principale : aussi grande que l'ecran (image de la taille
  de la zone client, au plus 1024 x 768) --- }

Procedure OsSetTitle(S : String);
Begin
 If (OsFrame = 0) Or (S = OsTitle) Then Exit;
 OsTitle := S;
 OsDummy := WinSetWindowText(OsFrame, OsZs(S));
End;

Procedure OsSyncMenu; Forward;
Procedure OlBigInit; Forward;

Procedure OsOpenWindow;
Var Fl, Sw, Sh, H0 : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 OlDebug := (ParamCount >= 1) And (ParamStr(ParamCount) = '/DEBUG');
 OsHab := WinInitialize(0);
 OsHmq := WinCreateMsgQueue(OsHab, 64);
 OsDummy := WinRegisterClass(OsHab, OsZs('OUTLINK'), LongInt(@OsClientProc), 0, 0);
 Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST Or FCF_DLGBORDER;
 OsClient := 0; OsTitle := 'Outlink';
 OsFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), OsZs('OUTLINK'), OsZs2('Outlink'), 0, 0, 0,
                               LongInt(@OsClient));
 { barre de menus provisoire (pour la taille de la zone client) }
 OsMenuLen := 0;
 H0 := OsMnOpen;
 OsMnItem(MIS_TEXT, 0, OS_MENUID - 1, '~Fichier');
 OsMnClose(H0, 1);
 OsDummy := WinCreateMenu(OsFrame, LongInt(@OsMenuT));
 OsMenuSig := -1;
 Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
 Rc[0] := 0; Rc[1] := 0; Rc[2] := Sw; Rc[3] := Sh;
 OsDummy := WinCalcFrameRect(OsFrame, LongInt(@Rc), 1);
 OsW := Rc[2] - Rc[0]; OsH := Rc[3] - Rc[1];
 If OsW > OsMaxW Then OsW := OsMaxW;
 If OsH > OsMaxH Then OsH := OsMaxH;
 OsW := OsW And Not 3;
 OsFb := Nil;
 If DosAllocMem(LongInt(@OsFb), OsW * OsH, $13) <> 0 Then Halt(1);
 FillChar(OsFb^, OsW * OsH, 7);
 OsInitBmi;
 Rc[0] := 0; Rc[1] := 0; Rc[2] := OsW; Rc[3] := OsH;
 OsDummy := WinCalcFrameRect(OsFrame, LongInt(@Rc), 0);
 OsDummy := WinSetWindowPos(OsFrame, HWND_TOP, (Sw - (Rc[2] - Rc[0])) Div 2, Sh - (Rc[3] - Rc[1]),
                            Rc[2] - Rc[0], Rc[3] - Rc[1], SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                            SWP_ACTIVATE);
 OsDummy := WinSetFocus(HWND_DESKTOP, OsClient);
 OsOpenTick := KTicks; OsRepaints := 0;
 OlBigInit;
 OsKHead := 0; OsKTail := 0; OsCHead := 0; OsCTail := 0; OsQuit := False; OsMB := 0;
End;

Procedure OsCloseWindow;
Begin
 If OsFrame <> 0 Then OsDummy := WinDestroyWindow(OsFrame);
 OsFrame := 0;
End;

Procedure OsDispatchCommands; Forward;
Const
  OlL1To850 : Array[160..255] Of Byte = (
    255,173,189,156,207,190,221,245,249,184,166,174,170,240,169,238,
    248,241,253,252,239,230,244,250,247,251,167,175,172,171,243,168,
    183,181,182,199,142,143,146,128,212,144,210,211,222,214,215,216,
    209,165,227,224,226,229,153,158,157,235,233,234,154,237,232,225,
    133,160,131,198,132,134,145,135,138,130,136,137,141,161,140,139,
    208,164,149,162,147,228,148,246,155,151,163,150,129,236,231,152);
  Ol850ToL1 : Array[128..255] Of Byte = (
    199,252,233,226,228,224,229,231,234,235,232,239,238,236,196,197,
    201,230,198,244,246,242,251,249,255,214,220,248,163,216,215,63,
    225,237,243,250,241,209,170,186,191,174,172,189,188,161,171,187,
    63,63,63,63,63,193,194,192,169,63,63,63,63,162,165,63,
    63,63,63,63,63,63,227,195,63,63,63,63,63,63,63,164,
    240,208,202,203,200,63,205,206,207,63,63,63,63,166,204,63,
    211,223,212,210,245,213,181,254,222,218,219,217,253,221,175,180,
    173,177,63,190,182,167,247,184,176,168,183,185,179,178,63,160);


{ --- grands tampons : les messages complets depassent les chaines de 255
  caracteres de la version Turbo Pascal --- }

Type
 TBigRef = Record                         { source complete d'un message (tas) }
  P : PFbArr;
  L : LongInt;
 End;

Const
 OlInCap = 2097152;                       { message recu : 2 Mo au plus }
 OlSvCap = 1048576;                       { fichier a ecrire, message a envoyer }
 OlTxCap = 16384;                         { texte decode d'un message }

Function DosFreeMem(Pb : LongInt) : LongInt; External 'DOSCALLS';

Var
 OlIn, OlSv : PFbArr;
 OlInLen, OlSvLen, OlSvBase, OlSvDepth : LongInt;
 OlSvStk : Array[0..7] Of LongInt;
 OlTx : Array[0..OlTxCap - 1] Of Byte;
 OlTxLen : LongInt;
 OlLinePartial, OlWasPartial : Boolean;

Procedure OlBigInit;
Begin
 OlIn := Nil; OlSv := Nil;
 If DosAllocMem(LongInt(@OlIn), OlInCap, $13) <> 0 Then Halt(1);
 If DosAllocMem(LongInt(@OlSv), OlSvCap, $13) <> 0 Then Halt(1);
 OlInLen := 0; OlSvLen := 0; OlSvBase := 0; OlSvDepth := 0;
End;

Procedure OlInClear;
Begin
 OlInLen := 0;
End;

Procedure OlInAddBuf(A, N : LongInt);
Var K : LongInt;
Begin
 If N > OlInCap - OlInLen Then N := OlInCap - OlInLen;
 For K := 0 To N - 1 Do OlIn^[OlInLen + K] := OsPkB(A + K);
 If N > 0 Then OlInLen := OlInLen + N;
End;

Procedure OlInAdd(S : String);
Begin
 If S <> '' Then OlInAddBuf(LongInt(@S[1]), Length(S));
End;

{ tampon d'ecriture (FileSaveData de la version DOS) : pile pour les
  sauvegardes imbriquees (agenda, options) }
Procedure OlSvClear;
Begin
 OlSvLen := OlSvBase;
End;

Function OlSvEmpty : Boolean;
Begin
 OlSvEmpty := OlSvLen <= OlSvBase;
End;

Procedure OlSvAddBuf(A, N : LongInt);
Var K : LongInt;
Begin
 If N > OlSvCap - OlSvLen Then N := OlSvCap - OlSvLen;
 For K := 0 To N - 1 Do OlSv^[OlSvLen + K] := OsPkB(A + K);
 If N > 0 Then OlSvLen := OlSvLen + N;
End;

Procedure OlSvAdd(S : String);
Begin
 If S <> '' Then OlSvAddBuf(LongInt(@S[1]), Length(S));
End;

Procedure OlSvPush;
Begin
 If OlSvDepth < 8 Then OlSvStk[OlSvDepth] := OlSvBase;
 Inc(OlSvDepth);
 OlSvBase := OlSvLen;
End;

Procedure OlSvPop;
Begin
 OlSvLen := OlSvBase;
 If OlSvDepth > 0 Then Dec(OlSvDepth);
 If OlSvDepth < 8 Then OlSvBase := OlSvStk[OlSvDepth] Else OlSvBase := 0;
End;

{ copie de N octets d'un tampon dans un bloc du tas }
Procedure OlFree(Var R : TBigRef);
Begin
 If R.P <> Nil Then OsDummy := DosFreeMem(LongInt(R.P));
 R.P := Nil; R.L := 0;
End;

Procedure OlStore(Var R : TBigRef; Src : PFbArr; N : LongInt);
Var K : LongInt;
Begin
 R.P := Nil; R.L := 0;
 If N <= 0 Then Exit;
 If DosAllocMem(LongInt(@R.P), N, $13) <> 0 Then
 Begin
  R.P := Nil;
  Exit;
 End;
 For K := 0 To N - 1 Do R.P^[K] := Src^[K];
 R.L := N;
End;

Procedure OlRefToSv(Var R : TBigRef);
Begin
 OlSvClear;
 If (R.P <> Nil) And (R.L > 0) Then OlSvAddBuf(LongInt(R.P), R.L);
End;

{ --- recherche et en-tetes dans un tampon --- }

Function OlUp(S : String) : String;
Var K : LongInt;
Begin
 For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
 OlUp := S;
End;

Function OlTrim(S : String) : String;
Begin
 While (S <> '') And (S[1] In [' ', #9]) Do Delete(S, 1, 1);
 While (S <> '') And (S[Length(S)] In [' ', #9, #13]) Do Delete(S, Length(S), 1);
 OlTrim := S;
End;

{ position de Pat dans B[S..E[ ; -1 : absent }
Function OlFind(B : PFbArr; S, E : LongInt; Pat : String) : LongInt;
Var I, K, N : LongInt; Ok : Boolean;
Begin
 OlFind := -1;
 N := Length(Pat);
 If N = 0 Then Exit;
 For I := S To E - N Do
  If B^[I] = Ord(Pat[1]) Then
  Begin
   Ok := True;
   K := 2;
   While Ok And (K <= N) Do
   Begin
    If B^[I + K - 1] <> Ord(Pat[K]) Then Ok := False;
    Inc(K);
   End;
   If Ok Then
   Begin
    OlFind := I;
    Exit;
   End;
  End;
End;

{ fin des en-tetes (debut du corps) de B[S..E[ }
Function OlBodyStart(B : PFbArr; S, E : LongInt) : LongInt;
Var P : LongInt;
Begin
 P := OlFind(B, S, E, #13#10#13#10);
 If P >= 0 Then
 Begin
  OlBodyStart := P + 4;
  Exit;
 End;
 P := OlFind(B, S, E, #10#10);
 If P >= 0 Then OlBodyStart := P + 2 Else OlBodyStart := E;
End;

{ valeur de l'en-tete Name (lignes de suite depliees) }
Function OlHdr(B : PFbArr; S, E : LongInt; Name : String) : String;
Var P, Q, HE, K : LongInt; Line, Key, Value, UName : String; Found : Boolean;
Begin
 OlHdr := '';
 If (B = Nil) Or (E <= S) Then Exit;
 HE := OlBodyStart(B, S, E);
 UName := OlUp(Name);
 P := S; Key := ''; Value := ''; Found := False;
 While P < HE Do
 Begin
  Q := P;
  While (Q < HE) And (B^[Q] <> 13) And (B^[Q] <> 10) Do Inc(Q);
  Line := '';
  For K := P To Q - 1 Do
   If Length(Line) < 250 Then Line := Line + Chr(B^[K]);
  P := Q;
  If (P < HE) And (B^[P] = 13) Then Inc(P);
  If (P < HE) And (B^[P] = 10) Then Inc(P);
  If Line = '' Then Break;
  If Line[1] In [' ', #9] Then
  Begin
   If Found And (Length(Value) < 250) Then Value := Value + ' ' + OlTrim(Line);
  End
  Else
  Begin
   If Found Then
   Begin
    OlHdr := Value;
    Exit;
   End;
   K := Pos(':', Line);
   If K > 0 Then
   Begin
    Key := OlUp(Copy(Line, 1, K - 1));
    If Key = UName Then
    Begin
     Found := True;
     Value := Copy(Line, K + 1, 255);
     Value := OlTrim(Value);
    End;
   End;
  End;
 End;
 If Found Then OlHdr := Value;
End;

Function OlRefHdr(Var R : TBigRef; Name : String) : String;
Begin
 If R.P = Nil Then OlRefHdr := '' Else OlRefHdr := OlHdr(R.P, 0, R.L, Name);
End;

Procedure OlDbgN(T : String; A, B : LongInt; S : String);
Var X, Y : String;
Begin
 Str(A, X); Str(B, Y);
 OlDbg(T + ' ' + X + '..' + Y + ' ' + S);
End;

{ parametre d'un en-tete : boundary, charset }
Function OlParam(H, Name : String) : String;
Var P, Q : LongInt; V : String;
Begin
 OlParam := '';
 P := Pos(OlUp(Name) + '=', OlUp(H));
 If P = 0 Then Exit;
 V := OlTrim(Copy(H, P + Length(Name) + 1, 255));
 If (V <> '') And (V[1] = '"') Then
 Begin
  Delete(V, 1, 1);
  Q := Pos('"', V);
 End
 Else
 Begin
  Q := Pos(';', V);
  If Q = 0 Then Q := Pos(' ', V);
 End;
 If Q > 0 Then V := Copy(V, 1, Q - 1);
 OlParam := V;
End;

{ partie de texte d'un message MIME : B[PS..PE[, type et codage ; WantPlain :
  seulement text/plain (sinon text/* : text/html) ; les pieces jointes sont
  ignorees, comme dans MailTextBody de la version DOS }
Function OlFindText(B : PFbArr; S, E, Depth : LongInt; WantPlain : Boolean;
                    Var PS, PE : LongInt; Var CT, Enc : String) : Boolean;
Var Bs, P, Q, NS : LongInt; H, Bnd, Disp : String;
Begin
 OlFindText := False;
 If Depth > 8 Then Exit;
 Bs := OlBodyStart(B, S, E);
 H := OlHdr(B, S, E, 'Content-Type');
 If Pos('MULTIPART/', OlUp(H)) = 1 Then
 Begin
  Bnd := OlParam(H, 'boundary');
  If Bnd = '' Then Exit;
  Bnd := '--' + Bnd;
  P := OlFind(B, Bs, E, Bnd);
  While P >= 0 Do
  Begin
   { debut de la partie : apres la ligne de la limite }
   NS := P + Length(Bnd);
   If (NS + 1 < E) And (B^[NS] = Ord('-')) And (B^[NS + 1] = Ord('-')) Then Exit;
   While (NS < E) And (B^[NS] <> 10) Do Inc(NS);
   Inc(NS);
   Q := OlFind(B, NS, E, Bnd);
   If Q < 0 Then Q := E;
   Disp := OlUp(OlHdr(B, NS, Q, 'Content-Disposition'));
   If Pos('ATTACHMENT', Disp) = 0 Then
    If OlFindText(B, NS, Q, Depth + 1, WantPlain, PS, PE, CT, Enc) Then
    Begin
     OlFindText := True;
     Exit;
    End;
   If Q >= E Then Exit;
   P := Q;
  End;
  Exit;
 End;
 If (H <> '') And (Pos('TEXT/', OlUp(H)) <> 1) Then Exit;
 If WantPlain And (H <> '') And (Pos('TEXT/PLAIN', OlUp(H)) <> 1) Then Exit;
 PS := Bs; PE := E; CT := H;
 Enc := OlUp(OlHdr(B, S, E, 'Content-Transfer-Encoding'));
 OlFindText := True;
End;

{ caractere decode -> texte (UTF-8 ou Latin-1 -> page de codes 850) }
Var
 OlU8Need, OlU8Acc : LongInt;

Procedure OlTxPut(C : LongInt);
Begin
 If OlTxLen < OlTxCap Then
 Begin
  OlTx[OlTxLen] := C;
  Inc(OlTxLen);
 End;
End;

Procedure OlTxCode(Cp : LongInt);
Begin
 If Cp < 128 Then OlTxPut(Cp)
 Else If (Cp >= 160) And (Cp <= 255) Then OlTxPut(OlL1To850[Cp])
 Else
  Case Cp Of
   $2018, $2019, $201A : OlTxPut(39);
   $201C, $201D, $201E : OlTxPut(34);
   $2013, $2014 : OlTxPut(45);
   $2026 : Begin OlTxPut(46); OlTxPut(46); OlTxPut(46); End;
   $20AC : OlTxPut(Ord('E'));
   $00A0 : OlTxPut(32);
  Else
   OlTxPut(Ord('?'));
  End;
End;

Procedure OlTxByte(C : LongInt; Utf8 : Boolean);
Begin
 If Not Utf8 Then
 Begin
  If C = $92 Then C := 39;
  If C = $93 Then C := 34;
  If C = $94 Then C := 34;
  If C = $96 Then C := 45;
  OlTxCode(C);
  Exit;
 End;
 If C < $80 Then
 Begin
  OlU8Need := 0;
  OlTxPut(C);
 End
 Else If (C And $C0) = $80 Then
 Begin
  If OlU8Need > 0 Then
  Begin
   OlU8Acc := (OlU8Acc Shl 6) Or (C And $3F);
   Dec(OlU8Need);
   If OlU8Need = 0 Then OlTxCode(OlU8Acc);
  End;
 End
 Else If (C And $E0) = $C0 Then Begin OlU8Acc := C And $1F; OlU8Need := 1; End
 Else If (C And $F0) = $E0 Then Begin OlU8Acc := C And $0F; OlU8Need := 2; End
 Else Begin OlU8Acc := C And $07; OlU8Need := 3; End;
End;

Function OlB64(C : LongInt) : LongInt;
Begin
 If (C >= Ord('A')) And (C <= Ord('Z')) Then OlB64 := C - Ord('A')
 Else If (C >= Ord('a')) And (C <= Ord('z')) Then OlB64 := C - Ord('a') + 26
 Else If (C >= Ord('0')) And (C <= Ord('9')) Then OlB64 := C - Ord('0') + 52
 Else If C = Ord('+') Then OlB64 := 62
 Else If C = Ord('/') Then OlB64 := 63
 Else OlB64 := -1;
End;

Function OlHexV(C : LongInt) : LongInt;
Begin
 If (C >= Ord('0')) And (C <= Ord('9')) Then OlHexV := C - Ord('0')
 Else If (C >= Ord('A')) And (C <= Ord('F')) Then OlHexV := C - Ord('A') + 10
 Else If (C >= Ord('a')) And (C <= Ord('f')) Then OlHexV := C - Ord('a') + 10
 Else OlHexV := -1;
End;

{ texte d'une partie : decode (base64, quoted-printable) dans OlRw, puis
  jeu de caracteres converti et HTML ramene a du texte ; resultat dans OlTx }
Var
 OlRw : Array[0..OlTxCap - 1] Of Byte;
 OlRwLen : LongInt;

{ entite HTML nommee -> point de code (0 : inconnue) }
Function OlEntity(E : String) : LongInt;
Const
 N1 = ' nbsp amp lt gt quot apos laquo raquo copy reg deg middot hellip ndash mdash lsquo rsquo ldquo rdquo euro ';
 C1 : Array[0..19] Of LongInt = (160, 38, 60, 62, 34, 39, 171, 187, 169, 174, 176, 183, $2026, $2013, $2014,
                                  $2018, $2019, $201C, $201D, $20AC);
 L1 = 'aeiouyAEIOUYcCnN';
Var P, K, Base, V : LongInt; Acc, Ch : String;
Begin
 OlEntity := 0;
 P := Pos(' ' + E + ' ', N1);
 If P > 0 Then
 Begin
  K := 0;
  For V := 1 To P Do If N1[V] = ' ' Then Inc(K);
  OlEntity := C1[K - 1];
  Exit;
 End;
 { lettre + acute, grave, circ, uml, cedil, tilde }
 If Length(E) < 4 Then Exit;
 Ch := Copy(E, 1, 1); Acc := Copy(E, 2, 10);
 If Pos(Ch, L1) = 0 Then Exit;
 V := 0;
 If Acc = 'grave' Then Base := 0 Else If Acc = 'acute' Then Base := 1 Else If Acc = 'circ' Then Base := 2
 Else If Acc = 'tilde' Then Base := 3 Else If Acc = 'uml' Then Base := 4 Else If Acc = 'cedil' Then Base := 5
 Else Exit;
 Case Ch[1] Of
  'a' : If Base <= 4 Then V := 224 + Base;
  'A' : If Base <= 4 Then V := 192 + Base;
  'e' : If (Base <= 4) And (Base <> 3) Then V := 232 + Base - Ord(Base = 4);
  'E' : If (Base <= 4) And (Base <> 3) Then V := 200 + Base - Ord(Base = 4);
  'i' : If (Base <= 4) And (Base <> 3) Then V := 236 + Base - Ord(Base = 4);
  'I' : If (Base <= 4) And (Base <> 3) Then V := 204 + Base - Ord(Base = 4);
  'o' : If Base <= 4 Then V := 242 + Base;
  'O' : If Base <= 4 Then V := 210 + Base;
  'u' : If (Base <= 4) And (Base <> 3) Then V := 249 + Base - Ord(Base = 4);
  'U' : If (Base <= 4) And (Base <> 3) Then V := 217 + Base - Ord(Base = 4);
  'y' : If Base = 1 Then V := 253 Else If Base = 4 Then V := 255;
  'Y' : If Base = 1 Then V := 221;
  'c' : If Base = 5 Then V := 231;
  'C' : If Base = 5 Then V := 199;
  'n' : If Base = 3 Then V := 241;
  'N' : If Base = 3 Then V := 209;
 End;
 OlEntity := V;
End;

Procedure OlTxNl;
Begin
 { une ligne vide au plus entre deux paragraphes }
 If OlTxLen = 0 Then Exit;
 If (OlTxLen >= 2) And (OlTx[OlTxLen - 1] = 10) And (OlTx[OlTxLen - 2] = 10) Then Exit;
 OlTxPut(10);
End;

Procedure OlDecodeText(B : PFbArr; PS, PE : LongInt; CT, Enc : String);
Var I, V, Bits, Acc, H1, H2, C, K, Cp, Code : LongInt; Utf8, Html, Sp, Close : Boolean; Ent, Tag, Skip : String;
Begin
 OlTxLen := 0; OlU8Need := 0; OlRwLen := 0;
 Utf8 := Pos('UTF-8', OlUp(OlParam(CT, 'charset'))) > 0;
 Html := Pos('TEXT/HTML', OlUp(CT)) = 1;
 Enc := OlUp(Enc);
 { 1. codage de transfert }
 Acc := 0; Bits := 0;
 I := PS;
 While (I < PE) And (OlRwLen < OlTxCap) Do
 Begin
  C := B^[I];
  Inc(I);
  If Pos('BASE64', Enc) > 0 Then
  Begin
   V := OlB64(C);
   If V < 0 Then Continue;
   Acc := ((Acc Shl 6) Or V) And $FFFFFF;
   Bits := Bits + 6;
   If Bits < 8 Then Continue;
   Bits := Bits - 8;
   C := (Acc Shr Bits) And 255;
  End
  Else If (Pos('QUOTED-PRINTABLE', Enc) > 0) And (C = Ord('=')) Then
  Begin
   If (I < PE) And (B^[I] = 13) Then Begin I := I + 2; Continue; End;
   If (I < PE) And (B^[I] = 10) Then Begin Inc(I); Continue; End;
   If I + 1 < PE Then
   Begin
    H1 := OlHexV(B^[I]); H2 := OlHexV(B^[I + 1]);
    If (H1 >= 0) And (H2 >= 0) Then Begin C := H1 * 16 + H2; I := I + 2; End;
   End;
  End;
  If C = 13 Then Continue;
  OlRw[OlRwLen] := C; Inc(OlRwLen);
 End;
 { 2. texte brut : jeu de caracteres }
 If Not Html Then
 Begin
  For I := 0 To OlRwLen - 1 Do OlTxByte(OlRw[I], Utf8);
  Exit;
 End;
 { 3. HTML : balises de bloc -> fins de ligne, style et script omis, entites }
 Sp := True; Skip := '';
 I := 0;
 While (I < OlRwLen) And (OlTxLen < OlTxCap - 8) Do
 Begin
  C := OlRw[I];
  Inc(I);
  If C = Ord('<') Then
  Begin
   Close := (I < OlRwLen) And (OlRw[I] = Ord('/'));
   If Close Then Inc(I);
   Tag := '';
   While (I < OlRwLen) And (Chr(OlRw[I]) In ['A'..'Z', 'a'..'z', '0'..'9', '!']) And (Length(Tag) < 12) Do
   Begin
    Tag := Tag + UpCase(Chr(OlRw[I])); Inc(I);
   End;
   { fin de la balise (commentaire : jusqu'a -->) }
   If Copy(Tag, 1, 3) = '!--' Then
   Begin
    While (I + 2 < OlRwLen) And Not ((OlRw[I] = Ord('-')) And (OlRw[I + 1] = Ord('-')) And (OlRw[I + 2] = Ord('>'))) Do Inc(I);
    I := I + 3;
    Continue;
   End;
   While (I < OlRwLen) And (OlRw[I] <> Ord('>')) Do Inc(I);
   Inc(I);
   If Skip <> '' Then
   Begin
    If Close And (Tag = Skip) Then Skip := '';
    Continue;
   End;
   If Not Close And ((Tag = 'STYLE') Or (Tag = 'SCRIPT') Or (Tag = 'HEAD') Or (Tag = 'TITLE')) Then
   Begin
    Skip := Tag; Continue;
   End;
   If Tag = 'BR' Then Begin OlTxPut(10); Sp := True; End
   Else If (Tag = 'P') Or (Tag = 'DIV') Or (Tag = 'TR') Or (Tag = 'TABLE') Or (Tag = 'UL') Or (Tag = 'OL') Or
           (Tag = 'BLOCKQUOTE') Or (Tag = 'H1') Or (Tag = 'H2') Or (Tag = 'H3') Or (Tag = 'H4') Or
           (Tag = 'H5') Or (Tag = 'H6') Or (Tag = 'HR') Then
   Begin
    If (OlTxLen > 0) And (OlTx[OlTxLen - 1] <> 10) Then OlTxPut(10);
    If Close Or (Tag = 'HR') Then OlTxNl;
    Sp := True;
   End
   Else If (Tag = 'LI') And Not Close Then
   Begin
    If (OlTxLen > 0) And (OlTx[OlTxLen - 1] <> 10) Then OlTxPut(10);
    OlTxPut(Ord('-')); OlTxPut(32); Sp := True;
   End
   Else If (Tag = 'TD') Or (Tag = 'TH') Then
   Begin
    If Not Sp Then Begin OlTxPut(32); Sp := True; End;
   End;
   Continue;
  End;
  If Skip <> '' Then Continue;
  If (C = 10) Or (C = 9) Then C := 32;
  If C = 32 Then
  Begin
   If Sp Then Continue;
   Sp := True;
   OlTxPut(32);
   Continue;
  End;
  Sp := False;
  If C = Ord('&') Then
  Begin
   Ent := '';
   K := I;
   While (K < OlRwLen) And (K - I < 10) And (OlRw[K] <> Ord(';')) And (OlRw[K] > 32) Do
   Begin
    Ent := Ent + Chr(OlRw[K]); Inc(K);
   End;
   Cp := 0;
   If (K < OlRwLen) And (OlRw[K] = Ord(';')) And (Ent <> '') Then
   Begin
    If Ent[1] = '#' Then
    Begin
     If (Length(Ent) > 1) And (UpCase(Ent[2]) = 'X') Then
     Begin
      Cp := 0;
      For V := 3 To Length(Ent) Do If OlHexV(Ord(Ent[V])) >= 0 Then Cp := Cp * 16 + OlHexV(Ord(Ent[V]));
     End
     Else Val(Copy(Ent, 2, 10), Cp, Code);
    End
    Else Cp := OlEntity(Ent);
   End;
   If Cp > 0 Then
   Begin
    I := K + 1;
    OlU8Need := 0;
    OlTxCode(Cp);
    Continue;
   End;
  End;
  OlTxByte(C, Utf8);
 End;
End;

{ texte d'un message (B[0..L[) : text/plain, sinon text/html }
Procedure OlMessageText(B : PFbArr; L : LongInt);
Var PS, PE : LongInt; CT, Enc : String;
Begin
 OlTxLen := 0;
 If (B = Nil) Or (L <= 0) Then Exit;
 If OlFindText(B, 0, L, 0, True, PS, PE, CT, Enc) Then OlDecodeText(B, PS, PE, CT, Enc)
 Else If OlFindText(B, 0, L, 0, False, PS, PE, CT, Enc) Then OlDecodeText(B, PS, PE, CT, Enc);
End;

{ debut du texte d'un message (regles de filtrage) }
Function OlRefText(Var R : TBigRef) : String;
Var K : LongInt; S : String;
Begin
 OlMessageText(R.P, R.L);
 S := '';
 For K := 0 To OlTxLen - 1 Do
  If Length(S) < 255 Then
  Begin
   If OlTx[K] = 10 Then S := S + ' ' Else S := S + Chr(OlTx[K]);
  End;
 OlRefText := S;
End;

{ chaine UTF-8 ou Latin-1 -> page de codes 850 (en-tetes decodes) }
Function OlConvStr(S : String; Utf8 : Boolean) : String;
Var K : LongInt; R : String;
Begin
 OlTxLen := 0; OlU8Need := 0;
 For K := 1 To Length(S) Do OlTxByte(Ord(S[K]), Utf8);
 R := '';
 For K := 0 To OlTxLen - 1 Do If Length(R) < 255 Then R := R + Chr(OlTx[K]);
 OlConvStr := R;
End;

{ texte de la page de codes 850 -> Windows-1252 (envoi) }
Function OlTo1252(S : String) : String;
Var K : LongInt;
Begin
 For K := 1 To Length(S) Do
  If Ord(S[K]) >= 128 Then S[K] := Chr(Ol850ToL1[Ord(S[K])]);
 OlTo1252 := S;
End;

{ texte tronque a la largeur d'une colonne (police de 8 points) }
Function OlFit(S : String; W : LongInt) : String;
Var N : LongInt;
Begin
 N := (W - 6) Div 8;
 If N < 1 Then N := 1;
 If Length(S) > N Then
 Begin
  If N > 4 Then S := Copy(S, 1, N - 3) + '...' Else S := Copy(S, 1, N);
 End;
 OlFit := S;
End;

{ date RFC 2822 (Mon, 16 Nov 2026 10:03:00 +0000) -> JJ/MM/AA }
Function OlShortDate(D : String) : String;
Const Mon = 'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC';
Var P, Day, M, Y, Code : LongInt; W : String; R, T : String;
Begin
 OlShortDate := Copy(D, 1, 10);
 P := Pos(',', D);
 If P > 0 Then Delete(D, 1, P);
 While (D <> '') And (D[1] = ' ') Do Delete(D, 1, 1);
 P := Pos(' ', D); If P = 0 Then Exit;
 Val(Copy(D, 1, P - 1), Day, Code); If Code <> 0 Then Exit;
 Delete(D, 1, P);
 W := OlUp(Copy(D, 1, 3)); M := Pos(W, Mon);
 If (M = 0) Or ((M - 1) Mod 3 <> 0) Then Exit;
 M := (M - 1) Div 3 + 1;
 Delete(D, 1, 4);
 Val(Copy(D, 1, 4), Y, Code); If Code <> 0 Then Exit;
 Str(Day, T); If Length(T) < 2 Then T := '0' + T; R := T + '/';
 Str(M, T); If Length(T) < 2 Then T := '0' + T; R := R + T + '/';
 Str(Y Mod 100, T); If Length(T) < 2 Then T := '0' + T;
 OlShortDate := R + T;
End;





Const
 { Dimensions de l'ecran VGA 640x480 }
 DEFAULT_SCREEN_WIDTH = 640;
 DEFAULT_SCREEN_HEIGHT = 480;
 OPEN_DIALOG_WIDTH = 560;
 OPEN_DIALOG_HEIGHT = 380;
 OPEN_DIALOG_ROWS = 14;
 MAX_OPEN_DIALOG_FILES = 256;

 { Couleurs style Windows 95/98 }
 COLOR_DESKTOP = 1;       { Bleu fonce - fond bureau }
 COLOR_TITLEBAR = 1;      { Bleu - barre de titre active }
 COLOR_TITLEBAR_INACTIVE = 8; { Gris - barre de titre inactive }
 COLOR_TITLEBAR_TEXT = 15; { Blanc - texte barre de titre }
 COLOR_WINDOW_BG = 7;     { Gris clair - fond fenetre }
 COLOR_WINDOW_BORDER = 0; { Noir - bordure fenetre }
 COLOR_MENU_BG = 7;       { Gris clair - fond menu }
 COLOR_MENU_TEXT = 0;     { Noir - texte menu }
 COLOR_MENU_HIGHLIGHT = 1; { Bleu - surbrillance menu }
 COLOR_MENU_HIGHLIGHT_TEXT = 15; { Blanc - texte surbrillance }
 COLOR_TOOLBAR_BG = 7;    { Gris clair - fond barre d'outils }
 COLOR_BUTTON_FACE = 7;   { Gris clair - face bouton }
 COLOR_BUTTON_LIGHT = 15; { Blanc - bord clair bouton }
 COLOR_BUTTON_DARK = 8;   { Gris fonce - bord sombre bouton }
 COLOR_LIST_BG = 15;      { Blanc - fond liste }
 COLOR_LIST_TEXT = 0;     { Noir - texte liste }
 COLOR_LIST_SELECTED = 1; { Bleu - selection liste }
 COLOR_LIST_SELECTED_TEXT = 15; { Blanc - texte selection }
 COLOR_FOLDER_BG = 7;     { Gris clair - fond panneau dossiers }
 COLOR_PREVIEW_BG = 15;   { Blanc - fond previsualisation }
 COLOR_SPLITTER = 8;      { Gris fonce - separateur }
 COLOR_SCROLLBAR = 7;     { Gris clair - barre de defilement }
 COLOR_STATUS_BG = 7;     { Gris clair - barre d'etat }
 COLOR_STATUS_TEXT = 0;   { Noir - texte barre d'etat }

 { Hauteurs des zones fixes }
 TITLEBAR_HEIGHT = 0;   { barre de titre de PM }
 MENUBAR_HEIGHT = 0;    { barre de menus de PM }
 TOOLBAR_HEIGHT = 28;
 STATUSBAR_HEIGHT = 20;

 { Largeur minimale des panneaux }
 MIN_FOLDER_WIDTH = 100;
 MIN_MESSAGE_WIDTH = 200;
 MIN_PREVIEW_HEIGHT = 80;

 { Taille de la zone de redimensionnement }
 SPLITTER_SIZE = 4;

 { Parametres du double-clic }
 DOUBLE_CLICK_TIME = 500;  { Temps max entre deux clics en millisecondes }
 DOUBLE_CLICK_DIST = 4;    { Distance max entre deux clics en pixels }

 { Boutons de la souris }
 MOUSE_LEFT = 1;
 MOUSE_RIGHT = 2;
 MOUSE_MIDDLE = 4;

Type
 
 TMailText = String;
 
 
 TOpenFileEntry = Record
  Name: String[255];
  IsDirectory: Boolean;
 End;
 TMailConnection = Record
  
  Open, Secure: Boolean;
  Sock: LongInt;                  { socket de TCPIP32.DLL }
  Host, Pending, Encrypted: TMailText;
 End;
 { Structure pour la disposition des zones de l'interface }
 TWindowLayout = Record
  TitleBarRect: Record X1, Y1, X2, Y2: Integer; End;
  MenuBarRect: Record X1, Y1, X2, Y2: Integer; End;
  ToolBarRect: Record X1, Y1, X2, Y2: Integer; End;
  FolderPaneRect: Record X1, Y1, X2, Y2: Integer; End;
  MessageListRect: Record X1, Y1, X2, Y2: Integer; End;
  PreviewPaneRect: Record X1, Y1, X2, Y2: Integer; End;
  StatusBarRect: Record X1, Y1, X2, Y2: Integer; End;
  VSplitterRect: Record X1, Y1, X2, Y2: Integer; End;
  HSplitterRect: Record X1, Y1, X2, Y2: Integer; End;
  FolderPaneWidth: Integer;
  PreviewPaneHeight: Integer;
 End;

 { Etat de la souris pour le redimensionnement }
 TDragState = (dsNone, dsDragVSplitter, dsDragHSplitter);

 { Type d'evenement souris }
 TMouseEvent = (meNone, meLeftClick, meRightClick, meMiddleClick,
                meLeftDoubleClick, meRightDoubleClick,
                meWheelUp, meWheelDown);

 { Structure pour un element de menu }
 TMenuItem = Record
  Caption: String[30];    { Texte de l'element }
  Shortcut: String[15];   { Raccourci clavier (ex: Ctrl+N) }
  Separator: Boolean;     { True si c'est un separateur }
  Enabled: Boolean;       { True si l'element est actif }
  ItemID: Integer;        { Identifiant unique de l'element }
 End;

 { Structure pour un menu deroulant }
 TDropdownMenu = Record
  Title: String[20];       { Titre du menu dans la barre }
  X, Width: Integer;       { Position et largeur dans la barre de menu }
  Items: Array[0..14] of TMenuItem; { Elements du menu (max 15) }
  ItemCount: Integer;      { Nombre d'elements }
  DropX, DropY: Integer;   { Position du menu deroulant }
  DropWidth, DropHeight: Integer; { Dimensions du menu deroulant }
 End;

 { Etat visuel d'un bouton de barre d'outils }
 TToolButtonState = (tbsNormal, tbsHover, tbsPressed, tbsDisabled);

 { Type d'icone pour un bouton }
 TToolIconType = (tiNewMsg, tiReply, tiReplyAll, tiForward,
                  tiSendRecv, tiDelete, tiPrint, tiAddressBook, tiSeparator);

 { Structure pour un bouton de barre d'outils }
 TToolButton = Record
  X, Y, W, H: Integer;       { Position et dimensions }
  Caption: String[15];       { Texte du bouton }
  Tooltip: String[40];       { Infobulle }
  IconType: TToolIconType;   { Type d'icone }
  CommandID: Integer;        { Commande associee }
  State: TToolButtonState;   { Etat actuel }
  Enabled: Boolean;          { Actif ou non }
 End;

 { Type de dossier pour l'arbre de navigation }
 TFolderType = (ftAccount, ftInbox, ftSent, ftDrafts, ftDeleted, ftJunk, ftCustom);

 { Structure pour un noeud de l'arbre de dossiers }
 TFolderNode = Record
  Name: String[30];          { Nom du dossier }
  FolderType: TFolderType;   { Type de dossier }
  Level: Integer;            { Niveau d'indentation (0=compte, 1=dossier, 2=sous-dossier) }
  ParentIndex: Integer;      { Index du parent (-1 si racine) }
  Expanded: Boolean;         { Etendu ou replie }
  Selected: Boolean;         { Selectionne }
  UnreadCount: LongInt;      { Nombre de messages non lus }
  TotalCount: LongInt;       { Nombre total de messages }
  Y: Integer;                { Position Y actuelle (calculee lors du dessin) }
  Visible: Boolean;          { Visible dans l'arbre (depend de l'expansion du parent) }
 End;

 { Priorite d'un message }
 TMessagePriority = (mpLow, mpNormal, mpHigh);

 { ============================================================================
   TYPES POUR LES PIECES JOINTES (TODO 13) - Declaration anticipee
   ============================================================================ }

 { Type de fichier pour l'icone }
 TAttachmentType = (
  atUnknown,    { Type inconnu }
  atDocument,   { Document texte (DOC, TXT, RTF) }
  atSpreadsheet,{ Tableur (XLS, CSV) }
  atImage,      { Image (JPG, PNG, GIF, BMP) }
  atArchive,    { Archive (ZIP, RAR, 7Z) }
  atExecutable, { Executable (EXE, COM, BAT) - DANGEREUX }
  atAudio,      { Audio (MP3, WAV) }
  atVideo,      { Video (AVI, MPG, MP4) }
  atPDF         { PDF }
 );

 { Structure pour une piece jointe }
 TAttachment = Record
  FileName: String[80];        { Nom du fichier }
  FilePath: String[200];       { Chemin complet sur disque }
  FileSize: LongInt;           { Taille en octets }
  FileType: TAttachmentType;   { Type de fichier }
  IsEmbedded: Boolean;         { Integre dans le message (non externe) }
  ContentID: String[40];       { ID pour les images integrees }
  IsDangerous: Boolean;        { Extension dangereuse }
 End;

 { ============================================================================
   TYPES POUR LE MOTEUR DE RENDU HTML (TODO 14)
   ============================================================================ }

 { Types de balises HTML supportees }
 THTMLTagType = (
  htUnknown,     { Balise inconnue }
  htHTML,        { <html> }
  htHead,        { <head> }
  htTitle,       { <title> }
  htMeta,        { <meta> }
  htBody,        { <body> }
  htDiv,         { <div> }
  htSpan,        { <span> }
  htP,           { <p> }
  htBr,          { <br> }
  htHr,          { <hr> }
  htB,           { <b> }
  htI,           { <i> }
  htU,           { <u> }
  htStrong,      { <strong> }
  htEm,          { <em> }
  htFont,        { <font> }
  htUL,          { <ul> }
  htOL,          { <ol> }
  htLI,          { <li> }
  htTable,       { <table> }
  htTR,          { <tr> }
  htTD,          { <td> }
  htTH,          { <th> }
  htA,           { <a> }
  htImg,         { <img> }
  htH1,          { <h1> }
  htH2,          { <h2> }
  htH3,          { <h3> }
  htCenter,      { <center> }
  htBlockquote,  { <blockquote> }
  htPre,         { <pre> }
  htCode         { <code> }
 );

 { Type de token HTML }
 THTMLTokenType = (
  ttText,        { Texte brut }
  ttOpenTag,     { <balise> }
  ttCloseTag,    { </balise> }
  ttSelfClose,   { <balise /> }
  ttComment,     { <!-- --> }
  ttDoctype,     { <!DOCTYPE> }
  ttEntity       { &entity; }
 );

 { Alignement du texte }
 THTMLAlign = (haLeft, haCenter, haRight, haJustify);

 { Structure d'un attribut HTML }
 THTMLAttribute = Record
  Name: String[20];
  Value: String[80];
 End;

 { Structure d'un token HTML }
 THTMLToken = Record
  TokenType: THTMLTokenType;
  TagType: THTMLTagType;
  TagName: String[20];
  Content: String[250];
  Attributes: Array[0..7] of THTMLAttribute;
  AttrCount: Integer;
 End;

 { Style de rendu courant }
 THTMLRenderStyle = Record
  Bold: Boolean;
  Italic: Boolean;
  Underline: Boolean;
  FontColor: Word;
  BGColor: Word;
  FontSize: Integer;       { 1-7 comme HTML, 3 = normal }
  Align: THTMLAlign;
  InPre: Boolean;          { Dans un bloc <pre> }
  ListLevel: Integer;      { Niveau d'imbrication des listes }
  ListOrdered: Boolean;    { Liste ordonnee ou non }
  ListItemNum: Integer;    { Numero de l'item courant }
  InTable: Boolean;        { Dans un tableau }
  InLink: Boolean;         { Dans un lien }
  LinkURL: String[200];    { URL du lien courant }
 End;

 { Element de rendu HTML }
 THTMLRenderElement = Record
  X, Y: Integer;           { Position }
  Width, Height: Integer;  { Dimensions }
  Text: String[80];        { Texte a afficher }
  Style: THTMLRenderStyle; { Style applique }
  IsLink: Boolean;         { Element cliquable }
  LinkURL: String[200];    { URL si lien }
  IsImage: Boolean;        { Placeholder d'image }
  ImageWidth: Integer;     { Largeur de l'image }
  ImageHeight: Integer;    { Hauteur de l'image }
 End;

 { ============================================================================
   TYPES POUR LE DECODAGE MIME (TODO 15)
   ============================================================================ }

 { Type d'encodage de transfert }
 TMIMETransferEncoding = (
  mte7Bit,             { 7bit - texte ASCII }
  mte8Bit,             { 8bit - texte avec caracteres etendus }
  mteQuotedPrintable,  { Quoted-Printable }
  mteBase64,           { Base64 }
  mteBinary            { Binaire }
 );

 { Type de contenu principal }
 TMIMEContentType = (
  mctText,             { text/* }
  mctMultipart,        { multipart/* }
  mctApplication,      { application/* }
  mctImage,            { image/* }
  mctAudio,            { audio/* }
  mctVideo,            { video/* }
  mctMessage,          { message/* }
  mctUnknown           { Type inconnu }
 );

 { Sous-type MIME }
 TMIMESubType = (
  mstPlain,            { text/plain }
  mstHTML,             { text/html }
  mstMixed,            { multipart/mixed }
  mstAlternative,      { multipart/alternative }
  mstRelated,          { multipart/related }
  mstOctetStream,      { application/octet-stream }
  mstPDF,              { application/pdf }
  mstJPEG,             { image/jpeg }
  mstPNG,              { image/png }
  mstGIF,              { image/gif }
  mstRFC822,           { message/rfc822 }
  mstUnknown           { Sous-type inconnu }
 );

 { Jeu de caracteres }
 TMIMECharset = (
  mcsASCII,            { US-ASCII }
  mcsUTF8,             { UTF-8 }
  mcsISO8859_1,        { ISO-8859-1 (Latin-1) }
  mcsWindows1252,      { Windows-1252 }
  mcsISO8859_15,       { ISO-8859-15 (Latin-9) }
  mcsUnknown           { Jeu inconnu }
 );

 { Structure pour un en-tete MIME }
 TMIMEHeader = Record
  Name: String[40];
  Value: String[200];
 End;

 { Structure pour une partie MIME }
 TMIMEPart = Record
  ContentType: TMIMEContentType;
  SubType: TMIMESubType;
  ContentTypeStr: String[60];    { Content-Type complet }
  Charset: TMIMECharset;
  TransferEncoding: TMIMETransferEncoding;
  Boundary: String[80];          { Pour multipart }
  FileName: String[80];          { Nom du fichier si piece jointe }
  ContentID: String[40];         { ID pour images inline }
  IsAttachment: Boolean;         { Est une piece jointe }
  DataOffset: LongInt;           { Position dans le flux }
  DataLength: LongInt;           { Taille des donnees }
  DecodedLength: LongInt;        { Taille une fois decode }
  PartCount: Integer;            { Nombre de sous-parties }
 End;

 { ============================================================================
   TYPES POUR LE CARNET D'ADRESSES (TODO 16)
   ============================================================================ }

 { Structure pour un contact }
 TContact = Record
  ID: Integer;                   { Identifiant unique }
  LastName: String[40];          { Nom de famille }
  FirstName: String[40];         { Prenom }
  DisplayName: String[60];       { Nom d'affichage }
  Email: String[80];             { Adresse email principale }
  Email2: String[80];            { Adresse email secondaire }
  Phone: String[20];             { Telephone principal }
  PhoneMobile: String[20];       { Telephone mobile }
  PhoneWork: String[20];         { Telephone travail }
  Address: String[80];           { Adresse ligne 1 }
  Address2: String[80];          { Adresse ligne 2 }
  City: String[40];              { Ville }
  PostalCode: String[10];        { Code postal }
  Country: String[30];           { Pays }
  Company: String[60];           { Entreprise }
  JobTitle: String[40];          { Titre/Fonction }
  Notes: String[200];            { Notes }
  Birthday: String[10];          { Date de naissance JJ/MM/AAAA }
  CreatedDate: LongInt;          { Date de creation }
  ModifiedDate: LongInt;         { Date de modification }
  IsSelected: Boolean;           { Selection pour operations en lot }
 End;

 { Type de tri pour les contacts }
 TContactSortField = (
  csfLastName,                   { Tri par nom }
  csfFirstName,                  { Tri par prenom }
  csfEmail,                      { Tri par email }
  csfCompany                     { Tri par entreprise }
 );

 { Etat de la fenetre carnet d'adresses }
 TAddressBookState = (
  absHidden,                     { Fenetre cachee }
  absList,                       { Liste des contacts }
  absEdit,                       { Edition d'un contact }
  absNew,                        { Nouveau contact }
  absSearch,                     { Recherche }
  absImport,                     { Import }
  absExport                      { Export }
 );

 { Format d'import/export }
 TAddressBookFormat = (
  abfVCard,                      { Format vCard (.vcf) }
  abfCSV                         { Format CSV }
 );

 { Champ de l'auto-completion }
 TAutoCompleteField = (
  acfTo,                         { Champ A: }
  acfCc,                         { Champ Cc: }
  acfBcc                         { Champ Cci: }
 );

 { Structure pour l'auto-completion }
 TAutoCompleteSuggestion = Record
  DisplayName: String[60];
  Email: String[80];
  MatchScore: Integer;           { Score de correspondance }
 End;

 { ============================================================================
   TYPES POUR LE SYSTEME DE REGLES DE FILTRAGE (TODO 17)
   ============================================================================ }

 { Type de condition pour une regle }
 TRuleConditionType = (
  rctSenderContains,             { Expediteur contient }
  rctSenderEquals,               { Expediteur egal a }
  rctSubjectContains,            { Objet contient }
  rctSubjectStartsWith,          { Objet commence par }
  rctBodyContains,               { Corps contient }
  rctSizeGreaterThan,            { Taille superieure a }
  rctSizeLessThan,               { Taille inferieure a }
  rctHasAttachment,              { Contient piece jointe }
  rctPriorityEquals,             { Priorite egale a }
  rctDateOlderThan,              { Date plus ancienne que (jours) }
  rctDateNewerThan,              { Date plus recente que (jours) }
  rctToContains,                 { Destinataire contient }
  rctCcContains                  { Copie contient }
 );

 { Type d'action pour une regle }
 TRuleActionType = (
  ratMoveToFolder,               { Deplacer vers dossier }
  ratCopyToFolder,               { Copier vers dossier }
  ratMarkAsRead,                 { Marquer comme lu }
  ratMarkAsUnread,               { Marquer comme non lu }
  ratSetFlag,                    { Marquer d'un drapeau }
  ratClearFlag,                  { Retirer le drapeau }
  ratSetPriority,                { Definir la priorite }
  ratDelete,                     { Supprimer }
  ratForwardTo,                  { Transferer a }
  ratAutoReply,                  { Repondre automatiquement }
  ratPlaySound,                  { Jouer un son }
  ratStopProcessing              { Arreter le traitement des regles }
 );

 { Operateur logique pour combiner les conditions }
 TRuleOperator = (
  roAnd,                         { Toutes les conditions doivent etre vraies }
  roOr                           { Au moins une condition doit etre vraie }
 );

 { Condition d'une regle }
 TRuleCondition = Record
  ConditionType: TRuleConditionType;
  Value: String[80];             { Valeur a comparer }
  NumericValue: LongInt;         { Valeur numerique (taille, jours) }
  CaseSensitive: Boolean;        { Respecter la casse }
 End;

 { Action d'une regle }
 TRuleAction = Record
  ActionType: TRuleActionType;
  TargetFolder: String[40];      { Dossier cible }
  TargetEmail: String[80];       { Email pour transfert }
  ReplyText: String[200];        { Texte de reponse automatique }
  PriorityValue: TMessagePriority; { Priorite a definir }
  SoundFile: String[40];         { Fichier son }
 End;

 { Structure complete d'une regle de filtrage }
 TFilterRule = Record
  ID: Integer;                   { Identifiant unique }
  Name: String[40];              { Nom de la regle }
  Description: String[80];       { Description }
  Enabled: Boolean;              { Regle active }
  Order: Integer;                { Ordre d'execution }
  ApplyToIncoming: Boolean;      { Appliquer aux messages entrants }
  ApplyToOutgoing: Boolean;      { Appliquer aux messages sortants }
  RuleOperator: TRuleOperator;   { Operateur AND/OR }
  Conditions: Array[0..4] of TRuleCondition; { Max 5 conditions }
  ConditionCount: Integer;       { Nombre de conditions }
  Actions: Array[0..2] of TRuleAction; { Max 3 actions }
  ActionCount: Integer;          { Nombre d'actions }
  CreatedDate: LongInt;          { Date de creation }
  LastTriggered: LongInt;        { Derniere execution }
  TriggerCount: LongInt;         { Nombre de fois declenchee }
 End;

 { Etat de la fenetre des regles }
 TRulesWindowState = (
  rwsHidden,                     { Fenetre cachee }
  rwsList,                       { Liste des regles }
  rwsEdit,                       { Edition d'une regle }
  rwsNew,                        { Nouvelle regle }
  rwsConditions,                 { Edition des conditions }
  rwsActions                     { Edition des actions }
 );

 { ============================================================================
   TYPES POUR LA RECHERCHE AVANCEE (TODO 18)
   ============================================================================ }

 { Champs de recherche }
 TSearchField = (
  sfSubject,                     { Recherche dans l'objet }
  sfBody,                        { Recherche dans le corps }
  sfSender,                      { Recherche dans l'expediteur }
  sfRecipient,                   { Recherche dans le destinataire }
  sfAll                          { Recherche dans tous les champs }
 );

 { Etat des filtres de recherche }
 TSearchFilter = Record
  SearchText: String[80];        { Texte a rechercher }
  SearchField: TSearchField;     { Champ de recherche }
  CaseSensitive: Boolean;        { Respecter la casse }
  WholeWord: Boolean;            { Mot entier seulement }
  HasAttachment: Boolean;        { Avec pieces jointes }
  FilterByAttachment: Boolean;   { Filtrer par pieces jointes }
  DateFilterEnabled: Boolean;    { Filtrer par date }
  DateFrom: LongInt;             { Date de debut }
  DateTo: LongInt;               { Date de fin }
  SizeFilterEnabled: Boolean;    { Filtrer par taille }
  MinSize: LongInt;              { Taille minimale }
  MaxSize: LongInt;              { Taille maximale }
  SearchAllFolders: Boolean;     { Rechercher dans tous les dossiers }
 End;

 { Resultat de recherche }
 TSearchResult = Record
  MessageIndex: Integer;         { Index du message }
  MatchPosition: Integer;        { Position de la correspondance }
  MatchLength: Integer;          { Longueur de la correspondance }
  MatchField: TSearchField;      { Champ ou la correspondance a ete trouvee }
  MatchContext: String[80];      { Contexte autour de la correspondance }
 End;

 { Element de l'historique de recherche }
 TSearchHistoryItem = Record
  SearchText: String[80];        { Texte recherche }
  SearchDate: LongInt;           { Date de la recherche }
  ResultCount: Integer;          { Nombre de resultats }
 End;

 { Etat de la fenetre de recherche }
 TSearchWindowState = (
  swsHidden,                     { Fenetre cachee }
  swsSimple,                     { Recherche simple }
  swsAdvanced,                   { Recherche avancee }
  swsResults                     { Affichage des resultats }
 );

 { ============================================================================
   TYPES POUR LA GESTION DES SIGNATURES (TODO 19)
   ============================================================================ }

 { Type de contenu de signature }
 TSignatureContentType = (
  sctPlainText,                  { Texte brut }
  sctHTML,                       { Texte HTML formate }
  sctRichText                    { Texte enrichi }
 );

 { Mode d'insertion de la signature }
 TSignatureInsertMode = (
  simNone,                       { Pas de signature }
  simNewMessages,                { Nouveaux messages seulement }
  simRepliesForwards,            { Reponses et transferts seulement }
  simAll                         { Tous les messages }
 );

 { Position de la signature dans le message }
 TSignaturePosition = (
  spAfterText,                   { Apres le texte du message }
  spBeforeQuote,                 { Avant le texte cite }
  spAtEnd                        { A la fin du message }
 );

 { Structure d'une signature de courriel }
 TEmailSignature = Record
  ID: Integer;                   { Identifiant unique }
  Name: String[40];              { Nom de la signature }
  Description: String[80];       { Description }
  IsDefault: Boolean;            { Signature par defaut }
  AccountID: Integer;            { ID du compte associe (0=tous) }
  ContentType: TSignatureContentType; { Type de contenu }
  PlainText: Array[0..19] of String[80]; { Texte brut (max 20 lignes) }
  PlainTextLines: Integer;       { Nombre de lignes de texte }
  HTMLContent: Array[0..29] of String[80]; { Contenu HTML (max 30 lignes) }
  HTMLContentLines: Integer;     { Nombre de lignes HTML }
  InsertMode: TSignatureInsertMode; { Mode d'insertion }
  Position: TSignaturePosition;  { Position dans le message }
  IncludeSeparator: Boolean;     { Inclure "-- " avant la signature }
  UseForReplies: Boolean;        { Utiliser pour les reponses }
  UseForForwards: Boolean;       { Utiliser pour les transferts }
  ReplySignatureID: Integer;     { ID signature pour reponses (-1=meme) }
  ForwardSignatureID: Integer;   { ID signature pour transferts (-1=meme) }
  CreatedDate: LongInt;          { Date de creation }
  ModifiedDate: LongInt;         { Date de derniere modification }
  IsActive: Boolean;             { Signature active }
 End;

 { Parametres de signature par compte }
 TAccountSignatureSettings = Record
  AccountID: Integer;            { ID du compte }
  DefaultSignatureID: Integer;   { Signature par defaut pour ce compte }
  ReplySignatureID: Integer;     { Signature pour reponses }
  ForwardSignatureID: Integer;   { Signature pour transferts }
  AutoInsert: Boolean;           { Insertion automatique }
  InsertPosition: TSignaturePosition; { Position d'insertion }
 End;

 { Etat de la fenetre d'edition de signature }
 TSignatureWindowState = (
  sigwsHidden,                   { Fenetre cachee }
  sigwsList,                     { Liste des signatures }
  sigwsEdit,                     { Edition d'une signature }
  sigwsNew,                      { Nouvelle signature }
  sigwsPreview                   { Apercu de la signature }
 );

 { Etat de l'editeur de signature }
 TSignatureEditorState = Record
  EditingSignature: TEmailSignature; { Signature en cours d'edition }
  CursorLine: Integer;           { Ligne du curseur }
  CursorCol: Integer;            { Colonne du curseur }
  SelectionStart: Integer;       { Debut de selection (ligne) }
  SelectionEnd: Integer;         { Fin de selection (ligne) }
  IsModified: Boolean;           { Modifications non sauvegardees }
  CurrentTab: Integer;           { Onglet actuel (0=Texte, 1=HTML, 2=Parametres) }
  ScrollOffset: Integer;         { Defilement vertical }
 End;

 { ============================================================================
   TYPES POUR LES NOTIFICATIONS ET ALERTES (TODO 20)
   ============================================================================ }

 { Type d'alerte sonore }
 TSoundAlertType = (
  satNone,                       { Pas de son }
  satSystemBeep,                 { Beep systeme }
  satWAVFile,                    { Fichier WAV personnalise }
  satMelody                      { Melodie integree }
 );

 { Type de notification visuelle }
 TVisualNotificationType = (
  vntNone,                       { Pas de notification visuelle }
  vntTitleFlash,                 { Clignotement de la barre de titre }
  vntTitleBadge,                 { Badge dans la barre de titre }
  vntTrayIcon,                   { Icone dans la barre d'etat }
  vntPopup                       { Fenetre popup }
 );

 { Etat de la notification }
 TNotificationState = (
  nsIdle,                        { En attente }
  nsChecking,                    { Verification en cours }
  nsNewMail,                     { Nouveau message detecte }
  nsError                        { Erreur de verification }
 );

 { Parametres de notification par dossier }
 TFolderNotificationSettings = Record
  FolderID: Integer;             { ID du dossier }
  FolderName: String[40];        { Nom du dossier }
  EnableNotification: Boolean;   { Notifications activees }
  SoundAlert: TSoundAlertType;   { Type d'alerte sonore }
  VisualAlert: TVisualNotificationType; { Type d'alerte visuelle }
  SoundFile: String[80];         { Chemin du fichier WAV }
  PlaySoundOnce: Boolean;        { Jouer le son une seule fois }
 End;

 { Parametres globaux de notification }
 TNotificationSettings = Record
  Enabled: Boolean;              { Notifications activees globalement }
  CheckInterval: Integer;        { Intervalle de verification (secondes) }
  DefaultSoundAlert: TSoundAlertType; { Alerte sonore par defaut }
  DefaultVisualAlert: TVisualNotificationType; { Alerte visuelle par defaut }
  DefaultSoundFile: String[80];  { Fichier WAV par defaut }
  ShowPopupDuration: Integer;    { Duree d'affichage popup (secondes) }
  PopupPosition: Integer;        { Position du popup (0=bas-droite, 1=haut-droite) }
  FlashCount: Integer;           { Nombre de clignotements }
  FlashInterval: Integer;        { Intervalle de clignotement (ms) }
  CheckOnStartup: Boolean;       { Verifier au demarrage }
  PlaySoundRepeat: Boolean;      { Repeter le son }
  MaxPopupMessages: Integer;     { Nombre max de messages dans popup }
 End;

 { Information sur un nouveau message pour notification }
 TNewMailInfo = Record
  AccountID: Integer;            { ID du compte }
  AccountName: String[40];       { Nom du compte }
  FolderID: Integer;             { ID du dossier }
  FolderName: String[40];        { Nom du dossier }
  MessageCount: Integer;         { Nombre de nouveaux messages }
  FirstSender: String[40];       { Expediteur du premier message }
  FirstSubject: String[60];      { Objet du premier message }
  Timestamp: LongInt;            { Horodatage de la notification }
  Displayed: Boolean;            { Notification affichee }
  Acknowledged: Boolean;         { Notification acquittee }
 End;

 { Historique des notifications }
 TNotificationHistoryItem = Record
  Timestamp: LongInt;            { Horodatage }
  AccountName: String[40];       { Nom du compte }
  FolderName: String[40];        { Nom du dossier }
  MessageCount: Integer;         { Nombre de messages }
  Subject: String[60];           { Objet du premier message }
 End;

 { Etat de la fenetre de notification popup }
 TNotificationPopupState = (
  npsHidden,                     { Popup cache }
  npsShowing,                    { Popup en cours d'affichage }
  npsFadingIn,                   { Animation d'apparition }
  npsFadingOut                   { Animation de disparition }
 );

 { Etat de la fenetre de configuration des notifications }
 TNotificationConfigState = (
  ncsHidden,                     { Fenetre cachee }
  ncsGeneral,                    { Onglet parametres generaux }
  ncsFolders,                    { Onglet parametres par dossier }
  ncsSounds,                     { Onglet configuration sons }
  ncsHistory                     { Onglet historique }
 );

 { ============================================================================
   TYPES POUR L'IMPRESSION ET L'APERCU AVANT IMPRESSION (TODO 21)
   ============================================================================ }

 { Port d'imprimante }
 TPrinterPort = (
  ppLPT1,                        { Port LPT1 }
  ppLPT2,                        { Port LPT2 }
  ppLPT3,                        { Port LPT3 }
  ppFile                         { Fichier }
 );

 { Format d'export }
 TExportFormat = (
  efText,                        { Texte brut }
  efHTML,                        { HTML }
  efRTF                          { Rich Text Format }
 );

 { Orientation de la page }
 TPageOrientation = (
  poPortrait,                    { Portrait }
  poLandscape                    { Paysage }
 );

 { Taille de papier }
 TPaperSize = (
  psLetter,                      { Lettre US (8.5 x 11) }
  psLegal,                       { Legal (8.5 x 14) }
  psA4,                          { A4 (210 x 297 mm) }
  psA5                           { A5 (148 x 210 mm) }
 );

 { Configuration des marges (en millimetres) }
 TPrintMargins = Record
  Top: Integer;                  { Marge superieure }
  Bottom: Integer;               { Marge inferieure }
  Left: Integer;                 { Marge gauche }
  Right: Integer;                { Marge droite }
 End;

 { En-tete et pied de page }
 TPrintHeaderFooter = Record
  Left: String[60];              { Texte gauche }
  Center: String[60];            { Texte centre }
  Right: String[60];             { Texte droite }
  Enabled: Boolean;              { Active }
 End;

 { Parametres d'impression }
 TPrintSettings = Record
  Port: TPrinterPort;            { Port d'imprimante }
  OutputFile: String[80];        { Fichier de sortie (si ppFile) }
  ExportFormat: TExportFormat;   { Format d'export }
  PageOrientation: TPageOrientation; { Orientation }
  PaperSize: TPaperSize;         { Taille du papier }
  Margins: TPrintMargins;        { Marges }
  Header: TPrintHeaderFooter;    { En-tete }
  Footer: TPrintHeaderFooter;    { Pied de page }
  PrintHeaders: Boolean;         { Imprimer les en-tetes du message }
  PrintAttachmentList: Boolean;  { Imprimer la liste des pieces jointes }
  FontSize: Integer;             { Taille de police (points) }
  LineSpacing: Integer;          { Interligne (pourcentage, 100 = simple) }
  Copies: Integer;               { Nombre de copies }
  PageNumbers: Boolean;          { Afficher les numeros de page }
  PrintDate: Boolean;            { Afficher la date d'impression }
 End;

 { Contenu d'une page pour l'apercu }
 TPrintPageContent = Record
  Lines: Array[0..59] of String[80]; { Lignes de texte (max 60 par page) }
  LineCount: Integer;            { Nombre de lignes }
  PageNumber: Integer;           { Numero de page }
  HasMore: Boolean;              { Page suivante existe }
 End;

 { Etat de l'apercu avant impression }
 TPrintPreviewState = (
  ppsHidden,                     { Fenetre cachee }
  ppsShowing,                    { Affichage normal }
  ppsZoomed                      { Affichage zoom }
 );

 { Etat de la fenetre de configuration d'impression }
 TPrintConfigState = (
  pcsHidden,                     { Fenetre cachee }
  pcsGeneral,                    { Onglet general }
  pcsMargins,                    { Onglet marges }
  pcsHeaderFooter,               { Onglet en-tetes/pieds de page }
  pcsExport                      { Onglet export }
 );

 { ============================================================================
   TYPES POUR LA SAUVEGARDE ET L'EXPORT (TODO 22)
   ============================================================================ }

 { Format d'export de messages }
 TMessageExportFormat = (
  mefEML,                        { Format EML (RFC 822) }
  mefMBOX,                       { Format MBOX (Unix mailbox) }
  mefText,                       { Texte brut }
  mefHTML                        { HTML }
 );

 { Type de sauvegarde }
 TBackupType = (
  btFull,                        { Sauvegarde complete }
  btMessages,                    { Messages^ uniquement }
  btContacts,                    { Contacts^ uniquement }
  btSettings,                    { Parametres uniquement }
  btAccounts                     { Comptes uniquement }
 );

 { Etat de la fenetre de sauvegarde/restauration }
 TBackupState = (
  bsHidden,                      { Fenetre cachee }
  bsBackupSelect,                { Selection du type de sauvegarde }
  bsBackupProgress,              { Sauvegarde en cours }
  bsBackupComplete,              { Sauvegarde terminee }
  bsRestoreSelect,               { Selection du fichier a restaurer }
  bsRestoreProgress,             { Restauration en cours }
  bsRestoreComplete,             { Restauration terminee }
  bsExportSelect,                { Selection du format d'export }
  bsExportProgress,              { Export en cours }
  bsExportComplete               { Export termine }
 );

 { Options de sauvegarde }
 TBackupOptions = Record
  IncludeMessages: Boolean;      { Inclure les messages }
  IncludeContacts: Boolean;      { Inclure les contacts }
  IncludeAccounts: Boolean;      { Inclure les comptes }
  IncludeSettings: Boolean;      { Inclure les parametres }
  IncludeSignatures: Boolean;    { Inclure les signatures }
  CompressBackup: Boolean;       { Compresser la sauvegarde }
  BackupPath: String[120];       { Chemin de sauvegarde }
  BackupName: String[60];        { Nom du fichier }
 End;

 { Options de restauration }
 TRestoreOptions = Record
  RestoreMessages: Boolean;      { Restaurer les messages }
  RestoreContacts: Boolean;      { Restaurer les contacts }
  RestoreAccounts: Boolean;      { Restaurer les comptes }
  RestoreSettings: Boolean;      { Restaurer les parametres }
  RestoreSignatures: Boolean;    { Restaurer les signatures }
  OverwriteExisting: Boolean;    { Ecraser les donnees existantes }
  RestorePath: String[120];      { Chemin du fichier }
 End;

 { En-tete de fichier de sauvegarde }
 TBackupHeader = Record
  Signature: Array[0..7] of Char; { 'OEBACKUP' }
  Version: Word;                 { Version du format }
  Created: LongInt;              { Date de creation }
  MessageCount: Integer;         { Nombre de messages }
  ContactCount: Integer;         { Nombre de contacts }
  AccountCount: Integer;         { Nombre de comptes }
  HasSettings: Boolean;          { Contient les parametres }
  HasSignatures: Boolean;        { Contient les signatures }
  Reserved: Array[0..15] of Byte; { Reserve pour extension }
 End;

 { Statistiques de sauvegarde/restauration }
 TBackupStats = Record
  TotalItems: Integer;           { Nombre total d'elements }
  ProcessedItems: Integer;       { Elements traites }
  SkippedItems: Integer;         { Elements ignores }
  ErrorCount: Integer;           { Nombre d'erreurs }
  StartTime: LongInt;            { Heure de debut }
  EndTime: LongInt;              { Heure de fin }
  FileSize: LongInt;             { Taille du fichier }
 End;

 { ============================================================================
   TYPES POUR LA CONFIGURATION DES PREFERENCES (TODO 23)
   ============================================================================ }

 { Onglet de preferences actif }
 TPrefsTab = (
  ptGeneral,                     { Onglet General }
  ptReading,                     { Onglet Lecture }
  ptComposing,                   { Onglet Redaction }
  ptConnection,                  { Onglet Connexion }
  ptSecurity                     { Onglet Securite }
 );

 { Langue de l'interface }
 TInterfaceLanguage = (
  ilFrench,                      { Francais (par defaut) }
  ilEnglish,                     { English }
  ilGerman,                      { Deutsch }
  ilItalian,                     { Italiano }
  ilSpanish,                     { Espanol }
  ilPortuguese,                  { Portugues }
  ilSwedish,                     { Svenska }
  ilDanish,                      { Dansk }
  ilJapanese,                    { Nihongo (romaji) }
  ilAlbanian                     { Shqip }
 );

 { Format de composition par defaut }
 TComposeFormat = (
  cfPlainText,                   { Texte brut }
  cfHTML,                        { HTML }
  cfRichText                     { Texte enrichi }
 );

 { Encodage par defaut }
 TDefaultEncoding = (
  deISO8859_1,                   { ISO-8859-1 (Latin-1) }
  deISO8859_15,                  { ISO-8859-15 (Latin-9) }
  deUTF8,                        { UTF-8 }
  deWindows1252,                 { Windows-1252 }
  deASCII                        { US-ASCII }
 );

 { Preferences generales }
 TGeneralPrefs = Record
  Language: TInterfaceLanguage;  { Langue de l'interface }
  DefaultFolder: String[80];     { Dossier par defaut }
  StartMinimized: Boolean;       { Demarrer minimise }
  CheckMailOnStart: Boolean;     { Verifier messages au demarrage }
  EmptyTrashOnExit: Boolean;     { Vider corbeille en quittant }
  ShowSplash: Boolean;           { Afficher ecran d'accueil }
  MinimizeToTray: Boolean;       { Minimiser dans la barre des taches }
  ConfirmExit: Boolean;          { Confirmer la fermeture }
 End;

 { Preferences de lecture }
 TReadingPrefs = Record
  FontName: String[40];          { Nom de la police }
  FontSize: Integer;             { Taille de la police }
  DefaultEncoding: TDefaultEncoding; { Encodage par defaut }
  MarkAsReadDelay: Integer;      { Delai avant marquage lu (secondes) }
  ShowPreviewPane: Boolean;      { Afficher le volet de previsualisation }
  PreviewOnRight: Boolean;       { Volet a droite (sinon en bas) }
  AutoExpandGroups: Boolean;     { Developper automatiquement les groupes }
  ShowHeaders: Boolean;          { Afficher tous les en-tetes }
  UseAlternateRowColor: Boolean; { Couleurs alternees }
 End;

 { Preferences de redaction }
 TComposingPrefs = Record
  DefaultFormat: TComposeFormat; { Format par defaut }
  FontName: String[40];          { Police de redaction }
  FontSize: Integer;             { Taille de police }
  SpellCheckEnabled: Boolean;    { Correcteur actif }
  SpellCheckOnSend: Boolean;     { Verifier avant envoi }
  AutoSaveDrafts: Boolean;       { Sauvegarde auto brouillons }
  AutoSaveInterval: Integer;     { Intervalle (minutes) }
  WrapTextAt: Integer;           { Retour a la ligne (colonnes) }
  IncludeOriginal: Boolean;      { Inclure message original }
  QuotePrefix: String[5];        { Prefixe de citation }
  DefaultSignature: Integer;     { Index signature par defaut }
 End;

 { Preferences de connexion }
 TConnectionPrefs = Record
  CheckInterval: Integer;        { Intervalle de verification (minutes) }
  ConnectionTimeout: Integer;    { Delai de connexion (secondes) }
  MaxRetries: Integer;           { Nombre de tentatives }
  RetryDelay: Integer;           { Delai entre tentatives (secondes) }
  OfflineMode: Boolean;          { Mode hors ligne }
  AutoReconnect: Boolean;        { Reconnexion automatique }
  SavePassword: Boolean;         { Sauvegarder mot de passe }
  UseSSL: Boolean;               { Utiliser SSL/TLS }
  VerifyCertificates: Boolean;   { Verifier les certificats }
 End;

 { Preferences de securite }
 TSecurityPrefs = Record
  WarnOnExternal: Boolean;       { Avertir liens externes }
  BlockExternalImages: Boolean;  { Bloquer images externes }
  WarnOnAttachments: Boolean;    { Avertir pieces jointes }
  BlockedExtensions: String[80]; { Extensions bloquees }
  EnableVirusCheck: Boolean;     { Verification antivirus }
  WarnOnUnencrypted: Boolean;    { Avertir non chiffre }
  EnablePhishingFilter: Boolean; { Filtre anti-hameconnage }
  TrustSenderImages: Boolean;    { Faire confiance aux images des contacts }
  MaxAttachmentSize: LongInt;    { Taille max piece jointe (octets) }
 End;

 { Toutes les preferences utilisateur }
 TUserPreferences = Record
  General: TGeneralPrefs;        { Preferences generales }
  Reading: TReadingPrefs;        { Preferences de lecture }
  Composing: TComposingPrefs;    { Preferences de redaction }
  Connection: TConnectionPrefs;  { Preferences de connexion }
  Security: TSecurityPrefs;      { Preferences de securite }
  Modified: Boolean;             { Preferences modifiees }
 End;

 { ============================================================================
   TYPES POUR LE MODE HORS LIGNE ET SYNCHRONISATION (TODO 24)
   ============================================================================ }

 { Etat de connexion }
 TConnectionState = (
  csOnline,                      { Connecte }
  csOffline,                     { Hors ligne }
  csConnecting,                  { En cours de connexion }
  csDisconnecting,               { En cours de deconnexion }
  csSynchronizing                { En cours de synchronisation }
 );

 { Type d'operation en attente }
 TQueuedOpType = (
  qotSendMessage,                { Envoyer un message }
  qotDeleteMessage,              { Supprimer un message }
  qotMoveMessage,                { Deplacer un message }
  qotMarkAsRead,                 { Marquer comme lu }
  qotMarkAsUnread,               { Marquer comme non lu }
  qotFlagMessage,                { Marquer d'un drapeau }
  qotUnflagMessage               { Retirer le drapeau }
 );

 { Etat d'une operation en file d'attente }
 TQueuedOpState = (
  qosWaiting,                    { En attente }
  qosProcessing,                 { En cours de traitement }
  qosCompleted,                  { Terminee }
  qosFailed                      { Echouee }
 );

 { Operation en file d'attente }
 TQueuedOperation = Record
  OpType: TQueuedOpType;         { Type d'operation }
  State: TQueuedOpState;         { Etat de l'operation }
  MessageID: String[20];         { ID du message concerne }
  TargetFolder: String[40];      { Dossier cible (pour deplacement) }
  QueuedTime: LongInt;           { Heure de mise en file (timestamp) }
  RetryCount: Integer;           { Nombre de tentatives }
  LastError: String[80];         { Derniere erreur }
  Priority: Integer;             { Priorite (0=haute, 9=basse) }
 End;

 { Message en cache local }
 TCachedMessage = Record
  MsgID: String[20];             { Identifiant unique }
  FolderName: String[40];        { Nom du dossier }
  FromName: String[40];          { Nom de l'expediteur }
  FromEmail: String[60];         { Adresse email }
  Subject: String[80];           { Objet }
  DateSort: LongInt;             { Date pour le tri }
  Size: LongInt;                 { Taille en octets }
  IsRead: Boolean;               { Message lu }
  IsFlagged: Boolean;            { Message marque }
  HasAttachment: Boolean;        { Contient des pieces jointes }
  CacheTime: LongInt;            { Heure de mise en cache }
  IsDirty: Boolean;              { Modifie localement }
 End;

 { Dossier en cache }
 TCachedFolder = Record
  Name: String[40];              { Nom du dossier }
  ParentName: String[40];        { Nom du dossier parent }
  MessageCount: Integer;         { Nombre de messages }
  UnreadCount: Integer;          { Messages^ non lus }
  LastSync: LongInt;             { Derniere synchronisation }
  IsDirty: Boolean;              { Modifie localement }
 End;

 { Statistiques de synchronisation }
 TSyncStats = Record
  MessagesSent: Integer;         { Messages^ envoyes }
  MessagesReceived: Integer;     { Messages^ recus }
  MessagesDeleted: Integer;      { Messages^ supprimes }
  MessagesMoved: Integer;        { Messages^ deplaces }
  Errors: Integer;               { Erreurs }
  StartTime: LongInt;            { Debut de la sync }
  EndTime: LongInt;              { Fin de la sync }
 End;

 { ============================================================================
   TYPES POUR LE SUPPORT MULTI-LANGUE (TODO 25)
   ============================================================================ }

 { Langues supportees }
 TLanguage = (
  langFrench,                    { Francais (par defaut) }
  langEnglish,                   { Anglais }
  langGerman,                    { Allemand }
  langItalian,                   { Italien }
  langSpanish,                   { Espagnol }
  langPortuguese,                { Portugais }
  langSwedish,                   { Suedois }
  langDanish,                    { Danois }
  langJapanese,                  { Japonais (romaji) }
  langAlbanian                   { Albanais }
 );

 { Identifiant de chaine traduisible }
 TStringID = (
  { Menu Fichier }
  sidFile, sidNewMessage, sidOpen, sidSave, sidSaveAs,
  sidPrint, sidExit,
  { Menu Edition }
  sidEdit, sidUndo, sidRedo, sidCut, sidCopy, sidPaste,
  sidSelectAll, sidFind,
  { Menu Affichage }
  sidView, sidFolderPane, sidPreviewPane, sidToolbar,
  sidStatusBar, sidRefresh,
  { Menu Message }
  sidMessage, sidReply, sidReplyAll, sidForward, sidDelete,
  sidMarkAsRead, sidMarkAsUnread, sidFlag,
  { Menu Outils }
  sidTools, sidAccounts, sidRules, sidPreferences,
  sidSendReceive,
  { Menu Aide }
  sidHelp, sidContents, sidAbout,
  { Dossiers }
  sidInbox, sidOutbox, sidSentItems, sidDrafts, sidTrash,
  { Interface }
  sidFrom, sidTo, sidSubject, sidDate, sidSize, sidPriority,
  sidAttachment, sidSearch, sidSearchPlaceholder,
  { Boutons }
  sidOK, sidCancel, sidYes, sidNo, sidApply, sidClose,
  { Messages^ }
  sidNoMessages, sidLoading, sidError, sidSuccess,
  sidConfirmDelete, sidMessageSent,
  { Etat connexion }
  sidOnline, sidOffline, sidConnecting, sidSynchronizing,
  { Divers }
  sidNewMail, sidUnreadCount, sidTotalCount,
  sidBytes, sidKB, sidMB
 );

 { Type de colonne pour la liste des messages }
 TColumnType = (ctPriority, ctAttachment, ctFlag, ctFrom, ctSubject, ctDate, ctSize);

 { Ordre de tri }
 TSortOrder = (soNone, soAscending, soDescending);

 { Structure pour un message }
 TMessage = Record
  MsgID: String[20];        { Identifiant unique }
  FromName: String[40];     { Nom de l'expediteur }
  FromEmail: String[60];    { Adresse email }
  ToName: String[40];       { Nom du destinataire }
  ToEmail: String[60];      { Adresse email destinataire }
  CcEmail: String[80];      { Adresse(s) en copie }
  Subject: String[80];      { Objet }
  DateStr: String[10];      { Date au format JJ/MM/AA }
  DateFull: String[25];     { Date complete pour affichage }
  DateSort: LongInt;        { Date pour le tri (secondes depuis 1970) }
  Size: LongInt;            { Taille en octets }
  Priority: TMessagePriority; { Priorite du message }
  HasAttachment: Boolean;   { Contient des pieces jointes }
  IsRead: Boolean;          { Message lu }
  IsFlagged: Boolean;       { Message marque d'un drapeau }
  IsSelected: Boolean;      { Message selectionne }
  Y: Integer;               { Position Y pour le clic }
  Body: Array[0..19] of String[80]; { Corps du message (max 20 lignes) }
  BodyLineCount: Integer;   { Nombre de lignes du corps }
  { Pieces jointes (TODO 13) }
  Attachments: Array[0..9] of TAttachment; { Liste des pieces jointes (max 10) }
  AttachmentCount: Integer;  { Nombre de pieces jointes }
 End;

 { Orientation du volet de previsualisation }
 TPreviewOrientation = (poHorizontal, poVertical);

 { ============================================================================
   TYPES ET STRUCTURES POUR LE CLIENT IMAP (RFC 3501)
   ============================================================================ }

 { Etat de la connexion IMAP }
 TIMAPState = (
  isDisconnected,  { Non connecte }
  isConnected,     { Connecte, pas encore authentifie }
  isAuthenticated, { Authentifie, pas de boite selectionnee }
  isSelected,      { Boite aux lettres selectionnee }
  isLogout         { Deconnexion en cours }
 );

 { Type de reponse IMAP }
 TIMAPResponseType = (
  irOK,            { Commande reussie }
  irNO,            { Commande echouee }
  irBAD,           { Commande invalide ou erreur de syntaxe }
  irContinue,      { Continuation requise (+) }
  irUntagged,      { Reponse non taguee (*) }
  irTagged,        { Reponse taguee }
  irBYE            { Serveur ferme la connexion }
 );

 { Type d'authentification IMAP }
 TIMAPAuthMethod = (
  iamLOGIN,        { Authentification LOGIN }
  iamPLAIN,        { Authentification PLAIN (Base64) }
  iamCRAMMD5,      { CRAM-MD5 (non implemente) }
  iamOAUTH2        { OAuth2 (non implemente) }
 );

 { Drapeaux IMAP pour les messages }
 TIMAPFlags = Record
  Seen: Boolean;      { \Seen - message lu }
  Answered: Boolean;  { \Answered - message repondu }
  Flagged: Boolean;   { \Flagged - message marque }
  Deleted: Boolean;   { \Deleted - message supprime }
  Draft: Boolean;     { \Draft - brouillon }
  Recent: Boolean;    { \Recent - message recent (lecture seule) }
 End;

 { Informations sur une boite aux lettres IMAP }
 TIMAPMailbox = Record
  Name: String[80];        { Nom de la boite }
  Delimiter: Char;         { Delimiteur de hierarchie }
  Exists: LongInt;         { Nombre de messages }
  Recent: LongInt;         { Nombre de messages recents }
  Unseen: LongInt;         { Numero du premier message non lu }
  UIDValidity: LongInt;    { Validite des UIDs }
  UIDNext: LongInt;        { Prochain UID }
  Flags: String[80];       { Drapeaux disponibles }
  PermanentFlags: String[80]; { Drapeaux permanents }
  ReadOnly: Boolean;       { Boite en lecture seule (EXAMINE) }
 End;

 { Structure d'une enveloppe de message IMAP }
 TIMAPEnvelope = Record
  MsgDate: String[30];     { Date du message }
  Subject: String[80];     { Objet }
  FromName: String[40];    { Nom de l'expediteur }
  FromEmail: String[60];   { Email de l'expediteur }
  ToName: String[40];      { Nom du destinataire }
  ToEmail: String[60];     { Email du destinataire }
  CcEmail: String[80];     { Emails en copie }
  ReplyTo: String[60];     { Adresse de reponse }
  MessageID: String[80];   { Message-ID }
  InReplyTo: String[80];   { In-Reply-To }
 End;

 { Structure pour un message IMAP recupere }
 TIMAPMessage = Record
  UID: LongInt;            { UID unique du message }
  SeqNum: LongInt;         { Numero de sequence }
  Flags: TIMAPFlags;       { Drapeaux du message }
  Size: LongInt;           { Taille en octets }
  Envelope: TIMAPEnvelope; { Enveloppe du message }
  BodyLoaded: Boolean;     { Corps charge en memoire }
 End;

 { Client IMAP complet }
 TIMAPClient = Record
  { Configuration de connexion }
  Host: String[80];        { Nom du serveur }
  Port: Integer;           { Port (993 pour IMAPS, 143 pour IMAP) }
  Username: String[60];    { Nom d'utilisateur }
  Password: String[40];    { Mot de passe }
  UseSSL: Boolean;         { Utiliser TLS/SSL }

  { Etat de la connexion }
  State: TIMAPState;       { Etat actuel }
  TagCounter: LongInt;     { Compteur de tags }
  LastTag: String[10];     { Dernier tag envoye }
  LastError: String[80];   { Derniere erreur }
  Capabilities: String[200]; { Capacites du serveur }

  { Boite aux lettres courante }
  CurrentMailbox: TIMAPMailbox;
  IsMailboxSelected: Boolean;

  { Support IDLE }
  IdleSupported: Boolean;  { Serveur supporte IDLE }
  IdleActive: Boolean;     { IDLE actuellement actif }

  { Etat du transport natif; la socket est geree dans TMailConnection. }
  Connected: Boolean;
  SocketHandle: Integer;
 End;

 { Structure pour une reponse IMAP parsee }
 TIMAPResponse = Record
  ResponseType: TIMAPResponseType;
  Tag: String[10];         { Tag de la commande }
  StatusCode: String[20];  { Code de statut (OK, NO, BAD) }
  Text: String[200];       { Texte de la reponse }
  Data: String[255];       { Donnees additionnelles }
  HasData: Boolean;        { Contient des donnees }
 End;

 { ============================================================================
   TYPES ET STRUCTURES POUR LE CLIENT POP3 (RFC 1939)
   ============================================================================ }

 { Etat de la connexion POP3 }
 TPOP3State = (
  psDisconnected,    { Non connecte }
  psAuthorization,   { Etat AUTHORIZATION - authentification requise }
  psTransaction,     { Etat TRANSACTION - commandes disponibles }
  psUpdate           { Etat UPDATE - deconnexion en cours }
 );

 { Type de reponse POP3 }
 TPOP3ResponseType = (
  prOK,              { +OK - Commande reussie }
  prERR              { -ERR - Commande echouee }
 );

 { Type d'authentification POP3 }
 TPOP3AuthMethod = (
  pamUSERPASS,       { Authentification USER/PASS }
  pamAPOP            { Authentification APOP (MD5) }
 );

 { Structure pour les statistiques de la boite POP3 }
 TPOP3Stats = Record
  MessageCount: LongInt;   { Nombre de messages }
  TotalSize: LongInt;      { Taille totale en octets }
 End;

 { Structure pour un element de la liste POP3 }
 TPOP3ListItem = Record
  MsgNum: Integer;         { Numero du message }
  Size: LongInt;           { Taille en octets }
  UIDL: String[70];        { Identifiant unique (UIDL) }
  Deleted: Boolean;        { Marque pour suppression }
 End;

 { Structure pour un message POP3 }
 TPOP3Message = Record
  MsgNum: Integer;         { Numero du message }
  Size: LongInt;           { Taille en octets }
  UIDL: String[70];        { Identifiant unique }
  FromName: String[40];    { Nom de l'expediteur }
  FromEmail: String[60];   { Email de l'expediteur }
  ToEmail: String[60];     { Email du destinataire }
  Subject: String[80];     { Objet }
  MsgDate: String[30];     { Date du message }
  HeadersOnly: Boolean;    { Seulement les en-tetes charges }
  Deleted: Boolean;        { Marque pour suppression }
 End;

 { Client POP3 complet }
 TPOP3Client = Record
  { Configuration de connexion }
  Host: String[80];        { Nom du serveur }
  Port: Integer;           { Port (995 pour POP3S, 110 pour POP3) }
  Username: String[60];    { Nom d'utilisateur }
  Password: String[40];    { Mot de passe }
  UseSSL: Boolean;         { Utiliser TLS/SSL }

  { Etat de la connexion }
  State: TPOP3State;       { Etat actuel }
  LastError: String[80];   { Derniere erreur }
  ServerGreeting: String[100]; { Message de bienvenue (contient timestamp APOP) }
  APOPTimestamp: String[80];   { Timestamp pour APOP }

  { Statistiques de la boite }
  Stats: TPOP3Stats;

  { Options }
  LeaveOnServer: Boolean;  { Laisser les messages sur le serveur }
  HeadersOnly: Boolean;    { Telecharger seulement les en-tetes }
  DeleteAfterDays: Integer; { Supprimer apres X jours (0 = jamais) }

  { Etat du transport natif; la socket est geree dans TMailConnection. }
  Connected: Boolean;
  SocketHandle: Integer;
 End;

 { Structure pour une reponse POP3 parsee }
 TPOP3Response = Record
  ResponseType: TPOP3ResponseType;
  Text: String[200];       { Texte de la reponse }
  Data: String[255];       { Donnees additionnelles }
  HasMultiline: Boolean;   { Reponse multiligne }
 End;

 { ============================================================================
   TYPES ET STRUCTURES POUR LE CLIENT SMTP (RFC 5321)
   ============================================================================ }

 { Etat de la connexion SMTP }
 TSMTPState = (
  ssDisconnected,    { Non connecte }
  ssConnected,       { Connecte, en attente de EHLO }
  ssAuthenticated,   { Authentifie, pret a envoyer }
  ssMailFrom,        { MAIL FROM envoye }
  ssRcptTo,          { Au moins un RCPT TO accepte }
  ssData,            { En mode DATA }
  ssQuit             { QUIT envoye, deconnexion en cours }
 );

 { Code de reponse SMTP (classe) }
 TSMTPResponseClass = (
  srcPositivePrelim,     { 1xx - Preliminaire positif }
  srcPositiveComplete,   { 2xx - Completion positive }
  srcPositiveInterm,     { 3xx - Intermediaire positif }
  srcNegativeTransient,  { 4xx - Erreur temporaire }
  srcNegativePermanent,  { 5xx - Erreur permanente }
  srcUnknown             { Classe inconnue }
 );

 { Type d'authentification SMTP }
 TSMTPAuthMethod = (
  samNone,           { Pas d'authentification }
  samPLAIN,          { Authentification PLAIN (RFC 4616) }
  samLOGIN,          { Authentification LOGIN }
  samCRAMMD5         { Authentification CRAM-MD5 (RFC 2195) }
 );

 { Extensions SMTP supportees (EHLO) }
 TSMTPExtensions = Record
  STARTTLS: Boolean;       { STARTTLS supporte }
  AUTH_PLAIN: Boolean;     { AUTH PLAIN supporte }
  AUTH_LOGIN: Boolean;     { AUTH LOGIN supporte }
  AUTH_CRAM_MD5: Boolean;  { AUTH CRAM-MD5 supporte }
  EIGHTBITMIME: Boolean;   { 8BITMIME supporte }
  SIZE: LongInt;           { Taille maximale message (0 = non limite) }
  PIPELINING: Boolean;     { PIPELINING supporte }
  DSN: Boolean;            { Delivery Status Notification supporte }
 End;

 { Structure pour un destinataire SMTP }
 TSMTPRecipient = Record
  Email: String[60];       { Adresse email }
  Accepted: Boolean;       { Accepte par le serveur }
  ErrorMsg: String[80];    { Message d'erreur si refuse }
 End;

 { Client SMTP complet }
 TSMTPClient = Record
  { Configuration de connexion }
  Host: String[80];        { Nom du serveur }
  Port: Integer;           { Port (465 pour SMTPS, 587 pour submission) }
  Username: String[60];    { Nom d'utilisateur }
  Password: String[40];    { Mot de passe }
  UseSSL: Boolean;         { Utiliser TLS/SSL implicite }
  UseSTARTTLS: Boolean;    { Utiliser STARTTLS }

  { Etat de la connexion }
  State: TSMTPState;       { Etat actuel }
  LastError: String[80];   { Derniere erreur }
  LastCode: Integer;       { Dernier code de reponse }
  ServerGreeting: String[100]; { Message de bienvenue }
  ServerDomain: String[60];    { Domaine du serveur (EHLO) }

  { Extensions supportees }
  Extensions: TSMTPExtensions;

  { Options d'authentification }
  AuthMethod: TSMTPAuthMethod;  { Methode d'authentification utilisee }
  Authenticated: Boolean;       { Est authentifie }

  { Message en cours d'envoi }
  MailFrom: String[60];    { Expediteur (MAIL FROM) }
  RcptCount: Integer;      { Nombre de destinataires }
  RcptAccepted: Integer;   { Nombre de destinataires acceptes }

  { Etat du transport natif; la socket est geree dans TMailConnection. }
  Connected: Boolean;
  SocketHandle: Integer;
  TLSActive: Boolean;      { TLS actif (apres STARTTLS) }
 End;

 { Structure pour une reponse SMTP parsee }
 TSMTPResponse = Record
  Code: Integer;           { Code numerique (250, 354, 550, etc.) }
  ResponseClass: TSMTPResponseClass; { Classe de reponse }
  Text: String[200];       { Texte de la reponse }
  IsMultiline: Boolean;    { Reponse multiligne }
  IsContinue: Boolean;     { Continuation (code-) }
 End;

 { Structure pour un message SMTP a envoyer }
 TSMTPMessage = Record
  From: String[60];        { Expediteur }
  FromName: String[40];    { Nom de l'expediteur }
  Recipients: Array[0..9] Of TSMTPRecipient; { Destinataires (TO, CC) }
  RecipientCount: Integer; { Nombre de destinataires }
  Subject: String[80];     { Sujet }
  Body: String[255];       { Corps du message (simplifie) }
  ContentType: String[40]; { Type de contenu }
  CharSet: String[20];     { Jeu de caracteres }
 End;

 { Structure pour une colonne de la liste des messages }
 TColumnHeader = Record
  ColType: TColumnType;     { Type de colonne }
  Title: String[15];        { Titre de la colonne }
  X: Integer;               { Position X }
  Width: Integer;           { Largeur de la colonne }
  Visible: Boolean;         { Colonne affichee }
  Sortable: Boolean;        { Triable ou non }
 End;

 { ============================================================================
   TYPES ET STRUCTURES POUR LE GESTIONNAIRE DE COMPTES (TODO 11)
   ============================================================================ }

 { Type de serveur entrant }
 TIncomingServerType = (istIMAP, istPOP3);

 { Type de securite de connexion }
 TConnectionSecurity = (csNone, csSSL, csSTARTTLS);

 { Etape de l'assistant de configuration de compte }
 TAccountWizardStep = (
  awsWelcome,          { Page d'accueil }
  awsAccountInfo,      { Informations du compte (nom, email) }
  awsIncomingServer,   { Serveur entrant (IMAP/POP3) }
  awsOutgoingServer,   { Serveur sortant (SMTP) }
  awsTestConnection,   { Test de connexion }
  awsComplete          { Configuration terminee }
 );

 { Resultat du test de connexion }
 TConnectionTestResult = (
  ctrNotTested,        { Pas encore teste }
  ctrTesting,          { Test en cours }
  ctrSuccess,          { Connexion reussie }
  ctrFailedIncoming,   { Echec serveur entrant }
  ctrFailedOutgoing,   { Echec serveur sortant }
  ctrFailedAuth,       { Echec authentification }
  ctrFailedNetwork     { Echec reseau }
 );

 { Structure complete d'un compte de messagerie }
 TEmailAccount = Record
  { Informations generales }
  AccountName: String[40];     { Nom du compte affiche dans l'interface }
  DisplayName: String[40];     { Nom affiche dans les messages envoyes }
  EmailAddress: String[60];    { Adresse email }
  Organization: String[40];    { Organisation (optionnel) }
  ReplyToAddress: String[60];  { Adresse de reponse (optionnel) }

  { Serveur entrant }
  IncomingType: TIncomingServerType;  { IMAP ou POP3 }
  IncomingHost: String[80];    { Nom du serveur entrant }
  IncomingPort: Integer;       { Port du serveur entrant }
  IncomingSecurity: TConnectionSecurity; { Type de securite }
  IncomingUsername: String[60]; { Nom d'utilisateur }
  IncomingPassword: String[40]; { Mot de passe (chiffre en XOR) }
  IncomingAuthMethod: Byte;    { Methode d'authentification (0=AUTO) }

  { Options POP3 specifiques }
  POP3LeaveOnServer: Boolean;  { Laisser les messages sur le serveur }
  POP3DeleteAfterDays: Integer; { Supprimer apres X jours (0=jamais) }
  POP3HeadersOnly: Boolean;    { Telecharger seulement les en-tetes }

  { Serveur sortant (SMTP) }
  OutgoingHost: String[80];    { Nom du serveur SMTP }
  OutgoingPort: Integer;       { Port du serveur SMTP }
  OutgoingSecurity: TConnectionSecurity; { Type de securite }
  OutgoingUsername: String[60]; { Nom d'utilisateur SMTP }
  OutgoingPassword: String[40]; { Mot de passe SMTP (chiffre en XOR) }
  OutgoingAuthRequired: Boolean; { Authentification requise }
  OutgoingUseSameAuth: Boolean;  { Utiliser les memes identifiants que entrant }

  { Etat du compte }
  IsActive: Boolean;           { Compte actif }
  IsDefault: Boolean;          { Compte par defaut }
  LastConnectionTest: TConnectionTestResult; { Resultat du dernier test }
  CheckIntervalMins: Integer;  { Intervalle de verification (minutes) }
 End;

 { Rendez-vous et reunions : heures locales dans le calendrier. }
 TRibbonButton = Record
  X,Y,W,H,MenuItem,Group: Integer;
 End;
 TCalendarEvent = Record
  ID,Sequence: LongInt;
  IsMeeting,InvitationSent: Boolean;
  Title,Location,UID,Organizer: String[80];
  StartDate,EndDate: String[10];
  StartTime,EndTime: String[5];
  Participants,Notes: String[255];
 End;
 TEventGUID = Record A: LongWord; B,C: Word; D: Array[0..7] Of Byte; End;
 TEventMoment =  Real ;
 TEventSystemTime = Record Year,Month,WeekDay,Day,Hour,Minute,Second,Millis: Word; End;

 { Structure pour un champ de saisie dans une boite de dialogue }
 TInputField = Record
  X, Y: Integer;               { Position }
  Width: Integer;              { Largeur en pixels }
  MaxLen: Integer;             { Longueur maximale du texte }
  Value: String[80];           { Valeur actuelle }
  IsPassword: Boolean;         { Masquer le texte }
  IsFocused: Boolean;          { Champ actif }
  CursorPos: Integer;          { Position du curseur }
  Label_: String[30];          { Etiquette du champ }
 End;

 { Structure pour un bouton radio dans une boite de dialogue }
 TRadioButton = Record
  X, Y: Integer;               { Position }
  Label_: String[30];          { Etiquette }
  Checked: Boolean;            { Selectionne }
  GroupID: Integer;            { ID du groupe de boutons radio }
 End;

 { Structure pour une case a cocher }
 TCheckBox = Record
  X, Y: Integer;               { Position }
  Label_: String[40];          { Etiquette }
  Checked: Boolean;            { Cochee }
 End;

 { ============================================================================
   TYPES ET STRUCTURES POUR LE COMPOSITEUR DE MESSAGES (TODO 12)
   ============================================================================ }

 { Options de formatage du texte }
 TTextFormat = Record
  Bold: Boolean;               { Texte en gras }
  Italic: Boolean;             { Texte en italique }
  Underline: Boolean;          { Texte souligne }
  FontColor: Word;             { Couleur du texte }
 End;

 { Structure pour une ligne de texte dans l'editeur }
 TEditorLine = Record
  Text: String[250];           { Contenu de la ligne }
  Format: TTextFormat;         { Formatage de la ligne }
 End;

 { Etat du compositeur de messages }
 TComposerState = (
  csNew,                       { Nouveau message }
  csReply,                     { Reponse }
  csReplyAll,                  { Reponse a tous }
  csForward,                   { Transfert }
  csDraft                      { Brouillon }
 );

 { Structure complete du compositeur de messages }
 TMessageComposer = Record
  { Champs d'en-tete }
  ToField: String[250];        { Destinataires }
  CcField: String[250];        { Copie carbone }
  BccField: String[250];       { Copie carbone invisible }
  SubjectField: String[80];    { Objet }
  AccountIndex: Integer;      { -1: compte du dossier ou compte par defaut }

  { Corps du message }
  Lines: Array[0..499] of TEditorLine; { Lignes de texte (max 500) }
  LineCount: Integer;          { Nombre de lignes }
  CursorX: Integer;            { Position X du curseur (caractere) }
  CursorY: Integer;            { Position Y du curseur (ligne) }
  ScrollX: Integer;            { Defilement horizontal }
  ScrollY: Integer;            { Defilement vertical }
  SelectStartX, SelectStartY: Integer; { Debut de selection }
  SelectEndX, SelectEndY: Integer;     { Fin de selection }
  HasSelection: Boolean;       { Selection active }

  { Formatage actuel }
  CurrentFormat: TTextFormat;  { Format applique aux nouvelles saisies }

  { Etat }
  State: TComposerState;       { Etat du compositeur }
  Modified: Boolean;           { Message modifie }
  OriginalMsgID: String[20];   { ID du message original (reponse/transfert) }

  { Pieces jointes du message (TODO 13) }
  Attachments: Array[0..19] of TAttachment; { Liste des pieces jointes }
  AttachmentCount: Integer;    { Nombre de pieces jointes }
 End;

Const
 { Identifiants des commandes de menu }
 CMD_FILE_NEW      = 101;
 CMD_FILE_OPEN     = 102;
 CMD_FILE_SAVE     = 103;
 CMD_FILE_SAVEAS   = 104;
 CMD_FILE_PRINT    = 105;
 CMD_FILE_EXIT     = 106;

 CMD_EDIT_UNDO     = 201;
 CMD_EDIT_CUT      = 202;
 CMD_EDIT_COPY     = 203;
 CMD_EDIT_PASTE    = 204;
 CMD_EDIT_SELECTALL= 205;

 CMD_VIEW_CALENDAR = 307;
 CMD_VIEW_MAIL = 308;
 CMD_EVENT_NEW = 312;
 CMD_EVENT_MEETING = 313;
 CMD_EVENT_AGENDA = 314;
 CMD_CAL_PREVIOUS = 309;
 CMD_CAL_NEXT = 310;
 CMD_CAL_TODAY = 311;
 CMD_VIEW_PREVIEW  = 301;
 CMD_VIEW_SORTBY   = 302;
 CMD_VIEW_COLUMNS  = 303;
 CMD_VIEW_REFRESH  = 304;
 CMD_VIEW_PREVIEW_ORIENT = 305; { Basculer orientation horizontal/vertical }
 CMD_VIEW_PREVIEW_SHOW   = 306; { Afficher/masquer volet de previsualisation }

 CMD_TOOLS_ACCOUNTS= 401;
 CMD_TOOLS_OPTIONS = 402;
 CMD_TOOLS_RULES   = 403;

 CMD_MSG_NEW       = 501;
 CMD_MSG_REPLY     = 502;
 CMD_MSG_REPLYALL  = 503;
 CMD_MSG_FORWARD   = 504;
 CMD_MSG_DELETE    = 505;

 CMD_HELP_ABOUT    = 601;
 CMD_HELP_HELP     = 602;

 { Commandes de barre d'outils }
 CMD_TB_SENDRECV   = 701;
 CMD_TB_ADDRESSBOOK= 702;

 { Nombre maximum de menus dans la barre }
 MAX_MENUS = 6;

 { Nombre maximum de boutons dans la barre d'outils }
 MAX_TOOLBAR_BUTTONS = 12;

 { Temps d'affichage de l'infobulle (ms) }
 TOOLTIP_DELAY = 500;

 { Nombre maximum de dossiers dans l'arbre }
 MAX_FOLDERS = 30;

 { Hauteur d'un noeud dans l'arbre }
 FOLDER_NODE_HEIGHT = 16;

 { Indentation par niveau }
 FOLDER_INDENT = 16;

 { Nombre maximum de messages dans la liste }
 MAX_MESSAGES = 100;

 { Nombre maximum de colonnes }
 MAX_COLUMNS = 7;

 { Hauteur d'une ligne de message }
 MESSAGE_ROW_HEIGHT = 16;

 { Largeur de l'en-tete de colonne }
 COLUMN_HEADER_HEIGHT = 18;

 { Constantes pour le volet de previsualisation }
 PREVIEW_LINE_HEIGHT = 14;    { Hauteur d'une ligne de texte }
 PREVIEW_SCROLLBAR_WIDTH = 14; { Largeur de la barre de defilement }
 PREVIEW_SCROLL_STEP = 3;     { Lignes a faire defiler par clic molette }
 PREVIEW_HEADER_LINES = 5;    { Nombre de lignes d'en-tete (De, A, Cc, Date, Objet) }
 PREVIEW_MIN_HEIGHT = 80;     { Hauteur minimale du volet }

 { ============================================================================
   CONSTANTES POUR LE CLIENT IMAP (RFC 3501)
   ============================================================================ }

 { Ports IMAP standard }
 IMAP_PORT = 143;          { Port IMAP standard }
 IMAPS_PORT = 993;         { Port IMAP sur SSL/TLS }

 { Tailles maximales }
 IMAP_MAX_RESPONSE_SIZE = 4096;   { Taille max d'une reponse }
 IMAP_MAX_MESSAGES = 100;         { Nombre max de messages a charger }
 IMAP_BUFFER_SIZE = 1024;         { Taille du buffer de lecture }

 { Timeouts en millisecondes }
 IMAP_CONNECT_TIMEOUT = 30000;    { Timeout de connexion }
 IMAP_READ_TIMEOUT = 60000;       { Timeout de lecture }
 IMAP_IDLE_TIMEOUT = 1680000;     { Timeout IDLE (28 minutes RFC) }

 { Drapeaux IMAP comme chaines }
 IMAP_FLAG_SEEN = '\Seen';
 IMAP_FLAG_ANSWERED = '\Answered';
 IMAP_FLAG_FLAGGED = '\Flagged';
 IMAP_FLAG_DELETED = '\Deleted';
 IMAP_FLAG_DRAFT = '\Draft';
 IMAP_FLAG_RECENT = '\Recent';

 { Codes de retour IMAP }
 IMAP_OK = 0;
 IMAP_ERR_CONNECT = -1;
 IMAP_ERR_AUTH = -2;
 IMAP_ERR_SELECT = -3;
 IMAP_ERR_FETCH = -4;
 IMAP_ERR_STORE = -5;
 IMAP_ERR_COPY = -6;
 IMAP_ERR_TIMEOUT = -7;
 IMAP_ERR_NETWORK = -8;
 IMAP_ERR_PROTOCOL = -9;

 { ============================================================================
   CONSTANTES POUR LE CLIENT POP3 (RFC 1939)
   ============================================================================ }

 { Ports POP3 standard }
 POP3_PORT = 110;          { Port POP3 standard }
 POP3S_PORT = 995;         { Port POP3 sur SSL/TLS }

 { Tailles maximales }
 POP3_MAX_RESPONSE_SIZE = 4096;   { Taille max d'une reponse }
 POP3_MAX_MESSAGES = 100;         { Nombre max de messages a charger }
 POP3_BUFFER_SIZE = 1024;         { Taille du buffer de lecture }
 POP3_MAX_LINE_LENGTH = 998;      { Longueur max d'une ligne (RFC 1939) }

 { Timeouts en millisecondes }
 POP3_CONNECT_TIMEOUT = 30000;    { Timeout de connexion }
 POP3_READ_TIMEOUT = 60000;       { Timeout de lecture }

 { Codes de retour POP3 }
 POP3_OK = 0;
 POP3_ERR_CONNECT = -1;
 POP3_ERR_AUTH = -2;
 POP3_ERR_STAT = -3;
 POP3_ERR_LIST = -4;
 POP3_ERR_RETR = -5;
 POP3_ERR_DELE = -6;
 POP3_ERR_TOP = -7;
 POP3_ERR_UIDL = -8;
 POP3_ERR_TIMEOUT = -9;
 POP3_ERR_NETWORK = -10;
 POP3_ERR_PROTOCOL = -11;

 { ============================================================================
   CONSTANTES POUR LE CLIENT SMTP (RFC 5321)
   ============================================================================ }

 { Ports SMTP standard }
 SMTP_PORT = 25;           { Port SMTP standard (non recommande) }
 SMTP_SUBMISSION_PORT = 587; { Port de soumission (STARTTLS) }
 SMTPS_PORT = 465;         { Port SMTP sur SSL/TLS implicite }

 { Tailles maximales }
 SMTP_MAX_RESPONSE_SIZE = 4096;   { Taille max d'une reponse }
 SMTP_BUFFER_SIZE = 1024;         { Taille du buffer de lecture }
 SMTP_MAX_LINE_LENGTH = 998;      { Longueur max d'une ligne (RFC 5321) }
 SMTP_MAX_RECIPIENTS = 100;       { Nombre max de destinataires }

 { Timeouts en millisecondes }
 SMTP_CONNECT_TIMEOUT = 30000;    { Timeout de connexion }
 SMTP_READ_TIMEOUT = 300000;      { Timeout de lecture (5 min pour DATA) }
 SMTP_GREETING_TIMEOUT = 300000;  { Timeout pour le greeting }

 { Codes de reponse SMTP (principaux) }
 SMTP_CODE_READY = 220;           { Service ready }
 SMTP_CODE_CLOSING = 221;         { Closing connection }
 SMTP_CODE_AUTH_OK = 235;         { Authentication successful }
 SMTP_CODE_OK = 250;              { Requested action completed }
 SMTP_CODE_USER_NOT_LOCAL = 251;  { User not local, will forward }
 SMTP_CODE_AUTH_CONTINUE = 334;   { Auth continuation }
 SMTP_CODE_START_MAIL = 354;      { Start mail input }
 SMTP_CODE_NOT_AVAILABLE = 421;   { Service not available }
 SMTP_CODE_MAILBOX_BUSY = 450;    { Mailbox unavailable (busy) }
 SMTP_CODE_LOCAL_ERROR = 451;     { Local error }
 SMTP_CODE_INSUFFICIENT = 452;    { Insufficient storage }
 SMTP_CODE_SYNTAX_ERROR = 500;    { Syntax error }
 SMTP_CODE_PARAM_ERROR = 501;     { Parameter syntax error }
 SMTP_CODE_NOT_IMPLEMENTED = 502; { Command not implemented }
 SMTP_CODE_BAD_SEQUENCE = 503;    { Bad sequence of commands }
 SMTP_CODE_PARAM_NOT_IMPL = 504;  { Parameter not implemented }
 SMTP_CODE_AUTH_REQUIRED = 530;   { Authentication required }
 SMTP_CODE_AUTH_FAILED = 535;     { Authentication failed }
 SMTP_CODE_MAILBOX_NOT_FOUND = 550; { Mailbox not found }
 SMTP_CODE_USER_NOT_LOCAL_ERR = 551; { User not local }
 SMTP_CODE_EXCEEDED_STORAGE = 552;   { Exceeded storage }
 SMTP_CODE_MAILBOX_NAME_ERR = 553;   { Mailbox name not allowed }
 SMTP_CODE_TRANSACTION_FAILED = 554; { Transaction failed }

 { Codes de retour des fonctions SMTP }
 SMTP_OK = 0;
 SMTP_ERR_CONNECT = -1;
 SMTP_ERR_EHLO = -2;
 SMTP_ERR_STARTTLS = -3;
 SMTP_ERR_AUTH = -4;
 SMTP_ERR_MAIL_FROM = -5;
 SMTP_ERR_RCPT_TO = -6;
 SMTP_ERR_DATA = -7;
 SMTP_ERR_SEND = -8;
 SMTP_ERR_QUIT = -9;
 SMTP_ERR_TIMEOUT = -10;
 SMTP_ERR_NETWORK = -11;
 SMTP_ERR_PROTOCOL = -12;
 SMTP_ERR_NO_RECIPIENTS = -13;
 SMTP_ERR_TLS = -14;

 { ============================================================================
   CONSTANTES POUR LE GESTIONNAIRE DE COMPTES (TODO 11)
   ============================================================================ }

 { Nombre maximum de comptes de messagerie }
 MAX_EMAIL_ACCOUNTS = 10;

 { Dimensions de la boite de dialogue de gestion des comptes }
 DIALOG_WIDTH = 500;
 DIALOG_HEIGHT = 350;

 { Dimensions des elements de dialogue }
 DIALOG_BUTTON_WIDTH = 80;
 DIALOG_BUTTON_HEIGHT = 22;
 DIALOG_INPUT_HEIGHT = 18;
 DIALOG_LABEL_HEIGHT = 14;
 DIALOG_MARGIN = 10;
 DIALOG_SPACING = 6;

 { Cle de chiffrement XOR pour les mots de passe }
 PASSWORD_XOR_KEY = $A5;

 { Ports par defaut selon le type de serveur }
 DEFAULT_IMAP_PORT = 143;
 DEFAULT_IMAPS_PORT = 993;
 DEFAULT_POP3_PORT = 110;
 DEFAULT_POP3S_PORT = 995;
 DEFAULT_SMTP_PORT = 25;
 DEFAULT_SMTP_SUBMISSION_PORT = 587;
 DEFAULT_SMTPS_PORT = 465;

 { ============================================================================
   CONSTANTES POUR LE COMPOSITEUR DE MESSAGES (TODO 12)
   ============================================================================ }

 { Dimensions de la fenetre du compositeur }
 COMPOSER_WIDTH = 550;
 COMPOSER_HEIGHT = 400;

 { Zones de la fenetre du compositeur }
 COMPOSER_HEADER_HEIGHT = 120;    { Zone des champs d'en-tete }
 COMPOSER_TOOLBAR_HEIGHT = 28;    { Barre d'outils de formatage }
 COMPOSER_FIELD_HEIGHT = 20;      { Hauteur d'un champ de saisie }
 COMPOSER_FIELD_SPACING = 26;     { Espacement entre champs }
 COMPOSER_LABEL_WIDTH = 50;       { Largeur des etiquettes }

 { Identifiants des champs du compositeur }
 COMP_FIELD_TO = 0;
 COMP_FIELD_CC = 1;
 COMP_FIELD_BCC = 2;
 COMP_FIELD_SUBJECT = 3;
 COMP_FIELD_BODY = 4;

 { Nombre max de lignes dans l'editeur }
 COMPOSER_MAX_LINES = 500;

 { Largeur max visible dans l'editeur }
 COMPOSER_EDITOR_VISIBLE_COLS = 70;
 COMPOSER_EDITOR_VISIBLE_ROWS = 12;

 { Couleurs de formatage disponibles }
 FORMAT_COLOR_BLACK = 0;
 FORMAT_COLOR_RED = 4;
 FORMAT_COLOR_GREEN = 2;
 FORMAT_COLOR_BLUE = 1;

 { ============================================================================
   CONSTANTES POUR LES PIECES JOINTES (TODO 13)
   ============================================================================ }

 { Nombre maximum de pieces jointes par message }
 MAX_ATTACHMENTS = 20;

 { Taille maximale totale des pieces jointes (10 Mo par defaut) }
 MAX_ATTACHMENT_SIZE = 10485760;

 { Taille maximale d'un seul fichier (5 Mo) }
 MAX_SINGLE_FILE_SIZE = 5242880;

 { Zone d'affichage des pieces jointes dans le compositeur }
 ATTACH_PANEL_HEIGHT = 50;
 ATTACH_ICON_SIZE = 32;
 ATTACH_ICON_SPACING = 40;

 { Extensions dangereuses (executables) }
 DANGEROUS_EXT_COUNT = 12;

 { ============================================================================
   CONSTANTES POUR LE MOTEUR DE RENDU HTML (TODO 14)
   ============================================================================ }

 { Nombre maximum de tokens HTML }
 MAX_HTML_TOKENS = 100;

 { Nombre maximum d'elements de rendu }
 MAX_HTML_ELEMENTS = 200;

 { Taille de police par defaut (equivalent HTML size=3) }
 HTML_DEFAULT_FONT_SIZE = 3;

 { Couleurs HTML par defaut }
 HTML_COLOR_LINK = LightBlue;      { Couleur des liens }
 HTML_COLOR_VISITED = Magenta;      { Liens visites }
 HTML_COLOR_TEXT = White;           { Texte par defaut }
 HTML_COLOR_BG = Black;             { Fond par defaut }

 { Indentation pour les listes }
 HTML_LIST_INDENT = 20;

 { Espacement des tableaux }
 HTML_TABLE_PADDING = 4;
 HTML_TABLE_BORDER = 1;

 { Nombre d'entites HTML supportees }
 HTML_ENTITY_COUNT = 15;

 { ============================================================================
   CONSTANTES POUR LE DECODAGE MIME (TODO 15)
   ============================================================================ }

 { Nombre maximum de parties MIME }
 MAX_MIME_PARTS = 20;

 { Nombre maximum d'en-tetes MIME }
 MAX_MIME_HEADERS = 30;

 { Taille maximale du buffer de decodage }
 MIME_DECODE_BUFFER = 4096;

 { Longueur maximale d'une ligne MIME }
 MIME_MAX_LINE_LENGTH = 998;

 { Table Base64 }
 BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

 { ============================================================================
   CONSTANTES POUR LE CARNET D'ADRESSES (TODO 16)
   ============================================================================ }

 { Nombre maximum de contacts }
 MAX_CONTACTS = 100;

 { Nombre maximum de suggestions d'auto-completion }
 MAX_AUTOCOMPLETE_SUGGESTIONS = 10;

 { Dimensions de la fenetre carnet d'adresses }
 ADDRESSBOOK_WIDTH = 500;
 ADDRESSBOOK_HEIGHT = 380;
 ADDRESSBOOK_MARGIN = 10;

 { Hauteur d'une ligne de contact }
 CONTACT_LINE_HEIGHT = 18;

 { Nombre de contacts visibles }
 CONTACTS_VISIBLE = 15;

 { Largeur des colonnes }
 CONTACT_COL_NAME = 150;
 CONTACT_COL_EMAIL = 200;
 CONTACT_COL_PHONE = 100;

 { Fichier de sauvegarde }
 ADDRESSBOOK_FILE = 'ADDRBOOK.DAT';

 { ============================================================================
   CONSTANTES POUR LE SYSTEME DE REGLES (TODO 17)
   ============================================================================ }

 { Nombre maximum de regles }
 MAX_RULES = 50;

 { Nombre maximum de conditions par regle }
 MAX_RULE_CONDITIONS = 5;

 { Nombre maximum d'actions par regle }
 MAX_RULE_ACTIONS = 3;

 { Dimensions de la fenetre des regles }
 RULES_WINDOW_WIDTH = 520;
 RULES_WINDOW_HEIGHT = 400;

 { Hauteur d'une ligne de regle }
 RULE_LINE_HEIGHT = 22;

 { Nombre de regles visibles }
 RULES_VISIBLE = 12;

 { Fichier de sauvegarde des regles }
 RULES_FILE = 'RULES.DAT';

 { ============================================================================
   CONSTANTES POUR LA RECHERCHE AVANCEE (TODO 18)
   ============================================================================ }

 { Nombre maximum de resultats de recherche }
 MAX_SEARCH_RESULTS = 100;

 { Nombre maximum d'elements dans l'historique }
 MAX_SEARCH_HISTORY = 20;

 { Dimensions de la fenetre de recherche }
 SEARCH_WINDOW_WIDTH = 480;
 SEARCH_WINDOW_HEIGHT = 380;

 { Hauteur d'une ligne de resultat }
 SEARCH_RESULT_HEIGHT = 20;

 { Nombre de resultats visibles }
 SEARCH_RESULTS_VISIBLE = 10;

 { ============================================================================
   CONSTANTES POUR LA GESTION DES SIGNATURES (TODO 19)
   ============================================================================ }

 { Nombre maximum de signatures }
 MAX_SIGNATURES = 20;

 { Nombre maximum de parametres par compte }
 MAX_ACCOUNT_SIG_SETTINGS = 10;

 { Dimensions de la fenetre de signatures }
 SIG_WINDOW_WIDTH = 550;
 SIG_WINDOW_HEIGHT = 420;

 { Dimensions de l'editeur de signature }
 SIG_EDITOR_WIDTH = 400;
 SIG_EDITOR_HEIGHT = 250;

 { Nombre maximum de lignes de texte }
 SIG_MAX_TEXT_LINES = 20;

 { Nombre maximum de lignes HTML }
 SIG_MAX_HTML_LINES = 30;

 { Nombre de signatures visibles dans la liste }
 SIG_LIST_VISIBLE = 8;

 { Hauteur d'une ligne dans la liste }
 SIG_LIST_ITEM_HEIGHT = 24;

 { Separateur standard de signature }
 SIG_SEPARATOR = '-- ';

 { ============================================================================
   CONSTANTES POUR LES NOTIFICATIONS ET ALERTES (TODO 20)
   ============================================================================ }

 { Intervalle de verification par defaut (en secondes) }
 NOTIF_DEFAULT_CHECK_INTERVAL = 300;

 { Intervalle minimum de verification (en secondes) }
 NOTIF_MIN_CHECK_INTERVAL = 60;

 { Intervalle maximum de verification (en secondes) }
 NOTIF_MAX_CHECK_INTERVAL = 3600;

 { Nombre maximum de notifications en attente }
 MAX_PENDING_NOTIFICATIONS = 20;

 { Nombre maximum d'elements dans l'historique }
 MAX_NOTIFICATION_HISTORY = 50;

 { Nombre maximum de parametres par dossier }
 MAX_FOLDER_NOTIFICATION_SETTINGS = 30;

 { Dimensions de la fenetre popup de notification }
 NOTIF_POPUP_WIDTH = 300;
 NOTIF_POPUP_HEIGHT = 100;

 { Duree d'affichage du popup par defaut (en secondes) }
 NOTIF_POPUP_DEFAULT_DURATION = 5;

 { Intervalle de clignotement par defaut (en millisecondes) }
 NOTIF_FLASH_DEFAULT_INTERVAL = 500;

 { Nombre de clignotements par defaut }
 NOTIF_FLASH_DEFAULT_COUNT = 5;

 { Dimensions de la fenetre de configuration }
 NOTIF_CONFIG_WIDTH = 500;
 NOTIF_CONFIG_HEIGHT = 400;

 { Frequence du beep systeme (Hz) }
 NOTIF_BEEP_FREQUENCY = 800;

 { Duree du beep systeme (ms) }
 NOTIF_BEEP_DURATION = 200;

 { ============================================================================
   CONSTANTES POUR L'IMPRESSION ET L'APERCU (TODO 21)
   ============================================================================ }

 { Nombre maximum de lignes par page }
 PRINT_MAX_LINES_PER_PAGE = 60;

 { Nombre maximum de pages dans l'apercu }
 MAX_PRINT_PAGES = 10;

 { Dimensions de la fenetre d'apercu }
 PRINT_PREVIEW_WIDTH = 550;
 PRINT_PREVIEW_HEIGHT = 420;

 { Dimensions de la fenetre de configuration }
 PRINT_CONFIG_WIDTH = 450;
 PRINT_CONFIG_HEIGHT = 350;

 { Marges par defaut (en mm) }
 PRINT_DEFAULT_MARGIN_TOP = 20;
 PRINT_DEFAULT_MARGIN_BOTTOM = 20;
 PRINT_DEFAULT_MARGIN_LEFT = 25;
 PRINT_DEFAULT_MARGIN_RIGHT = 15;

 { Taille de police par defaut }
 PRINT_DEFAULT_FONT_SIZE = 10;

 { Interligne par defaut (100 = simple) }
 PRINT_DEFAULT_LINE_SPACING = 120;

 { Caracteres par ligne selon la taille du papier }
 PRINT_CHARS_PER_LINE_LETTER = 80;
 PRINT_CHARS_PER_LINE_A4 = 78;

 { Lignes par page selon la taille du papier }
 PRINT_LINES_PER_PAGE_LETTER = 60;
 PRINT_LINES_PER_PAGE_A4 = 64;

 { ============================================================================
   CONSTANTES POUR LA SAUVEGARDE ET L'EXPORT (TODO 22)
   ============================================================================ }

 { Signature du fichier de sauvegarde }
 BACKUP_SIGNATURE = 'OEBACKUP';

 { Version du format de sauvegarde }
 BACKUP_VERSION = 1;

 { Extensions de fichiers }
 BACKUP_EXTENSION = '.OEB';
 EML_EXTENSION = '.EML';
 MBOX_EXTENSION = '.MBOX';

 { Dimensions de la fenetre de sauvegarde }
 BACKUP_WINDOW_WIDTH = 450;
 BACKUP_WINDOW_HEIGHT = 350;

 { Nombre maximum d'elements dans une sauvegarde }
 MAX_BACKUP_MESSAGES = 1000;
 MAX_BACKUP_CONTACTS = 100;

 { Separateur MBOX }
 MBOX_SEPARATOR = 'From ';

 { Taille maximale d'un fichier de sauvegarde (10 Mo) }
 MAX_BACKUP_SIZE = 10485760;

 { ============================================================================
   CONSTANTES POUR LA CONFIGURATION DES PREFERENCES (TODO 23)
   ============================================================================ }

 { Dimensions de la fenetre de preferences }
 PREFS_WINDOW_WIDTH = 500;
 PREFS_WINDOW_HEIGHT = 400;

 { Largeur de la liste des onglets }
 PREFS_TAB_WIDTH = 120;

 { Nombre d'onglets }
 PREFS_TAB_COUNT = 5;

 { Hauteur d'un onglet }
 PREFS_TAB_HEIGHT = 30;

 { Marges internes }
 PREFS_MARGIN = 15;

 { Nom du fichier de preferences }
 PREFS_FILENAME = 'OUTLINK.CFG';

 { Version du fichier de preferences }
 PREFS_VERSION = 1;

 { Noms des onglets }
 PREFS_TAB_NAMES: Array[0..4] of String[15] = (
  'General',
  'Lecture',
  'Redaction',
  'Connexion',
  'Securite'
 );

 { Noms des langues }
 PREFS_LANG_NAMES: Array[0..9] of String[15] = (
  'Francais',
  'English',
  'Deutsch',
  'Italiano',
  'Espanol',
  'Portugues',
  'Svenska',
  'Dansk',
  'Nihongo',
  'Shqip'
 );

 { Noms des encodages }
 PREFS_ENCODING_NAMES: Array[0..4] of String[15] = (
  'ISO-8859-1',
  'ISO-8859-15',
  'UTF-8',
  'Windows-1252',
  'US-ASCII'
 );

 { Noms des formats }
 PREFS_FORMAT_NAMES: Array[0..2] of String[15] = (
  'Texte brut',
  'HTML',
  'Texte enrichi'
 );

 { ============================================================================
   CONSTANTES POUR LE MODE HORS LIGNE ET SYNCHRONISATION (TODO 24)
   ============================================================================ }

 { Taille maximale de la file d'attente }
 MAX_QUEUED_OPS = 100;

 { Taille maximale du cache de messages }
 MAX_CACHED_MESSAGES = 100;

 { Taille maximale du cache de dossiers }
 MAX_CACHED_FOLDERS = 50;

 { Intervalle de verification de la connectivite (secondes) }
 CONNECTIVITY_CHECK_INTERVAL = 30;

 { Nombre maximum de tentatives par operation }
 MAX_RETRY_COUNT = 3;

 { Delai entre les tentatives (secondes) }
 RETRY_DELAY = 5;

 { Nom du fichier de cache }
 CACHE_FILENAME = 'OUTLINK.CAC';

 { Nom du fichier de file d'attente }
 QUEUE_FILENAME = 'OUTLINK.QUE';

 { Version du fichier de cache }
 CACHE_VERSION = 1;

 { Indicateurs d'etat de connexion }
 STATUS_ONLINE_TEXT = 'En ligne';
 STATUS_OFFLINE_TEXT = 'Hors ligne';
 STATUS_CONNECTING_TEXT = 'Connexion...';
 STATUS_SYNCING_TEXT = 'Synchronisation...';

 { ============================================================================
   CONSTANTES POUR LE SUPPORT MULTI-LANGUE (TODO 25)
   ============================================================================ }

 { Nombre maximum de chaines traduisibles }
 MAX_STRING_IDS = 73;

 { Codes de langue ISO }
 LANG_CODES: Array[TLanguage] of String[5] = (
  'FR', 'EN', 'DE', 'IT', 'ES', 'PT', 'SV', 'DA', 'JA', 'SQ'
 );

 { Noms des langues }
 LANG_NAMES: Array[TLanguage] of String[15] = (
  'Francais', 'English', 'Deutsch', 'Italiano', 'Espanol',
  'Portugues', 'Svenska', 'Dansk', 'Nihongo', 'Shqip'
 );

 { Extension des fichiers de langue }
 LANG_FILE_EXT = '.LNG';

 { Traductions francaises (par defaut) }
 STRINGS_FR: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Menu Fichier }
  'Fichier', 'Nouveau message', 'Ouvrir', 'Enregistrer', 'Enregistrer sous',
  'Imprimer', 'Quitter',
  { Menu Edition }
  'Edition', 'Annuler', 'Retablir', 'Couper', 'Copier', 'Coller',
  'Tout selectionner', 'Rechercher',
  { Menu Affichage }
  'Affichage', 'Volet des dossiers', 'Volet de lecture', 'Barre d''outils',
  'Barre d''etat', 'Actualiser',
  { Menu Message }
  'Message', 'Repondre', 'Repondre a tous', 'Transferer', 'Supprimer',
  'Marquer comme lu', 'Marquer comme non lu', 'Ajouter un indicateur',
  { Menu Outils }
  'Outils', 'Comptes', 'Regles', 'Preferences',
  'Envoyer/Recevoir',
  { Menu Aide }
  'Aide', 'Sommaire', 'A propos',
  { Dossiers }
  'Boite de reception', 'Boite d''envoi', 'Elements envoyes', 'Brouillons', 'Corbeille',
  { Interface }
  'De', 'A', 'Objet', 'Date', 'Taille', 'Priorite',
  'Piece jointe', 'Rechercher', 'Rechercher un message...',
  { Boutons }
  'OK', 'Annuler', 'Oui', 'Non', 'Appliquer', 'Fermer',
  { Messages^ }
  'Aucun message', 'Chargement...', 'Erreur', 'Succes',
  'Confirmer la suppression', 'Message envoye',
  { Etat connexion }
  'En ligne', 'Hors ligne', 'Connexion...', 'Synchronisation...',
  { Divers }
  'Nouveau courrier', 'non lus', 'messages',
  'octets', 'Ko', 'Mo'
 );

 { Traductions anglaises }
 STRINGS_EN: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Menu File }
  'File', 'New Message', 'Open', 'Save', 'Save As',
  'Print', 'Exit',
  { Menu Edit }
  'Edit', 'Undo', 'Redo', 'Cut', 'Copy', 'Paste',
  'Select All', 'Find',
  { Menu View }
  'View', 'Folder Pane', 'Preview Pane', 'Toolbar',
  'Status Bar', 'Refresh',
  { Menu Message }
  'Message', 'Reply', 'Reply All', 'Forward', 'Delete',
  'Mark as Read', 'Mark as Unread', 'Flag',
  { Menu Tools }
  'Tools', 'Accounts', 'Rules', 'Preferences',
  'Send/Receive',
  { Menu Help }
  'Help', 'Contents', 'About',
  { Folders }
  'Inbox', 'Outbox', 'Sent Items', 'Drafts', 'Trash',
  { Interface }
  'From', 'To', 'Subject', 'Date', 'Size', 'Priority',
  'Attachment', 'Search', 'Search messages...',
  { Buttons }
  'OK', 'Cancel', 'Yes', 'No', 'Apply', 'Close',
  { Messages^ }
  'No messages', 'Loading...', 'Error', 'Success',
  'Confirm delete', 'Message sent',
  { Connection state }
  'Online', 'Offline', 'Connecting...', 'Synchronizing...',
  { Misc }
  'New mail', 'unread', 'messages',
  'bytes', 'KB', 'MB'
 );

 { Traductions allemandes }
 STRINGS_DE: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Menu Datei }
  'Datei', 'Neue Nachricht', 'Oeffnen', 'Speichern', 'Speichern unter',
  'Drucken', 'Beenden',
  { Menu Bearbeiten }
  'Bearbeiten', 'Rueckgaengig', 'Wiederholen', 'Ausschneiden', 'Kopieren', 'Einfuegen',
  'Alles auswaehlen', 'Suchen',
  { Menu Ansicht }
  'Ansicht', 'Ordnerbereich', 'Vorschaubereich', 'Symbolleiste',
  'Statusleiste', 'Aktualisieren',
  { Menu Nachricht }
  'Nachricht', 'Antworten', 'Allen antworten', 'Weiterleiten', 'Loeschen',
  'Als gelesen markieren', 'Als ungelesen markieren', 'Kennzeichnen',
  { Menu Extras }
  'Extras', 'Konten', 'Regeln', 'Einstellungen',
  'Senden/Empfangen',
  { Menu Hilfe }
  'Hilfe', 'Inhalt', 'Info',
  { Ordner }
  'Posteingang', 'Postausgang', 'Gesendete', 'Entwuerfe', 'Papierkorb',
  { Oberflaeche }
  'Von', 'An', 'Betreff', 'Datum', 'Groesse', 'Prioritaet',
  'Anlage', 'Suchen', 'Nachrichten suchen...',
  { Schaltflaechen }
  'OK', 'Abbrechen', 'Ja', 'Nein', 'Uebernehmen', 'Schliessen',
  { Nachrichten }
  'Keine Nachrichten', 'Laden...', 'Fehler', 'Erfolg',
  'Loeschen bestaetigen', 'Nachricht gesendet',
  { Verbindungsstatus }
  'Online', 'Offline', 'Verbinden...', 'Synchronisieren...',
  { Sonstiges }
  'Neue E-Mail', 'ungelesen', 'Nachrichten',
  'Bytes', 'KB', 'MB'
 );

 { Traductions italiennes }
 STRINGS_IT: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Menu File }
  'File', 'Nuovo messaggio', 'Apri', 'Salva', 'Salva con nome',
  'Stampa', 'Esci',
  { Menu Modifica }
  'Modifica', 'Annulla', 'Ripeti', 'Taglia', 'Copia', 'Incolla',
  'Seleziona tutto', 'Trova',
  { Menu Visualizza }
  'Visualizza', 'Riquadro cartelle', 'Riquadro anteprima', 'Barra strumenti',
  'Barra di stato', 'Aggiorna',
  { Menu Messaggio }
  'Messaggio', 'Rispondi', 'Rispondi a tutti', 'Inoltra', 'Elimina',
  'Segna come letto', 'Segna come non letto', 'Contrassegna',
  { Menu Strumenti }
  'Strumenti', 'Account', 'Regole', 'Preferenze',
  'Invia/Ricevi',
  { Menu Guida }
  'Guida', 'Sommario', 'Informazioni su',
  { Cartelle }
  'Posta in arrivo', 'Posta in uscita', 'Posta inviata', 'Bozze', 'Cestino',
  { Interfaccia }
  'Da', 'A', 'Oggetto', 'Data', 'Dimensione', 'Priorita',
  'Allegato', 'Cerca', 'Cerca messaggi...',
  { Pulsanti }
  'OK', 'Annulla', 'Si', 'No', 'Applica', 'Chiudi',
  { Messaggi }
  'Nessun messaggio', 'Caricamento...', 'Errore', 'Successo',
  'Conferma eliminazione', 'Messaggio inviato',
  { Stato connessione }
  'Online', 'Offline', 'Connessione...', 'Sincronizzazione...',
  { Varie }
  'Nuova posta', 'non letti', 'messaggi',
  'byte', 'KB', 'MB'
 );

 { Traductions espagnoles }
 STRINGS_ES: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Menu Archivo }
  'Archivo', 'Nuevo mensaje', 'Abrir', 'Guardar', 'Guardar como',
  'Imprimir', 'Salir',
  { Menu Editar }
  'Editar', 'Deshacer', 'Rehacer', 'Cortar', 'Copiar', 'Pegar',
  'Seleccionar todo', 'Buscar',
  { Menu Ver }
  'Ver', 'Panel de carpetas', 'Panel de vista previa', 'Barra herramientas',
  'Barra de estado', 'Actualizar',
  { Menu Mensaje }
  'Mensaje', 'Responder', 'Responder a todos', 'Reenviar', 'Eliminar',
  'Marcar como leido', 'Marcar como no leido', 'Marcar',
  { Menu Herramientas }
  'Herramientas', 'Cuentas', 'Reglas', 'Preferencias',
  'Enviar/Recibir',
  { Menu Ayuda }
  'Ayuda', 'Contenido', 'Acerca de',
  { Carpetas }
  'Bandeja de entrada', 'Bandeja de salida', 'Enviados', 'Borradores', 'Papelera',
  { Interfaz }
  'De', 'Para', 'Asunto', 'Fecha', 'Tamano', 'Prioridad',
  'Adjunto', 'Buscar', 'Buscar mensajes...',
  { Botones }
  'OK', 'Cancelar', 'Si', 'No', 'Aplicar', 'Cerrar',
  { Mensajes }
  'Sin mensajes', 'Cargando...', 'Error', 'Exito',
  'Confirmar eliminacion', 'Mensaje enviado',
  { Estado conexion }
  'En linea', 'Sin conexion', 'Conectando...', 'Sincronizando...',
  { Varios }
  'Correo nuevo', 'no leidos', 'mensajes',
  'bytes', 'KB', 'MB'
 );

 { Traductions portugaises }
 STRINGS_PT: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Menu Ficheiro }
  'Ficheiro', 'Nova mensagem', 'Abrir', 'Guardar', 'Guardar como',
  'Imprimir', 'Sair',
  { Menu Editar }
  'Editar', 'Anular', 'Refazer', 'Cortar', 'Copiar', 'Colar',
  'Seleccionar tudo', 'Procurar',
  { Menu Ver }
  'Ver', 'Painel de pastas', 'Painel de pre-visualizacao', 'Barra ferramentas',
  'Barra de estado', 'Actualizar',
  { Menu Mensagem }
  'Mensagem', 'Responder', 'Responder a todos', 'Reencaminhar', 'Eliminar',
  'Marcar como lida', 'Marcar como nao lida', 'Sinalizar',
  { Menu Ferramentas }
  'Ferramentas', 'Contas', 'Regras', 'Preferencias',
  'Enviar/Receber',
  { Menu Ajuda }
  'Ajuda', 'Conteudo', 'Acerca de',
  { Pastas }
  'Caixa de entrada', 'Caixa de saida', 'Itens enviados', 'Rascunhos', 'Lixo',
  { Interface }
  'De', 'Para', 'Assunto', 'Data', 'Tamanho', 'Prioridade',
  'Anexo', 'Procurar', 'Procurar mensagens...',
  { Botoes }
  'OK', 'Cancelar', 'Sim', 'Nao', 'Aplicar', 'Fechar',
  { Mensagens }
  'Sem mensagens', 'A carregar...', 'Erro', 'Sucesso',
  'Confirmar eliminacao', 'Mensagem enviada',
  { Estado ligacao }
  'Online', 'Offline', 'A ligar...', 'A sincronizar...',
  { Diversos }
  'Novo correio', 'nao lidas', 'mensagens',
  'bytes', 'KB', 'MB'
 );

 { Traductions suedoises }
 STRINGS_SV: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Meny Arkiv }
  'Arkiv', 'Nytt meddelande', 'Oeppna', 'Spara', 'Spara som',
  'Skriv ut', 'Avsluta',
  { Meny Redigera }
  'Redigera', 'Aangra', 'Goer om', 'Klipp ut', 'Kopiera', 'Klistra in',
  'Markera allt', 'Soek',
  { Meny Visa }
  'Visa', 'Mappanel', 'Forhandsvisning', 'Verktygsfaelt',
  'Statusfaelt', 'Uppdatera',
  { Meny Meddelande }
  'Meddelande', 'Svara', 'Svara alla', 'Vidarebefordra', 'Ta bort',
  'Markera som laest', 'Markera som olaest', 'Flagga',
  { Meny Verktyg }
  'Verktyg', 'Konton', 'Regler', 'Installningar',
  'Skicka/Ta emot',
  { Meny Hjaelp }
  'Hjaelp', 'Innehall', 'Om',
  { Mappar }
  'Inkorg', 'Utkorg', 'Skickat', 'Utkast', 'Papperskorg',
  { Graenssnitt }
  'Fran', 'Till', 'AEmne', 'Datum', 'Storlek', 'Prioritet',
  'Bilaga', 'Soek', 'Soek meddelanden...',
  { Knappar }
  'OK', 'Avbryt', 'Ja', 'Nej', 'Tillaemp', 'Staeng',
  { Meddelanden }
  'Inga meddelanden', 'Laddar...', 'Fel', 'Lyckades',
  'Bekraefta borttagning', 'Meddelande skickat',
  { Anslutningsstatus }
  'Online', 'Offline', 'Ansluter...', 'Synkroniserar...',
  { OEvrigt }
  'Ny e-post', 'olaesta', 'meddelanden',
  'byte', 'KB', 'MB'
 );

 { Traductions danoises }
 STRINGS_DA: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Menu Fil }
  'Fil', 'Ny besked', 'AAbn', 'Gem', 'Gem som',
  'Udskriv', 'Afslut',
  { Menu Rediger }
  'Rediger', 'Fortryd', 'Annuller fortryd', 'Klip', 'Kopier', 'Indsaet',
  'Vaelg alle', 'Find',
  { Menu Vis }
  'Vis', 'Mappepanel', 'Eksempelpanel', 'Vaerktoejslinje',
  'Statuslinje', 'Opdater',
  { Menu Besked }
  'Besked', 'Svar', 'Svar alle', 'Videresend', 'Slet',
  'Marker som laest', 'Marker som ulaest', 'Flag',
  { Menu Funktioner }
  'Funktioner', 'Konti', 'Regler', 'Indstillinger',
  'Send/Modtag',
  { Menu Hjaelp }
  'Hjaelp', 'Indhold', 'Om',
  { Mapper }
  'Indbakke', 'Udbakke', 'Sendt', 'Kladder', 'Papirkurv',
  { Graenseflade }
  'Fra', 'Til', 'Emne', 'Dato', 'Storrelse', 'Prioritet',
  'Vedhaeftning', 'Soeg', 'Soeg i beskeder...',
  { Knapper }
  'OK', 'Annuller', 'Ja', 'Nej', 'Anvend', 'Luk',
  { Beskeder }
  'Ingen beskeder', 'Indlaeser...', 'Fejl', 'Succes',
  'Bekraeft sletning', 'Besked sendt',
  { Forbindelsesstatus }
  'Online', 'Offline', 'Forbinder...', 'Synkroniserer...',
  { Diverse }
  'Ny e-mail', 'ulaeste', 'beskeder',
  'bytes', 'KB', 'MB'
 );

 { Traductions japonaises (romaji) }
 STRINGS_JA: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Menu Fairu }
  'Fairu', 'Atarashii messeeji', 'Hiraku', 'Hozon', 'Namae wo tsukete hozon',
  'Insatsu', 'Shuuryou',
  { Menu Henshuu }
  'Henshuu', 'Modosu', 'Yarinaoshi', 'Kiru', 'Kopii', 'Haritsukezu',
  'Subete sentaku', 'Kensaku',
  { Menu Hyouji }
  'Hyouji', 'Foruda pein', 'Purebyu pein', 'Tsuuru baa',
  'Suteetasu baa', 'Saishinji',
  { Menu Messeeji }
  'Messeeji', 'Henshin', 'Zen-in ni henshin', 'Tensou', 'Sakujo',
  'Kidoku ni suru', 'Midoku ni suru', 'Furagu',
  { Menu Tsuuru }
  'Tsuuru', 'Akaunto', 'Ruuru', 'Settei',
  'Soushin/Jushin',
  { Menu Herupu }
  'Herupu', 'Mokuji', 'Kono apuri ni tsuite',
  { Foruda }
  'Jushinbako', 'Soushinbako', 'Soushinsumi', 'Shitagaki', 'Gomibako',
  { Intaafeisu }
  'Sashidashinin', 'Atesaki', 'Kenmei', 'Hizuke', 'Saizu', 'Yuusendo',
  'Tenpu', 'Kensaku', 'Messeeji wo kensaku...',
  { Botan }
  'OK', 'Kyanseru', 'Hai', 'Iie', 'Tekiyou', 'Tojiru',
  { Messeeji }
  'Messeeji nashi', 'Yomikomi-chu...', 'Eraa', 'Seikoo',
  'Sakujo kakunin', 'Messeeji soushin-zumi',
  { Setsuzoku joutai }
  'Onrain', 'Ofurain', 'Setsuzoku-chu...', 'Douki-chu...',
  { Sonota }
  'Shin meeru', 'midoku', 'messeeji',
  'baito', 'KB', 'MB'
 );

 { Traductions albanaises }
 STRINGS_SQ: Array[0..MAX_STRING_IDS-1] of String[40] = (
  { Menu Skedar }
  'Skedar', 'Mesazh i ri', 'Hap', 'Ruaj', 'Ruaj si',
  'Printo', 'Dil',
  { Menu Ndrysho }
  'Ndrysho', 'Zhbej', 'Ribej', 'Prit', 'Kopjo', 'Ngjit',
  'Zgjidh te gjitha', 'Keerko',
  { Menu Shiko }
  'Shiko', 'Paneli dosje', 'Paneli parapamje', 'Shiriti veglash',
  'Shiriti statusit', 'Rifresko',
  { Menu Mesazh }
  'Mesazh', 'Pergjigju', 'Pergjigju te gjitheve', 'Percjell', 'Fshi',
  'Sheno si lexuar', 'Sheno si palexuar', 'Sheno',
  { Menu Vegla }
  'Vegla', 'Llogarite', 'Rregullat', 'Preferencat',
  'Dergo/Merr',
  { Menu Ndihme }
  'Ndihme', 'Permbajtja', 'Rreth',
  { Dosje }
  'Kutia hyr'#137'se', 'Kutia dal'#137'se', 'Te d'#137'rguarat', 'Skica', 'Koshi',
  { Nderfaqe }
  'Nga', 'Per', 'Tema', 'Data', 'Madhesia', 'Prioriteti',
  'Bashk'#137'angjitje', 'Keerko', 'Keerko mesazhe...',
  { Butona }
  'OK', 'Anulo', 'Po', 'Jo', 'Zbato', 'Mbyll',
  { Mesazhe }
  'Pa mesazhe', 'Duke ngarkuar...', 'Gabim', 'Sukses',
  'Konfirmo fshirjen', 'Mesazhi u dergua',
  { Status lidhje }
  'Online', 'Offline', 'Duke u lidhur...', 'Duke sinkronizuar...',
  { Te tjera }
  'Poste e re', 'palexuar', 'mesazhe',
  'byte', 'KB', 'MB'
 );

Var
 ColumnsDialogVisible: Boolean;
 ColumnsDraft: Array[0..MAX_COLUMNS-1] Of TColumnHeader;
 ColumnsDialogSelection, ColumnsDialogFocus: Integer;
 ColumnsDialogError: String[60];
 SortDialogVisible: Boolean;
 SortDialogCriterion, SortDialogFocus: Integer;
 SortDialogOrder: TSortOrder;
 FileOpenVisible, FileOpenShowAll: Boolean;
 FileDialogSaveMode, FileSaveFromComposer: Boolean;
 FileSaveOverwritePending, FileSaveOverwriteYes: Boolean;
 FileSaveOverwritePath: String[255];
 FileSaveData: TMailText;
 FileOpenDirectory, FileOpenName: String[255];
 FileOpenError: String[80];
 FileOpenEntries: Array[0..MAX_OPEN_DIALOG_FILES-1] of TOpenFileEntry;
 FileOpenCount, FileOpenSelection, FileOpenScroll: Integer;
 FileOpenFocus, FileOpenCursor: Integer;
 FileOpenTruncated: Boolean;
 MaxScreen: Boolean;
 SCREEN_WIDTH, SCREEN_HEIGHT: Integer;
 DIALOG_X, DIALOG_Y, COMPOSER_X, COMPOSER_Y: Integer;
 ATTACH_PANEL_Y: Integer;
 Layout: TWindowLayout;
 DragState: TDragState;
 DragStartX, DragStartY: Integer;
 Running: Boolean;
 
 MouseX, MouseY: Integer;
 MouseBtn: Integer;
 
 

 { Variables pour la detection du double-clic }
 LastClickTime: LongInt;
 LastClickX, LastClickY: Integer;
 LastClickBtn: Integer;
 ClickCount: Integer;

 { Variables pour la molette de defilement }
 MouseWheelDelta: Integer;
 ScrollOffset: Integer;

 { Variables pour le systeme de menus }
 Menus: Array[0..MAX_MENUS-1] of TDropdownMenu;
 MenuCount: Integer;
 ActiveMenu: Integer;        { Index du menu actif (-1 = aucun) }
 ActiveMenuItem: Integer;    { Index de l'element survole (-1 = aucun) }
 LastMenuShortcut: Integer;
 MenuBarActive: Boolean;     { True si la barre de menu est active }

 { Variables pour la barre d'outils }
 ToolButtons: Array[0..MAX_TOOLBAR_BUTTONS-1] of TToolButton;
 ToolButtonCount: Integer;
 HoveredToolButton: Integer;  { Index du bouton survole (-1 = aucun) }
 PressedToolButton: Integer;  { Index du bouton appuye (-1 = aucun) }

 { Variables pour les infobulles }
 TooltipVisible: Boolean;
 TooltipX, TooltipY: Integer;
 TooltipText: String[40];
 TooltipStartTime: LongInt;
 LastMouseX, LastMouseY: Integer;

 { Variables pour l'arbre de dossiers }
 Folders: Array[0..MAX_FOLDERS-1] of TFolderNode;
 FolderCount: Integer;
 SelectedFolder: Integer;     { Index du dossier selectionne }
 HoveredFolder: Integer;      { Index du dossier survole }
 FolderScrollOffset: Integer; { Defilement de l'arbre }
 DraggedFolder: Integer;      { Index du dossier en cours de glisser-deposer }

 { Variables pour la liste des messages }

Type
 TOlA_Messages = Array[0..MAX_MESSAGES-1] of TMessage;
Var
 Messages: ^TOlA_Messages;
 MessageCount: Integer;
 SelectedMessage: Integer;    { Index du message selectionne (-1 = aucun) }
 LastSelectedMessage: Integer; { Pour la selection multiple avec Shift }
 MessageScrollOffset: Integer; { Defilement de la liste }
 CtrlKeyDown: Boolean;        { Touche Ctrl enfoncee }
 ShiftKeyDown: Boolean;       { Touche Shift enfoncee }

 { Variables pour les colonnes de messages }
 Columns: Array[0..MAX_COLUMNS-1] of TColumnHeader;
 ColumnCount: Integer;
 SortColumn: Integer;         { Index de la colonne de tri (-1 = aucun) }
 SortOrder: TSortOrder;       { Ordre de tri actuel }
 HoveredColumn: Integer;      { Index de la colonne survolee }

 { Variables pour le menu contextuel des messages }
 ContextMenuVisible: Boolean;
 ContextMenuX, ContextMenuY: Integer;
 ContextMenuWidth, ContextMenuHeight: Integer;
 ContextMenuItems: Array[0..7] of TMenuItem;
 ContextMenuItemCount: Integer;
 HoveredContextItem: Integer;

 { Variables pour le volet de previsualisation }
 PreviewScrollY: Integer;     { Position de defilement vertical }
 PreviewScrollX: Integer;     { Position de defilement horizontal }
 PreviewMaxScrollY: Integer;  { Defilement vertical maximum }
 PreviewMaxScrollX: Integer;  { Defilement horizontal maximum }
 PreviewOrientation: TPreviewOrientation; { Orientation du volet }
 PreviewVisible: Boolean;     { Volet visible ou masque }
 PreviewHeaderHeight: Integer; { Hauteur de la zone d'en-tetes }
 InPreviewPane: Boolean;      { Souris dans le volet de previsualisation }

 { Variables globales pour le client IMAP }
 IMAPClient: TIMAPClient;              { Instance du client IMAP }
 IMAPMessages: Array[0..0] of TIMAPMessage; { Cache des messages }
 IMAPMessageCount: Integer;            { Nombre de messages charges }
 IMAPConnecting: Boolean;              { Connexion en cours }
 IMAPLastActivity: LongInt;            { Dernier timestamp d'activite }

 { Variables globales pour le client POP3 }
 POP3Client: TPOP3Client;              { Instance du client POP3 }
 POP3Messages: Array[0..0] of TPOP3Message; { Cache des messages }

Type
 TOlA_POP3ListItems = Array[0..POP3_MAX_MESSAGES-1] of TPOP3ListItem;
Var
 POP3ListItems: ^TOlA_POP3ListItems;
 POP3MessageCount: Integer;            { Nombre de messages sur le serveur }
 POP3Connecting: Boolean;              { Connexion en cours }
 POP3LastActivity: LongInt;            { Dernier timestamp d'activite }

 { Variables globales pour le client SMTP }
 SMTPClient: TSMTPClient;              { Instance du client SMTP }
 SMTPRecipients: Array[0..SMTP_MAX_RECIPIENTS-1] of TSMTPRecipient; { Destinataires }
 SMTPCurrentMessage: TSMTPMessage;     { Message en cours de preparation }
 SMTPSending: Boolean;                 { Envoi en cours }
 SMTPLastActivity: LongInt;            { Dernier timestamp d'activite }

 { Variables globales pour le gestionnaire de comptes (TODO 11) }
 EmailAccounts: Array[0..MAX_EMAIL_ACCOUNTS-1] of TEmailAccount; { Liste des comptes }
 CommandLineAccountsFile: String[251];
 AccountStorageError: String[80];
 EmailAccountCount: Integer;           { Nombre de comptes configures }
 CurrentAccountIndex: Integer;         { Index du compte en cours d'edition }
 AccountDialogVisible: Boolean;        { Boite de dialogue visible }
 AccountWizardStep: TAccountWizardStep; { Etape de l'assistant }
 AccountWizardMode: Boolean;           { True = assistant, False = edition }
 TempAccount: TEmailAccount;           { Compte temporaire pour edition }
 AccountListScrollOffset: Integer;     { Defilement de la liste des comptes }
 SelectedAccountInList: Integer;       { Compte selectionne dans la liste }
 AccountDialogInputFields: Array[0..9] of TInputField; { Champs de saisie }
 AccountDialogRadioButtons: Array[0..5] of TRadioButton; { Boutons radio }
 AccountDialogCheckBoxes: Array[0..5] of TCheckBox; { Cases a cocher }
 FocusedInputField: Integer;           { Index du champ de saisie actif }
 ConnectionTestInProgress: Boolean;    { Test de connexion en cours }
 ConnectionTestResult: TConnectionTestResult; { Resultat du test }

 { Variables globales pour le compositeur de messages (TODO 12) }
 Composer: TMessageComposer;            { Instance du compositeur }
 ComposerVisible: Boolean;              { Fenetre du compositeur visible }
 ComposerFocusedField: Integer;         { Champ actif (0-4) }
 ComposerCursorVisible: Boolean;        { Curseur visible (clignotement) }
 ComposerCursorTimer: LongInt;          { Timer pour le clignotement }
 ComposerInputFields: Array[0..3] of TInputField; { Champs d'en-tete }
 ComposerFormatBold: Boolean;           { Bouton gras actif }
 ComposerFormatItalic: Boolean;         { Bouton italique actif }
 ComposerFormatUnderline: Boolean;      { Bouton souligne actif }

 { Variables globales pour les pieces jointes (TODO 13) }
 AttachPanelVisible: Boolean;           { Panneau de pieces jointes visible }
 SelectedAttachment: Integer;           { Index de la piece jointe selectionnee }
 AttachFileBrowserVisible: Boolean;     { Navigateur de fichiers visible }
 AttachCurrentPath: String[200];        { Chemin courant dans le navigateur }
 AttachFileList: Array[0..49] of String[80]; { Liste des fichiers }
 AttachFileCount: Integer;              { Nombre de fichiers }
 AttachSelectedFile: Integer;           { Fichier selectionne }
 AttachTotalSize: LongInt;              { Taille totale des pieces jointes }
 DangerousExtensions: Array[0..11] of String[4]; { Extensions dangereuses }

 { Variables globales pour le moteur HTML (TODO 14) }

Type
 TOlA_HTMLTokens = Array[0..MAX_HTML_TOKENS-1] of THTMLToken;
Var
 HTMLTokens: ^TOlA_HTMLTokens;
 HTMLTokenCount: Integer;               { Nombre de tokens }
 HTMLElements: Array[0..MAX_HTML_ELEMENTS-1] of THTMLRenderElement; { Elements de rendu }
 HTMLElementCount: Integer;             { Nombre d'elements }
 HTMLCurrentStyle: THTMLRenderStyle;    { Style courant }
 HTMLRenderX, HTMLRenderY: Integer;     { Position de rendu }
 HTMLRenderWidth: Integer;              { Largeur disponible }
 HTMLIsHTML: Boolean;                   { Le message est en HTML }

 { Variables globales pour le decodage MIME (TODO 15) }
 MIMEParts: Array[0..MAX_MIME_PARTS-1] of TMIMEPart;  { Parties MIME }
 MIMEPartCount: Integer;                { Nombre de parties }
 MIMEHeaders: Array[0..MAX_MIME_HEADERS-1] of TMIMEHeader; { En-tetes }
 MIMEHeaderCount: Integer;              { Nombre d'en-tetes }
 MIMERootPart: TMIMEPart;               { Partie racine }
 MIMETextPart: String;                  { Contenu texte decode }
 MIMEHTMLPart: String;                  { Contenu HTML decode }
 MIMEHasText: Boolean;                  { Message contient du texte }
 MIMEHasHTML: Boolean;                  { Message contient du HTML }
 MIMEHasAttachments: Boolean;           { Message contient des pieces jointes }

 { Variables globales pour le carnet d'adresses (TODO 16) }

Type
 TOlA_Contacts = Array[0..MAX_CONTACTS-1] of TContact;
Var
 Contacts: ^TOlA_Contacts;
 ContactCount: Integer;                 { Nombre de contacts }
 ContactNextID: Integer;                { Prochain ID disponible }
 ContactSortField: TContactSortField;   { Champ de tri }
 ContactSortAsc: Boolean;               { Ordre ascendant }
 ContactScrollOffset: Integer;          { Decalage de defilement }
 ContactSelectedIndex: Integer;         { Contact selectionne }
 AddressBookState: TAddressBookState;   { Etat de la fenetre }
 AddressBookX, AddressBookY: Integer;   { Position de la fenetre }
 AddressBookSearchText: String[40];     { Texte de recherche }
 EditingContact: TContact;              { Contact en cours d'edition }
 EditingContactIndex: Integer;          { Index du contact en edition (-1 si nouveau) }
 EditingField: Integer;                 { Champ en cours d'edition (0-16) }
 AddressBookVisible: Boolean;           { Visibilite du carnet }

 { Variables pour l'auto-completion }
 AutoCompleteSuggestions: Array[0..MAX_AUTOCOMPLETE_SUGGESTIONS-1] of TAutoCompleteSuggestion;
 AutoCompleteSuggestionCount: Integer;  { Nombre de suggestions }
 AutoCompleteVisible: Boolean;          { Suggestions visibles }
 AutoCompleteSelectedIndex: Integer;    { Suggestion selectionnee }
 AutoCompleteField: TAutoCompleteField; { Champ actif }
 AutoCompleteX, AutoCompleteY: Integer; { Position du popup }
 AutoCompleteText: String[40];          { Texte tape }

 { Variables globales pour le systeme de regles (TODO 17) }

Type
 TOlA_FilterRules = Array[0..MAX_RULES-1] of TFilterRule;
Var
 FilterRules: ^TOlA_FilterRules;
 RuleCount: Integer;                    { Nombre de regles }
 RuleNextID: Integer;                   { Prochain ID disponible }
 RulesWindowState: TRulesWindowState;   { Etat de la fenetre }
 RulesWindowX, RulesWindowY: Integer;   { Position de la fenetre }
 RulesFocus, RulesTextCursor: Integer;
 RulesError: String[70];
 RulesDeletePending, RulesStopAfter: Boolean;

Type
 TOlA_RulesBackup = Array[0..MAX_RULES-1] Of TFilterRule;
Var
 RulesBackup: ^TOlA_RulesBackup;
 RulesVisible: Boolean;                 { Visibilite de la fenetre }
 RulesScrollOffset: Integer;            { Decalage de defilement }
 RulesSelectedIndex: Integer;           { Regle selectionnee }
 EditingRule: TFilterRule;              { Regle en cours d'edition }
 EditingRuleIndex: Integer;             { Index de la regle en edition }
 EditingConditionIndex: Integer;        { Index de la condition en edition }
 EditingActionIndex: Integer;           { Index de l'action en edition }

 { Variables globales pour la recherche avancee (TODO 18) }
 SearchFilter: TSearchFilter;           { Filtre de recherche actuel }
 SearchResults: Array[0..MAX_SEARCH_RESULTS-1] of TSearchResult; { Resultats }
 SearchResultCount: Integer;            { Nombre de resultats }
 SearchHistory: Array[0..MAX_SEARCH_HISTORY-1] of TSearchHistoryItem; { Historique }
 SearchHistoryCount: Integer;           { Nombre d'elements dans l'historique }
 SearchWindowState: TSearchWindowState; { Etat de la fenetre }
 SearchWindowX, SearchWindowY: Integer; { Position de la fenetre }
 SearchVisible: Boolean;                { Visibilite de la fenetre }
 SearchScrollOffset: Integer;           { Decalage de defilement }
 SearchSelectedIndex: Integer;          { Resultat selectionne }
 SearchInProgress: Boolean;             { Recherche en cours }
 HighlightResults: Boolean;             { Mise en surbrillance active }
 CurrentHighlightIndex: Integer;        { Index de surbrillance actuel }

 { ============================================================================
   VARIABLES POUR LA GESTION DES SIGNATURES (TODO 19)
   ============================================================================ }


Type
 TOlA_Signatures = Array[0..MAX_SIGNATURES-1] of TEmailSignature;
Var
 Signatures: ^TOlA_Signatures;
 SignatureCount: Integer;              { Nombre de signatures }
 AccountSigSettings: Array[0..MAX_ACCOUNT_SIG_SETTINGS-1] of TAccountSignatureSettings;
 AccountSigSettingsCount: Integer;     { Nombre de parametres par compte }
 SignatureWindowState: TSignatureWindowState; { Etat de la fenetre }
 SignatureWindowX, SignatureWindowY: Integer; { Position de la fenetre }
 SignatureVisible: Boolean;            { Visibilite de la fenetre }
 SignatureScrollOffset: Integer;       { Decalage de defilement }
 SignatureSelectedIndex: Integer;      { Signature selectionnee }
 SignatureEditorState: TSignatureEditorState; { Etat de l'editeur }
 SignaturePreviewMode: Boolean;        { Mode apercu actif }
 CurrentSignatureID: Integer;          { ID de la signature en cours }
 NextSignatureID: Integer;             { Prochain ID disponible }

 { ============================================================================
   VARIABLES POUR LES NOTIFICATIONS ET ALERTES (TODO 20)
   ============================================================================ }

 NotificationSettings: TNotificationSettings; { Parametres globaux }
 FolderNotifSettings: Array[0..MAX_FOLDER_NOTIFICATION_SETTINGS-1] of TFolderNotificationSettings;
 FolderNotifSettingsCount: Integer;    { Nombre de parametres par dossier }
 PendingNotifications: Array[0..MAX_PENDING_NOTIFICATIONS-1] of TNewMailInfo;
 PendingNotificationCount: Integer;    { Nombre de notifications en attente }
 NotificationHistory: Array[0..MAX_NOTIFICATION_HISTORY-1] of TNotificationHistoryItem;
 NotificationHistoryCount: Integer;    { Nombre d'elements dans l'historique }
 NotificationState: TNotificationState; { Etat actuel de la notification }
 LastCheckTime: LongInt;               { Horodatage derniere verification }
 NextCheckTime: LongInt;               { Horodatage prochaine verification }
 NotificationPopupState: TNotificationPopupState; { Etat du popup }
 NotificationPopupX, NotificationPopupY: Integer; { Position du popup }
 NotificationPopupStartTime: LongInt;  { Debut d'affichage du popup }
 NotificationConfigState: TNotificationConfigState; { Etat de la config }
 NotificationConfigX, NotificationConfigY: Integer; { Position de la fenetre }
 NotificationConfigVisible: Boolean;   { Visibilite de la fenetre config }
 TitleFlashing: Boolean;               { Clignotement en cours }
 TitleFlashCount: Integer;             { Compteur de clignotements }
 TitleFlashLastTime: LongInt;          { Dernier clignotement }
 TitleFlashState: Boolean;             { Etat du clignotement (on/off) }
 UnreadMailCount: Integer;             { Nombre de messages non lus total }
 NewMailSinceLastCheck: Integer;       { Nouveaux messages depuis derniere verif }

 { ============================================================================
   VARIABLES POUR L'IMPRESSION ET L'APERCU (TODO 21)
   ============================================================================ }

 PrintSettings: TPrintSettings;        { Parametres d'impression }

Type
 TOlA_PrintPages = Array[0..MAX_PRINT_PAGES-1] of TPrintPageContent;
Var
 PrintPages: ^TOlA_PrintPages;
 PrintPageCount: Integer;              { Nombre de pages }
 PrintCurrentPage: Integer;            { Page actuelle dans l'apercu }
 PrintPreviewState: TPrintPreviewState; { Etat de l'apercu }
 PrintPreviewX, PrintPreviewY: Integer; { Position de la fenetre d'apercu }
 PrintPreviewZoom: Integer;            { Niveau de zoom (100 = 100%) }
 PrintConfigState: TPrintConfigState;  { Etat de la configuration }
 PrintConfigX, PrintConfigY: Integer;  { Position de la fenetre config }
 PrintConfigVisible: Boolean;          { Visibilite de la config }
 PrintMessageIndex: Integer;           { Index du message a imprimer }
 PrintInProgress: Boolean;             { Impression en cours }
 PrintFile: Text;                      { Fichier d'impression }

 { ============================================================================
   VARIABLES POUR LA SAUVEGARDE ET L'EXPORT (TODO 22)
   ============================================================================ }

 BackupState: TBackupState;            { Etat de la fenetre }
 BackupOptions: TBackupOptions;        { Options de sauvegarde }
 RestoreOptions: TRestoreOptions;      { Options de restauration }
 BackupStats: TBackupStats;            { Statistiques }
 BackupWindowX, BackupWindowY: Integer; { Position de la fenetre }
 BackupVisible: Boolean;               { Visibilite de la fenetre }
 BackupExportFormat: TMessageExportFormat; { Format d'export courant }
 BackupSelectedMessages: Array[0..99] of Integer; { Messages^ selectionnes }
 BackupSelectedCount: Integer;         { Nombre de messages selectionnes }
 BackupProgressPercent: Integer;       { Pourcentage de progression }
 BackupLastError: String[120];         { Dernier message d'erreur }

 { ============================================================================
   VARIABLES POUR LA CONFIGURATION DES PREFERENCES (TODO 23)
   ============================================================================ }

 OptionsDraft: TUserPreferences;
 EventDialogVisible,EventEditing,EventReturnToList,EventDeletePending: Boolean;
 CalendarEvents,EventBackup: Array[0..127] Of TCalendarEvent;
 EventDraft: TCalendarEvent;
 EventCount,EventEditIndex,EventFocus,EventCursor,EventListCount,EventListSelection,EventListScroll: Integer;
 EventList: Array[0..127] Of Integer;
 EventNextID: LongInt;
 EventError: String[90];
 BusyVisible,BusyGraphicsReady: Boolean;
 BusyTitle,BusyDetail,BusyStageText: String[80];
 BusyDone,BusyTotal,BusyStarted,BusyLastPaint,BusyFrame: LongInt;
 RibbonMode,RibbonKeyboardActive: Boolean;
 RibbonTab,RibbonFocus,RibbonPressed,RibbonHover,RibbonCount: Integer;
 RibbonButtons: Array[0..14] Of TRibbonButton;
 RibbonGroupCount: Integer;
 RibbonGroupX,RibbonGroupW: Array[0..7] Of Integer;
 CalendarVisible, CalendarInitialized, CalendarHasFocus: Boolean;
 CalendarYear,CalendarMonth,CalendarDay: Integer;
 LastViewShortcut: Integer;
 AboutVisible: Boolean;
 OptionsReady: Boolean;
 OptionsFocus, OptionsCursor: Integer;
 PreviewPaneWidth: Integer;
 OptionsError: String[80];
 UserPrefs: TUserPreferences;          { Preferences utilisateur }
 PrefsVisible: Boolean;                { Fenetre visible }
 PrefsWindowX, PrefsWindowY: Integer;  { Position de la fenetre }
 PrefsCurrentTab: TPrefsTab;           { Onglet actif }
 PrefsScrollOffset: Integer;           { Defilement dans l'onglet }
 PrefsHoveredTab: Integer;             { Onglet survole }
 PrefsEditingField: Integer;           { Champ en cours d'edition }
 PrefsEditBuffer: String[80];          { Tampon d'edition }
 PrefsNeedsSave: Boolean;              { Modifications non sauvegardees }

 { ============================================================================
   VARIABLES POUR LE MODE HORS LIGNE ET SYNCHRONISATION (TODO 24)
   ============================================================================ }

 ConnectionState: TConnectionState;    { Etat de connexion actuel }
 LastConnectivityCheck: LongInt;       { Derniere verification connectivite }
 IsManualOffline: Boolean;             { Mode hors ligne force manuellement }

 { File d'attente des operations }
 QueuedOps: Array[0..MAX_QUEUED_OPS-1] of TQueuedOperation;
 QueuedOpCount: Integer;               { Nombre d'operations en attente }
 QueueProcessing: Boolean;             { Traitement en cours }

 { Cache des messages }

Type
 TOlA_CachedMessages = Array[0..MAX_CACHED_MESSAGES-1] of TCachedMessage;
Var
 CachedMessages: ^TOlA_CachedMessages;
 CachedMessageCount: Integer;          { Nombre de messages en cache }

 { Cache des dossiers }
 CachedFolders: Array[0..MAX_CACHED_FOLDERS-1] of TCachedFolder;
 CachedFolderCount: Integer;           { Nombre de dossiers en cache }

 { Statistiques de synchronisation }
 LastSyncStats: TSyncStats;            { Stats de la derniere sync }
 SyncInProgress: Boolean;              { Synchronisation en cours }
 SyncProgress: Integer;                { Progression (0-100) }
 SyncStatusText: String[80];           { Texte d'etat de la sync }

 { Indicateur visuel }
 StatusIndicatorX: Integer;            { Position X de l'indicateur }
 StatusIndicatorY: Integer;            { Position Y de l'indicateur }
 StatusIndicatorVisible: Boolean;      { Indicateur visible }
 StatusBlinkState: Boolean;            { Etat de clignotement }
 LastBlinkTime: LongInt;               { Dernier changement de clignotement }

 { ============================================================================
   VARIABLES POUR LE SUPPORT MULTI-LANGUE (TODO 25)
   ============================================================================ }

 CurrentLanguage: TLanguage;           { Langue actuelle }
 CustomStrings: Array[0..MAX_STRING_IDS-1] of String[40]; { Chaines personnalisees }
 UseCustomStrings: Boolean;            { Utiliser les chaines personnalisees }
 LanguageFilePath: String[80];         { Chemin du fichier de langue }

{ Utilitaires integres: aucune unite utilitaire supplementaire. }


{ API natives declarees ici pour conserver un seul fichier source. }


Var
 IMAPWire, POP3Wire, SMTPWire: TMailConnection;
 MailError, MailStatus: String[80];
 MailRaw: TMailText;
 MessageSources, PendingMessageSources: Array[0..MAX_MESSAGES-1] of TBigRef;
 MailFetchFlags: TMailText;
 MailFetchUID: LongInt;

Type
 TOlA_MailNewMessages = Array[0..MAX_MESSAGES-1] of TMessage;
Var
 MailNewMessages: ^TOlA_MailNewMessages;
 MailFolderAccount: Array[0..MAX_FOLDERS-1] of Integer;
 MailLoadedFolder: Integer;
 

Procedure DrawStatusBar; Forward;
Procedure ReceiveMail; Forward;
Procedure RefreshAccountFolders; Forward;
Function GetTickCount: LongInt; Forward;
Procedure BusyBegin(Title,Detail: String); Forward;
Procedure BusyUpdate(Stage: String; Done,Total: LongInt); Forward;
Procedure BusyStage(Stage: String); Forward;
Procedure BusyPulse(Force: Boolean); Forward;
Procedure BusyEnd; Forward;

Function MailUpper(Text: TMailText): TMailText;
Var I: LongInt;
Begin
 For I:=1 To Length(Text) Do Text[I]:=UpCase(Text[I]);
 MailUpper:=Text;
End;

Function MailTrim(Text: TMailText): TMailText;
Begin
 While (Length(Text)>0) And (Text[1] In [' ',#9,#13,#10]) Do Delete(Text,1,1);
 While (Length(Text)>0) And (Text[Length(Text)] In [' ',#9,#13,#10]) Do Delete(Text,Length(Text),1);
 MailTrim:=Text;
End;

Procedure MailClose(Var C: TMailConnection);
Begin
 If C.Open Then Begin
  If C.Secure Then OsDummy := OsTlsClose(1);
  OsDummy := OsSoClose(C.Sock);
 End;
 C.Open := False; C.Secure := False;
 C.Pending := ''; C.Encrypted := '';
End;

{ Attente courte repetee : le reseau garde ses delais, l indicateur reste anime. }
Function MailWaitSocket(Var C: TMailConnection; Writing: Boolean): Boolean;
Begin
 { sockets bloquantes de TCPIP32.DLL }
 BusyPulse(False);
 MailWaitSocket := C.Open;
End;

Function MailWriteSocket(Var C: TMailConnection; Const Data: TMailText): Boolean;
Var Offset, N: LongInt;
Begin
 MailWriteSocket := False;
 Offset := 1;
 While Offset <= Length(Data) Do Begin
  N := OsSend(C.Sock, LongInt(@Data[Offset]), Length(Data) - Offset + 1, 0);
  If N <= 0 Then Begin MailError := 'Erreur envoi socket'; Exit; End;
  Inc(Offset, N);
 End;
 MailWriteSocket := True;
End;

Function MailReadSocket(Var C: TMailConnection; Var Data: TMailText): Boolean;
Var B: Array[0..255] Of Byte; N, Room, K: LongInt;
Begin
 MailReadSocket := False;
 Room := 250 - Length(Data);   { chaines d'OS2PC : 254 caracteres au plus }
 If Room <= 0 Then Begin MailReadSocket := True; Exit; End;
 BusyPulse(False);
 N := OsRecv(C.Sock, LongInt(@B), Room, 0);
 If N <= 0 Then Begin MailError := 'Connexion fermee ou delai de reception depasse'; Exit; End;
 For K := 0 To N - 1 Do Data := Data + Chr(B[K]);
 MailReadSocket := True;
End;

Function MailStartTLS(Var C: TMailConnection): Boolean;
Begin
 MailStartTLS := False;
 BusyStage('Negociation de la connexion securisee TLS...');
 If Not C.Open Or C.Secure Or (C.Pending <> '') Then Begin
  MailError := 'Etat TLS invalide'; Exit;
 End;
 { TLS32.DLL : TLS 1.3 ou 1.2 sur la socket deja connectee (aussi STARTTLS) }
 If OsTlsOpen(C.Sock, OsZs(C.Host)) <> 1 Then Begin
  MailError := Copy('Echec TLS : ' + OsTlsMessage, 1, 200); Exit;
 End;
 C.Secure := True;
 MailStartTLS := True;
End;

Function MailOpen(Var C: TMailConnection; Host: String; Port: Integer; SSL: Boolean): Boolean;
Var S: LongInt;
Begin
 MailOpen := False; MailClose(C); MailError := '';
 If UserPrefs.Connection.OfflineMode Then Begin MailError:='Mode hors ligne actif'; Exit; End;
 If (Host = '') Or (Port <= 0) Then Begin
  MailError := 'Serveur ou port invalide'; Exit;
 End;
 BusyStage('Resolution du serveur...');
 C.Host := Host;
 If OsResolve(Host) = 0 Then Begin MailError := 'Resolution DNS impossible'; Exit; End;
 BusyStage('Connexion au serveur...');
 S := OsTcpOpen(Host, Port);
 If S < 0 Then Begin MailError := 'Connexion au serveur impossible ou delai depasse'; Exit; End;
 C.Sock := S; C.Open := True;
 If SSL Then If Not MailStartTLS(C) Then Begin MailClose(C); Exit; End;
 MailOpen := True;
End;

Function MailWrite(Var C: TMailConnection; Const Text: TMailText): Boolean;
Begin
 MailWrite := False;
 If Not C.Open Then Begin MailError := 'Non connecte'; Exit; End;
 If Not C.Secure Then Begin MailWrite := MailWriteSocket(C, Text); Exit; End;
 If Text = '' Then Begin MailWrite := True; Exit; End;
 If OsTlsSend(1, LongInt(@Text[1]), Length(Text)) <> Length(Text) Then Begin
  MailError := 'Erreur chiffrement TLS'; Exit;
 End;
 MailWrite := True;
End;

Function MailFill(Var C: TMailConnection): Boolean;
Var B: Array[0..255] Of Byte; N, Room, K: LongInt;
Begin
 MailFill := False;
 If Not C.Open Then Begin MailError := 'Non connecte'; Exit; End;
 If Not C.Secure Then Begin MailFill := MailReadSocket(C, C.Pending); Exit; End;
 Room := 250 - Length(C.Pending);
 If Room <= 0 Then Begin MailFill := True; Exit; End;
 BusyPulse(False);
 N := OsTlsRecv(1, LongInt(@B), Room);
 If N <= 0 Then Begin MailError := 'Connexion TLS fermee'; Exit; End;
 For K := 0 To N - 1 Do C.Pending := C.Pending + Chr(B[K]);
 MailFill := True;
End;

Function MailReadLine(Var C: TMailConnection; Var Line: TMailText): Boolean;
Var P: LongInt;
Begin
 MailReadLine := False; Line := ''; OlLinePartial := False;
 Repeat
  P := Pos(#13#10, C.Pending);
  If P > 0 Then Begin
   Line := Copy(C.Pending, 1, P-1); Delete(C.Pending, 1, P+1);
   OlDbg('< ' + Line);
   MailReadLine := True; Exit;
  End;
  { ligne de plus de 250 caracteres : rendue par morceaux (OlLinePartial) }
  If Length(C.Pending) >= 248 Then Begin
   If C.Pending[Length(C.Pending)] = #13 Then Begin
    Line := Copy(C.Pending, 1, Length(C.Pending) - 1); C.Pending := #13;
   End Else Begin
    Line := C.Pending; C.Pending := '';
   End;
   OlLinePartial := True; MailReadLine := True; Exit;
  End;
  If Not MailFill(C) Then Exit;
 Until False;
End;

Function MailReadBytes(Var C: TMailConnection; Count: LongInt; Var Data: TMailText): Boolean;
Var N, Room: LongInt; B: Array[0..4095] Of Byte;
Begin
 { litteral IMAP (message complet) : directement dans le tampon OlIn }
 MailReadBytes := False; Data := '';
 If (Count < 0) Or (Count > 10485760) Then Begin MailError := 'Message trop grand (10 Mo maximum)'; Exit; End;
 N := Length(C.Pending);
 If N > Count Then N := Count;
 If N > 0 Then Begin
  OlInAddBuf(LongInt(@C.Pending[1]), N); Delete(C.Pending, 1, N); Count := Count - N;
 End;
 While Count > 0 Do Begin
  Room := Count; If Room > 4096 Then Room := 4096;
  If C.Secure Then N := OsTlsRecv(1, LongInt(@B), Room) Else N := OsRecv(C.Sock, LongInt(@B), Room, 0);
  If N <= 0 Then Begin MailError := 'Connexion fermee pendant la reception'; Exit; End;
  OlInAddBuf(LongInt(@B), N); Count := Count - N;
  BusyPulse(False);
 End;
 MailReadBytes := True;
End;

Function MailSafe(Const Text: TMailText): Boolean;
Var MailSafe_R: Boolean;
Begin
 MailSafe_R := (Pos(#13, Text)=0) And (Pos(#10, Text)=0) And (Pos(#0, Text)=0);
 If Not MailSafe_R Then MailError := 'Caractere interdit dans une commande';
 MailSafe := MailSafe_R;
End;

Function MailQuote(Const Text: TMailText): TMailText;
Var I: Integer;
Var MailQuote_R: TMailText;
Begin
 MailQuote_R := '"';
 For I := 1 To Length(Text) Do Begin
  If Text[I] In ['"', '\'] Then MailQuote_R := MailQuote_R + '\';
  MailQuote_R := MailQuote_R + Text[I];
 End;
 MailQuote_R := MailQuote_R + '"';
 MailQuote := MailQuote_R;
End;

{ Declarations avancees pour utilisation avant definition }
Procedure DrawInterface; Forward;
Procedure DrawMenuBar; Forward;
Procedure DrawRibbonTabs; Forward;
Procedure DrawRibbon; Forward;
Procedure RibbonSelectTab(Index: Integer; Keyboard: Boolean); Forward;
Function RibbonTabAt(X,Y: Integer): Integer; Forward;
Procedure DrawComposerWindow; Forward;
Procedure OpenMessageFile; Forward;
Procedure SaveMessageAs; Forward;
Procedure ShowSortDialog; Forward;
Procedure ShowColumnsDialog; Forward;
Procedure Rules_Show; Forward;
Procedure Prefs_Show; Forward;
Procedure ShowAboutDialog; Forward;
Procedure CalendarShow(Visible: Boolean); Forward;
Procedure FocusMail; Forward;
Procedure CalendarMoveMonth(Delta: Integer); Forward;
Procedure CalendarToday; Forward;
Procedure CalendarUpdateMenus; Forward;
Function CalendarPaneWidth: Integer; Forward;
Procedure EventNew(Meeting: Boolean); Forward;
Procedure EventAgenda; Forward;
Function EventOnDay(Const E: TCalendarEvent; Y,M,D: Integer): Boolean; Forward;
Procedure EventDraw; Forward;
Function WriteMessageFile(Path: TMailText; AllowReplace: Boolean): Boolean; Forward;
Function MailTextBody(Const Raw: TMailText; Depth: Integer): TMailText; Forward;
Procedure DrawColumnsDialog; Forward;
Procedure DrawSortDialog; Forward;
Procedure DrawOpenFileDialog; Forward;
Procedure CalculateLayout; Forward;
Procedure DrawFolderPane; Forward;
Procedure OpenNewMessage; Forward;
Procedure OpenReplyMessage(ReplyAll: Boolean); Forward;
Procedure OpenForwardMessage; Forward;
Procedure ShowAccountManagerDialog; Forward;
Procedure Search_AddToHistory(SearchText: String; ResultCount: Integer); Forward;
Procedure Offline_StartSync; Forward;

{ ============================================================================
  PROCEDURES D'INITIALISATION GRAPHIQUE
  ============================================================================ }

{ Meme selection que BROWSER.PAS: palette indexee et resolution maximale. }
Procedure SelectScreenDriverMode(WantMaxScreen: Boolean;
 Var Driver, Mode: Integer);

Begin
 
 Driver := Detect;
 Mode := VGAHi;
 
End;

Procedure UpdateScreenGeometry(Width, Height: Integer);
Begin
 SCREEN_WIDTH := Width;
 SCREEN_HEIGHT := Height;
 DIALOG_X := (SCREEN_WIDTH - DIALOG_WIDTH) Div 2;
 DIALOG_Y := (SCREEN_HEIGHT - DIALOG_HEIGHT) Div 2;
 COMPOSER_X := (SCREEN_WIDTH - COMPOSER_WIDTH) Div 2;
 COMPOSER_Y := (SCREEN_HEIGHT - COMPOSER_HEIGHT) Div 2;
 ATTACH_PANEL_Y := COMPOSER_Y + COMPOSER_HEADER_HEIGHT - ATTACH_PANEL_HEIGHT - 5;
End;

{ Les seize couleurs de l interface restent identiques dans le pilote D8bit. }
Procedure InitializeScreenPalette;

Begin
 
End;

Procedure InitializeGraphics;
Var
 Driver, Mode: Integer;
 ErrCode: Integer;
Begin
 SelectScreenDriverMode(MaxScreen, Driver, Mode);
 GInitGraph(Driver,Mode,'');
 ErrCode:=GGraphResult;
 If ErrCode=grOk Then Begin
  UpdateScreenGeometry(GGetMaxX + 1, GGetMaxY + 1);
  InitializeScreenPalette;
  GSetColor(White);
  GSetLineStyle(0,0,1);
 End
  Else
 Begin
  WriteLn('Erreur graphique : ',GGraphErrorMsg(ErrCode));
  Halt;
 End;
End;

{ ============================================================================
  PROCEDURES DE GESTION DE LA SOURIS
  ============================================================================ }


{ souris : voir OL_PORT.INC (messages de PM) }

{ Horloge en millisecondes: runtime FPC ou heure DOS, sans unite utilitaire. }
Function GetTickCount: LongInt;
Begin
 GetTickCount := KTicks;
End;


{ Initialise les variables de gestion de la souris }
Procedure InitMouseState;
Begin
 LastClickTime := 0;
 LastClickX := 0;
 LastClickY := 0;
 LastClickBtn := 0;
 ClickCount := 0;
 MouseWheelDelta := 0;
 ScrollOffset := 0;
End;

{ Lecture de la molette de la souris (INT 33h fonction 11h pour Turbo Pascal) }

{ Verifie si c'est un double-clic }
Function IsDoubleClick(X, Y, Btn: Integer): Boolean;
Var
 CurrentTime: LongInt;
 DeltaX, DeltaY: Integer;
Begin
 IsDoubleClick := False;
 CurrentTime := GetTickCount;

 { Verifier si le bouton est le meme que le precedent }
 If Btn <> LastClickBtn Then Begin
  LastClickTime := CurrentTime;
  LastClickX := X;
  LastClickY := Y;
  LastClickBtn := Btn;
  ClickCount := 1;
  Exit;
 End;

 { Calculer la distance depuis le dernier clic }
 DeltaX := Abs(X - LastClickX);
 DeltaY := Abs(Y - LastClickY);

 { Verifier le temps et la distance }
 If (CurrentTime - LastClickTime <= DOUBLE_CLICK_TIME) And
    (DeltaX <= DOUBLE_CLICK_DIST) And
    (DeltaY <= DOUBLE_CLICK_DIST) Then Begin
  Inc(ClickCount);
  If ClickCount >= 2 Then Begin
   IsDoubleClick := True;
   ClickCount := 0;
  End;
 End Else Begin
  ClickCount := 1;
 End;

 LastClickTime := CurrentTime;
 LastClickX := X;
 LastClickY := Y;
 LastClickBtn := Btn;
End;

{ Detecte le type d'evenement souris }
Function DetectMouseEvent(OldBtn, NewBtn, X, Y: Integer): TMouseEvent;
Var
 WheelDelta: Integer;
Begin
 DetectMouseEvent := meNone;

 { Verifier la molette de defilement }
 GetMouseWheel(WheelDelta);
 If WheelDelta > 0 Then Begin
  DetectMouseEvent := meWheelUp;
  Exit;
 End Else If WheelDelta < 0 Then Begin
  DetectMouseEvent := meWheelDown;
  Exit;
 End;

 { Detection du clic gauche (bouton enfonce puis relache) }
 If ((OldBtn And MOUSE_LEFT) <> 0) And ((NewBtn And MOUSE_LEFT) = 0) Then Begin
  If IsDoubleClick(X, Y, MOUSE_LEFT) Then
   DetectMouseEvent := meLeftDoubleClick
  Else
   DetectMouseEvent := meLeftClick;
  Exit;
 End;

 { Detection du clic droit }
 If ((OldBtn And MOUSE_RIGHT) <> 0) And ((NewBtn And MOUSE_RIGHT) = 0) Then Begin
  If IsDoubleClick(X, Y, MOUSE_RIGHT) Then
   DetectMouseEvent := meRightDoubleClick
  Else
   DetectMouseEvent := meRightClick;
  Exit;
 End;

 { Detection du clic milieu }
 If ((OldBtn And MOUSE_MIDDLE) <> 0) And ((NewBtn And MOUSE_MIDDLE) = 0) Then Begin
  DetectMouseEvent := meMiddleClick;
  Exit;
 End;
End;

{ ============================================================================
  PROCEDURES DE DESSIN UTILITAIRES
  ============================================================================ }

{ Dessine un rectangle rempli }
Procedure FillRect(X1, Y1, X2, Y2: Integer; Color: Word);
Begin
 GSetFillStyle(SolidFill, Color);
 GBar(X1, Y1, X2, Y2);
End;

{ Dessine un rectangle avec effet 3D (relief) }
Procedure Draw3DRect(X1, Y1, X2, Y2: Integer; Raised: Boolean);
Begin
 If Raised Then Begin
  GSetColor(COLOR_BUTTON_LIGHT);
  GLine(X1, Y1, X2, Y1);
  GLine(X1, Y1, X1, Y2);
  GSetColor(COLOR_BUTTON_DARK);
  GLine(X1, Y2, X2, Y2);
  GLine(X2, Y1, X2, Y2);
 End Else Begin
  GSetColor(COLOR_BUTTON_DARK);
  GLine(X1, Y1, X2, Y1);
  GLine(X1, Y1, X1, Y2);
  GSetColor(COLOR_BUTTON_LIGHT);
  GLine(X1, Y2, X2, Y2);
  GLine(X2, Y1, X2, Y2);
 End;
End;

{ Dessine un bouton de la barre d'outils avec etat }
Procedure DrawToolButton(X, Y, W, H: Integer; Pressed: Boolean);
Begin
 FillRect(X, Y, X + W, Y + H, COLOR_BUTTON_FACE);
 Draw3DRect(X, Y, X + W, Y + H, Not Pressed);
End;

{ Dessine un bouton de barre d'outils avec etat complet }
Procedure DrawToolButtonEx(Var Btn: TToolButton);
Var
 BgColor: Word;
Begin
 { Choisir la couleur de fond selon l'etat }
 Case Btn.State Of
  tbsNormal:   BgColor := COLOR_BUTTON_FACE;
  tbsHover:    BgColor := COLOR_LIST_SELECTED;
  tbsPressed:  BgColor := COLOR_BUTTON_FACE;
  tbsDisabled: BgColor := COLOR_BUTTON_FACE;
 End;

 { Dessiner le fond du bouton }
 FillRect(Btn.X, Btn.Y, Btn.X + Btn.W, Btn.Y + Btn.H, BgColor);

 { Dessiner le relief 3D selon l'etat }
 Case Btn.State Of
  tbsNormal:   Draw3DRect(Btn.X, Btn.Y, Btn.X + Btn.W, Btn.Y + Btn.H, True);
  tbsHover:    Draw3DRect(Btn.X, Btn.Y, Btn.X + Btn.W, Btn.Y + Btn.H, True);
  tbsPressed:  Draw3DRect(Btn.X, Btn.Y, Btn.X + Btn.W, Btn.Y + Btn.H, False);
  tbsDisabled: Begin End; { Pas de bordure pour desactive }
 End;
End;

{ Dessine une icone de bouton de barre d'outils }
Procedure DrawToolbarIcon(X, Y: Integer; IconType: TToolIconType; Disabled: Boolean);
Var
 IconColor: Word;
Begin
 If Disabled Then
  IconColor := COLOR_BUTTON_DARK
 Else
  IconColor := COLOR_MENU_TEXT;

 GSetColor(IconColor);

 Case IconType Of
  tiNewMsg: Begin
   { Icone enveloppe avec '+' }
   GRectangle(X, Y + 2, X + 14, Y + 12);
   GLine(X, Y + 2, X + 7, Y + 7);
   GLine(X + 14, Y + 2, X + 7, Y + 7);
   { Signe + }
   GSetColor(LightGreen);
   If Not Disabled Then Begin
    GLine(X + 11, Y, X + 11, Y + 6);
    GLine(X + 8, Y + 3, X + 14, Y + 3);
   End;
  End;

  tiReply: Begin
   { Fleche vers la gauche }
   GLine(X + 2, Y + 6, X + 12, Y + 6);
   GLine(X + 2, Y + 6, X + 6, Y + 2);
   GLine(X + 2, Y + 6, X + 6, Y + 10);
  End;

  tiReplyAll: Begin
   { Deux fleches vers la gauche }
   GLine(X + 4, Y + 6, X + 12, Y + 6);
   GLine(X + 4, Y + 6, X + 8, Y + 2);
   GLine(X + 4, Y + 6, X + 8, Y + 10);
   GLine(X, Y + 6, X + 4, Y + 2);
   GLine(X, Y + 6, X + 4, Y + 10);
  End;

  tiForward: Begin
   { Fleche vers la droite }
   GLine(X + 2, Y + 6, X + 12, Y + 6);
   GLine(X + 12, Y + 6, X + 8, Y + 2);
   GLine(X + 12, Y + 6, X + 8, Y + 10);
  End;

  tiSendRecv: Begin
   { Fleches bidirectionnelles }
   { Fleche vers le haut }
   GLine(X + 4, Y + 2, X + 4, Y + 10);
   GLine(X + 4, Y + 2, X + 2, Y + 5);
   GLine(X + 4, Y + 2, X + 6, Y + 5);
   { Fleche vers le bas }
   GLine(X + 10, Y + 2, X + 10, Y + 10);
   GLine(X + 10, Y + 10, X + 8, Y + 7);
   GLine(X + 10, Y + 10, X + 12, Y + 7);
  End;

  tiDelete: Begin
   { Croix }
   GSetColor(LightRed);
   If Disabled Then GSetColor(COLOR_BUTTON_DARK);
   GLine(X + 2, Y + 2, X + 12, Y + 12);
   GLine(X + 12, Y + 2, X + 2, Y + 12);
   GLine(X + 3, Y + 2, X + 13, Y + 12);
   GLine(X + 13, Y + 2, X + 3, Y + 12);
  End;

  tiPrint: Begin
   { Imprimante }
   GRectangle(X + 2, Y, X + 12, Y + 4);
   GRectangle(X, Y + 4, X + 14, Y + 10);
   GRectangle(X + 3, Y + 8, X + 11, Y + 14);
  End;

  tiAddressBook: Begin
   { Carnet }
   GRectangle(X + 2, Y, X + 12, Y + 14);
   GLine(X + 4, Y + 3, X + 10, Y + 3);
   GLine(X + 4, Y + 6, X + 10, Y + 6);
   GLine(X + 4, Y + 9, X + 10, Y + 9);
   { Reliure }
   GSetColor(COLOR_BUTTON_DARK);
   GLine(X + 2, Y, X + 2, Y + 14);
  End;

  tiSeparator: Begin
   { Separateur vertical }
   GSetColor(COLOR_BUTTON_DARK);
   GLine(X, Y + 2, X, Y + 14);
   GSetColor(COLOR_BUTTON_LIGHT);
   GLine(X + 1, Y + 2, X + 1, Y + 14);
  End;
 End;
End;

{ Initialise les boutons de la barre d'outils }
Procedure InitializeToolbar;
Var
 BtnX, BtnY, BtnW, BtnH: Integer;
 I: Integer;
Begin
 ToolButtonCount := 0;
 HoveredToolButton := -1;
 PressedToolButton := -1;
 TooltipVisible := False;

 BtnY := Layout.ToolBarRect.Y1 + 3;
 BtnW := 60;
 BtnH := 22;
 BtnX := 4;

 { Bouton Nouveau message }
 ToolButtons[0].X := BtnX;
 ToolButtons[0].Y := BtnY;
 ToolButtons[0].W := BtnW;
 ToolButtons[0].H := BtnH;
 ToolButtons[0].Caption := 'Nouveau';
 ToolButtons[0].Tooltip := 'Creer un nouveau message (Ctrl+N)';
 ToolButtons[0].IconType := tiNewMsg;
 ToolButtons[0].CommandID := CMD_MSG_NEW;
 ToolButtons[0].State := tbsNormal;
 ToolButtons[0].Enabled := True;

 { Bouton Repondre }
 BtnX := BtnX + BtnW + 4;
 ToolButtons[1].X := BtnX;
 ToolButtons[1].Y := BtnY;
 ToolButtons[1].W := BtnW;
 ToolButtons[1].H := BtnH;
 ToolButtons[1].Caption := 'Repondre';
 ToolButtons[1].Tooltip := 'Repondre a l''expediteur (Ctrl+R)';
 ToolButtons[1].IconType := tiReply;
 ToolButtons[1].CommandID := CMD_MSG_REPLY;
 ToolButtons[1].State := tbsNormal;
 ToolButtons[1].Enabled := True;

 { Bouton Repondre a tous }
 BtnX := BtnX + BtnW + 4;
 BtnW := 70;
 ToolButtons[2].X := BtnX;
 ToolButtons[2].Y := BtnY;
 ToolButtons[2].W := BtnW;
 ToolButtons[2].H := BtnH;
 ToolButtons[2].Caption := 'Rep.tous';
 ToolButtons[2].Tooltip := 'Repondre a tous les destinataires';
 ToolButtons[2].IconType := tiReplyAll;
 ToolButtons[2].CommandID := CMD_MSG_REPLYALL;
 ToolButtons[2].State := tbsNormal;
 ToolButtons[2].Enabled := True;

 { Bouton Transferer }
 BtnX := BtnX + BtnW + 4;
 BtnW := 70;
 ToolButtons[3].X := BtnX;
 ToolButtons[3].Y := BtnY;
 ToolButtons[3].W := BtnW;
 ToolButtons[3].H := BtnH;
 ToolButtons[3].Caption := 'Transferer';
 ToolButtons[3].Tooltip := 'Transferer ce message (Ctrl+F)';
 ToolButtons[3].IconType := tiForward;
 ToolButtons[3].CommandID := CMD_MSG_FORWARD;
 ToolButtons[3].State := tbsNormal;
 ToolButtons[3].Enabled := True;

 { Separateur }
 BtnX := BtnX + BtnW + 8;
 ToolButtons[4].X := BtnX;
 ToolButtons[4].Y := BtnY;
 ToolButtons[4].W := 2;
 ToolButtons[4].H := BtnH;
 ToolButtons[4].Caption := '';
 ToolButtons[4].Tooltip := '';
 ToolButtons[4].IconType := tiSeparator;
 ToolButtons[4].CommandID := 0;
 ToolButtons[4].State := tbsNormal;
 ToolButtons[4].Enabled := False;

 { Bouton Envoyer/Recevoir }
 BtnX := BtnX + 8;
 BtnW := 80;
 ToolButtons[5].X := BtnX;
 ToolButtons[5].Y := BtnY;
 ToolButtons[5].W := BtnW;
 ToolButtons[5].H := BtnH;
 ToolButtons[5].Caption := 'Env/Recv';
 ToolButtons[5].Tooltip := 'Envoyer et recevoir les messages';
 ToolButtons[5].IconType := tiSendRecv;
 ToolButtons[5].CommandID := CMD_TB_SENDRECV;
 ToolButtons[5].State := tbsNormal;
 ToolButtons[5].Enabled := True;

 { Bouton Supprimer }
 BtnX := BtnX + BtnW + 4;
 BtnW := 65;
 ToolButtons[6].X := BtnX;
 ToolButtons[6].Y := BtnY;
 ToolButtons[6].W := BtnW;
 ToolButtons[6].H := BtnH;
 ToolButtons[6].Caption := 'Supprimer';
 ToolButtons[6].Tooltip := 'Supprimer le message selectionne';
 ToolButtons[6].IconType := tiDelete;
 ToolButtons[6].CommandID := CMD_MSG_DELETE;
 ToolButtons[6].State := tbsNormal;
 ToolButtons[6].Enabled := True;

 { Bouton Imprimer }
 BtnX := BtnX + BtnW + 4;
 BtnW := 60;
 ToolButtons[7].X := BtnX;
 ToolButtons[7].Y := BtnY;
 ToolButtons[7].W := BtnW;
 ToolButtons[7].H := BtnH;
 ToolButtons[7].Caption := 'Imprimer';
 ToolButtons[7].Tooltip := 'Imprimer le message (Ctrl+P)';
 ToolButtons[7].IconType := tiPrint;
 ToolButtons[7].CommandID := CMD_FILE_PRINT;
 ToolButtons[7].State := tbsNormal;
 ToolButtons[7].Enabled := True;

 { Bouton Carnet d'adresses }
 BtnX := BtnX + BtnW + 4;
 BtnW := 65;
 ToolButtons[8].X := BtnX;
 ToolButtons[8].Y := BtnY;
 ToolButtons[8].W := BtnW;
 ToolButtons[8].H := BtnH;
 ToolButtons[8].Caption := 'Adresses';
 ToolButtons[8].Tooltip := 'Ouvrir le carnet d''adresses';
 ToolButtons[8].IconType := tiAddressBook;
 ToolButtons[8].CommandID := CMD_TB_ADDRESSBOOK;
 ToolButtons[8].State := tbsNormal;
 ToolButtons[8].Enabled := True;

 ToolButtonCount := 9;
End;

{ Trouve le bouton de barre d'outils a une position donnee }
Function GetToolButtonAtPoint(X, Y: Integer): Integer;
Var
 I: Integer;
Begin
 GetToolButtonAtPoint := -1;
 For I := 0 To ToolButtonCount - 1 Do Begin
  If ToolButtons[I].IconType <> tiSeparator Then Begin
   If (X >= ToolButtons[I].X) And (X <= ToolButtons[I].X + ToolButtons[I].W) And
      (Y >= ToolButtons[I].Y) And (Y <= ToolButtons[I].Y + ToolButtons[I].H) Then Begin
    GetToolButtonAtPoint := I;
    Exit;
   End;
  End;
 End;
End;

{ Affiche une infobulle }
Procedure ShowTooltip(X, Y: Integer; Text: String);
Var
 TipW, TipH: Integer;
 TipX, TipY: Integer;
Begin
 If Text = '' Then Exit;

 TipW := GTextWidth(Text) + 8;
 TipH := GTextHeight(Text) + 6;

 { Positionner l'infobulle sous le curseur }
 TipX := X;
 TipY := Y + 20;

 { S'assurer que l'infobulle reste visible }
 If TipX + TipW > SCREEN_WIDTH Then
  TipX := SCREEN_WIDTH - TipW - 2;
 If TipY + TipH > SCREEN_HEIGHT Then
  TipY := Y - TipH - 5;

 HideMouse;

 { Fond de l'infobulle (jaune clair) }
 GSetFillStyle(SolidFill, Yellow);
 GBar(TipX, TipY, TipX + TipW, TipY + TipH);

 { Bordure noire }
 GSetColor(Black);
 GRectangle(TipX, TipY, TipX + TipW, TipY + TipH);

 { Texte }
 GSetColor(Black);
 GOutTextXY(TipX + 4, TipY + 3, Text);

 ShowMouse;

 TooltipVisible := True;
 TooltipX := TipX;
 TooltipY := TipY;
 TooltipText := Text;
End;

{ Cache l'infobulle et redessine la zone }
Procedure HideTooltip;
Begin
 If TooltipVisible Then Begin
  TooltipVisible := False;
  DrawInterface;
 End;
End;

{ Dessine un texte centre dans un rectangle }
Procedure DrawCenteredText(X1, Y1, X2, Y2: Integer; Text: String; Color: Word);
Var
 TextW, TextH: Integer;
 TX, TY: Integer;
Begin
 GSetColor(Color);
 TextW := GTextWidth(Text);
 TextH := GTextHeight(Text);
 TX := X1 + ((X2 - X1 - TextW) Div 2);
 TY := Y1 + ((Y2 - Y1 - TextH) Div 2);
 GOutTextXY(TX, TY, Text);
End;

{ ============================================================================
  PROCEDURES D'INITIALISATION ET GESTION DES MENUS
  ============================================================================ }

{ Ajoute un element a un menu }
Procedure AddMenuItem(Var Menu: TDropdownMenu; Caption, Shortcut: String;
                      IsSeparator: Boolean; ItemID: Integer);
Begin
 If Menu.ItemCount < 15 Then Begin
  Menu.Items[Menu.ItemCount].Caption := Caption;
  Menu.Items[Menu.ItemCount].Shortcut := Shortcut;
  Menu.Items[Menu.ItemCount].Separator := IsSeparator;
  Menu.Items[Menu.ItemCount].Enabled := True;
  Menu.Items[Menu.ItemCount].ItemID := ItemID;
  Inc(Menu.ItemCount);
 End;
End;

{ Initialise tous les menus de la barre }
Procedure InitializeMenus;
Var
 I,J,NeededWidth: Integer;
 MenuX: Integer;
Begin
 MenuCount := 6;
 ActiveMenu := -1;
 ActiveMenuItem := -1;
 MenuBarActive := False;

 { Initialiser les positions des menus }
 MenuX := 8;

 { Menu Fichier }
 Menus[0].Title := 'Fichier';
 Menus[0].X := MenuX;
 Menus[0].Width := GTextWidth('Fichier') + 16;
 Menus[0].ItemCount := 0;
 AddMenuItem(Menus[0], 'Nouveau message', 'Ctrl+N', False, CMD_FILE_NEW);
 AddMenuItem(Menus[0], 'Nouveau rendez-vous...', '', False, CMD_EVENT_NEW);
 AddMenuItem(Menus[0], 'Nouvelle reunion...', '', False, CMD_EVENT_MEETING);
 AddMenuItem(Menus[0], 'Ouvrir', 'Ctrl+O', False, CMD_FILE_OPEN);
 AddMenuItem(Menus[0], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[0], 'Enregistrer sous...', 'Ctrl+S', False, CMD_FILE_SAVEAS);
 AddMenuItem(Menus[0], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[0], 'Imprimer...', 'Ctrl+P', False, CMD_FILE_PRINT);
 AddMenuItem(Menus[0], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[0], 'Quitter', 'Alt+F4', False, CMD_FILE_EXIT);

 MenuX := MenuX + Menus[0].Width;

 { Menu Edition }
 Menus[1].Title := 'Edition';
 Menus[1].X := MenuX;
 Menus[1].Width := GTextWidth('Edition') + 16;
 Menus[1].ItemCount := 0;
 AddMenuItem(Menus[1], 'Annuler', 'Ctrl+Z', False, CMD_EDIT_UNDO);
 AddMenuItem(Menus[1], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[1], 'Couper', 'Ctrl+X', False, CMD_EDIT_CUT);
 AddMenuItem(Menus[1], 'Copier', 'Ctrl+C', False, CMD_EDIT_COPY);
 AddMenuItem(Menus[1], 'Coller', 'Ctrl+V', False, CMD_EDIT_PASTE);
 AddMenuItem(Menus[1], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[1], 'Selectionner tout', 'Ctrl+A', False, CMD_EDIT_SELECTALL);

 MenuX := MenuX + Menus[1].Width;

 { Menu Affichage }
 Menus[2].Title := 'Affichage';
 Menus[2].X := MenuX;
 Menus[2].Width := GTextWidth('Affichage') + 16;
 Menus[2].ItemCount := 0;
 AddMenuItem(Menus[2], 'Volet de lecture', '', False, CMD_VIEW_PREVIEW_SHOW);
 AddMenuItem(Menus[2], 'Orientation volet', '', False, CMD_VIEW_PREVIEW_ORIENT);
 AddMenuItem(Menus[2], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[2], 'Trier par...', '', False, CMD_VIEW_SORTBY);
 AddMenuItem(Menus[2], 'Colonnes...', '', False, CMD_VIEW_COLUMNS);
 AddMenuItem(Menus[2], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[2], 'Actualiser', 'F5', False, CMD_VIEW_REFRESH);
 AddMenuItem(Menus[2], '', '', True, 0);
 AddMenuItem(Menus[2], 'Calendrier', 'Ctrl+2', False, CMD_VIEW_CALENDAR);
 AddMenuItem(Menus[2], 'Courrier', 'Ctrl+1', False, CMD_VIEW_MAIL);
 AddMenuItem(Menus[2], 'Mois precedent', 'PgPrec', False, CMD_CAL_PREVIOUS);
 AddMenuItem(Menus[2], 'Mois suivant', 'PgSuiv', False, CMD_CAL_NEXT);
 AddMenuItem(Menus[2], 'Aujourd''hui', 'Debut', False, CMD_CAL_TODAY);
 AddMenuItem(Menus[2], 'Agenda du jour...', '', False, CMD_EVENT_AGENDA);

 MenuX := MenuX + Menus[2].Width;

 { Menu Outils }
 Menus[3].Title := 'Outils';
 Menus[3].X := MenuX;
 Menus[3].Width := GTextWidth('Outils') + 16;
 Menus[3].ItemCount := 0;
 AddMenuItem(Menus[3], 'Comptes...', '', False, CMD_TOOLS_ACCOUNTS);
 AddMenuItem(Menus[3], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[3], 'Regles de messages...', '', False, CMD_TOOLS_RULES);
 AddMenuItem(Menus[3], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[3], 'Options...', '', False, CMD_TOOLS_OPTIONS);

 MenuX := MenuX + Menus[3].Width;

 { Menu Message }
 Menus[4].Title := 'Message';
 Menus[4].X := MenuX;
 Menus[4].Width := GTextWidth('Message') + 16;
 Menus[4].ItemCount := 0;
 AddMenuItem(Menus[4], 'Nouveau message', 'Ctrl+N', False, CMD_MSG_NEW);
 AddMenuItem(Menus[4], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[4], 'Repondre', 'Ctrl+R', False, CMD_MSG_REPLY);
 AddMenuItem(Menus[4], 'Repondre a tous', 'Ctrl+Maj+R', False, CMD_MSG_REPLYALL);
 AddMenuItem(Menus[4], 'Transferer', 'Ctrl+F', False, CMD_MSG_FORWARD);
 AddMenuItem(Menus[4], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[4], 'Supprimer', 'Suppr', False, CMD_MSG_DELETE);
 If RibbonMode Then Begin
  AddMenuItem(Menus[4], '', '', True, 0);
  AddMenuItem(Menus[4], 'Envoyer/Recevoir', '', False, CMD_TB_SENDRECV);
  AddMenuItem(Menus[4], 'Carnet d''adresses', '', False, CMD_TB_ADDRESSBOOK);
 End;

 MenuX := MenuX + Menus[4].Width;

 { Menu Aide (?) }
 Menus[5].Title := '?';
 Menus[5].X := MenuX;
 Menus[5].Width := GTextWidth('?') + 16;
 Menus[5].ItemCount := 0;
 AddMenuItem(Menus[5], 'Aide en ligne', 'F1', False, CMD_HELP_HELP);
 AddMenuItem(Menus[5], '', '', True, 0); { Separateur }
 AddMenuItem(Menus[5], 'A propos...', '', False, CMD_HELP_ABOUT);

 CalendarUpdateMenus;

 { Calculer les dimensions des menus deroulants }
 For I := 0 To MenuCount - 1 Do Begin
  Menus[I].DropX := Menus[I].X;
  Menus[I].DropY := Layout.MenuBarRect.Y2 + 1;
  Menus[I].DropWidth := 180;
  For J:=0 To Menus[I].ItemCount-1 Do Begin
   NeededWidth:=GTextWidth(Menus[I].Items[J].Caption)+GTextWidth(Menus[I].Items[J].Shortcut)+32;
   If NeededWidth>Menus[I].DropWidth Then Menus[I].DropWidth:=NeededWidth;
  End;
  If Menus[I].DropX+Menus[I].DropWidth>SCREEN_WIDTH Then
   Menus[I].DropX:=SCREEN_WIDTH-Menus[I].DropWidth;
  Menus[I].DropHeight := Menus[I].ItemCount * 18 + 4;
 End;
End;

{ Dessine un menu deroulant }
Procedure DrawDropdownMenu(MenuIndex: Integer);
Var
 I: Integer;
 ItemY: Integer;
 ItemX1, ItemY1, ItemX2, ItemY2: Integer;
Begin
 If (MenuIndex < 0) Or (MenuIndex >= MenuCount) Then Exit;
 If RibbonMode Then Begin RibbonSelectTab(MenuIndex,True); Exit; End;

 HideMouse;
 DrawMenuBar;

 { Fond du menu deroulant }
 FillRect(Menus[MenuIndex].DropX, Menus[MenuIndex].DropY,
          Menus[MenuIndex].DropX + Menus[MenuIndex].DropWidth,
          Menus[MenuIndex].DropY + Menus[MenuIndex].DropHeight,
          COLOR_MENU_BG);
 Draw3DRect(Menus[MenuIndex].DropX, Menus[MenuIndex].DropY,
            Menus[MenuIndex].DropX + Menus[MenuIndex].DropWidth,
            Menus[MenuIndex].DropY + Menus[MenuIndex].DropHeight, True);

 { Dessiner chaque element }
 ItemY := Menus[MenuIndex].DropY + 2;

 For I := 0 To Menus[MenuIndex].ItemCount - 1 Do Begin
  ItemX1 := Menus[MenuIndex].DropX + 2;
  ItemY1 := ItemY;
  ItemX2 := Menus[MenuIndex].DropX + Menus[MenuIndex].DropWidth - 2;
  ItemY2 := ItemY + 16;

  If Menus[MenuIndex].Items[I].Separator Then Begin
   { Dessiner un separateur }
   GSetColor(COLOR_BUTTON_DARK);
   GLine(ItemX1, ItemY1 + 8, ItemX2, ItemY1 + 8);
   GSetColor(COLOR_BUTTON_LIGHT);
   GLine(ItemX1, ItemY1 + 9, ItemX2, ItemY1 + 9);
  End Else Begin
   { Element survole? }
   If I = ActiveMenuItem Then Begin
    FillRect(ItemX1, ItemY1, ItemX2, ItemY2, COLOR_LIST_SELECTED);
    GSetColor(COLOR_LIST_SELECTED_TEXT);
   End Else Begin
    If Menus[MenuIndex].Items[I].Enabled Then
     GSetColor(COLOR_MENU_TEXT)
    Else
     GSetColor(COLOR_BUTTON_DARK);
   End;

   { Texte de l'element }
   GOutTextXY(ItemX1 + 4, ItemY1 + 3, Menus[MenuIndex].Items[I].Caption);

   { Raccourci clavier }
   If Menus[MenuIndex].Items[I].Shortcut <> '' Then Begin
    If I = ActiveMenuItem Then
     GSetColor(COLOR_LIST_SELECTED_TEXT)
    Else
     GSetColor(COLOR_BUTTON_DARK);
    GOutTextXY(ItemX2 - GTextWidth(Menus[MenuIndex].Items[I].Shortcut) - 4,
              ItemY1 + 3, Menus[MenuIndex].Items[I].Shortcut);
   End;
  End;

  ItemY := ItemY + 18;
 End;

 ShowMouse;
End;

{ Ferme le menu deroulant actif et redessine l'interface }
Procedure CloseDropdownMenu;
Begin
 If ActiveMenu >= 0 Then Begin
  ActiveMenu := -1;
  ActiveMenuItem := -1;
  MenuBarActive := False;
  DrawInterface;
 End;
End;

{ Verifie si un point est dans la zone d'un menu de la barre }
Function GetMenuAtPoint(X, Y: Integer): Integer;
Var
 I: Integer;
Begin
 GetMenuAtPoint := -1;
 If RibbonMode Then Begin GetMenuAtPoint:=RibbonTabAt(X,Y); Exit; End;
 If (Y >= Layout.MenuBarRect.Y1) And (Y <= Layout.MenuBarRect.Y2) Then Begin
  For I := 0 To MenuCount - 1 Do Begin
   If (X >= Menus[I].X) And (X < Menus[I].X + Menus[I].Width) Then Begin
    GetMenuAtPoint := I;
    Exit;
   End;
  End;
 End;
End;

{ Verifie si un point est dans le menu deroulant actif }
Function GetMenuItemAtPoint(X, Y: Integer): Integer;
Var
 I: Integer;
 ItemY: Integer;
Begin
 GetMenuItemAtPoint := -1;
 If ActiveMenu < 0 Then Exit;

 { Verifier si le point est dans le menu deroulant }
 If (X >= Menus[ActiveMenu].DropX) And
    (X <= Menus[ActiveMenu].DropX + Menus[ActiveMenu].DropWidth) And
    (Y >= Menus[ActiveMenu].DropY) And
    (Y <= Menus[ActiveMenu].DropY + Menus[ActiveMenu].DropHeight) Then Begin

  ItemY := Menus[ActiveMenu].DropY + 2;
  For I := 0 To Menus[ActiveMenu].ItemCount - 1 Do Begin
   If (Y >= ItemY) And (Y < ItemY + 18) Then Begin
    If Not Menus[ActiveMenu].Items[I].Separator Then
     GetMenuItemAtPoint := I;
    Exit;
   End;
   ItemY := ItemY + 18;
  End;
 End;
End;

{ Execute une commande de menu }
Procedure ExecuteMenuCommand(CmdID: Integer);
Begin
 CloseDropdownMenu;

 Case CmdID Of
  CMD_EVENT_NEW: EventNew(False);
  CMD_EVENT_MEETING: EventNew(True);
  CMD_EVENT_AGENDA: EventAgenda;
  CMD_VIEW_CALENDAR: CalendarShow(Not CalendarVisible);
  CMD_VIEW_MAIL: FocusMail;
  CMD_CAL_PREVIOUS: Begin CalendarMoveMonth(-1); DrawInterface; End;
  CMD_CAL_NEXT: Begin CalendarMoveMonth(1); DrawInterface; End;
  CMD_CAL_TODAY: Begin CalendarToday; DrawInterface; End;
  CMD_TOOLS_RULES: Rules_Show;
  CMD_VIEW_COLUMNS: ShowColumnsDialog;
  CMD_VIEW_SORTBY: ShowSortDialog;
  CMD_FILE_OPEN: OpenMessageFile;
  CMD_FILE_SAVE, CMD_FILE_SAVEAS: SaveMessageAs;

  CMD_FILE_NEW, CMD_MSG_NEW: Begin
   { Ouvrir le compositeur pour un nouveau message (TODO 12) }
   OpenNewMessage;
  End;

  CMD_MSG_REPLY: Begin
   { Ouvrir le compositeur pour une reponse (TODO 12) }
   OpenReplyMessage(False);
  End;

  CMD_MSG_REPLYALL: Begin
   { Ouvrir le compositeur pour une reponse a tous (TODO 12) }
   OpenReplyMessage(True);
  End;

  CMD_MSG_FORWARD: Begin
   { Ouvrir le compositeur pour un transfert (TODO 12) }
   OpenForwardMessage;
  End;

  CMD_FILE_EXIT: Begin
   Running := False;
  End;

  CMD_EDIT_COPY: Begin
   HideMouse;
   FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
            Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
   GSetColor(COLOR_STATUS_TEXT);
   GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
             'Commande: Copier                   ');
   ShowMouse;
  End;

  CMD_EDIT_PASTE: Begin
   HideMouse;
   FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
            Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
   GSetColor(COLOR_STATUS_TEXT);
   GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
             'Commande: Coller                   ');
   ShowMouse;
  End;

  CMD_VIEW_REFRESH: Begin
   ReceiveMail; DrawInterface;
  End;
  CMD_TB_SENDRECV: Begin
   ReceiveMail;
   DrawInterface;
  End;

  CMD_VIEW_PREVIEW_SHOW: Begin
   { Basculer affichage/masquage du volet de previsualisation }
   PreviewVisible := Not PreviewVisible;
   HideMouse;
   If PreviewVisible Then Begin
    { Restaurer la hauteur du volet }
    Layout.PreviewPaneHeight := 150;
    CalculateLayout;
    DrawInterface;
    FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
             Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
    GSetColor(COLOR_STATUS_TEXT);
    GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
              'Volet de lecture: Affiche          ');
   End
   Else Begin
    { Masquer le volet - donner tout l'espace a la liste }
    Layout.PreviewPaneHeight := 0;
    CalculateLayout;
    DrawInterface;
    FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
             Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
    GSetColor(COLOR_STATUS_TEXT);
    GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
              'Volet de lecture: Masque           ');
   End;
   ShowMouse;
  End;

  CMD_VIEW_PREVIEW_ORIENT: Begin
   { Basculer orientation du volet de previsualisation }
   If PreviewOrientation = poHorizontal Then
    PreviewOrientation := poVertical
   Else
    PreviewOrientation := poHorizontal;
   HideMouse;
   CalculateLayout;
   DrawInterface;
   FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
            Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
   GSetColor(COLOR_STATUS_TEXT);
   If PreviewOrientation = poHorizontal Then
    GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
              'Orientation: Horizontale           ')
   Else
    GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
              'Orientation: Verticale             ');
   ShowMouse;
  End;

  CMD_TOOLS_ACCOUNTS: Begin
   { Ouvrir la boite de dialogue de gestion des comptes (TODO 11) }
   ShowAccountManagerDialog;
  End;

  CMD_TOOLS_OPTIONS: Prefs_Show;

  CMD_HELP_ABOUT: ShowAboutDialog;

  Else Begin
   { Commande non implementee }
   HideMouse;
   FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
            Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
   GSetColor(COLOR_STATUS_TEXT);
   GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
             'Commande non implementee           ');
   ShowMouse;
  End;
 End;
End;

{ ============================================================================
  PROCEDURES DE CALCUL DE LA DISPOSITION
  ============================================================================ }

{ Calcule les rectangles de toutes les zones de l'interface }
Procedure CalculateLayout;
Var
 ClientTop, ClientBottom,MenuHeight,ToolbarHeight: Integer;
 RightPaneLeft, RightPaneRight: Integer;
 MessageListBottom: Integer;
Begin
 MenuHeight:=MENUBAR_HEIGHT; ToolbarHeight:=TOOLBAR_HEIGHT;
 If RibbonMode Then Begin MenuHeight:=24; ToolbarHeight:=92; End;
 { Barre de titre }
 Layout.TitleBarRect.X1 := 0;
 Layout.TitleBarRect.Y1 := 0;
 Layout.TitleBarRect.X2 := SCREEN_WIDTH - 1;
 Layout.TitleBarRect.Y2 := TITLEBAR_HEIGHT - 1;

 { Barre de menu }
 Layout.MenuBarRect.X1 := 0;
 Layout.MenuBarRect.Y1 := TITLEBAR_HEIGHT;
 Layout.MenuBarRect.X2 := SCREEN_WIDTH - 1;
 Layout.MenuBarRect.Y2 := TITLEBAR_HEIGHT + MenuHeight - 1;

 { Barre d'outils }
 Layout.ToolBarRect.X1 := 0;
 Layout.ToolBarRect.Y1 := TITLEBAR_HEIGHT + MenuHeight;
 Layout.ToolBarRect.X2 := SCREEN_WIDTH - 1;
 Layout.ToolBarRect.Y2 := TITLEBAR_HEIGHT + MenuHeight + ToolbarHeight - 1;

 { Barre d'etat }
 Layout.StatusBarRect.X1 := 0;
 Layout.StatusBarRect.Y1 := SCREEN_HEIGHT - STATUSBAR_HEIGHT;
 Layout.StatusBarRect.X2 := SCREEN_WIDTH - 1;
 Layout.StatusBarRect.Y2 := SCREEN_HEIGHT - 1;

 { Zone cliente (entre toolbar et statusbar) }
 ClientTop := Layout.ToolBarRect.Y2+1;
 ClientBottom := SCREEN_HEIGHT - STATUSBAR_HEIGHT - 1;

 { Panneau des dossiers (gauche) }
 Layout.FolderPaneRect.X1 := 0;
 Layout.FolderPaneRect.Y1 := ClientTop;
 Layout.FolderPaneRect.X2 := Layout.FolderPaneWidth - 1;
 Layout.FolderPaneRect.Y2 := ClientBottom;

 { Separateur vertical }
 Layout.VSplitterRect.X1 := Layout.FolderPaneWidth;
 Layout.VSplitterRect.Y1 := ClientTop;
 Layout.VSplitterRect.X2 := Layout.FolderPaneWidth + SPLITTER_SIZE - 1;
 Layout.VSplitterRect.Y2 := ClientBottom;

 { Zone de droite }
 RightPaneLeft := Layout.FolderPaneWidth + SPLITTER_SIZE;
 RightPaneRight := SCREEN_WIDTH - 1;
 If CalendarVisible Then Dec(RightPaneRight,CalendarPaneWidth+SPLITTER_SIZE);

 { Calcul de la hauteur du volet de previsualisation }
 MessageListBottom := ClientBottom - Layout.PreviewPaneHeight - SPLITTER_SIZE;

 { Liste des messages }
 Layout.MessageListRect.X1 := RightPaneLeft;
 Layout.MessageListRect.Y1 := ClientTop;
 Layout.MessageListRect.X2 := RightPaneRight;
 Layout.MessageListRect.Y2 := MessageListBottom;

 { Separateur horizontal }
 Layout.HSplitterRect.X1 := RightPaneLeft;
 Layout.HSplitterRect.Y1 := MessageListBottom + 1;
 Layout.HSplitterRect.X2 := RightPaneRight;
 Layout.HSplitterRect.Y2 := MessageListBottom + SPLITTER_SIZE;

 { Volet de previsualisation }
 Layout.PreviewPaneRect.X1 := RightPaneLeft;
 Layout.PreviewPaneRect.Y1 := MessageListBottom + SPLITTER_SIZE + 1;
 Layout.PreviewPaneRect.X2 := RightPaneRight;
 Layout.PreviewPaneRect.Y2 := ClientBottom;
 If Not PreviewVisible Then Begin
  Layout.MessageListRect.Y2:=ClientBottom;
  Layout.HSplitterRect.X1:=-1; Layout.HSplitterRect.X2:=-1;
  Layout.HSplitterRect.Y1:=-1; Layout.HSplitterRect.Y2:=-1;
 End Else If PreviewOrientation=poVertical Then Begin
  If PreviewPaneWidth<120 Then PreviewPaneWidth:=(RightPaneRight-RightPaneLeft) Div 2;
  If RightPaneRight-RightPaneLeft<240 Then PreviewPaneWidth:=(RightPaneRight-RightPaneLeft) Div 2
  Else If PreviewPaneWidth>RightPaneRight-RightPaneLeft-120 Then
   PreviewPaneWidth:=RightPaneRight-RightPaneLeft-120;
  Layout.MessageListRect.Y2:=ClientBottom;
  Layout.MessageListRect.X2:=RightPaneRight-PreviewPaneWidth-SPLITTER_SIZE;
  Layout.HSplitterRect.X1:=Layout.MessageListRect.X2+1;
  Layout.HSplitterRect.X2:=Layout.MessageListRect.X2+SPLITTER_SIZE;
  Layout.HSplitterRect.Y1:=ClientTop; Layout.HSplitterRect.Y2:=ClientBottom;
  Layout.PreviewPaneRect.X1:=Layout.HSplitterRect.X2+1;
  Layout.PreviewPaneRect.Y1:=ClientTop;
 End;
End;

{ ============================================================================
  PROCEDURES DE DESSIN DES ZONES DE L'INTERFACE
  ============================================================================ }

{ Dessine la barre de titre }
Procedure DrawTitleBar;
Begin
 OsSetTitle('Outlink');
End;

{ Ruban graphique : les commandes et leurs etats proviennent des menus existants. }
Function RibbonTitle(Index: Integer): String;
Begin
 RibbonTitle:=''; If (Index<0) Or (Index>=MenuCount) Then Exit;
 RibbonTitle:=Menus[Index].Title; If Index=5 Then RibbonTitle:='Aide';
End;

Function RibbonTabAt(X,Y: Integer): Integer;
Var I,Left,Width: Integer;
Begin
 RibbonTabAt:=-1;
 If (Y<Layout.MenuBarRect.Y1) Or (Y>Layout.MenuBarRect.Y2) Then Exit;
 Left:=8;
 For I:=0 To MenuCount-1 Do Begin
  Width:=GTextWidth(RibbonTitle(I))+24;
  If (X>=Left) And (X<Left+Width) Then Begin RibbonTabAt:=I; Exit; End;
  Inc(Left,Width+2);
 End;
End;

Procedure RibbonBuild;
Var Counts,Used: Array[0..7] Of Integer;
 I,G,Cols,TotalCols,ColW,Left,Slot: Integer;
Begin
 RibbonCount:=0; RibbonGroupCount:=0;
 If MenuCount=0 Then Exit;
 If (RibbonTab<0) Or (RibbonTab>=MenuCount) Then RibbonTab:=0;
 FillChar(Counts,SizeOf(Counts),0); FillChar(Used,SizeOf(Used),0); G:=0;
 For I:=0 To Menus[RibbonTab].ItemCount-1 Do
  If Menus[RibbonTab].Items[I].Separator Then Begin If G<7 Then Inc(G); End
  Else Inc(Counts[G]);
 RibbonGroupCount:=G+1; TotalCols:=0;
 For G:=0 To RibbonGroupCount-1 Do Inc(TotalCols,(Counts[G]+1) Div 2);
 If TotalCols=0 Then Exit;
 ColW:=(SCREEN_WIDTH-16-RibbonGroupCount*6) Div TotalCols;
 If ColW>160 Then ColW:=160;
 Left:=8;
 For G:=0 To RibbonGroupCount-1 Do Begin
  Cols:=(Counts[G]+1) Div 2; RibbonGroupX[G]:=Left;
  RibbonGroupW[G]:=Cols*ColW; Inc(Left,Cols*ColW+6);
 End;
 G:=0;
 For I:=0 To Menus[RibbonTab].ItemCount-1 Do
  If Menus[RibbonTab].Items[I].Separator Then Begin If G<7 Then Inc(G); End
  Else If RibbonCount<15 Then Begin
   Slot:=Used[G]; Inc(Used[G]);
   With RibbonButtons[RibbonCount] Do Begin
    X:=RibbonGroupX[G]+(Slot Div 2)*ColW; Y:=Layout.ToolBarRect.Y1+5+(Slot Mod 2)*33;
    W:=ColW-4; H:=30; MenuItem:=I; Group:=G;
   End;
   Inc(RibbonCount);
  End;
End;

Function RibbonButtonAt(MX,MY: Integer): Integer;
Var I: Integer;
Begin
 RibbonBuild; RibbonButtonAt:=-1;
 For I:=0 To RibbonCount-1 Do With RibbonButtons[I] Do
  If (MX>=RibbonButtons[I].X) And (MX<RibbonButtons[I].X+W) And
     (MY>=RibbonButtons[I].Y) And (MY<RibbonButtons[I].Y+H) Then Begin
   RibbonButtonAt:=I; Exit;
  End;
End;

Function RibbonGroupTitle(Group: Integer): String;
Begin
 RibbonGroupTitle:=RibbonTitle(RibbonTab);
 Case RibbonTab Of
  0: Case Group Of
   0: RibbonGroupTitle:='Nouveau / Ouvrir'; 1: RibbonGroupTitle:='Enregistrer';
   2: RibbonGroupTitle:='Imprimer'; 3: RibbonGroupTitle:='Fermer'; End;
  1: Case Group Of
   0: RibbonGroupTitle:='Annuler'; 1: RibbonGroupTitle:='Presse-papiers'; 2: RibbonGroupTitle:='Selection'; End;
  2: Case Group Of
   0: RibbonGroupTitle:='Lecture'; 1: RibbonGroupTitle:='Liste';
   2: RibbonGroupTitle:='Actualiser'; 3: RibbonGroupTitle:='Calendrier'; End;
  3: Case Group Of
   0: RibbonGroupTitle:='Comptes'; 1: RibbonGroupTitle:='Regles'; 2: RibbonGroupTitle:='Options'; End;
  4: Case Group Of
   0: RibbonGroupTitle:='Nouveau'; 1: RibbonGroupTitle:='Repondre';
   2: RibbonGroupTitle:='Actions'; 3: RibbonGroupTitle:='Communiquer'; End;
 End;
End;

Function RibbonFit(Text: String; Width: Integer): String;
Begin
 If GTextWidth(Text)>Width Then Begin
  While (Length(Text)>0) And (GTextWidth(Text+'...')>Width) Do Delete(Text,Length(Text),1);
  Text:=Text+'...';
 End;
 RibbonFit:=Text;
End;

Procedure DrawRibbonTabs;
Var I,Left,Width: Integer; Title: String;
Begin
 FillRect(0,Layout.MenuBarRect.Y1,SCREEN_WIDTH-1,Layout.MenuBarRect.Y2,LightGray); Left:=8;
 For I:=0 To MenuCount-1 Do Begin
  Title:=RibbonTitle(I); Width:=GTextWidth(Title)+24;
  If I=RibbonTab Then Begin
   FillRect(Left,Layout.MenuBarRect.Y1+1,Left+Width,Layout.MenuBarRect.Y2,White);
   Draw3DRect(Left,Layout.MenuBarRect.Y1+1,Left+Width,Layout.MenuBarRect.Y2,True); GSetColor(Blue);
  End Else GSetColor(Black);
  GOutTextXY(Left+12,Layout.MenuBarRect.Y1+7,Title);
  If RibbonKeyboardActive And (RibbonFocus<0) And (I=RibbonTab) Then
   GLine(Left+10,Layout.MenuBarRect.Y2-3,Left+Width-10,Layout.MenuBarRect.Y2-3);
  Inc(Left,Width+2);
 End;
End;

Procedure DrawRibbon;
Var I,J,P,Width,Command: Integer; Caption,First,Second: String; Icon: TToolIconType; Enabled,Selected: Boolean;
Begin
 RibbonBuild;
 FillRect(0,Layout.ToolBarRect.Y1,SCREEN_WIDTH-1,Layout.ToolBarRect.Y2,White);
 GSetColor(DarkGray); GLine(0,Layout.ToolBarRect.Y2,SCREEN_WIDTH-1,Layout.ToolBarRect.Y2);
 For I:=0 To RibbonGroupCount-1 Do Begin
  J:=RibbonGroupX[I]+RibbonGroupW[I]+1;
  GSetColor(LightGray); GLine(J,Layout.ToolBarRect.Y1+5,J,Layout.ToolBarRect.Y2-6);
  GSetColor(DarkGray);
  Caption:=RibbonFit(RibbonGroupTitle(I),RibbonGroupW[I]-4);
  GOutTextXY(RibbonGroupX[I]+2,Layout.ToolBarRect.Y2-13,Caption);
 End;
 For I:=0 To RibbonCount-1 Do With RibbonButtons[I] Do Begin
  Enabled:=Menus[RibbonTab].Items[MenuItem].Enabled;
  Selected:=Enabled And ((RibbonHover=I) Or (RibbonPressed=I) Or (RibbonKeyboardActive And (RibbonFocus=I)));
  If Selected Then Begin
   FillRect(X,Y,X+W-1,Y+H-1,LightCyan); Draw3DRect(X,Y,X+W-1,Y+H-1,RibbonPressed<>I);
  End;
  Command:=Menus[RibbonTab].Items[MenuItem].ItemID; Icon:=tiAddressBook;
  Case Command Of
   CMD_FILE_NEW,CMD_MSG_NEW,CMD_EVENT_NEW,CMD_EVENT_MEETING: Icon:=tiNewMsg;
   CMD_MSG_REPLY: Icon:=tiReply; CMD_MSG_REPLYALL: Icon:=tiReplyAll;
   CMD_MSG_FORWARD: Icon:=tiForward; CMD_MSG_DELETE: Icon:=tiDelete;
   CMD_TB_SENDRECV,CMD_VIEW_REFRESH: Icon:=tiSendRecv; CMD_FILE_PRINT: Icon:=tiPrint;
  End;
  DrawToolbarIcon(X+4,Y+7,Icon,Not Enabled);
  Caption:=Menus[RibbonTab].Items[MenuItem].Caption; Width:=W-28;
  First:=Caption; Second:='';
  If GTextWidth(First)>Width Then Begin
   P:=Length(First);
   While (P>1) And ((First[P]<>' ') Or (GTextWidth(Copy(First,1,P-1))>Width)) Do Dec(P);
   If P>1 Then Begin Second:=Copy(First,P+1,255); First:=Copy(First,1,P-1); End;
  End;
  If Enabled Then GSetColor(Black) Else GSetColor(DarkGray);
  If Second='' Then GOutTextXY(X+25,Y+11,RibbonFit(First,Width)) Else Begin
   GOutTextXY(X+25,Y+5,RibbonFit(First,Width)); GOutTextXY(X+25,Y+17,RibbonFit(Second,Width));
  End;
 End;
End;

Procedure RibbonSelectTab(Index: Integer; Keyboard: Boolean);
Var I: Integer;
Begin
 If (Index<0) Or (Index>=MenuCount) Then Exit;
 RibbonTab:=Index; RibbonKeyboardActive:=Keyboard; RibbonFocus:=-1; RibbonPressed:=-1; RibbonHover:=-1;
 ActiveMenu:=-1; ActiveMenuItem:=-1; MenuBarActive:=False; TooltipVisible:=False;
 RibbonBuild;
 If Keyboard Then For I:=0 To RibbonCount-1 Do
  If Menus[RibbonTab].Items[RibbonButtons[I].MenuItem].Enabled Then Begin RibbonFocus:=I; Break; End;
 DrawInterface;
End;

Procedure RibbonAdvance(Delta: Integer; TabCycle: Boolean);
Var Index,Step,Count: Integer;
Begin
 RibbonBuild; If RibbonCount=0 Then Exit;
 Step:=1; If Delta<0 Then Step:=-1;
 If RibbonFocus<0 Then Begin
  If Delta<0 Then Index:=RibbonCount-1 Else Index:=0;
 End Else Index:=RibbonFocus+Delta;
 For Count:=0 To RibbonCount Do Begin
  If (Index<0) Or (Index>=RibbonCount) Then Begin
   If TabCycle Then Begin RibbonFocus:=-1; Exit; End;
   If Index<0 Then Index:=RibbonCount-1 Else Index:=0;
  End;
  If Menus[RibbonTab].Items[RibbonButtons[Index].MenuItem].Enabled Then Begin RibbonFocus:=Index; Exit; End;
  Inc(Index,Step);
 End;
 RibbonFocus:=-1;
End;

Procedure RibbonKey(Key: Char; Extended: Boolean);
Var Index: Integer;
Begin
 If Extended Then Case Key Of
  #15: RibbonAdvance(-1,True);
  #75,#77: If RibbonFocus<0 Then Begin
   Index:=-1; If Key=#77 Then Index:=1;
   RibbonSelectTab((RibbonTab+Index+MenuCount) Mod MenuCount,False);
   RibbonKeyboardActive:=True; RibbonFocus:=-1;
  End Else If Key=#75 Then RibbonAdvance(-2,False) Else RibbonAdvance(2,False);
  #72: RibbonAdvance(-1,False); #80: RibbonAdvance(1,False);
  #71: Begin RibbonFocus:=-1; RibbonAdvance(1,False); End;
  #79: Begin RibbonFocus:=-1; RibbonAdvance(-1,False); End;
 End Else Case Key Of
  #27: If RibbonFocus>=0 Then RibbonFocus:=-1 Else RibbonKeyboardActive:=False;
  #9: RibbonAdvance(1,True);
  #13,' ': If (RibbonFocus>=0) And (RibbonFocus<RibbonCount) Then Begin
   Index:=RibbonButtons[RibbonFocus].MenuItem;
   If Menus[RibbonTab].Items[Index].Enabled Then Begin
    RibbonKeyboardActive:=False; RibbonFocus:=-1;
    ExecuteMenuCommand(Menus[RibbonTab].Items[Index].ItemID);
   End;
  End;
 End;
 DrawInterface;
End;

{ Dessine la barre de menu }
Procedure DrawMenuBar;
Var
 I: Integer;
Begin
 If RibbonMode Then Begin DrawRibbonTabs; Exit; End;
 OsSyncMenu; Exit;
 FillRect(Layout.MenuBarRect.X1, Layout.MenuBarRect.Y1,
          Layout.MenuBarRect.X2, Layout.MenuBarRect.Y2, COLOR_MENU_BG);
 Draw3DRect(Layout.MenuBarRect.X1, Layout.MenuBarRect.Y1,
            Layout.MenuBarRect.X2, Layout.MenuBarRect.Y2, True);

 For I := 0 To MenuCount - 1 Do Begin
  If I = ActiveMenu Then Begin
   FillRect(Menus[I].X, Layout.MenuBarRect.Y1 + 1,
            Menus[I].X + Menus[I].Width - 1, Layout.MenuBarRect.Y2 - 1,
            COLOR_MENU_HIGHLIGHT);
   GSetColor(COLOR_MENU_HIGHLIGHT_TEXT);
  End Else
   GSetColor(COLOR_MENU_TEXT);
  GOutTextXY(Menus[I].X + 8, Layout.MenuBarRect.Y1 + 4, Menus[I].Title);
 End;
End;

{ Dessine la barre d'outils avec icones et etats }
Procedure DrawToolBar;
Var
 I: Integer;
 IconX, IconY: Integer;
 TextX: Integer;
 TxtColorV: Word;
Begin
 If RibbonMode Then Begin DrawRibbon; Exit; End;
 { Dessiner le fond de la barre d'outils }
 FillRect(Layout.ToolBarRect.X1, Layout.ToolBarRect.Y1,
          Layout.ToolBarRect.X2, Layout.ToolBarRect.Y2, COLOR_TOOLBAR_BG);
 Draw3DRect(Layout.ToolBarRect.X1, Layout.ToolBarRect.Y1,
            Layout.ToolBarRect.X2, Layout.ToolBarRect.Y2, True);

 { Dessiner chaque bouton }
 For I := 0 To ToolButtonCount - 1 Do Begin
  If ToolButtons[I].IconType = tiSeparator Then Begin
   { Dessiner le separateur }
   DrawToolbarIcon(ToolButtons[I].X, ToolButtons[I].Y, tiSeparator, False);
  End Else Begin
   { Dessiner le bouton avec son etat }
   DrawToolButtonEx(ToolButtons[I]);

   { Position de l'icone (a gauche du texte) }
   IconX := ToolButtons[I].X + 3;
   IconY := ToolButtons[I].Y + 4;

   { Dessiner l'icone }
   DrawToolbarIcon(IconX, IconY, ToolButtons[I].IconType,
                   Not ToolButtons[I].Enabled);

   { Couleur du texte selon l'etat }
   If ToolButtons[I].Enabled Then Begin
    If ToolButtons[I].State = tbsHover Then
     TxtColorV := COLOR_LIST_SELECTED_TEXT
    Else
     TxtColorV := COLOR_MENU_TEXT;
   End Else
    TxtColorV := COLOR_BUTTON_DARK;

   { Dessiner le texte du bouton }
   TextX := IconX + 16;
   GSetColor(TxtColorV);
   GOutTextXY(TextX, ToolButtons[I].Y + 6, ToolButtons[I].Caption);
  End;
 End;
End;

{ ============================================================================
  PROCEDURES POUR L'ARBRE DE NAVIGATION (PANNEAU DOSSIERS)
  ============================================================================ }

{ Dessine une icone de dossier selon son type }
Procedure DrawFolderIcon(X, Y: Integer; FolderType: TFolderType; Expanded: Boolean);
Begin
 Case FolderType Of
  ftAccount: Begin
   { Icone de compte (ordinateur) }
   GSetColor(COLOR_BUTTON_DARK);
   GRectangle(X, Y + 2, X + 12, Y + 10);
   GRectangle(X + 2, Y + 10, X + 10, Y + 12);
   GSetColor(LightCyan);
   GBar(X + 1, Y + 3, X + 11, Y + 9);
  End;

  ftInbox: Begin
   { Icone boite de reception (dossier avec fleche entrante) }
   GSetColor(Yellow);
   GBar(X, Y + 4, X + 12, Y + 12);
   GSetColor(COLOR_BUTTON_DARK);
   GRectangle(X, Y + 4, X + 12, Y + 12);
   GLine(X, Y + 4, X + 6, Y);
   GLine(X + 6, Y, X + 12, Y + 4);
   { Fleche entrante }
   GSetColor(LightGreen);
   GLine(X + 6, Y + 6, X + 6, Y + 10);
   GLine(X + 4, Y + 8, X + 6, Y + 10);
   GLine(X + 8, Y + 8, X + 6, Y + 10);
  End;

  ftSent: Begin
   { Icone elements envoyes (dossier avec fleche sortante) }
   GSetColor(LightCyan);
   GBar(X, Y + 4, X + 12, Y + 12);
   GSetColor(COLOR_BUTTON_DARK);
   GRectangle(X, Y + 4, X + 12, Y + 12);
   GLine(X, Y + 4, X + 6, Y);
   GLine(X + 6, Y, X + 12, Y + 4);
   { Fleche sortante }
   GSetColor(LightBlue);
   GLine(X + 6, Y + 10, X + 6, Y + 6);
   GLine(X + 4, Y + 8, X + 6, Y + 6);
   GLine(X + 8, Y + 8, X + 6, Y + 6);
  End;

  ftDrafts: Begin
   { Icone brouillons (document avec crayon) }
   GSetColor(White);
   GBar(X + 2, Y, X + 12, Y + 12);
   GSetColor(COLOR_BUTTON_DARK);
   GRectangle(X + 2, Y, X + 12, Y + 12);
   { Lignes de texte }
   GLine(X + 4, Y + 3, X + 10, Y + 3);
   GLine(X + 4, Y + 6, X + 10, Y + 6);
   GLine(X + 4, Y + 9, X + 8, Y + 9);
  End;

  ftDeleted: Begin
   { Icone corbeille }
   GSetColor(COLOR_BUTTON_DARK);
   GRectangle(X + 2, Y + 2, X + 10, Y + 12);
   GLine(X, Y + 2, X + 12, Y + 2);
   GLine(X + 4, Y, X + 8, Y);
   { Lignes verticales de la corbeille }
   GLine(X + 4, Y + 4, X + 4, Y + 10);
   GLine(X + 6, Y + 4, X + 6, Y + 10);
   GLine(X + 8, Y + 4, X + 8, Y + 10);
  End;

  ftJunk: Begin
   { Icone courrier indesirable (dossier rouge) }
   GSetColor(LightRed);
   GBar(X, Y + 4, X + 12, Y + 12);
   GSetColor(COLOR_BUTTON_DARK);
   GRectangle(X, Y + 4, X + 12, Y + 12);
   GLine(X, Y + 4, X + 6, Y);
   GLine(X + 6, Y, X + 12, Y + 4);
   { X pour spam }
   GSetColor(White);
   GLine(X + 3, Y + 6, X + 9, Y + 10);
   GLine(X + 9, Y + 6, X + 3, Y + 10);
  End;

  ftCustom: Begin
   { Icone dossier standard }
   GSetColor(Yellow);
   GBar(X, Y + 4, X + 12, Y + 12);
   GSetColor(COLOR_BUTTON_DARK);
   GRectangle(X, Y + 4, X + 12, Y + 12);
   GLine(X, Y + 4, X + 6, Y);
   GLine(X + 6, Y, X + 12, Y + 4);
  End;
 End;
End;

{ Dessine le symbole d'expansion/reduction }
Procedure DrawExpandSymbol(X, Y: Integer; Expanded: Boolean);
Begin
 GSetColor(COLOR_BUTTON_DARK);
 GRectangle(X, Y, X + 8, Y + 8);
 GSetColor(White);
 GBar(X + 1, Y + 1, X + 7, Y + 7);
 GSetColor(Black);
 { Ligne horizontale (toujours) }
 GLine(X + 2, Y + 4, X + 6, Y + 4);
 { Ligne verticale (si replie) }
 If Not Expanded Then
  GLine(X + 4, Y + 2, X + 4, Y + 6);
End;

{ Verifie si un dossier a des enfants visibles }
Function HasChildren(FolderIndex: Integer): Boolean;
Var
 I: Integer;
Begin
 HasChildren := False;
 For I := 0 To FolderCount - 1 Do Begin
  If Folders[I].ParentIndex = FolderIndex Then Begin
   HasChildren := True;
   Exit;
  End;
 End;
End;

{ Met a jour la visibilite de tous les dossiers selon l'etat d'expansion des parents }
Procedure UpdateFolderVisibility;
Var
 I, P: Integer;
 IsVisible: Boolean;
Begin
 For I := 0 To FolderCount - 1 Do Begin
  If Folders[I].Level = 0 Then
   Folders[I].Visible := True
  Else Begin
   { Verifier si tous les parents sont etendus }
   IsVisible := True;
   P := Folders[I].ParentIndex;
   While (P >= 0) And IsVisible Do Begin
    If Not Folders[P].Expanded Then
     IsVisible := False;
    P := Folders[P].ParentIndex;
   End;
   Folders[I].Visible := IsVisible;
  End;
 End;
End;

{ Ajoute un dossier a l'arbre }
Procedure AddFolder(Name: String; FolderType: TFolderType; Level, ParentIndex: Integer;
                    Expanded: Boolean; UnreadCount, TotalCount: Integer);
Begin
 If FolderCount < MAX_FOLDERS Then Begin
  Folders[FolderCount].Name := Name;
  Folders[FolderCount].FolderType := FolderType;
  Folders[FolderCount].Level := Level;
  Folders[FolderCount].ParentIndex := ParentIndex;
  Folders[FolderCount].Expanded := Expanded;
  Folders[FolderCount].Selected := False;
  Folders[FolderCount].UnreadCount := UnreadCount;
  Folders[FolderCount].TotalCount := TotalCount;
  Folders[FolderCount].Y := 0;
  Folders[FolderCount].Visible := True;
  Inc(FolderCount);
 End;
End;

{ Initialise l'arbre de dossiers avec une structure multi-comptes }
Procedure InitializeFolderTree;
Var I, Root: Integer;
Begin
 FillChar(Folders,SizeOf(Folders),0);
 FolderCount:=0; SelectedFolder:=-1; HoveredFolder:=-1;
 FolderScrollOffset:=0; DraggedFolder:=-1;
 For I:=0 To MAX_FOLDERS-1 Do MailFolderAccount[I]:=-1;
 For I:=0 To EmailAccountCount-1 Do Begin
  Root:=FolderCount;
  AddFolder(EmailAccounts[I].AccountName,ftAccount,0,-1,True,0,0);
  MailFolderAccount[Root]:=I;
  AddFolder('Boite de reception',ftInbox,1,Root,False,0,0);
  MailFolderAccount[Root+1]:=I;
  If (SelectedFolder<0) Or EmailAccounts[I].IsDefault Then SelectedFolder:=Root+1;
 End;
 If SelectedFolder>=0 Then Folders[SelectedFolder].Selected:=True;
 UpdateFolderVisibility;
End;

Procedure RefreshAccountFolders;
Begin
 InitializeFolderTree;
 MessageCount:=0; SelectedMessage:=-1; MailLoadedFolder:=-1;
 MailStatus:='Comptes modifies - cliquez sur Envoyer/Recevoir';
End;

{ Trouve le dossier a une position Y donnee }
Function GetFolderAtPoint(X, Y: Integer): Integer;
Var
 I: Integer;
Begin
 GetFolderAtPoint := -1;

 { Verifier si on est dans le panneau des dossiers }
 If (X < Layout.FolderPaneRect.X1) Or (X > Layout.FolderPaneRect.X2) Or
    (Y < Layout.FolderPaneRect.Y1 + 28) Or (Y > Layout.FolderPaneRect.Y2) Then
  Exit;

 For I := 0 To FolderCount - 1 Do Begin
  If Folders[I].Visible And (Folders[I].Y > 0) Then Begin
   If (Y >= Folders[I].Y) And (Y < Folders[I].Y + FOLDER_NODE_HEIGHT) Then Begin
    GetFolderAtPoint := I;
    Exit;
   End;
  End;
 End;
End;

{ Verifie si le clic est sur le symbole d'expansion }
Function IsClickOnExpandSymbol(X, FolderIndex: Integer): Boolean;
Var
 SymbolX: Integer;
Begin
 IsClickOnExpandSymbol := False;
 If (FolderIndex < 0) Or (FolderIndex >= FolderCount) Then Exit;
 If Not HasChildren(FolderIndex) Then Exit;

 SymbolX := Layout.FolderPaneRect.X1 + 4 + (Folders[FolderIndex].Level * FOLDER_INDENT);
 IsClickOnExpandSymbol := (X >= SymbolX) And (X <= SymbolX + 10);
End;

{ Gere le clic sur un dossier }
Procedure HandleFolderClick(X, Y: Integer);
Var
 FolderIdx: Integer;
Begin
 FolderIdx := GetFolderAtPoint(X, Y);

 If FolderIdx >= 0 Then Begin
  { Verifier si on clique sur le symbole d'expansion }
  If IsClickOnExpandSymbol(X, FolderIdx) Then Begin
   Folders[FolderIdx].Expanded := Not Folders[FolderIdx].Expanded;
   UpdateFolderVisibility;
  End
  Else Begin
   { Selectionner le dossier }
   If SelectedFolder >= 0 Then
    Folders[SelectedFolder].Selected := False;
   SelectedFolder := FolderIdx;
   Folders[FolderIdx].Selected := True;
   If MailLoadedFolder<>FolderIdx Then Begin
    MessageCount:=0; SelectedMessage:=-1; PreviewScrollY:=0; MailLoadedFolder:=-1;
    MailStatus:='Cliquez sur Envoyer/Recevoir pour charger cette boite';
    DrawInterface;
   End;
  End;

  { Redessiner le panneau }
  HideMouse;
  DrawFolderPane;
  ShowMouse;
 End;
End;

{ Gere le survol de l'arbre de dossiers }
Procedure UpdateFolderHover;
Var
 NewHover: Integer;
Begin
 NewHover := GetFolderAtPoint(MouseX, MouseY);

 If NewHover <> HoveredFolder Then Begin
  HoveredFolder := NewHover;
  HideMouse;
  DrawFolderPane;
  ShowMouse;
 End;
End;

{ ============================================================================
  PROCEDURES POUR LA LISTE DES MESSAGES (TODO 6)
  ============================================================================ }

{ Initialise les colonnes de la liste des messages }
Procedure InitializeMessageColumns;
Begin
 ColumnCount := 7;

 { Colonne Priorite (icone) }
 Columns[0].ColType := ctPriority;
 Columns[0].Title := '!';
 Columns[0].Width := 20;
 Columns[0].Sortable := True;
 Columns[0].Visible := True;

 { Colonne Piece jointe (icone) }
 Columns[1].ColType := ctAttachment;
 Columns[1].Title := '@';
 Columns[1].Width := 20;
 Columns[1].Sortable := True;
 Columns[1].Visible := True;

 { Colonne Drapeau (icone) }
 Columns[2].ColType := ctFlag;
 Columns[2].Title := '*';
 Columns[2].Width := 20;
 Columns[2].Sortable := True;
 Columns[2].Visible := True;

 { Colonne De }
 Columns[3].ColType := ctFrom;
 Columns[3].Title := 'De';
 Columns[3].Width := 120;
 Columns[3].Sortable := True;
 Columns[3].Visible := True;

 { Colonne Objet }
 Columns[4].ColType := ctSubject;
 Columns[4].Title := 'Objet';
 Columns[4].Width := 200;
 Columns[4].Sortable := True;
 Columns[4].Visible := True;

 { Colonne Date }
 Columns[5].ColType := ctDate;
 Columns[5].Title := 'Date';
 Columns[5].Width := 70;
 Columns[5].Sortable := True;
 Columns[5].Visible := True;

 { Colonne Taille }
 Columns[6].ColType := ctSize;
 Columns[6].Title := 'Taille';
 Columns[6].Width := 60;
 Columns[6].Sortable := True;
 Columns[6].Visible := True;
End;

{ Formate une taille en octets pour l'affichage }
Function FormatSize(Size: LongInt): String;
Var
 S: String;
Begin
 If Size < 1024 Then Begin
  Str(Size, S);
  FormatSize := S + ' o';
 End
 Else If Size < 1048576 Then Begin
  Str(Size Div 1024, S);
  FormatSize := S + ' Ko';
 End
 Else Begin
  Str(Size Div 1048576, S);
  FormatSize := S + ' Mo';
 End;
End;

{ ============================================================================
  IMPLEMENTATION DU CLIENT IMAP (RFC 3501)
  ============================================================================ }

{ Genere un nouveau tag IMAP unique }
Function IMAP_GenerateTag: String;
Var
 S: String;
Begin
 Inc(IMAPClient.TagCounter);
 Str(IMAPClient.TagCounter, S);
 While Length(S) < 4 Do S := '0' + S;
 IMAP_GenerateTag := 'A' + S;
End;

{ Encode une chaine en Base64 pour l'authentification PLAIN }
Function IMAP_EncodeBase64(Const S: String): String;
Const
 Base64Chars: String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
Var
 I, J, Len: Integer;
 B: Array[0..2] of Byte;
 Result: String;
Begin
 Result := '';
 Len := Length(S);
 I := 1;
 While I <= Len Do Begin
  { Lire 3 octets }
  For J := 0 To 2 Do Begin
   If I + J <= Len Then
    B[J] := Ord(S[I + J])
   Else
    B[J] := 0;
  End;

  { Encoder en 4 caracteres Base64 }
  Result := Result + Base64Chars[(B[0] Shr 2) + 1];
  Result := Result + Base64Chars[((B[0] And 3) Shl 4) Or (B[1] Shr 4) + 1];

  If I + 1 <= Len Then
   Result := Result + Base64Chars[((B[1] And 15) Shl 2) Or (B[2] Shr 6) + 1]
  Else
   Result := Result + '=';

  If I + 2 <= Len Then
   Result := Result + Base64Chars[(B[2] And 63) + 1]
  Else
   Result := Result + '=';

  I := I + 3;
 End;
 IMAP_EncodeBase64 := Result;
End;

{ Initialise le client IMAP avec les parametres par defaut }
Procedure IMAP_InitClient;
Begin
 IMAPClient.Host := '';
 IMAPClient.Port := IMAPS_PORT;
 IMAPClient.Username := '';
 IMAPClient.Password := '';
 IMAPClient.UseSSL := True;

 IMAPClient.State := isDisconnected;
 IMAPClient.TagCounter := 0;
 IMAPClient.LastTag := '';
 IMAPClient.LastError := '';
 IMAPClient.Capabilities := '';

 IMAPClient.CurrentMailbox.Name := '';
 IMAPClient.CurrentMailbox.Exists := 0;
 IMAPClient.CurrentMailbox.Recent := 0;
 IMAPClient.CurrentMailbox.Unseen := 0;
 IMAPClient.CurrentMailbox.UIDValidity := 0;
 IMAPClient.CurrentMailbox.UIDNext := 0;
 IMAPClient.CurrentMailbox.ReadOnly := False;
 IMAPClient.IsMailboxSelected := False;

 IMAPClient.IdleSupported := False;
 IMAPClient.IdleActive := False;
 IMAPClient.Connected := False;
 IMAPClient.SocketHandle := -1;

 IMAPMessageCount := 0;
 IMAPConnecting := False;
 IMAPLastActivity := 0;
End;

{ Configure le client IMAP }
Procedure IMAP_Configure(Host: String; Port: Integer; User, Pass: String; UseSSL: Boolean);
Begin
 IMAPClient.Host := Host;
 IMAPClient.Port := Port;
 IMAPClient.Username := User;
 IMAPClient.Password := Pass;
 IMAPClient.UseSSL := UseSSL;
End;

{ Envoie une commande IMAP et lit la reponse taguee et ses literals. }
Function IMAP_SendCommand(Command: String): TIMAPResponse;
Var R: TIMAPResponse; Tag, Line, LiteralData, Cmd, NumberText: TMailText;
 N, P, Q, Code: LongInt;
Begin
 FillChar(R, SizeOf(R), 0); R.ResponseType := irBAD;
 R.Text := 'Erreur reseau'; MailRaw := ''; OlInClear; OlDbg('IMAP > ' + Command); MailFetchFlags:=''; MailFetchUID:=0;
 Cmd := Command;
 If (Cmd = 'IDLE') Or (Cmd = 'DONE') Then Begin
  R.Text := 'IDLE non pris en charge'; IMAP_SendCommand := R; Exit;
 End;
 If Not MailSafe(Cmd) Then Begin R.Text := MailError; IMAP_SendCommand := R; Exit; End;
 Tag := IMAP_GenerateTag; R.Tag := Tag; IMAPClient.LastTag := Tag;
 If MailWrite(IMAPWire, Tag + ' ' + Cmd + #13#10) Then
 Repeat
  If Not MailReadLine(IMAPWire, Line) Then Break;
  If Copy(Line, 1, Length(Tag)+1) = Tag + ' ' Then Begin
   Line := Copy(Line, Length(Tag)+2, Length(Line));
   P := Pos(' ', Line); If P=0 Then P := Length(Line)+1;
   R.StatusCode := Copy(Line, 1, P-1); R.Text := Copy(Line, P+1, 200);
   If R.StatusCode = 'OK' Then R.ResponseType := irOK
   Else If R.StatusCode = 'NO' Then R.ResponseType := irNO;
   If R.ResponseType = irOK Then Begin
    If (Pos('LOGIN ', Cmd)=1) Or (Pos('AUTHENTICATE ', Cmd)=1) Then IMAPClient.State := isAuthenticated;
    If (Pos('SELECT ', Cmd)=1) Or (Pos('EXAMINE ', Cmd)=1) Then Begin
     IMAPClient.State := isSelected; IMAPClient.IsMailboxSelected := True;
    End;
   End;
   IMAP_SendCommand := R; Exit;
  End;
  If Copy(Line,1,1)='+' Then Begin
   If Pos('AUTHENTICATE PLAIN ', Cmd)=1 Then Begin
    If Not MailWrite(IMAPWire, Copy(Cmd,20,Length(Cmd))+#13#10) Then Break;
   End Else Begin MailError := 'Continuation IMAP inattendue'; Break; End;
  End;
  If Pos('FETCH',Line)>0 Then Begin
   MailFetchFlags:=MailFetchFlags+Line;
   P:=Pos('UID ',Line);
   If P>0 Then Begin
    NumberText:=''; Q:=P+4;
    While (Q<=Length(Line)) And (Line[Q] In ['0'..'9']) Do Begin
     NumberText:=NumberText+Line[Q]; Inc(Q);
    End;
    Val(NumberText,N,Code); If Code=0 Then MailFetchUID:=N;
   End;
  End;
  If Pos(' EXISTS', Line)>0 Then Begin
   NumberText := Copy(Line,3,Pos(' EXISTS',Line)-3);
   Val(NumberText,N,Code); If (Code=0) And (N>=0) Then IMAPClient.CurrentMailbox.Exists := N;
  End;
  If Copy(Line,1,13)='* CAPABILITY ' Then IMAPClient.Capabilities := Copy(Line,14,200);
  If (Length(Line)>0) And (Line[Length(Line)]='}') Then Begin
   P := 0; For Q := Length(Line)-1 DownTo 1 Do If Line[Q]='{' Then Begin P:=Q; Break; End;
   If P>0 Then Begin
    NumberText := Copy(Line,P+1,Length(Line)-P-1); Val(NumberText,N,Code);
    If Code<>0 Then Begin MailError := 'Taille de literal IMAP invalide'; Break; End;
    If Not MailReadBytes(IMAPWire,N,LiteralData) Then Break;
   End;
  End;
  R.HasData := True; R.Data := Copy(Line,1,255);
 Until False;
 R.Text := MailError; IMAPClient.LastError := MailError;
 MailClose(IMAPWire); IMAPClient.Connected := False;
 IMAP_SendCommand := R;
End;

{ Connecte au serveur IMAP }
Function IMAP_Connect: Integer;
Var Line: TMailText; R: TIMAPResponse;
Begin
 IMAP_Connect := IMAP_ERR_CONNECT; IMAPClient.Connected := False;
 If Not MailOpen(IMAPWire,IMAPClient.Host,IMAPClient.Port,IMAPClient.UseSSL) Then Begin
  IMAPClient.LastError := MailError; Exit;
 End;
 If Not MailReadLine(IMAPWire,Line) Or
    ((Copy(Line,1,5)<>'* OK ') And (Copy(Line,1,10)<>'* PREAUTH ')) Then Begin
  IMAPClient.LastError := 'Accueil IMAP invalide: '+Copy(Line,1,50); MailClose(IMAPWire); Exit;
 End;
 IMAPClient.Connected := True; IMAPClient.State := isConnected;
 If Copy(Line,1,10)='* PREAUTH ' Then IMAPClient.State := isAuthenticated;
 R := IMAP_SendCommand('CAPABILITY');
 If R.ResponseType<>irOK Then Begin IMAPClient.LastError:=R.Text; MailClose(IMAPWire); Exit; End;
 IMAP_Connect := IMAP_OK;
End;

{ Authentifie avec la methode LOGIN }
Function IMAP_LoginAuth: Integer;
Var
 Response: TIMAPResponse;
 Command: String;
Begin
 If IMAPClient.State <> isConnected Then Begin
  IMAPClient.LastError := 'Non connecte';
  IMAP_LoginAuth := IMAP_ERR_AUTH;
  Exit;
 End;

 If Not MailSafe(IMAPClient.Username) Or Not MailSafe(IMAPClient.Password) Then Begin
  IMAPClient.LastError := MailError; IMAP_LoginAuth := IMAP_ERR_AUTH; Exit;
 End;
 Command := 'LOGIN ' + MailQuote(IMAPClient.Username) + ' ' + MailQuote(IMAPClient.Password);
 Response := IMAP_SendCommand(Command);

 If Response.ResponseType = irOK Then
  IMAP_LoginAuth := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec authentification: ' + Response.Text;
  IMAP_LoginAuth := IMAP_ERR_AUTH;
 End;
End;

{ Authentifie avec la methode PLAIN (Base64) }
Function IMAP_PlainAuth: Integer;
Var
 Response: TIMAPResponse;
 AuthString, Encoded: String;
Begin
 If IMAPClient.State <> isConnected Then Begin
  IMAPClient.LastError := 'Non connecte';
  IMAP_PlainAuth := IMAP_ERR_AUTH;
  Exit;
 End;

 { Format PLAIN: \0username\0password }
 AuthString := #0 + IMAPClient.Username + #0 + IMAPClient.Password;
 Encoded := IMAP_EncodeBase64(AuthString);

 Response := IMAP_SendCommand('AUTHENTICATE PLAIN ' + Encoded);

 If Response.ResponseType = irOK Then
  IMAP_PlainAuth := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec authentification PLAIN: ' + Response.Text;
  IMAP_PlainAuth := IMAP_ERR_AUTH;
 End;
End;

{ Selectionne une boite aux lettres }
Function IMAP_Select(Mailbox: String): Integer;
Var
 Response: TIMAPResponse;
Begin
 If IMAPClient.State < isAuthenticated Then Begin
  IMAPClient.LastError := 'Non authentifie';
  IMAP_Select := IMAP_ERR_SELECT;
  Exit;
 End;

 Response := IMAP_SendCommand('SELECT "' + Mailbox + '"');

 If Response.ResponseType = irOK Then Begin
  IMAPClient.CurrentMailbox.Name := Mailbox;
  IMAP_Select := IMAP_OK;
 End
 Else Begin
  IMAPClient.LastError := 'Echec SELECT: ' + Response.Text;
  IMAP_Select := IMAP_ERR_SELECT;
 End;
End;

{ Examine une boite aux lettres (lecture seule) }
Function IMAP_Examine(Mailbox: String): Integer;
Var
 Response: TIMAPResponse;
Begin
 If IMAPClient.State < isAuthenticated Then Begin
  IMAPClient.LastError := 'Non authentifie';
  IMAP_Examine := IMAP_ERR_SELECT;
  Exit;
 End;

 Response := IMAP_SendCommand('EXAMINE "' + Mailbox + '"');

 If Response.ResponseType = irOK Then Begin
  IMAPClient.CurrentMailbox.Name := Mailbox;
  IMAP_Examine := IMAP_OK;
 End
 Else Begin
  IMAPClient.LastError := 'Echec EXAMINE: ' + Response.Text;
  IMAP_Examine := IMAP_ERR_SELECT;
 End;
End;

{ Recupere les en-tetes d'un message par numero de sequence }
Function IMAP_FetchHeaders(SeqNum: LongInt): Integer;
Var
 Response: TIMAPResponse;
 SeqStr: String;
Begin
 If Not IMAPClient.IsMailboxSelected Then Begin
  IMAPClient.LastError := 'Aucune boite selectionnee';
  IMAP_FetchHeaders := IMAP_ERR_FETCH;
  Exit;
 End;

 Str(SeqNum, SeqStr);
 Response := IMAP_SendCommand('FETCH ' + SeqStr + ' (FLAGS ENVELOPE RFC822.SIZE)');

 If Response.ResponseType = irOK Then
  IMAP_FetchHeaders := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec FETCH: ' + Response.Text;
  IMAP_FetchHeaders := IMAP_ERR_FETCH;
 End;
End;

{ Recupere le corps complet d'un message }
Function IMAP_FetchBody(SeqNum: LongInt): Integer;
Var
 Response: TIMAPResponse;
 SeqStr: String;
Begin
 If Not IMAPClient.IsMailboxSelected Then Begin
  IMAPClient.LastError := 'Aucune boite selectionnee';
  IMAP_FetchBody := IMAP_ERR_FETCH;
  Exit;
 End;

 Str(SeqNum, SeqStr);
 Response := IMAP_SendCommand('FETCH ' + SeqStr + ' BODY.PEEK[]');

 If Response.ResponseType = irOK Then
  IMAP_FetchBody := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec FETCH BODY: ' + Response.Text;
  IMAP_FetchBody := IMAP_ERR_FETCH;
 End;
End;

{ Recupere un message par son UID }
Function IMAP_UIDFetch(UID: LongInt; FetchType: String): Integer;
Var
 Response: TIMAPResponse;
 UIDStr: String;
Begin
 If Not IMAPClient.IsMailboxSelected Then Begin
  IMAPClient.LastError := 'Aucune boite selectionnee';
  IMAP_UIDFetch := IMAP_ERR_FETCH;
  Exit;
 End;

 Str(UID, UIDStr);
 Response := IMAP_SendCommand('UID FETCH ' + UIDStr + ' ' + FetchType);

 If Response.ResponseType = irOK Then
  IMAP_UIDFetch := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec UID FETCH: ' + Response.Text;
  IMAP_UIDFetch := IMAP_ERR_FETCH;
 End;
End;

{ Modifie les drapeaux d'un message }
Function IMAP_Store(SeqNum: LongInt; Flags: String; AddFlags: Boolean): Integer;
Var
 Response: TIMAPResponse;
 SeqStr, FlagOp: String;
Begin
 If Not IMAPClient.IsMailboxSelected Then Begin
  IMAPClient.LastError := 'Aucune boite selectionnee';
  IMAP_Store := IMAP_ERR_STORE;
  Exit;
 End;

 Str(SeqNum, SeqStr);
 If AddFlags Then
  FlagOp := '+FLAGS'
 Else
  FlagOp := '-FLAGS';

 Response := IMAP_SendCommand('STORE ' + SeqStr + ' ' + FlagOp + ' (' + Flags + ')');

 If Response.ResponseType = irOK Then
  IMAP_Store := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec STORE: ' + Response.Text;
  IMAP_Store := IMAP_ERR_STORE;
 End;
End;

{ Marque un message comme lu }
Function IMAP_MarkAsRead(SeqNum: LongInt): Integer;
Begin
 IMAP_MarkAsRead := IMAP_Store(SeqNum, IMAP_FLAG_SEEN, True);
End;

{ Marque un message comme non lu }
Function IMAP_MarkAsUnread(SeqNum: LongInt): Integer;
Begin
 IMAP_MarkAsUnread := IMAP_Store(SeqNum, IMAP_FLAG_SEEN, False);
End;

{ Marque un message comme repondu }
Function IMAP_MarkAsAnswered(SeqNum: LongInt): Integer;
Begin
 IMAP_MarkAsAnswered := IMAP_Store(SeqNum, IMAP_FLAG_ANSWERED, True);
End;

{ Marque un message avec un drapeau }
Function IMAP_SetFlagged(SeqNum: LongInt; Flagged: Boolean): Integer;
Begin
 IMAP_SetFlagged := IMAP_Store(SeqNum, IMAP_FLAG_FLAGGED, Flagged);
End;

{ Marque un message comme supprime }
Function IMAP_MarkDeleted(SeqNum: LongInt): Integer;
Begin
 IMAP_MarkDeleted := IMAP_Store(SeqNum, IMAP_FLAG_DELETED, True);
End;

{ Copie un message vers une autre boite }
Function IMAP_Copy(SeqNum: LongInt; DestMailbox: String): Integer;
Var
 Response: TIMAPResponse;
 SeqStr: String;
Begin
 If Not IMAPClient.IsMailboxSelected Then Begin
  IMAPClient.LastError := 'Aucune boite selectionnee';
  IMAP_Copy := IMAP_ERR_COPY;
  Exit;
 End;

 Str(SeqNum, SeqStr);
 Response := IMAP_SendCommand('COPY ' + SeqStr + ' "' + DestMailbox + '"');

 If Response.ResponseType = irOK Then
  IMAP_Copy := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec COPY: ' + Response.Text;
  IMAP_Copy := IMAP_ERR_COPY;
 End;
End;

{ Copie un message par UID }
Function IMAP_UIDCopy(UID: LongInt; DestMailbox: String): Integer;
Var
 Response: TIMAPResponse;
 UIDStr: String;
Begin
 If Not IMAPClient.IsMailboxSelected Then Begin
  IMAPClient.LastError := 'Aucune boite selectionnee';
  IMAP_UIDCopy := IMAP_ERR_COPY;
  Exit;
 End;

 Str(UID, UIDStr);
 Response := IMAP_SendCommand('UID COPY ' + UIDStr + ' "' + DestMailbox + '"');

 If Response.ResponseType = irOK Then
  IMAP_UIDCopy := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec UID COPY: ' + Response.Text;
  IMAP_UIDCopy := IMAP_ERR_COPY;
 End;
End;

{ Liste les boites aux lettres }
Function IMAP_List(Reference, Pattern: String): Integer;
Var
 Response: TIMAPResponse;
Begin
 If IMAPClient.State < isAuthenticated Then Begin
  IMAPClient.LastError := 'Non authentifie';
  IMAP_List := IMAP_ERR_PROTOCOL;
  Exit;
 End;

 Response := IMAP_SendCommand('LIST "' + Reference + '" "' + Pattern + '"');

 If Response.ResponseType = irOK Then
  IMAP_List := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec LIST: ' + Response.Text;
  IMAP_List := IMAP_ERR_PROTOCOL;
 End;
End;

{ Liste les boites aux lettres abonnees }
Function IMAP_LSub(Reference, Pattern: String): Integer;
Var
 Response: TIMAPResponse;
Begin
 If IMAPClient.State < isAuthenticated Then Begin
  IMAPClient.LastError := 'Non authentifie';
  IMAP_LSub := IMAP_ERR_PROTOCOL;
  Exit;
 End;

 Response := IMAP_SendCommand('LSUB "' + Reference + '" "' + Pattern + '"');

 If Response.ResponseType = irOK Then
  IMAP_LSub := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec LSUB: ' + Response.Text;
  IMAP_LSub := IMAP_ERR_PROTOCOL;
 End;
End;

{ Entre en mode IDLE pour les notifications push }
Function IMAP_StartIdle: Integer;
Var
 Response: TIMAPResponse;
Begin
 If Not IMAPClient.IdleSupported Then Begin
  IMAPClient.LastError := 'IDLE non supporte par le serveur';
  IMAP_StartIdle := IMAP_ERR_PROTOCOL;
  Exit;
 End;

 If Not IMAPClient.IsMailboxSelected Then Begin
  IMAPClient.LastError := 'Aucune boite selectionnee';
  IMAP_StartIdle := IMAP_ERR_PROTOCOL;
  Exit;
 End;

 Response := IMAP_SendCommand('IDLE');

 If Response.ResponseType = irContinue Then Begin
  IMAPClient.IdleActive := True;
  IMAP_StartIdle := IMAP_OK;
 End
 Else Begin
  IMAPClient.LastError := 'Echec IDLE: ' + Response.Text;
  IMAP_StartIdle := IMAP_ERR_PROTOCOL;
 End;
End;

{ Sort du mode IDLE }
Function IMAP_StopIdle: Integer;
Var
 Response: TIMAPResponse;
Begin
 If Not IMAPClient.IdleActive Then Begin
  IMAP_StopIdle := IMAP_OK;
  Exit;
 End;

 Response := IMAP_SendCommand('DONE');

 If Response.ResponseType = irOK Then Begin
  IMAPClient.IdleActive := False;
  IMAP_StopIdle := IMAP_OK;
 End
 Else Begin
  IMAPClient.LastError := 'Echec DONE: ' + Response.Text;
  IMAP_StopIdle := IMAP_ERR_PROTOCOL;
 End;
End;

{ Envoie une commande NOOP pour maintenir la connexion }
Function IMAP_Noop: Integer;
Var
 Response: TIMAPResponse;
Begin
 Response := IMAP_SendCommand('NOOP');

 If Response.ResponseType = irOK Then
  IMAP_Noop := IMAP_OK
 Else Begin
  IMAPClient.LastError := 'Echec NOOP: ' + Response.Text;
  IMAP_Noop := IMAP_ERR_PROTOCOL;
 End;
End;

{ Se deconnecte du serveur IMAP }
Function IMAP_Logout: Integer;
Var
 Response: TIMAPResponse;
Begin
 If Not IMAPClient.Connected Then Begin
  IMAP_Logout := IMAP_OK;
  Exit;
 End;

 { Sortir du mode IDLE si actif }
 If IMAPClient.IdleActive Then
  IMAP_StopIdle;

 Response := IMAP_SendCommand('LOGOUT');
 MailClose(IMAPWire);

 { Fermer la connexion }
 IMAPClient.Connected := False;
 IMAPClient.SocketHandle := -1;
 IMAPClient.State := isDisconnected;
 IMAPClient.IsMailboxSelected := False;
 IMAPClient.IdleActive := False;

 IMAP_Logout := IMAP_OK;
End;

{ Deconnecte du serveur IMAP }
Procedure IMAP_Disconnect;
Begin
 IMAP_Logout;
End;

{ Supprime un message sur le serveur par son identifiant }
Function IMAP_DeleteMessage(MsgID: String): Boolean;
Var
 SeqNum: LongInt;
 Code: Integer;
Begin
 IMAP_DeleteMessage := False;
 Val(MsgID, SeqNum, Code);
 If Code <> 0 Then Exit;
 If IMAP_MarkDeleted(SeqNum) = IMAP_OK Then
  IMAP_DeleteMessage := True;
End;

{ Deplace un message vers un autre dossier }
Function IMAP_MoveMessage(MsgID, TargetFolder: String): Boolean;
Var
 SeqNum: LongInt;
 Code: Integer;
Begin
 IMAP_MoveMessage := False;
 Val(MsgID, SeqNum, Code);
 If Code <> 0 Then Exit;
 If IMAP_Copy(SeqNum, TargetFolder) = IMAP_OK Then Begin
  If IMAP_MarkDeleted(SeqNum) = IMAP_OK Then
   IMAP_MoveMessage := True;
 End;
End;

{ Modifie un drapeau sur un message }
Function IMAP_SetFlag(MsgID, Flag: String; Value: Boolean): Boolean;
Var
 SeqNum: LongInt;
 Code: Integer;
Begin
 IMAP_SetFlag := False;
 Val(MsgID, SeqNum, Code);
 If Code <> 0 Then Exit;
 If IMAP_Store(SeqNum, Flag, Value) = IMAP_OK Then
  IMAP_SetFlag := True;
End;

{ Synchronise la liste des messages avec le serveur }
Procedure IMAP_SyncMessages;
Begin
 ReceiveMail;
End;

{ Convertit les drapeaux IMAP en chaine }
Function IMAP_FlagsToString(Flags: TIMAPFlags): String;
Var
 S: String;
Begin
 S := '';
 If Flags.Seen Then S := S + IMAP_FLAG_SEEN + ' ';
 If Flags.Answered Then S := S + IMAP_FLAG_ANSWERED + ' ';
 If Flags.Flagged Then S := S + IMAP_FLAG_FLAGGED + ' ';
 If Flags.Deleted Then S := S + IMAP_FLAG_DELETED + ' ';
 If Flags.Draft Then S := S + IMAP_FLAG_DRAFT + ' ';
 If Flags.Recent Then S := S + IMAP_FLAG_RECENT + ' ';
 { Supprimer l'espace final }
 If Length(S) > 0 Then
  Delete(S, Length(S), 1);
 IMAP_FlagsToString := S;
End;

{ Retourne l'etat de connexion sous forme de chaine }
Function IMAP_GetStateString: String;
Begin
 Case IMAPClient.State Of
  isDisconnected: IMAP_GetStateString := 'Deconnecte';
  isConnected: IMAP_GetStateString := 'Connecte';
  isAuthenticated: IMAP_GetStateString := 'Authentifie';
  isSelected: IMAP_GetStateString := 'Boite selectionnee';
  isLogout: IMAP_GetStateString := 'Deconnexion';
 Else
  IMAP_GetStateString := 'Inconnu';
 End;
End;

{ Retourne les informations de la boite courante }
Function IMAP_GetMailboxInfo: String;
Var
 S, NumStr: String;
Begin
 If Not IMAPClient.IsMailboxSelected Then Begin
  IMAP_GetMailboxInfo := 'Aucune boite selectionnee';
  Exit;
 End;

 S := IMAPClient.CurrentMailbox.Name + ': ';
 Str(IMAPClient.CurrentMailbox.Exists, NumStr);
 S := S + NumStr + ' messages, ';
 Str(IMAPClient.CurrentMailbox.Recent, NumStr);
 S := S + NumStr + ' recents, ';
 Str(IMAPClient.CurrentMailbox.Unseen, NumStr);
 S := S + NumStr + ' non lus';

 If IMAPClient.CurrentMailbox.ReadOnly Then
  S := S + ' [LECTURE SEULE]';

 IMAP_GetMailboxInfo := S;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION IMAP
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU CLIENT POP3 (RFC 1939)
  ============================================================================ }

{ Initialise le client POP3 avec les parametres par defaut }
Procedure POP3_InitClient;
Begin
 POP3Client.Host := '';
 POP3Client.Port := POP3S_PORT;
 POP3Client.Username := '';
 POP3Client.Password := '';
 POP3Client.UseSSL := True;

 POP3Client.State := psDisconnected;
 POP3Client.LastError := '';
 POP3Client.ServerGreeting := '';
 POP3Client.APOPTimestamp := '';

 POP3Client.Stats.MessageCount := 0;
 POP3Client.Stats.TotalSize := 0;

 POP3Client.LeaveOnServer := True;
 POP3Client.HeadersOnly := False;
 POP3Client.DeleteAfterDays := 0;

 POP3Client.Connected := False;
 POP3Client.SocketHandle := -1;

 POP3MessageCount := 0;
 POP3Connecting := False;
 POP3LastActivity := 0;
End;

{ Configure le client POP3 }
Procedure POP3_Configure(Host: String; Port: Integer; User, Pass: String; UseSSL: Boolean);
Begin
 POP3Client.Host := Host;
 POP3Client.Port := Port;
 POP3Client.Username := User;
 POP3Client.Password := Pass;
 POP3Client.UseSSL := UseSSL;
End;

{ Configure les options du client POP3 }
Procedure POP3_SetOptions(LeaveOnServer, HeadersOnly: Boolean; DeleteAfterDays: Integer);
Begin
 POP3Client.LeaveOnServer := LeaveOnServer;
 POP3Client.HeadersOnly := HeadersOnly;
 POP3Client.DeleteAfterDays := DeleteAfterDays;
End;

{ Extrait le timestamp APOP du message de bienvenue }
Function POP3_ExtractAPOPTimestamp(Greeting: String): String;
Var
 StartPos, EndPos: Integer;
Begin
 POP3_ExtractAPOPTimestamp := '';
 StartPos := Pos('<', Greeting);
 If StartPos > 0 Then Begin
  EndPos := Pos('>', Greeting);
  If EndPos > StartPos Then
   POP3_ExtractAPOPTimestamp := Copy(Greeting, StartPos, EndPos - StartPos + 1);
 End;
End;

{ Calcule le hash MD5 pour l'authentification APOP }
{ Note: Implementation simplifiee, retourne une chaine hexadecimale }
Function POP3_MD5Hash(Input: String): String;
Begin
 POP3_MD5Hash := ''; { APOP non pris en charge; utiliser USER/PASS sur TLS. }
End;



{ Echanges POP3, reponses multilignes et transparence des points. }
Function POP3_SendCommand(Command: String): TPOP3Response;
Var R: TPOP3Response; Line, Cmd, Part: TMailText; Multi: Boolean;
Begin
 FillChar(R,SizeOf(R),0); R.ResponseType:=prERR; MailRaw:=''; OlInClear; OlWasPartial:=False; Cmd:=Command;
 If Not MailSafe(Cmd) Then Begin R.Text:=MailError; POP3_SendCommand:=R; Exit; End;
 If MailWrite(POP3Wire,Cmd+#13#10) And MailReadLine(POP3Wire,Line) Then Begin
  R.Text:=Copy(Line,5,200);
  If Copy(Line,1,3)='+OK' Then Begin
   R.ResponseType:=prOK;
   If Pos('PASS ',Cmd)=1 Then POP3Client.State:=psTransaction;
   Multi := (Pos('RETR ',Cmd)=1) Or (Pos('TOP ',Cmd)=1) Or (Cmd='LIST') Or (Cmd='UIDL') Or (Cmd='CAPA');
   R.HasMultiline:=Multi;
   If Multi Then Repeat
    If Not MailReadLine(POP3Wire,Part) Then Begin R.ResponseType:=prERR; Break; End;
    If Not OlWasPartial Then Begin
     If Part='.' Then Break;
     If Copy(Part,1,2)='..' Then Delete(Part,1,1);
    End;
    OlWasPartial:=OlLinePartial;
    OlInAdd(Part); If Not OlLinePartial Then OlInAdd(#13#10);
    If Length(MailRaw)<255 Then MailRaw:=Copy(MailRaw+Part+#13#10,1,255);
   Until False;
   R.Data:=Copy(MailRaw,1,255);
  End;
 End Else R.Text:=MailError;
 If (R.ResponseType<>prOK) And (MailError<>'') Then Begin
  R.Text:=MailError; MailClose(POP3Wire); POP3Client.Connected:=False;
 End;
 POP3_SendCommand:=R;
End;

{ Connecte au serveur POP3 }
Function POP3_Connect: Integer;
Var Line: TMailText;
Begin
 POP3_Connect:=POP3_ERR_CONNECT; POP3Client.Connected:=False;
 If Not MailOpen(POP3Wire,POP3Client.Host,POP3Client.Port,POP3Client.UseSSL) Then Begin
  POP3Client.LastError:=MailError; Exit;
 End;
 If Not MailReadLine(POP3Wire,Line) Or (Copy(Line,1,3)<>'+OK') Then Begin
  POP3Client.LastError:='Accueil POP3 invalide'; MailClose(POP3Wire); Exit;
 End;
 POP3Client.ServerGreeting:=Line; POP3Client.APOPTimestamp:='';
 POP3Client.Connected:=True; POP3Client.State:=psAuthorization;
 POP3_Connect:=POP3_OK;
End;

{ Authentifie avec la methode USER/PASS }
Function POP3_AuthUserPass: Integer;
Var
 Response: TPOP3Response;
Begin
 If POP3Client.State <> psAuthorization Then Begin
  POP3Client.LastError := 'Pas en etat AUTHORIZATION';
  POP3_AuthUserPass := POP3_ERR_AUTH;
  Exit;
 End;

 { Envoyer USER }
 Response := POP3_SendCommand('USER ' + POP3Client.Username);
 If Response.ResponseType <> prOK Then Begin
  POP3Client.LastError := 'USER echoue: ' + Response.Text;
  POP3_AuthUserPass := POP3_ERR_AUTH;
  Exit;
 End;

 { Envoyer PASS }
 Response := POP3_SendCommand('PASS ' + POP3Client.Password);
 If Response.ResponseType = prOK Then
  POP3_AuthUserPass := POP3_OK
 Else Begin
  POP3Client.LastError := 'PASS echoue: ' + Response.Text;
  POP3_AuthUserPass := POP3_ERR_AUTH;
 End;
End;

{ Authentifie avec la methode APOP }
Function POP3_AuthAPOP: Integer;
Begin
 POP3Client.LastError:='APOP non pris en charge; utiliser USER/PASS';
 POP3_AuthAPOP:=POP3_ERR_AUTH;
End;

{ Obtient les statistiques de la boite (STAT) }
Function POP3_Stat: Integer;
Var
 Response: TPOP3Response;
Begin
 If POP3Client.State <> psTransaction Then Begin
  POP3Client.LastError := 'Pas en etat TRANSACTION';
  POP3_Stat := POP3_ERR_STAT;
  Exit;
 End;

 Response := POP3_SendCommand('STAT');

 If Response.ResponseType = prOK Then
  POP3_Stat := POP3_OK
 Else Begin
  POP3Client.LastError := 'STAT echoue: ' + Response.Text;
  POP3_Stat := POP3_ERR_STAT;
 End;
End;

{ Liste les messages (LIST) }
Function POP3_List(MsgNum: Integer): Integer;
Var
 Response: TPOP3Response;
 NumStr: String;
Begin
 If POP3Client.State <> psTransaction Then Begin
  POP3Client.LastError := 'Pas en etat TRANSACTION';
  POP3_List := POP3_ERR_LIST;
  Exit;
 End;

 If MsgNum > 0 Then Begin
  Str(MsgNum, NumStr);
  Response := POP3_SendCommand('LIST ' + NumStr);
 End
 Else
  Response := POP3_SendCommand('LIST');

 If Response.ResponseType = prOK Then
  POP3_List := POP3_OK
 Else Begin
  POP3Client.LastError := 'LIST echoue: ' + Response.Text;
  POP3_List := POP3_ERR_LIST;
 End;
End;

{ Recupere un message complet (RETR) }
Function POP3_Retr(MsgNum: Integer): Integer;
Var
 Response: TPOP3Response;
 NumStr: String;
Begin
 If POP3Client.State <> psTransaction Then Begin
  POP3Client.LastError := 'Pas en etat TRANSACTION';
  POP3_Retr := POP3_ERR_RETR;
  Exit;
 End;

 Str(MsgNum, NumStr);
 Response := POP3_SendCommand('RETR ' + NumStr);

 If Response.ResponseType = prOK Then
  POP3_Retr := POP3_OK
 Else Begin
  POP3Client.LastError := 'RETR echoue: ' + Response.Text;
  POP3_Retr := POP3_ERR_RETR;
 End;
End;

{ Marque un message pour suppression (DELE) }
Function POP3_Dele(MsgNum: Integer): Integer;
Var
 Response: TPOP3Response;
 NumStr: String;
Begin
 If POP3Client.State <> psTransaction Then Begin
  POP3Client.LastError := 'Pas en etat TRANSACTION';
  POP3_Dele := POP3_ERR_DELE;
  Exit;
 End;

 Str(MsgNum, NumStr);
 Response := POP3_SendCommand('DELE ' + NumStr);

 If Response.ResponseType = prOK Then Begin
  { Marquer le message localement }
  If (MsgNum > 0) And (MsgNum <= POP3MessageCount) Then
   POP3ListItems^[MsgNum - 1].Deleted := True;
  POP3_Dele := POP3_OK;
 End
 Else Begin
  POP3Client.LastError := 'DELE echoue: ' + Response.Text;
  POP3_Dele := POP3_ERR_DELE;
 End;
End;

{ Recupere les en-tetes + N lignes du corps (TOP) }
Function POP3_Top(MsgNum, Lines: Integer): Integer;
Var
 Response: TPOP3Response;
 NumStr, LineStr: String;
Begin
 If POP3Client.State <> psTransaction Then Begin
  POP3Client.LastError := 'Pas en etat TRANSACTION';
  POP3_Top := POP3_ERR_TOP;
  Exit;
 End;

 Str(MsgNum, NumStr);
 Str(Lines, LineStr);
 Response := POP3_SendCommand('TOP ' + NumStr + ' ' + LineStr);

 If Response.ResponseType = prOK Then
  POP3_Top := POP3_OK
 Else Begin
  POP3Client.LastError := 'TOP echoue: ' + Response.Text;
  POP3_Top := POP3_ERR_TOP;
 End;
End;

{ Obtient les identifiants uniques (UIDL) }
Function POP3_UIDL(MsgNum: Integer): Integer;
Var
 Response: TPOP3Response;
 NumStr: String;
Begin
 If POP3Client.State <> psTransaction Then Begin
  POP3Client.LastError := 'Pas en etat TRANSACTION';
  POP3_UIDL := POP3_ERR_UIDL;
  Exit;
 End;

 If MsgNum > 0 Then Begin
  Str(MsgNum, NumStr);
  Response := POP3_SendCommand('UIDL ' + NumStr);
 End
 Else
  Response := POP3_SendCommand('UIDL');

 If Response.ResponseType = prOK Then
  POP3_UIDL := POP3_OK
 Else Begin
  POP3Client.LastError := 'UIDL echoue: ' + Response.Text;
  POP3_UIDL := POP3_ERR_UIDL;
 End;
End;

{ Envoie une commande NOOP pour maintenir la connexion }
Function POP3_Noop: Integer;
Var
 Response: TPOP3Response;
Begin
 Response := POP3_SendCommand('NOOP');

 If Response.ResponseType = prOK Then
  POP3_Noop := POP3_OK
 Else Begin
  POP3Client.LastError := 'NOOP echoue: ' + Response.Text;
  POP3_Noop := POP3_ERR_PROTOCOL;
 End;
End;

{ Annule les suppressions marquees (RSET) }
Function POP3_Rset: Integer;
Var
 Response: TPOP3Response;
 I: Integer;
Begin
 If POP3Client.State <> psTransaction Then Begin
  POP3Client.LastError := 'Pas en etat TRANSACTION';
  POP3_Rset := POP3_ERR_PROTOCOL;
  Exit;
 End;

 Response := POP3_SendCommand('RSET');

 If Response.ResponseType = prOK Then Begin
  { Annuler les marquages locaux }
  For I := 0 To POP3MessageCount - 1 Do
   POP3ListItems^[I].Deleted := False;
  POP3_Rset := POP3_OK;
 End
 Else Begin
  POP3Client.LastError := 'RSET echoue: ' + Response.Text;
  POP3_Rset := POP3_ERR_PROTOCOL;
 End;
End;

{ Se deconnecte du serveur POP3 (QUIT) }
Function POP3_Quit: Integer;
Var
 Response: TPOP3Response;
Begin
 If Not POP3Client.Connected Then Begin
  POP3_Quit := POP3_OK;
  Exit;
 End;

 Response := POP3_SendCommand('QUIT');
 MailClose(POP3Wire);

 { Fermer la connexion }
 POP3Client.Connected := False;
 POP3Client.SocketHandle := -1;
 POP3Client.State := psDisconnected;

 POP3_Quit := POP3_OK;
End;

{ Synchronise la liste des messages avec le serveur }
Procedure POP3_SyncMessages;
Begin
 ReceiveMail;
End;

Procedure POP3_DownloadMessages;
Begin
 ReceiveMail;
End;

{ Retourne l'etat de connexion sous forme de chaine }
Function POP3_GetStateString: String;
Begin
 Case POP3Client.State Of
  psDisconnected: POP3_GetStateString := 'Deconnecte';
  psAuthorization: POP3_GetStateString := 'Autorisation';
  psTransaction: POP3_GetStateString := 'Transaction';
  psUpdate: POP3_GetStateString := 'Mise a jour';
 Else
  POP3_GetStateString := 'Inconnu';
 End;
End;

{ Retourne les informations de la boite }
Function POP3_GetMailboxInfo: String;
Var
 S, NumStr: String;
Begin
 If POP3Client.State < psTransaction Then Begin
  POP3_GetMailboxInfo := 'Non connecte';
  Exit;
 End;

 Str(POP3Client.Stats.MessageCount, NumStr);
 S := NumStr + ' messages, ';
 Str(POP3Client.Stats.TotalSize Div 1024, NumStr);
 S := S + NumStr + ' Ko';

 POP3_GetMailboxInfo := S;
End;

{ Verifie si APOP est disponible }
Function POP3_IsAPOPAvailable: Boolean;
Begin
 POP3_IsAPOPAvailable := POP3Client.APOPTimestamp <> '';
End;

{ Compte les messages marques pour suppression }
Function POP3_GetDeletedCount: Integer;
Var
 I, Count: Integer;
Begin
 Count := 0;
 For I := 0 To POP3MessageCount - 1 Do
  If POP3ListItems^[I].Deleted Then
   Inc(Count);
 POP3_GetDeletedCount := Count;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION POP3
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU CLIENT SMTP (RFC 5321)
  ============================================================================ }

{ Initialise le client SMTP avec les parametres par defaut }
Procedure SMTP_InitClient;
Var
 I: Integer;
Begin
 SMTPClient.Host := '';
 SMTPClient.Port := SMTP_SUBMISSION_PORT;
 SMTPClient.Username := '';
 SMTPClient.Password := '';
 SMTPClient.UseSSL := False;
 SMTPClient.UseSTARTTLS := True;

 SMTPClient.State := ssDisconnected;
 SMTPClient.LastError := '';
 SMTPClient.LastCode := 0;
 SMTPClient.ServerGreeting := '';
 SMTPClient.ServerDomain := '';

 SMTPClient.Extensions.STARTTLS := False;
 SMTPClient.Extensions.AUTH_PLAIN := False;
 SMTPClient.Extensions.AUTH_LOGIN := False;
 SMTPClient.Extensions.AUTH_CRAM_MD5 := False;
 SMTPClient.Extensions.EIGHTBITMIME := False;
 SMTPClient.Extensions.SIZE := 0;
 SMTPClient.Extensions.PIPELINING := False;
 SMTPClient.Extensions.DSN := False;

 SMTPClient.AuthMethod := samNone;
 SMTPClient.Authenticated := False;

 SMTPClient.MailFrom := '';
 SMTPClient.RcptCount := 0;
 SMTPClient.RcptAccepted := 0;

 SMTPClient.Connected := False;
 SMTPClient.SocketHandle := -1;
 SMTPClient.TLSActive := False;

 { Initialiser les destinataires }
 For I := 0 To SMTP_MAX_RECIPIENTS - 1 Do Begin
  SMTPRecipients[I].Email := '';
  SMTPRecipients[I].Accepted := False;
  SMTPRecipients[I].ErrorMsg := '';
 End;

 { Initialiser le message courant }
 SMTPCurrentMessage.From := '';
 SMTPCurrentMessage.FromName := '';
 SMTPCurrentMessage.RecipientCount := 0;
 SMTPCurrentMessage.Subject := '';
 SMTPCurrentMessage.Body := '';
 SMTPCurrentMessage.ContentType := 'text/plain';
 SMTPCurrentMessage.CharSet := 'utf-8';

 SMTPSending := False;
 SMTPLastActivity := 0;
End;

{ Configure le client SMTP }
Procedure SMTP_Configure(Host: String; Port: Integer; User, Pass: String; UseSSL, UseSTARTTLS: Boolean);
Begin
 SMTPClient.Host := Host;
 SMTPClient.Port := Port;
 SMTPClient.Username := User;
 SMTPClient.Password := Pass;
 SMTPClient.UseSSL := UseSSL;
 SMTPClient.UseSTARTTLS := UseSTARTTLS;
End;

{ Determine la classe d'une reponse SMTP basee sur le code }
Function SMTP_GetResponseClass(Code: Integer): TSMTPResponseClass;
Begin
 Case Code Div 100 Of
  1: SMTP_GetResponseClass := srcPositivePrelim;
  2: SMTP_GetResponseClass := srcPositiveComplete;
  3: SMTP_GetResponseClass := srcPositiveInterm;
  4: SMTP_GetResponseClass := srcNegativeTransient;
  5: SMTP_GetResponseClass := srcNegativePermanent;
 Else
  SMTP_GetResponseClass := srcUnknown;
 End;
End;

{ Parse une reponse SMTP }
Function SMTP_ParseResponse(ResponseLine: String): TSMTPResponse;
Var
 Response: TSMTPResponse;
 CodeStr: String;
 ErrCode: Integer;
Begin
 Response.Code := 0;
 Response.ResponseClass := srcUnknown;
 Response.Text := '';
 Response.IsMultiline := False;
 Response.IsContinue := False;

 If Length(ResponseLine) >= 3 Then Begin
  CodeStr := Copy(ResponseLine, 1, 3);
  Val(CodeStr, Response.Code, ErrCode);
  If ErrCode = 0 Then Begin
   Response.ResponseClass := SMTP_GetResponseClass(Response.Code);
   { Verifier si c'est une ligne de continuation (code-texte) }
   If (Length(ResponseLine) >= 4) And (ResponseLine[4] = '-') Then Begin
    Response.IsMultiline := True;
    Response.IsContinue := True;
    If Length(ResponseLine) > 4 Then
     Response.Text := Copy(ResponseLine, 5, Length(ResponseLine) - 4);
   End
   Else If (Length(ResponseLine) >= 4) And (ResponseLine[4] = ' ') Then Begin
    If Length(ResponseLine) > 4 Then
     Response.Text := Copy(ResponseLine, 5, Length(ResponseLine) - 4);
   End
   Else If Length(ResponseLine) = 3 Then Begin
    Response.Text := '';
   End;
  End;
 End;

 SMTP_ParseResponse := Response;
End;

{ Echanges SMTP et reponses multilignes du serveur. }
Function SMTP_SendCommand(Command: String): TSMTPResponse;
Var R: TSMTPResponse; Line, Cmd: TMailText;
Begin
 FillChar(R,SizeOf(R),0); R.ResponseClass:=srcUnknown; Cmd:=Command;
 If Not MailSafe(Cmd) Then Begin R.Text:=MailError; SMTP_SendCommand:=R; Exit; End;
 If Cmd<>'' Then If Not MailWrite(SMTPWire,Cmd+#13#10) Then Begin R.Text:=MailError; SMTP_SendCommand:=R; Exit; End;
 Repeat
  If Not MailReadLine(SMTPWire,Line) Then Begin R.Code:=0; R.Text:=MailError; Break; End;
  R:=SMTP_ParseResponse(Copy(Line,1,255));
  If Pos('EHLO ',Cmd)=1 Then Begin
   If Pos('STARTTLS',Line)>0 Then SMTPClient.Extensions.STARTTLS:=True;
   If Pos('AUTH',Line)>0 Then Begin
    SMTPClient.Extensions.AUTH_PLAIN:=Pos('PLAIN',Line)>0;
    SMTPClient.Extensions.AUTH_LOGIN:=Pos('LOGIN',Line)>0;
   End;
  End;
 Until Not R.IsContinue;
 SMTPClient.LastCode:=R.Code;
 SMTP_SendCommand:=R;
End;



{ Encode une chaine en Base64 (implementation simplifiee) }
Function SMTP_Base64Encode(Input: String): String;
Const
 Base64Chars: String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
Var
 I, J, Len: Integer;
 B1, B2, B3: Byte;
 Output: String;
Begin
 Output := '';
 Len := Length(Input);
 I := 1;
 While I <= Len Do Begin
  B1 := Ord(Input[I]);
  If I + 1 <= Len Then B2 := Ord(Input[I + 1]) Else B2 := 0;
  If I + 2 <= Len Then B3 := Ord(Input[I + 2]) Else B3 := 0;

  Output := Output + Base64Chars[(B1 Shr 2) + 1];
  Output := Output + Base64Chars[((B1 And 3) Shl 4) Or (B2 Shr 4) + 1];
  If I + 1 <= Len Then
   Output := Output + Base64Chars[((B2 And 15) Shl 2) Or (B3 Shr 6) + 1]
  Else
   Output := Output + '=';
  If I + 2 <= Len Then
   Output := Output + Base64Chars[(B3 And 63) + 1]
  Else
   Output := Output + '=';

  Inc(I, 3);
 End;
 SMTP_Base64Encode := Output;
End;

{ Calcule un hash simplifie pour CRAM-MD5 }
Function SMTP_CRAMMD5Hash(Challenge, Password: String): String;
Begin
 SMTP_CRAMMD5Hash := ''; { Non pris en charge; AUTH LOGIN/PLAIN sur TLS. }
End;



{ Connecte au serveur SMTP }
Function SMTP_Connect: Integer;
Var R: TSMTPResponse;
Begin
 SMTP_Connect:=SMTP_ERR_CONNECT; SMTPClient.Connected:=False;
 If Not MailOpen(SMTPWire,SMTPClient.Host,SMTPClient.Port,SMTPClient.UseSSL) Then Begin
  SMTPClient.LastError:=MailError; Exit;
 End;
 R:=SMTP_SendCommand('');
 If R.Code<>220 Then Begin SMTPClient.LastError:=R.Text; MailClose(SMTPWire); Exit; End;
 SMTPClient.ServerGreeting:=R.Text; SMTPClient.Connected:=True;
 SMTPClient.TLSActive:=SMTPWire.Secure; SMTPClient.State:=ssConnected;
 SMTP_Connect:=SMTP_OK;
End;

{ Envoie la commande EHLO }
Function SMTP_EHLO(LocalDomain: String): Integer;
Var
 Response: TSMTPResponse;
Begin
 If SMTPClient.State < ssConnected Then Begin
  SMTPClient.LastError := 'Non connecte';
  SMTP_EHLO := SMTP_ERR_EHLO;
  Exit;
 End;

 Response := SMTP_SendCommand('EHLO ' + LocalDomain);
 If Response.Code = SMTP_CODE_OK Then Begin
  SMTPClient.State := ssConnected;
  SMTP_EHLO := SMTP_OK;
 End
 Else Begin
  SMTPClient.LastError := 'EHLO echoue: ' + Response.Text;
  SMTP_EHLO := SMTP_ERR_EHLO;
 End;
End;

{ Active STARTTLS pour passer en mode securise }
Function SMTP_STARTTLS: Integer;
Var
 Response: TSMTPResponse;
Begin
 If SMTPClient.State < ssConnected Then Begin
  SMTPClient.LastError := 'Non connecte';
  SMTP_STARTTLS := SMTP_ERR_STARTTLS;
  Exit;
 End;

 If Not SMTPClient.Extensions.STARTTLS Then Begin
  SMTPClient.LastError := 'STARTTLS non supporte par le serveur';
  SMTP_STARTTLS := SMTP_ERR_STARTTLS;
  Exit;
 End;

 If SMTPClient.TLSActive Then Begin
  SMTPClient.LastError := 'TLS deja actif';
  SMTP_STARTTLS := SMTP_OK;
  Exit;
 End;

 Response := SMTP_SendCommand('STARTTLS');
 If Response.Code = SMTP_CODE_READY Then Begin
  If MailStartTLS(SMTPWire) Then Begin
   SMTPClient.TLSActive := True;
   FillChar(SMTPClient.Extensions,SizeOf(SMTPClient.Extensions),0);
   SMTP_STARTTLS := SMTP_EHLO('localhost');
  End Else Begin
   SMTPClient.LastError := MailError; MailClose(SMTPWire);
   SMTP_STARTTLS := SMTP_ERR_STARTTLS;
  End;
 End
 Else Begin
  SMTPClient.LastError := 'STARTTLS echoue: ' + Response.Text;
  SMTP_STARTTLS := SMTP_ERR_STARTTLS;
 End;
End;

{ Authentification PLAIN (RFC 4616) }
Function SMTP_AuthPLAIN: Integer;
Var
 Response: TSMTPResponse;
 AuthString: String;
 EncodedAuth: String;
Begin
 If SMTPClient.State < ssConnected Then Begin
  SMTPClient.LastError := 'Non connecte';
  SMTP_AuthPLAIN := SMTP_ERR_AUTH;
  Exit;
 End;

 If Not SMTPClient.Extensions.AUTH_PLAIN Then Begin
  SMTPClient.LastError := 'AUTH PLAIN non supporte';
  SMTP_AuthPLAIN := SMTP_ERR_AUTH;
  Exit;
 End;

 { Construire la chaine d'authentification: \0username\0password }
 AuthString := Chr(0) + SMTPClient.Username + Chr(0) + SMTPClient.Password;
 EncodedAuth := SMTP_Base64Encode(AuthString);

 Response := SMTP_SendCommand('AUTH PLAIN ' + EncodedAuth);
 If Response.Code = SMTP_CODE_AUTH_OK Then Begin
  SMTPClient.Authenticated := True;
  SMTPClient.AuthMethod := samPLAIN;
  SMTPClient.State := ssAuthenticated;
  SMTP_AuthPLAIN := SMTP_OK;
 End
 Else Begin
  SMTPClient.LastError := 'AUTH PLAIN echoue: ' + Response.Text;
  SMTP_AuthPLAIN := SMTP_ERR_AUTH;
 End;
End;

{ Authentification LOGIN }
Function SMTP_AuthLOGIN: Integer;
Var
 Response: TSMTPResponse;
Begin
 If SMTPClient.State < ssConnected Then Begin
  SMTPClient.LastError := 'Non connecte';
  SMTP_AuthLOGIN := SMTP_ERR_AUTH;
  Exit;
 End;

 If Not SMTPClient.Extensions.AUTH_LOGIN Then Begin
  SMTPClient.LastError := 'AUTH LOGIN non supporte';
  SMTP_AuthLOGIN := SMTP_ERR_AUTH;
  Exit;
 End;

 { Envoyer AUTH LOGIN }
 Response := SMTP_SendCommand('AUTH LOGIN');
 If Response.Code <> SMTP_CODE_AUTH_CONTINUE Then Begin
  SMTPClient.LastError := 'AUTH LOGIN echoue: ' + Response.Text;
  SMTP_AuthLOGIN := SMTP_ERR_AUTH;
  Exit;
 End;

 { Envoyer le nom d'utilisateur en Base64 }
 Response := SMTP_SendCommand(SMTP_Base64Encode(SMTPClient.Username));
 If Response.Code <> SMTP_CODE_AUTH_CONTINUE Then Begin
  SMTPClient.LastError := 'Username echoue: ' + Response.Text;
  SMTP_AuthLOGIN := SMTP_ERR_AUTH;
  Exit;
 End;

 { Envoyer le mot de passe en Base64 }
 Response := SMTP_SendCommand(SMTP_Base64Encode(SMTPClient.Password));
 If Response.Code = SMTP_CODE_AUTH_OK Then Begin
  SMTPClient.Authenticated := True;
  SMTPClient.AuthMethod := samLOGIN;
  SMTPClient.State := ssAuthenticated;
  SMTP_AuthLOGIN := SMTP_OK;
 End
 Else Begin
  SMTPClient.LastError := 'Password echoue: ' + Response.Text;
  SMTP_AuthLOGIN := SMTP_ERR_AUTH;
 End;
End;

{ Authentification CRAM-MD5 (RFC 2195) }
Function SMTP_AuthCRAMMD5: Integer;
Begin
 SMTPClient.LastError:='CRAM-MD5 non pris en charge; utiliser LOGIN/PLAIN';
 SMTP_AuthCRAMMD5:=SMTP_ERR_AUTH;
End;

{ Envoie la commande MAIL FROM }
Function SMTP_MailFrom(SenderEmail: String): Integer;
Var
 Response: TSMTPResponse;
Begin
 If SMTPClient.State < ssConnected Then Begin
  SMTPClient.LastError := 'Non connecte';
  SMTP_MailFrom := SMTP_ERR_MAIL_FROM;
  Exit;
 End;

 Response := SMTP_SendCommand('MAIL FROM:<' + SenderEmail + '>');
 If Response.Code = SMTP_CODE_OK Then Begin
  SMTPClient.MailFrom := SenderEmail;
  SMTPClient.State := ssMailFrom;
  SMTPClient.RcptCount := 0;
  SMTPClient.RcptAccepted := 0;
  SMTP_MailFrom := SMTP_OK;
 End
 Else Begin
  SMTPClient.LastError := 'MAIL FROM echoue: ' + Response.Text;
  SMTP_MailFrom := SMTP_ERR_MAIL_FROM;
 End;
End;

{ Envoie la commande RCPT TO }
Function SMTP_RcptTo(RecipientEmail: String): Integer;
Var
 Response: TSMTPResponse;
Begin
 If SMTPClient.State < ssMailFrom Then Begin
  SMTPClient.LastError := 'MAIL FROM requis d''abord';
  SMTP_RcptTo := SMTP_ERR_RCPT_TO;
  Exit;
 End;

 Response := SMTP_SendCommand('RCPT TO:<' + RecipientEmail + '>');
 If (Response.Code = SMTP_CODE_OK) Or (Response.Code = SMTP_CODE_USER_NOT_LOCAL) Then Begin
  If SMTPClient.RcptCount < SMTP_MAX_RECIPIENTS Then Begin
   SMTPRecipients[SMTPClient.RcptCount].Email := RecipientEmail;
   SMTPRecipients[SMTPClient.RcptCount].Accepted := True;
   SMTPRecipients[SMTPClient.RcptCount].ErrorMsg := '';
   Inc(SMTPClient.RcptCount);
  End;
  Inc(SMTPClient.RcptAccepted);
  SMTPClient.State := ssRcptTo;
  SMTP_RcptTo := SMTP_OK;
 End
 Else Begin
  { Destinataire refuse mais on peut continuer }
  If SMTPClient.RcptCount < SMTP_MAX_RECIPIENTS Then Begin
   SMTPRecipients[SMTPClient.RcptCount].Email := RecipientEmail;
   SMTPRecipients[SMTPClient.RcptCount].Accepted := False;
   SMTPRecipients[SMTPClient.RcptCount].ErrorMsg := Response.Text;
   Inc(SMTPClient.RcptCount);
  End;
  SMTP_RcptTo := SMTP_ERR_RCPT_TO;
 End;
End;

{ Envoie la commande DATA et le contenu du message }
Function SMTP_Data(MessageBody: TMailText): Integer;
Var
 Response: TSMTPResponse;
 WireBody: TMailText;
 I: LongInt;
Begin
 If SMTPClient.State < ssRcptTo Then Begin
  SMTPClient.LastError := 'RCPT TO requis d''abord';
  SMTP_Data := SMTP_ERR_DATA;
  Exit;
 End;

 If SMTPClient.RcptAccepted = 0 Then Begin
  SMTPClient.LastError := 'Aucun destinataire accepte';
  SMTP_Data := SMTP_ERR_NO_RECIPIENTS;
  Exit;
 End;

 { Envoyer DATA }
 Response := SMTP_SendCommand('DATA');
 If Response.Code <> SMTP_CODE_START_MAIL Then Begin
  SMTPClient.LastError := 'DATA echoue: ' + Response.Text;
  SMTP_Data := SMTP_ERR_DATA;
  Exit;
 End;

 SMTPClient.State := ssData;

 WireBody:='';
 For I:=1 To Length(MessageBody) Do Begin
  If (MessageBody[I]='.') Then
   If (I=1) Or (MessageBody[I-1]=#10) Then WireBody:=WireBody+'.';
  WireBody:=WireBody+MessageBody[I];
 End;
 If Copy(WireBody,Length(WireBody)-1,2)<>#13#10 Then WireBody:=WireBody+#13#10;
 If Not MailWrite(SMTPWire, WireBody + '.'#13#10) Then Begin
  SMTPClient.LastError:=MailError; SMTP_Data:=SMTP_ERR_SEND; Exit;
 End;
 Response:=SMTP_SendCommand('');

 If Response.Code = SMTP_CODE_OK Then Begin
  SMTPClient.State := ssAuthenticated;
  SMTP_Data := SMTP_OK;
 End
 Else Begin
  SMTPClient.LastError := 'Envoi echoue: ' + Response.Text;
  SMTP_Data := SMTP_ERR_SEND;
 End;
End;

{ Envoie la commande RSET pour reinitialiser la transaction }
Function SMTP_Rset: Integer;
Var
 Response: TSMTPResponse;
Begin
 If SMTPClient.State < ssConnected Then Begin
  SMTPClient.LastError := 'Non connecte';
  SMTP_Rset := SMTP_ERR_PROTOCOL;
  Exit;
 End;

 Response := SMTP_SendCommand('RSET');
 If Response.Code = SMTP_CODE_OK Then Begin
  SMTPClient.State := ssAuthenticated;
  SMTPClient.MailFrom := '';
  SMTPClient.RcptCount := 0;
  SMTPClient.RcptAccepted := 0;
  SMTP_Rset := SMTP_OK;
 End
 Else Begin
  SMTPClient.LastError := 'RSET echoue: ' + Response.Text;
  SMTP_Rset := SMTP_ERR_PROTOCOL;
 End;
End;

{ Envoie la commande NOOP }
Function SMTP_Noop: Integer;
Var
 Response: TSMTPResponse;
Begin
 If SMTPClient.State < ssConnected Then Begin
  SMTPClient.LastError := 'Non connecte';
  SMTP_Noop := SMTP_ERR_PROTOCOL;
  Exit;
 End;

 Response := SMTP_SendCommand('NOOP');
 If Response.Code = SMTP_CODE_OK Then
  SMTP_Noop := SMTP_OK
 Else Begin
  SMTPClient.LastError := 'NOOP echoue: ' + Response.Text;
  SMTP_Noop := SMTP_ERR_PROTOCOL;
 End;
End;

{ Envoie la commande QUIT et deconnecte }
Function SMTP_Quit: Integer;
Var
 Response: TSMTPResponse;
Begin
 If SMTPClient.State = ssDisconnected Then Begin
  SMTP_Quit := SMTP_OK;
  Exit;
 End;

 If SMTPClient.Connected Then Begin
  Response := SMTP_SendCommand('QUIT');
  { Ignorer la reponse, on deconnecte quand meme }
 End;

 MailClose(SMTPWire);
 SMTPClient.Connected := False;
 SMTPClient.State := ssDisconnected;
 SMTPClient.SocketHandle := -1;
 SMTPClient.TLSActive := False;
 SMTPClient.Authenticated := False;
 SMTP_Quit := SMTP_OK;
End;

{ Envoie un message complet }
Function SMTP_SendMessage(Msg: TSMTPMessage): Integer;
Var
 I: Integer;
 Result: Integer;
 Headers: TMailText;
Begin
 { Verifier qu'on est connecte et authentifie }
 If SMTPClient.State < ssConnected Then Begin
  SMTPClient.LastError := 'Non connecte';
  SMTP_SendMessage := SMTP_ERR_CONNECT;
  Exit;
 End;

 { MAIL FROM }
 Result := SMTP_MailFrom(Msg.From);
 If Result <> SMTP_OK Then Begin
  SMTP_SendMessage := Result;
  Exit;
 End;

 { RCPT TO pour chaque destinataire }
 For I := 0 To Msg.RecipientCount - 1 Do Begin
  Result := SMTP_RcptTo(Msg.Recipients[I].Email);
  { Continuer meme si un destinataire est refuse }
 End;

 { Verifier qu'au moins un destinataire a ete accepte }
 If SMTPClient.RcptAccepted = 0 Then Begin
  SMTPClient.LastError := 'Tous les destinataires refuses';
  SMTP_Rset;
  SMTP_SendMessage := SMTP_ERR_NO_RECIPIENTS;
  Exit;
 End;

 { Construire les en-tetes et le corps }
 Headers := 'From: ';
 If Msg.FromName <> '' Then
  Headers := Headers + '"' + Msg.FromName + '" <' + Msg.From + '>'
 Else
  Headers := Headers + Msg.From;
 Headers := Headers + Chr(13) + Chr(10);
 Headers := Headers + 'To: ' + Msg.Recipients[0].Email + Chr(13) + Chr(10);
 Headers := Headers + 'Subject: ' + Msg.Subject + Chr(13) + Chr(10);
 Headers := Headers + 'Content-Type: ' + Msg.ContentType;
 If Msg.CharSet <> '' Then
  Headers := Headers + '; charset="' + Msg.CharSet + '"';
 Headers := Headers + Chr(13) + Chr(10);
 Headers := Headers + Chr(13) + Chr(10);
 Headers := Headers + Msg.Body;

 { DATA }
 Result := SMTP_Data(Headers);
 SMTP_SendMessage := Result;
End;

{ Retourne l'etat du client SMTP sous forme de chaine }
Function SMTP_GetStateString: String;
Begin
 Case SMTPClient.State Of
  ssDisconnected: SMTP_GetStateString := 'Deconnecte';
  ssConnected: SMTP_GetStateString := 'Connecte';
  ssAuthenticated: SMTP_GetStateString := 'Authentifie';
  ssMailFrom: SMTP_GetStateString := 'MAIL FROM envoye';
  ssRcptTo: SMTP_GetStateString := 'RCPT TO envoye';
  ssData: SMTP_GetStateString := 'DATA en cours';
  ssQuit: SMTP_GetStateString := 'Deconnexion';
 Else
  SMTP_GetStateString := 'Inconnu';
 End;
End;

{ Retourne les extensions supportees par le serveur }
Function SMTP_GetExtensionsString: String;
Var
 S: String;
Begin
 S := '';
 If SMTPClient.Extensions.STARTTLS Then S := S + 'STARTTLS ';
 If SMTPClient.Extensions.AUTH_PLAIN Then S := S + 'AUTH-PLAIN ';
 If SMTPClient.Extensions.AUTH_LOGIN Then S := S + 'AUTH-LOGIN ';
 If SMTPClient.Extensions.AUTH_CRAM_MD5 Then S := S + 'AUTH-CRAM-MD5 ';
 If SMTPClient.Extensions.EIGHTBITMIME Then S := S + '8BITMIME ';
 If SMTPClient.Extensions.PIPELINING Then S := S + 'PIPELINING ';
 If SMTPClient.Extensions.DSN Then S := S + 'DSN ';
 If S = '' Then S := 'Aucune';
 SMTP_GetExtensionsString := S;
End;

{ Verifie si STARTTLS est disponible }
Function SMTP_IsSTARTTLSAvailable: Boolean;
Begin
 SMTP_IsSTARTTLSAvailable := SMTPClient.Extensions.STARTTLS And Not SMTPClient.TLSActive;
End;

{ Verifie si une methode d'authentification est disponible }
Function SMTP_IsAuthAvailable(Method: TSMTPAuthMethod): Boolean;
Begin
 Case Method Of
  samPLAIN: SMTP_IsAuthAvailable := SMTPClient.Extensions.AUTH_PLAIN;
  samLOGIN: SMTP_IsAuthAvailable := SMTPClient.Extensions.AUTH_LOGIN;
  samCRAMMD5: SMTP_IsAuthAvailable := SMTPClient.Extensions.AUTH_CRAM_MD5;
 Else
  SMTP_IsAuthAvailable := True; { samNone }
 End;
End;

{ Retourne le nombre de destinataires acceptes }
Function SMTP_GetAcceptedCount: Integer;
Begin
 SMTP_GetAcceptedCount := SMTPClient.RcptAccepted;
End;

{ Retourne le nombre de destinataires refuses }
Function SMTP_GetRejectedCount: Integer;
Begin
 SMTP_GetRejectedCount := SMTPClient.RcptCount - SMTPClient.RcptAccepted;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION SMTP
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU GESTIONNAIRE DE COMPTES (TODO 11)
  ============================================================================ }

{ Chiffre/dechiffre un mot de passe avec XOR }
Function XORPassword(Password: String): String;
Var
 I: Integer;
 Result: String;
Begin
 Result := '';
 For I := 1 To Length(Password) Do
  Result := Result + Chr(Ord(Password[I]) Xor PASSWORD_XOR_KEY);
 XORPassword := Result;
End;

{ Ouvrir et authentifier le serveur entrant du compte reel. }
Function OpenIncomingAccount(Const Account: TEmailAccount): Boolean;
Var R: TIMAPResponse; P: TPOP3Response;
Begin
 OpenIncomingAccount:=False; MailError:='';
 If Account.IncomingType=istIMAP Then Begin
  IMAP_InitClient;
  IMAP_Configure(Account.IncomingHost,Account.IncomingPort,
   Account.IncomingUsername,XORPassword(Account.IncomingPassword),Account.IncomingSecurity=csSSL);
  If IMAP_Connect<>IMAP_OK Then Begin MailError:=IMAPClient.LastError; Exit; End;
  If Account.IncomingSecurity=csSTARTTLS Then Begin
   R:=IMAP_SendCommand('STARTTLS');
   If R.ResponseType<>irOK Then Begin MailError:='IMAP STARTTLS refuse: '+R.Text; MailClose(IMAPWire); Exit; End;
   If Not MailStartTLS(IMAPWire) Then Begin MailClose(IMAPWire); Exit; End;
  End;
  BusyStage('Authentification IMAP...');
  If IMAPClient.State<>isAuthenticated Then
   If IMAP_LoginAuth<>IMAP_OK Then Begin MailError:=IMAPClient.LastError; MailClose(IMAPWire); Exit; End;
 End Else Begin
  POP3_InitClient;
  POP3_Configure(Account.IncomingHost,Account.IncomingPort,
   Account.IncomingUsername,XORPassword(Account.IncomingPassword),Account.IncomingSecurity=csSSL);
  If POP3_Connect<>POP3_OK Then Begin MailError:=POP3Client.LastError; Exit; End;
  If Account.IncomingSecurity=csSTARTTLS Then Begin
   P:=POP3_SendCommand('STLS');
   If P.ResponseType<>prOK Then Begin MailError:='POP3 STLS refuse: '+P.Text; MailClose(POP3Wire); Exit; End;
   If Not MailStartTLS(POP3Wire) Then Begin MailClose(POP3Wire); Exit; End;
  End;
  BusyStage('Authentification POP3...');
  If POP3_AuthUserPass<>POP3_OK Then Begin MailError:=POP3Client.LastError; MailClose(POP3Wire); Exit; End;
 End;
 OpenIncomingAccount:=True;
End;

Function OpenOutgoingAccount(Const Account: TEmailAccount): Boolean;
Var User, Pass: String; ResultCode: Integer;
Begin
 OpenOutgoingAccount:=False; MailError:=''; SMTP_InitClient;
 User:=Account.OutgoingUsername; Pass:=XORPassword(Account.OutgoingPassword);
 If Account.OutgoingUseSameAuth Then Begin
  User:=Account.IncomingUsername; Pass:=XORPassword(Account.IncomingPassword);
 End;
 SMTP_Configure(Account.OutgoingHost,Account.OutgoingPort,User,Pass,
  Account.OutgoingSecurity=csSSL,Account.OutgoingSecurity=csSTARTTLS);
 ResultCode:=SMTP_Connect;
 If ResultCode=SMTP_OK Then ResultCode:=SMTP_EHLO('localhost');
 If (ResultCode=SMTP_OK) And (Account.OutgoingSecurity=csSTARTTLS) Then ResultCode:=SMTP_STARTTLS;
 If (ResultCode=SMTP_OK) And Account.OutgoingAuthRequired Then Begin
  BusyStage('Authentification SMTP...');
  If SMTPClient.Extensions.AUTH_PLAIN Then ResultCode:=SMTP_AuthPLAIN
  Else ResultCode:=SMTP_AuthLOGIN;
 End;
 If ResultCode<>SMTP_OK Then Begin MailError:=SMTPClient.LastError; MailClose(SMTPWire); Exit; End;
 OpenOutgoingAccount:=True;
End;

{ Sans option, le fichier des comptes suit le repertoire de l executable. }
Function AccountFileName: String;
Var
 S: String;
 I: Integer;
Begin
 If CommandLineAccountsFile <> '' Then Begin
  AccountFileName := CommandLineAccountsFile;
  Exit;
 End;
 S := ParamStr(0);
 I := Length(S);
 While (I > 0) And (S[I] <> '\') And (S[I] <> '/') And
       (S[I] <> ':') Do Dec(I);
 AccountFileName := Copy(S, 1, I) + 'OUTLINK.ACC';
End;

{ Format versionne: signature, taille d un compte, nombre, comptes complets.
  Les mots de passe conservent le codage XOR utilise par l assistant. }
Procedure SaveAccounts;
Var
 F: File;
 Name, TempName, BackupName: String;
 Header: Array[0..2] of LongInt;
 Written: LongInt;
 Err: Integer;
Begin
 AccountStorageError := '';
 Name := AccountFileName;
 TempName := Name + '.TMP';
 BackupName := Name + '.BAK';
 Header[0] := $4F414301;
 Header[1] := SizeOf(TEmailAccount);
 Header[2] := EmailAccountCount;
 {$I-}
 Assign(F, TempName);
 Rewrite(F, 1);
 Err := IOResult;
 If Err = 0 Then Begin
  BlockWrite(F, Header, SizeOf(Header), Written);
  Err := IOResult;
  If Written <> SizeOf(Header) Then Err := 101;
  If Err = 0 Then Begin
   BlockWrite(F, EmailAccounts, EmailAccountCount * SizeOf(TEmailAccount), Written);
   Err := IOResult;
   If Written <> EmailAccountCount * SizeOf(TEmailAccount) Then Err := 101;
  End;
  Close(F);
  If IOResult <> 0 Then Err := 101;
 End;
 If Err = 0 Then Begin
  Assign(F, BackupName);
  Erase(F);
  If IOResult <> 0 Then Begin End;
  Assign(F, Name);
  Rename(F, BackupName);
  Err := IOResult;
  { Un fichier absent est normal lors du premier enregistrement. }
  If Err = 2 Then Err := 0;
  If Err = 0 Then Begin
   Assign(F, TempName);
   Rename(F, Name);
   Err := IOResult;
   If Err <> 0 Then Begin
    Assign(F, BackupName);
    Rename(F, Name);
    If IOResult <> 0 Then Begin End;
   End;
  End;
 End;
 {$I+}
 If Err <> 0 Then
  AccountStorageError := 'Erreur: impossible de sauvegarder le fichier des comptes';
End;

Procedure LoadAccounts;
Var
 F: File;
 Header: Array[0..2] of LongInt;
 Loaded: Array[0..MAX_EMAIL_ACCOUNTS-1] of TEmailAccount;
 ReadCount, ExpectedSize: LongInt;
 Err: Integer;
Begin
 AccountStorageError := '';
 FillChar(Loaded, SizeOf(Loaded), 0);
 FillChar(Header, SizeOf(Header), 0);
 {$I-}
 Assign(F, AccountFileName);
 Reset(F, 1);
 Err := IOResult;
 If Err = 2 Then Begin
  { Recuperer la derniere sauvegarde si une ecriture a ete interrompue. }
  Assign(F, AccountFileName + '.BAK');
  Reset(F, 1);
  Err := IOResult;
  If Err = 2 Then Exit;
 End;
 If Err = 0 Then Begin
  BlockRead(F, Header, SizeOf(Header), ReadCount);
  Err := IOResult;
  If (ReadCount <> SizeOf(Header)) Or (Header[0] <> $4F414301) Or
     (Header[1] <> SizeOf(TEmailAccount)) Or (Header[2] < 0) Or
     (Header[2] > MAX_EMAIL_ACCOUNTS) Then Err := 100;
  If Err = 0 Then Begin
   ExpectedSize := Header[2] * SizeOf(TEmailAccount);
   If FileSize(F) <> SizeOf(Header) + ExpectedSize Then Err := 100;
   If IOResult <> 0 Then Err := 100;
   If Err = 0 Then Begin
    BlockRead(F, Loaded, ExpectedSize, ReadCount);
    Err := IOResult;
    If ReadCount <> ExpectedSize Then Err := 100;
   End;
  End;
  Close(F);
  If IOResult <> 0 Then Err := 100;
 End;
 {$I+}
 If Err = 0 Then Begin
  Move(Loaded, EmailAccounts, SizeOf(EmailAccounts));
  EmailAccountCount := Header[2];
 End
 Else AccountStorageError := 'Erreur: impossible de charger le fichier des comptes';
End;

{ Initialise le gestionnaire de comptes }
Procedure InitializeAccountManager;
Var
 I: Integer;
Begin
 EmailAccountCount := 0;
 CurrentAccountIndex := -1;
 AccountDialogVisible := False;
 AccountWizardStep := awsWelcome;
 AccountWizardMode := False;
 AccountListScrollOffset := 0;
 SelectedAccountInList := -1;
 FocusedInputField := -1;
 ConnectionTestInProgress := False;
 ConnectionTestResult := ctrNotTested;

 { Initialiser tous les comptes a zero }
 For I := 0 To MAX_EMAIL_ACCOUNTS - 1 Do Begin
  EmailAccounts[I].AccountName := '';
  EmailAccounts[I].EmailAddress := '';
  EmailAccounts[I].IsActive := False;
 End;

 LoadAccounts;
End;

{ Initialise un compte vide }
Procedure InitializeEmptyAccount(Var Account: TEmailAccount);
Begin
 Account.AccountName := '';
 Account.DisplayName := '';
 Account.EmailAddress := '';
 Account.Organization := '';
 Account.ReplyToAddress := '';
 Account.IncomingType := istIMAP;
 Account.IncomingHost := '';
 Account.IncomingPort := DEFAULT_IMAPS_PORT;
 Account.IncomingSecurity := csSSL;
 Account.IncomingUsername := '';
 Account.IncomingPassword := '';
 Account.IncomingAuthMethod := 0;
 Account.POP3LeaveOnServer := True;
 Account.POP3DeleteAfterDays := 0;
 Account.POP3HeadersOnly := False;
 Account.OutgoingHost := '';
 Account.OutgoingPort := DEFAULT_SMTP_SUBMISSION_PORT;
 Account.OutgoingSecurity := csSTARTTLS;
 Account.OutgoingUsername := '';
 Account.OutgoingPassword := '';
 Account.OutgoingAuthRequired := True;
 Account.OutgoingUseSameAuth := True;
 Account.IsActive := True;
 Account.IsDefault := False;
 Account.LastConnectionTest := ctrNotTested;
 Account.CheckIntervalMins := 5;
End;

{ Dessine une boite de dialogue modale }
Procedure DrawDialogBox(X, Y, W, H: Integer; Title: String);
Begin
 { Ombre de la boite de dialogue }
 GSetFillStyle(SolidFill, COLOR_BUTTON_DARK);
 GBar(X + 3, Y + 3, X + W + 3, Y + H + 3);

 { Fond de la boite de dialogue }
 GSetFillStyle(SolidFill, COLOR_WINDOW_BG);
 GBar(X, Y, X + W, Y + H);

 { Barre de titre }
 GSetFillStyle(SolidFill, COLOR_TITLEBAR);
 GBar(X + 2, Y + 2, X + W - 2, Y + 20);

 { Titre }
 GSetColor(COLOR_TITLEBAR_TEXT);
 GOutTextXY(X + 8, Y + 6, Title);

 { Bordure 3D }
 Draw3DRect(X, Y, X + W, Y + H, True);
 Draw3DRect(X + 2, Y + 22, X + W - 2, Y + H - 2, False);
End;

{ Dessine un bouton de dialogue }
Procedure DrawDialogButton(X, Y, W, H: Integer; Caption: String; Pressed, Enabled: Boolean);
Var
 TextX, TextY: Integer;
Begin
 { Fond du bouton }
 If Enabled Then
  GSetFillStyle(SolidFill, COLOR_BUTTON_FACE)
 Else
  GSetFillStyle(SolidFill, COLOR_BUTTON_DARK);
 GBar(X, Y, X + W, Y + H);

 { Relief 3D }
 Draw3DRect(X, Y, X + W, Y + H, Not Pressed);

 { Texte centre }
 If Enabled Then
  GSetColor(COLOR_MENU_TEXT)
 Else
  GSetColor(COLOR_BUTTON_DARK);
 TextX := X + (W - GTextWidth(Caption)) Div 2;
 TextY := Y + (H - GTextHeight(Caption)) Div 2;
 If Pressed Then Begin
  Inc(TextX);
  Inc(TextY);
 End;
 GOutTextXY(TextX, TextY, Caption);
End;

{ Boite d activite, avec progression reelle quand le total est connu. }
Procedure DrawBusyDialog;
Var X,Y,Width,Offset,Filled: Integer; Text,TotalText: String; Elapsed: LongInt;
Begin
 If Not BusyVisible Or Not BusyGraphicsReady Then Exit;
 X:=(SCREEN_WIDTH-440) Div 2; Y:=(SCREEN_HEIGHT-190) Div 2;
 HideMouse; GSetViewPort(0,0,SCREEN_WIDTH-1,SCREEN_HEIGHT-1,True);
 DrawDialogBox(X,Y,440,190,BusyTitle);
 GSetColor(Black); GOutTextXY(X+18,Y+40,Copy(BusyStageText,1,50));
 GOutTextXY(X+18,Y+62,Copy(BusyDetail,1,50));
 Width:=400;
 FillRect(X+18,Y+90,X+18+Width,Y+110,White);
 Draw3DRect(X+18,Y+90,X+18+Width,Y+110,False);
 If BusyTotal>0 Then Begin
  Filled:=(BusyDone*LongInt(Width-4)) Div BusyTotal;
  If Filled>0 Then FillRect(X+20,Y+92,X+19+Filled,Y+108,Blue);
  Str(BusyDone,Text); Str(BusyTotal,TotalText); GSetColor(Black);
  GOutTextXY(X+18,Y+124,Text+' / '+TotalText+' messages');
 End Else Begin
  Offset:=(BusyFrame Mod 24)*(Width-64) Div 23;
  FillRect(X+20+Offset,Y+92,X+78+Offset,Y+108,Blue); GSetColor(Black);
  GOutTextXY(X+18,Y+124,'En cours...');
 End;
 Elapsed:=(LongWord(GetTickCount)-LongWord(BusyStarted)) And $7FFFFFFF;
 Str(Elapsed Div 1000,Text); GSetColor(Black); GOutTextXY(X+18,Y+146,'Duree : '+Text+' s');
 Case BusyFrame Mod 4 Of 0: Text:='|'; 1: Text:='/'; 2: Text:='-'; 3: Text:=Chr(92); End;
 GOutTextXY(X+18,Y+168,'Veuillez patienter... '+Text); ShowMouse;
End;

Procedure BusyPulse(Force: Boolean);
Var Tick,Elapsed: LongInt;
Begin
 If Not BusyVisible Or Not BusyGraphicsReady Then Exit;
 Tick:=GetTickCount; Elapsed:=(LongWord(Tick)-LongWord(BusyLastPaint)) And $7FFFFFFF;
 If Not Force And (Elapsed<1000) Then Exit;
 BusyLastPaint:=Tick; Inc(BusyFrame); DrawBusyDialog;
 { Laisser le pilote graphique presenter l image, sans executer de commande utilisateur. }
 PmDelay(1);
End;

Procedure BusyBegin(Title,Detail: String);
Begin
 BusyTitle:=Title; BusyDetail:=Detail; BusyStageText:='Preparation...';
 BusyDone:=0; BusyTotal:=0; BusyFrame:=0; BusyStarted:=GetTickCount; BusyLastPaint:=BusyStarted;
 BusyVisible:=True; BusyPulse(True);
End;

Procedure BusyUpdate(Stage: String; Done,Total: LongInt);
Begin
 If Not BusyVisible Then Exit;
 BusyStageText:=Stage; BusyDone:=Done; BusyTotal:=Total;
 If BusyTotal<0 Then BusyTotal:=0;
 If BusyDone<0 Then BusyDone:=0;
 If (BusyTotal>0) And (BusyDone>BusyTotal) Then BusyDone:=BusyTotal;
 BusyPulse(True);
End;

Procedure BusyStage(Stage: String);
Begin If BusyVisible Then BusyUpdate(Stage,BusyDone,BusyTotal); End;

Procedure BusyEnd;
Begin
 If Not BusyVisible Then Exit;
 BusyVisible:=False;
 If BusyGraphicsReady Then DrawInterface;
End;

{ Dessine un champ de saisie }
Procedure DrawInputField(Var Field: TInputField);
Var
 DisplayText: String;
 I: Integer;
Begin
 { Etiquette }
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(Field.X, Field.Y - 14, Field.Label_);

 { Fond du champ }
 If Field.IsFocused Then
  GSetFillStyle(SolidFill, COLOR_LIST_BG)
 Else
  GSetFillStyle(SolidFill, COLOR_WINDOW_BG);
 GBar(Field.X, Field.Y, Field.X + Field.Width, Field.Y + DIALOG_INPUT_HEIGHT);

 { Bordure 3D inversee }
 Draw3DRect(Field.X, Field.Y, Field.X + Field.Width, Field.Y + DIALOG_INPUT_HEIGHT, False);

 { Texte ou asterisques }
 If Field.IsPassword Then Begin
  DisplayText := '';
  For I := 1 To Length(Field.Value) Do
   DisplayText := DisplayText + '*';
 End
 Else
  DisplayText := Field.Value;

 { Tronquer si trop long }
 While GTextWidth(DisplayText) > Field.Width - 8 Do
  Delete(DisplayText, 1, 1);

 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(Field.X + 4, Field.Y + 4, DisplayText);

 { Curseur si actif }
 If Field.IsFocused Then Begin
  GSetColor(COLOR_MENU_TEXT);
  GLine(Field.X + 4 + GTextWidth(DisplayText), Field.Y + 3,
       Field.X + 4 + GTextWidth(DisplayText), Field.Y + DIALOG_INPUT_HEIGHT - 3);
 End;
End;

{ Dessine un bouton radio }
Procedure DrawRadioButton(Var Radio: TRadioButton);
Begin
 { Cercle exterieur }
 GSetColor(COLOR_BUTTON_DARK);
 GCircle(Radio.X + 6, Radio.Y + 6, 6);

 { Cercle interieur si selectionne }
 If Radio.Checked Then Begin
  GSetFillStyle(SolidFill, COLOR_MENU_TEXT);
  GFillEllipse(Radio.X + 6, Radio.Y + 6, 3, 3);
 End
 Else Begin
  GSetFillStyle(SolidFill, COLOR_LIST_BG);
  GFillEllipse(Radio.X + 6, Radio.Y + 6, 4, 4);
 End;

 { Etiquette }
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(Radio.X + 16, Radio.Y + 2, Radio.Label_);
End;

{ Dessine une case a cocher }
Procedure DrawCheckBox(Var Check: TCheckBox);
Begin
 { Cadre }
 GSetFillStyle(SolidFill, COLOR_LIST_BG);
 GBar(Check.X, Check.Y, Check.X + 12, Check.Y + 12);
 Draw3DRect(Check.X, Check.Y, Check.X + 12, Check.Y + 12, False);

 { Coche si selectionnee }
 If Check.Checked Then Begin
  GSetColor(COLOR_MENU_TEXT);
  GLine(Check.X + 2, Check.Y + 6, Check.X + 5, Check.Y + 9);
  GLine(Check.X + 5, Check.Y + 9, Check.X + 10, Check.Y + 3);
  GLine(Check.X + 3, Check.Y + 6, Check.X + 5, Check.Y + 10);
  GLine(Check.X + 5, Check.Y + 10, Check.X + 10, Check.Y + 4);
 End;

 { Etiquette }
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(Check.X + 18, Check.Y + 2, Check.Label_);
End;

{ Initialise les champs pour la page d'information du compte }
Procedure InitAccountInfoFields;
Var
 BaseX, BaseY: Integer;
Begin
 BaseX := DIALOG_X + DIALOG_MARGIN + 20;
 BaseY := DIALOG_Y + 50;

 { Nom du compte }
 AccountDialogInputFields[0].X := BaseX;
 AccountDialogInputFields[0].Y := BaseY;
 AccountDialogInputFields[0].Width := 250;
 AccountDialogInputFields[0].MaxLen := 40;
 AccountDialogInputFields[0].Value := TempAccount.AccountName;
 AccountDialogInputFields[0].IsPassword := False;
 AccountDialogInputFields[0].IsFocused := True;
 AccountDialogInputFields[0].CursorPos := Length(TempAccount.AccountName);
 AccountDialogInputFields[0].Label_ := 'Nom du compte:';

 { Nom d'affichage }
 BaseY := BaseY + 45;
 AccountDialogInputFields[1].X := BaseX;
 AccountDialogInputFields[1].Y := BaseY;
 AccountDialogInputFields[1].Width := 250;
 AccountDialogInputFields[1].MaxLen := 40;
 AccountDialogInputFields[1].Value := TempAccount.DisplayName;
 AccountDialogInputFields[1].IsPassword := False;
 AccountDialogInputFields[1].IsFocused := False;
 AccountDialogInputFields[1].CursorPos := Length(TempAccount.DisplayName);
 AccountDialogInputFields[1].Label_ := 'Votre nom:';

 { Adresse email }
 BaseY := BaseY + 45;
 AccountDialogInputFields[2].X := BaseX;
 AccountDialogInputFields[2].Y := BaseY;
 AccountDialogInputFields[2].Width := 300;
 AccountDialogInputFields[2].MaxLen := 60;
 AccountDialogInputFields[2].Value := TempAccount.EmailAddress;
 AccountDialogInputFields[2].IsPassword := False;
 AccountDialogInputFields[2].IsFocused := False;
 AccountDialogInputFields[2].CursorPos := Length(TempAccount.EmailAddress);
 AccountDialogInputFields[2].Label_ := 'Adresse de courrier electronique:';

 { Organisation (optionnel) }
 BaseY := BaseY + 45;
 AccountDialogInputFields[3].X := BaseX;
 AccountDialogInputFields[3].Y := BaseY;
 AccountDialogInputFields[3].Width := 250;
 AccountDialogInputFields[3].MaxLen := 40;
 AccountDialogInputFields[3].Value := TempAccount.Organization;
 AccountDialogInputFields[3].IsPassword := False;
 AccountDialogInputFields[3].IsFocused := False;
 AccountDialogInputFields[3].CursorPos := Length(TempAccount.Organization);
 AccountDialogInputFields[3].Label_ := 'Organisation (optionnel):';

 FocusedInputField := 0;
End;

{ Initialise les champs pour la page du serveur entrant }
Procedure InitIncomingServerFields;
Var
 BaseX, BaseY: Integer;
Begin
 BaseX := DIALOG_X + DIALOG_MARGIN + 20;
 BaseY := DIALOG_Y + 50;

 { Boutons radio pour le type de serveur }
 AccountDialogRadioButtons[0].X := BaseX;
 AccountDialogRadioButtons[0].Y := BaseY;
 AccountDialogRadioButtons[0].Label_ := 'IMAP';
 AccountDialogRadioButtons[0].Checked := TempAccount.IncomingType = istIMAP;
 AccountDialogRadioButtons[0].GroupID := 1;

 AccountDialogRadioButtons[1].X := BaseX + 80;
 AccountDialogRadioButtons[1].Y := BaseY;
 AccountDialogRadioButtons[1].Label_ := 'POP3';
 AccountDialogRadioButtons[1].Checked := TempAccount.IncomingType = istPOP3;
 AccountDialogRadioButtons[1].GroupID := 1;

 { Serveur entrant }
 BaseY := BaseY + 35;
 AccountDialogInputFields[0].X := BaseX;
 AccountDialogInputFields[0].Y := BaseY;
 AccountDialogInputFields[0].Width := 280;
 AccountDialogInputFields[0].MaxLen := 80;
 AccountDialogInputFields[0].Value := TempAccount.IncomingHost;
 AccountDialogInputFields[0].IsPassword := False;
 AccountDialogInputFields[0].IsFocused := True;
 AccountDialogInputFields[0].CursorPos := Length(TempAccount.IncomingHost);
 AccountDialogInputFields[0].Label_ := 'Serveur de courrier entrant:';

 { Port }
 BaseY := BaseY + 45;
 AccountDialogInputFields[1].X := BaseX;
 AccountDialogInputFields[1].Y := BaseY;
 AccountDialogInputFields[1].Width := 60;
 AccountDialogInputFields[1].MaxLen := 5;
 If TempAccount.IncomingPort > 0 Then Begin
  Str(TempAccount.IncomingPort, AccountDialogInputFields[1].Value);
 End Else
  AccountDialogInputFields[1].Value := '';
 AccountDialogInputFields[1].IsPassword := False;
 AccountDialogInputFields[1].IsFocused := False;
 AccountDialogInputFields[1].CursorPos := 0;
 AccountDialogInputFields[1].Label_ := 'Port:';

 { Boutons radio pour la securite }
 BaseY := BaseY + 35;
 AccountDialogRadioButtons[2].X := BaseX;
 AccountDialogRadioButtons[2].Y := BaseY;
 AccountDialogRadioButtons[2].Label_ := 'Aucune';
 AccountDialogRadioButtons[2].Checked := TempAccount.IncomingSecurity = csNone;
 AccountDialogRadioButtons[2].GroupID := 2;

 AccountDialogRadioButtons[3].X := BaseX + 80;
 AccountDialogRadioButtons[3].Y := BaseY;
 AccountDialogRadioButtons[3].Label_ := 'SSL/TLS';
 AccountDialogRadioButtons[3].Checked := TempAccount.IncomingSecurity = csSSL;
 AccountDialogRadioButtons[3].GroupID := 2;

 AccountDialogRadioButtons[4].X := BaseX + 170;
 AccountDialogRadioButtons[4].Y := BaseY;
 AccountDialogRadioButtons[4].Label_ := 'STARTTLS';
 AccountDialogRadioButtons[4].Checked := TempAccount.IncomingSecurity = csSTARTTLS;
 AccountDialogRadioButtons[4].GroupID := 2;

 { Nom d'utilisateur }
 BaseY := BaseY + 35;
 AccountDialogInputFields[2].X := BaseX;
 AccountDialogInputFields[2].Y := BaseY;
 AccountDialogInputFields[2].Width := 280;
 AccountDialogInputFields[2].MaxLen := 60;
 AccountDialogInputFields[2].Value := TempAccount.IncomingUsername;
 AccountDialogInputFields[2].IsPassword := False;
 AccountDialogInputFields[2].IsFocused := False;
 AccountDialogInputFields[2].CursorPos := Length(TempAccount.IncomingUsername);
 AccountDialogInputFields[2].Label_ := 'Nom d''utilisateur:';

 { Mot de passe }
 BaseY := BaseY + 45;
 AccountDialogInputFields[3].X := BaseX;
 AccountDialogInputFields[3].Y := BaseY;
 AccountDialogInputFields[3].Width := 200;
 AccountDialogInputFields[3].MaxLen := 40;
 AccountDialogInputFields[3].Value := XORPassword(TempAccount.IncomingPassword);
 AccountDialogInputFields[3].IsPassword := True;
 AccountDialogInputFields[3].IsFocused := False;
 AccountDialogInputFields[3].CursorPos := 0;
 AccountDialogInputFields[3].Label_ := 'Mot de passe:';

 FocusedInputField := 0;
End;

{ Initialise les champs pour la page du serveur sortant }
Procedure InitOutgoingServerFields;
Var
 BaseX, BaseY: Integer;
Begin
 BaseX := DIALOG_X + DIALOG_MARGIN + 20;
 BaseY := DIALOG_Y + 50;

 { Serveur sortant }
 AccountDialogInputFields[0].X := BaseX;
 AccountDialogInputFields[0].Y := BaseY;
 AccountDialogInputFields[0].Width := 280;
 AccountDialogInputFields[0].MaxLen := 80;
 AccountDialogInputFields[0].Value := TempAccount.OutgoingHost;
 AccountDialogInputFields[0].IsPassword := False;
 AccountDialogInputFields[0].IsFocused := True;
 AccountDialogInputFields[0].CursorPos := Length(TempAccount.OutgoingHost);
 AccountDialogInputFields[0].Label_ := 'Serveur de courrier sortant (SMTP):';

 { Port }
 BaseY := BaseY + 45;
 AccountDialogInputFields[1].X := BaseX;
 AccountDialogInputFields[1].Y := BaseY;
 AccountDialogInputFields[1].Width := 60;
 AccountDialogInputFields[1].MaxLen := 5;
 If TempAccount.OutgoingPort > 0 Then Begin
  Str(TempAccount.OutgoingPort, AccountDialogInputFields[1].Value);
 End Else
  AccountDialogInputFields[1].Value := '';
 AccountDialogInputFields[1].IsPassword := False;
 AccountDialogInputFields[1].IsFocused := False;
 AccountDialogInputFields[1].CursorPos := 0;
 AccountDialogInputFields[1].Label_ := 'Port:';

 { Boutons radio pour la securite }
 BaseY := BaseY + 35;
 AccountDialogRadioButtons[0].X := BaseX;
 AccountDialogRadioButtons[0].Y := BaseY;
 AccountDialogRadioButtons[0].Label_ := 'Aucune';
 AccountDialogRadioButtons[0].Checked := TempAccount.OutgoingSecurity = csNone;
 AccountDialogRadioButtons[0].GroupID := 3;

 AccountDialogRadioButtons[1].X := BaseX + 80;
 AccountDialogRadioButtons[1].Y := BaseY;
 AccountDialogRadioButtons[1].Label_ := 'SSL/TLS';
 AccountDialogRadioButtons[1].Checked := TempAccount.OutgoingSecurity = csSSL;
 AccountDialogRadioButtons[1].GroupID := 3;

 AccountDialogRadioButtons[2].X := BaseX + 170;
 AccountDialogRadioButtons[2].Y := BaseY;
 AccountDialogRadioButtons[2].Label_ := 'STARTTLS';
 AccountDialogRadioButtons[2].Checked := TempAccount.OutgoingSecurity = csSTARTTLS;
 AccountDialogRadioButtons[2].GroupID := 3;

 { Case a cocher - Authentification requise }
 BaseY := BaseY + 30;
 AccountDialogCheckBoxes[0].X := BaseX;
 AccountDialogCheckBoxes[0].Y := BaseY;
 AccountDialogCheckBoxes[0].Label_ := 'Authentification requise';
 AccountDialogCheckBoxes[0].Checked := TempAccount.OutgoingAuthRequired;

 { Case a cocher - Utiliser memes identifiants }
 BaseY := BaseY + 25;
 AccountDialogCheckBoxes[1].X := BaseX + 20;
 AccountDialogCheckBoxes[1].Y := BaseY;
 AccountDialogCheckBoxes[1].Label_ := 'Memes identifiants que serveur entrant';
 AccountDialogCheckBoxes[1].Checked := TempAccount.OutgoingUseSameAuth;

 { Nom d'utilisateur SMTP (si different) }
 BaseY := BaseY + 30;
 AccountDialogInputFields[2].X := BaseX + 20;
 AccountDialogInputFields[2].Y := BaseY;
 AccountDialogInputFields[2].Width := 260;
 AccountDialogInputFields[2].MaxLen := 60;
 AccountDialogInputFields[2].Value := TempAccount.OutgoingUsername;
 AccountDialogInputFields[2].IsPassword := False;
 AccountDialogInputFields[2].IsFocused := False;
 AccountDialogInputFields[2].CursorPos := Length(TempAccount.OutgoingUsername);
 AccountDialogInputFields[2].Label_ := 'Nom d''utilisateur SMTP:';

 { Mot de passe SMTP }
 BaseY := BaseY + 45;
 AccountDialogInputFields[3].X := BaseX + 20;
 AccountDialogInputFields[3].Y := BaseY;
 AccountDialogInputFields[3].Width := 200;
 AccountDialogInputFields[3].MaxLen := 40;
 AccountDialogInputFields[3].Value := XORPassword(TempAccount.OutgoingPassword);
 AccountDialogInputFields[3].IsPassword := True;
 AccountDialogInputFields[3].IsFocused := False;
 AccountDialogInputFields[3].CursorPos := 0;
 AccountDialogInputFields[3].Label_ := 'Mot de passe SMTP:';

 FocusedInputField := 0;
End;

{ Sauvegarde les valeurs des champs de la page info compte }
Procedure SaveAccountInfoFields;
Begin
 TempAccount.AccountName := AccountDialogInputFields[0].Value;
 TempAccount.DisplayName := AccountDialogInputFields[1].Value;
 TempAccount.EmailAddress := AccountDialogInputFields[2].Value;
 TempAccount.Organization := AccountDialogInputFields[3].Value;

 { Auto-remplir le nom d'utilisateur avec l'email si vide }
 If TempAccount.IncomingUsername = '' Then
  TempAccount.IncomingUsername := TempAccount.EmailAddress;
End;

{ Sauvegarde les valeurs des champs du serveur entrant }
Procedure SaveIncomingServerFields;
Var
 PortCode: Integer;
Begin
 { Type de serveur }
 If AccountDialogRadioButtons[0].Checked Then
  TempAccount.IncomingType := istIMAP
 Else
  TempAccount.IncomingType := istPOP3;

 TempAccount.IncomingHost := AccountDialogInputFields[0].Value;

 { Port }
 Val(AccountDialogInputFields[1].Value, TempAccount.IncomingPort, PortCode);
 If PortCode <> 0 Then Begin
  If TempAccount.IncomingType = istIMAP Then
   TempAccount.IncomingPort := DEFAULT_IMAPS_PORT
  Else
   TempAccount.IncomingPort := DEFAULT_POP3S_PORT;
 End;

 { Securite }
 If AccountDialogRadioButtons[2].Checked Then
  TempAccount.IncomingSecurity := csNone
 Else If AccountDialogRadioButtons[3].Checked Then
  TempAccount.IncomingSecurity := csSSL
 Else
  TempAccount.IncomingSecurity := csSTARTTLS;

 TempAccount.IncomingUsername := AccountDialogInputFields[2].Value;
 TempAccount.IncomingPassword := XORPassword(AccountDialogInputFields[3].Value);
End;

{ Sauvegarde les valeurs des champs du serveur sortant }
Procedure SaveOutgoingServerFields;
Var
 PortCode: Integer;
Begin
 TempAccount.OutgoingHost := AccountDialogInputFields[0].Value;

 { Port }
 Val(AccountDialogInputFields[1].Value, TempAccount.OutgoingPort, PortCode);
 If PortCode <> 0 Then
  TempAccount.OutgoingPort := DEFAULT_SMTP_SUBMISSION_PORT;

 { Securite }
 If AccountDialogRadioButtons[0].Checked Then
  TempAccount.OutgoingSecurity := csNone
 Else If AccountDialogRadioButtons[1].Checked Then
  TempAccount.OutgoingSecurity := csSSL
 Else
  TempAccount.OutgoingSecurity := csSTARTTLS;

 TempAccount.OutgoingAuthRequired := AccountDialogCheckBoxes[0].Checked;
 TempAccount.OutgoingUseSameAuth := AccountDialogCheckBoxes[1].Checked;

 If Not TempAccount.OutgoingUseSameAuth Then Begin
  TempAccount.OutgoingUsername := AccountDialogInputFields[2].Value;
  TempAccount.OutgoingPassword := XORPassword(AccountDialogInputFields[3].Value);
 End
 Else Begin
  TempAccount.OutgoingUsername := TempAccount.IncomingUsername;
  TempAccount.OutgoingPassword := TempAccount.IncomingPassword;
 End;
End;

{ Teste la connexion au serveur entrant }
Function TestIncomingConnection: TConnectionTestResult;
Begin
 If OpenIncomingAccount(TempAccount) Then TestIncomingConnection:=ctrSuccess
 Else TestIncomingConnection:=ctrFailedIncoming;
 MailClose(IMAPWire); MailClose(POP3Wire);
End;

{ Verifie la connexion SMTP, TLS et l authentification sans envoyer de message. }
Function TestOutgoingConnection: TConnectionTestResult;
Begin
 If OpenOutgoingAccount(TempAccount) Then TestOutgoingConnection:=ctrSuccess
 Else TestOutgoingConnection:=ctrFailedOutgoing;
 MailClose(SMTPWire);
End;

{ Execute le test de connexion complet }
Procedure RunConnectionTestWork;
Var
 Result: TConnectionTestResult;
Begin
 ConnectionTestInProgress := True;
 ConnectionTestResult := ctrTesting;
 MailError := '';

 { Tester le serveur entrant }
 Result := TestIncomingConnection;
 If Result <> ctrSuccess Then Begin
  ConnectionTestResult := Result;
  ConnectionTestInProgress := False;
  Exit;
 End;

 BusyDetail:=TempAccount.OutgoingHost; BusyStage('Verification du serveur sortant...');
 { Tester le serveur sortant }
 Result := TestOutgoingConnection;
 If Result <> ctrSuccess Then Begin
  ConnectionTestResult := Result;
  ConnectionTestInProgress := False;
  Exit;
 End;

 ConnectionTestResult := ctrSuccess;
 TempAccount.LastConnectionTest := ctrSuccess;
 ConnectionTestInProgress := False;
End;

Procedure RunConnectionTest;
Begin
 If BusyVisible Then Exit;
 BusyBegin('Test de connexion du compte',TempAccount.IncomingHost);
 RunConnectionTestWork;
 BusyEnd;
End;

{ Retourne le texte du resultat du test }
Function GetConnectionTestResultText(Result: TConnectionTestResult): String;
Begin
 Case Result Of
  ctrNotTested: GetConnectionTestResultText := 'Non teste';
  ctrTesting: GetConnectionTestResultText := 'Test en cours...';
  ctrSuccess: GetConnectionTestResultText := 'Connexion reussie!';
  ctrFailedIncoming: GetConnectionTestResultText := 'Echec serveur entrant';
  ctrFailedOutgoing: GetConnectionTestResultText := 'Echec serveur sortant';
  ctrFailedAuth: GetConnectionTestResultText := 'Echec authentification';
  ctrFailedNetwork: GetConnectionTestResultText := 'Erreur reseau';
  Else GetConnectionTestResultText := 'Erreur inconnue';
 End;
End;

{ Dessine la page de bienvenue de l'assistant }
Procedure DrawWizardWelcomePage;
Var
 Y: Integer;
Begin
 Y := DIALOG_Y + 40;

 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Bienvenue dans l''assistant de configuration');
 Y := Y + 25;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'de compte de messagerie.');
 Y := Y + 35;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Cet assistant vous guidera pour configurer');
 Y := Y + 18;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'un nouveau compte de messagerie.');
 Y := Y + 35;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Vous aurez besoin des informations suivantes:');
 Y := Y + 25;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, '- Votre adresse de courrier electronique');
 Y := Y + 18;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, '- Le nom du serveur de courrier entrant');
 Y := Y + 18;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, '- Le nom du serveur de courrier sortant');
 Y := Y + 18;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, '- Votre nom d''utilisateur et mot de passe');
 Y := Y + 35;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Cliquez sur Suivant pour continuer.');
End;

{ Dessine la page d'information du compte }
Procedure DrawAccountInfoPage;
Var
 Y, I: Integer;
Begin
 Y := DIALOG_Y + 30;

 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Informations du compte');

 { Dessiner les champs de saisie }
 For I := 0 To 3 Do
  DrawInputField(AccountDialogInputFields[I]);
End;

{ Dessine la page du serveur entrant }
Procedure DrawIncomingServerPage;
Var
 Y, I: Integer;
Begin
 Y := DIALOG_Y + 30;

 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Serveur de courrier entrant');

 { Type de serveur }
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, DIALOG_Y + 38, 'Type de serveur:');

 { Dessiner les boutons radio type serveur }
 DrawRadioButton(AccountDialogRadioButtons[0]);
 DrawRadioButton(AccountDialogRadioButtons[1]);

 { Dessiner les champs de saisie }
 For I := 0 To 3 Do
  DrawInputField(AccountDialogInputFields[I]);

 { Dessiner les boutons radio securite }
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, AccountDialogRadioButtons[2].Y - 15, 'Securite:');
 DrawRadioButton(AccountDialogRadioButtons[2]);
 DrawRadioButton(AccountDialogRadioButtons[3]);
 DrawRadioButton(AccountDialogRadioButtons[4]);
End;

{ Dessine la page du serveur sortant }
Procedure DrawOutgoingServerPage;
Var
 Y, I: Integer;
Begin
 Y := DIALOG_Y + 30;

 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Serveur de courrier sortant (SMTP)');

 { Dessiner les champs de saisie }
 DrawInputField(AccountDialogInputFields[0]);
 DrawInputField(AccountDialogInputFields[1]);

 { Dessiner les boutons radio securite }
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, AccountDialogRadioButtons[0].Y - 15, 'Securite:');
 For I := 0 To 2 Do
  DrawRadioButton(AccountDialogRadioButtons[I]);

 { Dessiner les cases a cocher }
 DrawCheckBox(AccountDialogCheckBoxes[0]);
 DrawCheckBox(AccountDialogCheckBoxes[1]);

 { Dessiner les champs SMTP si auth requise et pas memes identifiants }
 If AccountDialogCheckBoxes[0].Checked And Not AccountDialogCheckBoxes[1].Checked Then Begin
  DrawInputField(AccountDialogInputFields[2]);
  DrawInputField(AccountDialogInputFields[3]);
 End;
End;

{ Dessine la page de test de connexion }
Procedure DrawTestConnectionPage;
Var
 Y: Integer;
 ResultColor: Word;
Begin
 Y := DIALOG_Y + 40;

 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Test de connexion');

 Y := Y + 35;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Configuration actuelle:');

 Y := Y + 25;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, 'Serveur entrant: ' + TempAccount.IncomingHost);
 Y := Y + 18;
 If TempAccount.IncomingType = istIMAP Then
  GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, 'Type: IMAP')
 Else
  GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, 'Type: POP3');
 Y := Y + 18;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, 'Serveur sortant: ' + TempAccount.OutgoingHost);

 Y := Y + 35;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Resultat du test:');

 Y := Y + 20;
 { Couleur selon le resultat }
 Case ConnectionTestResult Of
  ctrSuccess: ResultColor := LightGreen;
  ctrTesting: ResultColor := Yellow;
  Else ResultColor := LightRed;
 End;
 GSetColor(ResultColor);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, GetConnectionTestResultText(ConnectionTestResult));
 If (ConnectionTestResult<>ctrSuccess) And (MailError<>'') Then
  GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y+18, Copy(MailError,1,60));

 Y := Y + 40;
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Cliquez sur "Tester" pour verifier la connexion.');

 { Bouton Tester }
 DrawDialogButton(DIALOG_X + DIALOG_MARGIN, Y + 25, 80, DIALOG_BUTTON_HEIGHT,
                  'Tester', False, Not ConnectionTestInProgress);
End;

{ Dessine la page de completion }
Procedure DrawCompletePage;
Var
 Y: Integer;
Begin
 Y := DIALOG_Y + 40;

 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Configuration terminee!');

 Y := Y + 35;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Votre compte a ete configure avec succes.');

 Y := Y + 35;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Resume:');
 Y := Y + 25;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, 'Compte: ' + TempAccount.AccountName);
 Y := Y + 18;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, 'Email: ' + TempAccount.EmailAddress);
 Y := Y + 18;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, 'Serveur entrant: ' + TempAccount.IncomingHost);
 Y := Y + 18;
 GOutTextXY(DIALOG_X + DIALOG_MARGIN + 20, Y, 'Serveur sortant: ' + TempAccount.OutgoingHost);

 If ConnectionTestResult = ctrSuccess Then Begin
  Y := Y + 35;
  GSetColor(LightGreen);
  GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Test de connexion reussi!');
 End;

 Y := Y + 35;
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Cliquez sur Terminer pour sauvegarder.');
End;

{ Dessine le contenu de l'assistant selon l'etape }
Procedure DrawWizardContent;
Begin
 Case AccountWizardStep Of
  awsWelcome: DrawWizardWelcomePage;
  awsAccountInfo: DrawAccountInfoPage;
  awsIncomingServer: DrawIncomingServerPage;
  awsOutgoingServer: DrawOutgoingServerPage;
  awsTestConnection: DrawTestConnectionPage;
  awsComplete: DrawCompletePage;
 End;
End;

{ Dessine la boite de dialogue de l'assistant }
Procedure DrawAccountWizardDialog;
Var
 Title: String;
 BtnX, BtnY: Integer;
Begin
 { Titre selon l'etape }
 Case AccountWizardStep Of
  awsWelcome: Title := 'Assistant de compte - Bienvenue';
  awsAccountInfo: Title := 'Assistant de compte - Informations';
  awsIncomingServer: Title := 'Assistant de compte - Serveur entrant';
  awsOutgoingServer: Title := 'Assistant de compte - Serveur sortant';
  awsTestConnection: Title := 'Assistant de compte - Test';
  awsComplete: Title := 'Assistant de compte - Termine';
  Else Title := 'Assistant de compte';
 End;

 HideMouse;

 { Dessiner la boite de dialogue }
 DrawDialogBox(DIALOG_X, DIALOG_Y, DIALOG_WIDTH, DIALOG_HEIGHT, Title);

 { Dessiner le contenu selon l'etape }
 DrawWizardContent;

 { Boutons de navigation }
 BtnY := DIALOG_Y + DIALOG_HEIGHT - DIALOG_BUTTON_HEIGHT - DIALOG_MARGIN;

 { Bouton Annuler }
 BtnX := DIALOG_X + DIALOG_MARGIN;
 DrawDialogButton(BtnX, BtnY, DIALOG_BUTTON_WIDTH, DIALOG_BUTTON_HEIGHT,
                  'Annuler', False, True);

 { Bouton Precedent }
 BtnX := DIALOG_X + DIALOG_WIDTH - DIALOG_BUTTON_WIDTH * 3 - DIALOG_MARGIN * 2 - 10;
 DrawDialogButton(BtnX, BtnY, DIALOG_BUTTON_WIDTH, DIALOG_BUTTON_HEIGHT,
                  'Precedent', False, AccountWizardStep > awsWelcome);

 { Bouton Suivant/Terminer }
 BtnX := DIALOG_X + DIALOG_WIDTH - DIALOG_BUTTON_WIDTH * 2 - DIALOG_MARGIN - 5;
 If AccountWizardStep = awsComplete Then
  DrawDialogButton(BtnX, BtnY, DIALOG_BUTTON_WIDTH, DIALOG_BUTTON_HEIGHT,
                   'Terminer', False, True)
 Else
  DrawDialogButton(BtnX, BtnY, DIALOG_BUTTON_WIDTH, DIALOG_BUTTON_HEIGHT,
                   'Suivant', False, True);

 ShowMouse;
End;

{ Dessine la liste des comptes }
Procedure DrawAccountListDialog;
Var
 Y, I: Integer;
 BtnX, BtnY: Integer;
 BgColor: Word;
Begin
 HideMouse;

 { Dessiner la boite de dialogue }
 DrawDialogBox(DIALOG_X, DIALOG_Y, DIALOG_WIDTH, DIALOG_HEIGHT, 'Gestion des comptes');

 { Liste des comptes }
 Y := DIALOG_Y + 30;
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(DIALOG_X + DIALOG_MARGIN, Y, 'Comptes de messagerie:');

 Y := Y + 20;

 { Zone de liste }
 GSetFillStyle(SolidFill, COLOR_LIST_BG);
 GBar(DIALOG_X + DIALOG_MARGIN, Y, DIALOG_X + DIALOG_WIDTH - 120, Y + 180);
 Draw3DRect(DIALOG_X + DIALOG_MARGIN, Y, DIALOG_X + DIALOG_WIDTH - 120, Y + 180, False);

 { Afficher les comptes }
 For I := 0 To EmailAccountCount - 1 Do Begin
  If (I - AccountListScrollOffset >= 0) And (I - AccountListScrollOffset < 10) Then Begin
   { Fond de selection }
   If I = SelectedAccountInList Then Begin
    BgColor := COLOR_LIST_SELECTED;
    GSetFillStyle(SolidFill, BgColor);
    GBar(DIALOG_X + DIALOG_MARGIN + 2, Y + (I - AccountListScrollOffset) * 18,
        DIALOG_X + DIALOG_WIDTH - 122, Y + (I - AccountListScrollOffset) * 18 + 16);
    GSetColor(COLOR_LIST_SELECTED_TEXT);
   End
   Else
    GSetColor(COLOR_MENU_TEXT);

   GOutTextXY(DIALOG_X + DIALOG_MARGIN + 5, Y + (I - AccountListScrollOffset) * 18 + 3,
             EmailAccounts[I].AccountName);

   { Indicateur par defaut }
   If EmailAccounts[I].IsDefault Then
    GOutTextXY(DIALOG_X + DIALOG_WIDTH - 200, Y + (I - AccountListScrollOffset) * 18 + 3, '(defaut)');
  End;
 End;

 { Boutons d'action }
 BtnX := DIALOG_X + DIALOG_WIDTH - 110;
 BtnY := DIALOG_Y + 50;

 DrawDialogButton(BtnX, BtnY, 95, DIALOG_BUTTON_HEIGHT, 'Ajouter', False, True);
 BtnY := BtnY + 30;
 DrawDialogButton(BtnX, BtnY, 95, DIALOG_BUTTON_HEIGHT, 'Modifier', False, SelectedAccountInList >= 0);
 BtnY := BtnY + 30;
 DrawDialogButton(BtnX, BtnY, 95, DIALOG_BUTTON_HEIGHT, 'Supprimer', False, SelectedAccountInList >= 0);
 BtnY := BtnY + 30;
 DrawDialogButton(BtnX, BtnY, 95, DIALOG_BUTTON_HEIGHT, 'Par defaut', False, SelectedAccountInList >= 0);
 BtnY := BtnY + 30;
 DrawDialogButton(BtnX, BtnY, 95, DIALOG_BUTTON_HEIGHT, 'Proprietes', False, SelectedAccountInList >= 0);

 If AccountStorageError <> '' Then Begin
  GSetColor(LightRed);
  GOutTextXY(DIALOG_X + DIALOG_MARGIN, DIALOG_Y + 245, AccountStorageError);
 End;

 { Boutons de fermeture }
 BtnY := DIALOG_Y + DIALOG_HEIGHT - DIALOG_BUTTON_HEIGHT - DIALOG_MARGIN;
 BtnX := DIALOG_X + DIALOG_WIDTH - DIALOG_BUTTON_WIDTH - DIALOG_MARGIN;
 DrawDialogButton(BtnX, BtnY, DIALOG_BUTTON_WIDTH, DIALOG_BUTTON_HEIGHT, 'Fermer', False, True);

 ShowMouse;
End;

{ ============================================================================
  DrawAccountManagerDialog - Affiche la boite de dialogue de gestion des comptes

  Cette procedure est le point d'entree principal pour l'affichage du
  gestionnaire de comptes. Elle affiche soit:
  - La liste des comptes (mode liste) quand AccountWizardMode = False
  - L'assistant de configuration (mode assistant) quand AccountWizardMode = True

  Disposition de la boite de dialogue (mode liste):
  +-----------------------------------------------+
  | Gestion des comptes                       [X] |
  +-----------------------------------------------+
  | Comptes de messagerie:         | [Ajouter  ] |
  | +---------------------------+  | [Modifier ] |
  | | Compte 1           (def)  |  | [Supprimer] |
  | | Compte 2                  |  | [Par defaut]|
  | +---------------------------+  | [Proprietes]|
  |                                              |
  |                               [Fermer]       |
  +-----------------------------------------------+

  Disposition de l'assistant (chaque etape):
  +-----------------------------------------------+
  | Assistant de compte - [Titre etape]       [X] |
  +-----------------------------------------------+
  |                                              |
  | [Contenu variable selon l'etape]             |
  |                                              |
  | [Annuler]    [Precedent] [Suivant/Terminer] |
  +-----------------------------------------------+

  Coordonnees:
  - Position: DIALOG_X, DIALOG_Y (centre de l'ecran)
  - Dimensions: DIALOG_WIDTH x DIALOG_HEIGHT (500 x 350 pixels)
  - Marge interieure: DIALOG_MARGIN (10 pixels)
  ============================================================================ }
Procedure DrawAccountManagerDialog;
Begin
 If AccountWizardMode Then
  DrawAccountWizardDialog
 Else
  DrawAccountListDialog;
End;

{ Passe a l'etape suivante de l'assistant }
Procedure WizardNextStep;
Begin
 Case AccountWizardStep Of
  awsWelcome: Begin
   AccountWizardStep := awsAccountInfo;
   InitAccountInfoFields;
  End;
  awsAccountInfo: Begin
   SaveAccountInfoFields;
   AccountWizardStep := awsIncomingServer;
   InitIncomingServerFields;
  End;
  awsIncomingServer: Begin
   SaveIncomingServerFields;
   AccountWizardStep := awsOutgoingServer;
   InitOutgoingServerFields;
  End;
  awsOutgoingServer: Begin
   SaveOutgoingServerFields;
   AccountWizardStep := awsTestConnection;
   ConnectionTestResult := ctrNotTested;
  End;
  awsTestConnection: Begin
   AccountWizardStep := awsComplete;
  End;
  awsComplete: Begin
   { Sauvegarder le compte }
   If CurrentAccountIndex < 0 Then Begin
    If EmailAccountCount < MAX_EMAIL_ACCOUNTS Then Begin
     EmailAccounts[EmailAccountCount] := TempAccount;
     { Premier compte = defaut }
     If EmailAccountCount = 0 Then
      EmailAccounts[EmailAccountCount].IsDefault := True;
     Inc(EmailAccountCount);
    End;
   End
   Else Begin
    EmailAccounts[CurrentAccountIndex] := TempAccount;
   End;
   SaveAccounts;
   RefreshAccountFolders;
   AccountWizardMode := False;
   AccountDialogVisible := True;
  End;
 End;
 DrawAccountManagerDialog;
End;

{ Retourne a l'etape precedente de l'assistant }
Procedure WizardPreviousStep;
Begin
 Case AccountWizardStep Of
  awsAccountInfo: AccountWizardStep := awsWelcome;
  awsIncomingServer: Begin
   AccountWizardStep := awsAccountInfo;
   InitAccountInfoFields;
  End;
  awsOutgoingServer: Begin
   AccountWizardStep := awsIncomingServer;
   InitIncomingServerFields;
  End;
  awsTestConnection: Begin
   AccountWizardStep := awsOutgoingServer;
   InitOutgoingServerFields;
  End;
  awsComplete: AccountWizardStep := awsTestConnection;
 End;
 DrawAccountManagerDialog;
End;

{ Annule l'assistant }
Procedure WizardCancel;
Begin
 AccountWizardMode := False;
 AccountDialogVisible := True;
 DrawAccountManagerDialog;
End;

{ Ouvre la boite de dialogue de gestion des comptes }
Procedure ShowAccountManagerDialog;
Begin
 If ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or ColumnsDialogVisible Or
    RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Then Exit;
 RibbonKeyboardActive:=False; RibbonFocus:=-1;
 AccountDialogVisible := True;
 AccountWizardMode := False;
 SelectedAccountInList := -1;
 If EmailAccountCount > 0 Then
  SelectedAccountInList := 0;
 DrawInterface;
End;

{ Ferme la boite de dialogue de gestion des comptes }
Procedure HideAccountManagerDialog;
Begin
 AccountDialogVisible := False;
 AccountWizardMode := False;
 DrawInterface;
End;

{ Ouvre l'assistant pour un nouveau compte }
Procedure StartNewAccountWizard;
Begin
 InitializeEmptyAccount(TempAccount);
 CurrentAccountIndex := -1;
 AccountWizardMode := True;
 AccountWizardStep := awsWelcome;
 ConnectionTestResult := ctrNotTested;
 DrawAccountManagerDialog;
End;

{ Ouvre l'assistant pour modifier un compte existant }
Procedure EditExistingAccount(Index: Integer);
Begin
 If (Index < 0) Or (Index >= EmailAccountCount) Then Exit;
 TempAccount := EmailAccounts[Index];
 CurrentAccountIndex := Index;
 AccountWizardMode := True;
 AccountWizardStep := awsAccountInfo;
 InitAccountInfoFields;
 DrawAccountManagerDialog;
End;

{ Supprime un compte }
Procedure DeleteAccount(Index: Integer);
Var
 I: Integer;
Begin
 If (Index < 0) Or (Index >= EmailAccountCount) Then Exit;

 { Decaler les comptes }
 For I := Index To EmailAccountCount - 2 Do
  EmailAccounts[I] := EmailAccounts[I + 1];

 Dec(EmailAccountCount);
 If EmailAccountCount > 0 Then Begin
  For I := 0 To EmailAccountCount - 1 Do
   If EmailAccounts[I].IsDefault Then Break;
  If Not EmailAccounts[I].IsDefault Then EmailAccounts[0].IsDefault := True;
 End;
 SaveAccounts;
 RefreshAccountFolders;

 { Ajuster la selection }
 If SelectedAccountInList >= EmailAccountCount Then
  SelectedAccountInList := EmailAccountCount - 1;

 DrawAccountManagerDialog;
End;

{ Definit un compte comme compte par defaut }
Procedure SetDefaultAccount(Index: Integer);
Var
 I: Integer;
Begin
 If (Index < 0) Or (Index >= EmailAccountCount) Then Exit;

 For I := 0 To EmailAccountCount - 1 Do
  EmailAccounts[I].IsDefault := (I = Index);
 SaveAccounts;
 RefreshAccountFolders;

 DrawAccountManagerDialog;
End;

{ Gere les clics dans la boite de dialogue }
Procedure HandleAccountDialogClick(X, Y: Integer);
Var
 BtnX, BtnY, ListY, I: Integer;
Begin
 If Not AccountDialogVisible Then Exit;

 { Verifier si clic dans la boite de dialogue }
 If (X < DIALOG_X) Or (X > DIALOG_X + DIALOG_WIDTH) Or
    (Y < DIALOG_Y) Or (Y > DIALOG_Y + DIALOG_HEIGHT) Then Begin
  HideAccountManagerDialog;
  Exit;
 End;

 If AccountWizardMode Then Begin
  { Mode assistant }
  BtnY := DIALOG_Y + DIALOG_HEIGHT - DIALOG_BUTTON_HEIGHT - DIALOG_MARGIN;

  { Bouton Annuler }
  BtnX := DIALOG_X + DIALOG_MARGIN;
  If (X >= BtnX) And (X <= BtnX + DIALOG_BUTTON_WIDTH) And
     (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) Then Begin
   WizardCancel;
   Exit;
  End;

  { Bouton Precedent }
  BtnX := DIALOG_X + DIALOG_WIDTH - DIALOG_BUTTON_WIDTH * 3 - DIALOG_MARGIN * 2 - 10;
  If (X >= BtnX) And (X <= BtnX + DIALOG_BUTTON_WIDTH) And
     (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) And
     (AccountWizardStep > awsWelcome) Then Begin
   WizardPreviousStep;
   Exit;
  End;

  { Bouton Suivant/Terminer }
  BtnX := DIALOG_X + DIALOG_WIDTH - DIALOG_BUTTON_WIDTH * 2 - DIALOG_MARGIN - 5;
  If (X >= BtnX) And (X <= BtnX + DIALOG_BUTTON_WIDTH) And
     (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) Then Begin
   WizardNextStep;
   Exit;
  End;

  { Bouton Tester (page test) }
  If AccountWizardStep = awsTestConnection Then Begin
   BtnY := DIALOG_Y + 225;
   If (X >= DIALOG_X + DIALOG_MARGIN) And (X <= DIALOG_X + DIALOG_MARGIN + 80) And
      (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) And
      Not ConnectionTestInProgress Then Begin
    RunConnectionTest;
    DrawAccountManagerDialog;
    Exit;
   End;
  End;

  { Gerer les clics sur les champs de saisie }
  For I := 0 To 3 Do Begin
   If (X >= AccountDialogInputFields[I].X) And
      (X <= AccountDialogInputFields[I].X + AccountDialogInputFields[I].Width) And
      (Y >= AccountDialogInputFields[I].Y) And
      (Y <= AccountDialogInputFields[I].Y + DIALOG_INPUT_HEIGHT) Then Begin
    { Deselectionner tous les champs }
    AccountDialogInputFields[0].IsFocused := False;
    AccountDialogInputFields[1].IsFocused := False;
    AccountDialogInputFields[2].IsFocused := False;
    AccountDialogInputFields[3].IsFocused := False;
    { Selectionner ce champ }
    AccountDialogInputFields[I].IsFocused := True;
    FocusedInputField := I;
    DrawAccountManagerDialog;
    Exit;
   End;
  End;

  { Gerer les clics sur les boutons radio }
  For I := 0 To 4 Do Begin
   If (X >= AccountDialogRadioButtons[I].X) And
      (X <= AccountDialogRadioButtons[I].X + 100) And
      (Y >= AccountDialogRadioButtons[I].Y) And
      (Y <= AccountDialogRadioButtons[I].Y + 14) Then Begin
    { Deselectionner tous les boutons du meme groupe }
    Case AccountDialogRadioButtons[I].GroupID Of
     1: Begin { Type serveur }
      AccountDialogRadioButtons[0].Checked := False;
      AccountDialogRadioButtons[1].Checked := False;
     End;
     2: Begin { Securite entrante }
      AccountDialogRadioButtons[2].Checked := False;
      AccountDialogRadioButtons[3].Checked := False;
      AccountDialogRadioButtons[4].Checked := False;
     End;
     3: Begin { Securite sortante }
      AccountDialogRadioButtons[0].Checked := False;
      AccountDialogRadioButtons[1].Checked := False;
      AccountDialogRadioButtons[2].Checked := False;
     End;
    End;
    AccountDialogRadioButtons[I].Checked := True;
    DrawAccountManagerDialog;
    Exit;
   End;
  End;

  { Gerer les clics sur les cases a cocher }
  For I := 0 To 1 Do Begin
   If (X >= AccountDialogCheckBoxes[I].X) And
      (X <= AccountDialogCheckBoxes[I].X + 150) And
      (Y >= AccountDialogCheckBoxes[I].Y) And
      (Y <= AccountDialogCheckBoxes[I].Y + 14) Then Begin
    AccountDialogCheckBoxes[I].Checked := Not AccountDialogCheckBoxes[I].Checked;
    DrawAccountManagerDialog;
    Exit;
   End;
  End;
 End
 Else Begin
  { Mode liste des comptes }
  BtnX := DIALOG_X + DIALOG_WIDTH - 110;

  { Bouton Ajouter }
  BtnY := DIALOG_Y + 50;
  If (X >= BtnX) And (X <= BtnX + 95) And
     (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) Then Begin
   StartNewAccountWizard;
   Exit;
  End;

  { Bouton Modifier }
  BtnY := BtnY + 30;
  If (X >= BtnX) And (X <= BtnX + 95) And
     (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) And
     (SelectedAccountInList >= 0) Then Begin
   EditExistingAccount(SelectedAccountInList);
   Exit;
  End;

  { Bouton Supprimer }
  BtnY := BtnY + 30;
  If (X >= BtnX) And (X <= BtnX + 95) And
     (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) And
     (SelectedAccountInList >= 0) Then Begin
   DeleteAccount(SelectedAccountInList);
   Exit;
  End;

  { Bouton Par defaut }
  BtnY := BtnY + 30;
  If (X >= BtnX) And (X <= BtnX + 95) And
     (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) And
     (SelectedAccountInList >= 0) Then Begin
   SetDefaultAccount(SelectedAccountInList);
   Exit;
  End;

  { Bouton Proprietes }
  BtnY := BtnY + 30;
  If (X >= BtnX) And (X <= BtnX + 95) And
     (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) And
     (SelectedAccountInList >= 0) Then Begin
   EditExistingAccount(SelectedAccountInList);
   Exit;
  End;

  { Bouton Fermer }
  BtnY := DIALOG_Y + DIALOG_HEIGHT - DIALOG_BUTTON_HEIGHT - DIALOG_MARGIN;
  BtnX := DIALOG_X + DIALOG_WIDTH - DIALOG_BUTTON_WIDTH - DIALOG_MARGIN;
  If (X >= BtnX) And (X <= BtnX + DIALOG_BUTTON_WIDTH) And
     (Y >= BtnY) And (Y <= BtnY + DIALOG_BUTTON_HEIGHT) Then Begin
   HideAccountManagerDialog;
   Exit;
  End;

  { Clic dans la liste des comptes }
  ListY := DIALOG_Y + 50;
  If (X >= DIALOG_X + DIALOG_MARGIN) And (X <= DIALOG_X + DIALOG_WIDTH - 120) And
     (Y >= ListY) And (Y <= ListY + 180) Then Begin
   I := (Y - ListY) Div 18 + AccountListScrollOffset;
   If (I >= 0) And (I < EmailAccountCount) Then Begin
    SelectedAccountInList := I;
    DrawAccountManagerDialog;
   End;
  End;
 End;
End;

{ Gere les touches clavier dans la boite de dialogue }
Procedure HandleAccountDialogKeyPress(Key: Char);
Var
 FieldValue: String;
Begin
 If Not AccountDialogVisible Then Exit;
 If Not AccountWizardMode Then Begin
  If Key=#27 Then HideAccountManagerDialog;
  If Key=#13 Then Begin
   If SelectedAccountInList>=0 Then EditExistingAccount(SelectedAccountInList) Else StartNewAccountWizard;
  End;
  Exit;
 End;
 If Key=#27 Then Begin WizardCancel; Exit; End;
 If Key=#13 Then Begin WizardNextStep; Exit; End;
 If FocusedInputField < 0 Then Exit;

 FieldValue := AccountDialogInputFields[FocusedInputField].Value;

 If Key = #8 Then Begin { Backspace }
  If Length(FieldValue) > 0 Then Begin
   Delete(FieldValue, Length(FieldValue), 1);
   AccountDialogInputFields[FocusedInputField].Value := FieldValue;
   DrawAccountManagerDialog;
  End;
 End
 Else If Key = #9 Then Begin { Tab }
  AccountDialogInputFields[FocusedInputField].IsFocused := False;
  Inc(FocusedInputField);
  If FocusedInputField > 3 Then FocusedInputField := 0;
  AccountDialogInputFields[FocusedInputField].IsFocused := True;
  DrawAccountManagerDialog;
 End
 Else If Key = #13 Then Begin { Enter }
  WizardNextStep;
 End
 Else If Key = #27 Then Begin { Escape }
  WizardCancel;
 End
 Else If (((Key >= ' ') And (Key <= '~')) Or (Key >= #128)) Then Begin { Caracteres imprimables }
  If Length(FieldValue) < AccountDialogInputFields[FocusedInputField].MaxLen Then Begin
   FieldValue := FieldValue + Key;
   AccountDialogInputFields[FocusedInputField].Value := FieldValue;
   DrawAccountManagerDialog;
  End;
 End;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DU GESTIONNAIRE DE COMPTES
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU COMPOSITEUR DE MESSAGES (TODO 12)
  ============================================================================ }

{ Initialise le compositeur de messages }
Procedure InitializeComposer;
Var
 I: Integer;
Begin
 ComposerVisible := False;
 ComposerFocusedField := COMP_FIELD_TO;
 ComposerCursorVisible := True;
 ComposerCursorTimer := 0;
 ComposerFormatBold := False;
 ComposerFormatItalic := False;
 ComposerFormatUnderline := False;

 { Initialiser le compositeur }
 Composer.ToField := '';
 Composer.CcField := '';
 Composer.BccField := '';
 Composer.SubjectField := '';
 Composer.AccountIndex := -1;
 Composer.LineCount := 1;
 Composer.CursorX := 0;
 Composer.CursorY := 0;
 Composer.ScrollX := 0;
 Composer.ScrollY := 0;
 Composer.HasSelection := False;
 Composer.Modified := False;
 Composer.State := csNew;
 Composer.OriginalMsgID := '';

 { Format par defaut }
 Composer.CurrentFormat.Bold := False;
 Composer.CurrentFormat.Italic := False;
 Composer.CurrentFormat.Underline := False;
 Composer.CurrentFormat.FontColor := COLOR_MENU_TEXT;

 { Initialiser les pieces jointes (TODO 13) }
 Composer.AttachmentCount := 0;
 AttachTotalSize := 0;
 SelectedAttachment := -1;

 { Initialiser les lignes vides }
 For I := 0 To COMPOSER_MAX_LINES - 1 Do Begin
  Composer.Lines[I].Text := '';
  Composer.Lines[I].Format.Bold := False;
  Composer.Lines[I].Format.Italic := False;
  Composer.Lines[I].Format.Underline := False;
  Composer.Lines[I].Format.FontColor := COLOR_MENU_TEXT;
 End;
End;

{ Initialise les champs d'en-tete du compositeur }
Procedure InitComposerFields;
Var
 BaseX, BaseY: Integer;
Begin
 ActiveMenu := -1;
 ActiveMenuItem := -1;
 MenuBarActive := False;
 TooltipVisible := False;
 ContextMenuVisible := False;
 DragState := dsNone;
 BaseX := COMPOSER_X + COMPOSER_LABEL_WIDTH + 10;
 BaseY := COMPOSER_Y + 28;

 { Champ A: (destinataires) }
 ComposerInputFields[0].X := BaseX;
 ComposerInputFields[0].Y := BaseY;
 ComposerInputFields[0].Width := COMPOSER_WIDTH - COMPOSER_LABEL_WIDTH - 30;
 ComposerInputFields[0].MaxLen := 250;
 ComposerInputFields[0].Value := Composer.ToField;
 ComposerInputFields[0].IsPassword := False;
 ComposerInputFields[0].IsFocused := True;
 ComposerInputFields[0].CursorPos := Length(Composer.ToField);
 ComposerInputFields[0].Label_ := 'A:';

 { Champ Cc: }
 BaseY := BaseY + COMPOSER_FIELD_SPACING;
 ComposerInputFields[1].X := BaseX;
 ComposerInputFields[1].Y := BaseY;
 ComposerInputFields[1].Width := COMPOSER_WIDTH - COMPOSER_LABEL_WIDTH - 30;
 ComposerInputFields[1].MaxLen := 250;
 ComposerInputFields[1].Value := Composer.CcField;
 ComposerInputFields[1].IsPassword := False;
 ComposerInputFields[1].IsFocused := False;
 ComposerInputFields[1].CursorPos := Length(Composer.CcField);
 ComposerInputFields[1].Label_ := 'Cc:';

 { Champ Cci: }
 BaseY := BaseY + COMPOSER_FIELD_SPACING;
 ComposerInputFields[2].X := BaseX;
 ComposerInputFields[2].Y := BaseY;
 ComposerInputFields[2].Width := COMPOSER_WIDTH - COMPOSER_LABEL_WIDTH - 30;
 ComposerInputFields[2].MaxLen := 250;
 ComposerInputFields[2].Value := Composer.BccField;
 ComposerInputFields[2].IsPassword := False;
 ComposerInputFields[2].IsFocused := False;
 ComposerInputFields[2].CursorPos := Length(Composer.BccField);
 ComposerInputFields[2].Label_ := 'Cci:';

 { Champ Objet: }
 BaseY := BaseY + COMPOSER_FIELD_SPACING;
 ComposerInputFields[3].X := BaseX;
 ComposerInputFields[3].Y := BaseY;
 ComposerInputFields[3].Width := COMPOSER_WIDTH - COMPOSER_LABEL_WIDTH - 30;
 ComposerInputFields[3].MaxLen := 80;
 ComposerInputFields[3].Value := Composer.SubjectField;
 ComposerInputFields[3].IsPassword := False;
 ComposerInputFields[3].IsFocused := False;
 ComposerInputFields[3].CursorPos := Length(Composer.SubjectField);
 ComposerInputFields[3].Label_ := 'Objet:';

 ComposerFocusedField := COMP_FIELD_TO;
End;

{ Sauvegarde les valeurs des champs d'en-tete }
Procedure SaveComposerFields;
Begin
 Composer.ToField := ComposerInputFields[0].Value;
 Composer.CcField := ComposerInputFields[1].Value;
 Composer.BccField := ComposerInputFields[2].Value;
 Composer.SubjectField := ComposerInputFields[3].Value;
End;

{ Dessine un bouton de formatage }
Procedure DrawFormatButton(X, Y, W, H: Integer; Caption: String; Pressed: Boolean);
Begin
 { Fond du bouton }
 If Pressed Then
  GSetFillStyle(SolidFill, COLOR_LIST_SELECTED)
 Else
  GSetFillStyle(SolidFill, COLOR_BUTTON_FACE);
 GBar(X, Y, X + W, Y + H);

 { Relief 3D }
 Draw3DRect(X, Y, X + W, Y + H, Not Pressed);

 { Texte centre }
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(X + (W - GTextWidth(Caption)) Div 2, Y + (H - GTextHeight(Caption)) Div 2, Caption);
End;

{ Dessine la barre d'outils de formatage }
Procedure DrawComposerToolbar;
Var
 ToolbarY, BtnX: Integer;
Begin
 ToolbarY := COMPOSER_Y + COMPOSER_HEADER_HEIGHT + 2;

 { Fond de la barre d'outils }
 GSetFillStyle(SolidFill, COLOR_BUTTON_FACE);
 GBar(COMPOSER_X + 2, ToolbarY, COMPOSER_X + COMPOSER_WIDTH - 2, ToolbarY + COMPOSER_TOOLBAR_HEIGHT - 2);

 { Bordure }
 GSetColor(COLOR_BUTTON_DARK);
 GLine(COMPOSER_X + 2, ToolbarY + COMPOSER_TOOLBAR_HEIGHT - 1,
      COMPOSER_X + COMPOSER_WIDTH - 2, ToolbarY + COMPOSER_TOOLBAR_HEIGHT - 1);

 { Boutons de formatage }
 BtnX := COMPOSER_X + 8;

 { Bouton Gras (B) }
 DrawFormatButton(BtnX, ToolbarY + 3, 24, 20, 'B', ComposerFormatBold);
 BtnX := BtnX + 28;

 { Bouton Italique (I) }
 DrawFormatButton(BtnX, ToolbarY + 3, 24, 20, 'I', ComposerFormatItalic);
 BtnX := BtnX + 28;

 { Bouton Souligne (S) }
 DrawFormatButton(BtnX, ToolbarY + 3, 24, 20, 'S', ComposerFormatUnderline);
 BtnX := BtnX + 35;

 { Separateur }
 GSetColor(COLOR_BUTTON_DARK);
 GLine(BtnX, ToolbarY + 5, BtnX, ToolbarY + COMPOSER_TOOLBAR_HEIGHT - 7);
 GSetColor(COLOR_BUTTON_LIGHT);
 GLine(BtnX + 1, ToolbarY + 5, BtnX + 1, ToolbarY + COMPOSER_TOOLBAR_HEIGHT - 7);

 { Etiquette couleur }
 BtnX := BtnX + 10;
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(BtnX, ToolbarY + 8, 'Couleur:');
 BtnX := BtnX + 55;

 { Bouton couleur noire }
 GSetFillStyle(SolidFill, Black);
 GBar(BtnX, ToolbarY + 5, BtnX + 16, ToolbarY + 18);
 GSetColor(COLOR_BUTTON_DARK);
 GRectangle(BtnX, ToolbarY + 5, BtnX + 16, ToolbarY + 18);
 BtnX := BtnX + 20;

 { Bouton couleur rouge }
 GSetFillStyle(SolidFill, LightRed);
 GBar(BtnX, ToolbarY + 5, BtnX + 16, ToolbarY + 18);
 GSetColor(COLOR_BUTTON_DARK);
 GRectangle(BtnX, ToolbarY + 5, BtnX + 16, ToolbarY + 18);
 BtnX := BtnX + 20;

 { Bouton couleur verte }
 GSetFillStyle(SolidFill, LightGreen);
 GBar(BtnX, ToolbarY + 5, BtnX + 16, ToolbarY + 18);
 GSetColor(COLOR_BUTTON_DARK);
 GRectangle(BtnX, ToolbarY + 5, BtnX + 16, ToolbarY + 18);
 BtnX := BtnX + 20;

 { Bouton couleur bleue }
 GSetFillStyle(SolidFill, LightBlue);
 GBar(BtnX, ToolbarY + 5, BtnX + 16, ToolbarY + 18);
 GSetColor(COLOR_BUTTON_DARK);
 GRectangle(BtnX, ToolbarY + 5, BtnX + 16, ToolbarY + 18);
End;

{ Dessine un champ de saisie du compositeur }
Procedure DrawComposerField(Var Field: TInputField);
Var
 DisplayText: String;
Begin
 { Etiquette a gauche }
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(COMPOSER_X + 10, Field.Y + 4, Field.Label_);

 { Fond du champ }
 If Field.IsFocused Then
  GSetFillStyle(SolidFill, COLOR_LIST_BG)
 Else
  GSetFillStyle(SolidFill, COLOR_WINDOW_BG);
 GBar(Field.X, Field.Y, Field.X + Field.Width, Field.Y + COMPOSER_FIELD_HEIGHT);

 { Bordure 3D inversee }
 Draw3DRect(Field.X, Field.Y, Field.X + Field.Width, Field.Y + COMPOSER_FIELD_HEIGHT, False);

 { Texte }
 DisplayText := Field.Value;
 { Tronquer si trop long }
 While GTextWidth(DisplayText) > Field.Width - 8 Do
  Delete(DisplayText, 1, 1);

 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(Field.X + 4, Field.Y + 4, DisplayText);

 { Curseur si actif }
 If Field.IsFocused And ComposerCursorVisible Then Begin
  GSetColor(COLOR_MENU_TEXT);
  GLine(Field.X + 4 + GTextWidth(DisplayText), Field.Y + 3,
       Field.X + 4 + GTextWidth(DisplayText), Field.Y + COMPOSER_FIELD_HEIGHT - 3);
 End;
End;

{ Dessine la zone d'edition du compositeur }
Procedure DrawComposerEditor;
Var
 EditorX, EditorY, EditorW, EditorH: Integer;
 I, LineY, VisibleLine: Integer;
 DisplayText: String;
 LineFormat: TTextFormat;
Begin
 EditorX := COMPOSER_X + 4;
 EditorY := COMPOSER_Y + COMPOSER_HEADER_HEIGHT + COMPOSER_TOOLBAR_HEIGHT + 4;
 EditorW := COMPOSER_WIDTH - 8;
 EditorH := COMPOSER_HEIGHT - COMPOSER_HEADER_HEIGHT - COMPOSER_TOOLBAR_HEIGHT - 45;

 { Fond de l'editeur }
 GSetFillStyle(SolidFill, COLOR_LIST_BG);
 GBar(EditorX, EditorY, EditorX + EditorW, EditorY + EditorH);

 { Bordure 3D }
 Draw3DRect(EditorX, EditorY, EditorX + EditorW, EditorY + EditorH, False);

 { Dessiner les lignes de texte }
 LineY := EditorY + 4;
 For I := 0 To COMPOSER_EDITOR_VISIBLE_ROWS - 1 Do Begin
  VisibleLine := Composer.ScrollY + I;
  If VisibleLine < Composer.LineCount Then Begin
   DisplayText := Composer.Lines[VisibleLine].Text;
   LineFormat := Composer.Lines[VisibleLine].Format;

   { Appliquer le defilement horizontal }
   If Composer.ScrollX > 0 Then Begin
    If Length(DisplayText) > Composer.ScrollX Then
     Delete(DisplayText, 1, Composer.ScrollX)
    Else
     DisplayText := '';
   End;

   { Tronquer si trop long }
   If Length(DisplayText) > COMPOSER_EDITOR_VISIBLE_COLS Then
    DisplayText := Copy(DisplayText, 1, COMPOSER_EDITOR_VISIBLE_COLS);

   { Appliquer le formatage }
   GSetColor(LineFormat.FontColor);
   { Note: Le formatage gras/italique/souligne necessiterait
     des polices differentes, simplifie ici }
   GOutTextXY(EditorX + 4, LineY, DisplayText);
  End;
  LineY := LineY + 14;
 End;

 { Dessiner le curseur si dans l'editeur }
 If (ComposerFocusedField = COMP_FIELD_BODY) And ComposerCursorVisible Then Begin
  If (Composer.CursorY >= Composer.ScrollY) And
     (Composer.CursorY < Composer.ScrollY + COMPOSER_EDITOR_VISIBLE_ROWS) Then Begin
   LineY := EditorY + 4 + (Composer.CursorY - Composer.ScrollY) * 14;
   DisplayText := Copy(Composer.Lines[Composer.CursorY].Text, Composer.ScrollX + 1,
                       Composer.CursorX - Composer.ScrollX);
   GSetColor(COLOR_MENU_TEXT);
   GLine(EditorX + 4 + GTextWidth(DisplayText), LineY,
        EditorX + 4 + GTextWidth(DisplayText), LineY + 12);
  End;
 End;
End;

{ Dessine les boutons d'action du compositeur }
Procedure DrawComposerButtons;
Var
 BtnY, BtnX: Integer;
Begin
 BtnY := COMPOSER_Y + COMPOSER_HEIGHT - 30;

 { Bouton Envoyer }
 BtnX := COMPOSER_X + 10;
 DrawDialogButton(BtnX, BtnY, 80, 22, 'Envoyer', False, True);

 { Bouton Brouillon }
 BtnX := BtnX + 90;
 DrawDialogButton(BtnX, BtnY, 80, 22, 'Brouillon', False, True);

 { Bouton Annuler }
 BtnX := COMPOSER_X + COMPOSER_WIDTH - 90;
 DrawDialogButton(BtnX, BtnY, 80, 22, 'Annuler', False, True);
End;

{ Dessine la fenetre complete du compositeur }
Procedure DrawComposerWindow;
Var
 Title: String;
 I: Integer;
Begin
 If Not ComposerVisible Then Exit;

 HideMouse;

 { Titre selon l'etat }
 Case Composer.State Of
  csNew:      Title := 'Nouveau message';
  csReply:    Title := 'Re: ' + Composer.SubjectField;
  csReplyAll: Title := 'Re: ' + Composer.SubjectField;
  csForward:  Title := 'Fwd: ' + Composer.SubjectField;
  csDraft:    Title := 'Brouillon';
  Else        Title := 'Message';
 End;

 { Dessiner la boite de dialogue }
 DrawDialogBox(COMPOSER_X, COMPOSER_Y, COMPOSER_WIDTH, COMPOSER_HEIGHT, Title);

 { Dessiner les champs d'en-tete }
 For I := 0 To 3 Do
  DrawComposerField(ComposerInputFields[I]);

 { Barre d'outils de formatage }
 DrawComposerToolbar;

 { Zone d'edition }
 DrawComposerEditor;

 { Boutons d'action }
 DrawComposerButtons;

 ShowMouse;
End;

{ Ouvre le compositeur pour un nouveau message }
Procedure OpenNewMessage;
Begin
 InitializeComposer;
 Composer.State := csNew;
 ComposerVisible := True;
 InitComposerFields;
 DrawComposerWindow;
End;

{ Ouvre le compositeur pour une reponse }
Procedure OpenReplyMessage(ReplyAll: Boolean);
Var
 OrigMsg: TMessage; I: Integer; Prefix: String;
Begin
 If SelectedMessage < 0 Then Exit;

 InitializeComposer;
 OrigMsg := Messages^[SelectedMessage];

 { Preparer l'en-tete }
 Composer.ToField := OrigMsg.FromEmail;
 If ReplyAll Then Begin
  Composer.CcField := OrigMsg.CcEmail;
  Composer.State := csReplyAll;
 End
 Else
  Composer.State := csReply;

 { Objet avec Re: }
 If Pos('Re:', OrigMsg.Subject) <> 1 Then
  Composer.SubjectField := 'Re: ' + OrigMsg.Subject
 Else
  Composer.SubjectField := OrigMsg.Subject;

 Composer.OriginalMsgID := OrigMsg.MsgID;

 { Preparer le corps avec citation }
 Composer.Lines[0].Text := '';
 Composer.Lines[1].Text := '--- Message original ---';
 Composer.Lines[2].Text := 'De: ' + OrigMsg.FromName + ' <' + OrigMsg.FromEmail + '>';
 Composer.Lines[3].Text := 'Date: ' + OrigMsg.DateFull;
 Composer.Lines[4].Text := 'Objet: ' + OrigMsg.Subject;
 Composer.Lines[5].Text := '';
 Composer.LineCount := 6;
 If (Not OptionsReady) Or UserPrefs.Composing.IncludeOriginal Then Begin
  Prefix:='> '; If OptionsReady Then Prefix:=UserPrefs.Composing.QuotePrefix;
  For I:=0 To OrigMsg.BodyLineCount-1 Do Begin
   Composer.Lines[Composer.LineCount].Text:=Prefix+OrigMsg.Body[I]; Inc(Composer.LineCount);
  End;
 End Else Begin Composer.LineCount:=1; Composer.Lines[0].Text:=''; End;

 ComposerVisible := True;
 InitComposerFields;
 DrawComposerWindow;
End;

{ Ouvre le compositeur pour un transfert }
Procedure OpenForwardMessage;
Var
 OrigMsg: TMessage;
Begin
 If SelectedMessage < 0 Then Exit;

 InitializeComposer;
 OrigMsg := Messages^[SelectedMessage];

 Composer.State := csForward;

 { Objet avec Fwd: }
 If Pos('Fwd:', OrigMsg.Subject) <> 1 Then
  Composer.SubjectField := 'Fwd: ' + OrigMsg.Subject
 Else
  Composer.SubjectField := OrigMsg.Subject;

 Composer.OriginalMsgID := OrigMsg.MsgID;

 { Preparer le corps avec le message original }
 Composer.Lines[0].Text := '';
 Composer.Lines[1].Text := '---------- Message transfere ----------';
 Composer.Lines[2].Text := 'De: ' + OrigMsg.FromName + ' <' + OrigMsg.FromEmail + '>';
 Composer.Lines[3].Text := 'Date: ' + OrigMsg.DateFull;
 Composer.Lines[4].Text := 'A: ' + OrigMsg.ToEmail;
 Composer.Lines[5].Text := 'Objet: ' + OrigMsg.Subject;
 Composer.Lines[6].Text := '';
 Composer.LineCount := 7;

 ComposerVisible := True;
 InitComposerFields;
 DrawComposerWindow;
End;

{ Ferme le compositeur }
Procedure CloseComposer;
Begin
 ComposerVisible := False;
 DrawInterface;
End;

{ Sauvegarde le message comme brouillon }
Procedure SaveDraft;
Begin
 SaveComposerFields;
 { Ici on sauvegarderait le brouillon }
 { Pour l'instant, afficher un message }
 HideMouse;
 FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
          Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
 GSetColor(COLOR_STATUS_TEXT);
 GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
           'Brouillon enregistre                ');
 ShowMouse;
 Composer.Modified := False;
End;

{ ====================================================================== }
{  OS/2-0 : envoi SMTP depuis le tampon d'ecriture (messages de plus de   }
{  255 caracteres) et source du brouillon                                }
{ ====================================================================== }

{ date de l'en-tete Date: (RFC 5322) }
Function OlRfcDate : String;
Const
 Dn : Array[0..6] Of String[3] = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
 Mn : Array[1..12] Of String[3] = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
                                   'Nov', 'Dec');
Var Y, M, D, W, H, Mi, S, S100 : Word; T : String;
 Function Two(V : Word) : String;
 Var R : String;
 Begin
  Str(V, R);
  If Length(R) < 2 Then R := '0' + R;
  Two := R;
 End;
Begin
 GetDate(Y, M, D, W); GetTime(H, Mi, S, S100);
 If W > 6 Then W := 0;
 If (M < 1) Or (M > 12) Then M := 1;
 Str(Y, T);
 OlRfcDate := Dn[W] + ', ' + Two(D) + ' ' + Mn[M] + ' ' + T + ' ' + Two(H) + ':' + Two(Mi) + ':' + Two(S) +
              ' +0000';
End;

{ DATA : contenu de OlSv[OlSvBase..OlSvLen[ ; points doubles en debut de ligne }
Function SMTP_DataBuf: Integer;
Var Response: TSMTPResponse; Chunk: String; I: LongInt; C: Byte; LineStart: Boolean;
Begin
 If SMTPClient.State < ssRcptTo Then Begin
  SMTPClient.LastError := 'RCPT TO requis d''abord'; SMTP_DataBuf := SMTP_ERR_DATA; Exit;
 End;
 If SMTPClient.RcptAccepted = 0 Then Begin
  SMTPClient.LastError := 'Aucun destinataire accepte'; SMTP_DataBuf := SMTP_ERR_NO_RECIPIENTS; Exit;
 End;
 Response := SMTP_SendCommand('DATA');
 If Response.Code <> SMTP_CODE_START_MAIL Then Begin
  SMTPClient.LastError := 'DATA echoue: ' + Response.Text; SMTP_DataBuf := SMTP_ERR_DATA; Exit;
 End;
 SMTPClient.State := ssData;
 Chunk := ''; LineStart := True;
 For I := OlSvBase To OlSvLen - 1 Do Begin
  C := OlSv^[I];
  If LineStart And (C = Ord('.')) Then Chunk := Chunk + '.';
  Chunk := Chunk + Chr(C);
  LineStart := C = 10;
  If Length(Chunk) >= 240 Then Begin
   If Not MailWrite(SMTPWire, Chunk) Then Begin
    SMTPClient.LastError := MailError; SMTP_DataBuf := SMTP_ERR_SEND; Exit;
   End;
   Chunk := '';
  End;
 End;
 If Not LineStart Then Chunk := Chunk + #13#10;
 If Not MailWrite(SMTPWire, Chunk + '.'#13#10) Then Begin
  SMTPClient.LastError := MailError; SMTP_DataBuf := SMTP_ERR_SEND; Exit;
 End;
 Response := SMTP_SendCommand('');
 If Response.Code = SMTP_CODE_OK Then Begin
  SMTPClient.State := ssAuthenticated; SMTP_DataBuf := SMTP_OK;
 End Else Begin
  SMTPClient.LastError := 'Envoi echoue: ' + Response.Text; SMTP_DataBuf := SMTP_ERR_SEND;
 End;
End;

{ ComposerMessageSource dans le tampon d'ecriture }
Procedure OlComposerSource;
Var A, I: Integer;
Begin
 SaveComposerFields;
 A := Composer.AccountIndex;
 If (A < 0) And (SelectedFolder >= 0) And (SelectedFolder < FolderCount) Then A := MailFolderAccount[SelectedFolder];
 If A < 0 Then For I := 0 To EmailAccountCount - 1 Do If EmailAccounts[I].IsDefault Then A := I;
 OlSvClear;
 If (A >= 0) And (A < EmailAccountCount) Then OlSvAdd('From: ' + EmailAccounts[A].EmailAddress + #13#10);
 OlSvAdd('To: ' + Composer.ToField + #13#10);
 If Composer.CcField <> '' Then OlSvAdd('Cc: ' + Composer.CcField + #13#10);
 If Composer.BccField <> '' Then OlSvAdd('Bcc: ' + Composer.BccField + #13#10);
 OlSvAdd('Subject: ' + OlTo1252(Composer.SubjectField) + #13#10 + 'MIME-Version: 1.0'#13#10 +
         'Content-Type: text/plain; charset=windows-1252'#13#10 + 'Content-Transfer-Encoding: 8bit'#13#10#13#10);
 For I := 0 To Composer.LineCount - 1 Do OlSvAdd(OlTo1252(Composer.Lines[I].Text) + #13#10);
End;

{ Envoie le message }
{ Traiter les destinataires To/Cc/Bcc sans annoncer un succes avant DATA 250. }
Function MailRecipients(List: TMailText): Boolean;
Var P, Q: LongInt; Address: TMailText;
Begin
 MailRecipients:=False;
 While List<>'' Do Begin
  P:=1; While (P<=Length(List)) And Not (List[P] In [',',';']) Do Inc(P);
  Address:=MailTrim(Copy(List,1,P-1)); Delete(List,1,P);
  If Address<>'' Then Begin
   P:=Pos('<',Address); Q:=Pos('>',Address);
   If (P>0) And (Q>P) Then Address:=Copy(Address,P+1,Q-P-1);
   If (Length(Address)>60) Or Not MailSafe(Address) Then Begin MailError:='Destinataire invalide'; Exit; End;
   If SMTP_RcptTo(Address)<>SMTP_OK Then Begin MailError:='Destinataire refuse: '+Copy(Address,1,55); Exit; End;
  End;
 End;
 MailRecipients:=True;
End;

Procedure SendMessageWork;
Var A, I: Integer; Body: TMailText; OK: Boolean;
Begin
 SaveComposerFields;
 MailError:=''; A:=Composer.AccountIndex;
 If (A<0) And (SelectedFolder>=0) And (SelectedFolder<FolderCount) Then A:=MailFolderAccount[SelectedFolder];
 If A<0 Then For I:=0 To EmailAccountCount-1 Do
  If EmailAccounts[I].IsDefault Then A:=I;
 If A<0 Then Begin MailStatus:='Configurez un compte avant envoi'; DrawStatusBar; Exit; End;
 If Composer.ToField='' Then Begin MailStatus:='Destinataire requis'; DrawStatusBar; Exit; End;
 If Composer.AttachmentCount>0 Then Begin
  MailStatus:='Envoi des pieces jointes non implemente'; DrawStatusBar; Exit;
 End;
 If Not MailSafe(Composer.SubjectField) Or Not MailSafe(Composer.ToField) Or
    Not MailSafe(Composer.CcField) Or Not MailSafe(Composer.BccField) Or
    Not MailSafe(EmailAccounts[A].EmailAddress) Then Begin
  MailStatus:=MailError; DrawStatusBar; Exit;
 End;
 BusyBegin('Envoi du message',EmailAccounts[A].OutgoingHost);
 OK:=OpenOutgoingAccount(EmailAccounts[A]);
 If OK Then BusyStage('Envoi du message et attente de confirmation SMTP...');
 If OK Then OK:=SMTP_MailFrom(EmailAccounts[A].EmailAddress)=SMTP_OK;
 If OK Then OK:=MailRecipients(Composer.ToField);
 If OK Then OK:=MailRecipients(Composer.CcField);
 If OK Then OK:=MailRecipients(Composer.BccField);
 If OK Then Begin
  OlSvPush;
  OlSvAdd('From: '+EmailAccounts[A].EmailAddress+#13#10+'To: '+Composer.ToField+#13#10);
  If Composer.CcField<>'' Then OlSvAdd('Cc: '+Composer.CcField+#13#10);
  OlSvAdd('Subject: '+OlTo1252(Composer.SubjectField)+#13#10+'Date: '+OlRfcDate+#13#10+
   'MIME-Version: 1.0'#13#10'Content-Type: text/plain; charset=windows-1252'#13#10+
   'Content-Transfer-Encoding: 8bit'#13#10'X-Mailer: Outlink pour OS/2-0'#13#10#13#10);
  For I:=0 To Composer.LineCount-1 Do OlSvAdd(OlTo1252(Composer.Lines[I].Text)+#13#10);
  OK:=SMTP_DataBuf=SMTP_OK;
  OlSvPop;
 End;
 If OK Then Begin MailStatus:='Message accepte par le serveur SMTP'; MailClose(SMTPWire); CloseComposer; End
 Else Begin
  If MailError='' Then MailError:=SMTPClient.LastError;
  MailStatus:='Echec envoi: '+MailError; MailClose(SMTPWire); DrawStatusBar;
 End;
End;

Procedure SendMessage;
Begin
 If BusyVisible Then Exit;
 SendMessageWork;
 BusyEnd;
End;

{ Gere les clics dans le compositeur }
Procedure HandleComposerClick(X, Y: Integer);
Var
 I, BtnX, BtnY, ToolbarY: Integer;
 EditorX, EditorY, EditorW, EditorH: Integer;
 ClickedLine: Integer;
Begin
 If Not ComposerVisible Then Exit;

 { Le compositeur conserve le focus, meme lors d un clic a l exterieur. }
 If (X < COMPOSER_X) Or (X > COMPOSER_X + COMPOSER_WIDTH) Or
    (Y < COMPOSER_Y) Or (Y > COMPOSER_Y + COMPOSER_HEIGHT) Then Exit;

 { Verifier les boutons d'action }
 BtnY := COMPOSER_Y + COMPOSER_HEIGHT - 30;

 { Bouton Envoyer }
 BtnX := COMPOSER_X + 10;
 If (X >= BtnX) And (X <= BtnX + 80) And (Y >= BtnY) And (Y <= BtnY + 22) Then Begin
  SendMessage;
  Exit;
 End;

 { Bouton Brouillon }
 BtnX := BtnX + 90;
 If (X >= BtnX) And (X <= BtnX + 80) And (Y >= BtnY) And (Y <= BtnY + 22) Then Begin
  SaveDraft;
  Exit;
 End;

 { Bouton Annuler }
 BtnX := COMPOSER_X + COMPOSER_WIDTH - 90;
 If (X >= BtnX) And (X <= BtnX + 80) And (Y >= BtnY) And (Y <= BtnY + 22) Then Begin
  CloseComposer;
  Exit;
 End;

 { Verifier les champs d'en-tete }
 For I := 0 To 3 Do Begin
  If (X >= ComposerInputFields[I].X) And
     (X <= ComposerInputFields[I].X + ComposerInputFields[I].Width) And
     (Y >= ComposerInputFields[I].Y) And
     (Y <= ComposerInputFields[I].Y + COMPOSER_FIELD_HEIGHT) Then Begin
   { Deselectionner tous les champs }
   ComposerInputFields[0].IsFocused := False;
   ComposerInputFields[1].IsFocused := False;
   ComposerInputFields[2].IsFocused := False;
   ComposerInputFields[3].IsFocused := False;
   { Selectionner ce champ }
   ComposerInputFields[I].IsFocused := True;
   ComposerFocusedField := I;
   DrawComposerWindow;
   Exit;
  End;
 End;

 { Verifier la barre d'outils de formatage }
 ToolbarY := COMPOSER_Y + COMPOSER_HEADER_HEIGHT + 2;
 If (Y >= ToolbarY) And (Y <= ToolbarY + COMPOSER_TOOLBAR_HEIGHT) Then Begin
  BtnX := COMPOSER_X + 8;

  { Bouton Gras }
  If (X >= BtnX) And (X <= BtnX + 24) Then Begin
   ComposerFormatBold := Not ComposerFormatBold;
   Composer.CurrentFormat.Bold := ComposerFormatBold;
   DrawComposerWindow;
   Exit;
  End;
  BtnX := BtnX + 28;

  { Bouton Italique }
  If (X >= BtnX) And (X <= BtnX + 24) Then Begin
   ComposerFormatItalic := Not ComposerFormatItalic;
   Composer.CurrentFormat.Italic := ComposerFormatItalic;
   DrawComposerWindow;
   Exit;
  End;
  BtnX := BtnX + 28;

  { Bouton Souligne }
  If (X >= BtnX) And (X <= BtnX + 24) Then Begin
   ComposerFormatUnderline := Not ComposerFormatUnderline;
   Composer.CurrentFormat.Underline := ComposerFormatUnderline;
   DrawComposerWindow;
   Exit;
  End;

  { Boutons de couleur }
  BtnX := COMPOSER_X + 8 + 28 + 28 + 35 + 10 + 55;
  If (X >= BtnX) And (X <= BtnX + 16) Then Begin
   Composer.CurrentFormat.FontColor := Black;
   DrawComposerWindow;
   Exit;
  End;
  BtnX := BtnX + 20;
  If (X >= BtnX) And (X <= BtnX + 16) Then Begin
   Composer.CurrentFormat.FontColor := LightRed;
   DrawComposerWindow;
   Exit;
  End;
  BtnX := BtnX + 20;
  If (X >= BtnX) And (X <= BtnX + 16) Then Begin
   Composer.CurrentFormat.FontColor := LightGreen;
   DrawComposerWindow;
   Exit;
  End;
  BtnX := BtnX + 20;
  If (X >= BtnX) And (X <= BtnX + 16) Then Begin
   Composer.CurrentFormat.FontColor := LightBlue;
   DrawComposerWindow;
   Exit;
  End;
 End;

 { Verifier la zone d'edition }
 EditorX := COMPOSER_X + 4;
 EditorY := COMPOSER_Y + COMPOSER_HEADER_HEIGHT + COMPOSER_TOOLBAR_HEIGHT + 4;
 EditorW := COMPOSER_WIDTH - 8;
 EditorH := COMPOSER_HEIGHT - COMPOSER_HEADER_HEIGHT - COMPOSER_TOOLBAR_HEIGHT - 45;

 If (X >= EditorX) And (X <= EditorX + EditorW) And
    (Y >= EditorY) And (Y <= EditorY + EditorH) Then Begin
  { Clic dans l'editeur }
  ComposerFocusedField := COMP_FIELD_BODY;

  { Deselectionner les champs d'en-tete }
  ComposerInputFields[0].IsFocused := False;
  ComposerInputFields[1].IsFocused := False;
  ComposerInputFields[2].IsFocused := False;
  ComposerInputFields[3].IsFocused := False;

  { Calculer la ligne cliquee }
  ClickedLine := Composer.ScrollY + (Y - EditorY - 4) Div 14;
  If ClickedLine >= Composer.LineCount Then
   ClickedLine := Composer.LineCount - 1;
  If ClickedLine < 0 Then ClickedLine := 0;
  Composer.CursorY := ClickedLine;

  { Positionner le curseur X approximativement }
  Composer.CursorX := Length(Composer.Lines[ClickedLine].Text);

  DrawComposerWindow;
 End;
End;

{ Gere les touches clavier dans le compositeur }
Procedure HandleComposerKeyPress(Key: Char);
Var
 FieldValue: String;
 CurrentLine: String;
Begin
 If Not ComposerVisible Then Exit;

 If Key = #27 Then Begin { Escape }
  CloseComposer;
  Exit;
 End;

 { Gestion selon le champ actif }
 If ComposerFocusedField < COMP_FIELD_BODY Then Begin
  { Champs d'en-tete }
  FieldValue := ComposerInputFields[ComposerFocusedField].Value;

  If Key = #8 Then Begin { Backspace }
   If Length(FieldValue) > 0 Then Begin
    Delete(FieldValue, Length(FieldValue), 1);
    ComposerInputFields[ComposerFocusedField].Value := FieldValue;
    Composer.Modified := True;
    DrawComposerWindow;
   End;
  End
  Else If Key = #9 Then Begin { Tab }
   ComposerInputFields[ComposerFocusedField].IsFocused := False;
   Inc(ComposerFocusedField);
   If ComposerFocusedField > COMP_FIELD_SUBJECT Then
    ComposerFocusedField := COMP_FIELD_BODY
   Else
    ComposerInputFields[ComposerFocusedField].IsFocused := True;
   DrawComposerWindow;
  End
  Else If Key = #13 Then Begin { Enter - passer au corps }
   ComposerInputFields[ComposerFocusedField].IsFocused := False;
   ComposerFocusedField := COMP_FIELD_BODY;
   DrawComposerWindow;
  End
  Else If (((Key >= ' ') And (Key <= '~')) Or (Key >= #128)) Then Begin { Caracteres imprimables }
   If Length(FieldValue) < ComposerInputFields[ComposerFocusedField].MaxLen Then Begin
    FieldValue := FieldValue + Key;
    ComposerInputFields[ComposerFocusedField].Value := FieldValue;
    Composer.Modified := True;
    DrawComposerWindow;
   End;
  End;
 End
 Else Begin
  { Zone d'edition du corps }
  CurrentLine := Composer.Lines[Composer.CursorY].Text;

  If Key = #8 Then Begin { Backspace }
   If Composer.CursorX > 0 Then Begin
    Delete(CurrentLine, Composer.CursorX, 1);
    Composer.Lines[Composer.CursorY].Text := CurrentLine;
    Dec(Composer.CursorX);
    Composer.Modified := True;
    DrawComposerWindow;
   End
   Else If Composer.CursorY > 0 Then Begin
    { Fusionner avec la ligne precedente }
    Dec(Composer.CursorY);
    Composer.CursorX := Length(Composer.Lines[Composer.CursorY].Text);
    Composer.Lines[Composer.CursorY].Text := Composer.Lines[Composer.CursorY].Text + CurrentLine;
    { Decaler les lignes suivantes }
    While Composer.CursorY + 1 < Composer.LineCount - 1 Do Begin
     Composer.Lines[Composer.CursorY + 1] := Composer.Lines[Composer.CursorY + 2];
     Inc(Composer.CursorY);
    End;
    Dec(Composer.LineCount);
    Composer.CursorY := Composer.CursorY - (Composer.LineCount - Composer.CursorY - 1);
    Composer.Modified := True;
    DrawComposerWindow;
   End;
  End
  Else If Key = #13 Then Begin { Enter - nouvelle ligne }
   If Composer.LineCount < COMPOSER_MAX_LINES Then Begin
    { Decaler les lignes suivantes }
    If Composer.CursorY < Composer.LineCount - 1 Then Begin
     { Note: Simplifie - insere une nouvelle ligne }
    End;
    Inc(Composer.LineCount);
    Inc(Composer.CursorY);
    Composer.CursorX := 0;
    Composer.Lines[Composer.CursorY].Text := '';
    Composer.Lines[Composer.CursorY].Format := Composer.CurrentFormat;
    Composer.Modified := True;

    { Ajuster le defilement si necessaire }
    If Composer.CursorY >= Composer.ScrollY + COMPOSER_EDITOR_VISIBLE_ROWS Then
     Inc(Composer.ScrollY);

    DrawComposerWindow;
   End;
  End
  Else If Key = #9 Then Begin { Tab - retour aux champs d'en-tete }
   ComposerFocusedField := COMP_FIELD_TO;
   ComposerInputFields[COMP_FIELD_TO].IsFocused := True;
   DrawComposerWindow;
  End
  Else If (((Key >= ' ') And (Key <= '~')) Or (Key >= #128)) Then Begin { Caracteres imprimables }
   If Length(CurrentLine) < 250 Then Begin
    Insert(Key, CurrentLine, Composer.CursorX + 1);
    Composer.Lines[Composer.CursorY].Text := CurrentLine;
    Composer.Lines[Composer.CursorY].Format := Composer.CurrentFormat;
    Inc(Composer.CursorX);
    Composer.Modified := True;
    DrawComposerWindow;
   End;
  End;
 End;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DU COMPOSITEUR DE MESSAGES
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU SUPPORT DES PIECES JOINTES (TODO 13)
  ============================================================================ }

{ Initialise les extensions dangereuses }
Procedure InitDangerousExtensions;
Begin
 DangerousExtensions[0] := 'EXE';
 DangerousExtensions[1] := 'COM';
 DangerousExtensions[2] := 'BAT';
 DangerousExtensions[3] := 'CMD';
 DangerousExtensions[4] := 'SCR';
 DangerousExtensions[5] := 'PIF';
 DangerousExtensions[6] := 'VBS';
 DangerousExtensions[7] := 'JS';
 DangerousExtensions[8] := 'WSF';
 DangerousExtensions[9] := 'MSI';
 DangerousExtensions[10] := 'DLL';
 DangerousExtensions[11] := 'SYS';
End;

{ Initialise le gestionnaire de pieces jointes }
Procedure InitAttachmentManager;
Begin
 AttachPanelVisible := False;
 SelectedAttachment := -1;
 AttachFileBrowserVisible := False;
 AttachCurrentPath := '';
 AttachFileCount := 0;
 AttachSelectedFile := -1;
 AttachTotalSize := 0;
 InitDangerousExtensions;
End;

{ Extrait l'extension d'un nom de fichier }
Function GetFileExtension(FileName: String): String;
Var
 I: Integer;
 Ext: String;
Begin
 Ext := '';
 For I := Length(FileName) DownTo 1 Do Begin
  If FileName[I] = '.' Then Begin
   Ext := Copy(FileName, I + 1, Length(FileName) - I);
   Break;
  End;
 End;
 { Convertir en majuscules }
 For I := 1 To Length(Ext) Do
  If (Ext[I] >= 'a') And (Ext[I] <= 'z') Then
   Ext[I] := Chr(Ord(Ext[I]) - 32);
 GetFileExtension := Ext;
End;

{ Verifie si une extension est dangereuse }
Function IsDangerousExtension(Ext: String): Boolean;
Var
 I: Integer;
 UpperExt: String;
Begin
 IsDangerousExtension := False;
 UpperExt := Ext;
 { Convertir en majuscules }
 For I := 1 To Length(UpperExt) Do
  If (UpperExt[I] >= 'a') And (UpperExt[I] <= 'z') Then
   UpperExt[I] := Chr(Ord(UpperExt[I]) - 32);
 { Verifier contre la liste }
 For I := 0 To DANGEROUS_EXT_COUNT - 1 Do Begin
  If UpperExt = DangerousExtensions[I] Then Begin
   IsDangerousExtension := True;
   Exit;
  End;
 End;
End;

{ Determine le type de fichier d'apres l'extension }
Function GetAttachmentType(FileName: String): TAttachmentType;
Var
 Ext: String;
Begin
 Ext := GetFileExtension(FileName);

 { Documents }
 If (Ext = 'DOC') Or (Ext = 'DOCX') Or (Ext = 'TXT') Or
    (Ext = 'RTF') Or (Ext = 'ODT') Then
  GetAttachmentType := atDocument
 { Tableurs }
 Else If (Ext = 'XLS') Or (Ext = 'XLSX') Or (Ext = 'CSV') Or
         (Ext = 'ODS') Then
  GetAttachmentType := atSpreadsheet
 { Images }
 Else If (Ext = 'JPG') Or (Ext = 'JPEG') Or (Ext = 'PNG') Or
         (Ext = 'GIF') Or (Ext = 'BMP') Or (Ext = 'ICO') Then
  GetAttachmentType := atImage
 { Archives }
 Else If (Ext = 'ZIP') Or (Ext = 'RAR') Or (Ext = '7Z') Or
         (Ext = 'TAR') Or (Ext = 'GZ') Then
  GetAttachmentType := atArchive
 { Executables }
 Else If (Ext = 'EXE') Or (Ext = 'COM') Or (Ext = 'BAT') Or
         (Ext = 'CMD') Or (Ext = 'SCR') Then
  GetAttachmentType := atExecutable
 { Audio }
 Else If (Ext = 'MP3') Or (Ext = 'WAV') Or (Ext = 'OGG') Or
         (Ext = 'WMA') Or (Ext = 'FLAC') Then
  GetAttachmentType := atAudio
 { Video }
 Else If (Ext = 'AVI') Or (Ext = 'MPG') Or (Ext = 'MPEG') Or
         (Ext = 'MP4') Or (Ext = 'WMV') Or (Ext = 'MKV') Then
  GetAttachmentType := atVideo
 { PDF }
 Else If Ext = 'PDF' Then
  GetAttachmentType := atPDF
 Else
  GetAttachmentType := atUnknown;
End;

{ Formate une taille de fichier }
Function FormatFileSize(Size: LongInt): String;
Var
 S: String;
Begin
 If Size < 1024 Then
  Str(Size, S)
 Else If Size < 1048576 Then Begin
  Str(Size Div 1024, S);
  S := S + ' Ko';
 End
 Else Begin
  Str(Size Div 1048576, S);
  S := S + ' Mo';
 End;
 FormatFileSize := S;
End;

{ Dessine une icone de piece jointe selon son type }
Procedure DrawAttachmentIcon(X, Y: Integer; AttType: TAttachmentType);
Var
 IconColor: Word;
Begin
 { Couleur selon le type }
 Case AttType Of
  atDocument:   IconColor := LightCyan;
  atSpreadsheet: IconColor := LightGreen;
  atImage:      IconColor := LightMagenta;
  atArchive:    IconColor := Yellow;
  atExecutable: IconColor := LightRed;
  atAudio:      IconColor := LightBlue;
  atVideo:      IconColor := Cyan;
  atPDF:        IconColor := Red;
  Else          IconColor := LightGray;
 End;

 { Dessiner l'icone (rectangle avec coin plie) }
 GSetFillStyle(SolidFill, IconColor);
 GBar(X, Y, X + 24, Y + 28);
 GSetColor(COLOR_BUTTON_DARK);
 GRectangle(X, Y, X + 24, Y + 28);

 { Coin plie }
 GSetFillStyle(SolidFill, COLOR_WINDOW_BG);
 GSetColor(COLOR_BUTTON_DARK);
 GLine(X + 18, Y, X + 24, Y + 6);
 GLine(X + 18, Y, X + 18, Y + 6);
 GLine(X + 18, Y + 6, X + 24, Y + 6);

 { Symbole selon le type }
 GSetColor(Black);
 Case AttType Of
  atDocument:   GOutTextXY(X + 5, Y + 10, 'DOC');
  atSpreadsheet: GOutTextXY(X + 5, Y + 10, 'XLS');
  atImage:      GOutTextXY(X + 5, Y + 10, 'IMG');
  atArchive:    GOutTextXY(X + 5, Y + 10, 'ZIP');
  atExecutable: GOutTextXY(X + 5, Y + 10, 'EXE');
  atAudio:      GOutTextXY(X + 5, Y + 10, 'MP3');
  atVideo:      GOutTextXY(X + 5, Y + 10, 'VID');
  atPDF:        GOutTextXY(X + 5, Y + 10, 'PDF');
  Else          GOutTextXY(X + 5, Y + 10, '???');
 End;
End;

{ Dessine le panneau des pieces jointes dans le compositeur }
Procedure DrawAttachmentPanel;
Var
 PanelX, PanelY, PanelW, I: Integer;
 SizeStr: String;
Begin
 If Not ComposerVisible Then Exit;
 If Composer.AttachmentCount = 0 Then Exit;

 HideMouse;

 { Position du panneau }
 PanelX := COMPOSER_X + 4;
 PanelY := COMPOSER_Y + COMPOSER_HEADER_HEIGHT - ATTACH_PANEL_HEIGHT - 2;
 PanelW := COMPOSER_WIDTH - 8;

 { Fond du panneau }
 GSetFillStyle(SolidFill, COLOR_WINDOW_BG);
 GBar(PanelX, PanelY, PanelX + PanelW, PanelY + ATTACH_PANEL_HEIGHT);

 { Bordure }
 GSetColor(COLOR_BUTTON_DARK);
 GRectangle(PanelX, PanelY, PanelX + PanelW, PanelY + ATTACH_PANEL_HEIGHT);

 { Titre }
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(PanelX + 4, PanelY + 2, 'Pieces jointes:');

 { Dessiner les icones des pieces jointes }
 For I := 0 To Composer.AttachmentCount - 1 Do Begin
  DrawAttachmentIcon(PanelX + 90 + I * ATTACH_ICON_SPACING, PanelY + 2,
                     Composer.Attachments[I].FileType);

  { Avertissement si dangereux }
  If Composer.Attachments[I].IsDangerous Then Begin
   GSetColor(LightRed);
   GOutTextXY(PanelX + 90 + I * ATTACH_ICON_SPACING + 8, PanelY + 32, '!');
  End;
 End;

 { Taille totale }
 SizeStr := 'Total: ' + FormatFileSize(AttachTotalSize);
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(PanelX + PanelW - GTextWidth(SizeStr) - 10, PanelY + ATTACH_PANEL_HEIGHT - 14, SizeStr);

 ShowMouse;
End;

{ Ajoute une piece jointe au compositeur }
Function AddAttachment(FilePath: String): Boolean;
Var
 F: File;
 FileName: String;
 I: Integer;
 Ext: String;
Begin
 AddAttachment := False;

 { Verifier le nombre maximum }
 If Composer.AttachmentCount >= MAX_ATTACHMENTS Then Exit;

 { Extraire le nom du fichier }
 FileName := FilePath;
 For I := Length(FilePath) DownTo 1 Do Begin
  If (FilePath[I] = '\') Or (FilePath[I] = '/') Then Begin
   FileName := Copy(FilePath, I + 1, Length(FilePath) - I);
   Break;
  End;
 End;

 { Verifier si le fichier existe et obtenir sa taille }
 {$I-}
 Assign(F, FilePath);
 Reset(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 { Verifier la taille }
 If FileSize(F) > MAX_SINGLE_FILE_SIZE Then Begin
  Close(F);
  { Afficher avertissement taille }
  HideMouse;
  FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
           Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
  GSetColor(LightRed);
  GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
            'Erreur: Fichier trop volumineux (max 5 Mo)');
  ShowMouse;
  Exit;
 End;

 { Verifier la taille totale }
 If AttachTotalSize + System.FileSize(F) > MAX_ATTACHMENT_SIZE Then Begin
  Close(F);
  HideMouse;
  FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
           Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
  GSetColor(LightRed);
  GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
            'Erreur: Taille totale des pieces jointes depassee');
  ShowMouse;
  Exit;
 End;

 { Ajouter la piece jointe }
 { champs ecrits en entier, sans With : FileName et FilePath sont aussi
   ceux du parametre et de la variable locale }
 Begin
  Composer.Attachments[Composer.AttachmentCount].FileName := FileName;
  Composer.Attachments[Composer.AttachmentCount].FilePath := FilePath;
  Composer.Attachments[Composer.AttachmentCount].FileSize := System.FileSize(F);
  Composer.Attachments[Composer.AttachmentCount].FileType := GetAttachmentType(FileName);
  Composer.Attachments[Composer.AttachmentCount].IsEmbedded := False;
  Composer.Attachments[Composer.AttachmentCount].ContentID := '';

  { Verifier si extension dangereuse }
  Ext := GetFileExtension(FileName);
  Composer.Attachments[Composer.AttachmentCount].IsDangerous := IsDangerousExtension(Ext);
 End;

 AttachTotalSize := AttachTotalSize + System.FileSize(F);
 Close(F);

 Inc(Composer.AttachmentCount);
 Composer.Modified := True;

 { Afficher avertissement si dangereux }
 If Composer.Attachments[Composer.AttachmentCount - 1].IsDangerous Then Begin
  HideMouse;
  FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
           Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
  GSetColor(Yellow);
  GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
            'Attention: Extension potentiellement dangereuse!');
  ShowMouse;
 End;

 AddAttachment := True;
 DrawAttachmentPanel;
End;

{ Supprime une piece jointe du compositeur }
Procedure RemoveAttachment(Index: Integer);
Var
 I: Integer;
Begin
 If (Index < 0) Or (Index >= Composer.AttachmentCount) Then Exit;

 AttachTotalSize := AttachTotalSize - Composer.Attachments[Index].FileSize;

 { Decaler les pieces jointes suivantes }
 For I := Index To Composer.AttachmentCount - 2 Do
  Composer.Attachments[I] := Composer.Attachments[I + 1];

 Dec(Composer.AttachmentCount);
 Composer.Modified := True;

 If SelectedAttachment >= Composer.AttachmentCount Then
  SelectedAttachment := Composer.AttachmentCount - 1;

 DrawAttachmentPanel;
End;

{ Enregistre une piece jointe sur disque }
Function SaveAttachmentToDisk(Index: Integer; DestPath: String): Boolean;
Var
 SrcFile, DstFile: File;
 Buffer: Array[0..4095] of Byte;
 BytesRead: Integer;
Begin
 SaveAttachmentToDisk := False;

 If (Index < 0) Or (Index >= Composer.AttachmentCount) Then Exit;

 { Ouvrir le fichier source }
 {$I-}
 Assign(SrcFile, Composer.Attachments[Index].FilePath);
 Reset(SrcFile, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 { Creer le fichier destination }
 {$I-}
 Assign(DstFile, DestPath + '\' + Composer.Attachments[Index].FileName);
 Rewrite(DstFile, 1);
 {$I+}
 If IOResult <> 0 Then Begin
  Close(SrcFile);
  Exit;
 End;

 { Copier le contenu }
 Repeat
  BlockRead(SrcFile, Buffer, SizeOf(Buffer), BytesRead);
  If BytesRead > 0 Then
   BlockWrite(DstFile, Buffer, BytesRead);
 Until BytesRead = 0;

 Close(SrcFile);
 Close(DstFile);

 SaveAttachmentToDisk := True;

 { Confirmation }
 HideMouse;
 FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
          Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
 GSetColor(LightGreen);
 GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
           'Piece jointe enregistree avec succes');
 ShowMouse;
End;

{ Enregistre une piece jointe d'un message recu }
Function SaveReceivedAttachment(MsgIndex, AttachIndex: Integer; DestPath: String): Boolean;
Begin
 SaveReceivedAttachment := False;

 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;
 If (AttachIndex < 0) Or (AttachIndex >= Messages^[MsgIndex].AttachmentCount) Then Exit;

 { Note: Pour un vrai client, on telechargerait d'abord depuis le serveur }
 { Ici on simule l'operation }

 HideMouse;
 FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
          Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
 GSetColor(LightGreen);
 GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
           'Piece jointe enregistree: ' + Messages^[MsgIndex].Attachments[AttachIndex].FileName);
 ShowMouse;

 SaveReceivedAttachment := True;
End;

{ Dessine les pieces jointes d'un message dans le volet de preview }
Procedure DrawMessageAttachments(MsgIndex: Integer);
Var
 X, Y, I: Integer;
Begin
 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;
 If Not Messages^[MsgIndex].HasAttachment Then Exit;
 If Messages^[MsgIndex].AttachmentCount = 0 Then Exit;

 HideMouse;

 { Position sous les en-tetes }
 X := Layout.PreviewPaneRect.X1 + 10;
 Y := Layout.PreviewPaneRect.Y1 + PreviewHeaderHeight + 5;

 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(X, Y, 'Pieces jointes:');
 Y := Y + 16;

 { Dessiner les icones }
 For I := 0 To Messages^[MsgIndex].AttachmentCount - 1 Do Begin
  DrawAttachmentIcon(X + I * ATTACH_ICON_SPACING, Y,
                     Messages^[MsgIndex].Attachments[I].FileType);

  { Nom sous l'icone }
  GSetColor(COLOR_MENU_TEXT);
  If Length(Messages^[MsgIndex].Attachments[I].FileName) > 6 Then
   GOutTextXY(X + I * ATTACH_ICON_SPACING - 5, Y + 32,
             Copy(Messages^[MsgIndex].Attachments[I].FileName, 1, 6) + '..')
  Else
   GOutTextXY(X + I * ATTACH_ICON_SPACING, Y + 32,
             Messages^[MsgIndex].Attachments[I].FileName);
 End;

 ShowMouse;
End;

{ Gere le clic sur une piece jointe dans le compositeur }
Procedure HandleAttachmentClick(X, Y: Integer);
Var
 PanelX, PanelY, I, IconX: Integer;
Begin
 If Composer.AttachmentCount = 0 Then Exit;

 PanelX := COMPOSER_X + 4;
 PanelY := COMPOSER_Y + COMPOSER_HEADER_HEIGHT - ATTACH_PANEL_HEIGHT - 2;

 { Verifier le clic sur chaque icone }
 For I := 0 To Composer.AttachmentCount - 1 Do Begin
  IconX := PanelX + 90 + I * ATTACH_ICON_SPACING;
  If (X >= IconX) And (X <= IconX + 24) And
     (Y >= PanelY + 2) And (Y <= PanelY + 30) Then Begin
   SelectedAttachment := I;
   DrawAttachmentPanel;
   Exit;
  End;
 End;
End;

{ Reinitialise les pieces jointes du compositeur }
Procedure ClearComposerAttachments;
Begin
 Composer.AttachmentCount := 0;
 AttachTotalSize := 0;
 SelectedAttachment := -1;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DU SUPPORT DES PIECES JOINTES
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU MOTEUR DE RENDU HTML (TODO 14)
  ============================================================================ }

{ Convertit une chaine en majuscules }
Function HTML_UpperCase(S: String): String;
Var
 I: Integer;
Begin
 For I := 1 To Length(S) Do
  If (S[I] >= 'a') And (S[I] <= 'z') Then
   S[I] := Chr(Ord(S[I]) - 32);
 HTML_UpperCase := S;
End;

{ Convertit une chaine en minuscules }
Function HTML_LowerCase(S: String): String;
Var
 I: Integer;
Begin
 For I := 1 To Length(S) Do
  If (S[I] >= 'A') And (S[I] <= 'Z') Then
   S[I] := Chr(Ord(S[I]) + 32);
 HTML_LowerCase := S;
End;

{ Supprime les espaces en debut et fin de chaine }
Function HTML_Trim(S: String): String;
Begin
 While (Length(S) > 0) And (S[1] <= ' ') Do
  Delete(S, 1, 1);
 While (Length(S) > 0) And (S[Length(S)] <= ' ') Do
  Delete(S, Length(S), 1);
 HTML_Trim := S;
End;

{ Detecte le type de balise a partir de son nom }
Function HTML_GetTagType(TagName: String): THTMLTagType;
Var
 Upper: String;
Begin
 Upper := HTML_UpperCase(HTML_Trim(TagName));
 If Upper = 'HTML' Then HTML_GetTagType := htHTML
 Else If Upper = 'HEAD' Then HTML_GetTagType := htHead
 Else If Upper = 'TITLE' Then HTML_GetTagType := htTitle
 Else If Upper = 'META' Then HTML_GetTagType := htMeta
 Else If Upper = 'BODY' Then HTML_GetTagType := htBody
 Else If Upper = 'DIV' Then HTML_GetTagType := htDiv
 Else If Upper = 'SPAN' Then HTML_GetTagType := htSpan
 Else If Upper = 'P' Then HTML_GetTagType := htP
 Else If Upper = 'BR' Then HTML_GetTagType := htBr
 Else If Upper = 'HR' Then HTML_GetTagType := htHr
 Else If Upper = 'B' Then HTML_GetTagType := htB
 Else If Upper = 'I' Then HTML_GetTagType := htI
 Else If Upper = 'U' Then HTML_GetTagType := htU
 Else If Upper = 'STRONG' Then HTML_GetTagType := htStrong
 Else If Upper = 'EM' Then HTML_GetTagType := htEm
 Else If Upper = 'FONT' Then HTML_GetTagType := htFont
 Else If Upper = 'UL' Then HTML_GetTagType := htUL
 Else If Upper = 'OL' Then HTML_GetTagType := htOL
 Else If Upper = 'LI' Then HTML_GetTagType := htLI
 Else If Upper = 'TABLE' Then HTML_GetTagType := htTable
 Else If Upper = 'TR' Then HTML_GetTagType := htTR
 Else If Upper = 'TD' Then HTML_GetTagType := htTD
 Else If Upper = 'TH' Then HTML_GetTagType := htTH
 Else If Upper = 'A' Then HTML_GetTagType := htA
 Else If Upper = 'IMG' Then HTML_GetTagType := htImg
 Else If Upper = 'H1' Then HTML_GetTagType := htH1
 Else If Upper = 'H2' Then HTML_GetTagType := htH2
 Else If Upper = 'H3' Then HTML_GetTagType := htH3
 Else If Upper = 'CENTER' Then HTML_GetTagType := htCenter
 Else If Upper = 'BLOCKQUOTE' Then HTML_GetTagType := htBlockquote
 Else If Upper = 'PRE' Then HTML_GetTagType := htPre
 Else If Upper = 'CODE' Then HTML_GetTagType := htCode
 Else HTML_GetTagType := htUnknown;
End;

{ Decode une entite HTML }
Function HTML_DecodeEntity(Entity: String): String;
Var
 Upper: String;
Begin
 Upper := HTML_LowerCase(Entity);
 If Upper = 'nbsp' Then HTML_DecodeEntity := ' '
 Else If Upper = 'lt' Then HTML_DecodeEntity := '<'
 Else If Upper = 'gt' Then HTML_DecodeEntity := '>'
 Else If Upper = 'amp' Then HTML_DecodeEntity := '&'
 Else If Upper = 'quot' Then HTML_DecodeEntity := '"'
 Else If Upper = 'apos' Then HTML_DecodeEntity := ''''
 Else If Upper = 'copy' Then HTML_DecodeEntity := '(c)'
 Else If Upper = 'reg' Then HTML_DecodeEntity := '(R)'
 Else If Upper = 'euro' Then HTML_DecodeEntity := 'EUR'
 Else If Upper = 'eacute' Then HTML_DecodeEntity := 'e'
 Else If Upper = 'egrave' Then HTML_DecodeEntity := 'e'
 Else If Upper = 'agrave' Then HTML_DecodeEntity := 'a'
 Else If Upper = 'ccedil' Then HTML_DecodeEntity := 'c'
 Else If Upper = 'bull' Then HTML_DecodeEntity := '*'
 Else If Upper = 'mdash' Then HTML_DecodeEntity := '-'
 Else HTML_DecodeEntity := '?';
End;

{ Convertit une couleur HTML en couleur BGI }
Function HTML_ParseColor(ColorStr: String): Word;
Var
 Upper: String;
Begin
 Upper := HTML_UpperCase(HTML_Trim(ColorStr));
 { Couleurs nommees }
 If Upper = 'BLACK' Then HTML_ParseColor := Black
 Else If Upper = 'WHITE' Then HTML_ParseColor := White
 Else If Upper = 'RED' Then HTML_ParseColor := Red
 Else If Upper = 'GREEN' Then HTML_ParseColor := Green
 Else If Upper = 'BLUE' Then HTML_ParseColor := Blue
 Else If Upper = 'YELLOW' Then HTML_ParseColor := Yellow
 Else If Upper = 'CYAN' Then HTML_ParseColor := Cyan
 Else If Upper = 'MAGENTA' Then HTML_ParseColor := Magenta
 Else If Upper = 'GRAY' Then HTML_ParseColor := DarkGray
 Else If Upper = 'GREY' Then HTML_ParseColor := DarkGray
 Else If Upper = 'SILVER' Then HTML_ParseColor := LightGray
 Else If Upper = 'NAVY' Then HTML_ParseColor := Blue
 Else If Upper = 'MAROON' Then HTML_ParseColor := Red
 Else If Upper = 'OLIVE' Then HTML_ParseColor := Brown
 Else If Upper = 'PURPLE' Then HTML_ParseColor := Magenta
 Else If Upper = 'TEAL' Then HTML_ParseColor := Cyan
 Else If Upper = 'ORANGE' Then HTML_ParseColor := LightRed
 Else If (Length(Upper) >= 1) And (Upper[1] = '#') Then Begin
  { Couleur hexadecimale - approximation simple }
  If Length(Upper) >= 7 Then Begin
   { Extraction des composantes RGB basique }
   If (Upper[2] >= '8') Or (Upper[3] >= '8') Then HTML_ParseColor := LightRed
   Else If (Upper[4] >= '8') Or (Upper[5] >= '8') Then HTML_ParseColor := LightGreen
   Else If (Upper[6] >= '8') Or (Upper[7] >= '8') Then HTML_ParseColor := LightBlue
   Else HTML_ParseColor := DarkGray;
  End
  Else HTML_ParseColor := White;
 End
 Else HTML_ParseColor := White;
End;

{ Parse les attributs d'une balise }
Procedure HTML_ParseAttributes(AttrStr: String; Var Token: THTMLToken);
Var
 I, J, K: Integer;
 Name, Value: String;
 InQuote: Boolean;
 QuoteChar: Char;
Begin
 Token.AttrCount := 0;
 I := 1;

 While (I <= Length(AttrStr)) And (Token.AttrCount < 8) Do Begin
  { Sauter les espaces }
  While (I <= Length(AttrStr)) And (AttrStr[I] <= ' ') Do
   Inc(I);
  If I > Length(AttrStr) Then Exit;

  { Lire le nom de l'attribut }
  Name := '';
  While (I <= Length(AttrStr)) And (AttrStr[I] <> '=') And (AttrStr[I] > ' ') Do Begin
   Name := Name + AttrStr[I];
   Inc(I);
  End;

  If I > Length(AttrStr) Then Exit;

  { Sauter le signe = }
  If AttrStr[I] = '=' Then Inc(I);

  { Sauter les espaces }
  While (I <= Length(AttrStr)) And (AttrStr[I] <= ' ') Do
   Inc(I);
  If I > Length(AttrStr) Then Exit;

  { Lire la valeur }
  Value := '';
  If (AttrStr[I] = '"') Or (AttrStr[I] = '''') Then Begin
   QuoteChar := AttrStr[I];
   Inc(I);
   While (I <= Length(AttrStr)) And (AttrStr[I] <> QuoteChar) Do Begin
    Value := Value + AttrStr[I];
    Inc(I);
   End;
   Inc(I); { Sauter le guillemet fermant }
  End
  Else Begin
   While (I <= Length(AttrStr)) And (AttrStr[I] > ' ') Do Begin
    Value := Value + AttrStr[I];
    Inc(I);
   End;
  End;

  { Stocker l'attribut }
  If Length(Name) > 0 Then Begin
   Token.Attributes[Token.AttrCount].Name := HTML_LowerCase(Name);
   Token.Attributes[Token.AttrCount].Value := Value;
   Inc(Token.AttrCount);
  End;
 End;
End;

{ Recupere la valeur d'un attribut }
Function HTML_GetAttribute(Var Token: THTMLToken; Name: String): String;
Var
 I: Integer;
 LowerName: String;
Begin
 HTML_GetAttribute := '';
 LowerName := HTML_LowerCase(Name);
 For I := 0 To Token.AttrCount - 1 Do Begin
  If Token.Attributes[I].Name = LowerName Then Begin
   HTML_GetAttribute := Token.Attributes[I].Value;
   Exit;
  End;
 End;
End;

{ Tokenize le HTML }
Procedure HTML_Tokenize(HTML: String);
Var
 I, J, TagStart: Integer;
 InTag: Boolean;
 TagContent, TagName, AttrStr: String;
 IsClosing, IsSelfClose: Boolean;
 TextBuffer: String;
Begin
 HTMLTokenCount := 0;
 I := 1;
 TextBuffer := '';

 While (I <= Length(HTML)) And (HTMLTokenCount < MAX_HTML_TOKENS) Do Begin
  If HTML[I] = '<' Then Begin
   { Sauver le texte accumule }
   If Length(TextBuffer) > 0 Then Begin
    HTMLTokens^[HTMLTokenCount].TokenType := ttText;
    HTMLTokens^[HTMLTokenCount].Content := TextBuffer;
    HTMLTokens^[HTMLTokenCount].AttrCount := 0;
    Inc(HTMLTokenCount);
    TextBuffer := '';
   End;

   { Lire la balise }
   TagContent := '';
   Inc(I);

   { Verifier si c'est un commentaire }
   If (I + 2 <= Length(HTML)) And (HTML[I] = '!') And
      (HTML[I+1] = '-') And (HTML[I+2] = '-') Then Begin
    { Sauter le commentaire }
    While (I + 2 <= Length(HTML)) And Not
          ((HTML[I] = '-') And (HTML[I+1] = '-') And (HTML[I+2] = '>')) Do
     Inc(I);
    Inc(I, 3);
    Continue;
   End;

   { Lire le contenu de la balise }
   While (I <= Length(HTML)) And (HTML[I] <> '>') Do Begin
    TagContent := TagContent + HTML[I];
    Inc(I);
   End;
   Inc(I); { Sauter > }

   { Analyser la balise }
   IsClosing := False;
   IsSelfClose := False;

   If (Length(TagContent) > 0) And (TagContent[1] = '/') Then Begin
    IsClosing := True;
    Delete(TagContent, 1, 1);
   End;

   If (Length(TagContent) > 0) And (TagContent[Length(TagContent)] = '/') Then Begin
    IsSelfClose := True;
    Delete(TagContent, Length(TagContent), 1);
   End;

   { Extraire le nom de la balise }
   TagName := '';
   J := 1;
   While (J <= Length(TagContent)) And (TagContent[J] > ' ') Do Begin
    TagName := TagName + TagContent[J];
    Inc(J);
   End;

   { Extraire les attributs }
   AttrStr := '';
   If J <= Length(TagContent) Then
    AttrStr := Copy(TagContent, J, Length(TagContent) - J + 1);

   { Creer le token }
   If IsClosing Then
    HTMLTokens^[HTMLTokenCount].TokenType := ttCloseTag
   Else If IsSelfClose Then
    HTMLTokens^[HTMLTokenCount].TokenType := ttSelfClose
   Else
    HTMLTokens^[HTMLTokenCount].TokenType := ttOpenTag;

   HTMLTokens^[HTMLTokenCount].TagName := HTML_LowerCase(TagName);
   HTMLTokens^[HTMLTokenCount].TagType := HTML_GetTagType(TagName);
   HTMLTokens^[HTMLTokenCount].Content := '';
   HTML_ParseAttributes(AttrStr, HTMLTokens^[HTMLTokenCount]);
   Inc(HTMLTokenCount);
  End
  Else If HTML[I] = '&' Then Begin
   { Entite HTML }
   J := I + 1;
   While (J <= Length(HTML)) And (HTML[J] <> ';') And (J - I < 10) Do
    Inc(J);
   If (J <= Length(HTML)) And (HTML[J] = ';') Then Begin
    TextBuffer := TextBuffer + HTML_DecodeEntity(Copy(HTML, I + 1, J - I - 1));
    I := J + 1;
   End
   Else Begin
    TextBuffer := TextBuffer + HTML[I];
    Inc(I);
   End;
  End
  Else Begin
   { Texte normal }
   If HTML[I] >= ' ' Then
    TextBuffer := TextBuffer + HTML[I]
   Else If HTML[I] = #10 Then
    TextBuffer := TextBuffer + ' '
   Else If HTML[I] = #9 Then
    TextBuffer := TextBuffer + ' ';
   Inc(I);
  End;
 End;

 { Sauver le texte restant }
 If Length(TextBuffer) > 0 Then Begin
  HTMLTokens^[HTMLTokenCount].TokenType := ttText;
  HTMLTokens^[HTMLTokenCount].Content := TextBuffer;
  HTMLTokens^[HTMLTokenCount].AttrCount := 0;
  Inc(HTMLTokenCount);
 End;
End;

{ Initialise le style de rendu par defaut }
Procedure HTML_InitStyle;
Begin
 HTMLCurrentStyle.Bold := False;
 HTMLCurrentStyle.Italic := False;
 HTMLCurrentStyle.Underline := False;
 HTMLCurrentStyle.FontColor := HTML_COLOR_TEXT;
 HTMLCurrentStyle.BGColor := HTML_COLOR_BG;
 HTMLCurrentStyle.FontSize := HTML_DEFAULT_FONT_SIZE;
 HTMLCurrentStyle.Align := haLeft;
 HTMLCurrentStyle.InPre := False;
 HTMLCurrentStyle.ListLevel := 0;
 HTMLCurrentStyle.ListOrdered := False;
 HTMLCurrentStyle.ListItemNum := 0;
 HTMLCurrentStyle.InTable := False;
 HTMLCurrentStyle.InLink := False;
 HTMLCurrentStyle.LinkURL := '';
End;

{ Ajoute un element de rendu }
Procedure HTML_AddElement(Text: String; X, Y, W, H: Integer);
Begin
 If HTMLElementCount >= MAX_HTML_ELEMENTS Then Exit;

 HTMLElements[HTMLElementCount].X := X;
 HTMLElements[HTMLElementCount].Y := Y;
 HTMLElements[HTMLElementCount].Width := W;
 HTMLElements[HTMLElementCount].Height := H;
 HTMLElements[HTMLElementCount].Text := Text;
 HTMLElements[HTMLElementCount].Style := HTMLCurrentStyle;
 HTMLElements[HTMLElementCount].IsLink := HTMLCurrentStyle.InLink;
 HTMLElements[HTMLElementCount].LinkURL := HTMLCurrentStyle.LinkURL;
 HTMLElements[HTMLElementCount].IsImage := False;
 Inc(HTMLElementCount);
End;

{ Ajoute un placeholder d'image }
Procedure HTML_AddImagePlaceholder(X, Y, W, H: Integer);
Begin
 If HTMLElementCount >= MAX_HTML_ELEMENTS Then Exit;

 HTMLElements[HTMLElementCount].X := X;
 HTMLElements[HTMLElementCount].Y := Y;
 HTMLElements[HTMLElementCount].Width := W;
 HTMLElements[HTMLElementCount].Height := H;
 HTMLElements[HTMLElementCount].Text := '';
 HTMLElements[HTMLElementCount].Style := HTMLCurrentStyle;
 HTMLElements[HTMLElementCount].IsLink := False;
 HTMLElements[HTMLElementCount].LinkURL := '';
 HTMLElements[HTMLElementCount].IsImage := True;
 HTMLElements[HTMLElementCount].ImageWidth := W;
 HTMLElements[HTMLElementCount].ImageHeight := H;
 Inc(HTMLElementCount);
End;

{ Dessine une ligne horizontale }
Procedure HTML_DrawHR(Y, Width: Integer);
Begin
 GSetColor(DarkGray);
 GLine(HTMLRenderX, Y + 5, HTMLRenderX + Width - 1, Y + 5);
 GSetColor(LightGray);
 GLine(HTMLRenderX, Y + 6, HTMLRenderX + Width - 1, Y + 6);
End;

{ Rend les tokens HTML }
Procedure HTML_Render(StartX, StartY, MaxWidth, MaxHeight: Integer);
Var
 I, J, WordWidth, LineHeight: Integer;
 Word, Line: String;
 InHead: Boolean;
 AttrValue: String;
Begin
 HTML_InitStyle;
 HTMLElementCount := 0;
 HTMLRenderX := StartX;
 HTMLRenderY := StartY;
 HTMLRenderWidth := MaxWidth;
 LineHeight := 14;
 InHead := False;

 For I := 0 To HTMLTokenCount - 1 Do Begin
  Case HTMLTokens^[I].TokenType Of
   ttOpenTag: Begin
    Case HTMLTokens^[I].TagType Of
     htHead: InHead := True;
     htBody: InHead := False;
     htB, htStrong: HTMLCurrentStyle.Bold := True;
     htI, htEm: HTMLCurrentStyle.Italic := True;
     htU: HTMLCurrentStyle.Underline := True;
     htFont: Begin
      AttrValue := HTML_GetAttribute(HTMLTokens^[I], 'color');
      If Length(AttrValue) > 0 Then
       HTMLCurrentStyle.FontColor := HTML_ParseColor(AttrValue);
      AttrValue := HTML_GetAttribute(HTMLTokens^[I], 'size');
      If Length(AttrValue) > 0 Then Begin
       If AttrValue[1] In ['1'..'7'] Then
        HTMLCurrentStyle.FontSize := Ord(AttrValue[1]) - Ord('0');
      End;
     End;
     htA: Begin
      HTMLCurrentStyle.InLink := True;
      HTMLCurrentStyle.LinkURL := HTML_GetAttribute(HTMLTokens^[I], 'href');
      HTMLCurrentStyle.FontColor := HTML_COLOR_LINK;
      HTMLCurrentStyle.Underline := True;
     End;
     htP, htDiv: Begin
      If HTMLRenderX > StartX Then Begin
       HTMLRenderX := StartX + (HTMLCurrentStyle.ListLevel * HTML_LIST_INDENT);
       HTMLRenderY := HTMLRenderY + LineHeight + 4;
      End;
     End;
     htBr: Begin
      HTMLRenderX := StartX + (HTMLCurrentStyle.ListLevel * HTML_LIST_INDENT);
      HTMLRenderY := HTMLRenderY + LineHeight;
     End;
     htHr: Begin
      HTMLRenderX := StartX;
      HTMLRenderY := HTMLRenderY + 4;
      HTML_DrawHR(HTMLRenderY, MaxWidth);
      HTMLRenderY := HTMLRenderY + 12;
     End;
     htH1: Begin
      If HTMLRenderX > StartX Then HTMLRenderY := HTMLRenderY + LineHeight;
      HTMLRenderX := StartX;
      HTMLCurrentStyle.Bold := True;
      HTMLCurrentStyle.FontSize := 6;
      LineHeight := 20;
     End;
     htH2: Begin
      If HTMLRenderX > StartX Then HTMLRenderY := HTMLRenderY + LineHeight;
      HTMLRenderX := StartX;
      HTMLCurrentStyle.Bold := True;
      HTMLCurrentStyle.FontSize := 5;
      LineHeight := 18;
     End;
     htH3: Begin
      If HTMLRenderX > StartX Then HTMLRenderY := HTMLRenderY + LineHeight;
      HTMLRenderX := StartX;
      HTMLCurrentStyle.Bold := True;
      HTMLCurrentStyle.FontSize := 4;
      LineHeight := 16;
     End;
     htCenter: HTMLCurrentStyle.Align := haCenter;
     htUL: Begin
      Inc(HTMLCurrentStyle.ListLevel);
      HTMLCurrentStyle.ListOrdered := False;
      HTMLCurrentStyle.ListItemNum := 0;
      HTMLRenderX := StartX + (HTMLCurrentStyle.ListLevel * HTML_LIST_INDENT);
      If HTMLRenderY > StartY Then HTMLRenderY := HTMLRenderY + LineHeight;
     End;
     htOL: Begin
      Inc(HTMLCurrentStyle.ListLevel);
      HTMLCurrentStyle.ListOrdered := True;
      HTMLCurrentStyle.ListItemNum := 0;
      HTMLRenderX := StartX + (HTMLCurrentStyle.ListLevel * HTML_LIST_INDENT);
      If HTMLRenderY > StartY Then HTMLRenderY := HTMLRenderY + LineHeight;
     End;
     htLI: Begin
      HTMLRenderX := StartX + (HTMLCurrentStyle.ListLevel * HTML_LIST_INDENT);
      HTMLRenderY := HTMLRenderY + LineHeight;
      Inc(HTMLCurrentStyle.ListItemNum);
      { Dessiner le marqueur }
      If HTMLCurrentStyle.ListOrdered Then Begin
       Str(HTMLCurrentStyle.ListItemNum, Word);
       Word := Word + '. ';
      End
      Else
       Word := '* ';
      HTML_AddElement(Word, HTMLRenderX - 15, HTMLRenderY, 15, LineHeight);
     End;
     htTable: Begin
      HTMLCurrentStyle.InTable := True;
      HTMLRenderX := StartX;
      HTMLRenderY := HTMLRenderY + LineHeight;
     End;
     htTR: Begin
      HTMLRenderX := StartX;
      HTMLRenderY := HTMLRenderY + LineHeight + 2;
     End;
     htTD, htTH: Begin
      HTMLRenderX := HTMLRenderX + 10;
      If HTMLTokens^[I].TagType = htTH Then
       HTMLCurrentStyle.Bold := True;
     End;
     htImg: Begin
      AttrValue := HTML_GetAttribute(HTMLTokens^[I], 'width');
      WordWidth := 64;
      If Length(AttrValue) > 0 Then Begin
       Val(AttrValue, WordWidth, J);
       If J <> 0 Then WordWidth := 64;
      End;
      AttrValue := HTML_GetAttribute(HTMLTokens^[I], 'height');
      LineHeight := 64;
      If Length(AttrValue) > 0 Then Begin
       Val(AttrValue, LineHeight, J);
       If J <> 0 Then LineHeight := 64;
      End;
      HTML_AddImagePlaceholder(HTMLRenderX, HTMLRenderY, WordWidth, LineHeight);
      HTMLRenderX := HTMLRenderX + WordWidth + 4;
      LineHeight := 14;
     End;
     htPre, htCode: Begin
      HTMLCurrentStyle.InPre := True;
     End;
     htBlockquote: Begin
      HTMLRenderX := HTMLRenderX + 20;
      HTMLCurrentStyle.Italic := True;
     End;
    End;
   End;
   ttCloseTag: Begin
    Case HTMLTokens^[I].TagType Of
     htHead: InHead := False;
     htB, htStrong: HTMLCurrentStyle.Bold := False;
     htI, htEm: HTMLCurrentStyle.Italic := False;
     htU: HTMLCurrentStyle.Underline := False;
     htFont: Begin
      HTMLCurrentStyle.FontColor := HTML_COLOR_TEXT;
      HTMLCurrentStyle.FontSize := HTML_DEFAULT_FONT_SIZE;
     End;
     htA: Begin
      HTMLCurrentStyle.InLink := False;
      HTMLCurrentStyle.LinkURL := '';
      HTMLCurrentStyle.FontColor := HTML_COLOR_TEXT;
      HTMLCurrentStyle.Underline := False;
     End;
     htP, htDiv: Begin
      HTMLRenderX := StartX + (HTMLCurrentStyle.ListLevel * HTML_LIST_INDENT);
      HTMLRenderY := HTMLRenderY + LineHeight + 4;
     End;
     htH1, htH2, htH3: Begin
      HTMLCurrentStyle.Bold := False;
      HTMLCurrentStyle.FontSize := HTML_DEFAULT_FONT_SIZE;
      LineHeight := 14;
      HTMLRenderX := StartX;
      HTMLRenderY := HTMLRenderY + LineHeight + 4;
     End;
     htCenter: HTMLCurrentStyle.Align := haLeft;
     htUL, htOL: Begin
      If HTMLCurrentStyle.ListLevel > 0 Then
       Dec(HTMLCurrentStyle.ListLevel);
      HTMLRenderX := StartX + (HTMLCurrentStyle.ListLevel * HTML_LIST_INDENT);
      HTMLRenderY := HTMLRenderY + 4;
     End;
     htTable: Begin
      HTMLCurrentStyle.InTable := False;
      HTMLRenderY := HTMLRenderY + LineHeight;
     End;
     htTH: HTMLCurrentStyle.Bold := False;
     htPre, htCode: HTMLCurrentStyle.InPre := False;
     htBlockquote: Begin
      HTMLRenderX := StartX;
      HTMLCurrentStyle.Italic := False;
     End;
    End;
   End;
   ttText: Begin
    If InHead Then Continue;

    Line := HTMLTokens^[I].Content;

    { Rendre le texte mot par mot }
    J := 1;
    While J <= Length(Line) Do Begin
     { Extraire un mot }
     Word := '';
     While (J <= Length(Line)) And (Line[J] > ' ') Do Begin
      Word := Word + Line[J];
      Inc(J);
     End;

     If Length(Word) > 0 Then Begin
      WordWidth := GTextWidth(Word) + 4;

      { Verifier si le mot tient sur la ligne }
      If (HTMLRenderX + WordWidth > StartX + MaxWidth) And (HTMLRenderX > StartX) Then Begin
       HTMLRenderX := StartX + (HTMLCurrentStyle.ListLevel * HTML_LIST_INDENT);
       HTMLRenderY := HTMLRenderY + LineHeight;
      End;

      { Verifier si on depasse la hauteur max }
      If HTMLRenderY > StartY + MaxHeight Then Exit;

      HTML_AddElement(Word, HTMLRenderX, HTMLRenderY, WordWidth, LineHeight);
      HTMLRenderX := HTMLRenderX + WordWidth;
     End;

     { Sauter les espaces }
     While (J <= Length(Line)) And (Line[J] <= ' ') Do Begin
      If Line[J] = ' ' Then
       HTMLRenderX := HTMLRenderX + 4;
      Inc(J);
     End;
    End;
   End;
  End;
 End;
End;

{ Dessine les elements de rendu HTML }
Procedure HTML_Draw;
Var
 I: Integer;
 OldColor: Word;
Begin
 For I := 0 To HTMLElementCount - 1 Do Begin
  With HTMLElements[I] Do Begin
   If IsImage Then Begin
    { Dessiner le placeholder d'image }
    GSetColor(DarkGray);
    GRectangle(X, Y, X + ImageWidth, Y + ImageHeight);
    GSetFillStyle(SolidFill, DarkGray);
    GBar(X + 1, Y + 1, X + ImageWidth - 1, Y + ImageHeight - 1);
    GSetColor(LightGray);
    GOutTextXY(X + (ImageWidth Div 2) - 12, Y + (ImageHeight Div 2) - 4, '[IMG]');
   End
   Else If Length(Text) > 0 Then Begin
    GSetColor(Style.FontColor);
    If Style.Bold Then
     GSetTextStyle(DefaultFont, HorizDir, 1)
    Else
     GSetTextStyle(DefaultFont, HorizDir, 1);
    GOutTextXY(X, Y, Text);
    If Style.Underline Then Begin
     GSetColor(Style.FontColor);
     GLine(X, Y + 10, X + GTextWidth(Text), Y + 10);
    End;
   End;
  End;
 End;
End;

{ Detecte si une chaine contient du HTML }
Function HTML_IsHTMLContent(Content: String): Boolean;
Var
 Upper: String;
Begin
 Upper := HTML_UpperCase(Content);
 HTML_IsHTMLContent := (Pos('<HTML', Upper) > 0) Or
                       (Pos('<BODY', Upper) > 0) Or
                       (Pos('<DIV', Upper) > 0) Or
                       (Pos('<P>', Upper) > 0) Or
                       (Pos('<BR', Upper) > 0) Or
                       (Pos('<TABLE', Upper) > 0) Or
                       (Pos('<FONT', Upper) > 0);
End;

{ Rend un message HTML dans une zone donnee }
Procedure HTML_RenderMessage(HTML: String; X, Y, Width, Height: Integer);
Begin
 HideMouse;
 HTML_Tokenize(HTML);
 HTML_Render(X, Y, Width, Height);
 HTML_Draw;
 ShowMouse;
End;

{ Initialise le moteur HTML }
Procedure HTML_Init;
Begin
 HTMLTokenCount := 0;
 HTMLElementCount := 0;
 HTMLIsHTML := False;
 HTML_InitStyle;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DU MOTEUR DE RENDU HTML
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU DECODAGE MIME (TODO 15)
  ============================================================================ }

{ Convertit une chaine en majuscules pour MIME }
Function MIME_UpperCase(S: String): String;
Var
 I: Integer;
Begin
 For I := 1 To Length(S) Do
  If (S[I] >= 'a') And (S[I] <= 'z') Then
   S[I] := Chr(Ord(S[I]) - 32);
 MIME_UpperCase := S;
End;

{ Convertit une chaine en minuscules pour MIME }
Function MIME_LowerCase(S: String): String;
Var
 I: Integer;
Begin
 For I := 1 To Length(S) Do
  If (S[I] >= 'A') And (S[I] <= 'Z') Then
   S[I] := Chr(Ord(S[I]) + 32);
 MIME_LowerCase := S;
End;

{ Supprime les espaces en debut et fin de chaine }
Function MIME_Trim(S: String): String;
Begin
 While (Length(S) > 0) And (S[1] <= ' ') Do
  Delete(S, 1, 1);
 While (Length(S) > 0) And (S[Length(S)] <= ' ') Do
  Delete(S, Length(S), 1);
 MIME_Trim := S;
End;

{ Decode un caractere Base64 en valeur 0-63 }
Function MIME_Base64CharToValue(C: Char): Integer;
Begin
 If (C >= 'A') And (C <= 'Z') Then
  MIME_Base64CharToValue := Ord(C) - Ord('A')
 Else If (C >= 'a') And (C <= 'z') Then
  MIME_Base64CharToValue := Ord(C) - Ord('a') + 26
 Else If (C >= '0') And (C <= '9') Then
  MIME_Base64CharToValue := Ord(C) - Ord('0') + 52
 Else If C = '+' Then
  MIME_Base64CharToValue := 62
 Else If C = '/' Then
  MIME_Base64CharToValue := 63
 Else
  MIME_Base64CharToValue := -1;
End;

{ Decode une chaine Base64 }
Function MIME_DecodeBase64(Encoded: String): String;
Var
 I, J, Len: Integer;
 A, B, C, D: Integer;
 Output: String;
 Bytes: Array[0..2] of Byte;
Begin
 Output := '';
 I := 1;
 Len := Length(Encoded);

 While I <= Len Do Begin
  { Sauter les espaces et retours a la ligne }
  While (I <= Len) And (Encoded[I] <= ' ') Do
   Inc(I);
  If I > Len Then Break;

  { Lire 4 caracteres Base64 }
  A := MIME_Base64CharToValue(Encoded[I]);
  Inc(I);
  If I > Len Then Break;

  While (I <= Len) And (Encoded[I] <= ' ') Do Inc(I);
  If I > Len Then Break;
  B := MIME_Base64CharToValue(Encoded[I]);
  Inc(I);

  While (I <= Len) And (Encoded[I] <= ' ') Do Inc(I);
  If I > Len Then Begin
   { Seulement 2 caracteres - 1 octet }
   If (A >= 0) And (B >= 0) Then
    Output := Output + Chr((A Shl 2) Or (B Shr 4));
   Break;
  End;

  If Encoded[I] = '=' Then Begin
   { Padding - seulement 1 octet }
   If (A >= 0) And (B >= 0) Then
    Output := Output + Chr((A Shl 2) Or (B Shr 4));
   Break;
  End;

  C := MIME_Base64CharToValue(Encoded[I]);
  Inc(I);

  While (I <= Len) And (Encoded[I] <= ' ') Do Inc(I);
  If I > Len Then Begin
   { Seulement 3 caracteres - 2 octets }
   If (A >= 0) And (B >= 0) And (C >= 0) Then Begin
    Output := Output + Chr((A Shl 2) Or (B Shr 4));
    Output := Output + Chr(((B And $0F) Shl 4) Or (C Shr 2));
   End;
   Break;
  End;

  If Encoded[I] = '=' Then Begin
   { Padding - seulement 2 octets }
   If (A >= 0) And (B >= 0) And (C >= 0) Then Begin
    Output := Output + Chr((A Shl 2) Or (B Shr 4));
    Output := Output + Chr(((B And $0F) Shl 4) Or (C Shr 2));
   End;
   Break;
  End;

  D := MIME_Base64CharToValue(Encoded[I]);
  Inc(I);

  { Decoder les 3 octets }
  If (A >= 0) And (B >= 0) And (C >= 0) And (D >= 0) Then Begin
   Output := Output + Chr((A Shl 2) Or (B Shr 4));
   Output := Output + Chr(((B And $0F) Shl 4) Or (C Shr 2));
   Output := Output + Chr(((C And $03) Shl 6) Or D);
  End;
 End;

 MIME_DecodeBase64 := Output;
End;

{ Convertit un caractere hexa en valeur }
Function MIME_HexToValue(C: Char): Integer;
Begin
 If (C >= '0') And (C <= '9') Then
  MIME_HexToValue := Ord(C) - Ord('0')
 Else If (C >= 'A') And (C <= 'F') Then
  MIME_HexToValue := Ord(C) - Ord('A') + 10
 Else If (C >= 'a') And (C <= 'f') Then
  MIME_HexToValue := Ord(C) - Ord('a') + 10
 Else
  MIME_HexToValue := -1;
End;

{ Decode une chaine Quoted-Printable }
Function MIME_DecodeQuotedPrintable(Encoded: String): String;
Var
 I, Len: Integer;
 Output: String;
 H1, H2: Integer;
Begin
 Output := '';
 I := 1;
 Len := Length(Encoded);

 While I <= Len Do Begin
  If Encoded[I] = '=' Then Begin
   { Sequence encodee ou soft line break }
   If I + 2 <= Len Then Begin
    If (Encoded[I + 1] = #13) Or (Encoded[I + 1] = #10) Then Begin
     { Soft line break - ignorer }
     Inc(I);
     If (I <= Len) And (Encoded[I] = #13) Then Inc(I);
     If (I <= Len) And (Encoded[I] = #10) Then Inc(I);
    End
    Else Begin
     { Caractere encode =XX }
     H1 := MIME_HexToValue(Encoded[I + 1]);
     H2 := MIME_HexToValue(Encoded[I + 2]);
     If (H1 >= 0) And (H2 >= 0) Then
      Output := Output + Chr((H1 * 16) + H2)
     Else
      Output := Output + Encoded[I];
     Inc(I, 3);
    End;
   End
   Else Begin
    Output := Output + Encoded[I];
    Inc(I);
   End;
  End
  Else If Encoded[I] = '_' Then Begin
   { Underscore represente espace dans les en-tetes encodes }
   Output := Output + ' ';
   Inc(I);
  End
  Else Begin
   Output := Output + Encoded[I];
   Inc(I);
  End;
 End;

 MIME_DecodeQuotedPrintable := Output;
End;

{ Convertit UTF-8 en ASCII approximatif }
Function MIME_DecodeUTF8(UTF8: String): String;
Begin
 MIME_DecodeUTF8 := OlConvStr(UTF8, True);
End;

{ Convertit ISO-8859-1 en ASCII approximatif }
Function MIME_DecodeISO8859_1(ISO: String): String;
Begin
 MIME_DecodeISO8859_1 := OlConvStr(ISO, False);
End;

{ Convertit Windows-1252 en ASCII approximatif }
Function MIME_DecodeWindows1252(Win: String): String;
Begin
 MIME_DecodeWindows1252 := OlConvStr(Win, False);
End;

{ Parse le type de contenu }
Procedure MIME_ParseContentType(TypeStr: String; Var Part: TMIMEPart);
Var
 I, J: Integer;
 Lower, ParamName, ParamValue: String;
Begin
 Lower := MIME_LowerCase(MIME_Trim(TypeStr));
 Part.ContentTypeStr := TypeStr;

 { Determiner le type principal }
 If Copy(Lower, 1, 5) = 'text/' Then
  Part.ContentType := mctText
 Else If Copy(Lower, 1, 10) = 'multipart/' Then
  Part.ContentType := mctMultipart
 Else If Copy(Lower, 1, 12) = 'application/' Then
  Part.ContentType := mctApplication
 Else If Copy(Lower, 1, 6) = 'image/' Then
  Part.ContentType := mctImage
 Else If Copy(Lower, 1, 6) = 'audio/' Then
  Part.ContentType := mctAudio
 Else If Copy(Lower, 1, 6) = 'video/' Then
  Part.ContentType := mctVideo
 Else If Copy(Lower, 1, 8) = 'message/' Then
  Part.ContentType := mctMessage
 Else
  Part.ContentType := mctUnknown;

 { Determiner le sous-type }
 If Pos('text/plain', Lower) > 0 Then
  Part.SubType := mstPlain
 Else If Pos('text/html', Lower) > 0 Then
  Part.SubType := mstHTML
 Else If Pos('multipart/mixed', Lower) > 0 Then
  Part.SubType := mstMixed
 Else If Pos('multipart/alternative', Lower) > 0 Then
  Part.SubType := mstAlternative
 Else If Pos('multipart/related', Lower) > 0 Then
  Part.SubType := mstRelated
 Else If Pos('application/octet-stream', Lower) > 0 Then
  Part.SubType := mstOctetStream
 Else If Pos('application/pdf', Lower) > 0 Then
  Part.SubType := mstPDF
 Else If Pos('image/jpeg', Lower) > 0 Then
  Part.SubType := mstJPEG
 Else If Pos('image/png', Lower) > 0 Then
  Part.SubType := mstPNG
 Else If Pos('image/gif', Lower) > 0 Then
  Part.SubType := mstGIF
 Else If Pos('message/rfc822', Lower) > 0 Then
  Part.SubType := mstRFC822
 Else
  Part.SubType := mstUnknown;

 { Extraire les parametres }
 { Chercher le charset }
 I := Pos('charset=', Lower);
 If I > 0 Then Begin
  ParamValue := '';
  J := I + 8;
  If (J <= Length(TypeStr)) And (TypeStr[J] = '"') Then Begin
   Inc(J);
   While (J <= Length(TypeStr)) And (TypeStr[J] <> '"') Do Begin
    ParamValue := ParamValue + TypeStr[J];
    Inc(J);
   End;
  End
  Else Begin
   While (J <= Length(TypeStr)) And (TypeStr[J] > ' ') And (TypeStr[J] <> ';') Do Begin
    ParamValue := ParamValue + TypeStr[J];
    Inc(J);
   End;
  End;
  ParamValue := MIME_LowerCase(ParamValue);

  If (ParamValue = 'utf-8') Or (ParamValue = 'utf8') Then
   Part.Charset := mcsUTF8
  Else If (ParamValue = 'iso-8859-1') Or (ParamValue = 'latin1') Then
   Part.Charset := mcsISO8859_1
  Else If (ParamValue = 'windows-1252') Or (ParamValue = 'cp1252') Then
   Part.Charset := mcsWindows1252
  Else If (ParamValue = 'iso-8859-15') Or (ParamValue = 'latin9') Then
   Part.Charset := mcsISO8859_15
  Else If (ParamValue = 'us-ascii') Or (ParamValue = 'ascii') Then
   Part.Charset := mcsASCII
  Else
   Part.Charset := mcsUnknown;
 End;

 { Chercher le boundary }
 I := Pos('boundary=', Lower);
 If I > 0 Then Begin
  Part.Boundary := '';
  J := I + 9;
  If (J <= Length(TypeStr)) And (TypeStr[J] = '"') Then Begin
   Inc(J);
   While (J <= Length(TypeStr)) And (TypeStr[J] <> '"') Do Begin
    Part.Boundary := Part.Boundary + TypeStr[J];
    Inc(J);
   End;
  End
  Else Begin
   While (J <= Length(TypeStr)) And (TypeStr[J] > ' ') And (TypeStr[J] <> ';') Do Begin
    Part.Boundary := Part.Boundary + TypeStr[J];
    Inc(J);
   End;
  End;
 End;

 { Chercher le name/filename }
 I := Pos('name=', Lower);
 If I > 0 Then Begin
  Part.FileName := '';
  J := I + 5;
  If (J <= Length(TypeStr)) And (TypeStr[J] = '"') Then Begin
   Inc(J);
   While (J <= Length(TypeStr)) And (TypeStr[J] <> '"') Do Begin
    Part.FileName := Part.FileName + TypeStr[J];
    Inc(J);
   End;
  End
  Else Begin
   While (J <= Length(TypeStr)) And (TypeStr[J] > ' ') And (TypeStr[J] <> ';') Do Begin
    Part.FileName := Part.FileName + TypeStr[J];
    Inc(J);
   End;
  End;
 End;
End;

{ Parse le Content-Transfer-Encoding }
Procedure MIME_ParseTransferEncoding(EncStr: String; Var Part: TMIMEPart);
Var
 Lower: String;
Begin
 Lower := MIME_LowerCase(MIME_Trim(EncStr));

 If Lower = 'base64' Then
  Part.TransferEncoding := mteBase64
 Else If Lower = 'quoted-printable' Then
  Part.TransferEncoding := mteQuotedPrintable
 Else If Lower = '7bit' Then
  Part.TransferEncoding := mte7Bit
 Else If Lower = '8bit' Then
  Part.TransferEncoding := mte8Bit
 Else If Lower = 'binary' Then
  Part.TransferEncoding := mteBinary
 Else
  Part.TransferEncoding := mte7Bit;
End;

{ Parse le Content-Disposition }
Procedure MIME_ParseContentDisposition(DispStr: String; Var Part: TMIMEPart);
Var
 Lower: String;
 I, J: Integer;
Begin
 Lower := MIME_LowerCase(MIME_Trim(DispStr));

 Part.IsAttachment := (Pos('attachment', Lower) > 0);

 { Chercher filename }
 I := Pos('filename=', Lower);
 If I > 0 Then Begin
  J := I + 9;
  Part.FileName := '';
  If (J <= Length(DispStr)) And (DispStr[J] = '"') Then Begin
   Inc(J);
   While (J <= Length(DispStr)) And (DispStr[J] <> '"') Do Begin
    Part.FileName := Part.FileName + DispStr[J];
    Inc(J);
   End;
  End
  Else Begin
   While (J <= Length(DispStr)) And (DispStr[J] > ' ') And (DispStr[J] <> ';') Do Begin
    Part.FileName := Part.FileName + DispStr[J];
    Inc(J);
   End;
  End;
 End;
End;

{ Decode un en-tete encode (RFC 2047) }
Function MIME_DecodeEncodedWord(Word: String): String;
Var
 I, J, K: Integer;
 Charset, Encoding, Text, Decoded: String;
Begin
 MIME_DecodeEncodedWord := Word;

 { Format: =?charset?encoding?text?= }
 If (Copy(Word, 1, 2) <> '=?') Then Exit;
 If (Copy(Word, Length(Word) - 1, 2) <> '?=') Then Exit;

 { Extraire le charset }
 I := 3;
 Charset := '';
 While (I <= Length(Word)) And (Word[I] <> '?') Do Begin
  Charset := Charset + Word[I];
  Inc(I);
 End;
 Inc(I); { Sauter le ? }

 { Extraire l'encoding }
 Encoding := '';
 While (I <= Length(Word)) And (Word[I] <> '?') Do Begin
  Encoding := Encoding + Word[I];
  Inc(I);
 End;
 Inc(I); { Sauter le ? }

 { Extraire le texte }
 Text := '';
 While (I <= Length(Word) - 2) Do Begin
  Text := Text + Word[I];
  Inc(I);
 End;

 { Decoder selon l'encoding }
 Encoding := MIME_UpperCase(Encoding);
 If Encoding = 'B' Then
  Decoded := MIME_DecodeBase64(Text)
 Else If Encoding = 'Q' Then
  Decoded := MIME_DecodeQuotedPrintable(Text)
 Else
  Decoded := Text;

 { Convertir le charset }
 Charset := MIME_LowerCase(Charset);
 If (Charset = 'utf-8') Or (Charset = 'utf8') Then
  Decoded := MIME_DecodeUTF8(Decoded)
 Else If (Charset = 'iso-8859-1') Or (Charset = 'latin1') Then
  Decoded := MIME_DecodeISO8859_1(Decoded)
 Else If (Charset = 'windows-1252') Or (Charset = 'cp1252') Then
  Decoded := MIME_DecodeWindows1252(Decoded);

 MIME_DecodeEncodedWord := Decoded;
End;

{ Decode un en-tete complet (peut contenir plusieurs mots encodes) }
Function MIME_DecodeHeader(Header: String): String;
Var
 I, J, K: Integer;
 Output, Word: String;
Begin
 Output := '';
 I := 1;

 While I <= Length(Header) Do Begin
  If (I + 1 <= Length(Header)) And (Header[I] = '=') And (Header[I + 1] = '?') Then Begin
   { Mot encode trouve }
   Word := '=?';
   J := I + 2;
   While (J <= Length(Header)) And Not
         ((J + 1 <= Length(Header)) And (Header[J] = '?') And (Header[J + 1] = '=')) Do Begin
    Word := Word + Header[J];
    Inc(J);
   End;
   If J + 1 <= Length(Header) Then Begin
    Word := Word + '?=';
    J := J + 2;
   End;
   Output := Output + MIME_DecodeEncodedWord(Word);
   I := J;

   { Sauter les espaces entre mots encodes consecutifs }
   While (I <= Length(Header)) And (Header[I] <= ' ') And
         (I + 1 <= Length(Header)) And (Header[I + 1] = '=') Do
    Inc(I);
  End
  Else Begin
   Output := Output + Header[I];
   Inc(I);
  End;
 End;

 MIME_DecodeHeader := Output;
End;

{ Initialise une partie MIME }
Procedure MIME_InitPart(Var Part: TMIMEPart);
Begin
 Part.ContentType := mctText;
 Part.SubType := mstPlain;
 Part.ContentTypeStr := 'text/plain';
 Part.Charset := mcsASCII;
 Part.TransferEncoding := mte7Bit;
 Part.Boundary := '';
 Part.FileName := '';
 Part.ContentID := '';
 Part.IsAttachment := False;
 Part.DataOffset := 0;
 Part.DataLength := 0;
 Part.DecodedLength := 0;
 Part.PartCount := 0;
End;

{ Decode le contenu d'une partie MIME }
Function MIME_DecodePart(Content: String; Part: TMIMEPart): String;
Var
 Decoded: String;
Begin
 { Decoder le transfert }
 Case Part.TransferEncoding Of
  mteBase64: Decoded := MIME_DecodeBase64(Content);
  mteQuotedPrintable: Decoded := MIME_DecodeQuotedPrintable(Content);
  Else Decoded := Content;
 End;

 { Convertir le charset pour les parties texte }
 If Part.ContentType = mctText Then Begin
  Case Part.Charset Of
   mcsUTF8: Decoded := MIME_DecodeUTF8(Decoded);
   mcsISO8859_1, mcsISO8859_15: Decoded := MIME_DecodeISO8859_1(Decoded);
   mcsWindows1252: Decoded := MIME_DecodeWindows1252(Decoded);
  End;
 End;

 MIME_DecodePart := Decoded;
End;

{ Parse les en-tetes d'un message }
Procedure MIME_ParseHeaders(Headers: String);
Var
 I, J, LineStart: Integer;
 Line, Name, Value: String;
 ContinuedLine: Boolean;
Begin
 MIMEHeaderCount := 0;
 I := 1;

 While I <= Length(Headers) Do Begin
  { Lire une ligne }
  Line := '';
  While (I <= Length(Headers)) And (Headers[I] <> #13) And (Headers[I] <> #10) Do Begin
   Line := Line + Headers[I];
   Inc(I);
  End;

  { Sauter le retour a la ligne }
  If (I <= Length(Headers)) And (Headers[I] = #13) Then Inc(I);
  If (I <= Length(Headers)) And (Headers[I] = #10) Then Inc(I);

  { Ligne vide = fin des en-tetes }
  If Length(Line) = 0 Then Break;

  { Verifier si c'est une continuation }
  If (Length(Line) > 0) And ((Line[1] = ' ') Or (Line[1] = #9)) Then Begin
   { Continuation de la ligne precedente }
   If MIMEHeaderCount > 0 Then
    MIMEHeaders[MIMEHeaderCount - 1].Value :=
     MIMEHeaders[MIMEHeaderCount - 1].Value + ' ' + MIME_Trim(Line);
  End
  Else Begin
   { Nouvel en-tete }
   J := Pos(':', Line);
   If J > 0 Then Begin
    Name := MIME_Trim(Copy(Line, 1, J - 1));
    Value := MIME_Trim(Copy(Line, J + 1, Length(Line) - J));

    If MIMEHeaderCount < MAX_MIME_HEADERS Then Begin
     MIMEHeaders[MIMEHeaderCount].Name := MIME_LowerCase(Name);
     MIMEHeaders[MIMEHeaderCount].Value := Value;
     Inc(MIMEHeaderCount);
    End;
   End;
  End;
 End;
End;

{ Recupere la valeur d'un en-tete }
Function MIME_GetHeader(Name: String): String;
Var
 I: Integer;
 LowerName: String;
Begin
 MIME_GetHeader := '';
 LowerName := MIME_LowerCase(Name);
 For I := 0 To MIMEHeaderCount - 1 Do Begin
  If MIMEHeaders[I].Name = LowerName Then Begin
   MIME_GetHeader := MIMEHeaders[I].Value;
   Exit;
  End;
 End;
End;

{ Parse un message MIME complet }
Procedure MIME_ParseMessage(Message: String);
Var
 I, J, K, PartStart, PartEnd: Integer;
 HeaderEnd: Integer;
 Headers, Body, ContentType, Boundary: String;
 BoundaryLine, EndBoundary: String;
 PartHeaders, PartContent: String;
Begin
 MIMEPartCount := 0;
 MIMEHasText := False;
 MIMEHasHTML := False;
 MIMEHasAttachments := False;
 MIMETextPart := '';
 MIMEHTMLPart := '';

 { Trouver la fin des en-tetes }
 HeaderEnd := Pos(#13#10#13#10, Message);
 If HeaderEnd = 0 Then HeaderEnd := Pos(#10#10, Message);
 If HeaderEnd = 0 Then Begin
  { Pas d'en-tetes separes - tout est le corps }
  MIMETextPart := Message;
  MIMEHasText := True;
  Exit;
 End;

 Headers := Copy(Message, 1, HeaderEnd - 1);
 Body := Copy(Message, HeaderEnd + 4, Length(Message) - HeaderEnd - 3);
 If Body = '' Then Body := Copy(Message, HeaderEnd + 2, Length(Message) - HeaderEnd - 1);

 MIME_ParseHeaders(Headers);
 MIME_InitPart(MIMERootPart);

 { Analyser le Content-Type }
 ContentType := MIME_GetHeader('content-type');
 If Length(ContentType) > 0 Then
  MIME_ParseContentType(ContentType, MIMERootPart);

 { Analyser le Content-Transfer-Encoding }
 ContentType := MIME_GetHeader('content-transfer-encoding');
 If Length(ContentType) > 0 Then
  MIME_ParseTransferEncoding(ContentType, MIMERootPart);

 { Si multipart, parser les parties }
 If MIMERootPart.ContentType = mctMultipart Then Begin
  Boundary := MIMERootPart.Boundary;
  If Length(Boundary) = 0 Then Begin
   { Pas de boundary, traiter comme texte }
   MIMETextPart := Body;
   MIMEHasText := True;
   Exit;
  End;

  BoundaryLine := '--' + Boundary;
  EndBoundary := '--' + Boundary + '--';

  { Trouver les parties }
  I := Pos(BoundaryLine, Body);
  While I > 0 Do Begin
   { Passer apres le boundary }
   J := I + Length(BoundaryLine);
   While (J <= Length(Body)) And ((Body[J] = #13) Or (Body[J] = #10)) Do
    Inc(J);

   { Trouver le prochain boundary }
   K := Pos(BoundaryLine, Copy(Body, J, Length(Body) - J + 1));
   If K > 0 Then
    PartEnd := J + K - 2
   Else
    PartEnd := Length(Body);

   { Extraire cette partie }
   PartContent := Copy(Body, J, PartEnd - J);

   { Verifier si c'est le boundary final }
   If Copy(Body, I, Length(EndBoundary)) = EndBoundary Then Break;

   { Parser la partie }
   If (MIMEPartCount < MAX_MIME_PARTS) And (Length(PartContent) > 0) Then Begin
    { Trouver la separation en-tetes/corps de la partie }
    HeaderEnd := Pos(#13#10#13#10, PartContent);
    If HeaderEnd = 0 Then HeaderEnd := Pos(#10#10, PartContent);

    If HeaderEnd > 0 Then Begin
     PartHeaders := Copy(PartContent, 1, HeaderEnd - 1);
     PartContent := Copy(PartContent, HeaderEnd + 4, Length(PartContent) - HeaderEnd - 3);
     If PartContent = '' Then PartContent := Copy(PartContent, HeaderEnd + 2, Length(PartContent) - HeaderEnd - 1);
    End
    Else
     PartHeaders := '';

    MIME_InitPart(MIMEParts[MIMEPartCount]);

    { Parser les en-tetes de la partie }
    If Length(PartHeaders) > 0 Then Begin
     MIME_ParseHeaders(PartHeaders);
     ContentType := MIME_GetHeader('content-type');
     If Length(ContentType) > 0 Then
      MIME_ParseContentType(ContentType, MIMEParts[MIMEPartCount]);
     ContentType := MIME_GetHeader('content-transfer-encoding');
     If Length(ContentType) > 0 Then
      MIME_ParseTransferEncoding(ContentType, MIMEParts[MIMEPartCount]);
     ContentType := MIME_GetHeader('content-disposition');
     If Length(ContentType) > 0 Then
      MIME_ParseContentDisposition(ContentType, MIMEParts[MIMEPartCount]);
     ContentType := MIME_GetHeader('content-id');
     If Length(ContentType) > 0 Then Begin
      MIMEParts[MIMEPartCount].ContentID := ContentType;
      { Enlever les < > }
      If (Length(MIMEParts[MIMEPartCount].ContentID) > 2) And
         (MIMEParts[MIMEPartCount].ContentID[1] = '<') Then Begin
       Delete(MIMEParts[MIMEPartCount].ContentID, 1, 1);
       Delete(MIMEParts[MIMEPartCount].ContentID,
              Length(MIMEParts[MIMEPartCount].ContentID), 1);
      End;
     End;
    End;

    { Decoder le contenu }
    PartContent := MIME_DecodePart(PartContent, MIMEParts[MIMEPartCount]);

    { Stocker selon le type }
    If MIMEParts[MIMEPartCount].IsAttachment Then Begin
     MIMEHasAttachments := True;
    End
    Else If MIMEParts[MIMEPartCount].SubType = mstPlain Then Begin
     MIMETextPart := PartContent;
     MIMEHasText := True;
    End
    Else If MIMEParts[MIMEPartCount].SubType = mstHTML Then Begin
     MIMEHTMLPart := PartContent;
     MIMEHasHTML := True;
    End;

    Inc(MIMEPartCount);
   End;

   { Chercher le prochain boundary }
   I := Pos(BoundaryLine, Copy(Body, PartEnd, Length(Body) - PartEnd + 1));
   If I > 0 Then I := PartEnd + I - 1
   Else I := 0;
  End;
 End
 Else Begin
  { Message simple (non multipart) }
  Body := MIME_DecodePart(Body, MIMERootPart);

  If MIMERootPart.SubType = mstHTML Then Begin
   MIMEHTMLPart := Body;
   MIMEHasHTML := True;
  End
  Else Begin
   MIMETextPart := Body;
   MIMEHasText := True;
  End;
 End;
End;

{ Retourne le contenu texte d'un message MIME }
Function MIME_GetTextContent: String;
Begin
 If MIMEHasText Then
  MIME_GetTextContent := MIMETextPart
 Else If MIMEHasHTML Then
  MIME_GetTextContent := MIMEHTMLPart
 Else
  MIME_GetTextContent := '';
End;

{ Retourne le contenu HTML d'un message MIME }
Function MIME_GetHTMLContent: String;
Begin
 If MIMEHasHTML Then
  MIME_GetHTMLContent := MIMEHTMLPart
 Else
  MIME_GetHTMLContent := '';
End;

{ Verifie si un message contient des pieces jointes }
Function MIME_HasAttachments: Boolean;
Begin
 MIME_HasAttachments := MIMEHasAttachments;
End;

{ Retourne le nombre de parties }
Function MIME_GetPartCount: Integer;
Begin
 MIME_GetPartCount := MIMEPartCount;
End;

{ Initialise le decodeur MIME }
Procedure MIME_Init;
Begin
 MIMEPartCount := 0;
 MIMEHeaderCount := 0;
 MIME_InitPart(MIMERootPart);
 MIMETextPart := '';
 MIMEHTMLPart := '';
 MIMEHasText := False;
 MIMEHasHTML := False;
 MIMEHasAttachments := False;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DU DECODAGE MIME
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU CARNET D'ADRESSES (TODO 16)
  ============================================================================ }

{ Initialise un contact vide }
Procedure AB_InitContact(Var Contact: TContact);
Begin
 Contact.ID := 0;
 Contact.LastName := '';
 Contact.FirstName := '';
 Contact.DisplayName := '';
 Contact.Email := '';
 Contact.Email2 := '';
 Contact.Phone := '';
 Contact.PhoneMobile := '';
 Contact.PhoneWork := '';
 Contact.Address := '';
 Contact.Address2 := '';
 Contact.City := '';
 Contact.PostalCode := '';
 Contact.Country := '';
 Contact.Company := '';
 Contact.JobTitle := '';
 Contact.Notes := '';
 Contact.Birthday := '';
 Contact.CreatedDate := 0;
 Contact.ModifiedDate := 0;
 Contact.IsSelected := False;
End;

{ Initialise le carnet d'adresses }
Procedure AB_Init;
Var
 I: Integer;
Begin
 ContactCount := 0;
 ContactNextID := 1;
 ContactSortField := csfLastName;
 ContactSortAsc := True;
 ContactScrollOffset := 0;
 ContactSelectedIndex := -1;
 AddressBookState := absHidden;
 AddressBookX := (640 - ADDRESSBOOK_WIDTH) Div 2;
 AddressBookY := (480 - ADDRESSBOOK_HEIGHT) Div 2;
 AddressBookSearchText := '';
 EditingContactIndex := -1;
 EditingField := 0;
 AddressBookVisible := False;

 { Initialiser tous les contacts }
 For I := 0 To MAX_CONTACTS - 1 Do
  AB_InitContact(Contacts^[I]);

 { Auto-completion }
 AutoCompleteSuggestionCount := 0;
 AutoCompleteVisible := False;
 AutoCompleteSelectedIndex := -1;
 AutoCompleteField := acfTo;
 AutoCompleteText := '';
End;

{ Compare deux chaines sans casse }
Function AB_CompareStr(S1, S2: String): Integer;
Var
 I, L1, L2, MinL: Integer;
 C1, C2: Char;
Begin
 L1 := Length(S1);
 L2 := Length(S2);
 If L1 < L2 Then MinL := L1 Else MinL := L2;

 For I := 1 To MinL Do Begin
  C1 := S1[I];
  C2 := S2[I];
  { Convertir en majuscule }
  If (C1 >= 'a') And (C1 <= 'z') Then C1 := Chr(Ord(C1) - 32);
  If (C2 >= 'a') And (C2 <= 'z') Then C2 := Chr(Ord(C2) - 32);
  If C1 < C2 Then Begin
   AB_CompareStr := -1;
   Exit;
  End
  Else If C1 > C2 Then Begin
   AB_CompareStr := 1;
   Exit;
  End;
 End;

 If L1 < L2 Then AB_CompareStr := -1
 Else If L1 > L2 Then AB_CompareStr := 1
 Else AB_CompareStr := 0;
End;

{ Echange deux contacts }
Procedure AB_SwapContacts(Var A, B: TContact);
Var
 Temp: TContact;
Begin
 Temp := A;
 A := B;
 B := Temp;
End;

{ Tri les contacts (tri a bulles pour simplicite) }
Procedure AB_SortContacts;
Var
 I, J: Integer;
 Swapped: Boolean;
 Cmp: Integer;
 S1, S2: String;
Begin
 If ContactCount < 2 Then Exit;

 For I := 0 To ContactCount - 2 Do Begin
  Swapped := False;
  For J := 0 To ContactCount - 2 - I Do Begin
   { Obtenir les valeurs a comparer }
   Case ContactSortField Of
    csfLastName: Begin
     S1 := Contacts^[J].LastName;
     S2 := Contacts^[J + 1].LastName;
    End;
    csfFirstName: Begin
     S1 := Contacts^[J].FirstName;
     S2 := Contacts^[J + 1].FirstName;
    End;
    csfEmail: Begin
     S1 := Contacts^[J].Email;
     S2 := Contacts^[J + 1].Email;
    End;
    csfCompany: Begin
     S1 := Contacts^[J].Company;
     S2 := Contacts^[J + 1].Company;
    End;
   End;

   Cmp := AB_CompareStr(S1, S2);
   If Not ContactSortAsc Then Cmp := -Cmp;

   If Cmp > 0 Then Begin
    AB_SwapContacts(Contacts^[J], Contacts^[J + 1]);
    Swapped := True;
   End;
  End;
  If Not Swapped Then Break;
 End;
End;

{ Genere le nom d'affichage }
Function AB_GenerateDisplayName(Const Contact: TContact): String;
Begin
 If Length(Contact.DisplayName) > 0 Then
  AB_GenerateDisplayName := Contact.DisplayName
 Else If (Length(Contact.FirstName) > 0) And (Length(Contact.LastName) > 0) Then
  AB_GenerateDisplayName := Contact.FirstName + ' ' + Contact.LastName
 Else If Length(Contact.LastName) > 0 Then
  AB_GenerateDisplayName := Contact.LastName
 Else If Length(Contact.FirstName) > 0 Then
  AB_GenerateDisplayName := Contact.FirstName
 Else If Length(Contact.Email) > 0 Then
  AB_GenerateDisplayName := Contact.Email
 Else
  AB_GenerateDisplayName := '(Sans nom)';
End;

{ Ajoute un nouveau contact }
Function AB_AddContact(Var NewContact: TContact): Integer;
Begin
 AB_AddContact := -1;
 If ContactCount >= MAX_CONTACTS Then Exit;

 NewContact.ID := ContactNextID;
 Inc(ContactNextID);
 NewContact.CreatedDate := 0; { TODO: obtenir date actuelle }
 NewContact.ModifiedDate := NewContact.CreatedDate;

 If Length(NewContact.DisplayName) = 0 Then
  NewContact.DisplayName := AB_GenerateDisplayName(NewContact);

 Contacts^[ContactCount] := NewContact;
 AB_AddContact := ContactCount;
 Inc(ContactCount);

 AB_SortContacts;
End;

{ Modifie un contact existant }
Function AB_UpdateContact(Index: Integer; Const UpdatedContact: TContact): Boolean;
Begin
 AB_UpdateContact := False;
 If (Index < 0) Or (Index >= ContactCount) Then Exit;

 Contacts^[Index] := UpdatedContact;
 Contacts^[Index].ModifiedDate := 0; { TODO: obtenir date actuelle }

 If Length(Contacts^[Index].DisplayName) = 0 Then
  Contacts^[Index].DisplayName := AB_GenerateDisplayName(Contacts^[Index]);

 AB_UpdateContact := True;
 AB_SortContacts;
End;

{ Supprime un contact }
Function AB_DeleteContact(Index: Integer): Boolean;
Var
 I: Integer;
Begin
 AB_DeleteContact := False;
 If (Index < 0) Or (Index >= ContactCount) Then Exit;

 For I := Index To ContactCount - 2 Do
  Contacts^[I] := Contacts^[I + 1];

 Dec(ContactCount);
 AB_InitContact(Contacts^[ContactCount]);

 If ContactSelectedIndex >= ContactCount Then
  ContactSelectedIndex := ContactCount - 1;

 AB_DeleteContact := True;
End;

{ Recherche un contact par email }
Function AB_FindByEmail(Email: String): Integer;
Var
 I: Integer;
 LowerEmail, ContactEmail: String;
Begin
 AB_FindByEmail := -1;
 LowerEmail := Email;
 For I := 1 To Length(LowerEmail) Do
  If (LowerEmail[I] >= 'A') And (LowerEmail[I] <= 'Z') Then
   LowerEmail[I] := Chr(Ord(LowerEmail[I]) + 32);

 For I := 0 To ContactCount - 1 Do Begin
  ContactEmail := Contacts^[I].Email;
  { Convertir en minuscules }
  { Pour simplifier, comparaison directe }
  If AB_CompareStr(Contacts^[I].Email, Email) = 0 Then Begin
   AB_FindByEmail := I;
   Exit;
  End;
 End;
End;

Type
 TABResults = Array[0..CONTACTS_VISIBLE-1] of Integer;

{ Recherche des contacts correspondant au texte }
Function AB_Search(SearchText: String; Var Results: TABResults;
                   MaxResults: Integer): Integer;
Var
 I, Count: Integer;
 LowerSearch, LowerField: String;
 J: Integer;
Begin
 Count := 0;
 If Length(SearchText) = 0 Then Begin
  { Retourner tous les contacts }
  For I := 0 To ContactCount - 1 Do Begin
   If Count >= MaxResults Then Break;
   Results[Count] := I;
   Inc(Count);
  End;
  AB_Search := Count;
  Exit;
 End;

 { Convertir recherche en minuscules }
 LowerSearch := SearchText;
 For J := 1 To Length(LowerSearch) Do
  If (LowerSearch[J] >= 'A') And (LowerSearch[J] <= 'Z') Then
   LowerSearch[J] := Chr(Ord(LowerSearch[J]) + 32);

 For I := 0 To ContactCount - 1 Do Begin
  If Count >= MaxResults Then Break;

  { Verifier chaque champ }
  LowerField := Contacts^[I].LastName;
  For J := 1 To Length(LowerField) Do
   If (LowerField[J] >= 'A') And (LowerField[J] <= 'Z') Then
    LowerField[J] := Chr(Ord(LowerField[J]) + 32);
  If Pos(LowerSearch, LowerField) > 0 Then Begin
   Results[Count] := I;
   Inc(Count);
   Continue;
  End;

  LowerField := Contacts^[I].FirstName;
  For J := 1 To Length(LowerField) Do
   If (LowerField[J] >= 'A') And (LowerField[J] <= 'Z') Then
    LowerField[J] := Chr(Ord(LowerField[J]) + 32);
  If Pos(LowerSearch, LowerField) > 0 Then Begin
   Results[Count] := I;
   Inc(Count);
   Continue;
  End;

  LowerField := Contacts^[I].Email;
  For J := 1 To Length(LowerField) Do
   If (LowerField[J] >= 'A') And (LowerField[J] <= 'Z') Then
    LowerField[J] := Chr(Ord(LowerField[J]) + 32);
  If Pos(LowerSearch, LowerField) > 0 Then Begin
   Results[Count] := I;
   Inc(Count);
   Continue;
  End;

  LowerField := Contacts^[I].Company;
  For J := 1 To Length(LowerField) Do
   If (LowerField[J] >= 'A') And (LowerField[J] <= 'Z') Then
    LowerField[J] := Chr(Ord(LowerField[J]) + 32);
  If Pos(LowerSearch, LowerField) > 0 Then Begin
   Results[Count] := I;
   Inc(Count);
  End;
 End;

 AB_Search := Count;
End;

{ ============================================================================
  IMPORT/EXPORT VCARD (RFC 2426)
  ============================================================================ }

{ Encode une valeur pour vCard }
Function AB_VCardEncode(S: String): String;
Var
 I: Integer;
 Output: String;
Begin
 Output := '';
 For I := 1 To Length(S) Do Begin
  Case S[I] Of
   '\': Output := Output + '\\';
   ';': Output := Output + '\;';
   ',': Output := Output + '\,';
   #13: Output := Output + '\n';
   #10: ; { Ignorer LF }
   Else Output := Output + S[I];
  End;
 End;
 AB_VCardEncode := Output;
End;

{ Decode une valeur vCard }
Function AB_VCardDecode(S: String): String;
Var
 I: Integer;
 Output: String;
Begin
 Output := '';
 I := 1;
 While I <= Length(S) Do Begin
  If (S[I] = '\') And (I < Length(S)) Then Begin
   Case S[I + 1] Of
    '\': Output := Output + '\';
    ';': Output := Output + ';';
    ',': Output := Output + ',';
    'n', 'N': Output := Output + #13#10;
    Else Output := Output + S[I + 1];
   End;
   Inc(I, 2);
  End
  Else Begin
   Output := Output + S[I];
   Inc(I);
  End;
 End;
 AB_VCardDecode := Output;
End;

{ Exporte un contact en format vCard }
Function AB_ExportContactToVCard(Const Contact: TContact): String;
Var
 VCard: String;
Begin
 VCard := 'BEGIN:VCARD' + #13#10;
 VCard := VCard + 'VERSION:3.0' + #13#10;

 { Nom structure: Nom;Prenom }
 VCard := VCard + 'N:' + AB_VCardEncode(Contact.LastName) + ';' +
          AB_VCardEncode(Contact.FirstName) + ';;;' + #13#10;

 { Nom d'affichage }
 VCard := VCard + 'FN:' + AB_VCardEncode(AB_GenerateDisplayName(Contact)) + #13#10;

 { Email }
 If Length(Contact.Email) > 0 Then
  VCard := VCard + 'EMAIL;TYPE=INTERNET;TYPE=PREF:' + Contact.Email + #13#10;
 If Length(Contact.Email2) > 0 Then
  VCard := VCard + 'EMAIL;TYPE=INTERNET:' + Contact.Email2 + #13#10;

 { Telephones }
 If Length(Contact.Phone) > 0 Then
  VCard := VCard + 'TEL;TYPE=HOME:' + Contact.Phone + #13#10;
 If Length(Contact.PhoneMobile) > 0 Then
  VCard := VCard + 'TEL;TYPE=CELL:' + Contact.PhoneMobile + #13#10;
 If Length(Contact.PhoneWork) > 0 Then
  VCard := VCard + 'TEL;TYPE=WORK:' + Contact.PhoneWork + #13#10;

 { Adresse }
 If (Length(Contact.Address) > 0) Or (Length(Contact.City) > 0) Then Begin
  VCard := VCard + 'ADR;TYPE=HOME:;;' + AB_VCardEncode(Contact.Address);
  If Length(Contact.Address2) > 0 Then
   VCard := VCard + ' ' + AB_VCardEncode(Contact.Address2);
  VCard := VCard + ';' + AB_VCardEncode(Contact.City) + ';;' +
           AB_VCardEncode(Contact.PostalCode) + ';' +
           AB_VCardEncode(Contact.Country) + #13#10;
 End;

 { Entreprise }
 If Length(Contact.Company) > 0 Then
  VCard := VCard + 'ORG:' + AB_VCardEncode(Contact.Company) + #13#10;

 If Length(Contact.JobTitle) > 0 Then
  VCard := VCard + 'TITLE:' + AB_VCardEncode(Contact.JobTitle) + #13#10;

 { Date de naissance }
 If Length(Contact.Birthday) > 0 Then
  VCard := VCard + 'BDAY:' + Contact.Birthday + #13#10;

 { Notes }
 If Length(Contact.Notes) > 0 Then
  VCard := VCard + 'NOTE:' + AB_VCardEncode(Contact.Notes) + #13#10;

 VCard := VCard + 'END:VCARD' + #13#10;
 AB_ExportContactToVCard := VCard;
End;

{ Extrait une propriete d'une ligne vCard }
Procedure AB_ParseVCardLine(Line: String; Var PropName, PropValue: String);
Var
 I, ColonPos: Integer;
Begin
 PropName := '';
 PropValue := '';

 ColonPos := Pos(':', Line);
 If ColonPos = 0 Then Exit;

 PropName := Copy(Line, 1, ColonPos - 1);
 PropValue := Copy(Line, ColonPos + 1, Length(Line) - ColonPos);

 { Extraire le nom de propriete sans les parametres }
 I := Pos(';', PropName);
 If I > 0 Then
  PropName := Copy(PropName, 1, I - 1);

 { Convertir en majuscules }
 For I := 1 To Length(PropName) Do
  If (PropName[I] >= 'a') And (PropName[I] <= 'z') Then
   PropName[I] := Chr(Ord(PropName[I]) - 32);
End;

{ Importe un contact depuis format vCard }
Function AB_ImportContactFromVCard(VCard: String; Var Contact: TContact): Boolean;
Var
 I, LineStart, LineEnd: Integer;
 Line, PropName, PropValue: String;
 InVCard: Boolean;
 NameParts: Array[0..4] of String;
 PartCount, J, SemiPos: Integer;
Begin
 AB_ImportContactFromVCard := False;
 AB_InitContact(Contact);
 InVCard := False;

 I := 1;
 While I <= Length(VCard) Do Begin
  { Lire une ligne }
  LineStart := I;
  While (I <= Length(VCard)) And (VCard[I] <> #13) And (VCard[I] <> #10) Do
   Inc(I);
  Line := Copy(VCard, LineStart, I - LineStart);
  If (I <= Length(VCard)) And (VCard[I] = #13) Then Inc(I);
  If (I <= Length(VCard)) And (VCard[I] = #10) Then Inc(I);

  If Length(Line) = 0 Then Continue;

  AB_ParseVCardLine(Line, PropName, PropValue);

  If PropName = 'BEGIN' Then Begin
   If PropValue = 'VCARD' Then InVCard := True;
  End
  Else If PropName = 'END' Then Begin
   If PropValue = 'VCARD' Then Begin
    InVCard := False;
    AB_ImportContactFromVCard := True;
    Exit;
   End;
  End
  Else If InVCard Then Begin
   PropValue := AB_VCardDecode(PropValue);

   If PropName = 'N' Then Begin
    { Parser Nom;Prenom;;; }
    PartCount := 0;
    For J := 0 To 4 Do NameParts[J] := '';
    J := 1;
    While (J <= Length(PropValue)) And (PartCount <= 4) Do Begin
     If PropValue[J] = ';' Then
      Inc(PartCount)
     Else
      NameParts[PartCount] := NameParts[PartCount] + PropValue[J];
     Inc(J);
    End;
    Contact.LastName := NameParts[0];
    Contact.FirstName := NameParts[1];
   End
   Else If PropName = 'FN' Then
    Contact.DisplayName := PropValue
   Else If PropName = 'EMAIL' Then Begin
    If Length(Contact.Email) = 0 Then
     Contact.Email := PropValue
    Else If Length(Contact.Email2) = 0 Then
     Contact.Email2 := PropValue;
   End
   Else If PropName = 'TEL' Then Begin
    { Determiner le type par le contexte }
    If Pos('CELL', Line) > 0 Then
     Contact.PhoneMobile := PropValue
    Else If Pos('WORK', Line) > 0 Then
     Contact.PhoneWork := PropValue
    Else If Length(Contact.Phone) = 0 Then
     Contact.Phone := PropValue;
   End
   Else If PropName = 'ADR' Then Begin
    { Parser ;;Adresse;Ville;;CodePostal;Pays }
    PartCount := 0;
    For J := 0 To 4 Do NameParts[J] := '';
    J := 1;
    While (J <= Length(PropValue)) And (PartCount <= 4) Do Begin
     If PropValue[J] = ';' Then
      Inc(PartCount)
     Else If PartCount <= 4 Then
      NameParts[PartCount] := NameParts[PartCount] + PropValue[J];
     Inc(J);
    End;
    If Length(NameParts[2]) > 0 Then Contact.Address := NameParts[2];
    If Length(NameParts[3]) > 0 Then Contact.City := NameParts[3];
   End
   Else If PropName = 'ORG' Then
    Contact.Company := PropValue
   Else If PropName = 'TITLE' Then
    Contact.JobTitle := PropValue
   Else If PropName = 'BDAY' Then
    Contact.Birthday := PropValue
   Else If PropName = 'NOTE' Then
    Contact.Notes := PropValue;
  End;
 End;
End;

{ ============================================================================
  IMPORT/EXPORT CSV
  ============================================================================ }

{ Echappe une valeur pour CSV }
Function AB_CSVEscape(S: String): String;
Var
 NeedQuotes: Boolean;
 I: Integer;
 Output: String;
Begin
 NeedQuotes := False;
 For I := 1 To Length(S) Do
  If (S[I] = ',') Or (S[I] = '"') Or (S[I] = #13) Or (S[I] = #10) Then Begin
   NeedQuotes := True;
   Break;
  End;

 If NeedQuotes Then Begin
  Output := '"';
  For I := 1 To Length(S) Do Begin
   If S[I] = '"' Then
    Output := Output + '""'
   Else
    Output := Output + S[I];
  End;
  Output := Output + '"';
  AB_CSVEscape := Output;
 End
 Else
  AB_CSVEscape := S;
End;

{ Exporte l'en-tete CSV }
Function AB_GetCSVHeader: String;
Begin
 AB_GetCSVHeader := 'LastName,FirstName,DisplayName,Email,Email2,Phone,' +
                    'PhoneMobile,PhoneWork,Address,Address2,City,PostalCode,' +
                    'Country,Company,JobTitle,Birthday,Notes';
End;

{ Exporte un contact en format CSV }
Function AB_ExportContactToCSV(Const Contact: TContact): String;
Begin
 AB_ExportContactToCSV :=
  AB_CSVEscape(Contact.LastName) + ',' +
  AB_CSVEscape(Contact.FirstName) + ',' +
  AB_CSVEscape(Contact.DisplayName) + ',' +
  AB_CSVEscape(Contact.Email) + ',' +
  AB_CSVEscape(Contact.Email2) + ',' +
  AB_CSVEscape(Contact.Phone) + ',' +
  AB_CSVEscape(Contact.PhoneMobile) + ',' +
  AB_CSVEscape(Contact.PhoneWork) + ',' +
  AB_CSVEscape(Contact.Address) + ',' +
  AB_CSVEscape(Contact.Address2) + ',' +
  AB_CSVEscape(Contact.City) + ',' +
  AB_CSVEscape(Contact.PostalCode) + ',' +
  AB_CSVEscape(Contact.Country) + ',' +
  AB_CSVEscape(Contact.Company) + ',' +
  AB_CSVEscape(Contact.JobTitle) + ',' +
  AB_CSVEscape(Contact.Birthday) + ',' +
  AB_CSVEscape(Contact.Notes);
End;

{ Parse une valeur CSV (gere les guillemets) }
Function AB_CSVParseField(Line: String; Var Pos: Integer): String;
Var
 InQuotes: Boolean;
 Output: String;
Begin
 Output := '';
 InQuotes := False;

 If Pos > Length(Line) Then Begin
  AB_CSVParseField := '';
  Exit;
 End;

 { Verifier si commence par guillemet }
 If Line[Pos] = '"' Then Begin
  InQuotes := True;
  Inc(Pos);
 End;

 While Pos <= Length(Line) Do Begin
  If InQuotes Then Begin
   If Line[Pos] = '"' Then Begin
    If (Pos < Length(Line)) And (Line[Pos + 1] = '"') Then Begin
     { Double guillemet = guillemet simple }
     Output := Output + '"';
     Inc(Pos, 2);
    End
    Else Begin
     { Fin du champ }
     Inc(Pos);
     { Sauter la virgule }
     If (Pos <= Length(Line)) And (Line[Pos] = ',') Then Inc(Pos);
     Break;
    End;
   End
   Else Begin
    Output := Output + Line[Pos];
    Inc(Pos);
   End;
  End
  Else Begin
   If Line[Pos] = ',' Then Begin
    Inc(Pos);
    Break;
   End
   Else Begin
    Output := Output + Line[Pos];
    Inc(Pos);
   End;
  End;
 End;

 AB_CSVParseField := Output;
End;

{ Importe un contact depuis format CSV }
Function AB_ImportContactFromCSV(Line: String; Var Contact: TContact): Boolean;
Var
 P: Integer;
Begin
 AB_ImportContactFromCSV := False;
 AB_InitContact(Contact);
 P := 1;

 Contact.LastName := AB_CSVParseField(Line, P);
 Contact.FirstName := AB_CSVParseField(Line, P);
 Contact.DisplayName := AB_CSVParseField(Line, P);
 Contact.Email := AB_CSVParseField(Line, P);
 Contact.Email2 := AB_CSVParseField(Line, P);
 Contact.Phone := AB_CSVParseField(Line, P);
 Contact.PhoneMobile := AB_CSVParseField(Line, P);
 Contact.PhoneWork := AB_CSVParseField(Line, P);
 Contact.Address := AB_CSVParseField(Line, P);
 Contact.Address2 := AB_CSVParseField(Line, P);
 Contact.City := AB_CSVParseField(Line, P);
 Contact.PostalCode := AB_CSVParseField(Line, P);
 Contact.Country := AB_CSVParseField(Line, P);
 Contact.Company := AB_CSVParseField(Line, P);
 Contact.JobTitle := AB_CSVParseField(Line, P);
 Contact.Birthday := AB_CSVParseField(Line, P);
 Contact.Notes := AB_CSVParseField(Line, P);

 { Verifier qu'on a au moins un nom ou email }
 AB_ImportContactFromCSV := (Length(Contact.LastName) > 0) Or
                            (Length(Contact.FirstName) > 0) Or
                            (Length(Contact.Email) > 0);
End;

{ ============================================================================
  AUTO-COMPLETION
  ============================================================================ }

{ Calcule un score de correspondance }
Function AB_CalcMatchScore(SearchText, FieldValue: String): Integer;
Var
 I, J, Score: Integer;
 LowerSearch, LowerField: String;
Begin
 Score := 0;
 If Length(SearchText) = 0 Then Begin
  AB_CalcMatchScore := 0;
  Exit;
 End;

 { Convertir en minuscules }
 LowerSearch := SearchText;
 LowerField := FieldValue;
 For I := 1 To Length(LowerSearch) Do
  If (LowerSearch[I] >= 'A') And (LowerSearch[I] <= 'Z') Then
   LowerSearch[I] := Chr(Ord(LowerSearch[I]) + 32);
 For I := 1 To Length(LowerField) Do
  If (LowerField[I] >= 'A') And (LowerField[I] <= 'Z') Then
   LowerField[I] := Chr(Ord(LowerField[I]) + 32);

 { Correspondance exacte au debut = score maximum }
 If Copy(LowerField, 1, Length(LowerSearch)) = LowerSearch Then
  Score := 100 - Length(FieldValue)
 { Correspondance quelque part }
 Else If Pos(LowerSearch, LowerField) > 0 Then
  Score := 50 - Pos(LowerSearch, LowerField);

 AB_CalcMatchScore := Score;
End;

{ Met a jour les suggestions d'auto-completion }
Procedure AB_UpdateAutoComplete(SearchText: String);
Var
 I, J, Score, BestScore: Integer;
 Temp: TAutoCompleteSuggestion;
Begin
 AutoCompleteSuggestionCount := 0;
 AutoCompleteText := SearchText;

 If Length(SearchText) < 2 Then Begin
  AutoCompleteVisible := False;
  Exit;
 End;

 For I := 0 To ContactCount - 1 Do Begin
  If AutoCompleteSuggestionCount >= MAX_AUTOCOMPLETE_SUGGESTIONS Then Break;

  { Calculer le score pour ce contact }
  BestScore := AB_CalcMatchScore(SearchText, Contacts^[I].DisplayName);
  Score := AB_CalcMatchScore(SearchText, Contacts^[I].Email);
  If Score > BestScore Then BestScore := Score;
  Score := AB_CalcMatchScore(SearchText, Contacts^[I].FirstName);
  If Score > BestScore Then BestScore := Score;
  Score := AB_CalcMatchScore(SearchText, Contacts^[I].LastName);
  If Score > BestScore Then BestScore := Score;

  If BestScore > 0 Then Begin
   AutoCompleteSuggestions[AutoCompleteSuggestionCount].DisplayName :=
    AB_GenerateDisplayName(Contacts^[I]);
   AutoCompleteSuggestions[AutoCompleteSuggestionCount].Email := Contacts^[I].Email;
   AutoCompleteSuggestions[AutoCompleteSuggestionCount].MatchScore := BestScore;
   Inc(AutoCompleteSuggestionCount);
  End;
 End;

 { Trier par score (tri a bulles) }
 For I := 0 To AutoCompleteSuggestionCount - 2 Do
  For J := 0 To AutoCompleteSuggestionCount - 2 - I Do
   If AutoCompleteSuggestions[J].MatchScore <
      AutoCompleteSuggestions[J + 1].MatchScore Then Begin
    Temp := AutoCompleteSuggestions[J];
    AutoCompleteSuggestions[J] := AutoCompleteSuggestions[J + 1];
    AutoCompleteSuggestions[J + 1] := Temp;
   End;

 AutoCompleteVisible := AutoCompleteSuggestionCount > 0;
 AutoCompleteSelectedIndex := 0;
End;

{ Retourne la suggestion selectionnee formatee }
Function AB_GetSelectedSuggestion: String;
Begin
 If (AutoCompleteSelectedIndex >= 0) And
    (AutoCompleteSelectedIndex < AutoCompleteSuggestionCount) Then Begin
  If Length(AutoCompleteSuggestions[AutoCompleteSelectedIndex].DisplayName) > 0 Then
   AB_GetSelectedSuggestion :=
    '"' + AutoCompleteSuggestions[AutoCompleteSelectedIndex].DisplayName + '" <' +
    AutoCompleteSuggestions[AutoCompleteSelectedIndex].Email + '>'
  Else
   AB_GetSelectedSuggestion := AutoCompleteSuggestions[AutoCompleteSelectedIndex].Email;
 End
 Else
  AB_GetSelectedSuggestion := '';
End;

{ ============================================================================
  AFFICHAGE DU CARNET D'ADRESSES
  ============================================================================ }

{ Dessine la fenetre du carnet d'adresses }
Procedure AB_DrawWindow;
Var
 X, Y, W, H: Integer;
 I, Y1: Integer;
 DisplayStr: String;
 SearchResults: TABResults;
 ResultCount: Integer;
Begin
 If Not AddressBookVisible Then Exit;

 X := AddressBookX;
 Y := AddressBookY;
 W := ADDRESSBOOK_WIDTH;
 H := ADDRESSBOOK_HEIGHT;

 { Fond de la fenetre }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X, Y, X + W, Y + H);

 { Bordure }
 GSetColor(DarkGray);
 GRectangle(X, Y, X + W, Y + H);
 GSetColor(White);
 GLine(X + 1, Y + 1, X + W - 1, Y + 1);
 GLine(X + 1, Y + 1, X + 1, Y + H - 1);

 { Barre de titre }
 GSetFillStyle(SolidFill, Blue);
 GBar(X + 2, Y + 2, X + W - 2, Y + 22);
 GSetColor(White);
 GOutTextXY(X + 10, Y + 7, 'Carnet d''adresses');

 { Bouton fermer }
 GSetFillStyle(SolidFill, Red);
 GBar(X + W - 20, Y + 4, X + W - 4, Y + 20);
 GSetColor(White);
 GOutTextXY(X + W - 16, Y + 7, 'X');

 { Zone de recherche }
 GSetFillStyle(SolidFill, White);
 GBar(X + 10, Y + 30, X + W - 100, Y + 48);
 GSetColor(Black);
 GRectangle(X + 10, Y + 30, X + W - 100, Y + 48);
 If Length(AddressBookSearchText) > 0 Then
  GOutTextXY(X + 14, Y + 35, AddressBookSearchText)
 Else Begin
  GSetColor(DarkGray);
  GOutTextXY(X + 14, Y + 35, 'Rechercher...');
 End;

 { Boutons }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + W - 90, Y + 30, X + W - 10, Y + 48);
 GSetColor(Black);
 GRectangle(X + W - 90, Y + 30, X + W - 10, Y + 48);
 GOutTextXY(X + W - 75, Y + 35, 'Nouveau');

 { En-tetes de colonnes }
 Y1 := Y + 55;
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + 10, Y1, X + W - 10, Y1 + 18);
 GSetColor(Black);
 GRectangle(X + 10, Y1, X + W - 10, Y1 + 18);
 GOutTextXY(X + 15, Y1 + 4, 'Nom');
 GOutTextXY(X + 15 + CONTACT_COL_NAME, Y1 + 4, 'Email');
 GOutTextXY(X + 15 + CONTACT_COL_NAME + CONTACT_COL_EMAIL, Y1 + 4, 'Telephone');

 { Liste des contacts }
 Y1 := Y + 75;
 ResultCount := AB_Search(AddressBookSearchText, SearchResults, CONTACTS_VISIBLE);

 For I := 0 To ResultCount - 1 Do Begin
  If I + ContactScrollOffset >= ContactCount Then Break;

  { Fond de la ligne }
  If SearchResults[I] = ContactSelectedIndex Then
   GSetFillStyle(SolidFill, Blue)
  Else If (I Mod 2) = 0 Then
   GSetFillStyle(SolidFill, White)
  Else
   GSetFillStyle(SolidFill, LightGray);

  GBar(X + 10, Y1 + I * CONTACT_LINE_HEIGHT,
      X + W - 10, Y1 + (I + 1) * CONTACT_LINE_HEIGHT - 1);

  If SearchResults[I] = ContactSelectedIndex Then
   GSetColor(White)
  Else
   GSetColor(Black);

  { Nom }
  DisplayStr := AB_GenerateDisplayName(Contacts^[SearchResults[I]]);
  If Length(DisplayStr) > 20 Then
   DisplayStr := Copy(DisplayStr, 1, 18) + '..';
  GOutTextXY(X + 15, Y1 + I * CONTACT_LINE_HEIGHT + 4, DisplayStr);

  { Email }
  DisplayStr := Contacts^[SearchResults[I]].Email;
  If Length(DisplayStr) > 25 Then
   DisplayStr := Copy(DisplayStr, 1, 23) + '..';
  GOutTextXY(X + 15 + CONTACT_COL_NAME, Y1 + I * CONTACT_LINE_HEIGHT + 4, DisplayStr);

  { Telephone }
  DisplayStr := Contacts^[SearchResults[I]].Phone;
  If Length(DisplayStr) > 12 Then
   DisplayStr := Copy(DisplayStr, 1, 10) + '..';
  GOutTextXY(X + 15 + CONTACT_COL_NAME + CONTACT_COL_EMAIL,
            Y1 + I * CONTACT_LINE_HEIGHT + 4, DisplayStr);
 End;

 { Boutons du bas }
 Y1 := Y + H - 35;

 { Bouton Modifier }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + 10, Y1, X + 80, Y1 + 25);
 GSetColor(Black);
 GRectangle(X + 10, Y1, X + 80, Y1 + 25);
 GOutTextXY(X + 18, Y1 + 8, 'Modifier');

 { Bouton Supprimer }
 GBar(X + 90, Y1, X + 170, Y1 + 25);
 GRectangle(X + 90, Y1, X + 170, Y1 + 25);
 GOutTextXY(X + 96, Y1 + 8, 'Supprimer');

 { Bouton Import }
 GBar(X + W - 170, Y1, X + W - 90, Y1 + 25);
 GRectangle(X + W - 170, Y1, X + W - 90, Y1 + 25);
 GOutTextXY(X + W - 162, Y1 + 8, 'Importer');

 { Bouton Export }
 GBar(X + W - 80, Y1, X + W - 10, Y1 + 25);
 GRectangle(X + W - 80, Y1, X + W - 10, Y1 + 25);
 GOutTextXY(X + W - 72, Y1 + 8, 'Exporter');

 { Compteur }
 GSetColor(DarkGray);
 DisplayStr := '';
 Str(ContactCount, DisplayStr);
 DisplayStr := DisplayStr + ' contact(s)';
 GOutTextXY(X + W Div 2 - 30, Y1 + 8, DisplayStr);
End;

{ Dessine le popup d'auto-completion }
Procedure AB_DrawAutoComplete;
Var
 I, X, Y, W, H: Integer;
 DisplayStr: String;
Begin
 If Not AutoCompleteVisible Then Exit;
 If AutoCompleteSuggestionCount = 0 Then Exit;

 X := AutoCompleteX;
 Y := AutoCompleteY;
 W := 300;
 H := AutoCompleteSuggestionCount * 20 + 4;

 { Ombre }
 GSetFillStyle(SolidFill, DarkGray);
 GBar(X + 2, Y + 2, X + W + 2, Y + H + 2);

 { Fond }
 GSetFillStyle(SolidFill, White);
 GBar(X, Y, X + W, Y + H);

 { Bordure }
 GSetColor(Black);
 GRectangle(X, Y, X + W, Y + H);

 { Suggestions }
 For I := 0 To AutoCompleteSuggestionCount - 1 Do Begin
  If I = AutoCompleteSelectedIndex Then Begin
   GSetFillStyle(SolidFill, Blue);
   GBar(X + 1, Y + 2 + I * 20, X + W - 1, Y + 2 + (I + 1) * 20 - 1);
   GSetColor(White);
  End
  Else
   GSetColor(Black);

  DisplayStr := AutoCompleteSuggestions[I].DisplayName;
  If Length(DisplayStr) > 25 Then
   DisplayStr := Copy(DisplayStr, 1, 23) + '..';
  GOutTextXY(X + 5, Y + 5 + I * 20, DisplayStr);

  If I <> AutoCompleteSelectedIndex Then GSetColor(DarkGray);
  DisplayStr := '<' + AutoCompleteSuggestions[I].Email + '>';
  If Length(DisplayStr) > 30 Then
   DisplayStr := Copy(DisplayStr, 1, 28) + '..';
  GOutTextXY(X + 150, Y + 5 + I * 20, DisplayStr);
 End;
End;

{ Affiche le carnet d'adresses }
Procedure AB_Show;
Begin
 AddressBookVisible := True;
 AddressBookState := absList;
 ContactSelectedIndex := -1;
 AddressBookSearchText := '';
 ContactScrollOffset := 0;
End;

{ Cache le carnet d'adresses }
Procedure AB_Hide;
Begin
 AddressBookVisible := False;
 AddressBookState := absHidden;
End;

{ Gere un clic dans le carnet d'adresses }
Function AB_HandleClick(MX, MY: Integer): Boolean;
Var
 X, Y, W, H: Integer;
 I, Y1: Integer;
 SearchResults: TABResults;
 ResultCount: Integer;
Begin
 AB_HandleClick := False;
 If Not AddressBookVisible Then Exit;

 X := AddressBookX;
 Y := AddressBookY;
 W := ADDRESSBOOK_WIDTH;
 H := ADDRESSBOOK_HEIGHT;

 { Verifier si clic dans la fenetre }
 If (MX < X) Or (MX > X + W) Or (MY < Y) Or (MY > Y + H) Then Exit;

 AB_HandleClick := True;

 { Bouton fermer }
 If (MX >= X + W - 20) And (MX <= X + W - 4) And (MY >= Y + 4) And (MY <= Y + 20) Then Begin
  AB_Hide;
  Exit;
 End;

 { Bouton Nouveau }
 If (MX >= X + W - 90) And (MX <= X + W - 10) And (MY >= Y + 30) And (MY <= Y + 48) Then Begin
  { Creer nouveau contact }
  AB_InitContact(EditingContact);
  EditingContactIndex := -1;
  AddressBookState := absNew;
  Exit;
 End;

 { Zone de recherche }
 If (MX >= X + 10) And (MX <= X + W - 100) And (MY >= Y + 30) And (MY <= Y + 48) Then Begin
  AddressBookState := absSearch;
  Exit;
 End;

 { Liste des contacts }
 Y1 := Y + 75;
 ResultCount := AB_Search(AddressBookSearchText, SearchResults, CONTACTS_VISIBLE);

 For I := 0 To ResultCount - 1 Do Begin
  If (MY >= Y1 + I * CONTACT_LINE_HEIGHT) And
     (MY < Y1 + (I + 1) * CONTACT_LINE_HEIGHT) Then Begin
   ContactSelectedIndex := SearchResults[I];
   Exit;
  End;
 End;

 { Boutons du bas }
 Y1 := Y + H - 35;

 { Bouton Modifier }
 If (MX >= X + 10) And (MX <= X + 80) And (MY >= Y1) And (MY <= Y1 + 25) Then Begin
  If ContactSelectedIndex >= 0 Then Begin
   EditingContact := Contacts^[ContactSelectedIndex];
   EditingContactIndex := ContactSelectedIndex;
   AddressBookState := absEdit;
  End;
  Exit;
 End;

 { Bouton Supprimer }
 If (MX >= X + 90) And (MX <= X + 170) And (MY >= Y1) And (MY <= Y1 + 25) Then Begin
  If ContactSelectedIndex >= 0 Then Begin
   AB_DeleteContact(ContactSelectedIndex);
  End;
  Exit;
 End;
End;

{ Ajoute des contacts de demonstration }
Procedure AB_AddDemoContacts;
Var
 C: TContact;
Begin
 AB_InitContact(C);
 C.FirstName := 'Jean';
 C.LastName := 'Dupont';
 C.Email := 'jean.dupont@example.com';
 C.Phone := '514-555-1234';
 C.Company := 'Acme Inc.';
 AB_AddContact(C);

 AB_InitContact(C);
 C.FirstName := 'Marie';
 C.LastName := 'Tremblay';
 C.Email := 'marie.tremblay@exemple.ca';
 C.Phone := '418-555-5678';
 C.PhoneMobile := '418-555-9012';
 AB_AddContact(C);

 AB_InitContact(C);
 C.FirstName := 'Pierre';
 C.LastName := 'Martin';
 C.Email := 'p.martin@courriel.net';
 C.Company := 'Tech Solutions';
 C.JobTitle := 'Developpeur';
 AB_AddContact(C);

 AB_InitContact(C);
 C.FirstName := 'Sophie';
 C.LastName := 'Gagnon';
 C.Email := 'sophie.g@mail.com';
 C.Phone := '450-555-3456';
 C.City := 'Montreal';
 C.Country := 'Canada';
 AB_AddContact(C);
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DU CARNET D'ADRESSES
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU SYSTEME DE REGLES DE FILTRAGE (TODO 17)
  ============================================================================ }

{ Initialise une condition vide }
Procedure Rules_InitCondition(Var Cond: TRuleCondition);
Begin
 Cond.ConditionType := rctSenderContains;
 Cond.Value := '';
 Cond.NumericValue := 0;
 Cond.CaseSensitive := False;
End;

{ Initialise une action vide }
Procedure Rules_InitAction(Var Act: TRuleAction);
Begin
 Act.ActionType := ratMarkAsRead;
 Act.TargetFolder := '';
 Act.TargetEmail := '';
 Act.ReplyText := '';
 Act.PriorityValue := mpNormal;
 Act.SoundFile := '';
End;

{ Initialise une regle vide }
Procedure Rules_InitRule(Var Rule: TFilterRule);
Var
 I: Integer;
Begin
 Rule.ID := 0;
 Rule.Name := '';
 Rule.Description := '';
 Rule.Enabled := True;
 Rule.Order := 0;
 Rule.ApplyToIncoming := True;
 Rule.ApplyToOutgoing := False;
 Rule.RuleOperator := roAnd;
 Rule.ConditionCount := 0;
 Rule.ActionCount := 0;
 Rule.CreatedDate := 0;
 Rule.LastTriggered := 0;
 Rule.TriggerCount := 0;

 For I := 0 To MAX_RULE_CONDITIONS - 1 Do
  Rules_InitCondition(Rule.Conditions[I]);
 For I := 0 To MAX_RULE_ACTIONS - 1 Do
  Rules_InitAction(Rule.Actions[I]);
End;

{ Initialise le systeme de regles }
Procedure Rules_Init;
Var
 I: Integer;
Begin
 RuleCount := 0;
 RuleNextID := 1;
 RulesWindowState := rwsHidden;
 RulesWindowX := (SCREEN_WIDTH - RULES_WINDOW_WIDTH) Div 2;
 RulesWindowY := (SCREEN_HEIGHT - RULES_WINDOW_HEIGHT) Div 2;
 RulesVisible := False; RulesFocus:=0; RulesError:=''; RulesDeletePending:=False;
 RulesScrollOffset := 0;
 RulesSelectedIndex := -1;
 EditingRuleIndex := -1;
 EditingConditionIndex := -1;
 EditingActionIndex := -1;

 For I := 0 To MAX_RULES - 1 Do
  Rules_InitRule(FilterRules^[I]);
End;

{ Compare deux chaines sans tenir compte de la casse }
Function Rules_StrContains(Haystack, Needle: String; CaseSensitive: Boolean): Boolean;
Var
 I, J: Integer;
 H, N: String;
Begin
 Rules_StrContains := False;
 If Length(Needle) = 0 Then Begin
  Rules_StrContains := True;
  Exit;
 End;
 If Length(Needle) > Length(Haystack) Then Exit;

 H := Haystack;
 N := Needle;

 If Not CaseSensitive Then Begin
  For I := 1 To Length(H) Do
   If (H[I] >= 'A') And (H[I] <= 'Z') Then
    H[I] := Chr(Ord(H[I]) + 32);
  For I := 1 To Length(N) Do
   If (N[I] >= 'A') And (N[I] <= 'Z') Then
    N[I] := Chr(Ord(N[I]) + 32);
 End;

 Rules_StrContains := Pos(N, H) > 0;
End;

{ Verifie si une chaine commence par une autre }
Function Rules_StrStartsWith(Haystack, Needle: String; CaseSensitive: Boolean): Boolean;
Var
 I: Integer;
 H, N: String;
Begin
 Rules_StrStartsWith := False;
 If Length(Needle) = 0 Then Begin
  Rules_StrStartsWith := True;
  Exit;
 End;
 If Length(Needle) > Length(Haystack) Then Exit;

 H := Copy(Haystack, 1, Length(Needle));
 N := Needle;

 If Not CaseSensitive Then Begin
  For I := 1 To Length(H) Do
   If (H[I] >= 'A') And (H[I] <= 'Z') Then
    H[I] := Chr(Ord(H[I]) + 32);
  For I := 1 To Length(N) Do
   If (N[I] >= 'A') And (N[I] <= 'Z') Then
    N[I] := Chr(Ord(N[I]) + 32);
 End;

 Rules_StrStartsWith := H = N;
End;

{ Verifie si deux chaines sont egales }
Function Rules_StrEquals(S1, S2: String; CaseSensitive: Boolean): Boolean;
Var
 I: Integer;
 A, B: String;
Begin
 A := S1;
 B := S2;

 If Not CaseSensitive Then Begin
  For I := 1 To Length(A) Do
   If (A[I] >= 'A') And (A[I] <= 'Z') Then
    A[I] := Chr(Ord(A[I]) + 32);
  For I := 1 To Length(B) Do
   If (B[I] >= 'A') And (B[I] <= 'Z') Then
    B[I] := Chr(Ord(B[I]) + 32);
 End;

 Rules_StrEquals := A = B;
End;

{ Obtient le corps du message comme une seule chaine }
Function Rules_GetMessageBody(MsgIndex: Integer): String;
Var
 I: Integer;
 Body: String;
Begin
 Body := '';
 If (MsgIndex >= 0) And (MsgIndex < MessageCount) Then Begin
  For I := 0 To Messages^[MsgIndex].BodyLineCount - 1 Do Begin
   If Length(Body) + Length(Messages^[MsgIndex].Body[I]) < 250 Then
    Body := Body + Messages^[MsgIndex].Body[I] + ' ';
  End;
 End;
 Rules_GetMessageBody := Body;
End;

{ Evalue une condition sur un message }
Function Rules_EvaluateCondition(MsgIndex: Integer;
                                  Const Cond: TRuleCondition): Boolean;
Var
 Body, Needle: TMailText;
 PriorityStr: String;
Begin
 Rules_EvaluateCondition := False;
 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;

 Case Cond.ConditionType Of
  rctSenderContains:
   Rules_EvaluateCondition := Rules_StrContains(
    Messages^[MsgIndex].FromName + ' ' + Messages^[MsgIndex].FromEmail,
    Cond.Value, Cond.CaseSensitive);

  rctSenderEquals:
   Rules_EvaluateCondition := Rules_StrEquals(
    Messages^[MsgIndex].FromEmail, Cond.Value, Cond.CaseSensitive);

  rctSubjectContains:
   Rules_EvaluateCondition := Rules_StrContains(
    Messages^[MsgIndex].Subject, Cond.Value, Cond.CaseSensitive);

  rctSubjectStartsWith:
   Rules_EvaluateCondition := Rules_StrStartsWith(
    Messages^[MsgIndex].Subject, Cond.Value, Cond.CaseSensitive);

  rctBodyContains: Begin
   Body:=OlRefText(MessageSources[MsgIndex]); Needle:=Cond.Value;
   If MessageSources[MsgIndex].L=0 Then Body:=Rules_GetMessageBody(MsgIndex);
   If Not Cond.CaseSensitive Then Begin Body:=MailUpper(Body); Needle:=MailUpper(Needle); End;
   Rules_EvaluateCondition:=Pos(Needle,Body)>0;
  End;

  rctSizeGreaterThan:
   Rules_EvaluateCondition := Messages^[MsgIndex].Size > Cond.NumericValue;

  rctSizeLessThan:
   Rules_EvaluateCondition := Messages^[MsgIndex].Size < Cond.NumericValue;

  rctHasAttachment:
   Rules_EvaluateCondition := Messages^[MsgIndex].HasAttachment;

  rctPriorityEquals: Begin
   Case Messages^[MsgIndex].Priority Of
    mpHigh: PriorityStr := 'HIGH';
    mpNormal: PriorityStr := 'NORMAL';
    mpLow: PriorityStr := 'LOW';
   End;
   Rules_EvaluateCondition := Rules_StrEquals(PriorityStr, Cond.Value, False);
  End;

  rctDateOlderThan:
   { TODO: Implementer avec calcul de date reelle }
   Rules_EvaluateCondition := False;

  rctDateNewerThan:
   { TODO: Implementer avec calcul de date reelle }
   Rules_EvaluateCondition := False;

  rctToContains:
   Rules_EvaluateCondition := Rules_StrContains(
    Messages^[MsgIndex].ToName + ' ' + Messages^[MsgIndex].ToEmail,
    Cond.Value, Cond.CaseSensitive);

  rctCcContains:
   Rules_EvaluateCondition := Rules_StrContains(
    Messages^[MsgIndex].CcEmail, Cond.Value, Cond.CaseSensitive);
 End;
End;

{ Evalue toutes les conditions d'une regle sur un message }
Function Rules_EvaluateAllConditions(MsgIndex: Integer;
                                      Const Rule: TFilterRule): Boolean;
Var
 I: Integer;
 Result: Boolean;
 CondResult: Boolean;
Begin
 Rules_EvaluateAllConditions := False;
 If Rule.ConditionCount = 0 Then Begin
  { Pas de conditions = toujours vrai }
  Rules_EvaluateAllConditions := True;
  Exit;
 End;

 { Evaluer selon l'operateur }
 If Rule.RuleOperator = roAnd Then Begin
  Result := True;
  For I := 0 To Rule.ConditionCount - 1 Do Begin
   CondResult := Rules_EvaluateCondition(MsgIndex, Rule.Conditions[I]);
   Result := Result And CondResult;
   If Not Result Then Break;
  End;
 End
 Else Begin { roOr }
  Result := False;
  For I := 0 To Rule.ConditionCount - 1 Do Begin
   CondResult := Rules_EvaluateCondition(MsgIndex, Rule.Conditions[I]);
   Result := Result Or CondResult;
   If Result Then Break;
  End;
 End;

 Rules_EvaluateAllConditions := Result;
End;

{ Execute une action sur un message }
Procedure Rules_ExecuteAction(MsgIndex: Integer; Const Act: TRuleAction);
Begin
 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;

 Case Act.ActionType Of
  ratMoveToFolder: Begin
   { TODO: Implementer le deplacement vers dossier }
   { Pour l'instant, on marque juste le message }
  End;

  ratCopyToFolder: Begin
   { TODO: Implementer la copie vers dossier }
  End;

  ratMarkAsRead:
   Messages^[MsgIndex].IsRead := True;

  ratMarkAsUnread:
   Messages^[MsgIndex].IsRead := False;

  ratSetFlag:
   Messages^[MsgIndex].IsFlagged := True;

  ratClearFlag:
   Messages^[MsgIndex].IsFlagged := False;

  ratSetPriority:
   Messages^[MsgIndex].Priority := Act.PriorityValue;

  ratDelete: Begin
   { TODO: Deplacer vers corbeille }
   Messages^[MsgIndex].IsRead := True;
  End;

  ratForwardTo: Begin
   { TODO: Implementer le transfert }
  End;

  ratAutoReply: Begin
   { TODO: Implementer la reponse automatique }
  End;

  ratPlaySound: Begin
   { TODO: Jouer un son }
  End;

  ratStopProcessing: Begin
   { Gere dans la boucle principale }
  End;
 End;
End;

{ Execute toutes les actions d'une regle sur un message }
Function Rules_ExecuteAllActions(MsgIndex: Integer;
                                  Var Rule: TFilterRule): Boolean;
Var
 I: Integer;
 StopProcessing: Boolean;
Begin
 StopProcessing := False;

 For I := 0 To Rule.ActionCount - 1 Do Begin
  If Rule.Actions[I].ActionType = ratStopProcessing Then
   StopProcessing := True
  Else
   Rules_ExecuteAction(MsgIndex, Rule.Actions[I]);
 End;

 { Mettre a jour les statistiques }
 Inc(Rule.TriggerCount);
 Rule.LastTriggered := 0; { TODO: Date actuelle }

 Rules_ExecuteAllActions := StopProcessing;
End;

{ Applique toutes les regles a un message }
Procedure Rules_ApplyToMessage(MsgIndex: Integer; IsIncoming: Boolean);
Var
 I: Integer;
 StopProcessing: Boolean;
Begin
 StopProcessing := False;

 For I := 0 To RuleCount - 1 Do Begin
  If StopProcessing Then Break;
  If Not FilterRules^[I].Enabled Then Continue;

  { Verifier si la regle s'applique a ce type de message }
  If IsIncoming And (Not FilterRules^[I].ApplyToIncoming) Then Continue;
  If (Not IsIncoming) And (Not FilterRules^[I].ApplyToOutgoing) Then Continue;

  { Evaluer les conditions }
  If Rules_EvaluateAllConditions(MsgIndex, FilterRules^[I]) Then
   StopProcessing := Rules_ExecuteAllActions(MsgIndex, FilterRules^[I]);
 End;
End;

{ Applique toutes les regles a tous les messages }
Procedure Rules_ApplyToAllMessages;
Var I,Unread: Integer;
Begin
 Unread:=0;
 For I:=0 To MessageCount-1 Do Begin
  Rules_ApplyToMessage(I,True);
  If Not Messages^[I].IsRead Then Inc(Unread);
 End;
 If (SelectedFolder>=0) And (SelectedFolder<FolderCount) Then
  Folders[SelectedFolder].UnreadCount:=Unread;
End;

{ Ajoute une nouvelle regle }
Function Rules_AddRule(Var NewRule: TFilterRule): Integer;
Begin
 Rules_AddRule := -1;
 If RuleCount >= MAX_RULES Then Exit;

 NewRule.ID := RuleNextID;
 Inc(RuleNextID);
 NewRule.Order := RuleCount;
 NewRule.CreatedDate := 0; { TODO: Date actuelle }

 FilterRules^[RuleCount] := NewRule;
 Rules_AddRule := RuleCount;
 Inc(RuleCount);
End;

{ Modifie une regle existante }
Function Rules_UpdateRule(Index: Integer; Const UpdatedRule: TFilterRule): Boolean;
Begin
 Rules_UpdateRule := False;
 If (Index < 0) Or (Index >= RuleCount) Then Exit;

 FilterRules^[Index] := UpdatedRule;
 Rules_UpdateRule := True;
End;

{ Supprime une regle }
Function Rules_DeleteRule(Index: Integer): Boolean;
Var
 I: Integer;
Begin
 Rules_DeleteRule := False;
 If (Index < 0) Or (Index >= RuleCount) Then Exit;

 For I := Index To RuleCount - 2 Do Begin
  FilterRules^[I] := FilterRules^[I + 1];
  FilterRules^[I].Order := I;
 End;

 Dec(RuleCount);
 Rules_InitRule(FilterRules^[RuleCount]);

 If RulesSelectedIndex >= RuleCount Then
  RulesSelectedIndex := RuleCount - 1;

 Rules_DeleteRule := True;
End;

{ Deplace une regle vers le haut }
Function Rules_MoveUp(Index: Integer): Boolean;
Var
 Temp: TFilterRule;
Begin
 Rules_MoveUp := False;
 If (Index <= 0) Or (Index >= RuleCount) Then Exit;

 Temp := FilterRules^[Index];
 FilterRules^[Index] := FilterRules^[Index - 1];
 FilterRules^[Index - 1] := Temp;

 FilterRules^[Index].Order := Index;
 FilterRules^[Index - 1].Order := Index - 1;

 Rules_MoveUp := True;
End;

{ Deplace une regle vers le bas }
Function Rules_MoveDown(Index: Integer): Boolean;
Var
 Temp: TFilterRule;
Begin
 Rules_MoveDown := False;
 If (Index < 0) Or (Index >= RuleCount - 1) Then Exit;

 Temp := FilterRules^[Index];
 FilterRules^[Index] := FilterRules^[Index + 1];
 FilterRules^[Index + 1] := Temp;

 FilterRules^[Index].Order := Index;
 FilterRules^[Index + 1].Order := Index + 1;

 Rules_MoveDown := True;
End;

{ Active/desactive une regle }
Procedure Rules_ToggleEnabled(Index: Integer);
Begin
 If (Index >= 0) And (Index < RuleCount) Then
  FilterRules^[Index].Enabled := Not FilterRules^[Index].Enabled;
End;

{ Retourne le nom d'un type de condition }
Function Rules_GetConditionTypeName(CT: TRuleConditionType): String;
Begin
 Case CT Of
  rctSenderContains: Rules_GetConditionTypeName := 'Expediteur contient';
  rctSenderEquals: Rules_GetConditionTypeName := 'Expediteur egal a';
  rctSubjectContains: Rules_GetConditionTypeName := 'Objet contient';
  rctSubjectStartsWith: Rules_GetConditionTypeName := 'Objet commence par';
  rctBodyContains: Rules_GetConditionTypeName := 'Corps contient';
  rctSizeGreaterThan: Rules_GetConditionTypeName := 'Taille > (octets)';
  rctSizeLessThan: Rules_GetConditionTypeName := 'Taille < (octets)';
  rctHasAttachment: Rules_GetConditionTypeName := 'Contient piece jointe';
  rctPriorityEquals: Rules_GetConditionTypeName := 'Priorite egale a';
  rctDateOlderThan: Rules_GetConditionTypeName := 'Date plus ancienne (jours)';
  rctDateNewerThan: Rules_GetConditionTypeName := 'Date plus recente (jours)';
  rctToContains: Rules_GetConditionTypeName := 'Destinataire contient';
  rctCcContains: Rules_GetConditionTypeName := 'Copie contient';
  Else Rules_GetConditionTypeName := 'Inconnu';
 End;
End;

{ Retourne le nom d'un type d'action }
Function Rules_GetActionTypeName(AT: TRuleActionType): String;
Begin
 Case AT Of
  ratMoveToFolder: Rules_GetActionTypeName := 'Deplacer vers dossier';
  ratCopyToFolder: Rules_GetActionTypeName := 'Copier vers dossier';
  ratMarkAsRead: Rules_GetActionTypeName := 'Marquer comme lu';
  ratMarkAsUnread: Rules_GetActionTypeName := 'Marquer comme non lu';
  ratSetFlag: Rules_GetActionTypeName := 'Ajouter un drapeau';
  ratClearFlag: Rules_GetActionTypeName := 'Retirer le drapeau';
  ratSetPriority: Rules_GetActionTypeName := 'Definir priorite';
  ratDelete: Rules_GetActionTypeName := 'Supprimer';
  ratForwardTo: Rules_GetActionTypeName := 'Transferer a';
  ratAutoReply: Rules_GetActionTypeName := 'Repondre auto';
  ratPlaySound: Rules_GetActionTypeName := 'Jouer un son';
  ratStopProcessing: Rules_GetActionTypeName := 'Arreter traitement';
  Else Rules_GetActionTypeName := 'Inconnu';
 End;
End;

{ Fichier binaire versionne; chargement transactionnel et remplacement avec sauvegarde. }
Function Rules_Path: String;
Var Path: String; I: Integer;
Begin
 Path:=AccountFileName; I:=Length(Path);
 While (I>0) And Not (Path[I] In ['.',Chr(92),'/']) Do Dec(I);
 If (I>0) And (Path[I]='.') Then Delete(Path,I,255);
 Rules_Path:=Path+'.RUL';
End;

Function Rules_Valid(Const R: TFilterRule): Boolean;
Var I: Integer;
Begin
 Rules_Valid:=False;
 If (R.ID<1) Or (Ord(R.Enabled)>1) Or (Ord(R.ApplyToIncoming)>1) Or
    (Ord(R.ApplyToOutgoing)>1) Or (Length(R.Name)>40) Or (Length(R.Description)>80) Or
    (R.ConditionCount<1) Or (R.ConditionCount>MAX_RULE_CONDITIONS) Or
    (R.ActionCount<1) Or (R.ActionCount>MAX_RULE_ACTIONS) Or
    (Ord(R.RuleOperator)>Ord(High(TRuleOperator))) Then Exit;
 For I:=0 To R.ConditionCount-1 Do Begin
  If (Length(R.Conditions[I].Value)>80) Or (Ord(R.Conditions[I].CaseSensitive)>1) Then Exit;
  If Not (R.Conditions[I].ConditionType In [rctSenderContains,rctSenderEquals,
    rctSubjectContains,rctSubjectStartsWith,rctBodyContains,rctSizeGreaterThan,
    rctSizeLessThan,rctHasAttachment,rctPriorityEquals,rctToContains,rctCcContains]) Then Exit;
 End;
 For I:=0 To R.ActionCount-1 Do
  If Not (R.Actions[I].ActionType In [ratMarkAsRead,ratMarkAsUnread,ratSetFlag,
    ratClearFlag,ratSetPriority,ratStopProcessing]) Or
    (Ord(R.Actions[I].PriorityValue)>Ord(High(TMessagePriority))) Then Exit;
 Rules_Valid:=True;
End;

Function Rules_Save: Boolean;
Var F: File; Path,Temp,Backup: String; Signature: String[12];
 I,Err: Integer; Written: LongInt; Count,RecordSize: Word; HadFile: Boolean;
 Procedure WritePart(Var Data; Size: Word);
 Begin
  If Err<>0 Then Exit;
  {$I-}
  BlockWrite(F,Data,Size,Written); Err:=IOResult;
  {$I+}
  If Written<>Size Then Err:=101;
 End;
Begin
 Rules_Save:=False; RulesError:=''; Path:=Rules_Path; Temp:=Path+'.TMP'; Backup:=Path+'.BAK';
 {$I-}
 Assign(F,Temp); Reset(F,1); Err:=IOResult;
 If Err=0 Then Begin Close(F); Err:=IOResult;
  RulesError:='Fichier temporaire deja present.'; Exit; End;
 If (Err<>2) And (Err<>3) Then Begin RulesError:='Fichier temporaire inaccessible.'; Exit; End;
 Assign(F,Temp); Rewrite(F,1); Err:=IOResult;
 If Err<>0 Then Begin RulesError:='Impossible de sauvegarder les regles.'; Exit; End;
 FillChar(Signature,SizeOf(Signature),0);
 Signature:='OE-RULES-1'; Count:=RuleCount; RecordSize:=SizeOf(TFilterRule);
 WritePart(Signature,SizeOf(Signature)); WritePart(RecordSize,SizeOf(RecordSize));
 WritePart(Count,SizeOf(Count));
 For I:=0 To RuleCount-1 Do WritePart(FilterRules^[I],SizeOf(TFilterRule));
 Close(F); I:=IOResult; If Err=0 Then Err:=I;
 If Err<>0 Then Begin Erase(F); I:=IOResult;
  RulesError:='Erreur ecriture des regles.'; Exit; End;
 Assign(F,Path); Reset(F,1); HadFile:=IOResult=0;
 If HadFile Then Begin
  Close(F); Err:=IOResult;
  Assign(F,Backup); Erase(F); Err:=IOResult;
  Assign(F,Path); Rename(F,Backup); Err:=IOResult;
  If Err<>0 Then Begin Assign(F,Temp); Erase(F); I:=IOResult;
   RulesError:='Impossible de remplacer les regles.'; Exit; End;
 End;
 Assign(F,Temp); Rename(F,Path); Err:=IOResult;
 If Err<>0 Then Begin
  If HadFile Then Begin Assign(F,Backup); Rename(F,Path); I:=IOResult; End;
  RulesError:='Impossible de finaliser les regles.'; Exit;
 End;
 {$I+}
 Rules_Save:=True;
End;

Procedure Rules_Load;
Var F: File; Signature: String[12]; Count,RecordSize: Word;
 I,Err: Integer; ReadCount,Expected: LongInt;
 Procedure ReadPart(Var Data; Size: Word);
 Begin
  If Err<>0 Then Exit;
  {$I-}
  BlockRead(F,Data,Size,ReadCount); Err:=IOResult;
  {$I+}
  If ReadCount<>Size Then Err:=100;
 End;
Begin
 RulesError:=''; Count:=0; RecordSize:=0; Signature:='';
 {$I-}
 Assign(F,Rules_Path); Reset(F,1); Err:=IOResult;
 If Err=2 Then Exit;
 If Err<>0 Then Begin RulesError:='Impossible de lire les regles.'; Exit; End;
 ReadPart(Signature,SizeOf(Signature)); ReadPart(RecordSize,SizeOf(RecordSize)); ReadPart(Count,SizeOf(Count));
 If (Err=0) And ((Signature<>'OE-RULES-1') Or (RecordSize<>SizeOf(TFilterRule)) Or
    (Count>MAX_RULES)) Then Err:=100;
 If Err=0 Then Begin
  Expected:=SizeOf(Signature)+4+LongInt(Count)*RecordSize;
  If FileSize(F)<>Expected Then Err:=100;
 End;
 For I:=0 To Count-1 Do Begin
  If Err<>0 Then Break;
  ReadPart(RulesBackup^[I],SizeOf(TFilterRule));
  If (Err=0) And Not Rules_Valid(RulesBackup^[I]) Then Err:=100;
 End;
 Close(F); I:=IOResult; If Err=0 Then Err:=I;
 {$I+}
 If Err<>0 Then Begin RulesError:='Fichier de regles invalide ou incompatible.'; Exit; End;
 RuleCount:=Count; RuleNextID:=1;
 For I:=0 To RuleCount-1 Do Begin
  FilterRules^[I]:=RulesBackup^[I]; FilterRules^[I].Order:=I;
  If FilterRules^[I].ID>=RuleNextID Then RuleNextID:=FilterRules^[I].ID+1;
 End;
End;

Function Rules_Condition(Index: Integer): TRuleConditionType;
Begin
 Case Index Of
  0: Rules_Condition:=rctSenderContains; 1: Rules_Condition:=rctSenderEquals;
  2: Rules_Condition:=rctSubjectContains; 3: Rules_Condition:=rctSubjectStartsWith;
  4: Rules_Condition:=rctBodyContains; 5: Rules_Condition:=rctSizeGreaterThan;
  6: Rules_Condition:=rctSizeLessThan; 7: Rules_Condition:=rctHasAttachment;
  8: Rules_Condition:=rctPriorityEquals; 9: Rules_Condition:=rctToContains;
 Else Rules_Condition:=rctCcContains;
 End;
End;

Function Rules_Action(Index: Integer): TRuleActionType;
Begin
 Case Index Of
  0: Rules_Action:=ratMarkAsRead; 1: Rules_Action:=ratMarkAsUnread;
  2: Rules_Action:=ratSetFlag; 3: Rules_Action:=ratClearFlag;
  4: Rules_Action:=ratSetPriority;
 Else Rules_Action:=ratStopProcessing;
 End;
End;

Procedure Rules_BeginEdit(IsNew: Boolean);
Begin
 If IsNew Then Begin
  If RuleCount>=MAX_RULES Then Begin RulesError:='Nombre maximal de regles atteint.'; Exit; End;
  Rules_InitRule(EditingRule); EditingRuleIndex:=-1;
  EditingRule.ConditionCount:=1; EditingRule.ActionCount:=1;
  EditingRule.Conditions[0].ConditionType:=rctSubjectContains;
  EditingRule.Actions[0].ActionType:=ratMarkAsRead;
  RulesWindowState:=rwsNew;
 End Else Begin
  If (RulesSelectedIndex<0) Or (RulesSelectedIndex>=RuleCount) Then Exit;
  If (FilterRules^[RulesSelectedIndex].ConditionCount<>1) Or
     (FilterRules^[RulesSelectedIndex].ActionCount>2) Or
     ((FilterRules^[RulesSelectedIndex].ActionCount=2) And
      (FilterRules^[RulesSelectedIndex].Actions[1].ActionType<>ratStopProcessing)) Then Begin
   RulesError:='Cette regle complexe ne peut pas etre editee ici.'; Exit;
  End;
  EditingRule:=FilterRules^[RulesSelectedIndex]; EditingRuleIndex:=RulesSelectedIndex;
  RulesWindowState:=rwsEdit;
 End;
 RulesStopAfter:=(EditingRule.ActionCount>1) And
  (EditingRule.Actions[1].ActionType=ratStopProcessing);
 RulesFocus:=0; RulesTextCursor:=Length(EditingRule.Name); RulesError:='';
End;

Procedure Rules_DrawEditor;
Var X,Y,I: Integer; Text,LabelText: String;
Begin
 X:=RulesWindowX; Y:=RulesWindowY;
 DrawDialogBox(X,Y,RULES_WINDOW_WIDTH,RULES_WINDOW_HEIGHT,'Regle de message');
 For I:=0 To 6 Do Begin
  Text:=''; LabelText:='';
  Case I Of
   0: Begin LabelText:='Nom :'; Text:=EditingRule.Name; End;
   1: Begin LabelText:='Condition :'; Text:=Rules_GetConditionTypeName(EditingRule.Conditions[0].ConditionType); End;
   2: Begin LabelText:='Valeur :'; Text:=EditingRule.Conditions[0].Value; End;
   3: Begin LabelText:='Action :'; Text:=Rules_GetActionTypeName(EditingRule.Actions[0].ActionType); End;
   4: Begin LabelText:='Priorite :'; Case EditingRule.Actions[0].PriorityValue Of
    mpHigh: Text:='HIGH'; mpNormal: Text:='NORMAL'; mpLow: Text:='LOW'; End; End;
   5: Begin LabelText:='Arreter ensuite :'; Text:='Non'; If RulesStopAfter Then Text:='Oui'; End;
   6: Begin LabelText:='Active :'; Text:='Non'; If EditingRule.Enabled Then Text:='Oui'; End;
  End;
  GSetColor(Black); GOutTextXY(X+16,Y+40+I*36,LabelText);
  FillRect(X+164,Y+34+I*36,X+500,Y+60+I*36,White);
  GSetColor(Black);
  If ((I=0) Or (I=2)) And (RulesFocus=I) Then Begin
   Text:=Copy(Text,1,RulesTextCursor)+'|'+Copy(Text,RulesTextCursor+1,255);
   If RulesTextCursor>38 Then Delete(Text,1,RulesTextCursor-38);
  End;
  If RulesFocus=I Then Text:='> '+Text;
  GOutTextXY(X+168,Y+42+I*36,Copy(Text,1,40));
 End;
 GSetColor(Black); GOutTextXY(X+16,Y+300,'Fleches / Espace : choisir. Tab : champ suivant.');
 GOutTextXY(X+16,Y+322,RulesError);
 DrawDialogButton(X+304,Y+356,90,28,'OK',RulesFocus=7,True);
 DrawDialogButton(X+406,Y+356,98,28,'Annuler',RulesFocus=8,True);
End;

Procedure Rules_CommitEditor;
Var Code,I,OldCount,OldNext: Integer; Value: LongInt; Old: TFilterRule;
Begin
 RulesError:='';
 If MailTrim(EditingRule.Name)='' Then Begin RulesError:='Saisir un nom.'; Exit; End;
 If EditingRule.Conditions[0].ConditionType<>rctHasAttachment Then
  If MailTrim(EditingRule.Conditions[0].Value)='' Then Begin RulesError:='Saisir une valeur.'; Exit; End;
 If EditingRule.Conditions[0].ConditionType In [rctSizeGreaterThan,rctSizeLessThan] Then Begin
  Val(EditingRule.Conditions[0].Value,Value,Code);
  If (Code<>0) Or (Value<0) Then Begin RulesError:='Taille : nombre positif en octets.'; Exit; End;
  EditingRule.Conditions[0].NumericValue:=Value;
 End;
 If EditingRule.Conditions[0].ConditionType=rctPriorityEquals Then Begin
  EditingRule.Conditions[0].Value:=Copy(MailUpper(MailTrim(EditingRule.Conditions[0].Value)),1,80);
  If (EditingRule.Conditions[0].Value<>'HIGH') And (EditingRule.Conditions[0].Value<>'NORMAL') And
     (EditingRule.Conditions[0].Value<>'LOW') Then Begin RulesError:='Priorite : HIGH, NORMAL ou LOW.'; Exit; End;
 End;
 EditingRule.ConditionCount:=1; EditingRule.ActionCount:=1;
 If RulesStopAfter Then Begin EditingRule.ActionCount:=2;
  EditingRule.Actions[1].ActionType:=ratStopProcessing; End;
 OldCount:=RuleCount; OldNext:=RuleNextID;
 If EditingRuleIndex<0 Then I:=Rules_AddRule(EditingRule)
 Else Begin I:=EditingRuleIndex; Old:=FilterRules^[I]; FilterRules^[I]:=EditingRule; End;
 If Not Rules_Save Then Begin
  RuleCount:=OldCount; RuleNextID:=OldNext;
  If EditingRuleIndex>=0 Then FilterRules^[I]:=Old;
  Exit;
 End;
 RulesSelectedIndex:=I;
 If I>=RulesScrollOffset+RULES_VISIBLE Then RulesScrollOffset:=I-RULES_VISIBLE+1;
 RulesWindowState:=rwsList; RulesFocus:=0;
End;

{ Dessine la fenetre des regles }
Procedure Rules_DrawWindow;
Var
 X, Y, W, H: Integer;
 I, Y1: Integer;
 DisplayStr: String;
 EnabledStr: String;
Begin
 If Not RulesVisible Then Exit;
 If RulesWindowState In [rwsNew,rwsEdit] Then Begin Rules_DrawEditor; Exit; End;
 If RulesSelectedIndex<RulesScrollOffset Then RulesScrollOffset:=RulesSelectedIndex;
 If RulesSelectedIndex>=RulesScrollOffset+RULES_VISIBLE Then
  RulesScrollOffset:=RulesSelectedIndex-RULES_VISIBLE+1;
 If RulesScrollOffset>RuleCount-RULES_VISIBLE Then RulesScrollOffset:=RuleCount-RULES_VISIBLE;
 If RulesScrollOffset<0 Then RulesScrollOffset:=0;

 X := RulesWindowX;
 Y := RulesWindowY;
 W := RULES_WINDOW_WIDTH;
 H := RULES_WINDOW_HEIGHT;

 { Fond de la fenetre }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X, Y, X + W, Y + H);

 { Bordure }
 GSetColor(DarkGray);
 GRectangle(X, Y, X + W, Y + H);
 GSetColor(White);
 GLine(X + 1, Y + 1, X + W - 1, Y + 1);
 GLine(X + 1, Y + 1, X + 1, Y + H - 1);

 { Barre de titre }
 GSetFillStyle(SolidFill, Blue);
 GBar(X + 2, Y + 2, X + W - 2, Y + 22);
 GSetColor(White);
 GOutTextXY(X + 10, Y + 7, 'Regles de filtrage des messages');

 { Bouton fermer }
 GSetFillStyle(SolidFill, Red);
 GBar(X + W - 20, Y + 4, X + W - 4, Y + 20);
 GSetColor(White);
 GOutTextXY(X + W - 16, Y + 7, 'X');

 { Boutons de gestion }
 Y1 := Y + 30;

 { Bouton Nouvelle regle }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + 10, Y1, X + 100, Y1 + 22);
 GSetColor(Black);
 GRectangle(X + 10, Y1, X + 100, Y1 + 22);
 GOutTextXY(X + 18, Y1 + 6, 'Nouveau');

 { Bouton Modifier }
 GBar(X + 110, Y1, X + 190, Y1 + 22);
 GRectangle(X + 110, Y1, X + 190, Y1 + 22);
 GOutTextXY(X + 118, Y1 + 6, 'Modifier');

 { Bouton Supprimer }
 GBar(X + 200, Y1, X + 290, Y1 + 22);
 GRectangle(X + 200, Y1, X + 290, Y1 + 22);
 GOutTextXY(X + 206, Y1 + 6, 'Supprimer');

 { Bouton Monter }
 GBar(X + W - 170, Y1, X + W - 90, Y1 + 22);
 GRectangle(X + W - 170, Y1, X + W - 90, Y1 + 22);
 GOutTextXY(X + W - 162, Y1 + 6, 'Monter');

 { Bouton Descendre }
 GBar(X + W - 80, Y1, X + W - 10, Y1 + 22);
 GRectangle(X + W - 80, Y1, X + W - 10, Y1 + 22);
 GOutTextXY(X + W - 72, Y1 + 6, 'Descendre');

 { En-tetes de colonnes }
 Y1 := Y + 60;
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + 10, Y1, X + W - 10, Y1 + 18);
 GSetColor(Black);
 GRectangle(X + 10, Y1, X + W - 10, Y1 + 18);
 GOutTextXY(X + 15, Y1 + 4, 'Act');
 GOutTextXY(X + 50, Y1 + 4, 'Nom de la regle');
 GOutTextXY(X + 250, Y1 + 4, 'Conditions');
 GOutTextXY(X + 370, Y1 + 4, 'Actions');
 GOutTextXY(X + 460, Y1 + 4, 'Exec.');

 { Liste des regles }
 Y1 := Y + 80;
 For I := 0 To RULES_VISIBLE - 1 Do Begin
  If I + RulesScrollOffset >= RuleCount Then Break;

  { Fond de la ligne }
  If I + RulesScrollOffset = RulesSelectedIndex Then
   GSetFillStyle(SolidFill, Blue)
  Else If (I Mod 2) = 0 Then
   GSetFillStyle(SolidFill, White)
  Else
   GSetFillStyle(SolidFill, LightGray);

  GBar(X + 10, Y1 + I * RULE_LINE_HEIGHT,
      X + W - 10, Y1 + (I + 1) * RULE_LINE_HEIGHT - 1);

  If I + RulesScrollOffset = RulesSelectedIndex Then
   GSetColor(White)
  Else
   GSetColor(Black);

  { Case a cocher Active }
  If FilterRules^[I + RulesScrollOffset].Enabled Then
   EnabledStr := '[X]'
  Else
   EnabledStr := '[ ]';
  GOutTextXY(X + 15, Y1 + I * RULE_LINE_HEIGHT + 5, EnabledStr);

  { Nom de la regle }
  DisplayStr := FilterRules^[I + RulesScrollOffset].Name;
  If Length(DisplayStr) > 24 Then
   DisplayStr := Copy(DisplayStr, 1, 22) + '..';
  GOutTextXY(X + 50, Y1 + I * RULE_LINE_HEIGHT + 5, DisplayStr);

  { Nombre de conditions }
  Str(FilterRules^[I + RulesScrollOffset].ConditionCount, DisplayStr);
  DisplayStr := DisplayStr + ' cond.';
  GOutTextXY(X + 250, Y1 + I * RULE_LINE_HEIGHT + 5, DisplayStr);

  { Nombre d'actions }
  Str(FilterRules^[I + RulesScrollOffset].ActionCount, DisplayStr);
  DisplayStr := DisplayStr + ' act.';
  GOutTextXY(X + 370, Y1 + I * RULE_LINE_HEIGHT + 5, DisplayStr);

  { Nombre d'executions }
  Str(FilterRules^[I + RulesScrollOffset].TriggerCount, DisplayStr);
  GOutTextXY(X + 460, Y1 + I * RULE_LINE_HEIGHT + 5, DisplayStr);
 End;

 { Boutons du bas }
 Y1 := Y + H - 40;

 { Bouton Appliquer aux messages }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + 10, Y1, X + 180, Y1 + 28);
 GSetColor(Black);
 GRectangle(X + 10, Y1, X + 180, Y1 + 28);
 GOutTextXY(X + 18, Y1 + 9, 'Appliquer maintenant');

 { Compteur }
 GSetColor(DarkGray);
 Str(RuleCount, DisplayStr);
 DisplayStr := DisplayStr + ' regle(s)';
 GOutTextXY(X + W Div 2 - 20, Y1 + 9, DisplayStr);

 { Bouton Fermer }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + W - 80, Y1, X + W - 10, Y1 + 28);
 GSetColor(Black);
 GRectangle(X + W - 80, Y1, X + W - 10, Y1 + 28);
 GOutTextXY(X + W - 62, Y1 + 9, 'Fermer');
 DrawDialogButton(X+10,Y+30,90,22,'Nouveau',RulesFocus=1,RuleCount<MAX_RULES);
 DrawDialogButton(X+110,Y+30,80,22,'Modifier',RulesFocus=2,RulesSelectedIndex>=0);
 DrawDialogButton(X+200,Y+30,90,22,'Supprimer',RulesFocus=3,RulesSelectedIndex>=0);
 DrawDialogButton(X+350,Y+30,80,22,'Monter',RulesFocus=4,RulesSelectedIndex>0);
 DrawDialogButton(X+440,Y+30,70,22,'Descendre',RulesFocus=5,
                  (RulesSelectedIndex>=0) And (RulesSelectedIndex<RuleCount-1));
 DrawDialogButton(X+10,Y+H-40,170,28,'Appliquer maintenant',RulesFocus=6,True);
 DrawDialogButton(X+W-80,Y+H-40,70,28,'Fermer',RulesFocus=7,True);
 GSetColor(Black); GOutTextXY(X+12,Y+H-58,RulesError);
 If RulesDeletePending Then Begin
  FillRect(X+8,Y+H-60,X+W-8,Y+H-4,LightGray);
  GSetColor(Black); GOutTextXY(X+12,Y+H-56,'Supprimer cette regle ?');
  DrawDialogButton(X+10,Y+H-34,90,26,'Oui (O)',False,True);
  DrawDialogButton(X+110,Y+H-34,110,26,'Non (N)',True,True);
 End;
End;

{ Affiche la fenetre des regles }
Procedure Rules_Show;
Begin
 If ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or
    ColumnsDialogVisible Or RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Then Exit;
 RulesWindowX:=(SCREEN_WIDTH-RULES_WINDOW_WIDTH) Div 2;
 RulesWindowY:=(SCREEN_HEIGHT-RULES_WINDOW_HEIGHT) Div 2;
 RulesVisible:=True; RulesWindowState:=rwsList; RulesFocus:=0; RulesDeletePending:=False;
 RulesSelectedIndex:=-1; If RuleCount>0 Then RulesSelectedIndex:=0;
 RulesScrollOffset:=0; ContextMenuVisible:=False; DrawInterface;
End;

Procedure Rules_Hide;
Begin RulesVisible:=False; RulesWindowState:=rwsHidden; DrawInterface; End;

Procedure Rules_ListAction(Action: Integer);
Var I,OldSelection,OldCount: Integer;
Begin
 If Action=1 Then Begin Rules_BeginEdit(True); Exit; End;
 If Action=2 Then Begin Rules_BeginEdit(False); Exit; End;
 If Action=3 Then Begin
  RulesDeletePending:=(RulesSelectedIndex>=0) And (RulesSelectedIndex<RuleCount); Exit;
 End;
 If Action=6 Then Begin Rules_ApplyToAllMessages; RulesError:='Regles appliquees aux messages charges.'; Exit; End;
 If Action=7 Then Begin Rules_Hide; Exit; End;
 If (RulesSelectedIndex<0) Or (RulesSelectedIndex>=RuleCount) Then Exit;
 OldSelection:=RulesSelectedIndex; OldCount:=RuleCount;
 For I:=0 To RuleCount-1 Do RulesBackup^[I]:=FilterRules^[I];
 Case Action Of
  0: Rules_ToggleEnabled(RulesSelectedIndex);
  4: If Rules_MoveUp(RulesSelectedIndex) Then Dec(RulesSelectedIndex);
  5: If Rules_MoveDown(RulesSelectedIndex) Then Inc(RulesSelectedIndex);
  8: Rules_DeleteRule(RulesSelectedIndex);
 End;
 If Not Rules_Save Then Begin
  RuleCount:=OldCount; RulesSelectedIndex:=OldSelection;
  For I:=0 To RuleCount-1 Do FilterRules^[I]:=RulesBackup^[I];
 End;
End;

Procedure Rules_Cycle(Delta: Integer);
Var I,N: Integer;
Begin
 Case RulesFocus Of
  1: Begin
   N:=0; For I:=0 To 10 Do If Rules_Condition(I)=EditingRule.Conditions[0].ConditionType Then N:=I;
   EditingRule.Conditions[0].ConditionType:=Rules_Condition((N+Delta+11) Mod 11);
  End;
  3: Begin
   N:=0; For I:=0 To 5 Do If Rules_Action(I)=EditingRule.Actions[0].ActionType Then N:=I;
   EditingRule.Actions[0].ActionType:=Rules_Action((N+Delta+6) Mod 6);
  End;
  4: EditingRule.Actions[0].PriorityValue:=
      TMessagePriority((Ord(EditingRule.Actions[0].PriorityValue)+Delta+3) Mod 3);
  5: RulesStopAfter:=Not RulesStopAfter;
  6: EditingRule.Enabled:=Not EditingRule.Enabled;
 End;
End;

Procedure Rules_HandleKey(Key: Char; Extended: Boolean);
Var Text: String; Limit: Integer;
Begin
 If RulesDeletePending Then Begin
  If Not Extended Then Case UpCase(Key) Of
   'O': Begin Rules_ListAction(8); RulesDeletePending:=False; End;
   'N',#27,#13: RulesDeletePending:=False;
  End;
 End Else If RulesWindowState In [rwsNew,rwsEdit] Then Begin
  Text:=''; Limit:=80;
  If RulesFocus=0 Then Begin Text:=EditingRule.Name; Limit:=40; End;
  If RulesFocus=2 Then Text:=EditingRule.Conditions[0].Value;
  If Extended Then Begin
   If RulesFocus In [0,2] Then Case Key Of
    #75: If RulesTextCursor>0 Then Dec(RulesTextCursor);
    #77: If RulesTextCursor<Length(Text) Then Inc(RulesTextCursor);
    #71: RulesTextCursor:=0; #79: RulesTextCursor:=Length(Text);
    #83: Delete(Text,RulesTextCursor+1,1);
   End Else If Key In [#75,#72] Then Rules_Cycle(-1)
   Else If Key In [#77,#80] Then Rules_Cycle(1);
   If Key=#15 Then Begin RulesFocus:=(RulesFocus+8) Mod 9; RulesTextCursor:=0; End;
  End Else Case Key Of
   #27: Begin RulesWindowState:=rwsList; RulesError:=''; RulesFocus:=0; End;
   #9: Begin RulesFocus:=(RulesFocus+1) Mod 9; RulesTextCursor:=0; End;
   #13: If RulesFocus=8 Then Begin RulesWindowState:=rwsList; RulesError:=''; RulesFocus:=0; End
        Else Rules_CommitEditor;
   #8: If (RulesFocus In [0,2]) And (RulesTextCursor>0) Then Begin
    Delete(Text,RulesTextCursor,1); Dec(RulesTextCursor); End;
   #32..#255: If RulesFocus In [0,2] Then Begin
    If Length(Text)<Limit Then Begin Insert(Key,Text,RulesTextCursor+1); Inc(RulesTextCursor); End;
   End Else If Key=' ' Then Rules_Cycle(1);
  End;
  { Ne pas reecrire un champ apres un changement de focus ou une validation. }
  If RulesWindowState In [rwsNew,rwsEdit] Then Begin
   If (RulesFocus=0) And Not ((Not Extended And (Key=#9)) Or (Extended And (Key=#15))) Then
    EditingRule.Name:=Text;
   If (RulesFocus=2) And Not ((Not Extended And (Key=#9)) Or (Extended And (Key=#15))) Then
    EditingRule.Conditions[0].Value:=Text;
  End;
 End Else Begin
  If Extended Then Case Key Of
   #72: If RulesSelectedIndex>0 Then Dec(RulesSelectedIndex);
   #80: If RulesSelectedIndex<RuleCount-1 Then Inc(RulesSelectedIndex);
   #71: If RuleCount>0 Then RulesSelectedIndex:=0;
   #79: RulesSelectedIndex:=RuleCount-1;
   #73: Begin Dec(RulesSelectedIndex,RULES_VISIBLE); If RulesSelectedIndex<0 Then RulesSelectedIndex:=0; End;
   #81: Begin Inc(RulesSelectedIndex,RULES_VISIBLE);
    If RulesSelectedIndex>=RuleCount Then RulesSelectedIndex:=RuleCount-1; End;
   #83: Rules_ListAction(3);
   #15: RulesFocus:=(RulesFocus+7) Mod 8;
  End Else Case Key Of
   #27: Rules_Hide;
   #9: RulesFocus:=(RulesFocus+1) Mod 8;
   #13: If RulesFocus=0 Then Rules_BeginEdit(False) Else Rules_ListAction(RulesFocus);
   ' ': Rules_ListAction(RulesFocus);
   'n','N': Rules_BeginEdit(True);
  End;
 End;
 If RulesSelectedIndex<RulesScrollOffset Then RulesScrollOffset:=RulesSelectedIndex;
 If RulesSelectedIndex>=RulesScrollOffset+RULES_VISIBLE Then
  RulesScrollOffset:=RulesSelectedIndex-RULES_VISIBLE+1;
 If RulesScrollOffset<0 Then RulesScrollOffset:=0;
 DrawInterface;
End;

Function Rules_HandleClick(MX,MY: Integer): Boolean;
Var X,Y,I,Row: Integer;
Begin
 Rules_HandleClick:=True; X:=MX-RulesWindowX; Y:=MY-RulesWindowY;
 If (X<0) Or (X>RULES_WINDOW_WIDTH) Or (Y<0) Or (Y>RULES_WINDOW_HEIGHT) Then Exit;
 If RulesDeletePending Then Begin
  If (Y>=366) And (Y<=392) Then Begin
   If (X>=10) And (X<=100) Then Begin Rules_ListAction(8); RulesDeletePending:=False; End
   Else If (X>=110) And (X<=220) Then RulesDeletePending:=False;
  End; Exit;
 End;
 If RulesWindowState In [rwsNew,rwsEdit] Then Begin
  If (X>=164) And (X<=500) And (Y>=34) And (Y<286) Then Begin
   Row:=(Y-34) Div 36;
   If Y<=60+Row*36 Then Begin
    RulesFocus:=Row; RulesTextCursor:=0;
    If Row=0 Then RulesTextCursor:=Length(EditingRule.Name)
    Else If Row=2 Then RulesTextCursor:=Length(EditingRule.Conditions[0].Value)
    Else Rules_Cycle(1);
   End;
  End Else If (Y>=356) And (Y<=384) Then Begin
   If (X>=304) And (X<=394) Then Rules_CommitEditor
   Else If (X>=406) And (X<=504) Then Begin
    RulesWindowState:=rwsList; RulesError:=''; RulesFocus:=0; End;
  End;
  Exit;
 End;
 If (X>=500) And (X<=516) And (Y>=4) And (Y<=20) Then Begin Rules_Hide; Exit; End;
 If (Y>=30) And (Y<=52) Then Begin
  I:=-1;
  If (X>=10) And (X<=100) Then I:=1
  Else If (X>=110) And (X<=190) Then I:=2
  Else If (X>=200) And (X<=290) Then I:=3
  Else If (X>=350) And (X<=430) Then I:=4
  Else If (X>=440) And (X<=510) Then I:=5;
  If I>=0 Then Begin RulesFocus:=I; Rules_ListAction(I); End;
 End Else If (Y>=80) And (Y<80+RULES_VISIBLE*RULE_LINE_HEIGHT) And (X>=10) And (X<=510) Then Begin
  I:=RulesScrollOffset+(Y-80) Div RULE_LINE_HEIGHT;
  If I<RuleCount Then Begin RulesSelectedIndex:=I; RulesFocus:=0;
   If X<=45 Then Rules_ListAction(0); End;
 End Else If (Y>=360) And (Y<=388) Then Begin
  If (X>=10) And (X<=180) Then Rules_ListAction(6)
  Else If (X>=440) And (X<=510) Then Rules_ListAction(7);
 End;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DU SYSTEME DE REGLES
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DE LA RECHERCHE AVANCEE (TODO 18)
  ============================================================================ }

{ Initialise le filtre de recherche }
Procedure Search_InitFilter;
Begin
 SearchFilter.SearchText := '';
 SearchFilter.SearchField := sfAll;
 SearchFilter.CaseSensitive := False;
 SearchFilter.WholeWord := False;
 SearchFilter.HasAttachment := False;
 SearchFilter.FilterByAttachment := False;
 SearchFilter.DateFilterEnabled := False;
 SearchFilter.DateFrom := 0;
 SearchFilter.DateTo := 0;
 SearchFilter.SizeFilterEnabled := False;
 SearchFilter.MinSize := 0;
 SearchFilter.MaxSize := 0;
 SearchFilter.SearchAllFolders := False;
End;

{ Initialise le systeme de recherche }
Procedure Search_Init;
Var
 I: Integer;
Begin
 Search_InitFilter;
 SearchResultCount := 0;
 SearchHistoryCount := 0;
 SearchWindowState := swsHidden;
 SearchWindowX := (640 - SEARCH_WINDOW_WIDTH) Div 2;
 SearchWindowY := (480 - SEARCH_WINDOW_HEIGHT) Div 2;
 SearchVisible := False;
 SearchScrollOffset := 0;
 SearchSelectedIndex := -1;
 SearchInProgress := False;
 HighlightResults := True;
 CurrentHighlightIndex := -1;

 For I := 0 To MAX_SEARCH_RESULTS - 1 Do Begin
  SearchResults[I].MessageIndex := -1;
  SearchResults[I].MatchPosition := 0;
  SearchResults[I].MatchLength := 0;
  SearchResults[I].MatchField := sfAll;
  SearchResults[I].MatchContext := '';
 End;

 For I := 0 To MAX_SEARCH_HISTORY - 1 Do Begin
  SearchHistory[I].SearchText := '';
  SearchHistory[I].SearchDate := 0;
  SearchHistory[I].ResultCount := 0;
 End;
End;

{ Convertit une chaine en minuscules }
Function Search_ToLower(S: String): String;
Var
 I: Integer;
 R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do
  If (R[I] >= 'A') And (R[I] <= 'Z') Then
   R[I] := Chr(Ord(R[I]) + 32);
 Search_ToLower := R;
End;

{ Verifie si une chaine contient un mot entier }
Function Search_ContainsWholeWord(Haystack, Needle: String;
                                   CaseSensitive: Boolean): Boolean;
Var
 H, N: String;
 P: Integer;
 CharBefore, CharAfter: Char;
Begin
 Search_ContainsWholeWord := False;

 If CaseSensitive Then Begin
  H := Haystack;
  N := Needle;
 End
 Else Begin
  H := Search_ToLower(Haystack);
  N := Search_ToLower(Needle);
 End;

 P := Pos(N, H);
 While P > 0 Do Begin
  { Verifier le caractere avant }
  If P > 1 Then
   CharBefore := H[P - 1]
  Else
   CharBefore := ' ';

  { Verifier le caractere apres }
  If P + Length(N) <= Length(H) Then
   CharAfter := H[P + Length(N)]
  Else
   CharAfter := ' ';

  { Verifier si c'est un mot entier }
  If ((CharBefore = ' ') Or (CharBefore = ',') Or (CharBefore = '.') Or
      (CharBefore = ';') Or (CharBefore = ':') Or (CharBefore = '!') Or
      (CharBefore = '?') Or (CharBefore = '<') Or (CharBefore = '>')) And
     ((CharAfter = ' ') Or (CharAfter = ',') Or (CharAfter = '.') Or
      (CharAfter = ';') Or (CharAfter = ':') Or (CharAfter = '!') Or
      (CharAfter = '?') Or (CharAfter = '<') Or (CharAfter = '>')) Then Begin
   Search_ContainsWholeWord := True;
   Exit;
  End;

  { Chercher la prochaine occurrence }
  If P + Length(N) < Length(H) Then Begin
   Delete(H, 1, P);
   P := Pos(N, H);
  End
  Else
   P := 0;
 End;
End;

{ Verifie si une chaine contient une autre }
Function Search_Contains(Haystack, Needle: String;
                          CaseSensitive, WholeWord: Boolean): Integer;
Var
 H, N: String;
 P: Integer;
Begin
 Search_Contains := 0;
 If Length(Needle) = 0 Then Exit;
 If Length(Needle) > Length(Haystack) Then Exit;

 If WholeWord Then Begin
  If Search_ContainsWholeWord(Haystack, Needle, CaseSensitive) Then
   Search_Contains := Pos(Search_ToLower(Needle), Search_ToLower(Haystack))
  Else
   Search_Contains := 0;
  Exit;
 End;

 If CaseSensitive Then Begin
  H := Haystack;
  N := Needle;
 End
 Else Begin
  H := Search_ToLower(Haystack);
  N := Search_ToLower(Needle);
 End;

 P := Pos(N, H);
 Search_Contains := P;
End;

{ Obtient le corps du message comme une seule chaine }
Function Search_GetMessageBody(MsgIndex: Integer): String;
Var
 I: Integer;
 Body: String;
Begin
 Body := '';
 If (MsgIndex >= 0) And (MsgIndex < MessageCount) Then Begin
  For I := 0 To Messages^[MsgIndex].BodyLineCount - 1 Do Begin
   If Length(Body) + Length(Messages^[MsgIndex].Body[I]) < 250 Then
    Body := Body + Messages^[MsgIndex].Body[I] + ' ';
  End;
 End;
 Search_GetMessageBody := Body;
End;

{ Extrait le contexte autour d'une correspondance }
Function Search_GetContext(S: String; MatchPos, MatchLen: Integer): String;
Var
 Start, EndPos: Integer;
 Context: String;
Begin
 { Extraire 30 caracteres avant et apres }
 Start := MatchPos - 30;
 If Start < 1 Then Start := 1;

 EndPos := MatchPos + MatchLen + 30;
 If EndPos > Length(S) Then EndPos := Length(S);

 Context := Copy(S, Start, EndPos - Start + 1);

 { Ajouter des ellipses si necessaire }
 If Start > 1 Then Context := '...' + Context;
 If EndPos < Length(S) Then Context := Context + '...';

 Search_GetContext := Context;
End;

{ Recherche dans un message specifique }
Function Search_InMessage(MsgIndex: Integer): Boolean;
Var
 Found: Boolean;
 MatchPos: Integer;
 FieldText, Body: String;
 NewResult: TSearchResult;
Begin
 Search_InMessage := False;
 Found := False;

 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;
 If SearchResultCount >= MAX_SEARCH_RESULTS Then Exit;

 { Verifier les filtres }
 If SearchFilter.FilterByAttachment Then Begin
  If SearchFilter.HasAttachment <> Messages^[MsgIndex].HasAttachment Then Exit;
 End;

 If SearchFilter.DateFilterEnabled Then Begin
  If (SearchFilter.DateFrom > 0) And
     (Messages^[MsgIndex].DateSort < SearchFilter.DateFrom) Then Exit;
  If (SearchFilter.DateTo > 0) And
     (Messages^[MsgIndex].DateSort > SearchFilter.DateTo) Then Exit;
 End;

 If SearchFilter.SizeFilterEnabled Then Begin
  If (SearchFilter.MinSize > 0) And
     (Messages^[MsgIndex].Size < SearchFilter.MinSize) Then Exit;
  If (SearchFilter.MaxSize > 0) And
     (Messages^[MsgIndex].Size > SearchFilter.MaxSize) Then Exit;
 End;

 { Recherche dans l'objet }
 If (SearchFilter.SearchField = sfSubject) Or (SearchFilter.SearchField = sfAll) Then Begin
  MatchPos := Search_Contains(Messages^[MsgIndex].Subject, SearchFilter.SearchText,
                              SearchFilter.CaseSensitive, SearchFilter.WholeWord);
  If MatchPos > 0 Then Begin
   NewResult.MessageIndex := MsgIndex;
   NewResult.MatchPosition := MatchPos;
   NewResult.MatchLength := Length(SearchFilter.SearchText);
   NewResult.MatchField := sfSubject;
   NewResult.MatchContext := Search_GetContext(Messages^[MsgIndex].Subject,
                                               MatchPos, NewResult.MatchLength);
   SearchResults[SearchResultCount] := NewResult;
   Inc(SearchResultCount);
   Found := True;
   If SearchResultCount >= MAX_SEARCH_RESULTS Then Begin
    Search_InMessage := Found;
    Exit;
   End;
  End;
 End;

 { Recherche dans l'expediteur }
 If (SearchFilter.SearchField = sfSender) Or (SearchFilter.SearchField = sfAll) Then Begin
  FieldText := Messages^[MsgIndex].FromName + ' <' + Messages^[MsgIndex].FromEmail + '>';
  MatchPos := Search_Contains(FieldText, SearchFilter.SearchText,
                              SearchFilter.CaseSensitive, SearchFilter.WholeWord);
  If MatchPos > 0 Then Begin
   NewResult.MessageIndex := MsgIndex;
   NewResult.MatchPosition := MatchPos;
   NewResult.MatchLength := Length(SearchFilter.SearchText);
   NewResult.MatchField := sfSender;
   NewResult.MatchContext := Search_GetContext(FieldText, MatchPos, NewResult.MatchLength);
   SearchResults[SearchResultCount] := NewResult;
   Inc(SearchResultCount);
   Found := True;
   If SearchResultCount >= MAX_SEARCH_RESULTS Then Begin
    Search_InMessage := Found;
    Exit;
   End;
  End;
 End;

 { Recherche dans le destinataire }
 If (SearchFilter.SearchField = sfRecipient) Or (SearchFilter.SearchField = sfAll) Then Begin
  FieldText := Messages^[MsgIndex].ToName + ' <' + Messages^[MsgIndex].ToEmail + '>';
  MatchPos := Search_Contains(FieldText, SearchFilter.SearchText,
                              SearchFilter.CaseSensitive, SearchFilter.WholeWord);
  If MatchPos > 0 Then Begin
   NewResult.MessageIndex := MsgIndex;
   NewResult.MatchPosition := MatchPos;
   NewResult.MatchLength := Length(SearchFilter.SearchText);
   NewResult.MatchField := sfRecipient;
   NewResult.MatchContext := Search_GetContext(FieldText, MatchPos, NewResult.MatchLength);
   SearchResults[SearchResultCount] := NewResult;
   Inc(SearchResultCount);
   Found := True;
   If SearchResultCount >= MAX_SEARCH_RESULTS Then Begin
    Search_InMessage := Found;
    Exit;
   End;
  End;
 End;

 { Recherche dans le corps }
 If (SearchFilter.SearchField = sfBody) Or (SearchFilter.SearchField = sfAll) Then Begin
  Body := Search_GetMessageBody(MsgIndex);
  MatchPos := Search_Contains(Body, SearchFilter.SearchText,
                              SearchFilter.CaseSensitive, SearchFilter.WholeWord);
  If MatchPos > 0 Then Begin
   NewResult.MessageIndex := MsgIndex;
   NewResult.MatchPosition := MatchPos;
   NewResult.MatchLength := Length(SearchFilter.SearchText);
   NewResult.MatchField := sfBody;
   NewResult.MatchContext := Search_GetContext(Body, MatchPos, NewResult.MatchLength);
   SearchResults[SearchResultCount] := NewResult;
   Inc(SearchResultCount);
   Found := True;
  End;
 End;

 Search_InMessage := Found;
End;

{ Execute la recherche }
Procedure Search_Execute;
Var
 I: Integer;
Begin
 SearchResultCount := 0;
 SearchSelectedIndex := -1;
 SearchScrollOffset := 0;
 SearchInProgress := True;

 If Length(SearchFilter.SearchText) = 0 Then Begin
  SearchInProgress := False;
  Exit;
 End;

 { Rechercher dans tous les messages }
 For I := 0 To MessageCount - 1 Do Begin
  Search_InMessage(I);
  If SearchResultCount >= MAX_SEARCH_RESULTS Then Break;
 End;

 SearchInProgress := False;

 { Ajouter a l'historique }
 If SearchResultCount > 0 Then
  Search_AddToHistory(SearchFilter.SearchText, SearchResultCount);
End;

{ Ajoute une recherche a l'historique }
Procedure Search_AddToHistory(SearchText: String; ResultCount: Integer);
Var
 I: Integer;
Begin
 { Verifier si deja dans l'historique }
 For I := 0 To SearchHistoryCount - 1 Do Begin
  If SearchHistory[I].SearchText = SearchText Then Begin
   { Mettre a jour }
   SearchHistory[I].SearchDate := 0; { TODO: Date actuelle }
   SearchHistory[I].ResultCount := ResultCount;
   Exit;
  End;
 End;

 { Decaler si necessaire }
 If SearchHistoryCount >= MAX_SEARCH_HISTORY Then Begin
  For I := 0 To MAX_SEARCH_HISTORY - 2 Do
   SearchHistory[I] := SearchHistory[I + 1];
  SearchHistoryCount := MAX_SEARCH_HISTORY - 1;
 End;

 { Ajouter }
 SearchHistory[SearchHistoryCount].SearchText := SearchText;
 SearchHistory[SearchHistoryCount].SearchDate := 0; { TODO: Date actuelle }
 SearchHistory[SearchHistoryCount].ResultCount := ResultCount;
 Inc(SearchHistoryCount);
End;

{ Efface l'historique de recherche }
Procedure Search_ClearHistory;
Var
 I: Integer;
Begin
 For I := 0 To MAX_SEARCH_HISTORY - 1 Do Begin
  SearchHistory[I].SearchText := '';
  SearchHistory[I].SearchDate := 0;
  SearchHistory[I].ResultCount := 0;
 End;
 SearchHistoryCount := 0;
End;

{ Va au resultat suivant }
Procedure Search_NextResult;
Begin
 If SearchResultCount = 0 Then Exit;

 Inc(CurrentHighlightIndex);
 If CurrentHighlightIndex >= SearchResultCount Then
  CurrentHighlightIndex := 0;

 { Selectionner le message correspondant }
 If SearchResults[CurrentHighlightIndex].MessageIndex >= 0 Then
  SelectedMessage := SearchResults[CurrentHighlightIndex].MessageIndex;
End;

{ Va au resultat precedent }
Procedure Search_PrevResult;
Begin
 If SearchResultCount = 0 Then Exit;

 Dec(CurrentHighlightIndex);
 If CurrentHighlightIndex < 0 Then
  CurrentHighlightIndex := SearchResultCount - 1;

 { Selectionner le message correspondant }
 If SearchResults[CurrentHighlightIndex].MessageIndex >= 0 Then
  SelectedMessage := SearchResults[CurrentHighlightIndex].MessageIndex;
End;

{ Retourne le nom d'un champ de recherche }
Function Search_GetFieldName(Field: TSearchField): String;
Begin
 Case Field Of
  sfSubject: Search_GetFieldName := 'Objet';
  sfBody: Search_GetFieldName := 'Corps';
  sfSender: Search_GetFieldName := 'Expediteur';
  sfRecipient: Search_GetFieldName := 'Destinataire';
  sfAll: Search_GetFieldName := 'Tous';
  Else Search_GetFieldName := 'Inconnu';
 End;
End;

{ Dessine la fenetre de recherche }
Procedure Search_DrawWindow;
Var
 X, Y, W, H: Integer;
 I, Y1: Integer;
 DisplayStr: String;
 CheckStr: String;
Begin
 If Not SearchVisible Then Exit;

 X := SearchWindowX;
 Y := SearchWindowY;
 W := SEARCH_WINDOW_WIDTH;
 H := SEARCH_WINDOW_HEIGHT;

 { Fond de la fenetre }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X, Y, X + W, Y + H);

 { Bordure }
 GSetColor(DarkGray);
 GRectangle(X, Y, X + W, Y + H);
 GSetColor(White);
 GLine(X + 1, Y + 1, X + W - 1, Y + 1);
 GLine(X + 1, Y + 1, X + 1, Y + H - 1);

 { Barre de titre }
 GSetFillStyle(SolidFill, Blue);
 GBar(X + 2, Y + 2, X + W - 2, Y + 22);
 GSetColor(White);
 GOutTextXY(X + 10, Y + 7, 'Recherche avancee');

 { Bouton fermer }
 GSetFillStyle(SolidFill, Red);
 GBar(X + W - 20, Y + 4, X + W - 4, Y + 20);
 GSetColor(White);
 GOutTextXY(X + W - 16, Y + 7, 'X');

 { Zone de saisie du texte }
 Y1 := Y + 30;
 GSetColor(Black);
 GOutTextXY(X + 10, Y1 + 4, 'Rechercher:');

 GSetFillStyle(SolidFill, White);
 GBar(X + 90, Y1, X + W - 10, Y1 + 20);
 GSetColor(Black);
 GRectangle(X + 90, Y1, X + W - 10, Y1 + 20);
 GOutTextXY(X + 95, Y1 + 5, SearchFilter.SearchText);

 { Options de recherche }
 Y1 := Y + 58;
 GSetColor(Black);
 GOutTextXY(X + 10, Y1, 'Rechercher dans:');

 { Radio boutons pour le champ }
 Y1 := Y + 75;
 If SearchFilter.SearchField = sfAll Then CheckStr := '(o)' Else CheckStr := '( )';
 GOutTextXY(X + 10, Y1, CheckStr + ' Tous');
 If SearchFilter.SearchField = sfSubject Then CheckStr := '(o)' Else CheckStr := '( )';
 GOutTextXY(X + 100, Y1, CheckStr + ' Objet');
 If SearchFilter.SearchField = sfSender Then CheckStr := '(o)' Else CheckStr := '( )';
 GOutTextXY(X + 200, Y1, CheckStr + ' Expediteur');

 Y1 := Y + 92;
 If SearchFilter.SearchField = sfBody Then CheckStr := '(o)' Else CheckStr := '( )';
 GOutTextXY(X + 10, Y1, CheckStr + ' Corps');
 If SearchFilter.SearchField = sfRecipient Then CheckStr := '(o)' Else CheckStr := '( )';
 GOutTextXY(X + 100, Y1, CheckStr + ' Destinataire');

 { Cases a cocher }
 Y1 := Y + 115;
 If SearchFilter.CaseSensitive Then CheckStr := '[X]' Else CheckStr := '[ ]';
 GOutTextXY(X + 10, Y1, CheckStr + ' Respecter la casse');

 If SearchFilter.WholeWord Then CheckStr := '[X]' Else CheckStr := '[ ]';
 GOutTextXY(X + 200, Y1, CheckStr + ' Mot entier');

 Y1 := Y + 132;
 If SearchFilter.FilterByAttachment Then CheckStr := '[X]' Else CheckStr := '[ ]';
 GOutTextXY(X + 10, Y1, CheckStr + ' Avec pieces jointes uniquement');

 If SearchFilter.SearchAllFolders Then CheckStr := '[X]' Else CheckStr := '[ ]';
 GOutTextXY(X + 250, Y1, CheckStr + ' Tous dossiers');

 { Boutons }
 Y1 := Y + 155;
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + 10, Y1, X + 100, Y1 + 25);
 GSetColor(Black);
 GRectangle(X + 10, Y1, X + 100, Y1 + 25);
 GOutTextXY(X + 22, Y1 + 8, 'Rechercher');

 GBar(X + 110, Y1, X + 200, Y1 + 25);
 GRectangle(X + 110, Y1, X + 200, Y1 + 25);
 GOutTextXY(X + 130, Y1 + 8, 'Effacer');

 { Zone des resultats }
 Y1 := Y + 190;
 GSetColor(Black);
 Str(SearchResultCount, DisplayStr);
 GOutTextXY(X + 10, Y1, 'Resultats: ' + DisplayStr);

 { En-tete }
 Y1 := Y + 208;
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + 10, Y1, X + W - 10, Y1 + 16);
 GSetColor(Black);
 GRectangle(X + 10, Y1, X + W - 10, Y1 + 16);
 GOutTextXY(X + 15, Y1 + 3, 'Champ');
 GOutTextXY(X + 100, Y1 + 3, 'Contexte');

 { Liste des resultats }
 Y1 := Y + 226;
 For I := 0 To SEARCH_RESULTS_VISIBLE - 1 Do Begin
  If I + SearchScrollOffset >= SearchResultCount Then Break;

  { Fond de la ligne }
  If I + SearchScrollOffset = SearchSelectedIndex Then
   GSetFillStyle(SolidFill, Blue)
  Else If (I Mod 2) = 0 Then
   GSetFillStyle(SolidFill, White)
  Else
   GSetFillStyle(SolidFill, LightGray);

  GBar(X + 10, Y1 + I * SEARCH_RESULT_HEIGHT,
      X + W - 10, Y1 + (I + 1) * SEARCH_RESULT_HEIGHT - 1);

  If I + SearchScrollOffset = SearchSelectedIndex Then
   GSetColor(White)
  Else
   GSetColor(Black);

  { Champ }
  DisplayStr := Search_GetFieldName(SearchResults[I + SearchScrollOffset].MatchField);
  GOutTextXY(X + 15, Y1 + I * SEARCH_RESULT_HEIGHT + 4, DisplayStr);

  { Contexte }
  DisplayStr := SearchResults[I + SearchScrollOffset].MatchContext;
  If Length(DisplayStr) > 45 Then
   DisplayStr := Copy(DisplayStr, 1, 43) + '..';
  GOutTextXY(X + 100, Y1 + I * SEARCH_RESULT_HEIGHT + 4, DisplayStr);
 End;

 { Boutons du bas }
 Y1 := Y + H - 35;

 { Bouton Precedent }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X + 10, Y1, X + 100, Y1 + 25);
 GSetColor(Black);
 GRectangle(X + 10, Y1, X + 100, Y1 + 25);
 GOutTextXY(X + 22, Y1 + 8, 'Precedent');

 { Bouton Suivant }
 GBar(X + 110, Y1, X + 200, Y1 + 25);
 GRectangle(X + 110, Y1, X + 200, Y1 + 25);
 GOutTextXY(X + 130, Y1 + 8, 'Suivant');

 { Bouton Fermer }
 GBar(X + W - 80, Y1, X + W - 10, Y1 + 25);
 GRectangle(X + W - 80, Y1, X + W - 10, Y1 + 25);
 GOutTextXY(X + W - 62, Y1 + 8, 'Fermer');
End;

{ Affiche la fenetre de recherche }
Procedure Search_Show;
Begin
 SearchVisible := True;
 SearchWindowState := swsAdvanced;
 SearchSelectedIndex := -1;
 SearchScrollOffset := 0;
End;

{ Cache la fenetre de recherche }
Procedure Search_Hide;
Begin
 SearchVisible := False;
 SearchWindowState := swsHidden;
End;

{ Gere un clic dans la fenetre de recherche }
Function Search_HandleClick(MX, MY: Integer): Boolean;
Var
 X, Y, W, H: Integer;
 I, Y1: Integer;
Begin
 Search_HandleClick := False;
 If Not SearchVisible Then Exit;

 X := SearchWindowX;
 Y := SearchWindowY;
 W := SEARCH_WINDOW_WIDTH;
 H := SEARCH_WINDOW_HEIGHT;

 { Verifier si clic dans la fenetre }
 If (MX < X) Or (MX > X + W) Or (MY < Y) Or (MY > Y + H) Then Exit;

 Search_HandleClick := True;

 { Bouton fermer }
 If (MX >= X + W - 20) And (MX <= X + W - 4) And (MY >= Y + 4) And (MY <= Y + 20) Then Begin
  Search_Hide;
  Exit;
 End;

 { Radio boutons - Champ de recherche }
 Y1 := Y + 75;
 If (MY >= Y1 - 2) And (MY <= Y1 + 14) Then Begin
  If (MX >= X + 10) And (MX <= X + 90) Then
   SearchFilter.SearchField := sfAll
  Else If (MX >= X + 100) And (MX <= X + 180) Then
   SearchFilter.SearchField := sfSubject
  Else If (MX >= X + 200) And (MX <= X + 320) Then
   SearchFilter.SearchField := sfSender;
  Exit;
 End;

 Y1 := Y + 92;
 If (MY >= Y1 - 2) And (MY <= Y1 + 14) Then Begin
  If (MX >= X + 10) And (MX <= X + 90) Then
   SearchFilter.SearchField := sfBody
  Else If (MX >= X + 100) And (MX <= X + 220) Then
   SearchFilter.SearchField := sfRecipient;
  Exit;
 End;

 { Cases a cocher }
 Y1 := Y + 115;
 If (MY >= Y1 - 2) And (MY <= Y1 + 14) Then Begin
  If (MX >= X + 10) And (MX <= X + 180) Then
   SearchFilter.CaseSensitive := Not SearchFilter.CaseSensitive
  Else If (MX >= X + 200) And (MX <= X + 320) Then
   SearchFilter.WholeWord := Not SearchFilter.WholeWord;
  Exit;
 End;

 Y1 := Y + 132;
 If (MY >= Y1 - 2) And (MY <= Y1 + 14) Then Begin
  If (MX >= X + 10) And (MX <= X + 240) Then Begin
   SearchFilter.FilterByAttachment := Not SearchFilter.FilterByAttachment;
   If SearchFilter.FilterByAttachment Then
    SearchFilter.HasAttachment := True;
  End
  Else If (MX >= X + 250) And (MX <= X + 400) Then
   SearchFilter.SearchAllFolders := Not SearchFilter.SearchAllFolders;
  Exit;
 End;

 { Bouton Rechercher }
 Y1 := Y + 155;
 If (MX >= X + 10) And (MX <= X + 100) And (MY >= Y1) And (MY <= Y1 + 25) Then Begin
  Search_Execute;
  Exit;
 End;

 { Bouton Effacer }
 If (MX >= X + 110) And (MX <= X + 200) And (MY >= Y1) And (MY <= Y1 + 25) Then Begin
  Search_InitFilter;
  SearchResultCount := 0;
  Exit;
 End;

 { Liste des resultats }
 Y1 := Y + 226;
 For I := 0 To SEARCH_RESULTS_VISIBLE - 1 Do Begin
  If I + SearchScrollOffset >= SearchResultCount Then Break;

  If (MY >= Y1 + I * SEARCH_RESULT_HEIGHT) And
     (MY < Y1 + (I + 1) * SEARCH_RESULT_HEIGHT) Then Begin
   SearchSelectedIndex := I + SearchScrollOffset;
   { Selectionner le message correspondant }
   If SearchResults[SearchSelectedIndex].MessageIndex >= 0 Then Begin
    SelectedMessage := SearchResults[SearchSelectedIndex].MessageIndex;
    CurrentHighlightIndex := SearchSelectedIndex;
   End;
   Exit;
  End;
 End;

 { Boutons du bas }
 Y1 := Y + H - 35;

 { Bouton Precedent }
 If (MX >= X + 10) And (MX <= X + 100) And (MY >= Y1) And (MY <= Y1 + 25) Then Begin
  Search_PrevResult;
  Exit;
 End;

 { Bouton Suivant }
 If (MX >= X + 110) And (MX <= X + 200) And (MY >= Y1) And (MY <= Y1 + 25) Then Begin
  Search_NextResult;
  Exit;
 End;

 { Bouton Fermer }
 If (MX >= X + W - 80) And (MX <= X + W - 10) And (MY >= Y1) And (MY <= Y1 + 25) Then Begin
  Search_Hide;
  Exit;
 End;
End;

{ Gere une touche dans la fenetre de recherche }
Function Search_HandleKey(Key: Char): Boolean;
Begin
 Search_HandleKey := False;
 If Not SearchVisible Then Exit;

 Search_HandleKey := True;

 Case Key Of
  #27: { Echap }
   Search_Hide;
  #13: { Entree }
   Search_Execute;
  #8: { Backspace }
   If Length(SearchFilter.SearchText) > 0 Then
    Delete(SearchFilter.SearchText, Length(SearchFilter.SearchText), 1);
  Else
   If (((Key >= ' ') And (Key <= '~')) Or (Key >= #128)) Then Begin
    If Length(SearchFilter.SearchText) < 78 Then
     SearchFilter.SearchText := SearchFilter.SearchText + Key;
   End
   Else
    Search_HandleKey := False;
 End;
End;

{ Dessine la surbrillance d'un texte }
Procedure Search_HighlightText(X, Y: Integer; Text: String; MatchPos, MatchLen: Integer);
Var
 BeforeText, MatchText, AfterText: String;
 X1: Integer;
Begin
 If (MatchPos <= 0) Or (MatchPos > Length(Text)) Then Begin
  GSetColor(Black);
  GOutTextXY(X, Y, Text);
  Exit;
 End;

 BeforeText := Copy(Text, 1, MatchPos - 1);
 MatchText := Copy(Text, MatchPos, MatchLen);
 AfterText := Copy(Text, MatchPos + MatchLen, Length(Text) - MatchPos - MatchLen + 1);

 { Texte avant }
 GSetColor(Black);
 GOutTextXY(X, Y, BeforeText);
 X1 := X + GTextWidth(BeforeText);

 { Texte en surbrillance }
 GSetFillStyle(SolidFill, Yellow);
 GBar(X1, Y - 1, X1 + GTextWidth(MatchText), Y + GTextHeight(MatchText) + 1);
 GSetColor(Black);
 GOutTextXY(X1, Y, MatchText);
 X1 := X1 + GTextWidth(MatchText);

 { Texte apres }
 GSetColor(Black);
 GOutTextXY(X1, Y, AfterText);
End;

{ Verifie si un message fait partie des resultats de recherche }
Function Search_IsHighlighted(MsgIndex: Integer): Boolean;
Var
 I: Integer;
Begin
 Search_IsHighlighted := False;
 If Not HighlightResults Then Exit;
 If SearchResultCount = 0 Then Exit;

 For I := 0 To SearchResultCount - 1 Do Begin
  If SearchResults[I].MessageIndex = MsgIndex Then Begin
   Search_IsHighlighted := True;
   Exit;
  End;
 End;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DE LA RECHERCHE AVANCEE
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DE LA GESTION DES SIGNATURES (TODO 19)
  ============================================================================ }

{ Initialise le systeme de signatures }
Procedure Sig_Init;
Var
 I, J: Integer;
Begin
 SignatureCount := 0;
 AccountSigSettingsCount := 0;
 SignatureWindowState := sigwsHidden;
 SignatureWindowX := (GGetMaxX - SIG_WINDOW_WIDTH) Div 2;
 SignatureWindowY := (GGetMaxY - SIG_WINDOW_HEIGHT) Div 2;
 SignatureVisible := False;
 SignatureScrollOffset := 0;
 SignatureSelectedIndex := 0;
 SignaturePreviewMode := False;
 CurrentSignatureID := -1;
 NextSignatureID := 1;

 { Initialiser le tableau des signatures }
 For I := 0 To MAX_SIGNATURES - 1 Do Begin
  Signatures^[I].ID := 0;
  Signatures^[I].Name := '';
  Signatures^[I].Description := '';
  Signatures^[I].IsDefault := False;
  Signatures^[I].AccountID := 0;
  Signatures^[I].ContentType := sctPlainText;
  Signatures^[I].PlainTextLines := 0;
  Signatures^[I].HTMLContentLines := 0;
  Signatures^[I].InsertMode := simAll;
  Signatures^[I].Position := spAfterText;
  Signatures^[I].IncludeSeparator := True;
  Signatures^[I].UseForReplies := True;
  Signatures^[I].UseForForwards := True;
  Signatures^[I].ReplySignatureID := -1;
  Signatures^[I].ForwardSignatureID := -1;
  Signatures^[I].CreatedDate := 0;
  Signatures^[I].ModifiedDate := 0;
  Signatures^[I].IsActive := False;
  For J := 0 To SIG_MAX_TEXT_LINES - 1 Do
   Signatures^[I].PlainText[J] := '';
  For J := 0 To SIG_MAX_HTML_LINES - 1 Do
   Signatures^[I].HTMLContent[J] := '';
 End;

 { Initialiser les parametres par compte }
 For I := 0 To MAX_ACCOUNT_SIG_SETTINGS - 1 Do Begin
  AccountSigSettings[I].AccountID := 0;
  AccountSigSettings[I].DefaultSignatureID := -1;
  AccountSigSettings[I].ReplySignatureID := -1;
  AccountSigSettings[I].ForwardSignatureID := -1;
  AccountSigSettings[I].AutoInsert := True;
  AccountSigSettings[I].InsertPosition := spAfterText;
 End;

 { Initialiser l'etat de l'editeur }
 SignatureEditorState.CursorLine := 0;
 SignatureEditorState.CursorCol := 0;
 SignatureEditorState.SelectionStart := -1;
 SignatureEditorState.SelectionEnd := -1;
 SignatureEditorState.IsModified := False;
 SignatureEditorState.CurrentTab := 0;
 SignatureEditorState.ScrollOffset := 0;
End;

{ Cree une nouvelle signature vide }
Function Sig_Create(AName: String): Integer;
Var
 NewIndex: Integer;
Begin
 Sig_Create := -1;
 If SignatureCount >= MAX_SIGNATURES Then Exit;

 NewIndex := SignatureCount;
 Inc(SignatureCount);

 Signatures^[NewIndex].ID := NextSignatureID;
 Inc(NextSignatureID);
 Signatures^[NewIndex].Name := AName;
 Signatures^[NewIndex].Description := '';
 Signatures^[NewIndex].IsDefault := (SignatureCount = 1);
 Signatures^[NewIndex].AccountID := 0;
 Signatures^[NewIndex].ContentType := sctPlainText;
 Signatures^[NewIndex].PlainTextLines := 0;
 Signatures^[NewIndex].HTMLContentLines := 0;
 Signatures^[NewIndex].InsertMode := simAll;
 Signatures^[NewIndex].Position := spAfterText;
 Signatures^[NewIndex].IncludeSeparator := True;
 Signatures^[NewIndex].UseForReplies := True;
 Signatures^[NewIndex].UseForForwards := True;
 Signatures^[NewIndex].ReplySignatureID := -1;
 Signatures^[NewIndex].ForwardSignatureID := -1;
 Signatures^[NewIndex].CreatedDate := 1743465600;
 Signatures^[NewIndex].ModifiedDate := 1743465600;
 Signatures^[NewIndex].IsActive := True;

 Sig_Create := Signatures^[NewIndex].ID;
End;

{ Supprime une signature par son ID }
Function Sig_Delete(SigID: Integer): Boolean;
Var
 I, J, Index: Integer;
Begin
 Sig_Delete := False;
 Index := -1;

 { Trouver l'index de la signature }
 For I := 0 To SignatureCount - 1 Do Begin
  If Signatures^[I].ID = SigID Then Begin
   Index := I;
   Break;
  End;
 End;

 If Index < 0 Then Exit;

 { Decaler les signatures suivantes }
 For I := Index To SignatureCount - 2 Do
  Signatures^[I] := Signatures^[I + 1];

 Dec(SignatureCount);
 Sig_Delete := True;

 { Si c'etait la signature par defaut, definir la premiere comme defaut }
 If SignatureCount > 0 Then Begin
  For I := 0 To SignatureCount - 1 Do Begin
   If Signatures^[I].IsDefault Then Exit;
  End;
  Signatures^[0].IsDefault := True;
 End;
End;

{ Trouve une signature par son ID }
Function Sig_FindByID(SigID: Integer): Integer;
Var
 I: Integer;
Begin
 Sig_FindByID := -1;
 For I := 0 To SignatureCount - 1 Do Begin
  If Signatures^[I].ID = SigID Then Begin
   Sig_FindByID := I;
   Exit;
  End;
 End;
End;

{ Retourne la signature par defaut pour un compte }
Function Sig_GetDefaultForAccount(AccountID: Integer): Integer;
Var
 I: Integer;
Begin
 Sig_GetDefaultForAccount := -1;

 { Chercher dans les parametres par compte }
 For I := 0 To AccountSigSettingsCount - 1 Do Begin
  If AccountSigSettings[I].AccountID = AccountID Then Begin
   Sig_GetDefaultForAccount := AccountSigSettings[I].DefaultSignatureID;
   Exit;
  End;
 End;

 { Sinon chercher la signature par defaut globale }
 For I := 0 To SignatureCount - 1 Do Begin
  If Signatures^[I].IsDefault And Signatures^[I].IsActive Then Begin
   Sig_GetDefaultForAccount := Signatures^[I].ID;
   Exit;
  End;
 End;

 { Sinon retourner la premiere signature active }
 For I := 0 To SignatureCount - 1 Do Begin
  If Signatures^[I].IsActive Then Begin
   Sig_GetDefaultForAccount := Signatures^[I].ID;
   Exit;
  End;
 End;
End;

{ Retourne la signature pour les reponses }
Function Sig_GetReplySignature(AccountID: Integer): Integer;
Var
 I: Integer;
 DefaultID: Integer;
Begin
 Sig_GetReplySignature := -1;

 { Chercher dans les parametres par compte }
 For I := 0 To AccountSigSettingsCount - 1 Do Begin
  If AccountSigSettings[I].AccountID = AccountID Then Begin
   If AccountSigSettings[I].ReplySignatureID >= 0 Then Begin
    Sig_GetReplySignature := AccountSigSettings[I].ReplySignatureID;
    Exit;
   End;
  End;
 End;

 { Sinon utiliser la signature par defaut }
 DefaultID := Sig_GetDefaultForAccount(AccountID);
 If DefaultID >= 0 Then Begin
  I := Sig_FindByID(DefaultID);
  If I >= 0 Then Begin
   If Signatures^[I].UseForReplies Then Begin
    If Signatures^[I].ReplySignatureID >= 0 Then
     Sig_GetReplySignature := Signatures^[I].ReplySignatureID
    Else
     Sig_GetReplySignature := DefaultID;
   End;
  End;
 End;
End;

{ Retourne la signature pour les transferts }
Function Sig_GetForwardSignature(AccountID: Integer): Integer;
Var
 I: Integer;
 DefaultID: Integer;
Begin
 Sig_GetForwardSignature := -1;

 { Chercher dans les parametres par compte }
 For I := 0 To AccountSigSettingsCount - 1 Do Begin
  If AccountSigSettings[I].AccountID = AccountID Then Begin
   If AccountSigSettings[I].ForwardSignatureID >= 0 Then Begin
    Sig_GetForwardSignature := AccountSigSettings[I].ForwardSignatureID;
    Exit;
   End;
  End;
 End;

 { Sinon utiliser la signature par defaut }
 DefaultID := Sig_GetDefaultForAccount(AccountID);
 If DefaultID >= 0 Then Begin
  I := Sig_FindByID(DefaultID);
  If I >= 0 Then Begin
   If Signatures^[I].UseForForwards Then Begin
    If Signatures^[I].ForwardSignatureID >= 0 Then
     Sig_GetForwardSignature := Signatures^[I].ForwardSignatureID
    Else
     Sig_GetForwardSignature := DefaultID;
   End;
  End;
 End;
End;

{ Definit la signature par defaut }
Procedure Sig_SetDefault(SigID: Integer);
Var
 I, Index: Integer;
Begin
 { Retirer le statut par defaut de toutes les signatures }
 For I := 0 To SignatureCount - 1 Do
  Signatures^[I].IsDefault := False;

 { Definir la nouvelle signature par defaut }
 Index := Sig_FindByID(SigID);
 If Index >= 0 Then
  Signatures^[Index].IsDefault := True;
End;

{ Ajoute une ligne de texte a une signature }
Function Sig_AddTextLine(SigIndex: Integer; Line: String): Boolean;
Begin
 Sig_AddTextLine := False;
 If (SigIndex < 0) Or (SigIndex >= SignatureCount) Then Exit;
 If Signatures^[SigIndex].PlainTextLines >= SIG_MAX_TEXT_LINES Then Exit;

 Signatures^[SigIndex].PlainText[Signatures^[SigIndex].PlainTextLines] := Line;
 Inc(Signatures^[SigIndex].PlainTextLines);
 Signatures^[SigIndex].ModifiedDate := 1743465600;
 Sig_AddTextLine := True;
End;

{ Ajoute une ligne HTML a une signature }
Function Sig_AddHTMLLine(SigIndex: Integer; Line: String): Boolean;
Begin
 Sig_AddHTMLLine := False;
 If (SigIndex < 0) Or (SigIndex >= SignatureCount) Then Exit;
 If Signatures^[SigIndex].HTMLContentLines >= SIG_MAX_HTML_LINES Then Exit;

 Signatures^[SigIndex].HTMLContent[Signatures^[SigIndex].HTMLContentLines] := Line;
 Inc(Signatures^[SigIndex].HTMLContentLines);
 Signatures^[SigIndex].ContentType := sctHTML;
 Signatures^[SigIndex].ModifiedDate := 1743465600;
 Sig_AddHTMLLine := True;
End;

{ Vide le texte d'une signature }
Procedure Sig_ClearText(SigIndex: Integer);
Var
 I: Integer;
Begin
 If (SigIndex < 0) Or (SigIndex >= SignatureCount) Then Exit;

 For I := 0 To SIG_MAX_TEXT_LINES - 1 Do
  Signatures^[SigIndex].PlainText[I] := '';
 Signatures^[SigIndex].PlainTextLines := 0;
 Signatures^[SigIndex].ModifiedDate := 1743465600;
End;

{ Vide le contenu HTML d'une signature }
Procedure Sig_ClearHTML(SigIndex: Integer);
Var
 I: Integer;
Begin
 If (SigIndex < 0) Or (SigIndex >= SignatureCount) Then Exit;

 For I := 0 To SIG_MAX_HTML_LINES - 1 Do
  Signatures^[SigIndex].HTMLContent[I] := '';
 Signatures^[SigIndex].HTMLContentLines := 0;
 Signatures^[SigIndex].ModifiedDate := 1743465600;
End;

{ Genere le texte de la signature avec separateur optionnel }
Function Sig_GenerateText(SigIndex: Integer): String;
Var
 I: Integer;
 Result: String;
Begin
 Sig_GenerateText := '';
 If (SigIndex < 0) Or (SigIndex >= SignatureCount) Then Exit;

 Result := '';

 { Ajouter le separateur si configure }
 If Signatures^[SigIndex].IncludeSeparator Then
  Result := SIG_SEPARATOR + #13#10;

 { Ajouter les lignes de texte }
 For I := 0 To Signatures^[SigIndex].PlainTextLines - 1 Do Begin
  Result := Result + Signatures^[SigIndex].PlainText[I];
  If I < Signatures^[SigIndex].PlainTextLines - 1 Then
   Result := Result + #13#10;
 End;

 Sig_GenerateText := Result;
End;

{ Genere le contenu HTML de la signature }
Function Sig_GenerateHTML(SigIndex: Integer): String;
Var
 I: Integer;
 Result: String;
Begin
 Sig_GenerateHTML := '';
 If (SigIndex < 0) Or (SigIndex >= SignatureCount) Then Exit;
 If Signatures^[SigIndex].ContentType <> sctHTML Then Exit;

 Result := '';

 { Ajouter le separateur si configure }
 If Signatures^[SigIndex].IncludeSeparator Then
  Result := '<p>' + SIG_SEPARATOR + '</p>';

 { Ajouter les lignes HTML }
 For I := 0 To Signatures^[SigIndex].HTMLContentLines - 1 Do
  Result := Result + Signatures^[SigIndex].HTMLContent[I];

 Sig_GenerateHTML := Result;
End;

{ Configure les parametres de signature pour un compte }
Procedure Sig_SetAccountSettings(AccountID, DefaultSig, ReplySig, ForwardSig: Integer;
                                 AutoInsert: Boolean; InsertPos: TSignaturePosition);
Var
 I, Index: Integer;
Begin
 { Chercher si les parametres existent deja }
 Index := -1;
 For I := 0 To AccountSigSettingsCount - 1 Do Begin
  If AccountSigSettings[I].AccountID = AccountID Then Begin
   Index := I;
   Break;
  End;
 End;

 { Creer une nouvelle entree si necessaire }
 If Index < 0 Then Begin
  If AccountSigSettingsCount >= MAX_ACCOUNT_SIG_SETTINGS Then Exit;
  Index := AccountSigSettingsCount;
  Inc(AccountSigSettingsCount);
 End;

 { Configurer les parametres }
 AccountSigSettings[Index].AccountID := AccountID;
 AccountSigSettings[Index].DefaultSignatureID := DefaultSig;
 AccountSigSettings[Index].ReplySignatureID := ReplySig;
 AccountSigSettings[Index].ForwardSignatureID := ForwardSig;
 AccountSigSettings[Index].AutoInsert := AutoInsert;
 AccountSigSettings[Index].InsertPosition := InsertPos;
End;

{ Insere la signature dans le corps du message du compositeur }
Procedure Sig_InsertInComposer(SigID: Integer; IsReply, IsForward: Boolean);
Var
 SigIndex, LineIndex: Integer;
 SigText: String;
Begin
 { Trouver la signature appropriee }
 If IsReply Then
  SigID := Sig_GetReplySignature(0)
 Else If IsForward Then
  SigID := Sig_GetForwardSignature(0);

 If SigID < 0 Then SigID := Sig_GetDefaultForAccount(0);
 If SigID < 0 Then Exit;

 SigIndex := Sig_FindByID(SigID);
 If SigIndex < 0 Then Exit;
 If Not Signatures^[SigIndex].IsActive Then Exit;

 { Ajouter une ligne vide avant la signature }
 If Composer.LineCount < 498 Then Begin
  Composer.Lines[Composer.LineCount].Text := '';
  Inc(Composer.LineCount);
 End;

 { Ajouter le separateur si configure }
 If Signatures^[SigIndex].IncludeSeparator And (Composer.LineCount < 499) Then Begin
  Composer.Lines[Composer.LineCount].Text := SIG_SEPARATOR;
  Inc(Composer.LineCount);
 End;

 { Ajouter les lignes de la signature }
 For LineIndex := 0 To Signatures^[SigIndex].PlainTextLines - 1 Do Begin
  If Composer.LineCount >= 500 Then Break;
  Composer.Lines[Composer.LineCount].Text := Signatures^[SigIndex].PlainText[LineIndex];
  Inc(Composer.LineCount);
 End;
End;

{ Affiche la fenetre de gestion des signatures }
Procedure Sig_DrawWindow;
Var
 X1, Y1, X2, Y2: Integer;
 I, Y, ItemY: Integer;
 DisplayStr: String;
 IsSelected: Boolean;
 BtnX, BtnY, BtnW, BtnH: Integer;
Begin
 If Not SignatureVisible Then Exit;

 X1 := SignatureWindowX;
 Y1 := SignatureWindowY;
 X2 := X1 + SIG_WINDOW_WIDTH;
 Y2 := Y1 + SIG_WINDOW_HEIGHT;

 { Fond de la fenetre }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X1, Y1, X2, Y2);

 { Barre de titre }
 GSetFillStyle(SolidFill, Blue);
 GBar(X1, Y1, X2, Y1 + 25);
 GSetColor(White);
 GOutTextXY(X1 + 10, Y1 + 7, 'Gestion des signatures');

 { Bouton fermer }
 GSetFillStyle(SolidFill, Red);
 GBar(X2 - 25, Y1 + 3, X2 - 3, Y1 + 22);
 GSetColor(White);
 GOutTextXY(X2 - 18, Y1 + 7, 'X');

 { Bordure de la fenetre }
 GSetColor(DarkGray);
 GRectangle(X1, Y1, X2, Y2);
 GSetColor(White);
 GLine(X1 + 1, Y1 + 26, X2 - 1, Y1 + 26);

 Y := Y1 + 35;

 Case SignatureWindowState Of
  sigwsHidden: Exit;

  sigwsList: Begin
   { Titre de la liste }
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Signatures disponibles:');
   Y := Y + 25;

   { Liste des signatures }
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 20, Y + SIG_LIST_VISIBLE * SIG_LIST_ITEM_HEIGHT);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 20, Y + SIG_LIST_VISIBLE * SIG_LIST_ITEM_HEIGHT);

   For I := 0 To SIG_LIST_VISIBLE - 1 Do Begin
    If I + SignatureScrollOffset >= SignatureCount Then Break;

    ItemY := Y + I * SIG_LIST_ITEM_HEIGHT;
    IsSelected := (I + SignatureScrollOffset = SignatureSelectedIndex);

    If IsSelected Then Begin
     GSetFillStyle(SolidFill, Blue);
     GBar(X1 + 21, ItemY + 1, X2 - 21, ItemY + SIG_LIST_ITEM_HEIGHT - 1);
     GSetColor(White);
    End Else Begin
     GSetColor(Black);
    End;

    { Nom de la signature }
    DisplayStr := Signatures^[I + SignatureScrollOffset].Name;
    If Signatures^[I + SignatureScrollOffset].IsDefault Then
     DisplayStr := DisplayStr + ' (Par defaut)';
    If Not Signatures^[I + SignatureScrollOffset].IsActive Then
     DisplayStr := DisplayStr + ' [Inactive]';
    GOutTextXY(X1 + 25, ItemY + 5, DisplayStr);
   End;

   { Boutons }
   BtnY := Y + SIG_LIST_VISIBLE * SIG_LIST_ITEM_HEIGHT + 20;
   BtnW := 100;
   BtnH := 25;

   { Bouton Nouvelle }
   BtnX := X1 + 20;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(Black);
   GOutTextXY(BtnX + 20, BtnY + 7, 'Nouvelle');

   { Bouton Modifier }
   BtnX := X1 + 130;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(Black);
   GOutTextXY(BtnX + 22, BtnY + 7, 'Modifier');

   { Bouton Supprimer }
   BtnX := X1 + 240;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(Black);
   GOutTextXY(BtnX + 15, BtnY + 7, 'Supprimer');

   { Bouton Par defaut }
   BtnX := X1 + 350;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(Black);
   GOutTextXY(BtnX + 10, BtnY + 7, 'Par defaut');

   { Apercu de la signature selectionnee }
   BtnY := BtnY + BtnH + 20;
   GSetColor(Black);
   GOutTextXY(X1 + 20, BtnY, 'Apercu:');
   BtnY := BtnY + 20;

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, BtnY, X2 - 20, BtnY + 80);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, BtnY, X2 - 20, BtnY + 80);

   If (SignatureSelectedIndex >= 0) And (SignatureSelectedIndex < SignatureCount) Then Begin
    GSetColor(Black);
    For I := 0 To Signatures^[SignatureSelectedIndex].PlainTextLines - 1 Do Begin
     If I > 4 Then Break;
     GOutTextXY(X1 + 25, BtnY + 5 + I * 14, Signatures^[SignatureSelectedIndex].PlainText[I]);
    End;
   End;
  End;

  sigwsEdit, sigwsNew: Begin
   { Titre }
   GSetColor(Black);
   If SignatureWindowState = sigwsNew Then
    GOutTextXY(X1 + 20, Y, 'Nouvelle signature:')
   Else
    GOutTextXY(X1 + 20, Y, 'Modifier la signature:');
   Y := Y + 25;

   { Champ Nom }
   GOutTextXY(X1 + 20, Y, 'Nom:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 80, Y - 3, X1 + 300, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 80, Y - 3, X1 + 300, Y + 15);
   GSetColor(Black);
   GOutTextXY(X1 + 85, Y, SignatureEditorState.EditingSignature.Name);
   Y := Y + 25;

   { Description }
   GOutTextXY(X1 + 20, Y, 'Description:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 100, Y - 3, X2 - 20, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 100, Y - 3, X2 - 20, Y + 15);
   GSetColor(Black);
   GOutTextXY(X1 + 105, Y, SignatureEditorState.EditingSignature.Description);
   Y := Y + 30;

   { Zone d'edition du texte }
   GOutTextXY(X1 + 20, Y, 'Contenu de la signature:');
   Y := Y + 18;

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 20, Y + 120);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 20, Y + 120);

   GSetColor(Black);
   For I := 0 To 7 Do Begin
    If I + SignatureEditorState.ScrollOffset >= SIG_MAX_TEXT_LINES Then Break;
    If I + SignatureEditorState.ScrollOffset < SignatureEditorState.EditingSignature.PlainTextLines Then
     GOutTextXY(X1 + 25, Y + 5 + I * 14,
               SignatureEditorState.EditingSignature.PlainText[I + SignatureEditorState.ScrollOffset]);
   End;

   Y := Y + 130;

   { Options }
   If SignatureEditorState.EditingSignature.IncludeSeparator Then
    DisplayStr := '[X]'
   Else
    DisplayStr := '[ ]';
   GOutTextXY(X1 + 20, Y, DisplayStr + ' Inclure le separateur "-- "');
   Y := Y + 18;

   If SignatureEditorState.EditingSignature.UseForReplies Then
    DisplayStr := '[X]'
   Else
    DisplayStr := '[ ]';
   GOutTextXY(X1 + 20, Y, DisplayStr + ' Utiliser pour les reponses');

   If SignatureEditorState.EditingSignature.UseForForwards Then
    DisplayStr := '[X]'
   Else
    DisplayStr := '[ ]';
   GOutTextXY(X1 + 250, Y, DisplayStr + ' Utiliser pour les transferts');
   Y := Y + 25;

   { Boutons OK et Annuler }
   BtnW := 80;
   BtnH := 25;
   BtnY := Y2 - 40;

   { Bouton OK }
   BtnX := X2 - 180;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(Black);
   GOutTextXY(BtnX + 30, BtnY + 7, 'OK');

   { Bouton Annuler }
   BtnX := X2 - 90;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(Black);
   GOutTextXY(BtnX + 15, BtnY + 7, 'Annuler');
  End;

  sigwsPreview: Begin
   { Apercu plein ecran de la signature }
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Apercu de la signature:');
   Y := Y + 25;

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 20, Y2 - 60);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 20, Y2 - 60);

   If (SignatureSelectedIndex >= 0) And (SignatureSelectedIndex < SignatureCount) Then Begin
    GSetColor(DarkGray);
    GOutTextXY(X1 + 25, Y + 5, SIG_SEPARATOR);
    GSetColor(Black);
    For I := 0 To Signatures^[SignatureSelectedIndex].PlainTextLines - 1 Do Begin
     GOutTextXY(X1 + 25, Y + 20 + I * 14, Signatures^[SignatureSelectedIndex].PlainText[I]);
    End;
   End;

   { Bouton Fermer }
   BtnW := 80;
   BtnH := 25;
   BtnX := X2 - 100;
   BtnY := Y2 - 40;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(Black);
   GOutTextXY(BtnX + 18, BtnY + 7, 'Fermer');
  End;
 End;
End;

{ Gere les clics dans la fenetre de signatures }
Procedure Sig_HandleClick(MX, MY: Integer);
Var
 X1, Y1, X2, Y2: Integer;
 ListY, ItemY, I: Integer;
 BtnX, BtnY, BtnW, BtnH: Integer;
 ClickedIndex: Integer;
Begin
 If Not SignatureVisible Then Exit;

 X1 := SignatureWindowX;
 Y1 := SignatureWindowY;
 X2 := X1 + SIG_WINDOW_WIDTH;
 Y2 := Y1 + SIG_WINDOW_HEIGHT;

 { Verifier si clic hors de la fenetre }
 If (MX < X1) Or (MX > X2) Or (MY < Y1) Or (MY > Y2) Then Begin
  SignatureVisible := False;
  SignatureWindowState := sigwsHidden;
  Exit;
 End;

 { Bouton fermer }
 If (MX >= X2 - 25) And (MX <= X2 - 3) And (MY >= Y1 + 3) And (MY <= Y1 + 22) Then Begin
  SignatureVisible := False;
  SignatureWindowState := sigwsHidden;
  Exit;
 End;

 Case SignatureWindowState Of
  sigwsList: Begin
   ListY := Y1 + 60;

   { Clic dans la liste }
   If (MX >= X1 + 20) And (MX <= X2 - 20) And
      (MY >= ListY) And (MY <= ListY + SIG_LIST_VISIBLE * SIG_LIST_ITEM_HEIGHT) Then Begin
    ClickedIndex := (MY - ListY) Div SIG_LIST_ITEM_HEIGHT + SignatureScrollOffset;
    If ClickedIndex < SignatureCount Then
     SignatureSelectedIndex := ClickedIndex;
    Exit;
   End;

   { Boutons }
   BtnY := ListY + SIG_LIST_VISIBLE * SIG_LIST_ITEM_HEIGHT + 20;
   BtnW := 100;
   BtnH := 25;

   { Bouton Nouvelle }
   BtnX := X1 + 20;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    SignatureWindowState := sigwsNew;
    SignatureEditorState.EditingSignature.ID := 0;
    SignatureEditorState.EditingSignature.Name := 'Nouvelle signature';
    SignatureEditorState.EditingSignature.Description := '';
    SignatureEditorState.EditingSignature.PlainTextLines := 0;
    SignatureEditorState.EditingSignature.IncludeSeparator := True;
    SignatureEditorState.EditingSignature.UseForReplies := True;
    SignatureEditorState.EditingSignature.UseForForwards := True;
    SignatureEditorState.IsModified := False;
    SignatureEditorState.ScrollOffset := 0;
    Exit;
   End;

   { Bouton Modifier }
   BtnX := X1 + 130;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    If (SignatureSelectedIndex >= 0) And (SignatureSelectedIndex < SignatureCount) Then Begin
     SignatureWindowState := sigwsEdit;
     SignatureEditorState.EditingSignature := Signatures^[SignatureSelectedIndex];
     SignatureEditorState.IsModified := False;
     SignatureEditorState.ScrollOffset := 0;
    End;
    Exit;
   End;

   { Bouton Supprimer }
   BtnX := X1 + 240;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    If (SignatureSelectedIndex >= 0) And (SignatureSelectedIndex < SignatureCount) Then Begin
     Sig_Delete(Signatures^[SignatureSelectedIndex].ID);
     If SignatureSelectedIndex >= SignatureCount Then
      SignatureSelectedIndex := SignatureCount - 1;
     If SignatureSelectedIndex < 0 Then
      SignatureSelectedIndex := 0;
    End;
    Exit;
   End;

   { Bouton Par defaut }
   BtnX := X1 + 350;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    If (SignatureSelectedIndex >= 0) And (SignatureSelectedIndex < SignatureCount) Then
     Sig_SetDefault(Signatures^[SignatureSelectedIndex].ID);
    Exit;
   End;
  End;

  sigwsEdit, sigwsNew: Begin
   BtnW := 80;
   BtnH := 25;
   BtnY := Y2 - 40;

   { Options checkboxes }
   If (MY >= Y1 + 295) And (MY <= Y1 + 310) Then Begin
    If (MX >= X1 + 20) And (MX <= X1 + 240) Then Begin
     SignatureEditorState.EditingSignature.IncludeSeparator :=
       Not SignatureEditorState.EditingSignature.IncludeSeparator;
     Exit;
    End;
   End;

   If (MY >= Y1 + 313) And (MY <= Y1 + 328) Then Begin
    If (MX >= X1 + 20) And (MX <= X1 + 230) Then Begin
     SignatureEditorState.EditingSignature.UseForReplies :=
       Not SignatureEditorState.EditingSignature.UseForReplies;
     Exit;
    End;
    If (MX >= X1 + 250) And (MX <= X1 + 480) Then Begin
     SignatureEditorState.EditingSignature.UseForForwards :=
       Not SignatureEditorState.EditingSignature.UseForForwards;
     Exit;
    End;
   End;

   { Bouton OK }
   BtnX := X2 - 180;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    If SignatureWindowState = sigwsNew Then Begin
     { Creer la nouvelle signature }
     I := SignatureCount;
     If I < MAX_SIGNATURES Then Begin
      Signatures^[I] := SignatureEditorState.EditingSignature;
      Signatures^[I].ID := NextSignatureID;
      Inc(NextSignatureID);
      Signatures^[I].IsActive := True;
      Signatures^[I].CreatedDate := 1743465600;
      Signatures^[I].ModifiedDate := 1743465600;
      Inc(SignatureCount);
      SignatureSelectedIndex := I;
     End;
    End Else Begin
     { Mettre a jour la signature existante }
     Signatures^[SignatureSelectedIndex] := SignatureEditorState.EditingSignature;
     Signatures^[SignatureSelectedIndex].ModifiedDate := 1743465600;
    End;
    SignatureWindowState := sigwsList;
    Exit;
   End;

   { Bouton Annuler }
   BtnX := X2 - 90;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    SignatureWindowState := sigwsList;
    Exit;
   End;
  End;

  sigwsPreview: Begin
   { Bouton Fermer }
   BtnW := 80;
   BtnH := 25;
   BtnX := X2 - 100;
   BtnY := Y2 - 40;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    SignatureWindowState := sigwsList;
    Exit;
   End;
  End;
 End;
End;

{ Gere les touches clavier dans la fenetre de signatures }
Procedure Sig_HandleKey(Key: Char);
Var
 I: Integer;
Begin
 If Not SignatureVisible Then Exit;

 Case SignatureWindowState Of
  sigwsList: Begin
   Case Key Of
    #27: Begin { Echap }
     SignatureVisible := False;
     SignatureWindowState := sigwsHidden;
    End;
    #72: Begin { Fleche haut }
     If SignatureSelectedIndex > 0 Then
      Dec(SignatureSelectedIndex);
     If SignatureSelectedIndex < SignatureScrollOffset Then
      SignatureScrollOffset := SignatureSelectedIndex;
    End;
    #80: Begin { Fleche bas }
     If SignatureSelectedIndex < SignatureCount - 1 Then
      Inc(SignatureSelectedIndex);
     If SignatureSelectedIndex >= SignatureScrollOffset + SIG_LIST_VISIBLE Then
      SignatureScrollOffset := SignatureSelectedIndex - SIG_LIST_VISIBLE + 1;
    End;
    #13: Begin { Entree - modifier }
     If (SignatureSelectedIndex >= 0) And (SignatureSelectedIndex < SignatureCount) Then Begin
      SignatureWindowState := sigwsEdit;
      SignatureEditorState.EditingSignature := Signatures^[SignatureSelectedIndex];
      SignatureEditorState.IsModified := False;
      SignatureEditorState.ScrollOffset := 0;
     End;
    End;
    'n', 'N': Begin { Nouvelle signature }
     SignatureWindowState := sigwsNew;
     SignatureEditorState.EditingSignature.ID := 0;
     SignatureEditorState.EditingSignature.Name := 'Nouvelle signature';
     SignatureEditorState.EditingSignature.Description := '';
     SignatureEditorState.EditingSignature.PlainTextLines := 0;
     SignatureEditorState.EditingSignature.IncludeSeparator := True;
     SignatureEditorState.EditingSignature.UseForReplies := True;
     SignatureEditorState.EditingSignature.UseForForwards := True;
     SignatureEditorState.IsModified := False;
    End;
    'd', 'D': Begin { Par defaut }
     If (SignatureSelectedIndex >= 0) And (SignatureSelectedIndex < SignatureCount) Then
      Sig_SetDefault(Signatures^[SignatureSelectedIndex].ID);
    End;
   End;
  End;

  sigwsEdit, sigwsNew: Begin
   Case Key Of
    #27: Begin { Echap - annuler }
     SignatureWindowState := sigwsList;
    End;
    #8: Begin { Backspace }
     If Length(SignatureEditorState.EditingSignature.Name) > 0 Then Begin
      Delete(SignatureEditorState.EditingSignature.Name,
             Length(SignatureEditorState.EditingSignature.Name), 1);
      SignatureEditorState.IsModified := True;
     End;
    End;
    #13: Begin { Entree - sauvegarder }
     If SignatureWindowState = sigwsNew Then Begin
      I := SignatureCount;
      If I < MAX_SIGNATURES Then Begin
       Signatures^[I] := SignatureEditorState.EditingSignature;
       Signatures^[I].ID := NextSignatureID;
       Inc(NextSignatureID);
       Signatures^[I].IsActive := True;
       Inc(SignatureCount);
       SignatureSelectedIndex := I;
      End;
     End Else Begin
      Signatures^[SignatureSelectedIndex] := SignatureEditorState.EditingSignature;
     End;
     SignatureWindowState := sigwsList;
    End;
    Else Begin
     If (((Key >= ' ') And (Key <= '~')) Or (Key >= #128)) Then Begin
      If Length(SignatureEditorState.EditingSignature.Name) < 38 Then Begin
       SignatureEditorState.EditingSignature.Name :=
         SignatureEditorState.EditingSignature.Name + Key;
       SignatureEditorState.IsModified := True;
      End;
     End;
    End;
   End;
  End;

  sigwsPreview: Begin
   If Key = #27 Then
    SignatureWindowState := sigwsList;
  End;
 End;
End;

{ Affiche la fenetre de gestion des signatures }
Procedure Sig_ShowWindow;
Begin
 SignatureVisible := True;
 SignatureWindowState := sigwsList;
 SignatureScrollOffset := 0;
 If SignatureSelectedIndex >= SignatureCount Then
  SignatureSelectedIndex := 0;
End;

{ Masque la fenetre de gestion des signatures }
Procedure Sig_HideWindow;
Begin
 SignatureVisible := False;
 SignatureWindowState := sigwsHidden;
End;

{ Ajoute des signatures de demonstration }
Procedure Sig_AddDemoSignatures;
Var
 SigID, SigIndex: Integer;
Begin
 { Signature professionnelle }
 SigID := Sig_Create('Professionnelle');
 SigIndex := Sig_FindByID(SigID);
 If SigIndex >= 0 Then Begin
  Sig_AddTextLine(SigIndex, 'Cordialement,');
  Sig_AddTextLine(SigIndex, '');
  Sig_AddTextLine(SigIndex, 'Jean Dupont');
  Sig_AddTextLine(SigIndex, 'Directeur technique');
  Sig_AddTextLine(SigIndex, 'Entreprise ABC');
  Sig_AddTextLine(SigIndex, 'Tel: +1 514 555-1234');
  Sig_AddTextLine(SigIndex, 'jean.dupont@entreprise-abc.com');
  Signatures^[SigIndex].IsDefault := True;
 End;

 { Signature personnelle }
 SigID := Sig_Create('Personnelle');
 SigIndex := Sig_FindByID(SigID);
 If SigIndex >= 0 Then Begin
  Sig_AddTextLine(SigIndex, 'A bientot!');
  Sig_AddTextLine(SigIndex, '');
  Sig_AddTextLine(SigIndex, 'Jean');
  Signatures^[SigIndex].UseForReplies := True;
  Signatures^[SigIndex].UseForForwards := False;
 End;

 { Signature courte pour reponses }
 SigID := Sig_Create('Reponse courte');
 SigIndex := Sig_FindByID(SigID);
 If SigIndex >= 0 Then Begin
  Sig_AddTextLine(SigIndex, 'Merci,');
  Sig_AddTextLine(SigIndex, 'Jean Dupont');
  Signatures^[SigIndex].IncludeSeparator := False;
  Signatures^[SigIndex].UseForReplies := True;
  Signatures^[SigIndex].UseForForwards := True;
 End;

 { Configurer la premiere signature comme celle pour les reponses }
 If SignatureCount >= 3 Then Begin
  Signatures^[0].ReplySignatureID := Signatures^[2].ID;
  Signatures^[0].ForwardSignatureID := Signatures^[2].ID;
 End;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DE LA GESTION DES SIGNATURES (TODO 19)
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DES NOTIFICATIONS ET ALERTES (TODO 20)
  ============================================================================ }

{ Initialise le systeme de notifications }
Procedure Notif_Init;
Var
 I: Integer;
Begin
 { Parametres globaux par defaut }
 NotificationSettings.Enabled := True;
 NotificationSettings.CheckInterval := NOTIF_DEFAULT_CHECK_INTERVAL;
 NotificationSettings.DefaultSoundAlert := satSystemBeep;
 NotificationSettings.DefaultVisualAlert := vntTitleBadge;
 NotificationSettings.DefaultSoundFile := '';
 NotificationSettings.ShowPopupDuration := NOTIF_POPUP_DEFAULT_DURATION;
 NotificationSettings.PopupPosition := 0;
 NotificationSettings.FlashCount := NOTIF_FLASH_DEFAULT_COUNT;
 NotificationSettings.FlashInterval := NOTIF_FLASH_DEFAULT_INTERVAL;
 NotificationSettings.CheckOnStartup := True;
 NotificationSettings.PlaySoundRepeat := False;
 NotificationSettings.MaxPopupMessages := 5;

 { Initialiser les parametres par dossier }
 FolderNotifSettingsCount := 0;
 For I := 0 To MAX_FOLDER_NOTIFICATION_SETTINGS - 1 Do Begin
  FolderNotifSettings[I].FolderID := 0;
  FolderNotifSettings[I].FolderName := '';
  FolderNotifSettings[I].EnableNotification := True;
  FolderNotifSettings[I].SoundAlert := satSystemBeep;
  FolderNotifSettings[I].VisualAlert := vntTitleBadge;
  FolderNotifSettings[I].SoundFile := '';
  FolderNotifSettings[I].PlaySoundOnce := True;
 End;

 { Initialiser les notifications en attente }
 PendingNotificationCount := 0;
 For I := 0 To MAX_PENDING_NOTIFICATIONS - 1 Do Begin
  PendingNotifications[I].AccountID := 0;
  PendingNotifications[I].AccountName := '';
  PendingNotifications[I].FolderID := 0;
  PendingNotifications[I].FolderName := '';
  PendingNotifications[I].MessageCount := 0;
  PendingNotifications[I].FirstSender := '';
  PendingNotifications[I].FirstSubject := '';
  PendingNotifications[I].Timestamp := 0;
  PendingNotifications[I].Displayed := False;
  PendingNotifications[I].Acknowledged := False;
 End;

 { Initialiser l'historique }
 NotificationHistoryCount := 0;
 For I := 0 To MAX_NOTIFICATION_HISTORY - 1 Do Begin
  NotificationHistory[I].Timestamp := 0;
  NotificationHistory[I].AccountName := '';
  NotificationHistory[I].FolderName := '';
  NotificationHistory[I].MessageCount := 0;
  NotificationHistory[I].Subject := '';
 End;

 { Etat initial }
 NotificationState := nsIdle;
 LastCheckTime := 0;
 NextCheckTime := 0;
 NotificationPopupState := npsHidden;
 NotificationPopupX := GGetMaxX - NOTIF_POPUP_WIDTH - 10;
 NotificationPopupY := GGetMaxY - NOTIF_POPUP_HEIGHT - 50;
 NotificationPopupStartTime := 0;
 NotificationConfigState := ncsHidden;
 NotificationConfigX := (GGetMaxX - NOTIF_CONFIG_WIDTH) Div 2;
 NotificationConfigY := (GGetMaxY - NOTIF_CONFIG_HEIGHT) Div 2;
 NotificationConfigVisible := False;
 TitleFlashing := False;
 TitleFlashCount := 0;
 TitleFlashLastTime := 0;
 TitleFlashState := False;
 UnreadMailCount := 0;
 NewMailSinceLastCheck := 0;
End;

{ Joue un son d'alerte }
Procedure Notif_PlaySound(SoundType: TSoundAlertType; SoundFile: String);
Begin
 Case SoundType Of
  satNone: Begin
   { Pas de son }
  End;
  satSystemBeep: Begin
   { Beep systeme }
   
    PmSound(NOTIF_BEEP_FREQUENCY);
    PmDelay(NOTIF_BEEP_DURATION);
    PmNoSound;
   
  End;
  satWAVFile: Begin
   { Fichier WAV - non supporte en mode console pure }
   { Utiliser le beep systeme comme fallback }
   PmSound(NOTIF_BEEP_FREQUENCY);
   PmDelay(NOTIF_BEEP_DURATION);
   PmNoSound;
  End;
  satMelody: Begin
   { Melodie integree }
   PmSound(800); PmDelay(100); PmNoSound; PmDelay(50);
   PmSound(1000); PmDelay(100); PmNoSound; PmDelay(50);
   PmSound(1200); PmDelay(150); PmNoSound;
  End;
 End;
End;

{ Demarre le clignotement de la barre de titre }
Procedure Notif_StartTitleFlash;
Begin
 If Not TitleFlashing Then Begin
  TitleFlashing := True;
  TitleFlashCount := 0;
  TitleFlashLastTime := 0;
  TitleFlashState := True;
 End;
End;

{ Arrete le clignotement de la barre de titre }
Procedure Notif_StopTitleFlash;
Begin
 TitleFlashing := False;
 TitleFlashCount := 0;
 TitleFlashState := False;
End;

{ Met a jour le clignotement de la barre de titre }
Procedure Notif_UpdateTitleFlash;
Var
 CurrentTime: LongInt;
Begin
 If Not TitleFlashing Then Exit;

 CurrentTime := 0; { Simplification - utiliser GetTickCount en pratique }

 If TitleFlashCount >= NotificationSettings.FlashCount * 2 Then Begin
  Notif_StopTitleFlash;
  Exit;
 End;

 { Alterner l'etat }
 TitleFlashState := Not TitleFlashState;
 Inc(TitleFlashCount);
 TitleFlashLastTime := CurrentTime;
End;

{ Ajoute une notification a l'historique }
Procedure Notif_AddToHistory(AccountName, FolderName, Subject: String; MsgCount: Integer);
Var
 I: Integer;
Begin
 { Decaler l'historique si plein }
 If NotificationHistoryCount >= MAX_NOTIFICATION_HISTORY Then Begin
  For I := 0 To MAX_NOTIFICATION_HISTORY - 2 Do
   NotificationHistory[I] := NotificationHistory[I + 1];
  NotificationHistoryCount := MAX_NOTIFICATION_HISTORY - 1;
 End;

 { Ajouter la nouvelle entree }
 NotificationHistory[NotificationHistoryCount].Timestamp := 1743465600;
 NotificationHistory[NotificationHistoryCount].AccountName := AccountName;
 NotificationHistory[NotificationHistoryCount].FolderName := FolderName;
 NotificationHistory[NotificationHistoryCount].MessageCount := MsgCount;
 NotificationHistory[NotificationHistoryCount].Subject := Subject;
 Inc(NotificationHistoryCount);
End;

{ Cree une nouvelle notification }
Function Notif_Create(AccountID: Integer; AccountName, FolderName: String;
                      FolderID, MsgCount: Integer; Sender, Subject: String): Integer;
Var
 Index: Integer;
Begin
 Notif_Create := -1;
 If PendingNotificationCount >= MAX_PENDING_NOTIFICATIONS Then Exit;

 Index := PendingNotificationCount;
 Inc(PendingNotificationCount);

 PendingNotifications[Index].AccountID := AccountID;
 PendingNotifications[Index].AccountName := AccountName;
 PendingNotifications[Index].FolderID := FolderID;
 PendingNotifications[Index].FolderName := FolderName;
 PendingNotifications[Index].MessageCount := MsgCount;
 PendingNotifications[Index].FirstSender := Sender;
 PendingNotifications[Index].FirstSubject := Subject;
 PendingNotifications[Index].Timestamp := 1743465600;
 PendingNotifications[Index].Displayed := False;
 PendingNotifications[Index].Acknowledged := False;

 { Ajouter a l'historique }
 Notif_AddToHistory(AccountName, FolderName, Subject, MsgCount);

 Notif_Create := Index;
End;

{ Acquitte une notification }
Procedure Notif_Acknowledge(Index: Integer);
Begin
 If (Index >= 0) And (Index < PendingNotificationCount) Then
  PendingNotifications[Index].Acknowledged := True;
End;

{ Acquitte toutes les notifications }
Procedure Notif_AcknowledgeAll;
Var
 I: Integer;
Begin
 For I := 0 To PendingNotificationCount - 1 Do
  PendingNotifications[I].Acknowledged := True;

 Notif_StopTitleFlash;
 NotificationPopupState := npsHidden;
End;

{ Supprime les notifications acquittees }
Procedure Notif_CleanupAcknowledged;
Var
 I, NewCount: Integer;
Begin
 NewCount := 0;
 For I := 0 To PendingNotificationCount - 1 Do Begin
  If Not PendingNotifications[I].Acknowledged Then Begin
   If NewCount <> I Then
    PendingNotifications[NewCount] := PendingNotifications[I];
   Inc(NewCount);
  End;
 End;
 PendingNotificationCount := NewCount;
End;

{ Retourne le nombre de notifications non acquittees }
Function Notif_GetUnacknowledgedCount: Integer;
Var
 I, Count: Integer;
Begin
 Count := 0;
 For I := 0 To PendingNotificationCount - 1 Do Begin
  If Not PendingNotifications[I].Acknowledged Then
   Inc(Count);
 End;
 Notif_GetUnacknowledgedCount := Count;
End;

{ Configure les notifications pour un dossier }
Procedure Notif_SetFolderSettings(FolderID: Integer; FolderName: String;
                                   Enable: Boolean; Sound: TSoundAlertType;
                                   Visual: TVisualNotificationType; SoundFile: String);
Var
 I, Index: Integer;
Begin
 { Chercher si le dossier existe deja }
 Index := -1;
 For I := 0 To FolderNotifSettingsCount - 1 Do Begin
  If FolderNotifSettings[I].FolderID = FolderID Then Begin
   Index := I;
   Break;
  End;
 End;

 { Creer une nouvelle entree si necessaire }
 If Index < 0 Then Begin
  If FolderNotifSettingsCount >= MAX_FOLDER_NOTIFICATION_SETTINGS Then Exit;
  Index := FolderNotifSettingsCount;
  Inc(FolderNotifSettingsCount);
 End;

 { Configurer les parametres }
 FolderNotifSettings[Index].FolderID := FolderID;
 FolderNotifSettings[Index].FolderName := FolderName;
 FolderNotifSettings[Index].EnableNotification := Enable;
 FolderNotifSettings[Index].SoundAlert := Sound;
 FolderNotifSettings[Index].VisualAlert := Visual;
 FolderNotifSettings[Index].SoundFile := SoundFile;
 FolderNotifSettings[Index].PlaySoundOnce := True;
End;

{ Retourne les parametres de notification pour un dossier }
Function Notif_GetFolderSettings(FolderID: Integer): Integer;
Var
 I: Integer;
Begin
 Notif_GetFolderSettings := -1;
 For I := 0 To FolderNotifSettingsCount - 1 Do Begin
  If FolderNotifSettings[I].FolderID = FolderID Then Begin
   Notif_GetFolderSettings := I;
   Exit;
  End;
 End;
End;

{ Verifie les nouveaux messages (simulation) }
Procedure Notif_CheckNewMail;
Begin
 If Not NotificationSettings.Enabled Then Exit;

 NotificationState := nsChecking;

 { Simulation: detecter de nouveaux messages }
 { En pratique, cela utiliserait IMAP IDLE ou une verification periodique }

 { Exemple de notification simulee }
 { NotifIndex := Notif_Create(1, 'Mon compte', 'Boite de reception', 1, 2,
                               'expediteur@example.com', 'Nouveau message important'); }

 NotificationState := nsIdle;
 LastCheckTime := 1743465600;
 NextCheckTime := LastCheckTime + NotificationSettings.CheckInterval;
End;

{ Declenche les alertes pour les nouvelles notifications }
Procedure Notif_TriggerAlerts;
Var
 I, FolderIndex: Integer;
 SoundType: TSoundAlertType;
 VisualType: TVisualNotificationType;
 SoundFile: String;
 SoundPlayed: Boolean;
Begin
 SoundPlayed := False;

 For I := 0 To PendingNotificationCount - 1 Do Begin
  If Not PendingNotifications[I].Displayed Then Begin
   { Marquer comme affichee }
   PendingNotifications[I].Displayed := True;

   { Determiner le type d'alerte }
   FolderIndex := Notif_GetFolderSettings(PendingNotifications[I].FolderID);
   If FolderIndex >= 0 Then Begin
    If Not FolderNotifSettings[FolderIndex].EnableNotification Then Continue;
    SoundType := FolderNotifSettings[FolderIndex].SoundAlert;
    VisualType := FolderNotifSettings[FolderIndex].VisualAlert;
    SoundFile := FolderNotifSettings[FolderIndex].SoundFile;
   End Else Begin
    SoundType := NotificationSettings.DefaultSoundAlert;
    VisualType := NotificationSettings.DefaultVisualAlert;
    SoundFile := NotificationSettings.DefaultSoundFile;
   End;

   { Jouer le son (une seule fois si plusieurs notifications) }
   If Not SoundPlayed Then Begin
    Notif_PlaySound(SoundType, SoundFile);
    SoundPlayed := True;
   End;

   { Declencher l'alerte visuelle }
   Case VisualType Of
    vntTitleFlash: Notif_StartTitleFlash;
    vntTitleBadge: Begin
     { Le badge sera affiche lors du dessin de la barre de titre }
    End;
    vntPopup: Begin
     NotificationPopupState := npsShowing;
     NotificationPopupStartTime := 0;
    End;
   End;
  End;
 End;
End;

{ Affiche le popup de notification }
Procedure Notif_DrawPopup;
Var
 X1, Y1, X2, Y2: Integer;
 I, Y, DisplayCount: Integer;
 DisplayStr: String;
Begin
 If NotificationPopupState = npsHidden Then Exit;

 X1 := NotificationPopupX;
 Y1 := NotificationPopupY;
 X2 := X1 + NOTIF_POPUP_WIDTH;
 Y2 := Y1 + NOTIF_POPUP_HEIGHT;

 { Fond du popup }
 GSetFillStyle(SolidFill, LightBlue);
 GBar(X1, Y1, X2, Y2);

 { Bordure }
 GSetColor(Blue);
 GRectangle(X1, Y1, X2, Y2);

 { Titre }
 GSetFillStyle(SolidFill, Blue);
 GBar(X1 + 1, Y1 + 1, X2 - 1, Y1 + 20);
 GSetColor(White);
 GOutTextXY(X1 + 10, Y1 + 5, 'Nouveau courrier');

 { Bouton fermer }
 GSetFillStyle(SolidFill, Red);
 GBar(X2 - 20, Y1 + 3, X2 - 3, Y1 + 17);
 GSetColor(White);
 GOutTextXY(X2 - 15, Y1 + 5, 'X');

 { Contenu }
 Y := Y1 + 28;
 DisplayCount := 0;

 For I := 0 To PendingNotificationCount - 1 Do Begin
  If Not PendingNotifications[I].Acknowledged Then Begin
   If DisplayCount >= NotificationSettings.MaxPopupMessages Then Begin
    GSetColor(DarkGray);
    GOutTextXY(X1 + 10, Y, '... et plus');
    Break;
   End;

   GSetColor(Black);
   DisplayStr := PendingNotifications[I].FirstSender;
   If Length(DisplayStr) > 30 Then
    DisplayStr := Copy(DisplayStr, 1, 27) + '...';
   GOutTextXY(X1 + 10, Y, DisplayStr);
   Y := Y + 14;

   GSetColor(DarkGray);
   DisplayStr := PendingNotifications[I].FirstSubject;
   If Length(DisplayStr) > 35 Then
    DisplayStr := Copy(DisplayStr, 1, 32) + '...';
   GOutTextXY(X1 + 15, Y, DisplayStr);
   Y := Y + 16;

   Inc(DisplayCount);
  End;
 End;
End;

{ Gere les clics dans le popup de notification }
Procedure Notif_HandlePopupClick(MX, MY: Integer);
Var
 X1, Y1, X2, Y2: Integer;
Begin
 If NotificationPopupState = npsHidden Then Exit;

 X1 := NotificationPopupX;
 Y1 := NotificationPopupY;
 X2 := X1 + NOTIF_POPUP_WIDTH;
 Y2 := Y1 + NOTIF_POPUP_HEIGHT;

 { Verifier si clic dans le popup }
 If (MX < X1) Or (MX > X2) Or (MY < Y1) Or (MY > Y2) Then Exit;

 { Bouton fermer }
 If (MX >= X2 - 20) And (MX <= X2 - 3) And (MY >= Y1 + 3) And (MY <= Y1 + 17) Then Begin
  Notif_AcknowledgeAll;
  Exit;
 End;

 { Clic dans le contenu - ouvrir la boite de reception }
 { Pour l'instant, simplement acquitter }
 Notif_AcknowledgeAll;
End;

{ Affiche la fenetre de configuration des notifications }
Procedure Notif_DrawConfigWindow;
Var
 X1, Y1, X2, Y2: Integer;
 Y, BtnX, BtnY, BtnW, BtnH: Integer;
 DisplayStr, CheckStr: String;
 I: Integer;
Begin
 If Not NotificationConfigVisible Then Exit;

 X1 := NotificationConfigX;
 Y1 := NotificationConfigY;
 X2 := X1 + NOTIF_CONFIG_WIDTH;
 Y2 := Y1 + NOTIF_CONFIG_HEIGHT;

 { Fond de la fenetre }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X1, Y1, X2, Y2);

 { Barre de titre }
 GSetFillStyle(SolidFill, Blue);
 GBar(X1, Y1, X2, Y1 + 25);
 GSetColor(White);
 GOutTextXY(X1 + 10, Y1 + 7, 'Configuration des notifications');

 { Bouton fermer }
 GSetFillStyle(SolidFill, Red);
 GBar(X2 - 25, Y1 + 3, X2 - 3, Y1 + 22);
 GSetColor(White);
 GOutTextXY(X2 - 18, Y1 + 7, 'X');

 { Bordure }
 GSetColor(DarkGray);
 GRectangle(X1, Y1, X2, Y2);
 GSetColor(White);
 GLine(X1 + 1, Y1 + 26, X2 - 1, Y1 + 26);

 Y := Y1 + 35;

 Case NotificationConfigState Of
  ncsHidden: Exit;

  ncsGeneral: Begin
   { Onglets }
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 10, Y, X1 + 90, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y + 5, 'General');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 95, Y, X1 + 175, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 95, Y, X1 + 175, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 105, Y + 5, 'Dossiers');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 180, Y, X1 + 240, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 180, Y, X1 + 240, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 190, Y + 5, 'Sons');

   Y := Y + 35;

   { Activer les notifications }
   If NotificationSettings.Enabled Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, CheckStr + ' Activer les notifications de nouveau courrier');
   Y := Y + 25;

   { Intervalle de verification }
   GOutTextXY(X1 + 20, Y, 'Verifier les nouveaux messages toutes les:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 280, Y - 3, X1 + 340, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 280, Y - 3, X1 + 340, Y + 15);
   Str(NotificationSettings.CheckInterval Div 60, DisplayStr);
   GSetColor(Black);
   GOutTextXY(X1 + 285, Y, DisplayStr + ' min');
   Y := Y + 25;

   { Verifier au demarrage }
   If NotificationSettings.CheckOnStartup Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 20, Y, CheckStr + ' Verifier au demarrage');
   Y := Y + 25;

   { Type d'alerte sonore par defaut }
   GOutTextXY(X1 + 20, Y, 'Alerte sonore:');
   If NotificationSettings.DefaultSoundAlert = satNone Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 150, Y, CheckStr + ' Aucune');
   If NotificationSettings.DefaultSoundAlert = satSystemBeep Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 250, Y, CheckStr + ' Beep systeme');
   Y := Y + 18;
   If NotificationSettings.DefaultSoundAlert = satMelody Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 150, Y, CheckStr + ' Melodie');
   If NotificationSettings.DefaultSoundAlert = satWAVFile Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 250, Y, CheckStr + ' Fichier WAV');
   Y := Y + 25;

   { Type d'alerte visuelle par defaut }
   GOutTextXY(X1 + 20, Y, 'Alerte visuelle:');
   If NotificationSettings.DefaultVisualAlert = vntNone Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 150, Y, CheckStr + ' Aucune');
   If NotificationSettings.DefaultVisualAlert = vntTitleFlash Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 250, Y, CheckStr + ' Clignotement');
   Y := Y + 18;
   If NotificationSettings.DefaultVisualAlert = vntTitleBadge Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 150, Y, CheckStr + ' Badge titre');
   If NotificationSettings.DefaultVisualAlert = vntPopup Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 250, Y, CheckStr + ' Popup');
   Y := Y + 30;

   { Duree du popup }
   GOutTextXY(X1 + 20, Y, 'Duree d''affichage du popup:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 200, Y - 3, X1 + 250, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 200, Y - 3, X1 + 250, Y + 15);
   Str(NotificationSettings.ShowPopupDuration, DisplayStr);
   GSetColor(Black);
   GOutTextXY(X1 + 205, Y, DisplayStr + ' sec');
  End;

  ncsFolders: Begin
   { Onglets }
   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 10, Y, X1 + 90, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 10, Y, X1 + 90, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y + 5, 'General');

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 95, Y, X1 + 175, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 105, Y + 5, 'Dossiers');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 180, Y, X1 + 240, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 180, Y, X1 + 240, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 190, Y + 5, 'Sons');

   Y := Y + 35;

   { Liste des dossiers avec leurs parametres }
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Configurer les notifications par dossier:');
   Y := Y + 25;

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 20, Y + 180);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 20, Y + 180);

   GSetColor(Black);
   GOutTextXY(X1 + 25, Y + 5, 'Dossier                    Son         Visuel');
   Y := Y + 20;
   GLine(X1 + 20, Y, X2 - 20, Y);

   For I := 0 To FolderNotifSettingsCount - 1 Do Begin
    If I > 6 Then Break;
    If FolderNotifSettings[I].EnableNotification Then CheckStr := '[X]' Else CheckStr := '[ ]';
    GOutTextXY(X1 + 25, Y + 5 + I * 22, CheckStr + ' ' + FolderNotifSettings[I].FolderName);
   End;
  End;

  ncsSounds: Begin
   { Onglets }
   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 10, Y, X1 + 90, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 10, Y, X1 + 90, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y + 5, 'General');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 95, Y, X1 + 175, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 95, Y, X1 + 175, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 105, Y + 5, 'Dossiers');

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 180, Y, X1 + 240, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 190, Y + 5, 'Sons');

   Y := Y + 35;

   { Configuration des sons }
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Fichier WAV par defaut:');
   Y := Y + 20;

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(Black);
   If Length(NotificationSettings.DefaultSoundFile) > 0 Then
    GOutTextXY(X1 + 25, Y + 5, NotificationSettings.DefaultSoundFile)
   Else
    GOutTextXY(X1 + 25, Y + 5, '(Aucun fichier selectionne)');

   { Bouton Parcourir }
   BtnX := X2 - 90;
   BtnW := 70;
   BtnH := 20;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, Y, BtnX + BtnW, Y + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, Y, BtnX + BtnW, Y + BtnH);
   GSetColor(Black);
   GOutTextXY(BtnX + 10, Y + 5, 'Parcourir');

   Y := Y + 35;

   { Bouton Test }
   GOutTextXY(X1 + 20, Y, 'Tester le son:');
   BtnX := X1 + 120;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, Y - 3, BtnX + 80, Y + 17);
   GSetColor(DarkGray);
   GRectangle(BtnX, Y - 3, BtnX + 80, Y + 17);
   GSetColor(Black);
   GOutTextXY(BtnX + 20, Y, 'Tester');
  End;

  ncsHistory: Begin
   { Historique des notifications }
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Historique des notifications:');
   Y := Y + 25;

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 20, Y + 250);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 20, Y + 250);

   GSetColor(Black);
   For I := NotificationHistoryCount - 1 DownTo 0 Do Begin
    If NotificationHistoryCount - 1 - I > 10 Then Break;
    DisplayStr := NotificationHistory[I].AccountName + ' - ' +
                  NotificationHistory[I].FolderName + ': ' +
                  NotificationHistory[I].Subject;
    If Length(DisplayStr) > 55 Then
     DisplayStr := Copy(DisplayStr, 1, 52) + '...';
    GOutTextXY(X1 + 25, Y + 5 + (NotificationHistoryCount - 1 - I) * 22, DisplayStr);
   End;
  End;
 End;

 { Boutons OK et Annuler }
 BtnW := 80;
 BtnH := 25;
 BtnY := Y2 - 40;

 { Bouton OK }
 BtnX := X2 - 180;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 GOutTextXY(BtnX + 30, BtnY + 7, 'OK');

 { Bouton Annuler }
 BtnX := X2 - 90;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 GOutTextXY(BtnX + 15, BtnY + 7, 'Annuler');
End;

{ Gere les clics dans la fenetre de configuration }
Procedure Notif_HandleConfigClick(MX, MY: Integer);
Var
 X1, Y1, X2, Y2: Integer;
 BtnX, BtnY, BtnW, BtnH: Integer;
 TabY: Integer;
Begin
 If Not NotificationConfigVisible Then Exit;

 X1 := NotificationConfigX;
 Y1 := NotificationConfigY;
 X2 := X1 + NOTIF_CONFIG_WIDTH;
 Y2 := Y1 + NOTIF_CONFIG_HEIGHT;

 { Verifier si clic hors de la fenetre }
 If (MX < X1) Or (MX > X2) Or (MY < Y1) Or (MY > Y2) Then Begin
  NotificationConfigVisible := False;
  NotificationConfigState := ncsHidden;
  Exit;
 End;

 { Bouton fermer }
 If (MX >= X2 - 25) And (MX <= X2 - 3) And (MY >= Y1 + 3) And (MY <= Y1 + 22) Then Begin
  NotificationConfigVisible := False;
  NotificationConfigState := ncsHidden;
  Exit;
 End;

 TabY := Y1 + 35;

 { Onglets }
 If (MY >= TabY) And (MY <= TabY + 20) Then Begin
  If (MX >= X1 + 10) And (MX <= X1 + 90) Then Begin
   NotificationConfigState := ncsGeneral;
   Exit;
  End;
  If (MX >= X1 + 95) And (MX <= X1 + 175) Then Begin
   NotificationConfigState := ncsFolders;
   Exit;
  End;
  If (MX >= X1 + 180) And (MX <= X1 + 240) Then Begin
   NotificationConfigState := ncsSounds;
   Exit;
  End;
 End;

 { Options de l'onglet General }
 If NotificationConfigState = ncsGeneral Then Begin
  { Activer les notifications }
  If (MY >= TabY + 35) And (MY <= TabY + 50) And (MX >= X1 + 20) And (MX <= X1 + 400) Then Begin
   NotificationSettings.Enabled := Not NotificationSettings.Enabled;
   Exit;
  End;

  { Verifier au demarrage }
  If (MY >= TabY + 85) And (MY <= TabY + 100) And (MX >= X1 + 20) And (MX <= X1 + 300) Then Begin
   NotificationSettings.CheckOnStartup := Not NotificationSettings.CheckOnStartup;
   Exit;
  End;

  { Types d'alerte sonore }
  If (MY >= TabY + 110) And (MY <= TabY + 125) Then Begin
   If (MX >= X1 + 150) And (MX <= X1 + 240) Then Begin
    NotificationSettings.DefaultSoundAlert := satNone;
    Exit;
   End;
   If (MX >= X1 + 250) And (MX <= X1 + 380) Then Begin
    NotificationSettings.DefaultSoundAlert := satSystemBeep;
    Exit;
   End;
  End;
  If (MY >= TabY + 128) And (MY <= TabY + 143) Then Begin
   If (MX >= X1 + 150) And (MX <= X1 + 240) Then Begin
    NotificationSettings.DefaultSoundAlert := satMelody;
    Exit;
   End;
   If (MX >= X1 + 250) And (MX <= X1 + 380) Then Begin
    NotificationSettings.DefaultSoundAlert := satWAVFile;
    Exit;
   End;
  End;

  { Types d'alerte visuelle }
  If (MY >= TabY + 153) And (MY <= TabY + 168) Then Begin
   If (MX >= X1 + 150) And (MX <= X1 + 240) Then Begin
    NotificationSettings.DefaultVisualAlert := vntNone;
    Exit;
   End;
   If (MX >= X1 + 250) And (MX <= X1 + 380) Then Begin
    NotificationSettings.DefaultVisualAlert := vntTitleFlash;
    Exit;
   End;
  End;
  If (MY >= TabY + 171) And (MY <= TabY + 186) Then Begin
   If (MX >= X1 + 150) And (MX <= X1 + 240) Then Begin
    NotificationSettings.DefaultVisualAlert := vntTitleBadge;
    Exit;
   End;
   If (MX >= X1 + 250) And (MX <= X1 + 380) Then Begin
    NotificationSettings.DefaultVisualAlert := vntPopup;
    Exit;
   End;
  End;
 End;

 { Boutons OK et Annuler }
 BtnW := 80;
 BtnH := 25;
 BtnY := Y2 - 40;

 { Bouton OK }
 BtnX := X2 - 180;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  NotificationConfigVisible := False;
  NotificationConfigState := ncsHidden;
  Exit;
 End;

 { Bouton Annuler }
 BtnX := X2 - 90;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  NotificationConfigVisible := False;
  NotificationConfigState := ncsHidden;
  Exit;
 End;
End;

{ Gere les touches clavier dans la configuration }
Procedure Notif_HandleConfigKey(Key: Char);
Begin
 If Not NotificationConfigVisible Then Exit;

 Case Key Of
  #27: Begin { Echap }
   NotificationConfigVisible := False;
   NotificationConfigState := ncsHidden;
  End;
 End;
End;

{ Affiche la fenetre de configuration des notifications }
Procedure Notif_ShowConfig;
Begin
 NotificationConfigVisible := True;
 NotificationConfigState := ncsGeneral;
End;

{ Masque la fenetre de configuration des notifications }
Procedure Notif_HideConfig;
Begin
 NotificationConfigVisible := False;
 NotificationConfigState := ncsHidden;
End;

{ Retourne le texte du badge pour la barre de titre }
Function Notif_GetTitleBadge: String;
Var
 Count: Integer;
 Result: String;
Begin
 Count := Notif_GetUnacknowledgedCount;
 If Count > 0 Then Begin
  Str(Count, Result);
  Notif_GetTitleBadge := '(' + Result + ') ';
 End Else
  Notif_GetTitleBadge := '';
End;

{ Ajoute des parametres de notification de demonstration }
Procedure Notif_AddDemoSettings;
Begin
 { Configurer les notifications pour les dossiers standards }
 Notif_SetFolderSettings(1, 'Boite de reception', True, satSystemBeep, vntTitleBadge, '');
 Notif_SetFolderSettings(2, 'Elements envoyes', False, satNone, vntNone, '');
 Notif_SetFolderSettings(3, 'Brouillons', False, satNone, vntNone, '');
 Notif_SetFolderSettings(4, 'Elements supprimes', False, satNone, vntNone, '');
 Notif_SetFolderSettings(5, 'Courrier indesirable', True, satMelody, vntPopup, '');
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DES NOTIFICATIONS ET ALERTES (TODO 20)
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DE L'IMPRESSION ET APERCU AVANT IMPRESSION (TODO 21)
  ============================================================================ }

{ Initialise le systeme d'impression }
Procedure Print_Init;
Var
 I, J: Integer;
Begin
 { Parametres par defaut }
 PrintSettings.Port := ppLPT1;
 PrintSettings.OutputFile := '';
 PrintSettings.ExportFormat := efText;
 PrintSettings.PageOrientation := poPortrait;
 PrintSettings.PaperSize := psA4;
 PrintSettings.Margins.Top := PRINT_DEFAULT_MARGIN_TOP;
 PrintSettings.Margins.Bottom := PRINT_DEFAULT_MARGIN_BOTTOM;
 PrintSettings.Margins.Left := PRINT_DEFAULT_MARGIN_LEFT;
 PrintSettings.Margins.Right := PRINT_DEFAULT_MARGIN_RIGHT;
 PrintSettings.Header.Left := '';
 PrintSettings.Header.Center := 'Outlink';
 PrintSettings.Header.Right := '';
 PrintSettings.Header.Enabled := True;
 PrintSettings.Footer.Left := '';
 PrintSettings.Footer.Center := 'Page %PAGE%';
 PrintSettings.Footer.Right := '%DATE%';
 PrintSettings.Footer.Enabled := True;
 PrintSettings.PrintHeaders := True;
 PrintSettings.PrintAttachmentList := True;
 PrintSettings.FontSize := PRINT_DEFAULT_FONT_SIZE;
 PrintSettings.LineSpacing := PRINT_DEFAULT_LINE_SPACING;
 PrintSettings.Copies := 1;
 PrintSettings.PageNumbers := True;
 PrintSettings.PrintDate := True;

 { Initialiser les pages }
 PrintPageCount := 0;
 PrintCurrentPage := 0;
 For I := 0 To MAX_PRINT_PAGES - 1 Do Begin
  PrintPages^[I].LineCount := 0;
  PrintPages^[I].PageNumber := 0;
  PrintPages^[I].HasMore := False;
  For J := 0 To PRINT_MAX_LINES_PER_PAGE - 1 Do
   PrintPages^[I].Lines[J] := '';
 End;

 { Etat initial }
 PrintPreviewState := ppsHidden;
 PrintPreviewX := (GGetMaxX - PRINT_PREVIEW_WIDTH) Div 2;
 PrintPreviewY := (GGetMaxY - PRINT_PREVIEW_HEIGHT) Div 2;
 PrintPreviewZoom := 100;
 PrintConfigState := pcsHidden;
 PrintConfigX := (GGetMaxX - PRINT_CONFIG_WIDTH) Div 2;
 PrintConfigY := (GGetMaxY - PRINT_CONFIG_HEIGHT) Div 2;
 PrintConfigVisible := False;
 PrintMessageIndex := -1;
 PrintInProgress := False;
End;

{ Retourne le nombre de lignes par page selon le papier }
Function Print_GetLinesPerPage: Integer;
Begin
 Case PrintSettings.PaperSize Of
  psLetter, psLegal: Print_GetLinesPerPage := PRINT_LINES_PER_PAGE_LETTER;
  psA4, psA5: Print_GetLinesPerPage := PRINT_LINES_PER_PAGE_A4;
 Else
  Print_GetLinesPerPage := PRINT_LINES_PER_PAGE_LETTER;
 End;
End;

{ Retourne le nombre de caracteres par ligne selon le papier }
Function Print_GetCharsPerLine: Integer;
Begin
 Case PrintSettings.PaperSize Of
  psLetter, psLegal: Print_GetCharsPerLine := PRINT_CHARS_PER_LINE_LETTER;
  psA4, psA5: Print_GetCharsPerLine := PRINT_CHARS_PER_LINE_A4;
 Else
  Print_GetCharsPerLine := PRINT_CHARS_PER_LINE_LETTER;
 End;
End;

{ Remplace les variables dans une chaine d'en-tete/pied de page }
Function Print_ReplaceVariables(S: String; PageNum, TotalPages: Integer): String;
Var
 Result: String;
 PageStr, TotalStr: String;
Begin
 Result := S;
 Str(PageNum, PageStr);
 Str(TotalPages, TotalStr);

 { Remplacer %PAGE% par le numero de page }
 While Pos('%PAGE%', Result) > 0 Do
  Result := Copy(Result, 1, Pos('%PAGE%', Result) - 1) + PageStr +
            Copy(Result, Pos('%PAGE%', Result) + 6, Length(Result));

 { Remplacer %TOTAL% par le nombre total de pages }
 While Pos('%TOTAL%', Result) > 0 Do
  Result := Copy(Result, 1, Pos('%TOTAL%', Result) - 1) + TotalStr +
            Copy(Result, Pos('%TOTAL%', Result) + 7, Length(Result));

 { Remplacer %DATE% par la date actuelle }
 While Pos('%DATE%', Result) > 0 Do
  Result := Copy(Result, 1, Pos('%DATE%', Result) - 1) + '17/04/2026' +
            Copy(Result, Pos('%DATE%', Result) + 6, Length(Result));

 Print_ReplaceVariables := Result;
End;

{ Genere les pages d'impression pour un message }
Procedure Print_GeneratePages(MsgIndex: Integer);
Var
 CurrentPage, CurrentLine, BodyLine: Integer;
 LinesPerPage, CharsPerLine: Integer;
 TempLine: String;
Begin
 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;

 PrintMessageIndex := MsgIndex;
 PrintPageCount := 0;
 CurrentPage := 0;
 CurrentLine := 0;
 LinesPerPage := Print_GetLinesPerPage;
 CharsPerLine := Print_GetCharsPerLine;

 { Initialiser la premiere page }
 PrintPages^[CurrentPage].LineCount := 0;
 PrintPages^[CurrentPage].PageNumber := 1;

 { Ajouter les en-tetes du message si active }
 If PrintSettings.PrintHeaders Then Begin
  { De: }
  TempLine := 'De: ' + Messages^[MsgIndex].FromName + ' <' + Messages^[MsgIndex].FromEmail + '>';
  If Length(TempLine) > CharsPerLine Then
   TempLine := Copy(TempLine, 1, CharsPerLine);
  PrintPages^[CurrentPage].Lines[CurrentLine] := TempLine;
  Inc(CurrentLine);

  { A: }
  TempLine := 'A: ' + Messages^[MsgIndex].ToName + ' <' + Messages^[MsgIndex].ToEmail + '>';
  If Length(TempLine) > CharsPerLine Then
   TempLine := Copy(TempLine, 1, CharsPerLine);
  PrintPages^[CurrentPage].Lines[CurrentLine] := TempLine;
  Inc(CurrentLine);

  { Cc: si present }
  If Length(Messages^[MsgIndex].CcEmail) > 0 Then Begin
   TempLine := 'Cc: ' + Messages^[MsgIndex].CcEmail;
   If Length(TempLine) > CharsPerLine Then
    TempLine := Copy(TempLine, 1, CharsPerLine);
   PrintPages^[CurrentPage].Lines[CurrentLine] := TempLine;
   Inc(CurrentLine);
  End;

  { Date: }
  TempLine := 'Date: ' + Messages^[MsgIndex].DateFull;
  PrintPages^[CurrentPage].Lines[CurrentLine] := TempLine;
  Inc(CurrentLine);

  { Objet: }
  TempLine := 'Objet: ' + Messages^[MsgIndex].Subject;
  If Length(TempLine) > CharsPerLine Then
   TempLine := Copy(TempLine, 1, CharsPerLine);
  PrintPages^[CurrentPage].Lines[CurrentLine] := TempLine;
  Inc(CurrentLine);

  { Ligne vide de separation }
  PrintPages^[CurrentPage].Lines[CurrentLine] := '';
  Inc(CurrentLine);

  { Ligne de separation }
  PrintPages^[CurrentPage].Lines[CurrentLine] := '----------------------------------------';
  Inc(CurrentLine);

  { Ligne vide }
  PrintPages^[CurrentPage].Lines[CurrentLine] := '';
  Inc(CurrentLine);
 End;

 { Ajouter le corps du message }
 For BodyLine := 0 To Messages^[MsgIndex].BodyLineCount - 1 Do Begin
  { Verifier si on doit passer a la page suivante }
  If CurrentLine >= LinesPerPage Then Begin
   PrintPages^[CurrentPage].LineCount := CurrentLine;
   PrintPages^[CurrentPage].HasMore := True;
   Inc(CurrentPage);
   If CurrentPage >= MAX_PRINT_PAGES Then Break;
   CurrentLine := 0;
   PrintPages^[CurrentPage].PageNumber := CurrentPage + 1;
  End;

  TempLine := Messages^[MsgIndex].Body[BodyLine];
  If Length(TempLine) > CharsPerLine Then
   TempLine := Copy(TempLine, 1, CharsPerLine);
  PrintPages^[CurrentPage].Lines[CurrentLine] := TempLine;
  Inc(CurrentLine);
 End;

 { Liste des pieces jointes si active }
 If PrintSettings.PrintAttachmentList And (Messages^[MsgIndex].AttachmentCount > 0) Then Begin
  { Verifier l'espace }
  If CurrentLine + 3 >= LinesPerPage Then Begin
   PrintPages^[CurrentPage].LineCount := CurrentLine;
   PrintPages^[CurrentPage].HasMore := True;
   Inc(CurrentPage);
   If CurrentPage < MAX_PRINT_PAGES Then Begin
    CurrentLine := 0;
    PrintPages^[CurrentPage].PageNumber := CurrentPage + 1;
   End;
  End;

  If CurrentPage < MAX_PRINT_PAGES Then Begin
   PrintPages^[CurrentPage].Lines[CurrentLine] := '';
   Inc(CurrentLine);
   PrintPages^[CurrentPage].Lines[CurrentLine] := '----------------------------------------';
   Inc(CurrentLine);
   PrintPages^[CurrentPage].Lines[CurrentLine] := 'Pieces jointes:';
   Inc(CurrentLine);

   For BodyLine := 0 To Messages^[MsgIndex].AttachmentCount - 1 Do Begin
    If CurrentLine >= LinesPerPage Then Begin
     PrintPages^[CurrentPage].LineCount := CurrentLine;
     PrintPages^[CurrentPage].HasMore := True;
     Inc(CurrentPage);
     If CurrentPage >= MAX_PRINT_PAGES Then Break;
     CurrentLine := 0;
     PrintPages^[CurrentPage].PageNumber := CurrentPage + 1;
    End;
    PrintPages^[CurrentPage].Lines[CurrentLine] := '  - ' + Messages^[MsgIndex].Attachments[BodyLine].FileName;
    Inc(CurrentLine);
   End;
  End;
 End;

 { Finaliser la derniere page }
 If CurrentPage < MAX_PRINT_PAGES Then Begin
  PrintPages^[CurrentPage].LineCount := CurrentLine;
  PrintPages^[CurrentPage].HasMore := False;
 End;

 PrintPageCount := CurrentPage + 1;
 PrintCurrentPage := 0;
End;

{ Exporte un message en texte brut }
Procedure Print_ExportToText(MsgIndex: Integer; FileName: String);
Var
 F: Text;
 I, J: Integer;
Begin
 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;

 { Generer les pages }
 Print_GeneratePages(MsgIndex);

 {$I-}
 Assign(F, FileName);
 Rewrite(F);
 If IOResult <> 0 Then Exit;

 { Ecrire chaque page }
 For I := 0 To PrintPageCount - 1 Do Begin
  { En-tete si active }
  If PrintSettings.Header.Enabled Then Begin
   WriteLn(F, Print_ReplaceVariables(PrintSettings.Header.Center, I + 1, PrintPageCount));
   WriteLn(F, '');
  End;

  { Contenu }
  For J := 0 To PrintPages^[I].LineCount - 1 Do
   WriteLn(F, PrintPages^[I].Lines[J]);

  { Pied de page si active }
  If PrintSettings.Footer.Enabled Then Begin
   WriteLn(F, '');
   WriteLn(F, Print_ReplaceVariables(PrintSettings.Footer.Center, I + 1, PrintPageCount));
  End;

  { Saut de page si pas la derniere }
  If I < PrintPageCount - 1 Then
   WriteLn(F, #12); { Form feed }
 End;

 Close(F);
 {$I+}
End;

{ Exporte un message en HTML }
Procedure Print_ExportToHTML(MsgIndex: Integer; FileName: String);
Var
 F: Text;
 I, J: Integer;
 Line: String;
Begin
 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;

 { Generer les pages }
 Print_GeneratePages(MsgIndex);

 {$I-}
 Assign(F, FileName);
 Rewrite(F);
 If IOResult <> 0 Then Exit;

 { En-tete HTML }
 WriteLn(F, '<!DOCTYPE html>');
 WriteLn(F, '<html>');
 WriteLn(F, '<head>');
 WriteLn(F, '<meta charset="UTF-8">');
 WriteLn(F, '<title>Message: ' + Messages^[MsgIndex].Subject + '</title>');
 WriteLn(F, '<style>');
 WriteLn(F, 'body { font-family: Arial, sans-serif; margin: 20px; }');
 WriteLn(F, '.header { background: #f0f0f0; padding: 10px; border: 1px solid #ccc; }');
 WriteLn(F, '.header p { margin: 5px 0; }');
 WriteLn(F, '.body { margin-top: 20px; white-space: pre-wrap; }');
 WriteLn(F, '.attachments { margin-top: 20px; border-top: 1px solid #ccc; padding-top: 10px; }');
 WriteLn(F, '.footer { margin-top: 30px; font-size: 0.9em; color: #666; }');
 WriteLn(F, '</style>');
 WriteLn(F, '</head>');
 WriteLn(F, '<body>');

 { En-tete du message }
 WriteLn(F, '<div class="header">');
 WriteLn(F, '<p><strong>De:</strong> ' + Messages^[MsgIndex].FromName + ' &lt;' + Messages^[MsgIndex].FromEmail + '&gt;</p>');
 WriteLn(F, '<p><strong>A:</strong> ' + Messages^[MsgIndex].ToName + ' &lt;' + Messages^[MsgIndex].ToEmail + '&gt;</p>');
 If Length(Messages^[MsgIndex].CcEmail) > 0 Then
  WriteLn(F, '<p><strong>Cc:</strong> ' + Messages^[MsgIndex].CcEmail + '</p>');
 WriteLn(F, '<p><strong>Date:</strong> ' + Messages^[MsgIndex].DateFull + '</p>');
 WriteLn(F, '<p><strong>Objet:</strong> ' + Messages^[MsgIndex].Subject + '</p>');
 WriteLn(F, '</div>');

 { Corps du message }
 WriteLn(F, '<div class="body">');
 For I := 0 To Messages^[MsgIndex].BodyLineCount - 1 Do Begin
  Line := Messages^[MsgIndex].Body[I];
  { Echapper les caracteres HTML }
  While Pos('<', Line) > 0 Do
   Line := Copy(Line, 1, Pos('<', Line) - 1) + '&lt;' + Copy(Line, Pos('<', Line) + 1, Length(Line));
  While Pos('>', Line) > 0 Do
   Line := Copy(Line, 1, Pos('>', Line) - 1) + '&gt;' + Copy(Line, Pos('>', Line) + 1, Length(Line));
  WriteLn(F, Line);
 End;
 WriteLn(F, '</div>');

 { Pieces jointes }
 If Messages^[MsgIndex].AttachmentCount > 0 Then Begin
  WriteLn(F, '<div class="attachments">');
  WriteLn(F, '<p><strong>Pieces jointes:</strong></p>');
  WriteLn(F, '<ul>');
  For I := 0 To Messages^[MsgIndex].AttachmentCount - 1 Do
   WriteLn(F, '<li>' + Messages^[MsgIndex].Attachments[I].FileName + '</li>');
  WriteLn(F, '</ul>');
  WriteLn(F, '</div>');
 End;

 { Pied de page }
 WriteLn(F, '<div class="footer">');
 WriteLn(F, '<p>Imprime depuis Outlink - ' + Print_ReplaceVariables('%DATE%', 1, 1) + '</p>');
 WriteLn(F, '</div>');

 WriteLn(F, '</body>');
 WriteLn(F, '</html>');

 Close(F);
 {$I+}
End;

{ Envoie les donnees vers l'imprimante }
Procedure Print_SendToPrinter(MsgIndex: Integer);
Var
 PrinterName: String;
 F: Text;
 I, J, Copy: Integer;
Begin
 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;

 { Generer les pages }
 Print_GeneratePages(MsgIndex);

 { Determiner le port }
 Case PrintSettings.Port Of
  ppLPT1: PrinterName := 'LPT1';
  ppLPT2: PrinterName := 'LPT2';
  ppLPT3: PrinterName := 'LPT3';
  ppFile: Begin
   If Length(PrintSettings.OutputFile) > 0 Then Begin
    Case PrintSettings.ExportFormat Of
     efText: Print_ExportToText(MsgIndex, PrintSettings.OutputFile);
     efHTML: Print_ExportToHTML(MsgIndex, PrintSettings.OutputFile);
    End;
   End;
   Exit;
  End;
 End;

 { Imprimer chaque copie }
 For Copy := 1 To PrintSettings.Copies Do Begin
  {$I-}
  Assign(F, PrinterName);
  Rewrite(F);
  If IOResult <> 0 Then Exit;

  { Ecrire chaque page }
  For I := 0 To PrintPageCount - 1 Do Begin
   { En-tete si active }
   If PrintSettings.Header.Enabled Then Begin
    If Length(PrintSettings.Header.Left) > 0 Then
     Write(F, Print_ReplaceVariables(PrintSettings.Header.Left, I + 1, PrintPageCount));
    If Length(PrintSettings.Header.Center) > 0 Then Begin
     { Centrer le texte }
     WriteLn(F, '');
     WriteLn(F, Print_ReplaceVariables(PrintSettings.Header.Center, I + 1, PrintPageCount));
    End;
    WriteLn(F, '');
   End;

   { Contenu }
   For J := 0 To PrintPages^[I].LineCount - 1 Do
    WriteLn(F, PrintPages^[I].Lines[J]);

   { Pied de page si active }
   If PrintSettings.Footer.Enabled Then Begin
    WriteLn(F, '');
    If Length(PrintSettings.Footer.Left) > 0 Then
     Write(F, Print_ReplaceVariables(PrintSettings.Footer.Left, I + 1, PrintPageCount));
    If Length(PrintSettings.Footer.Center) > 0 Then
     WriteLn(F, Print_ReplaceVariables(PrintSettings.Footer.Center, I + 1, PrintPageCount));
    If Length(PrintSettings.Footer.Right) > 0 Then
     WriteLn(F, Print_ReplaceVariables(PrintSettings.Footer.Right, I + 1, PrintPageCount));
   End;

   { Saut de page si pas la derniere }
   If I < PrintPageCount - 1 Then
    Write(F, #12); { Form feed }
  End;

  Close(F);
  {$I+}
 End;
End;

{ Affiche l'apercu avant impression }
Procedure Print_DrawPreview;
Var
 X1, Y1, X2, Y2: Integer;
 PageX, PageY, PageW, PageH: Integer;
 I, Y, LineH: Integer;
 DisplayStr, PageStr: String;
 BtnX, BtnY, BtnW, BtnH: Integer;
Begin
 If PrintPreviewState = ppsHidden Then Exit;

 X1 := PrintPreviewX;
 Y1 := PrintPreviewY;
 X2 := X1 + PRINT_PREVIEW_WIDTH;
 Y2 := Y1 + PRINT_PREVIEW_HEIGHT;

 { Fond de la fenetre }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X1, Y1, X2, Y2);

 { Barre de titre }
 GSetFillStyle(SolidFill, Blue);
 GBar(X1, Y1, X2, Y1 + 25);
 GSetColor(White);
 GOutTextXY(X1 + 10, Y1 + 7, 'Apercu avant impression');

 { Bouton fermer }
 GSetFillStyle(SolidFill, Red);
 GBar(X2 - 25, Y1 + 3, X2 - 3, Y1 + 22);
 GSetColor(White);
 GOutTextXY(X2 - 18, Y1 + 7, 'X');

 { Bordure }
 GSetColor(DarkGray);
 GRectangle(X1, Y1, X2, Y2);

 { Zone de l'apercu de page (fond blanc) }
 PageW := 200;
 PageH := 280;
 PageX := X1 + 20;
 PageY := Y1 + 35;
 GSetFillStyle(SolidFill, White);
 GBar(PageX, PageY, PageX + PageW, PageY + PageH);
 GSetColor(Black);
 GRectangle(PageX, PageY, PageX + PageW, PageY + PageH);

 { Afficher le contenu de la page actuelle }
 If (PrintCurrentPage >= 0) And (PrintCurrentPage < PrintPageCount) Then Begin
  LineH := 4;
  GSetColor(DarkGray);
  For I := 0 To PrintPages^[PrintCurrentPage].LineCount - 1 Do Begin
   Y := PageY + 5 + I * LineH;
   If Y + LineH > PageY + PageH - 5 Then Break;
   { Simuler les lignes de texte avec des traits }
   DisplayStr := PrintPages^[PrintCurrentPage].Lines[I];
   If Length(DisplayStr) > 0 Then
    GLine(PageX + 5, Y + 2, PageX + 5 + Length(DisplayStr) * 2, Y + 2);
  End;
 End;

 { Informations de page }
 GSetColor(Black);
 Str(PrintCurrentPage + 1, PageStr);
 GOutTextXY(PageX + PageW + 20, PageY + 10, 'Page: ' + PageStr);
 Str(PrintPageCount, PageStr);
 GOutTextXY(PageX + PageW + 20, PageY + 25, 'Total: ' + PageStr + ' pages');

 { Boutons de navigation }
 BtnW := 80;
 BtnH := 25;
 BtnY := PageY + 60;

 { Bouton Page precedente }
 BtnX := PageX + PageW + 20;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 GOutTextXY(BtnX + 5, BtnY + 7, '< Prec.');

 { Bouton Page suivante }
 BtnY := BtnY + 30;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 GOutTextXY(BtnX + 5, BtnY + 7, 'Suiv. >');

 { Bouton Zoom }
 BtnY := BtnY + 40;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 Str(PrintPreviewZoom, PageStr);
 GSetColor(Black);
 GOutTextXY(BtnX + 10, BtnY + 7, 'Zoom ' + PageStr + '%');

 { Boutons d'action en bas }
 BtnY := Y2 - 40;

 { Bouton Imprimer }
 BtnX := X1 + 20;
 GSetFillStyle(SolidFill, Green);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(White);
 GOutTextXY(BtnX + 15, BtnY + 7, 'Imprimer');

 { Bouton Configurer }
 BtnX := BtnX + BtnW + 10;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 GOutTextXY(BtnX + 10, BtnY + 7, 'Options');

 { Bouton Exporter }
 BtnX := BtnX + BtnW + 10;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 GOutTextXY(BtnX + 10, BtnY + 7, 'Exporter');

 { Bouton Fermer }
 BtnX := X2 - BtnW - 10;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 GOutTextXY(BtnX + 15, BtnY + 7, 'Fermer');
End;

{ Gere les clics dans l'apercu avant impression }
Procedure Print_HandlePreviewClick(MX, MY: Integer);
Var
 X1, Y1, X2, Y2: Integer;
 BtnX, BtnY, BtnW, BtnH: Integer;
 PageX, PageW: Integer;
Begin
 If PrintPreviewState = ppsHidden Then Exit;

 X1 := PrintPreviewX;
 Y1 := PrintPreviewY;
 X2 := X1 + PRINT_PREVIEW_WIDTH;
 Y2 := Y1 + PRINT_PREVIEW_HEIGHT;
 BtnW := 80;
 BtnH := 25;
 PageW := 200;
 PageX := X1 + 20;

 { Verifier si clic hors de la fenetre }
 If (MX < X1) Or (MX > X2) Or (MY < Y1) Or (MY > Y2) Then Begin
  PrintPreviewState := ppsHidden;
  Exit;
 End;

 { Bouton fermer (X) }
 If (MX >= X2 - 25) And (MX <= X2 - 3) And (MY >= Y1 + 3) And (MY <= Y1 + 22) Then Begin
  PrintPreviewState := ppsHidden;
  Exit;
 End;

 { Boutons de navigation }
 BtnX := PageX + PageW + 20;
 BtnY := Y1 + 35 + 60;

 { Page precedente }
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  If PrintCurrentPage > 0 Then Dec(PrintCurrentPage);
  Exit;
 End;

 { Page suivante }
 BtnY := BtnY + 30;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  If PrintCurrentPage < PrintPageCount - 1 Then Inc(PrintCurrentPage);
  Exit;
 End;

 { Zoom }
 BtnY := BtnY + 40;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  PrintPreviewZoom := PrintPreviewZoom + 25;
  If PrintPreviewZoom > 200 Then PrintPreviewZoom := 50;
  Exit;
 End;

 { Boutons d'action en bas }
 BtnY := Y2 - 40;

 { Bouton Imprimer }
 BtnX := X1 + 20;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  Print_SendToPrinter(PrintMessageIndex);
  PrintPreviewState := ppsHidden;
  Exit;
 End;

 { Bouton Configurer }
 BtnX := BtnX + BtnW + 10;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  PrintConfigVisible := True;
  PrintConfigState := pcsGeneral;
  Exit;
 End;

 { Bouton Exporter }
 BtnX := BtnX + BtnW + 10;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  { Exporter en texte par defaut }
  Print_ExportToText(PrintMessageIndex, 'message.txt');
  Exit;
 End;

 { Bouton Fermer }
 BtnX := X2 - BtnW - 10;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  PrintPreviewState := ppsHidden;
  Exit;
 End;
End;

{ Affiche la fenetre de configuration d'impression }
Procedure Print_DrawConfigWindow;
Var
 X1, Y1, X2, Y2: Integer;
 Y, BtnX, BtnY, BtnW, BtnH: Integer;
 DisplayStr, CheckStr: String;
Begin
 If Not PrintConfigVisible Then Exit;

 X1 := PrintConfigX;
 Y1 := PrintConfigY;
 X2 := X1 + PRINT_CONFIG_WIDTH;
 Y2 := Y1 + PRINT_CONFIG_HEIGHT;

 { Fond de la fenetre }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X1, Y1, X2, Y2);

 { Barre de titre }
 GSetFillStyle(SolidFill, Blue);
 GBar(X1, Y1, X2, Y1 + 25);
 GSetColor(White);
 GOutTextXY(X1 + 10, Y1 + 7, 'Configuration de l''impression');

 { Bouton fermer }
 GSetFillStyle(SolidFill, Red);
 GBar(X2 - 25, Y1 + 3, X2 - 3, Y1 + 22);
 GSetColor(White);
 GOutTextXY(X2 - 18, Y1 + 7, 'X');

 { Bordure }
 GSetColor(DarkGray);
 GRectangle(X1, Y1, X2, Y2);

 Y := Y1 + 35;

 Case PrintConfigState Of
  pcsHidden: Exit;

  pcsGeneral: Begin
   { Onglets }
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 10, Y, X1 + 80, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y + 5, 'General');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 85, Y, X1 + 155, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 85, Y, X1 + 155, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 95, Y + 5, 'Marges');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 160, Y, X1 + 250, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 160, Y, X1 + 250, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 165, Y + 5, 'En-tetes');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 255, Y, X1 + 325, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 255, Y, X1 + 325, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 265, Y + 5, 'Export');

   Y := Y + 35;

   { Port d'imprimante }
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Imprimante:');
   If PrintSettings.Port = ppLPT1 Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 120, Y, CheckStr + ' LPT1');
   If PrintSettings.Port = ppLPT2 Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 200, Y, CheckStr + ' LPT2');
   If PrintSettings.Port = ppFile Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 280, Y, CheckStr + ' Fichier');
   Y := Y + 25;

   { Taille du papier }
   GOutTextXY(X1 + 20, Y, 'Papier:');
   If PrintSettings.PaperSize = psLetter Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 120, Y, CheckStr + ' Letter');
   If PrintSettings.PaperSize = psA4 Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 200, Y, CheckStr + ' A4');
   If PrintSettings.PaperSize = psLegal Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 280, Y, CheckStr + ' Legal');
   Y := Y + 25;

   { Orientation }
   GOutTextXY(X1 + 20, Y, 'Orientation:');
   If PrintSettings.PageOrientation = poPortrait Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 120, Y, CheckStr + ' Portrait');
   If PrintSettings.PageOrientation = poLandscape Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 220, Y, CheckStr + ' Paysage');
   Y := Y + 25;

   { Nombre de copies }
   GOutTextXY(X1 + 20, Y, 'Copies:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 120, Y - 3, X1 + 170, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 120, Y - 3, X1 + 170, Y + 15);
   Str(PrintSettings.Copies, DisplayStr);
   GSetColor(Black);
   GOutTextXY(X1 + 130, Y, DisplayStr);
   Y := Y + 25;

   { Options }
   If PrintSettings.PrintHeaders Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 20, Y, CheckStr + ' Imprimer les en-tetes du message');
   Y := Y + 20;

   If PrintSettings.PrintAttachmentList Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 20, Y, CheckStr + ' Lister les pieces jointes');
   Y := Y + 20;

   If PrintSettings.PageNumbers Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 20, Y, CheckStr + ' Afficher les numeros de page');
  End;

  pcsMargins: Begin
   { Onglets }
   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 10, Y, X1 + 80, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 10, Y, X1 + 80, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y + 5, 'General');

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 85, Y, X1 + 155, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 95, Y + 5, 'Marges');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 160, Y, X1 + 250, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 160, Y, X1 + 250, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 165, Y + 5, 'En-tetes');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 255, Y, X1 + 325, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 255, Y, X1 + 325, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 265, Y + 5, 'Export');

   Y := Y + 35;

   { Marges }
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Marges (en mm):');
   Y := Y + 25;

   GOutTextXY(X1 + 40, Y, 'Haut:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 100, Y - 3, X1 + 150, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 100, Y - 3, X1 + 150, Y + 15);
   Str(PrintSettings.Margins.Top, DisplayStr);
   GSetColor(Black);
   GOutTextXY(X1 + 105, Y, DisplayStr);

   GOutTextXY(X1 + 180, Y, 'Bas:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 230, Y - 3, X1 + 280, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 230, Y - 3, X1 + 280, Y + 15);
   Str(PrintSettings.Margins.Bottom, DisplayStr);
   GSetColor(Black);
   GOutTextXY(X1 + 235, Y, DisplayStr);
   Y := Y + 30;

   GOutTextXY(X1 + 40, Y, 'Gauche:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 100, Y - 3, X1 + 150, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 100, Y - 3, X1 + 150, Y + 15);
   Str(PrintSettings.Margins.Left, DisplayStr);
   GSetColor(Black);
   GOutTextXY(X1 + 105, Y, DisplayStr);

   GOutTextXY(X1 + 180, Y, 'Droite:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 230, Y - 3, X1 + 280, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 230, Y - 3, X1 + 280, Y + 15);
   Str(PrintSettings.Margins.Right, DisplayStr);
   GSetColor(Black);
   GOutTextXY(X1 + 235, Y, DisplayStr);
  End;

  pcsHeaderFooter: Begin
   { Onglets }
   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 10, Y, X1 + 80, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 10, Y, X1 + 80, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y + 5, 'General');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 85, Y, X1 + 155, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 85, Y, X1 + 155, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 95, Y + 5, 'Marges');

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 160, Y, X1 + 250, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 165, Y + 5, 'En-tetes');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 255, Y, X1 + 325, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 255, Y, X1 + 325, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 265, Y + 5, 'Export');

   Y := Y + 35;

   { En-tete }
   GSetColor(Black);
   If PrintSettings.Header.Enabled Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 20, Y, CheckStr + ' En-tete de page');
   Y := Y + 25;

   GOutTextXY(X1 + 40, Y, 'Centre:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 100, Y - 3, X2 - 30, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 100, Y - 3, X2 - 30, Y + 15);
   GSetColor(Black);
   GOutTextXY(X1 + 105, Y, PrintSettings.Header.Center);
   Y := Y + 30;

   { Pied de page }
   If PrintSettings.Footer.Enabled Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 20, Y, CheckStr + ' Pied de page');
   Y := Y + 25;

   GOutTextXY(X1 + 40, Y, 'Centre:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 100, Y - 3, X2 - 30, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 100, Y - 3, X2 - 30, Y + 15);
   GSetColor(Black);
   GOutTextXY(X1 + 105, Y, PrintSettings.Footer.Center);
   Y := Y + 25;

   GOutTextXY(X1 + 40, Y, 'Droite:');
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 100, Y - 3, X2 - 30, Y + 15);
   GSetColor(DarkGray);
   GRectangle(X1 + 100, Y - 3, X2 - 30, Y + 15);
   GSetColor(Black);
   GOutTextXY(X1 + 105, Y, PrintSettings.Footer.Right);
   Y := Y + 30;

   GOutTextXY(X1 + 20, Y, 'Variables: %PAGE%, %TOTAL%, %DATE%');
  End;

  pcsExport: Begin
   { Onglets }
   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 10, Y, X1 + 80, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 10, Y, X1 + 80, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y + 5, 'General');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 85, Y, X1 + 155, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 85, Y, X1 + 155, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 95, Y + 5, 'Marges');

   GSetFillStyle(SolidFill, LightGray);
   GBar(X1 + 160, Y, X1 + 250, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 160, Y, X1 + 250, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 165, Y + 5, 'En-tetes');

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 255, Y, X1 + 325, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 265, Y + 5, 'Export');

   Y := Y + 35;

   { Format d'export }
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Format d''export:');
   Y := Y + 25;

   If PrintSettings.ExportFormat = efText Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Texte brut (.txt)');
   Y := Y + 20;

   If PrintSettings.ExportFormat = efHTML Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 40, Y, CheckStr + ' HTML (.html)');
   Y := Y + 30;

   { Fichier de sortie }
   GOutTextXY(X1 + 20, Y, 'Fichier de sortie:');
   Y := Y + 20;

   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(Black);
   If Length(PrintSettings.OutputFile) > 0 Then
    GOutTextXY(X1 + 25, Y + 5, PrintSettings.OutputFile)
   Else
    GOutTextXY(X1 + 25, Y + 5, 'message.txt');

   { Bouton Parcourir }
   BtnX := X2 - 90;
   BtnW := 70;
   BtnH := 20;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, Y, BtnX + BtnW, Y + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, Y, BtnX + BtnW, Y + BtnH);
   GSetColor(Black);
   GOutTextXY(BtnX + 10, Y + 5, 'Parcourir');
  End;
 End;

 { Boutons OK et Annuler }
 BtnW := 80;
 BtnH := 25;
 BtnY := Y2 - 40;

 { Bouton OK }
 BtnX := X2 - 180;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 GOutTextXY(BtnX + 30, BtnY + 7, 'OK');

 { Bouton Annuler }
 BtnX := X2 - 90;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 GOutTextXY(BtnX + 15, BtnY + 7, 'Annuler');
End;

{ Gere les clics dans la fenetre de configuration }
Procedure Print_HandleConfigClick(MX, MY: Integer);
Var
 X1, Y1, X2, Y2: Integer;
 BtnX, BtnY, BtnW, BtnH: Integer;
 TabY: Integer;
Begin
 If Not PrintConfigVisible Then Exit;

 X1 := PrintConfigX;
 Y1 := PrintConfigY;
 X2 := X1 + PRINT_CONFIG_WIDTH;
 Y2 := Y1 + PRINT_CONFIG_HEIGHT;
 BtnW := 80;
 BtnH := 25;

 { Verifier si clic hors de la fenetre }
 If (MX < X1) Or (MX > X2) Or (MY < Y1) Or (MY > Y2) Then Begin
  PrintConfigVisible := False;
  PrintConfigState := pcsHidden;
  Exit;
 End;

 { Bouton fermer }
 If (MX >= X2 - 25) And (MX <= X2 - 3) And (MY >= Y1 + 3) And (MY <= Y1 + 22) Then Begin
  PrintConfigVisible := False;
  PrintConfigState := pcsHidden;
  Exit;
 End;

 TabY := Y1 + 35;

 { Onglets }
 If (MY >= TabY) And (MY <= TabY + 20) Then Begin
  If (MX >= X1 + 10) And (MX <= X1 + 80) Then Begin
   PrintConfigState := pcsGeneral;
   Exit;
  End;
  If (MX >= X1 + 85) And (MX <= X1 + 155) Then Begin
   PrintConfigState := pcsMargins;
   Exit;
  End;
  If (MX >= X1 + 160) And (MX <= X1 + 250) Then Begin
   PrintConfigState := pcsHeaderFooter;
   Exit;
  End;
  If (MX >= X1 + 255) And (MX <= X1 + 325) Then Begin
   PrintConfigState := pcsExport;
   Exit;
  End;
 End;

 { Options de l'onglet General }
 If PrintConfigState = pcsGeneral Then Begin
  { Port d'imprimante }
  If (MY >= TabY + 35) And (MY <= TabY + 50) Then Begin
   If (MX >= X1 + 120) And (MX <= X1 + 190) Then Begin
    PrintSettings.Port := ppLPT1;
    Exit;
   End;
   If (MX >= X1 + 200) And (MX <= X1 + 270) Then Begin
    PrintSettings.Port := ppLPT2;
    Exit;
   End;
   If (MX >= X1 + 280) And (MX <= X1 + 360) Then Begin
    PrintSettings.Port := ppFile;
    Exit;
   End;
  End;

  { Taille du papier }
  If (MY >= TabY + 60) And (MY <= TabY + 75) Then Begin
   If (MX >= X1 + 120) And (MX <= X1 + 190) Then Begin
    PrintSettings.PaperSize := psLetter;
    Exit;
   End;
   If (MX >= X1 + 200) And (MX <= X1 + 250) Then Begin
    PrintSettings.PaperSize := psA4;
    Exit;
   End;
   If (MX >= X1 + 280) And (MX <= X1 + 340) Then Begin
    PrintSettings.PaperSize := psLegal;
    Exit;
   End;
  End;

  { Orientation }
  If (MY >= TabY + 85) And (MY <= TabY + 100) Then Begin
   If (MX >= X1 + 120) And (MX <= X1 + 210) Then Begin
    PrintSettings.PageOrientation := poPortrait;
    Exit;
   End;
   If (MX >= X1 + 220) And (MX <= X1 + 310) Then Begin
    PrintSettings.PageOrientation := poLandscape;
    Exit;
   End;
  End;

  { Options checkboxes }
  If (MY >= TabY + 135) And (MY <= TabY + 150) And (MX >= X1 + 20) And (MX <= X1 + 350) Then Begin
   PrintSettings.PrintHeaders := Not PrintSettings.PrintHeaders;
   Exit;
  End;
  If (MY >= TabY + 155) And (MY <= TabY + 170) And (MX >= X1 + 20) And (MX <= X1 + 300) Then Begin
   PrintSettings.PrintAttachmentList := Not PrintSettings.PrintAttachmentList;
   Exit;
  End;
  If (MY >= TabY + 175) And (MY <= TabY + 190) And (MX >= X1 + 20) And (MX <= X1 + 300) Then Begin
   PrintSettings.PageNumbers := Not PrintSettings.PageNumbers;
   Exit;
  End;
 End;

 { Options de l'onglet En-tetes }
 If PrintConfigState = pcsHeaderFooter Then Begin
  If (MY >= TabY + 35) And (MY <= TabY + 50) And (MX >= X1 + 20) And (MX <= X1 + 200) Then Begin
   PrintSettings.Header.Enabled := Not PrintSettings.Header.Enabled;
   Exit;
  End;
  If (MY >= TabY + 110) And (MY <= TabY + 125) And (MX >= X1 + 20) And (MX <= X1 + 200) Then Begin
   PrintSettings.Footer.Enabled := Not PrintSettings.Footer.Enabled;
   Exit;
  End;
 End;

 { Options de l'onglet Export }
 If PrintConfigState = pcsExport Then Begin
  If (MY >= TabY + 60) And (MY <= TabY + 75) And (MX >= X1 + 40) And (MX <= X1 + 200) Then Begin
   PrintSettings.ExportFormat := efText;
   Exit;
  End;
  If (MY >= TabY + 80) And (MY <= TabY + 95) And (MX >= X1 + 40) And (MX <= X1 + 200) Then Begin
   PrintSettings.ExportFormat := efHTML;
   Exit;
  End;
 End;

 { Boutons OK et Annuler }
 BtnY := Y2 - 40;

 { Bouton OK }
 BtnX := X2 - 180;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  { Regenerer les pages avec les nouveaux parametres }
  If PrintMessageIndex >= 0 Then
   Print_GeneratePages(PrintMessageIndex);
  PrintConfigVisible := False;
  PrintConfigState := pcsHidden;
  Exit;
 End;

 { Bouton Annuler }
 BtnX := X2 - 90;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  PrintConfigVisible := False;
  PrintConfigState := pcsHidden;
  Exit;
 End;
End;

{ Affiche l'apercu avant impression pour un message }
Procedure Print_ShowPreview(MsgIndex: Integer);
Begin
 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;

 Print_GeneratePages(MsgIndex);
 PrintPreviewState := ppsShowing;
 PrintCurrentPage := 0;
End;

{ Masque l'apercu avant impression }
Procedure Print_HidePreview;
Begin
 PrintPreviewState := ppsHidden;
End;

{ Affiche la fenetre de configuration }
Procedure Print_ShowConfig;
Begin
 PrintConfigVisible := True;
 PrintConfigState := pcsGeneral;
End;

{ Masque la fenetre de configuration }
Procedure Print_HideConfig;
Begin
 PrintConfigVisible := False;
 PrintConfigState := pcsHidden;
End;

{ Imprime le message selectionne }
Procedure Print_PrintSelectedMessage;
Begin
 If SelectedMessage >= 0 Then
  Print_SendToPrinter(SelectedMessage);
End;

{ Exporte le message selectionne en texte }
Procedure Print_ExportSelectedToText(FileName: String);
Begin
 If SelectedMessage >= 0 Then
  Print_ExportToText(SelectedMessage, FileName);
End;

{ Exporte le message selectionne en HTML }
Procedure Print_ExportSelectedToHTML(FileName: String);
Begin
 If SelectedMessage >= 0 Then
  Print_ExportToHTML(SelectedMessage, FileName);
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DE L'IMPRESSION ET APERCU (TODO 21)
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DE LA SAUVEGARDE ET L'EXPORT (TODO 22)
  ============================================================================ }

{ Initialise le systeme de sauvegarde }
Procedure Backup_Init;
Begin
 { Etat initial }
 BackupState := bsHidden;
 BackupVisible := False;
 BackupWindowX := (GGetMaxX - BACKUP_WINDOW_WIDTH) Div 2;
 BackupWindowY := (GGetMaxY - BACKUP_WINDOW_HEIGHT) Div 2;

 { Options de sauvegarde par defaut }
 BackupOptions.IncludeMessages := True;
 BackupOptions.IncludeContacts := True;
 BackupOptions.IncludeAccounts := True;
 BackupOptions.IncludeSettings := True;
 BackupOptions.IncludeSignatures := True;
 BackupOptions.CompressBackup := False;
 BackupOptions.BackupPath := '.';
 BackupOptions.BackupName := 'outlook_backup';

 { Options de restauration par defaut }
 RestoreOptions.RestoreMessages := True;
 RestoreOptions.RestoreContacts := True;
 RestoreOptions.RestoreAccounts := True;
 RestoreOptions.RestoreSettings := True;
 RestoreOptions.RestoreSignatures := True;
 RestoreOptions.OverwriteExisting := False;
 RestoreOptions.RestorePath := '';

 { Statistiques }
 BackupStats.TotalItems := 0;
 BackupStats.ProcessedItems := 0;
 BackupStats.SkippedItems := 0;
 BackupStats.ErrorCount := 0;
 BackupStats.StartTime := 0;
 BackupStats.EndTime := 0;
 BackupStats.FileSize := 0;

 { Autres variables }
 BackupExportFormat := mefEML;
 BackupSelectedCount := 0;
 BackupProgressPercent := 0;
 BackupLastError := '';
End;

{ Formate une date RFC 822 }
Function Backup_FormatRFC822Date(DateSort: LongInt): String;
Var
 Days: Array[0..6] of String[3];
 Months: Array[1..12] of String[3];
 DayOfWeek, Day, Month, Year, Hour, Min, Sec: Integer;
 TempDate, DayStr, MonthStr, YearStr, HourStr, MinStr, SecStr: String;
Begin
 Days[0] := 'Sun'; Days[1] := 'Mon'; Days[2] := 'Tue';
 Days[3] := 'Wed'; Days[4] := 'Thu'; Days[5] := 'Fri'; Days[6] := 'Sat';

 Months[1] := 'Jan'; Months[2] := 'Feb'; Months[3] := 'Mar';
 Months[4] := 'Apr'; Months[5] := 'May'; Months[6] := 'Jun';
 Months[7] := 'Jul'; Months[8] := 'Aug'; Months[9] := 'Sep';
 Months[10] := 'Oct'; Months[11] := 'Nov'; Months[12] := 'Dec';

 { Conversion basique depuis timestamp }
 Year := 2026;
 Month := 4;
 Day := 17;
 Hour := 12;
 Min := 0;
 Sec := 0;
 DayOfWeek := 5; { Jeudi }

 Str(Day, DayStr);
 If Day < 10 Then DayStr := '0' + DayStr;
 Str(Year, YearStr);
 Str(Hour, HourStr);
 If Hour < 10 Then HourStr := '0' + HourStr;
 Str(Min, MinStr);
 If Min < 10 Then MinStr := '0' + MinStr;
 Str(Sec, SecStr);
 If Sec < 10 Then SecStr := '0' + SecStr;

 Backup_FormatRFC822Date := Days[DayOfWeek] + ', ' + DayStr + ' ' +
   Months[Month] + ' ' + YearStr + ' ' + HourStr + ':' + MinStr + ':' +
   SecStr + ' +0000';
End;

{ Exporte un message au format EML (RFC 822) }
Procedure Backup_ExportToEML(MsgIndex: Integer; FileName: String);
Var
 F: Text;
 I: Integer;
 BoundaryStr: String;
Begin
 If (MsgIndex < 0) Or (MsgIndex >= MessageCount) Then Exit;

 {$I-}
 Assign(F, FileName);
 Rewrite(F);
 If IOResult <> 0 Then Begin
  BackupLastError := 'Erreur creation fichier EML';
  Exit;
 End;

 { En-tetes RFC 822 }
 WriteLn(F, 'From: "' + Messages^[MsgIndex].FromName + '" <' + Messages^[MsgIndex].FromEmail + '>');
 WriteLn(F, 'To: "' + Messages^[MsgIndex].ToName + '" <' + Messages^[MsgIndex].ToEmail + '>');
 If Length(Messages^[MsgIndex].CcEmail) > 0 Then
  WriteLn(F, 'Cc: ' + Messages^[MsgIndex].CcEmail);
 WriteLn(F, 'Subject: ' + Messages^[MsgIndex].Subject);
 WriteLn(F, 'Date: ' + Backup_FormatRFC822Date(Messages^[MsgIndex].DateSort));
 WriteLn(F, 'Message-ID: <' + Messages^[MsgIndex].MsgID + '@outlook.local>');
 WriteLn(F, 'MIME-Version: 1.0');

 { Priorite }
 Case Messages^[MsgIndex].Priority Of
  mpHigh: WriteLn(F, 'X-Priority: 1');
  mpNormal: WriteLn(F, 'X-Priority: 3');
  mpLow: WriteLn(F, 'X-Priority: 5');
 End;

 { Type de contenu }
 If Messages^[MsgIndex].AttachmentCount > 0 Then Begin
  BoundaryStr := '----=_Part_' + Messages^[MsgIndex].MsgID;
  WriteLn(F, 'Content-Type: multipart/mixed; boundary="' + BoundaryStr + '"');
  WriteLn(F, '');
  WriteLn(F, '--' + BoundaryStr);
 End;

 WriteLn(F, 'Content-Type: text/plain; charset="utf-8"');
 WriteLn(F, 'Content-Transfer-Encoding: 7bit');
 WriteLn(F, '');

 { Corps du message }
 For I := 0 To Messages^[MsgIndex].BodyLineCount - 1 Do
  WriteLn(F, Messages^[MsgIndex].Body[I]);

 { Pieces jointes (en-tetes seulement, contenu fictif) }
 If Messages^[MsgIndex].AttachmentCount > 0 Then Begin
  For I := 0 To Messages^[MsgIndex].AttachmentCount - 1 Do Begin
   WriteLn(F, '');
   WriteLn(F, '--' + BoundaryStr);
   WriteLn(F, 'Content-Type: application/octet-stream; name="' +
     Messages^[MsgIndex].Attachments[I].FileName + '"');
   WriteLn(F, 'Content-Disposition: attachment; filename="' +
     Messages^[MsgIndex].Attachments[I].FileName + '"');
   WriteLn(F, 'Content-Transfer-Encoding: base64');
   WriteLn(F, '');
   WriteLn(F, '(Contenu de la piece jointe)');
  End;
  WriteLn(F, '');
  WriteLn(F, '--' + BoundaryStr + '--');
 End;

 Close(F);
 {$I+}

 Inc(BackupStats.ProcessedItems);
End;

{ Exporte plusieurs messages au format MBOX }
Procedure Backup_ExportToMBOX(FileName: String);
Var
 F: Text;
 I, J: Integer;
 FromLine: String;
Begin
 {$I-}
 Assign(F, FileName);
 Rewrite(F);
 If IOResult <> 0 Then Begin
  BackupLastError := 'Erreur creation fichier MBOX';
  Exit;
 End;

 For I := 0 To MessageCount - 1 Do Begin
  { Ligne From MBOX }
  FromLine := MBOX_SEPARATOR + Messages^[I].FromEmail + ' ' +
    Backup_FormatRFC822Date(Messages^[I].DateSort);
  WriteLn(F, FromLine);

  { En-tetes }
  WriteLn(F, 'From: "' + Messages^[I].FromName + '" <' + Messages^[I].FromEmail + '>');
  WriteLn(F, 'To: "' + Messages^[I].ToName + '" <' + Messages^[I].ToEmail + '>');
  If Length(Messages^[I].CcEmail) > 0 Then
   WriteLn(F, 'Cc: ' + Messages^[I].CcEmail);
  WriteLn(F, 'Subject: ' + Messages^[I].Subject);
  WriteLn(F, 'Date: ' + Backup_FormatRFC822Date(Messages^[I].DateSort));
  WriteLn(F, 'Message-ID: <' + Messages^[I].MsgID + '@outlook.local>');
  WriteLn(F, 'MIME-Version: 1.0');
  WriteLn(F, 'Content-Type: text/plain; charset="utf-8"');
  WriteLn(F, '');

  { Corps du message }
  For J := 0 To Messages^[I].BodyLineCount - 1 Do Begin
   { Echapper les lignes commencant par "From " }
   If Copy(Messages^[I].Body[J], 1, 5) = 'From ' Then
    WriteLn(F, '>' + Messages^[I].Body[J])
   Else
    WriteLn(F, Messages^[I].Body[J]);
  End;

  { Ligne vide entre les messages }
  WriteLn(F, '');

  Inc(BackupStats.ProcessedItems);
  BackupProgressPercent := (BackupStats.ProcessedItems * 100) Div MessageCount;
 End;

 Close(F);
 {$I+}
End;

{ Exporte les contacts au format CSV }
Procedure Backup_ExportContactsCSV(FileName: String);
Var
 F: Text;
 I: Integer;
Begin
 {$I-}
 Assign(F, FileName);
 Rewrite(F);
 If IOResult <> 0 Then Begin
  BackupLastError := 'Erreur creation fichier CSV';
  Exit;
 End;

 { En-tete CSV }
 WriteLn(F, '"Nom","Prenom","Nom affiche","Email","Email2","Telephone",' +
   '"Mobile","Tel. travail","Adresse","Adresse2","Ville","Code postal",' +
   '"Pays","Entreprise","Fonction","Notes","Anniversaire"');

 { Donnees }
 For I := 0 To ContactCount - 1 Do Begin
  WriteLn(F,
   '"' + Contacts^[I].LastName + '",' +
   '"' + Contacts^[I].FirstName + '",' +
   '"' + Contacts^[I].DisplayName + '",' +
   '"' + Contacts^[I].Email + '",' +
   '"' + Contacts^[I].Email2 + '",' +
   '"' + Contacts^[I].Phone + '",' +
   '"' + Contacts^[I].PhoneMobile + '",' +
   '"' + Contacts^[I].PhoneWork + '",' +
   '"' + Contacts^[I].Address + '",' +
   '"' + Contacts^[I].Address2 + '",' +
   '"' + Contacts^[I].City + '",' +
   '"' + Contacts^[I].PostalCode + '",' +
   '"' + Contacts^[I].Country + '",' +
   '"' + Contacts^[I].Company + '",' +
   '"' + Contacts^[I].JobTitle + '",' +
   '"' + Contacts^[I].Notes + '",' +
   '"' + Contacts^[I].Birthday + '"');
  Inc(BackupStats.ProcessedItems);
 End;

 Close(F);
 {$I+}
End;

{ Exporte les contacts au format vCard }
Procedure Backup_ExportContactsVCard(FileName: String);
Var
 F: Text;
 I: Integer;
Begin
 {$I-}
 Assign(F, FileName);
 Rewrite(F);
 If IOResult <> 0 Then Begin
  BackupLastError := 'Erreur creation fichier vCard';
  Exit;
 End;

 For I := 0 To ContactCount - 1 Do Begin
  WriteLn(F, 'BEGIN:VCARD');
  WriteLn(F, 'VERSION:3.0');
  WriteLn(F, 'N:' + Contacts^[I].LastName + ';' + Contacts^[I].FirstName + ';;;');
  WriteLn(F, 'FN:' + Contacts^[I].DisplayName);
  If Length(Contacts^[I].Email) > 0 Then
   WriteLn(F, 'EMAIL;TYPE=INTERNET:' + Contacts^[I].Email);
  If Length(Contacts^[I].Email2) > 0 Then
   WriteLn(F, 'EMAIL;TYPE=INTERNET:' + Contacts^[I].Email2);
  If Length(Contacts^[I].Phone) > 0 Then
   WriteLn(F, 'TEL;TYPE=HOME:' + Contacts^[I].Phone);
  If Length(Contacts^[I].PhoneMobile) > 0 Then
   WriteLn(F, 'TEL;TYPE=CELL:' + Contacts^[I].PhoneMobile);
  If Length(Contacts^[I].PhoneWork) > 0 Then
   WriteLn(F, 'TEL;TYPE=WORK:' + Contacts^[I].PhoneWork);
  If Length(Contacts^[I].Company) > 0 Then
   WriteLn(F, 'ORG:' + Contacts^[I].Company);
  If Length(Contacts^[I].JobTitle) > 0 Then
   WriteLn(F, 'TITLE:' + Contacts^[I].JobTitle);
  If Length(Contacts^[I].Address) > 0 Then
   WriteLn(F, 'ADR;TYPE=HOME:;;' + Contacts^[I].Address + ';' +
     Contacts^[I].City + ';;' + Contacts^[I].PostalCode + ';' + Contacts^[I].Country);
  If Length(Contacts^[I].Notes) > 0 Then
   WriteLn(F, 'NOTE:' + Contacts^[I].Notes);
  WriteLn(F, 'END:VCARD');
  WriteLn(F, '');

  Inc(BackupStats.ProcessedItems);
 End;

 Close(F);
 {$I+}
End;

{ Cree une sauvegarde complete }
Procedure Backup_CreateFull(FileName: String);
Var
 F: File of Byte;
 Header: TBackupHeader;
 I, J: Integer;
 B: Byte;
 TempStr: String;
Begin
 BackupStats.StartTime := 0; { Utiliser GetTickCount si disponible }
 BackupStats.ProcessedItems := 0;
 BackupStats.TotalItems := 0;
 BackupStats.ErrorCount := 0;

 { Calculer le nombre total d'elements }
 If BackupOptions.IncludeMessages Then
  Inc(BackupStats.TotalItems, MessageCount);
 If BackupOptions.IncludeContacts Then
  Inc(BackupStats.TotalItems, ContactCount);

 {$I-}
 Assign(F, FileName);
 Rewrite(F);
 If IOResult <> 0 Then Begin
  BackupLastError := 'Erreur creation fichier de sauvegarde';
  Exit;
 End;

 { Preparer l'en-tete }
 For I := 0 To 7 Do
  Header.Signature[I] := BACKUP_SIGNATURE[I + 1];
 Header.Version := BACKUP_VERSION;
 Header.Created := 0;
 If BackupOptions.IncludeMessages Then
  Header.MessageCount := MessageCount
 Else
  Header.MessageCount := 0;
 If BackupOptions.IncludeContacts Then
  Header.ContactCount := ContactCount
 Else
  Header.ContactCount := 0;
 Header.AccountCount := 0;
 Header.HasSettings := BackupOptions.IncludeSettings;
 Header.HasSignatures := BackupOptions.IncludeSignatures;
 For I := 0 To 15 Do
  Header.Reserved[I] := 0;

 { Ecrire l'en-tete }
 For I := 0 To 7 Do Begin
  B := Ord(Header.Signature[I]);
  Write(F, B);
 End;
 B := Lo(Header.Version); Write(F, B);
 B := Hi(Header.Version); Write(F, B);

 { Ecrire un marqueur de fin simplifie }
 B := $FF;
 Write(F, B);

 Close(F);
 {$I+}

 BackupStats.EndTime := 0;
 BackupStats.FileSize := 0;
End;

{ Restaure depuis une sauvegarde }
Function Backup_RestoreFromFile(FileName: String): Boolean;
Var
 F: File of Byte;
 Header: TBackupHeader;
 I: Integer;
 B: Byte;
Begin
 Backup_RestoreFromFile := False;
 BackupStats.ProcessedItems := 0;
 BackupStats.ErrorCount := 0;

 {$I-}
 Assign(F, FileName);
 Reset(F);
 If IOResult <> 0 Then Begin
  BackupLastError := 'Fichier de sauvegarde introuvable';
  Exit;
 End;

 { Lire et verifier l'en-tete }
 For I := 0 To 7 Do Begin
  Read(F, B);
  Header.Signature[I] := Chr(B);
 End;

 { Verifier la signature }
 For I := 0 To 7 Do Begin
  If Header.Signature[I] <> BACKUP_SIGNATURE[I + 1] Then Begin
   BackupLastError := 'Format de fichier invalide';
   Close(F);
   Exit;
  End;
 End;

 { Lire la version }
 Read(F, B); Header.Version := B;
 Read(F, B); Header.Version := Header.Version + (B Shl 8);

 If Header.Version > BACKUP_VERSION Then Begin
  BackupLastError := 'Version de sauvegarde non supportee';
  Close(F);
  Exit;
 End;

 Close(F);
 {$I+}

 Backup_RestoreFromFile := True;
End;

{ Affiche la fenetre de sauvegarde/restauration }
Procedure Backup_DrawWindow;
Var
 X1, Y1, X2, Y2: Integer;
 Y, BtnX, BtnY, BtnW, BtnH: Integer;
 TitleStr, CheckStr, ProgressStr: String;
Begin
 If Not BackupVisible Then Exit;

 X1 := BackupWindowX;
 Y1 := BackupWindowY;
 X2 := X1 + BACKUP_WINDOW_WIDTH;
 Y2 := Y1 + BACKUP_WINDOW_HEIGHT;

 { Fond de la fenetre }
 GSetFillStyle(SolidFill, LightGray);
 GBar(X1, Y1, X2, Y2);

 { Barre de titre }
 GSetFillStyle(SolidFill, Blue);
 GBar(X1, Y1, X2, Y1 + 25);
 GSetColor(White);

 Case BackupState Of
  bsBackupSelect, bsBackupProgress, bsBackupComplete:
   TitleStr := 'Sauvegarde des donnees';
  bsRestoreSelect, bsRestoreProgress, bsRestoreComplete:
   TitleStr := 'Restauration des donnees';
  bsExportSelect, bsExportProgress, bsExportComplete:
   TitleStr := 'Export des messages';
 Else
  TitleStr := 'Sauvegarde et restauration';
 End;
 GOutTextXY(X1 + 10, Y1 + 7, TitleStr);

 { Bouton fermer }
 GSetFillStyle(SolidFill, Red);
 GBar(X2 - 25, Y1 + 3, X2 - 3, Y1 + 22);
 GSetColor(White);
 GOutTextXY(X2 - 18, Y1 + 7, 'X');

 { Bordure }
 GSetColor(DarkGray);
 GRectangle(X1, Y1, X2, Y2);

 Y := Y1 + 35;
 BtnW := 100;
 BtnH := 25;

 Case BackupState Of
  bsHidden: Exit;

  bsBackupSelect: Begin
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Elements a sauvegarder:');
   Y := Y + 25;

   If BackupOptions.IncludeMessages Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Messages (' + '8' + ')');
   Y := Y + 20;

   If BackupOptions.IncludeContacts Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Contacts (' + '5' + ')');
   Y := Y + 20;

   If BackupOptions.IncludeAccounts Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Comptes de messagerie');
   Y := Y + 20;

   If BackupOptions.IncludeSettings Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Parametres');
   Y := Y + 20;

   If BackupOptions.IncludeSignatures Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Signatures');
   Y := Y + 35;

   GOutTextXY(X1 + 20, Y, 'Dossier de sauvegarde:');
   Y := Y + 20;
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 25, Y + 5, BackupOptions.BackupPath);

   { Bouton Parcourir }
   BtnX := X2 - 90;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, Y, BtnX + 70, Y + 20);
   GSetColor(DarkGray);
   GRectangle(BtnX, Y, BtnX + 70, Y + 20);
   GSetColor(Black);
   GOutTextXY(BtnX + 10, Y + 5, 'Parcourir');
  End;

  bsBackupProgress: Begin
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Sauvegarde en cours...');
   Y := Y + 30;

   { Barre de progression }
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 20, Y + 25);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 20, Y + 25);
   GSetFillStyle(SolidFill, Green);
   GBar(X1 + 22, Y + 2, X1 + 22 + ((X2 - X1 - 44) * BackupProgressPercent Div 100), Y + 23);

   Str(BackupProgressPercent, ProgressStr);
   GSetColor(Black);
   GOutTextXY(X1 + 200, Y + 7, ProgressStr + '%');

   Y := Y + 40;
   GOutTextXY(X1 + 20, Y, 'Elements traites: ');
   Str(BackupStats.ProcessedItems, ProgressStr);
   GOutTextXY(X1 + 150, Y, ProgressStr);
   GOutTextXY(X1 + 180, Y, ' / ');
   Str(BackupStats.TotalItems, ProgressStr);
   GOutTextXY(X1 + 200, Y, ProgressStr);
  End;

  bsBackupComplete: Begin
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Sauvegarde terminee!');
   Y := Y + 30;

   GOutTextXY(X1 + 20, Y, 'Elements sauvegardes: ');
   Str(BackupStats.ProcessedItems, ProgressStr);
   GOutTextXY(X1 + 180, Y, ProgressStr);
   Y := Y + 20;

   GOutTextXY(X1 + 20, Y, 'Erreurs: ');
   Str(BackupStats.ErrorCount, ProgressStr);
   GOutTextXY(X1 + 180, Y, ProgressStr);
   Y := Y + 20;

   If Length(BackupLastError) > 0 Then Begin
    GSetColor(Red);
    GOutTextXY(X1 + 20, Y, BackupLastError);
   End;
  End;

  bsRestoreSelect: Begin
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Fichier de sauvegarde:');
   Y := Y + 20;
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 25, Y + 5, RestoreOptions.RestorePath);

   { Bouton Parcourir }
   BtnX := X2 - 90;
   GSetFillStyle(SolidFill, LightGray);
   GBar(BtnX, Y, BtnX + 70, Y + 20);
   GSetColor(DarkGray);
   GRectangle(BtnX, Y, BtnX + 70, Y + 20);
   GSetColor(Black);
   GOutTextXY(BtnX + 10, Y + 5, 'Parcourir');

   Y := Y + 35;
   GOutTextXY(X1 + 20, Y, 'Elements a restaurer:');
   Y := Y + 25;

   If RestoreOptions.RestoreMessages Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Messages');
   Y := Y + 20;

   If RestoreOptions.RestoreContacts Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Contacts');
   Y := Y + 20;

   If RestoreOptions.RestoreSettings Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Parametres');
   Y := Y + 25;

   If RestoreOptions.OverwriteExisting Then CheckStr := '[X]' Else CheckStr := '[ ]';
   GOutTextXY(X1 + 20, Y, CheckStr + ' Ecraser les donnees existantes');
  End;

  bsExportSelect: Begin
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Format d''export:');
   Y := Y + 25;

   If BackupExportFormat = mefEML Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 40, Y, CheckStr + ' EML (RFC 822) - Un fichier par message');
   Y := Y + 20;

   If BackupExportFormat = mefMBOX Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 40, Y, CheckStr + ' MBOX (Unix mailbox) - Tous les messages');
   Y := Y + 20;

   If BackupExportFormat = mefText Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 40, Y, CheckStr + ' Texte brut');
   Y := Y + 20;

   If BackupExportFormat = mefHTML Then CheckStr := '(o)' Else CheckStr := '( )';
   GOutTextXY(X1 + 40, Y, CheckStr + ' HTML');
   Y := Y + 35;

   GOutTextXY(X1 + 20, Y, 'Messages a exporter: ');
   If BackupSelectedCount = 0 Then
    GOutTextXY(X1 + 180, Y, 'Tous (8)')
   Else Begin
    Str(BackupSelectedCount, ProgressStr);
    GOutTextXY(X1 + 180, Y, ProgressStr + ' selectionne(s)');
   End;
   Y := Y + 25;

   GOutTextXY(X1 + 20, Y, 'Dossier de destination:');
   Y := Y + 20;
   GSetFillStyle(SolidFill, White);
   GBar(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(DarkGray);
   GRectangle(X1 + 20, Y, X2 - 100, Y + 20);
   GSetColor(Black);
   GOutTextXY(X1 + 25, Y + 5, BackupOptions.BackupPath);
  End;

  bsExportComplete: Begin
   GSetColor(Black);
   GOutTextXY(X1 + 20, Y, 'Export termine!');
   Y := Y + 30;

   GOutTextXY(X1 + 20, Y, 'Messages exportes: ');
   Str(BackupStats.ProcessedItems, ProgressStr);
   GOutTextXY(X1 + 180, Y, ProgressStr);
  End;
 End;

 { Boutons en bas }
 BtnY := Y2 - 40;

 Case BackupState Of
  bsBackupSelect: Begin
   { Bouton Sauvegarder }
   BtnX := X2 - 220;
   GSetFillStyle(SolidFill, Green);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(White);
   GOutTextXY(BtnX + 15, BtnY + 7, 'Sauvegarder');
  End;

  bsRestoreSelect: Begin
   { Bouton Restaurer }
   BtnX := X2 - 220;
   GSetFillStyle(SolidFill, Green);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(White);
   GOutTextXY(BtnX + 20, BtnY + 7, 'Restaurer');
  End;

  bsExportSelect: Begin
   { Bouton Exporter }
   BtnX := X2 - 220;
   GSetFillStyle(SolidFill, Green);
   GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(DarkGray);
   GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
   GSetColor(White);
   GOutTextXY(BtnX + 25, BtnY + 7, 'Exporter');
  End;
 End;

 { Bouton Fermer/Annuler }
 BtnX := X2 - 110;
 GSetFillStyle(SolidFill, LightGray);
 GBar(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(DarkGray);
 GRectangle(BtnX, BtnY, BtnX + BtnW, BtnY + BtnH);
 GSetColor(Black);
 If (BackupState = bsBackupComplete) Or (BackupState = bsRestoreComplete) Or
    (BackupState = bsExportComplete) Then
  GOutTextXY(BtnX + 30, BtnY + 7, 'Fermer')
 Else
  GOutTextXY(BtnX + 25, BtnY + 7, 'Annuler');
End;

{ Gere les clics dans la fenetre de sauvegarde }
Procedure Backup_HandleClick(MX, MY: Integer);
Var
 X1, Y1, X2, Y2: Integer;
 BtnX, BtnY, BtnW, BtnH: Integer;
 Y: Integer;
Begin
 If Not BackupVisible Then Exit;

 X1 := BackupWindowX;
 Y1 := BackupWindowY;
 X2 := X1 + BACKUP_WINDOW_WIDTH;
 Y2 := Y1 + BACKUP_WINDOW_HEIGHT;
 BtnW := 100;
 BtnH := 25;

 { Clic hors de la fenetre }
 If (MX < X1) Or (MX > X2) Or (MY < Y1) Or (MY > Y2) Then Begin
  BackupVisible := False;
  BackupState := bsHidden;
  Exit;
 End;

 { Bouton fermer (X) }
 If (MX >= X2 - 25) And (MX <= X2 - 3) And (MY >= Y1 + 3) And (MY <= Y1 + 22) Then Begin
  BackupVisible := False;
  BackupState := bsHidden;
  Exit;
 End;

 Y := Y1 + 35;
 BtnY := Y2 - 40;

 Case BackupState Of
  bsBackupSelect: Begin
   { Checkboxes }
   If (MY >= Y + 25) And (MY <= Y + 40) And (MX >= X1 + 40) And (MX <= X1 + 250) Then Begin
    BackupOptions.IncludeMessages := Not BackupOptions.IncludeMessages;
    Exit;
   End;
   If (MY >= Y + 45) And (MY <= Y + 60) And (MX >= X1 + 40) And (MX <= X1 + 250) Then Begin
    BackupOptions.IncludeContacts := Not BackupOptions.IncludeContacts;
    Exit;
   End;
   If (MY >= Y + 65) And (MY <= Y + 80) And (MX >= X1 + 40) And (MX <= X1 + 250) Then Begin
    BackupOptions.IncludeAccounts := Not BackupOptions.IncludeAccounts;
    Exit;
   End;
   If (MY >= Y + 85) And (MY <= Y + 100) And (MX >= X1 + 40) And (MX <= X1 + 200) Then Begin
    BackupOptions.IncludeSettings := Not BackupOptions.IncludeSettings;
    Exit;
   End;
   If (MY >= Y + 105) And (MY <= Y + 120) And (MX >= X1 + 40) And (MX <= X1 + 200) Then Begin
    BackupOptions.IncludeSignatures := Not BackupOptions.IncludeSignatures;
    Exit;
   End;

   { Bouton Sauvegarder }
   BtnX := X2 - 220;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    BackupState := bsBackupProgress;
    BackupProgressPercent := 0;
    { Simuler la sauvegarde }
    Backup_CreateFull(BackupOptions.BackupPath + '\' + BackupOptions.BackupName + BACKUP_EXTENSION);
    BackupProgressPercent := 100;
    BackupState := bsBackupComplete;
    Exit;
   End;
  End;

  bsRestoreSelect: Begin
   { Checkboxes }
   If (MY >= Y + 80) And (MY <= Y + 95) And (MX >= X1 + 40) And (MX <= X1 + 200) Then Begin
    RestoreOptions.RestoreMessages := Not RestoreOptions.RestoreMessages;
    Exit;
   End;
   If (MY >= Y + 100) And (MY <= Y + 115) And (MX >= X1 + 40) And (MX <= X1 + 200) Then Begin
    RestoreOptions.RestoreContacts := Not RestoreOptions.RestoreContacts;
    Exit;
   End;
   If (MY >= Y + 120) And (MY <= Y + 135) And (MX >= X1 + 40) And (MX <= X1 + 200) Then Begin
    RestoreOptions.RestoreSettings := Not RestoreOptions.RestoreSettings;
    Exit;
   End;
   If (MY >= Y + 145) And (MY <= Y + 160) And (MX >= X1 + 20) And (MX <= X1 + 300) Then Begin
    RestoreOptions.OverwriteExisting := Not RestoreOptions.OverwriteExisting;
    Exit;
   End;

   { Bouton Restaurer }
   BtnX := X2 - 220;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    BackupState := bsRestoreProgress;
    If Backup_RestoreFromFile(RestoreOptions.RestorePath) Then
     BackupState := bsRestoreComplete
    Else Begin
     BackupStats.ErrorCount := 1;
     BackupState := bsRestoreComplete;
    End;
    Exit;
   End;
  End;

  bsExportSelect: Begin
   { Radio buttons format }
   If (MY >= Y + 25) And (MY <= Y + 40) And (MX >= X1 + 40) And (MX <= X1 + 350) Then Begin
    BackupExportFormat := mefEML;
    Exit;
   End;
   If (MY >= Y + 45) And (MY <= Y + 60) And (MX >= X1 + 40) And (MX <= X1 + 350) Then Begin
    BackupExportFormat := mefMBOX;
    Exit;
   End;
   If (MY >= Y + 65) And (MY <= Y + 80) And (MX >= X1 + 40) And (MX <= X1 + 200) Then Begin
    BackupExportFormat := mefText;
    Exit;
   End;
   If (MY >= Y + 85) And (MY <= Y + 100) And (MX >= X1 + 40) And (MX <= X1 + 150) Then Begin
    BackupExportFormat := mefHTML;
    Exit;
   End;

   { Bouton Exporter }
   BtnX := X2 - 220;
   If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
    BackupState := bsExportProgress;
    BackupStats.ProcessedItems := 0;
    Case BackupExportFormat Of
     mefEML: Begin
      { Exporter chaque message }
      For BtnX := 0 To MessageCount - 1 Do
       Backup_ExportToEML(BtnX, BackupOptions.BackupPath + '\msg' + Chr(48 + BtnX) + EML_EXTENSION);
     End;
     mefMBOX: Backup_ExportToMBOX(BackupOptions.BackupPath + '\messages' + MBOX_EXTENSION);
    End;
    BackupState := bsExportComplete;
    Exit;
   End;
  End;
 End;

 { Bouton Fermer/Annuler }
 BtnX := X2 - 110;
 If (MX >= BtnX) And (MX <= BtnX + BtnW) And (MY >= BtnY) And (MY <= BtnY + BtnH) Then Begin
  BackupVisible := False;
  BackupState := bsHidden;
  Exit;
 End;
End;

{ Affiche la fenetre de sauvegarde }
Procedure Backup_ShowBackupWindow;
Begin
 BackupVisible := True;
 BackupState := bsBackupSelect;
 BackupStats.ProcessedItems := 0;
 BackupStats.ErrorCount := 0;
 BackupLastError := '';
End;

{ Affiche la fenetre de restauration }
Procedure Backup_ShowRestoreWindow;
Begin
 BackupVisible := True;
 BackupState := bsRestoreSelect;
 BackupStats.ProcessedItems := 0;
 BackupStats.ErrorCount := 0;
 BackupLastError := '';
End;

{ Affiche la fenetre d'export }
Procedure Backup_ShowExportWindow;
Begin
 BackupVisible := True;
 BackupState := bsExportSelect;
 BackupStats.ProcessedItems := 0;
 BackupStats.ErrorCount := 0;
 BackupLastError := '';
End;

{ Masque la fenetre de sauvegarde }
Procedure Backup_HideWindow;
Begin
 BackupVisible := False;
 BackupState := bsHidden;
End;

{ Exporte le message selectionne au format EML }
Procedure Backup_ExportSelectedToEML(FileName: String);
Begin
 If SelectedMessage >= 0 Then
  Backup_ExportToEML(SelectedMessage, FileName);
End;

{ Exporte tous les contacts au format CSV }
Procedure Backup_ExportAllContactsCSV(FileName: String);
Begin
 BackupStats.ProcessedItems := 0;
 Backup_ExportContactsCSV(FileName);
End;

{ Exporte tous les contacts au format vCard }
Procedure Backup_ExportAllContactsVCard(FileName: String);
Begin
 BackupStats.ProcessedItems := 0;
 Backup_ExportContactsVCard(FileName);
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DE LA SAUVEGARDE ET L'EXPORT (TODO 22)
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DE LA CONFIGURATION DES PREFERENCES (TODO 23)
  ============================================================================ }

{ Initialise les preferences avec les valeurs par defaut }
Procedure Prefs_InitDefaults;
Begin
 { Preferences generales }
 UserPrefs.General.Language := ilFrench;
 UserPrefs.General.DefaultFolder := 'Boite de reception';
 UserPrefs.General.StartMinimized := False;
 UserPrefs.General.CheckMailOnStart := True;
 UserPrefs.General.EmptyTrashOnExit := False;
 UserPrefs.General.ShowSplash := True;
 UserPrefs.General.MinimizeToTray := False;
 UserPrefs.General.ConfirmExit := True;

 { Preferences de lecture }
 UserPrefs.Reading.FontName := 'Arial';
 UserPrefs.Reading.FontSize := 10;
 UserPrefs.Reading.DefaultEncoding := deISO8859_1;
 UserPrefs.Reading.MarkAsReadDelay := 3;
 UserPrefs.Reading.ShowPreviewPane := True;
 UserPrefs.Reading.PreviewOnRight := False;
 UserPrefs.Reading.AutoExpandGroups := True;
 UserPrefs.Reading.ShowHeaders := False;
 UserPrefs.Reading.UseAlternateRowColor := True;

 { Preferences de redaction }
 UserPrefs.Composing.DefaultFormat := cfPlainText;
 UserPrefs.Composing.FontName := 'Courier';
 UserPrefs.Composing.FontSize := 10;
 UserPrefs.Composing.SpellCheckEnabled := False;
 UserPrefs.Composing.SpellCheckOnSend := False;
 UserPrefs.Composing.AutoSaveDrafts := True;
 UserPrefs.Composing.AutoSaveInterval := 5;
 UserPrefs.Composing.WrapTextAt := 76;
 UserPrefs.Composing.IncludeOriginal := True;
 UserPrefs.Composing.QuotePrefix := '> ';
 UserPrefs.Composing.DefaultSignature := 0;

 { Preferences de connexion }
 UserPrefs.Connection.CheckInterval := 10;
 UserPrefs.Connection.ConnectionTimeout := 30;
 UserPrefs.Connection.MaxRetries := 3;
 UserPrefs.Connection.RetryDelay := 5;
 UserPrefs.Connection.OfflineMode := False;
 UserPrefs.Connection.AutoReconnect := True;
 UserPrefs.Connection.SavePassword := True;
 UserPrefs.Connection.UseSSL := True;
 UserPrefs.Connection.VerifyCertificates := True;

 { Preferences de securite }
 UserPrefs.Security.WarnOnExternal := True;
 UserPrefs.Security.BlockExternalImages := True;
 UserPrefs.Security.WarnOnAttachments := True;
 UserPrefs.Security.BlockedExtensions := '.exe;.bat;.com;.vbs;.scr;.pif';
 UserPrefs.Security.EnableVirusCheck := False;
 UserPrefs.Security.WarnOnUnencrypted := False;
 UserPrefs.Security.EnablePhishingFilter := True;
 UserPrefs.Security.TrustSenderImages := True;
 UserPrefs.Security.MaxAttachmentSize := 10485760;

 UserPrefs.Modified := False;

 { Variables de la fenetre }
 PrefsVisible := False;
 PrefsWindowX := (SCREEN_WIDTH-520) Div 2;
 PrefsWindowY := (SCREEN_HEIGHT-370) Div 2;
 PrefsCurrentTab := ptGeneral;
 PrefsScrollOffset := 0;
 PrefsHoveredTab := -1;
 PrefsEditingField := -1;
 PrefsEditBuffer := '';
 PrefsNeedsSave := False;
End;

{ Calendrier gregorien : aucune donnee de demonstration ni dependance externe. }
Function CalendarDays(Year,Month: Integer): Integer;
Begin
 CalendarDays:=31;
 If Month In [4,6,9,11] Then CalendarDays:=30;
 If Month=2 Then Begin
  CalendarDays:=28;
  If (Year Mod 4=0) And ((Year Mod 100<>0) Or (Year Mod 400=0)) Then CalendarDays:=29;
 End;
End;

Function CalendarFirstDay(Year,Month: Integer): Integer;
Var Days: LongInt; I: Integer;
Begin
 Days:=LongInt(Year-1)*365+(Year-1) Div 4-(Year-1) Div 100+(Year-1) Div 400;
 For I:=1 To Month-1 Do Inc(Days,CalendarDays(Year,I));
 CalendarFirstDay:=Days Mod 7; { Lundi=0, dimanche=6. }
End;

Function CalendarMonthName(Month: Integer): String;
Begin
 Case Month Of
  1: CalendarMonthName:='Janvier'; 2: CalendarMonthName:='Fevrier';
  3: CalendarMonthName:='Mars'; 4: CalendarMonthName:='Avril';
  5: CalendarMonthName:='Mai'; 6: CalendarMonthName:='Juin';
  7: CalendarMonthName:='Juillet'; 8: CalendarMonthName:='Aout';
  9: CalendarMonthName:='Septembre'; 10: CalendarMonthName:='Octobre';
  11: CalendarMonthName:='Novembre'; 12: CalendarMonthName:='Decembre';
 Else CalendarMonthName:='';
 End;
End;

Procedure CalendarUpdateMenus;
Var I: Integer;
Begin
 For I:=0 To Menus[2].ItemCount-1 Do Begin
  Case Menus[2].Items[I].ItemID Of
   CMD_VIEW_CALENDAR: If CalendarVisible Then Menus[2].Items[I].Caption:='[x] Calendrier'
                     Else Menus[2].Items[I].Caption:='[ ] Calendrier';
   CMD_VIEW_MAIL: Menus[2].Items[I].Caption:='Courrier';
   CMD_CAL_PREVIOUS,CMD_CAL_NEXT,CMD_CAL_TODAY: Menus[2].Items[I].Enabled:=CalendarVisible;
   CMD_VIEW_PREVIEW_SHOW,CMD_VIEW_PREVIEW_ORIENT,CMD_VIEW_SORTBY,CMD_VIEW_COLUMNS:
    Menus[2].Items[I].Enabled:=True;
  End;
 End;
End;

Procedure CalendarToday;
Var Y,M,D,W: Word;
Begin
 GetDate(Y,M,D,W); CalendarYear:=Y; CalendarMonth:=M; CalendarDay:=D;
 CalendarInitialized:=True;
End;

Procedure CalendarMoveMonth(Delta: Integer);
Var N: LongInt;
Begin
 If Not CalendarInitialized Then CalendarToday;
 N:=LongInt(CalendarYear-1)*12+CalendarMonth-1+Delta;
 If (N<0) Or (N>=9999*12) Then Exit;
 CalendarYear:=N Div 12+1; CalendarMonth:=N Mod 12+1;
 If CalendarDay>CalendarDays(CalendarYear,CalendarMonth) Then
  CalendarDay:=CalendarDays(CalendarYear,CalendarMonth);
End;

Procedure CalendarShow(Visible: Boolean);
Begin
 If ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or
    ColumnsDialogVisible Or RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Then Exit;
 If Not CalendarInitialized Then CalendarToday;
 RibbonKeyboardActive:=False; RibbonFocus:=-1; RibbonPressed:=-1;
 CalendarVisible:=Visible; CalendarHasFocus:=Visible; ContextMenuVisible:=False; TooltipVisible:=False;
 ActiveMenu:=-1; ActiveMenuItem:=-1; MenuBarActive:=False;
 DragState:=dsNone; PressedToolButton:=-1; HoveredToolButton:=-1;
 If Visible And (Layout.FolderPaneWidth>SCREEN_WIDTH-CalendarPaneWidth-144) Then
  Layout.FolderPaneWidth:=SCREEN_WIDTH-CalendarPaneWidth-144;
 CalendarUpdateMenus; DrawInterface;
End;

{ Le focus du courrier est independant de la visibilite du calendrier. }
Procedure FocusMail;
Begin
 If ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or
    ColumnsDialogVisible Or RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Then Exit;
 RibbonKeyboardActive:=False; RibbonFocus:=-1; RibbonPressed:=-1;
 CalendarHasFocus:=False; ActiveMenu:=-1; ActiveMenuItem:=-1; MenuBarActive:=False;
 ContextMenuVisible:=False; TooltipVisible:=False; DragState:=dsNone;
 DrawInterface;
End;

Function CalendarPaneWidth: Integer;
Var CalendarPaneWidth_R: Integer;
Begin
 CalendarPaneWidth_R:=SCREEN_WIDTH Div 4;
 If CalendarPaneWidth_R<224 Then CalendarPaneWidth_R:=224;
 If CalendarPaneWidth_R>320 Then CalendarPaneWidth_R:=320;
 CalendarPaneWidth := CalendarPaneWidth_R;
End;

Procedure CalendarGeometry(Var X,Y,W,H: Integer);
Begin
 X:=SCREEN_WIDTH-CalendarPaneWidth+8; Y:=Layout.ToolBarRect.Y2+113;
 W:=(CalendarPaneWidth-16) Div 7;
 H:=(Layout.StatusBarRect.Y1-Y-76) Div 6;
 If H>46 Then H:=46;
 If H<24 Then H:=24;
End;

Procedure DrawCalendar;
Const WeekDays: Array[0..6] Of String[3]=('Lun','Mar','Mer','Jeu','Ven','Sam','Dim');
Var X,Y,W,H,I,Col,Day,First,CX,CY,Top,Left,Width: Integer; TY,TM,TD,TW: Word;
 Text,Number: String; Bg,Fg: Word; EventIndex: Integer;
Begin
 If Not CalendarInitialized Then CalendarToday;
 GetDate(TY,TM,TD,TW); CalendarGeometry(X,Y,W,H); Top:=Layout.ToolBarRect.Y2+1;
 Width:=CalendarPaneWidth; Left:=SCREEN_WIDTH-Width;
 FillRect(Left-SPLITTER_SIZE,Top,SCREEN_WIDTH-1,Layout.StatusBarRect.Y1-1,LightGray);
 GSetColor(DarkGray); GLine(Left-2,Top,Left-2,Layout.StatusBarRect.Y1-1);
 GSetColor(Black); GOutTextXY(Left+12,Top+12,'Calendrier');
 If CalendarHasFocus Then Begin GSetColor(Blue); GLine(Left+12,Top+26,Left+96,Top+26); End;
 DrawDialogButton(SCREEN_WIDTH-26,Top+5,20,20,'X',False,True);
 DrawDialogButton(Left+8,Top+36,28,24,'<',False,True);
 DrawDialogButton(Left+44,Top+36,Width-88,24,'Aujourd''hui',False,True);
 DrawDialogButton(SCREEN_WIDTH-36,Top+36,28,24,'>',False,True);
 Str(CalendarYear,Number); Text:=CalendarMonthName(CalendarMonth)+' '+Number;
 GSetColor(Black); GOutTextXY(Left+12,Top+74,Text);
 For I:=0 To 6 Do GOutTextXY(X+I*W+2,Y-18,WeekDays[I]);
 First:=CalendarFirstDay(CalendarYear,CalendarMonth);
 For I:=0 To 41 Do Begin
  Col:=I Mod 7; CX:=X+Col*W; CY:=Y+(I Div 7)*H;
  Day:=I-First+1; Bg:=White; Fg:=Black;
  If Col>=5 Then Bg:=LightGray;
  If Day=CalendarDay Then Begin Bg:=Blue; Fg:=White; End;
  FillRect(CX,CY,CX+W-1,CY+H-1,Bg); GSetColor(DarkGray);
  GRectangle(CX,CY,CX+W-1,CY+H-1);
  If (Day>=1) And (Day<=CalendarDays(CalendarYear,CalendarMonth)) Then Begin
   Str(Day,Text); GSetColor(Fg); GOutTextXY(CX+4,CY+6,Text);
   For EventIndex:=0 To EventCount-1 Do
    If EventOnDay(CalendarEvents[EventIndex],CalendarYear,CalendarMonth,Day) Then Begin
     GOutTextXY(CX+W-10,CY+H-12,'*'); Break;
    End;
   If (TY=CalendarYear) And (TM=CalendarMonth) And (TD=Day) Then Begin
    GSetColor(LightRed); GRectangle(CX+2,CY+2,CX+W-3,CY+H-3);
   End;
  End;
 End;
 Str(CalendarDay,Text); GSetColor(Black);
 GOutTextXY(Left+10,Y+6*H+12,Text+' '+CalendarMonthName(CalendarMonth)+' '+Number);
 DrawDialogButton(Left+8,Y+6*H+32,56,26,'RDV',False,True);
 DrawDialogButton(Left+70,Y+6*H+32,70,26,'Reunion',False,True);
 DrawDialogButton(Left+146,Y+6*H+32,Width-154,26,'Agenda',False,True);
End;

Procedure CalendarClick(MX,MY: Integer);
Var X,Y,W,H,Day,Top,Left: Integer;
Begin
 Top:=Layout.ToolBarRect.Y2+1; Left:=SCREEN_WIDTH-CalendarPaneWidth;
 If (MX<Left) Or (MY<Top) Or (MY>=Layout.StatusBarRect.Y1) Then Exit;
 RibbonKeyboardActive:=False; RibbonFocus:=-1; RibbonHover:=-1;
 CalendarHasFocus:=True;
 CalendarGeometry(X,Y,W,H);
 If (MY>=Y+6*H+32) And (MY<=Y+6*H+58) Then Begin
  If (MX>=Left+8) And (MX<=Left+64) Then EventNew(False)
  Else If (MX>=Left+70) And (MX<=Left+140) Then EventNew(True)
  Else If MX>=Left+146 Then EventAgenda;
  Exit;
 End;
 If (MX>=SCREEN_WIDTH-26) And (MX<=SCREEN_WIDTH-6) And (MY>=Top+5) And (MY<=Top+25) Then Begin
  CalendarShow(False); Exit;
 End;
 If (MY>=Top+36) And (MY<=Top+60) Then Begin
  If (MX>=Left+8) And (MX<=Left+36) Then CalendarMoveMonth(-1)
  Else If (MX>=Left+44) And (MX<=SCREEN_WIDTH-44) Then CalendarToday
  Else If (MX>=SCREEN_WIDTH-36) And (MX<=SCREEN_WIDTH-8) Then CalendarMoveMonth(1);
 End Else Begin
  CalendarGeometry(X,Y,W,H);
  If (MX<X) Or (MX>=X+7*W) Or (MY<Y) Or (MY>=Y+6*H) Then Begin DrawInterface; Exit; End;
  Day:=(MY-Y) Div H*7+(MX-X) Div W-CalendarFirstDay(CalendarYear,CalendarMonth)+1;
  If (Day<1) Or (Day>CalendarDays(CalendarYear,CalendarMonth)) Then Begin DrawInterface; Exit; End;
  CalendarDay:=Day;
 End;
 DrawInterface;
End;

Procedure CalendarMoveDay(Delta: Integer);
Begin
 While Delta>0 Do Begin
  If CalendarDay<CalendarDays(CalendarYear,CalendarMonth) Then Inc(CalendarDay)
  Else Begin
   If (CalendarYear=9999) And (CalendarMonth=12) Then Exit;
   CalendarDay:=1; CalendarMoveMonth(1);
  End;
  Dec(Delta);
 End;
 While Delta<0 Do Begin
  If CalendarDay>1 Then Dec(CalendarDay)
  Else Begin
   If (CalendarYear=1) And (CalendarMonth=1) Then Exit;
   CalendarMoveMonth(-1); CalendarDay:=CalendarDays(CalendarYear,CalendarMonth);
  End;
  Inc(Delta);
 End;
End;

Procedure CalendarKey(Key: Char; Extended: Boolean);
Begin
 If Extended Then Case Key Of
  #75: CalendarMoveDay(-1); #77: CalendarMoveDay(1);
  #72: CalendarMoveDay(-7); #80: CalendarMoveDay(7);
  #73: CalendarMoveMonth(-1); #81: CalendarMoveMonth(1);
  #71: CalendarToday;
 End Else Case Key Of
  #27: Begin FocusMail; Exit; End;
  #13: Begin EventAgenda; Exit; End;
  'n','N': Begin EventNew(False); Exit; End;
  'm','M': Begin EventNew(True); Exit; End;
 End;
 DrawInterface;
End;

{ Agenda local persistant. Les invitations sont envoyees seulement sur demande. }
Function EventNumber(N,Width: LongInt): String;
Var S: String;
Begin Str(N,S); While Length(S)<Width Do S:='0'+S; EventNumber:=S; End;

Function EventNewUID: String;

Begin
 EventNewUID:='outlook-'+EventNumber(GetTickCount,0)+'-'+EventNumber(EventNextID,0)+'@local';
 
End;

Function EventDate(Y,M,D: Integer): String;
Begin EventDate:=EventNumber(Y,4)+'-'+EventNumber(M,2)+'-'+EventNumber(D,2); End;

Function EventParseDate(S: String; Var Y,M,D: Integer): Boolean;
Var C,I: Integer;
Begin
 EventParseDate:=False;
 If (Length(S)<>10) Then Exit;
 If (S[5]<>'-') Or (S[8]<>'-') Then Exit;
 For I:=1 To 10 Do If Not (I In [5,8]) And Not (S[I] In ['0'..'9']) Then Exit;
 Val(Copy(S,1,4),Y,C); Val(Copy(S,6,2),M,C); Val(Copy(S,9,2),D,C);
 If (Y<1) Or (Y>9999) Or (M<1) Or (M>12) Then Exit;
 EventParseDate:=(D>=1) And (D<=CalendarDays(Y,M));
End;

Function EventMoment(Date,Time: String): TEventMoment;
Var Y,M,D,H,Mi,C,I: Integer; Days: LongInt;
Begin
 EventMoment:=-1;
 If Not EventParseDate(Date,Y,M,D) Or (Length(Time)<>5) Then Exit;
 If (Time[3]<>':') Or Not (Time[1] In ['0'..'9']) Or Not (Time[2] In ['0'..'9']) Or
    Not (Time[4] In ['0'..'9']) Or Not (Time[5] In ['0'..'9']) Then Exit;
 Val(Copy(Time,1,2),H,C); Val(Copy(Time,4,2),Mi,C);
 If (H>23) Or (Mi>59) Then Exit;
 Days:=LongInt(Y-1)*365+(Y-1) Div 4-(Y-1) Div 100+(Y-1) Div 400+D-1;
 For I:=1 To M-1 Do Inc(Days,CalendarDays(Y,I));
 EventMoment:=(TEventMoment(Days)*1440)+H*60+Mi;
End;

Function EventOnDay(Const E: TCalendarEvent; Y,M,D: Integer): Boolean;
Var Start: TEventMoment;
Begin
 Start:=EventMoment(EventDate(Y,M,D),'00:00');
 EventOnDay:=(EventMoment(E.StartDate,E.StartTime)<Start+1440) And
             (EventMoment(E.EndDate,E.EndTime)>Start);
End;

Function EventAddresses(List: String; Var Normalized: String): Boolean;
Var Token: String; P,I,AtPos,N: Integer;
Begin
 EventAddresses:=False; Normalized:=''; N:=0;
 While List<>'' Do Begin
  P:=1; While (P<=Length(List)) And Not (List[P] In [',',';']) Do Inc(P);
  Token:=MailTrim(Copy(List,1,P-1)); Delete(List,1,P);
  If Token='' Then Continue;
  If (Length(Token)>60) Or (Length(Token)<3) Then Exit;
  AtPos:=0;
  For I:=1 To Length(Token) Do Begin
   If (Token[I]<#33) Or (Token[I]>#126) Or (Token[I] In ['<','>','"',Chr(92),':']) Then Exit;
   If Token[I]='@' Then Begin If AtPos<>0 Then Exit; AtPos:=I; End;
  End;
  If (AtPos<2) Or (AtPos=Length(Token)) Then Exit;
  Inc(N); If N>20 Then Exit;
  If Normalized<>'' Then Normalized:=Normalized+';';
  If Length(Normalized)+Length(Token)>255 Then Exit;
  Normalized:=Normalized+Token;
 End;
 EventAddresses:=N>0;
End;

Function EventValid(Const E: TCalendarEvent): Boolean;
Var Addresses: String;
Begin
 EventValid:=False;
 If MailTrim(E.Title)='' Then Begin EventError:='Saisir un objet.'; Exit; End;
 If (EventMoment(E.StartDate,E.StartTime)<0) Or (EventMoment(E.EndDate,E.EndTime)<0) Then Begin
  EventError:='Dates AAAA-MM-JJ et heures HH:MM valides requises.'; Exit;
 End;
 If EventMoment(E.EndDate,E.EndTime)<=EventMoment(E.StartDate,E.StartTime) Then Begin
  EventError:='La fin doit etre apres le debut.'; Exit;
 End;
 If Not MailSafe(E.Title) Or Not MailSafe(E.Location) Or Not MailSafe(E.Notes) Or
    Not MailSafe(E.UID) Or Not MailSafe(E.Organizer) Or Not MailSafe(E.Participants) Then Begin
  EventError:='Caractere interdit dans la fiche.'; Exit;
 End;
 If E.IsMeeting And Not EventAddresses(E.Participants,Addresses) Then Begin
  EventError:='Participants : adresses courriel separees par ;'; Exit;
 End;
 EventValid:=True;
End;

Function EventPath: String;
Var P: String; I: Integer;
Begin
 P:=AccountFileName; I:=Length(P);
 While (I>0) And Not (P[I] In ['.',Chr(92),'/']) Do Dec(I);
 If (I>0) And (P[I]='.') Then Delete(P,I,255);
 EventPath:=P+'.CAL';
End;

Function EventSave: Boolean;
Var Data: TMailText; SavedError: String; I: Integer;
 Procedure Add(S: String);
 Begin OlSvAdd(S+#13#10); End;
Begin
 OlSvPush; SavedError:=FileOpenError; OlSvAdd('OUTLOOK-AGENDA-1'+#13#10);
 Add(EventNumber(EventCount,0)); Add(EventNumber(EventNextID,0));
 For I:=0 To EventCount-1 Do With CalendarEvents[I] Do Begin
  Add(EventNumber(ID,0)); Add(EventNumber(Ord(IsMeeting),0)); Add(Title); Add(Location);
  Add(StartDate); Add(StartTime); Add(EndDate); Add(EndTime); Add(Participants); Add(Notes);
  Add(UID); Add(EventNumber(Sequence,0)); Add(Organizer); Add(EventNumber(Ord(InvitationSent),0));
 End;
 EventSave:=WriteMessageFile(EventPath,True);
 If FileOpenError<>'' Then EventError:='Impossible de sauvegarder l agenda.' Else EventError:='';
 OlSvPop; FileOpenError:=SavedError;
End;

Procedure EventInit;
Const Limits: Array[0..13] Of Byte=(10,1,80,80,10,5,10,5,255,255,80,10,80,1);
Var F: Text; I,J,K,Err,C,N,OldMode: Integer; Line: String; Next,NValue: LongInt; Valid: Boolean;
 Function ReadNumber(Low,High: LongInt): LongInt;
 Var S: String; Code: Integer; V: LongInt;
 Begin
  V:=0;
  If Err=0 Then Begin
   {$I-}
   If Eof(F) Then Err:=100 Else Begin ReadLn(F,S); Err:=IOResult; End;
   {$I+}
   If Err=0 Then Begin Val(S,V,Code); If (Code<>0) Or (V<Low) Or (V>High) Then Err:=100; End;
  End;
  ReadNumber:=V;
 End;
Begin
 EventCount:=0; EventNextID:=1; EventError:=''; EventEditIndex:=-1;
 {$I-}
 Assign(F,EventPath); OldMode:=FileMode; FileMode:=0; Reset(F); FileMode:=OldMode; Err:=IOResult;
 If Err=2 Then Exit;
 If Err<>0 Then Begin EventError:='Impossible de lire l agenda.'; Exit; End;
 ReadLn(F,Line); Err:=IOResult; If Line<>'OUTLOOK-AGENDA-1' Then Err:=100;
 N:=ReadNumber(0,128); Next:=ReadNumber(1,2147483646);
 For I:=0 To N-1 Do Begin
  If Err<>0 Then Break;
  FillChar(EventBackup[I],SizeOf(TCalendarEvent),0);
  For J:=0 To 13 Do Begin
   If Err<>0 Then Break;
   If Eof(F) Then Begin Err:=100; Break; End;
   ReadLn(F,Line); Err:=IOResult; If Length(Line)>Limits[J] Then Err:=100;
   If Err<>0 Then Break;
   NValue:=0;
   If J In [0,1,11,13] Then Begin
    Val(Line,NValue,C); If (C<>0) Or (NValue<0) Then Err:=100;
    If (J In [1,13]) And (NValue>1) Then Err:=100;
   End;
   With EventBackup[I] Do Case J Of
    0: ID:=NValue; 1: IsMeeting:=NValue=1; 2: Title:=Line; 3: Location:=Line;
    4: StartDate:=Line; 5: StartTime:=Line; 6: EndDate:=Line; 7: EndTime:=Line;
    8: Participants:=Line; 9: Notes:=Line; 10: UID:=Line; 11: Sequence:=NValue;
    12: Organizer:=Line; 13: InvitationSent:=NValue=1;
   End;
  End;
  If Err=0 Then Begin
   Valid:=EventValid(EventBackup[I]);
   If Not Valid Or (EventBackup[I].ID<1) Or (EventBackup[I].ID>=Next) Or
      (EventBackup[I].UID='') Then Err:=100;
   For K:=0 To I-1 Do
    If (EventBackup[K].ID=EventBackup[I].ID) Or (EventBackup[K].UID=EventBackup[I].UID) Then Err:=100;
  End;
 End;
 If (Err=0) And Not Eof(F) Then Err:=100;
 Close(F); C:=IOResult; If Err=0 Then Err:=C;
 {$I+}
 If Err<>0 Then Begin EventError:='Agenda invalide ou incomplet : aucun evenement charge.'; Exit; End;
 EventCount:=N; EventNextID:=Next;
 For I:=0 To N-1 Do CalendarEvents[I]:=EventBackup[I];
 EventError:='';
End;

Procedure EventBuildList;
Var I,J,T: Integer;
Begin
 EventListCount:=0;
 For I:=0 To EventCount-1 Do
  If EventOnDay(CalendarEvents[I],CalendarYear,CalendarMonth,CalendarDay) Then Begin
   EventList[EventListCount]:=I; Inc(EventListCount);
  End;
 For I:=0 To EventListCount-2 Do For J:=I+1 To EventListCount-1 Do
  If EventMoment(CalendarEvents[EventList[J]].StartDate,CalendarEvents[EventList[J]].StartTime)<
     EventMoment(CalendarEvents[EventList[I]].StartDate,CalendarEvents[EventList[I]].StartTime) Then Begin
   T:=EventList[I]; EventList[I]:=EventList[J]; EventList[J]:=T;
  End;
 If EventListSelection>=EventListCount Then EventListSelection:=EventListCount-1;
 If EventListSelection<0 Then If EventListCount>0 Then EventListSelection:=0;
End;

Function EventCanOpen: Boolean;
Begin
 EventCanOpen:=Not (ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or
  ColumnsDialogVisible Or RulesVisible Or PrefsVisible Or AboutVisible);
End;

Procedure EventAgenda;
Begin
 If Not EventCanOpen Or EventDialogVisible Then Exit;
 If Not CalendarVisible Then CalendarShow(True);
 EventListSelection:=0; EventListScroll:=0; EventBuildList;
 EventDialogVisible:=True; EventEditing:=False; EventDeletePending:=False; EventFocus:=0;
 DrawInterface;
End;

Procedure EventNew(Meeting: Boolean);
Var H,M,S,HS: Word;
Begin
 If Not EventCanOpen Or (EventDialogVisible And EventEditing) Then Exit;
 If EventCount>=128 Then Begin EventError:='Agenda plein (128 evenements).';
  MailStatus:=EventError; DrawInterface; Exit; End;
 EventReturnToList:=EventDialogVisible;
 If Not CalendarVisible Then CalendarShow(True);
 FillChar(EventDraft,SizeOf(EventDraft),0); EventDraft.IsMeeting:=Meeting;
 EventDraft.StartDate:=EventDate(CalendarYear,CalendarMonth,CalendarDay);
 EventDraft.EndDate:=EventDraft.StartDate;
 GetTime(H,M,S,HS); If H>22 Then H:=22;
 EventDraft.StartTime:=EventNumber(H,2)+':00'; EventDraft.EndTime:=EventNumber(H+1,2)+':00';
 EventEditIndex:=-1; EventDialogVisible:=True; EventEditing:=True;
 EventDeletePending:=False; EventFocus:=0; EventCursor:=0; EventError:=''; DrawInterface;
End;

Procedure EventEditSelected;
Begin
 If (EventListSelection<0) Or (EventListSelection>=EventListCount) Then Exit;
 EventEditIndex:=EventList[EventListSelection]; EventDraft:=CalendarEvents[EventEditIndex];
 EventReturnToList:=True; EventEditing:=True; EventFocus:=0;
 EventCursor:=Length(EventDraft.Title); EventError:=''; DrawInterface;
End;

Procedure EventCloseEditor;
Begin
 EventDeletePending:=False; EventError:='';
 If EventReturnToList Then Begin EventEditing:=False; EventFocus:=0; EventBuildList; End
 Else EventDialogVisible:=False;
 DrawInterface;
End;

Function EventCommit: Boolean;
Var I,Y,M,D,OldCount: Integer; OldNext: LongInt; Old: TCalendarEvent; Normalized: String;
Begin
 EventCommit:=False; EventError:=''; If Not EventValid(EventDraft) Then Exit;
 If EventDraft.IsMeeting Then Begin
  EventAddresses(EventDraft.Participants,Normalized); EventDraft.Participants:=Normalized;
 End;
 If EventDraft.IsMeeting Then Begin
  If EventDraft.Organizer<>'' Then Begin
   If Not EventAddresses(EventDraft.Organizer,Normalized) Then Begin EventError:='Organisateur invalide.'; Exit; End;
  End;
 End;
 OldCount:=EventCount; OldNext:=EventNextID;
 If EventEditIndex<0 Then Begin
  If EventCount>=128 Then Begin EventError:='Agenda plein.'; Exit; End;
  If EventNextID>=2147483646 Then Begin EventError:='Limite des identifiants atteinte.'; Exit; End;
  I:=EventCount; EventDraft.ID:=EventNextID; Inc(EventNextID); Inc(EventCount);
  EventDraft.UID:=EventNewUID;
 End Else Begin
  I:=EventEditIndex; Old:=CalendarEvents[I]; EventDraft.ID:=Old.ID; EventDraft.UID:=Old.UID;
  If Old.Sequence>=2147483646 Then Begin EventError:='Limite de versions atteinte.'; Exit; End;
  EventDraft.Sequence:=Old.Sequence+1;
 End;
 CalendarEvents[I]:=EventDraft;
 If Not EventSave Then Begin
  EventCount:=OldCount; EventNextID:=OldNext;
  If EventEditIndex>=0 Then CalendarEvents[I]:=Old;
  Exit;
 End;
 EventEditIndex:=I;
 If EventParseDate(EventDraft.StartDate,Y,M,D) Then Begin CalendarYear:=Y; CalendarMonth:=M; CalendarDay:=D; End;
 EventBuildList; EventCommit:=True;
End;

Procedure EventDelete;
Var I,N: Integer;
Begin
 If (EventEditIndex<0) Or (EventEditIndex>=EventCount) Then Exit;
 N:=EventCount;
 For I:=0 To N-1 Do EventBackup[I]:=CalendarEvents[I];
 For I:=EventEditIndex To N-2 Do CalendarEvents[I]:=CalendarEvents[I+1];
 Dec(EventCount);
 If Not EventSave Then Begin
  EventCount:=N; For I:=0 To N-1 Do CalendarEvents[I]:=EventBackup[I]; Exit;
 End;
 EventEditIndex:=-1; EventCloseEditor;
End;

{ Conversion et encodage des invitations iCalendar, sans nouvelle unite. }
Function EventUTF8(S: TMailText): TMailText;

Begin
 EventUTF8:=S;
 
End;

Function EventBase64(Const Data: TMailText): TMailText;
Const Alphabet: String[64]='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
Var I,N,Col: LongInt; A,B,C: Byte; Chunk: String;
Var EventBase64_R: TMailText;
Begin
 EventBase64_R:=''; I:=1; Col:=0; N:=Length(Data);
 While I<=N Do Begin
  A:=Ord(Data[I]); B:=0; C:=0;
  If I+1<=N Then B:=Ord(Data[I+1]); If I+2<=N Then C:=Ord(Data[I+2]);
  Chunk:=Alphabet[A Shr 2+1]+Alphabet[((A And 3) Shl 4 Or (B Shr 4))+1];
  If I+1<=N Then Chunk:=Chunk+Alphabet[((B And 15) Shl 2 Or (C Shr 6))+1] Else Chunk:=Chunk+'=';
  If I+2<=N Then Chunk:=Chunk+Alphabet[(C And 63)+1] Else Chunk:=Chunk+'=';
  EventBase64_R:=EventBase64_R+Chunk; Inc(I,3); Inc(Col,4);
  If Col=76 Then Begin EventBase64_R:=EventBase64_R+#13#10; Col:=0; End;
 End;
 If Col<>0 Then EventBase64_R:=EventBase64_R+#13#10;
 EventBase64 := EventBase64_R;
End;

Function EventEscape(Const S: TMailText): TMailText;
Var I: LongInt;
Var EventEscape_R: TMailText;
Begin
 EventEscape_R:='';
 For I:=1 To Length(S) Do Case S[I] Of
  Chr(92),';',',': EventEscape_R:=EventEscape_R+Chr(92)+S[I];
  #13: ; #10: EventEscape_R:=EventEscape_R+Chr(92)+'n';
 Else EventEscape_R:=EventEscape_R+S[I];
 End;
 EventEscape := EventEscape_R;
End;

Function EventUTC(Date,Time: String): String;

Begin
 EventUTC:='';
 
End;

Function EventInvitation(Const E: TCalendarEvent): TMailText;
Const Days: Array[0..6] Of String[3]=('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
 Months: Array[1..12] Of String[3]=('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
Var Data,Line,Participants,Address: TMailText; P,N: LongInt; Stamp: TEventSystemTime;
 Procedure AddInv(S: TMailText);
 Var Cut: LongInt;
 Begin
  While Length(S)>75 Do Begin
   Cut:=75;
   While (Cut>1) And ((Ord(S[Cut+1]) And $C0)=$80) Do Dec(Cut);
   Data:=Data+Copy(S,1,Cut)+#13#10; Delete(S,1,Cut); S:=' '+S;
  End;
  Data:=Data+S+#13#10;
 End;
Var EventInvitation_R: TMailText;
Begin
 Data:=''; EventInvitation_R:='';
 If (EventUTC(E.StartDate,E.StartTime)='') Or (EventUTC(E.EndDate,E.EndTime)='') Then Begin
  EventError:='Conversion UTC impossible pour ces dates.'; Begin EventInvitation := EventInvitation_R; Exit End;
 End;
 FillChar(Stamp,SizeOf(Stamp),0);
 
 AddInv('BEGIN:VCALENDAR'); AddInv('VERSION:2.0'); AddInv('PRODID:-//OFFICE-0//Outlink//FR');
 AddInv('CALSCALE:GREGORIAN'); AddInv('METHOD:REQUEST'); AddInv('BEGIN:VEVENT'); AddInv('UID:'+E.UID);
 AddInv('DTSTAMP:'+EventNumber(Stamp.Year,4)+EventNumber(Stamp.Month,2)+EventNumber(Stamp.Day,2)+'T'+
  EventNumber(Stamp.Hour,2)+EventNumber(Stamp.Minute,2)+EventNumber(Stamp.Second,2)+'Z');
 AddInv('SEQUENCE:'+EventNumber(E.Sequence,0)); AddInv('DTSTART:'+EventUTC(E.StartDate,E.StartTime));
 AddInv('DTEND:'+EventUTC(E.EndDate,E.EndTime)); AddInv('SUMMARY:'+EventEscape(EventUTF8(E.Title)));
 AddInv('LOCATION:'+EventEscape(EventUTF8(E.Location))); AddInv('DESCRIPTION:'+EventEscape(EventUTF8(E.Notes)));
 AddInv('ORGANIZER:mailto:'+E.Organizer); Participants:=E.Participants;
 While Participants<>'' Do Begin
  P:=1; While (P<=Length(Participants)) And Not (Participants[P] In [',',';']) Do Inc(P);
  Address:=MailTrim(Copy(Participants,1,P-1)); Delete(Participants,1,P);
  If Address<>'' Then AddInv('ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE:mailto:'+Address);
 End;
 AddInv('STATUS:CONFIRMED'); AddInv('END:VEVENT'); AddInv('END:VCALENDAR');
 { Les mots encodes d en-tete ne depassent pas 75 caracteres. }
 Participants:='';
 For P:=1 To Length(E.Participants) Do
  If E.Participants[P]=';' Then Participants:=Participants+', ' Else Participants:=Participants+E.Participants[P];
 EventInvitation_R:='From: '+E.Organizer+#13#10+'To: '+Participants+#13#10+
  'Date: '+Days[Stamp.WeekDay]+', '+EventNumber(Stamp.Day,2)+' '+Months[Stamp.Month]+' '+
  EventNumber(Stamp.Year,4)+' '+EventNumber(Stamp.Hour,2)+':'+EventNumber(Stamp.Minute,2)+':'+
  EventNumber(Stamp.Second,2)+' +0000'+#13#10+'Message-ID: <'+EventNewUID+'>'+#13#10+'Subject: ';
 Line:=EventUTF8('Invitation : '+E.Title); N:=1;
 While N<=Length(Line) Do Begin
  P:=30; If Length(Line)-N+1<P Then P:=Length(Line)-N+1;
  While (P>1) And (N+P<=Length(Line)) And ((Ord(Line[N+P]) And $C0)=$80) Do Dec(P);
  Address:=EventBase64(Copy(Line,N,P)); While Pos(#13#10,Address)>0 Do Delete(Address,Pos(#13#10,Address),2);
  If N>1 Then EventInvitation_R:=EventInvitation_R+#13#10+' ';
  EventInvitation_R:=EventInvitation_R+'=?UTF-8?B?'+Address+'?='; Inc(N,P);
 End;
 EventInvitation_R:=EventInvitation_R+#13#10+'MIME-Version: 1.0'+#13#10+
  'Content-Type: text/calendar; charset=UTF-8; method=REQUEST'+#13#10+
  'Content-Disposition: attachment; filename="invitation.ics"'+#13#10+
  'Content-Transfer-Encoding: base64'+#13#10+#13#10+EventBase64(Data);
 EventInvitation := EventInvitation_R;
End;

Procedure EventSendInvitationWork;
Var A,I: Integer; OK: Boolean; Body: TMailText; Addresses: String;
Begin
 EventError:='';
 If Not EventDraft.IsMeeting Then Begin EventError:='L invitation est reservee aux reunions.'; Exit; End;
 If Not EventValid(EventDraft) Then Exit;
 If UserPrefs.Connection.OfflineMode Then Begin EventError:='Mode hors ligne : invitation non envoyee.'; Exit; End;
 A:=-1;
 If EventDraft.InvitationSent Then Begin
  For I:=0 To EmailAccountCount-1 Do
   If MailUpper(EmailAccounts[I].EmailAddress)=MailUpper(EventDraft.Organizer) Then A:=I;
 End Else Begin
  If (SelectedFolder>=0) And (SelectedFolder<FolderCount) Then A:=MailFolderAccount[SelectedFolder];
  If A<0 Then For I:=0 To EmailAccountCount-1 Do If EmailAccounts[I].IsDefault Then A:=I;
 End;
 If (A<0) Or (A>=EmailAccountCount) Then Begin EventError:='Compte organisateur non configure.'; Exit; End;
 If Not EventAddresses(EmailAccounts[A].EmailAddress,Addresses) Then Begin
  EventError:='Adresse du compte organisateur invalide.'; Exit;
 End;
 EventDraft.Organizer:=EmailAccounts[A].EmailAddress;
 If Not EventCommit Then Exit;
 Body:=EventInvitation(EventDraft); If Body='' Then Exit;
 BusyBegin('Envoi de l invitation',EmailAccounts[A].OutgoingHost);
 OK:=OpenOutgoingAccount(EmailAccounts[A]);
 If OK Then BusyStage('Envoi de l invitation et confirmation SMTP...');
 If OK Then OK:=SMTP_MailFrom(EventDraft.Organizer)=SMTP_OK;
 If OK Then OK:=MailRecipients(EventDraft.Participants);
 If OK Then OK:=SMTP_Data(Body)=SMTP_OK;
 MailClose(SMTPWire);
 If Not OK Then Begin
  EventError:='Invitation non envoyee : '+Copy(MailError,1,60);
  If MailError='' Then EventError:='Invitation refusee : '+Copy(SMTPClient.LastError,1,60);
  Exit;
 End;
 EventDraft.InvitationSent:=True; CalendarEvents[EventEditIndex].InvitationSent:=True;
 If Not EventSave Then Begin EventError:='Invitation envoyee; sauvegarde du statut impossible.'; Exit; End;
 EventError:='Invitation acceptee par le serveur SMTP.';
End;

Procedure EventSendInvitation;
Begin
 If BusyVisible Then Exit;
 EventSendInvitationWork;
 BusyEnd;
End;

Function EventField(Index: Integer): String;
Begin
 Case Index Of
  0: EventField:=EventDraft.Title; 1: EventField:=EventDraft.Location;
  2: EventField:=EventDraft.StartDate; 3: EventField:=EventDraft.StartTime;
  4: EventField:=EventDraft.EndDate; 5: EventField:=EventDraft.EndTime;
  6: EventField:=EventDraft.Participants; 7: EventField:=EventDraft.Notes;
 Else EventField:='';
 End;
End;

Procedure EventPutField(Index: Integer; Text: String);
Begin
 Case Index Of
  0: EventDraft.Title:=Text; 1: EventDraft.Location:=Text;
  2: EventDraft.StartDate:=Text; 3: EventDraft.StartTime:=Text;
  4: EventDraft.EndDate:=Text; 5: EventDraft.EndTime:=Text;
  6: EventDraft.Participants:=Text; 7: EventDraft.Notes:=Text;
 End;
End;

Procedure EventDraw;
Const Labels: Array[0..8] Of String[15]=('Objet','Lieu','Date debut','Heure debut','Date fin','Heure fin',
 'Participants','Notes','Reunion');
Var X,Y,I,Index: Integer; Text,Title: String;
Begin
 If Not EventDialogVisible Then Exit;
 X:=(SCREEN_WIDTH-550) Div 2; Y:=(SCREEN_HEIGHT-420) Div 2;
 If EventEditing Then Begin
  Title:='Rendez-vous'; If EventDraft.IsMeeting Then Title:='Reunion';
  DrawDialogBox(X,Y,550,420,Title);
  For I:=0 To 8 Do Begin
   GSetColor(Black); GOutTextXY(X+14,Y+42+I*32,Labels[I]+' :');
   FillRect(X+146,Y+34+I*32,X+532,Y+60+I*32,White);
   Text:=EventField(I);
   If I=8 Then Begin Text:='Non'; If EventDraft.IsMeeting Then Text:='Oui'; End;
   If (EventFocus=I) And (I<8) Then Begin
    Insert('|',Text,EventCursor+1);
    If EventCursor>42 Then Delete(Text,1,EventCursor-42);
   End;
   If EventFocus=I Then Text:='> '+Text;
   GOutTextXY(X+150,Y+42+I*32,Copy(Text,1,47));
  End;
  DrawDialogButton(X+12,Y+378,94,26,'Enregistrer',EventFocus=9,True);
  DrawDialogButton(X+116,Y+378,110,26,'Inviter',EventFocus=10,EventDraft.IsMeeting);
  DrawDialogButton(X+236,Y+378,94,26,'Supprimer',EventFocus=11,EventEditIndex>=0);
  DrawDialogButton(X+440,Y+378,94,26,'Annuler',EventFocus=12,True);
  GSetColor(Black); GOutTextXY(X+14,Y+350,'Heures locales. Dates AAAA-MM-JJ, heures HH:MM.');
 End Else Begin
  DrawDialogBox(X,Y,550,420,'Agenda du jour - '+EventDate(CalendarYear,CalendarMonth,CalendarDay));
  DrawDialogButton(X+12,Y+30,104,26,'Nouveau RDV',EventFocus=1,EventCount<128);
  DrawDialogButton(X+126,Y+30,128,26,'Nouvelle reunion',EventFocus=2,EventCount<128);
  DrawDialogButton(X+264,Y+30,94,26,'Modifier',EventFocus=3,EventListCount>0);
  If EventListSelection<EventListScroll Then EventListScroll:=EventListSelection;
  If EventListSelection>=EventListScroll+12 Then EventListScroll:=EventListSelection-11;
  If EventListScroll<0 Then EventListScroll:=0;
  For I:=0 To 11 Do Begin
   Index:=EventListScroll+I;
   If Index>=EventListCount Then Break;
   If Index=EventListSelection Then Begin
    FillRect(X+12,Y+70+I*22,X+534,Y+90+I*22,Blue); GSetColor(White);
   End Else GSetColor(Black);
   With CalendarEvents[EventList[Index]] Do Begin
    Text:=StartTime+'-'+EndTime+' '; If IsMeeting Then Text:=Text+'[R] ';
    Text:=Text+Title;
   End;
   GOutTextXY(X+16,Y+76+I*22,Copy(Text,1,62));
  End;
  If EventListCount=0 Then Begin GSetColor(Black); GOutTextXY(X+16,Y+86,'Aucun rendez-vous pour ce jour.'); End;
  DrawDialogButton(X+12,Y+378,88,26,'Page -',EventFocus=4,EventListScroll>0);
  DrawDialogButton(X+110,Y+378,88,26,'Page +',EventFocus=5,EventListScroll+12<EventListCount);
  DrawDialogButton(X+440,Y+378,94,26,'Fermer',EventFocus=6,True);
 End;
 GSetColor(Black);
 If EventEditing Then GOutTextXY(X+14,Y+330,Copy(EventError,1,64))
 Else GOutTextXY(X+14,Y+350,Copy(EventError,1,64));
 If EventDeletePending Then Begin
  FillRect(X+8,Y+318,X+540,Y+412,LightGray); GSetColor(Black);
  GOutTextXY(X+14,Y+328,'Supprimer du calendrier local ?');
  If EventDraft.InvitationSent Then GOutTextXY(X+14,Y+350,'Cette action n annule pas l invitation envoyee.');
  DrawDialogButton(X+14,Y+378,94,26,'Oui (O)',False,True);
  DrawDialogButton(X+122,Y+378,94,26,'Non (N)',True,True);
 End;
End;

Procedure EventAction(Action: Integer);
Begin
 If EventEditing Then Case Action Of
  8: EventDraft.IsMeeting:=Not EventDraft.IsMeeting;
  9: If EventCommit Then EventCloseEditor;
  10: EventSendInvitation;
  11: If EventEditIndex>=0 Then EventDeletePending:=True;
  12: EventCloseEditor;
 End Else Case Action Of
  1: EventNew(False); 2: EventNew(True); 3: EventEditSelected;
  4: Begin Dec(EventListSelection,12); If EventListSelection<0 Then EventListSelection:=0; End;
  5: Begin Inc(EventListSelection,12);
   If EventListSelection>=EventListCount Then EventListSelection:=EventListCount-1; End;
  6: EventDialogVisible:=False;
 End;
 DrawInterface;
End;

Procedure EventKey(Key: Char; Extended: Boolean);
Const Limits: Array[0..7] Of Integer=(80,80,10,5,10,5,255,255);
Var Text: String; OldFocus: Integer;
Begin
 If EventDeletePending Then Begin
  If Not Extended Then Case UpCase(Key) Of
   'O': Begin EventDeletePending:=False; EventDelete; End;
   'N',#27,#13: EventDeletePending:=False;
  End;
 End Else If EventEditing Then Begin
  OldFocus:=EventFocus; Text:=EventField(EventFocus);
  If Extended Then Case Key Of
   #15: EventFocus:=(EventFocus+12) Mod 13;
   #75: If EventFocus<8 Then If EventCursor>0 Then Dec(EventCursor);
   #77: If EventFocus<8 Then If EventCursor<Length(Text) Then Inc(EventCursor);
   #71: EventCursor:=0; #79: EventCursor:=Length(Text);
   #83: If EventFocus<8 Then Delete(Text,EventCursor+1,1);
  End Else Case Key Of
   #27: Begin EventCloseEditor; Exit; End;
   #9: EventFocus:=(EventFocus+1) Mod 13;
   #13: Begin If EventFocus<8 Then EventAction(9) Else EventAction(EventFocus); Exit; End;
   #8: If (EventFocus<8) And (EventCursor>0) Then Begin Delete(Text,EventCursor,1); Dec(EventCursor); End;
   #32..#255: If EventFocus<8 Then Begin
    If Length(Text)<Limits[EventFocus] Then Begin Insert(Key,Text,EventCursor+1); Inc(EventCursor); End;
   End Else If Key=' ' Then Begin EventAction(EventFocus); Exit; End;
  End;
  EventPutField(OldFocus,Text);
  If EventFocus<>OldFocus Then EventCursor:=Length(EventField(EventFocus));
 End Else Begin
  If Extended Then Case Key Of
   #72: If EventListSelection>0 Then Dec(EventListSelection);
   #80: If EventListSelection<EventListCount-1 Then Inc(EventListSelection);
   #73: EventAction(4); #81: EventAction(5);
   #71: If EventListCount>0 Then EventListSelection:=0;
   #79: EventListSelection:=EventListCount-1;
   #82: EventNew(False);
   #83: Begin EventEditSelected; If EventEditing Then EventDeletePending:=True; End;
   #15: EventFocus:=(EventFocus+6) Mod 7;
  End Else Case Key Of
   #27: EventDialogVisible:=False;
   #9: EventFocus:=(EventFocus+1) Mod 7;
   #13,' ': If EventFocus=0 Then EventEditSelected Else EventAction(EventFocus);
   'n','N': EventNew(False); 'm','M': EventNew(True);
  End;
 End;
 DrawInterface;
End;

Procedure EventClick(MX,MY: Integer);
Var X,Y,Row: Integer;
Begin
 X:=MX-(SCREEN_WIDTH-550) Div 2; Y:=MY-(SCREEN_HEIGHT-420) Div 2;
 If (X<0) Or (X>550) Or (Y<0) Or (Y>420) Then Exit;
 If EventDeletePending Then Begin
  If (Y>=378) And (Y<=404) Then Begin
   If (X>=14) And (X<=108) Then Begin EventDeletePending:=False; EventDelete; End
   Else If (X>=122) And (X<=216) Then EventDeletePending:=False;
  End;
 End Else If EventEditing Then Begin
  If (X>=146) And (X<=532) And (Y>=34) And (Y<316) Then Begin
   Row:=(Y-34) Div 32;
   If Y<=60+Row*32 Then Begin EventFocus:=Row; EventCursor:=Length(EventField(Row));
    If Row=8 Then EventAction(8); End;
  End Else If (Y>=378) And (Y<=404) Then Begin
   If (X>=12) And (X<=106) Then EventAction(9)
   Else If (X>=116) And (X<=226) Then EventAction(10)
   Else If (X>=236) And (X<=330) Then EventAction(11)
   Else If (X>=440) And (X<=534) Then EventAction(12);
  End;
 End Else Begin
  If (Y>=30) And (Y<=56) Then Begin
   If (X>=12) And (X<=116) Then EventAction(1)
   Else If (X>=126) And (X<=254) Then EventAction(2)
   Else If (X>=264) And (X<=358) Then EventAction(3);
  End Else If (X>=12) And (X<=534) And (Y>=70) And (Y<334) Then Begin
   Row:=EventListScroll+(Y-70) Div 22;
   If Row<EventListCount Then Begin EventListSelection:=Row; EventFocus:=0; End;
  End Else If (Y>=378) And (Y<=404) Then Begin
   If (X>=12) And (X<=100) Then EventAction(4)
   Else If (X>=110) And (X<=198) Then EventAction(5)
   Else If (X>=440) And (X<=534) Then EventAction(6);
  End;
 End;
 DrawInterface;
End;

{ Informations du programme dans une boite graphique modale. }
Procedure DrawAboutDialog;
Var X,Y: Integer;
Begin
 If Not AboutVisible Then Exit;
 X:=(SCREEN_WIDTH-440) Div 2; Y:=(SCREEN_HEIGHT-260) Div 2;
 DrawDialogBox(X,Y,440,260,'A propos...');
 DrawDialogButton(X+416,Y+3,18,16,'X',False,True);
 { Petite enveloppe dessinee avec les primitives graphiques. }
 FillRect(X+20,Y+44,X+66,Y+78,White);
 GSetColor(Blue);
 GRectangle(X+20,Y+44,X+66,Y+78);
 GLine(X+20,Y+44,X+43,Y+62); GLine(X+66,Y+44,X+43,Y+62);
 GOutTextXY(X+84,Y+46,'Outlink');
 GSetColor(Black);
 GOutTextXY(X+84,Y+66,'Version 1.00 pour OS/2-0');
 GOutTextXY(X+20,Y+100,'Client de messagerie graphique en Pascal');
 GOutTextXY(X+20,Y+124,'Auteur : Sylvain Maltais');
 GOutTextXY(X+20,Y+144,'support@gladir.com');
 GOutTextXY(X+20,Y+166,'https://www.gladir.com/office-0');
 GOutTextXY(X+20,Y+186,'https://www.gladir.com/networkkitp');
 DrawDialogButton(X+176,Y+220,88,26,'OK',True,True);
End;

Procedure ShowAboutDialog;
Begin
 If ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or
    ColumnsDialogVisible Or RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Then Exit;
 AboutVisible:=True; ContextMenuVisible:=False; DrawInterface;
End;

Procedure CloseAboutDialog;
Begin AboutVisible:=False; DrawInterface; End;

Procedure HandleAboutClick(MX,MY: Integer);
Var X,Y: Integer;
Begin
 X:=(SCREEN_WIDTH-440) Div 2; Y:=(SCREEN_HEIGHT-260) Div 2;
 If ((MX>=X+176) And (MX<=X+264) And (MY>=Y+220) And (MY<=Y+246)) Or
    ((MX>=X+416) And (MX<=X+434) And (MY>=Y+3) And (MY<=Y+19)) Then CloseAboutDialog;
End;

Procedure HandleAboutKey(Key: Char);
Begin If Key In [#13,#27,' '] Then CloseAboutDialog; End;

{ Les options proposees sont reliees au comportement effectif du programme. }
Function Prefs_Path: String;
Var Path: String; I: Integer;
Begin
 Path:=AccountFileName; I:=Length(Path);
 While (I>0) And Not (Path[I] In ['.',Chr(92),'/']) Do Dec(I);
 If (I>0) And (Path[I]='.') Then Delete(Path,I,255);
 Prefs_Path:=Path+'.OPT';
End;

Function Prefs_Save: Boolean;
Var SavedData: TMailText; SavedError: String; Number: String;
 Procedure AddNumber(N: Integer);
 Begin Str(N,Number); OlSvAdd(Number+#13#10); End;
Begin
 OlSvPush; SavedError:=FileOpenError;
 OlSvAdd('OUTLOOK-OPTIONS-1'+#13#10);
 AddNumber(Ord(OptionsDraft.General.CheckMailOnStart));
 AddNumber(Ord(OptionsDraft.Reading.ShowPreviewPane));
 AddNumber(Ord(OptionsDraft.Reading.PreviewOnRight));
 AddNumber(Ord(OptionsDraft.Reading.UseAlternateRowColor));
 AddNumber(Ord(OptionsDraft.Composing.IncludeOriginal));
 OlSvAdd(OptionsDraft.Composing.QuotePrefix+#13#10);
 AddNumber(Ord(OptionsDraft.Connection.OfflineMode));
 AddNumber(OptionsDraft.Connection.ConnectionTimeout);
 Prefs_Save:=WriteMessageFile(Prefs_Path,True);
 OptionsError:='';
 If FileOpenError<>'' Then OptionsError:='Impossible de sauvegarder les options.';
 OlSvPop; FileOpenError:=SavedError;
End;

Function Prefs_Load: Boolean;
Var F: Text; Draft: TUserPreferences; Line: String; Err,Code,N,I: Integer; OldMode: Byte;
Begin
 Prefs_Load:=False; OptionsError:=''; Draft:=UserPrefs;
 {$I-}
 Assign(F,Prefs_Path); OldMode:=FileMode; FileMode:=0; Reset(F); FileMode:=OldMode; Err:=IOResult;
 If Err=2 Then Exit;
 If Err<>0 Then Begin OptionsError:='Impossible de lire les options.'; Exit; End;
 ReadLn(F,Line); Err:=IOResult;
 If (Err=0) And (Line<>'OUTLOOK-OPTIONS-1') Then Err:=100;
 For I:=0 To 7 Do Begin
  If Err<>0 Then Break;
  If Eof(F) Then Begin Err:=100; Break; End;
  ReadLn(F,Line); Err:=IOResult;
  If Err<>0 Then Break;
  If I=5 Then Begin
   If Length(Line)>5 Then Err:=100 Else Draft.Composing.QuotePrefix:=Line;
  End Else Begin
   Val(Line,N,Code);
   If (Code<>0) Or (N<0) Then Err:=100;
   If I=7 Then Begin If (N<10) Or (N>120) Then Err:=100; End
   Else If N>1 Then Err:=100;
   If Err=0 Then Case I Of
    0: Draft.General.CheckMailOnStart:=N=1;
    1: Draft.Reading.ShowPreviewPane:=N=1;
    2: Draft.Reading.PreviewOnRight:=N=1;
    3: Draft.Reading.UseAlternateRowColor:=N=1;
    4: Draft.Composing.IncludeOriginal:=N=1;
    6: Draft.Connection.OfflineMode:=N=1;
    7: Draft.Connection.ConnectionTimeout:=N;
   End;
  End;
 End;
 If (Err=0) And Not Eof(F) Then Err:=100;
 Close(F); Code:=IOResult; If Err=0 Then Err:=Code;
 {$I+}
 If Err<>0 Then Begin OptionsError:='Fichier options invalide ou incomplet.'; Exit; End;
 UserPrefs:=Draft; Prefs_Load:=True;
End;

Procedure Prefs_ApplyReadingSettings;
Begin
 If UserPrefs.Reading.PreviewOnRight Then PreviewOrientation:=poVertical
 Else PreviewOrientation:=poHorizontal;
 PreviewVisible:=UserPrefs.Reading.ShowPreviewPane;
 If PreviewVisible And (Layout.PreviewPaneHeight=0) Then Layout.PreviewPaneHeight:=150;
 CalculateLayout;
End;

Procedure Prefs_DrawWindow;
Var X,Y,I: Integer; Text: String; Checked: Boolean;
Begin
 If Not PrefsVisible Then Exit;
 X:=PrefsWindowX; Y:=PrefsWindowY; DrawDialogBox(X,Y,520,370,'Options');
 For I:=0 To 7 Do Begin
  Checked:=False; Text:='';
  Case I Of
   0: Begin Checked:=OptionsDraft.General.CheckMailOnStart; Text:='Relever le courrier au demarrage'; End;
   1: Begin Checked:=OptionsDraft.Reading.ShowPreviewPane; Text:='Afficher le volet de lecture'; End;
   2: Begin Checked:=OptionsDraft.Reading.PreviewOnRight; Text:='Placer le volet de lecture a droite'; End;
   3: Begin Checked:=OptionsDraft.Reading.UseAlternateRowColor; Text:='Alterner les couleurs des messages'; End;
   4: Begin Checked:=OptionsDraft.Composing.IncludeOriginal; Text:='Citer le message original dans les reponses'; End;
   5: Text:='Prefixe de citation :';
   6: Begin Checked:=OptionsDraft.Connection.OfflineMode; Text:='Mode hors ligne (aucune connexion)'; End;
   7: Text:='Delai reseau (10 a 120 secondes) :';
  End;
  If I In [0,1,2,3,4,6] Then Begin
   If Checked Then Text:='[x] '+Text Else Text:='[ ] '+Text;
  End;
  If OptionsFocus=I Then Text:='> '+Text Else Text:='  '+Text;
  GSetColor(Black); GOutTextXY(X+16,Y+40+I*32,Text);
  If I=5 Then Begin
   FillRect(X+286,Y+34+I*32,X+494,Y+58+I*32,White);
   Text:=OptionsDraft.Composing.QuotePrefix;
   If OptionsFocus=5 Then Insert('|',Text,OptionsCursor+1);
   GOutTextXY(X+292,Y+40+I*32,Text);
  End;
  If I=7 Then Begin
   Str(OptionsDraft.Connection.ConnectionTimeout,Text);
   GOutTextXY(X+350,Y+40+I*32,'< '+Text+' >');
  End;
 End;
 GSetColor(Black); GOutTextXY(X+16,Y+296,OptionsError);
 DrawDialogButton(X+224,Y+330,80,26,'OK',OptionsFocus=8,True);
 DrawDialogButton(X+314,Y+330,90,26,'Annuler',OptionsFocus=9,True);
 DrawDialogButton(X+414,Y+330,90,26,'Appliquer',OptionsFocus=10,True);
End;

Procedure Prefs_Hide;
Begin PrefsVisible:=False; DrawInterface; End;

Procedure Prefs_Commit(CloseAfter: Boolean);
Begin
 If Not Prefs_Save Then Begin DrawInterface; Exit; End;
 UserPrefs:=OptionsDraft; UserPrefs.Modified:=False;
 Prefs_ApplyReadingSettings;
 If CloseAfter Then PrefsVisible:=False;
 DrawInterface;
End;

Procedure Prefs_Change(Delta: Integer);
Begin
 OptionsError:='';
 Case OptionsFocus Of
  0: OptionsDraft.General.CheckMailOnStart:=Not OptionsDraft.General.CheckMailOnStart;
  1: OptionsDraft.Reading.ShowPreviewPane:=Not OptionsDraft.Reading.ShowPreviewPane;
  2: OptionsDraft.Reading.PreviewOnRight:=Not OptionsDraft.Reading.PreviewOnRight;
  3: OptionsDraft.Reading.UseAlternateRowColor:=Not OptionsDraft.Reading.UseAlternateRowColor;
  4: OptionsDraft.Composing.IncludeOriginal:=Not OptionsDraft.Composing.IncludeOriginal;
  6: OptionsDraft.Connection.OfflineMode:=Not OptionsDraft.Connection.OfflineMode;
  7: Begin
   Inc(OptionsDraft.Connection.ConnectionTimeout,Delta);
   If OptionsDraft.Connection.ConnectionTimeout<10 Then OptionsDraft.Connection.ConnectionTimeout:=10;
   If OptionsDraft.Connection.ConnectionTimeout>120 Then OptionsDraft.Connection.ConnectionTimeout:=120;
  End;
  8: Prefs_Commit(True);
  9: Prefs_Hide;
  10: Prefs_Commit(False);
 End;
End;

Procedure Prefs_Show;
Begin
 If ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or
    ColumnsDialogVisible Or RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Then Exit;
 OptionsDraft:=UserPrefs;
 OptionsDraft.Reading.ShowPreviewPane:=PreviewVisible;
 OptionsDraft.Reading.PreviewOnRight:=PreviewOrientation=poVertical;
 OptionsFocus:=0; OptionsCursor:=Length(OptionsDraft.Composing.QuotePrefix);
 PrefsWindowX:=(SCREEN_WIDTH-520) Div 2; PrefsWindowY:=(SCREEN_HEIGHT-370) Div 2;
 PrefsVisible:=True; ContextMenuVisible:=False; DrawInterface;
End;

Procedure Prefs_HandleKey(Key: Char; Extended: Boolean);
Var Text: String;
Begin
 Text:=OptionsDraft.Composing.QuotePrefix;
 If Extended Then Begin
  Case Key Of
   #15: OptionsFocus:=(OptionsFocus+10) Mod 11;
   #72: OptionsFocus:=(OptionsFocus+10) Mod 11;
   #80: OptionsFocus:=(OptionsFocus+1) Mod 11;
   #75: If OptionsFocus=5 Then Begin If OptionsCursor>0 Then Dec(OptionsCursor); End
        Else If OptionsFocus=7 Then Prefs_Change(-1);
   #77: If OptionsFocus=5 Then Begin If OptionsCursor<Length(Text) Then Inc(OptionsCursor); End
        Else If OptionsFocus=7 Then Prefs_Change(1);
   #71: If OptionsFocus=5 Then OptionsCursor:=0;
   #79: If OptionsFocus=5 Then OptionsCursor:=Length(Text);
   #83: If OptionsFocus=5 Then Delete(Text,OptionsCursor+1,1);
  End;
 End Else Case Key Of
  #27: Begin Prefs_Hide; Exit; End;
  #9: OptionsFocus:=(OptionsFocus+1) Mod 11;
  #13: Begin
   If OptionsFocus=9 Then Prefs_Hide Else Prefs_Commit(OptionsFocus<>10);
   Exit;
  End;
  #8: If (OptionsFocus=5) And (OptionsCursor>0) Then Begin
   Delete(Text,OptionsCursor,1); Dec(OptionsCursor); End;
  #32..#255: If OptionsFocus=5 Then Begin
   If Length(Text)<5 Then Begin Insert(Key,Text,OptionsCursor+1); Inc(OptionsCursor); End;
  End Else If Key=' ' Then Prefs_Change(1);
 End;
 OptionsDraft.Composing.QuotePrefix:=Text; DrawInterface;
End;

Procedure Prefs_HandleClick(MX,MY: Integer);
Var X,Y,Row: Integer;
Begin
 X:=MX-PrefsWindowX; Y:=MY-PrefsWindowY;
 If (X<0) Or (X>520) Or (Y<0) Or (Y>370) Then Exit;
 If (X>=16) And (X<=500) And (Y>=34) And (Y<282) Then Begin
  Row:=(Y-34) Div 32;
  If Y<=58+Row*32 Then Begin
   OptionsFocus:=Row;
   If Row=5 Then OptionsCursor:=Length(OptionsDraft.Composing.QuotePrefix)
   Else If (Row=7) And (X<380) Then Prefs_Change(-1) Else Prefs_Change(1);
  End;
 End Else If (Y>=330) And (Y<=356) Then Begin
  If (X>=224) And (X<=304) Then Prefs_Commit(True)
  Else If (X>=314) And (X<=404) Then Prefs_Hide
  Else If (X>=414) And (X<=504) Then Prefs_Commit(False);
 End;
 DrawInterface;
End;

Procedure Prefs_Init;
Begin
 Prefs_InitDefaults; OptionsReady:=True; Prefs_Load; Prefs_ApplyReadingSettings;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DE LA CONFIGURATION DES PREFERENCES (TODO 23)
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU MODE HORS LIGNE ET SYNCHRONISATION (TODO 24)
  ============================================================================ }

{ Initialise le systeme hors ligne }
Procedure Offline_Init;
Begin
 ConnectionState := csOffline;
 LastConnectivityCheck := 0;
 IsManualOffline := False;

 QueuedOpCount := 0;
 QueueProcessing := False;

 CachedMessageCount := 0;
 CachedFolderCount := 0;

 SyncInProgress := False;
 SyncProgress := 0;
 SyncStatusText := '';

 StatusIndicatorX := 0;
 StatusIndicatorY := 0;
 StatusIndicatorVisible := True;
 StatusBlinkState := False;
 LastBlinkTime := 0;

 FillChar(LastSyncStats, SizeOf(TSyncStats), 0);
End;

{ Retourne le texte d'etat de connexion }
Function Offline_GetStatusText: String;
Begin
 Case ConnectionState Of
  csOnline: Offline_GetStatusText := STATUS_ONLINE_TEXT;
  csOffline: Offline_GetStatusText := STATUS_OFFLINE_TEXT;
  csConnecting: Offline_GetStatusText := STATUS_CONNECTING_TEXT;
  csDisconnecting: Offline_GetStatusText := STATUS_OFFLINE_TEXT;
  csSynchronizing: Offline_GetStatusText := STATUS_SYNCING_TEXT;
  Else Offline_GetStatusText := STATUS_OFFLINE_TEXT;
 End;
End;

{ Verifie la connectivite reseau }
Function Offline_CheckConnectivity: Boolean;
Begin
 { Verification basique de la connectivite }
 { En pratique, on pourrait tenter une connexion au serveur IMAP }
 If IMAPClient.Connected Then Begin
  Offline_CheckConnectivity := True;
  Exit;
 End;

 { Tentative de connexion }
 {$I-}
 IMAP_Connect;
 {$I+}

 Offline_CheckConnectivity := IMAPClient.Connected;
End;

{ Met a jour l'etat de connexion }
Procedure Offline_UpdateConnectionState;
Var
 CurrentTime: LongInt;
 WasOnline: Boolean;
Begin
 { Ne pas verifier si mode hors ligne force }
 If IsManualOffline Then Begin
  ConnectionState := csOffline;
  Exit;
 End;

 { Obtenir le temps actuel }
 CurrentTime := GetTickCount Div 1000;

 { Verifier si c'est le moment de tester }
 If (CurrentTime - LastConnectivityCheck) < CONNECTIVITY_CHECK_INTERVAL Then
  Exit;

 LastConnectivityCheck := CurrentTime;
 WasOnline := (ConnectionState = csOnline);

 { Verifier la connectivite }
 If Offline_CheckConnectivity Then Begin
  If ConnectionState <> csOnline Then Begin
   ConnectionState := csOnline;
   { Lancer la synchronisation si on vient de se reconnecter }
   If Not WasOnline Then
    Offline_StartSync;
  End;
 End
 Else Begin
  ConnectionState := csOffline;
 End;
End;

{ Passe en mode hors ligne manuellement }
Procedure Offline_GoOffline;
Begin
 IsManualOffline := True;
 ConnectionState := csOffline;

 { Deconnecter le client IMAP }
 If IMAPClient.Connected Then
  IMAP_Disconnect;
End;

{ Passe en mode en ligne }
Procedure Offline_GoOnline;
Begin
 IsManualOffline := False;
 ConnectionState := csConnecting;

 { Tenter la connexion }
 If Offline_CheckConnectivity Then Begin
  ConnectionState := csOnline;
  { Lancer la synchronisation }
  Offline_StartSync;
 End
 Else Begin
  ConnectionState := csOffline;
 End;
End;

{ Ajoute une operation a la file d'attente }
Function Offline_QueueOperation(OpType: TQueuedOpType; MsgID, TargetFolder: String): Boolean;
Var
 I: Integer;
Begin
 Offline_QueueOperation := False;

 { Verifier s'il y a de la place }
 If QueuedOpCount >= MAX_QUEUED_OPS Then Exit;

 { Verifier si l'operation existe deja }
 For I := 0 To QueuedOpCount - 1 Do Begin
  If (QueuedOps[I].OpType = OpType) And (QueuedOps[I].MessageID = MsgID) And
     (QueuedOps[I].State = qosWaiting) Then Begin
   { Operation deja en attente }
   Exit;
  End;
 End;

 { Ajouter l'operation }
 QueuedOps[QueuedOpCount].OpType := OpType;
 QueuedOps[QueuedOpCount].State := qosWaiting;
 QueuedOps[QueuedOpCount].MessageID := MsgID;
 QueuedOps[QueuedOpCount].TargetFolder := TargetFolder;
 QueuedOps[QueuedOpCount].QueuedTime := GetTickCount Div 1000;
 QueuedOps[QueuedOpCount].RetryCount := 0;
 QueuedOps[QueuedOpCount].LastError := '';
 QueuedOps[QueuedOpCount].Priority := 5; { Priorite normale }

 Inc(QueuedOpCount);
 Offline_QueueOperation := True;
End;

{ Retire une operation de la file d'attente }
Procedure Offline_RemoveOperation(Index: Integer);
Var
 I: Integer;
Begin
 If (Index < 0) Or (Index >= QueuedOpCount) Then Exit;

 { Decaler les operations suivantes }
 For I := Index To QueuedOpCount - 2 Do
  QueuedOps[I] := QueuedOps[I + 1];

 Dec(QueuedOpCount);
End;

{ Traite une operation de la file d'attente }
Function Offline_ProcessOperation(Index: Integer): Boolean;
Var
 Op: TQueuedOperation;
Begin
 Offline_ProcessOperation := False;
 If (Index < 0) Or (Index >= QueuedOpCount) Then Exit;

 Op := QueuedOps[Index];
 QueuedOps[Index].State := qosProcessing;

 Case Op.OpType Of
  qotSendMessage: Begin
   { Envoyer le message via SMTP }
   { TODO: Implementer l'envoi SMTP }
   QueuedOps[Index].State := qosCompleted;
   Offline_ProcessOperation := True;
  End;

  qotDeleteMessage: Begin
   { Supprimer le message sur le serveur }
   If IMAP_DeleteMessage(Op.MessageID) Then Begin
    QueuedOps[Index].State := qosCompleted;
    Offline_ProcessOperation := True;
   End
   Else Begin
    QueuedOps[Index].State := qosFailed;
    QueuedOps[Index].LastError := 'Echec suppression';
    Inc(QueuedOps[Index].RetryCount);
   End;
  End;

  qotMoveMessage: Begin
   { Deplacer le message sur le serveur }
   If IMAP_MoveMessage(Op.MessageID, Op.TargetFolder) Then Begin
    QueuedOps[Index].State := qosCompleted;
    Offline_ProcessOperation := True;
   End
   Else Begin
    QueuedOps[Index].State := qosFailed;
    QueuedOps[Index].LastError := 'Echec deplacement';
    Inc(QueuedOps[Index].RetryCount);
   End;
  End;

  qotMarkAsRead: Begin
   { Marquer comme lu sur le serveur }
   If IMAP_SetFlag(Op.MessageID, '\Seen', True) Then Begin
    QueuedOps[Index].State := qosCompleted;
    Offline_ProcessOperation := True;
   End
   Else Begin
    QueuedOps[Index].State := qosFailed;
    Inc(QueuedOps[Index].RetryCount);
   End;
  End;

  qotMarkAsUnread: Begin
   { Marquer comme non lu }
   If IMAP_SetFlag(Op.MessageID, '\Seen', False) Then Begin
    QueuedOps[Index].State := qosCompleted;
    Offline_ProcessOperation := True;
   End
   Else Begin
    QueuedOps[Index].State := qosFailed;
    Inc(QueuedOps[Index].RetryCount);
   End;
  End;

  qotFlagMessage: Begin
   { Marquer avec drapeau }
   If IMAP_SetFlag(Op.MessageID, '\Flagged', True) Then Begin
    QueuedOps[Index].State := qosCompleted;
    Offline_ProcessOperation := True;
   End
   Else Begin
    QueuedOps[Index].State := qosFailed;
    Inc(QueuedOps[Index].RetryCount);
   End;
  End;

  qotUnflagMessage: Begin
   { Retirer le drapeau }
   If IMAP_SetFlag(Op.MessageID, '\Flagged', False) Then Begin
    QueuedOps[Index].State := qosCompleted;
    Offline_ProcessOperation := True;
   End
   Else Begin
    QueuedOps[Index].State := qosFailed;
    Inc(QueuedOps[Index].RetryCount);
   End;
  End;
 End;
End;

{ Traite la file d'attente des operations }
Procedure Offline_ProcessQueue;
Var
 I: Integer;
 Processed: Integer;
Begin
 If ConnectionState <> csOnline Then Exit;
 If QueueProcessing Then Exit;
 If QueuedOpCount = 0 Then Exit;

 QueueProcessing := True;
 Processed := 0;

 { Traiter les operations en attente }
 I := 0;
 While I < QueuedOpCount Do Begin
  If QueuedOps[I].State = qosWaiting Then Begin
   If Offline_ProcessOperation(I) Then Begin
    Inc(Processed);
    Inc(LastSyncStats.MessagesSent);
   End
   Else Begin
    { Verifier le nombre de tentatives }
    If QueuedOps[I].RetryCount >= MAX_RETRY_COUNT Then Begin
     { Abandonner l'operation }
     Offline_RemoveOperation(I);
     Inc(LastSyncStats.Errors);
     Continue; { Ne pas incrementer I }
    End;
   End;
  End
  Else If QueuedOps[I].State = qosCompleted Then Begin
   { Retirer les operations terminees }
   Offline_RemoveOperation(I);
   Continue;
  End;
  Inc(I);
 End;

 QueueProcessing := False;
End;

{ Ajoute un message au cache }
Function Offline_CacheMessage(Const Msg: TMessage): Boolean;
Var
 I, Index: Integer;
Begin
 Offline_CacheMessage := False;

 { Chercher si le message existe deja }
 Index := -1;
 For I := 0 To CachedMessageCount - 1 Do Begin
  If CachedMessages^[I].MsgID = Msg.MsgID Then Begin
   Index := I;
   Break;
  End;
 End;

 { Si non trouve et pas de place, utiliser LRU }
 If (Index < 0) And (CachedMessageCount >= MAX_CACHED_MESSAGES) Then Begin
  { Trouver le message le plus ancien }
  Index := 0;
  For I := 1 To CachedMessageCount - 1 Do Begin
   If CachedMessages^[I].CacheTime < CachedMessages^[Index].CacheTime Then
    Index := I;
  End;
 End
 Else If Index < 0 Then Begin
  Index := CachedMessageCount;
  Inc(CachedMessageCount);
 End;

 { Mettre a jour le cache }
 CachedMessages^[Index].MsgID := Msg.MsgID;
 CachedMessages^[Index].FolderName := 'INBOX'; { TODO: dossier actuel }
 CachedMessages^[Index].FromName := Msg.FromName;
 CachedMessages^[Index].FromEmail := Msg.FromEmail;
 CachedMessages^[Index].Subject := Msg.Subject;
 CachedMessages^[Index].DateSort := Msg.DateSort;
 CachedMessages^[Index].Size := Msg.Size;
 CachedMessages^[Index].IsRead := Msg.IsRead;
 CachedMessages^[Index].IsFlagged := Msg.IsFlagged;
 CachedMessages^[Index].HasAttachment := Msg.HasAttachment;
 CachedMessages^[Index].CacheTime := GetTickCount Div 1000;
 CachedMessages^[Index].IsDirty := False;

 Offline_CacheMessage := True;
End;

{ Trouve un message dans le cache }
Function Offline_FindCachedMessage(MsgID: String; Var Index: Integer): Boolean;
Var
 I: Integer;
Begin
 Offline_FindCachedMessage := False;
 Index := -1;

 For I := 0 To CachedMessageCount - 1 Do Begin
  If CachedMessages^[I].MsgID = MsgID Then Begin
   Index := I;
   Offline_FindCachedMessage := True;
   Exit;
  End;
 End;
End;

{ Ajoute un dossier au cache }
Function Offline_CacheFolder(Name, ParentName: String; MsgCount, UnreadCount: Integer): Boolean;
Var
 I, Index: Integer;
Begin
 Offline_CacheFolder := False;

 { Chercher si le dossier existe deja }
 Index := -1;
 For I := 0 To CachedFolderCount - 1 Do Begin
  If CachedFolders[I].Name = Name Then Begin
   Index := I;
   Break;
  End;
 End;

 If (Index < 0) And (CachedFolderCount >= MAX_CACHED_FOLDERS) Then Begin
  { Pas de place }
  Exit;
 End
 Else If Index < 0 Then Begin
  Index := CachedFolderCount;
  Inc(CachedFolderCount);
 End;

 CachedFolders[Index].Name := Name;
 CachedFolders[Index].ParentName := ParentName;
 CachedFolders[Index].MessageCount := MsgCount;
 CachedFolders[Index].UnreadCount := UnreadCount;
 CachedFolders[Index].LastSync := GetTickCount Div 1000;
 CachedFolders[Index].IsDirty := False;

 Offline_CacheFolder := True;
End;

{ Sauvegarde le cache sur disque }
Procedure Offline_SaveCache;
Var
 F: File of Byte;
 B: Byte;
 I, J: Integer;
Begin
 {$I-}
 Assign(F, CACHE_FILENAME);
 Rewrite(F);
 If IOResult <> 0 Then Exit;

 { Version }
 B := CACHE_VERSION;
 Write(F, B);

 { Nombre de messages en cache }
 B := CachedMessageCount And $FF;
 Write(F, B);
 B := (CachedMessageCount Shr 8) And $FF;
 Write(F, B);

 { Sauvegarder les messages }
 For I := 0 To CachedMessageCount - 1 Do Begin
  { MsgID }
  B := Length(CachedMessages^[I].MsgID);
  Write(F, B);
  For J := 1 To Length(CachedMessages^[I].MsgID) Do Begin
   B := Ord(CachedMessages^[I].MsgID[J]);
   Write(F, B);
  End;

  { FolderName }
  B := Length(CachedMessages^[I].FolderName);
  Write(F, B);
  For J := 1 To Length(CachedMessages^[I].FolderName) Do Begin
   B := Ord(CachedMessages^[I].FolderName[J]);
   Write(F, B);
  End;

  { FromName }
  B := Length(CachedMessages^[I].FromName);
  Write(F, B);
  For J := 1 To Length(CachedMessages^[I].FromName) Do Begin
   B := Ord(CachedMessages^[I].FromName[J]);
   Write(F, B);
  End;

  { Subject }
  B := Length(CachedMessages^[I].Subject);
  Write(F, B);
  For J := 1 To Length(CachedMessages^[I].Subject) Do Begin
   B := Ord(CachedMessages^[I].Subject[J]);
   Write(F, B);
  End;

  { Flags }
  B := 0;
  If CachedMessages^[I].IsRead Then B := B Or 1;
  If CachedMessages^[I].IsFlagged Then B := B Or 2;
  If CachedMessages^[I].HasAttachment Then B := B Or 4;
  If CachedMessages^[I].IsDirty Then B := B Or 8;
  Write(F, B);
 End;

 { Nombre de dossiers }
 B := CachedFolderCount;
 Write(F, B);

 { Sauvegarder les dossiers }
 For I := 0 To CachedFolderCount - 1 Do Begin
  B := Length(CachedFolders[I].Name);
  Write(F, B);
  For J := 1 To Length(CachedFolders[I].Name) Do Begin
   B := Ord(CachedFolders[I].Name[J]);
   Write(F, B);
  End;

  B := CachedFolders[I].MessageCount And $FF;
  Write(F, B);
  B := (CachedFolders[I].MessageCount Shr 8) And $FF;
  Write(F, B);

  B := CachedFolders[I].UnreadCount And $FF;
  Write(F, B);
  B := (CachedFolders[I].UnreadCount Shr 8) And $FF;
  Write(F, B);
 End;

 Close(F);
 {$I+}
End;

{ Charge le cache depuis le disque }
Function Offline_LoadCache: Boolean;
Var
 F: File of Byte;
 B, B2: Byte;
 I, J, Len: Integer;
Begin
 Offline_LoadCache := False;

 {$I-}
 Assign(F, CACHE_FILENAME);
 Reset(F);
 If IOResult <> 0 Then Exit;

 { Verifier la version }
 Read(F, B);
 If B > CACHE_VERSION Then Begin
  Close(F);
  Exit;
 End;

 { Nombre de messages }
 Read(F, B);
 Read(F, B2);
 CachedMessageCount := B Or (B2 Shl 8);
 If CachedMessageCount > MAX_CACHED_MESSAGES Then
  CachedMessageCount := MAX_CACHED_MESSAGES;

 { Charger les messages }
 For I := 0 To CachedMessageCount - 1 Do Begin
  { MsgID }
  Read(F, B);
  Len := B;
  CachedMessages^[I].MsgID := '';
  For J := 1 To Len Do Begin
   Read(F, B);
   CachedMessages^[I].MsgID := CachedMessages^[I].MsgID + Chr(B);
  End;

  { FolderName }
  Read(F, B);
  Len := B;
  CachedMessages^[I].FolderName := '';
  For J := 1 To Len Do Begin
   Read(F, B);
   CachedMessages^[I].FolderName := CachedMessages^[I].FolderName + Chr(B);
  End;

  { FromName }
  Read(F, B);
  Len := B;
  CachedMessages^[I].FromName := '';
  For J := 1 To Len Do Begin
   Read(F, B);
   CachedMessages^[I].FromName := CachedMessages^[I].FromName + Chr(B);
  End;

  { Subject }
  Read(F, B);
  Len := B;
  CachedMessages^[I].Subject := '';
  For J := 1 To Len Do Begin
   Read(F, B);
   CachedMessages^[I].Subject := CachedMessages^[I].Subject + Chr(B);
  End;

  { Flags }
  Read(F, B);
  CachedMessages^[I].IsRead := (B And 1) <> 0;
  CachedMessages^[I].IsFlagged := (B And 2) <> 0;
  CachedMessages^[I].HasAttachment := (B And 4) <> 0;
  CachedMessages^[I].IsDirty := (B And 8) <> 0;
 End;

 { Nombre de dossiers }
 Read(F, B);
 CachedFolderCount := B;
 If CachedFolderCount > MAX_CACHED_FOLDERS Then
  CachedFolderCount := MAX_CACHED_FOLDERS;

 { Charger les dossiers }
 For I := 0 To CachedFolderCount - 1 Do Begin
  Read(F, B);
  Len := B;
  CachedFolders[I].Name := '';
  For J := 1 To Len Do Begin
   Read(F, B);
   CachedFolders[I].Name := CachedFolders[I].Name + Chr(B);
  End;

  Read(F, B);
  Read(F, B2);
  CachedFolders[I].MessageCount := B Or (B2 Shl 8);

  Read(F, B);
  Read(F, B2);
  CachedFolders[I].UnreadCount := B Or (B2 Shl 8);
 End;

 Close(F);
 {$I+}

 Offline_LoadCache := True;
End;

{ Sauvegarde la file d'attente }
Procedure Offline_SaveQueue;
Var
 F: File of Byte;
 B: Byte;
 I, J: Integer;
Begin
 {$I-}
 Assign(F, QUEUE_FILENAME);
 Rewrite(F);
 If IOResult <> 0 Then Exit;

 { Nombre d'operations }
 B := QueuedOpCount;
 Write(F, B);

 For I := 0 To QueuedOpCount - 1 Do Begin
  { Type d'operation }
  B := Ord(QueuedOps[I].OpType);
  Write(F, B);

  { Etat }
  B := Ord(QueuedOps[I].State);
  Write(F, B);

  { MessageID }
  B := Length(QueuedOps[I].MessageID);
  Write(F, B);
  For J := 1 To Length(QueuedOps[I].MessageID) Do Begin
   B := Ord(QueuedOps[I].MessageID[J]);
   Write(F, B);
  End;

  { TargetFolder }
  B := Length(QueuedOps[I].TargetFolder);
  Write(F, B);
  For J := 1 To Length(QueuedOps[I].TargetFolder) Do Begin
   B := Ord(QueuedOps[I].TargetFolder[J]);
   Write(F, B);
  End;

  { RetryCount }
  B := QueuedOps[I].RetryCount;
  Write(F, B);

  { Priority }
  B := QueuedOps[I].Priority;
  Write(F, B);
 End;

 Close(F);
 {$I+}
End;

{ Charge la file d'attente }
Function Offline_LoadQueue: Boolean;
Var
 F: File of Byte;
 B: Byte;
 I, J, Len: Integer;
Begin
 Offline_LoadQueue := False;

 {$I-}
 Assign(F, QUEUE_FILENAME);
 Reset(F);
 If IOResult <> 0 Then Exit;

 Read(F, B);
 QueuedOpCount := B;
 If QueuedOpCount > MAX_QUEUED_OPS Then
  QueuedOpCount := MAX_QUEUED_OPS;

 For I := 0 To QueuedOpCount - 1 Do Begin
  Read(F, B);
  QueuedOps[I].OpType := TQueuedOpType(B);

  Read(F, B);
  QueuedOps[I].State := TQueuedOpState(B);

  Read(F, B);
  Len := B;
  QueuedOps[I].MessageID := '';
  For J := 1 To Len Do Begin
   Read(F, B);
   QueuedOps[I].MessageID := QueuedOps[I].MessageID + Chr(B);
  End;

  Read(F, B);
  Len := B;
  QueuedOps[I].TargetFolder := '';
  For J := 1 To Len Do Begin
   Read(F, B);
   QueuedOps[I].TargetFolder := QueuedOps[I].TargetFolder + Chr(B);
  End;

  Read(F, B);
  QueuedOps[I].RetryCount := B;

  Read(F, B);
  QueuedOps[I].Priority := B;

  QueuedOps[I].QueuedTime := GetTickCount Div 1000;
  QueuedOps[I].LastError := '';
 End;

 Close(F);
 {$I+}

 Offline_LoadQueue := True;
End;

{ Demarre la synchronisation }
Procedure Offline_StartSync;
Begin
 If SyncInProgress Then Exit;
 If ConnectionState <> csOnline Then Exit;

 SyncInProgress := True;
 SyncProgress := 0;
 ConnectionState := csSynchronizing;

 { Reinitialiser les statistiques }
 FillChar(LastSyncStats, SizeOf(TSyncStats), 0);
 LastSyncStats.StartTime := GetTickCount Div 1000;

 SyncStatusText := 'Connexion au serveur...';
End;

{ Execute une etape de synchronisation }
Procedure Offline_SyncStep;
Begin
 If Not SyncInProgress Then Exit;

 { Etape 1: Traiter la file d'attente (0-30%) }
 If SyncProgress < 30 Then Begin
  SyncStatusText := 'Envoi des operations en attente...';
  Offline_ProcessQueue;
  SyncProgress := 30;
  Exit;
 End;

 { Etape 2: Synchroniser les dossiers (30-50%) }
 If SyncProgress < 50 Then Begin
  SyncStatusText := 'Synchronisation des dossiers...';
  { TODO: Synchroniser la liste des dossiers }
  SyncProgress := 50;
  Exit;
 End;

 { Etape 3: Recuperer les nouveaux messages (50-90%) }
 If SyncProgress < 90 Then Begin
  SyncStatusText := 'Recuperation des nouveaux messages...';
  { TODO: Telecharger les nouveaux messages }
  SyncProgress := 90;
  Exit;
 End;

 { Etape 4: Finalisation (90-100%) }
 If SyncProgress < 100 Then Begin
  SyncStatusText := 'Finalisation...';

  { Sauvegarder le cache }
  Offline_SaveCache;

  SyncProgress := 100;
  LastSyncStats.EndTime := GetTickCount Div 1000;
  SyncInProgress := False;
  ConnectionState := csOnline;
  SyncStatusText := 'Synchronisation terminee';
 End;
End;

{ Arrete la synchronisation }
Procedure Offline_StopSync;
Begin
 If Not SyncInProgress Then Exit;

 SyncInProgress := False;
 ConnectionState := csOnline;
 SyncStatusText := 'Synchronisation annulee';
End;

{ Dessine l'indicateur de connexion }
Procedure Offline_DrawStatusIndicator;
Var
 X, Y: Integer;
 StatusColor: Word;
 StatusText: String;
 CurrentTime: LongInt;
Begin
 If Not StatusIndicatorVisible Then Exit;

 { Position dans la barre d'etat }
 X := GGetMaxX - 120;
 Y := GGetMaxY - 18;

 { Determiner la couleur }
 Case ConnectionState Of
  csOnline: StatusColor := Green;
  csOffline: StatusColor := Red;
  csConnecting: StatusColor := Yellow;
  csDisconnecting: StatusColor := Yellow;
  csSynchronizing: Begin
   { Clignotement pendant la sync }
   CurrentTime := GetTickCount Div 500;
   If (CurrentTime And 1) = 0 Then
    StatusColor := Yellow
   Else
    StatusColor := Green;
  End;
  Else StatusColor := LightGray;
 End;

 { Dessiner le cercle indicateur }
 GSetColor(StatusColor);
 GSetFillStyle(SolidFill, StatusColor);
 GFillEllipse(X + 8, Y + 8, 6, 6);
 GSetColor(DarkGray);
 GEllipse(X + 8, Y + 8, 0, 360, 6, 6);

 { Texte d'etat }
 StatusText := Offline_GetStatusText;
 If SyncInProgress Then Begin
  Str(SyncProgress, StatusText);
  StatusText := 'Sync: ' + StatusText + '%';
 End;

 GSetColor(Black);
 GOutTextXY(X + 20, Y + 3, StatusText);
End;

{ Gere le clic sur l'indicateur de connexion }
Procedure Offline_HandleStatusClick(MX, MY: Integer);
Var
 X, Y: Integer;
Begin
 X := GGetMaxX - 120;
 Y := GGetMaxY - 18;

 { Verifier si le clic est sur l'indicateur }
 If (MX >= X) And (MX <= X + 100) And (MY >= Y) And (MY <= Y + 16) Then Begin
  { Basculer le mode }
  If ConnectionState = csOnline Then
   Offline_GoOffline
  Else If ConnectionState = csOffline Then
   Offline_GoOnline;
 End;
End;

{ Retourne le nombre d'operations en attente }
Function Offline_GetPendingCount: Integer;
Var
 I, Count: Integer;
Begin
 Count := 0;
 For I := 0 To QueuedOpCount - 1 Do Begin
  If QueuedOps[I].State = qosWaiting Then
   Inc(Count);
 End;
 Offline_GetPendingCount := Count;
End;

{ Retourne True si en mode hors ligne }
Function Offline_IsOffline: Boolean;
Begin
 Offline_IsOffline := (ConnectionState = csOffline);
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DU MODE HORS LIGNE ET SYNCHRONISATION (TODO 24)
  ============================================================================ }

{ ============================================================================
  IMPLEMENTATION DU SUPPORT MULTI-LANGUE (TODO 25)
  ============================================================================ }

{ Retourne la chaine traduite pour un identifiant }
Function Lang_GetString(SID: TStringID): String;
Var
 Index: Integer;
Begin
 Index := Ord(SID);
 If (Index < 0) Or (Index >= MAX_STRING_IDS) Then Begin
  Lang_GetString := '';
  Exit;
 End;

 { Utiliser les chaines personnalisees si disponibles }
 If UseCustomStrings And (CustomStrings[Index] <> '') Then Begin
  Lang_GetString := CustomStrings[Index];
  Exit;
 End;

 { Sinon utiliser les traductions integrees }
 Case CurrentLanguage Of
  langFrench: Lang_GetString := STRINGS_FR[Index];
  langEnglish: Lang_GetString := STRINGS_EN[Index];
  langGerman: Lang_GetString := STRINGS_DE[Index];
  langItalian: Lang_GetString := STRINGS_IT[Index];
  langSpanish: Lang_GetString := STRINGS_ES[Index];
  langPortuguese: Lang_GetString := STRINGS_PT[Index];
  langSwedish: Lang_GetString := STRINGS_SV[Index];
  langDanish: Lang_GetString := STRINGS_DA[Index];
  langJapanese: Lang_GetString := STRINGS_JA[Index];
  langAlbanian: Lang_GetString := STRINGS_SQ[Index];
  Else Lang_GetString := STRINGS_FR[Index];
 End;
End;

{ Alias court pour obtenir une chaine }
Function _T(SID: TStringID): String;
Begin
 _T := Lang_GetString(SID);
End;

{ Detecte la langue depuis la variable d'environnement LANGUAGE }
Function Lang_DetectFromEnv: TLanguage;
Var
 LangEnv: String;
 I: Integer;
Begin
 Lang_DetectFromEnv := langFrench; { Par defaut }

 
 LangEnv := GetEnv('LANGUAGE');
 If LangEnv = '' Then
  LangEnv := GetEnv('LANG');
 

 If LangEnv = '' Then Exit;

 { Convertir en majuscules }
 For I := 1 To Length(LangEnv) Do
  If (LangEnv[I] >= 'a') And (LangEnv[I] <= 'z') Then
   LangEnv[I] := Chr(Ord(LangEnv[I]) - 32);

 { Verifier les codes de langue }
 If (Pos('EN', LangEnv) = 1) Or (Pos('US', LangEnv) > 0) Or
    (Pos('GB', LangEnv) > 0) Then
  Lang_DetectFromEnv := langEnglish
 Else If (Pos('DE', LangEnv) = 1) Or (Pos('GR', LangEnv) = 1) Or
         (Pos('GE', LangEnv) > 0) Then
  Lang_DetectFromEnv := langGerman
 Else If Pos('IT', LangEnv) = 1 Then
  Lang_DetectFromEnv := langItalian
 Else If (Pos('ES', LangEnv) = 1) Or (Pos('SP', LangEnv) = 1) Then
  Lang_DetectFromEnv := langSpanish
 Else If (Pos('PT', LangEnv) = 1) Or (Pos('PRT', LangEnv) > 0) Or
         (Pos('BR', LangEnv) > 0) Then
  Lang_DetectFromEnv := langPortuguese
 Else If (Pos('SV', LangEnv) = 1) Or (Pos('SE', LangEnv) = 1) Or
         (Pos('SWE', LangEnv) > 0) Then
  Lang_DetectFromEnv := langSwedish
 Else If (Pos('DA', LangEnv) = 1) Or (Pos('DK', LangEnv) = 1) Or
         (Pos('DNK', LangEnv) > 0) Then
  Lang_DetectFromEnv := langDanish
 Else If (Pos('JA', LangEnv) = 1) Or (Pos('JP', LangEnv) = 1) Or
         (Pos('JPN', LangEnv) > 0) Then
  Lang_DetectFromEnv := langJapanese
 Else If (Pos('SQ', LangEnv) = 1) Or (Pos('ALB', LangEnv) > 0) Or
         (Pos('AL', LangEnv) = 1) Then
  Lang_DetectFromEnv := langAlbanian
 Else If Pos('FR', LangEnv) = 1 Then
  Lang_DetectFromEnv := langFrench;
End;

{ Definit la langue courante }
Procedure Lang_SetLanguage(NewLang: TLanguage);
Begin
 CurrentLanguage := NewLang;
End;

{ Retourne la langue courante }
Function Lang_GetLanguage: TLanguage;
Begin
 Lang_GetLanguage := CurrentLanguage;
End;

{ Retourne le code de la langue courante }
Function Lang_GetCode: String;
Begin
 Lang_GetCode := LANG_CODES[CurrentLanguage];
End;

{ Retourne le nom de la langue courante }
Function Lang_GetName: String;
Begin
 Lang_GetName := LANG_NAMES[CurrentLanguage];
End;

{ Charge un fichier de langue }
Function Lang_LoadFile(Filename: String): Boolean;
Var
 F: Text;
 Line: String;
 Index, P: Integer;
 Key, Value: String;
Begin
 Lang_LoadFile := False;

 {$I-}
 Assign(F, Filename);
 Reset(F);
 If IOResult <> 0 Then Exit;

 UseCustomStrings := False;
 Index := 0;

 While Not Eof(F) And (Index < MAX_STRING_IDS) Do Begin
  ReadLn(F, Line);

  { Ignorer les commentaires et lignes vides }
  If (Length(Line) = 0) Or (Line[1] = ';') Or (Line[1] = '#') Then
   Continue;

  { Format: CLE=VALEUR ou simplement VALEUR (une par ligne) }
  P := Pos('=', Line);
  If P > 0 Then Begin
   { Format CLE=VALEUR }
   Key := Copy(Line, 1, P - 1);
   Value := Copy(Line, P + 1, Length(Line) - P);

   { Chercher l'index de la cle }
   { Pour simplifier, on utilise l'index numerique }
   Val(Key, Index, P);
   If (P = 0) And (Index >= 0) And (Index < MAX_STRING_IDS) Then Begin
    CustomStrings[Index] := Value;
   End;
  End
  Else Begin
   { Format sequentiel }
   CustomStrings[Index] := Line;
   Inc(Index);
  End;
 End;

 Close(F);
 {$I+}

 If IOResult = 0 Then Begin
  UseCustomStrings := True;
  LanguageFilePath := Filename;
  Lang_LoadFile := True;
 End;
End;

{ Sauvegarde les chaines dans un fichier de langue }
Function Lang_SaveFile(Filename: String): Boolean;
Var
 F: Text;
 I: Integer;
Begin
 Lang_SaveFile := False;

 {$I-}
 Assign(F, Filename);
 Rewrite(F);
 If IOResult <> 0 Then Exit;

 WriteLn(F, '; Fichier de langue pour Outlink');
 WriteLn(F, '; Langue: ' + LANG_NAMES[CurrentLanguage]);
 WriteLn(F, '; Code: ' + LANG_CODES[CurrentLanguage]);
 WriteLn(F, ';');
 WriteLn(F, '; Format: INDEX=TEXTE');
 WriteLn(F, '');

 For I := 0 To MAX_STRING_IDS - 1 Do Begin
  If UseCustomStrings And (CustomStrings[I] <> '') Then
   WriteLn(F, I, '=', CustomStrings[I])
  Else
   WriteLn(F, I, '=', Lang_GetString(TStringID(I)));
 End;

 Close(F);
 {$I+}

 Lang_SaveFile := (IOResult = 0);
End;

{ Charge automatiquement le fichier de langue si disponible }
Procedure Lang_AutoLoadFile;
Var
 Filename: String;
Begin
 Filename := 'OUTLOOK_' + LANG_CODES[CurrentLanguage] + LANG_FILE_EXT;
 If Lang_LoadFile(Filename) Then Exit;

 { Essayer avec le chemin complet }
 Filename := 'LANG\OUTLOOK_' + LANG_CODES[CurrentLanguage] + LANG_FILE_EXT;
 Lang_LoadFile(Filename);
End;

{ Initialise le systeme de traduction }
Procedure Lang_Init;
Var
 I: Integer;
Begin
 { Initialiser les chaines personnalisees }
 For I := 0 To MAX_STRING_IDS - 1 Do
  CustomStrings[I] := '';

 UseCustomStrings := False;
 LanguageFilePath := '';

 { Detecter la langue depuis l'environnement }
 CurrentLanguage := Lang_DetectFromEnv;

 { Essayer de charger un fichier de langue }
 Lang_AutoLoadFile;
End;

{ Retourne la liste des langues disponibles }
Function Lang_GetAvailableCount: Integer;
Begin
 Lang_GetAvailableCount := Ord(High(TLanguage)) + 1;
End;

{ Retourne le nom d'une langue par index }
Function Lang_GetNameByIndex(Index: Integer): String;
Begin
 If (Index >= 0) And (Index <= Ord(High(TLanguage))) Then
  Lang_GetNameByIndex := LANG_NAMES[TLanguage(Index)]
 Else
  Lang_GetNameByIndex := '';
End;

{ Retourne le code d'une langue par index }
Function Lang_GetCodeByIndex(Index: Integer): String;
Begin
 If (Index >= 0) And (Index <= Ord(High(TLanguage))) Then
  Lang_GetCodeByIndex := LANG_CODES[TLanguage(Index)]
 Else
  Lang_GetCodeByIndex := '';
End;

{ Definit la langue par son code }
Function Lang_SetByCode(Code: String): Boolean;
Var
 I: Integer;
 UpCode: String;
Begin
 Lang_SetByCode := False;
 UpCode := Code;

 { Convertir en majuscules }
 For I := 1 To Length(UpCode) Do
  If (UpCode[I] >= 'a') And (UpCode[I] <= 'z') Then
   UpCode[I] := Chr(Ord(UpCode[I]) - 32);

 { Chercher le code }
 For I := 0 To Ord(High(TLanguage)) Do Begin
  If LANG_CODES[TLanguage(I)] = UpCode Then Begin
   CurrentLanguage := TLanguage(I);
   Lang_AutoLoadFile;
   Lang_SetByCode := True;
   Exit;
  End;
 End;
End;

{ ============================================================================
  FIN DE L'IMPLEMENTATION DU SUPPORT MULTI-LANGUE (TODO 25)
  ============================================================================ }

{ En-tetes RFC 5322 avec lignes repliees. }
Function MailHeader(Const Raw, Name: TMailText): TMailText;
Var P, Q, StopAt: LongInt; Line, Key, Value: TMailText;
Begin
 MailHeader:=''; Key:=''; Value:=''; P:=1;
 StopAt:=Pos(#13#10#13#10,Raw); If StopAt=0 Then StopAt:=Length(Raw)+1;
 While P<StopAt Do Begin
  Q:=P; While (Q<StopAt) And (Raw[Q]<>#13) Do Inc(Q);
  Line:=Copy(Raw,P,Q-P); P:=Q+2;
  If (Line<>'') And (Line[1] In [' ',#9]) Then Value:=Value+' '+MailTrim(Line)
  Else Begin
   If MailUpper(Key)=MailUpper(Name) Then Begin MailHeader:=Value; Exit; End;
   Q:=Pos(':',Line); Key:=Copy(Line,1,Q-1); Value:=MailTrim(Copy(Line,Q+1,Length(Line)));
  End;
 End;
 If MailUpper(Key)=MailUpper(Name) Then MailHeader:=Value;
End;

Function MailDecodeData(Const Data, Encoding: TMailText): TMailText;
Const Alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
Var I, V, Bits, Acc, Code: LongInt; Hex: String;
Var MailDecodeData_R: TMailText;
Begin
 MailDecodeData_R:='';
 If Pos('BASE64',MailUpper(Encoding))>0 Then Begin
  Acc:=0; Bits:=0;
  For I:=1 To Length(Data) Do Begin
   V:=Pos(Data[I],Alphabet)-1;
   If V>=0 Then Begin
    Acc:=((Acc Shl 6) Or V) And $FFFFFF; Inc(Bits,6);
    If Bits>=8 Then Begin Dec(Bits,8); MailDecodeData_R:=MailDecodeData_R+Chr((Acc Shr Bits) And 255); End;
   End;
  End;
 End Else If Pos('QUOTED-PRINTABLE',MailUpper(Encoding))>0 Then Begin
  I:=1;
  While I<=Length(Data) Do Begin
   If (Data[I]='=') And (I+2<=Length(Data)) Then Begin
    If Copy(Data,I+1,2)=#13#10 Then Inc(I,3)
    Else Begin
     Hex:='$'+Copy(Data,I+1,2); Val(Hex,V,Code);
     If Code=0 Then Begin MailDecodeData_R:=MailDecodeData_R+Chr(V); Inc(I,3); End
     Else Begin MailDecodeData_R:=MailDecodeData_R+Data[I]; Inc(I); End;
    End;
   End Else Begin MailDecodeData_R:=MailDecodeData_R+Data[I]; Inc(I); End;
  End;
 End Else MailDecodeData_R:=Data;
 MailDecodeData := MailDecodeData_R;
End;

{ Parcourir MIME pour afficher la partie texte, sans creer de faux contenu. }
Function MailTextBody(Const Raw: TMailText; Depth: Integer): TMailText;
Var P, Q, R: LongInt; ContentType, Boundary, Body, Part, Candidate, Fallback: TMailText;
 Quoted, InTag: Boolean;
Begin
 MailTextBody:=''; If Depth>8 Then Exit;
 P:=Pos(#13#10#13#10,Raw); If P=0 Then Exit;
 Body:=Copy(Raw,P+4,Length(Raw)); ContentType:=MailHeader(Raw,'Content-Type');
 If Pos('MULTIPART/',MailUpper(ContentType))=1 Then Begin
  P:=Pos('BOUNDARY=',MailUpper(ContentType)); If P=0 Then Exit;
  Boundary:=MailTrim(Copy(ContentType,P+9,Length(ContentType)));
  Quoted:=(Boundary<>'') And (Boundary[1]='"');
  If Quoted Then Begin Delete(Boundary,1,1); P:=Pos('"',Boundary); End
  Else P:=Pos(';',Boundary);
  If P>0 Then Boundary:=Copy(Boundary,1,P-1);
  If Boundary='' Then Exit;
  Boundary:='--'+Boundary; P:=Pos(Boundary+#13#10,Body); Fallback:='';
  While P>0 Do Begin
   Delete(Body,1,P+Length(Boundary)+1); Q:=Pos(#13#10+Boundary,Body);
   If Q=0 Then Break;
   Part:=Copy(Body,1,Q-1);
   If Pos('ATTACHMENT',MailUpper(MailHeader(Part,'Content-Disposition')))=0 Then Begin
    Candidate:=MailTextBody(Part,Depth+1);
    If Pos('TEXT/PLAIN',MailUpper(MailHeader(Part,'Content-Type')))=1 Then Begin
     MailTextBody:=Candidate; Exit;
    End;
    If Fallback='' Then Fallback:=Candidate;
   End;
   Delete(Body,1,Q+1);
   If Copy(Body,Length(Boundary)+1,2)='--' Then Break;
   P:=Pos(Boundary+#13#10,Body);
  End;
  MailTextBody:=Fallback; Exit;
 End;
 If (ContentType<>'') And (Pos('TEXT/',MailUpper(ContentType))<>1) Then Exit;
 Body:=MailDecodeData(Body,MailHeader(Raw,'Content-Transfer-Encoding'));
 If Pos('TEXT/HTML',MailUpper(ContentType))=1 Then Begin
  Candidate:=''; InTag:=False;
  For R:=1 To Length(Body) Do Begin
   If Body[R]='<' Then Begin InTag:=True; Candidate:=Candidate+' '; End
   Else If Body[R]='>' Then InTag:=False
   Else If Not InTag Then Candidate:=Candidate+Body[R];
  End;
  Body:=Candidate;
 End;
 MailTextBody:=Body;
End;

Procedure MailParseMessage(Const Raw, ID: TMailText; Var Msg: TMessage);
Var Value, Body, Line: TMailText; P, Q, I, N: LongInt;
Begin
 FillChar(Msg,SizeOf(Msg),0); Msg.MsgID:=Copy(ID,1,20); Msg.Priority:=mpNormal;
 Value:=MailHeader(Raw,'From'); P:=Pos('<',Value); Q:=Pos('>',Value);
 If (P>0) And (Q>P) Then Begin
  Msg.FromName:=MIME_DecodeHeader(Copy(MailTrim(Copy(Value,1,P-1)),1,255));
  Msg.FromEmail:=Copy(Value,P+1,Q-P-1);
 End Else Begin Msg.FromEmail:=Copy(Value,1,60); Msg.FromName:=Msg.FromEmail; End;
 If Msg.FromName='' Then Msg.FromName:=Msg.FromEmail;
 Msg.ToEmail:=Copy(MailHeader(Raw,'To'),1,60);
 Msg.CcEmail:=Copy(MailHeader(Raw,'Cc'),1,80);
 Msg.Subject:=MIME_DecodeHeader(Copy(MailHeader(Raw,'Subject'),1,255));
 Msg.DateFull:=Copy(MailHeader(Raw,'Date'),1,25); Msg.DateStr:=OlShortDate(MailHeader(Raw,'Date'));
 Msg.Size:=Length(Raw);
 Msg.HasAttachment:=(Pos('ATTACHMENT',MailUpper(Raw))>0);
 Body:=MailTextBody(Raw,0); P:=1; I:=0;
 While (P<=Length(Body)) And (I<20) Do Begin
  Q:=P; While (Q<=Length(Body)) And Not (Body[Q] In [#13,#10]) Do Inc(Q);
  Line:=Copy(Body,P,Q-P);
  Repeat
   N:=Length(Line); If N>80 Then N:=80;
   Msg.Body[I]:=Copy(Line,1,N); Inc(I); Delete(Line,1,N);
  Until (Line='') Or (I=20);
  P:=Q+1; If (Q<Length(Body)) And (Body[Q]=#13) And (Body[Q+1]=#10) Then Inc(P);
 End;
 Msg.BodyLineCount:=I;
End;


{ ====================================================================== }
{  OS/2-0 : messages complets dans les grands tampons (version DOS :     }
{  chaines de 255 caracteres)                                            }
{ ====================================================================== }

{ en-tete decode (mots MIME) et converti en page de codes 850 }
Function OlHeaderText(Raw : String) : String;
Var V, U : String; K : LongInt; High : Boolean;
Begin
 V := MIME_DecodeHeader(Raw);
 U := OlUp(Raw);
 High := False;
 For K := 1 To Length(Raw) Do If Ord(Raw[K]) >= 128 Then High := True;
 { mots MIME (=?...?=) : convertis par MIME_DecodeHeader ; en-tete brut en UTF-8 }
 If High And (Pos('=?', Raw) = 0) Then V := OlConvStr(V, True);
 OlHeaderText := V;
End;

{ MailParseMessage sur B[0..L[ : en-tetes et 20 lignes de 80 caracteres }
Procedure MailParseBig(B : PFbArr; L : LongInt; Const ID : TMailText; Var Msg : TMessage);
Var Value, Line : String; P, Q, I, N, K : LongInt;
Begin
 FillChar(Msg, SizeOf(Msg), 0); Msg.MsgID := Copy(ID, 1, 20); Msg.Priority := mpNormal;
 Value := OlHdr(B, 0, L, 'From'); P := Pos('<', Value); Q := Pos('>', Value);
 If (P > 0) And (Q > P) Then
 Begin
  Line := MailTrim(Copy(Value, 1, P - 1));
  If (Line <> '') And (Line[1] = '"') Then Delete(Line, 1, 1);
  If (Line <> '') And (Line[Length(Line)] = '"') Then Delete(Line, Length(Line), 1);
  Msg.FromName := OlHeaderText(Line);
  Msg.FromEmail := Copy(Value, P + 1, Q - P - 1);
 End
 Else
 Begin
  Msg.FromEmail := Copy(Value, 1, 60); Msg.FromName := Msg.FromEmail;
 End;
 If Msg.FromName = '' Then Msg.FromName := Msg.FromEmail;
 Msg.ToEmail := Copy(OlHdr(B, 0, L, 'To'), 1, 60);
 Msg.CcEmail := Copy(OlHdr(B, 0, L, 'Cc'), 1, 80);
 Msg.Subject := OlHeaderText(OlHdr(B, 0, L, 'Subject'));
 Msg.DateFull := Copy(OlHdr(B, 0, L, 'Date'), 1, 25); Msg.DateStr := OlShortDate(OlHdr(B, 0, L, 'Date'));
 Msg.Size := L;
 Msg.HasAttachment := Pos('ATTACHMENT', OlUp(OlHdr(B, 0, L, 'Content-Type'))) > 0;
 If Not Msg.HasAttachment Then
  Msg.HasAttachment := (OlFind(B, 0, L, 'attachment') >= 0) Or (OlFind(B, 0, L, 'ATTACHMENT') >= 0) Or
                       (OlFind(B, 0, L, 'Attachment') >= 0);
 OlMessageText(B, L);
 P := 0; I := 0;
 While (P < OlTxLen) And (I < 20) Do
 Begin
  Q := P;
  While (Q < OlTxLen) And (OlTx[Q] <> 10) Do Inc(Q);
  Line := '';
  For K := P To Q - 1 Do If Length(Line) < 255 Then Line := Line + Chr(OlTx[K]);
  Repeat
   N := Length(Line);
   If N > 80 Then N := 80;
   Msg.Body[I] := Copy(Line, 1, N); Inc(I); Delete(Line, 1, N);
  Until (Line = '') Or (I = 20);
  P := Q + 1;
 End;
 Msg.BodyLineCount := I;
End;

{ fichier .eml -> tampon de reception (OlIn) }
Function OlLoadFile(FileName : String) : Boolean;
Var F : File; Size, Got : LongInt; Old : Byte;
Begin
 OlLoadFile := False; OlInLen := 0;
 {$I-}
 Assign(F, FileName); Old := FileMode; FileMode := 0; Reset(F, 1); FileMode := Old;
 If IOResult <> 0 Then Exit;
 Size := FileSize(F);
 If (IOResult = 0) And (Size > 0) And (Size <= OlInCap) Then
 Begin
  BlockRead(F, OlIn^[0], Size, Got);
  If (IOResult = 0) And (Got = Size) Then
  Begin
   OlInLen := Size;
   OlLoadFile := True;
  End;
 End;
 Close(F);
 If IOResult <> 0 Then OlLoadFile := False;
 {$I+}
End;

{ Accepter les fins de ligne LF des fichiers exportes sur d autres systemes. }
Function NormalizeMessageLines(Const Raw: TMailText): TMailText;

Begin
 
 NormalizeMessageLines := Raw;
 
End;

{ Ne modifier la vue que lorsque le fichier a ete entierement lu et valide. }
Function LoadMessageFile(FileName: TMailText): Boolean;
Var OpenedMessage: TMessage; I: Integer; K: LongInt;
Begin
 LoadMessageFile := False;
 If (FileName = '') Or (Length(FileName) > 255) Then Begin
  MailStatus := 'Erreur: chemin du courriel vide ou trop long'; Exit;
 End;
 If Not OlLoadFile(FileName) Then Begin
  MailStatus := 'Erreur: lecture impossible, fichier vide ou plus de 2 Mo'; Exit;
 End;
 If (OlInLen >= 3) And (OlIn^[0] = $EF) And (OlIn^[1] = $BB) And (OlIn^[2] = $BF) Then Begin
  For K := 3 To OlInLen - 1 Do OlIn^[K - 3] := OlIn^[K];
  OlInLen := OlInLen - 3;
 End;
 If (OlBodyStart(OlIn, 0, OlInLen) >= OlInLen) Or
    ((OlHdr(OlIn, 0, OlInLen, 'From') = '') And (OlHdr(OlIn, 0, OlInLen, 'Subject') = '') And
     (OlHdr(OlIn, 0, OlInLen, 'To') = '') And (OlHdr(OlIn, 0, OlInLen, 'MIME-Version') <> '1.0')) Then Begin
  MailStatus := 'Erreur: fichier invalide; un courriel au format EML est requis'; Exit;
 End;
 MailParseBig(OlIn, OlInLen, OlHdr(OlIn, 0, OlInLen, 'Message-ID'), OpenedMessage);
 OpenedMessage.IsRead := True;
 OpenedMessage.IsSelected := True;
 For I := 0 To FolderCount - 1 Do Folders[I].Selected := False;
 SelectedFolder := -1;
 MailLoadedFolder := -1;
 MessageCount := 1;
 Messages^[0] := OpenedMessage;
 For I := 0 To MAX_MESSAGES-1 Do OlFree(MessageSources[I]);
 OlStore(MessageSources[0], OlIn, OlInLen);
 SelectedMessage := 0;
 LastSelectedMessage := 0;
 MessageScrollOffset := 0;
 PreviewScrollX := 0;
 PreviewScrollY := 0;
 If Not OptionsReady Then PreviewVisible:=True;
 If Layout.PreviewPaneHeight = 0 Then Layout.PreviewPaneHeight := 150;
 MailStatus := 'Fichier ouvert : ' + Copy(FileName, 1, 62);
 LoadMessageFile := True;
End;

{ Navigation de fichiers avec les routines DOS deja presentes dans Uses.
  Aucune boite de dialogue native ni unite supplementaire n est utilisee. }
Function OpenFileJoin(DirectoryName, Name: TMailText): TMailText;
Var Separator: Char;
Begin
 Separator := '\';
 
 If (DirectoryName <> '') And
    Not (DirectoryName[Length(DirectoryName)] In ['\','/']) Then
  DirectoryName := DirectoryName + Separator;
 OpenFileJoin := DirectoryName + Name;
End;

Function OpenFileFullPath(Name: TMailText): TMailText;
Begin
 Name := MailTrim(Name);
 If (Length(Name) >= 2) And (Name[1] = '"') And (Name[Length(Name)] = '"') Then
  Name := Copy(Name, 2, Length(Name)-2);
 If Name = '' Then Begin OpenFileFullPath := ''; Exit; End;
 If Not (Name[1] In ['\','/']) And (Copy(Name,2,1) <> ':') Then
  Name := OpenFileJoin(FileOpenDirectory, Name);
 If Length(Name) > 255 Then OpenFileFullPath := ''
 Else OpenFileFullPath := FExpand(Name);
End;

Function OpenFileIsDirectory(Path: TMailText): Boolean;
Var F: File; Attributes: Word;
Begin
 OpenFileIsDirectory := False;
 If (Path = '') Or (Length(Path) > 255) Then Exit;
 Assign(F, Path);
 GetFAttr(F, Attributes);
 If DosError = 0 Then OpenFileIsDirectory := (Attributes And $10) <> 0;
End;

Procedure ReadOpenFileDirectory;
Var
 Entry: SearchRec;
 I, J: Integer;
 FirstError: Integer;
 Item, Swap: TOpenFileEntry;
 Pattern: TMailText;
Begin
 FileOpenCount := 1;
 FileOpenEntries[0].Name := '..';
 FileOpenEntries[0].IsDirectory := True;
 FileOpenSelection := 0;
 FileOpenScroll := 0;
 FileOpenTruncated := False;
 Pattern := OpenFileJoin(FileOpenDirectory, '*.*');
 If Length(Pattern) > 255 Then Begin
  FileOpenError := 'Erreur: chemin du repertoire trop long'; Exit;
 End;
 FindFirst(Pattern, AnyFile, Entry);
 FirstError := DosError;
 While DosError = 0 Do Begin
  If (Entry.Name <> '.') And (Entry.Name <> '..') Then Begin
   Item.Name := Entry.Name;
   Item.IsDirectory := (Entry.Attr And $10) <> 0;
   If Item.IsDirectory Or FileOpenShowAll Or
      (MailUpper(Copy(Item.Name, Length(Item.Name)-3, 4)) = '.EML') Then Begin
    If FileOpenCount < MAX_OPEN_DIALOG_FILES Then Begin
     FileOpenEntries[FileOpenCount] := Item;
     Inc(FileOpenCount);
    End Else FileOpenTruncated := True;
   End;
  End;
  FindNext(Entry);
 End;
 
 If (FirstError <> 0) And (FirstError <> 18) And (FirstError <> 2) Then
  FileOpenError := 'Erreur: impossible de lire ce repertoire';
 { Conserver .. en premier, puis les dossiers, puis les fichiers. }
 For I := 1 To FileOpenCount-2 Do
  For J := I+1 To FileOpenCount-1 Do
   If (FileOpenEntries[J].IsDirectory And Not FileOpenEntries[I].IsDirectory) Or
      ((FileOpenEntries[J].IsDirectory = FileOpenEntries[I].IsDirectory) And
       (MailUpper(FileOpenEntries[J].Name) < MailUpper(FileOpenEntries[I].Name))) Then Begin
    Swap := FileOpenEntries[I];
    FileOpenEntries[I] := FileOpenEntries[J];
    FileOpenEntries[J] := Swap;
   End;
End;

Procedure OpenFileSelect(Index: Integer);
Begin
 If Index < 0 Then Index := 0;
 If Index >= FileOpenCount Then Index := FileOpenCount-1;
 FileOpenSelection := Index;
 If Index < FileOpenScroll Then FileOpenScroll := Index;
 If Index >= FileOpenScroll + OPEN_DIALOG_ROWS Then
  FileOpenScroll := Index - OPEN_DIALOG_ROWS + 1;
 If (Index >= 0) And
    (Not FileDialogSaveMode Or Not FileOpenEntries[Index].IsDirectory) Then Begin
  FileOpenName := FileOpenEntries[Index].Name;
  FileOpenCursor := Length(FileOpenName);
 End;
End;

Procedure OpenFileChangeDirectory(Path: TMailText);
Begin
 If Not OpenFileIsDirectory(Path) Then Begin
  FileOpenError := 'Erreur: repertoire introuvable ou inaccessible'; Exit;
 End;
 FileOpenDirectory := Path;
 If Not FileDialogSaveMode Then Begin
  FileOpenName := ''; FileOpenCursor := 0;
 End;
 FileOpenError := '';
 ReadOpenFileDirectory;
 FileOpenFocus := 1;
End;

{ Ecrire le courriel complet, pas seulement les vingt lignes de previsualisation. }
Function MessageFileExists(Path: TMailText): Boolean;
Var F: File; Attributes: Word;
Begin
 Assign(F,Path); GetFAttr(F,Attributes);
 MessageFileExists:=DosError=0;
End;

Function MessageSaveSibling(Path, Extension: TMailText): TMailText;
Var I, LastSeparator, Attempt: Integer; Number: String; Candidate: TMailText;
Begin
 MessageSaveSibling:=''; LastSeparator:=0;
 For I:=1 To Length(Path) Do If Path[I] In ['\','/',':'] Then LastSeparator:=I;
 For Attempt:=0 To 9999 Do Begin
  Str(Attempt,Number);
  While Length(Number)<4 Do Number:='0'+Number;
  Candidate:=Copy(Path,1,LastSeparator)+'~OE'+Number+Extension;
  If Length(Candidate)>255 Then Exit;
  If Not MessageFileExists(Candidate) Then Begin MessageSaveSibling:=Candidate; Exit; End;
 End;
End;

Procedure DeleteMessageSaveTemporary(Path: TMailText);
Var F: File; Err: Integer;
Begin
 {$I-}
 Assign(F,Path); Erase(F); Err:=IOResult;
 {$I+}
End;

Function WriteMessageFile(Path: TMailText; AllowReplace: Boolean): Boolean;
Var F: File; Temporary, Backup: TMailText; Written: LongInt;
 Err, RestoreError: Integer; Attributes: Word; HadOriginal, Created: Boolean;
Begin
 WriteMessageFile:=False; FileOpenError:='';
 If OlSvEmpty Or (Path='') Or (Length(Path)>255) Then Begin
  FileOpenError:='Erreur: nom de fichier ou contenu du courriel invalide'; Exit;
 End;
 HadOriginal:=MessageFileExists(Path);
 If HadOriginal Then Begin
  If Not AllowReplace Then Begin FileOpenError:='Ce fichier existe deja'; Exit; End;
  Assign(F,Path); GetFAttr(F,Attributes);
  If (DosError<>0) Or ((Attributes And $11)<>0) Then Begin
   FileOpenError:='Erreur: fichier en lecture seule ou inaccessible'; Exit;
  End;
 End;
 Created:=False;
 Temporary:=MessageSaveSibling(Path,'.TMP');
 If Temporary='' Then Begin FileOpenError:='Erreur: impossible de creer un fichier temporaire'; Exit; End;
 {$I-}
 Assign(F,Temporary); Rewrite(F,1); Err:=IOResult;
 If Err=0 Then Begin
  Created:=True;
  BlockWrite(F,OlSv^[OlSvBase],OlSvLen-OlSvBase,Written);
  Err:=IOResult;
  If Written<>OlSvLen-OlSvBase Then Err:=101;
  Close(F);
  If IOResult<>0 Then Err:=101;
 End;
 {$I+}
 If Err<>0 Then Begin
  If Created Then DeleteMessageSaveTemporary(Temporary);
  FileOpenError:='Erreur: impossible d ecrire le courriel sur disque'; Exit;
 End;
 Backup:='';
 If HadOriginal Then Begin
  Backup:=MessageSaveSibling(Path,'.BAK');
  If Backup='' Then Err:=101
  Else Begin
   {$I-}
   Assign(F,Path); Rename(F,Backup); Err:=IOResult;
   {$I+}
  End;
  If Err<>0 Then Begin
   DeleteMessageSaveTemporary(Temporary);
   FileOpenError:='Erreur: le fichier existant ne peut pas etre remplace'; Exit;
  End;
 End;
 {$I-}
 Assign(F,Temporary); Rename(F,Path); Err:=IOResult;
 {$I+}
 If Err<>0 Then Begin
  RestoreError:=0;
  If Backup<>'' Then Begin
   {$I-}
   Assign(F,Backup); Rename(F,Path); RestoreError:=IOResult;
   {$I+}
  End;
  If RestoreError=0 Then Begin
   DeleteMessageSaveTemporary(Temporary);
   FileOpenError:='Erreur: enregistrement impossible, fichier precedent conserve';
  End Else FileOpenError:='Erreur: ancienne copie conservee dans '+Copy(Backup,1,34);
  Exit;
 End;
 If Backup<>'' Then DeleteMessageSaveTemporary(Backup);
 WriteMessageFile:=True;
End;

Procedure FinishMessageSave(Path: TMailText; AllowReplace: Boolean);
Begin
 If WriteMessageFile(Path,AllowReplace) Then Begin
  If FileSaveFromComposer Then Composer.Modified:=False;
  MailStatus:='Courriel enregistre : '+Copy(Path,1,58);
  FileOpenVisible:=False;
  OlSvClear;
  DrawInterface;
 End Else DrawOpenFileDialog;
End;

Procedure AnswerMessageOverwrite(ReplaceFile: Boolean);
Var Path: TMailText;
Begin
 Path:=FileSaveOverwritePath;
 FileSaveOverwritePending:=False;
 If ReplaceFile Then FinishMessageSave(Path,True) Else DrawOpenFileDialog;
End;

Procedure DrawMessageOverwrite;
Var X,Y: Integer; Text: String;
Begin
 X:=(SCREEN_WIDTH-420) Div 2; Y:=(SCREEN_HEIGHT-140) Div 2;
 DrawDialogBox(X,Y,420,140,'Remplacer le fichier existant ?');
 GSetColor(COLOR_MENU_TEXT);
 Text:=FileSaveOverwritePath;
 While (Text<>'') And (GTextWidth(Text)>390) Do Delete(Text,1,1);
 GOutTextXY(X+15,Y+38,Text);
 GOutTextXY(X+15,Y+60,'Le contenu actuel sera remplace.');
 DrawDialogButton(X+225,Y+100,80,22,'Oui',FileSaveOverwriteYes,True);
 DrawDialogButton(X+320,Y+100,80,22,'Non',Not FileSaveOverwriteYes,True);
End;

Procedure CancelOpenFileDialog;
Begin
 FileSaveOverwritePending:=False;
 OlSvClear;
 FileOpenVisible := False;
 DrawInterface;
End;

Procedure ConfirmOpenFileDialog;
Var Path: TMailText; PreviousStatus: String[80]; I, Separator: Integer;
Begin
 If FileOpenFocus = 1 Then
  Path := OpenFileFullPath(FileOpenEntries[FileOpenSelection].Name)
 Else Path := OpenFileFullPath(FileOpenName);
 If Path = '' Then Begin
  FileOpenError := 'Indiquez un nom de fichier ou un chemin de 255 caracteres au plus';
  DrawOpenFileDialog; Exit;
 End;
 If OpenFileIsDirectory(Path) Then OpenFileChangeDirectory(Path)
 Else If FileDialogSaveMode Then Begin
  Separator:=0;
  For I:=1 To Length(Path) Do If Path[I] In ['\','/',':'] Then Separator:=I;
  If Pos('.',Copy(Path,Separator+1,Length(Path)))=0 Then Path:=Path+'.eml';
  If Length(Path)>255 Then Begin
   FileOpenError:='Erreur: nom de fichier trop long'; DrawOpenFileDialog; Exit;
  End;
  If MessageFileExists(Path) Then Begin
   FileSaveOverwritePath:=Path;
   FileSaveOverwritePending:=True;
   FileSaveOverwriteYes:=False;
   DrawOpenFileDialog;
  End Else FinishMessageSave(Path,False);
  Exit;
 End Else Begin
  PreviousStatus := MailStatus;
  If LoadMessageFile(Path) Then Begin
   FileOpenVisible := False;
   DrawInterface;
   Exit;
  End;
  FileOpenError := MailStatus;
  MailStatus := PreviousStatus;
 End;
 DrawOpenFileDialog;
End;

Procedure ToggleOpenFileFilter;
Begin
 FileOpenShowAll := Not FileOpenShowAll;
 FileOpenError := '';
 ReadOpenFileDirectory;
 DrawOpenFileDialog;
End;

Procedure DrawOpenFileDialog;
Var X, Y, I, Index, FirstChar: Integer; Text, CursorText: String;
Begin
 If Not FileOpenVisible Then Exit;
 X := (SCREEN_WIDTH - OPEN_DIALOG_WIDTH) Div 2;
 Y := (SCREEN_HEIGHT - OPEN_DIALOG_HEIGHT) Div 2;
 HideMouse;
 If FileDialogSaveMode Then Text:='Enregistrer sous' Else Text:='Ouvrir un courriel';
 DrawDialogBox(X, Y, OPEN_DIALOG_WIDTH, OPEN_DIALOG_HEIGHT, Text);
 GSetColor(COLOR_MENU_TEXT);
 Text := FileOpenDirectory;
 While (Text <> '') And (GTextWidth(Text) > OPEN_DIALOG_WIDTH-120) Do Delete(Text,1,1);
 GOutTextXY(X+15, Y+35, Text);
 DrawDialogButton(X+OPEN_DIALOG_WIDTH-90,Y+28,75,22,'Parent',False,True);
 GSetFillStyle(SolidFill, COLOR_LIST_BG);
 GBar(X+15,Y+60,X+OPEN_DIALOG_WIDTH-15,Y+260);
 Draw3DRect(X+15,Y+60,X+OPEN_DIALOG_WIDTH-15,Y+260,False);
 For I := 0 To OPEN_DIALOG_ROWS-1 Do Begin
  Index := FileOpenScroll + I;
  If Index < FileOpenCount Then Begin
   If Index = FileOpenSelection Then Begin
    FillRect(X+17,Y+63+I*14,X+OPEN_DIALOG_WIDTH-38,Y+76+I*14,COLOR_MENU_HIGHLIGHT);
    GSetColor(COLOR_MENU_HIGHLIGHT_TEXT);
   End Else GSetColor(COLOR_MENU_TEXT);
   Text := FileOpenEntries[Index].Name;
   If FileOpenEntries[Index].IsDirectory Then Text := '['+Text+']';
   While (Text <> '') And (GTextWidth(Text) > OPEN_DIALOG_WIDTH-65) Do
    Delete(Text,Length(Text),1);
   GOutTextXY(X+20,Y+66+I*14,Text);
  End;
 End;
 DrawDialogButton(X+OPEN_DIALOG_WIDTH-35,Y+62,18,18,'^',False,True);
 DrawDialogButton(X+OPEN_DIALOG_WIDTH-35,Y+240,18,18,'v',False,True);
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(X+15,Y+271,'Nom du fichier :');
 If FileOpenFocus = 0 Then GSetFillStyle(SolidFill,COLOR_LIST_BG)
 Else GSetFillStyle(SolidFill,COLOR_WINDOW_BG);
 GBar(X+15,Y+286,X+OPEN_DIALOG_WIDTH-15,Y+306);
 Draw3DRect(X+15,Y+286,X+OPEN_DIALOG_WIDTH-15,Y+306,False);
 FirstChar := 1;
 CursorText := Copy(FileOpenName,1,FileOpenCursor);
 While (CursorText <> '') And (GTextWidth(CursorText) > OPEN_DIALOG_WIDTH-45) Do Begin
  Delete(CursorText,1,1); Inc(FirstChar);
 End;
 Text := Copy(FileOpenName,FirstChar,255);
 While (Text <> '') And (GTextWidth(Text) > OPEN_DIALOG_WIDTH-45) Do
  Delete(Text,Length(Text),1);
 GSetColor(COLOR_MENU_TEXT);
 GOutTextXY(X+19,Y+291,Text);
 If FileOpenFocus = 0 Then
  GLine(X+19+GTextWidth(CursorText),Y+289,X+19+GTextWidth(CursorText),Y+303);
 Text := FileOpenError;
 If (Text = '') And FileOpenTruncated Then Text := 'Liste limitee: saisir le chemin pour un autre fichier.';
 While (Text <> '') And (GTextWidth(Text) > OPEN_DIALOG_WIDTH-30) Do
  Delete(Text,Length(Text),1);
 GSetColor(LightRed);
 GOutTextXY(X+15,Y+316,Text);
 If FileOpenShowAll Then Text := '*.eml' Else Text := 'Tous fichiers';
 DrawDialogButton(X+15,Y+344,110,22,Text,FileOpenFocus=4,True);
 If FileDialogSaveMode Then Text:='Enregistrer' Else Text:='Ouvrir';
 DrawDialogButton(X+OPEN_DIALOG_WIDTH-205,Y+344,100,22,Text,FileOpenFocus=2,True);
 DrawDialogButton(X+OPEN_DIALOG_WIDTH-90,Y+344,75,22,'Annuler',FileOpenFocus=3,True);
 If FileSaveOverwritePending Then DrawMessageOverwrite;
 ShowMouse;
End;

Procedure HandleOpenFileKey(Key: Char; Extended: Boolean);
Begin
 If Not FileOpenVisible Then Exit;
 If FileSaveOverwritePending Then Begin
  If Not Extended Then Begin
   Case Ord(Key) of
    9: FileSaveOverwriteYes:=Not FileSaveOverwriteYes;
    27: Begin AnswerMessageOverwrite(False); Exit; End;
    13: Begin AnswerMessageOverwrite(FileSaveOverwriteYes); Exit; End;
    79,111,89,121: Begin AnswerMessageOverwrite(True); Exit; End;
    78,110: Begin AnswerMessageOverwrite(False); Exit; End;
   End;
  End;
  DrawOpenFileDialog; Exit;
 End;
 If FileOpenFocus=0 Then FileOpenError:='';
 If Extended Then Begin
  If FileOpenFocus = 1 Then Begin
   Case Ord(Key) of
    72: OpenFileSelect(FileOpenSelection-1);
    80: OpenFileSelect(FileOpenSelection+1);
    73: OpenFileSelect(FileOpenSelection-OPEN_DIALOG_ROWS);
    81: OpenFileSelect(FileOpenSelection+OPEN_DIALOG_ROWS);
    71: OpenFileSelect(0);
    79: OpenFileSelect(FileOpenCount-1);
   End;
  End Else If FileOpenFocus = 0 Then Begin
   Case Ord(Key) of
    75: If FileOpenCursor>0 Then Dec(FileOpenCursor);
    77: If FileOpenCursor<Length(FileOpenName) Then Inc(FileOpenCursor);
    71: FileOpenCursor:=0;
    79: FileOpenCursor:=Length(FileOpenName);
    83: Delete(FileOpenName,FileOpenCursor+1,1);
   End;
  End;
 End Else Begin
  Case Ord(Key) of
   27: Begin CancelOpenFileDialog; Exit; End;
   9: FileOpenFocus := (FileOpenFocus+1) Mod 5;
   13: Begin
    If FileOpenFocus=3 Then CancelOpenFileDialog
    Else If FileOpenFocus=4 Then ToggleOpenFileFilter
    Else ConfirmOpenFileDialog;
    Exit;
   End;
   8: If FileOpenFocus=0 Then Begin
       If FileOpenCursor>0 Then Begin
        Delete(FileOpenName,FileOpenCursor,1); Dec(FileOpenCursor);
       End;
      End Else If FileOpenFocus=1 Then
       OpenFileChangeDirectory(OpenFileFullPath('..'));
   Else If (FileOpenFocus=0) And (Key>=#32) And (Key<>#127) And
           (Length(FileOpenName)<255) Then Begin
    Insert(Key,FileOpenName,FileOpenCursor+1); Inc(FileOpenCursor);
   End;
  End;
 End;
 DrawOpenFileDialog;
End;

Procedure HandleOpenFileClick(MX, MY: Integer);
Var X, Y, Index: Integer; DoubleClick: Boolean;
Begin
 If Not FileOpenVisible Then Exit;
 If FileSaveOverwritePending Then Begin
  X:=(SCREEN_WIDTH-420) Div 2; Y:=(SCREEN_HEIGHT-140) Div 2;
  If (MY>=Y+100) And (MY<=Y+122) Then Begin
   If (MX>=X+225) And (MX<=X+305) Then AnswerMessageOverwrite(True)
   Else If (MX>=X+320) And (MX<=X+400) Then AnswerMessageOverwrite(False);
  End;
  Exit;
 End;
 X := (SCREEN_WIDTH-OPEN_DIALOG_WIDTH) Div 2;
 Y := (SCREEN_HEIGHT-OPEN_DIALOG_HEIGHT) Div 2;
 If (MX<X) Or (MX>X+OPEN_DIALOG_WIDTH) Or (MY<Y) Or (MY>Y+OPEN_DIALOG_HEIGHT) Then Exit;
 If (MY>=Y+344) And (MY<=Y+366) Then Begin
  If (MX>=X+OPEN_DIALOG_WIDTH-90) And (MX<=X+OPEN_DIALOG_WIDTH-15) Then Begin
   CancelOpenFileDialog; Exit;
  End;
  If (MX>=X+OPEN_DIALOG_WIDTH-205) And (MX<=X+OPEN_DIALOG_WIDTH-105) Then Begin
   FileOpenFocus:=0; ConfirmOpenFileDialog; Exit;
  End;
  If (MX>=X+15) And (MX<=X+125) Then Begin
   FileOpenFocus:=4; ToggleOpenFileFilter; Exit;
  End;
 End;
 If (MX>=X+OPEN_DIALOG_WIDTH-90) And (MY>=Y+28) And (MY<=Y+50) Then Begin
  OpenFileChangeDirectory(OpenFileFullPath('..')); DrawOpenFileDialog; Exit;
 End;
 If (MX>=X+15) And (MX<=X+OPEN_DIALOG_WIDTH-15) And (MY>=Y+286) And (MY<=Y+306) Then Begin
  FileOpenFocus:=0; FileOpenCursor:=Length(FileOpenName); DrawOpenFileDialog; Exit;
 End;
 If (MX>=X+15) And (MX<=X+OPEN_DIALOG_WIDTH-15) And (MY>=Y+63) And (MY<Y+259) Then Begin
  FileOpenFocus:=1;
  If MX>=X+OPEN_DIALOG_WIDTH-36 Then Begin
   If MY<Y+90 Then OpenFileSelect(FileOpenSelection-1)
   Else If MY>=Y+240 Then OpenFileSelect(FileOpenSelection+1);
  End Else Begin
   Index:=FileOpenScroll+(MY-Y-63) Div 14;
   If Index<FileOpenCount Then Begin
    DoubleClick:=IsDoubleClick(MX,MY,MOUSE_LEFT);
    OpenFileSelect(Index);
    If DoubleClick Then Begin ConfirmOpenFileDialog; Exit; End;
   End;
  End;
 End;
 DrawOpenFileDialog;
End;

Function BeginMessageFileDialog(SaveMode: Boolean): Boolean;
Var Err: Integer;
Begin
 BeginMessageFileDialog:=False;
 If AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or ColumnsDialogVisible Or
    RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Or
    (ComposerVisible And Not SaveMode) Then Exit;
 If FileOpenDirectory='' Then Begin
  {$I-}
  GetDir(0,FileOpenDirectory);
  Err:=IOResult;
  {$I+}
  If Err<>0 Then FileOpenDirectory:='.';
 End;
 FileDialogSaveMode:=SaveMode; FileSaveOverwritePending:=False;
 FileOpenName:=''; FileOpenCursor:=0; FileOpenFocus:=0; FileOpenError:='';
 FileOpenVisible:=True;
 TooltipVisible:=False; ContextMenuVisible:=False;
 ActiveMenu:=-1; ActiveMenuItem:=-1; MenuBarActive:=False; DragState:=dsNone;
 LastClickTime:=0;
 ReadOpenFileDirectory;
 BeginMessageFileDialog:=True;
End;

Procedure OpenMessageFile;
Begin
 If BeginMessageFileDialog(False) Then DrawOpenFileDialog;
End;

Function ComposerMessageSource: TMailText;
Var A,I: Integer; Data: TMailText;
Begin
 SaveComposerFields;
 A:=Composer.AccountIndex;
 If (A<0) And (SelectedFolder>=0) And (SelectedFolder<FolderCount) Then A:=MailFolderAccount[SelectedFolder];
 If A<0 Then For I:=0 To EmailAccountCount-1 Do If EmailAccounts[I].IsDefault Then A:=I;
 Data:='';
 If (A>=0) And (A<EmailAccountCount) Then
  Data:='From: '+EmailAccounts[A].EmailAddress+#13#10;
 Data:=Data+'To: '+Composer.ToField+#13#10;
 If Composer.CcField<>'' Then Data:=Data+'Cc: '+Composer.CcField+#13#10;
 If Composer.BccField<>'' Then Data:=Data+'Bcc: '+Composer.BccField+#13#10;
 Data:=Data+'Subject: '+Composer.SubjectField+#13#10+
  'MIME-Version: 1.0'#13#10'Content-Type: text/plain; charset=windows-1252'#13#10+
  'Content-Transfer-Encoding: 8bit'#13#10#13#10;
 For I:=0 To Composer.LineCount-1 Do Data:=Data+Composer.Lines[I].Text+#13#10;
 ComposerMessageSource:=Data;
End;

Procedure SaveMessageAs;
Var Subject: String; I: Integer; Data: TMailText;
Begin
 If AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or ColumnsDialogVisible Or
    RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Then Exit;
 If ComposerVisible Then Begin
  If Composer.AttachmentCount>0 Then Begin
   MailStatus:='Enregistrement des pieces jointes du brouillon non implemente';
   DrawStatusBar; Exit;
  End;
  OlComposerSource;
  Subject:=Composer.SubjectField;
 End Else Begin
  If (SelectedMessage<0) Or (SelectedMessage>=MessageCount) Then Begin
   MailStatus:='Selectionnez un courriel avant Enregistrer sous'; DrawStatusBar; Exit;
  End;
  OlRefToSv(MessageSources[SelectedMessage]);
  Subject:=Messages^[SelectedMessage].Subject;
  If MessageSources[SelectedMessage].L=0 Then Begin
   MailStatus:='Erreur: source complete du courriel indisponible'; DrawStatusBar; Exit;
  End;
 End;
 If Not BeginMessageFileDialog(True) Then Exit;
 FileSaveFromComposer:=ComposerVisible;
 For I:=1 To Length(Subject) Do
  If (Subject[I]<#32) Or (Subject[I] In ['\','/',':','*','?','"','<','>','|']) Then Subject[I]:='_';
 Subject:=MailTrim(Subject);
 If Subject='' Then FileOpenName:='message.eml'
 Else FileOpenName:='Message - '+Subject+'.eml';
 FileOpenCursor:=Length(FileOpenName);
 DrawOpenFileDialog;
End;

Procedure ReceiveMailWork;
Var AccountIndex, I, Total, First, Count, Code, Unread,ToFetch: LongInt;
 R: TIMAPResponse; P: TPOP3Response; Number, ID, StatText: TMailText;
 Success: Boolean;
Begin
 If (SelectedFolder<0) Or (SelectedFolder>=FolderCount) Then Begin
  MailStatus:='Configurez un compte dans Outils / Comptes'; Exit;
 End;
 AccountIndex:=MailFolderAccount[SelectedFolder];
 If (AccountIndex<0) Or (AccountIndex>=EmailAccountCount) Then Exit;
 If Folders[SelectedFolder].FolderType<>ftInbox Then Begin
  MailStatus:='Selectionnez la boite de reception du compte'; Exit;
 End;
 If Not EmailAccounts[AccountIndex].IsActive Then Begin MailStatus:='Compte desactive'; Exit; End;
 MailStatus:='Connexion a '+EmailAccounts[AccountIndex].IncomingHost;
 BusyBegin('Reception du courrier',EmailAccounts[AccountIndex].IncomingHost);
 If Not OpenIncomingAccount(EmailAccounts[AccountIndex]) Then Begin MailStatus:=MailError; Exit; End;
 For I:=0 To MAX_MESSAGES-1 Do OlFree(PendingMessageSources[I]);
 BusyStage('Lecture de la boite de reception...');
 Success:=True; Total:=0; Count:=0; Unread:=0;
 If EmailAccounts[AccountIndex].IncomingType=istIMAP Then Begin
  IMAPClient.CurrentMailbox.Exists:=0;
  If IMAP_Select('INBOX')<>IMAP_OK Then Begin MailError:=IMAPClient.LastError; Success:=False; End;
  Total:=IMAPClient.CurrentMailbox.Exists;
 End Else Begin
  P:=POP3_SendCommand('STAT'); StatText:=P.Text;
  I:=Pos(' ',StatText); If I>0 Then StatText:=Copy(StatText,1,I-1);
  Val(StatText,Total,Code);
  If (P.ResponseType<>prOK) Or (Code<>0) Or (Total<0) Then Begin
   MailError:='STAT refuse: '+P.Text; Success:=False;
  End;
 End;
 First:=Total-MAX_MESSAGES+1; If First<1 Then First:=1;
 ToFetch:=Total; If ToFetch>MAX_MESSAGES Then ToFetch:=MAX_MESSAGES;
 BusyUpdate('Reception des messages...',0,ToFetch);
 For I:=Total DownTo First Do Begin
  If Not Success Then Break;
  Str(I,Number);
  If EmailAccounts[AccountIndex].IncomingType=istIMAP Then Begin
   R:=IMAP_SendCommand('FETCH '+Number+' (UID FLAGS BODY.PEEK[])');
   Success:=R.ResponseType=irOK;
   If Not Success Then MailError:='Lecture IMAP refusee: '+R.Text;
   Str(MailFetchUID,ID);
  End Else Begin
   P:=POP3_SendCommand('RETR '+Number); Success:=P.ResponseType=prOK;
   If Not Success Then MailError:='Lecture POP3 refusee: '+P.Text;
   ID:=Number;
  End;
  If Success Then Begin
   MailParseBig(OlIn,OlInLen,ID,MailNewMessages^[Count]);
   OlStore(PendingMessageSources[Count],OlIn,OlInLen);
   If EmailAccounts[AccountIndex].IncomingType=istIMAP Then Begin
    MailNewMessages^[Count].IsRead:=Pos('\Seen',MailFetchFlags)>0;
    MailNewMessages^[Count].IsFlagged:=Pos('\Flagged',MailFetchFlags)>0;
   End;
   If Not MailNewMessages^[Count].IsRead Then Inc(Unread);
   Inc(Count); BusyUpdate('Reception des messages...',Count,ToFetch);
  End;
 End;
 MailClose(IMAPWire); MailClose(POP3Wire);
 IMAPClient.Connected:=False; IMAPClient.State:=isDisconnected;
 POP3Client.Connected:=False; POP3Client.State:=psDisconnected;
 If Not Success Then Begin
  For I:=0 To MAX_MESSAGES-1 Do OlFree(PendingMessageSources[I]);
  MailStatus:=MailError; Exit;
 End;
 BusyUpdate('Application des regles et preparation des messages...',0,0);
 Move(MailNewMessages^,Messages^,SizeOf(Messages^)); MessageCount:=Count;
 For I:=0 To MAX_MESSAGES-1 Do Begin
  OlFree(MessageSources[I]); MessageSources[I]:=PendingMessageSources[I];
  PendingMessageSources[I].P:=Nil; PendingMessageSources[I].L:=0;
 End;
 Rules_ApplyToAllMessages;
 Unread:=0;
 For I:=0 To MessageCount-1 Do If Not Messages^[I].IsRead Then Inc(Unread);
 SelectedMessage:=-1; LastSelectedMessage:=-1; MessageScrollOffset:=0; PreviewScrollY:=0;
 If Count>0 Then Begin SelectedMessage:=0; Messages^[0].IsSelected:=True; End;
 MailLoadedFolder:=SelectedFolder;
 Folders[SelectedFolder].TotalCount:=Total; Folders[SelectedFolder].UnreadCount:=Unread;
 Str(Count,Number); Str(Total,ID);
 MailStatus:=Number+' messages charges sur '+ID+' | '+EmailAccounts[AccountIndex].AccountName;
End;

Procedure ReceiveMail;
Begin
 If BusyVisible Then Exit;
 ReceiveMailWork;
 BusyEnd;
End;

{ Demarre avec une boite vide; seul le serveur fournit les messages. }
Procedure InitializeMessageList;
Var I: Integer;
Begin
 For I:=0 To MAX_MESSAGES-1 Do Begin
  MessageSources[I].P:=Nil; MessageSources[I].L:=0; PendingMessageSources[I].P:=Nil; PendingMessageSources[I].L:=0;
 End;
 MessageCount := 0;
 SelectedMessage := -1;
 LastSelectedMessage := -1;
 MessageScrollOffset := 0;
 SortColumn := 5;  { Tri par date par defaut }
 SortOrder := soDescending;
 CtrlKeyDown := False;
 ShiftKeyDown := False;
 ContextMenuVisible := False;
 HoveredColumn := -1;

 { Initialiser les variables de previsualisation }
 PreviewScrollY := 0;
 PreviewScrollX := 0;
 PreviewMaxScrollY := 0;
 PreviewMaxScrollX := 0;
 PreviewOrientation := poHorizontal;
 PreviewVisible := True;
 PreviewHeaderHeight := PREVIEW_LINE_HEIGHT * PREVIEW_HEADER_LINES + 20;
 InPreviewPane := False;

 { Initialiser le client IMAP }
 IMAP_InitClient;
 POP3_InitClient;
 SMTP_InitClient;
 FillChar(Messages^,SizeOf(Messages^),0);
 MailLoadedFolder:=-1;
 MailStatus:='Pret - cliquez sur Envoyer/Recevoir';

 { Initialiser les colonnes }
 InitializeMessageColumns;
End;

{ Dessine l'indicateur de tri sur un en-tete de colonne }
Procedure DrawSortIndicator(X, Y: Integer; Ascending: Boolean);
Begin
 GSetColor(COLOR_MENU_TEXT);
 If Ascending Then Begin
  { Triangle vers le haut }
  GLine(X, Y + 6, X + 4, Y);
  GLine(X + 4, Y, X + 8, Y + 6);
  GLine(X, Y + 6, X + 8, Y + 6);
 End
 Else Begin
  { Triangle vers le bas }
  GLine(X, Y, X + 4, Y + 6);
  GLine(X + 4, Y + 6, X + 8, Y);
  GLine(X, Y, X + 8, Y);
 End;
End;

{ Cle chronologique RFC 5322, independante du format de la date affichee. }
Function MessageDateKey(Index: Integer):
  Real ;
Const Months: String[36]='JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC';
Var Text, Token: TMailText; Parts: Array[0..5] Of String;
 I,N,P,Code,D,M,Y,H,Mi,Sec,Zone,ZHour,ZMin,MaxDay: Integer;
 Days: LongInt;
 Function Number(S: String): Integer;
 Var V,E: Integer;
 Begin Val(S,V,E); If E<>0 Then V:=-1; Number:=V; End;
 Function Leap(Year: Integer): Boolean;
 Begin Leap:=(Year Mod 4=0) And ((Year Mod 100<>0) Or (Year Mod 400=0)); End;
Begin
 MessageDateKey:=Messages^[Index].DateSort;
 Text:=MailUpper(OlRefHdr(MessageSources[Index],'Date'));
 If Text='' Then Text:=MailUpper(Messages^[Index].DateFull);
 P:=Pos(',',Text); If P>0 Then Delete(Text,1,P);
 N:=0;
 While (Text<>'') And (N<6) Do Begin
  Text:=MailTrim(Text); If Text='' Then Break;
  P:=1; While (P<=Length(Text)) And Not (Text[P] In [' ',#9]) Do Inc(P);
  Parts[N]:=Copy(Text,1,P-1); Inc(N); Delete(Text,1,P);
 End;
 If N<5 Then Exit;
 D:=Number(Parts[0]); P:=Pos(Parts[1],Months);
 If (Length(Parts[1])<>3) Or (P=0) Or ((P-1) Mod 3<>0) Then Exit;
 M:=(P-1) Div 3+1; Y:=Number(Parts[2]);
 If (Y>=0) And (Y<50) Then Inc(Y,2000)
 Else If (Y>=50) And (Y<100) Then Inc(Y,1900);
 If (Y<1601) Or (Y>9999) Then Exit;
 MaxDay:=31;
 If M In [4,6,9,11] Then MaxDay:=30;
 If M=2 Then Begin MaxDay:=28; If Leap(Y) Then Inc(MaxDay); End;
 If (D<1) Or (D>MaxDay) Then Exit;
 Token:=Parts[3]; P:=Pos(':',Token); If P=0 Then Exit;
 H:=Number(Copy(Token,1,P-1)); Delete(Token,1,P); P:=Pos(':',Token);
 Sec:=0;
 If P>0 Then Begin Sec:=Number(Copy(Token,P+1,255)); Token:=Copy(Token,1,P-1); End;
 Mi:=Number(Token);
 If (H<0) Or (H>23) Or (Mi<0) Or (Mi>59) Or (Sec<0) Or (Sec>60) Then Exit;
 Zone:=0; Token:=Parts[4];
 If (Length(Token)=5) And (Token[1] In ['+','-']) Then Begin
  ZHour:=Number(Copy(Token,2,2)); ZMin:=Number(Copy(Token,4,2));
  If (ZHour<0) Or (ZHour>23) Or (ZMin<0) Or (ZMin>59) Then Exit;
  Zone:=ZHour*60+ZMin; If Token[1]='-' Then Zone:=-Zone;
 End Else If (Token<>'UT') And (Token<>'UTC') And (Token<>'GMT') And (Token<>'Z') Then Begin
  { Zones historiques autorisees dans les en-tetes RFC 5322. }
  Code:=Pos('|'+Token+'|','|EST|EDT|CST|CDT|MST|MDT|PST|PDT|');
  If (Length(Token)<>3) Or (Code=0) Then Exit;
  Case (Code-1) Div 4 Of
   0: Zone:=-300; 1: Zone:=-240; 2: Zone:=-360; 3: Zone:=-300;
   4: Zone:=-420; 5: Zone:=-360; 6: Zone:=-480; 7: Zone:=-420;
  End;
 End;
 Days:=365*(Y-1)+(Y-1) Div 4-(Y-1) Div 100+(Y-1) Div 400;
 For I:=1 To M-1 Do Begin
  Inc(Days,31); If I In [4,6,9,11] Then Dec(Days);
  If I=2 Then Begin Dec(Days,3); If Leap(Y) Then Inc(Days); End;
 End;
 
 MessageDateKey:=(Days+0.0+D-1-719162)*86400+LongInt(H)*3600+Mi*60+Sec-LongInt(Zone)*60;
 
End;

{ Compare deux messages selon la colonne de tri }
Function CompareMessages(Idx1, Idx2: Integer): Integer;
Var
 Result: Integer;
Begin
 Result := 0;

 Case Columns[SortColumn].ColType Of
  ctPriority: Begin
   If Ord(Messages^[Idx1].Priority) < Ord(Messages^[Idx2].Priority) Then
    Result := -1
   Else If Ord(Messages^[Idx1].Priority) > Ord(Messages^[Idx2].Priority) Then
    Result := 1;
  End;

  ctAttachment: Begin
   If Messages^[Idx1].HasAttachment And Not Messages^[Idx2].HasAttachment Then
    Result := -1
   Else If Not Messages^[Idx1].HasAttachment And Messages^[Idx2].HasAttachment Then
    Result := 1;
  End;

  ctFlag: Begin
   If Messages^[Idx1].IsFlagged And Not Messages^[Idx2].IsFlagged Then
    Result := -1
   Else If Not Messages^[Idx1].IsFlagged And Messages^[Idx2].IsFlagged Then
    Result := 1;
  End;

  ctFrom: Begin
   If MailUpper(Messages^[Idx1].FromName) < MailUpper(Messages^[Idx2].FromName) Then
    Result := -1
   Else If MailUpper(Messages^[Idx1].FromName) > MailUpper(Messages^[Idx2].FromName) Then
    Result := 1;
  End;

  ctSubject: Begin
   If MailUpper(Messages^[Idx1].Subject) < MailUpper(Messages^[Idx2].Subject) Then
    Result := -1
   Else If MailUpper(Messages^[Idx1].Subject) > MailUpper(Messages^[Idx2].Subject) Then
    Result := 1;
  End;

  ctDate: Begin
   If MessageDateKey(Idx1) < MessageDateKey(Idx2) Then
    Result := -1
   Else If MessageDateKey(Idx1) > MessageDateKey(Idx2) Then
    Result := 1;
  End;

  ctSize: Begin
   If Messages^[Idx1].Size < Messages^[Idx2].Size Then
    Result := -1
   Else If Messages^[Idx1].Size > Messages^[Idx2].Size Then
    Result := 1;
  End;
 End;

 { Inverser si tri descendant }
 If SortOrder = soDescending Then
  Result := -Result;

 CompareMessages := Result;
End;

{ Trie la liste des messages selon la colonne active }
Procedure SortMessageList;
Var
 I, J: Integer;
 Temp: TMessage;
 TempSource: TBigRef;
Begin
 If (SortColumn < 0) Or (SortColumn >= ColumnCount) Then Exit;
 If SortOrder = soNone Then Exit;

 { Tri stable : les messages de meme valeur conservent leur ordre. }
 For I := 0 To MessageCount - 2 Do Begin
  For J := 0 To MessageCount - I - 2 Do Begin
   If CompareMessages(J, J + 1) > 0 Then Begin
    Temp := Messages^[J];
    Messages^[J] := Messages^[J + 1];
    Messages^[J + 1] := Temp;
    TempSource := MessageSources[J];
    MessageSources[J] := MessageSources[J+1];
    MessageSources[J+1] := TempSource;
    If SelectedMessage=J Then SelectedMessage:=J+1
    Else If SelectedMessage=J+1 Then SelectedMessage:=J;
    If LastSelectedMessage=J Then LastSelectedMessage:=J+1
    Else If LastSelectedMessage=J+1 Then LastSelectedMessage:=J;
   End;
  End;
 End;
End;

{ Boite modale de tri, entierement dessinee avec les routines graphiques. }
Function SortCriterionName(Index: Integer): String;
Begin
 Case Index Of
  0: SortCriterionName:='Priorite';
  1: SortCriterionName:='Pieces jointes';
  2: SortCriterionName:='Drapeau';
  3: SortCriterionName:='Expediteur';
  4: SortCriterionName:='Objet';
  5: SortCriterionName:='Date';
  6: SortCriterionName:='Taille';
 Else SortCriterionName:='';
 End;
End;

{ Configuration transactionnelle des colonnes : aucun effet avant OK. }
Procedure DrawColumnsDialog;
Var X,Y,I,C: Integer; Text: String;
Begin
 If Not ColumnsDialogVisible Then Exit;
 X:=(SCREEN_WIDTH-380) Div 2; Y:=(SCREEN_HEIGHT-290) Div 2;
 DrawDialogBox(X,Y,380,290,'Colonnes...');
 GSetColor(Black); GOutTextXY(X+16,Y+34,'Colonnes a afficher :');
 For I:=0 To ColumnCount-1 Do Begin
  C:=White; If I=ColumnsDialogSelection Then C:=Blue;
  FillRect(X+16,Y+54+I*22,X+236,Y+74+I*22,C);
  If I=ColumnsDialogSelection Then GSetColor(White) Else GSetColor(Black);
  Text:='[ ] '; If ColumnsDraft[I].Visible Then Text:='[x] ';
  Text:=Text+SortCriterionName(Ord(ColumnsDraft[I].ColType));
  If (ColumnsDialogFocus=0) And (I=ColumnsDialogSelection) Then Text:='> '+Text;
  GOutTextXY(X+20,Y+60+I*22,Text);
 End;
 DrawDialogButton(X+250,Y+56,112,24,'Monter',ColumnsDialogFocus=1,ColumnsDialogSelection>0);
 DrawDialogButton(X+250,Y+90,112,24,'Descendre',ColumnsDialogFocus=2,
                  ColumnsDialogSelection<ColumnCount-1);
 DrawDialogButton(X+250,Y+132,112,24,'Par defaut',ColumnsDialogFocus=3,True);
 GSetColor(Black); GOutTextXY(X+16,Y+216,ColumnsDialogError);
 DrawDialogButton(X+180,Y+250,76,24,'OK',ColumnsDialogFocus=4,True);
 DrawDialogButton(X+268,Y+250,94,24,'Annuler',ColumnsDialogFocus=5,True);
End;

Procedure ShowColumnsDialog;
Var I: Integer;
Begin
 If ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or
    SortDialogVisible Or ColumnsDialogVisible Or RulesVisible Or PrefsVisible Or AboutVisible Or
    EventDialogVisible Then Exit;
 For I:=0 To ColumnCount-1 Do ColumnsDraft[I]:=Columns[I];
 ColumnsDialogSelection:=0; ColumnsDialogFocus:=0; ColumnsDialogError:='';
 ColumnsDialogVisible:=True; ContextMenuVisible:=False; DrawInterface;
End;

Procedure CloseColumnsDialog(Apply: Boolean);
Var I,N: Integer; SortedType: TColumnType; HasSort: Boolean;
Begin
 If Apply Then Begin
  N:=0;
  For I:=0 To ColumnCount-1 Do If ColumnsDraft[I].Visible Then Inc(N);
  If N=0 Then Begin
   ColumnsDialogError:='Afficher au moins une colonne.'; DrawInterface; Exit;
  End;
  HasSort:=(SortColumn>=0) And (SortColumn<ColumnCount);
  If HasSort Then SortedType:=Columns[SortColumn].ColType Else SortedType:=ctDate;
  For I:=0 To ColumnCount-1 Do Begin
   Columns[I]:=ColumnsDraft[I];
   If HasSort And (Columns[I].ColType=SortedType) Then SortColumn:=I;
  End;
 End;
 ColumnsDialogVisible:=False; DrawInterface;
End;

Procedure MoveColumnsDraft(Delta: Integer);
Var Target: Integer; Temp: TColumnHeader;
Begin
 Target:=ColumnsDialogSelection+Delta;
 If (Target<0) Or (Target>=ColumnCount) Then Exit;
 Temp:=ColumnsDraft[Target]; ColumnsDraft[Target]:=ColumnsDraft[ColumnsDialogSelection];
 ColumnsDraft[ColumnsDialogSelection]:=Temp; ColumnsDialogSelection:=Target;
End;

Procedure ColumnsDialogAction(Action: Integer);
Var Saved: Array[0..MAX_COLUMNS-1] Of TColumnHeader;
 I,J: Integer;
Begin
 ColumnsDialogError:='';
 Case Action Of
  0: ColumnsDraft[ColumnsDialogSelection].Visible:=Not ColumnsDraft[ColumnsDialogSelection].Visible;
  1: MoveColumnsDraft(-1);
  2: MoveColumnsDraft(1);
  3: Begin
   { Retrouver l ordre initial sans modifier les colonnes actives. }
   For I:=0 To ColumnCount-1 Do Saved[I]:=ColumnsDraft[I];
   For I:=0 To ColumnCount-1 Do
    For J:=0 To ColumnCount-1 Do If Ord(Saved[J].ColType)=I Then Begin
     ColumnsDraft[I]:=Saved[J]; ColumnsDraft[I].Visible:=True;
    End;
   ColumnsDialogSelection:=0;
  End;
  4: Begin CloseColumnsDialog(True); Exit; End;
  5: Begin CloseColumnsDialog(False); Exit; End;
 End;
 DrawInterface;
End;

Procedure HandleColumnsDialogClick(MX,MY: Integer);
Var X,Y: Integer;
Begin
 X:=(SCREEN_WIDTH-380) Div 2; Y:=(SCREEN_HEIGHT-290) Div 2;
 If (MX>=X+16) And (MX<=X+236) And (MY>=Y+54) And (MY<Y+54+ColumnCount*22) Then Begin
  ColumnsDialogSelection:=(MY-Y-54) Div 22; ColumnsDialogFocus:=0;
  If MX<X+65 Then Begin ColumnsDialogAction(0); Exit; End;
 End Else If (MX>=X+250) And (MX<=X+362) And
             ((MY<Y+200) Or (MX>=X+268)) Then Begin
  If (MY>=Y+56) And (MY<=Y+80) Then ColumnsDialogFocus:=1
  Else If (MY>=Y+90) And (MY<=Y+114) Then ColumnsDialogFocus:=2
  Else If (MY>=Y+132) And (MY<=Y+156) Then ColumnsDialogFocus:=3
  Else If (MX>=X+268) And (MY>=Y+250) And (MY<=Y+274) Then ColumnsDialogFocus:=5
  Else Begin DrawInterface; Exit; End;
  ColumnsDialogAction(ColumnsDialogFocus); Exit;
 End Else If (MX>=X+180) And (MX<=X+256) And (MY>=Y+250) And (MY<=Y+274) Then Begin
  ColumnsDialogAction(4); Exit;
 End;
 DrawInterface;
End;

Procedure HandleColumnsDialogKey(Key: Char; Extended: Boolean);
Begin
 If Extended Then Begin
  Case Key Of
   #72: If ColumnsDialogFocus=0 Then
    ColumnsDialogSelection:=(ColumnsDialogSelection+ColumnCount-1) Mod ColumnCount;
   #80: If ColumnsDialogFocus=0 Then
    ColumnsDialogSelection:=(ColumnsDialogSelection+1) Mod ColumnCount;
   #71: If ColumnsDialogFocus=0 Then ColumnsDialogSelection:=0;
   #79: If ColumnsDialogFocus=0 Then ColumnsDialogSelection:=ColumnCount-1;
   #15: ColumnsDialogFocus:=(ColumnsDialogFocus+5) Mod 6;
  End;
 End Else Case Key Of
  #27: Begin CloseColumnsDialog(False); Exit; End;
  #9: ColumnsDialogFocus:=(ColumnsDialogFocus+1) Mod 6;
  #13: Begin
   If ColumnsDialogFocus=0 Then CloseColumnsDialog(True)
   Else ColumnsDialogAction(ColumnsDialogFocus);
   Exit;
  End;
  ' ': Begin ColumnsDialogAction(ColumnsDialogFocus); Exit; End;
 End;
 DrawInterface;
End;

Procedure DrawSortDialog;
Var X,Y,I,C: Integer; LabelText: String;
Begin
 If Not SortDialogVisible Then Exit;
 X:=(SCREEN_WIDTH-340) Div 2; Y:=(SCREEN_HEIGHT-270) Div 2;
 DrawDialogBox(X,Y,340,270,'Trier par...');
 GSetColor(Black); GOutTextXY(X+16,Y+34,'Critere :');
 For I:=0 To 6 Do Begin
  C:=White; If I=SortDialogCriterion Then C:=Blue;
  FillRect(X+16,Y+52+I*22,X+180,Y+72+I*22,C);
  If I=SortDialogCriterion Then GSetColor(White) Else GSetColor(Black);
  LabelText:=SortCriterionName(I);
  If (SortDialogFocus=0) And (I=SortDialogCriterion) Then LabelText:='> '+LabelText;
  GOutTextXY(X+20,Y+58+I*22,LabelText);
 End;
 GSetColor(Black); GOutTextXY(X+196,Y+34,'Ordre :');
 LabelText:='( ) Croissant'; If SortDialogOrder=soAscending Then LabelText:='(*) Croissant';
 GOutTextXY(X+196,Y+64,LabelText);
 LabelText:='( ) Decroissant'; If SortDialogOrder=soDescending Then LabelText:='(*) Decroissant';
 GOutTextXY(X+196,Y+94,LabelText);
 If SortDialogFocus=1 Then GOutTextXY(X+188,Y+120,'^ Fleches / Espace');
 DrawDialogButton(X+150,Y+232,76,24,'OK',SortDialogFocus=2,True);
 DrawDialogButton(X+238,Y+232,86,24,'Annuler',SortDialogFocus=3,True);
End;

Procedure ShowSortDialog;
Begin
 If ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or ColumnsDialogVisible Or
    RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Then Exit;
 SortDialogCriterion:=Ord(ctDate);
 If (SortColumn>=0) And (SortColumn<ColumnCount) Then
  SortDialogCriterion:=Ord(Columns[SortColumn].ColType);
 SortDialogOrder:=SortOrder;
 If SortDialogOrder=soNone Then SortDialogOrder:=soAscending;
 SortDialogFocus:=0; SortDialogVisible:=True;
 ContextMenuVisible:=False; DrawInterface;
End;

Procedure CloseSortDialog(Apply: Boolean);
Var I: Integer;
Begin
 If Apply Then Begin
  For I:=0 To ColumnCount-1 Do
   If Ord(Columns[I].ColType)=SortDialogCriterion Then Begin
    SortColumn:=I; SortOrder:=SortDialogOrder; SortMessageList; Break;
   End;
 End;
 SortDialogVisible:=False; DrawInterface;
End;

Procedure HandleSortDialogClick(MX,MY: Integer);
Var X,Y: Integer;
Begin
 X:=(SCREEN_WIDTH-340) Div 2; Y:=(SCREEN_HEIGHT-270) Div 2;
 If (MX>=X+16) And (MX<=X+180) And (MY>=Y+52) And (MY<Y+206) Then Begin
  SortDialogCriterion:=(MY-Y-52) Div 22; SortDialogFocus:=0;
 End Else If (MX>=X+188) And (MX<X+330) And (MY>=Y+52) And (MY<Y+112) Then Begin
  SortDialogFocus:=1;
  If MY<Y+82 Then SortDialogOrder:=soAscending Else SortDialogOrder:=soDescending;
 End Else If (MY>=Y+232) And (MY<=Y+256) Then Begin
  If (MX>=X+150) And (MX<=X+226) Then Begin CloseSortDialog(True); Exit; End;
  If (MX>=X+238) And (MX<=X+324) Then Begin CloseSortDialog(False); Exit; End;
 End;
 DrawInterface;
End;

Procedure HandleSortDialogKey(Key: Char; Extended: Boolean);
Begin
 If Extended Then Begin
  Case Key Of
   #72,#75: If SortDialogFocus=0 Then
     SortDialogCriterion:=(SortDialogCriterion+6) Mod 7
    Else If SortDialogFocus=1 Then SortDialogOrder:=soAscending;
   #80,#77: If SortDialogFocus=0 Then
     SortDialogCriterion:=(SortDialogCriterion+1) Mod 7
    Else If SortDialogFocus=1 Then SortDialogOrder:=soDescending;
   #71: If SortDialogFocus=0 Then SortDialogCriterion:=0;
   #79: If SortDialogFocus=0 Then SortDialogCriterion:=6;
   #15: SortDialogFocus:=(SortDialogFocus+3) Mod 4;
  End;
 End Else Case Key Of
  #27: Begin CloseSortDialog(False); Exit; End;
  #13: Begin CloseSortDialog(SortDialogFocus<>3); Exit; End;
  #9: SortDialogFocus:=(SortDialogFocus+1) Mod 4;
  ' ': Case SortDialogFocus Of
   1: If SortDialogOrder=soAscending Then SortDialogOrder:=soDescending
      Else SortDialogOrder:=soAscending;
   2,3: Begin CloseSortDialog(SortDialogFocus=2); Exit; End;
  End;
 End;
 DrawInterface;
End;

{ Dessine l'icone de priorite }
Procedure DrawPriorityIcon(X, Y: Integer; Priority: TMessagePriority);
Begin
 Case Priority Of
  mpHigh: Begin
   GSetColor(LightRed);
   GOutTextXY(X + 4, Y, '!');
  End;
  mpLow: Begin
   GSetColor(LightBlue);
   GOutTextXY(X + 2, Y, 'v');
  End;
 End;
End;

{ Dessine l'icone de piece jointe }
Procedure DrawAttachIcon2(X, Y: Integer);
Begin
 GSetColor(COLOR_MENU_TEXT);
 { Dessine un trombone simplifie }
 GLine(X + 3, Y + 2, X + 3, Y + 10);
 GLine(X + 3, Y + 10, X + 8, Y + 10);
 GLine(X + 8, Y + 10, X + 8, Y + 4);
 GLine(X + 8, Y + 4, X + 5, Y + 4);
 GLine(X + 5, Y + 4, X + 5, Y + 8);
End;

{ Dessine l'icone de drapeau }
Procedure DrawFlagIcon(X, Y: Integer);
Begin
 GSetColor(LightRed);
 { Mat du drapeau }
 GLine(X + 3, Y + 2, X + 3, Y + 12);
 { Drapeau triangulaire }
 GLine(X + 3, Y + 2, X + 10, Y + 5);
 GLine(X + 10, Y + 5, X + 3, Y + 8);
End;

{ Calcule les positions X des colonnes }
Procedure CalculateColumnPositions;
Var
 I, X: Integer;
Begin
 X := Layout.MessageListRect.X1 + 2;
 For I := 0 To ColumnCount - 1 Do Begin
  Columns[I].X := X;
  If Columns[I].Visible Then X := X + Columns[I].Width;
 End;
End;

{ Trouve l'index de la colonne a une position X }
Function GetColumnAtPoint(X: Integer): Integer;
Var
 I: Integer;
Begin
 GetColumnAtPoint := -1;
 For I := 0 To ColumnCount - 1 Do Begin
  If Columns[I].Visible And (X >= Columns[I].X) And
     (X < Columns[I].X + Columns[I].Width) Then Begin
   GetColumnAtPoint := I;
   Exit;
  End;
 End;
End;

{ Trouve l'index du message a une position Y }
Function GetMessageAtPoint(X, Y: Integer): Integer;
Var
 I: Integer;
Begin
 GetMessageAtPoint := -1;

 { Verifier si on est dans la zone des messages }
 If (X < Layout.MessageListRect.X1) Or (X > Layout.MessageListRect.X2) Then Exit;
 If (Y < Layout.MessageListRect.Y1 + COLUMN_HEADER_HEIGHT) Then Exit;
 If (Y > Layout.MessageListRect.Y2) Then Exit;

 For I := 0 To MessageCount - 1 Do Begin
  If (Messages^[I].Y > 0) And
     (Y >= Messages^[I].Y) And
     (Y < Messages^[I].Y + MESSAGE_ROW_HEIGHT) Then Begin
   GetMessageAtPoint := I;
   Exit;
  End;
 End;
End;

{ Deselectionne tous les messages }
Procedure DeselectAllMessages;
Var
 I: Integer;
Begin
 For I := 0 To MessageCount - 1 Do
  Messages^[I].IsSelected := False;
End;

{ Compte le nombre de messages selectionnes }
Function GetSelectedMessageCount: Integer;
Var
 I, Count: Integer;
Begin
 Count := 0;
 For I := 0 To MessageCount - 1 Do
  If Messages^[I].IsSelected Then Inc(Count);
 GetSelectedMessageCount := Count;
End;

{ Selectionne une plage de messages (pour Shift+clic) }
Procedure SelectMessageRange(FromIdx, ToIdx: Integer);
Var
 I, StartIdx, EndIdx: Integer;
Begin
 If FromIdx < ToIdx Then Begin
  StartIdx := FromIdx;
  EndIdx := ToIdx;
 End
 Else Begin
  StartIdx := ToIdx;
  EndIdx := FromIdx;
 End;

 For I := StartIdx To EndIdx Do
  Messages^[I].IsSelected := True;
End;

{ Gere le clic sur l'en-tete de colonne }
Procedure HandleColumnHeaderClick(ColIdx: Integer);
Begin
 If (ColIdx < 0) Or (ColIdx >= ColumnCount) Then Exit;
 If Not Columns[ColIdx].Sortable Then Exit;

 If SortColumn = ColIdx Then Begin
  { Basculer l'ordre de tri }
  If SortOrder = soAscending Then
   SortOrder := soDescending
  Else
   SortOrder := soAscending;
 End
 Else Begin
  SortColumn := ColIdx;
  SortOrder := soAscending;
 End;

 SortMessageList;
End;

{ Gere le clic sur un message }
Procedure HandleMessageClick(MsgIdx: Integer);
Var
 OldSelected: Integer;
Begin
 If (MsgIdx < 0) Or (MsgIdx >= MessageCount) Then Exit;

 OldSelected := SelectedMessage;

 If ShiftKeyDown And (LastSelectedMessage >= 0) Then Begin
  { Selection de plage avec Shift }
  DeselectAllMessages;
  SelectMessageRange(LastSelectedMessage, MsgIdx);
  SelectedMessage := MsgIdx;
 End
 Else If CtrlKeyDown Then Begin
  { Selection multiple avec Ctrl }
  Messages^[MsgIdx].IsSelected := Not Messages^[MsgIdx].IsSelected;
  If Messages^[MsgIdx].IsSelected Then Begin
   SelectedMessage := MsgIdx;
   LastSelectedMessage := MsgIdx;
  End;
 End
 Else Begin
  { Selection simple }
  DeselectAllMessages;
  Messages^[MsgIdx].IsSelected := True;
  SelectedMessage := MsgIdx;
  LastSelectedMessage := MsgIdx;
 End;

 { Reinitialiser le defilement du volet de previsualisation si nouveau message }
 If SelectedMessage <> OldSelected Then Begin
  PreviewScrollY := 0;
  PreviewScrollX := 0;
 End;
End;

{ Initialise le menu contextuel des messages }
Procedure InitializeContextMenu;
Begin
 ContextMenuItemCount := 8;

 ContextMenuItems[0].Caption := 'Ouvrir';
 ContextMenuItems[0].Shortcut := 'Entree';
 ContextMenuItems[0].Separator := False;
 ContextMenuItems[0].Enabled := True;
 ContextMenuItems[0].ItemID := CMD_FILE_OPEN;

 ContextMenuItems[1].Caption := '';
 ContextMenuItems[1].Shortcut := '';
 ContextMenuItems[1].Separator := True;
 ContextMenuItems[1].Enabled := True;
 ContextMenuItems[1].ItemID := 0;

 ContextMenuItems[2].Caption := 'Repondre';
 ContextMenuItems[2].Shortcut := 'Ctrl+R';
 ContextMenuItems[2].Separator := False;
 ContextMenuItems[2].Enabled := True;
 ContextMenuItems[2].ItemID := CMD_MSG_REPLY;

 ContextMenuItems[3].Caption := 'Repondre a tous';
 ContextMenuItems[3].Shortcut := 'Ctrl+Maj+R';
 ContextMenuItems[3].Separator := False;
 ContextMenuItems[3].Enabled := True;
 ContextMenuItems[3].ItemID := CMD_MSG_REPLYALL;

 ContextMenuItems[4].Caption := 'Transferer';
 ContextMenuItems[4].Shortcut := 'Ctrl+F';
 ContextMenuItems[4].Separator := False;
 ContextMenuItems[4].Enabled := True;
 ContextMenuItems[4].ItemID := CMD_MSG_FORWARD;

 ContextMenuItems[5].Caption := '';
 ContextMenuItems[5].Shortcut := '';
 ContextMenuItems[5].Separator := True;
 ContextMenuItems[5].Enabled := True;
 ContextMenuItems[5].ItemID := 0;

 ContextMenuItems[6].Caption := 'Marquer comme lu';
 ContextMenuItems[6].Shortcut := '';
 ContextMenuItems[6].Separator := False;
 ContextMenuItems[6].Enabled := True;
 ContextMenuItems[6].ItemID := 801;

 ContextMenuItems[7].Caption := 'Supprimer';
 ContextMenuItems[7].Shortcut := 'Suppr';
 ContextMenuItems[7].Separator := False;
 ContextMenuItems[7].Enabled := True;
 ContextMenuItems[7].ItemID := CMD_MSG_DELETE;
End;

{ Affiche le menu contextuel }
Procedure ShowContextMenu(X, Y: Integer);
Var
 I, MaxWidth, ItemHeight: Integer;
Begin
 InitializeContextMenu;

 { Calculer les dimensions }
 MaxWidth := 150;
 ItemHeight := 0;
 For I := 0 To ContextMenuItemCount - 1 Do Begin
  If ContextMenuItems[I].Separator Then
   ItemHeight := ItemHeight + 6
  Else
   ItemHeight := ItemHeight + 18;
 End;

 ContextMenuX := X;
 ContextMenuY := Y;
 ContextMenuWidth := MaxWidth;
 ContextMenuHeight := ItemHeight + 4;

 { Ajuster si hors ecran }
 If ContextMenuX + ContextMenuWidth > GGetMaxX Then
  ContextMenuX := GGetMaxX - ContextMenuWidth;
 If ContextMenuY + ContextMenuHeight > GGetMaxY Then
  ContextMenuY := GGetMaxY - ContextMenuHeight;

 ContextMenuVisible := True;
 HoveredContextItem := -1;
End;

{ Dessine le menu contextuel }
Procedure DrawContextMenu;
Var
 I, Y: Integer;
Begin
 If Not ContextMenuVisible Then Exit;

 { Fond du menu }
 FillRect(ContextMenuX, ContextMenuY,
          ContextMenuX + ContextMenuWidth, ContextMenuY + ContextMenuHeight,
          COLOR_BUTTON_FACE);
 Draw3DRect(ContextMenuX, ContextMenuY,
            ContextMenuX + ContextMenuWidth, ContextMenuY + ContextMenuHeight,
            True);

 Y := ContextMenuY + 2;

 For I := 0 To ContextMenuItemCount - 1 Do Begin
  If ContextMenuItems[I].Separator Then Begin
   GSetColor(COLOR_BUTTON_DARK);
   GLine(ContextMenuX + 2, Y + 2, ContextMenuX + ContextMenuWidth - 2, Y + 2);
   GSetColor(COLOR_BUTTON_LIGHT);
   GLine(ContextMenuX + 2, Y + 3, ContextMenuX + ContextMenuWidth - 2, Y + 3);
   Y := Y + 6;
  End
  Else Begin
   { Fond de l'element survole }
   If I = HoveredContextItem Then Begin
    FillRect(ContextMenuX + 2, Y,
             ContextMenuX + ContextMenuWidth - 2, Y + 16,
             COLOR_LIST_SELECTED);
    GSetColor(COLOR_LIST_SELECTED_TEXT);
   End
   Else Begin
    If ContextMenuItems[I].Enabled Then
     GSetColor(COLOR_MENU_TEXT)
    Else
     GSetColor(COLOR_BUTTON_DARK);
   End;

   GOutTextXY(ContextMenuX + 6, Y + 3, ContextMenuItems[I].Caption);

   { Raccourci a droite }
   If ContextMenuItems[I].Shortcut <> '' Then
    GOutTextXY(ContextMenuX + ContextMenuWidth - 50, Y + 3,
              ContextMenuItems[I].Shortcut);

   Y := Y + 18;
  End;
 End;
End;

{ Cache le menu contextuel }
Procedure HideContextMenu;
Begin
 ContextMenuVisible := False;
 HoveredContextItem := -1;
End;

{ Trouve l'element du menu contextuel a une position }
Function GetContextMenuItemAtPoint(X, Y: Integer): Integer;
Var
 I, ItemY: Integer;
Begin
 GetContextMenuItemAtPoint := -1;
 If Not ContextMenuVisible Then Exit;

 If (X < ContextMenuX) Or (X > ContextMenuX + ContextMenuWidth) Or
    (Y < ContextMenuY) Or (Y > ContextMenuY + ContextMenuHeight) Then Exit;

 ItemY := ContextMenuY + 2;
 For I := 0 To ContextMenuItemCount - 1 Do Begin
  If ContextMenuItems[I].Separator Then Begin
   ItemY := ItemY + 6;
  End
  Else Begin
   If (Y >= ItemY) And (Y < ItemY + 18) Then Begin
    If ContextMenuItems[I].Enabled Then
     GetContextMenuItemAtPoint := I;
    Exit;
   End;
   ItemY := ItemY + 18;
  End;
 End;
End;

{ Dessine le panneau des dossiers (arbre de navigation) }
Procedure DrawFolderPane;
Var
 Y, I: Integer;
 IndentX: Integer;
 NodeText: String;
 TxtColorV: Word;
 BgColor: Word;
Begin
 { Fond du panneau }
 FillRect(Layout.FolderPaneRect.X1, Layout.FolderPaneRect.Y1,
          Layout.FolderPaneRect.X2, Layout.FolderPaneRect.Y2, COLOR_FOLDER_BG);
 Draw3DRect(Layout.FolderPaneRect.X1, Layout.FolderPaneRect.Y1,
            Layout.FolderPaneRect.X2, Layout.FolderPaneRect.Y2, False);

 { Titre du panneau }
 GSetColor(COLOR_MENU_TEXT);
 Y := Layout.FolderPaneRect.Y1 + 4;
 GOutTextXY(Layout.FolderPaneRect.X1 + 4, Y, 'Dossiers');

 Y := Y + 16;
 GSetColor(COLOR_BUTTON_DARK);
 GLine(Layout.FolderPaneRect.X1 + 2, Y, Layout.FolderPaneRect.X2 - 2, Y);
 Y := Y + 8;

 { Dessiner l'arbre des dossiers }
 For I := 0 To FolderCount - 1 Do Begin
  If Not Folders[I].Visible Then Continue;

  { Sauvegarder la position Y pour la detection des clics }
  Folders[I].Y := Y;

  { Verifier si on depasse la zone visible }
  If Y + FOLDER_NODE_HEIGHT > Layout.FolderPaneRect.Y2 - 2 Then
   Break;

  IndentX := Layout.FolderPaneRect.X1 + 4 + (Folders[I].Level * FOLDER_INDENT);

  { Determiner les couleurs selon l'etat }
  If Folders[I].Selected Then Begin
   BgColor := COLOR_LIST_SELECTED;
   TxtColorV := COLOR_LIST_SELECTED_TEXT;
  End
  Else If I = HoveredFolder Then Begin
   BgColor := COLOR_BUTTON_FACE;
   TxtColorV := COLOR_MENU_TEXT;
  End
  Else Begin
   BgColor := COLOR_FOLDER_BG;
   TxtColorV := COLOR_MENU_TEXT;
  End;

  { Dessiner le fond si selectionne ou survole }
  If Folders[I].Selected Or (I = HoveredFolder) Then Begin
   FillRect(Layout.FolderPaneRect.X1 + 2, Y - 1,
            Layout.FolderPaneRect.X2 - 2, Y + FOLDER_NODE_HEIGHT - 3, BgColor);
  End;

  { Dessiner le symbole d'expansion si le dossier a des enfants }
  If HasChildren(I) Then Begin
   DrawExpandSymbol(IndentX, Y + 2, Folders[I].Expanded);
   IndentX := IndentX + 12;
  End
  Else Begin
   IndentX := IndentX + 12;
  End;

  { Dessiner l'icone du dossier }
  DrawFolderIcon(IndentX, Y, Folders[I].FolderType, Folders[I].Expanded);
  IndentX := IndentX + 16;

  { Preparer le texte avec compteur de messages non lus }
  If Folders[I].UnreadCount > 0 Then Begin
   Str(Folders[I].UnreadCount, NodeText);
   NodeText := Folders[I].Name + ' (' + NodeText + ')';
  End
  Else
   NodeText := Folders[I].Name;

  { Dessiner le texte }
  GSetColor(TxtColorV);
  GOutTextXY(IndentX, Y + 2, NodeText);

  Y := Y + FOLDER_NODE_HEIGHT;
 End;
End;

{ Dessine la liste des messages }
Procedure DrawMessageList;
Var
 Y, I, J: Integer;
 TxtColorV: Word;
 BgColor: Word;
 DisplayText: String;
 MaxY: Integer;
Begin
 GSetViewPort(0,0,Layout.MessageListRect.X2,SCREEN_HEIGHT-1,True);
 { Calculer les positions des colonnes }
 CalculateColumnPositions;

 { Fond de la liste }
 FillRect(Layout.MessageListRect.X1, Layout.MessageListRect.Y1,
          Layout.MessageListRect.X2, Layout.MessageListRect.Y2, COLOR_LIST_BG);
 Draw3DRect(Layout.MessageListRect.X1, Layout.MessageListRect.Y1,
            Layout.MessageListRect.X2, Layout.MessageListRect.Y2, False);

 { En-tetes de colonnes }
 Y := Layout.MessageListRect.Y1;
 FillRect(Layout.MessageListRect.X1 + 1, Y + 1,
          Layout.MessageListRect.X2 - 1, Y + COLUMN_HEADER_HEIGHT - 1, COLOR_BUTTON_FACE);
 Draw3DRect(Layout.MessageListRect.X1 + 1, Y + 1,
            Layout.MessageListRect.X2 - 1, Y + COLUMN_HEADER_HEIGHT - 1, True);

 { Dessiner chaque en-tete de colonne }
 For I := 0 To ColumnCount - 1 Do Begin
  If Not Columns[I].Visible Then Continue;
  { Separateur vertical }
  If I > 0 Then Begin
   GSetColor(COLOR_BUTTON_DARK);
   GLine(Columns[I].X - 1, Y + 2, Columns[I].X - 1, Y + COLUMN_HEADER_HEIGHT - 3);
  End;

  { Titre de la colonne }
  GSetColor(COLOR_MENU_TEXT);
  GOutTextXY(Columns[I].X + 4, Y + 4, Columns[I].Title);

  { Indicateur de tri }
  If (I = SortColumn) And (SortOrder <> soNone) Then Begin
   DrawSortIndicator(Columns[I].X + Columns[I].Width - 14, Y + 5,
                     SortOrder = soAscending);
  End;
 End;

 { Messages^ }
 Y := Layout.MessageListRect.Y1 + COLUMN_HEADER_HEIGHT + 1;
 MaxY := Layout.MessageListRect.Y2 - MESSAGE_ROW_HEIGHT;

 If MessageScrollOffset > MessageCount - 1 Then MessageScrollOffset := MessageCount - 1;
 If MessageScrollOffset < 0 Then MessageScrollOffset := 0;
 For I := 0 To MessageCount - 1 Do Messages^[I].Y := -1000;
 For I := MessageScrollOffset To MessageCount - 1 Do Begin
  If Y > MaxY Then Break;

  { Sauvegarder la position Y pour la detection des clics }
  Messages^[I].Y := Y;

  { Determiner les couleurs selon l'etat }
  If Messages^[I].IsSelected Then Begin
   BgColor := COLOR_LIST_SELECTED;
   TxtColorV := COLOR_LIST_SELECTED_TEXT;
  End
  Else Begin
   BgColor := COLOR_LIST_BG;
   If OptionsReady And UserPrefs.Reading.UseAlternateRowColor And (I Mod 2=1) Then BgColor:=LightGray;
   If Messages^[I].IsRead Then
    TxtColorV := COLOR_LIST_TEXT
   Else
    TxtColorV := COLOR_MENU_TEXT; { Plus fonce pour les non lus }
  End;

  { Dessiner le fond si selectionne }
  Begin
   FillRect(Layout.MessageListRect.X1 + 1, Y,
            Layout.MessageListRect.X2 - 1, Y + MESSAGE_ROW_HEIGHT - 1, BgColor);
  End;

  { Dessiner chaque colonne }
  For J := 0 To ColumnCount - 1 Do Begin
   If Not Columns[J].Visible Then Continue;
   Case Columns[J].ColType Of
    ctPriority: Begin
     DrawPriorityIcon(Columns[J].X, Y + 1, Messages^[I].Priority);
    End;

    ctAttachment: Begin
     If Messages^[I].HasAttachment Then
      DrawAttachIcon2(Columns[J].X, Y + 1);
    End;

    ctFlag: Begin
     If Messages^[I].IsFlagged Then
      DrawFlagIcon(Columns[J].X, Y + 1);
    End;

    ctFrom: Begin
     GSetColor(TxtColorV);
     { Tronquer si trop long }
     DisplayText := OlFit(Messages^[I].FromName, Columns[J].Width);
     GOutTextXY(Columns[J].X + 2, Y + 2, DisplayText);
    End;

    ctSubject: Begin
     GSetColor(TxtColorV);
     { Tronquer si trop long }
     DisplayText := OlFit(Messages^[I].Subject, Columns[J].Width);
     GOutTextXY(Columns[J].X + 2, Y + 2, DisplayText);
    End;

    ctDate: Begin
     GSetColor(TxtColorV);
     GOutTextXY(Columns[J].X + 2, Y + 2, OlFit(Messages^[I].DateStr, Columns[J].Width));
    End;

    ctSize: Begin
     GSetColor(TxtColorV);
     GOutTextXY(Columns[J].X + 2, Y + 2, OlFit(FormatSize(Messages^[I].Size), Columns[J].Width));
    End;
   End;
  End;

  Y := Y + MESSAGE_ROW_HEIGHT;
 End;

 GSetViewPort(0,0,SCREEN_WIDTH-1,SCREEN_HEIGHT-1,True);
 { Dessiner le menu contextuel si visible }
 If ContextMenuVisible Then
  DrawContextMenu;
End;

{ Dessine la barre de defilement verticale du volet de previsualisation }
Procedure DrawPreviewScrollbarV;
Var
 ScrollbarX, ScrollbarY1, ScrollbarY2: Integer;
 ThumbHeight, ThumbY: Integer;
 ContentHeight, ViewHeight: Integer;
Begin
 If Not PreviewVisible Then Exit;
 If PreviewMaxScrollY <= 0 Then Exit;

 ScrollbarX := Layout.PreviewPaneRect.X2 - PREVIEW_SCROLLBAR_WIDTH;
 ScrollbarY1 := Layout.PreviewPaneRect.Y1 + PreviewHeaderHeight + 1;
 ScrollbarY2 := Layout.PreviewPaneRect.Y2 - 1;

 { Fond de la barre de defilement }
 FillRect(ScrollbarX, ScrollbarY1, Layout.PreviewPaneRect.X2 - 1, ScrollbarY2,
          COLOR_BUTTON_FACE);
 Draw3DRect(ScrollbarX, ScrollbarY1, Layout.PreviewPaneRect.X2 - 1, ScrollbarY2,
            False);

 { Calcul du curseur }
 ViewHeight := ScrollbarY2 - ScrollbarY1 - 4;
 ContentHeight := PreviewMaxScrollY + ViewHeight;
 If ContentHeight > 0 Then Begin
  ThumbHeight := (ViewHeight * ViewHeight) Div ContentHeight;
  If ThumbHeight < 20 Then ThumbHeight := 20;
  If ThumbHeight > ViewHeight Then ThumbHeight := ViewHeight;

  ThumbY := ScrollbarY1 + 2 + ((PreviewScrollY * (ViewHeight - ThumbHeight)) Div PreviewMaxScrollY);

  { Dessiner le curseur }
  FillRect(ScrollbarX + 2, ThumbY, Layout.PreviewPaneRect.X2 - 3, ThumbY + ThumbHeight - 1,
           COLOR_BUTTON_FACE);
  Draw3DRect(ScrollbarX + 2, ThumbY, Layout.PreviewPaneRect.X2 - 3, ThumbY + ThumbHeight - 1,
             True);
 End;
End;

{ Dessine le volet de previsualisation }
Procedure DrawPreviewPane;
Var
 Y, I, BodyY, BodyTop, BodyBottom: Integer;
 MsgIdx: Integer;
 HeaderText: String;
 ContentWidth: Integer;
Begin
 { Si le volet est masque, ne rien dessiner }
 If Not PreviewVisible Then Exit;
 GSetViewPort(0,0,Layout.PreviewPaneRect.X2,SCREEN_HEIGHT-1,True);

 { Fond du volet }
 FillRect(Layout.PreviewPaneRect.X1, Layout.PreviewPaneRect.Y1,
          Layout.PreviewPaneRect.X2, Layout.PreviewPaneRect.Y2, COLOR_PREVIEW_BG);
 Draw3DRect(Layout.PreviewPaneRect.X1, Layout.PreviewPaneRect.Y1,
            Layout.PreviewPaneRect.X2, Layout.PreviewPaneRect.Y2, False);

 { Si aucun message selectionne, afficher un message par defaut }
 If (SelectedMessage < 0) Or (SelectedMessage >= MessageCount) Then Begin
  GSetColor(COLOR_BUTTON_DARK);
  Y := (Layout.PreviewPaneRect.Y1 + Layout.PreviewPaneRect.Y2) Div 2;
  GOutTextXY(Layout.PreviewPaneRect.X1 + 20, Y, 'Selectionnez un message pour le previsualiser');
  GSetViewPort(0,0,SCREEN_WIDTH-1,SCREEN_HEIGHT-1,True);
  Exit;
 End;

 MsgIdx := SelectedMessage;
 ContentWidth := Layout.PreviewPaneRect.X2 - Layout.PreviewPaneRect.X1 - PREVIEW_SCROLLBAR_WIDTH - 8;

 Y := Layout.PreviewPaneRect.Y1 + 4;

 { En-tete De: }
 GSetColor(COLOR_MENU_TEXT);
 HeaderText := 'De: ' + Messages^[MsgIdx].FromName + ' <' + Messages^[MsgIdx].FromEmail + '>';
 If Length(HeaderText) > 70 Then
  HeaderText := Copy(HeaderText, 1, 67) + '...';
 GOutTextXY(Layout.PreviewPaneRect.X1 + 4, Y, HeaderText);
 Y := Y + PREVIEW_LINE_HEIGHT;

 { En-tete A: }
 HeaderText := 'A: ' + Messages^[MsgIdx].ToEmail;
 If Length(HeaderText) > 70 Then
  HeaderText := Copy(HeaderText, 1, 67) + '...';
 GOutTextXY(Layout.PreviewPaneRect.X1 + 4, Y, HeaderText);
 Y := Y + PREVIEW_LINE_HEIGHT;

 { En-tete Cc: (si present) }
 If Messages^[MsgIdx].CcEmail <> '' Then Begin
  HeaderText := 'Cc: ' + Messages^[MsgIdx].CcEmail;
  If Length(HeaderText) > 70 Then
   HeaderText := Copy(HeaderText, 1, 67) + '...';
  GOutTextXY(Layout.PreviewPaneRect.X1 + 4, Y, HeaderText);
  Y := Y + PREVIEW_LINE_HEIGHT;
 End;

 { En-tete Date: }
 HeaderText := 'Date: ' + Messages^[MsgIdx].DateFull;
 GOutTextXY(Layout.PreviewPaneRect.X1 + 4, Y, HeaderText);
 Y := Y + PREVIEW_LINE_HEIGHT;

 { En-tete Objet: }
 HeaderText := 'Objet: ' + Messages^[MsgIdx].Subject;
 If Length(HeaderText) > 70 Then
  HeaderText := Copy(HeaderText, 1, 67) + '...';
 GOutTextXY(Layout.PreviewPaneRect.X1 + 4, Y, HeaderText);
 Y := Y + 8;

 { Ligne de separation }
 GSetColor(COLOR_BUTTON_DARK);
 GLine(Layout.PreviewPaneRect.X1 + 2, Y, Layout.PreviewPaneRect.X2 - PREVIEW_SCROLLBAR_WIDTH - 2, Y);
 GSetColor(COLOR_BUTTON_LIGHT);
 GLine(Layout.PreviewPaneRect.X1 + 2, Y + 1, Layout.PreviewPaneRect.X2 - PREVIEW_SCROLLBAR_WIDTH - 2, Y + 1);

 { Zone de contenu du message avec defilement }
 BodyTop := Y + 4;
 BodyBottom := Layout.PreviewPaneRect.Y2 - 2;
 BodyY := BodyTop - (PreviewScrollY * PREVIEW_LINE_HEIGHT);

 { Calculer le defilement maximum }
 PreviewMaxScrollY := Messages^[MsgIdx].BodyLineCount - ((BodyBottom - BodyTop) Div PREVIEW_LINE_HEIGHT);
 If PreviewMaxScrollY < 0 Then PreviewMaxScrollY := 0;

 { Ajuster le defilement si necessaire }
 If PreviewScrollY > PreviewMaxScrollY Then PreviewScrollY := PreviewMaxScrollY;
 If PreviewScrollY < 0 Then PreviewScrollY := 0;

 { Definir le rectangle de decoupage pour le corps }
 GSetViewPort(Layout.PreviewPaneRect.X1 + 2, BodyTop,
             Layout.PreviewPaneRect.X2 - PREVIEW_SCROLLBAR_WIDTH - 2, BodyBottom, True);

 { Dessiner les lignes du corps du message }
 GSetColor(COLOR_LIST_TEXT);
 For I := 0 To Messages^[MsgIdx].BodyLineCount - 1 Do Begin
  If (BodyY >= BodyTop - PREVIEW_LINE_HEIGHT) And (BodyY <= BodyBottom) Then Begin
   GOutTextXY(2 - PreviewScrollX, BodyY - BodyTop, Messages^[MsgIdx].Body[I]);
  End;
  BodyY := BodyY + PREVIEW_LINE_HEIGHT;
 End;

 { Restaurer le viewport complet }
 GSetViewPort(0, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1, True);

 { Dessiner la barre de defilement verticale si necessaire }
 DrawPreviewScrollbarV;
End;

{ Dessine les separateurs (splitters) }
Procedure DrawSplitters;
Begin
 { Separateur vertical }
 FillRect(Layout.VSplitterRect.X1, Layout.VSplitterRect.Y1,
          Layout.VSplitterRect.X2, Layout.VSplitterRect.Y2, COLOR_SPLITTER);
 Draw3DRect(Layout.VSplitterRect.X1, Layout.VSplitterRect.Y1,
            Layout.VSplitterRect.X2, Layout.VSplitterRect.Y2, True);

 { Separateur horizontal }
 If Not PreviewVisible Then Exit;
 FillRect(Layout.HSplitterRect.X1, Layout.HSplitterRect.Y1,
          Layout.HSplitterRect.X2, Layout.HSplitterRect.Y2, COLOR_SPLITTER);
 Draw3DRect(Layout.HSplitterRect.X1, Layout.HSplitterRect.Y1,
            Layout.HSplitterRect.X2, Layout.HSplitterRect.Y2, True);
End;

{ Dessine la barre d'etat }
Procedure DrawStatusBar;
Begin
 FillRect(Layout.StatusBarRect.X1, Layout.StatusBarRect.Y1,
          Layout.StatusBarRect.X2, Layout.StatusBarRect.Y2, COLOR_STATUS_BG);
 Draw3DRect(Layout.StatusBarRect.X1, Layout.StatusBarRect.Y1,
            Layout.StatusBarRect.X2, Layout.StatusBarRect.Y2, False);

 GSetColor(COLOR_STATUS_TEXT);
 GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
           MailStatus);
End;

{ ============================================================================
  PROCEDURE PRINCIPALE DE DESSIN
  ============================================================================ }

{ Dessine toute l'interface }
Procedure DrawInterface;
Begin
 HideMouse;

 { Fond de l'ecran }
 FillRect(0, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1, COLOR_DESKTOP);

 { Calcul de la disposition }
 CalculateLayout;

 { Dessin des elements }
 DrawTitleBar;
 DrawMenuBar;
 DrawToolBar;
 DrawFolderPane;
 DrawSplitters;
 DrawMessageList;
 DrawPreviewPane;
 If CalendarVisible Then DrawCalendar;
 DrawStatusBar;

 If ComposerVisible Then DrawComposerWindow;
 If AccountDialogVisible Then DrawAccountManagerDialog;
 If FileOpenVisible Then DrawOpenFileDialog;
 If SortDialogVisible Then DrawSortDialog;
 If ColumnsDialogVisible Then DrawColumnsDialog;
 If RulesVisible Then Rules_DrawWindow;
 If PrefsVisible Then Prefs_DrawWindow;
 If AboutVisible Then DrawAboutDialog;
 If EventDialogVisible Then EventDraw;
 If BusyVisible Then DrawBusyDialog;
 ShowMouse;
End;

{ ============================================================================
  PROCEDURES DE GESTION DES EVENEMENTS
  ============================================================================ }

{ Verifie si un point est dans un rectangle }
Function PointInRect(X, Y, X1, Y1, X2, Y2: Integer): Boolean;
Begin
 PointInRect := (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2);
End;

{ Gere le redimensionnement des panneaux avec la souris }
Procedure HandleMouseDrag;
Var
 NewWidth, NewHeight: Integer;
Begin
 Case DragState Of
  dsDragVSplitter: Begin
   { Redimensionnement du panneau des dossiers }
   NewWidth := MouseX - SPLITTER_SIZE Div 2;
   If NewWidth < MIN_FOLDER_WIDTH Then NewWidth := MIN_FOLDER_WIDTH;
   If NewWidth > SCREEN_WIDTH - MIN_MESSAGE_WIDTH - SPLITTER_SIZE Then
    NewWidth := SCREEN_WIDTH - MIN_MESSAGE_WIDTH - SPLITTER_SIZE;
   If CalendarVisible And (NewWidth>SCREEN_WIDTH-CalendarPaneWidth-144) Then
    NewWidth:=SCREEN_WIDTH-CalendarPaneWidth-144;
   If NewWidth <> Layout.FolderPaneWidth Then Begin
    Layout.FolderPaneWidth := NewWidth;
    DrawInterface;
   End;
  End;
  dsDragHSplitter: Begin
   If PreviewOrientation=poVertical Then Begin
    PreviewPaneWidth:=SCREEN_WIDTH-MouseX;
    If CalendarVisible Then Dec(PreviewPaneWidth,CalendarPaneWidth+SPLITTER_SIZE);
    If PreviewPaneWidth<120 Then PreviewPaneWidth:=120;
    DrawInterface; Exit;
   End;
   { Redimensionnement du volet de previsualisation }
   NewHeight := Layout.StatusBarRect.Y1 - MouseY - SPLITTER_SIZE;
   If NewHeight < MIN_PREVIEW_HEIGHT Then NewHeight := MIN_PREVIEW_HEIGHT;
   If NewHeight > Layout.StatusBarRect.Y1 - Layout.ToolBarRect.Y2 -
      MIN_PREVIEW_HEIGHT - SPLITTER_SIZE * 2 Then
    NewHeight := Layout.StatusBarRect.Y1 - Layout.ToolBarRect.Y2 -
                 MIN_PREVIEW_HEIGHT - SPLITTER_SIZE * 2;
   If NewHeight <> Layout.PreviewPaneHeight Then Begin
    Layout.PreviewPaneHeight := NewHeight;
    DrawInterface;
   End;
  End;
 End;
End;

{ Gere les clics de souris }
Procedure HandleMouseClick;
Var
 ClickedMenu: Integer;
 ClickedItem: Integer;
Begin
 If RibbonMode Then Begin
  ClickedMenu:=RibbonTabAt(MouseX,MouseY);
  If ClickedMenu>=0 Then Begin RibbonSelectTab(ClickedMenu,False); Exit; End;
 End;
 { Si un menu est ouvert, verifier le clic }
 If ActiveMenu >= 0 Then Begin
  { Clic sur un element du menu deroulant? }
  ClickedItem := GetMenuItemAtPoint(MouseX, MouseY);
  If ClickedItem >= 0 Then Begin
   If Menus[ActiveMenu].Items[ClickedItem].Enabled Then
    ExecuteMenuCommand(Menus[ActiveMenu].Items[ClickedItem].ItemID);
   Exit;
  End;

  { Clic sur un autre menu de la barre? }
  ClickedMenu := GetMenuAtPoint(MouseX, MouseY);
  If (ClickedMenu >= 0) And (ClickedMenu <> ActiveMenu) Then Begin
   ActiveMenu := ClickedMenu;
   ActiveMenuItem := -1;
   DrawInterface;
   DrawDropdownMenu(ActiveMenu);
   Exit;
  End;

  { Clic ailleurs = fermer le menu }
  CloseDropdownMenu;
  Exit;
 End;

 { Verifier le clic sur la barre de menu }
 ClickedMenu := GetMenuAtPoint(MouseX, MouseY);
 If ClickedMenu >= 0 Then Begin
  ActiveMenu := ClickedMenu;
  ActiveMenuItem := -1;
  MenuBarActive := True;
  DrawDropdownMenu(ActiveMenu);
  Exit;
 End;

 { Verifie si le clic est sur le separateur vertical }
 If PointInRect(MouseX, MouseY,
    Layout.VSplitterRect.X1, Layout.VSplitterRect.Y1,
    Layout.VSplitterRect.X2, Layout.VSplitterRect.Y2) Then Begin
  DragState := dsDragVSplitter;
  Exit;
 End;

 { Verifie si le clic est sur le separateur horizontal }
 If PointInRect(MouseX, MouseY,
    Layout.HSplitterRect.X1, Layout.HSplitterRect.Y1,
    Layout.HSplitterRect.X2, Layout.HSplitterRect.Y2) Then Begin
  DragState := dsDragHSplitter;
  Exit;
 End;

 { Verifie si le clic est sur le bouton Fermer }
 If PointInRect(MouseX, MouseY, SCREEN_WIDTH - 20, 3,
    SCREEN_WIDTH - 4, 17) Then Begin
  Running := False;
  Exit;
 End;
End;

{ Gere le clic droit de la souris (menu contextuel) }
Procedure HandleRightClick;
Begin
 { Afficher un menu contextuel selon la zone cliquee }
 If PointInRect(MouseX, MouseY,
    Layout.MessageListRect.X1, Layout.MessageListRect.Y1,
    Layout.MessageListRect.X2, Layout.MessageListRect.Y2) Then Begin
  { Menu contextuel pour la liste des messages }
  { TODO: Implementer le menu contextuel des messages }
  HideMouse;
  GSetColor(COLOR_STATUS_TEXT);
  GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
            'Clic droit: Menu contextuel message');
  ShowMouse;
 End
 Else If PointInRect(MouseX, MouseY,
    Layout.FolderPaneRect.X1, Layout.FolderPaneRect.Y1,
    Layout.FolderPaneRect.X2, Layout.FolderPaneRect.Y2) Then Begin
  { Menu contextuel pour le panneau des dossiers }
  { TODO: Implementer le menu contextuel des dossiers }
  HideMouse;
  GSetColor(COLOR_STATUS_TEXT);
  GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
            'Clic droit: Menu contextuel dossier ');
  ShowMouse;
 End;
End;

{ Gere le double-clic de la souris }
Procedure HandleDoubleClick;
Begin
 { Double-clic sur un message = ouvrir le message }
 If PointInRect(MouseX, MouseY,
    Layout.MessageListRect.X1, Layout.MessageListRect.Y1,
    Layout.MessageListRect.X2, Layout.MessageListRect.Y2) Then Begin
  { TODO: Ouvrir le message dans une nouvelle fenetre }
  HideMouse;
  FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
           Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
  GSetColor(COLOR_STATUS_TEXT);
  GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
            'Double-clic: Ouvrir le message      ');
  ShowMouse;
 End
 Else If PointInRect(MouseX, MouseY,
    Layout.FolderPaneRect.X1, Layout.FolderPaneRect.Y1,
    Layout.FolderPaneRect.X2, Layout.FolderPaneRect.Y2) Then Begin
  { Double-clic sur un dossier = developper/reduire }
  { TODO: Developper ou reduire le dossier }
  HideMouse;
  FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
           Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
  GSetColor(COLOR_STATUS_TEXT);
  GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
            'Double-clic: Developper le dossier  ');
  ShowMouse;
 End;
End;

{ Gere le defilement avec la molette de la souris }
Procedure HandleMouseWheel(Direction: Integer);
Begin
 { Direction > 0 = vers le haut, < 0 = vers le bas }

 { Defilement de la liste des messages }
 If PointInRect(MouseX, MouseY,
    Layout.MessageListRect.X1, Layout.MessageListRect.Y1,
    Layout.MessageListRect.X2, Layout.MessageListRect.Y2) Then Begin
  If Direction > 0 Then Begin
   { Defiler vers le haut }
   If ScrollOffset > 0 Then Dec(ScrollOffset);
  End Else Begin
   { Defiler vers le bas }
   Inc(ScrollOffset);
  End;
  HideMouse;
  FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
           Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
  GSetColor(COLOR_STATUS_TEXT);
  If Direction > 0 Then
   GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
             'Molette: Defiler vers le haut      ')
  Else
   GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
             'Molette: Defiler vers le bas       ');
  ShowMouse;
 End

 { Defilement du volet de previsualisation }
 Else If PreviewVisible And PointInRect(MouseX, MouseY,
    Layout.PreviewPaneRect.X1, Layout.PreviewPaneRect.Y1,
    Layout.PreviewPaneRect.X2, Layout.PreviewPaneRect.Y2) Then Begin
  If Direction > 0 Then Begin
   { Defiler vers le haut }
   PreviewScrollY := PreviewScrollY - PREVIEW_SCROLL_STEP;
   If PreviewScrollY < 0 Then PreviewScrollY := 0;
  End Else Begin
   { Defiler vers le bas }
   PreviewScrollY := PreviewScrollY + PREVIEW_SCROLL_STEP;
   If PreviewScrollY > PreviewMaxScrollY Then PreviewScrollY := PreviewMaxScrollY;
  End;
  HideMouse;
  DrawPreviewPane;
  FillRect(Layout.StatusBarRect.X1 + 1, Layout.StatusBarRect.Y1 + 1,
           Layout.StatusBarRect.X2 - 1, Layout.StatusBarRect.Y2 - 1, COLOR_STATUS_BG);
  GSetColor(COLOR_STATUS_TEXT);
  If Direction > 0 Then
   GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
             'Molette: Defiler apercu vers haut  ')
  Else
   GOutTextXY(Layout.StatusBarRect.X1 + 4, Layout.StatusBarRect.Y1 + 5,
             'Molette: Defiler apercu vers bas   ');
  ShowMouse;
 End;
End;

{ Gere le relachement du bouton de la souris }
Procedure HandleMouseRelease;
Begin
 DragState := dsNone;
End;

{ Met a jour le survol des elements de menu }
Procedure UpdateMenuHover;
Var
 NewMenu, NewItem: Integer;
Begin
 If ActiveMenu < 0 Then Exit;
 NewMenu := GetMenuAtPoint(MouseX, MouseY);
 If (NewMenu >= 0) And (NewMenu <> ActiveMenu) Then Begin
  { Effacer le deroulant precedent avant de dessiner le nouveau. }
  ActiveMenu := NewMenu;
  ActiveMenuItem := -1;
  MenuBarActive := True;
  DrawInterface;
  DrawDropdownMenu(ActiveMenu);
  Exit;
 End;
 NewItem := GetMenuItemAtPoint(MouseX, MouseY);
 If NewItem <> ActiveMenuItem Then Begin
  ActiveMenuItem := NewItem;
  DrawDropdownMenu(ActiveMenu);
 End;
End;

{ Met a jour le survol des boutons de barre d'outils }
Procedure UpdateToolbarHover;
Var
 NewHover: Integer;
 I: Integer;
 NeedRedraw: Boolean;
Begin
 If RibbonMode Then Begin
  NewHover:=RibbonButtonAt(MouseX,MouseY);
  If NewHover<>RibbonHover Then Begin RibbonHover:=NewHover; DrawToolBar; End;
  Exit;
 End;
 NewHover := GetToolButtonAtPoint(MouseX, MouseY);
 NeedRedraw := False;

 If NewHover <> HoveredToolButton Then Begin
  { Reinitialiser l'ancien bouton survole }
  If HoveredToolButton >= 0 Then Begin
   ToolButtons[HoveredToolButton].State := tbsNormal;
   NeedRedraw := True;
  End;

  { Mettre a jour le nouveau bouton survole }
  If NewHover >= 0 Then Begin
   If ToolButtons[NewHover].Enabled Then Begin
    ToolButtons[NewHover].State := tbsHover;
    NeedRedraw := True;
    { Demarrer le minuteur d'infobulle }
    TooltipStartTime := GetTickCount;
   End;
  End;

  { Cacher l'infobulle si on change de bouton }
  If TooltipVisible Then
   HideTooltip;

  HoveredToolButton := NewHover;

  { Redessiner la barre d'outils si necessaire }
  If NeedRedraw And Not TooltipVisible Then Begin
   HideMouse;
   DrawToolBar;
   ShowMouse;
  End;
 End
 Else Begin
  { Afficher l'infobulle apres le delai }
  If (HoveredToolButton >= 0) And (Not TooltipVisible) And
     (GetTickCount - TooltipStartTime >= TOOLTIP_DELAY) Then Begin
   ShowTooltip(MouseX, MouseY, ToolButtons[HoveredToolButton].Tooltip);
  End;
 End;
End;

{ Gere le clic sur un bouton de barre d'outils }
Procedure HandleToolbarClick;
Var
 BtnIdx: Integer;
Begin
 If RibbonMode Then Begin
  RibbonPressed:=RibbonButtonAt(MouseX,MouseY); RibbonKeyboardActive:=False; RibbonFocus:=-1;
  If RibbonPressed>=0 Then
   If Not Menus[RibbonTab].Items[RibbonButtons[RibbonPressed].MenuItem].Enabled Then RibbonPressed:=-1;
  DrawToolBar; Exit;
 End;
 BtnIdx := GetToolButtonAtPoint(MouseX, MouseY);
 If BtnIdx >= 0 Then Begin
  If ToolButtons[BtnIdx].Enabled Then Begin
   { Masquer l'infobulle }
   If TooltipVisible Then HideTooltip;

   { Mettre le bouton en etat appuye }
   ToolButtons[BtnIdx].State := tbsPressed;
   PressedToolButton := BtnIdx;
   HideMouse;
   DrawToolBar;
   ShowMouse;
  End;
 End;
End;

{ Gere le relachement d'un bouton de barre d'outils }
Procedure HandleToolbarRelease;
Var Index,Command: Integer;
Begin
 If RibbonMode Then Begin
  Index:=RibbonPressed; RibbonPressed:=-1;
  If (Index>=0) And (Index<RibbonCount) And (RibbonButtonAt(MouseX,MouseY)=Index) Then Begin
   Command:=RibbonButtons[Index].MenuItem;
   If Menus[RibbonTab].Items[Command].Enabled Then ExecuteMenuCommand(Menus[RibbonTab].Items[Command].ItemID);
  End;
  DrawInterface; Exit;
 End;
 If PressedToolButton >= 0 Then Begin
  { Verifier si on est toujours sur le meme bouton }
  If GetToolButtonAtPoint(MouseX, MouseY) = PressedToolButton Then Begin
   { Executer la commande du bouton }
   ExecuteMenuCommand(ToolButtons[PressedToolButton].CommandID);
  End;

  { Reinitialiser l'etat du bouton }
  ToolButtons[PressedToolButton].State := tbsNormal;
  PressedToolButton := -1;
  HideMouse;
  If ComposerVisible Then DrawComposerWindow Else DrawToolBar;
  ShowMouse;
 End;
End;

Function ApplicationHasKeyboardFocus: Boolean;

Begin
 ApplicationHasKeyboardFocus := False;
 
End;

Function MenuShortcutFromScan(Key: Char): Integer;
Begin
 Case Ord(Key) of
  33: MenuShortcutFromScan := 0; { Alt+F }
  18: MenuShortcutFromScan := 1; { Alt+E }
  30: MenuShortcutFromScan := 2; { Alt+A }
  24: MenuShortcutFromScan := 3; { Alt+O }
  50: MenuShortcutFromScan := 4; { Alt+M }
  53: MenuShortcutFromScan := 5; { Alt+? }
  Else MenuShortcutFromScan := -1;
 End;
End;

Procedure OpenMenuShortcut(MenuIndex: Integer);
Var I: Integer;
Begin
 If (MenuIndex < 0) Or (MenuIndex >= MenuCount) Then Exit;
 If ComposerVisible Or AccountDialogVisible Or FileOpenVisible Or SortDialogVisible Or ColumnsDialogVisible Or
    RulesVisible Or PrefsVisible Or AboutVisible Or EventDialogVisible Then Exit;
 TooltipVisible := False;
 ContextMenuVisible := False;
 MenuBarActive := True;
 If RibbonMode Then Begin RibbonSelectTab(MenuIndex,True); Exit; End;
 ActiveMenu := MenuIndex;
 ActiveMenuItem := -1;
 For I := 0 To Menus[MenuIndex].ItemCount - 1 Do
  If Menus[MenuIndex].Items[I].Enabled And
     Not Menus[MenuIndex].Items[I].Separator Then Begin
   ActiveMenuItem := I;
   Break;
  End;
 DrawInterface;
 DrawDropdownMenu(MenuIndex);
End;

Function NativeMenuShortcut: Integer;

Begin
 NativeMenuShortcut := -1;
 
End;

{ Ctrl+1 donne le focus au courrier; Ctrl+2 affiche et active le calendrier. }
Function NativeViewShortcut: Integer;
Begin
 NativeViewShortcut:=0;
 
End;

Procedure PollMenuShortcut;
Var MenuIndex,ViewIndex: Integer;
Begin
 ViewIndex:=NativeViewShortcut;
 If (ViewIndex<>0) And (ViewIndex<>LastViewShortcut) Then Begin
  If ViewIndex=1 Then FocusMail Else CalendarShow(True);
 End;
 LastViewShortcut:=ViewIndex;
 MenuIndex := NativeMenuShortcut;
 If (MenuIndex >= 0) And (MenuIndex <> LastMenuShortcut) Then
  OpenMenuShortcut(MenuIndex);
 LastMenuShortcut := MenuIndex;
End;

{ PtcCrt ne transmet pas toujours Alt+F4 dans son tampon de touches. }
Function ApplicationQuitRequested: Boolean;
Begin
 ApplicationQuitRequested := False;
 
End;

{ Boucle principale de gestion des evenements }

{ Moteur VBScript integre, sans unite supplementaire. }

Const
 VBS_MaxArguments=128;
 VBS_VersionText='5.812';
 VBS_ValueEmpty=0;VBS_ValueString=1;VBS_ValueNumber=2;VBS_ValueDate=3;
 VBS_ValueArray=4;VBS_ValueError=5;VBS_ValueNull=6;VBS_ValueObject=7;
 VBS_FunctionList:Array[0..66]of String[24]=(
  'ABS','ARRAY','ASC','ATN','CBOOL','CBYTE','CDATE','CDBL','CHR','CINT',
  'CLNG','COS','CSNG','CSTR','CVERR','DATE','DATESERIAL','DATEVALUE','DAY',
  'EXP','FIX','HEX','HOUR','INPUTBOX','INSTR','INT','ISARRAY','ISDATE',
  'ISEMPTY','ISERROR','ISNULL','ISNUMERIC','ISOBJECT','LBOUND','LCASE',
  'LEFT','LEN','LOG','LTRIM','MID','MINUTE','MONTH','MSGBOX','NOW','OCT',
  'RIGHT','RND','RTRIM','SECOND','SGN','SIN','SQR','STR','STRCOMP','STRING',
  'TAN','TIME','TIMESERIAL','TIMEVALUE','TRIM','UBOUND','UCASE','VAL','VARTYPE',
  'WEEKDAY','WSCRIPT.ARGUMENTS','YEAR');

Type
 VBS_PScriptLine=^VBS_TScriptLine;
 VBS_TScriptLine=Record
  Number:LongInt;
  Text:TMailText;
  Previous,Next:VBS_PScriptLine;
 End;
 VBS_PVariable=^VBS_TVariable;
 VBS_TVariable=Record
  Name:String[63];
  Value:TMailText;
  ValueKind:Byte;
  Next:VBS_PVariable;
 End;
 VBS_PCallBinding=^VBS_TCallBinding;
 VBS_TCallBinding=Record
  Name:String[63];
  ActualName:String[63];
  Existed:Boolean;
  CopyBack:Boolean;
  OldValue:TMailText;
  OldKind:Byte;
  Next:VBS_PCallBinding;
 End;
 VBS_TValue=Record
  Text:TMailText;
  Number:Real;
  IsNumber:Boolean;
  ValueKind:Byte;
 End;

Var
 VBS_FirstScriptLine,VBS_LastScriptLine:VBS_PScriptLine;
 VBS_LineCount,VBS_CurrentLine:LongInt;
 VBS_Variables:VBS_PVariable;
 VBS_ScriptArguments:Array[0..VBS_MaxArguments-1]of TMailText;
 VBS_ScriptArgumentCount:Integer;
 VBS_ScriptName:TMailText;
 VBS_TimeLimit:LongInt;
 VBS_StartHour,VBS_StartMinute,VBS_StartSecond,VBS_StartHundredth:Word;
 VBS_ExprText:TMailText;
 VBS_ExprPos:Integer;
 VBS_Terminated,VBS_ExitDoRequested,VBS_ExitForRequested,VBS_ExitSubRequested,VBS_ExitFunctionRequested:Boolean;
 VBS_OnErrorResumeNext:Boolean;
 VBS_ExitCode:Integer;
 VBS_ArrayCounter:LongInt;


Var
 CommandLineScript: TMailText;
 VBSSteps,VBSDepth: LongInt;
 VBSDiagnostic: TMailText;
 VBSStarted,VBSExplicit: Boolean;

Procedure VBSOutput(S:TMailText);
Begin
 VBSDiagnostic:=S; MailStatus:='VBScript: '+S;
End;
Function VBSHostStatement(S:TMailText):Boolean;Forward;
Function VBSHostValue(Name:TMailText;Var V:VBS_TValue):Boolean;Forward;
Procedure VBS_ScriptError(MessageText:TMailText;StopScript:Boolean);Forward;
Function VBS_Upper(S:TMailText):TMailText;
Var I:Integer;
Begin For I:=1To Length(S)Do If S[I]in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);VBS_Upper:=S;End;

Function VBS_FunctionIndex(Name:TMailText):Byte;
Var FirstIndex,LastIndex,MiddleIndex:Integer;
Begin
 Name:=VBS_Upper(Name);VBS_FunctionIndex:=255;
 FirstIndex:=Low(VBS_FunctionList);LastIndex:=High(VBS_FunctionList);
 While FirstIndex<=LastIndex Do Begin
  MiddleIndex:=(FirstIndex+LastIndex)div 2;
  If Name=VBS_FunctionList[MiddleIndex]Then Begin VBS_FunctionIndex:=MiddleIndex;Exit;End;
  If Name<VBS_FunctionList[MiddleIndex]Then LastIndex:=MiddleIndex-1
  Else FirstIndex:=MiddleIndex+1;
 End;
End;

Function VBS_Trim(S:TMailText):TMailText;
Begin
 While(Length(S)>0)and(S[1]in[' ',#9])Do Delete(S,1,1);
 While(Length(S)>0)and(S[Length(S)]in[' ',#9,#13,#10])Do Delete(S,Length(S),1);
 VBS_Trim:=S;
End;

Function VBS_StartsWith(S,Prefix:TMailText):Boolean;
Begin VBS_StartsWith:=Copy(VBS_Upper(VBS_Trim(S)),1,Length(Prefix))=VBS_Upper(Prefix);End;

Procedure VBS_AddScriptLine(S:TMailText);
Var Line:VBS_PScriptLine;
Begin
 New(Line);Inc(VBS_LineCount);Line^.Number:=VBS_LineCount;Line^.Text:=S;
 Line^.Previous:=VBS_LastScriptLine;Line^.Next:=Nil;
 If VBS_LastScriptLine<>Nil Then VBS_LastScriptLine^.Next:=Line
 Else VBS_FirstScriptLine:=Line;
 VBS_LastScriptLine:=Line;
End;

Function VBS_ScriptLineText(LineNumber:LongInt):TMailText;
Var Line:VBS_PScriptLine;
Begin
 If(LineNumber<1)or(LineNumber>VBS_LineCount)Then Begin VBS_ScriptLineText:='';Exit;End;
 If LineNumber<=(VBS_LineCount div 2)Then Begin
  Line:=VBS_FirstScriptLine;While(Line<>Nil)and(Line^.Number<LineNumber)Do Line:=Line^.Next;
 End Else Begin
  Line:=VBS_LastScriptLine;While(Line<>Nil)and(Line^.Number>LineNumber)Do Line:=Line^.Previous;
 End;
 If Line=Nil Then VBS_ScriptLineText:=''Else VBS_ScriptLineText:=Line^.Text;
End;

Procedure VBS_MakeText(S:TMailText;Var V:VBS_TValue);
Var Code:Integer;N:Real;
Begin
 V.Text:=S;Val(S,N,Code);V.IsNumber:=Code=0;
 If V.IsNumber Then Begin V.Number:=N;V.ValueKind:=VBS_ValueNumber;End
 Else Begin V.Number:=0;If S=''Then V.ValueKind:=VBS_ValueEmpty Else V.ValueKind:=VBS_ValueString;End;
End;

Procedure VBS_MakeNumber(N:Real;Var V:VBS_TValue);
Var S:TMailText;
Begin
 If Frac(N)=0Then Str(Trunc(N),S)Else Str(N:0:8,S);
 V.Text:=VBS_Trim(S);V.Number:=N;V.IsNumber:=True;V.ValueKind:=VBS_ValueNumber;
End;

Procedure VBS_MakeSingleNumber(N:Real;Var V:VBS_TValue);
Var Scale,ScaledValue:Real;
Begin
 If N=0Then Begin VBS_MakeNumber(0,V);Exit;End;
 Scale:=1;ScaledValue:=Abs(N);
 While ScaledValue>=10Do Begin ScaledValue:=ScaledValue/10;Scale:=Scale*10;End;
 While ScaledValue<1Do Begin ScaledValue:=ScaledValue*10;Scale:=Scale/10;End;
 ScaledValue:=Round(ScaledValue*1000000)/1000000;
 If N<0Then ScaledValue:=-ScaledValue;
 VBS_MakeNumber(ScaledValue*Scale,V);
End;

Function VBS_LeapYear(Year:Integer):Boolean;
Begin VBS_LeapYear:=(Year mod 4=0)and((Year mod 100<>0)or(Year mod 400=0));End;

Function VBS_MonthDays(Year,Month:Integer):Integer;
Const Days:Array[1..12]of Byte=(31,28,31,30,31,30,31,31,30,31,30,31);
Begin
 If(Month=2)and VBS_LeapYear(Year)Then VBS_MonthDays:=29 Else VBS_MonthDays:=Days[Month];
End;

Procedure VBS_MakeDateValue(Year,Month,Day:Integer;Var V:VBS_TValue);
Var SYear,SMonth,SDay:TMailText;
Begin
 If(Year>=0)and(Year<=29)Then Inc(Year,2000)
 Else If(Year>=30)and(Year<=99)Then Inc(Year,1900);
 While Month<1 Do Begin Dec(Year);Inc(Month,12);End;
 While Month>12 Do Begin Inc(Year);Dec(Month,12);End;
 While Day<1 Do Begin Dec(Month);If Month<1Then Begin Month:=12;Dec(Year);End;
  Inc(Day,VBS_MonthDays(Year,Month));End;
 While Day>VBS_MonthDays(Year,Month)Do Begin Dec(Day,VBS_MonthDays(Year,Month));Inc(Month);
  If Month>12Then Begin Month:=1;Inc(Year);End;End;
 Str(Year,SYear);Str(Month,SMonth);Str(Day,SDay);
 If Length(SMonth)<2Then SMonth:='0'+SMonth;If Length(SDay)<2Then SDay:='0'+SDay;
 VBS_MakeText(SDay+'/'+SMonth+'/'+VBS_Trim(SYear),V);V.ValueKind:=VBS_ValueDate;
End;

Procedure VBS_ParseDateValue(SourceText:TMailText;Var V:VBS_TValue);
Var FirstPart,SecondPart,ThirdPart:TMailText;P,Code,Year,Month,Day:Integer;
Begin
 SourceText:=VBS_Trim(SourceText);P:=Pos(' ',SourceText);
 If P>0Then SourceText:=Copy(SourceText,1,P-1);
 FirstPart:='';SecondPart:='';ThirdPart:='';
 P:=Pos('/',SourceText);If P=0Then P:=Pos('-',SourceText);
 If P=0Then Begin VBS_MakeText('',V);Exit;End;
 FirstPart:=Copy(SourceText,1,P-1);Delete(SourceText,1,P);
 P:=Pos('/',SourceText);If P=0Then P:=Pos('-',SourceText);
 If P=0Then Begin VBS_MakeText('',V);Exit;End;
 SecondPart:=Copy(SourceText,1,P-1);ThirdPart:=Copy(SourceText,P+1,32767);
 If Length(VBS_Trim(FirstPart))=4Then Begin
  Val(FirstPart,Year,Code);If Code<>0Then Begin VBS_MakeText('',V);Exit;End;
  Val(SecondPart,Month,Code);If Code<>0Then Begin VBS_MakeText('',V);Exit;End;
  Val(ThirdPart,Day,Code);
 End Else Begin
  Val(FirstPart,Day,Code);If Code<>0Then Begin VBS_MakeText('',V);Exit;End;
  Val(SecondPart,Month,Code);If Code<>0Then Begin VBS_MakeText('',V);Exit;End;
  Val(ThirdPart,Year,Code);
 End;
 If Code<>0Then VBS_MakeText('',V)Else VBS_MakeDateValue(Year,Month,Day,V);
End;

Procedure VBS_DateDayValue(SourceText:TMailText;Var V:VBS_TValue);
Var DateValue:VBS_TValue;Day,Code:Integer;
Begin
 VBS_ParseDateValue(SourceText,DateValue);
 If DateValue.Text=''Then Begin VBS_MakeText('',V);Exit;End;
 Val(Copy(DateValue.Text,1,2),Day,Code);
 If Code=0Then VBS_MakeNumber(Day,V)Else VBS_MakeText('',V);
End;

Procedure VBS_DateHourValue(SourceText:TMailText;Var V:VBS_TValue);
Var P,HourValue,Code:Integer;TimeText:TMailText;
Begin
 SourceText:=VBS_Trim(SourceText);P:=Pos(' ',SourceText);
 If P>0Then TimeText:=VBS_Trim(Copy(SourceText,P+1,32767))Else TimeText:=SourceText;
 P:=Pos(':',TimeText);If P=0Then Begin VBS_MakeNumber(0,V);Exit;End;
 Val(Copy(TimeText,1,P-1),HourValue,Code);
 If(Code=0)and(HourValue>=0)and(HourValue<=23)Then VBS_MakeNumber(HourValue,V)
 Else VBS_MakeText('',V);
End;

Procedure VBS_DateMinuteValue(SourceText:TMailText;Var V:VBS_TValue);
Var P,P2,MinuteValue,Code:Integer;TimeText:TMailText;
Begin
 SourceText:=VBS_Trim(SourceText);P:=Pos(' ',SourceText);
 If P>0Then TimeText:=VBS_Trim(Copy(SourceText,P+1,32767))Else TimeText:=SourceText;
 P:=Pos(':',TimeText);If P=0Then Begin VBS_MakeNumber(0,V);Exit;End;
 Delete(TimeText,1,P);P2:=Pos(':',TimeText);
 If P2>0Then TimeText:=Copy(TimeText,1,P2-1);
 Val(VBS_Trim(TimeText),MinuteValue,Code);
 If(Code=0)and(MinuteValue>=0)and(MinuteValue<=59)Then VBS_MakeNumber(MinuteValue,V)
 Else VBS_MakeText('',V);
End;

Procedure VBS_DateSecondValue(SourceText:TMailText;Var V:VBS_TValue);
Var P,SecondValue,Code:Integer;TimeText:TMailText;
Begin
 SourceText:=VBS_Trim(SourceText);P:=Pos(' ',SourceText);
 If P>0Then TimeText:=VBS_Trim(Copy(SourceText,P+1,32767))Else TimeText:=SourceText;
 P:=Pos(':',TimeText);If P=0Then Begin VBS_MakeNumber(0,V);Exit;End;
 Delete(TimeText,1,P);P:=Pos(':',TimeText);
 If P=0Then Begin VBS_MakeNumber(0,V);Exit;End;Delete(TimeText,1,P);
 P:=1;While(P<=Length(TimeText))and(TimeText[P]in['0'..'9'])Do Inc(P);
 Val(Copy(TimeText,1,P-1),SecondValue,Code);
 If(Code=0)and(SecondValue>=0)and(SecondValue<=59)Then VBS_MakeNumber(SecondValue,V)
 Else VBS_MakeText('',V);
End;

Procedure VBS_DateMonthValue(SourceText:TMailText;Var V:VBS_TValue);
Var DateValue:VBS_TValue;MonthValue,Code:Integer;
Begin
 VBS_ParseDateValue(SourceText,DateValue);
 If DateValue.Text=''Then Begin VBS_MakeText('',V);Exit;End;
 Val(Copy(DateValue.Text,4,2),MonthValue,Code);
 If Code=0Then VBS_MakeNumber(MonthValue,V)Else VBS_MakeText('',V);
End;

Procedure VBS_NowValue(Var V:VBS_TValue);
Var Year,Month,Day,DayOfWeek,HourValue,MinuteValue,Second,Hundredth:Word;
 DatePart,HourText,MinuteText,SecondText:TMailText;DateValue:VBS_TValue;
Begin
 GetDate(Year,Month,Day,DayOfWeek);GetTime(HourValue,MinuteValue,Second,Hundredth);
 VBS_MakeDateValue(Year,Month,Day,DateValue);Str(HourValue,HourText);
 Str(MinuteValue,MinuteText);Str(Second,SecondText);
 If Length(HourText)<2Then HourText:='0'+HourText;
 If Length(MinuteText)<2Then MinuteText:='0'+MinuteText;
 If Length(SecondText)<2Then SecondText:='0'+SecondText;
 DatePart:=DateValue.Text+' '+HourText+':'+MinuteText+':'+SecondText;
 VBS_MakeText(DatePart,V);V.ValueKind:=VBS_ValueDate;
End;

Procedure VBS_HexValue(NumberValue:LongInt;Var V:VBS_TValue);
Const Digits:Array[0..15] of Char='0123456789ABCDEF';
Var ResultText:TMailText;Digit,Count:Integer;Negative:Boolean;
Begin
 ResultText:='';Negative:=NumberValue<0;Count:=0;
 Repeat
  Digit:=NumberValue and 15;ResultText:=Digits[Digit]+ResultText;
  NumberValue:=NumberValue shr 4;Inc(Count);
 Until((Not Negative)and(NumberValue=0))or(Negative and(Count=8));
 VBS_MakeText(ResultText,V);
End;

Procedure VBS_OctValue(NumberValue:LongInt;Var V:VBS_TValue);
Const Digits:Array[0..7]of Char='01234567';
Var ResultText:TMailText;Digit,Count:Integer;Negative:Boolean;
Begin
 ResultText:='';Negative:=NumberValue<0;Count:=0;
 Repeat
  Digit:=NumberValue and 7;ResultText:=Digits[Digit]+ResultText;
  NumberValue:=NumberValue shr 3;Inc(Count);
 Until((Not Negative)and(NumberValue=0))or(Negative and(Count=11));
 VBS_MakeText(ResultText,V);
End;

Procedure VBS_StrValue(NumberValue:Real;Var V:VBS_TValue);
Var Number:VBS_TValue;
Begin
 VBS_MakeNumber(NumberValue,Number);
 If NumberValue>=0Then VBS_MakeText(' '+Number.Text,V)Else VBS_MakeText(Number.Text,V);
End;

Procedure VBS_MakeTimeValue(HourValue,MinuteValue,SecondValue:LongInt;Var V:VBS_TValue);
Var TotalSeconds:LongInt;HourText,MinuteText,SecondText:TMailText;
Begin
 TotalSeconds:=HourValue*3600+MinuteValue*60+SecondValue;
 TotalSeconds:=TotalSeconds mod 86400;If TotalSeconds<0Then Inc(TotalSeconds,86400);
 HourValue:=TotalSeconds div 3600;MinuteValue:=(TotalSeconds mod 3600)div 60;
 SecondValue:=TotalSeconds mod 60;Str(HourValue,HourText);Str(MinuteValue,MinuteText);
 Str(SecondValue,SecondText);If Length(HourText)<2Then HourText:='0'+HourText;
 If Length(MinuteText)<2Then MinuteText:='0'+MinuteText;
 If Length(SecondText)<2Then SecondText:='0'+SecondText;
 VBS_MakeText(HourText+':'+MinuteText+':'+SecondText,V);V.ValueKind:=VBS_ValueDate;
End;

Procedure VBS_CurrentTimeValue(Var V:VBS_TValue);
Var HourValue,MinuteValue,SecondValue,Hundredth:Word;
Begin GetTime(HourValue,MinuteValue,SecondValue,Hundredth);
 VBS_MakeTimeValue(HourValue,MinuteValue,SecondValue,V);End;

Procedure VBS_ParseTimeValue(SourceText:TMailText;Var V:VBS_TValue);
Var P,Code,HourValue,MinuteValue,SecondValue:Integer;UpperText,Part:TMailText;
 IsPM,IsAM:Boolean;
Begin
 SourceText:=VBS_Trim(SourceText);P:=Pos(' ',SourceText);
 If(P>0)and(Pos(':',Copy(SourceText,P+1,32767))>0)Then SourceText:=VBS_Trim(Copy(SourceText,P+1,32767));
 UpperText:=VBS_Upper(SourceText);IsPM:=Pos('PM',UpperText)>0;IsAM:=Pos('AM',UpperText)>0;
 P:=Pos(':',SourceText);If P=0Then Begin VBS_MakeText('',V);Exit;End;
 Part:=Copy(SourceText,1,P-1);Val(VBS_Trim(Part),HourValue,Code);
 If Code<>0Then Begin VBS_MakeText('',V);Exit;End;Delete(SourceText,1,P);
 P:=Pos(':',SourceText);
 If P>0Then Begin Part:=Copy(SourceText,1,P-1);Delete(SourceText,1,P);End
 Else Begin Part:=SourceText;SourceText:='0';End;
 Val(VBS_Trim(Part),MinuteValue,Code);If Code<>0Then Begin VBS_MakeText('',V);Exit;End;
 P:=1;While(P<=Length(SourceText))and(SourceText[P]in['0'..'9'])Do Inc(P);
 If P=1Then SecondValue:=0 Else Begin Val(Copy(SourceText,1,P-1),SecondValue,Code);
  If Code<>0Then Begin VBS_MakeText('',V);Exit;End;End;
 If IsPM and(HourValue<12)Then Inc(HourValue,12);
 If IsAM and(HourValue=12)Then HourValue:=0;
 If(HourValue<0)or(HourValue>23)or(MinuteValue<0)or(MinuteValue>59)or
   (SecondValue<0)or(SecondValue>59)Then VBS_MakeText('',V)
 Else VBS_MakeTimeValue(HourValue,MinuteValue,SecondValue,V);
End;

Procedure VBS_StrCompValue(A,B,C:VBS_TValue;ArgumentCount:Integer;Var V:VBS_TValue);
Var LeftText,RightText:TMailText;
Begin
 If(A.ValueKind=VBS_ValueNull)or(B.ValueKind=VBS_ValueNull)Then Begin VBS_MakeText('',V);V.ValueKind:=VBS_ValueNull;
  Exit;End;
 LeftText:=A.Text;RightText:=B.Text;
 If(ArgumentCount>=3)and(Trunc(C.Number)=1)Then Begin LeftText:=VBS_Upper(LeftText);RightText:=VBS_Upper(RightText);End;
 If LeftText<RightText Then VBS_MakeNumber(-1,V)Else If LeftText>RightText Then VBS_MakeNumber(1,V)Else VBS_MakeNumber(0,V);
End;

Procedure VBS_StringValue(Count:Integer;CharacterValue:VBS_TValue;Var V:VBS_TValue);
Var ResultText:TMailText;Character:Char;
Begin
 If Count<0Then Begin VBS_MakeText('',V);Exit;End;If Count>255Then Count:=255;
 If CharacterValue.IsNumber Then Character:=Chr(Trunc(CharacterValue.Number)and 255)
 Else If CharacterValue.Text=''Then Character:=#0Else Character:=CharacterValue.Text[1];
 ResultText:='';While Length(ResultText)<Count Do ResultText:=ResultText+Character;
 VBS_MakeText(ResultText,V);V.ValueKind:=VBS_ValueString;
End;

Procedure VBS_MsgBoxValue(MessageText:TMailText;StyleValue:Integer;TitleText:TMailText;Var V:VBS_TValue);
Begin VBSOutput('MsgBox non interactif: '+TitleText+' '+MessageText);VBS_MakeNumber(1,V);End;
Procedure VBS_InputBoxValue(PromptText,TitleText,DefaultText:TMailText;Var V:VBS_TValue);
Begin VBS_ScriptError('InputBox non supporte dans cet hote.',True);VBS_MakeText('',V);End;

Procedure VBS_InStrValue(A,B,C,D:VBS_TValue;ArgumentCount:Integer;Var V:VBS_TValue);
Var StartPosition,FoundPosition:Integer;SourceText,SearchText:TMailText;
Begin
 If ArgumentCount<3Then Begin StartPosition:=1;SourceText:=A.Text;SearchText:=B.Text;End
 Else Begin StartPosition:=Trunc(A.Number);SourceText:=B.Text;SearchText:=C.Text;End;
 If StartPosition<1Then StartPosition:=1;
 If(ArgumentCount>=4)and(Trunc(D.Number)=1)Then Begin
  SourceText:=VBS_Upper(SourceText);SearchText:=VBS_Upper(SearchText);
 End;
 If SearchText=''Then FoundPosition:=StartPosition
 Else FoundPosition:=Pos(SearchText,Copy(SourceText,StartPosition,32767));
 If FoundPosition>0Then Inc(FoundPosition,StartPosition-1);
 VBS_MakeNumber(FoundPosition,V);
End;

Procedure VBS_BooleanValue(State:Boolean;Var V:VBS_TValue);
Begin
 If State Then Begin VBS_MakeText('True',V);V.Number:=-1;End
 Else Begin VBS_MakeText('False',V);V.Number:=0;End;
End;

Procedure VBS_IsDateValue(A:VBS_TValue;Var V:VBS_TValue);
Var Converted:VBS_TValue;
Begin
 If A.ValueKind=VBS_ValueDate Then VBS_BooleanValue(True,V)
 Else Begin VBS_ParseDateValue(A.Text,Converted);VBS_BooleanValue(Converted.Text<>'',V);End;
End;

Function VBS_Truth(V:VBS_TValue):Boolean;
Begin VBS_Truth:=Not((V.Text='')or(V.Text='0')or(VBS_Upper(V.Text)='FALSE'));End;

Function VBS_FindVariable(Name:TMailText):VBS_PVariable;
Var P:VBS_PVariable;
Begin
 Name:=VBS_Upper(VBS_Trim(Name));P:=VBS_Variables;
 While P<>Nil Do Begin If P^.Name=Name Then Begin VBS_FindVariable:=P;Exit;End;P:=P^.Next;End;
 VBS_FindVariable:=Nil;
End;

Procedure VBS_SetVariable(Name,Value:TMailText);
Var P:VBS_PVariable;V:VBS_TValue;
Begin
 Name:=VBS_Upper(VBS_Trim(Name));If Name=''Then Exit;P:=VBS_FindVariable(Name);
 If P=Nil Then Begin New(P);P^.Name:=Name;P^.Next:=VBS_Variables;VBS_Variables:=P;End;
 VBS_MakeText(Value,V);P^.Value:=Value;P^.ValueKind:=V.ValueKind;
 If Copy(Value,1,8)='@VBARRAY'Then P^.ValueKind:=VBS_ValueArray;
 If Copy(Value,1,6)='Error 'Then P^.ValueKind:=VBS_ValueError;
End;

Procedure VBS_SetVariableValue(Name:TMailText;V:VBS_TValue);
Var P:VBS_PVariable;
Begin
 Name:=VBS_Upper(VBS_Trim(Name));If Name=''Then Exit;P:=VBS_FindVariable(Name);
 If P=Nil Then Begin New(P);P^.Name:=Name;P^.Next:=VBS_Variables;VBS_Variables:=P;End;
 P^.Value:=V.Text;P^.ValueKind:=V.ValueKind;
End;

Procedure VBS_GetVariable(Name:TMailText;Var V:VBS_TValue);
Var P:VBS_PVariable;
Begin
 If VBSHostValue(Name,V) Then Exit;
 P:=VBS_FindVariable(Name);If P=Nil Then Begin
  VBS_MakeText('',V);
  If VBSExplicit Then VBS_ScriptError('Variable non declaree: '+Name,True);
 End Else Begin
 VBS_MakeText(P^.Value,V);V.ValueKind:=P^.ValueKind;
 End;
End;

Procedure VBS_RemoveVariable(Name:TMailText);
Var P,Previous:VBS_PVariable;
Begin
 Name:=VBS_Upper(VBS_Trim(Name));P:=VBS_Variables;Previous:=Nil;
 While P<>Nil Do Begin
  If P^.Name=Name Then Begin
   If Previous=Nil Then VBS_Variables:=P^.Next Else Previous^.Next:=P^.Next;
   Dispose(P);Exit;
  End;
  Previous:=P;P:=P^.Next;
 End;
End;

Procedure VBS_RemoveVariablesWithPrefix(Prefix:TMailText);
Var P,Previous,NextVariable:VBS_PVariable;
Begin
 Prefix:=VBS_Upper(Prefix);P:=VBS_Variables;Previous:=Nil;
 While P<>Nil Do Begin
  NextVariable:=P^.Next;
  If Copy(P^.Name,1,Length(Prefix))=Prefix Then Begin
   If Previous=Nil Then VBS_Variables:=NextVariable Else Previous^.Next:=NextVariable;
   Dispose(P);
  End Else Previous:=P;
  P:=NextVariable;
 End;
End;

Procedure VBS_EraseVariable(Name:TMailText);
Var VariableEntry:VBS_PVariable;Reference,CountText,DynamicText:TMailText;Stored:VBS_TValue;
Begin
 Name:=VBS_Trim(Name);VariableEntry:=VBS_FindVariable(Name);
 If VariableEntry=Nil Then Exit;
 If VariableEntry^.ValueKind=VBS_ValueArray Then Begin
  Reference:=VariableEntry^.Value;VBS_GetVariable(Reference+'.COUNT',Stored);CountText:=Stored.Text;
  VBS_GetVariable(Reference+'.DYNAMIC',Stored);DynamicText:=Stored.Text;
  VBS_RemoveVariablesWithPrefix(Reference+'.');
  If DynamicText<>'1'Then Begin
   VBS_SetVariable(Reference+'.COUNT',CountText);VBS_SetVariable(Reference+'.DYNAMIC','0');Exit;
  End;
 End;
 VBS_RemoveVariable(Name);
End;

Procedure VBS_UBoundValue(A,B:VBS_TValue;ArgumentCount:Integer;Var V:VBS_TValue);
Var CountValue:VBS_TValue;
Begin
 If(A.ValueKind<>VBS_ValueArray)and(Copy(A.Text,1,8)<>'@VBARRAY')Then Begin VBS_MakeText('',V);Exit;End;
 If(ArgumentCount>1)and(Trunc(B.Number)<>1)Then Begin VBS_MakeText('',V);Exit;End;
 VBS_GetVariable(A.Text+'.COUNT',CountValue);VBS_MakeNumber(Trunc(CountValue.Number)-1,V);
End;

Procedure VBS_ValValue(SourceText:TMailText;Var V:VBS_TValue);
Var NumberText,UpperText:TMailText;Position,Code,Base,Digit:Integer;
 NumberValue:Real;IntegerValue:LongInt;HasDigit:Boolean;
Begin
 SourceText:=VBS_Trim(SourceText);UpperText:=VBS_Upper(SourceText);
 If(Copy(UpperText,1,2)='&H')or(Copy(UpperText,1,2)='&O')Then Begin
  If UpperText[2]='H'Then Base:=16 Else Base:=8;
  Position:=3;IntegerValue:=0;HasDigit:=False;
  While Position<=Length(UpperText)Do Begin
   If UpperText[Position]in['0'..'9']Then Digit:=Ord(UpperText[Position])-Ord('0')
   Else If UpperText[Position]in['A'..'F']Then Digit:=Ord(UpperText[Position])-Ord('A')+10
   Else Break;
   If Digit>=Base Then Break;
   IntegerValue:=IntegerValue*Base+Digit;HasDigit:=True;Inc(Position);
  End;
  If HasDigit Then VBS_MakeNumber(IntegerValue,V)Else VBS_MakeNumber(0,V);Exit;
 End;
 NumberText:='';Position:=1;HasDigit:=False;
 If(Position<=Length(SourceText))and(SourceText[Position]in['+','-'])Then Begin
  NumberText:=SourceText[Position];Inc(Position);End;
 While(Position<=Length(SourceText))and(SourceText[Position]in['0'..'9'])Do Begin
  NumberText:=NumberText+SourceText[Position];Inc(Position);HasDigit:=True;End;
 If(Position<=Length(SourceText))and(SourceText[Position]='.')Then Begin
  NumberText:=NumberText+'.';Inc(Position);
  While(Position<=Length(SourceText))and(SourceText[Position]in['0'..'9'])Do Begin
   NumberText:=NumberText+SourceText[Position];Inc(Position);HasDigit:=True;End;
 End;
 If HasDigit and(Position<=Length(SourceText))and(SourceText[Position]in['E','e'])Then Begin
  NumberText:=NumberText+'E';Inc(Position);
  If(Position<=Length(SourceText))and(SourceText[Position]in['+','-'])Then Begin
   NumberText:=NumberText+SourceText[Position];Inc(Position);End;
  While(Position<=Length(SourceText))and(SourceText[Position]in['0'..'9'])Do Begin
   NumberText:=NumberText+SourceText[Position];Inc(Position);End;
 End;
 If Not HasDigit Then VBS_MakeNumber(0,V)Else Begin
  Val(NumberText,NumberValue,Code);If Code=0Then VBS_MakeNumber(NumberValue,V)Else VBS_MakeNumber(0,V);
 End;
End;

Procedure VBS_VarTypeValue(A:VBS_TValue;Var V:VBS_TValue);
Var TypeNumber:Integer;
Begin
 Case A.ValueKind of
  VBS_ValueEmpty:TypeNumber:=0;
  VBS_ValueString:TypeNumber:=8;
  VBS_ValueNumber:TypeNumber:=5;
  VBS_ValueDate:TypeNumber:=7;
  VBS_ValueArray:TypeNumber:=8204; { vbArray + vbVariant }
  VBS_ValueError:TypeNumber:=10;
  VBS_ValueNull:TypeNumber:=1;
  VBS_ValueObject:TypeNumber:=9;
 Else TypeNumber:=12;
 End;
 VBS_MakeNumber(TypeNumber,V);
End;

Procedure VBS_DateParts(SourceText:TMailText;Var VBS_YearValue,MonthValue,DayValue:Integer;
 Var Valid:Boolean);
Var Converted:VBS_TValue;Code:Integer;
Begin
 VBS_ParseDateValue(SourceText,Converted);Valid:=Converted.Text<>'';
 If Not Valid Then Exit;
 Val(Copy(Converted.Text,1,2),DayValue,Code);If Code<>0Then Valid:=False;
 Val(Copy(Converted.Text,4,2),MonthValue,Code);If Code<>0Then Valid:=False;
 Val(Copy(Converted.Text,7,4),VBS_YearValue,Code);If Code<>0Then Valid:=False;
End;

Procedure VBS_WeekdayValue(A,B:VBS_TValue;ArgumentCount:Integer;Var V:VBS_TValue);
Var VBS_YearValue,MonthValue,DayValue,FirstDay,H,ResultDay:Integer;Valid:Boolean;
Begin
 VBS_DateParts(A.Text,VBS_YearValue,MonthValue,DayValue,Valid);
 If Not Valid Then Begin VBS_MakeText('',V);Exit;End;
 If ArgumentCount>1Then FirstDay:=Trunc(B.Number)Else FirstDay:=1;
 If FirstDay=0Then FirstDay:=1;
 If(FirstDay<1)or(FirstDay>7)Then Begin VBS_MakeText('',V);Exit;End;
 If MonthValue<3Then Begin Inc(MonthValue,12);Dec(VBS_YearValue);End;
 H:=(DayValue+(13*(MonthValue+1))div 5+VBS_YearValue+(VBS_YearValue div 4)-
     (VBS_YearValue div 100)+(VBS_YearValue div 400))mod 7;
 ResultDay:=((H+6)mod 7)+1;
 ResultDay:=((ResultDay-FirstDay+7)mod 7)+1;VBS_MakeNumber(ResultDay,V);
End;

Procedure VBS_YearValue(SourceText:TMailText;Var V:VBS_TValue);
Var YearNumber,MonthNumber,DayNumber:Integer;Valid:Boolean;
Begin
 VBS_DateParts(SourceText,YearNumber,MonthNumber,DayNumber,Valid);
 If Valid Then VBS_MakeNumber(YearNumber,V)Else VBS_MakeText('',V);
End;

Procedure VBS_SkipSpace;
Begin While(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]in[' ',#9])Do Inc(VBS_ExprPos);End;

Function VBS_ReadWord:TMailText;
Var S:TMailText;
Begin
 VBS_SkipSpace;S:='';
 While(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]in['A'..'Z','a'..'z','0'..'9','_','.'])Do Begin
  S:=S+VBS_ExprText[VBS_ExprPos];Inc(VBS_ExprPos);
 End;
 VBS_ReadWord:=S;
End;

Procedure VBS_ParseExpression(Var V:VBS_TValue);Forward;
Procedure VBS_CallUserFunction(FunctionName:TMailText;A,B,C,D:VBS_TValue;
 ArgumentCount:Integer;Var V:VBS_TValue);Forward;

Function VBS_UserFunctionExists(FunctionName:TMailText):Boolean;
Var I,P:Integer;Declaration,DeclarationName:TMailText;
Begin
 VBS_UserFunctionExists:=False;
 For I:=1To VBS_LineCount Do Begin
  Declaration:=VBS_Trim(VBS_ScriptLineText(I));
  If VBS_StartsWith(Declaration,'PUBLIC FUNCTION ')Then Delete(Declaration,1,7)
  Else If VBS_StartsWith(Declaration,'PRIVATE FUNCTION ')Then Delete(Declaration,1,8);
  If VBS_StartsWith(Declaration,'FUNCTION ')Then Begin
   Delete(Declaration,1,9);P:=Pos('(',Declaration);
   If P=0Then P:=Pos(' ',Declaration);
   If P=0Then DeclarationName:=VBS_Trim(Declaration)
   Else DeclarationName:=VBS_Trim(Copy(Declaration,1,P-1));
   If VBS_Upper(DeclarationName)=VBS_Upper(FunctionName)Then Begin VBS_UserFunctionExists:=True;Exit;End;
  End;
 End;
End;

Procedure VBS_ParsePrimary(Var V:VBS_TValue);
Var Q:Char;S,Name,U,ArrayReference,IndexText:TMailText;N:Real;
 Code,I,ElementIndex,ArgumentCount:Integer;FunctionByte:Byte;A,B,C,D:VBS_TValue;VariableEntry:VBS_PVariable;
 DateYear,DateMonth,DateDay,DateDayOfWeek:Word;
Begin
 VBS_SkipSpace;If VBS_ExprPos>Length(VBS_ExprText)Then Begin VBS_MakeText('',V);Exit;End;
 If VBS_ExprText[VBS_ExprPos]in['"','''']Then Begin
  Q:=VBS_ExprText[VBS_ExprPos];Inc(VBS_ExprPos);S:='';
  While VBS_ExprPos<=Length(VBS_ExprText)Do Begin
   If VBS_ExprText[VBS_ExprPos]=Q Then Begin
    If(VBS_ExprPos<Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos+1]=Q)Then Begin S:=S+Q;Inc(VBS_ExprPos,2);End
    Else Begin Inc(VBS_ExprPos);Break;End;
   End Else Begin S:=S+VBS_ExprText[VBS_ExprPos];Inc(VBS_ExprPos);End;
  End;
  VBS_MakeText(S,V);V.ValueKind:=VBS_ValueString;Exit;
 End;
 If VBS_ExprText[VBS_ExprPos]='('Then Begin Inc(VBS_ExprPos);VBS_ParseExpression(V);VBS_SkipSpace;
  If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]=')')Then Inc(VBS_ExprPos);Exit;End;
 If VBS_ExprText[VBS_ExprPos]in['0'..'9']Then Begin
  S:='';While(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]in['0'..'9','.'])Do Begin
  S:=S+VBS_ExprText[VBS_ExprPos];Inc(VBS_ExprPos);End;
  Val(S,N,Code);If Code=0Then VBS_MakeNumber(N,V)Else VBS_MakeText(S,V);Exit;
 End;
 Name:=VBS_ReadWord;U:=VBS_Upper(Name);
 If U='TRUE'Then Begin VBS_MakeNumber(-1,V);Exit;End;
 If U='FALSE'Then Begin VBS_MakeNumber(0,V);Exit;End;
 If U='EMPTY'Then Begin VBS_MakeText('',V);Exit;End;
 If U='NULL'Then Begin VBS_MakeText('',V);V.ValueKind:=VBS_ValueNull;Exit;End;
 If U='NOTHING'Then Begin VBS_MakeText('',V);V.ValueKind:=VBS_ValueObject;Exit;End;
 VBS_SkipSpace;
 FunctionByte:=VBS_FunctionIndex(U);
 If((FunctionByte=15)or(FunctionByte=43)or(FunctionByte=56))and
   ((VBS_ExprPos>Length(VBS_ExprText))or(VBS_ExprText[VBS_ExprPos]<>'('))Then Begin
  If FunctionByte=15Then Begin GetDate(DateYear,DateMonth,DateDay,DateDayOfWeek);
   VBS_MakeDateValue(DateYear,DateMonth,DateDay,V);End
  Else If FunctionByte=43Then VBS_NowValue(V)Else VBS_CurrentTimeValue(V);Exit;
 End;
 If(FunctionByte=255)and VBS_UserFunctionExists(Name)and
   ((VBS_ExprPos>Length(VBS_ExprText))or(VBS_ExprText[VBS_ExprPos]<>'('))Then Begin
  VBS_MakeText('',A);VBS_MakeText('',B);VBS_MakeText('',C);VBS_MakeText('',D);
  VBS_CallUserFunction(Name,A,B,C,D,0,V);Exit;
 End;
 VariableEntry:=VBS_FindVariable(Name);
 If(VariableEntry<>Nil)and(Copy(VariableEntry^.Value,1,8)='@VBARRAY')and
   (VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]='(')Then Begin
  Inc(VBS_ExprPos);VBS_ParseExpression(A);VBS_SkipSpace;
  If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]=')')Then Inc(VBS_ExprPos);
  Str(Trunc(A.Number),IndexText);
  VBS_GetVariable(VariableEntry^.Value+'.'+VBS_Trim(IndexText),V);Exit;
 End;
 If(U='ARRAY')and(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]='(')Then Begin
  Inc(VBS_ArrayCounter);Str(VBS_ArrayCounter,IndexText);
  ArrayReference:='@VBARRAY'+VBS_Trim(IndexText);ElementIndex:=0;Inc(VBS_ExprPos);VBS_SkipSpace;
  While(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]<>')')Do Begin
   VBS_ParseExpression(A);Str(ElementIndex,IndexText);
   VBS_SetVariable(ArrayReference+'.'+VBS_Trim(IndexText),A.Text);Inc(ElementIndex);VBS_SkipSpace;
   If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]=',')Then Begin Inc(VBS_ExprPos);VBS_SkipSpace;End
   Else Break;
  End;
  If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]=')')Then Inc(VBS_ExprPos);
  Str(ElementIndex,IndexText);VBS_SetVariable(ArrayReference+'.COUNT',VBS_Trim(IndexText));
  VBS_MakeText(ArrayReference,V);V.ValueKind:=VBS_ValueArray;Exit;
 End;
 If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]='(')Then Begin
  Inc(VBS_ExprPos);VBS_SkipSpace;ArgumentCount:=0;
  VBS_MakeText('',A);VBS_MakeText('',B);VBS_MakeText('',C);VBS_MakeText('',D);
  If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]<>')')Then Begin
   VBS_ParseExpression(A);Inc(ArgumentCount);VBS_SkipSpace;
  End;
  If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]=',')Then Begin
   Inc(VBS_ExprPos);
   VBS_ParseExpression(B);Inc(ArgumentCount);
   VBS_SkipSpace;
  End;
  If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]=',')Then Begin
   Inc(VBS_ExprPos);VBS_ParseExpression(C);
   Inc(ArgumentCount);
   VBS_SkipSpace;
  End;
  If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]=',')Then Begin
   Inc(VBS_ExprPos);
   VBS_ParseExpression(D);
   Inc(ArgumentCount);
   VBS_SkipSpace;
  End;
  If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]=')')Then Inc(VBS_ExprPos);
  If(FunctionByte=255)and VBS_UserFunctionExists(Name)Then Begin
   VBS_CallUserFunction(Name,A,B,C,D,ArgumentCount,V);Exit;
  End;
  Case FunctionByte of
   0:VBS_MakeNumber(Abs(A.Number),V);                         { ABS }
   1:VBS_MakeText('',V);                                      { ARRAY: analyse variadique ci-dessus }
   2:Begin If A.Text=''Then VBS_MakeNumber(0,V)
      Else VBS_MakeNumber(Ord(A.Text[1]),V);End;              { ASC }
   3:VBS_MakeNumber(ArcTan(A.Number),V);                      { ATN }
   4:If VBS_Truth(A)Then VBS_MakeText('True',V)Else VBS_MakeText('False',V); { CBOOL }
   5:Begin                                                { CBYTE }
      N:=Round(A.Number);
      If(N<0)or(N>255)Then VBS_MakeText('',V)Else VBS_MakeNumber(N,V);
     End;
   6:If A.IsNumber Then VBS_MakeText(A.Text,V)Else VBS_ParseDateValue(A.Text,V); { CDATE }
   7:VBS_MakeNumber(A.Number,V);                              { CDBL }
   8:VBS_MakeText(Chr(Trunc(A.Number)and 255),V);             { CHR }
   9:VBS_MakeNumber(Round(A.Number),V);                       { CINT }
   10:VBS_MakeNumber(Trunc(A.Number),V);                      { CLNG }
   11:VBS_MakeNumber(Cos(A.Number),V);                        { COS }
   12:VBS_MakeSingleNumber(A.Number,V);                       { CSNG }
   13:Begin VBS_MakeText(A.Text,V);V.ValueKind:=VBS_ValueString;End; { CSTR }
   14:Begin VBS_MakeText('Error '+A.Text,V);V.Number:=A.Number;V.ValueKind:=VBS_ValueError;End; { CVERR }
   15:Begin GetDate(DateYear,DateMonth,DateDay,DateDayOfWeek);
      VBS_MakeDateValue(DateYear,DateMonth,DateDay,V);End;    { DATE }
   16:VBS_MakeDateValue(Trunc(A.Number),Trunc(B.Number),Trunc(C.Number),V); { DATESERIAL }
   17:VBS_ParseDateValue(A.Text,V);                           { DATEVALUE }
   18:VBS_DateDayValue(A.Text,V);                             { DAY }
   19:VBS_MakeNumber(Exp(A.Number),V);                        { EXP }
   20:VBS_MakeNumber(Trunc(A.Number),V);                      { FIX }
   21:VBS_HexValue(Trunc(A.Number),V);                        { HEX }
   22:VBS_DateHourValue(A.Text,V);                            { HOUR }
   23:VBS_InputBoxValue(A.Text,B.Text,C.Text,V);              { INPUTBOX }
   24:VBS_InStrValue(A,B,C,D,ArgumentCount,V);                { INSTR }
   25:VBS_MakeNumber(Trunc(A.Number),V);                      { INT }
   26:VBS_BooleanValue((A.ValueKind=VBS_ValueArray)or(Copy(A.Text,1,8)='@VBARRAY'),V); { ISARRAY }
   27:VBS_IsDateValue(A,V);                                   { ISDATE }
   28:VBS_BooleanValue(A.ValueKind=VBS_ValueEmpty,V);              { ISEMPTY }
   29:VBS_BooleanValue(A.ValueKind=VBS_ValueError,V);              { ISERROR }
   30:VBS_BooleanValue(A.ValueKind=VBS_ValueNull,V);               { ISNULL }
   31:VBS_BooleanValue(A.IsNumber,V);                          { ISNUMERIC }
   32:VBS_BooleanValue(A.ValueKind=VBS_ValueObject,V);             { ISOBJECT }
   33:If((A.ValueKind=VBS_ValueArray)or(Copy(A.Text,1,8)='@VBARRAY'))and
        ((ArgumentCount<2)or(Trunc(B.Number)=1))Then
       VBS_MakeNumber(0,V)Else VBS_MakeText('',V);                { LBOUND }
   34:Begin                                               { LCASE }
      S:=A.Text;
      For I:=1To Length(S)Do If S[I]in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
      VBS_MakeText(S,V);
     End;
   35:VBS_MakeText(Copy(A.Text,1,Trunc(B.Number)),V);         { LEFT }
   36:VBS_MakeNumber(Length(A.Text),V);                       { LEN }
   37:If A.Number>0Then VBS_MakeNumber(Ln(A.Number),V)Else VBS_MakeText('',V); { LOG }
   38:Begin S:=A.Text;While(Length(S)>0)and(S[1]=' ')Do Delete(S,1,1);
      VBS_MakeText(S,V);End;                                  { LTRIM }
   39:Begin                                               { MID }
      I:=Trunc(B.Number);If I<1Then VBS_MakeText('',V)
      Else If ArgumentCount<3Then VBS_MakeText(Copy(A.Text,I,32767),V)
      Else If C.Number<0Then VBS_MakeText('',V)
      Else VBS_MakeText(Copy(A.Text,I,Trunc(C.Number)),V);
     End;
   40:VBS_DateMinuteValue(A.Text,V);                          { MINUTE }
   41:VBS_DateMonthValue(A.Text,V);                           { MONTH }
   42:VBS_MsgBoxValue(A.Text,Trunc(B.Number),C.Text,V);       { MSGBOX }
   43:VBS_NowValue(V);                                        { NOW }
   44:VBS_OctValue(Trunc(A.Number),V);                        { OCT }
   45:VBS_MakeText(Copy(A.Text,Length(A.Text)-Trunc(B.Number)+1,32767),V); { RIGHT }
   46:VBS_MakeNumber(Random,V);                               { RND }
   47:Begin                                               { RTRIM }
      If A.ValueKind=VBS_ValueNull Then V:=A Else Begin S:=A.Text;
       While(Length(S)>0)and(S[Length(S)]=' ')Do Delete(S,Length(S),1);
       VBS_MakeText(S,V);End;
     End;
   48:VBS_DateSecondValue(A.Text,V);                          { SECOND }
   49:If A.Number<0Then VBS_MakeNumber(-1,V)
      Else If A.Number>0Then VBS_MakeNumber(1,V)Else VBS_MakeNumber(0,V); { SGN }
   50:VBS_MakeNumber(Sin(A.Number),V);                        { SIN }
   51:If A.Number<0Then VBS_MakeText('',V)Else VBS_MakeNumber(Sqrt(A.Number),V); { SQR }
   52:VBS_StrValue(A.Number,V);                               { STR }
   53:VBS_StrCompValue(A,B,C,ArgumentCount,V);                { STRCOMP }
   54:VBS_StringValue(Trunc(A.Number),B,V);                   { STRING }
   55:If Cos(A.Number)=0Then VBS_MakeText('',V)Else VBS_MakeNumber(Sin(A.Number)/Cos(A.Number),V); { TAN }
   56:VBS_CurrentTimeValue(V);                                { TIME }
   57:VBS_MakeTimeValue(Trunc(A.Number),Trunc(B.Number),Trunc(C.Number),V); { TIMESERIAL }
   58:VBS_ParseTimeValue(A.Text,V);                           { TIMEVALUE }
   59:VBS_MakeText(VBS_Trim(A.Text),V);                           { TRIM }
   60:VBS_UBoundValue(A,B,ArgumentCount,V);                   { UBOUND }
   61:VBS_MakeText(VBS_Upper(A.Text),V);                          { UCASE }
   62:VBS_ValValue(A.Text,V);                                 { VAL }
   63:VBS_VarTypeValue(A,V);                                 { VARTYPE }
   64:VBS_WeekdayValue(A,B,ArgumentCount,V);                  { WEEKDAY }
   65:If(Trunc(A.Number)>=0)and(Trunc(A.Number)<VBS_ScriptArgumentCount)Then
       VBS_MakeText(VBS_ScriptArguments[Trunc(A.Number)],V)
      Else VBS_MakeText('',V);                               { WSCRIPT.ARGUMENTS }
   66:VBS_YearValue(A.Text,V);                               { YEAR }
   Else Begin VBS_MakeText('',V);VBS_ScriptError('Fonction inconnue: '+Name,True);End;
  End;
  Exit;
 End;
 If U='WSCRIPT.ARGUMENTS.COUNT'Then VBS_MakeNumber(VBS_ScriptArgumentCount,V)
 Else If U='WSCRIPT.SCRIPTNAME'Then VBS_MakeText(VBS_ScriptName,V)
 Else If U='WSCRIPT.FULLNAME'Then VBS_MakeText(ParamStr(0),V)
 Else VBS_GetVariable(Name,V);
End;

Procedure VBS_ParseUnary(Var V:VBS_TValue);
Begin
 VBS_SkipSpace;
 If Copy(VBS_Upper(Copy(VBS_ExprText,VBS_ExprPos,4)),1,4)='NOT 'Then Begin
  Inc(VBS_ExprPos,4);VBS_ParseUnary(V);
  If VBS_Truth(V)Then VBS_MakeNumber(0,V)
             Else VBS_MakeNumber(-1,V);
 End
  Else
 If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]='-')Then Begin
  Inc(VBS_ExprPos);
  VBS_ParseUnary(V);
  VBS_MakeNumber(-V.Number,V);
 End
  Else
 VBS_ParsePrimary(V);
End;

Procedure VBS_ParseMul(Var V:VBS_TValue);
Var R:VBS_TValue;Op:TMailText;
Begin
 VBS_ParseUnary(V);
 While True Do Begin VBS_SkipSpace;Op:='';
  If Copy(VBS_Upper(Copy(VBS_ExprText,VBS_ExprPos,4)),1,4)=' MOD'Then Begin Op:='MOD';Inc(VBS_ExprPos,4);End
  Else If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]in['*','/','\'])Then Begin
  Op:=VBS_ExprText[VBS_ExprPos];Inc(VBS_ExprPos);End;
  If Op=''Then Exit;VBS_ParseUnary(R);
  If Op='*'Then VBS_MakeNumber(V.Number*R.Number,V)
  Else If Op='/'Then Begin If R.Number=0Then VBS_MakeText('',V)Else VBS_MakeNumber(V.Number/R.Number,V);End
  Else If Op='\'Then Begin If Trunc(R.Number)=0Then VBS_MakeText('',V)Else VBS_MakeNumber(Trunc(V.Number)div
  Trunc(R.Number),V);End
  Else If Trunc(R.Number)=0Then VBS_MakeText('',V)Else VBS_MakeNumber(Trunc(V.Number)mod Trunc(R.Number),V);
 End;
End;

Procedure VBS_ParseAdd(Var V:VBS_TValue);
Var R:VBS_TValue;Op:Char;
Begin
 VBS_ParseMul(V);
 While True Do Begin VBS_SkipSpace;
  If(VBS_ExprPos>Length(VBS_ExprText))or Not(VBS_ExprText[VBS_ExprPos]in['+','-','&'])Then Exit;
  Op:=VBS_ExprText[VBS_ExprPos];Inc(VBS_ExprPos);VBS_ParseMul(R);
  If Op='&'Then VBS_MakeText(V.Text+R.Text,V)
  Else If Op='+'Then Begin If V.IsNumber and R.IsNumber Then VBS_MakeNumber(V.Number+R.Number,V)Else
  VBS_MakeText(V.Text+R.Text,V);End
  Else VBS_MakeNumber(V.Number-R.Number,V);
 End;
End;

Procedure VBS_ParseExpression(Var V:VBS_TValue);
Var R:VBS_TValue;Op:TMailText;Result:Boolean;
Begin
 VBS_ParseAdd(V);VBS_SkipSpace;Op:='';
 If Copy(VBS_ExprText,VBS_ExprPos,2)='<>'Then Begin Op:='<>';Inc(VBS_ExprPos,2);End
 Else If Copy(VBS_ExprText,VBS_ExprPos,2)='<='Then Begin Op:='<=';Inc(VBS_ExprPos,2);End
 Else If Copy(VBS_ExprText,VBS_ExprPos,2)='>='Then Begin Op:='>=';Inc(VBS_ExprPos,2);End
 Else If(VBS_ExprPos<=Length(VBS_ExprText))and(VBS_ExprText[VBS_ExprPos]in['=','<','>'])Then Begin
  Op:=VBS_ExprText[VBS_ExprPos];Inc(VBS_ExprPos);End;
 If Op<>''Then Begin VBS_ParseAdd(R);
  If V.IsNumber and R.IsNumber Then Begin
   If Op='='Then Result:=V.Number=R.Number Else If Op='<>'Then Result:=V.Number<>R.Number
   Else If Op='<'Then Result:=V.Number<R.Number Else If Op='>'Then Result:=V.Number>R.Number
   Else If Op='<='Then Result:=V.Number<=R.Number Else Result:=V.Number>=R.Number;
  End Else Begin
   If Op='='Then Result:=VBS_Upper(V.Text)=VBS_Upper(R.Text)Else If Op='<>'Then Result:=VBS_Upper(V.Text)<>VBS_Upper(R.Text)
   Else If Op='<'Then Result:=VBS_Upper(V.Text)<VBS_Upper(R.Text)Else If Op='>'Then
  Result:=VBS_Upper(V.Text)>VBS_Upper(R.Text)
   Else If Op='<='Then Result:=VBS_Upper(V.Text)<=VBS_Upper(R.Text)Else Result:=VBS_Upper(V.Text)>=VBS_Upper(R.Text);
  End;
  If Result Then VBS_MakeNumber(-1,V)Else VBS_MakeNumber(0,V);
 End;
End;

Procedure VBS_Evaluate(S:TMailText;Var V:VBS_TValue);
Begin VBS_ExprText:=VBS_Trim(S);VBS_ExprPos:=1;VBS_ParseExpression(V);End;

Function VBS_FindAssignment(S:TMailText):Integer;
Var I:Integer;Q:Char;
Begin
 Q:=#0;For I:=1To Length(S)Do Begin
  If Q<>#0Then Begin If S[I]=Q Then Q:=#0;End Else If S[I]in['"','''']Then Q:=S[I]
  Else If(S[I]='=')and((I=1)or Not(S[I-1]in['<','>']))Then Begin VBS_FindAssignment:=I;Exit;End;
 End;VBS_FindAssignment:=0;
End;

Procedure VBS_CheckTimeout;
Var H,M,S,HS:Word;Elapsed:LongInt;
Begin
 Inc(VBSSteps);
 If VBSSteps>10000 Then Begin
  VBS_OnErrorResumeNext:=False;VBS_ScriptError('Limite de 10000 instructions atteinte.',True);Exit;
 End;
 If VBS_TimeLimit<=0Then Exit;GetTime(H,M,S,HS);
 Elapsed:=(LongInt(H)*3600+LongInt(M)*60+S)-(LongInt(VBS_StartHour)*3600+LongInt(VBS_StartMinute)*60+VBS_StartSecond);
 If Elapsed<0Then Inc(Elapsed,86400);
 If Elapsed>=VBS_TimeLimit Then Begin VBSOutput('CSCRIPT: Delai d''execution depasse.');VBS_Terminated:=True;
  VBS_ExitCode:=1;End;
End;

Function VBS_FindBlock(StartLine:LongInt;OpenWord,CloseWord:TMailText):LongInt;
Var I:LongInt;Depth:Integer;S:TMailText;
Begin
 Depth:=1;For I:=StartLine+1To VBS_LineCount Do Begin S:=VBS_Upper(VBS_Trim(VBS_ScriptLineText(I)));
  If VBS_StartsWith(S,OpenWord)Then Inc(Depth);If VBS_StartsWith(S,CloseWord)Then Dec(Depth);
  If Depth=0Then Begin VBS_FindBlock:=I;Exit;End;
 End;VBS_FindBlock:=VBS_LineCount;
End;

Function VBS_FindElseLine(StartLine,EndLine:LongInt):LongInt;
Var I:LongInt;Depth:Integer;S:TMailText;
Begin
 Depth:=0;VBS_FindElseLine:=0;
 For I:=StartLine+1To EndLine-1Do Begin
  S:=VBS_Upper(VBS_Trim(VBS_ScriptLineText(I)));
  If VBS_StartsWith(S,'IF ')and(Pos(' THEN',S)>0)and
    (VBS_Trim(Copy(S,Pos(' THEN',S)+5,32767))='')Then Inc(Depth)
  Else If S='END IF'Then Begin If Depth>0Then Dec(Depth);End
  Else If(Depth=0)and((S='ELSE')or VBS_StartsWith(S,'ELSEIF '))Then Begin
   VBS_FindElseLine:=I;Exit;
  End;
 End;
End;

Function VBS_FindLoopEnd(StartLine:LongInt):LongInt;
Var I:LongInt;Depth:Integer;S:TMailText;
Begin
 Depth:=1;
 For I:=StartLine+1To VBS_LineCount Do Begin
  S:=VBS_Upper(VBS_Trim(VBS_ScriptLineText(I)));
  If(S='DO')or VBS_StartsWith(S,'DO WHILE ')or VBS_StartsWith(S,'DO UNTIL ')Then Inc(Depth)
  Else If VBS_StartsWith(S,'LOOP')Then Dec(Depth);
  If Depth=0Then Begin VBS_FindLoopEnd:=I;Exit;End;
 End;
 VBS_FindLoopEnd:=VBS_LineCount;
End;

Function VBS_KeywordOutsideQuotes(Source,Keyword:TMailText):Integer;
Var I:Integer;Quote:Char;
Begin
 VBS_KeywordOutsideQuotes:=0;Quote:=#0;I:=1;
 While I<=Length(Source)-Length(Keyword)+1Do Begin
  If Quote<>#0Then Begin
   If Source[I]=Quote Then Begin
    If(I<Length(Source))and(Source[I+1]=Quote)Then Inc(I)Else Quote:=#0;
   End;
  End Else If Source[I]in['''','"']Then Quote:=Source[I]
  Else If VBS_Upper(Copy(Source,I,Length(Keyword)))=VBS_Upper(Keyword)Then Begin
   VBS_KeywordOutsideQuotes:=I;Exit;
  End;
  Inc(I);
 End;
End;

Procedure VBS_ExecuteRange(FirstLine,LastLine:LongInt);Forward;
Procedure VBS_CallSub(CallText:TMailText);Forward;
Function VBS_ListItem(Var Source:TMailText):TMailText;Forward;
Function VBS_SimpleIdentifier(Source:TMailText):Boolean;Forward;
Procedure VBS_ExecuteStatementList(Source:TMailText);Forward;

Procedure VBS_ScriptError(MessageText:TMailText;StopScript:Boolean);
Begin
 If VBS_OnErrorResumeNext Then Exit;
 VBSOutput('Erreur VBScript: '+MessageText);
 VBS_ExitCode:=1;VBS_Terminated:=True;
End;

Procedure VBS_DeclareVariable(Declaration:TMailText);
Var Name,Bounds,Reference,NumberText:TMailText;P:Integer;UpperBound:VBS_TValue;ArrayValue:VBS_TValue;
 IsDynamic:Boolean;
Begin
 Declaration:=VBS_Trim(Declaration);P:=Pos('(',Declaration);
 If P=0Then Begin VBS_SetVariable(Declaration,'');Exit;End;
 Name:=VBS_Trim(Copy(Declaration,1,P-1));Bounds:=Copy(Declaration,P+1,32767);
 If(Length(Bounds)>0)and(Bounds[Length(Bounds)]=')')Then Delete(Bounds,Length(Bounds),1);
 Inc(VBS_ArrayCounter);Str(VBS_ArrayCounter,NumberText);Reference:='@VBARRAY'+VBS_Trim(NumberText);
 IsDynamic:=VBS_Trim(Bounds)='';
 If IsDynamic Then VBS_MakeNumber(0,UpperBound)Else VBS_Evaluate(Bounds,UpperBound);
 If UpperBound.Number<0Then VBS_MakeNumber(0,UpperBound);
 If IsDynamic Then NumberText:='0'Else Str(Trunc(UpperBound.Number)+1,NumberText);
 VBS_SetVariable(Reference+'.COUNT',VBS_Trim(NumberText));
 If IsDynamic Then VBS_SetVariable(Reference+'.DYNAMIC','1')Else VBS_SetVariable(Reference+'.DYNAMIC','0');
 VBS_MakeText(Reference,ArrayValue);ArrayValue.ValueKind:=VBS_ValueArray;VBS_SetVariableValue(Name,ArrayValue);
End;

Procedure VBS_RemoveArrayElementsFrom(Reference:TMailText;FirstRemoved:LongInt);
Var P,Previous,NextVariable:VBS_PVariable;Suffix:TMailText;ElementNumber:LongInt;Code:Integer;
 Removed:Boolean;
Begin
 Reference:=VBS_Upper(Reference)+'.';P:=VBS_Variables;Previous:=Nil;
 While P<>Nil Do Begin
  NextVariable:=P^.Next;Removed:=False;
  If Copy(P^.Name,1,Length(Reference))=Reference Then Begin
   Suffix:=Copy(P^.Name,Length(Reference)+1,32767);Val(Suffix,ElementNumber,Code);
   If(Code=0)and(ElementNumber>=FirstRemoved)Then Begin
    If Previous=Nil Then VBS_Variables:=NextVariable Else Previous^.Next:=NextVariable;
    Dispose(P);Removed:=True;
   End;
  End;
  If Not Removed Then Previous:=P;P:=NextVariable;
 End;
End;

Procedure VBS_ResizeArray(Declaration:TMailText;PreserveValues:Boolean);
Var Name,Bounds,Reference,NumberText:TMailText;P:Integer;UpperBound,Stored,ArrayValue:VBS_TValue;
 VariableEntry:VBS_PVariable;NewCount:LongInt;
Begin
 Declaration:=VBS_Trim(Declaration);P:=Pos('(',Declaration);
 If(P=0)or(Declaration[Length(Declaration)]<>')')Then Begin
  VBS_ScriptError('REDIM exige une borne de tableau.',True);Exit;
 End;
 Name:=VBS_Trim(Copy(Declaration,1,P-1));Bounds:=Copy(Declaration,P+1,Length(Declaration)-P-1);
 If Pos(',',Bounds)>0Then Begin VBS_ScriptError('REDIM multidimensionnel non supporte.',True);Exit;End;
 VBS_Evaluate(Bounds,UpperBound);
 If(Not UpperBound.IsNumber)or(UpperBound.Number<0)Then Begin
  VBS_ScriptError('borne REDIM invalide.',True);Exit;
 End;
 NewCount:=Trunc(UpperBound.Number)+1;VariableEntry:=VBS_FindVariable(Name);
 If(VariableEntry<>Nil)and(VariableEntry^.ValueKind=VBS_ValueArray)Then Begin
  Reference:=VariableEntry^.Value;VBS_GetVariable(Reference+'.DYNAMIC',Stored);
  If Stored.Text<>'1'Then Begin VBS_ScriptError('REDIM exige un tableau dynamique.',True);Exit;End;
 End Else Begin
  If PreserveValues Then Begin VBS_ScriptError('REDIM PRESERVE exige un tableau existant.',True);Exit;End;
  Inc(VBS_ArrayCounter);Str(VBS_ArrayCounter,NumberText);Reference:='@VBARRAY'+VBS_Trim(NumberText);
 End;
 If PreserveValues Then VBS_RemoveArrayElementsFrom(Reference,NewCount)
 Else VBS_RemoveVariablesWithPrefix(Reference+'.');
 Str(NewCount,NumberText);VBS_SetVariable(Reference+'.COUNT',VBS_Trim(NumberText));
 VBS_SetVariable(Reference+'.DYNAMIC','1');VBS_MakeText(Reference,ArrayValue);
 ArrayValue.ValueKind:=VBS_ValueArray;VBS_SetVariableValue(Name,ArrayValue);
End;

Procedure VBS_DeclareStaticVariable(Declaration:TMailText);
Var Name:TMailText;P:Integer;
Begin
 Declaration:=VBS_Trim(Declaration);P:=Pos('(',Declaration);
 If P=0Then Name:=Declaration Else Name:=VBS_Trim(Copy(Declaration,1,P-1));
 If VBS_FindVariable(Name)=Nil Then VBS_DeclareVariable(Declaration);
End;

Function VBS_UserSubExists(CallText:TMailText):Boolean;
Var I,P:Integer;CallName,Declaration,DeclarationName:TMailText;
Begin
 CallText:=VBS_Trim(CallText);P:=Pos('(',CallText);If P=0Then P:=Pos(' ',CallText);
 If P=0Then CallName:=CallText Else CallName:=Copy(CallText,1,P-1);
 VBS_UserSubExists:=False;
 For I:=1To VBS_LineCount Do Begin
  Declaration:=VBS_Trim(VBS_ScriptLineText(I));
  If VBS_StartsWith(Declaration,'PUBLIC SUB ')Then Delete(Declaration,1,7)
  Else If VBS_StartsWith(Declaration,'PRIVATE SUB ')Then Delete(Declaration,1,8);
  If VBS_StartsWith(Declaration,'SUB ')Then Begin
   Delete(Declaration,1,4);P:=Pos('(',Declaration);If P=0Then P:=Pos(' ',Declaration);
   If P=0Then DeclarationName:=VBS_Trim(Declaration)
   Else DeclarationName:=VBS_Trim(Copy(Declaration,1,P-1));
   If VBS_Upper(DeclarationName)=VBS_Upper(CallName)Then Begin VBS_UserSubExists:=True;Exit;End;
  End;
 End;
End;

Procedure VBS_AlignStringAssignment(StatementText:TMailText;AlignRight:Boolean);
Var Name,SourceText,ResultText:TMailText;P,TargetLength:Integer;Value,OldValue:VBS_TValue;
Begin
 P:=VBS_FindAssignment(StatementText);
 If P=0Then Begin
  If AlignRight Then VBS_ScriptError('RSET exige une affectation.',True)
  Else VBS_ScriptError('LSET exige une affectation.',True);Exit;
 End;
 Name:=VBS_Trim(Copy(StatementText,1,P-1));SourceText:=Copy(StatementText,P+1,32767);
 VBS_Evaluate(SourceText,Value);VBS_GetVariable(Name,OldValue);TargetLength:=Length(OldValue.Text);
 If TargetLength=0Then TargetLength:=Length(Value.Text);
 If Length(Value.Text)>TargetLength Then ResultText:=Copy(Value.Text,1,TargetLength)
 Else Begin ResultText:=Value.Text;
  If AlignRight Then While Length(ResultText)<TargetLength Do ResultText:=' '+ResultText
  Else While Length(ResultText)<TargetLength Do ResultText:=ResultText+' ';
 End;
 VBS_MakeText(ResultText,Value);Value.ValueKind:=VBS_ValueString;VBS_SetVariableValue(Name,Value);
End;

Procedure VBS_ExecuteStatement(S:TMailText);
Var U,Name,RightSide,BaseName,IndexText:TMailText;P,I:Integer;
 V,IndexValue:VBS_TValue;ArrayVariable:VBS_PVariable;WasLet,WasSet:Boolean;
Begin
 If VBS_Upper(VBS_Trim(S))='OPTION EXPLICIT' Then Begin VBSExplicit:=True;Exit;End;
 If VBSHostStatement(S) Then Exit;
 S:=VBS_Trim(S);If(S='')or(S[1]='''')or(VBS_Upper(S)='REM')or VBS_StartsWith(S,'REM ')Then Exit;
 U:=VBS_Upper(S);WasLet:=False;WasSet:=False;
 If VBS_StartsWith(S,'DIM ')Then Begin
  Delete(S,1,4);Repeat Name:=VBS_ListItem(S);VBS_DeclareVariable(Name);Until S='';Exit;End;
 If VBS_StartsWith(S,'PRIVATE ')Then Begin
  Delete(S,1,8);Repeat Name:=VBS_ListItem(S);VBS_DeclareVariable(Name);Until S='';Exit;End;
 If VBS_StartsWith(S,'PUBLIC ')Then Begin
  Delete(S,1,7);Repeat Name:=VBS_ListItem(S);VBS_DeclareVariable(Name);Until S='';Exit;End;
 If VBS_StartsWith(S,'STATIC ')Then Begin
  Delete(S,1,7);Repeat Name:=VBS_ListItem(S);VBS_DeclareStaticVariable(Name);Until S='';Exit;End;
 If VBS_StartsWith(S,'ERASE ')Then Begin
  Delete(S,1,6);Repeat Name:=VBS_ListItem(S);VBS_EraseVariable(Name);Until S='';Exit;End;
 If VBS_StartsWith(S,'REDIM ')Then Begin
  Delete(S,1,6);WasLet:=False;
  If VBS_StartsWith(S,'PRESERVE ')Then Begin Delete(S,1,9);WasLet:=True;End;
  Repeat Name:=VBS_ListItem(S);VBS_ResizeArray(Name,WasLet);Until(S='')or VBS_Terminated;Exit;
 End;
 If U='ON ERROR RESUME NEXT'Then Begin VBS_OnErrorResumeNext:=True;Exit;End;
 If(U='ON ERROR GOTO 0')or(U='ON ERROR GO TO 0')Then Begin VBS_OnErrorResumeNext:=False;Exit;End;
 If VBS_StartsWith(U,'ON ERROR ')Then Begin VBS_ScriptError('forme ON ERROR non supportee: '+S,False);Exit;End;
 If VBS_StartsWith(S,'LSET ')Then Begin
  Delete(S,1,5);VBS_AlignStringAssignment(S,False);Exit;
 End;
 If VBS_StartsWith(S,'RSET ')Then Begin Delete(S,1,5);VBS_AlignStringAssignment(S,True);Exit;End;
 If U='EXIT DO'Then Begin VBS_ExitDoRequested:=True;Exit;End;
 If U='EXIT FOR'Then Begin VBS_ExitForRequested:=True;Exit;End;
 If U='EXIT SUB'Then Begin VBS_ExitSubRequested:=True;Exit;End;
 If U='EXIT FUNCTION'Then Begin VBS_ExitFunctionRequested:=True;Exit;End;
 If VBS_StartsWith(S,'CALL ')Then Begin VBS_CallSub(VBS_Trim(Copy(S,6,32767)));Exit;End;
 If VBS_StartsWith(S,'WScript.Echo')Then Delete(S,1,Length('WScript.Echo'))
 Else If VBS_StartsWith(S,'Echo ')Then Delete(S,1,5)
 Else If VBS_StartsWith(S,'WScript.Quit')Then Begin
  Delete(S,1,Length('WScript.Quit'));
  VBS_Evaluate(S,V);VBS_ExitCode:=Trunc(V.Number);
  VBS_Terminated:=True;
  Exit;
 End
  Else
 If VBS_StartsWith(S,'MSGBOX')Then Begin
  If(Length(S)>6)and(S[7]='(')Then VBS_Evaluate(S,V)
  Else VBS_Evaluate('MsgBox('+VBS_Trim(Copy(S,7,32767))+')',V);
  Exit;
 End
  Else
 If VBS_StartsWith(S,'Randomize')Then Begin
  RightSide:=VBS_Trim(Copy(S,10,32767));
  If RightSide=''Then Randomize Else Begin VBS_Evaluate(RightSide,V);RandSeed:=Trunc(V.Number);End;
  Exit;
 End
 Else
 Begin
  If VBS_StartsWith(S,'SET ')Then Begin Delete(S,1,4);WasSet:=True;End;
  If VBS_StartsWith(S,'LET ')Then Begin Delete(S,1,4);WasLet:=True;End;
  P:=VBS_FindAssignment(S);If P>0Then Begin
   Name:=VBS_Trim(Copy(S,1,P-1));
   If VBSExplicit And (Pos('(',Name)=0) And (VBS_FindVariable(Name)=Nil) Then Begin
    VBS_ScriptError('Variable non declaree: '+Name,True);Exit;
   End;
   RightSide:=Copy(S,P+1,32767);
   VBS_Evaluate(RightSide,V);
   I:=Pos('(',Name);
   If(I>0)and(Name[Length(Name)]=')')Then Begin
    BaseName:=VBS_Trim(Copy(Name,1,I-1));ArrayVariable:=VBS_FindVariable(BaseName);
    If(ArrayVariable<>Nil)and(ArrayVariable^.ValueKind=VBS_ValueArray)Then Begin
     VBS_Evaluate(Copy(Name,I+1,Length(Name)-I-1),IndexValue);Str(Trunc(IndexValue.Number),IndexText);
     VBS_SetVariableValue(ArrayVariable^.Value+'.'+VBS_Trim(IndexText),V);
    End Else VBS_SetVariableValue(Name,V);
   End Else VBS_SetVariableValue(Name,V);
   Exit;
  End;
  If WasLet Then Begin
   VBS_ScriptError('LET exige une affectation.',True);Exit;
  End;
  If WasSet Then Begin VBS_ScriptError('SET exige une affectation.',True);Exit;End;
  If VBS_UserSubExists(S)Then Begin VBS_CallSub(S);Exit;End;
  VBS_ScriptError('instruction non reconnue: '+S,False);
  Exit;
 End;
 { La branche Echo arrive ici. }
 I:=1;While I<=Length(S)Do Begin P:=Pos(',',Copy(S,I,32767));
  If P=0Then Begin VBS_Evaluate(Copy(S,I,32767),V);VBSOutput(V.Text);I:=Length(S)+1;End
  Else Begin VBS_Evaluate(Copy(S,I,P-1),V);VBSOutput(V.Text+' ');Inc(I,P);End;
 End;
End;

Procedure VBS_ExecuteStatementList(Source:TMailText);
Var I,StartPosition:Integer;Quote:Char;StatementText:TMailText;
Begin
 I:=1;StartPosition:=1;Quote:=#0;
 While I<=Length(Source)Do Begin
  If Quote<>#0Then Begin
   If Source[I]=Quote Then Begin
    If(I<Length(Source))and(Source[I+1]=Quote)Then Inc(I)Else Quote:=#0;
   End;
  End Else If Source[I]in['''','"']Then Quote:=Source[I]
  Else If Source[I]=':'Then Begin
   StatementText:=VBS_Trim(Copy(Source,StartPosition,I-StartPosition));
   If StatementText<>''Then VBS_ExecuteStatement(StatementText);StartPosition:=I+1;
   If VBS_Terminated or VBS_ExitDoRequested or VBS_ExitForRequested or VBS_ExitSubRequested or
     VBS_ExitFunctionRequested Then Exit;
  End;
  Inc(I);
 End;
 StatementText:=VBS_Trim(Copy(Source,StartPosition,32767));
 If StatementText<>''Then VBS_ExecuteStatement(StatementText);
End;

Procedure VBS_ExecuteRangeWork(FirstLine,LastLine:LongInt);
Var S,U,Condition,Name,Rest:TMailText;P,ThenPos,ElsePos:Integer;
 EndLine,BodyStart,I,ElseLine,ElementIndex,ElementCount:LongInt;
 V,StartValue,EndValue,StepValue,Counter,Collection,CountValue:VBS_TValue;
 LoopAgain,UntilMode:Boolean;IndexText,NextName:TMailText;
Begin
 I:=FirstLine;
 While(I<=LastLine)and Not VBS_Terminated and Not VBS_ExitDoRequested and
   Not VBS_ExitForRequested and Not VBS_ExitSubRequested and Not VBS_ExitFunctionRequested Do Begin
  VBS_CheckTimeout;If VBS_Terminated Then Exit;VBS_CurrentLine:=I;S:=VBS_Trim(VBS_ScriptLineText(I));U:=VBS_Upper(S);
  If VBS_StartsWith(S,'ELSEIF ')Then Begin S:='IF '+VBS_Trim(Copy(S,8,32767));U:=VBS_Upper(S);End;
  If VBS_StartsWith(S,'SUB ')or VBS_StartsWith(S,'PUBLIC SUB ')or
    VBS_StartsWith(S,'PRIVATE SUB ')Then Begin
   While(I<=LastLine)and(VBS_Upper(VBS_Trim(VBS_ScriptLineText(I)))<>'END SUB')Do Inc(I);
  End
  Else If VBS_StartsWith(S,'FUNCTION ')or VBS_StartsWith(S,'PUBLIC FUNCTION ')or
    VBS_StartsWith(S,'PRIVATE FUNCTION ')Then Begin
   While(I<=LastLine)and(VBS_Upper(VBS_Trim(VBS_ScriptLineText(I)))<>'END FUNCTION')Do Inc(I);
  End
  Else If U='END SUB'Then Exit
  Else If U='END FUNCTION'Then Exit
  Else If VBS_StartsWith(S,'IF ')Then Begin
   ThenPos:=Pos(' THEN',U);If ThenPos>0Then Begin Condition:=Copy(S,4,ThenPos-4);VBS_Evaluate(Condition,V);
    Rest:=VBS_Trim(Copy(S,ThenPos+5,32767));
    If Rest<>''Then Begin ElsePos:=VBS_KeywordOutsideQuotes(Rest,' ELSE ');
     If VBS_Truth(V)Then Begin
      If ElsePos>0Then VBS_ExecuteStatementList(Copy(Rest,1,ElsePos-1))Else VBS_ExecuteStatementList(Rest);End
     Else If ElsePos>0Then VBS_ExecuteStatementList(Copy(Rest,ElsePos+6,32767));
    End Else Begin EndLine:=VBS_FindBlock(I,'IF ','END IF');BodyStart:=I+1;
     ElseLine:=VBS_FindElseLine(I,EndLine);
     If VBS_Truth(V)Then Begin If ElseLine=0Then VBS_ExecuteRange(BodyStart,EndLine-1)Else
  VBS_ExecuteRange(BodyStart,ElseLine-1);End
     Else If ElseLine>0Then Begin
      If VBS_StartsWith(VBS_Trim(VBS_ScriptLineText(ElseLine)),'ELSEIF ')Then VBS_ExecuteRange(ElseLine,EndLine-1)
      Else VBS_ExecuteRange(ElseLine+1,EndLine-1);
     End;I:=EndLine;
    End;
   End;
  End Else If VBS_StartsWith(S,'FOR EACH ')Then Begin
   Rest:=VBS_Trim(Copy(S,10,32767));P:=Pos(' IN ',VBS_Upper(Rest));
   If P=0Then Begin VBSOutput('Erreur VBScript: FOR EACH sans IN.');VBS_ExitCode:=1;Exit;End;
   Name:=VBS_Trim(Copy(Rest,1,P-1));VBS_Evaluate(Copy(Rest,P+4,32767),Collection);
   EndLine:=VBS_FindBlock(I,'FOR ','NEXT');ElementCount:=0;
   If(Collection.ValueKind=VBS_ValueArray)or(Copy(Collection.Text,1,8)='@VBARRAY')Then Begin
    VBS_GetVariable(Collection.Text+'.COUNT',CountValue);ElementCount:=Trunc(CountValue.Number);
   End;
   For ElementIndex:=0To ElementCount-1Do Begin
    Str(ElementIndex,IndexText);VBS_GetVariable(Collection.Text+'.'+VBS_Trim(IndexText),V);
    VBS_SetVariableValue(Name,V);VBS_ExecuteRange(I+1,EndLine-1);
    If VBS_ExitForRequested Then Begin VBS_ExitForRequested:=False;Break;End;
    If VBS_Terminated or VBS_ExitSubRequested or VBS_ExitFunctionRequested or VBS_ExitDoRequested Then Break;
   End;
   I:=EndLine;
  End Else If VBS_StartsWith(S,'FOR ')Then Begin
   Rest:=VBS_Trim(Copy(S,5,32767));P:=VBS_FindAssignment(Rest);
   If P=0Then Begin VBSOutput('Erreur VBScript: FOR sans signe =.');VBS_ExitCode:=1;VBS_Terminated:=True;Exit;End;
   Name:=VBS_Trim(Copy(Rest,1,P-1));Delete(Rest,1,P);
   If Not VBS_SimpleIdentifier(Name)Then Begin VBSOutput('Erreur VBScript: compteur FOR invalide.');
    VBS_ExitCode:=1;VBS_Terminated:=True;Exit;End;
   ThenPos:=Pos(' TO ',VBS_Upper(Rest));
   If ThenPos=0Then Begin VBSOutput('Erreur VBScript: FOR sans TO.');VBS_ExitCode:=1;VBS_Terminated:=True;Exit;End;
   VBS_Evaluate(Copy(Rest,1,ThenPos-1),StartValue);Delete(Rest,1,ThenPos+3);
   ElsePos:=Pos(' STEP ',VBS_Upper(Rest));If ElsePos>0Then Begin
    VBS_Evaluate(Copy(Rest,1,ElsePos-1),EndValue);
    VBS_Evaluate(Copy(Rest,ElsePos+6,32767),StepValue);
   End
    Else
   Begin
    VBS_Evaluate(Rest,EndValue);
    VBS_MakeNumber(1,StepValue);
   End;
   If Not StartValue.IsNumber or Not EndValue.IsNumber or Not StepValue.IsNumber Then Begin
    VBSOutput('Erreur VBScript: bornes FOR non numeriques.');VBS_ExitCode:=1;VBS_Terminated:=True;Exit;End;
   If StepValue.Number=0Then Begin VBSOutput('Erreur VBScript: STEP ne peut pas etre nul.');
    VBS_ExitCode:=1;VBS_Terminated:=True;Exit;End;
   EndLine:=VBS_FindBlock(I,'FOR ','NEXT');
   NextName:=VBS_Trim(Copy(VBS_Trim(VBS_ScriptLineText(EndLine)),5,32767));
   If(NextName<>'')and(VBS_Upper(NextName)<>VBS_Upper(Name))Then Begin
    VBSOutput('Erreur VBScript: NEXT '+NextName+' ne correspond pas a FOR '+Name+'.');
    VBS_ExitCode:=1;VBS_Terminated:=True;Exit;
   End;
   Counter:=StartValue;
   While(((StepValue.Number>=0)and(Counter.Number<=EndValue.Number))or((StepValue.Number<0)and
        (Counter.Number>=EndValue.Number)))and Not VBS_Terminated and Not VBS_ExitSubRequested and
        Not VBS_ExitDoRequested and Not VBS_ExitFunctionRequested Do Begin
    VBS_SetVariableValue(Name,Counter);
    VBS_ExecuteRange(I+1,EndLine-1);
    If VBS_ExitForRequested Then Begin VBS_ExitForRequested:=False;Break;End;
    VBS_MakeNumber(Counter.Number+StepValue.Number,Counter);
   End;
   I:=EndLine;
  End
   Else
  If(U='DO')or VBS_StartsWith(U,'DO WHILE ')or VBS_StartsWith(U,'DO UNTIL ')Then Begin
   EndLine:=VBS_FindLoopEnd(I);Condition:='';UntilMode:=False;
   If VBS_StartsWith(U,'DO WHILE ')Then Condition:=VBS_Trim(Copy(S,10,32767))
   Else If VBS_StartsWith(U,'DO UNTIL ')Then Begin Condition:=VBS_Trim(Copy(S,10,32767));UntilMode:=True;End;
   Repeat
    LoopAgain:=True;
    If Condition<>''Then Begin VBS_Evaluate(Condition,V);
     If UntilMode Then LoopAgain:=Not VBS_Truth(V)Else LoopAgain:=VBS_Truth(V);End;
    If LoopAgain Then VBS_ExecuteRange(I+1,EndLine-1);
    If VBS_ExitDoRequested Then Begin VBS_ExitDoRequested:=False;LoopAgain:=False;End;
    If LoopAgain and Not VBS_Terminated and(Condition='')Then Begin
     Rest:=VBS_Trim(VBS_ScriptLineText(EndLine));
     If VBS_StartsWith(Rest,'LOOP WHILE ')Then Begin VBS_Evaluate(VBS_Trim(Copy(Rest,12,32767)),V);
  LoopAgain:=VBS_Truth(V);End
     Else If VBS_StartsWith(Rest,'LOOP UNTIL ')Then Begin VBS_Evaluate(VBS_Trim(Copy(Rest,12,32767)),V);LoopAgain:=Not
  VBS_Truth(V);End;
    End;
    VBS_CheckTimeout;
   Until(Not LoopAgain)or VBS_Terminated or VBS_ExitSubRequested or VBS_ExitFunctionRequested or VBS_ExitForRequested;
   I:=EndLine;
  End Else
  If VBS_StartsWith(S,'WHILE ')Then Begin
   EndLine:=VBS_FindBlock(I,'WHILE ','WEND');
   Condition:=Copy(S,7,32767);VBS_Evaluate(Condition,V);
   While VBS_Truth(V)and Not VBS_Terminated and Not VBS_ExitSubRequested and
     Not VBS_ExitForRequested and Not VBS_ExitDoRequested and Not VBS_ExitFunctionRequested Do Begin
    VBS_ExecuteRange(I+1,EndLine-1);
    VBS_Evaluate(Condition,V);VBS_CheckTimeout;
   End;
   I:=EndLine;
  End
   Else
  If VBS_StartsWith(U,'NEXT')Then Begin VBS_ScriptError('NEXT sans FOR correspondant.',False);Exit;End
  Else If(U='ELSE')or(U='END IF')or(U='WEND')or VBS_StartsWith(U,'LOOP')Then Exit
  Else If(U='REM')or VBS_StartsWith(U,'REM ')or((Length(S)>0)and(S[1]=''''))Then VBS_ExecuteStatement(S)
  Else VBS_ExecuteStatementList(S);
  Inc(I);
 End;
End;

Procedure VBS_ExecuteRange(FirstLine,LastLine:LongInt);
Begin
 Inc(VBSDepth);
 If VBSDepth>32 Then Begin
  VBS_OnErrorResumeNext:=False;VBS_ScriptError('Recursion trop profonde.',True);
 End
 Else VBS_ExecuteRangeWork(FirstLine,LastLine);
 Dec(VBSDepth);
End;

Function VBS_ListItem(Var Source:TMailText):TMailText;
Var I,Depth:Integer;Quote:Char;InQuote:Boolean;
Begin
 I:=1;Depth:=0;Quote:=#0;InQuote:=False;
 While I<=Length(Source)Do Begin
  If InQuote Then Begin
   If Source[I]=Quote Then Begin
    If(I<Length(Source))and(Source[I+1]=Quote)Then Inc(I)Else InQuote:=False;
   End;
  End Else If Source[I]in['''','"']Then Begin InQuote:=True;Quote:=Source[I];End
  Else If Source[I]='('Then Inc(Depth)
  Else If Source[I]=')'Then Begin If Depth>0Then Dec(Depth);End
  Else If(Source[I]=',')and(Depth=0)Then Begin
   VBS_ListItem:=VBS_Trim(Copy(Source,1,I-1));Delete(Source,1,I);Exit;
  End;
  Inc(I);
 End;
 VBS_ListItem:=VBS_Trim(Source);Source:='';
End;

Function VBS_SimpleIdentifier(Source:TMailText):Boolean;
Var I:Integer;
Begin
 Source:=VBS_Trim(Source);VBS_SimpleIdentifier:=False;If Source=''Then Exit;
 If Not(Source[1]in['A'..'Z','a'..'z','_'])Then Exit;
 For I:=2To Length(Source)Do If Not(Source[I]in['A'..'Z','a'..'z','0'..'9','_'])Then Exit;
 VBS_SimpleIdentifier:=True;
End;

Procedure VBS_CallSub(CallText:TMailText);
Var CallName,ArgumentText,Declaration,DeclarationName,ParameterText:TMailText;
 ParameterName,ArgumentExpression,UpperDeclaration:TMailText;
 I,P,NameEnd:Integer;StartLine,EndLine:LongInt;Binding,NextBinding:VBS_PCallBinding;
 Existing:VBS_PVariable;ArgumentValue,CopyValue:VBS_TValue;ByReference:Boolean;
Begin
 CallText:=VBS_Trim(CallText);P:=Pos('(',CallText);
 If P>0Then Begin
  CallName:=VBS_Trim(Copy(CallText,1,P-1));ArgumentText:=Copy(CallText,P+1,32767);
  If(Length(ArgumentText)>0)and(ArgumentText[Length(ArgumentText)]=')')Then
   Delete(ArgumentText,Length(ArgumentText),1);
 End Else Begin
  P:=Pos(' ',CallText);
  If P>0Then Begin CallName:=Copy(CallText,1,P-1);ArgumentText:=VBS_Trim(Copy(CallText,P+1,32767));End
  Else Begin CallName:=CallText;ArgumentText:='';End;
 End;
 StartLine:=0;EndLine:=0;ParameterText:='';
 For I:=1To VBS_LineCount Do Begin
  Declaration:=VBS_Trim(VBS_ScriptLineText(I));UpperDeclaration:=VBS_Upper(Declaration);
  If VBS_StartsWith(Declaration,'PUBLIC SUB ')Then Delete(Declaration,1,7)
  Else If VBS_StartsWith(Declaration,'PRIVATE SUB ')Then Delete(Declaration,1,8);
  If VBS_StartsWith(Declaration,'SUB ')Then Begin
   Delete(Declaration,1,4);P:=Pos('(',Declaration);NameEnd:=Pos(' ',Declaration);
   If(P=0)or((NameEnd>0)and(NameEnd<P))Then P:=NameEnd;
   If P=0Then DeclarationName:=VBS_Trim(Declaration)
   Else DeclarationName:=VBS_Trim(Copy(Declaration,1,P-1));
   If VBS_Upper(DeclarationName)=VBS_Upper(CallName)Then Begin
    StartLine:=I;P:=Pos('(',Declaration);
    If P>0Then Begin ParameterText:=Copy(Declaration,P+1,32767);
     If(Length(ParameterText)>0)and(ParameterText[Length(ParameterText)]=')')Then
      Delete(ParameterText,Length(ParameterText),1);End;
    Break;
   End;
  End;
 End;
 If StartLine=0Then Begin
  VBSOutput('Erreur VBScript: procedure introuvable: '+CallName);
  VBS_ExitCode:=1;Exit;
 End;
 EndLine:=StartLine+1;
 While(EndLine<=VBS_LineCount)and(VBS_Upper(VBS_Trim(VBS_ScriptLineText(EndLine)))<>'END SUB')Do Inc(EndLine);
 Binding:=Nil;
 While ParameterText<>''Do Begin
  ParameterName:=VBS_ListItem(ParameterText);ByReference:=True;
  If VBS_StartsWith(ParameterName,'BYVAL ')Then Begin Delete(ParameterName,1,6);ByReference:=False;End
  Else If VBS_StartsWith(ParameterName,'BYREF ')Then Delete(ParameterName,1,6);
  P:=Pos(' ',ParameterName);If P>0Then ParameterName:=Copy(ParameterName,1,P-1);
  ArgumentExpression:=VBS_ListItem(ArgumentText);VBS_Evaluate(ArgumentExpression,ArgumentValue);
  New(NextBinding);NextBinding^.Name:=VBS_Upper(ParameterName);
  NextBinding^.ActualName:=VBS_Upper(VBS_Trim(ArgumentExpression));
  NextBinding^.CopyBack:=ByReference and VBS_SimpleIdentifier(ArgumentExpression);
  Existing:=VBS_FindVariable(ParameterName);NextBinding^.Existed:=Existing<>Nil;
  If Existing<>Nil Then Begin NextBinding^.OldValue:=Existing^.Value;
   NextBinding^.OldKind:=Existing^.ValueKind;End
  Else Begin NextBinding^.OldValue:='';NextBinding^.OldKind:=VBS_ValueEmpty;End;
  NextBinding^.Next:=Binding;Binding:=NextBinding;VBS_SetVariableValue(ParameterName,ArgumentValue);
 End;
 VBS_ExecuteRange(StartLine+1,EndLine-1);VBS_ExitSubRequested:=False;
 NextBinding:=Binding;
 While NextBinding<>Nil Do Begin
  If NextBinding^.CopyBack Then Begin VBS_GetVariable(NextBinding^.Name,CopyValue);
   VBS_SetVariableValue(NextBinding^.ActualName,CopyValue);End;
  NextBinding:=NextBinding^.Next;
 End;
 While Binding<>Nil Do Begin
  NextBinding:=Binding^.Next;
  If Binding^.Existed Then Begin VBS_MakeText(Binding^.OldValue,CopyValue);
   CopyValue.ValueKind:=Binding^.OldKind;VBS_SetVariableValue(Binding^.Name,CopyValue);End
  Else VBS_RemoveVariable(Binding^.Name);
  Dispose(Binding);Binding:=NextBinding;
 End;
End;

Procedure VBS_FunctionArgument(Index:Integer;A,B,C,D:VBS_TValue;Var V:VBS_TValue);
Begin
 Case Index of
  0:V:=A;
  1:V:=B;
  2:V:=C;
  3:V:=D;
 Else VBS_MakeText('',V);
 End;
End;

Procedure VBS_SaveFunctionBinding(Name:TMailText;Value:VBS_TValue;Var Bindings:VBS_PCallBinding);
Var Binding:VBS_PCallBinding;Existing:VBS_PVariable;
Begin
 New(Binding);Binding^.Name:=VBS_Upper(VBS_Trim(Name));Binding^.ActualName:='';
 Binding^.CopyBack:=False;Existing:=VBS_FindVariable(Name);Binding^.Existed:=Existing<>Nil;
 If Existing<>Nil Then Begin Binding^.OldValue:=Existing^.Value;
  Binding^.OldKind:=Existing^.ValueKind;End
 Else Begin Binding^.OldValue:='';Binding^.OldKind:=VBS_ValueEmpty;End;
 Binding^.Next:=Bindings;Bindings:=Binding;VBS_SetVariableValue(Name,Value);
End;

Procedure VBS_RestoreFunctionBindings(Var Bindings:VBS_PCallBinding);
Var Binding:VBS_PCallBinding;OldValue:VBS_TValue;
Begin
 While Bindings<>Nil Do Begin Binding:=Bindings^.Next;
  If Bindings^.Existed Then Begin VBS_MakeText(Bindings^.OldValue,OldValue);
   OldValue.ValueKind:=Bindings^.OldKind;VBS_SetVariableValue(Bindings^.Name,OldValue);End
  Else VBS_RemoveVariable(Bindings^.Name);
  Dispose(Bindings);Bindings:=Binding;
 End;
End;

Procedure VBS_CallUserFunction(FunctionName:TMailText;A,B,C,D:VBS_TValue;
 ArgumentCount:Integer;Var V:VBS_TValue);
Var I,P,ParameterIndex:Integer;StartLine,EndLine:LongInt;
 Declaration,DeclarationName,ParameterText,ParameterName:TMailText;
 SavedExpression:TMailText;SavedPosition:Integer;
 Bindings:VBS_PCallBinding;ArgumentValue,EmptyValue:VBS_TValue;
Begin
 SavedExpression:=VBS_ExprText;SavedPosition:=VBS_ExprPos;
 StartLine:=0;EndLine:=0;ParameterText:='';
 For I:=1To VBS_LineCount Do Begin
  Declaration:=VBS_Trim(VBS_ScriptLineText(I));
  If VBS_StartsWith(Declaration,'PUBLIC FUNCTION ')Then Delete(Declaration,1,7)
  Else If VBS_StartsWith(Declaration,'PRIVATE FUNCTION ')Then Delete(Declaration,1,8);
  If VBS_StartsWith(Declaration,'FUNCTION ')Then Begin
   Delete(Declaration,1,9);P:=Pos('(',Declaration);
   If P=0Then DeclarationName:=VBS_Trim(Declaration)
   Else DeclarationName:=VBS_Trim(Copy(Declaration,1,P-1));
   If VBS_Upper(DeclarationName)=VBS_Upper(FunctionName)Then Begin
    StartLine:=I;
    If P>0Then Begin ParameterText:=Copy(Declaration,P+1,32767);
     If(Length(ParameterText)>0)and(ParameterText[Length(ParameterText)]=')')Then
      Delete(ParameterText,Length(ParameterText),1);End;
    Break;
   End;
  End;
 End;
 If StartLine=0Then Begin VBS_MakeText('',V);VBS_ExprText:=SavedExpression;VBS_ExprPos:=SavedPosition;Exit;End;
 EndLine:=StartLine+1;
 While(EndLine<=VBS_LineCount)and(VBS_Upper(VBS_Trim(VBS_ScriptLineText(EndLine)))<>'END FUNCTION')Do Inc(EndLine);
 Bindings:=Nil;VBS_MakeText('',EmptyValue);VBS_SaveFunctionBinding(FunctionName,EmptyValue,Bindings);
 ParameterIndex:=0;
 While ParameterText<>''Do Begin
  ParameterName:=VBS_ListItem(ParameterText);
  If VBS_StartsWith(ParameterName,'BYVAL ')Then Delete(ParameterName,1,6)
  Else If VBS_StartsWith(ParameterName,'BYREF ')Then Delete(ParameterName,1,6);
  P:=Pos(' ',ParameterName);If P>0Then ParameterName:=Copy(ParameterName,1,P-1);
  If ParameterIndex<ArgumentCount Then VBS_FunctionArgument(ParameterIndex,A,B,C,D,ArgumentValue)
  Else VBS_MakeText('',ArgumentValue);
  VBS_SaveFunctionBinding(ParameterName,ArgumentValue,Bindings);Inc(ParameterIndex);
 End;
 VBS_ExecuteRange(StartLine+1,EndLine-1);VBS_ExitFunctionRequested:=False;
 VBS_GetVariable(FunctionName,V);VBS_RestoreFunctionBindings(Bindings);
 VBS_ExprText:=SavedExpression;VBS_ExprPos:=SavedPosition;
End;


{ Hote Outlook du moteur Pascal inspire de DEV-COOLS/CSCRIPT.PAS.
  Un seul message composeur est disponible. Aucun envoi implicite. }
Function VBSName(S:TMailText):TMailText;
Begin
 S:=VBS_Upper(VBS_Trim(S));
 While (Length(S)>0) And (S[Length(S)]='.') Do Delete(S,Length(S),1);
 VBSName:=S;
End;

Function VBSModalOpen:Boolean;
Begin
 VBSModalOpen:=ComposerVisible Or AccountDialogVisible Or PrefsVisible Or RulesVisible Or
  FileOpenVisible Or SortDialogVisible Or ColumnsDialogVisible Or AboutVisible Or EventDialogVisible;
End;

Procedure VBSSetProperty(Name,Value:TMailText);
Var I,P:LongInt; Rest,Part:TMailText;
Begin
 If Not ComposerVisible Then Begin VBS_ScriptError('Aucun nouveau message ouvert.',True);Exit;End;
 SaveComposerFields;
 Name:=VBSName(Name);
 If ((Name='SUBJECT') And (Length(Value)>80)) Or
    (((Name='TO') Or (Name='CC') Or (Name='BCC')) And (Length(Value)>250)) Then Begin
  VBS_ScriptError('Champ du message trop long: '+Name,True);Exit;
 End;
 If Name='SUBJECT' Then Composer.SubjectField:=Value
 Else If Name='TO' Then Composer.ToField:=Value
 Else If Name='CC' Then Composer.CcField:=Value
 Else If Name='BCC' Then Composer.BccField:=Value
 Else If (Name='FROM') Or (Name='SENDER') Or (Name='SOURCE') Then Begin
  I:=0;
  While (I<EmailAccountCount) And (VBS_Upper(EmailAccounts[I].EmailAddress)<>VBS_Upper(Value)) Do Inc(I);
  If I=EmailAccountCount Then Begin VBS_ScriptError('Compte expediteur inconnu: '+Value,True);Exit;End;
  Composer.AccountIndex:=I;
 End Else If Name='BODY' Then Begin
  Composer.LineCount:=0; Rest:=Value;
  Repeat
   P:=Pos(#10,Rest); If P=0 Then P:=Length(Rest)+1;
   Part:=Copy(Rest,1,P-1);Delete(Rest,1,P);
   If (Length(Part)>0) And (Part[Length(Part)]=#13) Then Delete(Part,Length(Part),1);
   Repeat
    I:=Composer.LineCount;
    If I>=500 Then Begin VBS_ScriptError('Corps du message trop long.',True);Exit;End;
    Composer.Lines[I].Text:=Copy(Part,1,250); Delete(Part,1,250);
    Inc(Composer.LineCount);
   Until Part='';
  Until Rest='';
 End Else Begin VBS_ScriptError('Propriete de message inconnue: '+Name,True);Exit;End;
 Composer.Modified:=True; InitComposerFields;
End;

Function VBSHostValue(Name:TMailText;Var V:VBS_TValue):Boolean;
Var P,I,A:Integer;Obj:VBS_PVariable;Value:TMailText;
Begin
 VBSHostValue:=False;P:=Pos('.',Name);If P=0 Then Exit;
 Obj:=VBS_FindVariable(Copy(Name,1,P-1));
 If (Obj=Nil) Or (Obj^.Value<>'@MESSAGE') Then Exit;
 VBSHostValue:=True;Name:=VBSName(Copy(Name,P+1,32767));Value:='';
 If Not ComposerVisible Then Begin VBS_ScriptError('Aucun message ouvert.',True);VBS_MakeText('',V);Exit;End;
 SaveComposerFields;
 If Name='SUBJECT' Then Value:=Composer.SubjectField
 Else If Name='TO' Then Value:=Composer.ToField
 Else If Name='CC' Then Value:=Composer.CcField
 Else If Name='BCC' Then Value:=Composer.BccField
 Else If Name='BODY' Then Begin
  For I:=0 To Composer.LineCount-1 Do Begin
   If I>0 Then Value:=Value+#13#10;
   Value:=Value+Composer.Lines[I].Text;
  End;
 End Else If (Name='FROM') Or (Name='SOURCE') Or (Name='SENDER') Then Begin
  A:=Composer.AccountIndex;
  If (A<0) And (SelectedFolder>=0) And (SelectedFolder<FolderCount) Then A:=MailFolderAccount[SelectedFolder];
  If A<0 Then For I:=0 To EmailAccountCount-1 Do If EmailAccounts[I].IsDefault Then A:=I;
  If (A>=0) And (A<EmailAccountCount) Then Value:=EmailAccounts[A].EmailAddress;
 End Else VBS_ScriptError('Propriete de message inconnue: '+Name,True);
 VBS_MakeText(Value,V);V.ValueKind:=VBS_ValueString;
End;

Function VBSHostStatement(S:TMailText):Boolean;
Var U,Name,RightSide,Target,Method,Args,Base:TMailText; P,Q,I,J,Cmd:Integer; V:VBS_TValue;
 Obj:VBS_PVariable;
Begin
 VBSHostStatement:=False;S:=VBS_Trim(S);U:=VBS_Upper(S);
 If (S='') Or (S[1]='''') Or (U='REM') Or VBS_StartsWith(U,'REM ') Then Exit;
 If VBS_StartsWith(S,'CALL ') Then Begin Delete(S,1,5); S:=VBS_Trim(S); U:=VBS_Upper(S);End;
 If VBS_StartsWith(S,'SET ') Then Begin
  Delete(S,1,4);P:=VBS_FindAssignment(S);If P=0 Then Exit;
  Name:=VBS_Trim(Copy(S,1,P-1));
  If VBSExplicit And (VBS_FindVariable(Name)=Nil) Then Begin
   VBSHostStatement:=True;VBS_ScriptError('Variable non declaree: '+Name,True);Exit;
  End;
  RightSide:=VBS_Trim(Copy(S,P+1,32767));U:=VBS_Upper(RightSide);
  If (U='OUTLOOK') Or (U='APPLICATION') Or (Pos('CREATEOBJECT(',U)=1) Then Begin
   If Pos('CREATEOBJECT(',U)=1 Then Begin
    Args:=Copy(RightSide,14,Length(RightSide)-14);VBS_Evaluate(Args,V);
    If VBS_Upper(V.Text)<>'OUTLOOK.APPLICATION' Then Begin
     VBSHostStatement:=True;VBS_ScriptError('CreateObject accepte Outlook.Application uniquement.',True);Exit;
    End;
   End;
   VBS_MakeText('@OUTLOOK',V);V.ValueKind:=VBS_ValueObject;
   VBS_SetVariableValue(Name,V);VBSHostStatement:=True;Exit;
  End;
  P:=Pos('.',U);
  If P>0 Then Begin
   Base:=VBS_Trim(Copy(RightSide,1,P-1));Obj:=VBS_FindVariable(Base);
   If (VBS_Upper(Base)='OUTLOOK') Or (VBS_Upper(Base)='APPLICATION') Or
      ((Obj<>Nil) And (Obj^.Value='@OUTLOOK')) Then Begin
    If Copy(U,P+1,11)='CREATEITEM(' Then Begin
     VBSHostStatement:=True;Args:=Copy(RightSide,P+12,Length(RightSide)-P-12);VBS_Evaluate(Args,V);
     If Not V.IsNumber Or (V.Number<>0) Then Begin VBS_ScriptError('CreateItem accepte 0 (courriel).',True);Exit;End;
     If VBSModalOpen Then Begin VBS_ScriptError('Fermez le dialogue actif avant CreateItem.',True);Exit;End;
     ActiveMenu:=-1;OpenNewMessage;VBS_MakeText('@MESSAGE',V);V.ValueKind:=VBS_ValueObject;
     VBS_SetVariableValue(Name,V);Exit;
    End;
   End;
  End;
  Exit;
 End;
 P:=Pos('.',S);If P=0 Then Exit;
 Target:=VBS_Upper(VBS_Trim(Copy(S,1,P-1)));
 If Not VBS_SimpleIdentifier(Target) Then Exit;
 If Target='WSCRIPT' Then Exit;
 Obj:=VBS_FindVariable(Target);
 If (Target='OUTLOOK') Or (Target='APPLICATION') Then Target:='@OUTLOOK'
 Else If Obj<>Nil Then Target:=Obj^.Value;
 If (Target<>'@OUTLOOK') And (Target<>'@MESSAGE') Then Begin
  Q:=VBS_FindAssignment(S);
  If (Q=0) Or (P<Q) Then Begin
   VBSHostStatement:=True;VBS_ScriptError('Objet inconnu: '+Target,True);
  End;
  Exit;
 End;
 VBSHostStatement:=True;Method:=VBS_Trim(Copy(S,P+1,32767));
 P:=VBS_FindAssignment(Method);
 If (Target='@MESSAGE') And (P>0) Then Begin
  Name:=VBS_Trim(Copy(Method,1,P-1));VBS_Evaluate(Copy(Method,P+1,32767),V);
  If Not VBS_Terminated Then VBSSetProperty(Name,V.Text);Exit;
 End;
 P:=1;While (P<=Length(Method)) And Not (Method[P] In [' ',#9,'(']) Do Inc(P);
 Args:=VBS_Trim(Copy(Method,P,32767));Method:=VBSName(Copy(Method,1,P-1));
 If (Length(Args)>0) And (Args[1]='(') Then Begin
  If Args[Length(Args)]<>')' Then Begin VBS_ScriptError('Parenthese fermante manquante.',True);Exit;End;
  Args:=Copy(Args,2,Length(Args)-2);
 End;
 If Target='@MESSAGE' Then Begin
  If (Method='DISPLAY') And (Args='') Then Begin DrawInterface;Exit;End;
  VBS_ScriptError('Methode de message inconnue: '+Method,True);Exit;
 End;
 If Method='NEWMESSAGE' Then Begin
  If VBSModalOpen Then Begin VBS_ScriptError('Un dialogue est deja ouvert.',True);Exit;End;
  ActiveMenu:=-1;OpenNewMessage;
  I:=0;While Args<>'' Do Begin
   Name:=VBS_ListItem(Args);VBS_Evaluate(Name,V);
   Case I Of 0:Name:='SUBJECT';1:Name:='FROM';2:Name:='TO';3:Name:='BODY';
    Else Begin VBS_ScriptError('NewMessage: quatre arguments maximum.',True);Exit;End;
   End;
   If (I<>1) Or (V.Text<>'') Then VBSSetProperty(Name,V.Text);
   If VBS_Terminated Then Exit;Inc(I);
  End;
  Exit;
 End;
 If VBSModalOpen Then Begin VBS_ScriptError('Un dialogue est deja ouvert.',True);Exit;End;
 VBS_Evaluate(Args,V);If VBS_Terminated Then Exit;Name:=VBSName(V.Text);
 If Method='OPENMENU' Then Begin
  If Name='AIDE' Then Name:='?';
  For I:=0 To 5 Do If VBSName(Menus[I].Title)=Name Then Begin OpenMenuShortcut(I);Exit;End;
  VBS_ScriptError('Menu inconnu: '+V.Text,True);Exit;
 End;
 If (Method='SHOWDIALOG') Or (Method='EXECUTECOMMAND') Then Begin
  Cmd:=-1;
  For I:=0 To 5 Do For J:=0 To Menus[I].ItemCount-1 Do
   If Not Menus[I].Items[J].Separator And (VBSName(Menus[I].Items[J].Caption)=Name) Then
    Cmd:=Menus[I].Items[J].ItemID;
  If Cmd<0 Then Begin VBS_ScriptError('Commande inconnue: '+V.Text,True);Exit;End;
  ExecuteMenuCommand(Cmd);Exit;
 End;
 VBS_ScriptError('Methode Outlook inconnue: '+Method,True);
End;

Function VBSWithoutComment(S:TMailText):TMailText;
Var I:Integer;Quoted:Boolean;
Begin
 I:=1;Quoted:=False;
 While I<=Length(S) Do Begin
  If S[I]='"' Then Begin
   If Quoted And (I<Length(S)) And (S[I+1]='"') Then Inc(I)
   Else Quoted:=Not Quoted;
  End Else If (S[I]='''') And Not Quoted Then Begin
   S:=Copy(S,1,I-1);Break;
  End;
  Inc(I);
 End;
 VBSWithoutComment:=S;
End;

Procedure RunStartupScript;
Var F:Text; S:TMailText; Err:Integer; Line:VBS_PScriptLine; Entry:VBS_PVariable; N:TMailText;
Begin
 If VBSStarted Or (CommandLineScript='') Then Exit;
 VBSStarted:=True;VBS_Terminated:=False;VBS_ExitCode:=0;VBSDiagnostic:='';VBS_CurrentLine:=0;
 VBS_LineCount:=0;VBS_ArrayCounter:=0;VBSSteps:=0;VBSDepth:=0;
 VBS_FirstScriptLine:=Nil;VBS_LastScriptLine:=Nil;VBS_Variables:=Nil;
 VBS_OnErrorResumeNext:=False;VBS_TimeLimit:=5;VBSExplicit:=False;
 VBS_ExitDoRequested:=False;VBS_ExitForRequested:=False;
 VBS_ExitSubRequested:=False;VBS_ExitFunctionRequested:=False;
 VBS_ScriptName:=CommandLineScript;VBS_ScriptArgumentCount:=0;
 For Err:=0 To VBS_MaxArguments-1 Do VBS_ScriptArguments[Err]:='';
 {$I-}Assign(F,CommandLineScript);Reset(F);{$I+}Err:=IOResult;
 If Err<>0 Then VBS_ScriptError('Impossible de lire '+CommandLineScript,True)
 Else Begin
  While Not Eof(F) And Not VBS_Terminated Do Begin
   {$I-}ReadLn(F,S);{$I+}Err:=IOResult;
   If Err<>0 Then VBS_ScriptError('Erreur de lecture du script.',True)
   Else If Length(S)>255 Then Begin
    VBS_CurrentLine:=VBS_LineCount+1;VBS_ScriptError('Ligne de script superieure a 255 caracteres.',True);
   End Else Begin
    If (VBS_LineCount=0) And (Copy(S,1,3)=#$EF#$BB#$BF) Then Delete(S,1,3);
    VBS_AddScriptLine(VBSWithoutComment(S));
   End;
   If VBS_LineCount>10000 Then VBS_ScriptError('Script trop volumineux.',True);
  End;
  {$I-}Close(F);{$I+}Err:=IOResult;
 End;
 If Not VBS_Terminated Then Begin
  VBS_SetVariable('vbCrLf',#13#10);VBS_SetVariable('vbCr',#13);VBS_SetVariable('vbLf',#10);
  VBS_SetVariable('vbTab',#9);VBS_SetVariable('olMailItem','0');
  GetTime(VBS_StartHour,VBS_StartMinute,VBS_StartSecond,VBS_StartHundredth);
  VBS_ExecuteRange(1,VBS_LineCount);
 End;
 If VBS_ExitCode<>0 Then Begin
  If VBSDiagnostic='' Then Begin Str(VBS_ExitCode,N);VBSDiagnostic:='Code de sortie '+N;End;
  Str(VBS_CurrentLine,N);MailStatus:='VBScript ligne '+N+': '+VBSDiagnostic;
 End Else If VBSDiagnostic='' Then MailStatus:='VBScript execute: '+CommandLineScript;
 While VBS_FirstScriptLine<>Nil Do Begin
  Line:=VBS_FirstScriptLine^.Next;Dispose(VBS_FirstScriptLine);VBS_FirstScriptLine:=Line;
 End;
 VBS_LastScriptLine:=Nil;
 While VBS_Variables<>Nil Do Begin Entry:=VBS_Variables^.Next;Dispose(VBS_Variables);VBS_Variables:=Entry;End;
 DrawInterface;
End;

{ Boucle principale de gestion des evenements }

{ ====================================================================== }
{  OS/2-0 : barre de menus de PM construite a partir des menus d'Outlink }
{ ====================================================================== }
{ Les menus deroulants dessines par Outlink (Menus[], InitializeMenus)    }
{ deviennent la barre de menus de PM : memes titres, memes elements,      }
{ memes raccourcis (affiches a droite) et elements grises ; une commande  }
{ de PM appelle ExecuteMenuCommand avec l'identifiant d'origine. Si la    }
{ langue change (titres traduits), la barre est reconstruite.             }

Function OsMenuSignature : LongInt;
Var I, J, K, H : LongInt;
Begin
 H := MenuCount;
 For I := 0 To MenuCount - 1 Do
 Begin
  For K := 1 To Length(Menus[I].Title) Do H := (H * 31 + Ord(Menus[I].Title[K])) And $7FFFFFF;
  For J := 0 To Menus[I].ItemCount - 1 Do
   For K := 1 To Length(Menus[I].Items[J].Caption) Do
    H := (H * 31 + Ord(Menus[I].Items[J].Caption[K])) And $7FFFFFF;
 End;
 OsMenuSignature := H;
End;

{ titre avec la lettre soulignee (~) : premiere lettre libre }
Function OsMnemonic(S : String; Var Used : String) : String;
Var K : LongInt; C : Char;
Begin
 For K := 1 To Length(S) Do
 Begin
  C := UpCase(S[K]);
  If (C >= 'A') And (C <= 'Z') And (Pos(C, Used) = 0) Then
  Begin
   Used := Used + C;
   OsMnemonic := Copy(S, 1, K - 1) + '~' + Copy(S, K, 255);
   Exit;
  End;
 End;
 OsMnemonic := S;
End;

Procedure OsSyncMenu;
Var I, J, H0, H1, N, M, Attr : LongInt; Used, S : String;
Begin
 If (OsFrame = 0) Or RibbonMode Then Exit;
 If OsMenuSignature = OsMenuSig Then Exit;
 OsMenuSig := OsMenuSignature;
 OsMenuLen := 0;
 Used := '';
 H0 := OsMnOpen;
 For I := 0 To MenuCount - 1 Do
 Begin
  OsMnItem(MIS_TEXT Or MIS_SUBMENU, 0, OS_MENUID - 100 - I, OsMnemonic(Menus[I].Title, Used));
  H1 := OsMnOpen;
  N := 0;
  For J := 0 To Menus[I].ItemCount - 1 Do
  Begin
   If Menus[I].Items[J].Separator Then OsMnItem(MIS_SEPARATOR, 0, 0, '')
   Else
   Begin
    S := Menus[I].Items[J].Caption;
    If Menus[I].Items[J].Shortcut <> '' Then S := S + Chr(9) + Menus[I].Items[J].Shortcut;
    If Menus[I].Items[J].Enabled Then Attr := 0 Else Attr := MIA_DISABLED;
    OsMnItem(MIS_TEXT, Attr, OS_MENUID + Menus[I].Items[J].ItemID, S);
   End;
   Inc(N);
  End;
  OsMnClose(H1, N);
 End;
 OsMnClose(H0, MenuCount);
 M := WinCreateMenu(OsFrame, LongInt(@OsMenuT));
 OsDummy := WinSendMsg(OsFrame, $0042, $FFFF, 0);      { WM_UPDATEFRAME : FCF_MENU }
End;

{ a l'ouverture d'un menu : elements actifs ou grises, comme Outlink }
Procedure OsMenuInit;
Var I, J, M : LongInt;
Begin
 M := WinWindowFromID(OsFrame, $8005);
 If M = 0 Then Exit;
 For I := 0 To MenuCount - 1 Do
  For J := 0 To Menus[I].ItemCount - 1 Do
   If Not Menus[I].Items[J].Separator Then
   Begin
    If Menus[I].Items[J].Enabled Then
     OsDummy := WinSendMsg(M, MM_SETITEMATTR, (OS_MENUID + Menus[I].Items[J].ItemID) Or $10000, MIA_DISABLED)
    Else
     OsDummy := WinSendMsg(M, MM_SETITEMATTR, (OS_MENUID + Menus[I].Items[J].ItemID) Or $10000,
                           MIA_DISABLED Or (MIA_DISABLED Shl 16));
   End;
End;

{ commandes de la barre de menus de PM : depuis la boucle d'Outlink }
Procedure OsDispatchCommands;
Var Id : LongInt;
Begin
 While OsCHead <> OsCTail Do
 Begin
  Id := OsCmds[OsCHead];
  OsCHead := (OsCHead + 1) Mod OsCmdMax;
  If ActiveMenu >= 0 Then CloseDropdownMenu;
  ExecuteMenuCommand(Id);
 End;
End;

{ raccourcis des menus (F5, Ctrl+N, Suppr...) : la version DOS les affiche }
{ sans les traiter tous ; ici, la touche cherche l'element de menu        }
Function OsAccel(Key : Char; Ext : Boolean) : Boolean;
Var Name : String; I, J : LongInt;
Begin
 OsAccel := False; Name := '';
 If Ext Then
 Begin
  If (Ord(Key) >= 59) And (Ord(Key) <= 68) Then Str(Ord(Key) - 58, Name);
  If Name <> '' Then Name := 'F' + Name
  Else If Key = #83 Then Name := 'Suppr'
  Else If Key = #107 Then Name := 'Alt+F4'
  Else If (Ord(Key) >= 120) And (Ord(Key) <= 128) Then Name := 'Ctrl+' + Chr(Ord(Key) - 120 + Ord('1'));
 End
 Else If (Ord(Key) >= 1) And (Ord(Key) <= 26) And Not (Key In [#8, #9, #13]) Then
  Name := 'Ctrl+' + Chr(Ord(Key) + 64);
 If Name = '' Then Exit;
 For I := 0 To MenuCount - 1 Do
  For J := 0 To Menus[I].ItemCount - 1 Do
   If (Menus[I].Items[J].Shortcut = Name) And Menus[I].Items[J].Enabled And
      Not Menus[I].Items[J].Separator Then
   Begin
    If ActiveMenu >= 0 Then CloseDropdownMenu;
    ExecuteMenuCommand(Menus[I].Items[J].ItemID);
    OsAccel := True;
    Exit;
   End;
End;

{ liste des messages au clavier (fleches, Pg prec/suiv, Debut, Fin) et
  defilement : la version DOS montrait seulement les premiers messages }
Function OsListRows : LongInt;
Var N : LongInt;
Begin
 N := (Layout.MessageListRect.Y2 - MESSAGE_ROW_HEIGHT - (Layout.MessageListRect.Y1 + COLUMN_HEADER_HEIGHT + 1))
      Div MESSAGE_ROW_HEIGHT + 1;
 If N < 1 Then N := 1;
 OsListRows := N;
End;

Function OsListKey(Key : Char) : Boolean;
Var N, Rows : LongInt;
Begin
 OsListKey := False;
 If (MessageCount <= 0) Or CalendarVisible Then Exit;
 Rows := OsListRows; N := SelectedMessage;
 Case Key Of
  #72 : Dec(N);
  #80 : Inc(N);
  #73 : N := N - Rows + 1;
  #81 : N := N + Rows - 1;
  #71 : N := 0;
  #79 : N := MessageCount - 1;
 Else Exit;
 End;
 If N < 0 Then N := 0;
 If N > MessageCount - 1 Then N := MessageCount - 1;
 If N < MessageScrollOffset Then MessageScrollOffset := N;
 If N >= MessageScrollOffset + Rows Then MessageScrollOffset := N - Rows + 1;
 HandleMessageClick(N);
 HideMouse; DrawMessageList; DrawPreviewPane; ShowMouse;
 OsListKey := True;
End;

Procedure OlHeapInit;
Begin
 If DosAllocMem(LongInt(@Messages), SizeOf(TOlA_Messages), $13) <> 0 Then Halt(1);
 FillChar(Messages^, SizeOf(TOlA_Messages), 0);
 If DosAllocMem(LongInt(@MailNewMessages), SizeOf(TOlA_MailNewMessages), $13) <> 0 Then Halt(1);
 FillChar(MailNewMessages^, SizeOf(TOlA_MailNewMessages), 0);
 If DosAllocMem(LongInt(@HTMLTokens), SizeOf(TOlA_HTMLTokens), $13) <> 0 Then Halt(1);
 FillChar(HTMLTokens^, SizeOf(TOlA_HTMLTokens), 0);
 If DosAllocMem(LongInt(@Contacts), SizeOf(TOlA_Contacts), $13) <> 0 Then Halt(1);
 FillChar(Contacts^, SizeOf(TOlA_Contacts), 0);
 If DosAllocMem(LongInt(@Signatures), SizeOf(TOlA_Signatures), $13) <> 0 Then Halt(1);
 FillChar(Signatures^, SizeOf(TOlA_Signatures), 0);
 If DosAllocMem(LongInt(@FilterRules), SizeOf(TOlA_FilterRules), $13) <> 0 Then Halt(1);
 FillChar(FilterRules^, SizeOf(TOlA_FilterRules), 0);
 If DosAllocMem(LongInt(@RulesBackup), SizeOf(TOlA_RulesBackup), $13) <> 0 Then Halt(1);
 FillChar(RulesBackup^, SizeOf(TOlA_RulesBackup), 0);
 If DosAllocMem(LongInt(@PrintPages), SizeOf(TOlA_PrintPages), $13) <> 0 Then Halt(1);
 FillChar(PrintPages^, SizeOf(TOlA_PrintPages), 0);
 If DosAllocMem(LongInt(@CachedMessages), SizeOf(TOlA_CachedMessages), $13) <> 0 Then Halt(1);
 FillChar(CachedMessages^, SizeOf(TOlA_CachedMessages), 0);
 If DosAllocMem(LongInt(@POP3ListItems), SizeOf(TOlA_POP3ListItems), $13) <> 0 Then Halt(1);
 FillChar(POP3ListItems^, SizeOf(TOlA_POP3ListItems), 0);
End;

Procedure MainEventLoop;
Var
 LastBtn: Integer;
 Key: Char;
 IsExtendedKey: Boolean;
 MouseEvent: TMouseEvent;
 InToolbar: Boolean;
 InFolderPane: Boolean;
 InMessageList: Boolean;
 InMessageListHeader: Boolean;
 ClickedCol, ClickedMsg, ShortcutMenu: Integer;
Begin
 Running := True;
 LastMenuShortcut := -1; LastViewShortcut:=0;
 LastBtn := 0;
 DragState := dsNone;
 InitMouseState;
 ActiveMenu := -1;
 ActiveMenuItem := -1;
 MenuBarActive := False;
 HoveredToolButton := -1;
 PressedToolButton := -1;
 TooltipVisible := False;
 LastMouseX := 0;
 LastMouseY := 0;
 HoveredFolder := -1;
 ContextMenuVisible := False;
 RunStartupScript;

 While Running Do Begin
  If ApplicationQuitRequested Then Begin
   Running := False;
   Break;
  End;

  PollMenuShortcut;
  OsDispatchCommands;
  If OsQuit Then Begin Running := False; Break; End;

  { Lecture de l'etat de la souris }
  
   GetMouseState(MouseX, MouseY, MouseBtn);
  

  { Un relachement hors du ruban annule aussi le bouton, meme au-dessus du calendrier. }
  If RibbonMode And (RibbonPressed>=0) And (MouseBtn And MOUSE_LEFT=0) And
     (LastBtn And MOUSE_LEFT<>0) Then HandleToolbarRelease;

  If EventDialogVisible Then Begin
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then EventClick(MouseX,MouseY);
   LastMouseX:=MouseX; LastMouseY:=MouseY; LastBtn:=MouseBtn;
  End Else If AboutVisible Then Begin
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then
    HandleAboutClick(MouseX,MouseY);
   LastMouseX:=MouseX; LastMouseY:=MouseY; LastBtn:=MouseBtn;
  End Else If PrefsVisible Then Begin
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then
    Prefs_HandleClick(MouseX,MouseY);
   LastMouseX:=MouseX; LastMouseY:=MouseY; LastBtn:=MouseBtn;
  End Else If RulesVisible Then Begin
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then Begin
    Rules_HandleClick(MouseX,MouseY); DrawInterface;
   End;
   LastMouseX:=MouseX; LastMouseY:=MouseY; LastBtn:=MouseBtn;
  End Else If ColumnsDialogVisible Then Begin
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then
    HandleColumnsDialogClick(MouseX,MouseY);
   LastMouseX:=MouseX; LastMouseY:=MouseY; LastBtn:=MouseBtn;
  End Else If SortDialogVisible Then Begin
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then
    HandleSortDialogClick(MouseX,MouseY);
   LastMouseX:=MouseX; LastMouseY:=MouseY; LastBtn:=MouseBtn;
  End Else If FileOpenVisible Then Begin
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then
    HandleOpenFileClick(MouseX,MouseY);
   LastMouseX:=MouseX; LastMouseY:=MouseY; LastBtn:=MouseBtn;
  End Else If AccountDialogVisible Then Begin
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then
    HandleAccountDialogClick(MouseX,MouseY);
   LastMouseX:=MouseX; LastMouseY:=MouseY; LastBtn:=MouseBtn;
  End Else If ComposerVisible Then Begin
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then
    HandleComposerClick(MouseX, MouseY);
   LastMouseX := MouseX;
   LastMouseY := MouseY;
   LastBtn := MouseBtn;
  End Else If CalendarVisible And (ActiveMenu<0) And
     (MouseX>=SCREEN_WIDTH-CalendarPaneWidth) And (MouseY>Layout.ToolBarRect.Y2) And
     (MouseY<Layout.StatusBarRect.Y1) Then Begin
   If RibbonMode And (RibbonHover>=0) Then Begin RibbonHover:=-1; DrawToolBar; End;
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then CalendarClick(MouseX,MouseY);
   LastMouseX:=MouseX; LastMouseY:=MouseY; LastBtn:=MouseBtn;
  End Else Begin
   If RibbonMode And RibbonKeyboardActive And
      (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then Begin
    RibbonKeyboardActive:=False; RibbonFocus:=-1; DrawMenuBar; DrawToolBar;
   End;
   If CalendarVisible And CalendarHasFocus And (ActiveMenu<0) And
      (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then Begin
    CalendarHasFocus:=False; DrawInterface;
   End;
   { Mise a jour du survol des menus (seulement si la souris a bouge) }
   If (ActiveMenu >= 0) And
      ((MouseX <> LastMouseX) Or (MouseY <> LastMouseY)) Then
    UpdateMenuHover;

   { Mise a jour du survol du menu contextuel (seulement si la souris a bouge) }
   If ContextMenuVisible And
      ((MouseX <> LastMouseX) Or (MouseY <> LastMouseY)) Then Begin
    HoveredContextItem := GetContextMenuItemAtPoint(MouseX, MouseY);
    HideMouse;
    DrawContextMenu;
    ShowMouse;
   End;

   { Mise a jour du survol des boutons de barre d'outils }
   InToolbar := (MouseY >= Layout.ToolBarRect.Y1) And
                (MouseY <= Layout.ToolBarRect.Y2);
   InFolderPane := (MouseX >= Layout.FolderPaneRect.X1) And
                   (MouseX <= Layout.FolderPaneRect.X2) And
                   (MouseY >= Layout.FolderPaneRect.Y1 + 28) And
                   (MouseY <= Layout.FolderPaneRect.Y2);
   InMessageListHeader := (MouseX >= Layout.MessageListRect.X1) And
                          (MouseX <= Layout.MessageListRect.X2) And
                          (MouseY >= Layout.MessageListRect.Y1) And
                          (MouseY <= Layout.MessageListRect.Y1 + COLUMN_HEADER_HEIGHT);
   InMessageList := (MouseX >= Layout.MessageListRect.X1) And
                    (MouseX <= Layout.MessageListRect.X2) And
                    (MouseY >= Layout.MessageListRect.Y1 + COLUMN_HEADER_HEIGHT) And
                    (MouseY <= Layout.MessageListRect.Y2);

   If RibbonMode And Not InToolbar And (RibbonHover>=0) Then Begin
    RibbonHover:=-1; DrawToolBar;
   End;
   If (ActiveMenu < 0) And InToolbar Then
    UpdateToolbarHover
   Else If HoveredToolButton >= 0 Then Begin
    { Reinitialiser quand on quitte la barre d'outils }
    ToolButtons[HoveredToolButton].State := tbsNormal;
    HoveredToolButton := -1;
    If TooltipVisible Then HideTooltip;
    HideMouse;
    DrawToolBar;
    ShowMouse;
   End;

   { Mise a jour du survol de l'arbre de dossiers }
   If (ActiveMenu < 0) And (Not InToolbar) And InFolderPane Then
    UpdateFolderHover
   Else If HoveredFolder >= 0 Then Begin
    HoveredFolder := -1;
    HideMouse;
    DrawFolderPane;
    ShowMouse;
   End;

   { Cacher l'infobulle si la souris bouge trop }
   If TooltipVisible And
      ((Abs(MouseX - LastMouseX) > 5) Or (Abs(MouseY - LastMouseY) > 5)) Then Begin
    HideTooltip;
    TooltipStartTime := GetTickCount;
   End;

   LastMouseX := MouseX;
   LastMouseY := MouseY;

   { Detection des evenements souris avances }
   MouseEvent := DetectMouseEvent(LastBtn, MouseBtn, MouseX, MouseY);

   Case MouseEvent Of
    meLeftClick: Begin
     { Clic simple traite lors de l'appui du bouton }
    End;
    meRightClick: Begin
     { Fermer le menu contextuel si visible }
     If ContextMenuVisible Then Begin
      HideContextMenu;
      HideMouse;
      DrawMessageList;
      ShowMouse;
     End
     { Fermer le menu si ouvert }
     Else If ActiveMenu >= 0 Then
      CloseDropdownMenu
     { Clic droit sur la liste des messages }
     Else If InMessageList Then Begin
      ClickedMsg := GetMessageAtPoint(MouseX, MouseY);
      If ClickedMsg >= 0 Then Begin
       { Selectionner le message si pas deja selectionne }
       If Not Messages^[ClickedMsg].IsSelected Then Begin
        DeselectAllMessages;
        Messages^[ClickedMsg].IsSelected := True;
        SelectedMessage := ClickedMsg;
       End;
       ShowContextMenu(MouseX, MouseY);
       HideMouse;
       DrawMessageList;
       ShowMouse;
      End;
     End
     Else
      HandleRightClick;
    End;
    meLeftDoubleClick: Begin
     HandleDoubleClick;
    End;
    meRightDoubleClick: Begin
     { Double-clic droit: pas d'action specifique }
    End;
    meWheelUp: Begin
     HandleMouseWheel(1);
    End;
    meWheelDown: Begin
     HandleMouseWheel(-1);
    End;
   End;

   { Detection du clic gauche (bouton enfonce) }
   If (MouseBtn And MOUSE_LEFT <> 0) And (LastBtn And MOUSE_LEFT = 0) Then Begin
    { Gerer les clics dans le compositeur de messages (TODO 12) }
    If ComposerVisible Then Begin
     HandleComposerClick(MouseX, MouseY);
    End
    { Gerer les clics dans la boite de dialogue des comptes }
    Else If AccountDialogVisible Then Begin
     HandleAccountDialogClick(MouseX, MouseY);
    End
    { Fermer le menu contextuel si clic ailleurs }
    Else If ContextMenuVisible Then Begin
     ClickedMsg := GetContextMenuItemAtPoint(MouseX, MouseY);
     If ClickedMsg >= 0 Then Begin
      { Executer la commande du menu }
      { TODO: Implementer les actions des commandes }
     End;
     HideContextMenu;
     HideMouse;
     DrawMessageList;
     ShowMouse;
    End
    { Verifier d'abord si c'est un clic sur la barre d'outils }
    Else If InToolbar And (ActiveMenu < 0) Then
     HandleToolbarClick
    { Verifier si c'est un clic sur l'arbre de dossiers }
    Else If InFolderPane And (ActiveMenu < 0) Then
     HandleFolderClick(MouseX, MouseY)
    { Verifier si c'est un clic sur l'en-tete de colonne }
    Else If InMessageListHeader And (ActiveMenu < 0) Then Begin
     ClickedCol := GetColumnAtPoint(MouseX);
     If ClickedCol >= 0 Then Begin
      HandleColumnHeaderClick(ClickedCol);
      HideMouse;
      DrawMessageList;
      ShowMouse;
     End;
    End
    { Verifier si c'est un clic sur un message }
    Else If InMessageList And (ActiveMenu < 0) Then Begin
     ClickedMsg := GetMessageAtPoint(MouseX, MouseY);
     If ClickedMsg >= 0 Then Begin
      HandleMessageClick(ClickedMsg);
      HideMouse;
      DrawMessageList;
      DrawPreviewPane;
      ShowMouse;
     End;
    End
    Else
     HandleMouseClick;
   End;

   { Detection du relachement du bouton gauche }
   If (MouseBtn And MOUSE_LEFT = 0) And (LastBtn And MOUSE_LEFT <> 0) Then Begin
    If (PressedToolButton >= 0) Or (RibbonMode And (RibbonPressed>=0)) Then
     HandleToolbarRelease
    Else
     HandleMouseRelease;
   End;

   { Gestion du glissement }
   If (MouseBtn And MOUSE_LEFT <> 0) And (DragState <> dsNone) Then Begin
    HandleMouseDrag;
   End;

   LastBtn := MouseBtn;

  End; { Evenements de la fenetre principale }

  { Verification des touches du clavier }
  If PmKeyPressed Then Begin
   Key := PmReadKey;
   IsExtendedKey := (Key = #0) Or (Key = #224);
   If IsExtendedKey Then Begin
    Key := PmReadKey;
    If Key = #107 Then Begin { Code etendu Alt+F4, y compris sous DOS. }
     Running := False;
     Break;
    End;
   End;
   If EventDialogVisible Then Begin EventKey(Key,IsExtendedKey); Continue; End;
   If AboutVisible Then Begin
    If Not IsExtendedKey Then HandleAboutKey(Key);
    Continue;
   End;
   If PrefsVisible Then Begin Prefs_HandleKey(Key,IsExtendedKey); Continue; End;
   If RulesVisible Then Begin
    Rules_HandleKey(Key,IsExtendedKey); Continue;
   End;
   If ColumnsDialogVisible Then Begin
    HandleColumnsDialogKey(Key,IsExtendedKey);
    Continue;
   End;
   If SortDialogVisible Then Begin
    HandleSortDialogKey(Key,IsExtendedKey);
    Continue;
   End;
   If FileOpenVisible Then Begin
    HandleOpenFileKey(Key,IsExtendedKey);
    Continue;
   End;
   If AccountDialogVisible Then Begin
    If Not IsExtendedKey Then HandleAccountDialogKeyPress(Key);
    Continue;
   End;
   If RibbonMode Then Begin
    ShortcutMenu:=-1;
    If IsExtendedKey Then ShortcutMenu:=MenuShortcutFromScan(Key);
    If ShortcutMenu>=0 Then Begin OpenMenuShortcut(ShortcutMenu); Continue; End;
    If IsExtendedKey And (Key=#68) Then Begin
     RibbonKeyboardActive:=Not RibbonKeyboardActive; RibbonFocus:=-1; DrawInterface; Continue;
    End;
    If RibbonKeyboardActive Then Begin RibbonKey(Key,IsExtendedKey); Continue; End;
   End;
   If CalendarVisible And CalendarHasFocus And (ActiveMenu<0) Then Begin
    ShortcutMenu:=-1;
    If IsExtendedKey Then ShortcutMenu:=MenuShortcutFromScan(Key);
    If ShortcutMenu>=0 Then OpenMenuShortcut(ShortcutMenu)
    Else CalendarKey(Key,IsExtendedKey);
    Continue;
   End;
   If (ActiveMenu < 0) And Not ComposerVisible And IsExtendedKey And OsListKey(Key) Then Continue;
   If (ActiveMenu < 0) And (Not ComposerVisible Or (IsExtendedKey And (Key >= #59) And (Key <= #68))) And
      OsAccel(Key, IsExtendedKey) Then Continue;
   If Not IsExtendedKey And (Key=#19) Then Begin { Ctrl+S }
    ExecuteMenuCommand(CMD_FILE_SAVEAS);
    Continue;
   End;
   If IsExtendedKey Then Begin
    ShortcutMenu := MenuShortcutFromScan(Key);
    If ShortcutMenu >= 0 Then Begin
     OpenMenuShortcut(ShortcutMenu);
     Continue;
    End;
    { Touches etendues (fleches, F1-F12, etc.) }
    If ActiveMenu >= 0 Then Begin
     Case Key Of
      #72: Begin { Fleche Haut }
       If Menus[ActiveMenu].ItemCount > 0 Then Begin
        If ActiveMenuItem < 0 Then
         ActiveMenuItem := Menus[ActiveMenu].ItemCount - 1
        Else Begin
         ActiveMenuItem := ActiveMenuItem - 1;
         { Sauter les separateurs }
         While (ActiveMenuItem >= 0) And
               Menus[ActiveMenu].Items[ActiveMenuItem].Separator Do
          Dec(ActiveMenuItem);
         If ActiveMenuItem < 0 Then Begin
          ActiveMenuItem := Menus[ActiveMenu].ItemCount - 1;
          While (ActiveMenuItem >= 0) And
                Menus[ActiveMenu].Items[ActiveMenuItem].Separator Do
           Dec(ActiveMenuItem);
         End;
        End;
        HideMouse;
        DrawDropdownMenu(ActiveMenu);
        ShowMouse;
       End;
      End;
      #80: Begin { Fleche Bas }
       If Menus[ActiveMenu].ItemCount > 0 Then Begin
        If ActiveMenuItem < 0 Then
         ActiveMenuItem := 0
        Else
         ActiveMenuItem := ActiveMenuItem + 1;
        { Sauter les separateurs }
        While (ActiveMenuItem < Menus[ActiveMenu].ItemCount) And
              Menus[ActiveMenu].Items[ActiveMenuItem].Separator Do
         Inc(ActiveMenuItem);
        If ActiveMenuItem >= Menus[ActiveMenu].ItemCount Then Begin
         ActiveMenuItem := 0;
         While (ActiveMenuItem < Menus[ActiveMenu].ItemCount) And
               Menus[ActiveMenu].Items[ActiveMenuItem].Separator Do
          Inc(ActiveMenuItem);
        End;
        HideMouse;
        DrawDropdownMenu(ActiveMenu);
        ShowMouse;
       End;
      End;
      #75: Begin { Fleche Gauche - menu precedent }
       ActiveMenu := ActiveMenu - 1;
       If ActiveMenu < 0 Then ActiveMenu := MenuCount - 1;
       ActiveMenuItem := -1;
       HideMouse;
       DrawInterface;
       DrawDropdownMenu(ActiveMenu);
       ShowMouse;
      End;
      #77: Begin { Fleche Droite - menu suivant }
       ActiveMenu := ActiveMenu + 1;
       If ActiveMenu >= MenuCount Then ActiveMenu := 0;
       ActiveMenuItem := -1;
       HideMouse;
       DrawInterface;
       DrawDropdownMenu(ActiveMenu);
       ShowMouse;
      End;
     End; { Case }
    End; { ActiveMenu >= 0 }
   End
   { Gerer les touches dans le compositeur de messages (TODO 12) }
   Else If ComposerVisible Then Begin
    HandleComposerKeyPress(Key);
   End
   Else If Key = #15 Then Begin { Ctrl+O }
    ExecuteMenuCommand(CMD_FILE_OPEN);
   End
   Else If Key = #27 Then Begin
    If TooltipVisible Then
     HideTooltip
    Else If ContextMenuVisible Then Begin
     HideContextMenu;
     HideMouse;
     DrawMessageList;
     ShowMouse;
    End
    Else If ActiveMenu >= 0 Then
     CloseDropdownMenu
    ;  { OS/2-0 : Echap ne ferme plus Outlink (Fichier - Quitter, Alt+F4) }
   End
   Else If Key = #13 Then Begin
    { Entree: executer l'element de menu selectionne }
    If (ActiveMenu >= 0) And (ActiveMenuItem >= 0) Then Begin
     If Menus[ActiveMenu].Items[ActiveMenuItem].Enabled Then
      ExecuteMenuCommand(Menus[ActiveMenu].Items[ActiveMenuItem].ItemID);
    End;
   End;
  End; { PmKeyPressed }

  { Petite pause pour ne pas saturer le CPU }
  PmDelay(10);
 End;
End;

{ ============================================================================
  PROGRAMME PRINCIPAL
  ============================================================================ }

{ Traiter l aide avant toute ouverture de fenetre ou lecture des comptes. }
Function CommandLineHelpRequested: Boolean;
Var I: Integer; Argument: TMailText;
Begin
 CommandLineHelpRequested := False;
 For I := 1 To ParamCount Do Begin
  Argument := MailUpper(ParamStr(I));
  If (Argument = '/?') Or (Argument = '-H') Or (Argument = '--HELP') Then Begin
   CommandLineHelpRequested := True;
   Exit;
  End;
 End;
End;

{ Les chemins relatifs sont interpretes depuis le repertoire courant. }
Function ParseAccountsOption: Boolean;
Var
 I: Integer;
 Argument, UpperArgument, FileName: TMailText;
 ErrorOutput: Text;
Begin
 ParseAccountsOption := False;
 CommandLineAccountsFile := '';
 CommandLineScript:=''; VBSStarted:=False;
 MaxScreen := False; RibbonMode:=False; RibbonTab:=4;
 RibbonKeyboardActive:=False; RibbonFocus:=-1; RibbonHover:=-1; RibbonPressed:=-1;
 I := 1;
 While I <= ParamCount Do Begin
  Argument := ParamStr(I);
  UpperArgument := MailUpper(Argument);
  If (UpperArgument='/CLASSICMENU') Or (UpperArgument='/RUBANMENU') Then Begin
   RibbonMode:=UpperArgument='/RUBANMENU'; Inc(I); Continue;
  End;
  If Copy(UpperArgument,1,10)='/VBSCRIPT:' Then Begin
   FileName:=Copy(Argument,11,Length(Argument));
   If (FileName='') Or (Length(Argument)=255) Then Begin
    Assign(ErrorOutput,'');Rewrite(ErrorOutput);
    WriteLn(ErrorOutput,'Erreur: /VBSCRIPT exige un chemin .vbs valide de moins de 245 caracteres.');
    Close(ErrorOutput);Exit;
   End;
   CommandLineScript:=FileName;Inc(I);Continue;
  End;
  If UpperArgument = '-MAXSCREEN' Then Begin
   MaxScreen := True;
   Inc(I);
   Continue;
  End;
  FileName := '';
  If Copy(UpperArgument, 1, 10) = '/ACCOUNTS:' Then
   FileName := Copy(Argument, 11, Length(Argument))
  Else If Copy(UpperArgument, 1, 11) = '--ACCOUNTS=' Then
   FileName := Copy(Argument, 12, Length(Argument))
  Else If (UpperArgument = '/ACCOUNTS') Or (UpperArgument = '--ACCOUNTS') Then Begin
   Inc(I);
   If I <= ParamCount Then FileName := ParamStr(I);
  End
  Else Begin
   Inc(I);
   Continue;
  End;
  { Reserver quatre caracteres pour les fichiers temporaires .TMP et .BAK. }
  If (FileName = '') Or (Length(FileName) > 251) Or
     (Length(Argument) = 255) Then Begin
   Assign(ErrorOutput, '');
   Rewrite(ErrorOutput);
   WriteLn(ErrorOutput, 'Erreur: /ACCOUNTS exige un chemin de 1 a 251 caracteres.');
   WriteLn(ErrorOutput, 'Exemple : OUTLINK /ACCOUNTS:"C:\Courriel\Mes comptes.ACC"');
   WriteLn(ErrorOutput, 'Utilisez OUTLINK /? pour afficher l aide.');
   Close(ErrorOutput);
   Exit;
  End;
  CommandLineAccountsFile := FileName;
  Inc(I);
 End;
 ParseAccountsOption := True;
End;

Procedure ShowCommandLineHelp;
Var HelpOutput: Text;
Begin
 { Un flux distinct conserve la sortie console, meme avec les unites Crt. }
 Assign(HelpOutput, '');
 Rewrite(HelpOutput);
 WriteLn(HelpOutput, 'OUTLINK - Cette commande permet de lancer le client de messagerie graphique.');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput, 'Syntaxe : OUTLINK [/CLASSICMENU | /RUBANMENU] [-maxscreen]');
 WriteLn(HelpOutput, '                  [/ACCOUNTS:<fichier>] [/VBSCRIPT:<fichier>] [/? | -h | --help]');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput, '  Sans option          Ouvre la fenetre d''Outlink (Presentation Manager).');
 WriteLn(HelpOutput, '  -h, --help           Affichent egalement cette aide.');
 WriteLn(HelpOutput, '  -maxscreen           Accepte pour compatibilite (la fenetre suit l''ecran).');
 WriteLn(HelpOutput, '  /?                   Affiche cette aide et quitte.');
 WriteLn(HelpOutput, '  /ACCOUNTS:<fichier>  Utilise ce fichier pour lire et sauvegarder les comptes.');
 WriteLn(HelpOutput, '  /ACCOUNTS <fichier> et --accounts <fichier> sont aussi acceptes.');
 WriteLn(HelpOutput, '      La forme --accounts=<fichier> est egalement acceptee.');
 WriteLn(HelpOutput, '  /CLASSICMENU         Menus classiques (par defaut).');
 WriteLn(HelpOutput, '  /RUBANMENU           Onglets et commandes en ruban.');
 WriteLn(HelpOutput, '      Si les deux sont specifies, le dernier parametre est utilise.');
 WriteLn(HelpOutput, '      Ruban : Alt+lettre ou F10, Tab/fleches, Enter et Esc.');
 WriteLn(HelpOutput, '  /VBSCRIPT:<fichier>  Execute un script VBScript Pascal au demarrage.');
 WriteLn(HelpOutput, '     Exemple : OUTLINK /VBSCRIPT:"C:\Scripts\Nouveau message.vbs"');
 WriteLn(HelpOutput, '     Script : Outlook.OpenMenu "Outils" ou Outlook.ShowDialog "Options"');
 WriteLn(HelpOutput, '     Set mail = Outlook.CreateItem(0) : To, Subject, Body, From puis mail.Display');
 WriteLn(HelpOutput, '     Sous-ensemble VBScript : aucun moteur COM, aucun envoi implicite.');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput, 'Exemple : OUTLINK /ACCOUNTS:"C:\Courriel\Mes comptes.ACC"');
 WriteLn(HelpOutput, 'Les chemins relatifs partent du repertoire courant.');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput, 'Ouvrir un courriel .eml : menu Fichier / Ouvrir ou Ctrl+O.');
 WriteLn(HelpOutput, 'Enregistrer sous : menu Fichier / Enregistrer sous ou Ctrl+S.');
 WriteLn(HelpOutput, 'Configurer les comptes : menu Outils / Comptes.');
 WriteLn(HelpOutput, 'Recevoir les courriels : selectionner la boite du compte,');
 WriteLn(HelpOutput, 'puis cliquer sur Envoyer/Recevoir (IMAP ou POP3).');
 WriteLn(HelpOutput, 'Envoyer un message : nouveau message, puis Envoyer (SMTP).');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput, 'Par defaut, les comptes sont conserves dans OUTLINK.ACC,');
 WriteLn(HelpOutput, 'dans le repertoire de l executable.');
 Close(HelpOutput);
End;

BEGIN
 If CommandLineHelpRequested Then Begin
  ShowCommandLineHelp;
  Halt(0);
 End;
 If Not ParseAccountsOption Then Halt(1);

 { Initialisation du mode graphique }
 OsOpenWindow;
 OlHeapInit;
 InitializeGraphics;
 BusyGraphicsReady:=True;

 { Verification de la souris }
 If Not MouseDriverFound Then Begin
  GCloseGraph;
  WriteLn('Erreur: Pilote souris non trouve!');
  WriteLn('Veuillez charger un pilote souris (MOUSE.COM ou equivalent).');
  Halt(1);
 End;

 { Initialisation de la disposition par defaut }
 Layout.FolderPaneWidth := 160;
 Layout.PreviewPaneHeight := 150;

 { Calcul initial de la disposition }
 CalculateLayout;

 { Initialisation des menus deroulants (et barre de menus de PM) }
 InitializeMenus;
 OsSyncMenu;

 { Initialisation de la barre d'outils }
 InitializeToolbar;

 { Charger les comptes avant de construire leurs dossiers. }
 InitializeAccountManager;

 { Initialisation de l'arbre de dossiers }
 InitializeFolderTree;

 { Initialisation de la liste des messages }
 InitializeMessageList;



 { Initialisation du compositeur de messages (TODO 12) }
 InitializeComposer;

 { Initialisation du gestionnaire de pieces jointes (TODO 13) }
 InitAttachmentManager;

 { Initialisation du moteur de rendu HTML (TODO 14) }
 HTML_Init;

 { Initialisation du decodeur MIME (TODO 15) }
 MIME_Init;

 { Initialisation du carnet d'adresses (TODO 16) }
 AB_Init;
 AB_AddDemoContacts;

 { Initialisation du systeme de regles (TODO 17) }
 Rules_Init;
 Rules_Load;
 EventInit;

 { Initialisation de la recherche avancee (TODO 18) }
 Search_Init;

 { Initialisation du systeme de signatures (TODO 19) }
 Sig_Init;
 Sig_AddDemoSignatures;

 { Initialisation du systeme de notifications (TODO 20) }
 Notif_Init;
 Notif_AddDemoSettings;

 { Initialisation du systeme d'impression (TODO 21) }
 Print_Init;

 { Initialisation du systeme de sauvegarde (TODO 22) }
 Backup_Init;

 { Initialisation du systeme de preferences (TODO 23) }
 Prefs_Init;

 { Initialisation du mode hors ligne (TODO 24) }
 Offline_Init;
 { Les anciens caches de demonstration ne constituent pas une source serveur. }
 { La boite est chargee explicitement via Envoyer/Recevoir. }

 { Initialisation du support multi-langue (TODO 25) }
 Lang_Init;

 { Affichage de l'interface }
 ShowMouse;
 DrawInterface;

 If UserPrefs.General.CheckMailOnStart And Not UserPrefs.Connection.OfflineMode And
    (EmailAccountCount>0) Then Begin ReceiveMail; DrawInterface; End;

 { Boucle principale }
 MainEventLoop;

 { Sauvegarde du cache avant fermeture }
 Offline_SaveCache;
 Offline_SaveQueue;

 MailClose(IMAPWire); MailClose(POP3Wire); MailClose(SMTPWire);
 

 { Fermeture du mode graphique }
 BusyGraphicsReady:=False;
 HideMouse;
 GCloseGraph;
 OsCloseWindow;
END.
