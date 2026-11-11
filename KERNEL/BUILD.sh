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
#  4. compile la bibliotheque DLL/DOSCALLS.PAS (DOSCALLS.DLL) et son
#     programme d'essai DLL/TESTDOS.PAS ;
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
echo "== Bibliotheque DOSCALLS.DLL (OS2PC, Library)"
"$W/os2pc" -Q "$ROOT/DLL/DOSCALLS.PAS" "$W/cd/DOSCALLS.DLL"
"$W/os2pc" -Q "$ROOT/DLL/TESTDOS.PAS" "$W/cd/TESTDOS.EXE"
cp "$ROOT/IMAGE/SYSTEM/CONFIG.SYS" "$W/cd/CONFIG.SYS"

echo "== CD-ROM amorcable"
"$W/makeiso" "$ROOT/IMAGE/OS2CD.ISO" /BOOT:"$W/cd/OS2BOOT" /LABEL:OS2_0 "$W/cd/*"
for F in OS2BOOT OS2LDR OS2KRNL CMD.EXE DOSCALLS.DLL; do cp "$W/cd/$F" "$ROOT/IMAGE/SYSTEM/$F"; done
echo "Termine : $ROOT/IMAGE/OS2CD.ISO"
