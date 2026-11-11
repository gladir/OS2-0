#!/bin/bash
# BUILD.sh - Construit OS/2-0 et le CD-ROM amorcable IMAGE/OS2CD.ISO
#
#  1. compile les outils avec Free Pascal : TOOLS/OS2PC.PAS (OS/2 Pascal
#     Compiler) et TOOLS/MAKEISO.PAS ;
#  2. compile le noyau avec OS2PC :
#        OS2PC -COS2BOOT OS2BOOT.PAS   -> OS2BOOT  (secteur d'amorce El Torito)
#        OS2PC -COS2LDR  OS2LDR.PAS    -> OS2LDR   (chargeur 16 -> 32 bits)
#        OS2PC -COS2KRNL OS2KRNL.PAS   -> OS2KRNL  (noyau 32 bits)
#  3. compile CMD.PAS et les commandes de la racine du depot (OS2PC -COS2) ;
#  4. compile les bibliotheques DLL/DOSCALLS.PAS (DOSCALLS.DLL),
#     DLL/FKA.PAS (FKA.DLL), DLL/HPFS.PAS (HPFS.IFS, systeme de
#     fichiers installable), DLL/VIOCALLS.PAS (VIOCALLS.DLL, video) et
#     DLL/MOUCALLS.PAS (MOUCALLS.DLL, souris), DLL/NLS.PAS (NLS.DLL,
#     langues nationales), DLL/KBDCALLS.PAS (KBDCALLS.DLL, clavier) et
#     DLL/MONCALLS.PAS (MONCALLS.DLL, moniteurs de peripheriques),
#     DLL/MSG.PAS (MSG.DLL, messages), DLL/NAMPIPES.PAS (NAMPIPES.DLL,
#     tuyaux nommes), DLL/SESMGR.PAS (SESMGR.DLL, sessions),
#     DLL/QUECALLS.PAS (QUECALLS.DLL, files d'attente) et leurs
#     programmes d'essai TESTDOS, TESTFKA, TESTHPFS, TESTVIO, TESTMOU,
#     TESTNLS, TESTKBD, TESTMON, TESTMSG, TESTNMP, TESTSES et TESTQUE ;
#  5. fabrique le CD-ROM : MAKEISO OS2CD.ISO /BOOT:OS2BOOT ...
#
# Variables : FPC (compilateur Free Pascal, defaut fpc), W (dossier de
# travail, defaut BUILD a la racine du depot).
# Test : qemu-system-i386 -m 64 -cdrom IMAGE/OS2CD.ISO -boot d
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
  if "$W/os2pc" -Q "$F" "$W/cd/$B.EXE" > "$W/$B.log" 2>&1 && [ -f "$W/cd/$B.EXE" ]; then
    echo "   $B.EXE"
  else
    echo "   $B : echec (voir $W/$B.log)"
    rm -f "$W/cd/$B.EXE"
  fi
done
echo "== Bibliotheques DOSCALLS.DLL, FKA.DLL, HPFS.IFS, VIOCALLS.DLL, MOUCALLS.DLL, NLS.DLL, KBDCALLS.DLL, MONCALLS.DLL, MSG.DLL, NAMPIPES.DLL, SESMGR.DLL et QUECALLS.DLL (OS2PC, Library)"
"$W/os2pc" -Q "$ROOT/DLL/DOSCALLS.PAS" "$W/cd/DOSCALLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTDOS.PAS" "$W/cd/TESTDOS.EXE"
"$W/os2pc" -Q "$ROOT/DLL/FKA.PAS" "$W/cd/FKA.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTFKA.PAS" "$W/cd/TESTFKA.EXE"
"$W/os2pc" -Q "$ROOT/DLL/HPFS.PAS" "$W/cd/HPFS.IFS"
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
cp "$ROOT/IMAGE/SYSTEM/CONFIG.SYS" "$W/cd/CONFIG.SYS"

echo "== CD-ROM amorcable"
"$W/makeiso" "$ROOT/IMAGE/OS2CD.ISO" /BOOT:"$W/cd/OS2BOOT" /LABEL:OS2_0 "$W/cd/*"
for F in OS2BOOT OS2LDR OS2KRNL CMD.EXE DOSCALLS.DLL FKA.DLL HPFS.IFS VIOCALLS.DLL MOUCALLS.DLL NLS.DLL KBDCALLS.DLL MONCALLS.DLL MSG.DLL NAMPIPES.DLL SESMGR.DLL QUECALLS.DLL; do cp "$W/cd/$F" "$ROOT/IMAGE/SYSTEM/$F"; done
echo "Termine : $ROOT/IMAGE/OS2CD.ISO"
