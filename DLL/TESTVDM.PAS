{ =======================================================================
  TESTVDM.PAS - OS/2-0 : programme d'essai de la machine virtuelle DOS

  Programme MS-DOS 16 bits (compile par OS2PC -CD TESTVDM.PAS) execute
  dans une session DOS d'OS/2-0 (mode virtuel 8086) : il verifie les
  services du DOS (version, fichiers, recherche, memoire, PSP), du BIOS
  (video, clavier, horloge, zone de donnees), de la souris (INT 33h), de
  la memoire etendue XMS (INT 2Fh 4300h), de la memoire paginee EMS
  (INT 67h : allocation, projection dans le cadre E000h) et la presence
  du serveur DPMI (INT 2Fh 1687h).

  Utilisation : TESTVDM (dans l'invite de commandes OS/2 ou une session
  DOS) ; derniere ligne : TESTVDM : n reussi(s), m echec(s).
  ======================================================================= }

Program TestVdm;

Uses Dos;

Var
  R : Registers;
  Ok, Ko : Integer;
  Buf, Buf2 : Array[0..1023] Of Byte;
  I, H, BSeg, Max : Word;
  Name : String;
  T0, T1 : LongInt;
  Same : Boolean;

Procedure Check(Cond : Boolean; Msg : String);
Begin
  If Cond Then
  Begin
    Inc(Ok);
    WriteLn('  ok    ', Msg);
  End
  Else
  Begin
    Inc(Ko);
    WriteLn('  ECHEC ', Msg);
  End;
End;

Function CF : Boolean;
Begin
  CF := (R.Flags And 1) <> 0;
End;

Procedure SetName(S : String);
Begin
  Name := S + #0;
End;

Begin
  Ok := 0; Ko := 0;
  WriteLn('TESTVDM : machine virtuelle DOS d''OS/2-0');

  { DOS : version }
  R.AX := $3000; MsDos(R);
  Check((R.AL = 5) And (R.AH = 0), 'INT 21h 30h : DOS 5.00');
  R.AX := $3306; MsDos(R);
  Check(R.BL = 5, 'INT 21h 3306h : version vraie 5');
  R.AH := $19; MsDos(R);
  Check(R.AL < 26, 'INT 21h 19h : unite courante');
  R.AH := $62; MsDos(R);
  Check((R.BX = PrefixSeg) And (MemW[R.BX:0] = $20CD), 'INT 21h 62h : PSP (INT 20h en tete)');
  Check(MemW[PrefixSeg:$2C] <> 0, 'PSP : segment de l''environnement');

  { fichiers : creer, ecrire, relire, taille, supprimer (D:) }
  For I := 0 To 1023 Do Buf[I] := I And 255;
  SetName('D:\VDMTEST.TMP');
  R.AH := $3C; R.CX := 0; R.DS := Seg(Name); R.DX := Ofs(Name) + 1; MsDos(R);
  Check(Not CF, 'INT 21h 3Ch : creation de D:\VDMTEST.TMP');
  H := R.AX;
  R.AH := $40; R.BX := H; R.CX := 1000; R.DS := Seg(Buf); R.DX := Ofs(Buf); MsDos(R);
  Check((Not CF) And (R.AX = 1000), 'INT 21h 40h : ecriture de 1000 octets');
  R.AH := $3E; R.BX := H; MsDos(R);
  Check(Not CF, 'INT 21h 3Eh : fermeture');
  R.AX := $3D00; R.DS := Seg(Name); R.DX := Ofs(Name) + 1; MsDos(R);
  Check(Not CF, 'INT 21h 3Dh : ouverture en lecture');
  H := R.AX;
  R.AX := $4202; R.BX := H; R.CX := 0; R.DX := 0; MsDos(R);
  Check((Not CF) And (R.AX = 1000) And (R.DX = 0), 'INT 21h 4202h : taille 1000');
  R.AX := $4200; R.BX := H; R.CX := 0; R.DX := 0; MsDos(R);
  FillChar(Buf2, SizeOf(Buf2), 0);
  R.AH := $3F; R.BX := H; R.CX := 1024; R.DS := Seg(Buf2); R.DX := Ofs(Buf2); MsDos(R);
  Same := (Not CF) And (R.AX = 1000);
  For I := 0 To 999 Do If Buf2[I] <> Buf[I] Then Same := False;
  Check(Same, 'INT 21h 3Fh : relecture identique');
  R.AH := $3E; R.BX := H; MsDos(R);
  R.AH := $41; R.DS := Seg(Name); R.DX := Ofs(Name) + 1; MsDos(R);
  Check(Not CF, 'INT 21h 41h : suppression');
  R.AX := $3D00; R.DS := Seg(Name); R.DX := Ofs(Name) + 1; MsDos(R);
  Check(CF And (R.AX = 2), 'INT 21h 3Dh : fichier supprime introuvable (2)');

  { recherche de fichiers (DTA du PSP) }
  SetName('C:\*.EXE');
  R.AH := $4E; R.CX := 0; R.DS := Seg(Name); R.DX := Ofs(Name) + 1; MsDos(R);
  Check(Not CF, 'INT 21h 4Eh : C:\*.EXE');
  R.AH := $4F; MsDos(R);
  Check(Not CF, 'INT 21h 4Fh : fichier suivant');

  { memoire du DOS : blocs (MCB) ; le programme rend d'abord 128 Ko de
    son bloc (le tas l'occupe en entier) }
  Max := MemW[PrefixSeg - 1:3];
  R.AH := $4A; R.ES := PrefixSeg; R.BX := Max - $2000; MsDos(R);
  Check(Not CF, 'INT 21h 4Ah : bloc du programme reduit');
  R.AH := $48; R.BX := $FFFF; MsDos(R);
  Max := R.BX;
  Check(CF And (R.AX = 8) And (Max > $1000), 'INT 21h 48h : plus grand bloc libre');
  R.AH := $48; R.BX := $100; MsDos(R);
  BSeg := R.AX;
  Check(Not CF, 'INT 21h 48h : bloc de 4 Ko');
  Mem[BSeg:0] := $5A; Mem[BSeg:$FFF] := $A5;
  Check((Mem[BSeg:0] = $5A) And (Mem[BSeg:$FFF] = $A5), 'bloc : ecriture et lecture');
  R.AH := $49; R.ES := BSeg; MsDos(R);
  Check(Not CF, 'INT 21h 49h : liberation');

  { BIOS }
  R.AH := $0F; Intr($10, R);
  Check(((R.AL And $7F) = 3) And (R.AH = 80), 'INT 10h 0Fh : mode texte 3, 80 colonnes');
  Check(MemW[$40:$4A] = 80, 'BDA : 80 colonnes');
  R.AH := $01; Intr($16, R);
  Check((R.Flags And $40) <> 0, 'INT 16h 01h : tampon du clavier vide');
  R.AH := $00; Intr($1A, R);
  T0 := (LongInt(R.CX) Shl 16) Or R.DX;
  For I := 1 To 30000 Do
  Begin
    R.AH := $00; Intr($1A, R);
    T1 := (LongInt(R.CX) Shl 16) Or R.DX;
    If T1 >= T0 + 3 Then Break;
  End;
  Check(T1 >= T0 + 3, 'INT 1Ah 00h : l''horloge avance');
  R.AX := 0; Intr($11, R);
  Check(R.AX <> 0, 'INT 11h : equipement');
  R.AX := 0; Intr($12, R);
  Check(R.AX = 640, 'INT 12h : 640 Ko');

  { souris }
  R.AX := 0; Intr($33, R);
  Check((R.AX = $FFFF) And (R.BX = 2), 'INT 33h 00h : souris a deux boutons');

  { XMS }
  R.AX := $4300; Intr($2F, R);
  Check(R.AL = $80, 'INT 2Fh 4300h : pilote XMS');
  R.AX := $4310; Intr($2F, R);
  Check(R.ES = $F000, 'INT 2Fh 4310h : point d''entree XMS');

  { EMS : pilote, cadre, allocation et projection }
  R.AH := $40; Intr($67, R);
  Check(R.AH = 0, 'INT 67h 40h : EMS pret');
  R.AH := $41; Intr($67, R);
  Check((R.AH = 0) And (R.BX = $E000), 'INT 67h 41h : cadre en E000h');
  R.AH := $42; Intr($67, R);
  Check((R.AH = 0) And (R.BX >= 4), 'INT 67h 42h : pages libres');
  R.AH := $43; R.BX := 2; Intr($67, R);
  Check(R.AH = 0, 'INT 67h 43h : 2 pages allouees');
  H := R.DX;
  R.AX := $4400; R.BX := 0; R.DX := H; Intr($67, R);
  Mem[$E000:0] := $3C; Mem[$E000:$3FFF] := $C3;
  R.AX := $4400; R.BX := 1; R.DX := H; Intr($67, R);
  Mem[$E000:0] := $77;
  R.AX := $4400; R.BX := 0; R.DX := H; Intr($67, R);
  Check((R.AH = 0) And (Mem[$E000:0] = $3C) And (Mem[$E000:$3FFF] = $C3),
        'INT 67h 44h : projection des pages logiques');
  R.AH := $45; R.DX := H; Intr($67, R);
  Check(R.AH = 0, 'INT 67h 45h : liberation');

  { DPMI }
  R.AX := $1687; Intr($2F, R);
  Check((R.AX = 0) And (R.CL >= 3), 'INT 2Fh 1687h : serveur DPMI');

  WriteLn('TESTVDM : ', Ok, ' reussi(s), ', Ko, ' echec(s).');
End.
