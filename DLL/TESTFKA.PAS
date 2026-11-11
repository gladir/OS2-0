{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de FKA.DLL sous OS/2-0.
}

Program TESTFKA;

{ Compilation : OS2PC TESTFKA.PAS   (produit TESTFKA.EXE)

  TESTFKA       verifie les neuf fonctions de FKA.DLL et leurs ordinaux
  TESTFKA VOIR  laisse ensuite la zone des touches de fonction affichee
                et permet de la parcourir au clavier (fleches, Entree,
                F1-F10, Echap pour terminer). }

Function FKAInit(Hab : LongInt) : LongInt; External 'FKA';
Function QueryFKADisplayDetails(Hwnd, PDetails : LongInt) : LongInt; External 'FKA';
Function WinFKAWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'FKA' Name 'WINFKAWNDPROC';
Function WinLoadFKA(Parent, HMod, Id : LongInt) : LongInt; External 'FKA' Name 'WINLOADFKA';
Function WinCreateFKA(Parent, PLabels, Count, Form : LongInt) : LongInt; External 'FKA' Name 'WINCREATEFKA';
Function WinSetFKAForm(Hwnd, Form : LongInt) : LongInt; External 'FKA' Name 'WINSETFKAFORM';
Function WinQueryFKAForm(Hwnd : LongInt) : LongInt; External 'FKA' Name 'WINQUERYFKAFORM';
Function WinGotoFKA(Hwnd : LongInt) : LongInt; External 'FKA' Name 'WINGOTOFKA';
Function WinGoFromFKA(Hwnd : LongInt) : LongInt; External 'FKA' Name 'WINGOFROMFKA';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';

Const
  WM_DESTROY = $0002;
  WM_PAINT   = $0023;
  WM_CHAR    = $007A;
  FKAM_SETTEXT = $0F03;
  FKAM_QUERYTEXT = $0F04;
  VK_LEFT    = $15;
  VK_RIGHT   = $17;
  VK_ENTER   = $1E;
  VK_ESC     = $0F;
  VK_F1      = $20;

Type
  PByte = ^Byte;
  PLong = ^LongInt;

Var
  Ok, Fail, Hwnd, Hwnd2, R, I, HMod, Pa, Pb, H, Act, N : LongInt;
  Labels : Array[0..9] Of LongInt;
  Texts : Array[0..9] Of Array[0..15] Of Byte;
  Det : Array[0..7] Of LongInt;
  Buf : Array[0..255] Of Byte;
  Name : Array[0..127] Of Byte;
  C : Char;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var I : LongInt; P : PByte;
Begin
  For I := 1 To Length(S) Do
  Begin
    P := Pointer(A + I - 1);
    P^ := Ord(S[I]);
  End;
  P := Pointer(A + Length(S));
  P^ := 0;
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name), S);
  Z := LongInt(@Name);
End;

Function GetStr(A : LongInt) : String;
Var S : String; P : PByte;
Begin
  S := '';
  P := Pointer(A);
  While (P^ <> 0) And (Length(S) < 255) Do
  Begin
    S := S + Chr(P^);
    A := A + 1;
    P := Pointer(A);
  End;
  GetStr := S;
End;

Procedure Check(What : String; Cond : Boolean);
Begin
  If Cond Then
  Begin
    Inc(Ok);
    WriteLn('  OK     ', What);
  End
  Else
  Begin
    Inc(Fail);
    WriteLn('  ECHEC  ', What);
  End;
End;

{ Message WM_CHAR pour une touche virtuelle }
Function Key(Vk : LongInt) : LongInt;
Begin
  Key := WinFKAWndProc(Hwnd, WM_CHAR, 2, Vk Shl 16);
End;

Procedure SetText(K : LongInt; S : String);
Begin
  PutZ(LongInt(@Texts[K]), S);
  Labels[K] := LongInt(@Texts[K]);
End;

BEGIN
  Ok := 0; Fail := 0;
  WriteLn('TESTFKA : essai de FKA.DLL');

  { ordinaux d'origine : 64 FKAInit ... 72 WINGOFROMFKA }
  Check('DosQueryModuleHandle FKA', DosQueryModuleHandle(Z('FKA'), LongInt(@HMod)) = 0);
  DosQueryProcAddr(HMod, 0, Z('FKAInit'), LongInt(@Pa));
  DosQueryProcAddr(HMod, 64, 0, LongInt(@Pb));
  Check('ordinal 64 = FKAInit', (Pa <> 0) And (Pa = Pb));
  DosQueryProcAddr(HMod, 0, Z('WINLOADFKA'), LongInt(@Pa));
  DosQueryProcAddr(HMod, 67, 0, LongInt(@Pb));
  Check('ordinal 67 = WINLOADFKA', (Pa <> 0) And (Pa = Pb));
  DosQueryProcAddr(HMod, 0, Z('WINGOFROMFKA'), LongInt(@Pa));
  DosQueryProcAddr(HMod, 72, 0, LongInt(@Pb));
  Check('ordinal 72 = WINGOFROMFKA', (Pa <> 0) And (Pa = Pb));
  Check('ordinal 73 inexistant', DosQueryProcAddr(HMod, 73, 0, LongInt(@Pb)) <> 0);

  Check('FKAInit', FKAInit(0) = 1);
  SetText(0, 'Aide'); SetText(1, 'Ouvrir'); SetText(2, 'Sauver,300'); SetText(3, 'Copier');
  SetText(4, 'Coller'); SetText(5, 'Chercher'); SetText(6, 'Imprimer'); SetText(7, 'Options');
  SetText(8, 'Menu'); SetText(9, 'Quitter');
  Hwnd := WinCreateFKA(0, LongInt(@Labels), 10, 1);
  Check('WINCREATEFKA (10 touches, forme courte)', Hwnd <> 0);
  Det[0] := 32;
  Check('QueryFKADisplayDetails', (QueryFKADisplayDetails(Hwnd, LongInt(@Det)) = 1) And
        (Det[1] = 1) And (Det[2] = 24) And (Det[4] = 10) And (Det[5] = 8));
  Check('WINQUERYFKAFORM = courte', WinQueryFKAForm(Hwnd) = 1);
  Check('WINSETFKAFORM longue', WinSetFKAForm(Hwnd, 2) = 1);
  Check('WINQUERYFKAFORM = longue', WinQueryFKAForm(Hwnd) = 2);
  Check('WINSETFKAFORM forme invalide refusee', WinSetFKAForm(Hwnd, 7) = 0);
  Check('WINFKAWNDPROC F5 -> commande 5', Key(VK_F1 + 4) = 5);
  Check('WINGOTOFKA', WinGotoFKA(Hwnd) = 1);
  Key(VK_RIGHT); Key(VK_RIGHT);
  Check('fleches + Entree -> touche 3 (commande 300)', Key(VK_ENTER) = 300);
  Key(VK_LEFT); Key(VK_LEFT); Key(VK_LEFT);
  QueryFKADisplayDetails(Hwnd, LongInt(@Det));
  Check('fleche gauche depuis F1 -> F10', (Det[6] = 1) And (Det[7] = 10));
  Check('WINGOFROMFKA', (WinGoFromFKA(Hwnd) = 1) And (QueryFKADisplayDetails(Hwnd, LongInt(@Det)) = 1) And
        (Det[6] = 0));
  Check('FKAM_SETTEXT', WinFKAWndProc(Hwnd, FKAM_SETTEXT, 2, Z('Charger')) = 1);
  N := WinFKAWndProc(Hwnd, FKAM_QUERYTEXT, 2, LongInt(@Buf));
  Check('FKAM_QUERYTEXT', (N = 7) And (GetStr(LongInt(@Buf)) = 'Charger'));

  { definition dans un fichier : FKA0007.TXT }
  If DosOpen(Z('FKA0007.TXT'), LongInt(@H), LongInt(@Act), 0, 0, $12, $42, 0) = 0 Then
  Begin
    PutZ(LongInt(@Buf), 'FORM=LONG;KEYS=12;1=Aide;3=Fichier,30;12=Fin,99');
    DosWrite(H, LongInt(@Buf), Length(GetStr(LongInt(@Buf))), LongInt(@N));
    DosClose(H);
  End;
  Hwnd2 := WinLoadFKA(0, 0, 7);
  Check('WINLOADFKA (FKA0007.TXT)', Hwnd2 <> 0);
  QueryFKADisplayDetails(Hwnd2, LongInt(@Det));
  Check('  forme longue, 12 touches', (Det[1] = 2) And (Det[4] = 12));
  Check('  F12 -> commande 99', WinFKAWndProc(Hwnd2, WM_CHAR, 2, (VK_F1 + 11) Shl 16) = 99);
  Check('WINLOADFKA id inexistant', WinLoadFKA(0, 0, 8) = 0);
  Check('WM_DESTROY', (WinFKAWndProc(Hwnd2, WM_DESTROY, 0, 0) = 0) And (WinQueryFKAForm(Hwnd2) = -1));
  DosDelete(Z('FKA0007.TXT'));
  WinSetFKAForm(Hwnd, 1);

  WriteLn;
  WriteLn('TESTFKA : ', Ok, ' reussi(s), ', Fail, ' echec(s).');

  If (ParamCount > 0) And (ParamStr(1) = 'VOIR') Then
  Begin
    { parcourir la FKA : touches lues par ReadLn (une lettre par ligne) }
    WriteLn('g/d + Entree : touche precedente/suivante, o : choisir, q : fin');
    WinGotoFKA(Hwnd);
    Repeat
      ReadLn(C);
      Case C Of
        'g' : Key(VK_LEFT);
        'd' : Key(VK_RIGHT);
        'o' : WriteLn('Commande choisie : ', Key(VK_ENTER));
      End;
      WinFKAWndProc(Hwnd, WM_PAINT, 0, 0);
    Until C = 'q';
  End;
  WinFKAWndProc(Hwnd, WM_DESTROY, 0, 0);
END.
