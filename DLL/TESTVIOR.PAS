{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Sous-systeme video de remplacement pour l'essai de
                VioRegister et VioGlobalReg (TESTVIO).
}

Library TESTVIOR;

{$IMAGEBASE $00F80000}

{ Compilation : OS2PC TESTVIOR.PAS   (produit TESTVIOR.DLL)

  VioReplace(Fonction, pParametres, Nombre) est appelee par VIOCALLS.DLL
  pour les fonctions remplacees : VioGetCurPos (0) rend toujours la
  position (7, 7) ; VioGetCurType (1) demande la fonction de base en
  rendant 99 (valeur usReturn de VioGlobalReg) ; les autres rendent -1
  (fonction de base, comme le demande VioRegister). ReplCalls rend le
  nombre d'appels recus. }

Type
  PLong = ^LongInt;

Var
  Calls : LongInt;

Function VioReplace(Fn, PPrm, N : LongInt) : LongInt;
Var P : PLong; R : LongInt;
Begin
  Inc(Calls);
  R := -1;
  If Fn = 0 Then
  Begin
    P := Pointer(PPrm);
    P := Pointer(P^);
    P^ := 7;
    P := Pointer(PPrm + 4);
    P := Pointer(P^);
    P^ := 7;
    R := 0;
  End
  Else If Fn = 1 Then R := 99;
  VioReplace := R;
End;

Function ReplCalls : LongInt;
Begin
  ReplCalls := Calls;
End;

exports
  VioReplace, ReplCalls;

BEGIN
  Calls := 0;
END.
