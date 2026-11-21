{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -Q)
  @description: OPENGL.DLL - OpenGL 1.1 logiciel d'OS/2-0.
}

Library OpenGL;

{$R-,S-,I-}
{$IMAGEBASE $00C40000}

{ Compilation : OS2PC -Q DLL\OPENGL.PAS OPENGL.DLL

  OpenGL 1.1 en rendu logiciel, porte de l'OPENGL32.DLL de Pasdows 95
  (KERNEL/VMM32.PAS : moteur de rasterisation commun avec Direct3D et
  couche OpenGL), avec l'interface de fenetrage d'OS/2 (PGL, comme
  l'OpenGL d'OS/2 Warp 4) a la place de WGL.

  Pipeline : sommets (glBegin/glEnd, tableaux de sommets, glDrawArrays,
  glDrawElements, glInterleavedArrays) transformes par les matrices
  (modele-vue, projection, texture ; piles de 32, 4 et 4), eclaires
  (8 lumieres : directionnelles, ponctuelles, projecteurs ; materiaux,
  glColorMaterial, speculaire), brouillard (lineaire, EXP, EXP2),
  decoupes dans le volume de vision (6 plans), projetes dans la
  fenetre d'affichage puis rasterises : triangles par lignes, Gouraud
  ou couleur unie, textures 2D corrigees en perspective (REPEAT ou
  CLAMP, MODULATE, REPLACE, DECAL, ADD, deux unites), tampon Z de
  24 bits, test alpha, melange alpha, glScissor, points et lignes,
  glPolygonMode. Etat : glPushAttrib/glPopAttrib,
  glPushClientAttrib, glGet*, glReadPixels, glDrawPixels, generation
  de coordonnees de texture. Listes d'affichage, accumulation, stencil,
  evaluateurs, selection et retour : signales, sans effet.

  Les fonctions qui prennent des flottants les recoivent comme des
  LongInt (bits IEEE 32 bits) ; les doubles en deux LongInt (mot bas,
  puis mot haut), comme l'OPENGL32.DLL de Pasdows.

  Interface PGL (Presentation Manager) :
    pglChooseConfig(hab, pAttribList) -> PVISUALCONFIG (attributs a la
      GLX : PGL_RGBA 4, PGL_DOUBLEBUFFER 5, PGL_DEPTH_SIZE 12..., fin 0)
    pglQueryConfigs(hab) -> liste de PVISUALCONFIG terminee par 0
    pglCreateContext(hab, pVisualConfig, hgcShare, fDirect) -> HGC
    pglDestroyContext(hab, hgc), pglMakeCurrent(hab, hgc, hwnd),
    pglGetCurrentContext(hab), pglGetCurrentWindow(hab),
    pglSwapBuffers(hab, hwnd) : tampon arriere -> zone client
      (GpiDrawBits, 24 bits par pel),
    pglQueryCapability(hab), pglQueryVersion(hab, pMajor, pMinor),
    pglWaitGL, pglWaitPM, pglCopyContext, pglIsIndirect,
    pglSelectColorIndexPalette (FALSE : couleurs RVB seulement),
    pglGrabFrontBitmap, pglReleaseFrontBitmap, pglUseFont (sans effet).
  Le tampon de couleur (32 bits) et le tampon Z (24 bits) suivent la
  taille de la zone client de la fenetre (WinQueryWindowRect). }

Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeMem(Pb : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetInfoBlocks(PPTib, PPPib : LongInt) : LongInt; External 'DOSCALLS';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, I : LongInt) : LongInt; External 'PMWIN';
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';

Type
  PB1 = ^Byte; PW2 = ^Word; PL4 = ^LongInt;

{ ==================================================================== }
{ Memoire (pointeurs : Mem[0:x] := n'ecrit pas hors du noyau)           }
{ ==================================================================== }

Function RdB(A : LongInt) : LongInt;
Var Q : PB1;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Function RdW(A : LongInt) : LongInt;
Var Q : PW2;
Begin
  Q := Pointer(A);
  RdW := Q^;
End;

Function RdL(A : LongInt) : LongInt;
Var Q : PL4;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Procedure WrB(A, V : LongInt);
Var Q : PB1;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
End;

Procedure WrW(A, V : LongInt);
Var Q : PW2;
Begin
  Q := Pointer(A);
  Q^ := V And $FFFF;
End;

Procedure WrL(A, V : LongInt);
Var Q : PL4;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Type
  TBA = Array[0..$7FFFFFF] Of Byte;
  PBA = ^TBA;

Procedure MoveMem(S, D, N : LongInt);
Begin
  If N > 0 Then Move(PBA(S)^[0], PBA(D)^[0], N);
End;

Procedure FillMem(D, N, V : LongInt);
Begin
  If N > 0 Then FillChar(PBA(D)^[0], N, V And 255);
End;

Function Max(A, B : LongInt) : LongInt;
Begin
  If A > B Then Max := A Else Max := B;
End;

Function Min(A, B : LongInt) : LongInt;
Begin
  If A < B Then Min := A Else Min := B;
End;

Function IntStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IntStr := S;
End;

Function HexStr(V, N : LongInt) : String;
Const Dg : String[16] = '0123456789ABCDEF';
Var S : String; I : LongInt;
Begin
  S := '';
  For I := N - 1 DownTo 0 Do S := S + Dg[((V Shr (I * 4)) And 15) + 1];
  HexStr := S;
End;

Function PStr(A : LongInt) : String;
Var S : String;
Begin
  S := '';
  If A <> 0 Then
    While (RdB(A) <> 0) And (Length(S) < 255) Do
    Begin
      S := S + Chr(RdB(A));
      Inc(A);
    End;
  PStr := S;
End;

Procedure PutPStr(A : LongInt; S : String; N : LongInt);
Var I : LongInt;
Begin
  If A = 0 Then Exit;
  If Length(S) > N - 1 Then S := Copy(S, 1, N - 1);
  For I := 1 To Length(S) Do WrB(A + I - 1, Ord(S[I]));
  WrB(A + Length(S), 0);
End;

{ blocs de memoire (prives au processus, rendus a sa fin) }
Function KAlloc(N : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := 0;
  If DosAllocMem(LongInt(@P), N, $13) <> 0 Then P := 0;
  KAlloc := P;
End;

Function KAllocSys(N : LongInt) : LongInt;
Begin
  KAllocSys := KAlloc(N);
End;

Procedure KFree(P : LongInt);
Begin
  If P <> 0 Then DosFreeMem(P);
End;

{ journal : port serie COM1 (comme le journal du noyau) }
Procedure KLog(S : String);
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

Procedure HeapCheck(S : String);
Begin
End;

{ identificateur du processus courant (PIB +0) }
Function CurProc : LongInt;
Var T, P : LongInt;
Begin
  T := 0; P := 0;
  DosGetInfoBlocks(LongInt(@T), LongInt(@P));
  If P <> 0 Then CurProc := RdL(P) Else CurProc := 0;
End;

{ ==================================================================== }
{ Surfaces internes (champs des surfaces DirectDraw de Pasdows) :       }
{ +64 largeur, +68 hauteur, +72 pas, +76 bits, +88 bits par pixel,      }
{ +92 drapeaux, +96..+108 masques R, G, B, A, +120 Z attache,           }
{ +124 palette, +148 cles, +240..+268 composantes, +272 sorte (2 565,   }
{ 3 555, 4 888, 5 X888, 6 A8888, 7 1555, 8 4444, 0 autre)               }
{ ==================================================================== }

Var
  SysPal : Array[0..767] Of Byte;

Function MaskPos(M : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := 0;
  If M = 0 Then
  Begin
    MaskPos := 0;
    Exit;
  End;
  While ((M Shr P) And 1) = 0 Do Inc(P);
  MaskPos := P;
End;

Function MaskLen(M : LongInt) : LongInt;
Var P, N : LongInt;
Begin
  N := 0;
  For P := 0 To 31 Do If ((M Shr P) And 1) <> 0 Then Inc(N);
  MaskLen := N;
End;

Function ChanGet(V, P, L : LongInt) : LongInt;
Var C : LongInt;
Begin
  ChanGet := 0;
  If L <= 0 Then Exit;
  C := (V Shr P) And ((1 Shl L) - 1);
  If L >= 8 Then ChanGet := (C Shr (L - 8)) And 255
  Else ChanGet := ((C Shl (8 - L)) Or (C Shr Max(0, 2 * L - 8))) And 255;
End;

Function ChanPut(C, P, L : LongInt) : LongInt;
Begin
  ChanPut := 0;
  If L <= 0 Then Exit;
  If L >= 8 Then C := C Shl (L - 8) Else C := C Shr (8 - L);
  ChanPut := C Shl P;
End;

Procedure SfInfo(S : LongInt);
Var K, B : LongInt;
Begin
  For K := 0 To 3 Do
  Begin
    WrL(S + 240 + K * 8, MaskPos(RdL(S + 96 + K * 4)));
    WrL(S + 244 + K * 8, MaskLen(RdL(S + 96 + K * 4)));
  End;
  B := RdL(S + 88);
  K := 0;
  If (RdL(S + 92) And $20) <> 0 Then K := 1
  Else If (B = 16) And (RdL(S + 96) = $F800) And (RdL(S + 100) = $7E0) And (RdL(S + 104) = $1F) Then K := 2
  Else If (B = 16) And (RdL(S + 96) = $7C00) And (RdL(S + 100) = $3E0) And (RdL(S + 104) = $1F) And
          (RdL(S + 108) = 0) Then K := 3
  Else If (B >= 24) And (RdL(S + 96) = $FF0000) And (RdL(S + 100) = $FF00) And (RdL(S + 104) = $FF) Then
  Begin
    If B = 24 Then K := 4
    Else If RdL(S + 108) = 0 Then K := 5
    Else If RdL(S + 108) = LongInt($FF000000) Then K := 6;
  End;
  WrL(S + 272, K);
End;

Function SfBytes(S : LongInt) : LongInt;
Begin
  SfBytes := (RdL(S + 88) + 7) Div 8;
End;

Function SfPalRGB(S, I : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := 0;
  If S <> 0 Then P := RdL(S + 124);
  If P <> 0 Then
  Begin
    P := P + 68 + (I And 255) * 4;
    SfPalRGB := (RdB(P) Shl 16) Or (RdB(P + 1) Shl 8) Or RdB(P + 2);
  End
  Else
    SfPalRGB := (SysPal[(I And 255) * 3] Shl 16) Or (SysPal[(I And 255) * 3 + 1] Shl 8) Or
                SysPal[(I And 255) * 3 + 2];
End;

Function SfToRGB(S, V : LongInt) : LongInt;
Var R, G, B, A : LongInt;
Begin
  Case RdL(S + 272) Of
    1 :
    Begin
      SfToRGB := LongInt($FF000000) Or SfPalRGB(S, V);
      Exit;
    End;
    2 :
    Begin
      R := (V Shr 11) And 31; G := (V Shr 5) And 63; B := V And 31;
      SfToRGB := LongInt($FF000000) Or (((R Shl 3) Or (R Shr 2)) Shl 16) Or
                 (((G Shl 2) Or (G Shr 4)) Shl 8) Or (B Shl 3) Or (B Shr 2);
      Exit;
    End;
    4, 5 :
    Begin
      SfToRGB := LongInt($FF000000) Or (V And $FFFFFF);
      Exit;
    End;
    6 :
    Begin
      SfToRGB := V;
      Exit;
    End;
  End;
  R := ChanGet(V, RdL(S + 240), RdL(S + 244));
  G := ChanGet(V, RdL(S + 248), RdL(S + 252));
  B := ChanGet(V, RdL(S + 256), RdL(S + 260));
  If RdL(S + 268) > 0 Then A := ChanGet(V, RdL(S + 264), RdL(S + 268))
  Else A := 255;
  SfToRGB := (A Shl 24) Or (R Shl 16) Or (G Shl 8) Or B;
End;

{ couleurs vraies seulement : pas de surface a palette }
Function DXIdxOf(C : LongInt) : LongInt;
Begin
  DXIdxOf := 0;
End;

Function SfFromRGB(S, C : LongInt) : LongInt;
Var V : LongInt;
Begin
  Case RdL(S + 272) Of
    1 :
    Begin
      SfFromRGB := DXIdxOf(C);
      Exit;
    End;
    2 :
    Begin
      SfFromRGB := ((C Shr 8) And $F800) Or ((C Shr 5) And $7E0) Or ((C Shr 3) And $1F);
      Exit;
    End;
    4, 5 :
    Begin
      SfFromRGB := C And $FFFFFF;
      Exit;
    End;
    6 :
    Begin
      SfFromRGB := C;
      Exit;
    End;
  End;
  V := ChanPut((C Shr 16) And 255, RdL(S + 240), RdL(S + 244)) Or
       ChanPut((C Shr 8) And 255, RdL(S + 248), RdL(S + 252)) Or
       ChanPut(C And 255, RdL(S + 256), RdL(S + 260));
  If RdL(S + 268) > 0 Then V := V Or ChanPut((C Shr 24) And 255, RdL(S + 264), RdL(S + 268));
  SfFromRGB := V;
End;

Procedure SfFill(D, L, T, R, B, V : LongInt);
Var X, Y, A, BY : LongInt;
Begin
  L := Max(L, 0); T := Max(T, 0);
  R := Min(R, RdL(D + 64)); B := Min(B, RdL(D + 68));
  If (L >= R) Or (T >= B) Then Exit;
  BY := SfBytes(D);
  For Y := T To B - 1 Do
  Begin
    A := RdL(D + 76) + Y * RdL(D + 72);
    Case BY Of
      1 : FillMem(A + L, R - L, V);
      2 :
        If (V And 255) = ((V Shr 8) And 255) Then FillMem(A + L * 2, (R - L) * 2, V)
        Else For X := L To R - 1 Do WrW(A + X * 2, V);
      3 :
        For X := L To R - 1 Do
        Begin
          WrW(A + X * 3, V); WrB(A + X * 3 + 2, V Shr 16);
        End;
    Else
      If (V = 0) Or (V = -1) Then FillMem(A + L * 4, (R - L) * 4, V)
      Else For X := L To R - 1 Do WrL(A + X * 4, V);
    End;
  End;
End;

{ ------------------------------------------------------------------ }
{ Direct3D : moteur logiciel commun (D3D 1 a 7 et Direct3D 8)        }
{ ------------------------------------------------------------------ }
{ Sommets (FVF) transformes par Monde x Vue x Projection, eclaires
  (lumieres directionnelles, ponctuelles et projecteurs, materiau),
  brouillard de sommet, decoupes dans le volume de vision (6 plans),
  projetes dans la fenetre d'affichage puis rasterises : triangles
  par lignes horizontales (centres des pixels aux coordonnees
  entieres), couleurs de Gouraud ou unies, textures corrigees en
  perspective (par segments de 16 pixels), deux etages de melange
  (COLOROP / ALPHAOP), cle de couleur, test alpha, tampon Z (16, 24
  ou 32 bits), melange alpha, specularite et brouillard. Cible : toute
  surface DirectDraw (8, 16, 24 ou 32 bits). }

Type
  TMat = Array[0..15] Of Double;
  TLit = Record
    Typ, On : LongInt;
    Dif, Spe, Amb : Array[0..3] Of Double;
    Pos, Dir : Array[0..2] Of Double;
    Rng, Fall, A0, A1, A2, Th, Ph : Double;
  End;
  TVtx = Record
    X, Y, Z, W : Double;          { coordonnees de decoupage }
    SX, SY, SZ, RW : Double;      { ecran, Z, 1/w }
    A, R, G, B, SR, SG, SB, F : Double;
    U0, V0, U1, V1 : Double;
    CF : LongInt;
  End;
  TVtxArr = Array[0..65535] Of TVtx;
  PVtxArr = ^TVtxArr;
  TD3D = Record
    RT, ZB, Ver, InScene, UseTSS, LegBlend : LongInt;
    VX, VY, VW, VH : LongInt;
    VMinZ, VMaxZ, ClX, ClY, ClW, ClH : Double;
    Wld, Viw, Prj, WV, WVP : TMat;
    MOk : Boolean;
    RS : Array[0..255] Of LongInt;
    TS : Array[0..255] Of LongInt;
    Tex : Array[0..7] Of LongInt;
    Mt : Array[0..16] Of Double;
    Lt : Array[0..15] Of TLit;
    LS : Array[0..15] Of LongInt;
    VPCur, D3DObj, Core : LongInt;
    VPs : Array[0..15] Of LongInt;
    BFvf, BPt, BN, BBuf, BMax, BIdx, BIn : LongInt;
    Tris, Verts : LongInt;
    ClipU, ClipI : LongInt;
    SBRec : LongInt;
    D8 : LongInt;
  End;
  PD3D = ^TD3D;

Const
  { etats de rendu utiles }
  rsTexHandle = 1; rsPersp = 4; rsZEnable = 7; rsFill = 8; rsShade = 9;
  rsZWrite = 14; rsATest = 15; rsLastPix = 16; rsTexMag = 17;
  rsTexMin = 18; rsSrcBl = 19; rsDstBl = 20; rsTexBlend = 21; rsCull = 22;
  rsZFunc = 23; rsARef = 24; rsAFunc = 25; rsDither = 26; rsABlend = 27;
  rsFog = 28; rsSpecular = 29; rsFogColor = 34; rsFogTable = 35;
  rsFogStart = 36; rsFogEnd = 37; rsFogDens = 38; rsCKey = 41;
  rsTFactor = 60; rsWrap0 = 128; rsClipping = 136; rsLighting = 137;
  rsAmbient = 139; rsFogVtx = 140; rsColorVtx = 141; rsLocalView = 142;
  rsNormalize = 143; rsDifSrc = 145; rsSpcSrc = 146; rsAmbSrc = 147;
  rsEmiSrc = 148;
  { etats d'etage de texture }
  tsCOp = 1; tsCA1 = 2; tsCA2 = 3; tsAOp = 4; tsAA1 = 5; tsAA2 = 6;
  tsTCI = 11; tsAddr = 12; tsAddrU = 13; tsAddrV = 14; tsMag = 16;
  tsMin = 17; tsMip = 18;

Var
  D3G : PD3D;                       { peripherique courant }
  DV : PVtxArr;                     { sommets traites }
  DVCap : LongInt;
  DVBase : LongInt;
  D3DStrideOvr : LongInt;          { pas impose (Direct3D 8), 0 sinon }
  D8Pal : LongInt;                 { palette courante des textures P8 }
  DC : Array[0..15] Of TVtx;        { polygone en decoupe }
  DC2 : Array[0..15] Of TVtx;
  LtV : Array[0..15] Of TLit;      { lumieres dans l'espace de la vue }
  { format des sommets d'entree }
  VFStride, VFPos, VFNrm, VFDif, VFSpc, VFTexN, VFRhw : LongInt;
  VFTex : Array[0..7] Of LongInt;
  VFTexD : Array[0..7] Of LongInt;
  { etat de rasterisation (par appel) }
  RBits, RPitch, RBy, RKind, RW, RH, RTs : LongInt;
  ZBits, ZPitch, ZBy, ZMax : LongInt;
  RZOn, RZWr, RZFn, RShade, RABl, RSrc, RDst, RATst, RAFn, RARef : LongInt;
  RCKey, RFogOn, RFogC, RSpec, RTFac, RCull, RFill : LongInt;
  TxOn : Array[0..1] Of Boolean;
  TxBits, TxPitch, TxW, TxH, TxKind, TxBy, TxKey, TxKeyOn, TxAddrU,
    TxAddrV, TxS, TxMagLin : Array[0..1] Of LongInt;
  TxPal : Array[0..255] Of LongInt;
  TxCOp, TxCA1, TxCA2, TxAOp, TxAA1, TxAA2, TxTci : Array[0..1] Of LongInt;
  NStage : LongInt;
  ClipL, ClipT, ClipR, ClipB : LongInt;
  D3DStats : LongInt;
  GlScOn : Boolean;             { decoupe d'OpenGL (glScissor) }
  GlScL, GlScT, GlScR, GlScB : LongInt;

{ Choisir le peripherique du coeur C }
Function DevSel(C : LongInt) : Boolean;
Var P : LongInt;
Begin
  P := RdL(C + 64);
  Move(P, D3G, 4);
  DevSel := P <> 0;
End;

Function FlL(L : LongInt) : Double;
Var F : Single;
Begin
  WrL(LongInt(@F), L);
  FlL := F;
End;

Function LFl(D : Double) : LongInt;
Var F : Single;
Begin
  F := D;
  LFl := RdL(LongInt(@F));
End;

Function FlM(A : LongInt) : Double;
Begin
  FlM := FlL(RdL(A));
End;

{ ------------------------------------------------------------------ }
{ Matrices (lignes, v' = v x M)                                       }
{ ------------------------------------------------------------------ }

Procedure MatId(Var M : TMat);
Var I : LongInt;
Begin
  For I := 0 To 15 Do M[I] := 0;
  M[0] := 1; M[5] := 1; M[10] := 1; M[15] := 1;
End;

Procedure MatMul(Var R : TMat; Var A, B : TMat);
Var I, J : LongInt; T : TMat;
Begin
  For I := 0 To 3 Do
    For J := 0 To 3 Do
      T[I * 4 + J] := A[I * 4] * B[J] + A[I * 4 + 1] * B[4 + J] +
                      A[I * 4 + 2] * B[8 + J] + A[I * 4 + 3] * B[12 + J];
  R := T;
End;

Procedure MatLoad(Var M : TMat; P : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 15 Do M[I] := FlM(P + I * 4);
End;

Procedure MatStore(Var M : TMat; P : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 15 Do WrL(P + I * 4, LFl(M[I]));
End;

Procedure D3DMats;
Begin
  If D3G^.MOk Then Exit;
  MatMul(D3G^.WV, D3G^.Wld, D3G^.Viw);
  MatMul(D3G^.WVP, D3G^.WV, D3G^.Prj);
  D3G^.MOk := True;
End;

{ Matrice de transformation : 1 monde, 2 vue, 3 projection (D3D7 :
  1 = D3DTRANSFORMSTATE_WORLD ; D3D8 : 256 = monde, 2 vue, 3 proj.) }
Function D3DMatOf(K : LongInt; Var M : TMat) : Boolean;
Begin
  D3DMatOf := True;
  Case K Of
    1, 256 : M := D3G^.Wld;
    2 : M := D3G^.Viw;
    3 : M := D3G^.Prj;
  Else
    D3DMatOf := False;
  End;
End;

Procedure D3DMatSet(K : LongInt; Var M : TMat);
Begin
  Case K Of
    1, 256 : D3G^.Wld := M;
    2 : D3G^.Viw := M;
    3 : D3G^.Prj := M;
  End;
  D3G^.MOk := False;
End;

{ ------------------------------------------------------------------ }
{ Etat initial                                                       }
{ ------------------------------------------------------------------ }

Procedure D3DDefaults;
Var I : LongInt;
Begin
  FillMem(LongInt(@D3G^.RS), SizeOf(D3G^.RS), 0);
  FillMem(LongInt(@D3G^.TS), SizeOf(D3G^.TS), 0);
  MatId(D3G^.Wld); MatId(D3G^.Viw); MatId(D3G^.Prj);
  D3G^.MOk := False;
  D3G^.RS[rsPersp] := 1;
  D3G^.RS[rsZEnable] := Ord(D3G^.ZB <> 0);
  D3G^.RS[rsFill] := 3; D3G^.RS[rsShade] := 2; D3G^.RS[rsZWrite] := 1;
  D3G^.RS[rsLastPix] := 1; D3G^.RS[rsTexMag] := 1; D3G^.RS[rsTexMin] := 1;
  D3G^.RS[rsSrcBl] := 2; D3G^.RS[rsDstBl] := 1; D3G^.RS[rsTexBlend] := 2;
  D3G^.RS[rsCull] := 3; D3G^.RS[rsZFunc] := 4; D3G^.RS[rsAFunc] := 8;
  D3G^.RS[rsFogStart] := 0; D3G^.RS[rsFogEnd] := LFl(1.0);
  D3G^.RS[rsFogDens] := LFl(1.0);
  D3G^.RS[rsTFactor] := -1;
  D3G^.RS[rsClipping] := 1; D3G^.RS[rsLighting] := 1;
  D3G^.RS[rsColorVtx] := 1; D3G^.RS[rsLocalView] := 1;
  D3G^.RS[rsDifSrc] := 1; D3G^.RS[rsSpcSrc] := 2;
  D3G^.RS[rsAmbSrc] := 0; D3G^.RS[rsEmiSrc] := 0;
  If D3G^.Ver < 7 Then D3G^.RS[rsLighting] := 0;
  For I := 0 To 7 Do
  Begin
    D3G^.TS[I * 32 + tsCOp] := 1; D3G^.TS[I * 32 + tsAOp] := 1;
    D3G^.TS[I * 32 + tsCA1] := 2; D3G^.TS[I * 32 + tsCA2] := 1;
    D3G^.TS[I * 32 + tsAA1] := 2; D3G^.TS[I * 32 + tsAA2] := 1;
    D3G^.TS[I * 32 + tsTCI] := I;
    D3G^.TS[I * 32 + tsAddr] := 1;
    D3G^.TS[I * 32 + tsAddrU] := 1; D3G^.TS[I * 32 + tsAddrV] := 1;
    D3G^.TS[I * 32 + tsMag] := 1; D3G^.TS[I * 32 + tsMin] := 1;
    D3G^.TS[I * 32 + tsMip] := 1;
    D3G^.Tex[I] := 0;
  End;
  D3G^.TS[tsCOp] := 4; D3G^.TS[tsAOp] := 2;
  For I := 0 To 16 Do D3G^.Mt[I] := 0;
  For I := 0 To 15 Do
  Begin
    FillMem(LongInt(@D3G^.Lt[I]), SizeOf(TLit), 0);
    D3G^.LS[I] := 0;
  End;
  D3G^.LS[3] := 2;
  D3G^.ClX := -1; D3G^.ClY := 1; D3G^.ClW := 2; D3G^.ClH := 2;
  D3G^.VMinZ := 0; D3G^.VMaxZ := 1;
  If D3G^.RT <> 0 Then
  Begin
    D3G^.VX := 0; D3G^.VY := 0;
    D3G^.VW := RdL(D3G^.RT + 64); D3G^.VH := RdL(D3G^.RT + 68);
  End;
  D3G^.LegBlend := 2;
End;

{ ------------------------------------------------------------------ }
{ Format des sommets (FVF)                                           }
{ ------------------------------------------------------------------ }

Procedure FvfParse(F : LongInt);
Var O, N, I, K : LongInt;
Begin
  O := 0;
  VFRhw := 0;
  Case F And $E Of
    2 : O := 12;
    4 :
    Begin
      O := 16; VFRhw := 1;
    End;
    6 : O := 16;
    8 : O := 20;
    $A : O := 24;
    $C : O := 28;
    $E : O := 32;
  End;
  VFPos := 0;
  VFNrm := -1; VFDif := -1; VFSpc := -1;
  If (F And $10) <> 0 Then
  Begin
    VFNrm := O; O := O + 12;
  End;
  If (F And $20) <> 0 Then O := O + 4;
  If (F And $40) <> 0 Then
  Begin
    VFDif := O; O := O + 4;
  End;
  If (F And $80) <> 0 Then
  Begin
    VFSpc := O; O := O + 4;
  End;
  N := (F Shr 8) And 15;
  If N > 8 Then N := 8;
  VFTexN := N;
  For I := 0 To N - 1 Do
  Begin
    VFTex[I] := O;
    K := (F Shr (16 + I * 2)) And 3;
    Case K Of
      0 : VFTexD[I] := 2;
      1 : VFTexD[I] := 3;
      2 : VFTexD[I] := 4;
    Else
      VFTexD[I] := 1;
    End;
    O := O + VFTexD[I] * 4;
  End;
  VFStride := O;
End;

{ Types de sommets de D3D 2 : 1 D3DVERTEX, 2 D3DLVERTEX, 3 D3DTLVERTEX }
Function VtToFvf(T : LongInt) : LongInt;
Begin
  Case T Of
    1 : VtToFvf := $112;
    2 : VtToFvf := $1E2;
  Else
    VtToFvf := $1C4;
  End;
End;

Procedure D3DGrow(N : LongInt);
Var H, P : LongInt;
Begin
  If N <= DVCap Then Exit;
  If DVCap > 0 Then
  Begin
    P := 0;
    Move(DV, P, 4);
    KFree(P);
  End;
  DVCap := Max(N, 1024);
  P := KAlloc(DVCap * SizeOf(TVtx) + 16);
  Move(P, DV, 4);
End;

{ ------------------------------------------------------------------ }
{ Eclairage d'un sommet (espace de la vue)                           }
{ ------------------------------------------------------------------ }

{ Lumieres (espace du monde) ramenees dans l'espace de la vue }
Procedure D3DLightsView;
Var I : LongInt; X, Y, Z, D : Double; M : TMat;
Begin
  M := D3G^.Viw;
  For I := 0 To 15 Do
  Begin
    LtV[I] := D3G^.Lt[I];
    If LtV[I].On = 0 Then Continue;
    If LtV[I].Typ = 4 Then
    Begin
      { parallele : direction depuis la position }
      LtV[I].Typ := 3;
      LtV[I].Dir[0] := -LtV[I].Pos[0]; LtV[I].Dir[1] := -LtV[I].Pos[1];
      LtV[I].Dir[2] := -LtV[I].Pos[2];
    End;
    X := LtV[I].Pos[0]; Y := LtV[I].Pos[1]; Z := LtV[I].Pos[2];
    LtV[I].Pos[0] := X * M[0] + Y * M[4] + Z * M[8] + M[12];
    LtV[I].Pos[1] := X * M[1] + Y * M[5] + Z * M[9] + M[13];
    LtV[I].Pos[2] := X * M[2] + Y * M[6] + Z * M[10] + M[14];
    X := LtV[I].Dir[0]; Y := LtV[I].Dir[1]; Z := LtV[I].Dir[2];
    LtV[I].Dir[0] := X * M[0] + Y * M[4] + Z * M[8];
    LtV[I].Dir[1] := X * M[1] + Y * M[5] + Z * M[9];
    LtV[I].Dir[2] := X * M[2] + Y * M[6] + Z * M[10];
    D := Sqrt(LtV[I].Dir[0] * LtV[I].Dir[0] + LtV[I].Dir[1] *
              LtV[I].Dir[1] + LtV[I].Dir[2] * LtV[I].Dir[2]);
    If D > 0.000001 Then
    Begin
      LtV[I].Dir[0] := LtV[I].Dir[0] / D; LtV[I].Dir[1] := LtV[I].Dir[1] / D;
      LtV[I].Dir[2] := LtV[I].Dir[2] / D;
    End;
  End;
End;

Procedure D3DLight(PX, PY, PZ, NX, NY, NZ : Double; DifC, SpcC : LongInt;
                   Var V : TVtx);
Var I, Src : LongInt;
    MdR, MdG, MdB, MdA, MaR, MaG, MaB, MsR, MsG, MsB, MeR, MeG, MeB,
    DR, DG, DB, AR, AG, AB, SR, SG, SB, LX, LY, LZ, D, At, Sp, NL, HX,
    HY, HZ, NH, VX, VY, VZ, Rho, Ct, Cp, X, Y, Z : Double;
Begin
  D := Sqrt(NX * NX + NY * NY + NZ * NZ);
  If D > 0.000001 Then
  Begin
    NX := NX / D; NY := NY / D; NZ := NZ / D;
  End;
  MdR := D3G^.Mt[0]; MdG := D3G^.Mt[1]; MdB := D3G^.Mt[2];
  MdA := D3G^.Mt[3];
  MaR := D3G^.Mt[4]; MaG := D3G^.Mt[5]; MaB := D3G^.Mt[6];
  MsR := D3G^.Mt[8]; MsG := D3G^.Mt[9]; MsB := D3G^.Mt[10];
  MeR := D3G^.Mt[12]; MeG := D3G^.Mt[13]; MeB := D3G^.Mt[14];
  If D3G^.RS[rsColorVtx] <> 0 Then
  Begin
    Src := D3G^.RS[rsDifSrc];
    If (Src = 1) And (DifC <> 0) Then
    Begin
      MdA := ((DifC Shr 24) And 255) / 255;
      MdR := ((DifC Shr 16) And 255) / 255;
      MdG := ((DifC Shr 8) And 255) / 255; MdB := (DifC And 255) / 255;
    End;
    If (D3G^.RS[rsAmbSrc] = 1) And (DifC <> 0) Then
    Begin
      MaR := ((DifC Shr 16) And 255) / 255;
      MaG := ((DifC Shr 8) And 255) / 255; MaB := (DifC And 255) / 255;
    End;
    If (D3G^.RS[rsSpcSrc] = 2) And (SpcC <> 0) Then
    Begin
      MsR := ((SpcC Shr 16) And 255) / 255;
      MsG := ((SpcC Shr 8) And 255) / 255; MsB := (SpcC And 255) / 255;
    End;
  End;
  I := D3G^.RS[rsAmbient];
  AR := ((I Shr 16) And 255) / 255; AG := ((I Shr 8) And 255) / 255;
  AB := (I And 255) / 255;
  DR := 0; DG := 0; DB := 0; SR := 0; SG := 0; SB := 0;
  For I := 0 To 15 Do
  Begin
    If LtV[I].On = 0 Then Continue;
    At := 1; Sp := 1;
    If LtV[I].Typ = 3 Then
    Begin
      LX := -LtV[I].Dir[0]; LY := -LtV[I].Dir[1];
      LZ := -LtV[I].Dir[2];
    End
    Else
    Begin
      LX := LtV[I].Pos[0] - PX; LY := LtV[I].Pos[1] - PY;
      LZ := LtV[I].Pos[2] - PZ;
      D := Sqrt(LX * LX + LY * LY + LZ * LZ);
      If (LtV[I].Rng > 0) And (D > LtV[I].Rng) Then Continue;
      If D > 0.000001 Then
      Begin
        LX := LX / D; LY := LY / D; LZ := LZ / D;
      End;
      X := LtV[I].A0 + LtV[I].A1 * D + LtV[I].A2 * D * D;
      If X > 0.000001 Then At := 1 / X;
      If LtV[I].Typ = 2 Then
      Begin
        Rho := -(LX * LtV[I].Dir[0] + LY * LtV[I].Dir[1] +
                 LZ * LtV[I].Dir[2]);
        Ct := Cos(LtV[I].Th / 2); Cp := Cos(LtV[I].Ph / 2);
        If Rho <= Cp Then Continue;
        If (Rho < Ct) And (Ct > Cp) Then Sp := (Rho - Cp) / (Ct - Cp);
      End;
    End;
    At := At * Sp;
    AR := AR + LtV[I].Amb[0] * At; AG := AG + LtV[I].Amb[1] * At;
    AB := AB + LtV[I].Amb[2] * At;
    NL := NX * LX + NY * LY + NZ * LZ;
    If NL <= 0 Then Continue;
    DR := DR + LtV[I].Dif[0] * NL * At;
    DG := DG + LtV[I].Dif[1] * NL * At;
    DB := DB + LtV[I].Dif[2] * NL * At;
    If (D3G^.RS[rsSpecular] <> 0) And (D3G^.Mt[16] > 0) Then
    Begin
      If D3G^.RS[rsLocalView] <> 0 Then
      Begin
        D := Sqrt(PX * PX + PY * PY + PZ * PZ);
        If D > 0.000001 Then
        Begin
          VX := -PX / D; VY := -PY / D; VZ := -PZ / D;
        End
        Else
        Begin
          VX := 0; VY := 0; VZ := -1;
        End;
      End
      Else
      Begin
        VX := 0; VY := 0; VZ := -1;
      End;
      HX := LX + VX; HY := LY + VY; HZ := LZ + VZ;
      D := Sqrt(HX * HX + HY * HY + HZ * HZ);
      If D > 0.000001 Then
      Begin
        NH := (NX * HX + NY * HY + NZ * HZ) / D;
        If NH > 0 Then
        Begin
          NH := Exp(D3G^.Mt[16] * Ln(NH)) * At;
          SR := SR + LtV[I].Spe[0] * NH;
          SG := SG + LtV[I].Spe[1] * NH;
          SB := SB + LtV[I].Spe[2] * NH;
        End;
      End;
    End;
  End;
  X := MeR + MaR * AR + MdR * DR;
  Y := MeG + MaG * AG + MdG * DG;
  Z := MeB + MaB * AB + MdB * DB;
  If X > 1 Then X := 1;
  If Y > 1 Then Y := 1;
  If Z > 1 Then Z := 1;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := 0;
  If Z < 0 Then Z := 0;
  If MdA > 1 Then MdA := 1;
  If MdA < 0 Then MdA := 0;
  V.R := X * 255; V.G := Y * 255; V.B := Z * 255; V.A := MdA * 255;
  X := MsR * SR; Y := MsG * SG; Z := MsB * SB;
  If X > 1 Then X := 1;
  If Y > 1 Then Y := 1;
  If Z > 1 Then Z := 1;
  V.SR := X * 255; V.SG := Y * 255; V.SB := Z * 255;
End;

{ Facteur de brouillard (1 sans brouillard, 0 tout brouillard) }
Function D3DFogOf(D : Double) : Double;
Var Md : LongInt; S, E, De, F : Double;
Begin
  Md := D3G^.RS[rsFogVtx];
  If Md = 0 Then Md := D3G^.RS[rsFogTable];
  If (D3G^.Ver <= 3) And (D3G^.LS[4] <> 0) Then Md := D3G^.LS[4];
  If Md = 0 Then Md := 3;
  S := FlL(D3G^.RS[rsFogStart]); E := FlL(D3G^.RS[rsFogEnd]);
  De := FlL(D3G^.RS[rsFogDens]);
  If D3G^.Ver <= 3 Then
  Begin
    If D3G^.LS[5] <> 0 Then S := FlL(D3G^.LS[5]);
    If D3G^.LS[6] <> 0 Then E := FlL(D3G^.LS[6]);
    If D3G^.LS[7] <> 0 Then De := FlL(D3G^.LS[7]);
  End;
  Case Md Of
    1 : F := Exp(-De * D);
    2 : F := Exp(-(De * D) * (De * D));
  Else
    If E - S > 0.000001 Then F := (E - D) / (E - S) Else F := 1;
  End;
  If F < 0 Then F := 0;
  If F > 1 Then F := 1;
  D3DFogOf := F;
End;

{ Traiter N sommets (format courant VF*, pas VFStride) de Src vers DV }
Procedure D3DProcess(Src, N : LongInt; Light : Boolean);
Var I, J, A, C, S, K, T : LongInt; X, Y, Z, W, PX, PY, PZ, NX, NY, NZ,
    NX2, NY2, NZ2 : Double;
    M : TMat;
Begin
  D3DGrow(DVBase + N);
  D3DMats;
  M := D3G^.WVP;
  For I := 0 To N - 1 Do
  Begin
    J := DVBase + I;
    A := Src + I * VFStride;
    X := FlM(A); Y := FlM(A + 4); Z := FlM(A + 8);
    If VFDif >= 0 Then C := RdL(A + VFDif) Else C := -1;
    If VFSpc >= 0 Then S := RdL(A + VFSpc) Else S := 0;
    If VFRhw <> 0 Then
    Begin
      W := FlM(A + 12);
      DV^[J].SX := X; DV^[J].SY := Y; DV^[J].SZ := Z;
      If Abs(W) < 0.0000001 Then W := 1;
      DV^[J].RW := W;
      DV^[J].X := X; DV^[J].Y := Y; DV^[J].Z := Z; DV^[J].W := 1 / W;
      DV^[J].CF := 0;
    End
    Else
    Begin
      DV^[J].X := X * M[0] + Y * M[4] + Z * M[8] + M[12];
      DV^[J].Y := X * M[1] + Y * M[5] + Z * M[9] + M[13];
      DV^[J].Z := X * M[2] + Y * M[6] + Z * M[10] + M[14];
      DV^[J].W := X * M[3] + Y * M[7] + Z * M[11] + M[15];
      DV^[J].CF := -1;
    End;
    DV^[J].A := (C Shr 24) And 255; DV^[J].R := (C Shr 16) And 255;
    DV^[J].G := (C Shr 8) And 255; DV^[J].B := C And 255;
    DV^[J].SR := (S Shr 16) And 255; DV^[J].SG := (S Shr 8) And 255;
    DV^[J].SB := S And 255;
    DV^[J].F := 1;
    If (VFRhw <> 0) And (VFSpc >= 0) Then
      DV^[J].F := ((S Shr 24) And 255) / 255;
    If (VFRhw = 0) And (Light Or (D3G^.RS[rsFog] <> 0)) Then
    Begin
      PX := X * D3G^.WV[0] + Y * D3G^.WV[4] + Z * D3G^.WV[8] + D3G^.WV[12];
      PY := X * D3G^.WV[1] + Y * D3G^.WV[5] + Z * D3G^.WV[9] + D3G^.WV[13];
      PZ := X * D3G^.WV[2] + Y * D3G^.WV[6] + Z * D3G^.WV[10] + D3G^.WV[14];
      If Light And (VFNrm >= 0) Then
      Begin
        NX := FlM(A + VFNrm); NY := FlM(A + VFNrm + 4);
        NZ := FlM(A + VFNrm + 8);
        NX2 := NX * D3G^.WV[0] + NY * D3G^.WV[4] + NZ * D3G^.WV[8];
        NY2 := NX * D3G^.WV[1] + NY * D3G^.WV[5] + NZ * D3G^.WV[9];
        NZ2 := NX * D3G^.WV[2] + NY * D3G^.WV[6] + NZ * D3G^.WV[10];
        If VFDif < 0 Then C := 0;
        D3DLight(PX, PY, PZ, NX2, NY2, NZ2, C, S, DV^[J]);
      End;
      If D3G^.RS[rsFog] <> 0 Then DV^[J].F := D3DFogOf(Abs(PZ));
    End;
    DV^[J].U0 := 0; DV^[J].V0 := 0; DV^[J].U1 := 0; DV^[J].V1 := 0;
    For K := 0 To 1 Do
    Begin
      T := D3G^.TS[K * 32 + tsTCI] And $FFFF;
      If (D3G^.Ver <= 2) Then T := 0;
      If T < VFTexN Then
      Begin
        If K = 0 Then
        Begin
          DV^[J].U0 := FlM(A + VFTex[T]);
          If VFTexD[T] > 1 Then DV^[J].V0 := FlM(A + VFTex[T] + 4);
        End
        Else
        Begin
          DV^[J].U1 := FlM(A + VFTex[T]);
          If VFTexD[T] > 1 Then DV^[J].V1 := FlM(A + VFTex[T] + 4);
        End;
      End;
    End;
  End;
  D3G^.Verts := D3G^.Verts + N;
End;

{ Projection dans la fenetre d'affichage }
Procedure D3DProject(Var V : TVtx);
Var IW : Double;
Begin
  If V.CF = 0 Then Exit;
  If Abs(V.W) < 0.0000001 Then IW := 10000000 Else IW := 1 / V.W;
  V.SX := D3G^.VX + ((V.X * IW - D3G^.ClX) / D3G^.ClW) * D3G^.VW;
  V.SY := D3G^.VY + ((D3G^.ClY - V.Y * IW) / D3G^.ClH) * D3G^.VH;
  V.SZ := D3G^.VMinZ + V.Z * IW * (D3G^.VMaxZ - D3G^.VMinZ);
  V.RW := IW;
End;

{ ------------------------------------------------------------------ }
{ Decoupage (polygone dans DC, N sommets) : 6 plans                  }
{ ------------------------------------------------------------------ }

Function PlaneD(Var V : TVtx; P : LongInt) : Double;
Begin
  Case P Of
    0 : PlaneD := V.X - D3G^.ClX * V.W;
    1 : PlaneD := (D3G^.ClX + D3G^.ClW) * V.W - V.X;
    2 : PlaneD := V.Y - (D3G^.ClY - D3G^.ClH) * V.W;
    3 : PlaneD := D3G^.ClY * V.W - V.Y;
    4 : PlaneD := V.Z;
  Else
    PlaneD := V.W - V.Z;
  End;
End;

Procedure VLerp(Var R : TVtx; Var A, B : TVtx; T : Double);
Begin
  R.X := A.X + (B.X - A.X) * T; R.Y := A.Y + (B.Y - A.Y) * T;
  R.Z := A.Z + (B.Z - A.Z) * T; R.W := A.W + (B.W - A.W) * T;
  R.A := A.A + (B.A - A.A) * T; R.R := A.R + (B.R - A.R) * T;
  R.G := A.G + (B.G - A.G) * T; R.B := A.B + (B.B - A.B) * T;
  R.SR := A.SR + (B.SR - A.SR) * T; R.SG := A.SG + (B.SG - A.SG) * T;
  R.SB := A.SB + (B.SB - A.SB) * T; R.F := A.F + (B.F - A.F) * T;
  R.U0 := A.U0 + (B.U0 - A.U0) * T; R.V0 := A.V0 + (B.V0 - A.V0) * T;
  R.U1 := A.U1 + (B.U1 - A.U1) * T; R.V1 := A.V1 + (B.V1 - A.V1) * T;
  R.CF := -1;
End;

Function D3DClipPoly(N : LongInt) : LongInt;
Var P, I, J, M : LongInt; DA, DB : Double;
Begin
  For P := 0 To 5 Do
  Begin
    If N < 3 Then
    Begin
      D3DClipPoly := 0;
      Exit;
    End;
    M := 0;
    For I := 0 To N - 1 Do
    Begin
      J := (I + 1) Mod N;
      DA := PlaneD(DC[I], P); DB := PlaneD(DC[J], P);
      If DA >= 0 Then
      Begin
        If M < 15 Then
        Begin
          DC2[M] := DC[I]; Inc(M);
        End;
      End;
      If ((DA >= 0) And (DB < 0)) Or ((DA < 0) And (DB >= 0)) Then
        If M < 15 Then
        Begin
          VLerp(DC2[M], DC[I], DC[J], DA / (DA - DB));
          Inc(M);
        End;
    End;
    For I := 0 To M - 1 Do DC[I] := DC2[I];
    N := M;
  End;
  D3DClipPoly := N;
End;

{ ------------------------------------------------------------------ }
{ Rasterisation                                                      }
{ ------------------------------------------------------------------ }

Function Mul8(A, B : LongInt) : LongInt;
Begin
  Mul8 := (A * B + 128) Div 255;
End;

Function Clamp8(V : LongInt) : LongInt;
Begin
  If V < 0 Then V := 0;
  If V > 255 Then V := 255;
  Clamp8 := V;
End;

Function CmpOk(Fn, A, B : LongInt) : Boolean;
Begin
  Case Fn Of
    1 : CmpOk := False;
    2 : CmpOk := A < B;
    3 : CmpOk := A = B;
    4 : CmpOk := A <= B;
    5 : CmpOk := A > B;
    6 : CmpOk := A <> B;
    7 : CmpOk := A >= B;
  Else
    CmpOk := True;
  End;
End;

{ Texel brut -> ARGB selon la sorte du format }
Function TxDecode(K, V : LongInt) : LongInt;
Var R, G, B, A : LongInt;
Begin
  Case TxKind[K] Of
    1 : TxDecode := TxPal[V And 255];
    2 :
    Begin
      R := (V Shr 11) And 31; G := (V Shr 5) And 63; B := V And 31;
      TxDecode := LongInt($FF000000) Or (((R Shl 3) Or (R Shr 2)) Shl 16) Or
                  (((G Shl 2) Or (G Shr 4)) Shl 8) Or (B Shl 3) Or (B Shr 2);
    End;
    3, 7 :
    Begin
      R := (V Shr 10) And 31; G := (V Shr 5) And 31; B := V And 31;
      A := 255;
      If (TxKind[K] = 7) And ((V And $8000) = 0) Then A := 0;
      TxDecode := (A Shl 24) Or (((R Shl 3) Or (R Shr 2)) Shl 16) Or
                  (((G Shl 3) Or (G Shr 2)) Shl 8) Or (B Shl 3) Or (B Shr 2);
    End;
    8 :
    Begin
      A := (V Shr 12) And 15; R := (V Shr 8) And 15; G := (V Shr 4) And 15;
      B := V And 15;
      TxDecode := ((A * 17) Shl 24) Or ((R * 17) Shl 16) Or
                  ((G * 17) Shl 8) Or (B * 17);
    End;
    4, 5 : TxDecode := LongInt($FF000000) Or (V And $FFFFFF);
    6 : TxDecode := V;
  Else
    TxDecode := SfToRGB(TxS[K], V);
  End;
End;

{ Coordonnee de texel (16.16) -> indice selon le mode d'adressage }
Function TxAddr(C, N, Md : LongInt) : LongInt;
Var X : LongInt;
Begin
  If C >= 0 Then X := C Shr 16
  Else X := -1 - ((-C - 1) Shr 16);
  Case Md Of
    3, 4 :
    Begin
      If X < 0 Then X := 0;
      If X >= N Then X := N - 1;
    End;
    2 :
    Begin
      X := X Mod (2 * N);
      If X < 0 Then X := X + 2 * N;
      If X >= N Then X := 2 * N - 1 - X;
    End;
  Else
    If (N And (N - 1)) = 0 Then X := X And (N - 1)
    Else
    Begin
      X := X Mod N;
      If X < 0 Then X := X + N;
    End;
  End;
  TxAddr := X;
End;

{ Texel de l'etage K en (U, V) 16.16 ; -1 dans Hit si cle de couleur }
Function TxFetch(K, U, V : LongInt; Var Keyed : Boolean) : LongInt;
Var X, Y, A, Raw : LongInt;
Begin
  X := TxAddr(U, TxW[K], TxAddrU[K]);
  Y := TxAddr(V, TxH[K], TxAddrV[K]);
  A := TxBits[K] + Y * TxPitch[K];
  Case TxBy[K] Of
    1 : Raw := RdB(A + X);
    2 : Raw := RdW(A + X * 2);
    3 : Raw := RdW(A + X * 3) Or (RdB(A + X * 3 + 2) Shl 16);
  Else
    Raw := RdL(A + X * 4);
  End;
  If (TxKeyOn[K] <> 0) And (Raw = TxKey[K]) Then Keyed := True;
  TxFetch := TxDecode(K, Raw);
End;

{ Argument d'un etage : 0 diffuse, 1 courant, 2 texture, 3 facteur,
  4 speculaire ; 10h complement, 20h alpha replique }
Function TxArg(Ar, Dif, Cur, Tex, Spe : LongInt) : LongInt;
Var V, A : LongInt;
Begin
  Case Ar And 7 Of
    0 : V := Dif;
    1 : V := Cur;
    2 : V := Tex;
    3 : V := RTFac;
    4 : V := Spe;
  Else
    V := Cur;
  End;
  If (Ar And $10) <> 0 Then V := V Xor -1;
  If (Ar And $20) <> 0 Then
  Begin
    A := (V Shr 24) And 255;
    V := (A Shl 24) Or (A Shl 16) Or (A Shl 8) Or A;
  End;
  TxArg := V;
End;

{ Operation d'etage sur une composante (decalage Sh) }
Function TxOpC(Op, A1, A2, Sh, Dif, Tex, Cur : LongInt) : LongInt;
Var X, Y, R, T : LongInt;
Begin
  X := (A1 Shr Sh) And 255; Y := (A2 Shr Sh) And 255;
  Case Op Of
    2 : R := X;
    3 : R := Y;
    4 : R := Mul8(X, Y);
    5 : R := Clamp8(Mul8(X, Y) * 2);
    6 : R := Clamp8(Mul8(X, Y) * 4);
    7 : R := Clamp8(X + Y);
    8 : R := Clamp8(X + Y - 128);
    9 : R := Clamp8((X + Y - 128) * 2);
    10 : R := Clamp8(X - Y);
    11 : R := Clamp8(X + Y - Mul8(X, Y));
    12, 13, 14, 16 :
    Begin
      Case Op Of
        12 : T := (Dif Shr 24) And 255;
        13 : T := (Tex Shr 24) And 255;
        14 : T := (RTFac Shr 24) And 255;
      Else
        T := (Cur Shr 24) And 255;
      End;
      R := Clamp8(Mul8(X, T) + Mul8(Y, 255 - T));
    End;
    15 : R := Clamp8(X + Mul8(Y, 255 - ((Tex Shr 24) And 255)));
    18 : R := Clamp8(X + Mul8((A1 Shr 24) And 255, Y));
    20 : R := Clamp8(X + Mul8(255 - ((A1 Shr 24) And 255), Y));
  Else
    R := Mul8(X, Y);
  End;
  TxOpC := R;
End;

{ Melange des etages : couleur finale (avant brouillard) }
Function D3DShade(Dif, Spe : LongInt; Var T0, T1 : LongInt) : LongInt;
Var K, Cur, Tex, A1, A2, R, G, B, A, Op : LongInt;
Begin
  Cur := Dif;
  For K := 0 To NStage - 1 Do
  Begin
    If K = 0 Then Tex := T0 Else Tex := T1;
    Op := TxCOp[K];
    If Op <= 1 Then Break;
    A1 := TxArg(TxCA1[K], Dif, Cur, Tex, Spe);
    A2 := TxArg(TxCA2[K], Dif, Cur, Tex, Spe);
    R := TxOpC(Op, A1, A2, 16, Dif, Tex, Cur);
    G := TxOpC(Op, A1, A2, 8, Dif, Tex, Cur);
    B := TxOpC(Op, A1, A2, 0, Dif, Tex, Cur);
    Op := TxAOp[K];
    If Op <= 1 Then A := (Cur Shr 24) And 255
    Else
    Begin
      A1 := TxArg(TxAA1[K], Dif, Cur, Tex, Spe);
      A2 := TxArg(TxAA2[K], Dif, Cur, Tex, Spe);
      A := TxOpC(Op, A1, A2, 24, Dif, Tex, Cur);
    End;
    Cur := (A Shl 24) Or (R Shl 16) Or (G Shl 8) Or B;
  End;
  D3DShade := Cur;
End;

{ Melange de texture des versions 1 et 2 (D3DRENDERSTATE_TEXTUREMAPBLEND) }
Function D3DLegacy(Dif, Tex : LongInt; HasA : Boolean) : LongInt;
Var A, R, G, B, T : LongInt;
Begin
  Case D3G^.LegBlend Of
    1, 5, 7 : D3DLegacy := Tex;
    3 :
    Begin
      T := (Tex Shr 24) And 255;
      R := Mul8((Tex Shr 16) And 255, T) + Mul8((Dif Shr 16) And 255, 255 - T);
      G := Mul8((Tex Shr 8) And 255, T) + Mul8((Dif Shr 8) And 255, 255 - T);
      B := Mul8(Tex And 255, T) + Mul8(Dif And 255, 255 - T);
      D3DLegacy := (Dif And LongInt($FF000000)) Or (Clamp8(R) Shl 16) Or
                   (Clamp8(G) Shl 8) Or Clamp8(B);
    End;
    8 :
    Begin
      R := Clamp8(((Tex Shr 16) And 255) + ((Dif Shr 16) And 255));
      G := Clamp8(((Tex Shr 8) And 255) + ((Dif Shr 8) And 255));
      B := Clamp8((Tex And 255) + (Dif And 255));
      D3DLegacy := (Dif And LongInt($FF000000)) Or (R Shl 16) Or (G Shl 8)
                   Or B;
    End;
  Else
    Begin
      R := Mul8((Tex Shr 16) And 255, (Dif Shr 16) And 255);
      G := Mul8((Tex Shr 8) And 255, (Dif Shr 8) And 255);
      B := Mul8(Tex And 255, Dif And 255);
      If D3G^.LegBlend = 4 Then
        A := Mul8((Tex Shr 24) And 255, (Dif Shr 24) And 255)
      Else If HasA Then A := (Tex Shr 24) And 255
      Else A := (Dif Shr 24) And 255;
      D3DLegacy := (A Shl 24) Or (R Shl 16) Or (G Shl 8) Or B;
    End;
  End;
End;

{ Facteur de melange (D3DBLEND) pour la source S et la destination D }
Function BlFac(F, S, D, Sh : LongInt) : LongInt;
Var SA, DA : LongInt;
Begin
  SA := (S Shr 24) And 255; DA := (D Shr 24) And 255;
  Case F Of
    1 : BlFac := 0;
    2 : BlFac := 255;
    3 : BlFac := (S Shr Sh) And 255;
    4 : BlFac := 255 - ((S Shr Sh) And 255);
    5, 12 : BlFac := SA;
    6, 13 : BlFac := 255 - SA;
    7 : BlFac := DA;
    8 : BlFac := 255 - DA;
    9 : BlFac := (D Shr Sh) And 255;
    10 : BlFac := 255 - ((D Shr Sh) And 255);
    11 : BlFac := Min(SA, 255 - DA);
  Else
    BlFac := 255;
  End;
End;

{ Pixel de la cible -> ARGB et inversement }
Function RtGet(A : LongInt) : LongInt;
Var V, R, G, B : LongInt;
Begin
  Case RKind Of
    1 : RtGet := LongInt($FF000000) Or SfPalRGB(RTs, RdB(A));
    2 :
    Begin
      V := RdW(A);
      R := (V Shr 11) And 31; G := (V Shr 5) And 63; B := V And 31;
      RtGet := LongInt($FF000000) Or (((R Shl 3) Or (R Shr 2)) Shl 16) Or
               (((G Shl 2) Or (G Shr 4)) Shl 8) Or (B Shl 3) Or (B Shr 2);
    End;
    4 : RtGet := LongInt($FF000000) Or RdW(A) Or (RdB(A + 2) Shl 16);
    5, 6 : RtGet := RdL(A);
  Else
    Begin
      Case RBy Of
        1 : V := RdB(A);
        2 : V := RdW(A);
        3 : V := RdW(A) Or (RdB(A + 2) Shl 16);
      Else
        V := RdL(A);
      End;
      RtGet := SfToRGB(RTs, V);
    End;
  End;
End;

Procedure RtPut(A, C : LongInt);
Var V : LongInt;
Begin
  Case RKind Of
    1 : WrB(A, DXIdxOf(C));
    2 : WrW(A, ((C Shr 8) And $F800) Or ((C Shr 5) And $7E0) Or)
                     ((C Shr 3) And $1F);
    3 : WrW(A, ((C Shr 9) And $7C00) Or ((C Shr 6) And $3E0) Or)
                     ((C Shr 3) And $1F);
    4 :
    Begin
      WrW(A, C); WrB(A + 2, C Shr 16);
    End;
    5 : WrL(A, C And $FFFFFF);
    6 : WrL(A, C);
  Else
    Begin
      V := SfFromRGB(RTs, C);
      Case RBy Of
        1 : WrB(A, V);
        2 : WrW(A, V);
        3 :
        Begin
          WrW(A, V); WrB(A + 2, V Shr 16);
        End;
      Else
        WrL(A, V);
      End;
    End;
  End;
End;

{ Ecrire un pixel (tests, melange) ; Z en 24 bits (0..FFFFFFh) }
Procedure D3DPixel(X, Y, Z, Dif, Spe, Fog, U0, V0, U1, V1 : LongInt);
Var ZA, ZO, CA, C, T0, T1, D, A, R, G, B, FS, FD : LongInt;
    Keyed : Boolean;
Begin
  ZA := 0;
  If RZOn <> 0 Then
  Begin
    ZA := ZBits + Y * ZPitch + X * ZBy;
    If ZBy = 2 Then
    Begin
      ZO := RdW(ZA); Z := Z Shr 8;
    End
    Else ZO := RdL(ZA) And $FFFFFF;
    If Not CmpOk(RZFn, Z, ZO) Then Exit;
  End;
  Keyed := False;
  T0 := -1; T1 := -1;
  If TxOn[0] Then T0 := TxFetch(0, U0, V0, Keyed);
  If TxOn[1] Then T1 := TxFetch(1, U1, V1, Keyed);
  If Keyed And (RCKey <> 0) Then Exit;
  If D3G^.UseTSS <> 0 Then C := D3DShade(Dif, Spe, T0, T1)
  Else If TxOn[0] Then
    C := D3DLegacy(Dif, T0, (TxKind[0] = 6) Or (TxKind[0] = 7) Or
                   (TxKind[0] = 8))
  Else C := Dif;
  If RATst <> 0 Then
    If Not CmpOk(RAFn, (C Shr 24) And 255, RARef) Then Exit;
  If RSpec <> 0 Then
  Begin
    R := Clamp8(((C Shr 16) And 255) + ((Spe Shr 16) And 255));
    G := Clamp8(((C Shr 8) And 255) + ((Spe Shr 8) And 255));
    B := Clamp8((C And 255) + (Spe And 255));
    C := (C And LongInt($FF000000)) Or (R Shl 16) Or (G Shl 8) Or B;
  End;
  If (RFogOn <> 0) And (Fog < 255) Then
  Begin
    R := Mul8((C Shr 16) And 255, Fog) + Mul8((RFogC Shr 16) And 255,
                                               255 - Fog);
    G := Mul8((C Shr 8) And 255, Fog) + Mul8((RFogC Shr 8) And 255, 255 - Fog);
    B := Mul8(C And 255, Fog) + Mul8(RFogC And 255, 255 - Fog);
    C := (C And LongInt($FF000000)) Or (Clamp8(R) Shl 16) Or
         (Clamp8(G) Shl 8) Or Clamp8(B);
  End;
  CA := RBits + Y * RPitch + X * RBy;
  If RABl <> 0 Then
  Begin
    D := RtGet(CA);
    If (RSrc = 12) Or (RSrc = 13) Then
    Begin
      If RSrc = 12 Then FS := 5 Else FS := 6;
      FD := 11 - FS;
    End
    Else
    Begin
      FS := RSrc; FD := RDst;
    End;
    R := Clamp8(Mul8((C Shr 16) And 255, BlFac(FS, C, D, 16)) +
                Mul8((D Shr 16) And 255, BlFac(FD, C, D, 16)));
    G := Clamp8(Mul8((C Shr 8) And 255, BlFac(FS, C, D, 8)) +
                Mul8((D Shr 8) And 255, BlFac(FD, C, D, 8)));
    B := Clamp8(Mul8(C And 255, BlFac(FS, C, D, 0)) +
                Mul8(D And 255, BlFac(FD, C, D, 0)));
    A := Clamp8(Mul8((C Shr 24) And 255, BlFac(FS, C, D, 24)) +
                Mul8((D Shr 24) And 255, BlFac(FD, C, D, 24)));
    C := (A Shl 24) Or (R Shl 16) Or (G Shl 8) Or B;
  End;
  RtPut(CA, C);
  If (RZOn <> 0) And (RZWr <> 0) Then
  Begin
    If ZBy = 2 Then WrW(ZA, Z)
    Else WrL(ZA, (RdL(ZA) And LongInt($FF000000)) Or Z);
  End;
End;

{ ------------------------------------------------------------------ }
{ Triangle (sommets ecran)                                           }
{ ------------------------------------------------------------------ }

Const
  NAt = 14;  { z, 1/w, a, r, g, b, sr, sg, sb, fog, u0/w, v0/w, u1/w, v1/w }

Type
  TAt = Array[0..NAt - 1] Of Double;

Procedure VAttr(Var V : TVtx; Var At : TAt);
Begin
  At[0] := V.SZ; At[1] := V.RW;
  At[2] := V.A; At[3] := V.R; At[4] := V.G; At[5] := V.B;
  At[6] := V.SR; At[7] := V.SG; At[8] := V.SB; At[9] := V.F * 255;
  At[10] := V.U0 * V.RW; At[11] := V.V0 * V.RW;
  At[12] := V.U1 * V.RW; At[13] := V.V1 * V.RW;
End;

Function DRound(D : Double) : LongInt;
Begin
  If D > 2000000000 Then D := 2000000000;
  If D < -2000000000 Then D := -2000000000;
  DRound := Round(D);
End;

{ ------------------------------------------------------------------ }
{ Chemin rapide : segment de N points sans appel par point           }
{ ------------------------------------------------------------------ }
{ Cas courant (OpenGL et Direct3D a un etage) : cible 32 bits, une
  texture (16 ou 32 bits) prise telle quelle ou multipliee par la
  couleur diffuse, tests Z et alpha, brouillard et melange. D3DSetup
  decide (FastOn) ; sinon D3DPixel point par point. }

Var
  FastOn : Boolean;
  FastCol, FastAlp : LongInt;   { 0 diffuse, 1 texture, 2 tex x diffuse }
  FastPow : Boolean;            { texture en puissances de 2, repetee }

{ (A x B) / 255 exact pour A, B dans [0, 255] }
Function M255(T : LongInt) : LongInt;
Begin
  T := T + 128;
  M255 := (T + (T Shr 8)) Shr 8;
End;

{ facteur de melange F pour la composante C de la source (S) et de la
  destination (D) ; SA, DA : alphas }
Function FBl(F, S, D, SA, DA : LongInt) : LongInt;
Begin
  Case F Of
    1 : FBl := 0;
    2 : FBl := 255;
    3 : FBl := S;
    4 : FBl := 255 - S;
    5 : FBl := SA;
    6 : FBl := 255 - SA;
    7 : FBl := DA;
    8 : FBl := 255 - DA;
    9 : FBl := D;
    10 : FBl := 255 - D;
    11 : If SA < 255 - DA Then FBl := SA Else FBl := 255 - DA;
  Else
    FBl := 255;
  End;
End;

{ argument d'etage simple : 0 diffuse, 1 texture, 2 produit ; -1 sinon }
Function FastArg(Op, A1, A2 : LongInt) : LongInt;
Begin
  FastArg := -1;
  If (A1 And $30) <> 0 Then Exit;
  If (Op = 4) And ((A2 And $30) <> 0) Then Exit;
  A1 := A1 And 7; A2 := A2 And 7;
  If A1 = 1 Then A1 := 0;
  If A2 = 1 Then A2 := 0;
  Case Op Of
    2 :
      If A1 = 0 Then FastArg := 0
      Else If A1 = 2 Then FastArg := 1;
    3 :
      If A2 = 0 Then FastArg := 0
      Else If A2 = 2 Then FastArg := 1;
    4 :
      If ((A1 = 2) And (A2 = 0)) Or ((A1 = 0) And (A2 = 2)) Then
        FastArg := 2
      Else If (A1 = 0) And (A2 = 0) Then FastArg := 0;
  End;
End;

{ le chemin rapide convient-il a l'etat prepare par D3DSetup ? }
Procedure FastDecide;
Var K : LongInt;
Begin
  FastOn := False;
  If (RKind <> 5) And (RKind <> 6) Then Exit;
  If (D3G^.UseTSS = 0) Or (NStage > 1) Or TxOn[1] Or (RSpec <> 0) Then Exit;
  If (RZOn <> 0) And (ZBy <> 2) And (ZBy <> 4) Then Exit;
  If NStage = 0 Then
  Begin
    FastCol := 0; FastAlp := 0;
  End
  Else
  Begin
    FastCol := FastArg(TxCOp[0], TxCA1[0], TxCA2[0]);
    If TxAOp[0] <= 1 Then FastAlp := 0
    Else FastAlp := FastArg(TxAOp[0], TxAA1[0], TxAA2[0]);
    If (FastCol < 0) Or (FastAlp < 0) Then Exit;
  End;
  If Not TxOn[0] Then
  Begin
    If (FastCol <> 0) Or (FastAlp <> 0) Then Exit;
  End
  Else
  Begin
    K := TxKind[0];
    If (K <> 2) And (K <> 5) And (K <> 6) And (K <> 7) And (K <> 8) Then
      Exit;
    If (TxKeyOn[0] <> 0) And (RCKey <> 0) Then Exit;
    FastPow := ((TxW[0] And (TxW[0] - 1)) = 0) And
               ((TxH[0] And (TxH[0] - 1)) = 0) And
               (TxAddrU[0] <= 1) And (TxAddrV[0] <= 1);
  End;
  FastOn := True;
End;

{ coordonnee de texel (16.16) -> indice (repetition ou bord) }
Function FastTc(C, N, Md : LongInt) : LongInt;
Var X : LongInt;
Begin
  If C >= 0 Then X := C Shr 16 Else X := -1 - ((-C - 1) Shr 16);
  If (Md = 3) Or (Md = 4) Then
  Begin
    If X < 0 Then X := 0;
    If X >= N Then X := N - 1;
  End
  Else
  Begin
    X := X Mod N;
    If X < 0 Then X := X + N;
  End;
  FastTc := X;
End;

Procedure D3DSpan(X, Y, N, Z, DZ, CA, DCA, CR, DCR, CG, DCG, CB, DCB, FF,
                  DFF, IU, DU, IV, DV : LongInt);
Var K, RA, ZA, ZO, ZC, A, R, G, B, TA, TR, TG, TB, V, TX, TY, TBits,
    TPit, TWm, THm, Kd, DR, DG, DB, DA, F, Fs, Fd : LongInt;
    Ok : Boolean;
Begin
  RA := RBits + Y * RPitch + X * 4;
  ZA := 0;
  If RZOn <> 0 Then ZA := ZBits + Y * ZPitch + X * ZBy;
  TBits := TxBits[0]; TPit := TxPitch[0]; TWm := TxW[0] - 1;
  THm := TxH[0] - 1; Kd := TxKind[0];
  TA := 255; TR := 255; TG := 255; TB := 255;
  Fs := RSrc; Fd := RDst;
  If (Fs = 12) Or (Fs = 13) Then
  Begin
    If Fs = 12 Then Fs := 5 Else Fs := 6;
    Fd := 11 - Fs;
  End;
  For K := 1 To N Do
  Begin
    Ok := True;
    ZC := Z;
    If ZC < 0 Then ZC := 0;
    If ZC > $FFFFFF Then ZC := $FFFFFF;
    If RZOn <> 0 Then
    Begin
      If ZBy = 2 Then
      Begin
        ZO := RdW(ZA); ZC := ZC Shr 8;
      End
      Else ZO := RdL(ZA) And $FFFFFF;
      Case RZFn Of
        1 : Ok := False;
        2 : Ok := ZC < ZO;
        3 : Ok := ZC = ZO;
        4 : Ok := ZC <= ZO;
        5 : Ok := ZC > ZO;
        6 : Ok := ZC <> ZO;
        7 : Ok := ZC >= ZO;
      End;
    End;
    If Ok Then
    Begin
      A := CA Div 65536; R := CR Div 65536; G := CG Div 65536;
      B := CB Div 65536;
      If A < 0 Then A := 0 Else If A > 255 Then A := 255;
      If R < 0 Then R := 0 Else If R > 255 Then R := 255;
      If G < 0 Then G := 0 Else If G > 255 Then G := 255;
      If B < 0 Then B := 0 Else If B > 255 Then B := 255;
      If (FastCol <> 0) Or (FastAlp <> 0) Then
      Begin
        If FastPow Then
        Begin
          TX := (IU Shr 16) And TWm; TY := (IV Shr 16) And THm;
        End
        Else
        Begin
          TX := FastTc(IU, TWm + 1, TxAddrU[0]);
          TY := FastTc(IV, THm + 1, TxAddrV[0]);
        End;
        Case Kd Of
          2 :
          Begin
            V := RdW(TBits + TY * TPit + TX * 2);
            TR := (V Shr 11) And 31; TG := (V Shr 5) And 63; TB := V And 31;
            TR := (TR Shl 3) Or (TR Shr 2); TG := (TG Shl 2) Or (TG Shr 4);
            TB := (TB Shl 3) Or (TB Shr 2); TA := 255;
          End;
          7 :
          Begin
            V := RdW(TBits + TY * TPit + TX * 2);
            TR := (V Shr 10) And 31; TG := (V Shr 5) And 31; TB := V And 31;
            TR := (TR Shl 3) Or (TR Shr 2); TG := (TG Shl 3) Or (TG Shr 2);
            TB := (TB Shl 3) Or (TB Shr 2);
            If (V And $8000) <> 0 Then TA := 255 Else TA := 0;
          End;
          8 :
          Begin
            V := RdW(TBits + TY * TPit + TX * 2);
            TA := ((V Shr 12) And 15) * 17; TR := ((V Shr 8) And 15) * 17;
            TG := ((V Shr 4) And 15) * 17; TB := (V And 15) * 17;
          End;
        Else
          Begin
            V := RdL(TBits + TY * TPit + TX * 4);
            TR := (V Shr 16) And 255; TG := (V Shr 8) And 255; TB := V And 255;
            If Kd = 6 Then TA := (V Shr 24) And 255 Else TA := 255;
          End;
        End;
        If FastCol = 1 Then
        Begin
          R := TR; G := TG; B := TB;
        End
        Else If FastCol = 2 Then
        Begin
          R := M255(R * TR); G := M255(G * TG); B := M255(B * TB);
        End;
        If FastAlp = 1 Then A := TA
        Else If FastAlp = 2 Then A := M255(A * TA);
      End;
      If RATst <> 0 Then
        Case RAFn Of
          1 : Ok := False;
          2 : Ok := A < RARef;
          3 : Ok := A = RARef;
          4 : Ok := A <= RARef;
          5 : Ok := A > RARef;
          6 : Ok := A <> RARef;
          7 : Ok := A >= RARef;
        End;
      If Ok Then
      Begin
        If RFogOn <> 0 Then
        Begin
          F := FF Div 65536;
          If F < 0 Then F := 0;
          If F < 255 Then
          Begin
            R := M255(R * F + ((RFogC Shr 16) And 255) * (255 - F));
            G := M255(G * F + ((RFogC Shr 8) And 255) * (255 - F));
            B := M255(B * F + (RFogC And 255) * (255 - F));
          End;
        End;
        If RABl <> 0 Then
        Begin
          V := RdL(RA);
          DR := (V Shr 16) And 255; DG := (V Shr 8) And 255; DB := V And 255;
          If RKind = 6 Then DA := (V Shr 24) And 255 Else DA := 255;
          If (Fs = 5) And (Fd = 6) Then
          Begin
            R := M255(R * A + DR * (255 - A));
            G := M255(G * A + DG * (255 - A));
            B := M255(B * A + DB * (255 - A));
          End
          Else If (Fs = 2) And (Fd = 2) Then
          Begin
            R := R + DR; G := G + DG; B := B + DB;
          End
          Else
          Begin
            R := M255(R * FBl(Fs, R, DR, A, DA) + DR * FBl(Fd, R, DR, A, DA));
            G := M255(G * FBl(Fs, G, DG, A, DA) + DG * FBl(Fd, G, DG, A, DA));
            B := M255(B * FBl(Fs, B, DB, A, DA) + DB * FBl(Fd, B, DB, A, DA));
            A := M255(A * FBl(Fs, A, DA, A, DA) + DA * FBl(Fd, A, DA, A, DA));
          End;
          If R > 255 Then R := 255;
          If G > 255 Then G := 255;
          If B > 255 Then B := 255;
          If A > 255 Then A := 255;
        End;
        If RKind = 6 Then
          WrL(RA, (A Shl 24) Or (R Shl 16) Or (G Shl 8) Or B)
        Else WrL(RA, (R Shl 16) Or (G Shl 8) Or B);
        If (RZOn <> 0) And (RZWr <> 0) Then
        Begin
          If ZBy = 2 Then WrW(ZA, ZC)
          Else WrL(ZA, (RdL(ZA) And LongInt($FF000000)) Or ZC);
        End;
      End;
    End;
    RA := RA + 4;
    If RZOn <> 0 Then ZA := ZA + ZBy;
    Z := Z + DZ;
    CA := CA + DCA; CR := CR + DCR; CG := CG + DCG; CB := CB + DCB;
    FF := FF + DFF; IU := IU + DU; IV := IV + DV;
  End;
End;

Procedure D3DLine(Var P, Q : TVtx); Forward;
Procedure D3DPoint(Var P : TVtx); Forward;

Procedure D3DTri(Var V0, V1, V2 : TVtx);
Var A0, A1, A2, DX, DY, AT : TAt;
    X0, Y0, X1, Y1, X2, Y2, Ar, YA, YB, XL, XR, T, W, U, V, U2, VV2,
    UE, VE, UE2, VE3 : Double;
    K, Y, YBeg, YEnd, XS, XE, X, Z, DZ, C0, CR, CG, CB, CA, SR, SG, SB, FF,
    DCA, DCR, DCG, DCB, DSR, DSG, DSB, DFF, Seg, N, IU, IV, IU2, IV2,
    DU, DV2, DU2, DV3, Dif, Spe : LongInt;
    Flat : Boolean;
Begin
  X0 := V0.SX; Y0 := V0.SY; X1 := V1.SX; Y1 := V1.SY; X2 := V2.SX;
  Y2 := V2.SY;
  Ar := (X1 - X0) * (Y2 - Y0) - (X2 - X0) * (Y1 - Y0);
  If Abs(Ar) < 0.0001 Then Exit;
  If (RCull = 2) And (Ar > 0) Then Exit;
  If (RCull = 3) And (Ar < 0) Then Exit;
  If RFill = 1 Then
  Begin
    D3DPoint(V0); D3DPoint(V1); D3DPoint(V2);
    Exit;
  End;
  If RFill = 2 Then
  Begin
    D3DLine(V0, V1); D3DLine(V1, V2); D3DLine(V2, V0);
    Exit;
  End;
  Inc(D3G^.Tris);
  VAttr(V0, A0); VAttr(V1, A1); VAttr(V2, A2);
  Flat := RShade = 1;
  If Flat Then
    For K := 2 To 8 Do
    Begin
      A1[K] := A0[K]; A2[K] := A0[K];
    End;
  For K := 0 To NAt - 1 Do
  Begin
    DX[K] := ((A1[K] - A0[K]) * (Y2 - Y0) - (A2[K] - A0[K]) * (Y1 - Y0)) / Ar;
    DY[K] := ((A2[K] - A0[K]) * (X1 - X0) - (A1[K] - A0[K]) * (X2 - X0)) / Ar;
  End;
  YA := Y0; YB := Y0;
  If Y1 < YA Then YA := Y1;
  If Y2 < YA Then YA := Y2;
  If Y1 > YB Then YB := Y1;
  If Y2 > YB Then YB := Y2;
  YBeg := DRound(YA + 0.4999999);
  If YBeg < YA Then Inc(YBeg);
  YEnd := DRound(YB + 0.4999999) - 1;
  If YBeg < ClipT Then YBeg := ClipT;
  If YEnd > ClipB - 1 Then YEnd := ClipB - 1;
  For Y := YBeg To YEnd Do
  Begin
    { intersections des aretes avec la ligne Y }
    XL := 1E30; XR := -1E30;
    For K := 0 To 2 Do
    Begin
      Case K Of
        0 : Begin YA := Y0; T := X0; W := Y1; U := X1; End;
        1 : Begin YA := Y1; T := X1; W := Y2; U := X2; End;
      Else
        Begin YA := Y2; T := X2; W := Y0; U := X0; End;
      End;
      If YA = W Then Continue;
      { arete calculee depuis son sommet haut : la meme valeur pour les
        deux triangles qui la partagent (ni trou ni recouvrement) }
      If YA > W Then
      Begin
        V := YA; YA := W; W := V;
        V := T; T := U; U := V;
      End;
      If (Y < YA) Or (Y >= W) Then Continue;
      V := T + (Y - YA) * (U - T) / (W - YA);
      If V < XL Then XL := V;
      If V > XR Then XR := V;
    End;
    If XL > XR Then Continue;
    XS := DRound(XL + 0.4999999);
    If XS < XL Then Inc(XS);
    XE := DRound(XR + 0.4999999) - 1;
    If XS < ClipL Then XS := ClipL;
    If XE > ClipR - 1 Then XE := ClipR - 1;
    If XS > XE Then Continue;
    For K := 0 To NAt - 1 Do
      AT[K] := A0[K] + DX[K] * (XS - X0) + DY[K] * (Y - Y0);
    Z := DRound(AT[0] * 16777215); DZ := DRound(DX[0] * 16777215);
    CA := DRound(AT[2] * 65536); CR := DRound(AT[3] * 65536);
    CG := DRound(AT[4] * 65536); CB := DRound(AT[5] * 65536);
    SR := DRound(AT[6] * 65536); SG := DRound(AT[7] * 65536);
    SB := DRound(AT[8] * 65536); FF := DRound(AT[9] * 65536);
    DCA := DRound(DX[2] * 65536); DCR := DRound(DX[3] * 65536);
    DCG := DRound(DX[4] * 65536); DCB := DRound(DX[5] * 65536);
    DSR := DRound(DX[6] * 65536); DSG := DRound(DX[7] * 65536);
    DSB := DRound(DX[8] * 65536); DFF := DRound(DX[9] * 65536);
    X := XS;
    While X <= XE Do
    Begin
      { segment de 16 pixels : coordonnees de texture exactes aux bouts }
      N := Min(16, XE - X + 1);
      IU := 0; IV := 0; IU2 := 0; IV2 := 0; DU := 0; DV2 := 0; DU2 := 0;
      DV3 := 0;
      If TxOn[0] Or TxOn[1] Then
      Begin
        W := AT[1] + DX[1] * (X - XS);
        T := AT[1] + DX[1] * (X + N - XS);
        If Abs(W) < 1E-12 Then W := 1E-12;
        If Abs(T) < 1E-12 Then T := 1E-12;
        U := (AT[10] + DX[10] * (X - XS)) / W;
        V := (AT[11] + DX[11] * (X - XS)) / W;
        UE := (AT[10] + DX[10] * (X + N - XS)) / T;
        VE := (AT[11] + DX[11] * (X + N - XS)) / T;
        IU := DRound(U * TxW[0] * 65536 - 32768);
        IV := DRound(V * TxH[0] * 65536 - 32768);
        DU := (DRound(UE * TxW[0] * 65536 - 32768) - IU) Div N;
        DV2 := (DRound(VE * TxH[0] * 65536 - 32768) - IV) Div N;
        If TxOn[1] Then
        Begin
          U2 := (AT[12] + DX[12] * (X - XS)) / W;
          VV2 := (AT[13] + DX[13] * (X - XS)) / W;
          UE2 := (AT[12] + DX[12] * (X + N - XS)) / T;
          VE3 := (AT[13] + DX[13] * (X + N - XS)) / T;
          IU2 := DRound(U2 * TxW[1] * 65536 - 32768);
          IV2 := DRound(VV2 * TxH[1] * 65536 - 32768);
          DU2 := (DRound(UE2 * TxW[1] * 65536 - 32768) - IU2) Div N;
          DV3 := (DRound(VE3 * TxH[1] * 65536 - 32768) - IV2) Div N;
        End;
      End;
      If FastOn Then
      Begin
        D3DSpan(X, Y, N, Z, DZ, CA, DCA, CR, DCR, CG, DCG, CB, DCB, FF, DFF,
                IU, DU, IV, DV2);
        Z := Z + DZ * N;
        CA := CA + DCA * N; CR := CR + DCR * N; CG := CG + DCG * N;
        CB := CB + DCB * N; SR := SR + DSR * N; SG := SG + DSG * N;
        SB := SB + DSB * N; FF := FF + DFF * N;
        X := X + N;
      End
      Else
      For K := 0 To N - 1 Do
      Begin
        Dif := (Clamp8(CA Div 65536) Shl 24) Or (Clamp8(CR Div 65536) Shl 16)
               Or (Clamp8(CG Div 65536) Shl 8) Or Clamp8(CB Div 65536);
        Spe := (Clamp8(SR Div 65536) Shl 16) Or (Clamp8(SG Div 65536) Shl 8)
               Or Clamp8(SB Div 65536);
        C0 := Z;
        If C0 < 0 Then C0 := 0;
        If C0 > $FFFFFF Then C0 := $FFFFFF;
        D3DPixel(X, Y, C0, Dif, Spe, Clamp8(FF Div 65536), IU, IV, IU2, IV2);
        Z := Z + DZ;
        CA := CA + DCA; CR := CR + DCR; CG := CG + DCG; CB := CB + DCB;
        SR := SR + DSR; SG := SG + DSG; SB := SB + DSB; FF := FF + DFF;
        IU := IU + DU; IV := IV + DV2; IU2 := IU2 + DU2; IV2 := IV2 + DV3;
        Inc(X);
      End;
    End;
  End;
End;

{ Couleur diffuse et speculaire d'un sommet }
Function VDif(Var P : TVtx) : LongInt;
Begin
  VDif := (Clamp8(DRound(P.A)) Shl 24) Or (Clamp8(DRound(P.R)) Shl 16) Or
          (Clamp8(DRound(P.G)) Shl 8) Or Clamp8(DRound(P.B));
End;

Function VSpe(Var P : TVtx) : LongInt;
Begin
  VSpe := (Clamp8(DRound(P.SR)) Shl 16) Or (Clamp8(DRound(P.SG)) Shl 8) Or
          Clamp8(DRound(P.SB));
End;

Procedure D3DPoint(Var P : TVtx);
Var X, Y, Z : LongInt;
Begin
  X := DRound(P.SX); Y := DRound(P.SY);
  If (X < ClipL) Or (Y < ClipT) Or (X >= ClipR) Or (Y >= ClipB) Then Exit;
  Z := DRound(P.SZ * 16777215);
  If Z < 0 Then Z := 0;
  If Z > $FFFFFF Then Z := $FFFFFF;
  D3DPixel(X, Y, Z, VDif(P), VSpe(P), Clamp8(DRound(P.F * 255)),
           DRound(P.U0 * TxW[0] * 65536), DRound(P.V0 * TxH[0] * 65536),
           DRound(P.U1 * TxW[1] * 65536), DRound(P.V1 * TxH[1] * 65536));
End;

Procedure D3DLine(Var P, Q : TVtx);
Var N, I, X, Y, Z : LongInt; T, DXX, DYY : Double; M : TVtx;
Begin
  DXX := Q.SX - P.SX; DYY := Q.SY - P.SY;
  N := DRound(Abs(DXX));
  If DRound(Abs(DYY)) > N Then N := DRound(Abs(DYY));
  If N > 4096 Then N := 4096;
  If N < 1 Then N := 1;
  For I := 0 To N - 1 Do
  Begin
    T := I / N;
    M := P;
    M.SX := P.SX + DXX * T; M.SY := P.SY + DYY * T;
    M.SZ := P.SZ + (Q.SZ - P.SZ) * T;
    If RShade <> 1 Then
    Begin
      M.A := P.A + (Q.A - P.A) * T; M.R := P.R + (Q.R - P.R) * T;
      M.G := P.G + (Q.G - P.G) * T; M.B := P.B + (Q.B - P.B) * T;
    End;
    M.U0 := P.U0 + (Q.U0 - P.U0) * T; M.V0 := P.V0 + (Q.V0 - P.V0) * T;
    X := 0; Y := 0; Z := 0;
    D3DPoint(M);
  End;
End;

{ ------------------------------------------------------------------ }
{ Preparation d'un dessin : cible, Z, textures, etats                }
{ ------------------------------------------------------------------ }

Procedure TxBind(K, S : LongInt);
Var I, P, L, M : LongInt;
Begin
  TxOn[K] := False;
  If S = 0 Then Exit;
  { niveau de mipmap : le premier (le choix par triangle est fait par
    la taille de la cible) }
  TxS[K] := S;
  TxBits[K] := RdL(S + 76); TxPitch[K] := RdL(S + 72);
  TxW[K] := RdL(S + 64); TxH[K] := RdL(S + 68);
  TxBy[K] := SfBytes(S);
  TxKind[K] := RdL(S + 272);
  If (RdL(S + 88) = 16) And (RdL(S + 96) = $7C00) And
     (RdL(S + 108) = $8000) Then TxKind[K] := 7;
  If (RdL(S + 88) = 16) And (RdL(S + 96) = $F00) And
     (RdL(S + 108) = $F000) Then TxKind[K] := 8;
  TxKeyOn[K] := RdL(S + 148) And 1;
  TxKey[K] := RdL(S + 132);
  If (TxKind[K] = 1) And (K = 0) Then
  Begin
    P := RdL(S + 124);
    For I := 0 To 255 Do
    Begin
      If P <> 0 Then
      Begin
        L := P + 68 + I * 4;
        M := 255;
        If (RdL(P + 64) And $400) <> 0 Then M := RdB(L + 3);
        TxPal[I] := (M Shl 24) Or (RdB(L) Shl 16) Or (RdB(L + 1) Shl 8)
                    Or RdB(L + 2);
      End
      Else If D8Pal <> 0 Then
      Begin
        L := D8Pal + I * 4;
        TxPal[I] := (RdB(L + 3) Shl 24) Or (RdB(L) Shl 16) Or
                    (RdB(L + 1) Shl 8) Or RdB(L + 2);
      End
      Else
        TxPal[I] := LongInt($FF000000) Or (SysPal[I * 3] Shl 16) Or
                    (SysPal[I * 3 + 1] Shl 8) Or SysPal[I * 3 + 2];
    End;
  End;
  If (TxW[K] <= 0) Or (TxH[K] <= 0) Or (TxBits[K] = 0) Then Exit;
  TxOn[K] := True;
End;

Function D3DSetup : Boolean;
Var Z, K, S, T : LongInt;
Begin
  D3DSetup := False;
  RTs := D3G^.RT;
  If RTs = 0 Then Exit;
  RBits := RdL(RTs + 76); RPitch := RdL(RTs + 72);
  RBy := SfBytes(RTs); RKind := RdL(RTs + 272);
  RW := RdL(RTs + 64); RH := RdL(RTs + 68);
  ClipL := Max(0, D3G^.VX); ClipT := Max(0, D3G^.VY);
  ClipR := Min(RW, D3G^.VX + D3G^.VW); ClipB := Min(RH, D3G^.VY + D3G^.VH);
  If GlScOn Then
  Begin
    ClipL := Max(ClipL, GlScL); ClipT := Max(ClipT, GlScT);
    ClipR := Min(ClipR, GlScR); ClipB := Min(ClipB, GlScB);
  End;
  Z := D3G^.ZB;
  If Z = 0 Then Z := RdL(RTs + 120);
  RZOn := 0;
  If (D3G^.RS[rsZEnable] <> 0) And (Z <> 0) Then
  Begin
    RZOn := 1;
    ZBits := RdL(Z + 76); ZPitch := RdL(Z + 72);
    ZBy := SfBytes(Z);
    If ZBy = 3 Then RZOn := 0;
  End;
  RZWr := D3G^.RS[rsZWrite];
  RZFn := D3G^.RS[rsZFunc];
  If RZFn = 0 Then RZFn := 4;
  RShade := D3G^.RS[rsShade];
  RABl := D3G^.RS[rsABlend];
  RSrc := D3G^.RS[rsSrcBl]; RDst := D3G^.RS[rsDstBl];
  If RSrc = 0 Then RSrc := 2;
  If RDst = 0 Then RDst := 1;
  RATst := D3G^.RS[rsATest]; RAFn := D3G^.RS[rsAFunc];
  RARef := D3G^.RS[rsARef] And 255;
  RCKey := D3G^.RS[rsCKey];
  RFogOn := D3G^.RS[rsFog]; RFogC := D3G^.RS[rsFogColor];
  RSpec := D3G^.RS[rsSpecular];
  RTFac := D3G^.RS[rsTFactor];
  RCull := D3G^.RS[rsCull];
  RFill := D3G^.RS[rsFill];
  If RFill = 0 Then RFill := 3;
  NStage := 0;
  TxOn[0] := False; TxOn[1] := False;
  If D3G^.UseTSS <> 0 Then
  Begin
    For K := 0 To 1 Do
    Begin
      S := D3G^.Tex[K];
      TxCOp[K] := D3G^.TS[K * 32 + tsCOp];
      TxCA1[K] := D3G^.TS[K * 32 + tsCA1];
      TxCA2[K] := D3G^.TS[K * 32 + tsCA2];
      TxAOp[K] := D3G^.TS[K * 32 + tsAOp];
      TxAA1[K] := D3G^.TS[K * 32 + tsAA1];
      TxAA2[K] := D3G^.TS[K * 32 + tsAA2];
      TxAddrU[K] := D3G^.TS[K * 32 + tsAddrU];
      TxAddrV[K] := D3G^.TS[K * 32 + tsAddrV];
      If TxCOp[K] <= 1 Then Break;
      TxBind(K, S);
      If Not TxOn[K] Then
      Begin
        { etage sans texture : l'argument texture vaut le courant }
        T := TxCA1[K] And 7;
        If T = 2 Then TxCA1[K] := (TxCA1[K] And $30) Or 1;
        T := TxCA2[K] And 7;
        If T = 2 Then TxCA2[K] := (TxCA2[K] And $30) Or 1;
        T := TxAA1[K] And 7;
        If T = 2 Then TxAA1[K] := (TxAA1[K] And $30) Or 1;
        T := TxAA2[K] And 7;
        If T = 2 Then TxAA2[K] := (TxAA2[K] And $30) Or 1;
      End;
      NStage := K + 1;
    End;
  End
  Else
  Begin
    TxBind(0, D3G^.RS[rsTexHandle]);
    If D3G^.Tex[0] <> 0 Then TxBind(0, D3G^.Tex[0]);
    TxAddrU[0] := D3G^.RS[3]; TxAddrV[0] := TxAddrU[0];
    If TxAddrU[0] = 0 Then
    Begin
      TxAddrU[0] := 1; TxAddrV[0] := 1;
    End;
  End;
  If Not TxOn[0] Then
  Begin
    TxW[0] := 1; TxH[0] := 1;
  End;
  If Not TxOn[1] Then
  Begin
    TxW[1] := 1; TxH[1] := 1;
  End;
  FastDecide;
  D3DSetup := (ClipL < ClipR) And (ClipT < ClipB);
End;

{ ------------------------------------------------------------------ }
{ Primitives                                                         }
{ ------------------------------------------------------------------ }

Function VInside(Var V : TVtx) : Boolean;
Var P : LongInt;
Begin
  VInside := True;
  If V.CF = 0 Then Exit;
  For P := 0 To 5 Do
    If PlaneD(V, P) < 0 Then
    Begin
      VInside := False;
      Exit;
    End;
End;

Procedure D3DTriIdx(I0, I1, I2 : LongInt);
Var N, K : LongInt;
Begin
  If (DV^[I0].CF = 0) And (DV^[I1].CF = 0) And (DV^[I2].CF = 0) Then
  Begin
    D3DTri(DV^[I0], DV^[I1], DV^[I2]);
    Exit;
  End;
  If VInside(DV^[I0]) And VInside(DV^[I1]) And VInside(DV^[I2]) Then
  Begin
    DC[0] := DV^[I0]; DC[1] := DV^[I1]; DC[2] := DV^[I2];
    D3DProject(DC[0]); D3DProject(DC[1]); D3DProject(DC[2]);
    D3DTri(DC[0], DC[1], DC[2]);
    Exit;
  End;
  DC[0] := DV^[I0]; DC[1] := DV^[I1]; DC[2] := DV^[I2];
  N := D3DClipPoly(3);
  If N < 3 Then Exit;
  For K := 0 To N - 1 Do D3DProject(DC[K]);
  For K := 1 To N - 2 Do D3DTri(DC[0], DC[K], DC[K + 1]);
End;

Procedure D3DLineIdx(I0, I1 : LongInt);
Var A, B : TVtx; P : LongInt; DA, DB, T : Double; Ok : Boolean;
Begin
  A := DV^[I0]; B := DV^[I1];
  If (A.CF <> 0) Or (B.CF <> 0) Then
  Begin
    Ok := True;
    For P := 0 To 5 Do
    Begin
      DA := PlaneD(A, P); DB := PlaneD(B, P);
      If (DA < 0) And (DB < 0) Then Ok := False
      Else If DA < 0 Then
      Begin
        T := DA / (DA - DB); VLerp(A, A, B, T);
      End
      Else If DB < 0 Then
      Begin
        T := DB / (DB - DA); VLerp(B, B, A, T);
      End;
    End;
    If Not Ok Then Exit;
    D3DProject(A); D3DProject(B);
  End;
  D3DLine(A, B);
End;

Procedure D3DPointIdx(I : LongInt);
Var A : TVtx;
Begin
  A := DV^[I];
  If Not VInside(A) Then Exit;
  D3DProject(A);
  D3DPoint(A);
End;

{ Indice K de la liste (Idx : adresse, Sz 2 ou 4 octets ; 0 : direct) }
Function IdxAt(Idx, Sz, K : LongInt) : LongInt;
Begin
  If Idx = 0 Then IdxAt := K
  Else If Sz = 4 Then IdxAt := RdL(Idx + K * 4)
  Else IdxAt := RdW(Idx + K * 2);
End;

{ Dessiner N elements de type Pt (sommets deja traites dans DV) }
Procedure D3DPrims(Pt, Idx, Sz, N, NV : LongInt);
Var I, A, B, C : LongInt;
Begin
  If Not D3DSetup Then Exit;
  Case Pt Of
    1 :
      For I := 0 To N - 1 Do
      Begin
        A := IdxAt(Idx, Sz, I);
        If A < NV Then D3DPointIdx(A);
      End;
    2 :
      For I := 0 To N Div 2 - 1 Do
      Begin
        A := IdxAt(Idx, Sz, I * 2); B := IdxAt(Idx, Sz, I * 2 + 1);
        If (A < NV) And (B < NV) Then D3DLineIdx(A, B);
      End;
    3 :
      For I := 0 To N - 2 Do
      Begin
        A := IdxAt(Idx, Sz, I); B := IdxAt(Idx, Sz, I + 1);
        If (A < NV) And (B < NV) Then D3DLineIdx(A, B);
      End;
    4 :
      For I := 0 To N Div 3 - 1 Do
      Begin
        A := IdxAt(Idx, Sz, I * 3); B := IdxAt(Idx, Sz, I * 3 + 1);
        C := IdxAt(Idx, Sz, I * 3 + 2);
        If (A < NV) And (B < NV) And (C < NV) Then D3DTriIdx(A, B, C);
      End;
    5 :
      For I := 0 To N - 3 Do
      Begin
        A := IdxAt(Idx, Sz, I); B := IdxAt(Idx, Sz, I + 1);
        C := IdxAt(Idx, Sz, I + 2);
        If (A < NV) And (B < NV) And (C < NV) Then
        Begin
          If Odd(I) Then D3DTriIdx(A, C, B) Else D3DTriIdx(A, B, C);
        End;
      End;
    6 :
      For I := 1 To N - 2 Do
      Begin
        A := IdxAt(Idx, Sz, 0); B := IdxAt(Idx, Sz, I);
        C := IdxAt(Idx, Sz, I + 1);
        If (A < NV) And (B < NV) And (C < NV) Then D3DTriIdx(A, B, C);
      End;
  End;
End;

{ Dessin complet : sommets (Src, FVF) puis primitives }
Procedure D3DDraw(Pt, Fvf, Src, NV, Idx, Sz, NI, Fl : LongInt);
Var Lit : Boolean;
Begin
  If (Src = 0) Or (NV <= 0) Then Exit;
  FvfParse(Fvf);
  If D3DStrideOvr > 0 Then VFStride := D3DStrideOvr;
  Lit := (D3G^.RS[rsLighting] <> 0) And (VFNrm >= 0) And (VFRhw = 0);
  If (D3G^.Ver <= 3) And (VFNrm >= 0) And (VFRhw = 0) Then
    Lit := (Fl And $10) = 0;
  If Lit Then D3DLightsView;
  D3DProcess(Src, NV, Lit);
  If Idx = 0 Then NI := NV;
  D3DPrims(Pt, Idx, Sz, NI, NV);
End;

{ Effacer : cible (couleur), Z (valeur 0..1) dans les rectangles }
Procedure D3DClear(N, Rects, Fl, Color, ZV : LongInt);
Var I, L, T, R, B, V, Z, ZS : LongInt;
Begin
  If D3G^.RT = 0 Then Exit;
  Z := D3G^.ZB;
  If Z = 0 Then Z := RdL(D3G^.RT + 120);
  If N = 0 Then N := 1;
  For I := 0 To N - 1 Do
  Begin
    If Rects <> 0 Then
    Begin
      L := RdL(Rects + I * 16); T := RdL(Rects + I * 16 + 4);
      R := RdL(Rects + I * 16 + 8); B := RdL(Rects + I * 16 + 12);
    End
    Else
    Begin
      L := D3G^.VX; T := D3G^.VY;
      R := D3G^.VX + D3G^.VW; B := D3G^.VY + D3G^.VH;
    End;
    If (Fl And 1) <> 0 Then
    Begin
      V := SfFromRGB(D3G^.RT, Color);
      SfFill(D3G^.RT, L, T, R, B, V);
    End;
    If ((Fl And 2) <> 0) And (Z <> 0) Then
    Begin
      ZS := SfBytes(Z);
      If ZS = 2 Then V := DRound(FlL(ZV) * 65535)
      Else V := DRound(FlL(ZV) * 16777215);
      SfFill(Z, L, T, R, B, V);
    End;
  End;
End;

{ ------------------------------------------------------------------ }
{ OpenGL 1.1 logiciel (OPENGL32.DLL) sur le moteur de Direct3D       }
{ ------------------------------------------------------------------ }
{ Un contexte (wglCreateContext) possede un etat TD3D, un tampon de
  couleur 32 bits (XRGB) et un tampon Z de 24 bits a la taille de la
  zone client de la fenetre. Les sommets (glBegin/glEnd, tableaux de
  sommets) sont transformes ici (matrices GL, en colonnes : la meme
  memoire que les matrices "lignes" de Direct3D), eclaires par
  D3DLight, puis passes en coordonnees de decoupage a D3DPrims qui
  decoupe, projette et rasterise. La profondeur GL [-w, w] est ramenee
  a [0, w]. SwapBuffers copie le tampon dans la fenetre. Les textures
  sont des surfaces internes (32 bits ARGB ou 16 bits selon le format
  interne demande), sans mipmaps (niveau 0 seulement). }

Const
  GlMaxTex = 4096;              { noms de textures }
  GlTexSz = 48;                 { +0 utilise, +4 surface, +8 L, +12 H,
                                  +16 enveloppe S, +20 T, +24 format,
                                  +28 alpha }
  GL_TEXTURE_2D = $0DE1;

Type
  TGLLt = Record
    Amb, Dif, Spe, Pos : Array[0..3] Of Double;
    SDir : Array[0..2] Of Double;
    SExp, SCut, A0, A1, A2 : Double;
  End;
  { etat sauvegarde par glPushAttrib (en bloc) }
  TGLA = Record
    TexOn : Array[0..1] Of LongInt;
    DepOn, DepFn, DepMsk, BlOn, BlSrc, BlDst, AlOn, AlFn : LongInt;
    AlRef : Double;
    CullOn, CullMd, Front, Shade, PolyMd : LongInt;
    ScOn, ScX, ScY, ScW, ScH, VpX, VpY, VpW, VpH : LongInt;
    DNear, DFar : Double;
    FogOn, FogMd : LongInt;
    FogS, FogE, FogD : Double;
    FogC : Array[0..3] Of Double;
    LitOn, CmOn, CmMode, NormOn : LongInt;
    LtOn : Array[0..7] Of LongInt;
    Lt : Array[0..7] Of TGLLt;
    MAmb, MDif, MSpe, MEmi, LMAmb : Array[0..3] Of Double;
    MShin : Double;
    Env : Array[0..1] Of LongInt;
    EnvC : Array[0..3] Of Double;
    Bound : Array[0..1] Of LongInt;
    ActTex : LongInt;
    ClrC : Array[0..3] Of Double;
    ClrZ : Double;
    POfOn : LongInt;
    POfF, POfU : Double;
    TgOn, TgMd : Array[0..3] Of LongInt;
    TgOP, TgEP : Array[0..15] Of Double;
    Col : Array[0..3] Of Double;
    Nrm : Array[0..2] Of Double;
    Tc0, Tc1 : Array[0..3] Of Double;
    PtSz, LnW : Double;
    DitOn, CMask : LongInt;
  End;
  { etat client (tableaux de sommets, stockage des pixels) }
  TGLCA = Record
    AOn, ASz, ATy, ASt, APt : Array[0..5] Of LongInt;
    CliTex, UnpA, UnpRL, PackA : LongInt;
  End;
  TGLC = Record
    S : TGLA;
    AStk : Array[0..7] Of TGLA;
    ASp : LongInt;
    CA : TGLCA;
    CStk : Array[0..3] Of TGLCA;
    CSp : LongInt;
    D3, Wnd, Dc, BW, BH, RT, ZB : LongInt;
    MMode, MVTop, PRTop, TXTop : LongInt;
    MV : Array[0..31] Of TMat;
    PR : Array[0..3] Of TMat;
    TX : Array[0..3] Of TMat;
    MVP, PZ : TMat;
    MOk, TxId : Boolean;
    Err, Prim, InBeg, Made : LongInt;
    RPos : Array[0..3] Of Double;
  End;
  PGLC = ^TGLC;
  T4D = Array[0..3] Of Double;
  T4L = Array[0..3] Of LongInt;

Var
  Gc : PGLC;                    { contexte courant (nil : aucun) }
  GcA : LongInt;                { son adresse }
  GlProc : LongInt;             { processus qui utilise OpenGL }
  GlCtx : Array[0..15] Of LongInt;
  GV : PVtxArr;                 { sommets de la primitive en cours }
  GVCap, GVN : LongInt;
  GIx, GIxCap : LongInt;        { indices des primitives (32 bits) }
  GSq, GSqCap : LongInt;        { suite des sommets (glDrawElements) }
  GlTexT : LongInt;             { table des textures (GlMaxTex x 48) }
  GlStrs : Array[0..3] Of LongInt;
  GlTodoS : String;

Var
  GlRing : Array[0..63] Of LongInt;   { derniers appels (numeros) }
  GlRingP : LongInt;

Var
  GlTop0, GlTopBad : LongInt;

{ appel numero N ; la pile du coprocesseur doit etre vide aux appels
  (sommet inchange depuis l'appel precedent) }
Procedure GlTr(N : LongInt);
Var S : LongInt;
Begin
  asm
    xor eax,eax
    fnstsw ax
    mov S,eax
  end;
  S := (S Shr 11) And 7;
  If GlRingP = 0 Then GlTop0 := S
  Else If (S <> GlTop0) And (GlTopBad < 8) Then
  Begin
    Inc(GlTopBad);
    KLog('OpenGL : pile FPU ' + IntStr(GlTop0) + ' -> ' + IntStr(S) +
         ' avant l''appel ' + IntStr(N) + ', apres ' +
         IntStr(GlRing[(GlRingP - 1) And 63]));
    GlTop0 := S;
  End;
  GlRing[GlRingP And 63] := N;
  Inc(GlRingP);
End;

Procedure GlDumpRing;
Var I : LongInt; S : String;
Begin
  If GlRingP = 0 Then Exit;
  S := 'OpenGL : derniers appels';
  For I := Max(0, GlRingP - 24) To GlRingP - 1 Do
    S := S + ' ' + IntStr(GlRing[I And 63]);
  KLog(S);
End;

Function DblOf(Lo, Hi : LongInt) : Double;
Var D : Double;
Begin
  WrL(LongInt(@D), Lo);
  WrL(LongInt(@D) + 4, Hi);
  DblOf := D;
End;

Function DbM(A : LongInt) : Double;
Begin
  DbM := DblOf(RdL(A), RdL(A + 4));
End;

Procedure DbPut(A : LongInt; D : Double);
Begin
  WrL(A, RdL(LongInt(@D)));
  WrL(A + 4, RdL(LongInt(@D) + 4));
End;

Function Cl01(D : Double) : Double;
Begin
  If D < 0 Then D := 0;
  If D > 1 Then D := 1;
  Cl01 := D;
End;

{ couleur (0..1) -> ARGB }
Function GlArgb(R, G, B, A : Double) : LongInt;
Begin
  GlArgb := (DRound(Cl01(A) * 255) Shl 24) Or
            (DRound(Cl01(R) * 255) Shl 16) Or
            (DRound(Cl01(G) * 255) Shl 8) Or DRound(Cl01(B) * 255);
End;

Procedure GlErr(E : LongInt);
Begin
  If (GcA <> 0) And (Gc^.Err = 0) Then Gc^.Err := E;
End;

{ fonction non realisee : signalee une fois dans le journal }
Procedure GlTodo(Nm : String);
Begin
  If Pos(' ' + Nm + ' ', GlTodoS) > 0 Then Exit;
  If Length(GlTodoS) + Length(Nm) < 240 Then
    GlTodoS := GlTodoS + Nm + ' ';
  KLog('OpenGL : ' + Nm + ' non realise');
End;

{ ------------------------------------------------------------------ }
{ Surfaces internes (memes champs que les surfaces DirectDraw)       }
{ ------------------------------------------------------------------ }

Function GlSurf(W, H, Bpp, RM, GM, BM, AM : LongInt) : LongInt;
Var S, P : LongInt;
Begin
  GlSurf := 0;
  If W < 1 Then W := 1;
  If H < 1 Then H := 1;
  S := KAlloc(300);
  If S = 0 Then Exit;
  FillMem(S, 300, 0);
  P := ((W * ((Bpp + 7) Div 8)) + 3) And Not 3;
  WrL(S + 64, W); WrL(S + 68, H); WrL(S + 72, P);
  WrL(S + 76, KAlloc(P * H + 16));
  If RdL(S + 76) = 0 Then
  Begin
    KFree(S);
    Exit;
  End;
  FillMem(RdL(S + 76), P * H, 0);
  WrL(S + 88, Bpp); WrL(S + 92, $40);
  If AM <> 0 Then WrL(S + 92, $41);
  WrL(S + 96, RM); WrL(S + 100, GM); WrL(S + 104, BM);
  WrL(S + 108, AM);
  SfInfo(S);
  GlSurf := S;
End;

Procedure GlSurfFree(S : LongInt);
Begin
  If S = 0 Then Exit;
  If RdL(S + 76) <> 0 Then KFree(RdL(S + 76));
  KFree(S);
End;

{ tampons du contexte a la taille de la zone client }
Procedure GlBuffers;
Var R : Array[0..3] Of LongInt; W, H : LongInt;
Begin
  W := 0; H := 0;
  If Gc^.Wnd <> 0 Then
  Begin
    WinQueryWindowRect(Gc^.Wnd, LongInt(@R));
    W := R[2] - R[0]; H := R[3] - R[1];
  End;
  If (W <= 0) Or (H <= 0) Then
  Begin
    W := WinQuerySysValue(1, 20); H := WinQuerySysValue(1, 21);
  End;
  If (Gc^.RT <> 0) And (W = Gc^.BW) And (H = Gc^.BH) Then Exit;
  GlSurfFree(Gc^.RT); GlSurfFree(Gc^.ZB);
  Gc^.RT := GlSurf(W, H, 32, $FF0000, $FF00, $FF, 0);
  Gc^.ZB := GlSurf(W, H, 32, 0, 0, 0, 0);
  If Gc^.ZB <> 0 Then
  Begin
    WrL(Gc^.ZB + 92, $400);
    FillMem(RdL(Gc^.ZB + 76), RdL(Gc^.ZB + 72) * H, -1);
  End;
  Gc^.BW := W; Gc^.BH := H;
  Move(Gc^.D3, D3G, 4);
  D3G^.RT := Gc^.RT; D3G^.ZB := Gc^.ZB;
  KLog('OpenGL : tampons ' + IntStr(W) + 'x' + IntStr(H));
End;

{ ------------------------------------------------------------------ }
{ Matrices                                                           }
{ ------------------------------------------------------------------ }

{ matrice courante (selon glMatrixMode) : adresse }
Function GlCurM : LongInt;
Begin
  Case Gc^.MMode Of
    $1701 : GlCurM := LongInt(@Gc^.PR[Gc^.PRTop]);
    $1702 : GlCurM := LongInt(@Gc^.TX[Gc^.TXTop]);
  Else
    GlCurM := LongInt(@Gc^.MV[Gc^.MVTop]);
  End;
End;

Procedure GlMChanged;
Begin
  Gc^.MOk := False;
End;

{ courante := M x courante (ordre de Direct3D : M appliquee d'abord) }
Procedure GlMulM(Var M : TMat);
Var C : TMat; A : LongInt;
Begin
  A := GlCurM;
  MoveMem(A, LongInt(@C), SizeOf(TMat));
  MatMul(C, M, C);
  MoveMem(LongInt(@C), A, SizeOf(TMat));
  GlMChanged;
End;

Procedure GlLoadM(Var M : TMat);
Begin
  MoveMem(LongInt(@M), GlCurM, SizeOf(TMat));
  GlMChanged;
End;

Function MatIsId(Var M : TMat) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := True;
  For I := 0 To 15 Do
    If (I Mod 5 = 0) Then
    Begin
      If M[I] <> 1 Then R := False;
    End
    Else If M[I] <> 0 Then R := False;
  MatIsId := R;
End;

{ MVP = MV x P x (z' = (z + w) / 2) }
Procedure GlMats;
Var Z : TMat;
Begin
  If Gc^.MOk Then Exit;
  MatId(Z);
  Z[10] := 0.5; Z[14] := 0.5;
  MatMul(Gc^.PZ, Gc^.PR[Gc^.PRTop], Z);
  MatMul(Gc^.MVP, Gc^.MV[Gc^.MVTop], Gc^.PZ);
  Gc^.TxId := MatIsId(Gc^.TX[Gc^.TXTop]);
  Gc^.MOk := True;
End;

{ ------------------------------------------------------------------ }
{ Etat -> Direct3D                                                   }
{ ------------------------------------------------------------------ }

Function GlCmp(F : LongInt) : LongInt;
Begin
  If (F >= $200) And (F <= $207) Then GlCmp := F - $200 + 1
  Else GlCmp := 8;
End;

Function GlBlF(F : LongInt) : LongInt;
Begin
  Case F Of
    0 : GlBlF := 1;
    1 : GlBlF := 2;
    $300..$308 : GlBlF := F - $300 + 3;
  Else
    GlBlF := 2;
  End;
End;

Function GlTexEnt(N : LongInt) : LongInt;
Begin
  GlTexEnt := 0;
  If (GlTexT = 0) Or (N < 0) Or (N >= GlMaxTex) Then Exit;
  GlTexEnt := GlTexT + N * GlTexSz;
End;

{ etage K de Direct3D d'apres l'unite de texture K }
Procedure GlStage(K : LongInt; On : Boolean);
Var T, E, B, Al : LongInt;
Begin
  B := K * 32;
  T := 0;
  If On And (Gc^.S.TexOn[K] <> 0) Then
  Begin
    E := GlTexEnt(Gc^.S.Bound[K]);
    If (E <> 0) And (RdL(E + 4) <> 0) Then T := RdL(E + 4);
  End;
  D3G^.Tex[K] := T;
  If T = 0 Then
  Begin
    If K = 0 Then
    Begin
      D3G^.TS[B + tsCOp] := 2; D3G^.TS[B + tsCA1] := 0;
      D3G^.TS[B + tsAOp] := 2; D3G^.TS[B + tsAA1] := 0;
    End
    Else
    Begin
      D3G^.TS[B + tsCOp] := 1; D3G^.TS[B + tsAOp] := 1;
    End;
    Exit;
  End;
  If K = 0 Then Al := 0 Else Al := 1;
  E := GlTexEnt(Gc^.S.Bound[K]);
  If RdL(E + 16) = $2901 Then D3G^.TS[B + tsAddrU] := 1
  Else D3G^.TS[B + tsAddrU] := 3;
  If RdL(E + 20) = $2901 Then D3G^.TS[B + tsAddrV] := 1
  Else D3G^.TS[B + tsAddrV] := 3;
  D3G^.TS[B + tsCA1] := 2; D3G^.TS[B + tsCA2] := Al;
  D3G^.TS[B + tsAA1] := 2; D3G^.TS[B + tsAA2] := Al;
  Case Gc^.S.Env[K] Of
    $1E01 :
    Begin
      { REPLACE }
      D3G^.TS[B + tsCOp] := 2;
      If RdL(E + 28) <> 0 Then D3G^.TS[B + tsAOp] := 2
      Else
      Begin
        D3G^.TS[B + tsAOp] := 2; D3G^.TS[B + tsAA1] := Al;
      End;
    End;
    $2101 :
    Begin
      { DECAL : texture melangee selon son alpha }
      D3G^.TS[B + tsCOp] := 13;
      D3G^.TS[B + tsAOp] := 2; D3G^.TS[B + tsAA1] := Al;
    End;
    $0104 :
    Begin
      { ADD }
      D3G^.TS[B + tsCOp] := 7; D3G^.TS[B + tsAOp] := 4;
    End;
  Else
    Begin
      { MODULATE (et BLEND, approche) }
      D3G^.TS[B + tsCOp] := 4; D3G^.TS[B + tsAOp] := 4;
    End;
  End;
End;

{ lumieres et materiau GL -> Direct3D (positions deja dans l'oeil) }
Procedure GlLights;
Var I, K : LongInt; C : Double;
Begin
  For I := 0 To 15 Do D3G^.Lt[I].On := 0;
  For I := 0 To 7 Do
  Begin
    If Gc^.S.LtOn[I] = 0 Then Continue;
    D3G^.Lt[I].On := 1;
    For K := 0 To 3 Do
    Begin
      D3G^.Lt[I].Dif[K] := Gc^.S.Lt[I].Dif[K];
      D3G^.Lt[I].Spe[K] := Gc^.S.Lt[I].Spe[K];
      D3G^.Lt[I].Amb[K] := Gc^.S.Lt[I].Amb[K];
    End;
    If Gc^.S.Lt[I].Pos[3] = 0 Then
    Begin
      D3G^.Lt[I].Typ := 3;
      For K := 0 To 2 Do D3G^.Lt[I].Dir[K] := -Gc^.S.Lt[I].Pos[K];
    End
    Else
    Begin
      C := Gc^.S.Lt[I].Pos[3];
      For K := 0 To 2 Do D3G^.Lt[I].Pos[K] := Gc^.S.Lt[I].Pos[K] / C;
      D3G^.Lt[I].Typ := 1;
      If Gc^.S.Lt[I].SCut < 180 Then
      Begin
        D3G^.Lt[I].Typ := 2;
        For K := 0 To 2 Do D3G^.Lt[I].Dir[K] := Gc^.S.Lt[I].SDir[K];
        D3G^.Lt[I].Ph := Gc^.S.Lt[I].SCut * 2 * 3.14159265358979 / 180;
        D3G^.Lt[I].Th := D3G^.Lt[I].Ph * 0.8;
      End;
    End;
    D3G^.Lt[I].A0 := Gc^.S.Lt[I].A0; D3G^.Lt[I].A1 := Gc^.S.Lt[I].A1;
    D3G^.Lt[I].A2 := Gc^.S.Lt[I].A2;
    D3G^.Lt[I].Rng := 0;
  End;
  For K := 0 To 3 Do
  Begin
    D3G^.Mt[K] := Gc^.S.MDif[K]; D3G^.Mt[4 + K] := Gc^.S.MAmb[K];
    D3G^.Mt[8 + K] := Gc^.S.MSpe[K]; D3G^.Mt[12 + K] := Gc^.S.MEmi[K];
  End;
  D3G^.Mt[16] := Gc^.S.MShin;
  D3G^.RS[rsAmbient] := GlArgb(Gc^.S.LMAmb[0], Gc^.S.LMAmb[1],
                               Gc^.S.LMAmb[2], 1);
  D3G^.RS[rsColorVtx] := Gc^.S.CmOn;
  D3G^.RS[rsDifSrc] := 0; D3G^.RS[rsAmbSrc] := 0; D3G^.RS[rsSpcSrc] := 0;
  If (Gc^.S.CmMode = $1201) Or (Gc^.S.CmMode = $1602) Then
    D3G^.RS[rsDifSrc] := 1;
  If (Gc^.S.CmMode = $1200) Or (Gc^.S.CmMode = $1602) Then
    D3G^.RS[rsAmbSrc] := 1;
  MatId(D3G^.Viw);
  D3DLightsView;
End;

{ choisir le peripherique du contexte et lui donner l'etat GL }
Procedure GlSync;
Var C : LongInt;
Begin
  Move(Gc^.D3, D3G, 4);
  D3G^.RT := Gc^.RT; D3G^.ZB := Gc^.ZB;
  D3G^.UseTSS := 1;
  D3G^.VX := Gc^.S.VpX; D3G^.VY := Gc^.BH - (Gc^.S.VpY + Gc^.S.VpH);
  D3G^.VW := Max(1, Gc^.S.VpW); D3G^.VH := Max(1, Gc^.S.VpH);
  { centres des pixels a +0,5 comme dans OpenGL }
  D3G^.ClX := -1 + 1 / D3G^.VW; D3G^.ClW := 2;
  D3G^.ClY := 1 - 1 / D3G^.VH; D3G^.ClH := 2;
  D3G^.VMinZ := Gc^.S.DNear; D3G^.VMaxZ := Gc^.S.DFar;
  D3G^.RS[rsZEnable] := Gc^.S.DepOn;
  D3G^.RS[rsZWrite] := Gc^.S.DepMsk;
  D3G^.RS[rsZFunc] := GlCmp(Gc^.S.DepFn);
  D3G^.RS[rsABlend] := Gc^.S.BlOn;
  D3G^.RS[rsSrcBl] := GlBlF(Gc^.S.BlSrc);
  D3G^.RS[rsDstBl] := GlBlF(Gc^.S.BlDst);
  D3G^.RS[rsATest] := Gc^.S.AlOn;
  D3G^.RS[rsAFunc] := GlCmp(Gc^.S.AlFn);
  D3G^.RS[rsARef] := DRound(Cl01(Gc^.S.AlRef) * 255);
  C := 1;
  If Gc^.S.CullOn <> 0 Then
  Begin
    { face rejetee : sens horaire (GL) -> 2, antihoraire -> 3 }
    If (Gc^.S.CullMd = $405) = (Gc^.S.Front = $901) Then C := 2 Else C := 3;
    If Gc^.S.CullMd = $408 Then C := 1;
  End;
  D3G^.RS[rsCull] := C;
  If Gc^.S.Shade = $1D00 Then D3G^.RS[rsShade] := 1
  Else D3G^.RS[rsShade] := 2;
  Case Gc^.S.PolyMd Of
    $1B00 : D3G^.RS[rsFill] := 1;
    $1B01 : D3G^.RS[rsFill] := 2;
  Else
    D3G^.RS[rsFill] := 3;
  End;
  D3G^.RS[rsFog] := Gc^.S.FogOn;
  D3G^.RS[rsFogColor] := GlArgb(Gc^.S.FogC[0], Gc^.S.FogC[1],
                                Gc^.S.FogC[2], 1);
  Case Gc^.S.FogMd Of
    $800 : D3G^.RS[rsFogVtx] := 1;
    $801 : D3G^.RS[rsFogVtx] := 2;
  Else
    D3G^.RS[rsFogVtx] := 3;
  End;
  D3G^.RS[rsFogStart] := LFl(Gc^.S.FogS);
  D3G^.RS[rsFogEnd] := LFl(Gc^.S.FogE);
  D3G^.RS[rsFogDens] := LFl(Gc^.S.FogD);
  D3G^.RS[rsLighting] := Gc^.S.LitOn;
  D3G^.RS[rsSpecular] := Gc^.S.LitOn;
  D3G^.RS[rsCKey] := 0;
  D3G^.RS[rsTFactor] := GlArgb(Gc^.S.EnvC[0], Gc^.S.EnvC[1], Gc^.S.EnvC[2],
                               Gc^.S.EnvC[3]);
  GlStage(0, True);
  GlStage(1, D3G^.Tex[0] <> 0);
  If Gc^.S.LitOn <> 0 Then GlLights;
  GlScOn := Gc^.S.ScOn <> 0;
  If GlScOn Then
  Begin
    GlScL := Gc^.S.ScX; GlScR := Gc^.S.ScX + Gc^.S.ScW;
    GlScT := Gc^.BH - (Gc^.S.ScY + Gc^.S.ScH); GlScB := Gc^.BH - Gc^.S.ScY;
  End;
End;

{ ------------------------------------------------------------------ }
{ Sommets                                                            }
{ ------------------------------------------------------------------ }

Procedure GlGrowV(N : LongInt);
Var P, Q, H, C : LongInt;
Begin
  If N <= GVCap Then Exit;
  C := Max(N + N Div 2, 1024);
  P := KAlloc(C * SizeOf(TVtx) + 16);
  If P = 0 Then Exit;
  If GVCap > 0 Then
  Begin
    Q := 0;
    Move(GV, Q, 4);
    MoveMem(Q, P, GVN * SizeOf(TVtx));
    KFree(Q);
  End;
  Move(P, GV, 4);
  GVCap := C;
End;

Procedure GlGrowI(N : LongInt);
Var P, H, C : LongInt;
Begin
  If N <= GIxCap Then Exit;
  C := Max(N + N Div 2, 4096);
  P := KAlloc(C * 4 + 16);
  If P = 0 Then Exit;
  If GIx <> 0 Then KFree(GIx);
  GIx := P; GIxCap := C;
End;

Procedure GlGrowS(N : LongInt);
Var P, H, C : LongInt;
Begin
  If N <= GSqCap Then Exit;
  C := Max(N + N Div 2, 4096);
  P := KAlloc(C * 4 + 16);
  If P = 0 Then Exit;
  If GSq <> 0 Then KFree(GSq);
  GSq := P; GSqCap := C;
End;

{ coordonnees de texture generees (unite 0) : composante C (0 S .. 3 Q) }
Function GlTexGen(C : LongInt; Var Ob, Ey, Nr : T4D;
                  Def : Double) : Double;
Var M : LongInt; X, Y, Z, D, NE, RX, RY, RZ : Double;
Begin
  GlTexGen := Def;
  If Gc^.S.TgOn[C] = 0 Then Exit;
  M := Gc^.S.TgMd[C];
  Case M Of
    $2401 :
      GlTexGen := Gc^.S.TgOP[C * 4] * Ob[0] + Gc^.S.TgOP[C * 4 + 1] * Ob[1] +
                  Gc^.S.TgOP[C * 4 + 2] * Ob[2] + Gc^.S.TgOP[C * 4 + 3] * Ob[3];
    $2400 :
      GlTexGen := Gc^.S.TgEP[C * 4] * Ey[0] + Gc^.S.TgEP[C * 4 + 1] * Ey[1] +
                  Gc^.S.TgEP[C * 4 + 2] * Ey[2] + Gc^.S.TgEP[C * 4 + 3] * Ey[3];
    $2402 :
    Begin
      { SPHERE_MAP }
      X := Ey[0]; Y := Ey[1]; Z := Ey[2];
      D := Sqrt(X * X + Y * Y + Z * Z);
      If D > 0.000001 Then
      Begin
        X := X / D; Y := Y / D; Z := Z / D;
      End;
      NE := Nr[0] * X + Nr[1] * Y + Nr[2] * Z;
      RX := X - 2 * Nr[0] * NE; RY := Y - 2 * Nr[1] * NE;
      RZ := Z - 2 * Nr[2] * NE + 1;
      D := 2 * Sqrt(RX * RX + RY * RY + RZ * RZ);
      If D < 0.000001 Then D := 0.000001;
      If C = 0 Then GlTexGen := RX / D + 0.5
      Else GlTexGen := RY / D + 0.5;
    End;
  End;
End;

{ sommet (X, Y, Z, W) avec les attributs courants -> GV[GVN] }
Procedure GlVtx(X, Y, Z, W : Double);
Var M : TMat; J, DCol : LongInt; D, S, T, R, Q, S2, T2 : Double;
    Ob, Ey, Nr : T4D; NeedE : Boolean;
Begin
  If GcA = 0 Then Exit;
  GlGrowV(GVN + 1);
  If GVN >= GVCap Then Exit;
  J := GVN;
  M := Gc^.MVP;
  GV^[J].X := X * M[0] + Y * M[4] + Z * M[8] + W * M[12];
  GV^[J].Y := X * M[1] + Y * M[5] + Z * M[9] + W * M[13];
  GV^[J].Z := X * M[2] + Y * M[6] + Z * M[10] + W * M[14];
  GV^[J].W := X * M[3] + Y * M[7] + Z * M[11] + W * M[15];
  GV^[J].CF := -1;
  If (Gc^.S.POfOn <> 0) Then
    GV^[J].Z := GV^[J].Z + (Gc^.S.POfU * 4 + Gc^.S.POfF * 8) / 16777215 *
                GV^[J].W;
  NeedE := (Gc^.S.LitOn <> 0) Or (Gc^.S.FogOn <> 0) Or
           ((Gc^.S.TgOn[0] Or Gc^.S.TgOn[1]) <> 0);
  If NeedE Then
  Begin
    Ob[0] := X; Ob[1] := Y; Ob[2] := Z; Ob[3] := W;
    M := Gc^.MV[Gc^.MVTop];
    Ey[0] := X * M[0] + Y * M[4] + Z * M[8] + W * M[12];
    Ey[1] := X * M[1] + Y * M[5] + Z * M[9] + W * M[13];
    Ey[2] := X * M[2] + Y * M[6] + Z * M[10] + W * M[14];
    Ey[3] := X * M[3] + Y * M[7] + Z * M[11] + W * M[15];
    If Abs(Ey[3]) > 0.0000001 Then
    Begin
      Ey[0] := Ey[0] / Ey[3]; Ey[1] := Ey[1] / Ey[3];
      Ey[2] := Ey[2] / Ey[3];
    End;
    Nr[0] := Gc^.S.Nrm[0] * M[0] + Gc^.S.Nrm[1] * M[4] + Gc^.S.Nrm[2] * M[8];
    Nr[1] := Gc^.S.Nrm[0] * M[1] + Gc^.S.Nrm[1] * M[5] + Gc^.S.Nrm[2] * M[9];
    Nr[2] := Gc^.S.Nrm[0] * M[2] + Gc^.S.Nrm[1] * M[6] +
             Gc^.S.Nrm[2] * M[10];
    D := Sqrt(Nr[0] * Nr[0] + Nr[1] * Nr[1] + Nr[2] * Nr[2]);
    If D > 0.000001 Then
    Begin
      Nr[0] := Nr[0] / D; Nr[1] := Nr[1] / D; Nr[2] := Nr[2] / D;
    End;
  End;
  If Gc^.S.LitOn <> 0 Then
  Begin
    DCol := GlArgb(Gc^.S.Col[0], Gc^.S.Col[1], Gc^.S.Col[2],
                   Gc^.S.Col[3]);
    If DCol = 0 Then DCol := 1;
    D3DLight(Ey[0], Ey[1], Ey[2], Nr[0], Nr[1], Nr[2], DCol, 0, GV^[J]);
    If (Gc^.S.CmOn = 0) Or (Gc^.S.CmMode = $1200) Then
      GV^[J].A := Cl01(Gc^.S.MDif[3]) * 255
    Else GV^[J].A := Cl01(Gc^.S.Col[3]) * 255;
  End
  Else
  Begin
    GV^[J].R := Cl01(Gc^.S.Col[0]) * 255; GV^[J].G := Cl01(Gc^.S.Col[1]) * 255;
    GV^[J].B := Cl01(Gc^.S.Col[2]) * 255; GV^[J].A := Cl01(Gc^.S.Col[3]) * 255;
    GV^[J].SR := 0; GV^[J].SG := 0; GV^[J].SB := 0;
  End;
  If Gc^.S.FogOn <> 0 Then GV^[J].F := D3DFogOf(Abs(Ey[2]))
  Else GV^[J].F := 1;
  S := Gc^.S.Tc0[0]; T := Gc^.S.Tc0[1]; R := Gc^.S.Tc0[2];
  Q := Gc^.S.Tc0[3];
  If NeedE Then
  Begin
    S := GlTexGen(0, Ob, Ey, Nr, S); T := GlTexGen(1, Ob, Ey, Nr, T);
    R := GlTexGen(2, Ob, Ey, Nr, R); Q := GlTexGen(3, Ob, Ey, Nr, Q);
  End;
  If Not Gc^.TxId Then
  Begin
    M := Gc^.TX[Gc^.TXTop];
    S2 := S * M[0] + T * M[4] + R * M[8] + Q * M[12];
    T2 := S * M[1] + T * M[5] + R * M[9] + Q * M[13];
    Q := S * M[3] + T * M[7] + R * M[11] + Q * M[15];
    S := S2; T := T2;
  End;
  If Abs(Q) < 0.0000001 Then Q := 1;
  GV^[J].U0 := S / Q; GV^[J].V0 := T / Q;
  Q := Gc^.S.Tc1[3];
  If Abs(Q) < 0.0000001 Then Q := 1;
  GV^[J].U1 := Gc^.S.Tc1[0] / Q; GV^[J].V1 := Gc^.S.Tc1[1] / Q;
  Inc(GVN);
End;

{ indice de la suite (0 : directe) }
Function GlSeq(Sq, K : LongInt) : LongInt;
Begin
  If Sq = 0 Then GlSeq := K Else GlSeq := RdL(Sq + K * 4);
End;

Var
  GlNI : LongInt;

Procedure GlPutI(A : LongInt);
Begin
  WrL(GIx + GlNI * 4, A);
  Inc(GlNI);
End;

{ triangle (A, B, C) dont le sommet P (0, 1, 2) donne la couleur unie }
Procedure GlTri3(A, B, C, P : LongInt);
Begin
  If (P = 2) And (Gc^.S.Shade = $1D00) Then
  Begin
    GlPutI(C); GlPutI(A); GlPutI(B);
  End
  Else If (P = 1) And (Gc^.S.Shade = $1D00) Then
  Begin
    GlPutI(B); GlPutI(C); GlPutI(A);
  End
  Else
  Begin
    GlPutI(A); GlPutI(B); GlPutI(C);
  End;
End;

{ dessiner N sommets de GV (suite Sq) en primitives GL de type Md }
Procedure GlDraw(Md, N, Sq : LongInt);
Var I, A, B, C, D, Pt : LongInt; Old : PVtxArr;
Begin
  If (N <= 0) Or (GVN <= 0) Then Exit;
  If (Gc^.S.CullOn <> 0) And (Gc^.S.CullMd = $408) And (Md >= 4) Then Exit;
  GlGrowI(N * 3 + 16);
  GlNI := 0;
  Case Md Of
    0 :
    Begin
      Pt := 1;
      For I := 0 To N - 1 Do GlPutI(GlSeq(Sq, I));
    End;
    1 :
    Begin
      Pt := 2;
      For I := 0 To (N Div 2) * 2 - 1 Do GlPutI(GlSeq(Sq, I));
    End;
    2, 3 :
    Begin
      Pt := 2;
      For I := 0 To N - 2 Do
      Begin
        GlPutI(GlSeq(Sq, I)); GlPutI(GlSeq(Sq, I + 1));
      End;
      If (Md = 2) And (N > 2) Then
      Begin
        GlPutI(GlSeq(Sq, N - 1)); GlPutI(GlSeq(Sq, 0));
      End;
    End;
    4 :
    Begin
      Pt := 4;
      For I := 0 To N Div 3 - 1 Do
        GlTri3(GlSeq(Sq, I * 3), GlSeq(Sq, I * 3 + 1), GlSeq(Sq, I * 3 + 2),
               2);
    End;
    5 :
    Begin
      Pt := 4;
      For I := 0 To N - 3 Do
      Begin
        A := GlSeq(Sq, I); B := GlSeq(Sq, I + 1); C := GlSeq(Sq, I + 2);
        If Odd(I) Then GlTri3(B, A, C, 2) Else GlTri3(A, B, C, 2);
      End;
    End;
    6 :
    Begin
      Pt := 4;
      A := GlSeq(Sq, 0);
      For I := 1 To N - 2 Do
        GlTri3(A, GlSeq(Sq, I), GlSeq(Sq, I + 1), 2);
    End;
    7 :
    Begin
      Pt := 4;
      For I := 0 To N Div 4 - 1 Do
      Begin
        A := GlSeq(Sq, I * 4); B := GlSeq(Sq, I * 4 + 1);
        C := GlSeq(Sq, I * 4 + 2); D := GlSeq(Sq, I * 4 + 3);
        GlTri3(A, B, D, 2); GlTri3(B, C, D, 1);
      End;
    End;
    8 :
    Begin
      Pt := 4;
      For I := 0 To N Div 2 - 2 Do
      Begin
        A := GlSeq(Sq, I * 2); B := GlSeq(Sq, I * 2 + 1);
        C := GlSeq(Sq, I * 2 + 2); D := GlSeq(Sq, I * 2 + 3);
        GlTri3(A, B, D, 2); GlTri3(A, D, C, 1);
      End;
    End;
    9 :
    Begin
      Pt := 4;
      A := GlSeq(Sq, 0);
      For I := 1 To N - 2 Do
        GlTri3(GlSeq(Sq, I), GlSeq(Sq, I + 1), A, 2);
    End;
  Else
    Begin
      GlErr($500);
      Exit;
    End;
  End;
  If GlNI = 0 Then Exit;
  GlSync;
  Old := DV;
  DV := GV;
  D3DPrims(Pt, GIx, 4, GlNI, GVN);
  DV := Old;
  GlScOn := False;
End;

{ ------------------------------------------------------------------ }
{ Tableaux de sommets                                                }
{ ------------------------------------------------------------------ }

{ composante K de l'element I du tableau T (0 sommet, 1 normale,
  2 couleur, 3 et 4 textures) ; Norm : entiers ramenes a [0, 1] }
Procedure GlArrGet(T, I : LongInt; Var V : T4D; Norm : Boolean);
Var A, K, N, Ty, St, Sz : LongInt; X : Double;
Begin
  Ty := Gc^.CA.ATy[T]; N := Gc^.CA.ASz[T];
  Case Ty Of
    $1400, $1401 : Sz := 1;
    $1402, $1403 : Sz := 2;
    $140A : Sz := 8;
  Else
    Sz := 4;
  End;
  St := Gc^.CA.ASt[T];
  If St = 0 Then St := Sz * N;
  A := Gc^.CA.APt[T] + I * St;
  For K := 0 To N - 1 Do
  Begin
    Case Ty Of
      $1400 :
      Begin
        X := RdB(A + K);
        If X > 127 Then X := X - 256;
        If Norm Then X := X / 127;
      End;
      $1401 :
      Begin
        X := RdB(A + K);
        If Norm Then X := X / 255;
      End;
      $1402 :
      Begin
        X := RdW(A + K * 2);
        If X > 32767 Then X := X - 65536;
        If Norm Then X := X / 32767;
      End;
      $1403 :
      Begin
        X := RdW(A + K * 2);
        If Norm Then X := X / 65535;
      End;
      $1404, $1405 :
      Begin
        X := RdL(A + K * 4);
        If Norm Then X := X / 2147483647.0;
      End;
      $140A : X := DbM(A + K * 8);
    Else
      X := FlM(A + K * 4);
    End;
    V[K] := X;
  End;
End;

{ element I des tableaux actifs : attributs courants puis sommet }
Procedure GlArrElem(I : LongInt);
Var V : T4D; K : LongInt;
Begin
  If Gc^.CA.AOn[1] <> 0 Then
  Begin
    GlArrGet(1, I, V, True);
    For K := 0 To 2 Do Gc^.S.Nrm[K] := V[K];
  End;
  If Gc^.CA.AOn[2] <> 0 Then
  Begin
    V[3] := 1;
    GlArrGet(2, I, V, True);
    For K := 0 To 3 Do Gc^.S.Col[K] := V[K];
  End;
  If Gc^.CA.AOn[3] <> 0 Then
  Begin
    V[1] := 0; V[2] := 0; V[3] := 1;
    GlArrGet(3, I, V, False);
    For K := 0 To 3 Do Gc^.S.Tc0[K] := V[K];
  End;
  If Gc^.CA.AOn[4] <> 0 Then
  Begin
    V[1] := 0; V[2] := 0; V[3] := 1;
    GlArrGet(4, I, V, False);
    For K := 0 To 3 Do Gc^.S.Tc1[K] := V[K];
  End;
  If Gc^.CA.AOn[0] <> 0 Then
  Begin
    V[2] := 0; V[3] := 1;
    GlArrGet(0, I, V, False);
    GlVtx(V[0], V[1], V[2], V[3]);
  End;
End;

{ ------------------------------------------------------------------ }
{ Pixels : formats et types                                          }
{ ------------------------------------------------------------------ }

Function GlComps(F : LongInt) : LongInt;
Begin
  Case F Of
    $190A : GlComps := 2;
    $1907, $80E0 : GlComps := 3;
    $1908, $80E1 : GlComps := 4;
  Else
    GlComps := 1;
  End;
End;

{ octets par point }
Function GlPixBytes(F, T : LongInt) : LongInt;
Begin
  Case T Of
    $8032, $8362 : GlPixBytes := 1;
    $8033, $8034, $8363..$8366 : GlPixBytes := 2;
    $8035, $8036, $8367, $8368 : GlPixBytes := 4;
    $1400, $1401 : GlPixBytes := GlComps(F);
    $1402, $1403 : GlPixBytes := GlComps(F) * 2;
  Else
    GlPixBytes := GlComps(F) * 4;
  End;
End;

{ largeurs (en bits) des champs d'un type compacte, du poids fort au
  poids faible ; Rev : la premiere composante est au poids faible }
Function GlPacked(T : LongInt; Var W : T4L; Var Rev : Boolean) : LongInt;
Begin
  GlPacked := 0; Rev := False;
  Case T Of
    $8032 : Begin W[0] := 3; W[1] := 3; W[2] := 2; GlPacked := 3; End;
    $8362 : Begin W[0] := 2; W[1] := 3; W[2] := 3; GlPacked := 3;
                  Rev := True; End;
    $8033, $8365 : Begin W[0] := 4; W[1] := 4; W[2] := 4; W[3] := 4;
                         GlPacked := 4; Rev := T = $8365; End;
    $8034 : Begin W[0] := 5; W[1] := 5; W[2] := 5; W[3] := 1;
                  GlPacked := 4; End;
    $8366 : Begin W[0] := 1; W[1] := 5; W[2] := 5; W[3] := 5;
                  GlPacked := 4; Rev := True; End;
    $8363, $8364 : Begin W[0] := 5; W[1] := 6; W[2] := 5; GlPacked := 3;
                         Rev := T = $8364; End;
    $8035, $8367 : Begin W[0] := 8; W[1] := 8; W[2] := 8; W[3] := 8;
                         GlPacked := 4; Rev := T = $8367; End;
    $8036 : Begin W[0] := 10; W[1] := 10; W[2] := 10; W[3] := 2;
                  GlPacked := 4; End;
    $8368 : Begin W[0] := 2; W[1] := 10; W[2] := 10; W[3] := 10;
                  GlPacked := 4; Rev := True; End;
  End;
End;

{ point a l'adresse A -> ARGB }
Function GlRdPix(A, F, T : LongInt) : LongInt;
Var C, W : T4L;
    N, K, V, Sh, Tot, M, R, G, B, Al : LongInt; X : Double; Rev : Boolean;
Begin
  N := GlPacked(T, W, Rev);
  If N > 0 Then
  Begin
    Case GlPixBytes(F, T) Of
      1 : V := RdB(A);
      2 : V := RdW(A);
    Else
      V := RdL(A);
    End;
    Tot := 0;
    For K := 0 To N - 1 Do Tot := Tot + W[K];
    Sh := 0;
    If Rev Then
      For K := 0 To N - 1 Do
      Begin
        { composante K : champ N - 1 - K (poids faible d'abord) }
        M := W[N - 1 - K];
        C[K] := ((V Shr Sh) And ((1 Shl M) - 1)) * 255 Div ((1 Shl M) - 1);
        Sh := Sh + M;
      End
    Else
    Begin
      Sh := Tot;
      For K := 0 To N - 1 Do
      Begin
        M := W[K];
        Sh := Sh - M;
        C[K] := ((V Shr Sh) And ((1 Shl M) - 1)) * 255 Div ((1 Shl M) - 1);
      End;
    End;
    If N = 3 Then C[3] := 255;
  End
  Else
  Begin
    N := GlComps(F);
    For K := 0 To N - 1 Do
    Begin
      Case T Of
        $1401 : V := RdB(A + K);
        $1400 :
        Begin
          V := RdB(A + K);
          If V > 127 Then V := 0;
          V := V * 2;
        End;
        $1403 : V := RdW(A + K * 2) Shr 8;
        $1402 :
        Begin
          V := RdW(A + K * 2);
          If V > 32767 Then V := 0;
          V := V Shr 7;
        End;
        $1405 : V := (RdL(A + K * 4) Shr 24) And 255;
        $1404 : V := Max(0, RdL(A + K * 4)) Shr 23;
        $1406 :
        Begin
          X := FlM(A + K * 4);
          V := DRound(Cl01(X) * 255);
        End;
      Else
        V := 0;
      End;
      If V > 255 Then V := 255;
      C[K] := V;
    End;
  End;
  R := 255; G := 255; B := 255; Al := 255;
  Case F Of
    $1907, $1908 :
    Begin
      R := C[0]; G := C[1]; B := C[2];
      If F = $1908 Then Al := C[3];
    End;
    $80E0, $80E1 :
    Begin
      B := C[0]; G := C[1]; R := C[2];
      If F = $80E1 Then Al := C[3];
    End;
    $1909 :
    Begin
      R := C[0]; G := C[0]; B := C[0];
    End;
    $190A :
    Begin
      R := C[0]; G := C[0]; B := C[0]; Al := C[1];
    End;
    $1906 : Al := C[0];
    $1903 : Begin R := C[0]; G := 0; B := 0; End;
    $1904 : Begin R := 0; G := C[0]; B := 0; End;
    $1905 : Begin R := 0; G := 0; B := C[0]; End;
  Else
    Begin
      R := C[0]; G := C[0]; B := C[0];
    End;
  End;
  GlRdPix := (Al Shl 24) Or (R Shl 16) Or (G Shl 8) Or B;
End;

{ ARGB -> texel de la surface S (format de stockage) }
Procedure GlWrTex(S, X, Y, C : LongInt);
Var A, V : LongInt;
Begin
  A := RdL(S + 76) + Y * RdL(S + 72);
  Case RdL(S + 88) Of
    16 :
    Begin
      If RdL(S + 108) = $8000 Then
        V := ((C Shr 16) And $8000) Or ((C Shr 9) And $7C00) Or
             ((C Shr 6) And $3E0) Or ((C Shr 3) And $1F)
      Else If RdL(S + 108) = $F000 Then
        V := ((C Shr 16) And $F000) Or ((C Shr 12) And $F00) Or
             ((C Shr 8) And $F0) Or ((C Shr 4) And $F)
      Else
        V := ((C Shr 8) And $F800) Or ((C Shr 5) And $7E0) Or
             ((C Shr 3) And $1F);
      WrW(A + X * 2, V);
    End;
  Else
    WrL(A + X * 4, C);
  End;
End;

{ debut de la ligne Y d'une image (stockage : alignement, longueur) }
Function GlRowAdr(P, W, Y, F, T : LongInt; Pack : Boolean) : LongInt;
Var L, Al, B : LongInt;
Begin
  If Pack Then
  Begin
    Al := Gc^.CA.PackA; L := W;
  End
  Else
  Begin
    Al := Gc^.CA.UnpA; L := Gc^.CA.UnpRL;
    If L <= 0 Then L := W;
  End;
  If Al <= 0 Then Al := 4;
  B := L * GlPixBytes(F, T);
  B := ((B + Al - 1) Div Al) * Al;
  GlRowAdr := P + Y * B;
End;

{ ------------------------------------------------------------------ }
{ Contextes (wgl*) et presentation                                   }
{ ------------------------------------------------------------------ }

Procedure GlSel(P : LongInt);
Begin
  GcA := P;
  Move(GcA, Gc, 4);
End;

Procedure GlLtDef(Var L : TGLLt; I : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 3 Do
  Begin
    L.Amb[K] := 0; L.Dif[K] := 0; L.Spe[K] := 0; L.Pos[K] := 0;
  End;
  L.Amb[3] := 1; L.Dif[3] := 1; L.Spe[3] := 1;
  If I = 0 Then
    For K := 0 To 2 Do
    Begin
      L.Dif[K] := 1; L.Spe[K] := 1;
    End;
  L.Pos[2] := 1;
  L.SDir[0] := 0; L.SDir[1] := 0; L.SDir[2] := -1;
  L.SExp := 0; L.SCut := 180; L.A0 := 1; L.A1 := 0; L.A2 := 0;
End;

{ etat initial d'un contexte (le contexte P devient courant) }
Procedure GlInitCtx(P, D : LongInt);
Var I : LongInt;
Begin
  GlSel(P);
  Gc^.D3 := D;
  Move(D, D3G, 4);
  D3G^.Ver := 7; D3G^.UseTSS := 1;
  D3DDefaults;
  Gc^.S.DepFn := $201; Gc^.S.DepMsk := 1;
  Gc^.S.BlSrc := 1; Gc^.S.BlDst := 0;
  Gc^.S.AlFn := $207; Gc^.S.AlRef := 0;
  Gc^.S.CullMd := $405; Gc^.S.Front := $901; Gc^.S.Shade := $1D01;
  Gc^.S.PolyMd := $1B02;
  Gc^.S.DNear := 0; Gc^.S.DFar := 1;
  Gc^.S.FogMd := $800; Gc^.S.FogS := 0; Gc^.S.FogE := 1; Gc^.S.FogD := 1;
  Gc^.S.CmMode := $1602;
  For I := 0 To 7 Do GlLtDef(Gc^.S.Lt[I], I);
  For I := 0 To 3 Do
  Begin
    Gc^.S.MAmb[I] := 0.2; Gc^.S.MDif[I] := 0.8; Gc^.S.MSpe[I] := 0;
    Gc^.S.MEmi[I] := 0; Gc^.S.LMAmb[I] := 0.2; Gc^.S.Col[I] := 1;
    Gc^.S.Tc0[I] := 0; Gc^.S.Tc1[I] := 0;
  End;
  Gc^.S.MAmb[3] := 1; Gc^.S.MDif[3] := 1; Gc^.S.MSpe[3] := 1;
  Gc^.S.MEmi[3] := 1; Gc^.S.LMAmb[3] := 1;
  Gc^.S.Tc0[3] := 1; Gc^.S.Tc1[3] := 1;
  Gc^.S.Nrm[0] := 0; Gc^.S.Nrm[1] := 0; Gc^.S.Nrm[2] := 1;
  Gc^.S.Env[0] := $2100; Gc^.S.Env[1] := $2100;
  Gc^.S.ClrZ := 1;
  Gc^.S.PtSz := 1; Gc^.S.LnW := 1; Gc^.S.DitOn := 1; Gc^.S.CMask := 15;
  For I := 0 To 3 Do Gc^.S.TgMd[I] := $2400;
  Gc^.S.TgOP[0] := 1; Gc^.S.TgOP[5] := 1;
  Gc^.S.TgEP[0] := 1; Gc^.S.TgEP[5] := 1;
  Gc^.CA.UnpA := 4; Gc^.CA.PackA := 4;
  For I := 0 To 5 Do
  Begin
    Gc^.CA.ASz[I] := 4; Gc^.CA.ATy[I] := $1406;
  End;
  Gc^.CA.ASz[1] := 3;
  MatId(Gc^.MV[0]); MatId(Gc^.PR[0]); MatId(Gc^.TX[0]);
  Gc^.MMode := $1700;
  Gc^.MOk := False;
End;

{ ------------------------------------------------------------------ }
{ Interface de Presentation Manager (pgl*, comme OS/2 Warp)          }
{ ------------------------------------------------------------------ }
{ Une seule configuration visuelle : RGBA 8-8-8-8, double tampon,
  Z de 24 bits. VISUALCONFIG : +0 vid, +4 rgba, +8..+20 tailles R, V,
  B, A, +24..+32 masques R, V, B, +36..+48 accumulation, +52 double
  tampon, +56 stereo, +60 taille du tampon, +64 Z, +68 stencil, +72
  tampons auxiliaires, +76 niveau, +80 suivante. }

Const
  PGL_USE_GL = 1; PGL_BUFFER_SIZE = 2; PGL_LEVEL = 3; PGL_RGBA = 4;
  PGL_DOUBLEBUFFER = 5; PGL_STEREO = 6; PGL_AUX_BUFFERS = 7;
  PGL_RED_SIZE = 8; PGL_ALPHA_SIZE = 11; PGL_DEPTH_SIZE = 12;
  PGL_STENCIL_SIZE = 13; PGL_ACCUM_RED_SIZE = 14; PGL_ACCUM_ALPHA_SIZE = 17;
  PGL_SINGLEBUFFER = 18;

Var
  GlVc : Array[0..1] Of Array[0..21] Of LongInt;   { double, simple }
  GlVcList : Array[0..2] Of LongInt;
  GlSingle : Array[0..15] Of Boolean;              { contexte a simple tampon }
  GlBmi : Array[0..3] Of LongInt;                  { BITMAPINFOHEADER2 (16) }
  GlRow, GlRowCap : LongInt;                       { image 24 bits (bas en haut) }
  GlFrames : LongInt;

Procedure GlVcInit;
Var K : LongInt;
Begin
  For K := 0 To 1 Do
  Begin
    FillChar(GlVc[K], SizeOf(GlVc[K]), 0);
    GlVc[K][0] := K + 1;
    GlVc[K][1] := 1;
    GlVc[K][2] := 8; GlVc[K][3] := 8; GlVc[K][4] := 8; GlVc[K][5] := 8;
    GlVc[K][6] := $FF0000; GlVc[K][7] := $FF00; GlVc[K][8] := $FF;
    GlVc[K][13] := 1 - K;
    GlVc[K][15] := 32; GlVc[K][16] := 24;
  End;
  GlVc[0][20] := LongInt(@GlVc[1]);
  GlVcList[0] := LongInt(@GlVc[0]); GlVcList[1] := LongInt(@GlVc[1]); GlVcList[2] := 0;
End;

Function GlCtxIdx(P : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  If P <> 0 Then
    For I := 0 To 15 Do
      If GlCtx[I] = P Then R := I;
  GlCtxIdx := R;
End;

Function GlCtxOk(P : LongInt) : Boolean;
Begin
  GlCtxOk := GlCtxIdx(P) >= 0;
End;

{ un autre processus que le dernier utilisateur : les blocs de celui-ci
  (prives, rendus a sa fin) sont oublies }
Procedure GlProcCheck;
Var P, I : LongInt;
Begin
  P := CurProc;
  If (GlProc = 0) Or (GlProc = P) Then
  Begin
    GlProc := P;
    Exit;
  End;
  For I := 0 To 15 Do GlCtx[I] := 0;
  GcA := 0; Move(GcA, Gc, 4);
  GlTexT := 0;
  For I := 0 To 3 Do GlStrs[I] := 0;
  DVCap := 0; GVCap := 0; GVN := 0; GIx := 0; GIxCap := 0; GSq := 0; GSqCap := 0;
  GlRow := 0; GlRowCap := 0; GlFrames := 0;
  GlScOn := False;
  GlProc := P;
End;

{ pglChooseConfig(hab, pAttribList) }
Function pglChooseConfig(Hab, PList : LongInt) : LongInt;
Var A, Dbl, Ok : LongInt;
Begin
  GlTr(1);
  If GlVc[0][0] = 0 Then GlVcInit;
  Dbl := 0; Ok := 1;
  A := PList;
  If A <> 0 Then
    While RdL(A) <> 0 Do
    Begin
      Case RdL(A) Of
        PGL_DOUBLEBUFFER : Dbl := 1;
        PGL_SINGLEBUFFER : Dbl := 0;
        PGL_USE_GL, PGL_RGBA : ;
        PGL_STEREO : Ok := 0;
        PGL_BUFFER_SIZE, PGL_LEVEL, PGL_AUX_BUFFERS, PGL_RED_SIZE..PGL_ALPHA_SIZE, PGL_DEPTH_SIZE,
        PGL_STENCIL_SIZE, PGL_ACCUM_RED_SIZE..PGL_ACCUM_ALPHA_SIZE :
        Begin
          A := A + 4;
          If ((RdL(A - 4) = PGL_LEVEL) And (RdL(A) <> 0)) Or ((RdL(A - 4) = PGL_AUX_BUFFERS) And (RdL(A) > 0)) Or
             ((RdL(A - 4) = PGL_DEPTH_SIZE) And (RdL(A) > 24)) Or ((RdL(A - 4) >= PGL_RED_SIZE) And
             (RdL(A - 4) <= PGL_ALPHA_SIZE) And (RdL(A) > 8)) Then Ok := 0;
        End;
      End;
      A := A + 4;
    End;
  If Ok = 0 Then
  Begin
    pglChooseConfig := 0;
    Exit;
  End;
  If Dbl <> 0 Then pglChooseConfig := LongInt(@GlVc[0]) Else pglChooseConfig := LongInt(@GlVc[1]);
End;

{ pglQueryConfigs(hab) : tableau de PVISUALCONFIG termine par 0 }
Function pglQueryConfigs(Hab : LongInt) : LongInt;
Begin
  GlTr(2);
  If GlVc[0][0] = 0 Then GlVcInit;
  pglQueryConfigs := LongInt(@GlVcList);
End;

{ pglCreateContext(hab, pVisualConfig, hgcShareList, fIsDirect) }
Function pglCreateContext(Hab, PVc, Share, Direct : LongInt) : LongInt;
Var I, P, D, Old : LongInt;
Begin
  GlTr(3);
  pglCreateContext := 0;
  GlProcCheck;
  If GlVc[0][0] = 0 Then GlVcInit;
  I := 0;
  While (I < 16) And (GlCtx[I] <> 0) Do Inc(I);
  If I >= 16 Then Exit;
  P := KAlloc(SizeOf(TGLC) + 16);
  D := KAlloc(SizeOf(TD3D) + 16);
  If (P = 0) Or (D = 0) Then Exit;
  FillMem(P, SizeOf(TGLC), 0);
  FillMem(D, SizeOf(TD3D), 0);
  If GlTexT = 0 Then
  Begin
    GlTexT := KAlloc(GlMaxTex * GlTexSz + 16);
    If GlTexT <> 0 Then FillMem(GlTexT, GlMaxTex * GlTexSz, 0);
  End;
  If GlStrs[0] = 0 Then
  Begin
    GlStrs[0] := KAlloc(256);
    PutPStr(GlStrs[0], 'OS/2-0', 32);
    GlStrs[1] := GlStrs[0] + 32;
    PutPStr(GlStrs[1], 'OS/2-0 OpenGL (rendu logiciel)', 64);
    GlStrs[2] := GlStrs[0] + 96;
    PutPStr(GlStrs[2], '1.1.0 OS/2-0', 32);
    GlStrs[3] := GlStrs[0] + 128;
    PutPStr(GlStrs[3], 'GL_ARB_multitexture GL_EXT_texture_env_add', 128);
  End;
  Old := GcA;
  GlInitCtx(P, D);
  GlSel(Old);
  GlCtx[I] := P;
  GlSingle[I] := (PVc <> 0) And (RdL(PVc + 52) = 0);
  KLog('OpenGL : contexte ' + HexStr(P, 8));
  pglCreateContext := P;
End;

{ pglMakeCurrent(hab, hgc, hwnd) }
Function pglMakeCurrent(Hab, P, Hwnd : LongInt) : LongInt;
Begin
  GlTr(4);
  pglMakeCurrent := 1;
  If (P = 0) Or (Hwnd = 0) Then
  Begin
    GlSel(0);
    Exit;
  End;
  If Not GlCtxOk(P) Then
  Begin
    pglMakeCurrent := 0;
    Exit;
  End;
  GlSel(P);
  Gc^.Dc := 0;
  Gc^.Wnd := Hwnd;
  GlBuffers;
  If Gc^.Made = 0 Then
  Begin
    Gc^.Made := 1;
    Gc^.S.VpW := Gc^.BW; Gc^.S.VpH := Gc^.BH;
    Gc^.S.ScW := Gc^.BW; Gc^.S.ScH := Gc^.BH;
  End;
End;

{ pglDestroyContext(hab, hgc) }
Function pglDestroyContext(Hab, P : LongInt) : LongInt;
Var I, Old : LongInt;
Begin
  GlTr(5);
  pglDestroyContext := 0;
  If Not GlCtxOk(P) Then Exit;
  Old := GcA;
  If P = GcA Then Old := 0;
  For I := 0 To 15 Do
    If GlCtx[I] = P Then GlCtx[I] := 0;
  GlSel(P);
  GlSurfFree(Gc^.RT); GlSurfFree(Gc^.ZB);
  If Gc^.D3 <> 0 Then KFree(Gc^.D3);
  GlSel(Old);
  KFree(P);
  pglDestroyContext := 1;
End;

Function pglGetCurrentContext(Hab : LongInt) : LongInt;
Begin
  GlTr(6);
  pglGetCurrentContext := GcA;
End;

Function pglGetCurrentWindow(Hab : LongInt) : LongInt;
Begin
  GlTr(7);
  If GcA = 0 Then pglGetCurrentWindow := 0 Else pglGetCurrentWindow := Gc^.Wnd;
End;

{ tampon de couleur (32 bits, haut en bas) -> zone client : image de
  24 bits par pel, lignes de bas en haut (bitmap d'OS/2), GpiDrawBits }
Procedure GlPresent;
Var Hps, W, H, Y, X, S, D, Pitch, Src, Need, V : LongInt;
    P : Array[0..7] Of LongInt;
Begin
  If (GcA = 0) Or (Gc^.RT = 0) Or (Gc^.Wnd = 0) Then Exit;
  W := Gc^.BW; H := Gc^.BH;
  Pitch := ((W * 3) + 3) And Not 3;
  Need := Pitch * H + 16;
  If Need > GlRowCap Then
  Begin
    If GlRow <> 0 Then KFree(GlRow);
    GlRow := KAlloc(Need);
    If GlRow = 0 Then
    Begin
      GlRowCap := 0;
      Exit;
    End;
    GlRowCap := Need;
  End;
  Src := RdL(Gc^.RT + 76);
  For Y := 0 To H - 1 Do
  Begin
    S := Src + (H - 1 - Y) * RdL(Gc^.RT + 72);
    D := GlRow + Y * Pitch;
    For X := 0 To W - 1 Do
    Begin
      V := RdL(S);
      WrW(D, V); WrB(D + 2, V Shr 16);
      S := S + 4; D := D + 3;
    End;
  End;
  GlBmi[0] := 16; GlBmi[1] := W; GlBmi[2] := H; GlBmi[3] := 1 Or (24 Shl 16);
  Hps := WinGetPS(Gc^.Wnd);
  If Hps = 0 Then Exit;
  P[0] := 0; P[1] := 0; P[2] := W; P[3] := H;
  P[4] := 0; P[5] := 0; P[6] := W; P[7] := H;
  GpiDrawBits(Hps, GlRow, LongInt(@GlBmi), 4, LongInt(@P), $CC, 0);
  WinReleasePS(Hps);
  Inc(GlFrames);
  If (GlFrames < 4) Or (GlFrames Mod 100 = 0) Then
  Begin
    Move(Gc^.D3, D3G, 4);
    KLog('OpenGL : image ' + IntStr(GlFrames) + ' (' + IntStr(D3G^.Tris) + ' triangles)');
  End;
End;

{ pglSwapBuffers(hab, hwnd) : contexte courant, ou celui de la fenetre }
Function pglSwapBuffers(Hab, Hwnd : LongInt) : LongInt;
Var I, Old : LongInt;
Begin
  GlTr(8);
  pglSwapBuffers := 1;
  Old := GcA;
  If (GcA = 0) Or ((Hwnd <> 0) And (Gc^.Wnd <> Hwnd)) Then
    For I := 0 To 15 Do
      If GlCtx[I] <> 0 Then
      Begin
        GlSel(GlCtx[I]);
        If Gc^.Wnd = Hwnd Then Old := GlCtx[I];
      End;
  GlSel(Old);
  If GcA = 0 Then
  Begin
    pglSwapBuffers := 0;
    Exit;
  End;
  GlPresent;
  GlBuffers;
End;

{ glFlush et glFinish d'un contexte a simple tampon : image affichee }
Procedure GlFlushSingle;
Var I : LongInt;
Begin
  I := GlCtxIdx(GcA);
  If (I >= 0) And GlSingle[I] Then GlPresent;
End;

Function pglQueryCapability(Hab : LongInt) : LongInt;
Begin
  GlTr(9);
  pglQueryCapability := 1;          { PGL_RENDER_DIRECT ... rendu logiciel }
End;

Function pglQueryVersion(Hab, PMaj, PMin : LongInt) : LongInt;
Begin
  GlTr(10);
  If PMaj <> 0 Then WrL(PMaj, 1);
  If PMin <> 0 Then WrL(PMin, 1);
  pglQueryVersion := 1;
End;

Function pglWaitGL(Hab : LongInt) : LongInt;
Begin
  GlTr(11);
  pglWaitGL := 1;
End;

Function pglWaitPM(Hab : LongInt) : LongInt;
Begin
  GlTr(12);
  pglWaitPM := 1;
End;

Function pglCopyContext(Hab, Src, Dst, Mask : LongInt) : LongInt;
Begin
  GlTr(13);
  pglCopyContext := Ord(GlCtxOk(Src) And GlCtxOk(Dst));
End;

Function pglIsIndirect(Hab, Hgc : LongInt) : LongInt;
Begin
  GlTr(14);
  pglIsIndirect := 0;
End;

Function pglSelectColorIndexPalette(Hab, Hpal, Hgc : LongInt) : LongInt;
Begin
  GlTr(15);
  pglSelectColorIndexPalette := 0;
End;

Function pglGrabFrontBitmap(Hab, PHps, PHbm, PRect : LongInt) : LongInt;
Begin
  GlTr(16);
  pglGrabFrontBitmap := 0;
End;

Function pglReleaseFrontBitmap(Hab : LongInt) : LongInt;
Begin
  GlTr(17);
  pglReleaseFrontBitmap := 1;
End;

Function pglUseFont(Hab, Hps, PAttrs, LogId, First, Count, ListBase : LongInt) : LongInt;
Begin
  GlTr(18);
  GlTodo('pglUseFont');
  pglUseFont := 0;
End;

{ fin du processus : contextes et textures oublies (blocs liberes par
  KFreeOwner) }
Procedure GlProcDone(P : LongInt);
Var I : LongInt;
Begin
  If (GlProc <> P) Or (GlProc = 0) Then Exit;
  For I := 0 To 15 Do GlCtx[I] := 0;
  GlSel(0);
  GlTexT := 0;
  GlProc := 0;
  GlScOn := False;
End;

{ ------------------------------------------------------------------ }
{ Etat                                                               }
{ ------------------------------------------------------------------ }

Function GlOk : Boolean;
Begin
  GlOk := GcA <> 0;
End;

Procedure GlCap(C, V : LongInt);
Begin
  If Not GlOk Then Exit;
  Case C Of
    $0DE0, $0DE1 : Gc^.S.TexOn[Gc^.S.ActTex] := V;
    $0B71 : Gc^.S.DepOn := V;
    $0BE2 : Gc^.S.BlOn := V;
    $0BC0 : Gc^.S.AlOn := V;
    $0B44 : Gc^.S.CullOn := V;
    $0B60 : Gc^.S.FogOn := V;
    $0B50 : Gc^.S.LitOn := V;
    $4000..$4007 : Gc^.S.LtOn[C - $4000] := V;
    $0B57 : Gc^.S.CmOn := V;
    $0BA1, $803A : Gc^.S.NormOn := V;
    $0C11 : Gc^.S.ScOn := V;
    $8037, $2A01, $2A02 : Gc^.S.POfOn := V;
    $0C60..$0C63 : Gc^.S.TgOn[C - $0C60] := V;
    $0BD0 : Gc^.S.DitOn := V;
  End;
End;

Function GlCapOn(C : LongInt) : LongInt;
Begin
  GlCapOn := 0;
  If Not GlOk Then Exit;
  Case C Of
    $0DE0, $0DE1 : GlCapOn := Gc^.S.TexOn[Gc^.S.ActTex];
    $0B71 : GlCapOn := Gc^.S.DepOn;
    $0BE2 : GlCapOn := Gc^.S.BlOn;
    $0BC0 : GlCapOn := Gc^.S.AlOn;
    $0B44 : GlCapOn := Gc^.S.CullOn;
    $0B60 : GlCapOn := Gc^.S.FogOn;
    $0B50 : GlCapOn := Gc^.S.LitOn;
    $4000..$4007 : GlCapOn := Gc^.S.LtOn[C - $4000];
    $0B57 : GlCapOn := Gc^.S.CmOn;
    $0BA1, $803A : GlCapOn := Gc^.S.NormOn;
    $0C11 : GlCapOn := Gc^.S.ScOn;
    $8037 : GlCapOn := Gc^.S.POfOn;
    $0C60..$0C63 : GlCapOn := Gc^.S.TgOn[C - $0C60];
    $0BD0 : GlCapOn := Gc^.S.DitOn;
    $8074 : GlCapOn := Gc^.CA.AOn[0];
    $8075 : GlCapOn := Gc^.CA.AOn[1];
    $8076 : GlCapOn := Gc^.CA.AOn[2];
    $8078 : GlCapOn := Gc^.CA.AOn[3 + Gc^.CA.CliTex];
  End;
End;

Procedure glEnable(C : LongInt);
Begin
  GlTr(19);
  GlCap(C, 1);
End;

Procedure glDisable(C : LongInt);
Begin
  GlTr(20);
  GlCap(C, 0);
End;

Function glIsEnabled(C : LongInt) : LongInt;
Begin
  GlTr(21);
  glIsEnabled := GlCapOn(C);
End;

Function GlArrOf(C : LongInt) : LongInt;
Begin
  Case C Of
    $8074 : GlArrOf := 0;
    $8075 : GlArrOf := 1;
    $8076 : GlArrOf := 2;
    $8078 : GlArrOf := 3 + Gc^.CA.CliTex;
    $8079 : GlArrOf := 5;
  Else
    GlArrOf := -1;
  End;
End;

Procedure glEnableClientState(C : LongInt);
Var A : LongInt;
Begin
  GlTr(22);
  If Not GlOk Then Exit;
  A := GlArrOf(C);
  If A >= 0 Then Gc^.CA.AOn[A] := 1;
End;

Procedure glDisableClientState(C : LongInt);
Var A : LongInt;
Begin
  GlTr(23);
  If Not GlOk Then Exit;
  A := GlArrOf(C);
  If A >= 0 Then Gc^.CA.AOn[A] := 0;
End;

Procedure GlSetArr(A, Sz, Ty, St, P : LongInt);
Begin
  If Not GlOk Then Exit;
  Gc^.CA.ASz[A] := Sz; Gc^.CA.ATy[A] := Ty; Gc^.CA.ASt[A] := St;
  Gc^.CA.APt[A] := P;
End;

Procedure glVertexPointer(Sz, Ty, St, P : LongInt);
Begin
  GlTr(24);
  GlSetArr(0, Sz, Ty, St, P);
End;

Procedure glNormalPointer(Ty, St, P : LongInt);
Begin
  GlTr(25);
  GlSetArr(1, 3, Ty, St, P);
End;

Procedure glColorPointer(Sz, Ty, St, P : LongInt);
Begin
  GlTr(26);
  GlSetArr(2, Sz, Ty, St, P);
End;

Procedure glTexCoordPointer(Sz, Ty, St, P : LongInt);
Begin
  GlTr(27);
  If GlOk Then GlSetArr(3 + Gc^.CA.CliTex, Sz, Ty, St, P);
End;

Procedure glEdgeFlagPointer(St, P : LongInt);
Begin
  GlTr(28);
  GlSetArr(5, 1, $1401, St, P);
End;

Procedure glIndexPointer(Ty, St, P : LongInt);
Begin
  GlTr(29);
End;

Procedure glGetPointerv(N, P : LongInt);
Var A : LongInt;
Begin
  GlTr(30);
  If Not GlOk Or (P = 0) Then Exit;
  A := -1;
  Case N Of
    $808E : A := 0;
    $808F : A := 1;
    $8090 : A := 2;
    $8092 : A := 3 + Gc^.CA.CliTex;
    $8093 : A := 5;
  End;
  If A >= 0 Then WrL(P, Gc^.CA.APt[A]) Else WrL(P, 0);
End;

{ glInterleavedArrays : t texture, c couleur, n normale, v sommet }
Procedure glInterleavedArrays(F, St, P : LongInt);
Var Tc, Cc, Ct, Vc, O, S, K : LongInt; N : Boolean;
Begin
  GlTr(31);
  If Not GlOk Then Exit;
  K := F - $2A20;
  If (K < 0) Or (K > 13) Then
  Begin
    GlErr($500);
    Exit;
  End;
  Tc := 0; Cc := 0; Ct := $1406; Vc := 3; N := False;
  Case K Of
    0 : Vc := 2;
    2 : Begin Cc := 4; Ct := $1401; Vc := 2; End;
    3 : Begin Cc := 4; Ct := $1401; End;
    4 : Cc := 3;
    5 : N := True;
    6 : Begin Cc := 4; N := True; End;
    7 : Tc := 2;
    8 : Begin Tc := 4; Vc := 4; End;
    9 : Begin Tc := 2; Cc := 4; Ct := $1401; End;
    10 : Begin Tc := 2; Cc := 3; End;
    11 : Begin Tc := 2; N := True; End;
    12 : Begin Tc := 2; Cc := 4; N := True; End;
    13 : Begin Tc := 4; Cc := 4; N := True; Vc := 4; End;
  End;
  S := Tc * 4 + Vc * 4;
  If N Then S := S + 12;
  If Ct = $1401 Then S := S + Cc Else S := S + Cc * 4;
  If St = 0 Then St := S;
  For K := 0 To 5 Do Gc^.CA.AOn[K] := 0;
  O := P;
  If Tc > 0 Then
  Begin
    GlSetArr(3, Tc, $1406, St, O); Gc^.CA.AOn[3] := 1;
    O := O + Tc * 4;
  End;
  If Cc > 0 Then
  Begin
    GlSetArr(2, Cc, Ct, St, O); Gc^.CA.AOn[2] := 1;
    If Ct = $1401 Then O := O + Cc Else O := O + Cc * 4;
  End;
  If N Then
  Begin
    GlSetArr(1, 3, $1406, St, O); Gc^.CA.AOn[1] := 1;
    O := O + 12;
  End;
  GlSetArr(0, Vc, $1406, St, O); Gc^.CA.AOn[0] := 1;
End;

Procedure glArrayElement(I : LongInt);
Begin
  GlTr(32);
  If GlOk Then GlArrElem(I);
End;

Procedure glDrawArrays(Md, F, N : LongInt);
Var I : LongInt;
Begin
  GlTr(33);
  If Not GlOk Or (N <= 0) Then Exit;
  If Gc^.CA.AOn[0] = 0 Then Exit;
  GlMats;
  GVN := 0;
  GlGrowV(N);
  For I := F To F + N - 1 Do GlArrElem(I);
  GlDraw(Md, GVN, 0);
  GVN := 0;
End;

Function GlIdx(Ty, P, K : LongInt) : LongInt;
Begin
  Case Ty Of
    $1401 : GlIdx := RdB(P + K);
    $1403 : GlIdx := RdW(P + K * 2);
  Else
    GlIdx := RdL(P + K * 4);
  End;
End;

Procedure glDrawElements(Md, N, Ty, P : LongInt);
Var I, Mn, Mx, V : LongInt;
Begin
  GlTr(34);
  If Not GlOk Or (N <= 0) Or (P = 0) Then Exit;
  If Gc^.CA.AOn[0] = 0 Then Exit;
  GlMats;
  Mn := GlIdx(Ty, P, 0); Mx := Mn;
  For I := 1 To N - 1 Do
  Begin
    V := GlIdx(Ty, P, I);
    If V < Mn Then Mn := V;
    If V > Mx Then Mx := V;
  End;
  GVN := 0;
  If (Mn >= 0) And (Mx - Mn + 1 <= Max(N * 4, 256)) Then
  Begin
    { sommets [Mn, Mx] traites une fois, puis suite d'indices }
    GlGrowV(Mx - Mn + 1);
    GlGrowS(N);
    If GSq = 0 Then Exit;
    For I := Mn To Mx Do GlArrElem(I);
    If GVN <> Mx - Mn + 1 Then
    Begin
      GVN := 0;
      Exit;
    End;
    For I := 0 To N - 1 Do WrL(GSq + I * 4, GlIdx(Ty, P, I) - Mn);
    GlDraw(Md, N, GSq);
  End
  Else
  Begin
    GlGrowV(N);
    For I := 0 To N - 1 Do GlArrElem(GlIdx(Ty, P, I));
    GlDraw(Md, GVN, 0);
  End;
  GVN := 0;
End;

Procedure glDrawRangeElements(Md, A, B, N, Ty, P : LongInt);
Begin
  GlTr(35);
  glDrawElements(Md, N, Ty, P);
End;

Procedure glBegin(Md : LongInt);
Begin
  GlTr(36);
  If Not GlOk Then Exit;
  If Gc^.InBeg <> 0 Then
  Begin
    GlErr($502);
    Exit;
  End;
  GlMats;
  Gc^.InBeg := 1; Gc^.Prim := Md;
  GVN := 0;
End;

Procedure glEnd;
Begin
  GlTr(37);
  If Not GlOk Then Exit;
  If Gc^.InBeg = 0 Then
  Begin
    GlErr($502);
    Exit;
  End;
  Gc^.InBeg := 0;
  GlDraw(Gc^.Prim, GVN, 0);
  GVN := 0;
End;

{ attributs courants (appeles par les variantes glVertex*, glColor*...) }
Procedure GlSetV(X, Y, Z, W : Double);
Begin
  If GlOk Then
    If Gc^.InBeg <> 0 Then GlVtx(X, Y, Z, W);
End;

Procedure GlSetC(R, G, B, A : Double);
Begin
  If Not GlOk Then Exit;
  Gc^.S.Col[0] := R; Gc^.S.Col[1] := G; Gc^.S.Col[2] := B;
  Gc^.S.Col[3] := A;
End;

Procedure GlSetN(X, Y, Z : Double);
Begin
  If Not GlOk Then Exit;
  Gc^.S.Nrm[0] := X; Gc^.S.Nrm[1] := Y; Gc^.S.Nrm[2] := Z;
End;

Procedure GlSetT(U : LongInt; S, T, R, Q : Double);
Begin
  If Not GlOk Then Exit;
  If U = 1 Then
  Begin
    Gc^.S.Tc1[0] := S; Gc^.S.Tc1[1] := T; Gc^.S.Tc1[2] := R;
    Gc^.S.Tc1[3] := Q;
  End
  Else
  Begin
    Gc^.S.Tc0[0] := S; Gc^.S.Tc0[1] := T; Gc^.S.Tc0[2] := R;
    Gc^.S.Tc0[3] := Q;
  End;
End;

{ position raster : fenetre (origine en bas a gauche) }
Procedure GlSetR(X, Y, Z, W : Double);
Var M : TMat; CX, CY, CW : Double;
Begin
  If Not GlOk Then Exit;
  GlMats;
  M := Gc^.MVP;
  CX := X * M[0] + Y * M[4] + Z * M[8] + W * M[12];
  CY := X * M[1] + Y * M[5] + Z * M[9] + W * M[13];
  CW := X * M[3] + Y * M[7] + Z * M[11] + W * M[15];
  If Abs(CW) < 0.0000001 Then CW := 1;
  Gc^.RPos[0] := Gc^.S.VpX + (CX / CW + 1) * Gc^.S.VpW / 2;
  Gc^.RPos[1] := Gc^.S.VpY + (CY / CW + 1) * Gc^.S.VpH / 2;
End;

Procedure GlSetI(V : Double);
Begin
End;

Procedure GlRectQ(X1, Y1, X2, Y2 : Double);
Begin
  If Not GlOk Or (Gc^.InBeg <> 0) Then Exit;
  GlMats;
  Gc^.InBeg := 1; Gc^.Prim := 9;
  GVN := 0;
  GlVtx(X1, Y1, 0, 1); GlVtx(X2, Y1, 0, 1);
  GlVtx(X2, Y2, 0, 1); GlVtx(X1, Y2, 0, 1);
  glEnd;
End;

{ ------------------------------------------------------------------ }
{ Effacement et etats simples                                        }
{ ------------------------------------------------------------------ }

Procedure glClear(M : LongInt);
Var L, T, R, B : LongInt;
Begin
  GlTr(38);
  If Not GlOk Or (Gc^.RT = 0) Then Exit;
  L := 0; T := 0; R := Gc^.BW; B := Gc^.BH;
  If Gc^.S.ScOn <> 0 Then
  Begin
    L := Max(0, Gc^.S.ScX); R := Min(Gc^.BW, Gc^.S.ScX + Gc^.S.ScW);
    T := Max(0, Gc^.BH - (Gc^.S.ScY + Gc^.S.ScH));
    B := Min(Gc^.BH, Gc^.BH - Gc^.S.ScY);
  End;
  If (M And $4000) <> 0 Then
    SfFill(Gc^.RT, L, T, R, B, GlArgb(Gc^.S.ClrC[0], Gc^.S.ClrC[1],
           Gc^.S.ClrC[2], 0) And $FFFFFF);
  If ((M And $100) <> 0) And (Gc^.S.DepMsk <> 0) And (Gc^.ZB <> 0) Then
    SfFill(Gc^.ZB, L, T, R, B, DRound(Cl01(Gc^.S.ClrZ) * 16777215));
End;

Procedure glClearColor(R, G, B, A : LongInt);
Begin
  GlTr(39);
  If Not GlOk Then Exit;
  Gc^.S.ClrC[0] := FlL(R); Gc^.S.ClrC[1] := FlL(G);
  Gc^.S.ClrC[2] := FlL(B); Gc^.S.ClrC[3] := FlL(A);
End;

Procedure glClearDepth(Lo, Hi : LongInt);
Begin
  GlTr(40);
  If GlOk Then Gc^.S.ClrZ := DblOf(Lo, Hi);
End;

Procedure glViewport(X, Y, W, H : LongInt);
Begin
  GlTr(41);
  If Not GlOk Then Exit;
  Gc^.S.VpX := X; Gc^.S.VpY := Y; Gc^.S.VpW := W; Gc^.S.VpH := H;
End;

Procedure glScissor(X, Y, W, H : LongInt);
Begin
  GlTr(42);
  If Not GlOk Then Exit;
  Gc^.S.ScX := X; Gc^.S.ScY := Y; Gc^.S.ScW := W; Gc^.S.ScH := H;
End;

Procedure glDepthRange(NL, NH, FL, FH : LongInt);
Begin
  GlTr(43);
  If Not GlOk Then Exit;
  Gc^.S.DNear := Cl01(DblOf(NL, NH)); Gc^.S.DFar := Cl01(DblOf(FL, FH));
End;

Procedure glDepthFunc(F : LongInt);
Begin
  GlTr(44);
  If GlOk Then Gc^.S.DepFn := F;
End;

Procedure glDepthMask(F : LongInt);
Begin
  GlTr(45);
  If GlOk Then Gc^.S.DepMsk := Ord((F And 255) <> 0);
End;

Procedure glBlendFunc(S, D : LongInt);
Begin
  GlTr(46);
  If Not GlOk Then Exit;
  Gc^.S.BlSrc := S; Gc^.S.BlDst := D;
End;

Procedure glAlphaFunc(F, R : LongInt);
Begin
  GlTr(47);
  If Not GlOk Then Exit;
  Gc^.S.AlFn := F; Gc^.S.AlRef := FlL(R);
End;

Procedure glCullFace(M : LongInt);
Begin
  GlTr(48);
  If GlOk Then Gc^.S.CullMd := M;
End;

Procedure glFrontFace(M : LongInt);
Begin
  GlTr(49);
  If GlOk Then Gc^.S.Front := M;
End;

Procedure glShadeModel(M : LongInt);
Begin
  GlTr(50);
  If GlOk Then Gc^.S.Shade := M;
End;

Procedure glPolygonMode(F, M : LongInt);
Begin
  GlTr(51);
  If GlOk And (F <> $404) Then Gc^.S.PolyMd := M;
End;

Procedure glPolygonOffset(F, U : LongInt);
Begin
  GlTr(52);
  If Not GlOk Then Exit;
  Gc^.S.POfF := FlL(F); Gc^.S.POfU := FlL(U);
End;

Procedure glColorMask(R, G, B, A : LongInt);
Begin
  GlTr(53);
  If GlOk Then
    Gc^.S.CMask := Ord(R <> 0) Or (Ord(G <> 0) Shl 1) Or (Ord(B <> 0) Shl 2)
                   Or (Ord(A <> 0) Shl 3);
End;

Procedure glLineWidth(W : LongInt);
Begin
  GlTr(54);
  If GlOk Then Gc^.S.LnW := FlL(W);
End;

Procedure glPointSize(W : LongInt);
Begin
  GlTr(55);
  If GlOk Then Gc^.S.PtSz := FlL(W);
End;

Procedure glHint(T, M : LongInt);
Begin
  GlTr(56);
End;

Procedure glFlush;
Begin
  GlTr(57);
End;

Procedure glFinish;
Begin
  GlTr(58);
End;

Function glGetError : LongInt;
Begin
  GlTr(59);
  glGetError := 0;
  If Not GlOk Then Exit;
  glGetError := Gc^.Err;
  Gc^.Err := 0;
End;

Function glGetString(N : LongInt) : LongInt;
Begin
  GlTr(60);
  glGetString := 0;
  If (N >= $1F00) And (N <= $1F03) Then glGetString := GlStrs[N - $1F00];
End;

Procedure glDrawBuffer(M : LongInt);
Begin
  GlTr(61);
End;

Procedure glReadBuffer(M : LongInt);
Begin
  GlTr(62);
End;

{ ------------------------------------------------------------------ }
{ Brouillard, lumieres, materiaux                                    }
{ ------------------------------------------------------------------ }

{ parametre GL : K-ieme valeur (I : entiers, F : flottants 32 bits) }
Function GlPv(P, K : LongInt; Fl : Boolean) : Double;
Begin
  If Fl Then GlPv := FlM(P + K * 4) Else GlPv := RdL(P + K * 4);
End;

{ couleur entiere -> [0, 1] (glLightiv, glMaterialiv...) }
Function GlPc(P, K : LongInt; Fl : Boolean) : Double;
Begin
  If Fl Then GlPc := FlM(P + K * 4)
  Else GlPc := RdL(P + K * 4) / 2147483647.0;
End;

Procedure GlFog(N, P : LongInt; Fl : Boolean);
Var K : LongInt;
Begin
  If Not GlOk Or (P = 0) Then Exit;
  Case N Of
    $0B65 :
    Begin
      Gc^.S.FogMd := DRound(GlPv(P, 0, Fl));
      If Fl Then Gc^.S.FogMd := DRound(FlM(P));
    End;
    $0B62 : Gc^.S.FogD := GlPv(P, 0, Fl);
    $0B63 : Gc^.S.FogS := GlPv(P, 0, Fl);
    $0B64 : Gc^.S.FogE := GlPv(P, 0, Fl);
    $0B66 : For K := 0 To 3 Do Gc^.S.FogC[K] := GlPc(P, K, Fl);
  End;
End;

Procedure glFogfv(N, P : LongInt);
Begin
  GlTr(63);
  GlFog(N, P, True);
End;

Procedure glFogiv(N, P : LongInt);
Begin
  GlTr(64);
  GlFog(N, P, False);
End;

Procedure glFogf(N, V : LongInt);
Begin
  GlTr(65);
  GlFog(N, LongInt(@V), True);
End;

Procedure glFogi(N, V : LongInt);
Begin
  GlTr(66);
  GlFog(N, LongInt(@V), False);
End;

Procedure GlLight(L, N, P : LongInt; Fl : Boolean);
Var I, K : LongInt; M : TMat; X, Y, Z, W : Double;
Begin
  If Not GlOk Or (P = 0) Then Exit;
  I := L - $4000;
  If (I < 0) Or (I > 7) Then Exit;
  M := Gc^.MV[Gc^.MVTop];
  Case N Of
    $1200 : For K := 0 To 3 Do Gc^.S.Lt[I].Amb[K] := GlPc(P, K, Fl);
    $1201 : For K := 0 To 3 Do Gc^.S.Lt[I].Dif[K] := GlPc(P, K, Fl);
    $1202 : For K := 0 To 3 Do Gc^.S.Lt[I].Spe[K] := GlPc(P, K, Fl);
    $1203 :
    Begin
      { position transformee par la matrice modele-vue courante }
      X := GlPv(P, 0, Fl); Y := GlPv(P, 1, Fl); Z := GlPv(P, 2, Fl);
      W := GlPv(P, 3, Fl);
      Gc^.S.Lt[I].Pos[0] := X * M[0] + Y * M[4] + Z * M[8] + W * M[12];
      Gc^.S.Lt[I].Pos[1] := X * M[1] + Y * M[5] + Z * M[9] + W * M[13];
      Gc^.S.Lt[I].Pos[2] := X * M[2] + Y * M[6] + Z * M[10] + W * M[14];
      Gc^.S.Lt[I].Pos[3] := W;
    End;
    $1204 :
    Begin
      X := GlPv(P, 0, Fl); Y := GlPv(P, 1, Fl); Z := GlPv(P, 2, Fl);
      Gc^.S.Lt[I].SDir[0] := X * M[0] + Y * M[4] + Z * M[8];
      Gc^.S.Lt[I].SDir[1] := X * M[1] + Y * M[5] + Z * M[9];
      Gc^.S.Lt[I].SDir[2] := X * M[2] + Y * M[6] + Z * M[10];
    End;
    $1205 : Gc^.S.Lt[I].SExp := GlPv(P, 0, Fl);
    $1206 : Gc^.S.Lt[I].SCut := GlPv(P, 0, Fl);
    $1207 : Gc^.S.Lt[I].A0 := GlPv(P, 0, Fl);
    $1208 : Gc^.S.Lt[I].A1 := GlPv(P, 0, Fl);
    $1209 : Gc^.S.Lt[I].A2 := GlPv(P, 0, Fl);
  End;
End;

Procedure glLightfv(L, N, P : LongInt);
Begin
  GlTr(67);
  GlLight(L, N, P, True);
End;

Procedure glLightiv(L, N, P : LongInt);
Begin
  GlTr(68);
  GlLight(L, N, P, False);
End;

Procedure glLightf(L, N, V : LongInt);
Begin
  GlTr(69);
  GlLight(L, N, LongInt(@V), True);
End;

Procedure glLighti(L, N, V : LongInt);
Begin
  GlTr(70);
  GlLight(L, N, LongInt(@V), False);
End;

Procedure glGetLightfv(L, N, P : LongInt);
Var I, K : LongInt;
Begin
  GlTr(71);
  If Not GlOk Or (P = 0) Then Exit;
  I := L - $4000;
  If (I < 0) Or (I > 7) Then Exit;
  For K := 0 To 3 Do
    Case N Of
      $1200 : WrL(P + K * 4, LFl(Gc^.S.Lt[I].Amb[K]));
      $1201 : WrL(P + K * 4, LFl(Gc^.S.Lt[I].Dif[K]));
      $1202 : WrL(P + K * 4, LFl(Gc^.S.Lt[I].Spe[K]));
      $1203 : WrL(P + K * 4, LFl(Gc^.S.Lt[I].Pos[K]));
    End;
End;

Procedure glGetLightiv(L, N, P : LongInt);
Begin
  GlTr(72);
  glGetLightfv(L, N, P);
End;

Procedure GlLModel(N, P : LongInt; Fl : Boolean);
Var K : LongInt;
Begin
  If Not GlOk Or (P = 0) Then Exit;
  If N = $0B53 Then
    For K := 0 To 3 Do Gc^.S.LMAmb[K] := GlPc(P, K, Fl);
End;

Procedure glLightModelfv(N, P : LongInt);
Begin
  GlTr(73);
  GlLModel(N, P, True);
End;

Procedure glLightModeliv(N, P : LongInt);
Begin
  GlTr(74);
  GlLModel(N, P, False);
End;

Procedure glLightModelf(N, V : LongInt);
Begin
  GlTr(75);
End;

Procedure glLightModeli(N, V : LongInt);
Begin
  GlTr(76);
End;

Procedure GlMaterial(F, N, P : LongInt; Fl : Boolean);
Var K : LongInt;
Begin
  If Not GlOk Or (P = 0) Or (F = $404) Then Exit;
  For K := 0 To 3 Do
    Case N Of
      $1200 : Gc^.S.MAmb[K] := GlPc(P, K, Fl);
      $1201 : Gc^.S.MDif[K] := GlPc(P, K, Fl);
      $1202 : Gc^.S.MSpe[K] := GlPc(P, K, Fl);
      $1600 : Gc^.S.MEmi[K] := GlPc(P, K, Fl);
      $1602 :
      Begin
        Gc^.S.MAmb[K] := GlPc(P, K, Fl); Gc^.S.MDif[K] := GlPc(P, K, Fl);
      End;
    End;
  If N = $1601 Then Gc^.S.MShin := GlPv(P, 0, Fl);
End;

Procedure glMaterialfv(F, N, P : LongInt);
Begin
  GlTr(77);
  GlMaterial(F, N, P, True);
End;

Procedure glMaterialiv(F, N, P : LongInt);
Begin
  GlTr(78);
  GlMaterial(F, N, P, False);
End;

Procedure glMaterialf(F, N, V : LongInt);
Begin
  GlTr(79);
  GlMaterial(F, N, LongInt(@V), True);
End;

Procedure glMateriali(F, N, V : LongInt);
Begin
  GlTr(80);
  GlMaterial(F, N, LongInt(@V), False);
End;

Procedure glGetMaterialfv(F, N, P : LongInt);
Var K : LongInt;
Begin
  GlTr(81);
  If Not GlOk Or (P = 0) Then Exit;
  For K := 0 To 3 Do
    Case N Of
      $1200 : WrL(P + K * 4, LFl(Gc^.S.MAmb[K]));
      $1201 : WrL(P + K * 4, LFl(Gc^.S.MDif[K]));
      $1202 : WrL(P + K * 4, LFl(Gc^.S.MSpe[K]));
      $1600 : WrL(P + K * 4, LFl(Gc^.S.MEmi[K]));
    End;
  If N = $1601 Then WrL(P, LFl(Gc^.S.MShin));
End;

Procedure glGetMaterialiv(F, N, P : LongInt);
Begin
  GlTr(82);
  glGetMaterialfv(F, N, P);
End;

Procedure glColorMaterial(F, M : LongInt);
Begin
  GlTr(83);
  If GlOk Then Gc^.S.CmMode := M;
End;

{ ------------------------------------------------------------------ }
{ Matrices                                                           }
{ ------------------------------------------------------------------ }

Procedure glMatrixMode(M : LongInt);
Begin
  GlTr(84);
  If GlOk Then Gc^.MMode := M;
End;

Procedure glLoadIdentity;
Var M : TMat;
Begin
  GlTr(85);
  If Not GlOk Then Exit;
  MatId(M);
  GlLoadM(M);
End;

Procedure glLoadMatrixf(P : LongInt);
Var M : TMat;
Begin
  GlTr(86);
  If Not GlOk Or (P = 0) Then Exit;
  MatLoad(M, P);
  GlLoadM(M);
End;

Procedure glLoadMatrixd(P : LongInt);
Var M : TMat; I : LongInt;
Begin
  GlTr(87);
  If Not GlOk Or (P = 0) Then Exit;
  For I := 0 To 15 Do M[I] := DbM(P + I * 8);
  GlLoadM(M);
End;

Procedure glMultMatrixf(P : LongInt);
Var M : TMat;
Begin
  GlTr(88);
  If Not GlOk Or (P = 0) Then Exit;
  MatLoad(M, P);
  GlMulM(M);
End;

Procedure glMultMatrixd(P : LongInt);
Var M : TMat; I : LongInt;
Begin
  GlTr(89);
  If Not GlOk Or (P = 0) Then Exit;
  For I := 0 To 15 Do M[I] := DbM(P + I * 8);
  GlMulM(M);
End;

Procedure glPushMatrix;
Begin
  GlTr(90);
  If Not GlOk Then Exit;
  Case Gc^.MMode Of
    $1701 :
      If Gc^.PRTop < 3 Then
      Begin
        Gc^.PR[Gc^.PRTop + 1] := Gc^.PR[Gc^.PRTop]; Inc(Gc^.PRTop);
      End
      Else GlErr($503);
    $1702 :
      If Gc^.TXTop < 3 Then
      Begin
        Gc^.TX[Gc^.TXTop + 1] := Gc^.TX[Gc^.TXTop]; Inc(Gc^.TXTop);
      End
      Else GlErr($503);
  Else
    If Gc^.MVTop < 31 Then
    Begin
      Gc^.MV[Gc^.MVTop + 1] := Gc^.MV[Gc^.MVTop]; Inc(Gc^.MVTop);
    End
    Else GlErr($503);
  End;
End;

Procedure glPopMatrix;
Begin
  GlTr(91);
  If Not GlOk Then Exit;
  Case Gc^.MMode Of
    $1701 : If Gc^.PRTop > 0 Then Dec(Gc^.PRTop) Else GlErr($504);
    $1702 : If Gc^.TXTop > 0 Then Dec(Gc^.TXTop) Else GlErr($504);
  Else
    If Gc^.MVTop > 0 Then Dec(Gc^.MVTop) Else GlErr($504);
  End;
  GlMChanged;
End;

Procedure GlTrans(X, Y, Z : Double);
Var M : TMat;
Begin
  If Not GlOk Then Exit;
  MatId(M);
  M[12] := X; M[13] := Y; M[14] := Z;
  GlMulM(M);
End;

Procedure GlScale(X, Y, Z : Double);
Var M : TMat;
Begin
  If Not GlOk Then Exit;
  MatId(M);
  M[0] := X; M[5] := Y; M[10] := Z;
  GlMulM(M);
End;

Procedure GlRot(A, X, Y, Z : Double);
Var M : TMat; C, S, T, D : Double;
Begin
  If Not GlOk Then Exit;
  D := Sqrt(X * X + Y * Y + Z * Z);
  If D < 0.0000001 Then Exit;
  X := X / D; Y := Y / D; Z := Z / D;
  A := A * 3.14159265358979 / 180;
  C := Cos(A); S := Sin(A); T := 1 - C;
  MatId(M);
  M[0] := X * X * T + C; M[1] := Y * X * T + Z * S; M[2] := X * Z * T - Y * S;
  M[4] := X * Y * T - Z * S; M[5] := Y * Y * T + C; M[6] := Y * Z * T + X * S;
  M[8] := X * Z * T + Y * S; M[9] := Y * Z * T - X * S; M[10] := Z * Z * T + C;
  GlMulM(M);
End;

Procedure glTranslatef(X, Y, Z : LongInt);
Begin
  GlTr(92);
  GlTrans(FlL(X), FlL(Y), FlL(Z));
End;

Procedure glTranslated(XL, XH, YL, YH, ZL, ZH : LongInt);
Begin
  GlTr(93);
  GlTrans(DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH));
End;

Procedure glScalef(X, Y, Z : LongInt);
Begin
  GlTr(94);
  GlScale(FlL(X), FlL(Y), FlL(Z));
End;

Procedure glScaled(XL, XH, YL, YH, ZL, ZH : LongInt);
Begin
  GlTr(95);
  GlScale(DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH));
End;

Procedure glRotatef(A, X, Y, Z : LongInt);
Begin
  GlTr(96);
  GlRot(FlL(A), FlL(X), FlL(Y), FlL(Z));
End;

Procedure glRotated(AL, AH, XL, XH, YL, YH, ZL, ZH : LongInt);
Begin
  GlTr(97);
  GlRot(DblOf(AL, AH), DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH));
End;

Procedure GlOrthoM(L, R, B, T, N, F : Double);
Var M : TMat;
Begin
  If Not GlOk Then Exit;
  If (R = L) Or (T = B) Or (F = N) Then
  Begin
    GlErr($501);
    Exit;
  End;
  MatId(M);
  M[0] := 2 / (R - L); M[5] := 2 / (T - B); M[10] := -2 / (F - N);
  M[12] := -(R + L) / (R - L); M[13] := -(T + B) / (T - B);
  M[14] := -(F + N) / (F - N);
  GlMulM(M);
End;

Procedure GlFrustumM(L, R, B, T, N, F : Double);
Var M : TMat;
Begin
  If Not GlOk Then Exit;
  If (R = L) Or (T = B) Or (F = N) Or (N <= 0) Then
  Begin
    GlErr($501);
    Exit;
  End;
  MatId(M);
  M[0] := 2 * N / (R - L); M[5] := 2 * N / (T - B);
  M[8] := (R + L) / (R - L); M[9] := (T + B) / (T - B);
  M[10] := -(F + N) / (F - N); M[11] := -1;
  M[14] := -2 * F * N / (F - N); M[15] := 0;
  GlMulM(M);
End;

Procedure glOrtho(LL, LH, RL, RH, BL, BH, TL, TH, NL, NH, FL, FH : LongInt);
Begin
  GlTr(98);
  GlOrthoM(DblOf(LL, LH), DblOf(RL, RH), DblOf(BL, BH), DblOf(TL, TH),
           DblOf(NL, NH), DblOf(FL, FH));
End;

Procedure glFrustum(LL, LH, RL, RH, BL, BH, TL, TH, NL, NH, FL, FH : LongInt);
Begin
  GlTr(99);
  GlFrustumM(DblOf(LL, LH), DblOf(RL, RH), DblOf(BL, BH), DblOf(TL, TH),
             DblOf(NL, NH), DblOf(FL, FH));
End;

{ ------------------------------------------------------------------ }
{ Generation de coordonnees de texture                               }
{ ------------------------------------------------------------------ }

Procedure GlTexGenP(C, N, P : LongInt; Ty : LongInt);
Var I, K : LongInt; V : Double;
Begin
  If Not GlOk Or (P = 0) Then Exit;
  I := C - $2000;
  If (I < 0) Or (I > 3) Then Exit;
  If N = $2500 Then
  Begin
    Case Ty Of
      0 : V := RdL(P);
      1 : V := FlM(P);
    Else
      V := DbM(P);
    End;
    Gc^.S.TgMd[I] := DRound(V);
    Exit;
  End;
  For K := 0 To 3 Do
  Begin
    Case Ty Of
      0 : V := RdL(P + K * 4);
      1 : V := FlM(P + K * 4);
    Else
      V := DbM(P + K * 8);
    End;
    If N = $2501 Then Gc^.S.TgOP[I * 4 + K] := V
    Else If N = $2502 Then Gc^.S.TgEP[I * 4 + K] := V;
  End;
End;

Procedure glTexGeni(C, N, V : LongInt);
Begin
  GlTr(100);
  GlTexGenP(C, N, LongInt(@V), 0);
End;

Procedure glTexGenf(C, N, V : LongInt);
Begin
  GlTr(101);
  GlTexGenP(C, N, LongInt(@V), 1);
End;

Procedure glTexGend(C, N, VL, VH : LongInt);
Var D : Double;
Begin
  GlTr(102);
  D := DblOf(VL, VH);
  GlTexGenP(C, N, LongInt(@D), 2);
End;

Procedure glTexGeniv(C, N, P : LongInt);
Begin
  GlTr(103);
  GlTexGenP(C, N, P, 0);
End;

Procedure glTexGenfv(C, N, P : LongInt);
Begin
  GlTr(104);
  GlTexGenP(C, N, P, 1);
End;

Procedure glTexGendv(C, N, P : LongInt);
Begin
  GlTr(105);
  GlTexGenP(C, N, P, 2);
End;

Procedure glGetTexGeniv(C, N, P : LongInt);
Begin
  GlTr(106);
  If GlOk And (P <> 0) And (N = $2500) And (C >= $2000) And (C <= $2003) Then
    WrL(P, Gc^.S.TgMd[C - $2000]);
End;

Procedure glGetTexGenfv(C, N, P : LongInt);
Begin
  GlTr(107);
  If GlOk And (P <> 0) And (N = $2500) And (C >= $2000) And (C <= $2003) Then
    WrL(P, LFl(Gc^.S.TgMd[C - $2000]));
End;

Procedure glGetTexGendv(C, N, P : LongInt);
Begin
  GlTr(108);
  If GlOk And (P <> 0) And (N = $2500) And (C >= $2000) And (C <= $2003) Then
    DbPut(P, Gc^.S.TgMd[C - $2000]);
End;

{ ------------------------------------------------------------------ }
{ Textures                                                           }
{ ------------------------------------------------------------------ }

Procedure glGenTextures(N, P : LongInt);
Var I, K : LongInt;
Begin
  GlTr(109);
  If (GlTexT = 0) Or (P = 0) Then Exit;
  K := 1;
  For I := 0 To N - 1 Do
  Begin
    While (K < GlMaxTex) And (RdL(GlTexEnt(K)) <> 0) Do Inc(K);
    If K >= GlMaxTex Then
    Begin
      WrL(P + I * 4, 0);
      GlErr($505);
    End
    Else
    Begin
      WrL(GlTexEnt(K), 2);          { reserve }
      WrL(P + I * 4, K);
      Inc(K);
    End;
  End;
End;

Procedure GlTexFree(N : LongInt);
Var E : LongInt;
Begin
  E := GlTexEnt(N);
  If E = 0 Then Exit;
  GlSurfFree(RdL(E + 4));
  FillMem(E, GlTexSz, 0);
End;

Procedure glDeleteTextures(N, P : LongInt);
Var I, T : LongInt;
Begin
  GlTr(110);
  If (GlTexT = 0) Or (P = 0) Then Exit;
  For I := 0 To N - 1 Do
  Begin
    T := RdL(P + I * 4);
    If (T > 0) And (T < GlMaxTex) Then
    Begin
      GlTexFree(T);
      If GlOk Then
      Begin
        If Gc^.S.Bound[0] = T Then Gc^.S.Bound[0] := 0;
        If Gc^.S.Bound[1] = T Then Gc^.S.Bound[1] := 0;
      End;
    End;
  End;
End;

Function glIsTexture(T : LongInt) : LongInt;
Begin
  GlTr(111);
  glIsTexture := 0;
  If (T > 0) And (GlTexEnt(T) <> 0) Then
    glIsTexture := Ord(RdL(GlTexEnt(T)) <> 0);
End;

Function glAreTexturesResident(N, P, R : LongInt) : LongInt;
Var I : LongInt;
Begin
  GlTr(112);
  If R <> 0 Then
    For I := 0 To N - 1 Do WrB(R + I, 1);
  glAreTexturesResident := 1;
End;

Procedure glPrioritizeTextures(N, P, R : LongInt);
Begin
  GlTr(113);
End;

{ entree de la texture liee a l'unite active (creee au besoin) }
Function GlBoundEnt : LongInt;
Var E : LongInt;
Begin
  GlBoundEnt := 0;
  If Not GlOk Then Exit;
  E := GlTexEnt(Gc^.S.Bound[Gc^.S.ActTex]);
  If E = 0 Then Exit;
  If RdL(E) <> 1 Then
  Begin
    WrL(E, 1);
    WrL(E + 16, $2901); WrL(E + 20, $2901);
  End;
  GlBoundEnt := E;
End;

Procedure glBindTexture(T, N : LongInt);
Begin
  GlTr(114);
  If Not GlOk Then Exit;
  If (N < 0) Or (N >= GlMaxTex) Then
  Begin
    GlErr($505);
    Exit;
  End;
  Gc^.S.Bound[Gc^.S.ActTex] := N;
  GlBoundEnt;
End;

{ format de stockage selon le format interne : 7 (1555), 8 (4444),
  2 (565), 6 (ARGB 32 bits), 5 (XRGB 32 bits) }
Function GlStore(F : LongInt) : LongInt;
Begin
  Case F Of
    $8057 : GlStore := 7;
    $8055, $8056 : GlStore := 8;
    $2A10, $804F, $8050 : GlStore := 2;
    3, $1907, $8051..$8054, $80E0 : GlStore := 5;
  Else
    GlStore := 6;
  End;
End;

Function GlTexSurf(K, W, H : LongInt) : LongInt;
Begin
  Case K Of
    7 : GlTexSurf := GlSurf(W, H, 16, $7C00, $3E0, $1F, $8000);
    8 : GlTexSurf := GlSurf(W, H, 16, $F00, $F0, $F, $F000);
    2 : GlTexSurf := GlSurf(W, H, 16, $F800, $7E0, $1F, 0);
    5 : GlTexSurf := GlSurf(W, H, 32, $FF0000, $FF00, $FF, 0);
  Else
    GlTexSurf := GlSurf(W, H, 32, $FF0000, $FF00, $FF, LongInt($FF000000));
  End;
End;

{ copier une image (W x H, format F, type T) en (X, Y) de la surface }
Procedure GlTexPut(S, X, Y, W, H, F, T, P : LongInt);
Var I, J, A, B, SW, SH : LongInt;
Begin
  If (P = 0) Or (S = 0) Then Exit;
  SW := RdL(S + 64); SH := RdL(S + 68);
  B := GlPixBytes(F, T);
  For J := 0 To H - 1 Do
  Begin
    If (Y + J < 0) Or (Y + J >= SH) Then Continue;
    A := GlRowAdr(P, W, J, F, T, False);
    For I := 0 To W - 1 Do
      If (X + I >= 0) And (X + I < SW) Then
        GlWrTex(S, X + I, Y + J, GlRdPix(A + I * B, F, T));
  End;
End;

Procedure glTexImage2D(Tg, Lv, IF2, W, H, Bd, F, T, P : LongInt);
Var E, K : LongInt;
Begin
  GlTr(115);
  If (Lv <> 0) Or (W <= 0) Or (H <= 0) Then Exit;
  E := GlBoundEnt;
  If E = 0 Then Exit;
  K := GlStore(IF2);
  If (RdL(E + 4) = 0) Or (RdL(E + 8) <> W) Or (RdL(E + 12) <> H)
     Or (RdL(E + 24) <> IF2) Then
  Begin
    GlSurfFree(RdL(E + 4));
    WrL(E + 4, GlTexSurf(K, W, H));
    If RdL(E + 4) = 0 Then
    Begin
      GlErr($505);
      Exit;
    End;
  End;
  HeapCheck('glTexImage2D');
  WrL(E + 8, W); WrL(E + 12, H); WrL(E + 24, IF2);
  WrL(E + 28, Ord((K = 6) Or (K = 7) Or (K = 8)));
  GlTexPut(RdL(E + 4), 0, 0, W, H, F, T, P);
End;

Procedure glTexImage1D(Tg, Lv, IF2, W, Bd, F, T, P : LongInt);
Begin
  GlTr(116);
  glTexImage2D(Tg, Lv, IF2, W, 1, Bd, F, T, P);
End;

Procedure glTexSubImage2D(Tg, Lv, X, Y, W, H, F, T, P : LongInt);
Var E : LongInt;
Begin
  GlTr(117);
  If Lv <> 0 Then Exit;
  E := GlBoundEnt;
  If (E = 0) Or (RdL(E + 4) = 0) Then Exit;
  GlTexPut(RdL(E + 4), X, Y, W, H, F, T, P);
End;

Procedure glTexSubImage1D(Tg, Lv, X, W, F, T, P : LongInt);
Begin
  GlTr(118);
  glTexSubImage2D(Tg, Lv, X, 0, W, 1, F, T, P);
End;

{ copie depuis le tampon de couleur (origine en bas a gauche) }
Procedure GlCopyTex(S, DX, DY, X, Y, W, H : LongInt);
Var I, J, SY, A : LongInt;
Begin
  If (S = 0) Or Not GlOk Or (Gc^.RT = 0) Then Exit;
  For J := 0 To H - 1 Do
  Begin
    SY := Gc^.BH - 1 - (Y + J);
    If (SY < 0) Or (SY >= Gc^.BH) Then Continue;
    A := RdL(Gc^.RT + 76) + SY * RdL(Gc^.RT + 72);
    For I := 0 To W - 1 Do
      If (X + I >= 0) And (X + I < Gc^.BW) And (DX + I < RdL(S + 64)) And
         (DY + J < RdL(S + 68)) Then
        GlWrTex(S, DX + I, DY + J, RdL(A + (X + I) * 4) Or
                LongInt($FF000000));
  End;
End;

Procedure glCopyTexImage2D(Tg, Lv, IF2, X, Y, W, H, Bd : LongInt);
Var E : LongInt;
Begin
  GlTr(119);
  If Lv <> 0 Then Exit;
  glTexImage2D(Tg, 0, IF2, W, H, 0, $1908, $1401, 0);
  E := GlBoundEnt;
  If E <> 0 Then GlCopyTex(RdL(E + 4), 0, 0, X, Y, W, H);
End;

Procedure glCopyTexImage1D(Tg, Lv, IF2, X, Y, W, Bd : LongInt);
Begin
  GlTr(120);
  glCopyTexImage2D(Tg, Lv, IF2, X, Y, W, 1, Bd);
End;

Procedure glCopyTexSubImage2D(Tg, Lv, DX, DY, X, Y, W, H : LongInt);
Var E : LongInt;
Begin
  GlTr(121);
  If Lv <> 0 Then Exit;
  E := GlBoundEnt;
  If E <> 0 Then GlCopyTex(RdL(E + 4), DX, DY, X, Y, W, H);
End;

Procedure glCopyTexSubImage1D(Tg, Lv, DX, X, Y, W : LongInt);
Begin
  GlTr(122);
  glCopyTexSubImage2D(Tg, Lv, DX, 0, X, Y, W, 1);
End;

Procedure glGetTexImage(Tg, Lv, F, T, P : LongInt);
Begin
  GlTr(123);
  GlTodo('glGetTexImage');
End;

Procedure GlTexParam(N, P : LongInt; Fl : Boolean);
Var E, V : LongInt;
Begin
  E := GlBoundEnt;
  If (E = 0) Or (P = 0) Then Exit;
  If Fl Then V := DRound(FlM(P)) Else V := RdL(P);
  Case N Of
    $2802 : WrL(E + 16, V);
    $2803 : WrL(E + 20, V);
  End;
End;

Procedure glTexParameteri(T, N, V : LongInt);
Begin
  GlTr(124);
  GlTexParam(N, LongInt(@V), False);
End;

Procedure glTexParameterf(T, N, V : LongInt);
Begin
  GlTr(125);
  GlTexParam(N, LongInt(@V), True);
End;

Procedure glTexParameteriv(T, N, P : LongInt);
Begin
  GlTr(126);
  GlTexParam(N, P, False);
End;

Procedure glTexParameterfv(T, N, P : LongInt);
Begin
  GlTr(127);
  GlTexParam(N, P, True);
End;

Procedure glGetTexParameteriv(T, N, P : LongInt);
Var E : LongInt;
Begin
  GlTr(128);
  E := GlBoundEnt;
  If (E = 0) Or (P = 0) Then Exit;
  Case N Of
    $2802 : WrL(P, RdL(E + 16));
    $2803 : WrL(P, RdL(E + 20));
    $2800 : WrL(P, $2601);
    $2801 : WrL(P, $2601);
  Else
    WrL(P, 0);
  End;
End;

Procedure glGetTexParameterfv(T, N, P : LongInt);
Begin
  GlTr(129);
  glGetTexParameteriv(T, N, P);
  If P <> 0 Then WrL(P, LFl(RdL(P)));
End;

Procedure glGetTexLevelParameteriv(T, Lv, N, P : LongInt);
Var E, V : LongInt;
Begin
  GlTr(130);
  If P = 0 Then Exit;
  WrL(P, 0);
  E := GlBoundEnt;
  If (E = 0) Or (Lv <> 0) Then Exit;
  V := 0;
  Case N Of
    $1000 : V := RdL(E + 8);
    $1001 : V := RdL(E + 12);
    $1003 : V := RdL(E + 24);
    $805C..$805E : V := 8;
    $805F : V := 8 * RdL(E + 28);
  End;
  WrL(P, V);
End;

Procedure glGetTexLevelParameterfv(T, Lv, N, P : LongInt);
Begin
  GlTr(131);
  glGetTexLevelParameteriv(T, Lv, N, P);
  If P <> 0 Then WrL(P, LFl(RdL(P)));
End;

Procedure GlTexEnv(N, P : LongInt; Fl : Boolean);
Var K : LongInt;
Begin
  If Not GlOk Or (P = 0) Then Exit;
  If N = $2200 Then
  Begin
    If Fl Then Gc^.S.Env[Gc^.S.ActTex] := DRound(FlM(P))
    Else Gc^.S.Env[Gc^.S.ActTex] := RdL(P);
  End
  Else If N = $2201 Then
    For K := 0 To 3 Do Gc^.S.EnvC[K] := GlPc(P, K, Fl);
End;

Procedure glTexEnvi(T, N, V : LongInt);
Begin
  GlTr(132);
  GlTexEnv(N, LongInt(@V), False);
End;

Procedure glTexEnvf(T, N, V : LongInt);
Begin
  GlTr(133);
  GlTexEnv(N, LongInt(@V), True);
End;

Procedure glTexEnviv(T, N, P : LongInt);
Begin
  GlTr(134);
  GlTexEnv(N, P, False);
End;

Procedure glTexEnvfv(T, N, P : LongInt);
Begin
  GlTr(135);
  GlTexEnv(N, P, True);
End;

Procedure glGetTexEnviv(T, N, P : LongInt);
Begin
  GlTr(136);
  If GlOk And (P <> 0) And (N = $2200) Then
    WrL(P, Gc^.S.Env[Gc^.S.ActTex]);
End;

Procedure glGetTexEnvfv(T, N, P : LongInt);
Begin
  GlTr(137);
  If GlOk And (P <> 0) And (N = $2200) Then
    WrL(P, LFl(Gc^.S.Env[Gc^.S.ActTex]));
End;

Procedure glPixelStorei(N, V : LongInt);
Begin
  GlTr(138);
  If Not GlOk Then Exit;
  Case N Of
    $0CF5 : Gc^.CA.UnpA := V;
    $0CF2 : Gc^.CA.UnpRL := V;
    $0D05 : Gc^.CA.PackA := V;
  End;
End;

Procedure glPixelStoref(N, V : LongInt);
Begin
  GlTr(139);
  glPixelStorei(N, DRound(FlL(V)));
End;

{ multitexture (GL_ARB_multitexture) }
Procedure glActiveTextureARB(U : LongInt);
Begin
  GlTr(140);
  If GlOk And (U >= $84C0) And (U <= $84C1) Then Gc^.S.ActTex := U - $84C0;
End;

Procedure glClientActiveTextureARB(U : LongInt);
Begin
  GlTr(141);
  If GlOk And (U >= $84C0) And (U <= $84C1) Then Gc^.CA.CliTex := U - $84C0;
End;

{ ------------------------------------------------------------------ }
{ Pixels                                                             }
{ ------------------------------------------------------------------ }

Procedure glReadPixels(X, Y, W, H, F, T, P : LongInt);
Var I, J, A, D, C, SY, B : LongInt;
Begin
  GlTr(142);
  If Not GlOk Or (P = 0) Or (Gc^.RT = 0) Then Exit;
  B := GlComps(F);
  For J := 0 To H - 1 Do
  Begin
    SY := Gc^.BH - 1 - (Y + J);
    D := GlRowAdr(P, W, J, F, $1401, True);
    If (SY < 0) Or (SY >= Gc^.BH) Then Continue;
    A := RdL(Gc^.RT + 76) + SY * RdL(Gc^.RT + 72);
    For I := 0 To W - 1 Do
    Begin
      If (X + I < 0) Or (X + I >= Gc^.BW) Then C := 0
      Else C := RdL(A + (X + I) * 4);
      Case F Of
        $80E0, $80E1 :
        Begin
          WrB(D, C); WrB(D + 1, C Shr 8); WrB(D + 2, C Shr 16);
          If B = 4 Then WrB(D + 3, 255);
        End;
      Else
        Begin
          WrB(D, C Shr 16);
          If B > 1 Then WrB(D + 1, C Shr 8);
          If B > 2 Then WrB(D + 2, C);
          If B > 3 Then WrB(D + 3, 255);
        End;
      End;
      D := D + B;
    End;
  End;
End;

Procedure glDrawPixels(W, H, F, T, P : LongInt);
Var I, J, A, D, X0, Y0, SY, B, C : LongInt;
Begin
  GlTr(143);
  If Not GlOk Or (P = 0) Or (Gc^.RT = 0) Then Exit;
  X0 := DRound(Gc^.RPos[0]); Y0 := DRound(Gc^.RPos[1]);
  B := GlPixBytes(F, T);
  For J := 0 To H - 1 Do
  Begin
    SY := Gc^.BH - 1 - (Y0 + J);
    If (SY < 0) Or (SY >= Gc^.BH) Then Continue;
    A := GlRowAdr(P, W, J, F, T, False);
    D := RdL(Gc^.RT + 76) + SY * RdL(Gc^.RT + 72);
    For I := 0 To W - 1 Do
      If (X0 + I >= 0) And (X0 + I < Gc^.BW) Then
      Begin
        C := GlRdPix(A + I * B, F, T);
        If (Gc^.S.AlOn = 0) Or (((C Shr 24) And 255) > 0) Then
          WrL(D + (X0 + I) * 4, C And $FFFFFF);
      End;
  End;
End;

{ ------------------------------------------------------------------ }
{ Pile d'attributs                                                   }
{ ------------------------------------------------------------------ }

Procedure glPushAttrib(M : LongInt);
Begin
  GlTr(144);
  If Not GlOk Then Exit;
  If Gc^.ASp >= 8 Then
  Begin
    GlErr($503);
    Exit;
  End;
  Gc^.AStk[Gc^.ASp] := Gc^.S;
  Inc(Gc^.ASp);
End;

Procedure glPopAttrib;
Begin
  GlTr(145);
  If Not GlOk Then Exit;
  If Gc^.ASp <= 0 Then
  Begin
    GlErr($504);
    Exit;
  End;
  Dec(Gc^.ASp);
  Gc^.S := Gc^.AStk[Gc^.ASp];
End;

Procedure glPushClientAttrib(M : LongInt);
Begin
  GlTr(146);
  If Not GlOk Then Exit;
  If Gc^.CSp >= 4 Then
  Begin
    GlErr($503);
    Exit;
  End;
  Gc^.CStk[Gc^.CSp] := Gc^.CA;
  Inc(Gc^.CSp);
End;

Procedure glPopClientAttrib;
Begin
  GlTr(147);
  If Not GlOk Then Exit;
  If Gc^.CSp <= 0 Then
  Begin
    GlErr($504);
    Exit;
  End;
  Dec(Gc^.CSp);
  Gc^.CA := Gc^.CStk[Gc^.CSp];
End;

{ ------------------------------------------------------------------ }
{ Interrogations                                                     }
{ ------------------------------------------------------------------ }

Var
  GlQv : Array[0..15] Of Double;

{ valeurs de l'etat N dans GlQv ; resultat : nombre (0 : inconnu) }
Function GlQuery(N : LongInt) : LongInt;
Var K, C : LongInt; M : TMat;
Begin
  GlQuery := 1;
  For K := 0 To 15 Do GlQv[K] := 0;
  C := 1;
  Case N Of
    $0BA2 :
    Begin
      GlQv[0] := Gc^.S.VpX; GlQv[1] := Gc^.S.VpY;
      GlQv[2] := Gc^.S.VpW; GlQv[3] := Gc^.S.VpH; C := 4;
    End;
    $0C10 :
    Begin
      GlQv[0] := Gc^.S.ScX; GlQv[1] := Gc^.S.ScY;
      GlQv[2] := Gc^.S.ScW; GlQv[3] := Gc^.S.ScH; C := 4;
    End;
    $0BA6, $0BA7, $0BA8 :
    Begin
      Case N Of
        $0BA6 : M := Gc^.MV[Gc^.MVTop];
        $0BA7 : M := Gc^.PR[Gc^.PRTop];
      Else
        M := Gc^.TX[Gc^.TXTop];
      End;
      For K := 0 To 15 Do GlQv[K] := M[K];
      C := 16;
    End;
    $0BA0 : GlQv[0] := Gc^.MMode;
    $0BA3 : GlQv[0] := Gc^.MVTop + 1;
    $0BA4 : GlQv[0] := Gc^.PRTop + 1;
    $0BA5 : GlQv[0] := Gc^.TXTop + 1;
    $0D33 : GlQv[0] := 1024;
    $0D31 : GlQv[0] := 8;
    $0D32 : GlQv[0] := 6;
    $0D36 : GlQv[0] := 32;
    $0D38, $0D39 : GlQv[0] := 4;
    $0D35 : GlQv[0] := 8;
    $0D3B : GlQv[0] := 4;
    $0D3A :
    Begin
      GlQv[0] := 2048; GlQv[1] := 2048; C := 2;
    End;
    $0D52, $0D53, $0D54 : GlQv[0] := 8;
    $0D55, $0D57..$0D5B, $0D51 : GlQv[0] := 0;
    $0D50 : GlQv[0] := 4;
    $0D56 : GlQv[0] := 24;
    $0C32 : GlQv[0] := 1;
    $0C33 : GlQv[0] := 0;
    $84E2 : GlQv[0] := 2;
    $86A2 : GlQv[0] := 0;
    $8069 : GlQv[0] := Gc^.S.Bound[Gc^.S.ActTex];
    $84E0 : GlQv[0] := $84C0 + Gc^.S.ActTex;
    $84E1 : GlQv[0] := $84C0 + Gc^.CA.CliTex;
    $0CF5 : GlQv[0] := Gc^.CA.UnpA;
    $0D05 : GlQv[0] := Gc^.CA.PackA;
    $0B70 :
    Begin
      GlQv[0] := Gc^.S.DNear; GlQv[1] := Gc^.S.DFar; C := 2;
    End;
    $0C22 :
    Begin
      For K := 0 To 3 Do GlQv[K] := Gc^.S.ClrC[K];
      C := 4;
    End;
    $0B73 : GlQv[0] := Gc^.S.ClrZ;
    $0B00 :
    Begin
      For K := 0 To 3 Do GlQv[K] := Gc^.S.Col[K];
      C := 4;
    End;
    $0B02 :
    Begin
      For K := 0 To 2 Do GlQv[K] := Gc^.S.Nrm[K];
      C := 3;
    End;
    $0B03 :
    Begin
      For K := 0 To 3 Do GlQv[K] := Gc^.S.Tc0[K];
      C := 4;
    End;
    $0B74 : GlQv[0] := Gc^.S.DepFn;
    $0B72 : GlQv[0] := Gc^.S.DepMsk;
    $0BE1 : GlQv[0] := Gc^.S.BlSrc;
    $0BE0 : GlQv[0] := Gc^.S.BlDst;
    $0BC1 : GlQv[0] := Gc^.S.AlFn;
    $0BC2 : GlQv[0] := Gc^.S.AlRef;
    $0B45 : GlQv[0] := Gc^.S.CullMd;
    $0B46 : GlQv[0] := Gc^.S.Front;
    $0B54 : GlQv[0] := Gc^.S.Shade;
    $0B07 :
    Begin
      GlQv[0] := Gc^.RPos[0]; GlQv[1] := Gc^.RPos[1]; GlQv[3] := 1; C := 4;
    End;
    $0B08 : GlQv[0] := 1;
    $0B11, $0B21 : GlQv[0] := 1;
    $0B12, $0B22 :
    Begin
      GlQv[0] := 1; GlQv[1] := 64; C := 2;
    End;
  Else
    Begin
      C := 1;
      GlQv[0] := GlCapOn(N);
    End;
  End;
  GlQuery := C;
End;

Procedure glGetIntegerv(N, P : LongInt);
Var K, C : LongInt;
Begin
  GlTr(148);
  If Not GlOk Or (P = 0) Then Exit;
  C := GlQuery(N);
  For K := 0 To C - 1 Do WrL(P + K * 4, DRound(GlQv[K]));
End;

Procedure glGetFloatv(N, P : LongInt);
Var K, C : LongInt;
Begin
  GlTr(149);
  If Not GlOk Or (P = 0) Then Exit;
  C := GlQuery(N);
  For K := 0 To C - 1 Do WrL(P + K * 4, LFl(GlQv[K]));
End;

Procedure glGetDoublev(N, P : LongInt);
Var K, C : LongInt;
Begin
  GlTr(150);
  If Not GlOk Or (P = 0) Then Exit;
  C := GlQuery(N);
  For K := 0 To C - 1 Do DbPut(P + K * 8, GlQv[K]);
End;

Procedure glGetBooleanv(N, P : LongInt);
Var K, C : LongInt;
Begin
  GlTr(151);
  If Not GlOk Or (P = 0) Then Exit;
  C := GlQuery(N);
  For K := 0 To C - 1 Do WrB(P + K, Ord(GlQv[K] <> 0));
End;

{ ------------------------------------------------------------------ }
{ Listes d'affichage : non enregistrees (signalees)                  }
{ ------------------------------------------------------------------ }

Var
  GlListN : LongInt;

Function glGenLists(N : LongInt) : LongInt;
Begin
  GlTr(152);
  GlTodo('glGenLists');
  glGenLists := GlListN + 1;
  GlListN := GlListN + N;
End;

Procedure glNewList(L, M : LongInt);
Begin
  GlTr(153);
  GlTodo('glNewList');
End;

Procedure glEndList;
Begin
  GlTr(154);
End;

Procedure glCallList(L : LongInt);
Begin
  GlTr(155);
End;

Procedure glCallLists(N, T, P : LongInt);
Begin
  GlTr(156);
End;

Procedure glDeleteLists(L, N : LongInt);
Begin
  GlTr(157);
End;

Function glIsList(L : LongInt) : LongInt;
Begin
  GlTr(158);
  glIsList := Ord((L > 0) And (L <= GlListN));
End;

Procedure glListBase(B : LongInt);
Begin
  GlTr(159);
End;

{ ------------------------------------------------------------------ }
{ Variantes (fichier genere : types et nombres de composantes)       }
{ ------------------------------------------------------------------ }

Function GlB(V : LongInt) : LongInt;
Begin
  V := V And 255;
  If V > 127 Then V := V - 256;
  GlB := V;
End;

Function GlS(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V > 32767 Then V := V - 65536;
  GlS := V;
End;

Function GlUI(V : LongInt) : Double;
Begin
  If V < 0 Then GlUI := V + 4294967296.0 Else GlUI := V;
End;

Procedure glVertex2d(XL, XH, YL, YH : LongInt);
Begin
  GlTr(160);
  GlSetV(DblOf(XL, XH), DblOf(YL, YH), 0, 1);
End;

Procedure glVertex2dv(P : LongInt);
Begin
  GlTr(161);
  If P = 0 Then Exit;
  GlSetV(DbM(P), DbM(P + 8), 0, 1);
End;

Procedure glVertex2f(X, Y : LongInt);
Begin
  GlTr(162);
  GlSetV(FlL(X), FlL(Y), 0, 1);
End;

Procedure glVertex2fv(P : LongInt);
Begin
  GlTr(163);
  If P = 0 Then Exit;
  GlSetV(FlM(P), FlM(P + 4), 0, 1);
End;

Procedure glVertex2i(X, Y : LongInt);
Begin
  GlTr(164);
  GlSetV(X, Y, 0, 1);
End;

Procedure glVertex2iv(P : LongInt);
Begin
  GlTr(165);
  If P = 0 Then Exit;
  GlSetV(RdL(P), RdL(P + 4), 0, 1);
End;

Procedure glVertex2s(X, Y : LongInt);
Begin
  GlTr(166);
  GlSetV(GlS(X), GlS(Y), 0, 1);
End;

Procedure glVertex2sv(P : LongInt);
Begin
  GlTr(167);
  If P = 0 Then Exit;
  GlSetV(GlS(RdW(P)), GlS(RdW(P + 2)), 0, 1);
End;

Procedure glVertex3d(XL, XH, YL, YH, ZL, ZH : LongInt);
Begin
  GlTr(168);
  GlSetV(DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), 1);
End;

Procedure glVertex3dv(P : LongInt);
Begin
  GlTr(169);
  If P = 0 Then Exit;
  GlSetV(DbM(P), DbM(P + 8), DbM(P + 16), 1);
End;

Procedure glVertex3f(X, Y, Z : LongInt);
Begin
  GlTr(170);
  GlSetV(FlL(X), FlL(Y), FlL(Z), 1);
End;

Procedure glVertex3fv(P : LongInt);
Begin
  GlTr(171);
  If P = 0 Then Exit;
  GlSetV(FlM(P), FlM(P + 4), FlM(P + 8), 1);
End;

Procedure glVertex3i(X, Y, Z : LongInt);
Begin
  GlTr(172);
  GlSetV(X, Y, Z, 1);
End;

Procedure glVertex3iv(P : LongInt);
Begin
  GlTr(173);
  If P = 0 Then Exit;
  GlSetV(RdL(P), RdL(P + 4), RdL(P + 8), 1);
End;

Procedure glVertex3s(X, Y, Z : LongInt);
Begin
  GlTr(174);
  GlSetV(GlS(X), GlS(Y), GlS(Z), 1);
End;

Procedure glVertex3sv(P : LongInt);
Begin
  GlTr(175);
  If P = 0 Then Exit;
  GlSetV(GlS(RdW(P)), GlS(RdW(P + 2)), GlS(RdW(P + 4)), 1);
End;

Procedure glVertex4d(XL, XH, YL, YH, ZL, ZH, WL, WH : LongInt);
Begin
  GlTr(176);
  GlSetV(DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), DblOf(WL, WH));
End;

Procedure glVertex4dv(P : LongInt);
Begin
  GlTr(177);
  If P = 0 Then Exit;
  GlSetV(DbM(P), DbM(P + 8), DbM(P + 16), DbM(P + 24));
End;

Procedure glVertex4f(X, Y, Z, W : LongInt);
Begin
  GlTr(178);
  GlSetV(FlL(X), FlL(Y), FlL(Z), FlL(W));
End;

Procedure glVertex4fv(P : LongInt);
Begin
  GlTr(179);
  If P = 0 Then Exit;
  GlSetV(FlM(P), FlM(P + 4), FlM(P + 8), FlM(P + 12));
End;

Procedure glVertex4i(X, Y, Z, W : LongInt);
Begin
  GlTr(180);
  GlSetV(X, Y, Z, W);
End;

Procedure glVertex4iv(P : LongInt);
Begin
  GlTr(181);
  If P = 0 Then Exit;
  GlSetV(RdL(P), RdL(P + 4), RdL(P + 8), RdL(P + 12));
End;

Procedure glVertex4s(X, Y, Z, W : LongInt);
Begin
  GlTr(182);
  GlSetV(GlS(X), GlS(Y), GlS(Z), GlS(W));
End;

Procedure glVertex4sv(P : LongInt);
Begin
  GlTr(183);
  If P = 0 Then Exit;
  GlSetV(GlS(RdW(P)), GlS(RdW(P + 2)), GlS(RdW(P + 4)),
      GlS(RdW(P + 6)));
End;

Procedure glColor3b(X, Y, Z : LongInt);
Begin
  GlTr(184);
  GlSetC((GlB(X) / 127), (GlB(Y) / 127), (GlB(Z) / 127), 1);
End;

Procedure glColor3bv(P : LongInt);
Begin
  GlTr(185);
  If P = 0 Then Exit;
  GlSetC((GlB(RdB(P)) / 127), (GlB(RdB(P + 1)) / 127),
      (GlB(RdB(P + 2)) / 127), 1);
End;

Procedure glColor3d(XL, XH, YL, YH, ZL, ZH : LongInt);
Begin
  GlTr(186);
  GlSetC(DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), 1);
End;

Procedure glColor3dv(P : LongInt);
Begin
  GlTr(187);
  If P = 0 Then Exit;
  GlSetC(DbM(P), DbM(P + 8), DbM(P + 16), 1);
End;

Procedure glColor3f(X, Y, Z : LongInt);
Begin
  GlTr(188);
  GlSetC(FlL(X), FlL(Y), FlL(Z), 1);
End;

Procedure glColor3fv(P : LongInt);
Begin
  GlTr(189);
  If P = 0 Then Exit;
  GlSetC(FlM(P), FlM(P + 4), FlM(P + 8), 1);
End;

Procedure glColor3i(X, Y, Z : LongInt);
Begin
  GlTr(190);
  GlSetC((X / 2147483647.0), (Y / 2147483647.0), (Z / 2147483647.0), 1);
End;

Procedure glColor3iv(P : LongInt);
Begin
  GlTr(191);
  If P = 0 Then Exit;
  GlSetC((RdL(P) / 2147483647.0), (RdL(P + 4) / 2147483647.0),
      (RdL(P + 8) / 2147483647.0), 1);
End;

Procedure glColor3s(X, Y, Z : LongInt);
Begin
  GlTr(192);
  GlSetC((GlS(X) / 32767), (GlS(Y) / 32767), (GlS(Z) / 32767), 1);
End;

Procedure glColor3sv(P : LongInt);
Begin
  GlTr(193);
  If P = 0 Then Exit;
  GlSetC((GlS(RdW(P)) / 32767), (GlS(RdW(P + 2)) / 32767),
      (GlS(RdW(P + 4)) / 32767), 1);
End;

Procedure glColor3ub(X, Y, Z : LongInt);
Begin
  GlTr(194);
  GlSetC(((X And 255) / 255), ((Y And 255) / 255), ((Z And 255) / 255), 1);
End;

Procedure glColor3ubv(P : LongInt);
Begin
  GlTr(195);
  If P = 0 Then Exit;
  GlSetC(((RdB(P) And 255) / 255), ((RdB(P + 1) And 255) / 255),
      ((RdB(P + 2) And 255) / 255), 1);
End;

Procedure glColor3ui(X, Y, Z : LongInt);
Begin
  GlTr(196);
  GlSetC((GlUI(X) / 4294967295.0), (GlUI(Y) / 4294967295.0),
      (GlUI(Z) / 4294967295.0), 1);
End;

Procedure glColor3uiv(P : LongInt);
Begin
  GlTr(197);
  If P = 0 Then Exit;
  GlSetC((GlUI(RdL(P)) / 4294967295.0),
      (GlUI(RdL(P + 4)) / 4294967295.0),
      (GlUI(RdL(P + 8)) / 4294967295.0), 1);
End;

Procedure glColor3us(X, Y, Z : LongInt);
Begin
  GlTr(198);
  GlSetC(((X And $FFFF) / 65535), ((Y And $FFFF) / 65535),
      ((Z And $FFFF) / 65535), 1);
End;

Procedure glColor3usv(P : LongInt);
Begin
  GlTr(199);
  If P = 0 Then Exit;
  GlSetC(((RdW(P) And $FFFF) / 65535),
      ((RdW(P + 2) And $FFFF) / 65535),
      ((RdW(P + 4) And $FFFF) / 65535), 1);
End;

Procedure glColor4b(X, Y, Z, W : LongInt);
Begin
  GlTr(200);
  GlSetC((GlB(X) / 127), (GlB(Y) / 127), (GlB(Z) / 127), (GlB(W) / 127));
End;

Procedure glColor4bv(P : LongInt);
Begin
  GlTr(201);
  If P = 0 Then Exit;
  GlSetC((GlB(RdB(P)) / 127), (GlB(RdB(P + 1)) / 127),
      (GlB(RdB(P + 2)) / 127), (GlB(RdB(P + 3)) / 127));
End;

Procedure glColor4d(XL, XH, YL, YH, ZL, ZH, WL, WH : LongInt);
Begin
  GlTr(202);
  GlSetC(DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), DblOf(WL, WH));
End;

Procedure glColor4dv(P : LongInt);
Begin
  GlTr(203);
  If P = 0 Then Exit;
  GlSetC(DbM(P), DbM(P + 8), DbM(P + 16), DbM(P + 24));
End;

Procedure glColor4f(X, Y, Z, W : LongInt);
Begin
  GlTr(204);
  GlSetC(FlL(X), FlL(Y), FlL(Z), FlL(W));
End;

Procedure glColor4fv(P : LongInt);
Begin
  GlTr(205);
  If P = 0 Then Exit;
  GlSetC(FlM(P), FlM(P + 4), FlM(P + 8), FlM(P + 12));
End;

Procedure glColor4i(X, Y, Z, W : LongInt);
Begin
  GlTr(206);
  GlSetC((X / 2147483647.0), (Y / 2147483647.0), (Z / 2147483647.0),
      (W / 2147483647.0));
End;

Procedure glColor4iv(P : LongInt);
Begin
  GlTr(207);
  If P = 0 Then Exit;
  GlSetC((RdL(P) / 2147483647.0), (RdL(P + 4) / 2147483647.0),
      (RdL(P + 8) / 2147483647.0), (RdL(P + 12) / 2147483647.0));
End;

Procedure glColor4s(X, Y, Z, W : LongInt);
Begin
  GlTr(208);
  GlSetC((GlS(X) / 32767), (GlS(Y) / 32767), (GlS(Z) / 32767),
      (GlS(W) / 32767));
End;

Procedure glColor4sv(P : LongInt);
Begin
  GlTr(209);
  If P = 0 Then Exit;
  GlSetC((GlS(RdW(P)) / 32767), (GlS(RdW(P + 2)) / 32767),
      (GlS(RdW(P + 4)) / 32767), (GlS(RdW(P + 6)) / 32767));
End;

Procedure glColor4ub(X, Y, Z, W : LongInt);
Begin
  GlTr(210);
  GlSetC(((X And 255) / 255), ((Y And 255) / 255), ((Z And 255) / 255),
      ((W And 255) / 255));
End;

Procedure glColor4ubv(P : LongInt);
Begin
  GlTr(211);
  If P = 0 Then Exit;
  GlSetC(((RdB(P) And 255) / 255), ((RdB(P + 1) And 255) / 255),
      ((RdB(P + 2) And 255) / 255), ((RdB(P + 3) And 255) / 255));
End;

Procedure glColor4ui(X, Y, Z, W : LongInt);
Begin
  GlTr(212);
  GlSetC((GlUI(X) / 4294967295.0), (GlUI(Y) / 4294967295.0),
      (GlUI(Z) / 4294967295.0), (GlUI(W) / 4294967295.0));
End;

Procedure glColor4uiv(P : LongInt);
Begin
  GlTr(213);
  If P = 0 Then Exit;
  GlSetC((GlUI(RdL(P)) / 4294967295.0),
      (GlUI(RdL(P + 4)) / 4294967295.0),
      (GlUI(RdL(P + 8)) / 4294967295.0),
      (GlUI(RdL(P + 12)) / 4294967295.0));
End;

Procedure glColor4us(X, Y, Z, W : LongInt);
Begin
  GlTr(214);
  GlSetC(((X And $FFFF) / 65535), ((Y And $FFFF) / 65535),
      ((Z And $FFFF) / 65535), ((W And $FFFF) / 65535));
End;

Procedure glColor4usv(P : LongInt);
Begin
  GlTr(215);
  If P = 0 Then Exit;
  GlSetC(((RdW(P) And $FFFF) / 65535),
      ((RdW(P + 2) And $FFFF) / 65535),
      ((RdW(P + 4) And $FFFF) / 65535),
      ((RdW(P + 6) And $FFFF) / 65535));
End;

Procedure glNormal3b(X, Y, Z : LongInt);
Begin
  GlTr(216);
  GlSetN((GlB(X) / 127), (GlB(Y) / 127), (GlB(Z) / 127));
End;

Procedure glNormal3bv(P : LongInt);
Begin
  GlTr(217);
  If P = 0 Then Exit;
  GlSetN((GlB(RdB(P)) / 127), (GlB(RdB(P + 1)) / 127),
      (GlB(RdB(P + 2)) / 127));
End;

Procedure glNormal3d(XL, XH, YL, YH, ZL, ZH : LongInt);
Begin
  GlTr(218);
  GlSetN(DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH));
End;

Procedure glNormal3dv(P : LongInt);
Begin
  GlTr(219);
  If P = 0 Then Exit;
  GlSetN(DbM(P), DbM(P + 8), DbM(P + 16));
End;

Procedure glNormal3f(X, Y, Z : LongInt);
Begin
  GlTr(220);
  GlSetN(FlL(X), FlL(Y), FlL(Z));
End;

Procedure glNormal3fv(P : LongInt);
Begin
  GlTr(221);
  If P = 0 Then Exit;
  GlSetN(FlM(P), FlM(P + 4), FlM(P + 8));
End;

Procedure glNormal3i(X, Y, Z : LongInt);
Begin
  GlTr(222);
  GlSetN((X / 2147483647.0), (Y / 2147483647.0), (Z / 2147483647.0));
End;

Procedure glNormal3iv(P : LongInt);
Begin
  GlTr(223);
  If P = 0 Then Exit;
  GlSetN((RdL(P) / 2147483647.0), (RdL(P + 4) / 2147483647.0),
      (RdL(P + 8) / 2147483647.0));
End;

Procedure glNormal3s(X, Y, Z : LongInt);
Begin
  GlTr(224);
  GlSetN((GlS(X) / 32767), (GlS(Y) / 32767), (GlS(Z) / 32767));
End;

Procedure glNormal3sv(P : LongInt);
Begin
  GlTr(225);
  If P = 0 Then Exit;
  GlSetN((GlS(RdW(P)) / 32767), (GlS(RdW(P + 2)) / 32767),
      (GlS(RdW(P + 4)) / 32767));
End;

Procedure glTexCoord1d(XL, XH : LongInt);
Begin
  GlTr(226);
  GlSetT(0, DblOf(XL, XH), 0, 0, 1);
End;

Procedure glTexCoord1dv(P : LongInt);
Begin
  GlTr(227);
  If P = 0 Then Exit;
  GlSetT(0, DbM(P), 0, 0, 1);
End;

Procedure glTexCoord1f(X : LongInt);
Begin
  GlTr(228);
  GlSetT(0, FlL(X), 0, 0, 1);
End;

Procedure glTexCoord1fv(P : LongInt);
Begin
  GlTr(229);
  If P = 0 Then Exit;
  GlSetT(0, FlM(P), 0, 0, 1);
End;

Procedure glTexCoord1i(X : LongInt);
Begin
  GlTr(230);
  GlSetT(0, X, 0, 0, 1);
End;

Procedure glTexCoord1iv(P : LongInt);
Begin
  GlTr(231);
  If P = 0 Then Exit;
  GlSetT(0, RdL(P), 0, 0, 1);
End;

Procedure glTexCoord1s(X : LongInt);
Begin
  GlTr(232);
  GlSetT(0, GlS(X), 0, 0, 1);
End;

Procedure glTexCoord1sv(P : LongInt);
Begin
  GlTr(233);
  If P = 0 Then Exit;
  GlSetT(0, GlS(RdW(P)), 0, 0, 1);
End;

Procedure glTexCoord2d(XL, XH, YL, YH : LongInt);
Begin
  GlTr(234);
  GlSetT(0, DblOf(XL, XH), DblOf(YL, YH), 0, 1);
End;

Procedure glTexCoord2dv(P : LongInt);
Begin
  GlTr(235);
  If P = 0 Then Exit;
  GlSetT(0, DbM(P), DbM(P + 8), 0, 1);
End;

Procedure glTexCoord2f(X, Y : LongInt);
Begin
  GlTr(236);
  GlSetT(0, FlL(X), FlL(Y), 0, 1);
End;

Procedure glTexCoord2fv(P : LongInt);
Begin
  GlTr(237);
  If P = 0 Then Exit;
  GlSetT(0, FlM(P), FlM(P + 4), 0, 1);
End;

Procedure glTexCoord2i(X, Y : LongInt);
Begin
  GlTr(238);
  GlSetT(0, X, Y, 0, 1);
End;

Procedure glTexCoord2iv(P : LongInt);
Begin
  GlTr(239);
  If P = 0 Then Exit;
  GlSetT(0, RdL(P), RdL(P + 4), 0, 1);
End;

Procedure glTexCoord2s(X, Y : LongInt);
Begin
  GlTr(240);
  GlSetT(0, GlS(X), GlS(Y), 0, 1);
End;

Procedure glTexCoord2sv(P : LongInt);
Begin
  GlTr(241);
  If P = 0 Then Exit;
  GlSetT(0, GlS(RdW(P)), GlS(RdW(P + 2)), 0, 1);
End;

Procedure glTexCoord3d(XL, XH, YL, YH, ZL, ZH : LongInt);
Begin
  GlTr(242);
  GlSetT(0, DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), 1);
End;

Procedure glTexCoord3dv(P : LongInt);
Begin
  GlTr(243);
  If P = 0 Then Exit;
  GlSetT(0, DbM(P), DbM(P + 8), DbM(P + 16), 1);
End;

Procedure glTexCoord3f(X, Y, Z : LongInt);
Begin
  GlTr(244);
  GlSetT(0, FlL(X), FlL(Y), FlL(Z), 1);
End;

Procedure glTexCoord3fv(P : LongInt);
Begin
  GlTr(245);
  If P = 0 Then Exit;
  GlSetT(0, FlM(P), FlM(P + 4), FlM(P + 8), 1);
End;

Procedure glTexCoord3i(X, Y, Z : LongInt);
Begin
  GlTr(246);
  GlSetT(0, X, Y, Z, 1);
End;

Procedure glTexCoord3iv(P : LongInt);
Begin
  GlTr(247);
  If P = 0 Then Exit;
  GlSetT(0, RdL(P), RdL(P + 4), RdL(P + 8), 1);
End;

Procedure glTexCoord3s(X, Y, Z : LongInt);
Begin
  GlTr(248);
  GlSetT(0, GlS(X), GlS(Y), GlS(Z), 1);
End;

Procedure glTexCoord3sv(P : LongInt);
Begin
  GlTr(249);
  If P = 0 Then Exit;
  GlSetT(0, GlS(RdW(P)), GlS(RdW(P + 2)), GlS(RdW(P + 4)), 1);
End;

Procedure glTexCoord4d(XL, XH, YL, YH, ZL, ZH, WL, WH : LongInt);
Begin
  GlTr(250);
  GlSetT(0, DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), DblOf(WL, WH));
End;

Procedure glTexCoord4dv(P : LongInt);
Begin
  GlTr(251);
  If P = 0 Then Exit;
  GlSetT(0, DbM(P), DbM(P + 8), DbM(P + 16), DbM(P + 24));
End;

Procedure glTexCoord4f(X, Y, Z, W : LongInt);
Begin
  GlTr(252);
  GlSetT(0, FlL(X), FlL(Y), FlL(Z), FlL(W));
End;

Procedure glTexCoord4fv(P : LongInt);
Begin
  GlTr(253);
  If P = 0 Then Exit;
  GlSetT(0, FlM(P), FlM(P + 4), FlM(P + 8), FlM(P + 12));
End;

Procedure glTexCoord4i(X, Y, Z, W : LongInt);
Begin
  GlTr(254);
  GlSetT(0, X, Y, Z, W);
End;

Procedure glTexCoord4iv(P : LongInt);
Begin
  GlTr(255);
  If P = 0 Then Exit;
  GlSetT(0, RdL(P), RdL(P + 4), RdL(P + 8), RdL(P + 12));
End;

Procedure glTexCoord4s(X, Y, Z, W : LongInt);
Begin
  GlTr(256);
  GlSetT(0, GlS(X), GlS(Y), GlS(Z), GlS(W));
End;

Procedure glTexCoord4sv(P : LongInt);
Begin
  GlTr(257);
  If P = 0 Then Exit;
  GlSetT(0, GlS(RdW(P)), GlS(RdW(P + 2)), GlS(RdW(P + 4)),
      GlS(RdW(P + 6)));
End;

Procedure glRasterPos2d(XL, XH, YL, YH : LongInt);
Begin
  GlTr(258);
  GlSetR(DblOf(XL, XH), DblOf(YL, YH), 0, 1);
End;

Procedure glRasterPos2dv(P : LongInt);
Begin
  GlTr(259);
  If P = 0 Then Exit;
  GlSetR(DbM(P), DbM(P + 8), 0, 1);
End;

Procedure glRasterPos2f(X, Y : LongInt);
Begin
  GlTr(260);
  GlSetR(FlL(X), FlL(Y), 0, 1);
End;

Procedure glRasterPos2fv(P : LongInt);
Begin
  GlTr(261);
  If P = 0 Then Exit;
  GlSetR(FlM(P), FlM(P + 4), 0, 1);
End;

Procedure glRasterPos2i(X, Y : LongInt);
Begin
  GlTr(262);
  GlSetR(X, Y, 0, 1);
End;

Procedure glRasterPos2iv(P : LongInt);
Begin
  GlTr(263);
  If P = 0 Then Exit;
  GlSetR(RdL(P), RdL(P + 4), 0, 1);
End;

Procedure glRasterPos2s(X, Y : LongInt);
Begin
  GlTr(264);
  GlSetR(GlS(X), GlS(Y), 0, 1);
End;

Procedure glRasterPos2sv(P : LongInt);
Begin
  GlTr(265);
  If P = 0 Then Exit;
  GlSetR(GlS(RdW(P)), GlS(RdW(P + 2)), 0, 1);
End;

Procedure glRasterPos3d(XL, XH, YL, YH, ZL, ZH : LongInt);
Begin
  GlTr(266);
  GlSetR(DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), 1);
End;

Procedure glRasterPos3dv(P : LongInt);
Begin
  GlTr(267);
  If P = 0 Then Exit;
  GlSetR(DbM(P), DbM(P + 8), DbM(P + 16), 1);
End;

Procedure glRasterPos3f(X, Y, Z : LongInt);
Begin
  GlTr(268);
  GlSetR(FlL(X), FlL(Y), FlL(Z), 1);
End;

Procedure glRasterPos3fv(P : LongInt);
Begin
  GlTr(269);
  If P = 0 Then Exit;
  GlSetR(FlM(P), FlM(P + 4), FlM(P + 8), 1);
End;

Procedure glRasterPos3i(X, Y, Z : LongInt);
Begin
  GlTr(270);
  GlSetR(X, Y, Z, 1);
End;

Procedure glRasterPos3iv(P : LongInt);
Begin
  GlTr(271);
  If P = 0 Then Exit;
  GlSetR(RdL(P), RdL(P + 4), RdL(P + 8), 1);
End;

Procedure glRasterPos3s(X, Y, Z : LongInt);
Begin
  GlTr(272);
  GlSetR(GlS(X), GlS(Y), GlS(Z), 1);
End;

Procedure glRasterPos3sv(P : LongInt);
Begin
  GlTr(273);
  If P = 0 Then Exit;
  GlSetR(GlS(RdW(P)), GlS(RdW(P + 2)), GlS(RdW(P + 4)), 1);
End;

Procedure glRasterPos4d(XL, XH, YL, YH, ZL, ZH, WL, WH : LongInt);
Begin
  GlTr(274);
  GlSetR(DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), DblOf(WL, WH));
End;

Procedure glRasterPos4dv(P : LongInt);
Begin
  GlTr(275);
  If P = 0 Then Exit;
  GlSetR(DbM(P), DbM(P + 8), DbM(P + 16), DbM(P + 24));
End;

Procedure glRasterPos4f(X, Y, Z, W : LongInt);
Begin
  GlTr(276);
  GlSetR(FlL(X), FlL(Y), FlL(Z), FlL(W));
End;

Procedure glRasterPos4fv(P : LongInt);
Begin
  GlTr(277);
  If P = 0 Then Exit;
  GlSetR(FlM(P), FlM(P + 4), FlM(P + 8), FlM(P + 12));
End;

Procedure glRasterPos4i(X, Y, Z, W : LongInt);
Begin
  GlTr(278);
  GlSetR(X, Y, Z, W);
End;

Procedure glRasterPos4iv(P : LongInt);
Begin
  GlTr(279);
  If P = 0 Then Exit;
  GlSetR(RdL(P), RdL(P + 4), RdL(P + 8), RdL(P + 12));
End;

Procedure glRasterPos4s(X, Y, Z, W : LongInt);
Begin
  GlTr(280);
  GlSetR(GlS(X), GlS(Y), GlS(Z), GlS(W));
End;

Procedure glRasterPos4sv(P : LongInt);
Begin
  GlTr(281);
  If P = 0 Then Exit;
  GlSetR(GlS(RdW(P)), GlS(RdW(P + 2)), GlS(RdW(P + 4)),
      GlS(RdW(P + 6)));
End;

Procedure glMultiTexCoord1dARB(U, XL, XH : LongInt);
Begin
  GlTr(282);
  GlSetT(U - $84C0, DblOf(XL, XH), 0, 0, 1);
End;

Procedure glMultiTexCoord1dvARB(U, P : LongInt);
Begin
  GlTr(283);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, DbM(P), 0, 0, 1);
End;

Procedure glMultiTexCoord1fARB(U, X : LongInt);
Begin
  GlTr(284);
  GlSetT(U - $84C0, FlL(X), 0, 0, 1);
End;

Procedure glMultiTexCoord1fvARB(U, P : LongInt);
Begin
  GlTr(285);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, FlM(P), 0, 0, 1);
End;

Procedure glMultiTexCoord1iARB(U, X : LongInt);
Begin
  GlTr(286);
  GlSetT(U - $84C0, X, 0, 0, 1);
End;

Procedure glMultiTexCoord1ivARB(U, P : LongInt);
Begin
  GlTr(287);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, RdL(P), 0, 0, 1);
End;

Procedure glMultiTexCoord1sARB(U, X : LongInt);
Begin
  GlTr(288);
  GlSetT(U - $84C0, GlS(X), 0, 0, 1);
End;

Procedure glMultiTexCoord1svARB(U, P : LongInt);
Begin
  GlTr(289);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, GlS(RdW(P)), 0, 0, 1);
End;

Procedure glMultiTexCoord2dARB(U, XL, XH, YL, YH : LongInt);
Begin
  GlTr(290);
  GlSetT(U - $84C0, DblOf(XL, XH), DblOf(YL, YH), 0, 1);
End;

Procedure glMultiTexCoord2dvARB(U, P : LongInt);
Begin
  GlTr(291);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, DbM(P), DbM(P + 8), 0, 1);
End;

Procedure glMultiTexCoord2fARB(U, X, Y : LongInt);
Begin
  GlTr(292);
  GlSetT(U - $84C0, FlL(X), FlL(Y), 0, 1);
End;

Procedure glMultiTexCoord2fvARB(U, P : LongInt);
Begin
  GlTr(293);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, FlM(P), FlM(P + 4), 0, 1);
End;

Procedure glMultiTexCoord2iARB(U, X, Y : LongInt);
Begin
  GlTr(294);
  GlSetT(U - $84C0, X, Y, 0, 1);
End;

Procedure glMultiTexCoord2ivARB(U, P : LongInt);
Begin
  GlTr(295);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, RdL(P), RdL(P + 4), 0, 1);
End;

Procedure glMultiTexCoord2sARB(U, X, Y : LongInt);
Begin
  GlTr(296);
  GlSetT(U - $84C0, GlS(X), GlS(Y), 0, 1);
End;

Procedure glMultiTexCoord2svARB(U, P : LongInt);
Begin
  GlTr(297);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, GlS(RdW(P)), GlS(RdW(P + 2)), 0, 1);
End;

Procedure glMultiTexCoord3dARB(U, XL, XH, YL, YH, ZL, ZH : LongInt);
Begin
  GlTr(298);
  GlSetT(U - $84C0, DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), 1);
End;

Procedure glMultiTexCoord3dvARB(U, P : LongInt);
Begin
  GlTr(299);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, DbM(P), DbM(P + 8), DbM(P + 16), 1);
End;

Procedure glMultiTexCoord3fARB(U, X, Y, Z : LongInt);
Begin
  GlTr(300);
  GlSetT(U - $84C0, FlL(X), FlL(Y), FlL(Z), 1);
End;

Procedure glMultiTexCoord3fvARB(U, P : LongInt);
Begin
  GlTr(301);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, FlM(P), FlM(P + 4), FlM(P + 8), 1);
End;

Procedure glMultiTexCoord3iARB(U, X, Y, Z : LongInt);
Begin
  GlTr(302);
  GlSetT(U - $84C0, X, Y, Z, 1);
End;

Procedure glMultiTexCoord3ivARB(U, P : LongInt);
Begin
  GlTr(303);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, RdL(P), RdL(P + 4), RdL(P + 8), 1);
End;

Procedure glMultiTexCoord3sARB(U, X, Y, Z : LongInt);
Begin
  GlTr(304);
  GlSetT(U - $84C0, GlS(X), GlS(Y), GlS(Z), 1);
End;

Procedure glMultiTexCoord3svARB(U, P : LongInt);
Begin
  GlTr(305);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, GlS(RdW(P)), GlS(RdW(P + 2)), GlS(RdW(P + 4)),
      1);
End;

Procedure glMultiTexCoord4dARB(U, XL, XH, YL, YH, ZL, ZH, WL, WH : LongInt);
Begin
  GlTr(306);
  GlSetT(U - $84C0, DblOf(XL, XH), DblOf(YL, YH), DblOf(ZL, ZH), DblOf(WL,
      WH));
End;

Procedure glMultiTexCoord4dvARB(U, P : LongInt);
Begin
  GlTr(307);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, DbM(P), DbM(P + 8), DbM(P + 16), DbM(P + 24));
End;

Procedure glMultiTexCoord4fARB(U, X, Y, Z, W : LongInt);
Begin
  GlTr(308);
  GlSetT(U - $84C0, FlL(X), FlL(Y), FlL(Z), FlL(W));
End;

Procedure glMultiTexCoord4fvARB(U, P : LongInt);
Begin
  GlTr(309);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, FlM(P), FlM(P + 4), FlM(P + 8), FlM(P + 12));
End;

Procedure glMultiTexCoord4iARB(U, X, Y, Z, W : LongInt);
Begin
  GlTr(310);
  GlSetT(U - $84C0, X, Y, Z, W);
End;

Procedure glMultiTexCoord4ivARB(U, P : LongInt);
Begin
  GlTr(311);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, RdL(P), RdL(P + 4), RdL(P + 8), RdL(P + 12));
End;

Procedure glMultiTexCoord4sARB(U, X, Y, Z, W : LongInt);
Begin
  GlTr(312);
  GlSetT(U - $84C0, GlS(X), GlS(Y), GlS(Z), GlS(W));
End;

Procedure glMultiTexCoord4svARB(U, P : LongInt);
Begin
  GlTr(313);
  If P = 0 Then Exit;
  GlSetT(U - $84C0, GlS(RdW(P)), GlS(RdW(P + 2)), GlS(RdW(P + 4)),
      GlS(RdW(P + 6)));
End;

Procedure glIndexd(XL, XH : LongInt);
Begin
  GlTr(314);
  GlSetI(DblOf(XL, XH));
End;

Procedure glIndexdv(P : LongInt);
Begin
  GlTr(315);
  If P = 0 Then Exit;
  GlSetI(DbM(P));
End;

Procedure glIndexf(X : LongInt);
Begin
  GlTr(316);
  GlSetI(FlL(X));
End;

Procedure glIndexfv(P : LongInt);
Begin
  GlTr(317);
  If P = 0 Then Exit;
  GlSetI(FlM(P));
End;

Procedure glIndexi(X : LongInt);
Begin
  GlTr(318);
  GlSetI(X);
End;

Procedure glIndexiv(P : LongInt);
Begin
  GlTr(319);
  If P = 0 Then Exit;
  GlSetI(RdL(P));
End;

Procedure glIndexs(X : LongInt);
Begin
  GlTr(320);
  GlSetI(GlS(X));
End;

Procedure glIndexsv(P : LongInt);
Begin
  GlTr(321);
  If P = 0 Then Exit;
  GlSetI(GlS(RdW(P)));
End;

Procedure glIndexub(X : LongInt);
Begin
  GlTr(322);
  GlSetI((X And 255));
End;

Procedure glIndexubv(P : LongInt);
Begin
  GlTr(323);
  If P = 0 Then Exit;
  GlSetI((RdB(P) And 255));
End;

Procedure glRectd(AL, AH, BL, BH, CL, CH, DL, DH : LongInt);
Begin
  GlTr(324);
  GlRectQ(DblOf(AL, AH), DblOf(BL, BH), DblOf(CL, CH), DblOf(DL, DH));
End;

Procedure glRectdv(P1, P2 : LongInt);
Begin
  GlTr(325);
  If (P1 = 0) Or (P2 = 0) Then Exit;
  GlRectQ(DbM(P1), DbM(P1 + 8), DbM(P2), DbM(P2 + 8));
End;

Procedure glRectf(A, B, C, D : LongInt);
Begin
  GlTr(326);
  GlRectQ(FlL(A), FlL(B), FlL(C), FlL(D));
End;

Procedure glRectfv(P1, P2 : LongInt);
Begin
  GlTr(327);
  If (P1 = 0) Or (P2 = 0) Then Exit;
  GlRectQ(FlM(P1), FlM(P1 + 4), FlM(P2), FlM(P2 + 4));
End;

Procedure glRecti(A, B, C, D : LongInt);
Begin
  GlTr(328);
  GlRectQ(A, B, C, D);
End;

Procedure glRectiv(P1, P2 : LongInt);
Begin
  GlTr(329);
  If (P1 = 0) Or (P2 = 0) Then Exit;
  GlRectQ(RdL(P1), RdL(P1 + 4), RdL(P2), RdL(P2 + 4));
End;

Procedure glRects(A, B, C, D : LongInt);
Begin
  GlTr(330);
  GlRectQ(GlS(A), GlS(B), GlS(C), GlS(D));
End;

Procedure glRectsv(P1, P2 : LongInt);
Begin
  GlTr(331);
  If (P1 = 0) Or (P2 = 0) Then Exit;
  GlRectQ(GlS(RdW(P1)), GlS(RdW(P1 + 2)), GlS(RdW(P2)),
      GlS(RdW(P2 + 2)));
End;

Procedure glAccum(A0, A1 : LongInt);
Begin
  GlTr(332);
  GlTodo('glAccum');
End;

Procedure glBitmap(A0, A1, A2, A3, A4, A5, A6 : LongInt);
Begin
  GlTr(333);
  GlTodo('glBitmap');
End;

Procedure glClearAccum(A0, A1, A2, A3 : LongInt);
Begin
  GlTr(334);
End;

Procedure glClearIndex(A0 : LongInt);
Begin
  GlTr(335);
End;

Procedure glClearStencil(A0 : LongInt);
Begin
  GlTr(336);
End;

Procedure glClipPlane(A0, A1 : LongInt);
Begin
  GlTr(337);
  GlTodo('glClipPlane');
End;

Procedure glGetClipPlane(A0, A1 : LongInt);
Begin
  GlTr(338);
End;

Procedure glCopyPixels(A0, A1, A2, A3, A4 : LongInt);
Begin
  GlTr(339);
  GlTodo('glCopyPixels');
End;

Procedure glEdgeFlag(A0 : LongInt);
Begin
  GlTr(340);
End;

Procedure glEdgeFlagv(A0 : LongInt);
Begin
  GlTr(341);
End;

Procedure glEvalCoord1d(A0, A1 : LongInt);
Begin
  GlTr(342);
End;

Procedure glEvalCoord1dv(A0 : LongInt);
Begin
  GlTr(343);
End;

Procedure glEvalCoord1f(A0 : LongInt);
Begin
  GlTr(344);
End;

Procedure glEvalCoord1fv(A0 : LongInt);
Begin
  GlTr(345);
End;

Procedure glEvalCoord2d(A0, A1, A2, A3 : LongInt);
Begin
  GlTr(346);
End;

Procedure glEvalCoord2dv(A0 : LongInt);
Begin
  GlTr(347);
End;

Procedure glEvalCoord2f(A0, A1 : LongInt);
Begin
  GlTr(348);
End;

Procedure glEvalCoord2fv(A0 : LongInt);
Begin
  GlTr(349);
End;

Procedure glEvalMesh1(A0, A1, A2 : LongInt);
Begin
  GlTr(350);
End;

Procedure glEvalMesh2(A0, A1, A2, A3, A4 : LongInt);
Begin
  GlTr(351);
End;

Procedure glEvalPoint1(A0 : LongInt);
Begin
  GlTr(352);
End;

Procedure glEvalPoint2(A0, A1 : LongInt);
Begin
  GlTr(353);
End;

Procedure glFeedbackBuffer(A0, A1, A2 : LongInt);
Begin
  GlTr(354);
  GlTodo('glFeedbackBuffer');
End;

Procedure glGetMapdv(A0, A1, A2 : LongInt);
Begin
  GlTr(355);
End;

Procedure glGetMapfv(A0, A1, A2 : LongInt);
Begin
  GlTr(356);
End;

Procedure glGetMapiv(A0, A1, A2 : LongInt);
Begin
  GlTr(357);
End;

Procedure glGetPixelMapfv(A0, A1 : LongInt);
Begin
  GlTr(358);
End;

Procedure glGetPixelMapuiv(A0, A1 : LongInt);
Begin
  GlTr(359);
End;

Procedure glGetPixelMapusv(A0, A1 : LongInt);
Begin
  GlTr(360);
End;

Procedure glGetPolygonStipple(A0 : LongInt);
Begin
  GlTr(361);
End;

Procedure glIndexMask(A0 : LongInt);
Begin
  GlTr(362);
End;

Procedure glInitNames;
Begin
  GlTr(363);
End;

Procedure glLoadName(A0 : LongInt);
Begin
  GlTr(364);
End;

Procedure glPushName(A0 : LongInt);
Begin
  GlTr(365);
End;

Procedure glPopName;
Begin
  GlTr(366);
End;

Procedure glPassThrough(A0 : LongInt);
Begin
  GlTr(367);
End;

Procedure glSelectBuffer(A0, A1 : LongInt);
Begin
  GlTr(368);
  GlTodo('glSelectBuffer');
End;

Procedure glLineStipple(A0, A1 : LongInt);
Begin
  GlTr(369);
End;

Procedure glLogicOp(A0 : LongInt);
Begin
  GlTr(370);
  GlTodo('glLogicOp');
End;

Procedure glMap1d(A0, A1, A2, A3, A4, A5, A6, A7 : LongInt);
Begin
  GlTr(371);
End;

Procedure glMap1f(A0, A1, A2, A3, A4, A5 : LongInt);
Begin
  GlTr(372);
End;

Procedure glMap2d(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12,
  A13 : LongInt);
Begin
  GlTr(373);
End;

Procedure glMap2f(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9 : LongInt);
Begin
  GlTr(374);
End;

Procedure glMapGrid1d(A0, A1, A2, A3, A4 : LongInt);
Begin
  GlTr(375);
End;

Procedure glMapGrid1f(A0, A1, A2 : LongInt);
Begin
  GlTr(376);
End;

Procedure glMapGrid2d(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9 : LongInt);
Begin
  GlTr(377);
End;

Procedure glMapGrid2f(A0, A1, A2, A3, A4, A5 : LongInt);
Begin
  GlTr(378);
End;

Procedure glPixelMapfv(A0, A1, A2 : LongInt);
Begin
  GlTr(379);
End;

Procedure glPixelMapuiv(A0, A1, A2 : LongInt);
Begin
  GlTr(380);
End;

Procedure glPixelMapusv(A0, A1, A2 : LongInt);
Begin
  GlTr(381);
End;

Procedure glPixelTransferf(A0, A1 : LongInt);
Begin
  GlTr(382);
End;

Procedure glPixelTransferi(A0, A1 : LongInt);
Begin
  GlTr(383);
End;

Procedure glPixelZoom(A0, A1 : LongInt);
Begin
  GlTr(384);
End;

Procedure glPolygonStipple(A0 : LongInt);
Begin
  GlTr(385);
End;

Procedure glStencilFunc(A0, A1, A2 : LongInt);
Begin
  GlTr(386);
  GlTodo('glStencilFunc');
End;

Procedure glStencilMask(A0 : LongInt);
Begin
  GlTr(387);
End;

Procedure glStencilOp(A0, A1, A2 : LongInt);
Begin
  GlTr(388);
End;

Function glRenderMode(M : LongInt) : LongInt;
Begin
  GlTr(389);
  glRenderMode := 0;
End;



Exports
  pglChooseConfig Name 'pglChooseConfig',
  pglQueryConfigs Name 'pglQueryConfigs',
  pglCreateContext Name 'pglCreateContext',
  pglMakeCurrent Name 'pglMakeCurrent',
  pglDestroyContext Name 'pglDestroyContext',
  pglGetCurrentContext Name 'pglGetCurrentContext',
  pglGetCurrentWindow Name 'pglGetCurrentWindow',
  pglSwapBuffers Name 'pglSwapBuffers',
  pglQueryCapability Name 'pglQueryCapability',
  pglQueryVersion Name 'pglQueryVersion',
  pglWaitGL Name 'pglWaitGL',
  pglWaitPM Name 'pglWaitPM',
  pglCopyContext Name 'pglCopyContext',
  pglIsIndirect Name 'pglIsIndirect',
  pglSelectColorIndexPalette Name 'pglSelectColorIndexPalette',
  pglGrabFrontBitmap Name 'pglGrabFrontBitmap',
  pglReleaseFrontBitmap Name 'pglReleaseFrontBitmap',
  pglUseFont Name 'pglUseFont',
  glEnable Name 'glEnable',
  glDisable Name 'glDisable',
  glIsEnabled Name 'glIsEnabled',
  glEnableClientState Name 'glEnableClientState',
  glDisableClientState Name 'glDisableClientState',
  glVertexPointer Name 'glVertexPointer',
  glNormalPointer Name 'glNormalPointer',
  glColorPointer Name 'glColorPointer',
  glTexCoordPointer Name 'glTexCoordPointer',
  glEdgeFlagPointer Name 'glEdgeFlagPointer',
  glIndexPointer Name 'glIndexPointer',
  glGetPointerv Name 'glGetPointerv',
  glInterleavedArrays Name 'glInterleavedArrays',
  glArrayElement Name 'glArrayElement',
  glDrawArrays Name 'glDrawArrays',
  glDrawElements Name 'glDrawElements',
  glDrawRangeElements Name 'glDrawRangeElements',
  glBegin Name 'glBegin',
  glEnd Name 'glEnd',
  glClear Name 'glClear',
  glClearColor Name 'glClearColor',
  glClearDepth Name 'glClearDepth',
  glViewport Name 'glViewport',
  glScissor Name 'glScissor',
  glDepthRange Name 'glDepthRange',
  glDepthFunc Name 'glDepthFunc',
  glDepthMask Name 'glDepthMask',
  glBlendFunc Name 'glBlendFunc',
  glAlphaFunc Name 'glAlphaFunc',
  glCullFace Name 'glCullFace',
  glFrontFace Name 'glFrontFace',
  glShadeModel Name 'glShadeModel',
  glPolygonMode Name 'glPolygonMode',
  glPolygonOffset Name 'glPolygonOffset',
  glColorMask Name 'glColorMask',
  glLineWidth Name 'glLineWidth',
  glPointSize Name 'glPointSize',
  glHint Name 'glHint',
  glFlush Name 'glFlush',
  glFinish Name 'glFinish',
  glGetError Name 'glGetError',
  glGetString Name 'glGetString',
  glDrawBuffer Name 'glDrawBuffer',
  glReadBuffer Name 'glReadBuffer',
  glFogfv Name 'glFogfv',
  glFogiv Name 'glFogiv',
  glFogf Name 'glFogf',
  glFogi Name 'glFogi',
  glLightfv Name 'glLightfv',
  glLightiv Name 'glLightiv',
  glLightf Name 'glLightf',
  glLighti Name 'glLighti',
  glGetLightfv Name 'glGetLightfv',
  glGetLightiv Name 'glGetLightiv',
  glLightModelfv Name 'glLightModelfv',
  glLightModeliv Name 'glLightModeliv',
  glLightModelf Name 'glLightModelf',
  glLightModeli Name 'glLightModeli',
  glMaterialfv Name 'glMaterialfv',
  glMaterialiv Name 'glMaterialiv',
  glMaterialf Name 'glMaterialf',
  glMateriali Name 'glMateriali',
  glGetMaterialfv Name 'glGetMaterialfv',
  glGetMaterialiv Name 'glGetMaterialiv',
  glColorMaterial Name 'glColorMaterial',
  glMatrixMode Name 'glMatrixMode',
  glLoadIdentity Name 'glLoadIdentity',
  glLoadMatrixf Name 'glLoadMatrixf',
  glLoadMatrixd Name 'glLoadMatrixd',
  glMultMatrixf Name 'glMultMatrixf',
  glMultMatrixd Name 'glMultMatrixd',
  glPushMatrix Name 'glPushMatrix',
  glPopMatrix Name 'glPopMatrix',
  glTranslatef Name 'glTranslatef',
  glTranslated Name 'glTranslated',
  glScalef Name 'glScalef',
  glScaled Name 'glScaled',
  glRotatef Name 'glRotatef',
  glRotated Name 'glRotated',
  glOrtho Name 'glOrtho',
  glFrustum Name 'glFrustum',
  glTexGeni Name 'glTexGeni',
  glTexGenf Name 'glTexGenf',
  glTexGend Name 'glTexGend',
  glTexGeniv Name 'glTexGeniv',
  glTexGenfv Name 'glTexGenfv',
  glTexGendv Name 'glTexGendv',
  glGetTexGeniv Name 'glGetTexGeniv',
  glGetTexGenfv Name 'glGetTexGenfv',
  glGetTexGendv Name 'glGetTexGendv',
  glGenTextures Name 'glGenTextures',
  glDeleteTextures Name 'glDeleteTextures',
  glIsTexture Name 'glIsTexture',
  glAreTexturesResident Name 'glAreTexturesResident',
  glPrioritizeTextures Name 'glPrioritizeTextures',
  glBindTexture Name 'glBindTexture',
  glTexImage2D Name 'glTexImage2D',
  glTexImage1D Name 'glTexImage1D',
  glTexSubImage2D Name 'glTexSubImage2D',
  glTexSubImage1D Name 'glTexSubImage1D',
  glCopyTexImage2D Name 'glCopyTexImage2D',
  glCopyTexImage1D Name 'glCopyTexImage1D',
  glCopyTexSubImage2D Name 'glCopyTexSubImage2D',
  glCopyTexSubImage1D Name 'glCopyTexSubImage1D',
  glGetTexImage Name 'glGetTexImage',
  glTexParameteri Name 'glTexParameteri',
  glTexParameterf Name 'glTexParameterf',
  glTexParameteriv Name 'glTexParameteriv',
  glTexParameterfv Name 'glTexParameterfv',
  glGetTexParameteriv Name 'glGetTexParameteriv',
  glGetTexParameterfv Name 'glGetTexParameterfv',
  glGetTexLevelParameteriv Name 'glGetTexLevelParameteriv',
  glGetTexLevelParameterfv Name 'glGetTexLevelParameterfv',
  glTexEnvi Name 'glTexEnvi',
  glTexEnvf Name 'glTexEnvf',
  glTexEnviv Name 'glTexEnviv',
  glTexEnvfv Name 'glTexEnvfv',
  glGetTexEnviv Name 'glGetTexEnviv',
  glGetTexEnvfv Name 'glGetTexEnvfv',
  glPixelStorei Name 'glPixelStorei',
  glPixelStoref Name 'glPixelStoref',
  glActiveTextureARB Name 'glActiveTextureARB',
  glClientActiveTextureARB Name 'glClientActiveTextureARB',
  glReadPixels Name 'glReadPixels',
  glDrawPixels Name 'glDrawPixels',
  glPushAttrib Name 'glPushAttrib',
  glPopAttrib Name 'glPopAttrib',
  glPushClientAttrib Name 'glPushClientAttrib',
  glPopClientAttrib Name 'glPopClientAttrib',
  glGetIntegerv Name 'glGetIntegerv',
  glGetFloatv Name 'glGetFloatv',
  glGetDoublev Name 'glGetDoublev',
  glGetBooleanv Name 'glGetBooleanv',
  glGenLists Name 'glGenLists',
  glNewList Name 'glNewList',
  glEndList Name 'glEndList',
  glCallList Name 'glCallList',
  glCallLists Name 'glCallLists',
  glDeleteLists Name 'glDeleteLists',
  glIsList Name 'glIsList',
  glListBase Name 'glListBase',
  glVertex2d Name 'glVertex2d',
  glVertex2dv Name 'glVertex2dv',
  glVertex2f Name 'glVertex2f',
  glVertex2fv Name 'glVertex2fv',
  glVertex2i Name 'glVertex2i',
  glVertex2iv Name 'glVertex2iv',
  glVertex2s Name 'glVertex2s',
  glVertex2sv Name 'glVertex2sv',
  glVertex3d Name 'glVertex3d',
  glVertex3dv Name 'glVertex3dv',
  glVertex3f Name 'glVertex3f',
  glVertex3fv Name 'glVertex3fv',
  glVertex3i Name 'glVertex3i',
  glVertex3iv Name 'glVertex3iv',
  glVertex3s Name 'glVertex3s',
  glVertex3sv Name 'glVertex3sv',
  glVertex4d Name 'glVertex4d',
  glVertex4dv Name 'glVertex4dv',
  glVertex4f Name 'glVertex4f',
  glVertex4fv Name 'glVertex4fv',
  glVertex4i Name 'glVertex4i',
  glVertex4iv Name 'glVertex4iv',
  glVertex4s Name 'glVertex4s',
  glVertex4sv Name 'glVertex4sv',
  glColor3b Name 'glColor3b',
  glColor3bv Name 'glColor3bv',
  glColor3d Name 'glColor3d',
  glColor3dv Name 'glColor3dv',
  glColor3f Name 'glColor3f',
  glColor3fv Name 'glColor3fv',
  glColor3i Name 'glColor3i',
  glColor3iv Name 'glColor3iv',
  glColor3s Name 'glColor3s',
  glColor3sv Name 'glColor3sv',
  glColor3ub Name 'glColor3ub',
  glColor3ubv Name 'glColor3ubv',
  glColor3ui Name 'glColor3ui',
  glColor3uiv Name 'glColor3uiv',
  glColor3us Name 'glColor3us',
  glColor3usv Name 'glColor3usv',
  glColor4b Name 'glColor4b',
  glColor4bv Name 'glColor4bv',
  glColor4d Name 'glColor4d',
  glColor4dv Name 'glColor4dv',
  glColor4f Name 'glColor4f',
  glColor4fv Name 'glColor4fv',
  glColor4i Name 'glColor4i',
  glColor4iv Name 'glColor4iv',
  glColor4s Name 'glColor4s',
  glColor4sv Name 'glColor4sv',
  glColor4ub Name 'glColor4ub',
  glColor4ubv Name 'glColor4ubv',
  glColor4ui Name 'glColor4ui',
  glColor4uiv Name 'glColor4uiv',
  glColor4us Name 'glColor4us',
  glColor4usv Name 'glColor4usv',
  glNormal3b Name 'glNormal3b',
  glNormal3bv Name 'glNormal3bv',
  glNormal3d Name 'glNormal3d',
  glNormal3dv Name 'glNormal3dv',
  glNormal3f Name 'glNormal3f',
  glNormal3fv Name 'glNormal3fv',
  glNormal3i Name 'glNormal3i',
  glNormal3iv Name 'glNormal3iv',
  glNormal3s Name 'glNormal3s',
  glNormal3sv Name 'glNormal3sv',
  glTexCoord1d Name 'glTexCoord1d',
  glTexCoord1dv Name 'glTexCoord1dv',
  glTexCoord1f Name 'glTexCoord1f',
  glTexCoord1fv Name 'glTexCoord1fv',
  glTexCoord1i Name 'glTexCoord1i',
  glTexCoord1iv Name 'glTexCoord1iv',
  glTexCoord1s Name 'glTexCoord1s',
  glTexCoord1sv Name 'glTexCoord1sv',
  glTexCoord2d Name 'glTexCoord2d',
  glTexCoord2dv Name 'glTexCoord2dv',
  glTexCoord2f Name 'glTexCoord2f',
  glTexCoord2fv Name 'glTexCoord2fv',
  glTexCoord2i Name 'glTexCoord2i',
  glTexCoord2iv Name 'glTexCoord2iv',
  glTexCoord2s Name 'glTexCoord2s',
  glTexCoord2sv Name 'glTexCoord2sv',
  glTexCoord3d Name 'glTexCoord3d',
  glTexCoord3dv Name 'glTexCoord3dv',
  glTexCoord3f Name 'glTexCoord3f',
  glTexCoord3fv Name 'glTexCoord3fv',
  glTexCoord3i Name 'glTexCoord3i',
  glTexCoord3iv Name 'glTexCoord3iv',
  glTexCoord3s Name 'glTexCoord3s',
  glTexCoord3sv Name 'glTexCoord3sv',
  glTexCoord4d Name 'glTexCoord4d',
  glTexCoord4dv Name 'glTexCoord4dv',
  glTexCoord4f Name 'glTexCoord4f',
  glTexCoord4fv Name 'glTexCoord4fv',
  glTexCoord4i Name 'glTexCoord4i',
  glTexCoord4iv Name 'glTexCoord4iv',
  glTexCoord4s Name 'glTexCoord4s',
  glTexCoord4sv Name 'glTexCoord4sv',
  glRasterPos2d Name 'glRasterPos2d',
  glRasterPos2dv Name 'glRasterPos2dv',
  glRasterPos2f Name 'glRasterPos2f',
  glRasterPos2fv Name 'glRasterPos2fv',
  glRasterPos2i Name 'glRasterPos2i',
  glRasterPos2iv Name 'glRasterPos2iv',
  glRasterPos2s Name 'glRasterPos2s',
  glRasterPos2sv Name 'glRasterPos2sv',
  glRasterPos3d Name 'glRasterPos3d',
  glRasterPos3dv Name 'glRasterPos3dv',
  glRasterPos3f Name 'glRasterPos3f',
  glRasterPos3fv Name 'glRasterPos3fv',
  glRasterPos3i Name 'glRasterPos3i',
  glRasterPos3iv Name 'glRasterPos3iv',
  glRasterPos3s Name 'glRasterPos3s',
  glRasterPos3sv Name 'glRasterPos3sv',
  glRasterPos4d Name 'glRasterPos4d',
  glRasterPos4dv Name 'glRasterPos4dv',
  glRasterPos4f Name 'glRasterPos4f',
  glRasterPos4fv Name 'glRasterPos4fv',
  glRasterPos4i Name 'glRasterPos4i',
  glRasterPos4iv Name 'glRasterPos4iv',
  glRasterPos4s Name 'glRasterPos4s',
  glRasterPos4sv Name 'glRasterPos4sv',
  glMultiTexCoord1dARB Name 'glMultiTexCoord1dARB',
  glMultiTexCoord1dvARB Name 'glMultiTexCoord1dvARB',
  glMultiTexCoord1fARB Name 'glMultiTexCoord1fARB',
  glMultiTexCoord1fvARB Name 'glMultiTexCoord1fvARB',
  glMultiTexCoord1iARB Name 'glMultiTexCoord1iARB',
  glMultiTexCoord1ivARB Name 'glMultiTexCoord1ivARB',
  glMultiTexCoord1sARB Name 'glMultiTexCoord1sARB',
  glMultiTexCoord1svARB Name 'glMultiTexCoord1svARB',
  glMultiTexCoord2dARB Name 'glMultiTexCoord2dARB',
  glMultiTexCoord2dvARB Name 'glMultiTexCoord2dvARB',
  glMultiTexCoord2fARB Name 'glMultiTexCoord2fARB',
  glMultiTexCoord2fvARB Name 'glMultiTexCoord2fvARB',
  glMultiTexCoord2iARB Name 'glMultiTexCoord2iARB',
  glMultiTexCoord2ivARB Name 'glMultiTexCoord2ivARB',
  glMultiTexCoord2sARB Name 'glMultiTexCoord2sARB',
  glMultiTexCoord2svARB Name 'glMultiTexCoord2svARB',
  glMultiTexCoord3dARB Name 'glMultiTexCoord3dARB',
  glMultiTexCoord3dvARB Name 'glMultiTexCoord3dvARB',
  glMultiTexCoord3fARB Name 'glMultiTexCoord3fARB',
  glMultiTexCoord3fvARB Name 'glMultiTexCoord3fvARB',
  glMultiTexCoord3iARB Name 'glMultiTexCoord3iARB',
  glMultiTexCoord3ivARB Name 'glMultiTexCoord3ivARB',
  glMultiTexCoord3sARB Name 'glMultiTexCoord3sARB',
  glMultiTexCoord3svARB Name 'glMultiTexCoord3svARB',
  glMultiTexCoord4dARB Name 'glMultiTexCoord4dARB',
  glMultiTexCoord4dvARB Name 'glMultiTexCoord4dvARB',
  glMultiTexCoord4fARB Name 'glMultiTexCoord4fARB',
  glMultiTexCoord4fvARB Name 'glMultiTexCoord4fvARB',
  glMultiTexCoord4iARB Name 'glMultiTexCoord4iARB',
  glMultiTexCoord4ivARB Name 'glMultiTexCoord4ivARB',
  glMultiTexCoord4sARB Name 'glMultiTexCoord4sARB',
  glMultiTexCoord4svARB Name 'glMultiTexCoord4svARB',
  glIndexd Name 'glIndexd',
  glIndexdv Name 'glIndexdv',
  glIndexf Name 'glIndexf',
  glIndexfv Name 'glIndexfv',
  glIndexi Name 'glIndexi',
  glIndexiv Name 'glIndexiv',
  glIndexs Name 'glIndexs',
  glIndexsv Name 'glIndexsv',
  glIndexub Name 'glIndexub',
  glIndexubv Name 'glIndexubv',
  glRectd Name 'glRectd',
  glRectdv Name 'glRectdv',
  glRectf Name 'glRectf',
  glRectfv Name 'glRectfv',
  glRecti Name 'glRecti',
  glRectiv Name 'glRectiv',
  glRects Name 'glRects',
  glRectsv Name 'glRectsv',
  glAccum Name 'glAccum',
  glBitmap Name 'glBitmap',
  glClearAccum Name 'glClearAccum',
  glClearIndex Name 'glClearIndex',
  glClearStencil Name 'glClearStencil',
  glClipPlane Name 'glClipPlane',
  glGetClipPlane Name 'glGetClipPlane',
  glCopyPixels Name 'glCopyPixels',
  glEdgeFlag Name 'glEdgeFlag',
  glEdgeFlagv Name 'glEdgeFlagv',
  glEvalCoord1d Name 'glEvalCoord1d',
  glEvalCoord1dv Name 'glEvalCoord1dv',
  glEvalCoord1f Name 'glEvalCoord1f',
  glEvalCoord1fv Name 'glEvalCoord1fv',
  glEvalCoord2d Name 'glEvalCoord2d',
  glEvalCoord2dv Name 'glEvalCoord2dv',
  glEvalCoord2f Name 'glEvalCoord2f',
  glEvalCoord2fv Name 'glEvalCoord2fv',
  glEvalMesh1 Name 'glEvalMesh1',
  glEvalMesh2 Name 'glEvalMesh2',
  glEvalPoint1 Name 'glEvalPoint1',
  glEvalPoint2 Name 'glEvalPoint2',
  glFeedbackBuffer Name 'glFeedbackBuffer',
  glGetMapdv Name 'glGetMapdv',
  glGetMapfv Name 'glGetMapfv',
  glGetMapiv Name 'glGetMapiv',
  glGetPixelMapfv Name 'glGetPixelMapfv',
  glGetPixelMapuiv Name 'glGetPixelMapuiv',
  glGetPixelMapusv Name 'glGetPixelMapusv',
  glGetPolygonStipple Name 'glGetPolygonStipple',
  glIndexMask Name 'glIndexMask',
  glInitNames Name 'glInitNames',
  glLoadName Name 'glLoadName',
  glPushName Name 'glPushName',
  glPopName Name 'glPopName',
  glPassThrough Name 'glPassThrough',
  glSelectBuffer Name 'glSelectBuffer',
  glLineStipple Name 'glLineStipple',
  glLogicOp Name 'glLogicOp',
  glMap1d Name 'glMap1d',
  glMap1f Name 'glMap1f',
  glMap2d Name 'glMap2d',
  glMap2f Name 'glMap2f',
  glMapGrid1d Name 'glMapGrid1d',
  glMapGrid1f Name 'glMapGrid1f',
  glMapGrid2d Name 'glMapGrid2d',
  glMapGrid2f Name 'glMapGrid2f',
  glPixelMapfv Name 'glPixelMapfv',
  glPixelMapuiv Name 'glPixelMapuiv',
  glPixelMapusv Name 'glPixelMapusv',
  glPixelTransferf Name 'glPixelTransferf',
  glPixelTransferi Name 'glPixelTransferi',
  glPixelZoom Name 'glPixelZoom',
  glPolygonStipple Name 'glPolygonStipple',
  glStencilFunc Name 'glStencilFunc',
  glStencilMask Name 'glStencilMask',
  glStencilOp Name 'glStencilOp',
  glRenderMode Name 'glRenderMode';

BEGIN
  GlVcInit;
END.
