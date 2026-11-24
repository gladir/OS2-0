<p align="center">
  <img src="IMAGE/LOGO_OS2ZERO.png" width="640" alt="OS/2 Zero (clone)">
</p>

<h1 align="center">OS2-0 (OS/2 Zero)</h1>

<p align="center"><b>Un clone d'OS/2 Warp 3 écrit entièrement en Pascal : du secteur d'amorce au Workplace Shell.</b></p>

OS2-0 est un système d'exploitation 32 bits qui reproduit OS/2 Warp 3 : un noyau multitâche protégé, les bibliothèques de l'API d'OS/2 (DOSCALLS, VIOCALLS, KBDCALLS, MOUCALLS, PMWIN, PMGPI, PMMERGE et une trentaine d'autres DLL, IFS compris), Presentation Manager et un bureau Workplace Shell avec ses dossiers d'objets, son LaunchPad et ses carnets de paramètres. Tout est écrit en Pascal, plus de 240 000 lignes, et compilé par **OS2PC**, le compilateur du projet, qui produit le secteur d'amorce, le chargeur, le noyau, les DLL et les programmes. OS2PC se compile aussi lui-même : OS2-0 peut donc reconstruire ses propres programmes avec Pascal Developer, son environnement de développement.

OS2-0 démarre d'un CD-ROM ou d'un disque dur, dans QEMU, VirtualBox (y compris au-dessus de Hyper-V) ou VMware.

<table>
	<tr>
		<td align="center"><img src="IMAGE/PMSHELL.png" width="400" alt="Le bureau Workplace Shell"><br><i>Le bureau (Workplace Shell) et ses dossiers d'objets</i></td>
		<td align="center"><img src="IMAGE/EXPLORATEUR.png" width="400" alt="Explorateur OS2-Zero"><br><i>Explorateur OS2-Zero, un explorateur à deux volets</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/WEB_GLADIR.png" width="400" alt="Navigateur Web"><br><i>Navigateur Web : HTML, CSS, JavaScript, HTTPS (TLS 1.3)</i></td>
		<td align="center"><img src="IMAGE/PASDEV.png" width="400" alt="Pascal Developer"><br><i>Pascal Developer : compiler et exécuter dans OS/2-0</i></td>
	</tr>
</table>

<h2>Ce qu'OS2-0 sait faire</h2>

<ul>
	<li><b>Noyau 32 bits</b> (OS2KRNL) : mode protégé, pagination, tâches préemptives, sessions plein écran et fenêtrées, chargeur de programmes et de DLL 32 bits (PE et LX), programmes 16 bits d'OS/2 1.x (NE) et machine virtuelle DOS en mode V86 (Turbo Pascal 7, BGI, DPMI).</li>
	<li><b>Systèmes de fichiers</b> : HPFS par défaut, NTFS en lecture, écriture et formatage pour partager ses fichiers avec Windows et Linux, FAT12 sur disquette, ISO 9660 sur CD-ROM, disque virtuel en mémoire ; pilotes IFS chargés par <code>IFS=</code> de CONFIG.SYS.</li>
	<li><b>Presentation Manager et Workplace Shell</b> : fenêtres, menus, contrôles, GPI, presse-papiers, glisser-déposer, raccourcis, modèles, LaunchPad, carnets Système, Souris, Pays et Langue ; de 640 × 480 en 16 couleurs (VGA) à 1024 × 768 en 16 millions de couleurs (VESA).</li>
	<li><b>Applications</b> : Explorateur OS2-Zero, Calculatrice, Paint (dessin bitmap), WorDium (traitement de texte : DOCX, PDF, GAT du MonsterBook, correcteur d'orthographe), Excelsior (tableur : XLC, XLS, XLSX, formules, graphiques), Outlink (courrier IMAP, POP3 et SMTP), Navigateur Web, Gestionnaire des tâches, Gestionnaire de périphériques, Audio numérique, Lecteur MP3, Notator for OS2-Zero, Essai OpenGL (OPENGL.DLL, OpenGL 1.1), Client FTP (FTP et SFTP), Client SSH (terminal xterm, SFTP, macros) et Connexion Bureau à distance (RDP vers Windows Server, TLS et NLA) du dossier Outils réseau, Pascal Developer, Astromancie (interprétation de l'astrologie) et Onirologie (interprétation des rêves) du dossier Loisirs, Astronomie, Simulateur de planète, Anatomie 3D du système circulatoire, Table des éléments et Dessin de chimie du dossier Science, Maximilien CRM, Sample Accounting, Acrodoc (PDF), News Master, PresentPoint et Bloc-notes du dossier Productivité, OS2-Zero Debugger (débogueur graphique dans l'esprit de Turbo Debugger), Client GitHub et Client SVN du dossier Developer Kit (aussi dans Outils réseau), Serveur Web (HTTP, HTTPS, PSP et ASP, console dans le style d'IIS) du dossier Outils réseau, jeux (Solitaire Klondike, Échecs, Mahjongg, Sudoku, Othello, TileMan, Hex 2048, Backgammon, Poker, Billard, Checkers, Yahtzee, Bataille navale, Puissance 4, Soko-Ban, Baccarat, Tours de Hanoï, Baby, 421, Mille-pattes, Astéroïde, Badugi, Tic-Tac-Toe, Baseball, Excavateur, Machine à boule, Barbu, Casse-Brique, Bataille, Invasion de l'espace, FreeCell, Commandement des missiles, L25, Bubble Shooter, BlackJack, Blox, Golf, Grenouille, Bonhomme pendu, Lights, Alunissage, Boston, Cannonball, Bingo, Craps, Roulette, Xiangqi, Le Plombier, Tic-Tac-Toe 3D, Patience), fenêtres OS/2 et DOS, les commandes d'OS/2 (CMD.EXE, CHKDSK, FORMAT, XCOPY, MODE, TREE…).</li>
	<li><b>Matériel</b> : disques IDE et ATAPI, lecteur de disquettes, cartes son (Sound Blaster, AC'97, AudioPCI), réseau (Intel PRO/1000, AMD PCnet) avec pile TCP/IP, DHCP, DNS et TLS ; outils invités de VirtualBox et de VMware (souris absolue, écran redimensionnable).</li>
	<li><b>Virtualisation</b> : machines virtuelles de VirtualBox (.vbox, VHD, VDI) exécutées directement sur le processeur par <b>AMD-V</b> (SVM et tables imbriquées NPT), <b>Intel VT-x</b> (VMX, EPT, invité sans restriction) ou, à défaut, le <b>mode virtuel 8086</b> du 80386 ; MS-DOS 6.22 y démarre ; installation de MSDOS-0, UNIX-0, OS2-Zero et Pasdows95 à partir de leur image ISO téléchargée de GitHub (CD-ROM El Torito, IDE ATA/ATAPI, VGA planaire émulé).</li>
	<li><b>Installation</b> graphique dans le style de Warp 3, sur une partition HPFS ou NTFS, en six langues.</li>
</ul>

<h2>Essayer OS2-0</h2>

Construire les images (Free Pascal) puis démarrer le CD-ROM dans QEMU :

<pre>KERNEL/BUILD.sh
qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d</pre>

Installer sur un disque dur, puis démarrer depuis le disque :

<pre>qemu-img create -f raw disque.img 300M
qemu-system-i386 -m 64 -cdrom IMAGE/OS2INST.ISO -hda disque.img -boot d
qemu-system-i386 -m 64 -hda disque.img</pre>

Sous Windows, <code>KERNEL\BUILD.BAT</code> fait la même construction. La documentation complète d'OS2-0 est dans <a href="IMAGE/LISEZMOI.TXT">IMAGE/LISEZMOI.TXT</a>, également copiée sur le CD-ROM.

<h2>Liste des fichiers</h2>

Voici la liste des différents fichiers proposés dans OS2-0 :

<table>
		<tr>
			<th>Nom</th>
			<th>Description</th>	
		</tr>
		<tr>
		 	<td><b>APPEND.PAS</b></td>
			<td>Cette commande permet d'ouvrir des fichiers quelconque se trouvant dans les répertoires spécifiés comme s'il s'agissait du répertoire courant.</td>
		</tr>
		<tr>
			<td><b>ASSIGN.PAS</b></td>
			<td>Cette commande permet de créer un disque virtuel à partir d'un autre disque.</td>
		</tr>
		<tr>
			<td><b>ATTRIB.PAS</b></td>
			<td>Cette commande permet de demander ou de changer les attributs d'un fichier.</td>
		</tr>
		<tr>
			<td><b>BROWSER.PAS</b></td>
			<td>Navigateur Web de Presentation Manager avec l'apparence d'OS/2 Warp 3 (adapté du BROWSER.PAS de DEV-COOLS) : HTML, CSS, JavaScript, images GIF, PNG, JPEG et BMP, code source, codes QR, menu contextuel et outils de développement F12 (Inspecteur, Débogueur, Éditeur de style, Console, Réseau).</td>
		</tr>
		<tr>
			<td><b>CALC.PAS</b></td>
			<td>Calculatrice de Presentation Manager (bureau → Productivité), portée de celle de Pasdows 95 vers l'API d'OS/2 (PMWIN, PMGPI) et l'apparence de Warp 3 : mode Standard, mémoire, presse-papiers de PM.</td>
		</tr>
		<tr>
			<td><b>CHKDSK.PAS</b></td>
			<td>Cette commande permet de vérifier le disque. Cette commande est inspiré du DOS.</td>
		</tr>		
		<tr>
			<td><b>CMD.PAS</b></td>
			<td>Cette commande permet de lancer l'interpréteur de commande OS/2. Il s'agit d'un équivalent du CMD de OS/2.</td>
		</tr>  
		<tr>
			<td><b>COMMAND.PAS</b></td>
			<td>Logiciel clone d'un <i>COMMAND.COM</i> du système d'exploitation <a href="https://www.gladir.com/OS/DOS/intro.htm"><i>DOS</i></a>.</td>
		</tr>
		<tr>
			<td><b>COMP.PAS</b></td>
			<td>Cette commande permet de comparer deux fichiers. Cette commande est un equivalent du <a href="https://www.gladir.com/OS/PCDOS/intro.htm">PC-DOS</a> ou <a href="https://www.gladir.com/OS/MSDOS/intro.htm">MS-DOS</a>.</td>
		</tr>
		<tr>
			<td><b>CURL.PAS</b></td>
			<td>Cette commande transfère une URL (<b>http://</b> et <b>https://</b>), comme la commande curl de Windows 10 : -o, -O, -I, -i, -X, -d, -H, -A, -L, -s, -v, -f, -x (proxy, ou <code>SET HTTPS_PROXY</code>/<code>HTTP_PROXY</code>). Elle est portée de Pasdows 95 : WININET y est remplacé par TCPIP32.DLL et TLS32.DLL (HTTP/1.1, corps « chunked », tunnel CONNECT).</td>
		</tr>
		<tr>
			 <td><b>DEBUG.PAS</b></td>
			 <td>Cette commande permet de deboguer un programme.</td>
		</tr>
		<tr>
			<td><b>DISKCOMP.PAS</b></td>
			<td>Cette commande permet de comparer des disquettes ou des images.</td>
		</tr>		
		<tr>
		    	<td><b>DISKCOPY.PAS</b></td>
		    	<td>Cette commande permet de copier des disquettes ou des images.</td>
		</tr>	
		<tr>
			<td><b>DOSKEY.PAS</b></td>
			<td>Cette commande permet de charger le programme DOSKEY.</td>
		</tr>
		<tr>
			<td><b>EDLIN.PAS</b></td>
			<td>Cette commande permet de lancer l'éditeur en ligne de commande.</td>
		</tr>
		<tr>
			<td><b>EXE2BIN.PAS</b></td>
			<td>Cette commande permet de convertir un fichier EXE en binaire (COM).</td>
		</tr>
		<tr>
			<td><b>EXPLORER.PAS</b></td>
			<td>Explorateur OS2-Zero : explorateur de fichiers à deux volets dans le style de Windows 95 (arbre des dossiers, Grandes icônes ou Détails, barre d'état, Connecter un lecteur réseau), porté de l'Explorateur Pasdows ; application de Presentation Manager indépendante (bureau → Productivité, menu contextuel du bureau).</td>
		</tr>
		<tr>
			<td><b>FIND.PAS</b></td>
			<td>Cette commande permet de rechercher une chaine de caractères dans des fichiers. Cette commande est un équivalent du DOS.</td>
		</tr>
		<tr>
			<td><b>FORMAT.PAS</b></td>
			<td>Cette commande permet de formater un unite de disquette.</td>
		</tr>
		<tr>
			<td><b>GRAFTABL.PAS</b></td>
			<td>Cette commande permet d'effectuer le chargement en mémoire conventionnelle d'une table de police de caractères pour les modes graphiques.</td>
		</tr>
		<tr>
			<td><b>IPCONFIG.PAS</b></td>
			<td>Cette commande affiche la configuration IP de l'ordinateur, comme IPCONFIG de Windows : adresse, masque et passerelle de lan0 ; <code>/ALL</code> ajoute le nom de l'hôte, la carte, l'adresse physique, le DHCP (serveur, bail) et le DNS ; <code>/RENEW</code> refait la demande DHCP. Elle est portée de Pasdows 95 : IPHLPAPI y est remplacé par TCPIP32.DLL (TCPIPINFO).</td>
		</tr>
		<tr>
			<td><b>LABEL.PAS</b></td>
			<td>Cette commande permet de changer le nom d'un volume.</td>
		</tr>
		<tr>
			<td><b>MEM.PAS</b></td>
			<td>Cette commande permet d'afficher les informations sur la mémoire. Cette commande est un clone de la commande MS-DOS ou PC-DOS.</td>
		</tr>
		<tr>
			<td><b>MODE.PAS</b></td>
			<td>Cette commande permet d'effectuer la gestion des paramètres d'un périphérique.</td>
		</tr>
		<tr>
			<td><b>MORE.PAS</b></td>
			<td>Cette commande permet de recevoir l'entrée puis l'affichage sur un périphérique un écran à la fois.</td>
    		</tr>	
    		<tr>
			<td><b>MOVE.PAS</td>
			<td>Cette commande permet de déplacer un fichier.</td>
		</tr>
		<tr>
			<td><b>OUTLINK.PAS</b></td>
			<td>Outlink : client de messagerie dans l'esprit d'Outlook, porté de <code>OUTLOOK.PAS</code> du dépôt OFFICE-0 vers Presentation Manager (bureau → Productivité) ; réception IMAP et POP3, envoi SMTP, TLS et STARTTLS, par les sockets de TCPIP32.DLL et TLS32.DLL.</td>
		</tr>
		<tr>
			<td><b>WORDIUM.PAS</b></td>
			<td>WorDium : traitement de texte porté de <code>WORD.PAS</code> du dépôt OFFICE-0 vers Presentation Manager (bureau → Productivité) ; formats WPD, DOCX, DOC, PDF et GAT du MonsterBook, correcteur d'orthographe en cinq langues, impression par le tampon d'impression d'OS/2.</td>
		</tr>
		<tr>
			<td><b>EXCELSIO.PAS</b></td>
			<td>Excelsior : tableur porté de <code>EXCEL.PAS</code> du dépôt OFFICE-0 vers Presentation Manager (bureau → Productivité) ; 16 feuilles de 4096 lignes sur 256 colonnes, formules, graphiques, formats XLC, XLS (BIFF8) et XLSX.</td>
		</tr>
		<tr>
			<td><b>APPS/PAINT.PAS</b></td>
			<td>Paint : programme de dessin bitmap dans l'esprit de Paint, porté de Pasdows 95 (CloneDRAW) vers Presentation Manager (bureau → Productivité).</td>
		</tr>
		<tr>
			<td><b>PASDEV.PAS</b></td>
			<td>Pascal Developer : environnement de développement intégré Pascal de Presentation Manager (dossier Developer Kit du bureau), dans l'esprit de Borland Pascal mais avec l'apparence d'OS/2 : fenêtres d'édition MDI à coloration syntaxique, compilation par OS2PC.EXE, exécution, boîte Information.</td>
		</tr>
		<tr>
			<td><b>GETSRC.PAS</b></td>
			<td>Télécharger le code source d'OS2-Zero (dossier Developer Kit du bureau) : copie le code source actuel d'OS/2-0 depuis GitHub dans C:\SOURCE\OS2-0\ (sans les données de Git), avec barre de progression ; Mettre à jour ne copie que les fichiers modifiés.</td>
		</tr>
		<tr>
			<td><b>APPS/OS2DBG.PAS</b></td>
			<td>OS2-Zero Debugger (dossier Developer Kit du bureau) : débogueur des programmes d'OS/2-0 dans l'esprit de Turbo Debugger, avec l'apparence de Presentation Manager : désassembleur x86 32 bits coloré, registres, mémoire, pile, points d'arrêt, pas à pas, exceptions.</td>
		</tr>
		<tr>
			<td><b>APPS/VIRTUAL.PAS</b></td>
			<td>Virtualisation (dossier Système OS/2 du bureau) : gestionnaire de machines virtuelles à la façon de VirtualBox, avec les menus et l'apparence d'OS/2 ; machines au format de VirtualBox (.vbox, disques VHD, VDI, IMG) exécutées directement sur le processeur par AMD-V, Intel VT-x ou le mode virtuel 8086 du 80386 (KrnVirt du noyau), menu Information de virtualisation ; type de système en liste déroulante, image ISO d'installation de MSDOS-0, UNIX-0, OS2-Zero ou Pasdows95 téléchargée de GitHub puis installée, CD-ROM El Torito, contrôleurs IDE ATA/ATAPI, modes VGA planaires émulés.</td>
		</tr>
		<tr>
			<td><b>APPS/GITCLI.PAS</b></td>
			<td>Client GitHub (dossiers Outils réseau et Developer Kit du bureau) : client Git et GitHub dans le genre de GitHub Desktop, celui de Pasdows 95 porté de l'API Win32 vers celle d'OS/2 (PMWIN, PMGPI, DOSCALLS, TCPIP32, TLS32) en un seul fichier source : Git écrit en Pascal (SHA-1, zlib, objets, packs, deltas, index, fusion à trois voies), cloner, récupérer, tirer et pousser en <b>http://</b>, <b>https://</b> et <b>git://</b>, branches, historique, différences, API de GitHub.com ; <code>GITCLI /TEST</code> vérifie le tout sur COM1.</td>
		</tr>
		<tr>
			<td><b>APPS/SVNCLI.PAS</b></td>
			<td>Client SVN (dossiers Outils réseau et Developer Kit du bureau) : client <b>Subversion</b> dans le genre du Client GitHub, celui de Pasdows 95 porté de l'API Win32 vers celle d'OS/2 (PMWIN, PMGPI, PMMERGE, DOSCALLS, TCPIP32, TLS32) en un seul fichier source : extraction, mise à jour avec fusion à trois voies, validation, annulation, svn:ignore, branches, historique et différences en couleurs, en <b>svn://</b> (CRAM-MD5), <b>http://</b> et <b>https://</b> (Apache et mod_dav_svn) ; <code>SVNCLI /TEST</code> vérifie le tout sur COM1.</td>
		</tr>
		<tr>
			<td><b>APPS/WEBSRV.PAS</b></td>
			<td>Serveur Web (dossier Outils réseau du bureau) : un seul fichier source pour le serveur (<code>WEBSRV /SERVICE</code> : HTTP/1.1, HTTPS en TLS 1.3, hôtes virtuels, pages <b>.psp</b> (Pascal Server Pages) et <b>.asp</b> (VBScript) compilées et exécutées dans le serveur) et sa console de Presentation Manager dans le style d'IIS (arbre des sites et des fonctionnalités, panneau qui suit l'arbre, volet Actions, menus déroulants) ; démarrage avec OS/2 par une ligne <code>RUN=</code> de CONFIG.SYS, désactivé par défaut.</td>
		</tr>
		<tr>
			<td><b>APPS/NOTEPAD.PAS</b></td>
			<td>Bloc-notes (dossier Productivité du bureau) : le Bloc-notes de Pasdows 95 porté de l'API Win32 vers celle d'OS/2 (PMWIN, DOSCALLS).</td>
		</tr>
		<tr>
			<td><b>REPLACE.PAS</b></td>
			<td>Cette commande permet de remplacer un fichier. Cette commande est un équivalent du DOS.</td>
		</tr>
		<tr>
			<td><b>SORT.PAS</b></td>
			<td>Cette commande permet de trier une fichier texte ASCII et de retourner le résultat. Cette commande est un équivalent de la commande du DOS.</td>
		</tr>
		<tr>
			<td><b>TASKMGR.PAS</b></td>
			<td>Gestionnaire des tâches de Presentation Manager : applications, processus, performances (processeur et mémoire), réseau et utilisateurs, dans le style du Gestionnaire des tâches de Windows XP avec l'apparence d'OS/2 Warp 3.</td>
		</tr>
		<tr>
			<td><b>TREE.PAS</b></td>
			<td>Cette commande permet d'afficher un arbre de répertoire.</td>
		</tr>
		<tr>
			<td><b>XCOPY.PAS</b></td>
			<td>Cette commande permet d'effectuer la copie étendue avec sous-répertoire de fichier(s) vers un nouvel emplacement.</td>
		</tr>
	</table>

<h2>Jeux (KLONDIKE.PAS, ECHECS.PAS, MAHJONGG.PAS, SUDOKU.PAS, OTHELLO.PAS, TILEMAN.PAS, HEX2048.PAS, BACKGAM.PAS, POKER.PAS, BILLARD.PAS, CHECKERS.PAS, YATHZEE.PAS, BATTLE.PAS, POWER4.PAS, SOKOBAN.PAS, BACCARAT.PAS, HANOIS.PAS, BABY.PAS, 421.PAS, CENTIPED.PAS, ASTEROID.PAS, BADUGI.PAS, TTT.PAS, BASEBALL.PAS, EXCAVAT.PAS, PINBALL.PAS, BARBU.PAS, BREAKOUT.PAS, BATAILLE.PAS, INVADERS.PAS, FREECELL.PAS, MISSILE.PAS, L25.PAS, BUBBLE.PAS, BLACKJAK.PAS, BLOX.PAS, GOLF.PAS, FROGGER.PAS, HANGMAN.PAS, LIGHTS.PAS, LUNAR.PAS, BOSTON.PAS, CANNONBA.PAS, BINGO.PAS, CRAPS.PAS, ROULETTE.PAS, XIANGQI.PAS, TTT3D.PAS, PATIENCE.PAS, PLOMBIER.PAS)</h2>

Comme OS/2 Warp 3, le bureau a un dossier <b>Jeux</b> avec cinquante jeux de Presentation Manager, écrits en Pascal et compilés par OS2PC. Ce sont des réalisations originales des jeux traditionnels (dessins vectoriels faits par les programmes, aucune image d'IBM). Ils s'exécutent dans la session de Presentation Manager, en même temps que le bureau ; le programme d'installation les copie si le composant « Jeux » est choisi (le dossier n'affiche que les jeux présents).

<img width="640" height="480" alt="OS/2-0 : le dossier Jeux du bureau" src="IMAGE/JEUX.png" />

<table>
	<tr><th>Jeu</th><th>Description</th></tr>
	<tr><td><b>Solitaire - Klondike</b> (KLONDIKE.EXE)</td><td>La patience Klondike : pioche, défausse, quatre fondations (de l'as au roi par couleur), sept colonnes (rouge et noir en alternance, un roi seul dans une colonne vide). Glisser une carte (et celles qui la recouvrent) ou cliquer la carte puis sa destination ; double clic : vers sa fondation ; une carte cachée se retourne d'un clic. Menus Partie (Nouvelle partie F2, Annuler Ctrl+Z, Terminer automatiquement), Options (tirer 1 ou 3 cartes), Aide. Score : fondation +10, défausse vers une colonne +5, carte retournée +5, fondation vers une colonne −15, pioche recyclée −100 (tirage de 1). Paramètre <code>/SEED:n</code> : donne reproductible.</td></tr>
	<tr><td><b>Échecs</b> (ECHECS.EXE)</td><td>Toutes les règles : roque (petit et grand), prise en passant, promotion, échec, mat, pat, règle des 50 coups, matériel insuffisant. L'ordinateur joue les noirs (ou les blancs, ou personne : Deux joueurs) : recherche alpha-bêta à 1, 2 ou 3 demi-coups selon le niveau (facile, moyen, difficile), puis recherche des prises ; évaluation par le matériel et la position des pièces. Cliquer une pièce marque ses cases d'arrivée ; dernier coup encadré ; liste des coups en notation française (R, D, T, F, C ; <code>O-O</code>, <code>+</code>, <code>#</code>) ; Ctrl+Z annule le coup du joueur et la réponse.</td></tr>
	<tr><td><b>Mahjongg Solitaire</b> (MAHJONGG.EXE)</td><td>144 tuiles en cinq étages selon la disposition de la tortue : cercles, bambous et caractères de 1 à 9, vents (E, S, O, N), dragons rouge, vert et blanc (4 de chaque), 4 fleurs et 4 saisons (deux fleurs ou deux saisons forment une paire). On retire les paires de tuiles libres (rien dessus, côté gauche ou droit dégagé). Chaque donne est faisable : elle est construite en vidant un plateau plein par paires de tuiles libres. Indice (I), Annuler (Ctrl+Z), Recommencer la partie, nombre de tuiles et de paires jouables, fin de partie détectée ; <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Sudoku</b> (SUDOKU.EXE)</td><td>Porté du prototype <code>SODOKU.PAS</code> du dépôt 7iles (Turbo Pascal et BGI, clavier seulement) vers Presentation Manager. Remplir la grille de 9 × 9 pour que chaque ligne, colonne et carré de 3 × 3 contienne une fois les chiffres de 1 à 9. Chaque grille est construite au hasard (solution complète par retour arrière, puis cases retirées par paires symétriques tant que la solution reste unique ; le prototype ne vérifiait pas les carrés) ; niveaux Facile, Moyen et Difficile (38, 30 et 25 chiffres donnés environ). Cliquer une case puis un chiffre du pavé, ou taper 1 à 9 ; bouton 2, Suppr ou Espace : effacer. Chiffres donnés sur fond gris, les vôtres en bleu, ceux en conflit en rouge, le même chiffre éclairé dans toute la grille. Menu Partie : nouvelle partie (F2), recommencer, annuler (Ctrl+Z), indice (I), vérifier (V : chiffres faux sur fond rouge), solution, niveau ; chronomètre dans la barre d'état ; <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Othello</b> (OTHELLO.EXE)</td><td>Porté du prototype <code>OTHELLO.PAS</code> du dépôt 7iles (Turbo Pascal et BGI, clavier seulement, écran de titre) vers Presentation Manager. Avoir le plus de pions de sa couleur à la fin : chaque coup doit encadrer en ligne droite au moins un pion adverse, et tous les pions encadrés sont retournés ; qui ne peut pas jouer passe son tour (automatiquement), la partie finit quand personne ne peut jouer. Contre l'ordinateur (vous jouez les noirs) ou à deux joueurs ; niveaux Facile (coup glouton avec du hasard, comme le prototype), Moyen (poids des cases et mobilité) et Difficile (recherche alpha-bêta sur quatre demi-coups). Cliquer une case, ou flèches et Entrée ; coups possibles marqués d'un point, dernier coup d'un carré rouge ; H : indices (nombre de pions retournés par chaque coup) ; Ctrl+Z annule jusqu'au dernier coup du joueur ; panneau des scores, menus Partie et Aide, barre d'état ; résultat en fin de partie. <code>/SEED:n</code> ; <code>/AUTO</code> : l'ordinateur joue les deux couleurs (démonstration).</td></tr>
	<tr><td><b>TileMan</b> (TILEMAN.EXE)</td><td>Porté du prototype <code>TILEMAN.PAS</code> du dépôt 7iles (Turbo Pascal et BGI, clavier seulement, écrans de titre et de fin) vers Presentation Manager. Conquête de terrain sur 35 × 25 cases : le disque jaune part de son territoire (tuiles bleues) et laisse une trace (cyan) en dehors ; en y revenant, la trace et toutes les zones fermées sans ennemi deviennent territoire (le prototype ne gardait que les zones entourées, sans toucher les murs). Les ennemis rouges rebondissent en diagonale sur les murs et le territoire ; s'ils touchent le joueur ou sa trace, ou si le joueur recoupe sa trace, une vie de moins (trois vies) et retour au point de sortie. Niveau terminé à 75 % du terrain (bonus) ; chaque niveau ajoute un ennemi et les accélère. Flèches, Espace (s'arrêter dans son territoire), P ou Pause ; vitesse lente, normale ou rapide ; panneau (pointage, niveau, vies, trace, barre de progression avec l'objectif) ; bandeaux de niveau, de pause et de fin. Dessin seulement de ce qui change (pas de scintillement) ; le jeu s'arrête de lui-même pendant les menus et les boîtes de message. <code>/SEED:n</code> ; <code>/AUTO</code> : pilote automatique (démonstration).</td></tr>
	<tr><td><b>Hex 2048</b> (HEX2048.EXE)</td><td>Porté du prototype <code>HEX2048.PAS</code> du dépôt 7iles vers Presentation Manager. Le 2048 sur une grille hexagonale de 19 cases (3-4-5-4-3) : glisser toutes les tuiles dans une des six directions ; deux tuiles égales qui se rencontrent fusionnent une fois par glissement, le pointage gagne leur somme, une tuile (2, ou 4 une fois sur dix) apparaît ; atteindre 2048 (continuer ensuite), fin quand plus rien ne glisse. Le prototype ne déplaçait chaque tuile que d'une case et ajoutait quatre tuiles par coup. Touches Q W E A S D (comme le prototype), 7 8 9 1 2 3 du pavé numérique, Début, Pg préc, Fin, Pg suiv, flèches haut et bas ; clic sur le plateau du côté où glisser, ou sur la rose des directions ; Ctrl+Z annule le dernier glissement ; tuiles en relief avec une couleur par valeur, nouvelle tuile qui apparaît en grandissant ; meilleur pointage de la séance. <code>/SEED:n</code> ; <code>/AUTO</code> : l'ordinateur joue seul.</td></tr>
	<tr><td><b>Backgammon</b> (BACKGAM.EXE)</td><td>Porté du prototype <code>BACKGAM.PAS</code> du dépôt 7iles (coups tapés par lettres de cases) vers Presentation Manager, avec les règles complètes que le prototype n'avait pas : barre et entrée, pions frappés, sortie des pions (avec un dé plus fort si aucun pion plus loin), obligation de jouer le plus de dés possible (ou le plus fort), doubles joués quatre fois, lancer d'ouverture, gammon et backgammon (2 et 3 points). Plateau en bois avec les numéros des cases, pions blancs (vous) et noirs (l'ordinateur), plateau de sortie, dés dessinés (grisés une fois joués). Lancer les dés (bouton, Espace ou clic sur le plateau), cliquer un pion blanc : ses cases d'arrivée sont marquées d'un point jaune ; Ctrl+Z remet les pions du tour ; les coups de l'ordinateur sont joués un à un, ses cases d'arrivée marquées en cyan. L'ordinateur Normal évalue toutes ses suites de coups (course, pions exposés aux coups directs et indirects, cases faites, barrages, pions sur la barre) ; Facile joue au hasard. Panneau : course (pips) et pions sortis de chacun, parties gagnées. <code>/SEED:n</code> ; <code>/AUTO</code> : l'ordinateur joue les deux couleurs.</td></tr>
	<tr><td><b>Poker</b> (POKER.EXE)</td><td>Porté du prototype <code>POKER.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Poker à cinq cartes (draw) contre l'ordinateur : chacun mise (10, 25, 50 ou 100 $ ; 50 $ comme le prototype) et reçoit cinq cartes ; on choisit les cartes à échanger (clic ou 1 à 5), puis Abattre, Relancer (doubler la mise : l'ordinateur suit ou se couche selon sa main) ou Se coucher. Mains nommées en français (« Paire de rois », « Full aux dames par les 3 »…) ; à combinaison égale, les hauteurs départagent (le prototype ne comparait que les combinaisons). L'ordinateur échange comme un joueur (garde ses paires, tire à la couleur ou à la quinte ouverte, sinon garde sa figure). Cartes dessinées comme celles du Solitaire, tapis vert, argent (1000 $ au départ), donnes gagnées ; menu Aide : règles et liste des combinaisons. <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Billard</b> (BILLARD.EXE)</td><td>Porté du prototype <code>BILLARD.PAS</code> du dépôt 7iles (visée aux flèches, écran de titre) vers Presentation Manager. Billard américain à 8 boules : après la casse, le premier qui empoche prend les pleines (1 à 7) ou les rayées (9 à 15) ; on rejoue tant qu'on empoche une de ses boules sans faute ; la 8 en dernier (trop tôt ou avec une faute : partie perdue) ; fautes : blanche empochée (remise sur son point), aucune boule touchée, première boule touchée qui n'est pas des siennes. Physique en virgule fixe : frottement du tapis, chocs élastiques entre boules, rebonds amortis sur les bandes, six poches. Visée à la souris (la queue suit le pointeur ; ligne de visée et boule fantôme sur la première boule touchée) ; maintenir le bouton dose la puissance (jauge), le relâcher tire ; ou flèches, Espace (puissance) et Entrée comme le prototype. Contre l'ordinateur (il vise la boule la mieux placée vers une poche par la méthode de la boule fantôme ; Facile ou Normal) ou à deux joueurs. La table est dessinée dans une image en mémoire de 256 couleurs, affichée par GpiDrawBits seulement là où les boules bougent : pas de scintillement. <code>/SEED:n</code> ; <code>/AUTO</code>.</td></tr>
	<tr><td><b>Checkers</b> (CHECKERS.EXE)</td><td>Porté du prototype <code>CHECKERS.PAS</code> du dépôt 7iles (deux curseurs au clavier, historique des coups) vers Presentation Manager. Dames anglaises sur les cases foncées : un pion avance d'une case en diagonale et prend en sautant (vers l'avant), en rafle tant qu'il peut ; prise obligatoire ; un pion qui atteint la dernière rangée devient dame (couronne) et va dans les quatre directions ; plus de pion ou de coup : partie perdue ; 40 coups chacun sans prise ni pion avancé : nulle (le prototype n'avait ni prise obligatoire, ni rafle, ni prise par les dames). Contre l'ordinateur (recherche alpha-bêta qui poursuit les prises au-delà de l'horizon ; Facile, Moyen, Difficile) ou à deux ; on choisit qui commence, comme le prototype. Clic sur un pion puis sur une case marquée d'un point (une rafle se joue sur sa case d'arrivée), ou flèches et Entrée ; dernier coup encadré ; liste des coups en notation du prototype (colonne et rangée, <code>x</code> pour une prise) ; Ctrl+Z. <code>/SEED:n</code> ; <code>/AUTO</code>.</td></tr>
	<tr><td><b>Yahtzee</b> (YATHZEE.EXE)</td><td>Porté du prototype <code>YATHZEE.PAS</code> du dépôt 7iles (mode texte, feuille de pointage en caractères semi-graphiques) vers Presentation Manager. Treize tours d'au plus trois lancers de cinq dés ; on garde des dés d'un clic (ou 1 à 5) entre les lancers, puis on clique une case libre de sa colonne, où les points possibles sont affichés en gris sur fond jaune. Section supérieure (as à six, prime de 35 à partir de 63 points), brelan, carré, full (25), petite suite (30), grande suite (40), Yahtzee (50, puis prime de 100 par Yahtzee de plus), chance. Seul (comme le prototype), contre l'ordinateur (il garde ses dés selon les cases libres et choisit la case qui rapporte le plus) ou à deux joueurs ; dés qui roulent ; meilleur pointage de la séance. <code>/SEED:n</code> ; <code>/AUTO</code>.</td></tr>
	<tr><td><b>Bataille navale</b> (BATTLE.EXE)</td><td>Jeu écrit pour OS/2-0 (sans prototype), le jeu classique de la bataille navale : chaque joueur place en secret sa flotte sur une grille de 10 × 10 (porte-avions 5 cases, cuirassé 4, croiseur 3, sous-marin 3, torpilleur 2), puis on tire chacun son tour sur une case de la grille adverse : dans l'eau (point blanc), touché (feu), touché-coulé ; le premier qui coule toute la flotte adverse gagne. Option tir en salve : autant de tirs par tour que de navires encore à flot. Chaque type de navire a sa silhouette : vue de dessus sur la grille (pont d'envol et îlot du porte-avions, trois tourelles du cuirassé, kiosque du sous-marin…) et de profil sur l'eau dans le panneau de placement et la liste de la flotte. Placement à la souris (le navire suit le pointeur, vert s'il tient, rouge sinon ; bouton 2 ou R : pivoter ; un clic sur un navire placé le reprend) ou au clavier, ou au hasard (A). Modes : humain contre l'ordinateur (par défaut), deux joueurs (un rideau cache la flotte de l'autre entre les tours) et ordinateur contre ordinateur. L'ordinateur Normal tire selon la densité des positions encore possibles des navires restants et achève les navires touchés ; Facile tire au hasard autour de ses coups au but. En cinq langues : français, anglais, espagnol, italien et allemand (menu Langue, qui refait les menus ; au départ la langue du système, <code>SET LANGUAGE=</code> de CONFIG.SYS, ou <code>/LANG:FR</code>, <code>EN</code>, <code>ES</code>, <code>IT</code>, <code>DE</code>). <code>/SEED:n</code> ; <code>/AUTO</code>.</td></tr>
	<tr><td><b>Puissance 4</b> (POWER4.EXE)</td><td>Porté du prototype <code>POWER4.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Aligner quatre jetons de sa couleur (horizontale, verticale ou diagonale) sur la grille de 7 colonnes et 6 rangées ; chaque jeton tombe au plus bas de la colonne choisie (chute animée) ; grille pleine : nulle ; l'alignement gagnant est marqué. Contre l'ordinateur (vous avez les rouges, comme le prototype ; l'ordinateur peut commencer) ou à deux joueurs. L'ordinateur cherche par alpha-bêta (Facile 2 demi-coups avec du hasard, Moyen 5, Difficile 7) en comptant les alignements encore possibles ; le prototype ne voyait que le coup gagnant immédiat. Clic sur une colonne (le jeton suit la souris au-dessus de la grille), flèches et Entrée, 1 à 7 ; Ctrl+Z annule jusqu'au dernier coup du joueur ; victoires et parties nulles comptées. <code>/SEED:n</code> ; <code>/AUTO</code>.</td></tr>
	<tr><td><b>Soko-Ban</b> (SOKOBAN.EXE)</td><td>Porté du prototype <code>SOKOBAN.PAS</code> du dépôt 7iles (1992, Turbo Pascal en mode texte) vers Presentation Manager, avec ses 85 étages repris tels quels. Pousser toutes les caisses sur les cibles : le magasinier pousse une caisse à la fois en marchant contre elle, il ne peut ni tirer ni pousser deux caisses. Murs de briques roses en relief, caisses en bois (vertes une fois rangées), cibles en losange, magasinier dessiné. Flèches pour marcher et pousser ; clic sur une case libre : le magasinier y va par le plus court chemin (sans pousser) ; clic sur une caisse voisine : la pousser. Annulation illimitée (Ctrl+Z ou Retour arrière), F10 ou Échap (recommencer), F8 et F9 (étage précédent et suivant, comme le prototype), choix de l'étage parmi les 85 (F2 ; étages réussis en vert), démonstration de l'étage 1 (F3, la solution du prototype) ; pas, poussées, caisses rangées, record de la séance. <code>/LEVEL:n</code> ; <code>/DEMO</code>.</td></tr>
	<tr><td><b>Baccarat</b> (BACCARAT.EXE)</td><td>Porté du prototype <code>BACCARAT.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager : tapis vert, mains du Joueur et du Banquier, cartes dessinées (comme le Poker) montrées une à une, trois cases de mise cliquables (Joueur 1 pour 1, Banquier 0,95 pour 1, Égalité 8 pour 1) avec le jeton de la mise, sabot de six jeux, panneau de l'argent (1000 $ au départ, comme le prototype) et historique des 18 derniers coups. Règle classique du tirage (naturel 8 ou 9, troisième carte du Joueur avec 0 à 5, tableau du Banquier) ; contrairement au prototype, le naturel est appliqué et un gain rend aussi la mise. 1, 2, 3 (case), + et - (mise), Espace (distribuer), donne rapide (menu). <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Tours de Hanoï</b> (HANOIS.EXE)</td><td>Porté du prototype <code>HANOIS.PAS</code> du dépôt 7iles (2011, mode texte) : socle et tiges de bois, disques de couleur en relief. Comme le prototype, la pile est sur la tige 2 et doit aller sur la tige 1 ou 3, sans poser un disque sur un plus petit (127 coups au moins pour 7 disques). Souris (cliquer une tige pour prendre son disque, puis une autre pour le poser) ou clavier (1, 2, 3 comme le « De : » et « à : » du prototype, flèches et Espace), annulation (Ctrl+Z), 3 à 8 disques (menu Disques), solution animée depuis la position courante (F3), record par nombre de disques. <code>/DISKS:n</code> ; <code>/SOLVE</code>.</td></tr>
	<tr><td><b>Baby</b> (BABY.EXE)</td><td>Porté du prototype <code>BABY.PAS</code> du dépôt 7iles (2024, Turbo Pascal et BGI) avec ses images (immeuble en feu, 26 positions du bébé, pompiers, ambulance) : des bébés sautent de l'immeuble en feu et les deux pompiers doivent les faire rebondir trois fois sur leur toile jusqu'à l'ambulance. Image en mémoire (GpiDrawBits, seuls les rectangles changés sont recopiés), ciel de nuit étoilé, flammes animées, chaussée ; 25 points par bébé sauvé, vagues de 26 bébés de plus en plus rapides, trois vies. Flèches (comme le prototype), A B C ou 1 2 3, souris, pause (P). <code>/SEED:n</code> ; <code>/AUTO</code> (pompiers automatiques).</td></tr>
	<tr><td><b>421</b> (421.EXE)</td><td>Porté du prototype <code>421.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) : piste de bois et de feutre, dés en relief qui roulent (le 1 rouge), 21 jetons par joueur, 11 manches. Trois lancers par manche en gardant des dés (clic ou 1 2 3, fond jaune) ; 421 (10 points), brelans (8), suites (6), sinon les as ; sur un 421 chaque autre joueur paie 2 jetons au gagnant, 1 sur un brelan ou une suite. Contre 1, 2 ou 3 ordinateurs (menu Options), qui s'arrêtent sur une combinaison. <code>/SEED:n</code> ; <code>/AUTO</code> ; <code>/OPP:n</code>.</td></tr>
	<tr><td><b>Mille-pattes</b> (CENTIPED.EXE)</td><td>Porté du prototype <code>CENTIPED.PAS</code> du dépôt 7iles (2024, mode texte de 40 × 23 caractères) vers Presentation Manager, en graphique : chaque caractère du prototype devient un carreau dessiné (jardin de nuit, bordure de pierres, champignons, mille-pattes avec tête et pattes, araignée, canon), dans une image en mémoire dont seuls les carreaux changés sont recopiés (GpiDrawBits). Les règles et les déplacements du prototype sont repris : un mille-pattes touché au milieu se coupe en deux et accélère, chaque anneau touché devient un champignon (violet), un champignon tient deux tirs, l'araignée invincible sème des champignons et détruit le canon ; pointage du prototype (50 au départ, −2 par tir, +10, +100). Un mille-pattes qui atteint la terre coûte une vie (le prototype terminait la partie). Flèches (ou 1 3, 4 6, 7 9 comme le prototype), Espace, souris (le canon suit la souris, clic pour tirer), trois vitesses (menu Options), pause. Bruitages joués par MDM.DLL (tir, champignon et anneau touchés, canon perdu, nouvelle vague ; menu Options, Son). <code>/SEED:n</code> ; <code>/AUTO</code> (canon automatique) ; <code>/NOSOUND</code>.</td></tr>
	<tr><td><b>Astéroïde</b> (ASTEROID.EXE)</td><td>Porté du prototype <code>ASTEROID.PAS</code> du dépôt 7iles (mode texte, vaisseau fixe au centre qui tourne et tire sur les astéroïdes venus des bords) vers Presentation Manager, en graphique : ciel étoilé avec nébuleuse et planète à anneaux, vaisseau dessiné qui pivote en douceur, astéroïdes de pierre ombrés et cratérisés aux contours irréguliers, tirs lumineux, explosions en particules, dans une image en mémoire dont seuls les rectangles changés sont recopiés (GpiDrawBits). Comme le prototype, le vaisseau reste au centre ; en plus, les astéroïdes arrivent par vagues de plus en plus rapides (une vague tous les 15 astéroïdes détruits), trois vies et un record. Flèches gauche et droite (tourner), Espace (tirer, tir continu en gardant la touche), souris (le vaisseau vise le pointeur, clic pour tirer), pause (P). Bruitages joués par MDM.DLL (tir, explosion des astéroïdes et du vaisseau, nouvelle vague ; menu Options, Son). <code>/SEED:n</code> ; <code>/AUTO</code> (visée automatique) ; <code>/NOSOUND</code>.</td></tr>
	<tr><td><b>Badugi</b> (BADUGI.EXE)</td><td>Porté du prototype <code>BADUGI.PAS</code> du dépôt 7iles (poker coréen à quatre cartes) : tapis vert, quatre joueurs (vous au sud contre trois ordinateurs), cartes dessinées comme au Poker, jetons et pot. Le prototype ne faisait qu'une donne et un échange ; le jeu suit maintenant la vraie règle : petite et grosse blinde (10 et 20 sur 1000 jetons), quatre tours de mise (parole, relance, se coucher, au plus quatre relances) entre trois échanges, et la vraie valeur des mains (un badugi a quatre cartes de quatre couleurs et de quatre rangs différents ; moins de cartes valables perd, puis la plus basse gagne, l'as est bas). L'ordinateur mise et échange selon sa main. Clic sur les cartes ou 1 2 3 4 pour choisir celles à échanger, C (parole ou suivre), R (relancer), P (se coucher), D (échanger), S (servi), Entrée (donne suivante). <code>/SEED:n</code> ; <code>/AUTO</code>.</td></tr>
	<tr><td><b>Tic-Tac-Toe</b> (TTT.EXE)</td><td>Porté du prototype <code>TTT.PAS</code> du dépôt 7iles (mode texte, contre l'ordinateur) : grille de 3 × 3 en relief, X verts en traits épais, O rouges en anneaux, ligne gagnante barrée, panneau des victoires, défaites et nulles. Trois niveaux (menu Options) : Facile, Moyen (la stratégie du prototype : gagner, bloquer, centre, coins) et Difficile (minimax, imbattable). L'ordinateur commence comme dans le prototype, ou vous (menu « Vous commencez »). Souris, touches 1 à 9 (comme le pavé numérique), flèches et Entrée, annulation (Ctrl+Z), N (nouvelle partie). <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Baseball</b> (BASEBALL.EXE)</td><td>Porté du prototype <code>BASEBALL.PAS</code> du dépôt 7iles (simulation en mode texte) en graphique : terrain vu d'en haut (pelouse rayée, losange de terre, buts, monticule, clôture, estrades et foule), joueurs dessinés, lancer et vol de la balle animés, coureurs qui avancent de but en but, tableau des points par manche, voyants des balles, prises et retraits. Les règles du prototype sont gardées (frappes selon la moyenne du frappeur et la qualité du lancer, simple, double, triple ou circuit, roulant souvent retiré) ; vous jouez maintenant une des deux équipes contre l'ordinateur : au bâton, le moment du coup d'élan compte (Espace ou clic au passage de la balle), au monticule, choix de la force du lancer (+ et -). Neuf manches, pas de fin de neuvième si les Locaux mènent, victoire sur le dernier point. Bruitages joués par MDM.DLL (lancer, élan, frappe du bâton, balle dans le gant, retrait, point marqué, la foule au coup de circuit, fin de partie ; menu Options, Son). <code>/SEED:n</code> ; <code>/AUTO</code> ; <code>/NOSOUND</code>.</td></tr>
	<tr><td><b>Excavateur</b> (EXCAVAT.EXE)</td><td>Jeu du genre des creuseurs de galeries, écrit à partir des règles d'un clone en Turbo Pascal fourni (<i>DigMan In the Rock</i>, de l'équipe dark-cloud, mode 320 × 200) : les dessins, les huit niveaux, les créatures et l'apparence sont propres à OS/2-0. Image en mémoire (GpiDrawBits, seules les parties qui changent sont recopiées) : ciel avec le chevalement de la mine, terre en quatre couches avec cailloux et racines, galeries creusées au pixel près, excavatrice jaune à foret (tournée dans les quatre directions), taupes, foreuses casquées, pierres précieuses taillées (émeraudes, rubis, saphirs, améthystes, topazes selon le niveau), sacs d'or, tas d'or, lanterne. L'excavatrice creuse où elle va et ramasse les pierres (25 points ; huit à la suite : 250 de plus). Un sac que plus rien ne soutient se balance puis tombe (pas tant que l'excavatrice est juste dessous) ; tombé de deux étages ou plus, il s'ouvre (or : 500 points) ; il écrase ce qui est dessous ; il se pousse à gauche ou à droite. Les taupes sortent du repaire et suivent les galeries ; certaines deviennent des foreuses qui creusent et mangent les pierres. Le tir part dans la galerie et se recharge. La lanterne, au repaire quand la moitié des créatures sont vaincues, les effraie : on les attrape (200 à 1600 points). Trois vies, une de plus tous les 20000 points. Flèches (une case par appui, la répétition de la touche fait continuer : Presentation Manager ne signale pas le relâchement), Espace, P, trois vitesses (menu Options). <code>/SEED:n</code> ; <code>/AUTO</code> (démonstration) ; <code>/LEVEL:n</code>.</td></tr>
	<tr><td><b>Machine à boule</b> (PINBALL.EXE)</td><td>Porté du flipper fourni (Turbo Pascal, mode X 320 × 400, Sound Blaster ; jeu d'origine de Ansgar Scherp et Joachim Gelhaus, dont les sources, les tables et les sons sont réutilisables en citant les auteurs) avec ses deux tables, <b>Glace</b> et <b>Rat de l'espace</b>, leurs masques de collision, les bras des batteurs, la balle, le ressort, les polices de l'afficheur et ses quatorze sons. Tout est dans le programme (constantes Pascal, compressées en LZSS) : un seul fichier, PINBALL.EXE. La physique d'origine est reprise (la balle suit le masque au pixel près, gravité réduite sur la table du rat), ainsi que les événements des deux tables : bumpers, lumières, P-C-S et SPECIAL, trou de ver, boucles, température et feux pour la glace ; R-A-T, P-H-A-S-E-R, porte et balle verrouillée, rampe, trous de sortie, relance pour le rat ; bonus comptés en fin de balle. Fenêtre de Presentation Manager : la table défile pour suivre la balle, afficheur à points rouges au-dessus (messages traduits, tapés puis défilant comme l'original), panneau des pointages de 1 à 4 joueurs avec la table en miniature, menus Partie, Options (table, joueurs, son) et Aide. Sons joués à leur fréquence d'origine par MDM.DLL. Batteurs : Maj gauche et Maj droite tenues (état du clavier lu à chaque image, comme l'original ; flèches : un coup) ; ressort : Espace puis Espace (ou Ctrl tenu puis relâché) ; K secoue la table (cinq fois : TILT, la balle est perdue). Le lancement de la table du rat est plus fort que l'original, qui ne franchissait pas la courbe du haut. <code>/TABLE:1</code> ou <code>2</code> ; <code>/AUTO</code> (démonstration) ; <code>/NOSOUND</code> ; <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Barbu</b> (BARBU.EXE)</td><td>Porté du prototype <code>BARBU.PAS</code> du dépôt 7iles (Turbo Pascal et BGI, cartes en rectangles) : tapis vert dans un cadre de bois, vous au sud contre Ouest, Nord et Est (l'ordinateur), cartes dessinées comme au Poker, mains adverses en éventail, levée au centre, cartes jouables surlignées, panneau de la donne, du contrat et des points. Le donneur choisit le contrat : <b>Pas de levées</b> (2 par levée), <b>Pas de cœurs</b> (2 par cœur), <b>Pas de dames</b> (6 par dame), <b>Le Barbu</b> (le roi de cœur, 16), <b>Pas la dernière levée</b> (16) ou <b>La salade</b> (tout à la fois) ; le moins de points gagne. Ajouts au prototype : la salade, le choix du contrat par le donneur, partie courte (6 donnes) ou complète (24 donnes, chaque donneur joue chaque contrat), l'as le plus fort, pas d'entame à cœur tant qu'on a autre chose, le roi de cœur à défausser au Barbu, la donne qui s'arrête quand toutes les pénalités sont tombées, un ordinateur qui passe sous la carte maîtresse et se défait de ses cartes dangereuses. Souris, ou flèches et Entrée ; 1 à 6 pour le contrat. Menus Partie, Options et Aide. <code>/AUTO</code> ; <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Casse-Brique</b> (BREAKOUT.EXE)</td><td>Porté du prototype <code>BREAKOUT.PAS</code> du dépôt 7iles (mode texte de 40 colonnes) en graphique : image en mémoire recopiée par morceaux, mur métallique riveté, six rangées de 19 briques en relief (deux rouges à 7 points, une orange et deux vertes à 4 points, une bleue à 1 point), raquette chromée, balle lumineuse, éclats des briques, panneau du pointage, des balles et du niveau, bruitages synthétisés joués par MDM.DLL. Comme le prototype : 5 balles, une balle de plus et un nouveau mur à chaque mur abattu. Ajouts : la balle rebondit selon l'endroit où elle touche la raquette et accélère au fil des coups, chaque nouveau mur commence plus bas, la souris guide la raquette, record de la séance. Options : balles illimitées, briques restantes, son. <code>/FULLBALLS</code> ; <code>/SHOWBRICKS</code> ; <code>/NOSOUND</code> ; <code>/AUTO</code> ; <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Bataille</b> (BATAILLE.EXE)</td><td>Porté du prototype <code>BATAILLE.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) : tapis vert, paquets en relief, cartes dessinées retournées une à une, batailles montrées carte par carte (trois cartes cachées, une visible, et ainsi de suite), panneau du compte des cartes avec jauges, plis, batailles et parties gagnées. Celui qui ne peut pas finir une bataille perd la partie ; les cartes gagnées vont sous le paquet dans un ordre mélangé. Espace ou clic pour jouer, jeu automatique en trois vitesses. <code>/AUTO</code> ; <code>/BATAILLE</code> (le premier pli est une bataille) ; <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Invasion de l'espace</b> (INVADERS.EXE)</td><td>Porté du prototype <code>INVADERS.PAS</code> du dépôt 7iles (Turbo Pascal et BGI en noir et blanc, titre en caractères) en couleur : image en mémoire recopiée par morceaux, ciel étoilé avec planète et nébuleuse, envahisseurs dessinés d'après les dessins de 24 × 16 points du prototype (en couleur, avec relief et ombre, deux poses qui alternent), quatre abris qui s'effritent au point près, canon, vaisseau mère, explosions, écran titre avec la table des pointages, panneau du pointage, des canons et des envahisseurs restants. Comme le prototype : cinq rangées de douze envahisseurs qui descendent à chaque bord et tirent, 40, 30, 20 et 10 points selon la rangée, 100 points pour le vaisseau mère, trois canons, un canon de plus par tableau terminé. Ajouts : la marche des envahisseurs s'accélère quand il en reste peu, chaque tableau commence plus bas, un tir peut détruire une bombe, la souris, le record de la séance, une démonstration (menu Options). Bruitages joués par MDM.DLL (tirs, explosions, vaisseau mère, marche des envahisseurs). <code>/AUTO</code> ; <code>/LEVEL:n</code> ; <code>/NOSOUND</code> ; <code>/SEED:n</code>.</td></tr>
	<tr><td><b>FreeCell</b> (FREECELL.EXE)</td><td>Porté du prototype <code>FREECELL.PAS</code> du dépôt 7iles (Turbo Pascal et BGI, cartes en rectangles de 50 × 70) : tapis vert, cartes dessinées comme au Poker (cartes recouvertes dessinées en allégé pour un affichage rapide), quatre cellules libres et quatre fondations marquées de leur couleur, cartes choisies surlignées, colonnes resserrées quand elles s'allongent. Comme le prototype : 52 cartes visibles en huit colonnes, une carte se pose sur la suivante de l'autre couleur, toute carte va sur une colonne vide, fondations de l'as au roi ; clic pour choisir puis clic pour déposer. Ajouts : les donnes numérotées (les mêmes que celles du FreeCell de Windows, la donne 1 commence par le valet de carreau), le déplacement d'une suite d'un coup selon les cellules et colonnes libres, les cartes qui montent seules aux fondations quand elles ne servent plus, le double clic, l'annulation (Ctrl+Z), donne suivante et rejouer la donne, clavier (1 à 8, A à D, H). <code>/DEAL:n</code> ; <code>/AUTO</code> (coups évidents) ; <code>/SEED:n</code>.</td></tr>
	<tr><td><b>Commandement des missiles</b> (MISSILE.EXE)</td><td>Porté du prototype <code>MISSILE.PAS</code> du dépôt 7iles (Turbo Pascal, mode 13h de 320 × 200, souris obligatoire) : image en mémoire recopiée par morceaux, ciel de nuit étoilé avec lune, collines, six villes aux fenêtres éclairées, batterie au centre dont le canon suit le viseur, traînées des missiles, boules de feu, panneau du pointage, bruitages joués par MDM.DLL. Comme le prototype : les missiles tombent sur six villes, une ville touchée est détruite pour de bon, la partie est perdue quand il n'en reste plus ; chaque niveau envoie plus de missiles, plus vite ; 100 points par missile, 75 par ville restante en fin de niveau. Ce qui change : le clic envoie un antimissile qui explose au point visé, et sa boule de feu détruit les missiles qui la traversent (chacun explose à son tour : réactions en chaîne) ; 30 antimissiles par niveau, batterie touchée muette jusqu'au niveau suivant, missiles qui se divisent à partir du niveau 3, une ville de plus tous les 10 000 points. Souris, ou flèches et Espace. <code>/AUTO</code> ; <code>/LEVEL:n</code> ; <code>/NOSOUND</code> ; <code>/SEED:n</code>.</td></tr>
	<tr><td><b>L25</b> (L25.EXE)</td><td>Porté du prototype <code>L25.PAS</code> du dépôt 7iles (menu en mode texte, damier BGI de 16 points, flèches et Entrée) : échiquier de 5 × 5 dans un cadre de bois avec ses coordonnées, cavalier dessiné, cases parcourues numérotées et reliées par le chemin du cavalier, sauts possibles marqués d'un point jaune. Comme le prototype : le cavalier part du coin en haut à gauche et doit passer par les 25 cases sans jamais repasser par la même ; sans saut possible avant la 25e, la partie est perdue. Ajouts : la souris, l'annulation, le départ au choix, une solution montrée coup par coup depuis la position atteinte (recherche avec retour arrière, cases les plus contraintes d'abord), le meilleur parcours. <code>/AUTO</code> (la solution se joue en boucle).</td></tr>
	<tr><td><b>Bubble Shooter</b> (BUBBLE.EXE)</td><td>Porté du prototype <code>BS.PAS</code> du dépôt 7iles (Turbo Pascal et BGI, bulles en cercles plats) vers Presentation Manager, et corrigé : viser avec la souris (ou les flèches) et tirer la bulle chargée ; elle rebondit sur les murs et s'accroche dans une grille hexagonale décalée ; un groupe de 3 bulles ou plus de la même couleur éclate (trouvé par remplissage, les bulles sont vraiment retirées : le prototype en oubliait parfois) et les bulles qui ne tiennent plus au plafond tombent (20 points chacune). La couleur chargée est toujours une couleur encore présente ; le plafond métallique riveté descend après quelques tirs ratés ; la partie est perdue quand les bulles passent la ligne rouge, gagnée quand le plateau est vidé (bonus, niveau suivant plus difficile). Bulles en relief, fond en dégradé, canon en dôme, ligne de visée avec rebonds (Options), bulle suivante, panneau avec pointage, niveau, tirs, plafond et record ; animation au minuteur dans une image en mémoire, sans scintillement. Menus Partie (Nouvelle partie F2, Pause P), Options (Ligne de visée, Démonstration, Son), Aide (Règles F1, À propos). <code>/SEED:n</code>, <code>/LEVEL:n</code>, <code>/AUTO</code> (l'ordinateur joue), <code>/NOSOUND</code>, <code>/TEST</code> (essais de l'accrochage, de l'éclatement, des chutes et des rebonds, puis 120 tirs reproductibles, résultats sur le port série).</td></tr>
	<tr><td><b>BlackJack</b> (BLACKJAK.EXE)</td><td>Porté du prototype <code>BLACKJAK.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Le BlackJack contre le croupier : tapis vert en dégradé, rebord de bois, sabot de quatre jeux (mélangé quand il reste moins de 52 cartes), cartes dessinées (as, symboles, figures, dos bleu) qui glissent du sabot, jetons de 5 à 500 $ et cercle de mise ; boutons Distribuer, Tirer, Rester, Doubler et Effacer la mise (grisés quand ils ne s'appliquent pas) ; le croupier tire jusqu'à 16 et vérifie sa carte cachée devant un as ou un 10 ; BlackJack payé 3 contre 2, solde de départ de 1000 $, record de la séance. Options : Son, Distribution rapide, Afficher les totaux, Démonstration (l'ordinateur suit la stratégie de base). Corrigé : la carte cachée du croupier et son total, le paquet remélangé à chaque donne. <code>/SEED:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Blox</b> (BLOX.EXE)</td><td>Porté du prototype <code>BLOX.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Des pièces de quatre blocs tombent dans un puits de 10 × 20 ; une ligne complète disparaît (après un clignotement). Sa particularité, gardée du prototype : des <b>briques maçonnées sont déjà posées au fond</b> (3 à 11 rangées selon le niveau de départ, toujours trouées), et tous les 10 lignes le niveau monte, la chute accélère et une nouvelle rangée de briques monte du fond ; détruire toutes les briques rapporte une prime. Blocs en relief, pièce suivante, ombre de la pièce, titre en petits blocs, panneaux de Warp 3 ; rotation dans les deux sens avec décalage contre les murs, chute immédiate (Espace), pause (P) ; pièces tirées d'un sac de sept. Options : Niveau de départ (1 à 9), Ombre, Son, Démonstration. Corrigé : tirage inégal des pièces, briques de départ formant une ligne complète, couleurs changeantes. <code>/SEED:n</code>, <code>/LEVEL:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Golf</b> (GOLF.EXE)</td><td>Porté du prototype <code>GOLF.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Le Golf à six cartes contre l'ordinateur : deux cartes retournées au début de chaque trou ; on pioche ou on prend la défausse, on échange avec une de ses cartes ou on défausse puis on retourne une carte ; deux cartes de même rang dans une colonne valent 0 ; quand un joueur a tout retourné, l'autre joue un dernier tour ; parcours de 9 ou 3 trous, le plus petit total gagne. Tapis vert, cartes dessinées qui glissent (dos au drapeau de golf), paires entourées en vert, carnet de pointage, démonstration. Corrigé : cartes retournées jamais comptées (la donne ne finissait pas), pointage d'un seul chiffre, pioche vide, cartes cachées oubliées au compte. <code>/SEED:n</code>, <code>/HOLES:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Grenouille</b> (FROGGER.EXE)</td><td>Porté du prototype <code>FROGGER.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Jeu d'arcade, dessins originaux : la grenouille traverse quatre voies (voitures, tracteurs, bolides, camions), puis la rivière en sautant sur des troncs et des tortues (certaines plongent) pour atteindre les cinq nénuphars de la haie ; vies, barre de temps, mouche bonus, niveaux de plus en plus rapides, trois difficultés ; flèches ou clic autour de la grenouille, P : pause ; animation à 25 images par seconde dans une image en mémoire. Corrigé : couleurs des voitures, grenouille portée par tous les troncs à la fois, collisions, minuterie dépendante du processeur, fin de partie sans message. <code>/SEED:n</code>, <code>/LEVEL:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Bonhomme pendu</b> (HANGMAN.EXE)</td><td>Porté du prototype <code>HANGMAN.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Le jeu du pendu, avec un <b>bonhomme dessiné en style dessin animé</b> : ciel en dégradé, soleil, nuages, collines, potence en bois (planches, veinures, vis, jambe de force), corde torsadée ; à chaque erreur une partie du bonhomme s'ajoute (grosse tête ronde avec cheveux et oreilles, chemise à boutons, ceinture, bras, pantalon, chaussures) et son visage change (sourire, inquiétude, peur avec goutte de sueur ; yeux en croix et langue tirée s'il est pendu, grand sourire et bras levés s'il est sauvé). Clavier de lettres cliquable (vert : lettre du mot, rouge : absente) et clavier physique (lettres accentuées comprises), cœurs des erreurs restantes, pointage, série et record ; niveaux Débutant, Chevalier et Roi (listes du prototype). Corrigé : une bonne lettre tapée deux fois comptait deux fois, le dernier mot de chaque liste n'était jamais tiré. <code>/SEED:n</code>, <code>/LEVEL:</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Lights</b> (LIGHTS.EXE)</td><td>Porté du prototype <code>LIGHTS.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Casse-tête de lampes : cliquer une lampe l'inverse avec ses quatre voisines ; il faut toutes les éteindre. Lampes de verre dans des douilles de métal en relief, halo, fondu à l'allumage et à l'extinction ; souris ou curseur au clavier, annulation sans limite, indice (anneau vert), solution, nombre minimal de coups calculé exactement (algèbre de GF(2)) ; les 25 niveaux du prototype puis des niveaux au hasard toujours solubles. Corrigé : le niveau 14 était insoluble, compteur de coups de deux chiffres, pas de souris. <code>/SEED:n</code>, <code>/LEVEL:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Alunissage</b> (LUNAR.EXE)</td><td>Porté du prototype <code>LUNAR.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Poser le module lunaire sur une piste, doucement, en dosant le moteur principal et les propulseurs (gravité lunaire, carburant compté). Ciel étoilé avec la Terre, montagnes lointaines, sol en relief éclairé de côté avec ses cratères, pistes balisées à multiplicateur (x1 à x5 : plus étroite, mieux payée), module dessiné (étage de descente doré, pieds, antenne), flamme et jets, poussière soulevée, explosion en débris qui retombent ; instruments (altitude, descente, dérive, carburant), un terrain par niveau, trois modules, trois difficultés, pause, pilote automatique, souris (bouton maintenu : moteur). Corrigé : poussée selon le tampon du clavier, carburant par touche, contact au sol sur deux points, vitesse horizontale non vérifiée, explosion jamais effacée. <code>/SEED:n</code>, <code>/LEVEL:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Boston</b> (BOSTON.EXE)</td><td>Porté du prototype <code>BOSTON.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Jeu de levées à quatre : vous (Sud) contre Ouest, Nord et Est. Enchères de 5 à 13 levées à trèfle, carreau, coeur, pique ou sans atout (boîte d'enchères en relief, bulles des annonces, conseil sur la valeur de votre main) ; le demandeur joue seul contre les trois autres ; il faut fournir, l'atout l'emporte. Tapis dans un cadre de bois, cartes dessinées, dos à croisillons, cartes qui glissent vers la levée, cartes injouables grisées, dernière levée, pointage du Boston à somme nulle, partie de 4 ou 8 donnes avec donneur tournant, ordinateur qui évalue sa main, compte les cartes et tire les atouts. Corrigé : contrat imposé sans enchères, touches 1 à 9 seulement, une seule donne sans pointage, attentes bloquantes. <code>/SEED:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Cannonball</b> (CANNONBA.EXE)</td><td>Porté du prototype <code>CANNONBA.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. L'homme-canon du cirque : régler l'angle (10 à 80°) et la puissance, tirer, puis déplacer le filet sur son chariot pour rattraper l'artiste. Intérieur de chapiteau (toile rayée, lambrequin festonné, guirlande de fanions, public dans les gradins, piste de sciure, projecteurs), canon peint sur son affût à roue, artiste orienté selon sa trajectoire, traînée, fumée, filet qui rebondit, confettis, étoiles en cas de chute ; spectacles de 10 artistes, pointage (précision, distance, vent, séries), courants d'air, point de chute prévu en option, trois largeurs de filet, souris (le pointeur vise, le filet suit). Corrigé : trajectoire effacée en trouant le décor, filet par à-coups, pas de fin de partie ni de pointage, artiste hors de l'écran. <code>/SEED:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Bingo</b> (BINGO.EXE)</td><td>Porté du prototype <code>BINGO.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Bingo à 75 boules (B 1-15, I 16-30, N 31-45, G 46-60, O 61-75, case centrale libre) contre 1 à 3 ordinateurs : carton de papier avec les lettres sur des boules de couleur, case libre étoilée, marques d'encreur, boule tirée qui roule jusqu'à sa place, dernières boules, tableau des 75 numéros, cartons des adversaires ; on marque soi-même ses numéros (clic, ou flèches et Entrée) et on crie BINGO (ligne, colonne ou diagonale), avant que les ordinateurs ne le crient ; faux bingo refusé, bingo partagé, tirage et marquage automatiques en option, manches et score de la séance. Corrigé : le joueur n'avait rien à faire, il gagnait toujours en cas d'égalité, le tirage par essais pouvait finir la partie trop tôt, le mode automatique bloquait le programme. <code>/SEED:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Craps</b> (CRAPS.EXE)</td><td>Porté du prototype <code>CRAPS.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Jeu de dés de casino : au premier lancer 7 ou 11 gagnent, 2, 3 ou 12 perdent, les autres totaux deviennent le point à refaire avant le 7. Table de bois et de feutre, cases des points 4, 5, SIX, 8, NEUF, 10 avec le palet ON/OFF, dés rouges en relief qui roulent, rebondissent et tournent sur le tapis ; mises en jetons (5 à 100 $) sur la ligne de passe, Ne passe pas (12 nul), le champ (2 et 12 doubles) et la cote au juste prix (2 pour 1, 3 pour 2, 6 pour 5) ; mise précédente rejouée d'une touche, statistiques, record, démonstration. Corrigé : un 11 pendant le point faisait perdre, la mise changeait en cours de coup, il fallait N pour rejouer, rien n'arrêtait la partie sans argent. <code>/SEED:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Roulette</b> (ROULETTE.EXE)</td><td>Porté du prototype <code>ROULETTE.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Roulette européenne à un zéro : cylindre dessiné avec soin (jante de bois, piste et losanges, numéros dans l'ordre du cylindre, cases et cloisons d'argent, cône et croisillon dorés) qui tourne vraiment pendant que la bille tourne en sens inverse, ralentit, rebondit et tombe dans sa case ; tapis complet (pleins 35 pour 1, colonnes et douzaines 2 pour 1, rouge, noir, pair, impair, manque, passe 1 pour 1), jetons de 1 à 100 $ empilés, curseur au clavier sur tout le tapis, cases gagnantes en or, douze derniers numéros, mise rejouée, lancer rapide, démonstration. Corrigé : numéros de la roue dans l'ordre 0 à 36, roue immobile, manque, passe et douzaines inaccessibles à la souris, mise négative possible, dix mises au plus. <code>/SEED:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Xiangqi</b> (XIANGQI.EXE)</td><td>Porté du prototype <code>XIANGQI.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Les échecs chinois contre l'ordinateur ou à deux : plateau de bois veiné de 9 × 10 intersections, rivière (楚河 漢界 en idéogrammes), palais et diagonales, repères des canons et des soldats ; pièces rondes d'ivoire en relief à l'anneau et à l'idéogramme gravés, rouges ou noires, qui se soulèvent et glissent ; coups possibles et dernier coup marqués, échec signalé, liste des coups en notation chinoise. Ordinateur alpha-bêta en trois niveaux, indice, annulation, jouer les noirs (plateau retourné), démonstration ; nulle par triple répétition, 60 coups sans prise ou manque de pièces d'attaque. Corrigé : l'échec n'était jamais détecté (ni mat, ni interdiction de laisser son Général en prise), Généraux face à face permis, pat compté nul (au Xiangqi il perd), ordinateur à un demi-coup, pas de souris. <code>/SEED:n</code>, <code>/LEVEL:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Tic-Tac-Toe 3D</b> (TTT3D.EXE)</td><td>Porté du prototype <code>TTT3D.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) vers Presentation Manager. Le morpion dans un cube de 4 × 4 × 4 (ou 3 × 3 × 3) contre l'ordinateur ou à deux : quatre plateaux de verre empilés en perspective et reliés par les arêtes du cube, billes rouges et bleues en relief qui tombent sur leur case avec leur ombre, niveau courant éclairé, ligne gagnante dorée ; souris, ou flèches et Pg Préc/Suiv au clavier. Ordinateur en trois niveaux (gain, parade, fourchette, suites de menaces forcées), premier joueur en alternance, annulation, indice, démonstration, pointage de la séance. Corrigé : seules 44 des 76 lignes gagnantes étaient vérifiées (colonnes verticales et diagonales des plans verticaux oubliées), niveaux superposés dans la vue 3D, ordinateur qui prenait la première case libre, pas de souris. <code>/SEED:n</code>, <code>/LEVEL:n</code>, <code>/SIZE:3</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Patience</b> (PATIENCE.EXE)</td><td>Porté du prototype <code>PATIENCE.PAS</code> du dépôt 7iles (Turbo Pascal, mode texte, 1992) vers Presentation Manager. Patience en solitaire : la carte de départ donne le rang de base, quatre réserves de trois cartes, pioche retournée trois par trois (ou une à une) sans limite ; quatre rangées par couleur ouvertes par les cartes du rang de base, la première reçoit toute carte de sa couleur, les suivantes seulement si la rangée du dessus a déjà ce rang. Tapis de feutre, cartes dessinées (points disposés, As dans un anneau doré, portraits de Valet, Dame et Roi, dos bordeaux à treillis doré), cartes qui glissent, cartes rangées par colonnes de rang. Annulation sans limite, indice, même donne, démonstration, statistiques. Corrigé : cartes empilées dans l'ordre d'arrivée, défausse mal effacée, partie bloquée jamais détectée, programme qui quittait à la victoire. <code>/SEED:n</code>, <code>/DRAW:1</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
	<tr><td><b>Le Plombier</b> (PLOMBIER.EXE)</td><td>Réalisé à partir du prototype inachevé <code>MARIO.PAS</code> du dépôt 7iles (Turbo Pascal et BGI) pour Presentation Manager, entièrement redessiné (dessins et bruitages originaux). Jeu de plateformes à un écran dans le genre des jeux d'arcade de 1983 : Lorenzo le plombier (chandail gris, salopette ocre, casquette sarcelle), déplacé par les flèches (il continue d'avancer jusqu'à une autre flèche) et qui saute avec Espace, frappe le dessous des plateformes (carrés à quatre triangles : 13+13, 3+16+3, 11+POW+11, plancher de briques rouges) pour retourner les ennemis sortis à tour de rôle de deux tuyaux bleu acier, puis les élimine en les touchant ; tuyaux de retour gris. Tortues, crabes (deux coups), mouches combattantes, rats (petits, rapides, demi-tours au hasard), crocodiles (lents, deux coups), verglas qui gèle les plateformes, pièces ; bloc POW (3 coups par phase), clefs de plombier à ramasser en bas et à déposer sur la plateforme du haut (bonus), éliminations à la suite, phases bonus chronométrées (4 et 9, plancher glissant), les 10 phases demandées puis reprise plus rapide, nacelle de retour, vie de plus à 20 000 points ; pointage en haut à gauche, record en haut à droite, phase en bas à gauche sous le tuyau ; démonstration (l'ordinateur essaie chaque action sur une seconde de jeu simulée), souris. Corrigé : saut sans gravité jusqu'au plafond, coup de tête qui retournait tous les ennemis de la même hauteur, ennemis jamais dangereux (ni vies ni fin de phase), ennemis disparus aux tuyaux du bas, scintillement (GetImage/PutImage), vitesse liée à l'ordinateur. <code>/SEED:n</code>, <code>/PHASE:n</code>, <code>/AUTO</code>, <code>/NOSOUND</code>, <code>/TEST</code>.</td></tr>
</table>

<img width="640" height="480" alt="OS/2-0 : Solitaire - Klondike" src="IMAGE/KLONDIKE.png" />
<img width="640" height="480" alt="OS/2-0 : Échecs (l'ordinateur a répondu au premier coup)" src="IMAGE/ECHECS.png" />
<img width="640" height="480" alt="OS/2-0 : Mahjongg Solitaire" src="IMAGE/MAHJONGG.png" />
<img width="640" height="480" alt="OS/2-0 : Sudoku (un chiffre en conflit en rouge, un indice en vert)" src="IMAGE/SUDOKU.png" />
<img width="640" height="480" alt="OS/2-0 : Othello contre l'ordinateur, indices affichés" src="IMAGE/OTHELLO.png" />
<img width="640" height="480" alt="OS/2-0 : TileMan (territoire conquis en bleu, trace en cyan)" src="IMAGE/TILEMAN.png" />
<img width="640" height="480" alt="OS/2-0 : Hex 2048" src="IMAGE/HEX2048.png" />
<img width="640" height="480" alt="OS/2-0 : Backgammon (un pion choisi, ses cases d'arrivée marquées)" src="IMAGE/BACKGAM.png" />
<img width="640" height="480" alt="OS/2-0 : Poker (abattage : paire de 6 contre paire de 5)" src="IMAGE/POKER.png" />
<img width="640" height="480" alt="OS/2-0 : Billard (casse, visée à la souris)" src="IMAGE/BILLARD.png" />
<img width="640" height="480" alt="OS/2-0 : Checkers contre l'ordinateur" src="IMAGE/CHECKERS.png" />
<img width="640" height="480" alt="OS/2-0 : Yahtzee (points possibles en jaune, deux dés gardés)" src="IMAGE/YAHTZEE.png" />
<img width="640" height="480" alt="OS/2-0 : Bataille navale, placement de la flotte (silhouette du cuirassé)" src="IMAGE/BATTLE.png" />
<img width="640" height="480" alt="OS/2-0 : Bataille navale en italien, ordinateur contre ordinateur" src="IMAGE/BATTLE_IT.png" />
<img width="640" height="480" alt="OS/2-0 : Puissance 4" src="IMAGE/POWER4.png" />
<img width="640" height="480" alt="OS/2-0 : Soko-Ban, étage 7" src="IMAGE/SOKOBAN.png" />
<img width="640" height="480" alt="OS/2-0 : Baccarat" src="IMAGE/BACCARAT.png" />
<img width="640" height="480" alt="OS/2-0 : Tours de Hanoï" src="IMAGE/HANOIS.png" />
<img width="640" height="480" alt="OS/2-0 : Baby" src="IMAGE/BABY.png" />
<img width="640" height="480" alt="OS/2-0 : 421" src="IMAGE/421.png" />
<img width="640" height="480" alt="OS/2-0 : Mille-pattes" src="IMAGE/CENTIPED.png" />
<img width="640" height="480" alt="OS/2-0 : Astéroïde" src="IMAGE/ASTEROID.png" />
<img width="640" height="480" alt="OS/2-0 : Badugi (échange des cartes)" src="IMAGE/BADUGI.png" />
<img width="640" height="480" alt="OS/2-0 : Tic-Tac-Toe (ligne gagnante barrée)" src="IMAGE/TTT.png" />
<img width="640" height="480" alt="OS/2-0 : Baseball (un double)" src="IMAGE/BASEBALL.png" />
<img width="640" height="480" alt="OS/2-0 : Excavateur, niveau 2 (rubis)" src="IMAGE/EXCAVAT.png" />
<img width="640" height="480" alt="OS/2-0 : Excavateur, la lanterne effraie les taupes" src="IMAGE/EXCAVAT_LANTERNE.png" />
<img width="640" height="480" alt="OS/2-0 : Machine à boule, table Rat de l'espace" src="IMAGE/PINBALL.png" />
<img width="640" height="480" alt="OS/2-0 : Machine à boule, table Glace" src="IMAGE/PINBALL_GLACE.png" />
<img width="640" height="480" alt="OS/2-0 : Barbu, contrat Pas de coeurs (cartes jouables surlignées)" src="IMAGE/BARBU.png" />
<img width="640" height="480" alt="OS/2-0 : Casse-Brique" src="IMAGE/BREAKOUT.png" />
<img width="640" height="480" alt="OS/2-0 : Bataille (double bataille, 18 cartes)" src="IMAGE/BATAILLE.png" />
<img width="640" height="480" alt="OS/2-0 : Invasion de l'espace, écran titre" src="IMAGE/INVADERS_TITRE.png" />
<img width="640" height="480" alt="OS/2-0 : Invasion de l'espace" src="IMAGE/INVADERS.png" />
<img width="640" height="480" alt="OS/2-0 : FreeCell, donne 617 (une suite choisie)" src="IMAGE/FREECELL.png" />
<img width="640" height="480" alt="OS/2-0 : Commandement des missiles, niveau 7" src="IMAGE/MISSILE.png" />
<img width="640" height="480" alt="OS/2-0 : L25, solution montrée coup par coup" src="IMAGE/L25.png" />
<img width="640" height="480" alt="OS/2-0 : Bubble Shooter, partie en cours" src="IMAGE/BUBBLE.png" />
<img width="640" height="480" alt="OS/2-0 : Bubble Shooter, éclatement et chute de bulles (niveau 2)" src="IMAGE/BUBBLE_CHUTE.png" />
<img width="640" height="480" alt="OS/2-0 : BlackJack" src="IMAGE/BLACKJACK.png" />
<img width="640" height="480" alt="OS/2-0 : Blox, briques au fond du puits" src="IMAGE/BLOX.png" />
<img width="640" height="480" alt="OS/2-0 : Golf à six cartes" src="IMAGE/GOLF.png" />
<img width="640" height="480" alt="OS/2-0 : Grenouille, la route et la rivière" src="IMAGE/GRENOUILLE.png" />
<img width="640" height="480" alt="OS/2-0 : Bonhomme pendu, partie perdue" src="IMAGE/PENDU.png" />
<img width="640" height="480" alt="OS/2-0 : Bonhomme pendu, partie gagnée" src="IMAGE/PENDU_GAGNE.png" />
<img width="640" height="480" alt="OS/2-0 : Lights, indice" src="IMAGE/LIGHTS.png" />
<img width="640" height="480" alt="OS/2-0 : Alunissage, le module au-dessus de la piste x5" src="IMAGE/ALUNISSAGE.png" />
<img width="640" height="480" alt="OS/2-0 : Boston, une levée en cours" src="IMAGE/BOSTON.png" />
<img width="640" height="480" alt="OS/2-0 : Cannonball, l'artiste en vol au-dessus du filet" src="IMAGE/CANNONBALL.png" />
<img width="640" height="480" alt="OS/2-0 : Bingo, carton et tirage" src="IMAGE/BINGO.png" />
<img width="640" height="480" alt="OS/2-0 : Craps, dés sur le tapis" src="IMAGE/CRAPS.png" />
<img width="640" height="480" alt="OS/2-0 : Roulette, le cylindre et le tapis" src="IMAGE/ROULETTE.png" />
<img width="640" height="480" alt="OS/2-0 : Xiangqi, partie contre l'ordinateur" src="IMAGE/XIANGQI.png" />
<img width="640" height="480" alt="OS/2-0 : Tic-Tac-Toe 3D, le cube de 4 × 4 × 4" src="IMAGE/TTT3D.png" />
<img width="640" height="480" alt="OS/2-0 : Patience, partie en cours" src="IMAGE/PATIENCE.png" />
<img width="640" height="480" alt="OS/2-0 : Le Plombier, un crocodile sort du tuyau" src="IMAGE/PLOMBIER.png" />
<img width="640" height="480" alt="OS/2-0 : Le Plombier, tortues retournées par le bloc POW" src="IMAGE/PLOMBIER_POW.png" />

Les chaînes d'OS2PC font au plus 255 caractères : les règles des jeux et plusieurs aides (Othello, Sudoku, Klondike, Navigateur Web, Audio numérique, Pascal Developer, Gestionnaire des tâches…) étaient coupées en plein mot ; le texte est maintenant cumulé dans un tampon (<code>LClr</code>, <code>LAdd</code>) puis affiché par <code>LMsgBox</code>. Un nom de procédure identique à une procédure du Graph intégré d'OS2PC appelle celle d'OS2PC sans message : la fonction <code>Sector</code> d'Hex 2048 démarrait le Graph de Win32 au premier clic sur le plateau et le jeu se fermait (SYS1804 CreateSolidBrush) ; elle s'appelle maintenant <code>DirSector</code>, et les noms des procédures de tous les jeux ont été vérifiés contre la liste des fonctions intégrées d'OS2PC. Écrire ces jeux a fait apparaître des limites d'OS2PC. La borne d'une boucle <code>For</code> était gardée dans une variable statique : dans une fonction récursive (la recherche alpha-bêta des Échecs), un appel intérieur écrasait la borne de la boucle de l'appelant, qui ne se terminait plus. OS2PC la range maintenant dans le cadre de pile de la procédure (une case par <code>For</code> du corps, sous les variables locales) ; seul le programme principal garde une variable statique. Les tableaux à deux dimensions dans un enregistrement et la copie d'enregistrements entiers ne sont pas encore fiables (les jeux utilisent des tableaux globaux à une dimension).

<h2>Noyau OS/2 32 bits et CD-ROM amorçable</h2>

OS2-0 possède son propre noyau OS/2 32 bits écrit en Pascal. Comme sous OS/2, le démarrage se fait en trois fichiers, chacun écrit dans un seul fichier source Pascal (dossier <b>KERNEL</b>) :

<table>
	<tr><th>Fichier</th><th>Source</th><th>Description</th></tr>
	<tr><td><b>OS2BOOT</b></td><td>KERNEL/OS2BOOT.PAS</td><td>Secteur d'amorce du CD-ROM (El Torito sans émulation, mode réel 8086) : lit le système de fichiers ISO 9660 par l'INT 13h étendue et charge OS2LDR en 2000:0000.</td></tr>
	<tr><td><b>OS2LDR</b></td><td>KERNEL/OS2LDR.PAS</td><td>Chargeur 16 bits : charge l'image PE du noyau à 1 Mo (INT 15h/87h), relève la carte mémoire (E820h), active la ligne A20, installe une GDT plate et passe en mode protégé.</td></tr>
	<tr><td><b>OS2KRNL</b></td><td>KERNEL/OS2KRNL.PAS</td><td>Noyau 32 bits (80386, mode protégé) : console VGA, IDT, exceptions (écran TRAP), PIC, minuterie, clavier, souris PS/2, tas, pagination, pilote ATAPI, disques durs IDE, ISO 9660 et disque virtuel en mémoire, systèmes de fichiers installables (IFS=), couche API DOSCALLS, chargeur de programmes PE et processus, lecture de CONFIG.SYS et lancement du PROTSHELL (<b>PMSHELL.EXE</b>, le bureau ; CMD.EXE par défaut), Ctrl+Alt+Suppr (signalé au bureau, sinon redémarrage), appel du BIOS en mode réel (KERNEL/BIOSCALL.ASM), modes VESA (KrnVideo), lecteur de disquettes A: (FAT12) et machine virtuelle DOS (mode V86, TSS, LDT : sessions DOS).</td></tr>
</table>

<img width="720" height="400" alt="OS/2-0 : CMD.EXE sous le noyau OS2KRNL" src="IMAGE/OS2-0.png" />

Le compilateur <b>OS2PC.PAS</b> (« OS/2 Pascal Compiler », dossier <b>TOOLS</b>) est dérivé de <b>TPCW32.PAS</b> du dépôt <a href="https://github.com/gladir/DEV-COOLS">DEV-COOLS</a>. Il ajoute les destinations suivantes :

<table>
	<tr><th>Option</th><th>Description</th></tr>
	<tr><td><b>-COS2BOOT</b></td><td>Image binaire brute 8086 chargée en 07C0:0000, sans DOS (OS2BOOT).</td></tr>
	<tr><td><b>-COS2LDR</b></td><td>Image binaire brute 8086 chargée en 2000:0000, sans DOS (OS2LDR).</td></tr>
	<tr><td><b>-COS2KRNL</b></td><td>Noyau 32 bits : image PE liée à 1 Mo, assembleur 80386 natif (IN/OUT, INT, LGDT, LIDT, MOV CRn, IRETD...), procédures <i>Interrupt</i>, accès direct à Mem/MemW/MemL/Port/PortW ; les fonctions utilisées par le runtime (WriteFile, CreateFileA...) sont les procédures Pascal du noyau, exportées sous le nom DOSCALLS.DLL.</td></tr>
	<tr><td><b>-COS2</b></td><td>Destination par défaut : programme 32 bits pour OS/2-0 (CMD.EXE et les commandes), dont les importations sont liées par le noyau. Un source commençant par <code>Library</code> produit une DLL (clause <code>exports nom [Name 'externe'] [Index ordinal]</code>, jusqu'à 4095 exportations, base préférée fixée par <code>{$IMAGEBASE $00D00000}</code>, section <code>.reloc</code> produite pour que le noyau puisse la reloger ; une constante <code>Const NOM = 'texte';</code> ou entière peut aussi être exportée comme donnée) ; une fonction déclarée <code>External 'DLL' [Name 'nom']</code> est importée de cette DLL.</td></tr>
</table>

OS2PC accepte aussi la syntaxe de Free Pascal qu'utilisent les programmes écrits pour lui (comme <b>APPS/PAINT.PAS</b>, Paint) : <code>AnsiString</code> à compteur de références (<code>{$H+}</code>), <code>Int64</code> et <code>QWord</code>, <code>PByte</code>, <code>PtrUInt</code> et l'arithmétique des pointeurs, tableaux dynamiques (<code>SetLength</code>) et paramètres tableaux ouverts, types procéduraux, procédures imbriquées appelées par une procédure sœur (lien statique), <code>Try</code> ... <code>Except</code> / <code>Finally</code> et <code>Raise</code>. Ces ajouts viennent du compilateur de <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a>, un descendant d'OS2PC, et y ont été réintégrés. Comme Turbo Pascal, OS2PC signale maintenant un identificateur inconnu (au lieu d'une adresse nulle) et un identificateur déclaré deux fois dans une même portée.

<h3>Multitâche et sessions</h3>

Le noyau <b>OS2KRNL</b> est multitâche : chaque fil d'exécution est une tâche (la tâche 0 est le noyau lui-même), avec sa propre pile ; <code>CtxSwitch</code> passe de l'une à l'autre en sauvant les registres et les drapeaux. Une attente (clavier, <code>DosSleep</code>, sémaphore, fin d'un processus...) cède le processeur aux autres tâches, et le processeur s'arrête (<code>HLT</code>) quand toutes attendent. La minuterie (100 Hz) interrompt toutes les 30 ms une tâche qui exécute le code de son programme (fenêtre 00400000h-007FFFFFh) ; le noyau et les DLL, dont les données sont globales et partagées, ne sont jamais interrompus au milieu d'un appel, et un programme de Presentation Manager (dont PMWIN.DLL appelle les procédures de fenêtre) cède la main en attendant ses messages. <code>CreateProcessA</code> est asynchrone ; <code>DosExecPgm</code> attend la fin de l'enfant en <code>EXEC_SYNC</code>, la laisse à <code>DosWaitChild</code> en <code>EXEC_ASYNC</code> ou le détache (<code>EXEC_BACKGROUND</code>) ; <code>DosCreateThread</code> crée un vrai fil. La mémoire physique des processus est allouée par blocs et rendue à leur fin, quel que soit l'ordre ; le noyau gère 64 processus et 128 tâches.

Chaque <b>session</b> a son écran (tampon vidéo logique de 32 Ko), sa console (curseur, attribut, lignes réservées) et sa file du clavier. La table des pages des 4 premiers Mo est propre à chaque session : la session au premier plan voit le VGA en 000A0000h et 000B8000h, les autres écrivent dans leur tampon (les programmes, VIOCALLS et la console du noyau n'ont pas à le savoir). Les ports du VGA ne sont programmés que pour la session au premier plan (VIOCALLS, PMWIN et PMGPI le vérifient). <b>Alt+Échap</b> passe à la session suivante, <b>Ctrl+Échap</b> revient à Presentation Manager (puis, sur le bureau, ouvre la liste des fenêtres) et <b>Ctrl+Alt+Suppr</b> ouvre la boîte <a href="#securite">Sécurité d'OS/2</a> du bureau (sans bureau, il redémarre l'ordinateur). Les programmes de Presentation Manager partagent la session de PM (écran graphique, créée par le premier) ; un programme de PM lancé depuis une invite de commandes rejoint cette session, mais sa sortie standard reste dans la console de l'invite. Quand le dernier processus d'une session se termine, la session disparaît et l'écran revient à la session d'où elle a été lancée. <code>KrnTaskCtl</code> et <code>KrnSesCtl</code> (exportés par le noyau) servent DOSCALLS, PMWIN, VIOCALLS et le bureau.

<h3>Bibliothèque DOSCALLS.DLL</h3>

Le fichier <b>DLL/DOSCALLS.PAS</b> est la bibliothèque OS/2 <b>DOSCALLS.DLL</b> : elle implémente les 315 fonctions <b>Dos*</b> des API d'OS/2 1.x et 2.x : fichiers et répertoires, recherche, attributs, tuyaux anonymes et nommés, mémoire (objets, mémoire partagée, segments, sous-allocation), sémaphores (événement, mutex, MuxWait, système, RAM), minuteries, processus et processus légers, exceptions et signaux, modules et ressources, pays, pages de codes et messages, périphériques, moniteurs, etc. Elle se compile avec OS2PC (<code>Library DOSCALLS; ... exports ...</code>) en une DLL liée à 00C00000h, que le noyau charge au démarrage et partage entre tous les processus. Le noyau place chaque DLL à sa base préférée si la place est libre, sinon il la reloge (section <code>.reloc</code> produite par OS2PC) à la première place libre de la région 00800000h-00FFFFFFh (8 Mo) ; quand elle est pleine, la DLL va dans un bloc de mémoire physique pris à la demande au-delà de 16 Mo, vu à la même adresse par tous les processus. La table des modules grandit au besoin. Un programme l'utilise ainsi (convention <i>_System</i> d'OS/2) :

<pre>Function DosBeep(Freq, Duration : LongInt) : LongInt; External 'DOSCALLS';</pre>

Le programme <b>DLL/TESTDOS.PAS</b> vérifie un échantillon de ces fonctions sous OS/2-0 (59 vérifications).

<h3>Bibliothèque FKA.DLL</h3>

Le fichier <b>DLL/FKA.PAS</b> est la bibliothèque OS/2 <b>FKA.DLL</b> (<i>Function Key Area</i>, zone des touches de fonction des versions DBCS d'OS/2), liée à 00D00000h, avec ses ordinaux d'origine :

<table>
	<tr><th>Fonction</th><th>Ordinal</th><th>Description</th></tr>
	<tr><td>FKAInit</td><td>64</td><td>Initialiser la FKA pour le processus.</td></tr>
	<tr><td>QueryFKADisplayDetails</td><td>65</td><td>Détails d'affichage (forme, lignes, touches, focus, touche choisie).</td></tr>
	<tr><td>WINFKAWNDPROC</td><td>66</td><td>Procédure de fenêtre : WM_CHAR (F1-F12, flèches, Entrée), WM_PAINT, WM_DESTROY, FKAM_SETTEXT...</td></tr>
	<tr><td>WINLOADFKA</td><td>67</td><td>Charger une FKA (ressource RT_FKA ou fichier FKAnnnn.TXT).</td></tr>
	<tr><td>WINCREATEFKA</td><td>68</td><td>Créer une FKA à partir de libellés.</td></tr>
	<tr><td>WINSETFKAFORM</td><td>69</td><td>Fixer la forme : masquée, courte (1 ligne) ou longue (2 lignes).</td></tr>
	<tr><td>WINQUERYFKAFORM</td><td>70</td><td>Demander la forme.</td></tr>
	<tr><td>WINGOTOFKA</td><td>71</td><td>Donner le focus à la FKA.</td></tr>
	<tr><td>WINGOFROMFKA</td><td>72</td><td>Rendre le focus à l'application.</td></tr>
</table>

Sans Presentation Manager, la zone est dessinée en mode texte sur les dernières lignes de l'écran, retirées de la zone de défilement de la console. Le programme <b>DLL/TESTFKA.PAS</b> la vérifie (24 vérifications, et <code>TESTFKA VOIR</code> pour la parcourir au clavier).

<h3>Système de fichiers HPFS.IFS</h3>

Le fichier <b>DLL/HPFS.PAS</b> est le pilote de système de fichiers installable OS/2 <b>HPFS.IFS</b> (<i>High Performance File System</i>), lié à 00E00000h. Il utilise le vrai format HPFS sur disque : secteur d'amorce, superbloc, bloc de réserve, bitmaps par bandes de 8 Mo, bande des répertoires, fnodes, arbres B+ d'allocation (anodes), répertoires en arbres B de dnodes triés sans tenir compte de la casse (page de codes 850), noms longs (254 caractères) à casse conservée, dates de création, d'accès et d'écriture, attributs étendus (EA). Le noyau le charge d'après CONFIG.SYS :

<pre>IFS=C:\HPFS.IFS /CACHE:32 /AUTOCHECK:D /RAMDISK:4096</pre>

puis lui présente les partitions de type 07h des disques durs IDE et un disque virtuel de 4 Mo (<code>/RAMDISK</code>, formaté au démarrage). Chaque volume reconnu reçoit une lettre d'unité (D:, E:...) : CMD.EXE, DOSCALLS.DLL et tous les programmes y accèdent normalement (DIR, COPY, MD, programmes lancés depuis D:...), le noyau aiguillant les fichiers de ces unités vers les points d'entrée du pilote. Un volume mal fermé cité par <code>/AUTOCHECK</code> est vérifié et corrigé au démarrage.

Le pilote exporte les 43 points d'entrée d'un IFS d'OS/2 (adaptés à OS/2-0 : paramètres de 32 bits, convention <i>_System</i>) :

<table>
	<tr><th>Points d'entrée</th><th>Rôle</th></tr>
	<tr><td>FS_NAME, FS_ATTRIBUTE</td><td>Données exportées : nom du système de fichiers (« HPFS ») et attributs du pilote.</td></tr>
	<tr><td>FS_INIT, FS_MOUNT, FS_ATTACH, FS_FSINFO, FS_FSCTL, FS_FLUSHBUF, FS_SHUTDOWN, FS_EXIT</td><td>Initialisation, reconnaissance des volumes, nom de volume et espace libre, contrôle du pilote (formatage, vérification de type CHKDSK, statistiques), écriture des tampons, arrêt, fin de processus.</td></tr>
	<tr><td>FS_OPENCREATE, FS_CLOSE, FS_READ, FS_WRITE, FS_CHGFILEPTR, FS_NEWSIZE, FS_COMMIT, FS_FILEINFO, FS_FILEIO, FS_FILELOCKS, FS_CANCELLOCKREQUEST, FS_IOCTL</td><td>Fichiers ouverts : partage, lecture et écriture, taille, informations et EA, entrées/sorties groupées, verrous de plages, contrôle de périphérique.</td></tr>
	<tr><td>FS_PATHINFO, FS_FILEATTRIBUTE, FS_DELETE, FS_MKDIR, FS_RMDIR, FS_MOVE, FS_COPY, FS_CHDIR, FS_PROCESSNAME</td><td>Opérations par chemin : informations, attributs, suppression, répertoires, renommage et déplacement, copie avec les EA, répertoire courant, forme canonique des noms.</td></tr>
	<tr><td>FS_FINDFIRST, FS_FINDNEXT, FS_FINDFROMNAME, FS_FINDCLOSE, FS_FINDNOTIFYFIRST, FS_FINDNOTIFYNEXT, FS_FINDNOTIFYCLOSE</td><td>Recherche de fichiers (niveaux 1 à 3, avec EA) et surveillance des changements d'un répertoire.</td></tr>
	<tr><td>FS_OPENPAGEFILE, FS_ALLOCATEPAGESPACE, FS_DOPAGEIO, FS_SETSWAP</td><td>Fichier d'échange (pages de 4 Ko).</td></tr>
	<tr><td>FS_NMPIPE</td><td>Tuyaux nommés : ils ne sont pas sur un volume HPFS (ERROR_NOT_SUPPORTED, comme sous OS/2).</td></tr>
</table>

Le programme <b>DLL/TESTHPFS.PAS</b> vérifie ces points d'entrée (79 vérifications : arbre B de 150 fichiers, fichiers fragmentés à anodes, EA, verrous, copie, déplacement, cohérence du volume...).

<h3>Système de fichiers NTFS.IFS</h3>

<b>DLL/NTFS.PAS</b> produit <b>NTFS.IFS</b>, le pilote de système de fichiers installable NTFS d'OS/2-0, porté du pilote NTFS de <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a> (KERNEL/VMM32.PAS, partie 3c, et le formatage de SETUP/INSTALL.PAS). Il présente les mêmes 43 points d'entrée FS_* que HPFS.IFS (<code>FS_NAME</code> = <code>NTFS</code>) : les partitions 07h dont le secteur d'amorce porte <code>NTFS    </code> reçoivent une lettre, et CMD.EXE, DOSCALLS.DLL, le bureau et tous les programmes y lisent et y écrivent.

<table>
	<tr><th>Fonction</th><th>Détail</th></tr>
	<tr><td>Lecture</td><td>NTFS 3.x (Windows 2000, XP et suivants) : enregistrements de la MFT et leurs correctifs de secteurs, attributs résidents et non résidents (listes de runs, fichiers creux), listes d'attributs et enregistrements d'extension, répertoires (index $I30 en arbre B+, noms comparés par la table $UpCase du volume). Noms UTF-16 convertis en page de codes 850.</td></tr>
	<tr><td>Écriture</td><td>Création, écriture, troncature (résident puis non résident), renommage, déplacement, suppression, MD/RD ; bitmap des clusters et de la MFT, extension de la MFT, index reconstruits (petit index dans $INDEX_ROOT ou arbre de blocs INDX), $MFTMirr ; noms longs dans l'espace de noms POSIX (comme ntfs-3g), noms 8.3 valides dans l'espace DOS+Win32. Le journal $LogFile n'est pas tenu : il est vidé (FFh) comme le fait ntfs-3g. Bit « volume sale » de $Volume tenu ; un volume mal fermé est vérifié et réparé au montage (<code>/AUTOCHECK</code>).</td></tr>
	<tr><td>Formatage</td><td>FS_FSCTL 8000h (NTFS 3.1, clusters de 4 Ko, fichiers système, $Secure, $UpCase, journal à la taille de mkntfs) ; par le noyau : <code>KrnDiskCtl(11, disque, bloc)</code> avec le système de fichiers <code>NTFS</code> en +16 (INSTALL.EXE).</td></tr>
	<tr><td>Vérification</td><td>FS_FSCTL 8001h (comme CHKDSK) et 8002h (statistiques).</td></tr>
	<tr><td>Démarrage</td><td>OS/2-0 démarre d'un C: en NTFS : INSTALL met NTFS.IFS dans la zone d'amorçage, OS2LDR le charge (octet +48h du bloc d'information = <code>N</code>) et le noyau monte C: avec lui avant de lire CONFIG.SYS (<code>IFS=C:\NTFS.IFS /AUTOCHECK:C</code>, puis HPFS.IFS pour les autres volumes et le disque virtuel).</td></tr>
	<tr><td>Limites</td><td>Fichiers compressés ou chiffrés non lus ; attributs étendus d'OS/2 non enregistrés (ERROR_EAS_NOT_SUPPORTED) ; un fichier à liste d'attributs se lit mais ne s'écrit pas ; fichiers de 2 Go et plus en lecture seule ; heures enregistrées en heure locale ; pas de noms 8.3 générés.</td></tr>
</table>

Essais : <b>TESTNTFS</b> [unité] [GARDER | FORMATER [GRAND] | NOYAU] (DLL/TESTNTFS.PAS) vérifie les points d'entrée sur un volume préparé sous Linux (mkntfs et ntfs-3g : fichiers résidents et de 300 Ko, accents, arbre B+ de 300 fichiers, répertoire dans un enregistrement d'extension), puis sur un volume formaté par le pilote (700 fichiers, arbre B+ à trois niveaux, MFT étendue) ; chaque volume est ensuite vérifié sous Linux (ntfsfix, ntfsresize, ntfs-3g). Clusters de 512 octets à 64 Ko, volumes de 2 et 3 Go. Une installation complète sur NTFS (INSTALL.EXE), puis le démarrage du disque dur jusqu'au bureau, ont été faits sous QEMU ; le volume obtenu est validé par ntfsfix. Les volumes de référence sont ceux de mkntfs et ntfs-3g : aucun volume créé par Windows n'a été essayé.

<img width="640" height="480" alt="OS/2-0 démarré d'un disque dur en NTFS" src="IMAGE/NTFS_BUREAU.png" />

<h3>Bibliothèque VIOCALLS.DLL</h3>

Le fichier <b>DLL/VIOCALLS.PAS</b> est le sous-système vidéo OS/2 <b>VIOCALLS.DLL</b> (lié à 00F00000h), avec ses 76 fonctions et leurs ordinaux d'origine (1 VioEndPopup ... 76 XVioGetCAState ; alias VioScrollRi, VioSetCursorPos et VioScrollLe). Les programmes et les DLL d'OS/2-0 s'exécutant en anneau 0, VIOCALLS écrit directement dans la mémoire de l'écran (000B8000h) et programme le VGA par ses ports (OS2PC émet de vraies instructions IN/OUT dans les blocs asm de la cible -COS2) ; la position du curseur et l'attribut courant sont ceux de la console du noyau, si bien que VIO et WriteLn restent cohérents.

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>VioWrtCharStr, VioWrtCharStrAtt, VioWrtCellStr, VioWrtNChar, VioWrtNAttr, VioWrtNCell, VioReadCharStr, VioReadCellStr</td><td>Écriture et lecture de caractères, d'attributs et de cellules.</td></tr>
	<tr><td>VioScrollUp, VioScrollDn, VioScrollLf, VioScrollRt</td><td>Défilement d'un rectangle dans les quatre directions.</td></tr>
	<tr><td>VioWrtTty, VioGetAnsi, VioSetAnsi</td><td>Sortie télétype avec les séquences ANSI (position, déplacements, effacements, couleurs).</td></tr>
	<tr><td>VioGetCurPos, VioSetCurPos, VioGetCurType, VioSetCurType</td><td>Position et forme du curseur (registres du CRTC).</td></tr>
	<tr><td>VioGetMode, VioSetMode, VioGetConfig, VioGetState, VioSetState, VioGetFont, VioSetFont, VioGetCp, VioSetCp</td><td>Mode texte 80 x 25 et modes graphiques du VGA : 640 x 480 x 16 (12h), 640 x 480 x 2 (11h), 640 x 350 x 16 (10h), 640 x 200 x 16 (0Eh), 320 x 200 x 16 (0Dh), 320 x 200 x 256 (13h), mémoire en 000A0000h par VioGetPhysBuf (les fonctions du mode texte rendent alors ERROR_VIO_MODE ; le retour au texte recharge la police et la palette) ; configuration, palette, registres de couleur, bordure, clignotement, soulignement, police du générateur de caractères, page de codes. Modes VESA du BIOS de la carte (VBE, par le noyau) : toute résolution proposée (800 x 600, 1024 x 768, 1280 x 1024...) en 256 couleurs ou en couleurs directes (15, 16, 24, 32 bits), mémoire linéaire ; ordinaux internes VIOQUERYMODES (1002) et VIOQUERYVBE (1003).</td></tr>
	<tr><td>VioGetBuf, VioShowBuf, VioGetPhysBuf</td><td>Tampon vidéo logique (LVB) et accès au tampon physique.</td></tr>
	<tr><td>VioPopUp, VioEndPopup, VioScrLock, VioScrUnlock, VioSavRedrawWait, VioSavRedrawUndo, VioModeWait, VioModeUndo, VioSave, VioRestore, VioSswSwitch, VioRedrawSize, VioSrfBlock, VioSrfUnblock</td><td>Fenêtres surgissantes, verrou de l'écran, attentes du gestionnaire de sessions, sauvegarde, bascule et blocage de l'affichage.</td></tr>
	<tr><td>VioPrtSc, VioPrtScToggle, Avs_Prtsc, Avs_PrtscToggle</td><td>Impression et capture de l'écran (fichier C:\PRTSC.TXT, copie de la sortie télétype).</td></tr>
	<tr><td>VioRegister, VioGlobalReg, VioDeRegister</td><td>Remplacement de fonctions par un sous-système vidéo chargé depuis une DLL.</td></tr>
	<tr><td>VioCreatePS, VioDestroyPS, VioAssociate, VioShowPS, VioSetOrg, VioGetOrg, VioCreateLogFont, VioDeleteSetId, VioQuerySetIds, VioQueryFonts, VioGetDeviceCellSize, VioSetDeviceCellSize, VioGetPSAddress</td><td>Espaces de présentation AVIO (cellules de 2 ou 4 octets), affichés à l'écran une fois associés ; associés au DC d'une fenêtre de PM (WinOpenWindowDC), ils sont dessinés dans la fenêtre (cellule VioSetOrg en haut à gauche) et chaque écriture y apparaît aussitôt. Ordinaux internes VIOAVIOSIZE (1004, taille de la fenêtre gardée dans les PS d'un DC, appelé par WinDefAVioWindowProc) et VIOQUERYAVIOSIZE (1005).</td></tr>
	<tr><td>VioInit, VioShellInit, VioHetInit, VioFree, VioQueryConsole</td><td>Initialisation, remise à l'état d'origine du VGA, libération des ressources d'un processus, état de la console.</td></tr>
	<tr><td>VioCheckCharType, XVioCheckCharType, XVioCreateCA, XVioDestroyCA, XVioSetCAState, XVioGetCAState</td><td>Caractères à double octet (pages de codes 932, 936, 942, 949, 950) et jeux d'attributs étendus.</td></tr>
</table>

Le programme <b>DLL/TESTVIO.PAS</b> vérifie ces fonctions (127 vérifications, relues par VIO, directement dans la mémoire de l'écran et dans les registres du VGA, dont les modes graphiques) avec la DLL de remplacement <b>DLL/TESTVIOR.PAS</b>.

<h3>Bibliothèque MOUCALLS.DLL</h3>
 La <b>molette</b> d'une souris PS/2 IntelliMouse est reconnue (paquets de 4 octets) : MouReadEventQue rend les événements $0100 (cran vers le haut) et $0200 (cran vers le bas) quand le masque des événements (MouSetEventMask, jusqu'à $37F) les demande, et PMWIN les change en <code>WM_VSCROLL</code> pour la fenêtre sous le pointeur.
Le fichier <b>DLL/MOUCALLS.PAS</b> est le sous-système souris OS/2 <b>MOUCALLS.DLL</b> (lié à 00F40000h), avec ses 29 fonctions et leurs ordinaux d'origine (1 MouGetPtrShape ... 30 MouSetThreshold). Le noyau reçoit les paquets de la souris PS/2 (IRQ 12, port auxiliaire du 8042) et les met à disposition par KrnMouRead ; MOUCALLS en fait des événements et dessine le pointeur dans l'écran texte. Quand l'écran est en mode graphique (VioSetMode), les lignes et colonnes rapportées sont des pels (0 à 479 et 0 à 639 en 640 x 480) et le pointeur est dessiné par le programme (PMWIN.DLL pour Presentation Manager).

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>MouOpen, MouClose, MouFree, MouShellInit, MouInitReal, MouSynch</td><td>Ouverture et fermeture de la souris, libération, initialisation de l'interpréteur, pilote de pointeur, accès synchronisé.</td></tr>
	<tr><td>MouReadEventQue, MouGetNumQueEl, MouFlushQue, MouGetEventMask, MouSetEventMask</td><td>File de 64 événements (déplacements et boutons, avec ou sans attente) et masque des événements rapportés.</td></tr>
	<tr><td>MouGetPtrPos, MouSetPtrPos, MouGetPtrShape, MouSetPtrShape, MouDrawPtr, MouRemovePtr</td><td>Position du pointeur (ligne, colonne), forme (masques ET et OU exclusif de la cellule), dessin et zone d'exclusion.</td></tr>
	<tr><td>MouGetScaleFact, MouSetScaleFact, MouGetThreshold, MouSetThreshold, MouGetNumMickeys, MouGetNumButtons</td><td>Facteurs d'échelle (mickeys par 8 pels), seuils d'accélération, résolution et nombre de boutons.</td></tr>
	<tr><td>MouGetDevStatus, MouSetDevStatus, MouGetHotKey, MouSetHotKey</td><td>État du périphérique (pointeur désactivé, déplacements en mickeys) et boutons de la touche de session.</td></tr>
	<tr><td>MouRegister, MouDeRegister</td><td>Remplacement de fonctions par un sous-système souris chargé depuis une DLL.</td></tr>
</table>

Le programme <b>DLL/TESTMOU.PAS</b> vérifie ces fonctions (60 vérifications ; la seconde partie attend des événements de la souris, envoyés sous QEMU par <code>mouse_move</code> et <code>mouse_button</code>).

<h3>Bibliothèque NLS.DLL</h3>

Le fichier <b>DLL/NLS.PAS</b> est la bibliothèque OS/2 <b>NLS.DLL</b> (langues nationales, liée à 00D40000h), avec ses 8 fonctions et leurs ordinaux d'origine. Elle contient les données du fichier de pays d'OS/2 pour 29 pays et les pages de codes 437, 850, 852, 857, 860, 861, 863, 865, 866 ainsi que les pages à double octet 932, 942, 936, 949 et 950.

<table>
	<tr><th>Fonction</th><th>Ordinal</th><th>Description</th></tr>
	<tr><td>DosCaseMap</td><td>1</td><td>Conversion en majuscules (OS/2 1.x, COUNTRYCODE de 16 bits).</td></tr>
	<tr><td>DosGetCollate</td><td>2</td><td>Table de tri (OS/2 1.x).</td></tr>
	<tr><td>DosGetCtryInfo</td><td>3</td><td>Informations du pays (COUNTRYINFO de 16 bits, 38 octets).</td></tr>
	<tr><td>DosGetDBCSEv</td><td>4</td><td>Vecteur des octets de tête DBCS (OS/2 1.x).</td></tr>
	<tr><td>DosQueryCtryInfo</td><td>5</td><td>Informations du pays (COUNTRYINFO de 32 bits, 44 octets) : date, heure, monnaie, séparateurs.</td></tr>
	<tr><td>DosQueryDBCSEnv</td><td>6</td><td>Vecteur des octets de tête DBCS.</td></tr>
	<tr><td>DosMapCase</td><td>7</td><td>Conversion en majuscules selon le pays et la page de codes (lettres accentuées, turc, cyrillique ; octets de queue DBCS gardés).</td></tr>
	<tr><td>DosQueryCollate</td><td>8</td><td>Table de tri (accents ignorés, ordre scandinave des lettres Æ, Ø, Å, Ä, Ö).</td></tr>
</table>

Le programme <b>DLL/TESTNLS.PAS</b> vérifie ces fonctions (31 vérifications).

<h3>Bibliothèque KBDCALLS.DLL</h3>

Le fichier <b>DLL/KBDCALLS.PAS</b> est le sous-système clavier OS/2 <b>KBDCALLS.DLL</b> (lié à 00C80000h), avec ses 25 fonctions et leurs ordinaux d'origine (1 KbdSetCustXt ... 25 KbdSetHWId). Le noyau range chaque frappe (IRQ 1) avec l'état des touches de changement d'état et l'heure, et la met à disposition par KrnKbdRead et KrnKbdCtl ; KBDCALLS la traduit avec la table du clavier logique (codes étendus 00h ou E0h compatibles avec le BIOS et OS/2).

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>KbdCharIn, KbdPeek, KbdFlushBuffer</td><td>Lecture d'un caractère (KBDKEYINFO, avec ou sans attente), consultation sans retrait, vidage du tampon.</td></tr>
	<tr><td>KbdStringIn</td><td>Lecture d'une chaîne : en mode ASCII avec édition (Retour arrière, Échap, gabarit F1 et F3) et écho, en mode binaire caractère par caractère.</td></tr>
	<tr><td>KbdGetStatus, KbdSetStatus</td><td>Écho, mode ASCII ou binaire, caractère de fin (1 ou 2 octets), rapport des touches de changement d'état, verrouillages (avec les voyants).</td></tr>
	<tr><td>KbdOpen, KbdClose, KbdGetFocus, KbdFreeFocus</td><td>Claviers logiques et attribution du clavier physique.</td></tr>
	<tr><td>KbdGetCp, KbdSetCp, KbdSetCustXt, KbdXlate</td><td>Page de codes, table de traduction personnalisée, traduction d'un code de balayage.</td></tr>
	<tr><td>KbdGetHWId, KbdSetHWId</td><td>Identification du clavier (AB41h, clavier étendu).</td></tr>
	<tr><td>KbdRegister, KbdDeRegister</td><td>Remplacement de fonctions par un sous-système clavier chargé depuis une DLL.</td></tr>
	<tr><td>KbdInit, KbdShellInit, KbdLoadInstance, KbdSwitchFgnd, KbdSetFgnd, KbdFree, KbdSynch</td><td>Initialisation de la session et de l'interpréteur, premier plan, libération des ressources d'un processus, accès synchronisé.</td></tr>
</table>

Le programme <b>DLL/TESTKBD.PAS</b> vérifie ces fonctions (97 vérifications ; la seconde partie lit des touches, envoyées sous QEMU par <code>sendkey</code>).

<h3>Bibliothèque MONCALLS.DLL</h3>

Le fichier <b>DLL/MONCALLS.PAS</b> est la bibliothèque OS/2 <b>MONCALLS.DLL</b> des moniteurs de périphériques (liée à 00CB0000h), avec ses 5 fonctions et leurs ordinaux d'origine. Un moniteur s'insère dans le flux de données d'un périphérique de caractères : le noyau détourne vers la chaîne des moniteurs les frappes du clavier (KBD$, avant KBDCALLS et la console), les paquets de la souris (MOUSE$, avant MOUCALLS) et les données écrites sur l'imprimante (LPT1 à LPT3 et PRN, avant le port parallèle) ; chaque moniteur peut modifier, supprimer ou ajouter des paquets. Les fonctions DosMon* de DOSCALLS.DLL sont transmises à MONCALLS.DLL.

<table>
	<tr><th>Fonction</th><th>Ordinal</th><th>Description</th></tr>
	<tr><td>DosMonWrite</td><td>1</td><td>Rendre un paquet au flux par le tampon de sortie : il passe au moniteur suivant, ou au périphérique après le dernier.</td></tr>
	<tr><td>DosMonRead</td><td>2</td><td>Lire le paquet suivant de la chaîne dans le tampon d'entrée (avec ou sans attente).</td></tr>
	<tr><td>DosMonClose</td><td>3</td><td>Terminer la surveillance (les paquets en attente continuent vers le périphérique).</td></tr>
	<tr><td>DosMonOpen</td><td>4</td><td>Ouvrir KBD$, MOUSE$, LPT1 à LPT3 ou PRN pour le surveiller.</td></tr>
	<tr><td>DosMonReg</td><td>5</td><td>Enregistrer les tampons d'entrée et de sortie (MONIN, MONOUT) au début, à la fin ou à la place par défaut de la chaîne.</td></tr>
</table>

Le programme <b>DLL/TESTMON.PAS</b> vérifie ces fonctions (52 vérifications : chaîne de trois moniteurs de l'imprimante, touches modifiées, supprimées ou ajoutées, déplacement de la souris doublé).

<h3>Bibliothèque MSG.DLL</h3>

Le fichier <b>DLL/MSG.PAS</b> est la bibliothèque OS/2 <b>MSG.DLL</b> des messages (liée à 00D80000h), avec ses 9 points d'entrée et leurs ordinaux d'origine. Elle lit les fichiers de messages d'OS/2 au format MKMSGF (index de mots ou de doubles mots, types E, W, I, H, P), cherche le fichier dans le chemin indiqué, le répertoire courant, DPATH, C:\ et C:\OS2\SYSTEM, garde les fichiers ouverts jusqu'à DosCloseMessageFile et consulte d'abord un segment de messages en mémoire s'il est fourni. Les principaux messages système (OSO001.MSG) y sont intégrés. Les fonctions de messages de DOSCALLS.DLL (DosGetMessage, DosInsertMessage, DosPutMessage, DosQueryMessageCP...) lui sont transmises.

<table>
	<tr><th>Fonction</th><th>Ordinal</th><th>Description</th></tr>
	<tr><td>Dos16PutMessage, DosPutMessage (Dos32PutMessage)</td><td>1, 5</td><td>Écrire un message dans un fichier ou à l'écran (lignes coupées entre les mots à 80 colonnes).</td></tr>
	<tr><td>Dos16TrueGetMessage, DosTrueGetMessage (Dos32TrueGetMessage)</td><td>2, 6</td><td>Lire un message (préfixe « SYS0002: » des erreurs et avertissements, %0 sans fin de ligne) et y insérer les variables %1 à %9 ; message d'erreur SYS0317, SYS0318 ou SYS0319 si le message ou le fichier est introuvable.</td></tr>
	<tr><td>DosInsMessage, DosInsertMessage (Dos32InsertMessage)</td><td>3, 4</td><td>Insérer les variables %1 à %9 dans un message en mémoire.</td></tr>
	<tr><td>Dos16IQueryMessageCP, DosIQueryMessageCP (Dos32IQueryMessageCP)</td><td>7, 8</td><td>Pages de codes et langue d'un fichier de messages.</td></tr>
	<tr><td>DosCloseMessageFile (Dos32CloseMessageFile)</td><td>9</td><td>Fermer un fichier de messages gardé ouvert.</td></tr>
</table>

Les points d'entrée d'OS/2 1.x (Dos16*, DosInsMessage) rendent les longueurs dans un mot, ceux d'OS/2 2.x dans un double mot. Le programme <b>DLL/TESTMSG.PAS</b> vérifie ces fonctions (45 vérifications, avec des fichiers de messages qu'il fabrique sur le disque virtuel HPFS).

<h3>Bibliothèque NAMPIPES.DLL</h3>

Le fichier <b>DLL/NAMPIPES.PAS</b> est la bibliothèque OS/2 <b>NAMPIPES.DLL</b> des tuyaux nommés (liée à 00DB0000h), avec ses 14 fonctions et leurs ordinaux d'origine. Elle gère les instances multiples d'un même nom (\PIPE\nom), les tuyaux d'octets et de messages (chaque message précédé d'un en-tête de 2 octets), l'accès entrant, sortant ou bidirectionnel, le mode bloquant et le mode de lecture propres à chaque bout, et les sémaphores attachées (système ou d'événement). Les handles des tuyaux sont ceux de DOSCALLS.DLL : DosOpen (client), DosRead, DosWrite et DosClose s'y appliquent, et les fonctions DosXxxNPipe d'OS/2 2.x de DOSCALLS.DLL lui sont transmises.

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>DosMakeNmPipe, DosConnectNmPipe, DosDisConnectNmPipe, DosWaitNmPipe</td><td>Création d'une instance (créée à l'écoute), attente d'un client, déconnexion, attente d'une instance libre.</td></tr>
	<tr><td>DosQNmPipeInfo, DosQNmPHandState, DosSetNmPHandState</td><td>Informations (PIPEINFO), état du handle, mode bloquant et mode de lecture (octets ou messages).</td></tr>
	<tr><td>DosPeekNmPipe, DosRawReadNmPipe, DosRawWriteNmPipe</td><td>Lecture sans retrait (AVAILDATA, état), lecture et écriture brutes (avec les en-têtes des messages).</td></tr>
	<tr><td>DosTransactNmPipe, DosCallNmPipe</td><td>Transaction sur un tuyau de messages bidirectionnel, appel (ouverture, transaction, fermeture).</td></tr>
	<tr><td>DosSetNmPipeSem, DosQNmPipeSemState</td><td>Sémaphore libérée quand des données arrivent, que de la place se libère ou que l'autre bout ferme ; état (PIPESEMSTATE).</td></tr>
</table>

Les processus s'exécutant un à la fois, une opération qui devrait attendre l'autre bout rend aussitôt une erreur (ERROR_NO_DATA, ERROR_PIPE_NOT_CONNECTED ou ERROR_SEM_TIMEOUT). Le programme <b>DLL/TESTNMP.PAS</b> vérifie ces fonctions (58 vérifications).

<h3>Bibliothèque SESMGR.DLL</h3>

Le fichier <b>DLL/SESMGR.PAS</b> est le gestionnaire de sessions OS/2 <b>SESMGR.DLL</b> (lié à 00FA0000h), avec ses 41 points d'entrée et leurs ordinaux d'origine (1 DosSMSGDoPopup ... 41 DosRegisterNotification ; QhKeybdHandle et QhMouseHandle sont des données). La session 1 est celle de CMD.EXE. Une session démarrée au premier plan exécute aussitôt son programme sur un écran propre ; à sa fin, l'écran, le curseur et le clavier de la session d'origine sont rendus. Une session démarrée en arrière-plan attend d'être choisie pour s'exécuter.

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>DOSSTARTSESSION, DOSSELECTSESSION, DOSSETSESSION, DOSSTOPSESSION, Dos32StartSession, Dos32SelectSession, Dos32SetSession, Dos32StopSession</td><td>Démarrage (STARTDATA : session enfant ou indépendante, premier plan ou arrière-plan, type, PgmControl dont SSF_CONTROL_NOAUTOCLOSE, ObjectBuffer), choix, réglage (sélectionnable, liée) et arrêt des sessions enfants.</td></tr>
	<tr><td>DosSMInitialize, DosSMStart, DosSMSwitch, DosSMTerminate, DosSMGetStatus, DosSMSetSessionType, DosSMParentSwitch, DosSetMNLockTime, DosGetTimes</td><td>Interpréteur propriétaire du gestionnaire : sessions de premier niveau, bascule, fin, état des sessions, type, retour au parent, durée minimale au premier plan.</td></tr>
	<tr><td>DosSMGetAppReq, DosSMServeAppReq, DosSMDoAppReq</td><td>Demandes des applications : tant qu'un interpréteur est propriétaire, les DosStartSession, DosSelectSession, DosSetSession et DosStopSession des autres processus lui sont confiés.</td></tr>
	<tr><td>DosSMSetTitle, DosSMPause, DosSMRealPrtSc, DosSMPMPresent</td><td>Titre de la session, pause (Ctrl+Verr num), impression de l'écran, présence de Presentation Manager (absent).</td></tr>
	<tr><td>DosSMSGDoPopup, DosSMSGEndPopup, DosScrLock, DosScrUnlock, DosSavRedrawWait, DosSavRedrawUndo, DosModeWait, DosModeUndo</td><td>Fenêtres surgissantes, verrou de l'écran et processus légers de sauvegarde et de retraçage (VIOCALLS.DLL).</td></tr>
	<tr><td>DOSSMREGISTERDD, DosSMOpenDD, DosSMNotifyDD, DosSMNotifyDD2, DosSMHDEInit, DosSMSysInit, DosRegisterNotification</td><td>Pilotes avertis des changements de session (KBD$ : KbdSwitchFgnd), HARDERR, DLL appelées à chaque démarrage, fin, passage au premier plan ou changement de titre.</td></tr>
</table>

Le programme <b>DLL/TESTSES.PAS</b> vérifie ces fonctions (59 vérifications ; ses sessions enfants exécutent TESTSES lui-même).

<h3>Bibliothèque QUECALLS.DLL</h3>

Le fichier <b>DLL/QUECALLS.PAS</b> est la bibliothèque OS/2 <b>QUECALLS.DLL</b> des files d'attente (liée à 00E70000h), avec ses 16 fonctions et leurs ordinaux d'origine : les 8 points d'entrée d'OS/2 1.x (1 DosReadQueue ... 8 DosCreateQueue) et leurs équivalents 32 bits (9 Dos32ReadQueue ... 16 Dos32CreateQueue). Le processus qui crée une file (\QUEUES\nom) en est le propriétaire et le seul à la lire ; les autres l'ouvrent pour y écrire. Les éléments (code de requête, longueur, adresse des données, priorité) sont lus selon l'ordre de la file : FIFO, LIFO ou par priorités (15 la plus haute). DosPeekQueue rend un code d'élément que DosReadQueue peut lire ensuite ; une sémaphore (1.x : DosSemClear, 2.x : DosPostEventSem) est signalée à chaque élément ajouté. Les points d'entrée 1.x rendent QUEUERESULT (deux mots), ceux de 2.x REQUESTDATA (deux doubles mots). SESMGR.DLL y écrit la fin des sessions enfants (TermQ).

Le programme <b>DLL/TESTQUE.PAS</b> vérifie ces fonctions (31 vérifications, avec un écrivain d'un autre processus et la file de fin d'une session).

<h3>Bibliothèque SPOOLCP.DLL</h3>

Le fichier <b>DLL/SPOOLCP.PAS</b> est la bibliothèque OS/2 <b>SPOOLCP.DLL</b>, le commutateur de polices des imprimantes (liée à 00EA0000h), avec ses 5 fonctions et leurs ordinaux d'origine. Pour chaque imprimante (PRN, LPT1 à LPT3), elle connaît les polices résidentes et celles d'un fichier de polices, et pour chaque fichier ouvert vers l'imprimante (handle du port ou fichier de spoule) la page de codes et la police actives. Activer une police écrit sur ce handle la séquence de commande qui la choisit, précédée la première fois des données à télécharger dans l'imprimante.

<table>
	<tr><th>Fonction</th><th>Ordinal</th><th>Description</th></tr>
	<tr><td>DosPFSCloseUser</td><td>1</td><td>Le fichier est fermé : sa page de codes et sa police actives sont oubliées.</td></tr>
	<tr><td>DosPFSQueryAct</td><td>2</td><td>Page de codes et police actives d'un fichier.</td></tr>
	<tr><td>DosPFSInit</td><td>3</td><td>Installer le commutateur d'une imprimante : polices résidentes (HWFONTS) et fichier de polices.</td></tr>
	<tr><td>DosPFSActivate</td><td>4</td><td>Activer une page de codes et une police (téléchargement, puis séquence de choix).</td></tr>
	<tr><td>DosPFSVerifyFont</td><td>5</td><td>La page de codes et la police sont-elles disponibles ?</td></tr>
</table>

Le fichier de polices est un fichier texte propre à OS/2-0 (lignes TYPE, FONT et LOAD, octets en hexadécimal), et non le format .DCP d'IBM. Le programme <b>DLL/TESTPFS.PAS</b> vérifie ces fonctions (26 vérifications ; avec QEMU, <code>-parallel file:</code> recueille les séquences envoyées à LPT1).

<h3>Bibliothèque RMINFO.DLL</h3>

Le fichier <b>DLL/RMINFO.PAS</b> est la bibliothèque OS/2 <b>RMINFO.DLL</b> du gestionnaire de ressources (Resource Manager, liée à 00800000h), avec ses 34 points d'entrée et leurs ordinaux d'origine (les fonctions _RMxxx sont les seconds points d'entrée des fonctions RMxxx). Elle tient l'arbre des pilotes, adaptateurs, périphériques détectés et ressources matérielles (ports d'entrée/sortie, interruptions, mémoire, DMA, minuteries) ; une ressource exclusive ne peut être allouée deux fois, une ressource partagée ou multiplexée peut l'être par plusieurs pilotes du même mode. Au chargement, l'arbre décrit le matériel géré par le noyau (pilote OS2KRNL : contrôleur d'interruptions, minuterie, horloge, clavier, souris, IDE, VGA, ports COM et LPT présents) avec leurs identificateurs PnP (PNP0303...).

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>RMCreateDriver, RMDestroyDriver</td><td>Inscription d'un pilote (DRIVERSTRUCT) ; sa destruction retire ses adaptateurs, périphériques et ressources.</td></tr>
	<tr><td>RMAllocResource, RMDeallocResource</td><td>Allocation (RESOURCESTRUCT : exclusive, partagée ou multiplexée) et libération des ressources.</td></tr>
	<tr><td>RMCreateAdapter, RMDestroyAdapter, RMCreateDetected, RMDestroyDetected</td><td>Adaptateurs (éventuellement imbriqués) et périphériques détectés, avec leurs ressources (AHRESOURCE).</td></tr>
	<tr><td>RMEnumNodes, RMGetNodeInfo, RMHandleToResourceHandleList, RMDevIDToHandleList</td><td>Énumération des nœuds, informations d'un nœud, ressources d'un nœud, recherche par identificateurs (HANDLELIST).</td></tr>
	<tr><td>RMConvertID</td><td>Identificateur EISA/PnP compressé ↔ texte (0303D041h ↔ PNP0303).</td></tr>
	<tr><td>RMGetSnoopLevel, RMSetSnoopLevel, RMSaveDetectedData, RMDeleteDetectedData</td><td>Niveau de détection du matériel ; sauvegarde des périphériques détectés (C:\RMDETECT.DAT).</td></tr>
</table>

Le programme <b>DLL/TESTRM.PAS</b> vérifie ces fonctions (37 vérifications ; <code>TESTRM LISTE</code> affiche l'arbre).

<h3>Bibliothèque OS2SM.DLL</h3>

Le fichier <b>DLL/OS2SM.PAS</b> est la bibliothèque OS/2 <b>OS2SM.DLL</b> (liée à 00850000h), la partie « gestion des sessions » de l'interpréteur de Presentation Manager, avec ses 46 points d'entrée et leurs ordinaux d'origine (1 à 45 et la donnée SHELLWINDOW, ordinal 103). Elle tient la liste des tâches (switch list : structures SWCNTRL, SWENTRY et SWBLOCK) et s'appuie sur SESMGR.DLL : une entrée désigne une session, la choisir l'exécute. OS2SM s'inscrit auprès de SESMGR (DosRegisterNotification, point d'entrée interne OS2SMNOTIFY, ordinal 200) : chaque session démarrée reçoit une entrée, une session terminée quitte la liste et la session courante est suivie. OS/2-0 n'a pas Presentation Manager : les handles de fenêtres sont conservés tels quels et un programme PM (PROG_PM) est refusé.

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>WinInitSessionMgr</td><td>Le processus devient l'interpréteur propriétaire du gestionnaire de sessions (DosSMInitialize).</td></tr>
	<tr><td>WinAddSwitchEntry, WinCreateSwitchEntry, WinChangeSwitchEntry, WinSetSwEntry, WinQuerySwitchEntry, WinRemoveSwitchEntry, WinInitSwEntry, WinQuerySwitchHandle, WinQuerySwitchList</td><td>Entrées de la liste des tâches (HSWITCH : indice et génération ; un handle périmé est refusé).</td></tr>
	<tr><td>WinSwitchToProgram, WinSwitchToProgram2, WinSwitchToTaskManager, WinSetFgndWindow, WinProcessHotKey</td><td>Passage d'un programme à l'autre (DosSMSwitch ; Ctrl+Échap, Alt+Échap et Alt+Tab).</td></tr>
	<tr><td>SheStartProgram, SheStartLongProgram, WinInstStartApp, WinExecProgram</td><td>Démarrage d'un programme dans une session (STARTDATA, PROGDETAILS) ou dans la session courante (DosExecPgm).</td></tr>
	<tr><td>WinEndProgram, WinStopProgram, WinEndWindowSession, WinTerminateApp, WinInitSession, WinEndSession</td><td>Fin d'un programme ou d'une session et de ses entrées.</td></tr>
	<tr><td>WinQueryTaskTitle, WinQuerySessionTitle, WinSetTitle, WinQueryTaskSizePos, WinQueryExtIdFocus, WinSetExtIdFocus</td><td>Titres, taille et position (SWP) des tâches ; focus du clavier étendu.</td></tr>
	<tr><td>SheInitializeIniFile, StartSystemExecutables, ShlLoadPublicFonts, ShlUnloadPublicFonts, WinSave</td><td>Fichier de l'interpréteur C:\OS2SM.INI (lignes RUN= et FONT=, section [Bureau]).</td></tr>
	<tr><td>SheSystemShutdown, WinNoShutdown</td><td>Arrêt du système (bureau sauvé, tampons vidés), qui peut être empêché.</td></tr>
	<tr><td>WinStpRegister, WinSwitchProgramRegister, WinCplRegister, WinPMFileRegister, LPFNSHELLWNDPROC, LPFNICONWNDPROC, FNBADAPPDLGPROC</td><td>Inscriptions de fenêtres et de modules ; procédures de fenêtre de l'interpréteur.</td></tr>
</table>

Le programme <b>DLL/TESTSM.PAS</b> vérifie ces fonctions (62 vérifications ; les sessions exécutent <code>TESTSM KID titre</code>).

<h3>Bibliothèque HELPMGR.DLL</h3>

Le fichier <b>DLL/HELPMGR.PAS</b> est la bibliothèque OS/2 <b>HELPMGR.DLL</b> (liée à 00880000h), le gestionnaire d'aide IPF (Information Presentation Facility), avec ses 6 points d'entrée et leurs ordinaux d'origine (51 à 56, ceux qu'importent les programmes d'OS/2 comme l'installation d'IBM Works). Une application crée une instance d'aide à partir d'une structure HELPINIT (titre, tutoriel, bibliothèques .HLP, table d'aide), puis l'associe à ses fenêtres cadres. Les bibliothèques sont cherchées telles quelles, dans le répertoire courant, dans la variable HELP (<code>SET HELP=D:\AIDE;</code> dans le CONFIG.SYS du CD-ROM) puis dans C:\ ; un fichier .HLP commence par la signature HSP. OS/2-0 n'a pas Presentation Manager : les handles de fenêtres sont conservés tels quels.

<table>
	<tr><th>Fonction</th><th>Rôle</th></tr>
	<tr><td>WinCreateHelpInstance</td><td>Créer une instance d'aide (HELPINIT ; erreur dans ulReturnCode : HMERR_OPEN_LIB_FILE, HMERR_INVALID_LIB_FILE, HMERR_HELPTABLE_UNDEFINE, HMERR_NO_MEMORY).</td></tr>
	<tr><td>WinDestroyHelpInstance</td><td>Détruire une instance (ses associations sont retirées).</td></tr>
	<tr><td>WinAssociateHelpInstance, WinQueryHelpInstance</td><td>Associer une instance à une fenêtre cadre (instance nulle : retirer l'association) ; instance d'une fenêtre.</td></tr>
	<tr><td>WinCreateHelpTable, WinLoadHelpTable</td><td>Remplacer la table d'aide d'une instance : HELPTABLE et HELPSUBTABLE en mémoire (copiées), ou ressources RT_HELPTABLE et RT_HELPSUBTABLE d'un module (DosGetResource).</td></tr>
</table>

Deux points d'entrée internes à OS/2-0 donnent ce qu'IPF ferait à la touche F1 : HMQUERYPANELID (ordinal 100 : panneau d'aide d'une fenêtre selon la table d'aide) et HMQUERYINSTANCEINFO (ordinal 101). Le programme <b>DLL/TESTHLP.PAS</b> vérifie ces fonctions (29 vérifications ; OS2PC ne produisant pas de ressources, le module de WinLoadHelpTable est une image PE construite en mémoire).

<h3>Bibliothèque LIBUNI.DLL</h3>

Le fichier <b>DLL/LIBUNI.PAS</b> est la bibliothèque OS/2 <b>LIBUNI.DLL</b> (liée à 00900000h), les services Unicode et de locales (ULS, Universal Language Support), avec ses 78 points d'entrée et leurs ordinaux d'origine. Les chaînes sont en UniChar (UCS-2) ; les tables des caractères (attributs, majuscules et minuscules, valeurs numériques, classes bidirectionnelles, décompositions canoniques) couvrent le plan multilingue de base et sont générées à partir de la base Unicode 15.1. Douze locales sont fournies : C, POSIX, UNIVERSAL, en_US, en_GB, fr_FR, fr_CA, de_DE, es_ES, it_IT, nl_NL et pt_BR (jours, mois, formats des dates et des heures, nombres, monnaie, noms des langues et des pays) ; le nom vide désigne la locale par défaut (variables LC_ALL, LC_xxx, LANG, puis la fonction Locale).

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>UniCreateLocaleObject, UniFreeLocaleObject, UniQueryLocaleObject, UniLocaleStrToToken, UniLocaleTokenToStr, UniMapCtryToLocale, Locale</td><td>Objets locales (nom, jeton, code de pays ; catégories LC_*).</td></tr>
	<tr><td>UniQueryLocaleItem, UniQueryLocaleValue, UniQueryLocaleInfo, UniFreeLocaleInfo, UniFreeMem</td><td>Éléments des locales (136 LocaleItem), structure UniLconv.</td></tr>
	<tr><td>UniQueryAlpha... UniQueryXdigit, UniQueryChar, UniQueryAttr, UniCreateAttrObject, UniQueryCharAttr, UniScanForAttr, UniFreeAttrObject</td><td>Attributs des caractères (CT_*).</td></tr>
	<tr><td>UniQueryCharType, UniQueryCharTypeTable, UniQueryStringType, UniQueryNumericValue</td><td>Types UNICTYPE (classe, bidi, écriture, attributs étendus, pages de codes), valeur numérique.</td></tr>
	<tr><td>UniToupper, UniTolower, UniTransUpper, UniTransLower, UniStrupr, UniStrlwr</td><td>Majuscules et minuscules.</td></tr>
	<tr><td>UniStrcat... UniStrtok (21 fonctions)</td><td>Chaînes UniChar.</td></tr>
	<tr><td>UniStrcoll, UniStrxfrm, UniMakeKey, UniGetColval</td><td>Collation à trois niveaux (lettre, accent, casse).</td></tr>
	<tr><td>UniCreateTransformObject, UniTransformStr, UniFreeTransformObject, UniProcessUconv</td><td>Transformations (upper, lower, compose, decompose, hiragana, katakana, fullwidth, halfwidth) ; page de codes 437 ou 850 vers Unicode.</td></tr>
	<tr><td>UniStrtol, UniStrtoul, UniStrtod, UniStrftime, UniStrptime, UniStrfmon</td><td>Nombres, dates et heures, montants selon la locale.</td></tr>
	<tr><td>UniMakeUserLocale, UniSetUserLocaleItem, UniGetOverride, UniDeleteUserLocale, UniCompleteUserLocale, UniQueryLocaleList, UniQueryLanguageName, UniQueryCountryName</td><td>Locales de l'utilisateur (C:\USERLOC.INI), liste des locales, noms des langues et des pays.</td></tr>
</table>

UniMakeKey, UniGetColval, UniGetOverride, UniProcessUconv et Locale ne sont pas documentées par IBM : leur rôle est décrit dans le source. Le programme <b>DLL/TESTUNI.PAS</b> vérifie ces fonctions (107 vérifications).

<h3>Bibliothèque PMDRAG.DLL</h3>

Le fichier <b>DLL/PMDRAG.PAS</b> est la bibliothèque OS/2 <b>PMDRAG.DLL</b> (liée à 00A00000h), la manipulation directe (glisser-déposer) de Presentation Manager, avec ses 76 points d'entrée : ordinaux 1 à 31 (points d'entrée 16 bits, noms en majuscules) et 32 à 62 (32 bits) pour les 31 fonctions de base, 63 à 66 pour DrgDragFiles et DrgAcceptDroppedFiles, 67 à 76 pour le glissement différé et les fonctions de Warp. OS/2-0 n'a pas Presentation Manager : PMDRAG tient un registre de fenêtres (point d'entrée interne DRGREGISTERWINDOW : handle, rectangle de l'écran en pels, procédure de fenêtre _System ou Pascal d'OS2PC) qui reçoivent les messages DM_* ; DrgDrag suit la souris (MOUCALLS.DLL) jusqu'au relâchement du bouton ou à Échap.

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>DrgAllocDraginfo, DrgReallocDraginfo, DrgFreeDraginfo, DrgAccessDraginfo, DrgPushDraginfo, DrgQueryDragitem, DrgQueryDragitemCount, DrgQueryDragitemPtr, DrgSetDragitem, DrgQueryDraginfoPtr...</td><td>Structures DRAGINFO et DRAGITEM (mémoire partagée, accès comptés : après DM_DROP, la cible libère).</td></tr>
	<tr><td>DrgAddStrHandle, DrgDeleteStrHandle, DrgQueryStrName, DrgQueryStrNameLen, DrgDeleteDraginfoStrHandles</td><td>Chaînes par handles (HSTR C000h à C0FFh, partagées et comptées).</td></tr>
	<tr><td>DrgQueryNativeRMF, DrgVerifyRMF, DrgVerifyNativeRMF, DrgQueryFormat, DrgQueryTrueType, DrgVerifyTrueType, DrgVerifyType, DrgVerifyTypeSet</td><td>Mécanismes et formats de rendu (&lt;m,f&gt; et (m1,m2)x(f1,f2)), types.</td></tr>
	<tr><td>DrgDrag, DrgLazyDrag, DrgLazyDrop, DrgCancelLazyDrag, DrgQueryDragStatus, DrgSetDragPointer, DrgSetDragImage</td><td>Glissement à la souris (DM_DRAGOVER, DM_DRAGLEAVE, DM_DROP) ou différé.</td></tr>
	<tr><td>DrgAllocDragtransfer, DrgFreeDragtransfer, DrgSendTransferMsg, DrgPostTransferMsg</td><td>Transferts (DRAGTRANSFER) ; messages envoyés ou postés (remis à la fin du message en cours).</td></tr>
	<tr><td>DrgDragFiles, DrgAcceptDroppedFiles</td><td>Glissement de fichiers : la fenêtre cible copie ou déplace les fichiers dans son répertoire (DM_ENDCONVERSATION, DM_DRAGFILECOMPLETE ; DM_RENDERFILE si la source fait le rendu).</td></tr>
	<tr><td>DrgGetPS, DrgGetClipPS, DrgReleasePS</td><td>Espaces de présentation (handles sans dessin : pas de GPI).</td></tr>
</table>

Le programme <b>DLL/TESTDRG.PAS</b> vérifie ces fonctions (42 vérifications ; il se termine par trois glissements à la souris, voir son en-tête pour les événements à envoyer avec QEMU).

<h3>Bibliothèque PMWIN.DLL</h3>

Le fichier <b>DLL/PMWIN.PAS</b> est la bibliothèque OS/2 <b>PMWIN.DLL</b> (liée à 00B00000h), le gestionnaire de fenêtres de Presentation Manager, avec ses 649 ordinaux (387 fonctions : ordinaux 1 à 640 de l'interface 16 bits, noms en majuscules quand la fonction est aussi exportée à un ordinal 32 bits, et 700 à 996), plus les points d'entrée internes WINSYSCLASSPROC (ordinal 1000, procédure des classes du système), WINQUERYPSINFO (ordinal 1001, fenêtre, origine et rectangle visible d'un HPS, utilisé par PMGPI.DLL), WINQUERYSCREENTEXT (ordinal 1002, texte écrit à l'écran, pour les programmes d'essai) et WINHIDEOVERLAYS (ordinal 1003, retire le pointeur et le curseur avant un dessin direct de PMGPI.DLL).

PMWIN dessine en mode graphique : la première file de messages passe l'écran en 640 x 480 (VioSetMode ; origine en bas à gauche). Par défaut, c'est un mode VESA à mémoire linéaire (32, sinon 16 bits par pel, avec les couleurs du VGA) ; sans BIOS VESA, c'est le mode 12h du VGA (640 x 480 x 16 couleurs, quatre plans). <code>SET PMRESOLUTION=640x480x4</code> force le mode 12h. Le dessin direct dans les plans demandait, pour chaque octet, une lecture et une écriture de la fenêtre A0000h et des écritures dans les ports du VGA : sous VirtualBox au-dessus de Hyper-V, chacune est une sortie de la machine virtuelle et le dessin y devenait très lent (environ 420 000 accès pour afficher le bureau). En VGA 16 couleurs, PMWIN et PMGPI dessinent maintenant dans un <b>écran fantôme</b> en mémoire (un octet par pel, comme une mémoire linéaire de 8 bits) ; quand la file de messages est au repos (au plus toutes les 60 ms pendant un dessin continu), <code>GFlush</code> compare l'écran fantôme à ce que le VGA affiche et ne recopie que les groupes de 32 pels qui ont changé : une écriture de 32 bits en mode d'écriture 2 pour un groupe d'une seule couleur, quatre (une par plan, en mode d'écriture 0) sinon, et quatre écritures de port pour tout le vidage. Les zones effacées puis redessinées à l'identique ne vont plus au VGA, et rien n'y est relu. Ouvrir puis fermer un dossier : environ 632 000 accès au VGA avant, environ 20 000 écritures de 32 bits et 128 accès aux ports avec l'écran fantôme, pour une image identique au pel près. <code>SET PMSHADOW=NON</code> revient au dessin direct. Les fenêtres sont dessinées en pels, comme sous OS/2 Warp :

<table>
	<tr><th>Élément</th><th>Dessin</th></tr>
	<tr><td>Cadre (FS_SIZEBORDER, FS_DLGBORDER, FS_BORDER)</td><td>Bordure grise en relief de 4, 3 ou 1 pel ; barre de titre de 20 pels (couleur de la fenêtre active ou inactive, titre centré) ; menu système et boutons de réduction et d'agrandissement (ou de restauration) en relief ; une fenêtre se déplace en tirant sa barre de titre.</td></tr>
	<tr><td>Menus</td><td>Barre d'actions de 20 pels, menus déroulants en relief (lignes de 20 pels, mnémoniques soulignés, coches, séparateurs gravés, flèche des sous-menus, raccourcis après une tabulation alignés à droite), article choisi en surbrillance.</td></tr>
	<tr><td>Boutons</td><td>Boutons poussoirs en relief (enfoncés quand on clique, cadre noir pour le bouton par défaut, pointillés autour du texte qui a le focus), cases à cocher (coche dessinée, état indéterminé), boutons radio ronds.</td></tr>
	<tr><td>Champs, listes, défilement</td><td>Champs de saisie et textes multilignes en creux avec un curseur vertical, listes en creux (sélection en surbrillance, article courant en pointillés), listes déroulantes avec leur bouton, barres de défilement (flèches, curseur proportionnel à SBM_SETTHUMBSIZE que l'on peut glisser : SB_SLIDERTRACK puis SB_SLIDERPOSITION), groupes au cadre gravé.</td></tr>
	<tr><td>Dessin du programme</td><td>WinFillRect, WinDrawText (mnémonique souligné), WinDrawBorder, WinInvertRect, WinDrawBitmap (bitmaps OS/2 de 1, 4, 8 et 24 bits, étirées ; bitmaps du système), WinDrawPointer, WinScrollWindow (pels déplacés par octets entiers) ; les fonctions Gpi* de PMGPI.DLL dessinent dans les mêmes espaces de présentation.</td></tr>
	<tr><td>Pointeur et curseur</td><td>Flèche noire et blanche suivant la souris (positions en pels), curseur en rectangle inversé ; ils sont retirés avant un dessin qui les touche et remis quand le programme lit ses messages.</td></tr>
</table>

<img width="1296" height="480" alt="OS/2-0 : PMWIN.DLL en 640 x 480 x 16 couleurs (menu, dialogue)" src="IMAGE/PMWIN.png" />

Le texte est celui de la police 8 x 16 du VGA ; les couleurs CLR_*, SYSCLR_* et RVB deviennent les 16 couleurs du VGA. Quand le dernier programme de PM appelle WinTerminate, l'écran revient au mode texte ; CMD.EXE y revient aussi quand un programme se termine en laissant l'écran en mode graphique. Avec <b>SET PMMODE=TEXTE</b>, PM reste dans l'écran texte de 80 x 25 cellules, vu en coordonnées de 640 x 400 pels (une cellule = 8 x 16 pels). Le clavier (KBDCALLS.DLL) et la souris (MOUCALLS.DLL) sont lus par WinGetMsg et WinPeekMsg. Les procédures de fenêtre d'un programme OS2PC (adresses 00400000h à 007FFFFFh) sont appelées avec la convention Pascal, les autres avec la convention _System.

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>WinInitialize, WinTerminate, WinCreateMsgQueue, WinDestroyMsgQueue, WinGetLastError, WinGetErrorInfo, WinQueryVersion...</td><td>Ancres (HAB), files de messages (HMQ), erreurs PMERR_* (gravité 4).</td></tr>
	<tr><td>WinRegisterClass, WinCreateWindow, WinCreateStdWindow, WinDestroyWindow, WinSetWindowPos, WinQueryWindow, WinQueryWindowULong, WinSetParent, WinWindowFromID, WinBeginEnumWindows...</td><td>Classes, arbre des parents et des propriétaires, ordre de superposition, mots réservés, texte, énumération.</td></tr>
	<tr><td>WinSendMsg, WinPostMsg, WinGetMsg, WinPeekMsg, WinDispatchMsg, WinBroadcastMsg, WinStartTimer, WinSetHook, WinSetFocus, WinSetActiveWindow, WinSetCapture...</td><td>Messages, WM_PAINT, minuteries, crochets (HK_INPUT, HK_SENDMSG, HK_MSGFILTER...), focus, activation, capture, clavier (WM_CHAR) et souris (WM_BUTTONxDOWN...).</td></tr>
	<tr><td>WinBeginPaint, WinGetPS, WinFillRect, WinDrawText, WinDrawBorder, WinInvalidateRect, WinUpdateWindow, WinScrollWindow, WinSetRect, WinIntersectRect...</td><td>Espaces de présentation, mise à jour, dessin en pels (en cellules avec PMMODE=TEXTE), rectangles.</td></tr>
	<tr><td>WinDefWindowProc, WinDefDlgProc, WinCreateDlg, WinDlgBox, WinProcessDlg, WinDismissDlg, WinMessageBox, WinCreateMenu, WinLoadMenu, WinPopupMenu...</td><td>Contrôles (cadre, barre de titre, bouton, statique, champ de saisie, liste, liste déroulante, barre de défilement, menu, texte multiligne), dialogues (modèles DLGTEMPLATE, unités de dialogue = 2 pels), boîtes de message, menus (barre d'actions, sous-menus, mnémoniques).</td></tr>
	<tr><td>WinCreateAccelTable, WinTranslateAccel, WinOpenClipbrd, WinSetClipbrdData, WinAddAtom, WinCreateHeap, WinLoadString, WinQuerySysValue, WinSetSysColors, WinUpper, WinCpTranslateString, WinSetPresParam...</td><td>Accélérateurs, presse-papiers, atomes, tas, ressources (RT_STRING, RT_MESSAGE, RT_MENU, RT_DIALOG, RT_ACCELTABLE), valeurs et couleurs du système, pages de codes 437 et 850, paramètres de présentation.</td></tr>
</table>

Limites : les fonctions Gpi* sont dans PMGPI.DLL (qui accepte les HPS et HDC de PMWIN) ; les régions de PMWIN se limitent à la fenêtre entière (en mode texte, une bitmap est dessinée en trame) ; une seule police ; les pointeurs du système sont dessinés en flèche ; WinCatch et WinThrow ne peuvent dérouler la pile (WinThrow rend FALSE), les messages envoyés à une fenêtre d'un autre processus ne sont remis que si sa procédure est dans une DLL. Le programme <b>DLL/TESTWIN.PAS</b> vérifie ces fonctions (75 vérifications ; il se termine par des entrées du clavier et de la souris, voir son en-tête pour les événements à envoyer avec QEMU).

<h3>Bibliothèque PMGPI.DLL</h3>
 <b>Découpage par les fenêtres placées au-dessus</b> : un espace de présentation obtenu hors de WM_PAINT (<code>WinGetPS</code>, <code>WinGetClipPS</code>, contexte de fenêtre), celui des animations comme l'Essai OpenGL, ne dessine pas sur les menus et les fenêtres qui le recouvrent : PMWIN donne leurs rectangles (point d'entrée interne WINQUERYOBSCURING, ordinal 1011) et PMGPI les retire de sa liste de rectangles de découpage. Un menu système ouvert sur une animation reste donc visible et utilisable.
Le fichier <b>DLL/PMGPI.PAS</b> est la bibliothèque OS/2 <b>PMGPI.DLL</b> (base préférée 00800000h, relogée par le noyau si la place est prise), l'interface graphique GPI de Presentation Manager, avec ses 572 ordinaux (303 fonctions Dev*, Gpi*, Dsp*, Mt*, Segs* et Fmt* : ordinaux 1 à 312 de l'interface 16 bits, noms en majuscules quand la fonction est aussi exportée à un ordinal 32 bits, et 351 à 657). Elle dessine dans quatre sortes de cibles :

<table>
	<tr><th>Cible</th><th>Dessin</th></tr>
	<tr><td>Bitmap en mémoire (DevOpenDC OD_MEMORY + GpiSetBitmap)</td><td>1, 4, 8 ou 24 bits par pel, lignes de bas en haut alignées sur 4 octets, table de couleurs RVB (format BITMAPINFOHEADER et BITMAPINFOHEADER2).</td></tr>
	<tr><td>Écran graphique (DevOpenDC OD_DIRECT, mode choisi par VioSetMode)</td><td>640 x 480 x 16 couleurs (mode 12h, VGA en mode d'écriture 2), 640 x 480 x 2, 640 x 350 x 16, 640 x 200 x 16, 320 x 200 x 16 et 320 x 200 x 256 couleurs (13h). Les couleurs par défaut de PM vont aux index usuels du pilote VGA (CLR_BLUE = bleu vif 9, CLR_DARKBLUE = 1...).</td></tr>
	<tr><td>Espaces de présentation de PMWIN (WinGetPS, WinBeginPaint, WinGetScreenPS)</td><td>Écran graphique de PM (640 x 480 x 16 couleurs), découpé par le rectangle visible de la fenêtre ; le pointeur et le curseur de PMWIN sont retirés avant le dessin. Avec PMMODE=TEXTE : 640 x 400 pels sur 80 x 25 cellules (une zone colore le fond des cellules, le texte s'écrit dans les cellules).</td></tr>
	<tr><td>Métafichier (OD_METAFILE)</td><td>Journal des appels Gpi* (rejoué par GpiPlayMetaFile, enregistré par GpiSaveMetaFile sous l'en-tête « OS20MF01 »).</td></tr>
	<tr><td>Tampon d'impression (OD_QUEUED)</td><td>Travail de PMSPL.DLL : DEVESC_STARTDOC, DEVESC_ENDDOC (numéro du travail), DEVESC_ABORTDOC, DEVESC_RAWDATA ; en PM_Q_STD, les appels Gpi* sont enregistrés comme un métafichier puis imprimés par PicPrint.</td></tr>
</table>

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>DevOpenDC, DevCloseDC, DevQueryCaps, DevEscape, DevQueryDeviceNames, DevPostDeviceModes...</td><td>Contextes de périphériques (CAPS_*), la fermeture d'un DC de métafichier rend le HMF.</td></tr>
	<tr><td>GpiCreatePS, GpiAssociate, GpiDestroyPS, GpiSavePS, GpiRestorePS, GpiResetPS, GpiErase, GpiSetPS, GpiQueryPS...</td><td>Espaces de présentation (micro-PS et PS normaux, unités PU_PELS, PU_LOMETRIC, PU_HIMETRIC, PU_LOENGLISH, PU_HIENGLISH, PU_TWIPS, PU_ARBITRARY).</td></tr>
	<tr><td>GpiMove, GpiLine, GpiPolyLine, GpiBox, GpiFullArc, GpiPartialArc, GpiPointArc, GpiPolySpline, GpiPolyFillet, GpiPolyFilletSharp, GpiCharStringAt, GpiCharStringPosAt, GpiMarker, GpiPolyMarker, GpiImage, GpiSetPel, GpiQueryPel, GpiFloodFill, GpiPolygons...</td><td>Primitives : types et épaisseur de ligne, coins arrondis, arcs d'ellipse, Bézier, coniques, texte 8 x 16 de la police VGA (boîte de caractères, angle, cisaillement, direction, alignement), marqueurs, mélanges FM_* et BM_*, motifs PATSYM_* et motifs de bitmap.</td></tr>
	<tr><td>GpiBeginArea, GpiEndArea, GpiBeginPath, GpiEndPath, GpiFillPath, GpiStrokePath, GpiOutlinePath, GpiModifyPath, GpiPathToRegion, GpiSetClipPath...</td><td>Zones et chemins (alternance ou enroulement).</td></tr>
	<tr><td>GpiCreateRegion, GpiCombineRegion, GpiEqualRegion, GpiOffsetRegion, GpiPtInRegion, GpiRectInRegion, GpiQueryRegionRects, GpiPaintRegion, GpiSetClipRegion, GpiIntersectClipRectangle, GpiExcludeClipRectangle...</td><td>Régions (listes de rectangles), découpage.</td></tr>
	<tr><td>GpiSetModelTransformMatrix, GpiSetDefaultViewMatrix, GpiSetSegmentTransformMatrix, GpiTranslate, GpiScale, GpiRotate, GpiConvert, GpiSetPageViewport, GpiSetGraphicsField, GpiSetViewingLimits...</td><td>Transformations (MATRIXLF en FIXED 16.16), espaces de coordonnées monde, modèle, page par défaut, page et périphérique.</td></tr>
	<tr><td>GpiCreateBitmap, GpiSetBitmap, GpiQueryBitmapBits, GpiSetBitmapBits, GpiBitBlt, GpiWCBitBlt, GpiDrawBits, GpiLoadBitmap...</td><td>Bitmaps, transferts de blocs (les 256 opérations ROP sur source, motif et destination, étirement ou réduction par échantillonnage), conversion monochrome et couleur.</td></tr>
	<tr><td>GpiCreateLogColorTable, GpiQueryRGBColor, GpiCreatePalette, GpiSelectPalette, GpiQueryFonts, GpiCreateLogFont, GpiQueryFontMetrics, GpiLoadFonts...</td><td>Tables de couleurs (index, RVB), palettes, polices (System VIO et System Monospaced).</td></tr>
	<tr><td>GpiOpenSegment, GpiCloseSegment, GpiDrawChain, GpiDrawSegment, GpiSetElementPointer, GpiLabel, GpiQueryElement, GpiPutData, GpiCorrelateChain, GpiQueryBoundaryData, GpiPlayMetaFile, GpiLoadMetaFile, GpiSaveMetaFile...</td><td>Segments retenus (DM_RETAIN, éléments, étiquettes, attributs et priorités), corrélation (zone de sélection, balises), données de limites, métafichiers.</td></tr>
</table>

<img width="640" height="480" alt="OS/2-0 : PMGPI.DLL en 640 x 480 x 16 couleurs" src="IMAGE/PMGPI.png" />

Limites : une seule police (8 x 16 de VIOCALLS, agrandie ou réduite par la boîte de caractères) ; les éléments des segments et des métafichiers sont des appels Gpi* enregistrés (pas d'ordres GOCA) ; les codes PMERR_* sont transmis à WinGetLastError de PMWIN ; un programme qui passe l'écran en mode graphique doit revenir au mode texte (VioSetMode) avant de rendre la main à CMD. L'ordinal 541 porte le nom GPISETPATTERNSET de la liste fournie et appelle GpiSetPatternSet (dans OS/2, cet ordinal est GpiSetPattern). Les codes PMERR_* sont des valeurs approchées. Le programme <b>DLL/TESTGPI.PAS</b> vérifie ces fonctions (68 vérifications ; il affiche quelques secondes l'écran ci-dessus en 640 x 480, puis dessine dans un espace de présentation de PMWIN).

<h3>Bibliothèque PMMERGE.DLL</h3>

Le fichier <b>DLL/PMMERGE.PAS</b> est la bibliothèque OS/2 <b>PMMERGE.DLL</b> (base préférée 00800000h, relogée par le noyau si la place est prise), qui réunit dans OS/2 Warp 4 PMWIN, PMSHAPI (profils, liste des programmes) et des points d'entrée internes de PMGRE et de PMVIOP. Elle a 1039 ordinaux (2000 à 10021 ; le nom Win32CalcFrameRect est donné deux fois, l'ordinal 5118 l'exporte en majuscules) :

<table>
	<tr><th>Fonctions</th><th>Réalisation</th></tr>
	<tr><td>Win* et Win32* du gestionnaire de fenêtres (WinCreateWindow, Win32SendMsg, WinGetPS...)</td><td>Transmises à PMWIN.DLL (et GpiLoadBitmap), qui garde l'état : fenêtres, files, écran graphique.</td></tr>
	<tr><td>Liste des tâches et démarrage (WinAddSwitchEntry, WinQuerySwitchList, WinSwitchToProgram, SheSystemShutdown, StartSystemExecutables...)</td><td>Transmises à OS2SM.DLL ; WinStartApp démarre aussi un programme de Presentation Manager ; WinHAPPfromPID et WinHSWITCHfromHAPP lisent la liste des tâches.</td></tr>
	<tr><td>PrfOpenProfile, PrfQueryProfileString, PrfWriteProfileData, PrfQueryProfileSize, PrfReset, PrfQueryProfile, Prf32*, WinQueryProfile*, WinWriteProfile*, PrfWriteToDisk, PrfSuspendWriteToDisk...</td><td>Profils dans des fichiers INI au format binaire d'OS/2 (en-tête FFFFFFFFh, applications, clés, données) : HINI_USERPROFILE (OS2.INI), HINI_SYSTEMPROFILE (OS2SYS.INI), HINI_PROFILE (les deux en lecture), fichiers ouverts par PrfOpenProfile ; noms pris dans USER_INI et SYSTEM_INI (par défaut C:\OS2.INI et C:\OS2SYS.INI) ; listes des applications et des clés, suppression, écriture à chaque modification (ou retardée).</td></tr>
	<tr><td>PrfAddProgram, PrfChangeProgram, PrfQueryDefinition, PrfQueryProgramTitles, PrfCreateGroup, PrfDestroyGroup, PrfQueryProgramHandle, WinAddProgram, WinQueryProgramTitles...</td><td>Liste des programmes et des groupes (PROGDETAILS, PROGTITLE, SGH_ROOT), gardée dans le profil (applications PM_Programs et PM_Groups).</td></tr>
	<tr><td>WinSetProperty, WinQueryProperty, WinEnumProperties, WinSetClassProperty..., WinSetControlColors, WinQueryDesktopWorkArea, DAXCREATECARET, DaxSwapMouseButton, Win32AddClipbrdViewer, Win32IsWindowOfClass, WinMessageBox2, WinDrawTabbedText...</td><td>Fonctions de Warp 4 : propriétés des fenêtres et des classes, couleurs des contrôles (paramètres de présentation), zone de travail du bureau, curseur DAX, chaîne des visualiseurs du presse-papiers, boîte de message à boutons choisis.</td></tr>
	<tr><td>Edit* (EditCreate, EditSetSelection, EditReplace, EditCopy, EditCXFromICH...)</td><td>Agissent sur un champ de saisie de PMWIN désigné par son HWND.</td></tr>
	<tr><td>WinXX* (tas), SS* (mémoire), RamSem*, PMRequestMutexSem, WinMsp*...</td><td>Tas dans la mémoire partagée de la DLL, blocs de DosAllocMem, sémaphores en mémoire (LongInt : processus propriétaire), sémaphores mutex de DOSCALLS.</td></tr>
	<tr><td>Gre*, PmWinGreEntry*, InnerGre32Entry*, Dispatch16Gate*, PFN*R2, *_Call_16, GRE16*...</td><td>Entrées du moteur graphique et du code 16 bits, absents d'OS/2-0 : elles rendent 0 (fonction inconnue).</td></tr>
</table>

Limites : les entrées de données de Warp 4 (ShellWindow, PMSemaphores, PHandleTable, PSharedHeap, GreMemptrs, FPen, VPAULDefaultColors) sont des fonctions qui rendent l'adresse de la donnée ; GetIconWindows* ne lit pas les icônes de Windows ; les noms d'applications et de clés des profils distinguent les majuscules. Le programme <b>DLL/TESTMRG.PAS</b> vérifie ces fonctions (47 vérifications : ordinaux, profil et format du fichier INI, programmes et groupes, relais vers PMWIN, propriétés, champ de saisie, couleurs, tas, mémoire, sémaphores).

<h3>Bibliothèque PMPIC.DLL</h3>

Le fichier <b>DLL/PMPIC.PAS</b> est la bibliothèque OS/2 <b>PMPIC.DLL</b> (base préférée 00800000h, relogée si la place est prise), celle des outils PICPRINT et PICICHG d'OS/2 :

<table>
	<tr><th>Fonction</th><th>Rôle</th></tr>
	<tr><td>PicPrint(hab, pszFilename, lType, pszParams) (1)</td><td>Imprime un métafichier (PIP_MF 1) ou un fichier PIF (PIP_PIF 2) : l'image est dessinée par PMGPI.DLL dans une page de 640 x 480 pels (options /W:n et /H:n), puis envoyée en graphique ESC/P (ESC @, bandes de 8 lignes ESC * 1 à 120 points par pouce et ESC J 24, saut de page) à PRN, LPT1 à LPT3 ou à un fichier (premier mot de pszParams ; PRN par défaut).</td></tr>
	<tr><td>PicIchg(hab, pszFilename1, pszFilename2, lType) (2)</td><td>Conversion PIC_PIFTOMET (0) : fichier PIF -> métafichier ; PIC_SSTOFONT (2, jeu de symboles de GDDM -> police) rend FALSE.</td></tr>
	<tr><td>pif2met(pszPif, pszMet) (3)</td><td>Conversion d'un fichier PIF en métafichier de PMGPI.DLL.</td></tr>
</table>

Le fichier PIF (Picture Interchange Format de GDDM) est lu comme une suite d'ordres de dessin GDF/GOCA (nombres de 16 bits, octet fort en premier ; texte en EBCDIC, page de codes 037) : couleur et couleur étendue, mélanges, motif, type et largeur de ligne, marqueur, position courante, paramètres d'arc, boîte et angle des caractères, lignes (absolues et relatives), boîtes, cercles, arcs, filets, marqueurs, texte, zones ; les autres ordres (segments, commentaires...) sont sautés d'après leur longueur (formes courte, longue et très longue). Limites : les en-têtes d'enregistrements des fichiers de GDDM ne sont pas interprétés (le fichier doit commencer par les ordres), PIC_SSTOFONT n'est pas réalisée, l'impression est en noir et blanc (seuil de luminance) pour une imprimante ESC/P. Le programme <b>DLL/TESTPIC.PAS</b> vérifie ces fonctions (17 vérifications : conversion, pels du métafichier rejoué, sorties d'impression ; avec QEMU, <code>-parallel file:sortie.txt</code> recueille ce qui est envoyé à PRN).

<h3>Bibliothèque PMSHAPI.DLL</h3>

Le fichier <b>DLL/PMSHAPI.PAS</b> est la bibliothèque OS/2 <b>PMSHAPI.DLL</b> (base préférée 00800000h, relogée si la place est prise), l'interface de l'interpréteur de Presentation Manager d'OS/2 1.x, 2.x et Warp 3 : 144 ordinaux (1 à 213) pour les profils (Prf*, WinQueryProfile*, WinWriteProfile*), la liste des programmes et des groupes (PrfAddProgram, PrfQueryProgramTitles, WinAddProgram, WinCreateGroup...), la liste des tâches et le démarrage des programmes (WinAddSwitchEntry, WinQuerySwitchList, WinSwitchToProgram, WinStartApp, WinHAPPfromPID...) et les points d'entrée internes de l'interpréteur (ShePI*, Shp*, SheSystemShutdown, StartSystemExecutables, ShellWindow...).

Comme sous OS/2 Warp 4, où ces fonctions sont passées dans PMMERGE.DLL, chaque point d'entrée de PMSHAPI appelle par son nom la fonction de <b>PMMERGE.DLL</b> qui la réalise : un programme voit les mêmes profils, les mêmes programmes et la même liste des tâches, qu'il soit lié à PMSHAPI ou à PMMERGE. Quand un nom figure deux fois (ordinal 16 bits et ordinal 32 bits : PrfQueryProfileInt 32 et 114, WinStartApp 119 et 201...), l'ordinal le plus bas est exporté sous le nom en majuscules (PRFQUERYPROFILEINT, WINSTARTAPP). PMSHAPI ajoute le crochet des profils : <b>SheSetProfileHook</b>(pfnHook) l'installe ou le retire pour le processus appelant, il est appelé (fl = HINI, pszApp, pszKey) après chaque écriture réussie faite par PMSHAPI (PrfWriteProfileString, PrfWriteProfileData, WinWriteProfileString, WinWriteProfileData), et <b>SheProfileHook</b>(fl, pszApp, pszKey) l'appelle et rend sa valeur. Le programme <b>DLL/TESTSHA.PAS</b> vérifie ces fonctions (34 vérifications : ordinaux et noms, profils lus et écrits par PMSHAPI et PMMERGE, crochet, programmes et groupes, liste des tâches).

<h3>Bibliothèque PMSPL.DLL</h3>

Le fichier <b>DLL/PMSPL.PAS</b> est la bibliothèque OS/2 <b>PMSPL.DLL</b> (base préférée 00800000h, relogée si la place est prise), le tampon d'impression (spouleur) de Presentation Manager : 44 ordinaux (1 à 90, noms en majuscules) et un point d'entrée interne (1001, procédure de la fenêtre du délai de SplMessageBox).

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>SPLQMOPEN, SPLQMSTARTDOC, SPLQMWRITE, SPLQMENDDOC, SPLQMCLOSE, SPLQMABORTDOC, SPLQMABORT (1 à 8)</td><td>Travail d'impression : SplQmOpen(pszToken, lCount, DEVOPENSTRUC) choisit la file (pszLogAddress : file, imprimante ou port ; vide : file par défaut) et le type de données (PM_Q_STD par défaut, PM_Q_RAW) et rend un HSPL ; les données vont dans le fichier de spoule <code>C:\SPOOL\file\nnnnn.SPL</code> ; SplQmEndDoc rend le numéro du travail ; SplQmClose termine le document commencé, SplQmAbort l'abandonne.</td></tr>
	<tr><td>SPLMESSAGEBOX (7)</td><td>Boîte de message du spouleur (file de messages créée si besoin) : texte complété par l'imprimante et les erreurs SPLDATA_*, icône d'après SPLINFO_* ; après trois minutes (clé MSGTIMEOUT de PM_SPOOLER, en secondes), elle rend MBID_RETRY.</td></tr>
	<tr><td>SPLINIT (20)</td><td>Initialisation : lit les files et les imprimantes du profil du système (applications PM_SPOOLER, PM_SPOOLER_QUEUE, PM_SPOOLER_QUEUE_DESCR, PM_SPOOLER_PRINTER, PM_SPOOLER_PRINTER_DESCR d'OS2SYS.INI) ; sans file, crée PRINTER1 (LPT1, pilote IBMNULL) et LPT1Q.</td></tr>
	<tr><td>SPLQMLISTQUEUES, SPLQMQUERYQINFO, SPLQMLISTJOBS, SPLQMQUERYJINFO, SPLQMQUERYPINFO (21 à 24, 33)</td><td>Listes et informations au format 32 bits d'OS/2 : PRQINFO3, PRQINFO6, niveau 4 (file suivie de ses PRJINFO2), numéros de travaux (niveau 0), PRJINFO2, PRJINFO3, PRDINFO3 ; chaînes placées à la fin du tampon ; ERROR_MORE_DATA, NERR_BufTooSmall et pcbNeeded.</td></tr>
	<tr><td>SPLQMHOLDQUEUE, SPLQMRELEASEQUEUE, SPLQMHOLDJOB, SPLQMRELEASEJOB, SPLQMCANCELJOB, SPLQMRESTARTJOB, SPLQMREPEATJOB, SPLQMPRINTJOBNEXT, SPLQMCHANGEJOBPRTY, SPLQMSETSTATUS, SPLQMUPDATEQPROCPARMS (25 à 32, 34, 36, 42)</td><td>Gestion : retenir et libérer une file ou un travail, annuler, reprendre depuis le début, copier un travail, le mettre en tête, changer sa priorité (1 à 99, 50 par défaut, PRTY=n), fixer les bits d'état PRJ_* et le texte d'état, changer les paramètres du processeur (COP=n : copies).</td></tr>
	<tr><td>SPLQMWRITEFILE, SPLQMQUERYPRINTDATA (35, 41)</td><td>Un fichier devient un travail PM_Q_RAW (commande PRINT) ; lecture des données d'un travail.</td></tr>
	<tr><td>SPLQMCREATEQUEUE, SPLQMDESTROYQUEUE, SPLQMLISTAVAILQUEUES, SPLQMLISTDIRECTPRINTERS (37 à 40)</td><td>Création d'une file (PRQINFO3 ; pszPrinters : imprimante, port ou « nom=port », le port pouvant être PRN, LPT1 à LPT3, COMn, NUL ou un fichier), suppression, noms des files, ports parallèles présents.</td></tr>
	<tr><td>SPLSTDOPEN, SPLSTDCLOSE, SPLSTDSTART, SPLSTDSTOP, SPLSTDDELETE, SPLSTDGETBITS, SPLSTDQUERYLENGTH (50 à 56)</td><td>Données PM_Q_STD : les appels de la GPI faits sur un DC de PMGPI.DLL sont enregistrés dans un métafichier (HSTD), lu par SplStdGetBits.</td></tr>
	<tr><td>PRTOPEN, PRTWRITE, PRTDEVIOCTL, PRTCLOSE, PRTABORT (70 à 73, 75)</td><td>Accès à l'imprimante : si une file sert le port, les données forment un travail PM_Q_RAW (imprimé à PrtClose, abandonné par PrtAbort), sinon le port est ouvert directement ; PrtDevIOCtl (ordre d'OS/2 1.x) gère la catégorie 5 (contrôle de la page, réessai, initialisation, police, état du port parallèle).</td></tr>
	<tr><td>SPLRING3 (90)</td><td>Appelle pfn(ulParam) et rend sa valeur (tout s'exécute en anneau 0 sous OS/2-0).</td></tr>
</table>

Un travail est imprimé dès qu'il est complet si sa file et lui-même ne sont pas retenus et si l'heure est dans la plage de la file. Le processeur PMPRINT envoie le fichier séparateur puis les données : PM_Q_RAW telles quelles, PM_Q_STD dessinées par PicPrint de PMPIC.DLL (graphique ESC/P) ; un port qui ne s'ouvre pas laisse le travail retenu avec PRJ_ERROR et PRJ_DESTOFFLINE. Un DC <b>OD_QUEUED</b> de PMGPI.DLL est maintenant un travail du spouleur : SplQmOpen à DevOpenDC, DEVESC_STARTDOC, DEVESC_ENDDOC (rend le numéro du travail), DEVESC_ABORTDOC, DEVESC_RAWDATA, et en PM_Q_STD l'enregistrement des appels de la GPI (points d'entrée internes GPISTDSTART 1001 et GPISTDSTOP 1002 de PMGPI). Limites : 16 files, 16 imprimantes, 64 travaux ; l'impression se fait dans le processus qui termine le travail ; un travail PM_Q_STD tient sur une page ; les pilotes d'imprimante ne sont pas chargés. Le programme <b>DLL/TESTSPL.PAS</b> vérifie ces fonctions (46 vérifications : files, travaux, impression dans un fichier, port en erreur, Prt* vers LPT1, SplStd*, DC OD_QUEUED imprimé par PicPrint, délai de SplMessageBox, SplRing3).

<h3>Bibliothèque PMVIOP.DLL et fenêtres OS/2</h3>

Le fichier <b>DLL/PMVIOP.PAS</b> est la bibliothèque OS/2 <b>PMVIOP.DLL</b> (base préférée 00800000h, relogée si la place est prise), le « bouclier VIO » (VIO Shield) de Presentation Manager : il montre un écran de caractères (cellules caractère + attribut du mode texte) dans une fenêtre de PM. C'est la base des <b>fenêtres OS/2</b> : l'objet <b>Fenêtre OS/2</b> du bureau (et du dossier Système OS/2) lance CMD.EXE dans une nouvelle session dont l'écran est montré dans une fenêtre, à côté des autres, pendant que le bureau reste visible. Elle exporte les 73 ordinaux de la liste d'OS/2 (1 à 57 et 101 à 122), avec les noms en majuscules du PMVIOP.DLL d'origine (un module LX surtout en 16 bits, de 64 entrées : 44, 45, 50, 51 et 55 viennent d'une version plus récente) ; les variables de l'original (102, 104, 107, 108, 110 à 121, dans son segment de données) sont rendues par des fonctions (OS2PC n'exporte que des constantes).

<img width="640" height="480" alt="OS/2-0 : une fenêtre OS/2 (CMD.EXE dans une fenêtre du bureau, PMVIOP.DLL)" src="IMAGE/FENETREOS2.png" />

<b>Historique et barre de défilement.</b> Une fenêtre OS/2 garde les lignes qui sortent en haut de l'écran de sa session (1000 par défaut, jusqu'à 10 000) : la barre de défilement verticale, <b>Maj+Pg.préc.</b>, <b>Maj+Pg.suiv.</b>, <b>Maj+↑</b>, <b>Maj+↓</b>, <b>Ctrl+Maj+Début</b> et <b>Ctrl+Maj+Fin</b> parcourent cet historique ; Marquer et Copier prennent les lignes affichées, et une touche frappée pour le programme ramène à l'écran de la session. Les lignes sont gardées par le noyau, dans un tampon circulaire par session (<code>KrnSesCtl</code> 22 : taille ; 23 : lecture), au moment où elles quittent l'écran : aucune n'est perdue, même quand la sortie défile plus vite que la fenêtre ne se redessine. L'article <b>Paramètres...</b> du menu système (icône de la fenêtre) et du menu du bouton 2 ouvre une boîte où l'on choisit le nombre de lignes gardées et un <b>fichier d'historique</b> facultatif (par exemple <code>C:\HISTO.TXT</code>) : chaque ligne qui sort de l'écran y est ajoutée, puis le contenu de l'écran à la fermeture de la fenêtre. Ces choix sont retenus dans OS2.INI (application <code>PMVIOP</code>, clés <code>LIGNES</code> et <code>FICHIER</code>).

<table>
	<tr>
		<td align="center"><img src="IMAGE/FENETREOS2_HISTORIQUE.png" width="400" alt="Fenêtre OS/2 : historique et barre de défilement"><br><i>Maj+Pg.préc. : les lignes de HELP sorties de l'écran, barre de défilement à droite</i></td>
		<td align="center"><img src="IMAGE/FENETREOS2_PARAMETRES.png" width="400" alt="Fenêtre OS/2 : boîte Paramètres"><br><i>Paramètres : lignes gardées et fichier d'historique</i></td>
	</tr>
</table>

<table>
	<tr><th>Fonctions</th><th>Rôle</th></tr>
	<tr><td>WinCreateConsole, WinDestroyConsole, QueryConsole, HFrameWindowFromConsole, MakeVisible (1, 2, 41, 122, 42)</td><td>Console : fenêtre à titre, menu système et bouton de réduction (zone client de la classe PMVIOP_SHIELD, procédure VioShieldWindowProc ; cadre sous-classé par ShieldFrameProc) ; fl : 1 visible, 2 session (numéro dans les bits 8 à 15), 4 clavier ouvert. La fenêtre est bornée par l'écran (en 640 x 480 : 79 colonnes visibles, la zone visible suit le curseur). Handle 56430001h + rang (16 consoles).</td></tr>
	<tr><td>WinSyncWithPS, LockVioPS, UnlockVioPS, UnlockSemaphores, ClearData (3, 27, 28, 39, 40)</td><td>Console privée : son tampon est rempli depuis un espace de présentation AVIO de VIOCALLS.DLL (cellules de 2 ou 4 octets, taille du PS) ; verrou du redessin ; tampon vidé.</td></tr>
	<tr><td>ScreenGroupToFPConsole (101)</td><td>Console montrant une session : le tampon vidéo logique de la session est relu toutes les 120 ms (KrnSesCtl 18), les lignes changées et le curseur sont redessinés ; les touches frappées dans la fenêtre vont au clavier de la session (KrnSesCtl 19) ; pour une session DOS, la souris va aussi au pilote INT 33h de la machine (KrnSesCtl 21) ; la console se ferme quand la session se termine.</td></tr>
	<tr><td>WinConsoleSetStatus, WinConsoleGetStatus, WinShieldPreThaw, WinShieldAbort (6, 7, 35, 24)</td><td>État : 1 gelée (l'écran n'est plus redessiné), 2 marquage, 4 sélection faite ; dégel avec redessin complet ; abandon : fin des programmes de la session (KrnSesCtl 20) et console détruite.</td></tr>
	<tr><td>WinConsoleSetCP, WinConsoleGetCP, WinConsoleKbdXlate, WinConsoleSetCustXt, PCharXlateTblDefault (8, 10, 11, 12, 111)</td><td>Page de codes (437, 850, 852, 857, 860, 861, 863, 865, 866, 869) ; traduction d'une KBDKEYINFO par la table de la console (256 octets) ou la table par défaut.</td></tr>
	<tr><td>WinConsoleOpenKbd, WinConsoleCloseKbd, WinConsoleGetFocus, WinConsoleFreeFocus, WinConsoleReadKeyEvent, WinConsoleFlushKeyEvents, WinConsoleGetKbdHandle, KeyboardEvent, EstablishKbdEnvironment (4, 5, 13 à 16, 31, 105, 106)</td><td>Clavier : file de 32 événements (WM_CHAR de la fenêtre ou KeyboardEvent) lus en KBDKEYINFO, avec ou sans attente ; focus d'un processus (ERROR_BUSY pour les autres).</td></tr>
	<tr><td>WinConsoleQueuedPointerEvents, WinConsoleReadPointerEvent, WinConsoleFlushPointerEvents, WinConsoleGet/SetPointerFilterMask, WinConsoleGet/SetPtrPos, WinConsoleAttach/DetachMouseUser (17 à 23, 32, 33)</td><td>Souris : file de 32 MOUEVENTINFO (ligne et colonne de la cellule) pour les utilisateurs attachés ; masque des événements ignorés ; position du pointeur en cellules.</td></tr>
	<tr><td>WinDefAVioWindowProc (30)</td><td>Procédure AVIO par défaut : une application AVIO lui passe tous les WM_SIZE de la fenêtre à laquelle son espace de présentation AVIO est associé, avec les paramètres reçus ; la taille de la fenêtre est gardée dans le PS (VIOCALLS) qui est redessiné, et, pour une console, les cellules visibles sont recalculées. Ce n'est pas un remplacement de WinDefWindowProc, que l'application appelle comme d'habitude : les autres messages ne sont pas traités (elle rend 0).</td></tr>
	<tr><td>MarkingWindowProc, TaskMgrSubClassProc, GetPasteChar (29, 34, 43)</td><td>Bouton 2 dans la fenêtre (ou Maj+F10) : menu Marquer, Copier, Tout copier, Coller, Plein écran, Fermer. Marquer : glisser avec le bouton 1 choisit un rectangle de cellules (inversé), Copier le met dans le presse-papiers de PM (texte) ; Coller envoie le texte du presse-papiers au programme quelques caractères à la fois ; Fermer demande confirmation si un programme s'exécute.</td></tr>
	<tr><td>WinInitShield, Mortician, HMQTaskmgr, HMyModuleHandle, NPSZStrings, GetSelAccess, SelCommonList, usCommonSegSize, APFNVDMServ (36, 37, 110, 107, 104, 103, 119, 120, 102)</td><td>Initialisation (classes publiques, file de la liste des tâches) ; consoles des processus terminés ; données internes (chaînes, liste des consoles, table des services).</td></tr>
	<tr><td>Seamless*, VDM*, PM32ClipDDENotify, TerminateClipDDE, NotifyAllVDMs, Get32DisplayType, VdmRegisterHook, VdmDeregisterHook, FKbdHook, FMouHook, FSeamlessCaptured, HAPPSeamlessCommonVDM*, HMODSeamless (44 à 57, 108, 112 à 121)</td><td>Il n'y a pas de WIN-OS/2 dans OS/2-0 : SeamlessCommonVDM rend ERROR_NOT_SUPPORTED, les objets « seamless » sont seulement enregistrés ; NotifyAllVDMs poste un message à toutes les consoles ; Get32DisplayType rend 3 (VGA) ou 8 (BIOS VESA).</td></tr>
</table>

Le noyau a trois nouvelles opérations de KrnSesCtl : 18 (écran d'une session : tampon vidéo, curseur, lignes, colonnes, nombre de processus), 19 (touche ajoutée au clavier d'une session) et 20 (fin des processus d'une session). Le programme <b>DLL/TESTVIOP.PAS</b> vérifie ces fonctions (70 vérifications : ordinaux, console privée remplie depuis un PS AVIO et dessinée, fenêtre AVIO d'un programme (WM_SIZE passé à WinDefAVioWindowProc, PS associé au DC de la fenêtre et dessiné dedans, VioSetOrg), console redimensionnée, état, page de codes, traduction, clavier et souris par messages, marquage et presse-papiers, menu, entrées seamless et VDM, puis CMD.EXE dans une fenêtre OS/2 : commandes tapées par KeyboardEvent, WM_CHAR et Coller, sortie dessinée dans la fenêtre, WinShieldAbort).

<h3>Bureau PMSHELL.EXE (Workplace Shell)</h3>

Le fichier <b>PMSHELL.PAS</b> est le programme OS/2 <b>PMSHELL.EXE</b>, l'interpréteur de Presentation Manager : le CONFIG.SYS du CD-ROM contient <code>PROTSHELL=C:\PMSHELL.EXE</code> (et <code>SET RUNWORKPLACE=C:\PMSHELL.EXE</code>), le noyau le lance donc au démarrage à la place de CMD.EXE (et le relance s'il se termine), et OS/2-0 démarre sur son bureau, en 640 x 480 (mémoire linéaire VESA, sinon VGA 16 couleurs), prêt à être utilisé à la souris et au clavier. <code>COMSPEC</code> reste <code>C:\CMD.EXE</code> (le noyau ne le remplace plus quand CONFIG.SYS le fixe).

<img width="640" height="480" alt="OS/2-0 : le bureau PMSHELL.EXE (dossiers Lecteurs et C:\, menu contextuel)" src="IMAGE/PMSHELL.png" />

<table>
	<tr><th>Élément</th><th>Rôle</th></tr>
	<tr><td>Bureau</td><td>Fenêtre de tout l'écran, toujours sous les autres ; objets Système OS/2, Lecteurs, Invite de commandes OS/2, Liste des fenêtres, Modèles, Broyeur, Arrêt et Fenêtre OS/2, Navigateur Web, les dossiers Developer Kit, Productivité, Jeux, Multimédia, Loisirs et Science, puis le contenu du répertoire du bureau (<code>C:\DESKTOP</code>, ou <code>D:\DESKTOP</code> si C: est en lecture seule) et les raccourcis du bureau. Les icônes se déplacent à la souris ; leur position est gardée dans OS2.INI (application PMSHELL).</td></tr>
	<tr><td>Dossiers</td><td>Système OS/2 (invite de commandes, lecteurs, liste des fenêtres, configuration du système, informations sur le système, gestionnaire des tâches, aide, arrêt, fenêtres OS/2 et DOS), Productivité, Jeux, Multimédia, Loisirs et Science (directement sur le bureau), Lecteurs (une icône par unité : C: CD-ROM, D: disque virtuel HPFS...) et les répertoires : sous-répertoires, programmes (.EXE, .COM), fichiers de commandes (.CMD, .BAT) et fichiers de données, triés, avec barre de défilement. Un dossier déjà ouvert est activé au lieu d'être rouvert.</td></tr>
	<tr><td>Glisser-déposer</td><td>Avec le bouton 2 (ou le bouton 1 dans un dossier), entre le bureau et les dossiers : un objet déposé sur un dossier ou dans la fenêtre d'un dossier y est déplacé (copié avec Ctrl, ou d'une unité à une autre) ; sur le <b>Broyeur</b>, il est supprimé après confirmation ; sur le <b>LaunchPad</b>, il y est ajouté. Comme dans le Workplace Shell, un objet programme d'un dossier du système (Jeux, Productivité, Loisirs, Système OS/2…) ou un programme posé sur le bureau n'est pas un fichier du dossier : le déposer ailleurs crée un raccourci, son exécutable reste en place, et il ne peut pas être supprimé. Un glisser ne commence qu'au-delà de 10 pixels (un double clic un peu tremblé, ou la souris absolue de VirtualBox, ne déplace rien).</td></tr>
	<tr><td>Raccourcis (shadows)</td><td>Menu contextuel « Créer un raccourci » (sur le bureau), ou dépôt avec Ctrl+Maj : le raccourci (étiquette en couleur) ouvre l'objet d'origine ; le supprimer ne supprime que le raccourci. Ils sont gardés dans OS2.INI (application PMSHELL_RACCOURCIS).</td></tr>
	<tr><td>Modèles</td><td>Dossier Modèles : Dossier, Fichier de données, Fichier de commandes ; ouvrir un modèle (ou le déposer sur un dossier) crée un nouvel objet (DOSSIER, NOUVEAU.TXT, NOUVEAU.CMD, numérotés au besoin).</td></tr>
	<tr><td>Souris</td><td>Clic : sélection ; Ctrl+clic : ajouter un objet au choix ou l'en retirer ; double clic : ouvrir ; bouton 2 : menu contextuel de l'objet (Ouvrir, Ouvrir dans l'Explorateur, Modifier, Couper, Copier, Coller, Créer un raccourci ou Créer un autre, Supprimer, Renommer, Propriétés) ou du fond (Nouveau, Coller, Coller le raccourci, Sélectionner tout, Actualiser, Réorganiser, Trier, Liste des fenêtres, Informations système, Aide, Arrêt ; dans un dossier : Inverser la sélection, Dossier parent, Ouvrir dans l'Explorateur, Invite de commandes ici, Propriétés, Fermer). Clavier : Ctrl+A, Ctrl+X, Ctrl+C, Ctrl+V, Suppr, F2.</td></tr>
	<tr><td>Clavier</td><td>Flèches, Début, Fin, lettre : sélection ; Entrée : ouvrir ; Maj+F10 : menu contextuel ; Ctrl+Échap : liste des fenêtres ; F5 : actualiser ; Retour arrière : dossier parent ; Suppr : supprimer le fichier (après confirmation) ; F1 : aide ; Alt+F4 : fermer la fenêtre (sur le bureau : arrêt) ; Échap : fermer la visionneuse ou la liste des fenêtres.</td></tr>
	<tr><td>Programmes</td><td>Un programme, un fichier de commandes (COMSPEC /C) ou l'invite de commandes (COMSPEC) est lancé dans une nouvelle session plein écran (ou, pour les objets Fenêtre OS/2 et Fenêtre DOS, dans une fenêtre du bureau par PMVIOP.DLL), dans le répertoire de son dossier, et le bureau continue de s'exécuter : Ctrl+Échap y revient, la liste des fenêtres montre les sessions en cours et permet d'y retourner. Un programme de PM quitte sa session pour celle de Presentation Manager : ses fenêtres apparaissent sur le bureau, à côté des autres. Quand un programme en mode texte autre que l'invite de commandes se termine, le noyau attend une touche avant de revenir au bureau (pour lire ce qu'il a affiché).</td></tr>
	<tr><td>Visionneuse</td><td>Un fichier de données s'ouvre dans une fenêtre qui en montre les lignes (2000 au plus).</td></tr>
	<tr><td>Arrêt</td><td>Après confirmation, les fenêtres sont fermées, les fichiers écrits (DosShutdown) puis l'ordinateur est <b>mis hors tension</b> par l'ACPI (état S5) : la fenêtre de VirtualBox, de VMware ou de QEMU se ferme comme un PC qui s'éteint. Le noyau (<code>KrnDiskCtl</code> 16) trouve la table RSDP (zone EBDA ou E0000h-FFFFFh), la RSDT ou la XSDT, la FADT (registres PM1a_CNT et PM1b_CNT, SMI_CMD et ACPI_ENABLE) et l'objet <code>\_S5_</code> de la DSDT (SLP_TYPa, SLP_TYPb), passe en mode ACPI au besoin et écrit SLP_TYP et SLP_EN dans PM1a_CNT. Sur un ordinateur sans ACPI, l'écran indique que l'ordinateur peut être éteint ; <b>Ctrl+Alt+Suppr</b> redémarre l'ordinateur (le bureau le rend au noyau après l'arrêt).</td></tr>
	<tr><td>STARTUP.CMD</td><td>C:\STARTUP.CMD ou D:\STARTUP.CMD est exécuté au démarrage, avant l'affichage du bureau.</td></tr>
</table>

Pour cela, PMWIN.DLL a trois points d'entrée internes : WINSUSPENDSCREEN (1004) prête l'écran au programme lancé, WINRESUMESCREEN (1005) le rend à PM (tout est redessiné, les événements de la souris reçus entre-temps sont oubliés) et WINQUERYSCREENTAKEN (1006) dit si un programme de PM l'a pris. Les icônes sont dessinées par PMGPI.DLL sur l'espace de présentation des fenêtres ; les dossiers, menus, boîtes de message et listes sont ceux de PMWIN. Il n'y a pas de limite au nombre de fenêtres ni au nombre d'objets d'un dossier : les tables de PMSHELL grandissent à la demande (GetMem), et PMWIN.DLL gère jusqu'à 1024 fenêtres, 64 files de messages, 128 espaces de présentation et 128 minuteries. Avec <code>SET PMMODE=TEXTE</code>, le bureau s'affiche en mode texte. Pour démarrer sur la ligne de commande comme avant, mettre <code>PROTSHELL=C:\CMD.EXE</code> dans CONFIG.SYS.

Quand un programme s'arrête sur une exception (TRAP) ou, s'il est de Presentation Manager, sur une erreur d'exécution Pascal (Runtime error 200 à 217), le noyau garde le détail (KrnTaskCtl 21) et le bureau l'affiche dans une boîte <b>SYS3175</b>, comme OS/2 : programme, numéro et nom de l'exception, adresse (EIP, CR2). Sans elle, un programme de PM disparaissait sans message : l'écran texte du noyau est caché par PM, et la sortie standard d'un programme de PM n'est vue de personne.

<h3>Modes VESA et carnet « Système - Paramètres »</h3>

L'écran de Presentation Manager n'est plus limité au VGA 640 x 480 x 16 couleurs : OS/2-0 utilise le <b>BIOS VESA</b> (VBE) de la carte vidéo.

<table>
	<tr><th>Couche</th><th>Rôle</th></tr>
	<tr><td>Noyau (OS2KRNL)</td><td>Appel d'une interruption du BIOS en mode réel depuis le mode protégé : le petit programme <b>KERNEL/BIOSCALL.ASM</b> (assemblé une fois, recopié en 0000:7000) sauve CR0/CR3/CR4, la GDT et l'IDT, repasse en mode réel (pagination coupée, IVT du BIOS, PIC en 08h/70h avec les IRQ masquées), exécute INT 10h puis revient. Au démarrage, le noyau relève les modes du VBE (4F00h, 4F01h) : modes graphiques à mémoire linéaire de 640 x 480 au moins, 8 bits (palette) ou 15, 16, 24, 32 bits (couleurs directes) ; QEMU en propose 67 (VBE 3.0, 16 Mo). API <b>KrnVideo</b> : liste des modes, passage à un mode VESA (4F02h avec mémoire linéaire) ou à un mode du BIOS (retour au texte).</td></tr>
	<tr><td>VIOCALLS.DLL</td><td>VioSetMode accepte toute résolution VESA (hres, vres, bits par pel) ; VioGetMode donne l'adresse de la mémoire linéaire (buf_addr) et les octets par ligne (partial_length) ; le retour au mode texte, une fenêtre surgissante et la bascule des sessions quittent proprement le mode VESA.</td></tr>
	<tr><td>PMWIN.DLL, PMGPI.DLL</td><td>Dessin dans la mémoire linéaire en 8, 15, 16, 24 ou 32 bits par pel (remplissages par REP STOS, défilement par REP MOVS, pointeur, curseur, texte) ; les bitmaps gardent leurs couleurs RVB ; PMGPI dessine sur l'écran VESA (cible TG_LFB). La résolution se choisit par <code>SET PMRESOLUTION=1024x768x32</code> dans CONFIG.SYS, par OS2.INI (PM_Display, RESOLUTION) ou à chaud par WINSETSCREENMODE (ordinal interne 1007) : les fenêtres sont ramenées dans l'écran et tout est redessiné ; le LaunchPad se replace.</td></tr>
	<tr><td>PMSHELL.EXE</td><td>Carnet <b>Système - Paramètres</b> (Système OS/2 → Configuration du système → Système, Souris, Couleurs du bureau, Langue ou Pays ; ou le menu du bureau « Paramètres du système... ») : reliure à spirale et onglets comme sous Warp 3.</td></tr>
</table>

<table>
	<tr><th>Onglet</th><th>Réglages</th></tr>
	<tr><td>Écran</td><td>Écran choisi (VESA, version du VBE, mémoire) ; liste des résolutions « largeur x hauteur x nombre de couleurs » (VGA 640 x 480 x 16 et tous les modes VESA de la carte, jusqu'à 16 777 216 couleurs) ; fréquence de balayage ; Appliquer (changement immédiat, puis « La conserver ? »), Annuler, Par défaut (640 x 480 en mémoire linéaire), Capacités.</td></tr>
	<tr><td>Confirmations</td><td>Demander une confirmation avant de supprimer un dossier, un fichier ou un raccourci, avant l'arrêt du système.</td></tr>
	<tr><td>Titre</td><td>Objet de même nom : ajouter un numéro ou avertir sans créer l'objet.</td></tr>
	<tr><td>Fenêtre</td><td>Objet déjà ouvert : afficher la fenêtre existante ou en ouvrir une nouvelle.</td></tr>
	<tr><td>Entrée</td><td>Délai du double clic, boutons de la souris inversés (gaucher : SV_SWAPBUTTON, géré par PMWIN).</td></tr>
	<tr><td>Logo</td><td>Logo au démarrage du bureau : aucun, 3 ou 5 secondes, jusqu'à un clic.</td></tr>
	<tr><td>Général</td><td>Couleur du fond du bureau (16 couleurs).</td></tr>
	<tr><td>Langue</td><td>Langue des programmes (<code>SET LANGUAGE=</code> de CONFIG.SYS et environnement du système) : français, anglais, allemand, espagnol, italien, albanais, portugais, suédois, danois, japonais (romaji). Aussi par l'objet Langue de Configuration du système.</td></tr>
</table>

Les réglages sont gardés dans OS2.INI (application PMSHELL). Le programme <b>DLL/TESTVIO.PAS</b> vérifie les modes VESA (800 x 600 x 256 et 1024 x 768 x 32 bits : pels de la mémoire linéaire, retour au texte) ; TESTGPI et TESTWIN passent aussi en 1024 x 768 x 32 bits. Une correction d'OS2PC a accompagné ce travail : dans les blocs asm, STOSW, MOVSW, LODSW, SCASW et CMPSW (avec ou sans REP) sont maintenant de vraies instructions sur des mots de 16 bits (préfixe 66h) au lieu de devenir STOSD, MOVSD...

<img width="640" height="480" alt="OS/2-0 en 1024 x 768 x 16 millions de couleurs : carnet Système - Paramètres, onglet Écran (résolutions VESA)" src="IMAGE/PARAMETRES.png" />

<h3>Carnet « Souris - Paramètres »</h3>

L'objet <b>Souris</b> (Système OS/2 → Configuration du système) ouvre le carnet de la souris de Warp 3, dont chaque réglage agit tout de suite et est gardé dans OS2.INI (application PMSHELL) :

<img width="640" height="480" alt="OS/2-0 : carnet Souris - Paramètres, onglet Minutage (zone d'essai du double clic réussie)" src="IMAGE/SOURIS.png" />

<table>
	<tr><th>Onglet</th><th>Réglages</th></tr>
	<tr><td>Minutage</td><td>Double clic : curseur de Lent à Rapide (1000 à 200 ms, SV_DBLCLKTIME) et <b>zone d'essai</b> qui change de couleur quand le double clic est reconnu ; vitesse de déplacement : curseur de Lent à Rapide (facteurs d'échelle et seuils d'accélération de MOUCALLS.DLL : MouSetScaleFact, MouSetThreshold) ; Annuler, Par défaut, Aide. Les curseurs se glissent à la souris ou s'avancent par leurs flèches.</td></tr>
	<tr><td>Configuration</td><td>Droitier ou gaucher (boutons 1 et 2 inversés par PMWIN : SV_SWAPBUTTON), avec le dessin de la souris.</td></tr>
	<tr><td>Affectations</td><td>Liste des fenêtres : clic du bouton 3 (milieu), double clic du bouton 1 sur le fond du bureau, ou aucun ; menus contextuels : clic du bouton 2 ou Maj + clic du bouton 1 ; glisser-déposer : bouton 2 (et 1) ou bouton 1 seulement.</td></tr>
	<tr><td>Pointeurs</td><td>Taille normale (16 x 16) ou grande (32 x 32), blanc à bord noir ou noir à bord blanc, avec un aperçu (PMWIN : WINSETPOINTERSTYLE, ordinal interne 1009).</td></tr>
	<tr><td>Comète</td><td>Pointeur comète : une traînée d'images grises suit le pointeur et s'efface quand la souris s'arrête ; longueur de la traînée (1 à 6).</td></tr>
	<tr><td>Général</td><td>Titre de l'objet (renomme l'objet et le carnet) ; souris détectée (nombre de boutons) et réglages courants.</td></tr>
</table>

Le pointeur de PMWIN est maintenant fait de « lutins » : les pels qu'ils couvrent sont gardés (valeur du périphérique en mémoire linéaire, couleur sur les plans du VGA) et rendus dans l'ordre inverse du dessin, ce qui permet la grande taille et la traînée.

<h3>Carnet « Pays - Paramètres »</h3>

L'objet <b>Pays</b> de Configuration du système (Système OS/2 → Configuration du système → Pays) ouvre le carnet « Pays - Paramètres » de Warp 3 : reliure à spirale, onglets, boutons Annuler (valeurs à l'ouverture du carnet), Par défaut (valeurs du pays) et Aide, et un exemple mis à jour à chaque changement.

<img width="640" height="480" alt="OS/2-0 : carnet Pays - Paramètres, onglet Pays" src="IMAGE/PAYS.png" />

<table>
	<tr><th>Onglet</th><th>Réglages</th></tr>
	<tr><td>Pays</td><td>Pays (liste déroulante : États-Unis, Canada, Amérique latine, Pays-Bas, Belgique, France, Espagne, Italie, Suisse, Royaume-Uni, Danemark, Suède, Norvège, Allemagne, Brésil, Australie, Japon, Portugal, Albanie, Finlande) : tous les formats prennent les valeurs du pays (DosQueryCtryInfo), la ligne <code>COUNTRY=</code> de CONFIG.SYS et la variable <code>COUNTRY</code> de l'environnement changent ; mesures (métriques ou anglo-saxonnes) ; séparateur de liste.</td></tr>
	<tr><td>Heure</td><td>12 ou 24 heures, textes avant midi et après midi (AM, PM), séparateur.</td></tr>
	<tr><td>Date</td><td>Ordre (mois-jour-année, jour-mois-année, année-mois-jour), séparateur.</td></tr>
	<tr><td>Nombres</td><td>Séparateurs des milliers et des décimales, nombre de décimales, zéro avant la virgule, symbole monétaire et sa position (avant ou après le montant, avec ou sans espace).</td></tr>
	<tr><td>Général</td><td>Titre de l'objet.</td></tr>
</table>

Les valeurs sont gardées dans OS2.INI, application <code>PM_National</code>, sous les clés d'OS/2 (<code>iCountry</code>, <code>iMeasurement</code>, <code>sList</code>, <code>iTime</code>, <code>s1159</code>, <code>s2359</code>, <code>sTime</code>, <code>iDate</code>, <code>sDate</code>, <code>sThousand</code>, <code>sDecimal</code>, <code>iDigits</code>, <code>iLzero</code>, <code>sCurrency</code>, <code>iCurrency</code>), que les programmes de Presentation Manager lisent par PrfQueryProfileString. Le noyau met la ligne <code>COUNTRY=</code> de CONFIG.SYS dans la variable <code>COUNTRY</code> ; DOSCALLS.DLL la relit à chaque DosQueryCtryInfo (le changement de pays vaut tout de suite) et connaît maintenant les 20 pays de la liste (NLS.DLL : Albanie ajoutée). Les champs combinés de PMWIN (classe <code>WC_COMBOBOX</code>) déroulent maintenant leur liste au clic : choix au clic ou par Entrée, fermeture par un clic ailleurs.

<h3>Loisirs : Astromancie (APPS/ASTROMAN.PAS) et Onirologie (APPS/REVES.PAS)</h3>

Le dossier <b>Loisirs</b> du bureau contient deux applications portées du dépôt <b>Mystix</b> (Turbo Pascal 7 et Free Pascal, BGI en 640 x 480 x 16 couleurs) vers Presentation Manager : <b>Astromancie</b>, logiciel interactif d'interprétation de l'astrologie (clone graphique du logiciel URRIS de 1985), et <b>Onirologie</b>, interprète de rêves. Comme les autres applications, leurs sources sont dans le dossier <b>APPS</b> du dépôt, chacune en un seul fichier (moteur, textes d'interprétation, dictionnaire et interface). Le moteur d'origine est conservé tel quel ; ce qui change pour OS/2 :

<table>
	<tr><th>Élément</th><th>OS/2-0</th></tr>
	<tr><td>Fenêtre</td><td>Fenêtre de Presentation Manager : barre de titre (nom de la personne, titre du rêve), menu système, barre de menus d'OS/2 construite à partir des tables de menus d'origine dans la langue choisie (F10, Alt + lettre, souris ; raccourcis F1 à F9 et Alt+X affichés). La fenêtre tient dans un écran de 640 x 480 (32 lignes de texte par page au lieu de 34).</td></tr>
	<tr><td>Pages</td><td>Pages de texte, éditeur du récit et graphiques sur fond blanc, avec les couleurs d'origine assombries pour rester lisibles ; barre d'information et barre d'état grises ; barre de défilement d'OS/2 (flèches et pages à la souris). La carte du ciel et les pages d'accueil gardent leur ciel étoilé.</td></tr>
	<tr><td>Dialogues</td><td>Boîtes de dialogue, boutons, zones de saisie et listes dans le style d'OS/2 ; les messages et les questions (Oui/Non) passent par <code>WinMessageBox</code>.</td></tr>
	<tr><td>Menus</td><td>Astromancie : les choix qui demandent un thème sont grisés tant qu'aucun horoscope n'est ouvert. Onirologie : Surligner est un choix coché.</td></tr>
</table>

<img width="640" height="480" alt="Le dossier Loisirs du bureau : Astromancie et Onirologie" src="IMAGE/LOISIRS.png" />

<b>Astromancie</b> (ASTROMAN.EXE) : nouvel horoscope (nom, date et heure de naissance, pays, état, ville : les coordonnées et le décalage horaire sont retrouvés dans l'atlas intégré), calepin des personnes (ASTROMAN.CAL), thème natal (planètes, signes, maisons, mots-clés, planète dominante, ascendant), maisons, carte du ciel (roue du zodiaque, aspects, planètes du jour sur l'anneau extérieur), détail d'une planète ou d'une maison, thème du jour, prévisions, tarot astrologique, comparaison de deux thèmes, exportation de la page (ASTROMAN.TXT), guide ; cinq langues (variable <code>LANGUAGE</code> : FR, EN, DE, ES, IT).

<table>
	<tr>
		<td align="center"><img src="IMAGE/ASTROMANCIE.png" width="400" alt="Astromancie : thème natal"><br><i>Thème natal (15/03/1970, 14 h 30, Paris)</i></td>
		<td align="center"><img src="IMAGE/ASTROMANCIE_CARTE.png" width="400" alt="Astromancie : carte du ciel"><br><i>Carte du ciel (F7)</i></td>
	</tr>
</table>

<b>Onirologie</b> (REVES.EXE) : éditeur du récit (accents par Tab, mots-clés surlignés : symboles, émotions positives et négatives), propriétés du rêve (titre, date, rêveur, humeur au réveil, langue du récit, rêve récurrent ou lucide), analyse par un dictionnaire intégré de 442 symboles et 17 831 mots-clés en cinq langues (détection de la langue), sens du rêve, rapport complet, symboles, tonalité et émotions (camembert, jauge, évolution au fil du récit), thèmes et domaines de vie, classification, archétypes, dictionnaire (parcourir, chercher, par catégorie), journal des rêves (REVES.JNL) et ses statistiques, importation et exportation de textes. <code>REVES récit.txt</code> ouvre un récit dans l'éditeur ; le CD-ROM contient l'exemple <b>REVE.TXT</b>.

<table>
	<tr>
		<td align="center"><img src="IMAGE/ONIROLOGIE.png" width="400" alt="Onirologie : éditeur du récit"><br><i>Le récit, mots-clés surlignés</i></td>
		<td align="center"><img src="IMAGE/ONIROLOGIE_TONALITE.png" width="400" alt="Onirologie : tonalité et émotions"><br><i>Tonalité et émotions (F7)</i></td>
	</tr>
</table>

La couche d'OS/2 de chaque programme dessine dans une image en mémoire de 640 x 480 (les routines de l'unité Graph utilisées sont réécrites : traits, rectangles, cercles, arcs, secteurs, texte agrandi), montrée dans la fenêtre par <code>GpiDrawBits</code> ; la file de messages de PM alimente la boucle d'origine (touches, clics, choix des menus). Dans OS2PC, chaque élément d'un tableau de <code>String[n]</code> occupe 256 octets : les 17 831 mots-clés et les 3 872 lignes de texte d'Onirologie sont regroupés dans des chaînes de 200 caractères, indexées au démarrage (REVES.EXE passe de 6,7 Mo à 1,7 Mo, sous la limite de 4 Mo de l'image d'un programme). Le portage a été vérifié par les modes texte d'origine : <code>ASTROMAN /TEST</code> (deux thèmes : Paris 1970 et Montréal 1985) et <code>REVES /TEST</code> et <code>/RAPPORT</code> donnent exactement les mêmes lignes que les programmes d'origine compilés par Free Pascal sous Linux. Ce travail a corrigé trois défauts d'OS2PC, valables pour tous les programmes : une fonction qui rend un <code>Single</code> effaçait 8 octets au lieu de 4 en commençant (l'EBP sauvé de l'appelant était remis à zéro) ; un paramètre <code>Integer</code>, <code>Word</code> ou <code>Byte</code> passé par valeur et modifié dans la procédure (<code>A := A + 360</code>) n'était réécrit que sur 2 octets mais relu sur 4 ; <code>Read(F, S)</code> sur un fichier texte lisait toute la ligne au lieu de s'arrêter avant la fin de ligne, comme Turbo Pascal.

<h3>Science : Astronomie, Simulateur de planète, Anatomie 3D, Table des éléments et Dessin de chimie (APPS)</h3>

Le dossier <b>Science</b> du bureau contient cinq applications graphiques portées vers Presentation Manager, chacune en un seul fichier source du dossier <b>APPS</b> du dépôt :

<table>
	<tr><th>Application</th><th>Source</th><th>Dépôt d'origine</th><th>Contenu</th></tr>
	<tr><td>Astronomie</td><td><code>APPS/ASTRO.PAS</code> (ASTRO.EXE)</td><td>Axtro</td><td>Calendriers (jour julien, rang du jour, Pâques et fêtes mobiles, calendriers grégorien, julien, hébreu, maya…), coordonnées (équatoriales, écliptiques, galactiques, horizontales, géographiques), observation (équation du temps, réfraction, cadran solaire), éphémérides (planètes, étoiles doubles, comètes), phénomènes (phases de la Lune, lever, coucher et passage au méridien, satellites de Jupiter, Mars, Saturne, Uranus, Neptune et Pluton, réduction des observations physiques) ; vues graphiques : calendrier lunaire, système solaire, comètes, Voie lactée, catalogue de 92 planètes et exoplanètes, 88 constellations, 1000 étoiles.</td></tr>
	<tr><td>Simulateur de planète</td><td><code>APPS/SIMUPLAN.PAS</code> (SIMUPLAN.EXE)</td><td>Axtro</td><td>Simulation animée du système solaire : démarrer, pause, recommencer, vitesse ; orbites, noms des astres, ceinture d'astéroïdes, étoiles du fond ; système intérieur ou complet, zoom ; fiche des astres de la simulation.</td></tr>
	<tr><td>Anatomie 3D du système circulatoire</td><td><code>APPS/CS3DA.PAS</code> (CS3DA.EXE, avec <code>HUMAN.C3D</code> et <code>PHYSIO.CFG</code>)</td><td>BIOLOGIE-0</td><td>Modèle 3D du corps humain (artères, veines, capillaires, cœur), animation de la circulation, physiologie (fréquence cardiaque, pression, débit…), électrocardiogramme et courbe de pression.</td></tr>
	<tr><td>Table des éléments</td><td><code>APPS/ELEMENTS.PAS</code> (ELEMENTS.EXE)</td><td>QCHIMIE</td><td>Tableau périodique des 118 éléments (F5) ou liste des éléments (F6), fiche de chaque élément (numéro, symbole, masse, groupe, période, catégorie, état), recherche par nom, symbole ou numéro (F3), couleurs des catégories.</td></tr>
	<tr><td>Dessin de chimie</td><td><code>APPS/CHEMDRAW.PAS</code> (CHEMDRAW.EXE)</td><td>QCHIMIE</td><td>Éditeur de structures chimiques (atomes, liaisons, cycles, flèches, texte), importation et exportation SMILES, MOL, InChI, SVG, BMP, analyse (formule brute, masse, RMN, spectre de masse).</td></tr>
</table>

<img width="640" height="480" alt="Le dossier Science du bureau" src="IMAGE/SCIENCE.png" />

<b>Astronomie</b> utilise au maximum les composants d'OS/2 au lieu de dessiner elle-même ses contrôles, ce qui la rend plus fluide que la version DOS :

<table>
	<tr><th>Élément</th><th>OS/2-0</th></tr>
	<tr><td>Menus</td><td>Barre de menus de PM (Alt + lettre, F10, souris), construite à partir des tables de menus d'origine (le menu Phénomènes, limité à 18 choix dans la version DOS, perdait ses quatre derniers : Réduction Neptune, Réduction Pluton, Constellations et Étoiles ; il en a maintenant 22).</td></tr>
	<tr><td>Saisies</td><td>Boîte de dialogue modale de PM : champ de saisie (<code>WC_ENTRYFIELD</code>, texte proposé sélectionné), boutons <b>OK</b> et <b>Annuler</b> (<code>WC_BUTTON</code>), Entrée et Échap ; la fenêtre principale est désactivée pendant la saisie.</td></tr>
	<tr><td>Messages et questions</td><td><code>WinMessageBox</code> (information, Oui/Non).</td></tr>
	<tr><td>Résultats</td><td>Fenêtre de PM « Résultats » : texte dans la police du système, barres de défilement de PM verticale et horizontale (<code>WC_SCROLLBAR</code>), flèches, Pg préc., Pg suiv., Début, Fin, boutons <b>Enregistrer...</b> (fichier texte) et <b>Fermer</b>.</td></tr>
	<tr><td>Vues graphiques</td><td>Calendrier lunaire, système solaire, comètes, Voie lactée, planètes, constellations et étoiles s'ouvrent chacune dans sa propre fenêtre de PM (barre de titre, menu système) avec de vrais boutons de PM (Mois précédent, &lt; Heure, Jour &gt;&gt;, Fermer…) et, pour les catalogues, une liste de PM avec sa barre de défilement (jusqu'à 1000 étoiles) ; seuls les dessins scientifiques (orbites, figures des constellations, couleur des étoiles) restent dessinés.</td></tr>
	<tr><td>Barre d'outils</td><td>Icônes des sept vues sous la barre de menus (souris).</td></tr>
</table>

<table>
	<tr>
		<td align="center"><img src="IMAGE/ASTRONOMIE.png" width="400" alt="Astronomie : saisie de la date"><br><i>Saisie (Phases de la Lune)</i></td>
		<td align="center"><img src="IMAGE/ASTRONOMIE_RESULTATS.png" width="400" alt="Astronomie : fenêtre des résultats"><br><i>Fenêtre des résultats (date → jour julien)</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/ASTRONOMIE_CONSTELLATIONS.png" width="400" alt="Astronomie : constellations"><br><i>Les 88 constellations (liste de PM)</i></td>
		<td align="center"><img src="IMAGE/ASTRONOMIE_SYSTEME.png" width="400" alt="Astronomie : système solaire"><br><i>Système solaire (boutons de PM)</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/SIMUPLAN.png" width="400" alt="Simulateur de planète"><br><i>Simulateur de planète</i></td>
		<td align="center"><img src="IMAGE/CS3DA.png" width="400" alt="Anatomie 3D du système circulatoire"><br><i>Anatomie 3D du système circulatoire</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/ELEMENTS.png" width="400" alt="Table des éléments"><br><i>Table des éléments</i></td>
		<td align="center"><img src="IMAGE/CHEMDRAW.png" width="400" alt="Dessin de chimie"><br><i>Dessin de chimie (aspirine importée en SMILES)</i></td>
	</tr>
</table>

Les cinq programmes partagent une couche d'OS/2 qui remplace l'unité Graph du BGI, Crt et la souris : le dessin va dans une image en mémoire de 640 x 480 en 256 couleurs (palette d'origine et couleurs supplémentaires), montrée par <code>GpiDrawBits</code> et figée pendant qu'un menu ou une autre fenêtre est au premier plan ; la file de messages de PM alimente les boucles d'origine (touches, clics, choix des menus). La barre de menus dessinée par chaque programme est remplacée par celle de PM. Les saisies et les messages de l'Anatomie 3D, de la Table des éléments et du Dessin de chimie passent aussi par les boîtes de dialogue de PM. L'Anatomie 3D lit son modèle <code>HUMAN.C3D</code> et sa physiologie <code>PHYSIO.CFG</code> à côté de son programme ; ils sont copiés sur le CD-ROM et installés avec elle.

Ce travail a corrigé un défaut d'<b>OS2PC</b>, valable pour tous les programmes : une constante réelle déclarée dans une procédure (<code>Const G = 0.01720209895;</code>) était écrite en données sur 8 octets (Double) mais relue selon le type de son littéral (Extended, 10 octets, ou Single) : elle valait NaN ou 0 (la vue des comètes d'Astronomie bouclait sans fin). Elle est maintenant écrite dans le type de son littéral. Une sous-routine locale d'Astronomie qui déclarait un tableau de 1000 étoiles (100 Ko) sur la pile est passée sur le tas.

<h3>Productivité : Maximilien CRM, Sample Accounting, Acrodoc, News Master et PresentPoint (APPS)</h3>

Le dossier <b>Productivité</b> du bureau reçoit cinq applications du dépôt <b>OFFICE-0</b>, portées vers Presentation Manager avec l'apparence d'OS/2 et ses menus, chacune en un seul fichier source du dossier <b>APPS</b> :

<table>
	<tr><th>Application</th><th>Source</th><th>Contenu</th><th>Composants d'OS/2</th></tr>
	<tr><td>Maximilien CRM</td><td><code>APPS/MAXIMIZE.PAS</code> (MAXIMIZE.EXE)</td><td>Gestion des relations clients (clone de Maximizer CRM) : moteur MyISAM (.frm, .MYD, .MYI) et SQL intégrés, carnet d'adresses, contacts, notes, journée de travail, opportunités, hotlist, calendrier, courriels, bibliothèque de documents, commandes (OrderDesk), plans d'action, publipostage, rapports, console SQL ; accueil (exemple, nouveau CRM vide, CRM existant).</td><td>Barre de menus de PM (neuf menus, coches), menu contextuel de PM (clic droit, F9) avec ses sous-menus et ses choix grisés, fiches de PM (étiquettes, champs de saisie, cases à cocher, boutons de liste, barre de défilement, Tab et Maj+Tab, F2, F4), listes de PM, visionneuse de rapports avec barres de défilement de PM, boîtes de message et de saisie de PM ; tables, éditeur de texte, chronomètre et À propos dans des fenêtres de PM à part avec de vrais boutons ; boutons de PM sur l'écran d'accueil ; titre de la fenêtre = nom du CRM ouvert.</td></tr>
	<tr><td>Sample Accounting</td><td><code>APPS/SIMPLY.PAS</code> (SIMPLY.EXE)</td><td>Comptabilité (clone de Simply Accounting) : grand livre, comptes, fournisseurs, clients, paie, inventaire, projets, transactions, conciliation, rapports (bilan, état des résultats, journaux), graphiques.</td><td>Barre de menus de PM (neuf menus), fenêtres de la version DOS refaites en contrôles de PM (champs, cases, listes déroulantes, boutons, onglets), boîtes de message de PM.</td></tr>
	<tr><td>Acrodoc</td><td><code>APPS/ACROBAT.PAS</code> (ACROBAT.EXE)</td><td>Visionneuse et éditeur PDF (clone d'Acrobat) : filtres Flate, ASCIIHex, ASCII85, polices, images JPEG, JPEG 2000, JBIG2, CCITT, dégradés, calques ; commentaires (texte, note, surlignage, crayon, formes, tampon, signature, biffure), pages (insertion, rotation, recadrage, filigrane, numérotation), recherche, vignettes, enregistrement incrémental, exportation en texte et en BMP.</td><td>Barre de menus de PM (six menus, coches et choix grisés), rendu dans une image de 256 couleurs (cube 6 x 6 x 6 et gris), formulaires de PM (champs, listes déroulantes, cases à cocher, échantillons de couleur), boîte de fichiers de PM, boîtes de message de PM ; sélecteur de couleurs et boîtes d'information (À propos avec son illustration) dans des fenêtres de PM à part.</td></tr>
	<tr><td>News Master</td><td><code>APPS/NEWS.PAS</code> (NEWS.EXE)</td><td>Mise en page de journaux (clone de NewsMaster) : pages, colonnes, titres, textes, images, polices, impression.</td><td>Barre de menus de PM, menu principal et boîtes de la version DOS en boîtes de PM (boutons, saisies), boîte de fichiers de PM.</td></tr>
	<tr><td>PresentPoint</td><td><code>APPS/POWERPNT.PAS</code> (POWERPNT.EXE)</td><td>Présentations (clone de PowerPoint) : diapositives, texte, formes vectorielles, thèmes, transitions, animations, diaporama, mode plan.</td><td>Barre de menus de PM sur deux lignes (dix menus), boîte de fichiers de PM, boîtes de message et de saisie de PM.</td></tr>
</table>

<img width="640" height="480" alt="Le dossier Productivité du bureau" src="IMAGE/PRODUCTIVITE_OFFICE.png" />

<table>
	<tr>
		<td align="center"><img src="IMAGE/MAXIMIZE.png" width="400" alt="Maximilien CRM"><br><i>Maximilien CRM : carnet d'adresses</i></td>
		<td align="center"><img src="IMAGE/MAXIMIZE_FICHE.png" width="400" alt="Maximilien CRM : fiche de PM"><br><i>Fiche de PM (liste F4 « Statut »)</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/MAXIMIZE_MENU.png" width="400" alt="Maximilien CRM : menu contextuel de PM"><br><i>Menu contextuel de PM (clic droit)</i></td>
		<td align="center"><img src="IMAGE/MAXIMIZE_TABLE.png" width="400" alt="Maximilien CRM : table des utilisateurs"><br><i>Table des utilisateurs dans sa fenêtre de PM</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/SIMPLY.png" width="400" alt="Sample Accounting"><br><i>Sample Accounting</i></td>
		<td align="center"><img src="IMAGE/ACROBAT.png" width="400" alt="Acrodoc"><br><i>Acrodoc : LETTRE.PDF</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/ACROBAT_FORMULAIRE.png" width="400" alt="Acrodoc : formulaire de PM"><br><i>Acrodoc : formulaire de PM (filigrane)</i></td>
		<td align="center"><img src="IMAGE/ACROBAT_APROPOS.png" width="400" alt="Acrodoc : À propos"><br><i>Acrodoc : À propos</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/NEWS.png" width="400" alt="News Master"><br><i>News Master : menu principal</i></td>
		<td align="center"><img src="IMAGE/POWERPNT.png" width="400" alt="PresentPoint"><br><i>PresentPoint</i></td>
	</tr>
</table>

Les cinq programmes partagent la couche d'OS/2 du dossier Science (unité Graph, Crt et souris sur la file de messages de PM, image en mémoire montrée par <code>GpiDrawBits</code>) ; la barre de titre et la barre de menus qu'ils dessinaient sont celles d'OS/2. Les fenêtres de PM communes (boucle modale qui garde sa boîte, vue dessinée dans une fenêtre de PM à part dont les boutons sont de vrais boutons de PM transmis au bouton dessiné, l'image d'avant revenant dans la fenêtre principale à la fermeture) servent à Maximilien CRM et à Acrodoc. <b>PMWIN</b> resserre l'espacement des titres d'une barre de menus qui ne tient pas sur une ligne, puis la répartit sur plusieurs lignes (Sample Accounting, PresentPoint) ; <code>WinCalcFrameRect</code> en tient compte.

Ce travail a corrigé deux défauts d'<b>OS2PC</b>, valables pour tous les programmes : <code>FillChar(X, N, ' ')</code> remplissait avec l'octet de poids faible de l'adresse de la chaîne <code>' '</code> au lieu du code du caractère (les champs vides des fiches de Maximilien CRM contenaient des <code>ÿ</code>) ; <code>With F(I)^ Do</code>, où <code>F</code> est une fonction qui rend un pointeur, n'était pas reconnu et les champs étaient pris pour des variables globales (Acrodoc l'emploie 29 fois). Le <code>FindNext</code> d'Acrodoc (recherche du texte suivant), du même nom que <code>FindNext(SR)</code> de l'unité DOS, est renommé.

<h3>Bloc-notes (APPS/NOTEPAD.PAS)</h3>

Le dossier <b>Productivité</b> a maintenant un <b>Bloc-notes</b> (NOTEPAD.EXE, avant Maximilien CRM) : celui de Pasdows 95, une application intégrée au noyau de Pasdows (<code>KERNEL/VMM32.PAS</code>), porté vers l'API d'OS/2 et compilé par OS2PC en un seul fichier source, <code>APPS/NOTEPAD.PAS</code>. Les fenêtres internes, la barre de menus, les boîtes Ouvrir, Enregistrer sous et Rechercher dessinées, le presse-papiers et les boîtes de message du noyau de Pasdows sont remplacés par les composants de Presentation Manager :

<img width="640" height="480" alt="OS/2-0 : le Bloc-notes, boîte Rechercher de PM" src="IMAGE/BLOCNOTES.png" />

<table>
	<tr><th>Élément</th><th>Pasdows 95</th><th>OS/2-0 (Presentation Manager)</th></tr>
	<tr><td>Fenêtre</td><td>Fenêtre interne du noyau</td><td>WinCreateStdWindow : titre, menu système, réduction, agrandissement, liste des fenêtres, bordure de taille, barres de défilement de PM (verticale et horizontale)</td></tr>
	<tr><td>Menus</td><td>Barre de menus dessinée</td><td>Gabarit de menu et WinCreateMenu : Fichier, Édition, Recherche, Aide ; mnémoniques, raccourcis, choix grisés à l'ouverture du menu (WM_INITMENU)</td></tr>
	<tr><td>Ouvrir, Enregistrer sous</td><td>Boîtes dessinées</td><td>Boîte de PM : champ du nom (WC_ENTRYFIELD), répertoire, liste des répertoires et des fichiers (WC_LISTBOX, DosFindFirst), masque, boutons</td></tr>
	<tr><td>Rechercher</td><td>Boîte dessinée</td><td>Boîte de PM : champ de saisie, case Respecter la casse, boutons Suivant et Annuler ; F3 cherche encore</td></tr>
	<tr><td>Presse-papiers, messages</td><td>Du noyau de Pasdows</td><td>Presse-papiers de PM (CF_TEXT) ; WinMessageBox (À propos, « Voulez-vous enregistrer les modifications ? » avec Oui, Non et Annuler)</td></tr>
	<tr><td>Fichiers</td><td>API du noyau</td><td>DosOpen, DosRead, DosWrite (CR LF ; LF seul et Ctrl+Z acceptés à la lecture)</td></tr>
</table>

Texte jusqu'à 256 Ko, sélection à la souris ou avec Maj et les flèches, Annuler (un second Annuler rétablit), Couper, Copier, Coller, Supprimer, Sélectionner tout, Heure/Date (F5), Rechercher (Ctrl+F) et Suivant (F3). Le bureau ouvre les fichiers .TXT, .INI, .LOG, .PAS, .CFG et .SYS avec le Bloc-notes (icône de bloc à spirale), et <code>NOTEPAD fichier</code> l'ouvre depuis l'invite de commandes. Ce travail a corrigé la constante <code>MB_YESNOCANCEL</code> (5 ; la valeur 3 donnait Abandonner, Réessayer, Ignorer) dans le Bloc-notes, Lecteur MP3, Pascal Developer, Audio numérique, Maximilien CRM, Sample Accounting et Acrodoc.

<h3>Bureau : menu Nouveau et fenêtres redimensionnables</h3>

Le menu contextuel du bureau (clic droit sur le fond, ou Maj+F10) et celui d'un dossier ont un sous-menu <b>Nouveau</b> : <b>Dossier</b> (« Nouveau dossier »), <b>Document texte</b> (« Nouveau document.TXT », ouvert par le Bloc-notes), <b>Image bitmap</b> (« Nouvelle image.BMP », une image BMP 24 bits blanche de 320 x 240, ouverte par Paint), <b>Document HTML</b> (« Nouvelle page.HTML », une page HTML minimale, ouverte par le Navigateur Web) et <b>Fichier de commandes</b> (« Nouveau fichier de commandes.CMD »). Un numéro est ajouté si le nom existe déjà.

<img width="640" height="480" alt="OS/2-0 : menu contextuel du bureau, sous-menu Nouveau" src="IMAGE/BUREAU_NOUVEAU.png" />

<h3>Bureau et dossiers : Couper, Copier, Coller, Sélectionner tout, Renommer</h3>

Le menu contextuel d'un objet (bouton 2 sur une icône du bureau ou d'un dossier) a maintenant les commandes d'un explorateur de fichiers :

<table>
	<tr><th>Commande</th><th>Effet</th></tr>
	<tr><td>Ouvrir</td><td>Ouvre l'objet, ou tous les objets choisis.</td></tr>
	<tr><td>Ouvrir dans l'Explorateur</td><td>Sur un dossier : l'Explorateur OS2-Zero sur ce dossier. Aussi « Invite de commandes ici ».</td></tr>
	<tr><td>Modifier (Bloc-notes)</td><td>Sur un fichier de commandes, une page HTML ou un fichier de données : l'ouvre dans le Bloc-notes au lieu de l'exécuter ou de l'afficher.</td></tr>
	<tr><td>Couper (Ctrl+X), Copier (Ctrl+C)</td><td>Met les objets choisis dans le presse-papiers, celui de l'Explorateur OS2-Zero (mémoire partagée <code>\SHAREMEM\EXPLORER.CLP</code> et texte CF_TEXT) : on copie sur le bureau et on colle dans l'Explorateur, ou l'inverse. Un programme ou un objet du système (dossier Jeux, Fenêtre OS/2…) se copie mais ne se coupe pas : Coller en fait un raccourci, comme le Workplace Shell.</td></tr>
	<tr><td>Coller (Ctrl+V)</td><td>Sur le fond : dans le bureau ou le dossier ; sur un dossier : dans ce dossier. Copie d'un lecteur à l'autre, déplacement (DosMove) sur le même lecteur pour Couper, « Copie de nom » si l'objet est collé dans son propre dossier, confirmation avant de remplacer un objet du même nom, refus de coller un dossier dans lui-même.</td></tr>
	<tr><td>Coller le raccourci</td><td>Crée des raccourcis vers les objets copiés.</td></tr>
	<tr><td>Sélectionner tout (Ctrl+A), Inverser la sélection</td><td>Choix de plusieurs objets ; Ctrl+clic ajoute un objet au choix ou l'en retire. Couper, Copier, Supprimer, Ouvrir et Propriétés agissent sur tout le choix.</td></tr>
	<tr><td>Supprimer… (Suppr)</td><td>Une seule confirmation pour plusieurs objets (« Supprimer ces 2 objets ? ») ; les objets du système ne sont jamais supprimés.</td></tr>
	<tr><td>Renommer… (F2)</td><td>Boîte Renommer (le nom sans l'extension est choisi) pour un fichier, un dossier ou un raccourci ; la position de l'icône sur le bureau suit le nouveau nom.</td></tr>
	<tr><td>Propriétés</td><td>Pour les fichiers et dossiers, la boîte Propriétés de l'Explorateur OS2-Zero (<code>EXPLORER /FPROPS fichier…</code>) : type, emplacement, taille, contenu, dates de création, de modification et de dernier accès, attributs modifiables ; pour plusieurs objets, leur taille totale. Sur le fond d'un dossier : les propriétés du dossier.</td></tr>
</table>

Les commandes qui ne s'appliquent pas sont grisées (MIA_DISABLED) : Couper, Supprimer et Renommer sur un objet du système, Coller quand le presse-papiers ne contient pas d'objets.

Le menu du fond du bureau et de chaque dossier a aussi un sous-menu <b>Trier</b>, avec une coche (MIA_CHECKED) sur le choix en cours : <b>Non trié</b> (par défaut : l'ordre d'origine), <b>Par ordre alphabétique</b> et <b>Par catégorie</b> : les dossiers d'abord, puis, dans le dossier Jeux, les jeux par genre (cartes, plateau, réflexion, arcade, dés et sport), les programmes, les documents par type (texte, HTML, WorDium et Excelsior, images, sons) et les raccourcis, chaque catégorie en ordre alphabétique. Le choix est gardé pour chaque dossier dans OS2.INI (application PMSHELL, clé <code>TRI</code>) ; sur le bureau, il remet les icônes en colonnes comme Réorganiser.

<img width="640" height="480" alt="OS/2-0 : dossier Jeux trié par catégorie, sous-menu Trier" src="IMAGE/JEUX_TRI.png" />

<img width="640" height="480" alt="OS/2-0 : menu contextuel d'un objet du bureau" src="IMAGE/BUREAU_MENU_OBJET.png" />

<img width="640" height="480" alt="OS/2-0 : boîte Renommer du bureau" src="IMAGE/BUREAU_RENOMMER.png" />

<img width="640" height="480" alt="OS/2-0 : Propriétés d'un fichier du bureau" src="IMAGE/BUREAU_PROPRIETES.png" />

<img width="640" height="480" alt="OS/2-0 : Supprimer plusieurs objets choisis par Ctrl+A" src="IMAGE/BUREAU_SUPPRIMER.png" />

Les fenêtres à bordure de taille (FCF_SIZEBORDER), dont les dossiers du bureau, se redimensionnent maintenant à la souris : <b>PMWIN</b> reconnaît le bord gauche, droit, haut ou bas et les quatre coins (16 pels) d'un cadre, même quand la souris est sur un contrôle du cadre (les coins du bas débordent sur le bouton de la barre de défilement), capture la souris et suit le glissement par WinSetWindowPos (taille d'au moins 100 x 60 pels) ; la fenêtre cliente reçoit WM_SIZE et se redessine. Le pointeur prend la forme des flèches de taille d'OS/2 (horizontale, verticale ou diagonale, comme SPTR_SIZEWE, SPTR_SIZENS, SPTR_SIZENWSE et SPTR_SIZENESW) dès qu'il survole un bord ou un coin.

<b>Lecteurs</b> : au démarrage du CD-ROM, C: est le CD-ROM ; au démarrage du disque dur où OS/2-0 est installé, C: est sa partition et le CD-ROM reçoit maintenant la première lettre libre après les partitions (D: le plus souvent) : le noyau lit son volume ISO 9660 par l'ATAPI (IDE ou AHCI) avec le même code que le C: d'un démarrage du CD-ROM. Le dossier Lecteurs montre « Lecteur C » et « Lecteur D (CD-ROM) » ; avant, le CD-ROM n'avait pas de lettre et C: était toujours appelé CD-ROM.

<h3 id="securite">Sécurité d'OS/2 (Ctrl+Alt+Suppr)</h3>

Sur ce point, OS2-0 suit Windows NT et <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a> plutôt qu'OS/2. Ctrl+Échap (liste des fenêtres), Alt+Échap (session suivante) et Ctrl+Alt+Verr Num (récupération) ne suffisent pas. <b>Ctrl+Alt+Suppr</b> ne redémarre donc plus l'ordinateur : il ouvre la boîte <b>Sécurité d'OS/2</b> du bureau (PMSHELL.EXE), dans l'apparence de Presentation Manager.

<ul>
	<li><b>Verrouiller l'ordinateur</b> (V) : un écran de la couleur du bureau couvre tout l'écran, LaunchPad compris. Le clavier et la souris ne vont plus aux programmes, qui continuent de tourner. Alt+Échap et Ctrl+Échap ne changent plus de session. <b>Ctrl+Alt+Suppr</b> le déverrouille.</li>
	<li><b>Fermer la session...</b> (F) : après confirmation, tous les programmes sont arrêtés (sauf le bureau et le LaunchPad) et les dossiers ouverts sont fermés ; le bureau reste.</li>
	<li><b>Arrêter...</b> (A) : l'Arrêt du bureau (confirmation, DosShutdown, mise hors tension).</li>
	<li><b>Gestionnaire des tâches</b> (G) : TASKMGR.EXE.</li>
	<li><b>Annuler</b> (Entrée ou Échap).</li>
</ul>

Le noyau signale la combinaison au bureau (<code>KrnSesCtl</code> 24 : le bureau s'inscrit au démarrage, puis demande toutes les 200 ms si elle a été pressée) et ramène Presentation Manager au premier plan si une session plein écran (invite de commandes, session DOS) y était. Sans bureau, le noyau redémarre l'ordinateur comme avant : démarrage, installation, PROTSHELL=CMD.EXE, après l'Arrêt. Il redémarre aussi quand un appui attend depuis plus de 5 secondes, si le bureau ne répond plus.

Sous <b>VirtualBox</b>, Windows (l'hôte) garde pour lui Ctrl+Alt+Suppr : envoyez-le avec la touche hôte (<b>Ctrl droit + Suppr</b>) ou par le menu <i>Entrée, Clavier, Insérer Ctrl-Alt-Suppr</i>. Sous QEMU, utilisez <i>sendkey ctrl-alt-delete</i> dans le moniteur.

<img width="640" height="480" alt="OS/2-0 : Ctrl+Alt+Suppr, Sécurité d'OS/2" src="IMAGE/SECURITE.png" />
<img width="640" height="480" alt="OS/2-0 : ordinateur verrouillé" src="IMAGE/VERROUILLE.png" />

<h3>Calculatrice (CALC.PAS)</h3>

OS/2 Warp 3 n'avait pas de calculatrice. OS/2-0 en a une : celle de Pasdows 95 (<code>APPS/CALC.PAS</code>, programme Win32), portée vers l'API d'OS/2 et l'apparence de Warp. Elle est dans le nouveau dossier <b>Productivité</b> de Système OS/2 (objet <b>Calculatrice</b>) ; <code>CALC</code> à l'invite de commandes la lance aussi. Le programme d'installation la copie toujours.

<img width="640" height="480" alt="OS/2-0 : la Calculatrice, ouverte depuis le dossier Productivité du bureau" src="IMAGE/CALCULATRICE.png" />

<table>
	<tr><th>Élément</th><th>Pasdows 95 (Win32)</th><th>OS/2-0 (Presentation Manager)</th></tr>
	<tr><td>Fenêtre</td><td>RegisterClassA, CreateWindowExA, AdjustWindowRect</td><td>WinRegisterClass, WinCreateStdWindow (titre, menu système, réduction, liste des fenêtres, bordure de dialogue : taille fixe), taille du cadre calculée par WinQueryWindowRect</td></tr>
	<tr><td>Menus</td><td>CreateMenu, AppendMenuA</td><td>Gabarit de menu de PM (MENUTEMPLATE) et WinCreateMenu : <u>É</u>dition (Copier Ctrl+C, Coller Ctrl+V), <u>A</u>ffichage (Standard coché, Scientifique désactivé), A<u>i</u>de (À propos)</td></tr>
	<tr><td>Dessin</td><td>GDI : FillRect, crayons, LineTo, TextOutA</td><td>WinFillRect, GpiSetColor, GpiMove, GpiLine, WinDrawText (DT_CENTER, DT_RIGHT, DT_VCENTER) ; origine en bas à gauche</td></tr>
	<tr><td>Apparence</td><td>Boutons en relief de Windows 95</td><td>Boutons poussoirs de PMWIN (blanc et noir à l'extérieur, gris foncé à l'intérieur ; inversés quand enfoncés), affichage en creux comme une zone de saisie, couleurs foncées lisibles même en VGA 16 couleurs</td></tr>
	<tr><td>Clavier et souris</td><td>WM_CHAR, WM_KEYDOWN, SetCapture</td><td>WM_CHAR de PM (KC_CHAR, KC_VIRTUALKEY, KC_CTRL), WM_BUTTON1DOWN/UP, WinSetCapture</td></tr>
	<tr><td>Presse-papiers</td><td>GlobalAlloc, SetClipboardData</td><td>WinOpenClipbrd, WinSetClipbrdData (CF_TEXT, CFI_POINTER), WinQueryClipbrdData</td></tr>
	<tr><td>Séparateur décimal</td><td>GetLocaleInfoA</td><td>Carnet Pays (OS2.INI, PM_National, sDecimal), sinon DosQueryCtryInfo</td></tr>
	<tr><td>Langue</td><td colspan="2">Variable <code>LANGUAGE</code> de CONFIG.SYS : français, anglais, allemand, italien, espagnol</td></tr>
	<tr><td>À propos, bip</td><td>MessageBoxA, MessageBeep</td><td>WinMessageBox, WinAlarm</td></tr>
</table>

Le calcul est celui de Pasdows 95, en double précision : chiffres, virgule, +/-, quatre opérations, racine carrée (<code>sqrt</code>), pourcentage, inverse (<code>1/x</code>), égal qui répète la dernière opération, mémoire (MC, MR, MS, M+, indicateur <b>M</b>), Retour arrière, CE et C ; affichage sur 15 chiffres significatifs, notation scientifique au-delà (<code>1,5e+020</code>). Clavier : chiffres, <code>.</code> ou <code>,</code>, <code>+ - * /</code>, Entrée ou <code>=</code>, <code>@</code> (racine), <code>%</code>, <code>R</code> (1/x), F9 (+/-), Retour arrière, Suppr (CE), Échap (C), Ctrl+L, R, M, P (mémoire), Ctrl+C et Ctrl+V (le texte collé est tapé touche par touche). Les exceptions du coprocesseur sont masquées et chaque résultat est vérifié : une division par zéro ou un dépassement affiche un message (« Impossible de diviser par zéro. », « Dépassement de capacité. ») au lieu d'une TRAP 0010 sous VirtualBox.

<h3>Explorateur OS2-Zero (EXPLORER.PAS)</h3>

Le Workplace Shell d'OS/2 montre les fichiers dans des dossiers d'objets, une fenêtre par dossier. Ce modèle convient à beaucoup de travaux, mais pas à tous : certains utilisateurs veulent parfois un explorateur à deux volets, l'arbre des dossiers d'un côté et le contenu de l'autre. <b>Explorateur OS2-Zero</b> répond à ce besoin sans toucher au bureau : c'est une application de Presentation Manager indépendante (comme un traitement de texte ou la Calculatrice), portée de l'Explorateur Pasdows de Pasdows 95, qui faisait partie du noyau <code>VMM32</code> et devient ici un programme qui utilise l'API d'OS/2. On l'ouvre de deux façons : l'objet <b>Explorateur OS2-Zero</b> du dossier <b>Productivité</b> (Système OS/2), ou le menu contextuel du bureau (bouton 2), entre <i>Gestionnaire des tâches</i> et <i>Navigateur Web</i>. <code>EXPLORER [dossier]</code> à l'invite l'ouvre aussi.

<img width="640" height="480" alt="OS/2-0 : l'Explorateur OS2-Zero (arbre des dossiers et contenu de C:, Grandes icônes)" src="IMAGE/EXPLORATEUR.png" />
<img width="640" height="480" alt="OS/2-0 : l'Explorateur OS2-Zero en mode Détails" src="IMAGE/EXPLORATEUR_DETAILS.png" />

<table>
	<tr><th>Partie</th><th>Description</th></tr>
	<tr><td>Arbre « Tous les dossiers »</td><td>Bureau, Poste de travail, lecteurs (disque, CD-ROM, disquette), dossiers ; cases + et −, traits pointillés, branches dépliées à la demande ; l'arbre suit le dossier affiché. Clavier : flèches haut et bas (le contenu suit), gauche (replier ou remonter), droite (déplier).</td></tr>
	<tr><td>« Contenu de »</td><td><b>Grandes icônes</b> (cellules de 100 × 70 comme Pasdows 95, étiquettes sur deux lignes) ou <b>Détails</b> (nom, taille en Ko, type, date de modification). Dossiers d'abord, puis fichiers, par ordre alphabétique. Barres de défilement, flèches, Début, Fin, Pg.préc., Pg.suiv., une lettre : objet suivant qui commence par elle.</td></tr>
	<tr><td>Barre d'état</td><td>Nombre d'objets ou objet choisi (taille en octets ; espace libre et capacité d'un lecteur), espace disque libre du lecteur.</td></tr>
	<tr><td>Ouvrir (double clic, Entrée)</td><td>Dossier ou lecteur : l'affiche. <code>.EXE</code>, <code>.COM</code> : lance le programme (nouvelle session, comme les objets programme du bureau) ; <code>.CMD</code>, <code>.BAT</code> : par CMD.EXE ; textes et sources (<code>.TXT</code>, <code>.PAS</code>, <code>.INI</code>…) : Pascal Developer ; <code>.WAV</code> : Audio numérique ; <code>.MP3</code>, <code>.M3U</code> : Lecteur MP3 ; <code>.HTM</code> : Navigateur Web.</td></tr>
	<tr><td>Menus</td><td>Fichier (Ouvrir, Nouveau dossier, Supprimer, Renommer, Propriétés, Fermer), Édition (Couper, Copier, Coller, Sélectionner tout, Inverser la sélection), Affichage (Grandes icônes, Détails, Actualiser F5), Aller à (Dossier parent : Retour arrière, Poste de travail), Outils (Connecter un lecteur réseau…, Déconnecter un lecteur réseau…), ? (À propos). Bouton 2 : menu contextuel (voir ci-dessous) ; sur le Poste de travail et ses lecteurs, aussi Connecter et Déconnecter un lecteur réseau ; sur un lecteur réseau, Déconnecter. Tab passe de l'arbre au contenu.</td></tr>
	<tr><td>Propriétés (Alt+Entrée)</td><td>Fichier, dossier ou plusieurs éléments : boîte <b>Propriétés</b> (voir ci-dessous). Lecteur : boîte <b>Propriétés de (C:)</b> de Pasdows 95 (voir ci-dessous).</td></tr>
</table>

<b>Couper, Copier, Coller, Sélectionner tout, Propriétés.</b> L'Explorateur OS2-Zero reprend les nouveautés de l'Explorateur de Pasdows 95 (menus contextuels de Windows 95), avec l'API d'OS/2 :

<ul>
	<li><b>Menus contextuels</b> (bouton 2) : sur un fichier ou un dossier, <i>Ouvrir</i>, <b>Couper</b>, <b>Copier</b>, <b>Coller</b> (dans ce dossier), <i>Supprimer</i>, <i>Renommer</i>, <b>Sélectionner tout</b> et <b>Propriétés</b> ; sur le fond du dossier, <b>Sélectionner tout</b>, <b>Actualiser</b>, <b>Coller</b>, <i>Nouveau dossier</i> et <i>Propriétés</i> ; sur un dossier de l'arbre, <i>Coller</i> et <i>Nouveau dossier</i>.</li>
	<li><b>Sélection multiple</b> : <b>Ctrl+clic</b> ajoute ou retire un élément, <b>Maj+clic</b> (ou Maj+flèches) choisit une plage, <b>Sélectionner tout</b> (<b>Ctrl+A</b>) tout le dossier, <i>Inverser la sélection</i> ; la barre d'état donne « <i>n</i> objet(s) sélectionné(s) » et leur taille. Couper, Copier, Supprimer et Propriétés portent sur tous les éléments choisis (« Voulez-vous vraiment supprimer ces 2 éléments ? ») ; Renommer, sur un seul.</li>
	<li><b>Couper / Copier / Coller</b> (<b>Ctrl+X</b>, <b>Ctrl+C</b>, <b>Ctrl+V</b>) : fichiers et dossiers avec tout leur contenu (<code>DosCopy</code>), d'un lecteur à l'autre (HPFS, NTFS, disque virtuel, lecteurs réseau SMB, depuis le CD-ROM) ; Couper déplace (<code>DosMove</code> sur le même lecteur, sinon copie puis suppression). Copier dans le même dossier crée « Copie de <i>nom</i> », « Copie (2) de <i>nom</i> »… ; un élément qui existe déjà fait demander <i>Voulez-vous le remplacer ?</i> (Oui, Non, Annuler) ; copier un dossier dans lui-même est refusé. La liste des fichiers est gardée dans une mémoire partagée nommée (<code>\SHAREMEM\EXPLORER.CLP</code> : d'un Explorateur à l'autre) et le presse-papiers de PM reçoit leurs chemins en texte (un texte copié ensuite remplace la liste).</li>
	<li><b>Supprimer</b> (<b>Suppr</b>) avec confirmation, dossiers compris ; <b>Renommer</b> (<b>F2</b>) ; <b>Nouveau dossier</b> (« Nouveau dossier », puis la boîte Renommer comme sous Windows).</li>
	<li><b>Propriétés</b> d'un fichier ou d'un dossier (boîte de Presentation Manager) : icône et nom, <b>type</b>, <b>emplacement</b>, <b>taille</b> (« 126 Ko (129 024 octets) »), <b>contenu</b> d'un dossier (fichiers et sous-dossiers, taille totale), dates de <b>création</b>, de <b>modification</b> et de <b>dernier accès</b> (« samedi 21 novembre 2026 22:37:34 ») et <b>attributs</b> <i>Lecture seule</i>, <i>Masqué</i>, <i>Archive</i>, <i>Système</i>, modifiables (<code>DosSetPathInfo</code>) par OK ou Appliquer, grisés sur le CD-ROM. Pour plusieurs éléments : nombre de fichiers et de dossiers, dossier commun, taille totale, attributs communs.</li>
	<li>Un fichier <code>.MP3</code>, <code>.M3U</code> ou <code>.PLS</code> s'ouvre dans le <b>Lecteur MP3</b> (il n'était associé à rien).</li>
</ul>

<img width="640" height="480" alt="OS/2-0 : menu contextuel d'un fichier dans l'Explorateur OS2-Zero (Ouvrir, Couper, Copier, Supprimer, Renommer, Sélectionner tout, Propriétés)" src="IMAGE/EXPLORATEUR_MENU_FICHIER.png" />
<img width="640" height="480" alt="OS/2-0 : l'Explorateur OS2-Zero, deux éléments choisis (Copie de HANOIS.EXE et HANOIS.EXE) et la barre d'état" src="IMAGE/EXPLORATEUR_SELECTION.png" />
<img width="640" height="480" alt="OS/2-0 : Propriétés d'un fichier dans l'Explorateur OS2-Zero (type, emplacement, taille, dates, attributs)" src="IMAGE/EXPLORATEUR_PROPRIETES_FICHIER.png" />
<img width="640" height="480" alt="OS/2-0 : Propriétés de deux éléments dans l'Explorateur OS2-Zero" src="IMAGE/EXPLORATEUR_PROPRIETES_PLUSIEURS.png" />
<img width="640" height="480" alt="OS/2-0 : Coller sur un élément qui existe déjà : Confirmer le remplacement" src="IMAGE/EXPLORATEUR_REMPLACER.png" />

La boîte <b>Propriétés de (C:)</b> d'un lecteur reprend celle de Pasdows 95 : onglet <b>Général</b> avec l'icône du lecteur, son nom de volume (modifiable sur un disque dur ou le disque virtuel : <code>DosSetFSInfo</code> niveau 2, bouton Appliquer), son type et son système de fichiers, l'espace utilisé (bleu) et l'espace libre (magenta) en octets et en Ko, Mo ou Go, la capacité, et un <b>camembert en relief</b> (ellipse et flanc dessinés par segments, part libre dans le sens trigonométrique depuis 0°) avec « Lecteur C » ; onglet <b>Outils</b> (Vérifier maintenant… lance CHKDSK ; sauvegarde et défragmentation grisées) ; onglet <b>Partage</b> ; boutons OK, Annuler, Appliquer ; Tab et Maj+Tab changent d'onglet, Entrée vaut OK, Échap Annuler. Elle s'ouvre par Fichier → Propriétés ou le menu contextuel d'un lecteur dans l'Explorateur, et aussi par le menu contextuel d'un lecteur du dossier <b>Lecteurs</b> du bureau, qui lance <code>EXPLORER /PROPS:C:</code> (la boîte seule). De même, <code>EXPLORER /FPROPS fichier…</code> ouvre seule la boîte Propriétés de fichiers ou de dossiers (menu contextuel du bureau et des dossiers).

<img width="640" height="480" alt="OS/2-0 : Propriétés de (C:) ouvertes depuis le dossier Lecteurs du bureau, avec le camembert de l'espace utilisé et libre" src="IMAGE/EXPLORATEUR_PROPRIETES.png" />

Le portage remplace les services du noyau de Pasdows par l'API d'OS/2 : <code>DosFindFirst</code>/<code>DosFindNext</code> (FILEFINDBUF3 : nom, taille, attributs, date) au lieu du parcours direct des répertoires FAT et ISO 9660 ; <code>DosQueryCurrentDisk</code> pour les lecteurs, <code>DosQueryFSInfo</code> (étiquette de volume, espace libre) et <code>DosQueryFSAttach</code> (nom du système de fichiers) ; <code>DosExecPgm</code> pour ouvrir ; fenêtre standard, gabarit de menu, <code>WinPopupMenu</code> et <code>WinMessageBox</code> de PM. Les icônes de Pasdows 95 (grille de 32 × 32 mise à l'échelle : 32 points dans le contenu, 16 dans l'arbre et les Détails) sont redessinées par <code>WinFillRect</code> et <code>GpiLine</code> ; les reliefs, les en-têtes et la barre d'état gardent l'apparence de Windows 95. Langue : variable <code>LANGUAGE</code> (français, anglais, allemand, italien, espagnol).

<h3>Lecteurs réseau : Connecter un lecteur réseau (SMB.IFS, Windows Server, Samba)</h3>

L'Explorateur OS2-Zero monte maintenant un dossier partagé d'un serveur Windows (Windows Server 2019, 2016, 2022, Windows 10 et 11) ou Samba comme une unité d'OS/2-0 : menu <b>Outils → Connecter un lecteur réseau…</b>, ou bouton 2 sur le <b>Poste de travail</b> (dans l'arbre ou dans le contenu). C'est la boîte de Pasdows 95, faite ici des contrôles de Presentation Manager (liste déroulante, champs de saisie, case à cocher, boutons) :

<img width="640" height="480" alt="OS/2-0 : la boîte Connecter un lecteur réseau de l'Explorateur OS2-Zero (lecteur, chemin \\serveur\partage, nom d'utilisateur, mot de passe, Se reconnecter à l'ouverture de session)" src="IMAGE/EXPLORATEUR_RESEAU.png" />

<table>
	<tr><th>Champ</th><th>Rôle</th></tr>
	<tr><td>Lecteur</td><td>Les lettres libres de D: à Z: ; la première est proposée.</td></tr>
	<tr><td>Chemin</td><td><code>\\serveur\partage</code> : nom DNS ou adresse IP du serveur (par exemple <code>\\192.168.1.10\Public</code>), puis le nom du partage. Les barres obliques <code>/</code> sont acceptées et les <code>\\</code> ajoutés s'ils manquent.</td></tr>
	<tr><td>Nom d'utilisateur</td><td><code>nom</code>, ou <code>DOMAINE\nom</code> pour un compte de domaine Active Directory ; vide : compte invité.</td></tr>
	<tr><td>Mot de passe</td><td>Affiché en astérisques ; il ne reste pas en mémoire : SMB.IFS n'en garde que la clé NT (MD4).</td></tr>
	<tr><td>Se reconnecter à l'ouverture de session</td><td>Le lecteur est gardé dans OS2.INI (application <code>PM_NetworkDrives</code>, clé = la lettre : chemin, utilisateur et clé NT, jamais le mot de passe) ; au démarrage, le bureau (PMSHELL) le rattache sans attendre le serveur : la connexion se fait au premier accès.</td></tr>
</table>

En cas d'échec, une boîte explique pourquoi : serveur injoignable sur le port 445, partage introuvable, nom d'utilisateur ou mot de passe incorrect (le champ du mot de passe est alors sélectionné pour le retaper), accès refusé, lettre déjà utilisée. Une fois connecté, l'Explorateur ouvre le lecteur : <code>partage sur 'serveur' (Z:)</code>, avec l'icône d'un disque branché au réseau. On y lit, copie, renomme, crée et supprime fichiers et dossiers depuis l'Explorateur, les dossiers du bureau (le dossier <b>Lecteurs</b> montre `Lecteur Z (\\serveur\partage)`), CMD.EXE et tous les programmes, comme sur un disque local. <b>Outils → Déconnecter un lecteur réseau…</b> (liste des lecteurs réseau) ou <b>Déconnecter</b> du menu contextuel d'un lecteur réseau le détache et l'oublie dans OS2.INI.

<img width="640" height="480" alt="OS/2-0 : un partage Samba monté en E: et ouvert dans l'Explorateur OS2-Zero (dossiers, fichiers, 18,29 Go libres)" src="IMAGE/EXPLORATEUR_RESEAU_LECTEUR.png" />
<img width="640" height="480" alt="OS/2-0 : le Poste de travail de l'Explorateur OS2-Zero avec le lecteur réseau et son menu contextuel Ouvrir, Déconnecter, Propriétés" src="IMAGE/EXPLORATEUR_RESEAU_POSTE.png" />

<table>
	<tr><th>Élément</th><th>Rôle</th></tr>
	<tr><td><b>SMB.IFS</b> (DLL/SMB.PAS)</td><td>Système de fichiers installable <b>distant</b> (<code>FS_NAME</code> = <code>SMB</code>), comme le Requester de LAN Server : client <b>SMB2</b> (dialectes 2.0.2 et 2.1 ; Windows Server 2019 les accepte toujours, SMB1 n'est pas utilisé), session <b>NTLMv2</b> dans SPNEGO, messages <b>signés</b> (HMAC-SHA256, exigé par les contrôleurs de domaine et par <code>server signing = mandatory</code> de Samba), MD4, MD5, HMAC-MD5 et SHA-256 écrits en Pascal. Il porte le client SMB de Pasdows 95 vers les points d'entrée FS_* d'OS/2 : FS_ATTACH (attacher, détacher, informations), FS_OPENCREATE, FS_READ, FS_WRITE, FS_CHGFILEPTR, FS_CLOSE, FS_FINDFIRST/FINDNEXT/FINDCLOSE (QUERY_DIRECTORY, FILEFINDBUF3 avec dates et attributs), FS_PATHINFO et FS_FILEINFO, FS_MKDIR, FS_RMDIR, FS_DELETE, FS_MOVE (renommage), FS_NEWSIZE, FS_FILEATTRIBUTE, FS_FSINFO (espace libre : FileFsSizeInformation) ; FS_COPY laisse la copie au noyau. Lectures et écritures par blocs de la taille négociée avec le serveur ; une connexion perdue (serveur redémarré, réseau coupé) est rouverte à l'accès suivant. Le transport passe par les sockets de TCPIP32.DLL (port 445). Le point d'entrée <code>SMBLASTERROR</code> donne le texte de la dernière erreur (statut NT du serveur).</td></tr>
	<tr><td><b>DosFSAttach</b>, <b>DosQueryFSAttach</b> (DOSCALLS.DLL)</td><td>L'API d'OS/2 des unités distantes : <code>DosFSAttach("Z:", "SMB", "\\serveur\partage" 0 utilisateur 0 mot de passe 0, cb, FS_ATTACH)</code> attache l'unité, <code>FS_DETACH</code> la détache ; <code>DosQueryFSAttach</code> rend <code>FSAT_REMOTEDRV</code> (4), le nom du FSD (<code>SMB</code>) et le chemin réseau. Le noyau charge <code>C:\SMB.IFS</code> à la première demande (pas de ligne <code>IFS=</code> à ajouter) et lui envoie toutes les opérations de l'unité (<code>KrnDiskCtl</code> 13, 14 et 15).</td></tr>
	<tr><td><b>NET.EXE</b> (NET.PAS)</td><td>La commande <code>NET USE</code> du Requester d'OS/2 à l'invite : <code>NET USE</code> (liste), <code>NET USE Z: \\serveur\partage [motdepasse | *] [/USER:[domaine\]nom]</code>, <code>NET USE * …</code> (première lettre libre en partant de Z:), <code>NET USE Z: /DELETE</code>. <code>*</code> demande le mot de passe sans l'afficher.</td></tr>
</table>

Pour un serveur Windows Server 2019 : partager le dossier (Propriétés → Partage → Partage avancé, et les droits NTFS du compte), vérifier que le pare-feu laisse passer le « Partage de fichiers et d'imprimantes (SMB-Entrée) », port TCP 445. Le nom NetBIOS seul d'un serveur n'est pas résolu (pas de diffusion NetBIOS) : utiliser son nom DNS ou son adresse IP. Sous VirtualBox, la carte en NAT atteint un serveur du réseau local par son adresse IP ; en « accès par pont », OS/2-0 est sur le même réseau que le serveur. Essais : Samba 4 (signature obligatoire, NTLMv2 seulement) depuis QEMU, avec copie de fichiers de 165 Ko et 1,1 Mo dans les deux sens (identiques), MD, REN, RD, DEL, DIR avec les dates, connexion permanente rétablie au redémarrage d'une installation sur disque dur.

<h3>Outils réseau : Client FTP (APPS/FTPCLI.PAS)</h3>

Le dossier <b>Outils réseau</b> du bureau contient le <b>Client FTP</b> (FTPCLI.EXE), dans le genre de FileZilla : celui de <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a>, porté de l'API Win32 vers celle d'OS/2 (PMWIN, PMGPI, DOSCALLS, TCPIP32) et compilé par OS2PC en un seul fichier source. Toutes ses fonctions sont reprises :

<ul>
	<li><b>FTP</b> : EPSV/PASV, FEAT, UTF-8, MLSD ou LIST (Unix et MS-DOS) ; <b>SFTP v3</b> sur SSH-2 : curve25519-sha256, clés d'hôte ssh-ed25519 et rsa-sha2-512/256 vérifiées, aes128-ctr, hmac-sha2-256, kex strict, mot de passe ou clavier interactif ; clé d'hôte inconnue présentée avec son empreinte SHA-256, puis mémorisée dans <code>knownhosts.txt</code> (commun avec le Client SSH).</li>
	<li>Barre d'outils, <b>connexion rapide</b> avec historique (<code>recentservers.xml</code>), journal en couleurs, panneaux <b>Site local</b> et <b>Site distant</b> (colonnes triables, sélection multiple, glisser-déposer).</li>
	<li><b>File d'attente</b> avec progression, onglets <i>Fichiers en attente</i>, <i>Transferts échoués</i> et <i>Transferts réussis</i> ; dossiers envoyés et téléchargés avec tout leur contenu ; transferts dans un fil de travail (<code>DosCreateThread</code>, sémaphore).</li>
	<li>Menus déroulants et contextuels : envoyer, télécharger, créer un dossier, supprimer, renommer, copier l'URL, <b>droits d'accès</b> (chmod), commande personnalisée, fichiers masqués, fichier existant (remplacer, reprendre, renommer, ignorer).</li>
	<li><b>Gestionnaire de sites</b> : <code>sitemanager.xml</code> au format de FileZilla 3 (dossiers, protocole, type d'ouverture de session, mot de passe en base64), importation et exportation.</li>
	<li>Les fichiers de configuration sont dans <code>C:\RESEAU\</code> (ou <code>D:\RESEAU\</code> au démarrage du CD-ROM).</li>
</ul>

<img width="640" height="480" alt="OS/2-0 : Client FTP, session SFTP, site local D:, transferts réussis" src="IMAGE/CLIENT_FTP_SFTP.png" />
<img width="640" height="480" alt="OS/2-0 : Client FTP, Gestionnaire de sites (site SFTP)" src="IMAGE/CLIENT_FTP_SITES.png" />
<img width="640" height="480" alt="OS/2-0 : Client FTP, clé d'hôte SSH inconnue et son empreinte SHA-256" src="IMAGE/CLIENT_FTP_HOTE.png" />
<img width="640" height="480" alt="OS/2-0 : Client FTP, droits d'accès d'un fichier distant (chmod)" src="IMAGE/CLIENT_FTP_DROITS.png" />
<img width="640" height="480" alt="OS/2-0 : Client FTP, session FTP" src="IMAGE/CLIENT_FTP.png" />
<img width="640" height="480" alt="OS/2-0 : Client FTP, menu contextuel du site distant" src="IMAGE/CLIENT_FTP_MENU.png" />

Écarts avec l'original : <i>Importer</i> et <i>Exporter</i> du Gestionnaire de sites demandent le chemin dans une boîte de saisie (la boîte standard de fichiers n'existe pas encore) ; <i>Ouvrir</i> un fichier local choisit l'application d'après l'extension, comme l'Explorateur OS2-Zero.

<h3>Outils réseau : Client SSH (APPS/SSHCLI.PAS)</h3>

Le dossier <b>Outils réseau</b> contient aussi le <b>Client SSH</b> (SSHCLI.EXE), dans le genre de MobaXterm : celui de Pasdows 95, porté de Win32 vers Presentation Manager, DOSCALLS et TCPIP32, et compilé par OS2PC en un seul fichier source. Toutes ses fonctions sont reprises :

<ul>
	<li><b>SSH-2</b> : curve25519-sha256, clés d'hôte ssh-ed25519 et rsa-sha2-512/256 vérifiées (<code>knownhosts.txt</code>, commun avec le Client FTP), aes128-ctr, hmac-sha2-256, kex strict, mot de passe ou clavier interactif ; canal session, pty-req, shell ou exec, maintien de la connexion, code de sortie (« Session terminée (code de sortie 3) »).</li>
	<li><b>Terminal xterm</b> : couleurs 16, 256 et RVB, région de défilement, écran alternatif (<code>top</code>, <code>vi</code>), UTF-8 affiché en page de codes, graphismes DEC, historique, sélection, copier, coller, changement de taille (window-change).</li>
	<li>Barre d'outils à grandes icônes, menus Terminal, Sessions, Affichage, Outils, Paramètres, Macros et ?, barre d'état ; <b>onglets des sessions</b> (accueil, jusqu'à 8 sessions, menu contextuel), <b>MultiExec</b> (la frappe va à toutes les sessions), reconnexion.</li>
	<li>Panneau de gauche : <b>connexion rapide</b> (<code>utilisateur@serveur:port</code>) et quatre onglets : <b>Sessions</b> (arbre à dossiers, <code>sessions.xml</code>, mot de passe facultatif en base64), <b>Outils</b> (programmes d'OS/2-0 : Invite de commandes, Gestionnaire des tâches, Gestionnaire de périphériques, Explorateur OS2-Zero, Bloc-notes, Calculatrice, Client FTP, Navigateur Web ; table ASCII, générateur de mots de passe), <b>Macros</b> (enregistrement des frappes, <code>macros.xml</code>) et <b>SFTP</b> (navigateur de la session active : télécharger, envoyer, créer, renommer, supprimer).</li>
	<li>Une tâche par session (<code>DosCreateThread</code>) qui attend le réseau par <b>select</b> ; un contexte SSH par tâche, échangé sous un sémaphore d'exclusion. Pour cela, <b>TCPIP32.DLL</b> exporte maintenant <code>select</code> (ordinal 12, select d'OS/2 : tableau de sockets, délai en millisecondes) et <code>bsdselect</code> (ordinal 32, select de BSD : <code>fd_set</code> et <code>timeval</code>).</li>
	<li>Les fichiers <code>sessions.xml</code>, <code>macros.xml</code>, <code>settings.xml</code> et <code>knownhosts.txt</code> sont dans <code>C:\RESEAU\</code> (ou <code>D:\RESEAU\</code> si C: est en lecture seule).</li>
</ul>

<img width="640" height="480" alt="OS/2-0 : Client SSH, session vers un serveur Linux : ls, couleurs 16, 256 et RVB, UTF-8, graphismes DEC" src="IMAGE/CLIENT_SSH.png" />
<img width="640" height="480" alt="OS/2-0 : Client SSH, top dans l'écran alternatif" src="IMAGE/CLIENT_SSH_TOP.png" />
<img width="640" height="480" alt="OS/2-0 : Client SSH, onglet SFTP du panneau de gauche" src="IMAGE/CLIENT_SSH_SFTP.png" />
<img width="640" height="480" alt="OS/2-0 : Client SSH, nouvelle session" src="IMAGE/CLIENT_SSH_SESSION.png" />
<img width="640" height="480" alt="OS/2-0 : Client SSH, clé d'hôte inconnue" src="IMAGE/CLIENT_SSH_CLE_HOTE.png" />
<img width="640" height="480" alt="OS/2-0 : Client SSH, onglet Outils" src="IMAGE/CLIENT_SSH_OUTILS.png" />

<h3>Outils réseau : Connexion Bureau à distance (APPS/MSTSC.PAS)</h3>

Le dossier <b>Outils réseau</b> contient aussi la <b>Connexion Bureau à distance</b> (MSTSC.EXE, icône d'un écran distant relié à un ordinateur) : le client <b>RDP</b> (Remote Desktop Protocol) de <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a>, porté de Win32 vers Presentation Manager, DOSCALLS et TCPIP32, avec l'apparence d'OS/2 Warp 3, et compilé par OS2PC en un seul fichier source. Il ouvre une session sur <b>Windows Server 2008 à 2022</b> (dont Windows Server 2019), Windows 7 à 11, xrdp ou FreeRDP.

<ul>
	<li><b>Boîte de connexion</b> grise de PM (contrôles natifs) : <b>ordinateur</b> (nom ou adresse, <i>serveur:port</i> si le port n'est pas 3389), <b>nom d'utilisateur</b> (<i>DOMAINE\nom</i> ou <i>nom</i>), <b>mot de passe</b> (masqué), <b>domaine</b> et <b>taille de l'écran</b> (liste déroulante : 640 x 480, 800 x 600, 1024 x 768 ou plein écran) ; menus Connexion et Aide ; Tab et Maj+Tab, Entrée = Connexion, Échap = Quitter. Le dernier ordinateur, l'utilisateur de chaque serveur, le domaine et la taille sont gardés dans OS2.INI (application <code>PM_RemoteDesktop</code>) ; le mot de passe n'est jamais enregistré.</li>
	<li><b>Sécurité</b> : <b>TLS 1.2</b> (ECDHE x25519, AES-128-GCM, SHA-256) et l'authentification au niveau du réseau (<b>NLA</b>) de Windows Server 2019 : <b>CredSSP</b> version 6, NTLMv2 avec signature et scellement RC4, clé publique du serveur liée par SHA-256 avec un nonce, TSCredentials.</li>
	<li><b>Connexion</b> : X.224 (négociation de la sécurité), MCS et GCC, Erect Domain, Attach User, Channel Join, Client Info (ouverture de session automatique), licences, Demand Active / Confirm Active, Synchronize, Control, Font List ; messages d'erreur du serveur en français (mauvais mot de passe, compte désactivé…).</li>
	<li><b>Affichage</b> : mises à jour par le chemin rapide (fast-path, fragments réassemblés) ou classiques, bitmaps non compressés ou compressés en RLE entrelacé (8, 15, 16 et 24 bits), palette ; l'écran distant est gardé dans une image de 24 bits dessinée par <code>GpiDrawBits</code> dans une fenêtre de PM avec barres de défilement, ou en <b>plein écran</b> sans cadre (Ctrl+Alt+Pause ou Ctrl+Alt+Entrée).</li>
	<li><b>Entrées</b> : clavier par codes de balayage, souris (trois boutons) et <b>molette</b> par le chemin rapide ; menu <b>Session</b> : Envoyer Ctrl+Alt+Suppr (aussi Ctrl+Alt+Fin), Plein écran, Déconnecter (avec confirmation, retour à la boîte de connexion).</li>
	<li>La réception tourne dans une tâche (<code>DosCreateThread</code>) qui attend le réseau par <code>select</code> et parle à la fenêtre par <code>WinPostMsg</code> ; l'image de l'écran et les envois sont protégés par des sémaphores d'exclusion (<code>DosRequestMutexSem</code>).</li>
	<li><b>Molette de la souris</b> : ce travail l'a ajoutée à OS/2-0. Le noyau reconnaît la souris PS/2 IntelliMouse (paquets de 4 octets, message « Souris PS/2 a molette (IntelliMouse). » au démarrage), MOUCALLS.DLL produit les événements de molette ($0100 vers le haut, $0200 vers le bas, si le masque des événements les demande) et PMWIN.DLL envoie <code>WM_VSCROLL</code> (SB_LINEUP, SB_LINEDOWN) à la fenêtre sous le pointeur : les listes, les dossiers et les programmes avec une barre de défilement défilent à la molette (pas le bureau).</li>
</ul>

Essayé avec le serveur <b>FreeRDP</b> (shadow, NLA et NTLMv2 obligatoires, 800 x 600) et <b>xrdp</b> (TLS seul) : ouverture de session, affichage, frappe dans un terminal, souris, sélection et collage, molette, défilement, plein écran, mauvais mot de passe, déconnexion. Avec QEMU (<code>-nic user,model=e1000</code>), le serveur de l'hôte est <b>10.0.2.2</b>.

<img width="640" height="480" alt="OS/2-0 : Connexion Bureau à distance, boîte de connexion" src="IMAGE/BUREAU_DISTANCE.png" />
<img width="640" height="480" alt="OS/2-0 : Connexion Bureau à distance, session de 800 x 600 dans une fenêtre (serveur FreeRDP avec NLA)" src="IMAGE/BUREAU_DISTANCE_SESSION.png" />
<img width="640" height="480" alt="OS/2-0 : Connexion Bureau à distance en plein écran" src="IMAGE/BUREAU_DISTANCE_PLEIN_ECRAN.png" />

<h3>Outils réseau : Client GitHub (APPS/GITCLI.PAS)</h3>

Les dossiers <b>Outils réseau</b> et <b>Developer Kit</b> contiennent aussi le <b>Client GitHub</b> (deux objets, le même programme GITCLI.EXE, icône du disque noir de GitHub et d'un graphe de branches), dans le genre de GitHub Desktop : celui de <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a>, porté de Win32 vers Presentation Manager, DOSCALLS, TCPIP32 et TLS32 en un seul fichier source compilé par OS2PC (aucune API d'OS/2 n'a manqué).

<ul>
	<li><b>Git en Pascal</b> : SHA-1, zlib (inflate et deflate), objets libres, <b>packs</b> et index v2, deltas OFS_DELTA et REF_DELTA, index DIRC, .gitignore, statut, <b>fusion à trois voies</b> avec conflits (marqueurs, MERGE_HEAD) et résolution, différences.</li>
	<li><b>Réseau</b> : protocole intelligent en <b>http://</b>, <b>https://</b> (TLS32) et <b>git://</b> : <b>cloner</b>, récupérer, <b>tirer</b>, <b>pousser</b>, publier ; API de GitHub.com avec un jeton (liste des dépôts, publication) ; WININET n'existant pas sous OS/2, un client HTTP/1.1 sur TCPIP32 (Content-Length, « chunked », redirections) ; proxy des Options ou de <code>SET HTTP_PROXY</code> (tunnel CONNECT).</li>
	<li><b>Fenêtre</b> : onglets <b>Modifications</b> (cases à cocher, résumé, description, Valider) et <b>Historique</b>, différences en couleurs, branches (nouvelle, renommer, supprimer, extraire une branche distante), liste des dépôts, boîtes Cloner, Options (jeton, identité, proxy), paramètres du dépôt et « Parcourir » (au lieu de SHBrowseForFolder) ; menus et menus contextuels de PM, contrôles natifs (MLE pour la description) ; fil réseau DosCreateThread ; Explorateur, Invite de commandes et Navigateur Web lancés par DosExecPgm ; réglages dans C:\RESEAU\GITCLI.INI (D:\RESEAU quand C: est en lecture seule).</li>
	<li><b>Corrigé</b> par rapport à Pasdows : le compteur d'avance et de retard (un retard de trop dans un long historique), la touche Tab de la fenêtre principale, le clavier qui ne revenait pas après la fermeture d'une boîte.</li>
	<li><b>Paramètres</b> : <code>GITCLI chemin</code>, <code>/CLONE:url /DIR:chemin</code>, <code>/TEST [/URL:url]... [/RO:url]...</code> : 23 essais (SHA-1, zlib, objets, packs et deltas, statut, diff, historique, branches, fusion et conflit, puis clonage, validation, push et pull sur des serveurs git://, http:// et https://, et clonages de dépôts publics de GitHub.com) ; <code>/INDEX:pack /DIR:chemin</code> indexe un pack reçu dans un dépôt neuf et mesure le temps sur COM1.</li>
	<li><b>Gros dépôts</b> : le noyau d'OS/2-0 ne préempte pas un programme de PM ; pendant un clonage, le fil réseau calculait donc sans rendre la main, et tout le système (pointeur de la souris compris) restait figé pendant la reconstitution des gros fichiers. Cloner OS2-0 lui-même montre bien le problème : 193 versions des images ISO de 26 à 48 Mo, plus de 5 Go à reconstituer et à hacher. Le fil cède maintenant le processeur toutes les 30 ms (DosSleep(0)) dans les longs calculs (inflate, deltas, SHA-1, lectures et écritures). La compression SHA-1 est en assembleur 386 déroulé : elle prenait la moitié du temps. Les objets reconstitués de 2 Mo au plus restent en mémoire (8 Mo en tout) pour les chaînes de deltas : un README.md de 50 versions n'est plus reconstitué depuis la racine de sa chaîne pour chaque version. La barre d'état avance à chaque gros objet. Le Client SVN cède aussi le processeur (MD5, svndiff, fichiers).</li>
	<li><b>OS2PC</b> : en écrivant ce SHA-1 en assembleur, des instructions disparaissaient du binaire sans message. Le lexeur lisait <code>6ED9EBA1h</code> comme le réel 6E9 suivi de <code>D9EBA1h</code>, et <code>08F1BBCDCh</code> comme 8 suivi d'un identificateur. Dans les blocs asm des programmes, <code>db</code>, <code>dw</code>, <code>bswap</code>, <code>jecxz</code>, <code>cli</code> et <code>sti</code> n'étaient pas assemblés. Les constantes hexadécimales à suffixe h sont maintenant lues comme telles pour toutes les cibles, et les blocs asm passent par l'assembleur du noyau (instructions système, <code>db/dw/dd</code>, <code>bswap</code>, <code>jecxz</code>). Une instruction qui ne produit aucun octet est maintenant une erreur de compilation, avec son numéro de ligne. Les PUSH, POP et MOV de registres de segment, sans objet en modèle plat, sont ignorés expressément. Effets sur les binaires : RDTSC (<code>db 0Fh, 31h</code>) est maintenant réellement exécuté dans TLS32.DLL, FTPCLI et MSTSC, au lieu de rendre le contenu d'EAX (une meilleure source d'aléa pour TLS). Do16CLI et Do16STI de PMMERGE.DLL masquent et autorisent vraiment les interruptions. DOSKEY garde son code résident DOS (INT 21h) pour Turbo Pascal seulement : sous OS/2-0, <code>DOSKEY</code> explique que ce mode n'existe pas et <code>DOSKEY /SHELL</code> lance l'interpréteur. Les autres binaires sont identiques octet pour octet, noyau compris.</li>
</ul>

<img width="800" height="600" alt="OS/2-0 : Client GitHub, modifications et différences" src="IMAGE/CLIENT_GITHUB.png" />
<img width="800" height="600" alt="OS/2-0 : Client GitHub, historique" src="IMAGE/CLIENT_GITHUB_HISTORIQUE.png" />
<img width="800" height="600" alt="OS/2-0 : Client GitHub, branches" src="IMAGE/CLIENT_GITHUB_BRANCHES.png" />
<img width="800" height="600" alt="OS/2-0 : Client GitHub, cloner un dépôt" src="IMAGE/CLIENT_GITHUB_CLONER.png" />

<h3>Outils réseau : Client SVN (APPS/SVNCLI.PAS)</h3>

Les dossiers <b>Outils réseau</b> et <b>Developer Kit</b> contiennent aussi le <b>Client SVN</b> (deux objets, le même programme SVNCLI.EXE, icône d'un dossier de copie de travail et des branches d'un dépôt) : le client <b>Subversion</b> de <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a>, dans le genre du Client GitHub, porté de Win32 vers Presentation Manager, DOSCALLS, TCPIP32 et TLS32 en un seul fichier source compilé par OS2PC (aucune API d'OS/2 n'a manqué).

<ul>
	<li><b>Copie de travail</b> (.pasvn) : statut, <b>extraction</b>, <b>mise à jour</b> avec fusion à trois voies (conflits <i>.mine</i> et <i>.rN</i>, résolution), <b>validation</b> (ajouts, dossiers, suppressions, <b>svn:ignore</b>), annulation, <b>branches</b> (création, changement, retour), <b>historique</b> et <b>différences</b> en couleurs lues sur le serveur.</li>
	<li><b>Protocoles</b> : <b>svn://</b> (ra_svn, ANONYMOUS et CRAM-MD5, svndiff0) et WebDAV / HTTP v2 de mod_dav_svn en <b>http://</b> et <b>https://</b> : WININET n'existant pas sous OS/2, un client HTTP/1.1 sur TCPIP32 (connexion gardée, corps « chunked », réponses 100) et TLS32 pour https ; proxy des Options ou de <code>HTTP_PROXY</code> (tunnel CONNECT).</li>
	<li><b>Pour OS/2</b> : fenêtre de PM aux menus, onglets et boîtes de l'original (contrôles PM, MLE pour la description), fil réseau DosCreateThread avec verrou DosCreateMutexSem, réglages dans OS2.INI au lieu de SVNCLI.INI, boîte « Choisir un dossier » (lecteurs et sous-dossiers) au lieu de SHBrowseForFolder, DosExecPgm au lieu de ShellExecute.</li>
	<li><b>Paramètres</b> : <code>SVNCLI dossier</code> ouvre une copie de travail, <code>SVNCLI url dossier</code> en extrait une, <code>/CHECKOUT url dossier</code> extrait sans fenêtre, <code>/USER:</code> et <code>/PASS:</code>, <code>/TEST [urls]</code> : 45 essais (MD5, HMAC-MD5, svndiff, différences, fusions, protocoles, puis extraction, validation, fusion, conflit, annulation, suppression, historique et branches sur un serveur svn://, http:// et https://).</li>
</ul>

<img width="640" height="480" alt="OS/2-0 : Client SVN, copie de travail" src="IMAGE/CLIENT_SVN.png" />
<img width="640" height="480" alt="OS/2-0 : Client SVN, historique et différences" src="IMAGE/CLIENT_SVN_HISTORIQUE.png" />
<img width="640" height="480" alt="OS/2-0 : Client SVN, extraire une copie de travail" src="IMAGE/CLIENT_SVN_EXTRAIRE.png" />

<h3>Outils réseau : Serveur Web (APPS/WEBSRV.PAS)</h3>

Le dossier <b>Outils réseau</b> contient le <b>Serveur Web</b> d'OS/2-0 (WEBSRV.EXE, icône d'un serveur et du globe du Web) : un vrai serveur HTTP et HTTPS, avec ses moteurs de pages <b>PSP</b> (Pascal Server Pages) et <b>ASP</b> (VBScript), et sa console d'administration dans le style du Gestionnaire des services Internet (IIS), aux couleurs et aux reliefs d'OS/2. Tout est dans un seul fichier source compilé par OS2PC : le serveur, TLS 1.3, la cryptographie (SHA-256, AES-GCM, X25519, ECDSA P-256), le compilateur PSP, le compilateur VBScript, la machine qui exécute les pages et la console. Aucune dépendance externe : OS/2-0 se compile toujours avec les seuls outils fournis.

<ul>
	<li><b>Console</b> (<code>WEBSRV</code> sans paramètre, ou bureau → Outils réseau → Serveur Web) : menus déroulants <b>Fichier</b>, <b>Action</b>, <b>Affichage</b>, <b>Outils</b> et <b>?</b> ; barre d'outils (Démarrer, Arrêter, Redémarrer, Actualiser, Ajouter un site, Parcourir) ; à gauche l'<b>arbre</b> du serveur : <i>Sites</i> (chaque site et ses fonctionnalités : Liaisons, Paramètres de base, Document par défaut, Exploration de répertoire, Pages d'erreurs, En-têtes de réponse HTTP, Répertoires virtuels, Authentification, Mappages de gestionnaires, Certificat SSL, Journalisation), <i>Types MIME</i>, <i>Paramètres du serveur</i>, <i>Surveillance</i> et <i>Journal du serveur</i> ; au centre le <b>panneau qui suit l'arbre</b>, comme IIS (page d'accueil avec les icônes des fonctionnalités, listes avec Ajouter, Modifier, Supprimer, formulaires avec Appliquer et Annuler) ; à droite le <b>volet Actions</b> (liens selon la sélection, caché quand la fenêtre est étroite) ; en bas la barre d'état. Appliquer enregistre <code>WEBSRV.CFG</code> et le serveur en marche relit sa configuration sans s'arrêter. La <b>Surveillance</b> trace en direct les requêtes par seconde et les connexions ; <b>Parcourir</b> ouvre le site dans le Navigateur Web d'OS/2-0.</li>
	<li><b>Démarrage</b> : la case <i>Démarrer le serveur Web avec OS/2</i> (page d'accueil du serveur, ou Outils) ajoute ou retire la ligne <code>RUN=C:\WEBSRV.EXE /SERVICE</code> de CONFIG.SYS. <b>Par défaut elle n'est pas cochée</b> : rien n'est chargé au démarrage. Sinon le serveur est lancé détaché, sans fenêtre, avant le bureau. <code>WEBSRV /START</code>, <code>/STOP</code> et <code>/STATUS</code> le pilotent depuis l'invite ; <code>WEBSRV /PSP page [requête]</code> exécute une page sans le réseau.</li>
	<li><b>HTTP/1.1</b> : connexions persistantes, GET, HEAD, POST, réponses 304 (If-Modified-Since, If-None-Match), plages (206), documents par défaut, exploration de répertoire, pages d'erreurs personnalisées, en-têtes ajoutés, répertoires virtuels, types MIME, authentification de base, journal W3C par site (<code>LOGS\W3SVCn\exAAMMJJ.LOG</code>).</li>
	<li><b>HTTPS</b> : TLS 1.3 (TLS_AES_128_GCM_SHA256, X25519), certificat ECDSA P-256 auto-signé créé par la console (ou fourni en PEM).</li>
	<li><b>Hôtes virtuels</b> comme IIS : chaque site a ses liaisons (http ou https, adresse IP, port, nom d'hôte) ; une requête va au site qui répond à l'adresse IP et au port où elle est arrivée et au nom de domaine de son en-tête Host. Les pages .htm et .html partent telles quelles.</li>
	<li><b>PSP</b> : le langage des compilateurs PSP de DEV-COOLS (bloc <code>&lt;% ... %&gt;</code>, <code>&lt;%= ... %&gt;</code>, var, const, type, procédures et fonctions, tableaux, chaînes, boucles, case, unités de la bibliothèque) ; <b>ASP</b> : VBScript (Dim, ReDim, If, For, For Each, Do, While, Select Case, Function, Sub, With, On Error Resume Next). Les deux langages ont les objets d'ASP : Request (QueryString, Form, Cookies, ServerVariables, BinaryRead), Response, Server, Session, Application, Scripting.Dictionary, Scripting.FileSystemObject. Une page est compilée une fois en code intermédiaire (gardée tant que le fichier ne change pas).</li>
	<li><b>Fort trafic sans ralentir OS/2</b> : une seule tâche, sockets non bloquants et select (48 connexions en même temps par serveur), classe de priorité « temps libre » (<code>DosSetPriority</code> : tranches de 10 ms, le reste du système passe devant), pages PSP et ASP exécutées par tranches de 20 000 instructions entre lesquelles les autres connexions avancent, fichiers envoyés par blocs, journal écrit par paquets. Dans QEMU : 760 requêtes par seconde (pages statiques), 230 (pages PSP), un programme de calcul garde les deux tiers du processeur pendant la charge.</li>
	<li><b>Menu contextuel</b> : le bouton 2 de la souris sur un nœud de l'arbre ouvre son menu, comme dans IIS. Sur le serveur et sur <i>Sites</i> : Ajouter un site Web, Démarrer, Arrêter ou Redémarrer le serveur, Créer un certificat, Démarrer avec OS/2, Développer et Réduire tout, Actualiser. Sur un site : Démarrer ou Arrêter le site, Parcourir, Paramètres de base, Liaisons, Explorer le dossier, Ajouter un site, Supprimer le site. Sur une fonctionnalité : Parcourir le site, Accueil du site.</li>
	<li><b>Bases de données externes</b> : les pages PSP et ASP parlent directement à <b>PostgreSQL</b> (protocole v3 ; authentification SCRAM-SHA-256, md5 ou mot de passe en clair) et à <b>MariaDB</b> ou <b>MySQL</b> (protocole 4.1 ; mysql_native_password, et le chemin rapide de caching_sha2_password), sans pilote ni bibliothèque externe : MD5, SHA-1, PBKDF2, HMAC-SHA-256 et les deux protocoles sont dans WEBSRV.PAS. Une page qui attend sa base ne bloque pas le serveur : la machine des pages reprend l'instruction quand la réponse arrive, et les autres connexions sont servies entre-temps (le socket de la base est dans le <code>select</code> du service). Les connexions authentifiées restent en réserve d'une requête à l'autre (même chaîne de connexion ; huit au plus, fermées après une minute sans usage) : une page qui se reconnecte ne refait pas l'authentification.</li>
	<li><b>Machines externes</b> : le serveur écoute sur toutes les adresses de la carte réseau ; les autres ordinateurs du réseau l'atteignent par l'adresse d'OS/2-0 (IPCONFIG). Dans QEMU en réseau « user », il faut une redirection de port (<code>hostfwd=tcp::8080-:80</code>) ; dans VirtualBox ou VMware en accès par pont, l'adresse suffit.</li>
</ul>

Bases de données dans une page PSP (types <code>DatabaseConnection</code> et <code>RecordSet</code>, objet <code>Database</code>) :

<pre>
&lt;%
Var
  Connexion : DatabaseConnection;
  Resultats : RecordSet;
BEGIN
  Connexion := Database.Connect('Provider=PostgreSQL;Server=MONSERVEUR;Database=MaBase;User Id=nom;Password=mdp;');
  Resultats := Connexion.Query('SELECT * FROM ClientsDemo');
  While Not Resultats.Eof Do
  Begin
    WriteLn('Nom      : ' + Resultats['Nom']);
    WriteLn('Prenom   : ' + Resultats['Prenom']);
    Resultats.Next;
  End;
  Resultats.Close;
  Connexion.Close;
END.
%&gt;
</pre>

<ul>
	<li><b>Chaîne de connexion</b> : <code>Provider=PostgreSQL</code> ou <code>Provider=MariaDB</code> (ou <code>MySQL</code> ; sans Provider, le port 5432 ou 3306 décide), <code>Server</code> (ou <code>Host</code>, <code>Data Source</code> ; <code>hôte,port</code> ou <code>hôte:port</code>), <code>Port</code>, <code>Database</code> (ou <code>Initial Catalog</code>), <code>User Id</code> (ou <code>UID</code>), <code>Password</code> (ou <code>PWD</code>) ; ou la forme URL <code>postgresql://nom:mdp@hôte:port/base</code>, <code>mariadb://…</code>, <code>mysql://…</code>.</li>
	<li><b>Connexion</b> : <code>Query(sql)</code> rend un RecordSet ; <code>Execute(sql)</code> rend le nombre de lignes touchées (ou un RecordSet si la requête rend des colonnes) ; <code>Quote(texte)</code> rend un littéral SQL entre apostrophes (pour éviter l'injection SQL) ; <code>Connected</code> ; <code>Close</code> (la connexion retourne à la réserve).</li>
	<li><b>RecordSet</b> : <code>Resultats['Nom']</code> ou <code>Resultats[0]</code> (nom de colonne sans égard à la casse), <code>Eof</code>, <code>Bof</code>, <code>Next</code> (ou <code>MoveNext</code>), <code>MoveFirst</code>, <code>RecordCount</code>, <code>FieldCount</code>, <code>FieldName(i)</code>, <code>Fields('Nom').Name</code> et <code>.Value</code>, <code>RowsAffected</code>, <code>Close</code>. Les entiers, réels et booléens de la base deviennent des nombres et des booléens ; <code>NUMERIC</code> et <code>DECIMAL</code> restent du texte exact (1250.50) ; NULL est vide.</li>
	<li><b>ASP</b> : <code>Set Cn = Server.CreateObject("ADODB.Connection")</code>, <code>Cn.Open "Provider=MariaDB;…"</code>, <code>Set Rs = Cn.Execute("SELECT …")</code>, <code>Rs("Nom")</code>, <code>Rs.Fields("Nom").Value</code>, <code>Rs.Fields.Count</code>, <code>Rs.EOF</code>, <code>Rs.MoveNext</code>, et <code>ADODB.Recordset</code> avec <code>Rs.Open sql, Cn</code>.</li>
	<li><b>Erreurs</b> : une erreur de la base (mot de passe refusé, table inconnue…) arrête la page avec son message et son code SQLSTATE, comme les autres erreurs d'exécution (<code>On Error Resume Next</code> en ASP).</li>
	<li><b>Limites</b> : pas de chiffrement TLS vers la base (le serveur de bases doit accepter les connexions non chiffrées : <code>host</code> dans pg_hba.conf) ; pas de SQL Server pour l'instant ; caching_sha2_password de MySQL 8 n'accepte que le chemin rapide sans TLS : créez l'utilisateur avec mysql_native_password.</li>
	<li><code>WEBSRV /DBTEST</code> vérifie MD5, SHA-1, PBKDF2 et SCRAM-SHA-256 (vecteur de la RFC 7677).</li>
</ul>

<img width="1024" height="768" alt="OS/2-0 : Serveur Web, accueil du Site Web par défaut, volet Actions" src="IMAGE/SERVEUR_WEB.png" />
<img width="1024" height="768" alt="OS/2-0 : page PSP servie par le Serveur Web dans le Navigateur Web" src="IMAGE/SERVEUR_WEB_PSP.png" />
<img width="640" height="480" alt="OS/2-0 : Serveur Web, surveillance en direct" src="IMAGE/SERVEUR_WEB_SURVEILLANCE.png" />
<img width="640" height="480" alt="OS/2-0 : Serveur Web, liaisons d'un site" src="IMAGE/SERVEUR_WEB_LIAISONS.png" />

Pour le Serveur Web, le système a reçu :
<ul>
	<li><b>TCPIP32.DLL, côté serveur</b> : <code>listen</code>, <code>accept</code> (file des connexions et réserve de tampons par socket d'écoute), <code>ioctl</code> (FIONBIO, FIONREAD), <code>setsockopt</code>, <code>getsockopt</code>, <code>getsockname</code>, <code>getpeername</code> ; 96 sockets ; émission par fenêtre glissante (plusieurs segments en vol), réémission par minuterie, retransmission rapide, MSS du correspondant, sockets laissés par un programme terminé récupérés ; <code>select</code> sur 128 sockets ; cache ARP de 64 adresses qui apprend des trames reçues ; <b>boucle locale</b> (127.0.0.1, <code>localhost</code> et la propre adresse de l'ordinateur : les paquets ne passent pas par la carte), pour que le Navigateur Web et CURL d'OS/2-0 atteignent le serveur ; un programme qui démarre pendant la demande DHCP d'un autre l'attend au lieu d'échouer.</li>
	<li><b>Pilotes réseau</b> : anneaux de réception plus grands (E1000 48 descripteurs, PCNET 64) pour les rafales de nombreux clients.</li>
	<li><b>Noyau</b> : ligne <code>RUN=</code> de CONFIG.SYS (jusqu'à 8 programmes détachés lancés avant le bureau) ; classe de priorité « temps libre » (<code>DosSetPriority</code>, KrnTaskCtl 36 : tranche de 10 ms, puis deux tours passés) ; recherche dans les répertoires du CD-ROM (ISO 9660) en une passe avec reprise à la dernière position : ouvrir ou interroger un fichier passe de 100 ms à 0,1 ms.</li>
</ul>

En écrivant les clients des bases de données, deux autres pièges d'OS2PC ont été contournés dans WEBSRV.PAS : un littéral chaîne contenant <code>#0</code> (<code>Salt + #0#0#0#1</code>) est coupé au premier octet nul (les littéraux sont rangés en chaînes ASCIIZ) ; et, dans un <code>With</code>, un champ nommé <code>Port</code> est pris pour le tableau <code>Port[]</code> de Turbo Pascal (le champ s'appelle <code>DbPort</code>).

Ce travail a corrigé deux défauts d'<b>OS2PC</b>, valables pour tous les programmes :
<ul>
	<li><b>Paramètre chaîne écrasé avant l'appel</b> : une chaîne passée en paramètre (un littéral, une concaténation, un résultat de fonction) est formée dans l'anneau des 256 chaînes temporaires (STRRING). Si un paramètre <i>suivant</i> appelait une fonction qui en usait plus de 256 (une boucle de concaténations : <code>L := L + Chr(...)</code> sur tout CONFIG.SYS), l'anneau faisait le tour et recouvrait le premier paramètre avant l'appel. <code>Check('Démarrer le serveur Web avec OS/2', AutoStartOn, ...)</code> recevait ainsi un libellé d'un caractère. Le tampon de l'anneau d'un paramètre chaîne suivi d'autres paramètres est maintenant <b>épinglé</b> (<code>_TPRT_STRPIN</code>) jusqu'à ce que tous les paramètres soient évalués ; l'allocateur de l'anneau (<code>_TPRT_RINGNEXT</code>) saute les tampons épinglés, et l'appelé recopie toujours ses paramètres chaîne dès son entrée.</li>
	<li><b>Adresse dans le résultat d'une fonction</b> : <code>@F^[I]</code>, <code>@F(X)^.Champ</code> ou <code>Move(F^[0], Dest, N)</code>, où <code>F</code> rend un pointeur, donnaient l'adresse du code de la fonction (ou la valeur de l'élément) au lieu de l'adresse de l'élément. La fonction est maintenant appelée et les suffixes (<code>^</code>, <code>[ ]</code>, <code>.</code>) s'appliquent au pointeur rendu, pour <code>@</code> comme pour les paramètres VAR et sans type.</li>
</ul>

<h3>Paint (APPS/PAINT.PAS) : dessin bitmap</h3>

<b>Paint</b> est le programme de dessin d'OS/2-0, dans le dossier <b>Productivité</b> (bureau → Productivité → Paint ; <code>PAINT [fichier]</code> à l'invite). Une image (<code>.BMP</code>, <code>.PCX</code>, <code>.GIF</code>, <code>.PNG</code>, <code>.JPG</code>…) ouverte depuis un dossier du bureau ou depuis l'Explorateur OS2-Zero s'ouvre aussi dans Paint. C'est le <code>PAINT.PAS</code> de Pasdows 95 (lui-même issu de CloneDRAW, pour MS-DOS) : tous les outils (sélection, gomme, remplissage, pipette, loupe, crayon, pinceau, aérographe, texte, ligne, courbe, rectangle, polygone, ellipse, rectangle arrondi), les menus Fichier, Modifier, Affichage, Image, Couleurs, Outils et ?, Annuler/Rétablir, une trentaine de formats d'image en lecture et en écriture.

<img width="800" height="600" alt="OS/2-0 : Paint sur un bureau de 800 x 600, avec PAYSAGE.BMP" src="IMAGE/PAINT.png" />
<img width="800" height="600" alt="OS/2-0 : Paint, menu Image de Presentation Manager" src="IMAGE/PAINT_MENU.png" />

<table>
	<tr><th>Partie</th><th>Version Pasdows 95 (Win32)</th><th>OS/2-0 (Presentation Manager)</th></tr>
	<tr><td>Fenêtre</td><td>Fenêtre Win32 (CreateWindowEx), image de 256 couleurs montrée par SetDIBitsToDevice</td><td>Fenêtre de PM (WinCreateStdWindow : barre de titre, menu système, bouton de réduction, liste des fenêtres), image en mémoire (DosAllocMem) montrée par <code>GpiDrawBits</code>, zones modifiées seulement</td></tr>
	<tr><td>Menus</td><td>Barre de menus dessinée par PAINT</td><td>Barre de menus de PM construite à partir des menus de PAINT : lettres soulignées, raccourcis à droite, éléments grisés ou cochés ; une commande appelle <code>HandleMenuClick</code></td></tr>
	<tr><td>Souris et clavier</td><td>WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_KEYDOWN, WM_CHAR</td><td>WM_MOUSEMOVE, WM_BUTTON1DOWN…, WM_CHAR de PM (codes de <code>ReadKey</code>) ; fermer la fenêtre ou Alt+F4 : Quitter avec confirmation ; F10 active la barre de menus, comme dans OS/2</td></tr>
	<tr><td>Fichiers</td><td colspan="2">Boîtes Ouvrir et Enregistrer sous de PAINT (dossiers et fichiers par DosFindFirst) ; le dossier racine vide d'un lecteur (disque virtuel D:) est maintenant accepté comme destination</td></tr>
</table>

PAINT est dessiné pour un écran de 640 × 480, sa barre de menus comprise. Sur un bureau d'au moins 800 × 600, Paint a une fenêtre complète de 640 × 480 (captures ci-dessus) ; sur un bureau de 640 × 480, comme la version Pasdows 95 qui passait alors en plein écran sans cadre, la fenêtre n'a que la barre de menus de PM, qui prend la place de celle de PAINT, et les boîtes de dialogue sont centrées au-dessus de la ligne d'état. L'exemple <b>PAYSAGE.BMP</b> (<code>IMAGE/EXEMPLES</code>) est copié sur le CD-ROM.

PAINT.PAS (45 000 lignes) est écrit pour Free Pascal : AnsiString, Int64, PByte, l'arithmétique des pointeurs, tableaux dynamiques, Try/Except. Il est compilé par OS2PC comme les autres programmes (fonctions <code>External 'PMWIN'</code> et <code>'PMGPI'</code>) : le compilateur de Pasdows 95, qui descend d'OS2PC et avait ajouté cette syntaxe, a été fusionné dans OS2PC (voir plus haut). Seule la couche de PAINT qui remplaçait Graph, Crt et la souris par Win32 est remplacée, par une couche qui utilise l'API d'OS/2 ; le reste du programme est celui de Pasdows 95. Le noyau fournit maintenant <code>sprintf</code> et <code>strtod</code>, que le runtime d'OS2PC appelle pour écrire et lire les réels (<code>Str</code>, <code>Write</code>, <code>Val</code>) : elles étaient listées dans DOSCALLS.DLL mais absentes, et tout programme qui affichait un réel s'arrêtait (SYS1804).

<h3>WorDium (WORDIUM.PAS) : traitement de texte</h3>

<b>WorDium</b> est le traitement de texte d'OS/2-0, dans le dossier <b>Productivité</b> (bureau → Productivité → WorDium ; <code>WORDIUM [/CLASSICMENU | /RUBANMENU] [document]</code> à l'invite, <code>WORDIUM /?</code> : aide). Un document (<code>.DOCX</code>, <code>.DOC</code>, <code>.PDF</code>, <code>.GAT</code>, <code>.GPX</code>, <code>.WPD</code>) ouvert depuis un dossier du bureau ou depuis l'Explorateur OS2-Zero s'ouvre aussi dans WorDium. C'est le <code>WORD.PAS</code> du dépôt OFFICE-0, écrit pour MS-DOS (BGI en 640 × 480, souris de l'interruption 33h), porté vers Presentation Manager avec toutes ses fonctions :

<ul>
	<li>saisie et mise en forme : gras, italique, souligné, tailles de 6 à 72 points, 16 couleurs, alignements (gauche, centré, droite, justifié), retraits, filets, sauts de page ; affichage Normal ou Mise en page, règle, zoom ;</li>
	<li>tableaux (insertion, lignes et colonnes, menu contextuel du bouton droit), images (BMP, PCX, GIF, JPEG, TIFF, XBM, BGX, GPX), symboles ;</li>
	<li>boîtes Police, Paragraphe, Zoom, Rechercher, Remplacer, Statistiques, Options, Sommaire de l'aide, À propos ; Annuler et Rétablir ;</li>
	<li>formats : <b>WPD</b> (format natif), <b>DOCX</b> (lecture et écriture : ZIP et Deflate écrits en Pascal, styles, numérotation, en-têtes et pieds de page, images), <b>DOC</b> de Word 97 (lecture), <b>PDF</b> (lecture : texte placé, flux FlateDecode, graphiques), <b>GAT</b> du MonsterBook (lecture et écriture : attributs gras, souligné, italique, double largeur, images <code>[DC:</code>), <b>GPX</b> ;</li>
	<li><b>correcteur d'orthographe</b> (F7) : français, anglais, allemand, espagnol et italien, suggestions, Remplacer, Ignorer ;</li>
	<li>cinq langues de l'interface, comme la version DOS : la variable <code>LANGUAGE</code> (réglée par Configuration du système) choisit le français, l'anglais (EN), l'espagnol (ES ou SP), l'italien (IT) ou l'allemand (DE ou GR) ;</li>
	<li>menus classiques (style Word 2003, par défaut) ou ruban (<code>/RUBANMENU</code>, style Word 2007).</li>
</ul>

<img width="800" height="600" alt="OS/2-0 : WorDium sur un bureau de 800 x 600, avec le document MONSTER.GAT du MonsterBook" src="IMAGE/WORDIUM.png" />
<img width="800" height="600" alt="OS/2-0 : WorDium, correcteur d'orthographe en français" src="IMAGE/WORDIUM_ORTHO.png" />

<table>
	<tr><th>Partie</th><th>Version DOS (OFFICE-0)</th><th>OS/2-0 (Presentation Manager)</th></tr>
	<tr><td>Fenêtre</td><td>Plein écran BGI 640 × 480, barre de menus dessinée par WorDium</td><td>Fenêtre de PM (barre de titre avec le nom du document, menu système, bouton de réduction, liste des fenêtres) ; l'image de 640 × 480 est gardée en mémoire et montrée par <code>GpiDrawBits</code>, zones modifiées seulement</td></tr>
	<tr><td>Menus</td><td>Menus déroulants de WorDium, F10, Alt+lettre</td><td>Barre de menus de PM construite à partir des menus de WorDium (lettres soulignées, raccourcis à droite, coches de l'Affichage) ; avec le ruban, les titres de la barre de menus de PM sont les onglets</td></tr>
	<tr><td>Boîtes</td><td>Cadres gris, barre de titre bleue</td><td>Barre de titre d'OS/2 (case du menu système, titre centré) ; messages et questions par <code>WinMessageBox</code></td></tr>
	<tr><td>Clavier et souris</td><td><code>ReadKey</code>, interruption 33h ou PtcMouse avec flèche dessinée par WorDium</td><td>WM_CHAR (codes de <code>ReadKey</code>, lettres accentuées de la page de codes 850 acceptées), WM_BUTTON*, pointeur de PM ; fermer la fenêtre : Fichier → Quitter</td></tr>
	<tr><td>Impression</td><td>Absente (« Impression disponible sous Windows »)</td><td>Tampon d'impression d'OS/2 : chaque page est dessinée par la GPI (<code>DevOpenDC</code> OD_QUEUED, PM_Q_STD) et imprimée par PMSPL et PicPrint en graphique ESC/P, page de 8 × 10,5 pouces</td></tr>
</table>

<img width="480" height="633" alt="OS/2-0 : page imprimée par WorDium (MONSTER.GAT), sortie ESC/P du port LPT1 décodée" src="IMAGE/WORDIUM_IMPRESSION.png" />

Les exemples <b>MONSTER.GAT</b> (MonsterBook) et <b>LETTRE.PDF</b> (<code>IMAGE/EXEMPLES</code>) sont copiés sur le CD-ROM. WORDIUM.PAS (18 000 lignes) est compilé par OS2PC ; le portage a été vérifié en comparant, fichier par fichier, ce que lisent et écrivent WorDium compilé par Free Pascal sous Linux et WorDium compilé par OS2PC sous OS/2-0 (quatre PDF, un GAT, un DOCX, les enregistrements DOCX, GAT et WPD, les suggestions du correcteur dans les cinq langues) : les résultats sont identiques, et LibreOffice ouvre les DOCX écrits par WorDium. Ce travail a corrigé OS2PC : <code>Assign</code>, <code>Reset</code>, <code>Rewrite</code>, <code>Close</code>… sur une variable fichier qui est un champ d'enregistrement (<code>Z.F</code>), <code>Byte('&lt;')</code> (code du caractère), paramètres <code>Const</code> chaîne recopiés à l'entrée (une chaîne temporaire pouvait être recouverte), types du programme qui masquent les types prédéfinis du même nom (<code>PWord</code>), champs d'un <code>With</code> prioritaires sur les variables, <code>ClrEol</code> qui applique la couleur courante (la ligne de titre de CMD est bleue sur toute la largeur). Le noyau sert les <code>GetMem</code> de 64 Ko et plus par de grands blocs de mémoire physique (le tas du noyau ne compte que quelques Mo) ; PMSPL transmet la taille de page <code>/W:</code> <code>/H:</code> à PicPrint.

<h3>Excelsior (EXCELSIO.PAS) : tableur</h3>

<b>Excelsior</b> est le tableur d'OS/2-0, dans le dossier <b>Productivité</b> (bureau → Productivité → Excelsior ; <code>EXCELSIO [/CLASSICMENU | /RUBANMENU] [classeur]</code> à l'invite, <code>EXCELSIO /?</code> : aide). Un classeur (<code>.XLC</code>, <code>.XLS</code>, <code>.XLSX</code>) ouvert depuis un dossier du bureau ou depuis l'Explorateur OS2-Zero s'ouvre aussi dans Excelsior. C'est le <code>EXCEL.PAS</code> du dépôt OFFICE-0, écrit pour MS-DOS (BGI en 640 × 480, souris de l'interruption 33h), porté vers Presentation Manager avec toutes ses fonctions :

<ul>
	<li>les mêmes dimensions que la version DOS : <b>16 feuilles de 4096 lignes sur 256 colonnes</b> (A à IV), lignes allouées à la demande ; onglets des feuilles (insérer, renommer, supprimer), largeurs des colonnes et hauteurs des lignes ;</li>
	<li>saisie et barre de formule ; <b>formules</b> avec opérateurs (+ − × ÷ ^ &amp; comparaisons), plages et références, recalcul automatique, erreurs (#DIV/0!, #VALUE!, #NAME?, #CIRC!) et une cinquantaine de fonctions en anglais ou en français (SUM, AVERAGE/MOYENNE, MIN, MAX, COUNT, PRODUCT/PRODUIT, IF/SI, ROUND/ARRONDI, SQRT/RACINE, POWER/PUISSANCE, LEFT/GAUCHE, MID/STXT, LEN/NBCAR, UPPER/MAJUSCULE, AND/ET, OR/OU, MOD, INT/ENT, PI, TODAY/AUJOURDHUI…) ;</li>
	<li>sélection (souris, F8), Couper, Copier, Coller, Annuler et Rétablir (30 niveaux), menus contextuels des cellules et des onglets ;</li>
	<li>mise en forme des cellules : gras, italique, souligné, alignements, formats Nombre, Pourcentage, Monétaire, Date et Texte, couleurs du texte et du fond ;</li>
	<li><b>graphiques</b> (barres, lignes, secteurs) et images BMP ancrés aux cellules ;</li>
	<li>formats : <b>XLC</b> (format natif), <b>XLS</b> d'Excel 97 à 2003 (BIFF8 dans un conteneur OLE2, lecture et écriture) et <b>XLSX</b> (ZIP et Deflate écrits en Pascal, lecture et écriture) ; boîtes Ouvrir et Enregistrer sous avec les lecteurs et les dossiers ;</li>
	<li>menus classiques (style Excel 2003, par défaut) ou ruban (<code>/RUBANMENU</code>, style Excel 2007).</li>
</ul>

<img width="800" height="600" alt="OS/2-0 : Excelsior sur un bureau de 800 x 600, avec le classeur BUDGET.XLC et un graphique en secteurs" src="IMAGE/EXCELSIOR.png" />
<img width="800" height="600" alt="OS/2-0 : Excelsior avec le ruban (/RUBANMENU)" src="IMAGE/EXCELSIOR_RUBAN.png" />

<table>
	<tr><th>Partie</th><th>Version DOS (OFFICE-0)</th><th>OS/2-0 (Presentation Manager)</th></tr>
	<tr><td>Fenêtre</td><td>Plein écran BGI 640 × 480, barre de menus dessinée par Excelsior</td><td>Fenêtre de PM (barre de titre avec le nom du classeur, menu système, bouton de réduction, liste des fenêtres) ; l'image de 640 × 480 est gardée en mémoire et montrée par <code>GpiDrawBits</code>, zones modifiées seulement</td></tr>
	<tr><td>Menus</td><td>Menus déroulants d'Excelsior, F10, Alt+lettre</td><td>Barre de menus de PM construite à partir des menus d'Excelsior (lettres soulignées, raccourcis à droite ; les commandes que la version DOS n'a pas sont grisées, comme dans son ruban) ; avec le ruban, les titres de la barre de menus de PM sont les onglets</td></tr>
	<tr><td>Boîtes</td><td>Cadres gris, barre de titre bleue</td><td>Barre de titre d'OS/2 (case du menu système, titre centré) ; messages et confirmations par <code>WinMessageBox</code></td></tr>
	<tr><td>Clavier et souris</td><td><code>ReadKey</code>, interruption 33h ou PtcMouse</td><td>WM_CHAR (codes de <code>ReadKey</code>), WM_BUTTON*, pointeur de PM ; Alt+F4 ou fermer la fenêtre : Quitter ; la boucle principale rend la main à OS/2 quand il n'y a rien à faire</td></tr>
</table>

L'exemple <b>BUDGET.XLC</b> (<code>IMAGE/EXEMPLES</code> : deux feuilles, une trentaine de formules, formats et couleurs) est copié sur le CD-ROM. EXCELSIO.PAS (9 400 lignes) est compilé par OS2PC ; le portage a été vérifié en comparant ce que lisent et écrivent Excelsior compilé par Free Pascal sous Linux et Excelsior compilé par OS2PC sous OS/2-0 (un XLC avec formules, un XLSX et un XLS écrits par LibreOffice ; pour chacun, les cellules calculées, puis les enregistrements XLC, XLS et XLSX relus) : les résultats sont identiques (les fichiers XLC d'OS/2 ont des fins de ligne CR-LF). Des défauts de la version DOS sont corrigés : le flux XLS de moins de 4096 octets (qui doit aller dans le mini-flux d'OLE2) est complété comme le fait Excel et la longueur de l'enregistrement FONT est la bonne (ni Excel, ni LibreOffice, ni Excelsior lui-même ne relisaient les XLS d'Excelsior ; LibreOffice les ouvre maintenant) ; la lecture XLS prend les nombres RK et MULRK et les résultats des formules (FORMULA, STRING) qu'écrivent Excel et LibreOffice ; une formule dont le résultat est un texte (<code>=SI(…;"grand";"petit")</code>, <code>=A2&amp;" et "&amp;A3</code>) est enregistrée en XLS et en XLSX avec ce texte, et non comme le nombre 0. Ce travail a corrigé OS2PC : un <code>Break</code> ou un <code>Continue</code> placé dans un <code>Case</code> laissait le sélecteur du <code>Case</code> sur la pile (la boucle <code>For</code> qui l'entourait relisait sa borne au mauvais endroit). Le noyau honore la réserve de pile de l'en-tête PE quand un programme demande plus de 1 Mo (<code>{$M}</code> d'OS2PC ; Excelsior prend 2 Mo pour l'évaluation récursive des formules) et sert jusqu'à 2048 grands blocs de mémoire par processus (une ligne d'Excelsior en est un).

<h3>Outlink (OUTLINK.PAS) : courrier IMAP, POP3 et SMTP</h3>

<b>Outlink</b> est le client de messagerie d'OS/2-0, dans le dossier <b>Productivité</b> (bureau → Productivité → Outlink ; <code>OUTLINK [/ACCOUNTS:fichier]</code> à l'invite). C'est un portage de <code>OUTLOOK.PAS</code>, le clone d'Outlook du dépôt OFFICE-0, écrit pour MS-DOS : la version d'origine dessine avec l'unité Graph du BGI, lit la souris par l'interruption 33h et passe par un pilote de paquets pour le réseau. Sous OS/2-0, Outlink est une vraie fenêtre de Presentation Manager, avec la barre de titre et la barre de menus d'OS/2 (Fichier, Édition, Affichage, Outils, Message, ?, avec leurs lettres soulignées et leurs raccourcis), et ses communications passent par l'API réseau d'OS/2 : les sockets de <b>TCPIP32.DLL</b> (<code>gethostbyname</code>, <code>socket</code>, <code>connect</code>, <code>send</code>, <code>recv</code>, <code>soclose</code>) et le chiffrement de <b>TLS32.DLL</b> (TLS 1.3 et 1.2).

<img width="640" height="480" alt="OS/2-0 : Outlink, boîte de réception IMAP et prévisualisation d'un message" src="IMAGE/OUTLINK.png" />
<img width="640" height="480" alt="OS/2-0 : Outlink, nouveau message" src="IMAGE/OUTLINK_MESSAGE.png" />

<table>
	<tr><th>Partie</th><th>Description</th></tr>
	<tr><td>Fenêtre</td><td>Barre d'outils (Nouveau, Répondre, Répondre à tous, Transférer, Envoyer/Recevoir, Supprimer, Imprimer, Adresses), dossiers des comptes, liste des messages (priorité, pièce jointe, indicateur, De, Objet, Date JJ/MM/AA, Taille ; tri par colonne), volet de prévisualisation avec défilement, barre d'état. L'image est dessinée en mémoire et seules les zones changées sont recopiées (<code>GpiDrawBits</code>).</td></tr>
	<tr><td>Comptes</td><td>Outils → Comptes (fichier <code>OUTLINK.ACC</code> à côté du programme, ou <code>/ACCOUNTS:</code>) : réception IMAP ou POP3, envoi SMTP (AUTH PLAIN) ; pour chaque serveur, sans chiffrement, TLS implicite (993, 995, 465) ou STARTTLS (IMAP, SMTP) / STLS (POP3).</td></tr>
	<tr><td>Envoyer/Recevoir (F5)</td><td>Relève la boîte de réception du compte choisi (les 100 messages les plus récents) ; au démarrage, relève du compte par défaut. Une fenêtre d'attente montre l'avancement.</td></tr>
	<tr><td>Lecture</td><td>Clic ou flèches, Pg préc./Pg suiv., Début, Fin (la liste défile ; la version DOS ne montrait que les premiers messages). En-têtes MIME (<code>=?UTF-8?Q?…?=</code>, <code>=?ISO-8859-1?B?…?=</code>), corps <i>quoted-printable</i> ou base64, parties <code>multipart</code> (le texte est choisi, les pièces jointes signalées), HTML ramené à du texte (paragraphes, listes, entités <code>&amp;eacute;</code> et <code>&amp;#233;</code>, style et script omis) ; UTF-8, ISO-8859-1 et Windows-1252 convertis en page de codes 850 : les accents sont conservés (la version DOS les retirait). Messages complets gardés dans de grands tampons (la version DOS se limitait à des chaînes de 255 caractères).</td></tr>
	<tr><td>Écriture</td><td>Nouveau message (Ctrl+N), Répondre (Ctrl+R), Transférer (Ctrl+F) : A, Cc, Cci (plusieurs adresses séparées par des virgules), Objet, texte ; envoi en Windows-1252 8 bits, transparence des points (<i>dot-stuffing</i>). Fichier → Ouvrir (.eml) et Enregistrer sous.</td></tr>
</table>

Les raccourcis affichés dans les menus (F1, F5, Ctrl+lettre, Suppr) sont maintenant tous traités ; Échap ferme les menus et les boîtes mais ne quitte plus le programme (Fichier → Quitter ou Alt+F4). Limites : les pièces jointes ne sont pas envoyées, et comme pour le Navigateur Web et WGET, le certificat du serveur n'est pas vérifié. Il faut le composant <b>Réseau TCP/IP</b> de l'installation (TCPIP32.DLL, TLS32.DLL et un pilote de carte).

Le portage a mis au jour quelques défauts corrigés au passage : <b>OS2PC</b> comparait mal deux chaînes calculées (<code>Copy(S,1,6) = T + ' '</code> était toujours vrai : l'opérande de gauche est maintenant copié dans un tampon avant la comparaison), <code>Delete(S, I, N)</code> lisait au-delà de la fin de la chaîne quand <code>N</code> dépassait la longueur (le nombre est maintenant borné), <code>GetFAttr</code> et <code>SetFAttr</code> lisaient le nom à la mauvaise place dans la variable fichier et réutilisaient les mêmes étiquettes à chaque appel (deux <code>GetFAttr</code> dans un programme faisaient boucler le second), et les zéros de fin du segment de données n'étaient pas écrits dans le .EXE (les données initialisées sont placées avant les tableaux à zéro, que le chargeur du noyau remplit déjà de zéros ; OUTLINK.EXE fait ainsi 1 Mo). <b>PMGPI.DLL</b> convertissait la couleur de chaque point dans <code>GpiDrawBits</code> ; une copie simple (SRCCOPY, sans étirement, image de 1, 4 ou 8 bits par point) convertit maintenant la palette une seule fois, ce qui accélère tous les programmes qui dessinent dans une image en mémoire (Outlink, Notator, les jeux).

<h3>Multimédia : Audio numérique (DIGAUDIO.PAS), MDM.DLL et pilotes des cartes son</h3>

Le dossier <b>Multimédia</b> du bureau contient <b>Audio numérique</b>, l'application « Digital Audio » de MMPM/2 (le multimédia d'OS/2 Warp), et les sons du système ; un fichier <code>.WAV</code> ouvert depuis un dossier du bureau s'ouvre aussi dans Audio numérique. Tout est écrit en Pascal et compilé par OS2PC, avec trois nouveaux pilotes pour les cartes son les plus répandues.

<img width="640" height="480" alt="OS/2-0 : Audio numérique (lecture de DEMARRE.WAV) ouvert depuis le dossier Multimédia" src="IMAGE/AUDIONUM.png" />

<table>
	<tr><th>Élément</th><th>Rôle</th></tr>
	<tr><td><b>Audio numérique</b> (DIGAUDIO.PAS → DIGAUDIO.EXE)</td><td>Fenêtre de Warp : informations d'édition (partie affichée, sélection avec champs à flèches), boutons début, arrêt, pause, lecture, fin, enregistrement, position du média (position, longueur, temps d'enregistrement disponible), bouton du volume, forme d'onde (clic : position ; glisser ou Maj+clic : sélection ; curseur de lecture ; barre de défilement). Menus Fichier (nouveau, ouvrir, enregistrer, enregistrer sous : boîte avec unités, répertoires et fichiers WAV), Édition (annuler, couper, copier, coller, supprimer, tout sélectionner), Affichage (zoom), Options (effets sur la sélection ou tout le son : inverser, amplifier, atténuer, fondus entrant et sortant, écho, silence), Contrôle, Type (11 025, 22 050, 44 100 Hz ; 8 ou 16 bits ; mono ou stéréo : le son est converti), Aide. Clavier : Espace lecture/arrêt, Début, Fin, flèches (Maj : sélection), Suppr, Ctrl+X, C, V, Z, R. L'enregistrement remplace la sélection ou s'insère à la position. Fichiers WAV PCM 8 ou 16 bits, mono ou stéréo, jusqu'à 3 Mo de son.</td></tr>
	<tr><td><b>MDM.DLL</b> (DLL/MDM.PAS)</td><td>Le « Media Device Manager » de MMPM/2 : choix du pilote (variable <code>AUDIODRIVER</code> de CONFIG.SYS : SBAUDIO, ICHAUDIO, ESAUDIO ou NONE ; sans elle, détection), fil de flux qui remplit le tampon circulaire de la carte en convertissant le son au format de la carte (8/16 bits, mono/stéréo, changement de fréquence) avec le volume ; interface de chaînes MCI <code>mciSendString</code> pour l'appareil <code>waveaudio</code> (open, play, record, stop, pause, resume, seek, status, set, save, close, info, capability, sysinfo ; positions en millisecondes, échantillons ou octets ; <code>notify</code> poste MM_MCINOTIFY) et <code>mciGetErrorString</code> ; points d'entrée internes MDMPLAY, MDMRECORD, MDMSTOP, MDMPAUSE, MDMPOSITION, MDMSTATE, MDMVOLUME, MDMAUDIOINFO, MDMCARDFORMAT, et MDMSTREAM, MDMFEED pour jouer en flux un son produit au fur et à mesure (Lecteur MP3).</td></tr>
	<tr><td><b>SBAUDIO.DLL</b> (DLL/SBAUDIO.PAS)</td><td>Creative Sound Blaster 1.x, 2.0, Pro, 16 (et AWE32/64, compatibles) : DSP aux ports 220h à 280h (ou variable <code>BLASTER</code>), version du DSP, DMA ISA 8 bits et 16 bits du 8237 en mode auto-initialisé, mélangeur ; SB16 : 8/16 bits, mono/stéréo, 5 000 à 44 100 Hz.</td></tr>
	<tr><td><b>ICHAUDIO.DLL</b> (DLL/ICHAUDIO.PAS)</td><td>AC'97 des jeux de composants Intel (ICH à ICH7, 440MX) et compatibles (nVidia nForce, AMD-8111) : recherche sur le bus PCI, remise à zéro du lien AC'97, codec (volumes, fréquence variable VRA), bus maître avec une liste de 32 descripteurs parcourue en boucle ; lecture et enregistrement.</td></tr>
	<tr><td><b>ESAUDIO.DLL</b> (DLL/ESAUDIO.PAS)</td><td>Ensoniq AudioPCI ES1370 (Sound Blaster PCI 64) : bus maître PCI, canaux DAC2 (lecture) et ADC (enregistrement) en boucle, diviseur de fréquence, codec AK4531 ; lecture et enregistrement.</td></tr>
</table>

Un pilote de carte son est une DLL à un seul point d'entrée, <code>AUDIOSTRATEGY</code> (ordinal 1), qui reçoit un paquet de requête comme un pilote de périphérique d'OS/2 : détecter, ouvrir (format demandé → format de la carte, tampon circulaire de 64 Ko pris dans le tas du noyau, en mémoire basse : convient au DMA ISA et au bus maître PCI), démarrer, position, arrêter, volume, fermer. La position est lue dans la carte (compteur du 8237, CIV/PICB de l'AC'97, compteur de trame de l'ES1370) : les pilotes n'ont pas besoin des interruptions. Un programme de Presentation Manager n'étant pas préempté, MDM.DLL alimente aussi le tampon quand le programme demande la position du flux.

<img width="640" height="480" alt="OS/2-0 : le dossier Multimédia du bureau (Audio numérique, Lecteur MP3, Notator for OS2-Zero, sons)" src="IMAGE/MULTIMEDIA.png" />

Le noyau donne maintenant aux processus de grands blocs de mémoire (KrnTaskCtl 15 à 17 : mémoire physique au-delà de 16 Mo, vue à la même adresse, rendue à la fin du processus) : DOSCALLS.DLL les utilise pour DosAllocMem à partir de 64 Ko, au lieu du petit tas du noyau. Le programme <b>DLL/TESTMDM.PAS</b> vérifie MDM.DLL et le pilote (41 vérifications : lecture à 11 025, 22 050 et 44 100 Hz en 8 et 16 bits, mono et stéréo, pause, reprise, arrêt, chaînes MCI, enregistrement, sauvegarde et relecture d'un WAV) ; avec QEMU, <code>-audiodev wav</code> recueille le son produit :

<pre>qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d -audiodev wav,id=son,path=sortie.wav -device sb16,audiodev=son
qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d -audiodev pa,id=son -device AC97,audiodev=son
qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d -audiodev pa,id=son -device ES1370,audiodev=son</pre>

Les sons <b>DEMARRE.WAV</b> (carillon, 22 050 Hz, 16 bits, mono) et <b>CLOCHE.WAV</b> (11 025 Hz, 8 bits, stéréo) de <b>IMAGE/SONS</b> sont des sons originaux synthétisés. Écrire ces programmes a fait apparaître d'autres pièges d'OS2PC : <code>Detect</code> (constante de l'unité Graph) et <code>Mem</code> (tableau de Turbo Pascal) sont des noms réservés qui ne peuvent pas nommer une fonction ou une variable.

<h3>Lecteur MP3 (MP3PLAY.PAS)</h3>

Le <b>Lecteur MP3</b> du dossier <b>Multimédia</b> joue les fichiers MP3 (MPEG-1, 2 et 2.5 Layer III, débit fixe ou variable, mono ou stéréo, 8 000 à 48 000 Hz) dans l'apparence des appareils multimédias de Warp, avec les menus déroulants habituels : afficheur noir (temps en chiffres à sept segments, titre défilant, débit, fréquence, stéréo, numéro du morceau, analyseur de spectre, voyants ÉGAL, ALÉA, RÉP), barre de position, boutons début, recul, lecture, pause, arrêt, avance, fin et éjection (ouvrir), volume, balance, aléatoire et répéter, et un carnet à deux onglets : <b>Liste de lecture</b> et <b>Égaliseur</b>. Tout est dans un seul fichier source, <b>MP3PLAY.PAS</b>, compilé par OS2PC : le décodeur vient de <code>PLAYMP3.PAS</code> (dépôt MP3-Player-0 : décodeur procédural sans bibliothèque externe ; tables Huffman et fenêtre de synthèse de PDMP3, domaine public ; tables de bandes et facteurs LSF de minimp3, CC0), accéléré pour le temps réel (table |x|^(4/3), synthèse polyphase et IMDCT par symétrie, anneau de synthèse, sous-bandes nulles sautées). Le son passe par MDM.DLL et le pilote de la carte son.

<img width="640" height="480" alt="Lecteur MP3 : lecture d'AURORE.MP3, liste de lecture et analyseur de spectre" src="IMAGE/MP3PLAY.png" />

<table>
	<tr><th>Fonction</th><th>Détails</th></tr>
	<tr><td>Liste de lecture</td><td>Ajouter des fichiers ou un dossier entier, retirer, effacer, monter, descendre, trier (titre ou nom de fichier), mélanger ; double clic ou Entrée : jouer ; durée de chaque morceau (en-tête Xing/Info ou débit) et durée totale. Titre et artiste des étiquettes ID3 v1 et v2.2 à v2.4 (Latin-1, UTF-16, UTF-8). Listes M3U (ouvrir, enregistrer). La liste n'a pas de taille maximale. Elle est gardée d'une fois à l'autre (MP3PLAY.M3U dans le dossier du programme) avec le volume, la balance, l'égaliseur et les options (MP3PLAY.INI) ; au premier lancement, elle contient les MP3 du dossier du programme.</td></tr>
	<tr><td>Égaliseur</td><td>10 bandes (60 Hz à 16 kHz) et préamplification, de −12 à +12 dB, et 12 préréglages (Normal, Classique, Club, Danse, Basses, Aigus, Basses et aigus, Rock, Pop, Jazz, Voix, Salle de concert). Il agit sur les 576 raies de fréquence de chaque granule avant la synthèse ; le spectre affiché est celui du son en train d'être joué.</td></tr>
	<tr><td>Menus</td><td>Fichier (ouvrir, ajouter des fichiers ou un dossier, ouvrir et enregistrer une liste M3U, informations sur le morceau, quitter), Lecture (lecture/pause, arrêt, précédent, suivant, reculer et avancer de 5 s, aléatoire, répéter la liste ou le morceau), Liste (jouer la sélection, retirer, effacer, monter, descendre, trier, mélanger), Égaliseur (actif, préréglages), Affichage (onglet, temps écoulé ou restant, spectre), Aide.</td></tr>
	<tr><td>Clavier</td><td>Espace lecture/pause, S arrêt, ← et → (5 s), Pg préc. et Pg suiv. (morceau), + et − (volume), ↑ et ↓ (sélection), Entrée (jouer la sélection), Suppr (retirer), Ctrl+O (ouvrir), Ctrl+A (ajouter), F1 (aide).</td></tr>
	<tr><td>Ligne de commande</td><td><code>MP3PLAY [fichier.MP3 ... | liste.M3U] [/NOSAVE]</code> : les morceaux donnés sont joués tout de suite ; sans paramètre, la liste de la dernière fois. Un <code>.MP3</code> ou un <code>.M3U</code> ouvert depuis un dossier du bureau s'ouvre dans le Lecteur MP3.</td></tr>
</table>

<img width="640" height="480" alt="Lecteur MP3 : page Égaliseur (préréglage Rock)" src="IMAGE/MP3PLAYEQ.png" />

Un fil d'exécution décode le MP3 en avance dans un anneau de 3 secondes que MDM.DLL joue en flux : <code>MDMSTREAM</code> (ordinal 109) donne l'anneau et le format, <code>MDMFEED</code> (ordinal 110) annonce le nombre d'octets écrits et rend la position jouée ; si le décodeur prend du retard, MDM joue du silence sans avancer. Un programme de Presentation Manager n'étant pas préempté, le fil du décodeur cède le processeur après chaque trame par <code>DosSleep(0)</code>, qui passe maintenant la main aux autres fils (KDelay(0) du noyau) : la fenêtre reste active pendant la lecture. Le morceau d'exemple <b>AURORE.MP3</b> de <b>IMAGE/MUSIQUE</b> (« Aurore sur Warp », 28 s, 128 kbit/s) est une composition originale synthétisée.

<h3>OpenGL (OPENGL.DLL) et Essai OpenGL (APPS/GLTEST.PAS)</h3>

OS/2-0 a maintenant <b>OpenGL 1.1</b> : <b>OPENGL.DLL</b> (DLL/OPENGL.PAS) est un rendu logiciel porté de l'OPENGL32.DLL de <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a> (moteur de rastérisation et couche GL de son noyau VMM32), avec l'interface de Presentation Manager de l'OpenGL d'OS/2 Warp (<b>PGL</b>) à la place de WGL : <code>pglChooseConfig</code> (attributs PGL_RGBA, PGL_DOUBLEBUFFER, PGL_DEPTH_SIZE…), <code>pglQueryConfigs</code>, <code>pglCreateContext</code>, <code>pglMakeCurrent(hab, hgc, hwnd)</code>, <code>pglSwapBuffers(hab, hwnd)</code> (tampon arrière recopié dans la zone client par <code>GpiDrawBits</code> en 24 bits), <code>pglDestroyContext</code>, <code>pglGetCurrentContext</code>, <code>pglQueryVersion</code>… : 389 fonctions exportées (371 <code>gl*</code>, 18 <code>pgl*</code>).

<ul>
	<li>Sommets par glBegin/glEnd et tableaux de sommets (glDrawArrays, glDrawElements, glInterleavedArrays), piles de matrices, 8 lumières et matériaux, brouillard, découpage, textures 2D corrigées en perspective (deux unités), tampon Z de 24 bits, test et mélange alpha, glScissor, glPushAttrib, glGet*, glReadPixels et glDrawPixels.</li>
	<li>Les tampons suivent la taille de la fenêtre (agrandir la fenêtre les recrée).</li>
	<li>Comme dans Pasdows, les listes d'affichage, l'accumulation, le stencil, les évaluateurs, le mode sélection et <code>pglUseFont</code> sont acceptés sans effet ; seul le mode RVB existe (pas d'index de couleur).</li>
	<li>Les paramètres flottants suivent la convention de Pasdows : un <code>float</code> est passé par ses 32 bits IEEE (LongInt), un <code>double</code> en deux LongInt (bas, haut).</li>
	<li>PMGPI.DLL a un chemin rapide pour <code>GpiDrawBits</code> d'une image de 24 bits par pel (sans étirement) : la recopie de chaque image est environ trois fois plus rapide.</li>
</ul>

L'objet <b>Essai OpenGL</b> du dossier <b>Multimédia</b> (GLTEST.EXE, l'exemple de Pasdows réécrit pour Presentation Manager) dessine un cube texturé et éclairé (glBegin/glEnd), une pyramide en tableaux de sommets (glDrawElements), un sol dans le brouillard et un carré translucide (mélange alpha), en double tampon ; Échap ou la fermeture de la fenêtre pour quitter. Il écrit dans le journal le nom du rendu et, après 30 images, l'erreur GL (0).

<img width="640" height="480" alt="OS/2-0 : Essai OpenGL (cube texturé et éclairé, pyramide, sol dans le brouillard, carré translucide)" src="IMAGE/OPENGL_GLTEST.png" />

<h3>Notator for OS2-Zero (NOTATOR.PAS)</h3>

<b>Notator for OS2-Zero</b> est le portage pour Presentation Manager de <code>NOTATOR.PAS</code> du dépôt OFFICE-0, un clone du séquenceur MIDI et éditeur de partition <i>Notator SL</i> (Turbo Pascal 7 et Free Pascal : BGI en 640 × 480, souris de l'interruption 33h, haut-parleur, MPU-401 ou synthétiseur de Windows). On le lance par l'objet <b>Notator for OS2-Zero</b> du dossier <b>Multimédia</b>, ou à l'invite : <code>NOTATOR [fichier.SON | fichier.MID] [/PLAY]</code> ; il s'ouvre (seul ou avec un morceau) sur l'édition de partition (F1 : page d'arrangement). Les exemples d'OFFICE-0 (<code>SAMPLES/NOTATOR</code>) sont fournis dans <b>IMAGE/NOTATOR</b> et copiés à la racine du CD-ROM et du disque : <code>BLUES_C</code>, <code>CANON_RE</code>, <code>FREREJAC</code> (<code>FRERE_JACQUES</code>, nom 8.3), <code>GROOVES</code>, <code>ODE_JOIE</code> et <code>TWINKLE</code>, chacun en <code>.SON</code> et en <code>.MID</code>, avec <code>NOTATOR.TXT</code>.

<img width="640" height="480" alt="Notator for OS2-Zero : page d'arrangement de BLUES_C.SON pendant la lecture" src="IMAGE/NOTATOR.png" />

Toutes les fonctions de la version DOS sont conservées : page d'arrangement (4 chaînes de 99 patterns de 16 pistes, paramètres de piste, boutons DROP, PUNCH, SOLO, MUTE, CYCLE…), partition (clés, armures, ligatures, triolets, silences, paroles, palette de 14 symboles, hyper-éditeur de vélocité ou de contrôleurs), matrice (piano roll), liste d'événements avec filtres, quantification et groove adaptatif, transposition, vélocité, longueurs, copie de pistes, de patterns et de mesures, insertion et suppression de mesures, annulation, presse-papiers, enregistrement au clavier d'ordinateur (Z..M et Q..P), métronome, décompte, boucle entre locators, punch, morceau de démonstration, fichiers <code>.SON</code> et MIDI standard (lecture et écriture), impression de la partition et copie d'écran PBM, options dans <code>NOTATOR.OPT</code>, trois langues (<code>LANGUAGE=EN</code>, FR ou GR).

<img width="640" height="480" alt="Notator for OS2-Zero : partition d'ODE_JOIE.SON avec les paroles (F2)" src="IMAGE/NOTATOR_PARTITION.png" />

<table>
	<tr><th>Version DOS</th><th>Notator for OS2-Zero</th></tr>
	<tr><td>Écran BGI de 640 × 480 en 16 couleurs</td><td>Image de 640 × 480 en mémoire (un octet par point, couleurs du BGI) montrée dans la zone client par <code>GpiDrawBits</code>, seulement pour les zones modifiées ; les routines de Graph utilisées (Line, Rectangle, Bar, FillPoly, Ellipse, FillEllipse, Arc, PutPixel, GetPixel, OutTextXY avec la police 8 × 8, styles de trait et de remplissage, SetWriteMode) sont écrites dans le programme.</td></tr>
	<tr><td>Barre de menus et barre de titre GEM dessinées (lignes 0 à 33)</td><td>Barre de titre (nom du morceau, <code>*</code> s'il est modifié) et barre de menus de PM construites à partir des tables de menus d'origine (mêmes commandes, raccourcis affichés, coches et éléments grisés mis à jour par WM_INITMENU) ; F12 ouvre la barre de menus, F10 reste la touche de NOTATOR (valeur de note) ; la fermeture de la fenêtre passe par Quitter.</td></tr>
	<tr><td>Boîtes de dialogue noir et blanc</td><td>Style d'OS/2 : fond gris, barre de titre bleue avec menu système, boutons et champs en relief ; les confirmations sont des <code>WinMessageBox</code>. L'aide (F11) n'est plus tronquée à 255 caractères.</td></tr>
	<tr><td>KeyPressed, ReadKey, souris de l'Int 33h</td><td>File d'événements remplie par la procédure de fenêtre (WM_CHAR traduit en codes du BIOS, boutons et déplacements de la souris, commandes des menus) ; quand rien n'attend, le moteur avance (lecture, enregistrement, métronome) et le programme rend la main quelques millisecondes.</td></tr>
	<tr><td>Haut-parleur, MPU-401, synthétiseur waveOut de Windows</td><td>Le synthétiseur logiciel (ondes, enveloppes, sons de batterie) est joué par <b>MDM.DLL</b> sur la carte son (Sound Blaster 16, AC'97, ES1370) : un flux de 20 s (44 100 Hz, 16 bits, stéréo) rempli juste devant la position de lecture ; menu MIDI → Sortie MIDI : carte son, MPU-401 (réservé à la version DOS) ou aucune.</td></tr>
	<tr><td>Fichiers <code>.SON</code> écrits avec BlockWrite des enregistrements</td><td>Même disposition, octet par octet (OS2PC range les <code>String[n]</code> sur 256 octets) : un morceau enregistré par OS/2-0 est identique à celui de la version DOS.</td></tr>
	<tr><td>Cellule FREE : MemAvail</td><td>Mémoire libre du système en Ko (DosQuerySysInfo).</td></tr>
</table>

<img width="640" height="480" alt="Notator for OS2-Zero : vue Matrice (F3) et menu Fonctions de la barre de menus de PM" src="IMAGE/NOTATOR_MENU.png" />

Le portage a aussi fait apparaître deux pièges d'OS2PC : une variable locale qui porte le nom d'une procédure (<code>Info</code>) donne, avec <code>@</code>, l'adresse de la procédure (MDM.DLL écrivait alors le nom de la carte son par-dessus son code) ; et les fonctions locales qui lisent les variables de la procédure englobante (<code>SlotOf</code> de LoadMidi, <code>Sc</code> de CmdResolution, <code>Fl</code> de LoadOptions) sont sorties au niveau du programme.

Les fichiers <code>.SON</code> et <code>.MID</code> s'ouvrent dans Notator depuis l'Explorateur OS2-Zero et depuis les dossiers du bureau (icône de Notator). Sous VirtualBox, Notator pouvait s'arrêter (SYS3175) pendant la lecture : <b>MDM.DLL</b> alimentait le flux depuis deux fils à la fois, son propre fil et celui du programme qui demande la position (<code>MdmPosition</code>), sans exclusion ; deux remplissages simultanés de l'anneau de la carte pouvaient écrire au-delà de sa fin. Un verrou (<code>XCHG</code> atomique) les sépare maintenant. L'assembleur intégré d'OS2PC ne codait <code>XCHG</code> qu'entre deux registres et omettait sans message <code>XCHG reg,[mem]</code> : il produit maintenant l'instruction (87h /r) dans les deux sens. Notator s'ouvre maintenant sur l'édition de partition ; pendant la lecture dans cette vue, les cases de position (en haut) et la tête de lecture étaient recopiées à l'écran en un seul rectangle, presque tout l'écran à chaque double croche, et le son se hachait : elles sont envoyées séparément, le synthétiseur est aussi alimenté pendant les longs dessins, et il calcule 200 ms d'avance au lieu de 50.

<h3>VirtualBox : Additions d'OS/2-0, réseau TCP/IP et Gestionnaire de périphériques</h3>

OS/2-0 reconnaît maintenant le matériel des machines virtuelles de <b>VirtualBox</b> et en a les pilotes, comme les « Additions invitées » :

<table>
	<tr><th>Élément</th><th>Rôle</th></tr>
	<tr><td><b>VBOXGST.DLL</b> (DLL/VBOXGST.PAS)</td><td>Pilote du « VirtualBox Guest Service » (VMMDev, PCI 80EE:CAFE) : il se présente à l'hôte (ReportGuestInfo, ReportGuestInfo2 avec la version de l'hôte, ReportGuestStatus), annonce qu'il sait changer la taille de l'écran (SetGuestCapabilities : graphisme) et la souris absolue, cache le pointeur de l'hôte au-dessus de la machine (un seul pointeur : celui d'OS/2-0) et lit les demandes de l'hôte (AcknowledgeEvents, GetDisplayChangeRequest2), sans interruption.</td></tr>
	<tr><td>Souris intégrée</td><td>MOUCALLS.DLL lit la position absolue (GetMouseStatus) à chaque paquet de la souris PS/2 que VirtualBox envoie : le pointeur d'OS/2-0 suit exactement celui de l'hôte, sans capture de la souris ni pointeur en double ; si l'hôte ne veut plus de souris absolue (souris capturée), les déplacements relatifs reprennent.</td></tr>
	<tr><td>Taille de l'écran</td><td>VIOCALLS.DLL sait programmer l'adaptateur graphique de VirtualBox (VBoxVGA, VMSVGA) par l'interface VBE DISPI (ports 1CEh/1CFh) à <b>n'importe quelle</b> résolution (mémoire linéaire des modes VESA, taille de la mémoire vidéo vérifiée) ; PMWIN.DLL lit toutes les 300 ms les demandes de l'hôte (fenêtre de la machine redimensionnée, « Ajuster automatiquement la taille de l'écran », menu Écran virtuel → Redimensionner) et passe l'écran à cette taille (WINSETSCREENMODE) ; le bureau (WM_SYSVALUECHANGED) et le LaunchPad se réorganisent. La même interface DISPI existe dans QEMU et Bochs (<code>SET PMRESOLUTION=</code> accepte alors toute taille).</td></tr>
	<tr><td><b>E1000.DLL</b> (DLL/E1000.PAS)</td><td>Intel PRO/1000 : 82540EM (« Intel PRO/1000 MT Desktop », la carte par défaut de VirtualBox ; QEMU <code>e1000</code>), 82543GC, 82545EM, 82544, 82574L : registres en mémoire, anneaux de descripteurs (bus maître), adresse MAC de l'EEPROM.</td></tr>
	<tr><td><b>PCNET.DLL</b> (DLL/PCNET.PAS)</td><td>AMD PCnet-PCI II (Am79C970A) et PCnet-FAST III (Am79C973), les autres cartes de VirtualBox (QEMU <code>pcnet</code>) : mode 32 bits, structures de style 2, bloc d'initialisation, anneaux de descripteurs.</td></tr>
	<tr><td><b>TLS32.DLL</b> (DLL/TLS32.PAS)</td><td>Connexions chiffrées <b>TLS 1.3</b> (TLS_AES_128_GCM_SHA256) et <b>TLS 1.2</b> (ECDHE-RSA et ECDHE-ECDSA-AES128-GCM-SHA256) sur une socket de TCPIP32.DLL, échange de clés <b>X25519</b> ; SHA-256, HMAC, HKDF, PRF, AES-128, GCM et X25519 écrits en Pascal. Points d'entrée <code>TLSOPEN</code>, <code>TLSSEND</code>, <code>TLSRECV</code>, <code>TLSCLOSE</code>, <code>TLSERROR</code>, <code>TLSINFO</code> ; utilisée par le Navigateur Web et WGET pour <code>https://</code>. Les certificats du serveur ne sont pas vérifiés (pas de magasin d'autorités) : la connexion est chiffrée, pas authentifiée.</td></tr>
	<tr><td><b>TCPIP32.DLL</b> (DLL/TCPIP32.PAS)</td><td>Pile TCP/IP : ARP, IPv4, ICMP (réponse aux échos, sockets bruts), UDP, DHCP (au premier usage ; sinon <code>SET IP_ADDRESS=</code>, <code>IP_NETMASK</code>, <code>IP_GATEWAY</code>, <code>IP_DNS</code>), DNS, TCP client (ouverture en trois temps, MSS, accusés de réception et réémission, fenêtre, FIN, RST) ; interface des sockets d'OS/2 : <code>sock_init</code>, <code>socket</code>, <code>bind</code>, <code>connect</code>, <code>send</code>, <code>recv</code>, <code>sendto</code>, <code>recvfrom</code>, <code>soclose</code>, <code>shutdown</code>, <code>sock_errno</code>, <code>gethostbyname</code>, <code>gethostid</code>, <code>inet_addr</code>. Pilote : <code>SET NETDRIVER=E1000</code>, <code>PCNET</code> ou <code>NONE</code>, sinon détection.</td></tr>
	<tr><td>Commandes</td><td><b>IFCONFIG</b> (interface lan0 : carte, MAC, adresse, masque, passerelle, DNS, DHCP et bail ; <code>/RENEW</code>), <b>PING</b> hôte [nombre], <b>HOST</b> nom (DNS), <b>WGET</b> http[s]://hôte[:port]/chemin [fichier] (HTTP/1.0 ; https:// par TLS32.DLL), <b>NET USE</b> (lecteurs réseau Windows et Samba par SMB.IFS, voir <i>Lecteurs réseau</i>), <b>IPCONFIG</b> [/ALL] [/RENEW] et <b>CURL</b> [options] url, portées de Pasdows 95 (voir ci-dessous).</td></tr>
	<tr><td><b>Gestionnaire de périphériques</b> (DEVMGR.PAS)</td><td>Système OS/2 → Configuration du système : le matériel par catégorie (affichage, réseau, multimédia, stockage, entrée, ports, système, ponts, USB) lu sur le bus PCI, dans la zone du BIOS et auprès du noyau, avec ses ressources, son pilote d'OS/2-0 et son état (en rouge : aucun pilote). Sous VirtualBox : VirtualBox Guest Service (VBOXGST.DLL), adaptateur graphique VirtualBox (DISPI), souris VirtualBox intégrée, carte réseau (E1000.DLL ou PCNET.DLL, avec son adresse MAC).</td></tr>
</table>

<b>IPCONFIG</b> et <b>CURL</b> sont les commandes de <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a>, portées des API Win32 vers celles d'OS/2. IPCONFIG lisait IPHLPAPI.DLL (GetAdaptersInfo, GetNetworkParams) ; il lit maintenant la pile elle-même (TCPIP32.DLL, point d'entrée TCPIPINFO, qui donne aussi le serveur DHCP). CURL passait par WININET.DLL ; il parle maintenant HTTP/1.1 sur les sockets de TCPIP32.DLL et chiffre les adresses https:// par TLS32.DLL (TLS 1.3 et 1.2, certificat non vérifié). Il décode les corps « chunked », suit les redirections (-L, au plus 10) et passe par un proxy : requête absolue en http://, tunnel CONNECT en https://. Il rend les codes de sortie de curl : 6 hôte inconnu, 7 connexion, 22 erreur HTTP avec -f, 35 TLS, 47 trop de redirections. IPCONFIG suit la variable LANGUAGE (EN : anglais).

<pre>
[C:\]IPCONFIG /ALL
   Description. . . . . . . . . . . . : Intel PRO/1000 MT Desktop (82540EM) (E1000.DLL)
   Adresse physique . . . . . . . . . : 52-54-00-12-34-56
   DHCP activé. . . . . . . . . . . . : Oui
   Adresse IP . . . . . . . . . . . . : 10.0.2.15
   Serveur DHCP . . . . . . . . . . . : 10.0.2.2
[C:\]CURL -o D:\LIC.TXT https://raw.githubusercontent.com/gladir/OS2-0/main/LICENSE
1072 octets recus dans D:\LIC.TXT (HTTP 200)
</pre>

<img width="640" height="480" alt="OS/2-0 : le Gestionnaire de périphériques" src="IMAGE/PERIPHERIQUES.png" />

Réglages conseillés de la machine virtuelle : type « OS/2 Warp 3 » (ou « Autre »), contrôleur graphique VBoxVGA ou VMSVGA, carte réseau Intel PRO/1000 MT Desktop ou PCnet-FAST III en NAT, souris PS/2. Les Additions ne demandent aucune installation : VBOXGST.DLL est chargé dès qu'il trouve le VMMDev.

<img width="804" height="671" alt="OS/2-0 dans VirtualBox 7 sous Windows : le bureau et le dossier Système OS/2" src="IMAGE/VIRTUALBOX.png" />

<i>OS/2-0 dans <b>VirtualBox 7.0</b> sous Windows (VirtualBox au-dessus de Hyper-V) : le bureau, le dossier Système OS/2 et le LaunchPad.</i>

<b>Installation depuis VirtualBox.</b> Le CD-ROM d'installation s'arrêtait dès le démarrage du noyau : « OS/2-0 OS2LDR...... » restait affiché et plus rien ne se passait. Trois causes ont été trouvées et corrigées :

<table>
	<tr><th>Réglage de VirtualBox</th><th>Problème</th><th>Correction</th></tr>
	<tr><td>Tous (la panne principale), surtout quand VirtualBox tourne au-dessus de Hyper-V (mode « NEM », journal : <code>HM: ... fall back to NEM</code>)</td><td>OS2LDR copie le noyau en mémoire étendue par INT 15h AH=87h ; le BIOS de VirtualBox laisse la <b>ligne A20 coupée</b> à la sortie de ces copies. Le noyau démarrait donc avec A20 coupée : sous Hyper-V, VirtualBox retire alors de la machine la zone 1 Mo – 1 Mo + 64 Ko et exécute ce qui s'y trouve (les gestionnaires d'interruptions et la console du noyau) en repliant les adresses sur la mémoire basse. Journal : <code>A20 disabled (changed 221 times)</code>, des millions d'instructions émulées (<code>/IEM/CPU0/cPotentialExits</code>), processeur arrêté dans le noyau avec une pile perdue.</td><td>OS2LDR réactive la ligne A20 après le chargement, juste avant le passage en mode protégé, et vérifie qu'elle l'est (0000:0500 et FFFF:0510 ne doivent pas désigner la même case) ; sinon il passe par le contrôleur du clavier (commande D1h). La régression reproduit la panne (OS2LDR d'essai qui coupe A20 : QEMU replie alors toute la mémoire) et vérifie que le bureau s'affiche.</td></tr>
	<tr><td>Plus de 2 Go de mémoire (les types Windows proposent 2 à 4 Go)</td><td>Le noyau calcule les adresses en entiers signés de 32 bits : la taille de la mémoire devenait négative, et l'appel au BIOS vidéo qui suit partait dans le vide (écran figé après « Mémoire : … Ko »).</td><td>La mémoire gérée est plafonnée à 1792 Mo (OS/2-0 n'en demande pas plus) ; la vraie taille reste affichée.</td></tr>
	<tr><td>Disque et CD-ROM sur un contrôleur <b>SATA</b> (AHCI), le choix par défaut de nombreux types, et le seul du chipset ICH9</td><td>Le noyau ne connaissait que l'IDE : « lecteur de CD-ROM ATAPI introuvable », puis aucun disque où installer.</td><td>Nouveau pilote AHCI dans le noyau : contrôleur cherché sur le bus PCI (classe 01h, sous-classe 06h), ports SATA, lecteur ATAPI (PACKET, READ(10)) et disques ATA (IDENTIFY, lecture et écriture DMA 48 bits, vidage du cache). Installation, démarrage du disque dur SATA et fichiers sur C: fonctionnent comme en IDE.</td></tr>
</table>

Ces cas sont reproduits dans la régression avec QEMU (<code>-m 3584</code> ; <code>-M q35</code>, dont le disque et le lecteur de CD-ROM sont en SATA) ; le CD d'installation démarre aussi sous Bochs, dont le BIOS est l'ancêtre de celui de VirtualBox. Il faut enfin laisser <b>EFI désactivé</b> (Système → Carte mère) : le CD-ROM d'OS/2-0 démarre par le BIOS (El Torito), comme celui d'OS/2 Warp 3.

<pre>qemu-system-i386 -m 3584 -cdrom IMAGE/OS2INST.ISO -boot d -drive file=disque.img,format=raw,if=ide
qemu-system-i386 -M q35 -m 512 -cdrom IMAGE/OS2INST.ISO -boot d -drive file=disque.img,format=raw,if=ide</pre>

<pre>qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d -nic user,model=e1000
qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d -nic user,model=pcnet</pre>

<h3>VMware Workstation : VMware Tools d'OS/2-0</h3>

Sous <b>VMware Workstation</b> (et VMware Player, Fusion, ESXi), OS/2-0 a aussi ses pilotes, comme les « VMware Tools » :

<table>
	<tr><th>Élément</th><th>Rôle</th></tr>
	<tr><td><b>VMWTOOLS.DLL</b> (DLL/VMWTOOLS.PAS)</td><td>VMware Tools d'OS/2-0 : porte dérobée de VMware (port 5658h, nombre magique 564D5868h ; GETVERSION), souris <b>vmmouse</b> (ABSPOINTER : READ_ID, REQUEST_ABSOLUTE, file des paquets) et canal <b>GuestRPC</b> (RPCI pour parler à l'hôte, TCLO pour en recevoir les ordres) : version des Tools (<code>tools.set.version</code>), capacités (<code>tools.capability.resolution_set</code>, <code>resolution_server toolbox</code>, <code>resolution_min</code>), réponses à <code>reset</code>, <code>ping</code>, <code>Capabilities_Register</code>, <code>Set_Option</code> et <b><code>Resolution_Set</code></b> (taille de l'écran voulue par l'hôte). Chargé par MOUCALLS.DLL et PMWIN.DLL seulement si la porte dérobée répond <b>et</b> que la carte VMware SVGA II est sur le bus PCI (QEMU répond aussi à la porte dérobée).</td></tr>
	<tr><td>Souris</td><td>MOUCALLS.DLL lit la position absolue de la vmmouse (0..65535) et ses boutons à chaque paquet PS/2 : le pointeur d'OS/2-0 suit exactement celui de l'hôte, qui le masque au-dessus de la machine — un seul pointeur, sans capture (Ctrl+Alt) ni pointeur en double.</td></tr>
	<tr><td>Carte graphique <b>VMware SVGA II</b></td><td>VIOCALLS.DLL programme la carte (PCI 15AD:0405) par ses registres (ports BAR0 : index et valeur ; identification SVGA_ID_2) : n'importe quelle résolution jusqu'au maximum de la carte, en 32 bits par pel, mémoire linéaire (FB_START + FB_OFFSET, BYTES_PER_LINE), file de commandes (FIFO : MIN, MAX, NEXT_CMD, STOP) ; PMWIN.DLL envoie au plus toutes les 30 ms la commande UPDATE pour que l'hôte recopie l'écran, et un curseur matériel transparent (DEFINE_CURSOR) est défini si la carte en a. Sous VMware, le bureau passe en 32 bits dès le démarrage, puis prend la taille que VMware Workstation demande (fenêtre redimensionnée, « Ajuster l'invité maintenant », plein écran, menu Affichage → Taille automatique) : le bureau et le LaunchPad se réorganisent.</td></tr>
	<tr><td>Carte réseau</td><td>Les cartes de VMware Workstation : <b>vlance</b> (AMD PCnet-PCI II : PCNET.DLL), <b>e1000</b> (Intel 82545EM : E1000.DLL) et <b>e1000e</b> (Intel 82574L : E1000.DLL), avec la pile TCP/IP (DHCP du NAT de VMware). La carte paravirtuelle VMXNET3 n'a pas de pilote : choisir e1000 ou vlance (<code>ethernet0.virtualDev = "e1000"</code> dans le fichier .vmx).</td></tr>
	<tr><td>Gestionnaire de périphériques</td><td>Sous VMware : « VMware Tools d'OS/2-0 » (VMWTOOLS.DLL : version de la machine virtuelle, souris absolue, canal des Tools et nombre d'ordres reçus de l'hôte), « Souris VMware (PS/2 + vmmouse absolue) », « Adaptateur graphique VMware SVGA II » (pilote SVGA II de VIOCALLS.DLL), carte réseau VMware (vlance ou e1000), et le reste du matériel de VMware (VMCI, ponts PCI Express, USB, SATA, VMXNET3).</td></tr>
</table>

<img width="800" height="600" alt="OS/2-0 sous VMware : le Gestionnaire de périphériques" src="IMAGE/VMWARE.png" />

Réglages conseillés de la machine virtuelle : système invité « OS/2 » (ou « Autre »), carte réseau e1000 ou vlance (NAT), mémoire 64 Mo ou plus. Rien à installer : VMWTOOLS.DLL est chargé dès qu'il trouve VMware. Dans QEMU, <code>-vga vmware</code> donne la même carte SVGA II et la même souris vmmouse (QEMU n'a pas le canal GuestRPC : pas de Resolution_Set) :

<pre>qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d -vga vmware -nic user,model=pcnet</pre>

<h3>Sessions DOS : machine virtuelle 8086 (Turbo Pascal, DPMI, EMS, XMS)</h3>

Comme OS/2 2.0, OS/2-0 exécute les programmes <b>MS-DOS</b> (fichiers <b>.COM</b>, et <b>.EXE</b> sans en-tête PE ni NE) dans une <b>machine virtuelle DOS</b> en <b>mode virtuel 8086</b>. Le moniteur, le BIOS, le DOS, la souris, XMS, EMS et le serveur DPMI viennent de la machine virtuelle de <a href="https://github.com/gladir/Pasdows95">Pasdows 95</a> (KERNEL/VMM32.PAS, partie 17), adaptés au noyau d'OS/2-0 (partie 13b de KERNEL/OS2KRNL.PAS). On lance un programme DOS depuis l'invite de commandes OS/2 (CMD.EXE l'attend, comme un programme OS/2), depuis un dossier du bureau, ou on ouvre <b>Fenêtre DOS</b> ou <b>DOS plein écran</b> (dossier Système OS/2) : l'interpréteur de commandes intégré de la machine (COMMAND.COM : DIR, CD, COPY, DEL, MD, RD, REN, TYPE, SET, VER, EXIT, programmes...).

<table>
	<tr><th>Élément</th><th>Rôle</th></tr>
	<tr><td>Mode virtuel 8086</td><td>Une tâche du noyau exécute le code 16 bits (EFLAGS.VM, IOPL 0). Le processeur a maintenant une <b>TSS</b> (pile de l'anneau 0 de chaque tâche, ESP0 changé avec la tâche) et une <b>LDT</b> (sélecteurs des clients DPMI) ; les procédures <i>Interrupt</i> du noyau rechargent DS et ES (compilateur OS2PC), car une interruption peut survenir en mode V86 ou en anneau 3. L'horloge partage le temps entre la machine et les autres tâches.</td></tr>
	<tr><td>Mémoire</td><td>Le premier mégaoctet de la machine est projeté par la <b>table de pages de sa session</b> (entrée 0 du répertoire de pages, qui suit la session) : 0 à 9FFFFh, B0000h à B7FFFh et C0000h à FFFFFh sont 1 Mo de mémoire physique de la machine ; A0000h à AFFFFh et B8000h à BFFFFh sont l'écran de la session (la carte au premier plan, le tampon de la session sinon). Les tâches du noyau gardent les pages d'identité (CtxSwitch change l'entrée 0 après le changement de pile).</td></tr>
	<tr><td>Moniteur</td><td>INT, IRET, PUSHF, POPF, CLI, STI, HLT, IN, OUT provoquent une faute de protection générale émulée ; IF virtuel ; horloge (INT 08h, 1Ch, minuterie reprogrammable), clavier (INT 09h, port 60h : les codes de balayage de la session au premier plan) et souris PS/2 sont des interruptions virtuelles.</td></tr>
	<tr><td>BIOS et DOS 5.00</td><td>BIOS écrit en Pascal (INT 10h, 11h, 12h, 13h, 15h, 16h, 1Ah, zone de données), DOS (INT 21h : mémoire MCB, PSP, chargement des .COM et .EXE, EXEC, fichiers du noyau sur toutes les unités, recherche, répertoire courant par unité, pays...), INT 2Fh, souris INT 33h (pointeur en mode texte).</td></tr>
	<tr><td><b>Fenêtre DOS</b></td><td>Comme sous OS/2, la session DOS s'exécute dans une <b>fenêtre de Presentation Manager</b>, à côté des programmes OS/2 : PMVIOP.DLL (bouclier VIO) relit l'écran de la session et y dessine les lignes changées et le curseur ; les touches de la fenêtre vont au clavier de la machine (le code « traduit » de PM, Ctrl+F9 = 66h par exemple, redevient le code matériel de la touche, avec Maj, Ctrl et Alt du message WM_CHAR) et la souris va au pilote INT 33h de la machine (position en cellules, boutons ; KrnSesCtl 21). Un programme qui passe en <b>mode graphique</b> fait passer la session en plein écran ; elle revient dans sa fenêtre quand il retourne au mode texte. Les raccourcis du système (Alt+F4, Alt+F5, Alt+F9, Alt+F10, F10) restent à PM, comme sous OS/2 : on utilise alors les menus du programme.</td></tr>
	<tr><td>Écran plein écran</td><td>Au premier plan, la session utilise directement la carte VGA : mode texte dans B8000h, <b>modes graphiques par le vrai BIOS</b> (appel en mode réel, BDA vidéo et tampons recopiés) et ports de la carte (3B0h à 3DFh) ; le haut-parleur (port 61h, canal 2 de la minuterie) aussi. À l'arrière-plan (Ctrl+Échap, Alt+Échap), un programme en mode texte continue dans le tampon de la session ; un programme en mode graphique est suspendu, ses plans, son mode et sa palette sont sauvés et rendus à son retour.</td></tr>
	<tr><td>XMS 3.0, EMS 4.0, DPMI 0.9</td><td>Mémoire étendue XMS (INT 2Fh 4300h/4310h, blocs pris dans la mémoire physique), mémoire paginée EMS (INT 67h, cadre en E000h projeté par la table de pages de la session), serveur <b>DPMI</b> (INT 2Fh 1687h, client 16 ou 32 bits en anneau 3, services de l'INT 31h, extensions MS-DOS) : les programmes de Borland Pascal en mode protégé (RTM.EXE, DPMI16BI.OVL) comme <b>TPX.EXE</b> fonctionnent.</td></tr>
	<tr><td>Disquette A:</td><td>Lecteur A: (contrôleur 765, DMA, IRQ 6) en <b>FAT12</b> (et FAT16), en lecture, vu par toutes les API de fichiers du noyau (CMD et sessions DOS) ; un changement de disquette est détecté (DSKCHG).</td></tr>
	<tr><td><b>TESTVDM.EXE</b> (DLL/TESTVDM.PAS)</td><td>Programme MS-DOS 16 bits compilé par <b>OS2PC -CD</b> : 36 vérifications (version, fichiers, recherche, mémoire, BIOS, souris, XMS, EMS, DPMI).</td></tr>
</table>

<b>Turbo Pascal 7</b> s'installe depuis ses quatre disquettes : <i>qemu-system-i386 ... -fda Disk01.img</i>, puis <b>A:</b> et <b>INSTALL</b> dans une fenêtre DOS ou l'invite de commandes ; on change de disquette dans le moniteur de QEMU (<i>change floppy0 Disk02.img</i>) quand l'installateur la demande. L'EDI (<b>TURBO</b>) fonctionne entièrement, dans sa fenêtre du bureau comme en plein écran : édition, menus au clavier et à la souris, compilation et exécution (Ctrl+F9), écran utilisateur (Alt+F5 en plein écran, menu Debug - User screen dans une fenêtre) ; le compilateur <b>TPC</b>, les programmes graphiques comme <b>BGIDEMO</b> (VGA 640 x 480, pilote EGAVGA.BGI) et l'EDI en mode protégé <b>TPX</b> (DPMI, plus de 34 Mo de mémoire protégée libre).

<table>
	<tr>
		<td align="center"><img src="IMAGE/DOS_TURBO.png" width="400" alt="EDI de Turbo Pascal 7 dans une fenêtre DOS"><br><i>L'EDI de Turbo Pascal 7 dans une fenêtre DOS du bureau</i></td>
		<td align="center"><img src="IMAGE/DOS_SORTIE.png" width="400" alt="Programme compilé et exécuté"><br><i>Le programme compilé et exécuté (Ctrl+F9) : écran utilisateur</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/DOS_SOURIS.png" width="400" alt="Souris dans la fenêtre DOS"><br><i>Menu Edit ouvert à la souris, dans la fenêtre</i></td>
		<td align="center"><img src="IMAGE/DOS_TPX.png" width="400" alt="TPX.EXE dans une fenêtre DOS"><br><i>TPX.EXE (DPMI) dans une fenêtre : 34 Mo de mémoire protégée libre</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/DOS_INSTALL.png" width="400" alt="Installation de Turbo Pascal 7"><br><i>INSTALL.EXE depuis la disquette A:, dans une fenêtre</i></td>
		<td align="center"><img src="IMAGE/DOS_BGIDEMO.png" width="400" alt="BGIDEMO"><br><i>BGIDEMO (VGA 640x480 16 couleurs) : le mode graphique passe en plein écran</i></td>
	</tr>
</table>

Limites : une seule session DOS à la fois ; les modes graphiques s'affichent en plein écran seulement (pas dans une fenêtre) ; la disquette est en lecture seule ; pas de carte son émulée pour la machine (le haut-parleur seulement) ; pas de modes VESA pour les programmes DOS ; la zone haute (HMA) n'est pas disponible ; seuls des clients DPMI 16 bits (Borland Pascal) ont été essayés.

<h3>Programmes d'OS/2 2.x (LX) et d'OS/2 1.x (NE 16 bits)</h3>

Pour exécuter les vrais programmes d'OS/2 (pas seulement ceux compilés par OS2PC), le noyau charge aussi les deux formats d'exécutables d'IBM :

<table>
	<tr><th>Format</th><th>Chargement</th></tr>
	<tr><td><b>LX</b> (OS/2 2.x, 32 bits ; partie 13c du noyau)</td><td>Objets et pages (normales, itérées EXEPACK 1 et EXEPACK 2), corrections internes et importations (par ordinal ou par nom), table des points d'entrée, ressources ; programme dans la fenêtre du processus (00400000h), DLL dans la région des DLL (_DLL_InitTerm appelée). Le HMODULE est un en-tête PE synthétique (exportations et ressources), si bien que DosQueryProcAddr, DosGetResource et WinLoadString fonctionnent tels quels ; TIB et PIB par FS, convention _System. Une importation inconnue reçoit une souche qui l'écrit dans le journal du noyau.</td></tr>
	<tr><td><b>NE</b> (OS/2 1.x, 16 bits ; partie 13d du noyau et <b>DLL/API16.PAS</b>)</td><td>Comme OS/2 2.x, OS/2-0 exécute les programmes 16 bits d'OS/2 1.x : segments (normaux et itérés) dans la fenêtre du processus, un sélecteur de la LDT (16 bits, anneau 3) par segment, corrections internes et importations (DOSHUGEINCR et DOSHUGESHIFT sont des constantes). Le programme s'exécute à l'<b>anneau 3</b> (pile de l'anneau 0 par fil dans la TSS) ; chaque fonction du système qu'il importe reçoit une souche 16 bits (<code>mov ax,n ; call far porte:0 ; retf taille</code>) et une <b>porte d'appel</b> de la LDT mène au noyau, qui appelle la fonction de <b>API16.DLL</b> : arguments lus sur la pile 16 bits (convention Pascal), pointeurs 16:16 convertis (KrnTaskCtl 30), structures de 16 bits traduites (FILESTATUS, FILEFINDBUF...), puis appel des fonctions 32 bits de DOSCALLS, VIOCALLS, KBDCALLS, NLS et MSG. DosAllocSeg, DosReallocSeg, DosFreeSeg, DosCreateThread (fils 16 bits, DS et ES du créateur) et DosExit sont faits par le noyau ; sémaphores en mémoire (DosSemSet, DosSemClear, DosSemWait), fichiers (DosOpen2, DosRead, DosWrite, DosChgFilePtr, DosFindFirst2, DosQPathInfo, DosSetFileInfo...), messages liés au programme (DosGetMessage avec segment de messages), écran et clavier VIO. Environ 50 fonctions sont fournies ; une fonction absente est signalée dans le journal du noyau.</td></tr>
</table>

<h3>IBM Works sous OS/2-0</h3>

<b>IBM Works</b> (Footprint Works, disquettes WORKS01 à WORKS05), la suite bureautique livrée avec OS/2 Warp 3, sert d'essai grandeur nature pour les vrais programmes d'OS/2. Ses archives <code>.@</code> se décompressent sous OS/2-0 avec son propre décompresseur <b>FPWTUPCK.EXE</b> — un programme <b>16 bits</b> d'OS/2 1.x avec trois fils et des sémaphores — puis son gestionnaire d'informations personnelles <b>FPWPIM.EXE</b> (LX, Presentation Manager, avec ses DLL FEN20PDE, FPWPIMR...) s'exécute sur le bureau d'OS/2-0, dans ses cinq modes : carnet de rendez-vous (<code>-M</code>), bottin (<code>-P</code>), bloc-notes (<code>-N</code>), agenda (<code>-G</code>) et liste des tâches (<code>-T</code>).

<table>
	<tr>
		<td align="center"><img src="IMAGE/IBMWORKS_RDV.png" width="400" alt="IBM Works : carnet de rendez-vous"><br><i>FPWPIM -M : carnet de rendez-vous de la semaine</i></td>
		<td align="center"><img src="IMAGE/IBMWORKS_AGENDA.png" width="400" alt="IBM Works : agenda"><br><i>FPWPIM -G : agenda du mois (alarmes, tâches, lancements)</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/IBMWORKS_TACHES.png" width="400" alt="IBM Works : liste des tâches"><br><i>FPWPIM -T : liste des tâches</i></td>
		<td align="center"><img src="IMAGE/IBMWORKS_BOTTIN.png" width="400" alt="IBM Works : bottin"><br><i>FPWPIM -P : bottin (carnet d'adresses)</i></td>
	</tr>
</table>

Pour y arriver, OS/2-0 a reçu : les programmes NE 16 bits (ci-dessus) et <b>API16.DLL</b> (dont DosGetMessage avec les segments de messages MSGBIND), les tables d'aide à 8 octets de <b>HELPMGR.DLL</b>, les tables de couleurs logiques (GpiCreateLogColorTable) dans PMWIN, <b>PMWP.DLL</b> (objets du Workplace Shell : WinCreateObject, WinSetObjectData, WinQueryObject, WinOpenObject, WinLoadFileIcon..., objets conservés dans OS2.INI), <b>PMCTLS.DLL</b> (dialogues standard WinFileDlg et WinFontDlg), SplQueryQueue et SplEnumQueue dans PMSPL, <code>LIBPATH=.;C:\;</code> dans CONFIG.SYS, les fichiers de commandes de CMD.EXE et la copie avec * et ?. L'installation (<b>INSTALL.EXE</b>) démarre depuis la disquette A:, décompresse ses fichiers et lance <b>FPWIDLDS.EXE</b>, qui demande encore les objets <b>16:16</b> des programmes LX (DosFlatToSel, DosSelToFlat) ; le traitement de texte et le tableur d'IBM Works (FPWWP, FPWSS) demandent en plus les classes SOM du Workplace Shell. Le travail continue ; chaque étape franchie est vérifiée par la régression.

<h3>Virtualisation (APPS/VIRTUAL.PAS) : machines de VirtualBox par AMD-V, Intel VT-x ou mode V86</h3>

Le dossier <b>Système OS/2</b> contient <b>Virtualisation</b> (VIRTUAL.EXE, icône de deux écrans : la machine invitée dans l'hôte), un gestionnaire de machines virtuelles à la façon de <b>VirtualBox</b>, avec la barre de menus, les boutons et l'apparence d'OS/2 Warp 3, écrit en un seul fichier source compilé par OS2PC. Il exécute les machines au <b>format de VirtualBox</b> : le fichier de machine <b>.vbox</b> (XML de VirtualBox 1.16 : nom, type de système, mémoire vive, ordre d'amorçage, contrôleur IDE et disquette, registre des supports), les disques <b>VHD</b> fixes ou dynamiques (allocation des blocs de 2 Mo à l'écriture, pied de page et table des blocs tenus à jour, image tronquée lue par la copie du pied de page), <b>VDI</b> fixes ou dynamiques, <b>VMDK</b> plats et images brutes (.IMG), et les disquettes de 360 Ko à 2,88 Mo.

<table>
	<tr>
		<td align="center"><img src="IMAGE/VIRTUALISATION.png" width="400" alt="Virtualisation : gestionnaire des machines"><br><i>Le gestionnaire : liste des machines, détails par sections (Général, Système, Stockage, Fichier) et boutons, comme VirtualBox</i></td>
		<td align="center"><img src="IMAGE/VIRTUALISATION_DOS.png" width="400" alt="Virtualisation : MS-DOS 6.22"><br><i>Le VHD de MS-DOS 6.22 de VirtualBox démarré dans une fenêtre d'OS/2 : VER et DIR (ici en mode virtuel 8086 sous QEMU, F5 au démarrage)</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/VIRTUALISATION_INFO.png" width="400" alt="Information de virtualisation"><br><i>Machine &gt; Information de virtualisation : méthode, processeur, structures et compteurs des sorties de l'invité</i></td>
		<td align="center"><img src="IMAGE/VIRTUALISATION_CONFIG.png" width="400" alt="Configuration d'une machine"><br><i>Configuration d'une machine : nom, type, mémoire, disques (création d'un VHD dynamique), disquette, CD-ROM, ordre d'amorçage (ici MSDOS-0 choisi : nom, disque neuf et amorçage par le CD-ROM remplis)</i></td>
	</tr>
</table>

<h4>Supports amovibles : menu Périphériques et barre d'état</h4>

Comme dans VirtualBox, la fenêtre de la machine a un menu <b>Périphériques</b> (Alt+P) et sa barre d'état montre à droite trois icônes : le disque dur (témoin vert après une lecture ou une écriture), le <b>CD-ROM</b> (disque argenté, ou contour gris s'il est vide) et la <b>disquette</b>. Un clic (bouton 1 ou 2) sur la partie « disque » de la barre d'état ou sur ces icônes ouvre le menu des supports : le CD-ROM inséré, <b>Choisir une image de CD-ROM...</b>, <b>Éjecter le CD-ROM</b>, la disquette, <b>Choisir une image de disquette...</b>, <b>Éjecter la disquette</b> et <b>Informations sur les disques...</b> (pour chaque unité : fichier, format, taille, géométrie CHS, lectures et écritures, lecture seule ; pour le CD-ROM : secteurs de 2048 octets, amorce El Torito et émulation active). La boîte de choix liste les images trouvées (.ISO ; .IMG, .IMA, .VFD) dans le dossier des machines et à la racine de C: et D:, avec un champ pour un autre fichier. Le changement est fait par la tâche de la machine entre deux sorties de l'invité, noté dans le .vbox ; le lecteur de CD-ROM ATAPI reste présent sans disque (NOT READY, MEDIUM NOT PRESENT) et signale le changement (UNIT ATTENTION), la disquette le signale par INT 13h AH=16h.

<table>
	<tr>
		<td align="center"><img src="IMAGE/VIRTUALISATION_SUPPORTS.png" width="400" alt="Menu des supports"><br><i>Clic sur la partie disque de la barre d'état : menu des supports (CD-ROM inséré, disquette vide)</i></td>
		<td align="center"><img src="IMAGE/VIRTUALISATION_CHOIX_CD.png" width="400" alt="Choisir une image de CD-ROM"><br><i>Choisir une image de CD-ROM : images trouvées et fichier</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/VIRTUALISATION_DISQUES.png" width="400" alt="Informations sur les disques"><br><i>Informations sur les disques de la machine en fonction</i></td>
		<td></td>
	</tr>
</table>

<h4>Installer un système à partir de GitHub</h4>

Dans <b>Nouvelle machine virtuelle</b>, le champ <b>Type (OSType)</b> est une liste déroulante :

<table>
	<tr><th>Type</th><th>Image d'installation</th><th>Machine proposée</th></tr>
	<tr><td><b>MSDOS-0</b> (télécharger à partir de GitHub)</td><td><code>gladir/MSDOS-0</code>, <code>IMAGE/INSTALLCD.ISO</code> (5 Mo, El Torito : disquette de 2,88 Mo émulée)</td><td>32 Mo, VHD de 64 Mo, OSType DOS</td></tr>
	<tr><td><b>UNIX-0</b> (télécharger à partir de GitHub)</td><td><code>gladir/UNIX-0</code>, <code>IMAGES/UNIX0-CD.ISO</code> (8 Mo, El Torito : disque dur émulé)</td><td>16 Mo, VHD de 64 Mo, OSType Other</td></tr>
	<tr><td><b>OS2-Zero</b> (télécharger à partir de GitHub)</td><td><code>gladir/OS2-0</code>, <code>IMAGE/OS2INST.ISO</code> (46 Mo, El Torito sans émulation)</td><td>64 Mo, VHD de 512 Mo, OSType OS2Warp3</td></tr>
	<tr><td><b>Pasdows95</b> (télécharger à partir de GitHub)</td><td><code>gladir/Pasdows95</code>, <code>IMAGE/INSTALL.ISO</code> (22 Mo, El Torito sans émulation)</td><td>64 Mo, VHD de 512 Mo, OSType Windows95</td></tr>
	<tr><td><b>DOS</b>, <b>Windows</b>, <b>Linux</b>, <b>Autre</b> (fourni par vous localement)</td><td>disques et image de CD-ROM choisis par vous (champs Disque dur 0 et 1, Disquette, CD-ROM)</td><td>OSType DOS, Windows95, Linux ou Other</td></tr>
</table>

Choisir un système de GitHub remplit le nom, la mémoire, la case <b>Nouveau disque dynamique (VHD)</b> et sa taille, et coche <b>Amorcer d'abord le CD-ROM</b>. Avec OK, le VHD neuf est créé dans le dossier de la machine (C:\VMS\nom), puis l'image ISO est <b>téléchargée</b> de <code>https://raw.githubusercontent.com/gladir/<i>dépôt</i>/main/<i>chemin</i></code> dans ce même dossier : fenêtre de progression (Mo reçus sur la taille annoncée, pourcentage, vitesse, bouton Annuler), en https:// par TLS32.DLL et TCPIP32.DLL dans un fil d'exécution à part (le gestionnaire reste actif), avec le proxy de <code>SET HTTP_PROXY=hôte:port</code> (tunnel CONNECT), les redirections et les réponses « chunked » ; le fichier est écrit en .TMP puis renommé, et l'espace libre est vérifié avant. Quand l'image est complète, la machine est enregistrée (.vbox avec le lecteur DVD sur le port IDE secondaire et l'ordre d'amorçage DVD, disque dur, disquette ; un attribut <code>distribution</code> que VirtualBox ignore garde le nom du système) et <b>démarre aussitôt sur le CD-ROM</b> : l'installateur du système s'ouvre dans la fenêtre de la machine. Une image déjà présente dans le dossier n'est pas retéléchargée ; en cas d'échec ou d'annulation, le message donne la cause (hôte introuvable, proxy, TLS, erreur HTTP, disque plein, coupure) et le VHD neuf est effacé.

<table>
	<tr>
		<td align="center"><img src="IMAGE/VIRTUALISATION_NOUVELLE.png" width="400" alt="Nouvelle machine : type"><br><i>Nouvelle machine virtuelle : la liste des types, systèmes de GitHub et systèmes fournis localement</i></td>
		<td align="center"><img src="IMAGE/VIRTUALISATION_TELECHARGEMENT.png" width="400" alt="Téléchargement de l'image"><br><i>Téléchargement de l'image d'installation de MSDOS-0 à partir de GitHub</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/VIRTUALISATION_MSDOS0.png" width="400" alt="Installation de MSDOS-0"><br><i>La machine démarre sur le CD-ROM téléchargé : installation de MSDOS-0 (mode virtuel 8086)</i></td>
		<td align="center"><img src="IMAGE/VIRTUALISATION_PASDOWS.png" width="400" alt="Installation de Pasdows 95"><br><i>L'installateur de Pasdows 95 en VGA 640 × 480 en 16 couleurs (modes planaires émulés) dans la fenêtre de la machine</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/VIRTUALISATION_PASDOWS_FIN.png" width="400" alt="Installation de Pasdows 95 terminée"><br><i>Écran de l'invité : installation de Pasdows 95 terminée sur le VHD (mode virtuel 8086)</i></td>
		<td align="center"><img src="IMAGE/VIRTUALISATION_PASDOWS_BUREAU.png" width="400" alt="Bureau de Pasdows 95"><br><i>La machine démarre du VHD installé : bureau de Pasdows 95 dans Virtualisation</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/VIRTUALISATION_OS2ZERO_BOCHS.png" width="400" alt="OS2-Zero dans la machine"><br><i>Sous Bochs avec AMD-V : l'installation d'OS2-Zero commence à se dessiner dans la machine (Presentation Manager en VGA planaire émulé, chaque accès passant par une sortie NPF ; les textes n'étaient pas encore dessinés à la fin de l'essai, Bochs étant très lent)</i></td>
		<td></td>
	</tr>
</table>

Ce qui a été vérifié sous QEMU (mode virtuel 8086) : les quatre images téléchargées de GitHub par le proxy du conteneur (tailles et CRC32 identiques à ceux des dépôts) ; <b>MSDOS-0</b> s'installe entièrement sur un VHD neuf (partition, formatage, copie des fichiers) puis la machine démarre de ce disque dur jusqu'à <code>C:\&gt;</code> ; <b>UNIX-0</b> démarre de son CD-ROM (connexion <code>install</code>), s'installe sur un VHD neuf (UFS1 et zone de va-et-vient, 165 fichiers) puis démarre de ce disque dur jusqu'à <code>login:</code> ; l'installateur graphique de <b>Pasdows 95</b> (VGA planaire émulé : plus de deux millions d'instructions émulées) va jusqu'au bout (partition, formatage, copie des fichiers) puis la machine démarre de son VHD jusqu'au bureau de Pasdows 95 (interface VGA 16 couleurs d'IO.SYS, le noyau VMM32 en mode protégé demandant AMD-V ou VT-x). <b>OS2-Zero</b> passe en mode protégé dès son chargeur : sous Bochs avec AMD-V (SVM et NPT), son noyau démarre dans la machine, lit le CD-ROM par l'<b>ATAPI émulé</b> (INS/OUTS en adresses 32 bits) et charge DOSCALLS, HPFS.IFS, NTFS.IFS et Presentation Manager, dont la fenêtre d'installation commence à se dessiner en VGA planaire émulé (mode protégé 32 bits, sorties NPF) ; en mode V86, Virtualisation dit que le système exige AMD-V ou VT-x au lieu de s'arrêter sur une sortie inconnue.

L'invité s'exécute <b>directement sur le processeur</b> : c'est de la <b>virtualisation</b> et non de l'émulation (comme l'émulateur DOS de DEVENV.PAS) ; les instructions de l'invité ne sont pas interprétées, seules les entrées et sorties et quelques instructions privilégiées reviennent à l'application. Le noyau choisit, dans cet ordre :

<table>
	<tr><th>Méthode</th><th>Matériel</th><th>Fonctionnement</th></tr>
	<tr><td><b>AMD-V (SVM)</b></td><td>Athlon 64, Phenom, Opteron, Ryzen, EPYC (CPUID 8000_0001h ECX bit 2, tables imbriquées NPT, VM_CR.SVMDIS à 0)</td><td>EFER.SVME, zone de sauvegarde de l'hôte (VM_HSAVE_PA), bloc de contrôle <b>VMCB</b> de 4 Ko (interceptions : INTR, NMI, CPUID, INVD, HLT, toutes les E/S par l'IOPM, les MSR par le MSRPM, arrêt, VMRUN à SKINIT), <b>tables NPT</b> à deux niveaux qui projettent l'adresse physique 0 de l'invité sur sa mémoire, ASID 1 ; VMSAVE/VMLOAD autour de <b>VMRUN</b> (FS, GS, TR et LDTR de l'hôte), GIF fermé pendant les échanges ; interruptions injectées par EVENTINJ, sortie VINTR quand l'invité masque les interruptions.</td></tr>
	<tr><td><b>Intel VT-x (VMX)</b></td><td>Core 2 et suivants avec <b>EPT</b> et <b>invité sans restriction</b> (Westmere et suivants ; IA32_FEATURE_CONTROL non verrouillé à 0)</td><td>CR4.VMXE, CR0 et CR4 aux bits fixés par les MSR 486h à 489h, région <b>VMXON</b>, structure <b>VMCS</b> (VMCLEAR, VMPTRLD, VMREAD, VMWRITE), contrôles ajustés par les MSR « true » 48Dh à 490h, <b>tables EPT</b> à quatre niveaux (pages de 4 Ko en écriture différée), état de l'hôte (GDTR, IDTR, TR, CR3), VMLAUNCH puis VMRESUME ; sorties : interruptions externes, NMI, HLT, E/S, MSR, CPUID, MOV CR3/CR4 ; injection par le champ d'entrée et la fenêtre d'interruption ; INVEPT quand les tables changent.</td></tr>
	<tr><td><b>Mode virtuel 8086</b> (plan B)</td><td>tout 80386 et suivant</td><td>comme les sessions DOS d'OS/2 2.x : l'invité s'exécute en mode V86 à l'anneau 3 dans la tâche de l'application, ses 256 premières pages sont sa mémoire ; les instructions sensibles (IN, OUT, INT, IRET, PUSHF, POPF, CLI, STI, HLT) provoquent une faute de protection générale que le moniteur du noyau traite, IF est virtuel ; la minuterie de l'hôte détourne l'invité vers un HLT en F000:FF00 pour rendre la main à l'application. Pas de mode protégé dans l'invité ni de zone haute (HMA) : HIMEM.SYS et DOS=HIGH exigent AMD-V ou VT-x (au démarrage de MS-DOS, F5 saute CONFIG.SYS). Un invité qui passe en mode protégé (LGDT, LIDT, LMSW, MOV CR0) ou qui touche la mémoire au-dessus de 1 Mo est arrêté avec ce message. La fenêtre VGA est retirée par les pages de l'invité : les modes planaires sont émulés aussi en V86.</td></tr>
</table>

Sans aucune méthode, Virtualisation refuse de démarrer. Le menu <b>Machine &gt; Information de virtualisation</b> (et le bouton du même nom) ouvre une boîte qui donne la méthode utilisée et tous les détails techniques : fabricant et nom du processeur (CPUID), famille, modèle et révision ; AMD-V : présence, révision SVM, nombre d'ASID, NPT, NRIP, verrou, désactivation par le BIOS ; Intel VT-x : révision de la VMCS, EPT (écriture différée ou non), invité sans restriction, VPID ; pour la machine en fonction : mémoire de l'invité et son adresse physique, VMCB ou VMCS, racine des tables NPT ou EPT, IOPM et MSRPM, interceptions, mode d'injection, compteurs des sorties de l'invité (E/S, HLT, interruptions de l'hôte, CPUID, MSR), services du BIOS, interruptions injectées, géométrie et activité du disque.

Comme KVM, le noyau ne fait que le processeur (<b>KrnVirt</b>, partie 13e d'OS2KRNL, exportée par DOSCALLS) : <code>KrnVirt(0)</code> information, <code>(1, taille, méthode)</code> création de la machine (bloc contigu au-delà de 16 Mo, vu par l'application à la même adresse), <code>(2, cadre)</code> exécution jusqu'à la sortie suivante (cadre de 160 octets : registres, segments et leurs bases, CR0, CR3, CR4, interruption à injecter, raison et détails de la sortie), <code>(3)</code> destruction, <code>(4)</code> police 8 × 16 du VGA, <code>(5)</code> compteurs, <code>(6, état)</code> <b>ligne A20</b> (les 16 pages de la zone HMA retombent sur 0-FFFFh quand elle est fermée, comme sur un PC), <code>(7, état)</code> <b>fenêtre VGA</b> A0000h-AFFFFh absente ou présente (pages de l'invité en mode V86, entrées NPT ou EPT, TLB vidé ou INVEPT) pour émuler les modes planaires ; le cadre donne aussi le bit D du segment de code (offset 136 : code 16 ou 32 bits, lu dans le VMCB ou la VMCS). CPUID (sans SVM ni VMX pour l'invité), RDMSR/WRMSR et les instructions de virtualisation de l'invité (#UD) sont traités dans le noyau. Un programme de PM n'étant pas préempté, la tâche de la machine cède le processeur aux autres tâches à la fin de sa tranche de 30 ms (après une sortie due à la minuterie de l'hôte). Le reste de la machine est dans VIRTUAL.EXE, en Pascal :

<table>
	<tr><th>Partie</th><th>Contenu</th></tr>
	<tr><td><b>BIOS</b></td><td>Talons des vecteurs en F000:1000h (STI, OUT 0EEh, RETF 2) servis par l'application à chaque sortie d'E/S ; gestionnaires INT 08h (compteur de 0040:006Ch, INT 1Ch, fin d'interruption) et INT 09h (INT 15h AH=4Fh pour KEYB, puis traduction des codes de balayage) en code 16 bits ; POST : vecteurs, données du BIOS, tables (configuration, disquette, disque dur), polices 8 × 8, 8 × 14 et 8 × 16, F000:FFF0h, date et modèle (AT) ; amorçage de la disquette ou du disque dur (ordre de la machine) ou du <b>CD-ROM</b> (<b>El Torito</b> : descripteur d'amorce au secteur 17, catalogue, entrée initiale ; sans émulation, les secteurs de l'image en segment:0000 avec DL = E0h ; émulation d'une disquette de 1,2, 1,44 ou 2,88 Mo, lecteur 00h, la vraie disquette passant en 01h ; émulation d'un disque dur, lecteur 80h, les disques passant en 81h et 82h, taille tirée de sa table des partitions).</td></tr>
	<tr><td><b>INT 10h</b></td><td>Modes texte 40 et 80 colonnes de 25 à 50 lignes, CGA 04h, 05h et 06h, VGA 13h (320 × 200 en 256 couleurs) ; curseur, pages, défilement, caractères, télétype, points, palette et DAC, polices utilisateur (11h : <b>DISPLAY.SYS</b> et pages de codes 863), informations (11h 30h, 12h, 1Ah) ; écritures directes de la police dans le plan 2 reprises au retour au mode texte ; <b>modes planaires 16 couleurs 0Dh, 0Eh, 10h et 12h</b> (tables de registres d'IBM, points, texte du BIOS et défilement dans les plans).</td></tr>
	<tr><td><b>VGA planaire</b></td><td>Dans les modes 16 couleurs, A0000h-AFFFFh n'est pas de la mémoire ordinaire : 4 plans de 64 Ko, verrous, modes d'écriture 0 à 3 (rotation, fonction logique, set/reset, masques de bits et de plans) et de lecture 0 et 1 (comparaison de couleur). Dès que les registres du séquenceur et du contrôleur graphique de l'invité désignent un mode planaire (par le BIOS ou directement par 3C4h/3CEh), la fenêtre est retirée à l'invité (KrnVirt 7) : chaque accès sort vers l'application, qui <b>émule l'instruction</b> fautive (préfixes de segment, 66h, 67h, REP ; MOV, MOVS de plan à plan par les verrous, STOS, LODS, CMPS, SCAS, opérations arithmétiques et logiques avec les drapeaux, TEST, XCHG, MOVZX/MOVSX, INC/DEC, NOT/NEG, décalages et rotations ; adresses 16 et 32 bits) puis reprend l'invité ; une répétition REP est traitée en une seule sortie. L'image est rendue selon le CRTC (largeur, hauteur affichée, départ, largeur de ligne, division d'écran), les registres de palette et le DAC, y compris le 256 couleurs non chaîné (mode X) ; la fenêtre de la machine passe à 350, 400 ou 480 lignes selon l'invité.</td></tr>
	<tr><td><b>INT 13h</b></td><td>Lecture, écriture, vérification en CHS (géométrie de la table des partitions : 128 têtes et 63 secteurs pour le VHD de MS-DOS 6.22 de VirtualBox), paramètres (08h, 15h), extensions LBA 41h, 42h, 43h, 44h et 48h ; disques 80h et 81h, disquette 00h ; <b>CD-ROM</b> E0h (extensions 41h, 42h en secteurs de 2048 octets, 48h ; 4Bh : état et fin de l'émulation El Torito) et lecteurs émulés par le CD-ROM.</td></tr>
	<tr><td><b>INT 11h à 1Ah</b></td><td>Équipement, mémoire (640 Ko), INT 15h (88h, 87h, E801h, E820h, C0h, 24xxh pour A20, 4Fh, 86h, <b>APM 1.2</b> 53xxh : installation, connexion du mode réel, version, activation, état de l'alimentation, et 5307h « hors tension » qui éteint la machine et ferme sa fenêtre, comme <code>POWER ADV:OFF</code> de MSDOS-0), clavier INT 16h (tampon de 0040:001Eh, attente d'une touche sans occuper le processeur), imprimante et ports série absents, horloge INT 1Ah (tops, heure et date de l'hôte).</td></tr>
	<tr><td><b>Périphériques</b></td><td>8259A maître et esclave (initialisation, masques, IRR/ISR, fin d'interruption simple et spécifique), 8254 (canaux 0 et 2, verrou, port 61h), 8042 (port 60h et 64h, octet de commande, A20, remise à zéro, commandes du clavier ED, F2, F4, FF...), horloge CMOS (70h, 71h : heure, date, mémoire, disquettes), VGA (CRTC, séquenceur, contrôleur graphique, attributs, DAC, 3DAh), port 92h, PCI absent, port E9h (journal de l'invité) ; <b>contrôleurs IDE</b> en PIO pour les invités en mode protégé : canal primaire 1F0h-1F7h/3F6h (disques 0 et 1 en <b>ATA</b> : IDENTIFY, READ/WRITE SECTORS et MULTIPLE, SET MULTIPLE, LBA 28 bits et CHS, READ NATIVE MAX, IRQ 14), canal secondaire 170h-177h/376h (<b>CD-ROM ATAPI</b> : IDENTIFY PACKET, paquets de 12 octets, READ(10) et READ(12) par blocs dans la limite d'octets de l'hôte, READ CAPACITY, READ TOC, INQUIRY, REQUEST SENSE, MODE SENSE, GET CONFIGURATION, TEST UNIT READY, IRQ 15), signature ATAPI, remise à zéro logicielle, nIEN.</td></tr>
	<tr><td><b>Fenêtres</b></td><td>Gestionnaire : liste des machines (C:\VMS et OS2.INI, application PM_Virtualisation), détails par sections (Général, Système, Stockage, Fichier), boutons Nouvelle, Configuration, Retirer, Démarrer, Information de virtualisation ; menus Fichier, Machine, Aide. Configuration : nom, type (liste déroulante : systèmes de GitHub ou fournis localement, enregistré comme OSType de VirtualBox), mémoire, disques 0 et 1, création d'un <b>VHD dynamique</b>, disquette, <b>CD-ROM (image ISO)</b>, amorcer d'abord la disquette ou le CD-ROM ; le .vbox est écrit dans C:\VMS\nom (D:\VMS si C: est en lecture seule). Téléchargement : fenêtre de progression, puis démarrage de la machine sur le CD-ROM. Fenêtre de la machine : écran de l'invité (image de 8 bits par point montrée par GpiDrawBits, seulement quand il change), clavier remis à l'invité en codes de balayage (KEYB CF de l'invité garde sa disposition ; Alt+M, Alt+P et Alt+A ouvrent les menus de la fenêtre), barre d'état (méthode, sorties, disque, icônes du disque dur, du CD-ROM et de la disquette ; clic : menu des supports) ; menu Périphériques (choisir ou éjecter le CD-ROM et la disquette, informations sur les disques) ; menu Machine (Pause, Réinitialiser, Envoyer Ctrl+Alt+Suppr, Information de virtualisation, Éteindre la machine). La machine tourne dans sa propre tâche (DosCreateThread).</td></tr>
</table>

Pour démarrer une machine de VirtualBox, copier son dossier (fichier .vbox et disques) ou seulement son disque (.vhd, .vdi) dans <b>C:\VMS</b> : Virtualisation la trouve au démarrage (ou par Machine &gt; Actualiser) et écrit un .vbox à côté d'un disque seul. Dans VirtualBox, OS/2-0 profite d'AMD-V ou de VT-x si la case <b>Activer VT-x/AMD-V imbriqué</b> de la machine d'OS/2-0 est cochée (Système &gt; Processeur) ; sinon le plan B (V86) s'applique. Sous QEMU, le mode réel de l'invité avec NPT n'est pas traduit par la version 8.2 (les essais d'AMD-V et de VT-x se font sous Bochs).

<code>VIRTUAL /TEST</code> fait les essais sans fenêtre (résultat sur COM1) : création d'un VHD dynamique et écriture d'un secteur d'amorce (allocation d'un bloc), .vbox écrit puis relu, amorçage d'un invité d'essai (INT 10h, lecture CHS et écriture LBA par INT 13h, minuterie avec HLT, touche par le 8042, mode 13h, INT 15h 88h), Information de virtualisation, secteur écrit par l'invité relu dans le VHD. <code>VIRTUAL /BOOTTEST:disque /WAIT:n /KEYS:texte</code> démarre un disque sans fenêtre, tape le texte (| : Entrée) après n secondes et écrit l'écran sur COM1 ; <code>/TRACE</code> journalise chaque sortie ; <code>/ADD:fichier</code> ajoute une machine (.vbox) ou un disque ; <code>/START:nom</code> démarre une machine et <code>/KEYS:texte</code> tape ce texte à son démarrage (<code>#</code> : F5, qui fait sauter CONFIG.SYS et AUTOEXEC.BAT à MS-DOS). <code>/BOOTTEST:image.ISO</code> amorce un CD-ROM, avec <code>/HD:disque.vhd</code> (créé par <code>/HDMB:n</code> s'il n'existe pas), <code>/MEM:n</code> (Mo), <code>/RUN:n</code> (secondes après les touches) ; dans <code>/KEYS:</code>, <code>^</code> est aussi Entrée (la barre verticale est un tube pour CMD.EXE). <code>/ADD:image.ISO</code> crée une machine amorcée par ce CD-ROM, <code>/NEW</code> ouvre Nouvelle machine virtuelle et <code>/VMS:dossier</code> choisit le dossier des machines ; <code>/SHOT:COM</code> (avec /BOOTTEST) écrit l'image de l'invité sur COM1 à la fin de l'essai, <code>/SHOT:fichier.BMP</code> dans un fichier BMP.

<h3>Gestionnaire des tâches (TASKMGR.PAS)</h3>

L'OS/2 d'origine n'avait <b>pas de gestionnaire des tâches</b> : la Liste des fenêtres (Ctrl+Échap) permettait seulement de passer d'un programme à l'autre ou d'en fermer un, sans rien dire de l'occupation du processeur ni de la mémoire. OS/2-0 en ajoute un : <b>TASKMGR.PAS</b> (TASKMGR.EXE) reprend la présentation et les fonctions du Gestionnaire des tâches de Windows XP, avec l'apparence d'OS/2 Warp 3 (fond gris, reliefs, onglets de carnet, cadres de groupe gravés, boutons de PM). On l'ouvre par le menu contextuel du bureau (<b>Gestionnaire des tâches</b>) ou par son objet du dossier <b>Système OS/2</b> (icône d'un moniteur avec sa courbe).

<table>
	<tr>
		<td align="center"><img src="IMAGE/TASKMGR_PERF.png" width="400" alt="Gestionnaire des tâches : Performances"><br><i>Performances : utilisation du processeur (temps du noyau en rouge) et de la mémoire, pendant le lancement de Klondike puis de Mahjongg</i></td>
		<td align="center"><img src="IMAGE/TASKMGR_PROC.png" width="400" alt="Gestionnaire des tâches : Processus"><br><i>Processus : nom, PID, processeur, mémoire, fils et session de chaque processus, triés par colonne</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/TASKMGR_RESEAU.png" width="400" alt="Gestionnaire des tâches : Réseau"><br><i>Réseau : trames par seconde de l'interface lan0 (carte Intel PRO/1000, adresse obtenue par DHCP)</i></td>
		<td></td>
	</tr>
</table>

<table>
	<tr><th>Onglet</th><th>Contenu</th></tr>
	<tr><td><b>Applications</b></td><td>Fenêtres principales des programmes (cadres de PMWIN avec un titre) et sessions plein écran. <b>Fin de tâche</b> (WM_CLOSE à la fenêtre, ou arrêt des processus de la session), <b>Basculer vers</b> (double clic, Entrée), <b>Nouvelle tâche...</b> (dialogue « Créer une nouvelle tâche » : le programme est cherché dans le répertoire courant, le PATH et C:\ ; un programme de PM démarre dans la session de PM, les autres dans une nouvelle session ; .CMD et .BAT par CMD.EXE).</td></tr>
	<tr><td><b>Processus</b></td><td>Nom de l'image et type (PM, VIO, LX, DOS), PID, utilisation du processeur (%), mémoire (fenêtre du processus, blocs du tas du noyau, grands blocs), nombre de fils, session ; le <b>Processus inactif</b> et le noyau (<b>OS2KRNL</b>) ; tri en cliquant les titres des colonnes. <b>Terminer le processus</b> (Suppr), après confirmation : DosKillProcess.</td></tr>
	<tr><td><b>Performances</b></td><td>Jauge et historique de l'utilisation du processeur (vert vif sur grille vert sombre qui défile ; temps du noyau en rouge : menu Affichage), jauge et historique de la mémoire utilisée (jaune) ; <b>Totaux</b> (handles, fils, processus), <b>Mémoire physique</b> (totale, disponible, disque virtuel), <b>Charge dédiée</b> (totale, limite, maximale), <b>Mémoire du noyau</b> (totale, tas des processus, noyau).</td></tr>
	<tr><td><b>Réseau</b></td><td>Historique des trames par seconde de l'interface lan0 (échelle automatique), carte et pilote, adresse MAC, état de la liaison et adresse IP, trames reçues et envoyées (TCPIP32.DLL).</td></tr>
	<tr><td><b>Utilisateurs</b></td><td>Sessions de l'utilisateur : numéro, état (actif au premier plan, arrière-plan, inactif) et titre ; <b>Basculer vers</b>, <b>Fermer la session</b> (arrête ses programmes).</td></tr>
	<tr><td>Menus et barre d'état</td><td>Fichier (Nouvelle tâche, Quitter), Affichage (Actualiser maintenant F5, fréquence d'actualisation haute 0,5 s, normale 1 s, basse 4 s ou suspendue, temps du noyau), Aide ; barre d'état : processus, utilisation du processeur, charge dédiée. Ctrl+Tab change d'onglet.</td></tr>
</table>

Le multitâche du noyau existait (tâches, ordonnanceur préemptif, sessions) ; pour le Gestionnaire des tâches, le noyau compte maintenant le temps du processeur à chaque interruption de la minuterie (100 Hz) : temps <b>inactif</b> (processeur arrêté par hlt dans la boucle d'attente), temps de chaque <b>processus</b>, temps du <b>noyau</b> (code interrompu hors du programme : noyau et DLL du système). Deux nouvelles fonctions le donnent aux programmes : <b>KrnTaskCtl 34</b> (état du système : tops, temps inactif et du noyau, mémoire physique et disponible, tas du noyau, fils, processus, handles, disque virtuel) et <b>KrnTaskCtl 35</b> (un processus : PID, parent, fils, temps du processeur, mémoire, session, type, nom et chemin). PMWIN détruit maintenant les fenêtres d'un processus terminé de force (au plus une fois par seconde, pendant l'attente des messages) et efface le curseur d'une fenêtre détruite. Les graphiques utilisent des couleurs RGB (GpiCreateLogColorTable, LCOLF_RGB) quand l'écran a plus de 16 couleurs.

<h3>Navigateur Web (BROWSER.PAS)</h3>

On a beaucoup reproché à OS/2 Warp 3 sa faiblesse sur le <b>Web</b> : à l'heure où Internet arrivait chez tout le monde, il n'offrait qu'un navigateur à part, le WebExplorer de l'Internet Access Kit, vite dépassé (ni JavaScript, ni outils pour les développeurs) et mal intégré au reste du système. OS/2-0 en a un, intégré au bureau : <b>BROWSER.PAS</b> (BROWSER.EXE). On l'ouvre par le menu contextuel du bureau (<b>Navigateur Web</b>), par son icône du bureau (un globe devant une page) ou par son objet du dossier <b>Système OS/2</b> ; depuis CMD, <code>BROWSER adresse</code> l'ouvre sur une page.

<table>
	<tr>
		<td align="center"><img src="IMAGE/WEB_BUREAU.png" width="400" alt="Bureau : icône et menu contextuel du Navigateur Web"><br><i>Le Navigateur Web sur le bureau et dans son menu contextuel</i></td>
		<td align="center"><img src="IMAGE/WEB_GLADIR.png" width="400" alt="Navigateur Web : page de type Gladir.com"><br><i>Page reproduisant la structure de www.gladir.com : bandeau, colonne de rubriques, tableaux imbriqués, images</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/WEB_GOOGLE.png" width="400" alt="Navigateur Web : page de type Google"><br><i>Page reproduisant celle de www.google.ca : logo PNG, formulaire de recherche, scripts</i></td>
		<td align="center"><img src="IMAGE/WEB_JS.png" width="400" alt="Navigateur Web : démonstration JavaScript"><br><i>JavaScript : document.write, DOM modifié par un clic, horloge (setInterval), feuille CSS externe</i></td>
	</tr>
</table>

<h4>Le concept : le navigateur de DEV-COOLS, refait pour Presentation Manager</h4>

Le point de départ est le navigateur graphique <b>BROWSER.PAS</b> du dépôt <b>DEV-COOLS</b> (Turbo Pascal / Free Pascal, unité Graph, WinInet). Son architecture est gardée : lecture de la source HTML, analyseur qui construit un arbre de nœuds, moteur de rendu par balises, décodeurs d'images GIF, PNG, JPEG et BMP, historique, favoris, barre d'adresse et boutons Précédent / Suivant / Actualiser. Tout le reste est refait pour qu'il soit un vrai programme d'OS/2, qui ne pourrait pas tourner ailleurs :

<table>
	<tr><th>Élément</th><th>Avec l'apparence d'OS/2 Warp 3</th></tr>
	<tr><td>Fenêtre</td><td>Cadre de PM redimensionnable (titre, menu système, bordure), vrai menu de PM (Fichier, Affichage, Aller, Signets, Options, Aide), raccourcis (Alt+Gauche, F5, Ctrl+U, F12...), barre d'état gravée, boîtes de message et dialogues de PM.</td></tr>
	<tr><td>Barre d'outils</td><td>Boutons en relief portant des <b>icônes d'OS/2</b> créées par l'API des pointeurs et icônes (WinCreatePointerIndirect, WinDrawPointer) : Précédent, Suivant, Arrêter, Actualiser, Accueil, Signets, Code source ; grisées (DP_HALFTONED) quand l'action est impossible ; globe d'OS/2 allumé pendant le chargement, grisé ensuite.</td></tr>
	<tr><td>Contrôles</td><td>Champ d'adresse WC_ENTRYFIELD (tout sélectionné à l'activation : la frappe remplace l'adresse), barre de défilement WC_SCROLLBAR, menu contextuel par WinCreateMenu et WinPopupMenu, presse-papiers de PM.</td></tr>
	<tr><td>Dessin</td><td>GPI : couleurs RGB, polices mises à l'échelle (GpiSetCharBox), images par GpiDrawBits, à partir d'une liste d'affichage ; le défilement et les scripts ne redessinent que ce qui change. En 16 couleurs, les couleurs des pages sont ramenées à celles de la palette.</td></tr>
	<tr><td>Réseau</td><td>TCPIP32.DLL d'OS/2-0 (HTTP/1.1 : redirections, transfert « chunked », proxy HTTP), dans un fil d'exécution à part : la fenêtre reste vivante pendant le chargement (bouton Arrêter).</td></tr>
	<tr><td>Réglages</td><td>Signets, page d'accueil, proxy et options dans <b>OS2.INI</b> (application BROWSER).</td></tr>
</table>

<h4>Les problèmes corrigés</h4>

Le navigateur d'origine plantait sur <b>www.google.ca</b> et sur <b>www.gladir.com</b>. Les causes, et celles trouvées en chemin dans OS/2-0 lui-même, sont corrigées :

<table>
	<tr><th>Problème</th><th>Correction</th></tr>
	<tr><td>Le contenu des &lt;script&gt; et &lt;style&gt; était analysé comme du HTML (un <code>a&lt;b</code> d'un script ouvrait des balises sans fin)</td><td>Contenu de &lt;script&gt;, &lt;style&gt; et &lt;textarea&gt; lu comme texte brut, jusqu'à sa balise de fin.</td></tr>
	<tr><td>Pages très imbriquées (tableaux dans des tableaux), pages énormes</td><td>Profondeur de l'arbre et de la récursion bornées, tableaux aux colonnes et lignes bornées (au-delà de 12 niveaux, cellules mesurées simplement), corps des réponses et images de taille bornée, mémoire épuisée gérée (page tronquée au lieu d'un plantage).</td></tr>
	<tr><td>Accents illisibles</td><td>UTF-8 reconnu par validation des séquences complètes, converti en page de codes 850 ; entités inconnues gardées telles quelles.</td></tr>
	<tr><td>Attributs sans valeur ou mal fermés, images tronquées ou corrompues</td><td>Analyseur tolérant ; décodeurs d'images vérifiés à chaque lecture (image ignorée au lieu d'un plantage).</td></tr>
	<tr><td>Boucle sans fin dans un script</td><td>Budget d'instructions et mémoire bornée pour le JavaScript : le script est arrêté, avec un message dans la Console.</td></tr>
	<tr><td>Débordement de pile (« runtime error 216 ») sur certaines pages</td><td>Défaut du compilateur <b>OS2PC</b> : ses routines de chaînes écrivaient un octet nul <i>après</i> le 255<sup>e</sup> caractère, une case trop loin. Elles sont maintenant limitées à 254 caractères.</td></tr>
	<tr><td><code>Break</code> compilé comme un appel de procédure, appels à des procédures inexistantes acceptés sans rien dire</td><td>OS2PC : un littéral d'un caractère comme <code>')'</code> était confondu avec la ponctuation, ce qui faussait la suite de l'instruction. Il avertit aussi maintenant des procédures et fonctions non définies (et, avec -w, des variables implicites).</td></tr>
	<tr><td>Fonction qui s'appelait elle-même sans fin (plantage TRAP 6)</td><td>OS2PC compile le nom d'une fonction lu dans son propre corps comme un appel récursif : le navigateur utilise une variable locale pour le résultat.</td></tr>
	<tr><td>Calculs en virgule flottante faux quand plusieurs programmes tournent</td><td>Noyau : l'état du coprocesseur x87 est sauvé et rendu à chaque changement de tâche (FNSAVE, FRSTOR).</td></tr>
	<tr><td>F12 agissait comme F5</td><td>PMWIN : codes de balayage de F11 et F12 (0x57 et 0x58) traduits en VK_F11 et VK_F12.</td></tr>
	<tr><td>Page qui clignotait chaque seconde avec une horloge en JavaScript</td><td>Redessin partiel : après chaque mise en page, seules les opérations de dessin qui ont changé sont invalidées.</td></tr>
</table>

Pour s'en assurer, le moteur (analyseur, CSS, mise en page, JavaScript) est aussi compilé par Free Pascal sur l'hôte, avec vérification des bornes, et passé au <b>test aléatoire</b> : 400 pages HTML et 600 scripts déformés au hasard, sans aucun plantage ; puis 40 pages dans OS/2-0 sous QEMU. Remarque : l'environnement des essais n'avait pas accès aux vrais sites ; www.google.ca et www.gladir.com ont donc été <b>reproduits</b> sur un petit serveur HTTP local (même structure, mêmes pièges : scripts, tableaux imbriqués, UTF-8, images), que QEMU voit à l'adresse 10.0.2.2.

<h4>Les possibilités</h4>

<table>
	<tr>
		<td align="center"><img src="IMAGE/WEB_MENU.png" width="400" alt="Navigateur Web : menu contextuel d'un lien"><br><i>Bouton 2 sur un lien : menu contextuel de PM</i></td>
		<td align="center"><img src="IMAGE/WEB_QR.png" width="400" alt="Navigateur Web : code QR de la page"><br><i>Créer un code QR pour cette page : à lire avec un téléphone</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/WEB_SOURCE.png" width="400" alt="Navigateur Web : code source"><br><i>Code source (view-source:, Ctrl+U) numéroté et coloré</i></td>
		<td align="center"><img src="IMAGE/WEB_INSPECTEUR.png" width="400" alt="Outils de développement : Inspecteur"><br><i>F12, Inspecteur : élément choisi à la souris, encadré en orange dans la page</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/WEB_CONSOLE.png" width="400" alt="Outils de développement : Console"><br><i>Console : expressions évaluées, erreurs, DOM modifié en direct</i></td>
		<td align="center"><img src="IMAGE/WEB_RESEAU.png" width="400" alt="Outils de développement : Réseau"><br><i>Réseau : chaque requête de la page (état, type, taille, durée)</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/WEB_STYLE.png" width="400" alt="Outils de développement : Éditeur de style"><br><i>Éditeur de style : la couleur du titre changée en direct dans demo.css</i></td>
		<td align="center"><img src="IMAGE/WEB_DEBOGUEUR.png" width="400" alt="Outils de développement : Débogueur"><br><i>Débogueur : scripts de la page, internes et externes</i></td>
	</tr>
	<tr>
		<td align="center"><img src="IMAGE/WEB_HTTPS.png" width="400" alt="Navigateur Web : https://www.gladir.com/ en TLS 1.3"><br><i>https://www.gladir.com/ (le vrai site) en TLS 1.3 par TLS32.DLL : la barre d'état indique la connexion chiffrée</i></td>
		<td></td>
	</tr>
</table>

<h4>HTTPS : TLS32.DLL</h4>

Les adresses <b>https://</b> sont chiffrées par <b>TLS32.DLL</b> (DLL/TLS32.PAS), entièrement écrite en Pascal pour OS/2-0 : <b>TLS 1.3</b> (RFC 8446, suite TLS_AES_128_GCM_SHA256) et, pour les serveurs qui ne le connaissent pas, <b>TLS 1.2</b> (ECDHE-RSA et ECDHE-ECDSA avec AES-128-GCM et SHA-256). L'échange de clés se fait en <b>X25519</b> (RFC 7748). SHA-256, HMAC, HKDF, la PRF de TLS 1.2, AES-128 et GCM sont aussi écrits en Pascal, sans entiers de 64 bits (OS2PC n'en a pas). Le chiffrement a été vérifié avec les vecteurs d'essai des normes, puis en connexion avec OpenSSL (TLS 1.3, TLS 1.2 RSA et ECDSA, demande de certificat client) et avec de vrais sites. Le Navigateur Web et <code>WGET https://...</code> s'en servent ; avec un proxy, la connexion passe par un tunnel <code>CONNECT</code>.
Le navigateur masque les exceptions du coprocesseur (arithmétique IEEE du JavaScript : <code>1/0</code> donne <code>Infinity</code>) : le runtime d'OS2PC les démasque comme Free Pascal, et sous VirtualBox (virtualisation matérielle, CR0.NE) le calcul de <code>Infinity</code> arrêtait le navigateur (SYS3175, TRAP 0010) dès qu'une page comme https://www.gladir.com/ exécutait son JavaScript ; QEMU, en émulation, ne lève pas cette exception.
<b>Limite :</b> la chaîne de certificats du serveur n'est <b>pas vérifiée</b> (OS/2-0 n'a pas de magasin d'autorités de certification). La connexion est chiffrée et le message Finished du serveur est vérifié, mais un intermédiaire actif pourrait se faire passer pour le serveur ; la barre d'état le rappelle (« certificat non vérifié »). Un serveur qui n'accepte que la courbe P-256 pour l'échange de clés refuse la connexion.

<table>
	<tr><th>Fonction</th><th>Détails</th></tr>
	<tr><td><b>Pages</b></td><td>HTML (titres, paragraphes, listes, tableaux, formulaires, liens, ancres, &lt;meta refresh&gt;), CSS (feuilles &lt;link&gt; et &lt;style&gt;, attribut style ; couleurs, fonds, polices, alignement, marges et espacements), images GIF, PNG, JPEG et BMP, pages text/plain, adresses http://, file:///C:/... et about:home. Enregistrer sous : les octets reçus tels quels, avec confirmation avant de remplacer un fichier.</td></tr>
	<tr><td><b>JavaScript</b></td><td>Sous-ensemble d'ECMAScript 5 et 6 : var, let, const, fonctions et fonctions fléchées, objets, tableaux (map, filter, reduce, forEach...), chaînes, décomposition (...), switch, try/catch, for-in/for-of, Math, Date, JSON ; document.write, DOM (getElementById, querySelector, innerHTML, textContent, style, classList, createElement, appendChild...), événements (onclick, addEventListener, onload, DOMContentLoaded, onsubmit, onchange, survol), setTimeout et setInterval, location, history, alert.</td></tr>
	<tr><td><b>Code source</b></td><td>view-source:adresse, Ctrl+U ou menu Affichage : lignes numérotées ; balises, attributs, valeurs, commentaires, scripts et styles en couleurs.</td></tr>
	<tr><td><b>Menu contextuel</b></td><td>Bouton 2 dans la page : Ouvrir le lien, Code QR du lien, Copier l'adresse du lien (presse-papiers de PM), Précédent, Suivant, Actualiser, Voir le code source, Enregistrer sous..., Créer un code QR pour cette page, Inspecter (F12). Les actions impossibles sont grisées.</td></tr>
	<tr><td><b>Code QR</b></td><td>Générateur écrit pour OS/2-0 : versions 1 à 10 (jusqu'à 271 octets), niveau de correction L, blocs Reed-Solomon entrelacés, choix du meilleur des 8 masques. Vérifié par un vérificateur indépendant (format BCH, syndromes Reed-Solomon) et, module par module, sur la capture d'écran.</td></tr>
	<tr><td><b>Outils de développement (F12)</b></td><td>Panneau ancré sous la page, à la manière de <b>Firebug</b> : <b>Inspecteur</b> (arbre du DOM repliable, attributs, style calculé ; bouton de sélection puis clic dans la page, ou Inspecter du menu contextuel), <b>Débogueur</b> (scripts internes et externes), <b>Éditeur de style</b> (double clic sur une ligne d'une feuille : la page est restylée aussitôt), <b>Console</b> (messages de console.log, warn et error, erreurs des scripts ; Entrée évalue une expression dans la page, flèches haut et bas pour l'historique), <b>Réseau</b> (état, méthode, domaine, fichier, type, taille et durée de chaque requête ; clic : détails dans la barre d'état).</td></tr>
	<tr><td><b>Presse-papiers</b></td><td>Ajouté pour l'occasion aux champs de saisie de PMWIN, avec les touches CUA d'OS/2 : Maj+Inser (coller), Ctrl+Inser (copier), Maj+Suppr (couper), et aussi Ctrl+V, Ctrl+C et Ctrl+X.</td></tr>
	<tr><td><b>Diagnostic</b></td><td><code>SET BROWSER_TRACE=1</code> dans CONFIG.SYS recopie la console et les étapes du chargement sur la sortie standard (le port série sous QEMU).</td></tr>
</table>

Pour l'essayer sous QEMU, il faut une carte réseau : <code>qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d -nic user,model=e1000</code>. Les sites en <b>https://</b> passent par <b>TLS32.DLL</b> (voir plus bas) ; un proxy HTTP reste possible (menu Options - Proxy, ou <code>SET HTTP_PROXY=hôte:port</code> : tunnel CONNECT). Du navigateur d'origine, ne sont pas encore repris : les flux RSS/Atom, les cadres &lt;iframe&gt; affichés dans la page (ils sont remplacés par un lien), la liste des répertoires ftp://, le texte des PDF et les images SVG.

<h3>Pascal Developer (PASDEV.PAS) et dossier Developer Kit</h3>

Le bureau a maintenant un dossier <b>Developer Kit</b> qui contient <b>Pascal Developer</b> (PASDEV.EXE), un environnement de développement intégré Pascal dans l'esprit de Borland Pascal, mais avec l'apparence d'OS/2 :

<img width="800" height="600" alt="OS/2-0 : le dossier Developer Kit du bureau et l'objet Pascal Developer" src="IMAGE/DEVKIT.png" />

<img width="800" height="600" alt="OS/2-0 : Pascal Developer, source coloré et fenêtre Messages après la compilation" src="IMAGE/PASDEV.png" />

<table>
	<tr><th>Fonction</th><th>Description</th></tr>
	<tr><td>Fenêtres MDI</td><td>Les sources s'ouvrent dans des fenêtres d'édition dessinées dans la zone de travail : barre de titre aux couleurs du système (glisser pour déplacer, double clic ou case de droite pour agrandir, case de gauche pour fermer), barres de défilement, coin de redimensionnement ; menu Fenêtre : Mosaïque, Cascade, Suivante (F6), Messages, Liste (Alt+0), Fermer tout.</td></tr>
	<tr><td>Coloration syntaxique</td><td>Mots réservés, directives <code>{$...}</code>, commentaires <code>{ }</code>, <code>(* *)</code> et <code>//</code> (même sur plusieurs lignes), chaînes et caractères <code>#nn</code>, nombres décimaux et hexadécimaux.</td></tr>
	<tr><td>Fichier, Édition, Recherche</td><td>Nouveau (Ctrl+N), Ouvrir (F3 : liste des répertoires et des sources), Enregistrer (F2), Enregistrer sous, Enregistrer tout, Fermer (Alt+F3), Quitter (Alt+X) ; Couper, Copier, Coller (presse-papiers de PM, touches CUA et Borland), Effacer, Tout sélectionner ; Rechercher (Ctrl+F), Occurrence suivante (Ctrl+L), Aller à la ligne (Ctrl+G), Ouvrir le fichier au curseur (Ctrl+Entrée, pour un <code>Uses</code> ou un <code>{$I}</code>).</td></tr>
	<tr><td>Compiler (F9)</td><td>Le source est enregistré puis compilé par <b>OS2PC.EXE</b>, le compilateur OS2PC compilé par lui-même pour OS/2-0 ; sa sortie standard est redirigée vers un fichier et ses messages (erreurs, avertissements avec leur numéro de ligne) vont dans la fenêtre <b>Messages</b> : un double clic va à la ligne en cause. Le compilateur tourne en arrière-plan (DosExecPgm asynchrone, fin attendue par un minuteur et DosWaitChild) : l'EDI et le bureau restent utilisables pendant la compilation. Une boîte <b>Compilation</b>, comme celle de Borland Pascal, montre le fichier principal, la destination, l'étape (lecture du source, déclarations, procédures et instructions, génération du code, écriture du .EXE), la ligne en cours sur le nombre de lignes, les erreurs, les avertissements, la durée et une barre de progression ; elle se ferme à la fin. Son bouton <b>Annuler</b> (ou Échap) arrête le compilateur (DosKillProcess) : la sortie déjà produite reste dans la fenêtre Messages et l'EDI est aussitôt prêt pour une nouvelle compilation. OS2PC publie sa progression avec l'option <code>-PRG</code> dans la mémoire partagée <code>\SHAREMEM\OS2PC.PRG</code> créée par Pascal Developer (aucune écriture sur disque).</td></tr>
	<tr><td>Destination</td><td>Menu Compiler : <b>OS/2 Presentation Manager</b> (par défaut, symbole <code>OS2PM</code>) ou <b>OS/2 Console</b> (symbole <code>OS2CONSOLE</code>).</td></tr>
	<tr><td>Exécuter (Ctrl+F9)</td><td>Compile si le source a changé, puis lance le programme : directement pour PM, dans une fenêtre OS/2 (pause à la fin) pour une console ; un programme compilé pour PM qui n'ouvre aucune fenêtre (ni WinInitialize ni WinCreateStdWindow : un simple WriteLn) est lui aussi lancé dans une fenêtre OS/2, sinon sa sortie ne serait visible nulle part ; Paramètres : arguments du programme.</td></tr>
	<tr><td>Information</td><td>Taille du code, des données, de la pile et du fichier .EXE, importations, lignes compilées, durée, avertissements et erreurs de la dernière compilation.</td></tr>
	<tr><td>Barre d'état et menu contextuel</td><td>Ligne et colonne du curseur, Insertion ou Refrappe (touche Ins), fichier modifié, destination ; bouton 2 de la souris (ou Maj+F10) : Couper, Copier, Coller, Effacer, Tout sélectionner, Ouvrir le fichier au curseur, Aller à la ligne, Compiler, Exécuter, Information.</td></tr>
</table>

Alt+F9 (réduire) et F10 (menu) sont des touches du système d'OS/2 : la compilation est sur F9 (le « Make » de Borland). Deux exemples sont copiés sur le CD-ROM : <b>BONJOUR.PAS</b> (fenêtre de PM) et <b>HELLO.PAS</b> (console).

<h3>Télécharger le code source d'OS2-Zero (GETSRC.PAS)</h3>

Le dossier <b>Developer Kit</b> contient aussi <b>Télécharger le code source d'OS2-Zero</b> (GETSRC.EXE) : une boîte de dialogue qui copie le code source actuel d'OS/2-0 depuis GitHub (dépôt <code>gladir/OS2-0</code>, branche par défaut) dans le dossier <b>C:\SOURCE\OS2-0\</b>. Seuls les fichiers du projet sont copiés : ni l'historique ni les données de Git (pas de dossier <code>.git</code>). À la fin, l'<b>Explorateur OS2-Zero</b> s'ouvre sur le dossier.

<img width="640" height="480" alt="OS/2-0 : Télécharger le code source d'OS2-Zero, téléchargement en cours (fichier, pourcentage, vitesse, temps restant)" src="IMAGE/GETSRC.png" />
<img width="640" height="480" alt="OS/2-0 : le code source copié, ouvert dans l'Explorateur OS2-Zero" src="IMAGE/GETSRC_FIN.png" />

<table>
	<tr><th>Fonction</th><th>Description</th></tr>
	<tr><td>Télécharger</td><td>La liste des fichiers vient de l'API de GitHub (arbre complet de la branche, <code>api.github.com</code>) ; chaque fichier est ensuite téléchargé de <code>raw.githubusercontent.com</code> en <b>https://</b> par TLS32.DLL, sur une seule connexion gardée ouverte d'un fichier à l'autre (HTTP/1.1), et les dossiers sont créés au besoin. Les noms et chemins sont ceux du dépôt.</td></tr>
	<tr><td>Mettre à jour</td><td>La liste <code>C:\SOURCE\OS2-0.LST</code> garde l'empreinte SHA-1 de Git et la taille de chaque fichier copié : seuls les fichiers nouveaux ou modifiés sont téléchargés, ceux qui ont été retirés du dépôt sont effacés. La liste est enregistrée en cours de route : après une coupure, Mettre à jour reprend où le téléchargement s'est arrêté.</td></tr>
	<tr><td>Annuler</td><td>Interrompt le téléchargement (le fichier en cours est effacé) ; une fois terminé, le bouton devient Fermer.</td></tr>
	<tr><td>Progression</td><td>Barre de progression avec pourcentage, nom du fichier en cours, nombre de fichiers et d'octets copiés, vitesse et temps restant ; le travail se fait dans un fil d'exécution à part, la fenêtre reste active.</td></tr>
	<tr><td>Images du CD-ROM</td><td>Les fichiers <code>IMAGE\*.ISO</code> (une soixantaine de Mo) ne sont copiés que si la case est cochée.</td></tr>
	<tr><td>Contrôles</td><td>Espace libre vérifié avant de commencer ; erreurs expliquées (réseau, disque, message de GitHub). L'API de GitHub permet 60 demandes par heure et par adresse sans jeton (deux par téléchargement) ; <code>SET GITHUB_TOKEN=...</code> permet d'en faire davantage. Proxy : <code>SET HTTP_PROXY=hôte:port</code>.</td></tr>
</table>

Essayé sous QEMU avec le vrai dépôt : 343 fichiers (25 Mo) copiés de raw.githubusercontent.com, puis Mettre à jour (aucun fichier à copier). La régression utilise un faux GitHub local en https:// (liste, fichiers, puis un fichier modifié, un ajouté et un retiré). Paramètres d'essai : <code>/DEST:dossier</code>, <code>/API:</code> et <code>/RAW:</code> (serveurs), <code>/AUTO</code>, <code>/UPDATE</code>, <code>/ISO</code>, <code>/NOEXPLORER</code>.

<img width="800" height="600" alt="OS/2-0 : Pascal Developer, boîte Information (taille du code et des données du programme compilé)" src="IMAGE/PASDEV_INFO.png" />

La boîte <b>À propos</b> montre Blaise Pascal écrivant OS/2 à la plume (image de 144 x 176 pels en 16 couleurs, tramée, rangée par rangée dans le source) :

<img width="800" height="600" alt="OS/2-0 : Pascal Developer, boîte À propos (Blaise Pascal écrivant OS/2)" src="IMAGE/PASDEV_APROPOS.png" />

Pour que OS2PC se compile lui-même et produise un OS2PC.EXE qui fonctionne sous OS/2-0, le compilateur a été corrigé : grandes tables allouées au démarrage (DosAllocMem), variables globales d'un type alias de <code>String</code>, <code>Pos</code> sur des chaînes Pascal (<code>Pos(#0, S)</code>), procédures imbriquées appelées par une procédure sœur (lien statique), variables portant le nom d'une fonction prédéfinie (<code>Mem</code>), <code>Move</code> avec recouvrement, procédure du programme prioritaire sur une prédéfinie du même nom (<code>InsLine</code> de Crt), caractère <code>#0</code> conservé par le lexeur. OS2PC.EXE produit les mêmes fichiers, octet pour octet, que le compilateur construit par Free Pascal (HELLO, TREE, KLONDIKE, BONJOUR, et PASDEV lui-même). OS2PC écrit le fichier .EXE par un tampon de 64 Ko : il l'écrivait octet par octet, et sous OS/2-0 chaque écriture devenait un DosWrite puis une écriture de secteur du disque (HPFS.IFS) ; compiler BONJOUR.PAS sur le disque dur faisait plus de 60 millions d'accès au contrôleur IDE et 817 000 lectures de l'horloge (sous VirtualBox au-dessus de Hyper-V, autant de sorties de la machine virtuelle : la compilation semblait figée), contre 2,2 millions (surtout le chargement d'OS2PC.EXE) et 45 maintenant ; les fichiers produits sont identiques octet pour octet. Ses tables n'ont <b>aucune taille maximale</b> : elles commencent petites et grandissent à la demande, tant qu'il reste de la mémoire (jetons, symboles, types, champs de record, procédures, données, constantes typées, commutateurs <code>{$I}</code> et <code>{$R}</code>, code machine, étiquettes, adresses à corriger, importations, exportations, relocalisations). Les tables d'enregistrements sont des tableaux de pointeurs vers des fiches allouées par blocs et jamais déplacées : seul le tableau des pointeurs grandit, si bien qu'une affectation comme <code>TypeTab^[T]^.Base := ParseType(...)</code> reste juste même si la fonction appelée ajoute des types (le code produit par OS2PC calcule l'adresse de gauche avant l'appel), et qu'aucun grand bloc contigu n'est nécessaire. Avant, OS2PC.EXE réservait environ 40 Mo au départ et avait des limites fixes (4 096 symboles, 384 types, 64 champs par record, 512 Ko de code, 8 192 étiquettes, 16 384 adresses à corriger…), au-delà desquelles certaines entrées étaient ignorées sans erreur. Maintenant, 64 Mo suffisent pour compiler PASDEV.PAS (4 000 lignes) dans OS/2-0, et un programme d'essai de 15 700 lignes (337 000 jetons, 6 600 symboles, plus de 700 types, un record de 100 champs, 1,6 Mo de code) se compile avec 256 Mo ; le compilateur construit par Free Pascal produit, pour tous les programmes du système, les mêmes fichiers octet pour octet qu'avant. Deux défauts faisaient échouer la compilation, dans OS/2-0, de programmes ordinaires (dès que la table des procédures dépassait 64 entrées, ou dès la 17e fonction externe), par exemple 421.PAS téléchargé par « Télécharger le code source d'OS2-Zero » : la compilation semblait ne jamais finir, ou finissait sur une fausse erreur « identificateur déjà déclaré ». D'abord, les petits blocs de <code>GetMem</code> et <code>New</code> de tous les programmes venaient du tas du noyau (quelques Mo partagés par tout le système), qu'OS2PC.EXE épuisait : <code>GetMem</code> rendait alors <code>Nil</code> sans erreur. Chaque processus prend maintenant au plus 256 Ko du tas du noyau ; ses autres petits blocs viennent de ses propres arènes, de la mémoire physique au-delà de 16 Mo (comme les grands blocs), découpées comme le tas du noyau et rendues à la fin du processus. Ensuite, OS2PC agrandissait ses tables de chaînes (<code>String[63]</code>, 64 octets avec Free Pascal) avec une taille d'élément écrite en dur (64), alors que le code produit par OS2PC donne 256 octets à toute chaîne courte : OS2PC.EXE écrivait au-delà de ces tables à partir de la 17e fonction externe. Les tailles s'écrivent maintenant <code>SizeOf(TProcStr)</code>, et OS2PC.EXE compile 421.PAS et FREECELL.PAS en des fichiers identiques, octet pour octet, à ceux du compilateur construit par Free Pascal.

<h3>OS2-Zero Debugger (APPS/OS2DBG.PAS)</h3>

Le dossier <b>Developer Kit</b> contient <b>OS2-Zero Debugger</b> (OS2DBG.EXE), un débogueur des programmes d'OS/2-0 dans l'esprit de la fenêtre CPU de Turbo Debugger, mais avec l'interface graphique d'OS/2 : fenêtre de Presentation Manager à bordure de taille, barre de menus (Fichier, Exécution, Points d'arrêt, Données, Aide), barre d'outils de boutons de PM, barre d'état, boîtes Ouvrir et Aller à l'adresse de PM, et quatre volets à barre de défilement de PM dont l'en-tête actif prend la couleur d'une barre de titre.

<img width="640" height="480" alt="OS/2-0 : le dossier Developer Kit et l'objet OS2-Zero Debugger" src="IMAGE/DEVKIT_DEBUGGER.png" />

<img width="640" height="480" alt="OS2-Zero Debugger : point d'arrêt sur CLIENTPROC du Bloc-notes (désassemblage coloré, registres, mémoire, pile)" src="IMAGE/OS2DBG.png" />

<table>
	<tr>
		<td align="center"><img src="IMAGE/OS2DBG_RETOUR.png" width="400" alt="OS2-Zero Debugger : jusqu'au retour dans PMWIN"><br><i>Alt+F8 : retour de CLIENTPROC dans PMWIN.DLL (point d'arrêt matériel)</i></td>
		<td align="center"><img src="IMAGE/OS2DBG_EXCEPTION.png" width="400" alt="OS2-Zero Debugger : exception"><br><i>Exception (division par zéro) vue avant la fin du programme</i></td>
	</tr>
</table>

<table>
	<tr><th>Volet</th><th>Contenu</th></tr>
	<tr><td>Code</td><td>Désassemblage x86 32 bits en syntaxe Intel (instructions générales, système et du coprocesseur), colonnes adresse, octets et instruction ; <b>coloration syntaxique</b> : instructions en bleu, sauts, appels et retours en rouge foncé, registres en magenta, nombres en vert, symboles en brun, mots clés (<code>dword ptr</code>, <code>rep</code>, <code>offset</code>) en gris ; étiquettes des procédures ; ligne d'EIP surlignée en jaune avec une flèche ; points d'arrêt en rouge avec une pastille ; à la ligne d'EIP, un saut conditionnel indique « saut effectué ↑/↓ » ou « pas de saut » d'après EFLAGS ; destination d'un saut ou d'un appel nommée en commentaire.</td></tr>
	<tr><td>Registres</td><td>EAX à EIP, EFLAGS, CS, DS, ES, FS (et CR2 après un défaut de page), drapeaux c z s o p a i d t ; une valeur changée par le dernier pas ou la dernière exécution est en rouge. Entrée ou double clic : modifier le registre (boîte de saisie de PM) ; Espace ou double clic sur un drapeau : l'inverser.</td></tr>
	<tr><td>Mémoire</td><td>16 octets par ligne (8 dans une fenêtre étroite) en hexadécimal et en ASCII, à partir de la section de données du programme ; les octets changés depuis la dernière reprise sont en rouge.</td></tr>
	<tr><td>Pile</td><td>Doubles mots à partir d'ESP (ligne jaune), ESP et EBP marqués ; une adresse de retour est nommée (<code>CLIENTPROC+1Ah</code>, ou le nom d'une fonction exportée d'une DLL). Entrée ou double clic : montrer la valeur dans le volet Code ou Mémoire.</td></tr>
</table>

<table>
	<tr><th>Commande</th><th>Touche</th><th>Effet</th></tr>
	<tr><td>Ouvrir un programme</td><td>Ctrl+O</td><td>Lance le programme sous le débogueur (DosExecPgm, EXEC_TRACE) ; il s'arrête à son point d'entrée. <code>OS2DBG programme [arguments]</code> le fait au démarrage ; Fichier → Arguments change les arguments.</td></tr>
	<tr><td>Exécuter</td><td>F9</td><td>Jusqu'au prochain point d'arrêt, à une exception ou à la fin du programme</td></tr>
	<tr><td>Pas à pas (entrer)</td><td>F7</td><td>Une instruction (drapeau TF), en entrant dans les appels, y compris dans les DLL</td></tr>
	<tr><td>Pas (sauter les appels)</td><td>F8</td><td>Saute <code>call</code>, <code>int</code>, <code>loop</code> et les instructions <code>rep</code></td></tr>
	<tr><td>Jusqu'au curseur</td><td>F4</td><td>Jusqu'à la ligne choisie</td></tr>
	<tr><td>Jusqu'au retour</td><td>Alt+F8</td><td>Jusqu'à l'adresse de retour de la procédure (cadre EBP)</td></tr>
	<tr><td>Pause</td><td>F12</td><td>Arrête le programme qui s'exécute</td></tr>
	<tr><td>Point d'arrêt</td><td>F2, clic dans la marge, double clic</td><td>Pose ou retire un point d'arrêt (INT 3) ; liste et suppression de tous par le menu Points d'arrêt</td></tr>
	<tr><td>Redémarrer, Terminer</td><td>Ctrl+F2, Alt+F2</td><td>Relance le programme (les points d'arrêt sont gardés) ou le termine</td></tr>
	<tr><td>Aller à l'adresse</td><td>Ctrl+G</td><td>Dans le volet actif : adresse hexadécimale, registre, symbole (<code>CLIENTPROC</code>, <code>WinGetMsg</code>), avec + et -</td></tr>
	<tr><td>Origine</td><td>Ctrl+E</td><td>Revient à EIP</td></tr>
	<tr><td>Volet suivant</td><td>Tab, Maj+Tab</td><td>Code, Registres, Mémoire, Pile</td></tr>
</table>

Les <b>symboles</b> viennent de la table des importations du programme (les appels <code>call dword ptr [PMWIN.WinGetMsg]</code> et les fonctions des DLL où l'on entre en pas à pas), de la table des exportations de chaque DLL utilisée (lue en mémoire) et de la carte <code>.MAP</code> du programme, si elle est à côté de lui : <code>OS2PC -GD PROG.PAS</code> la produit (procédures et fonctions). Une exception du programme (division par zéro, protection générale, défaut de page…) est montrée avant la fin du programme, avec son nom et l'instruction fautive ; reprendre l'exécution le termine.

Le <b>noyau</b> donne au débogueur ce qu'il faut (<code>KrnTaskCtl</code> 60 à 70, que DOSCALLS appelle pour <code>DosExecPgm</code> avec <code>EXEC_TRACE</code> ou <code>EXEC_ASYNCRESULTDB</code>) : le programme lancé est suivi en pas à pas (drapeau TF) jusqu'à son point d'entrée, où sa tâche est mise à l'arrêt (nouvel état de tâche que l'ordonnanceur saute) ; INT 1 et INT 3 d'un programme débogué arrêtent sa tâche au lieu de le terminer, et une exception le garde arrêté jusqu'à ce que le débogueur le laisse finir. Le débogueur lit l'état, les registres du cadre d'interruption (avec ou sans code d'erreur), lit et écrit la mémoire du programme (sa fenêtre de 4 Mo est projetée le temps de la copie), le modifie, le reprend en pas à pas ou non, l'arrête (TF posé dans les drapeaux sauvés de ses tâches) et le termine ; le programme débogué meurt avec son débogueur. Les DLL étant partagées par tous les processus, un arrêt temporaire dans une DLL (F4, F8 ou Alt+F8 vers PMWIN) n'écrit pas INT 3 dans leur code, ce qui tuerait les autres programmes : c'est un <b>point d'arrêt matériel</b> (DR0, DR7) que le noyau charge seulement quand il passe au programme débogué, et qu'il retire quand il est atteint (DR6).

Écrire le débogueur a montré qu'un nom de variable identique à une constante prédéfinie d'OS2PC (<code>MONO</code> de l'unité Graph) est pris pour la constante : la variable s'appelle autrement.

<h3>LaunchPad (LAUNCHPAD.PAS)</h3>

Le fichier <b>LAUNCHPAD.PAS</b> est le <b>LaunchPad</b> d'OS/2 Warp 3 (<b>LAUNCHPD.EXE</b> sur le CD-ROM, nom 8.3 de l'ISO 9660) : PMSHELL le lance au démarrage du bureau (sauf si OS2.INI contient PMSHELL, LAUNCHPAD = 0), dans la session de Presentation Manager, et les deux programmes s'exécutent en même temps. C'est une petite barre toujours visible, en bas au centre de l'écran (déplaçable en glissant son fond ; position gardée dans OS2.INI).

<img width="640" height="480" alt="OS/2-0 : le LaunchPad (tiroir du lecteur C: ouvert) et la fenêtre Rechercher des objets" src="IMAGE/LAUNCHPAD.png" />

<table>
	<tr><th>Élément</th><th>Rôle</th></tr>
	<tr><td>Actions (petits boutons)</td><td><b>Verrouiller</b> : écran de verrouillage (fenêtre système modale qui capture la souris et le clavier ; mot de passe facultatif, OS2.INI LAUNCHPAD MOTDEPASSE) ; <b>Rechercher</b> : recherche de fichiers sur toutes les unités (masque avec * et ?), faite en arrière-plan quelques répertoires à la fois, un double clic ou Entrée ouvre le résultat ; <b>Arrêt</b> ; <b>Liste des fenêtres</b>.</td></tr>
	<tr><td>Objets (grands boutons)</td><td>Lecteur C:, Invite de commandes OS/2, Aide, Imprimante (file d'attente du spouleur PMSPL.DLL : travaux, annulation, « Imprimer... » un fichier par SplQmWriteFile).</td></tr>
	<tr><td>Tiroirs</td><td>La flèche au-dessus d'un objet ouvre son tiroir : Lecteurs et les autres unités ; Système OS/2 et Modèles ; Informations sur le système ; Imprimer un fichier...</td></tr>
	<tr><td>Ajouter, retirer</td><td>Sans limite : on dépose un objet du bureau ou d'un dossier sur la barre (sur un bouton : dans son tiroir), ou menu contextuel (bouton 2) : Ajouter un programme ou un dossier..., Retirer cet objet, Mot de passe de verrouillage..., Fermer le LaunchPad. Les objets sont gardés dans OS2.INI (application LAUNCHPAD).</td></tr>
	<tr><td>Aide et clavier</td><td>La souris immobile sur un bouton affiche son nom (bulle d'aide). Barre active : flèches gauche et droite, Entrée ou espace, flèche haut (tiroir), Échap.</td></tr>
</table>

Les dossiers, les programmes et les fichiers sont ouverts par le bureau : le LaunchPad écrit la demande dans OS2.INI (PMSHELL, REQ<i>n</i> : OPEN, DRIVES, SYS, TEMPL, CMD, RUN, BATCH, VIEW, WINLIST, HELP, INFO, SHUTDOWN) et poste WM_USER + 1 à la fenêtre du bureau (PMSHELL, HWND) ; un objet déposé par PMSHELL arrive par LAUNCHPAD, DEPOT et WM_USER + 1 à la barre.

Pour que deux programmes de PM partagent l'écran, PMWIN.DLL remet maintenant la souris et le clavier à la file de la fenêtre visée, même quand c'est un autre processus qui a lu l'événement (une touche pour un autre processus lui est mise en attente : ses crochets, accélérateurs et procédures sont appelés par lui), et une fenêtre qui se dessine fait redessiner les fenêtres des autres processus placées au-dessus d'elle. Deux corrections d'OS2PC ont aussi été nécessaires : l'instruction <code>F(x)^.champ := valeur</code> (fonction qui rend un pointeur) était compilée comme un simple appel, et <code>GetMem(Pointer(v), n)</code> rangeait le pointeur ailleurs que dans <code>v</code>.

<h3>Installation sur un disque dur (INSTALL.PAS, CD-ROM IMAGE/OS2INST.ISO)</h3>

Le fichier <b>INSTALL.PAS</b> est le programme OS/2 <b>INSTALL.EXE</b>, le programme d'installation graphique d'OS/2-0, à l'apparence de l'installation d'OS/2 Warp 3 (fenêtres de Presentation Manager sur fond turquoise). Le nouveau CD-ROM <b>IMAGE/OS2INST.ISO</b> contient les mêmes fichiers que <b>IMAGE/OS2CD.ISO</b>, avec le CONFIG.SYS de <b>IMAGE/INSTALL</b> (<code>PROTSHELL=C:\INSTALL.EXE</code>) : il démarre directement dans l'installation. Une fois OS/2-0 installé, l'ordinateur démarre du disque dur, sans CD-ROM, et la partition HPFS devient l'unité C:.

<img width="640" height="480" alt="OS/2-0 : installation, page Bienvenue" src="IMAGE/INSTALL_BIENVENUE.png" />
<img width="640" height="480" alt="OS/2-0 : installation, page Configuration du système (avec le choix de la langue)" src="IMAGE/INSTALL_CONFIG.png" />

<table>
	<tr><th>Étape</th><th>Rôle</th></tr>
	<tr><td>Bienvenue</td><td>Installation facile (premier disque dur : partition HPFS existante, ou tout l'espace libre ; choix par défaut) ou avancée ; Quitter redémarre l'ordinateur.</td></tr>
	<tr><td>Configuration du système</td><td>Le tableau de bord de Warp 3 : pays, clavier, <b>langue</b> (nouveau, français par défaut), souris, ports série, affichage principal (VGA 640 x 480 ou un mode VESA : <code>SET PMRESOLUTION=</code>), affichage secondaire, gestion de l'alimentation, PCMCIA, CD-ROM, imprimante, multimédia, SCSI. Un clic sur l'icône (ou le titre) d'un choix ouvre la liste de ses valeurs ; les champs à flèches changent de valeur. L'assistant change aussitôt de langue (français, anglais, allemand, espagnol, italien, albanais ; le portugais, le suédois, le danois et le japonais sont affichés en anglais), le pays et le clavier suivent.</td></tr>
	<tr><td>Partitionnement du disque dur</td><td>Comme FDISK : disques IDE (modèle, taille), partitions principales et espaces libres ; création d'une partition HPFS (07h) dont on donne la taille en Mo (alignée sur 1 Mo, après les 4 premiers Mo du disque), suppression (après confirmation), choix de la partition. La table est écrite au secteur 0 du disque.</td></tr>
	<tr><td>Formatage</td><td><b>HPFS</b> (choix par défaut, le système de fichiers d'OS/2, par HPFS.IFS : FS_FSCTL 8000h) ou <b>NTFS</b> (par NTFS.IFS : KrnDiskCtl 11 ; les fichiers se partagent alors facilement avec Windows et Linux), avec le nom du volume ; « Ne pas formater » garde les fichiers d'une partition HPFS ou NTFS existante (réinstallation). <code>SET INSTALL_FS=NTFS</code> dans le CONFIG.SYS du CD-ROM d'installation fait de NTFS le choix initial (et le choix de l'installation facile).</td></tr>
	<tr><td>Composants</td><td>Système de base et Presentation Manager (obligatoire), bureau et LaunchPad (sinon <code>PROTSHELL=C:\CMD.EXE</code>), utilitaires, programmes d'essai TEST*.EXE, disque virtuel de 4 Mo (les applications, dont celles des dossiers Science et Productivité, sont toujours installées), jeux (Solitaire - Klondike, Échecs, Mahjongg, Sudoku, Othello, TileMan, Hex 2048, Backgammon, Poker, Billard, Checkers, Yahtzee, Bataille navale, Puissance 4, Soko-Ban, Baccarat, Tours de Hanoï, Baby, 421, Mille-pattes, Astéroïde, Badugi, Tic-Tac-Toe, Baseball, Excavateur, Machine à boule, Barbu, Casse-Brique, Bataille, Invasion de l'espace, FreeCell, Commandement des missiles, L25, Bubble Shooter, BlackJack, Blox, Golf, Grenouille, Bonhomme pendu, Lights, Alunissage, Boston, Cannonball, Bingo, Craps, Roulette, Xiangqi, Le Plombier, Tic-Tac-Toe 3D, Patience) et loisirs (Astromancie, Onirologie et son récit d'exemple REVE.TXT), multimédia (Audio numérique, Lecteur MP3 et son morceau d'exemple, Notator for OS2-Zero et ses exemples, MDM.DLL, pilotes des cartes son, sons), réseau TCP/IP (TCPIP32.DLL, E1000.DLL, PCNET.DLL, IFCONFIG, IPCONFIG, PING, HOST, WGET, CURL, Outlink) ; espace nécessaire et espace disponible.</td></tr>
	<tr><td>Transfert des fichiers</td><td>Barre de progression aux logos OS/2, fichier courant ; copie des fichiers du CD-ROM, création de C:\DESKTOP et C:\AIDE, CONFIG.SYS du disque dur (<code>IFS=C:\HPFS.IFS /CACHE:64 /AUTOCHECK:C</code>, <code>SET LANGUAGE=</code>, <code>COUNTRY=</code>, <code>DEVINFO=KBD,...</code>, <code>SET PMRESOLUTION=</code>...), zone d'amorçage et secteur d'amorce principal.</td></tr>
	<tr><td>Fin</td><td>Retirer le CD-ROM puis Redémarrer (les tampons des volumes sont vidés, puis remise à zéro par le contrôleur du clavier).</td></tr>
</table>

<img width="640" height="480" alt="OS/2-0 : installation, partitionnement du disque dur" src="IMAGE/INSTALL_DISQUE.png" />
<img width="640" height="480" alt="OS/2-0 : installation, transfert des fichiers" src="IMAGE/INSTALL_COPIE.png" />

Démarrage du disque dur : le secteur d'amorce principal (<b>KERNEL/HDBOOT.ASM</b>, assemblé une fois et recopié dans le tableau MbrCode de INSTALL.PAS) cherche la partition active, lit le répertoire de la <b>zone d'amorçage</b> (secteur 1 du disque : <code>OS20BOOT</code>, puis des entrées nom, LBA, taille) et charge OS2LDR en 2000:0000 ; la zone d'amorçage (secteurs 1 à 8191, avant la première partition) contient OS2LDR, OS2KRNL et HPFS.IFS. OS2LDR lit alors des secteurs de 512 octets au lieu de 2048, charge le noyau et recopie HPFS.IFS en 00600000h ; le bloc d'information d'amorçage reçoit <code>'HD'</code> (+34h), le début de la partition active (+38h) et l'adresse de HPFS.IFS (+40h). Le noyau charge ce pilote depuis la mémoire, monte la partition active en <b>C:</b> (HPFS), puis lit C:\CONFIG.SYS et les DLL sur le disque ; le lecteur de CD-ROM n'est plus nécessaire. Nouvelle API du noyau <b>KrnDiskCtl</b> (disques IDE : description, lecture et écriture de secteurs, formatage et montage d'une partition, démontage, vidage des tampons, redémarrage) et <b>SetEnvironmentVariableA</b> (environnement du système).

<pre>qemu-img create -f raw disque.img 300M
qemu-system-i386 -m 64 -cdrom IMAGE/OS2INST.ISO -hda disque.img -boot d
qemu-system-i386 -m 64 -hda disque.img</pre>

<h3>Écran de démarrage graphique</h3>

Au démarrage du disque dur, les messages du noyau ne défilent plus à la console : OS2KRNL passe aussitôt en 640 × 480 × 16 couleurs (mode 12h du BIOS) et montre la boîte <b>Démarrage d'OS/2-0</b>, avec le logo d'OS/2 Zero, la liste des étapes et une progression faite de cercles. Chaque étape terminée est cochée en vert, une flèche et le gras désignent l'étape en cours, et les cercles se remplissent d'une étape à l'autre, ainsi qu'à chaque module (DLL, pilote IFS) chargé. La boîte reste à l'écran jusqu'à ce que Presentation Manager le prenne.

<img width="640" height="480" alt="OS/2-0 : l'écran de démarrage (logo, étapes cochées, progression en cercles)" src="IMAGE/DEMARRAGE.png" />

<table>
	<tr><th>Étape</th><th>Travail du noyau</th></tr>
	<tr><td>Mémoire, processeur et vidéo</td><td>Relevé des modes VESA (INT 10h, 4F00h/4F01h).</td></tr>
	<tr><td>Disques durs et lecteur de CD-ROM</td><td>Contrôleurs IDE et lecteur ATAPI.</td></tr>
	<tr><td>Partition d'amorçage (HPFS ou NTFS)</td><td>Pilote IFS chargé par OS2LDR, partitions, montage de C:.</td></tr>
	<tr><td>Configuration (CONFIG.SYS)</td><td>Lecture de C:\CONFIG.SYS.</td></tr>
	<tr><td>Bibliothèques du système</td><td>DOSCALLS.DLL.</td></tr>
	<tr><td>Systèmes de fichiers installés</td><td>Lignes <code>IFS=</code>, autres volumes, disque virtuel.</td></tr>
	<tr><td>Presentation Manager</td><td>Chargement du processeur de commandes (PMSHELL.EXE) et de ses DLL : un cercle par module.</td></tr>
	<tr><td>Bureau (Workplace Shell)</td><td>Démarrage du bureau, jusqu'à la première file de messages de PM.</td></tr>
</table>

Le journal reste complet : les messages vont toujours au port série et dans l'écran texte de la session 0, dont les pages B8000h sont redirigées vers son tampon pendant que la carte est en mode graphique. <b>Échap</b> ramène la console texte avec tout le journal ; une erreur du noyau (<code>SYS…</code>, <code>OS2KRNL:</code>), une exception, un programme en mode texte qui lit le clavier (PROTSHELL=C:\CMD.EXE) ou un processeur de commandes qui se termine avant PM font de même. <code>SET BOOTSCREEN=TEXTE</code> dans CONFIG.SYS garde la console. Le dessin se fait dans un tampon d'un octet par point, recopié plan par plan dans la mémoire de la carte VGA, zones modifiées seulement. Le logo (128 × 172 points, palette de 16 couleurs programmée dans le DAC) est dans <b>KERNEL/LOGO.INC</b>, produit par <b>TOOLS/MKLOGO.PY</b> à partir de <b>IMAGE/LOGO_OS2ZERO.png</b>. VIOCALLS.DLL, chargée pendant l'écran de démarrage, ne lit plus l'état d'origine du VGA (police, palette, registres) sur la carte, alors en mode graphique, mais dans l'état du mode texte que le noyau a relevé juste avant (<code>KrnVideo</code> 6) : le bureau garde sa police et les sessions plein écran leurs couleurs.

Langue : la variable <code>LANGUAGE</code> de CONFIG.SYS (convention commune avec MSDOS-0, Pasdows95...) vaut <code>FR</code> (français, par défaut), <code>EN</code> (anglais), <code>GR</code> (allemand), <code>SP</code> (espagnol), <code>IT</code> (italien), <code>ALB</code> ou <code>SQ</code> (albanais, shqip), <code>PT</code> ou <code>PRT</code> (portugais), <code>SE</code> ou <code>SWE</code> (suédois), <code>DK</code> ou <code>DNK</code> (danois), <code>JP</code> ou <code>JPN</code> (japonais en romaji) ; <code>ES</code> est aussi accepté pour l'espagnol. Après l'installation, elle se change dans <b>Système OS/2 → Configuration du système → Langue</b> (onglet Langue du carnet Système - Paramètres) : la ligne <code>SET LANGUAGE=</code> de C:\CONFIG.SYS est modifiée et l'environnement du système aussi (les programmes lancés ensuite, comme CMD.EXE et les commandes, utilisent la nouvelle langue).

<img width="640" height="480" alt="OS/2-0 : onglet Langue du carnet Système - Paramètres" src="IMAGE/LANGUE.png" />

Le CD-ROM amorçable <b>IMAGE/OS2CD.ISO</b> contient OS2BOOT, OS2LDR, OS2KRNL, CONFIG.SYS, DOSCALLS.DLL, FKA.DLL, HPFS.IFS, VIOCALLS.DLL, MOUCALLS.DLL, NLS.DLL, KBDCALLS.DLL, MONCALLS.DLL, MSG.DLL, NAMPIPES.DLL, SESMGR.DLL, QUECALLS.DLL, SPOOLCP.DLL, RMINFO.DLL, OS2SM.DLL, HELPMGR.DLL, LIBUNI.DLL, PMDRAG.DLL, PMWIN.DLL, PMGPI.DLL, PMMERGE.DLL, PMPIC.DLL, PMSHAPI.DLL, PMSPL.DLL, PMVIOP.DLL, API16.DLL, PMWP.DLL, PMCTLS.DLL, MDM.DLL, SBAUDIO.DLL, ICHAUDIO.DLL, ESAUDIO.DLL, VBOXGST.DLL, VMWTOOLS.DLL, TCPIP32.DLL, TLS32.DLL, NTFS.IFS, E1000.DLL, PCNET.DLL, CMD.EXE, PMSHELL.EXE, LAUNCHPD.EXE, INSTALL.EXE, KLONDIKE.EXE, ECHECS.EXE, MAHJONGG.EXE, DIGAUDIO.EXE, MP3PLAY.EXE, ASTROMAN.EXE, REVES.EXE, REVE.TXT, ASTRO.EXE, SIMUPLAN.EXE, CS3DA.EXE, HUMAN.C3D, PHYSIO.CFG, ELEMENTS.EXE, CHEMDRAW.EXE, DEVMGR.EXE, TASKMGR.EXE, BROWSER.EXE, IFCONFIG.EXE, IPCONFIG.EXE, PING.EXE, HOST.EXE, WGET.EXE, CURL.EXE, DEMARRE.WAV, CLOCHE.WAV, AURORE.MP3, TESTDOS.EXE, TESTFKA.EXE, TESTHPFS.EXE, TESTVIO.EXE, TESTMOU.EXE, TESTNLS.EXE, TESTKBD.EXE, TESTMON.EXE, TESTMSG.EXE, TESTNMP.EXE, TESTSES.EXE, TESTQUE.EXE, TESTPFS.EXE, TESTRM.EXE, TESTSM.EXE, TESTHLP.EXE, TESTUNI.EXE, TESTDRG.EXE, TESTWIN.EXE, TESTGPI.EXE, TESTMRG.EXE, TESTPIC.EXE, TESTSHA.EXE, TESTSPL.EXE, TESTVIOP.EXE, TESTMDM.EXE, TESTVDM.EXE et les commandes du dépôt compilées avec OS2PC. Il se fabrique avec <b>TOOLS/MAKEISO.PAS</b> (ISO 9660 + El Torito) ; le script <b>KERNEL/BUILD.sh</b> (ou <b>KERNEL/BUILD.BAT</b>) reconstruit le tout :

<pre>KERNEL/BUILD.sh
qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d</pre>

Le même script fabrique aussi le CD-ROM d'installation <b>IMAGE/OS2INST.ISO</b>.

Pour essayer HPFS sur un disque dur, ajouter une image disque dont une partition est de type 07h (<code>-hda disque.img</code>) : formatée HPFS, elle devient l'unité D: (le disque virtuel passe à E:).

Voir <a href="IMAGE/LISEZMOI.TXT">IMAGE/LISEZMOI.TXT</a> pour les détails (carte mémoire, CONFIG.SYS, limites).

<h2>Compilation</h2>
	
Les fichiers Pascal n'ont aucune dépendances, il suffit de télécharger le fichier désiré et de le compiler avec Free Pascal avec la syntaxe de commande  :

<pre><b>fpc</b> <i>LEFICHIER.PAS</i></pre>
	
Sinon, vous pouvez également le compiler avec le Turbo Pascal à l'aide de la syntaxe de commande suivante :	

<pre><b>tpc</b> <i>LEFICHIER.PAS</i></pre>
	
Par exemple, si vous voulez compiler CMD.PAS, vous devrez tapez la commande suivante :

<pre><b>fpc</b> CMD.PAS</pre>

<h2>Licence</h2>
<ul>
 <li>Le code source est publié sous la licence <a href="https://github.com/gladir/OS2-0/blob/main/LICENSE">MIT</a>.</li>
 <li>Le paquet original est publié sous la licence <a href="https://github.com/gladir/OS2-0/blob/main/LICENSE">MIT</a>.</li>
</ul>
