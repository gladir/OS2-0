#!/bin/bash
# BUILD.sh - Construit OS/2-0 et le CD-ROM amorcable IMAGE/OS2CD.ISO
#
#  1. compile les outils avec Free Pascal : TOOLS/OS2PC.PAS (OS/2 Pascal
#     Compiler) et TOOLS/MAKEISO.PAS ;
#  2. compile le noyau avec OS2PC :
#        OS2PC -COS2BOOT OS2BOOT.PAS   -> OS2BOOT  (secteur d'amorce El Torito)
#        OS2PC -COS2LDR  OS2LDR.PAS    -> OS2LDR   (chargeur 16 -> 32 bits)
#        OS2PC -COS2KRNL OS2KRNL.PAS   -> OS2KRNL  (noyau 32 bits)
#     (OS2KRNL.PAS inclut LOGO.INC, le logo de l'ecran de demarrage,
#     produit par TOOLS/MKLOGO.PY depuis IMAGE/LOGO_OS2ZERO.png) ;
#  3. compile CMD.PAS et les commandes de la racine du depot (OS2PC -COS2) ;
#     dont les jeux du dossier Jeux du bureau : KLONDIKE.PAS (Solitaire -
#     Klondike), ECHECS.PAS (Echecs), MAHJONGG.PAS (Mahjongg Solitaire) et
#     SUDOKU.PAS (Sudoku), OTHELLO.PAS (Othello), TILEMAN.PAS (TileMan),
#     HEX2048.PAS (Hex 2048), BACKGAM.PAS (Backgammon), POKER.PAS (Poker),
#     BILLARD.PAS (Billard), CHECKERS.PAS (Checkers), YATHZEE.PAS (Yahtzee),
#     BATTLE.PAS (Bataille navale, en cinq langues), POWER4.PAS (Puissance 4),
#     SOKOBAN.PAS (Soko-Ban), BACCARAT.PAS (Baccarat), HANOIS.PAS (Tours de
#     Hanoi), BABY.PAS (Baby, sauvetage de bebes), 421.PAS (421, des),
#     CENTIPED.PAS (Mille-pattes), ASTEROID.PAS (Asteroide), BADUGI.PAS
#     (Badugi, poker coreen), TTT.PAS (Tic-Tac-Toe), BASEBALL.PAS (Baseball),
#     EXCAVAT.PAS (Excavateur), PINBALL.PAS (Pinball : tables et sons dans le
#     programme), BARBU.PAS (Barbu), BREAKOUT.PAS (Casse-Brique),
#     BATAILLE.PAS (Bataille), INVADERS.PAS (Invasion de l'espace),
#     FREECELL.PAS (FreeCell), MISSILE.PAS (Commandement des missiles),
#     L25.PAS (L25, parcours du cavalier), BUBBLE.PAS (Bubble Shooter, porte
#     du prototype BS.PAS de 7iles), BLACKJAK.PAS (BlackJack), BLOX.PAS
#     (Blox), GOLF.PAS (Golf, cartes), FROGGER.PAS (Grenouille), HANGMAN.PAS
#     (Bonhomme pendu), LIGHTS.PAS (Lights), LUNAR.PAS (Alunissage), BOSTON.PAS
#     (Boston), CANNONBA.PAS (Cannonball), BINGO.PAS (Bingo), CRAPS.PAS (Craps),
#     ROULETTE.PAS (Roulette), XIANGQI.PAS (Xiangqi), TTT3D.PAS (Tic-Tac-Toe
#     3D), PATIENCE.PAS (Patience), et
#     DIGAUDIO.PAS (Audio numerique, dossier Multimedia), MP3PLAY.PAS
#     (Lecteur MP3 : decodeur, liste de lecture et egaliseur dans le meme
#     fichier, dossier Multimedia ; son exemple IMAGE/MUSIQUE/*.MP3 est
#     copie sur le CD-ROM), NOTATOR.PAS
#     (Notator for OS2-Zero, sequenceur et editeur de partition porte de
#     NOTATOR.PAS du depot OFFICE-0, dossier Multimedia ; ses exemples de
#     IMAGE/NOTATOR, .SON et .MID, sont copies sur le CD-ROM), TASKMGR.PAS
#     (Gestionnaire des taches, dossier Systeme OS/2) et BROWSER.PAS
#     (Navigateur Web : HTML, CSS, JavaScript, codes QR, outils F12 ;
#     bureau et dossier Systeme OS/2), PASDEV.PAS (Pascal Developer,
#     environnement de developpement du dossier Developer Kit), GETSRC.PAS
#     (Telecharger le code source d'OS2-Zero depuis GitHub, dossier
#     Developer Kit), CALC.PAS
#     (Calculatrice portee de Pasdows 95, dossier Productivite) et
#     EXPLORER.PAS (Explorateur OS2-Zero, porte de l'Explorateur Pasdows :
#     dossier Productivite et menu contextuel du bureau) et OUTLINK.PAS
#     (Outlink, client de messagerie porte de OUTLOOK.PAS du depot
#     OFFICE-0 : IMAP, POP3 et SMTP par TCPIP32.DLL, TLS et STARTTLS par
#     TLS32.DLL ; dossier Productivite) et WORDIUM.PAS (WorDium, traitement
#     de texte porte de WORD.PAS du depot OFFICE-0 : DOCX, DOC, PDF, GAT du
#     MonsterBook, correcteur d'orthographe ; dossier Productivite) et
#     EXCELSIO.PAS (Excelsior, tableur porte de EXCEL.PAS du depot
#     OFFICE-0 : XLC, XLS, XLSX, formules, graphiques ; dossier
#     Productivite) ;
#  3a. compile APPS/PAINT.PAS (Paint, porte de Pasdows 95, dossier
#     Productivite) avec OS2PC, qui accepte les AnsiString, Int64, QWord,
#     PByte, tableaux dynamiques, types proceduraux et Try/Except de Free
#     Pascal qu'utilise PAINT ;
#  3c. compile APPS/ASTROMAN.PAS (Astromancie, interpretation de
#     l'astrologie) et APPS/REVES.PAS (Onirologie, interpretation des
#     reves), portes du depot Mystix (dossier Loisirs du bureau) ;
#  3d. compile APPS/ASTRO.PAS (Astronomie) et APPS/SIMUPLAN.PAS
#     (Simulateur de planete) du depot Axtro, APPS/CS3DA.PAS (Anatomie 3D
#     du systeme circulatoire, donnees APPS/HUMAN.C3D et APPS/PHYSIO.CFG)
#     du depot BIOLOGIE-0, APPS/ELEMENTS.PAS (Table des elements) et
#     APPS/CHEMDRAW.PAS (Dessin de chimie) du depot QCHIMIE (dossier
#     Science du bureau) ;
#  3e. compile APPS/MAXIMIZE.PAS (Maximilien CRM), APPS/SIMPLY.PAS
#     (Sample Accounting), APPS/ACROBAT.PAS (Acrodoc), APPS/NEWS.PAS
#     (News Master) et APPS/POWERPNT.PAS (PresentPoint) du depot OFFICE-0
#     et APPS/NOTEPAD.PAS (Bloc-notes de Pasdows 95) (dossier Productivite
#     du bureau), APPS/OS2DBG.PAS (OS2-Zero Debugger, dossier Developer
#     Kit) ;
#  3b. compile OS2PC.PAS avec OS2PC lui-meme : OS2PC.EXE, le compilateur
#     natif d'OS/2-0 qu'utilise Pascal Developer ; les exemples de
#     IMAGE/EXEMPLES (BONJOUR.PAS, HELLO.PAS, PAYSAGE.BMP pour Paint,
#     MONSTER.GAT et LETTRE.PDF pour WorDium, BUDGET.XLC pour Excelsior,
#     REVE.TXT pour Onirologie)
#     sont copies sur le CD-ROM ;
#  4. compile les bibliotheques DLL/DOSCALLS.PAS (DOSCALLS.DLL),
#     DLL/FKA.PAS (FKA.DLL), DLL/NTFS.PAS (NTFS.IFS, NTFS en lecture, ecriture
#     et formatage, porte de Pasdows 95), DLL/HPFS.PAS (HPFS.IFS, systeme de
#     fichiers installable), DLL/VIOCALLS.PAS (VIOCALLS.DLL, video) et
#     DLL/MOUCALLS.PAS (MOUCALLS.DLL, souris), DLL/NLS.PAS (NLS.DLL,
#     langues nationales), DLL/KBDCALLS.PAS (KBDCALLS.DLL, clavier) et
#     DLL/MONCALLS.PAS (MONCALLS.DLL, moniteurs de peripheriques),
#     DLL/MSG.PAS (MSG.DLL, messages), DLL/NAMPIPES.PAS (NAMPIPES.DLL,
#     tuyaux nommes), DLL/SESMGR.PAS (SESMGR.DLL, sessions),
#     DLL/QUECALLS.PAS (QUECALLS.DLL, files d'attente), DLL/SPOOLCP.PAS
#     (SPOOLCP.DLL, polices des imprimantes), DLL/RMINFO.PAS (RMINFO.DLL,
#     gestionnaire de ressources), DLL/OS2SM.PAS (OS2SM.DLL, liste des
#     taches), DLL/HELPMGR.PAS (HELPMGR.DLL, aide IPF), DLL/LIBUNI.PAS
#     (LIBUNI.DLL, Unicode et locales), DLL/PMDRAG.PAS (PMDRAG.DLL,
#     glisser-deposer), DLL/PMWIN.PAS (PMWIN.DLL, gestionnaire de
#     fenetres de PM), DLL/PMGPI.PAS (PMGPI.DLL, interface graphique
#     GPI de PM), DLL/PMMERGE.PAS (PMMERGE.DLL, PM fusionne de Warp 4),
#     DLL/PMPIC.PAS (PMPIC.DLL, impression et conversion d'images),
#     DLL/PMSHAPI.PAS (PMSHAPI.DLL, interface de l'interpreteur de PM),
#     DLL/PMSPL.PAS (PMSPL.DLL, tampon d'impression de PM),
#     DLL/PMVIOP.PAS (PMVIOP.DLL, bouclier VIO : fenetres OS/2),
#     DLL/API16.PAS (API16.DLL, fonctions des programmes 16 bits d'OS/2 1.x),
#     DLL/PMWP.PAS (PMWP.DLL, objets du Workplace Shell), DLL/PMCTLS.PAS
#     (PMCTLS.DLL, dialogues standard Fichier et Police),
#     DLL/MDM.PAS (MDM.DLL, multimedia MMPM/2 : MCI, son numerique),
#     DLL/OPENGL.PAS (OPENGL.DLL, OpenGL 1.1 logiciel porte de Pasdows 95,
#     interface PGL d'OS/2 ; exemple APPS/GLTEST.PAS, Essai OpenGL) et
#     les pilotes des cartes son DLL/SBAUDIO.PAS (Sound Blaster),
#     DLL/ICHAUDIO.PAS (AC'97 Intel ICH) et DLL/ESAUDIO.PAS (Ensoniq
#     AudioPCI), DLL/VBOXGST.PAS (VBOXGST.DLL, Additions VirtualBox :
#     souris integree, taille de l'ecran), DLL/VMWTOOLS.PAS (VMWTOOLS.DLL,
#     VMware Tools : souris vmmouse, Resolution_Set), DLL/TCPIP32.PAS (TCPIP32.DLL,
#     pile TCP/IP), DLL/TLS32.PAS (TLS32.DLL, TLS 1.3/1.2 pour https://), DLL/SMB.PAS
#     (SMB.IFS, lecteurs reseau Windows et Samba : SMB2, NTLMv2, signature ;
#     DosFSAttach, NET USE, Explorateur OS2-Zero) et les pilotes reseau DLL/E1000.PAS (Intel PRO/1000)
#     et DLL/PCNET.PAS (AMD PCnet), et leurs programmes d'essai TESTDOS, TESTFKA,
#     TESTHPFS, TESTVIO, TESTMOU, TESTNLS, TESTKBD, TESTMON, TESTMSG,
#     TESTNMP, TESTSES, TESTQUE, TESTPFS, TESTRM, TESTSM, TESTHLP,
#     TESTUNI, TESTDRG, TESTWIN, TESTGPI, TESTMRG, TESTPIC, TESTSHA,
#     TESTSPL, TESTVIOP et TESTMDM, et TESTVDM (programme MS-DOS 16 bits
#     de la session DOS, OS2PC -CD) ; les sons de IMAGE/SONS (WAV) sont
#     copies sur le CD-ROM ;
#  5. fabrique le CD-ROM : MAKEISO OS2CD.ISO /BOOT:OS2BOOT ... ;
#  6. fabrique le CD-ROM d'installation IMAGE/OS2INST.ISO : memes fichiers,
#     CONFIG.SYS de IMAGE/INSTALL (PROTSHELL=C:\INSTALL.EXE : INSTALL.PAS,
#     programme d'installation graphique sur un disque dur).
#     KERNEL/HDBOOT.ASM (MBR du disque dur) est deja assemble dans
#     INSTALL.PAS (tableau MbrCode : nasm -f bin HDBOOT.ASM).
#
# Variables : FPC (compilateur Free Pascal, defaut fpc), W (dossier de
# travail, defaut BUILD a la racine du depot).
# Test : qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d
# Installation : qemu-img create -f raw disque.img 300M, puis
#   qemu-system-i386 -m 64 -cdrom IMAGE/OS2INST.ISO -hda disque.img -boot d
# et ensuite (demarrage du disque dur) : qemu-system-i386 -m 64 -hda disque.img
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
FPC=${FPC:-fpc}
W=${W:-$ROOT/BUILD}
mkdir -p "$W/obj" "$W/cd"

echo "== Outils (Free Pascal)"
"$FPC" -O1 -FU"$W/obj" -o"$W/os2pc" "$ROOT/TOOLS/OS2PC.PAS" > "$W/os2pc.log" || { cat "$W/os2pc.log"; exit 1; }
"$FPC" -FU"$W/obj" -o"$W/makeiso" "$ROOT/TOOLS/MAKEISO.PAS" > "$W/makeiso.log" || { cat "$W/makeiso.log"; exit 1; }

echo "== Noyau (OS2PC)"
"$W/os2pc" -COS2BOOT "$HERE/OS2BOOT.PAS" "$W/cd/OS2BOOT"
"$W/os2pc" -COS2LDR "$HERE/OS2LDR.PAS" "$W/cd/OS2LDR"
"$W/os2pc" -COS2KRNL "$HERE/OS2KRNL.PAS" "$W/cd/OS2KRNL"

echo "== Commandes (OS2PC -COS2)"
for F in "$ROOT"/*.PAS; do
  B=$(basename "$F" .PAS)
  # nom 8.3 sur le CD-ROM (ISO 9660 niveau 1)
  O=$B; [ "$B" = LAUNCHPAD ] && O=LAUNCHPD
  if "$W/os2pc" -Q "$F" "$W/cd/$O.EXE" > "$W/$B.log" 2>&1 && [ -f "$W/cd/$O.EXE" ]; then
    echo "   $O.EXE"
  else
    echo "   $B : echec (voir $W/$B.log)"
    rm -f "$W/cd/$O.EXE"
  fi
done

echo "== Paint (OS2PC : APPS/PAINT.PAS, porte de Pasdows 95)"
"$W/os2pc" -Q "$ROOT/APPS/PAINT.PAS" "$W/cd/PAINT.EXE" > "$W/PAINT.log" 2>&1 || { cat "$W/PAINT.log"; exit 1; }
echo "   PAINT.EXE"
echo "== Loisirs (OS2PC : APPS/ASTROMAN.PAS et APPS/REVES.PAS, portes du depot Mystix)"
for B in ASTROMAN REVES; do
  "$W/os2pc" -Q "$ROOT/APPS/$B.PAS" "$W/cd/$B.EXE" > "$W/$B.log" 2>&1 || { cat "$W/$B.log"; exit 1; }
  echo "   $B.EXE"
done
echo "== Science (OS2PC : APPS/ASTRO.PAS, SIMUPLAN.PAS, CS3DA.PAS, ELEMENTS.PAS et CHEMDRAW.PAS)"
for B in ASTRO SIMUPLAN CS3DA ELEMENTS CHEMDRAW; do
  "$W/os2pc" -Q "$ROOT/APPS/$B.PAS" "$W/cd/$B.EXE" > "$W/$B.log" 2>&1 || { cat "$W/$B.log"; exit 1; }
  echo "   $B.EXE"
done
# modele du corps humain et physiologie de l'Anatomie 3D (a cote de CS3DA.EXE)
cp "$ROOT/APPS/HUMAN.C3D" "$ROOT/APPS/PHYSIO.CFG" "$W/cd/"
echo "== Productivite et Developer Kit (OS2PC : APPS/MAXIMIZE.PAS, SIMPLY.PAS, ACROBAT.PAS, NEWS.PAS, POWERPNT.PAS, NOTEPAD.PAS et OS2DBG.PAS)"
for B in MAXIMIZE SIMPLY ACROBAT NEWS POWERPNT NOTEPAD OS2DBG; do
  "$W/os2pc" -Q "$ROOT/APPS/$B.PAS" "$W/cd/$B.EXE" > "$W/$B.log" 2>&1 || { cat "$W/$B.log"; exit 1; }
  echo "   $B.EXE"
done
echo "== OS2PC.EXE (compilateur natif : OS2PC.PAS compile par OS2PC) et exemples de Pascal Developer"
"$W/os2pc" -Q "$ROOT/TOOLS/OS2PC.PAS" "$W/cd/OS2PC.EXE"
cp "$ROOT"/IMAGE/EXEMPLES/*.PAS "$W/cd/"
cp "$ROOT"/IMAGE/EXEMPLES/*.BMP "$W/cd/"
cp "$ROOT"/IMAGE/EXEMPLES/*.GAT "$ROOT"/IMAGE/EXEMPLES/*.PDF "$ROOT"/IMAGE/EXEMPLES/*.XLC "$W/cd/"
# exemple de recit de reve pour Onirologie (REVES REVE.TXT)
cp "$ROOT"/IMAGE/EXEMPLES/REVE.TXT "$W/cd/"
echo "== Bibliotheques DOSCALLS.DLL, FKA.DLL, HPFS.IFS, NTFS.IFS, VIOCALLS.DLL, MOUCALLS.DLL, NLS.DLL, KBDCALLS.DLL, MONCALLS.DLL, MSG.DLL, NAMPIPES.DLL, SESMGR.DLL, QUECALLS.DLL, SPOOLCP.DLL, RMINFO.DLL, OS2SM.DLL, HELPMGR.DLL, LIBUNI.DLL, PMDRAG.DLL, PMWIN.DLL, PMGPI.DLL, PMMERGE.DLL, PMPIC.DLL, PMSHAPI.DLL, PMSPL.DLL, PMVIOP.DLL, API16.DLL, PMWP.DLL et PMCTLS.DLL (OS2PC, Library)"
"$W/os2pc" -Q "$ROOT/DLL/DOSCALLS.PAS" "$W/cd/DOSCALLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTDOS.PAS" "$W/cd/TESTDOS.EXE"
"$W/os2pc" -Q "$ROOT/DLL/FKA.PAS" "$W/cd/FKA.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTFKA.PAS" "$W/cd/TESTFKA.EXE"
"$W/os2pc" -Q "$ROOT/DLL/HPFS.PAS" "$W/cd/HPFS.IFS"
"$W/os2pc" -Q "$ROOT/DLL/NTFS.PAS" "$W/cd/NTFS.IFS"
"$W/os2pc" -Q "$ROOT/DLL/TESTNTFS.PAS" "$W/cd/TESTNTFS.EXE"
"$W/os2pc" -Q "$ROOT/DLL/TESTHPFS.PAS" "$W/cd/TESTHPFS.EXE"
"$W/os2pc" -Q "$ROOT/DLL/VIOCALLS.PAS" "$W/cd/VIOCALLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTVIOR.PAS" "$W/cd/TESTVIOR.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTVIO.PAS" "$W/cd/TESTVIO.EXE"
"$W/os2pc" -Q "$ROOT/DLL/MOUCALLS.PAS" "$W/cd/MOUCALLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTMOU.PAS" "$W/cd/TESTMOU.EXE"
"$W/os2pc" -Q "$ROOT/DLL/NLS.PAS" "$W/cd/NLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTNLS.PAS" "$W/cd/TESTNLS.EXE"
"$W/os2pc" -Q "$ROOT/DLL/KBDCALLS.PAS" "$W/cd/KBDCALLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTKBD.PAS" "$W/cd/TESTKBD.EXE"
"$W/os2pc" -Q "$ROOT/DLL/MONCALLS.PAS" "$W/cd/MONCALLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTMON.PAS" "$W/cd/TESTMON.EXE"
"$W/os2pc" -Q "$ROOT/DLL/MSG.PAS" "$W/cd/MSG.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTMSG.PAS" "$W/cd/TESTMSG.EXE"
"$W/os2pc" -Q "$ROOT/DLL/NAMPIPES.PAS" "$W/cd/NAMPIPES.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTNMP.PAS" "$W/cd/TESTNMP.EXE"
"$W/os2pc" -Q "$ROOT/DLL/SESMGR.PAS" "$W/cd/SESMGR.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTSES.PAS" "$W/cd/TESTSES.EXE"
"$W/os2pc" -Q "$ROOT/DLL/QUECALLS.PAS" "$W/cd/QUECALLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTQUE.PAS" "$W/cd/TESTQUE.EXE"
"$W/os2pc" -Q "$ROOT/DLL/SPOOLCP.PAS" "$W/cd/SPOOLCP.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTPFS.PAS" "$W/cd/TESTPFS.EXE"
"$W/os2pc" -Q "$ROOT/DLL/RMINFO.PAS" "$W/cd/RMINFO.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTRM.PAS" "$W/cd/TESTRM.EXE"
"$W/os2pc" -Q "$ROOT/DLL/OS2SM.PAS" "$W/cd/OS2SM.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTSM.PAS" "$W/cd/TESTSM.EXE"
"$W/os2pc" -Q "$ROOT/DLL/HELPMGR.PAS" "$W/cd/HELPMGR.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTHLP.PAS" "$W/cd/TESTHLP.EXE"
"$W/os2pc" -Q "$ROOT/DLL/LIBUNI.PAS" "$W/cd/LIBUNI.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTUNI.PAS" "$W/cd/TESTUNI.EXE"
"$W/os2pc" -Q "$ROOT/DLL/PMDRAG.PAS" "$W/cd/PMDRAG.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTDRG.PAS" "$W/cd/TESTDRG.EXE"
"$W/os2pc" -Q "$ROOT/DLL/PMWIN.PAS" "$W/cd/PMWIN.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTWIN.PAS" "$W/cd/TESTWIN.EXE"
"$W/os2pc" -Q "$ROOT/DLL/PMGPI.PAS" "$W/cd/PMGPI.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTGPI.PAS" "$W/cd/TESTGPI.EXE"
"$W/os2pc" -Q "$ROOT/DLL/PMMERGE.PAS" "$W/cd/PMMERGE.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTMRG.PAS" "$W/cd/TESTMRG.EXE"
"$W/os2pc" -Q "$ROOT/DLL/PMPIC.PAS" "$W/cd/PMPIC.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTPIC.PAS" "$W/cd/TESTPIC.EXE"
"$W/os2pc" -Q "$ROOT/DLL/PMSHAPI.PAS" "$W/cd/PMSHAPI.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTSHA.PAS" "$W/cd/TESTSHA.EXE"
"$W/os2pc" -Q "$ROOT/DLL/PMSPL.PAS" "$W/cd/PMSPL.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTSPL.PAS" "$W/cd/TESTSPL.EXE"
"$W/os2pc" -Q "$ROOT/DLL/PMVIOP.PAS" "$W/cd/PMVIOP.DLL"
"$W/os2pc" -Q "$ROOT/DLL/API16.PAS" "$W/cd/API16.DLL"
"$W/os2pc" -Q "$ROOT/DLL/PMWP.PAS" "$W/cd/PMWP.DLL"
"$W/os2pc" -Q "$ROOT/DLL/PMCTLS.PAS" "$W/cd/PMCTLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTVIOP.PAS" "$W/cd/TESTVIOP.EXE"
echo "== VirtualBox (VBOXGST.DLL), VMware (VMWTOOLS.DLL) et reseau : TCPIP32.DLL, TLS32.DLL (https), pilotes E1000.DLL et PCNET.DLL"
for B in VBOXGST VMWTOOLS TCPIP32 TLS32 E1000 PCNET; do "$W/os2pc" -Q "$ROOT/DLL/$B.PAS" "$W/cd/$B.DLL"; done
echo "== Lecteurs reseau : SMB.IFS (client SMB2 des partages Windows et Samba)"
"$W/os2pc" -Q "$ROOT/DLL/SMB.PAS" "$W/cd/SMB.IFS"
echo "== Multimedia : MDM.DLL et pilotes SBAUDIO.DLL, ICHAUDIO.DLL, ESAUDIO.DLL"
for B in MDM SBAUDIO ICHAUDIO ESAUDIO; do "$W/os2pc" -Q "$ROOT/DLL/$B.PAS" "$W/cd/$B.DLL"; done
"$W/os2pc" -Q "$ROOT/DLL/TESTMDM.PAS" "$W/cd/TESTMDM.EXE"
echo "== OpenGL : OPENGL.DLL (OpenGL 1.1 logiciel, interface PGL) et GLTEST.EXE (Essai OpenGL, dossier Multimedia)"
"$W/os2pc" -Q "$ROOT/DLL/OPENGL.PAS" "$W/cd/OPENGL.DLL"
"$W/os2pc" -Q "$ROOT/APPS/GLTEST.PAS" "$W/cd/GLTEST.EXE"
echo "== Outils reseau (OS2PC : APPS/FTPCLI.PAS, Client FTP et SFTP, APPS/SSHCLI.PAS, Client SSH, et APPS/MSTSC.PAS, Connexion Bureau a distance, portes de Pasdows 95)"
"$W/os2pc" -Q "$ROOT/APPS/FTPCLI.PAS" "$W/cd/FTPCLI.EXE"
"$W/os2pc" -Q "$ROOT/APPS/SSHCLI.PAS" "$W/cd/SSHCLI.EXE"
"$W/os2pc" -Q "$ROOT/APPS/MSTSC.PAS" "$W/cd/MSTSC.EXE"
echo "== Virtualisation (OS2PC : APPS/VIRTUAL.PAS, machines de VirtualBox par AMD-V, Intel VT-x ou mode V86, KrnVirt du noyau)"
"$W/os2pc" -Q "$ROOT/APPS/VIRTUAL.PAS" "$W/cd/VIRTUAL.EXE"
echo "== Session DOS : TESTVDM.EXE (programme MS-DOS 16 bits, OS2PC -CD)"
"$W/os2pc" -Q -CD "$ROOT/DLL/TESTVDM.PAS" "$W/cd/TESTVDM.EXE"
cp "$ROOT"/IMAGE/SONS/*.WAV "$W/cd/"
cp "$ROOT"/IMAGE/MUSIQUE/*.MP3 "$W/cd/"
cp "$ROOT"/IMAGE/NOTATOR/*.SON "$ROOT"/IMAGE/NOTATOR/*.MID "$ROOT"/IMAGE/NOTATOR/NOTATOR.TXT "$W/cd/"
cp "$ROOT/IMAGE/SYSTEM/CONFIG.SYS" "$W/cd/CONFIG.SYS"

echo "== CD-ROM amorcable"
"$W/makeiso" "$ROOT/IMAGE/OS2CD.ISO" /BOOT:"$W/cd/OS2BOOT" /LABEL:OS2_0 "$W/cd/*"
for F in OS2BOOT OS2LDR OS2KRNL CMD.EXE PMSHELL.EXE LAUNCHPD.EXE DOSCALLS.DLL FKA.DLL HPFS.IFS NTFS.IFS SMB.IFS OPENGL.DLL VIOCALLS.DLL MOUCALLS.DLL NLS.DLL KBDCALLS.DLL MONCALLS.DLL MSG.DLL NAMPIPES.DLL SESMGR.DLL QUECALLS.DLL SPOOLCP.DLL RMINFO.DLL OS2SM.DLL HELPMGR.DLL LIBUNI.DLL PMDRAG.DLL PMWIN.DLL PMGPI.DLL PMMERGE.DLL PMPIC.DLL PMSHAPI.DLL PMSPL.DLL PMVIOP.DLL API16.DLL PMWP.DLL PMCTLS.DLL MDM.DLL SBAUDIO.DLL ICHAUDIO.DLL ESAUDIO.DLL VBOXGST.DLL VMWTOOLS.DLL TCPIP32.DLL TLS32.DLL E1000.DLL PCNET.DLL; do cp "$W/cd/$F" "$ROOT/IMAGE/SYSTEM/$F"; done
echo "== CD-ROM d'installation"
rm -rf "$W/cdinst"; mkdir -p "$W/cdinst"
cp "$W/cd/"* "$W/cdinst/"
cp "$ROOT/IMAGE/INSTALL/CONFIG.SYS" "$W/cdinst/CONFIG.SYS"
"$W/makeiso" "$ROOT/IMAGE/OS2INST.ISO" /BOOT:"$W/cdinst/OS2BOOT" /LABEL:OS2_0_INSTALL "$W/cdinst/*"
echo "Termine : $ROOT/IMAGE/OS2CD.ISO et $ROOT/IMAGE/OS2INST.ISO"
