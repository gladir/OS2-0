{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/qchimie)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Clone de l'application ChemDraw, pour le Presentation
                Manager d'OS/2-0 (dossier Science) - editeur de structures
                chimiques 2D (molecules, reactions, fleches, formes) avec
                analyse (formule, masse, spectre de masse), import / export
                SMILES, MOL, SVG et BMP, prediction RMN et dictionnaire de noms.

  Ligne de commande :
    CHEMDRAW [fichier.CDT|.MOL|.SMI]

  Fonctionnalites :
    - Outils de liaisons (simple, double, triple, coin plein, coin hachure,
      gras, ondulee, pointillee), chaines, cycles (3 a 8, benzene, ...)
    - Etiquettes d'atomes, groupes (Me, Et, Ph, COOH, ...), charges, radicaux
    - Fleches de reaction, d'equilibre, de resonance, fleches courbes,
      crochets, formes, orbitales, textes
    - Selection (rectangle, lasso), deplacement, rotation, gomme, annuler
    - Analyse : formule, poids moleculaire, masse exacte, spectre de masse
    - Nettoyage automatique de la structure (mise en page 2D)
    - Stereochimie : descripteurs R/S (regles CIP) a partir des coins pleins
      et hachures, descripteurs E/Z, chiralite @ / @@ et / \ du SMILES
    - Menus deroulants adaptes de CLONEDRAW\PAINT.PAS

  Aucune dependance externe : tout le code est dans ce fichier.

  Portage vers OS/2-0 (OS2PC -COS2) de CHEMDRAW.PAS du depot QCHIMIE :
  tout l'editeur est conserve (outils, chimie, stereochimie, SMILES, MOL,
  InChI, SVG, BMP, RMN, spectre de masse, noms). Pour OS/2 : fenetre de
  Presentation Manager, barre de menus d'OS/2 construite a partir des
  neuf menus d'origine (coches et choix grises mis a jour a l'ouverture),
  dessin dans une image de 640 x 451 montree par GpiDrawBits (couche
  Graph, Crt et souris emulees sur la file de messages de PM ; la fenetre
  tient dans un ecran de 640 x 480), boites de dialogue dans le style
  d'OS/2, pointeur de la souris de PM.
}

Program CHEMDRAW;

{$IFDEF FPC}
 {$MODE TP}
 {$Q-}
 {$R-}
{$ELSE}
 {$M 40000,0,655360}
{$ENDIF}


{ --------------------------------------------------------------------- }
{ Constantes generales                                                  }
{ --------------------------------------------------------------------- }

Const
 PROG_TITLE      = 'ChemDraw Clone 1.00 - QChimie';
 PROG_VERSION    = '1.00';

 MENUBAR_H       = 20;
 TOOLBAR_H       = 24;
 STATUS_H        = 18;
 SCROLL_W        = 14;
 PAL_W           = 78;
 BTN_SZ          = 26;

 NUM_MENUS       = 9;
 MAX_MENU_ITEMS  = 26;
 MENU_FILE       = 0;
 MENU_EDIT       = 1;
 MENU_VIEW       = 2;
 MENU_OBJECT     = 3;
 MENU_STRUCT     = 4;
 MENU_COLOR      = 5;
 MENU_TEXT       = 6;
 MENU_TOOLS      = 7;
 MENU_HELP       = 8;

 BOND_LEN        = 28.0;      { longueur standard d'une liaison (px a 100%) }
 GRID_STEP       = 14.0;

 MAX_ATOMS       = 1000;
 MAX_BONDS       = 1100;
 MAX_TEXTS       = 100;
 MAX_SHAPES      = 200;
 MAX_RINGS       = 80;
 MAX_RING_SZ     = 40;
 UNDO_MAX        = 12;

 { Outils }
 T_SELECT   = 0;   T_LASSO    = 1;   T_HAND     = 2;
 T_ZOOM     = 3;   T_ERASER   = 4;   T_ROTATE   = 5;
 T_BOND     = 6;   T_DOUBLE   = 7;   T_TRIPLE   = 8;
 T_WEDGE    = 9;   T_HASH     = 10;  T_BOLD     = 11;
 T_WAVY     = 12;  T_DASH     = 13;  T_CHAIN    = 14;
 T_TEXT     = 15;  T_RING3    = 16;  T_RING4    = 17;
 T_RING5    = 18;  T_RING6    = 19;  T_RING7    = 20;
 T_RING8    = 21;  T_BENZENE  = 22;  T_CPD      = 23;
 T_ARROW    = 24;  T_EQUIL    = 25;  T_RESON    = 26;
 T_RETRO    = 27;  T_DASHARR  = 28;  T_CURVE2   = 29;
 T_CURVE1   = 30;  T_BRACKET  = 31;  T_LINE     = 32;
 T_RECT     = 33;  T_ELLIPSE  = 34;  T_PLUS     = 35;
 T_ORBS     = 36;  T_ORBP     = 37;  T_ATOM     = 38;
 NUM_TOOLS  = 39;

 { Styles de liaison }
 ST_NORMAL  = 0;  ST_WEDGE = 1;  ST_HASH = 2;  ST_BOLD = 3;
 ST_WAVY    = 4;  ST_DASH  = 5;

 { Types de formes }
 SH_LINE    = 1;  SH_ARROW   = 2;  SH_EQUIL   = 3;  SH_RESON  = 4;
 SH_RETRO   = 5;  SH_DASHARR = 6;  SH_CURVE2  = 7;  SH_CURVE1 = 8;
 SH_RECT    = 9;  SH_ELLIPSE = 10; SH_BRACKET = 11; SH_ORBS   = 12;
 SH_ORBP    = 13;

 { Modes de glissement }
 DR_NONE    = 0;  DR_MOVE   = 1;  DR_MARQUEE = 2;  DR_LASSO  = 3;
 DR_BOND    = 4;  DR_CHAIN  = 5;  DR_SHAPE   = 6;  DR_ROTATE = 7;
 DR_HAND    = 8;  DR_ERASE  = 9;  DR_SCROLLH = 10; DR_SCROLLV = 11;
 DR_HANDLE  = 12; DR_ZOOMBOX = 13;

{ --------------------------------------------------------------------- }
{ Types                                                                 }
{ --------------------------------------------------------------------- }

Type
 TAtom = Record
  X, Y : Real;
  Z    : Byte;             { numero atomique (0 = etiquette generique) }
  Chg  : ShortInt;         { charge formelle }
  Iso  : Integer;          { nombre de masse (0 = naturel) }
  Rad  : Byte;             { nombre d'electrons non apparies }
  Col  : Byte;             { couleur }
  Sel  : Boolean;
  Mark : Byte;             { bits temporaires : 1=ensemble, 2=place, 4=arom. }
  Lbl  : String[11];       { groupe (Me, Ph, COOH ...) ou etiquette }
 End;

 TBond = Record
  A, B  : Integer;
  Order : Byte;            { 1, 2, 3 (4 = aromatique temporaire) }
  Sty   : Byte;            { ST_xxx }
  DPos  : Byte;            { 0=auto 1=gauche 2=droite 3=centre }
  Col   : Byte;
 End;

 TText = Record
  X, Y : Real;
  Col  : Byte;
  Siz  : Byte;
  Sel  : Boolean;
  S    : String[70];
 End;

 TShape = Record
  Kind : Byte;
  X1, Y1, X2, Y2 : Real;
  CX, CY : Real;           { point de controle (courbes) }
  Col  : Byte;
  Sel  : Boolean;
 End;

 TAInfo = Record
  Deg   : Integer;
  BSum  : Integer;
  H     : Integer;
  SvX   : Real;            { somme des vecteurs unitaires vers les voisins }
  SvY   : Real;
  Warn  : Boolean;
 End;

 PAtomArr  = ^TAtomArr;
 TAtomArr  = Array[0..MAX_ATOMS-1] Of TAtom;
 PBondArr  = ^TBondArr;
 TBondArr  = Array[0..MAX_BONDS-1] Of TBond;
 PTextArr  = ^TTextArr;
 TTextArr  = Array[0..MAX_TEXTS-1] Of TText;
 PShapeArr = ^TShapeArr;
 TShapeArr = Array[0..MAX_SHAPES-1] Of TShape;
 PInfoArr  = ^TInfoArr;
 TInfoArr  = Array[0..MAX_ATOMS-1] Of TAInfo;

 TSnap = Record
  NA, NB, NT, NS : Integer;
  PA, PB, PT, PS : Pointer;
 End;

 TMenuItem = Record
  Caption   : String[34];
  Shortcut  : String[12];
  Enabled   : Boolean;
  Checked   : Boolean;
  Separator : Boolean;
 End;

 TMenu = Record
  Title     : String[16];
  Items     : Array[0..MAX_MENU_ITEMS-1] Of TMenuItem;
  ItemCount : Byte;
  X, Y, Width : Integer;
 End;

 TCounts = Array[0..103] Of LongInt;
 TStCArr = Array[0..MAX_ATOMS-1] Of Char;
 TEzCArr = Array[0..MAX_BONDS-1] Of Char;

{ --------------------------------------------------------------------- }
{ Variables globales                                                    }
{ --------------------------------------------------------------------- }

Var
 { Document }
 At  : PAtomArr;
 Bd  : PBondArr;
 Tx  : PTextArr;
 Sh  : PShapeArr;
 Inf : PInfoArr;
 NAt, NBd, NTx, NSh : Integer;
 DocVer      : LongInt;         { incremente a chaque modification }
 DocName     : String;
 Modified    : Boolean;

 { Anneaux (cache) }
 NRings      : Integer;
 RingN       : Array[0..MAX_RINGS-1] Of Integer;
 RingA       : Array[0..MAX_RINGS-1, 0..MAX_RING_SZ-1] Of Integer;
 RingVer     : LongInt;

 { Annuler / retablir }
 UndoStk     : Array[0..UNDO_MAX-1] Of TSnap;
 UndoN       : Integer;
 RedoStk     : Array[0..UNDO_MAX-1] Of TSnap;
 RedoN       : Integer;
 Pending     : TSnap;
 HasPending  : Boolean;
 Clip        : TSnap;
 ClipValid   : Boolean;
 ClipSmiles  : String;

 { Ecran }
 ScreenWidth, ScreenHeight : Integer;
 CvX1, CvY1, CvX2, CvY2    : Integer;   { zone du canevas }
 Zoom        : Real;
 ScrollX, ScrollY : Real;
 TxtScale    : Integer;

 { Etat des outils }
 CurTool     : Integer;
 CurElem     : Integer;
 CurColor    : Byte;
 TextSize    : Integer;
 OptGrid, OptSnap, OptFixAng, OptFixLen : Boolean;
 OptShowC, OptNumbers, OptWarn, OptAnalysis, OptColorEl : Boolean;
 OptDark : Boolean;
 OptStereo : Boolean;           { afficher les descripteurs R/S et E/Z }
 StC     : ^TStCArr;            { descripteur R/S par atome (#0 = aucun) }
 EzC     : ^TEzCArr;            { descripteur E/Z par liaison }
 StVer   : LongInt;
 StNA, StNB : Integer;

 { Menus }
 Menus       : Array[0..NUM_MENUS-1] Of TMenu;
 MenuBarHeight : Integer;
 MenuActive  : Boolean;
 ActiveMenu, ActiveMenuItem : Integer;

 { Souris }
 MouseX, MouseY, MouseButtons : Integer;
 OldMouseX, OldMouseY, OldMouseButtons : Integer;
 MouseAvailable : Boolean;
 DragKind    : Integer;
 DragSX, DragSY : Real;            { point de depart (doc) }
 DragLX, DragLY : Real;            { dernier point (doc) }
 DragAtom    : Integer;            { atome de depart (-1 aucun) }
 DragShape   : Integer;
 DragHandle  : Integer;
 DragPts     : Array[0..255] Of Integer;
 DragNPts    : Integer;
 DragMoved   : Boolean;
 DragEditing : Boolean;
 HovAtom, HovBond, HovShape, HovText : Integer;
 LastClickT  : LongInt;
 LastClickX, LastClickY : Integer;
 RotCX, RotCY, RotA0 : Real;

 { Boucle principale }
 Running     : Boolean;
 NeedRedraw  : Boolean;
 StatusMsg   : String;
 PropText    : Array[0..5] Of String;

{ --------------------------------------------------------------------- }
{ Tables d'elements                                                     }
{ --------------------------------------------------------------------- }

Const
 ElSym : Array[1..103] Of String[2] = (
  'H','He','Li','Be','B','C','N','O','F','Ne','Na','Mg','Al','Si','P','S',
  'Cl','Ar','K','Ca','Sc','Ti','V','Cr','Mn','Fe','Co','Ni','Cu','Zn','Ga',
  'Ge','As','Se','Br','Kr','Rb','Sr','Y','Zr','Nb','Mo','Tc','Ru','Rh','Pd',
  'Ag','Cd','In','Sn','Sb','Te','I','Xe','Cs','Ba','La','Ce','Pr','Nd','Pm',
  'Sm','Eu','Gd','Tb','Dy','Ho','Er','Tm','Yb','Lu','Hf','Ta','W','Re','Os',
  'Ir','Pt','Au','Hg','Tl','Pb','Bi','Po','At','Rn','Fr','Ra','Ac','Th','Pa',
  'U','Np','Pu','Am','Cm','Bk','Cf','Es','Fm','Md','No','Lr');

 ElWt : Array[1..103] Of Real = (
  1.008, 4.0026, 6.94, 9.0122, 10.81, 12.011, 14.007, 15.999, 18.998, 20.180,
  22.990, 24.305, 26.982, 28.085, 30.974, 32.06, 35.45, 39.948, 39.098, 40.078,
  44.956, 47.867, 50.942, 51.996, 54.938, 55.845, 58.933, 58.693, 63.546, 65.38,
  69.723, 72.630, 74.922, 78.971, 79.904, 83.798, 85.468, 87.62, 88.906, 91.224,
  92.906, 95.95, 98.0, 101.07, 102.906, 106.42, 107.868, 112.414, 114.818, 118.710,
  121.760, 127.60, 126.904, 131.293, 132.905, 137.327, 138.905, 140.116, 140.908,
  144.242, 145.0, 150.36, 151.964, 157.25, 158.925, 162.500, 164.930, 167.259,
  168.934, 173.045, 174.967, 178.49, 180.948, 183.84, 186.207, 190.23, 192.217,
  195.084, 196.967, 200.592, 204.38, 207.2, 208.980, 209.0, 210.0, 222.0, 223.0,
  226.0, 227.0, 232.038, 231.036, 238.029, 237.0, 244.0, 243.0, 247.0, 247.0,
  251.0, 252.0, 257.0, 258.0, 259.0, 262.0);

 ElName : Array[1..103] Of String[13] = (
  'Hydrogene','Helium','Lithium','Beryllium','Bore','Carbone','Azote','Oxygene',
  'Fluor','Neon','Sodium','Magnesium','Aluminium','Silicium','Phosphore','Soufre',
  'Chlore','Argon','Potassium','Calcium','Scandium','Titane','Vanadium','Chrome',
  'Manganese','Fer','Cobalt','Nickel','Cuivre','Zinc','Gallium','Germanium',
  'Arsenic','Selenium','Brome','Krypton','Rubidium','Strontium','Yttrium',
  'Zirconium','Niobium','Molybdene','Technetium','Ruthenium','Rhodium',
  'Palladium','Argent','Cadmium','Indium','Etain','Antimoine','Tellure','Iode',
  'Xenon','Cesium','Baryum','Lanthane','Cerium','Praseodyme','Neodyme',
  'Promethium','Samarium','Europium','Gadolinium','Terbium','Dysprosium',
  'Holmium','Erbium','Thulium','Ytterbium','Lutetium','Hafnium','Tantale',
  'Tungstene','Rhenium','Osmium','Iridium','Platine','Or','Mercure','Thallium',
  'Plomb','Bismuth','Polonium','Astate','Radon','Francium','Radium','Actinium',
  'Thorium','Protactinium','Uranium','Neptunium','Plutonium','Americium',
  'Curium','Berkelium','Californium','Einsteinium','Fermium','Mendelevium',
  'Nobelium','Lawrencium');

{ Palette de couleurs pour la bibliotheque de couleurs de menu }
 ColNames : Array[0..15] Of String[14] = (
  'Noir','Bleu','Vert','Cyan','Rouge','Magenta','Marron','Gris clair',
  'Gris fonce','Bleu clair','Vert clair','Cyan clair','Rouge clair',
  'Magenta clair','Jaune','Blanc');

{ --------------------------------------------------------------------- }
{ Utilitaires                                                           }
{ --------------------------------------------------------------------- }

Function IntToStr(N: LongInt): String;
Var S: String;
Begin
 Str(N, S);
 IntToStr := S;
End;

Function RealToStr(R: Real; Decim: Integer): String;
Var S: String;
Begin
 Str(R:0:Decim, S);
 RealToStr := S;
End;

Function UpCh(C: Char): Char;
Begin
 If (C >= 'a') And (C <= 'z') Then UpCh := Chr(Ord(C) - 32) Else UpCh := C;
End;

Function UpStr(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do R[I] := UpCh(R[I]);
 UpStr := R;
End;

Function TrimStr(Const S: String): String;
Var I, J: Integer;
Begin
 I := 1; J := Length(S);
 While (I <= J) And (S[I] <= ' ') Do Inc(I);
 While (J >= I) And (S[J] <= ' ') Do Dec(J);
 TrimStr := Copy(S, I, J - I + 1);
End;

Function MinI(A, B: Integer): Integer;
Begin If A < B Then MinI := A Else MinI := B; End;

Function MaxI(A, B: Integer): Integer;
Begin If A > B Then MaxI := A Else MaxI := B; End;

Function MinR(A, B: Real): Real;
Begin If A < B Then MinR := A Else MinR := B; End;

Function MaxR(A, B: Real): Real;
Begin If A > B Then MaxR := A Else MaxR := B; End;

Function AbsR(R: Real): Real;
Begin If R < 0 Then AbsR := -R Else AbsR := R; End;

Function SgnR(R: Real): Integer;
Begin
 If R > 0 Then SgnR := 1 Else If R < 0 Then SgnR := -1 Else SgnR := 0;
End;

Function ClampI(V, Lo, Hi: Integer): Integer;
Begin
 If V < Lo Then V := Lo;
 If V > Hi Then V := Hi;
 ClampI := V;
End;

Function ClampR(V, Lo, Hi: Real): Real;
Begin
 If V < Lo Then V := Lo;
 If V > Hi Then V := Hi;
 ClampR := V;
End;

Function Atan2(Y, X: Real): Real;
Var A: Real;
Begin
 If X = 0 Then Begin
  If Y > 0 Then Atan2 := Pi / 2
  Else If Y < 0 Then Atan2 := -Pi / 2
  Else Atan2 := 0;
 End
 Else Begin
  A := ArcTan(Y / X);
  If X < 0 Then Begin
   If Y >= 0 Then A := A + Pi Else A := A - Pi;
  End;
  Atan2 := A;
 End;
End;

Function Tan(X: Real): Real;
Begin
 Tan := Sin(X) / Cos(X);
End;

Function NormAng(A: Real): Real;
Begin
 While A > Pi Do A := A - 2 * Pi;
 While A <= -Pi Do A := A + 2 * Pi;
 NormAng := A;
End;

Function Dist(X1, Y1, X2, Y2: Real): Real;
Begin
 Dist := Sqrt((X2 - X1) * (X2 - X1) + (Y2 - Y1) * (Y2 - Y1));
End;

Function RoundI(R: Real): Integer;
Begin
 If R > 30000 Then R := 30000;
 If R < -30000 Then R := -30000;
 RoundI := Round(R);
End;

Function PadR(Const S: String; W: Integer): String;
Var R: String;
Begin
 R := S;
 While Length(R) < W Do R := R + ' ';
 PadR := R;
End;

Function PadL(Const S: String; W: Integer): String;
Var R: String;
Begin
 R := S;
 While Length(R) < W Do R := ' ' + R;
 PadL := R;
End;

Function StrToRealDef(Const S: String; Def: Real): Real;
Var R: Real; Code: Integer;
Begin
 Val(TrimStr(S), R, Code);
 If Code = 0 Then StrToRealDef := R Else StrToRealDef := Def;
End;

Function StrToIntDef(Const S: String; Def: LongInt): LongInt;
Var R: LongInt; Code: Integer;
Begin
 Val(TrimStr(S), R, Code);
 If Code = 0 Then StrToIntDef := R Else StrToIntDef := Def;
End;

Function PosI(Const Needle, S: String): Integer;
Begin
 PosI := Pos(UpStr(Needle), UpStr(S));
End;

Function ExtractExt(Const FN: String): String;
Var I: Integer;
Begin
 I := Length(FN);
 While (I > 0) And (FN[I] <> '.') And (FN[I] <> '\') And (FN[I] <> '/') Do Dec(I);
 If (I > 0) And (FN[I] = '.') Then ExtractExt := UpStr(Copy(FN, I, 255))
 Else ExtractExt := '';
End;

Function ChangeExt(Const FN, Ext: String): String;
Var I: Integer;
Begin
 I := Length(FN);
 While (I > 0) And (FN[I] <> '.') And (FN[I] <> '\') And (FN[I] <> '/') Do Dec(I);
 If (I > 0) And (FN[I] = '.') Then ChangeExt := Copy(FN, 1, I - 1) + Ext
 Else ChangeExt := FN + Ext;
End;

Function FileOK(Const FN: String): Boolean;
Var F: File;
Begin
 {$I-}
 Assign(F, FN);
 Reset(F, 1);
 {$I+}
 If IOResult = 0 Then Begin
  Close(F);
  FileOK := True;
 End
 Else FileOK := False;
End;

{ Symbole d'element -> numero atomique (0 si inconnu) }
Function ElemBySymbol(Const Sym: String): Integer;
Var I: Integer; S: String;
Begin
 ElemBySymbol := 0;
 S := TrimStr(Sym);
 If (Length(S) < 1) Or (Length(S) > 2) Then Exit;
 S[1] := UpCh(S[1]);
 If Length(S) = 2 Then Begin
  If (S[2] >= 'A') And (S[2] <= 'Z') Then S[2] := Chr(Ord(S[2]) + 32);
 End;
 For I := 1 To 103 Do
  If ElSym[I] = S Then Begin ElemBySymbol := I; Exit; End;
End;

{ Electrons de valence (groupe principal) }
Function ValElec(Z: Integer): Integer;
Begin
 Case Z Of
  1, 3, 11, 19, 37, 55, 87 : ValElec := 1;
  2, 4, 12, 20, 38, 56, 88 : ValElec := 2;
  5, 13, 31, 49, 81        : ValElec := 3;
  6, 14, 32, 50, 82        : ValElec := 4;
  7, 15, 33, 51, 83        : ValElec := 5;
  8, 16, 34, 52, 84        : ValElec := 6;
  9, 17, 35, 53, 85        : ValElec := 7;
  10, 18, 36, 54, 86       : ValElec := 8;
 Else ValElec := 2;
 End;
End;

{ Element de la serie "organique" pour lequel on calcule les H implicites }
Function IsOrganicEl(Z: Integer): Boolean;
Begin
 Case Z Of
  5, 6, 7, 8, 9, 14, 15, 16, 17, 32, 33, 34, 35, 50, 51, 52, 53 :
   IsOrganicEl := True;
 Else IsOrganicEl := False;
 End;
End;

{ Plus petite valence permise >= Sum (-1 si aucune) }
Function NextValence(Z, Chg, Sum: Integer): Integer;
Var G, V, I: Integer; L: Array[0..3] Of Integer; N: Integer; Hyper: Boolean;
Begin
 G := ValElec(Z) - Chg;
 Hyper := Z > 10;
 N := 1; L[0] := 0;
 Case G Of
  3 : Begin L[0] := 3; End;
  4 : Begin L[0] := 4; End;
  5 : Begin L[0] := 3; If Hyper Then Begin L[1] := 5; N := 2; End; End;
  6 : Begin L[0] := 2; If Hyper Then Begin L[1] := 4; L[2] := 6; N := 3; End; End;
  7 : Begin L[0] := 1; If Hyper Then Begin L[1] := 3; L[2] := 5; L[3] := 7; N := 4; End; End;
  8 : Begin L[0] := 0; End;
 Else
  If G <= 0 Then L[0] := 0 Else L[0] := G;
 End;
 NextValence := -1;
 For I := 0 To N - 1 Do Begin
  V := L[I];
  If V >= Sum Then Begin NextValence := V; Exit; End;
 End;
End;

Function MaxValence(Z, Chg: Integer): Integer;
Var V: Integer;
Begin
 V := NextValence(Z, Chg, 99);
 If V >= 0 Then MaxValence := V
 Else Begin
  V := 8;
  While (V > 0) And (NextValence(Z, Chg, V) < 0) Do Dec(V);
  MaxValence := NextValence(Z, Chg, V);
 End;
End;

{ Masse monoisotopique de l'isotope le plus abondant }
Function ElExact(Z: Integer): Real;
Begin
 Case Z Of
  1 : ElExact := 1.00782503;     2 : ElExact := 4.00260325;
  3 : ElExact := 7.0160040;      4 : ElExact := 9.0121822;
  5 : ElExact := 11.0093054;     6 : ElExact := 12.0;
  7 : ElExact := 14.0030740;     8 : ElExact := 15.9949146;
  9 : ElExact := 18.9984032;     10 : ElExact := 19.9924402;
  11 : ElExact := 22.9897693;    12 : ElExact := 23.9850417;
  13 : ElExact := 26.9815386;    14 : ElExact := 27.9769265;
  15 : ElExact := 30.9737620;    16 : ElExact := 31.9720707;
  17 : ElExact := 34.9688527;    18 : ElExact := 39.9623831;
  19 : ElExact := 38.9637065;    20 : ElExact := 39.9625912;
  22 : ElExact := 47.9479463;    23 : ElExact := 50.9439595;
  24 : ElExact := 51.9405075;    25 : ElExact := 54.9380451;
  26 : ElExact := 55.9349375;    27 : ElExact := 58.9331950;
  28 : ElExact := 57.9353429;    29 : ElExact := 62.9295975;
  30 : ElExact := 63.9291422;    31 : ElExact := 68.9255736;
  32 : ElExact := 73.9211778;    33 : ElExact := 74.9215965;
  34 : ElExact := 79.9165213;    35 : ElExact := 78.9183371;
  36 : ElExact := 83.911507;     37 : ElExact := 84.9117897;
  38 : ElExact := 87.9056121;    40 : ElExact := 89.9046977;
  42 : ElExact := 97.9054082;    46 : ElExact := 105.903486;
  47 : ElExact := 106.905097;    48 : ElExact := 113.9033585;
  50 : ElExact := 119.9021947;   51 : ElExact := 120.9038157;
  52 : ElExact := 129.9062244;   53 : ElExact := 126.904473;
  54 : ElExact := 131.9041535;   55 : ElExact := 132.905451;
  56 : ElExact := 137.905247;    74 : ElExact := 183.9509312;
  78 : ElExact := 194.964791;    79 : ElExact := 196.966552;
  80 : ElExact := 201.970643;    82 : ElExact := 207.9766521;
  83 : ElExact := 208.9803991;   92 : ElExact := 238.0507882;
 Else
  If (Z >= 1) And (Z <= 103) Then ElExact := Round(ElWt[Z]) Else ElExact := 0;
 End;
End;

{ Couleur d'affichage d'un element (mode "atomes en couleur") }
Function ElColor(Z: Integer): Byte;
Begin
 Case Z Of
  1  : ElColor := DarkGray;
  6  : ElColor := Black;
  7  : ElColor := Blue;
  8  : ElColor := Red;
  9, 17 : ElColor := Green;
  16 : ElColor := Brown;
  15 : ElColor := Magenta;
  35 : ElColor := Brown;
  53 : ElColor := Magenta;
  5  : ElColor := Brown;
  11, 19, 3 : ElColor := Magenta;
 Else ElColor := DarkGray;
 End;
End;

{ --------------------------------------------------------------------- }
{ Gestion de la souris                                                  }
{ --------------------------------------------------------------------- }

Const
 CanvasTop = MENUBAR_H;
 CanvasBot = MENUBAR_H + 430;

{ ================================================================== }
{ OS/2-0 : PRESENTATION MANAGER, GRAPH ET CRT EMULES                  }
{ ================================================================== }
{ La version DOS dessine avec l'unite Graph du BGI (640 x 480, 16     }
{ couleurs) et lit le clavier et la souris dans sa propre boucle.     }
{ Ici :                                                               }
{  - le dessin va dans une image en memoire de 640 x 480 (un octet    }
{    par point), montree dans la zone client d'une fenetre de PM par  }
{    GpiDrawBits (seules les zones modifiees sont recopiees) ;        }
{  - les lignes 0 a MENU_H - 1 de la version DOS (barre de menus      }
{    dessinee par le programme) sont remplacees par la barre de       }
{    titre et la barre de menus de PM, construites a partir des       }
{    tables de menus d'origine (dans la langue choisie) ;             }
{  - les routines de Graph utilisees (Line, Rectangle, Bar, Circle,   }
{    Arc, FillEllipse, PieSlice, PutPixel, OutTextXY agrandi par      }
{    SetTextStyle, styles de trait et de remplissage) sont ecrites    }
{    ici ;                                                            }
{  - la file de messages de PM (WinPeekMsg) est videe dans une file   }
{    d'evenements : touches (WM_CHAR, en codes du BIOS de la version  }
{    DOS), clics (WM_BUTTON1DOWN), commandes des menus (WM_COMMAND) ; }
{  - les messages et les questions passent par WinMessageBox.         }
{ Palette de l'image : couleurs 0 a 15 du BGI, puis 16 a 31 : memes   }
{ couleurs foncees, lisibles sur le fond blanc des pages de texte.    }

Const
 NormalPut = 0;
 ClipOn = True; ClipOff = False;
 WM_SIZE = $0007; WM_COMMAND = $0020; WM_SYSCOMMAND = $0021; WM_PAINT = $0023;
 WM_CLOSE = $0029; WM_MENUEND = $0035; WM_QUIT = $002A; WM_INITMENU = $0033; WM_MOUSEMOVE = $0070;
 WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
 WM_BUTTON2DOWN = $0074; WM_CHAR = $007A;
 FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100;
 FCF_TASKLIST = $800;
 HWND_DESKTOP = 1; HWND_TOP = 3;
 SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
 MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
 MIA_DISABLED = $4000; MM_SETITEMATTR = $0192;
 MB_OK = 0; MB_YESNO = 4; MB_ICONQUESTION = $10; MB_ICONEXCLAMATION = $20;
 MB_INFORMATION = $30; MB_MOVEABLE = $4000; MBID_YES = 6;
 KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SCANCODE = 4; KC_SHIFT = 8; KC_CTRL = $10;
 KC_ALT = $20; KC_KEYUP = $40;
 VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08;
 VK_ESC = $0F; VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14;
 VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_INSERT = $1A;
 VK_DELETE = $1B; VK_ENTER = $1E; VK_F1 = $20;
 SC_APPMENU = $8006; CMDSRC_ACCELERATOR = 3;
 PM_REMOVE = 1;
 FbW = 640; FbH = 480;
 EvQMax = 64;
 { evenements : 1 touche, 2 clic, 5 commande de menu (9999 = fermer) }
 EV_KEY = 1; EV_CLICK = 2; EV_CMD = 5; CMD_CLOSE = 9999;

Type
 PointType = Record
  X, Y : Integer;
 End;
 FillPatternType = Array[1..8] Of Byte;

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinPeekMsg(Hab, P, HF, First, Last, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSysClassProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WINSYSCLASSPROC';
Function WinSubclassWindow(H, Proc : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryCapture(HD : LongInt) : LongInt; External 'PMWIN';
Function WinQueryActiveWindow(HD : LongInt) : LongInt; External 'PMWIN';
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';

{ police 8 x 8 (256 caracteres, page de codes 437) : police du BGI }
Const
  Font8 : Array[0..2047] Of Byte = (
    $00,$00,$00,$00,$00,$00,$00,$00,$7E,$81,$A5,$81,$BD,$99,$81,$7E,
    $7E,$FF,$DB,$FF,$C3,$E7,$FF,$7E,$6C,$FE,$FE,$FE,$7C,$38,$10,$00,
    $10,$38,$7C,$FE,$7C,$38,$10,$00,$38,$7C,$38,$FE,$FE,$7C,$38,$7C,
    $10,$10,$38,$7C,$FE,$7C,$38,$7C,$00,$00,$18,$3C,$3C,$18,$00,$00,
    $FF,$FF,$E7,$C3,$C3,$E7,$FF,$FF,$00,$3C,$66,$42,$42,$66,$3C,$00,
    $FF,$C3,$99,$BD,$BD,$99,$C3,$FF,$0F,$07,$0F,$7D,$CC,$CC,$CC,$78,
    $3C,$66,$66,$66,$3C,$18,$7E,$18,$3F,$33,$3F,$30,$30,$70,$F0,$E0,
    $7F,$63,$7F,$63,$63,$67,$E6,$C0,$99,$5A,$3C,$E7,$E7,$3C,$5A,$99,
    $80,$E0,$F8,$FE,$F8,$E0,$80,$00,$02,$0E,$3E,$FE,$3E,$0E,$02,$00,
    $18,$3C,$7E,$18,$18,$7E,$3C,$18,$66,$66,$66,$66,$66,$00,$66,$00,
    $7F,$DB,$DB,$7B,$1B,$1B,$1B,$00,$3E,$63,$38,$6C,$6C,$38,$CC,$78,
    $00,$00,$00,$00,$7E,$7E,$7E,$00,$18,$3C,$7E,$18,$7E,$3C,$18,$FF,
    $18,$3C,$7E,$18,$18,$18,$18,$00,$18,$18,$18,$18,$7E,$3C,$18,$00,
    $00,$18,$0C,$FE,$0C,$18,$00,$00,$00,$30,$60,$FE,$60,$30,$00,$00,
    $00,$00,$C0,$C0,$C0,$FE,$00,$00,$00,$24,$66,$FF,$66,$24,$00,$00,
    $00,$18,$3C,$7E,$FF,$FF,$00,$00,$00,$FF,$FF,$7E,$3C,$18,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$30,$78,$78,$78,$30,$00,$30,$00,
    $6C,$6C,$6C,$00,$00,$00,$00,$00,$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00,
    $30,$7C,$C0,$78,$0C,$F8,$30,$00,$00,$C6,$CC,$18,$30,$66,$C6,$00,
    $38,$6C,$38,$76,$DC,$CC,$76,$00,$60,$60,$C0,$00,$00,$00,$00,$00,
    $18,$30,$60,$60,$60,$30,$18,$00,$60,$30,$18,$18,$18,$30,$60,$00,
    $00,$66,$3C,$FF,$3C,$66,$00,$00,$00,$30,$30,$FC,$30,$30,$00,$00,
    $00,$00,$00,$00,$00,$30,$30,$60,$00,$00,$00,$FC,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$30,$30,$00,$06,$0C,$18,$30,$60,$C0,$80,$00,
    $7C,$C6,$C6,$C6,$C6,$C6,$7C,$00,$30,$70,$30,$30,$30,$30,$FC,$00,
    $78,$CC,$0C,$38,$60,$CC,$FC,$00,$78,$CC,$0C,$38,$0C,$CC,$78,$00,
    $1C,$3C,$6C,$CC,$FE,$0C,$1E,$00,$FC,$C0,$F8,$0C,$0C,$CC,$78,$00,
    $38,$60,$C0,$F8,$CC,$CC,$78,$00,$FC,$CC,$0C,$18,$30,$30,$30,$00,
    $78,$CC,$CC,$78,$CC,$CC,$78,$00,$78,$CC,$CC,$7C,$0C,$18,$70,$00,
    $00,$30,$30,$00,$00,$30,$30,$00,$00,$30,$30,$00,$00,$30,$30,$60,
    $18,$30,$60,$C0,$60,$30,$18,$00,$00,$00,$FC,$00,$00,$FC,$00,$00,
    $60,$30,$18,$0C,$18,$30,$60,$00,$78,$CC,$0C,$18,$30,$00,$30,$00,
    $7C,$C6,$DE,$DE,$DE,$C0,$78,$00,$38,$6C,$C6,$C6,$FE,$C6,$C6,$00,
    $FC,$C6,$C6,$FC,$C6,$C6,$FC,$00,$7C,$C6,$C6,$C0,$C0,$C6,$7C,$00,
    $F8,$CC,$C6,$C6,$C6,$CC,$F8,$00,$FE,$C0,$C0,$FC,$C0,$C0,$FE,$00,
    $FE,$C0,$C0,$FC,$C0,$C0,$C0,$00,$7C,$C6,$C0,$CE,$C6,$C6,$7E,$00,
    $C6,$C6,$C6,$FE,$C6,$C6,$C6,$00,$78,$30,$30,$30,$30,$30,$78,$00,
    $1E,$06,$06,$06,$C6,$C6,$7C,$00,$C6,$CC,$D8,$F0,$D8,$CC,$C6,$00,
    $C0,$C0,$C0,$C0,$C0,$C0,$FE,$00,$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00,
    $C6,$E6,$F6,$DE,$CE,$C6,$C6,$00,$7C,$C6,$C6,$C6,$C6,$C6,$7C,$00,
    $FC,$C6,$C6,$FC,$C0,$C0,$C0,$00,$7C,$C6,$C6,$C6,$C6,$C6,$7C,$06,
    $FC,$C6,$C6,$FC,$C6,$C6,$C6,$00,$78,$CC,$60,$30,$18,$CC,$78,$00,
    $FC,$30,$30,$30,$30,$30,$30,$00,$C6,$C6,$C6,$C6,$C6,$C6,$7C,$00,
    $C6,$C6,$C6,$C6,$C6,$6C,$38,$00,$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00,
    $C6,$C6,$6C,$38,$6C,$C6,$C6,$00,$C3,$C3,$66,$3C,$18,$18,$18,$00,
    $FE,$0C,$18,$30,$60,$C0,$FE,$00,$3C,$30,$30,$30,$30,$30,$3C,$00,
    $C0,$60,$30,$18,$0C,$06,$03,$00,$3C,$0C,$0C,$0C,$0C,$0C,$3C,$00,
    $00,$38,$6C,$C6,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,
    $30,$30,$18,$00,$00,$00,$00,$00,$00,$00,$7C,$06,$7E,$C6,$7E,$00,
    $C0,$C0,$FC,$C6,$C6,$E6,$DC,$00,$00,$00,$7C,$C6,$C0,$C0,$7E,$00,
    $06,$06,$7E,$C6,$C6,$CE,$76,$00,$00,$00,$7C,$C6,$FE,$C0,$7E,$00,
    $1E,$30,$7C,$30,$30,$30,$30,$00,$00,$00,$7E,$C6,$CE,$76,$06,$7C,
    $C0,$C0,$FC,$C6,$C6,$C6,$C6,$00,$18,$00,$38,$18,$18,$18,$3C,$00,
    $18,$00,$38,$18,$18,$18,$18,$F0,$C0,$C0,$CC,$D8,$F0,$D8,$CC,$00,
    $38,$18,$18,$18,$18,$18,$3C,$00,$00,$00,$CC,$FE,$D6,$C6,$C6,$00,
    $00,$00,$FC,$C6,$C6,$C6,$C6,$00,$00,$00,$7C,$C6,$C6,$C6,$7C,$00,
    $00,$00,$FC,$C6,$C6,$E6,$DC,$C0,$00,$00,$7E,$C6,$C6,$CE,$76,$06,
    $00,$00,$6E,$70,$60,$60,$60,$00,$00,$00,$7C,$C0,$7C,$06,$FC,$00,
    $30,$30,$7C,$30,$30,$30,$1C,$00,$00,$00,$C6,$C6,$C6,$C6,$7E,$00,
    $00,$00,$C6,$C6,$C6,$6C,$38,$00,$00,$00,$C6,$C6,$D6,$FE,$6C,$00,
    $00,$00,$C6,$6C,$38,$6C,$C6,$00,$00,$00,$C6,$C6,$CE,$76,$06,$7C,
    $00,$00,$FC,$18,$30,$60,$FC,$00,$1C,$30,$30,$E0,$30,$30,$1C,$00,
    $18,$18,$18,$00,$18,$18,$18,$00,$E0,$30,$30,$1C,$30,$30,$E0,$00,
    $76,$DC,$00,$00,$00,$00,$00,$00,$00,$10,$38,$6C,$C6,$C6,$FE,$00,
    $78,$CC,$C0,$CC,$78,$18,$0C,$78,$00,$CC,$00,$CC,$CC,$CC,$7E,$00,
    $1C,$00,$78,$CC,$FC,$C0,$78,$00,$7E,$C3,$3C,$06,$3E,$66,$3F,$00,
    $CC,$00,$78,$0C,$7C,$CC,$7E,$00,$E0,$00,$78,$0C,$7C,$CC,$7E,$00,
    $30,$30,$78,$0C,$7C,$CC,$7E,$00,$00,$00,$78,$C0,$C0,$78,$0C,$38,
    $7E,$C3,$3C,$66,$7E,$60,$3C,$00,$CC,$00,$78,$CC,$FC,$C0,$78,$00,
    $E0,$00,$78,$CC,$FC,$C0,$78,$00,$CC,$00,$70,$30,$30,$30,$78,$00,
    $7C,$C6,$38,$18,$18,$18,$3C,$00,$E0,$00,$70,$30,$30,$30,$78,$00,
    $C6,$38,$6C,$C6,$FE,$C6,$C6,$00,$30,$30,$00,$78,$CC,$FC,$CC,$00,
    $1C,$00,$FC,$60,$78,$60,$FC,$00,$00,$00,$7F,$0C,$7F,$CC,$7F,$00,
    $3E,$6C,$CC,$FE,$CC,$CC,$CE,$00,$78,$CC,$00,$78,$CC,$CC,$78,$00,
    $00,$CC,$00,$78,$CC,$CC,$78,$00,$00,$E0,$00,$78,$CC,$CC,$78,$00,
    $78,$CC,$00,$CC,$CC,$CC,$7E,$00,$00,$E0,$00,$CC,$CC,$CC,$7E,$00,
    $00,$CC,$00,$CC,$CC,$7C,$0C,$F8,$C3,$18,$3C,$66,$66,$3C,$18,$00,
    $CC,$00,$CC,$CC,$CC,$CC,$78,$00,$18,$18,$7E,$C0,$C0,$7E,$18,$18,
    $38,$6C,$64,$F0,$60,$E6,$FC,$00,$CC,$CC,$78,$FC,$30,$FC,$30,$30,
    $F8,$CC,$CC,$FA,$C6,$CF,$C6,$C7,$0E,$1B,$18,$3C,$18,$18,$D8,$70,
    $1C,$00,$78,$0C,$7C,$CC,$7E,$00,$38,$00,$70,$30,$30,$30,$78,$00,
    $00,$1C,$00,$78,$CC,$CC,$78,$00,$00,$1C,$00,$CC,$CC,$CC,$7E,$00,
    $00,$F8,$00,$F8,$CC,$CC,$CC,$00,$FC,$00,$CC,$EC,$FC,$DC,$CC,$00,
    $3C,$6C,$6C,$3E,$00,$7E,$00,$00,$38,$6C,$6C,$38,$00,$7C,$00,$00,
    $30,$00,$30,$60,$C0,$CC,$78,$00,$00,$00,$00,$FC,$C0,$C0,$00,$00,
    $00,$00,$00,$FC,$0C,$0C,$00,$00,$C3,$C6,$CC,$DE,$33,$66,$CC,$0F,
    $C3,$C6,$CC,$DB,$37,$6F,$CF,$03,$18,$18,$00,$18,$18,$18,$18,$00,
    $00,$33,$66,$CC,$66,$33,$00,$00,$00,$CC,$66,$33,$66,$CC,$00,$00,
    $22,$88,$22,$88,$22,$88,$22,$88,$55,$AA,$55,$AA,$55,$AA,$55,$AA,
    $DB,$77,$DB,$EE,$DB,$77,$DB,$EE,$18,$18,$18,$18,$18,$18,$18,$18,
    $18,$18,$18,$18,$F8,$18,$18,$18,$18,$18,$F8,$18,$F8,$18,$18,$18,
    $36,$36,$36,$36,$F6,$36,$36,$36,$00,$00,$00,$00,$FE,$36,$36,$36,
    $00,$00,$F8,$18,$F8,$18,$18,$18,$36,$36,$F6,$06,$F6,$36,$36,$36,
    $36,$36,$36,$36,$36,$36,$36,$36,$00,$00,$FE,$06,$F6,$36,$36,$36,
    $36,$36,$F6,$06,$FE,$00,$00,$00,$36,$36,$36,$36,$FE,$00,$00,$00,
    $18,$18,$F8,$18,$F8,$00,$00,$00,$00,$00,$00,$00,$F8,$18,$18,$18,
    $18,$18,$18,$18,$1F,$00,$00,$00,$18,$18,$18,$18,$FF,$00,$00,$00,
    $00,$00,$00,$00,$FF,$18,$18,$18,$18,$18,$18,$18,$1F,$18,$18,$18,
    $00,$00,$00,$00,$FF,$00,$00,$00,$18,$18,$18,$18,$FF,$18,$18,$18,
    $18,$18,$1F,$18,$1F,$18,$18,$18,$36,$36,$36,$36,$37,$36,$36,$36,
    $36,$36,$37,$30,$3F,$00,$00,$00,$00,$00,$3F,$30,$37,$36,$36,$36,
    $36,$36,$F7,$00,$FF,$00,$00,$00,$00,$00,$FF,$00,$F7,$36,$36,$36,
    $36,$36,$37,$30,$37,$36,$36,$36,$00,$00,$FF,$00,$FF,$00,$00,$00,
    $36,$36,$F7,$00,$F7,$36,$36,$36,$18,$18,$FF,$00,$FF,$00,$00,$00,
    $36,$36,$36,$36,$FF,$00,$00,$00,$00,$00,$FF,$00,$FF,$18,$18,$18,
    $00,$00,$00,$00,$FF,$36,$36,$36,$36,$36,$36,$36,$3F,$00,$00,$00,
    $18,$18,$1F,$18,$1F,$00,$00,$00,$00,$00,$1F,$18,$1F,$18,$18,$18,
    $00,$00,$00,$00,$3F,$36,$36,$36,$36,$36,$36,$36,$FF,$36,$36,$36,
    $18,$18,$FF,$18,$FF,$18,$18,$18,$18,$18,$18,$18,$F8,$00,$00,$00,
    $00,$00,$00,$00,$1F,$18,$18,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
    $00,$00,$00,$00,$FF,$FF,$FF,$FF,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,
    $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$FF,$FF,$FF,$FF,$00,$00,$00,$00,
    $00,$00,$76,$DC,$C8,$DC,$76,$00,$00,$78,$CC,$F8,$CC,$F8,$C0,$C0,
    $00,$FC,$CC,$C0,$C0,$C0,$C0,$00,$00,$FE,$6C,$6C,$6C,$6C,$6C,$00,
    $FC,$CC,$60,$30,$60,$CC,$FC,$00,$00,$00,$7E,$D8,$D8,$D8,$70,$00,
    $00,$66,$66,$66,$66,$7C,$60,$C0,$00,$76,$DC,$18,$18,$18,$18,$00,
    $FC,$30,$78,$CC,$CC,$78,$30,$FC,$38,$6C,$C6,$FE,$C6,$6C,$38,$00,
    $38,$6C,$C6,$C6,$6C,$6C,$EE,$00,$1C,$30,$18,$7C,$CC,$CC,$78,$00,
    $00,$00,$7E,$DB,$DB,$7E,$00,$00,$06,$0C,$7E,$DB,$DB,$7E,$60,$C0,
    $38,$60,$C0,$F8,$C0,$60,$38,$00,$78,$CC,$CC,$CC,$CC,$CC,$CC,$00,
    $00,$FC,$00,$FC,$00,$FC,$00,$00,$30,$30,$FC,$30,$30,$00,$FC,$00,
    $60,$30,$18,$30,$60,$00,$FC,$00,$18,$30,$60,$30,$18,$00,$FC,$00,
    $0E,$1B,$1B,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$D8,$D8,$70,
    $30,$30,$00,$FC,$00,$30,$30,$00,$00,$76,$DC,$00,$76,$DC,$00,$00,
    $38,$6C,$6C,$38,$00,$00,$00,$00,$00,$00,$00,$18,$18,$00,$00,$00,
    $00,$00,$00,$00,$18,$00,$00,$00,$0F,$0C,$0C,$0C,$EC,$6C,$3C,$1C,
    $78,$6C,$6C,$6C,$6C,$00,$00,$00,$70,$18,$30,$60,$78,$00,$00,$00,
    $00,$00,$3C,$3C,$3C,$3C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);

Var
 OsHab, OsHmq, OsFrame, OsClient, Dummy, OsMenu : LongInt;
 Fb : Array[0..FbW * FbH - 1] Of Byte;     { image, lignes de bas en haut }
 Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;   { BITMAPINFO2 et palette }
 DirtyX1, DirtyY1, DirtyX2, DirtyY2 : LongInt;
 GColor, GBk, GFillStyle, GFillColor, GLineStyle, GThick, GWrite : LongInt;
 GLinePat, GTextSz, GJustH, GJustV : LongInt;
 EvMX, EvMY, EvMB : LongInt;
 EvKind, EvKey, EvX, EvY : Array[0..EvQMax - 1] Of LongInt;
 EvHead, EvTail : LongInt;
 NameZ, NameZ2 : Array[0..1023] Of Byte;
 TxtBuf : Array[0..4095] Of Byte;
 MenuT : Array[0..16383] Of Byte;
 MenuLen : LongInt;
 Qmsg : Array[0..7] Of LongInt;
 OsTitle : String;
 MnemoKeys : String;                         { lettres des titres de menus }
 PaperMode : Boolean;                        { page sur fond blanc }
 { fenetre de Graph (SetViewPort) : origine et rectangle de decoupe }
 VOX, VOY, ClipX1, ClipY1, ClipX2, ClipY2 : LongInt;
 GFillPat : Array[1..8] Of Byte;
 { Crt emule : touches (codes du BIOS), commandes des menus, souris }
 KeyQ : Array[0..127] Of LongInt;
 KeyH, KeyT, PendScan : LongInt;
 CmdQ : Array[0..31] Of LongInt;
 CmdH, CmdT : LongInt;
 MBtn, MLatch : LongInt;
 MenuUp, MenuStale, WasActive : LongInt;

{ --- utilitaires --- }

Procedure WrB(A, V : LongInt);
Type PByte1 = ^Byte;
Var Q : PByte1;
Begin
 Q := Pointer(A);
 Q^ := V;
End;

Procedure WrW(A, V : LongInt);
Begin
 WrB(A, V And 255);
 WrB(A + 1, (V Shr 8) And 255);
End;

Procedure WrL(A, V : LongInt);
Begin
 WrW(A, V And $FFFF);
 WrW(A + 2, (V Shr 16) And $FFFF);
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
 For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
 WrB(A + Length(S), 0);
End;

Function OsZ(S : String) : LongInt;
Begin
 PutZ(LongInt(@NameZ), S);
 OsZ := LongInt(@NameZ);
End;

Function OsZ2(S : String) : LongInt;
Begin
 PutZ(LongInt(@NameZ2), S);
 OsZ2 := LongInt(@NameZ2);
End;

Function Lo16(V : LongInt) : LongInt;
Begin
 Lo16 := V And $FFFF;
End;

Function Hi16(V : LongInt) : LongInt;
Begin
 Hi16 := (V Shr 16) And $FFFF;
End;

Function S16(V : LongInt) : LongInt;
Begin
 V := V And $FFFF;
 If V >= $8000 Then V := V - $10000;
 S16 := V;
End;

Function Min2(A, B : LongInt) : LongInt;
Begin
 If A < B Then Min2 := A Else Min2 := B;
End;

Function Max2(A, B : LongInt) : LongInt;
Begin
 If A > B Then Max2 := A Else Max2 := B;
End;

{ --- image et zones modifiees --- }

Procedure GTouch(X1, Y1, X2, Y2 : LongInt);
Begin
 If X1 < 0 Then X1 := 0;
 If Y1 < 0 Then Y1 := 0;
 If X2 > FbW - 1 Then X2 := FbW - 1;
 If Y2 > FbH - 1 Then Y2 := FbH - 1;
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 If DirtyX1 < 0 Then
 Begin
  DirtyX1 := X1; DirtyY1 := Y1; DirtyX2 := X2; DirtyY2 := Y2;
 End
 Else
 Begin
  If X1 < DirtyX1 Then DirtyX1 := X1;
  If Y1 < DirtyY1 Then DirtyY1 := Y1;
  If X2 > DirtyX2 Then DirtyX2 := X2;
  If Y2 > DirtyY2 Then DirtyY2 := Y2;
 End;
End;

Procedure Plot(X, Y, C : LongInt);
Var A : LongInt;
Begin
 If (X < ClipX1) Or (Y < ClipY1) Or (X > ClipX2) Or (Y > ClipY2) Then Exit;
 A := (FbH - 1 - Y) * FbW + X;
 If GWrite = XORPut Then Fb[A] := (Fb[A] Xor C) And 255 Else Fb[A] := C And 255;
End;

Procedure HSpan(X1, X2, Y, C : LongInt);
Var A, X : LongInt;
Begin
 If (Y < ClipY1) Or (Y > ClipY2) Then Exit;
 If X1 < ClipX1 Then X1 := ClipX1;
 If X2 > ClipX2 Then X2 := ClipX2;
 If X2 < X1 Then Exit;
 A := (FbH - 1 - Y) * FbW;
 If GWrite = XORPut Then
  For X := X1 To X2 Do Fb[A + X] := (Fb[A + X] Xor C) And 255
 Else
  For X := X1 To X2 Do Fb[A + X] := C And 255;
End;

{ motif de remplissage : bit du point (X, Y) }
Function FillBit(X, Y : LongInt) : Boolean;
Var B : LongInt;
Begin
 Case GFillStyle Of
  EmptyFill : B := 0;
  SolidFill : B := $FF;
  LineFill : If (Y And 7) < 2 Then B := $FF Else B := 0;
  LtSlashFill, SlashFill : B := $80 Shr ((X + Y) And 7);
  BkSlashFill, LtBkSlashFill : B := $01 Shl ((X + Y) And 7);
  HatchFill : If (Y And 7) = 0 Then B := $FF Else B := $80;
  XHatchFill : B := ($80 Shr ((X + Y) And 7)) Or ($01 Shl ((X + Y) And 7));
  InterleaveFill : If (Y And 1) = 0 Then B := $CC Else B := $33;
  WideDotFill : If (Y And 7) = 0 Then B := $80 Else B := 0;
  CloseDotFill : If (Y And 1) = 0 Then B := $88 Else B := 0;
  UserFill : B := GFillPat[(Y And 7) + 1];
 Else
  B := $FF;
 End;
 FillBit := (B And ($80 Shr (X And 7))) <> 0;
End;

{ ligne horizontale remplie selon le motif (bits a 0 : couleur de fond) }
Procedure FillSpan(X1, X2, Y : LongInt);
Var X : LongInt;
Begin
 If GFillStyle = SolidFill Then
 Begin
  HSpan(X1, X2, Y, GFillColor);
  Exit;
 End;
 For X := X1 To X2 Do
  If FillBit(X, Y) Then Plot(X, Y, GFillColor) Else Plot(X, Y, GBk);
End;

{ --- Graph : etat --- }

{ sur une page a fond blanc (PaperMode), les traits et le texte prennent
  la version foncee de leur couleur (blanc -> noir) ; les remplissages
  gardent leurs couleurs }
Procedure SetColor(C : Integer);
Begin
 C := C And 255;
 If PaperMode And (C > 0) And (C < 16) Then C := 16 + C;
 GColor := C;
End;

Function GetColor : Integer;
Begin
 GetColor := GColor;
End;

Procedure SetLineStyle(Style : Integer; Pattern : Word; Thick : Integer);
Begin
 GLineStyle := Style;
 Case Style Of
  DottedLn : GLinePat := $CCCC;
  CenterLn : GLinePat := $FC78;
  DashedLn : GLinePat := $F8F8;
  UserBitLn : GLinePat := Pattern;
 Else
  GLinePat := $FFFF;
 End;
 If Thick >= 3 Then GThick := 3 Else GThick := 1;
End;

Procedure SetFillStyle(Pattern : Integer; Color : Integer);
Begin
 GFillStyle := Pattern;
 GFillColor := Color And 255;
End;

Procedure SetTextStyle(Font, Dir, Size : Integer);
Begin
 If Size < 1 Then Size := 1;
 If Size > 10 Then Size := 10;
 GTextSz := Size;
End;

Procedure SetTextJustify(H, V : Integer);
Begin
 GJustH := H;
 GJustV := V;
End;

{ --- Graph : traits --- }

Procedure LineThin(X1, Y1, X2, Y2 : LongInt);
Var Dx, Dy, Sx, Sy, E, E2, N : LongInt;
Begin
 Dx := Abs(X2 - X1); Dy := -Abs(Y2 - Y1);
 If X1 < X2 Then Sx := 1 Else Sx := -1;
 If Y1 < Y2 Then Sy := 1 Else Sy := -1;
 E := Dx + Dy; N := 0;
 While True Do
 Begin
  If (GLinePat And ($8000 Shr (N And 15))) <> 0 Then Plot(X1, Y1, GColor);
  Inc(N);
  If (X1 = X2) And (Y1 = Y2) Then Exit;
  E2 := 2 * E;
  If E2 >= Dy Then
  Begin
   E := E + Dy; X1 := X1 + Sx;
  End;
  If E2 <= Dx Then
  Begin
   E := E + Dx; Y1 := Y1 + Sy;
  End;
 End;
End;

Procedure LineA(X1, Y1, X2, Y2 : Integer);
Begin
 GTouch(Min2(X1, X2) - 1, Min2(Y1, Y2) - 1, Max2(X1, X2) + 1, Max2(Y1, Y2) + 1);
 If GThick = 3 Then
 Begin
  If Abs(X2 - X1) >= Abs(Y2 - Y1) Then
  Begin
   LineThin(X1, Y1 - 1, X2, Y2 - 1); LineThin(X1, Y1, X2, Y2); LineThin(X1, Y1 + 1, X2, Y2 + 1);
  End
  Else
  Begin
   LineThin(X1 - 1, Y1, X2 - 1, Y2); LineThin(X1, Y1, X2, Y2); LineThin(X1 + 1, Y1, X2 + 1, Y2);
  End;
 End
 Else LineThin(X1, Y1, X2, Y2);
End;

Procedure RectangleA(X1, Y1, X2, Y2 : Integer);
Begin
 LineA(X1, Y1, X2, Y1); LineA(X2, Y1, X2, Y2);
 LineA(X2, Y2, X1, Y2); LineA(X1, Y2, X1, Y1);
End;

Procedure BarA(X1, Y1, X2, Y2 : Integer);
Var Y, T : LongInt;
Begin
 If X1 > X2 Then
 Begin
  T := X1; X1 := X2; X2 := T;
 End;
 If Y1 > Y2 Then
 Begin
  T := Y1; Y1 := Y2; Y2 := T;
 End;
 GTouch(X1, Y1, X2, Y2);
 For Y := Y1 To Y2 Do FillSpan(X1, X2, Y);
End;

Procedure PutPixelA(X, Y : Integer; C : Word);
Begin
 GTouch(X, Y, X, Y);
 Plot(X, Y, C);
End;

Function GetPixelA(X, Y : Integer) : Word;
Begin
 If (X < 0) Or (Y < 0) Or (X >= FbW) Or (Y >= FbH) Then GetPixelA := 0
 Else GetPixelA := Fb[(FbH - 1 - Y) * FbW + X];
End;

{ --- Graph : ellipses (angles en degres, sens trigonometrique) --- }

Procedure EllipseA(X, Y : Integer; StAngle, EndAngle : Word; XR, YR : Word);
Var A, A2, Steps, K, Px, Py, Qx, Qy : LongInt; T : Double;
Begin
 If (XR = 0) And (YR = 0) Then
 Begin
  PutPixelA(X, Y, GColor);
  Exit;
 End;
 A := StAngle; A2 := EndAngle;
 If A2 <= A Then A2 := A2 + 360;
 If (StAngle = 0) And (EndAngle = 360) Then A2 := 360;
 Steps := ((A2 - A) * (XR + YR)) Div 60 + 8;
 If Steps > 720 Then Steps := 720;
 GTouch(X - XR - 2, Y - YR - 2, X + XR + 2, Y + YR + 2);
 T := A * Pi / 180;
 Px := X + Round(XR * Cos(T)); Py := Y - Round(YR * Sin(T));
 For K := 1 To Steps Do
 Begin
  T := (A + (A2 - A) * K / Steps) * Pi / 180;
  Qx := X + Round(XR * Cos(T)); Qy := Y - Round(YR * Sin(T));
  If (Qx <> Px) Or (Qy <> Py) Then
  Begin
   If GThick = 3 Then LineA(Px, Py, Qx, Qy) Else LineThin(Px, Py, Qx, Qy);
   Px := Qx; Py := Qy;
  End;
 End;
End;

Procedure FillEllipseA(X, Y : Integer; XR, YR : Word);
Var Dy, W : LongInt; T : Double;
Begin
 GTouch(X - XR - 1, Y - YR - 1, X + XR + 1, Y + YR + 1);
 For Dy := -YR To YR Do
 Begin
  If YR = 0 Then W := XR
  Else
  Begin
   T := 1 - (Dy * Dy) / (YR * 1.0 * YR);
   If T < 0 Then T := 0;
   W := Round(XR * Sqrt(T));
  End;
  FillSpan(X - W, X + W, Y + Dy);
 End;
 EllipseA(X, Y, 0, 360, XR, YR);
End;

Procedure ArcA(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 EllipseA(X, Y, StAngle, EndAngle, Radius, Radius);
End;

Procedure CircleA(X, Y : Integer; Radius : Word);
Begin
 EllipseA(X, Y, 0, 360, Radius, Radius);
End;

{ secteur plein de StAngle a EndAngle (degres), puis son contour }
Procedure PieSliceA(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Var Dx, Dy, R2, A0, A1 : LongInt; Ang : Double; Inside : Boolean;
Begin
 A0 := StAngle; A1 := EndAngle;
 If A1 < A0 Then A1 := A1 + 360;
 R2 := LongInt(Radius) * Radius;
 GTouch(X - Radius - 1, Y - Radius - 1, X + Radius + 1, Y + Radius + 1);
 For Dy := -Radius To Radius Do
  For Dx := -Radius To Radius Do
   If Dx * Dx + Dy * Dy <= R2 Then
   Begin
    If (Dx = 0) And (Dy = 0) Then Ang := 0
    Else
    Begin
     If Dx = 0 Then
     Begin
      If Dy < 0 Then Ang := 90 Else Ang := 270;
     End
     Else
     Begin
      Ang := ArcTan(-Dy / Dx) * 180 / Pi;
      If Dx < 0 Then Ang := Ang + 180
      Else If -Dy < 0 Then Ang := Ang + 360;
     End;
    End;
    Inside := (Ang >= A0) And (Ang <= A1);
    If (Not Inside) And (A1 > 360) Then Inside := Ang + 360 <= A1;
    If Inside Then
    Begin
     If FillBit(X + Dx, Y + Dy) Then Plot(X + Dx, Y + Dy, GFillColor)
     Else Plot(X + Dx, Y + Dy, GBk);
    End;
   End;
 { contour : couleur du trait ; si c'est la version foncee (page blanche)
   de la couleur de remplissage, la couleur de remplissage (comme le BGI,
   ou le secteur et son contour sont de la meme couleur) }
 If GColor = 16 + GFillColor Then GColor := GFillColor;
 EllipseA(X, Y, StAngle, EndAngle, Radius, Radius);
 LineA(X, Y, X + Round(Radius * Cos(A0 * Pi / 180)), Y - Round(Radius * Sin(A0 * Pi / 180)));
 LineA(X, Y, X + Round(Radius * Cos(A1 * Pi / 180)), Y - Round(Radius * Sin(A1 * Pi / 180)));
End;

{ --- Graph : texte (police 8 x 8 agrandie GTextSz fois, fond transparent) --- }

Procedure OutTextXYA(X, Y : Integer; S : String);
Var I, R, K, B, C, Sz, W, Cx, R0 : LongInt; Hat : Boolean;
Begin
 If S = '' Then Exit;
 Sz := GTextSz;
 W := Length(S) * 8 * Sz;
 If GJustH = CenterText Then X := X - W Div 2
 Else If GJustH = RightText Then X := X - W;
 If GJustV = CenterText Then Y := Y - 4 * Sz
 Else If GJustV = BottomText Then Y := Y - 8 * Sz;
 GTouch(X, Y - Sz, X + W - 1, Y + 8 * Sz - 1);
 For I := 1 To Length(S) Do
 Begin
  C := Ord(S[I]);
  { a, e, i, o, u circonflexes : dans la police 8 x 8, l'accent colle a
    la lettre ; on dessine la lettre de base puis l'accent au-dessus }
  Hat := True;
  Case C Of
   131 : C := Ord('a');
   136 : C := Ord('e');
   140 : C := Ord('i');
   147 : C := Ord('o');
   150 : C := Ord('u');
  Else Hat := False;
  End;
  If Hat Then R0 := 2 Else R0 := 0;
  Cx := X + (I - 1) * 8 * Sz;
  For R := R0 To 7 Do
  Begin
   B := Font8[C * 8 + R];
   If B <> 0 Then
    For K := 0 To 7 Do
     If (B And ($80 Shr K)) <> 0 Then
     Begin
      If Sz = 1 Then Plot(Cx + K, Y + R, GColor)
      Else For W := 0 To Sz - 1 Do
       HSpan(Cx + K * Sz, Cx + (K + 1) * Sz - 1, Y + R * Sz + W, GColor);
     End;
  End;
  If Hat Then
   For W := 0 To Sz - 1 Do
   Begin
    HSpan(Cx + 3 * Sz, Cx + 5 * Sz - 1, Y - Sz + W, GColor);
    HSpan(Cx + 2 * Sz, Cx + 3 * Sz - 1, Y + W, GColor);
    HSpan(Cx + 5 * Sz, Cx + 6 * Sz - 1, Y + W, GColor);
   End;
 End;
End;

Procedure ClearDevice;
Var K : LongInt;
Begin
 For K := 0 To FbW * FbH - 1 Do Fb[K] := GBk;
 GTouch(0, 0, FbW - 1, FbH - 1);
End;

{ --- Graph : fenetre (SetViewPort), fonctions publiques (coordonnees
  relatives a la fenetre courante) --- }

Procedure SetViewPort(X1, Y1, X2, Y2 : Integer; Clip : Boolean);
Begin
 VOX := X1; VOY := Y1;
 If Clip Then
 Begin
  ClipX1 := Max2(X1, 0); ClipY1 := Max2(Y1, 0);
  ClipX2 := Min2(X2, FbW - 1); ClipY2 := Min2(Y2, FbH - 1);
 End
 Else
 Begin
  ClipX1 := 0; ClipY1 := 0; ClipX2 := FbW - 1; ClipY2 := FbH - 1;
 End;
End;

Procedure ClearViewPort;
Var Y : LongInt;
Begin
 GTouch(ClipX1, ClipY1, ClipX2, ClipY2);
 For Y := ClipY1 To ClipY2 Do HSpan(ClipX1, ClipX2, Y, GBk);
End;

Function GetMaxX : Integer;
Begin
 GetMaxX := FbW - 1;
End;

Function GetMaxY : Integer;
Begin
 GetMaxY := CanvasBot;
End;

Function GraphResult : Integer;
Begin
 GraphResult := 0;
End;

Procedure SetBkColor(C : Integer);
Begin
 GBk := C And 255;
End;

Procedure SetWriteMode(M : Integer);
Begin
 If M = XORPut Then GWrite := XORPut Else GWrite := NormalPut;
End;

Procedure SetFillPattern(Pat : FillPatternType; Color : Integer);
Var I : Integer;
Begin
 For I := 1 To 8 Do GFillPat[I] := Pat[I];
 GFillStyle := UserFill;
 GFillColor := Color And 255;
End;

Function TextWidth(S : String) : Integer;
Begin
 TextWidth := Length(S) * 8 * GTextSz;
End;

Function TextHeight(S : String) : Integer;
Begin
 TextHeight := 8 * GTextSz;
End;

Procedure Line(X1, Y1, X2, Y2 : Integer);
Begin
 LineA(X1 + VOX, Y1 + VOY, X2 + VOX, Y2 + VOY);
End;

Procedure Rectangle(X1, Y1, X2, Y2 : Integer);
Begin
 RectangleA(X1 + VOX, Y1 + VOY, X2 + VOX, Y2 + VOY);
End;

Procedure Bar(X1, Y1, X2, Y2 : Integer);
Begin
 BarA(X1 + VOX, Y1 + VOY, X2 + VOX, Y2 + VOY);
End;

Procedure PutPixel(X, Y : Integer; C : Word);
Begin
 PutPixelA(X + VOX, Y + VOY, C);
End;

Function GetPixel(X, Y : Integer) : Word;
Begin
 GetPixel := GetPixelA(X + VOX, Y + VOY);
End;

Procedure Ellipse(X, Y : Integer; StAngle, EndAngle : Word; XR, YR : Word);
Begin
 EllipseA(X + VOX, Y + VOY, StAngle, EndAngle, XR, YR);
End;

Procedure FillEllipse(X, Y : Integer; XR, YR : Word);
Begin
 FillEllipseA(X + VOX, Y + VOY, XR, YR);
End;

Procedure Arc(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 ArcA(X + VOX, Y + VOY, StAngle, EndAngle, Radius);
End;

Procedure Circle(X, Y : Integer; Radius : Word);
Begin
 CircleA(X + VOX, Y + VOY, Radius);
End;

Procedure PieSlice(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 PieSliceA(X + VOX, Y + VOY, StAngle, EndAngle, Radius);
End;

Procedure OutTextXY(X, Y : Integer; S : String);
Begin
 OutTextXYA(X + VOX, Y + VOY, S);
End;

{ polygone plein (regle pair-impair), puis son contour }
Procedure FillPoly(N : Integer; Var Pts);
Type TPts = Array[1..512] Of PointType;
Var P : ^TPts; I, J, Y, Y1, Y2, K, Cnt, T, Xa, Ya, Xb, Yb : LongInt; Xs : Array[0..127] Of LongInt;
Begin
 P := @Pts;
 If (N < 2) Or (N > 512) Then Exit;
 Y1 := P^[1].Y; Y2 := P^[1].Y;
 For I := 2 To N Do
 Begin
  If P^[I].Y < Y1 Then Y1 := P^[I].Y;
  If P^[I].Y > Y2 Then Y2 := P^[I].Y;
 End;
 For Y := Y1 To Y2 Do
 Begin
  Cnt := 0;
  For I := 1 To N Do
  Begin
   J := I + 1;
   If J > N Then J := 1;
   Xa := P^[I].X; Ya := P^[I].Y; Xb := P^[J].X; Yb := P^[J].Y;
   If ((Ya <= Y) And (Yb > Y)) Or ((Yb <= Y) And (Ya > Y)) Then
    If Cnt < 128 Then
    Begin
     Xs[Cnt] := Xa + ((Y - Ya) * (Xb - Xa)) Div (Yb - Ya);
     Inc(Cnt);
    End;
  End;
  For I := 1 To Cnt - 1 Do
  Begin
   T := Xs[I]; K := I - 1;
   While (K >= 0) And (Xs[K] > T) Do
   Begin
    Xs[K + 1] := Xs[K];
    Dec(K);
   End;
   Xs[K + 1] := T;
  End;
  I := 0;
  While I + 1 < Cnt Do
  Begin
   GTouch(Xs[I] + VOX, Y + VOY, Xs[I + 1] + VOX, Y + VOY);
   FillSpan(Xs[I] + VOX, Xs[I + 1] + VOX, Y + VOY);
   I := I + 2;
  End;
 End;
 For I := 1 To N Do
 Begin
  J := I + 1;
  If J > N Then J := 1;
  Line(P^[I].X, P^[I].Y, P^[J].X, P^[J].Y);
 End;
End;

Procedure DrawPoly(N : Integer; Var Pts);
Type TPtsD = Array[1..512] Of PointType;
Var P : ^TPtsD; I : LongInt;
Begin
 P := @Pts;
 For I := 1 To N - 1 Do Line(P^[I].X, P^[I].Y, P^[I + 1].X, P^[I + 1].Y);
End;

{ images : largeur, hauteur (2 mots) puis un octet par point }
Function ImageSize(X1, Y1, X2, Y2 : Integer) : Word;
Begin
 ImageSize := (Abs(X2 - X1) + 1) * (Abs(Y2 - Y1) + 1) + 4;
End;

Procedure GetImage(X1, Y1, X2, Y2 : Integer; Var BitMap);
Type TB = Array[0..65535] Of Byte;
Var P : ^TB; X, Y, W, H, K : LongInt;
Begin
 P := @BitMap;
 W := X2 - X1 + 1; H := Y2 - Y1 + 1;
 P^[0] := W And 255; P^[1] := W Shr 8; P^[2] := H And 255; P^[3] := H Shr 8;
 K := 4;
 For Y := Y1 To Y2 Do
  For X := X1 To X2 Do
  Begin
   P^[K] := GetPixel(X, Y);
   Inc(K);
  End;
End;

Procedure PutImage(X1, Y1 : Integer; Var BitMap; Op : Word);
Type TBP = Array[0..65535] Of Byte;
Var P : ^TBP; X, Y, W, H, K, Old : LongInt;
Begin
 P := @BitMap;
 W := P^[0] + P^[1] * 256; H := P^[2] + P^[3] * 256;
 Old := GWrite;
 If Op = XORPut Then GWrite := XORPut Else GWrite := NormalPut;
 GTouch(X1 + VOX, Y1 + VOY, X1 + VOX + W - 1, Y1 + VOY + H - 1);
 K := 4;
 For Y := 0 To H - 1 Do
  For X := 0 To W - 1 Do
  Begin
   Plot(X1 + VOX + X, Y1 + VOY + Y, P^[K]);
   Inc(K);
  End;
 GWrite := Old;
End;

{ --- palette de l'image (BITMAPINFO2 de 8 bits) --- }

Procedure InitBmi;
Const
 Pal : Array[0..31] Of LongInt = (
  $000000, $0000AA, $00AA00, $00AAAA, $AA0000, $AA00AA, $AA5500, $AAAAAA,
  $555555, $5555FF, $55FF55, $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF,
  { couleurs foncees pour le fond blanc (16 + couleur du BGI) }
  $000000, $00008C, $00782A, $006E78, $A00000, $820082, $8C4600, $505050,
  $969696, $1E46C8, $00963C, $0082A0, $D21E1E, $B400B4, $A07800, $000000);
Var I, A : LongInt;
Begin
 FillChar(Bmi, SizeOf(Bmi), 0);
 WrL(LongInt(@Bmi), 16);
 WrL(LongInt(@Bmi) + 4, FbW);
 WrL(LongInt(@Bmi) + 8, FbH);
 WrW(LongInt(@Bmi) + 12, 1);
 WrW(LongInt(@Bmi) + 14, 8);
 For I := 0 To 31 Do
 Begin
  A := LongInt(@Bmi) + 16 + I * 4;
  WrB(A, Pal[I] And 255);
  WrB(A + 1, (Pal[I] Shr 8) And 255);
  WrB(A + 2, (Pal[I] Shr 16) And 255);
 End;
 GColor := White; GBk := Black; GFillStyle := SolidFill; GFillColor := White;
 GLineStyle := SolidLn; GLinePat := $FFFF; GThick := 1; GWrite := NormalPut;
 GTextSz := 1; GJustH := LeftText; GJustV := TopText; PaperMode := False;
 VOX := 0; VOY := 0; ClipX1 := 0; ClipY1 := 0; ClipX2 := FbW - 1; ClipY2 := FbH - 1;
 KeyH := 0; KeyT := 0; PendScan := -1; MenuUp := 0; MenuStale := 0; WasActive := 1; CmdH := 0; CmdT := 0; MBtn := 0; MLatch := 0;
 DirtyX1 := -1;
End;

{ couleur I de la palette de l'image (32 a 255 : couleurs du programme),
  RGB = $RRGGBB }
Procedure SetPalEntry(I, RGB : LongInt);
Var A : LongInt;
Begin
 A := LongInt(@Bmi) + 16 + I * 4;
 WrB(A, RGB And 255);
 WrB(A + 1, (RGB Shr 8) And 255);
 WrB(A + 2, (RGB Shr 16) And 255);
End;

{ couleur foncee (lisible sur fond blanc) d'une couleur du BGI }
Function DocCol(C : Integer) : Integer;
Begin
 DocCol := 16 + (C And 15);
End;

{ --- affichage dans la zone client --- }

{ montrer la zone X1..X2, Y1..Y2 de l'image (Y vers le bas) dans la zone
  client : seules les lignes CanvasTop a CanvasBot de l'image sont
  montrees ; la ligne Y de l'image est la ligne CanvasBot - Y du client }
{ fenetre secondaire de PM (vue graphique dans sa propre fenetre) : elle
  montre le rectangle CatX0, CatY0, CatW x CatH de l'image, sauf les
  rectangles de ses controles (PMWIN ne decoupe pas le dessin du parent
  autour de ses fenetres filles) }
Var
 CatFr, CatCl, CatX0, CatY0, CatW, CatH, CatNEx : LongInt;
 CatSave : Pointer;                  { image de la fenetre principale figee }
 CatEx : Array[0..15, 0..3] Of LongInt;

Procedure CatBlitK(Hps, X1, Y1, X2, Y2, K : LongInt);
Var P : Array[0..7] Of LongInt; A1, B1, A2, B2 : LongInt;
Begin
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 If K < CatNEx Then
 Begin
  A1 := CatEx[K, 0]; B1 := CatEx[K, 1]; A2 := CatEx[K, 2]; B2 := CatEx[K, 3];
  If (A1 > X2) Or (A2 < X1) Or (B1 > Y2) Or (B2 < Y1) Then
   CatBlitK(Hps, X1, Y1, X2, Y2, K + 1)
  Else
  Begin
   If B1 > Y1 Then CatBlitK(Hps, X1, Y1, X2, B1 - 1, K + 1);
   If B2 < Y2 Then CatBlitK(Hps, X1, B2 + 1, X2, Y2, K + 1);
   If B1 > Y1 Then Y1 := B1;
   If B2 < Y2 Then Y2 := B2;
   If A1 > X1 Then CatBlitK(Hps, X1, Y1, A1 - 1, Y2, K + 1);
   If A2 < X2 Then CatBlitK(Hps, A2 + 1, Y1, X2, Y2, K + 1);
  End;
  Exit;
 End;
 P[0] := X1 - CatX0; P[1] := CatY0 + CatH - 1 - Y2;
 P[2] := X2 + 1 - CatX0; P[3] := CatY0 + CatH - Y1;
 P[4] := X1; P[5] := FbH - 1 - Y2; P[6] := X2 + 1; P[7] := FbH - Y1;
 Dummy := GpiDrawBits(Hps, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

Procedure CatBlit(Hps, X1, Y1, X2, Y2 : LongInt);
Begin
 If X1 < CatX0 Then X1 := CatX0;
 If Y1 < CatY0 Then Y1 := CatY0;
 If X2 > CatX0 + CatW - 1 Then X2 := CatX0 + CatW - 1;
 If Y2 > CatY0 + CatH - 1 Then Y2 := CatY0 + CatH - 1;
 CatBlitK(Hps, X1, Y1, X2, Y2, 0);
End;

Procedure Blit(Hps, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt; Src : LongInt;
Begin
 Src := LongInt(@Fb);
 If (CatCl <> 0) And (CatSave <> Nil) Then Src := LongInt(CatSave);
 If Y1 < CanvasTop Then Y1 := CanvasTop;
 If Y2 > CanvasBot Then Y2 := CanvasBot;
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 P[0] := X1; P[1] := CanvasBot - Y2; P[2] := X2 + 1; P[3] := CanvasBot - Y1 + 1;
 P[4] := X1; P[5] := FbH - 1 - Y2; P[6] := X2 + 1; P[7] := FbH - Y1;
 Dummy := GpiDrawBits(Hps, Src, LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

{ envoyer a l'ecran ce qui a change depuis le dernier appel }
Procedure FlushScreen;
Var Hps, Cap : LongInt;
Begin
 If OsClient = 0 Then Exit;
 { PM ne decoupe pas le dessin par les fenetres qui recouvrent celle-ci :
   rien n'est montre hors de WM_PAINT quand un menu est ouvert ou que la
   fenetre n'est pas active ; tout est remontre au retour }
 Cap := WinQueryCapture(HWND_DESKTOP);
 If (MenuUp <> 0) And (Cap = 0) Then
 Begin
  Inc(MenuStale);
  If MenuStale > 5 Then MenuUp := 0;
 End
 Else MenuStale := 0;
 { vue graphique dans une fenetre a part : seule celle-ci est mise a jour }
 If CatCl <> 0 Then
 Begin
  WasActive := 0;
  If (MenuUp = 0) And (DirtyX1 >= 0) And (WinQueryActiveWindow(HWND_DESKTOP) = CatFr) Then
  Begin
   Hps := WinGetPS(CatCl);
   If Hps <> 0 Then
   Begin
    CatBlit(Hps, DirtyX1, DirtyY1, DirtyX2, DirtyY2);
    Dummy := WinReleasePS(Hps);
   End;
   DirtyX1 := -1;
  End;
  Exit;
 End;
 If (MenuUp <> 0) Or ((Cap <> 0) And (Cap <> OsClient)) Or
    (WinQueryActiveWindow(HWND_DESKTOP) <> OsFrame) Then
 Begin
  WasActive := 0;
  Exit;
 End;
 If WasActive = 0 Then
 Begin
  GTouch(0, 0, FbW - 1, FbH - 1);
  WasActive := 1;
 End;
 If DirtyX1 < 0 Then Exit;
 Hps := WinGetPS(OsClient);
 If Hps <> 0 Then
 Begin
  Blit(Hps, DirtyX1, DirtyY1, DirtyX2, DirtyY2);
  Dummy := WinReleasePS(Hps);
 End;
 DirtyX1 := -1;
End;

{ --- file d'evenements (remplie par la procedure de fenetre) --- }

Procedure EvPush(K, Key, X, Y : LongInt);
Var N : LongInt;
Begin
 N := (EvTail + 1) Mod EvQMax;
 If N = EvHead Then Exit;
 EvKind[EvTail] := K; EvKey[EvTail] := Key; EvX[EvTail] := X; EvY[EvTail] := Y;
 EvTail := N;
End;

{ Alt + lettre -> code de balayage du clavier du PC }
Function AltScan(C : Char) : LongInt;
Const
 R1 : String[10] = 'QWERTYUIOP';
 R2 : String[9] = 'ASDFGHJKL';
 R3 : String[7] = 'ZXCVBNM';
Begin
 AltScan := 0;
 C := UpCase(C);
 If Pos(C, R1) > 0 Then AltScan := 15 + Pos(C, R1);
 If Pos(C, R2) > 0 Then AltScan := 29 + Pos(C, R2);
 If Pos(C, R3) > 0 Then AltScan := 43 + Pos(C, R3);
End;

{ touche de PM (WM_CHAR) -> code de la version DOS : caractere = Ord,
  touche etendue = 256 + code de balayage du BIOS }
Function KeyCode(Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Ch, Vk, K : LongInt;
Begin
 KeyCode := -1;
 Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
 If (Fl And KC_KEYUP) <> 0 Then Exit;
 K := -1;
 If (Fl And KC_VIRTUALKEY) <> 0 Then
 Begin
  Case Vk Of
   VK_ESC : K := 27;
   VK_NEWLINE, VK_ENTER : K := 13;
   VK_BACKSPACE : K := 8;
   VK_TAB : If (Fl And KC_SHIFT) <> 0 Then K := 271 Else K := 9;
   VK_BACKTAB : K := 271;
   VK_UP : K := 328;
   VK_DOWN : K := 336;
   VK_LEFT : If (Fl And KC_CTRL) <> 0 Then K := 371 Else K := 331;
   VK_RIGHT : If (Fl And KC_CTRL) <> 0 Then K := 372 Else K := 333;
   VK_HOME : If (Fl And KC_CTRL) <> 0 Then K := 375 Else K := 327;
   VK_END : If (Fl And KC_CTRL) <> 0 Then K := 373 Else K := 335;
   VK_PAGEUP : If (Fl And KC_CTRL) <> 0 Then K := 388 Else K := 329;
   VK_PAGEDOWN : If (Fl And KC_CTRL) <> 0 Then K := 374 Else K := 337;
   VK_INSERT : K := 338;
   VK_DELETE : K := 339;
  End;
  If (Vk >= VK_F1) And (Vk <= VK_F1 + 9) And ((Fl And (KC_ALT Or KC_CTRL Or KC_SHIFT)) = 0) Then
   K := 315 + Vk - VK_F1;
 End;
 If (K < 0) And ((Fl And KC_ALT) <> 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  { Alt + lettre d'un titre de menu : laissee a la barre de menus de PM }
  If (AltScan(Chr(Ch)) > 0) And (Pos(UpCase(Chr(Ch)), MnemoKeys) = 0) Then
   K := 256 + AltScan(Chr(Ch));
 End
 Else If (K < 0) And ((Fl And KC_CHAR) <> 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  K := Ch;
  If ((Fl And KC_CTRL) <> 0) And (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then
   K := Ord(UpCase(Chr(Ch))) - 64;
 End;
 { Ctrl + lettre sans KC_CHAR }
 If (K < 0) And ((Fl And KC_CTRL) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
  If (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then K := Ord(UpCase(Chr(Ch))) - 64;
 KeyCode := K;
End;

Procedure MenuInit(M : LongInt); Forward;
Procedure BuildMenuBar; Forward;

Procedure KeyPush(K : LongInt);
Var N : LongInt;
Begin
 N := (KeyT + 1) And 127;
 If N = KeyH Then Exit;
 KeyQ[KeyT] := K;
 KeyT := N;
End;

Procedure CmdPush(C : LongInt);
Var N : LongInt;
Begin
 N := (CmdT + 1) And 31;
 If N = CmdH Then Exit;
 CmdQ[CmdT] := C;
 CmdT := N;
End;

{ procedure de la zone client : touches (file des touches, codes du BIOS),
  souris (position, boutons ; un clic bref reste vu une fois par
  GetMouseState) et commandes des menus (file des commandes) }
Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, K, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 ClientProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    Blit(Hps, 0, CanvasTop, FbW - 1, CanvasBot);
    Dummy := WinEndPaint(Hps);
   End;
  WM_CHAR :
   Begin
    K := KeyCode(Mp1, Mp2);
    If K >= 0 Then
    Begin
     KeyPush(K);
     ClientProc := 1;
    End
    Else ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_MOUSEMOVE :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_BUTTON1DOWN, WM_BUTTON1DBLCLK, WM_BUTTON2DOWN, $0076 :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    Dummy := WinSetFocus(HWND_DESKTOP, H);
    Dummy := WinSetCapture(HWND_DESKTOP, H);
    If (Msg = WM_BUTTON1DOWN) Or (Msg = WM_BUTTON1DBLCLK) Then K := 1 Else K := 2;
    MBtn := MBtn Or K; MLatch := MLatch Or K;
    EvPush(EV_CLICK, K, EvMX, EvMY);
    ClientProc := 1;
   End;
  WM_BUTTON1UP, $0075 :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    If Msg = WM_BUTTON1UP Then MBtn := MBtn And Not 1 Else MBtn := MBtn And Not 2;
    If MBtn = 0 Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
    ClientProc := 1;
   End;
  WM_COMMAND : CmdPush(Lo16(Mp1));
  WM_INITMENU : Begin MenuUp := 1; MenuInit(Lo16(Mp1)); End;
  WM_MENUEND : MenuUp := 0;
  WM_CLOSE : CmdPush(CMD_CLOSE);
 Else
  ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

Procedure PumpMessages;
Begin
 While WinPeekMsg(OsHab, LongInt(@Qmsg), 0, 0, 0, PM_REMOVE) <> 0 Do
 Begin
  If Qmsg[1] = WM_QUIT Then CmdPush(CMD_CLOSE)
  Else Dummy := WinDispatchMsg(OsHab, LongInt(@Qmsg));
 End;
End;

{ --- Crt et souris emules --- }

Function KeyPressed : Boolean;
Begin
 FlushScreen;
 PumpMessages;
 If (KeyH = KeyT) And (PendScan < 0) Then Dummy := DosSleep(1);
 KeyPressed := (KeyH <> KeyT) Or (PendScan >= 0);
End;

{ touche etendue (code >= 256) : #0 puis le code de balayage }
Function ReadKey : Char;
Var K : LongInt;
Begin
 If PendScan >= 0 Then
 Begin
  ReadKey := Chr(PendScan);
  PendScan := -1;
  Exit;
 End;
 While KeyH = KeyT Do
 Begin
  FlushScreen;
  PumpMessages;
  If KeyH = KeyT Then Dummy := DosSleep(10);
 End;
 K := KeyQ[KeyH];
 KeyH := (KeyH + 1) And 127;
 If K >= 256 Then
 Begin
  PendScan := K - 256;
  ReadKey := #0;
 End
 Else ReadKey := Chr(K);
End;

Procedure Delay(Ms : Word);
Begin
 FlushScreen;
 PumpMessages;
 Dummy := DosSleep(Ms);
End;

Procedure GetMouseState(Var X, Y, Button : LongInt);
Begin
 FlushScreen;
 PumpMessages;
 X := EvMX; Y := EvMY;
 Button := MBtn Or MLatch;
 MLatch := 0;
End;

{ commande de la barre de menus en attente (CMD_CLOSE : fermeture) }
Function PollCmd(Var C : LongInt) : Boolean;
Begin
 PumpMessages;
 PollCmd := CmdH <> CmdT;
 If CmdH <> CmdT Then
 Begin
  C := CmdQ[CmdH];
  CmdH := (CmdH + 1) And 31;
 End;
End;

{ --- gabarit de la barre de menus (MENUTEMPLATE) --- }

Procedure MnB(V : LongInt);
Begin
 MenuT[MenuLen] := V And 255;
 Inc(MenuLen);
End;

Procedure MnW(V : LongInt);
Begin
 MnB(V And 255);
 MnB((V Shr 8) And 255);
End;

Function MnOpen : LongInt;
Begin
 MnOpen := MenuLen;
 MnW(0); MnW(0); MnW(0);
End;

Procedure MnClose(H, Count : LongInt);
Begin
 WrW(LongInt(@MenuT) + H, MenuLen - H);
 WrW(LongInt(@MenuT) + H + 4, Count);
End;

Procedure MnItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
 MnW(Style); MnW(Attr); MnW(Id);
 If (Style And MIS_SEPARATOR) = 0 Then
 Begin
  For K := 1 To Length(S) Do MnB(Ord(S[K]));
  MnB(0);
 End;
End;

Procedure MnAttr(Id, Attr : LongInt; On : Boolean);
Var V : LongInt;
Begin
 If On Then V := Attr Else V := 0;
 Dummy := WinSendMsg(OsMenu, MM_SETITEMATTR, Id Or $10000, Attr Or (V Shl 16));
End;

{ libelle de la version DOS ('&Fichier') -> libelle de PM ('~Fichier') }
Function PmLabel(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do If S[I] = '&' Then S[I] := '~';
 PmLabel := S;
End;

{ --- boites de message d'OS/2 --- }

Function PmBox(Title, Txt : String; Fl : LongInt) : LongInt;
Begin
 FlushScreen;
 PutZ(LongInt(@TxtBuf), Txt);
 PmBox := WinMessageBox(HWND_DESKTOP, OsFrame, LongInt(@TxtBuf), OsZ(Title), 0, Fl Or MB_MOVEABLE);
End;

{ titre de la fenetre (change seulement s'il differe) }
Procedure SetTitle(S : String);
Begin
 If (S = OsTitle) Or (OsFrame = 0) Then Exit;
 OsTitle := S;
 Dummy := WinSetWindowText(OsFrame, OsZ(S));
End;

{ fenetre principale : zone client de 640 x (CanvasBot + 1 - CanvasTop) }
Procedure OpenWindow(Cls, Title : String);
Var Fl, W, H, X, Y, Sw, Sh : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 OsHab := WinInitialize(0);
 OsHmq := WinCreateMsgQueue(OsHab, 64);
 Dummy := WinRegisterClass(OsHab, OsZ(Cls), LongInt(@ClientProc), 0, 0);
 Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST Or FCF_DLGBORDER;
 OsClient := 0;
 OsFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), OsZ(Cls),
   OsZ2(Title), 0, 0, 0, LongInt(@OsClient));
 OsTitle := Title;
 BuildMenuBar;
 Rc[0] := 0; Rc[1] := 0; Rc[2] := FbW; Rc[3] := CanvasBot + 1 - CanvasTop;
 Dummy := WinCalcFrameRect(OsFrame, LongInt(@Rc), 0);
 W := Rc[2] - Rc[0]; H := Rc[3] - Rc[1];
 Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
 X := (Sw - W) Div 2; Y := (Sh - H) Div 2;
 If X < 0 Then X := 0;
 { ecran trop petit : barre de titre en haut de l'ecran }
 If Y < 0 Then Y := Sh - H;
 Dummy := WinSetWindowPos(OsFrame, HWND_TOP, X, Y, W, H,
   SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
 Dummy := WinSetFocus(HWND_DESKTOP, OsClient);
End;

{ --- elements d'interface dessines dans le style d'OS/2 --- }

{ relief : clair en haut a gauche, sombre en bas a droite (ou l'inverse) }
Procedure Bevel(X1, Y1, X2, Y2 : Integer; Sunken : Boolean);
Begin
 If Sunken Then SetColor(DarkGray) Else SetColor(White);
 Line(X1, Y1, X2, Y1);
 Line(X1, Y1, X1, Y2);
 If Sunken Then SetColor(White) Else SetColor(DarkGray);
 Line(X1, Y2, X2, Y2);
 Line(X2, Y1, X2, Y2);
End;

{ rectangle pointille (focus d'OS/2) }
Procedure FocusRect(X1, Y1, X2, Y2 : Integer);
Begin
 SetLineStyle(DottedLn, 0, 1);
 SetColor(Black);
 Rectangle(X1, Y1, X2, Y2);
 SetLineStyle(SolidLn, 0, 1);
End;

{ barre de defilement verticale d'OS/2 (fleches, glissiere, curseur) }
Procedure DrawVScroll(X1, Y1, X2, Y2 : Integer; Top, N, Vis : LongInt);
Var Ty, Th, Cx, R : LongInt;
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(X1, Y1, X2, Y2);
 For Ty := Y1 + 14 To Y2 - 14 Do
  For Cx := X1 To X2 Do
   If ((Cx + Ty) And 1) = 0 Then Plot(Cx, Ty, White);
 Bar(X1, Y1, X2, Y1 + 13);
 Bevel(X1, Y1, X2, Y1 + 13, False);
 Bar(X1, Y2 - 13, X2, Y2);
 Bevel(X1, Y2 - 13, X2, Y2, False);
 Cx := (X1 + X2) Div 2;
 SetColor(Black);
 For R := 0 To 3 Do
 Begin
  Line(Cx - R, Y1 + 5 + R, Cx + R, Y1 + 5 + R);
  Line(Cx - R, Y2 - 5 - R, Cx + R, Y2 - 5 - R);
 End;
 If (N <= Vis) Or (N <= 0) Then Exit;
 Th := (Y2 - Y1 - 28) * Vis Div N;
 If Th < 12 Then Th := 12;
 Ty := Y1 + 14 + (Y2 - Y1 - 28 - Th) * Top Div (N - Vis);
 Bar(X1, Ty, X2, Ty + Th);
 Bevel(X1, Ty, X2, Ty + Th, False);
End;

{ souris de PM (couche OS/2) ; le pointeur est celui du systeme }
Procedure InitMouseDriver;
Begin
 MouseAvailable := True;
End;

Procedure ShowMouseCursor;
Begin
End;

Procedure HideMouseCursor;
Begin
End;

Procedure GetMouseLocal(Var X, Y, Buttons: Integer);
Var LX, LY, LB: LongInt;
Begin
 GetMouseState(LX, LY, LB);
 X := LX; Y := LY; Buttons := LB;
End;

{ Horloge en millisecondes depuis minuit }
{ Horloge en millisecondes (GetTickCount de PM) }
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';

Function NowMs: LongInt;
Begin
 NowMs := KTicks Mod 86400000;
End;

{ --------------------------------------------------------------------- }
{ Modele du document : atomes, liaisons, textes, formes                 }
{ --------------------------------------------------------------------- }

Type
 TAdjArr  = Array[0..MAX_ATOMS-1, 0..7] Of Integer;
 PAdjArr  = ^TAdjArr;
 TAdjCnt  = Array[0..MAX_ATOMS-1] Of Byte;
 PAdjCnt  = ^TAdjCnt;
 TIntArr  = Array[0..MAX_ATOMS-1] Of Integer;
 PIntArr  = ^TIntArr;

Var
 Adj      : PAdjArr;
 AdjB     : PAdjArr;
 AdjN     : PAdjCnt;
 Tmp1     : PIntArr;
 Tmp2     : PIntArr;
 Tmp3     : PIntArr;
 TopoVer  : LongInt;
 PropDirty: Boolean;
 PasteN   : Integer;

Procedure TopoChanged;
Begin
 Inc(TopoVer);
End;

Procedure Touch;
Begin
 Inc(DocVer);
 Modified := True;
 NeedRedraw := True;
 PropDirty := True;
End;

Procedure InitDoc;
Begin
 New(At); New(Bd); New(Tx); New(Sh); New(Inf);
 New(Adj); New(AdjB); New(AdjN);
 New(Tmp1); New(Tmp2); New(Tmp3);
 NAt := 0; NBd := 0; NTx := 0; NSh := 0;
 DocVer := 0; TopoVer := 1; RingVer := 0; NRings := 0;
 Modified := False;
 PropDirty := True;
End;

Procedure ClearSelection;
Var I: Integer;
Begin
 For I := 0 To NAt - 1 Do At^[I].Sel := False;
 For I := 0 To NTx - 1 Do Tx^[I].Sel := False;
 For I := 0 To NSh - 1 Do Sh^[I].Sel := False;
 PropDirty := True;
End;

Function AnySelected: Boolean;
Var I: Integer;
Begin
 AnySelected := True;
 For I := 0 To NAt - 1 Do If At^[I].Sel Then Exit;
 For I := 0 To NTx - 1 Do If Tx^[I].Sel Then Exit;
 For I := 0 To NSh - 1 Do If Sh^[I].Sel Then Exit;
 AnySelected := False;
End;

Function CountSelAtoms: Integer;
Var I, N: Integer;
Begin
 N := 0;
 For I := 0 To NAt - 1 Do If At^[I].Sel Then Inc(N);
 CountSelAtoms := N;
End;

Procedure ClearDoc;
Begin
 NAt := 0; NBd := 0; NTx := 0; NSh := 0;
 TopoChanged;
 Touch;
End;

Function NewAtom(AX, AY: Real; AZ: Integer): Integer;
Begin
 If NAt >= MAX_ATOMS Then Begin NewAtom := -1; Exit; End;
 At^[NAt].X := AX;
 At^[NAt].Y := AY;
 At^[NAt].Z := AZ;
 At^[NAt].Chg := 0;
 At^[NAt].Iso := 0;
 At^[NAt].Rad := 0;
 At^[NAt].Col := CurColor;
 At^[NAt].Sel := False;
 At^[NAt].Mark := 0;
 At^[NAt].Lbl := '';
 NewAtom := NAt;
 Inc(NAt);
 TopoChanged;
 Touch;
End;

Function FindBond(A, B: Integer): Integer;
Var J: Integer;
Begin
 For J := 0 To NBd - 1 Do
  If ((Bd^[J].A = A) And (Bd^[J].B = B)) Or
     ((Bd^[J].A = B) And (Bd^[J].B = A)) Then Begin
   FindBond := J; Exit;
  End;
 FindBond := -1;
End;

{ Cree une liaison ; si elle existe deja, renvoie l'existante inchangee }
Function NewBond(A, B, AOrder, ASty: Integer): Integer;
Var J: Integer;
Begin
 If (A = B) Or (A < 0) Or (B < 0) Then Begin NewBond := -1; Exit; End;
 J := FindBond(A, B);
 If J >= 0 Then Begin NewBond := J; Exit; End;
 If NBd >= MAX_BONDS Then Begin NewBond := -1; Exit; End;
 Bd^[NBd].A := A;
 Bd^[NBd].B := B;
 Bd^[NBd].Order := AOrder;
 Bd^[NBd].Sty := ASty;
 Bd^[NBd].DPos := 0;
 Bd^[NBd].Col := CurColor;
 NewBond := NBd;
 Inc(NBd);
 TopoChanged;
 Touch;
End;

Procedure DelBond(J: Integer);
Var K: Integer;
Begin
 If (J < 0) Or (J >= NBd) Then Exit;
 For K := J To NBd - 2 Do Bd^[K] := Bd^[K + 1];
 Dec(NBd);
 TopoChanged;
 Touch;
End;

Procedure DelAtom(I: Integer);
Var K: Integer;
Begin
 If (I < 0) Or (I >= NAt) Then Exit;
 For K := NBd - 1 Downto 0 Do
  If (Bd^[K].A = I) Or (Bd^[K].B = I) Then DelBond(K);
 For K := I To NAt - 2 Do At^[K] := At^[K + 1];
 Dec(NAt);
 For K := 0 To NBd - 1 Do Begin
  If Bd^[K].A > I Then Dec(Bd^[K].A);
  If Bd^[K].B > I Then Dec(Bd^[K].B);
 End;
 TopoChanged;
 Touch;
End;

Procedure DelText(I: Integer);
Var K: Integer;
Begin
 If (I < 0) Or (I >= NTx) Then Exit;
 For K := I To NTx - 2 Do Tx^[K] := Tx^[K + 1];
 Dec(NTx);
 Touch;
End;

Procedure DelShape(I: Integer);
Var K: Integer;
Begin
 If (I < 0) Or (I >= NSh) Then Exit;
 For K := I To NSh - 2 Do Sh^[K] := Sh^[K + 1];
 Dec(NSh);
 Touch;
End;

Function NewText(TX0, TY0: Real; Const S: String): Integer;
Begin
 If NTx >= MAX_TEXTS Then Begin NewText := -1; Exit; End;
 Tx^[NTx].X := TX0;
 Tx^[NTx].Y := TY0;
 Tx^[NTx].S := S;
 Tx^[NTx].Col := CurColor;
 Tx^[NTx].Siz := TextSize;
 Tx^[NTx].Sel := False;
 NewText := NTx;
 Inc(NTx);
 Touch;
End;

Function NewShape(AKind: Integer; AX1, AY1, AX2, AY2: Real): Integer;
Begin
 If NSh >= MAX_SHAPES Then Begin NewShape := -1; Exit; End;
 Sh^[NSh].Kind := AKind;
 Sh^[NSh].X1 := AX1; Sh^[NSh].Y1 := AY1;
 Sh^[NSh].X2 := AX2; Sh^[NSh].Y2 := AY2;
 Sh^[NSh].CX := (AX1 + AX2) / 2 + (AY1 - AY2) * 0.35;
 Sh^[NSh].CY := (AY1 + AY2) / 2 + (AX2 - AX1) * 0.35;
 Sh^[NSh].Col := CurColor;
 Sh^[NSh].Sel := False;
 NewShape := NSh;
 Inc(NSh);
 Touch;
End;

{ Supprime tous les objets selectionnes }
Procedure DeleteSelected;
Var
 I, J, K, N : Integer;
Begin
 { atomes : compactage avec table de correspondance }
 N := 0;
 For I := 0 To NAt - 1 Do Begin
  If At^[I].Sel Then Tmp1^[I] := -1
  Else Begin Tmp1^[I] := N; Inc(N); End;
 End;
 J := 0;
 For K := 0 To NBd - 1 Do Begin
  If (Tmp1^[Bd^[K].A] >= 0) And (Tmp1^[Bd^[K].B] >= 0) Then Begin
   Bd^[J] := Bd^[K];
   Bd^[J].A := Tmp1^[Bd^[K].A];
   Bd^[J].B := Tmp1^[Bd^[K].B];
   Inc(J);
  End;
 End;
 NBd := J;
 J := 0;
 For I := 0 To NAt - 1 Do
  If Not At^[I].Sel Then Begin
   At^[J] := At^[I];
   Inc(J);
  End;
 NAt := J;
 J := 0;
 For I := 0 To NTx - 1 Do
  If Not Tx^[I].Sel Then Begin Tx^[J] := Tx^[I]; Inc(J); End;
 NTx := J;
 J := 0;
 For I := 0 To NSh - 1 Do
  If Not Sh^[I].Sel Then Begin Sh^[J] := Sh^[I]; Inc(J); End;
 NSh := J;
 TopoChanged;
 Touch;
End;

{ Liste d'adjacence (voisins et liaisons correspondantes) }
Procedure BuildAdj;
Var I, J, A, B: Integer;
Begin
 For I := 0 To NAt - 1 Do AdjN^[I] := 0;
 For J := 0 To NBd - 1 Do Begin
  A := Bd^[J].A; B := Bd^[J].B;
  If AdjN^[A] < 8 Then Begin
   Adj^[A, AdjN^[A]] := B; AdjB^[A, AdjN^[A]] := J; Inc(AdjN^[A]);
  End;
  If AdjN^[B] < 8 Then Begin
   Adj^[B, AdjN^[B]] := A; AdjB^[B, AdjN^[B]] := J; Inc(AdjN^[B]);
  End;
 End;
End;

{ Calcule les infos derivees : degre, somme des ordres, H implicites }
Procedure UpdateInfo;
Var
 I, J, A, B, V : Integer;
 D, UX, UY : Real;
Begin
 For I := 0 To NAt - 1 Do Begin
  Inf^[I].Deg := 0; Inf^[I].BSum := 0;
  Inf^[I].SvX := 0; Inf^[I].SvY := 0;
  Inf^[I].H := 0; Inf^[I].Warn := False;
 End;
 For J := 0 To NBd - 1 Do Begin
  A := Bd^[J].A; B := Bd^[J].B;
  D := Dist(At^[A].X, At^[A].Y, At^[B].X, At^[B].Y);
  If D < 0.001 Then D := 0.001;
  UX := (At^[B].X - At^[A].X) / D;
  UY := (At^[B].Y - At^[A].Y) / D;
  Inc(Inf^[A].Deg); Inc(Inf^[A].BSum, Bd^[J].Order);
  Inf^[A].SvX := Inf^[A].SvX + UX; Inf^[A].SvY := Inf^[A].SvY + UY;
  Inc(Inf^[B].Deg); Inc(Inf^[B].BSum, Bd^[J].Order);
  Inf^[B].SvX := Inf^[B].SvX - UX; Inf^[B].SvY := Inf^[B].SvY - UY;
 End;
 For I := 0 To NAt - 1 Do Begin
  If (At^[I].Lbl = '') And (At^[I].Z > 0) And IsOrganicEl(At^[I].Z) Then Begin
   V := NextValence(At^[I].Z, At^[I].Chg, Inf^[I].BSum + At^[I].Rad);
   If V < 0 Then Begin
    Inf^[I].H := 0;
    Inf^[I].Warn := True;
   End
   Else Begin
    Inf^[I].H := V - Inf^[I].BSum - At^[I].Rad;
    If Inf^[I].H < 0 Then Inf^[I].H := 0;
   End;
  End
  Else If (At^[I].Lbl <> '') And (Inf^[I].Deg > 1) Then Inf^[I].Warn := True;
 End;
End;

{ --------------------------------------------------------------------- }
{ Anneaux : recherche des cycles les plus courts                        }
{ --------------------------------------------------------------------- }

Function SameRing(R: Integer; Const Cyc: Array Of Integer; N: Integer): Boolean;
Var I, J: Integer; F: Boolean;
Begin
 SameRing := False;
 If RingN[R] <> N Then Exit;
 For I := 0 To N - 1 Do Begin
  F := False;
  For J := 0 To N - 1 Do
   If RingA[R, J] = Cyc[I] Then Begin F := True; Break; End;
  If Not F Then Exit;
 End;
 SameRing := True;
End;

Procedure FindRings;
Var
 J, I, K, Head, Tail, Cur, Nx, N, S, T : Integer;
 Cyc : Array[0..MAX_RING_SZ - 1] Of Integer;
 Found : Boolean;
 Dup : Boolean;
Begin
 NRings := 0;
 BuildAdj;
 { chaque liaison : cycle le plus court qui la contient }
 For J := 0 To NBd - 1 Do Begin
  If NRings >= MAX_RINGS Then Break;
  S := Bd^[J].A; T := Bd^[J].B;
  { BFS de S vers T sans utiliser la liaison J }
  For I := 0 To NAt - 1 Do Tmp1^[I] := -2;     { parent }
  Tmp1^[S] := -1;
  Tmp2^[0] := S; Head := 0; Tail := 1;
  Found := False;
  While (Head < Tail) And Not Found Do Begin
   Cur := Tmp2^[Head]; Inc(Head);
   For K := 0 To AdjN^[Cur] - 1 Do Begin
    If AdjB^[Cur, K] = J Then Continue;
    Nx := Adj^[Cur, K];
    If Tmp1^[Nx] = -2 Then Begin
     Tmp1^[Nx] := Cur;
     If Nx = T Then Begin Found := True; Break; End;
     If Tail < MAX_ATOMS Then Begin Tmp2^[Tail] := Nx; Inc(Tail); End;
    End;
   End;
  End;
  If Found Then Begin
   N := 0; Cur := T;
   While (Cur >= 0) And (N <= MAX_RING_SZ) Do Begin
    If N < MAX_RING_SZ Then Cyc[N] := Cur;
    Inc(N);
    Cur := Tmp1^[Cur];
   End;
   If (N >= 3) And (N <= MAX_RING_SZ) Then Begin
    Dup := False;
    For K := 0 To NRings - 1 Do
     If SameRing(K, Cyc, N) Then Begin Dup := True; Break; End;
    If Not Dup Then Begin
     RingN[NRings] := N;
     For I := 0 To N - 1 Do RingA[NRings, I] := Cyc[I];
     Inc(NRings);
    End;
   End;
  End;
 End;
 RingVer := TopoVer;
End;

Procedure EnsureRings;
Begin
 If RingVer <> TopoVer Then FindRings;
End;

{ Plus petit anneau contenant la liaison A-B (-1 si aucun) }
Function RingOfBond(A, B: Integer): Integer;
Var R, I, Best: Integer; HA, HB: Boolean;
Begin
 EnsureRings;
 Best := -1;
 For R := 0 To NRings - 1 Do Begin
  HA := False; HB := False;
  For I := 0 To RingN[R] - 1 Do Begin
   If RingA[R, I] = A Then HA := True;
   If RingA[R, I] = B Then HB := True;
  End;
  If HA And HB Then Begin
   If (Best < 0) Or (RingN[R] < RingN[Best]) Then Best := R;
  End;
 End;
 RingOfBond := Best;
End;

Function AtomInRing(A: Integer): Boolean;
Var R, I: Integer;
Begin
 EnsureRings;
 For R := 0 To NRings - 1 Do
  For I := 0 To RingN[R] - 1 Do
   If RingA[R, I] = A Then Begin AtomInRing := True; Exit; End;
 AtomInRing := False;
End;

{ Marque (Mark bit 8) le fragment connexe d'un atome }
Procedure SelectFragment(Start: Integer; Value: Boolean);
Var Head, Tail, Cur, K, I: Integer;
Begin
 If (Start < 0) Or (Start >= NAt) Then Exit;
 BuildAdj;
 For I := 0 To NAt - 1 Do Tmp1^[I] := 0;
 Tmp2^[0] := Start; Tmp1^[Start] := 1; Head := 0; Tail := 1;
 While Head < Tail Do Begin
  Cur := Tmp2^[Head]; Inc(Head);
  At^[Cur].Sel := Value;
  For K := 0 To AdjN^[Cur] - 1 Do
   If Tmp1^[Adj^[Cur, K]] = 0 Then Begin
    Tmp1^[Adj^[Cur, K]] := 1;
    Tmp2^[Tail] := Adj^[Cur, K]; Inc(Tail);
   End;
 End;
 PropDirty := True;
End;

{ Etendue des objets (en coordonnees document) }
Procedure DocBounds(SelOnly: Boolean; Var X1, Y1, X2, Y2: Real; Var Empty: Boolean);
Var I: Integer;
 Procedure Add(PX, PY: Real);
 Begin
  If Empty Then Begin
   X1 := PX; X2 := PX; Y1 := PY; Y2 := PY; Empty := False;
  End
  Else Begin
   If PX < X1 Then X1 := PX; If PX > X2 Then X2 := PX;
   If PY < Y1 Then Y1 := PY; If PY > Y2 Then Y2 := PY;
  End;
 End;
Begin
 Empty := True; X1 := 0; Y1 := 0; X2 := 0; Y2 := 0;
 For I := 0 To NAt - 1 Do
  If (Not SelOnly) Or At^[I].Sel Then Add(At^[I].X, At^[I].Y);
 For I := 0 To NTx - 1 Do
  If (Not SelOnly) Or Tx^[I].Sel Then Begin
   Add(Tx^[I].X, Tx^[I].Y);
   Add(Tx^[I].X + Length(Tx^[I].S) * 8 * Tx^[I].Siz, Tx^[I].Y + 8 * Tx^[I].Siz);
  End;
 For I := 0 To NSh - 1 Do
  If (Not SelOnly) Or Sh^[I].Sel Then Begin
   Add(Sh^[I].X1, Sh^[I].Y1);
   Add(Sh^[I].X2, Sh^[I].Y2);
   If Sh^[I].Kind in [SH_CURVE1, SH_CURVE2] Then Add(Sh^[I].CX, Sh^[I].CY);
  End;
End;

{ --------------------------------------------------------------------- }
{ Annuler / retablir et presse-papiers                                  }
{ --------------------------------------------------------------------- }

Procedure FreeSnap(Var S: TSnap);
Begin
 If S.PA <> Nil Then FreeMem(S.PA, S.NA * SizeOf(TAtom));
 If S.PB <> Nil Then FreeMem(S.PB, S.NB * SizeOf(TBond));
 If S.PT <> Nil Then FreeMem(S.PT, S.NT * SizeOf(TText));
 If S.PS <> Nil Then FreeMem(S.PS, S.NS * SizeOf(TShape));
 S.PA := Nil; S.PB := Nil; S.PT := Nil; S.PS := Nil;
 S.NA := 0; S.NB := 0; S.NT := 0; S.NS := 0;
End;

Procedure TakeSnap(Var S: TSnap);
Begin
 S.PA := Nil; S.PB := Nil; S.PT := Nil; S.PS := Nil;
 S.NA := NAt; S.NB := NBd; S.NT := NTx; S.NS := NSh;
 If NAt > 0 Then Begin GetMem(S.PA, NAt * SizeOf(TAtom)); Move(At^, S.PA^, NAt * SizeOf(TAtom)); End;
 If NBd > 0 Then Begin GetMem(S.PB, NBd * SizeOf(TBond)); Move(Bd^, S.PB^, NBd * SizeOf(TBond)); End;
 If NTx > 0 Then Begin GetMem(S.PT, NTx * SizeOf(TText)); Move(Tx^, S.PT^, NTx * SizeOf(TText)); End;
 If NSh > 0 Then Begin GetMem(S.PS, NSh * SizeOf(TShape)); Move(Sh^, S.PS^, NSh * SizeOf(TShape)); End;
End;

Procedure RestoreSnap(Const S: TSnap);
Begin
 NAt := S.NA; NBd := S.NB; NTx := S.NT; NSh := S.NS;
 If NAt > 0 Then Move(S.PA^, At^, NAt * SizeOf(TAtom));
 If NBd > 0 Then Move(S.PB^, Bd^, NBd * SizeOf(TBond));
 If NTx > 0 Then Move(S.PT^, Tx^, NTx * SizeOf(TText));
 If NSh > 0 Then Move(S.PS^, Sh^, NSh * SizeOf(TShape));
 TopoChanged;
 Touch;
End;

Procedure PushSnap(Var Stk: Array Of TSnap; Var N: Integer; Var S: TSnap);
Var I: Integer;
Begin
 If N >= UNDO_MAX Then Begin
  FreeSnap(Stk[0]);
  For I := 0 To UNDO_MAX - 2 Do Stk[I] := Stk[I + 1];
  N := UNDO_MAX - 1;
 End;
 Stk[N] := S;
 Inc(N);
End;

Procedure ClearRedo;
Var I: Integer;
Begin
 For I := 0 To RedoN - 1 Do FreeSnap(RedoStk[I]);
 RedoN := 0;
End;

{ Debut d'une edition : sauvegarde l'etat courant }
Procedure BeginEdit;
Begin
 If HasPending Then FreeSnap(Pending);
 TakeSnap(Pending);
 HasPending := True;
End;

Procedure CommitEdit;
Begin
 If Not HasPending Then Exit;
 PushSnap(UndoStk, UndoN, Pending);
 HasPending := False;
 ClearRedo;
End;

Procedure CancelEdit;
Begin
 If HasPending Then FreeSnap(Pending);
 HasPending := False;
End;

{ Sauvegarde immediate avant une modification }
Procedure PushUndo;
Begin
 BeginEdit;
 CommitEdit;
End;

{ Vide l'historique annuler / retablir }
Procedure ClearHistory;
Var I: Integer;
Begin
 For I := 0 To UndoN - 1 Do FreeSnap(UndoStk[I]);
 For I := 0 To RedoN - 1 Do FreeSnap(RedoStk[I]);
 UndoN := 0; RedoN := 0;
 CancelEdit;
End;

Procedure DoUndo;
Var S: TSnap;
Begin
 If UndoN = 0 Then Exit;
 TakeSnap(S);
 PushSnap(RedoStk, RedoN, S);
 Dec(UndoN);
 RestoreSnap(UndoStk[UndoN]);
 FreeSnap(UndoStk[UndoN]);
 ClearSelection;
End;

Procedure DoRedo;
Var S: TSnap;
Begin
 If RedoN = 0 Then Exit;
 TakeSnap(S);
 PushSnap(UndoStk, UndoN, S);
 Dec(RedoN);
 RestoreSnap(RedoStk[RedoN]);
 FreeSnap(RedoStk[RedoN]);
 ClearSelection;
End;

{ Copie la selection dans le presse-papiers interne }
Procedure CopySelection;
Var
 I, J, N, NB2, NT2, NS2 : Integer;
Begin
 PasteN := 0;
 If ClipValid Then FreeSnap(Clip);
 N := 0;
 For I := 0 To NAt - 1 Do Begin
  If At^[I].Sel Then Begin Tmp1^[I] := N; Inc(N); End
  Else Tmp1^[I] := -1;
 End;
 NB2 := 0;
 For J := 0 To NBd - 1 Do
  If (Tmp1^[Bd^[J].A] >= 0) And (Tmp1^[Bd^[J].B] >= 0) Then Inc(NB2);
 NT2 := 0; NS2 := 0;
 For I := 0 To NTx - 1 Do If Tx^[I].Sel Then Inc(NT2);
 For I := 0 To NSh - 1 Do If Sh^[I].Sel Then Inc(NS2);
 Clip.NA := N; Clip.NB := NB2; Clip.NT := NT2; Clip.NS := NS2;
 Clip.PA := Nil; Clip.PB := Nil; Clip.PT := Nil; Clip.PS := Nil;
 If N > 0 Then GetMem(Clip.PA, N * SizeOf(TAtom));
 If NB2 > 0 Then GetMem(Clip.PB, NB2 * SizeOf(TBond));
 If NT2 > 0 Then GetMem(Clip.PT, NT2 * SizeOf(TText));
 If NS2 > 0 Then GetMem(Clip.PS, NS2 * SizeOf(TShape));
 N := 0;
 For I := 0 To NAt - 1 Do
  If At^[I].Sel Then Begin
   PAtomArr(Clip.PA)^[N] := At^[I];
   PAtomArr(Clip.PA)^[N].Sel := False;
   Inc(N);
  End;
 NB2 := 0;
 For J := 0 To NBd - 1 Do
  If (Tmp1^[Bd^[J].A] >= 0) And (Tmp1^[Bd^[J].B] >= 0) Then Begin
   PBondArr(Clip.PB)^[NB2] := Bd^[J];
   PBondArr(Clip.PB)^[NB2].A := Tmp1^[Bd^[J].A];
   PBondArr(Clip.PB)^[NB2].B := Tmp1^[Bd^[J].B];
   Inc(NB2);
  End;
 NT2 := 0;
 For I := 0 To NTx - 1 Do
  If Tx^[I].Sel Then Begin
   PTextArr(Clip.PT)^[NT2] := Tx^[I];
   PTextArr(Clip.PT)^[NT2].Sel := False;
   Inc(NT2);
  End;
 NS2 := 0;
 For I := 0 To NSh - 1 Do
  If Sh^[I].Sel Then Begin
   PShapeArr(Clip.PS)^[NS2] := Sh^[I];
   PShapeArr(Clip.PS)^[NS2].Sel := False;
   Inc(NS2);
  End;
 ClipValid := True;
End;

Procedure PasteClipboard(OffX, OffY: Real);
Var I, Base : Integer;
Begin
 Inc(PasteN);
 OffX := OffX * PasteN; OffY := OffY * PasteN;
 If Not ClipValid Then Exit;
 If (NAt + Clip.NA > MAX_ATOMS) Or (NBd + Clip.NB > MAX_BONDS) Or
    (NTx + Clip.NT > MAX_TEXTS) Or (NSh + Clip.NS > MAX_SHAPES) Then Exit;
 ClearSelection;
 Base := NAt;
 For I := 0 To Clip.NA - 1 Do Begin
  At^[NAt] := PAtomArr(Clip.PA)^[I];
  At^[NAt].X := At^[NAt].X + OffX;
  At^[NAt].Y := At^[NAt].Y + OffY;
  At^[NAt].Sel := True;
  Inc(NAt);
 End;
 For I := 0 To Clip.NB - 1 Do Begin
  Bd^[NBd] := PBondArr(Clip.PB)^[I];
  Inc(Bd^[NBd].A, Base);
  Inc(Bd^[NBd].B, Base);
  Inc(NBd);
 End;
 For I := 0 To Clip.NT - 1 Do Begin
  Tx^[NTx] := PTextArr(Clip.PT)^[I];
  Tx^[NTx].X := Tx^[NTx].X + OffX;
  Tx^[NTx].Y := Tx^[NTx].Y + OffY;
  Tx^[NTx].Sel := True;
  Inc(NTx);
 End;
 For I := 0 To Clip.NS - 1 Do Begin
  Sh^[NSh] := PShapeArr(Clip.PS)^[I];
  Sh^[NSh].X1 := Sh^[NSh].X1 + OffX; Sh^[NSh].X2 := Sh^[NSh].X2 + OffX;
  Sh^[NSh].Y1 := Sh^[NSh].Y1 + OffY; Sh^[NSh].Y2 := Sh^[NSh].Y2 + OffY;
  Sh^[NSh].CX := Sh^[NSh].CX + OffX; Sh^[NSh].CY := Sh^[NSh].CY + OffY;
  Sh^[NSh].Sel := True;
  Inc(NSh);
 End;
 TopoChanged;
 Touch;
End;

{ --------------------------------------------------------------------- }
{ Groupes d'atomes (surnoms) : Me, Et, Ph, COOH ...                     }
{ --------------------------------------------------------------------- }

Const
 NNICK = 44;

Type
 TNick = Record
  Nm, Rv : String[6];       { affichage normal / inverse }
  Fm     : String[8];       { formule brute }
  Sm     : String[28];      { fragment SMILES (1er atome = point d'attache) }
  AF, AR : Byte;            { rang du caractere d'ancrage }
 End;

Const
 Nicks : Array[1..NNICK] Of TNick = (
  (Nm:'Me';    Rv:'Me';    Fm:'CH3';    Sm:'C';             AF:1; AR:1),
  (Nm:'Et';    Rv:'Et';    Fm:'C2H5';   Sm:'CC';            AF:1; AR:1),
  (Nm:'Pr';    Rv:'Pr';    Fm:'C3H7';   Sm:'CCC';           AF:1; AR:1),
  (Nm:'iPr';   Rv:'iPr';   Fm:'C3H7';   Sm:'C(C)C';         AF:1; AR:1),
  (Nm:'Bu';    Rv:'Bu';    Fm:'C4H9';   Sm:'CCCC';          AF:1; AR:1),
  (Nm:'iBu';   Rv:'iBu';   Fm:'C4H9';   Sm:'CC(C)C';        AF:1; AR:1),
  (Nm:'tBu';   Rv:'tBu';   Fm:'C4H9';   Sm:'C(C)(C)C';      AF:1; AR:1),
  (Nm:'Ph';    Rv:'Ph';    Fm:'C6H5';   Sm:'C1=CC=CC=C1';   AF:1; AR:1),
  (Nm:'Bn';    Rv:'Bn';    Fm:'C7H7';   Sm:'CC1=CC=CC=C1';  AF:1; AR:1),
  (Nm:'Cy';    Rv:'Cy';    Fm:'C6H11';  Sm:'C1CCCCC1';      AF:1; AR:1),
  (Nm:'Ac';    Rv:'Ac';    Fm:'C2H3O';  Sm:'C(C)=O';        AF:1; AR:1),
  (Nm:'Bz';    Rv:'Bz';    Fm:'C7H5O';  Sm:'C(=O)C1=CC=CC=C1'; AF:1; AR:1),
  (Nm:'OMe';   Rv:'MeO';   Fm:'CH3O';   Sm:'OC';            AF:1; AR:3),
  (Nm:'OEt';   Rv:'EtO';   Fm:'C2H5O';  Sm:'OCC';           AF:1; AR:3),
  (Nm:'OAc';   Rv:'AcO';   Fm:'C2H3O2'; Sm:'OC(C)=O';       AF:1; AR:3),
  (Nm:'OBn';   Rv:'BnO';   Fm:'C7H7O';  Sm:'OCC1=CC=CC=C1'; AF:1; AR:3),
  (Nm:'OPh';   Rv:'PhO';   Fm:'C6H5O';  Sm:'OC1=CC=CC=C1';  AF:1; AR:3),
  (Nm:'COOH';  Rv:'HOOC';  Fm:'CHO2';   Sm:'C(=O)O';        AF:1; AR:4),
  (Nm:'CO2H';  Rv:'HO2C';  Fm:'CHO2';   Sm:'C(=O)O';        AF:1; AR:4),
  (Nm:'CO2Me'; Rv:'MeO2C'; Fm:'C2H3O2'; Sm:'C(=O)OC';       AF:1; AR:5),
  (Nm:'CO2Et'; Rv:'EtO2C'; Fm:'C3H5O2'; Sm:'C(=O)OCC';      AF:1; AR:5),
  (Nm:'CHO';   Rv:'OHC';   Fm:'CHO';    Sm:'C=O';           AF:1; AR:3),
  (Nm:'CONH2'; Rv:'H2NOC'; Fm:'CH2NO';  Sm:'C(N)=O';        AF:1; AR:5),
  (Nm:'CH2OH'; Rv:'HOH2C'; Fm:'CH3O';   Sm:'CO';            AF:1; AR:5),
  (Nm:'CN';    Rv:'NC';    Fm:'CN';     Sm:'C#N';           AF:1; AR:2),
  (Nm:'NO2';   Rv:'O2N';   Fm:'NO2';    Sm:'[N+](=O)[O-]';  AF:1; AR:3),
  (Nm:'CF3';   Rv:'F3C';   Fm:'CF3';    Sm:'C(F)(F)F';      AF:1; AR:3),
  (Nm:'CCl3';  Rv:'Cl3C';  Fm:'CCl3';   Sm:'C(Cl)(Cl)Cl';   AF:1; AR:4),
  (Nm:'NMe2';  Rv:'Me2N';  Fm:'C2H6N';  Sm:'N(C)C';         AF:1; AR:4),
  (Nm:'NHMe';  Rv:'MeHN';  Fm:'CH4N';   Sm:'NC';            AF:1; AR:4),
  (Nm:'NHAc';  Rv:'AcHN';  Fm:'C2H4NO'; Sm:'NC(C)=O';       AF:1; AR:4),
  (Nm:'SMe';   Rv:'MeS';   Fm:'CH3S';   Sm:'SC';            AF:1; AR:3),
  (Nm:'SO2Me'; Rv:'MeO2S'; Fm:'CH3O2S'; Sm:'S(C)(=O)=O';    AF:1; AR:5),
  (Nm:'SO3H';  Rv:'HO3S';  Fm:'HO3S';   Sm:'S(O)(=O)=O';    AF:1; AR:4),
  (Nm:'Boc';   Rv:'Boc';   Fm:'C5H9O2'; Sm:'C(=O)OC(C)(C)C'; AF:1; AR:1),
  (Nm:'Cbz';   Rv:'Cbz';   Fm:'C8H7O2'; Sm:'C(=O)OCC1=CC=CC=C1'; AF:1; AR:1),
  (Nm:'Ts';    Rv:'Ts';    Fm:'C7H7O2S'; Sm:'S(=O)(=O)C1=CC=C(C)C=C1'; AF:1; AR:1),
  (Nm:'Ms';    Rv:'Ms';    Fm:'CH3O2S'; Sm:'S(C)(=O)=O';    AF:1; AR:1),
  (Nm:'Tf';    Rv:'Tf';    Fm:'CF3O2S'; Sm:'S(=O)(=O)C(F)(F)F'; AF:1; AR:1),
  (Nm:'TMS';   Rv:'TMS';   Fm:'C3H9Si'; Sm:'[Si](C)(C)C';   AF:1; AR:1),
  (Nm:'TBS';   Rv:'TBS';   Fm:'C6H15Si'; Sm:'[Si](C)(C)C(C)(C)C'; AF:1; AR:1),
  (Nm:'OTs';   Rv:'TsO';   Fm:'C7H7O3S'; Sm:'OS(=O)(=O)C1=CC=C(C)C=C1'; AF:1; AR:3),
  (Nm:'OMs';   Rv:'MsO';   Fm:'CH3O3S'; Sm:'OS(C)(=O)=O';   AF:1; AR:3),
  (Nm:'OTf';   Rv:'TfO';   Fm:'CF3O3S'; Sm:'OS(=O)(=O)C(F)(F)F'; AF:1; AR:3)
 );

Function FindNick(Const L: String): Integer;
Var I: Integer; U: String;
Begin
 U := UpStr(L);
 For I := 1 To NNICK Do
  If UpStr(Nicks[I].Nm) = U Then Begin FindNick := I; Exit; End;
 FindNick := 0;
End;

{ --------------------------------------------------------------------- }
{ Transformations ecran <-> document                                    }
{ --------------------------------------------------------------------- }

Function SX(X: Real): Integer;
Begin
 SX := RoundI((X - ScrollX) * Zoom);
End;

Function SY(Y: Real): Integer;
Begin
 SY := RoundI((Y - ScrollY) * Zoom);
End;

Function SXr(X: Real): Real;
Begin
 SXr := (X - ScrollX) * Zoom;
End;

Function SYr(Y: Real): Real;
Begin
 SYr := (Y - ScrollY) * Zoom;
End;

Function DocX(MX: Integer): Real;
Begin
 DocX := ScrollX + (MX - CvX1) / Zoom;
End;

Function DocY(MY: Integer): Real;
Begin
 DocY := ScrollY + (MY - CvY1) / Zoom;
End;

Function InCanvas(MX, MY: Integer): Boolean;
Begin
 InCanvas := (MX >= CvX1) And (MX <= CvX2) And (MY >= CvY1) And (MY <= CvY2);
End;

Function PtInRect(MX, MY, X1, Y1, X2, Y2: Integer): Boolean;
Begin
 PtInRect := (MX >= X1) And (MX <= X2) And (MY >= Y1) And (MY <= Y2);
End;

Function DistToSeg(PX, PY, X1, Y1, X2, Y2: Real): Real;
Var DX, DY, T, L2: Real;
Begin
 DX := X2 - X1; DY := Y2 - Y1;
 L2 := DX * DX + DY * DY;
 If L2 < 0.000001 Then Begin DistToSeg := Dist(PX, PY, X1, Y1); Exit; End;
 T := ((PX - X1) * DX + (PY - Y1) * DY) / L2;
 If T < 0 Then T := 0;
 If T > 1 Then T := 1;
 DistToSeg := Dist(PX, PY, X1 + T * DX, Y1 + T * DY);
End;

{ --------------------------------------------------------------------- }
{ Petite police pour indices, exposants et charges                      }
{ --------------------------------------------------------------------- }

Const
 MiniF : Array[0..12, 0..4] Of Byte = (
  (7,5,5,5,7), (2,6,2,2,7), (7,1,7,4,7), (7,1,7,1,7), (5,5,7,1,1),
  (7,4,7,1,7), (7,4,7,5,7), (7,1,1,1,1), (7,5,7,5,7), (7,5,7,1,7),
  (0,2,7,2,0), (0,0,7,0,0), (0,0,2,0,0));

Procedure DrawMini(Ch: Char; X, Y, S: Integer; Col: Byte);
Var Idx, R, C: Integer;
Begin
 If (Ch >= '0') And (Ch <= '9') Then Idx := Ord(Ch) - 48
 Else If Ch = '+' Then Idx := 10
 Else If Ch = '-' Then Idx := 11
 Else If Ch = '.' Then Idx := 12
 Else Exit;
 SetFillStyle(SolidFill, Col);
 For R := 0 To 4 Do
  For C := 0 To 2 Do
   If (MiniF[Idx, R] And (4 Shr C)) <> 0 Then
    Bar(X + C * S, Y + R * S, X + C * S + S - 1, Y + R * S + S - 1);
End;

Function IsDigitCh(C: Char): Boolean;
Begin
 IsDigitCh := (C >= '0') And (C <= '9');
End;

{ --------------------------------------------------------------------- }
{ Etiquettes d'atomes                                                   }
{ --------------------------------------------------------------------- }

Function LabelVisible(I: Integer): Boolean;
Begin
 With At^[I] Do
  LabelVisible := (Lbl <> '') Or (Z <> 6) Or OptShowC Or (Inf^[I].Deg = 0) Or
                  (Chg <> 0) Or (Iso <> 0) Or (Rad <> 0);
End;

{ Construit le texte de l'etiquette, la position et la longueur d'ancrage }
Procedure BuildLabel(I: Integer; Var T: String; Var Anchor, ALen: Integer;
                     Var ChgS: String);
Var
 Sym, Hs, IsoS : String;
 K, H : Integer;
 Rev  : Boolean;
Begin
 ChgS := '';
 ALen := 1;
 Rev := Inf^[I].SvX > 0.15;
 If At^[I].Lbl <> '' Then Begin
  K := FindNick(At^[I].Lbl);
  If K > 0 Then Begin
   If Rev Then Begin T := Nicks[K].Rv; Anchor := Nicks[K].AR; End
   Else Begin T := Nicks[K].Nm; Anchor := Nicks[K].AF; End;
  End
  Else Begin T := At^[I].Lbl; Anchor := 1; ALen := Length(T); If ALen > 2 Then ALen := 1; End;
 End
 Else If At^[I].Z = 0 Then Begin T := '?'; Anchor := 1; End
 Else Begin
  Sym := ElSym[At^[I].Z];
  H := Inf^[I].H;
  ALen := Length(Sym);
  If H = 0 Then Begin T := Sym; Anchor := 1; End
  Else Begin
   If H = 1 Then Hs := 'H' Else Hs := 'H' + IntToStr(H);
   If Inf^[I].Deg = 0 Then Rev := At^[I].Z In [8, 9, 16, 17, 34, 35, 52, 53];
   If Rev Then Begin T := Hs + Sym; Anchor := Length(Hs) + 1; End
   Else Begin T := Sym + Hs; Anchor := 1; End;
  End;
 End;
 If At^[I].Iso > 0 Then Begin
  IsoS := IntToStr(At^[I].Iso);
  T := IsoS + T;
  Inc(Anchor, Length(IsoS));
 End;
 If At^[I].Chg <> 0 Then Begin
  If Abs(At^[I].Chg) > 1 Then ChgS := IntToStr(Abs(At^[I].Chg));
  If At^[I].Chg > 0 Then ChgS := ChgS + '+' Else ChgS := ChgS + '-';
 End;
 If At^[I].Rad > 0 Then ChgS := ChgS + '.';
End;

{ Largeur d'un caractere de l'etiquette ; Kind : 0=lettre 1=indice 2=exposant }
Function CharKind(Const T: String; P: Integer): Integer;
Var K: Integer; Seen: Boolean;
Begin
 If Not IsDigitCh(T[P]) Then Begin CharKind := 0; Exit; End;
 Seen := False;
 For K := 1 To P - 1 Do If Not IsDigitCh(T[K]) Then Seen := True;
 If Seen Then CharKind := 1 Else CharKind := 2;
End;

Function CharW(Const T: String; P: Integer): Integer;
Begin
 If CharKind(T, P) = 0 Then CharW := 8 * TxtScale Else CharW := 4 * TxtScale;
End;

Procedure LabelMetrics(Const T: String; Anchor, ALen: Integer;
                       Var Total, AOff, ASpan: Integer);
Var I: Integer;
Begin
 Total := 0; AOff := 0; ASpan := 0;
 For I := 1 To Length(T) Do Begin
  If I = Anchor Then AOff := Total;
  If (I >= Anchor) And (I < Anchor + ALen) Then ASpan := ASpan + CharW(T, I);
  Total := Total + CharW(T, I);
 End;
 If ASpan = 0 Then ASpan := 8 * TxtScale;
End;

{ Distance a partir du centre de l'atome ou la liaison sort de l'etiquette }
Function AtomClip(I: Integer; UX, UY: Real): Real;
Var
 T, ChgS : String;
 Anchor, ALen, Total, AOff, ASpan : Integer;
 HW, HH, R, Q : Real;
Begin
 If Not LabelVisible(I) Then Begin AtomClip := 0; Exit; End;
 BuildLabel(I, T, Anchor, ALen, ChgS);
 LabelMetrics(T, Anchor, ALen, Total, AOff, ASpan);
 HW := ASpan / 2 + 3;
 HH := 4 * TxtScale + 3;
 R := 100000;
 If AbsR(UX) > 0.001 Then Begin Q := HW / AbsR(UX); If Q < R Then R := Q; End;
 If AbsR(UY) > 0.001 Then Begin Q := HH / AbsR(UY); If Q < R Then R := Q; End;
 AtomClip := R;
End;

Procedure DrawAtomLabel(I, CX, CY: Integer; Col: Byte);
Var
 T, ChgS : String;
 Anchor, ALen, Total, AOff, ASpan, P, X, K : Integer;
 Ch : String;
Begin
 BuildLabel(I, T, Anchor, ALen, ChgS);
 LabelMetrics(T, Anchor, ALen, Total, AOff, ASpan);
 X := CX - ASpan Div 2 - AOff;
 SetTextStyle(DefaultFont, HorizDir, TxtScale);
 SetColor(Col);
 For P := 1 To Length(T) Do Begin
  K := CharKind(T, P);
  If K = 0 Then Begin
   Ch := T[P];
   OutTextXY(X, CY - 4 * TxtScale, Ch);
  End
  Else If K = 1 Then DrawMini(T[P], X, CY + TxtScale, TxtScale, Col)
  Else DrawMini(T[P], X, CY - 4 * TxtScale - TxtScale, TxtScale, Col);
  X := X + CharW(T, P);
 End;
 For P := 1 To Length(ChgS) Do Begin
  DrawMini(ChgS[P], X, CY - 5 * TxtScale, TxtScale, Col);
  X := X + 4 * TxtScale;
 End;
End;

{ --------------------------------------------------------------------- }
{ Dessin des liaisons                                                   }
{ --------------------------------------------------------------------- }

Procedure DLine(X1, Y1, X2, Y2: Real);
Begin
 Line(RoundI(X1), RoundI(Y1), RoundI(X2), RoundI(Y2));
End;

Procedure DDashed(X1, Y1, X2, Y2: Real; DashL, GapL: Real);
Var L, UX, UY, T, E: Real;
Begin
 L := Dist(X1, Y1, X2, Y2);
 If L < 1 Then Exit;
 UX := (X2 - X1) / L; UY := (Y2 - Y1) / L;
 T := 0;
 While T < L Do Begin
  E := T + DashL;
  If E > L Then E := L;
  DLine(X1 + UX * T, Y1 + UY * T, X1 + UX * E, Y1 + UY * E);
  T := E + GapL;
 End;
End;

Procedure FillTri(X1, Y1, X2, Y2, X3, Y3: Real; Col: Byte);
Var P : Array[0..2] Of PointType;
Begin
 P[0].X := RoundI(X1); P[0].Y := RoundI(Y1);
 P[1].X := RoundI(X2); P[1].Y := RoundI(Y2);
 P[2].X := RoundI(X3); P[2].Y := RoundI(Y3);
 SetFillStyle(SolidFill, Col);
 SetColor(Col);
 FillPoly(3, P);
End;

Procedure LineW(W: Integer);
Begin
 If W > 1 Then SetLineStyle(SolidLn, 0, ThickWidth) Else SetLineStyle(SolidLn, 0, NormWidth);
End;

{ Peint une liaison ; coordonnees ecran ; ShA/ShB = degagement aux etiquettes }
Procedure PaintBond(X1, Y1, X2, Y2: Real; AOrder, ASty, Side: Integer;
                    ShA, ShB: Real; Col: Byte; ShortA, ShortB: Boolean);
Var
 L, UX, UY, NX, NY, D, HW, SXa, SYa, EXa, EYa, T, Amp, Sa, Sb, Off : Real;
 N, K : Integer;
 PX, PY, QX, QY : Real;
Begin
 L := Dist(X1, Y1, X2, Y2);
 If L < 2 Then Exit;
 UX := (X2 - X1) / L; UY := (Y2 - Y1) / L;
 NX := -UY; NY := UX;
 SXa := X1 + UX * ShA; SYa := Y1 + UY * ShA;
 EXa := X2 - UX * ShB; EYa := Y2 - UY * ShB;
 If Dist(SXa, SYa, EXa, EYa) < 2 Then Exit;
 L := Dist(SXa, SYa, EXa, EYa);
 D := 0.18 * BOND_LEN * Zoom;
 If D < 3 Then D := 3;
 SetColor(Col);
 SetLineStyle(SolidLn, 0, NormWidth);
 Case ASty Of
  ST_WEDGE: Begin
   HW := 0.10 * BOND_LEN * Zoom; If HW < 2 Then HW := 2;
   FillTri(SXa, SYa, EXa + NX * HW, EYa + NY * HW, EXa - NX * HW, EYa - NY * HW, Col);
  End;
  ST_HASH: Begin
   HW := 0.10 * BOND_LEN * Zoom; If HW < 2 Then HW := 2;
   N := RoundI(L / 3.2); If N < 4 Then N := 4;
   For K := 0 To N Do Begin
    T := K / N;
    PX := SXa + (EXa - SXa) * T; PY := SYa + (EYa - SYa) * T;
    Off := 0.5 + HW * T;
    DLine(PX + NX * Off, PY + NY * Off, PX - NX * Off, PY - NY * Off);
   End;
  End;
  ST_BOLD: Begin
   SetLineStyle(SolidLn, 0, ThickWidth);
   DLine(SXa, SYa, EXa, EYa);
   SetLineStyle(SolidLn, 0, NormWidth);
  End;
  ST_WAVY: Begin
   Amp := 2.5 * Zoom; If Amp < 2 Then Amp := 2;
   N := RoundI(L / 2); If N < 4 Then N := 4;
   PX := SXa; PY := SYa;
   For K := 1 To N Do Begin
    T := K / N;
    Off := Amp * Sin(T * L * 2 * Pi / (7 * Zoom + 2));
    QX := SXa + (EXa - SXa) * T + NX * Off;
    QY := SYa + (EYa - SYa) * T + NY * Off;
    DLine(PX, PY, QX, QY);
    PX := QX; PY := QY;
   End;
  End;
  ST_DASH: DDashed(SXa, SYa, EXa, EYa, 4, 3);
 Else
  Case AOrder Of
   2: Begin
    If Side = 0 Then Begin
     DLine(SXa + NX * D / 2, SYa + NY * D / 2, EXa + NX * D / 2, EYa + NY * D / 2);
     DLine(SXa - NX * D / 2, SYa - NY * D / 2, EXa - NX * D / 2, EYa - NY * D / 2);
    End
    Else Begin
     DLine(SXa, SYa, EXa, EYa);
     Sa := 0; Sb := 0;
     If ShortA Then Sa := D * 1.0;
     If ShortB Then Sb := D * 1.0;
     If Sa + Sb > L * 0.7 Then Begin Sa := 0; Sb := 0; End;
     DLine(SXa + NX * D * Side + UX * Sa, SYa + NY * D * Side + UY * Sa,
           EXa + NX * D * Side - UX * Sb, EYa + NY * D * Side - UY * Sb);
    End;
   End;
   3: Begin
    DLine(SXa, SYa, EXa, EYa);
    DLine(SXa + NX * D, SYa + NY * D, EXa + NX * D, EYa + NY * D);
    DLine(SXa - NX * D, SYa - NY * D, EXa - NX * D, EYa - NY * D);
   End;
  Else
   DLine(SXa, SYa, EXa, EYa);
  End;
 End;
 SetLineStyle(SolidLn, 0, NormWidth);
End;

{ Cote du deuxieme trait d'une double liaison : -1, 0 (centre), +1 }
Function BondSide(J: Integer): Integer;
Var
 A, B, R, I, N, Left, Right : Integer;
 UX, UY, NX, NY, L, MX, MY, CX, CY, S : Real;
 K : Integer;
Begin
 A := Bd^[J].A; B := Bd^[J].B;
 BondSide := 0;
 Case Bd^[J].DPos Of
  1: Begin BondSide := 1; Exit; End;
  2: Begin BondSide := -1; Exit; End;
  3: Begin BondSide := 0; Exit; End;
 End;
 L := Dist(At^[A].X, At^[A].Y, At^[B].X, At^[B].Y);
 If L < 0.001 Then Exit;
 UX := (At^[B].X - At^[A].X) / L; UY := (At^[B].Y - At^[A].Y) / L;
 NX := -UY; NY := UX;
 MX := (At^[A].X + At^[B].X) / 2; MY := (At^[A].Y + At^[B].Y) / 2;
 R := RingOfBond(A, B);
 If R >= 0 Then Begin
  CX := 0; CY := 0;
  For I := 0 To RingN[R] - 1 Do Begin
   CX := CX + At^[RingA[R, I]].X; CY := CY + At^[RingA[R, I]].Y;
  End;
  CX := CX / RingN[R]; CY := CY / RingN[R];
  S := (CX - MX) * NX + (CY - MY) * NY;
  If S > 0 Then BondSide := 1 Else BondSide := -1;
  Exit;
 End;
 If (Inf^[A].Deg = 1) Or (Inf^[B].Deg = 1) Then Exit;
 BuildAdj;
 Left := 0; Right := 0;
 For K := 0 To AdjN^[A] - 1 Do
  If Adj^[A, K] <> B Then Begin
   N := Adj^[A, K];
   S := (At^[N].X - MX) * NX + (At^[N].Y - MY) * NY;
   If S > 0 Then Inc(Left) Else Inc(Right);
  End;
 For K := 0 To AdjN^[B] - 1 Do
  If Adj^[B, K] <> A Then Begin
   N := Adj^[B, K];
   S := (At^[N].X - MX) * NX + (At^[N].Y - MY) * NY;
   If S > 0 Then Inc(Left) Else Inc(Right);
  End;
 If Left > Right Then BondSide := 1
 Else If Right > Left Then BondSide := -1
 Else BondSide := 0;
End;

Procedure DrawBond(J: Integer; Col: Byte);
Var
 A, B, Side : Integer;
 X1, Y1, X2, Y2, L, UX, UY, ShA, ShB : Real;
 SA, SB : Boolean;
Begin
 A := Bd^[J].A; B := Bd^[J].B;
 X1 := SXr(At^[A].X); Y1 := SYr(At^[A].Y);
 X2 := SXr(At^[B].X); Y2 := SYr(At^[B].Y);
 L := Dist(X1, Y1, X2, Y2);
 If L < 1 Then Exit;
 UX := (X2 - X1) / L; UY := (Y2 - Y1) / L;
 ShA := AtomClip(A, UX, UY);
 ShB := AtomClip(B, -UX, -UY);
 Side := 0;
 If (Bd^[J].Order = 2) And (Bd^[J].Sty = ST_NORMAL) Then Side := BondSide(J);
 SA := (ShA = 0) And (Inf^[A].Deg > 1);
 SB := (ShB = 0) And (Inf^[B].Deg > 1);
 PaintBond(X1, Y1, X2, Y2, Bd^[J].Order, Bd^[J].Sty, Side, ShA, ShB, Col, SA, SB);
End;

{ --------------------------------------------------------------------- }
{ Dessin des formes : fleches, courbes, cadres, orbitales               }
{ --------------------------------------------------------------------- }

Procedure ArrowHead(TX0, TY0, DX, DY: Real; Full, Left: Boolean; Col: Byte);
{ pointe de fleche en (TX0,TY0), direction unitaire (DX,DY) }
Var HL, HW, BX, BY, NX, NY : Real;
Begin
 HL := 10; HW := 4;
 If Zoom > 1.5 Then Begin HL := 12; HW := 5; End;
 NX := -DY; NY := DX;
 BX := TX0 - DX * HL; BY := TY0 - DY * HL;
 If Full Then
  FillTri(TX0, TY0, BX + NX * HW, BY + NY * HW, BX - NX * HW, BY - NY * HW, Col)
 Else If Left Then
  FillTri(TX0, TY0, BX + NX * HW, BY + NY * HW, BX, BY, Col)
 Else
  FillTri(TX0, TY0, BX - NX * HW, BY - NY * HW, BX, BY, Col);
End;

Procedure DrawEllipseRot(CX, CY, RA, RB, Ang: Real; Fill: Boolean; Col: Byte);
Var
 P : Array[0..32] Of PointType;
 K : Integer;
 T, CA, SA2, EX, EY : Real;
Begin
 CA := Cos(Ang); SA2 := Sin(Ang);
 For K := 0 To 31 Do Begin
  T := K * 2 * Pi / 32;
  EX := RA * Cos(T); EY := RB * Sin(T);
  P[K].X := RoundI(CX + EX * CA - EY * SA2);
  P[K].Y := RoundI(CY + EX * SA2 + EY * CA);
 End;
 P[32] := P[0];
 SetColor(Col);
 If Fill Then Begin
  SetFillStyle(SolidFill, Col);
  FillPoly(33, P);
 End
 Else DrawPoly(33, P);
End;

Procedure DrawShapeRec(Const S: TShape; Col: Byte);
Var
 X1, Y1, X2, Y2, CX, CY, L, UX, UY, NX, NY, T, PX, PY, QX, QY, TX1, TY1 : Real;
 K, N : Integer;
 W2 : Real;
Begin
 X1 := SXr(S.X1); Y1 := SYr(S.Y1); X2 := SXr(S.X2); Y2 := SYr(S.Y2);
 CX := SXr(S.CX); CY := SYr(S.CY);
 SetColor(Col);
 SetLineStyle(SolidLn, 0, NormWidth);
 L := Dist(X1, Y1, X2, Y2);
 If L > 0.5 Then Begin UX := (X2 - X1) / L; UY := (Y2 - Y1) / L; End
 Else Begin UX := 1; UY := 0; End;
 NX := -UY; NY := UX;
 Case S.Kind Of
  SH_LINE: DLine(X1, Y1, X2, Y2);
  SH_ARROW: Begin
   DLine(X1, Y1, X2 - UX * 6, Y2 - UY * 6);
   ArrowHead(X2, Y2, UX, UY, True, True, Col);
  End;
  SH_DASHARR: Begin
   DDashed(X1, Y1, X2 - UX * 6, Y2 - UY * 6, 5, 3);
   ArrowHead(X2, Y2, UX, UY, True, True, Col);
  End;
  SH_RESON: Begin
   DLine(X1 + UX * 6, Y1 + UY * 6, X2 - UX * 6, Y2 - UY * 6);
   ArrowHead(X2, Y2, UX, UY, True, True, Col);
   ArrowHead(X1, Y1, -UX, -UY, True, True, Col);
  End;
  SH_EQUIL: Begin
   DLine(X1 + NX * 3, Y1 + NY * 3, X2 + NX * 3, Y2 + NY * 3);
   DLine(X1 - NX * 3, Y1 - NY * 3, X2 - NX * 3, Y2 - NY * 3);
   ArrowHead(X2 + NX * 3, Y2 + NY * 3, UX, UY, False, False, Col);
   ArrowHead(X1 - NX * 3, Y1 - NY * 3, -UX, -UY, False, False, Col);
  End;
  SH_RETRO: Begin
   DLine(X1 + NX * 3, Y1 + NY * 3, X2 - UX * 8 + NX * 3, Y2 - UY * 8 + NY * 3);
   DLine(X1 - NX * 3, Y1 - NY * 3, X2 - UX * 8 - NX * 3, Y2 - UY * 8 - NY * 3);
   DLine(X2, Y2, X2 - UX * 12 + NX * 7, Y2 - UY * 12 + NY * 7);
   DLine(X2, Y2, X2 - UX * 12 - NX * 7, Y2 - UY * 12 - NY * 7);
  End;
  SH_CURVE2, SH_CURVE1: Begin
   N := 18;
   PX := X1; PY := Y1;
   For K := 1 To N Do Begin
    T := K / N;
    QX := (1 - T) * (1 - T) * X1 + 2 * (1 - T) * T * CX + T * T * X2;
    QY := (1 - T) * (1 - T) * Y1 + 2 * (1 - T) * T * CY + T * T * Y2;
    If K = N Then Begin TX1 := QX - PX; TY1 := QY - PY; End;
    DLine(PX, PY, QX, QY);
    PX := QX; PY := QY;
   End;
   L := Sqrt(TX1 * TX1 + TY1 * TY1);
   If L > 0.001 Then
    ArrowHead(X2, Y2, TX1 / L, TY1 / L, S.Kind = SH_CURVE2, True, Col);
  End;
  SH_RECT: Rectangle(RoundI(X1), RoundI(Y1), RoundI(X2), RoundI(Y2));
  SH_ELLIPSE: Begin
   W2 := AbsR(X2 - X1) / 2;
   If (W2 >= 1) And (AbsR(Y2 - Y1) >= 2) Then
    Ellipse(RoundI((X1 + X2) / 2), RoundI((Y1 + Y2) / 2), 0, 360,
            RoundI(W2), RoundI(AbsR(Y2 - Y1) / 2));
  End;
  SH_BRACKET: Begin
   W2 := 6;
   DLine(X1 + W2, Y1, X1, Y1); DLine(X1, Y1, X1, Y2); DLine(X1, Y2, X1 + W2, Y2);
   DLine(X2 - W2, Y1, X2, Y1); DLine(X2, Y1, X2, Y2); DLine(X2, Y2, X2 - W2, Y2);
  End;
  SH_ORBS: Begin
   If L >= 2 Then Circle(RoundI(X1), RoundI(Y1), RoundI(L));
  End;
  SH_ORBP: Begin
   If L >= 4 Then Begin
    DrawEllipseRot(X1 + UX * L / 2, Y1 + UY * L / 2, L / 2, L / 4.5, Atan2(UY, UX), False, Col);
    DrawEllipseRot(X1 - UX * L / 2, Y1 - UY * L / 2, L / 2, L / 4.5, Atan2(UY, UX), True, Col);
   End;
  End;
 End;
 SetLineStyle(SolidLn, 0, NormWidth);
End;

Procedure DrawHandle(X, Y: Integer);
Begin
 SetFillStyle(SolidFill, White);
 Bar(X - 3, Y - 3, X + 3, Y + 3);
 SetColor(Blue);
 Rectangle(X - 3, Y - 3, X + 3, Y + 3);
End;

Procedure TextRectScreen(I: Integer; Var X1, Y1, X2, Y2: Integer);
Var Sc: Integer;
Begin
 Sc := Tx^[I].Siz * TxtScale;
 X1 := SX(Tx^[I].X);
 Y1 := SY(Tx^[I].Y);
 X2 := X1 + Length(Tx^[I].S) * 8 * Sc;
 Y2 := Y1 + 8 * Sc;
End;

Procedure ShapeHandlePos(I, H: Integer; Var HX, HY: Integer);
Begin
 Case H Of
  0: Begin HX := SX(Sh^[I].X1); HY := SY(Sh^[I].Y1); End;
  1: Begin HX := SX(Sh^[I].X2); HY := SY(Sh^[I].Y2); End;
 Else
  HX := SX(Sh^[I].CX); HY := SY(Sh^[I].CY);
 End;
End;

{ --------------------------------------------------------------------- }
{ Composants d'interface : biseaux, boutons                              }
{ --------------------------------------------------------------------- }

{ Bevel : couche OS/2 }

Procedure DrawButton(X1, Y1, X2, Y2: Integer; Const Caption: String;
                     Focused: Boolean);
Var TX, TY: Integer;
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
 SetColor(White);
 Line(X1, Y1, X2, Y1);
 Line(X1, Y1, X1, Y2);
 SetColor(DarkGray);
 Line(X1 + 1, Y2 - 1, X2 - 1, Y2 - 1);
 Line(X2 - 1, Y1 + 1, X2 - 1, Y2 - 1);
 SetColor(Black);
 Line(X1, Y2, X2, Y2);
 Line(X2, Y1, X2, Y2);
 SetTextStyle(DefaultFont, HorizDir, 1);
 TX := (X1 + X2 - TextWidth(Caption)) Div 2;
 TY := (Y1 + Y2 - TextHeight(Caption)) Div 2;
 SetColor(Black);
 OutTextXY(TX, TY, Caption);
 If Focused Then Begin
  SetColor(Black);
  Rectangle(X1 + 3, Y1 + 3, X2 - 3, Y2 - 3);
 End;
End;

{ boite de dialogue d'OS/2 : bordure epaisse, barre de titre au titre centre }
Procedure DrawDialogBox(X1, Y1, X2, Y2: Integer; Const Title: String);
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(X1, Y1, X2, Y2);
 SetColor(Black);
 Rectangle(X1, Y1, X2, Y2);
 Bevel(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, False);
 Bevel(X1 + 3, Y1 + 3, X2 - 3, Y2 - 3, True);
 SetFillStyle(SolidFill, Blue);
 Bar(X1 + 4, Y1 + 4, X2 - 4, Y1 + 17);
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(White);
 OutTextXY((X1 + X2 - TextWidth(Title)) Div 2, Y1 + 7, Title);
 SetColor(Black);
End;

{ --------------------------------------------------------------------- }
{ Outils : noms, barre d'outils, palette                                }
{ --------------------------------------------------------------------- }

Const
 PAGE_W = 1200;
 PAGE_H = 900;

 ToolName : Array[0..NUM_TOOLS - 1] Of String[30] = (
  'Selection (rectangle)', 'Lasso', 'Main (deplacer la vue)', 'Zoom',
  'Gomme', 'Rotation', 'Liaison simple', 'Liaison double', 'Liaison triple',
  'Liaison coin plein', 'Liaison coin hachure', 'Liaison grasse',
  'Liaison ondulee', 'Liaison pointillee', 'Chaine', 'Texte / etiquette',
  'Cyclopropane', 'Cyclobutane', 'Cyclopentane', 'Cyclohexane',
  'Cycloheptane', 'Cyclooctane', 'Benzene', 'Cyclopentadiene',
  'Fleche de reaction', 'Fleche d''equilibre', 'Fleche de resonance',
  'Fleche retrosynthetique', 'Fleche pointillee', 'Fleche courbe (2 e-)',
  'Fleche courbe (1 e-)', 'Crochets', 'Ligne', 'Rectangle', 'Ellipse',
  'Signe plus', 'Orbitale s', 'Orbitale p', 'Atome');

 TB_NEW = 1;  TB_OPEN = 2;  TB_SAVE = 3;  TB_UNDO = 4;  TB_REDO = 5;
 TB_ZOUT = 6; TB_ZIN = 7;   TB_Z100 = 8;  TB_FIT = 9;
 TB_CHGP = 10; TB_CHGM = 11; TB_PERIOD = 12;
 TB_ATOM0 = 20;
 MAX_TB = 32;

 TbAtoms : Array[0..9] Of Byte = (6, 7, 8, 16, 15, 9, 17, 35, 53, 1);

Var
 StatText : String;
 NTB    : Integer;
 TBId   : Array[0..MAX_TB - 1] Of Integer;
 TBX1   : Array[0..MAX_TB - 1] Of Integer;
 TBX2   : Array[0..MAX_TB - 1] Of Integer;
 TBCap  : Array[0..MAX_TB - 1] Of String[5];
 TBHint : Array[0..MAX_TB - 1] Of String[44];

Procedure AddTB(Id: Integer; Const Cap, Hint: String; Var X: Integer);
Var W: Integer;
Begin
 W := 8 * Length(Cap) + 8;
 If W < 22 Then W := 22;
 TBId[NTB] := Id; TBCap[NTB] := Cap; TBHint[NTB] := Hint;
 TBX1[NTB] := X; TBX2[NTB] := X + W - 1;
 X := X + W + 1;
 Inc(NTB);
End;

Procedure InitToolbar;
Var X, I: Integer;
Begin
 NTB := 0; X := 3;
 AddTB(TB_NEW,  'Nouv', 'Nouveau document', X);
 AddTB(TB_OPEN, 'Ouvr', 'Ouvrir un fichier', X);
 AddTB(TB_SAVE, 'Enr.', 'Enregistrer', X);
 X := X + 5;
 AddTB(TB_UNDO, '<-', 'Annuler (Ctrl+Z)', X);
 AddTB(TB_REDO, '->', 'Retablir (Ctrl+Y)', X);
 X := X + 5;
 AddTB(TB_ZOUT, '-', 'Zoom arriere', X);
 AddTB(TB_ZIN,  '+', 'Zoom avant', X);
 AddTB(TB_Z100, '1:1', 'Zoom 100 %', X);
 AddTB(TB_FIT,  'Fit', 'Ajuster a la fenetre', X);
 X := X + 5;
 For I := 0 To 9 Do
  AddTB(TB_ATOM0 + I, ElSym[TbAtoms[I]], 'Atome ' + ElName[TbAtoms[I]], X);
 AddTB(TB_PERIOD, '...', 'Tableau periodique', X);
 X := X + 5;
 AddTB(TB_CHGP, 'q+', 'Charge positive (selection / survol)', X);
 AddTB(TB_CHGM, 'q-', 'Charge negative (selection / survol)', X);
End;

Procedure DrawToolbar;
Var I, Y1, Y2: Integer; Down: Boolean;
Begin
 Y1 := MENUBAR_H; Y2 := MENUBAR_H + TOOLBAR_H - 1;
 SetFillStyle(SolidFill, LightGray);
 Bar(0, Y1, ScreenWidth - 1, Y2);
 SetColor(DarkGray);
 Line(0, Y2, ScreenWidth - 1, Y2);
 SetTextStyle(DefaultFont, HorizDir, 1);
 For I := 0 To NTB - 1 Do Begin
  Down := (TBId[I] >= TB_ATOM0) And (TBId[I] < TB_ATOM0 + 10) And
          (CurTool = T_ATOM) And (CurElem = TbAtoms[TBId[I] - TB_ATOM0]);
  SetFillStyle(SolidFill, LightGray);
  If Down Then SetFillStyle(SolidFill, LightCyan);
  Bar(TBX1[I], Y1 + 2, TBX2[I], Y2 - 2);
  Bevel(TBX1[I], Y1 + 2, TBX2[I], Y2 - 2, Down);
  SetColor(Black);
  If (TBId[I] >= TB_ATOM0) And (TBId[I] < TB_ATOM0 + 10) And OptColorEl Then
   SetColor(ElColor(TbAtoms[TBId[I] - TB_ATOM0]));
  OutTextXY((TBX1[I] + TBX2[I] - 8 * Length(TBCap[I])) Div 2 + 1, Y1 + 8, TBCap[I]);
 End;
End;

Function ToolbarHit(MX, MY: Integer): Integer;
Var I: Integer;
Begin
 ToolbarHit := -1;
 If (MY < MENUBAR_H) Or (MY >= MENUBAR_H + TOOLBAR_H) Then Exit;
 For I := 0 To NTB - 1 Do
  If (MX >= TBX1[I]) And (MX <= TBX2[I]) Then Begin ToolbarHit := I; Exit; End;
End;

Function PalY: Integer;
Begin
 PalY := MENUBAR_H + TOOLBAR_H;
End;

Procedure ToolRect(T: Integer; Var X1, Y1, X2, Y2: Integer);
Begin
 X1 := (T Mod 3) * BTN_SZ;
 Y1 := PalY + (T Div 3) * BTN_SZ;
 X2 := X1 + BTN_SZ - 1;
 Y2 := Y1 + BTN_SZ - 1;
End;

Function ToolHit(MX, MY: Integer): Integer;
Var T, X1, Y1, X2, Y2: Integer;
Begin
 ToolHit := -1;
 For T := 0 To NUM_TOOLS - 1 Do Begin
  ToolRect(T, X1, Y1, X2, Y2);
  If PtInRect(MX, MY, X1, Y1, X2, Y2) Then Begin ToolHit := T; Exit; End;
 End;
End;

{ Dessine une forme avec des coordonnees ecran (pour les icones) }
Procedure IconShape(AKind: Integer; X1, Y1, X2, Y2: Real);
Var S: TShape; SZ, SSX, SSY: Real;
Begin
 SZ := Zoom; SSX := ScrollX; SSY := ScrollY;
 Zoom := 1; ScrollX := 0; ScrollY := 0;
 S.Kind := AKind; S.X1 := X1; S.Y1 := Y1; S.X2 := X2; S.Y2 := Y2;
 S.CX := (X1 + X2) / 2 + (Y1 - Y2) * 0.4; S.CY := (Y1 + Y2) / 2 + (X2 - X1) * 0.4;
 S.Col := Black; S.Sel := False;
 DrawShapeRec(S, Black);
 Zoom := SZ; ScrollX := SSX; ScrollY := SSY;
End;

Procedure IconBond(Order, Sty, Side: Integer; X, Y: Integer);
Var SZ: Real;
Begin
 SZ := Zoom;
 Zoom := 0.55;
 PaintBond(X + 5, Y + 20, X + 21, Y + 6, Order, Sty, Side, 0, 0, Black, False, False);
 Zoom := SZ;
End;

Procedure IconRing(N: Integer; X, Y: Integer; Inner: Integer);
Var
 P : Array[0..9] Of PointType;
 K : Integer;
 A, R : Real;
 Q : Array[0..9] Of PointType;
Begin
 R := 9;
 For K := 0 To N - 1 Do Begin
  A := -Pi / 2 + K * 2 * Pi / N;
  P[K].X := X + 13 + RoundI(R * Cos(A));
  P[K].Y := Y + 13 + RoundI(R * Sin(A));
  Q[K].X := X + 13 + RoundI((R - 3.5) * Cos(A));
  Q[K].Y := Y + 13 + RoundI((R - 3.5) * Sin(A));
 End;
 P[N] := P[0];
 SetColor(Black);
 DrawPoly(N + 1, P);
 If Inner = 1 Then Begin
  For K := 0 To 2 Do Line(Q[2 * K].X, Q[2 * K].Y, Q[2 * K + 1].X, Q[2 * K + 1].Y);
 End
 Else If Inner = 2 Then Begin
  Line(Q[1].X, Q[1].Y, Q[2].X, Q[2].Y);
  Line(Q[3].X, Q[3].Y, Q[4].X, Q[4].Y);
 End;
End;

Procedure DrawToolIcon(T, X, Y: Integer);
Var CX, CY: Integer; S: String;
Begin
 CX := X + 13; CY := Y + 13;
 SetColor(Black);
 SetLineStyle(SolidLn, 0, NormWidth);
 SetTextStyle(DefaultFont, HorizDir, 1);
 Case T Of
  T_SELECT: Begin
   DDashed(X + 4, Y + 5, X + 20, Y + 5, 2, 2); DDashed(X + 20, Y + 5, X + 20, Y + 20, 2, 2);
   DDashed(X + 20, Y + 20, X + 4, Y + 20, 2, 2); DDashed(X + 4, Y + 20, X + 4, Y + 5, 2, 2);
   FillTri(X + 9, Y + 9, X + 9, Y + 19, X + 17, Y + 15, Black);
  End;
  T_LASSO: Begin
   Ellipse(CX, CY - 2, 0, 360, 8, 5);
   Line(CX - 4, CY + 3, CX - 7, CY + 9);
   Line(CX - 7, CY + 9, CX - 3, CY + 10);
  End;
  T_HAND: Begin
   Rectangle(X + 7, Y + 12, X + 19, Y + 21);
   Line(X + 9, Y + 12, X + 9, Y + 5); Line(X + 12, Y + 12, X + 12, Y + 3);
   Line(X + 15, Y + 12, X + 15, Y + 4); Line(X + 18, Y + 12, X + 18, Y + 7);
   Line(X + 7, Y + 15, X + 4, Y + 12);
  End;
  T_ZOOM: Begin
   Circle(X + 11, Y + 11, 6);
   Line(X + 15, Y + 15, X + 21, Y + 21);
   Line(X + 8, Y + 11, X + 14, Y + 11); Line(X + 11, Y + 8, X + 11, Y + 14);
  End;
  T_ERASER: Begin
   FillTri(X + 5, Y + 15, X + 14, Y + 6, X + 21, Y + 13, LightMagenta);
   FillTri(X + 5, Y + 15, X + 21, Y + 13, X + 12, Y + 22, LightMagenta);
   SetColor(Black);
   Line(X + 5, Y + 15, X + 14, Y + 6); Line(X + 14, Y + 6, X + 21, Y + 13);
   Line(X + 21, Y + 13, X + 12, Y + 22); Line(X + 12, Y + 22, X + 5, Y + 15);
  End;
  T_ROTATE: Begin
   Arc(CX, CY, 40, 320, 8);
   FillTri(CX + 6, CY - 6, CX + 12, CY - 7, CX + 9, CY - 1, Black);
  End;
  T_BOND:   IconBond(1, ST_NORMAL, 0, X, Y);
  T_DOUBLE: IconBond(2, ST_NORMAL, 0, X, Y);
  T_TRIPLE: IconBond(3, ST_NORMAL, 0, X, Y);
  T_WEDGE:  IconBond(1, ST_WEDGE, 0, X, Y);
  T_HASH:   IconBond(1, ST_HASH, 0, X, Y);
  T_BOLD:   IconBond(1, ST_BOLD, 0, X, Y);
  T_WAVY:   IconBond(1, ST_WAVY, 0, X, Y);
  T_DASH:   IconBond(1, ST_DASH, 0, X, Y);
  T_CHAIN: Begin
   Line(X + 3, Y + 17, X + 8, Y + 9); Line(X + 8, Y + 9, X + 13, Y + 17);
   Line(X + 13, Y + 17, X + 18, Y + 9); Line(X + 18, Y + 9, X + 23, Y + 17);
  End;
  T_TEXT: Begin
   SetTextStyle(DefaultFont, HorizDir, 2);
   OutTextXY(X + 5, Y + 5, 'A');
   SetTextStyle(DefaultFont, HorizDir, 1);
  End;
  T_RING3: IconRing(3, X, Y, 0);
  T_RING4: IconRing(4, X, Y, 0);
  T_RING5: IconRing(5, X, Y, 0);
  T_RING6: IconRing(6, X, Y, 0);
  T_RING7: IconRing(7, X, Y, 0);
  T_RING8: IconRing(8, X, Y, 0);
  T_BENZENE: IconRing(6, X, Y, 1);
  T_CPD:   IconRing(5, X, Y, 2);
  T_ARROW:   IconShape(SH_ARROW,   X + 3, Y + 13, X + 23, Y + 13);
  T_EQUIL:   IconShape(SH_EQUIL,   X + 3, Y + 13, X + 23, Y + 13);
  T_RESON:   IconShape(SH_RESON,   X + 3, Y + 13, X + 23, Y + 13);
  T_RETRO:   IconShape(SH_RETRO,   X + 3, Y + 13, X + 23, Y + 13);
  T_DASHARR: IconShape(SH_DASHARR, X + 3, Y + 13, X + 23, Y + 13);
  T_CURVE2:  IconShape(SH_CURVE2,  X + 4, Y + 20, X + 22, Y + 20);
  T_CURVE1:  IconShape(SH_CURVE1,  X + 4, Y + 20, X + 22, Y + 20);
  T_BRACKET: IconShape(SH_BRACKET, X + 5, Y + 5, X + 21, Y + 21);
  T_LINE:    IconShape(SH_LINE,    X + 4, Y + 21, X + 22, Y + 5);
  T_RECT:    IconShape(SH_RECT,    X + 4, Y + 6, X + 22, Y + 20);
  T_ELLIPSE: IconShape(SH_ELLIPSE, X + 3, Y + 6, X + 23, Y + 20);
  T_PLUS: Begin
   Line(X + 6, CY, X + 20, CY); Line(CX, Y + 6, CX, Y + 20);
  End;
  T_ORBS: Circle(CX, CY, 8);
  T_ORBP: IconShape(SH_ORBP, X + 13, Y + 13, X + 13, Y + 25);
  T_ATOM: Begin
   S := ElSym[CurElem];
   OutTextXY(CX - 4 * Length(S), CY - 4, S);
  End;
 End;
End;

Procedure DrawPalette;
Var
 T, X1, Y1, X2, Y2, I, SX1, SY1 : Integer;
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(0, PalY, PAL_W - 1, ScreenHeight - STATUS_H - 1);
 For T := 0 To NUM_TOOLS - 1 Do Begin
  ToolRect(T, X1, Y1, X2, Y2);
  If T = CurTool Then SetFillStyle(SolidFill, LightCyan)
  Else SetFillStyle(SolidFill, LightGray);
  Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
  Bevel(X1, Y1, X2, Y2, T = CurTool);
  DrawToolIcon(T, X1, Y1);
 End;
 { echantillons de couleurs }
 SY1 := PalY + 13 * BTN_SZ + 6;
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(DarkGray);
 OutTextXY(4, SY1, 'Couleur');
 For I := 0 To 15 Do Begin
  SX1 := 5 + (I Mod 4) * 17;
  Y1 := SY1 + 12 + (I Div 4) * 14;
  SetFillStyle(SolidFill, I);
  Bar(SX1, Y1, SX1 + 14, Y1 + 11);
  If I = CurColor Then SetColor(White) Else SetColor(DarkGray);
  Rectangle(SX1 - 1, Y1 - 1, SX1 + 15, Y1 + 12);
  If I = CurColor Then Begin
   SetColor(Black);
   Rectangle(SX1 - 2, Y1 - 2, SX1 + 16, Y1 + 13);
  End;
 End;
End;

Function SwatchHit(MX, MY: Integer): Integer;
Var I, SX1, SY1, Y1: Integer;
Begin
 SwatchHit := -1;
 SY1 := PalY + 13 * BTN_SZ + 6;
 For I := 0 To 15 Do Begin
  SX1 := 5 + (I Mod 4) * 17;
  Y1 := SY1 + 12 + (I Div 4) * 14;
  If PtInRect(MX, MY, SX1, Y1, SX1 + 14, Y1 + 11) Then Begin SwatchHit := I; Exit; End;
 End;
End;

{ --------------------------------------------------------------------- }
{ Barres de defilement                                                  }
{ --------------------------------------------------------------------- }

Var
 ExtX1, ExtY1, ExtX2, ExtY2 : Real;

Procedure ComputeExtents;
Var X1, Y1, X2, Y2: Real; Empty: Boolean;
Begin
 ExtX1 := -60; ExtY1 := -60; ExtX2 := PAGE_W + 60; ExtY2 := PAGE_H + 60;
 DocBounds(False, X1, Y1, X2, Y2, Empty);
 If Not Empty Then Begin
  If X1 - 80 < ExtX1 Then ExtX1 := X1 - 80;
  If Y1 - 80 < ExtY1 Then ExtY1 := Y1 - 80;
  If X2 + 80 > ExtX2 Then ExtX2 := X2 + 80;
  If Y2 + 80 > ExtY2 Then ExtY2 := Y2 + 80;
 End;
End;

Procedure ClampScroll;
Var VW, VH, MaxX, MaxY: Real;
Begin
 ComputeExtents;
 VW := (CvX2 - CvX1 + 1) / Zoom;
 VH := (CvY2 - CvY1 + 1) / Zoom;
 MaxX := ExtX2 - VW; If MaxX < ExtX1 Then MaxX := ExtX1;
 MaxY := ExtY2 - VH; If MaxY < ExtY1 Then MaxY := ExtY1;
 ScrollX := ClampR(ScrollX, ExtX1, MaxX);
 ScrollY := ClampR(ScrollY, ExtY1, MaxY);
End;

{ Geometrie des pouces : renvoie debut et fin en pixels sur la piste }
Procedure ThumbH(Var T1, T2, TrackLo, TrackHi: Integer);
Var VW, Span, F1, F2: Real;
Begin
 ComputeExtents;
 VW := (CvX2 - CvX1 + 1) / Zoom;
 TrackLo := CvX1 + SCROLL_W; TrackHi := CvX2 - SCROLL_W;
 Span := ExtX2 - ExtX1;
 F1 := (ScrollX - ExtX1) / Span; F2 := (ScrollX + VW - ExtX1) / Span;
 F1 := ClampR(F1, 0, 1); F2 := ClampR(F2, 0, 1);
 T1 := TrackLo + RoundI(F1 * (TrackHi - TrackLo));
 T2 := TrackLo + RoundI(F2 * (TrackHi - TrackLo));
 If T2 - T1 < 12 Then T2 := T1 + 12;
 If T2 > TrackHi Then Begin T2 := TrackHi; T1 := T2 - 12; End;
End;

Procedure ThumbV(Var T1, T2, TrackLo, TrackHi: Integer);
Var VH, Span, F1, F2: Real;
Begin
 ComputeExtents;
 VH := (CvY2 - CvY1 + 1) / Zoom;
 TrackLo := CvY1 + SCROLL_W; TrackHi := CvY2 - SCROLL_W;
 Span := ExtY2 - ExtY1;
 F1 := (ScrollY - ExtY1) / Span; F2 := (ScrollY + VH - ExtY1) / Span;
 F1 := ClampR(F1, 0, 1); F2 := ClampR(F2, 0, 1);
 T1 := TrackLo + RoundI(F1 * (TrackHi - TrackLo));
 T2 := TrackLo + RoundI(F2 * (TrackHi - TrackLo));
 If T2 - T1 < 12 Then T2 := T1 + 12;
 If T2 > TrackHi Then Begin T2 := TrackHi; T1 := T2 - 12; End;
End;

Procedure DrawScrollBars;
Var T1, T2, Lo, Hi: Integer;
Begin
 { horizontale }
 SetFillStyle(SolidFill, LightGray);
 Bar(CvX1, CvY2 + 1, CvX2 + SCROLL_W, CvY2 + SCROLL_W);
 DrawButton(CvX1, CvY2 + 1, CvX1 + SCROLL_W - 1, CvY2 + SCROLL_W, '<', False);
 DrawButton(CvX2 - SCROLL_W + 1, CvY2 + 1, CvX2, CvY2 + SCROLL_W, '>', False);
 ThumbH(T1, T2, Lo, Hi);
 SetFillStyle(SolidFill, White);
 Bar(Lo, CvY2 + 2, Hi, CvY2 + SCROLL_W - 1);
 DrawButton(T1, CvY2 + 1, T2, CvY2 + SCROLL_W, '', False);
 { verticale }
 SetFillStyle(SolidFill, LightGray);
 Bar(CvX2 + 1, CvY1, CvX2 + SCROLL_W, CvY2 + SCROLL_W);
 DrawButton(CvX2 + 1, CvY1, CvX2 + SCROLL_W, CvY1 + SCROLL_W - 1, '^', False);
 DrawButton(CvX2 + 1, CvY2 - SCROLL_W + 1, CvX2 + SCROLL_W, CvY2, 'v', False);
 ThumbV(T1, T2, Lo, Hi);
 SetFillStyle(SolidFill, White);
 Bar(CvX2 + 2, Lo, CvX2 + SCROLL_W - 1, Hi);
 DrawButton(CvX2 + 1, T1, CvX2 + SCROLL_W, T2, '', False);
 SetFillStyle(SolidFill, LightGray);
 Bar(CvX2 + 1, CvY2 + 1, CvX2 + SCROLL_W, CvY2 + SCROLL_W);
End;

{ --------------------------------------------------------------------- }
{ Aides de dessin : accrochage, chaine                                  }
{ --------------------------------------------------------------------- }

Function SnapGrid(V: Real): Real;
Begin
 If OptSnap Then SnapGrid := Round(V / GRID_STEP) * GRID_STEP
 Else SnapGrid := V;
End;

Procedure SnapEnd(X0, Y0, MX, MY, AngStep: Real; FixLen: Boolean; Var EX, EY: Real);
Var A, L: Real;
Begin
 L := Dist(X0, Y0, MX, MY);
 If L < 0.5 Then Begin EX := X0; EY := Y0; Exit; End;
 A := Atan2(MY - Y0, MX - X0);
 If OptFixAng Then A := Round(A / AngStep) * AngStep;
 If FixLen Then L := BOND_LEN;
 EX := X0 + L * Cos(A);
 EY := Y0 + L * Sin(A);
End;

Const
 MAX_CHAIN = 40;

Var
 ChainX, ChainY : Array[0..MAX_CHAIN] Of Real;

{ Calcule les points d'une chaine en zigzag ; renvoie le nombre de liaisons }
Function ChainPoints(X0, Y0, MX, MY: Real): Integer;
Var
 L, Phi, A, S : Real;
 N, K : Integer;
Begin
 L := Dist(X0, Y0, MX, MY);
 Phi := Atan2(MY - Y0, MX - X0);
 If OptFixAng Then Phi := Round(Phi / (Pi / 6)) * (Pi / 6);
 N := Round(L / (BOND_LEN * 0.866));
 If N < 1 Then N := 1;
 If N > MAX_CHAIN Then N := MAX_CHAIN;
 ChainX[0] := X0; ChainY[0] := Y0;
 S := -1;
 For K := 1 To N Do Begin
  A := Phi + S * Pi / 6;
  ChainX[K] := ChainX[K - 1] + BOND_LEN * Cos(A);
  ChainY[K] := ChainY[K - 1] + BOND_LEN * Sin(A);
  S := -S;
 End;
 ChainPoints := N;
End;

{ --------------------------------------------------------------------- }
{ Dessin du canevas                                                     }
{ --------------------------------------------------------------------- }

Procedure DrawGrid;
Var X, Y, X0, Y0, GX, GY: Real; PXi, PYi: Integer; W, H: Integer; St: Real;
Begin
 W := CvX2 - CvX1; H := CvY2 - CvY1;
 St := GRID_STEP * Zoom;
 If St < 6 Then Exit;
 GX := Trunc(ScrollX / GRID_STEP) * GRID_STEP;
 GY := Trunc(ScrollY / GRID_STEP) * GRID_STEP;
 X0 := GX; Y0 := GY;
 Y := Y0;
 While SYr(Y) <= H Do Begin
  X := X0;
  PYi := SY(Y);
  While SXr(X) <= W Do Begin
   PXi := SX(X);
   If (PXi >= 0) And (PYi >= 0) Then Begin
    If OptDark Then PutPixel(PXi, PYi, DarkGray) Else PutPixel(PXi, PYi, LightGray);
   End;
   X := X + GRID_STEP;
  End;
  Y := Y + GRID_STEP;
 End;
End;

{ Couleur effective dans le canevas (le noir devient blanc en mode sombre) }
Function CF(Col: Byte): Byte;
Begin
 If OptDark And (Col = Black) Then CF := White Else CF := Col;
End;

Function AtomColorOf(I: Integer): Byte;
Begin
 If OptColorEl And (At^[I].Col = Black) And (At^[I].Z > 0) Then
  AtomColorOf := CF(ElColor(At^[I].Z))
 Else AtomColorOf := CF(At^[I].Col);
End;

Procedure DrawPreview;
Var
 EX, EY, SXa, SYa : Real;
 K, N : Integer;
 S : TShape;
 TS: String;
 Px, Py: Real;
Begin
 Case DragKind Of
  DR_BOND: Begin
   If DragAtom >= 0 Then Begin SXa := At^[DragAtom].X; SYa := At^[DragAtom].Y; End
   Else Begin SXa := DragSX; SYa := DragSY; End;
   If (HovAtom >= 0) And (HovAtom <> DragAtom) Then Begin
    EX := At^[HovAtom].X; EY := At^[HovAtom].Y;
   End
   Else SnapEnd(SXa, SYa, DragLX, DragLY, Pi / 6, OptFixLen, EX, EY);
   Case CurTool Of
    T_DOUBLE: PaintBond(SXr(SXa), SYr(SYa), SXr(EX), SYr(EY), 2, ST_NORMAL, 0, 0, 0, DarkGray, False, False);
    T_TRIPLE: PaintBond(SXr(SXa), SYr(SYa), SXr(EX), SYr(EY), 3, ST_NORMAL, 0, 0, 0, DarkGray, False, False);
    T_WEDGE:  PaintBond(SXr(SXa), SYr(SYa), SXr(EX), SYr(EY), 1, ST_WEDGE, 0, 0, 0, DarkGray, False, False);
    T_HASH:   PaintBond(SXr(SXa), SYr(SYa), SXr(EX), SYr(EY), 1, ST_HASH, 0, 0, 0, DarkGray, False, False);
    T_BOLD:   PaintBond(SXr(SXa), SYr(SYa), SXr(EX), SYr(EY), 1, ST_BOLD, 0, 0, 0, DarkGray, False, False);
    T_WAVY:   PaintBond(SXr(SXa), SYr(SYa), SXr(EX), SYr(EY), 1, ST_WAVY, 0, 0, 0, DarkGray, False, False);
    T_DASH:   PaintBond(SXr(SXa), SYr(SYa), SXr(EX), SYr(EY), 1, ST_DASH, 0, 0, 0, DarkGray, False, False);
   Else
    PaintBond(SXr(SXa), SYr(SYa), SXr(EX), SYr(EY), 1, ST_NORMAL, 0, 0, 0, DarkGray, False, False);
   End;
  End;
  DR_CHAIN: Begin
   If DragAtom >= 0 Then Begin Px := At^[DragAtom].X; Py := At^[DragAtom].Y; End
   Else Begin Px := DragSX; Py := DragSY; End;
   N := ChainPoints(Px, Py, DragLX, DragLY);
   SetColor(DarkGray);
   For K := 1 To N Do DLine(SXr(ChainX[K - 1]), SYr(ChainY[K - 1]), SXr(ChainX[K]), SYr(ChainY[K]));
   SetTextStyle(DefaultFont, HorizDir, 1);
   SetColor(Blue);
   TS := IntToStr(N);
   OutTextXY(SX(ChainX[N]) + 6, SY(ChainY[N]) - 4, TS);
  End;
  DR_SHAPE: Begin
   S.Kind := CurTool - T_ARROW + SH_ARROW;
   Case CurTool Of
    T_BRACKET: S.Kind := SH_BRACKET;
    T_LINE: S.Kind := SH_LINE;
    T_RECT: S.Kind := SH_RECT;
    T_ELLIPSE: S.Kind := SH_ELLIPSE;
    T_ORBS: S.Kind := SH_ORBS;
    T_ORBP: S.Kind := SH_ORBP;
   End;
   S.X1 := DragSX; S.Y1 := DragSY; S.X2 := DragLX; S.Y2 := DragLY;
   S.CX := (S.X1 + S.X2) / 2 + (S.Y1 - S.Y2) * 0.35;
   S.CY := (S.Y1 + S.Y2) / 2 + (S.X2 - S.X1) * 0.35;
   DrawShapeRec(S, DarkGray);
  End;
  DR_MARQUEE: Begin
   SetColor(Blue);
   DDashed(SXr(DragSX), SYr(DragSY), SXr(DragLX), SYr(DragSY), 3, 2);
   DDashed(SXr(DragLX), SYr(DragSY), SXr(DragLX), SYr(DragLY), 3, 2);
   DDashed(SXr(DragLX), SYr(DragLY), SXr(DragSX), SYr(DragLY), 3, 2);
   DDashed(SXr(DragSX), SYr(DragLY), SXr(DragSX), SYr(DragSY), 3, 2);
  End;
  DR_LASSO: Begin
   SetColor(Blue);
   For K := 1 To DragNPts - 1 Do
    Line(DragPts[2 * K - 2], DragPts[2 * K - 1], DragPts[2 * K], DragPts[2 * K + 1]);
  End;
  DR_ZOOMBOX: Begin
   SetColor(Red);
   Rectangle(SX(DragSX), SY(DragSY), SX(DragLX), SY(DragLY));
  End;
 End;
End;

Procedure EnsureStereo; Forward;

{ Direction (unitaire) du plus grand espace libre autour de l'atome I }
Procedure FreeDir(I: Integer; Var DX, DY: Real);
Var
 K, N, J : Integer;
 Ang : Array[0..8] Of Real;
 T, Gap, BestGap, Mid : Real;
Begin
 N := AdjN^[I];
 If N > 8 Then N := 8;
 DX := 0; DY := -1;
 If N = 0 Then Exit;
 For K := 0 To N - 1 Do
  Ang[K] := Atan2(At^[Adj^[I, K]].Y - At^[I].Y, At^[Adj^[I, K]].X - At^[I].X);
 For K := 1 To N - 1 Do Begin
  T := Ang[K]; J := K - 1;
  While (J >= 0) And (Ang[J] > T) Do Begin Ang[J + 1] := Ang[J]; Dec(J); End;
  Ang[J + 1] := T;
 End;
 Ang[N] := Ang[0] + 2 * Pi;
 BestGap := -1; Mid := 0;
 For K := 0 To N - 1 Do Begin
  Gap := Ang[K + 1] - Ang[K];
  If Gap > BestGap Then Begin BestGap := Gap; Mid := (Ang[K] + Ang[K + 1]) / 2; End;
 End;
 DX := Cos(Mid); DY := Sin(Mid);
End;

Procedure DrawCanvas;
Var
 I, J, A, B, X, Y, R : Integer;
 Col : Byte;
 X1, Y1, X2, Y2 : Integer;
 DX, DY, DL : Real;
Begin
 UpdateInfo;
 If OptStereo Then EnsureStereo;
 If Zoom >= 2.4 Then TxtScale := 3
 Else If Zoom >= 1.45 Then TxtScale := 2
 Else TxtScale := 1;
 SetViewPort(CvX1, CvY1, CvX2, CvY2, True);
 If OptDark Then SetFillStyle(SolidFill, Black) Else SetFillStyle(SolidFill, White);
 Bar(0, 0, CvX2 - CvX1, CvY2 - CvY1);
 If OptGrid Then DrawGrid;
 { limites de la page }
 If OptDark Then SetColor(DarkGray) Else SetColor(LightGray);
 Rectangle(SX(0), SY(0), SX(PAGE_W), SY(PAGE_H));
 SetLineStyle(SolidLn, 0, NormWidth);
 { formes }
 For I := 0 To NSh - 1 Do Begin
  If Sh^[I].Sel Then DrawShapeRec(Sh^[I], LightBlue);
  DrawShapeRec(Sh^[I], CF(Sh^[I].Col));
 End;
 { surbrillance : liaisons et atomes selectionnes / survoles }
 For J := 0 To NBd - 1 Do Begin
  A := Bd^[J].A; B := Bd^[J].B;
  If (At^[A].Sel And At^[B].Sel) Or (J = HovBond) Then Begin
   If J = HovBond Then Col := LightCyan Else Col := LightBlue;
   SetColor(Col);
   SetLineStyle(SolidLn, 0, ThickWidth);
   Line(SX(At^[A].X), SY(At^[A].Y), SX(At^[B].X), SY(At^[B].Y));
   SetLineStyle(SolidLn, 0, NormWidth);
  End;
 End;
 For I := 0 To NAt - 1 Do Begin
  If At^[I].Sel Or (I = HovAtom) Then Begin
   If At^[I].Sel Then SetFillStyle(SolidFill, LightBlue)
   Else SetFillStyle(SolidFill, LightCyan);
   R := 5 + 2 * TxtScale;
   SetColor(LightBlue);
   FillEllipse(SX(At^[I].X), SY(At^[I].Y), R, R);
  End;
 End;
 { liaisons }
 For J := 0 To NBd - 1 Do Begin
  Col := CF(Bd^[J].Col);
  DrawBond(J, Col);
 End;
 { etiquettes }
 For I := 0 To NAt - 1 Do Begin
  X := SX(At^[I].X); Y := SY(At^[I].Y);
  If (X < -40) Or (Y < -40) Or (X > CvX2 - CvX1 + 40) Or (Y > CvY2 - CvY1 + 40) Then Continue;
  If LabelVisible(I) Then DrawAtomLabel(I, X, Y, AtomColorOf(I));
  If OptWarn And Inf^[I].Warn Then Begin
   SetColor(Red);
   Rectangle(X - 6 * TxtScale - 2, Y - 6 * TxtScale - 2, X + 6 * TxtScale + 2, Y + 6 * TxtScale + 2);
  End;
  If OptNumbers Then Begin
   SetTextStyle(DefaultFont, HorizDir, 1);
   If OptDark Then SetColor(LightGray) Else SetColor(DarkGray);
   OutTextXY(X + 5, Y - 12, IntToStr(I + 1));
  End;
  If OptStereo And (StC^[I] <> #0) Then Begin
   SetTextStyle(DefaultFont, HorizDir, 1);
   If OptDark Then SetColor(LightRed) Else SetColor(Red);
   FreeDir(I, DX, DY);
   OutTextXY(X + Round(DX * (13 + 5 * TxtScale)) - 12, Y + Round(DY * (11 + 4 * TxtScale)) - 4,
             '(' + StC^[I] + ')');
  End;
 End;
 If OptStereo Then
  For J := 0 To NBd - 1 Do
   If EzC^[J] <> #0 Then Begin
    A := Bd^[J].A; B := Bd^[J].B;
    X := SX((At^[A].X + At^[B].X) / 2); Y := SY((At^[A].Y + At^[B].Y) / 2);
    DX := -(At^[B].Y - At^[A].Y); DY := At^[B].X - At^[A].X;
    DL := Sqrt(DX * DX + DY * DY);
    If DL < 0.1 Then DL := 1;
    SetTextStyle(DefaultFont, HorizDir, 1);
    If OptDark Then SetColor(LightRed) Else SetColor(Red);
    OutTextXY(X + Round(DX / DL * (14 + 3 * TxtScale)) - 12, Y + Round(DY / DL * (12 + 3 * TxtScale)) - 4,
              '(' + EzC^[J] + ')');
   End;
 { textes }
 For I := 0 To NTx - 1 Do Begin
  TextRectScreen(I, X1, Y1, X2, Y2);
  If Tx^[I].Sel Then Begin
   SetFillStyle(SolidFill, LightBlue);
   Bar(X1 - 2, Y1 - 2, X2 + 2, Y2 + 2);
  End;
  SetTextStyle(DefaultFont, HorizDir, Tx^[I].Siz * TxtScale);
  SetColor(CF(Tx^[I].Col));
  OutTextXY(X1, Y1, Tx^[I].S);
 End;
 SetTextStyle(DefaultFont, HorizDir, 1);
 { poignees des formes selectionnees }
 For I := 0 To NSh - 1 Do
  If Sh^[I].Sel Then Begin
   ShapeHandlePos(I, 0, X, Y); DrawHandle(X, Y);
   ShapeHandlePos(I, 1, X, Y); DrawHandle(X, Y);
   If Sh^[I].Kind In [SH_CURVE1, SH_CURVE2] Then Begin
    ShapeHandlePos(I, 2, X, Y); DrawHandle(X, Y);
   End;
  End;
 DrawPreview;
 SetViewPort(0, 0, ScreenWidth - 1, ScreenHeight - 1, True);
End;

{ --------------------------------------------------------------------- }
{ Barre de menus                                                        }
{ --------------------------------------------------------------------- }

Procedure LayoutMenuBar;
Var I, X, W : Integer;
Begin
 X := 6;
 For I := 0 To NUM_MENUS - 1 Do Begin
  W := 8 * Length(Menus[I].Title);
  Menus[I].X := X;
  Menus[I].Y := 0;
  X := X + W + 14;
 End;
 MenuBarHeight := MENUBAR_H;
End;

Procedure DrawMenuBar;
Var
 I, W : Integer;
Begin
 LayoutMenuBar;
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetFillStyle(SolidFill, LightGray);
 Bar(0, 0, ScreenWidth - 1, MenuBarHeight - 1);
 SetColor(DarkGray);
 Line(0, MenuBarHeight - 1, ScreenWidth - 1, MenuBarHeight - 1);
 For I := 0 To NUM_MENUS - 1 Do Begin
  W := 8 * Length(Menus[I].Title);
  If MenuActive And (ActiveMenu = I) Then Begin
   SetFillStyle(SolidFill, Blue);
   Bar(Menus[I].X - 3, Menus[I].Y + 2, Menus[I].X + W + 3, Menus[I].Y + MENUBAR_H - 3);
   SetColor(White);
  End
  Else SetColor(Black);
  OutTextXY(Menus[I].X, Menus[I].Y + 6, Menus[I].Title);
 End;
End;

Procedure DrawMenuPopup(MenuIdx: Integer);
Var
 I, ItemHeight, X, Y, W, H, Wmax, WSc : Integer;
 Cap, Sc : String;
Begin
 If (MenuIdx < 0) Or (MenuIdx >= NUM_MENUS) Then Exit;
 SetTextStyle(DefaultFont, HorizDir, 1);
 ItemHeight := 16;
 Wmax := 0;
 For I := 0 To Menus[MenuIdx].ItemCount - 1 Do Begin
  Cap := Menus[MenuIdx].Items[I].Caption;
  Sc  := Menus[MenuIdx].Items[I].Shortcut;
  W := TextWidth(Cap) + 30 + TextWidth(Sc) + 12;
  If W > Wmax Then Wmax := W;
 End;
 If Wmax < 180 Then Wmax := 180;
 Menus[MenuIdx].Width := Wmax;
 X := Menus[MenuIdx].X - 3;
 Y := Menus[MenuIdx].Y + MENUBAR_H;
 W := Wmax;
 H := Menus[MenuIdx].ItemCount * ItemHeight + 4;
 If X + W >= ScreenWidth Then X := ScreenWidth - W - 2;
 SetFillStyle(SolidFill, LightGray);
 Bar(X, Y, X + W, Y + H);
 SetColor(White);
 Line(X, Y, X + W, Y); Line(X, Y, X, Y + H);
 SetColor(DarkGray);
 Line(X + W, Y, X + W, Y + H); Line(X, Y + H, X + W, Y + H);
 SetColor(Black);
 Line(X + W + 1, Y + 1, X + W + 1, Y + H + 1);
 Line(X + 1, Y + H + 1, X + W + 1, Y + H + 1);
 For I := 0 To Menus[MenuIdx].ItemCount - 1 Do Begin
  If Menus[MenuIdx].Items[I].Separator Then Begin
   SetColor(DarkGray);
   Line(X + 4, Y + 2 + I * ItemHeight + ItemHeight Div 2,
        X + W - 4, Y + 2 + I * ItemHeight + ItemHeight Div 2);
  End
  Else Begin
   If ActiveMenuItem = I Then Begin
    SetFillStyle(SolidFill, Blue);
    Bar(X + 2, Y + 2 + I * ItemHeight, X + W - 2, Y + 2 + (I + 1) * ItemHeight);
    SetColor(White);
   End
   Else Begin
    If Menus[MenuIdx].Items[I].Enabled Then SetColor(Black)
    Else SetColor(DarkGray);
   End;
   If Menus[MenuIdx].Items[I].Checked Then
    OutTextXY(X + 5, Y + 4 + I * ItemHeight, #251);
   OutTextXY(X + 22, Y + 4 + I * ItemHeight, Menus[MenuIdx].Items[I].Caption);
   Sc := Menus[MenuIdx].Items[I].Shortcut;
   If Sc <> '' Then Begin
    WSc := TextWidth(Sc);
    OutTextXY(X + W - WSc - 8, Y + 4 + I * ItemHeight, Sc);
   End;
  End;
 End;
End;

Function MenuBarHitTest(Mx, My: Integer): Integer;
Var I, X1, X2: Integer;
Begin
 MenuBarHitTest := -1;
 If My >= MenuBarHeight Then Exit;
 For I := 0 To NUM_MENUS - 1 Do Begin
  X1 := Menus[I].X - 3;
  X2 := Menus[I].X + 8 * Length(Menus[I].Title) + 3;
  If (Mx >= X1) And (Mx <= X2) Then Begin
   MenuBarHitTest := I; Exit;
  End;
 End;
End;

Function MenuItemHitTest(Mx, My, MenuIdx: Integer): Integer;
Var Idx, Top, Bot, X, W: Integer;
Begin
 MenuItemHitTest := -1;
 If (MenuIdx < 0) Or (MenuIdx >= NUM_MENUS) Then Exit;
 Top := Menus[MenuIdx].Y + MENUBAR_H;
 Bot := Top + Menus[MenuIdx].ItemCount * 16 + 4;
 X := Menus[MenuIdx].X - 3;
 W := Menus[MenuIdx].Width;
 If X + W >= ScreenWidth Then X := ScreenWidth - W - 2;
 If (Mx < X) Or (Mx > X + W) Or (My < Top) Or (My > Bot) Then Exit;
 Idx := (My - Top - 2) Div 16;
 If (Idx < 0) Or (Idx >= Menus[MenuIdx].ItemCount) Then Exit;
 MenuItemHitTest := Idx;
End;

Procedure MenuNextItem(Step: Integer);
Var N, I: Integer;
Begin
 If (ActiveMenu < 0) Or (ActiveMenu >= NUM_MENUS) Then Exit;
 N := Menus[ActiveMenu].ItemCount;
 If N <= 0 Then Exit;
 If ActiveMenuItem < 0 Then Begin
  If Step > 0 Then ActiveMenuItem := -1 Else ActiveMenuItem := N;
 End;
 For I := 1 To N Do Begin
  ActiveMenuItem := ActiveMenuItem + Step;
  If ActiveMenuItem < 0 Then ActiveMenuItem := N - 1;
  If ActiveMenuItem >= N Then ActiveMenuItem := 0;
  If Not Menus[ActiveMenu].Items[ActiveMenuItem].Separator Then Exit;
 End;
End;

{ --------------------------------------------------------------------- }
{ Barre d'etat et fenetre d'analyse                                     }
{ --------------------------------------------------------------------- }

Procedure UpdateProps; Forward;

Procedure DrawStatusBar;
Var Y, X: Integer; S: String;
Begin
 Y := ScreenHeight - STATUS_H;
 SetFillStyle(SolidFill, LightGray);
 Bar(0, Y, ScreenWidth - 1, ScreenHeight - 1);
 SetColor(DarkGray);
 Line(0, Y, ScreenWidth - 1, Y);
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(Black);
 If StatusMsg <> '' Then S := StatusMsg
 Else S := ToolName[CurTool];
 OutTextXY(6, Y + 5, Copy(S, 1, 48));
 { formule et poids moleculaire }
 S := StatText;
 X := ScreenWidth - 8 * Length(S) - 6;
 If X < 6 + 8 * 40 Then X := 6 + 8 * 40;
 SetColor(Blue);
 OutTextXY(X, Y + 5, Copy(S, 1, (ScreenWidth - X) Div 8));
End;

Procedure DrawAnalysisWindow;
Var X1, Y1, X2, Y2, I: Integer;
Begin
 If Not OptAnalysis Then Exit;
 X2 := CvX2 - 4; X1 := X2 - 312; Y1 := CvY1 + 4; Y2 := Y1 + 84;
 SetFillStyle(SolidFill, LightGray);
 Bar(X1, Y1, X2, Y2);
 Bevel(X1, Y1, X2, Y2, False);
 SetFillStyle(SolidFill, Blue);
 Bar(X1 + 1, Y1 + 1, X2 - 1, Y1 + 11);
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(White);
 OutTextXY(X1 + 4, Y1 + 2, 'Proprietes chimiques');
 SetColor(Black);
 For I := 0 To 5 Do Begin
  If I = 5 Then Break;
  OutTextXY(X1 + 5, Y1 + 15 + I * 13, Copy(PropText[I], 1, 38));
 End;
End;

Procedure RedrawAll;
Begin
 If PropDirty Then UpdateProps;
 HideMouseCursor;
 DrawCanvas;
 DrawScrollBars;
 DrawPalette;
 DrawToolbar;
 DrawAnalysisWindow;
 DrawStatusBar;
 DrawMenuBar;
 If MenuActive Then DrawMenuPopup(ActiveMenu);
 ShowMouseCursor;
 NeedRedraw := False;
End;

{ --------------------------------------------------------------------- }
{ Boites de dialogue                                                   }
{ --------------------------------------------------------------------- }

Const
 MAX_TL = 300;

Var
 DlgOldLeft : Boolean;
 DlgHappened : Boolean;
 TLines     : Array[0..MAX_TL - 1] Of String[72];
 NTL        : Integer;

Procedure DlgBegin;
Var K: Char;
Begin
 While KeyPressed Do Begin
  K := ReadKey;
  If K = #0 Then If KeyPressed Then K := ReadKey;
 End;
 GetMouseLocal(MouseX, MouseY, MouseButtons);
 DlgOldLeft := (MouseButtons And 1) <> 0;
End;

{ Interroge clavier et souris. Key : 0=rien, 1..255=ASCII, 256+code=touche etendue }
Function DlgPoll(Var Key, MX, MY: Integer; Var Click: Boolean): Boolean;
Var K: Char; L: Boolean;
Begin
 Key := 0; Click := False;
 If KeyPressed Then Begin
  K := ReadKey;
  If K = #0 Then Begin
   If KeyPressed Then Begin K := ReadKey; Key := 256 + Ord(K); End;
  End
  Else Key := Ord(K);
 End;
 GetMouseLocal(MouseX, MouseY, MouseButtons);
 MX := MouseX; MY := MouseY;
 L := (MouseButtons And 1) <> 0;
 Click := L And Not DlgOldLeft;
 DlgOldLeft := L;
 DlgPoll := (Key <> 0) Or Click;
End;

Procedure DlgEnd;
Begin
 DlgHappened := True;
 OldMouseButtons := MouseButtons;
 OldMouseX := MouseX; OldMouseY := MouseY;
 NeedRedraw := True;
End;

Function WordLine(Const S: String; N: Integer): String;
{ N-ieme segment (base 1) d'une chaine separee par '|' }
Var I, K, St: Integer;
Begin
 K := 1; St := 1;
 For I := 1 To Length(S) + 1 Do Begin
  If (I > Length(S)) Or (S[I] = '|') Then Begin
   If K = N Then Begin WordLine := Copy(S, St, I - St); Exit; End;
   Inc(K); St := I + 1;
  End;
 End;
 WordLine := '';
End;

Function CountLines(Const S: String): Integer;
Var I, N: Integer;
Begin
 N := 1;
 For I := 1 To Length(S) Do If S[I] = '|' Then Inc(N);
 CountLines := N;
End;

{ ================================================================== }
{ OS/2-0 : BOITES DE DIALOGUE NATIVES DE PRESENTATION MANAGER         }
{ ================================================================== }
{ La version DOS dessinait elle-meme ses boites (cadre, champ de      }
{ saisie, boutons, barres de defilement) et lisait clavier et souris  }
{ dans sa propre boucle. Ici ce sont de vraies fenetres de PM :       }
{  - saisie : boite modale avec un champ de saisie (WC_ENTRYFIELD) et }
{    les boutons OK / Annuler (WC_BUTTON) ;                           }
{  - resultats : fenetre modale dont le texte defile avec deux barres }
{    de defilement de PM (WC_SCROLLBAR), boutons Enregistrer et       }
{    Fermer ;                                                         }
{  - messages et questions : WinMessageBox.                           }
{ Pendant une boite modale, la fenetre qui l'a ouverte est desactivee }
{ (WinEnableWindow) et les messages sont distribues par WinGetMsg.    }

Const
 WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006;
 WC_LISTBOX = $FFFF0007; WC_SCROLLBAR = $FFFF0008;
 WS_VISIBLE = $80000000; WS_TABSTOP = $00020000; WS_GROUP = $00010000;
 BS_PUSHBUTTON = 0; BS_DEFAULT = $0400;
 ES_AUTOSCROLL = 4; ES_MARGIN = 8;
 SBS_HORZ = 0; SBS_VERT = 1;
 EM_SETTEXTLIMIT = $0143; EM_SETSEL = $0142;
 SBM_SETSCROLLBAR = $01A0; SBM_SETPOS = $01A1; SBM_SETTHUMBSIZE = $01A6;
 LM_QUERYITEMCOUNT = $0160; LM_INSERTITEM = $0161; LM_SETTOPINDEX = $0162;
 LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165; LM_QUERYTOPINDEX = $016D;
 LM_DELETEALL = $016E;
 LN_SELECT = 1; LN_ENTER = 5;
 WM_CREATE = $0001; WM_CONTROL = $0030; WM_VSCROLL = $0031; WM_HSCROLL = $0032;
 SB_LINEUP = 1; SB_LINEDOWN = 2; SB_PAGEUP = 3; SB_PAGEDOWN = 4;
 SB_SLIDERTRACK = 5; SB_SLIDERPOSITION = 6;
 CLR_PMWHITE = -2; CLR_PMBLACK = -1; CLR_PMBLUE = 1; CLR_PMDARKBLUE = 9;
 CLR_PALEGRAY = 15;
 ID_POK = 1; ID_PCANCEL = 2; ID_PSAVE = 3; ID_PEF = 20; ID_PVSB = 21; ID_PHSB = 22;
 PmChW = 8; PmChH = 16;

Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';

Var
 PmTopFr : LongInt;                       { fenetre qui recoit la saisie }
 PmLevel : LongInt;                       { profondeur des boites modales }
 PmEnd : Array[0..7] Of LongInt;          { 0 : ouverte, 1 : OK, 2 : annulee }
 PmClsDone, RsClsDone : Boolean;
 { boite de saisie }
 InFr, InCl, InEf : LongInt;
 InP1, InP2, InVal : String;
 InMax : LongInt;
 { fenetre des resultats }
 RsFr, RsCl, RsVsb, RsHsb : LongInt;
 RsTop, RsLeft, RsRows, RsCols, RsMaxLen : LongInt;

Function PmLo(V : LongInt) : LongInt;
Begin
 PmLo := V And $FFFF;
End;

Function PmHi(V : LongInt) : LongInt;
Begin
 PmHi := (V Shr 16) And $FFFF;
End;

Function PmS16(V : LongInt) : LongInt;
Begin
 V := V And $FFFF;
 If V >= $8000 Then V := V - $10000;
 PmS16 := V;
End;

{ texte d'une ligne dans une zone de dessin (Y compte depuis le haut) }
Procedure PmText(Hps, Hh, X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
 If S = '' Then Exit;
 PutZ(LongInt(@TxtBuf), S);
 Rc[0] := X; Rc[1] := Hh - Y - PmChH; Rc[2] := X + Length(S) * PmChW; Rc[3] := Hh - Y;
 Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ cadre de fenetre de dialogue de la taille de zone client W x H, centre
  sur la fenetre principale }
Function PmOpenBox(Cls, Title : String; W, H : LongInt; Var Cl : LongInt) : LongInt;
Var Fl, Fr, Sw, Sh, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
 Cl := 0;
 Fr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), OsZ(Cls), OsZ2(Title), 0, 0, 0, LongInt(@Cl));
 If Fr <> 0 Then
 Begin
  Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
  Dummy := WinCalcFrameRect(Fr, LongInt(@Rc), 0);
  W := Rc[2] - Rc[0]; H := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - W) Div 2; Y := (Sh - H) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := 0;
  Dummy := WinSetWindowPos(Fr, HWND_TOP, X, Y, W, H,
    SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Fr);
 End;
 PmOpenBox := Fr;
End;

{ boucle modale : la fenetre Fr recoit la saisie jusqu'a PmEnd[niveau] }
Function PmModal(Fr, Focus, Ef : LongInt) : LongInt;
Var Prev, Lv, N : LongInt; Buf : Array[0..259] Of Byte;
Begin
 FlushScreen;
 If PmTopFr = 0 Then PmTopFr := OsFrame;
 Prev := PmTopFr;
 Inc(PmLevel); Lv := PmLevel;
 PmEnd[Lv] := 0;
 { la fenetre qui avait la souris (clic en cours) la rend }
 Dummy := WinSetCapture(HWND_DESKTOP, 0);
 MBtn := 0; MLatch := 0;
 Dummy := WinEnableWindow(Prev, 0);
 PmTopFr := Fr;
 If Focus <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Focus);
 While PmEnd[Lv] = 0 Do
 Begin
  If WinGetMsg(OsHab, LongInt(@Qmsg), 0, 0, 0) = 0 Then
  Begin
   CmdPush(CMD_CLOSE);
   PmEnd[Lv] := 2;
  End
  Else Dummy := WinDispatchMsg(OsHab, LongInt(@Qmsg));
 End;
 PmModal := PmEnd[Lv];
 { texte du champ de saisie, lu avant la destruction de la boite }
 If (Ef <> 0) And (PmEnd[Lv] = 1) Then
 Begin
  N := WinQueryWindowText(Ef, 252, LongInt(@Buf));
  If N < 0 Then N := 0;
  InVal := '';
  While (Length(InVal) < N) And (Buf[Length(InVal)] <> 0) Do InVal := InVal + Chr(Buf[Length(InVal)]);
 End;
 Dec(PmLevel);
 Dummy := WinEnableWindow(Prev, 1);
 PmTopFr := Prev;
 { la fenetre d'origine redevient active (barre de titre) avant que la
   boite disparaisse }
 Dummy := WinSetActiveWindow(HWND_DESKTOP, Prev);
 If Prev = OsFrame Then Dummy := WinSetFocus(HWND_DESKTOP, OsClient);
 Dummy := WinDestroyWindow(Fr);
End;

Procedure PmDone(V : LongInt);
Begin
 If PmLevel > 0 Then PmEnd[PmLevel] := V;
End;

{ Entree et Echap remontes par les controles de la boite }
Function PmDlgKey(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk : LongInt;
Begin
 Fl := PmLo(Mp1); Vk := PmHi(Mp2);
 PmDlgKey := 1;
 If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And
    ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then PmDone(1)
 Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then PmDone(2)
 Else PmDlgKey := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

{ --- boite de saisie --- }

Function InputProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, W, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 InputProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, 0);
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
    Y := 8;
    PmText(Hps, Rc[3], 12, Y, InP1, CLR_PMBLACK, CLR_PALEGRAY);
    If InP2 <> '' Then PmText(Hps, Rc[3], 12, Y + PmChH, InP2, CLR_PMBLACK, CLR_PALEGRAY);
    Dummy := WinEndPaint(Hps);
   End;
  WM_COMMAND :
   If PmLo(Mp1) = ID_POK Then PmDone(1) Else If PmLo(Mp1) = ID_PCANCEL Then PmDone(2);
  WM_CHAR : InputProc := PmDlgKey(H, Msg, Mp1, Mp2);
  WM_CLOSE : PmDone(2);
 Else
  InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

{ controles de la boite de saisie (zone client W de large) }
Procedure InControls(H, W : LongInt);
Begin
 InEf := WinCreateWindow(H, WC_ENTRYFIELD, 0, WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
   12, 44, W - 24, 20, H, HWND_TOP, ID_PEF, 0, 0);
 Dummy := WinSendMsg(InEf, EM_SETTEXTLIMIT, InMax, 0);
 Dummy := WinCreateWindow(H, WC_BUTTON, OsZ('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
   W - 196, 8, 88, 26, H, HWND_TOP, ID_POK, 0, 0);
 Dummy := WinCreateWindow(H, WC_BUTTON, OsZ('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
   W - 100, 8, 88, 26, H, HWND_TOP, ID_PCANCEL, 0, 0);
End;

Procedure PmRegister;
Begin
 If PmClsDone Then Exit;
 PmClsDone := True;
 Dummy := WinRegisterClass(OsHab, OsZ('ASTROIN'), LongInt(@InputProc), 0, 0);
End;

{ coupe un texte trop long en deux lignes (a un espace) }
Procedure PmSplit(S : String; Max : LongInt; Var A, B : String);
Var K : LongInt;
Begin
 A := S; B := '';
 If Length(S) <= Max Then Exit;
 K := Max;
 While (K > 1) And (S[K] <> ' ') Do Dec(K);
 If K <= 1 Then K := Max;
 A := Copy(S, 1, K);
 B := Copy(S, K + 1, 255);
 While (B <> '') And (B[1] = ' ') Do Delete(B, 1, 1);
 If Length(B) > Max Then B := Copy(B, 1, Max);
End;

Function PmInput(Title, Prompt : String; Var S : String; MaxLen : LongInt) : Boolean;
Var W, H, L, R : LongInt;
Begin
 PmRegister;
 PmSplit(Prompt, 70, InP1, InP2);
 L := Length(InP1);
 If Length(InP2) > L Then L := Length(InP2);
 W := L * PmChW + 24;
 If W < 380 Then W := 380;
 If W < Length(Title) * PmChW + 80 Then W := Length(Title) * PmChW + 80;
 If W > 600 Then W := 600;
 H := 96;
 If InP2 <> '' Then H := H + PmChH;
 If MaxLen < 1 Then MaxLen := 1;
 If MaxLen > 250 Then MaxLen := 250;
 InMax := MaxLen;
 InFr := PmOpenBox('ASTROIN', Title, W, H, InCl);
 If InFr = 0 Then
 Begin
  PmInput := False;
  Exit;
 End;
 InControls(InCl, W);
 Dummy := WinSetWindowText(InEf, OsZ(S));
 Dummy := WinSendMsg(InEf, EM_SETSEL, Length(S) Shl 16, 0);
 R := PmModal(InFr, InEf, InEf);
 If R = 1 Then S := InVal;
 PmInput := R = 1;
End;


Procedure ShowMessage(Const Title, Msg: String);
{ boite de message de PM ; '|' separe les lignes }
Var T : String; I : Integer;
Begin
 T := Msg;
 For I := 1 To Length(T) Do If T[I] = '|' Then T[I] := #10;
 Dummy := PmBox(Title, T, MB_OK Or MB_INFORMATION);
End;

Function ConfirmBox(Const Title, Msg: String): Boolean;
Var I: Integer; T: String;
Begin
 T := Msg;
 For I := 1 To Length(T) Do If T[I] = '|' Then T[I] := ' ';
 ConfirmBox := PmBox(Title, T, MB_YESNO Or MB_ICONQUESTION) = MBID_YES;
 DlgEnd;
End;

Function InputString(Const Title, Prompt: String; Var Value: String): Boolean;
{ boite de dialogue de PM : champ de saisie, boutons OK et Annuler }
Begin
 InputString := PmInput(Title, Prompt, Value, 250);
End;

{ Liste / visionneuse de texte dans TLines[0..NTL-1] ; renvoie l'indice choisi }
Function ListDialog(Const Title: String; Selectable: Boolean): Integer;
Const BW = 80; BH = 22; LH = 12;
Var
 X1, Y1, X2, Y2, LX1, LY1, LX2, LY2, MaxLn, Top, Sel, I, Y : Integer;
 B1X, B2X, BY1, BY2, Key, MX, MY, Row : Integer;
 Click, Done, Redraw : Boolean;
 Res : Integer;
 LastT : LongInt;
 LastRow : Integer;
Begin
 X1 := 40; Y1 := 24; X2 := ScreenWidth - 40; Y2 := ScreenHeight - 24;
 LX1 := X1 + 8; LY1 := Y1 + 24; LX2 := X2 - 24; LY2 := Y2 - 40;
 MaxLn := (LY2 - LY1 - 4) Div LH;
 BY1 := Y2 - BH - 8; BY2 := BY1 + BH;
 B1X := X2 - 2 * (BW + 10); B2X := X2 - (BW + 10);
 Top := 0; Sel := 0; Res := -1; Done := False; Redraw := True;
 LastT := 0; LastRow := -2;
 HideMouseCursor;
 DrawDialogBox(X1, Y1, X2, Y2, Title);
 If Selectable Then Begin
  DrawButton(B1X, BY1, B1X + BW, BY2, 'OK', True);
  DrawButton(B2X, BY1, B2X + BW, BY2, 'Annuler', False);
 End
 Else DrawButton(B2X, BY1, B2X + BW, BY2, 'Fermer', True);
 DrawButton(LX2 + 2, LY1, LX2 + 18, LY1 + 16, '^', False);
 DrawButton(LX2 + 2, LY2 - 16, LX2 + 18, LY2, 'v', False);
 ShowMouseCursor;
 DlgBegin;
 While Not Done Do Begin
  If Redraw Then Begin
   HideMouseCursor;
   SetFillStyle(SolidFill, White);
   Bar(LX1, LY1, LX2, LY2);
   SetColor(Black);
   Rectangle(LX1, LY1, LX2, LY2);
   SetTextStyle(DefaultFont, HorizDir, 1);
   For I := 0 To MaxLn - 1 Do Begin
    If Top + I >= NTL Then Break;
    Y := LY1 + 3 + I * LH;
    If Selectable And (Top + I = Sel) Then Begin
     SetFillStyle(SolidFill, Blue);
     Bar(LX1 + 1, Y - 1, LX2 - 1, Y + LH - 2);
     SetColor(White);
    End
    Else SetColor(Black);
    OutTextXY(LX1 + 4, Y, TLines[Top + I]);
   End;
   ShowMouseCursor;
   Redraw := False;
  End;
  If DlgPoll(Key, MX, MY, Click) Then Begin
   Case Key Of
    256 + 72: Begin If Selectable Then Begin If Sel > 0 Then Dec(Sel); If Sel < Top Then Top := Sel; End Else If Top > 0 Then Dec(Top); Redraw := True; End;
    256 + 80: Begin If Selectable Then Begin If Sel < NTL - 1 Then Inc(Sel); If Sel >= Top + MaxLn Then Top := Sel - MaxLn + 1; End Else If Top < NTL - MaxLn Then Inc(Top); Redraw := True; End;
    256 + 73: Begin Dec(Top, MaxLn); If Top < 0 Then Top := 0; If Selectable Then Sel := Top; Redraw := True; End;
    256 + 81: Begin
     Inc(Top, MaxLn); If Top > NTL - MaxLn Then Top := NTL - MaxLn; If Top < 0 Then Top := 0;
     If Selectable Then Sel := Top; Redraw := True;
    End;
    256 + 71: Begin Top := 0; Sel := 0; Redraw := True; End;
    256 + 79: Begin
     Sel := NTL - 1; Top := NTL - MaxLn; If Top < 0 Then Top := 0; Redraw := True;
    End;
    13: Begin If Selectable Then Res := Sel Else Res := 0; Done := True; End;
    27: Begin Res := -1; Done := True; End;
   End;
   If Click Then Begin
    If PtInRect(MX, MY, B2X, BY1, B2X + BW, BY2) Then Begin Res := -1; Done := True; End
    Else If Selectable And PtInRect(MX, MY, B1X, BY1, B1X + BW, BY2) Then Begin Res := Sel; Done := True; End
    Else If PtInRect(MX, MY, LX2 + 2, LY1, LX2 + 18, LY1 + 16) Then Begin If Top > 0 Then Dec(Top, 3); If Top < 0 Then Top := 0; Redraw := True; End
    Else If PtInRect(MX, MY, LX2 + 2, LY2 - 16, LX2 + 18, LY2) Then Begin
     If Top < NTL - MaxLn Then Inc(Top, 3); If Top > NTL - MaxLn Then Top := NTL - MaxLn; If Top < 0 Then Top := 0; Redraw := True;
    End
    Else If Selectable And PtInRect(MX, MY, LX1, LY1, LX2, LY2) Then Begin
     Row := Top + (MY - LY1 - 3) Div LH;
     If (Row >= 0) And (Row < NTL) Then Begin
      If (Row = LastRow) And (NowMs - LastT < 600) And (NowMs >= LastT) Then Begin
       Res := Row; Done := True;
      End;
      Sel := Row; LastRow := Row; LastT := NowMs;
      Redraw := True;
     End;
    End;
   End;
  End;
  Delay(10);
 End;
 DlgEnd;
 ListDialog := Res;
End;

{ --------------------------------------------------------------------- }
{ Tableau periodique                                                    }
{ --------------------------------------------------------------------- }

Procedure PTPos(Z: Integer; Var Row, Col: Integer);
Begin
 Row := 0; Col := 0;
 Case Z Of
  1: Begin Row := 1; Col := 1; End;
  2: Begin Row := 1; Col := 18; End;
  3, 4: Begin Row := 2; Col := Z - 2; End;
  5..10: Begin Row := 2; Col := Z + 8; End;
  11, 12: Begin Row := 3; Col := Z - 10; End;
  13..18: Begin Row := 3; Col := Z; End;
  19..36: Begin Row := 4; Col := Z - 18; End;
  37..54: Begin Row := 5; Col := Z - 36; End;
  55, 56: Begin Row := 6; Col := Z - 54; End;
  57..71: Begin Row := 8; Col := Z - 54; End;
  72..86: Begin Row := 6; Col := Z - 68; End;
  87, 88: Begin Row := 7; Col := Z - 86; End;
  89..103: Begin Row := 9; Col := Z - 86; End;
 End;
End;

Function PTColor(Z: Integer): Byte;
Begin
 Case Z Of
  2, 10, 18, 36, 54, 86 : PTColor := LightMagenta;
  9, 17, 35, 53, 85     : PTColor := LightCyan;
  1, 6, 7, 8, 15, 16, 34: PTColor := LightGreen;
  3, 4, 11, 12, 19, 20, 37, 38, 55, 56, 87, 88 : PTColor := LightRed;
  5, 14, 32, 33, 51, 52 : PTColor := Yellow;
  57..71, 89..103       : PTColor := LightGray;
 Else PTColor := White;
 End;
End;

Function PeriodicDialog: Integer;
Const CW = 32; CH = 22; BW = 80; BH = 22;
Var
 X1, Y1, X2, Y2, OX, OY, Z, Row, Col, Key, MX, MY, BX1, BY1, BX2, BY2 : Integer;
 Click, Done : Boolean;
 Res : Integer;
 CX1, CY1 : Integer;
 S : String;
Begin
 X1 := (ScreenWidth - (18 * CW + 20)) Div 2; X2 := X1 + 18 * CW + 20;
 Y1 := 40; Y2 := Y1 + 9 * CH + 100;
 OX := X1 + 10; OY := Y1 + 24;
 BX2 := X2 - 10; BX1 := BX2 - BW; BY2 := Y2 - 8; BY1 := BY2 - BH;
 HideMouseCursor;
 DrawDialogBox(X1, Y1, X2, Y2, 'Tableau periodique - choisir un element');
 SetTextStyle(DefaultFont, HorizDir, 1);
 For Z := 1 To 103 Do Begin
  PTPos(Z, Row, Col);
  If Row > 0 Then Begin
   CX1 := OX + (Col - 1) * CW; CY1 := OY + (Row - 1) * CH + (Row Div 8) * 10;
   SetFillStyle(SolidFill, PTColor(Z));
   Bar(CX1, CY1, CX1 + CW - 2, CY1 + CH - 2);
   SetColor(DarkGray);
   Rectangle(CX1, CY1, CX1 + CW - 2, CY1 + CH - 2);
   SetColor(Black);
   OutTextXY(CX1 + (CW - 2 - 8 * Length(ElSym[Z])) Div 2, CY1 + 7, ElSym[Z]);
  End;
 End;
 DrawButton(BX1, BY1, BX2, BY2, 'Annuler', False);
 SetColor(Black);
 OutTextXY(OX + 2 * CW, OY + 5, 'Cliquer sur un element, ou taper son symbole puis Entree');
 ShowMouseCursor;
 DlgBegin;
 Done := False; Res := 0; S := '';
 While Not Done Do Begin
  If DlgPoll(Key, MX, MY, Click) Then Begin
   If Key = 27 Then Done := True;
   If (Key >= 65) And (Key <= 122) And (Key <> 91) And (Key <> 92) And (Key <> 93) And (Key <> 94) And (Key <> 95) And (Key <> 96) Then Begin
    If (Length(S) >= 2) Then S := '';
    If Length(S) = 0 Then S := UpCh(Chr(Key)) Else S := S + Chr(Key Or 32);
   End
   Else If (Key = 8) And (Length(S) > 0) Then Delete(S, Length(S), 1)
   Else If Key = 13 Then Begin
    Z := ElemBySymbol(S);
    If Z > 0 Then Begin Res := Z; Done := True; End;
   End;
   HideMouseCursor;
   SetFillStyle(SolidFill, LightGray);
   Bar(OX, Y2 - 30, OX + 200, Y2 - 8);
   SetColor(Black);
   Z := ElemBySymbol(S);
   If Z > 0 Then OutTextXY(OX, Y2 - 26, 'Symbole : ' + S + '_  ' + ElName[Z] + ' (Entree)')
   Else OutTextXY(OX, Y2 - 26, 'Symbole : ' + S + '_');
   ShowMouseCursor;
   If Click Then Begin
    If PtInRect(MX, MY, BX1, BY1, BX2, BY2) Then Done := True
    Else Begin
     For Z := 1 To 103 Do Begin
      PTPos(Z, Row, Col);
      If Row > 0 Then Begin
       CX1 := OX + (Col - 1) * CW; CY1 := OY + (Row - 1) * CH + (Row Div 8) * 10;
       If PtInRect(MX, MY, CX1, CY1, CX1 + CW - 2, CY1 + CH - 2) Then Begin
        Res := Z; Done := True;
       End;
      End;
     End;
    End;
   End;
  End;
  Delay(10);
 End;
 DlgEnd;
 PeriodicDialog := Res;
End;

{ --------------------------------------------------------------------- }
{ Boite d'ouverture de fichier                                          }
{ --------------------------------------------------------------------- }

Const
 FD_MAX_FILES = 256;

Type
 TFDEntry = Record
  Name  : String[14];
  IsDir : Boolean;
 End;

Var
 FDFiles : Array[0..FD_MAX_FILES - 1] Of TFDEntry;
 FDCount, FDTop, FDSel : Integer;
 FDMask, FDFileName : String;

Procedure FD_ScanMask(Const Mask: String);
Var Sr: SearchRec;
Begin
 FindFirst(Mask, AnyFile, Sr);
 While (DosError = 0) And (FDCount < FD_MAX_FILES) Do Begin
  If ((Sr.Attr And Directory) = 0) Then Begin
   FDFiles[FDCount].Name := Sr.Name;
   FDFiles[FDCount].IsDir := False;
   Inc(FDCount);
  End;
  FindNext(Sr);
 End;
 {$IFDEF FPC}FindClose(Sr);{$ENDIF}
End;

Procedure FD_ScanDir(Const Mask: String);
Var
 Sr : SearchRec;
 Tmp : TFDEntry;
 I, J, P : Integer;
 M : String;
Begin
 FDCount := 0;
 FindFirst('*', Directory, Sr);
 While (DosError = 0) And (FDCount < FD_MAX_FILES) Do Begin
  If ((Sr.Attr And Directory) <> 0) And (Sr.Name <> '.') Then Begin
   FDFiles[FDCount].Name := Sr.Name;
   FDFiles[FDCount].IsDir := True;
   Inc(FDCount);
  End;
  FindNext(Sr);
 End;
 {$IFDEF FPC}FindClose(Sr);{$ENDIF}
 M := Mask;
 Repeat
  P := Pos(';', M);
  If P > 0 Then Begin FD_ScanMask(Copy(M, 1, P - 1)); Delete(M, 1, P); End
  Else Begin FD_ScanMask(M); M := ''; End;
 Until M = '';
 For I := 1 To FDCount - 1 Do Begin
  Tmp := FDFiles[I];
  J := I - 1;
  While (J >= 0) And
        ((FDFiles[J].IsDir < Tmp.IsDir) Or
         ((FDFiles[J].IsDir = Tmp.IsDir) And (UpStr(FDFiles[J].Name) > UpStr(Tmp.Name)))) Do Begin
   FDFiles[J + 1] := FDFiles[J];
   Dec(J);
  End;
  FDFiles[J + 1] := Tmp;
 End;
End;

Procedure FD_DrawList(X1, Y1, X2, Y2: Integer);
Var I, Y, MaxLn : Integer; S : String;
Begin
 SetFillStyle(SolidFill, White);
 Bar(X1, Y1, X2, Y2);
 SetColor(Black);
 Rectangle(X1, Y1, X2, Y2);
 SetTextStyle(DefaultFont, HorizDir, 1);
 MaxLn := (Y2 - Y1 - 2) Div 10;
 For I := 0 To MaxLn - 1 Do Begin
  If FDTop + I >= FDCount Then Break;
  Y := Y1 + 2 + I * 10;
  If FDTop + I = FDSel Then Begin
   SetFillStyle(SolidFill, Blue);
   Bar(X1 + 1, Y, X2 - 1, Y + 9);
   SetColor(White);
  End
  Else SetColor(Black);
  If FDFiles[FDTop + I].IsDir Then S := '[' + FDFiles[FDTop + I].Name + ']'
  Else S := FDFiles[FDTop + I].Name;
  OutTextXY(X1 + 4, Y + 1, S);
 End;
End;

Function FileOpenDialog(Const Title: String; Var FileName: String;
                        Const InitialMask: String): Boolean;
Const BW = 80; BH = 22;
Var
 X1, Y1, X2, Y2, LX1, LY1, LX2, LY2, BOu1, BAn1, BBY1, BBY2, MaxLn : Integer;
 Key, MX, MY, SimK : Integer;
 Click, Done, Result : Boolean;
 OldDir, CurDir : String;
 NewMask : String;
 LastT : LongInt;
 LastRow, Row : Integer;
Begin
 FileOpenDialog := False;
 GetDir(0, OldDir);
 FDMask := InitialMask;
 FD_ScanDir(FDMask);
 FDTop := 0; FDSel := 0;
 X1 := 50; Y1 := 40; X2 := ScreenWidth - 50; Y2 := ScreenHeight - 40;
 LX1 := X1 + 10; LY1 := Y1 + 50; LX2 := X2 - 10; LY2 := Y2 - 90;
 MaxLn := (LY2 - LY1 - 2) Div 10;
 BBY1 := Y2 - BH - 8; BBY2 := BBY1 + BH;
 BOu1 := X2 - 2 * (BW + 8) - 10;
 BAn1 := X2 - (BW + 8) - 10;
 HideMouseCursor;
 DrawDialogBox(X1, Y1, X2, Y2, Title);
 GetDir(0, CurDir);
 SetColor(Black);
 OutTextXY(X1 + 10, Y1 + 22, 'Dossier : ' + Copy(CurDir, 1, 52));
 OutTextXY(X1 + 10, Y1 + 35, 'Masque : ' + FDMask + '   (Tab = changer le masque)');
 OutTextXY(X1 + 10, Y2 - 80, 'Fichier:');
 DrawButton(BOu1, BBY1, BOu1 + BW, BBY2, 'Ouvrir', True);
 DrawButton(BAn1, BBY1, BAn1 + BW, BBY2, 'Annuler', False);
 ShowMouseCursor;
 Done := False; Result := False; FDFileName := '';
 LastT := 0; LastRow := -2;
 DlgBegin;
 While Not Done Do Begin
  HideMouseCursor;
  SetFillStyle(SolidFill, White);
  Bar(X1 + 80, Y2 - 83, X2 - 10, Y2 - 70);
  SetColor(Black);
  Rectangle(X1 + 80, Y2 - 84, X2 - 9, Y2 - 69);
  OutTextXY(X1 + 84, Y2 - 81, FDFileName + '_');
  FD_DrawList(LX1, LY1, LX2, LY2);
  ShowMouseCursor;
  SimK := 0;
  Repeat
   If DlgPoll(Key, MX, MY, Click) Then Begin
    If Click Then Begin
     If PtInRect(MX, MY, BOu1, BBY1, BOu1 + BW, BBY2) Then SimK := 13
     Else If PtInRect(MX, MY, BAn1, BBY1, BAn1 + BW, BBY2) Then SimK := 27
     Else If PtInRect(MX, MY, LX1, LY1, LX2, LY2) Then Begin
      Row := FDTop + (MY - LY1 - 2) Div 10;
      If (Row >= 0) And (Row < FDCount) Then Begin
       If (Row = LastRow) And (NowMs - LastT < 600) And (NowMs >= LastT) Then SimK := 13;
       FDSel := Row; LastRow := Row; LastT := NowMs;
       FDFileName := '';
      End;
     End;
    End;
    If SimK = 0 Then SimK := Key;
    If SimK = 0 Then SimK := -1;
    Break;
   End;
   Delay(10);
  Until False;
  Case SimK Of
   -1: ;
   256 + 72: Begin If FDSel > 0 Then Dec(FDSel); If FDSel < FDTop Then FDTop := FDSel; End;
   256 + 80: Begin
    If FDSel < FDCount - 1 Then Inc(FDSel);
    If FDSel >= FDTop + MaxLn Then FDTop := FDSel - MaxLn + 1;
   End;
   256 + 73: Begin Dec(FDSel, MaxLn); If FDSel < 0 Then FDSel := 0; FDTop := FDSel; End;
   256 + 81: Begin
    Inc(FDSel, MaxLn); If FDSel >= FDCount Then FDSel := FDCount - 1;
    FDTop := FDSel - MaxLn + 1; If FDTop < 0 Then FDTop := 0;
   End;
   256 + 71: Begin FDSel := 0; FDTop := 0; End;
   256 + 79: Begin
    FDSel := FDCount - 1; FDTop := FDSel - MaxLn + 1; If FDTop < 0 Then FDTop := 0;
   End;
   13: Begin
    If FDFileName <> '' Then Begin
     FileName := FDFileName; Result := True; Done := True;
    End
    Else If (FDSel >= 0) And (FDSel < FDCount) Then Begin
     If FDFiles[FDSel].IsDir Then Begin
      {$I-}ChDir(FDFiles[FDSel].Name);{$I+}
      If IOResult <> 0 Then ;
      FD_ScanDir(FDMask);
      FDTop := 0; FDSel := 0;
      GetDir(0, CurDir);
      HideMouseCursor;
      SetFillStyle(SolidFill, LightGray);
      Bar(X1 + 10, Y1 + 20, X2 - 5, Y1 + 31);
      SetColor(Black);
      OutTextXY(X1 + 10, Y1 + 22, 'Dossier : ' + Copy(CurDir, 1, 52));
      ShowMouseCursor;
     End
     Else Begin
      FileName := FDFiles[FDSel].Name; Result := True; Done := True;
     End;
    End;
   End;
   27: Begin Result := False; Done := True; End;
   9: Begin
    NewMask := FDMask;
    If InputString('Masque', 'Entrer le masque (ex: *.CDT;*.MOL):', NewMask) Then Begin
     FDMask := NewMask; FD_ScanDir(FDMask); FDTop := 0; FDSel := 0;
    End;
    HideMouseCursor;
    DrawDialogBox(X1, Y1, X2, Y2, Title);
    SetColor(Black);
    OutTextXY(X1 + 10, Y1 + 22, 'Dossier : ' + Copy(CurDir, 1, 52));
    OutTextXY(X1 + 10, Y1 + 35, 'Masque : ' + FDMask + '   (Tab = changer le masque)');
    OutTextXY(X1 + 10, Y2 - 80, 'Fichier:');
    DrawButton(BOu1, BBY1, BOu1 + BW, BBY2, 'Ouvrir', True);
    DrawButton(BAn1, BBY1, BAn1 + BW, BBY2, 'Annuler', False);
    ShowMouseCursor;
   End;
   8: Begin If Length(FDFileName) > 0 Then Delete(FDFileName, Length(FDFileName), 1); End;
  Else
   If (SimK >= 32) And (SimK < 256) And (Length(FDFileName) < 60) Then
    FDFileName := FDFileName + Chr(SimK);
  End;
 End;
 If Not Result Then ChDir(OldDir);
 DlgEnd;
 FileOpenDialog := Result;
End;

Function FileSaveDialog(Const Title: String; Var FileName: String): Boolean;
Var Cur: String;
Begin
 Cur := FileName;
 If InputString(Title, 'Nom du fichier :', Cur) And (Cur <> '') Then Begin
  FileName := Cur;
  FileSaveDialog := True;
 End
 Else FileSaveDialog := False;
End;

{ --------------------------------------------------------------------- }
{ Definition des menus                                                  }
{ --------------------------------------------------------------------- }

Procedure ZeroMenu(Var M: TMenu);
Var I: Integer;
Begin
 For I := 0 To MAX_MENU_ITEMS - 1 Do Begin
  M.Items[I].Caption := '';
  M.Items[I].Shortcut := '';
  M.Items[I].Enabled := True;
  M.Items[I].Checked := False;
  M.Items[I].Separator := False;
 End;
End;

Procedure MI(Var Mn: TMenu; Idx: Integer; Const Cap, Sc: String);
Begin
 Mn.Items[Idx].Caption := Cap;
 Mn.Items[Idx].Shortcut := Sc;
End;

Procedure MS(Var Mn: TMenu; Idx: Integer);
Begin
 Mn.Items[Idx].Separator := True;
End;

Procedure InitMenus;
Var I: Integer;
Begin
 { Fichier }
 ZeroMenu(Menus[MENU_FILE]);
 Menus[MENU_FILE].Title := 'Fichier';
 Menus[MENU_FILE].ItemCount := 14;
 MI(Menus[MENU_FILE], 0, 'Nouveau', 'Ctrl+N');
 MI(Menus[MENU_FILE], 1, 'Ouvrir...', 'Ctrl+O');
 MI(Menus[MENU_FILE], 2, 'Enregistrer', 'Ctrl+S');
 MI(Menus[MENU_FILE], 3, 'Enregistrer sous...', '');
 MS(Menus[MENU_FILE], 4);
 MI(Menus[MENU_FILE], 5, 'Importer SMILES...', '');
 MI(Menus[MENU_FILE], 6, 'Importer MOL...', '');
 MI(Menus[MENU_FILE], 7, 'Exporter MOL...', '');
 MI(Menus[MENU_FILE], 8, 'Exporter SMILES...', '');
 MI(Menus[MENU_FILE], 9, 'Exporter InChI...', '');
 MI(Menus[MENU_FILE], 10, 'Exporter SVG...', '');
 MI(Menus[MENU_FILE], 11, 'Exporter BMP...', '');
 MS(Menus[MENU_FILE], 12);
 MI(Menus[MENU_FILE], 13, 'Quitter', 'Alt+X');
 { Edition }
 ZeroMenu(Menus[MENU_EDIT]);
 Menus[MENU_EDIT].Title := 'Edition';
 Menus[MENU_EDIT].ItemCount := 17;
 MI(Menus[MENU_EDIT], 0, 'Annuler', 'Ctrl+Z');
 MI(Menus[MENU_EDIT], 1, 'Retablir', 'Ctrl+Y');
 MS(Menus[MENU_EDIT], 2);
 MI(Menus[MENU_EDIT], 3, 'Couper', 'Ctrl+X');
 MI(Menus[MENU_EDIT], 4, 'Copier', 'Ctrl+C');
 MI(Menus[MENU_EDIT], 5, 'Coller', 'Ctrl+V');
 MI(Menus[MENU_EDIT], 6, 'Effacer', 'Suppr');
 MS(Menus[MENU_EDIT], 7);
 MI(Menus[MENU_EDIT], 8, 'Tout selectionner', 'Ctrl+A');
 MI(Menus[MENU_EDIT], 9, 'Deselectionner', 'Echap');
 MI(Menus[MENU_EDIT], 10, 'Inverser la selection', '');
 MI(Menus[MENU_EDIT], 11, 'Selectionner le fragment', '');
 MS(Menus[MENU_EDIT], 12);
 MI(Menus[MENU_EDIT], 13, 'Copier comme SMILES', '');
 MI(Menus[MENU_EDIT], 14, 'Coller un SMILES...', '');
 MS(Menus[MENU_EDIT], 15);
 MI(Menus[MENU_EDIT], 16, 'Dupliquer', 'Ctrl+D');
 { Affichage }
 ZeroMenu(Menus[MENU_VIEW]);
 Menus[MENU_VIEW].Title := 'Affichage';
 Menus[MENU_VIEW].ItemCount := 18;
 MI(Menus[MENU_VIEW], 0, 'Zoom avant', 'PgUp');
 MI(Menus[MENU_VIEW], 1, 'Zoom arriere', 'PgDn');
 MI(Menus[MENU_VIEW], 2, 'Zoom 100 %', 'F5');
 MI(Menus[MENU_VIEW], 3, 'Ajuster a la fenetre', 'Home');
 MS(Menus[MENU_VIEW], 4);
 MI(Menus[MENU_VIEW], 5, 'Grille', 'F6');
 MI(Menus[MENU_VIEW], 6, 'Accrocher a la grille', '');
 MI(Menus[MENU_VIEW], 7, 'Angles fixes', '');
 MI(Menus[MENU_VIEW], 8, 'Longueurs fixes', '');
 MS(Menus[MENU_VIEW], 9);
 MI(Menus[MENU_VIEW], 10, 'Afficher les carbones', '');
 MI(Menus[MENU_VIEW], 11, 'Numeros d''atomes', '');
 MI(Menus[MENU_VIEW], 12, 'Avertissements de valence', '');
 MI(Menus[MENU_VIEW], 13, 'Atomes en couleur', '');
 MI(Menus[MENU_VIEW], 14, 'Stereochimie (R/S, E/Z)', '');
 MI(Menus[MENU_VIEW], 15, 'Mode sombre', '');
 MS(Menus[MENU_VIEW], 16);
 MI(Menus[MENU_VIEW], 17, 'Proprietes chimiques', 'F2');
 { Objet }
 ZeroMenu(Menus[MENU_OBJECT]);
 Menus[MENU_OBJECT].Title := 'Objet';
 Menus[MENU_OBJECT].ItemCount := 19;
 MI(Menus[MENU_OBJECT], 0, 'Aligner a gauche', '');
 MI(Menus[MENU_OBJECT], 1, 'Aligner a droite', '');
 MI(Menus[MENU_OBJECT], 2, 'Aligner en haut', '');
 MI(Menus[MENU_OBJECT], 3, 'Aligner en bas', '');
 MI(Menus[MENU_OBJECT], 4, 'Centrer horizontalement', '');
 MI(Menus[MENU_OBJECT], 5, 'Centrer verticalement', '');
 MS(Menus[MENU_OBJECT], 6);
 MI(Menus[MENU_OBJECT], 7, 'Distribuer horizontalement', '');
 MI(Menus[MENU_OBJECT], 8, 'Distribuer verticalement', '');
 MS(Menus[MENU_OBJECT], 9);
 MI(Menus[MENU_OBJECT], 10, 'Rotation 90 deg horaire', '');
 MI(Menus[MENU_OBJECT], 11, 'Rotation 90 deg anti-horaire', '');
 MI(Menus[MENU_OBJECT], 12, 'Rotation 180 deg', '');
 MI(Menus[MENU_OBJECT], 13, 'Rotation libre...', '');
 MI(Menus[MENU_OBJECT], 14, 'Retourner horizontalement', '');
 MI(Menus[MENU_OBJECT], 15, 'Retourner verticalement', '');
 MS(Menus[MENU_OBJECT], 16);
 MI(Menus[MENU_OBJECT], 17, 'Mettre a l''echelle...', '');
 MI(Menus[MENU_OBJECT], 18, 'Longueur de liaison standard', '');
 { Structure }
 ZeroMenu(Menus[MENU_STRUCT]);
 Menus[MENU_STRUCT].Title := 'Structure';
 Menus[MENU_STRUCT].ItemCount := 23;
 MI(Menus[MENU_STRUCT], 0, 'Liaison simple', '');
 MI(Menus[MENU_STRUCT], 1, 'Liaison double', '');
 MI(Menus[MENU_STRUCT], 2, 'Liaison triple', '');
 MI(Menus[MENU_STRUCT], 3, 'Coin plein', '');
 MI(Menus[MENU_STRUCT], 4, 'Coin hachure', '');
 MI(Menus[MENU_STRUCT], 5, 'Liaison grasse', '');
 MI(Menus[MENU_STRUCT], 6, 'Liaison ondulee', '');
 MI(Menus[MENU_STRUCT], 7, 'Liaison pointillee', '');
 MI(Menus[MENU_STRUCT], 8, 'Position de la double liaison', '');
 MI(Menus[MENU_STRUCT], 9, 'Inverser la liaison', '');
 MS(Menus[MENU_STRUCT], 10);
 MI(Menus[MENU_STRUCT], 11, 'Charge +', '');
 MI(Menus[MENU_STRUCT], 12, 'Charge -', '');
 MI(Menus[MENU_STRUCT], 13, 'Radical', '');
 MI(Menus[MENU_STRUCT], 14, 'Retirer charge / radical', '');
 MS(Menus[MENU_STRUCT], 15);
 MI(Menus[MENU_STRUCT], 16, 'Changer l''element...', '');
 MI(Menus[MENU_STRUCT], 17, 'Etiquette de l''atome...', '');
 MI(Menus[MENU_STRUCT], 18, 'Tableau periodique...', '');
 MS(Menus[MENU_STRUCT], 19);
 MI(Menus[MENU_STRUCT], 20, 'Nettoyer la structure', 'Ctrl+L');
 MI(Menus[MENU_STRUCT], 21, 'Developper l''etiquette', '');
 MI(Menus[MENU_STRUCT], 22, 'Modeles...', 'F4');
 { Couleur }
 ZeroMenu(Menus[MENU_COLOR]);
 Menus[MENU_COLOR].Title := 'Couleur';
 Menus[MENU_COLOR].ItemCount := 18;
 For I := 0 To 15 Do MI(Menus[MENU_COLOR], I, ColNames[I], '');
 MS(Menus[MENU_COLOR], 16);
 MI(Menus[MENU_COLOR], 17, 'Atomes en couleur', '');
 { Texte }
 ZeroMenu(Menus[MENU_TEXT]);
 Menus[MENU_TEXT].Title := 'Texte';
 Menus[MENU_TEXT].ItemCount := 10;
 MI(Menus[MENU_TEXT], 0, 'Nouveau texte...', '');
 MI(Menus[MENU_TEXT], 1, 'Modifier le texte...', '');
 MS(Menus[MENU_TEXT], 2);
 MI(Menus[MENU_TEXT], 3, 'Taille normale', '');
 MI(Menus[MENU_TEXT], 4, 'Grande taille', '');
 MS(Menus[MENU_TEXT], 5);
 MI(Menus[MENU_TEXT], 6, 'Inserer la formule', '');
 MI(Menus[MENU_TEXT], 7, 'Inserer la masse moleculaire', '');
 MI(Menus[MENU_TEXT], 8, 'Inserer le nom (si connu)', '');
 MI(Menus[MENU_TEXT], 9, 'Inserer le SMILES', '');
 { Analyse }
 ZeroMenu(Menus[MENU_TOOLS]);
 Menus[MENU_TOOLS].Title := 'Analyse';
 Menus[MENU_TOOLS].ItemCount := 13;
 MI(Menus[MENU_TOOLS], 0, 'Analyse detaillee...', 'F3');
 MI(Menus[MENU_TOOLS], 1, 'Spectre de masse...', '');
 MI(Menus[MENU_TOOLS], 2, 'Prediction RMN 13C...', '');
 MI(Menus[MENU_TOOLS], 3, 'Prediction RMN 1H...', '');
 MS(Menus[MENU_TOOLS], 4);
 MI(Menus[MENU_TOOLS], 5, 'Structure -> Nom', '');
 MI(Menus[MENU_TOOLS], 6, 'Nom -> Structure...', '');
 MI(Menus[MENU_TOOLS], 7, 'Afficher le SMILES', '');
 MI(Menus[MENU_TOOLS], 8, 'Afficher l''InChI', '');
 MI(Menus[MENU_TOOLS], 9, 'Stereochimie (R/S, E/Z)...', '');
 MS(Menus[MENU_TOOLS], 10);
 MI(Menus[MENU_TOOLS], 11, 'Verifier la structure', '');
 MI(Menus[MENU_TOOLS], 12, 'Proprietes chimiques', 'F2');
 { Aide }
 ZeroMenu(Menus[MENU_HELP]);
 Menus[MENU_HELP].Title := 'Aide';
 Menus[MENU_HELP].ItemCount := 5;
 MI(Menus[MENU_HELP], 0, 'Guide d''utilisation', 'F1');
 MI(Menus[MENU_HELP], 1, 'Raccourcis clavier...', '');
 MI(Menus[MENU_HELP], 2, 'Groupes d''atomes...', '');
 MS(Menus[MENU_HELP], 3);
 MI(Menus[MENU_HELP], 4, 'A propos...', '');
End;

Procedure UpdateMenuChecks;
Begin
 Menus[MENU_VIEW].Items[5].Checked := OptGrid;
 Menus[MENU_VIEW].Items[6].Checked := OptSnap;
 Menus[MENU_VIEW].Items[7].Checked := OptFixAng;
 Menus[MENU_VIEW].Items[8].Checked := OptFixLen;
 Menus[MENU_VIEW].Items[10].Checked := OptShowC;
 Menus[MENU_VIEW].Items[11].Checked := OptNumbers;
 Menus[MENU_VIEW].Items[12].Checked := OptWarn;
 Menus[MENU_VIEW].Items[13].Checked := OptColorEl;
 Menus[MENU_VIEW].Items[14].Checked := OptStereo;
 Menus[MENU_VIEW].Items[15].Checked := OptDark;
 Menus[MENU_VIEW].Items[17].Checked := OptAnalysis;
 Menus[MENU_COLOR].Items[17].Checked := OptColorEl;
 Menus[MENU_TOOLS].Items[12].Checked := OptAnalysis;
 Menus[MENU_TEXT].Items[3].Checked := TextSize = 1;
 Menus[MENU_TEXT].Items[4].Checked := TextSize = 2;
 Menus[MENU_EDIT].Items[0].Enabled := UndoN > 0;
 Menus[MENU_EDIT].Items[1].Enabled := RedoN > 0;
End;

{ barre de menus de PM construite a partir des menus ci-dessus : choix I
  du menu M = identificateur 100 + 32 * M + I ; sous-menu M = 900 + M ;
  mnemonique : premiere lettre du titre pas encore prise }
Procedure BuildMenuBar;
Var
 M, I, K, H0, H1 : Integer;
 S, Lb : String;
 Mn : Boolean;
Begin
 MenuLen := 0;
 MnemoKeys := '';
 H0 := MnOpen;
 For M := 0 To NUM_MENUS - 1 Do Begin
  S := Menus[M].Title; Lb := ''; Mn := False;
  For K := 1 To Length(S) Do Begin
   If (Not Mn) And (UpCase(S[K]) >= 'A') And (UpCase(S[K]) <= 'Z') And
      (Pos(UpCase(S[K]), MnemoKeys) = 0) Then Begin
    Lb := Lb + '~'; MnemoKeys := MnemoKeys + UpCase(S[K]); Mn := True;
   End;
   Lb := Lb + S[K];
  End;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 900 + M, Lb);
  H1 := MnOpen;
  For I := 0 To Menus[M].ItemCount - 1 Do
   If Menus[M].Items[I].Separator Then MnItem(MIS_SEPARATOR, 0, 100 + 32 * M + I, '')
   Else Begin
    S := Menus[M].Items[I].Caption;
    If Menus[M].Items[I].Shortcut <> '' Then S := S + #9 + Menus[M].Items[I].Shortcut;
    MnItem(MIS_TEXT, 0, 100 + 32 * M + I, S);
   End;
  MnClose(H1, Menus[M].ItemCount);
 End;
 MnClose(H0, NUM_MENUS);
 OsMenu := WinCreateMenu(OsFrame, LongInt(@MenuT));
End;

{ ouverture d'un menu : coches et choix grises de la version DOS }
Procedure MenuInit(M : LongInt);
Var I : Integer;
Begin
 M := M - 900;
 If (M < 0) Or (M >= NUM_MENUS) Then Exit;
 UpdateMenuChecks;
 For I := 0 To Menus[M].ItemCount - 1 Do
  If Not Menus[M].Items[I].Separator Then Begin
   MnAttr(100 + 32 * M + I, MIA_CHECKED, Menus[M].Items[I].Checked);
   MnAttr(100 + 32 * M + I, MIA_DISABLED, Not Menus[M].Items[I].Enabled);
  End;
End;

{ --------------------------------------------------------------------- }
{ Chimie : composition, formule, masses, spectre de masse               }
{ --------------------------------------------------------------------- }

{ Analyse une formule brute ("C2H5O") et ajoute a C ; renvoie False si erreur }
Function ParseFormulaInto(Const F: String; Var C: TCounts): Boolean;
Var
 I, N, Z : Integer;
 S : String;
Begin
 ParseFormulaInto := True;
 I := 1;
 While I <= Length(F) Do Begin
  If (F[I] >= 'A') And (F[I] <= 'Z') Then Begin
   S := F[I];
   Inc(I);
   If (I <= Length(F)) And (F[I] >= 'a') And (F[I] <= 'z') Then Begin
    S := S + F[I]; Inc(I);
   End;
   N := 0;
   While (I <= Length(F)) And IsDigitCh(F[I]) Do Begin
    N := N * 10 + Ord(F[I]) - 48; Inc(I);
   End;
   If N = 0 Then N := 1;
   Z := ElemBySymbol(S);
   If Z = 0 Then ParseFormulaInto := False
   Else Inc(C[Z], N);
  End
  Else Begin ParseFormulaInto := False; Inc(I); End;
 End;
 
End;

{ Composition de la selection (ou de tout le document) }
Procedure Composition(SelOnly: Boolean; Var C: TCounts; Var Chg: Integer;
                      Var Generic: Boolean);
Var I, K, Z: Integer;
Begin
 For Z := 0 To 103 Do C[Z] := 0;
 Chg := 0; Generic := False;
 UpdateInfo;
 For I := 0 To NAt - 1 Do Begin
  If SelOnly And Not At^[I].Sel Then Continue;
  Inc(Chg, At^[I].Chg);
  If At^[I].Lbl <> '' Then Begin
   K := FindNick(At^[I].Lbl);
   If K > 0 Then ParseFormulaInto(Nicks[K].Fm, C)
   Else Generic := True;
  End
  Else If At^[I].Z = 0 Then Generic := True
  Else Begin
   Inc(C[At^[I].Z]);
   Inc(C[1], Inf^[I].H);
  End;
 End;
End;

Function HillFormula(Const C: TCounts; Chg: Integer): String;
Var
 S : String;
 Order : Array[1..103] Of Integer;
 N, I, J, T : Integer;
 Function Num(V: LongInt): String;
 Begin
  If V > 1 Then Num := IntToStr(V) Else Num := '';
 End;
Begin
 S := '';
 N := 0;
 For I := 1 To 103 Do Begin
  If C[I] > 0 Then Begin
   If (C[6] > 0) And ((I = 6) Or (I = 1)) Then Continue;
   Inc(N); Order[N] := I;
  End;
 End;
 For I := 2 To N Do Begin
  T := Order[I]; J := I - 1;
  While (J >= 1) And (ElSym[Order[J]] > ElSym[T]) Do Begin
   Order[J + 1] := Order[J]; Dec(J);
  End;
  Order[J + 1] := T;
 End;
 If C[6] > 0 Then Begin
  S := 'C' + Num(C[6]);
  If C[1] > 0 Then S := S + 'H' + Num(C[1]);
 End;
 For I := 1 To N Do S := S + ElSym[Order[I]] + Num(C[Order[I]]);
 If Chg > 0 Then Begin
  If Chg > 1 Then S := S + IntToStr(Chg);
  S := S + '+';
 End
 Else If Chg < 0 Then Begin
  If Chg < -1 Then S := S + IntToStr(-Chg);
  S := S + '-';
 End;
 HillFormula := S;
End;

Function MolWeight(Const C: TCounts): Real;
Var Z: Integer; W: Real;
Begin
 W := 0;
 For Z := 1 To 103 Do W := W + C[Z] * ElWt[Z];
 MolWeight := W;
End;

Function ExactMass(Const C: TCounts): Real;
Var Z: Integer; W: Real;
Begin
 W := 0;
 For Z := 1 To 103 Do W := W + C[Z] * ElExact(Z);
 ExactMass := W;
End;

{ --------------------------------------------------------------------- }
{ Distribution isotopique                                               }
{ --------------------------------------------------------------------- }

Const
 ISO_MAX = 12;

Type
 TIsoDist = Record
  P, M : Array[0..ISO_MAX] Of Real;      { probabilite et decalage de masse }
 End;

{ Isotopes d'un element : decalage de nombre de masse, abondance, decalage de masse }
Procedure ElemIsotopes(Z: Integer; Var N: Integer;
                       Var Off: Array Of Integer; Var Ab, Dm: Array Of Real);
Begin
 N := 1; Off[0] := 0; Ab[0] := 1; Dm[0] := 0;
 Case Z Of
  1 : Begin N := 2; Ab[0] := 0.999885; Off[1] := 1; Ab[1] := 0.000115; Dm[1] := 1.006277; End;
  6 : Begin N := 2; Ab[0] := 0.9893; Off[1] := 1; Ab[1] := 0.0107; Dm[1] := 1.003355; End;
  7 : Begin N := 2; Ab[0] := 0.99636; Off[1] := 1; Ab[1] := 0.00364; Dm[1] := 0.997035; End;
  8 : Begin N := 3; Ab[0] := 0.99757; Off[1] := 1; Ab[1] := 0.00038; Dm[1] := 1.004217;
            Off[2] := 2; Ab[2] := 0.00205; Dm[2] := 2.004245; End;
  14: Begin N := 3; Ab[0] := 0.92223; Off[1] := 1; Ab[1] := 0.04685; Dm[1] := 0.999568;
            Off[2] := 2; Ab[2] := 0.03092; Dm[2] := 1.996844; End;
  16: Begin N := 4; Ab[0] := 0.9499; Off[1] := 1; Ab[1] := 0.0075; Dm[1] := 0.999388;
            Off[2] := 2; Ab[2] := 0.0425; Dm[2] := 1.995796;
            Off[3] := 4; Ab[3] := 0.0001; Dm[3] := 3.99501; End;
  17: Begin N := 2; Ab[0] := 0.7576; Off[1] := 2; Ab[1] := 0.2424; Dm[1] := 1.99705; End;
  35: Begin N := 2; Ab[0] := 0.5069; Off[1] := 2; Ab[1] := 0.4931; Dm[1] := 1.997953; End;
 End;
End;

Procedure IsotopePattern(Const C: TCounts; Var D: TIsoDist);
Var
 Z, K, A, B, N, I, Cnt : Integer;
 Off : Array[0..3] Of Integer;
 Ab, Dm : Array[0..3] Of Real;
 NP : TIsoDist;
 W : Real;
Begin
 For K := 0 To ISO_MAX Do Begin D.P[K] := 0; D.M[K] := 0; End;
 D.P[0] := 1;
 For Z := 1 To 103 Do Begin
  If C[Z] <= 0 Then Continue;
  ElemIsotopes(Z, N, Off, Ab, Dm);
  If N = 1 Then Continue;
  Cnt := C[Z];
  For I := 1 To Cnt Do Begin
   For K := 0 To ISO_MAX Do Begin NP.P[K] := 0; NP.M[K] := 0; End;
   For A := 0 To ISO_MAX Do Begin
    If D.P[A] <= 1E-12 Then Continue;
    For B := 0 To N - 1 Do Begin
     If A + Off[B] > ISO_MAX Then Continue;
     W := D.P[A] * Ab[B];
     NP.P[A + Off[B]] := NP.P[A + Off[B]] + W;
     NP.M[A + Off[B]] := NP.M[A + Off[B]] + W * (D.M[A] + Dm[B]);
    End;
   End;
   For K := 0 To ISO_MAX Do Begin
    If NP.P[K] > 0 Then Begin D.P[K] := NP.P[K]; D.M[K] := NP.M[K] / NP.P[K]; End
    Else Begin D.P[K] := 0; D.M[K] := 0; End;
   End;
  End;
 End;
End;

{ Met a jour les textes de proprietes (barre d'etat, fenetre d'analyse) }
Procedure UpdateProps;
Var
 C : TCounts;
 Chg, Z, K, Cnt : Integer;
 Generic, SelOnly : Boolean;
 MW, EM, Pct, Mx : Real;
 F, S : String;
 D : TIsoDist;
Begin
 PropDirty := False;
 SelOnly := CountSelAtoms > 0;
 Composition(SelOnly, C, Chg, Generic);
 Cnt := 0;
 For Z := 1 To 103 Do Inc(Cnt, C[Z]);
 If Cnt = 0 Then Begin
  For K := 0 To 5 Do PropText[K] := '';
  StatText := '';
  Exit;
 End;
 F := HillFormula(C, Chg);
 If Generic Then F := F + '+R';
 MW := MolWeight(C);
 EM := ExactMass(C);
 PropText[0] := 'Formule : ' + F;
 PropText[1] := 'Poids mol. : ' + RealToStr(MW, 2);
 PropText[2] := 'Masse exacte : ' + RealToStr(EM, 4);
 IsotopePattern(C, D);
 Mx := 0;
 For K := 0 To ISO_MAX Do If D.P[K] > Mx Then Mx := D.P[K];
  S := 'm/z : ' + RealToStr(EM + D.M[0], 2) + ' (100)';
 K := 1;
 While (K <= ISO_MAX) And (Length(S) < 22) Do Begin
  If (Mx > 0) And (D.P[K] / Mx > 0.005) Then
   S := S + ', ' + RealToStr(EM + D.M[K], 2) + ' (' + RealToStr(D.P[K] / Mx * 100, 1) + ')';
  Inc(K);
 End;
 PropText[3] := S;
 S := 'Analyse : ';
 If MW > 0 Then Begin
  Pct := C[6] * ElWt[6] / MW * 100;
  If C[6] > 0 Then S := S + 'C ' + RealToStr(Pct, 2) + '; ';
  Pct := C[1] * ElWt[1] / MW * 100;
  If C[1] > 0 Then S := S + 'H ' + RealToStr(Pct, 2) + '; ';
  For Z := 2 To 103 Do
   If (Z <> 6) And (C[Z] > 0) And (Length(S) < 40) Then
    S := S + ElSym[Z] + ' ' + RealToStr(C[Z] * ElWt[Z] / MW * 100, 2) + '; ';
 End;
 PropText[4] := S;
 PropText[5] := '';
 If SelOnly Then StatText := '[sel] ' + F + '  PM ' + RealToStr(MW, 2)
 Else StatText := F + '  PM ' + RealToStr(MW, 2);
End;

{ --------------------------------------------------------------------- }
{ SMILES : ecriture                                                     }
{ --------------------------------------------------------------------- }

Type
 TBuf = Array[0..4095] Of Char;
 TSmNb = Array[0..MAX_ATOMS - 1, 0..4] Of Integer;

Var
 SmBuf  : ^TBuf;
 SmLen  : Integer;
 SmVis  : Array[0..MAX_ATOMS - 1] Of Byte;
 SmPar  : Array[0..MAX_ATOMS - 1] Of Integer;
 SmSize : Array[0..MAX_ATOMS - 1] Of Integer;
 SmBK   : Array[0..MAX_BONDS - 1] Of Byte;
 SmBR   : Array[0..MAX_BONDS - 1] Of Byte;
 SmUsed : Array[1..99] Of Boolean;
 SmH    : Array[0..MAX_ATOMS - 1] Of ShortInt;
 SmEnd  : Array[0..MAX_ATOMS - 1] Of Byte;
 SmRoot : Array[0..MAX_ATOMS - 1] Of Integer;
 SmSym  : Array[0..MAX_BONDS - 1] Of Char;       { / ou \ ecrit sur la liaison }
 { chiralite SMILES : etiquette (0, 1 = @, 2 = @@), voisins dans l'ordre
   d'ecriture (-1 = H implicite, < -1 = fermeture de cycle non resolue) }
 SmCh   : Array[0..MAX_ATOMS - 1] Of Byte;
 SmNn   : Array[0..MAX_ATOMS - 1] Of ShortInt;
 SmFrm  : Array[0..MAX_ATOMS - 1] Of Byte;
 SmNb   : ^TSmNb;
 SmDir  : Array[0..MAX_BONDS - 1] Of Byte;     { 1 = '/', 2 = '\' sur la liaison }

Procedure SmAdd(Const S: String);
Var I: Integer;
Begin
 For I := 1 To Length(S) Do
  If SmLen < 4095 Then Begin SmBuf^[SmLen] := S[I]; Inc(SmLen); End;
End;

Function SmBufStr: String;
Var I, N: Integer; S: String;
Begin
 N := SmLen; If N > 255 Then N := 255;
 S := '';
 For I := 0 To N - 1 Do S := S + SmBuf^[I];
 SmBufStr := S;
End;

Function SmAtomToken(I, Chir: Integer): String;
Var S: String; H: Integer; Bare: Boolean;
Begin
 If At^[I].Z = 0 Then Begin SmAtomToken := '*'; Exit; End;
 H := Inf^[I].H;
 Bare := (At^[I].Chg = 0) And (At^[I].Iso = 0) And (At^[I].Rad = 0) And
         (At^[I].Z In [5, 6, 7, 8, 9, 15, 16, 17, 35, 53]) And (Chir = 0);
 If Bare Then Begin SmAtomToken := ElSym[At^[I].Z]; Exit; End;
 S := '[';
 If At^[I].Iso > 0 Then S := S + IntToStr(At^[I].Iso);
 S := S + ElSym[At^[I].Z];
 If Chir = 1 Then S := S + '@' Else If Chir = 2 Then S := S + '@@';
 If H > 0 Then Begin
  S := S + 'H';
  If H > 1 Then S := S + IntToStr(H);
 End;
 If At^[I].Chg > 0 Then Begin
  S := S + '+';
  If At^[I].Chg > 1 Then S := S + IntToStr(At^[I].Chg);
 End
 Else If At^[I].Chg < 0 Then Begin
  S := S + '-';
  If At^[I].Chg < -1 Then S := S + IntToStr(-At^[I].Chg);
 End;
 SmAtomToken := S + ']';
End;

Procedure SmDFS1(I, ParBond: Integer);
Var K, J, NB: Integer;
Begin
 SmVis[I] := 1; SmSize[I] := 1;
 For K := 0 To AdjN^[I] - 1 Do Begin
  J := AdjB^[I, K]; NB := Adj^[I, K];
  If J = ParBond Then Continue;
  If SmVis[NB] = 2 Then Continue;
  If SmVis[NB] = 0 Then Begin
   SmBK[J] := 1; SmPar[NB] := I;
   SmDFS1(NB, J);
   Inc(SmSize[I], SmSize[NB]);
  End
  Else If SmBK[J] = 0 Then SmBK[J] := 2;
 End;
End;

Function SmBondSym(J: Integer): String;
Begin
 Case Bd^[J].Order Of
  2: SmBondSym := '=';
  3: SmBondSym := '#';
 Else If SmSym[J] <> #0 Then SmBondSym := SmSym[J]
 Else SmBondSym := '';
 End;
End;

Function SmChiralOf(I, Ns: Integer; HasFrom: Boolean; Const Sl: Array Of Integer): Integer; Forward;
Procedure SmStereoPrepare; Forward;

Procedure SmWriteAtom(I, ParBond: Integer);
Var
 K, J, NB, R, NCh, A, B, T, NS, Chir : Integer;
 Ch : Array[0..7] Of Integer;
 ChB : Array[0..7] Of Integer;
 Sl : Array[0..7] Of Integer;
 Nk : Integer;
Begin
 { enfants de l'arbre, les plus petits d'abord }
 NCh := 0;
 For K := 0 To AdjN^[I] - 1 Do Begin
  J := AdjB^[I, K]; NB := Adj^[I, K];
  If (SmBK[J] = 1) And (J <> ParBond) And (SmPar[NB] = I) And (NCh < 8) Then Begin
   Ch[NCh] := NB; ChB[NCh] := J; Inc(NCh);
  End;
 End;
 For A := 1 To NCh - 1 Do Begin
  T := A;
  While (T > 0) And (SmSize[Ch[T - 1]] > SmSize[Ch[T]]) Do Begin
   B := Ch[T]; Ch[T] := Ch[T - 1]; Ch[T - 1] := B;
   B := ChB[T]; ChB[T] := ChB[T - 1]; ChB[T - 1] := B;
   Dec(T);
  End;
 End;
 { ordre des voisins tel qu'ecrit : source, H, fermetures de cycles, enfants }
 NS := 0;
 If ParBond >= 0 Then Begin
  If Bd^[ParBond].A = I Then Sl[NS] := Bd^[ParBond].B Else Sl[NS] := Bd^[ParBond].A;
  Inc(NS);
 End;
 If Inf^[I].H = 1 Then Begin Sl[NS] := -1; Inc(NS); End;
 For K := 0 To AdjN^[I] - 1 Do
  If (SmBK[AdjB^[I, K]] = 2) And (NS < 8) Then Begin Sl[NS] := Adj^[I, K]; Inc(NS); End;
 For K := 0 To NCh - 1 Do
  If NS < 8 Then Begin Sl[NS] := Ch[K]; Inc(NS); End;
 Chir := SmChiralOf(I, NS, ParBond >= 0, Sl);
 { atome ou groupe }
 Nk := 0;
 If At^[I].Lbl <> '' Then Nk := FindNick(At^[I].Lbl);
 If Nk > 0 Then SmAdd(Nicks[Nk].Sm) Else SmAdd(SmAtomToken(I, Chir));
 { fermetures / ouvertures de cycles }
 For K := 0 To AdjN^[I] - 1 Do Begin
  J := AdjB^[I, K];
  If SmBK[J] = 2 Then Begin
   If SmBR[J] = 0 Then Begin
    R := 1;
    While (R < 99) And SmUsed[R] Do Inc(R);
    SmUsed[R] := True; SmBR[J] := R;
    SmAdd(SmBondSym(J));
    If R < 10 Then SmAdd(IntToStr(R)) Else SmAdd('%' + IntToStr(R));
   End
   Else Begin
    R := SmBR[J];
    If R < 10 Then SmAdd(IntToStr(R)) Else SmAdd('%' + IntToStr(R));
    SmUsed[R] := False;
   End;
  End;
 End;
 For K := 0 To NCh - 1 Do Begin
  If K < NCh - 1 Then SmAdd('(');
  SmAdd(SmBondSym(ChB[K]));
  SmWriteAtom(Ch[K], ChB[K]);
  If K < NCh - 1 Then SmAdd(')');
 End;
End;

{ Ecrit le SMILES de tout le document (ou de la selection) dans SmBuf }
Procedure WriteSmiles(SelOnly: Boolean);
Var I, J, NRoots: Integer;
Begin
 SmLen := 0;
 UpdateInfo;
 BuildAdj;
 For I := 0 To NAt - 1 Do Begin SmVis[I] := 0; SmPar[I] := -1; End;
 For J := 0 To NBd - 1 Do Begin SmBK[J] := 0; SmBR[J] := 0; End;
 For I := 1 To 99 Do SmUsed[I] := False;
 For J := 0 To NBd - 1 Do SmSym[J] := #0;
 { atomes hors selection : marques visites }
 If SelOnly Then
  For I := 0 To NAt - 1 Do If Not At^[I].Sel Then SmVis[I] := 2;
 NRoots := 0;
 For I := 0 To NAt - 1 Do Begin
  If SmVis[I] <> 0 Then Continue;
  SmDFS1(I, -1);
  SmRoot[NRoots] := I; Inc(NRoots);
 End;
 SmStereoPrepare;
 For I := 0 To NRoots - 1 Do Begin
  If I > 0 Then SmAdd('.');
  SmWriteAtom(SmRoot[I], -1);
 End;
End;

{ --------------------------------------------------------------------- }
{ SMILES : lecture                                                      }
{ --------------------------------------------------------------------- }

Var
 KekMatch : Array[0..MAX_ATOMS - 1] Of Byte;

Function KekSolve: Boolean;
Var I, J, K, NB: Integer; Found: Boolean;
Begin
 I := 0; Found := False;
 While I < NAt Do Begin
  If KekMatch[I] = 1 Then Begin Found := True; Break; End;
  Inc(I);
 End;
 If Not Found Then Begin KekSolve := True; Exit; End;
 BuildAdj;
 For K := 0 To AdjN^[I] - 1 Do Begin
  J := AdjB^[I, K]; NB := Adj^[I, K];
  If (Bd^[J].Order = 4) And (KekMatch[NB] = 1) Then Begin
   KekMatch[I] := 2; KekMatch[NB] := 2; Bd^[J].DPos := 9;
   If KekSolve Then Begin KekSolve := True; Exit; End;
   KekMatch[I] := 1; KekMatch[NB] := 1; Bd^[J].DPos := 0;
  End;
 End;
 KekSolve := False;
End;

Function LowValence(Z, Chg: Integer): Integer;
Var V: Integer;
Begin
 V := NextValence(Z, Chg, 0);
 If V < 0 Then V := 0;
 LowValence := V;
End;

Procedure Kekulize(First: Integer);
Var I, J, Sum, Rem2: Integer; Any: Boolean;
Begin
 Any := False;
 For J := 0 To NBd - 1 Do If Bd^[J].Order = 4 Then Any := True;
 If Not Any Then Exit;
 For I := 0 To NAt - 1 Do KekMatch[I] := 0;
 For I := First To NAt - 1 Do Begin
  If (At^[I].Mark And 4) = 0 Then Continue;
  Sum := 0;
  For J := 0 To NBd - 1 Do
   If (Bd^[J].A = I) Or (Bd^[J].B = I) Then Begin
    If Bd^[J].Order = 4 Then Inc(Sum) Else Inc(Sum, Bd^[J].Order);
   End;
  Rem2 := LowValence(At^[I].Z, At^[I].Chg) - Sum;
  If SmH[I] > 0 Then Dec(Rem2, SmH[I]);
  If Rem2 >= 1 Then KekMatch[I] := 1;
 End;
 If KekSolve Then Begin
  For J := 0 To NBd - 1 Do
   If Bd^[J].Order = 4 Then Begin
    If Bd^[J].DPos = 9 Then Bd^[J].Order := 2 Else Bd^[J].Order := 1;
    Bd^[J].DPos := 0;
   End;
 End
 Else Begin
  For J := 0 To NBd - 1 Do
   If Bd^[J].Order = 4 Then Begin Bd^[J].Order := 1; Bd^[J].DPos := 0; End;
 End;
End;

{ Ajoute V a la liste ordonnee des voisins SMILES de l'atome A }
Procedure SmPush(A, V: Integer);
Begin
 If (A < 0) Or (A >= MAX_ATOMS) Then Exit;
 If SmNn[A] < 5 Then Begin
  SmNb^[A, SmNn[A]] := V;
  Inc(SmNn[A]);
 End;
End;

{ Remplace la fermeture de cycle Ph (placeholder) de A par l'atome V }
Procedure SmResolve(A, Ph, V: Integer);
Var K: Integer;
Begin
 For K := 0 To SmNn[A] - 1 Do
  If SmNb^[A, K] = Ph Then Begin SmNb^[A, K] := V; Exit; End;
End;

{ Lit un SMILES ; les atomes crees sont a l'origine avec Mark=1.
  First / Last = plage d'indices ajoutes. }
Function ParseSmiles(Const S: String; Var First, Last: Integer): Boolean;
Var
 P, Prev, NewA, Pend, Z, Num, K, Hn, Chg, Iso, B2 : Integer;
 Stack : Array[0..63] Of Integer;
 SP : Integer;
 RcAtom, RcOrd, RcDir : Array[0..99] Of Integer;
 C, C2 : Char;
 Arom, Bracket : Boolean;
 Sym : String;
 OK : Boolean;
 Chir, Dir, BJ : Integer;
Begin
 ParseSmiles := False;
 Dir := 0;
 If SmNb = Nil Then New(SmNb);
 First := NAt; Last := NAt - 1;
 OK := True;
 For K := 0 To 99 Do Begin RcAtom[K] := -1; RcOrd[K] := 0; RcDir[K] := 0; End;
 SP := 0; Prev := -1; Pend := 0; P := 1;
 While (P <= Length(S)) And OK Do Begin
  C := S[P];
  Case C Of
   '(' : Begin If SP < 63 Then Begin Stack[SP] := Prev; Inc(SP); End; Inc(P); End;
   ')' : Begin If SP > 0 Then Begin Dec(SP); Prev := Stack[SP]; End; Pend := 0; Dir := 0; Inc(P); End;
   '.' : Begin Prev := -1; Pend := 0; Dir := 0; Inc(P); End;
   '-' : Begin Pend := 1; Inc(P); End;
   '=' : Begin Pend := 2; Inc(P); End;
   '#' : Begin Pend := 3; Inc(P); End;
   ':' : Begin Pend := 4; Inc(P); End;
   '/', '\' : Begin
    If Pend = 0 Then Pend := 1;
    If C = '/' Then Dir := 1 Else Dir := 2;
    Inc(P);
   End;
   '0'..'9', '%' : Begin
    If C = '%' Then Begin
     Num := 0; Inc(P);
     If P + 1 <= Length(S) Then Begin Num := (Ord(S[P]) - 48) * 10 + Ord(S[P + 1]) - 48; Inc(P, 2); End;
    End
    Else Begin Num := Ord(C) - 48; Inc(P); End;
    If (Num < 0) Or (Num > 99) Or (Prev < 0) Then OK := False
    Else If RcAtom[Num] < 0 Then Begin
     RcAtom[Num] := Prev; RcOrd[Num] := Pend; RcDir[Num] := Dir; Pend := 0;
     SmPush(Prev, -(100 + Num));
    End
    Else Begin
     B2 := Pend;
     If B2 = 0 Then B2 := RcOrd[Num];
     If B2 = 0 Then Begin
      If ((At^[Prev].Mark And 4) <> 0) And ((At^[RcAtom[Num]].Mark And 4) <> 0) Then B2 := 4 Else B2 := 1;
     End;
     BJ := NewBond(RcAtom[Num], Prev, B2, ST_NORMAL);
     If BJ >= 0 Then Begin
      { symbole / ou \ : celui de l'ouverture, sinon celui de la fermeture inverse }
      If RcDir[Num] <> 0 Then SmDir[BJ] := RcDir[Num]
      Else If Dir = 1 Then SmDir[BJ] := 2
      Else If Dir = 2 Then SmDir[BJ] := 1
      Else SmDir[BJ] := 0;
     End;
     Dir := 0;
     SmResolve(RcAtom[Num], -(100 + Num), Prev);
     SmPush(Prev, RcAtom[Num]);
     RcAtom[Num] := -1; Pend := 0;
    End;
   End;
  Else
   { atome }
   Arom := False; Bracket := False; Hn := 0; Chg := 0; Iso := 0; Z := 0; Chir := 0;
   If C = '[' Then Begin
    Bracket := True;
    Inc(P);
    While (P <= Length(S)) And IsDigitCh(S[P]) Do Begin Iso := Iso * 10 + Ord(S[P]) - 48; Inc(P); End;
    Sym := '';
    If P <= Length(S) Then Begin
     C2 := S[P];
     If (C2 >= 'a') And (C2 <= 'z') Then Begin
      Arom := True;
      Sym := UpCh(C2); Inc(P);
      If (P <= Length(S)) And (Sym + S[P] = 'Se') Then Begin Sym := 'Se'; Inc(P); End;
      If (P <= Length(S)) And (Sym = 'A') And (S[P] = 's') Then Begin Sym := 'As'; Inc(P); End;
     End
     Else If (C2 >= 'A') And (C2 <= 'Z') Then Begin
      Sym := C2; Inc(P);
      If (P <= Length(S)) And (S[P] >= 'a') And (S[P] <= 'z') And (ElemBySymbol(Sym + S[P]) > 0) Then Begin
       Sym := Sym + S[P]; Inc(P);
      End;
     End
     Else If C2 = '*' Then Begin Sym := '*'; Inc(P); End;
    End;
    If Sym = '*' Then Z := 0 Else Z := ElemBySymbol(Sym);
    If (Z = 0) And (Sym <> '*') Then OK := False;
    While (P <= Length(S)) And (S[P] <> ']') Do Begin
     C2 := S[P];
     If C2 = '@' Then Begin
      Inc(P); Chir := 1;
      If (P <= Length(S)) And (S[P] = '@') Then Begin Chir := 2; Inc(P); End;
      If (P + 1 <= Length(S)) And (S[P] In ['A'..'Z']) And (S[P + 1] In ['A'..'Z']) Then Chir := 0;
     End
     Else If C2 = 'H' Then Begin
      Inc(P); Hn := 1;
      If (P <= Length(S)) And IsDigitCh(S[P]) Then Begin Hn := Ord(S[P]) - 48; Inc(P); End;
     End
     Else If (C2 = '+') Or (C2 = '-') Then Begin
      K := 1; If C2 = '-' Then K := -1;
      Inc(P);
      Chg := K;
      If (P <= Length(S)) And IsDigitCh(S[P]) Then Begin Chg := K * (Ord(S[P]) - 48); Inc(P); End
      Else While (P <= Length(S)) And (S[P] = C2) Do Begin Chg := Chg + K; Inc(P); End;
     End
     Else If C2 = ':' Then Begin
      Inc(P);
      While (P <= Length(S)) And IsDigitCh(S[P]) Do Inc(P);
     End
     Else Inc(P);
    End;
    If P <= Length(S) Then Inc(P);
   End
   Else Begin
    Sym := '';
    Case C Of
     'B': Begin Sym := 'B'; Inc(P); If (P <= Length(S)) And (S[P] = 'r') Then Begin Sym := 'Br'; Inc(P); End; End;
     'C': Begin Sym := 'C'; Inc(P); If (P <= Length(S)) And (S[P] = 'l') Then Begin Sym := 'Cl'; Inc(P); End; End;
     'N', 'O', 'P', 'S', 'F', 'I': Begin Sym := C; Inc(P); End;
     'b', 'c', 'n', 'o', 'p', 's': Begin Sym := UpCh(C); Arom := True; Inc(P); End;
     '*': Begin Sym := '*'; Inc(P); End;
    Else
     OK := False;
    End;
    If OK Then Begin
     If Sym = '*' Then Z := 0 Else Z := ElemBySymbol(Sym);
     If (Z = 0) And (Sym <> '*') Then OK := False;
    End;
   End;
   If OK Then Begin
    NewA := NewAtom(0, 0, Z);
    If NewA < 0 Then OK := False
    Else Begin
     At^[NewA].Mark := 1;
     If Arom Then At^[NewA].Mark := At^[NewA].Mark Or 4;
     At^[NewA].Chg := Chg;
     At^[NewA].Iso := Iso;
     If Z = 0 Then At^[NewA].Lbl := 'R';
     If Bracket Then SmH[NewA] := Hn Else SmH[NewA] := -1;
     SmCh[NewA] := Chir; SmNn[NewA] := 0;
     If Prev >= 0 Then SmFrm[NewA] := 1 Else SmFrm[NewA] := 0;
     If Prev >= 0 Then Begin
      SmPush(NewA, Prev); SmPush(Prev, NewA);
     End;
     If Bracket And (Chir <> 0) And (Hn = 1) Then SmPush(NewA, -1);
     If Prev >= 0 Then Begin
      B2 := Pend;
      If B2 = 0 Then Begin
       If Arom And ((At^[Prev].Mark And 4) <> 0) Then B2 := 4 Else B2 := 1;
      End;
      BJ := NewBond(Prev, NewA, B2, ST_NORMAL);
      If BJ >= 0 Then SmDir[BJ] := Dir;
     End;
     Dir := 0;
     Prev := NewA; Pend := 0;
    End;
   End;
  End;
 End;
 If Not OK Then Exit;
 Last := NAt - 1;
 If Last < First Then Exit;
 Kekulize(First);
 { atomes entre crochets : H explicites -> radicaux eventuels }
 UpdateInfo;
 For K := First To Last Do Begin
  If (SmH[K] >= 0) And (At^[K].Z > 0) And IsOrganicEl(At^[K].Z) And (SmH[K] < Inf^[K].H) Then Begin
   At^[K].Rad := Inf^[K].H - SmH[K];
   If At^[K].Rad > 3 Then At^[K].Rad := 3;
  End;
 End;
 TopoChanged;
 ParseSmiles := True;
End;

{ --------------------------------------------------------------------- }
{ Mise en page 2D automatique (nettoyage, import SMILES, modeles)      }
{ --------------------------------------------------------------------- }

Var
 LQ       : Array[0..MAX_ATOMS - 1] Of Integer;
 LQH, LQT : Integer;
 RingSys  : Array[0..MAX_RINGS - 1] Of Integer;
 RingDone : Array[0..MAX_RINGS - 1] Of Boolean;

Function IsPlaced(I: Integer): Boolean;
Begin
 IsPlaced := (At^[I].Mark And 2) <> 0;
End;

Procedure PutAtom(I: Integer; X, Y: Real);
Begin
 At^[I].X := X; At^[I].Y := Y;
 At^[I].Mark := At^[I].Mark Or 2;
 If LQT < MAX_ATOMS Then Begin LQ[LQT] := I; Inc(LQT); End;
End;

Procedure ComputeRingSystems;
Var R, Q, I, J, Old: Integer; Changed, Shared: Boolean;
Begin
 EnsureRings;
 For R := 0 To NRings - 1 Do RingSys[R] := R;
 Repeat
  Changed := False;
  For R := 0 To NRings - 1 Do
   For Q := R + 1 To NRings - 1 Do
    If RingSys[R] <> RingSys[Q] Then Begin
     Shared := False;
     For I := 0 To RingN[R] - 1 Do
      For J := 0 To RingN[Q] - 1 Do
       If RingA[R, I] = RingA[Q, J] Then Shared := True;
     If Shared Then Begin
      Old := RingSys[Q];
      For I := 0 To NRings - 1 Do If RingSys[I] = Old Then RingSys[I] := RingSys[R];
      Changed := True;
     End;
    End;
 Until Not Changed;
End;

Function RingRadius(N: Integer): Real;
Begin
 RingRadius := BOND_LEN / (2 * Sin(Pi / N));
End;

{ Place un anneau : tient compte des atomes deja places }
Procedure PlaceRing(Rg: Integer);
Var
 N, K, NPl, I0, A, B, Q, J, Run, S0, S1, T : Integer;
 Cyc : Array[0..MAX_RING_SZ - 1] Of Integer;
 Pl : Array[0..MAX_RING_SZ - 1] Of Boolean;
 CX, CY, R, Th0, ThB, S, MX, MY, PX, PY, RX, RY, Ap, L, UX, UY, SX2, SY2, Amp : Real;
 Found : Boolean;
 Nb : Integer;
Begin
 N := RingN[Rg];
 For K := 0 To N - 1 Do Begin Cyc[K] := RingA[Rg, K]; Pl[K] := IsPlaced(Cyc[K]); End;
 NPl := 0; I0 := -1;
 For K := 0 To N - 1 Do If Pl[K] Then Begin Inc(NPl); If I0 < 0 Then I0 := K; End;
 R := RingRadius(N);
 If NPl = N Then Exit;
 If NPl = 0 Then Begin
  { anneau libre au centre de l'origine }
  For K := 0 To N - 1 Do
   PutAtom(Cyc[K], R * Cos(-Pi / 2 + K * 2 * Pi / N), R * Sin(-Pi / 2 + K * 2 * Pi / N));
  Exit;
 End;
 { deux atomes adjacents places : cycle fusionne }
 A := -1;
 If NPl = 2 Then
  For K := 0 To N - 1 Do
   If Pl[K] And Pl[(K + 1) Mod N] Then A := K;
 If (NPl = 2) And (A >= 0) Then Begin
  { reordonne : c0 = Cyc[A], c1 = Cyc[A+1] }
  B := (A + 1) Mod N;
  MX := (At^[Cyc[A]].X + At^[Cyc[B]].X) / 2;
  MY := (At^[Cyc[A]].Y + At^[Cyc[B]].Y) / 2;
  { point de reference : centre d'un anneau deja place contenant les deux atomes }
  RX := 0; RY := 0; Found := False;
  For Q := 0 To NRings - 1 Do Begin
   If (Q = Rg) Or Not RingDone[Q] Then Continue;
   I0 := 0; J := 0;
   For K := 0 To RingN[Q] - 1 Do Begin
    If RingA[Q, K] = Cyc[A] Then Inc(I0);
    If RingA[Q, K] = Cyc[B] Then Inc(J);
   End;
   If (I0 > 0) And (J > 0) Then Begin
    For K := 0 To RingN[Q] - 1 Do Begin
     RX := RX + At^[RingA[Q, K]].X; RY := RY + At^[RingA[Q, K]].Y;
    End;
    RX := RX / RingN[Q]; RY := RY / RingN[Q];
    Found := True; Break;
   End;
  End;
  If Not Found Then Begin
   Nb := 0; RX := 0; RY := 0;
   For K := 0 To NAt - 1 Do
    If IsPlaced(K) And (K <> Cyc[A]) And (K <> Cyc[B]) Then Begin
     RX := RX + At^[K].X; RY := RY + At^[K].Y; Inc(Nb);
    End;
   If Nb > 0 Then Begin RX := RX / Nb; RY := RY / Nb; End Else Begin RX := MX; RY := MY - 1; End;
  End;
  L := Dist(At^[Cyc[A]].X, At^[Cyc[A]].Y, At^[Cyc[B]].X, At^[Cyc[B]].Y);
  If L < 0.001 Then L := 0.001;
  UX := -(At^[Cyc[B]].Y - At^[Cyc[A]].Y) / L;
  UY := (At^[Cyc[B]].X - At^[Cyc[A]].X) / L;
  If (RX - MX) * UX + (RY - MY) * UY > 0 Then Begin UX := -UX; UY := -UY; End;
  Ap := BOND_LEN / (2 * Tan(Pi / N));
  CX := MX + UX * Ap; CY := MY + UY * Ap;
  Th0 := Atan2(At^[Cyc[A]].Y - CY, At^[Cyc[A]].X - CX);
  ThB := Atan2(At^[Cyc[B]].Y - CY, At^[Cyc[B]].X - CX);
  S := 1; If NormAng(ThB - Th0) < 0 Then S := -1;
  For K := 2 To N - 1 Do Begin
   T := (A + K) Mod N;
   If Not Pl[T] Then
    PutAtom(Cyc[T], CX + R * Cos(Th0 + S * K * 2 * Pi / N), CY + R * Sin(Th0 + S * K * 2 * Pi / N));
  End;
  Exit;
 End;
 { un seul atome place (ou atomes non adjacents) : cycle attache }
 If NPl = 1 Then Begin
  A := I0;
  PX := At^[Cyc[A]].X; PY := At^[Cyc[A]].Y;
  UX := 0; UY := 0;
  For K := 0 To NBd - 1 Do Begin
   If Bd^[K].A = Cyc[A] Then Q := Bd^[K].B
   Else If Bd^[K].B = Cyc[A] Then Q := Bd^[K].A
   Else Continue;
   If IsPlaced(Q) Then Begin
    L := Dist(PX, PY, At^[Q].X, At^[Q].Y);
    If L > 0.001 Then Begin
     UX := UX + (At^[Q].X - PX) / L; UY := UY + (At^[Q].Y - PY) / L;
    End;
   End;
  End;
  L := Sqrt(UX * UX + UY * UY);
  If L < 0.05 Then Begin UX := 0; UY := 1; End
  Else Begin UX := -UX / L; UY := -UY / L; End;
  CX := PX + UX * R; CY := PY + UY * R;
  Th0 := Atan2(PY - CY, PX - CX);
  For K := 1 To N - 1 Do Begin
   T := (A + K) Mod N;
   PutAtom(Cyc[T], CX + R * Cos(Th0 + K * 2 * Pi / N), CY + R * Sin(Th0 + K * 2 * Pi / N));
  End;
  Exit;
 End;
 { pontage : repartit les atomes manquants entre les atomes places }
 CX := 0; CY := 0;
 For K := 0 To N - 1 Do If Pl[K] Then Begin CX := CX + At^[Cyc[K]].X; CY := CY + At^[Cyc[K]].Y; End;
 CX := CX / NPl; CY := CY / NPl;
 K := 0;
 While K < N Do Begin
  If Not Pl[K] And Pl[(K + N - 1) Mod N] Then Begin
   S0 := (K + N - 1) Mod N;
   Run := 0; T := K;
   While Not Pl[T] Do Begin Inc(Run); T := (T + 1) Mod N; End;
   S1 := T;
   SX2 := At^[Cyc[S0]].X; SY2 := At^[Cyc[S0]].Y;
   L := Dist(SX2, SY2, At^[Cyc[S1]].X, At^[Cyc[S1]].Y);
   If L < 0.001 Then L := 0.001;
   UX := -(At^[Cyc[S1]].Y - SY2) / L; UY := (At^[Cyc[S1]].X - SX2) / L;
   MX := (SX2 + At^[Cyc[S1]].X) / 2; MY := (SY2 + At^[Cyc[S1]].Y) / 2;
   If (CX - MX) * UX + (CY - MY) * UY > 0 Then Begin UX := -UX; UY := -UY; End;
   Amp := 0.6 * BOND_LEN;
   For J := 1 To Run Do Begin
    T := (S0 + J) Mod N;
    PutAtom(Cyc[T], SX2 + (At^[Cyc[S1]].X - SX2) * J / (Run + 1) + UX * Amp * Sin(Pi * J / (Run + 1)),
                    SY2 + (At^[Cyc[S1]].Y - SY2) * J / (Run + 1) + UY * Amp * Sin(Pi * J / (Run + 1)));
   End;
   K := K + Run;
  End
  Else Inc(K);
 End;
 For K := 0 To N - 1 Do
  If Not IsPlaced(Cyc[K]) Then PutAtom(Cyc[K], CX + K, CY + K);
End;

{ Place tout un systeme d'anneaux ; Atom0 = atome d'attache deja place (ou -1) }
Procedure PlaceSystem(Sys, Atom0: Integer);
Var
 R, K, Best, BestN, Cnt, First : Integer;
Begin
 First := -1;
 If Atom0 >= 0 Then Begin
  For R := 0 To NRings - 1 Do
   If (RingSys[R] = Sys) And Not RingDone[R] Then Begin
    For K := 0 To RingN[R] - 1 Do
     If RingA[R, K] = Atom0 Then Begin
      If (First < 0) Or (RingN[R] < RingN[First]) Then First := R;
     End;
   End;
 End;
 If First < 0 Then Begin
  For R := 0 To NRings - 1 Do
   If (RingSys[R] = Sys) And Not RingDone[R] Then
    If (First < 0) Or (RingN[R] > RingN[First]) Then First := R;
 End;
 If First < 0 Then Exit;
 PlaceRing(First);
 RingDone[First] := True;
 Repeat
  Best := -1; BestN := 0;
  For R := 0 To NRings - 1 Do
   If (RingSys[R] = Sys) And Not RingDone[R] Then Begin
    Cnt := 0;
    For K := 0 To RingN[R] - 1 Do If IsPlaced(RingA[R, K]) Then Inc(Cnt);
    If Cnt > BestN Then Begin BestN := Cnt; Best := R; End;
   End;
  If Best >= 0 Then Begin
   PlaceRing(Best);
   RingDone[Best] := True;
  End;
 Until Best < 0;
 { anneaux d'un systeme sans atome partage place : placement libre }
 For R := 0 To NRings - 1 Do
  If (RingSys[R] = Sys) And Not RingDone[R] Then Begin
   PlaceRing(R);
   RingDone[R] := True;
  End;
 
End;

Function LinearAtom(A: Integer): Boolean;
Var K, N2: Integer;
Begin
 N2 := 0;
 LinearAtom := False;
 For K := 0 To NBd - 1 Do
  If (Bd^[K].A = A) Or (Bd^[K].B = A) Then Begin
   If Bd^[K].Order = 3 Then LinearAtom := True;
   If Bd^[K].Order = 2 Then Inc(N2);
  End;
 If N2 >= 2 Then LinearAtom := True;
End;

Function RingUndone(N: Integer): Integer;
{ indice d'un anneau non place contenant l'atome N, ou -1 }
Var R, K: Integer;
Begin
 RingUndone := -1;
 For R := 0 To NRings - 1 Do
  If Not RingDone[R] Then
   For K := 0 To RingN[R] - 1 Do
    If RingA[R, K] = N Then Begin RingUndone := R; Exit; End;
End;

Function MinDistPlaced(PX, PY: Real; Excl: Integer): Real;
Var K: Integer; D, M: Real;
Begin
 M := 1E9;
 For K := 0 To NAt - 1 Do
  If IsPlaced(K) And (K <> Excl) Then Begin
   D := Dist(PX, PY, At^[K].X, At^[K].Y);
   If D < M Then M := D;
  End;
 MinDistPlaced := M;
End;

{ Place les voisins non places de l'atome A }
Procedure PlaceChildren(A: Integer);
Var
 U : Array[0..7] Of Integer;
 PA : Array[0..7] Of Real;
 NU, NP, K, I, J, G, Rg : Integer;
 Ang : Array[0..7] Of Real;
 AX, AY, Desired, C1, C2, P1X, P1Y, P2X, P2Y, D1, D2, BestGap, GapStart, Gap, T : Real;
 Nb : Integer;
Begin
 NU := 0; NP := 0;
 AX := At^[A].X; AY := At^[A].Y;
 For K := 0 To AdjN^[A] - 1 Do Begin
  Nb := Adj^[A, K];
  If IsPlaced(Nb) Then Begin
   If NP < 8 Then Begin PA[NP] := Atan2(At^[Nb].Y - AY, At^[Nb].X - AX); Inc(NP); End;
  End
  Else If NU < 8 Then Begin U[NU] := Nb; Inc(NU); End;
 End;
 If NU = 0 Then Exit;
 If NP = 0 Then Begin
  Case NU Of
   1: Ang[0] := -Pi / 6;
   2: Begin Ang[0] := -Pi / 6; Ang[1] := -Pi / 6 + 2 * Pi / 3; End;
   3: Begin Ang[0] := -Pi / 2; Ang[1] := -Pi / 2 + 2 * Pi / 3; Ang[2] := -Pi / 2 + 4 * Pi / 3; End;
  Else
   For K := 0 To NU - 1 Do Ang[K] := -Pi / 2 + K * 2 * Pi / NU;
  End;
 End
 Else If (NP = 1) And (NU = 1) Then Begin
  If LinearAtom(A) Then Ang[0] := PA[0] + Pi
  Else Begin
   C1 := PA[0] + 2 * Pi / 3; C2 := PA[0] - 2 * Pi / 3;
   { zigzag : parallele a la liaison grand-parent -> parent }
   Nb := -1; G := -1;
   For K := 0 To AdjN^[A] - 1 Do If IsPlaced(Adj^[A, K]) Then Nb := Adj^[A, K];
   If Nb >= 0 Then
    For K := 0 To AdjN^[Nb] - 1 Do
     If (Adj^[Nb, K] <> A) And IsPlaced(Adj^[Nb, K]) Then G := Adj^[Nb, K];
   If G >= 0 Then Begin
    Desired := Atan2(At^[Nb].Y - At^[G].Y, At^[Nb].X - At^[G].X);
    If AbsR(NormAng(C1 - Desired)) <= AbsR(NormAng(C2 - Desired)) Then Ang[0] := C1 Else Ang[0] := C2;
   End
   Else If AbsR(NormAng(C1)) <= AbsR(NormAng(C2)) Then Ang[0] := C1
   Else Ang[0] := C2;
   P1X := AX + BOND_LEN * Cos(C1); P1Y := AY + BOND_LEN * Sin(C1);
   P2X := AX + BOND_LEN * Cos(C2); P2Y := AY + BOND_LEN * Sin(C2);
   D1 := MinDistPlaced(P1X, P1Y, -1);
   D2 := MinDistPlaced(P2X, P2Y, -1);
   If (Ang[0] = C1) And (D1 < 0.6 * BOND_LEN) And (D2 > D1) Then Ang[0] := C2
   Else If (Ang[0] = C2) And (D2 < 0.6 * BOND_LEN) And (D1 > D2) Then Ang[0] := C1;
  End;
 End
 Else Begin
  { plus grand angle libre entre les voisins places }
  For I := 1 To NP - 1 Do Begin
   T := PA[I]; J := I - 1;
   While (J >= 0) And (PA[J] > T) Do Begin PA[J + 1] := PA[J]; Dec(J); End;
   PA[J + 1] := T;
  End;
  BestGap := -1; GapStart := PA[0];
  For I := 0 To NP - 1 Do Begin
   If I < NP - 1 Then Gap := PA[I + 1] - PA[I] Else Gap := PA[0] + 2 * Pi - PA[I];
   If NP = 1 Then Gap := 2 * Pi;
   If Gap > BestGap Then Begin BestGap := Gap; GapStart := PA[I]; End;
  End;
  For K := 0 To NU - 1 Do Ang[K] := GapStart + BestGap * (K + 1) / (NU + 1);
 End;
 For K := 0 To NU - 1 Do Begin
  If IsPlaced(U[K]) Then Continue;
  PutAtom(U[K], AX + BOND_LEN * Cos(Ang[K]), AY + BOND_LEN * Sin(Ang[K]));
  Rg := RingUndone(U[K]);
  If Rg >= 0 Then PlaceSystem(RingSys[Rg], U[K]);
 End;
 
End;

Procedure GrowQueue;
Var A: Integer;
Begin
 While LQH < LQT Do Begin
  A := LQ[LQH]; Inc(LQH);
  PlaceChildren(A);
 End;
End;

{ Initialise les drapeaux d'anneaux realises }
Procedure InitRingDone;
Var R, K: Integer; All: Boolean;
Begin
 ComputeRingSystems;
 For R := 0 To NRings - 1 Do Begin
  All := True;
  For K := 0 To RingN[R] - 1 Do If Not IsPlaced(RingA[R, K]) Then All := False;
  RingDone[R] := All;
 End;
End;

{ Met en page les atomes marques (Mark bit 1) ; centre le resultat en (CX,CY) }
Procedure LayoutMarked(CX, CY: Real);
Var
 I, K, R, Best, BestCnt, CompN, Head, Tail, Cur, Nb, Sy, StartI : Integer;
 Members : Array[0..MAX_ATOMS - 1] Of Integer;
 MinX, MaxX, MinY, MaxY, CurX, DX, TMinX, TMaxX, TMinY, TMaxY : Real;
 Cnt2 : Integer;
Begin
 BuildAdj;
 ComputeRingSystems;
 For I := 0 To NAt - 1 Do
  If (At^[I].Mark And 1) <> 0 Then At^[I].Mark := At^[I].Mark And 253
  Else At^[I].Mark := At^[I].Mark Or 2;
 For R := 0 To NRings - 1 Do RingDone[R] := False;
 CurX := 0;
 TMinX := 1E9; TMaxX := -1E9; TMinY := 1E9; TMaxY := -1E9;
 For StartI := 0 To NAt - 1 Do Begin
  If ((At^[StartI].Mark And 1) = 0) Or IsPlaced(StartI) Then Continue;
  { composante connexe }
  Head := 0; Tail := 1;
  Members[0] := StartI;
  { BFS en utilisant le drapeau 8 comme "vu" }
  At^[StartI].Mark := At^[StartI].Mark Or 8;
  While Head < Tail Do Begin
   Cur := Members[Head]; Inc(Head);
   For K := 0 To AdjN^[Cur] - 1 Do Begin
    Nb := Adj^[Cur, K];
    If ((At^[Nb].Mark And 8) = 0) And ((At^[Nb].Mark And 1) <> 0) Then Begin
     At^[Nb].Mark := At^[Nb].Mark Or 8;
     Members[Tail] := Nb; Inc(Tail);
    End;
   End;
  End;
  CompN := Tail;
  { systeme d'anneaux de depart : le plus gros }
  Best := -1; BestCnt := 0;
  For R := 0 To NRings - 1 Do Begin
   If RingDone[R] Then Continue;
   If (At^[RingA[R, 0]].Mark And 8) = 0 Then Continue;
   Cnt2 := 0;
   For K := 0 To NRings - 1 Do If RingSys[K] = RingSys[R] Then Inc(Cnt2);
   Cnt2 := Cnt2 * 100 + RingN[R];
   If Cnt2 > BestCnt Then Begin BestCnt := Cnt2; Best := R; End;
  End;
  LQH := 0; LQT := 0;
  If Best >= 0 Then Begin
   Sy := RingSys[Best];
   PlaceSystem(Sy, -1);
  End
  Else PutAtom(StartI, 0, 0);
  GrowQueue;
  { atomes restants (securite) }
  For K := 0 To CompN - 1 Do
   If Not IsPlaced(Members[K]) Then Begin
    PutAtom(Members[K], 0, 0);
    GrowQueue;
   End;
  { boite englobante puis decalage a droite du precedent }
  MinX := 1E9; MaxX := -1E9; MinY := 1E9; MaxY := -1E9;
  For K := 0 To CompN - 1 Do Begin
   If At^[Members[K]].X < MinX Then MinX := At^[Members[K]].X;
   If At^[Members[K]].X > MaxX Then MaxX := At^[Members[K]].X;
   If At^[Members[K]].Y < MinY Then MinY := At^[Members[K]].Y;
   If At^[Members[K]].Y > MaxY Then MaxY := At^[Members[K]].Y;
  End;
  DX := CurX - MinX;
  For K := 0 To CompN - 1 Do Begin
   At^[Members[K]].X := At^[Members[K]].X + DX;
   At^[Members[K]].Y := At^[Members[K]].Y - (MinY + MaxY) / 2;
  End;
  CurX := MaxX + DX + 2.2 * BOND_LEN;
  If MinX + DX < TMinX Then TMinX := MinX + DX;
  If MaxX + DX > TMaxX Then TMaxX := MaxX + DX;
  If (MinY - (MinY + MaxY) / 2) < TMinY Then TMinY := MinY - (MinY + MaxY) / 2;
  If (MaxY - (MinY + MaxY) / 2) > TMaxY Then TMaxY := MaxY - (MinY + MaxY) / 2;
 End;
 { centrage global }
 If TMinX > TMaxX Then Begin
  For I := 0 To NAt - 1 Do At^[I].Mark := 0;
  Exit;
 End;
 DX := CX - (TMinX + TMaxX) / 2;
 For I := 0 To NAt - 1 Do
  If (At^[I].Mark And 1) <> 0 Then Begin
   At^[I].X := At^[I].X + DX;
   At^[I].Y := At^[I].Y + CY - (TMinY + TMaxY) / 2;
  End;
 For I := 0 To NAt - 1 Do At^[I].Mark := 0;
 Touch;
End;

{ Marque les fragments contenant des atomes selectionnes (ou tous) }
Procedure MarkFragments(SelOnly: Boolean);
Var I, Head, Tail, Cur, K, Nb: Integer;
Begin
 BuildAdj;
 For I := 0 To NAt - 1 Do At^[I].Mark := 0;
 If Not SelOnly Then Begin
  For I := 0 To NAt - 1 Do At^[I].Mark := 1;
  Exit;
 End;
 For I := 0 To NAt - 1 Do
  If At^[I].Sel And ((At^[I].Mark And 1) = 0) Then Begin
   Head := 0; Tail := 1; Tmp2^[0] := I; At^[I].Mark := 1;
   While Head < Tail Do Begin
    Cur := Tmp2^[Head]; Inc(Head);
    For K := 0 To AdjN^[Cur] - 1 Do Begin
     Nb := Adj^[Cur, K];
     If (At^[Nb].Mark And 1) = 0 Then Begin
      At^[Nb].Mark := 1; Tmp2^[Tail] := Nb; Inc(Tail);
     End;
    End;
   End;
  End;
End;

Procedure CaptureStereo; Forward;
Procedure RestoreStereo; Forward;

{ Nettoyage de la structure : refait la mise en page des fragments }
Procedure CleanUpStructure;
Var
 I, N : Integer;
 CX, CY : Real;
 SelOnly : Boolean;
Begin
 SelOnly := CountSelAtoms > 0;
 MarkFragments(SelOnly);
 CX := 0; CY := 0; N := 0;
 For I := 0 To NAt - 1 Do
  If (At^[I].Mark And 1) <> 0 Then Begin
   CX := CX + At^[I].X; CY := CY + At^[I].Y; Inc(N);
  End;
 If N = 0 Then Exit;
 CX := CX / N; CY := CY / N;
 CaptureStereo;
 LayoutMarked(CX, CY);
 RestoreStereo;
End;

{ Supprime les atomes d'indice >= F (annule un import rate) }
Procedure TruncateAtoms(F: Integer);
Var K, J: Integer;
Begin
 J := 0;
 For K := 0 To NBd - 1 Do
  If (Bd^[K].A < F) And (Bd^[K].B < F) Then Begin Bd^[J] := Bd^[K]; Inc(J); End;
 NBd := J;
 If NAt > F Then NAt := F;
 TopoChanged;
 Touch;
End;

{ Centre visible du canevas en coordonnees document }
Procedure ViewCenter(Var CX, CY: Real);
Begin
 CX := ScrollX + (CvX2 - CvX1) / 2 / Zoom;
 CY := ScrollY + (CvY2 - CvY1) / 2 / Zoom;
End;

Procedure ApplySmilesChirality(F, L: Integer); Forward;

{ Ajoute un SMILES au document, centre en (CX,CY) ; selectionne les nouveaux atomes }
Function AddSmilesAt(Const S: String; CX, CY: Real): Boolean;
Var F, L, I: Integer;
Begin
 AddSmilesAt := False;
 F := NAt;
 If Not ParseSmiles(S, F, L) Then Begin
  TruncateAtoms(F);
  Exit;
 End;
 LayoutMarked(CX, CY);
 ApplySmilesChirality(F, L);
 ClearSelection;
 For I := F To L Do At^[I].Sel := True;
 AddSmilesAt := True;
End;

{ Remplace un groupe d'atomes (Me, Ph, ...) par ses atomes reels }
Procedure ExpandLabel(I: Integer);
Var
 K, F, L, J, Q, OldN : Integer;
 Sm : String;
Begin
 If (I < 0) Or (I >= NAt) Or (At^[I].Lbl = '') Then Exit;
 K := FindNick(At^[I].Lbl);
 If K = 0 Then Exit;
 Sm := Nicks[K].Sm;
 OldN := NAt;
 If Not ParseSmiles(Sm, F, L) Then Begin TruncateAtoms(OldN); Exit; End;
 At^[I].Z := At^[F].Z;
 At^[I].Chg := At^[F].Chg;
 At^[I].Iso := At^[F].Iso;
 At^[I].Lbl := '';
 For J := 0 To NBd - 1 Do Begin
  If Bd^[J].A = F Then Bd^[J].A := I;
  If Bd^[J].B = F Then Bd^[J].B := I;
 End;
 { supprime l'atome F (qui n'a plus de liaison propre) }
 For Q := F To NAt - 2 Do At^[Q] := At^[Q + 1];
 Dec(NAt);
 For J := 0 To NBd - 1 Do Begin
  If Bd^[J].A > F Then Dec(Bd^[J].A);
  If Bd^[J].B > F Then Dec(Bd^[J].B);
 End;
 TopoChanged;
 BuildAdj;
 For Q := 0 To NAt - 1 Do Begin
  If (Q >= F) And (Q < NAt) Then At^[Q].Mark := 0 Else At^[Q].Mark := 2;
 End;
 InitRingDone;
 LQH := 0; LQT := 0;
 LQ[0] := I; LQT := 1;
 GrowQueue;
 For Q := 0 To NAt - 1 Do At^[Q].Mark := 0;
 Touch;
End;

Procedure ExpandAllLabels;
Var I: Integer;
Begin
 I := 0;
 While I < NAt Do Begin
  If (At^[I].Lbl <> '') And (FindNick(At^[I].Lbl) > 0) Then ExpandLabel(I);
  Inc(I);
 End;
End;

{ --------------------------------------------------------------------- }
{ Fichiers : format natif CDT, MOL, SMILES, SVG, BMP                    }
{ --------------------------------------------------------------------- }

Function NextTok(Var S: String): String;
Var P: Integer;
Begin
 S := TrimStr(S);
 P := Pos(' ', S);
 If P = 0 Then Begin NextTok := S; S := ''; End
 Else Begin NextTok := Copy(S, 1, P - 1); S := Copy(S, P + 1, 255); End;
End;

Function SaveCDT(Const FN: String): Boolean;
Var F: Text; I: Integer; L: String;
Begin
 {$I-}
 Assign(F, FN); Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Begin SaveCDT := False; Exit; End;
 WriteLn(F, 'CDT1');
 For I := 0 To NAt - 1 Do Begin
  L := At^[I].Lbl; If L = '' Then L := '-';
  WriteLn(F, 'A ', RealToStr(At^[I].X, 2), ' ', RealToStr(At^[I].Y, 2), ' ',
          At^[I].Z, ' ', At^[I].Chg, ' ', At^[I].Iso, ' ', At^[I].Rad, ' ',
          At^[I].Col, ' ', L);
 End;
 For I := 0 To NBd - 1 Do
  WriteLn(F, 'B ', Bd^[I].A, ' ', Bd^[I].B, ' ', Bd^[I].Order, ' ',
          Bd^[I].Sty, ' ', Bd^[I].DPos, ' ', Bd^[I].Col);
 For I := 0 To NTx - 1 Do
  WriteLn(F, 'T ', RealToStr(Tx^[I].X, 2), ' ', RealToStr(Tx^[I].Y, 2), ' ',
          Tx^[I].Col, ' ', Tx^[I].Siz, ' ', Tx^[I].S);
 For I := 0 To NSh - 1 Do
  WriteLn(F, 'S ', Sh^[I].Kind, ' ', RealToStr(Sh^[I].X1, 2), ' ', RealToStr(Sh^[I].Y1, 2), ' ',
          RealToStr(Sh^[I].X2, 2), ' ', RealToStr(Sh^[I].Y2, 2), ' ',
          RealToStr(Sh^[I].CX, 2), ' ', RealToStr(Sh^[I].CY, 2), ' ', Sh^[I].Col);
 Close(F);
 SaveCDT := True;
End;

Function LoadCDT(Const FN: String): Boolean;
Var
 F : Text; Line, T : String;
Begin
 LoadCDT := False;
 {$I-}
 Assign(F, FN); Reset(F);
 {$I+}
 If IOResult <> 0 Then Exit;
 NAt := 0; NBd := 0; NTx := 0; NSh := 0;
 While Not Eof(F) Do Begin
  ReadLn(F, Line);
  Line := TrimStr(Line);
  If Length(Line) < 2 Then Continue;
  T := NextTok(Line);
  If T = 'A' Then Begin
   If NAt < MAX_ATOMS Then Begin
    At^[NAt].X := StrToRealDef(NextTok(Line), 0);
    At^[NAt].Y := StrToRealDef(NextTok(Line), 0);
    At^[NAt].Z := StrToIntDef(NextTok(Line), 6);
    At^[NAt].Chg := StrToIntDef(NextTok(Line), 0);
    At^[NAt].Iso := StrToIntDef(NextTok(Line), 0);
    At^[NAt].Rad := StrToIntDef(NextTok(Line), 0);
    At^[NAt].Col := StrToIntDef(NextTok(Line), 0);
    T := NextTok(Line);
    If T = '-' Then T := '';
    At^[NAt].Lbl := T;
    At^[NAt].Sel := False; At^[NAt].Mark := 0;
    Inc(NAt);
   End;
  End
  Else If T = 'B' Then Begin
   If NBd < MAX_BONDS Then Begin
    Bd^[NBd].A := StrToIntDef(NextTok(Line), 0);
    Bd^[NBd].B := StrToIntDef(NextTok(Line), 0);
    Bd^[NBd].Order := StrToIntDef(NextTok(Line), 1);
    Bd^[NBd].Sty := StrToIntDef(NextTok(Line), 0);
    Bd^[NBd].DPos := StrToIntDef(NextTok(Line), 0);
    Bd^[NBd].Col := StrToIntDef(NextTok(Line), 0);
    If (Bd^[NBd].A >= 0) And (Bd^[NBd].A < NAt) And (Bd^[NBd].B >= 0) And (Bd^[NBd].B < NAt) Then Inc(NBd);
   End;
  End
  Else If T = 'T' Then Begin
   If NTx < MAX_TEXTS Then Begin
    Tx^[NTx].X := StrToRealDef(NextTok(Line), 0);
    Tx^[NTx].Y := StrToRealDef(NextTok(Line), 0);
    Tx^[NTx].Col := StrToIntDef(NextTok(Line), 0);
    Tx^[NTx].Siz := StrToIntDef(NextTok(Line), 1);
    Tx^[NTx].S := Line;
    Tx^[NTx].Sel := False;
    Inc(NTx);
   End;
  End
  Else If T = 'S' Then Begin
   If NSh < MAX_SHAPES Then Begin
    Sh^[NSh].Kind := StrToIntDef(NextTok(Line), 1);
    Sh^[NSh].X1 := StrToRealDef(NextTok(Line), 0);
    Sh^[NSh].Y1 := StrToRealDef(NextTok(Line), 0);
    Sh^[NSh].X2 := StrToRealDef(NextTok(Line), 0);
    Sh^[NSh].Y2 := StrToRealDef(NextTok(Line), 0);
    Sh^[NSh].CX := StrToRealDef(NextTok(Line), 0);
    Sh^[NSh].CY := StrToRealDef(NextTok(Line), 0);
    Sh^[NSh].Col := StrToIntDef(NextTok(Line), 0);
    Sh^[NSh].Sel := False;
    Inc(NSh);
   End;
  End;
 End;
 Close(F);
 TopoChanged;
 Touch;
 LoadCDT := True;
End;

{ Fichier MOL (V2000) ; l'echelle est de 1.5 angstroem = BOND_LEN pixels }
Function SaveMOL(Const FN: String): Boolean;
Var
 F : Text; I, N, K, Cnt : Integer;
 Snap : TSnap;
 Sc : Real;
 Mod0 : Boolean;
 ChgL : String;
 Function F4(V: Real): String;
 Begin F4 := PadL(RealToStr(V, 4), 10); End;
Begin
 {$I-}
 Assign(F, FN); Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Begin SaveMOL := False; Exit; End;
 Mod0 := Modified;
 TakeSnap(Snap);
 ExpandAllLabels;
 UpdateInfo;
 Sc := 1.5 / BOND_LEN;
 WriteLn(F, 'ChemDraw clone');
 WriteLn(F, '  CHEMDRAW.PAS');
 WriteLn(F, '');
 WriteLn(F, PadL(IntToStr(NAt), 3), PadL(IntToStr(NBd), 3), '  0  0  0  0  0  0  0  0999 V2000');
 For I := 0 To NAt - 1 Do Begin
  If At^[I].Z = 0 Then ChgL := 'R' Else ChgL := ElSym[At^[I].Z];
  WriteLn(F, F4(At^[I].X * Sc), F4(-At^[I].Y * Sc), F4(0), ' ', PadR(ChgL, 3),
          ' 0  0  0  0  0  0  0  0  0  0  0  0');
 End;
 For I := 0 To NBd - 1 Do Begin
  K := 0;
  If Bd^[I].Sty = ST_WEDGE Then K := 1
  Else If Bd^[I].Sty = ST_HASH Then K := 6
  Else If Bd^[I].Sty = ST_WAVY Then K := 4;
  WriteLn(F, PadL(IntToStr(Bd^[I].A + 1), 3), PadL(IntToStr(Bd^[I].B + 1), 3),
          PadL(IntToStr(Bd^[I].Order), 3), PadL(IntToStr(K), 3), '  0  0  0');
 End;
 N := 0;
 For I := 0 To NAt - 1 Do If At^[I].Chg <> 0 Then Inc(N);
 I := 0;
 While I < NAt Do Begin
  Cnt := 0; ChgL := '';
  K := I;
  While (K < NAt) And (Cnt < 8) Do Begin
   If At^[K].Chg <> 0 Then Begin
    ChgL := ChgL + PadL(IntToStr(K + 1), 4) + PadL(IntToStr(At^[K].Chg), 4);
    Inc(Cnt);
   End;
   Inc(K);
  End;
  If Cnt > 0 Then WriteLn(F, 'M  CHG', PadL(IntToStr(Cnt), 3), ChgL);
  I := K;
 End;
 For I := 0 To NAt - 1 Do
  If At^[I].Iso > 0 Then WriteLn(F, 'M  ISO  1', PadL(IntToStr(I + 1), 4), PadL(IntToStr(At^[I].Iso), 4));
 WriteLn(F, 'M  END');
 Close(F);
 RestoreSnap(Snap);
 FreeSnap(Snap);
 Modified := Mod0;
 SaveMOL := True;
End;

Function LoadMOL(Const FN: String): Boolean;
Var
 F : Text; Line : String;
 NA, NB, I, A, B, Ord2, St, Base, K, Cnt, P, Z, Code, J : Integer;
 X, Y : Real;
 Sym : String;
 First : Integer;
 AllZero : Boolean;
Begin
 LoadMOL := False;
 {$I-}
 Assign(F, FN); Reset(F);
 {$I+}
 If IOResult <> 0 Then Exit;
 Base := NAt;
 ReadLn(F, Line); ReadLn(F, Line); ReadLn(F, Line);
 If Eof(F) Then Begin Close(F); Exit; End;
 ReadLn(F, Line);
 NA := StrToIntDef(Copy(Line, 1, 3), 0);
 NB := StrToIntDef(Copy(Line, 4, 3), 0);
 If (NA <= 0) Or (Base + NA > MAX_ATOMS) Or (Base + NB > MAX_BONDS) Then Begin Close(F); Exit; End;
 First := NAt;
 AllZero := True;
 For I := 1 To NA Do Begin
  ReadLn(F, Line);
  X := StrToRealDef(Copy(Line, 1, 10), 0);
  Y := StrToRealDef(Copy(Line, 11, 10), 0);
  Sym := TrimStr(Copy(Line, 32, 3));
  Z := ElemBySymbol(Sym);
  K := NewAtom(X * BOND_LEN / 1.5, -Y * BOND_LEN / 1.5, Z);
  If K < 0 Then Begin Close(F); Exit; End;
  If Z = 0 Then At^[K].Lbl := Sym;
  Code := StrToIntDef(Copy(Line, 37, 3), 0);
  If (Code >= 1) And (Code <= 7) And (Code <> 4) Then At^[K].Chg := 4 - Code;
  If (X <> 0) Or (Y <> 0) Then AllZero := False;
  At^[K].Mark := 1;
 End;
 For I := 1 To NB Do Begin
  ReadLn(F, Line);
  A := StrToIntDef(Copy(Line, 1, 3), 0) - 1 + Base;
  B := StrToIntDef(Copy(Line, 4, 3), 0) - 1 + Base;
  Ord2 := StrToIntDef(Copy(Line, 7, 3), 1);
  St := StrToIntDef(Copy(Line, 10, 3), 0);
  If Ord2 > 4 Then Ord2 := 1;
  If (A >= Base) And (B >= Base) And (A < NAt) And (B < NAt) Then Begin
   K := NewBond(A, B, Ord2, ST_NORMAL);
   If K >= 0 Then Begin
    If St = 1 Then Bd^[K].Sty := ST_WEDGE
    Else If St = 6 Then Bd^[K].Sty := ST_HASH
    Else If St = 4 Then Bd^[K].Sty := ST_WAVY;
    If Ord2 = 4 Then Begin
     At^[A].Mark := At^[A].Mark Or 4; At^[B].Mark := At^[B].Mark Or 4;
    End;
   End;
  End;
 End;
 { lignes M  ... }
 While Not Eof(F) Do Begin
  ReadLn(F, Line);
  If Copy(Line, 1, 6) = 'M  END' Then Break;
  If Copy(Line, 1, 6) = 'M  CHG' Then Begin
   Cnt := StrToIntDef(Copy(Line, 7, 3), 0);
   For K := 0 To Cnt - 1 Do Begin
    P := 10 + K * 8;
    J := StrToIntDef(Copy(Line, P, 4), 0) - 1 + Base;
    Code := StrToIntDef(Copy(Line, P + 4, 4), 0);
    If (J >= Base) And (J < NAt) Then At^[J].Chg := Code;
   End;
  End
  Else If Copy(Line, 1, 6) = 'M  ISO' Then Begin
   Cnt := StrToIntDef(Copy(Line, 7, 3), 0);
   For K := 0 To Cnt - 1 Do Begin
    P := 10 + K * 8;
    J := StrToIntDef(Copy(Line, P, 4), 0) - 1 + Base;
    Code := StrToIntDef(Copy(Line, P + 4, 4), 0);
    If (J >= Base) And (J < NAt) Then At^[J].Iso := Code;
   End;
  End;
 End;
 Close(F);
 For I := First To NAt - 1 Do SmH[I] := -1;
 Kekulize(First);
 UpdateInfo;
 If AllZero Then LayoutMarked(0, 0)
 Else Begin
  For I := First To NAt - 1 Do At^[I].Mark := 0;
 End;
 For I := First To NAt - 1 Do At^[I].Mark := 0;
 TopoChanged;
 Touch;
 LoadMOL := True;
End;

Function SaveSMILES(Const FN: String): Boolean;
Var F: Text;
Begin
 {$I-}
 Assign(F, FN); Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Begin SaveSMILES := False; Exit; End;
 WriteLn(F, SmBufStr);
 Close(F);
 SaveSMILES := True;
End;

Function LoadSMILESFile(Const FN: String): Boolean;
Var F: Text; Line: String; First, L, Cnt, First0: Integer;
Begin
 LoadSMILESFile := False;
 First0 := NAt;
 {$I-}
 Assign(F, FN); Reset(F);
 {$I+}
 If IOResult <> 0 Then Exit;
 Cnt := 0;
 While Not Eof(F) Do Begin
  ReadLn(F, Line);
  Line := TrimStr(Line);
  If Line = '' Then Continue;
  Line := NextTok(Line);
  If ParseSmiles(Line, First, L) Then Inc(Cnt)
  Else TruncateAtoms(First);
 End;
 Close(F);
 If Cnt > 0 Then Begin
  LayoutMarked(BOND_LEN * 6, BOND_LEN * 5);
  ApplySmilesChirality(First0, NAt - 1);
  LoadSMILESFile := True;
 End;
 
End;

{ ---- SVG ---- }

Const
 SvgCol : Array[0..15] Of String[8] = (
  '#000000', '#0000AA', '#00AA00', '#00AAAA', '#AA0000', '#AA00AA', '#AA5500',
  '#AAAAAA', '#555555', '#5555FF', '#55FF55', '#55FFFF', '#FF5555', '#FF55FF',
  '#FFFF55', '#FFFFFF');

Function SvgNum(V: Real): String;
Begin
 SvgNum := RealToStr(V, 1);
End;

Function SaveSVG(Const FN: String): Boolean;
Var
 F : Text;
 I, J, A, B, K, N : Integer;
 X1, Y1, X2, Y2, L, UX, UY, NX, NY, D, ShA, ShB, SxA, SyA, ExA, EyA, HW, T, OffX, OffY : Real;
 Empty : Boolean;
 Col, T2, ChgS : String;
 Anchor, ALen, Side : Integer;
 Pts : String;
 Procedure Ln(AX, AY, BX, BY: Real; Const Extra: String);
 Begin
  WriteLn(F, '<line x1="', SvgNum(AX + OffX), '" y1="', SvgNum(AY + OffY), '" x2="',
          SvgNum(BX + OffX), '" y2="', SvgNum(BY + OffY), '" stroke="', Col,
          '" stroke-width="1.3"', Extra, '/>');
 End;
 Procedure Head(HX, HY, DX, DY: Real; Full, Left: Boolean);
 Var BX, BY, PX, PY: Real;
 Begin
  BX := HX - DX * 10; BY := HY - DY * 10;
  PX := -DY * 4; PY := DX * 4;
  If Full Then
   WriteLn(F, '<polygon points="', SvgNum(HX + OffX), ',', SvgNum(HY + OffY), ' ',
           SvgNum(BX + PX + OffX), ',', SvgNum(BY + PY + OffY), ' ',
           SvgNum(BX - PX + OffX), ',', SvgNum(BY - PY + OffY), '" fill="', Col, '"/>')
  Else If Left Then
   WriteLn(F, '<polygon points="', SvgNum(HX + OffX), ',', SvgNum(HY + OffY), ' ',
           SvgNum(BX + PX + OffX), ',', SvgNum(BY + PY + OffY), ' ',
           SvgNum(BX + OffX), ',', SvgNum(BY + OffY), '" fill="', Col, '"/>')
  Else
   WriteLn(F, '<polygon points="', SvgNum(HX + OffX), ',', SvgNum(HY + OffY), ' ',
           SvgNum(BX - PX + OffX), ',', SvgNum(BY - PY + OffY), ' ',
           SvgNum(BX + OffX), ',', SvgNum(BY + OffY), '" fill="', Col, '"/>');
 End;
Begin
 {$I-}
 Assign(F, FN); Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Begin SaveSVG := False; Exit; End;
 UpdateInfo;
 TxtScale := 1;
 DocBounds(False, X1, Y1, X2, Y2, Empty);
 If Empty Then Begin X1 := 0; Y1 := 0; X2 := 100; Y2 := 100; End;
 OffX := 30 - X1; OffY := 30 - Y1;
 WriteLn(F, '<?xml version="1.0" encoding="UTF-8"?>');
 WriteLn(F, '<svg xmlns="http://www.w3.org/2000/svg" width="', SvgNum(X2 - X1 + 60),
         '" height="', SvgNum(Y2 - Y1 + 60), '" viewBox="0 0 ', SvgNum(X2 - X1 + 60), ' ',
         SvgNum(Y2 - Y1 + 60), '">');
 WriteLn(F, '<rect width="100%" height="100%" fill="#FFFFFF"/>');
 For I := 0 To NSh - 1 Do Begin
  Col := SvgCol[Sh^[I].Col And 15];
  X1 := Sh^[I].X1; Y1 := Sh^[I].Y1; X2 := Sh^[I].X2; Y2 := Sh^[I].Y2;
  L := Dist(X1, Y1, X2, Y2);
  If L > 0.01 Then Begin UX := (X2 - X1) / L; UY := (Y2 - Y1) / L; End Else Begin UX := 1; UY := 0; End;
  NX := -UY; NY := UX;
  Case Sh^[I].Kind Of
   SH_LINE: Ln(X1, Y1, X2, Y2, '');
   SH_ARROW: Begin Ln(X1, Y1, X2 - UX * 6, Y2 - UY * 6, ''); Head(X2, Y2, UX, UY, True, True); End;
   SH_DASHARR: Begin Ln(X1, Y1, X2 - UX * 6, Y2 - UY * 6, ' stroke-dasharray="5,3"'); Head(X2, Y2, UX, UY, True, True); End;
   SH_RESON: Begin Ln(X1 + UX * 6, Y1 + UY * 6, X2 - UX * 6, Y2 - UY * 6, ''); Head(X2, Y2, UX, UY, True, True); Head(X1, Y1, -UX, -UY, True, True); End;
   SH_EQUIL: Begin
    Ln(X1 + NX * 3, Y1 + NY * 3, X2 + NX * 3, Y2 + NY * 3, '');
    Ln(X1 - NX * 3, Y1 - NY * 3, X2 - NX * 3, Y2 - NY * 3, '');
    Head(X2 + NX * 3, Y2 + NY * 3, UX, UY, False, False);
    Head(X1 - NX * 3, Y1 - NY * 3, -UX, -UY, False, False);
   End;
   SH_RETRO: Begin
    Ln(X1 + NX * 3, Y1 + NY * 3, X2 - UX * 8 + NX * 3, Y2 - UY * 8 + NY * 3, '');
    Ln(X1 - NX * 3, Y1 - NY * 3, X2 - UX * 8 - NX * 3, Y2 - UY * 8 - NY * 3, '');
    Ln(X2, Y2, X2 - UX * 12 + NX * 7, Y2 - UY * 12 + NY * 7, '');
    Ln(X2, Y2, X2 - UX * 12 - NX * 7, Y2 - UY * 12 - NY * 7, '');
   End;
   SH_CURVE1, SH_CURVE2: Begin
    WriteLn(F, '<path d="M ', SvgNum(X1 + OffX), ' ', SvgNum(Y1 + OffY), ' Q ',
            SvgNum(Sh^[I].CX + OffX), ' ', SvgNum(Sh^[I].CY + OffY), ' ',
            SvgNum(X2 + OffX), ' ', SvgNum(Y2 + OffY), '" fill="none" stroke="', Col, '" stroke-width="1.3"/>');
    L := Dist(Sh^[I].CX, Sh^[I].CY, X2, Y2);
    If L > 0.01 Then Head(X2, Y2, (X2 - Sh^[I].CX) / L, (Y2 - Sh^[I].CY) / L, Sh^[I].Kind = SH_CURVE2, True);
   End;
   SH_RECT: WriteLn(F, '<rect x="', SvgNum(MinR(X1, X2) + OffX), '" y="', SvgNum(MinR(Y1, Y2) + OffY),
                    '" width="', SvgNum(AbsR(X2 - X1)), '" height="', SvgNum(AbsR(Y2 - Y1)),
                    '" fill="none" stroke="', Col, '" stroke-width="1.3"/>');
   SH_ELLIPSE: WriteLn(F, '<ellipse cx="', SvgNum((X1 + X2) / 2 + OffX), '" cy="', SvgNum((Y1 + Y2) / 2 + OffY),
                       '" rx="', SvgNum(AbsR(X2 - X1) / 2), '" ry="', SvgNum(AbsR(Y2 - Y1) / 2),
                       '" fill="none" stroke="', Col, '" stroke-width="1.3"/>');
   SH_BRACKET: Begin
    WriteLn(F, '<path d="M ', SvgNum(X1 + 6 + OffX), ' ', SvgNum(Y1 + OffY), ' H ', SvgNum(X1 + OffX), ' V ',
            SvgNum(Y2 + OffY), ' H ', SvgNum(X1 + 6 + OffX), '" fill="none" stroke="', Col, '"/>');
    WriteLn(F, '<path d="M ', SvgNum(X2 - 6 + OffX), ' ', SvgNum(Y1 + OffY), ' H ', SvgNum(X2 + OffX), ' V ',
            SvgNum(Y2 + OffY), ' H ', SvgNum(X2 - 6 + OffX), '" fill="none" stroke="', Col, '"/>');
   End;
   SH_ORBS: WriteLn(F, '<circle cx="', SvgNum(X1 + OffX), '" cy="', SvgNum(Y1 + OffY), '" r="', SvgNum(L),
                    '" fill="none" stroke="', Col, '"/>');
   SH_ORBP: Begin
    WriteLn(F, '<ellipse cx="', SvgNum(X1 + UX * L / 2 + OffX), '" cy="', SvgNum(Y1 + UY * L / 2 + OffY),
            '" rx="', SvgNum(L / 2), '" ry="', SvgNum(L / 4.5), '" transform="rotate(',
            SvgNum(Atan2(UY, UX) * 180 / Pi), ' ', SvgNum(X1 + UX * L / 2 + OffX), ' ',
            SvgNum(Y1 + UY * L / 2 + OffY), ')" fill="none" stroke="', Col, '"/>');
    WriteLn(F, '<ellipse cx="', SvgNum(X1 - UX * L / 2 + OffX), '" cy="', SvgNum(Y1 - UY * L / 2 + OffY),
            '" rx="', SvgNum(L / 2), '" ry="', SvgNum(L / 4.5), '" transform="rotate(',
            SvgNum(Atan2(UY, UX) * 180 / Pi), ' ', SvgNum(X1 - UX * L / 2 + OffX), ' ',
            SvgNum(Y1 - UY * L / 2 + OffY), ')" fill="', Col, '" stroke="', Col, '"/>');
   End;
  End;
 End;
 For J := 0 To NBd - 1 Do Begin
  A := Bd^[J].A; B := Bd^[J].B;
  Col := SvgCol[Bd^[J].Col And 15];
  X1 := At^[A].X; Y1 := At^[A].Y; X2 := At^[B].X; Y2 := At^[B].Y;
  L := Dist(X1, Y1, X2, Y2);
  If L < 1 Then Continue;
  UX := (X2 - X1) / L; UY := (Y2 - Y1) / L; NX := -UY; NY := UX;
  ShA := 0; ShB := 0;
  If LabelVisible(A) Then ShA := 7;
  If LabelVisible(B) Then ShB := 7;
  SxA := X1 + UX * ShA; SyA := Y1 + UY * ShA; ExA := X2 - UX * ShB; EyA := Y2 - UY * ShB;
  D := 0.18 * BOND_LEN;
  Case Bd^[J].Sty Of
   ST_WEDGE: Begin
    HW := 0.10 * BOND_LEN;
    WriteLn(F, '<polygon points="', SvgNum(SxA + OffX), ',', SvgNum(SyA + OffY), ' ',
            SvgNum(ExA + NX * HW + OffX), ',', SvgNum(EyA + NY * HW + OffY), ' ',
            SvgNum(ExA - NX * HW + OffX), ',', SvgNum(EyA - NY * HW + OffY), '" fill="', Col, '"/>');
   End;
   ST_HASH: Begin
    HW := 0.10 * BOND_LEN;
    N := Round(L / 3.2); If N < 4 Then N := 4;
    For K := 0 To N Do Begin
     T := K / N;
     Ln(SxA + (ExA - SxA) * T + NX * (0.5 + HW * T), SyA + (EyA - SyA) * T + NY * (0.5 + HW * T),
        SxA + (ExA - SxA) * T - NX * (0.5 + HW * T), SyA + (EyA - SyA) * T - NY * (0.5 + HW * T), '');
    End;
   End;
   ST_BOLD: Ln(SxA, SyA, ExA, EyA, ' stroke-width="3.5"');
   ST_DASH: Ln(SxA, SyA, ExA, EyA, ' stroke-dasharray="4,3"');
   ST_WAVY: Begin
    Pts := '';
    N := Round(L / 2); If N < 4 Then N := 4;
    For K := 0 To N Do Begin
     T := K / N;
     Pts := Pts + SvgNum(SxA + (ExA - SxA) * T + NX * 2.5 * Sin(T * L * 2 * Pi / 8) + OffX) + ',' +
            SvgNum(SyA + (EyA - SyA) * T + NY * 2.5 * Sin(T * L * 2 * Pi / 8) + OffY) + ' ';
    End;
    WriteLn(F, '<polyline points="', Pts, '" fill="none" stroke="', Col, '" stroke-width="1.3"/>');
   End;
  Else
   Case Bd^[J].Order Of
    2: Begin
     Side := BondSide(J);
     If Side = 0 Then Begin
      Ln(SxA + NX * D / 2, SyA + NY * D / 2, ExA + NX * D / 2, EyA + NY * D / 2, '');
      Ln(SxA - NX * D / 2, SyA - NY * D / 2, ExA - NX * D / 2, EyA - NY * D / 2, '');
     End
     Else Begin
      Ln(SxA, SyA, ExA, EyA, '');
      Ln(SxA + NX * D * Side + UX * D, SyA + NY * D * Side + UY * D,
         ExA + NX * D * Side - UX * D, EyA + NY * D * Side - UY * D, '');
     End;
    End;
    3: Begin
     Ln(SxA, SyA, ExA, EyA, '');
     Ln(SxA + NX * D, SyA + NY * D, ExA + NX * D, EyA + NY * D, '');
     Ln(SxA - NX * D, SyA - NY * D, ExA - NX * D, EyA - NY * D, '');
    End;
   Else Ln(SxA, SyA, ExA, EyA, '');
   End;
  End;
 End;
 For I := 0 To NAt - 1 Do Begin
  If Not LabelVisible(I) Then Continue;
  BuildLabel(I, T2, Anchor, ALen, ChgS);
  Col := SvgCol[At^[I].Col And 15];
  Pts := '';
  For K := 1 To Length(T2) Do
   If IsDigitCh(T2[K]) And (CharKind(T2, K) = 1) Then
    Pts := Pts + '<tspan baseline-shift="sub" font-size="9">' + T2[K] + '</tspan>'
   Else Pts := Pts + T2[K];
  If ChgS <> '' Then Pts := Pts + '<tspan baseline-shift="super" font-size="9">' + ChgS + '</tspan>';
  WriteLn(F, '<text x="', SvgNum(At^[I].X + OffX), '" y="', SvgNum(At^[I].Y + OffY + 4),
          '" font-family="Arial" font-size="13" text-anchor="middle" fill="', Col, '">', Pts, '</text>');
 End;
 For I := 0 To NTx - 1 Do
  WriteLn(F, '<text x="', SvgNum(Tx^[I].X + OffX), '" y="', SvgNum(Tx^[I].Y + OffY + 9 * Tx^[I].Siz),
          '" font-family="Arial" font-size="', 12 * Tx^[I].Siz, '" fill="', SvgCol[Tx^[I].Col And 15], '">',
          Tx^[I].S, '</text>');
 WriteLn(F, '</svg>');
 Close(F);
 SaveSVG := True;
End;

{ ---- BMP 16 couleurs : copie du canevas affiche ---- }

Function SaveBMP(Const FN: String): Boolean;
Const
 Pal : Array[0..15] Of LongInt = (
  $000000, $AA0000, $00AA00, $AAAA00, $0000AA, $AA00AA, $0055AA, $AAAAAA,
  $555555, $FF5555, $55FF55, $FFFF55, $5555FF, $FF55FF, $55FFFF, $FFFFFF);
Var
 F : File;
 W, H, RowB, X, Y, I : Integer;
 Row : Array[0..511] Of Byte;
 Hdr : Array[0..53] Of Byte;
 PalB : Array[0..63] Of Byte;
 P1, P2, FileSz : LongInt;
 Procedure PutL(Ofs: Integer; V: LongInt);
 Begin
  Hdr[Ofs] := V And 255; Hdr[Ofs + 1] := (V Shr 8) And 255;
  Hdr[Ofs + 2] := (V Shr 16) And 255; Hdr[Ofs + 3] := (V Shr 24) And 255;
 End;
Begin
 SaveBMP := False;
 W := CvX2 - CvX1 + 1; H := CvY2 - CvY1 + 1;
 RowB := ((W + 1) Div 2 + 3) And $FFFC;
 If RowB > 512 Then Exit;
 {$I-}
 Assign(F, FN); Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;
 FillChar(Hdr, SizeOf(Hdr), 0);
 Hdr[0] := Ord('B'); Hdr[1] := Ord('M');
 FileSz := 54 + 64 + LongInt(RowB) * H;
 PutL(2, FileSz); PutL(10, 54 + 64);
 PutL(14, 40); PutL(18, W); PutL(22, H);
 Hdr[26] := 1; Hdr[28] := 4;
 PutL(34, LongInt(RowB) * H); PutL(46, 16); PutL(50, 16);
 BlockWrite(F, Hdr, 54);
 For I := 0 To 15 Do Begin
  PalB[I * 4] := Pal[I] And 255;
  PalB[I * 4 + 1] := (Pal[I] Shr 8) And 255;
  PalB[I * 4 + 2] := (Pal[I] Shr 16) And 255;
  PalB[I * 4 + 3] := 0;
 End;
 BlockWrite(F, PalB, 64);
 For Y := H - 1 Downto 0 Do Begin
  FillChar(Row, SizeOf(Row), 0);
  X := 0;
  While X < W Do Begin
   P1 := GetPixel(CvX1 + X, CvY1 + Y) And 15;
   If X + 1 < W Then P2 := GetPixel(CvX1 + X + 1, CvY1 + Y) And 15 Else P2 := 0;
   Row[X Div 2] := (P1 Shl 4) Or P2;
   Inc(X, 2);
  End;
  BlockWrite(F, Row, RowB);
 End;
 Close(F);
 SaveBMP := True;
End;

{ --------------------------------------------------------------------- }
{ Dictionnaire de composes (nom <-> structure) et modeles               }
{ --------------------------------------------------------------------- }

Const
 NNAMES = 192;

Type
 TNameRec = Record
  Nm : String[84];          { noms separes par | }
  Sm : String[56];
 End;

Const
 NameDB : Array[1..NNAMES] Of TNameRec = (
  (Nm:'methane';  Sm:'C'),
  (Nm:'ethane';   Sm:'CC'),
  (Nm:'propane';  Sm:'CCC'),
  (Nm:'butane';   Sm:'CCCC'),
  (Nm:'isobutane|2-methylpropane'; Sm:'CC(C)C'),
  (Nm:'pentane';  Sm:'CCCCC'),
  (Nm:'isopentane|2-methylbutane'; Sm:'CCC(C)C'),
  (Nm:'neopentane|2,2-dimethylpropane'; Sm:'CC(C)(C)C'),
  (Nm:'hexane';   Sm:'CCCCCC'),
  (Nm:'heptane';  Sm:'CCCCCCC'),
  (Nm:'octane';   Sm:'CCCCCCCC'),
  (Nm:'nonane';   Sm:'CCCCCCCCC'),
  (Nm:'decane';   Sm:'CCCCCCCCCC'),
  (Nm:'isooctane|2,2,4-trimethylpentane'; Sm:'CC(C)CC(C)(C)C'),
  (Nm:'cyclopropane'; Sm:'C1CC1'),
  (Nm:'cyclobutane';  Sm:'C1CCC1'),
  (Nm:'cyclopentane'; Sm:'C1CCCC1'),
  (Nm:'cyclohexane';  Sm:'C1CCCCC1'),
  (Nm:'cycloheptane'; Sm:'C1CCCCCC1'),
  (Nm:'cyclooctane';  Sm:'C1CCCCCCC1'),
  (Nm:'ethylene|ethene|ethylene'; Sm:'C=C'),
  (Nm:'propene|propylene'; Sm:'C=CC'),
  (Nm:'1-butene|but-1-ene'; Sm:'C=CCC'),
  (Nm:'2-butene|but-2-ene'; Sm:'CC=CC'),
  (Nm:'isobutene|isobutylene|2-methylpropene'; Sm:'CC(C)=C'),
  (Nm:'1,3-butadiene|butadiene|buta-1,3-diene'; Sm:'C=CC=C'),
  (Nm:'isoprene|2-methyl-1,3-butadiene'; Sm:'CC(=C)C=C'),
  (Nm:'cyclohexene'; Sm:'C1=CCCCC1'),
  (Nm:'acetylene|ethyne|acetylene'; Sm:'C#C'),
  (Nm:'propyne'; Sm:'CC#C'),
  (Nm:'benzene|benzene'; Sm:'c1ccccc1'),
  (Nm:'toluene|methylbenzene'; Sm:'Cc1ccccc1'),
  (Nm:'o-xylene|1,2-dimethylbenzene'; Sm:'Cc1ccccc1C'),
  (Nm:'m-xylene|1,3-dimethylbenzene'; Sm:'Cc1cccc(C)c1'),
  (Nm:'p-xylene|1,4-dimethylbenzene'; Sm:'Cc1ccc(C)cc1'),
  (Nm:'ethylbenzene'; Sm:'CCc1ccccc1'),
  (Nm:'styrene|vinylbenzene'; Sm:'C=Cc1ccccc1'),
  (Nm:'cumene|isopropylbenzene'; Sm:'CC(C)c1ccccc1'),
  (Nm:'naphthalene|naphtalene'; Sm:'c1ccc2ccccc2c1'),
  (Nm:'anthracene'; Sm:'c1ccc2cc3ccccc3cc2c1'),
  (Nm:'phenanthrene'; Sm:'c1ccc2c(c1)ccc1ccccc12'),
  (Nm:'biphenyl'; Sm:'c1ccc(cc1)-c1ccccc1'),
  (Nm:'phenol'; Sm:'Oc1ccccc1'),
  (Nm:'catechol|pyrocatechol|1,2-dihydroxybenzene'; Sm:'Oc1ccccc1O'),
  (Nm:'resorcinol'; Sm:'Oc1cccc(O)c1'),
  (Nm:'hydroquinone'; Sm:'Oc1ccc(O)cc1'),
  (Nm:'aniline'; Sm:'Nc1ccccc1'),
  (Nm:'nitrobenzene'; Sm:'[O-][N+](=O)c1ccccc1'),
  (Nm:'chlorobenzene'; Sm:'Clc1ccccc1'),
  (Nm:'bromobenzene'; Sm:'Brc1ccccc1'),
  (Nm:'fluorobenzene'; Sm:'Fc1ccccc1'),
  (Nm:'iodobenzene'; Sm:'Ic1ccccc1'),
  (Nm:'benzaldehyde'; Sm:'O=Cc1ccccc1'),
  (Nm:'benzoic acid|acide benzoique'; Sm:'OC(=O)c1ccccc1'),
  (Nm:'acetophenone'; Sm:'CC(=O)c1ccccc1'),
  (Nm:'benzyl alcohol|alcool benzylique'; Sm:'OCc1ccccc1'),
  (Nm:'anisole|methoxybenzene'; Sm:'COc1ccccc1'),
  (Nm:'benzonitrile'; Sm:'N#Cc1ccccc1'),
  (Nm:'benzamide'; Sm:'NC(=O)c1ccccc1'),
  (Nm:'benzophenone'; Sm:'O=C(c1ccccc1)c1ccccc1'),
  (Nm:'salicylic acid|acide salicylique'; Sm:'OC(=O)c1ccccc1O'),
  (Nm:'aspirin|aspirine|acetylsalicylic acid|acide acetylsalicylique'; Sm:'CC(=O)Oc1ccccc1C(O)=O'),
  (Nm:'paracetamol|acetaminophen|acetaminophene'; Sm:'CC(=O)Nc1ccc(O)cc1'),
  (Nm:'ibuprofen|ibuprofene'; Sm:'CC(C)Cc1ccc(cc1)C(C)C(O)=O'),
  (Nm:'caffeine|cafeine'; Sm:'Cn1cnc2c1c(=O)n(C)c(=O)n2C'),
  (Nm:'nicotine'; Sm:'CN1CCCC1c1cccnc1'),
  (Nm:'vanillin|vanilline'; Sm:'COc1cc(C=O)ccc1O'),
  (Nm:'menthol'; Sm:'CC(C)C1CCC(C)CC1O'),
  (Nm:'camphor|camphre'; Sm:'CC1(C)C2CCC1(C)C(=O)C2'),
  (Nm:'adrenaline|epinephrine'; Sm:'CNCC(O)c1ccc(O)c(O)c1'),
  (Nm:'dopamine'; Sm:'NCCc1ccc(O)c(O)c1'),
  (Nm:'serotonin'; Sm:'NCCc1c[nH]c2ccc(O)cc12'),
  (Nm:'capsaicin|capsaicine'; Sm:'COc1cc(CNC(=O)CCCCC=CC(C)C)ccc1O'),
  (Nm:'pyridine'; Sm:'c1ccncc1'),
  (Nm:'pyrimidine'; Sm:'c1cncnc1'),
  (Nm:'pyrazine'; Sm:'c1cnccn1'),
  (Nm:'pyrrole'; Sm:'c1cc[nH]c1'),
  (Nm:'furan|furane'; Sm:'c1ccoc1'),
  (Nm:'thiophene'; Sm:'c1ccsc1'),
  (Nm:'imidazole'; Sm:'c1c[nH]cn1'),
  (Nm:'pyrazole'; Sm:'c1cn[nH]c1'),
  (Nm:'oxazole'; Sm:'c1cocn1'),
  (Nm:'thiazole'; Sm:'c1cscn1'),
  (Nm:'indole'; Sm:'c1ccc2[nH]ccc2c1'),
  (Nm:'quinoline|quinoleine'; Sm:'c1ccc2ncccc2c1'),
  (Nm:'isoquinoline'; Sm:'c1ccc2cnccc2c1'),
  (Nm:'purine'; Sm:'c1ncc2[nH]cnc2n1'),
  (Nm:'adenine'; Sm:'Nc1ncnc2[nH]cnc12'),
  (Nm:'guanine'; Sm:'Nc1nc2[nH]cnc2c(=O)[nH]1'),
  (Nm:'cytosine'; Sm:'Nc1cc[nH]c(=O)n1'),
  (Nm:'thymine'; Sm:'Cc1c[nH]c(=O)[nH]c1=O'),
  (Nm:'uracil|uracile'; Sm:'O=c1cc[nH]c(=O)[nH]1'),
  (Nm:'tetrahydrofuran|thf'; Sm:'C1CCOC1'),
  (Nm:'1,4-dioxane|dioxane'; Sm:'C1COCCO1'),
  (Nm:'morpholine'; Sm:'C1COCCN1'),
  (Nm:'piperidine'; Sm:'C1CCNCC1'),
  (Nm:'pyrrolidine'; Sm:'C1CCNC1'),
  (Nm:'piperazine'; Sm:'C1CNCCN1'),
  (Nm:'methanol|alcool methylique'; Sm:'CO'),
  (Nm:'ethanol|alcool ethylique|ethyl alcohol'; Sm:'CCO'),
  (Nm:'propan-1-ol|1-propanol|propanol'; Sm:'CCCO'),
  (Nm:'isopropanol|propan-2-ol|2-propanol'; Sm:'CC(C)O'),
  (Nm:'butan-1-ol|1-butanol|butanol'; Sm:'CCCCO'),
  (Nm:'butan-2-ol|2-butanol'; Sm:'CCC(C)O'),
  (Nm:'tert-butanol|2-methylpropan-2-ol|t-butanol'; Sm:'CC(C)(C)O'),
  (Nm:'ethylene glycol|glycol|ethane-1,2-diol|ethylene glycol'; Sm:'OCCO'),
  (Nm:'glycerol|glycerin|glycerine|glycerol|propane-1,2,3-triol'; Sm:'OCC(O)CO'),
  (Nm:'cyclohexanol'; Sm:'OC1CCCCC1'),
  (Nm:'dimethyl ether|ether dimethylique'; Sm:'COC'),
  (Nm:'diethyl ether|ether|ether diethylique|ethoxyethane'; Sm:'CCOCC'),
  (Nm:'mtbe|methyl tert-butyl ether'; Sm:'COC(C)(C)C'),
  (Nm:'formaldehyde|methanal|formaldehyde'; Sm:'C=O'),
  (Nm:'acetaldehyde|ethanal'; Sm:'CC=O'),
  (Nm:'propanal|propionaldehyde'; Sm:'CCC=O'),
  (Nm:'acetone|propanone'; Sm:'CC(C)=O'),
  (Nm:'butanone|methyl ethyl ketone|mek|2-butanone'; Sm:'CCC(C)=O'),
  (Nm:'cyclohexanone'; Sm:'O=C1CCCCC1'),
  (Nm:'acrolein|propenal'; Sm:'C=CC=O'),
  (Nm:'formic acid|acide formique|methanoic acid|acide methanoique'; Sm:'OC=O'),
  (Nm:'acetic acid|acide acetique|ethanoic acid|acide ethanoique'; Sm:'CC(O)=O'),
  (Nm:'propanoic acid|acide propanoique|propionic acid'; Sm:'CCC(O)=O'),
  (Nm:'butanoic acid|acide butanoique|butyric acid|acide butyrique'; Sm:'CCCC(O)=O'),
  (Nm:'oxalic acid|acide oxalique'; Sm:'OC(=O)C(O)=O'),
  (Nm:'malonic acid|acide malonique'; Sm:'OC(=O)CC(O)=O'),
  (Nm:'succinic acid|acide succinique'; Sm:'OC(=O)CCC(O)=O'),
  (Nm:'lactic acid|acide lactique'; Sm:'CC(O)C(O)=O'),
  (Nm:'citric acid|acide citrique'; Sm:'OC(=O)CC(O)(CC(O)=O)C(O)=O'),
  (Nm:'tartaric acid|acide tartrique'; Sm:'OC(C(O)C(O)=O)C(O)=O'),
  (Nm:'maleic acid|acide maleique'; Sm:'OC(=O)C=CC(O)=O'),
  (Nm:'pyruvic acid|acide pyruvique'; Sm:'CC(=O)C(O)=O'),
  (Nm:'acrylic acid|acide acrylique'; Sm:'C=CC(O)=O'),
  (Nm:'ascorbic acid|acide ascorbique|vitamine c|vitamin c'; Sm:'OCC(O)C1OC(=O)C(O)=C1O'),
  (Nm:'methyl acetate|acetate de methyle'; Sm:'CC(=O)OC'),
  (Nm:'ethyl acetate|acetate d''ethyle|acetate de ethyle'; Sm:'CCOC(C)=O'),
  (Nm:'urea|uree'; Sm:'NC(N)=O'),
  (Nm:'acetamide'; Sm:'CC(N)=O'),
  (Nm:'formamide'; Sm:'NC=O'),
  (Nm:'dmf|dimethylformamide'; Sm:'CN(C)C=O'),
  (Nm:'methylamine'; Sm:'CN'),
  (Nm:'ethylamine'; Sm:'CCN'),
  (Nm:'dimethylamine'; Sm:'CNC'),
  (Nm:'trimethylamine'; Sm:'CN(C)C'),
  (Nm:'triethylamine'; Sm:'CCN(CC)CC'),
  (Nm:'ethylenediamine'; Sm:'NCCN'),
  (Nm:'acetonitrile'; Sm:'CC#N'),
  (Nm:'dmso|dimethyl sulfoxide|dimethylsulfoxyde'; Sm:'CS(C)=O'),
  (Nm:'chloroform|trichloromethane|trichloromethane'; Sm:'ClC(Cl)Cl'),
  (Nm:'dichloromethane|methylene chloride|chlorure de methylene'; Sm:'ClCCl'),
  (Nm:'carbon tetrachloride|tetrachloromethane|tetrachlorure de carbone'; Sm:'ClC(Cl)(Cl)Cl'),
  (Nm:'chloromethane|methyl chloride'; Sm:'CCl'),
  (Nm:'bromomethane|methyl bromide'; Sm:'CBr'),
  (Nm:'iodomethane|methyl iodide'; Sm:'CI'),
  (Nm:'chloroethane|ethyl chloride'; Sm:'CCCl'),
  (Nm:'vinyl chloride|chlorure de vinyle|chloroethene'; Sm:'C=CCl'),
  (Nm:'freon-12|dichlorodifluoromethane'; Sm:'FC(F)(Cl)Cl'),
  (Nm:'methanethiol|methyl mercaptan'; Sm:'CS'),
  (Nm:'water|eau'; Sm:'O'),
  (Nm:'ammonia|ammoniac|ammoniaque'; Sm:'N'),
  (Nm:'hydrogen peroxide|peroxyde d''hydrogene|eau oxygenee'; Sm:'OO'),
  (Nm:'hydrochloric acid|acide chlorhydrique|hydrogen chloride'; Sm:'Cl'),
  (Nm:'sulfuric acid|acide sulfurique'; Sm:'OS(O)(=O)=O'),
  (Nm:'nitric acid|acide nitrique'; Sm:'O[N+]([O-])=O'),
  (Nm:'carbon dioxide|dioxyde de carbone|co2'; Sm:'O=C=O'),
  (Nm:'carbon monoxide|monoxyde de carbone|co'; Sm:'[C-]#[O+]'),
  (Nm:'hydrogen sulfide|sulfure d''hydrogene'; Sm:'S'),
  (Nm:'sodium chloride|chlorure de sodium|sel'; Sm:'[Na+].[Cl-]'),
  (Nm:'glucose|d-glucose'; Sm:'OCC1OC(O)C(O)C(O)C1O'),
  (Nm:'fructose'; Sm:'OCC1(O)OCC(O)C(O)C1O'),
  (Nm:'ribose'; Sm:'OCC1OC(O)C(O)C1O'),
  (Nm:'sucrose|saccharose'; Sm:'OCC1OC(OC2(CO)OC(CO)C(O)C2O)C(O)C(O)C1O'),
  (Nm:'glycine'; Sm:'NCC(O)=O'),
  (Nm:'alanine'; Sm:'CC(N)C(O)=O'),
  (Nm:'valine'; Sm:'CC(C)C(N)C(O)=O'),
  (Nm:'leucine'; Sm:'CC(C)CC(N)C(O)=O'),
  (Nm:'isoleucine'; Sm:'CCC(C)C(N)C(O)=O'),
  (Nm:'serine'; Sm:'NC(CO)C(O)=O'),
  (Nm:'threonine'; Sm:'CC(O)C(N)C(O)=O'),
  (Nm:'cysteine'; Sm:'NC(CS)C(O)=O'),
  (Nm:'methionine'; Sm:'CSCCC(N)C(O)=O'),
  (Nm:'phenylalanine'; Sm:'NC(Cc1ccccc1)C(O)=O'),
  (Nm:'tyrosine'; Sm:'NC(Cc1ccc(O)cc1)C(O)=O'),
  (Nm:'tryptophan|tryptophane'; Sm:'NC(Cc1c[nH]c2ccccc12)C(O)=O'),
  (Nm:'aspartic acid|acide aspartique'; Sm:'NC(CC(O)=O)C(O)=O'),
  (Nm:'glutamic acid|acide glutamique'; Sm:'NC(CCC(O)=O)C(O)=O'),
  (Nm:'asparagine'; Sm:'NC(CC(N)=O)C(O)=O'),
  (Nm:'glutamine'; Sm:'NC(CCC(N)=O)C(O)=O'),
  (Nm:'lysine'; Sm:'NCCCCC(N)C(O)=O'),
  (Nm:'arginine'; Sm:'NC(CCCNC(N)=N)C(O)=O'),
  (Nm:'histidine'; Sm:'NC(Cc1c[nH]cn1)C(O)=O'),
  (Nm:'proline'; Sm:'OC(=O)C1CCCN1'),
  (Nm:'cholesterol (squelette)|steroide|steroid'; Sm:'C1CCC2C(C1)CCC1C2CCC2CCCC12'),
  (Nm:'adamantane'; Sm:'C1C2CC3CC1CC(C2)C3')
 );

 NTPL = 24;

Type
 TTplRec = Record
  Nm : String[30];
  Sm : String[56];
 End;

Const
 Tpl : Array[1..NTPL] Of TTplRec = (
  (Nm:'Benzene';             Sm:'c1ccccc1'),
  (Nm:'Naphtalene';          Sm:'c1ccc2ccccc2c1'),
  (Nm:'Anthracene';          Sm:'c1ccc2cc3ccccc3cc2c1'),
  (Nm:'Phenanthrene';        Sm:'c1ccc2c(c1)ccc1ccccc12'),
  (Nm:'Biphenyle';           Sm:'c1ccc(cc1)-c1ccccc1'),
  (Nm:'Pyridine';            Sm:'c1ccncc1'),
  (Nm:'Pyrimidine';          Sm:'c1cncnc1'),
  (Nm:'Pyrrole';             Sm:'c1cc[nH]c1'),
  (Nm:'Furane';              Sm:'c1ccoc1'),
  (Nm:'Thiophene';           Sm:'c1ccsc1'),
  (Nm:'Imidazole';           Sm:'c1c[nH]cn1'),
  (Nm:'Indole';              Sm:'c1ccc2[nH]ccc2c1'),
  (Nm:'Quinoleine';          Sm:'c1ccc2ncccc2c1'),
  (Nm:'Purine';              Sm:'c1ncc2[nH]cnc2n1'),
  (Nm:'Cyclohexane';         Sm:'C1CCCCC1'),
  (Nm:'Decaline';            Sm:'C1CCC2CCCCC2C1'),
  (Nm:'Squelette steroide';  Sm:'C1CCC2C(C1)CCC1C2CCC2CCCC12'),
  (Nm:'Adamantane';          Sm:'C1C2CC3CC1CC(C2)C3'),
  (Nm:'Ether couronne 18-C-6'; Sm:'C1COCCOCCOCCOCCOCCO1'),
  (Nm:'Morpholine';          Sm:'C1COCCN1'),
  (Nm:'Piperidine';          Sm:'C1CCNCC1'),
  (Nm:'Glucose (pyranose)';  Sm:'OCC1OC(O)C(O)C(O)C1O'),
  (Nm:'Caffeine';            Sm:'Cn1cnc2c1c(=O)n(C)c(=O)n2C'),
  (Nm:'Aspirine';            Sm:'CC(=O)Oc1ccccc1C(O)=O')
 );

{ Normalise un nom pour la comparaison }
Function NormName(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := Copy(S, 1, 255);
 For I := 1 To Length(R) Do
  If (R[I] >= 'A') And (R[I] <= 'Z') Then R[I] := Chr(Ord(R[I]) + 32);
 NormName := TrimStr(R);
End;

{ Cherche un nom dans une liste d'alias (separes par |) ; 2 = exact, 1 = contient }
Function AliasMatch(Const Aliases, Q: String): Integer;
Var I, St, K: Integer; A: String;
Begin
 AliasMatch := 0;
 St := 1;
 For I := 1 To Length(Aliases) + 1 Do Begin
  If (I > Length(Aliases)) Or (Aliases[I] = '|') Then Begin
   A := Copy(Aliases, St, I - St);
   If A = Q Then Begin AliasMatch := 2; Exit; End;
   K := Pos(Q, A);
   If (K > 0) And (Length(Q) >= 3) Then AliasMatch := 1;
   St := I + 1;
  End;
 End;
End;

Function FirstAlias(Const Aliases: String): String;
Var P: Integer;
Begin
 P := Pos('|', Aliases);
 If P = 0 Then FirstAlias := Aliases Else FirstAlias := Copy(Aliases, 1, P - 1);
End;

{ Cle canonique d'un graphe (invariants de Morgan) }
Var
 CanonL, CanonN : Array[0..MAX_ATOMS - 1] Of LongInt;

Procedure ComputeCanon;
Var
 Rnd, I, K, J, Nb, M : Integer;
 V : Array[0..7] Of LongInt;
 T, H : LongInt;
 InRing : Boolean;
Begin
 UpdateInfo;
 BuildAdj;
 EnsureRings;
 For I := 0 To NAt - 1 Do
  CanonL[I] := LongInt(At^[I].Z) * 100003 + (At^[I].Chg + 8) * 1009 + Inf^[I].H * 31 +
               Inf^[I].Deg + At^[I].Iso * 7919;
 For Rnd := 1 To 7 Do Begin
  For I := 0 To NAt - 1 Do Begin
   M := 0;
   For K := 0 To AdjN^[I] - 1 Do Begin
    Nb := Adj^[I, K]; J := AdjB^[I, K];
    InRing := RingOfBond(I, Nb) >= 0;
    If InRing Then V[M] := CanonL[Nb] * 8 Else V[M] := CanonL[Nb] * 8 + Bd^[J].Order;
    Inc(M);
   End;
   For K := 1 To M - 1 Do Begin
    T := V[K]; J := K - 1;
    While (J >= 0) And (V[J] > T) Do Begin V[J + 1] := V[J]; Dec(J); End;
    V[J + 1] := T;
   End;
   H := CanonL[I] * 16777619 + 12345;
   For K := 0 To M - 1 Do H := (H Xor V[K]) * 16777619 + K;
   CanonN[I] := H;
  End;
  For I := 0 To NAt - 1 Do CanonL[I] := CanonN[I];
 End;
End;

Function GraphKey: String;
Var
 I, J, K, SumOrd : Integer;
 H1, H2, T : LongInt;
 Srt : Array[0..MAX_ATOMS - 1] Of LongInt;
Begin
 ComputeCanon;
 For I := 0 To NAt - 1 Do Srt[I] := CanonL[I];
 For I := 1 To NAt - 1 Do Begin
  T := Srt[I]; J := I - 1;
  While (J >= 0) And (Srt[J] > T) Do Begin Srt[J + 1] := Srt[J]; Dec(J); End;
  Srt[J + 1] := T;
 End;
 H1 := 17; H2 := 91;
 For I := 0 To NAt - 1 Do Begin
  H1 := (H1 Xor Srt[I]) * 16777619 + 7;
  H2 := (H2 + Srt[I]) * 2654435 + I;
 End;
 SumOrd := 0;
 For K := 0 To NBd - 1 Do Inc(SumOrd, Bd^[K].Order);
 GraphKey := IntToStr(NAt) + '/' + IntToStr(NBd) + '/' + IntToStr(SumOrd) + '/' +
             IntToStr(H1) + '/' + IntToStr(H2);
End;

{ Structure -> nom : compare avec le dictionnaire }
Function NameFromStructure(Var Name: String): Boolean;
Var
 Snap : TSnap;
 Key, K2 : String;
 I, F, L : Integer;
 Mod0 : Boolean;
Begin
 NameFromStructure := False;
 Name := '';
 If NAt = 0 Then Exit;
 Mod0 := Modified;
 TakeSnap(Snap);
 ExpandAllLabels;
 Key := GraphKey;
 For I := 1 To NNAMES Do Begin
  NAt := 0; NBd := 0;
  TopoChanged;
  If ParseSmiles(NameDB[I].Sm, F, L) Then Begin
   K2 := GraphKey;
   If K2 = Key Then Begin
    Name := FirstAlias(NameDB[I].Nm);
    NameFromStructure := True;
    Break;
   End;
  End;
 End;
 RestoreSnap(Snap);
 FreeSnap(Snap);
 Modified := Mod0;
End;

{ Nom -> structure ; insere au centre de la vue }
Function StructureFromName(Const NameIn: String; Var SmilesOut: String): Boolean;
Var
 Q : String;
 I, Cnt, Sc : Integer;
 Idx : Array[1..40] Of Integer;
 Pick : Integer;
Begin
 StructureFromName := False;
 Q := NormName(NameIn);
 If Q = '' Then Exit;
 Cnt := 0;
 For I := 1 To NNAMES Do Begin
  Sc := AliasMatch(NameDB[I].Nm, Q);
  If Sc = 2 Then Begin
   SmilesOut := NameDB[I].Sm;
   StructureFromName := True;
   Exit;
  End;
  If (Sc = 1) And (Cnt < 40) Then Begin Inc(Cnt); Idx[Cnt] := I; End;
 End;
 If Cnt = 0 Then Exit;
 If Cnt = 1 Then Begin
  SmilesOut := NameDB[Idx[1]].Sm;
  StructureFromName := True;
  Exit;
 End;
 NTL := 0;
 For I := 1 To Cnt Do Begin
  TLines[NTL] := Copy(FirstAlias(NameDB[Idx[I]].Nm), 1, 40);
  Inc(NTL);
 End;
 Pick := ListDialog('Plusieurs composes correspondent', True);
 If Pick >= 0 Then Begin
  SmilesOut := NameDB[Idx[Pick + 1]].Sm;
  StructureFromName := True;
 End;
 
End;

{ --------------------------------------------------------------------- }
{ Prediction RMN (estimation par increments additifs)                   }
{ --------------------------------------------------------------------- }

Const
 MAX_PK = 64;
 { types de groupes }
 GK_NONE = 0;  GK_OH = 1;   GK_OR = 2;   GK_OCOR = 3; GK_NH2 = 4;  GK_NHR = 5;
 GK_NR2 = 6;   GK_NHCO = 7; GK_NO2 = 8;  GK_F = 9;    GK_CL = 10;  GK_BR = 11;
 GK_I = 12;    GK_SH = 13;  GK_SR = 14;  GK_PH = 15;  GK_CC = 16;  GK_CCC = 17;
 GK_KET = 18;  GK_ALD = 19; GK_ACID = 20; GK_ESTER = 21; GK_AMIDE = 22; GK_CN = 23;
 GK_CF3 = 24;  GK_ALK = 25;

 { increments 13C alkyle : alpha, beta, gamma }
 CAl : Array[0..25] Of Real = (0, 49, 58, 54, 29, 37, 42, 28, 61, 68, 31, 20, 7, 11, 20, 23, 20, 4.5, 30, 29, 21, 20, 22, 4, 0, 0);
 CBe : Array[0..25] Of Real = (0, 10, 8, 6, 11, 8, 6, 7, 3, 9, 11, 11, 11, 12, 7, 9, 6, 5, 1, -1, 3, 3, 3, 3, 0, 0);
 CGa : Array[0..25] Of Real = (0, -6, -4, -3, -5, -4, -3, -4, -3, -4, -4, -3, -1, -4, -3, -2, 0, -3, -3, -3, -2, -2, -3, -3, 0, 0);
 { increments 1H alkyle : alpha }
 HAl : Array[0..25] Of Real = (0, 2.5, 2.4, 2.9, 1.6, 1.6, 1.5, 2.3, 3.4, 3.3, 2.1, 1.9, 1.4, 1.1, 1.2, 1.4, 0.8, 0.9, 1.2, 1.1, 1.1, 1.0, 1.0, 1.1, 0.3, 0);
 { aromatiques 13C : ipso, ortho, meta, para }
 CAr : Array[0..25, 0..3] Of Real = (
  (0,0,0,0), (26.9,-12.7,1.4,-7.3), (31.4,-14.4,1.0,-7.7), (22.4,-7.1,-0.4,-3.2),
  (18.2,-13.4,0.8,-10.0), (22,-15,0.8,-11), (24,-16,0.8,-12), (11.1,-9.9,0.2,-5.6),
  (19.9,-4.9,0.9,6.1), (34.8,-12.9,1.4,-4.5), (6.2,0.4,1.3,-1.9), (-5.5,3.4,1.7,-1.6),
  (-32.2,9.9,2.6,-7.3), (10,-1.5,0.5,-4), (10,-1.5,0.5,-4), (13.0,-1.1,0.5,-1.0),
  (7.6,-1.8,-1.8,-3.5), (-6.2,3.6,-0.4,-0.3), (9.1,0.1,0.0,4.2), (8.2,1.2,0.5,5.8),
  (2.1,1.6,-0.1,5.2), (2.0,1.2,-0.1,4.3), (5.0,-1.2,0.0,3.4), (-16.0,3.5,0.7,4.3),
  (2.6,-3.1,0.4,3.4), (9.3,0.7,-0.1,-3.0));
 { aromatiques 1H : ortho, meta, para }
 HAr : Array[0..25, 0..2] Of Real = (
  (0,0,0), (-0.56,-0.12,-0.45), (-0.48,-0.09,-0.44), (-0.25,0.03,-0.13),
  (-0.75,-0.25,-0.65), (-0.6,-0.2,-0.6), (-0.6,-0.2,-0.6), (0.12,-0.07,-0.28),
  (0.95,0.26,0.38), (-0.26,0,-0.20), (0.03,-0.02,-0.09), (0.18,-0.08,-0.04),
  (0.39,-0.21,0), (-0.08,-0.16,-0.22), (-0.08,-0.16,-0.22), (0.37,0.20,0.10),
  (0.06,-0.03,-0.10), (0.15,-0.02,-0.01), (0.62,0.14,0.21), (0.56,0.22,0.29),
  (0.85,0.18,0.25), (0.71,0.11,0.21), (0.61,0.10,0.17), (0.36,0.18,0.28),
  (0.32,0.14,0.20), (-0.18,-0.10,-0.20));

Var
 NmrN     : Integer;
 NmrPpm   : Array[0..MAX_PK - 1] Of Real;
 NmrCnt   : Array[0..MAX_PK - 1] Of Integer;
 NmrMult  : Array[0..MAX_PK - 1] Of String[6];
 NmrDesc  : Array[0..MAX_PK - 1] Of String[14];
 NmrKey   : Array[0..MAX_PK - 1] Of LongInt;
 ArA      : Array[0..MAX_ATOMS - 1] Of Boolean;
 ArRing   : Array[0..MAX_ATOMS - 1] Of Integer;

Function NeighborCount(A: Integer): Integer;
Begin
 NeighborCount := AdjN^[A];
End;

Function CountBondsOf(A, Ord2: Integer): Integer;
Var K, N: Integer;
Begin
 N := 0;
 For K := 0 To AdjN^[A] - 1 Do If Bd^[AdjB^[A, K]].Order = Ord2 Then Inc(N);
 CountBondsOf := N;
End;

{ Perception d'aromaticite simple (anneaux de 5 ou 6 atomes) ; RingAro[R] = cycle aromatique }
Var
 RingAro : Array[0..MAX_RINGS - 1] Of Boolean;

Procedure MarkAromRings;
Var
 R, K, N, I, J, Nb, Q, W, Sp2, Hetero : Integer;
 Found, AllSingle : Boolean;
Begin
 EnsureRings;
 BuildAdj;
 ComputeRingSystems;
 For R := 0 To NRings - 1 Do Begin
  RingAro[R] := False;
  N := RingN[R];
  If (N <> 5) And (N <> 6) Then Continue;
  Sp2 := 0; Hetero := 0;
  For K := 0 To N - 1 Do Begin
   I := RingA[R, K];
   Found := False;
   AllSingle := True;
   For J := 0 To AdjN^[I] - 1 Do Begin
    If Bd^[AdjB^[I, J]].Order <> 1 Then AllSingle := False;
    If Bd^[AdjB^[I, J]].Order = 2 Then Begin
     Nb := Adj^[I, J];
     For Q := 0 To NRings - 1 Do
      If RingSys[Q] = RingSys[R] Then
       For W := 0 To RingN[Q] - 1 Do
        If RingA[Q, W] = Nb Then Found := True;
    End;
   End;
   If Found Then Inc(Sp2);
   If (At^[I].Z In [7, 8, 16]) And AllSingle Then Inc(Hetero);
  End;
  RingAro[R] := ((N = 6) And (Sp2 = 6)) Or ((N = 5) And (Sp2 = 4) And (Hetero >= 1));
 End;
End;

Procedure FindAromatic;
Var R, K, I: Integer;
Begin
 MarkAromRings;
 For I := 0 To NAt - 1 Do Begin ArA[I] := False; ArRing[I] := -1; End;
 For R := 0 To NRings - 1 Do
  If RingAro[R] Then
   For K := 0 To RingN[R] - 1 Do Begin
    I := RingA[R, K];
    ArA[I] := True;
    If (ArRing[I] < 0) Or (RingN[R] < RingN[ArRing[I]]) Then ArRing[I] := R;
   End;
End;

{ Type du groupe forme par l'atome X rattache a l'atome From }
Function GroupKind(X, From: Integer): Integer;
Var
 K, Nb, J, NO, NH, NC, NHal, Dbl : Integer;
 HasOdbl : Boolean;
Begin
 GroupKind := GK_NONE;
 If At^[X].Lbl <> '' Then Begin GroupKind := GK_ALK; Exit; End;
 Case At^[X].Z Of
  9 : GroupKind := GK_F;
  17: GroupKind := GK_CL;
  35: GroupKind := GK_BR;
  53: GroupKind := GK_I;
  8 : Begin
   GroupKind := GK_OR;
   If Inf^[X].H > 0 Then GroupKind := GK_OH
   Else
    For K := 0 To AdjN^[X] - 1 Do Begin
     Nb := Adj^[X, K];
     If Nb <> From Then
      For J := 0 To AdjN^[Nb] - 1 Do
       If (Bd^[AdjB^[Nb, J]].Order = 2) And (At^[Adj^[Nb, J]].Z = 8) Then GroupKind := GK_OCOR;
    End;
  End;
  16: Begin
   If Inf^[X].H > 0 Then GroupKind := GK_SH Else GroupKind := GK_SR;
  End;
  7 : Begin
   NO := 0;
   For K := 0 To AdjN^[X] - 1 Do
    If At^[Adj^[X, K]].Z = 8 Then Inc(NO);
   If NO >= 2 Then GroupKind := GK_NO2
   Else Begin
    GroupKind := GK_NR2;
    If Inf^[X].H = 2 Then GroupKind := GK_NH2
    Else If Inf^[X].H = 1 Then GroupKind := GK_NHR;
    For K := 0 To AdjN^[X] - 1 Do Begin
     Nb := Adj^[X, K];
     If Nb <> From Then
      For J := 0 To AdjN^[Nb] - 1 Do
       If (Bd^[AdjB^[Nb, J]].Order = 2) And (At^[Adj^[Nb, J]].Z = 8) Then GroupKind := GK_NHCO;
    End;
   End;
  End;
  6 : Begin
   { carbone }
   If ArA[X] Then Begin GroupKind := GK_PH; Exit; End;
   NO := 0; NC := 0; NHal := 0; NH := 0; Dbl := 0; HasOdbl := False;
   For K := 0 To AdjN^[X] - 1 Do Begin
    Nb := Adj^[X, K];
    If Nb <> From Then Begin
     If Bd^[AdjB^[X, K]].Order = 3 Then Begin
      If At^[Nb].Z = 7 Then GroupKind := GK_CN Else GroupKind := GK_CCC;
      Exit;
     End;
     If Bd^[AdjB^[X, K]].Order = 2 Then Begin
      If At^[Nb].Z = 8 Then HasOdbl := True Else Dbl := 1;
     End;
    End;
    If At^[Nb].Z = 8 Then Inc(NO);
    If At^[Nb].Z = 7 Then Inc(NH);
    If At^[Nb].Z = 6 Then Inc(NC);
    If At^[Nb].Z In [9, 17, 35] Then Inc(NHal);
   End;
   If HasOdbl Then Begin
    If NO >= 2 Then Begin
     { acide ou ester }
     GroupKind := GK_ACID;
     For K := 0 To AdjN^[X] - 1 Do
      If (At^[Adj^[X, K]].Z = 8) And (Bd^[AdjB^[X, K]].Order = 1) And (Inf^[Adj^[X, K]].H = 0) Then GroupKind := GK_ESTER;
    End
    Else If NH > 0 Then GroupKind := GK_AMIDE
    Else If (NC = 0) Or (Inf^[X].H > 0) Then GroupKind := GK_ALD
    Else GroupKind := GK_KET;
   End
   Else If Dbl = 1 Then GroupKind := GK_CC
   Else If NHal >= 2 Then GroupKind := GK_CF3
   Else GroupKind := GK_ALK;
  End;
 Else
  GroupKind := GK_NONE;
 End;
End;

Function IsAlkylC(X: Integer): Boolean;
Var K: Integer;
Begin
 IsAlkylC := False;
 If (At^[X].Z <> 6) Or ArA[X] Or (At^[X].Lbl <> '') Then Exit;
 For K := 0 To AdjN^[X] - 1 Do
  If Bd^[AdjB^[X, K]].Order > 1 Then Exit;
 IsAlkylC := True;
End;

Procedure AddPeak(Ppm: Real; Cnt: Integer; Const Mult, Desc: String; Key: LongInt);
Var I: Integer;
Begin
 For I := 0 To NmrN - 1 Do
  If (NmrKey[I] = Key) And (NmrDesc[I] = Desc) Then Begin
   NmrPpm[I] := (NmrPpm[I] * NmrCnt[I] + Ppm * Cnt) / (NmrCnt[I] + Cnt);
   Inc(NmrCnt[I], Cnt);
   Exit;
  End;
 If NmrN >= MAX_PK Then Exit;
 NmrPpm[NmrN] := Ppm; NmrCnt[NmrN] := Cnt; NmrMult[NmrN] := Mult;
 NmrDesc[NmrN] := Desc; NmrKey[NmrN] := Key;
 Inc(NmrN);
End;

{ Deplacement du carbone sp3 par increments }
Function ShiftC_sp3(C: Integer): Real;
Var
 K, J, M, Nb, Nb2, Nb3, NA, NBeta, NGam, G : Integer;
 D : Real;
Begin
 NA := 0; NBeta := 0; NGam := 0; D := -2.3;
 For K := 0 To AdjN^[C] - 1 Do Begin
  Nb := Adj^[C, K];
  If IsAlkylC(Nb) Then Begin
   Inc(NA);
   For J := 0 To AdjN^[Nb] - 1 Do Begin
    Nb2 := Adj^[Nb, J];
    If Nb2 = C Then Continue;
    If IsAlkylC(Nb2) Then Begin
     Inc(NBeta);
     For M := 0 To AdjN^[Nb2] - 1 Do Begin
      Nb3 := Adj^[Nb2, M];
      If (Nb3 <> Nb) And IsAlkylC(Nb3) Then Inc(NGam);
      G := GroupKind(Nb3, Nb2);
      If (Nb3 <> Nb) And (Not IsAlkylC(Nb3)) And (G <> GK_NONE) And (G <> GK_ALK) Then D := D + CGa[G];
     End;
    End
    Else Begin
     G := GroupKind(Nb2, Nb);
     If (G <> GK_NONE) And (G <> GK_ALK) Then D := D + CBe[G];
    End;
   End;
  End
  Else Begin
   G := GroupKind(Nb, C);
   If (G <> GK_NONE) And (G <> GK_ALK) And (G <> GK_CF3) Then Begin
    D := D + CAl[G];
    { effet gamma/beta des groupes plus loin : ignore }
   End
   Else If G = GK_CF3 Then D := D + 0
   Else Begin
    Inc(NA);
   End;
  End;
 End;
 D := D + 9.1 * NA + 9.4 * NBeta - 2.5 * NGam;
 If D < 0 Then D := D * 0.5;
 If D < -5 Then D := -5;
 ShiftC_sp3 := D;
End;

Function ShiftC_arom(C: Integer): Real;
Var
 R, N, K, P, Q, Dd, G, S, Nb, Hv, Pos2 : Integer;
 D : Real;
 Cyc : Array[0..MAX_RING_SZ - 1] Of Integer;
 InRing : Boolean;
Begin
 R := ArRing[C];
 N := RingN[R];
 For K := 0 To N - 1 Do Cyc[K] := RingA[R, K];
 P := 0;
 For K := 0 To N - 1 Do If Cyc[K] = C Then P := K;
 D := 128.5;
 If N = 5 Then Begin
  { hetero 5 : valeurs par position }
  Hv := -1;
  For K := 0 To N - 1 Do If At^[Cyc[K]].Z In [7, 8, 16] Then Hv := K;
  If Hv >= 0 Then Begin
   Dd := Abs(P - Hv); If Dd > 2 Then Dd := N - Dd;
   Case At^[Cyc[Hv]].Z Of
    8 : If Dd = 1 Then D := 142.8 Else D := 109.8;
    16: If Dd = 1 Then D := 125.6 Else D := 127.3;
   Else If Dd = 1 Then D := 118.4 Else D := 108.2;
   End;
  End;
 End;
 For K := 0 To N - 1 Do Begin
  Dd := Abs(P - K); If Dd > N Div 2 Then Dd := N - Dd;
  If K = P Then Dd := 0;
  { heteroatome du cycle (pyridine) }
  If (N = 6) And (K <> P) And (At^[Cyc[K]].Z = 7) And (At^[Cyc[K]].Chg = 0) Then Begin
   Case Dd Of
    1: D := D + 21.5;
    2: D := D - 5.0;
    3: D := D + 7.4;
   End;
  End;
  If K = P Then Begin
   If (At^[C].Z <> 6) Then D := D + 0;
  End;
  { substituants hors cycle }
  For S := 0 To AdjN^[Cyc[K]] - 1 Do Begin
   Nb := Adj^[Cyc[K], S];
   InRing := False;
   For Q := 0 To N - 1 Do If Cyc[Q] = Nb Then InRing := True;
   If InRing Then Continue;
   G := GroupKind(Nb, Cyc[K]);
   If G = GK_NONE Then Continue;
   If G = GK_ALK Then G := 25;
   If ArA[Nb] Then G := GK_PH;
   Pos2 := Dd;
   If N = 5 Then Begin
    If Dd = 0 Then D := D + CAr[G, 0] * 0.8
    Else If Dd = 1 Then D := D + CAr[G, 1] * 0.7
    Else D := D + CAr[G, 2] * 0.5;
   End
   Else Begin
    If Pos2 > 3 Then Pos2 := 3;
    D := D + CAr[G, Pos2];
   End;
  End;
 End;
 ShiftC_arom := D;
End;

Function ShiftC(C: Integer; Var Desc: String): Real;
Var
 K, Nb, NO, NN, NS, NHal, NC, Dbl, O2, Other, G : Integer;
 D, RV : Real;
Begin
 Desc := 'C';
 If ArA[C] Then Begin
  If Inf^[C].H > 0 Then Desc := 'CH ar.' Else Desc := 'C ar.';
  ShiftC := ShiftC_arom(C);
  Exit;
 End;
 NO := 0; NN := 0; NS := 0; NHal := 0; NC := 0; Dbl := -1; O2 := -1; Other := -1;
 For K := 0 To AdjN^[C] - 1 Do Begin
  Nb := Adj^[C, K];
  Case Bd^[AdjB^[C, K]].Order Of
   3: Begin
    If At^[Nb].Z = 7 Then Begin Desc := 'C#N'; ShiftC := 118; End
    Else Begin
     If Inf^[C].H > 0 Then Begin Desc := 'C#CH'; ShiftC := 68; End
     Else Begin Desc := 'C#C'; ShiftC := 82; End;
    End;
    Exit;
   End;
   2: Begin
    If At^[Nb].Z = 8 Then O2 := Nb
    Else If At^[Nb].Z = 6 Then Dbl := Nb
    Else Other := Nb;
   End;
  End;
  If At^[Nb].Z = 8 Then Inc(NO) Else If At^[Nb].Z = 7 Then Inc(NN)
  Else If At^[Nb].Z = 16 Then Inc(NS) Else If At^[Nb].Z = 6 Then Inc(NC)
  Else If At^[Nb].Z In [9, 17, 35, 53] Then Inc(NHal);
 End;
 If O2 >= 0 Then Begin
  { carbonyle }
  If (NO >= 3) Or ((NO = 2) And (NN > 0)) Then Begin Desc := 'C=O'; ShiftC := 158; Exit; End;
  If NO >= 2 Then Begin
   Desc := 'C=O (acide/ester)'; RV := 172;
   For K := 0 To AdjN^[C] - 1 Do
    If (At^[Adj^[C, K]].Z = 8) And (Bd^[AdjB^[C, K]].Order = 1) And (Inf^[Adj^[C, K]].H > 0) Then RV := 177;
   If NC > 0 Then Begin
    For K := 0 To AdjN^[C] - 1 Do
     If ArA[Adj^[C, K]] Or (Bd^[AdjB^[C, K]].Order > 1) Then RV := RV - 6;
   End;
   ShiftC := RV;
   Exit;
  End;
  If NN > 0 Then Begin Desc := 'C=O (amide)'; ShiftC := 172; Exit; End;
  If NHal > 0 Then Begin Desc := 'C=O (chlorure)'; ShiftC := 170; Exit; End;
  If Inf^[C].H > 0 Then Begin
   Desc := 'CHO'; ShiftC := 200;
   For K := 0 To AdjN^[C] - 1 Do If ArA[Adj^[C, K]] Then ShiftC := 192;
   Exit;
  End;
  Desc := 'C=O (cetone)'; RV := 208;
  For K := 0 To AdjN^[C] - 1 Do
   If ArA[Adj^[C, K]] Or (Bd^[AdjB^[C, K]].Order > 1) Then RV := RV - 10;
  ShiftC := RV;
  Exit;
 End;
 If Other >= 0 Then Begin
  If At^[Other].Z = 7 Then Begin Desc := 'C=N'; ShiftC := 158; Exit; End;
  Desc := 'C=X'; ShiftC := 160; Exit;
 End;
 If Dbl >= 0 Then Begin
   D := 123.3;
  For K := 0 To AdjN^[C] - 1 Do Begin
   Nb := Adj^[C, K];
   If Nb = Dbl Then Continue;
   G := GroupKind(Nb, C);
   Case G Of
    GK_OH, GK_OR, GK_OCOR: D := D + 28;
    GK_NH2, GK_NHR, GK_NR2: D := D + 20;
    GK_CL, GK_BR: D := D + 3;
    GK_F: D := D + 25;
    GK_PH: D := D + 12;
    GK_KET, GK_ALD, GK_ACID, GK_ESTER, GK_AMIDE, GK_CN: D := D + 6;
    GK_CC: D := D + 8;
   Else D := D + 10.5;
   End;
  End;
  For K := 0 To AdjN^[Dbl] - 1 Do Begin
   Nb := Adj^[Dbl, K];
   If Nb = C Then Continue;
   G := GroupKind(Nb, Dbl);
   Case G Of
    GK_OH, GK_OR, GK_OCOR: D := D - 35;
    GK_NH2, GK_NHR, GK_NR2: D := D - 28;
    GK_CL, GK_BR, GK_F: D := D - 5;
    GK_PH: D := D - 8;
    GK_KET, GK_ALD, GK_ACID, GK_ESTER, GK_AMIDE, GK_CN: D := D + 8;
    GK_CC: D := D - 4;
   Else D := D - 8;
   End;
  End;
  If D < 85 Then D := 85;
  If Inf^[C].H = 2 Then Desc := '=CH2' Else If Inf^[C].H = 1 Then Desc := '=CH' Else Desc := '=C<';
  ShiftC := D;
  Exit;
 End;
 { sp3 }
 Case Inf^[C].H Of
  3: Desc := 'CH3';
  2: Desc := 'CH2';
  1: Desc := 'CH';
 Else Desc := 'C';
 End;
 ShiftC := ShiftC_sp3(C);
End;

Procedure PredictC13;
Var C: Integer; Desc: String; Sh: Real;
Begin
 NmrN := 0;
 UpdateInfo; BuildAdj; ComputeCanon; FindAromatic;
 For C := 0 To NAt - 1 Do Begin
  If (At^[C].Z <> 6) Or (At^[C].Lbl <> '') Then Continue;
  Sh := ShiftC(C, Desc);
  If Sh < 0 Then Sh := 0;
  AddPeak(Sh, 1, '', Desc, CanonL[C]);
 End;
End;

{ Deplacement 1H d'un carbone portant des H }
Function ShiftH_C(C: Integer; Var Desc: String): Real;
Var
 K, J, Nb, Nb2, G, Dd, P, Q, N, R, S, Hv : Integer;
 D, Base : Real;
 Cyc : Array[0..MAX_RING_SZ - 1] Of Integer;
 InRing : Boolean;
 Pos2 : Integer;
Begin
 Desc := 'H';
 If ArA[C] Then Begin
  Desc := 'H ar.';
  R := ArRing[C]; N := RingN[R];
  For K := 0 To N - 1 Do Cyc[K] := RingA[R, K];
  P := 0;
  For K := 0 To N - 1 Do If Cyc[K] = C Then P := K;
  D := 7.27;
  If N = 5 Then Begin
   Hv := -1;
   For K := 0 To N - 1 Do If At^[Cyc[K]].Z In [7, 8, 16] Then Hv := K;
   If Hv >= 0 Then Begin
    Dd := Abs(P - Hv); If Dd > 2 Then Dd := N - Dd;
    Case At^[Cyc[Hv]].Z Of
     8 : If Dd = 1 Then D := 7.4 Else D := 6.3;
     16: If Dd = 1 Then D := 7.2 Else D := 7.0;
    Else If Dd = 1 Then D := 6.7 Else D := 6.2;
    End;
   End;
  End;
  For K := 0 To N - 1 Do Begin
   Dd := Abs(P - K); If Dd > N Div 2 Then Dd := N - Dd;
   If K = P Then Continue;
   If (N = 6) And (At^[Cyc[K]].Z = 7) And (At^[Cyc[K]].Chg = 0) Then Begin
    Case Dd Of
     1: D := D + 1.35;
     2: D := D - 0.02;
     3: D := D + 0.37;
    End;
   End;
   For S := 0 To AdjN^[Cyc[K]] - 1 Do Begin
    Nb := Adj^[Cyc[K], S];
    InRing := False;
    For Q := 0 To N - 1 Do If Cyc[Q] = Nb Then InRing := True;
    If InRing Then Continue;
    G := GroupKind(Nb, Cyc[K]);
    If G = GK_NONE Then Continue;
    If G = GK_ALK Then G := 25;
    If ArA[Nb] Then G := GK_PH;
    Pos2 := Dd; If Pos2 > 3 Then Pos2 := 3;
    If (Pos2 >= 1) And (Pos2 <= 3) Then D := D + HAr[G, Pos2 - 1];
   End;
  End;
  ShiftH_C := D;
  Exit;
 End;
 { vinylique }
 For K := 0 To AdjN^[C] - 1 Do
  If (Bd^[AdjB^[C, K]].Order = 2) And (At^[Adj^[C, K]].Z = 6) Then Begin
   Nb := Adj^[C, K];
   If Inf^[C].H = 2 Then Begin Desc := '=CH2'; D := 4.9; End
   Else Begin Desc := '=CH'; D := 5.4; End;
   For J := 0 To AdjN^[C] - 1 Do If Adj^[C, J] <> Nb Then Begin
    G := GroupKind(Adj^[C, J], C);
    If G in [GK_OR, GK_OH, GK_OCOR] Then D := D + 1.0;
    If G in [GK_PH] Then D := D + 1.0;
    If G in [GK_KET, GK_ALD, GK_ACID, GK_ESTER, GK_AMIDE, GK_CN] Then D := D + 0.8;
    If G in [GK_CL, GK_BR] Then D := D + 0.3;
   End;
   For J := 0 To AdjN^[Nb] - 1 Do If Adj^[Nb, J] <> C Then Begin
    G := GroupKind(Adj^[Nb, J], Nb);
    If G in [GK_KET, GK_ALD, GK_ACID, GK_ESTER, GK_AMIDE, GK_CN] Then D := D + 0.9;
    If G in [GK_PH] Then D := D + 0.3;
    If G in [GK_OR, GK_OH, GK_OCOR] Then D := D - 0.6;
   End;
   ShiftH_C := D;
   Exit;
  End;
 { alcyne terminal }
 For K := 0 To AdjN^[C] - 1 Do
  If Bd^[AdjB^[C, K]].Order = 3 Then Begin Desc := '#CH'; ShiftH_C := 2.5; Exit; End;
 { aldehyde }
 For K := 0 To AdjN^[C] - 1 Do
  If (Bd^[AdjB^[C, K]].Order = 2) And (At^[Adj^[C, K]].Z = 8) Then Begin
   Desc := 'CHO'; ShiftH_C := 9.7; Exit;
  End;
 { aliphatique }
 Case Inf^[C].H Of
  3: Begin Base := 0.9; Desc := 'CH3'; End;
  2: Begin Base := 1.25; Desc := 'CH2'; End;
 Else Begin Base := 1.5; Desc := 'CH'; End;
 End;
 D := Base;
 For K := 0 To AdjN^[C] - 1 Do Begin
  Nb := Adj^[C, K];
  G := GroupKind(Nb, C);
  If ArA[Nb] Then G := GK_PH;
  If (G <> GK_NONE) And (G <> GK_ALK) And (G <> GK_CF3) Then Begin
   D := D + HAl[G];
   If (G = GK_CF3) Then D := D + 0;
  End
  Else If G = GK_CF3 Then D := D + 0.3
  Else Begin
   { carbone voisin : effets beta des heteroatomes }
   For J := 0 To AdjN^[Nb] - 1 Do Begin
    Nb2 := Adj^[Nb, J];
    If Nb2 = C Then Continue;
    G := GroupKind(Nb2, Nb);
    If G In [GK_OH, GK_OR, GK_OCOR, GK_NH2, GK_NHR, GK_NR2, GK_NHCO, GK_NO2, GK_F, GK_CL, GK_BR, GK_I, GK_SH, GK_SR] Then
     D := D + 0.25;
   End;
  End;
 End;
 ShiftH_C := D;
End;

Function MultOf(C: Integer): String;
Var K, Nb, NG, NH : Integer; Same : Boolean; Hf : Integer;
Begin
 NG := 0; NH := 0; Hf := -1; Same := True;
 For K := 0 To AdjN^[C] - 1 Do Begin
  Nb := Adj^[C, K];
  If (At^[Nb].Z = 6) And (Inf^[Nb].H > 0) Then Begin
   Inc(NG); NH := NH + Inf^[Nb].H;
   If (Hf >= 0) And (Hf <> Inf^[Nb].H) Then Same := False;
   Hf := Inf^[Nb].H;
  End;
 End;
 If ArA[C] Then Begin MultOf := 'm'; Exit; End;
 If NH = 0 Then MultOf := 's'
 Else If (NG > 1) And Not Same Then MultOf := 'm'
 Else Case NH Of
  1: MultOf := 'd';
  2: MultOf := 't';
  3: MultOf := 'q';
  4: MultOf := 'quint';
  5: MultOf := 'sext';
  6: MultOf := 'sept';
 Else MultOf := 'm';
 End;
End;

Procedure PredictH1;
Var C, Nb, K, G : Integer; Desc : String; Sh : Real;
Begin
 NmrN := 0;
 UpdateInfo; BuildAdj; ComputeCanon; FindAromatic;
 For C := 0 To NAt - 1 Do Begin
  If At^[C].Lbl <> '' Then Continue;
  If (At^[C].Z = 6) And (Inf^[C].H > 0) Then Begin
   Sh := ShiftH_C(C, Desc);
   AddPeak(Sh, Inf^[C].H, MultOf(C), Desc, CanonL[C]);
  End
  Else If (At^[C].Z = 8) And (Inf^[C].H > 0) Then Begin
   Sh := 2.5; Desc := 'OH';
   For K := 0 To AdjN^[C] - 1 Do Begin
    Nb := Adj^[C, K];
    If ArA[Nb] Then Begin Sh := 5.5; Desc := 'OH ar.'; End
    Else If At^[Nb].Z = 6 Then Begin
     G := GroupKind(Nb, C);
     If G = GK_ACID Then Begin Sh := 11.5; Desc := 'COOH'; End;
    End;
   End;
   AddPeak(Sh, Inf^[C].H, 's', Desc, CanonL[C]);
  End
  Else If (At^[C].Z = 7) And (Inf^[C].H > 0) And (At^[C].Chg = 0) Then Begin
   Sh := 1.5; Desc := 'NH';
   For K := 0 To AdjN^[C] - 1 Do Begin
    Nb := Adj^[C, K];
    If ArA[Nb] Then Begin Sh := 3.7; Desc := 'NH ar.'; End
    Else If At^[Nb].Z = 6 Then Begin
     G := GroupKind(Nb, C);
     If G = GK_AMIDE Then Begin Sh := 6.5; Desc := 'CONH'; End;
    End;
   End;
   AddPeak(Sh, Inf^[C].H, 's', Desc, CanonL[C]);
  End
  Else If (At^[C].Z = 16) And (Inf^[C].H > 0) Then
   AddPeak(1.6, Inf^[C].H, 's', 'SH', CanonL[C]);
 End;
End;

{ Trace le spectre dans une boite de dialogue }
Procedure ShowSpectrum(Const Title: String; IsH: Boolean);
Const BW = 90; BH = 22;
Var
 X1, Y1, X2, Y2, PX1, PY1, PX2, PY2, I, J, K, Key, MX, MY, BX1, BX2, BY1, BY2, B3X : Integer;
 Click, Done : Boolean;
 Lo, Hi, Sc, PkMax, T : Real;
 XP, H, Lines2, Sp : Integer;
 S : String;
 Bino : Array[0..6] Of Integer;
 LblEnd : Array[0..4] Of Integer;
 SOrd : Array[0..MAX_PK - 1] Of Integer;
 T2 : Integer;
Begin
 If NmrN = 0 Then Begin ShowMessage(Title, 'Aucun atome a analyser.'); Exit; End;
 If IsH Then Begin Lo := 0; Hi := 12; End Else Begin Lo := 0; Hi := 220; End;
 PkMax := 0;
 For I := 0 To NmrN - 1 Do Begin
  If NmrCnt[I] > PkMax Then PkMax := NmrCnt[I];
  If NmrPpm[I] > Hi Then Hi := Trunc(NmrPpm[I]) + 2;
 End;
 X1 := 20; Y1 := 40; X2 := ScreenWidth - 20; Y2 := ScreenHeight - 40;
 PX1 := X1 + 20; PX2 := X2 - 20; PY1 := Y1 + 40; PY2 := Y2 - 70;
 BY1 := Y2 - 30; BY2 := BY1 + BH;
 BX2 := X2 - 12; BX1 := BX2 - BW; B3X := BX1 - BW - 10;
 HideMouseCursor;
 DrawDialogBox(X1, Y1, X2, Y2, Title);
 SetFillStyle(SolidFill, White);
 Bar(PX1 - 10, PY1 - 22, PX2 + 10, PY2 + 24);
 SetColor(Black);
 Rectangle(PX1 - 10, PY1 - 22, PX2 + 10, PY2 + 24);
 Line(PX1, PY2, PX2, PY2);
 SetTextStyle(DefaultFont, HorizDir, 1);
 { graduations (ppm decroissants vers la droite) }
 Sc := (PX2 - PX1) / (Hi - Lo);
 If IsH Then J := 1 Else J := 20;
 K := 0;
 While K <= Hi Do Begin
  XP := PX2 - Round((K - Lo) * Sc);
  Line(XP, PY2, XP, PY2 + 4);
  S := IntToStr(K);
  OutTextXY(XP - 4 * Length(S), PY2 + 7, S);
  Inc(K, J);
 End;
 OutTextXY(PX1, PY2 + 18, 'ppm');
 For K := 0 To 4 Do LblEnd[K] := -999;
 For J := 0 To NmrN - 1 Do SOrd[J] := J;
 For J := 1 To NmrN - 1 Do Begin
  T2 := SOrd[J]; K := J - 1;
  While (K >= 0) And (NmrPpm[SOrd[K]] < NmrPpm[T2]) Do Begin SOrd[K + 1] := SOrd[K]; Dec(K); End;
  SOrd[K + 1] := T2;
 End;
 For J := 0 To NmrN - 1 Do Begin
  I := SOrd[J];
  XP := PX2 - Round((NmrPpm[I] - Lo) * Sc);
  If IsH Then H := 25 + Round(NmrCnt[I] / PkMax * (PY2 - PY1 - 100))
  Else H := (PY2 - PY1 - 70) Div 2 + Round(NmrCnt[I] / PkMax * ((PY2 - PY1 - 70) Div 2));
  If H > PY2 - PY1 - 60 Then H := PY2 - PY1 - 60;
  SetColor(Blue);
  If IsH Then Begin
   Lines2 := 1;
   If NmrMult[I] = 'd' Then Lines2 := 2 Else If NmrMult[I] = 't' Then Lines2 := 3
   Else If NmrMult[I] = 'q' Then Lines2 := 4 Else If NmrMult[I] = 'quint' Then Lines2 := 5
   Else If NmrMult[I] = 'sext' Then Lines2 := 6 Else If NmrMult[I] = 'sept' Then Lines2 := 7
   Else If NmrMult[I] = 'm' Then Lines2 := 5;
   For K := 0 To 6 Do Bino[K] := 0;
   Case Lines2 Of
    1: Begin Bino[0] := 1; End;
    2: Begin Bino[0] := 1; Bino[1] := 1; End;
    3: Begin Bino[0] := 1; Bino[1] := 2; Bino[2] := 1; End;
    4: Begin Bino[0] := 1; Bino[1] := 3; Bino[2] := 3; Bino[3] := 1; End;
    5: Begin Bino[0] := 1; Bino[1] := 4; Bino[2] := 6; Bino[3] := 4; Bino[4] := 1; End;
    6: Begin Bino[0] := 1; Bino[1] := 5; Bino[2] := 10; Bino[3] := 10; Bino[4] := 5; Bino[5] := 1; End;
   Else
    Bino[0] := 1; Bino[1] := 6; Bino[2] := 15; Bino[3] := 20; Bino[4] := 15; Bino[5] := 6; Bino[6] := 1;
   End;
   Sp := 3;
   For K := 0 To Lines2 - 1 Do Begin
    T := H * Bino[K] / (Bino[Lines2 Div 2] + 0.0);
    If Lines2 > 1 Then T := H * Bino[K] / (Bino[(Lines2 - 1) Div 2] + 0.0);
    If T > H Then T := H;
    Line(Round(XP + (K - (Lines2 - 1) / 2) * Sp), PY2, Round(XP + (K - (Lines2 - 1) / 2) * Sp), PY2 - Round(T));
   End;
  End
  Else Line(XP, PY2, XP, PY2 - H);
  SetColor(Black);
  S := RealToStr(NmrPpm[I], 1);
  If IsH Then S := RealToStr(NmrPpm[I], 2);
  K := 0;
  While (K < 4) And (LblEnd[K] > XP - 4 * Length(S) - 2) Do Inc(K);
  LblEnd[K] := XP + 4 * Length(S);
  OutTextXY(XP - 4 * Length(S), PY2 - H - 12 - K * 10, S);
  If IsH Then Begin
   SetColor(DarkGray);
   OutTextXY(XP - 4, PY2 + 28 + (I Mod 2) * 0, IntToStr(NmrCnt[I]) + 'H');
  End;
 End;
 SetColor(Black);
 If IsH Then S := 'Prediction RMN 1H (approximative) - 400 MHz, CDCl3'
 Else S := 'Prediction RMN 13C (approximative) - decouple 1H';
 OutTextXY(PX1, PY1 - 14, S);
 SetColor(DarkGray);
 OutTextXY(X1 + 8, Y2 - 24, 'Echap = fermer');
 DrawButton(B3X, BY1, B3X + BW, BY2, 'Tableau...', False);
 DrawButton(BX1, BY1, BX2, BY2, 'Fermer', True);
 ShowMouseCursor;
 DlgBegin;
 Done := False;
 While Not Done Do Begin
  If DlgPoll(Key, MX, MY, Click) Then Begin
   If (Key = 27) Or (Key = 13) Then Done := True;
   If Click And PtInRect(MX, MY, BX1, BY1, BX2, BY2) Then Done := True;
   If Click And PtInRect(MX, MY, B3X, BY1, B3X + BW, BY2) Then Begin
    NTL := 0;
    If IsH Then Begin
     TLines[NTL] := PadR('ppm', 8) + PadR('H', 5) + PadR('mult.', 7) + 'groupe'; Inc(NTL);
    End
    Else Begin
     TLines[NTL] := PadR('ppm', 8) + PadR('nb', 5) + 'groupe'; Inc(NTL);
    End;
    For I := 0 To NmrN - 1 Do Begin
     If IsH Then
      TLines[NTL] := PadR(RealToStr(NmrPpm[I], 2), 8) + PadR(IntToStr(NmrCnt[I]), 5) + PadR(NmrMult[I], 7) + NmrDesc[I]
     Else
      TLines[NTL] := PadR(RealToStr(NmrPpm[I], 1), 8) + PadR(IntToStr(NmrCnt[I]), 5) + NmrDesc[I];
     Inc(NTL);
    End;
    ListDialog('Tableau des deplacements chimiques', False);
    Done := True;
   End;
  End;
  Delay(10);
 End;
 DlgEnd;
End;

{ --------------------------------------------------------------------- }
{ Dialogues d'analyse                                                   }
{ --------------------------------------------------------------------- }

Procedure AddTL(Const S: String);
Begin
 If NTL < MAX_TL Then Begin TLines[NTL] := Copy(S, 1, 72); Inc(NTL); End;
End;

Procedure DetailedAnalysis;
Var
 C : TCounts;
 Chg, Z, I, K, Cnt, Don, Acc, Rot, NH, NHal, NN : Integer;
 Generic, SelOnly : Boolean;
 MW, EM, Dbe : Real;
 D : TIsoDist;
 Nm : String;
 Mx : Real;
Begin
 SelOnly := CountSelAtoms > 0;
 Composition(SelOnly, C, Chg, Generic);
 Cnt := 0;
 For Z := 1 To 103 Do Inc(Cnt, C[Z]);
 If Cnt = 0 Then Begin ShowMessage('Analyse', 'Aucune structure a analyser.'); Exit; End;
 UpdateInfo; BuildAdj; EnsureRings;
 MW := MolWeight(C); EM := ExactMass(C);
 NTL := 0;
 If SelOnly Then AddTL('(analyse de la selection)');
 AddTL('Formule moleculaire : ' + HillFormula(C, Chg));
 AddTL('Poids moleculaire   : ' + RealToStr(MW, 3));
 AddTL('Masse exacte        : ' + RealToStr(EM, 5));
 IsotopePattern(C, D);
 Mx := 0;
 For I := 0 To ISO_MAX Do If D.P[I] > Mx Then Mx := D.P[I];
 For I := 0 To ISO_MAX Do
  If (Mx > 0) And (D.P[I] / Mx > 0.005) Then Begin
   AddTL('   ' + RealToStr(EM + D.M[I], 4) + '  (' + RealToStr(D.P[I] / Mx * 100, 1) + ' %)');
  End;
 AddTL('');
 AddTL('Analyse elementaire :');
 For K := 1 To 103 Do Begin
  Z := K;
  If K = 1 Then Z := 6 Else If K = 2 Then Z := 1 Else If K = 6 Then Z := 2;
  If C[Z] > 0 Then
   AddTL('   ' + PadR(ElSym[Z], 3) + PadL(IntToStr(C[Z]), 4) + '   ' +
         RealToStr(C[Z] * ElWt[Z] / MW * 100, 2) + ' %   (' + ElName[Z] + ')');
 End;
 AddTL('');
 NH := C[1]; NHal := C[9] + C[17] + C[35] + C[53]; NN := C[7] + C[15];
 Dbe := (2 * C[6] + 2 + NN - NH - NHal) / 2;
 AddTL('Degres d''insaturation : ' + RealToStr(Dbe, 1));
 AddTL('Atomes lourds : ' + IntToStr(Cnt - C[1]) + '   Liaisons : ' + IntToStr(NBd) + '   Cycles : ' + IntToStr(NRings));
 Don := 0; Acc := 0; Rot := 0;
 For I := 0 To NAt - 1 Do Begin
  If SelOnly And Not At^[I].Sel Then Continue;
  If (At^[I].Z In [7, 8]) Then Begin Inc(Acc); If Inf^[I].H > 0 Then Inc(Don); End;
 End;
 For I := 0 To NBd - 1 Do
  If (Bd^[I].Order = 1) And (Inf^[Bd^[I].A].Deg > 1) And (Inf^[Bd^[I].B].Deg > 1) And
     (RingOfBond(Bd^[I].A, Bd^[I].B) < 0) And (Inf^[Bd^[I].A].BSum - Bd^[I].Order < 3) Then Inc(Rot);
 AddTL('Donneurs de H : ' + IntToStr(Don) + '   Accepteurs : ' + IntToStr(Acc) + '   Liaisons rotatives : ' + IntToStr(Rot));
 If Generic Then AddTL('Attention : la structure contient des atomes generiques (R, X ...)');
 WriteSmiles(SelOnly);
 AddTL('');
 AddTL('SMILES : ' + SmBufStr);
 If (Not SelOnly) And NameFromStructure(Nm) Then AddTL('Nom : ' + Nm);
 ListDialog('Analyse detaillee', False);
End;

Procedure ShowMassSpectrum;
Const BW = 90; BH = 22;
Var
 C : TCounts;
 Chg, Z, I, Cnt, X1, Y1, X2, Y2, PX1, PY1, PX2, PY2, XP, H, K, Key, MX, MY, BX1, BY1, BX2, BY2 : Integer;
 Generic, Click, Done : Boolean;
 EM, PkMax, Lo, Hi, Sc : Real;
 D : TIsoDist;
 S : String;
Begin
 Composition(CountSelAtoms > 0, C, Chg, Generic);
 Cnt := 0;
 For Z := 1 To 103 Do Inc(Cnt, C[Z]);
 If Cnt = 0 Then Begin ShowMessage('Spectre de masse', 'Aucune structure a analyser.'); Exit; End;
 EM := ExactMass(C);
 IsotopePattern(C, D);
 PkMax := 0;
 For I := 0 To ISO_MAX Do If D.P[I] > PkMax Then PkMax := D.P[I];
 X1 := 40; Y1 := 60; X2 := ScreenWidth - 40; Y2 := ScreenHeight - 60;
 PX1 := X1 + 30; PX2 := X2 - 30; PY1 := Y1 + 50; PY2 := Y2 - 60;
 BX2 := X2 - 12; BX1 := BX2 - BW; BY1 := Y2 - 30; BY2 := BY1 + BH;
 Lo := Trunc(EM) - 2; Hi := Trunc(EM) + ISO_MAX + 1;
 Sc := (PX2 - PX1) / (Hi - Lo);
 HideMouseCursor;
 DrawDialogBox(X1, Y1, X2, Y2, 'Spectre de masse - motif isotopique');
 SetFillStyle(SolidFill, White);
 Bar(PX1 - 10, PY1 - 22, PX2 + 10, PY2 + 38);
 SetColor(Black);
 Rectangle(PX1 - 10, PY1 - 22, PX2 + 10, PY2 + 38);
 Line(PX1, PY2, PX2, PY2);
 SetTextStyle(DefaultFont, HorizDir, 1);
 For K := Round(Lo) To Round(Hi) Do Begin
  XP := PX1 + Round((K - Lo) * Sc);
  Line(XP, PY2, XP, PY2 + 3);
  S := IntToStr(K);
  OutTextXY(XP - 4 * Length(S), PY2 + 6, S);
 End;
 OutTextXY(PX1, PY1 - 16, 'Formule ' + HillFormula(C, Chg) + '   (intensite relative, %)');
 For I := 0 To ISO_MAX Do Begin
  If (PkMax <= 0) Or (D.P[I] / PkMax < 0.001) Then Continue;
  XP := PX1 + Round((EM + D.M[I] - Lo) * Sc);
  H := Round(D.P[I] / PkMax * (PY2 - PY1 - 10));
  SetFillStyle(SolidFill, Blue);
  Bar(XP - 2, PY2 - H, XP + 2, PY2);
  SetColor(Black);
  S := RealToStr(D.P[I] / PkMax * 100, 1);
  OutTextXY(XP - 4 * Length(S), PY2 - H - 12, S);
  S := RealToStr(EM + D.M[I], 2);
  SetColor(DarkGray);
  OutTextXY(XP - 4 * Length(S), PY2 + 16 + (I Mod 2) * 10, S);
 End;
 DrawButton(BX1, BY1, BX2, BY2, 'Fermer', True);
 ShowMouseCursor;
 DlgBegin;
 Done := False;
 While Not Done Do Begin
  If DlgPoll(Key, MX, MY, Click) Then Begin
   If (Key = 27) Or (Key = 13) Then Done := True;
   If Click And PtInRect(MX, MY, BX1, BY1, BX2, BY2) Then Done := True;
  End;
  Delay(10);
 End;
 DlgEnd;
End;

Procedure CheckStructure;
Var I, N: Integer;
Begin
 UpdateInfo;
 NTL := 0; N := 0;
 For I := 0 To NAt - 1 Do
  If Inf^[I].Warn Then Begin
   If At^[I].Lbl <> '' Then
    AddTL('Atome ' + IntToStr(I + 1) + ' (' + At^[I].Lbl + ') : groupe relie a plusieurs liaisons')
   Else
    AddTL('Atome ' + IntToStr(I + 1) + ' (' + ElSym[At^[I].Z] + ') : valence ' + IntToStr(Inf^[I].BSum) +
          ' trop elevee (max ' + IntToStr(MaxValence(At^[I].Z, At^[I].Chg)) + ')');
   Inc(N);
  End;
 If N = 0 Then ShowMessage('Verification', 'Aucun probleme detecte (' + IntToStr(NAt) + ' atomes, ' + IntToStr(NBd) + ' liaisons).')
 Else ListDialog('Verification de la structure : ' + IntToStr(N) + ' probleme(s)', False);
End;

{ --------------------------------------------------------------------- }
{ Stereochimie : priorites CIP, descripteurs R/S et E/Z                 }
{ --------------------------------------------------------------------- }
{ Le graphe hierarchique (digraphe CIP) est construit sphere par sphere
  a partir du centre : atomes dupliques pour les liaisons multiples et les
  fermetures de cycles, hydrogenes implicites et doublets libres.
  Regles appliquees : 1a (numero atomique), 2 (nombre de masse),
  3 (Z avant E), 4a (unites chirales avant pseudo-asymetriques), 4b (like
  avant unlike), 4c (r avant s) et 5 (R avant S). Les descripteurs des
  centres du digraphe viennent des etiquettes deja calculees ; un centre
  dont les deux ligands de cycle sont equivalents recoit un descripteur
  provisoire selon le sens de parcours depuis la racine. }

Const
 CP_MAXN  = 6000;
 CP_KIDS  = 7;
 CP_DEPTH = 14;

Type
 TCpNode = Record
  Z    : Byte;
  Mass : Integer;
  A    : Integer;           { atome (>=0), -1 = H implicite, -2 = doublet }
  Par  : Integer;           { noeud parent (-1 = branche issue de la racine) }
  Lev  : Byte;
  NK   : Byte;
  Dup  : Boolean;
  Ds   : Byte;              { descripteur : 1 R, 2 S, 3 r, 4 s }
  Ez   : Byte;              { 1 = E, 2 = Z (liaison double portee) }
  Kid  : Array[0..CP_KIDS - 1] Of Integer;
 End;
 TCpArr = Array[0..CP_MAXN - 1] Of TCpNode;
 TCpLst = Array[0..CP_MAXN - 1] Of Integer;

Var
 Cp     : ^TCpArr;
 CpN    : Integer;
 CpRoot : Integer;
 CpOver : Boolean;
 CpL1, CpL2, CpL3, CpL4 : ^TCpLst;
 CpReady : Boolean;
 CpRuleMax : Integer;      { regles actives : 2, 3 (+ Z/E) ou 6 (toutes) }
 CmpRule   : Integer;      { regle qui a departage la derniere comparaison }
 ConvUp    : Boolean;      { convention des centres d'un cycle symetrique }
 TieA, TieB : Array[0..MAX_ATOMS - 1] Of Integer;
 TieLab    : Array[0..MAX_ATOMS - 1] Of Char;

Procedure InitStereo;
Begin
 If CpReady Then Exit;
 ConvUp := True; CpRuleMax := 6;
 New(Cp); New(CpL1); New(CpL2); New(CpL3); New(CpL4);
 New(StC); New(EzC);
 CpReady := True;
End;

Function MassNum(Z, Iso: Integer): Integer;
Begin
 If Iso > 0 Then MassNum := Iso
 Else If Z = 35 Then MassNum := 79
 Else If (Z >= 1) And (Z <= 103) Then MassNum := Round(ElWt[Z])
 Else MassNum := 0;
End;

Function NewCp(AZ, AMass, AA, APar, ALev: Integer; ADup: Boolean): Integer;
Begin
 If CpN >= CP_MAXN Then Begin CpOver := True; NewCp := -1; Exit; End;
 Cp^[CpN].Z := AZ; Cp^[CpN].Mass := AMass; Cp^[CpN].A := AA;
 Cp^[CpN].Par := APar; Cp^[CpN].Lev := ALev; Cp^[CpN].NK := 0;
 Cp^[CpN].Dup := ADup; Cp^[CpN].Ds := 0; Cp^[CpN].Ez := 0;
 NewCp := CpN;
 Inc(CpN);
End;

Function AddKid(X, AZ, AMass, AA: Integer; ADup: Boolean): Integer;
Var K: Integer;
Begin
 AddKid := -1;
 If Cp^[X].NK >= CP_KIDS Then Exit;
 K := NewCp(AZ, AMass, AA, X, Cp^[X].Lev + 1, ADup);
 If K < 0 Then Exit;
 Cp^[X].Kid[Cp^[X].NK] := K;
 Inc(Cp^[X].NK);
 AddKid := K;
End;

Procedure AddDupKid(X, M: Integer);
Var K: Integer;
Begin
 K := AddKid(X, At^[M].Z, MassNum(At^[M].Z, At^[M].Iso), M, True);
End;

{ Liaison multiple P=O, S=O ... : traitee comme une liaison simple avec
  separation de charges (pas d'atomes dupliques) }
Function YlideBond(A, M: Integer): Boolean;
Var ZA, ZM: Integer;
Begin
 ZA := At^[A].Z; ZM := At^[M].Z;
 YlideBond := ((ZA In [15, 16, 33, 34]) And (ZM In [7, 8, 16, 34])) Or
              ((ZM In [15, 16, 33, 34]) And (ZA In [7, 8, 16, 34]));
End;

{ Ajoute les voisins du noeud X (atome A) dans le digraphe }
Procedure ExpandNode(X: Integer);
Var
 A, P, K, M, J, T, X2, K2, BO : Integer;
 OnPath : Boolean;
Begin
 A := Cp^[X].A;
 If Cp^[X].Par >= 0 Then P := Cp^[Cp^[X].Par].A Else P := CpRoot;
 J := FindBond(A, P);
 If J >= 0 Then
  If Not YlideBond(A, P) Then
   For T := 2 To Bd^[J].Order Do AddDupKid(X, P);
 For K := 0 To AdjN^[A] - 1 Do Begin
  M := Adj^[A, K];
  If M = P Then Continue;
  J := AdjB^[A, K];
  OnPath := M = CpRoot;
  X2 := Cp^[X].Par;
  While (Not OnPath) And (X2 >= 0) Do Begin
   If Cp^[X2].A = M Then OnPath := True;
   X2 := Cp^[X2].Par;
  End;
  If OnPath Then AddDupKid(X, M)
  Else K2 := AddKid(X, At^[M].Z, MassNum(At^[M].Z, At^[M].Iso), M, False);
  BO := Bd^[J].Order;
  If YlideBond(A, M) Then BO := 1;
  For T := 2 To BO Do AddDupKid(X, M);
 End;
 For T := 1 To Inf^[A].H Do K2 := AddKid(X, 1, 1, -1, False);
End;

{ Developpe tout le digraphe niveau par niveau a partir de F ;
  si la reserve est epuisee au milieu d'un niveau, ce niveau n'est pas
  developpe du tout (les branches restent comparables) }
Procedure ExpandAll(F: Integer);
Var X, Y, CurLev, LevBegin : Integer;
Begin
 CpOver := False;
 CurLev := -1; LevBegin := CpN;
 X := F;
 While X < CpN Do Begin
  If Cp^[X].Lev <> CurLev Then Begin
   CurLev := Cp^[X].Lev; LevBegin := CpN;
  End;
  If CurLev >= CP_DEPTH Then Break;
  If (Not Cp^[X].Dup) And (Cp^[X].A >= 0) Then ExpandNode(X);
  If CpOver Then Begin
   CpN := LevBegin;
   For Y := 0 To CpN - 1 Do
    If Cp^[Y].Lev = CurLev Then Cp^[Y].NK := 0;
   CpOver := False;
   Break;
  End;
  Inc(X);
 End;
End;

Function NodeVal(X, Mode: Integer): Integer;
Var D: Integer;
Begin
 If X < 0 Then Begin NodeVal := 0; Exit; End;
 D := Cp^[X].Ds;
 Case Mode Of
  0: NodeVal := Cp^[X].Z;
  1: NodeVal := Cp^[X].Mass;
  2: NodeVal := Cp^[X].Ez;
  3: If D In [1, 2] Then NodeVal := 2 Else If D In [3, 4] Then NodeVal := 1 Else NodeVal := 0;
  5: If D = 3 Then NodeVal := 2 Else If D = 4 Then NodeVal := 1 Else NodeVal := 0;
  6: If D = 1 Then NodeVal := 2 Else If D = 2 Then NodeVal := 1 Else NodeVal := 0;
 Else NodeVal := 0;
 End;
End;

{ Compare deux sous-arbres sphere par sphere : -1, 0 ou 1 }
Function CmpMode(A, B, Mode: Integer): Integer;
Var
 N, M, I, T, KA, KB, K, VA, VB : Integer;
 P : ^TCpLst;
Begin
 CmpMode := 0;
 CpL1^[0] := A; CpL2^[0] := B; N := 1;
 While N > 0 Do Begin
  For I := 0 To N - 1 Do Begin
   VA := NodeVal(CpL1^[I], Mode); VB := NodeVal(CpL2^[I], Mode);
   If VA <> VB Then Begin
    If VA > VB Then CmpMode := 1 Else CmpMode := -1;
    Exit;
   End;
  End;
  M := 0;
  For I := 0 To N - 1 Do Begin
   KA := 0; KB := 0;
   If CpL1^[I] >= 0 Then KA := Cp^[CpL1^[I]].NK;
   If CpL2^[I] >= 0 Then KB := Cp^[CpL2^[I]].NK;
   K := KA; If KB > K Then K := KB;
   For T := 0 To K - 1 Do Begin
    If M >= CP_MAXN Then Exit;
    If T < KA Then CpL3^[M] := Cp^[CpL1^[I]].Kid[T] Else CpL3^[M] := -1;
    If T < KB Then CpL4^[M] := Cp^[CpL2^[I]].Kid[T] Else CpL4^[M] := -1;
    Inc(M);
   End;
  End;
  P := CpL1; CpL1 := CpL3; CpL3 := P;
  P := CpL2; CpL2 := CpL4; CpL4 := P;
  N := M;
 End;
End;

{ Liste des descripteurs d'un ligand, sphere par sphere (R/S = 1, 2 ; r/s = 3, 4) }
Function DescList(A: Integer; Var L: Array Of Integer): Integer;
Var N, M, I, T, K, Cnt : Integer; P : ^TCpLst;
Begin
 Cnt := 0;
 CpL1^[0] := A; N := 1;
 While N > 0 Do Begin
  For I := 0 To N - 1 Do
   If (CpL1^[I] >= 0) And (Cp^[CpL1^[I]].Ds <> 0) And (Cnt <= High(L)) Then Begin
    L[Cnt] := Cp^[CpL1^[I]].Ds; Inc(Cnt);
   End;
  M := 0;
  For I := 0 To N - 1 Do
   If CpL1^[I] >= 0 Then
    For T := 0 To Cp^[CpL1^[I]].NK - 1 Do
     If M < CP_MAXN Then Begin CpL3^[M] := Cp^[CpL1^[I]].Kid[T]; Inc(M); End;
  P := CpL1; CpL1 := CpL3; CpL3 := P;
  N := M;
 End;
 DescList := Cnt;
End;

{ Regle 4b : un ligand dont les descripteurs sont tous identiques au premier
  (like) l'emporte sur un ligand qui en contient d'opposes (unlike) }
Function Cmp4b(A, B: Integer): Integer;
Var
 LA, LB : Array[0..63] Of Integer;
 NA, NB, I, M, FA, FB : Integer;
Begin
 Cmp4b := 0;
 NA := DescList(A, LA); NB := DescList(B, LB);
 If (NA < 2) And (NB < 2) Then Exit;
 M := NA; If NB > M Then M := NB;
 For I := 1 To M - 1 Do Begin
  FA := 0; FB := 0;
  If (I < NA) And (LA[I] = LA[0]) Then FA := 1;
  If (I < NB) And (LB[I] = LB[0]) Then FB := 1;
  If FA <> FB Then Begin
   If FA > FB Then Cmp4b := 1 Else Cmp4b := -1;
   Exit;
  End;
 End;
End;

{ Les deux ligands sont-ils image l'un de l'autre dans un miroir ? }
Function Enantiomorphic(A, B: Integer): Boolean;
Var
 LA, LB : Array[0..63] Of Integer;
 NA, NB, I : Integer;
Begin
 Enantiomorphic := False;
 NA := DescList(A, LA); NB := DescList(B, LB);
 If (NA = 0) Or (NA <> NB) Then Exit;
 For I := 0 To NA - 1 Do Begin
  If (LA[I] In [1, 2]) And (LB[I] <> 3 - LA[I]) Then Exit;
  If (LA[I] In [3, 4]) And (LB[I] <> 7 - LA[I]) Then Exit;
 End;
 Enantiomorphic := True;
End;

Function CmpNodes(A, B: Integer): Integer;
Var R: Integer;
Begin
 CmpRule := 1;
 R := CmpMode(A, B, 0);
 If (R = 0) Then Begin CmpRule := 2; R := CmpMode(A, B, 1); End;
 If (R = 0) And (CpRuleMax >= 3) Then Begin CmpRule := 3; R := CmpMode(A, B, 2); End;
 If (R = 0) And (CpRuleMax >= 6) Then Begin CmpRule := 4; R := CmpMode(A, B, 3); End;
 If (R = 0) And (CpRuleMax >= 6) Then Begin CmpRule := 4; R := Cmp4b(A, B); End;
 If (R = 0) And (CpRuleMax >= 6) Then Begin CmpRule := 5; R := CmpMode(A, B, 5); End;
 If (R = 0) And (CpRuleMax >= 6) Then Begin CmpRule := 6; R := CmpMode(A, B, 6); End;
 CmpNodes := R;
End;

{ Descripteurs portes par les noeuds : Z / E des liaisons doubles, R / S des
  centres deja etiquetes ; un centre indecidable a cause d'un cycle
  symetrique recoit un descripteur provisoire r / s selon le sens de
  parcours (le voisin du cote de la racine est range au-dessus) }
Procedure AssignDesc;
Var X, A, J, K, Pa : Integer; Lab : Char; Up : Boolean;
Begin
 For X := 0 To CpN - 1 Do Begin
  A := Cp^[X].A;
  If (A < 0) Or Cp^[X].Dup Then Continue;
  For K := 0 To AdjN^[A] - 1 Do Begin
   J := AdjB^[A, K];
   If EzC^[J] = 'Z' Then Cp^[X].Ez := 2
   Else If (EzC^[J] = 'E') And (Cp^[X].Ez = 0) Then Cp^[X].Ez := 1;
  End;
  If CpRuleMax < 6 Then Continue;
  Lab := StC^[A];
  If Cp^[X].Par >= 0 Then Pa := Cp^[Cp^[X].Par].A Else Pa := CpRoot;
  If (TieA[A] >= 0) And ((Pa = TieA[A]) Or (Pa = TieB[A])) Then Begin
   Up := Pa = TieA[A];
   Lab := TieLab[A];
   If Up <> ConvUp Then Begin
    If Lab = 'R' Then Lab := 'S' Else Lab := 'R';
   End;
   If Lab = 'R' Then Cp^[X].Ds := 3 Else Cp^[X].Ds := 4;
  End
  Else If Lab = 'R' Then Cp^[X].Ds := 1
  Else If Lab = 'S' Then Cp^[X].Ds := 2
  Else If Lab = 'r' Then Cp^[X].Ds := 3
  Else If Lab = 's' Then Cp^[X].Ds := 4;
 End;
End;

{ Trie les fils de tous les noeuds, du plus profond au plus proche }
Procedure SortAllKids;
Var X, I, J, T : Integer;
Begin
 For X := CpN - 1 Downto 0 Do
  For I := 1 To Cp^[X].NK - 1 Do Begin
   T := Cp^[X].Kid[I]; J := I - 1;
   While (J >= 0) And (CmpNodes(Cp^[X].Kid[J], T) < 0) Do Begin
    Cp^[X].Kid[J + 1] := Cp^[X].Kid[J];
    Dec(J);
   End;
   Cp^[X].Kid[J + 1] := T;
  End;
End;

{ Construit les branches issues de Root (sauf Excl) ; ajoute un doublet
  libre si LPWant > 0 et que les branches sont au nombre de LPWant - 1.
  Renvoie le nombre de branches. }
Function BuildBranches(Root, Excl, LPWant: Integer; Var Br: Array Of Integer): Integer;
Var K, M, T, NB, X : Integer;
Begin
 CpN := 0; CpRoot := Root; CpOver := False; NB := 0;
 For K := 0 To AdjN^[Root] - 1 Do Begin
  M := Adj^[Root, K];
  If M = Excl Then Continue;
  If NB > 3 Then Break;
  X := NewCp(At^[M].Z, MassNum(At^[M].Z, At^[M].Iso), M, -1, 0, False);
  Br[NB] := X; Inc(NB);
 End;
 For T := 1 To Inf^[Root].H Do Begin
  If NB > 3 Then Break;
  X := NewCp(1, 1, -1, -1, 0, False);
  Br[NB] := X; Inc(NB);
 End;
 If (LPWant > 0) And (NB = LPWant - 1) Then Begin
  X := NewCp(0, 0, -2, -1, 0, False);
  Br[NB] := X; Inc(NB);
 End;
 ExpandAll(0);
 AssignDesc;
 SortAllKids;
 BuildBranches := NB;
End;

{ Trie les branches par priorite decroissante ; faux si deux sont egales }
Function RankBranches(NB: Integer; Var Br: Array Of Integer): Boolean;
Var I, J, T : Integer;
Begin
 For I := 1 To NB - 1 Do Begin
  T := Br[I]; J := I - 1;
  While (J >= 0) And (CmpNodes(Br[J], T) < 0) Do Begin
   Br[J + 1] := Br[J];
   Dec(J);
  End;
  Br[J + 1] := T;
 End;
 RankBranches := True;
 For I := 0 To NB - 2 Do
  If CmpNodes(Br[I], Br[I + 1]) = 0 Then RankBranches := False;
End;

{ --------------------------------------------------------------------- }
{ Centres stereogenes (R/S)                                              }
{ --------------------------------------------------------------------- }

{ Renvoie 0 : pas un centre ; 1 : centre sans doublet ; 2 : avec doublet }
Function StereoKind(C: Integer): Integer;
Var Z, D, H, BS : Integer;
Begin
 StereoKind := 0;
 If (At^[C].Lbl <> '') Or (At^[C].Rad > 0) Then Exit;
 Z := At^[C].Z; D := Inf^[C].Deg; H := Inf^[C].H; BS := Inf^[C].BSum;
 If D < 2 Then Exit;
 Case Z Of
  6, 14, 32, 50: If (At^[C].Chg = 0) And (D + H = 4) And (BS + H = 4) Then StereoKind := 1;
  7: If (At^[C].Chg = 1) And (D + H = 4) And (BS + H = 4) Then StereoKind := 1;
  15: If At^[C].Chg = 0 Then Begin
       If D + H = 4 Then StereoKind := 1
       Else If (D = 3) And (H = 0) And (BS = 3) Then StereoKind := 2;
      End
      Else If (At^[C].Chg = 1) And (D + H = 4) Then StereoKind := 1;
  16: If (At^[C].Chg = 0) And (D = 3) And (H = 0) And (BS = 4) Then StereoKind := 2
      Else If (At^[C].Chg = 1) And (D = 3) And (H = 0) And (BS = 3) Then StereoKind := 2;
 End;
End;

Function Det3(AX, AY, AZ, BX, BY, BZ, CX, CY, CZ: Real): Real;
Begin
 Det3 := AX * (BY * CZ - BZ * CY) - AY * (BX * CZ - BZ * CX) + AZ * (BX * CY - BY * CX);
End;

{ Vecteur 3D unitaire (plan) + profondeur d'un substituant de C ;
  la profondeur vient du coin plein / hachure dont l'extremite fine est C }
Procedure NbVector(C, N: Integer; Var VX, VY, VZ: Real; Var Wd: Boolean);
Var J: Integer; D: Real;
Begin
 VX := At^[N].X - At^[C].X;
 VY := -(At^[N].Y - At^[C].Y);
 D := Sqrt(VX * VX + VY * VY);
 If D < 0.0001 Then D := 0.0001;
 VX := VX / D; VY := VY / D; VZ := 0;
 J := FindBond(C, N);
 If (J >= 0) And (Bd^[J].A = C) Then Begin
  If Bd^[J].Sty = ST_WEDGE Then Begin VZ := 0.8; Wd := True; End
  Else If Bd^[J].Sty = ST_HASH Then Begin VZ := -0.8; Wd := True; End;
 End;
End;

{ Remplit les 4 vecteurs (substituants dans l'ordre donne ; -1 = implicite) ;
  renvoie le determinant d'orientation, 0 si indetermine }
Function Orient4(C: Integer; Const Sl: Array Of Integer; Var HasWedge: Boolean): Real;
Var
 VX, VY, VZ : Array[0..3] Of Real;
 K, Imp, Cnt : Integer;
 SX, SY, SZ, L : Real;
 Wd : Boolean;
Begin
 Orient4 := 0;
 HasWedge := False;
 Imp := -1; Cnt := 0; SX := 0; SY := 0; SZ := 0;
 For K := 0 To 3 Do Begin
  If Sl[K] >= 0 Then Begin
   Wd := False;
   NbVector(C, Sl[K], VX[K], VY[K], VZ[K], Wd);
   If Wd Then HasWedge := True;
   SX := SX + VX[K]; SY := SY + VY[K]; SZ := SZ + VZ[K];
  End
  Else Begin
   If Imp >= 0 Then Exit;
   Imp := K;
  End;
 End;
 If Imp >= 0 Then Begin
  L := Sqrt(SX * SX + SY * SY + SZ * SZ);
  If L < 0.05 Then Exit;
  VX[Imp] := -SX / L; VY[Imp] := -SY / L; VZ[Imp] := -SZ / L;
 End;
 Orient4 := Det3(VX[1] - VX[0], VY[1] - VY[0], VZ[1] - VZ[0],
                 VX[2] - VX[0], VY[2] - VY[0], VZ[2] - VZ[0],
                 VX[3] - VX[0], VY[3] - VY[0], VZ[3] - VZ[0]);
End;

Function ChiralLabel(C: Integer): Char;
Var
 SK, K, J, NB : Integer;
 Low : Boolean;
 Res : Char;
 Br : Array[0..7] Of Integer;
 Sl : Array[0..3] Of Integer;
 D : Real;
 HasW, Wavy : Boolean;
Begin
 ChiralLabel := #0;
 SK := StereoKind(C);
 If SK = 0 Then Exit;
 HasW := False; Wavy := False;
 For K := 0 To AdjN^[C] - 1 Do Begin
  J := AdjB^[C, K];
  If Bd^[J].Sty = ST_WAVY Then Wavy := True;
  If (Bd^[J].A = C) And (Bd^[J].Sty In [ST_WEDGE, ST_HASH]) Then HasW := True;
 End;
 If Wavy Or (Not HasW) Then Exit;
 If SK = 2 Then NB := BuildBranches(C, -1, 4, Br) Else NB := BuildBranches(C, -1, 0, Br);
 If NB <> 4 Then Exit;
 If Not RankBranches(4, Br) Then Exit;
 { ordre decroissant : a > b > c > d ; Sl[3] = le plus faible }
 For K := 0 To 3 Do Sl[K] := Cp^[Br[3 - K]].A;
 D := Orient4(C, Sl, HasW);
 If Abs(D) < 0.02 Then Exit;
 { minuscule (pseudo-asymetrie) si une paire a ete departagee par 4c ou 5 }
 Low := False;
 For K := 0 To 2 Do
  If (CmpNodes(Br[K], Br[K + 1]) <> 0) And (CmpRule >= 5) And Enantiomorphic(Br[K], Br[K + 1]) Then Low := True;
 If D > 0 Then Res := 'R' Else Res := 'S';
 If Low Then Res := Chr(Ord(Res) + 32);
 ChiralLabel := Res;
End;

{ Memorise, pour un centre que les regles 1 a 3 ne departagent pas, la paire
  de ligands equivalents et l'etiquette obtenue si le premier l'emporte }
Procedure TieInfo(C: Integer);
Var
 SK, K, J, NB, I, Cnt, P : Integer;
 Br : Array[0..7] Of Integer;
 Sl : Array[0..3] Of Integer;
 D : Real;
 HasW, Wavy : Boolean;
Begin
 TieA[C] := -1; TieB[C] := -1;
 SK := StereoKind(C);
 If SK = 0 Then Exit;
 HasW := False; Wavy := False;
 For K := 0 To AdjN^[C] - 1 Do Begin
  J := AdjB^[C, K];
  If Bd^[J].Sty = ST_WAVY Then Wavy := True;
  If (Bd^[J].A = C) And (Bd^[J].Sty In [ST_WEDGE, ST_HASH]) Then HasW := True;
 End;
 If Wavy Or (Not HasW) Then Exit;
 If SK = 2 Then NB := BuildBranches(C, -1, 4, Br) Else NB := BuildBranches(C, -1, 0, Br);
 If NB <> 4 Then Exit;
 If RankBranches(4, Br) Then Exit;
 Cnt := 0; P := -1;
 For I := 0 To 2 Do
  If CmpNodes(Br[I], Br[I + 1]) = 0 Then Begin Inc(Cnt); P := I; End;
 If Cnt <> 1 Then Exit;
 If (Cp^[Br[P]].A < 0) Or (Cp^[Br[P + 1]].A < 0) Then Exit;
 For K := 0 To 3 Do Sl[K] := Cp^[Br[3 - K]].A;
 D := Orient4(C, Sl, HasW);
 If Abs(D) < 0.02 Then Exit;
 TieA[C] := Cp^[Br[P]].A; TieB[C] := Cp^[Br[P + 1]].A;
 If D > 0 Then TieLab[C] := 'R' Else TieLab[C] := 'S';
End;

{ --------------------------------------------------------------------- }
{ Liaisons doubles (E/Z)                                                 }
{ --------------------------------------------------------------------- }

{ Cote du point (X,Y) par rapport a l'axe A->B : +1, -1 ou 0 }
Function SideOf(A, B: Integer; X, Y: Real): Integer;
Var CrossV: Real;
Begin
 CrossV := (At^[B].X - At^[A].X) * (Y - At^[A].Y) - (At^[B].Y - At^[A].Y) * (X - At^[A].X);
 If CrossV > 0.5 Then SideOf := 1
 Else If CrossV < -0.5 Then SideOf := -1
 Else SideOf := 0;
End;

{ Cote du substituant prioritaire de l'extremite E (partenaire P) }
Function HighSide(E, P, AxA, AxB: Integer; Var OK: Boolean): Integer;
Var
 NB, K, S, Other : Integer;
 Br : Array[0..7] Of Integer;
Begin
 HighSide := 0; OK := False;
 If (At^[E].Z <> 6) And (Inf^[E].Deg = 2) Then NB := BuildBranches(E, P, 2, Br) Else NB := BuildBranches(E, P, 0, Br);
 If NB <> 2 Then Exit;
 If Not RankBranches(2, Br) Then Exit;
 If Cp^[Br[0]].A >= 0 Then
  S := SideOf(AxA, AxB, At^[Cp^[Br[0]].A].X, At^[Cp^[Br[0]].A].Y)
 Else Begin
  Other := Cp^[Br[1]].A;
  If Other < 0 Then Exit;
  S := -SideOf(AxA, AxB, At^[Other].X, At^[Other].Y);
 End;
 If S = 0 Then Exit;
 HighSide := S; OK := True;
End;

Function EndOK(E, P: Integer): Boolean;
Var K, J, N2 : Integer;
Begin
 EndOK := False;
 If (At^[E].Lbl <> '') Or (At^[E].Rad > 0) Then Exit;
 If Not (At^[E].Z In [6, 7]) Then Exit;
 N2 := 0;
 For K := 0 To AdjN^[E] - 1 Do Begin
  J := AdjB^[E, K];
  If Bd^[J].Order > 1 Then Inc(N2);
  If Bd^[J].Sty = ST_WAVY Then Exit;
 End;
 If N2 <> 1 Then Exit;
 If At^[E].Z = 6 Then Begin
  If (At^[E].Chg <> 0) Or (Inf^[E].Deg - 1 + Inf^[E].H <> 2) Then Exit;
 End
 Else Begin
  If (At^[E].Chg <> 0) Or (Inf^[E].Deg <> 2) Or (Inf^[E].H <> 0) Then Exit;
 End;
 EndOK := True;
End;

{ Azote d'un azoxy : N+ portant un O- terminal }
Function AzoxyEnd(E, P: Integer): Boolean;
Var K, J, NO : Integer;
Begin
 AzoxyEnd := False;
 If (At^[E].Z <> 7) Or (At^[E].Chg <> 1) Or (At^[E].Lbl <> '') Then Exit;
 If (Inf^[E].Deg <> 3) Or (Inf^[E].H <> 0) Then Exit;
 NO := 0;
 For K := 0 To AdjN^[E] - 1 Do Begin
  J := Adj^[E, K];
  If (J <> P) And (At^[J].Z = 8) And (At^[J].Chg = -1) And (Inf^[J].Deg = 1) Then Inc(NO);
 End;
 AzoxyEnd := NO = 1;
End;

{ Extremite d'une liaison double stereogene au sens CIP : C, N, azoxy, P, As }
Function EndOKCip(E, P: Integer): Boolean;
Var K, J, N2 : Integer;
Begin
 EndOKCip := True;
 If EndOK(E, P) Or AzoxyEnd(E, P) Then Exit;
 EndOKCip := False;
 If (At^[E].Lbl <> '') Or (At^[E].Rad > 0) Or (At^[E].Chg <> 0) Then Exit;
 If Not (At^[E].Z In [15, 33]) Then Exit;
 If (Inf^[E].Deg <> 2) Or (Inf^[E].H <> 0) Then Exit;
 N2 := 0;
 For K := 0 To AdjN^[E] - 1 Do Begin
  J := AdjB^[E, K];
  If Bd^[J].Order > 1 Then Inc(N2);
  If Bd^[J].Sty = ST_WAVY Then Exit;
 End;
 EndOKCip := N2 = 1;
End;

Function DoubleBondLabel(J: Integer): Char;
Var A, B, R, SA, SB : Integer; OK1, OK2 : Boolean;
Begin
 DoubleBondLabel := #0;
 If (Bd^[J].Order <> 2) Or (Bd^[J].Sty = ST_WAVY) Or (Bd^[J].DPos = 3) Then Exit;
 A := Bd^[J].A; B := Bd^[J].B;
 If Not (EndOKCip(A, B) And EndOKCip(B, A)) Then Exit;
 R := RingOfBond(A, B);
 If (R >= 0) And (RingN[R] < 8) Then Exit;
 SA := HighSide(A, B, A, B, OK1);
 SB := HighSide(B, A, A, B, OK2);
 If Not (OK1 And OK2) Then Exit;
 If SA = SB Then DoubleBondLabel := 'Z' Else DoubleBondLabel := 'E';
End;

{ --------------------------------------------------------------------- }
{ Calcul global (mis en cache selon la version du document)             }
{ --------------------------------------------------------------------- }

Procedure ComputeStereo;
Var I, J, Iter : Integer; Ch : Boolean; Lab : Char;
Begin
 InitStereo;
 UpdateInfo;
 BuildAdj;
 For I := 0 To NAt - 1 Do Begin StC^[I] := #0; TieA[I] := -1; TieB[I] := -1; End;
 For J := 0 To NBd - 1 Do EzC^[J] := #0;
 { passe 1 : regles 1 et 2 pour E/Z, puis regles 1 a 3 pour les centres }
 CpRuleMax := 2;
 For J := 0 To NBd - 1 Do EzC^[J] := DoubleBondLabel(J);
 CpRuleMax := 3;
 For I := 0 To NAt - 1 Do StC^[I] := ChiralLabel(I);
 { passe 2 : regles 4 et 5 avec les descripteurs deja connus }
 CpRuleMax := 3;
 For I := 0 To NAt - 1 Do If StC^[I] = #0 Then TieInfo(I);
 CpRuleMax := 6;
 For Iter := 1 To 5 Do Begin
  Ch := False;
  For I := 0 To NAt - 1 Do
   If (StC^[I] = #0) And (StereoKind(I) > 0) Then Begin
    Lab := ChiralLabel(I);
    If Lab <> #0 Then Begin StC^[I] := Lab; Ch := True; End;
   End;
  For J := 0 To NBd - 1 Do
   If (EzC^[J] = #0) And (Bd^[J].Order = 2) Then Begin
    Lab := DoubleBondLabel(J);
    If Lab <> #0 Then Begin EzC^[J] := Lab; Ch := True; End;
   End;
  If Not Ch Then Break;
 End;
 CpRuleMax := 2;
 StVer := DocVer;
 StNA := NAt; StNB := NBd;
End;

Procedure EnsureStereo;
Begin
 If (StVer <> DocVer) Or (StNA <> NAt) Or (StNB <> NBd) Or (Not CpReady) Then ComputeStereo;
End;

{ --------------------------------------------------------------------- }
{ SMILES : ecriture de @ / @@ et de / \                                  }
{ --------------------------------------------------------------------- }

{ Etiquette de chiralite (1 = @, 2 = @@, 0 = aucune) de l'atome I dont les
  Ns voisins sont ecrits dans l'ordre Sl (-1 = H implicite) }
Function SmChiralOf(I, Ns: Integer; HasFrom: Boolean; Const Sl: Array Of Integer): Integer;
Var
 S4 : Array[0..3] Of Integer;
 SK, K, J, T : Integer;
 D : Real;
 HW : Boolean;
Begin
 SmChiralOf := 0;
 SK := StereoKind(I);
 If SK = 0 Then Exit;
 If Ns = 4 Then Begin
  For K := 0 To 3 Do S4[K] := Sl[K];
 End
 Else If (Ns = 3) And (SK = 2) Then Begin
  If HasFrom Then T := 1 Else T := 0;
  J := 0;
  For K := 0 To 3 Do
   If K = T Then S4[K] := -1
   Else Begin S4[K] := Sl[J]; Inc(J); End;
 End
 Else Exit;
 For K := 0 To 3 Do
  If S4[K] >= 0 Then Begin
   If SmVis[S4[K]] = 2 Then Exit;
   J := FindBond(I, S4[K]);
   If (J >= 0) And (Bd^[J].Sty = ST_WAVY) Then Exit;
  End;
 D := Orient4(I, S4, HW);
 If (Not HW) Or (Abs(D) < 0.02) Then Exit;
 If D < 0 Then SmChiralOf := 1 Else SmChiralOf := 2;
End;

{ Symbole / ou \ de la liaison JJ entre E et X pour un cote vertical V de X }
Function SmSymFor(E, X, V: Integer): Char;
Var Up: Boolean;
Begin
 If SmPar[X] = E Then Up := V > 0     { E ecrit avant X : X au-dessus }
 Else Up := V < 0;                    { X ecrit avant E : E au-dessus de X }
 If Up Then SmSymFor := '/' Else SmSymFor := '\';
End;

Function SmVertOf(E, X: Integer; Sym: Char): Integer;
Begin
 If SmPar[X] = E Then Begin
  If Sym = '/' Then SmVertOf := 1 Else SmVertOf := -1;
 End
 Else Begin
  If Sym = '/' Then SmVertOf := -1 Else SmVertOf := 1;
 End;
End;

{ Choisit le substituant porteur du symbole pour l'extremite E }
Function SmPickSub(E, P: Integer; Var JJ: Integer): Integer;
Var K, J, M, Best, Sc, BestSc : Integer;
Begin
 Best := -1; JJ := -1; BestSc := -1;
 For K := 0 To AdjN^[E] - 1 Do Begin
  M := Adj^[E, K]; J := AdjB^[E, K];
  If (M = P) Or (Bd^[J].Order <> 1) Or (SmBK[J] <> 1) Or (SmVis[M] = 2) Then Continue;
  { de preference une liaison deja marquee ou menant a une autre liaison double }
  Sc := 0;
  If SmSym[J] <> #0 Then Inc(Sc, 2);
  If SmEnd[M] <> 0 Then Inc(Sc);
  If Sc > BestSc Then Begin Best := M; JJ := J; BestSc := Sc; End;
 End;
 SmPickSub := Best;
End;

Procedure SmStereoPrepare;
Var
 J, A, B, W, S2, XA, XB, JA, JB, VA, VB, T : Integer;
 Cis : Boolean;
Begin
 ComputeStereo;
 For J := 0 To NAt - 1 Do SmEnd[J] := 0;
 For J := 0 To NBd - 1 Do
  If EzC^[J] <> #0 Then Begin SmEnd[Bd^[J].A] := 1; SmEnd[Bd^[J].B] := 1; End;
 For J := 0 To NBd - 1 Do Begin
  If (EzC^[J] = #0) Or (SmBK[J] <> 1) Then Continue;
  A := Bd^[J].A; B := Bd^[J].B;
  If (SmVis[A] = 2) Or (SmVis[B] = 2) Then Continue;
  If SmPar[B] = A Then W := A Else If SmPar[A] = B Then W := B Else Continue;
  If W = A Then S2 := B Else S2 := A;
  XA := SmPickSub(W, S2, JA);
  XB := SmPickSub(S2, W, JB);
  If (XA < 0) Or (XB < 0) Then Continue;
  VA := -SideOf(W, S2, At^[XA].X, At^[XA].Y);
  VB := -SideOf(W, S2, At^[XB].X, At^[XB].Y);
  If (VA = 0) Or (VB = 0) Then Continue;
  Cis := VA = VB;
  If (SmSym[JA] <> #0) And (SmSym[JB] <> #0) Then Continue;
  If SmSym[JA] <> #0 Then Begin
   VA := SmVertOf(W, XA, SmSym[JA]);
   If Cis Then VB := VA Else VB := -VA;
  End
  Else If SmSym[JB] <> #0 Then Begin
   VB := SmVertOf(S2, XB, SmSym[JB]);
   If Cis Then VA := VB Else VA := -VB;
  End;
  SmSym[JA] := SmSymFor(W, XA, VA);
  SmSym[JB] := SmSymFor(S2, XB, VB);
 End;
End;

{ --------------------------------------------------------------------- }
{ SMILES : chiralite @ / @@ -> coins pleins / hachures                  }
{ --------------------------------------------------------------------- }

{ Cote vertical (+1 / -1) d'un substituant lie a l'atome E par la liaison JJ
  d'apres les symboles / et \ du SMILES ; 0 si la liaison n'a pas de symbole }
Function SmVertical(E, JJ: Integer): Integer;
Var M: Integer;
Begin
 If SmDir[JJ] = 0 Then Begin SmVertical := 0; Exit; End;
 If SmDir[JJ] = 1 Then M := 1 Else M := -1;
 If Bd^[JJ].A = E Then SmVertical := M Else SmVertical := -M;
End;

{ Premier substituant (autre que le partenaire) portant un symbole / ou \ }
Function SmDirNeighbor(E, J: Integer; Var Nb, Vert: Integer): Boolean;
Var K, JJ: Integer;
Begin
 SmDirNeighbor := False;
 For K := 0 To AdjN^[E] - 1 Do Begin
  JJ := AdjB^[E, K];
  If JJ = J Then Continue;
  If SmDir[JJ] <> 0 Then Begin
   Nb := Adj^[E, K]; Vert := SmVertical(E, JJ);
   SmDirNeighbor := True; Exit;
  End;
 End;
End;

{ Symetrie par rapport a l'axe A-B du fragment cote B de la liaison J ;
  faux si la liaison est dans un cycle (rien n'est modifie) }
Function MirrorBSide(J: Integer): Boolean;
Var
 A, B, I, Head, Tail, Cur, K, Nx : Integer;
 DX, DY, DL, PX, PY, T : Real;
 Ring : Boolean;
Begin
 MirrorBSide := False;
 A := Bd^[J].A; B := Bd^[J].B;
 For I := 0 To NAt - 1 Do Tmp1^[I] := 0;
 Tmp1^[B] := 1; Tmp2^[0] := B; Head := 0; Tail := 1; Ring := False;
 While Head < Tail Do Begin
  Cur := Tmp2^[Head]; Inc(Head);
  For K := 0 To AdjN^[Cur] - 1 Do Begin
   If AdjB^[Cur, K] = J Then Continue;
   Nx := Adj^[Cur, K];
   If Nx = A Then Ring := True;
   If Tmp1^[Nx] = 0 Then Begin Tmp1^[Nx] := 1; Tmp2^[Tail] := Nx; Inc(Tail); End;
  End;
 End;
 If Ring Then Exit;
 DX := At^[B].X - At^[A].X; DY := At^[B].Y - At^[A].Y;
 DL := Sqrt(DX * DX + DY * DY);
 If DL < 0.001 Then Exit;
 DX := DX / DL; DY := DY / DL;
 For I := 0 To NAt - 1 Do
  If Tmp1^[I] <> 0 Then Begin
   PX := At^[I].X - At^[A].X; PY := At^[I].Y - At^[A].Y;
   T := PX * DX + PY * DY;
   At^[I].X := At^[A].X + 2 * T * DX - PX;
   At^[I].Y := At^[A].Y + 2 * T * DY - PY;
  End;
 MirrorBSide := True;
End;

{ --- grands cycles : mise en page imposant les doubles liaisons E / Z --- }

Var
 RqJ : Array[0..MAX_BONDS - 1] Of Byte;   { 1 = cis, 2 = trans (voisins de cycle) }

Function InRingR(R, A: Integer): Boolean;
Var K: Integer;
Begin
 InRingR := True;
 For K := 0 To RingN[R] - 1 Do If RingA[R, K] = A Then Exit;
 InRingR := False;
End;

{ Relation cis (vrai) des voisins de cycle de la liaison J d'apres celle de
  deux substituants XA et XB (un substituant hors cycle est du cote oppose) }
Function RingRelation(J, XA, XB: Integer; Cis: Boolean): Boolean;
Var R: Integer; Res: Boolean;
Begin
 Res := Cis;
 R := RingOfBond(Bd^[J].A, Bd^[J].B);
 If R >= 0 Then Begin
  If Not InRingR(R, XA) Then Res := Not Res;
  If Not InRingR(R, XB) Then Res := Not Res;
 End;
 RingRelation := Res;
End;

{ Resout les angles de virage T (signes S) pour qu'un polygone de pas BL se
  referme ; faux si la resolution echoue }
Function SolveTurns(N: Integer; Const S: Array Of Integer; Beta: Real; Var T: Array Of Real): Boolean;
Var
 P, Q, J, K, It, Tries : Integer;
 Alpha, Dir, Fx, Fy, G, Sc, Sx, Sy, L0, L1, L2, Det : Real;
 Jx, Jy, Dl, DirA : Array[0..MAX_RING_SZ - 1] Of Real;
 M : Array[0..2, 0..3] Of Real;
 Ok : Boolean;
 R2, C2, T2 : Integer;
 Fct, Tmp : Real;
Begin
 SolveTurns := False;
 P := 0;
 For J := 0 To N - 1 Do If S[J] > 0 Then Inc(P);
 Q := N - P;
 If P < 1 Then Exit;
 Alpha := (2 * Pi + Q * Beta) / P;
 If Alpha > 2.4 Then Exit;
 For J := 0 To N - 1 Do If S[J] > 0 Then T[J] := Alpha Else T[J] := -Beta;
 For It := 1 To 300 Do Begin
  Dir := 0; Fx := 0; Fy := 0; G := -2 * Pi;
  For J := 0 To N - 1 Do Begin
   Dir := Dir + T[J]; DirA[J] := Dir; G := G + T[J];
   Fx := Fx + Cos(Dir); Fy := Fy + Sin(Dir);
  End;
  If (Abs(Fx) < 1E-7) And (Abs(Fy) < 1E-7) And (Abs(G) < 1E-7) Then Begin SolveTurns := True; Exit; End;
  Sx := 0; Sy := 0;
  For J := N - 1 Downto 0 Do Begin
   Sx := Sx - Sin(DirA[J]); Sy := Sy + Cos(DirA[J]);
   Jx[J] := Sx; Jy[J] := Sy;
  End;
  For R2 := 0 To 2 Do For C2 := 0 To 3 Do M[R2, C2] := 0;
  For J := 0 To N - 1 Do Begin
   M[0, 0] := M[0, 0] + Jx[J] * Jx[J]; M[0, 1] := M[0, 1] + Jx[J] * Jy[J]; M[0, 2] := M[0, 2] + Jx[J];
   M[1, 1] := M[1, 1] + Jy[J] * Jy[J]; M[1, 2] := M[1, 2] + Jy[J];
   M[2, 2] := M[2, 2] + 1;
  End;
  M[1, 0] := M[0, 1]; M[2, 0] := M[0, 2]; M[2, 1] := M[1, 2];
  M[0, 3] := -Fx; M[1, 3] := -Fy; M[2, 3] := -G;
  { elimination de Gauss }
  Ok := True;
  For K := 0 To 2 Do Begin
   T2 := K;
   For R2 := K + 1 To 2 Do If Abs(M[R2, K]) > Abs(M[T2, K]) Then T2 := R2;
   If Abs(M[T2, K]) < 1E-12 Then Begin Ok := False; Break; End;
   For C2 := 0 To 3 Do Begin Tmp := M[K, C2]; M[K, C2] := M[T2, C2]; M[T2, C2] := Tmp; End;
   For R2 := K + 1 To 2 Do Begin
    Fct := M[R2, K] / M[K, K];
    For C2 := K To 3 Do M[R2, C2] := M[R2, C2] - Fct * M[K, C2];
   End;
  End;
  If Not Ok Then Exit;
  L2 := M[2, 3] / M[2, 2];
  L1 := (M[1, 3] - M[1, 2] * L2) / M[1, 1];
  L0 := (M[0, 3] - M[0, 1] * L1 - M[0, 2] * L2) / M[0, 0];
  For J := 0 To N - 1 Do Dl[J] := Jx[J] * L0 + Jy[J] * L1 + L2;
  Sc := 1;
  For Tries := 1 To 10 Do Begin
   Ok := True;
   For J := 0 To N - 1 Do Begin
    Dir := T[J] + Sc * Dl[J];
    If (S[J] > 0) And (Dir < 0.03) Then Ok := False;
    If (S[J] < 0) And (Dir > -0.03) Then Ok := False;
   End;
   If Ok Then Break;
   Sc := Sc / 2;
  End;
  If Not Ok Then Exit;
  For J := 0 To N - 1 Do T[J] := T[J] + Sc * Dl[J];
 End;
End;

{ Le polygone de sommets (X, Y) est-il simple et sans sommets trop proches ? }
Function PolygonOK(N: Integer; Const X, Y: Array Of Real): Boolean;
Var I, J : Integer;
 D1, D2, D3, D4 : Real;
 Function Orn(AX, AY, BX, BY, CX, CY: Real): Real;
 Begin
  Orn := (BX - AX) * (CY - AY) - (BY - AY) * (CX - AX);
 End;
Begin
 PolygonOK := False;
 For I := 0 To N - 1 Do
  For J := I + 2 To N - 1 Do Begin
   If (I = 0) And (J = N - 1) Then Continue;
   If Dist(X[I], Y[I], X[J], Y[J]) < 0.6 * BOND_LEN Then Exit;
   D1 := Orn(X[I], Y[I], X[(I + 1) Mod N], Y[(I + 1) Mod N], X[J], Y[J]);
   D2 := Orn(X[I], Y[I], X[(I + 1) Mod N], Y[(I + 1) Mod N], X[(J + 1) Mod N], Y[(J + 1) Mod N]);
   D3 := Orn(X[J], Y[J], X[(J + 1) Mod N], Y[(J + 1) Mod N], X[I], Y[I]);
   D4 := Orn(X[J], Y[J], X[(J + 1) Mod N], Y[(J + 1) Mod N], X[(I + 1) Mod N], Y[(I + 1) Mod N]);
   If (D1 * D2 < 0) And (D3 * D4 < 0) Then Exit;
  End;
 PolygonOK := True;
End;

{ Redessine le cycle R pour respecter les relations cis / trans imposees
  (RqJ) ; les fragments portes par les atomes du cycle suivent. }
Procedure FixMacro(R: Integer);
Var
 N, K, J, P, Q, Bi, NFree, BestFree, BestDist, Dd, Sum, Tr, M, Head, Tail, Cur, Nx, I : Integer;
 Rg : Array[0..MAX_RING_SZ - 1] Of Integer;
 Rb : Array[0..MAX_RING_SZ - 1] Of Integer;
 Dflip : Array[0..MAX_RING_SZ - 1] Of Integer;
 Forced : Array[0..MAX_RING_SZ - 1] Of Boolean;
 Sg : Array[0..MAX_RING_SZ - 1] Of Integer;
 T : Array[0..MAX_RING_SZ - 1] Of Real;
 NPX, NPY, OPX, OPY : Array[0..MAX_RING_SZ - 1] Of Real;
 Frag : Array[0..MAX_ATOMS - 1] Of ShortInt;   { numero du cycle + 1 }
 Betas : Array[0..4] Of Real;
 BI2, CI, NCand : Integer;
 Dfix : Array[0..MAX_RING_SZ - 1] Of Integer;
 Cand, CandD, DfL2 : Array[0..MAX_RING_SZ - 1] Of Integer;
 S1, S2, S : Integer;
 Cur2 : Boolean;
 Mismatch, Okk : Boolean;
 CX0, CY0, CX1, CY1, A0, A1, Beta, Ux, Uy, Vx, Vy, L, Rho, CsR, SnR, PX, PY, Ang0, Ang1 : Real;
Begin
 N := RingN[R];
 If (N < 8) Or (N > MAX_RING_SZ) Then Exit;
 For K := 0 To N - 1 Do Rg[K] := RingA[R, K];
 For K := 0 To N - 1 Do Begin
  Rb[K] := FindBond(Rg[K], Rg[(K + 1) Mod N]);
  If Rb[K] < 0 Then Exit;
 End;
 { relations imposees ou courantes pour chaque liaison double du cycle }
 Mismatch := False;
 For K := 0 To N - 1 Do Begin
  Forced[K] := False; Dflip[K] := 0;
  If Bd^[Rb[K]].Order <> 2 Then Continue;
  S1 := SideOf(Rg[K], Rg[(K + 1) Mod N], At^[Rg[(K + N - 1) Mod N]].X, At^[Rg[(K + N - 1) Mod N]].Y);
  S2 := SideOf(Rg[K], Rg[(K + 1) Mod N], At^[Rg[(K + 2) Mod N]].X, At^[Rg[(K + 2) Mod N]].Y);
  Cur2 := S1 = S2;
  If (S1 = 0) Or (S2 = 0) Then Cur2 := True;
  Forced[K] := True;
  If RqJ[Rb[K]] = 1 Then Begin
   If Not Cur2 Then Mismatch := True;
   Dflip[K] := 0;
  End
  Else If RqJ[Rb[K]] = 2 Then Begin
   If Cur2 Then Mismatch := True;
   Dflip[K] := 1;
  End
  Else If Cur2 Then Dflip[K] := 0 Else Dflip[K] := 1;
 End;
 If Not Mismatch Then Exit;
 { fragments portes par les atomes du cycle : disjoints et sans retour au cycle }
 For I := 0 To NAt - 1 Do Frag[I] := 0;
 For K := 0 To N - 1 Do Frag[Rg[K]] := -1;
 For K := 0 To N - 1 Do Begin
  For J := 0 To AdjN^[Rg[K]] - 1 Do Begin
   Nx := Adj^[Rg[K], J];
   If Frag[Nx] <> 0 Then Begin
    If (Frag[Nx] = -1) And ((Nx = Rg[(K + 1) Mod N]) Or (Nx = Rg[(K + N - 1) Mod N])) Then Continue;
    Exit;     { pont ou cycle fusionne }
   End;
   Head := 0; Tail := 1; Tmp2^[0] := Nx; Frag[Nx] := K + 1;
   While Head < Tail Do Begin
    Cur := Tmp2^[Head]; Inc(Head);
    For M := 0 To AdjN^[Cur] - 1 Do Begin
     I := Adj^[Cur, M];
     If I = Rg[K] Then Continue;
     If Frag[I] = -1 Then Exit;
     If (Frag[I] <> 0) And (Frag[I] <> K + 1) Then Exit;
     If Frag[I] = 0 Then Begin Frag[I] := K + 1; Tmp2^[Tail] := I; Inc(Tail); End;
    End;
   End;
  End;
 End;
 { parite des inversions de virage : un cycle ferme en exige un nombre pair ;
   si besoin on ajoute une inversion sur une liaison libre (essais par
   proximite d'une liaison trans) }
 { chaque liaison trans recoit une inversion compensatrice voisine (liaison
   libre) : le virage inverse reste isole, comme un coude du cycle }
 For K := 0 To N - 1 Do Dfix[K] := 0;
 For K := 0 To N - 1 Do
  If Forced[K] And (Dflip[K] = 1) Then Begin
   J := (K + 1) Mod N;
   If (Not Forced[J]) And (Dfix[J] = 0) And (Dfix[(K + N - 1) Mod N] = 0) Then Dfix[J] := 1
   Else Begin
    J := (K + N - 1) Mod N;
    If (Not Forced[J]) And (Dfix[J] = 0) Then Dfix[J] := 1;
   End;
  End;
 For K := 0 To N - 1 Do If Dfix[K] = 1 Then Dflip[K] := 1;
 Sum := 0;
 For K := 0 To N - 1 Do Sum := Sum + Dflip[K];
 NCand := 0;
 If Odd(Sum) Then Begin
  For K := 0 To N - 1 Do
   If Not Forced[K] Then Begin
    Dd := N;
    For J := 0 To N - 1 Do
     If Forced[J] And (Dflip[J] = 1) Then Begin
      Tr := Abs(K - J); If N - Tr < Tr Then Tr := N - Tr;
      If Tr < Dd Then Dd := Tr;
     End;
    Cand[NCand] := K; CandD[NCand] := Dd; Inc(NCand);
   End;
  If NCand = 0 Then Exit;
  For K := 1 To NCand - 1 Do Begin
   J := Cand[K]; Dd := CandD[K]; Tr := K - 1;
   While (Tr >= 0) And (CandD[Tr] > Dd) Do Begin Cand[Tr + 1] := Cand[Tr]; CandD[Tr + 1] := CandD[Tr]; Dec(Tr); End;
   Cand[Tr + 1] := J; CandD[Tr + 1] := Dd;
  End;
 End
 Else Begin Cand[0] := -1; NCand := 1; End;
 Betas[0] := 0.45; Betas[1] := 0.7; Betas[2] := 0.25; Betas[3] := 1.0; Betas[4] := 0.12;
 Okk := False;
 For CI := 0 To NCand - 1 Do Begin
  For K := 0 To N - 1 Do DfL2[K] := Dflip[K];
  If Cand[CI] >= 0 Then DfL2[Cand[CI]] := 1;
  Sg[0] := 1;
  For K := 0 To N - 2 Do If DfL2[K] = 1 Then Sg[K + 1] := -Sg[K] Else Sg[K + 1] := Sg[K];
  P := 0;
  For K := 0 To N - 1 Do If Sg[K] > 0 Then Inc(P);
  Q := N - P;
  If P < Q Then Begin
   For K := 0 To N - 1 Do Sg[K] := -Sg[K];
  End;
  For BI2 := 0 To 4 Do Begin
   Beta := Betas[BI2];
   If Not SolveTurns(N, Sg, Beta, T) Then Continue;
   L := 0;
   NPX[0] := 0; NPY[0] := 0;
   For K := 0 To N - 2 Do Begin
    L := L + T[K];
    NPX[K + 1] := NPX[K] + BOND_LEN * Cos(L);
    NPY[K + 1] := NPY[K] + BOND_LEN * Sin(L);
   End;
   If PolygonOK(N, NPX, NPY) Then Begin Okk := True; Break; End;
  End;
  If Okk Then Break;
 End;
 If Not Okk Then Exit;
 { centre et orientation de l'ancien et du nouveau cycle }
 CX0 := 0; CY0 := 0; CX1 := 0; CY1 := 0; A0 := 0; A1 := 0;
 For K := 0 To N - 1 Do Begin
  CX0 := CX0 + At^[Rg[K]].X; CY0 := CY0 + At^[Rg[K]].Y;
  CX1 := CX1 + NPX[K]; CY1 := CY1 + NPY[K];
  J := (K + 1) Mod N;
  A0 := A0 + At^[Rg[K]].X * At^[Rg[J]].Y - At^[Rg[J]].X * At^[Rg[K]].Y;
  A1 := A1 + NPX[K] * NPY[J] - NPX[J] * NPY[K];
 End;
 CX0 := CX0 / N; CY0 := CY0 / N; CX1 := CX1 / N; CY1 := CY1 / N;
 For K := 0 To N - 1 Do Begin
  NPX[K] := NPX[K] - CX1; NPY[K] := NPY[K] - CY1;
  If (A0 > 0) <> (A1 > 0) Then NPX[K] := -NPX[K];
  NPX[K] := NPX[K] + CX0; NPY[K] := NPY[K] + CY0;
 End;
 { fragments : meme sortie du cycle (direction opposee a la bissectrice) }
 For K := 0 To N - 1 Do Begin
  OPX[K] := At^[Rg[K]].X; OPY[K] := At^[Rg[K]].Y;
 End;
 For K := 0 To N - 1 Do Begin
  J := (K + 1) Mod N; I := (K + N - 1) Mod N;
  Ux := OPX[I] - OPX[K]; Uy := OPY[I] - OPY[K]; L := Sqrt(Ux * Ux + Uy * Uy); If L < 0.001 Then L := 1;
  Ux := Ux / L; Uy := Uy / L;
  Vx := OPX[J] - OPX[K]; Vy := OPY[J] - OPY[K]; L := Sqrt(Vx * Vx + Vy * Vy); If L < 0.001 Then L := 1;
  Vx := Vx / L; Vy := Vy / L;
  Ang0 := Atan2(-(Uy + Vy), -(Ux + Vx));
  Ux := NPX[I] - NPX[K]; Uy := NPY[I] - NPY[K]; L := Sqrt(Ux * Ux + Uy * Uy); If L < 0.001 Then L := 1;
  Ux := Ux / L; Uy := Uy / L;
  Vx := NPX[J] - NPX[K]; Vy := NPY[J] - NPY[K]; L := Sqrt(Vx * Vx + Vy * Vy); If L < 0.001 Then L := 1;
  Vx := Vx / L; Vy := Vy / L;
  Ang1 := Atan2(-(Uy + Vy), -(Ux + Vx));
  Rho := Ang1 - Ang0;
  CsR := Cos(Rho); SnR := Sin(Rho);
  For I := 0 To NAt - 1 Do
   If Frag[I] = K + 1 Then Begin
    PX := At^[I].X - OPX[K]; PY := At^[I].Y - OPY[K];
    At^[I].X := NPX[K] + CsR * PX - SnR * PY;
    At^[I].Y := NPY[K] + SnR * PX + CsR * PY;
   End;
 End;
 For K := 0 To N - 1 Do Begin At^[Rg[K]].X := NPX[K]; At^[Rg[K]].Y := NPY[K]; End;
End;

Procedure FixMacroRings;
Var R, K, J : Integer; Any : Boolean;
Begin
 EnsureRings;
 For R := 0 To NRings - 1 Do Begin
  If RingN[R] < 8 Then Continue;
  Any := False;
  For K := 0 To RingN[R] - 1 Do Begin
   J := FindBond(RingA[R, K], RingA[R, (K + 1) Mod RingN[R]]);
   If (J >= 0) And (RqJ[J] <> 0) Then Any := True;
  End;
  If Any Then FixMacro(R);
 End;
 For J := 0 To NBd - 1 Do RqJ[J] := 0;
End;

{ Retourne le fragment cote B des liaisons doubles dont la geometrie
  cis/trans ne correspond pas aux symboles / et \ du SMILES }
Procedure ApplySmilesDoubleBonds(F, L: Integer);
Var J, A, B, XA, XB, VA, VB, S1, S2 : Integer;
Begin
 BuildAdj;
 For J := 0 To NBd - 1 Do Begin
  If Bd^[J].Order <> 2 Then Continue;
  A := Bd^[J].A; B := Bd^[J].B;
  If (A < F) Or (A > L) Or (B < F) Or (B > L) Then Continue;
  If Not SmDirNeighbor(A, J, XA, VA) Then Continue;
  If Not SmDirNeighbor(B, J, XB, VB) Then Continue;
  S1 := SideOf(A, B, At^[XA].X, At^[XA].Y);
  S2 := SideOf(A, B, At^[XB].X, At^[XB].Y);
  If (S1 = 0) Or (S2 = 0) Then Continue;
  { cis (memes cotes) si les deux substituants sont du meme cote vertical }
  If ((S1 = S2) = (VA = VB)) Then Continue;
  If Not MirrorBSide(J) Then
   If RingRelation(J, XA, XB, VA = VB) Then RqJ[J] := 1 Else RqJ[J] := 2;
 End;
 FixMacroRings;
End;

{ Pose un coin plein ou hachure sur une liaison de K (extremite fine en K)
  pour que le determinant d'orientation des voisins Sl ait le signe voulu
  (WantNeg : negatif). Prefer = liaison a essayer en premier (-1 : aucune). }
Function SetChirality(K: Integer; Const Sl: Array Of Integer; WantNeg: Boolean; Prefer: Integer): Boolean;
Var
 I, J, Pass, Best, BestScore, Sc, Mate, T : Integer;
 Tried : Array[0..7] Of Boolean;
 D : Real;
 HasW : Boolean;
Begin
 SetChirality := False;
 For I := 0 To AdjN^[K] - 1 Do Begin
  J := AdjB^[K, I];
  If (Bd^[J].A = K) And (Bd^[J].Sty In [ST_WEDGE, ST_HASH]) Then Bd^[J].Sty := ST_NORMAL;
  Tried[I] := False;
 End;
 For Pass := 1 To AdjN^[K] Do Begin
  { choisit la liaison : de preference celle demandee, hors cycle, terminale }
  Best := -1; BestScore := -1;
  For I := 0 To AdjN^[K] - 1 Do Begin
   If Tried[I] Then Continue;
   J := AdjB^[K, I]; Mate := Adj^[K, I];
   If (Bd^[J].Order <> 1) Or (Bd^[J].Sty <> ST_NORMAL) Then Continue;
   Sc := 1;
   If J = Prefer Then Inc(Sc, 20);
   If RingOfBond(K, Mate) < 0 Then Inc(Sc, 4);
   If Inf^[Mate].Deg = 1 Then Inc(Sc, 2);
   If StereoKind(Mate) = 0 Then Inc(Sc, 1);
   If Sc > BestScore Then Begin BestScore := Sc; Best := I; End;
  End;
  If Best < 0 Then Exit;
  Tried[Best] := True;
  J := AdjB^[K, Best];
  If Bd^[J].B = K Then Begin
   T := Bd^[J].A; Bd^[J].A := Bd^[J].B; Bd^[J].B := T;
  End;
  Bd^[J].Sty := ST_WEDGE;
  D := Orient4(K, Sl, HasW);
  If Abs(D) < 0.02 Then Begin Bd^[J].Sty := ST_NORMAL; Continue; End;
  If (D < 0) <> WantNeg Then Bd^[J].Sty := ST_HASH;
  SetChirality := True;
  Exit;
 End;
End;

Procedure ApplySmilesChirality(F, L: Integer);
Var
 K, I, J, N, T : Integer;
 Sl : Array[0..3] Of Integer;
 Ok : Boolean;
Begin
 InitStereo;
 UpdateInfo;
 BuildAdj;
 ApplySmilesDoubleBonds(F, L);
 For K := F To L Do Begin
  If SmCh[K] = 0 Then Continue;
  N := SmNn[K];
  If (N < 3) Or (N > 4) Then Continue;
  If N = 3 Then Begin
   { le doublet libre prend la place juste apres l'atome source }
   If (At^[K].Z <> 15) And (At^[K].Z <> 16) Then Continue;
   If SmFrm[K] <> 0 Then T := 1 Else T := 0;
   J := 0;
   For I := 0 To 3 Do
    If I = T Then Sl[I] := -1
    Else Begin Sl[I] := SmNb^[K, J]; Inc(J); End;
  End
  Else For I := 0 To 3 Do Sl[I] := SmNb^[K, I];
  { une fermeture de cycle non resolue (< -1) rend la liste inutilisable }
  Ok := True;
  For I := 0 To 3 Do If Sl[I] < -1 Then Ok := False;
  If Not Ok Then Continue;
  { '@' (sens anti-horaire vu du premier voisin) <=> determinant negatif }
  If SetChirality(K, Sl, SmCh[K] = 1, -1) Then;
 End;
 Touch;
End;

{ --------------------------------------------------------------------- }
{ Conservation de la stereochimie lors d'une remise en page             }
{ --------------------------------------------------------------------- }

Const CAP_MAX = 200;

Var
 CapN, CapDN : Integer;
 CapAt   : Array[0..CAP_MAX - 1] Of Integer;
 CapSl   : Array[0..CAP_MAX - 1, 0..3] Of Integer;
 CapNeg  : Array[0..CAP_MAX - 1] Of Boolean;
 CapPref : Array[0..CAP_MAX - 1] Of Integer;
 CapDb   : Array[0..CAP_MAX - 1] Of Integer;
 CapXA, CapXB : Array[0..CAP_MAX - 1] Of Integer;
 CapCis  : Array[0..CAP_MAX - 1] Of Boolean;

{ Memorise la stereochimie (centres avec coin, liaisons doubles) des atomes
  marques (Mark bit 1) avant une mise en page }
Procedure CaptureStereo;
Var
 K, I, J, M, NS, R : Integer;
 D : Real;
 HW, Wavy : Boolean;
 S1, S2, XA, XB, A, B : Integer;
Begin
 InitStereo;
 UpdateInfo;
 BuildAdj;
 CapN := 0; CapDN := 0;
 For K := 0 To NAt - 1 Do Begin
  If ((At^[K].Mark And 1) = 0) Or (CapN >= CAP_MAX) Then Continue;
  If StereoKind(K) = 0 Then Continue;
  Wavy := False; M := -1;
  For I := 0 To AdjN^[K] - 1 Do Begin
   J := AdjB^[K, I];
   If Bd^[J].Sty = ST_WAVY Then Wavy := True;
   If (M < 0) And (Bd^[J].A = K) And (Bd^[J].Sty In [ST_WEDGE, ST_HASH]) Then M := J;
  End;
  If Wavy Or (M < 0) Then Continue;
  NS := 0;
  For I := 0 To AdjN^[K] - 1 Do If NS < 4 Then Begin CapSl[CapN, NS] := Adj^[K, I]; Inc(NS); End;
  While NS < 4 Do Begin CapSl[CapN, NS] := -1; Inc(NS); End;
  D := Orient4(K, CapSl[CapN], HW);
  If (Not HW) Or (Abs(D) < 0.02) Then Continue;
  CapAt[CapN] := K; CapNeg[CapN] := D < 0; CapPref[CapN] := M;
  Inc(CapN);
 End;
 For J := 0 To NBd - 1 Do Begin
  If (Bd^[J].Order <> 2) Or (CapDN >= CAP_MAX) Then Continue;
  A := Bd^[J].A; B := Bd^[J].B;
  If ((At^[A].Mark And 1) = 0) Or ((At^[B].Mark And 1) = 0) Then Continue;
  If (Bd^[J].Sty = ST_WAVY) Or (Bd^[J].DPos = 3) Then Continue;
  If Not (EndOKCip(A, B) And EndOKCip(B, A)) Then Continue;
  R := RingOfBond(A, B);
  If (R >= 0) And (RingN[R] < 8) Then Continue;
  XA := -1; XB := -1;
  For I := 0 To AdjN^[A] - 1 Do If (XA < 0) And (Adj^[A, I] <> B) Then XA := Adj^[A, I];
  For I := 0 To AdjN^[B] - 1 Do If (XB < 0) And (Adj^[B, I] <> A) Then XB := Adj^[B, I];
  If (XA < 0) Or (XB < 0) Then Continue;
  S1 := SideOf(A, B, At^[XA].X, At^[XA].Y);
  S2 := SideOf(A, B, At^[XB].X, At^[XB].Y);
  If (S1 = 0) Or (S2 = 0) Then Continue;
  CapDb[CapDN] := J; CapXA[CapDN] := XA; CapXB[CapDN] := XB; CapCis[CapDN] := S1 = S2;
  Inc(CapDN);
 End;
End;

{ Retablit la stereochimie memorisee apres la mise en page }
Procedure RestoreStereo;
Var K, J, A, B, S1, S2 : Integer;
Begin
 BuildAdj;
 UpdateInfo;
 For K := 0 To CapDN - 1 Do Begin
  J := CapDb[K]; A := Bd^[J].A; B := Bd^[J].B;
  S1 := SideOf(A, B, At^[CapXA[K]].X, At^[CapXA[K]].Y);
  S2 := SideOf(A, B, At^[CapXB[K]].X, At^[CapXB[K]].Y);
  If (S1 = 0) Or (S2 = 0) Then Continue;
  If (S1 = S2) <> CapCis[K] Then
   If Not MirrorBSide(J) Then
    If RingRelation(J, CapXA[K], CapXB[K], CapCis[K]) Then RqJ[J] := 1 Else RqJ[J] := 2;
 End;
 FixMacroRings;
 For K := 0 To CapN - 1 Do
  If SetChirality(CapAt[K], CapSl[K], CapNeg[K], CapPref[K]) Then;
 Touch;
End;
{ --------------------------------------------------------------------- }
{ InChI standard (formule, connectivite, hydrogenes, charge, stereochimie) }
{ Sans isotopes. Une seule molecule connexe.                            }
{ --------------------------------------------------------------------- }

Const
 IN_MAX    = 200;
 IN_DEPTH  = 70;
 IN_CTMAX  = 1500;
 IN_LF     = 300;
 IN_SE     = 100;

Type
 TIRk = Array[0..IN_MAX - 1] Of Integer;
 PIRk = ^TIRk;
 TICt = Array[0..IN_CTMAX - 1] Of Integer;
 PICt = ^TICt;
 TSePar = Array[0..IN_LF - 1, 0..IN_SE - 1] Of Byte;

Var
 InMsg     : String;
 InBuf     : ^TBuf;
 InLen     : Integer;
 IGone     : Array[0..MAX_ATOMS - 1] Of Boolean;
 IHs, IChg : Array[0..MAX_ATOMS - 1] Of Integer;
 IBo       : Array[0..MAX_BONDS - 1] Of Byte;
 BAro      : Array[0..MAX_BONDS - 1] Of Boolean;
 TgPar     : Array[0..MAX_ATOMS - 1] Of Integer;
 TgIn      : Array[0..MAX_ATOMS - 1] Of Boolean;
 TgPath    : Array[0..8] Of Integer;
 TgDonor   : Integer;
 ICN       : Integer;
 ICDoc     : TIRk;
 ICPos     : Array[0..MAX_ATOMS - 1] Of Integer;
 ICEl      : TIRk;
 ICNb      : Array[0..IN_MAX - 1, 0..7] Of Integer;
 ICNbN     : TIRk;
 ICH2      : TIRk;
 IBestR    : TIRk;
 ICtBest, ICtCur   : PICt;
 IHBest, IHCur     : PICt;
 ICtBestN, ICtCurN, IHBestN, IHCurN : Integer;
 IHave     : Boolean;
 INodes    : LongInt;
 Lv, LvM   : Array[0..IN_DEPTH] Of PIRk;
 ICnt      : Array[0..IN_MAX] Of Integer;
 { serialisation }
 SAdj      : Array[1..IN_MAX, 0..7] Of Integer;
 SDeg      : Array[1..IN_MAX] Of Integer;
 SIdx, SSize : Array[1..IN_MAX] Of Integer;
 SCh       : Array[1..IN_MAX, 0..7] Of Integer;
 SChN      : Array[1..IN_MAX] Of Integer;
 SCl       : Array[1..IN_MAX, 0..7] Of Integer;
 SClN      : Array[1..IN_MAX] Of Integer;
 SCnt      : Integer;
 { stereochimie }
 ILeaves   : Array[0..IN_LF - 1] Of PIRk;
 INLeaf    : Integer;
 IStOn     : Boolean;
 SeN       : Integer;
 SeKind    : Array[0..IN_SE - 1] Of Byte;     { 1 = centre, 2 = liaison double }
 SeA, SeB  : Array[0..IN_SE - 1] Of Integer;  { centre (SeA) ou extremites }
 SeDef     : Array[0..IN_SE - 1] Of Boolean;  { defini par la geometrie }
 SeOn      : Array[0..IN_SE - 1] Of Boolean;  { stereogene }
 SePar     : ^TSePar;
 OutB      : Array[0..IN_SE - 1, 0..2] Of Integer;
 OutBN     : Integer;
 OutT      : Array[0..IN_SE - 1, 0..1] Of Integer;
 OutTN     : Integer;
 InChiral  : Boolean;
 InInvert  : Boolean;
 InStHas   : Boolean;
 SeSaveN, SeSaveT : Integer;
 SeSaveB   : Array[0..IN_SE - 1, 0..2] Of Integer;
 SeSaveTT  : Array[0..IN_SE - 1, 0..1] Of Integer;

Procedure InAdd(Const S: String);
Var I: Integer;
Begin
 For I := 1 To Length(S) Do
  If InLen < 4095 Then Begin InBuf^[InLen] := S[I]; Inc(InLen); End;
End;

Function InStr: String;
Var I, N: Integer; S: String;
Begin
 N := InLen; If N > 255 Then N := 255;
 S := '';
 For I := 0 To N - 1 Do S := S + InBuf^[I];
 InStr := S;
End;

Function IsEndp(I: Integer): Boolean;
Begin
 IsEndp := (At^[I].Z In [7, 8, 16, 34, 52]) And (IChg[I] = 0) And Not IGone[I];
End;

Function HasDblI(I: Integer): Boolean;
Var K: Integer;
Begin
 HasDblI := True;
 For K := 0 To AdjN^[I] - 1 Do
  If IBo[AdjB^[I, K]] = 2 Then Exit;
 HasDblI := False;
End;

Function HeavyDeg(I: Integer): Integer;
Var K, N: Integer;
Begin
 N := 0;
 For K := 0 To AdjN^[I] - 1 Do If Not IGone[Adj^[I, K]] Then Inc(N);
 HeavyDeg := N;
End;

Function TgFind(X: Integer): Integer;
Begin
 While TgPar[X] <> X Do Begin TgPar[X] := TgPar[TgPar[X]]; X := TgPar[X]; End;
 TgFind := X;
End;

Function InRingAtom(R, A: Integer): Boolean;
Var K: Integer;
Begin
 InRingAtom := True;
 For K := 0 To RingN[R] - 1 Do If RingA[R, K] = A Then Exit;
 InRingAtom := False;
End;

{ Parcours des chemins alternes a partir du donneur TgDonor }
Procedure TgDFS(A, Need, Len: Integer);
Var
 K, B, J, T, R, Z : Integer;
 InPath, Ok, AllIn : Boolean;
Begin
 For K := 0 To AdjN^[A] - 1 Do Begin
  B := Adj^[A, K]; J := AdjB^[A, K];
  If IGone[B] Then Continue;
  InPath := False;
  For T := 0 To Len Do If TgPath[T] = B Then InPath := True;
  If InPath Then Continue;
  If Not ((IBo[J] = Need) Or BAro[J]) Then Continue;
  TgPath[Len + 1] := B;
  If (Need = 2) And IsEndp(B) And (B <> TgDonor) And HasDblI(B) Then Begin
   Ok := True;
   If Len + 1 > 2 Then Begin
    Ok := False;
    For R := 0 To NRings - 1 Do Begin
     AllIn := True;
     For T := 1 To Len Do If Not InRingAtom(R, TgPath[T]) Then AllIn := False;
     If AllIn And (InRingAtom(R, TgDonor) Or InRingAtom(R, B)) Then Ok := True;
    End;
   End
   Else Begin
    Z := At^[TgPath[1]].Z;
    If Not (Z In [6, 7, 15]) Then
     If (HeavyDeg(TgDonor) <> 1) Or (HeavyDeg(B) <> 1) Then Ok := False;
   End;
   If Ok Then Begin
    TgPar[TgFind(TgDonor)] := TgFind(B);
    TgIn[TgDonor] := True; TgIn[B] := True;
   End;
  End;
  If Len + 1 < 6 Then Begin
   Z := At^[B].Z;
   If ((Need = 1) And (Z In [6, 7, 15, 16, 33, 34, 51, 52])) Or
      ((Need = 2) And (Z In [6, 7])) Then TgDFS(B, 3 - Need, Len + 1);
  End;
 End;
End;

{ --- raffinement et recherche du numerotage canonique --- }

Function IKeyLE(Var R: TIRk; Var NS: Array Of Integer; J, I: Integer): Boolean;
Var K: Integer;
Begin
 IKeyLE := False;
 If R[J] < R[I] Then Begin IKeyLE := True; Exit; End;
 If R[J] > R[I] Then Exit;
 For K := 0 To ICNbN[I] - 1 Do Begin
  If NS[J * 8 + K] < NS[I * 8 + K] Then Begin IKeyLE := True; Exit; End;
  If NS[J * 8 + K] > NS[I * 8 + K] Then Exit;
 End;
 IKeyLE := True;
End;

Procedure IRefine(Var R: TIRk);
Var
 NS : Array[0..IN_MAX * 8 - 1] Of Integer;
 NewR : TIRk;
 I, J, K, T, C : Integer;
 Changed : Boolean;
Begin
 Repeat
  For I := 0 To ICN - 1 Do Begin
   For K := 0 To ICNbN[I] - 1 Do NS[I * 8 + K] := R[ICNb[I, K]];
   For K := 1 To ICNbN[I] - 1 Do Begin
    T := NS[I * 8 + K]; J := K - 1;
    While (J >= 0) And (NS[I * 8 + J] > T) Do Begin NS[I * 8 + J + 1] := NS[I * 8 + J]; Dec(J); End;
    NS[I * 8 + J + 1] := T;
   End;
  End;
  Changed := False;
  For I := 0 To ICN - 1 Do Begin
   C := 0;
   For J := 0 To ICN - 1 Do If IKeyLE(R, NS, J, I) Then Inc(C);
   NewR[I] := C;
  End;
  For I := 0 To ICN - 1 Do
   If NewR[I] <> R[I] Then Changed := True;
  R := NewR;
 Until Not Changed;
End;

Procedure IAddCt(Var A: TICt; Var N: Integer; V: Integer);
Begin
 If N < IN_CTMAX Then Begin A[N] := V; Inc(N); End;
End;

Function ICmpArr(Var A: TICt; NA: Integer; Var B: TICt; NB: Integer): Integer;
Var K, M: Integer;
Begin
 If NA < NB Then M := NA Else M := NB;
 For K := 0 To M - 1 Do Begin
  If A[K] < B[K] Then Begin ICmpArr := -1; Exit; End;
  If A[K] > B[K] Then Begin ICmpArr := 1; Exit; End;
 End;
 If NA < NB Then ICmpArr := -1 Else If NA > NB Then ICmpArr := 1 Else ICmpArr := 0;
End;

Procedure ILeaf(Var R: TIRk);
Var
 Ord2 : TIRk;
 P, I, K, J, T, H, C1 : Integer;
 Tmp : Array[0..7] Of Integer;
 NT : Integer;
Begin
 For I := 0 To ICN - 1 Do Ord2[R[I] - 1] := I;
 ICtCurN := 0;
 For P := 1 To ICN Do Begin
  I := Ord2[P - 1];
  IAddCt(ICtCur^, ICtCurN, P);
  NT := 0;
  For K := 0 To ICNbN[I] - 1 Do
   If R[ICNb[I, K]] < P Then Begin Tmp[NT] := R[ICNb[I, K]]; Inc(NT); End;
  For K := 1 To NT - 1 Do Begin
   T := Tmp[K]; J := K - 1;
   While (J >= 0) And (Tmp[J] > T) Do Begin Tmp[J + 1] := Tmp[J]; Dec(J); End;
   Tmp[J + 1] := T;
  End;
  For K := 0 To NT - 1 Do IAddCt(ICtCur^, ICtCurN, Tmp[K]);
 End;
 IHCurN := 0;
 For H := 1 To 9 Do Begin
  IAddCt(IHCur^, IHCurN, 1000 + H);
  For P := 1 To ICN Do
   If ICH2[Ord2[P - 1]] = H Then IAddCt(IHCur^, IHCurN, P);
 End;
 If Not IHave Then C1 := -1
 Else Begin
  C1 := ICmpArr(ICtCur^, ICtCurN, ICtBest^, ICtBestN);
  If C1 = 0 Then C1 := ICmpArr(IHCur^, IHCurN, IHBest^, IHBestN);
 End;
 If C1 < 0 Then Begin
  Move(ICtCur^, ICtBest^, SizeOf(TICt)); ICtBestN := ICtCurN;
  Move(IHCur^, IHBest^, SizeOf(TICt)); IHBestN := IHCurN;
  IBestR := R;
  IHave := True;
  INLeaf := 0;
  If IStOn Then Begin ILeaves[0]^ := R; INLeaf := 1; End;
 End
 Else If (C1 = 0) And IStOn And (INLeaf < IN_LF) Then Begin
  ILeaves[INLeaf]^ := R; Inc(INLeaf);
 End;
End;

Function SameNbI(A, B: Integer): Boolean;
Var K, J: Integer; F: Boolean;
Begin
 SameNbI := False;
 If ICNbN[A] <> ICNbN[B] Then Exit;
 For K := 0 To ICNbN[A] - 1 Do Begin
  F := False;
  For J := 0 To ICNbN[B] - 1 Do If ICNb[A, K] = ICNb[B, J] Then F := True;
  If Not F Then Exit;
 End;
 SameNbI := True;
End;

Procedure ISearch(D: Integer);
Var
 R, M : PIRk;
 I, V, Cell, Size, T, U, NM : Integer;
 Skip : Boolean;
Begin
 Inc(INodes);
 R := Lv[D]; M := LvM[D];
 For V := 0 To ICN Do ICnt[V] := 0;
 For I := 0 To ICN - 1 Do Inc(ICnt[R^[I]]);
 Cell := 0;
 For V := 1 To ICN Do If ICnt[V] > 1 Then Begin Cell := V; Break; End;
 If Cell = 0 Then Begin ILeaf(R^); Exit; End;
 Size := ICnt[Cell];
 NM := 0;
 For I := 0 To ICN - 1 Do If R^[I] = Cell Then Begin M^[NM] := I; Inc(NM); End;
 If (D >= IN_DEPTH - 1) Or (INodes > 40000) Then Begin
  { arret : departage arbitraire par l'ordre des indices }
  Lv[D + 1]^ := R^;
  For T := 0 To NM - 1 Do Lv[D + 1]^[M^[T]] := Cell - Size + 1 + T;
  ILeaf(Lv[D + 1]^);
  Exit;
 End;
 For T := 0 To NM - 1 Do Begin
  Skip := False;
  For U := 0 To T - 1 Do
   If (ICH2[M^[U]] = ICH2[M^[T]]) And SameNbI(M^[U], M^[T]) Then Skip := True;
  If Skip Then Continue;
  Lv[D + 1]^ := R^;
  Lv[D + 1]^[M^[T]] := Cell - Size + 1;
  IRefine(Lv[D + 1]^);
  ISearch(D + 1);
 End;
End;

{ --- serialisation de la couche connectivite --- }

Procedure SDfs(A, P: Integer);
Var K, B: Integer;
Begin
 SIdx[A] := SCnt; Inc(SCnt);
 For K := 0 To SDeg[A] - 1 Do Begin
  B := SAdj[A, K];
  If B = P Then Continue;
  If SIdx[B] < 0 Then Begin
   SCh[A, SChN[A]] := B; Inc(SChN[A]);
   SDfs(B, A);
  End
  Else If SIdx[B] < SIdx[A] Then Begin
   SCl[A, SClN[A]] := B; Inc(SClN[A]);
  End;
 End;
End;

Function SSz(A: Integer): Integer;
Var K, S: Integer;
Begin
 S := 1 + SClN[A];
 For K := 0 To SChN[A] - 1 Do S := S + SSz(SCh[A, K]);
 SSize[A] := S;
 SSz := S;
End;

Procedure SEmit(A: Integer);
Var
 Items : Array[0..15] Of Integer;     { > 0 : enfant, < 0 : fermeture de cycle }
 M, K, J, T, X, Y : Integer;
 Procedure Item(V: Integer);
 Begin
  If V < 0 Then InAdd(IntToStr(-V)) Else SEmit(V);
 End;
Begin
 M := 0;
 For K := 0 To SClN[A] - 1 Do Begin Items[M] := -SCl[A, K]; Inc(M); End;
 For K := 0 To SChN[A] - 1 Do Begin Items[M] := SCh[A, K]; Inc(M); End;
 { tri des enfants : taille puis numero }
 For K := SClN[A] + 1 To M - 1 Do Begin
  T := Items[K]; J := K - 1;
  While J >= SClN[A] Do Begin
   X := Items[J]; Y := T;
   If (SSize[X] > SSize[Y]) Or ((SSize[X] = SSize[Y]) And (X > Y)) Then Begin
    Items[J + 1] := Items[J]; Dec(J);
   End
   Else Break;
  End;
  Items[J + 1] := T;
 End;
 InAdd(IntToStr(A));
 If M = 0 Then Exit;
 If M = 1 Then Begin
  InAdd('-'); Item(Items[0]);
 End
 Else Begin
  InAdd('(');
  For K := 0 To M - 2 Do Begin
   If K > 0 Then InAdd(',');
   Item(Items[K]);
  End;
  InAdd(')');
  Item(Items[M - 1]);
 End;
End;

{ --- stereochimie : parites tetraedriques et liaisons doubles --- }

{ Rang d'un voisin du document dans un numerotage (0 pour un H) }
Function IKey(Var R: TIRk; A: Integer): Integer;
Begin
 If IGone[A] Then IKey := 0 Else IKey := R[ICPos[A]];
End;

{ Parite (1 = '-', 2 = '+') du centre X pour le numerotage R ;
  Def = faux si la geometrie ne la definit pas (parite synthetique) }
Function SeCenterPar(X: Integer; Var R: TIRk; Var Def: Boolean): Integer;
Var
 Sl, Ky, Rf : Array[0..3] Of Integer;
 N, K, J, T, V, I, Inv : Integer;
 D : Real;
 HW : Boolean;
Begin
 N := 0;
 For K := 1 To Inf^[X].H Do
  If N < 4 Then Begin Sl[N] := -1; Ky[N] := 0; Rf[N] := N; Inc(N); End;
 For K := 0 To AdjN^[X] - 1 Do
  If N < 4 Then Begin
   J := Adj^[X, K]; Sl[N] := J; Ky[N] := IKey(R, J); Rf[N] := N; Inc(N);
  End;
 If N = 3 Then Begin
  For I := 3 Downto 1 Do Begin Sl[I] := Sl[I - 1]; Ky[I] := Ky[I - 1]; Rf[I] := Rf[I - 1] + 1; End;
  Sl[0] := -1; Ky[0] := 0; Rf[0] := 0;
 End;
 For K := 1 To 3 Do Begin
  T := Ky[K]; V := Sl[K]; I := Rf[K]; J := K - 1;
  While (J >= 0) And (Ky[J] > T) Do Begin
   Ky[J + 1] := Ky[J]; Sl[J + 1] := Sl[J]; Rf[J + 1] := Rf[J]; Dec(J);
  End;
  Ky[J + 1] := T; Sl[J + 1] := V; Rf[J + 1] := I;
 End;
 D := Orient4(X, Sl, HW);
 Def := HW And (Abs(D) >= 0.02);
 For K := 0 To AdjN^[X] - 1 Do
  If Bd^[AdjB^[X, K]].Sty = ST_WAVY Then Def := False;
 If Def Then Begin
  If D < 0 Then SeCenterPar := 1 Else SeCenterPar := 2;
 End
 Else Begin
  Inv := 0;
  For K := 0 To 2 Do
   For J := K + 1 To 3 Do If Rf[K] > Rf[J] Then Inv := 1 - Inv;
  SeCenterPar := 1 + Inv;
 End;
End;

{ Parite de la liaison double J : '-' (1) si les voisins de plus grand
  numero des deux extremites sont du meme cote (cis), '+' (2) sinon }
Function SeBondPar(J: Integer; Var R: TIRk; Var Def: Boolean): Integer;
Var
 A, B, E, P, K, M, Key, Best, BestKey, Idx, Pos2 : Integer;
 Side : Array[0..1] Of Integer;
 Syn : Array[0..1] Of Integer;
 Geo : Boolean;
Begin
 A := Bd^[J].A; B := Bd^[J].B;
 Geo := (Bd^[J].DPos <> 3) And (Bd^[J].Sty <> ST_WAVY);
 For E := 0 To 1 Do Begin
  If E = 0 Then Begin P := A; M := B; End Else Begin P := B; M := A; End;
  Best := -1; BestKey := -1; Idx := 0; Pos2 := 0;
  For K := 0 To AdjN^[P] - 1 Do Begin
   If Adj^[P, K] = M Then Continue;
   Key := IKey(R, Adj^[P, K]);
   If Key > BestKey Then Begin BestKey := Key; Best := Adj^[P, K]; Pos2 := Idx; End;
   Inc(Idx);
  End;
  If Best < 0 Then Begin Side[E] := 0; Syn[E] := 1; End
  Else Begin
   Side[E] := SideOf(A, B, At^[Best].X, At^[Best].Y);
   If Pos2 = 0 Then Syn[E] := 1 Else Syn[E] := -1;
  End;
 End;
 Def := Geo And (Side[0] <> 0) And (Side[1] <> 0);
 If Def Then Begin
  If Side[0] = Side[1] Then SeBondPar := 1 Else SeBondPar := 2;
 End
 Else If Syn[0] = Syn[1] Then SeBondPar := 1 Else SeBondPar := 2;
End;

{ Deux voisins du centre (ou de l'extremite) sont-ils interchangeables ? }
Function SeTwins(X, Excl: Integer): Boolean;
Var K, T, A, B, NH : Integer;
Begin
 SeTwins := True;
 NH := Inf^[X].H;
 For K := 0 To AdjN^[X] - 1 Do
  If (Adj^[X, K] <> Excl) And IGone[Adj^[X, K]] Then Inc(NH);
 If NH >= 2 Then Exit;
 For K := 0 To AdjN^[X] - 1 Do Begin
  A := Adj^[X, K];
  If (A = Excl) Or IGone[A] Then Continue;
  For T := K + 1 To AdjN^[X] - 1 Do Begin
   B := Adj^[X, T];
   If (B = Excl) Or IGone[B] Then Continue;
   If (ICEl[ICPos[A]] = ICEl[ICPos[B]]) And (ICH2[ICPos[A]] = ICH2[ICPos[B]]) And
      SameNbI(ICPos[A], ICPos[B]) Then Exit;
  End;
 End;
 SeTwins := False;
End;

{ Chemin alterne (double, simple, double ...) depuis un cation jusqu'a la
  liaison JT : la charge est delocalisee et InChI ignore la stereo de JT }
Function SeAlt(A, JT, Need, Depth: Integer; Var Seen: Array Of Boolean): Boolean;
Var K, J, B : Integer; Ok : Boolean;
Begin
 SeAlt := False;
 If Depth > 8 Then Exit;
 For K := 0 To AdjN^[A] - 1 Do Begin
  J := AdjB^[A, K]; B := Adj^[A, K];
  If IGone[B] Or Seen[B] Then Continue;
  If Need = 2 Then Ok := (IBo[J] = 2) Or BAro[J] Else Ok := (IBo[J] = 1) Or BAro[J];
  If Not Ok Then Continue;
  If (J = JT) And (Need = 2) Then Begin SeAlt := True; Exit; End;
  Seen[B] := True;
  If SeAlt(B, JT, 3 - Need, Depth + 1, Seen) Then Begin Seen[B] := False; SeAlt := True; Exit; End;
  Seen[B] := False;
 End;
End;

Function SeCationConj(JT: Integer): Boolean;
Var I, K : Integer; Seen : Array[0..MAX_ATOMS - 1] Of Boolean;
Begin
 SeCationConj := False;
 For I := 0 To NAt - 1 Do
  If (Not IGone[I]) And (IChg[I] > 0) And (At^[I].Z In [7, 15, 16]) Then Begin
   For K := 0 To NAt - 1 Do Seen[K] := False;
   Seen[I] := True;
   If SeAlt(I, JT, 2, 0, Seen) Then Begin SeCationConj := True; Exit; End;
  End;
End;

{ Extremite de liaison double : atome neutre usuel ou azote d'un azoxy }
Function SeEndOK(E, P: Integer): Boolean;
Begin
 SeEndOK := EndOK(E, P) Or AzoxyEnd(E, P);
End;

{ Elements stereogenes possibles (centres et liaisons doubles) }
Procedure SeBuild;
Var
 I, J, A, B, R : Integer;
 Dm : TIRk;
 D : Boolean;
Begin
 SeN := 0; IStOn := False;
 For I := 0 To IN_MAX - 1 Do Dm[I] := I + 1;
 For I := 0 To NAt - 1 Do Begin
  If IGone[I] Or (SeN >= IN_SE) Then Continue;
  If StereoKind(I) = 0 Then Continue;
  If (At^[I].Z = 15) And (Inf^[I].H > 0) Then Continue;
  If SeTwins(I, -1) Then Continue;
  SeKind[SeN] := 1; SeA[SeN] := I; SeB[SeN] := -1;
  If SeCenterPar(I, Dm, D) = 0 Then;
  SeDef[SeN] := D;
  Inc(SeN);
 End;
 For J := 0 To NBd - 1 Do Begin
  If SeN >= IN_SE Then Break;
  If (Bd^[J].Order <> 2) Or (IBo[J] <> 2) Or BAro[J] Then Continue;
  A := Bd^[J].A; B := Bd^[J].B;
  If IGone[A] Or IGone[B] Or TgIn[A] Or TgIn[B] Then Continue;
  If Not (SeEndOK(A, B) And SeEndOK(B, A)) Then Continue;
  R := RingOfBond(A, B);
  If (R >= 0) And (RingN[R] < 8) Then Continue;
  If SeCationConj(J) Then Continue;
  If SeTwins(A, B) Or SeTwins(B, A) Then Continue;
  SeKind[SeN] := 2; SeA[SeN] := A; SeB[SeN] := B;
  If SeBondPar(J, Dm, D) = 0 Then;
  SeDef[SeN] := D;
  Inc(SeN);
 End;
 For I := 0 To SeN - 1 Do If SeDef[I] Then IStOn := True;
End;

Type
 TSeKeyArr = Array[0..IN_LF - 1, 0..IN_SE - 1] Of LongInt;
 TSeByteArr = Array[0..IN_LF - 1, 0..IN_SE - 1] Of Byte;

Var
 SeKey  : ^TSeKeyArr;     { cle de position de chaque element, triee }
 SeVal  : ^TSeByteArr;    { parite (1, 2) ou 3 = indefinie }
 SeEl   : ^TSeByteArr;    { indice de l'element }
 SeMask : Array[0..IN_SE - 1] Of Boolean;
 WKey   : PICt;
 WKeyN  : Integer;
 WOutB  : Array[0..IN_SE - 1, 0..2] Of Integer;
 WOutBN : Integer;
 WOutT  : Array[0..IN_SE - 1, 0..1] Of Integer;
 WOutTN : Integer;

{ Remplit les entrees triees du numerotage L }
Procedure SeFill(L: Integer);
Var
 E, I, T, P1, P2 : Integer;
 KK : LongInt;
 VV, EE : Byte;
Begin
 For E := 0 To SeN - 1 Do Begin
  If SeKind[E] = 1 Then KK := 100000 + ILeaves[L]^[ICPos[SeA[E]]]
  Else Begin
   P1 := ILeaves[L]^[ICPos[SeA[E]]]; P2 := ILeaves[L]^[ICPos[SeB[E]]];
   If P1 > P2 Then KK := LongInt(P1) * 256 + P2 Else KK := LongInt(P2) * 256 + P1;
  End;
  SeKey^[L, E] := KK; SeEl^[L, E] := E;
  SeVal^[L, E] := SePar^[L, E];
 End;
 For I := 1 To SeN - 1 Do Begin
  KK := SeKey^[L, I]; VV := SeVal^[L, I]; EE := SeEl^[L, I]; T := I - 1;
  While (T >= 0) And (SeKey^[L, T] > KK) Do Begin
   SeKey^[L, T + 1] := SeKey^[L, T]; SeVal^[L, T + 1] := SeVal^[L, T]; SeEl^[L, T + 1] := SeEl^[L, T];
   Dec(T);
  End;
  SeKey^[L, T + 1] := KK; SeVal^[L, T + 1] := VV; SeEl^[L, T + 1] := EE;
 End;
End;

{ Cle de comparaison du numerotage L (Inv = structure inversee) ;
  remplit WOutB / WOutT }
Procedure SeEntries(L: Integer; Inv: Boolean);
Var I, E, V : Integer; KK : LongInt;
Begin
 WOutBN := 0; WOutTN := 0; WKeyN := 0;
 For I := 0 To SeN - 1 Do Begin
  If Not SeMask[I] Then Continue;
  E := SeEl^[L, I]; KK := SeKey^[L, I];
  If SeDef[E] Then V := SeVal^[L, I] Else V := 3;
  If SeKind[E] = 1 Then Begin
   If Inv And SeDef[E] Then V := 3 - V;
   WOutT[WOutTN, 0] := KK - 100000; WOutT[WOutTN, 1] := V; Inc(WOutTN);
   IAddCt(WKey^, WKeyN, 2); IAddCt(WKey^, WKeyN, KK - 100000); IAddCt(WKey^, WKeyN, V);
  End
  Else Begin
   WOutB[WOutBN, 0] := KK Div 256; WOutB[WOutBN, 1] := KK Mod 256; WOutB[WOutBN, 2] := V; Inc(WOutBN);
   IAddCt(WKey^, WKeyN, 1); IAddCt(WKey^, WKeyN, KK Div 256); IAddCt(WKey^, WKeyN, KK Mod 256);
   IAddCt(WKey^, WKeyN, V);
  End;
 End;
End;

{ Un centre defini d'un cycle qui partage ce cycle avec un autre centre defini
  n'est jamais retire : la stereochimie du cycle leve l'equivalence }
Function SeRemovable(E: Integer): Boolean;
Var T, R, K : Integer; InA, InB : Boolean;
Begin
 SeRemovable := True;
 If (SeKind[E] <> 1) Or (Not SeDef[E]) Then Exit;
 EnsureRings;
 For T := 0 To SeN - 1 Do
  If (T <> E) And (SeKind[T] = 1) And SeDef[T] Then
   For R := 0 To NRings - 1 Do Begin
    InA := False; InB := False;
    For K := 0 To RingN[R] - 1 Do Begin
     If RingA[R, K] = SeA[E] Then InA := True;
     If RingA[R, K] = SeA[T] Then InB := True;
    End;
    If InA And InB Then Begin SeRemovable := False; Exit; End;
   End;
End;

{ Choisit le numerotage qui minimise la couche stereo et prepare OutB / OutT }
Procedure SeAnalyze;
Var
 L, L2, E, I, Cnt, Last, Pass, BestL, N0, N1 : Integer;
 D, Chg, AnyDef : Boolean;
 Best0, Best1 : PICt;
Begin
 InStHas := False; InChiral := False; InInvert := False;
 OutBN := 0; OutTN := 0; N0 := 0; N1 := 0;
 If (Not IStOn) Or (INLeaf = 0) Then Exit;
 For L := 0 To INLeaf - 1 Do Begin
  For E := 0 To SeN - 1 Do Begin
   If SeKind[E] = 1 Then SePar^[L, E] := SeCenterPar(SeA[E], ILeaves[L]^, D)
   Else SePar^[L, E] := SeBondPar(FindBond(SeA[E], SeB[E]), ILeaves[L]^, D);
  End;
  SeFill(L);
 End;
 For I := 0 To SeN - 1 Do SeMask[I] := True;
 { une position qui change seule d'un numerotage equivalent a l'autre
   n'est pas stereogene }
 Repeat
  Chg := False;
  For L := 0 To INLeaf - 2 Do
   For L2 := L + 1 To INLeaf - 1 Do Begin
    Cnt := 0; Last := -1;
    For I := 0 To SeN - 1 Do
     If SeMask[I] And (SeVal^[L, I] <> SeVal^[L2, I]) Then Begin
      Inc(Cnt); Last := I; If Cnt > 1 Then Break;
     End;
    If (Cnt = 1) And SeRemovable(SeEl^[L, Last]) Then Begin SeMask[Last] := False; Chg := True; End;
   End;
 Until Not Chg;
 AnyDef := False;
 For I := 0 To SeN - 1 Do
  If SeMask[I] And SeDef[SeEl^[0, I]] Then AnyDef := True;
 If Not AnyDef Then Exit;
 New(Best0); New(Best1);
 For Pass := 0 To 1 Do Begin
  BestL := -1;
  For L := 0 To INLeaf - 1 Do Begin
   SeEntries(L, Pass = 1);
   If (BestL < 0) Or ((Pass = 0) And (ICmpArr(WKey^, WKeyN, Best0^, N0) < 0)) Or
      ((Pass = 1) And (ICmpArr(WKey^, WKeyN, Best1^, N1) < 0)) Then Begin
    BestL := L;
    If Pass = 0 Then Begin Move(WKey^, Best0^, SizeOf(TICt)); N0 := WKeyN; End
    Else Begin Move(WKey^, Best1^, SizeOf(TICt)); N1 := WKeyN; End;
    OutBN := WOutBN; OutTN := WOutTN;
    For I := 0 To WOutBN - 1 Do Begin OutB[I, 0] := WOutB[I, 0]; OutB[I, 1] := WOutB[I, 1]; OutB[I, 2] := WOutB[I, 2]; End;
    For I := 0 To WOutTN - 1 Do Begin OutT[I, 0] := WOutT[I, 0]; OutT[I, 1] := WOutT[I, 1]; End;
    If Pass = 0 Then IBestR := ILeaves[L]^;
   End;
  End;
  If Pass = 0 Then Begin
   { memorise la structure telle quelle ; la passe 1 la remplace si besoin }
   SeSaveN := OutBN; SeSaveT := OutTN;
   For I := 0 To OutBN - 1 Do Begin SeSaveB[I, 0] := OutB[I, 0]; SeSaveB[I, 1] := OutB[I, 1]; SeSaveB[I, 2] := OutB[I, 2]; End;
   For I := 0 To OutTN - 1 Do Begin SeSaveTT[I, 0] := OutT[I, 0]; SeSaveTT[I, 1] := OutT[I, 1]; End;
  End;
 End;
 If ICmpArr(Best1^, N1, Best0^, N0) < 0 Then Begin
  { la structure inversee est plus petite : /m1 (OutB / OutT deja a jour) }
  InInvert := True; InChiral := True;
  For L := 0 To INLeaf - 1 Do Begin
   SeEntries(L, True);
   If ICmpArr(WKey^, WKeyN, Best1^, N1) = 0 Then Begin IBestR := ILeaves[L]^; Break; End;
  End;
 End
 Else Begin
  OutBN := SeSaveN; OutTN := SeSaveT;
  For I := 0 To OutBN - 1 Do Begin OutB[I, 0] := SeSaveB[I, 0]; OutB[I, 1] := SeSaveB[I, 1]; OutB[I, 2] := SeSaveB[I, 2]; End;
  For I := 0 To OutTN - 1 Do Begin OutT[I, 0] := SeSaveTT[I, 0]; OutT[I, 1] := SeSaveTT[I, 1]; End;
  If ICmpArr(Best1^, N1, Best0^, N0) > 0 Then InChiral := True;
 End;
 Dispose(Best0); Dispose(Best1);
 InStHas := True;
End;

Function SeSign(V: Integer): String;
Begin
 If V = 1 Then SeSign := '-' Else If V = 2 Then SeSign := '+' Else SeSign := '?';
End;

{ Ecrit les couches /b /t /m /s }
Procedure SeWrite;
Var I: Integer;
Begin
 If Not InStHas Then Exit;
 If OutBN > 0 Then Begin
  InAdd('/b');
  For I := 0 To OutBN - 1 Do Begin
   If I > 0 Then InAdd(',');
   InAdd(IntToStr(OutB[I, 0]) + '-' + IntToStr(OutB[I, 1]) + SeSign(OutB[I, 2]));
  End;
 End;
 If OutTN > 0 Then Begin
  InAdd('/t');
  For I := 0 To OutTN - 1 Do Begin
   If I > 0 Then InAdd(',');
   InAdd(IntToStr(OutT[I, 0]) + SeSign(OutT[I, 1]));
  End;
  If InChiral Then Begin
   If InInvert Then InAdd('/m1') Else InAdd('/m0');
   InAdd('/s1');
  End;
 End;
End;


{ Calcule l'InChI du document ; resultat dans InBuf ; message d'erreur dans InMsg }
Function ComputeInChI: Boolean;
Var
 Snap : TSnap;
 Mod0 : Boolean;
 I, J, K, N, Z, P, Q, Pn, NG, Seed, Cur, Head, Tail : Integer;
 Cnts : TCounts;
 ElOrd : Array[0..103] Of Integer;
 Present : Array[0..103] Of Boolean;
 Vis : Array[0..MAX_ATOMS - 1] Of Boolean;
 Key : TIRk;
 R0 : TIRk;
 GRoot : Array[0..IN_MAX - 1] Of Integer;
 GHs   : Array[0..IN_MAX - 1] Of Integer;
 GCnt  : Array[0..IN_MAX - 1] Of Integer;
 GOf   : Array[0..MAX_ATOMS - 1] Of Integer;
 Found, Any, Aromatic, AllIn : Boolean;
 RkOf  : TIRk;
 ARk   : Array[0..IN_MAX - 1] Of Integer;
 Seg   : String;
 FirstSeg, FirstGrp : Boolean;
 Terms, Best : Integer;
 ChgS  : String;
 S1, S2 : String;
 Bi, C1, C2, Lo, Hi, Cnt2, H : Integer;
 GL : Array[0..IN_MAX - 1] Of Integer;
 NGL : Integer;
 Tmp : Integer;
Begin
 ComputeInChI := False;
 InMsg := '';
 InLen := 0;
 If NAt = 0 Then Begin InMsg := 'Aucune structure.'; Exit; End;
 Mod0 := Modified;
 TakeSnap(Snap);
 ExpandAllLabels;
 UpdateInfo;
 BuildAdj;
 { atomes d'hydrogene terminaux : retires du graphe }
 For I := 0 To NAt - 1 Do Begin
  IGone[I] := False;
  IHs[I] := Inf^[I].H;
  IChg[I] := At^[I].Chg;
 End;
 For I := 0 To NAt - 1 Do
  If (At^[I].Z = 1) And (AdjN^[I] = 1) And (At^[I].Chg = 0) And (NAt > 2) Then Begin
   J := Adj^[I, 0];
   If At^[J].Z <> 1 Then Begin IGone[I] := True; Inc(IHs[J]); End;
  End;
 N := 0;
 For I := 0 To NAt - 1 Do If Not IGone[I] Then Inc(N);
 If N > IN_MAX Then Begin InMsg := 'Structure trop grande (max ' + IntToStr(IN_MAX) + ' atomes).'; End;
 For I := 0 To NAt - 1 Do
  If Not IGone[I] Then Begin
   If (At^[I].Z = 0) Or (At^[I].Lbl <> '') Then Begin InMsg := 'Etiquette generique (R, X ...) non prise en charge.'; End;
   If Not (At^[I].Z In [1, 5, 6, 7, 8, 9, 14, 15, 16, 17, 33, 34, 35, 52, 53]) And (AdjN^[I] > 0) Then
    InMsg := 'Metaux / elements non organiques lies non pris en charge.';
  End;
 If InMsg = '' Then Begin
  { connexite }
  For I := 0 To NAt - 1 Do Vis[I] := IGone[I];
  Seed := -1;
  For I := 0 To NAt - 1 Do If Not Vis[I] Then Begin Seed := I; Break; End;
  If Seed >= 0 Then Begin
   Head := 0; Tail := 1; Tmp2^[0] := Seed; Vis[Seed] := True;
   While Head < Tail Do Begin
    Cur := Tmp2^[Head]; Inc(Head);
    For K := 0 To AdjN^[Cur] - 1 Do
     If Not Vis[Adj^[Cur, K]] Then Begin Vis[Adj^[Cur, K]] := True; Tmp2^[Tail] := Adj^[Cur, K]; Inc(Tail); End;
   End;
   For I := 0 To NAt - 1 Do If Not Vis[I] Then InMsg := 'Plusieurs fragments : non pris en charge.';
  End
  Else InMsg := 'Aucun atome lourd.';
 End;
 If InMsg <> '' Then Begin RestoreSnap(Snap); FreeSnap(Snap); Modified := Mod0; Exit; End;
 { ordres de liaison et neutralisation des charges }
 For J := 0 To NBd - 1 Do IBo[J] := Bd^[J].Order;
 Pn := 0;
 For I := 0 To NAt - 1 Do Begin
  If IGone[I] Then Continue;
  For K := 0 To AdjN^[I] - 1 Do Begin
   J := Adj^[I, K];
   If (J > I) And Not IGone[J] And (IChg[I] * IChg[J] < 0) Then Begin
    IChg[I] := 0; IChg[J] := 0;
    Inc(IBo[AdjB^[I, K]]);
   End;
  End;
 End;
 For I := 0 To NAt - 1 Do Begin
  If IGone[I] Then Continue;
  If (IChg[I] > 0) And (IHs[I] > 0) And (At^[I].Z In [7, 8, 16, 15]) Then Begin
   Dec(IHs[I]); Dec(IChg[I]); Inc(Pn);
  End
  Else If (IChg[I] < 0) And (At^[I].Z In [7, 8, 16, 34, 52, 9, 17, 35, 53]) Then Begin
   Inc(IHs[I]); Inc(IChg[I]); Dec(Pn);
  End;
 End;
 Q := 0;
 For I := 0 To NAt - 1 Do If Not IGone[I] Then Q := Q + IChg[I];
 { cycles aromatiques }
 EnsureRings;
 MarkAromRings;
 For J := 0 To NBd - 1 Do BAro[J] := False;
 For K := 0 To NRings - 1 Do
  If RingAro[K] Then
   For I := 0 To RingN[K] - 1 Do Begin
    J := FindBond(RingA[K, I], RingA[K, (I + 1) Mod RingN[K]]);
    If J >= 0 Then BAro[J] := True;
   End;
 { groupes tautomeres (H mobiles) }
 For I := 0 To NAt - 1 Do Begin TgPar[I] := I; TgIn[I] := False; End;
 For I := 0 To NAt - 1 Do
  If IsEndp(I) And (IHs[I] > 0) Then Begin
   TgDonor := I; TgPath[0] := I;
   TgDFS(I, 1, 0);
  End;
 NG := 0;
 For I := 0 To IN_MAX - 1 Do Begin GRoot[I] := 0; GCnt[I] := 0; GHs[I] := 0; End;
 For I := 0 To NAt - 1 Do GOf[I] := -1;
 For I := 0 To NAt - 1 Do
  If TgIn[I] Then Begin
   Z := TgFind(I);
   Found := False;
   For K := 0 To NG - 1 Do If GRoot[K] = Z Then Begin GOf[I] := K; Inc(GCnt[K]); Found := True; Break; End;
   If Not Found And (NG < IN_MAX) Then Begin
    GRoot[NG] := Z; GCnt[NG] := 1; GHs[NG] := 0; GOf[I] := NG; Inc(NG);
   End;
  End;
 For I := 0 To NAt - 1 Do If GOf[I] >= 0 Then Inc(GHs[GOf[I]], IHs[I]);
 { cation net : retrait de protons }
 While Q > 0 Do Begin
  K := -1;
  For J := 0 To NG - 1 Do If GHs[J] > 0 Then Begin K := J; Break; End;
  If K >= 0 Then Begin
   Dec(GHs[K]); Inc(Pn); Dec(Q);
   For I := 0 To NAt - 1 Do If (GOf[I] = K) And (IHs[I] > 0) Then Begin Dec(IHs[I]); Break; End;
  End
  Else Begin
   Found := False;
   For I := 0 To NAt - 1 Do
    If Not Found And Not IGone[I] And (At^[I].Z = 8) And (IHs[I] > 0) And (IChg[I] = 0) Then Begin
     Aromatic := False;
     For K := 0 To AdjN^[I] - 1 Do Begin
      J := Adj^[I, K];
      If At^[J].Z = 7 Then Aromatic := True;
      For H := 0 To AdjN^[J] - 1 Do
       If (Adj^[J, H] <> I) And BAro[AdjB^[J, H]] Then Aromatic := True;
     End;
     If Aromatic Then Begin Dec(IHs[I]); Inc(Pn); Dec(Q); Found := True; End;
    End;
   If Not Found Then Break;
  End;
 End;
 { graphe compact }
 ICN := 0;
 For I := 0 To NAt - 1 Do
  If Not IGone[I] Then Begin ICDoc[ICN] := I; ICPos[I] := ICN; Inc(ICN); End
  Else ICPos[I] := -1;
 For I := 0 To 103 Do Present[I] := False;
 For I := 0 To ICN - 1 Do Present[At^[ICDoc[I]].Z] := True;
 { rang Hill des elements : C d'abord puis ordre alphabetique }
 For Z := 1 To 103 Do
  If Present[Z] Then Begin
   ElOrd[Z] := 0;
   For J := 1 To 103 Do
    If Present[J] And (J <> Z) Then Begin
     If J = 6 Then Inc(ElOrd[Z])
     Else If (Z <> 6) And (ElSym[J] < ElSym[Z]) Then Inc(ElOrd[Z]);
    End;
  End;
 For I := 0 To ICN - 1 Do Begin
  J := ICDoc[I];
  ICEl[I] := ElOrd[At^[J].Z];
  ICNbN[I] := 0;
  For K := 0 To AdjN^[J] - 1 Do
   If Not IGone[Adj^[J, K]] Then Begin
    ICNb[I, ICNbN[I]] := ICPos[Adj^[J, K]]; Inc(ICNbN[I]);
   End;
  ICH2[I] := IHs[J];
  If GOf[J] >= 0 Then ICH2[I] := 0;
 End;
 { numerotage canonique }
 InStHas := False; IStOn := False;
 If ICN = 1 Then IBestR[0] := 1
 Else Begin
  For I := 0 To ICN - 1 Do Key[I] := ICEl[I] * 16 + ICNbN[I];
  For I := 0 To ICN - 1 Do Begin
   Cnt2 := 0;
   For J := 0 To ICN - 1 Do If Key[J] <= Key[I] Then Inc(Cnt2);
   R0[I] := Cnt2;
  End;
  IRefine(R0);
  Lv[0]^ := R0;
  IHave := False; INodes := 0;
  INLeaf := 0;
  SeBuild;
  ISearch(0);
  If IStOn Then SeAnalyze;
 End;
 For I := 0 To ICN - 1 Do RkOf[I] := IBestR[I];
 { formule }
 For Z := 0 To 103 Do Cnts[Z] := 0;
 For I := 0 To ICN - 1 Do Begin
  Inc(Cnts[At^[ICDoc[I]].Z]);
  Inc(Cnts[1], IHs[ICDoc[I]]);
 End;
 InAdd('InChI=1S/');
 InAdd(HillFormula(Cnts, 0));
 { connectivite }
 If ICN > 1 Then Begin
  For I := 1 To ICN Do Begin SDeg[I] := 0; SIdx[I] := -1; SChN[I] := 0; SClN[I] := 0; End;
  For I := 0 To ICN - 1 Do Begin
   K := RkOf[I];
   For J := 0 To ICNbN[I] - 1 Do Begin SAdj[K, SDeg[K]] := RkOf[ICNb[I, J]]; Inc(SDeg[K]); End;
   { tri croissant }
   For J := 1 To SDeg[K] - 1 Do Begin
    Tmp := SAdj[K, J]; H := J - 1;
    While (H >= 0) And (SAdj[K, H] > Tmp) Do Begin SAdj[K, H + 1] := SAdj[K, H]; Dec(H); End;
    SAdj[K, H + 1] := Tmp;
   End;
  End;
  Seed := 1;
  For I := ICN Downto 1 Do If SDeg[I] = 1 Then Seed := I;
  SCnt := 0;
  SDfs(Seed, 0);
  SSz(Seed);
  InAdd('/c');
  SEmit(Seed);
 End;
 { hydrogenes }
 FirstSeg := True;
 Any := False;
 For H := 1 To 9 Do Begin
  NGL := 0;
  For P := 1 To ICN Do Begin
   For I := 0 To ICN - 1 Do If (RkOf[I] = P) And (ICH2[I] = H) Then Begin GL[NGL] := P; Inc(NGL); End;
  End;
  If NGL = 0 Then Continue;
  If Not Any Then InAdd('/h');
  If Not FirstSeg Then InAdd(',');
  FirstSeg := False; Any := True;
  K := 0;
  While K < NGL Do Begin
   J := K;
   While (J + 1 < NGL) And (GL[J + 1] = GL[J] + 1) Do Inc(J);
   If K > 0 Then InAdd(',');
   If J = K Then InAdd(IntToStr(GL[K])) Else InAdd(IntToStr(GL[K]) + '-' + IntToStr(GL[J]));
   K := J + 1;
  End;
  InAdd('H');
  If H > 1 Then InAdd(IntToStr(H));
 End;
 { groupes mobiles : tries par nombre d'atomes puis numeros }
 For K := 0 To NG - 1 Do ARk[K] := K;
 For K := 1 To NG - 1 Do Begin
  Tmp := ARk[K]; J := K - 1;
  While J >= 0 Do Begin
   { comparer les groupes ARk[J] et Tmp }
   C1 := 0;
   If GCnt[ARk[J]] > GCnt[Tmp] Then C1 := 1
   Else If GCnt[ARk[J]] < GCnt[Tmp] Then C1 := -1
   Else Begin
    { memes tailles : comparer les listes de rangs }
    NGL := 0;
    For I := 0 To ICN - 1 Do If GOf[ICDoc[I]] = ARk[J] Then Begin GL[NGL] := RkOf[I]; Inc(NGL); End;
    For H := 1 To NGL - 1 Do Begin Bi := GL[H]; Lo := H - 1; While (Lo >= 0) And (GL[Lo] > Bi) Do Begin GL[Lo + 1] := GL[Lo]; Dec(Lo); End; GL[Lo + 1] := Bi; End;
    S1 := '';
    For H := 0 To NGL - 1 Do S1 := S1 + Chr(GL[H] Div 256 + 1) + Chr(GL[H] Mod 256 + 1);
    NGL := 0;
    For I := 0 To ICN - 1 Do If GOf[ICDoc[I]] = Tmp Then Begin GL[NGL] := RkOf[I]; Inc(NGL); End;
    For H := 1 To NGL - 1 Do Begin Bi := GL[H]; Lo := H - 1; While (Lo >= 0) And (GL[Lo] > Bi) Do Begin GL[Lo + 1] := GL[Lo]; Dec(Lo); End; GL[Lo + 1] := Bi; End;
    S2 := '';
    For H := 0 To NGL - 1 Do S2 := S2 + Chr(GL[H] Div 256 + 1) + Chr(GL[H] Mod 256 + 1);
    If S1 > S2 Then C1 := 1 Else C1 := -1;
   End;
   If C1 > 0 Then Begin ARk[J + 1] := ARk[J]; Dec(J); End
   Else Break;
  End;
  ARk[J + 1] := Tmp;
 End;
 FirstGrp := True;
 For K := 0 To NG - 1 Do Begin
  If GHs[ARk[K]] <= 0 Then Continue;
  If Not Any Then InAdd('/h');
  If Not FirstSeg And FirstGrp Then InAdd(',');
  FirstSeg := False; Any := True; FirstGrp := False;
  NGL := 0;
  For I := 0 To ICN - 1 Do If GOf[ICDoc[I]] = ARk[K] Then Begin GL[NGL] := RkOf[I]; Inc(NGL); End;
  For H := 1 To NGL - 1 Do Begin Bi := GL[H]; Lo := H - 1; While (Lo >= 0) And (GL[Lo] > Bi) Do Begin GL[Lo + 1] := GL[Lo]; Dec(Lo); End; GL[Lo + 1] := Bi; End;
  InAdd('(H');
  If GHs[ARk[K]] > 1 Then InAdd(IntToStr(GHs[ARk[K]]));
  For H := 0 To NGL - 1 Do InAdd(',' + IntToStr(GL[H]));
  InAdd(')');
 End;
 If Q <> 0 Then Begin
  If Q > 0 Then ChgS := '+' + IntToStr(Q) Else ChgS := '-' + IntToStr(-Q);
  InAdd('/q' + ChgS);
 End;
 If Pn <> 0 Then Begin
  If Pn > 0 Then ChgS := '+' + IntToStr(Pn) Else ChgS := '-' + IntToStr(-Pn);
  InAdd('/p' + ChgS);
 End;
 SeWrite;
 RestoreSnap(Snap);
 FreeSnap(Snap);
 Modified := Mod0;
 ComputeInChI := True;
End;

Procedure InitInChI;
Var D: Integer;
Begin
 New(InBuf);
 New(ICtBest); New(ICtCur); New(IHBest); New(IHCur);
 For D := 0 To IN_DEPTH Do Begin New(Lv[D]); New(LvM[D]); End;
 For D := 0 To IN_LF - 1 Do New(ILeaves[D]);
 New(SePar); New(WKey); New(SeKey); New(SeVal); New(SeEl);
 InLen := 0;
End;

{ --------------------------------------------------------------------- }
{ Recherche d'objets sous le curseur                                    }
{ --------------------------------------------------------------------- }

Procedure UpdateTxtScale;
Begin
 If Zoom >= 2.4 Then TxtScale := 3
 Else If Zoom >= 1.45 Then TxtScale := 2
 Else TxtScale := 1;
End;

Function FindAtomAt(MX, MY: Integer; Tol: Real): Integer;
Var I: Integer; D, Best: Real;
Begin
 FindAtomAt := -1; Best := Tol;
 For I := 0 To NAt - 1 Do Begin
  D := Dist(MX - CvX1, MY - CvY1, SXr(At^[I].X), SYr(At^[I].Y));
  If D <= Best Then Begin Best := D; FindAtomAt := I; End;
 End;
End;

Function FindBondAt(MX, MY: Integer; Tol: Real): Integer;
Var J, A, B: Integer; D, Best: Real;
Begin
 FindBondAt := -1; Best := Tol;
 For J := 0 To NBd - 1 Do Begin
  A := Bd^[J].A; B := Bd^[J].B;
  D := DistToSeg(MX - CvX1, MY - CvY1, SXr(At^[A].X), SYr(At^[A].Y), SXr(At^[B].X), SYr(At^[B].Y));
  If D <= Best Then Begin Best := D; FindBondAt := J; End;
 End;
End;

Function FindTextAt(MX, MY: Integer): Integer;
Var I, X1, Y1, X2, Y2: Integer;
Begin
 FindTextAt := -1;
 For I := NTx - 1 Downto 0 Do Begin
  TextRectScreen(I, X1, Y1, X2, Y2);
  If PtInRect(MX - CvX1, MY - CvY1, X1 - 2, Y1 - 2, X2 + 2, Y2 + 2) Then Begin
   FindTextAt := I; Exit;
  End;
 End;
End;

Function ShapeDist(I: Integer; PX, PY: Real): Real;
Var
 X1, Y1, X2, Y2, CX, CY, L, UX, UY, D, M, T, QX, QY, PrX, PrY, RX, RY, V : Real;
 K : Integer;
Begin
 X1 := SXr(Sh^[I].X1); Y1 := SYr(Sh^[I].Y1); X2 := SXr(Sh^[I].X2); Y2 := SYr(Sh^[I].Y2);
 CX := SXr(Sh^[I].CX); CY := SYr(Sh^[I].CY);
 L := Dist(X1, Y1, X2, Y2);
 Case Sh^[I].Kind Of
  SH_CURVE1, SH_CURVE2: Begin
   M := 1E9; PrX := X1; PrY := Y1;
   For K := 1 To 16 Do Begin
    T := K / 16;
    QX := (1 - T) * (1 - T) * X1 + 2 * (1 - T) * T * CX + T * T * X2;
    QY := (1 - T) * (1 - T) * Y1 + 2 * (1 - T) * T * CY + T * T * Y2;
    D := DistToSeg(PX, PY, PrX, PrY, QX, QY);
    If D < M Then M := D;
    PrX := QX; PrY := QY;
   End;
   ShapeDist := M;
  End;
  SH_RECT, SH_BRACKET: Begin
   M := DistToSeg(PX, PY, X1, Y1, X2, Y1);
   D := DistToSeg(PX, PY, X2, Y1, X2, Y2); If D < M Then M := D;
   D := DistToSeg(PX, PY, X2, Y2, X1, Y2); If D < M Then M := D;
   D := DistToSeg(PX, PY, X1, Y2, X1, Y1); If D < M Then M := D;
   ShapeDist := M;
  End;
  SH_ELLIPSE: Begin
   RX := AbsR(X2 - X1) / 2; RY := AbsR(Y2 - Y1) / 2;
   If (RX < 1) Or (RY < 1) Then ShapeDist := 1E9
   Else Begin
    V := Sqrt(Sqr((PX - (X1 + X2) / 2) / RX) + Sqr((PY - (Y1 + Y2) / 2) / RY));
    If RX < RY Then ShapeDist := AbsR(V - 1) * RX Else ShapeDist := AbsR(V - 1) * RY;
   End;
  End;
  SH_ORBS: ShapeDist := AbsR(Dist(PX, PY, X1, Y1) - L);
  SH_ORBP: Begin
   If L < 1 Then ShapeDist := 1E9
   Else Begin
    UX := (X2 - X1) / L; UY := (Y2 - Y1) / L;
    D := DistToSeg(PX, PY, X1 - UX * L, Y1 - UY * L, X1 + UX * L, Y1 + UY * L) - L / 5;
    If D < 0 Then D := 0;
    ShapeDist := D;
   End;
  End;
 Else
  ShapeDist := DistToSeg(PX, PY, X1, Y1, X2, Y2);
 End;
End;

Function FindShapeAt(MX, MY: Integer): Integer;
Var I: Integer; D, Best: Real;
Begin
 FindShapeAt := -1; Best := 5;
 For I := NSh - 1 Downto 0 Do Begin
  D := ShapeDist(I, MX - CvX1, MY - CvY1);
  If D <= Best Then Begin Best := D; FindShapeAt := I; End;
 End;
End;

{ Poignee d'une forme selectionnee sous le curseur ; renvoie la forme et le numero }
Function FindHandleAt(MX, MY: Integer; Var Which: Integer): Integer;
Var I, H, HX, HY, NH: Integer;
Begin
 FindHandleAt := -1;
 For I := 0 To NSh - 1 Do
  If Sh^[I].Sel Then Begin
   If Sh^[I].Kind In [SH_CURVE1, SH_CURVE2] Then NH := 2 Else NH := 1;
   For H := 0 To NH Do Begin
    ShapeHandlePos(I, H, HX, HY);
    If (AbsR(HX - (MX - CvX1)) <= 5) And (AbsR(HY - (MY - CvY1)) <= 5) Then Begin
     FindHandleAt := I; Which := H; Exit;
    End;
   End;
  End;
End;

Function FindAtomNear(X, Y, Tol: Real; Excl: Integer): Integer;
Var I: Integer;
Begin
 FindAtomNear := -1;
 For I := 0 To NAt - 1 Do
  If (I <> Excl) And (Dist(X, Y, At^[I].X, At^[I].Y) <= Tol) Then Begin
   FindAtomNear := I; Exit;
  End;
End;

{ --------------------------------------------------------------------- }
{ Operations d'edition                                                  }
{ --------------------------------------------------------------------- }

{ Atomes cibles : la selection ou, a defaut, l'atome survole }
Function GatherTargets: Integer;
Var I, N: Integer;
Begin
 N := 0;
 For I := 0 To NAt - 1 Do If At^[I].Sel Then Begin Tmp3^[N] := I; Inc(N); End;
 If (N = 0) And (HovAtom >= 0) Then Begin Tmp3^[0] := HovAtom; N := 1; End;
 GatherTargets := N;
End;

Procedure SetAtomElement(I, Z: Integer);
Begin
 At^[I].Z := Z;
 At^[I].Lbl := '';
 If Z <> 1 Then At^[I].Iso := 0;
 TopoChanged;
End;

Procedure ApplyLabel(I: Integer; Const SIn: String);
Var
 S, Base : String;
 K, Z, P : Integer;
 AllH : Boolean;
Begin
 S := TrimStr(SIn);
 If S = '' Then Begin SetAtomElement(I, 6); Touch; Exit; End;
 If S = 'D' Then Begin SetAtomElement(I, 1); At^[I].Iso := 2; Touch; Exit; End;
 { symbole d'element exact }
 If Length(S) <= 2 Then Begin
  If (S[1] >= 'A') And (S[1] <= 'Z') And ((Length(S) = 1) Or ((S[2] >= 'a') And (S[2] <= 'z'))) Then Begin
   K := FindNick(S);
   If (K > 0) And ((S = 'Ac') Or (S = 'Pr')) Then Begin
    At^[I].Z := 0; At^[I].Lbl := Nicks[K].Nm; Touch; Exit;
   End;
   Z := ElemBySymbol(S);
   If Z > 0 Then Begin SetAtomElement(I, Z); Touch; Exit; End;
  End;
 End;
 { element + H : OH, NH2, CH3, SH ... }
 P := 1;
 If Length(S) >= 2 Then Begin
  If (S[2] >= 'a') And (S[2] <= 'z') Then P := 3 Else P := 2;
 End;
 If P <= Length(S) + 1 Then Begin
  Base := Copy(S, 1, P - 1);
  AllH := (P <= Length(S)) And (S[P] = 'H');
  If AllH Then
   For K := P + 1 To Length(S) Do If Not IsDigitCh(S[K]) Then AllH := False;
  If AllH And (ElemBySymbol(Base) > 0) And (FindNick(S) = 0) Then Begin
   SetAtomElement(I, ElemBySymbol(Base)); Touch; Exit;
  End;
 End;
 K := FindNick(S);
 If K > 0 Then Begin
  At^[I].Z := 0; At^[I].Lbl := Nicks[K].Nm;
 End
 Else Begin
  At^[I].Z := 0; At^[I].Lbl := Copy(S, 1, 11);
 End;
 TopoChanged;
 Touch;
End;

Procedure EditAtomLabel(I: Integer);
Var S: String;
Begin
 If At^[I].Lbl <> '' Then S := At^[I].Lbl
 Else If At^[I].Z > 0 Then S := ElSym[At^[I].Z]
 Else S := '';
 If InputString('Etiquette de l''atome', 'Symbole ou groupe (O, Cl, Ph, COOH, OMe, R1 ...) :', S) Then Begin
  PushUndo;
  ApplyLabel(I, S);
 End;
End;

Procedure EditText(I: Integer);
Var S: String;
Begin
 S := Tx^[I].S;
 If InputString('Modifier le texte', 'Texte :', S) Then Begin
  PushUndo;
  If S = '' Then DelText(I) Else Begin Tx^[I].S := Copy(S, 1, 70); Touch; End;
 End;
End;

Procedure CleanOrphans;
{ supprime les atomes de carbone nus sans liaison marques (Mark=16) }
Var I: Integer;
Begin
 UpdateInfo;
 For I := NAt - 1 Downto 0 Do
  If ((At^[I].Mark And 16) <> 0) And (At^[I].Z = 6) And (At^[I].Lbl = '') And
     (At^[I].Chg = 0) And (Inf^[I].Deg = 0) Then DelAtom(I);
 For I := 0 To NAt - 1 Do At^[I].Mark := 0;
End;

Procedure MarkNeighbors(A: Integer);
Var K: Integer;
Begin
 BuildAdj;
 For K := 0 To AdjN^[A] - 1 Do At^[Adj^[A, K]].Mark := At^[Adj^[A, K]].Mark Or 16;
End;

Procedure EraseAt(MX, MY: Integer);
Var A, B, T, S: Integer;
Begin
 UpdateTxtScale;
 A := FindAtomAt(MX, MY, 9);
 If A >= 0 Then Begin
  MarkNeighbors(A);
  DelAtom(A);
  CleanOrphans;
  Exit;
 End;
 B := FindBondAt(MX, MY, 5);
 If B >= 0 Then Begin
  At^[Bd^[B].A].Mark := 16; At^[Bd^[B].B].Mark := 16;
  DelBond(B);
  CleanOrphans;
  Exit;
 End;
 T := FindTextAt(MX, MY);
 If T >= 0 Then Begin DelText(T); Exit; End;
 S := FindShapeAt(MX, MY);
 If S >= 0 Then DelShape(S);
End;

Procedure SelectInRect(X1, Y1, X2, Y2: Real; Add: Boolean);
Var I, TX1, TY1, TX2, TY2: Integer; T: Real;
Begin
 If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T; End;
 If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;
 If Not Add Then ClearSelection;
 For I := 0 To NAt - 1 Do
  If (At^[I].X >= X1) And (At^[I].X <= X2) And (At^[I].Y >= Y1) And (At^[I].Y <= Y2) Then At^[I].Sel := True;
 For I := 0 To NTx - 1 Do Begin
  TextRectScreen(I, TX1, TY1, TX2, TY2);
  If (Tx^[I].X >= X1) And (Tx^[I].X <= X2) And (Tx^[I].Y >= Y1) And (Tx^[I].Y <= Y2) Then Tx^[I].Sel := True;
 End;
 For I := 0 To NSh - 1 Do
  If (Sh^[I].X1 >= X1) And (Sh^[I].X1 <= X2) And (Sh^[I].Y1 >= Y1) And (Sh^[I].Y1 <= Y2) And
     (Sh^[I].X2 >= X1) And (Sh^[I].X2 <= X2) And (Sh^[I].Y2 >= Y1) And (Sh^[I].Y2 <= Y2) Then Sh^[I].Sel := True;
 PropDirty := True;
End;

Function PointInPoly(PX, PY: Integer): Boolean;
Var I, J: Integer; In1: Boolean;
Begin
 In1 := False;
 J := DragNPts - 1;
 For I := 0 To DragNPts - 1 Do Begin
  If ((DragPts[2 * I + 1] > PY) <> (DragPts[2 * J + 1] > PY)) And
     (PX < (DragPts[2 * J] - DragPts[2 * I]) * (PY - DragPts[2 * I + 1]) /
           (DragPts[2 * J + 1] - DragPts[2 * I + 1] + 0.0001) + DragPts[2 * I]) Then In1 := Not In1;
  J := I;
 End;
 PointInPoly := In1;
End;

Procedure SelectInLasso;
Var I: Integer;
Begin
 ClearSelection;
 If DragNPts < 3 Then Exit;
 For I := 0 To NAt - 1 Do
  If PointInPoly(SX(At^[I].X), SY(At^[I].Y)) Then At^[I].Sel := True;
 For I := 0 To NTx - 1 Do
  If PointInPoly(SX(Tx^[I].X), SY(Tx^[I].Y)) Then Tx^[I].Sel := True;
 For I := 0 To NSh - 1 Do
  If PointInPoly(SX(Sh^[I].X1), SY(Sh^[I].Y1)) And PointInPoly(SX(Sh^[I].X2), SY(Sh^[I].Y2)) Then Sh^[I].Sel := True;
 PropDirty := True;
End;

Procedure MoveSelection(DX, DY: Real);
Var I: Integer;
Begin
 For I := 0 To NAt - 1 Do If At^[I].Sel Then Begin At^[I].X := At^[I].X + DX; At^[I].Y := At^[I].Y + DY; End;
 For I := 0 To NTx - 1 Do If Tx^[I].Sel Then Begin Tx^[I].X := Tx^[I].X + DX; Tx^[I].Y := Tx^[I].Y + DY; End;
 For I := 0 To NSh - 1 Do
  If Sh^[I].Sel Then Begin
   Sh^[I].X1 := Sh^[I].X1 + DX; Sh^[I].X2 := Sh^[I].X2 + DX; Sh^[I].CX := Sh^[I].CX + DX;
   Sh^[I].Y1 := Sh^[I].Y1 + DY; Sh^[I].Y2 := Sh^[I].Y2 + DY; Sh^[I].CY := Sh^[I].CY + DY;
  End;
 Touch;
End;

{ Transformation de la selection autour de (CX,CY) : mode 0=rotation, 1=miroir H, 2=miroir V, 3=echelle }
Procedure TransformSel(Mode: Integer; Param, CX, CY: Real);
Var
 I : Integer;
 CA, SA : Real;
 Procedure Tr(Var X, Y: Real);
 Var NX, NY: Real;
 Begin
  Case Mode Of
   0: Begin
    NX := CX + (X - CX) * CA - (Y - CY) * SA;
    NY := CY + (X - CX) * SA + (Y - CY) * CA;
    X := NX; Y := NY;
   End;
   1: X := 2 * CX - X;
   2: Y := 2 * CY - Y;
   3: Begin X := CX + (X - CX) * Param; Y := CY + (Y - CY) * Param; End;
  End;
 End;
Begin
 CA := Cos(Param); SA := Sin(Param);
 For I := 0 To NAt - 1 Do If At^[I].Sel Then Tr(At^[I].X, At^[I].Y);
 For I := 0 To NTx - 1 Do If Tx^[I].Sel Then Tr(Tx^[I].X, Tx^[I].Y);
 For I := 0 To NSh - 1 Do
  If Sh^[I].Sel Then Begin
   Tr(Sh^[I].X1, Sh^[I].Y1); Tr(Sh^[I].X2, Sh^[I].Y2); Tr(Sh^[I].CX, Sh^[I].CY);
  End;
 Touch;
End;

Procedure SelCenter(Var CX, CY: Real; Var Empty: Boolean);
Var X1, Y1, X2, Y2: Real;
Begin
 DocBounds(True, X1, Y1, X2, Y2, Empty);
 CX := (X1 + X2) / 2; CY := (Y1 + Y2) / 2;
End;

{ Nombre d'unites (fragments, textes, formes) selectionnees pour l'alignement }
Var
 UnX1, UnY1, UnX2, UnY2 : Array[0..255] Of Real;
 UnKind, UnIdx : Array[0..255] Of Integer;
 NUn : Integer;

Procedure BuildUnits;
Var I, K, Head, Tail, Cur, Nb, U: Integer;
 Procedure AddPt(U2: Integer; X, Y: Real);
 Begin
  If X < UnX1[U2] Then UnX1[U2] := X;
  If X > UnX2[U2] Then UnX2[U2] := X;
  If Y < UnY1[U2] Then UnY1[U2] := Y;
  If Y > UnY2[U2] Then UnY2[U2] := Y;
 End;
Begin
 NUn := 0;
 BuildAdj;
 For I := 0 To NAt - 1 Do Tmp3^[I] := -1;
 For I := 0 To NAt - 1 Do
  If At^[I].Sel And (Tmp3^[I] < 0) And (NUn < 255) Then Begin
   U := NUn; Inc(NUn);
   UnKind[U] := 0; UnIdx[U] := I;
   UnX1[U] := 1E9; UnY1[U] := 1E9; UnX2[U] := -1E9; UnY2[U] := -1E9;
   Head := 0; Tail := 1; Tmp2^[0] := I; Tmp3^[I] := U;
   While Head < Tail Do Begin
    Cur := Tmp2^[Head]; Inc(Head);
    AddPt(U, At^[Cur].X, At^[Cur].Y);
    For K := 0 To AdjN^[Cur] - 1 Do Begin
     Nb := Adj^[Cur, K];
     If At^[Nb].Sel And (Tmp3^[Nb] < 0) Then Begin Tmp3^[Nb] := U; Tmp2^[Tail] := Nb; Inc(Tail); End;
    End;
   End;
  End;
 For I := 0 To NTx - 1 Do
  If Tx^[I].Sel And (NUn < 255) Then Begin
   U := NUn; Inc(NUn); UnKind[U] := 1; UnIdx[U] := I;
   UnX1[U] := Tx^[I].X; UnY1[U] := Tx^[I].Y;
   UnX2[U] := Tx^[I].X + Length(Tx^[I].S) * 8 * Tx^[I].Siz; UnY2[U] := Tx^[I].Y + 8 * Tx^[I].Siz;
  End;
 For I := 0 To NSh - 1 Do
  If Sh^[I].Sel And (NUn < 255) Then Begin
   U := NUn; Inc(NUn); UnKind[U] := 2; UnIdx[U] := I;
   UnX1[U] := MinR(Sh^[I].X1, Sh^[I].X2); UnX2[U] := MaxR(Sh^[I].X1, Sh^[I].X2);
   UnY1[U] := MinR(Sh^[I].Y1, Sh^[I].Y2); UnY2[U] := MaxR(Sh^[I].Y1, Sh^[I].Y2);
  End;
 
End;

Procedure MoveUnit(U: Integer; DX, DY: Real);
Var I: Integer;
Begin
 Case UnKind[U] Of
  0: For I := 0 To NAt - 1 Do If Tmp3^[I] = U Then Begin At^[I].X := At^[I].X + DX; At^[I].Y := At^[I].Y + DY; End;
  1: Begin Tx^[UnIdx[U]].X := Tx^[UnIdx[U]].X + DX; Tx^[UnIdx[U]].Y := Tx^[UnIdx[U]].Y + DY; End;
  2: With Sh^[UnIdx[U]] Do Begin
   X1 := X1 + DX; X2 := X2 + DX; CX := CX + DX; Y1 := Y1 + DY; Y2 := Y2 + DY; CY := CY + DY;
  End;
 End;
End;

Procedure AlignUnits(Mode: Integer);
{ 0 gauche 1 droite 2 haut 3 bas 4 centre H 5 centre V }
Var U: Integer; T, Cx, Cy: Real;
Begin
 BuildUnits;
 If NUn < 2 Then Exit;
 PushUndo;
 Case Mode Of
  0: Begin T := 1E9; For U := 0 To NUn - 1 Do If UnX1[U] < T Then T := UnX1[U];
      For U := 0 To NUn - 1 Do MoveUnit(U, T - UnX1[U], 0); End;
  1: Begin T := -1E9; For U := 0 To NUn - 1 Do If UnX2[U] > T Then T := UnX2[U];
      For U := 0 To NUn - 1 Do MoveUnit(U, T - UnX2[U], 0); End;
  2: Begin T := 1E9; For U := 0 To NUn - 1 Do If UnY1[U] < T Then T := UnY1[U];
      For U := 0 To NUn - 1 Do MoveUnit(U, 0, T - UnY1[U]); End;
  3: Begin T := -1E9; For U := 0 To NUn - 1 Do If UnY2[U] > T Then T := UnY2[U];
      For U := 0 To NUn - 1 Do MoveUnit(U, 0, T - UnY2[U]); End;
  4: Begin Cx := 0; For U := 0 To NUn - 1 Do Cx := Cx + (UnX1[U] + UnX2[U]) / 2;
      Cx := Cx / NUn;
      For U := 0 To NUn - 1 Do MoveUnit(U, Cx - (UnX1[U] + UnX2[U]) / 2, 0); End;
  5: Begin Cy := 0; For U := 0 To NUn - 1 Do Cy := Cy + (UnY1[U] + UnY2[U]) / 2;
      Cy := Cy / NUn;
      For U := 0 To NUn - 1 Do MoveUnit(U, 0, Cy - (UnY1[U] + UnY2[U]) / 2); End;
 End;
 Touch;
End;

Procedure DistributeUnits(Horiz: Boolean);
Var
 U, V, N : Integer;
 Ord2 : Array[0..255] Of Integer;
 T : Integer;
 Lo, Hi, Gap, Tot, Pos : Real;
 Function Pos0(U2: Integer): Real;
 Begin If Horiz Then Pos0 := UnX1[U2] Else Pos0 := UnY1[U2]; End;
 Function Len0(U2: Integer): Real;
 Begin If Horiz Then Len0 := UnX2[U2] - UnX1[U2] Else Len0 := UnY2[U2] - UnY1[U2]; End;
Begin
 BuildUnits;
 If NUn < 3 Then Exit;
 PushUndo;
 N := NUn;
 For U := 0 To N - 1 Do Ord2[U] := U;
 For U := 1 To N - 1 Do Begin
  T := Ord2[U]; V := U - 1;
  While (V >= 0) And (Pos0(Ord2[V]) > Pos0(T)) Do Begin Ord2[V + 1] := Ord2[V]; Dec(V); End;
  Ord2[V + 1] := T;
 End;
 Lo := Pos0(Ord2[0]);
 Hi := Pos0(Ord2[N - 1]) + Len0(Ord2[N - 1]);
 Tot := 0;
 For U := 0 To N - 1 Do Tot := Tot + Len0(U);
 Gap := (Hi - Lo - Tot) / (N - 1);
 Pos := Lo;
 For U := 0 To N - 1 Do Begin
  If Horiz Then MoveUnit(Ord2[U], Pos - UnX1[Ord2[U]], 0)
  Else MoveUnit(Ord2[U], 0, Pos - UnY1[Ord2[U]]);
  Pos := Pos + Len0(Ord2[U]) + Gap;
 End;
 Touch;
End;

{ Ramene la selection a la longueur de liaison standard }
Procedure StandardBondLength;
Var J, N: Integer; S, F, CX, CY: Real; Empty: Boolean;
Begin
 S := 0; N := 0;
 For J := 0 To NBd - 1 Do
  If At^[Bd^[J].A].Sel And At^[Bd^[J].B].Sel Then Begin
   S := S + Dist(At^[Bd^[J].A].X, At^[Bd^[J].A].Y, At^[Bd^[J].B].X, At^[Bd^[J].B].Y);
   Inc(N);
  End;
 If N = 0 Then Begin
  For J := 0 To NBd - 1 Do Begin
   S := S + Dist(At^[Bd^[J].A].X, At^[Bd^[J].A].Y, At^[Bd^[J].B].X, At^[Bd^[J].B].Y);
   Inc(N);
  End;
  If N = 0 Then Exit;
  For J := 0 To NAt - 1 Do At^[J].Sel := True;
 End;
 F := BOND_LEN / (S / N);
 PushUndo;
 SelCenter(CX, CY, Empty);
 TransformSel(3, F, CX, CY);
End;

{ --------------------------------------------------------------------- }
{ Construction : liaisons, cycles, chaines                              }
{ --------------------------------------------------------------------- }

Procedure ToolBondKind(T: Integer; Var AOrder, ASty: Integer);
Begin
 AOrder := 1; ASty := ST_NORMAL;
 Case T Of
  T_DOUBLE: AOrder := 2;
  T_TRIPLE: AOrder := 3;
  T_WEDGE: ASty := ST_WEDGE;
  T_HASH: ASty := ST_HASH;
  T_BOLD: ASty := ST_BOLD;
  T_WAVY: ASty := ST_WAVY;
  T_DASH: ASty := ST_DASH;
 End;
End;

Function IsBondTool(T: Integer): Boolean;
Begin
 IsBondTool := (T >= T_BOND) And (T <= T_DASH);
End;

Procedure ModifyBond(J, T: Integer);
Var Tmp, AOrder, ASty: Integer;
Begin
 ToolBondKind(T, AOrder, ASty);
 Case T Of
  T_BOND: Begin
   If Bd^[J].Sty <> ST_NORMAL Then Begin Bd^[J].Sty := ST_NORMAL; Bd^[J].Order := 1; End
   Else Begin Inc(Bd^[J].Order); If Bd^[J].Order > 3 Then Bd^[J].Order := 1; End;
  End;
  T_DOUBLE: Begin
   If (Bd^[J].Order = 2) And (Bd^[J].Sty = ST_NORMAL) Then Bd^[J].DPos := (Bd^[J].DPos + 1) Mod 4
   Else Begin Bd^[J].Order := 2; Bd^[J].Sty := ST_NORMAL; End;
  End;
  T_TRIPLE: Begin
   If (Bd^[J].Order = 3) And (Bd^[J].Sty = ST_NORMAL) Then Bd^[J].Order := 1
   Else Begin Bd^[J].Order := 3; Bd^[J].Sty := ST_NORMAL; End;
  End;
  T_WEDGE, T_HASH: Begin
   If Bd^[J].Sty = ASty Then Begin
    Tmp := Bd^[J].A; Bd^[J].A := Bd^[J].B; Bd^[J].B := Tmp;
   End
   Else Begin Bd^[J].Sty := ASty; Bd^[J].Order := 1; End;
  End;
  T_BOLD, T_WAVY, T_DASH: Begin
   If Bd^[J].Sty = ASty Then Bd^[J].Sty := ST_NORMAL
   Else Begin Bd^[J].Sty := ASty; Bd^[J].Order := 1; End;
  End;
 End;
 TopoChanged;
 Touch;
End;

{ Position suggeree d'un nouvel atome lie a A (zigzag, plus grand angle libre) }
Procedure SuggestPos(A: Integer; Var X, Y: Real);
Var F, Q, SaveH, SaveT: Integer;
Begin
 F := NewAtom(0, 0, 6);
 If F < 0 Then Begin X := At^[A].X + BOND_LEN; Y := At^[A].Y; Exit; End;
 NewBond(A, F, 1, ST_NORMAL);
 BuildAdj;
 For Q := 0 To NAt - 1 Do If Q <> F Then At^[Q].Mark := 2 Else At^[Q].Mark := 0;
 SaveH := LQH; SaveT := LQT;
 LQH := 0; LQT := 0;
 PlaceChildren(A);
 LQH := SaveH; LQT := SaveT;
 X := At^[F].X; Y := At^[F].Y;
 For Q := 0 To NAt - 1 Do At^[Q].Mark := 0;
 DelAtom(F);
End;

Procedure AddBondFromAtom(A, AOrder, ASty: Integer);
Var X, Y: Real; N: Integer;
Begin
 SuggestPos(A, X, Y);
 N := FindAtomNear(X, Y, 0.4 * BOND_LEN, A);
 If N < 0 Then N := NewAtom(X, Y, 6);
 If N >= 0 Then NewBond(A, N, AOrder, ASty);
End;

Function ObtainAtom(X, Y: Real): Integer;
Var N: Integer;
Begin
 N := FindAtomNear(X, Y, 0.35 * BOND_LEN, -1);
 If N < 0 Then N := NewAtom(X, Y, 6);
 ObtainAtom := N;
End;

Function RingStartAngle(N: Integer): Real;
Begin
 If ((N Mod 2) = 1) Or (N = 6) Then RingStartAngle := -Pi / 2
 Else RingStartAngle := -Pi / 2 - Pi / N;
End;

{ Dessine un cycle de N atomes ; Tool decide des liaisons doubles }
Procedure BuildRing(N: Integer; Tool: Integer; PX, PY: Real; HitA, HitB: Integer;
                    SideX, SideY: Real);
Var
 VX, VY : Array[0..9] Of Real;
 VI : Array[0..9] Of Integer;
 K, A, B, K2, J, Shift : Integer;
 Ok2 : Boolean;
 R, Ap, CX, CY, Th0, S, ThB, MX, MY, UX, UY, L, SumX, SumY, Q : Real;
 Dbl : Array[0..9] Of Boolean;
Begin
 R := BOND_LEN / (2 * Sin(Pi / N));
 For K := 0 To N - 1 Do VI[K] := -1;
 Shift := 0;
 If HitB >= 0 Then Begin
  A := Bd^[HitB].A; B := Bd^[HitB].B;
  MX := (At^[A].X + At^[B].X) / 2; MY := (At^[A].Y + At^[B].Y) / 2;
  L := Dist(At^[A].X, At^[A].Y, At^[B].X, At^[B].Y);
  If L < 0.1 Then Exit;
  UX := -(At^[B].Y - At^[A].Y) / L; UY := (At^[B].X - At^[A].X) / L;
  If (SideX - MX) * UX + (SideY - MY) * UY < 0 Then Begin UX := -UX; UY := -UY; End;
  Ap := BOND_LEN / (2 * Tan(Pi / N));
  CX := MX + UX * Ap; CY := MY + UY * Ap;
  Th0 := Atan2(At^[A].Y - CY, At^[A].X - CX);
  ThB := Atan2(At^[B].Y - CY, At^[B].X - CX);
  S := 1; If NormAng(ThB - Th0) < 0 Then S := -1;
  VI[0] := A; VI[1] := B;
  { un cycle aromatique sur une liaison simple isolee : la liaison devient double }
  If (Tool = T_BENZENE) And (Bd^[HitB].Order = 1) And (Bd^[HitB].Sty = ST_NORMAL) Then Begin
   Ok2 := True;
   For K := 0 To NBd - 1 Do
    If (K <> HitB) And (Bd^[K].Order = 2) And
       ((Bd^[K].A = A) Or (Bd^[K].B = A) Or (Bd^[K].A = B) Or (Bd^[K].B = B)) Then Ok2 := False;
   If Ok2 Then Bd^[HitB].Order := 2;
  End;
 End
 Else If HitA >= 0 Then Begin
  SumX := 0; SumY := 0;
  BuildAdj;
  For K := 0 To AdjN^[HitA] - 1 Do Begin
   Q := Dist(At^[HitA].X, At^[HitA].Y, At^[Adj^[HitA, K]].X, At^[Adj^[HitA, K]].Y);
   If Q > 0.01 Then Begin
    SumX := SumX + (At^[Adj^[HitA, K]].X - At^[HitA].X) / Q;
    SumY := SumY + (At^[Adj^[HitA, K]].Y - At^[HitA].Y) / Q;
   End;
  End;
  L := Sqrt(SumX * SumX + SumY * SumY);
  If L < 0.1 Then Begin UX := 0; UY := -1; End Else Begin UX := -SumX / L; UY := -SumY / L; End;
  CX := At^[HitA].X + UX * R; CY := At^[HitA].Y + UY * R;
  Th0 := Atan2(At^[HitA].Y - CY, At^[HitA].X - CX);
  S := 1;
  VI[0] := HitA;
 End
 Else Begin
  CX := PX; CY := PY;
  Th0 := RingStartAngle(N);
  S := 1;
 End;
 For K := 0 To N - 1 Do Begin
  VX[K] := CX + R * Cos(Th0 + S * K * 2 * Pi / N);
  VY[K] := CY + R * Sin(Th0 + S * K * 2 * Pi / N);
 End;
 For K := 0 To N - 1 Do
  If VI[K] < 0 Then VI[K] := ObtainAtom(VX[K], VY[K]);
 For K := 0 To N - 1 Do If VI[K] < 0 Then Exit;
 { liaisons doubles }
 For K := 0 To N - 1 Do Dbl[K] := False;
 Case Tool Of
  T_BENZENE: For K := 0 To N - 1 Do Dbl[K] := ((K + Shift) Mod 2) = 0;
  T_CPD: Begin Dbl[1] := True; Dbl[3] := True; End;
 End;
 For K := 0 To N - 1 Do Begin
  K2 := (K + 1) Mod N;
  J := FindBond(VI[K], VI[K2]);
  If J < 0 Then Begin
   If Dbl[K] Then NewBond(VI[K], VI[K2], 2, ST_NORMAL) Else NewBond(VI[K], VI[K2], 1, ST_NORMAL);
  End;
 End;
 TopoChanged;
 Touch;
End;

Function RingSizeOfTool(T: Integer): Integer;
Begin
 Case T Of
  T_RING3: RingSizeOfTool := 3;
  T_RING4: RingSizeOfTool := 4;
  T_RING5, T_CPD: RingSizeOfTool := 5;
  T_RING6, T_BENZENE: RingSizeOfTool := 6;
  T_RING7: RingSizeOfTool := 7;
  T_RING8: RingSizeOfTool := 8;
 Else RingSizeOfTool := 6;
 End;
End;

Procedure CommitChain(StartA: Integer; Px, Py: Real);
Var N, K, Prev, A: Integer;
Begin
 N := ChainPoints(Px, Py, DragLX, DragLY);
 If StartA >= 0 Then Prev := StartA Else Prev := ObtainAtom(ChainX[0], ChainY[0]);
 For K := 1 To N Do Begin
  A := ObtainAtom(ChainX[K], ChainY[K]);
  If (A >= 0) And (Prev >= 0) Then NewBond(Prev, A, 1, ST_NORMAL);
  Prev := A;
 End;
End;

Procedure CommitBondDrag(MX, MY: Integer; BondHit: Integer);
Var
 AOrder, ASty, S, E, B : Integer;
 SXa, SYa, EX, EY : Real;
 Moved : Boolean;
Begin
 ToolBondKind(CurTool, AOrder, ASty);
 Moved := DragMoved;
 If Not Moved Then Begin
  If DragAtom >= 0 Then AddBondFromAtom(DragAtom, AOrder, ASty)
  Else If BondHit >= 0 Then ModifyBond(BondHit, CurTool)
  Else Begin
   SXa := DragSX; SYa := DragSY;
   S := ObtainAtom(SXa, SYa);
   E := ObtainAtom(SXa + BOND_LEN * Cos(-Pi / 6), SYa + BOND_LEN * Sin(-Pi / 6));
   If (S >= 0) And (E >= 0) Then NewBond(S, E, AOrder, ASty);
  End;
  Exit;
 End;
 If DragAtom >= 0 Then S := DragAtom Else S := ObtainAtom(DragSX, DragSY);
 If S < 0 Then Exit;
 SXa := At^[S].X; SYa := At^[S].Y;
 E := FindAtomAt(MX, MY, 9);
 If (E >= 0) And (E <> S) Then Begin
  EX := At^[E].X; EY := At^[E].Y;
 End
 Else Begin
  E := -1;
  SnapEnd(SXa, SYa, DragLX, DragLY, Pi / 6, OptFixLen, EX, EY);
  E := ObtainAtom(EX, EY);
 End;
 If (E < 0) Or (E = S) Then Exit;
 B := FindBond(S, E);
 If B >= 0 Then ModifyBond(B, CurTool)
 Else NewBond(S, E, AOrder, ASty);
End;

Procedure ApplyColor(Col: Byte);
Var I, J: Integer; Any: Boolean;
Begin
 CurColor := Col;
 Any := AnySelected;
 If Not Any Then Exit;
 PushUndo;
 For I := 0 To NAt - 1 Do If At^[I].Sel Then At^[I].Col := Col;
 For J := 0 To NBd - 1 Do
  If At^[Bd^[J].A].Sel And At^[Bd^[J].B].Sel Then Bd^[J].Col := Col;
 For I := 0 To NTx - 1 Do If Tx^[I].Sel Then Tx^[I].Col := Col;
 For I := 0 To NSh - 1 Do If Sh^[I].Sel Then Sh^[I].Col := Col;
 Touch;
End;

{ --------------------------------------------------------------------- }
{ Vue : zoom, defilement                                                }
{ --------------------------------------------------------------------- }

Procedure ZoomAt(Factor, DX, DY: Real);
Var NewZ: Real;
Begin
 NewZ := ClampR(Zoom * Factor, 0.25, 4.0);
 ScrollX := DX - (DX - ScrollX) * Zoom / NewZ;
 ScrollY := DY - (DY - ScrollY) * Zoom / NewZ;
 Zoom := NewZ;
 UpdateTxtScale;
 ClampScroll;
 NeedRedraw := True;
End;

Procedure ZoomCenter(Factor: Real);
Var CX, CY: Real;
Begin
 ViewCenter(CX, CY);
 ZoomAt(Factor, CX, CY);
End;

Procedure SetZoom100;
Var CX, CY: Real;
Begin
 ViewCenter(CX, CY);
 ZoomAt(1.0 / Zoom, CX, CY);
End;

Procedure FitToWindow;
Var X1, Y1, X2, Y2, Z1, Z2, W, H: Real; Empty: Boolean;
Begin
 DocBounds(False, X1, Y1, X2, Y2, Empty);
 If Empty Then Begin Zoom := 1; ScrollX := 0; ScrollY := 0; NeedRedraw := True; Exit; End;
 W := X2 - X1 + 80; H := Y2 - Y1 + 80;
 Z1 := (CvX2 - CvX1 + 1) / W; Z2 := (CvY2 - CvY1 + 1) / H;
 Zoom := ClampR(MinR(Z1, Z2), 0.25, 1.6);
 UpdateTxtScale;
 ScrollX := (X1 + X2) / 2 - (CvX2 - CvX1 + 1) / 2 / Zoom;
 ScrollY := (Y1 + Y2) / 2 - (CvY2 - CvY1 + 1) / 2 / Zoom;
 ClampScroll;
 NeedRedraw := True;
End;

{ --------------------------------------------------------------------- }
{ Fichiers : operations de haut niveau                                  }
{ --------------------------------------------------------------------- }

Procedure NewDocument;
Begin
 If Modified And (NAt + NTx + NSh > 0) Then
  If Not ConfirmBox('Nouveau', 'Abandonner les modifications ?') Then Exit;
 ClearDoc;
 ClearHistory;
 DocName := '';
 Modified := False;
 Zoom := 1; ScrollX := 0; ScrollY := 0;
 NeedRedraw := True;
End;

Procedure LoadAnyFile(Const FN: String);
Var Ext: String; OK: Boolean;
Begin
 Ext := ExtractExt(FN);
 PushUndo;
 ClearSelection;
 OK := False;
 If Ext = '.CDT' Then Begin
  NAt := 0; NBd := 0; NTx := 0; NSh := 0;
  OK := LoadCDT(FN);
  If OK Then DocName := FN;
 End
 Else If (Ext = '.MOL') Or (Ext = '.SDF') Then Begin
  OK := LoadMOL(FN);
  If OK Then DocName := '';
 End
 Else If (Ext = '.SMI') Or (Ext = '.SMILES') Then Begin
  OK := LoadSMILESFile(FN);
 End
 Else Begin
  NAt := 0; NBd := 0; NTx := 0; NSh := 0;
  OK := LoadCDT(FN);
  If OK Then DocName := FN;
 End;
 If Not OK Then ShowMessage('Ouvrir', 'Impossible de lire le fichier :|' + FN)
 Else Begin
  Modified := False;
  FitToWindow;
 End;
End;

Procedure DoOpenFile;
Var FN: String;
Begin
 FN := '';
 If FileOpenDialog('Ouvrir', FN, '*.CDT;*.MOL;*.SDF;*.SMI') Then Begin
  If Modified And (NAt + NTx + NSh > 0) Then
   If Not ConfirmBox('Ouvrir', 'Abandonner les modifications ?') Then Exit;
  LoadAnyFile(FN);
 End;
End;

Procedure DoSaveAs;
Var FN: String;
Begin
 FN := DocName;
 If FN = '' Then FN := 'SANSNOM.CDT';
 If FileSaveDialog('Enregistrer sous', FN) Then Begin
  If ExtractExt(FN) = '' Then FN := FN + '.CDT';
  If SaveCDT(FN) Then Begin DocName := FN; Modified := False; StatusMsg := 'Enregistre : ' + FN; End
  Else ShowMessage('Enregistrer', 'Echec de l''ecriture du fichier.');
 End;
End;

Procedure DoSave;
Begin
 If DocName = '' Then DoSaveAs
 Else If SaveCDT(DocName) Then Begin Modified := False; StatusMsg := 'Enregistre : ' + DocName; End
 Else ShowMessage('Enregistrer', 'Echec de l''ecriture du fichier.');
End;

{ Ecrit l'InChI calcule (InBuf) dans un fichier texte }
Function SaveInChI(Const FN: String): Boolean;
Var F: Text; I: Integer; S: String;
Begin
 {$I-}
 Assign(F, FN); Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Begin SaveInChI := False; Exit; End;
 S := '';
 For I := 0 To InLen - 1 Do S := S + InBuf^[I];
 WriteLn(F, S);
 Close(F);
 SaveInChI := True;
End;

Procedure DoExport(Kind: Integer);
Var FN, Def: String;
Begin
 Case Kind Of
  0: Def := 'SORTIE.MOL';
  1: Def := 'SORTIE.SMI';
  2: Def := 'SORTIE.SVG';
  4: Def := 'SORTIE.TXT';
 Else Def := 'SORTIE.BMP';
 End;
 FN := Def;
 If Not FileSaveDialog('Exporter', FN) Then Exit;
 Case Kind Of
  0: If SaveMOL(FN) Then StatusMsg := 'Exporte : ' + FN Else ShowMessage('Exporter', 'Echec de l''ecriture.');
  1: Begin
   WriteSmiles(False);
   If SaveSMILES(FN) Then StatusMsg := 'Exporte : ' + FN Else ShowMessage('Exporter', 'Echec de l''ecriture.');
  End;
  2: If SaveSVG(FN) Then StatusMsg := 'Exporte : ' + FN Else ShowMessage('Exporter', 'Echec de l''ecriture.');
  4: Begin
   If Not ComputeInChI Then ShowMessage('InChI', InMsg)
   Else If SaveInChI(FN) Then StatusMsg := 'Exporte : ' + FN
   Else ShowMessage('Exporter', 'Echec de l''ecriture.');
  End;
  3: Begin
   ClearSelection; HovAtom := -1; HovBond := -1;
   RedrawAll;
   If SaveBMP(FN) Then StatusMsg := 'Exporte : ' + FN Else ShowMessage('Exporter', 'Echec de l''ecriture.');
  End;
 End;
End;

Procedure ImportMolDialog;
Var FN: String;
Begin
 FN := '';
 If FileOpenDialog('Importer MOL', FN, '*.MOL;*.SDF') Then Begin
  PushUndo; ClearSelection;
  If LoadMOL(FN) Then FitToWindow
  Else ShowMessage('Importer', 'Fichier MOL invalide.');
 End;
End;

Procedure ImportSmilesDialog;
Var S: String; CX, CY: Real;
Begin
 S := '';
 If InputString('Importer SMILES', 'Chaine SMILES (ex: CC(=O)Oc1ccccc1C(O)=O) :', S) And (TrimStr(S) <> '') Then Begin
  PushUndo;
  ViewCenter(CX, CY);
  If Not AddSmilesAt(TrimStr(S), CX, CY) Then Begin
   DoUndo; ClearRedo;
   ShowMessage('Importer SMILES', 'SMILES invalide.');
  End;
 End;
End;

Procedure InsertNameDialog;
Var S, Sm: String; CX, CY: Real;
Begin
 S := '';
 If InputString('Nom -> Structure', 'Nom du compose (ex: aspirine, caffeine, glucose) :', S) Then Begin
  If StructureFromName(S, Sm) Then Begin
   PushUndo;
   ViewCenter(CX, CY);
   If Not AddSmilesAt(Sm, CX, CY) Then Begin DoUndo; ClearRedo; ShowMessage('Nom -> Structure', 'Erreur interne de lecture.'); End;
  End
  Else ShowMessage('Nom -> Structure', 'Compose inconnu :|' + S + '|Le dictionnaire contient les composes courants.');
 End;
End;

Procedure TemplateDialog;
Var I, P: Integer; CX, CY: Real;
Begin
 NTL := 0;
 For I := 1 To NTPL Do AddTL(Tpl[I].Nm);
 P := ListDialog('Modeles de structures', True);
 If P >= 0 Then Begin
  PushUndo;
  ViewCenter(CX, CY);
  If Not AddSmilesAt(Tpl[P + 1].Sm, CX, CY) Then Begin DoUndo; ClearRedo; End;
 End;
End;

Procedure StructureToName;
Var Nm: String;
Begin
 If NAt = 0 Then Begin ShowMessage('Structure -> Nom', 'Dessinez d''abord une structure.'); Exit; End;
 If NameFromStructure(Nm) Then
  ShowMessage('Structure -> Nom', 'Nom : ' + Nm)
 Else
  ShowMessage('Structure -> Nom', 'Structure absente du dictionnaire.|(composes courants uniquement)');
End;

Procedure ShowSmiles;
Var S: String;
Begin
 WriteSmiles(CountSelAtoms > 0);
 S := SmBufStr;
 If S = '' Then ShowMessage('SMILES', 'Aucune structure.')
 Else Begin
  ClipSmiles := S;
  If Length(S) > 60 Then ShowMessage('SMILES', Copy(S, 1, 60) + '|' + Copy(S, 61, 60) + '|' + Copy(S, 121, 60) + '|' + Copy(S, 181, 60))
  Else ShowMessage('SMILES', S);
 End;
End;

{ Affiche l'InChI de la structure }
Procedure ShowInChI;
Var I: Integer; Isot: Boolean; S: String;
Begin
 If Not ComputeInChI Then Begin ShowMessage('InChI', InMsg); Exit; End;
 NTL := 0;
 AddTL('InChI standard (IUPAC) de la structure :');
 AddTL('');
 S := '';
 For I := 0 To InLen - 1 Do Begin
  S := S + InBuf^[I];
  If Length(S) >= 58 Then Begin AddTL(S); S := ''; End;
 End;
 If S <> '' Then AddTL(S);
 Isot := False;
 For I := 0 To NAt - 1 Do If At^[I].Iso > 0 Then Isot := True;
 AddTL('');
 AddTL('Couches : formule, connectivite (/c), hydrogenes (/h),');
 AddTL('charge (/q), protons (/p) et stereochimie (/b /t /m /s).');
 AddTL('Voir Fichier > Exporter InChI.');
 If Isot Then AddTL('Attention : les isotopes ne sont pas encodes.');
 ListDialog('InChI', False);
End;

{ Liste les descripteurs stereochimiques (R/S, E/Z) de la structure }
Procedure ShowStereo;
Var I, J, NR, NE : Integer; S : String;
Begin
 ComputeStereo;
 NTL := 0;
 AddTL('Descripteurs stereochimiques (regles CIP 1 a 5) :');
 AddTL('');
 NR := 0; NE := 0;
 For I := 0 To NAt - 1 Do
  If StC^[I] <> #0 Then Begin
   Inc(NR);
   S := '  Atome ' + IntToStr(I + 1) + ' (' + ElSym[At^[I].Z] + ') : ' + StC^[I];
   If StC^[I] = 'R' Then S := S + '  (rectus)' Else S := S + '  (sinister)';
   AddTL(S);
  End;
 For J := 0 To NBd - 1 Do
  If EzC^[J] <> #0 Then Begin
   Inc(NE);
   S := '  Liaison ' + IntToStr(Bd^[J].A + 1) + '=' + IntToStr(Bd^[J].B + 1) + ' : ' + EzC^[J];
   If EzC^[J] = 'E' Then S := S + '  (entgegen)' Else S := S + '  (zusammen)';
   AddTL(S);
  End;
 If NR + NE = 0 Then Begin
  AddTL('  Aucun descripteur : dessinez des liaisons en coin plein ou');
  AddTL('  hachure (centre a l''extremite fine) pour specifier un centre R/S,');
  AddTL('  ou une liaison double substituee pour obtenir E/Z.');
 End
 Else Begin
  AddTL('');
  AddTL(IntToStr(NR) + ' centre(s) R/S, ' + IntToStr(NE) + ' liaison(s) E/Z.');
 End;
 AddTL('');
 AddTL('Minuscules r / s : centres pseudo-asymetriques. Les centres dont');
 AddTL('les substituants restent indiscernables apres les regles 1 a 5');
 AddTL('ne sont pas etiquetes.');
 ListDialog('Stereochimie', False);
End;

Procedure InsertTextBelow(Const S: String);
Var X1, Y1, X2, Y2: Real; Empty: Boolean; T: Integer;
Begin
 If S = '' Then Exit;
 PushUndo;
 DocBounds(False, X1, Y1, X2, Y2, Empty);
 If Empty Then ViewCenter(X1, Y1) Else Begin X1 := (X1 + X2) / 2 - Length(S) * 4 * TextSize; Y1 := Y2 + 24; End;
 T := NewText(X1, Y1, S);
 If T >= 0 Then Begin ClearSelection; Tx^[T].Sel := True; End;
End;

{ --------------------------------------------------------------------- }
{ Aide                                                                  }
{ --------------------------------------------------------------------- }

Procedure ShowHelp(Kind: Integer);
Begin
 NTL := 0;
 Case Kind Of
  0: Begin
   AddTL('GUIDE D''UTILISATION - ChemDraw Clone');
   AddTL('');
   AddTL('Palette de gauche : cliquer sur un outil.');
   AddTL(' Selection / Lasso : choisir, deplacer (glisser), double-clic = fragment');
   AddTL(' Liaisons : cliquer sur un atome pour prolonger, glisser pour tracer,');
   AddTL('   cliquer sur une liaison pour changer son ordre / son style.');
   AddTL(' Chaine : glisser, le nombre de liaisons est affiche.');
   AddTL(' Cycles : cliquer dans le vide (centre), sur un atome (substituant)');
   AddTL('   ou sur une liaison (cycle fusionne du cote du curseur).');
   AddTL(' Texte : clic sur un atome = etiquette (O, Cl, Ph, COOH, OMe ...),');
   AddTL('   clic dans le vide = texte libre.');
   AddTL(' Fleches / formes : glisser du point de depart au point d''arrivee.');
   AddTL(' Gomme : cliquer ou glisser pour effacer. Rotation : glisser.');
   AddTL('');
   AddTL('Touches (survol d''un atome) : c n o s p f h i l(Cl) b(Br) -> element');
   AddTL('   + / - = charge ,  . = radical ,  t ou Entree = etiquette');
   AddTL('Touches (survol d''une liaison) : 1 2 3 = ordre, w = coin plein,');
   AddTL('   y = coin hachure, v = ondulee, x = grasse, d = pointillee');
   AddTL('Suppr / Retour arriere : efface le survol ou la selection.');
   AddTL('');
   AddTL('Menu Analyse : formule, masse, spectre de masse, RMN 1H / 13C,');
   AddTL('   InChI standard, SMILES (avec @ / @@ et / \),');
   AddTL('   stereochimie R/S et E/Z (aussi Affichage > Stereochimie),');
   AddTL('   structure -> nom, nom -> structure (dictionnaire de composes).');
   AddTL('Menu Structure > Nettoyer : remet la structure en forme (Ctrl+L).');
   AddTL('Fichier : CDT (natif), MOL, SMILES, InChI, SVG, BMP.');
  End;
  1: Begin
   AddTL('RACCOURCIS CLAVIER');
   AddTL('');
   AddTL('Ctrl+N  Nouveau            Ctrl+O  Ouvrir          Ctrl+S  Enregistrer');
   AddTL('Ctrl+Z  Annuler            Ctrl+Y  Retablir');
   AddTL('Ctrl+X  Couper             Ctrl+C  Copier          Ctrl+V  Coller');
   AddTL('Ctrl+A  Tout selectionner  Ctrl+D  Dupliquer       Ctrl+L  Nettoyer');
   AddTL('Suppr   Effacer            Echap   Deselectionner / annuler');
   AddTL('PgUp / PgDn  Zoom          Home    Ajuster         F5  Zoom 100 %');
   AddTL('Fleches  Deplacer la selection (ou la vue)');
   AddTL('F1  Aide    F2  Proprietes    F3  Analyse detaillee   F4  Modeles');
   AddTL('F6  Grille  F9 / F10  Barre de menus     Alt+X  Quitter');
  End;
  2: Begin
   AddTL('GROUPES D''ATOMES RECONNUS (outil Texte sur un atome)');
   AddTL('');
   AddTL('Me Et Pr iPr Bu iBu tBu Ph Bn Cy Ac Bz');
   AddTL('OMe OEt OAc OBn OPh COOH CO2H CO2Me CO2Et CHO CONH2 CH2OH');
   AddTL('CN NO2 CF3 CCl3 NMe2 NHMe NHAc SMe SO2Me SO3H');
   AddTL('Boc Cbz Ts Ms Tf TMS TBS OTs OMs OTf');
   AddTL('');
   AddTL('Ces groupes se developpent en atomes reels avec :');
   AddTL('   Structure > Developper l''etiquette.');
   AddTL('Tout autre texte (R, R1, X, Ar ...) est une etiquette generique.');
  End;
 End;
 ListDialog('Aide', False);
End;

Procedure ShowAbout;
Begin
 ShowMessage('A propos', PROG_TITLE + '|Version ' + PROG_VERSION +
  '|Clone de ChemDraw ecrit en Pascal|Turbo Pascal 7 / Free Pascal|https://www.gladir.com/qchimie');
End;

{ --------------------------------------------------------------------- }
{ Commandes de menu                                                    }
{ --------------------------------------------------------------------- }

Var
 DragBondHit : Integer;
 DragPressX, DragPressY : Integer;
 EditVer     : LongInt;
 HandX0, HandY0 : Real;
 ScrollGrab  : Integer;
 TextBuf     : String;

Procedure ChangeTargets(Mode, Value: Integer);
{ Mode : 0 element, 1 charge (+delta), 2 radical, 3 reinitialiser }
Var N, K, I: Integer;
Begin
 N := GatherTargets;
 If N = 0 Then Begin StatusMsg := 'Survolez ou selectionnez un atome.'; Exit; End;
 PushUndo;
 For K := 0 To N - 1 Do Begin
  I := Tmp3^[K];
  Case Mode Of
   0: SetAtomElement(I, Value);
   1: Begin
    If (At^[I].Chg + Value >= -4) And (At^[I].Chg + Value <= 4) Then At^[I].Chg := At^[I].Chg + Value;
   End;
   2: At^[I].Rad := (At^[I].Rad + 1) Mod 3;
   3: Begin At^[I].Chg := 0; At^[I].Rad := 0; End;
  End;
 End;
 TopoChanged;
 Touch;
End;

Procedure SetBondTargets(AOrder, ASty: Integer);
Var J, N: Integer; Any: Boolean;
Begin
 N := 0;
 For J := 0 To NBd - 1 Do
  If (At^[Bd^[J].A].Sel And At^[Bd^[J].B].Sel) Or (J = HovBond) Then Inc(N);
 If N = 0 Then Begin StatusMsg := 'Survolez ou selectionnez une liaison.'; Exit; End;
 PushUndo;
 Any := False;
 For J := 0 To NBd - 1 Do
  If (At^[Bd^[J].A].Sel And At^[Bd^[J].B].Sel) Or (J = HovBond) Then Begin
   Bd^[J].Order := AOrder; Bd^[J].Sty := ASty; Any := True;
  End;
 If Any Then Begin TopoChanged; Touch; End;
End;

Procedure CycleDoublePos;
Var J: Integer;
Begin
 PushUndo;
 For J := 0 To NBd - 1 Do
  If ((At^[Bd^[J].A].Sel And At^[Bd^[J].B].Sel) Or (J = HovBond)) And (Bd^[J].Order = 2) Then
   Bd^[J].DPos := (Bd^[J].DPos + 1) Mod 4;
 Touch;
End;

Procedure ReverseBonds;
Var J, T: Integer;
Begin
 PushUndo;
 For J := 0 To NBd - 1 Do
  If (At^[Bd^[J].A].Sel And At^[Bd^[J].B].Sel) Or (J = HovBond) Then Begin
   T := Bd^[J].A; Bd^[J].A := Bd^[J].B; Bd^[J].B := T;
  End;
 Touch;
End;

Procedure ElementDialogApply;
Var Z: Integer;
Begin
 Z := PeriodicDialog;
 If Z > 0 Then Begin
  CurElem := Z;
  If GatherTargets > 0 Then ChangeTargets(0, Z);
 End;
End;

Procedure ExpandTargets;
Var I, Guard: Integer; Any: Boolean;
Begin
 Any := CountSelAtoms > 0;
 PushUndo;
 Guard := 0;
 I := 0;
 While (I < NAt) And (Guard < 500) Do Begin
  If (At^[I].Lbl <> '') And (FindNick(At^[I].Lbl) > 0) And (At^[I].Sel Or Not Any) Then Begin
   ExpandLabel(I); Inc(Guard);
  End
  Else Inc(I);
 End;
 Touch;
End;

Procedure DoRotateDialog;
Var S: String; A: Real; CX, CY: Real; Empty: Boolean;
Begin
 S := '15';
 If InputString('Rotation libre', 'Angle en degres (positif = sens horaire) :', S) Then Begin
  A := StrToRealDef(S, 0) * Pi / 180;
  PushUndo;
  SelCenter(CX, CY, Empty);
  If Not Empty Then TransformSel(0, A, CX, CY);
 End;
End;

Procedure DoScaleDialog;
Var S: String; F: Real; CX, CY: Real; Empty: Boolean;
Begin
 S := '120';
 If InputString('Mettre a l''echelle', 'Pourcentage (100 = inchange) :', S) Then Begin
  F := StrToRealDef(S, 100) / 100;
  If (F < 0.1) Or (F > 10) Then Exit;
  PushUndo;
  SelCenter(CX, CY, Empty);
  If Not Empty Then TransformSel(3, F, CX, CY);
 End;
End;

Procedure NeedSelMsg;
Begin
 ShowMessage('Objet', 'Selectionnez d''abord des objets.');
End;

Procedure DispatchMenu(M, I: Integer);
Var
 CX, CY : Real;
 Empty : Boolean;
 J, N : Integer;
 S : String;
 C : TCounts;
 Chg : Integer;
 Generic : Boolean;
Begin
 UpdateInfo;
 RedrawAll;
 Case M Of
  MENU_FILE: Case I Of
   0: NewDocument;
   1: DoOpenFile;
   2: DoSave;
   3: DoSaveAs;
   5: ImportSmilesDialog;
   6: ImportMolDialog;
   7: DoExport(0);
   8: DoExport(1);
   9: DoExport(4);
   10: DoExport(2);
   11: DoExport(3);
   13: Running := False;
  End;
  MENU_EDIT: Case I Of
   0: DoUndo;
   1: DoRedo;
   3: If AnySelected Then Begin CopySelection; PushUndo; DeleteSelected; End;
   4: If AnySelected Then CopySelection;
   5: If ClipValid Then Begin PushUndo; PasteClipboard(24, 24); End;
   6: If AnySelected Then Begin PushUndo; DeleteSelected; End;
   8: Begin
    For J := 0 To NAt - 1 Do At^[J].Sel := True;
    For J := 0 To NTx - 1 Do Tx^[J].Sel := True;
    For J := 0 To NSh - 1 Do Sh^[J].Sel := True;
    PropDirty := True;
   End;
   9: ClearSelection;
   10: Begin
    For J := 0 To NAt - 1 Do At^[J].Sel := Not At^[J].Sel;
    For J := 0 To NTx - 1 Do Tx^[J].Sel := Not Tx^[J].Sel;
    For J := 0 To NSh - 1 Do Sh^[J].Sel := Not Sh^[J].Sel;
    PropDirty := True;
   End;
   11: Begin
    For J := 0 To NAt - 1 Do Tmp3^[J] := Ord(At^[J].Sel);
    For J := 0 To NAt - 1 Do If Tmp3^[J] = 1 Then SelectFragment(J, True);
   End;
   13: ShowSmiles;
   14: Begin
    S := ClipSmiles;
    If InputString('Coller un SMILES', 'Chaine SMILES :', S) And (TrimStr(S) <> '') Then Begin
     PushUndo;
     ViewCenter(CX, CY);
     If Not AddSmilesAt(TrimStr(S), CX, CY) Then Begin DoUndo; ClearRedo; ShowMessage('SMILES', 'SMILES invalide.'); End;
    End;
   End;
   16: If AnySelected Then Begin CopySelection; PushUndo; PasteClipboard(24, 24); End;
  End;
  MENU_VIEW: Case I Of
   0: ZoomCenter(1.25);
   1: ZoomCenter(0.8);
   2: SetZoom100;
   3: FitToWindow;
   5: OptGrid := Not OptGrid;
   6: OptSnap := Not OptSnap;
   7: OptFixAng := Not OptFixAng;
   8: OptFixLen := Not OptFixLen;
   10: OptShowC := Not OptShowC;
   11: OptNumbers := Not OptNumbers;
   12: OptWarn := Not OptWarn;
   13: OptColorEl := Not OptColorEl;
   14: OptStereo := Not OptStereo;
   15: OptDark := Not OptDark;
   17: OptAnalysis := Not OptAnalysis;
  End;
  MENU_OBJECT: Begin
   If Not AnySelected Then Begin NeedSelMsg; Exit; End;
   Case I Of
    0..5: AlignUnits(I);
    7: DistributeUnits(True);
    8: DistributeUnits(False);
    10, 11, 12, 14, 15: Begin
     PushUndo;
     SelCenter(CX, CY, Empty);
     Case I Of
      10: TransformSel(0, Pi / 2, CX, CY);
      11: TransformSel(0, -Pi / 2, CX, CY);
      12: TransformSel(0, Pi, CX, CY);
      14: TransformSel(1, 0, CX, CY);
      15: TransformSel(2, 0, CX, CY);
     End;
    End;
    13: DoRotateDialog;
    17: DoScaleDialog;
    18: StandardBondLength;
   End;
  End;
  MENU_STRUCT: Case I Of
   0: SetBondTargets(1, ST_NORMAL);
   1: SetBondTargets(2, ST_NORMAL);
   2: SetBondTargets(3, ST_NORMAL);
   3: SetBondTargets(1, ST_WEDGE);
   4: SetBondTargets(1, ST_HASH);
   5: SetBondTargets(1, ST_BOLD);
   6: SetBondTargets(1, ST_WAVY);
   7: SetBondTargets(1, ST_DASH);
   8: CycleDoublePos;
   9: ReverseBonds;
   11: ChangeTargets(1, 1);
   12: ChangeTargets(1, -1);
   13: ChangeTargets(2, 0);
   14: ChangeTargets(3, 0);
   16: ElementDialogApply;
   17: Begin
    N := GatherTargets;
    If N >= 1 Then EditAtomLabel(Tmp3^[0])
    Else StatusMsg := 'Survolez ou selectionnez un atome.';
   End;
   18: Begin
    J := PeriodicDialog;
    If J > 0 Then Begin CurElem := J; CurTool := T_ATOM; End;
   End;
   20: Begin PushUndo; CleanUpStructure; End;
   21: ExpandTargets;
   22: TemplateDialog;
  End;
  MENU_COLOR: Begin
   If I <= 15 Then ApplyColor(I)
   Else If I = 17 Then OptColorEl := Not OptColorEl;
  End;
  MENU_TEXT: Case I Of
   0: Begin
    S := '';
    If InputString('Nouveau texte', 'Texte :', S) And (S <> '') Then Begin
     PushUndo; ViewCenter(CX, CY);
     J := NewText(CX - Length(S) * 4, CY, Copy(S, 1, 70));
     If J >= 0 Then Begin ClearSelection; Tx^[J].Sel := True; End;
    End;
   End;
   1: Begin
    N := -1;
    For J := 0 To NTx - 1 Do If Tx^[J].Sel Then N := J;
    If N >= 0 Then EditText(N) Else ShowMessage('Texte', 'Selectionnez un texte.');
   End;
   3, 4: Begin
    TextSize := I - 2;
    For J := 0 To NTx - 1 Do If Tx^[J].Sel Then Tx^[J].Siz := TextSize;
    Touch;
   End;
   6, 7, 9: Begin
    Composition(CountSelAtoms > 0, C, Chg, Generic);
    If I = 6 Then InsertTextBelow(HillFormula(C, Chg))
    Else If I = 7 Then InsertTextBelow('PM : ' + RealToStr(MolWeight(C), 2))
    Else Begin WriteSmiles(CountSelAtoms > 0); InsertTextBelow(SmBufStr); End;
   End;
   8: Begin
    If NameFromStructure(S) Then InsertTextBelow(S)
    Else ShowMessage('Texte', 'Nom inconnu pour cette structure.');
   End;
  End;
  MENU_TOOLS: Case I Of
   0: DetailedAnalysis;
   1: ShowMassSpectrum;
   2: Begin PredictC13; ShowSpectrum('Prediction RMN 13C', False); End;
   3: Begin PredictH1; ShowSpectrum('Prediction RMN 1H', True); End;
   5: StructureToName;
   6: InsertNameDialog;
   7: ShowSmiles;
   8: ShowInChI;
   9: ShowStereo;
   11: CheckStructure;
   12: OptAnalysis := Not OptAnalysis;
  End;
  MENU_HELP: Case I Of
   0: ShowHelp(0);
   1: ShowHelp(1);
   2: ShowHelp(2);
   4: ShowAbout;
  End;
 End;

 NeedRedraw := True;
End;

Procedure DoToolbar(Id: Integer);
Var Z: Integer;
Begin
 Case Id Of
  TB_NEW: NewDocument;
  TB_OPEN: DoOpenFile;
  TB_SAVE: DoSave;
  TB_UNDO: DoUndo;
  TB_REDO: DoRedo;
  TB_ZOUT: ZoomCenter(0.8);
  TB_ZIN: ZoomCenter(1.25);
  TB_Z100: SetZoom100;
  TB_FIT: FitToWindow;
  TB_CHGP: ChangeTargets(1, 1);
  TB_CHGM: ChangeTargets(1, -1);
  TB_PERIOD: Begin
   Z := PeriodicDialog;
   If Z > 0 Then Begin CurElem := Z; CurTool := T_ATOM; If GatherTargets > 0 Then ChangeTargets(0, Z); End;
  End;
 Else
  If (Id >= TB_ATOM0) And (Id < TB_ATOM0 + 10) Then Begin
   CurElem := TbAtoms[Id - TB_ATOM0];
   CurTool := T_ATOM;
   If CountSelAtoms > 0 Then ChangeTargets(0, CurElem);
  End;
 End;
 NeedRedraw := True;
End;

{ --------------------------------------------------------------------- }
{ Gestion du clavier                                                    }
{ --------------------------------------------------------------------- }

Procedure DeleteTargets;
Var A, B: Integer;
Begin
 If AnySelected Then Begin
  PushUndo; DeleteSelected; ClearSelection;
 End
 Else If HovAtom >= 0 Then Begin
  PushUndo; A := HovAtom; MarkNeighbors(A); DelAtom(A); CleanOrphans; HovAtom := -1;
 End
 Else If HovBond >= 0 Then Begin
  PushUndo; B := HovBond;
  At^[Bd^[B].A].Mark := 16; At^[Bd^[B].B].Mark := 16;
  DelBond(B); CleanOrphans; HovBond := -1;
 End
 Else If HovShape >= 0 Then Begin PushUndo; DelShape(HovShape); HovShape := -1; End
 Else If HovText >= 0 Then Begin PushUndo; DelText(HovText); HovText := -1; End;
End;

Procedure HotkeyBond(Ch: Char);
Var J, N: Integer;
Begin
 N := 0;
 For J := 0 To NBd - 1 Do
  If (At^[Bd^[J].A].Sel And At^[Bd^[J].B].Sel) Or (J = HovBond) Then Inc(N);
 If N = 0 Then Exit;
 Case Ch Of
  '1': SetBondTargets(1, ST_NORMAL);
  '2': SetBondTargets(2, ST_NORMAL);
  '3': SetBondTargets(3, ST_NORMAL);
  'w', 'W': SetBondTargets(1, ST_WEDGE);
  'y', 'Y': SetBondTargets(1, ST_HASH);
  'v', 'V': SetBondTargets(1, ST_WAVY);
  'x', 'X': SetBondTargets(1, ST_BOLD);
  'd', 'D': SetBondTargets(1, ST_DASH);
 End;
End;

Procedure MoveOrScroll(DX, DY: Integer);
Begin
 If AnySelected Then Begin
  PushUndo;
  MoveSelection(DX * 4 / Zoom, DY * 4 / Zoom);
 End
 Else Begin
  ScrollX := ScrollX + DX * 30 / Zoom;
  ScrollY := ScrollY + DY * 30 / Zoom;
  ClampScroll;
  NeedRedraw := True;
 End;
End;

Procedure HandleKey;
Var
 K : Char;
 Z, N : Integer;
Begin
 K := ReadKey;
 If K = #0 Then Begin
  K := ReadKey;
  If MenuActive Then Begin
   Case K Of
    #75: Begin
     Dec(ActiveMenu); If ActiveMenu < 0 Then ActiveMenu := NUM_MENUS - 1;
     ActiveMenuItem := 0; MenuNextItem(0); If ActiveMenuItem < 0 Then ActiveMenuItem := 0;
    End;
    #77: Begin
     Inc(ActiveMenu); If ActiveMenu >= NUM_MENUS Then ActiveMenu := 0;
     ActiveMenuItem := 0; MenuNextItem(0); If ActiveMenuItem < 0 Then ActiveMenuItem := 0;
    End;
    #72: MenuNextItem(-1);
    #80: MenuNextItem(1);
    #68, #67: Begin MenuActive := False; ActiveMenu := -1; End;
   End;
   NeedRedraw := True;
   Exit;
  End;
  Case K Of
   #59: ShowHelp(0);
   #60: OptAnalysis := Not OptAnalysis;
   #61: DetailedAnalysis;
   #62: TemplateDialog;
   #63: SetZoom100;
   #64: OptGrid := Not OptGrid;
   #67, #68: Begin MenuActive := True; ActiveMenu := 0; ActiveMenuItem := 0; MenuNextItem(0); End;
   #45: Running := False;
   #71: FitToWindow;
   #73: ZoomCenter(1.25);
   #81: ZoomCenter(0.8);
   #72: MoveOrScroll(0, -1);
   #80: MoveOrScroll(0, 1);
   #75: MoveOrScroll(-1, 0);
   #77: MoveOrScroll(1, 0);
   #83: DeleteTargets;
  End;
  NeedRedraw := True;
  Exit;
 End;
 If MenuActive Then Begin
  Case K Of
   #27: Begin MenuActive := False; ActiveMenu := -1; End;
   #13: Begin
    If (ActiveMenuItem >= 0) And Not Menus[ActiveMenu].Items[ActiveMenuItem].Separator Then Begin
     Z := ActiveMenu; N := ActiveMenuItem;
     MenuActive := False; ActiveMenu := -1;
     UpdateMenuChecks;
     DispatchMenu(Z, N);
    End;
   End;
  End;
  NeedRedraw := True;
  Exit;
 End;
 Case K Of
  #14: NewDocument;
  #15: DoOpenFile;
  #19: DoSave;
  #26: DoUndo;
  #25: DoRedo;
  #24: DispatchMenu(MENU_EDIT, 3);
  #3: DispatchMenu(MENU_EDIT, 4);
  #22: DispatchMenu(MENU_EDIT, 5);
  #1: DispatchMenu(MENU_EDIT, 8);
  #4: DispatchMenu(MENU_EDIT, 16);
  #12: DispatchMenu(MENU_STRUCT, 20);
  #17: Running := False;
  #27: Begin
   If DragKind <> DR_NONE Then Begin
    If HasPending Then Begin RestoreSnap(Pending); CancelEdit; End;
    DragKind := DR_NONE;
   End
   Else ClearSelection;
  End;
  #8: DeleteTargets;
  #13: If HovAtom >= 0 Then EditAtomLabel(HovAtom);
  't', 'T': If HovAtom >= 0 Then EditAtomLabel(HovAtom);
  '+', '=': ChangeTargets(1, 1);
  '-', '_': ChangeTargets(1, -1);
  '.': ChangeTargets(2, 0);
  '1', '2', '3', 'w', 'W', 'y', 'Y', 'v', 'V', 'x', 'X', 'd', 'D': Begin
   If (HovBond >= 0) Or (HovAtom < 0) Then HotkeyBond(K)
   Else Begin
    If K = 'd' Then ChangeTargets(0, 1);
   End;
  End;
  'c', 'C': ChangeTargets(0, 6);
  'n', 'N': ChangeTargets(0, 7);
  'o', 'O': ChangeTargets(0, 8);
  's', 'S': ChangeTargets(0, 16);
  'p', 'P': ChangeTargets(0, 15);
  'f', 'F': ChangeTargets(0, 9);
  'h', 'H': ChangeTargets(0, 1);
  'i', 'I': ChangeTargets(0, 53);
  'l': ChangeTargets(0, 17);
  'L': ChangeTargets(0, 3);
  'b': ChangeTargets(0, 35);
  'B': ChangeTargets(0, 5);
 End;
 NeedRedraw := True;
End;

{ --------------------------------------------------------------------- }
{ Gestion de la souris                                                  }
{ --------------------------------------------------------------------- }

Procedure BeginMove;
Begin
 BeginEdit;
 DragEditing := True;
 DragKind := DR_MOVE;
 PropDirty := True;
End;

Procedure OnCanvasPress(MX, MY: Integer; Dbl: Boolean);
Var
 DX, DY : Real;
 HA, HB, HT, HS, WH, N : Integer;
Begin
 UpdateInfo;
 UpdateTxtScale;
 DX := DocX(MX); DY := DocY(MY);
 DragSX := DX; DragSY := DY; DragLX := DX; DragLY := DY;
 DragPressX := MX; DragPressY := MY;
 DragMoved := False; DragBondHit := -1; DragAtom := -1; DragEditing := False;
 EditVer := DocVer;
 HA := FindAtomAt(MX, MY, 9);
 HB := -1;
 If HA < 0 Then HB := FindBondAt(MX, MY, 5);
 Case CurTool Of
  T_SELECT, T_LASSO: Begin
   HS := FindHandleAt(MX, MY, WH);
   If HS >= 0 Then Begin
    BeginEdit; DragEditing := True; DragKind := DR_HANDLE; DragShape := HS; DragHandle := WH;
    Exit;
   End;
   HT := -1; HS := -1;
   If (HA < 0) And (HB < 0) Then Begin
    HT := FindTextAt(MX, MY);
    If HT < 0 Then HS := FindShapeAt(MX, MY);
   End;
   If HA >= 0 Then Begin
    If Dbl Then Begin ClearSelection; SelectFragment(HA, True); End
    Else If Not At^[HA].Sel Then Begin ClearSelection; At^[HA].Sel := True; End;
    BeginMove;
   End
   Else If HB >= 0 Then Begin
    If Not (At^[Bd^[HB].A].Sel And At^[Bd^[HB].B].Sel) Then Begin
     ClearSelection; At^[Bd^[HB].A].Sel := True; At^[Bd^[HB].B].Sel := True;
    End;
    If Dbl Then SelectFragment(Bd^[HB].A, True);
    BeginMove;
   End
   Else If HT >= 0 Then Begin
    If Dbl Then Begin EditText(HT); Exit; End;
    If Not Tx^[HT].Sel Then Begin ClearSelection; Tx^[HT].Sel := True; End;
    BeginMove;
   End
   Else If HS >= 0 Then Begin
    If Not Sh^[HS].Sel Then Begin ClearSelection; Sh^[HS].Sel := True; End;
    BeginMove;
   End
   Else Begin
    ClearSelection;
    If CurTool = T_SELECT Then DragKind := DR_MARQUEE
    Else Begin
     DragKind := DR_LASSO; DragNPts := 1;
     DragPts[0] := MX - CvX1; DragPts[1] := MY - CvY1;
    End;
   End;
  End;
  T_HAND: Begin
   DragKind := DR_HAND; HandX0 := ScrollX; HandY0 := ScrollY;
  End;
  T_ZOOM: DragKind := DR_ZOOMBOX;
  T_ERASER: Begin
   BeginEdit; DragEditing := True; DragKind := DR_ERASE;
   EraseAt(MX, MY);
  End;
  T_ROTATE: Begin
   If (Not AnySelected) And (HA >= 0) Then SelectFragment(HA, True);
   If Not AnySelected Then Exit;
   SelCenter(RotCX, RotCY, DragMoved);
   DragMoved := False;
   RotA0 := Atan2(DY - RotCY, DX - RotCX);
   BeginEdit; DragEditing := True; DragKind := DR_ROTATE;
  End;
  T_BOND..T_DASH, T_ATOM: Begin
   BeginEdit; DragEditing := True; DragKind := DR_BOND;
   DragAtom := HA; DragBondHit := HB;
   If HA < 0 Then Begin DragSX := SnapGrid(DX); DragSY := SnapGrid(DY); End;
  End;
  T_CHAIN: Begin
   BeginEdit; DragEditing := True; DragKind := DR_CHAIN;
   DragAtom := HA;
   If HA < 0 Then Begin DragSX := SnapGrid(DX); DragSY := SnapGrid(DY); End;
  End;
  T_TEXT: Begin
   If HA >= 0 Then EditAtomLabel(HA)
   Else Begin
    HT := FindTextAt(MX, MY);
    If HT >= 0 Then EditText(HT)
    Else Begin
     TextBuf := '';
     If InputString('Nouveau texte', 'Texte :', TextBuf) And (TextBuf <> '') Then Begin
      PushUndo;
      N := NewText(SnapGrid(DX), SnapGrid(DY) - 4, Copy(TextBuf, 1, 70));
      If N >= 0 Then Begin ClearSelection; Tx^[N].Sel := True; End;
     End;
    End;
   End;
  End;
  T_RING3..T_CPD: Begin
   N := RingSizeOfTool(CurTool);
   BeginEdit; DragEditing := True;
   If HA >= 0 Then BuildRing(N, CurTool, 0, 0, HA, -1, DX, DY)
   Else If HB >= 0 Then BuildRing(N, CurTool, 0, 0, -1, HB, DX, DY)
   Else BuildRing(N, CurTool, SnapGrid(DX), SnapGrid(DY), -1, -1, DX, DY);
   If DocVer <> EditVer Then CommitEdit Else CancelEdit;
   DragEditing := False;
  End;
  T_ARROW..T_CURVE1, T_BRACKET..T_RECT, T_ELLIPSE, T_ORBS, T_ORBP: Begin
   BeginEdit; DragEditing := True; DragKind := DR_SHAPE;
   DragSX := SnapGrid(DX); DragSY := SnapGrid(DY);
  End;
  T_PLUS: Begin
   BeginEdit;
   N := NewText(DX - 4, DY - 8, '+');
   If N >= 0 Then Tx^[N].Siz := 2;
   If DocVer <> EditVer Then CommitEdit Else CancelEdit;
  End;
 End;
End;

Procedure FinishShape;
Var
 Kd, Idx : Integer;
 EX, EY, SXa, SYa, LX, LY : Real;
Begin
 Case CurTool Of
  T_ARROW..T_CURVE1: Kd := CurTool - T_ARROW + SH_ARROW;
  T_BRACKET: Kd := SH_BRACKET;
  T_LINE: Kd := SH_LINE;
  T_RECT: Kd := SH_RECT;
  T_ELLIPSE: Kd := SH_ELLIPSE;
  T_ORBS: Kd := SH_ORBS;
  T_ORBP: Kd := SH_ORBP;
 Else Exit;
 End;
 SXa := DragSX; SYa := DragSY;
 LX := DragLX; LY := DragLY;
 If Kd In [SH_ARROW..SH_CURVE1, SH_LINE] Then Begin
  If OptFixAng Then SnapEnd(SXa, SYa, LX, LY, Pi / 12, False, EX, EY)
  Else Begin EX := LX; EY := LY; End;
 End
 Else Begin
  If OptSnap Then Begin EX := SnapGrid(LX); EY := SnapGrid(LY); End
  Else Begin EX := LX; EY := LY; End;
 End;
 If Dist(SXa, SYa, EX, EY) < 6 Then Exit;
 Idx := NewShape(Kd, SXa, SYa, EX, EY);
 If Idx >= 0 Then Begin
  ClearSelection;
  Sh^[Idx].Sel := True;
 End;
End;

Procedure CommitAtomDrag(MX, MY: Integer);
Var S, E, N0: Integer; EX, EY, SXa, SYa: Real;
Begin
 If Not DragMoved Then Begin
  If DragAtom >= 0 Then SetAtomElement(DragAtom, CurElem)
  Else Begin
   S := ObtainAtom(DragSX, DragSY);
   If S >= 0 Then SetAtomElement(S, CurElem);
  End;
  Touch;
  Exit;
 End;
 If DragAtom >= 0 Then S := DragAtom Else Begin
  N0 := NAt;
  S := ObtainAtom(DragSX, DragSY);
  If (S >= 0) And (S >= N0) Then SetAtomElement(S, 6);
 End;
 If S < 0 Then Exit;
 SXa := At^[S].X; SYa := At^[S].Y;
 E := FindAtomAt(MX, MY, 9);
 If (E < 0) Or (E = S) Then Begin
  SnapEnd(SXa, SYa, DragLX, DragLY, Pi / 6, OptFixLen, EX, EY);
  N0 := NAt;
  E := ObtainAtom(EX, EY);
  If (E >= N0) Then SetAtomElement(E, CurElem);
 End;
 If (E >= 0) And (E <> S) Then NewBond(S, E, 1, ST_NORMAL);
End;

Procedure OnDragMove(MX, MY: Integer);
Var
 DX, DY, A, Dlt : Real;
 T1, T2, Lo, Hi : Integer;
Begin
 DX := DocX(MX); DY := DocY(MY);
 If Abs(MX - DragPressX) + Abs(MY - DragPressY) >= 4 Then DragMoved := True;
 Case DragKind Of
  DR_MOVE: If DragMoved Then Begin
   MoveSelection(DX - DragLX, DY - DragLY);
   DragLX := DX; DragLY := DY;
  End;
  DR_MARQUEE, DR_ZOOMBOX: Begin DragLX := DX; DragLY := DY; NeedRedraw := True; End;
  DR_LASSO: Begin
   If (DragNPts < 120) And ((Abs(MX - CvX1 - DragPts[2 * DragNPts - 2]) > 2) Or (Abs(MY - CvY1 - DragPts[2 * DragNPts - 1]) > 2)) Then Begin
    DragPts[2 * DragNPts] := MX - CvX1;
    DragPts[2 * DragNPts + 1] := MY - CvY1;
    Inc(DragNPts);
   End;
   NeedRedraw := True;
  End;
  DR_BOND, DR_CHAIN, DR_SHAPE: Begin
   DragLX := DX; DragLY := DY;
   HovAtom := FindAtomAt(MX, MY, 9);
   NeedRedraw := True;
  End;
  DR_ROTATE: Begin
   A := Atan2(DY - RotCY, DX - RotCX);
   Dlt := A - RotA0;
   TransformSel(0, Dlt, RotCX, RotCY);
   RotA0 := A;
  End;
  DR_HAND: Begin
   ScrollX := HandX0 - (MX - DragPressX) / Zoom;
   ScrollY := HandY0 - (MY - DragPressY) / Zoom;
   ClampScroll;
   NeedRedraw := True;
  End;
  DR_ERASE: EraseAt(MX, MY);
  DR_SCROLLH: Begin
   ThumbH(T1, T2, Lo, Hi);
   ScrollX := ExtX1 + (MX - ScrollGrab - Lo) / (Hi - Lo) * (ExtX2 - ExtX1);
   ClampScroll; NeedRedraw := True;
  End;
  DR_SCROLLV: Begin
   ThumbV(T1, T2, Lo, Hi);
   ScrollY := ExtY1 + (MY - ScrollGrab - Lo) / (Hi - Lo) * (ExtY2 - ExtY1);
   ClampScroll; NeedRedraw := True;
  End;
  DR_HANDLE: Begin
   Case DragHandle Of
    0: Begin Sh^[DragShape].X1 := DX; Sh^[DragShape].Y1 := DY; End;
    1: Begin Sh^[DragShape].X2 := DX; Sh^[DragShape].Y2 := DY; End;
   Else
    Sh^[DragShape].CX := DX; Sh^[DragShape].CY := DY;
   End;
   Touch;
  End;
 End;
End;

Procedure OnRelease(MX, MY: Integer);
Var
 Px, Py, X1, Y1, X2, Y2, W, H, Z1, Z2 : Real;
 N : Integer;
Begin
 Case DragKind Of
  DR_MOVE: ;
  DR_MARQUEE: If DragMoved Then SelectInRect(DragSX, DragSY, DragLX, DragLY, False);
  DR_LASSO: SelectInLasso;
  DR_BOND: Begin
   If CurTool = T_ATOM Then CommitAtomDrag(MX, MY)
   Else CommitBondDrag(MX, MY, DragBondHit);
  End;
  DR_CHAIN: Begin
   If DragMoved Then Begin
    If DragAtom >= 0 Then Begin Px := At^[DragAtom].X; Py := At^[DragAtom].Y; End
    Else Begin Px := DragSX; Py := DragSY; End;
    CommitChain(DragAtom, Px, Py);
   End
   Else Begin
    If DragAtom >= 0 Then AddBondFromAtom(DragAtom, 1, ST_NORMAL)
    Else Begin
     N := ObtainAtom(DragSX, DragSY);
     If N >= 0 Then Begin
      Px := DragSX + BOND_LEN * Cos(-Pi / 6); Py := DragSY + BOND_LEN * Sin(-Pi / 6);
      X1 := ObtainAtom(Px, Py);
      If X1 >= 0 Then NewBond(N, Trunc(X1), 1, ST_NORMAL);
     End;
    End;
   End;
  End;
  DR_SHAPE: FinishShape;
  DR_ZOOMBOX: Begin
   If DragMoved Then Begin
    X1 := MinR(DragSX, DragLX); X2 := MaxR(DragSX, DragLX);
    Y1 := MinR(DragSY, DragLY); Y2 := MaxR(DragSY, DragLY);
    W := X2 - X1; H := Y2 - Y1;
    If (W > 8) And (H > 8) Then Begin
     Z1 := (CvX2 - CvX1 + 1) / W; Z2 := (CvY2 - CvY1 + 1) / H;
     Zoom := ClampR(MinR(Z1, Z2), 0.25, 4);
     UpdateTxtScale;
     ScrollX := (X1 + X2) / 2 - (CvX2 - CvX1 + 1) / 2 / Zoom;
     ScrollY := (Y1 + Y2) / 2 - (CvY2 - CvY1 + 1) / 2 / Zoom;
     ClampScroll;
    End;
   End
   Else ZoomAt(1.5, DragSX, DragSY);
  End;
 End;
 If DragEditing Then Begin
  If DocVer <> EditVer Then CommitEdit Else CancelEdit;
  DragEditing := False;
 End;
 DragKind := DR_NONE;
 NeedRedraw := True;
 PropDirty := True;
End;

Function ScrollbarPress(MX, MY: Integer): Boolean;
Var T1, T2, Lo, Hi: Integer;
Begin
 ScrollbarPress := False;
 If (MY >= CvY2 + 1) And (MY <= CvY2 + SCROLL_W) And (MX >= CvX1) And (MX <= CvX2) Then Begin
  ScrollbarPress := True;
  ThumbH(T1, T2, Lo, Hi);
  If MX < CvX1 + SCROLL_W Then ScrollX := ScrollX - 40 / Zoom
  Else If MX > CvX2 - SCROLL_W Then ScrollX := ScrollX + 40 / Zoom
  Else If MX < T1 Then ScrollX := ScrollX - (CvX2 - CvX1) / Zoom * 0.8
  Else If MX > T2 Then ScrollX := ScrollX + (CvX2 - CvX1) / Zoom * 0.8
  Else Begin DragKind := DR_SCROLLH; ScrollGrab := MX - T1; End;
  ClampScroll; NeedRedraw := True;
 End
 Else If (MX >= CvX2 + 1) And (MX <= CvX2 + SCROLL_W) And (MY >= CvY1) And (MY <= CvY2) Then Begin
  ScrollbarPress := True;
  ThumbV(T1, T2, Lo, Hi);
  If MY < CvY1 + SCROLL_W Then ScrollY := ScrollY - 40 / Zoom
  Else If MY > CvY2 - SCROLL_W Then ScrollY := ScrollY + 40 / Zoom
  Else If MY < T1 Then ScrollY := ScrollY - (CvY2 - CvY1) / Zoom * 0.8
  Else If MY > T2 Then ScrollY := ScrollY + (CvY2 - CvY1) / Zoom * 0.8
  Else Begin DragKind := DR_SCROLLV; ScrollGrab := MY - T1; End;
  ClampScroll; NeedRedraw := True;
 End;
End;

Procedure UpdateHover(MX, MY: Integer);
Var
 HA, HB, HT, HS, T, B : Integer;
 Msg : String;
Begin
 HA := -1; HB := -1; HT := -1; HS := -1;
 Msg := '';
 If InCanvas(MX, MY) And Not MenuActive Then Begin
  UpdateInfo;
  UpdateTxtScale;
  HA := FindAtomAt(MX, MY, 9);
  If HA < 0 Then HB := FindBondAt(MX, MY, 5);
  If (HA < 0) And (HB < 0) Then Begin
   HT := FindTextAt(MX, MY);
   If HT < 0 Then HS := FindShapeAt(MX, MY);
  End;
  If HA >= 0 Then Begin
   If At^[HA].Lbl <> '' Then Msg := 'Atome ' + IntToStr(HA + 1) + ' : ' + At^[HA].Lbl
   Else If At^[HA].Z > 0 Then Msg := 'Atome ' + IntToStr(HA + 1) + ' : ' + ElSym[At^[HA].Z] + ' (' + ElName[At^[HA].Z] + ')';
   If Inf^[HA].H > 0 Then Msg := Msg + '  H:' + IntToStr(Inf^[HA].H);
   If At^[HA].Chg <> 0 Then Msg := Msg + '  charge ' + IntToStr(At^[HA].Chg);
  End
  Else If HB >= 0 Then Begin
   Msg := 'Liaison ' + IntToStr(HB + 1) + ' : ordre ' + IntToStr(Bd^[HB].Order);
   B := Bd^[HB].Sty;
   Case B Of
    ST_WEDGE: Msg := Msg + ' (coin plein)';
    ST_HASH: Msg := Msg + ' (coin hachure)';
    ST_BOLD: Msg := Msg + ' (grasse)';
    ST_WAVY: Msg := Msg + ' (ondulee)';
    ST_DASH: Msg := Msg + ' (pointillee)';
   End;
   Msg := Msg + '  L=' + RealToStr(Dist(At^[Bd^[HB].A].X, At^[Bd^[HB].A].Y, At^[Bd^[HB].B].X, At^[Bd^[HB].B].Y) / BOND_LEN * 1.5, 2) + ' A';
  End;
 End
 Else If (MY >= MENUBAR_H) And (MY < MENUBAR_H + TOOLBAR_H) Then Begin
  T := ToolbarHit(MX, MY);
  If T >= 0 Then Msg := TBHint[T];
 End
 Else If MX < PAL_W Then Begin
  T := ToolHit(MX, MY);
  If T >= 0 Then Msg := ToolName[T];
 End;
 If (HA <> HovAtom) Or (HB <> HovBond) Or (HT <> HovText) Or (HS <> HovShape) Then Begin
  HovAtom := HA; HovBond := HB; HovText := HT; HovShape := HS;
  NeedRedraw := True;
 End;
 If Msg <> StatusMsg Then Begin
  If (Msg <> '') Or (HovAtom < 0) Then Begin
   StatusMsg := Msg;
   NeedRedraw := True;
  End;
 End;
End;

Procedure HandleMouse;
Var
 Hit, ItemHit, T, Sw : Integer;
 LeftDown, RightDown, OldLeft, OldRight, Dbl, Moved : Boolean;
Begin
 GetMouseLocal(MouseX, MouseY, MouseButtons);
 LeftDown := (MouseButtons And 1) <> 0;
 RightDown := (MouseButtons And 2) <> 0;
 OldLeft := (OldMouseButtons And 1) <> 0;
 OldRight := (OldMouseButtons And 2) <> 0;
 Moved := (MouseX <> OldMouseX) Or (MouseY <> OldMouseY);
 DlgHappened := False;
 { survol des menus }
 If MenuActive And Moved Then Begin
  Hit := MenuBarHitTest(MouseX, MouseY);
  If (Hit >= 0) And (Hit <> ActiveMenu) Then Begin
   ActiveMenu := Hit; ActiveMenuItem := -1; NeedRedraw := True;
  End
  Else Begin
   ItemHit := MenuItemHitTest(MouseX, MouseY, ActiveMenu);
   If (ItemHit >= 0) And (ItemHit <> ActiveMenuItem) And
      (Not Menus[ActiveMenu].Items[ItemHit].Separator) Then Begin
    ActiveMenuItem := ItemHit; NeedRedraw := True;
   End;
  End;
 End;
 { bouton gauche enfonce }
 If LeftDown And Not OldLeft Then Begin
  Hit := MenuBarHitTest(MouseX, MouseY);
  If Hit >= 0 Then Begin
   If MenuActive And (ActiveMenu = Hit) Then Begin MenuActive := False; ActiveMenu := -1; End
   Else Begin MenuActive := True; ActiveMenu := Hit; ActiveMenuItem := -1; UpdateMenuChecks; End;
   NeedRedraw := True;
  End
  Else If MenuActive Then Begin
   ItemHit := MenuItemHitTest(MouseX, MouseY, ActiveMenu);
   If (ItemHit >= 0) And Not Menus[ActiveMenu].Items[ItemHit].Separator Then Begin
    T := ActiveMenu;
    MenuActive := False; ActiveMenu := -1;
    DispatchMenu(T, ItemHit);
   End
   Else If ItemHit < 0 Then Begin MenuActive := False; ActiveMenu := -1; End;
   NeedRedraw := True;
  End
  Else If (MouseY >= MENUBAR_H) And (MouseY < MENUBAR_H + TOOLBAR_H) Then Begin
   T := ToolbarHit(MouseX, MouseY);
   If T >= 0 Then DoToolbar(TBId[T]);
  End
  Else If MouseX < PAL_W Then Begin
   T := ToolHit(MouseX, MouseY);
   If T >= 0 Then Begin
    CurTool := T;
    NeedRedraw := True;
   End
   Else Begin
    Sw := SwatchHit(MouseX, MouseY);
    If Sw >= 0 Then ApplyColor(Sw);
    NeedRedraw := True;
   End;
  End
  Else If ScrollbarPress(MouseX, MouseY) Then
  Else If InCanvas(MouseX, MouseY) Then Begin
   Dbl := (NowMs - LastClickT < 450) And (NowMs >= LastClickT) And
          (Abs(MouseX - LastClickX) < 5) And (Abs(MouseY - LastClickY) < 5);
   LastClickT := NowMs; LastClickX := MouseX; LastClickY := MouseY;
   If Dbl Then LastClickT := 0;
   OnCanvasPress(MouseX, MouseY, Dbl);
   NeedRedraw := True;
  End;
 End;
 { bouton droit : zoom arriere ou deplacement de la vue }
 If RightDown And Not OldRight And (DragKind = DR_NONE) And InCanvas(MouseX, MouseY) And Not MenuActive Then Begin
  If CurTool = T_ZOOM Then ZoomAt(1 / 1.5, DocX(MouseX), DocY(MouseY))
  Else Begin
   DragKind := DR_HAND; HandX0 := ScrollX; HandY0 := ScrollY;
   DragPressX := MouseX; DragPressY := MouseY;
   DragEditing := False;
  End;
 End;
 { glisser }
 If (DragKind <> DR_NONE) And (LeftDown Or RightDown) And Moved Then OnDragMove(MouseX, MouseY);
 { relachement }
 If (DragKind <> DR_NONE) And (Not LeftDown) And ((DragKind <> DR_HAND) Or Not RightDown) Then OnRelease(MouseX, MouseY);
 If (DragKind = DR_NONE) And Not MenuActive Then UpdateHover(MouseX, MouseY);
 If Not DlgHappened Then OldMouseButtons := MouseButtons;
 OldMouseX := MouseX; OldMouseY := MouseY;
End;

{ --------------------------------------------------------------------- }
{ Initialisation et boucle principale                                   }
{ --------------------------------------------------------------------- }

Procedure InitializeGraphics;
Begin
 InitMenus;                    { barre de menus de PM (OpenWindow) }
 InitBmi;
 OsFrame := 0; OsClient := 0;
 OpenWindow('CHEMDRAW', 'Dessin de chimie');
 SetColor(White);
 SetLineStyle(0, 0, 1);
 ScreenWidth := GetMaxX + 1;
 ScreenHeight := GetMaxY + 1;
End;

Procedure InitializeAll;
Var I: Integer;
Begin
 InitDoc;
 InitInChI;
 New(SmBuf);
 SmLen := 0;
 UndoN := 0; RedoN := 0; HasPending := False; ClipValid := False; ClipSmiles := '';
 For I := 0 To UNDO_MAX - 1 Do Begin
  UndoStk[I].PA := Nil; UndoStk[I].PB := Nil; UndoStk[I].PT := Nil; UndoStk[I].PS := Nil;
  RedoStk[I] := UndoStk[I];
 End;
 Pending.PA := Nil; Pending.PB := Nil; Pending.PT := Nil; Pending.PS := Nil;
 Clip := Pending;
 CvX1 := PAL_W; CvY1 := MENUBAR_H + TOOLBAR_H;
 CvX2 := ScreenWidth - SCROLL_W - 1;
 CvY2 := ScreenHeight - STATUS_H - SCROLL_W - 1;
 Zoom := 1.0; ScrollX := -30; ScrollY := -30;
 TxtScale := 1;
 CurTool := T_BOND; CurElem := 6; CurColor := Black; TextSize := 1;
 OptGrid := False; OptSnap := False; OptFixAng := True; OptFixLen := True;
 OptShowC := False; OptNumbers := False; OptWarn := True; OptAnalysis := False;
 OptColorEl := False; OptDark := False; OptStereo := False;
 StVer := -1;
 DocName := '';
 DragKind := DR_NONE; DragAtom := -1;
 HovAtom := -1; HovBond := -1; HovShape := -1; HovText := -1;
 LastClickT := 0; LastClickX := -100; LastClickY := -100;
 MenuActive := False; ActiveMenu := -1; ActiveMenuItem := -1;
 OldMouseButtons := 0; OldMouseX := -1; OldMouseY := -1;
 StatusMsg := '';
 For I := 0 To 5 Do PropText[I] := '';
 InitMenus;
 InitToolbar;
 LayoutMenuBar;
 InitMouseDriver;
 Running := True;
 NeedRedraw := True;
End;

Procedure MainLoop;
Var C : LongInt;
Begin
 RedrawAll;
 While Running Do Begin
  If KeyPressed Then HandleKey;
  { barre de menus de PM }
  While PollCmd(C) And Running Do Begin
   If C = CMD_CLOSE Then DispatchMenu(MENU_FILE, 13)
   Else If (C >= 100) And (C < 100 + 32 * NUM_MENUS) Then
    DispatchMenu((C - 100) Div 32, (C - 100) Mod 32);
   NeedRedraw := True;
  End;
  HandleMouse;
  If MenuActive Then UpdateMenuChecks;
  If NeedRedraw Then RedrawAll;
  Delay(8);
 End;
End;

{ ===================================================================== }
{ Programme principal                                                   }
{ ===================================================================== }

Var
 InitFile : String;
 VCX, VCY : Real;

BEGIN
 If (ParamStr(1) = '/?') Or (ParamStr(1) = '--help') Or (ParamStr(1) = '-h') Then Begin
  WriteLn('CHEMDRAW - Cette commande permet de lancer l''editeur de structures chimiques 2D.');
  WriteLn;
  WriteLn('Syntaxe : CHEMDRAW [fichier.CDT|.MOL|.SDF|.SMI] [-s SMILES]');
  WriteLn;
  WriteLn(' fichier   Document a ouvrir (format natif CDT, MOL, SDF ou SMILES)');
  WriteLn(' -s        Dessine la structure decrite par la chaine SMILES');
  Halt;
 End;
 InitializeGraphics;
 InitializeAll;
 SetViewPort(0, 0, ScreenWidth - 1, ScreenHeight - 1, True);
 If ParamCount >= 1 Then Begin
  If (ParamStr(1) = '-s') Or (ParamStr(1) = '/S') Then Begin
   If ParamCount >= 2 Then Begin
    ViewCenter(VCX, VCY);
    If Not AddSmilesAt(ParamStr(2), VCX, VCY) Then StatusMsg := 'SMILES invalide';
    ClearSelection;
    FitToWindow;
   End;
  End
  Else Begin
   InitFile := ParamStr(1);
   If FileOK(InitFile) Then LoadAnyFile(InitFile) Else StatusMsg := 'Fichier introuvable : ' + InitFile;
  End;
 End;
 ClearHistory; Modified := False;
 MainLoop;
 Dummy := WinDestroyWindow(OsFrame);
END.
