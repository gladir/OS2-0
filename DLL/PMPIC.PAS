{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMPIC.DLL de OS/2-0 (images : impression
                des metafichiers et des fichiers PIF, conversion PIF ->
                metafichier).
}

Library PMPIC;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC PMPIC.PAS   (produit PMPIC.DLL)

  PMPIC.DLL est la bibliothèque des images de Presentation Manager (outils
  PICPRINT et PICICHG d'OS/2) :

     1 PicPrint(hab, pszFilename, lType, pszParams) : BOOL
         imprime un metafichier (PIP_MF 1) ou un fichier PIF (PIP_PIF 2).
         L'image est dessinee par PMGPI.DLL dans une page de 640 x 480
         pels puis envoyee a l'imprimante en graphique ESC/P (ESC @, puis
         par bandes de 8 lignes : ESC * 1 (120 points par pouce) et ESC J
         24, et un saut de page). pszParams : peripherique ou fichier de
         sortie (PRN, LPT1 a LPT3, ou un nom de fichier ; PRN si vide) ;
         /W:n et /H:n changent la largeur et la hauteur de la page (pels).
     2 PicIchg(hab, pszFilename1, pszFilename2, lType) : BOOL
         conversion : PIC_PIFTOMET (0) fichier PIF -> metafichier ;
         PIC_SSTOFONT (2, jeu de symboles de GDDM -> police) n'est pas
         disponible (FALSE, PMERR_INV_FUNCTION).
     3 pif2met(pszPif, pszMet) : BOOL
         conversion d'un fichier PIF en metafichier (celle de PicIchg).

  Fichier PIF (Picture Interchange Format de GDDM) : il est lu comme une
  suite d'ordres de dessin GDF/GOCA (les memes que ceux des segments de
  la GPI) ; nombres de 16 bits signes, octet fort en premier ; texte en
  EBCDIC (page de codes 037). Format des ordres :
    00h                     sans effet (1 octet)
    08h-0Fh et 38h-3Fh      forme courte : code, un octet de donnee
    FEh                     forme tres longue : code, code 2, longueur
                            sur 2 octets, donnees (ignore)
    autres                  forme longue : code, longueur, donnees
  Ordres reconnus (les autres sont sautes d'apres leur longueur) :
    0Ah GSCOL couleur (0 defaut, 1 bleu, 2 rouge, 3 rose, 4 vert, 5
        turquoise, 6 jaune, 7 neutre, 8 noir, 9 a 15 comme CLR_*)
    26h GSECOL couleur etendue (2 octets)
    0Ch GSMX melange, 0Dh GSBMX melange du fond (FM_*, BM_*)
    08h GSPS jeu de motifs (ignore), 28h GSPT motif (1 octet)
    18h GSLT type de ligne, 19h GSLW largeur de ligne (1 octet)
    29h GSMT symbole de marqueur (1 octet)
    21h GSCP position courante (x, y)
    22h GSAP parametres d'arc (p, q, r, s)
    33h GSCC boite de caractere (cx, cy), 34h GSCA angle (x, y)
    C1h GLINE  lignes : (x, y) de depart puis points ; 81h GCLINE depuis
               la position courante : points
    E1h GRLINE lignes relatives : (x, y) puis deplacements (dx, dy d'un
               octet signe) ; A1h GCRLINE depuis la position courante
    C0h GBOX   boite : drapeaux (40h remplie, 20h contour), reserve,
               (x1, y1), (x2, y2) [, coins arrondis h, v] ; 80h GCBOX
               depuis la position courante : drapeaux, reserve, (x2, y2)
               [, h, v]
    C7h GFARC  cercle : centre (x, y), multiplicateur (entier, fraction
               sur 256) ; 87h GCFARC autour de la position courante
    E3h GPARC  arc : centre (x, y), multiplicateur (2 octets), angle de
               depart et balayage en degres (2 octets chacun) ; A3h GCPARC
    C5h GFLT   filet : (x, y) puis points ; 85h GCFLT
    C2h GMRK   marqueurs aux points ; 82h GCMRK
    C3h GCHST  texte : (x, y) puis caracteres EBCDIC ; 83h GCCHST a la
               position courante
    68h GBAR   debut de zone (drapeaux : 40h remplissage par
               enroulement) ; 60h GEAR fin de zone
  Les segments (ordres 70h...) et commentaires (01h) sont sautes.

  Convention _System (comme DOSCALLS.DLL). Erreurs : WinGetLastError de
  PMWIN.DLL (PMERR_INV_FUNCTION, PMERR_INVALID_PARM, fichier absent :
  PMERR_INV_FILE). }

Const
  PIP_MF = 1; PIP_PIF = 2;
  PIC_PIFTOMET = 0; PIC_SSTOFONT = 2;
  OD_MEMORY = 8; OD_METAFILE = 3;
  PU_PELS = 8; GPIA_ASSOC = $4000;
  PMERR_INV_FUNCTION = $1001;
  PMERR_INVALID_PARM = $1303;
  PMERR_INV_FILE = $1102;
  MaxPif = 262144;

  { EBCDIC (page de codes 037) -> ASCII ; 63 '?' pour les autres }
  Ebc : Array[0..255] Of Byte = (
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,
    32, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 46, 60, 40, 43, 124,
    38, 63, 63, 63, 63, 63, 63, 63, 63, 63, 33, 36, 42, 41, 59, 63,
    45, 47, 63, 63, 63, 63, 63, 63, 63, 63, 63, 44, 37, 95, 62, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 96, 58, 35, 64, 39, 61, 34,
    63, 97, 98, 99, 100, 101, 102, 103, 104, 105, 63, 63, 63, 63, 63, 63,
    63, 106, 107, 108, 109, 110, 111, 112, 113, 114, 63, 63, 63, 63, 63, 63,
    63, 126, 115, 116, 117, 118, 119, 120, 121, 122, 63, 63, 63, 91, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 93, 63, 63,
    123, 65, 66, 67, 68, 69, 70, 71, 72, 73, 63, 63, 63, 63, 63, 63,
    125, 74, 75, 76, 77, 78, 79, 80, 81, 82, 63, 63, 63, 63, 63, 63,
    92, 63, 83, 84, 85, 86, 87, 88, 89, 90, 63, 63, 63, 63, 63, 63,
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 63, 63, 63, 63, 63, 63);

Type
  PLong = ^LongInt;
  PByte = ^Byte;

{ --- services des autres DLL --- }
Function DcOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function DcRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function DcAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS' Name 'DosAllocMem';
Function DcFreeMem(Pb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosFreeMem';
Function WinSetErrorInfo(E, Fs : LongInt) : LongInt; External 'PMWIN' Name 'WinSetErrorInfo';
Function DevOpenDC(Hab, T, PTok, N, PDop, Hc : LongInt) : LongInt; External 'PMGPI' Name 'DevOpenDC';
Function DevCloseDC(H : LongInt) : LongInt; External 'PMGPI' Name 'DevCloseDC';
Function GpiCreatePS(Hab, Hdc, PSz, Fl : LongInt) : LongInt; External 'PMGPI' Name 'GpiCreatePS';
Function GpiDestroyPS(H : LongInt) : LongInt; External 'PMGPI' Name 'GpiDestroyPS';
Function GpiAssociate(H, Hdc : LongInt) : LongInt; External 'PMGPI' Name 'GpiAssociate';
Function GpiErase(H : LongInt) : LongInt; External 'PMGPI' Name 'GpiErase';
Function GpiCreateBitmap(H, PHdr, Fl, PInit, Pbmi : LongInt) : LongInt; External 'PMGPI' Name 'GpiCreateBitmap';
Function GpiSetBitmap(H, Hbm : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetBitmap';
Function GpiDeleteBitmap(Hbm : LongInt) : LongInt; External 'PMGPI' Name 'GpiDeleteBitmap';
Function GpiQueryBitmapBits(H, S, N, PB, Pbmi : LongInt) : LongInt; External 'PMGPI' Name 'GpiQueryBitmapBits';
Function GpiSetColor(H, C : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetColor';
Function GpiSetMix(H, M : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetMix';
Function GpiSetBackMix(H, M : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetBackMix';
Function GpiSetPattern(H, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetPattern';
Function GpiSetLineType(H, T : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetLineType';
Function GpiSetLineWidth(H, W : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetLineWidth';
Function GpiSetMarker(H, S : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetMarker';
Function GpiSetArcParams(H, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetArcParams';
Function GpiSetCharBox(H, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetCharBox';
Function GpiSetCharAngle(H, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiSetCharAngle';
Function GpiMove(H, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiMove';
Function GpiLine(H, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiLine';
Function GpiBox(H, C, P, HR, VR : LongInt) : LongInt; External 'PMGPI' Name 'GpiBox';
Function GpiFullArc(H, C, M : LongInt) : LongInt; External 'PMGPI' Name 'GpiFullArc';
Function GpiPartialArc(H, P, M, A, S : LongInt) : LongInt; External 'PMGPI' Name 'GpiPartialArc';
Function GpiPolyFillet(H, N, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiPolyFillet';
Function GpiMarker(H, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiMarker';
Function GpiCharStringAt(H, P, N, S : LongInt) : LongInt; External 'PMGPI' Name 'GpiCharStringAt';
Function GpiCharString(H, N, S : LongInt) : LongInt; External 'PMGPI' Name 'GpiCharString';
Function GpiBeginArea(H, F : LongInt) : LongInt; External 'PMGPI' Name 'GpiBeginArea';
Function GpiEndArea(H : LongInt) : LongInt; External 'PMGPI' Name 'GpiEndArea';
Function GpiQueryCurrentPosition(H, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiQueryCurrentPosition';
Function GpiPlayMetaFile(H, M, N1, PO, PS, N2, PD : LongInt) : LongInt; External 'PMGPI' Name 'GpiPlayMetaFile';
Function GpiLoadMetaFile(Hab, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiLoadMetaFile';
Function GpiSaveMetaFile(M, P : LongInt) : LongInt; External 'PMGPI' Name 'GpiSaveMetaFile';
Function GpiDeleteMetaFile(M : LongInt) : LongInt; External 'PMGPI' Name 'GpiDeleteMetaFile';

Var
  Pt : Array[0..63] Of LongInt;
  Txt : Array[0..259] Of Byte;
  Bmi : Array[0..15] Of LongInt;
  NameZ : Array[0..259] Of Byte;
  OutB : Array[0..2047] Of Byte;
  OutN, OutH, OutErr : LongInt;
  PageW, PageH : LongInt;
  Dummy : LongInt;

{ ==================================================================== }
{ Utilitaires                                                          }
{ ==================================================================== }

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  P := Pointer(A);
  P^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  P := Pointer(A);
  P^ := V And 255;
End;

Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (N < 255) And (RdB(A + N) <> 0) Do
    Begin
      S := S + Chr(RdB(A + N));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Procedure SetErr(Code : LongInt);
Begin
  Dummy := WinSetErrorInfo($40000 Or Code, 0);
End;

{ nombre de 16 bits signe, octet fort en premier }
Function S16(A : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := (RdB(A) Shl 8) Or RdB(A + 1);
  If V >= 32768 Then V := V - 65536;
  S16 := V;
End;

{ octet signe }
Function S8(A : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := RdB(A);
  If V >= 128 Then V := V - 256;
  S8 := V;
End;

{ couleur GOCA -> couleur de PM }
Function PifColor(V : LongInt) : LongInt;
Begin
  If V = 0 Then PifColor := -3
  Else If V = 8 Then PifColor := -1
  Else If V >= 32768 Then PifColor := V - 65536
  Else PifColor := V;
End;

{ fichier entier dans un bloc de DosAllocMem ; taille, 0 : erreur }
Function LoadFile(PName : LongInt; Var B : LongInt) : LongInt;
Var H, Act, N, Got : LongInt;
Begin
  LoadFile := 0; B := 0;
  H := 0; Act := 0;
  If DcOpen(PName, LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> 0 Then Exit;
  If DcAllocMem(LongInt(@B), MaxPif, $13) <> 0 Then
  Begin
    B := 0;
    Dummy := DcClose(H);
    Exit;
  End;
  N := 0; Got := 0;
  Repeat
    Got := 0;
    If DcRead(H, B + N, MinI(MaxPif - N, 65536), LongInt(@Got)) <> 0 Then Got := 0;
    N := N + Got;
  Until (Got = 0) Or (N >= MaxPif);
  Dummy := DcClose(H);
  LoadFile := N;
End;

{ ==================================================================== }
{ PIF -> metafichier                                                   }
{ ==================================================================== }

{ points (x, y) de 16 bits a partir de A (N points) dans Pt }
Procedure GetPts(A, N : LongInt);
Var K : LongInt;
Begin
  If N > 32 Then N := 32;
  For K := 0 To N - 1 Do
  Begin
    Pt[K * 2] := S16(A + K * 4);
    Pt[K * 2 + 1] := S16(A + K * 4 + 2);
  End;
End;

Procedure MoveTo2(Hps, X, Y : LongInt);
Begin
  Pt[0] := X; Pt[1] := Y;
  Dummy := GpiMove(Hps, LongInt(@Pt));
End;

{ lignes vers les N points de Pt }
Procedure Lines(Hps, N : LongInt);
Var K : LongInt; Q : Array[0..1] Of LongInt;
Begin
  For K := 0 To N - 1 Do
  Begin
    Q[0] := Pt[K * 2]; Q[1] := Pt[K * 2 + 1];
    Dummy := GpiLine(Hps, LongInt(@Q));
  End;
End;

{ texte EBCDIC de N octets en A }
Function EbcText(A, N : LongInt) : LongInt;
Var K : LongInt;
Begin
  If N > 255 Then N := 255;
  If N < 0 Then N := 0;
  For K := 0 To N - 1 Do Txt[K] := Ebc[RdB(A + K)];
  Txt[N] := 0;
  EbcText := N;
End;

{ executer un ordre (code C, donnees en D, L octets) }
Procedure PifOrder(Hps, C, D, L : LongInt);
Var N, X, Y, K, M, F : LongInt; Q : Array[0..3] Of LongInt;
Begin
  Case C Of
    $0A : Dummy := GpiSetColor(Hps, PifColor(RdB(D)));
    $26 : If L >= 2 Then Dummy := GpiSetColor(Hps, PifColor((RdB(D) Shl 8) Or RdB(D + 1)));
    $0C : Dummy := GpiSetMix(Hps, RdB(D));
    $0D : Dummy := GpiSetBackMix(Hps, RdB(D));
    $28 : If L >= 1 Then Dummy := GpiSetPattern(Hps, RdB(D));
    $18 : If L >= 1 Then Dummy := GpiSetLineType(Hps, RdB(D));
    $19 : If L >= 1 Then Dummy := GpiSetLineWidth(Hps, RdB(D) Shl 16);
    $29 : If L >= 1 Then Dummy := GpiSetMarker(Hps, RdB(D));
    $21 : If L >= 4 Then MoveTo2(Hps, S16(D), S16(D + 2));
    $22 : If L >= 8 Then
          Begin
            Q[0] := S16(D); Q[1] := S16(D + 2); Q[2] := S16(D + 4); Q[3] := S16(D + 6);
            Dummy := GpiSetArcParams(Hps, LongInt(@Q));
          End;
    $33 : If L >= 4 Then
          Begin
            Q[0] := S16(D) Shl 16; Q[1] := S16(D + 2) Shl 16;
            Dummy := GpiSetCharBox(Hps, LongInt(@Q));
          End;
    $34 : If L >= 4 Then
          Begin
            Q[0] := S16(D); Q[1] := S16(D + 2);
            Dummy := GpiSetCharAngle(Hps, LongInt(@Q));
          End;
    $C1, $81 :
      Begin
        N := L Div 4;
        If C = $C1 Then
        Begin
          If N < 1 Then Exit;
          MoveTo2(Hps, S16(D), S16(D + 2));
          D := D + 4; Dec(N);
        End;
        GetPts(D, N);
        Lines(Hps, MinI(N, 32));
      End;
    $E1, $A1 :
      Begin
        If C = $E1 Then
        Begin
          If L < 4 Then Exit;
          MoveTo2(Hps, S16(D), S16(D + 2));
          D := D + 4; L := L - 4;
        End;
        Dummy := GpiQueryCurrentPosition(Hps, LongInt(@Q));
        X := Q[0]; Y := Q[1];
        K := 0;
        While K + 1 < L Do
        Begin
          X := X + S8(D + K); Y := Y + S8(D + K + 1);
          Q[0] := X; Q[1] := Y;
          Dummy := GpiLine(Hps, LongInt(@Q));
          K := K + 2;
        End;
      End;
    $C0, $80 :
      Begin
        If L < 6 Then Exit;
        F := RdB(D);
        If (F And $60) = $60 Then M := 3 Else If (F And $40) <> 0 Then M := 1 Else M := 2;
        If C = $C0 Then
        Begin
          If L < 10 Then Exit;
          MoveTo2(Hps, S16(D + 2), S16(D + 4));
          D := D + 4; L := L - 4;
        End;
        Q[0] := S16(D + 2); Q[1] := S16(D + 4);
        X := 0; Y := 0;
        If L >= 10 Then
        Begin
          X := S16(D + 6); Y := S16(D + 8);
        End;
        Dummy := GpiBox(Hps, M, LongInt(@Q), X, Y);
      End;
    $C7, $87 :
      Begin
        If C = $C7 Then
        Begin
          If L < 6 Then Exit;
          MoveTo2(Hps, S16(D), S16(D + 2));
          D := D + 4; L := L - 4;
        End;
        If L < 2 Then Exit;
        Dummy := GpiFullArc(Hps, 2, (RdB(D) Shl 16) Or (RdB(D + 1) Shl 8));
      End;
    $E3, $A3 :
      Begin
        If C = $E3 Then
        Begin
          If L < 10 Then Exit;
          Q[0] := S16(D); Q[1] := S16(D + 2);
          D := D + 4;
        End
        Else
        Begin
          If L < 6 Then Exit;
          Dummy := GpiQueryCurrentPosition(Hps, LongInt(@Q));
        End;
        Dummy := GpiPartialArc(Hps, LongInt(@Q), S16(D) Shl 16, S16(D + 2) Shl 16, S16(D + 4) Shl 16);
      End;
    $C5, $85 :
      Begin
        N := L Div 4;
        If C = $C5 Then
        Begin
          If N < 1 Then Exit;
          MoveTo2(Hps, S16(D), S16(D + 2));
          D := D + 4; Dec(N);
        End;
        If N > 32 Then N := 32;
        GetPts(D, N);
        If N >= 2 Then Dummy := GpiPolyFillet(Hps, N, LongInt(@Pt))
        Else Lines(Hps, N);
      End;
    $C2, $82 :
      Begin
        N := MinI(L Div 4, 32);
        If (C = $82) And (N = 0) Then
        Begin
          Dummy := GpiQueryCurrentPosition(Hps, LongInt(@Q));
          Dummy := GpiMarker(Hps, LongInt(@Q));
        End;
        GetPts(D, N);
        For K := 0 To N - 1 Do
        Begin
          Q[0] := Pt[K * 2]; Q[1] := Pt[K * 2 + 1];
          Dummy := GpiMarker(Hps, LongInt(@Q));
        End;
      End;
    $C3 :
      If L >= 4 Then
      Begin
        Q[0] := S16(D); Q[1] := S16(D + 2);
        N := EbcText(D + 4, L - 4);
        Dummy := GpiCharStringAt(Hps, LongInt(@Q), N, LongInt(@Txt));
      End;
    $83 :
      Begin
        N := EbcText(D, L);
        Dummy := GpiCharString(Hps, N, LongInt(@Txt));
      End;
    $68 :
      Begin
        F := 0;
        If L >= 1 Then
          If (RdB(D) And $40) <> 0 Then F := 2;
        Dummy := GpiBeginArea(Hps, 1 Or F);
      End;
    $60 : Dummy := GpiEndArea(Hps);
  End;
End;

{ fichier PIF -> metafichier de PMGPI (HMF) ; 0 : erreur }
Function PifToHmf(PPif : LongInt) : LongInt;
Var B, N, Hdc, Hps, P, C, L, D : LongInt;
Begin
  PifToHmf := 0;
  N := LoadFile(PPif, B);
  If B = 0 Then
  Begin
    SetErr(PMERR_INV_FILE);
    Exit;
  End;
  PutZ(LongInt(@NameZ), '*');
  Hdc := DevOpenDC(0, OD_METAFILE, LongInt(@NameZ), 0, 0, 0);
  Hps := GpiCreatePS(0, Hdc, 0, PU_PELS Or GPIA_ASSOC);
  If (Hdc = 0) Or (Hps = 0) Then
  Begin
    Dummy := DcFreeMem(B);
    Exit;
  End;
  P := 0;
  While P < N Do
  Begin
    C := RdB(B + P);
    If C = 0 Then Inc(P)
    Else If ((C And $F0) = 0) Or ((C And $F0) = $30) Then
    Begin
      If (C And $0F) >= 8 Then
      Begin
        If P + 1 < N Then PifOrder(Hps, C, B + P + 1, 1);
        P := P + 2;
      End
      Else
      Begin
        If P + 1 >= N Then L := 0 Else L := RdB(B + P + 1);
        D := B + P + 2;
        If D + L <= B + N Then PifOrder(Hps, C, D, L);
        P := P + 2 + L;
      End;
    End
    Else If C = $FE Then
    Begin
      If P + 3 < N Then L := (RdB(B + P + 2) Shl 8) Or RdB(B + P + 3) Else L := 0;
      P := P + 4 + L;
    End
    Else
    Begin
      If P + 1 >= N Then L := 0 Else L := RdB(B + P + 1);
      D := B + P + 2;
      If D + L <= B + N Then PifOrder(Hps, C, D, L);
      P := P + 2 + L;
    End;
  End;
  Dummy := DcFreeMem(B);
  Dummy := GpiAssociate(Hps, 0);
  Dummy := GpiDestroyPS(Hps);
  PifToHmf := DevCloseDC(Hdc);
End;

{ pif2met(pszPif, pszMet) : BOOL }
Function pif2met(PPif, PMet : LongInt) : LongInt;
Var M : LongInt;
Begin
  pif2met := 0;
  If (PPif = 0) Or (PMet = 0) Then
  Begin
    SetErr(PMERR_INVALID_PARM);
    Exit;
  End;
  M := PifToHmf(PPif);
  If M = 0 Then Exit;
  If GpiSaveMetaFile(M, PMet) <> 0 Then pif2met := 1
  Else Dummy := GpiDeleteMetaFile(M);
End;

{ PicIchg(hab, pszFilename1, pszFilename2, lType) : BOOL }
Function PicIchg(Hab, P1, P2, Typ : LongInt) : LongInt;
Begin
  PicIchg := 0;
  If Typ = PIC_PIFTOMET Then PicIchg := pif2met(P1, P2)
  Else SetErr(PMERR_INV_FUNCTION);
End;

{ ==================================================================== }
{ Impression (graphique ESC/P)                                         }
{ ==================================================================== }

Procedure OutFlush;
Var W : LongInt;
Begin
  If (OutN > 0) And (OutErr = 0) Then
  Begin
    W := 0;
    If DcWrite(OutH, LongInt(@OutB), OutN, LongInt(@W)) <> 0 Then OutErr := 1;
  End;
  OutN := 0;
End;

Procedure OutByte(V : LongInt);
Begin
  If OutN >= 2048 Then OutFlush;
  OutB[OutN] := V And 255;
  Inc(OutN);
End;

{ nombre apres /W: ou /H: dans les parametres (Def s'il n'y est pas) }
Function ParamNum(S, Key : String; Def : LongInt) : LongInt;
Var I, V : LongInt; Got : Boolean;
Begin
  ParamNum := Def;
  I := Pos(Key, UpStr(S));
  If I = 0 Then Exit;
  I := I + Length(Key);
  V := 0; Got := False;
  While (I <= Length(S)) And (S[I] >= '0') And (S[I] <= '9') Do
  Begin
    V := V * 10 + Ord(S[I]) - 48;
    Got := True;
    Inc(I);
  End;
  If Got And (V >= 8) And (V <= 4000) Then ParamNum := V;
End;

{ sortie : premier mot des parametres qui n'est pas une option }
Function ParamOut(S : String) : String;
Var I : LongInt; W, R : String;
Begin
  R := ''; W := '';
  S := S + ' ';
  For I := 1 To Length(S) Do
    If S[I] = ' ' Then
    Begin
      If (W <> '') And (W[1] <> '/') And (R = '') Then R := W;
      W := '';
    End
    Else W := W + S[I];
  If R = '' Then R := 'PRN';
  ParamOut := R;
End;

{ PicPrint(hab, pszFilename, lType, pszParams) : BOOL }
Function PicPrint(Hab, PName, Typ, PPrm : LongInt) : LongInt;
Var M, Hdc, Hps, Hbm, Act, Stride, Bits, Band, Row, X, R, V, Lum, Bv, A, Y0 : LongInt; Prm : String;
Begin
  PicPrint := 0;
  If PName = 0 Then
  Begin
    SetErr(PMERR_INVALID_PARM);
    Exit;
  End;
  If Typ = PIP_MF Then
  Begin
    M := GpiLoadMetaFile(Hab, PName);
    If M = 0 Then
    Begin
      SetErr(PMERR_INV_FILE);
      Exit;
    End;
  End
  Else If Typ = PIP_PIF Then
  Begin
    M := PifToHmf(PName);
    If M = 0 Then Exit;
  End
  Else
  Begin
    SetErr(PMERR_INVALID_PARM);
    Exit;
  End;
  Prm := GetZ(PPrm);
  PageW := ParamNum(Prm, '/W:', 640); PageH := ParamNum(Prm, '/H:', 480);
  PageH := (PageH + 7) And Not 7;
  { page en 24 bits : PMGPI dessine le metafichier }
  PutZ(LongInt(@NameZ), '*');
  Hdc := DevOpenDC(Hab, OD_MEMORY, LongInt(@NameZ), 0, 0, 0);
  Hps := GpiCreatePS(Hab, Hdc, 0, PU_PELS Or GPIA_ASSOC);
  For R := 0 To 15 Do Bmi[R] := 0;
  Bmi[0] := 16; Bmi[1] := PageW; Bmi[2] := PageH; Bmi[3] := 1 Or (24 Shl 16);
  Hbm := GpiCreateBitmap(Hps, LongInt(@Bmi), 0, 0, 0);
  If (Hdc = 0) Or (Hps = 0) Or (Hbm = 0) Or (GpiSetBitmap(Hps, Hbm) = -1) Then
  Begin
    Dummy := GpiDeleteMetaFile(M);
    Exit;
  End;
  Dummy := GpiErase(Hps);
  Dummy := GpiPlayMetaFile(Hps, M, 0, 0, 0, 0, 0);
  Dummy := GpiDeleteMetaFile(M);
  { imprimante ou fichier }
  PutZ(LongInt(@NameZ), ParamOut(Prm));
  OutH := 0; Act := 0; OutN := 0; OutErr := 0;
  If DcOpen(LongInt(@NameZ), LongInt(@OutH), LongInt(@Act), 0, 0, $12, $22, 0) <> 0 Then
  Begin
    SetErr(PMERR_INV_FILE);
    OutErr := 1;
  End;
  Stride := ((PageW * 24 + 31) Div 32) * 4;
  Bits := 0;
  If (OutErr = 0) And (DcAllocMem(LongInt(@Bits), Stride * 8, $13) = 0) Then
  Begin
    OutByte(27); OutByte(Ord('@'));
    Band := 0;
    While Band < PageH Div 8 Do
    Begin
      { 8 lignes du haut vers le bas : lignes du bitmap PageH-8-8*Band.. }
      Y0 := PageH - 8 - Band * 8;
      Dummy := GpiQueryBitmapBits(Hps, Y0, 8, Bits, LongInt(@Bmi));
      OutByte(27); OutByte(Ord('*')); OutByte(1); OutByte(PageW And 255); OutByte(PageW Shr 8);
      X := 0;
      While X < PageW Do
      Begin
        V := 0;
        For R := 0 To 7 Do
        Begin
          { R = 0 : ligne du haut de la bande (bit 7) }
          A := Bits + (7 - R) * Stride + X * 3;
          Lum := RdB(A) * 11 + RdB(A + 1) * 59 + RdB(A + 2) * 30;
          If Lum < 12800 Then V := V Or ($80 Shr R);
        End;
        OutByte(V);
        Inc(X);
      End;
      OutByte(27); OutByte(Ord('J')); OutByte(24);
      Inc(Band);
    End;
    OutByte(12);
    OutFlush;
    Dummy := DcFreeMem(Bits);
  End
  Else OutErr := 1;
  If OutH <> 0 Then Dummy := DcClose(OutH);
  Dummy := GpiSetBitmap(Hps, 0);
  Dummy := GpiDeleteBitmap(Hbm);
  Dummy := GpiDestroyPS(Hps);
  Dummy := DevCloseDC(Hdc);
  If OutErr = 0 Then PicPrint := 1;
End;

exports
  PicPrint Index 1 Name 'PicPrint',
  PicIchg Index 2 Name 'PicIchg',
  pif2met Index 3 Name 'pif2met';

BEGIN
END.
