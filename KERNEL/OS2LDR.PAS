{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2LDR)
  @description: Chargeur OS/2-0 (OS2LDR) : charge le noyau 32 bits
                OS2KRNL a 1 Mo puis passe en mode protege.
}

Program OS2LDR;

{ Compilation : OS2PC -COS2LDR OS2LDR.PAS   (produit le fichier OS2LDR)

  OS2BOOT charge cette image en 2000:0000 (comme le vrai OS2LDR d'OS/2)
  et lui laisse en 0000:0500 le bloc d'information d'amorcage (unite,
  repertoire racine du CD-ROM). OS2LDR, en mode reel :

    1. cherche OS2KRNL dans le repertoire racine ISO 9660 ;
    2. lit le fichier secteur par secteur (INT 13h etendue) et le recopie
       dans une zone de transit en memoire etendue (00400000h) par
       INT 15h/87h ;
    3. analyse l'en-tete PE du noyau (base 00100000h) et recopie les
       en-tetes et chaque section a son adresse virtuelle (memoire
       physique : la pagination n'est pas encore active), la partie non
       initialisee est mise a zero ;
    4. releve la carte memoire (INT 15h E820h, E801h ou 88h) ;
    5. active la ligne A20, installe une GDT plate (08h code 32 bits,
       10h donnees 32 bits), passe en mode protege et saute au point
       d'entree du noyau (pile 00090000h).

  Bloc d'information d'amorcage (0000:0500), complete par OS2LDR :
    +00 mot  'OB'           +02 octet unite      +04 LBA racine
    +08 taille racine       +0C LBA OS2LDR       +10 taille OS2LDR
    +14 memoire etendue (Ko au-dela de 1 Mo)
    +18 nombre d'entrees E820 (table de 24 octets par entree en 0:0600)
    +1C base du noyau       +20 taille de l'image  +24 point d'entree
    +28 ligne du curseur    +29 colonne du curseur
    +2C LBA OS2KRNL         +30 taille OS2KRNL
    +34 'HD' (4448h) : demarrage d'un disque dur (ecrit par le MBR)
    +38 debut de la partition d'amorcage  +3C sa taille (secteurs)
    +40 adresse de HPFS.IFS charge en memoire  +44 sa taille
  GDT temporaire en 0000:0A00, GDTR en 0000:0A20, code de transition
  32 bits en 0000:0A40.

  Demarrage d'un disque dur (installe par INSTALL.EXE) : le MBR d'OS/2-0
  (KERNEL/HDBOOT.ASM) charge OS2LDR depuis la zone d'amorcage (secteurs 1
  et suivants du disque, avant la premiere partition) et met 'HD' en +34.
  OS2LDR y lit alors des secteurs de 512 octets : repertoire au secteur
  1 ('OS20BOOT', nombre d'entrees, puis des entrees de 32 octets en +16 :
  nom ASCIIZ de 16 octets, LBA, taille), OS2KRNL, et HPFS.IFS qu'il
  recopie en 00600000h pour que le noyau puisse monter C: (partition HPFS
  active) avant de lire ses fichiers. }

{$S-,R-,I-}

Const
  BufSeg    = $3000;          { tampon des secteurs du CD-ROM (30000h)  }
  HdrSeg    = $3800;          { copie des en-tetes PE (38000h)          }
  ZeroSeg   = $4000;          { 32 Ko de zeros (40000h)                 }
  Staging   = $00400000;      { zone de transit du fichier OS2KRNL      }
  IfsAddr   = $00600000;      { HPFS.IFS (demarrage d'un disque dur)    }
  Info      = $0500;
  E820Tab   = $0600;
  E820Max   = 40;
  GdtOfs    = $0A00;
  GdtrOfs   = $0A20;
  TrampOfs  = $0A40;
  KrnlName  = 'OS2KRNL';

Type
  TDap = Record
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
  { table de descripteurs pour INT 15h/87h (48 octets) }
  MoveGdt    : Array[0..47] Of Byte;
  E820Buf    : Array[0..23] Of Byte;
  ContVal    : LongInt;       { valeur de continuation E820 (EBX) }
  HdMode     : Boolean;       { demarrage d'un disque dur (zone d'amorcage) }
  SecSize    : LongInt;       { 2048 (CD-ROM) ou 512 (disque dur) }

{ ------------------------------------------------------------------ }
{ Affichage par le BIOS                                              }
{ ------------------------------------------------------------------ }

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

Procedure PutHex(V : LongInt; Digits : Integer);
Const Hx : String[16] = '0123456789ABCDEF';
Var I : Integer; Sh : Integer;
Begin
  For I := Digits - 1 DownTo 0 Do
  Begin
    Sh := I * 4;
    PutC(Hx[((V Shr Sh) And 15) + 1]);
  End;
End;

Procedure Fatal(Const S : String);
Begin
  PutS(#13#10'OS2LDR: ');
  PutS(S);
  PutS(#13#10'Le systeme est arrete.');
  asm
    cli
  @h:
    hlt
    jmp @h
  end;
End;

{ ------------------------------------------------------------------ }
{ Lecture du CD-ROM (INT 13h etendue, secteurs de 2048 octets)       }
{ ------------------------------------------------------------------ }

Function ReadSectors(Lba : LongInt; Count : Word; BSeg : Word) : Boolean;
Var Drv, Err, Tries : Byte;
Begin
  Tries := 0;
  Repeat
    Dap.Size := 16; Dap.Res := 0; Dap.Count := Count;
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
      ReadSectors := True;
      Exit;
    End;
    asm
      xor ah,ah
      mov dl,Drv
      int 13h
    end;
    Inc(Tries);
  Until Tries >= 3;
  ReadSectors := False;
End;

Function ReadSector(Lba : LongInt; BSeg : Word) : Boolean;
Begin
  ReadSector := ReadSectors(Lba, 1, BSeg);
End;

Function GetD(Sg, Ofs : Word) : LongInt;
Begin
  GetD := LongInt(MemW[Sg:Ofs]) + LongInt(MemW[Sg:Ofs + 2]) * 65536;
End;

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

{ repertoire de la zone d'amorcage d'un disque dur (secteur RootLba) }
Procedure FindBootFile(Const Name : String);
Var E, I : Integer; Ok : Boolean;
Begin
  Found := False;
  If Not ReadSector(RootLba, BufSeg) Then Fatal('erreur de lecture de la zone d''amorcage');
  If (Mem[BufSeg:0] <> Ord('O')) Or (Mem[BufSeg:1] <> Ord('S')) Or (Mem[BufSeg:2] <> Ord('2')) Or
     (Mem[BufSeg:3] <> Ord('0')) Then Fatal('zone d''amorcage invalide');
  For E := 0 To MemW[BufSeg:8] - 1 Do
    If (Not Found) And (E < 15) Then
    Begin
      Ok := True;
      For I := 1 To Length(Name) Do
        If UpCase(Chr(Mem[BufSeg:16 + E * 32 + I - 1])) <> Name[I] Then Ok := False;
      If Ok And (Mem[BufSeg:16 + E * 32 + Length(Name)] = 0) Then
      Begin
        FileLba := GetD(BufSeg, 16 + E * 32 + 16);
        FileSize := GetD(BufSeg, 16 + E * 32 + 20);
        Found := True;
      End;
    End;
End;

Procedure FindFile(Const Name : String);
Var Sector, NSect : LongInt; Ofs, RecLen : Word;
Begin
  If HdMode Then
  Begin
    FindBootFile(Name);
    Exit;
  End;
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
      If RecLen = 0 Then Ofs := 2048
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

{ ------------------------------------------------------------------ }
{ Copie vers / depuis la memoire etendue : INT 15h AH=87h            }
{ Src, Dst : adresses lineaires 32 bits ; Bytes pair, <= 65536       }
{ ------------------------------------------------------------------ }

Procedure SetDesc(Ofs : Integer; Base : LongInt);
Begin
  MoveGdt[Ofs] := $FF; MoveGdt[Ofs + 1] := $FF;          { limite 64 Ko }
  MoveGdt[Ofs + 2] := Base And $FF;
  MoveGdt[Ofs + 3] := (Base Shr 8) And $FF;
  MoveGdt[Ofs + 4] := (Base Shr 16) And $FF;
  MoveGdt[Ofs + 5] := $93;                                { donnees R/W }
  MoveGdt[Ofs + 6] := 0;
  MoveGdt[Ofs + 7] := (Base Shr 24) And $FF;
End;

Procedure ExtCopy(Src, Dst, Bytes : LongInt);
Var I : Integer; Words : Word; Err : Byte;
Begin
  For I := 0 To 47 Do MoveGdt[I] := 0;
  SetDesc(16, Src);
  SetDesc(24, Dst);
  Words := Word((Bytes + 1) Div 2);
  asm
    push es
    push ds
    pop es
    lea si,MoveGdt
    mov cx,Words
    mov ah,87h
    int 15h
    mov al,0
    adc al,0
    mov Err,al
    pop es
  end;
  If Err <> 0 Then Fatal('erreur INT 15h/87h (copie en memoire etendue)');
End;

{ Copie de grande taille par blocs de 32 Ko }
Procedure BigCopy(Src, Dst, Bytes : LongInt);
Var N : LongInt;
Begin
  While Bytes > 0 Do
  Begin
    If Bytes > 32768 Then N := 32768 Else N := Bytes;
    ExtCopy(Src, Dst, N);
    Src := Src + N; Dst := Dst + N; Bytes := Bytes - N;
  End;
End;

{ Mise a zero d une zone de la memoire etendue }
Procedure BigZero(Dst, Bytes : LongInt);
Var N : LongInt;
Begin
  While Bytes > 0 Do
  Begin
    If Bytes > 32768 Then N := 32768 Else N := Bytes;
    ExtCopy(LongInt(ZeroSeg) * 16, Dst, N);
    Dst := Dst + N; Bytes := Bytes - N;
  End;
End;

{ ------------------------------------------------------------------ }
{ Ligne A20                                                          }
{ ------------------------------------------------------------------ }

Procedure EnableA20;
Begin
  asm
    mov ax,2401h
    int 15h
    in al,92h
    or al,2
    and al,0FEh
    out 92h,al
  end;
End;

{ ------------------------------------------------------------------ }
{ Carte memoire                                                      }
{ ------------------------------------------------------------------ }

Procedure ReadMemoryMap;
Var
  Count : Integer; Ok : Byte; I : Integer;
  KbExt : LongInt; W1, W2 : Word;
Begin
  Count := 0;
  ContVal := 0;
  Repeat
    Ok := 0;
    asm
      push es
      push ds
      pop es
      lea di,E820Buf
      db 66h
      mov bx,word ptr ContVal
      db 66h
      mov ax,0E820h
      dw 0
      db 66h
      mov dx,4150h
      dw 534Dh
      db 66h
      mov cx,24
      dw 0
      int 15h
      jc @fin
      db 66h
      cmp ax,4150h
      dw 534Dh
      jne @fin
      mov Ok,1
      db 66h
      mov word ptr ContVal,bx
    @fin:
      pop es
    end;
    If Ok = 0 Then Break;
    For I := 0 To 23 Do Mem[0:E820Tab + Count * 24 + I] := E820Buf[I];
    Inc(Count);
  Until (ContVal = 0) Or (Count >= E820Max);
  MemW[0:Info + $18] := Count;
  MemW[0:Info + $1A] := 0;
  { taille de la memoire etendue (Ko au-dela de 1 Mo) : E801h sinon 88h }
  W1 := 0; W2 := 0; Ok := 0;
  asm
    mov ax,0E801h
    int 15h
    jc @no801
    or ax,ax
    jnz @use
    mov ax,cx
    mov bx,dx
  @use:
    mov W1,ax
    mov W2,bx
    mov Ok,1
  @no801:
  end;
  If Ok <> 0 Then
    KbExt := LongInt(W1) + LongInt(W2) * 64
  Else
  Begin
    asm
      mov ah,88h
      int 15h
      mov W1,ax
    end;
    KbExt := W1;
  End;
  MemW[0:Info + $14] := Word(KbExt);
  MemW[0:Info + $16] := Word(KbExt Shr 16);
End;

{ ------------------------------------------------------------------ }
{ Chargement de OS2KRNL                                              }
{ ------------------------------------------------------------------ }

Var
  KBase, KEntry, KImgSize, KHdrSize : LongInt;
  PeOfs, SectOfs : Word;
  NSect, OptSize, I : Integer;
  VSize, VAddr, RawSize, RawPtr, N : LongInt;
  Sector, NSectors : LongInt;
  Row, Col : Byte;

{ fichier FileLba / FileSize -> memoire etendue (blocs de 32 Ko) }
Procedure ReadFileTo(Dst : LongInt; Const What : String);
Var N : Word;
Begin
  NSectors := (FileSize + SecSize - 1) Div SecSize;
  Sector := 0;
  While Sector < NSectors Do
  Begin
    N := 32768 Div SecSize;
    If NSectors - Sector < N Then N := NSectors - Sector;
    If Not ReadSectors(FileLba + Sector, N, BufSeg) Then Fatal('erreur de lecture de ' + What);
    ExtCopy(LongInt(BufSeg) * 16, Dst + Sector * SecSize, LongInt(N) * SecSize);
    PutC('.');
    Sector := Sector + N;
  End;
End;

{ demarrage d'un disque dur : HPFS.IFS en memoire pour le noyau }
Procedure LoadBootIfs;
Begin
  FindFile('HPFS.IFS');
  If Not Found Then Fatal('HPFS.IFS introuvable dans la zone d''amorcage');
  ReadFileTo(IfsAddr, 'HPFS.IFS');
  MemW[0:Info + $40] := Word(IfsAddr); MemW[0:Info + $42] := Word(IfsAddr Shr 16);
  MemW[0:Info + $44] := Word(FileSize); MemW[0:Info + $46] := Word(FileSize Shr 16);
End;

Procedure LoadKernel;
Begin
  FindFile(KrnlName);
  If Not Found Then Fatal('OS2KRNL introuvable');
  MemW[0:Info + $2C] := Word(FileLba);  MemW[0:Info + $2E] := Word(FileLba Shr 16);
  MemW[0:Info + $30] := Word(FileSize); MemW[0:Info + $32] := Word(FileSize Shr 16);
  { lecture du fichier vers la zone de transit en memoire etendue }
  ReadFileTo(Staging, 'OS2KRNL');
  { en-tetes PE (4 Ko) }
  ExtCopy(Staging, LongInt(HdrSeg) * 16, 4096);
  If MemW[HdrSeg:0] <> $5A4D Then Fatal('OS2KRNL : signature MZ absente');
  PeOfs := MemW[HdrSeg:$3C];
  If (MemW[HdrSeg:PeOfs] <> $4550) Or (MemW[HdrSeg:PeOfs + 4] <> $014C) Then
    Fatal('OS2KRNL : image PE 80386 attendue');
  NSect := MemW[HdrSeg:PeOfs + 6];
  OptSize := MemW[HdrSeg:PeOfs + 20];
  KEntry := GetD(HdrSeg, PeOfs + 24 + 16);
  KBase := GetD(HdrSeg, PeOfs + 24 + 28);
  KImgSize := GetD(HdrSeg, PeOfs + 24 + 56);
  KHdrSize := GetD(HdrSeg, PeOfs + 24 + 60);
  If KBase < $00100000 Then Fatal('OS2KRNL : base inferieure a 1 Mo');
  { en-tetes, puis chaque section a son adresse virtuelle }
  BigZero(KBase, KImgSize);
  BigCopy(Staging, KBase, KHdrSize);
  SectOfs := PeOfs + 24 + OptSize;
  For I := 0 To NSect - 1 Do
  Begin
    VSize := GetD(HdrSeg, SectOfs + 8);
    VAddr := GetD(HdrSeg, SectOfs + 12);
    RawSize := GetD(HdrSeg, SectOfs + 16);
    RawPtr := GetD(HdrSeg, SectOfs + 20);
    If RawSize > VSize Then N := VSize Else N := RawSize;
    If N > 0 Then BigCopy(Staging + RawPtr, KBase + VAddr, N);
    SectOfs := SectOfs + 40;
  End;
  MemW[0:Info + $1C] := Word(KBase);    MemW[0:Info + $1E] := Word(KBase Shr 16);
  MemW[0:Info + $20] := Word(KImgSize); MemW[0:Info + $22] := Word(KImgSize Shr 16);
  KEntry := KBase + KEntry;
  MemW[0:Info + $24] := Word(KEntry);   MemW[0:Info + $26] := Word(KEntry Shr 16);
End;

{ ------------------------------------------------------------------ }
{ GDT, code de transition 32 bits et passage en mode protege         }
{ ------------------------------------------------------------------ }

Procedure PutB(Var P : Word; B : Byte);
Begin
  Mem[0:P] := B;
  Inc(P);
End;

Procedure PutDW(Var P : Word; D : LongInt);
Begin
  PutB(P, D And $FF); PutB(P, (D Shr 8) And $FF);
  PutB(P, (D Shr 16) And $FF); PutB(P, (D Shr 24) And $FF);
End;

Procedure BuildGdt;
Var P : Word;
Begin
  { 00h nul, 08h code 32 bits 0..4 Go, 10h donnees 32 bits 0..4 Go }
  P := GdtOfs;
  PutDW(P, 0); PutDW(P, 0);
  PutDW(P, $0000FFFF); PutDW(P, $00CF9A00);
  PutDW(P, $0000FFFF); PutDW(P, $00CF9200);
  { GDTR }
  MemW[0:GdtrOfs] := 3 * 8 - 1;
  MemW[0:GdtrOfs + 2] := GdtOfs;
  MemW[0:GdtrOfs + 4] := 0;
  { code de transition (32 bits) en 0:0A40 :
      mov ax,10h / mov ds,ax / es / fs / gs / ss
      mov esp,00090000h / mov ebx,00000500h / mov eax,point d'entree
      jmp eax }
  P := TrampOfs;
  PutB(P, $66); PutB(P, $B8); PutB(P, $10); PutB(P, $00);
  PutB(P, $8E); PutB(P, $D8);
  PutB(P, $8E); PutB(P, $C0);
  PutB(P, $8E); PutB(P, $E0);
  PutB(P, $8E); PutB(P, $E8);
  PutB(P, $8E); PutB(P, $D0);
  PutB(P, $BC); PutDW(P, $00090000);
  PutB(P, $BB); PutDW(P, Info);
  PutB(P, $B8); PutDW(P, KEntry);
  PutB(P, $FF); PutB(P, $E0);
End;

Procedure GetCursor;
Var R, C : Byte;
Begin
  asm
    mov ah,3
    xor bh,bh
    int 10h
    mov R,dh
    mov C,dl
  end;
  Mem[0:Info + $28] := R;
  Mem[0:Info + $29] := C;
End;

BEGIN
  BootDrive := Lo(PrefixSeg);
  If MemW[0:Info] <> $424F Then Fatal('bloc d''information d''amorcage absent');
  RootLba := GetD(0, Info + 4);
  RootSize := GetD(0, Info + 8);
  HdMode := MemW[0:Info + $34] = $4448;
  If HdMode Then SecSize := 512
  Else
  Begin
    SecSize := 2048;
    MemW[0:Info + $34] := 0;
  End;
  PutS('OS2LDR');
  { 32 Ko de zeros pour la mise a zero de la memoire etendue }
  For I := 0 To 16383 Do MemW[ZeroSeg:I * 2] := 0;
  EnableA20;
  ReadMemoryMap;
  LoadKernel;
  If HdMode Then LoadBootIfs;
  BuildGdt;
  PutS(#13#10);
  GetCursor;
  { passage en mode protege : LGDT, CR0.PE, saut lointain 08h:0A40h }
  asm
    cli
    xor ax,ax
    mov ds,ax
    db 0Fh,01h,16h
    dw 0A20h
    db 0Fh,20h,0C0h
    db 0Ch,01h
    db 0Fh,22h,0C0h
    db 0EAh
    dw 0A40h
    dw 0008h
  end;
END.
