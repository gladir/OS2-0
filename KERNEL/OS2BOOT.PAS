{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2BOOT)
  @description: Secteur d'amorce OS/2-0 pour CD-ROM (El Torito, sans
                emulation). Charge OS2LDR et lui passe le controle.
}

Program OS2BOOT;

{ Compilation : OS2PC -COS2BOOT OS2BOOT.PAS   (produit le fichier OS2BOOT)

  Le BIOS charge cette image en 0000:7C00 (le compilateur la resout pour
  le segment 07C0h) et lui passe le numero de l'unite CD-ROM dans DL
  (disponible ici dans PrefixSeg). OS2BOOT :

    1. lit le descripteur de volume primaire ISO 9660 (secteur 16) ;
    2. parcourt le repertoire racine a la recherche de OS2LDR ;
    3. charge OS2LDR en 2000:0000 (INT 13h etendue, secteurs de 2 Ko) ;
    4. depose le bloc d'information d'amorcage en 0000:0500 :
         +0  mot  : 'OB' (signature 424Fh)
         +2  octet: unite d'amorcage (DL du BIOS)
         +3  octet: reserve
         +4  mot double : LBA du repertoire racine
         +8  mot double : taille du repertoire racine (octets)
         +12 mot double : LBA de OS2LDR
         +16 mot double : taille de OS2LDR
    5. saute en 2000:0000 avec DL = unite d'amorcage.

  Comme sous OS/2, le chargeur OS2LDR est place au segment 2000h. }

{$S-,R-,I-}

Const
  BufSeg    = $1000;          { tampon de lecture des secteurs (10000h) }
  LdrSeg    = $2000;          { OS2LDR est charge en 2000:0000          }
  InfoOfs   = $0500;          { bloc d'information d'amorcage (0:0500)  }
  LdrName   = 'OS2LDR';

Type
  TDap = Record               { paquet d'adresse disque (INT 13h AH=42h) }
    Size   : Byte;
    Res    : Byte;
    Count  : Word;
    BufOfs : Word;
    BufSg  : Word;
    LbaLo  : LongInt;
    LbaHi  : LongInt;
  End;

Var
  BootDrive  : Byte;
  Dap        : TDap;
  RootLba    : LongInt;
  RootSize   : LongInt;
  FileLba    : LongInt;
  FileSize   : LongInt;
  Found      : Boolean;

{ Afficher un caractere par le BIOS video (teletype) }
Procedure PutC(C : Char);
Var X : Byte;
Begin
  X := Ord(C);
  asm
    mov ah,0Eh
    mov al,X
    mov bx,7
    int 10h
  end;
End;

Procedure PutS(Const S : String);
Var I : Integer;
Begin
  For I := 1 To Length(S) Do PutC(S[I]);
End;

{ Message d'erreur fatale : attendre une touche puis redemarrer }
Procedure Fatal(Const S : String);
Begin
  PutS(#13#10'OS2BOOT: ');
  PutS(S);
  PutS(#13#10'Appuyez sur une touche pour redemarrer.');
  asm
    xor ah,ah
    int 16h
    int 19h
  end;
End;

{ Lire un secteur de 2048 octets (LBA) en Seg:0000 ; vrai si succes }
Function ReadSector(Lba : LongInt; BSeg : Word) : Boolean;
Var Drv, Err, Tries : Byte;
Begin
  Tries := 0;
  Repeat
    Dap.Size := 16; Dap.Res := 0; Dap.Count := 1;
    Dap.BufOfs := 0; Dap.BufSg := BSeg;
    Dap.LbaLo := Lba; Dap.LbaHi := 0;
    Drv := BootDrive;
    asm
      mov ah,42h
      mov dl,Drv
      lea si,Dap
      int 13h
      mov al,0
      adc al,0
      mov Err,al
    end;
    If Err = 0 Then
    Begin
      ReadSector := True;
      Exit;
    End;
    { reinitialiser l'unite et recommencer }
    asm
      xor ah,ah
      mov dl,Drv
      int 13h
    end;
    Inc(Tries);
  Until Tries >= 3;
  ReadSector := False;
End;

{ Mot double little-endian en Seg:Ofs }
Function GetD(Seg, Ofs : Word) : LongInt;
Begin
  GetD := LongInt(MemW[Seg:Ofs]) + LongInt(MemW[Seg:Ofs + 2]) * 65536;
End;

{ Comparer l'identificateur d'un enregistrement de repertoire (Ofs) au nom
  cherche : "OS2LDR", "OS2LDR." ou "OS2LDR.;1" sont acceptes }
Function NameMatch(Ofs : Word; Const Name : String) : Boolean;
Var Len, I : Integer; C : Char;
Begin
  NameMatch := False;
  Len := Mem[BufSeg:Ofs + 32];
  If Len < Length(Name) Then Exit;
  For I := 1 To Length(Name) Do
    If UpCase(Chr(Mem[BufSeg:Ofs + 32 + I])) <> Name[I] Then Exit;
  If Len > Length(Name) Then
  Begin
    C := Chr(Mem[BufSeg:Ofs + 33 + Length(Name)]);
    If (C <> '.') And (C <> ';') Then Exit;
  End;
  NameMatch := True;
End;

{ Chercher Name dans le repertoire racine }
Procedure FindFile(Const Name : String);
Var Sector, NSect : LongInt; Ofs, RecLen : Word;
Begin
  Found := False;
  NSect := (RootSize + 2047) Div 2048;
  Sector := 0;
  While (Sector < NSect) And Not Found Do
  Begin
    If Not ReadSector(RootLba + Sector, BufSeg) Then Fatal('erreur de lecture du repertoire');
    Ofs := 0;
    While Ofs < 2048 Do
    Begin
      RecLen := Mem[BufSeg:Ofs];
      If RecLen = 0 Then Ofs := 2048   { fin des enregistrements du secteur }
      Else
      Begin
        If (Mem[BufSeg:Ofs + 25] And 2) = 0 Then
          If NameMatch(Ofs, Name) Then
          Begin
            FileLba := GetD(BufSeg, Ofs + 2);
            FileSize := GetD(BufSeg, Ofs + 10);
            Found := True;
            Ofs := 2048;
          End;
        Ofs := Ofs + RecLen;
      End;
    End;
    Inc(Sector);
  End;
End;

{ Verifier la presence des extensions INT 13h }
Function HasExtensions : Boolean;
Var Drv, Ok : Byte;
Begin
  Drv := BootDrive;
  asm
    mov ah,41h
    mov bx,55AAh
    mov dl,Drv
    int 13h
    mov al,0
    jc @no
    cmp bx,0AA55h
    jne @no
    mov al,1
  @no:
    mov Ok,al
  end;
  HasExtensions := Ok <> 0;
End;

Var
  LSeg     : Word;
  Sector   : LongInt;
  NSect    : LongInt;

BEGIN
  BootDrive := Lo(PrefixSeg);
  PutS('OS/2-0 ');
  If Not HasExtensions Then Fatal('INT 13h etendue absente');
  { descripteur de volume primaire }
  If Not ReadSector(16, BufSeg) Then Fatal('erreur de lecture du CD-ROM');
  If (Mem[BufSeg:0] <> 1) Or (Mem[BufSeg:1] <> Ord('C')) Or
     (Mem[BufSeg:2] <> Ord('D')) Then Fatal('CD-ROM non ISO 9660');
  RootLba := GetD(BufSeg, 156 + 2);
  RootSize := GetD(BufSeg, 156 + 10);
  { recherche et chargement de OS2LDR }
  FindFile(LdrName);
  If Not Found Then Fatal('OS2LDR introuvable');
  NSect := (FileSize + 2047) Div 2048;
  If NSect > 31 * 4 Then Fatal('OS2LDR trop grand');
  LSeg := LdrSeg;
  Sector := 0;
  While Sector < NSect Do
  Begin
    If Not ReadSector(FileLba + Sector, LSeg) Then Fatal('erreur de lecture de OS2LDR');
    LSeg := LSeg + 2048 Div 16;
    Inc(Sector);
  End;
  { bloc d'information d'amorcage }
  MemW[0:InfoOfs] := $424F;
  Mem[0:InfoOfs + 2] := BootDrive;
  Mem[0:InfoOfs + 3] := 0;
  MemW[0:InfoOfs + 4] := Word(RootLba);
  MemW[0:InfoOfs + 6] := Word(RootLba Shr 16);
  MemW[0:InfoOfs + 8] := Word(RootSize);
  MemW[0:InfoOfs + 10] := Word(RootSize Shr 16);
  MemW[0:InfoOfs + 12] := Word(FileLba);
  MemW[0:InfoOfs + 14] := Word(FileLba Shr 16);
  MemW[0:InfoOfs + 16] := Word(FileSize);
  MemW[0:InfoOfs + 18] := Word(FileSize Shr 16);
  { passer le controle a OS2LDR (2000:0000) }
  asm
    mov dl,BootDrive
    xor dh,dh
    db 0EAh
    dw 0
    dw 2000h
  end;
END.
