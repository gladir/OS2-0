{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: HOST - adresse IP d'un nom (DNS, TCPIP32.DLL) d'OS/2-0.
}

Program HOST;

{$R-,S-,I-}

{ Compilation : OS2PC HOST.PAS   (produit HOST.EXE)

  HOST nom : adresse IP du nom (serveur DNS de la configuration DHCP ou
  IP_DNS de CONFIG.SYS). }

Function GetHostByName(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';

Var
  H, A, K : LongInt;
  S : String;
  NameB : Array[0..255] Of Byte;

Function RdL(X : LongInt) : LongInt;
Type PL = ^LongInt;
Var Q : PL;
Begin
  Q := Pointer(X);
  RdL := Q^;
End;

Function RdB(X : LongInt) : LongInt;
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(X);
  RdB := Q^;
End;

BEGIN
  If ParamCount < 1 Then
  Begin
    Writeln('HOST nom : adresse IP du nom (DNS).');
    Halt(1);
  End;
  S := ParamStr(1);
  For K := 1 To Length(S) Do NameB[K - 1] := Ord(S[K]);
  NameB[Length(S)] := 0;
  H := GetHostByName(LongInt(@NameB));
  If H = 0 Then
  Begin
    Writeln('HOST : ', S, ' introuvable.');
    Halt(1);
  End;
  A := RdL(RdL(H + 16));
  Writeln(S, ' est ', RdB(A), '.', RdB(A + 1), '.', RdB(A + 2), '.', RdB(A + 3));
END.
