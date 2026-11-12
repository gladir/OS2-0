{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMGPI.DLL de OS/2-0 (interface de
                programmation graphique GPI et contextes de
                peripheriques Dev* de Presentation Manager).
}

Library PMGPI;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC PMGPI.PAS   (produit PMGPI.DLL)

  PMGPI.DLL est l'interface graphique de Presentation Manager (GPI) :
  contextes de peripheriques (DevOpenDC...), espaces de presentation,
  transformations (modele, vue, vue par defaut, page -> peripherique),
  attributs (couleurs, melanges, lignes, caracteres, marqueurs, motifs),
  primitives (lignes, boites, arcs, filets, splines de Bezier, marqueurs,
  texte, images), zones et chemins, regions et decoupage, bitmaps
  (GpiCreateBitmap, GpiBitBlt...), tables de couleurs et palettes,
  polices logiques, segments retenus et elements, correlation, donnees
  de limites, metafichiers.

  Cibles du dessin :
    - bitmap en memoire (contexte OD_MEMORY, GpiSetBitmap) de 1, 4, 8
      ou 24 bits par pel ;
    - ecran (DevOpenDC OD_DIRECT ou OD_INFO "DISPLAY", WinOpenWindowDC,
      espaces de presentation de PMWIN.DLL : WinGetPS, WinBeginPaint) :
      en mode graphique du VGA (VioSetMode : 640 x 480 x 16, 640 x 350,
      640 x 200, 320 x 200 x 16 ou 256 couleurs, 640 x 480 x 2), les pels
      sont ecrits en 000A0000h ; en mode texte, l'ecran est vu en
      640 x 400 pels et une cellule de 8 x 16 pels prend la couleur de
      fond du dessin (le texte s'ecrit dans les cellules) ;
    - metafichier (OD_METAFILE) : les appels sont enregistres.

  Coordonnees : comme dans OS/2, l'origine est en bas a gauche et y croit
  vers le haut ; les matrices MATRIXLF ont des elements FIXED (16.16).
  Les courbes (arcs, filets, splines) sont approchees par des lignes
  dans l'espace du monde puis transformees. La police est celle du VGA
  (8 x 16, VioGetFont), mise a l'echelle de la boite des caracteres.

  Segments et metafichiers : les appels de dessin et d'attributs sont
  enregistres comme elements (type ETYPE_* = 47000000h + numero de
  l'appel, donnees = parametres et tableaux) ; GpiDrawSegment, GpiDraw-
  Chain et GpiPlayMetaFile les rejouent. Fichier de metafichier :
  'OS20MF01', longueur, elements.

  Handles : HDC 4447xxxxh (les DC de fenetre de PMWIN 4443xxxxh sont
  acceptes), HPS 4750xxxxh (ceux de PMWIN 5053xxxxh sont acceptes),
  HBITMAP 4742xxxxh, HRGN 4752xxxxh, HMF 474Dxxxxh, HPAL 474Cxxxxh.

  Limites : pas de GOCA (GpiPutData et GpiGetData transportent les
  elements du format ci-dessus), pas d'impression (OD_QUEUED est un
  contexte sans sortie), une seule police (System VIO / System
  Monospaced), largeur geometrique des lignes approchee. Les fonctions
  Mt*, Segs*, Fmt* et Dsp* (internes a OS/2) sont decrites avec leur
  code. Les points d'entree 16 bits (ordinaux 1 a 312) ont le meme effet
  que les points d'entree 32 bits (351 a 657) ; un nom exporte deux fois
  l'est en majuscules a l'ordinal bas. }

{ ==================================================================== }
{ Partie 1 - Constantes, types, variables, utilitaires                  }
{ ==================================================================== }

Const
  MaxDC = 32; MaxGPS = 48; MaxGBmp = 96; MaxRgn = 128; MaxMeta = 16; MaxPal = 16;
  MaxSeg = 128; MaxLcid = 16; MaxClipR = 64; MaxPrev = 8;
  ArenaSize = 262144;
  { types de DC }
  OD_QUEUED = 2; OD_DIRECT = 5; OD_INFO = 6; OD_METAFILE = 3; OD_METAFILE_NOQUERY = 7; OD_MEMORY = 8;
  DCT_WINDOW = 20; DCT_PMPS = 21;
  { cibles du dessin }
  TG_NONE = 0; TG_BMP = 1; TG_PLANAR = 2; TG_LINEAR = 3; TG_TEXT = 4;
  { erreurs (gravite 4) }
  PMERR_INV_HPS = $207F; PMERR_INV_HDC = $2075; PMERR_INV_HBITMAP = $2079; PMERR_INV_HRGN = $208E;
  PMERR_INV_PARAMETER = $1208; PMERR_INV_COORDINATE = $205B; PMERR_INSUFFICIENT_MEMORY = $203E;
  PMERR_INV_LENGTH = $2092; PMERR_INV_SEG = $20B3; PMERR_INV_HMF = $2088; PMERR_INV_HPAL = $20B7;
  PMERR_BITMAP_IS_SELECTED = $2021; PMERR_INV_IN_AREA = $208A; PMERR_INV_IN_PATH = $208B;
  PMERR_PATH_UNKNOWN = $20D3; PMERR_FONT_NOT_LOADED = $2061; PMERR_INV_LOCAL_ID = $20A3;
  PMERR_NO_BITMAP_SELECTED = $2109; PMERR_INV_METAFILE = $20A9;
  { couleurs }
  CLR_FALSE = -5; CLR_TRUE = -4; CLR_DEFAULT = -3; CLR_WHITE = -2; CLR_BLACK = -1;
  CLR_BACKGROUND = 0; CLR_NEUTRAL = 7;
  { melanges }
  FM_DEFAULT = 0; FM_OR = 1; FM_OVERPAINT = 2; FM_XOR = 4; FM_LEAVEALONE = 5; FM_AND = 6;
  { mode de dessin }
  DM_DRAW = 1; DM_RETAIN = 2; DM_DRAWANDRETAIN = 3;
  { types de primitives }
  PRIM_LINE = 1; PRIM_CHAR = 2; PRIM_MARKER = 3; PRIM_AREA = 4; PRIM_IMAGE = 5;
  { elements enregistres : ETYPE_BASE + numero de l'appel }
  ETYPE_BASE = $47000000;
  E_SETCOLOR = 1; E_SETBACKCOLOR = 2; E_SETMIX = 3; E_SETBACKMIX = 4; E_SETLINETYPE = 5;
  E_SETLINEWIDTH = 6; E_SETLINEWIDTHGEOM = 7; E_SETLINEEND = 8; E_SETLINEJOIN = 9;
  E_SETCURPOS = 10; E_MOVE = 11; E_LINE = 12; E_POLYLINE = 13; E_BOX = 14; E_SETARCPARAMS = 15;
  E_POINTARC = 16; E_FULLARC = 17; E_PARTIALARC = 18; E_POLYFILLET = 19; E_POLYFILLETSHARP = 20;
  E_POLYSPLINE = 21; E_SETPATTERNSET = 22; E_SETPATTERN = 23; E_SETPATTERNREF = 24;
  E_BEGINAREA = 25; E_ENDAREA = 26; E_SETCHARSET = 27; E_SETCHARBOX = 28; E_SETCHARANGLE = 29;
  E_SETCHARSHEAR = 30; E_SETCHARDIR = 31; E_SETCHARMODE = 32; E_CHARSTRING = 33;
  E_CHARSTRINGPOS = 34; E_SETMARKERSET = 35; E_SETMARKER = 36; E_SETMARKERBOX = 37;
  E_MARKER = 38; E_POLYMARKER = 39; E_IMAGE = 40; E_SETPEL = 41; E_SETTAG = 42;
  E_SETMODELXFORM = 43; E_CALLSEGMENT = 44; E_LABEL = 45; E_COMMENT = 46; E_POLYLINEDISJ = 47;
  E_SETCHAREXTRA = 48; E_SETCHARBREAK = 49; E_SETTEXTALIGN = 50; E_BEGINPATH = 51;
  E_ENDPATH = 52; E_CLOSEFIGURE = 53; E_FILLPATH = 54; E_STROKEPATH = 55; E_OUTLINEPATH = 56;
  E_POP = 57; E_SETATTRS = 58; E_FLOODFILL = 59; E_POLYGONS = 60; E_USER = 61; E_ERASE = 62;
  E_SETVIEWLIMITS = 63;
  SinTab : Array[0..1023] Of LongInt = (
    0, 402, 804, 1206, 1608, 2010, 2412, 2814, 3216, 3617, 4019, 4420,
    4821, 5222, 5623, 6023, 6424, 6824, 7224, 7623, 8022, 8421, 8820, 9218,
    9616, 10014, 10411, 10808, 11204, 11600, 11996, 12391, 12785, 13180, 13573, 13966,
    14359, 14751, 15143, 15534, 15924, 16314, 16703, 17091, 17479, 17867, 18253, 18639,
    19024, 19409, 19792, 20175, 20557, 20939, 21320, 21699, 22078, 22457, 22834, 23210,
    23586, 23961, 24335, 24708, 25080, 25451, 25821, 26190, 26558, 26925, 27291, 27656,
    28020, 28383, 28745, 29106, 29466, 29824, 30182, 30538, 30893, 31248, 31600, 31952,
    32303, 32652, 33000, 33347, 33692, 34037, 34380, 34721, 35062, 35401, 35738, 36075,
    36410, 36744, 37076, 37407, 37736, 38064, 38391, 38716, 39040, 39362, 39683, 40002,
    40320, 40636, 40951, 41264, 41576, 41886, 42194, 42501, 42806, 43110, 43412, 43713,
    44011, 44308, 44604, 44898, 45190, 45480, 45769, 46056, 46341, 46624, 46906, 47186,
    47464, 47741, 48015, 48288, 48559, 48828, 49095, 49361, 49624, 49886, 50146, 50404,
    50660, 50914, 51166, 51417, 51665, 51911, 52156, 52398, 52639, 52878, 53114, 53349,
    53581, 53812, 54040, 54267, 54491, 54714, 54934, 55152, 55368, 55582, 55794, 56004,
    56212, 56418, 56621, 56823, 57022, 57219, 57414, 57607, 57798, 57986, 58172, 58356,
    58538, 58718, 58896, 59071, 59244, 59415, 59583, 59750, 59914, 60075, 60235, 60392,
    60547, 60700, 60851, 60999, 61145, 61288, 61429, 61568, 61705, 61839, 61971, 62101,
    62228, 62353, 62476, 62596, 62714, 62830, 62943, 63054, 63162, 63268, 63372, 63473,
    63572, 63668, 63763, 63854, 63944, 64031, 64115, 64197, 64277, 64354, 64429, 64501,
    64571, 64639, 64704, 64766, 64827, 64884, 64940, 64993, 65043, 65091, 65137, 65180,
    65220, 65259, 65294, 65328, 65358, 65387, 65413, 65436, 65457, 65476, 65492, 65505,
    65516, 65525, 65531, 65535, 65536, 65535, 65531, 65525, 65516, 65505, 65492, 65476,
    65457, 65436, 65413, 65387, 65358, 65328, 65294, 65259, 65220, 65180, 65137, 65091,
    65043, 64993, 64940, 64884, 64827, 64766, 64704, 64639, 64571, 64501, 64429, 64354,
    64277, 64197, 64115, 64031, 63944, 63854, 63763, 63668, 63572, 63473, 63372, 63268,
    63162, 63054, 62943, 62830, 62714, 62596, 62476, 62353, 62228, 62101, 61971, 61839,
    61705, 61568, 61429, 61288, 61145, 60999, 60851, 60700, 60547, 60392, 60235, 60075,
    59914, 59750, 59583, 59415, 59244, 59071, 58896, 58718, 58538, 58356, 58172, 57986,
    57798, 57607, 57414, 57219, 57022, 56823, 56621, 56418, 56212, 56004, 55794, 55582,
    55368, 55152, 54934, 54714, 54491, 54267, 54040, 53812, 53581, 53349, 53114, 52878,
    52639, 52398, 52156, 51911, 51665, 51417, 51166, 50914, 50660, 50404, 50146, 49886,
    49624, 49361, 49095, 48828, 48559, 48288, 48015, 47741, 47464, 47186, 46906, 46624,
    46341, 46056, 45769, 45480, 45190, 44898, 44604, 44308, 44011, 43713, 43412, 43110,
    42806, 42501, 42194, 41886, 41576, 41264, 40951, 40636, 40320, 40002, 39683, 39362,
    39040, 38716, 38391, 38064, 37736, 37407, 37076, 36744, 36410, 36075, 35738, 35401,
    35062, 34721, 34380, 34037, 33692, 33347, 33000, 32652, 32303, 31952, 31600, 31248,
    30893, 30538, 30182, 29824, 29466, 29106, 28745, 28383, 28020, 27656, 27291, 26925,
    26558, 26190, 25821, 25451, 25080, 24708, 24335, 23961, 23586, 23210, 22834, 22457,
    22078, 21699, 21320, 20939, 20557, 20175, 19792, 19409, 19024, 18639, 18253, 17867,
    17479, 17091, 16703, 16314, 15924, 15534, 15143, 14751, 14359, 13966, 13573, 13180,
    12785, 12391, 11996, 11600, 11204, 10808, 10411, 10014, 9616, 9218, 8820, 8421,
    8022, 7623, 7224, 6824, 6424, 6023, 5623, 5222, 4821, 4420, 4019, 3617,
    3216, 2814, 2412, 2010, 1608, 1206, 804, 402, 0, -402, -804, -1206,
    -1608, -2010, -2412, -2814, -3216, -3617, -4019, -4420, -4821, -5222, -5623, -6023,
    -6424, -6824, -7224, -7623, -8022, -8421, -8820, -9218, -9616, -10014, -10411, -10808,
    -11204, -11600, -11996, -12391, -12785, -13180, -13573, -13966, -14359, -14751, -15143, -15534,
    -15924, -16314, -16703, -17091, -17479, -17867, -18253, -18639, -19024, -19409, -19792, -20175,
    -20557, -20939, -21320, -21699, -22078, -22457, -22834, -23210, -23586, -23961, -24335, -24708,
    -25080, -25451, -25821, -26190, -26558, -26925, -27291, -27656, -28020, -28383, -28745, -29106,
    -29466, -29824, -30182, -30538, -30893, -31248, -31600, -31952, -32303, -32652, -33000, -33347,
    -33692, -34037, -34380, -34721, -35062, -35401, -35738, -36075, -36410, -36744, -37076, -37407,
    -37736, -38064, -38391, -38716, -39040, -39362, -39683, -40002, -40320, -40636, -40951, -41264,
    -41576, -41886, -42194, -42501, -42806, -43110, -43412, -43713, -44011, -44308, -44604, -44898,
    -45190, -45480, -45769, -46056, -46341, -46624, -46906, -47186, -47464, -47741, -48015, -48288,
    -48559, -48828, -49095, -49361, -49624, -49886, -50146, -50404, -50660, -50914, -51166, -51417,
    -51665, -51911, -52156, -52398, -52639, -52878, -53114, -53349, -53581, -53812, -54040, -54267,
    -54491, -54714, -54934, -55152, -55368, -55582, -55794, -56004, -56212, -56418, -56621, -56823,
    -57022, -57219, -57414, -57607, -57798, -57986, -58172, -58356, -58538, -58718, -58896, -59071,
    -59244, -59415, -59583, -59750, -59914, -60075, -60235, -60392, -60547, -60700, -60851, -60999,
    -61145, -61288, -61429, -61568, -61705, -61839, -61971, -62101, -62228, -62353, -62476, -62596,
    -62714, -62830, -62943, -63054, -63162, -63268, -63372, -63473, -63572, -63668, -63763, -63854,
    -63944, -64031, -64115, -64197, -64277, -64354, -64429, -64501, -64571, -64639, -64704, -64766,
    -64827, -64884, -64940, -64993, -65043, -65091, -65137, -65180, -65220, -65259, -65294, -65328,
    -65358, -65387, -65413, -65436, -65457, -65476, -65492, -65505, -65516, -65525, -65531, -65535,
    -65536, -65535, -65531, -65525, -65516, -65505, -65492, -65476, -65457, -65436, -65413, -65387,
    -65358, -65328, -65294, -65259, -65220, -65180, -65137, -65091, -65043, -64993, -64940, -64884,
    -64827, -64766, -64704, -64639, -64571, -64501, -64429, -64354, -64277, -64197, -64115, -64031,
    -63944, -63854, -63763, -63668, -63572, -63473, -63372, -63268, -63162, -63054, -62943, -62830,
    -62714, -62596, -62476, -62353, -62228, -62101, -61971, -61839, -61705, -61568, -61429, -61288,
    -61145, -60999, -60851, -60700, -60547, -60392, -60235, -60075, -59914, -59750, -59583, -59415,
    -59244, -59071, -58896, -58718, -58538, -58356, -58172, -57986, -57798, -57607, -57414, -57219,
    -57022, -56823, -56621, -56418, -56212, -56004, -55794, -55582, -55368, -55152, -54934, -54714,
    -54491, -54267, -54040, -53812, -53581, -53349, -53114, -52878, -52639, -52398, -52156, -51911,
    -51665, -51417, -51166, -50914, -50660, -50404, -50146, -49886, -49624, -49361, -49095, -48828,
    -48559, -48288, -48015, -47741, -47464, -47186, -46906, -46624, -46341, -46056, -45769, -45480,
    -45190, -44898, -44604, -44308, -44011, -43713, -43412, -43110, -42806, -42501, -42194, -41886,
    -41576, -41264, -40951, -40636, -40320, -40002, -39683, -39362, -39040, -38716, -38391, -38064,
    -37736, -37407, -37076, -36744, -36410, -36075, -35738, -35401, -35062, -34721, -34380, -34037,
    -33692, -33347, -33000, -32652, -32303, -31952, -31600, -31248, -30893, -30538, -30182, -29824,
    -29466, -29106, -28745, -28383, -28020, -27656, -27291, -26925, -26558, -26190, -25821, -25451,
    -25080, -24708, -24335, -23961, -23586, -23210, -22834, -22457, -22078, -21699, -21320, -20939,
    -20557, -20175, -19792, -19409, -19024, -18639, -18253, -17867, -17479, -17091, -16703, -16314,
    -15924, -15534, -15143, -14751, -14359, -13966, -13573, -13180, -12785, -12391, -11996, -11600,
    -11204, -10808, -10411, -10014, -9616, -9218, -8820, -8421, -8022, -7623, -7224, -6824,
    -6424, -6023, -5623, -5222, -4821, -4420, -4019, -3617, -3216, -2814, -2412, -2010,
    -1608, -1206, -804, -402);
Const
  { indices des champs de TGps.X }
  gxArcP = 0; gxArcQ = 1; gxArcR = 2; gxArcS = 3; gxTag = 4; gxDefTag = 5; gxAttrMode = 6;
  gxDrawMode = 7; gxEditMode = 8; gxStopDraw = 9; gxDCtl = 10; gxVlX1 = 18; gxVlY1 = 19;
  gxVlX2 = 20; gxVlY2 = 21; gxVlOn = 22; gxGfX1 = 23; gxGfY1 = 24; gxGfX2 = 25; gxGfY2 = 26;
  gxGfOn = 27; gxClipRgn = 28; gxClipPath = 29; gxLogMode = 30; gxLogTab = 31; gxLogN = 32;
  gxPal = 33; gxCp = 34; gxBndOn = 35; gxBndX1 = 36; gxBndY1 = 37; gxBndX2 = 38; gxBndY2 = 39;
  gxPickX = 40; gxPickY = 41; gxPickW = 42; gxPickH = 43; gxOpenSeg = 44; gxElemPtr = 45;
  gxInArea = 46; gxAreaFl = 47; gxInPath = 48; gxPathFl = 49; gxPathId = 50; gxAttrStk = 51;
  gxSaveStk = 52; gxSaveN = 53; gxLcids = 54; gxLsCtr = 55; gxDefArcP = 56; gxDefArcQ = 57;
  gxDefArcR = 58; gxDefArcS = 59; gxDefVlX1 = 60; gxDefVlY1 = 61; gxDefVlX2 = 62; gxDefVlY2 = 63;
  gxDefVlOn = 64; gxInElem = 65; gxElemStart = 66;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

  { espace de presentation }
  TGps = Record
    Pid, Hab, Dc, Flags, Units, PgW, PgH : LongInt;
    PmHps : LongInt;                       { HPS de PMWIN (0 : aucun) }
    Vx1, Vy1, Vx2, Vy2 : LongInt;          { cloture de la page (pels) }
    Mdl, Vw, Dv : Array[0..8] Of LongInt;  { modele, vue, vue par defaut }
    CurX, CurY : LongInt;
    LColor, LBack, LMix, LBMix, LWidth, LGeom, LType, LEnd, LJoin : LongInt;
    CColor, CBack, CMix, CBMix, CSet, CMode, CBoxX, CBoxY, CAngX, CAngY, CShX, CShY : LongInt;
    CDir, CAlignH, CAlignV, CExtra, CBreak : LongInt;
    MColor, MBack, MMix, MBMix, MSet, MSym, MBoxX, MBoxY : LongInt;
    AColor, ABack, AMix, ABMix, PSet, PSym, PRefX, PRefY : LongInt;
    IColor, IBack, IMix, IBMix : LongInt;
    X : Array[0..66] Of LongInt;            { champs suivants (OS2PC : 64 champs nommes au plus) }
  End;

Var
  { contextes de peripheriques }
  DcUse, DcPid, DcType, DcW, DcH, DcBmp, DcMeta, DcWnd, DcOwner, DcHab : Array[0..MaxDC - 1] Of LongInt;
  { espaces de presentation }
  Gps : Array[0..MaxGPS - 1] Of TGps;
  GpsUse : Array[0..MaxGPS - 1] Of LongInt;
  { bitmaps }
  BmUse, BmPid, BmCx, BmCy, BmBpp, BmBits, BmStride, BmPal, BmDc, BmDimX, BmDimY : Array[0..MaxGBmp - 1] Of LongInt;
  { regions : rectangles (x1, y1, x2, y2 exclusifs) en arena }
  RgUse, RgPid, RgN, RgCap, RgData : Array[0..MaxRgn - 1] Of LongInt;
  { metafichiers et segments : tampons d'elements (arena) }
  MfUse, MfData, MfLen, MfCap : Array[0..MaxMeta - 1] Of LongInt;
  SgUse, SgPs, SgId, SgData, SgLen, SgCap, SgAttr, SgPri, SgNElem : Array[0..MaxSeg - 1] Of LongInt;
  SgXf : Array[0..MaxSeg * 9 - 1] Of LongInt;
  { palettes }
  PlUse, PlPid, PlN, PlData : Array[0..MaxPal - 1] Of LongInt;
  { cible courante du dessin }
  TgKind, TgW, TgH, TgBase, TgStride, TgBpp, TgOffX, TgOffY, TgBm : LongInt;
  ClipN : LongInt;
  ClipX1, ClipY1, ClipX2, ClipY2 : Array[0..MaxClipR - 1] Of LongInt;
  RMode, Hit, HitX1, HitY1, HitX2, HitY2 : LongInt;   { 0 dessin, 2 correlation }
  CurK : LongInt;
  { figures (zones, chemins) : sommets en pels du peripherique }
  FgX, FgY : Array[0..4095] Of LongInt;
  FgN : LongInt;
  FgStart : Array[0..255] Of LongInt;
  FgCnt : LongInt;
  PathX, PathY : Array[0..4095] Of LongInt;
  PathN, PathFigs : LongInt;
  PathStart : Array[0..255] Of LongInt;
  PathOk : LongInt;
  { police (8 x 16) }
  FontBits : Array[0..4095] Of Byte;
  FontOk : LongInt;
  { palettes du materiel }
  Vga16 : Array[0..15] Of LongInt;
  Pal256 : Array[0..255] Of LongInt;
  DefTab : Array[0..15] Of LongInt;
  { divers }
  Arena : Array[0..ArenaSize - 1] Of Byte;
  Recording, Replaying, ReplayDepth, LastErr : LongInt;
  PmMod, PmErrFn, PmInfoFn, PmFromDc : LongInt;
  NameZ : Array[0..259] Of Byte;
  Scratch : Array[0..1023] Of Byte;
  Dummy : LongInt;

Var
  PatBuf : Array[0..7] Of LongInt;
  PatOn : LongInt;                       { 0 plein, 1 motif, 2 vide (BLANK) }
  PatRx, PatRy : LongInt;
  CompM : Array[0..8] Of LongInt;        { monde -> page (espace courant) }
  { points du monde d'une primitive et points du peripherique }
  WX, WY, DXs, DYs : Array[0..4095] Of LongInt;
  WN : LongInt;
  { intersections d'une ligne de balayage }
  XC, XD : Array[0..2047] Of LongInt;
  FgClosed : Array[0..255] Of LongInt;
  PathClosed : Array[0..255] Of LongInt;
  BrushW : LongInt;
  { vecteurs du peripherique d'un caractere (16.16) : largeur et hauteur }
  TBx, TBy, TUx, TUy : LongInt;
  TWx, TWy : LongInt;
  RecE, RecN, PushCnt : LongInt;
  RecV : Array[0..15] Of LongInt;
  { source d'un transfert : bitmap ou cible d'un espace }
  SrKind, SrW, SrH, SrBase, SrStride, SrBpp, SrOffX, SrOffY, SrBm, SrPbmi : LongInt;
  SvKind, SvW, SvH, SvBase, SvStride, SvBpp, SvOffX, SvOffY, SvBm : LongInt;
  SegInit : Array[0..MaxGPS * 16 - 1] Of LongInt;     { attributs initiaux }
  CorHits, CorMax, CorOut, CorSeg : LongInt;
  MtCur, MtPos : Array[0..7] Of LongInt;

{ --- services des autres DLL --- }
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetProcessHeap : LongInt; External 'DOSCALLS' Name 'GetProcessHeap';
Function KHeapAlloc(H, Flags, Size : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapAlloc';
Function KHeapFree(H, Flags, P : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapFree';
Function DcQueryModuleHandle(PName, PH : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryModuleHandle';
Function DcQueryProcAddr(H, Ord, PName, PP : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryProcAddr';
Function DcGetResource(H, T, Id, PP : LongInt) : LongInt; External 'DOSCALLS' Name 'DosGetResource';
Function DcOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function VioGetMode(P, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetMode';
Function VioGetFont(P, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetFont';

{ --- acces a la memoire --- }
Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
End;

{ mot signe }
Function RdSW(A : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := RdW(A);
  If V >= $8000 Then V := V - $10000;
  RdSW := V;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FFFF;
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
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FF;
End;

Procedure MemMove(Src, Dst, N : LongInt);
Var K : LongInt;
Begin
  If (Dst < Src) Then
  Begin
    For K := 0 To N - 1 Do WrB(Dst + K, RdB(Src + K));
  End
  Else
    For K := N - 1 DownTo 0 Do WrB(Dst + K, RdB(Src + K));
End;

Procedure MemZero(A, N : LongInt);
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do WrB(A + K, 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (RdB(A + N) <> 0) And (N < 255) Do
    Begin
      S := S + Chr(RdB(A + N));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

{ N caracteres (N < 0 : jusqu'au zero) }
Function GetN(A, N : LongInt) : String;
Var S : String; K : LongInt;
Begin
  If N < 0 Then
  Begin
    GetN := GetZ(A);
    Exit;
  End;
  S := '';
  If A <> 0 Then
    For K := 0 To N - 1 Do
      If Length(S) < 255 Then S := S + Chr(RdB(A + K));
  GetN := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  If A = 0 Then Exit;
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

{ Copier S dans un tampon de Cb octets ; rend la longueur copiee }
Function PutZN(A, Cb : LongInt; S : String) : LongInt;
Begin
  PutZN := 0;
  If (A = 0) Or (Cb <= 0) Then Exit;
  If Length(S) > Cb - 1 Then S := Copy(S, 1, Cb - 1);
  PutZ(A, S);
  PutZN := Length(S);
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;


Function IntStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IntStr := S;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

Function Alive(Pid : LongInt) : Boolean;
Begin
  Alive := (Pid = 0) Or (Pid = MyPid) Or (KrnMonIo(0, 4, Pid) <> 0);
End;

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
End;

Function AbsI(A : LongInt) : LongInt;
Begin
  If A < 0 Then AbsI := -A Else AbsI := A;
End;

Function SLo(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V - $10000;
  SLo := V;
End;

{ --- arithmetique en virgule fixe (16.16) --- }
Function FMul(A, B : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    mov eax,A
    mov ecx,B
    imul ecx
    shr eax,16
    shl edx,16
    or eax,edx
    mov R,eax
  end;
  FMul := R;
End;

{ produit arrondi }
Function FMulR(A, B : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    mov eax,A
    mov ecx,B
    imul ecx
    add eax,32768
    adc edx,0
    shr eax,16
    shl edx,16
    or eax,edx
    mov R,eax
  end;
  FMulR := R;
End;

Function FDiv(A, B : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If B <> 0 Then
  asm
    mov eax,A
    mov edx,eax
    sar edx,16
    shl eax,16
    mov ecx,B
    idiv ecx
    mov R,eax
  end;
  FDiv := R;
End;

{ A * B / C sur 64 bits }
Function MulDiv(A, B, C : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If C <> 0 Then
  asm
    mov eax,A
    mov ecx,B
    imul ecx
    mov ecx,C
    idiv ecx
    mov R,eax
  end;
  MulDiv := R;
End;

{ arrondi d'une valeur 16.16 }
Function FRound(F : LongInt) : LongInt;
Begin
  If F >= 0 Then FRound := (F + $8000) Div $10000
  Else FRound := -((-F + $8000) Div $10000);
End;

Function ISqrt(N : LongInt) : LongInt;
Var X, Y : LongInt;
Begin
  If N <= 0 Then
  Begin
    ISqrt := 0;
    Exit;
  End;
  X := N; Y := (X + 1) Div 2;
  While Y < X Do
  Begin
    X := Y;
    Y := (X + N Div X) Div 2;
  End;
  ISqrt := X;
End;

{ sinus et cosinus (16.16) d'un angle exprime en 1024e de tour }
Function SinA(A : LongInt) : LongInt;
Begin
  SinA := SinTab[A And 1023];
End;

Function CosA(A : LongInt) : LongInt;
Begin
  CosA := SinTab[(A + 256) And 1023];
End;

{ angle (1024e de tour) du vecteur (X, Y) }
Function Angle1024(X, Y : LongInt) : LongInt;
Var Lo, Hi, Md, R, L, Sx, Sy : LongInt;
Begin
  If (X = 0) And (Y = 0) Then
  Begin
    Angle1024 := 0;
    Exit;
  End;
  L := ISqrt(MulDiv(X, X, 1) + MulDiv(Y, Y, 1));
  If (AbsI(X) > 32767) Or (AbsI(Y) > 32767) Then
  Begin
    X := X Div 256; Y := Y Div 256;
    L := ISqrt(X * X + Y * Y);
  End;
  If L = 0 Then L := 1;
  Sx := MulDiv(X, 65536, L); Sy := MulDiv(Y, 65536, L);
  { angle dans [0, 256] par la valeur absolue du sinus }
  Lo := 0; Hi := 256;
  While Lo < Hi Do
  Begin
    Md := (Lo + Hi) Div 2;
    If SinTab[Md] < AbsI(Sy) Then Lo := Md + 1 Else Hi := Md;
  End;
  R := Lo;
  If (Sx >= 0) And (Sy >= 0) Then Angle1024 := R
  Else If (Sx < 0) And (Sy >= 0) Then Angle1024 := 512 - R
  Else If (Sx < 0) And (Sy < 0) Then Angle1024 := 512 + R
  Else Angle1024 := (1024 - R) And 1023;
End;

{ --- ports du VGA (anneau 0) --- }
Procedure OutB(P, V : LongInt);
Begin
  asm
    mov edx,P
    mov eax,V
    out dx,al
  end;
End;

{ --- appel d'un point d'entree _System --- }
Function CallSys2(F, A1, A2 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,8
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys2 := R;
End;

{ --- memoire : blocs (+0 taille | 1 si utilise, +4 processus) --- }
Function HeapAllocIn(Base, Size, N : LongInt) : LongInt;
Var P, BS, Need, R, K : LongInt;
Begin
  R := 0;
  Need := ((N + 7) And Not 7) + 8;
  P := 0;
  While (R = 0) And (P < Size) Do
  Begin
    BS := RdL(Base + P) And Not 1;
    If BS <= 0 Then P := Size
    Else
    Begin
      If (RdL(Base + P) And 1) = 0 Then
      Begin
        While (P + BS < Size) And ((RdL(Base + P + BS) And 1) = 0) And (RdL(Base + P + BS) > 0) Do
        Begin
          BS := BS + RdL(Base + P + BS);
          WrL(Base + P, BS);
        End;
        If BS >= Need Then
        Begin
          If BS - Need >= 16 Then
          Begin
            WrL(Base + P + Need, BS - Need);
            BS := Need;
          End;
          WrL(Base + P, BS Or 1);
          WrL(Base + P + 4, MyPid);
          R := Base + P + 8;
          For K := 0 To BS - 9 Do WrB(R + K, 0);
        End;
      End;
      P := P + BS;
    End;
  End;
  HeapAllocIn := R;
End;

Function MemAlloc(N : LongInt) : LongInt;
Begin
  MemAlloc := HeapAllocIn(LongInt(@Arena), ArenaSize, N);
End;

Procedure MemFree(A : LongInt);
Begin
  If (A >= LongInt(@Arena) + 8) And (A < LongInt(@Arena) + ArenaSize) Then WrL(A - 8, RdL(A - 8) And Not 1);
End;

Function MemSize(A : LongInt) : LongInt;
Begin
  MemSize := (RdL(A - 8) And Not 1) - 8;
End;

{ grands blocs (bitmaps) : tas du processus }
Function BigAlloc(N : LongInt) : LongInt;
Var P, K : LongInt;
Begin
  P := KHeapAlloc(KGetProcessHeap, 0, N);
  If P <> 0 Then
    For K := 0 To N - 1 Do WrB(P + K, 0);
  BigAlloc := P;
End;

Procedure BigFree(P : LongInt);
Begin
  If P <> 0 Then Dummy := KHeapFree(KGetProcessHeap, 0, P);
End;

{ --- erreurs : rendues par WinGetLastError (PMWIN) --- }
Procedure SetErr(Code : LongInt);
Begin
  LastErr := (4 Shl 16) Or Code;
  If PmErrFn = 0 Then
  Begin
    If PmMod = 0 Then
    Begin
      PutZ(LongInt(@NameZ), 'PMWIN');
      If DcQueryModuleHandle(LongInt(@NameZ), LongInt(@PmMod)) <> 0 Then PmMod := 0;
    End;
    If PmMod <> 0 Then
    Begin
      PutZ(LongInt(@NameZ), 'WinSetErrorInfo');
      If DcQueryProcAddr(PmMod, 0, LongInt(@NameZ), LongInt(@PmErrFn)) <> 0 Then PmErrFn := 0;
    End;
  End;
  If PmErrFn <> 0 Then Dummy := CallSys2(PmErrFn, LastErr, 0);
End;


{ ==================================================================== }
{ Partie 2 - Contextes, bitmaps, cible du dessin, pels, couleurs        }
{ ==================================================================== }

Function DcIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $44470001;
  If (I < 0) Or (I >= MaxDC) Then I := -1
  Else If DcUse[I] = 0 Then I := -1;
  DcIdx := I;
End;

Function BmIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $47420001;
  If (I < 0) Or (I >= MaxGBmp) Then I := -1
  Else If (BmUse[I] = 0) Or Not Alive(BmPid[I]) Then I := -1;
  BmIdx := I;
End;

Function NewDc(Typ : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxDC - 1 DownTo 0 Do
    If (DcUse[I] = 0) Or Not Alive(DcPid[I]) Then F := I;
  If F >= 0 Then
  Begin
    DcUse[F] := 1; DcPid[F] := MyPid; DcType[F] := Typ; DcW[F] := 640; DcH[F] := 480;
    DcBmp[F] := -1; DcMeta[F] := -1; DcWnd[F] := 0; DcOwner[F] := MyPid; DcHab[F] := 0;
  End;
  NewDc := F;
End;

{ --- ecran : mode du VGA (VIOCALLS) --- }
Function ScreenMode(Var W, H, Bits : LongInt) : LongInt;
Var Mi : Array[0..39] Of Byte; K : LongInt;
Begin
  For K := 0 To 39 Do Mi[K] := 0;
  WrW(LongInt(@Mi), 34);
  Dummy := VioGetMode(LongInt(@Mi), 0);
  If (Mi[2] And 2) <> 0 Then
  Begin
    W := RdW(LongInt(@Mi) + 8); H := RdW(LongInt(@Mi) + 10); Bits := Mi[3];
    If Bits = 8 Then ScreenMode := TG_LINEAR Else ScreenMode := TG_PLANAR;
  End
  Else
  Begin
    W := 640; H := 400; Bits := 4;
    ScreenMode := TG_TEXT;
  End;
End;

{ --- informations d'un espace ou d'une fenetre de PMWIN : HWND, origine,
  rectangle visible (pels de l'ecran) --- }
Function PmInfo(H, P : LongInt) : Boolean;
Begin
  PmInfo := False;
  If PmMod = 0 Then
  Begin
    PutZ(LongInt(@NameZ), 'PMWIN');
    If DcQueryModuleHandle(LongInt(@NameZ), LongInt(@PmMod)) <> 0 Then PmMod := 0;
  End;
  If PmMod = 0 Then Exit;
  If PmInfoFn = 0 Then
    If DcQueryProcAddr(PmMod, 1001, 0, LongInt(@PmInfoFn)) <> 0 Then PmInfoFn := 0;
  If PmInfoFn = 0 Then Exit;
  PmInfo := CallSys2(PmInfoFn, H, P) <> 0;
End;

Function PmWndFromDc(Hdc : LongInt) : LongInt;
Begin
  PmWndFromDc := 0;
  If PmMod = 0 Then
  Begin
    PutZ(LongInt(@NameZ), 'PMWIN');
    If DcQueryModuleHandle(LongInt(@NameZ), LongInt(@PmMod)) <> 0 Then PmMod := 0;
  End;
  If PmMod = 0 Then Exit;
  If PmFromDc = 0 Then
  Begin
    PutZ(LongInt(@NameZ), 'WinWindowFromDC');
    If DcQueryProcAddr(PmMod, 0, LongInt(@NameZ), LongInt(@PmFromDc)) <> 0 Then PmFromDc := 0;
  End;
  If PmFromDc <> 0 Then PmWndFromDc := CallSys2(PmFromDc, Hdc, 0);
End;

{ --- couleurs --- }
Function RgbDist(A, B : LongInt) : LongInt;
Var Dr, Dg, Db : LongInt;
Begin
  Dr := ((A Shr 16) And 255) - ((B Shr 16) And 255);
  Dg := ((A Shr 8) And 255) - ((B Shr 8) And 255);
  Db := (A And 255) - (B And 255);
  RgbDist := Dr * Dr * 3 + Dg * Dg * 4 + Db * Db * 2;
End;

{ index de la couleur la plus proche dans une table de N couleurs RVB }
Function Nearest(Tab, N, Rgb : LongInt) : LongInt;
Var I, B, D, Bd : LongInt;
Begin
  B := 0; Bd := $7FFFFFFF;
  For I := 0 To N - 1 Do
  Begin
    D := RgbDist(RdL(Tab + I * 4), Rgb);
    If D < Bd Then
    Begin
      Bd := D; B := I;
    End;
  End;
  Nearest := B;
End;

{ couleurs d'un bitmap : table de 256 RVB (arena) }
Function BmTab(B : LongInt) : LongInt;
Begin
  BmTab := BmPal[B];
End;

{ table et nombre de couleurs de la cible courante }
Function TgTab(Var N : LongInt) : LongInt;
Begin
  N := 16;
  TgTab := LongInt(@Vga16);
  Case TgKind Of
    TG_BMP :
      Begin
        If TgBpp >= 24 Then N := 0
        Else
        Begin
          N := 1 Shl TgBpp;
          TgTab := BmPal[TgBm];
        End;
      End;
    TG_PLANAR :
      If TgBpp = 1 Then N := 2;
    TG_LINEAR :
      Begin
        N := 256;
        TgTab := LongInt(@Pal256);
      End;
    TG_TEXT : N := 8;
  End;
End;

{ couleurs par defaut de PM -> index du VGA 16 couleurs (comme le pilote
  VGA de PM : CLR_BLUE bleu vif 9, CLR_DARKBLUE bleu 1...) }
Const
  PmVga : Array[0..15] Of Byte = (15, 9, 12, 13, 10, 11, 14, 0, 8, 1, 4, 5, 2, 3, 6, 7);

{ valeur du peripherique pour une couleur RVB }
Function DevVal(Rgb : LongInt) : LongInt;
Var N, T, I, V : LongInt;
Begin
  T := TgTab(N);
  V := -1;
  If T = LongInt(@Vga16) Then
  Begin
    I := 0;
    While (I < 16) And (V < 0) Do
    Begin
      If DefTab[I] = (Rgb And $FFFFFF) Then V := PmVga[I];
      Inc(I);
    End;
  End;
  If (V >= 0) And (N = 16) Then DevVal := V
  Else If N = 0 Then DevVal := Rgb And $FFFFFF
  Else If (TgKind = TG_PLANAR) And (TgBpp = 1) Then
  Begin
    If RgbDist(Rgb, 0) < RgbDist(Rgb, $FFFFFF) Then DevVal := 0 Else DevVal := 1;
  End
  Else DevVal := Nearest(T, N, Rgb);
End;

{ couleur RVB d'une valeur du peripherique }
Function DevRgb(V : LongInt) : LongInt;
Var N, T, I : LongInt;
Begin
  T := TgTab(N);
  If N = 0 Then DevRgb := V And $FFFFFF
  Else If (TgKind = TG_PLANAR) And (TgBpp = 1) Then
  Begin
    If V <> 0 Then DevRgb := $FFFFFF Else DevRgb := 0;
  End
  Else If (T = LongInt(@Vga16)) And (N = 16) Then
  Begin
    I := 0;
    While PmVga[I] <> (V And 15) Do Inc(I);
    DevRgb := DefTab[I];
  End
  Else DevRgb := RdL(T + (V Mod N) * 4);
End;

Function DevMask : LongInt;
Begin
  Case TgKind Of
    TG_BMP : If TgBpp >= 24 Then DevMask := $FFFFFF Else DevMask := (1 Shl TgBpp) - 1;
    TG_PLANAR : If TgBpp = 1 Then DevMask := 1 Else DevMask := 15;
    TG_LINEAR : DevMask := 255;
    TG_TEXT : DevMask := 7;
  Else
    DevMask := 15;
  End;
End;

{ couleur logique -> RVB (Back : couleur de fond par defaut) }
Function ClrRgb(K, C : LongInt; Back : Boolean) : LongInt;
Var T : LongInt;
Begin
  If C = CLR_DEFAULT Then
  Begin
    If Back Then C := CLR_BACKGROUND Else C := CLR_NEUTRAL;
  End;
  If C = CLR_WHITE Then ClrRgb := $FFFFFF
  Else If C = CLR_BLACK Then ClrRgb := 0
  Else If C = CLR_TRUE Then ClrRgb := $FFFFFF
  Else If C = CLR_FALSE Then ClrRgb := 0
  Else If Gps[K].X[gxLogMode] = 3 Then ClrRgb := C And $FFFFFF
  Else If (Gps[K].X[gxLogMode] = 4) And (Gps[K].X[gxPal] > 0) Then
  Begin
    T := Gps[K].X[gxPal] - 1;
    If (C >= 0) And (C < PlN[T]) Then ClrRgb := RdL(PlData[T] + C * 4) And $FFFFFF Else ClrRgb := 0;
  End
  Else If (C >= 0) And (C < Gps[K].X[gxLogN]) Then ClrRgb := RdL(Gps[K].X[gxLogTab] + C * 4) And $FFFFFF
  Else If (C >= 0) And (C <= 15) Then ClrRgb := DefTab[C]
  Else ClrRgb := 0;
End;

{ couleur logique -> valeur du peripherique }
Function ClrDev(K, C : LongInt; Back : Boolean) : LongInt;
Begin
  If C = CLR_TRUE Then ClrDev := DevMask
  Else If C = CLR_FALSE Then ClrDev := 0
  Else ClrDev := DevVal(ClrRgb(K, C, Back));
End;

{ --- melanges (FM_*) sur des valeurs du peripherique --- }
Function MixV(Old, New, Mx, Msk : LongInt) : LongInt;
Var R : LongInt;
Begin
  Case Mx Of
    0, 2 : R := New;
    1 : R := Old Or New;
    4 : R := Old Xor New;
    5 : R := Old;
    6 : R := Old And New;
    7 : R := Old And Not New;
    8 : R := New And Not Old;
    9 : R := 0;
    10 : R := Not (Old Or New);
    11 : R := Not (Old Xor New);
    12 : R := Not Old;
    13 : R := New Or Not Old;
    14 : R := Not New;
    15 : R := Old Or Not New;
    16 : R := Not (Old And New);
    17 : R := Msk;
  Else
    R := New;
  End;
  MixV := R And Msk;
End;

{ --- pels de la cible (coordonnees de la cible, y vers le haut) --- }
Function TgGet(X, Y : LongInt) : LongInt;
Var A, P, V, M, Row : LongInt;
Begin
  TgGet := 0;
  If (X < 0) Or (Y < 0) Or (X >= TgW) Or (Y >= TgH) Then Exit;
  Case TgKind Of
    TG_BMP :
      Begin
        A := TgBase + Y * TgStride;
        Case TgBpp Of
          1 : TgGet := (RdB(A + X Shr 3) Shr (7 - (X And 7))) And 1;
          4 : If (X And 1) = 0 Then TgGet := RdB(A + X Shr 1) Shr 4 Else TgGet := RdB(A + X Shr 1) And 15;
          8 : TgGet := RdB(A + X);
        Else
          TgGet := RdB(A + X * 3) Or (RdB(A + X * 3 + 1) Shl 8) Or (RdB(A + X * 3 + 2) Shl 16);
        End;
      End;
    TG_PLANAR :
      Begin
        Row := TgH - 1 - Y;
        A := $A0000 + Row * TgStride + X Shr 3;
        M := $80 Shr (X And 7);
        V := 0;
        For P := 0 To 3 Do
        Begin
          OutB($3CE, 4); OutB($3CF, P);
          If (RdB(A) And M) <> 0 Then V := V Or (1 Shl P);
        End;
        OutB($3CE, 4); OutB($3CF, 0);
        If TgBpp = 1 Then V := V And 1;
        TgGet := V;
      End;
    TG_LINEAR : TgGet := RdB($A0000 + (TgH - 1 - Y) * TgW + X);
    TG_TEXT : TgGet := (RdB($B8000 + (((TgH - 1 - Y) Div 16) * 80 + X Div 8) * 2 + 1) Shr 4) And 7;
  End;
End;

Procedure TgPut(X, Y, V : LongInt);
Var A, B, Row : LongInt;
Begin
  If (X < 0) Or (Y < 0) Or (X >= TgW) Or (Y >= TgH) Then Exit;
  Case TgKind Of
    TG_BMP :
      Begin
        A := TgBase + Y * TgStride;
        Case TgBpp Of
          1 :
            Begin
              B := RdB(A + X Shr 3);
              If (V And 1) <> 0 Then B := B Or ($80 Shr (X And 7)) Else B := B And Not ($80 Shr (X And 7));
              WrB(A + X Shr 3, B);
            End;
          4 :
            Begin
              B := RdB(A + X Shr 1);
              If (X And 1) = 0 Then B := (B And $0F) Or ((V And 15) Shl 4) Else B := (B And $F0) Or (V And 15);
              WrB(A + X Shr 1, B);
            End;
          8 : WrB(A + X, V);
        Else
          Begin
            WrB(A + X * 3, V); WrB(A + X * 3 + 1, V Shr 8); WrB(A + X * 3 + 2, V Shr 16);
          End;
        End;
      End;
    TG_PLANAR :
      Begin
        Row := TgH - 1 - Y;
        A := $A0000 + Row * TgStride + X Shr 3;
        OutB($3CE, 5); OutB($3CF, 2);              { mode d'ecriture 2 }
        OutB($3CE, 3); OutB($3CF, 0);
        OutB($3CE, 8); OutB($3CF, $80 Shr (X And 7));
        OutB($3C4, 2); OutB($3C5, $0F);
        B := RdB(A);
        If TgBpp = 1 Then
        Begin
          If (V And 1) <> 0 Then V := 15 Else V := 0;
        End;
        WrB(A, V);
        OutB($3CE, 8); OutB($3CF, $FF);
        OutB($3CE, 5); OutB($3CF, 0);
      End;
    TG_LINEAR : WrB($A0000 + (TgH - 1 - Y) * TgW + X, V);
    TG_TEXT :
      Begin
        A := $B8000 + (((TgH - 1 - Y) Div 16) * 80 + X Div 8) * 2 + 1;
        WrB(A, (RdB(A) And $8F) Or ((V And 7) Shl 4));
      End;
  End;
End;

{ ligne horizontale de pels identiques (remplacement), plans du VGA par
  octets }
Procedure TgSpan(X1, X2, Y, V : LongInt);
Var A, X, M, Row, Xs, Xe : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If X2 > TgW Then X2 := TgW;
  If (X1 >= X2) Or (Y < 0) Or (Y >= TgH) Then Exit;
  If TgKind = TG_PLANAR Then
  Begin
    If TgBpp = 1 Then
    Begin
      If (V And 1) <> 0 Then V := 15 Else V := 0;
    End;
    Row := TgH - 1 - Y;
    OutB($3CE, 5); OutB($3CF, 2);
    OutB($3CE, 3); OutB($3CF, 0);
    OutB($3C4, 2); OutB($3C5, $0F);
    X := X1;
    While X < X2 Do
    Begin
      Xs := X; Xe := MinI((X And Not 7) + 8, X2);
      M := ($FF Shr (Xs And 7)) And ($FF Shl (8 - (Xe - (Xs And Not 7)))) And $FF;
      A := $A0000 + Row * TgStride + X Shr 3;
      OutB($3CE, 8); OutB($3CF, M);
      Dummy := RdB(A);
      WrB(A, V);
      X := Xe;
    End;
    OutB($3CE, 8); OutB($3CF, $FF);
    OutB($3CE, 5); OutB($3CF, 0);
  End
  Else If TgKind = TG_TEXT Then
  Begin
    X := X1;
    While X < X2 Do
    Begin
      TgPut(X, Y, V);
      X := (X And Not 7) + 8;
    End;
  End
  Else
    For X := X1 To X2 - 1 Do TgPut(X, Y, V);
End;

{ --- cible du dessin d'un espace de presentation --- }
Procedure ClipSet(X1, Y1, X2, Y2 : LongInt);
Begin
  ClipN := 1;
  ClipX1[0] := X1; ClipY1[0] := Y1; ClipX2[0] := X2; ClipY2[0] := Y2;
End;

{ restreindre la liste de decoupage au rectangle (coordonnees de la cible) }
Procedure ClipRect(X1, Y1, X2, Y2 : LongInt);
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To ClipN - 1 Do
  Begin
    ClipX1[N] := MaxI(ClipX1[I], X1); ClipY1[N] := MaxI(ClipY1[I], Y1);
    ClipX2[N] := MinI(ClipX2[I], X2); ClipY2[N] := MinI(ClipY2[I], Y2);
    If (ClipX1[N] < ClipX2[N]) And (ClipY1[N] < ClipY2[N]) Then Inc(N);
  End;
  ClipN := N;
End;

{ restreindre la liste de decoupage a une region (rectangles en pels du
  peripherique, decales de Ox, Oy) }
Procedure ClipRegion(R, Ox, Oy : LongInt);
Var I, J, N, A : LongInt;
    TX1, TY1, TX2, TY2 : Array[0..MaxClipR - 1] Of LongInt;
Begin
  N := 0;
  For I := 0 To ClipN - 1 Do
    For J := 0 To RgN[R] - 1 Do
      If N < MaxClipR Then
      Begin
        A := RgData[R] + J * 16;
        TX1[N] := MaxI(ClipX1[I], RdL(A) + Ox); TY1[N] := MaxI(ClipY1[I], RdL(A + 4) + Oy);
        TX2[N] := MinI(ClipX2[I], RdL(A + 8) + Ox); TY2[N] := MinI(ClipY2[I], RdL(A + 12) + Oy);
        If (TX1[N] < TX2[N]) And (TY1[N] < TY2[N]) Then Inc(N);
      End;
  For I := 0 To N - 1 Do
  Begin
    ClipX1[I] := TX1[I]; ClipY1[I] := TY1[I]; ClipX2[I] := TX2[I]; ClipY2[I] := TY2[I];
  End;
  ClipN := N;
End;

Function RgIdx(H : LongInt) : LongInt; Forward;
Procedure LimitClip(K : LongInt); Forward;

{ preparer la cible du dessin de l'espace K ; faux si rien n'est dessine }
Function BeginDraw(K : LongInt) : Boolean;
Var D, W, H, Bits, Wn : LongInt; Info : Array[0..7] Of LongInt; Ok : Boolean;
Begin
  CurK := K;
  TgKind := TG_NONE; TgOffX := 0; TgOffY := 0; TgBm := -1;
  ClipN := 0;
  D := Gps[K].Dc;
  Ok := False;
  If Gps[K].PmHps <> 0 Then
  Begin
    If PmInfo(Gps[K].PmHps, LongInt(@Info)) Then
    Begin
      TgKind := ScreenMode(W, H, Bits);
      TgW := W; TgH := H; TgBpp := Bits; TgStride := W Div 8;
      TgOffX := Info[1]; TgOffY := Info[2];
      ClipSet(0, 0, TgW, TgH);
      ClipRect(Info[3], Info[4], Info[5], Info[6]);
      Ok := True;
    End;
  End
  Else If (D >= 0) And (DcUse[D] <> 0) Then
  Begin
    If DcType[D] = OD_MEMORY Then
    Begin
      If (DcBmp[D] >= 0) And (BmUse[DcBmp[D]] <> 0) Then
      Begin
        TgKind := TG_BMP; TgBm := DcBmp[D];
        TgW := BmCx[TgBm]; TgH := BmCy[TgBm]; TgBpp := BmBpp[TgBm]; TgBase := BmBits[TgBm];
        TgStride := BmStride[TgBm];
        ClipSet(0, 0, TgW, TgH);
        Ok := True;
      End;
    End
    Else If (DcType[D] = OD_DIRECT) Or (DcType[D] = OD_INFO) Or (DcType[D] = DCT_WINDOW) Then
    Begin
      TgKind := ScreenMode(W, H, Bits);
      TgW := W; TgH := H; TgBpp := Bits; TgStride := W Div 8;
      ClipSet(0, 0, TgW, TgH);
      Ok := DcType[D] <> OD_INFO;
      If DcType[D] = DCT_WINDOW Then
      Begin
        Wn := DcWnd[D];
        If PmInfo(Wn, LongInt(@Info)) Then
        Begin
          TgOffX := Info[1]; TgOffY := Info[2];
          ClipRect(Info[3], Info[4], Info[5], Info[6]);
        End
        Else Ok := False;
      End;
    End;
  End;
  If Not Ok Then
  Begin
    TgKind := TG_NONE;
    BeginDraw := False;
    Exit;
  End;
  If (Gps[K].X[gxClipRgn] >= 0) And (RgUse[Gps[K].X[gxClipRgn]] <> 0) Then ClipRegion(Gps[K].X[gxClipRgn], TgOffX, TgOffY);
  If (Gps[K].X[gxClipPath] >= 0) And (RgUse[Gps[K].X[gxClipPath]] <> 0) Then ClipRegion(Gps[K].X[gxClipPath], TgOffX, TgOffY);
  LimitClip(K);
  BeginDraw := ClipN > 0;
End;

{ --- pels du dessin : coordonnees du peripherique (avant decalage) --- }
Procedure BndAdd(X, Y : LongInt);
Var K : LongInt;
Begin
  K := CurK;
  If (K < 0) Or (Gps[K].X[gxBndOn] = 0) Then Exit;
  If Gps[K].X[gxBndOn] = 1 Then
  Begin
    Gps[K].X[gxBndX1] := X; Gps[K].X[gxBndY1] := Y; Gps[K].X[gxBndX2] := X; Gps[K].X[gxBndY2] := Y;
    Gps[K].X[gxBndOn] := 2;
  End
  Else
  Begin
    Gps[K].X[gxBndX1] := MinI(Gps[K].X[gxBndX1], X); Gps[K].X[gxBndY1] := MinI(Gps[K].X[gxBndY1], Y);
    Gps[K].X[gxBndX2] := MaxI(Gps[K].X[gxBndX2], X); Gps[K].X[gxBndY2] := MaxI(Gps[K].X[gxBndY2], Y);
  End;
End;

Function InClip(X, Y : LongInt) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := False;
  I := 0;
  While (I < ClipN) And Not R Do
  Begin
    If (X >= ClipX1[I]) And (X < ClipX2[I]) And (Y >= ClipY1[I]) And (Y < ClipY2[I]) Then R := True;
    Inc(I);
  End;
  InClip := R;
End;

Procedure DPix(X, Y, V, Mx : LongInt);
Var Sx, Sy : LongInt;
Begin
  If Mx = FM_LEAVEALONE Then Exit;
  Sx := X + TgOffX; Sy := Y + TgOffY;
  If Not InClip(Sx, Sy) Then Exit;
  If RMode = 2 Then
  Begin
    If (X >= HitX1) And (X < HitX2) And (Y >= HitY1) And (Y < HitY2) Then Hit := 1;
    Exit;
  End;
  BndAdd(X, Y);
  If TgKind = TG_NONE Then Exit;
  If (Mx = FM_OVERPAINT) Or (Mx = FM_DEFAULT) Then TgPut(Sx, Sy, V)
  Else TgPut(Sx, Sy, MixV(TgGet(Sx, Sy), V, Mx, DevMask));
End;

{ motif de remplissage (8 octets) de l'espace K ; 0 : plein }
Const
  PatTab : Array[0..159] Of LongInt = (
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,          { 0 defaut : plein }
    $FF, $77, $FF, $DD, $FF, $77, $FF, $DD,          { 1 DENSE1 }
    $77, $DD, $77, $DD, $77, $DD, $77, $DD,          { 2 }
    $EE, $55, $BB, $55, $EE, $55, $BB, $55,          { 3 }
    $AA, $55, $AA, $55, $AA, $55, $AA, $55,          { 4 }
    $AA, $44, $AA, $11, $AA, $44, $AA, $11,          { 5 }
    $88, $22, $88, $22, $88, $22, $88, $22,          { 6 }
    $80, $08, $80, $08, $80, $08, $80, $08,          { 7 }
    $80, $00, $08, $00, $80, $00, $08, $00,          { 8 DENSE8 }
    $88, $88, $88, $88, $88, $88, $88, $88,          { 9 VERT }
    $FF, $00, $00, $00, $FF, $00, $00, $00,          { 10 HORIZ }
    $88, $44, $22, $11, $88, $44, $22, $11,          { 11 DIAG1 }
    $CC, $66, $33, $99, $CC, $66, $33, $99,          { 12 DIAG2 }
    $11, $22, $44, $88, $11, $22, $44, $88,          { 13 DIAG3 }
    $99, $33, $66, $CC, $99, $33, $66, $CC,          { 14 DIAG4 }
    $00, $00, $00, $00, $00, $00, $00, $00,          { 15 NOSHADE }
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,          { 16 SOLID }
    $AA, $55, $AA, $55, $AA, $55, $AA, $55,          { 17 HALFTONE }
    $FF, $88, $88, $88, $FF, $88, $88, $88,          { 18 HATCH }
    $81, $42, $24, $18, $18, $24, $42, $81);         { 19 DIAGHATCH }


Function BmPatBits(B : LongInt) : Boolean; Forward;

Procedure PatPrepare(K : LongInt);
Var S, I : LongInt;
Begin
  S := Gps[K].PSym;
  PatOn := 1;
  If Gps[K].PSet <> 0 Then
  Begin
    If Not BmPatBits(Gps[K].PSet) Then
      For I := 0 To 7 Do PatBuf[I] := $FF;
  End
  Else If S = 64 Then PatOn := 2
  Else If (S <= 0) Or (S = 16) Or (S > 19) Then PatOn := 0
  Else
    For I := 0 To 7 Do PatBuf[I] := PatTab[S * 8 + I];
  PatRx := Gps[K].PRefX; PatRy := Gps[K].PRefY;
End;

{ remplir de X1 a X2 (exclu) sur la ligne Y, avec le motif et les
  couleurs de zone (Fg, Bg : valeurs du peripherique) }
Procedure DSpan(X1, X2, Y, Fg, Bg, Mx, BMx : LongInt);
Var I, X, A1, A2, Sy, Row : LongInt; On : Boolean;
Begin
  If X1 >= X2 Then Exit;
  Sy := Y + TgOffY;
  If RMode = 2 Then
  Begin
    If (Y >= HitY1) And (Y < HitY2) And (X1 < HitX2) And (X2 > HitX1) Then
      If InClip(MaxI(X1, HitX1) + TgOffX, Sy) Then Hit := 1;
    Exit;
  End;
  BndAdd(X1, Y); BndAdd(X2 - 1, Y);
  If TgKind = TG_NONE Then Exit;
  For I := 0 To ClipN - 1 Do
    If (Sy >= ClipY1[I]) And (Sy < ClipY2[I]) Then
    Begin
      A1 := MaxI(X1 + TgOffX, ClipX1[I]); A2 := MinI(X2 + TgOffX, ClipX2[I]);
      If A1 < A2 Then
      Begin
        If (PatOn = 0) And ((Mx = FM_OVERPAINT) Or (Mx = FM_DEFAULT)) Then TgSpan(A1, A2, Sy, Fg)
        Else If PatOn = 2 Then
        Begin
          If (BMx <> FM_LEAVEALONE) And (BMx <> 0) Then
            For X := A1 To A2 - 1 Do TgPut(X, Sy, MixV(TgGet(X, Sy), Bg, BMx, DevMask));
        End
        Else
        Begin
          Row := (Y - PatRy) And 7;
          For X := A1 To A2 - 1 Do
          Begin
            On := (PatOn = 0) Or (((PatBuf[7 - Row] Shr (7 - ((X - TgOffX - PatRx) And 7))) And 1) <> 0);
            If On Then
            Begin
              If (Mx = FM_OVERPAINT) Or (Mx = FM_DEFAULT) Then TgPut(X, Sy, Fg)
              Else If Mx <> FM_LEAVEALONE Then TgPut(X, Sy, MixV(TgGet(X, Sy), Fg, Mx, DevMask));
            End
            Else If (BMx <> FM_LEAVEALONE) And (BMx <> 0) Then
              TgPut(X, Sy, MixV(TgGet(X, Sy), Bg, BMx, DevMask));
          End;
        End;
      End;
    End;
End;

{ valeur d'un pel du peripherique (coordonnees du peripherique) }
Function DGet(X, Y : LongInt) : LongInt;
Begin
  DGet := TgGet(X + TgOffX, Y + TgOffY);
End;

{ --- bitmaps --- }
Function NewBitmap(Cx, Cy, Bpp : LongInt) : LongInt;
Var I, F, St, T, K : LongInt;
Begin
  NewBitmap := -1;
  If (Cx <= 0) Or (Cy <= 0) Or (Cx > 4096) Or (Cy > 4096) Then Exit;
  If Bpp <= 1 Then Bpp := 1
  Else If Bpp <= 4 Then Bpp := 4
  Else If Bpp <= 8 Then Bpp := 8
  Else Bpp := 24;
  F := -1;
  For I := MaxGBmp - 1 DownTo 0 Do
    If (BmUse[I] = 0) Or Not Alive(BmPid[I]) Then F := I;
  If F < 0 Then Exit;
  If BmUse[F] <> 0 Then MemFree(BmPal[F]);
  St := ((Cx * Bpp + 31) Div 32) * 4;
  BmBits[F] := BigAlloc(St * Cy);
  If BmBits[F] = 0 Then Exit;
  T := MemAlloc(1024);
  If T = 0 Then
  Begin
    BigFree(BmBits[F]);
    Exit;
  End;
  If Bpp = 1 Then
  Begin
    WrL(T, 0); WrL(T + 4, $FFFFFF);
  End
  Else If Bpp = 4 Then
  Begin
    For K := 0 To 15 Do WrL(T + K * 4, Vga16[K]);
  End
  Else For K := 0 To 255 Do WrL(T + K * 4, Pal256[K]);
  BmUse[F] := 1; BmPid[F] := MyPid; BmCx[F] := Cx; BmCy[F] := Cy; BmBpp[F] := Bpp;
  BmStride[F] := St; BmPal[F] := T; BmDc[F] := -1; BmDimX[F] := 0; BmDimY[F] := 0;
  NewBitmap := F;
End;

Procedure FreeBitmap(B : LongInt);
Begin
  BigFree(BmBits[B]);
  MemFree(BmPal[B]);
  BmUse[B] := 0;
End;


{ ==================================================================== }
{ Partie 3 - Espaces de presentation, transformations, regions          }
{ ==================================================================== }


{ --- matrices (MATRIXLF : M11, M12, M13, M21, M22, M23, M31, M32, M33) --- }
Procedure MatIdent(A : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 8 Do WrL(A + I * 4, 0);
  WrL(A, $10000); WrL(A + 16, $10000); WrL(A + 32, 1);
End;

{ C = A puis B (C peut etre A ou B) }
Procedure MatMul(A, B, C : LongInt);
Var R : Array[0..8] Of LongInt; I : LongInt;
Begin
  R[0] := FMul(RdL(A), RdL(B)) + FMul(RdL(A + 4), RdL(B + 12));
  R[1] := FMul(RdL(A), RdL(B + 4)) + FMul(RdL(A + 4), RdL(B + 16));
  R[2] := 0;
  R[3] := FMul(RdL(A + 12), RdL(B)) + FMul(RdL(A + 16), RdL(B + 12));
  R[4] := FMul(RdL(A + 12), RdL(B + 4)) + FMul(RdL(A + 16), RdL(B + 16));
  R[5] := 0;
  R[6] := FMul(RdL(A + 24), RdL(B)) + FMul(RdL(A + 28), RdL(B + 12)) + RdL(B + 24);
  R[7] := FMul(RdL(A + 24), RdL(B + 4)) + FMul(RdL(A + 28), RdL(B + 16)) + RdL(B + 28);
  R[8] := 1;
  For I := 0 To 8 Do WrL(C + I * 4, R[I]);
End;

{ point par une matrice }
Procedure MatPt(M : LongInt; X, Y : LongInt; Var RX, RY : LongInt);
Begin
  RX := FMulR(X, RdL(M)) + FMulR(Y, RdL(M + 12)) + RdL(M + 24);
  RY := FMulR(X, RdL(M + 4)) + FMulR(Y, RdL(M + 16)) + RdL(M + 28);
End;

{ inverse d'une matrice ; faux si elle n'est pas inversible }
Function MatInv(A, C : LongInt) : Boolean;
Var D, I11, I12, I21, I22, T1, T2 : LongInt;
Begin
  D := FMul(RdL(A), RdL(A + 16)) - FMul(RdL(A + 4), RdL(A + 12));
  If D = 0 Then
  Begin
    MatInv := False;
    Exit;
  End;
  I11 := FDiv(RdL(A + 16), D); I12 := -FDiv(RdL(A + 4), D);
  I21 := -FDiv(RdL(A + 12), D); I22 := FDiv(RdL(A), D);
  T1 := RdL(A + 24); T2 := RdL(A + 28);
  WrL(C, I11); WrL(C + 4, I12); WrL(C + 8, 0);
  WrL(C + 12, I21); WrL(C + 16, I22); WrL(C + 20, 0);
  WrL(C + 24, -(FMul(T1, I11) + FMul(T2, I21)));
  WrL(C + 28, -(FMul(T1, I12) + FMul(T2, I22)));
  WrL(C + 32, 1);
  MatInv := True;
End;

{ point par l'inverse d'une matrice (translation retiree d'abord, sans
  perte de precision) ; faux si elle n'est pas inversible }
Function InvPt(A, X, Y : LongInt; Var RX, RY : LongInt) : Boolean;
Var M : Array[0..8] Of LongInt; B : Boolean;
Begin
  B := MatInv(A, LongInt(@M));
  InvPt := B;
  If Not B Then Exit;
  X := X - RdL(A + 24); Y := Y - RdL(A + 28);
  RX := FMulR(X, M[0]) + FMulR(Y, M[3]);
  RY := FMulR(X, M[1]) + FMulR(Y, M[4]);
End;

{ composer la transformation monde -> page de l'espace K }
Procedure CompSet(K : LongInt);
Begin
  MatMul(LongInt(@Gps[K].Mdl), LongInt(@Gps[K].Vw), LongInt(@CompM));
  MatMul(LongInt(@CompM), LongInt(@Gps[K].Dv), LongInt(@CompM));
End;

{ page -> peripherique et inverse }
Procedure PageDev(K, X, Y : LongInt; Var DX, DY : LongInt);
Begin
  If (Gps[K].PgW <= 0) Or (Gps[K].PgH <= 0) Then
  Begin
    DX := X; DY := Y;
  End
  Else
  Begin
    DX := Gps[K].Vx1 + MulDiv(X, Gps[K].Vx2 - Gps[K].Vx1, Gps[K].PgW);
    DY := Gps[K].Vy1 + MulDiv(Y, Gps[K].Vy2 - Gps[K].Vy1, Gps[K].PgH);
  End;
End;

Procedure DevPage(K, X, Y : LongInt; Var PX, PY : LongInt);
Begin
  If (Gps[K].PgW <= 0) Or (Gps[K].PgH <= 0) Or (Gps[K].Vx2 = Gps[K].Vx1) Or (Gps[K].Vy2 = Gps[K].Vy1) Then
  Begin
    PX := X; PY := Y;
  End
  Else
  Begin
    PX := MulDiv(X - Gps[K].Vx1, Gps[K].PgW, Gps[K].Vx2 - Gps[K].Vx1);
    PY := MulDiv(Y - Gps[K].Vy1, Gps[K].PgH, Gps[K].Vy2 - Gps[K].Vy1);
  End;
End;

{ monde -> peripherique (CompSet appele avant) }
Procedure XF(K, X, Y : LongInt; Var DX, DY : LongInt);
Var PX, PY : LongInt;
Begin
  MatPt(LongInt(@CompM), X, Y, PX, PY);
  PageDev(K, PX, PY, DX, DY);
End;

{ vecteur du monde -> vecteur du peripherique (sans translation), en
  16.16 }
Procedure XFVec(K, FX, FY : LongInt; Var DX, DY : LongInt);
Var PX, PY : LongInt;
Begin
  PX := FMul(FX, CompM[0]) + FMul(FY, CompM[3]);
  PY := FMul(FX, CompM[1]) + FMul(FY, CompM[4]);
  If (Gps[K].PgW > 0) And (Gps[K].PgH > 0) Then
  Begin
    PX := MulDiv(PX, Gps[K].Vx2 - Gps[K].Vx1, Gps[K].PgW);
    PY := MulDiv(PY, Gps[K].Vy2 - Gps[K].Vy1, Gps[K].PgH);
  End;
  DX := PX; DY := PY;
End;

{ --- espaces de coordonnees (GpiConvert) : 1 monde, 2 modele, 3 page
  par defaut, 4 page, 5 peripherique --- }
Procedure CvtUp(K, Sp, X, Y : LongInt; Var RX, RY : LongInt);
Begin
  Case Sp Of
    1 : MatPt(LongInt(@Gps[K].Mdl), X, Y, RX, RY);
    2 : MatPt(LongInt(@Gps[K].Vw), X, Y, RX, RY);
    3 : MatPt(LongInt(@Gps[K].Dv), X, Y, RX, RY);
    4 : PageDev(K, X, Y, RX, RY);
  Else
    Begin
      RX := X; RY := Y;
    End;
  End;
End;

Procedure CvtDown(K, Sp, X, Y : LongInt; Var RX, RY : LongInt);
Var Ok : Boolean;
Begin
  RX := X; RY := Y;
  Case Sp Of
    2 : Ok := InvPt(LongInt(@Gps[K].Mdl), X, Y, RX, RY);
    3 : Ok := InvPt(LongInt(@Gps[K].Vw), X, Y, RX, RY);
    4 : Ok := InvPt(LongInt(@Gps[K].Dv), X, Y, RX, RY);
    5 : DevPage(K, X, Y, RX, RY);
  End;
End;

Procedure Convert(K, Src, Dst, X, Y : LongInt; Var RX, RY : LongInt);
Var S : LongInt;
Begin
  S := Src;
  While S < Dst Do
  Begin
    CvtUp(K, S, X, Y, X, Y);
    Inc(S);
  End;
  While S > Dst Do
  Begin
    CvtDown(K, S, X, Y, X, Y);
    Dec(S);
  End;
  RX := X; RY := Y;
End;

{ --- espaces de presentation --- }
Function GpsIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $47500001;
  If (I < 0) Or (I >= MaxGPS) Then I := -1
  Else If (GpsUse[I] = 0) Or Not Alive(Gps[I].Pid) Then I := -1;
  GpsIdx := I;
End;

Function DefTabInit(T : LongInt) : LongInt;
Var I : LongInt;
Begin
  For I := 0 To 15 Do WrL(T + I * 4, DefTab[I]);
  DefTabInit := 16;
End;

{ taille du peripherique d'un DC }
Procedure DcSize(D : LongInt; Var W, H : LongInt);
Var B : LongInt;
Begin
  W := 640; H := 480;
  If (D >= 0) And (DcUse[D] <> 0) Then
  Begin
    If (DcType[D] = OD_MEMORY) And (DcBmp[D] >= 0) Then
    Begin
      W := BmCx[DcBmp[D]]; H := BmCy[DcBmp[D]];
    End
    Else If (DcType[D] = OD_DIRECT) Or (DcType[D] = OD_INFO) Or (DcType[D] = DCT_WINDOW) Then
    Begin
      Dummy := ScreenMode(W, H, B);
    End
    Else
    Begin
      W := DcW[D]; H := DcH[D];
    End;
  End;
End;

{ pels par metre de l'unite de page (0 : pels) }
Function UnitsPerM(U : LongInt) : LongInt;
Begin
  Case U And $1C Of
    $0C : UnitsPerM := 10000;
    $10 : UnitsPerM := 100000;
    $14 : UnitsPerM := 3937;
    $18 : UnitsPerM := 39370;
    $1C : UnitsPerM := 56693;
  Else
    UnitsPerM := 0;
  End;
End;

{ cloture de la page selon les unites }
Procedure ViewportDefault(K : LongInt);
Var W, H, U : LongInt;
Begin
  DcSize(Gps[K].Dc, W, H);
  U := Gps[K].Units And $1C;
  If Gps[K].PgW <= 0 Then
  Begin
    If UnitsPerM(U) > 0 Then
    Begin
      Gps[K].PgW := MulDiv(W, UnitsPerM(U), 3780); Gps[K].PgH := MulDiv(H, UnitsPerM(U), 3780);
    End
    Else
    Begin
      Gps[K].PgW := W; Gps[K].PgH := H;
    End;
  End;
  Gps[K].Vx1 := 0; Gps[K].Vy1 := 0;
  If UnitsPerM(U) > 0 Then
  Begin
    Gps[K].Vx2 := MulDiv(Gps[K].PgW, 3780, UnitsPerM(U));
    Gps[K].Vy2 := MulDiv(Gps[K].PgH, 3780, UnitsPerM(U));
  End
  Else If U = 4 Then
  Begin
    { unites arbitraires : la page remplit le peripherique (proportions gardees) }
    If MulDiv(W, Gps[K].PgH, Gps[K].PgW) <= H Then
    Begin
      Gps[K].Vx2 := W; Gps[K].Vy2 := MulDiv(W, Gps[K].PgH, Gps[K].PgW);
    End
    Else
    Begin
      Gps[K].Vy2 := H; Gps[K].Vx2 := MulDiv(H, Gps[K].PgW, Gps[K].PgH);
    End;
  End
  Else
  Begin
    Gps[K].Vx2 := Gps[K].PgW; Gps[K].Vy2 := Gps[K].PgH;
  End;
  If Gps[K].Vx2 = 0 Then Gps[K].Vx2 := 1;
  If Gps[K].Vy2 = 0 Then Gps[K].Vy2 := 1;
End;

{ boite des caracteres par defaut (8 x 16 pels) en unites de page, 16.16 }
Procedure DefCharBox(K : LongInt; Var CX, CY : LongInt);
Var X, Y : LongInt;
Begin
  DevPage(K, Gps[K].Vx1 + 8, Gps[K].Vy1 + 16, X, Y);
  If X <= 0 Then X := 1;
  If Y <= 0 Then Y := 1;
  CX := X Shl 16; CY := Y Shl 16;
End;

Procedure AttrDefaults(K : LongInt);
Var Cx, Cy : LongInt;
Begin
  Gps[K].LColor := CLR_DEFAULT; Gps[K].LBack := CLR_DEFAULT; Gps[K].LMix := 0; Gps[K].LBMix := 0;
  Gps[K].LWidth := $10000; Gps[K].LGeom := 1; Gps[K].LType := 0; Gps[K].LEnd := 0; Gps[K].LJoin := 0;
  Gps[K].CColor := CLR_DEFAULT; Gps[K].CBack := CLR_DEFAULT; Gps[K].CMix := 0; Gps[K].CBMix := 0;
  Gps[K].CSet := 0; Gps[K].CMode := 0;
  DefCharBox(K, Cx, Cy);
  Gps[K].CBoxX := Cx; Gps[K].CBoxY := Cy;
  Gps[K].CAngX := 1; Gps[K].CAngY := 0; Gps[K].CShX := 0; Gps[K].CShY := 1;
  Gps[K].CDir := 1; Gps[K].CAlignH := 1; Gps[K].CAlignV := 1; Gps[K].CExtra := 0; Gps[K].CBreak := 0;
  Gps[K].MColor := CLR_DEFAULT; Gps[K].MBack := CLR_DEFAULT; Gps[K].MMix := 0; Gps[K].MBMix := 0;
  Gps[K].MSet := 0; Gps[K].MSym := 0; Gps[K].MBoxX := Cx; Gps[K].MBoxY := Cx;
  Gps[K].AColor := CLR_DEFAULT; Gps[K].ABack := CLR_DEFAULT; Gps[K].AMix := 0; Gps[K].ABMix := 0;
  Gps[K].PSet := 0; Gps[K].PSym := 0; Gps[K].PRefX := 0; Gps[K].PRefY := 0;
  Gps[K].IColor := CLR_DEFAULT; Gps[K].IBack := CLR_DEFAULT; Gps[K].IMix := 0; Gps[K].IBMix := 0;
  Gps[K].X[gxArcP] := Gps[K].X[gxDefArcP]; Gps[K].X[gxArcQ] := Gps[K].X[gxDefArcQ]; Gps[K].X[gxArcR] := Gps[K].X[gxDefArcR];
  Gps[K].X[gxArcS] := Gps[K].X[gxDefArcS];
  Gps[K].X[gxTag] := Gps[K].X[gxDefTag];
  Gps[K].X[gxLsCtr] := 0;
End;

Procedure InitPs(K, D, Units, W, H : LongInt);
Var I : LongInt;
Begin
  MemZero(LongInt(@Gps[K]), SizeOf(TGps));
  Gps[K].Pid := MyPid; Gps[K].Dc := D; Gps[K].Units := Units; Gps[K].PgW := W; Gps[K].PgH := H;
  Gps[K].PmHps := 0;
  ViewportDefault(K);
  MatIdent(LongInt(@Gps[K].Mdl)); MatIdent(LongInt(@Gps[K].Vw)); MatIdent(LongInt(@Gps[K].Dv));
  Gps[K].X[gxDefArcP] := 1; Gps[K].X[gxDefArcQ] := 1; Gps[K].X[gxDefArcR] := 0; Gps[K].X[gxDefArcS] := 0;
  Gps[K].X[gxDefTag] := 0;
  AttrDefaults(K);
  Gps[K].X[gxAttrMode] := 1; Gps[K].X[gxDrawMode] := DM_DRAW; Gps[K].X[gxEditMode] := 1;
  For I := 0 To 7 Do Gps[K].X[gxDCtl + I] := 0;
  Gps[K].X[gxDCtl + 1] := 0; Gps[K].X[gxDCtl + 2] := 1;
  Gps[K].X[gxClipRgn] := -1; Gps[K].X[gxClipPath] := -1;
  Gps[K].X[gxLogMode] := 0;
  Gps[K].X[gxLogTab] := MemAlloc(1024);
  Gps[K].X[gxLogN] := DefTabInit(Gps[K].X[gxLogTab]);
  Gps[K].X[gxCp] := 850;
  Gps[K].X[gxPickW] := 2; Gps[K].X[gxPickH] := 2;
  Gps[K].X[gxAttrStk] := MemAlloc(4096);
  Gps[K].X[gxSaveStk] := MemAlloc(MaxPrev * SizeOf(TGps) + 16);
  Gps[K].X[gxLcids] := MemAlloc(MaxLcid * 48);
  Gps[K].CurX := 0; Gps[K].CurY := 0;
  For I := 0 To 15 Do SegInit[K * 16 + I] := 0;
  SegInit[K * 16 + 2] := 1; SegInit[K * 16 + 6] := 1;
End;

Function NewPs : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxGPS - 1 DownTo 0 Do
    If (GpsUse[I] = 0) Or Not Alive(Gps[I].Pid) Then F := I;
  If (F >= 0) And (GpsUse[F] <> 0) Then
  Begin
    MemFree(Gps[F].X[gxLogTab]); MemFree(Gps[F].X[gxAttrStk]); MemFree(Gps[F].X[gxSaveStk]); MemFree(Gps[F].X[gxLcids]);
  End;
  If F >= 0 Then GpsUse[F] := 1;
  NewPs := F;
End;

{ espace de presentation (les HPS de PMWIN sont acceptes) ; -1 : erreur }
Function PsK(H : LongInt) : LongInt;
Var I, K : LongInt; Info : Array[0..7] Of LongInt;
Begin
  K := GpsIdx(H);
  If (K < 0) And ((H And $FFFF0000) = $50530000) Then
  Begin
    For I := MaxGPS - 1 DownTo 0 Do
      If (GpsUse[I] <> 0) And (Gps[I].PmHps = H) And (Gps[I].Pid = MyPid) Then K := I;
    If (K < 0) And PmInfo(H, LongInt(@Info)) Then
    Begin
      K := NewPs;
      If K >= 0 Then
      Begin
        InitPs(K, -1, 8, Info[5] - Info[3], Info[6] - Info[4]);
        Gps[K].PmHps := H;
        Gps[K].PgW := 640; Gps[K].PgH := 480;
        Gps[K].Vx1 := 0; Gps[K].Vy1 := 0; Gps[K].Vx2 := 640; Gps[K].Vy2 := 480;
      End;
    End;
  End;
  If K < 0 Then SetErr(PMERR_INV_HPS);
  PsK := K;
End;

{ --- regions : rectangles en pels du peripherique (x2, y2 exclus) --- }
Function RgIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $47520001;
  If (I < 0) Or (I >= MaxRgn) Then I := -1
  Else If (RgUse[I] = 0) Or Not Alive(RgPid[I]) Then I := -1;
  RgIdx := I;
End;

Function NewRgn : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxRgn - 1 DownTo 0 Do
    If (RgUse[I] = 0) Or Not Alive(RgPid[I]) Then F := I;
  If F >= 0 Then
  Begin
    If RgUse[F] <> 0 Then MemFree(RgData[F]);
    RgUse[F] := 1; RgPid[F] := MyPid; RgN[F] := 0; RgCap[F] := 0; RgData[F] := 0;
  End;
  NewRgn := F;
End;

{ ajouter un rectangle a la region R }
Procedure RgAdd(R, X1, Y1, X2, Y2 : LongInt);
Var P, C : LongInt;
Begin
  If (X1 >= X2) Or (Y1 >= Y2) Then Exit;
  If RgN[R] >= RgCap[R] Then
  Begin
    C := MaxI(16, RgCap[R] * 2);
    P := MemAlloc(C * 16);
    If P = 0 Then Exit;
    If RgData[R] <> 0 Then
    Begin
      MemMove(RgData[R], P, RgN[R] * 16);
      MemFree(RgData[R]);
    End;
    RgData[R] := P; RgCap[R] := C;
  End;
  P := RgData[R] + RgN[R] * 16;
  WrL(P, X1); WrL(P + 4, Y1); WrL(P + 8, X2); WrL(P + 12, Y2);
  Inc(RgN[R]);
End;

Function RgHas(R, X, Y : LongInt) : Boolean;
Var J, A : LongInt; Ok : Boolean;
Begin
  Ok := False;
  J := 0;
  While (J < RgN[R]) And Not Ok Do
  Begin
    A := RgData[R] + J * 16;
    If (X >= RdL(A)) And (X < RdL(A + 8)) And (Y >= RdL(A + 4)) And (Y < RdL(A + 12)) Then Ok := True;
    Inc(J);
  End;
  RgHas := Ok;
End;

{ boite d'une region ; faux si elle est vide }
Function RgBox(R : LongInt; Var X1, Y1, X2, Y2 : LongInt) : Boolean;
Var J, A : LongInt;
Begin
  X1 := 0; Y1 := 0; X2 := 0; Y2 := 0;
  For J := 0 To RgN[R] - 1 Do
  Begin
    A := RgData[R] + J * 16;
    If J = 0 Then
    Begin
      X1 := RdL(A); Y1 := RdL(A + 4); X2 := RdL(A + 8); Y2 := RdL(A + 12);
    End
    Else
    Begin
      X1 := MinI(X1, RdL(A)); Y1 := MinI(Y1, RdL(A + 4)); X2 := MaxI(X2, RdL(A + 8)); Y2 := MaxI(Y2, RdL(A + 12));
    End;
  End;
  RgBox := RgN[R] > 0;
End;

{ bords tries sans doublons }
Procedure EdgeAdd(T : LongInt; Var N : LongInt; V : LongInt);
Var I, J : LongInt; Found : Boolean;
Begin
  Found := False;
  For I := 0 To N - 1 Do
    If RdL(T + I * 4) = V Then Found := True;
  If Found Or (N >= 1024) Then Exit;
  I := N;
  While (I > 0) And (RdL(T + (I - 1) * 4) > V) Do
  Begin
    WrL(T + I * 4, RdL(T + (I - 1) * 4));
    Dec(I);
  End;
  WrL(T + I * 4, V);
  Inc(N);
  J := 0;
End;

{ combiner A et B dans D : 1 OU, 2 copie, 4 OU exclusif, 6 ET, 7 A sauf
  B ; rend la complexite (1 vide, 2 rectangle, 3 complexe) }
Function RgCombine(D, A, B, Op : LongInt) : LongInt;
Var Xs, Ys, NX, NY, I, J, X0, A1, B1, R, T, S : LongInt; InA, InB, In1 : Boolean;
Begin
  T := NewRgn;
  If T < 0 Then
  Begin
    RgCombine := 0;
    Exit;
  End;
  Xs := MemAlloc(4096); Ys := MemAlloc(4096);
  NX := 0; NY := 0;
  For I := 0 To RgN[A] - 1 Do
  Begin
    S := RgData[A] + I * 16;
    EdgeAdd(Xs, NX, RdL(S)); EdgeAdd(Xs, NX, RdL(S + 8)); EdgeAdd(Ys, NY, RdL(S + 4)); EdgeAdd(Ys, NY, RdL(S + 12));
  End;
  If (Op <> 2) And (B >= 0) Then
    For I := 0 To RgN[B] - 1 Do
    Begin
      S := RgData[B] + I * 16;
      EdgeAdd(Xs, NX, RdL(S)); EdgeAdd(Xs, NX, RdL(S + 8)); EdgeAdd(Ys, NY, RdL(S + 4)); EdgeAdd(Ys, NY, RdL(S + 12));
    End;
  For J := 0 To NY - 2 Do
  Begin
    X0 := -1;
    For I := 0 To NX - 2 Do
    Begin
      A1 := RdL(Xs + I * 4); B1 := RdL(Ys + J * 4);
      InA := RgHas(A, A1, B1);
      InB := False;
      If (Op <> 2) And (B >= 0) Then InB := RgHas(B, A1, B1);
      Case Op Of
        1 : In1 := InA Or InB;
        4 : In1 := InA Xor InB;
        6 : In1 := InA And InB;
        7 : In1 := InA And Not InB;
      Else
        In1 := InA;
      End;
      If In1 And (X0 < 0) Then X0 := A1;
      If (Not In1) And (X0 >= 0) Then
      Begin
        RgAdd(T, X0, B1, A1, RdL(Ys + (J + 1) * 4));
        X0 := -1;
      End;
    End;
    If X0 >= 0 Then RgAdd(T, X0, RdL(Ys + J * 4), RdL(Xs + (NX - 1) * 4), RdL(Ys + (J + 1) * 4));
  End;
  MemFree(Xs); MemFree(Ys);
  { fusion verticale des rectangles identiques en x }
  I := 0;
  While I < RgN[T] Do
  Begin
    J := I + 1;
    R := 0;
    While J < RgN[T] Do
    Begin
      S := RgData[T];
      If (RdL(S + J * 16) = RdL(S + I * 16)) And (RdL(S + J * 16 + 8) = RdL(S + I * 16 + 8)) And
         (RdL(S + J * 16 + 4) = RdL(S + I * 16 + 12)) Then
      Begin
        WrL(S + I * 16 + 12, RdL(S + J * 16 + 12));
        MemMove(S + (J + 1) * 16, S + J * 16, (RgN[T] - J - 1) * 16);
        Dec(RgN[T]);
      End
      Else Inc(J);
    End;
    Inc(I);
  End;
  { resultat dans D }
  If RgData[D] <> 0 Then MemFree(RgData[D]);
  RgData[D] := RgData[T]; RgN[D] := RgN[T]; RgCap[D] := RgCap[T];
  RgUse[T] := 0; RgData[T] := 0;
  If RgN[D] = 0 Then RgCombine := 1
  Else If RgN[D] = 1 Then RgCombine := 2
  Else RgCombine := 3;
End;

{ region de rectangles du monde (RECTL) de l'espace K }
Procedure RgFromRects(K, R, N, P : LongInt);
Var I, X1, Y1, X2, Y2, A, B, C, D, T : LongInt;
Begin
  If RgData[R] <> 0 Then MemFree(RgData[R]);
  RgData[R] := 0; RgN[R] := 0; RgCap[R] := 0;
  CompSet(K);
  T := NewRgn;
  If T < 0 Then Exit;
  For I := 0 To N - 1 Do
  Begin
    XF(K, RdL(P + I * 16), RdL(P + I * 16 + 4), A, B);
    XF(K, RdL(P + I * 16 + 8), RdL(P + I * 16 + 12), C, D);
    X1 := MinI(A, C); X2 := MaxI(A, C); Y1 := MinI(B, D); Y2 := MaxI(B, D);
    If RgN[R] = 0 Then RgAdd(R, X1, Y1, X2, Y2)
    Else
    Begin
      RgN[T] := 0;
      RgAdd(T, X1, Y1, X2, Y2);
      Dummy := RgCombine(R, R, T, 1);
    End;
  End;
  If RgData[T] <> 0 Then MemFree(RgData[T]);
  RgUse[T] := 0;
End;

{ limites de vue et champ graphique : restreindre le decoupage }
Procedure LimitClip(K : LongInt);
Var M : Array[0..8] Of LongInt; A, B, C, D, X1, Y1, X2, Y2 : LongInt;
Begin
  If Gps[K].X[gxVlOn] <> 0 Then
  Begin
    MatMul(LongInt(@Gps[K].Vw), LongInt(@Gps[K].Dv), LongInt(@M));
    MatPt(LongInt(@M), Gps[K].X[gxVlX1], Gps[K].X[gxVlY1], A, B);
    PageDev(K, A, B, X1, Y1);
    MatPt(LongInt(@M), Gps[K].X[gxVlX2], Gps[K].X[gxVlY2], C, D);
    PageDev(K, C, D, X2, Y2);
    ClipRect(MinI(X1, X2) + TgOffX, MinI(Y1, Y2) + TgOffY, MaxI(X1, X2) + 1 + TgOffX, MaxI(Y1, Y2) + 1 + TgOffY);
  End;
  If Gps[K].X[gxGfOn] <> 0 Then
  Begin
    PageDev(K, Gps[K].X[gxGfX1], Gps[K].X[gxGfY1], X1, Y1);
    PageDev(K, Gps[K].X[gxGfX2], Gps[K].X[gxGfY2], X2, Y2);
    ClipRect(MinI(X1, X2) + TgOffX, MinI(Y1, Y2) + TgOffY, MaxI(X1, X2) + 1 + TgOffX, MaxI(Y1, Y2) + 1 + TgOffY);
  End;
End;


{ ==================================================================== }
{ Partie 4 - Trace : lignes, polygones, courbes, marqueurs, texte       }
{ ==================================================================== }


Const
  LinePat : Array[0..9] Of LongInt = ($FFFF, $AAAA, $F0F0, $FE20, $A0A0, $FFF0, $FE28, $FFFF, $0000, $AAAA);

{ --- points du monde --- }
Procedure WPut(X, Y : LongInt);
Begin
  If WN < 4096 Then
  Begin
    WX[WN] := X; WY[WN] := Y;
    Inc(WN);
  End;
End;

{ --- lignes du peripherique --- }
Procedure BrushPix(X, Y, V, Mx : LongInt);
Var I, J, H : LongInt;
Begin
  If BrushW <= 1 Then DPix(X, Y, V, Mx)
  Else
  Begin
    H := BrushW Div 2;
    For I := 0 To BrushW - 1 Do
      For J := 0 To BrushW - 1 Do DPix(X - H + I, Y - H + J, V, Mx);
  End;
End;

{ ligne de (X1, Y1) a (X2, Y2) ; le motif de ligne se poursuit d'une ligne
  a l'autre (LsCtr) ; Skip : sans le premier pel }
Procedure DLine(K, X1, Y1, X2, Y2, V, Bk, Mx, BMx, Pat : LongInt; Skip : Boolean);
Var Dx, Dy, Sx, Sy, Er, E2, N : LongInt; First : Boolean;
Begin
  Dx := AbsI(X2 - X1); Dy := -AbsI(Y2 - Y1);
  If X1 < X2 Then Sx := 1 Else Sx := -1;
  If Y1 < Y2 Then Sy := 1 Else Sy := -1;
  Er := Dx + Dy;
  First := True; N := 0;
  While N < 100000 Do
  Begin
    If Not (First And Skip) Then
    Begin
      If ((Pat Shr (15 - (Gps[K].X[gxLsCtr] And 15))) And 1) <> 0 Then BrushPix(X1, Y1, V, Mx)
      Else If (BMx <> 0) And (BMx <> FM_LEAVEALONE) Then BrushPix(X1, Y1, Bk, BMx);
      Inc(Gps[K].X[gxLsCtr]);
    End;
    First := False;
    If (X1 = X2) And (Y1 = Y2) Then N := 100000
    Else
    Begin
      E2 := 2 * Er;
      If E2 >= Dy Then
      Begin
        Er := Er + Dy; X1 := X1 + Sx;
      End;
      If E2 <= Dx Then
      Begin
        Er := Er + Dx; Y1 := Y1 + Sy;
      End;
    End;
    Inc(N);
  End;
End;

{ trait des lignes du peripherique DXs/DYs (0 a N-1) avec les attributs
  de ligne de l'espace K }
Procedure StrokeDev(K, N : LongInt; Closed : Boolean);
Var I, V, Bk, Mx, BMx, Pat, T : LongInt;
Begin
  If N < 1 Then Exit;
  V := ClrDev(K, Gps[K].LColor, False);
  Bk := ClrDev(K, Gps[K].LBack, True);
  Mx := Gps[K].LMix;
  If Mx = 0 Then Mx := FM_OVERPAINT;
  BMx := Gps[K].LBMix;
  T := Gps[K].LType;
  If (T < 0) Or (T > 9) Then T := 0;
  Pat := LinePat[T];
  If T = 8 Then Exit;
  If BrushW <= 0 Then BrushW := MaxI(1, Gps[K].LWidth Shr 16);
  If N = 1 Then DLine(K, DXs[0], DYs[0], DXs[0], DYs[0], V, Bk, Mx, BMx, Pat, False);
  For I := 1 To N - 1 Do DLine(K, DXs[I - 1], DYs[I - 1], DXs[I], DYs[I], V, Bk, Mx, BMx, Pat, I > 1);
  If Closed And (N > 2) Then DLine(K, DXs[N - 1], DYs[N - 1], DXs[0], DYs[0], V, Bk, Mx, BMx, Pat, True);
End;

{ --- figures (zones et chemins) --- }
Procedure FigNew(X, Y : LongInt);
Begin
  If FgCnt >= 255 Then Exit;
  If (FgCnt > 0) And (FgStart[FgCnt - 1] = FgN - 1) Then
  Begin
    FgX[FgN - 1] := X; FgY[FgN - 1] := Y;
    Exit;
  End;
  FgStart[FgCnt] := FgN; FgClosed[FgCnt] := 0;
  Inc(FgCnt);
  If FgN < 4096 Then
  Begin
    FgX[FgN] := X; FgY[FgN] := Y;
    Inc(FgN);
  End;
End;

Procedure FigAdd(X, Y : LongInt);
Begin
  If FgCnt = 0 Then FigNew(X, Y)
  Else If FgN < 4096 Then
  Begin
    FgX[FgN] := X; FgY[FgN] := Y;
    Inc(FgN);
  End;
End;

{ remplir des figures (sommets Xa/Ya, debuts St, NF figures, NT sommets)
  par balayage : pair-impair ou enroulement }
Procedure PolyFillDev(K, Xa, Ya, St, NF, NT : LongInt; Winding : Boolean; Fg, Bg, Mx, BMx : LongInt);
Var F, I, J, A, B, E, N, Y, Y1, Y2, X1, X2, Ymin, Ymax, T, D, W, Xs : LongInt;
Begin
  If NT < 2 Then Exit;
  Ymin := RdL(Ya); Ymax := Ymin;
  For I := 0 To NT - 1 Do
  Begin
    Ymin := MinI(Ymin, RdL(Ya + I * 4)); Ymax := MaxI(Ymax, RdL(Ya + I * 4));
  End;
  If Ymax - Ymin > 4096 Then Ymax := Ymin + 4096;
  For Y := Ymin To Ymax Do
  Begin
    N := 0;
    For F := 0 To NF - 1 Do
    Begin
      A := RdL(St + F * 4);
      If F < NF - 1 Then B := RdL(St + (F + 1) * 4) Else B := NT;
      For I := A To B - 1 Do
      Begin
        If I = B - 1 Then J := A Else J := I + 1;
        Y1 := RdL(Ya + I * 4); Y2 := RdL(Ya + J * 4);
        If ((2 * Y1 <= 2 * Y + 1) And (2 * Y + 1 < 2 * Y2)) Or ((2 * Y2 <= 2 * Y + 1) And (2 * Y + 1 < 2 * Y1)) Then
          If N < 2048 Then
          Begin
            X1 := RdL(Xa + I * 4); X2 := RdL(Xa + J * 4);
            XC[N] := X1 * 2 + MulDiv(2 * Y + 1 - 2 * Y1, 2 * (X2 - X1), 2 * (Y2 - Y1));
            If Y2 > Y1 Then XD[N] := 1 Else XD[N] := -1;
            Inc(N);
          End;
      End;
    End;
    { tri }
    For I := 1 To N - 1 Do
    Begin
      T := XC[I]; D := XD[I]; J := I;
      While (J > 0) And (XC[J - 1] > T) Do
      Begin
        XC[J] := XC[J - 1]; XD[J] := XD[J - 1];
        Dec(J);
      End;
      XC[J] := T; XD[J] := D;
    End;
    If Winding Then
    Begin
      W := 0; Xs := 0;
      For I := 0 To N - 1 Do
      Begin
        If W = 0 Then Xs := XC[I];
        W := W + XD[I];
        If W = 0 Then DSpan(Xs Div 2, XC[I] Div 2, Y, Fg, Bg, Mx, BMx);
      End;
    End
    Else
    Begin
      I := 0;
      While I + 1 < N Do
      Begin
        DSpan(XC[I] Div 2, XC[I + 1] Div 2, Y, Fg, Bg, Mx, BMx);
        I := I + 2;
      End;
    End;
  End;
  E := 0;
End;

{ couleurs et melanges de zone de l'espace K }
Procedure AreaFill(K, Xa, Ya, St, NF, NT : LongInt; Winding : Boolean);
Var Mx, BMx : LongInt;
Begin
  PatPrepare(K);
  Mx := Gps[K].AMix;
  If Mx = 0 Then Mx := FM_OVERPAINT;
  BMx := Gps[K].ABMix;
  If BMx = 0 Then BMx := FM_LEAVEALONE;
  PolyFillDev(K, Xa, Ya, St, NF, NT, Winding, ClrDev(K, Gps[K].AColor, False), ClrDev(K, Gps[K].ABack, True), Mx, BMx);
End;

{ --- sortie d'une primitive : points du monde WX/WY (le premier est la
  position courante) ; dans une zone ou un chemin, les points s'ajoutent
  a la figure ; sinon ils sont traces --- }
Procedure EmitWorld(K : LongInt; NewFig, Draw : Boolean);
Var I : LongInt;
Begin
  If WN = 0 Then Exit;
  CompSet(K);
  For I := 0 To WN - 1 Do XF(K, WX[I], WY[I], DXs[I], DYs[I]);
  If (Gps[K].X[gxInArea] <> 0) Or (Gps[K].X[gxInPath] <> 0) Then
  Begin
    If NewFig Or (FgCnt = 0) Then FigNew(DXs[0], DYs[0]);
    For I := 1 To WN - 1 Do FigAdd(DXs[I], DYs[I]);
  End
  Else If Draw Then
  Begin
    If BeginDraw(K) Then
    Begin
      BrushW := 0;
      StrokeDev(K, WN, False);
    End;
  End;
  Gps[K].CurX := WX[WN - 1]; Gps[K].CurY := WY[WN - 1];
End;

{ --- courbes (points du monde ajoutes a WX/WY) --- }
{ arc d'ellipse des parametres d'arc : centre (Cx, Cy), multiplicateur
  (16.16), angle de depart et ouverture en 1024e de tour (ouverture
  negative : sens horaire) }
Procedure ArcPts(K, Cx, Cy, Mult, A0, Sweep : LongInt);
Var N, I, A, C, S, VX, VY, R : LongInt;
Begin
  R := FMul(AbsI(Gps[K].X[gxArcP]) + AbsI(Gps[K].X[gxArcQ]) + AbsI(Gps[K].X[gxArcR]) + AbsI(Gps[K].X[gxArcS]), Mult);
  N := MaxI(8, MinI(256, R Div 2));
  N := MaxI(1, MulDiv(N, AbsI(Sweep), 1024));
  For I := 0 To N Do
  Begin
    A := A0 + MulDiv(Sweep, I, N);
    C := CosA(A); S := SinA(A);
    VX := Gps[K].X[gxArcP] * C + Gps[K].X[gxArcR] * S;
    VY := Gps[K].X[gxArcS] * C + Gps[K].X[gxArcQ] * S;
    WPut(Cx + FRound(FMul(VX, Mult)), Cy + FRound(FMul(VY, Mult)));
  End;
End;

{ courbe de Bezier cubique de (X0, Y0) par deux points de controle }
Procedure BezPts(X0, Y0, X1, Y1, X2, Y2, X3, Y3 : LongInt);
Var I, N, T, U, A, B, C, D : LongInt;
Begin
  N := MaxI(8, MinI(64, (AbsI(X3 - X0) + AbsI(Y3 - Y0) + AbsI(X1 - X0) + AbsI(Y2 - Y3)) Div 4));
  For I := 1 To N Do
  Begin
    T := MulDiv(I, 65536, N); U := 65536 - T;
    A := FMul(FMul(U, U), U); B := 3 * FMul(FMul(U, U), T); C := 3 * FMul(FMul(U, T), T); D := FMul(FMul(T, T), T);
    WPut(FRound(X0 * A + X1 * B + X2 * C + X3 * D), FRound(Y0 * A + Y1 * B + Y2 * C + Y3 * D));
  End;
End;

{ conique (Bezier quadratique rationnelle de poids W, 16.16) }
Procedure ConicPts(X0, Y0, X1, Y1, X2, Y2, W : LongInt);
Var I, N, T, U, A, B, C, Den : LongInt;
Begin
  N := MaxI(8, MinI(64, (AbsI(X2 - X0) + AbsI(Y2 - Y0) + AbsI(X1 - X0) + AbsI(Y1 - Y0)) Div 4));
  For I := 1 To N Do
  Begin
    T := MulDiv(I, 65536, N); U := 65536 - T;
    A := FMul(U, U); B := 2 * FMul(FMul(U, T), W); C := FMul(T, T);
    Den := A + B + C;
    If Den = 0 Then Den := 1;
    WPut(MulDiv(X0, A, Den) + MulDiv(X1, B, Den) + MulDiv(X2, C, Den),
         MulDiv(Y0, A, Den) + MulDiv(Y1, B, Den) + MulDiv(Y2, C, Den));
  End;
End;

{ ligne horizontale pleine }
Procedure DSpanSolid(X1, X2, Y, V, Mx : LongInt);
Begin
  PatOn := 0;
  DSpan(X1, X2, Y, V, 0, Mx, FM_LEAVEALONE);
End;

{ --- marqueurs (centre en pels du peripherique, demi-taille Hx, Hy) --- }
Procedure MarkLine(K, X1, Y1, X2, Y2, V, Mx : LongInt);
Begin
  DLine(K, X1, Y1, X2, Y2, V, 0, Mx, 0, $FFFF, False);
End;

Procedure DrawMarker(K, X, Y, Hx, Hy : LongInt);
Var V, Mx, S, I, J, R : LongInt;
Begin
  V := ClrDev(K, Gps[K].MColor, False);
  Mx := Gps[K].MMix;
  If Mx = 0 Then Mx := FM_OVERPAINT;
  S := Gps[K].MSym;
  If S = 0 Then S := 1;
  Hx := MaxI(1, Hx); Hy := MaxI(1, Hy);
  BrushW := 1;
  Case S Of
    1 :
      Begin
        MarkLine(K, X - Hx, Y - Hy, X + Hx, Y + Hy, V, Mx); MarkLine(K, X - Hx, Y + Hy, X + Hx, Y - Hy, V, Mx);
      End;
    2 :
      Begin
        MarkLine(K, X - Hx, Y, X + Hx, Y, V, Mx); MarkLine(K, X, Y - Hy, X, Y + Hy, V, Mx);
      End;
    3, 7 :
      Begin
        MarkLine(K, X - Hx, Y, X, Y + Hy, V, Mx); MarkLine(K, X, Y + Hy, X + Hx, Y, V, Mx);
        MarkLine(K, X + Hx, Y, X, Y - Hy, V, Mx); MarkLine(K, X, Y - Hy, X - Hx, Y, V, Mx);
        If S = 7 Then
          For J := -Hy To Hy Do
          Begin
            I := Hx - MulDiv(AbsI(J), Hx, Hy);
            DSpanSolid(X - I, X + I + 1, Y + J, V, Mx);
          End;
      End;
    4, 8 :
      Begin
        If S = 8 Then
        Begin
          For J := -Hy To Hy Do DSpanSolid(X - Hx, X + Hx + 1, Y + J, V, Mx);
        End
        Else
        Begin
          MarkLine(K, X - Hx, Y - Hy, X + Hx, Y - Hy, V, Mx); MarkLine(K, X + Hx, Y - Hy, X + Hx, Y + Hy, V, Mx);
          MarkLine(K, X + Hx, Y + Hy, X - Hx, Y + Hy, V, Mx); MarkLine(K, X - Hx, Y + Hy, X - Hx, Y - Hy, V, Mx);
        End;
      End;
    5 :
      Begin
        MarkLine(K, X, Y + Hy, X + Hx, Y - Hy Div 2, V, Mx); MarkLine(K, X + Hx, Y - Hy Div 2, X - Hx, Y - Hy Div 2, V, Mx);
        MarkLine(K, X - Hx, Y - Hy Div 2, X, Y + Hy, V, Mx);
        MarkLine(K, X, Y - Hy, X + Hx, Y + Hy Div 2, V, Mx); MarkLine(K, X + Hx, Y + Hy Div 2, X - Hx, Y + Hy Div 2, V, Mx);
        MarkLine(K, X - Hx, Y + Hy Div 2, X, Y - Hy, V, Mx);
      End;
    6 :
      Begin
        MarkLine(K, X - Hx, Y, X + Hx, Y, V, Mx); MarkLine(K, X, Y - Hy, X, Y + Hy, V, Mx);
        MarkLine(K, X - Hx, Y - Hy, X + Hx, Y + Hy, V, Mx); MarkLine(K, X - Hx, Y + Hy, X + Hx, Y - Hy, V, Mx);
      End;
    9 :
      For J := -1 To 0 Do DSpanSolid(X - 1, X + 1, Y + J, V, Mx);
    10 :
      For I := 0 To 31 Do
      Begin
        R := I * 32;
        MarkLine(K, X + FRound(FMul(Hx Shl 16, CosA(R))), Y + FRound(FMul(Hy Shl 16, SinA(R))),
                 X + FRound(FMul(Hx Shl 16, CosA(R + 32))), Y + FRound(FMul(Hy Shl 16, SinA(R + 32))), V, Mx);
      End;
  End;
End;

{ --- texte (police 8 x 16 du VGA ; ligne de base sous la ligne 11) --- }

{ vecteurs du caractere dans le monde (16.16) puis le peripherique }
Procedure CharVectors(K : LongInt);
Var Ax, Ay, L, Bx, By, Ux, Uy, Sx : LongInt;
Begin
  Ax := Gps[K].CAngX; Ay := Gps[K].CAngY;
  If (Ax = 0) And (Ay = 0) Then Ax := 1;
  L := ISqrt(MulDiv(Ax, Ax, 1) + MulDiv(Ay, Ay, 1));
  If (AbsI(Ax) > 30000) Or (AbsI(Ay) > 30000) Then
  Begin
    Ax := Ax Div 1024; Ay := Ay Div 1024;
    L := ISqrt(Ax * Ax + Ay * Ay);
  End;
  If L = 0 Then L := 1;
  { direction unitaire (16.16) }
  Ax := MulDiv(Ax, 65536, L); Ay := MulDiv(Ay, 65536, L);
  Bx := FMul(Ax, Gps[K].CBoxX); By := FMul(Ay, Gps[K].CBoxX);
  Ux := FMul(-Ay, Gps[K].CBoxY); Uy := FMul(Ax, Gps[K].CBoxY);
  { cisaillement : decalage selon la ligne de base par unite de hauteur }
  If Gps[K].CShY <> 0 Then
  Begin
    Sx := MulDiv(Gps[K].CShX, 65536, Gps[K].CShY);
    Ux := Ux + FMul(Bx, FMul(Sx, FDiv(Gps[K].CBoxY, MaxI(Gps[K].CBoxX, 1))));
    Uy := Uy + FMul(By, FMul(Sx, FDiv(Gps[K].CBoxY, MaxI(Gps[K].CBoxX, 1))));
  End;
  XFVec(K, Bx, By, TBx, TBy);
  XFVec(K, Ux, Uy, TUx, TUy);
End;

{ dessiner un caractere : origine (16.16, peripherique) }
Procedure DrawGlyph(K, Ch, Ox, Oy, V, Mx : LongInt);
Var Gx, Gy, Bits, Px, Py, Qx, Qy, I : LongInt; Fast : Boolean;
    Xs, Ys, Ss : Array[0..4] Of LongInt;
Begin
  Fast := (TBx = 8 * 65536) And (TBy = 0) And (TUx = 0) And (TUy = 16 * 65536);
  For Gy := 0 To 15 Do
  Begin
    Bits := FontBits[Ch * 16 + Gy];
    If Bits <> 0 Then
      For Gx := 0 To 7 Do
        If ((Bits Shr (7 - Gx)) And 1) <> 0 Then
        Begin
          If Fast Then DPix(FRound(Ox) + Gx, FRound(Oy) + 11 - Gy, V, Mx)
          Else
          Begin
            { coin du pel (Gx, Gy) : u = Gx / 8, v = (11 - Gy) / 16 }
            Px := Ox + MulDiv(TBx, Gx, 8) + MulDiv(TUx, 11 - Gy, 16);
            Py := Oy + MulDiv(TBy, Gx, 8) + MulDiv(TUy, 11 - Gy, 16);
            If (AbsI(TBx) + AbsI(TBy) <= 12 * 65536) And (AbsI(TUx) + AbsI(TUy) <= 24 * 65536) Then
              DPix(FRound(Px + TBx Div 16 + TUx Div 32), FRound(Py + TBy Div 16 + TUy Div 32), V, Mx)
            Else
            Begin
              Qx := Px + TBx Div 8; Qy := Py + TBy Div 8;
              Xs[0] := FRound(Px); Ys[0] := FRound(Py);
              Xs[1] := FRound(Qx); Ys[1] := FRound(Qy);
              Xs[2] := FRound(Qx + TUx Div 16); Ys[2] := FRound(Qy + TUy Div 16);
              Xs[3] := FRound(Px + TUx Div 16); Ys[3] := FRound(Py + TUy Div 16);
              Ss[0] := 0;
              PatOn := 0;
              PolyFillDev(K, LongInt(@Xs), LongInt(@Ys), LongInt(@Ss), 1, 4, False, V, 0, Mx, FM_LEAVEALONE);
              I := 0;
            End;
          End;
        End;
  End;
End;

{ largeur d'une chaine en pels du peripherique le long de la ligne de
  base (16.16) : vecteur dans TWx, TWy }

{ ecrire une chaine a la position (X, Y) du monde ; Adx : increments
  (CHS_VECTOR, unites du monde) ou 0 ; rend la position finale du monde }
Procedure DrawText(K, X, Y, P, N, Adx : LongInt; Draw : Boolean; Var EX, EY : LongInt);
Var I, Ch, Ox, Oy, V, Bk, Mx, BMx, Dx, Dy, Sx, Sy, Ax, Ay, Ex1, Ey1, Cw, Ch2, C, R, A, Fg : LongInt;
    Txt : Boolean; Qx, Qy, Qs : Array[0..4] Of LongInt;
Begin
  CompSet(K);
  CharVectors(K);
  XF(K, X, Y, Dx, Dy);
  Ox := Dx Shl 16; Oy := Dy Shl 16;
  { largeur totale }
  TWx := 0; TWy := 0;
  For I := 0 To N - 1 Do
  Begin
    TWx := TWx + TBx; TWy := TWy + TBy;
  End;
  { alignement }
  Case Gps[K].CAlignH Of
    3 :
      Begin
        Ox := Ox - TWx Div 2; Oy := Oy - TWy Div 2;
      End;
    4 :
      Begin
        Ox := Ox - TWx; Oy := Oy - TWy;
      End;
  End;
  Case Gps[K].CAlignV Of
    2 :
      Begin
        Ox := Ox - MulDiv(TUx, 12, 16); Oy := Oy - MulDiv(TUy, 12, 16);
      End;
    3 :
      Begin
        Ox := Ox - MulDiv(TUx, 4, 16); Oy := Oy - MulDiv(TUy, 4, 16);
      End;
    5 :
      Begin
        Ox := Ox + MulDiv(TUx, 4, 16); Oy := Oy + MulDiv(TUy, 4, 16);
      End;
  End;
  If Draw And BeginDraw(K) Then
  Begin
    V := ClrDev(K, Gps[K].CColor, False);
    Bk := ClrDev(K, Gps[K].CBack, True);
    Mx := Gps[K].CMix;
    If Mx = 0 Then Mx := FM_OVERPAINT;
    BMx := Gps[K].CBMix;
    If BMx = 0 Then BMx := FM_LEAVEALONE;
    Txt := TgKind = TG_TEXT;
    Fg := Nearest(LongInt(@Vga16), 16, ClrRgb(K, Gps[K].CColor, False));
    For I := 0 To N - 1 Do
    Begin
      Ch := RdB(P + I);
      If Txt Then
      Begin
        { mode texte : le caractere va dans la cellule }
        Sx := FRound(Ox + TUx Div 4) + TgOffX; Sy := FRound(Oy + TUy Div 4) + TgOffY;
        If InClip(Sx, Sy) And (RMode <> 2) Then
        Begin
          C := Sx Div 8; R := (TgH - 1 - Sy) Div 16;
          If (C >= 0) And (C < 80) And (R >= 0) And (R < 25) Then
          Begin
            A := $B8000 + (R * 80 + C) * 2;
            WrB(A, Ch);
            If BMx <> FM_LEAVEALONE Then WrB(A + 1, (Fg And 15) Or ((Bk And 7) Shl 4))
            Else WrB(A + 1, (RdB(A + 1) And $F0) Or (Fg And 15));
          End;
        End;
        BndAdd(FRound(Ox), FRound(Oy));
      End
      Else
      Begin
        If BMx <> FM_LEAVEALONE Then
        Begin
          PatOn := 0;
          { fond de la cellule : rectangle de la boite }
          Ex1 := Ox - MulDiv(TUx, 4, 16); Ey1 := Oy - MulDiv(TUy, 4, 16);
          Qx[0] := FRound(Ex1); Qy[0] := FRound(Ey1);
          Qx[1] := FRound(Ex1 + TBx); Qy[1] := FRound(Ey1 + TBy);
          Qx[2] := FRound(Ex1 + TBx + TUx); Qy[2] := FRound(Ey1 + TBy + TUy);
          Qx[3] := FRound(Ex1 + TUx); Qy[3] := FRound(Ey1 + TUy);
          Qs[0] := 0;
          PolyFillDev(K, LongInt(@Qx), LongInt(@Qy), LongInt(@Qs), 1, 4, False, Bk, 0, BMx, FM_LEAVEALONE);
        End;
        DrawGlyph(K, Ch, Ox, Oy, V, Mx);
      End;
      { avance }
      Ax := TBx; Ay := TBy;
      Case Gps[K].CDir Of
        3 :
          Begin
            Ax := -TBx; Ay := -TBy;
          End;
        2 :
          Begin
            Ax := -TUx; Ay := -TUy;
          End;
        4 :
          Begin
            Ax := TUx; Ay := TUy;
          End;
      End;
      Ox := Ox + Ax; Oy := Oy + Ay;
    End;
  End;
  { position finale du monde : depart + largeur }
  Cw := 0; Ch2 := 0;
  If Adx <> 0 Then
  Begin
    For I := 0 To N - 1 Do Cw := Cw + RdL(Adx + I * 4);
    EX := X + MulDiv(Cw, Gps[K].CAngX, MaxI(1, ISqrt(Gps[K].CAngX * Gps[K].CAngX + Gps[K].CAngY * Gps[K].CAngY)));
    EY := Y + MulDiv(Cw, Gps[K].CAngY, MaxI(1, ISqrt(Gps[K].CAngX * Gps[K].CAngX + Gps[K].CAngY * Gps[K].CAngY)));
  End
  Else
  Begin
    Sx := FRound(MulDiv(Gps[K].CBoxX, N, 1) + Gps[K].CExtra * N);
    Ax := Gps[K].CAngX; Ay := Gps[K].CAngY;
    R := ISqrt(MinI(Ax * Ax + Ay * Ay, 2000000000));
    If R = 0 Then R := 1;
    If Gps[K].CDir = 3 Then Sx := -Sx;
    EX := X + MulDiv(Sx, Ax, R); EY := Y + MulDiv(Sx, Ay, R);
    If (Gps[K].CDir = 2) Or (Gps[K].CDir = 4) Then
    Begin
      Sy := FRound(Gps[K].CBoxY * N);
      If Gps[K].CDir = 2 Then Sy := -Sy;
      EX := X - MulDiv(Sy, Ay, R); EY := Y + MulDiv(Sy, Ax, R);
    End;
  End;
  Ch2 := 0;
End;

{ --- remplissage par diffusion : depuis (X, Y) du peripherique ; Surf :
  la surface de la couleur C ; sinon jusqu'a la frontiere de couleur C --- }
Function FloodDev(K, X, Y, C : LongInt; Surf : Boolean) : LongInt;
Var Stk, Sp, Cap, A, X1, X2, Yy, Fg, Bg, Mx, BMx, V, N, Sx, Sy : LongInt; Ok : Boolean;
    Seen : LongInt;
Begin
  FloodDev := 0;
  If TgKind = TG_NONE Then Exit;
  Cap := 8192;
  Stk := MemAlloc(Cap * 8);
  Seen := BigAlloc(TgW * TgH Div 8 + 8);
  If (Stk = 0) Or (Seen = 0) Then
  Begin
    MemFree(Stk); BigFree(Seen);
    Exit;
  End;
  PatPrepare(K);
  Fg := ClrDev(K, Gps[K].AColor, False); Bg := ClrDev(K, Gps[K].ABack, True);
  Mx := Gps[K].AMix;
  If Mx = 0 Then Mx := FM_OVERPAINT;
  BMx := Gps[K].ABMix;
  If BMx = 0 Then BMx := FM_LEAVEALONE;
  Sp := 0;
  WrL(Stk, X); WrL(Stk + 4, Y); Sp := 1;
  N := 0;
  While (Sp > 0) And (N < 200000) Do
  Begin
    Inc(N);
    Dec(Sp);
    X := RdL(Stk + Sp * 8); Y := RdL(Stk + Sp * 8 + 4);
    Sx := X + TgOffX; Sy := Y + TgOffY;
    If InClip(Sx, Sy) Then
    Begin
      A := Sy * TgW + Sx;
      If (RdB(Seen + A Shr 3) And (1 Shl (A And 7))) = 0 Then
      Begin
        V := TgGet(Sx, Sy);
        If Surf Then Ok := V = C Else Ok := V <> C;
        If Ok Then
        Begin
          { etendre a gauche et a droite }
          X1 := X; X2 := X;
          While InClip(X1 - 1 + TgOffX, Sy) And ((TgGet(X1 - 1 + TgOffX, Sy) = C) = Surf) And
                ((RdB(Seen + (A - (X - X1) - 1) Shr 3) And (1 Shl ((A - (X - X1) - 1) And 7))) = 0) Do Dec(X1);
          While InClip(X2 + 1 + TgOffX, Sy) And ((TgGet(X2 + 1 + TgOffX, Sy) = C) = Surf) And
                ((RdB(Seen + (A + (X2 - X) + 1) Shr 3) And (1 Shl ((A + (X2 - X) + 1) And 7))) = 0) Do Inc(X2);
          For Yy := X1 To X2 Do
          Begin
            A := Sy * TgW + Yy + TgOffX;
            WrB(Seen + A Shr 3, RdB(Seen + A Shr 3) Or (1 Shl (A And 7)));
          End;
          DSpan(X1, X2 + 1, Y, Fg, Bg, Mx, BMx);
          FloodDev := 1;
          { lignes voisines }
          For Yy := X1 To X2 Do
            If Sp < Cap - 2 Then
            Begin
              WrL(Stk + Sp * 8, Yy); WrL(Stk + Sp * 8 + 4, Y + 1);
              WrL(Stk + Sp * 8 + 8, Yy); WrL(Stk + Sp * 8 + 12, Y - 1);
              Sp := Sp + 2;
            End;
        End;
      End;
    End;
  End;
  MemFree(Stk);
  BigFree(Seen);
End;


{ ==================================================================== }
{ Partie 5 - Enregistrement, espaces de presentation, attributs,        }
{ primitives, zones, chemins, texte                                     }
{ ==================================================================== }


Function HpsOf(K : LongInt) : LongInt;
Begin
  If Gps[K].PmHps <> 0 Then HpsOf := Gps[K].PmHps Else HpsOf := $47500001 + K;
End;

{ --- tampons d'elements : type (4), longueur des donnees (4), donnees
  (alignees sur 4) --- }
Function BufGrow(Var Buf, Len, Cap : LongInt; Need : LongInt) : Boolean;
Var P, C : LongInt;
Begin
  BufGrow := True;
  If Len + Need <= Cap Then Exit;
  C := MaxI(1024, Cap * 2);
  While C < Len + Need Do C := C * 2;
  P := MemAlloc(C);
  If P = 0 Then
  Begin
    BufGrow := False;
    Exit;
  End;
  If Buf <> 0 Then
  Begin
    MemMove(Buf, P, Len);
    MemFree(Buf);
  End;
  Buf := P; Cap := C;
End;

{ decalage de l'element numero N (1...) d'un tampon ; Len si absent }
Function ElemOfs(Buf, Len, N : LongInt) : LongInt;
Var O, I : LongInt;
Begin
  O := 0; I := 1;
  While (O < Len) And (I < N) Do
  Begin
    O := O + 8 + ((RdL(Buf + O + 4) + 3) And Not 3);
    Inc(I);
  End;
  ElemOfs := O;
End;

Function ElemCount(Buf, Len : LongInt) : LongInt;
Var O, N : LongInt;
Begin
  O := 0; N := 0;
  While O < Len Do
  Begin
    O := O + 8 + ((RdL(Buf + O + 4) + 3) And Not 3);
    Inc(N);
  End;
  ElemCount := N;
End;

{ inserer un element (type T, donnees D de L octets) a la position Pos
  (decalage) d'un tampon }
Function BufInsert(Var Buf, Len, Cap : LongInt; Pos, T, D, L : LongInt) : Boolean;
Var Sz : LongInt;
Begin
  BufInsert := False;
  Sz := 8 + ((L + 3) And Not 3);
  If Not BufGrow(Buf, Len, Cap, Sz) Then Exit;
  MemMove(Buf + Pos, Buf + Pos + Sz, Len - Pos);
  WrL(Buf + Pos, T); WrL(Buf + Pos + 4, L);
  MemZero(Buf + Pos + 8, Sz - 8);
  If L > 0 Then MemMove(D, Buf + Pos + 8, L);
  Len := Len + Sz;
  BufInsert := True;
End;

Procedure BufDelete(Buf : LongInt; Var Len : LongInt; Pos : LongInt);
Var Sz : LongInt;
Begin
  If Pos >= Len Then Exit;
  Sz := 8 + ((RdL(Buf + Pos + 4) + 3) And Not 3);
  MemMove(Buf + Pos + Sz, Buf + Pos, Len - Pos - Sz);
  Len := Len - Sz;
End;

Function SegIdx(K, Id : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxSeg - 1 DownTo 0 Do
    If (SgUse[I] <> 0) And (SgPs[I] = K) And (SgId[I] = Id) Then R := I;
  SegIdx := R;
End;

{ ajouter un element a la cible de l'espace K (segment ouvert ou
  metafichier) }
Function AddElem(K, T, D, L : LongInt) : Boolean;
Var S, Pos, M : LongInt;
Begin
  AddElem := False;
  If (Gps[K].Dc >= 0) And (DcUse[Gps[K].Dc] <> 0) And (DcMeta[Gps[K].Dc] >= 0) Then
  Begin
    M := DcMeta[Gps[K].Dc];
    AddElem := BufInsert(MfData[M], MfLen[M], MfCap[M], MfLen[M], T, D, L);
  End
  Else If (Gps[K].X[gxOpenSeg] <> 0) And ((Gps[K].X[gxDrawMode] And DM_RETAIN) <> 0) Then
  Begin
    S := SegIdx(K, Gps[K].X[gxOpenSeg]);
    If S < 0 Then Exit;
    Pos := ElemOfs(SgData[S], SgLen[S], Gps[K].X[gxElemPtr] + 1);
    If (Gps[K].X[gxEditMode] = 2) And (Gps[K].X[gxElemPtr] > 0) Then
    Begin
      Pos := ElemOfs(SgData[S], SgLen[S], Gps[K].X[gxElemPtr]);
      BufDelete(SgData[S], SgLen[S], Pos);
      Dec(Gps[K].X[gxElemPtr]);
    End;
    If BufInsert(SgData[S], SgLen[S], SgCap[S], Pos, T, D, L) Then
    Begin
      Inc(Gps[K].X[gxElemPtr]);
      AddElem := True;
    End;
  End;
End;

{ debut de l'enregistrement d'un appel }
Procedure RecI(E : LongInt);
Begin
  RecE := E; RecN := 0;
End;

Procedure RecL(V : LongInt);
Begin
  If RecN < 16 Then
  Begin
    RecV[RecN] := V;
    Inc(RecN);
  End;
End;

{ fin : l'appel est enregistre (segment ou metafichier) ; rend vrai s'il
  faut aussi dessiner }
Function RecDone(K, Ex, ExLen : LongInt) : Boolean;
Var Buf, L, Rec : Boolean; P : LongInt;
Begin
  RecDone := True;
  If Replaying <> 0 Then Exit;
  Rec := ((Gps[K].Dc >= 0) And (DcUse[Gps[K].Dc] <> 0) And (DcMeta[Gps[K].Dc] >= 0)) Or
         ((Gps[K].X[gxOpenSeg] <> 0) And ((Gps[K].X[gxDrawMode] And DM_RETAIN) <> 0));
  If Not Rec Then Exit;
  L := False; Buf := False;
  P := MemAlloc(RecN * 4 + MaxI(ExLen, 0) + 8);
  If P <> 0 Then
  Begin
    MemMove(LongInt(@RecV), P, RecN * 4);
    If ExLen > 0 Then MemMove(Ex, P + RecN * 4, ExLen);
    Dummy := LongInt(AddElem(K, ETYPE_BASE + RecE, P, RecN * 4 + MaxI(ExLen, 0)));
    MemFree(P);
  End;
  If (Gps[K].Dc >= 0) And (DcUse[Gps[K].Dc] <> 0) And (DcMeta[Gps[K].Dc] >= 0) Then RecDone := False
  Else RecDone := Gps[K].X[gxDrawMode] <> DM_RETAIN;
End;

{ ==================================================================== }
{ Contextes de peripheriques                                            }
{ ==================================================================== }
{ DevOpenDC(hab, lType, pszToken, lCount, pdopData, hdcComp) : HDC.
  DEVOPENSTRUC : pszLogAddress, pszDriverName, pdriv, pszDataType... ;
  OD_DIRECT/OD_INFO "DISPLAY" (ou sans pilote) : l'ecran ; OD_MEMORY :
  bitmaps ; OD_METAFILE : enregistrement ; OD_QUEUED : sans sortie }
Function DevOpenDC(Hab, Typ, PTok, N, PDop, HComp : LongInt) : LongInt;
Var D, M, I : LongInt;
Begin
  DevOpenDC := 0;
  If (Typ <> OD_QUEUED) And (Typ <> OD_DIRECT) And (Typ <> OD_INFO) And (Typ <> OD_METAFILE) And
     (Typ <> OD_METAFILE_NOQUERY) And (Typ <> OD_MEMORY) Then
  Begin
    SetErr(PMERR_INV_PARAMETER);
    Exit;
  End;
  D := NewDc(Typ);
  If D < 0 Then
  Begin
    SetErr(PMERR_INSUFFICIENT_MEMORY);
    Exit;
  End;
  DcHab[D] := Hab;
  If (Typ = OD_METAFILE) Or (Typ = OD_METAFILE_NOQUERY) Then
  Begin
    M := -1;
    For I := MaxMeta - 1 DownTo 0 Do
      If MfUse[I] = 0 Then M := I;
    If M < 0 Then
    Begin
      DcUse[D] := 0;
      SetErr(PMERR_INSUFFICIENT_MEMORY);
      Exit;
    End;
    MfUse[M] := 1; MfData[M] := 0; MfLen[M] := 0; MfCap[M] := 0;
    DcMeta[D] := M;
    DcType[D] := OD_METAFILE;
  End;
  DevOpenDC := $44470001 + D;
End;

{ handle d'un DC (les DC de fenetre de PMWIN sont convertis) ; -1 }
Function DcK(H : LongInt) : LongInt;
Var D, I, W : LongInt;
Begin
  D := DcIdx(H);
  If (D < 0) And ((H And $FFFF0000) = $44430000) Then
  Begin
    For I := MaxDC - 1 DownTo 0 Do
      If (DcUse[I] <> 0) And (DcType[I] = DCT_WINDOW) And (DcOwner[I] = H) Then D := I;
    If D < 0 Then
    Begin
      W := PmWndFromDc(H);
      If W <> 0 Then
      Begin
        D := NewDc(DCT_WINDOW);
        If D >= 0 Then
        Begin
          DcWnd[D] := W; DcOwner[D] := H;
        End;
      End;
    End;
  End;
  If D < 0 Then SetErr(PMERR_INV_HDC);
  DcK := D;
End;

{ DevCloseDC(hdc) : HMF pour un metafichier, 1 (DEV_OK) sinon, 0 erreur }
Function DevCloseDC(H : LongInt) : LongInt;
Var D, K : LongInt;
Begin
  D := DcIdx(H);
  If D < 0 Then
  Begin
    SetErr(PMERR_INV_HDC);
    DevCloseDC := 0;
    Exit;
  End;
  For K := 0 To MaxGPS - 1 Do
    If (GpsUse[K] <> 0) And (Gps[K].Dc = D) Then Gps[K].Dc := -1;
  If DcBmp[D] >= 0 Then BmDc[DcBmp[D]] := -1;
  If DcMeta[D] >= 0 Then DevCloseDC := $474D0001 + DcMeta[D] Else DevCloseDC := 1;
  DcUse[D] := 0;
End;

Function DevStdOpen(Hab, Typ, PTok, N, PDop, HComp : LongInt) : LongInt;
Begin
  DevStdOpen := DevOpenDC(Hab, Typ, PTok, N, PDop, HComp);
End;

{ DevQueryCaps(hdc, lStart, lCount, alArray) : CAPS_* }
Function DevQueryCaps(H, St, N, P : LongInt) : LongInt;
Var D, I, W, Hh, B, V, C : LongInt;
Begin
  DevQueryCaps := 0;
  D := DcK(H);
  If (D < 0) Or (P = 0) Then Exit;
  DcSize(D, W, Hh);
  B := 4;
  If (DcType[D] = OD_MEMORY) And (DcBmp[D] >= 0) Then B := BmBpp[DcBmp[D]]
  Else If DcType[D] <> OD_MEMORY Then Dummy := ScreenMode(W, Hh, B);
  C := 1 Shl MinI(B, 24);
  For I := 0 To N - 1 Do
  Begin
    Case St + I Of
      0 : V := 5;                    { CAPS_FAMILY : affichage }
      1 : V := 3;                    { CAPS_IO_CAPS }
      2 : V := 1;                    { CAPS_TECHNOLOGY : trame }
      3 : V := $200;
      4 : V := W;
      5 : V := Hh;
      6 : V := W Div 8;
      7 : V := Hh Div 16;
      8, 9 : V := 3780;              { pels par metre (96 ppp) }
      10, 35 : V := 8;
      11, 36 : V := 16;
      12 : V := 8;
      13 : V := 8;
      14 : V := MinI(C, 16777216);
      15 : V := 1;
      16 : V := B;
      17 : V := 3;                   { LCOLF_INDRGB, CONSECRGB, RGB }
      18 : V := 3;
      19 : V := $1FFFF;              { tous les melanges }
      20 : V := $3F;
      21 : V := 0;
      22 : V := 0;
      23 : V := 4;                   { formats de bitmaps }
      24 : V := 7;                   { RC_BITBLT, BANDING, BITMAP_SCALING }
      25, 26 : V := 8;
      27 : V := 0;
      28, 29, 30 : V := 3;
      31 : V := 0;
      32 : V := $1FF;
      33 : V := MinI(C, 16777216);
      34 : V := MinI(C - 1, 255);
      37, 38 : V := 96;
      39 : V := 0;
      40 : V := 2;
      41 : V := 0;
    Else
      V := 0;
    End;
    WrL(P + I * 4, V);
  End;
  DevQueryCaps := 1;
End;

{ DevQueryHardCopyCaps(hdc, lStartForm, lForms, phcInfo) : nombre de
  formulaires (l'ecran n'en a pas) }
Function DevQueryHardCopyCaps(H, St, N, P : LongInt) : LongInt;
Begin
  If DcK(H) < 0 Then DevQueryHardCopyCaps := -1 Else DevQueryHardCopyCaps := 0;
End;

{ DevEscape(hdc, lCode, lInCount, pbInData, plOutCount, pbOutData) :
  DEVESC_QUERYESCSUPPORT 0, STARTDOC 8150, ENDDOC 8151, NEWFRAME 16300,
  ABORTDOC 8153, QUERYVIOCELLSIZES 35 ; DEV_OK 1, DEVESC_NOTIMPLEMENTED 0 }
Function DevEscape(H, Code, NIn, PIn, PNOut, POut : LongInt) : LongInt;
Var C : LongInt;
Begin
  DevEscape := 0;
  If DcK(H) < 0 Then
  Begin
    DevEscape := -1;
    Exit;
  End;
  Case Code Of
    0 :
      Begin
        C := 0;
        If (PIn <> 0) And (NIn >= 4) Then C := RdL(PIn);
        If (C = 8150) Or (C = 8151) Or (C = 8153) Or (C = 16300) Or (C = 0) Then DevEscape := 1;
      End;
    8150, 8151, 8153, 16300 :
      Begin
        If PNOut <> 0 Then WrL(PNOut, 0);
        DevEscape := 1;
      End;
  End;
End;

{ DevPostDeviceModes(hab, pdrivDriverData, pszDriverName, pszDeviceName,
  pszName, flOptions) : taille des donnees du pilote (aucune) }
Function DevPostDeviceModes(Hab, PDriv, PDrv, PDev, PName, Fl : LongInt) : LongInt;
Begin
  DevPostDeviceModes := 0;
End;

{ DevQueryDeviceNames(hab, pszDriverName, pldn, aDeviceName,
  aDeviceDesc, pldt, aDataType) : pilote DISPLAY, appareil VGA }
Function DevQueryDeviceNames(Hab, PDrv, PN, PNames, PDesc, PNT, PTypes : LongInt) : LongInt;
Begin
  DevQueryDeviceNames := 0;
  If (PN = 0) Or (PNT = 0) Then Exit;
  If (RdL(PN) >= 1) And (PNames <> 0) Then Dummy := PutZN(PNames, 32, 'VGA');
  If (RdL(PN) >= 1) And (PDesc <> 0) Then Dummy := PutZN(PDesc, 64, 'Ecran VGA (OS/2-0)');
  If (RdL(PNT) >= 1) And (PTypes <> 0) Then Dummy := PutZN(PTypes, 16, 'PM_Q_STD');
  WrL(PN, 1); WrL(PNT, 1);
  DevQueryDeviceNames := 1;
End;

{ DevQueryDisplayResolutions(pul, pulCount) : resolutions (largeur,
  hauteur, couleurs) }
Function DevQueryDisplayResolutions(P, PN : LongInt) : LongInt;
Begin
  If PN <> 0 Then WrL(PN, 3);
  If P <> 0 Then
  Begin
    WrL(P, 640); WrL(P + 4, 480); WrL(P + 8, 16);
    WrL(P + 12, 320); WrL(P + 16, 200); WrL(P + 20, 256);
    WrL(P + 24, 640); WrL(P + 28, 400); WrL(P + 32, 8);
  End;
  DevQueryDisplayResolutions := 1;
End;

{ DspDefaultResolution(fSet, p) : resolution par defaut (640 x 480 x 16) }
Function DspDefaultResolution(FSet, P : LongInt) : LongInt;
Begin
  If (FSet = 0) And (P <> 0) Then
  Begin
    WrL(P, 640); WrL(P + 4, 480); WrL(P + 8, 16);
  End;
  DspDefaultResolution := 1;
End;

Function DspInitSystemDriverName(P, Cb : LongInt) : LongInt;
Begin
  If (P <> 0) And (Cb > 0) Then Dummy := PutZN(P, Cb, 'DISPLAY');
  DspInitSystemDriverName := 1;
End;

Function GpiSetDCOwner(H, Owner : LongInt) : LongInt;
Var D : LongInt;
Begin
  D := DcK(H);
  If D < 0 Then GpiSetDCOwner := 0
  Else
  Begin
    DcPid[D] := Owner;
    If Owner = 0 Then DcPid[D] := 0;
    GpiSetDCOwner := 1;
  End;
End;

{ ==================================================================== }
{ Espaces de presentation                                               }
{ ==================================================================== }
{ GpiCreatePS(hab, hdc, psizlSize, flOptions) : PU_* (bits 2-4),
  GPIA_ASSOC 4000h }
Function GpiCreatePS(Hab, Hdc, PSz, Fl : LongInt) : LongInt;
Var K, D, W, H : LongInt;
Begin
  GpiCreatePS := 0;
  D := -1;
  If Hdc <> 0 Then
  Begin
    D := DcK(Hdc);
    If D < 0 Then Exit;
  End;
  K := NewPs;
  If K < 0 Then
  Begin
    SetErr(PMERR_INSUFFICIENT_MEMORY);
    Exit;
  End;
  W := 0; H := 0;
  If PSz <> 0 Then
  Begin
    W := RdL(PSz); H := RdL(PSz + 4);
  End;
  If (Fl And $1C) = 0 Then Fl := Fl Or 8;
  If (Fl And $4000) = 0 Then D := -1;
  InitPs(K, D, Fl, W, H);
  Gps[K].Hab := Hab; Gps[K].Flags := Fl;
  If (D < 0) And (Hdc <> 0) Then Gps[K].Dc := -1;
  GpiCreatePS := $47500001 + K;
End;

Function GpiQueryPS(Hps, PSz : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then
  Begin
    GpiQueryPS := 0;
    Exit;
  End;
  If PSz <> 0 Then
  Begin
    WrL(PSz, Gps[K].PgW); WrL(PSz + 4, Gps[K].PgH);
  End;
  GpiQueryPS := Gps[K].Flags Or (Gps[K].Units And $1C);
End;

Procedure FreeSegsOf(K : LongInt);
Var I : LongInt;
Begin
  For I := 0 To MaxSeg - 1 Do
    If (SgUse[I] <> 0) And (SgPs[I] = K) Then
    Begin
      MemFree(SgData[I]);
      SgUse[I] := 0;
    End;
End;

Function GpiDestroyPS(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then
  Begin
    GpiDestroyPS := 0;
    Exit;
  End;
  FreeSegsOf(K);
  MemFree(Gps[K].X[gxLogTab]); MemFree(Gps[K].X[gxAttrStk]); MemFree(Gps[K].X[gxSaveStk]); MemFree(Gps[K].X[gxLcids]);
  GpsUse[K] := 0;
  GpiDestroyPS := 1;
End;

{ GpiSetPS(hps, psizlsize, flOptions) : nouvelle taille et unites }
Function GpiSetPS(Hps, PSz, Fl : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetPS := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If (Fl And $1C) <> 0 Then Gps[K].Units := Fl And $1C;
  Gps[K].PgW := 0; Gps[K].PgH := 0;
  If PSz <> 0 Then
  Begin
    Gps[K].PgW := RdL(PSz); Gps[K].PgH := RdL(PSz + 4);
  End;
  ViewportDefault(K);
  GpiSetPS := 1;
End;

{ GpiAssociate(hps, hdc) : associer (hdc 0 : dissocier) }
Function GpiAssociate(Hps, Hdc : LongInt) : LongInt;
Var K, D : LongInt;
Begin
  GpiAssociate := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Hdc = 0 Then Gps[K].Dc := -1
  Else
  Begin
    D := DcK(Hdc);
    If D < 0 Then Exit;
    Gps[K].Dc := D;
    If (Gps[K].PgW = 0) Or (Gps[K].Vx2 <= 1) Then ViewportDefault(K);
  End;
  GpiAssociate := 1;
End;

Function GpiQueryDevice(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (Gps[K].Dc < 0) Then GpiQueryDevice := 0
  Else If DcType[Gps[K].Dc] = DCT_WINDOW Then GpiQueryDevice := DcOwner[Gps[K].Dc]
  Else GpiQueryDevice := $44470001 + Gps[K].Dc;
End;

{ GpiResetPS(hps, flOptions) : GRES_ATTRS 1, GRES_SEGMENTS 2, GRES_ALL 4 }
Function GpiResetPS(Hps, Fl : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiResetPS := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  AttrDefaults(K);
  Gps[K].CurX := 0; Gps[K].CurY := 0;
  If (Fl And 6) <> 0 Then
  Begin
    FreeSegsOf(K);
    Gps[K].X[gxOpenSeg] := 0; Gps[K].X[gxElemPtr] := 0;
  End;
  If (Fl And 4) <> 0 Then
  Begin
    MatIdent(LongInt(@Gps[K].Mdl)); MatIdent(LongInt(@Gps[K].Vw)); MatIdent(LongInt(@Gps[K].Dv));
    Gps[K].X[gxClipRgn] := -1; Gps[K].X[gxClipPath] := -1; Gps[K].X[gxVlOn] := 0; Gps[K].X[gxGfOn] := 0;
    Gps[K].X[gxLogMode] := 0; Gps[K].X[gxLogN] := DefTabInit(Gps[K].X[gxLogTab]); Gps[K].X[gxPal] := 0;
    Gps[K].X[gxInArea] := 0; Gps[K].X[gxInPath] := 0;
    WrL(Gps[K].X[gxAttrStk], 0); Gps[K].X[gxSaveN] := 0;
  End;
  GpiResetPS := 1;
End;

{ GpiSavePS(hps) : identificateur ; GpiRestorePS(hps, lPSid) (negatif :
  relatif) }
Function GpiSavePS(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSavePS := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Gps[K].X[gxSaveN] >= MaxPrev Then
  Begin
    SetErr(PMERR_INSUFFICIENT_MEMORY);
    Exit;
  End;
  MemMove(LongInt(@Gps[K]), Gps[K].X[gxSaveStk] + Gps[K].X[gxSaveN] * SizeOf(TGps), SizeOf(TGps));
  Inc(Gps[K].X[gxSaveN]);
  GpiSavePS := Gps[K].X[gxSaveN];
End;

Function GpiRestorePS(Hps, Id : LongInt) : LongInt;
Var K, N, Stk, Lt, At, Lc : LongInt; Tab : Array[0..255] Of LongInt;
Begin
  GpiRestorePS := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  N := Gps[K].X[gxSaveN];
  If Id < 0 Then Id := N + 1 + Id;
  If (Id < 1) Or (Id > N) Then
  Begin
    SetErr(PMERR_INV_PARAMETER);
    Exit;
  End;
  Stk := Gps[K].X[gxSaveStk]; Lt := Gps[K].X[gxLogTab]; At := Gps[K].X[gxAttrStk]; Lc := Gps[K].X[gxLcids];
  MemMove(Lt, LongInt(@Tab), 1024);
  MemMove(Stk + (Id - 1) * SizeOf(TGps), LongInt(@Gps[K]), SizeOf(TGps));
  Gps[K].X[gxSaveStk] := Stk; Gps[K].X[gxLogTab] := Lt; Gps[K].X[gxAttrStk] := At; Gps[K].X[gxLcids] := Lc;
  Gps[K].X[gxSaveN] := Id - 1;
  GpiRestorePS := 1;
End;

{ GpiErase(hps) : effacer avec la couleur CLR_BACKGROUND }
Function GpiErase(Hps : LongInt) : LongInt;
Var K, Y, V : LongInt;
Begin
  GpiErase := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E_ERASE);
  If RecDone(K, 0, 0) Then
    If BeginDraw(K) Then
    Begin
      V := ClrDev(K, CLR_BACKGROUND, True);
      PatOn := 0;
      For Y := 0 To TgH - 1 Do DSpan(-TgOffX, TgW - TgOffX, Y - TgOffY, V, 0, FM_OVERPAINT, FM_LEAVEALONE);
    End;
  GpiErase := 1;
End;

{ ==================================================================== }
{ Attributs                                                             }
{ ==================================================================== }
{ pile des attributs (GpiPop) : (champ, valeur) }
Procedure PushAttr(K, F, V : LongInt);
Var N : LongInt;
Begin
  If (Gps[K].X[gxAttrMode] <> 0) Or (Replaying <> 0) Then Exit;
  N := RdL(Gps[K].X[gxAttrStk]);
  If N >= 500 Then Exit;
  WrL(Gps[K].X[gxAttrStk] + 8 + N * 8, F); WrL(Gps[K].X[gxAttrStk] + 12 + N * 8, V);
  WrL(Gps[K].X[gxAttrStk], N + 1);
  If F >= 0 Then Inc(PushCnt);
End;

{ fin d'un appel d'attribut : marque (-nombre de valeurs) }
Procedure PushMark(K : LongInt);
Begin
  If PushCnt > 0 Then PushAttr(K, -PushCnt, 0);
  PushCnt := 0;
End;

{ champ numero F de l'espace K : adresse }
Function AttrAddr(K, F : LongInt) : LongInt;
Begin
  AttrAddr := LongInt(@Gps[K]) + F * 4;
End;

Function FieldOf(K, A : LongInt) : LongInt;
Begin
  FieldOf := (A - LongInt(@Gps[K])) Div 4;
End;

{ fixer un attribut (adresse dans l'enregistrement) en gardant l'ancienne
  valeur sur la pile }
Procedure SetAttr(K, A, V : LongInt);
Begin
  PushAttr(K, FieldOf(K, A), RdL(A));
  WrL(A, V);
End;

Function GpiPop(Hps, N : LongInt) : LongInt;
Var K, C, F, G : LongInt;
Begin
  GpiPop := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E_POP); RecL(N);
  Dummy := LongInt(RecDone(K, 0, 0));
  C := RdL(Gps[K].X[gxAttrStk]);
  While (N > 0) And (C > 0) Do
  Begin
    Dec(C);
    F := RdL(Gps[K].X[gxAttrStk] + 8 + C * 8);
    If F < 0 Then
    Begin
      G := -F;
      While (G > 0) And (C > 0) Do
      Begin
        Dec(C);
        WrL(AttrAddr(K, RdL(Gps[K].X[gxAttrStk] + 8 + C * 8)), RdL(Gps[K].X[gxAttrStk] + 12 + C * 8));
        Dec(G);
      End;
    End
    Else WrL(AttrAddr(K, F), RdL(Gps[K].X[gxAttrStk] + 12 + C * 8));
    Dec(N);
  End;
  WrL(Gps[K].X[gxAttrStk], C);
  GpiPop := 1;
End;

Function GpiSetAttrMode(Hps, M : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (M < 0) Or (M > 1) Then GpiSetAttrMode := 0
  Else
  Begin
    Gps[K].X[gxAttrMode] := M;
    GpiSetAttrMode := 1;
  End;
End;

Function GpiQueryAttrMode(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryAttrMode := -1 Else GpiQueryAttrMode := Gps[K].X[gxAttrMode];
End;

{ fixer un attribut de toutes les primitives (couleur, fond, melanges) }
Function SetAll(Hps, E, Which, V : LongInt) : LongInt;
Var K : LongInt;
Begin
  SetAll := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E); RecL(V);
  Dummy := LongInt(RecDone(K, 0, 0));
  PushCnt := 0;
  Case Which Of
    0 :
      Begin
        SetAttr(K, LongInt(@Gps[K].LColor), V); SetAttr(K, LongInt(@Gps[K].CColor), V);
        SetAttr(K, LongInt(@Gps[K].MColor), V); SetAttr(K, LongInt(@Gps[K].AColor), V);
        SetAttr(K, LongInt(@Gps[K].IColor), V);
      End;
    1 :
      Begin
        SetAttr(K, LongInt(@Gps[K].LBack), V); SetAttr(K, LongInt(@Gps[K].CBack), V);
        SetAttr(K, LongInt(@Gps[K].MBack), V); SetAttr(K, LongInt(@Gps[K].ABack), V);
        SetAttr(K, LongInt(@Gps[K].IBack), V);
      End;
    2 :
      Begin
        SetAttr(K, LongInt(@Gps[K].LMix), V); SetAttr(K, LongInt(@Gps[K].CMix), V);
        SetAttr(K, LongInt(@Gps[K].MMix), V); SetAttr(K, LongInt(@Gps[K].AMix), V);
        SetAttr(K, LongInt(@Gps[K].IMix), V);
      End;
    3 :
      Begin
        SetAttr(K, LongInt(@Gps[K].LBMix), V); SetAttr(K, LongInt(@Gps[K].CBMix), V);
        SetAttr(K, LongInt(@Gps[K].MBMix), V); SetAttr(K, LongInt(@Gps[K].ABMix), V);
        SetAttr(K, LongInt(@Gps[K].IBMix), V);
      End;
  End;
  PushMark(K);
  SetAll := 1;
End;

Function GpiSetColor(Hps, C : LongInt) : LongInt;
Begin
  GpiSetColor := SetAll(Hps, E_SETCOLOR, 0, C);
End;

Function GpiQueryColor(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryColor := -255 Else GpiQueryColor := Gps[K].LColor;
End;

Function GpiSetBackColor(Hps, C : LongInt) : LongInt;
Begin
  GpiSetBackColor := SetAll(Hps, E_SETBACKCOLOR, 1, C);
End;

Function GpiQueryBackColor(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryBackColor := -255 Else GpiQueryBackColor := Gps[K].LBack;
End;

Function GpiSetMix(Hps, M : LongInt) : LongInt;
Begin
  If (M < 0) Or (M > 17) Then
  Begin
    SetErr(PMERR_INV_PARAMETER);
    GpiSetMix := 0;
  End
  Else GpiSetMix := SetAll(Hps, E_SETMIX, 2, M);
End;

Function GpiQueryMix(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryMix := -1 Else GpiQueryMix := Gps[K].LMix;
End;

Function GpiSetBackMix(Hps, M : LongInt) : LongInt;
Begin
  GpiSetBackMix := SetAll(Hps, E_SETBACKMIX, 3, M);
End;

Function GpiQueryBackMix(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryBackMix := -1 Else GpiQueryBackMix := Gps[K].LBMix;
End;

{ attribut simple : enregistrement puis valeur }
Function SetOne(Hps, E, Ofs, V : LongInt) : LongInt;
Var K : LongInt;
Begin
  SetOne := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E); RecL(V);
  Dummy := LongInt(RecDone(K, 0, 0));
  PushCnt := 0;
  SetAttr(K, LongInt(@Gps[K]) + Ofs, V);
  PushMark(K);
  SetOne := 1;
End;

Function OneOf(Hps, Ofs : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then OneOf := -1 Else OneOf := RdL(LongInt(@Gps[K]) + Ofs);
End;

Function OfsOf(Var F : LongInt) : LongInt;
Begin
  OfsOf := LongInt(@F) - LongInt(@Gps[0]);
End;

Function GpiSetLineType(Hps, T : LongInt) : LongInt;
Begin
  GpiSetLineType := SetOne(Hps, E_SETLINETYPE, OfsOf(Gps[0].LType), T);
End;

Function GpiQueryLineType(Hps : LongInt) : LongInt;
Begin
  GpiQueryLineType := OneOf(Hps, OfsOf(Gps[0].LType));
End;

Function GpiSetLineWidth(Hps, W : LongInt) : LongInt;
Begin
  GpiSetLineWidth := SetOne(Hps, E_SETLINEWIDTH, OfsOf(Gps[0].LWidth), W);
End;

Function GpiQueryLineWidth(Hps : LongInt) : LongInt;
Begin
  GpiQueryLineWidth := OneOf(Hps, OfsOf(Gps[0].LWidth));
End;

Function GpiSetLineWidthGeom(Hps, W : LongInt) : LongInt;
Begin
  GpiSetLineWidthGeom := SetOne(Hps, E_SETLINEWIDTHGEOM, OfsOf(Gps[0].LGeom), W);
End;

Function GpiQueryLineWidthGeom(Hps : LongInt) : LongInt;
Begin
  GpiQueryLineWidthGeom := OneOf(Hps, OfsOf(Gps[0].LGeom));
End;

Function GpiSetLineEnd(Hps, V : LongInt) : LongInt;
Begin
  GpiSetLineEnd := SetOne(Hps, E_SETLINEEND, OfsOf(Gps[0].LEnd), V);
End;

Function GpiQueryLineEnd(Hps : LongInt) : LongInt;
Begin
  GpiQueryLineEnd := OneOf(Hps, OfsOf(Gps[0].LEnd));
End;

Function GpiSetLineJoin(Hps, V : LongInt) : LongInt;
Begin
  GpiSetLineJoin := SetOne(Hps, E_SETLINEJOIN, OfsOf(Gps[0].LJoin), V);
End;

Function GpiQueryLineJoin(Hps : LongInt) : LongInt;
Begin
  GpiQueryLineJoin := OneOf(Hps, OfsOf(Gps[0].LJoin));
End;

Function GpiSetPatternSet(Hps, V : LongInt) : LongInt;
Begin
  GpiSetPatternSet := SetOne(Hps, E_SETPATTERNSET, OfsOf(Gps[0].PSet), V);
End;

Function GpiQueryPatternSet(Hps : LongInt) : LongInt;
Begin
  GpiQueryPatternSet := OneOf(Hps, OfsOf(Gps[0].PSet));
End;

Function GpiSetPattern(Hps, V : LongInt) : LongInt;
Begin
  GpiSetPattern := SetOne(Hps, E_SETPATTERN, OfsOf(Gps[0].PSym), V);
End;

Function GpiQueryPattern(Hps : LongInt) : LongInt;
Begin
  GpiQueryPattern := OneOf(Hps, OfsOf(Gps[0].PSym));
End;

Function GpiSetMarkerSet(Hps, V : LongInt) : LongInt;
Begin
  GpiSetMarkerSet := SetOne(Hps, E_SETMARKERSET, OfsOf(Gps[0].MSet), V);
End;

Function GpiQueryMarkerSet(Hps : LongInt) : LongInt;
Begin
  GpiQueryMarkerSet := OneOf(Hps, OfsOf(Gps[0].MSet));
End;

Function GpiSetMarker(Hps, V : LongInt) : LongInt;
Begin
  GpiSetMarker := SetOne(Hps, E_SETMARKER, OfsOf(Gps[0].MSym), V);
End;

Function GpiQueryMarker(Hps : LongInt) : LongInt;
Begin
  GpiQueryMarker := OneOf(Hps, OfsOf(Gps[0].MSym));
End;

Function GpiSetCharSet(Hps, V : LongInt) : LongInt;
Begin
  GpiSetCharSet := SetOne(Hps, E_SETCHARSET, OfsOf(Gps[0].CSet), V);
End;

Function GpiQueryCharSet(Hps : LongInt) : LongInt;
Begin
  GpiQueryCharSet := OneOf(Hps, OfsOf(Gps[0].CSet));
End;

Function GpiSetCharDirection(Hps, V : LongInt) : LongInt;
Begin
  If V = 0 Then V := 1;
  GpiSetCharDirection := SetOne(Hps, E_SETCHARDIR, OfsOf(Gps[0].CDir), V);
End;

Function GpiQueryCharDirection(Hps : LongInt) : LongInt;
Begin
  GpiQueryCharDirection := OneOf(Hps, OfsOf(Gps[0].CDir));
End;

Function GpiSetCharMode(Hps, V : LongInt) : LongInt;
Begin
  GpiSetCharMode := SetOne(Hps, E_SETCHARMODE, OfsOf(Gps[0].CMode), V);
End;

Function GpiQueryCharMode(Hps : LongInt) : LongInt;
Begin
  GpiQueryCharMode := OneOf(Hps, OfsOf(Gps[0].CMode));
End;

Function GpiSetCharExtra(Hps, V : LongInt) : LongInt;
Begin
  GpiSetCharExtra := SetOne(Hps, E_SETCHAREXTRA, OfsOf(Gps[0].CExtra), V);
End;

Function GpiQueryCharExtra(Hps, P : LongInt) : LongInt;
Begin
  GpiQueryCharExtra := 0;
  If P = 0 Then Exit;
  WrL(P, OneOf(Hps, OfsOf(Gps[0].CExtra)));
  GpiQueryCharExtra := 1;
End;

Function GpiSetCharBreakExtra(Hps, V : LongInt) : LongInt;
Begin
  GpiSetCharBreakExtra := SetOne(Hps, E_SETCHARBREAK, OfsOf(Gps[0].CBreak), V);
End;

Function GpiQueryCharBreakExtra(Hps, P : LongInt) : LongInt;
Begin
  GpiQueryCharBreakExtra := 0;
  If P = 0 Then Exit;
  WrL(P, OneOf(Hps, OfsOf(Gps[0].CBreak)));
  GpiQueryCharBreakExtra := 1;
End;

{ attribut a deux valeurs (point ou taille) }
Function SetTwo(Hps, E, Ofs, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  SetTwo := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E); RecL(RdL(P)); RecL(RdL(P + 4));
  Dummy := LongInt(RecDone(K, 0, 0));
  PushCnt := 0;
  SetAttr(K, LongInt(@Gps[K]) + Ofs, RdL(P));
  SetAttr(K, LongInt(@Gps[K]) + Ofs + 4, RdL(P + 4));
  PushMark(K);
  SetTwo := 1;
End;

Function TwoOf(Hps, Ofs, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  TwoOf := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  WrL(P, RdL(LongInt(@Gps[K]) + Ofs)); WrL(P + 4, RdL(LongInt(@Gps[K]) + Ofs + 4));
  TwoOf := 1;
End;

Function GpiSetCharBox(Hps, P : LongInt) : LongInt;
Begin
  GpiSetCharBox := SetTwo(Hps, E_SETCHARBOX, OfsOf(Gps[0].CBoxX), P);
End;

Function GpiQueryCharBox(Hps, P : LongInt) : LongInt;
Begin
  GpiQueryCharBox := TwoOf(Hps, OfsOf(Gps[0].CBoxX), P);
End;

Function GpiSetCharAngle(Hps, P : LongInt) : LongInt;
Begin
  GpiSetCharAngle := SetTwo(Hps, E_SETCHARANGLE, OfsOf(Gps[0].CAngX), P);
End;

Function GpiQueryCharAngle(Hps, P : LongInt) : LongInt;
Begin
  GpiQueryCharAngle := TwoOf(Hps, OfsOf(Gps[0].CAngX), P);
End;

Function GpiSetCharShear(Hps, P : LongInt) : LongInt;
Begin
  GpiSetCharShear := SetTwo(Hps, E_SETCHARSHEAR, OfsOf(Gps[0].CShX), P);
End;

Function GpiQueryCharShear(Hps, P : LongInt) : LongInt;
Begin
  GpiQueryCharShear := TwoOf(Hps, OfsOf(Gps[0].CShX), P);
End;

Function GpiSetMarkerBox(Hps, P : LongInt) : LongInt;
Begin
  GpiSetMarkerBox := SetTwo(Hps, E_SETMARKERBOX, OfsOf(Gps[0].MBoxX), P);
End;

Function GpiQueryMarkerBox(Hps, P : LongInt) : LongInt;
Begin
  GpiQueryMarkerBox := TwoOf(Hps, OfsOf(Gps[0].MBoxX), P);
End;

Function GpiSetPatternRefPoint(Hps, P : LongInt) : LongInt;
Begin
  GpiSetPatternRefPoint := SetTwo(Hps, E_SETPATTERNREF, OfsOf(Gps[0].PRefX), P);
End;

Function GpiQueryPatternRefPoint(Hps, P : LongInt) : LongInt;
Begin
  GpiQueryPatternRefPoint := TwoOf(Hps, OfsOf(Gps[0].PRefX), P);
End;

{ GpiSetTextAlignment(hps, lHoriz, lVert) }
Function GpiSetTextAlignment(Hps, H, V : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetTextAlignment := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E_SETTEXTALIGN); RecL(H); RecL(V);
  Dummy := LongInt(RecDone(K, 0, 0));
  If (H = 0) Or (H = 5) Then H := 1;
  If (V = 0) Or (V = 6) Then V := 1;
  PushCnt := 0;
  SetAttr(K, LongInt(@Gps[K].CAlignH), H); SetAttr(K, LongInt(@Gps[K].CAlignV), V);
  PushMark(K);
  GpiSetTextAlignment := 1;
End;

Function GpiQueryTextAlignment(Hps, PH, PV : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryTextAlignment := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If PH <> 0 Then WrL(PH, Gps[K].CAlignH);
  If PV <> 0 Then WrL(PV, Gps[K].CAlignV);
  GpiQueryTextAlignment := 1;
End;

{ ARCPARAMS (lP, lQ, lR, lS) }
Function GpiSetArcParams(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetArcParams := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E_SETARCPARAMS); RecL(RdL(P)); RecL(RdL(P + 4)); RecL(RdL(P + 8)); RecL(RdL(P + 12));
  Dummy := LongInt(RecDone(K, 0, 0));
  Gps[K].X[gxArcP] := RdL(P); Gps[K].X[gxArcQ] := RdL(P + 4); Gps[K].X[gxArcR] := RdL(P + 8); Gps[K].X[gxArcS] := RdL(P + 12);
  GpiSetArcParams := 1;
End;

Function GpiQueryArcParams(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryArcParams := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  WrL(P, Gps[K].X[gxArcP]); WrL(P + 4, Gps[K].X[gxArcQ]); WrL(P + 8, Gps[K].X[gxArcR]); WrL(P + 12, Gps[K].X[gxArcS]);
  GpiQueryArcParams := 1;
End;

Function GpiSetDefArcParams(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetDefArcParams := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  Gps[K].X[gxDefArcP] := RdL(P); Gps[K].X[gxDefArcQ] := RdL(P + 4); Gps[K].X[gxDefArcR] := RdL(P + 8); Gps[K].X[gxDefArcS] := RdL(P + 12);
  GpiSetDefArcParams := 1;
End;

Function GpiQueryDefArcParams(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryDefArcParams := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  WrL(P, Gps[K].X[gxDefArcP]); WrL(P + 4, Gps[K].X[gxDefArcQ]); WrL(P + 8, Gps[K].X[gxDefArcR]); WrL(P + 12, Gps[K].X[gxDefArcS]);
  GpiQueryDefArcParams := 1;
End;

Function GpiSetTag(Hps, T : LongInt) : LongInt;
Begin
  GpiSetTag := SetOne(Hps, E_SETTAG, OfsOf(Gps[0].X[gxTag]), T);
End;

Function GpiQueryTag(Hps, P : LongInt) : LongInt;
Begin
  GpiQueryTag := 0;
  If P = 0 Then Exit;
  WrL(P, OneOf(Hps, OfsOf(Gps[0].X[gxTag])));
  GpiQueryTag := 1;
End;

Function GpiSetDefTag(Hps, T : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiSetDefTag := 0
  Else
  Begin
    Gps[K].X[gxDefTag] := T;
    GpiSetDefTag := 1;
  End;
End;

Function GpiQueryDefTag(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then GpiQueryDefTag := 0
  Else
  Begin
    WrL(P, Gps[K].X[gxDefTag]);
    GpiQueryDefTag := 1;
  End;
End;

{ --- paquets d'attributs (GpiSetAttrs, GpiQueryAttrs) : champs de
  chaque type de primitive et leur taille dans le paquet --- }
Procedure BundleField(K, Prim, Bit : LongInt; Var A, Ofs, Sz : LongInt);
Begin
  A := 0; Ofs := -1; Sz := 4;
  Case Prim Of
    PRIM_LINE :
      Case Bit Of
        0 : Begin A := LongInt(@Gps[K].LColor); Ofs := 0; End;
        1 : Begin A := LongInt(@Gps[K].LBack); Ofs := 4; End;
        2 : Begin A := LongInt(@Gps[K].LMix); Ofs := 8; Sz := 2; End;
        3 : Begin A := LongInt(@Gps[K].LBMix); Ofs := 10; Sz := 2; End;
        4 : Begin A := LongInt(@Gps[K].LWidth); Ofs := 12; End;
        5 : Begin A := LongInt(@Gps[K].LGeom); Ofs := 16; End;
        6 : Begin A := LongInt(@Gps[K].LType); Ofs := 20; Sz := 2; End;
        7 : Begin A := LongInt(@Gps[K].LEnd); Ofs := 22; Sz := 2; End;
        8 : Begin A := LongInt(@Gps[K].LJoin); Ofs := 24; Sz := 2; End;
      End;
    PRIM_CHAR :
      Case Bit Of
        0 : Begin A := LongInt(@Gps[K].CColor); Ofs := 0; End;
        1 : Begin A := LongInt(@Gps[K].CBack); Ofs := 4; End;
        2 : Begin A := LongInt(@Gps[K].CMix); Ofs := 8; Sz := 2; End;
        3 : Begin A := LongInt(@Gps[K].CBMix); Ofs := 10; Sz := 2; End;
        4 : Begin A := LongInt(@Gps[K].CSet); Ofs := 12; Sz := 2; End;
        5 : Begin A := LongInt(@Gps[K].CMode); Ofs := 14; Sz := 2; End;
        6 : Begin A := LongInt(@Gps[K].CBoxX); Ofs := 16; Sz := 8; End;
        7 : Begin A := LongInt(@Gps[K].CAngX); Ofs := 24; Sz := 8; End;
        8 : Begin A := LongInt(@Gps[K].CShX); Ofs := 32; Sz := 8; End;
        9 : Begin A := LongInt(@Gps[K].CDir); Ofs := 40; Sz := 2; End;
        10 : Begin A := LongInt(@Gps[K].CAlignH); Ofs := 42; Sz := 2; End;
        11 : Begin A := LongInt(@Gps[K].CExtra); Ofs := 44; End;
        12 : Begin A := LongInt(@Gps[K].CBreak); Ofs := 48; End;
      End;
    PRIM_MARKER :
      Case Bit Of
        0 : Begin A := LongInt(@Gps[K].MColor); Ofs := 0; End;
        1 : Begin A := LongInt(@Gps[K].MBack); Ofs := 4; End;
        2 : Begin A := LongInt(@Gps[K].MMix); Ofs := 8; Sz := 2; End;
        3 : Begin A := LongInt(@Gps[K].MBMix); Ofs := 10; Sz := 2; End;
        4 : Begin A := LongInt(@Gps[K].MSet); Ofs := 12; Sz := 2; End;
        5 : Begin A := LongInt(@Gps[K].MSym); Ofs := 14; Sz := 2; End;
        6 : Begin A := LongInt(@Gps[K].MBoxX); Ofs := 16; Sz := 8; End;
      End;
    PRIM_AREA :
      Case Bit Of
        0 : Begin A := LongInt(@Gps[K].AColor); Ofs := 0; End;
        1 : Begin A := LongInt(@Gps[K].ABack); Ofs := 4; End;
        2 : Begin A := LongInt(@Gps[K].AMix); Ofs := 8; Sz := 2; End;
        3 : Begin A := LongInt(@Gps[K].ABMix); Ofs := 10; Sz := 2; End;
        4 : Begin A := LongInt(@Gps[K].PSet); Ofs := 12; Sz := 2; End;
        5 : Begin A := LongInt(@Gps[K].PSym); Ofs := 14; Sz := 2; End;
        6 : Begin A := LongInt(@Gps[K].PRefX); Ofs := 16; Sz := 8; End;
      End;
    PRIM_IMAGE :
      Case Bit Of
        0 : Begin A := LongInt(@Gps[K].IColor); Ofs := 0; End;
        1 : Begin A := LongInt(@Gps[K].IBack); Ofs := 4; End;
        2 : Begin A := LongInt(@Gps[K].IMix); Ofs := 8; Sz := 2; End;
        3 : Begin A := LongInt(@Gps[K].IBMix); Ofs := 10; Sz := 2; End;
      End;
  End;
End;

{ GpiSetAttrs(hps, lPrimType, flAttrMask, flDefMask, ppbunAttrs) }
Function GpiSetAttrs(Hps, Prim, Mask, DefMask, P : LongInt) : LongInt;
Var K, B, A, Ofs, Sz, V, J : LongInt;
Begin
  GpiSetAttrs := 0;
  K := PsK(Hps);
  If (K < 0) Or (Prim < 1) Or (Prim > 5) Then Exit;
  RecI(E_SETATTRS); RecL(Prim); RecL(Mask); RecL(DefMask);
  Dummy := LongInt(RecDone(K, P, 52));
  PushCnt := 0;
  For B := 0 To 12 Do
    If ((Mask Or DefMask) And (1 Shl B)) <> 0 Then
    Begin
      BundleField(K, Prim, B, A, Ofs, Sz);
      If A <> 0 Then
        For J := 0 To (Sz Div 4) - 1 + Ord(Sz < 4) Do
        Begin
          If (DefMask And (1 Shl B)) <> 0 Then
          Begin
            If B <= 1 Then V := CLR_DEFAULT Else V := 0;
            If (Prim = PRIM_LINE) And (B = 4) Then V := $10000;
          End
          Else If Sz = 2 Then V := RdW(P + Ofs)
          Else V := RdL(P + Ofs + J * 4);
          SetAttr(K, A + J * 4, V);
        End;
    End;
  PushMark(K);
  GpiSetAttrs := 1;
End;

{ GpiQueryAttrs(hps, lPrimType, flAttrMask, ppbunAttrs) : masque rendu }
Function GpiQueryAttrs(Hps, Prim, Mask, P : LongInt) : LongInt;
Var K, B, A, Ofs, Sz, J : LongInt;
Begin
  GpiQueryAttrs := -1;
  K := PsK(Hps);
  If (K < 0) Or (Prim < 1) Or (Prim > 5) Or (P = 0) Then Exit;
  For B := 0 To 12 Do
    If (Mask And (1 Shl B)) <> 0 Then
    Begin
      BundleField(K, Prim, B, A, Ofs, Sz);
      If A <> 0 Then
      Begin
        If Sz = 2 Then WrW(P + Ofs, RdL(A))
        Else
          For J := 0 To (Sz Div 4) - 1 Do WrL(P + Ofs + J * 4, RdL(A + J * 4));
      End;
    End;
  GpiQueryAttrs := Mask;
End;

Function GpiSetDefAttrs(Hps, Prim, Mask, P : LongInt) : LongInt;
Begin
  GpiSetDefAttrs := GpiSetAttrs(Hps, Prim, Mask, 0, P);
End;

Function GpiQueryDefAttrs(Hps, Prim, Mask, P : LongInt) : LongInt;
Begin
  GpiQueryDefAttrs := GpiQueryAttrs(Hps, Prim, Mask, P);
End;

{ ==================================================================== }
{ Primitives                                                            }
{ ==================================================================== }
{ debut d'une primitive : WX/WY demarre a la position courante }
Procedure PrimStart(K : LongInt);
Begin
  WN := 0;
  WPut(Gps[K].CurX, Gps[K].CurY);
End;

Function GpiSetCurrentPosition(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetCurrentPosition := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E_SETCURPOS); RecL(RdL(P)); RecL(RdL(P + 4));
  Dummy := LongInt(RecDone(K, 0, 0));
  Gps[K].CurX := RdL(P); Gps[K].CurY := RdL(P + 4);
  GpiSetCurrentPosition := 1;
End;

Function GpiQueryCurrentPosition(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryCurrentPosition := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  WrL(P, Gps[K].CurX); WrL(P + 4, Gps[K].CurY);
  GpiQueryCurrentPosition := 1;
End;

Function GpiMove(Hps, P : LongInt) : LongInt;
Var K, X, Y : LongInt;
Begin
  GpiMove := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E_MOVE); RecL(RdL(P)); RecL(RdL(P + 4));
  Dummy := LongInt(RecDone(K, 0, 0));
  Gps[K].CurX := RdL(P); Gps[K].CurY := RdL(P + 4);
  Gps[K].X[gxLsCtr] := 0;
  If (Gps[K].X[gxInArea] <> 0) Or (Gps[K].X[gxInPath] <> 0) Then
  Begin
    CompSet(K);
    XF(K, Gps[K].CurX, Gps[K].CurY, X, Y);
    FigNew(X, Y);
  End;
  GpiMove := 1;
End;

{ resultat d'une primitive : GPI_OK 1, GPI_HITS 2 (correlation) }
Function PrimRes : LongInt;
Begin
  If (RMode = 2) And (Hit <> 0) Then PrimRes := 2 Else PrimRes := 1;
End;

Function GpiLine(Hps, P : LongInt) : LongInt;
Var K : LongInt; D : Boolean;
Begin
  GpiLine := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E_LINE); RecL(RdL(P)); RecL(RdL(P + 4));
  D := RecDone(K, 0, 0);
  PrimStart(K);
  WPut(RdL(P), RdL(P + 4));
  EmitWorld(K, False, D);
  GpiLine := PrimRes;
End;

Function GpiPolyLine(Hps, N, P : LongInt) : LongInt;
Var K, I : LongInt; D : Boolean;
Begin
  GpiPolyLine := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Or (N < 0) Then Exit;
  RecI(E_POLYLINE); RecL(N);
  D := RecDone(K, P, N * 8);
  PrimStart(K);
  For I := 0 To N - 1 Do WPut(RdL(P + I * 8), RdL(P + I * 8 + 4));
  EmitWorld(K, False, D);
  GpiPolyLine := PrimRes;
End;

{ GpiPolyLineDisjoint(hps, lCount, aptlPoints) : paires de points }
Function GpiPolyLineDisjoint(Hps, N, P : LongInt) : LongInt;
Var K, I : LongInt; D : Boolean;
Begin
  GpiPolyLineDisjoint := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Or (N < 0) Then Exit;
  RecI(E_POLYLINEDISJ); RecL(N);
  D := RecDone(K, P, N * 8);
  I := 0;
  While I + 1 < N Do
  Begin
    WN := 0;
    WPut(RdL(P + I * 8), RdL(P + I * 8 + 4)); WPut(RdL(P + I * 8 + 8), RdL(P + I * 8 + 12));
    Gps[K].X[gxLsCtr] := 0;
    EmitWorld(K, True, D);
    I := I + 2;
  End;
  GpiPolyLineDisjoint := PrimRes;
End;

{ figure fermee du monde WX/WY : remplie (zone, bords compris) et/ou
  tracee }
Procedure ClosedFigure(K : LongInt; Ctl : LongInt; D : Boolean);
Var I, Mx, My : LongInt; St : Array[0..0] Of LongInt;
Begin
  If WN < 2 Then Exit;
  CompSet(K);
  For I := 0 To WN - 1 Do XF(K, WX[I], WY[I], DXs[I], DYs[I]);
  If (Gps[K].X[gxInArea] <> 0) Or (Gps[K].X[gxInPath] <> 0) Then
  Begin
    FigNew(DXs[0], DYs[0]);
    For I := 1 To WN - 1 Do FigAdd(DXs[I], DYs[I]);
    If FgCnt > 0 Then FgClosed[FgCnt - 1] := 1;
    FigNew(DXs[0], DYs[0]);
    Exit;
  End;
  If Not D Then Exit;
  If Not BeginDraw(K) Then Exit;
  If (Ctl And 1) <> 0 Then
  Begin
    { remplissage : les pels de la frontiere sont compris }
    Mx := DXs[0]; My := DYs[0];
    For I := 0 To WN - 1 Do
    Begin
      Mx := MaxI(Mx, DXs[I]); My := MaxI(My, DYs[I]);
    End;
    For I := 0 To WN - 1 Do
    Begin
      FgX[I] := DXs[I]; FgY[I] := DYs[I];
      If DXs[I] = Mx Then FgX[I] := Mx + 1;
      If DYs[I] = My Then FgY[I] := My + 1;
    End;
    St[0] := 0;
    AreaFill(K, LongInt(@FgX), LongInt(@FgY), LongInt(@St), 1, WN, False);
  End;
  If ((Ctl And 2) <> 0) Or (Ctl = 0) Then
  Begin
    BrushW := 0;
    StrokeDev(K, WN, True);
  End;
End;

{ GpiBox(hps, lControl, pptlPoint, lHRound, lVRound) : DRO_FILL 1,
  DRO_OUTLINE 2, DRO_OUTLINEFILL 3 }
Function GpiBox(Hps, Ctl, P, HR, VR : LongInt) : LongInt;
Var K, X1, Y1, X2, Y2, Cx, Cy, Rx, Ry, I, Sx, Sy : LongInt; D : Boolean;
Begin
  GpiBox := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E_BOX); RecL(Ctl); RecL(RdL(P)); RecL(RdL(P + 4)); RecL(HR); RecL(VR);
  D := RecDone(K, 0, 0);
  X1 := MinI(Gps[K].CurX, RdL(P)); X2 := MaxI(Gps[K].CurX, RdL(P));
  Y1 := MinI(Gps[K].CurY, RdL(P + 4)); Y2 := MaxI(Gps[K].CurY, RdL(P + 4));
  Sx := Gps[K].CurX; Sy := Gps[K].CurY;
  WN := 0;
  Rx := MinI(AbsI(HR) Div 2, (X2 - X1) Div 2); Ry := MinI(AbsI(VR) Div 2, (Y2 - Y1) Div 2);
  If (Rx > 0) And (Ry > 0) Then
  Begin
    { coins arrondis : quarts d'ellipse }
    For I := 0 To 8 Do WPut(X2 - Rx + FRound(Rx * CosA(I * 32)), Y2 - Ry + FRound(Ry * SinA(I * 32)));
    For I := 8 To 16 Do WPut(X1 + Rx + FRound(Rx * CosA(I * 32)), Y2 - Ry + FRound(Ry * SinA(I * 32)));
    For I := 16 To 24 Do WPut(X1 + Rx + FRound(Rx * CosA(I * 32)), Y1 + Ry + FRound(Ry * SinA(I * 32)));
    For I := 24 To 32 Do WPut(X2 - Rx + FRound(Rx * CosA(I * 32)), Y1 + Ry + FRound(Ry * SinA(I * 32)));
  End
  Else
  Begin
    WPut(X1, Y1); WPut(X2, Y1); WPut(X2, Y2); WPut(X1, Y2);
  End;
  ClosedFigure(K, Ctl, D);
  Gps[K].CurX := Sx; Gps[K].CurY := Sy;
  GpiBox := PrimRes;
End;

{ GpiFullArc(hps, lControl, fxMultiplier) : ellipse autour de la
  position courante }
Function GpiFullArc(Hps, Ctl, Mult : LongInt) : LongInt;
Var K, Cx, Cy : LongInt; D : Boolean;
Begin
  GpiFullArc := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E_FULLARC); RecL(Ctl); RecL(Mult);
  D := RecDone(K, 0, 0);
  Cx := Gps[K].CurX; Cy := Gps[K].CurY;
  WN := 0;
  ArcPts(K, Cx, Cy, Mult, 0, 1024);
  If WN > 1 Then Dec(WN);
  ClosedFigure(K, Ctl, D);
  Gps[K].CurX := Cx; Gps[K].CurY := Cy;
  GpiFullArc := PrimRes;
End;

{ angle FIXED en degres -> 1024e de tour }
Function DegA(F : LongInt) : LongInt;
Begin
  DegA := MulDiv(F, 1024, 360 * 65536);
End;

{ GpiPartialArc(hps, pptlCenter, fxMultiplier, fxStartAngle, fxSweepAngle) }
Function GpiPartialArc(Hps, PC, Mult, A0, Sw : LongInt) : LongInt;
Var K : LongInt; D : Boolean;
Begin
  GpiPartialArc := 0;
  K := PsK(Hps);
  If (K < 0) Or (PC = 0) Then Exit;
  RecI(E_PARTIALARC); RecL(RdL(PC)); RecL(RdL(PC + 4)); RecL(Mult); RecL(A0); RecL(Sw);
  D := RecDone(K, 0, 0);
  PrimStart(K);
  ArcPts(K, RdL(PC), RdL(PC + 4), Mult, DegA(A0), DegA(Sw));
  EmitWorld(K, False, D);
  GpiPartialArc := PrimRes;
End;

{ GpiPointArc(hps, pptl2) : arc par la position courante et deux points }
Function GpiPointArc(Hps, P : LongInt) : LongInt;
Var K, Ax, Ay, Bx, By, Cx, Cy, Dd, B2, C2, Ux, Uy, R, A0, A1, A2, S, M, Sp, Sq, Sr, Ss : LongInt; D : Boolean;
Begin
  GpiPointArc := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E_POINTARC); RecL(RdL(P)); RecL(RdL(P + 4)); RecL(RdL(P + 8)); RecL(RdL(P + 12));
  D := RecDone(K, 0, 0);
  Ax := Gps[K].CurX; Ay := Gps[K].CurY;
  Bx := RdL(P) - Ax; By := RdL(P + 4) - Ay; Cx := RdL(P + 8) - Ax; Cy := RdL(P + 12) - Ay;
  PrimStart(K);
  Dd := 2 * (Bx * Cy - By * Cx);
  If Dd = 0 Then
  Begin
    WPut(RdL(P + 8), RdL(P + 12));
    EmitWorld(K, False, D);
    GpiPointArc := PrimRes;
    Exit;
  End;
  B2 := Bx * Bx + By * By; C2 := Cx * Cx + Cy * Cy;
  Ux := MulDiv(B2, Cy, Dd) - MulDiv(C2, By, Dd);
  Uy := MulDiv(C2, Bx, Dd) - MulDiv(B2, Cx, Dd);
  R := ISqrt(Ux * Ux + Uy * Uy);
  A0 := Angle1024(-Ux, -Uy); A1 := Angle1024(Bx - Ux, By - Uy); A2 := Angle1024(Cx - Ux, Cy - Uy);
  S := (A2 - A0) And 1023;
  If ((A1 - A0) And 1023) > S Then S := S - 1024;
  { arc dans l'espace des parametres unitaires }
  M := R Shl 16;
  Sp := Gps[K].X[gxArcP]; Sq := Gps[K].X[gxArcQ]; Sr := Gps[K].X[gxArcR]; Ss := Gps[K].X[gxArcS];
  Gps[K].X[gxArcP] := 1; Gps[K].X[gxArcQ] := 1; Gps[K].X[gxArcR] := 0; Gps[K].X[gxArcS] := 0;
  WN := 1;
  ArcPts(K, Ax + Ux, Ay + Uy, M, A0, S);
  WX[WN - 1] := RdL(P + 8); WY[WN - 1] := RdL(P + 12);
  Gps[K].X[gxArcP] := Sp; Gps[K].X[gxArcQ] := Sq; Gps[K].X[gxArcR] := Sr; Gps[K].X[gxArcS] := Ss;
  EmitWorld(K, False, D);
  GpiPointArc := PrimRes;
End;

{ GpiPolyFillet(hps, lCount, aptlPoints) : courbe tangente aux lignes }
Function GpiPolyFillet(Hps, N, P : LongInt) : LongInt;
Var K, I, X0, Y0, Mx, My : LongInt; D : Boolean;
Begin
  GpiPolyFillet := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Or (N < 1) Then Exit;
  RecI(E_POLYFILLET); RecL(N);
  D := RecDone(K, P, N * 8);
  PrimStart(K);
  If N = 1 Then WPut(RdL(P), RdL(P + 4))
  Else
  Begin
    X0 := Gps[K].CurX; Y0 := Gps[K].CurY;
    For I := 0 To N - 2 Do
    Begin
      If I = N - 2 Then
      Begin
        Mx := RdL(P + (I + 1) * 8); My := RdL(P + (I + 1) * 8 + 4);
      End
      Else
      Begin
        Mx := (RdL(P + I * 8) + RdL(P + (I + 1) * 8)) Div 2; My := (RdL(P + I * 8 + 4) + RdL(P + (I + 1) * 8 + 4)) Div 2;
      End;
      ConicPts(X0, Y0, RdL(P + I * 8), RdL(P + I * 8 + 4), Mx, My, $10000);
      X0 := Mx; Y0 := My;
    End;
  End;
  EmitWorld(K, False, D);
  GpiPolyFillet := PrimRes;
End;

{ GpiPolyFilletSharp(hps, lCount, aptlPoints, afxPoints) : paires
  (controle, fin) et nettete }
Function GpiPolyFilletSharp(Hps, N, P, PS : LongInt) : LongInt;
Var K, I, X0, Y0, Buf : LongInt; D : Boolean;
Begin
  GpiPolyFilletSharp := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Or (PS = 0) Or (N < 2) Then Exit;
  RecI(E_POLYFILLETSHARP); RecL(N);
  { points puis nettetes }
  Buf := MemAlloc(N * 8 + (N Div 2) * 4 + 8);
  If Buf <> 0 Then
  Begin
    MemMove(P, Buf, N * 8);
    MemMove(PS, Buf + N * 8, (N Div 2) * 4);
  End;
  D := RecDone(K, Buf, N * 8 + (N Div 2) * 4);
  MemFree(Buf);
  PrimStart(K);
  X0 := Gps[K].CurX; Y0 := Gps[K].CurY;
  I := 0;
  While I + 1 < N Do
  Begin
    ConicPts(X0, Y0, RdL(P + I * 8), RdL(P + I * 8 + 4), RdL(P + I * 8 + 8), RdL(P + I * 8 + 12), RdL(PS + (I Div 2) * 4));
    X0 := RdL(P + I * 8 + 8); Y0 := RdL(P + I * 8 + 12);
    I := I + 2;
  End;
  EmitWorld(K, False, D);
  GpiPolyFilletSharp := PrimRes;
End;

{ GpiPolySpline(hps, lCount, aptlPoints) : courbes de Bezier par
  triplets (controle 1, controle 2, fin) }
Function GpiPolySpline(Hps, N, P : LongInt) : LongInt;
Var K, I, X0, Y0 : LongInt; D : Boolean;
Begin
  GpiPolySpline := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Or (N < 3) Then Exit;
  RecI(E_POLYSPLINE); RecL(N);
  D := RecDone(K, P, N * 8);
  PrimStart(K);
  X0 := Gps[K].CurX; Y0 := Gps[K].CurY;
  I := 0;
  While I + 2 < N Do
  Begin
    BezPts(X0, Y0, RdL(P + I * 8), RdL(P + I * 8 + 4), RdL(P + I * 8 + 8), RdL(P + I * 8 + 12),
           RdL(P + I * 8 + 16), RdL(P + I * 8 + 20));
    X0 := RdL(P + I * 8 + 16); Y0 := RdL(P + I * 8 + 20);
    I := I + 3;
  End;
  EmitWorld(K, False, D);
  GpiPolySpline := PrimRes;
End;

{ --- zones --- }
{ GpiBeginArea(hps, flOptions) : BA_BOUNDARY 1, BA_WINDING 2, BA_EXCL 8 }
Function GpiBeginArea(Hps, Fl : LongInt) : LongInt;
Var K, X, Y : LongInt;
Begin
  GpiBeginArea := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If (Gps[K].X[gxInArea] <> 0) Or (Gps[K].X[gxInPath] <> 0) Then
  Begin
    SetErr(PMERR_INV_IN_AREA);
    Exit;
  End;
  RecI(E_BEGINAREA); RecL(Fl);
  Dummy := LongInt(RecDone(K, 0, 0));
  Gps[K].X[gxInArea] := 1; Gps[K].X[gxAreaFl] := Fl;
  FgN := 0; FgCnt := 0;
  CompSet(K);
  XF(K, Gps[K].CurX, Gps[K].CurY, X, Y);
  FigNew(X, Y);
  GpiBeginArea := 1;
End;

{ trait des figures FgX/FgY avec les attributs de ligne }
Procedure StrokeFigs(K : LongInt; ForceClose : Boolean);
Var F, A, B, I : LongInt;
Begin
  For F := 0 To FgCnt - 1 Do
  Begin
    A := FgStart[F];
    If F < FgCnt - 1 Then B := FgStart[F + 1] Else B := FgN;
    If B - A >= 2 Then
    Begin
      For I := A To B - 1 Do
      Begin
        DXs[I - A] := FgX[I]; DYs[I - A] := FgY[I];
      End;
      StrokeDev(K, B - A, ForceClose Or (FgClosed[F] <> 0));
    End;
  End;
End;

Function GpiEndArea(Hps : LongInt) : LongInt;
Var K : LongInt; D : Boolean;
Begin
  GpiEndArea := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Gps[K].X[gxInArea] = 0 Then
  Begin
    SetErr(PMERR_INV_PARAMETER);
    Exit;
  End;
  RecI(E_ENDAREA);
  D := RecDone(K, 0, 0);
  Gps[K].X[gxInArea] := 0;
  If D And BeginDraw(K) Then
  Begin
    AreaFill(K, LongInt(@FgX), LongInt(@FgY), LongInt(@FgStart), FgCnt, FgN, (Gps[K].X[gxAreaFl] And 2) <> 0);
    If (Gps[K].X[gxAreaFl] And 1) <> 0 Then
    Begin
      BrushW := 0;
      StrokeFigs(K, True);
    End;
  End;
  FgN := 0; FgCnt := 0;
  GpiEndArea := PrimRes;
End;

{ --- chemins (le chemin 1 est le seul gere) --- }
Function GpiBeginPath(Hps, Id : LongInt) : LongInt;
Var K, X, Y : LongInt;
Begin
  GpiBeginPath := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If (Gps[K].X[gxInArea] <> 0) Or (Gps[K].X[gxInPath] <> 0) Or (Id <> 1) Then
  Begin
    SetErr(PMERR_INV_IN_PATH);
    Exit;
  End;
  RecI(E_BEGINPATH); RecL(Id);
  Dummy := LongInt(RecDone(K, 0, 0));
  Gps[K].X[gxInPath] := 1; Gps[K].X[gxPathId] := Id;
  FgN := 0; FgCnt := 0;
  CompSet(K);
  XF(K, Gps[K].CurX, Gps[K].CurY, X, Y);
  FigNew(X, Y);
  GpiBeginPath := 1;
End;

Function GpiCloseFigure(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiCloseFigure := 0;
  K := PsK(Hps);
  If (K < 0) Or (Gps[K].X[gxInPath] = 0) Then Exit;
  RecI(E_CLOSEFIGURE);
  Dummy := LongInt(RecDone(K, 0, 0));
  If FgCnt > 0 Then
  Begin
    FgClosed[FgCnt - 1] := 1;
    FigNew(FgX[FgStart[FgCnt - 1]], FgY[FgStart[FgCnt - 1]]);
  End;
  GpiCloseFigure := 1;
End;

Function GpiEndPath(Hps : LongInt) : LongInt;
Var K, I, N : LongInt;
Begin
  GpiEndPath := 0;
  K := PsK(Hps);
  If (K < 0) Or (Gps[K].X[gxInPath] = 0) Then Exit;
  RecI(E_ENDPATH);
  Dummy := LongInt(RecDone(K, 0, 0));
  Gps[K].X[gxInPath] := 0;
  { figures d'un seul point retirees }
  PathN := 0; PathFigs := 0;
  For I := 0 To FgCnt - 1 Do
  Begin
    If I < FgCnt - 1 Then N := FgStart[I + 1] - FgStart[I] Else N := FgN - FgStart[I];
    If N >= 2 Then
    Begin
      PathStart[PathFigs] := PathN; PathClosed[PathFigs] := FgClosed[I];
      Inc(PathFigs);
      MemMove(LongInt(@FgX[FgStart[I]]), LongInt(@PathX[PathN]), N * 4);
      MemMove(LongInt(@FgY[FgStart[I]]), LongInt(@PathY[PathN]), N * 4);
      PathN := PathN + N;
    End;
  End;
  PathOk := 1;
  FgN := 0; FgCnt := 0;
  GpiEndPath := 1;
End;

{ chemin -> figures de trace }
Procedure PathToFigs;
Var I : LongInt;
Begin
  MemMove(LongInt(@PathX), LongInt(@FgX), PathN * 4); MemMove(LongInt(@PathY), LongInt(@FgY), PathN * 4);
  FgN := PathN; FgCnt := PathFigs;
  For I := 0 To PathFigs - 1 Do
  Begin
    FgStart[I] := PathStart[I]; FgClosed[I] := PathClosed[I];
  End;
End;

{ GpiFillPath(hps, lPath, lOptions) : FPATH_WINDING 2 }
Function GpiFillPath(Hps, Id, Fl : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiFillPath := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If PathOk = 0 Then
  Begin
    SetErr(PMERR_PATH_UNKNOWN);
    Exit;
  End;
  RecI(E_FILLPATH); RecL(Id); RecL(Fl);
  If RecDone(K, 0, 0) And BeginDraw(K) Then
    AreaFill(K, LongInt(@PathX), LongInt(@PathY), LongInt(@PathStart), PathFigs, PathN, (Fl And 2) <> 0);
  PathOk := 0;
  GpiFillPath := PrimRes;
End;

{ GpiStrokePath(hps, lPath, flOptions) : largeur geometrique }
Function GpiStrokePath(Hps, Id, Fl : LongInt) : LongInt;
Var K, Wx, Wy : LongInt;
Begin
  GpiStrokePath := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If PathOk = 0 Then
  Begin
    SetErr(PMERR_PATH_UNKNOWN);
    Exit;
  End;
  RecI(E_STROKEPATH); RecL(Id); RecL(Fl);
  If RecDone(K, 0, 0) And BeginDraw(K) Then
  Begin
    CompSet(K);
    XFVec(K, Gps[K].LGeom Shl 16, 0, Wx, Wy);
    BrushW := MaxI(1, FRound(ISqrt(MulDiv(Wx, Wx, 65536) + MulDiv(Wy, Wy, 65536)) Shl 8));
    PathToFigs;
    StrokeFigs(K, False);
    BrushW := 0;
  End;
  PathOk := 0;
  GpiStrokePath := PrimRes;
End;

Function GpiOutlinePath(Hps, Id, Fl : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiOutlinePath := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If PathOk = 0 Then
  Begin
    SetErr(PMERR_PATH_UNKNOWN);
    Exit;
  End;
  RecI(E_OUTLINEPATH); RecL(Id); RecL(Fl);
  If RecDone(K, 0, 0) And BeginDraw(K) Then
  Begin
    PathToFigs;
    BrushW := 1;
    StrokeFigs(K, False);
    BrushW := 0;
  End;
  PathOk := 0;
  GpiOutlinePath := PrimRes;
End;

{ GpiModifyPath(hps, lPath, lMode) : MPATH_STROKE 6 : le contour devient
  la zone (largeur geometrique, approchee par un trait epais) }
Function GpiModifyPath(Hps, Id, Mode : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (PathOk = 0) Then GpiModifyPath := 0 Else GpiModifyPath := 1;
End;

{ region des pels d'un chemin (balayage) }
Function PathRegion(K : LongInt; Winding : Boolean) : LongInt;
Var R, Y, I, Ymin, Ymax, F, A, B, J, N, Y1, Y2, X1, X2, T, D, W, Xs : LongInt;
Begin
  PathRegion := -1;
  R := NewRgn;
  If R < 0 Then Exit;
  If PathN < 2 Then
  Begin
    PathRegion := R;
    Exit;
  End;
  Ymin := PathY[0]; Ymax := Ymin;
  For I := 0 To PathN - 1 Do
  Begin
    Ymin := MinI(Ymin, PathY[I]); Ymax := MaxI(Ymax, PathY[I]);
  End;
  For Y := Ymin To Ymax Do
  Begin
    N := 0;
    For F := 0 To PathFigs - 1 Do
    Begin
      A := PathStart[F];
      If F < PathFigs - 1 Then B := PathStart[F + 1] Else B := PathN;
      For I := A To B - 1 Do
      Begin
        If I = B - 1 Then J := A Else J := I + 1;
        Y1 := PathY[I]; Y2 := PathY[J];
        If ((2 * Y1 <= 2 * Y + 1) And (2 * Y + 1 < 2 * Y2)) Or ((2 * Y2 <= 2 * Y + 1) And (2 * Y + 1 < 2 * Y1)) Then
          If N < 2048 Then
          Begin
            X1 := PathX[I]; X2 := PathX[J];
            XC[N] := X1 * 2 + MulDiv(2 * Y + 1 - 2 * Y1, 2 * (X2 - X1), 2 * (Y2 - Y1));
            If Y2 > Y1 Then XD[N] := 1 Else XD[N] := -1;
            Inc(N);
          End;
      End;
    End;
    For I := 1 To N - 1 Do
    Begin
      T := XC[I]; D := XD[I]; J := I;
      While (J > 0) And (XC[J - 1] > T) Do
      Begin
        XC[J] := XC[J - 1]; XD[J] := XD[J - 1];
        Dec(J);
      End;
      XC[J] := T; XD[J] := D;
    End;
    If Winding Then
    Begin
      W := 0; Xs := 0;
      For I := 0 To N - 1 Do
      Begin
        If W = 0 Then Xs := XC[I];
        W := W + XD[I];
        If W = 0 Then RgAdd(R, Xs Div 2, Y, XC[I] Div 2, Y + 1);
      End;
    End
    Else
    Begin
      I := 0;
      While I + 1 < N Do
      Begin
        RgAdd(R, XC[I] Div 2, Y, XC[I + 1] Div 2, Y + 1);
        I := I + 2;
      End;
    End;
  End;
  { fusion des lignes identiques }
  Dummy := RgCombine(R, R, -1, 2);
  PathRegion := R;
End;

{ GpiPathToRegion(hps, lPath, lOptions) : HRGN }
Function GpiPathToRegion(Hps, Id, Fl : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  GpiPathToRegion := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If PathOk = 0 Then
  Begin
    SetErr(PMERR_PATH_UNKNOWN);
    Exit;
  End;
  R := PathRegion(K, (Fl And 2) <> 0);
  PathOk := 0;
  If R >= 0 Then GpiPathToRegion := $47520001 + R;
End;

{ GpiSetClipPath(hps, lPath, lOptions) : 0 SCP_RESET ; SCP_AND 1 }
Function GpiSetClipPath(Hps, Id, Fl : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  GpiSetClipPath := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Id = 0 Then
  Begin
    If Gps[K].X[gxClipPath] >= 0 Then
    Begin
      MemFree(RgData[Gps[K].X[gxClipPath]]);
      RgUse[Gps[K].X[gxClipPath]] := 0;
    End;
    Gps[K].X[gxClipPath] := -1;
    GpiSetClipPath := 1;
    Exit;
  End;
  If PathOk = 0 Then
  Begin
    SetErr(PMERR_PATH_UNKNOWN);
    Exit;
  End;
  R := PathRegion(K, (Fl And 2) <> 0);
  PathOk := 0;
  If R < 0 Then Exit;
  If Gps[K].X[gxClipPath] >= 0 Then
  Begin
    MemFree(RgData[Gps[K].X[gxClipPath]]);
    RgUse[Gps[K].X[gxClipPath]] := 0;
  End;
  Gps[K].X[gxClipPath] := R;
  GpiSetClipPath := 1;
End;

{ --- marqueurs --- }
Procedure MarkerAt(K, X, Y : LongInt; D : Boolean);
Var Dx, Dy, Hx, Hy, Vx, Vy : LongInt;
Begin
  Gps[K].CurX := X; Gps[K].CurY := Y;
  If Not D Then Exit;
  If Gps[K].MSym = 64 Then Exit;
  CompSet(K);
  XF(K, X, Y, Dx, Dy);
  XFVec(K, Gps[K].MBoxX, 0, Vx, Vy);
  Hx := FRound(ISqrt(MulDiv(Vx, Vx, 65536) + MulDiv(Vy, Vy, 65536)) Shl 8) Div 2;
  XFVec(K, 0, Gps[K].MBoxY, Vx, Vy);
  Hy := FRound(ISqrt(MulDiv(Vx, Vx, 65536) + MulDiv(Vy, Vy, 65536)) Shl 8) Div 2;
  If BeginDraw(K) Then DrawMarker(K, Dx, Dy, Hx, Hy);
End;

Function GpiMarker(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiMarker := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E_MARKER); RecL(RdL(P)); RecL(RdL(P + 4));
  MarkerAt(K, RdL(P), RdL(P + 4), RecDone(K, 0, 0));
  GpiMarker := PrimRes;
End;

Function GpiPolyMarker(Hps, N, P : LongInt) : LongInt;
Var K, I : LongInt; D : Boolean;
Begin
  GpiPolyMarker := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E_POLYMARKER); RecL(N);
  D := RecDone(K, P, N * 8);
  For I := 0 To N - 1 Do MarkerAt(K, RdL(P + I * 8), RdL(P + I * 8 + 4), D);
  GpiPolyMarker := PrimRes;
End;

{ --- texte --- }
Function GpiCharString(Hps, N, P : LongInt) : LongInt;
Var K, X, Y : LongInt; D : Boolean;
Begin
  GpiCharString := 0;
  K := PsK(Hps);
  If (K < 0) Or ((P = 0) And (N > 0)) Then Exit;
  RecI(E_CHARSTRING); RecL(Gps[K].CurX); RecL(Gps[K].CurY); RecL(N);
  D := RecDone(K, P, N);
  DrawText(K, Gps[K].CurX, Gps[K].CurY, P, N, 0, D, X, Y);
  Gps[K].CurX := X; Gps[K].CurY := Y;
  GpiCharString := PrimRes;
End;

Function GpiCharStringAt(Hps, PPt, N, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiCharStringAt := 0;
  K := PsK(Hps);
  If (K < 0) Or (PPt = 0) Then Exit;
  If GpiMove(Hps, PPt) = 0 Then Exit;
  GpiCharStringAt := GpiCharString(Hps, N, P);
End;

{ GpiCharStringPosAt(hps, pptlStart, prclRect, flOptions, lCount,
  pchString, alAdx) : CHS_OPAQUE 1, CHS_VECTOR 2, CHS_LEAVEPOS 8,
  CHS_CLIP 10h, CHS_UNDERSCORE 200h, CHS_STRIKEOUT 400h }
Function GpiCharStringPosAt(Hps, PPt, PR, Fl, N, P, Adx : LongInt) : LongInt;
Var K, X, Y, X0, Y0, Vx, Vy, Dx1, Dy1, Dx2, Dy2, I, Yy, V, Bk, Mx : LongInt; D : Boolean;
Begin
  GpiCharStringPosAt := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If PPt <> 0 Then
  Begin
    Gps[K].CurX := RdL(PPt); Gps[K].CurY := RdL(PPt + 4);
  End;
  X0 := Gps[K].CurX; Y0 := Gps[K].CurY;
  RecI(E_CHARSTRINGPOS); RecL(X0); RecL(Y0); RecL(Fl); RecL(N);
  If PR <> 0 Then
  Begin
    RecL(RdL(PR)); RecL(RdL(PR + 4)); RecL(RdL(PR + 8)); RecL(RdL(PR + 12));
  End
  Else
  Begin
    RecL(0); RecL(0); RecL(0); RecL(0);
  End;
  D := RecDone(K, P, N);
  If D And (PR <> 0) And (((Fl And 1) <> 0) Or ((Fl And $10) <> 0)) And BeginDraw(K) Then
  Begin
    CompSet(K);
    XF(K, RdL(PR), RdL(PR + 4), Dx1, Dy1); XF(K, RdL(PR + 8), RdL(PR + 12), Dx2, Dy2);
    If (Fl And 1) <> 0 Then
    Begin
      Bk := ClrDev(K, Gps[K].CBack, True);
      PatOn := 0;
      For Yy := MinI(Dy1, Dy2) To MaxI(Dy1, Dy2) - 1 Do
        DSpan(MinI(Dx1, Dx2), MaxI(Dx1, Dx2), Yy, Bk, 0, FM_OVERPAINT, FM_LEAVEALONE);
    End;
  End;
  If (Fl And $10) <> 0 Then
  Begin
    { decoupage au rectangle : limites de vue temporaires }
    If PR <> 0 Then
    Begin
      Gps[K].X[gxGfOn] := Gps[K].X[gxGfOn] Or 2;
      Gps[K].X[gxGfX1] := RdL(PR); Gps[K].X[gxGfY1] := RdL(PR + 4); Gps[K].X[gxGfX2] := RdL(PR + 8) - 1; Gps[K].X[gxGfY2] := RdL(PR + 12) - 1;
    End;
  End;
  If (Fl And 2) <> 0 Then DrawText(K, X0, Y0, P, N, Adx, D, X, Y)
  Else DrawText(K, X0, Y0, P, N, 0, D, X, Y);
  If (Fl And $10) <> 0 Then Gps[K].X[gxGfOn] := Gps[K].X[gxGfOn] And 1;
  If D And ((Fl And $600) <> 0) And BeginDraw(K) Then
  Begin
    { souligne et barre : lignes sous et dans les caracteres }
    CompSet(K);
    V := ClrDev(K, Gps[K].CColor, False);
    Mx := Gps[K].CMix;
    If Mx = 0 Then Mx := FM_OVERPAINT;
    XF(K, X0, Y0, Dx1, Dy1); XF(K, X, Y, Dx2, Dy2);
    BrushW := 1;
    If (Fl And $200) <> 0 Then DLine(K, Dx1, Dy1 - 2, Dx2, Dy2 - 2, V, 0, Mx, 0, $FFFF, False);
    If (Fl And $400) <> 0 Then DLine(K, Dx1, Dy1 + 5, Dx2, Dy2 + 5, V, 0, Mx, 0, $FFFF, False);
  End;
  If (Fl And 8) = 0 Then
  Begin
    Gps[K].CurX := X; Gps[K].CurY := Y;
  End;
  I := 0;
  GpiCharStringPosAt := PrimRes;
End;

Function GpiCharStringPos(Hps, PR, Fl, N, P, Adx : LongInt) : LongInt;
Begin
  GpiCharStringPos := GpiCharStringPosAt(Hps, 0, PR, Fl, N, P, Adx);
End;

{ GpiQueryCharStringPosAt(hps, pptlStart, flOptions, lCount, pchString,
  alXincrements, aptlPositions) : positions des N + 1 caracteres }
Function GpiQueryCharStringPosAt(Hps, PPt, Fl, N, P, Adx, PPos : LongInt) : LongInt;
Var K, I, X, Y, W, R, Ax, Ay : LongInt;
Begin
  GpiQueryCharStringPosAt := 0;
  K := PsK(Hps);
  If (K < 0) Or (PPos = 0) Then Exit;
  If PPt <> 0 Then
  Begin
    X := RdL(PPt); Y := RdL(PPt + 4);
  End
  Else
  Begin
    X := Gps[K].CurX; Y := Gps[K].CurY;
  End;
  Ax := Gps[K].CAngX; Ay := Gps[K].CAngY;
  R := ISqrt(MinI(Ax * Ax + Ay * Ay, 2000000000));
  If R = 0 Then R := 1;
  W := 0;
  For I := 0 To N Do
  Begin
    WrL(PPos + I * 8, X + MulDiv(W, Ax, R)); WrL(PPos + I * 8 + 4, Y + MulDiv(W, Ay, R));
    If I < N Then
    Begin
      If ((Fl And 2) <> 0) And (Adx <> 0) Then W := W + RdL(Adx + I * 4)
      Else W := W + FRound(Gps[K].CBoxX + Gps[K].CExtra);
    End;
  End;
  GpiQueryCharStringPosAt := 1;
End;

Function GpiQueryCharStringPos(Hps, Fl, N, P, Adx, PPos : LongInt) : LongInt;
Begin
  GpiQueryCharStringPos := GpiQueryCharStringPosAt(Hps, 0, Fl, N, P, Adx, PPos);
End;

{ GpiQueryTextBox(hps, lCount1, pchString, lCount2, aptlPoints) :
  TXTBOX_TOPLEFT 0, BOTTOMLEFT 1, TOPRIGHT 2, BOTTOMRIGHT 3, CONCAT 4 }
Function GpiQueryTextBox(Hps, N, P, N2, PPt : LongInt) : LongInt;
Var K, W, Asc, Dsc, Ax, Ay, R, I : LongInt; V : Array[0..9] Of LongInt;
Begin
  GpiQueryTextBox := 0;
  K := PsK(Hps);
  If (K < 0) Or (PPt = 0) Then Exit;
  W := FRound((Gps[K].CBoxX + Gps[K].CExtra) * N);
  Asc := FRound(MulDiv(Gps[K].CBoxY, 12, 16)); Dsc := FRound(MulDiv(Gps[K].CBoxY, 4, 16));
  V[0] := 0; V[1] := Asc; V[2] := 0; V[3] := -Dsc; V[4] := W; V[5] := Asc; V[6] := W; V[7] := -Dsc; V[8] := W; V[9] := 0;
  Ax := Gps[K].CAngX; Ay := Gps[K].CAngY;
  R := ISqrt(MinI(Ax * Ax + Ay * Ay, 2000000000));
  If R = 0 Then R := 1;
  For I := 0 To MinI(N2, 5) - 1 Do
  Begin
    WrL(PPt + I * 8, MulDiv(V[I * 2], Ax, R) - MulDiv(V[I * 2 + 1], Ay, R));
    WrL(PPt + I * 8 + 4, MulDiv(V[I * 2], Ay, R) + MulDiv(V[I * 2 + 1], Ax, R));
  End;
  GpiQueryTextBox := 1;
End;

{ --- image (1 bit par pel, lignes de haut en bas, octets entiers) --- }
Function GpiImage(Hps, Fmt, PSz, Len, P : LongInt) : LongInt;
Var K, W, H, X, Y, Dx, Dy, St, Fg, Bg, Mx, BMx, B : LongInt; D : Boolean;
Begin
  GpiImage := 0;
  K := PsK(Hps);
  If (K < 0) Or (PSz = 0) Or (P = 0) Then Exit;
  W := RdL(PSz); H := RdL(PSz + 4);
  St := (W + 7) Div 8;
  RecI(E_IMAGE); RecL(Fmt); RecL(W); RecL(H); RecL(Len);
  D := RecDone(K, P, MinI(Len, St * H));
  If D And BeginDraw(K) Then
  Begin
    CompSet(K);
    XF(K, Gps[K].CurX, Gps[K].CurY, Dx, Dy);
    Fg := ClrDev(K, Gps[K].IColor, False); Bg := ClrDev(K, Gps[K].IBack, True);
    Mx := Gps[K].IMix;
    If Mx = 0 Then Mx := FM_OVERPAINT;
    BMx := Gps[K].IBMix;
    If BMx = 0 Then BMx := FM_LEAVEALONE;
    For Y := 0 To H - 1 Do
      For X := 0 To W - 1 Do
        If Y * St + X Div 8 < Len Then
        Begin
          B := (RdB(P + Y * St + X Div 8) Shr (7 - (X And 7))) And 1;
          If B <> 0 Then DPix(Dx + X, Dy - Y, Fg, Mx) Else DPix(Dx + X, Dy - Y, Bg, BMx);
        End;
  End;
  GpiImage := PrimRes;
End;

{ --- pels --- }
Function GpiSetPel(Hps, P : LongInt) : LongInt;
Var K, Dx, Dy, Mx : LongInt;
Begin
  GpiSetPel := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  RecI(E_SETPEL); RecL(RdL(P)); RecL(RdL(P + 4));
  If RecDone(K, 0, 0) And BeginDraw(K) Then
  Begin
    CompSet(K);
    XF(K, RdL(P), RdL(P + 4), Dx, Dy);
    Mx := Gps[K].LMix;
    If Mx = 0 Then Mx := FM_OVERPAINT;
    DPix(Dx, Dy, ClrDev(K, Gps[K].LColor, False), Mx);
  End;
  GpiSetPel := PrimRes;
End;

{ couleur logique (index le plus proche, ou RVB) d'une valeur du
  peripherique }
Function LogOfDev(K, V : LongInt) : LongInt;
Var Rgb, I, B, D, Bd : LongInt;
Begin
  Rgb := DevRgb(V);
  If Gps[K].X[gxLogMode] = 3 Then
  Begin
    LogOfDev := Rgb;
    Exit;
  End;
  B := 0; Bd := $7FFFFFFF;
  For I := 0 To Gps[K].X[gxLogN] - 1 Do
  Begin
    D := RgbDist(RdL(Gps[K].X[gxLogTab] + I * 4), Rgb);
    If D < Bd Then
    Begin
      Bd := D; B := I;
    End;
  End;
  LogOfDev := B;
End;

Function GpiQueryPel(Hps, P : LongInt) : LongInt;
Var K, Dx, Dy, Sx, Sy : LongInt;
Begin
  GpiQueryPel := -255;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  If Not BeginDraw(K) Then Exit;
  CompSet(K);
  XF(K, RdL(P), RdL(P + 4), Dx, Dy);
  Sx := Dx + TgOffX; Sy := Dy + TgOffY;
  If Not InClip(Sx, Sy) Then Exit;
  GpiQueryPel := LogOfDev(K, TgGet(Sx, Sy));
End;

{ GpiPtVisible(hps, pptlPoint) : PVIS_INVISIBLE 1, PVIS_VISIBLE 2 }
Function GpiPtVisible(Hps, P : LongInt) : LongInt;
Var K, Dx, Dy : LongInt;
Begin
  GpiPtVisible := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  GpiPtVisible := 1;
  If Not BeginDraw(K) Then Exit;
  CompSet(K);
  XF(K, RdL(P), RdL(P + 4), Dx, Dy);
  If InClip(Dx + TgOffX, Dy + TgOffY) Then GpiPtVisible := 2;
End;

{ GpiRectVisible(hps, prclRectangle) : RVIS_INVISIBLE 1, RVIS_PARTIAL 2,
  RVIS_VISIBLE 3 }
Function GpiRectVisible(Hps, P : LongInt) : LongInt;
Var K, X1, Y1, X2, Y2, A, B, I, In1, Area, Tot : LongInt;
Begin
  GpiRectVisible := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  GpiRectVisible := 1;
  If Not BeginDraw(K) Then Exit;
  CompSet(K);
  XF(K, RdL(P), RdL(P + 4), A, B); XF(K, RdL(P + 8), RdL(P + 12), X2, Y2);
  X1 := MinI(A, X2) + TgOffX; Y1 := MinI(B, Y2) + TgOffY; X2 := MaxI(A, X2) + TgOffX; Y2 := MaxI(B, Y2) + TgOffY;
  Tot := (X2 - X1) * (Y2 - Y1); Area := 0;
  For I := 0 To ClipN - 1 Do
  Begin
    A := MaxI(0, MinI(X2, ClipX2[I]) - MaxI(X1, ClipX1[I]));
    B := MaxI(0, MinI(Y2, ClipY2[I]) - MaxI(Y1, ClipY1[I]));
    Area := Area + A * B;
  End;
  In1 := 1;
  If Area > 0 Then In1 := 2;
  If (Tot > 0) And (Area >= Tot) Then In1 := 3;
  GpiRectVisible := In1;
End;

{ GpiFloodFill(hps, lOptions, lColor) : FF_BOUNDARY 0, FF_SURFACE 1 }
Function GpiFloodFill(Hps, Opt, C : LongInt) : LongInt;
Var K, Dx, Dy : LongInt;
Begin
  GpiFloodFill := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E_FLOODFILL); RecL(Opt); RecL(C);
  If RecDone(K, 0, 0) And BeginDraw(K) Then
  Begin
    CompSet(K);
    XF(K, Gps[K].CurX, Gps[K].CurY, Dx, Dy);
    Dummy := FloodDev(K, Dx, Dy, ClrDev(K, C, False), Opt = 1);
  End;
  GpiFloodFill := 1;
End;

{ GpiPolygons(hps, ulCount, paplgn, flOptions, flModel) : POLYGON
  (ulPoints, aPointl) ; POLYGON_BOUNDARY 1, POLYGON_WINDING 2 }
Function GpiPolygons(Hps, N, P, Fl, Md : LongInt) : LongInt;
Var K, I, J, Np, Pp, X, Y : LongInt;
Begin
  GpiPolygons := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  If Not RecDone(K, 0, 0) Then
  Begin
    GpiPolygons := 1;
    Exit;
  End;
  CompSet(K);
  FgN := 0; FgCnt := 0;
  XF(K, Gps[K].CurX, Gps[K].CurY, X, Y);
  For I := 0 To N - 1 Do
  Begin
    Np := RdL(P + I * 8); Pp := RdL(P + I * 8 + 4);
    If I = 0 Then FigNew(X, Y) Else
    Begin
      XF(K, RdL(Pp + (Np - 1) * 8), RdL(Pp + (Np - 1) * 8 + 4), X, Y);
      FigNew(X, Y);
    End;
    For J := 0 To Np - 1 Do
    Begin
      XF(K, RdL(Pp + J * 8), RdL(Pp + J * 8 + 4), X, Y);
      FigAdd(X, Y);
    End;
  End;
  If BeginDraw(K) Then
  Begin
    AreaFill(K, LongInt(@FgX), LongInt(@FgY), LongInt(@FgStart), FgCnt, FgN, (Fl And 2) <> 0);
    If (Fl And 1) <> 0 Then
    Begin
      BrushW := 0;
      StrokeFigs(K, True);
    End;
  End;
  FgN := 0; FgCnt := 0;
  GpiPolygons := PrimRes;
End;


{ ==================================================================== }
{ Partie 6 - Bitmaps, transferts de blocs, regions, couleurs, polices,  }
{ transformations                                                       }
{ ==================================================================== }

{ --- en-tetes de bitmaps : BITMAPINFOHEADER (cbFix 12 : cx, cy, cPlanes,
  cBitCount en USHORT) ou BITMAPINFOHEADER2 (cx, cy en ULONG, puis
  cPlanes, cBitCount, ulCompression...) ; table de couleurs apres
  l'en-tete : RGB (3 octets) ou RGB2 (4 octets) --- }
Procedure HdrRead(P : LongInt; Var Cx, Cy, Bpp : LongInt);
Begin
  If RdL(P) = 12 Then
  Begin
    Cx := RdW(P + 4); Cy := RdW(P + 6); Bpp := RdW(P + 8) * RdW(P + 10);
  End
  Else
  Begin
    Cx := RdL(P + 4); Cy := RdL(P + 8); Bpp := RdW(P + 12) * RdW(P + 14);
  End;
  If Bpp = 0 Then Bpp := 1;
End;

{ couleur numero I de la table d'une BITMAPINFO }
Function HdrColor(P, I : LongInt) : LongInt;
Var A : LongInt;
Begin
  If RdL(P) = 12 Then
  Begin
    A := P + 12 + I * 3;
    HdrColor := RdB(A) Or (RdB(A + 1) Shl 8) Or (RdB(A + 2) Shl 16);
  End
  Else
  Begin
    A := P + RdL(P) + I * 4;
    HdrColor := RdB(A) Or (RdB(A + 1) Shl 8) Or (RdB(A + 2) Shl 16);
  End;
End;

Procedure HdrSetColor(P, I, Rgb : LongInt);
Var A : LongInt;
Begin
  If RdL(P) = 12 Then
  Begin
    A := P + 12 + I * 3;
    WrB(A, Rgb); WrB(A + 1, Rgb Shr 8); WrB(A + 2, Rgb Shr 16);
  End
  Else
  Begin
    A := P + RdL(P) + I * 4;
    WrB(A, Rgb); WrB(A + 1, Rgb Shr 8); WrB(A + 2, Rgb Shr 16); WrB(A + 3, 0);
  End;
End;

{ pel numero X d'une ligne de Bpp bits }
Function RowPix(A, Bpp, X : LongInt) : LongInt;
Begin
  Case Bpp Of
    1 : RowPix := (RdB(A + X Shr 3) Shr (7 - (X And 7))) And 1;
    4 : If (X And 1) = 0 Then RowPix := RdB(A + X Shr 1) Shr 4 Else RowPix := RdB(A + X Shr 1) And 15;
    8 : RowPix := RdB(A + X);
  Else
    RowPix := RdB(A + X * 3) Or (RdB(A + X * 3 + 1) Shl 8) Or (RdB(A + X * 3 + 2) Shl 16);
  End;
End;

Procedure RowSet(A, Bpp, X, V : LongInt);
Var B : LongInt;
Begin
  Case Bpp Of
    1 :
      Begin
        B := RdB(A + X Shr 3);
        If (V And 1) <> 0 Then B := B Or ($80 Shr (X And 7)) Else B := B And Not ($80 Shr (X And 7));
        WrB(A + X Shr 3, B);
      End;
    4 :
      Begin
        B := RdB(A + X Shr 1);
        If (X And 1) = 0 Then B := (B And $0F) Or ((V And 15) Shl 4) Else B := (B And $F0) Or (V And 15);
        WrB(A + X Shr 1, B);
      End;
    8 : WrB(A + X, V);
  Else
    Begin
      WrB(A + X * 3, V); WrB(A + X * 3 + 1, V Shr 8); WrB(A + X * 3 + 2, V Shr 16);
    End;
  End;
End;

{ copier des lignes d'une application (format de Pbmi) dans le bitmap B }
Function BitsIn(B, St, N, PBits, Pbmi : LongInt) : LongInt;
Var Cx, Cy, Bpp, SStride, Y, X, V, Rgb, T, Nc : LongInt;
Begin
  HdrRead(Pbmi, Cx, Cy, Bpp);
  SStride := ((Cx * Bpp + 31) Div 32) * 4;
  T := BmPal[B];
  Nc := 1 Shl MinI(BmBpp[B], 8);
  For Y := 0 To N - 1 Do
    If (St + Y >= 0) And (St + Y < BmCy[B]) Then
      For X := 0 To MinI(Cx, BmCx[B]) - 1 Do
      Begin
        V := RowPix(PBits + Y * SStride, Bpp, X);
        If Bpp <= 8 Then Rgb := HdrColor(Pbmi, V) Else Rgb := V;
        If BmBpp[B] >= 24 Then V := Rgb Else V := Nearest(T, Nc, Rgb);
        RowSet(BmBits[B] + (St + Y) * BmStride[B], BmBpp[B], X, V);
      End;
  BitsIn := N;
End;

{ copier des lignes du bitmap B vers une application (format de Pbmi,
  table de couleurs remplie) }
Function BitsOut(B, St, N, PBits, Pbmi : LongInt) : LongInt;
Var Cx, Cy, Bpp, DStride, Y, X, V, Rgb, I, Nc, Tab : LongInt;
Begin
  HdrRead(Pbmi, Cx, Cy, Bpp);
  If Cx = 0 Then Cx := BmCx[B];
  DStride := ((Cx * Bpp + 31) Div 32) * 4;
  { table de couleurs : celle du bitmap si meme profondeur, sinon la
    table standard }
  Nc := 1 Shl MinI(Bpp, 8);
  Tab := MemAlloc(1024);
  If Tab = 0 Then
  Begin
    BitsOut := 0;
    Exit;
  End;
  If Bpp <= 8 Then
  Begin
    For I := 0 To Nc - 1 Do
    Begin
      If (Bpp = BmBpp[B]) Then V := RdL(BmPal[B] + I * 4)
      Else If Bpp = 1 Then
      Begin
        If I = 0 Then V := 0 Else V := $FFFFFF;
      End
      Else If Bpp = 4 Then V := Vga16[I]
      Else V := Pal256[I];
      WrL(Tab + I * 4, V);
      HdrSetColor(Pbmi, I, V);
    End;
  End;
  For Y := 0 To N - 1 Do
    If (St + Y >= 0) And (St + Y < BmCy[B]) And (PBits <> 0) Then
      For X := 0 To MinI(Cx, BmCx[B]) - 1 Do
      Begin
        V := RowPix(BmBits[B] + (St + Y) * BmStride[B], BmBpp[B], X);
        If BmBpp[B] <= 8 Then Rgb := RdL(BmPal[B] + V * 4) Else Rgb := V;
        If Bpp >= 24 Then V := Rgb
        Else If Bpp = BmBpp[B] Then V := V
        Else V := Nearest(Tab, Nc, Rgb);
        RowSet(PBits + Y * DStride, Bpp, X, V);
      End;
  MemFree(Tab);
  BitsOut := N;
End;

{ GpiCreateBitmap(hps, pbmpNew, flOptions, pbInitData, pbmiInfoTable) :
  CBM_INIT 4 }
Function GpiCreateBitmap(Hps, PHdr, Fl, PInit, Pbmi : LongInt) : LongInt;
Var Cx, Cy, Bpp, B, I, N : LongInt;
Begin
  GpiCreateBitmap := 0;
  If PHdr = 0 Then
  Begin
    SetErr(PMERR_INV_PARAMETER);
    Exit;
  End;
  HdrRead(PHdr, Cx, Cy, Bpp);
  B := NewBitmap(Cx, Cy, Bpp);
  If B < 0 Then
  Begin
    SetErr(PMERR_INSUFFICIENT_MEMORY);
    Exit;
  End;
  If (Pbmi <> 0) And (BmBpp[B] <= 8) Then
  Begin
    HdrRead(Pbmi, Cx, Cy, Bpp);
    If Bpp = BmBpp[B] Then
    Begin
      N := 1 Shl Bpp;
      For I := 0 To N - 1 Do WrL(BmPal[B] + I * 4, HdrColor(Pbmi, I));
    End;
  End;
  If ((Fl And 4) <> 0) And (PInit <> 0) And (Pbmi <> 0) Then Dummy := BitsIn(B, 0, BmCy[B], PInit, Pbmi);
  GpiCreateBitmap := $47420001 + B;
End;

Function GpiDeleteBitmap(H : LongInt) : LongInt;
Var B : LongInt;
Begin
  GpiDeleteBitmap := 0;
  B := BmIdx(H);
  If B < 0 Then
  Begin
    SetErr(PMERR_INV_HBITMAP);
    Exit;
  End;
  If BmDc[B] >= 0 Then
  Begin
    SetErr(PMERR_BITMAP_IS_SELECTED);
    Exit;
  End;
  FreeBitmap(B);
  GpiDeleteBitmap := 1;
End;

{ GpiSetBitmap(hps, hbm) : bitmap du DC memoire ; rend l'ancien (-1
  erreur) }
Function GpiSetBitmap(Hps, H : LongInt) : LongInt;
Var K, D, B, Old : LongInt;
Begin
  GpiSetBitmap := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  D := Gps[K].Dc;
  If (D < 0) Or (DcType[D] <> OD_MEMORY) Then
  Begin
    SetErr(PMERR_INV_HDC);
    Exit;
  End;
  B := -1;
  If H <> 0 Then
  Begin
    B := BmIdx(H);
    If B < 0 Then
    Begin
      SetErr(PMERR_INV_HBITMAP);
      Exit;
    End;
    If (BmDc[B] >= 0) And (BmDc[B] <> D) Then
    Begin
      SetErr(PMERR_BITMAP_IS_SELECTED);
      Exit;
    End;
  End;
  Old := DcBmp[D];
  If Old >= 0 Then BmDc[Old] := -1;
  DcBmp[D] := B;
  If B >= 0 Then BmDc[B] := D;
  If (Gps[K].Units And $1C) = 8 Then
  Begin
    Gps[K].PgW := 0; Gps[K].PgH := 0;
    ViewportDefault(K);
  End;
  If Old >= 0 Then GpiSetBitmap := $47420001 + Old Else GpiSetBitmap := 0;
End;

Function GpiSetBitmapDimension(H, P : LongInt) : LongInt;
Var B : LongInt;
Begin
  B := BmIdx(H);
  If (B < 0) Or (P = 0) Then GpiSetBitmapDimension := 0
  Else
  Begin
    BmDimX[B] := RdL(P); BmDimY[B] := RdL(P + 4);
    GpiSetBitmapDimension := 1;
  End;
End;

Function GpiQueryBitmapDimension(H, P : LongInt) : LongInt;
Var B : LongInt;
Begin
  B := BmIdx(H);
  If (B < 0) Or (P = 0) Then GpiQueryBitmapDimension := 0
  Else
  Begin
    WrL(P, BmDimX[B]); WrL(P + 4, BmDimY[B]);
    GpiQueryBitmapDimension := 1;
  End;
End;

{ GpiQueryBitmapParameters(hbm, pbmpData) : BITMAPINFOHEADER (12) }
Function GpiQueryBitmapParameters(H, P : LongInt) : LongInt;
Var B : LongInt;
Begin
  B := BmIdx(H);
  If (B < 0) Or (P = 0) Then GpiQueryBitmapParameters := 0
  Else
  Begin
    WrL(P, 12); WrW(P + 4, BmCx[B]); WrW(P + 6, BmCy[B]); WrW(P + 8, 1); WrW(P + 10, BmBpp[B]);
    GpiQueryBitmapParameters := 1;
  End;
End;

{ GpiQueryBitmapInfoHeader(hbm, pbmpData) : BITMAPINFOHEADER2 (cbFix
  donne la taille a remplir) }
Function GpiQueryBitmapInfoHeader(H, P : LongInt) : LongInt;
Var B, Cb : LongInt; Tmp : Array[0..15] Of LongInt;
Begin
  GpiQueryBitmapInfoHeader := 0;
  B := BmIdx(H);
  If (B < 0) Or (P = 0) Then Exit;
  Cb := RdL(P);
  If (Cb < 16) Or (Cb > 64) Then Cb := 64;
  MemZero(LongInt(@Tmp), 64);
  Tmp[0] := Cb; Tmp[1] := BmCx[B]; Tmp[2] := BmCy[B];
  WrW(LongInt(@Tmp) + 12, 1); WrW(LongInt(@Tmp) + 14, BmBpp[B]);
  Tmp[5] := BmStride[B] * BmCy[B]; Tmp[6] := 3780; Tmp[7] := 3780;
  If BmBpp[B] <= 8 Then Tmp[8] := 1 Shl BmBpp[B];
  MemMove(LongInt(@Tmp), P, Cb);
  GpiQueryBitmapInfoHeader := 1;
End;

{ GpiQueryDeviceBitmapFormats(hps, lCount, alArray) : paires (plans,
  bits) }
Function GpiQueryDeviceBitmapFormats(Hps, N, P : LongInt) : LongInt;
Var I, V : LongInt;
Begin
  GpiQueryDeviceBitmapFormats := 0;
  If (PsK(Hps) < 0) Or (P = 0) Then Exit;
  For I := 0 To MinI(N, 8) - 1 Do
  Begin
    Case I Of
      1 : V := 4;
      3 : V := 1;
      5 : V := 8;
      7 : V := 24;
    Else
      V := 1;
    End;
    WrL(P + I * 4, V);
  End;
  GpiQueryDeviceBitmapFormats := 1;
End;

{ bitmap du DC memoire de l'espace K (-1) }
Function PsBitmap(K : LongInt) : LongInt;
Var D : LongInt;
Begin
  PsBitmap := -1;
  D := Gps[K].Dc;
  If (D >= 0) And (DcType[D] = OD_MEMORY) Then PsBitmap := DcBmp[D];
End;

{ GpiSetBitmapBits(hps, lScanStart, lScans, pbBuffer, pbmiInfoTable) }
Function GpiSetBitmapBits(Hps, St, N, PBits, Pbmi : LongInt) : LongInt;
Var K, B : LongInt;
Begin
  GpiSetBitmapBits := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  B := PsBitmap(K);
  If (B < 0) Or (Pbmi = 0) Or (PBits = 0) Then
  Begin
    SetErr(PMERR_NO_BITMAP_SELECTED);
    Exit;
  End;
  GpiSetBitmapBits := BitsIn(B, St, N, PBits, Pbmi);
End;

Function GpiQueryBitmapBits(Hps, St, N, PBits, Pbmi : LongInt) : LongInt;
Var K, B : LongInt;
Begin
  GpiQueryBitmapBits := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  B := PsBitmap(K);
  If (B < 0) Or (Pbmi = 0) Then
  Begin
    SetErr(PMERR_NO_BITMAP_SELECTED);
    Exit;
  End;
  GpiQueryBitmapBits := BitsOut(B, St, N, PBits, Pbmi);
End;

Function GpiSetBitmapOwner(Hps, H, Owner : LongInt) : LongInt;
Var B : LongInt;
Begin
  B := BmIdx(H);
  If B < 0 Then GpiSetBitmapOwner := 0
  Else
  Begin
    BmPid[B] := Owner;
    GpiSetBitmapOwner := 1;
  End;
End;

{ GpiLoadBitmap(hps, hmod, ulId, lWidth, lHeight) : ressource RT_BITMAP
  (2) : BITMAPFILEHEADER ('BM', cbSize, xHot, yHot, offBits, en-tete) ou
  BITMAPARRAYFILEHEADER ('BA' : premier bitmap) }
Function GpiLoadBitmap(Hps, Hmod, Id, W, H : LongInt) : LongInt;
Var P, Hb, Hdr, Off, Cx, Cy, Bpp, B, B2, X, Y, Sx, Sy, V, HdrLen : LongInt;
Begin
  GpiLoadBitmap := 0;
  P := 0;
  If DcGetResource(Hmod, 2, Id, LongInt(@P)) <> 0 Then P := 0;
  If P = 0 Then
  Begin
    SetErr(PMERR_INV_PARAMETER);
    Exit;
  End;
  If RdW(P) = $4142 Then P := P + 14;                       { 'BA' }
  If RdW(P) <> $4D42 Then Exit;
  Off := RdL(P + 10);
  Hdr := P + 14;
  HdrRead(Hdr, Cx, Cy, Bpp);
  HdrLen := 0;
  Hb := GpiCreateBitmap(Hps, Hdr, 4, P + Off, Hdr);
  If Hb = 0 Then Exit;
  If ((W > 0) And (W <> Cx)) Or ((H > 0) And (H <> Cy)) Then
  Begin
    B := BmIdx(Hb);
    If W <= 0 Then W := Cx;
    If H <= 0 Then H := Cy;
    B2 := NewBitmap(W, H, BmBpp[B]);
    If B2 >= 0 Then
    Begin
      MemMove(BmPal[B], BmPal[B2], 1024);
      For Y := 0 To H - 1 Do
        For X := 0 To W - 1 Do
        Begin
          Sx := MulDiv(X, Cx, W); Sy := MulDiv(Y, Cy, H);
          V := RowPix(BmBits[B] + Sy * BmStride[B], BmBpp[B], Sx);
          RowSet(BmBits[B2] + Y * BmStride[B2], BmBpp[B2], X, V);
        End;
      FreeBitmap(B);
      Hb := $47420001 + B2;
    End;
  End;
  GpiLoadBitmap := Hb;
End;

{ --- transfert de blocs --- }

Procedure TgSave;
Begin
  SvKind := TgKind; SvW := TgW; SvH := TgH; SvBase := TgBase; SvStride := TgStride; SvBpp := TgBpp;
  SvOffX := TgOffX; SvOffY := TgOffY; SvBm := TgBm;
End;

Procedure TgRestore;
Begin
  TgKind := SvKind; TgW := SvW; TgH := SvH; TgBase := SvBase; TgStride := SvStride; TgBpp := SvBpp;
  TgOffX := SvOffX; TgOffY := SvOffY; TgBm := SvBm;
End;

{ couleur RVB du pel (X, Y) de la source }
Function SrcRgb(X, Y : LongInt) : LongInt;
Var V : LongInt;
Begin
  SrcRgb := -1;
  If (X < 0) Or (Y < 0) Or (X >= SrW) Or (Y >= SrH) Then Exit;
  If SrKind = 99 Then
  Begin
    V := RowPix(SrBase + Y * SrStride, SrBpp, X);
    If SrBpp <= 8 Then SrcRgb := HdrColor(SrPbmi, V) Else SrcRgb := V;
    Exit;
  End;
  TgSave;
  TgKind := SrKind; TgW := SrW; TgH := SrH; TgBase := SrBase; TgStride := SrStride; TgBpp := SrBpp; TgBm := SrBm;
  V := TgGet(X + SrOffX, Y + SrOffY);
  SrcRgb := DevRgb(V);
  TgRestore;
End;

{ resultat d'une operation ROP3 sur des valeurs (bits) }
Function Rop3(R, P, S, D, Msk : LongInt) : LongInt;
Var Res, C, T : LongInt;
Begin
  Res := 0;
  For C := 0 To 7 Do
    If ((R Shr C) And 1) <> 0 Then
    Begin
      If (C And 4) <> 0 Then T := P Else T := Not P;
      If (C And 2) <> 0 Then T := T And S Else T := T And Not S;
      If (C And 1) <> 0 Then T := T And D Else T := T And Not D;
      Res := Res Or T;
    End;
  Rop3 := Res And Msk;
End;

{ transfert vers l'espace K : cible (X1, Y1)-(X2, Y2) du peripherique,
  source (Sx1, Sy1)-(Sx2, Sy2) ; HasSrc : la source existe ; MonoBg :
  couleur RVB du fond de la source pour une cible monochrome }
Procedure BltDo(K, X1, Y1, X2, Y2, Sx1, Sy1, Sx2, Sy2, Rop : LongInt; HasSrc : Boolean; SrcBack : LongInt);
Var X, Y, Sx, Sy, Rgb, S, D, P, Msk, Fg, Bg, Ifg, Ibg, Tw, Th, Sw, Sh, Row, Px, Py : LongInt; On, UsesD : Boolean;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  Msk := DevMask;
  PatPrepare(K);
  Fg := ClrDev(K, Gps[K].AColor, False); Bg := ClrDev(K, Gps[K].ABack, True);
  Ifg := ClrDev(K, Gps[K].IColor, False); Ibg := ClrDev(K, Gps[K].IBack, True);
  Tw := X2 - X1; Th := Y2 - Y1; Sw := Sx2 - Sx1; Sh := Sy2 - Sy1;
  If Sw <= 0 Then Sw := Tw;
  If Sh <= 0 Then Sh := Th;
  UsesD := ((Rop Shr 1) And $55) <> (Rop And $55);
  For Y := Y1 To Y2 - 1 Do
  Begin
    Py := Y + TgOffY;
    For X := X1 To X2 - 1 Do
    Begin
      Px := X + TgOffX;
      If InClip(Px, Py) Then
      Begin
        If RMode = 2 Then
        Begin
          If (X >= HitX1) And (X < HitX2) And (Y >= HitY1) And (Y < HitY2) Then Hit := 1;
        End
        Else
        Begin
          S := 0;
          If HasSrc Then
          Begin
            Sx := Sx1 + MulDiv(X - X1, Sw, Tw); Sy := Sy1 + MulDiv(Y - Y1, Sh, Th);
            Rgb := SrcRgb(Sx, Sy);
            If (SrBpp = 1) And (DevMask <> 1) And (SrKind <> 99) Then
            Begin
              { source monochrome : 1 -> couleur de premier plan, 0 -> fond }
              If Rgb <> 0 Then S := Ifg Else S := Ibg;
            End
            Else If Msk = 1 Then
            Begin
              { cible monochrome : le fond de la source donne 0 }
              If Rgb = SrcBack Then S := 0 Else S := 1;
            End
            Else If Rgb >= 0 Then S := DevVal(Rgb);
          End;
          P := Fg;
          If PatOn <> 0 Then
          Begin
            Row := (Y - PatRy) And 7;
            On := (PatOn = 1) And (((PatBuf[7 - Row] Shr (7 - ((X - PatRx) And 7))) And 1) <> 0);
            If Not On Then P := Bg;
          End;
          D := 0;
          If UsesD Then D := TgGet(Px, Py);
          TgPut(Px, Py, Rop3(Rop, P, S, D, Msk));
          BndAdd(X, Y);
        End;
      End;
    End;
  End;
End;

{ cible d'un transfert : rectangle du monde -> peripherique }
Procedure BltTarget(K, P : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Var A, B, C, D : LongInt;
Begin
  CompSet(K);
  XF(K, RdL(P), RdL(P + 4), A, B); XF(K, RdL(P + 8), RdL(P + 12), C, D);
  X1 := MinI(A, C); X2 := MaxI(A, C); Y1 := MinI(B, D); Y2 := MaxI(B, D);
End;

{ GpiBitBlt(hpsTarget, hpsSource, lCount, aptlPoints, lRop, flOptions) :
  cible en coordonnees du monde (bord droit et haut exclus), source en
  pels du peripherique ; 4 points : etirement }
Function GpiBitBlt(HT, HS, N, P, Rop, Fl : LongInt) : LongInt;
Var KT, KS, X1, Y1, X2, Y2, Sx1, Sy1, Sx2, Sy2, Back : LongInt; HasSrc : Boolean;
Begin
  GpiBitBlt := 0;
  KT := PsK(HT);
  If (KT < 0) Or (P = 0) Or (N < 2) Then Exit;
  HasSrc := N >= 3;
  Back := 0;
  If HasSrc Then
  Begin
    KS := PsK(HS);
    If KS < 0 Then Exit;
    If Not BeginDraw(KS) Then
    Begin
      GpiBitBlt := 1;
      Exit;
    End;
    SrKind := TgKind; SrW := TgW; SrH := TgH; SrBase := TgBase; SrStride := TgStride; SrBpp := TgBpp;
    SrOffX := TgOffX; SrOffY := TgOffY; SrBm := TgBm;
    Back := ClrRgb(KS, Gps[KS].IBack, True);
    Sx1 := RdL(P + 16); Sy1 := RdL(P + 20);
    If N >= 4 Then
    Begin
      Sx2 := RdL(P + 24); Sy2 := RdL(P + 28);
    End
    Else
    Begin
      Sx2 := 0; Sy2 := 0;
    End;
  End;
  If Not BeginDraw(KT) Then
  Begin
    GpiBitBlt := 1;
    Exit;
  End;
  BltTarget(KT, P, X1, Y1, X2, Y2);
  If HasSrc And (N < 4) Then
  Begin
    Sx2 := Sx1 + X2 - X1; Sy2 := Sy1 + Y2 - Y1;
  End;
  BltDo(KT, X1, Y1, X2, Y2, Sx1, Sy1, Sx2, Sy2, Rop And 255, HasSrc, Back);
  GpiBitBlt := PrimRes;
End;

{ GpiWCBitBlt(hpsTarget, hbmSource, lCount, aptlPoints, lRop, flOptions) }
Function GpiWCBitBlt(HT, Hbm, N, P, Rop, Fl : LongInt) : LongInt;
Var KT, B, X1, Y1, X2, Y2, Sx1, Sy1, Sx2, Sy2 : LongInt;
Begin
  GpiWCBitBlt := 0;
  KT := PsK(HT);
  B := BmIdx(Hbm);
  If (KT < 0) Or (B < 0) Or (P = 0) Or (N < 3) Then Exit;
  SrKind := TG_BMP; SrW := BmCx[B]; SrH := BmCy[B]; SrBase := BmBits[B]; SrStride := BmStride[B]; SrBpp := BmBpp[B];
  SrOffX := 0; SrOffY := 0; SrBm := B;
  If Not BeginDraw(KT) Then
  Begin
    GpiWCBitBlt := 1;
    Exit;
  End;
  BltTarget(KT, P, X1, Y1, X2, Y2);
  Sx1 := RdL(P + 16); Sy1 := RdL(P + 20);
  If N >= 4 Then
  Begin
    Sx2 := RdL(P + 24); Sy2 := RdL(P + 28);
  End
  Else
  Begin
    Sx2 := Sx1 + X2 - X1; Sy2 := Sy1 + Y2 - Y1;
  End;
  BltDo(KT, X1, Y1, X2, Y2, Sx1, Sy1, Sx2, Sy2, Rop And 255, True, $FFFFFF);
  GpiWCBitBlt := PrimRes;
End;

{ GpiDrawBits(hps, pBits, pbmiInfoTable, lCount, aptlPoints, lRop,
  flOptions) : source = pels d'une application }
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt;
Var K, Cx, Cy, Bpp, X1, Y1, X2, Y2, Sx1, Sy1, Sx2, Sy2 : LongInt;
Begin
  GpiDrawBits := 0;
  K := PsK(Hps);
  If (K < 0) Or (PBits = 0) Or (Pbmi = 0) Or (P = 0) Or (N < 3) Then Exit;
  HdrRead(Pbmi, Cx, Cy, Bpp);
  SrKind := 99; SrW := Cx; SrH := Cy; SrBase := PBits; SrStride := ((Cx * Bpp + 31) Div 32) * 4; SrBpp := Bpp;
  SrPbmi := Pbmi; SrOffX := 0; SrOffY := 0;
  If Not BeginDraw(K) Then
  Begin
    GpiDrawBits := 1;
    Exit;
  End;
  BltTarget(K, P, X1, Y1, X2, Y2);
  Sx1 := RdL(P + 16); Sy1 := RdL(P + 20);
  If N >= 4 Then
  Begin
    Sx2 := RdL(P + 24); Sy2 := RdL(P + 28);
  End
  Else
  Begin
    Sx2 := Sx1 + X2 - X1; Sy2 := Sy1 + Y2 - Y1;
  End;
  BltDo(K, X1, Y1, X2, Y2, Sx1, Sy1, Sx2, Sy2, Rop And 255, True, $FFFFFF);
  GpiDrawBits := PrimRes;
End;

{ ==================================================================== }
{ Regions et decoupage                                                  }
{ ==================================================================== }
Function GpiCreateRegion(Hps, N, P : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  GpiCreateRegion := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  R := NewRgn;
  If R < 0 Then
  Begin
    SetErr(PMERR_INSUFFICIENT_MEMORY);
    Exit;
  End;
  If (N > 0) And (P <> 0) Then RgFromRects(K, R, N, P);
  GpiCreateRegion := $47520001 + R;
End;

Function GpiSetRegion(Hps, H, N, P : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  GpiSetRegion := 0;
  K := PsK(Hps);
  R := RgIdx(H);
  If (K < 0) Or (R < 0) Then
  Begin
    SetErr(PMERR_INV_HRGN);
    Exit;
  End;
  RgFromRects(K, R, N, P);
  GpiSetRegion := 1;
End;

Function GpiDestroyRegion(Hps, H : LongInt) : LongInt;
Var R, K : LongInt;
Begin
  GpiDestroyRegion := 0;
  R := RgIdx(H);
  If R < 0 Then
  Begin
    SetErr(PMERR_INV_HRGN);
    Exit;
  End;
  For K := 0 To MaxGPS - 1 Do
    If (GpsUse[K] <> 0) And (Gps[K].X[gxClipRgn] = R) Then
    Begin
      SetErr(PMERR_INV_HRGN);
      Exit;
    End;
  MemFree(RgData[R]);
  RgUse[R] := 0;
  GpiDestroyRegion := 1;
End;

{ GpiCombineRegion(hps, hrgnDest, hrgnSrc1, hrgnSrc2, lMode) : CRGN_OR
  1, COPY 2, XOR 4, AND 6, DIFF 7 ; RGN_NULL 1, RECT 2, COMPLEX 3 }
Function GpiCombineRegion(Hps, HD, H1, H2, Mode : LongInt) : LongInt;
Var D, A, B : LongInt;
Begin
  GpiCombineRegion := 0;
  D := RgIdx(HD); A := RgIdx(H1);
  If Mode = 2 Then B := -1 Else B := RgIdx(H2);
  If (D < 0) Or (A < 0) Or ((Mode <> 2) And (B < 0)) Then
  Begin
    SetErr(PMERR_INV_HRGN);
    Exit;
  End;
  GpiCombineRegion := RgCombine(D, A, B, Mode);
End;

{ GpiEqualRegion(hps, hrgnSrc1, hrgnSrc2) : EQRGN_NOTEQUAL 1, EQUAL 2 }
Function GpiEqualRegion(Hps, H1, H2 : LongInt) : LongInt;
Var A, B, T, R : LongInt;
Begin
  GpiEqualRegion := 0;
  A := RgIdx(H1); B := RgIdx(H2);
  If (A < 0) Or (B < 0) Then Exit;
  T := NewRgn;
  If T < 0 Then Exit;
  R := RgCombine(T, A, B, 4);
  If R = 1 Then GpiEqualRegion := 2 Else GpiEqualRegion := 1;
  MemFree(RgData[T]);
  RgUse[T] := 0;
End;

Function GpiOffsetRegion(Hps, H, P : LongInt) : LongInt;
Var R, I, A : LongInt;
Begin
  GpiOffsetRegion := 0;
  R := RgIdx(H);
  If (R < 0) Or (P = 0) Then Exit;
  For I := 0 To RgN[R] - 1 Do
  Begin
    A := RgData[R] + I * 16;
    WrL(A, RdL(A) + RdL(P)); WrL(A + 8, RdL(A + 8) + RdL(P));
    WrL(A + 4, RdL(A + 4) + RdL(P + 4)); WrL(A + 12, RdL(A + 12) + RdL(P + 4));
  End;
  GpiOffsetRegion := 1;
End;

{ GpiPtInRegion(hps, hrgn, pptlPoint) : PRGN_OUTSIDE 1, INSIDE 2 }
Function GpiPtInRegion(Hps, H, P : LongInt) : LongInt;
Var K, R, X, Y : LongInt;
Begin
  GpiPtInRegion := 0;
  K := PsK(Hps); R := RgIdx(H);
  If (K < 0) Or (R < 0) Or (P = 0) Then Exit;
  CompSet(K);
  XF(K, RdL(P), RdL(P + 4), X, Y);
  If RgHas(R, X, Y) Then GpiPtInRegion := 2 Else GpiPtInRegion := 1;
End;

{ GpiRectInRegion(hps, hrgn, prclRect) : RRGN_OUTSIDE 1, PARTIAL 2,
  INSIDE 3 }
Function GpiRectInRegion(Hps, H, P : LongInt) : LongInt;
Var K, R, T, X1, Y1, X2, Y2, A, B, C, D, Ar, I, S : LongInt;
Begin
  GpiRectInRegion := 0;
  K := PsK(Hps); R := RgIdx(H);
  If (K < 0) Or (R < 0) Or (P = 0) Then Exit;
  CompSet(K);
  XF(K, RdL(P), RdL(P + 4), A, B); XF(K, RdL(P + 8), RdL(P + 12), C, D);
  X1 := MinI(A, C); X2 := MaxI(A, C); Y1 := MinI(B, D); Y2 := MaxI(B, D);
  Ar := 0;
  For I := 0 To RgN[R] - 1 Do
  Begin
    S := RgData[R] + I * 16;
    A := MaxI(0, MinI(X2, RdL(S + 8)) - MaxI(X1, RdL(S)));
    B := MaxI(0, MinI(Y2, RdL(S + 12)) - MaxI(Y1, RdL(S + 4)));
    Ar := Ar + A * B;
  End;
  T := 1;
  If Ar > 0 Then T := 2;
  If Ar >= (X2 - X1) * (Y2 - Y1) Then T := 3;
  GpiRectInRegion := T;
End;

{ GpiQueryRegionBox(hps, hrgn, prclBound) : complexite }
Function GpiQueryRegionBox(Hps, H, P : LongInt) : LongInt;
Var R, X1, Y1, X2, Y2 : LongInt;
Begin
  GpiQueryRegionBox := 0;
  R := RgIdx(H);
  If (R < 0) Or (P = 0) Then Exit;
  Dummy := LongInt(RgBox(R, X1, Y1, X2, Y2));
  WrL(P, X1); WrL(P + 4, Y1); WrL(P + 8, X2); WrL(P + 12, Y2);
  If RgN[R] = 0 Then GpiQueryRegionBox := 1
  Else If RgN[R] = 1 Then GpiQueryRegionBox := 2
  Else GpiQueryRegionBox := 3;
End;

{ GpiQueryRegionRects(hps, hrgn, prclBound, prgnrcControl, prclRect) :
  RGNRECT (ircStart, crc, crcReturned, ulDirection) }
Function GpiQueryRegionRects(Hps, H, PB, PC, PR : LongInt) : LongInt;
Var R, I, St, N, C : LongInt;
Begin
  GpiQueryRegionRects := 0;
  R := RgIdx(H);
  If (R < 0) Or (PC = 0) Then Exit;
  St := MaxI(RdL(PC), 1); N := RdL(PC + 4);
  C := 0;
  For I := St - 1 To RgN[R] - 1 Do
    If (C < N) And (PR <> 0) Then
    Begin
      MemMove(RgData[R] + I * 16, PR + C * 16, 16);
      Inc(C);
    End;
  WrL(PC + 8, C);
  GpiQueryRegionRects := 1;
End;

Function GpiSetRegionOwner(Hps, H, Owner : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := RgIdx(H);
  If R < 0 Then GpiSetRegionOwner := 0
  Else
  Begin
    RgPid[R] := Owner;
    GpiSetRegionOwner := 1;
  End;
End;

{ peindre une region avec les attributs de zone }
Function GpiPaintRegion(Hps, H : LongInt) : LongInt;
Var K, R, I, S, Y, Fg, Bg, Mx, BMx : LongInt;
Begin
  GpiPaintRegion := 0;
  K := PsK(Hps); R := RgIdx(H);
  If (K < 0) Or (R < 0) Then Exit;
  If BeginDraw(K) Then
  Begin
    PatPrepare(K);
    Fg := ClrDev(K, Gps[K].AColor, False); Bg := ClrDev(K, Gps[K].ABack, True);
    Mx := Gps[K].AMix;
    If Mx = 0 Then Mx := FM_OVERPAINT;
    BMx := Gps[K].ABMix;
    If BMx = 0 Then BMx := FM_LEAVEALONE;
    For I := 0 To RgN[R] - 1 Do
    Begin
      S := RgData[R] + I * 16;
      For Y := RdL(S + 4) To RdL(S + 12) - 1 Do DSpan(RdL(S), RdL(S + 8), Y, Fg, Bg, Mx, BMx);
    End;
  End;
  GpiPaintRegion := PrimRes;
End;

{ GpiFrameRegion(hps, hrgn, psizlThickness) : cadre de chaque rectangle }
Function GpiFrameRegion(Hps, H, PT : LongInt) : LongInt;
Var K, R, I, S, Y, Fg, Tx, Ty, X1, Y1, X2, Y2 : LongInt;
Begin
  GpiFrameRegion := 0;
  K := PsK(Hps); R := RgIdx(H);
  If (K < 0) Or (R < 0) Then Exit;
  Tx := 1; Ty := 1;
  If PT <> 0 Then
  Begin
    Tx := MaxI(1, RdL(PT)); Ty := MaxI(1, RdL(PT + 4));
  End;
  If BeginDraw(K) Then
  Begin
    Fg := ClrDev(K, Gps[K].AColor, False);
    PatOn := 0;
    For I := 0 To RgN[R] - 1 Do
    Begin
      S := RgData[R] + I * 16;
      X1 := RdL(S); Y1 := RdL(S + 4); X2 := RdL(S + 8); Y2 := RdL(S + 12);
      For Y := Y1 To Y2 - 1 Do
        If (Y < Y1 + Ty) Or (Y >= Y2 - Ty) Then DSpan(X1, X2, Y, Fg, 0, FM_OVERPAINT, FM_LEAVEALONE)
        Else
        Begin
          DSpan(X1, MinI(X1 + Tx, X2), Y, Fg, 0, FM_OVERPAINT, FM_LEAVEALONE);
          DSpan(MaxI(X2 - Tx, X1), X2, Y, Fg, 0, FM_OVERPAINT, FM_LEAVEALONE);
        End;
    End;
  End;
  GpiFrameRegion := PrimRes;
End;

{ GpiSetClipRegion(hps, hrgn, phrgnOld) : complexite (la region
  appartient alors a l'espace) }
Function GpiSetClipRegion(Hps, H, POld : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  GpiSetClipRegion := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  R := -1;
  If H <> 0 Then
  Begin
    R := RgIdx(H);
    If R < 0 Then
    Begin
      SetErr(PMERR_INV_HRGN);
      Exit;
    End;
  End;
  If POld <> 0 Then
  Begin
    If Gps[K].X[gxClipRgn] >= 0 Then WrL(POld, $47520001 + Gps[K].X[gxClipRgn]) Else WrL(POld, 0);
  End;
  Gps[K].X[gxClipRgn] := R;
  If R < 0 Then GpiSetClipRegion := 1
  Else If RgN[R] = 0 Then GpiSetClipRegion := 1
  Else If RgN[R] = 1 Then GpiSetClipRegion := 2
  Else GpiSetClipRegion := 3;
End;

Function GpiQueryClipRegion(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (Gps[K].X[gxClipRgn] < 0) Then GpiQueryClipRegion := 0
  Else GpiQueryClipRegion := $47520001 + Gps[K].X[gxClipRgn];
End;

{ region de decoupage de l'espace (creee si absente : tout le
  peripherique) }
Function ClipOf(K : LongInt) : LongInt;
Var R, W, H : LongInt;
Begin
  If Gps[K].X[gxClipRgn] < 0 Then
  Begin
    R := NewRgn;
    If R >= 0 Then
    Begin
      DcSize(Gps[K].Dc, W, H);
      RgAdd(R, -32768, -32768, 32767, 32767);
      Gps[K].X[gxClipRgn] := R;
    End;
  End;
  ClipOf := Gps[K].X[gxClipRgn];
End;

{ GpiQueryClipBox(hps, prclBound) : boite (coordonnees du monde) }
Function GpiQueryClipBox(Hps, P : LongInt) : LongInt;
Var K, I, X1, Y1, X2, Y2 : LongInt; M : Array[0..8] Of LongInt;
Begin
  GpiQueryClipBox := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  If Not BeginDraw(K) Then
  Begin
    MemZero(P, 16);
    GpiQueryClipBox := 1;
    Exit;
  End;
  X1 := ClipX1[0]; Y1 := ClipY1[0]; X2 := ClipX2[0]; Y2 := ClipY2[0];
  For I := 1 To ClipN - 1 Do
  Begin
    X1 := MinI(X1, ClipX1[I]); Y1 := MinI(Y1, ClipY1[I]); X2 := MaxI(X2, ClipX2[I]); Y2 := MaxI(Y2, ClipY2[I]);
  End;
  X1 := X1 - TgOffX; X2 := X2 - TgOffX; Y1 := Y1 - TgOffY; Y2 := Y2 - TgOffY;
  Convert(K, 5, 1, X1, Y1, X1, Y1);
  Convert(K, 5, 1, X2 - 1, Y2 - 1, X2, Y2);
  WrL(P, X1); WrL(P + 4, Y1); WrL(P + 8, X2); WrL(P + 12, Y2);
  If ClipN = 1 Then GpiQueryClipBox := 2 Else GpiQueryClipBox := 3;
  M[0] := 0;
End;

{ GpiIntersectClipRectangle / GpiExcludeClipRectangle (hps, prcl) }
Function ClipOp(Hps, P, Op : LongInt) : LongInt;
Var K, R, T : LongInt;
Begin
  ClipOp := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  R := ClipOf(K);
  T := NewRgn;
  If (R < 0) Or (T < 0) Then Exit;
  RgFromRects(K, T, 1, P);
  ClipOp := RgCombine(R, R, T, Op);
  MemFree(RgData[T]);
  RgUse[T] := 0;
End;

Function GpiIntersectClipRectangle(Hps, P : LongInt) : LongInt;
Begin
  GpiIntersectClipRectangle := ClipOp(Hps, P, 6);
End;

Function GpiExcludeClipRectangle(Hps, P : LongInt) : LongInt;
Begin
  GpiExcludeClipRectangle := ClipOp(Hps, P, 7);
End;

Function GpiOffsetClipRegion(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiOffsetClipRegion := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Or (Gps[K].X[gxClipRgn] < 0) Then Exit;
  If GpiOffsetRegion(Hps, $47520001 + Gps[K].X[gxClipRgn], P) <> 0 Then GpiOffsetClipRegion := 2;
End;

{ ==================================================================== }
{ Tables de couleurs et palettes                                        }
{ ==================================================================== }
{ GpiCreateLogColorTable(hps, flOptions, lFormat, lStart, lCount,
  alTable) : LCOL_RESET 1 ; LCOLF_DEFAULT 0, INDRGB 1, CONSECRGB 2,
  RGB 3, PALETTE 4 }
Function GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P : LongInt) : LongInt;
Var K, I, Ix : LongInt;
Begin
  GpiCreateLogColorTable := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If (Opt And 1) <> 0 Then
  Begin
    Gps[K].X[gxLogN] := DefTabInit(Gps[K].X[gxLogTab]);
    Gps[K].X[gxLogMode] := 0;
  End;
  Case Fmt Of
    0 :
      Begin
        Gps[K].X[gxLogN] := DefTabInit(Gps[K].X[gxLogTab]);
        Gps[K].X[gxLogMode] := 0;
      End;
    1 :
      Begin
        I := 0;
        While I + 1 < N Do
        Begin
          Ix := RdL(P + I * 4);
          If (Ix >= 0) And (Ix < 256) Then
          Begin
            WrL(Gps[K].X[gxLogTab] + Ix * 4, RdL(P + I * 4 + 4) And $FFFFFF);
            Gps[K].X[gxLogN] := MaxI(Gps[K].X[gxLogN], Ix + 1);
          End;
          I := I + 2;
        End;
        Gps[K].X[gxLogMode] := 1;
      End;
    2 :
      Begin
        For I := 0 To N - 1 Do
          If (St + I >= 0) And (St + I < 256) Then
          Begin
            WrL(Gps[K].X[gxLogTab] + (St + I) * 4, RdL(P + I * 4) And $FFFFFF);
            Gps[K].X[gxLogN] := MaxI(Gps[K].X[gxLogN], St + I + 1);
          End;
        Gps[K].X[gxLogMode] := 1;
      End;
    3 : Gps[K].X[gxLogMode] := 3;
    4 : Gps[K].X[gxLogMode] := 4;
  Else
    Begin
      SetErr(PMERR_INV_PARAMETER);
      Exit;
    End;
  End;
  GpiCreateLogColorTable := 1;
End;

Function GpiRealizeColorTable(Hps : LongInt) : LongInt;
Begin
  If PsK(Hps) < 0 Then GpiRealizeColorTable := 0 Else GpiRealizeColorTable := 1;
End;

Function GpiUnrealizeColorTable(Hps : LongInt) : LongInt;
Begin
  If PsK(Hps) < 0 Then GpiUnrealizeColorTable := 0 Else GpiUnrealizeColorTable := 1;
End;

{ GpiQueryColorData(hps, lCount, alArray) : format, index min et max,
  taille de la table du peripherique }
Function GpiQueryColorData(Hps, N, P : LongInt) : LongInt;
Var K, V : Array[0..3] Of LongInt; I, Ks, Nt : LongInt;
Begin
  GpiQueryColorData := 0;
  Ks := PsK(Hps);
  If (Ks < 0) Or (P = 0) Then Exit;
  V[0] := Gps[Ks].X[gxLogMode];
  If V[0] = 1 Then V[0] := 1;
  V[1] := 0; V[2] := Gps[Ks].X[gxLogN] - 1;
  If BeginDraw(Ks) Then Dummy := TgTab(Nt) Else Nt := 16;
  V[3] := Nt;
  For I := 0 To MinI(N, 4) - 1 Do WrL(P + I * 4, V[I]);
  K[0] := 0;
  GpiQueryColorData := 1;
End;

{ GpiQueryLogColorTable(hps, flOptions, lStart, lCount, alArray) :
  nombre rendu (QLCT_RGB -2 en mode RVB) }
Function GpiQueryLogColorTable(Hps, Opt, St, N, P : LongInt) : LongInt;
Var K, I, C : LongInt;
Begin
  GpiQueryLogColorTable := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Gps[K].X[gxLogMode] = 3 Then
  Begin
    GpiQueryLogColorTable := -2;
    Exit;
  End;
  C := 0;
  For I := St To MinI(St + N, Gps[K].X[gxLogN]) - 1 Do
    If P <> 0 Then
    Begin
      If (Opt And 1) <> 0 Then
      Begin
        WrL(P + C * 4, I); WrL(P + C * 4 + 4, RdL(Gps[K].X[gxLogTab] + I * 4));
        C := C + 2;
      End
      Else
      Begin
        WrL(P + C * 4, RdL(Gps[K].X[gxLogTab] + I * 4));
        Inc(C);
      End;
    End;
  GpiQueryLogColorTable := C;
End;

{ GpiQueryRealColors(hps, flOptions, lStart, lCount, alColors) }
Function GpiQueryRealColors(Hps, Opt, St, N, P : LongInt) : LongInt;
Var K, I, T, Nt, C : LongInt;
Begin
  GpiQueryRealColors := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  If BeginDraw(K) Then T := TgTab(Nt)
  Else
  Begin
    T := LongInt(@Vga16); Nt := 16;
  End;
  If Nt = 0 Then Nt := 256;
  C := 0;
  For I := St To MinI(St + N, Nt) - 1 Do
  Begin
    If Nt = 256 Then WrL(P + C * 4, RdL(T + I * 4) And $FFFFFF) Else WrL(P + C * 4, RdL(T + I * 4));
    Inc(C);
  End;
  GpiQueryRealColors := C;
End;

Function GpiQueryNearestColor(Hps, Opt, Rgb : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryNearestColor := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Not BeginDraw(K) Then
  Begin
    TgKind := TG_PLANAR; TgBpp := 4;
  End;
  GpiQueryNearestColor := DevRgb(DevVal(Rgb));
End;

{ GpiQueryColorIndex(hps, flOptions, lRgbColor) : index logique }
Function GpiQueryColorIndex(Hps, Opt, Rgb : LongInt) : LongInt;
Var K, I, B, D, Bd : LongInt;
Begin
  GpiQueryColorIndex := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Gps[K].X[gxLogMode] = 3 Then
  Begin
    GpiQueryColorIndex := Rgb And $FFFFFF;
    Exit;
  End;
  B := 0; Bd := $7FFFFFFF;
  For I := 0 To Gps[K].X[gxLogN] - 1 Do
  Begin
    D := RgbDist(RdL(Gps[K].X[gxLogTab] + I * 4), Rgb);
    If D < Bd Then
    Begin
      Bd := D; B := I;
    End;
  End;
  GpiQueryColorIndex := B;
End;

{ GpiQueryRGBColor(hps, flOptions, lColor) }
Function GpiQueryRGBColor(Hps, Opt, C : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryRGBColor := -1 Else GpiQueryRGBColor := ClrRgb(K, C, False);
End;

{ --- palettes (HPAL 474Cxxxxh) --- }
Function PlIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $474C0001;
  If (I < 0) Or (I >= MaxPal) Then I := -1
  Else If PlUse[I] = 0 Then I := -1;
  If I < 0 Then SetErr(PMERR_INV_HPAL);
  PlIdx := I;
End;

{ GpiCreatePalette(hab, flOptions, ulFormat, ulCount, aulTable) }
Function GpiCreatePalette(Hab, Opt, Fmt, N, P : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  GpiCreatePalette := 0;
  F := -1;
  For I := MaxPal - 1 DownTo 0 Do
    If (PlUse[I] = 0) Or Not Alive(PlPid[I]) Then F := I;
  If (F < 0) Or (N <= 0) Or (N > 256) Then
  Begin
    SetErr(PMERR_INV_PARAMETER);
    Exit;
  End;
  If PlUse[F] <> 0 Then MemFree(PlData[F]);
  PlData[F] := MemAlloc(1024);
  If PlData[F] = 0 Then Exit;
  For I := 0 To N - 1 Do
    If P <> 0 Then WrL(PlData[F] + I * 4, RdL(P + I * 4) And $FFFFFF);
  PlUse[F] := 1; PlPid[F] := MyPid; PlN[F] := N;
  GpiCreatePalette := $474C0001 + F;
End;

Function GpiDeletePalette(H : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  GpiDeletePalette := 0;
  I := PlIdx(H);
  If I < 0 Then Exit;
  For K := 0 To MaxGPS - 1 Do
    If (GpsUse[K] <> 0) And (Gps[K].X[gxPal] = I + 1) Then Gps[K].X[gxPal] := 0;
  MemFree(PlData[I]);
  PlUse[I] := 0;
  GpiDeletePalette := 1;
End;

{ GpiSelectPalette(hps, hpal) : ancienne palette }
Function GpiSelectPalette(Hps, H : LongInt) : LongInt;
Var K, I : LongInt;
Begin
  GpiSelectPalette := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Gps[K].X[gxPal] > 0 Then GpiSelectPalette := $474C0000 + Gps[K].X[gxPal] Else GpiSelectPalette := 0;
  If H = 0 Then
  Begin
    Gps[K].X[gxPal] := 0;
    If Gps[K].X[gxLogMode] = 4 Then Gps[K].X[gxLogMode] := 0;
  End
  Else
  Begin
    I := PlIdx(H);
    If I < 0 Then Exit;
    Gps[K].X[gxPal] := I + 1;
    Gps[K].X[gxLogMode] := 4;
  End;
End;

Function GpiQueryPalette(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (Gps[K].X[gxPal] = 0) Then GpiQueryPalette := 0 Else GpiQueryPalette := $474C0000 + Gps[K].X[gxPal];
End;

Function GpiSetPaletteEntries(H, Fmt, St, N, P : LongInt) : LongInt;
Var I, J : LongInt;
Begin
  GpiSetPaletteEntries := 0;
  I := PlIdx(H);
  If (I < 0) Or (P = 0) Then Exit;
  For J := 0 To N - 1 Do
    If (St + J >= 0) And (St + J < 256) Then
    Begin
      WrL(PlData[I] + (St + J) * 4, RdL(P + J * 4) And $FFFFFF);
      PlN[I] := MaxI(PlN[I], St + J + 1);
    End;
  GpiSetPaletteEntries := 1;
End;

Function GpiAnimatePalette(H, Fmt, St, N, P : LongInt) : LongInt;
Begin
  If GpiSetPaletteEntries(H, Fmt, St, N, P) <> 0 Then GpiAnimatePalette := N Else GpiAnimatePalette := -1;
End;

{ GpiQueryPaletteInfo(hpal, hps, flOptions, ulStart, ulCount, aulArray) }
Function GpiQueryPaletteInfo(H, Hps, Opt, St, N, P : LongInt) : LongInt;
Var I, J, C : LongInt;
Begin
  GpiQueryPaletteInfo := -1;
  I := PlIdx(H);
  If I < 0 Then Exit;
  If (N = 0) Or (P = 0) Then
  Begin
    GpiQueryPaletteInfo := PlN[I];
    Exit;
  End;
  C := 0;
  For J := St To MinI(St + N, PlN[I]) - 1 Do
  Begin
    WrL(P + C * 4, RdL(PlData[I] + J * 4));
    Inc(C);
  End;
  GpiQueryPaletteInfo := C;
End;

{ ==================================================================== }
{ Polices : une police du systeme (System VIO, System Monospaced), 8 x 16 }
{ identificateurs locaux : lcid (4), type (4 : 1 police, 2 bitmap),     }
{ bitmap (4), nom de la police (32), correspondance (4)                 }
{ ==================================================================== }
Function LcidSlot(K, Id : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxLcid - 1 DownTo 0 Do
    If RdL(Gps[K].X[gxLcids] + I * 48) = Id Then R := I;
  LcidSlot := R;
End;

Function FaceOk(S : String) : Boolean;
Begin
  S := UpStr(S);
  FaceOk := (S = '') Or (S = 'SYSTEM VIO') Or (S = 'SYSTEM MONOSPACED') Or (S = 'SYSTEM PROPORTIONAL') Or
            (S = 'COURIER') Or (S = 'HELV') Or (S = 'TMS RMN');
End;

{ GpiCreateLogFont(hps, pName, lLcid, pfatAttrs) : FONT_DEFAULT 1,
  FONT_MATCH 2 ; FATTRS : usRecordLength, fsSelection, lMatch,
  szFacename[32] (8)... }
Function GpiCreateLogFont(Hps, PName, Id, PF : LongInt) : LongInt;
Var K, S, I : LongInt; F : String;
Begin
  GpiCreateLogFont := 0;
  K := PsK(Hps);
  If (K < 0) Or (Id < 1) Or (Id > 254) Then
  Begin
    SetErr(PMERR_INV_LOCAL_ID);
    Exit;
  End;
  S := LcidSlot(K, Id);
  If S < 0 Then S := LcidSlot(K, 0);
  If S < 0 Then
  Begin
    SetErr(PMERR_INSUFFICIENT_MEMORY);
    Exit;
  End;
  F := '';
  If PF <> 0 Then F := GetZ(PF + 8);
  WrL(Gps[K].X[gxLcids] + S * 48, Id); WrL(Gps[K].X[gxLcids] + S * 48 + 4, 1); WrL(Gps[K].X[gxLcids] + S * 48 + 8, 0);
  If F = '' Then F := 'System VIO';
  Dummy := PutZN(Gps[K].X[gxLcids] + S * 48 + 12, 32, F);
  If PName <> 0 Then
    For I := 0 To 7 Do WrB(Gps[K].X[gxLcids] + S * 48 + 44 + I Mod 4, RdB(PName + I Mod 4));
  If FaceOk(F) And (UpStr(F) <> 'COURIER') And (UpStr(F) <> 'HELV') And (UpStr(F) <> 'TMS RMN') Then
    GpiCreateLogFont := 2
  Else GpiCreateLogFont := 1;
End;

{ GpiSetBitmapId(hps, hbm, lLcid) : bitmap utilisable comme motif }
Function GpiSetBitmapId(Hps, Hbm, Id : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  GpiSetBitmapId := 0;
  K := PsK(Hps);
  If (K < 0) Or (BmIdx(Hbm) < 0) Or (Id < 1) Or (Id > 254) Then Exit;
  S := LcidSlot(K, Id);
  If S < 0 Then S := LcidSlot(K, 0);
  If S < 0 Then Exit;
  WrL(Gps[K].X[gxLcids] + S * 48, Id); WrL(Gps[K].X[gxLcids] + S * 48 + 4, 2); WrL(Gps[K].X[gxLcids] + S * 48 + 8, Hbm);
  GpiSetBitmapId := 1;
End;

Function GpiQueryBitmapHandle(Hps, Id : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  GpiQueryBitmapHandle := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := LcidSlot(K, Id);
  If (S >= 0) And (RdL(Gps[K].X[gxLcids] + S * 48 + 4) = 2) Then GpiQueryBitmapHandle := RdL(Gps[K].X[gxLcids] + S * 48 + 8);
End;

{ motif d'un bitmap identifie par un lcid (espace courant CurK) : 8 x 8 }
Function BmPatBits(Id : LongInt) : Boolean;
Var S, B, X, Y, V : LongInt;
Begin
  BmPatBits := False;
  If CurK < 0 Then Exit;
  S := LcidSlot(CurK, Id);
  If (S < 0) Or (RdL(Gps[CurK].X[gxLcids] + S * 48 + 4) <> 2) Then Exit;
  B := BmIdx(RdL(Gps[CurK].X[gxLcids] + S * 48 + 8));
  If B < 0 Then Exit;
  For Y := 0 To 7 Do
  Begin
    V := 0;
    For X := 0 To 7 Do
      If RowPix(BmBits[B] + (Y Mod BmCy[B]) * BmStride[B], BmBpp[B], X Mod BmCx[B]) <> 0 Then V := V Or ($80 Shr X);
    PatBuf[Y] := V;
  End;
  BmPatBits := True;
End;

Function GpiDeleteSetId(Hps, Id : LongInt) : LongInt;
Var K, S, I : LongInt;
Begin
  GpiDeleteSetId := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Id = -1 Then
  Begin
    For I := 0 To MaxLcid - 1 Do WrL(Gps[K].X[gxLcids] + I * 48, 0);
    GpiDeleteSetId := 1;
    Exit;
  End;
  S := LcidSlot(K, Id);
  If (S < 0) Or (Id = 0) Then
  Begin
    SetErr(PMERR_INV_LOCAL_ID);
    Exit;
  End;
  WrL(Gps[K].X[gxLcids] + S * 48, 0);
  If Gps[K].CSet = Id Then Gps[K].CSet := 0;
  GpiDeleteSetId := 1;
End;

Function GpiQueryNumberSetIds(Hps : LongInt) : LongInt;
Var K, I, N : LongInt;
Begin
  GpiQueryNumberSetIds := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  N := 0;
  For I := 0 To MaxLcid - 1 Do
    If RdL(Gps[K].X[gxLcids] + I * 48) <> 0 Then Inc(N);
  GpiQueryNumberSetIds := N;
End;

{ GpiQuerySetIds(hps, lCount, alTypes, aNames (STR8), allcids) :
  LCIDT_FONT 6, LCIDT_BITMAP 7 }
Function GpiQuerySetIds(Hps, N, PT, PN, PL : LongInt) : LongInt;
Var K, I, C : LongInt;
Begin
  GpiQuerySetIds := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  C := 0;
  For I := 0 To MaxLcid - 1 Do
    If (RdL(Gps[K].X[gxLcids] + I * 48) <> 0) And (C < N) Then
    Begin
      If PT <> 0 Then
      Begin
        If RdL(Gps[K].X[gxLcids] + I * 48 + 4) = 2 Then WrL(PT + C * 4, 7) Else WrL(PT + C * 4, 6);
      End;
      If PN <> 0 Then
      Begin
        MemMove(Gps[K].X[gxLcids] + I * 48 + 44, PN + C * 8, 4);
        MemZero(PN + C * 8 + 4, 4);
      End;
      If PL <> 0 Then WrL(PL + C * 4, RdL(Gps[K].X[gxLcids] + I * 48));
      Inc(C);
    End;
  GpiQuerySetIds := 1;
End;

{ FONTMETRICS de la police du systeme (208 octets) }
Procedure FillMetrics(P, Cb : LongInt; Face : String);
Var M : Array[0..51] Of LongInt; A : LongInt;
Begin
  MemZero(LongInt(@M), 208);
  A := LongInt(@M);
  Dummy := PutZN(A, 32, Face);
  Dummy := PutZN(A + 32, 32, Face);
  WrW(A + 64, 0); WrW(A + 66, 850);
  WrL(A + 68, 16); WrL(A + 72, 8); WrL(A + 76, 12); WrL(A + 80, 4); WrL(A + 84, 8); WrL(A + 88, 4);
  WrL(A + 92, 2); WrL(A + 96, 0); WrL(A + 100, 8); WrL(A + 104, 8); WrL(A + 108, 8); WrL(A + 112, 16);
  WrW(A + 116, 0); WrW(A + 118, 0); WrW(A + 120, 0); WrW(A + 122, 5); WrW(A + 124, 5);
  WrW(A + 126, 96); WrW(A + 128, 96); WrW(A + 130, 1); WrW(A + 132, 254); WrW(A + 134, 31); WrW(A + 136, 32);
  WrW(A + 138, 120); WrW(A + 140, 120); WrW(A + 142, 120);
  WrW(A + 144, 1);                    { FM_TYPE_FIXED }
  WrW(A + 146, 0); WrW(A + 148, 0); WrW(A + 150, 0);
  WrL(A + 184, 1); WrL(A + 188, 2); WrL(A + 192, 1); WrL(A + 196, 6);
  WrW(A + 200, 0); WrW(A + 202, 0); WrL(A + 204, 1);
  MemMove(A, P, MinI(Cb, 208));
End;

{ GpiQueryFonts(hps, flOptions, pszFacename, plReqFonts, lMetricsLength,
  afmMetrics) : polices restantes }
Function GpiQueryFonts(Hps, Opt, PFace, PReq, Len, P : LongInt) : LongInt;
Var Faces : Array[0..1] Of String[31]; N, I, Ret : LongInt; F : String;
Begin
  GpiQueryFonts := -1;
  If PsK(Hps) < 0 Then Exit;
  Faces[0] := 'System VIO'; Faces[1] := 'System Monospaced';
  F := '';
  If PFace <> 0 Then F := UpStr(GetZ(PFace));
  N := 0;
  For I := 0 To 1 Do
    If (F = '') Or (F = UpStr(Faces[I])) Then Inc(N);
  Ret := 0;
  If PReq <> 0 Then
  Begin
    Ret := 0;
    For I := 0 To 1 Do
      If ((F = '') Or (F = UpStr(Faces[I]))) And (Ret < RdL(PReq)) And (P <> 0) Then
      Begin
        FillMetrics(P + Ret * Len, Len, Faces[I]);
        Inc(Ret);
      End;
    WrL(PReq, Ret);
  End;
  GpiQueryFonts := N - Ret;
End;

Function GpiQueryFontMetrics(Hps, Len, P : LongInt) : LongInt;
Var K, S : LongInt; F : String;
Begin
  GpiQueryFontMetrics := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  F := 'System VIO';
  S := LcidSlot(K, Gps[K].CSet);
  If (Gps[K].CSet <> 0) And (S >= 0) Then F := GetZ(Gps[K].X[gxLcids] + S * 48 + 12);
  FillMetrics(P, Len, F);
  GpiQueryFontMetrics := 1;
End;

Function GpiQueryKerningPairs(Hps, N, P : LongInt) : LongInt;
Begin
  If PsK(Hps) < 0 Then GpiQueryKerningPairs := -1 Else GpiQueryKerningPairs := 0;
End;

{ GpiQueryWidthTable(hps, lFirstChar, lCount, alData) }
Function GpiQueryWidthTable(Hps, First, N, P : LongInt) : LongInt;
Var K, I : LongInt;
Begin
  GpiQueryWidthTable := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  For I := 0 To N - 1 Do WrL(P + I * 4, FRound(Gps[K].CBoxX + Gps[K].CExtra));
  GpiQueryWidthTable := 1;
End;

Function GpiQueryDefCharBox(Hps, P : LongInt) : LongInt;
Var K, Cx, Cy : LongInt;
Begin
  GpiQueryDefCharBox := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  DefCharBox(K, Cx, Cy);
  WrL(P, FRound(Cx)); WrL(P + 4, FRound(Cy));
  GpiQueryDefCharBox := 1;
End;

Function GpiSetCp(Hps, Cp : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiSetCp := 0
  Else
  Begin
    Gps[K].X[gxCp] := Cp;
    GpiSetCp := 1;
  End;
End;

Function GpiQueryCp(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryCp := 0 Else GpiQueryCp := Gps[K].X[gxCp];
End;

{ chargement de polices : seule la police du systeme existe ; les
  fichiers de polices (.FON) sont acceptes s'ils existent }
Function FontFileOk(P : LongInt) : Boolean;
Var H, A : LongInt;
Begin
  FontFileOk := False;
  If P = 0 Then Exit;
  H := 0; A := 0;
  If DcOpen(P, LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0) = 0 Then
  Begin
    Dummy := DcClose(H);
    FontFileOk := True;
  End;
End;

Function GpiLoadFonts(Hab, P : LongInt) : LongInt;
Begin
  If FontFileOk(P) Then GpiLoadFonts := 1
  Else
  Begin
    SetErr(PMERR_FONT_NOT_LOADED);
    GpiLoadFonts := 0;
  End;
End;

Function GpiUnloadFonts(Hab, P : LongInt) : LongInt;
Begin
  GpiUnloadFonts := 1;
End;

Function GpiLoadPublicFonts(Hab, P : LongInt) : LongInt;
Begin
  GpiLoadPublicFonts := GpiLoadFonts(Hab, P);
End;

Function GpiUnloadPublicFonts(Hab, P : LongInt) : LongInt;
Begin
  GpiUnloadPublicFonts := 1;
End;

Function GpiInstallIFIFont(Hab, PFile, PDir : LongInt) : LongInt;
Begin
  GpiInstallIFIFont := GpiLoadFonts(Hab, PFile);
End;

{ GpiQueryFontFileDescriptions(hab, pszFilename, plCount, affdescsNames) :
  FFDESCS2 (nom de famille, nom de police, 32 octets chacun) }
Function GpiQueryFontFileDescriptions(Hab, PF, PN, P : LongInt) : LongInt;
Begin
  GpiQueryFontFileDescriptions := -1;
  If Not FontFileOk(PF) Then
  Begin
    SetErr(PMERR_FONT_NOT_LOADED);
    Exit;
  End;
  If (PN <> 0) And (RdL(PN) >= 1) And (P <> 0) Then
  Begin
    Dummy := PutZN(P, 32, 'System VIO'); Dummy := PutZN(P + 32, 32, 'System VIO');
    WrL(PN, 1);
    GpiQueryFontFileDescriptions := 0;
  End
  Else GpiQueryFontFileDescriptions := 1;
End;

Function GpiQueryFullFontFileDescs(Hab, PF, PN, P, PLen : LongInt) : LongInt;
Begin
  GpiQueryFullFontFileDescs := GpiQueryFontFileDescriptions(Hab, PF, PN, P);
End;

{ GpiQueryLogicalFont(hps, lcid, pName (STR8), pfat, length) }
Function GpiQueryLogicalFont(Hps, Id, PName, PF, Len : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  GpiQueryLogicalFont := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := LcidSlot(K, Id);
  If (S < 0) Or (RdL(Gps[K].X[gxLcids] + S * 48 + 4) <> 1) Then Exit;
  If PName <> 0 Then
  Begin
    MemMove(Gps[K].X[gxLcids] + S * 48 + 44, PName, 4);
    MemZero(PName + 4, 4);
  End;
  If (PF <> 0) And (Len >= 40) Then
  Begin
    MemZero(PF, MinI(Len, 56));
    WrW(PF, MinI(Len, 56));
    Dummy := PutZN(PF + 8, 32, GetZ(Gps[K].X[gxLcids] + S * 48 + 12));
    If Len >= 44 Then WrW(PF + 42, Gps[K].X[gxCp]);
    If Len >= 52 Then
    Begin
      WrL(PF + 44, 16); WrL(PF + 48, 8);
    End;
  End;
  GpiQueryLogicalFont := 1;
End;

{ GpiQueryFaceString(hps, pszFamilyName, pfaceAttrs, length,
  pszCompoundFaceName) : longueur }
Function GpiQueryFaceString(Hps, PFam, PAt, Len, POut : LongInt) : LongInt;
Var S : String;
Begin
  S := GetZ(PFam);
  If S = '' Then S := 'System VIO';
  GpiQueryFaceString := PutZN(POut, Len, S);
End;

Function GpiQueryFontAction(Hab, Opt : LongInt) : LongInt;
Begin
  GpiQueryFontAction := 0;
End;

{ ==================================================================== }
{ Transformations                                                       }
{ ==================================================================== }
{ appliquer une matrice partielle (lCount elements) a une matrice :
  TRANSFORM_REPLACE 0, ADD 1, PREEMPT 2 }
Procedure ApplyMat(Dst, N, P, Opt : LongInt);
Var M : Array[0..8] Of LongInt; I : LongInt;
Begin
  MatIdent(LongInt(@M));
  For I := 0 To MinI(N, 9) - 1 Do M[I] := RdL(P + I * 4);
  If M[8] = 0 Then M[8] := 1;
  Case Opt Of
    1 : MatMul(Dst, LongInt(@M), Dst);
    2 : MatMul(LongInt(@M), Dst, Dst);
  Else
    MemMove(LongInt(@M), Dst, 36);
  End;
End;

Function SetMat(Hps, Which, N, P, Opt : LongInt) : LongInt;
Var K : LongInt;
Begin
  SetMat := 0;
  K := PsK(Hps);
  If (K < 0) Or ((N > 0) And (P = 0)) Or (N < 0) Or (N > 9) Then Exit;
  Case Which Of
    0 :
      Begin
        RecI(E_SETMODELXFORM); RecL(N); RecL(Opt);
        Dummy := LongInt(RecDone(K, P, N * 4));
        ApplyMat(LongInt(@Gps[K].Mdl), N, P, Opt);
      End;
    1 : ApplyMat(LongInt(@Gps[K].Vw), N, P, Opt);
    2 : ApplyMat(LongInt(@Gps[K].Dv), N, P, Opt);
  End;
  SetMat := 1;
End;

Function QueryMat(Hps, Which, N, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  QueryMat := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  Case Which Of
    0 : MemMove(LongInt(@Gps[K].Mdl), P, MinI(N, 9) * 4);
    1 : MemMove(LongInt(@Gps[K].Vw), P, MinI(N, 9) * 4);
    2 : MemMove(LongInt(@Gps[K].Dv), P, MinI(N, 9) * 4);
  End;
  QueryMat := 1;
End;

Function GpiSetModelTransformMatrix(Hps, N, P, Opt : LongInt) : LongInt;
Begin
  GpiSetModelTransformMatrix := SetMat(Hps, 0, N, P, Opt);
End;

Function GpiQueryModelTransformMatrix(Hps, N, P : LongInt) : LongInt;
Begin
  GpiQueryModelTransformMatrix := QueryMat(Hps, 0, N, P);
End;

Function GpiSetViewingTransformMatrix(Hps, N, P, Opt : LongInt) : LongInt;
Begin
  GpiSetViewingTransformMatrix := SetMat(Hps, 1, N, P, Opt);
End;

Function GpiQueryViewingTransformMatrix(Hps, N, P : LongInt) : LongInt;
Begin
  GpiQueryViewingTransformMatrix := QueryMat(Hps, 1, N, P);
End;

Function GpiSetDefaultViewMatrix(Hps, N, P, Opt : LongInt) : LongInt;
Begin
  GpiSetDefaultViewMatrix := SetMat(Hps, 2, N, P, Opt);
End;

Function GpiQueryDefaultViewMatrix(Hps, N, P : LongInt) : LongInt;
Begin
  GpiQueryDefaultViewMatrix := QueryMat(Hps, 2, N, P);
End;

{ GpiTranslate(hps, pmatlfArray, lOptions, pptlTranslation) }
Function GpiTranslate(Hps, PM, Opt, P : LongInt) : LongInt;
Var M : Array[0..8] Of LongInt;
Begin
  GpiTranslate := 0;
  If (PM = 0) Or (P = 0) Then Exit;
  MatIdent(LongInt(@M));
  M[6] := RdL(P); M[7] := RdL(P + 4);
  If Opt = 0 Then MemMove(LongInt(@M), PM, 36) Else ApplyMat(PM, 9, LongInt(@M), Opt);
  GpiTranslate := 1;
End;

{ GpiScale(hps, pmatlfArray, lOptions, afxScale, pptlCenter) }
Function GpiScale(Hps, PM, Opt, PS, PC : LongInt) : LongInt;
Var M : Array[0..8] Of LongInt; Cx, Cy : LongInt;
Begin
  GpiScale := 0;
  If (PM = 0) Or (PS = 0) Then Exit;
  Cx := 0; Cy := 0;
  If PC <> 0 Then
  Begin
    Cx := RdL(PC); Cy := RdL(PC + 4);
  End;
  MatIdent(LongInt(@M));
  M[0] := RdL(PS); M[4] := RdL(PS + 4);
  M[6] := Cx - FMul(Cx, M[0]); M[7] := Cy - FMul(Cy, M[4]);
  If Opt = 0 Then MemMove(LongInt(@M), PM, 36) Else ApplyMat(PM, 9, LongInt(@M), Opt);
  GpiScale := 1;
End;

{ GpiRotate(hps, pmatlfArray, lOptions, fxAngle, pptlCenter) : degres
  (16.16), sens trigonometrique }
Function GpiRotate(Hps, PM, Opt, Ang, PC : LongInt) : LongInt;
Var M : Array[0..8] Of LongInt; Cx, Cy, C, S, A : LongInt;
Begin
  GpiRotate := 0;
  If PM = 0 Then Exit;
  Cx := 0; Cy := 0;
  If PC <> 0 Then
  Begin
    Cx := RdL(PC); Cy := RdL(PC + 4);
  End;
  A := DegA(Ang);
  C := CosA(A); S := SinA(A);
  MatIdent(LongInt(@M));
  M[0] := C; M[1] := S; M[3] := -S; M[4] := C;
  M[6] := Cx - (FMulR(Cx, C) - FMulR(Cy, S)); M[7] := Cy - (FMulR(Cx, S) + FMulR(Cy, C));
  If Opt = 0 Then MemMove(LongInt(@M), PM, 36) Else ApplyMat(PM, 9, LongInt(@M), Opt);
  GpiRotate := 1;
End;

{ GpiConvert(hps, lSrc, lTarg, lCount, aptlPoints) : CVTC_WORLD 1, MODEL
  2, DEFAULTPAGE 3, PAGE 4, DEVICE 5 }
Function GpiConvert(Hps, Src, Dst, N, P : LongInt) : LongInt;
Var K, I, X, Y : LongInt;
Begin
  GpiConvert := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Or (Src < 1) Or (Src > 5) Or (Dst < 1) Or (Dst > 5) Then Exit;
  For I := 0 To N - 1 Do
  Begin
    Convert(K, Src, Dst, RdL(P + I * 8), RdL(P + I * 8 + 4), X, Y);
    WrL(P + I * 8, X); WrL(P + I * 8 + 4, Y);
  End;
  GpiConvert := 1;
End;

{ GpiConvertWithMatrix(hps, lCountp, aptlPoints, lCount, pmatlfArray) }
Function GpiConvertWithMatrix(Hps, N, P, NM, PM : LongInt) : LongInt;
Var M : Array[0..8] Of LongInt; I, X, Y : LongInt;
Begin
  GpiConvertWithMatrix := 0;
  If (P = 0) Or (PM = 0) Then Exit;
  MatIdent(LongInt(@M));
  For I := 0 To MinI(NM, 9) - 1 Do M[I] := RdL(PM + I * 4);
  For I := 0 To N - 1 Do
  Begin
    MatPt(LongInt(@M), RdL(P + I * 8), RdL(P + I * 8 + 4), X, Y);
    WrL(P + I * 8, X); WrL(P + I * 8 + 4, Y);
  End;
  GpiConvertWithMatrix := 1;
End;

Function GpiSetPageViewport(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetPageViewport := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  Gps[K].Vx1 := RdL(P); Gps[K].Vy1 := RdL(P + 4); Gps[K].Vx2 := RdL(P + 8); Gps[K].Vy2 := RdL(P + 12);
  If Gps[K].Vx2 = Gps[K].Vx1 Then Inc(Gps[K].Vx2);
  If Gps[K].Vy2 = Gps[K].Vy1 Then Inc(Gps[K].Vy2);
  GpiSetPageViewport := 1;
End;

Function GpiQueryPageViewport(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryPageViewport := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  WrL(P, Gps[K].Vx1); WrL(P + 4, Gps[K].Vy1); WrL(P + 8, Gps[K].Vx2); WrL(P + 12, Gps[K].Vy2);
  GpiQueryPageViewport := 1;
End;

{ GpiSetGraphicsField(hps, prclField) : rectangle de la page (0 : aucun) }
Function GpiSetGraphicsField(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetGraphicsField := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If P = 0 Then Gps[K].X[gxGfOn] := 0
  Else
  Begin
    Gps[K].X[gxGfX1] := RdL(P); Gps[K].X[gxGfY1] := RdL(P + 4); Gps[K].X[gxGfX2] := RdL(P + 8); Gps[K].X[gxGfY2] := RdL(P + 12);
    Gps[K].X[gxGfOn] := 1;
  End;
  GpiSetGraphicsField := 1;
End;

Function GpiQueryGraphicsField(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryGraphicsField := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  If Gps[K].X[gxGfOn] = 0 Then MemZero(P, 16)
  Else
  Begin
    WrL(P, Gps[K].X[gxGfX1]); WrL(P + 4, Gps[K].X[gxGfY1]); WrL(P + 8, Gps[K].X[gxGfX2]); WrL(P + 12, Gps[K].X[gxGfY2]);
  End;
  GpiQueryGraphicsField := 1;
End;

{ GpiSetViewingLimits(hps, prclLimits) : rectangle de l'espace modele }
Function GpiSetViewingLimits(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetViewingLimits := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If P = 0 Then Gps[K].X[gxVlOn] := 0
  Else
  Begin
    RecI(E_SETVIEWLIMITS); RecL(RdL(P)); RecL(RdL(P + 4)); RecL(RdL(P + 8)); RecL(RdL(P + 12));
    Dummy := LongInt(RecDone(K, 0, 0));
    Gps[K].X[gxVlX1] := RdL(P); Gps[K].X[gxVlY1] := RdL(P + 4); Gps[K].X[gxVlX2] := RdL(P + 8); Gps[K].X[gxVlY2] := RdL(P + 12);
    Gps[K].X[gxVlOn] := 1;
  End;
  GpiSetViewingLimits := 1;
End;

Function GpiQueryViewingLimits(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryViewingLimits := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  If Gps[K].X[gxVlOn] = 0 Then
  Begin
    WrL(P, -134217728); WrL(P + 4, -134217728); WrL(P + 8, 134217727); WrL(P + 12, 134217727);
  End
  Else
  Begin
    WrL(P, Gps[K].X[gxVlX1]); WrL(P + 4, Gps[K].X[gxVlY1]); WrL(P + 8, Gps[K].X[gxVlX2]); WrL(P + 12, Gps[K].X[gxVlY2]);
  End;
  GpiQueryViewingLimits := 1;
End;

Function GpiSetDefViewingLimits(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetDefViewingLimits := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If P = 0 Then Gps[K].X[gxDefVlOn] := 0
  Else
  Begin
    Gps[K].X[gxDefVlX1] := RdL(P); Gps[K].X[gxDefVlY1] := RdL(P + 4); Gps[K].X[gxDefVlX2] := RdL(P + 8);
    Gps[K].X[gxDefVlY2] := RdL(P + 12); Gps[K].X[gxDefVlOn] := 1;
  End;
  GpiSetDefViewingLimits := 1;
End;

Function GpiQueryDefViewingLimits(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryDefViewingLimits := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  If Gps[K].X[gxDefVlOn] = 0 Then
  Begin
    WrL(P, -134217728); WrL(P + 4, -134217728); WrL(P + 8, 134217727); WrL(P + 12, 134217727);
  End
  Else
  Begin
    WrL(P, Gps[K].X[gxDefVlX1]); WrL(P + 4, Gps[K].X[gxDefVlY1]); WrL(P + 8, Gps[K].X[gxDefVlX2]); WrL(P + 12, Gps[K].X[gxDefVlY2]);
  End;
  GpiQueryDefViewingLimits := 1;
End;


{ ==================================================================== }
{ Partie 7 - Segments, elements, correlation, metafichiers, divers      }
{ ==================================================================== }


Function GpiSetDrawingMode(Hps, M : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (M < 1) Or (M > 3) Then GpiSetDrawingMode := 0
  Else
  Begin
    Gps[K].X[gxDrawMode] := M;
    GpiSetDrawingMode := 1;
  End;
End;

Function GpiQueryDrawingMode(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryDrawingMode := 0 Else GpiQueryDrawingMode := Gps[K].X[gxDrawMode];
End;

{ GpiSetDrawControl(hps, lControl, lValue) : DCTL_ERASE 1, DISPLAY 2,
  BOUNDARY 3, DYNAMIC 4, CORRELATE 5 }
Function GpiSetDrawControl(Hps, C, V : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetDrawControl := 0;
  K := PsK(Hps);
  If (K < 0) Or (C < 1) Or (C > 5) Then Exit;
  Gps[K].X[gxDCtl + C] := V;
  If C = 3 Then
  Begin
    If V <> 0 Then
    Begin
      If Gps[K].X[gxBndOn] = 0 Then Gps[K].X[gxBndOn] := 1;
    End
    Else Gps[K].X[gxBndOn] := 0;
  End;
  GpiSetDrawControl := 1;
End;

Function GpiQueryDrawControl(Hps, C : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (C < 1) Or (C > 5) Then GpiQueryDrawControl := -1 Else GpiQueryDrawControl := Gps[K].X[gxDCtl + C];
End;

Function GpiSetStopDraw(Hps, V : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiSetStopDraw := 0
  Else
  Begin
    Gps[K].X[gxStopDraw] := V;
    GpiSetStopDraw := 1;
  End;
End;

Function GpiQueryStopDraw(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryStopDraw := -1 Else GpiQueryStopDraw := Gps[K].X[gxStopDraw];
End;

Function GpiSetEditMode(Hps, M : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (M < 1) Or (M > 2) Then GpiSetEditMode := 0
  Else
  Begin
    Gps[K].X[gxEditMode] := M;
    GpiSetEditMode := 1;
  End;
End;

Function GpiQueryEditMode(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryEditMode := 0 Else GpiQueryEditMode := Gps[K].X[gxEditMode];
End;

{ --- rejeu des elements d'un tampon dans l'espace K --- }
Function DrawSeg(K, S : LongInt) : Boolean; Forward;

Procedure ReplayBuf(K, Buf, Len : LongInt);
Var O, T, D, H, E, L, S, Sv : LongInt; M : Array[0..8] Of LongInt;
Begin
  If ReplayDepth > 16 Then Exit;
  Inc(ReplayDepth);
  Sv := Replaying;
  Replaying := 1;
  H := HpsOf(K);
  O := 0;
  While (O < Len) And (Gps[K].X[gxStopDraw] = 0) Do
  Begin
    T := RdL(Buf + O); L := RdL(Buf + O + 4); D := Buf + O + 8;
    E := T - ETYPE_BASE;
    Hit := 0;
    Case E Of
      E_SETCOLOR : Dummy := GpiSetColor(H, RdL(D));
      E_SETBACKCOLOR : Dummy := GpiSetBackColor(H, RdL(D));
      E_SETMIX : Dummy := GpiSetMix(H, RdL(D));
      E_SETBACKMIX : Dummy := GpiSetBackMix(H, RdL(D));
      E_SETLINETYPE : Dummy := GpiSetLineType(H, RdL(D));
      E_SETLINEWIDTH : Dummy := GpiSetLineWidth(H, RdL(D));
      E_SETLINEWIDTHGEOM : Dummy := GpiSetLineWidthGeom(H, RdL(D));
      E_SETLINEEND : Dummy := GpiSetLineEnd(H, RdL(D));
      E_SETLINEJOIN : Dummy := GpiSetLineJoin(H, RdL(D));
      E_SETCURPOS : Dummy := GpiSetCurrentPosition(H, D);
      E_MOVE : Dummy := GpiMove(H, D);
      E_LINE : Dummy := GpiLine(H, D);
      E_POLYLINE : Dummy := GpiPolyLine(H, RdL(D), D + 4);
      E_BOX : Dummy := GpiBox(H, RdL(D), D + 4, RdL(D + 12), RdL(D + 16));
      E_SETARCPARAMS : Dummy := GpiSetArcParams(H, D);
      E_POINTARC : Dummy := GpiPointArc(H, D);
      E_FULLARC : Dummy := GpiFullArc(H, RdL(D), RdL(D + 4));
      E_PARTIALARC : Dummy := GpiPartialArc(H, D, RdL(D + 8), RdL(D + 12), RdL(D + 16));
      E_POLYFILLET : Dummy := GpiPolyFillet(H, RdL(D), D + 4);
      E_POLYFILLETSHARP : Dummy := GpiPolyFilletSharp(H, RdL(D), D + 4, D + 4 + RdL(D) * 8);
      E_POLYSPLINE : Dummy := GpiPolySpline(H, RdL(D), D + 4);
      E_SETPATTERNSET : Dummy := GpiSetPatternSet(H, RdL(D));
      E_SETPATTERN : Dummy := GpiSetPattern(H, RdL(D));
      E_SETPATTERNREF : Dummy := GpiSetPatternRefPoint(H, D);
      E_BEGINAREA : Dummy := GpiBeginArea(H, RdL(D));
      E_ENDAREA : Dummy := GpiEndArea(H);
      E_SETCHARSET : Dummy := GpiSetCharSet(H, RdL(D));
      E_SETCHARBOX : Dummy := GpiSetCharBox(H, D);
      E_SETCHARANGLE : Dummy := GpiSetCharAngle(H, D);
      E_SETCHARSHEAR : Dummy := GpiSetCharShear(H, D);
      E_SETCHARDIR : Dummy := GpiSetCharDirection(H, RdL(D));
      E_SETCHARMODE : Dummy := GpiSetCharMode(H, RdL(D));
      E_CHARSTRING : Dummy := GpiCharString(H, RdL(D + 8), D + 12);
      E_CHARSTRINGPOS : Dummy := GpiCharStringPosAt(H, D, D + 16, RdL(D + 8), RdL(D + 12), D + 32, 0);
      E_SETMARKERSET : Dummy := GpiSetMarkerSet(H, RdL(D));
      E_SETMARKER : Dummy := GpiSetMarker(H, RdL(D));
      E_SETMARKERBOX : Dummy := GpiSetMarkerBox(H, D);
      E_MARKER : Dummy := GpiMarker(H, D);
      E_POLYMARKER : Dummy := GpiPolyMarker(H, RdL(D), D + 4);
      E_IMAGE : Dummy := GpiImage(H, RdL(D), D + 4, RdL(D + 12), D + 16);
      E_SETPEL : Dummy := GpiSetPel(H, D);
      E_SETTAG : Dummy := GpiSetTag(H, RdL(D));
      E_SETMODELXFORM : Dummy := GpiSetModelTransformMatrix(H, RdL(D), D + 8, RdL(D + 4));
      E_CALLSEGMENT :
        Begin
          S := SegIdx(K, RdL(D));
          If S >= 0 Then
          Begin
            MemMove(LongInt(@Gps[K].Mdl), LongInt(@M), 36);
            ApplyMat(LongInt(@Gps[K].Mdl), RdL(D + 4), D + 12, RdL(D + 8));
            Dummy := LongInt(DrawSeg(K, S));
            MemMove(LongInt(@M), LongInt(@Gps[K].Mdl), 36);
          End;
        End;
      E_POLYLINEDISJ : Dummy := GpiPolyLineDisjoint(H, RdL(D), D + 4);
      E_SETCHAREXTRA : Dummy := GpiSetCharExtra(H, RdL(D));
      E_SETCHARBREAK : Dummy := GpiSetCharBreakExtra(H, RdL(D));
      E_SETTEXTALIGN : Dummy := GpiSetTextAlignment(H, RdL(D), RdL(D + 4));
      E_BEGINPATH : Dummy := GpiBeginPath(H, RdL(D));
      E_ENDPATH : Dummy := GpiEndPath(H);
      E_CLOSEFIGURE : Dummy := GpiCloseFigure(H);
      E_FILLPATH : Dummy := GpiFillPath(H, RdL(D), RdL(D + 4));
      E_STROKEPATH : Dummy := GpiStrokePath(H, RdL(D), RdL(D + 4));
      E_OUTLINEPATH : Dummy := GpiOutlinePath(H, RdL(D), RdL(D + 4));
      E_POP : Dummy := GpiPop(H, RdL(D));
      E_SETATTRS : Dummy := GpiSetAttrs(H, RdL(D), RdL(D + 4), RdL(D + 8), D + 12);
      E_FLOODFILL : Dummy := GpiFloodFill(H, RdL(D), RdL(D + 4));
      E_ERASE : Dummy := GpiErase(H);
      E_SETVIEWLIMITS : Dummy := GpiSetViewingLimits(H, D);
    End;
    { correlation : un element a touche l'ouverture }
    If (RMode = 2) And (Hit <> 0) And (CorHits < CorMax) Then
    Begin
      If CorOut <> 0 Then
      Begin
        WrL(CorOut + CorHits * 8, SgId[CorSeg]); WrL(CorOut + CorHits * 8 + 4, Gps[K].X[gxTag]);
      End;
      Inc(CorHits);
      Hit := 0;
    End;
    O := O + 8 + ((L + 3) And Not 3);
  End;
  Replaying := Sv;
  Dec(ReplayDepth);
End;

{ dessiner un segment : attributs par defaut, transformation du segment }
Function DrawSeg(K, S : LongInt) : Boolean;
Var Save, M : LongInt; Cs : LongInt;
Begin
  DrawSeg := True;
  If (SgAttr[S] And 4) = 0 Then Exit;                     { invisible }
  Save := MemAlloc(SizeOf(TGps));
  If Save = 0 Then Exit;
  MemMove(LongInt(@Gps[K]), Save, SizeOf(TGps));
  AttrDefaults(K);
  Gps[K].X[gxOpenSeg] := 0;
  MatMul(LongInt(@SgXf[S * 9]), LongInt(@Gps[K].Mdl), LongInt(@Gps[K].Mdl));
  Cs := CorSeg;
  CorSeg := S;
  ReplayBuf(K, SgData[S], SgLen[S]);
  CorSeg := Cs;
  M := Gps[K].X[gxStopDraw];
  MemMove(Save, LongInt(@Gps[K]), SizeOf(TGps));
  Gps[K].X[gxStopDraw] := M;
  MemFree(Save);
End;

{ segments de la chaine de l'espace K dans l'ordre (rangs dans L) }
Function ChainList(K, L : LongInt) : LongInt;
Var I, J, N, T : LongInt;
Begin
  N := 0;
  For I := 0 To MaxSeg - 1 Do
    If (SgUse[I] <> 0) And (SgPs[I] = K) And ((SgAttr[I] And (1 Shl 6)) <> 0) Then
    Begin
      WrL(L + N * 4, I);
      Inc(N);
    End;
  For I := 1 To N - 1 Do
  Begin
    T := RdL(L + I * 4); J := I;
    While (J > 0) And (SgPri[RdL(L + (J - 1) * 4)] > SgPri[T]) Do
    Begin
      WrL(L + J * 4, RdL(L + (J - 1) * 4));
      Dec(J);
    End;
    WrL(L + J * 4, T);
  End;
  ChainList := N;
End;

Function DrawRange(K, First, Last : LongInt) : LongInt;
Var L, N, I, S : LongInt; On : Boolean;
Begin
  DrawRange := 1;
  L := MemAlloc(MaxSeg * 4);
  If L = 0 Then Exit;
  N := ChainList(K, L);
  On := First = 0;
  I := 0;
  While (I < N) And (Gps[K].X[gxStopDraw] = 0) Do
  Begin
    S := RdL(L + I * 4);
    If SgId[S] = First Then On := True;
    If On Then Dummy := LongInt(DrawSeg(K, S));
    If (Last <> 0) And (SgId[S] = Last) Then On := False;
    Inc(I);
  End;
  MemFree(L);
End;

Function GpiDrawChain(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiDrawChain := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Gps[K].X[gxDCtl + 1] <> 0 Then Dummy := GpiErase(Hps);
  Gps[K].X[gxStopDraw] := 0;
  GpiDrawChain := DrawRange(K, 0, 0);
End;

Function GpiDrawFrom(Hps, First, Last : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiDrawFrom := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  Gps[K].X[gxStopDraw] := 0;
  GpiDrawFrom := DrawRange(K, First, Last);
End;

Function GpiDrawSegment(Hps, Id : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  GpiDrawSegment := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := SegIdx(K, Id);
  If S < 0 Then
  Begin
    SetErr(PMERR_INV_SEG);
    Exit;
  End;
  Gps[K].X[gxStopDraw] := 0;
  Dummy := LongInt(DrawSeg(K, S));
  GpiDrawSegment := 1;
End;

{ segments dynamiques : redessines par GpiDrawDynamics }
Function GpiDrawDynamics(Hps : LongInt) : LongInt;
Var K, I : LongInt;
Begin
  GpiDrawDynamics := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  For I := 0 To MaxSeg - 1 Do
    If (SgUse[I] <> 0) And (SgPs[I] = K) And ((SgAttr[I] And (1 Shl 8)) <> 0) Then Dummy := LongInt(DrawSeg(K, I));
  GpiDrawDynamics := 1;
End;

Function GpiRemoveDynamics(Hps, First, Last : LongInt) : LongInt;
Begin
  If PsK(Hps) < 0 Then GpiRemoveDynamics := 0 Else GpiRemoveDynamics := 1;
End;

{ GpiOpenSegment(hps, lSegment) : cree ou rouvre (fin du segment) }
Function GpiOpenSegment(Hps, Id : LongInt) : LongInt;
Var K, S, I, P : LongInt;
Begin
  GpiOpenSegment := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If (Gps[K].X[gxOpenSeg] <> 0) Or (Id < 0) Then
  Begin
    SetErr(PMERR_INV_SEG);
    Exit;
  End;
  S := SegIdx(K, Id);
  If S < 0 Then
  Begin
    For I := MaxSeg - 1 DownTo 0 Do
      If SgUse[I] = 0 Then S := I;
    If S < 0 Then
    Begin
      SetErr(PMERR_INSUFFICIENT_MEMORY);
      Exit;
    End;
    SgUse[S] := 1; SgPs[S] := K; SgId[S] := Id; SgData[S] := 0; SgLen[S] := 0; SgCap[S] := 0;
    SgAttr[S] := 0;
    For I := 1 To 11 Do
      If SegInit[K * 16 + I] <> 0 Then SgAttr[S] := SgAttr[S] Or (1 Shl I);
    P := 0;
    For I := 0 To MaxSeg - 1 Do
      If (SgUse[I] <> 0) And (SgPs[I] = K) And (I <> S) Then P := MaxI(P, SgPri[I]);
    SgPri[S] := P + 1;
    MatIdent(LongInt(@SgXf[S * 9]));
  End;
  Gps[K].X[gxOpenSeg] := Id;
  If Id = 0 Then Gps[K].X[gxOpenSeg] := -1;
  Gps[K].X[gxElemPtr] := ElemCount(SgData[S], SgLen[S]);
  GpiOpenSegment := 1;
End;

Function GpiCloseSegment(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiCloseSegment := 0;
  K := PsK(Hps);
  If (K < 0) Or (Gps[K].X[gxOpenSeg] = 0) Then Exit;
  Gps[K].X[gxOpenSeg] := 0;
  Gps[K].X[gxElemPtr] := 0;
  GpiCloseSegment := 1;
End;

Function GpiDeleteSegments(Hps, First, Last : LongInt) : LongInt;
Var K, I : LongInt;
Begin
  GpiDeleteSegments := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  For I := 0 To MaxSeg - 1 Do
    If (SgUse[I] <> 0) And (SgPs[I] = K) And (SgId[I] >= First) And (SgId[I] <= Last) Then
    Begin
      If Gps[K].X[gxOpenSeg] = SgId[I] Then Gps[K].X[gxOpenSeg] := 0;
      MemFree(SgData[I]);
      SgUse[I] := 0;
    End;
  GpiDeleteSegments := 1;
End;

Function GpiDeleteSegment(Hps, Id : LongInt) : LongInt;
Begin
  GpiDeleteSegment := GpiDeleteSegments(Hps, Id, Id);
End;

{ GpiQuerySegmentNames(hps, lFirstid, lLastid, lMax, alSegids) }
Function GpiQuerySegmentNames(Hps, First, Last, Max, P : LongInt) : LongInt;
Var K, I, J, N, T : LongInt;
Begin
  GpiQuerySegmentNames := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  N := 0;
  For I := 0 To MaxSeg - 1 Do
    If (SgUse[I] <> 0) And (SgPs[I] = K) And (SgId[I] >= First) And (SgId[I] <= Last) And (N < Max) Then
    Begin
      If P <> 0 Then
      Begin
        T := SgId[I]; J := N;
        While (J > 0) And (RdL(P + (J - 1) * 4) > T) Do
        Begin
          WrL(P + J * 4, RdL(P + (J - 1) * 4));
          Dec(J);
        End;
        WrL(P + J * 4, T);
      End;
      Inc(N);
    End;
  GpiQuerySegmentNames := N;
End;

{ attributs des segments : ATTR_DETECTABLE 1, VISIBLE 2, CHAINED 6,
  DYNAMIC 8, FASTCHAIN 9, PROP_DETECTABLE 10, PROP_VISIBLE 11 }
Function GpiSetInitialSegmentAttrs(Hps, A, V : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (A < 1) Or (A > 11) Then GpiSetInitialSegmentAttrs := 0
  Else
  Begin
    SegInit[K * 16 + A] := V;
    GpiSetInitialSegmentAttrs := 1;
  End;
End;

Function GpiQueryInitialSegmentAttrs(Hps, A : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (A < 1) Or (A > 11) Then GpiQueryInitialSegmentAttrs := -1
  Else GpiQueryInitialSegmentAttrs := SegInit[K * 16 + A];
End;

Function GpiSetSegmentAttrs(Hps, Id, A, V : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  GpiSetSegmentAttrs := 0;
  K := PsK(Hps);
  If (K < 0) Or (A < 1) Or (A > 11) Then Exit;
  S := SegIdx(K, Id);
  If S < 0 Then
  Begin
    SetErr(PMERR_INV_SEG);
    Exit;
  End;
  If V <> 0 Then SgAttr[S] := SgAttr[S] Or (1 Shl A) Else SgAttr[S] := SgAttr[S] And Not (1 Shl A);
  GpiSetSegmentAttrs := 1;
End;

Function GpiQuerySegmentAttrs(Hps, Id, A : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  GpiQuerySegmentAttrs := -1;
  K := PsK(Hps);
  If (K < 0) Or (A < 1) Or (A > 11) Then Exit;
  S := SegIdx(K, Id);
  If S >= 0 Then GpiQuerySegmentAttrs := (SgAttr[S] Shr A) And 1;
End;

{ GpiSetSegmentPriority(hps, lSegid, lRefSegid, lOrder) : HIGHER_PRI 1
  (apres la reference), LOWER_PRI -1 (avant) }
Function GpiSetSegmentPriority(Hps, Id, Ref, Ord1 : LongInt) : LongInt;
Var K, S, R, L, N, I, P : LongInt;
Begin
  GpiSetSegmentPriority := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := SegIdx(K, Id); R := SegIdx(K, Ref);
  If (S < 0) Or ((Ref <> 0) And (R < 0)) Then
  Begin
    SetErr(PMERR_INV_SEG);
    Exit;
  End;
  L := MemAlloc(MaxSeg * 4);
  If L = 0 Then Exit;
  N := ChainList(K, L);
  P := 1;
  For I := 0 To N - 1 Do
    If RdL(L + I * 4) <> S Then
    Begin
      If (RdL(L + I * 4) = R) And (Ord1 < 0) Then
      Begin
        SgPri[S] := P; Inc(P);
      End;
      SgPri[RdL(L + I * 4)] := P; Inc(P);
      If (RdL(L + I * 4) = R) And (Ord1 >= 0) Then
      Begin
        SgPri[S] := P; Inc(P);
      End;
    End;
  If R < 0 Then
  Begin
    If Ord1 >= 0 Then SgPri[S] := P Else SgPri[S] := 0;
  End;
  MemFree(L);
  GpiSetSegmentPriority := 1;
End;

{ GpiQuerySegmentPriority(hps, lRefSegid, lOrder) : segment voisin }
Function GpiQuerySegmentPriority(Hps, Ref, Ord1 : LongInt) : LongInt;
Var K, L, N, I, R : LongInt;
Begin
  GpiQuerySegmentPriority := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  L := MemAlloc(MaxSeg * 4);
  If L = 0 Then Exit;
  N := ChainList(K, L);
  R := 0;
  For I := 0 To N - 1 Do
    If SgId[RdL(L + I * 4)] = Ref Then
    Begin
      If (Ord1 > 0) And (I + 1 < N) Then R := SgId[RdL(L + (I + 1) * 4)];
      If (Ord1 < 0) And (I > 0) Then R := SgId[RdL(L + (I - 1) * 4)];
    End;
  MemFree(L);
  GpiQuerySegmentPriority := R;
End;

Function GpiSetSegmentTransformMatrix(Hps, Id, N, P, Opt : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  GpiSetSegmentTransformMatrix := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := SegIdx(K, Id);
  If (S < 0) Or ((N > 0) And (P = 0)) Then Exit;
  ApplyMat(LongInt(@SgXf[S * 9]), N, P, Opt);
  GpiSetSegmentTransformMatrix := 1;
End;

Function GpiQuerySegmentTransformMatrix(Hps, Id, N, P : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  GpiQuerySegmentTransformMatrix := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := SegIdx(K, Id);
  If (S < 0) Or (P = 0) Then Exit;
  MemMove(LongInt(@SgXf[S * 9]), P, MinI(N, 9) * 4);
  GpiQuerySegmentTransformMatrix := 1;
End;

{ GpiCallSegmentMatrix(hps, lSegment, lCount, pmatlfArray, lOptions) }
Function GpiCallSegmentMatrix(Hps, Id, N, P, Opt : LongInt) : LongInt;
Var K, S : LongInt; M : Array[0..8] Of LongInt;
Begin
  GpiCallSegmentMatrix := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E_CALLSEGMENT); RecL(Id); RecL(N); RecL(Opt);
  If Not RecDone(K, P, N * 4) Then
  Begin
    GpiCallSegmentMatrix := 1;
    Exit;
  End;
  S := SegIdx(K, Id);
  If S < 0 Then
  Begin
    SetErr(PMERR_INV_SEG);
    Exit;
  End;
  MemMove(LongInt(@Gps[K].Mdl), LongInt(@M), 36);
  If (N > 0) And (P <> 0) Then ApplyMat(LongInt(@Gps[K].Mdl), N, P, Opt);
  Dummy := LongInt(DrawSeg(K, S));
  MemMove(LongInt(@M), LongInt(@Gps[K].Mdl), 36);
  GpiCallSegmentMatrix := 1;
End;

Function GpiErrorSegmentData(Hps, PSeg, PCtx : LongInt) : LongInt;
Begin
  If PSeg <> 0 Then WrL(PSeg, 0);
  If PCtx <> 0 Then WrL(PCtx, 0);
  GpiErrorSegmentData := 0;
End;

{ --- elements du segment ouvert --- }
Function OpenSegIdx(K : LongInt) : LongInt;
Var Id : LongInt;
Begin
  Id := Gps[K].X[gxOpenSeg];
  If Id = -1 Then Id := 0;
  If Gps[K].X[gxOpenSeg] = 0 Then OpenSegIdx := -1 Else OpenSegIdx := SegIdx(K, Id);
End;

Function GpiSetElementPointer(Hps, N : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  GpiSetElementPointer := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := OpenSegIdx(K);
  If S < 0 Then Exit;
  Gps[K].X[gxElemPtr] := MaxI(0, MinI(N, ElemCount(SgData[S], SgLen[S])));
  GpiSetElementPointer := 1;
End;

Function GpiQueryElementPointer(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiQueryElementPointer := -1 Else GpiQueryElementPointer := Gps[K].X[gxElemPtr];
End;

Function GpiOffsetElementPointer(Hps, D : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiOffsetElementPointer := 0
  Else GpiOffsetElementPointer := GpiSetElementPointer(Hps, Gps[K].X[gxElemPtr] + D);
End;

Function GpiDeleteElementRange(Hps, First, Last : LongInt) : LongInt;
Var K, S, I : LongInt;
Begin
  GpiDeleteElementRange := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := OpenSegIdx(K);
  If (S < 0) Or (First < 1) Or (Last < First) Then Exit;
  For I := Last DownTo First Do
    If I <= ElemCount(SgData[S], SgLen[S]) Then BufDelete(SgData[S], SgLen[S], ElemOfs(SgData[S], SgLen[S], I));
  Gps[K].X[gxElemPtr] := MaxI(0, First - 1);
  GpiDeleteElementRange := 1;
End;

Function GpiDeleteElement(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If (K < 0) Or (Gps[K].X[gxElemPtr] < 1) Then GpiDeleteElement := 0
  Else GpiDeleteElement := GpiDeleteElementRange(Hps, Gps[K].X[gxElemPtr], Gps[K].X[gxElemPtr]);
End;

Function GpiLabel(Hps, L : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiLabel := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E_LABEL); RecL(L);
  Dummy := LongInt(RecDone(K, 0, 0));
  GpiLabel := 1;
End;

{ numero de l'element etiquette L apres Start (0 : absent) }
Function FindLabel(S, Start, L : LongInt) : LongInt;
Var O, N, R : LongInt;
Begin
  R := 0; O := 0; N := 0;
  While (O < SgLen[S]) And (R = 0) Do
  Begin
    Inc(N);
    If (N > Start) And (RdL(SgData[S] + O) = ETYPE_BASE + E_LABEL) And (RdL(SgData[S] + O + 8) = L) Then R := N;
    O := O + 8 + ((RdL(SgData[S] + O + 4) + 3) And Not 3);
  End;
  FindLabel := R;
End;

Function GpiSetElementPointerAtLabel(Hps, L : LongInt) : LongInt;
Var K, S, N : LongInt;
Begin
  GpiSetElementPointerAtLabel := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := OpenSegIdx(K);
  If S < 0 Then Exit;
  N := FindLabel(S, Gps[K].X[gxElemPtr], L);
  If N = 0 Then N := FindLabel(S, 0, L);
  If N > 0 Then
  Begin
    Gps[K].X[gxElemPtr] := N;
    GpiSetElementPointerAtLabel := 1;
  End;
End;

Function GpiDeleteElementsBetweenLabels(Hps, L1, L2 : LongInt) : LongInt;
Var K, S, A, B : LongInt;
Begin
  GpiDeleteElementsBetweenLabels := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := OpenSegIdx(K);
  If S < 0 Then Exit;
  A := FindLabel(S, 0, L1);
  If A = 0 Then Exit;
  B := FindLabel(S, A, L2);
  If B = 0 Then Exit;
  If B - A > 1 Then Dummy := GpiDeleteElementRange(Hps, A + 1, B - 1);
  Gps[K].X[gxElemPtr] := A;
  GpiDeleteElementsBetweenLabels := 1;
End;

{ GpiQueryElementType(hps, plType, lLength, pszData) : taille des donnees }
Function GpiQueryElementType(Hps, PT, Len, PD : LongInt) : LongInt;
Var K, S, O : LongInt;
Begin
  GpiQueryElementType := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := OpenSegIdx(K);
  If (S < 0) Or (Gps[K].X[gxElemPtr] < 1) Then Exit;
  O := ElemOfs(SgData[S], SgLen[S], Gps[K].X[gxElemPtr]);
  If O >= SgLen[S] Then Exit;
  If PT <> 0 Then WrL(PT, RdL(SgData[S] + O));
  If (PD <> 0) And (Len > 0) Then WrB(PD, 0);
  GpiQueryElementType := RdL(SgData[S] + O + 4);
End;

{ GpiQueryElement(hps, lOff, lMaxLength, pbData) : octets copies }
Function GpiQueryElement(Hps, Off, Max, P : LongInt) : LongInt;
Var K, S, O, L : LongInt;
Begin
  GpiQueryElement := -1;
  K := PsK(Hps);
  If K < 0 Then Exit;
  S := OpenSegIdx(K);
  If (S < 0) Or (Gps[K].X[gxElemPtr] < 1) Or (P = 0) Then Exit;
  O := ElemOfs(SgData[S], SgLen[S], Gps[K].X[gxElemPtr]);
  L := RdL(SgData[S] + O + 4) - Off;
  If L < 0 Then L := 0;
  L := MinI(L, Max);
  MemMove(SgData[S] + O + 8 + Off, P, L);
  GpiQueryElement := L;
End;

{ GpiElement(hps, lType, pszDesc, lLength, pbData) : element brut }
Function GpiElement(Hps, T, PDesc, Len, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiElement := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If Not AddElem(K, T, P, MaxI(Len, 0)) Then
  Begin
    If (Gps[K].X[gxOpenSeg] = 0) Then GpiElement := 1;
    Exit;
  End;
  GpiElement := 1;
End;

Function GpiBeginElement(Hps, T, PDesc : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiBeginElement := 0;
  K := PsK(Hps);
  If (K < 0) Or (Gps[K].X[gxInElem] <> 0) Then Exit;
  Gps[K].X[gxInElem] := 1; Gps[K].X[gxElemStart] := Gps[K].X[gxElemPtr];
  GpiBeginElement := 1;
End;

Function GpiEndElement(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiEndElement := 0;
  K := PsK(Hps);
  If (K < 0) Or (Gps[K].X[gxInElem] = 0) Then Exit;
  Gps[K].X[gxInElem] := 0;
  GpiEndElement := 1;
End;

{ GpiGetData(hps, lSegment, plOffset, lFormat, lLength, pbData) : octets }
Function GpiGetData(Hps, Id, POff, Fmt, Len, P : LongInt) : LongInt;
Var K, S, O, L : LongInt;
Begin
  GpiGetData := -1;
  K := PsK(Hps);
  If (K < 0) Or (POff = 0) Then Exit;
  S := SegIdx(K, Id);
  If S < 0 Then
  Begin
    SetErr(PMERR_INV_SEG);
    Exit;
  End;
  O := RdL(POff);
  L := MaxI(0, MinI(Len, SgLen[S] - O));
  If P <> 0 Then MemMove(SgData[S] + O, P, L);
  WrL(POff, O + L);
  GpiGetData := L;
End;

{ GpiPutData(hps, lFormat, plCount, pbData) : elements complets ajoutes }
Function GpiPutData(Hps, Fmt, PN, P : LongInt) : LongInt;
Var K, N, O, L : LongInt;
Begin
  GpiPutData := 0;
  K := PsK(Hps);
  If (K < 0) Or (PN = 0) Or (P = 0) Then Exit;
  N := RdL(PN); O := 0;
  While O + 8 <= N Do
  Begin
    L := RdL(P + O + 4);
    If O + 8 + L > N Then O := N
    Else
    Begin
      Dummy := LongInt(AddElem(K, RdL(P + O), P + O + 8, L));
      O := O + 8 + ((L + 3) And Not 3);
    End;
  End;
  WrL(PN, MinI(O, N));
  GpiPutData := 1;
End;

{ --- ouverture de selection et correlation --- }
Function GpiSetPickApertureSize(Hps, Opt, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetPickApertureSize := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  If (Opt = 0) Or (P = 0) Then
  Begin
    Gps[K].X[gxPickW] := 2; Gps[K].X[gxPickH] := 2;
  End
  Else
  Begin
    Gps[K].X[gxPickW] := MaxI(1, RdL(P)); Gps[K].X[gxPickH] := MaxI(1, RdL(P + 4));
  End;
  GpiSetPickApertureSize := 1;
End;

Function GpiQueryPickApertureSize(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryPickApertureSize := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  WrL(P, Gps[K].X[gxPickW]); WrL(P + 4, Gps[K].X[gxPickH]);
  GpiQueryPickApertureSize := 1;
End;

Function GpiSetPickAperturePosition(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiSetPickAperturePosition := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  Gps[K].X[gxPickX] := RdL(P); Gps[K].X[gxPickY] := RdL(P + 4);
  GpiSetPickAperturePosition := 1;
End;

Function GpiQueryPickAperturePosition(Hps, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiQueryPickAperturePosition := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  WrL(P, Gps[K].X[gxPickX]); WrL(P + 4, Gps[K].X[gxPickY]);
  GpiQueryPickAperturePosition := 1;
End;

{ correler les segments First..Last (0 : tous) ; resultats (segment,
  balise) ; PICKSEL_ALL 1 : y compris les segments non detectables }
Function Correlate(K, First, Last, Typ, PPt, Max, P : LongInt) : LongInt;
Var L, N, I, S, X, Y, Save : LongInt; On : Boolean;
Begin
  Correlate := -1;
  If PPt <> 0 Then
  Begin
    Gps[K].X[gxPickX] := RdL(PPt); Gps[K].X[gxPickY] := RdL(PPt + 4);
  End;
  PageDev(K, Gps[K].X[gxPickX], Gps[K].X[gxPickY], X, Y);
  HitX1 := X - Gps[K].X[gxPickW] Div 2; HitY1 := Y - Gps[K].X[gxPickH] Div 2;
  HitX2 := HitX1 + Gps[K].X[gxPickW]; HitY2 := HitY1 + Gps[K].X[gxPickH];
  L := MemAlloc(MaxSeg * 4);
  If L = 0 Then Exit;
  N := ChainList(K, L);
  CorHits := 0; CorMax := Max; CorOut := P;
  Save := RMode;
  RMode := 2;
  On := First = 0;
  For I := 0 To N - 1 Do
  Begin
    S := RdL(L + I * 4);
    If SgId[S] = First Then On := True;
    If On And ((Typ = 1) Or ((SgAttr[S] And 2) <> 0)) Then Dummy := LongInt(DrawSeg(K, S));
    If (Last <> 0) And (SgId[S] = Last) Then On := False;
  End;
  RMode := Save;
  MemFree(L);
  Correlate := CorHits;
End;

{ GpiCorrelateChain(hps, lType, pptlPick, lMaxHits, lMaxDepth, alSegTag) }
Function GpiCorrelateChain(Hps, Typ, PPt, Max, Depth, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiCorrelateChain := -1 Else GpiCorrelateChain := Correlate(K, 0, 0, Typ, PPt, Max, P);
End;

Function GpiCorrelateFrom(Hps, First, Last, Typ, PPt, Max, Depth, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiCorrelateFrom := -1 Else GpiCorrelateFrom := Correlate(K, First, Last, Typ, PPt, Max, P);
End;

Function GpiCorrelateSegment(Hps, Id, Typ, PPt, Max, Depth, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiCorrelateSegment := -1 Else GpiCorrelateSegment := Correlate(K, Id, Id, Typ, PPt, Max, P);
End;

{ --- donnees des limites --- }
Function GpiResetBoundaryData(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiResetBoundaryData := 0
  Else
  Begin
    If Gps[K].X[gxBndOn] <> 0 Then Gps[K].X[gxBndOn] := 1;
    GpiResetBoundaryData := 1;
  End;
End;

{ GpiQueryBoundaryData(hps, prclBoundary) : en coordonnees du modele
  (inverse de la vue et de la page) ; FALSE si rien n'a ete dessine }
Function GpiQueryBoundaryData(Hps, P : LongInt) : LongInt;
Var K, X1, Y1, X2, Y2 : LongInt;
Begin
  GpiQueryBoundaryData := 0;
  K := PsK(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  If Gps[K].X[gxBndOn] <> 2 Then
  Begin
    MemZero(P, 16);
    Exit;
  End;
  Convert(K, 5, 2, Gps[K].X[gxBndX1], Gps[K].X[gxBndY1], X1, Y1);
  Convert(K, 5, 2, Gps[K].X[gxBndX2], Gps[K].X[gxBndY2], X2, Y2);
  WrL(P, MinI(X1, X2)); WrL(P + 4, MinI(Y1, Y2)); WrL(P + 8, MaxI(X1, X2)); WrL(P + 12, MaxI(Y1, Y2));
  GpiQueryBoundaryData := 1;
End;

{ ==================================================================== }
{ Metafichiers (HMF 474Dxxxxh)                                          }
{ ==================================================================== }
Function MfIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $474D0001;
  If (I < 0) Or (I >= MaxMeta) Then I := -1
  Else If MfUse[I] = 0 Then I := -1;
  If I < 0 Then SetErr(PMERR_INV_HMF);
  MfIdx := I;
End;

Function NewMeta : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxMeta - 1 DownTo 0 Do
    If MfUse[I] = 0 Then F := I;
  If F >= 0 Then
  Begin
    MfUse[F] := 1; MfData[F] := 0; MfLen[F] := 0; MfCap[F] := 0;
  End;
  NewMeta := F;
End;

Function GpiDeleteMetaFile(H : LongInt) : LongInt;
Var M, D : LongInt;
Begin
  GpiDeleteMetaFile := 0;
  M := MfIdx(H);
  If M < 0 Then Exit;
  For D := 0 To MaxDC - 1 Do
    If (DcUse[D] <> 0) And (DcMeta[D] = M) Then Exit;
  MemFree(MfData[M]);
  MfUse[M] := 0;
  GpiDeleteMetaFile := 1;
End;

Function GpiCopyMetaFile(H : LongInt) : LongInt;
Var M, N : LongInt;
Begin
  GpiCopyMetaFile := 0;
  M := MfIdx(H);
  If M < 0 Then Exit;
  N := NewMeta;
  If N < 0 Then Exit;
  If BufGrow(MfData[N], MfLen[N], MfCap[N], MfLen[M] + 8) Then
  Begin
    MemMove(MfData[M], MfData[N], MfLen[M]);
    MfLen[N] := MfLen[M];
  End;
  GpiCopyMetaFile := $474D0001 + N;
End;

Function GpiQueryMetaFileLength(H : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := MfIdx(H);
  If M < 0 Then GpiQueryMetaFileLength := -1 Else GpiQueryMetaFileLength := MfLen[M] + 12;
End;

{ image du fichier : 'OS20MF01', longueur (4), elements }
Function GpiQueryMetaFileBits(H, Off, Len, P : LongInt) : LongInt;
Var M, I, B : LongInt; Hd : Array[0..11] Of Byte;
Begin
  GpiQueryMetaFileBits := 0;
  M := MfIdx(H);
  If (M < 0) Or (P = 0) Then Exit;
  PutZ(LongInt(@Hd), 'OS20MF01');
  WrL(LongInt(@Hd) + 8, MfLen[M]);
  For I := 0 To Len - 1 Do
  Begin
    If Off + I < 12 Then B := Hd[Off + I]
    Else If Off + I - 12 < MfLen[M] Then B := RdB(MfData[M] + Off + I - 12)
    Else B := 0;
    WrB(P + I, B);
  End;
  GpiQueryMetaFileBits := 1;
End;

Function GpiSetMetaFileBits(H, Off, Len, P : LongInt) : LongInt;
Var M, I, N : LongInt;
Begin
  GpiSetMetaFileBits := 0;
  M := MfIdx(H);
  If (M < 0) Or (P = 0) Then Exit;
  N := Off + Len - 12;
  If N > MfLen[M] Then
  Begin
    If Not BufGrow(MfData[M], MfLen[M], MfCap[M], N - MfLen[M]) Then Exit;
    MfLen[M] := N;
  End;
  For I := 0 To Len - 1 Do
    If Off + I >= 12 Then WrB(MfData[M] + Off + I - 12, RdB(P + I));
  GpiSetMetaFileBits := 1;
End;

{ GpiLoadMetaFile(hab, pszFilename) : HMF }
Function GpiLoadMetaFile(Hab, PName : LongInt) : LongInt;
Var H, A, N, Got, M : LongInt; Hd : Array[0..11] Of Byte;
Begin
  GpiLoadMetaFile := 0;
  H := 0; A := 0;
  If DcOpen(PName, LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0) <> 0 Then
  Begin
    SetErr(PMERR_INV_METAFILE);
    Exit;
  End;
  Got := 0;
  Dummy := DcRead(H, LongInt(@Hd), 12, LongInt(@Got));
  N := RdL(LongInt(@Hd) + 8);
  If (Got <> 12) Or (GetN(LongInt(@Hd), 8) <> 'OS20MF01') Or (N < 0) Or (N > 1000000) Then
  Begin
    Dummy := DcClose(H);
    SetErr(PMERR_INV_METAFILE);
    Exit;
  End;
  M := NewMeta;
  If (M >= 0) And BufGrow(MfData[M], MfLen[M], MfCap[M], N + 8) Then
  Begin
    Dummy := DcRead(H, MfData[M], N, LongInt(@Got));
    MfLen[M] := Got;
    GpiLoadMetaFile := $474D0001 + M;
  End;
  Dummy := DcClose(H);
End;

{ GpiSaveMetaFile(hmf, pszFilename) : ecrit puis supprime le metafichier }
Function GpiSaveMetaFile(Hm, PName : LongInt) : LongInt;
Var M, H, A, W : LongInt; Hd : Array[0..11] Of Byte;
Begin
  GpiSaveMetaFile := 0;
  M := MfIdx(Hm);
  If M < 0 Then Exit;
  H := 0; A := 0;
  If DcOpen(PName, LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0) <> 0 Then Exit;
  PutZ(LongInt(@Hd), 'OS20MF01');
  WrL(LongInt(@Hd) + 8, MfLen[M]);
  W := 0;
  Dummy := DcWrite(H, LongInt(@Hd), 12, LongInt(@W));
  If MfLen[M] > 0 Then Dummy := DcWrite(H, MfData[M], MfLen[M], LongInt(@W));
  Dummy := DcClose(H);
  MemFree(MfData[M]);
  MfUse[M] := 0;
  GpiSaveMetaFile := 1;
End;

{ GpiPlayMetaFile(hps, hmf, lCount1, alOptarray, plSegCount, lCount2,
  pszDesc) }
Function GpiPlayMetaFile(Hps, Hm, N1, POpt, PSeg, N2, PDesc : LongInt) : LongInt;
Var K, M : LongInt;
Begin
  GpiPlayMetaFile := 0;
  K := PsK(Hps);
  M := MfIdx(Hm);
  If (K < 0) Or (M < 0) Then Exit;
  If PSeg <> 0 Then WrL(PSeg, 0);
  If (PDesc <> 0) And (N2 > 0) Then Dummy := PutZN(PDesc, N2, 'OS/2-0');
  Gps[K].X[gxStopDraw] := 0;
  ReplayBuf(K, MfData[M], MfLen[M]);
  GpiPlayMetaFile := 1;
End;

Function GpiAccessMetaFile(Hm : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := MfIdx(Hm);
  If M < 0 Then GpiAccessMetaFile := 0 Else GpiAccessMetaFile := MfData[M];
End;

Function GpiOpenMetafile(Hab, PName : LongInt) : LongInt;
Begin
  GpiOpenMetafile := GpiLoadMetaFile(Hab, PName);
End;

Function GpiCloseMetafile(Hm : LongInt) : LongInt;
Begin
  GpiCloseMetafile := GpiDeleteMetaFile(Hm);
End;

Function GpiSuspendPlay(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiSuspendPlay := 0
  Else
  Begin
    Gps[K].X[gxStopDraw] := 1;
    GpiSuspendPlay := 1;
  End;
End;

Function GpiResumePlay(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsK(Hps);
  If K < 0 Then GpiResumePlay := 0
  Else
  Begin
    Gps[K].X[gxStopDraw] := 0;
    GpiResumePlay := 1;
  End;
End;

Function GpiMtAssociate(Hps, Hm : LongInt) : LongInt;
Begin
  GpiMtAssociate := 1;
End;

Function GpiMtDisassociate(Hps : LongInt) : LongInt;
Begin
  GpiMtDisassociate := 1;
End;

Function GpiComment(Hps, Len, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  GpiComment := 0;
  K := PsK(Hps);
  If K < 0 Then Exit;
  RecI(E_COMMENT); RecL(Len);
  Dummy := LongInt(RecDone(K, P, MaxI(Len, 0)));
  GpiComment := 1;
End;

{ --- lecture interne des metafichiers (Mt*) : requete = rang + 1 --- }
Function MtStartReadRequest(Hm : LongInt) : LongInt;
Var M, I, F : LongInt;
Begin
  MtStartReadRequest := 0;
  M := MfIdx(Hm);
  If M < 0 Then Exit;
  F := -1;
  For I := 7 DownTo 0 Do
    If MtCur[I] = 0 Then F := I;
  If F < 0 Then Exit;
  MtCur[F] := M + 1; MtPos[F] := 0;
  MtStartReadRequest := F + 1;
End;

Function MtEndReadRequest(R : LongInt) : LongInt;
Begin
  If (R >= 1) And (R <= 8) Then
  Begin
    MtCur[R - 1] := 0;
    MtEndReadRequest := 1;
  End
  Else MtEndReadRequest := 0;
End;

{ element suivant (type, longueur, donnees) copie dans P ; octets }
Function MtGetNextGraphicsData(R, P, Cb : LongInt) : LongInt;
Var M, O, L : LongInt;
Begin
  MtGetNextGraphicsData := 0;
  If (R < 1) Or (R > 8) Or (MtCur[R - 1] = 0) Then Exit;
  M := MtCur[R - 1] - 1;
  O := MtPos[R - 1];
  If O >= MfLen[M] Then Exit;
  L := 8 + ((RdL(MfData[M] + O + 4) + 3) And Not 3);
  If P <> 0 Then MemMove(MfData[M] + O, P, MinI(L, Cb));
  MtPos[R - 1] := O + L;
  MtGetNextGraphicsData := MinI(L, Cb);
End;

Function MtGetFirstGraphicsData(R, P, Cb : LongInt) : LongInt;
Begin
  If (R >= 1) And (R <= 8) Then MtPos[R - 1] := 0;
  MtGetFirstGraphicsData := MtGetNextGraphicsData(R, P, Cb);
End;

Function MtGetDescription(R, P, Cb : LongInt) : LongInt;
Begin
  MtGetDescription := PutZN(P, Cb, 'OS/2-0 metafichier');
End;

Function MtGetCodepage(R : LongInt) : LongInt;
Begin
  MtGetCodepage := 850;
End;

{ table de couleurs par defaut (16 RVB) }
Function MtGetLCT(R, P, Cb : LongInt) : LongInt;
Var I : LongInt;
Begin
  For I := 0 To MinI(Cb Div 4, 16) - 1 Do WrL(P + I * 4, DefTab[I]);
  MtGetLCT := MinI(Cb Div 4, 16);
End;

Function MtGetGDDInfo(R, P, Cb : LongInt) : LongInt;
Begin
  If (P <> 0) And (Cb >= 8) Then
  Begin
    WrL(P, 640); WrL(P + 4, 480);
  End;
  MtGetGDDInfo := 1;
End;

{ polices d'un metafichier : aucune }
Function MtGetFirstFont(R, P, Cb : LongInt) : LongInt;
Begin
  MtGetFirstFont := 0;
End;

Function MtGetNextFont(R, P, Cb : LongInt) : LongInt;
Begin
  MtGetNextFont := 0;
End;

{ fonctions internes de GOCA et des fenetres de segments : sans effet }
Function SegsGWOpenSegmentWindow(Hps, Id : LongInt) : LongInt;
Begin
  SegsGWOpenSegmentWindow := 1;
End;

Function SegsGWNewPartData(Hps, P, Cb : LongInt) : LongInt;
Begin
  SegsGWNewPartData := 1;
End;

Function SegsGWNextOrderF(Hps, P : LongInt) : LongInt;
Begin
  SegsGWNextOrderF := 0;
End;

Function FmtOrderTable(P : LongInt) : LongInt;
Begin
  FmtOrderTable := 0;
End;

Function FmtConvertGocaPoly(P, Cb, PO : LongInt) : LongInt;
Begin
  FmtConvertGocaPoly := 0;
End;

{ GpiStartRequest(hps) : demarrer une requete de saisie (non geree) }
Function GpiStartRequest(Hps : LongInt) : LongInt;
Begin
  If PsK(Hps) < 0 Then GpiStartRequest := 0 Else GpiStartRequest := 1;
End;

{ GpiVectorSymbol(hps, ...) : symboles vectoriels (aucun) }
Function GpiVectorSymbol(Hps, P : LongInt) : LongInt;
Begin
  GpiVectorSymbol := 0;
End;

{ GpiConvPSH(hps) : handle d'espace convertible (le meme) }
Function GpiConvPSH(Hps : LongInt) : LongInt;
Begin
  If PsK(Hps) < 0 Then GpiConvPSH := 0 Else GpiConvPSH := Hps;
End;

{ ==================================================================== }
{ Points d'entree 16 bits, exportations, initialisation               }
{ ==================================================================== }

{ ordinaux bas (interface 16 bits) : memes fonctions }
Function W16_DevOpenDC(Hab, Typ, PTok, N, PDop, HComp : LongInt) : LongInt;
Begin
  W16_DevOpenDC := DevOpenDC(Hab, Typ, PTok, N, PDop, HComp);
End;

Function W16_DevCloseDC(H : LongInt) : LongInt;
Begin
  W16_DevCloseDC := DevCloseDC(H);
End;

Function W16_DevPostDeviceModes(Hab, PDriv, PDrv, PDev, PName, Fl : LongInt) : LongInt;
Begin
  W16_DevPostDeviceModes := DevPostDeviceModes(Hab, PDriv, PDrv, PDev, PName, Fl);
End;

Function W16_DevEscape(H, Code, NIn, PIn, PNOut, POut : LongInt) : LongInt;
Begin
  W16_DevEscape := DevEscape(H, Code, NIn, PIn, PNOut, POut);
End;

Function W16_DevQueryHardCopyCaps(H, St, N, P : LongInt) : LongInt;
Begin
  W16_DevQueryHardCopyCaps := DevQueryHardCopyCaps(H, St, N, P);
End;

Function W16_DevQueryCaps(H, St, N, P : LongInt) : LongInt;
Begin
  W16_DevQueryCaps := DevQueryCaps(H, St, N, P);
End;

Function W16_GpiCreatePS(Hab, Hdc, PSz, Fl : LongInt) : LongInt;
Begin
  W16_GpiCreatePS := GpiCreatePS(Hab, Hdc, PSz, Fl);
End;

Function W16_GpiQueryPS(Hps, PSz : LongInt) : LongInt;
Begin
  W16_GpiQueryPS := GpiQueryPS(Hps, PSz);
End;

Function W16_GpiDestroyPS(Hps : LongInt) : LongInt;
Begin
  W16_GpiDestroyPS := GpiDestroyPS(Hps);
End;

Function W16_GpiResetPS(Hps, Fl : LongInt) : LongInt;
Begin
  W16_GpiResetPS := GpiResetPS(Hps, Fl);
End;

Function W16_GpiSavePS(Hps : LongInt) : LongInt;
Begin
  W16_GpiSavePS := GpiSavePS(Hps);
End;

Function W16_GpiRestorePS(Hps, Id : LongInt) : LongInt;
Begin
  W16_GpiRestorePS := GpiRestorePS(Hps, Id);
End;

Function W16_GpiAssociate(Hps, Hdc : LongInt) : LongInt;
Begin
  W16_GpiAssociate := GpiAssociate(Hps, Hdc);
End;

Function W16_GpiErrorSegmentData(Hps, PSeg, PCtx : LongInt) : LongInt;
Begin
  W16_GpiErrorSegmentData := GpiErrorSegmentData(Hps, PSeg, PCtx);
End;

Function W16_GpiErase(Hps : LongInt) : LongInt;
Begin
  W16_GpiErase := GpiErase(Hps);
End;

Function W16_GpiSetDrawControl(Hps, C, V : LongInt) : LongInt;
Begin
  W16_GpiSetDrawControl := GpiSetDrawControl(Hps, C, V);
End;

Function W16_GpiQueryDrawControl(Hps, C : LongInt) : LongInt;
Begin
  W16_GpiQueryDrawControl := GpiQueryDrawControl(Hps, C);
End;

Function W16_GpiDrawChain(Hps : LongInt) : LongInt;
Begin
  W16_GpiDrawChain := GpiDrawChain(Hps);
End;

Function W16_GpiDrawFrom(Hps, First, Last : LongInt) : LongInt;
Begin
  W16_GpiDrawFrom := GpiDrawFrom(Hps, First, Last);
End;

Function W16_GpiDrawSegment(Hps, Id : LongInt) : LongInt;
Begin
  W16_GpiDrawSegment := GpiDrawSegment(Hps, Id);
End;

Function W16_GpiSetStopDraw(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetStopDraw := GpiSetStopDraw(Hps, V);
End;

Function W16_GpiQueryStopDraw(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryStopDraw := GpiQueryStopDraw(Hps);
End;

Function W16_GpiRemoveDynamics(Hps, First, Last : LongInt) : LongInt;
Begin
  W16_GpiRemoveDynamics := GpiRemoveDynamics(Hps, First, Last);
End;

Function W16_GpiDrawDynamics(Hps : LongInt) : LongInt;
Begin
  W16_GpiDrawDynamics := GpiDrawDynamics(Hps);
End;

Function W16_GpiSetDrawingMode(Hps, M : LongInt) : LongInt;
Begin
  W16_GpiSetDrawingMode := GpiSetDrawingMode(Hps, M);
End;

Function W16_GpiQueryDrawingMode(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryDrawingMode := GpiQueryDrawingMode(Hps);
End;

Function W16_GpiGetData(Hps, Id, POff, Fmt, Len, P : LongInt) : LongInt;
Begin
  W16_GpiGetData := GpiGetData(Hps, Id, POff, Fmt, Len, P);
End;

Function W16_GpiPutData(Hps, Fmt, PN, P : LongInt) : LongInt;
Begin
  W16_GpiPutData := GpiPutData(Hps, Fmt, PN, P);
End;

Function W16_GpiSetPickApertureSize(Hps, Opt, P : LongInt) : LongInt;
Begin
  W16_GpiSetPickApertureSize := GpiSetPickApertureSize(Hps, Opt, P);
End;

Function W16_GpiQueryPickApertureSize(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryPickApertureSize := GpiQueryPickApertureSize(Hps, P);
End;

Function W16_GpiSetPickAperturePosition(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetPickAperturePosition := GpiSetPickAperturePosition(Hps, P);
End;

Function W16_GpiQueryPickAperturePosition(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryPickAperturePosition := GpiQueryPickAperturePosition(Hps, P);
End;

Function W16_GpiSetTag(Hps, T : LongInt) : LongInt;
Begin
  W16_GpiSetTag := GpiSetTag(Hps, T);
End;

Function W16_GpiQueryTag(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryTag := GpiQueryTag(Hps, P);
End;

Function W16_GpiCorrelateChain(Hps, Typ, PPt, Max, Depth, P : LongInt) : LongInt;
Begin
  W16_GpiCorrelateChain := GpiCorrelateChain(Hps, Typ, PPt, Max, Depth, P);
End;

Function W16_GpiCorrelateFrom(Hps, First, Last, Typ, PPt, Max, Depth, P : LongInt) : LongInt;
Begin
  W16_GpiCorrelateFrom := GpiCorrelateFrom(Hps, First, Last, Typ, PPt, Max, Depth, P);
End;

Function W16_GpiCorrelateSegment(Hps, Id, Typ, PPt, Max, Depth, P : LongInt) : LongInt;
Begin
  W16_GpiCorrelateSegment := GpiCorrelateSegment(Hps, Id, Typ, PPt, Max, Depth, P);
End;

Function W16_GpiResetBoundaryData(Hps : LongInt) : LongInt;
Begin
  W16_GpiResetBoundaryData := GpiResetBoundaryData(Hps);
End;

Function W16_GpiQueryBoundaryData(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryBoundaryData := GpiQueryBoundaryData(Hps, P);
End;

Function W16_GpiOpenSegment(Hps, Id : LongInt) : LongInt;
Begin
  W16_GpiOpenSegment := GpiOpenSegment(Hps, Id);
End;

Function W16_GpiCloseSegment(Hps : LongInt) : LongInt;
Begin
  W16_GpiCloseSegment := GpiCloseSegment(Hps);
End;

Function W16_GpiDeleteSegment(Hps, Id : LongInt) : LongInt;
Begin
  W16_GpiDeleteSegment := GpiDeleteSegment(Hps, Id);
End;

Function W16_GpiDeleteSegments(Hps, First, Last : LongInt) : LongInt;
Begin
  W16_GpiDeleteSegments := GpiDeleteSegments(Hps, First, Last);
End;

Function W16_GpiQuerySegmentNames(Hps, First, Last, Max, P : LongInt) : LongInt;
Begin
  W16_GpiQuerySegmentNames := GpiQuerySegmentNames(Hps, First, Last, Max, P);
End;

Function W16_GpiSetInitialSegmentAttrs(Hps, A, V : LongInt) : LongInt;
Begin
  W16_GpiSetInitialSegmentAttrs := GpiSetInitialSegmentAttrs(Hps, A, V);
End;

Function W16_GpiQueryInitialSegmentAttrs(Hps, A : LongInt) : LongInt;
Begin
  W16_GpiQueryInitialSegmentAttrs := GpiQueryInitialSegmentAttrs(Hps, A);
End;

Function W16_GpiSetSegmentAttrs(Hps, Id, A, V : LongInt) : LongInt;
Begin
  W16_GpiSetSegmentAttrs := GpiSetSegmentAttrs(Hps, Id, A, V);
End;

Function W16_GpiQuerySegmentAttrs(Hps, Id, A : LongInt) : LongInt;
Begin
  W16_GpiQuerySegmentAttrs := GpiQuerySegmentAttrs(Hps, Id, A);
End;

Function W16_GpiSetSegmentPriority(Hps, Id, Ref, Ord1 : LongInt) : LongInt;
Begin
  W16_GpiSetSegmentPriority := GpiSetSegmentPriority(Hps, Id, Ref, Ord1);
End;

Function W16_GpiQuerySegmentPriority(Hps, Ref, Ord1 : LongInt) : LongInt;
Begin
  W16_GpiQuerySegmentPriority := GpiQuerySegmentPriority(Hps, Ref, Ord1);
End;

Function W16_GpiSetEditMode(Hps, M : LongInt) : LongInt;
Begin
  W16_GpiSetEditMode := GpiSetEditMode(Hps, M);
End;

Function W16_GpiQueryEditMode(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryEditMode := GpiQueryEditMode(Hps);
End;

Function W16_GpiSetElementPointer(Hps, N : LongInt) : LongInt;
Begin
  W16_GpiSetElementPointer := GpiSetElementPointer(Hps, N);
End;

Function W16_GpiQueryElementPointer(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryElementPointer := GpiQueryElementPointer(Hps);
End;

Function W16_GpiOffsetElementPointer(Hps, D : LongInt) : LongInt;
Begin
  W16_GpiOffsetElementPointer := GpiOffsetElementPointer(Hps, D);
End;

Function W16_GpiDeleteElement(Hps : LongInt) : LongInt;
Begin
  W16_GpiDeleteElement := GpiDeleteElement(Hps);
End;

Function W16_GpiDeleteElementRange(Hps, First, Last : LongInt) : LongInt;
Begin
  W16_GpiDeleteElementRange := GpiDeleteElementRange(Hps, First, Last);
End;

Function W16_GpiLabel(Hps, L : LongInt) : LongInt;
Begin
  W16_GpiLabel := GpiLabel(Hps, L);
End;

Function W16_GpiSetElementPointerAtLabel(Hps, L : LongInt) : LongInt;
Begin
  W16_GpiSetElementPointerAtLabel := GpiSetElementPointerAtLabel(Hps, L);
End;

Function W16_GpiDeleteElementsBetweenLabels(Hps, L1, L2 : LongInt) : LongInt;
Begin
  W16_GpiDeleteElementsBetweenLabels := GpiDeleteElementsBetweenLabels(Hps, L1, L2);
End;

Function W16_GpiQueryElementType(Hps, PT, Len, PD : LongInt) : LongInt;
Begin
  W16_GpiQueryElementType := GpiQueryElementType(Hps, PT, Len, PD);
End;

Function W16_GpiQueryElement(Hps, Off, Max, P : LongInt) : LongInt;
Begin
  W16_GpiQueryElement := GpiQueryElement(Hps, Off, Max, P);
End;

Function W16_GpiBeginElement(Hps, T, PDesc : LongInt) : LongInt;
Begin
  W16_GpiBeginElement := GpiBeginElement(Hps, T, PDesc);
End;

Function W16_GpiEndElement(Hps : LongInt) : LongInt;
Begin
  W16_GpiEndElement := GpiEndElement(Hps);
End;

Function W16_GpiSetSegmentTransformMatrix(Hps, Id, N, P, Opt : LongInt) : LongInt;
Begin
  W16_GpiSetSegmentTransformMatrix := GpiSetSegmentTransformMatrix(Hps, Id, N, P, Opt);
End;

Function W16_GpiQuerySegmentTransformMatrix(Hps, Id, N, P : LongInt) : LongInt;
Begin
  W16_GpiQuerySegmentTransformMatrix := GpiQuerySegmentTransformMatrix(Hps, Id, N, P);
End;

Function W16_GpiSetModelTransformMatrix(Hps, N, P, Opt : LongInt) : LongInt;
Begin
  W16_GpiSetModelTransformMatrix := GpiSetModelTransformMatrix(Hps, N, P, Opt);
End;

Function W16_GpiQueryModelTransformMatrix(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryModelTransformMatrix := GpiQueryModelTransformMatrix(Hps, N, P);
End;

Function W16_GpiCallSegmentMatrix(Hps, Id, N, P, Opt : LongInt) : LongInt;
Begin
  W16_GpiCallSegmentMatrix := GpiCallSegmentMatrix(Hps, Id, N, P, Opt);
End;

Function W16_GpiSetDefaultViewMatrix(Hps, N, P, Opt : LongInt) : LongInt;
Begin
  W16_GpiSetDefaultViewMatrix := GpiSetDefaultViewMatrix(Hps, N, P, Opt);
End;

Function W16_GpiQueryDefaultViewMatrix(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryDefaultViewMatrix := GpiQueryDefaultViewMatrix(Hps, N, P);
End;

Function W16_GpiSetPageViewport(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetPageViewport := GpiSetPageViewport(Hps, P);
End;

Function W16_GpiQueryPageViewport(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryPageViewport := GpiQueryPageViewport(Hps, P);
End;

Function W16_GpiSetViewingTransformMatrix(Hps, N, P, Opt : LongInt) : LongInt;
Begin
  W16_GpiSetViewingTransformMatrix := GpiSetViewingTransformMatrix(Hps, N, P, Opt);
End;

Function W16_GpiQueryViewingTransformMatrix(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryViewingTransformMatrix := GpiQueryViewingTransformMatrix(Hps, N, P);
End;

Function W16_GpiSetGraphicsField(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetGraphicsField := GpiSetGraphicsField(Hps, P);
End;

Function W16_GpiQueryGraphicsField(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryGraphicsField := GpiQueryGraphicsField(Hps, P);
End;

Function W16_GpiSetViewingLimits(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetViewingLimits := GpiSetViewingLimits(Hps, P);
End;

Function W16_GpiQueryViewingLimits(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryViewingLimits := GpiQueryViewingLimits(Hps, P);
End;

Function W16_GpiConvert(Hps, Src, Dst, N, P : LongInt) : LongInt;
Begin
  W16_GpiConvert := GpiConvert(Hps, Src, Dst, N, P);
End;

Function W16_GpiSetAttrMode(Hps, M : LongInt) : LongInt;
Begin
  W16_GpiSetAttrMode := GpiSetAttrMode(Hps, M);
End;

Function W16_GpiQueryAttrMode(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryAttrMode := GpiQueryAttrMode(Hps);
End;

Function W16_GpiPop(Hps, N : LongInt) : LongInt;
Begin
  W16_GpiPop := GpiPop(Hps, N);
End;

Function W16_GpiSetAttrs(Hps, Prim, Mask, DefMask, P : LongInt) : LongInt;
Begin
  W16_GpiSetAttrs := GpiSetAttrs(Hps, Prim, Mask, DefMask, P);
End;

Function W16_GpiQueryAttrs(Hps, Prim, Mask, P : LongInt) : LongInt;
Begin
  W16_GpiQueryAttrs := GpiQueryAttrs(Hps, Prim, Mask, P);
End;

Function W16_GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P : LongInt) : LongInt;
Begin
  W16_GpiCreateLogColorTable := GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P);
End;

Function W16_GpiQueryColorData(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryColorData := GpiQueryColorData(Hps, N, P);
End;

Function W16_GpiQueryLogColorTable(Hps, Opt, St, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryLogColorTable := GpiQueryLogColorTable(Hps, Opt, St, N, P);
End;

Function W16_GpiQueryRealColors(Hps, Opt, St, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryRealColors := GpiQueryRealColors(Hps, Opt, St, N, P);
End;

Function W16_GpiQueryNearestColor(Hps, Opt, Rgb : LongInt) : LongInt;
Begin
  W16_GpiQueryNearestColor := GpiQueryNearestColor(Hps, Opt, Rgb);
End;

Function W16_GpiQueryColorIndex(Hps, Opt, Rgb : LongInt) : LongInt;
Begin
  W16_GpiQueryColorIndex := GpiQueryColorIndex(Hps, Opt, Rgb);
End;

Function W16_GpiQueryRGBColor(Hps, Opt, C : LongInt) : LongInt;
Begin
  W16_GpiQueryRGBColor := GpiQueryRGBColor(Hps, Opt, C);
End;

Function W16_GpiSetColor(Hps, C : LongInt) : LongInt;
Begin
  W16_GpiSetColor := GpiSetColor(Hps, C);
End;

Function W16_GpiQueryColor(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryColor := GpiQueryColor(Hps);
End;

Function W16_GpiSetBackColor(Hps, C : LongInt) : LongInt;
Begin
  W16_GpiSetBackColor := GpiSetBackColor(Hps, C);
End;

Function W16_GpiQueryBackColor(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryBackColor := GpiQueryBackColor(Hps);
End;

Function W16_GpiSetMix(Hps, M : LongInt) : LongInt;
Begin
  W16_GpiSetMix := GpiSetMix(Hps, M);
End;

Function W16_GpiQueryMix(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryMix := GpiQueryMix(Hps);
End;

Function W16_GpiSetBackMix(Hps, M : LongInt) : LongInt;
Begin
  W16_GpiSetBackMix := GpiSetBackMix(Hps, M);
End;

Function W16_GpiQueryBackMix(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryBackMix := GpiQueryBackMix(Hps);
End;

Function W16_GpiSetLineType(Hps, T : LongInt) : LongInt;
Begin
  W16_GpiSetLineType := GpiSetLineType(Hps, T);
End;

Function W16_GpiQueryLineType(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryLineType := GpiQueryLineType(Hps);
End;

Function W16_GpiSetLineWidth(Hps, W : LongInt) : LongInt;
Begin
  W16_GpiSetLineWidth := GpiSetLineWidth(Hps, W);
End;

Function W16_GpiQueryLineWidth(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryLineWidth := GpiQueryLineWidth(Hps);
End;

Function W16_GpiSetLineWidthGeom(Hps, W : LongInt) : LongInt;
Begin
  W16_GpiSetLineWidthGeom := GpiSetLineWidthGeom(Hps, W);
End;

Function W16_GpiQueryLineWidthGeom(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryLineWidthGeom := GpiQueryLineWidthGeom(Hps);
End;

Function W16_GpiSetLineEnd(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetLineEnd := GpiSetLineEnd(Hps, V);
End;

Function W16_GpiQueryLineEnd(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryLineEnd := GpiQueryLineEnd(Hps);
End;

Function W16_GpiSetLineJoin(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetLineJoin := GpiSetLineJoin(Hps, V);
End;

Function W16_GpiQueryLineJoin(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryLineJoin := GpiQueryLineJoin(Hps);
End;

Function W16_GpiSetCurrentPosition(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetCurrentPosition := GpiSetCurrentPosition(Hps, P);
End;

Function W16_GpiQueryCurrentPosition(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryCurrentPosition := GpiQueryCurrentPosition(Hps, P);
End;

Function W16_GpiMove(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiMove := GpiMove(Hps, P);
End;

Function W16_GpiLine(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiLine := GpiLine(Hps, P);
End;

Function W16_GpiPolyLine(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiPolyLine := GpiPolyLine(Hps, N, P);
End;

Function W16_GpiBox(Hps, Ctl, P, HR, VR : LongInt) : LongInt;
Begin
  W16_GpiBox := GpiBox(Hps, Ctl, P, HR, VR);
End;

Function W16_GpiPtVisible(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiPtVisible := GpiPtVisible(Hps, P);
End;

Function W16_GpiRectVisible(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiRectVisible := GpiRectVisible(Hps, P);
End;

Function W16_GpiSetArcParams(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetArcParams := GpiSetArcParams(Hps, P);
End;

Function W16_GpiQueryArcParams(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryArcParams := GpiQueryArcParams(Hps, P);
End;

Function W16_GpiPointArc(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiPointArc := GpiPointArc(Hps, P);
End;

Function W16_GpiFullArc(Hps, Ctl, Mult : LongInt) : LongInt;
Begin
  W16_GpiFullArc := GpiFullArc(Hps, Ctl, Mult);
End;

Function W16_GpiPartialArc(Hps, PC, Mult, A0, Sw : LongInt) : LongInt;
Begin
  W16_GpiPartialArc := GpiPartialArc(Hps, PC, Mult, A0, Sw);
End;

Function W16_GpiPolyFillet(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiPolyFillet := GpiPolyFillet(Hps, N, P);
End;

Function W16_GpiPolyFilletSharp(Hps, N, P, PS : LongInt) : LongInt;
Begin
  W16_GpiPolyFilletSharp := GpiPolyFilletSharp(Hps, N, P, PS);
End;

Function W16_GpiPolySpline(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiPolySpline := GpiPolySpline(Hps, N, P);
End;

Function W16_GpiSetBitmapId(Hps, Hbm, Id : LongInt) : LongInt;
Begin
  W16_GpiSetBitmapId := GpiSetBitmapId(Hps, Hbm, Id);
End;

Function W16_GpiQueryBitmapHandle(Hps, Id : LongInt) : LongInt;
Begin
  W16_GpiQueryBitmapHandle := GpiQueryBitmapHandle(Hps, Id);
End;

Function W16_GpiSetPatternSet(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetPatternSet := GpiSetPatternSet(Hps, V);
End;

Function W162_GpiSetPatternSet(Hps, V : LongInt) : LongInt;
Begin
  W162_GpiSetPatternSet := GpiSetPatternSet(Hps, V);
End;

Function W16_GpiQueryPatternSet(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryPatternSet := GpiQueryPatternSet(Hps);
End;

Function W16_GpiQueryPattern(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryPattern := GpiQueryPattern(Hps);
End;

Function W16_GpiSetPatternRefPoint(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetPatternRefPoint := GpiSetPatternRefPoint(Hps, P);
End;

Function W16_GpiQueryPatternRefPoint(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryPatternRefPoint := GpiQueryPatternRefPoint(Hps, P);
End;

Function W16_GpiBeginArea(Hps, Fl : LongInt) : LongInt;
Begin
  W16_GpiBeginArea := GpiBeginArea(Hps, Fl);
End;

Function W16_GpiEndArea(Hps : LongInt) : LongInt;
Begin
  W16_GpiEndArea := GpiEndArea(Hps);
End;

Function W16_GpiLoadFonts(Hab, P : LongInt) : LongInt;
Begin
  W16_GpiLoadFonts := GpiLoadFonts(Hab, P);
End;

Function W16_GpiUnloadFonts(Hab, P : LongInt) : LongInt;
Begin
  W16_GpiUnloadFonts := GpiUnloadFonts(Hab, P);
End;

Function W16_GpiCreateLogFont(Hps, PName, Id, PF : LongInt) : LongInt;
Begin
  W16_GpiCreateLogFont := GpiCreateLogFont(Hps, PName, Id, PF);
End;

Function W16_GpiDeleteSetId(Hps, Id : LongInt) : LongInt;
Begin
  W16_GpiDeleteSetId := GpiDeleteSetId(Hps, Id);
End;

Function W16_GpiQueryNumberSetIds(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryNumberSetIds := GpiQueryNumberSetIds(Hps);
End;

Function W16_GpiQuerySetIds(Hps, N, PT, PN, PL : LongInt) : LongInt;
Begin
  W16_GpiQuerySetIds := GpiQuerySetIds(Hps, N, PT, PN, PL);
End;

Function W16_GpiQueryFonts(Hps, Opt, PFace, PReq, Len, P : LongInt) : LongInt;
Begin
  W16_GpiQueryFonts := GpiQueryFonts(Hps, Opt, PFace, PReq, Len, P);
End;

Function W16_GpiQueryFontMetrics(Hps, Len, P : LongInt) : LongInt;
Begin
  W16_GpiQueryFontMetrics := GpiQueryFontMetrics(Hps, Len, P);
End;

Function W16_GpiQueryKerningPairs(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryKerningPairs := GpiQueryKerningPairs(Hps, N, P);
End;

Function W16_GpiQueryWidthTable(Hps, First, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryWidthTable := GpiQueryWidthTable(Hps, First, N, P);
End;

Function W16_GpiSetCp(Hps, Cp : LongInt) : LongInt;
Begin
  W16_GpiSetCp := GpiSetCp(Hps, Cp);
End;

Function W16_GpiQueryCp(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryCp := GpiQueryCp(Hps);
End;

Function W16_GpiQueryTextBox(Hps, N, P, N2, PPt : LongInt) : LongInt;
Begin
  W16_GpiQueryTextBox := GpiQueryTextBox(Hps, N, P, N2, PPt);
End;

Function W16_DevQueryDeviceNames(Hab, PDrv, PN, PNames, PDesc, PNT, PTypes : LongInt) : LongInt;
Begin
  W16_DevQueryDeviceNames := DevQueryDeviceNames(Hab, PDrv, PN, PNames, PDesc, PNT, PTypes);
End;

Function W16_GpiQueryDefCharBox(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryDefCharBox := GpiQueryDefCharBox(Hps, P);
End;

Function W16_GpiQueryFontFileDescriptions(Hab, PF, PN, P : LongInt) : LongInt;
Begin
  W16_GpiQueryFontFileDescriptions := GpiQueryFontFileDescriptions(Hab, PF, PN, P);
End;

Function W16_GpiSetCharSet(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetCharSet := GpiSetCharSet(Hps, V);
End;

Function W16_GpiQueryCharSet(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryCharSet := GpiQueryCharSet(Hps);
End;

Function W16_GpiSetCharBox(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetCharBox := GpiSetCharBox(Hps, P);
End;

Function W16_GpiQueryCharBox(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryCharBox := GpiQueryCharBox(Hps, P);
End;

Function W16_GpiSetCharAngle(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetCharAngle := GpiSetCharAngle(Hps, P);
End;

Function W16_GpiQueryCharAngle(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryCharAngle := GpiQueryCharAngle(Hps, P);
End;

Function W16_GpiSetCharShear(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetCharShear := GpiSetCharShear(Hps, P);
End;

Function W16_GpiQueryCharShear(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryCharShear := GpiQueryCharShear(Hps, P);
End;

Function W16_GpiSetCharDirection(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetCharDirection := GpiSetCharDirection(Hps, V);
End;

Function W16_GpiQueryCharDirection(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryCharDirection := GpiQueryCharDirection(Hps);
End;

Function W16_GpiSetCharMode(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetCharMode := GpiSetCharMode(Hps, V);
End;

Function W16_GpiQueryCharMode(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryCharMode := GpiQueryCharMode(Hps);
End;

Function W16_GpiCharString(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiCharString := GpiCharString(Hps, N, P);
End;

Function W16_GpiCharStringAt(Hps, PPt, N, P : LongInt) : LongInt;
Begin
  W16_GpiCharStringAt := GpiCharStringAt(Hps, PPt, N, P);
End;

Function W16_GpiCharStringPos(Hps, PR, Fl, N, P, Adx : LongInt) : LongInt;
Begin
  W16_GpiCharStringPos := GpiCharStringPos(Hps, PR, Fl, N, P, Adx);
End;

Function W16_GpiCharStringPosAt(Hps, PPt, PR, Fl, N, P, Adx : LongInt) : LongInt;
Begin
  W16_GpiCharStringPosAt := GpiCharStringPosAt(Hps, PPt, PR, Fl, N, P, Adx);
End;

Function W16_GpiSetMarkerSet(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetMarkerSet := GpiSetMarkerSet(Hps, V);
End;

Function W16_GpiQueryMarkerSet(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryMarkerSet := GpiQueryMarkerSet(Hps);
End;

Function W16_GpiSetMarker(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetMarker := GpiSetMarker(Hps, V);
End;

Function W16_GpiQueryMarker(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryMarker := GpiQueryMarker(Hps);
End;

Function W16_GpiSetMarkerBox(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetMarkerBox := GpiSetMarkerBox(Hps, P);
End;

Function W16_GpiQueryMarkerBox(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryMarkerBox := GpiQueryMarkerBox(Hps, P);
End;

Function W16_GpiMarker(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiMarker := GpiMarker(Hps, P);
End;

Function W16_GpiPolyMarker(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiPolyMarker := GpiPolyMarker(Hps, N, P);
End;

Function W16_GpiImage(Hps, Fmt, PSz, Len, P : LongInt) : LongInt;
Begin
  W16_GpiImage := GpiImage(Hps, Fmt, PSz, Len, P);
End;

Function W16_GpiCreateBitmap(Hps, PHdr, Fl, PInit, Pbmi : LongInt) : LongInt;
Begin
  W16_GpiCreateBitmap := GpiCreateBitmap(Hps, PHdr, Fl, PInit, Pbmi);
End;

Function W16_GpiDeleteBitmap(H : LongInt) : LongInt;
Begin
  W16_GpiDeleteBitmap := GpiDeleteBitmap(H);
End;

Function W16_GpiSetBitmap(Hps, H : LongInt) : LongInt;
Begin
  W16_GpiSetBitmap := GpiSetBitmap(Hps, H);
End;

Function W16_GpiSetBitmapDimension(H, P : LongInt) : LongInt;
Begin
  W16_GpiSetBitmapDimension := GpiSetBitmapDimension(H, P);
End;

Function W16_GpiQueryBitmapDimension(H, P : LongInt) : LongInt;
Begin
  W16_GpiQueryBitmapDimension := GpiQueryBitmapDimension(H, P);
End;

Function W16_GpiQueryDeviceBitmapFormats(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryDeviceBitmapFormats := GpiQueryDeviceBitmapFormats(Hps, N, P);
End;

Function W16_GpiQueryBitmapParameters(H, P : LongInt) : LongInt;
Begin
  W16_GpiQueryBitmapParameters := GpiQueryBitmapParameters(H, P);
End;

Function W16_GpiSetBitmapBits(Hps, St, N, PBits, Pbmi : LongInt) : LongInt;
Begin
  W16_GpiSetBitmapBits := GpiSetBitmapBits(Hps, St, N, PBits, Pbmi);
End;

Function W16_GpiQueryBitmapBits(Hps, St, N, PBits, Pbmi : LongInt) : LongInt;
Begin
  W16_GpiQueryBitmapBits := GpiQueryBitmapBits(Hps, St, N, PBits, Pbmi);
End;

Function W16_GpiBitBlt(HT, HS, N, P, Rop, Fl : LongInt) : LongInt;
Begin
  W16_GpiBitBlt := GpiBitBlt(HT, HS, N, P, Rop, Fl);
End;

Function W16_GpiSetPel(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetPel := GpiSetPel(Hps, P);
End;

Function W16_GpiQueryPel(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryPel := GpiQueryPel(Hps, P);
End;

Function W16_GpiCreateRegion(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiCreateRegion := GpiCreateRegion(Hps, N, P);
End;

Function W16_GpiSetRegion(Hps, H, N, P : LongInt) : LongInt;
Begin
  W16_GpiSetRegion := GpiSetRegion(Hps, H, N, P);
End;

Function W16_GpiDestroyRegion(Hps, H : LongInt) : LongInt;
Begin
  W16_GpiDestroyRegion := GpiDestroyRegion(Hps, H);
End;

Function W16_GpiCombineRegion(Hps, HD, H1, H2, Mode : LongInt) : LongInt;
Begin
  W16_GpiCombineRegion := GpiCombineRegion(Hps, HD, H1, H2, Mode);
End;

Function W16_GpiEqualRegion(Hps, H1, H2 : LongInt) : LongInt;
Begin
  W16_GpiEqualRegion := GpiEqualRegion(Hps, H1, H2);
End;

Function W16_GpiOffsetRegion(Hps, H, P : LongInt) : LongInt;
Begin
  W16_GpiOffsetRegion := GpiOffsetRegion(Hps, H, P);
End;

Function W16_GpiPtInRegion(Hps, H, P : LongInt) : LongInt;
Begin
  W16_GpiPtInRegion := GpiPtInRegion(Hps, H, P);
End;

Function W16_GpiRectInRegion(Hps, H, P : LongInt) : LongInt;
Begin
  W16_GpiRectInRegion := GpiRectInRegion(Hps, H, P);
End;

Function W16_GpiQueryRegionBox(Hps, H, P : LongInt) : LongInt;
Begin
  W16_GpiQueryRegionBox := GpiQueryRegionBox(Hps, H, P);
End;

Function W16_GpiQueryRegionRects(Hps, H, PB, PC, PR : LongInt) : LongInt;
Begin
  W16_GpiQueryRegionRects := GpiQueryRegionRects(Hps, H, PB, PC, PR);
End;

Function W16_GpiSetClipRegion(Hps, H, POld : LongInt) : LongInt;
Begin
  W16_GpiSetClipRegion := GpiSetClipRegion(Hps, H, POld);
End;

Function W16_GpiQueryClipRegion(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryClipRegion := GpiQueryClipRegion(Hps);
End;

Function W16_GpiQueryClipBox(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryClipBox := GpiQueryClipBox(Hps, P);
End;

Function W16_GpiIntersectClipRectangle(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiIntersectClipRectangle := GpiIntersectClipRectangle(Hps, P);
End;

Function W16_GpiExcludeClipRectangle(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiExcludeClipRectangle := GpiExcludeClipRectangle(Hps, P);
End;

Function W16_GpiOffsetClipRegion(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiOffsetClipRegion := GpiOffsetClipRegion(Hps, P);
End;

Function W16_GpiPaintRegion(Hps, H : LongInt) : LongInt;
Begin
  W16_GpiPaintRegion := GpiPaintRegion(Hps, H);
End;

Function W16_GpiLoadMetaFile(Hab, PName : LongInt) : LongInt;
Begin
  W16_GpiLoadMetaFile := GpiLoadMetaFile(Hab, PName);
End;

Function W16_GpiCopyMetaFile(H : LongInt) : LongInt;
Begin
  W16_GpiCopyMetaFile := GpiCopyMetaFile(H);
End;

Function W16_GpiPlayMetaFile(Hps, Hm, N1, POpt, PSeg, N2, PDesc : LongInt) : LongInt;
Begin
  W16_GpiPlayMetaFile := GpiPlayMetaFile(Hps, Hm, N1, POpt, PSeg, N2, PDesc);
End;

Function W16_GpiSaveMetaFile(Hm, PName : LongInt) : LongInt;
Begin
  W16_GpiSaveMetaFile := GpiSaveMetaFile(Hm, PName);
End;

Function W16_GpiDeleteMetaFile(H : LongInt) : LongInt;
Begin
  W16_GpiDeleteMetaFile := GpiDeleteMetaFile(H);
End;

Function W16_GpiQueryMetaFileBits(H, Off, Len, P : LongInt) : LongInt;
Begin
  W16_GpiQueryMetaFileBits := GpiQueryMetaFileBits(H, Off, Len, P);
End;

Function W16_GpiSetMetaFileBits(H, Off, Len, P : LongInt) : LongInt;
Begin
  W16_GpiSetMetaFileBits := GpiSetMetaFileBits(H, Off, Len, P);
End;

Function W16_GpiQueryMetaFileLength(H : LongInt) : LongInt;
Begin
  W16_GpiQueryMetaFileLength := GpiQueryMetaFileLength(H);
End;

Function W16_GpiSetClipPath(Hps, Id, Fl : LongInt) : LongInt;
Begin
  W16_GpiSetClipPath := GpiSetClipPath(Hps, Id, Fl);
End;

Function W16_GpiBeginPath(Hps, Id : LongInt) : LongInt;
Begin
  W16_GpiBeginPath := GpiBeginPath(Hps, Id);
End;

Function W16_GpiEndPath(Hps : LongInt) : LongInt;
Begin
  W16_GpiEndPath := GpiEndPath(Hps);
End;

Function W16_GpiCloseFigure(Hps : LongInt) : LongInt;
Begin
  W16_GpiCloseFigure := GpiCloseFigure(Hps);
End;

Function W16_GpiModifyPath(Hps, Id, Mode : LongInt) : LongInt;
Begin
  W16_GpiModifyPath := GpiModifyPath(Hps, Id, Mode);
End;

Function W16_GpiFillPath(Hps, Id, Fl : LongInt) : LongInt;
Begin
  W16_GpiFillPath := GpiFillPath(Hps, Id, Fl);
End;

Function W16_GpiQueryDevice(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryDevice := GpiQueryDevice(Hps);
End;

Function W16_GpiQueryCharStringPos(Hps, Fl, N, P, Adx, PPos : LongInt) : LongInt;
Begin
  W16_GpiQueryCharStringPos := GpiQueryCharStringPos(Hps, Fl, N, P, Adx, PPos);
End;

Function W16_GpiQueryCharStringPosAt(Hps, PPt, Fl, N, P, Adx, PPos : LongInt) : LongInt;
Begin
  W16_GpiQueryCharStringPosAt := GpiQueryCharStringPosAt(Hps, PPt, Fl, N, P, Adx, PPos);
End;

Function W16_GpiSetPS(Hps, PSz, Fl : LongInt) : LongInt;
Begin
  W16_GpiSetPS := GpiSetPS(Hps, PSz, Fl);
End;

Function W16_GpiLoadPublicFonts(Hab, P : LongInt) : LongInt;
Begin
  W16_GpiLoadPublicFonts := GpiLoadPublicFonts(Hab, P);
End;

Function W16_GpiUnloadPublicFonts(Hab, P : LongInt) : LongInt;
Begin
  W16_GpiUnloadPublicFonts := GpiUnloadPublicFonts(Hab, P);
End;

Function W16_GpiComment(Hps, Len, P : LongInt) : LongInt;
Begin
  W16_GpiComment := GpiComment(Hps, Len, P);
End;

Function W16_GpiWCBitBlt(HT, Hbm, N, P, Rop, Fl : LongInt) : LongInt;
Begin
  W16_GpiWCBitBlt := GpiWCBitBlt(HT, Hbm, N, P, Rop, Fl);
End;

Function W16_GpiStrokePath(Hps, Id, Fl : LongInt) : LongInt;
Begin
  W16_GpiStrokePath := GpiStrokePath(Hps, Id, Fl);
End;

Function W16_GpiSuspendPlay(Hps : LongInt) : LongInt;
Begin
  W16_GpiSuspendPlay := GpiSuspendPlay(Hps);
End;

Function W16_GpiResumePlay(Hps : LongInt) : LongInt;
Begin
  W16_GpiResumePlay := GpiResumePlay(Hps);
End;

Function W16_GpiOutlinePath(Hps, Id, Fl : LongInt) : LongInt;
Begin
  W16_GpiOutlinePath := GpiOutlinePath(Hps, Id, Fl);
End;

Function W16_GpiSetDefTag(Hps, T : LongInt) : LongInt;
Begin
  W16_GpiSetDefTag := GpiSetDefTag(Hps, T);
End;

Function W16_GpiQueryDefTag(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryDefTag := GpiQueryDefTag(Hps, P);
End;

Function W16_GpiSetDefAttrs(Hps, Prim, Mask, P : LongInt) : LongInt;
Begin
  W16_GpiSetDefAttrs := GpiSetDefAttrs(Hps, Prim, Mask, P);
End;

Function W16_GpiQueryDefAttrs(Hps, Prim, Mask, P : LongInt) : LongInt;
Begin
  W16_GpiQueryDefAttrs := GpiQueryDefAttrs(Hps, Prim, Mask, P);
End;

Function W16_GpiSetDefViewingLimits(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetDefViewingLimits := GpiSetDefViewingLimits(Hps, P);
End;

Function W16_GpiQueryDefViewingLimits(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryDefViewingLimits := GpiQueryDefViewingLimits(Hps, P);
End;

Function W16_GpiSetDefArcParams(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiSetDefArcParams := GpiSetDefArcParams(Hps, P);
End;

Function W16_GpiQueryDefArcParams(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryDefArcParams := GpiQueryDefArcParams(Hps, P);
End;

Function W16_GpiTranslate(Hps, PM, Opt, P : LongInt) : LongInt;
Begin
  W16_GpiTranslate := GpiTranslate(Hps, PM, Opt, P);
End;

Function W16_GpiScale(Hps, PM, Opt, PS, PC : LongInt) : LongInt;
Begin
  W16_GpiScale := GpiScale(Hps, PM, Opt, PS, PC);
End;

Function W16_GpiRotate(Hps, PM, Opt, Ang, PC : LongInt) : LongInt;
Begin
  W16_GpiRotate := GpiRotate(Hps, PM, Opt, Ang, PC);
End;

Function W16_GpiPolyLineDisjoint(Hps, N, P : LongInt) : LongInt;
Begin
  W16_GpiPolyLineDisjoint := GpiPolyLineDisjoint(Hps, N, P);
End;

Function W16_GpiPathToRegion(Hps, Id, Fl : LongInt) : LongInt;
Begin
  W16_GpiPathToRegion := GpiPathToRegion(Hps, Id, Fl);
End;

Function W16_GpiFloodFill(Hps, Opt, C : LongInt) : LongInt;
Begin
  W16_GpiFloodFill := GpiFloodFill(Hps, Opt, C);
End;

Function W16_GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt;
Begin
  W16_GpiDrawBits := GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl);
End;

Function W16_GpiQueryBitmapInfoHeader(H, P : LongInt) : LongInt;
Begin
  W16_GpiQueryBitmapInfoHeader := GpiQueryBitmapInfoHeader(H, P);
End;

Function W16_GpiQueryLogicalFont(Hps, Id, PName, PF, Len : LongInt) : LongInt;
Begin
  W16_GpiQueryLogicalFont := GpiQueryLogicalFont(Hps, Id, PName, PF, Len);
End;

Function W16_GpiQueryFaceString(Hps, PFam, PAt, Len, POut : LongInt) : LongInt;
Begin
  W16_GpiQueryFaceString := GpiQueryFaceString(Hps, PFam, PAt, Len, POut);
End;

Function W16_GpiQueryFontAction(Hab, Opt : LongInt) : LongInt;
Begin
  W16_GpiQueryFontAction := GpiQueryFontAction(Hab, Opt);
End;

Function W16_GpiCreatePalette(Hab, Opt, Fmt, N, P : LongInt) : LongInt;
Begin
  W16_GpiCreatePalette := GpiCreatePalette(Hab, Opt, Fmt, N, P);
End;

Function W16_GpiDeletePalette(H : LongInt) : LongInt;
Begin
  W16_GpiDeletePalette := GpiDeletePalette(H);
End;

Function W16_GpiSelectPalette(Hps, H : LongInt) : LongInt;
Begin
  W16_GpiSelectPalette := GpiSelectPalette(Hps, H);
End;

Function W16_GpiAnimatePalette(H, Fmt, St, N, P : LongInt) : LongInt;
Begin
  W16_GpiAnimatePalette := GpiAnimatePalette(H, Fmt, St, N, P);
End;

Function W16_GpiSetPaletteEntries(H, Fmt, St, N, P : LongInt) : LongInt;
Begin
  W16_GpiSetPaletteEntries := GpiSetPaletteEntries(H, Fmt, St, N, P);
End;

Function W16_GpiQueryPalette(Hps : LongInt) : LongInt;
Begin
  W16_GpiQueryPalette := GpiQueryPalette(Hps);
End;

Function W16_GpiQueryPaletteInfo(H, Hps, Opt, St, N, P : LongInt) : LongInt;
Begin
  W16_GpiQueryPaletteInfo := GpiQueryPaletteInfo(H, Hps, Opt, St, N, P);
End;

Function W16_GpiQueryCharExtra(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryCharExtra := GpiQueryCharExtra(Hps, P);
End;

Function W16_GpiSetCharExtra(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetCharExtra := GpiSetCharExtra(Hps, V);
End;

Function W16_GpiQueryCharBreakExtra(Hps, P : LongInt) : LongInt;
Begin
  W16_GpiQueryCharBreakExtra := GpiQueryCharBreakExtra(Hps, P);
End;

Function W16_GpiSetCharBreakExtra(Hps, V : LongInt) : LongInt;
Begin
  W16_GpiSetCharBreakExtra := GpiSetCharBreakExtra(Hps, V);
End;

Function W16_GpiFrameRegion(Hps, H, PT : LongInt) : LongInt;
Begin
  W16_GpiFrameRegion := GpiFrameRegion(Hps, H, PT);
End;

Function W16_GpiConvertWithMatrix(Hps, N, P, NM, PM : LongInt) : LongInt;
Begin
  W16_GpiConvertWithMatrix := GpiConvertWithMatrix(Hps, N, P, NM, PM);
End;

Function W16_GpiSetDCOwner(H, Owner : LongInt) : LongInt;
Begin
  W16_GpiSetDCOwner := GpiSetDCOwner(H, Owner);
End;

Function W16_GpiSetBitmapOwner(Hps, H, Owner : LongInt) : LongInt;
Begin
  W16_GpiSetBitmapOwner := GpiSetBitmapOwner(Hps, H, Owner);
End;

Function W16_GpiSetRegionOwner(Hps, H, Owner : LongInt) : LongInt;
Begin
  W16_GpiSetRegionOwner := GpiSetRegionOwner(Hps, H, Owner);
End;

Function W16_GpiInstallIFIFont(Hab, PFile, PDir : LongInt) : LongInt;
Begin
  W16_GpiInstallIFIFont := GpiInstallIFIFont(Hab, PFile, PDir);
End;

Function W16_DspInitSystemDriverName(P, Cb : LongInt) : LongInt;
Begin
  W16_DspInitSystemDriverName := DspInitSystemDriverName(P, Cb);
End;

exports
  W16_DevOpenDC Index 1 Name 'DEVOPENDC',
  W16_DevCloseDC Index 2 Name 'DEVCLOSEDC',
  W16_DevPostDeviceModes Index 3 Name 'DEVPOSTDEVICEMODES',
  W16_DevEscape Index 4 Name 'DEVESCAPE',
  W16_DevQueryHardCopyCaps Index 5 Name 'DEVQUERYHARDCOPYCAPS',
  W16_DevQueryCaps Index 6 Name 'DEVQUERYCAPS',
  W16_GpiCreatePS Index 7 Name 'GPICREATEPS',
  W16_GpiQueryPS Index 9 Name 'GPIQUERYPS',
  W16_GpiDestroyPS Index 10 Name 'GPIDESTROYPS',
  W16_GpiResetPS Index 11 Name 'GPIRESETPS',
  W16_GpiSavePS Index 12 Name 'GPISAVEPS',
  W16_GpiRestorePS Index 13 Name 'GPIRESTOREPS',
  W16_GpiAssociate Index 14 Name 'GPIASSOCIATE',
  W16_GpiErrorSegmentData Index 15 Name 'GPIERRORSEGMENTDATA',
  W16_GpiErase Index 16 Name 'GPIERASE',
  W16_GpiSetDrawControl Index 17 Name 'GPISETDRAWCONTROL',
  W16_GpiQueryDrawControl Index 18 Name 'GPIQUERYDRAWCONTROL',
  W16_GpiDrawChain Index 19 Name 'GPIDRAWCHAIN',
  W16_GpiDrawFrom Index 20 Name 'GPIDRAWFROM',
  W16_GpiDrawSegment Index 21 Name 'GPIDRAWSEGMENT',
  W16_GpiSetStopDraw Index 22 Name 'GPISETSTOPDRAW',
  W16_GpiQueryStopDraw Index 23 Name 'GPIQUERYSTOPDRAW',
  W16_GpiRemoveDynamics Index 24 Name 'GPIREMOVEDYNAMICS',
  W16_GpiDrawDynamics Index 25 Name 'GPIDRAWDYNAMICS',
  W16_GpiSetDrawingMode Index 26 Name 'GPISETDRAWINGMODE',
  W16_GpiQueryDrawingMode Index 27 Name 'GPIQUERYDRAWINGMODE',
  W16_GpiGetData Index 28 Name 'GPIGETDATA',
  W16_GpiPutData Index 29 Name 'GPIPUTDATA',
  W16_GpiSetPickApertureSize Index 30 Name 'GPISETPICKAPERTURESIZE',
  W16_GpiQueryPickApertureSize Index 31 Name 'GPIQUERYPICKAPERTURESIZE',
  W16_GpiSetPickAperturePosition Index 32 Name 'GPISETPICKAPERTUREPOSITION',
  W16_GpiQueryPickAperturePosition Index 33 Name 'GPIQUERYPICKAPERTUREPOSITION',
  W16_GpiSetTag Index 34 Name 'GPISETTAG',
  W16_GpiQueryTag Index 35 Name 'GPIQUERYTAG',
  W16_GpiCorrelateChain Index 36 Name 'GPICORRELATECHAIN',
  W16_GpiCorrelateFrom Index 37 Name 'GPICORRELATEFROM',
  W16_GpiCorrelateSegment Index 38 Name 'GPICORRELATESEGMENT',
  W16_GpiResetBoundaryData Index 42 Name 'GPIRESETBOUNDARYDATA',
  W16_GpiQueryBoundaryData Index 43 Name 'GPIQUERYBOUNDARYDATA',
  W16_GpiOpenSegment Index 44 Name 'GPIOPENSEGMENT',
  W16_GpiCloseSegment Index 46 Name 'GPICLOSESEGMENT',
  W16_GpiDeleteSegment Index 47 Name 'GPIDELETESEGMENT',
  W16_GpiDeleteSegments Index 48 Name 'GPIDELETESEGMENTS',
  W16_GpiQuerySegmentNames Index 49 Name 'GPIQUERYSEGMENTNAMES',
  W16_GpiSetInitialSegmentAttrs Index 51 Name 'GPISETINITIALSEGMENTATTRS',
  W16_GpiQueryInitialSegmentAttrs Index 52 Name 'GPIQUERYINITIALSEGMENTATTRS',
  W16_GpiSetSegmentAttrs Index 53 Name 'GPISETSEGMENTATTRS',
  W16_GpiQuerySegmentAttrs Index 54 Name 'GPIQUERYSEGMENTATTRS',
  W16_GpiSetSegmentPriority Index 55 Name 'GPISETSEGMENTPRIORITY',
  W16_GpiQuerySegmentPriority Index 56 Name 'GPIQUERYSEGMENTPRIORITY',
  W16_GpiSetEditMode Index 57 Name 'GPISETEDITMODE',
  W16_GpiQueryEditMode Index 58 Name 'GPIQUERYEDITMODE',
  W16_GpiSetElementPointer Index 59 Name 'GPISETELEMENTPOINTER',
  W16_GpiQueryElementPointer Index 60 Name 'GPIQUERYELEMENTPOINTER',
  W16_GpiOffsetElementPointer Index 61 Name 'GPIOFFSETELEMENTPOINTER',
  W16_GpiDeleteElement Index 62 Name 'GPIDELETEELEMENT',
  W16_GpiDeleteElementRange Index 63 Name 'GPIDELETEELEMENTRANGE',
  W16_GpiLabel Index 64 Name 'GPILABEL',
  W16_GpiSetElementPointerAtLabel Index 65 Name 'GPISETELEMENTPOINTERATLABEL',
  W16_GpiDeleteElementsBetweenLabels Index 66 Name 'GPIDELETEELEMENTSBETWEENLABELS',
  W16_GpiQueryElementType Index 67 Name 'GPIQUERYELEMENTTYPE',
  W16_GpiQueryElement Index 68 Name 'GPIQUERYELEMENT',
  GpiElement Index 69 Name 'GpiElement',
  W16_GpiBeginElement Index 70 Name 'GPIBEGINELEMENT',
  W16_GpiEndElement Index 71 Name 'GPIENDELEMENT',
  W16_GpiSetSegmentTransformMatrix Index 78 Name 'GPISETSEGMENTTRANSFORMMATRIX',
  W16_GpiQuerySegmentTransformMatrix Index 79 Name 'GPIQUERYSEGMENTTRANSFORMMATRIX',
  W16_GpiSetModelTransformMatrix Index 80 Name 'GPISETMODELTRANSFORMMATRIX',
  W16_GpiQueryModelTransformMatrix Index 81 Name 'GPIQUERYMODELTRANSFORMMATRIX',
  W16_GpiCallSegmentMatrix Index 82 Name 'GPICALLSEGMENTMATRIX',
  W16_GpiSetDefaultViewMatrix Index 83 Name 'GPISETDEFAULTVIEWMATRIX',
  W16_GpiQueryDefaultViewMatrix Index 84 Name 'GPIQUERYDEFAULTVIEWMATRIX',
  W16_GpiSetPageViewport Index 85 Name 'GPISETPAGEVIEWPORT',
  W16_GpiQueryPageViewport Index 86 Name 'GPIQUERYPAGEVIEWPORT',
  W16_GpiSetViewingTransformMatrix Index 87 Name 'GPISETVIEWINGTRANSFORMMATRIX',
  W16_GpiQueryViewingTransformMatrix Index 88 Name 'GPIQUERYVIEWINGTRANSFORMMATRIX',
  W16_GpiSetGraphicsField Index 89 Name 'GPISETGRAPHICSFIELD',
  W16_GpiQueryGraphicsField Index 90 Name 'GPIQUERYGRAPHICSFIELD',
  W16_GpiSetViewingLimits Index 91 Name 'GPISETVIEWINGLIMITS',
  W16_GpiQueryViewingLimits Index 92 Name 'GPIQUERYVIEWINGLIMITS',
  W16_GpiConvert Index 93 Name 'GPICONVERT',
  W16_GpiSetAttrMode Index 94 Name 'GPISETATTRMODE',
  W16_GpiQueryAttrMode Index 95 Name 'GPIQUERYATTRMODE',
  W16_GpiPop Index 96 Name 'GPIPOP',
  W16_GpiSetAttrs Index 97 Name 'GPISETATTRS',
  W16_GpiQueryAttrs Index 98 Name 'GPIQUERYATTRS',
  W16_GpiCreateLogColorTable Index 99 Name 'GPICREATELOGCOLORTABLE',
  GpiRealizeColorTable Index 100 Name 'GpiRealizeColorTable',
  GpiUnrealizeColorTable Index 101 Name 'GpiUnrealizeColorTable',
  W16_GpiQueryColorData Index 102 Name 'GPIQUERYCOLORDATA',
  W16_GpiQueryLogColorTable Index 103 Name 'GPIQUERYLOGCOLORTABLE',
  W16_GpiQueryRealColors Index 104 Name 'GPIQUERYREALCOLORS',
  W16_GpiQueryNearestColor Index 105 Name 'GPIQUERYNEARESTCOLOR',
  W16_GpiQueryColorIndex Index 106 Name 'GPIQUERYCOLORINDEX',
  W16_GpiQueryRGBColor Index 107 Name 'GPIQUERYRGBCOLOR',
  W16_GpiSetColor Index 108 Name 'GPISETCOLOR',
  W16_GpiQueryColor Index 109 Name 'GPIQUERYCOLOR',
  W16_GpiSetBackColor Index 110 Name 'GPISETBACKCOLOR',
  W16_GpiQueryBackColor Index 111 Name 'GPIQUERYBACKCOLOR',
  W16_GpiSetMix Index 112 Name 'GPISETMIX',
  W16_GpiQueryMix Index 113 Name 'GPIQUERYMIX',
  W16_GpiSetBackMix Index 114 Name 'GPISETBACKMIX',
  W16_GpiQueryBackMix Index 115 Name 'GPIQUERYBACKMIX',
  W16_GpiSetLineType Index 116 Name 'GPISETLINETYPE',
  W16_GpiQueryLineType Index 117 Name 'GPIQUERYLINETYPE',
  W16_GpiSetLineWidth Index 118 Name 'GPISETLINEWIDTH',
  W16_GpiQueryLineWidth Index 119 Name 'GPIQUERYLINEWIDTH',
  W16_GpiSetLineWidthGeom Index 120 Name 'GPISETLINEWIDTHGEOM',
  W16_GpiQueryLineWidthGeom Index 121 Name 'GPIQUERYLINEWIDTHGEOM',
  W16_GpiSetLineEnd Index 122 Name 'GPISETLINEEND',
  W16_GpiQueryLineEnd Index 123 Name 'GPIQUERYLINEEND',
  W16_GpiSetLineJoin Index 124 Name 'GPISETLINEJOIN',
  W16_GpiQueryLineJoin Index 125 Name 'GPIQUERYLINEJOIN',
  W16_GpiSetCurrentPosition Index 126 Name 'GPISETCURRENTPOSITION',
  W16_GpiQueryCurrentPosition Index 127 Name 'GPIQUERYCURRENTPOSITION',
  W16_GpiMove Index 128 Name 'GPIMOVE',
  W16_GpiLine Index 129 Name 'GPILINE',
  W16_GpiPolyLine Index 130 Name 'GPIPOLYLINE',
  W16_GpiBox Index 131 Name 'GPIBOX',
  W16_GpiPtVisible Index 132 Name 'GPIPTVISIBLE',
  W16_GpiRectVisible Index 133 Name 'GPIRECTVISIBLE',
  W16_GpiSetArcParams Index 134 Name 'GPISETARCPARAMS',
  W16_GpiQueryArcParams Index 135 Name 'GPIQUERYARCPARAMS',
  W16_GpiPointArc Index 136 Name 'GPIPOINTARC',
  W16_GpiFullArc Index 137 Name 'GPIFULLARC',
  W16_GpiPartialArc Index 138 Name 'GPIPARTIALARC',
  W16_GpiPolyFillet Index 139 Name 'GPIPOLYFILLET',
  W16_GpiPolyFilletSharp Index 140 Name 'GPIPOLYFILLETSHARP',
  W16_GpiPolySpline Index 141 Name 'GPIPOLYSPLINE',
  W16_GpiSetBitmapId Index 142 Name 'GPISETBITMAPID',
  W16_GpiQueryBitmapHandle Index 143 Name 'GPIQUERYBITMAPHANDLE',
  W16_GpiSetPatternSet Index 144 Name 'GPISETPATTERNSET',
  W16_GpiQueryPatternSet Index 145 Name 'GPIQUERYPATTERNSET',
  GpiSetPattern Index 146 Name 'GpiSetPattern',
  W16_GpiQueryPattern Index 147 Name 'GPIQUERYPATTERN',
  W16_GpiSetPatternRefPoint Index 148 Name 'GPISETPATTERNREFPOINT',
  W16_GpiQueryPatternRefPoint Index 149 Name 'GPIQUERYPATTERNREFPOINT',
  W16_GpiBeginArea Index 150 Name 'GPIBEGINAREA',
  W16_GpiEndArea Index 151 Name 'GPIENDAREA',
  W16_GpiLoadFonts Index 152 Name 'GPILOADFONTS',
  W16_GpiUnloadFonts Index 153 Name 'GPIUNLOADFONTS',
  W16_GpiCreateLogFont Index 154 Name 'GPICREATELOGFONT',
  W16_GpiDeleteSetId Index 155 Name 'GPIDELETESETID',
  W16_GpiQueryNumberSetIds Index 156 Name 'GPIQUERYNUMBERSETIDS',
  W16_GpiQuerySetIds Index 157 Name 'GPIQUERYSETIDS',
  W16_GpiQueryFonts Index 158 Name 'GPIQUERYFONTS',
  W16_GpiQueryFontMetrics Index 159 Name 'GPIQUERYFONTMETRICS',
  W16_GpiQueryKerningPairs Index 160 Name 'GPIQUERYKERNINGPAIRS',
  W16_GpiQueryWidthTable Index 161 Name 'GPIQUERYWIDTHTABLE',
  W16_GpiSetCp Index 162 Name 'GPISETCP',
  W16_GpiQueryCp Index 163 Name 'GPIQUERYCP',
  W16_GpiQueryTextBox Index 164 Name 'GPIQUERYTEXTBOX',
  W16_DevQueryDeviceNames Index 165 Name 'DEVQUERYDEVICENAMES',
  W16_GpiQueryDefCharBox Index 166 Name 'GPIQUERYDEFCHARBOX',
  W16_GpiQueryFontFileDescriptions Index 167 Name 'GPIQUERYFONTFILEDESCRIPTIONS',
  W16_GpiSetCharSet Index 168 Name 'GPISETCHARSET',
  W16_GpiQueryCharSet Index 169 Name 'GPIQUERYCHARSET',
  W16_GpiSetCharBox Index 170 Name 'GPISETCHARBOX',
  W16_GpiQueryCharBox Index 171 Name 'GPIQUERYCHARBOX',
  W16_GpiSetCharAngle Index 172 Name 'GPISETCHARANGLE',
  W16_GpiQueryCharAngle Index 173 Name 'GPIQUERYCHARANGLE',
  W16_GpiSetCharShear Index 174 Name 'GPISETCHARSHEAR',
  W16_GpiQueryCharShear Index 175 Name 'GPIQUERYCHARSHEAR',
  W16_GpiSetCharDirection Index 176 Name 'GPISETCHARDIRECTION',
  W16_GpiQueryCharDirection Index 177 Name 'GPIQUERYCHARDIRECTION',
  W16_GpiSetCharMode Index 178 Name 'GPISETCHARMODE',
  W16_GpiQueryCharMode Index 179 Name 'GPIQUERYCHARMODE',
  W16_GpiCharString Index 180 Name 'GPICHARSTRING',
  W16_GpiCharStringAt Index 181 Name 'GPICHARSTRINGAT',
  W16_GpiCharStringPos Index 182 Name 'GPICHARSTRINGPOS',
  W16_GpiCharStringPosAt Index 183 Name 'GPICHARSTRINGPOSAT',
  W16_GpiSetMarkerSet Index 184 Name 'GPISETMARKERSET',
  W16_GpiQueryMarkerSet Index 185 Name 'GPIQUERYMARKERSET',
  W16_GpiSetMarker Index 186 Name 'GPISETMARKER',
  W16_GpiQueryMarker Index 187 Name 'GPIQUERYMARKER',
  W16_GpiSetMarkerBox Index 188 Name 'GPISETMARKERBOX',
  W16_GpiQueryMarkerBox Index 189 Name 'GPIQUERYMARKERBOX',
  W16_GpiMarker Index 190 Name 'GPIMARKER',
  W16_GpiPolyMarker Index 191 Name 'GPIPOLYMARKER',
  W16_GpiImage Index 192 Name 'GPIIMAGE',
  W16_GpiCreateBitmap Index 196 Name 'GPICREATEBITMAP',
  W16_GpiDeleteBitmap Index 197 Name 'GPIDELETEBITMAP',
  W16_GpiSetBitmap Index 198 Name 'GPISETBITMAP',
  W16_GpiSetBitmapDimension Index 199 Name 'GPISETBITMAPDIMENSION',
  W16_GpiQueryBitmapDimension Index 200 Name 'GPIQUERYBITMAPDIMENSION',
  W16_GpiQueryDeviceBitmapFormats Index 201 Name 'GPIQUERYDEVICEBITMAPFORMATS',
  W16_GpiQueryBitmapParameters Index 202 Name 'GPIQUERYBITMAPPARAMETERS',
  W16_GpiSetBitmapBits Index 203 Name 'GPISETBITMAPBITS',
  W16_GpiQueryBitmapBits Index 204 Name 'GPIQUERYBITMAPBITS',
  W16_GpiBitBlt Index 205 Name 'GPIBITBLT',
  W16_GpiSetPel Index 206 Name 'GPISETPEL',
  W16_GpiQueryPel Index 207 Name 'GPIQUERYPEL',
  W16_GpiCreateRegion Index 208 Name 'GPICREATEREGION',
  W16_GpiSetRegion Index 209 Name 'GPISETREGION',
  W16_GpiDestroyRegion Index 210 Name 'GPIDESTROYREGION',
  W16_GpiCombineRegion Index 211 Name 'GPICOMBINEREGION',
  W16_GpiEqualRegion Index 212 Name 'GPIEQUALREGION',
  W16_GpiOffsetRegion Index 213 Name 'GPIOFFSETREGION',
  W16_GpiPtInRegion Index 214 Name 'GPIPTINREGION',
  W16_GpiRectInRegion Index 215 Name 'GPIRECTINREGION',
  W16_GpiQueryRegionBox Index 216 Name 'GPIQUERYREGIONBOX',
  W16_GpiQueryRegionRects Index 217 Name 'GPIQUERYREGIONRECTS',
  W16_GpiSetClipRegion Index 218 Name 'GPISETCLIPREGION',
  W16_GpiQueryClipRegion Index 219 Name 'GPIQUERYCLIPREGION',
  W16_GpiQueryClipBox Index 220 Name 'GPIQUERYCLIPBOX',
  W16_GpiIntersectClipRectangle Index 221 Name 'GPIINTERSECTCLIPRECTANGLE',
  W16_GpiExcludeClipRectangle Index 222 Name 'GPIEXCLUDECLIPRECTANGLE',
  W16_GpiOffsetClipRegion Index 223 Name 'GPIOFFSETCLIPREGION',
  W16_GpiPaintRegion Index 224 Name 'GPIPAINTREGION',
  W16_GpiLoadMetaFile Index 225 Name 'GPILOADMETAFILE',
  W16_GpiCopyMetaFile Index 226 Name 'GPICOPYMETAFILE',
  W16_GpiPlayMetaFile Index 227 Name 'GPIPLAYMETAFILE',
  W16_GpiSaveMetaFile Index 228 Name 'GPISAVEMETAFILE',
  W16_GpiDeleteMetaFile Index 229 Name 'GPIDELETEMETAFILE',
  W16_GpiQueryMetaFileBits Index 230 Name 'GPIQUERYMETAFILEBITS',
  W16_GpiSetMetaFileBits Index 231 Name 'GPISETMETAFILEBITS',
  W16_GpiQueryMetaFileLength Index 232 Name 'GPIQUERYMETAFILELENGTH',
  W16_GpiSetClipPath Index 233 Name 'GPISETCLIPPATH',
  W16_GpiBeginPath Index 234 Name 'GPIBEGINPATH',
  W16_GpiEndPath Index 235 Name 'GPIENDPATH',
  W16_GpiCloseFigure Index 236 Name 'GPICLOSEFIGURE',
  W16_GpiModifyPath Index 237 Name 'GPIMODIFYPATH',
  W16_GpiFillPath Index 238 Name 'GPIFILLPATH',
  GpiStartRequest Index 239 Name 'GpiStartRequest',
  W16_GpiQueryDevice Index 240 Name 'GPIQUERYDEVICE',
  GpiVectorSymbol Index 241 Name 'GpiVectorSymbol',
  GpiOpenMetafile Index 242 Name 'GpiOpenMetafile',
  GpiCloseMetafile Index 243 Name 'GpiCloseMetafile',
  DevStdOpen Index 244 Name 'DevStdOpen',
  W16_GpiQueryCharStringPos Index 245 Name 'GPIQUERYCHARSTRINGPOS',
  W16_GpiQueryCharStringPosAt Index 246 Name 'GPIQUERYCHARSTRINGPOSAT',
  GpiConvPSH Index 247 Name 'GpiConvPSH',
  W16_GpiSetPS Index 248 Name 'GPISETPS',
  SegsGWOpenSegmentWindow Index 249 Name 'SegsGWOpenSegmentWindow',
  MtEndReadRequest Index 250 Name 'MtEndReadRequest',
  MtGetDescription Index 251 Name 'MtGetDescription',
  FmtOrderTable Index 252 Name 'FmtOrderTable',
  MtGetCodepage Index 253 Name 'MtGetCodepage',
  MtGetLCT Index 254 Name 'MtGetLCT',
  MtGetGDDInfo Index 255 Name 'MtGetGDDInfo',
  FmtConvertGocaPoly Index 256 Name 'FmtConvertGocaPoly',
  MtGetFirstFont Index 257 Name 'MtGetFirstFont',
  SegsGWNewPartData Index 258 Name 'SegsGWNewPartData',
  MtStartReadRequest Index 259 Name 'MtStartReadRequest',
  MtGetFirstGraphicsData Index 260 Name 'MtGetFirstGraphicsData',
  MtGetNextFont Index 261 Name 'MtGetNextFont',
  MtGetNextGraphicsData Index 262 Name 'MtGetNextGraphicsData',
  W16_GpiLoadPublicFonts Index 263 Name 'GPILOADPUBLICFONTS',
  W16_GpiUnloadPublicFonts Index 264 Name 'GPIUNLOADPUBLICFONTS',
  GpiAccessMetaFile Index 265 Name 'GpiAccessMetaFile',
  GpiMtAssociate Index 266 Name 'GpiMtAssociate',
  GpiMtDisassociate Index 267 Name 'GpiMtDisassociate',
  W16_GpiComment Index 268 Name 'GPICOMMENT',
  W16_GpiWCBitBlt Index 269 Name 'GPIWCBITBLT',
  W16_GpiStrokePath Index 270 Name 'GPISTROKEPATH',
  SegsGWNextOrderF Index 271 Name 'SegsGWNextOrderF',
  W16_GpiSuspendPlay Index 272 Name 'GPISUSPENDPLAY',
  W16_GpiResumePlay Index 273 Name 'GPIRESUMEPLAY',
  W16_GpiOutlinePath Index 274 Name 'GPIOUTLINEPATH',
  W16_GpiSetDefTag Index 275 Name 'GPISETDEFTAG',
  W16_GpiQueryDefTag Index 276 Name 'GPIQUERYDEFTAG',
  W16_GpiSetDefAttrs Index 277 Name 'GPISETDEFATTRS',
  W16_GpiQueryDefAttrs Index 278 Name 'GPIQUERYDEFATTRS',
  W16_GpiSetDefViewingLimits Index 279 Name 'GPISETDEFVIEWINGLIMITS',
  W16_GpiQueryDefViewingLimits Index 280 Name 'GPIQUERYDEFVIEWINGLIMITS',
  W16_GpiSetDefArcParams Index 281 Name 'GPISETDEFARCPARAMS',
  W16_GpiQueryDefArcParams Index 282 Name 'GPIQUERYDEFARCPARAMS',
  W16_GpiTranslate Index 283 Name 'GPITRANSLATE',
  W16_GpiScale Index 284 Name 'GPISCALE',
  W16_GpiRotate Index 285 Name 'GPIROTATE',
  W16_GpiPolyLineDisjoint Index 286 Name 'GPIPOLYLINEDISJOINT',
  W16_GpiPathToRegion Index 287 Name 'GPIPATHTOREGION',
  W16_GpiFloodFill Index 289 Name 'GPIFLOODFILL',
  W16_GpiDrawBits Index 290 Name 'GPIDRAWBITS',
  W16_GpiQueryBitmapInfoHeader Index 291 Name 'GPIQUERYBITMAPINFOHEADER',
  W16_GpiQueryLogicalFont Index 292 Name 'GPIQUERYLOGICALFONT',
  W16_GpiQueryFaceString Index 293 Name 'GPIQUERYFACESTRING',
  W16_GpiQueryFontAction Index 294 Name 'GPIQUERYFONTACTION',
  W16_GpiCreatePalette Index 295 Name 'GPICREATEPALETTE',
  W16_GpiDeletePalette Index 296 Name 'GPIDELETEPALETTE',
  W16_GpiSelectPalette Index 297 Name 'GPISELECTPALETTE',
  W16_GpiAnimatePalette Index 298 Name 'GPIANIMATEPALETTE',
  W16_GpiSetPaletteEntries Index 299 Name 'GPISETPALETTEENTRIES',
  W16_GpiQueryPalette Index 300 Name 'GPIQUERYPALETTE',
  W16_GpiQueryPaletteInfo Index 301 Name 'GPIQUERYPALETTEINFO',
  W16_GpiQueryCharExtra Index 302 Name 'GPIQUERYCHAREXTRA',
  W16_GpiSetCharExtra Index 303 Name 'GPISETCHAREXTRA',
  W16_GpiQueryCharBreakExtra Index 304 Name 'GPIQUERYCHARBREAKEXTRA',
  W16_GpiSetCharBreakExtra Index 305 Name 'GPISETCHARBREAKEXTRA',
  W16_GpiFrameRegion Index 306 Name 'GPIFRAMEREGION',
  W16_GpiConvertWithMatrix Index 307 Name 'GPICONVERTWITHMATRIX',
  W16_GpiSetDCOwner Index 308 Name 'GPISETDCOWNER',
  W16_GpiSetBitmapOwner Index 309 Name 'GPISETBITMAPOWNER',
  W16_GpiSetRegionOwner Index 310 Name 'GPISETREGIONOWNER',
  W16_GpiInstallIFIFont Index 311 Name 'GPIINSTALLIFIFONT',
  W16_DspInitSystemDriverName Index 312 Name 'DSPINITSYSTEMDRIVERNAME',
  GpiAssociate Index 351 Name 'GpiAssociate',
  GpiBeginArea Index 352 Name 'GpiBeginArea',
  GpiBeginElement Index 353 Name 'GpiBeginElement',
  GpiBeginPath Index 354 Name 'GpiBeginPath',
  GpiBitBlt Index 355 Name 'GpiBitBlt',
  GpiBox Index 356 Name 'GpiBox',
  GpiCallSegmentMatrix Index 357 Name 'GpiCallSegmentMatrix',
  GpiCharString Index 358 Name 'GpiCharString',
  GpiCharStringAt Index 359 Name 'GpiCharStringAt',
  GpiCloseFigure Index 360 Name 'GpiCloseFigure',
  GpiCloseSegment Index 361 Name 'GpiCloseSegment',
  GpiCombineRegion Index 362 Name 'GpiCombineRegion',
  GpiComment Index 363 Name 'GpiComment',
  GpiConvert Index 364 Name 'GpiConvert',
  GpiCopyMetaFile Index 365 Name 'GpiCopyMetaFile',
  GpiCorrelateChain Index 366 Name 'GpiCorrelateChain',
  GpiCorrelateFrom Index 367 Name 'GpiCorrelateFrom',
  GpiCreateLogFont Index 368 Name 'GpiCreateLogFont',
  GpiCreatePS Index 369 Name 'GpiCreatePS',
  GpiCreateRegion Index 370 Name 'GpiCreateRegion',
  GpiDeleteBitmap Index 371 Name 'GpiDeleteBitmap',
  GpiDeleteElement Index 372 Name 'GpiDeleteElement',
  GpiDeleteElementRange Index 373 Name 'GpiDeleteElementRange',
  GpiDeleteElementsBetweenLabels Index 374 Name 'GpiDeleteElementsBetweenLabels',
  GpiDeleteMetaFile Index 375 Name 'GpiDeleteMetaFile',
  GpiDeleteSegment Index 376 Name 'GpiDeleteSegment',
  GpiDeleteSegments Index 377 Name 'GpiDeleteSegments',
  GpiDeleteSetId Index 378 Name 'GpiDeleteSetId',
  GpiDestroyPS Index 379 Name 'GpiDestroyPS',
  GpiDrawChain Index 380 Name 'GpiDrawChain',
  GpiDrawDynamics Index 381 Name 'GpiDrawDynamics',
  GpiDrawFrom Index 382 Name 'GpiDrawFrom',
  GpiDrawSegment Index 383 Name 'GpiDrawSegment',
  GpiEndArea Index 385 Name 'GpiEndArea',
  GpiEndElement Index 386 Name 'GpiEndElement',
  GpiEndPath Index 387 Name 'GpiEndPath',
  GpiEqualRegion Index 388 Name 'GpiEqualRegion',
  GpiErase Index 389 Name 'GpiErase',
  GpiErrorSegmentData Index 390 Name 'GpiErrorSegmentData',
  GpiExcludeClipRectangle Index 391 Name 'GpiExcludeClipRectangle',
  GpiFillPath Index 392 Name 'GpiFillPath',
  GpiFullArc Index 393 Name 'GpiFullArc',
  GpiGetData Index 394 Name 'GpiGetData',
  GpiImage Index 395 Name 'GpiImage',
  GpiIntersectClipRectangle Index 396 Name 'GpiIntersectClipRectangle',
  GpiLabel Index 397 Name 'GpiLabel',
  GpiLine Index 398 Name 'GpiLine',
  GpiLoadBitmap Index 399 Name 'GpiLoadBitmap',
  GpiLoadFonts Index 400 Name 'GpiLoadFonts',
  GpiLoadMetaFile Index 401 Name 'GpiLoadMetaFile',
  GpiMarker Index 402 Name 'GpiMarker',
  GpiModifyPath Index 403 Name 'GpiModifyPath',
  GpiMove Index 404 Name 'GpiMove',
  GpiOffsetClipRegion Index 405 Name 'GpiOffsetClipRegion',
  GpiOffsetElementPointer Index 406 Name 'GpiOffsetElementPointer',
  GpiOffsetRegion Index 407 Name 'GpiOffsetRegion',
  GpiOpenSegment Index 408 Name 'GpiOpenSegment',
  GpiPaintRegion Index 409 Name 'GpiPaintRegion',
  GpiPlayMetaFile Index 411 Name 'GpiPlayMetaFile',
  GpiPointArc Index 412 Name 'GpiPointArc',
  GpiPolyFillet Index 413 Name 'GpiPolyFillet',
  GpiPolyFilletSharp Index 414 Name 'GpiPolyFilletSharp',
  GpiPolyLine Index 415 Name 'GpiPolyLine',
  GpiPolyMarker Index 416 Name 'GpiPolyMarker',
  GpiPolySpline Index 417 Name 'GpiPolySpline',
  GpiPop Index 418 Name 'GpiPop',
  GpiPtInRegion Index 419 Name 'GpiPtInRegion',
  GpiPtVisible Index 420 Name 'GpiPtVisible',
  GpiPutData Index 421 Name 'GpiPutData',
  GpiQueryArcParams Index 422 Name 'GpiQueryArcParams',
  GpiQueryAttrMode Index 423 Name 'GpiQueryAttrMode',
  GpiQueryBackColor Index 424 Name 'GpiQueryBackColor',
  GpiQueryBackMix Index 425 Name 'GpiQueryBackMix',
  GpiQueryBitmapDimension Index 426 Name 'GpiQueryBitmapDimension',
  GpiQueryBitmapHandle Index 427 Name 'GpiQueryBitmapHandle',
  GpiQueryBoundaryData Index 428 Name 'GpiQueryBoundaryData',
  GpiQueryCharAngle Index 429 Name 'GpiQueryCharAngle',
  GpiQueryCharBox Index 430 Name 'GpiQueryCharBox',
  GpiQueryCharDirection Index 431 Name 'GpiQueryCharDirection',
  GpiQueryCharMode Index 432 Name 'GpiQueryCharMode',
  GpiQueryCharSet Index 433 Name 'GpiQueryCharSet',
  GpiQueryCharShear Index 434 Name 'GpiQueryCharShear',
  GpiQueryClipBox Index 435 Name 'GpiQueryClipBox',
  GpiQueryClipRegion Index 436 Name 'GpiQueryClipRegion',
  GpiQueryColor Index 437 Name 'GpiQueryColor',
  GpiQueryColorData Index 438 Name 'GpiQueryColorData',
  GpiQueryColorIndex Index 439 Name 'GpiQueryColorIndex',
  GpiQueryCp Index 440 Name 'GpiQueryCp',
  GpiQueryCurrentPosition Index 441 Name 'GpiQueryCurrentPosition',
  GpiQueryDefCharBox Index 442 Name 'GpiQueryDefCharBox',
  GpiQueryDefaultViewMatrix Index 443 Name 'GpiQueryDefaultViewMatrix',
  GpiQueryDevice Index 444 Name 'GpiQueryDevice',
  GpiQueryDeviceBitmapFormats Index 445 Name 'GpiQueryDeviceBitmapFormats',
  GpiQueryDrawControl Index 446 Name 'GpiQueryDrawControl',
  GpiQueryDrawingMode Index 447 Name 'GpiQueryDrawingMode',
  GpiQueryEditMode Index 448 Name 'GpiQueryEditMode',
  GpiQueryElement Index 449 Name 'GpiQueryElement',
  GpiQueryElementPointer Index 450 Name 'GpiQueryElementPointer',
  GpiQueryElementType Index 451 Name 'GpiQueryElementType',
  GpiQueryFontFileDescriptions Index 452 Name 'GpiQueryFontFileDescriptions',
  GpiQueryFontMetrics Index 453 Name 'GpiQueryFontMetrics',
  GpiQueryGraphicsField Index 454 Name 'GpiQueryGraphicsField',
  GpiQueryInitialSegmentAttrs Index 455 Name 'GpiQueryInitialSegmentAttrs',
  GpiQueryKerningPairs Index 456 Name 'GpiQueryKerningPairs',
  GpiQueryLineEnd Index 457 Name 'GpiQueryLineEnd',
  GpiQueryLineJoin Index 458 Name 'GpiQueryLineJoin',
  GpiQueryLineType Index 459 Name 'GpiQueryLineType',
  GpiQueryLineWidth Index 460 Name 'GpiQueryLineWidth',
  GpiQueryLineWidthGeom Index 461 Name 'GpiQueryLineWidthGeom',
  GpiQueryMarker Index 462 Name 'GpiQueryMarker',
  GpiQueryMarkerBox Index 463 Name 'GpiQueryMarkerBox',
  GpiQueryMarkerSet Index 464 Name 'GpiQueryMarkerSet',
  GpiQueryMetaFileBits Index 465 Name 'GpiQueryMetaFileBits',
  GpiQueryMetaFileLength Index 466 Name 'GpiQueryMetaFileLength',
  GpiQueryMix Index 467 Name 'GpiQueryMix',
  GpiQueryModelTransformMatrix Index 468 Name 'GpiQueryModelTransformMatrix',
  GpiQueryNearestColor Index 469 Name 'GpiQueryNearestColor',
  GpiQueryNumberSetIds Index 470 Name 'GpiQueryNumberSetIds',
  GpiQueryPS Index 471 Name 'GpiQueryPS',
  GpiQueryPageViewport Index 472 Name 'GpiQueryPageViewport',
  GpiQueryPattern Index 473 Name 'GpiQueryPattern',
  GpiQueryPatternRefPoint Index 474 Name 'GpiQueryPatternRefPoint',
  GpiQueryPatternSet Index 475 Name 'GpiQueryPatternSet',
  GpiQueryPel Index 476 Name 'GpiQueryPel',
  GpiQueryPickAperturePosition Index 477 Name 'GpiQueryPickAperturePosition',
  GpiQueryPickApertureSize Index 478 Name 'GpiQueryPickApertureSize',
  GpiQueryRGBColor Index 479 Name 'GpiQueryRGBColor',
  GpiQueryRealColors Index 480 Name 'GpiQueryRealColors',
  GpiQueryRegionBox Index 481 Name 'GpiQueryRegionBox',
  GpiQuerySegmentAttrs Index 482 Name 'GpiQuerySegmentAttrs',
  GpiQuerySegmentNames Index 483 Name 'GpiQuerySegmentNames',
  GpiQuerySegmentPriority Index 484 Name 'GpiQuerySegmentPriority',
  GpiQuerySegmentTransformMatrix Index 485 Name 'GpiQuerySegmentTransformMatrix',
  GpiQuerySetIds Index 486 Name 'GpiQuerySetIds',
  GpiQueryStopDraw Index 487 Name 'GpiQueryStopDraw',
  GpiQueryTag Index 488 Name 'GpiQueryTag',
  GpiQueryTextBox Index 489 Name 'GpiQueryTextBox',
  GpiQueryViewingLimits Index 490 Name 'GpiQueryViewingLimits',
  GpiQueryViewingTransformMatrix Index 491 Name 'GpiQueryViewingTransformMatrix',
  GpiQueryWidthTable Index 492 Name 'GpiQueryWidthTable',
  GpiRectInRegion Index 494 Name 'GpiRectInRegion',
  GpiRectVisible Index 495 Name 'GpiRectVisible',
  GpiRemoveDynamics Index 496 Name 'GpiRemoveDynamics',
  GpiResetBoundaryData Index 497 Name 'GpiResetBoundaryData',
  GpiResetPS Index 498 Name 'GpiResetPS',
  GpiRestorePS Index 499 Name 'GpiRestorePS',
  GpiSaveMetaFile Index 500 Name 'GpiSaveMetaFile',
  GpiSavePS Index 501 Name 'GpiSavePS',
  GpiSetArcParams Index 502 Name 'GpiSetArcParams',
  GpiSetAttrMode Index 503 Name 'GpiSetAttrMode',
  GpiSetBackColor Index 504 Name 'GpiSetBackColor',
  GpiSetBackMix Index 505 Name 'GpiSetBackMix',
  GpiSetBitmap Index 506 Name 'GpiSetBitmap',
  GpiSetBitmapDimension Index 507 Name 'GpiSetBitmapDimension',
  GpiSetBitmapId Index 508 Name 'GpiSetBitmapId',
  GpiSetCharAngle Index 509 Name 'GpiSetCharAngle',
  GpiSetCharBox Index 510 Name 'GpiSetCharBox',
  GpiSetCharDirection Index 511 Name 'GpiSetCharDirection',
  GpiSetCharMode Index 512 Name 'GpiSetCharMode',
  GpiSetCharSet Index 513 Name 'GpiSetCharSet',
  GpiSetCharShear Index 514 Name 'GpiSetCharShear',
  GpiSetClipPath Index 515 Name 'GpiSetClipPath',
  GpiSetClipRegion Index 516 Name 'GpiSetClipRegion',
  GpiSetColor Index 517 Name 'GpiSetColor',
  GpiSetCp Index 518 Name 'GpiSetCp',
  GpiSetCurrentPosition Index 519 Name 'GpiSetCurrentPosition',
  GpiSetDefaultViewMatrix Index 520 Name 'GpiSetDefaultViewMatrix',
  GpiSetDrawControl Index 521 Name 'GpiSetDrawControl',
  GpiSetDrawingMode Index 522 Name 'GpiSetDrawingMode',
  GpiSetEditMode Index 523 Name 'GpiSetEditMode',
  GpiSetElementPointer Index 524 Name 'GpiSetElementPointer',
  GpiSetElementPointerAtLabel Index 525 Name 'GpiSetElementPointerAtLabel',
  GpiSetGraphicsField Index 526 Name 'GpiSetGraphicsField',
  GpiSetInitialSegmentAttrs Index 527 Name 'GpiSetInitialSegmentAttrs',
  GpiSetLineEnd Index 528 Name 'GpiSetLineEnd',
  GpiSetLineJoin Index 529 Name 'GpiSetLineJoin',
  GpiSetLineType Index 530 Name 'GpiSetLineType',
  GpiSetLineWidth Index 531 Name 'GpiSetLineWidth',
  GpiSetLineWidthGeom Index 532 Name 'GpiSetLineWidthGeom',
  GpiSetMarker Index 533 Name 'GpiSetMarker',
  GpiSetMarkerBox Index 534 Name 'GpiSetMarkerBox',
  GpiSetMarkerSet Index 535 Name 'GpiSetMarkerSet',
  GpiSetMetaFileBits Index 536 Name 'GpiSetMetaFileBits',
  GpiSetMix Index 537 Name 'GpiSetMix',
  GpiSetModelTransformMatrix Index 538 Name 'GpiSetModelTransformMatrix',
  GpiSetPS Index 539 Name 'GpiSetPS',
  GpiSetPageViewport Index 540 Name 'GpiSetPageViewport',
  W162_GpiSetPatternSet Index 541 Name 'GPISETPATTERNSET',
  GpiSetPatternRefPoint Index 542 Name 'GpiSetPatternRefPoint',
  GpiSetPatternSet Index 543 Name 'GpiSetPatternSet',
  GpiSetPel Index 544 Name 'GpiSetPel',
  GpiSetPickAperturePosition Index 545 Name 'GpiSetPickAperturePosition',
  GpiSetRegion Index 546 Name 'GpiSetRegion',
  GpiSetSegmentAttrs Index 547 Name 'GpiSetSegmentAttrs',
  GpiSetSegmentPriority Index 548 Name 'GpiSetSegmentPriority',
  GpiSetSegmentTransformMatrix Index 549 Name 'GpiSetSegmentTransformMatrix',
  GpiSetStopDraw Index 550 Name 'GpiSetStopDraw',
  GpiSetTag Index 551 Name 'GpiSetTag',
  GpiSetViewingLimits Index 552 Name 'GpiSetViewingLimits',
  GpiSetViewingTransformMatrix Index 553 Name 'GpiSetViewingTransformMatrix',
  GpiStrokePath Index 554 Name 'GpiStrokePath',
  GpiUnloadFonts Index 555 Name 'GpiUnloadFonts',
  GpiWCBitBlt Index 557 Name 'GpiWCBitBlt',
  GpiPolyLineDisjoint Index 558 Name 'GpiPolyLineDisjoint',
  GpiPathToRegion Index 559 Name 'GpiPathToRegion',
  GpiFloodFill Index 560 Name 'GpiFloodFill',
  GpiSuspendPlay Index 561 Name 'GpiSuspendPlay',
  GpiResumePlay Index 562 Name 'GpiResumePlay',
  GpiOutlinePath Index 563 Name 'GpiOutlinePath',
  GpiTranslate Index 564 Name 'GpiTranslate',
  GpiScale Index 565 Name 'GpiScale',
  GpiRotate Index 566 Name 'GpiRotate',
  GpiQueryDefArcParams Index 567 Name 'GpiQueryDefArcParams',
  GpiQueryDefTag Index 568 Name 'GpiQueryDefTag',
  GpiQueryDefViewingLimits Index 569 Name 'GpiQueryDefViewingLimits',
  GpiSetDefArcParams Index 570 Name 'GpiSetDefArcParams',
  GpiSetDefTag Index 571 Name 'GpiSetDefTag',
  GpiSetDefViewingLimits Index 572 Name 'GpiSetDefViewingLimits',
  GpiQueryBitmapParameters Index 573 Name 'GpiQueryBitmapParameters',
  GpiQueryLogicalFont Index 574 Name 'GpiQueryLogicalFont',
  GpiQueryFaceString Index 575 Name 'GpiQueryFaceString',
  GpiQueryFontAction Index 576 Name 'GpiQueryFontAction',
  GpiDeletePalette Index 577 Name 'GpiDeletePalette',
  GpiSelectPalette Index 578 Name 'GpiSelectPalette',
  GpiQueryPalette Index 579 Name 'GpiQueryPalette',
  GpiCharStringPos Index 580 Name 'GpiCharStringPos',
  GpiCharStringPosAt Index 581 Name 'GpiCharStringPosAt',
  GpiCorrelateSegment Index 582 Name 'GpiCorrelateSegment',
  GpiQueryAttrs Index 583 Name 'GpiQueryAttrs',
  GpiQueryCharStringPos Index 584 Name 'GpiQueryCharStringPos',
  GpiQueryCharStringPosAt Index 585 Name 'GpiQueryCharStringPosAt',
  GpiQueryFonts Index 586 Name 'GpiQueryFonts',
  GpiQueryRegionRects Index 587 Name 'GpiQueryRegionRects',
  GpiSetAttrs Index 588 Name 'GpiSetAttrs',
  GpiSetPickApertureSize Index 589 Name 'GpiSetPickApertureSize',
  GpiQueryDefAttrs Index 590 Name 'GpiQueryDefAttrs',
  GpiSetDefAttrs Index 591 Name 'GpiSetDefAttrs',
  GpiCreateLogColorTable Index 592 Name 'GpiCreateLogColorTable',
  GpiQueryLogColorTable Index 593 Name 'GpiQueryLogColorTable',
  GpiCreatePalette Index 594 Name 'GpiCreatePalette',
  GpiAnimatePalette Index 595 Name 'GpiAnimatePalette',
  GpiSetPaletteEntries Index 596 Name 'GpiSetPaletteEntries',
  GpiQueryPaletteInfo Index 597 Name 'GpiQueryPaletteInfo',
  GpiCreateBitmap Index 598 Name 'GpiCreateBitmap',
  GpiQueryBitmapBits Index 599 Name 'GpiQueryBitmapBits',
  GpiQueryBitmapInfoHeader Index 601 Name 'GpiQueryBitmapInfoHeader',
  GpiSetBitmapBits Index 602 Name 'GpiSetBitmapBits',
  GpiDrawBits Index 603 Name 'GpiDrawBits',
  DevCloseDC Index 604 Name 'DevCloseDC',
  DevEscape Index 605 Name 'DevEscape',
  DevQueryCaps Index 606 Name 'DevQueryCaps',
  DevQueryDeviceNames Index 607 Name 'DevQueryDeviceNames',
  DevQueryHardCopyCaps Index 608 Name 'DevQueryHardCopyCaps',
  DevPostDeviceModes Index 609 Name 'DevPostDeviceModes',
  DevOpenDC Index 610 Name 'DevOpenDC',
  GpiDestroyRegion Index 611 Name 'GpiDestroyRegion',
  GpiPartialArc Index 612 Name 'GpiPartialArc',
  GpiQueryCharExtra Index 613 Name 'GpiQueryCharExtra',
  GpiSetCharExtra Index 614 Name 'GpiSetCharExtra',
  GpiQueryCharBreakExtra Index 615 Name 'GpiQueryCharBreakExtra',
  GpiSetCharBreakExtra Index 616 Name 'GpiSetCharBreakExtra',
  GpiFrameRegion Index 617 Name 'GpiFrameRegion',
  GpiConvertWithMatrix Index 618 Name 'GpiConvertWithMatrix',
  GpiSetDCOwner Index 619 Name 'GpiSetDCOwner',
  GpiSetBitmapOwner Index 620 Name 'GpiSetBitmapOwner',
  GpiSetRegionOwner Index 621 Name 'GpiSetRegionOwner',
  GpiLoadPublicFonts Index 622 Name 'GpiLoadPublicFonts',
  GpiUnloadPublicFonts Index 623 Name 'GpiUnloadPublicFonts',
  GpiInstallIFIFont Index 624 Name 'GpiInstallIFIFont',
  GpiQueryTextAlignment Index 648 Name 'GpiQueryTextAlignment',
  GpiSetTextAlignment Index 649 Name 'GpiSetTextAlignment',
  GpiPolygons Index 650 Name 'GpiPolygons',
  DspDefaultResolution Index 654 Name 'DspDefaultResolution',
  DevQueryDisplayResolutions Index 655 Name 'DevQueryDisplayResolutions',
  DspInitSystemDriverName Index 656 Name 'DspInitSystemDriverName',
  GpiQueryFullFontFileDescs Index 657 Name 'GpiQueryFullFontFileDescs';

Var
  InitI : LongInt;
  InitF : Array[0..7] Of LongInt;

BEGIN
  WrL(LongInt(@Arena), ArenaSize);
  WrL(LongInt(@Arena) + 4, 0);
  { table logique par defaut (CLR_BACKGROUND 0 blanc ... CLR_PALEGRAY 15) }
  DefTab[0] := $FFFFFF; DefTab[1] := $0000FF; DefTab[2] := $FF0000; DefTab[3] := $FF00FF;
  DefTab[4] := $00FF00; DefTab[5] := $00FFFF; DefTab[6] := $FFFF00; DefTab[7] := $000000;
  DefTab[8] := $808080; DefTab[9] := $000080; DefTab[10] := $800000; DefTab[11] := $800080;
  DefTab[12] := $008000; DefTab[13] := $008080; DefTab[14] := $808000; DefTab[15] := $CCCCCC;
  { 16 couleurs du VGA }
  Vga16[0] := $000000; Vga16[1] := $0000AA; Vga16[2] := $00AA00; Vga16[3] := $00AAAA;
  Vga16[4] := $AA0000; Vga16[5] := $AA00AA; Vga16[6] := $AA5500; Vga16[7] := $AAAAAA;
  Vga16[8] := $555555; Vga16[9] := $5555FF; Vga16[10] := $55FF55; Vga16[11] := $55FFFF;
  Vga16[12] := $FF5555; Vga16[13] := $FF55FF; Vga16[14] := $FFFF55; Vga16[15] := $FFFFFF;
  { palette du mode 13h (celle de VIOCALLS) }
  For InitI := 0 To 15 Do Pal256[InitI] := Vga16[InitI];
  For InitI := 0 To 15 Do Pal256[16 + InitI] := ((InitI * 16 + 12) * $10101) And $FFFFFF;
  For InitI := 0 To 215 Do
    Pal256[32 + InitI] := (((InitI Div 36) * 12 + (InitI Div 36) Div 2) * 4 Shl 16) Or
                          ((((InitI Div 6) Mod 6) * 12 + ((InitI Div 6) Mod 6) Div 2) * 4 Shl 8) Or
                          (((InitI Mod 6) * 12 + (InitI Mod 6) Div 2) * 4);
  For InitI := 248 To 255 Do Pal256[InitI] := (((InitI - 248) * 8 + 7) * 4) * $10101;
  { police du VGA (VioGetFont, police d'origine) }
  For InitI := 0 To 7 Do InitF[InitI] := 0;
  WrW(LongInt(@InitF), 14); WrW(LongInt(@InitF) + 2, 1);
  FontOk := 0;
  If VioGetFont(LongInt(@InitF), 0) = 0 Then
    If (RdL(LongInt(@InitF) + 8) <> 0) And (RdW(LongInt(@InitF) + 6) > 0) Then
    Begin
      For InitI := 0 To 4095 Do
        If (InitI Mod 16) < RdW(LongInt(@InitF) + 6) Then
          FontBits[InitI] := RdB(RdL(LongInt(@InitF) + 8) + (InitI Div 16) * RdW(LongInt(@InitF) + 6) + InitI Mod 16)
        Else FontBits[InitI] := 0;
      FontOk := 1;
    End;
  CurK := -1; RMode := 0; Replaying := 0; ReplayDepth := 0;
  PmMod := 0; PmErrFn := 0; PmInfoFn := 0; PmFromDc := 0;
END.
