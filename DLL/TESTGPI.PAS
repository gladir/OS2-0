{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de PMGPI.DLL sous OS/2-0.
}

Program TESTGPI;

{$R-,S-,I-}

{ Compilation : OS2PC TESTGPI.PAS   (produit TESTGPI.EXE)

  TESTGPI verifie PMGPI.DLL : ses 572 ordinaux, puis le dessin dans des
  bitmaps en memoire (pels relus par GpiQueryPel et GpiQueryBitmapBits) :
  lignes, boites, arcs, zones, chemins, texte, marqueurs, images,
  melanges, motifs de ligne, regions et decoupage, transformations,
  unites de page, GpiBitBlt, tables de couleurs, palettes, polices,
  segments retenus, correlation, donnees de limites, metafichiers,
  remplissage par diffusion, piles d'attributs. Il dessine ensuite a
  l'ecran en 640 x 480 x 16 couleurs (VioSetMode, quelques secondes)
  puis dans un espace de presentation de PMWIN (ecran graphique de PM :
  640 x 480 x 16 couleurs ; ecran texte si PMMODE=TEXTE). }

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function VioSetMode(P, H : LongInt) : LongInt; External 'VIOCALLS';

Function DevOpenDC(Hab, T, PTok, N, PDop, Hc : LongInt) : LongInt; External 'PMGPI';
Function DevCloseDC(H : LongInt) : LongInt; External 'PMGPI';
Function DevQueryCaps(H, S, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiCreatePS(Hab, Hdc, PSz, Fl : LongInt) : LongInt; External 'PMGPI';
Function GpiDestroyPS(H : LongInt) : LongInt; External 'PMGPI';
Function GpiAssociate(H, Hdc : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryPS(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiErase(H : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateBitmap(H, PHdr, Fl, PInit, Pbmi : LongInt) : LongInt; External 'PMGPI';
Function GpiSetBitmap(H, Hbm : LongInt) : LongInt; External 'PMGPI';
Function GpiDeleteBitmap(Hbm : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryBitmapParameters(Hbm, P : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryBitmapBits(H, S, N, PB, Pbmi : LongInt) : LongInt; External 'PMGPI';
Function GpiSetBitmapBits(H, S, N, PB, Pbmi : LongInt) : LongInt; External 'PMGPI';
Function GpiSetColor(H, C : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryColor(H : LongInt) : LongInt; External 'PMGPI';
Function GpiSetBackColor(H, C : LongInt) : LongInt; External 'PMGPI';
Function GpiSetMix(H, M : LongInt) : LongInt; External 'PMGPI';
Function GpiSetBackMix(H, M : LongInt) : LongInt; External 'PMGPI';
Function GpiSetLineType(H, T : LongInt) : LongInt; External 'PMGPI';
Function GpiSetLineWidth(H, W : LongInt) : LongInt; External 'PMGPI';
Function GpiSetPattern(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiPolyLine(H, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(H, C, P, HR, VR : LongInt) : LongInt; External 'PMGPI';
Function GpiSetArcParams(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiFullArc(H, C, M : LongInt) : LongInt; External 'PMGPI';
Function GpiPartialArc(H, P, M, A, S : LongInt) : LongInt; External 'PMGPI';
Function GpiPointArc(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiPolySpline(H, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiPolyFillet(H, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryCurrentPosition(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBeginArea(H, F : LongInt) : LongInt; External 'PMGPI';
Function GpiEndArea(H : LongInt) : LongInt; External 'PMGPI';
Function GpiBeginPath(H, Id : LongInt) : LongInt; External 'PMGPI';
Function GpiEndPath(H : LongInt) : LongInt; External 'PMGPI';
Function GpiCloseFigure(H : LongInt) : LongInt; External 'PMGPI';
Function GpiFillPath(H, Id, F : LongInt) : LongInt; External 'PMGPI';
Function GpiPathToRegion(H, Id, F : LongInt) : LongInt; External 'PMGPI';
Function GpiCharStringAt(H, P, N, S : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryTextBox(H, N, S, N2, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetCharBox(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetMarker(H, S : LongInt) : LongInt; External 'PMGPI';
Function GpiMarker(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiImage(H, F, PSz, L, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetPel(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryPel(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateRegion(H, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiDestroyRegion(H, R : LongInt) : LongInt; External 'PMGPI';
Function GpiCombineRegion(H, D, A, B, M : LongInt) : LongInt; External 'PMGPI';
Function GpiEqualRegion(H, A, B : LongInt) : LongInt; External 'PMGPI';
Function GpiOffsetRegion(H, R, P : LongInt) : LongInt; External 'PMGPI';
Function GpiPtInRegion(H, R, P : LongInt) : LongInt; External 'PMGPI';
Function GpiRectInRegion(H, R, P : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryRegionBox(H, R, P : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryRegionRects(H, R, PB, PC, PR : LongInt) : LongInt; External 'PMGPI';
Function GpiSetClipRegion(H, R, P : LongInt) : LongInt; External 'PMGPI';
Function GpiPaintRegion(H, R : LongInt) : LongInt; External 'PMGPI';
Function GpiSetModelTransformMatrix(H, N, P, O : LongInt) : LongInt; External 'PMGPI';
Function GpiConvert(H, S, T, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiRotate(H, P, O, A, C : LongInt) : LongInt; External 'PMGPI';
Function GpiScale(H, P, O, S, C : LongInt) : LongInt; External 'PMGPI';
Function GpiTranslate(H, P, O, T : LongInt) : LongInt; External 'PMGPI';
Function GpiBitBlt(T, S, N, P, R, F : LongInt) : LongInt; External 'PMGPI';
Function GpiWCBitBlt(T, B, N, P, R, F : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateLogColorTable(H, O, F, S, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryRGBColor(H, O, C : LongInt) : LongInt; External 'PMGPI';
Function GpiCreatePalette(Hab, O, F, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSelectPalette(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryPaletteInfo(P, H, O, S, N, A : LongInt) : LongInt; External 'PMGPI';
Function GpiDeletePalette(P : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryFonts(H, O, PF, PN, L, P : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateLogFont(H, PN, Id, PF : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryNumberSetIds(H : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryFontMetrics(H, L, P : LongInt) : LongInt; External 'PMGPI';
Function GpiDeleteSetId(H, Id : LongInt) : LongInt; External 'PMGPI';
Function GpiSetDrawingMode(H, M : LongInt) : LongInt; External 'PMGPI';
Function GpiOpenSegment(H, Id : LongInt) : LongInt; External 'PMGPI';
Function GpiCloseSegment(H : LongInt) : LongInt; External 'PMGPI';
Function GpiDrawSegment(H, Id : LongInt) : LongInt; External 'PMGPI';
Function GpiDrawChain(H : LongInt) : LongInt; External 'PMGPI';
Function GpiDeleteSegment(H, Id : LongInt) : LongInt; External 'PMGPI';
Function GpiQuerySegmentNames(H, F, L, M, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetElementPointer(H, N : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryElementPointer(H : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryElementType(H, PT, L, PD : LongInt) : LongInt; External 'PMGPI';
Function GpiLabel(H, L : LongInt) : LongInt; External 'PMGPI';
Function GpiSetElementPointerAtLabel(H, L : LongInt) : LongInt; External 'PMGPI';
Function GpiCorrelateChain(H, T, P, M, D, A : LongInt) : LongInt; External 'PMGPI';
Function GpiSetTag(H, T : LongInt) : LongInt; External 'PMGPI';
Function GpiSetDrawControl(H, C, V : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryBoundaryData(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiResetBoundaryData(H : LongInt) : LongInt; External 'PMGPI';
Function GpiPlayMetaFile(H, M, N1, PO, PS, N2, PD : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryMetaFileLength(M : LongInt) : LongInt; External 'PMGPI';
Function GpiSaveMetaFile(M, P : LongInt) : LongInt; External 'PMGPI';
Function GpiLoadMetaFile(Hab, P : LongInt) : LongInt; External 'PMGPI';
Function GpiDeleteMetaFile(M : LongInt) : LongInt; External 'PMGPI';
Function GpiFloodFill(H, O, C : LongInt) : LongInt; External 'PMGPI';
Function GpiSetAttrMode(H, M : LongInt) : LongInt; External 'PMGPI';
Function GpiPop(H, N : LongInt) : LongInt; External 'PMGPI';
Function GpiSavePS(H : LongInt) : LongInt; External 'PMGPI';
Function GpiRestorePS(H, Id : LongInt) : LongInt; External 'PMGPI';
Function GpiSetAttrs(H, P, M, D, B : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryAttrs(H, P, M, B : LongInt) : LongInt; External 'PMGPI';
Function GpiSetCurrentPosition(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiPtVisible(H, P : LongInt) : LongInt; External 'PMGPI';

Function WinInitialize(F : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetScreenPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(H : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyMsgQueue(H : LongInt) : LongInt; External 'PMWIN';
Function WinTerminate(H : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(H, I : LongInt) : LongInt; External 'PMWIN';

Const
  OD_MEMORY = 8; OD_DIRECT = 5; OD_METAFILE = 3;
  PU_PELS = 8; PU_LOMETRIC = $0C; GPIA_ASSOC = $4000; GPIT_MICRO = $1000;
  CLR_BACKGROUND = 0; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_NEUTRAL = 7; CLR_BLACK = -1; CLR_WHITE = -2; CLR_DARKBLUE = 9; CLR_BROWN = 14;
  DRO_FILL = 1; DRO_OUTLINE = 2; DRO_OUTLINEFILL = 3;
  FM_XOR = 4; FM_OVERPAINT = 2;
  ROP_SRCCOPY = $CC; ROP_DSTINVERT = $55; ROP_PATCOPY = $F0;
  NOrd = 572;
  Ords : Array[0..571] Of Word = (
    1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17,
    18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33,
    34, 35, 36, 37, 38, 42, 43, 44, 46, 47, 48, 49, 51, 52, 53, 54,
    55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
    71, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92,
    93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
    109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124,
    125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140,
    141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156,
    157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172,
    173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188,
    189, 190, 191, 192, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207,
    208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223,
    224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255,
    256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271,
    272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287,
    289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304,
    305, 306, 307, 308, 309, 310, 311, 312, 351, 352, 353, 354, 355, 356, 357, 358,
    359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 374,
    375, 376, 377, 378, 379, 380, 381, 382, 383, 385, 386, 387, 388, 389, 390, 391,
    392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407,
    408, 409, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424,
    425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440,
    441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456,
    457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472,
    473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488,
    489, 490, 491, 492, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505,
    506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521,
    522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537,
    538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553,
    554, 555, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570,
    571, 572, 573, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586,
    587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 601, 602, 603,
    604, 605, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619,
    620, 621, 622, 623, 624, 648, 649, 650, 654, 655, 656, 657);

Var
  Ok, Fail, R, R2, I, J, N, A, B, C, X, Y, P, Hmod : LongInt;
  Hdc, Hps, Hbm, Hdc2, Hps2, Hbm2, Hrg1, Hrg2, Hrg3, Hdcm, Hpsm, Hmf, Hdcs, Hpss, Hpal, Hab, Hmq : LongInt;
  Name : Array[0..255] Of Byte;
  Bmi : Array[0..63] Of LongInt;
  Bits : Array[0..4095] Of Byte;
  Pt, Pp : Array[0..15] Of LongInt;
  Rc : Array[0..15] Of LongInt;
  M : Array[0..8] Of LongInt;
  Fm : Array[0..63] Of LongInt;
  Mode : Array[0..15] Of Byte;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function HStr(V : LongInt) : String;
Var S : String; K, D : LongInt;
Begin
  S := '';
  For K := 5 DownTo 0 Do
  Begin
    D := (V Shr (K * 4)) And 15;
    If D < 10 Then S := S + Chr(48 + D) Else S := S + Chr(55 + D);
  End;
  HStr := S;
End;

Function RdL(A : LongInt) : LongInt;
Type PLong = ^LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Type PLong = ^LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrW(A, V : LongInt);
Type PWord = ^Word;
Var P : PWord;
Begin
  P := Pointer(A);
  P^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Type PByte = ^Byte;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure WrB(A, V : LongInt);
Type PByte = ^Byte;
Var P : PByte;
Begin
  P := Pointer(A);
  P^ := V;
End;

Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name[K - 1] := Ord(S[K]);
  Name[Length(S)] := 0;
  Z := LongInt(@Name);
End;

Procedure OutStr(T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do
    If OutLen < 16380 Then
    Begin
      OutBuf[OutLen] := Ord(T[K]);
      Inc(OutLen);
    End;
End;

Procedure Check(What : String; Cond : Boolean);
Begin
  If Cond Then
  Begin
    Inc(Ok);
    OutStr('  OK     ' + What + Chr(13) + Chr(10));
  End
  Else
  Begin
    Inc(Fail);
    OutStr('  ECHEC  ' + What + '  (code ' + IStr(R) + ')' + Chr(13) + Chr(10));
  End;
End;

{ point dans Pp[0..1] }
Function PtA(X1, Y1 : LongInt) : LongInt;
Begin
  Pp[0] := X1; Pp[1] := Y1;
  PtA := LongInt(@Pp);
End;

Function Pel(H, X1, Y1 : LongInt) : LongInt;
Var Q : Array[0..1] Of LongInt;
Begin
  Q[0] := X1; Q[1] := Y1;
  Pel := GpiQueryPel(H, LongInt(@Q));
End;

{ nombre de pels de couleur C dans un rectangle }
Function Count(H, X1, Y1, X2, Y2, C1 : LongInt) : LongInt;
Var Xx, Yy, N1 : LongInt;
Begin
  N1 := 0;
  For Yy := Y1 To Y2 Do
    For Xx := X1 To X2 Do
      If Pel(H, Xx, Yy) = C1 Then Inc(N1);
  Count := N1;
End;

Function GoTo2(H, X1, Y1 : LongInt) : LongInt;
Begin
  GoTo2 := GpiMove(H, PtA(X1, Y1));
End;

Function DrawTo(H, X1, Y1 : LongInt) : LongInt;
Begin
  DrawTo := GpiLine(H, PtA(X1, Y1));
End;

Function BoxTo(H, C1, X1, Y1 : LongInt) : LongInt;
Begin
  BoxTo := GpiBox(H, C1, PtA(X1, Y1), 0, 0);
End;

{ BITMAPINFOHEADER2 (16 octets) }
Function Hdr(Cx, Cy, Bpp : LongInt) : LongInt;
Begin
  For I := 0 To 63 Do Bmi[I] := 0;
  Bmi[0] := 16; Bmi[1] := Cx; Bmi[2] := Cy;
  WrW(LongInt(@Bmi) + 12, 1); WrW(LongInt(@Bmi) + 14, Bpp);
  Hdr := LongInt(@Bmi);
End;

{ espace de presentation sur un bitmap en memoire }
Procedure MemPS(Cx, Cy, Bpp : LongInt; Var Dc, Ps, Bm : LongInt);
Var D1, P1, B1 : LongInt;
Begin
  D1 := DevOpenDC(0, OD_MEMORY, Z('*'), 0, 0, 0);
  P1 := GpiCreatePS(0, D1, 0, PU_PELS Or GPIA_ASSOC Or GPIT_MICRO);
  B1 := GpiCreateBitmap(P1, Hdr(Cx, Cy, Bpp), 0, 0, 0);
  R := GpiSetBitmap(P1, B1);
  Dc := D1; Ps := P1; Bm := B1;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTGPI : essai de PMGPI.DLL');

  { --- ordinaux --- }
  Hmod := 0;
  R := DosQueryModuleHandle(Z('PMGPI'), LongInt(@Hmod));
  N := 0;
  For I := 0 To NOrd - 1 Do
  Begin
    P := 0;
    If DosQueryProcAddr(Hmod, Ords[I], 0, LongInt(@P)) = 0 Then
      If P <> 0 Then Inc(N);
  End;
  Check('572 ordinaux de PMGPI (' + IStr(N) + ')', N = 572);
  P := 0; A := 0;
  R := DosQueryProcAddr(Hmod, 0, Z('GPISETPATTERNSET'), LongInt(@P));
  R2 := DosQueryProcAddr(Hmod, 0, Z('GpiQueryFullFontFileDescs'), LongInt(@A));
  Check('noms GPISETPATTERNSET et GpiQueryFullFontFileDescs', (P <> 0) And (A <> 0));

  { --- contexte memoire et bitmap 24 bits --- }
  MemPS(64, 48, 24, Hdc, Hps, Hbm);
  Check('DevOpenDC (OD_MEMORY), GpiCreatePS, GpiCreateBitmap, GpiSetBitmap', (Hdc <> 0) And (Hps <> 0) And (Hbm <> 0) And
        (R = 0));
  R := DevQueryCaps(Hdc, 4, 2, LongInt(@Rc));
  R2 := GpiQueryBitmapParameters(Hbm, LongInt(@Fm));
  Check('DevQueryCaps (64 x 48), GpiQueryBitmapParameters (24 bits)', (R = 1) And (Rc[0] = 64) And (Rc[1] = 48) And
        (R2 = 1) And ((Fm[2] Shr 16) = 24));
  R := GpiErase(Hps);
  Check('GpiErase : CLR_BACKGROUND partout', (R = 1) And (Pel(Hps, 0, 0) = CLR_BACKGROUND) And (Pel(Hps, 63, 47) = 0));

  { --- lignes --- }
  R := GpiSetColor(Hps, CLR_RED);
  R := GoTo2(Hps, 5, 5); R := DrawTo(Hps, 20, 5);
  Check('GpiMove, GpiLine (rouge)', (R = 1) And (Pel(Hps, 5, 5) = CLR_RED) And (Pel(Hps, 20, 5) = CLR_RED) And
        (Pel(Hps, 12, 6) = 0) And (GpiQueryColor(Hps) = CLR_RED));
  R := GoTo2(Hps, 30, 40); R := DrawTo(Hps, 40, 30);
  Check('ligne en diagonale', (Pel(Hps, 35, 35) = CLR_RED) And (Pel(Hps, 30, 40) = CLR_RED));
  R := GpiSetLineType(Hps, 1);
  R := GoTo2(Hps, 0, 8); R := DrawTo(Hps, 31, 8);
  N := Count(Hps, 0, 8, 31, 8, CLR_RED);
  R := GpiSetLineType(Hps, 0);
  Check('GpiSetLineType (pointille : ' + IStr(N) + ' pels sur 32)', (N >= 14) And (N <= 18));
  R := GpiErase(Hps);
  Pt[0] := 2; Pt[1] := 2; Pt[2] := 20; Pt[3] := 2; Pt[4] := 20; Pt[5] := 10;
  R := GoTo2(Hps, 2, 10);
  R := GpiPolyLine(Hps, 3, LongInt(@Pt));
  R2 := GpiQueryCurrentPosition(Hps, LongInt(@Rc));
  Check('GpiPolyLine, position courante', (R = 1) And (Pel(Hps, 2, 6) = CLR_RED) And (Pel(Hps, 20, 6) = CLR_RED) And
        (Rc[0] = 20) And (Rc[1] = 10));

  { --- boites --- }
  R := GpiErase(Hps);
  R := GpiSetColor(Hps, CLR_BLUE);
  R := GoTo2(Hps, 30, 10); R := BoxTo(Hps, DRO_FILL, 40, 20);
  Check('GpiBox DRO_FILL (coins compris)', (Pel(Hps, 35, 15) = CLR_BLUE) And (Pel(Hps, 40, 20) = CLR_BLUE) And
        (Pel(Hps, 30, 10) = CLR_BLUE) And (Pel(Hps, 41, 15) = 0) And (Pel(Hps, 35, 21) = 0));
  R := GpiSetColor(Hps, CLR_GREEN);
  R := GoTo2(Hps, 2, 2); R := BoxTo(Hps, DRO_OUTLINE, 12, 12);
  Check('GpiBox DRO_OUTLINE', (Pel(Hps, 2, 7) = CLR_GREEN) And (Pel(Hps, 12, 7) = CLR_GREEN) And
        (Pel(Hps, 7, 12) = CLR_GREEN) And (Pel(Hps, 7, 7) = 0));

  { --- arcs --- }
  R := GpiErase(Hps);
  Pt[0] := 1; Pt[1] := 1; Pt[2] := 0; Pt[3] := 0;
  R := GpiSetArcParams(Hps, LongInt(@Pt));
  R := GoTo2(Hps, 20, 20);
  R := GpiFullArc(Hps, DRO_OUTLINE, 10 Shl 16);
  Check('GpiFullArc contour (rayon 10)', (Pel(Hps, 30, 20) = CLR_GREEN) And (Pel(Hps, 20, 30) = CLR_GREEN) And
        (Pel(Hps, 10, 20) = CLR_GREEN) And (Pel(Hps, 20, 20) = 0));
  R := GpiSetColor(Hps, CLR_YELLOW);
  R := GoTo2(Hps, 50, 20);
  R := GpiFullArc(Hps, DRO_FILL, 6 Shl 16);
  Check('GpiFullArc plein', (Pel(Hps, 50, 20) = CLR_YELLOW) And (Pel(Hps, 53, 23) = CLR_YELLOW) And (Pel(Hps, 50, 30) = 0));
  R := GpiErase(Hps);
  R := GoTo2(Hps, 20, 20);
  R := GpiPartialArc(Hps, PtA(20, 20), 10 Shl 16, 0, 90 Shl 16);
  R2 := GpiQueryCurrentPosition(Hps, LongInt(@Rc));
  Check('GpiPartialArc (quart de cercle)', (Pel(Hps, 30, 20) = CLR_YELLOW) And (Pel(Hps, 27, 27) = CLR_YELLOW) And
        (Rc[0] = 20) And (Rc[1] = 30) And (Pel(Hps, 13, 13) = 0));
  R := GpiErase(Hps);
  R := GoTo2(Hps, 10, 20);
  Pt[0] := 20; Pt[1] := 30; Pt[2] := 30; Pt[3] := 20;
  R := GpiPointArc(Hps, LongInt(@Pt));
  R2 := GpiQueryCurrentPosition(Hps, LongInt(@Rc));
  Check('GpiPointArc (trois points)', (R = 1) And (Pel(Hps, 20, 30) = CLR_YELLOW) And (Rc[0] = 30) And (Rc[1] = 20) And
        (Count(Hps, 10, 20, 30, 31, CLR_YELLOW) > 20));
  R := GpiErase(Hps);
  R := GoTo2(Hps, 2, 2);
  Pt[0] := 2; Pt[1] := 40; Pt[2] := 60; Pt[3] := 40; Pt[4] := 60; Pt[5] := 2;
  R := GpiPolySpline(Hps, 3, LongInt(@Pt));
  R2 := GpiQueryCurrentPosition(Hps, LongInt(@Rc));
  Check('GpiPolySpline (Bezier)', (R = 1) And (Rc[0] = 60) And (Rc[1] = 2) And ((Pel(Hps, 31, 30) = CLR_YELLOW) Or (Pel(Hps, 31, 31) = CLR_YELLOW)));
  R := GoTo2(Hps, 2, 2);
  R := GpiPolyFillet(Hps, 3, LongInt(@Pt));
  Check('GpiPolyFillet', (R = 1) And (Count(Hps, 0, 0, 63, 47, CLR_YELLOW) > 60));

  { --- zones et chemins --- }
  R := GpiErase(Hps);
  R := GpiSetColor(Hps, CLR_PINK);
  R := GoTo2(Hps, 5, 5);
  R := GpiBeginArea(Hps, 0);
  Pt[0] := 45; Pt[1] := 5; Pt[2] := 25; Pt[3] := 40;
  R := GpiPolyLine(Hps, 2, LongInt(@Pt));
  R2 := GpiEndArea(Hps);
  Check('GpiBeginArea, GpiEndArea (triangle plein)', (R2 = 1) And (Pel(Hps, 25, 15) = CLR_PINK) And
        (Pel(Hps, 25, 41) = 0) And (Pel(Hps, 5, 30) = 0));
  R := GpiErase(Hps);
  R := GoTo2(Hps, 10, 10);
  R := GpiBeginPath(Hps, 1);
  Pt[0] := 50; Pt[1] := 10; Pt[2] := 50; Pt[3] := 40; Pt[4] := 10; Pt[5] := 40;
  R := GpiPolyLine(Hps, 3, LongInt(@Pt));
  R := GpiCloseFigure(Hps);
  R := GpiEndPath(Hps);
  R2 := GpiFillPath(Hps, 1, 0);
  Check('GpiBeginPath, GpiCloseFigure, GpiEndPath, GpiFillPath', (R2 = 1) And (Pel(Hps, 30, 25) = CLR_PINK) And
        (Pel(Hps, 5, 5) = 0));
  R := GoTo2(Hps, 10, 10);
  R := GpiBeginPath(Hps, 1);
  R := GpiPolyLine(Hps, 3, LongInt(@Pt));
  R := GpiCloseFigure(Hps);
  R := GpiEndPath(Hps);
  Hrg1 := GpiPathToRegion(Hps, 1, 0);
  Check('GpiPathToRegion, GpiPtInRegion', (Hrg1 <> 0) And (GpiPtInRegion(Hps, Hrg1, PtA(30, 25)) = 2) And
        (GpiPtInRegion(Hps, Hrg1, PtA(55, 25)) = 1));
  R := GpiDestroyRegion(Hps, Hrg1);

  { --- texte, marqueurs, images --- }
  R := GpiErase(Hps);
  R := GpiSetColor(Hps, CLR_NEUTRAL);
  R := GpiCharStringAt(Hps, PtA(2, 10), 2, Z('AB'));
  N := Count(Hps, 2, 6, 17, 21, CLR_NEUTRAL);
  R2 := GpiQueryCurrentPosition(Hps, LongInt(@Rc));
  Check('GpiCharStringAt (' + IStr(N) + ' pels noirs, position ' + IStr(Rc[0]) + ')', (N > 20) And (Rc[0] = 18) And
        (Rc[1] = 10));
  R := GpiQueryTextBox(Hps, 2, Z('AB'), 5, LongInt(@Fm));
  Check('GpiQueryTextBox (concatenation 16, hauteur 12)', (R = 1) And (Fm[8] = 16) And (Fm[9] = 0) And (Fm[1] = 12) And
        (Fm[3] = -4));
  R := GpiErase(Hps);
  Pt[0] := 16 Shl 16; Pt[1] := 32 Shl 16;
  R := GpiSetCharBox(Hps, LongInt(@Pt));
  R := GpiCharStringAt(Hps, PtA(2, 10), 1, Z('H'));
  N := Count(Hps, 2, 2, 19, 34, CLR_NEUTRAL);
  Check('GpiSetCharBox 16 x 32 (' + IStr(N) + ' pels)', N > 80);
  R := GpiErase(Hps);
  R := GpiSetMarker(Hps, 8);
  R := GpiMarker(Hps, PtA(20, 20));
  Check('GpiMarker (carre plein)', (Pel(Hps, 20, 20) = CLR_NEUTRAL) And (Pel(Hps, 22, 22) = CLR_NEUTRAL) And
        (Pel(Hps, 30, 30) = 0));
  R := GpiErase(Hps);
  Bits[0] := $F0; Bits[1] := $0F;
  Rc[0] := 8; Rc[1] := 2;
  R := GoTo2(Hps, 10, 10);
  R := GpiImage(Hps, 0, LongInt(@Rc), 2, LongInt(@Bits));
  Check('GpiImage (8 x 2)', (Pel(Hps, 10, 10) = CLR_NEUTRAL) And (Pel(Hps, 14, 10) = 0) And (Pel(Hps, 14, 9) = CLR_NEUTRAL));

  { --- pels, melanges --- }
  R := GpiErase(Hps);
  R := GpiSetColor(Hps, CLR_RED);
  R := GpiSetPel(Hps, PtA(3, 3));
  A := Pel(Hps, 3, 3);
  R := GpiSetMix(Hps, FM_XOR);
  R := GpiSetPel(Hps, PtA(3, 3));
  B := Pel(Hps, 3, 3);
  R := GpiSetPel(Hps, PtA(3, 3));
  C := Pel(Hps, 3, 3);
  R := GpiSetMix(Hps, FM_OVERPAINT);
  Check('GpiSetPel, GpiQueryPel, GpiSetMix FM_XOR (deux fois)', (A = CLR_RED) And (B <> CLR_RED) And (C = CLR_RED));

  { --- bits du bitmap --- }
  R := GpiErase(Hps);
  R := GpiSetPel(Hps, PtA(1, 0));
  R := GpiQueryBitmapBits(Hps, 0, 1, LongInt(@Bits), Hdr(64, 48, 24));
  Check('GpiQueryBitmapBits (24 bits : pel 1 rouge)', (R = 1) And (Bits[3] = 0) And (Bits[4] = 0) And (Bits[5] = 255) And
        (Bits[0] = 255));
  For I := 0 To 63 Do Bits[I] := $12;
  R := Hdr(64, 48, 4);
  Bmi[4] := $000000; Bmi[5] := $0000FF; Bmi[6] := $00FF00;
  R := GpiSetBitmapBits(Hps, 46, 1, LongInt(@Bits), LongInt(@Bmi));
  Check('GpiSetBitmapBits (4 bits, table de couleurs)', (R = 1) And (Pel(Hps, 0, 46) = CLR_BLUE) And
        (Pel(Hps, 1, 46) = CLR_GREEN));

  { --- regions et decoupage --- }
  Rc[0] := 0; Rc[1] := 0; Rc[2] := 20; Rc[3] := 20;
  Hrg1 := GpiCreateRegion(Hps, 1, LongInt(@Rc));
  Rc[0] := 10; Rc[1] := 10; Rc[2] := 30; Rc[3] := 30;
  Hrg2 := GpiCreateRegion(Hps, 1, LongInt(@Rc));
  Hrg3 := GpiCreateRegion(Hps, 0, 0);
  R := GpiCombineRegion(Hps, Hrg3, Hrg1, Hrg2, 1);
  R2 := GpiQueryRegionBox(Hps, Hrg3, LongInt(@Fm));
  Check('GpiCreateRegion, GpiCombineRegion OU, GpiQueryRegionBox', (R = 3) And (Fm[0] = 0) And (Fm[1] = 0) And
        (Fm[2] = 30) And (Fm[3] = 30));
  R := GpiCombineRegion(Hps, Hrg3, Hrg1, Hrg2, 6);
  R2 := GpiQueryRegionBox(Hps, Hrg3, LongInt(@Fm));
  Check('GpiCombineRegion ET (rectangle 10-20)', (R = 2) And (Fm[0] = 10) And (Fm[2] = 20));
  R := GpiCombineRegion(Hps, Hrg3, Hrg1, Hrg2, 7);
  Check('GpiCombineRegion DIFF, GpiPtInRegion', (R = 3) And (GpiPtInRegion(Hps, Hrg3, PtA(5, 5)) = 2) And
        (GpiPtInRegion(Hps, Hrg3, PtA(15, 15)) = 1));
  Rc[0] := 0; Rc[1] := 0; Rc[2] := 5; Rc[3] := 5;
  Check('GpiRectInRegion, GpiEqualRegion', (GpiRectInRegion(Hps, Hrg1, LongInt(@Rc)) = 3) And
        (GpiEqualRegion(Hps, Hrg1, Hrg1) = 2) And (GpiEqualRegion(Hps, Hrg1, Hrg2) = 1));
  R := GpiOffsetRegion(Hps, Hrg1, PtA(5, 5));
  R2 := GpiQueryRegionBox(Hps, Hrg1, LongInt(@Fm));
  Fm[10] := 1; Fm[11] := 10; Fm[12] := 0; Fm[13] := 0;
  A := GpiQueryRegionRects(Hps, Hrg3, 0, LongInt(@Fm) + 40, LongInt(@Bits));
  Check('GpiOffsetRegion, GpiQueryRegionRects (' + IStr(Fm[12]) + ')', (Fm[0] = 5) And (Fm[2] = 25) And (A = 1) And
        (Fm[12] >= 2));
  R := GpiErase(Hps);
  R := GpiSetClipRegion(Hps, Hrg2, 0);
  R := GpiSetColor(Hps, CLR_CYAN);
  R := GoTo2(Hps, 0, 0); R := BoxTo(Hps, DRO_FILL, 63, 47);
  R2 := GpiSetClipRegion(Hps, 0, 0);
  Check('GpiSetClipRegion : dessin decoupe', (Pel(Hps, 15, 15) = CLR_CYAN) And (Pel(Hps, 5, 5) = 0) And
        (Pel(Hps, 40, 40) = 0) And (GpiPtVisible(Hps, PtA(40, 40)) = 2));
  R := GpiErase(Hps);
  R := GpiPaintRegion(Hps, Hrg2);
  Check('GpiPaintRegion', (Pel(Hps, 15, 15) = CLR_CYAN) And (Pel(Hps, 31, 31) = 0));
  R := GpiDestroyRegion(Hps, Hrg1); R := GpiDestroyRegion(Hps, Hrg2); R := GpiDestroyRegion(Hps, Hrg3);

  { --- transformations --- }
  For I := 0 To 8 Do M[I] := 0;
  M[0] := 2 Shl 16; M[4] := 2 Shl 16; M[6] := 10; M[7] := 5; M[8] := 1;
  R := GpiSetModelTransformMatrix(Hps, 9, LongInt(@M), 0);
  Pt[0] := 3; Pt[1] := 4;
  R2 := GpiConvert(Hps, 1, 5, 1, LongInt(@Pt));
  Check('GpiSetModelTransformMatrix, GpiConvert monde -> peripherique (' + IStr(Pt[0]) + ', ' + IStr(Pt[1]) + ')',
        (R = 1) And (Pt[0] = 16) And (Pt[1] = 13));
  R := GpiConvert(Hps, 5, 1, 1, LongInt(@Pt));
  Check('GpiConvert inverse (' + IStr(Pt[0]) + ', ' + IStr(Pt[1]) + ')', (Pt[0] = 3) And (Pt[1] = 4));
  R := GpiRotate(Hps, LongInt(@M), 0, 90 Shl 16, 0);
  R := GpiSetModelTransformMatrix(Hps, 9, LongInt(@M), 0);
  Pt[0] := 10; Pt[1] := 0;
  R2 := GpiConvert(Hps, 1, 5, 1, LongInt(@Pt));
  Check('GpiRotate 90 degres (' + IStr(Pt[0]) + ', ' + IStr(Pt[1]) + ')', (Pt[0] = 0) And (Pt[1] = 10));
  Pt[2] := 3 Shl 16; Pt[3] := 3 Shl 16;
  R := GpiScale(Hps, LongInt(@M), 0, LongInt(@Pt) + 8, 0);
  R := GpiTranslate(Hps, LongInt(@M), 1, PtA(1, 2));
  R := GpiSetModelTransformMatrix(Hps, 9, LongInt(@M), 0);
  Pt[0] := 2; Pt[1] := 2;
  R2 := GpiConvert(Hps, 1, 5, 1, LongInt(@Pt));
  Check('GpiScale, GpiTranslate (' + IStr(Pt[0]) + ', ' + IStr(Pt[1]) + ')', (Pt[0] = 7) And (Pt[1] = 8));
  R := GpiSetModelTransformMatrix(Hps, 0, 0, 0);
  R := GpiErase(Hps);
  Hdc2 := DevOpenDC(0, OD_MEMORY, Z('*'), 0, 0, 0);
  Hps2 := GpiCreatePS(0, Hdc2, 0, PU_LOMETRIC Or GPIA_ASSOC);
  Pt[0] := 1000; Pt[1] := 500;
  R := GpiConvert(Hps2, 1, 5, 1, LongInt(@Pt));
  A := GpiQueryPS(Hps2, LongInt(@Rc));
  Check('PU_LOMETRIC : 100 mm -> ' + IStr(Pt[0]) + ' pels, GpiQueryPS', (Pt[0] >= 377) And (Pt[0] <= 379) And
        (Pt[1] >= 188) And (Pt[1] <= 190) And ((A And $1C) = PU_LOMETRIC));
  R := GpiDestroyPS(Hps2); R := DevCloseDC(Hdc2);

  { --- transferts de blocs --- }
  MemPS(16, 16, 24, Hdc2, Hps2, Hbm2);
  R := GpiErase(Hps2);
  R := GpiSetColor(Hps2, CLR_RED);
  R := GoTo2(Hps2, 0, 0); R := BoxTo(Hps2, DRO_FILL, 7, 15);
  R := GpiErase(Hps);
  Pt[0] := 20; Pt[1] := 20; Pt[2] := 36; Pt[3] := 36; Pt[4] := 0; Pt[5] := 0;
  R := GpiBitBlt(Hps, Hps2, 3, LongInt(@Pt), ROP_SRCCOPY, 0);
  Check('GpiBitBlt ROP_SRCCOPY', (R = 1) And (Pel(Hps, 22, 22) = CLR_RED) And (Pel(Hps, 30, 22) = 0) And
        (Pel(Hps, 37, 22) = 0));
  R := GpiBitBlt(Hps, 0, 2, LongInt(@Pt), ROP_DSTINVERT, 0);
  Check('GpiBitBlt ROP_DSTINVERT', (Pel(Hps, 30, 22) = CLR_NEUTRAL) And (Pel(Hps, 22, 22) = CLR_CYAN));
  R := GpiSetColor(Hps, CLR_GREEN);
  R := GpiBitBlt(Hps, 0, 2, LongInt(@Pt), ROP_PATCOPY, 0);
  Check('GpiBitBlt ROP_PATCOPY', Pel(Hps, 25, 25) = CLR_GREEN);
  R := GpiErase(Hps);
  Pt[0] := 0; Pt[1] := 0; Pt[2] := 32; Pt[3] := 32; Pt[4] := 0; Pt[5] := 0; Pt[6] := 16; Pt[7] := 16;
  R := GpiWCBitBlt(Hps, Hbm2, 4, LongInt(@Pt), ROP_SRCCOPY, 0);
  Check('GpiWCBitBlt etire (16 -> 32)', (R = 1) And (Pel(Hps, 14, 5) = CLR_RED) And (Pel(Hps, 18, 5) = 0));
  R := GpiSetBitmap(Hps2, 0);
  R2 := GpiDeleteBitmap(Hbm2);
  Check('GpiSetBitmap 0 (ancien rendu), GpiDeleteBitmap', (R = Hbm2) And (R2 = 1));
  R := GpiDestroyPS(Hps2); R := DevCloseDC(Hdc2);
  MemPS(8, 8, 1, Hdc2, Hps2, Hbm2);
  R := GpiErase(Hps2);
  R := GpiSetColor(Hps2, CLR_BLACK);
  R := GoTo2(Hps2, 0, 0); R := BoxTo(Hps2, DRO_FILL, 3, 7);
  R := GpiErase(Hps);
  R := GpiSetColor(Hps, CLR_BLUE); R := GpiSetBackColor(Hps, CLR_YELLOW);
  Pt[0] := 0; Pt[1] := 0; Pt[2] := 8; Pt[3] := 8; Pt[4] := 0; Pt[5] := 0;
  R := GpiBitBlt(Hps, Hps2, 3, LongInt(@Pt), ROP_SRCCOPY, 0);
  Check('bitmap monochrome -> couleur (1 : premier plan, 0 : fond)', (Pel(Hps, 1, 1) = CLR_YELLOW) And
        (Pel(Hps, 6, 1) = CLR_BLUE));
  R := GpiSetBitmap(Hps2, 0); R := GpiDeleteBitmap(Hbm2); R := GpiDestroyPS(Hps2); R := DevCloseDC(Hdc2);

  { --- couleurs --- }
  R := GpiSetBackColor(Hps, CLR_BACKGROUND);
  Pt[0] := $123456;
  R := GpiCreateLogColorTable(Hps, 0, 2, 16, 1, LongInt(@Pt));
  R2 := GpiSetColor(Hps, 16);
  A := GpiSetPel(Hps, PtA(1, 1));
  R2 := GpiQueryBitmapBits(Hps, 1, 1, LongInt(@Bits), Hdr(64, 48, 24));
  Check('GpiCreateLogColorTable (LCOLF_CONSECRGB), GpiQueryRGBColor', (R = 1) And
        (GpiQueryRGBColor(Hps, 0, 16) = $123456) And (Bits[3] = $56) And (Bits[4] = $34) And (Bits[5] = $12));
  R := GpiCreateLogColorTable(Hps, 0, 3, 0, 0, 0);
  R2 := GpiSetColor(Hps, $00FF8000);
  A := GpiSetPel(Hps, PtA(2, 2));
  Check('mode RVB (LCOLF_RGB) : GpiQueryPel rend la couleur', (R = 1) And (Pel(Hps, 2, 2) = $FF8000));
  R := GpiCreateLogColorTable(Hps, 1, 0, 0, 0, 0);
  Pt[0] := $FF0000; Pt[1] := $00FF00; Pt[2] := $0000FF;
  Hpal := GpiCreatePalette(0, 0, 0, 3, LongInt(@Pt));
  R := GpiSelectPalette(Hps, Hpal);
  R2 := GpiQueryPaletteInfo(Hpal, Hps, 0, 0, 3, LongInt(@Rc));
  Check('GpiCreatePalette, GpiSelectPalette, GpiQueryPaletteInfo', (Hpal <> 0) And (R = 0) And (R2 = 3) And
        (Rc[1] = $00FF00) And (GpiQueryRGBColor(Hps, 0, 2) = $0000FF));
  R := GpiSelectPalette(Hps, 0); R2 := GpiDeletePalette(Hpal);
  Check('GpiDeletePalette', (R = Hpal) And (R2 = 1));

  { --- polices --- }
  Fm[0] := 0;
  N := 5;
  R := GpiQueryFonts(Hps, 1, 0, LongInt(@N), 208, LongInt(@Bits));
  Check('GpiQueryFonts (' + IStr(N) + ' polices)', (R = 0) And (N = 2));
  For I := 0 To 13 Do Fm[I] := 0;
  WrW(LongInt(@Fm), 56);
  R := Z('System VIO');
  For I := 0 To 10 Do WrB(LongInt(@Fm) + 8 + I, Name[I]);
  R := GpiCreateLogFont(Hps, Z('F1'), 1, LongInt(@Fm));
  R2 := GpiQueryFontMetrics(Hps, 208, LongInt(@Bits));
  Check('GpiCreateLogFont (FONT_MATCH), GpiQueryNumberSetIds, GpiQueryFontMetrics', (R = 2) And
        (GpiQueryNumberSetIds(Hps) = 1) And (R2 = 1) And (RdL(LongInt(@Bits) + 68) = 16) And (Bits[0] = Ord('S')));
  Check('GpiDeleteSetId', (GpiDeleteSetId(Hps, 1) = 1) And (GpiQueryNumberSetIds(Hps) = 0));

  { --- segments, correlation, limites --- }
  R := GpiErase(Hps);
  R := GpiSetDrawingMode(Hps, 2);
  R := GpiOpenSegment(Hps, 7);
  R := GpiSetColor(Hps, CLR_RED);
  R := GpiSetTag(Hps, 99);
  R := GpiLabel(Hps, 5);
  R := GoTo2(Hps, 10, 10); R := BoxTo(Hps, DRO_FILL, 20, 20);
  N := GpiQueryElementPointer(Hps);
  R := GpiSetElementPointerAtLabel(Hps, 5);
  A := GpiQueryElementPointer(Hps);
  R2 := GpiCloseSegment(Hps);
  Check('DM_RETAIN : segment enregistre sans dessin (' + IStr(N) + ' elements)', (R2 = 1) And (N = 5) And (A = 3) And
        (Pel(Hps, 15, 15) = 0));
  R := GpiSetDrawingMode(Hps, 1);
  R := GpiDrawSegment(Hps, 7);
  Check('GpiDrawSegment', (R = 1) And (Pel(Hps, 15, 15) = CLR_RED));
  R := GpiErase(Hps);
  R := GpiDrawChain(Hps);
  N := GpiQuerySegmentNames(Hps, 1, 100, 10, LongInt(@Rc));
  Check('GpiDrawChain, GpiQuerySegmentNames', (Pel(Hps, 15, 15) = CLR_RED) And (N = 1) And (Rc[0] = 7));
  R := GpiCorrelateChain(Hps, 1, PtA(15, 15), 4, 1, LongInt(@Fm));
  R2 := GpiCorrelateChain(Hps, 1, PtA(40, 40), 4, 1, LongInt(@Fm) + 32);
  Check('GpiCorrelateChain (segment 7, balise 99)', (R >= 1) And (Fm[0] = 7) And (Fm[1] = 99) And (R2 = 0));
  R := GpiSetDrawControl(Hps, 3, 1);
  R := GoTo2(Hps, 10, 12); R := DrawTo(Hps, 25, 30);
  R2 := GpiQueryBoundaryData(Hps, LongInt(@Fm));
  Check('DCTL_BOUNDARY, GpiQueryBoundaryData', (R2 = 1) And (Fm[0] = 10) And (Fm[1] = 12) And (Fm[2] = 25) And
        (Fm[3] = 30));
  R := GpiSetDrawControl(Hps, 3, 0);
  R := GpiDeleteSegment(Hps, 7);
  Check('GpiDeleteSegment', (R = 1) And (GpiQuerySegmentNames(Hps, 1, 100, 10, LongInt(@Rc)) = 0));

  { --- metafichier --- }
  Hdcm := DevOpenDC(0, OD_METAFILE, Z('*'), 0, 0, 0);
  Hpsm := GpiCreatePS(0, Hdcm, 0, PU_PELS Or GPIA_ASSOC);
  R := GpiSetColor(Hpsm, CLR_BROWN);
  R := GoTo2(Hpsm, 40, 30); R := BoxTo(Hpsm, DRO_FILL, 50, 40);
  R := GpiAssociate(Hpsm, 0);
  R := GpiDestroyPS(Hpsm);
  Hmf := DevCloseDC(Hdcm);
  R := GpiErase(Hps);
  R2 := GpiPlayMetaFile(Hps, Hmf, 0, 0, 0, 0, 0);
  Check('OD_METAFILE, DevCloseDC (HMF), GpiPlayMetaFile', (Hmf <> 0) And (GpiQueryMetaFileLength(Hmf) > 12) And
        (R2 = 1) And (Pel(Hps, 45, 35) = CLR_BROWN));
  A := DosDelete(Z('D:\ESSAI.MET'));
  R := GpiSaveMetaFile(Hmf, Z('D:\ESSAI.MET'));
  Hmf := GpiLoadMetaFile(0, Z('D:\ESSAI.MET'));
  R2 := GpiErase(Hps);
  R2 := GpiPlayMetaFile(Hps, Hmf, 0, 0, 0, 0, 0);
  Check('GpiSaveMetaFile, GpiLoadMetaFile', (R = 1) And (Hmf <> 0) And (Pel(Hps, 45, 35) = CLR_BROWN) And
        (GpiDeleteMetaFile(Hmf) = 1));
  A := DosDelete(Z('D:\ESSAI.MET'));

  { --- remplissage par diffusion, attributs --- }
  R := GpiErase(Hps);
  R := GpiSetColor(Hps, CLR_NEUTRAL);
  R := GoTo2(Hps, 5, 5); R := BoxTo(Hps, DRO_OUTLINE, 25, 25);
  R := GpiSetColor(Hps, CLR_RED);
  R := GoTo2(Hps, 15, 15);
  R := GpiFloodFill(Hps, 0, CLR_NEUTRAL);
  Check('GpiFloodFill FF_BOUNDARY', (Pel(Hps, 10, 10) = CLR_RED) And (Pel(Hps, 5, 10) = CLR_NEUTRAL) And
        (Pel(Hps, 30, 30) = 0));
  R := GpiSetAttrMode(Hps, 0);
  R := GpiSetColor(Hps, CLR_BLUE);
  R := GpiSetColor(Hps, CLR_GREEN);
  R := GpiPop(Hps, 1);
  A := GpiQueryColor(Hps);
  R := GpiSetAttrMode(Hps, 1);
  Check('AM_PRESERVE, GpiPop', A = CLR_BLUE);
  N := GpiSavePS(Hps);
  R := GpiSetColor(Hps, CLR_PINK);
  R2 := GpiRestorePS(Hps, -1);
  Check('GpiSavePS, GpiRestorePS', (N = 1) And (R2 = 1) And (GpiQueryColor(Hps) = CLR_BLUE));
  For I := 0 To 7 Do Fm[I] := 0;
  Fm[0] := CLR_CYAN; Fm[3] := 3 Shl 16;
  R := GpiSetAttrs(Hps, 1, 1 Or $10, 0, LongInt(@Fm));
  For I := 0 To 7 Do Fm[I] := 0;
  R2 := GpiQueryAttrs(Hps, 1, 1 Or $10, LongInt(@Fm));
  Check('GpiSetAttrs, GpiQueryAttrs (LINEBUNDLE)', (R = 1) And (R2 = $11) And (Fm[0] = CLR_CYAN) And (Fm[3] = 3 Shl 16));
  R := GpiDestroyPS(Hps);
  R2 := GpiDeleteBitmap(Hbm);
  Check('GpiDestroyPS, DevCloseDC', (R = 1) And (DevCloseDC(Hdc) = 1));

  { --- ecran 640 x 480 x 16 couleurs --- }
  For I := 0 To 15 Do Mode[I] := 0;
  WrW(LongInt(@Mode), 12); Mode[2] := 3; Mode[3] := 4; WrW(LongInt(@Mode) + 8, 640); WrW(LongInt(@Mode) + 10, 480);
  A := VioSetMode(LongInt(@Mode), 0);
  Hdcs := DevOpenDC(0, OD_DIRECT, Z('*'), 0, 0, 0);
  Hpss := GpiCreatePS(0, Hdcs, 0, PU_PELS Or GPIA_ASSOC);
  R := DevQueryCaps(Hdcs, 4, 2, LongInt(@Rc));
  R2 := GpiErase(Hpss);
  R := GpiSetColor(Hpss, CLR_DARKBLUE);
  R := GoTo2(Hpss, 0, 440); R := BoxTo(Hpss, DRO_FILL, 639, 479);
  R := GpiSetColor(Hpss, CLR_WHITE);
  R := GpiCharStringAt(Hpss, PtA(16, 454), 33, Z('OS/2-0 : PMGPI en 640 x 480 x 16'));
  For I := 0 To 5 Do
  Begin
    R := GpiSetColor(Hpss, I + 1);
    R := GoTo2(Hpss, 40 + I * 96, 300);
    R := BoxTo(Hpss, DRO_FILL, 110 + I * 96, 400);
  End;
  Pt[0] := 1; Pt[1] := 1; Pt[2] := 0; Pt[3] := 0;
  R := GpiSetArcParams(Hpss, LongInt(@Pt));
  For I := 0 To 3 Do
  Begin
    R := GpiSetColor(Hpss, 9 + I);
    R := GoTo2(Hpss, 120 + I * 130, 170);
    R := GpiFullArc(Hpss, DRO_OUTLINEFILL, (40 + I * 5) Shl 16);
  End;
  R := GpiSetColor(Hpss, CLR_NEUTRAL);
  For I := 0 To 15 Do
  Begin
    R := GoTo2(Hpss, 20, 20 + I * 4);
    R := DrawTo(Hpss, 620, 80 - I * 4);
  End;
  R := GpiSetColor(Hpss, CLR_RED);
  R := GpiCharStringAt(Hpss, PtA(240, 100), 21, Z('Cercles et rectangles'));
  A := Pel(Hpss, 75, 350); B := Pel(Hpss, 120, 170);
  Check('ecran 640 x 480 (' + IStr(Rc[0]) + ' x ' + IStr(Rc[1]) + ', pels ' + IStr(A) + ' ' + IStr(B) + ')', (Rc[0] = 640) And (Rc[1] = 480) And
        (A = CLR_BLUE) And (B = 9));
  R := DosSleep(3000);
  R := GpiDestroyPS(Hpss); R := DevCloseDC(Hdcs);
  For I := 0 To 15 Do Mode[I] := 0;
  WrW(LongInt(@Mode), 8); Mode[2] := 1; Mode[3] := 4; WrW(LongInt(@Mode) + 4, 80); WrW(LongInt(@Mode) + 6, 25);
  R := VioSetMode(LongInt(@Mode), 0);

  { --- espace de presentation de PMWIN : ecran graphique de PM (ou ecran
    texte avec PMMODE=TEXTE) --- }
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Hpss := WinGetScreenPS(1);
  R := GpiSetColor(Hpss, CLR_BLUE);
  R := GoTo2(Hpss, 80, 80); R := BoxTo(Hpss, DRO_FILL, 159, 111);
  If WinQuerySysValue(1, 21) = 480 Then
  Begin
    R := GpiSetColor(Hpss, CLR_YELLOW);
    R := GpiCharStringAt(Hpss, PtA(320, 200), 3, Z('GPI'));
    A := Pel(Hpss, 100, 100);
    N := Count(Hpss, 320, 190, 343, 217, CLR_YELLOW);
    Check('GpiBox et texte dans un espace de PMWIN (ecran graphique : ' + IStr(N) + ' pels jaunes)',
          (A = CLR_BLUE) And (N > 20));
  End
  Else
  Begin
    A := RdB($B8000 + ((24 - 96 Div 16) * 80 + 15) * 2 + 1);
    R := GpiSetColor(Hpss, CLR_YELLOW);
    R := GpiCharStringAt(Hpss, PtA(320, 200), 3, Z('GPI'));
    B := RdB($B8000 + (12 * 80 + 40) * 2);
    Check('GpiBox et texte dans un espace de PMWIN (cellules : fond ' + IStr((A Shr 4) And 7) + ')',
          (((A Shr 4) And 7) = 1) And (B = Ord('G')));
  End;
  R := WinReleasePS(Hpss);
  R := WinDestroyMsgQueue(Hmq);
  R := WinTerminate(Hab);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTGPI : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
