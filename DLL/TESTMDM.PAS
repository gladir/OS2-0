{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de MDM.DLL (son numerique, MCI) et du
                pilote de la carte son.
}

Program TESTMDM;

{$R-,S-,I-}

{ Compilation : OS2PC TESTMDM.PAS   (produit TESTMDM.EXE)

  Verifie MDM.DLL et le pilote de la carte son : nom de la carte, lecture
  d'un son synthetise (accord de 0,6 s) aux formats 8 et 16 bits, mono et
  stereo, a 11 025, 22 050 et 44 100 Hz, avance de la position, pause et
  reprise, arret ; interface de chaines MCI (open, set, status, play wait,
  seek, record, save et relecture d'un fichier WAV, close), messages
  d'erreur. Parametre /SANSCARTE : seulement les verifications qui ne
  demandent pas de carte son. }

Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeMem(Pb : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function MdmAudioInfo(PBuf, Len : LongInt) : LongInt; External 'MDM' Name 'MDMAUDIOINFO';
Function MdmPlay(PData, Bytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMPLAY';
Function MdmRecord(PData, MaxBytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMRECORD';
Function MdmStop : LongInt; External 'MDM' Name 'MDMSTOP';
Function MdmPause(On : LongInt) : LongInt; External 'MDM' Name 'MDMPAUSE';
Function MdmPosition : LongInt; External 'MDM' Name 'MDMPOSITION';
Function MdmState : LongInt; External 'MDM' Name 'MDMSTATE';
Function MdmVolume(V : LongInt) : LongInt; External 'MDM' Name 'MDMVOLUME';
Function MdmCardFormat(PRate, PBits, PCh : LongInt) : LongInt; External 'MDM' Name 'MDMCARDFORMAT';
Function MciSendString(PCmd, PRet, RetLen, Hwnd, User : LongInt) : LongInt; External 'MDM' Name 'mciSendString';
Function MciGetErrorString(Err, PBuf, Len : LongInt) : LongInt; External 'MDM' Name 'mciGetErrorString';

Var
  Ok, Bad, Buf, Caps, Dummy0 : LongInt;
  NoRec : Boolean;
  NameB, Ret, CmdB : Array[0..255] Of Byte;
  Card : Boolean;

Procedure Check(S : String; B : Boolean);
Begin
  If B Then Inc(Ok)
  Else
  Begin
    Inc(Bad);
    Writeln('ECHEC : ', S);
  End;
End;

Function GetP(P : LongInt) : String;
Type PB = ^Byte;
Var S : String; K : LongInt; Q : PB;
Begin
  S := '';
  K := 0;
  Q := Pointer(P);
  While (K < 255) And (Q^ <> 0) Do
  Begin
    S := S + Chr(Q^);
    Inc(K);
    Q := Pointer(P + K);
  End;
  GetP := S;
End;

Function Mci(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do CmdB[K - 1] := Ord(S[K]);
  CmdB[Length(S)] := 0;
  Ret[0] := 0;
  Mci := MciSendString(LongInt(@CmdB), LongInt(@Ret), 255, 0, 0);
End;

Function RetS : String;
Begin
  RetS := GetP(LongInt(@Ret));
End;

Function Num(S : String) : LongInt;
Var V, C : LongInt;
Begin
  Val(S, V, C);
  If C <> 0 Then V := -1;
  Num := V;
End;

Procedure WrB(A, V : LongInt);
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
End;

{ accord (do, mi, sol) approche par des ondes triangulaires }
Function Tri(T, Period : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := T Mod Period;
  If P < Period Div 2 Then Tri := -8000 + (16000 * P) Div (Period Div 2)
  Else Tri := 8000 - (16000 * (P - Period Div 2)) Div (Period Div 2);
End;

{ son de Ms millisecondes au format donne ; rend le nombre d'octets }
Function MakeTone(Rate, Bits, Ch, Ms : LongInt) : LongInt;
Var N, I, V, A, FB : LongInt;
Begin
  N := (Rate Div 1000) * Ms;
  FB := (Bits Div 8) * Ch;
  A := Buf;
  For I := 0 To N - 1 Do
  Begin
    V := Tri(I * 100, (Rate * 100) Div 262) + Tri(I * 100, (Rate * 100) Div 330) + Tri(I * 100, (Rate * 100) Div 392);
    V := V Div 2;
    If Bits = 8 Then
    Begin
      WrB(A, (V + 32768) Shr 8);
      If Ch = 2 Then WrB(A + 1, (V + 32768) Shr 8);
    End
    Else
    Begin
      WrB(A, V And 255); WrB(A + 1, (V Shr 8) And 255);
      If Ch = 2 Then
      Begin
        WrB(A + 2, V And 255); WrB(A + 3, (V Shr 8) And 255);
      End;
    End;
    A := A + FB;
  End;
  MakeTone := N * FB;
End;

{ jouer jusqu'a la fin ; rend la plus grande position vue }
Function PlayAll(Rate, Bits, Ch : LongInt) : Boolean;
Var N, K, P, Mx : LongInt;
Begin
  N := MakeTone(Rate, Bits, Ch, 600);
  PlayAll := False;
  If MdmPlay(Buf, N, Rate, Bits, Ch) <> 0 Then Exit;
  Mx := 0; K := 0;
  While (MdmState <> 0) And (K < 300) Do
  Begin
    P := MdmPosition;
    If P > Mx Then Mx := P;
    Dummy0 := DosSleep(20);
    Inc(K);
  End;
  PlayAll := (MdmState = 0) And (Mx > N Div 4) And (Mx <= N);
End;

Var
  K, P1, P2, R, Rt, Bt, Cn : LongInt;
  S : String;

BEGIN
  Ok := 0; Bad := 0;
  Writeln('Essai de MDM.DLL (multimedia) et du pilote de la carte son');
  Buf := 0;
  Check('DosAllocMem 1 Mo (grand bloc)', DosAllocMem(LongInt(@Buf), 1048576, $13) = 0);
  Check('Grand bloc au-dela de 16 Mo', Buf >= $01000000);
  Caps := MdmAudioInfo(LongInt(@NameB), 255);
  Writeln('Carte son : ', GetP(LongInt(@NameB)));
  Card := Caps <> 0;
  NoRec := (Caps And 2) = 0;
  For K := 1 To ParamCount Do
  Begin
    If (ParamStr(K) = '/SANSCARTE') Or (ParamStr(K) = '/sanscarte') Then Card := False;
    If (ParamStr(K) = '/SANSENREG') Or (ParamStr(K) = '/sansenreg') Then NoRec := True;
  End;
  { erreurs et appareils sans carte }
  Check('mciGetErrorString', (MciGetErrorString(5012, LongInt(@NameB), 255) = 0) And (GetP(LongInt(@NameB)) = 'Fichier introuvable.'));
  Check('MCI commande inconnue', Mci('jouer tout') = 5006);
  Check('MCI appareil inconnu', Mci('play rien') = 5001);
  Check('MCI open new alias son', (Mci('open new type waveaudio alias son') = 0) And (Num(RetS) >= 1));
  Check('MCI alias en double', Mci('open new alias son') = 5048);
  Check('MCI set format', Mci('set son samplespersec 22050 bitspersample 16 channels 1') = 0);
  Check('MCI status samples per second', (Mci('status son samples per second') = 0) And (RetS = '22050'));
  Check('MCI status length (vide)', (Mci('status son length') = 0) And (RetS = '0'));
  Check('MCI status mode', (Mci('status son mode') = 0) And (RetS = 'stopped'));
  Check('MCI capability device type', (Mci('capability son device type') = 0) And (RetS = 'waveaudio'));
  Check('MCI open fichier absent', Mci('open C:\ABSENT.WAV alias x') = 5012);
  Check('MCI set audio volume', (Mci('set son audio volume 70') = 0) And (MdmVolume(-1) = 70));
  Dummy0 := MdmVolume(90);
  If Card Then
  Begin
    Check('Lecture 22 050 Hz 16 bits mono', PlayAll(22050, 16, 1));
    Check('Lecture 11 025 Hz 8 bits mono', PlayAll(11025, 8, 1));
    Check('Lecture 44 100 Hz 16 bits stereo', PlayAll(44100, 16, 2));
    Check('Lecture 22 050 Hz 8 bits stereo', PlayAll(22050, 8, 2));
    { pause, reprise, arret }
    R := MakeTone(22050, 16, 1, 1500);
    Check('MdmPlay', MdmPlay(Buf, R, 22050, 16, 1) = 0);
    Dummy0 := MdmCardFormat(LongInt(@Rt), LongInt(@Bt), LongInt(@Cn));
    Writeln('Format de la carte : ', Rt, ' Hz, ', Bt, ' bits, ', Cn, ' canal(aux)');
    Check('MdmCardFormat', (Rt > 0) And ((Bt = 8) Or (Bt = 16)));
    Dummy0 := DosSleep(300);
    Check('MdmState lecture', MdmState = 1);
    Dummy0 := MdmPause(1);
    P1 := MdmPosition;
    Dummy0 := DosSleep(200);
    P2 := MdmPosition;
    Check('Pause (position figee)', (MdmState = 3) And (P1 = P2) And (P1 > 0));
    Dummy0 := MdmPause(0);
    Dummy0 := DosSleep(300);
    Check('Reprise (la position avance)', (MdmState = 1) And (MdmPosition > P2));
    Dummy0 := MdmStop;
    Check('MdmStop', (MdmState = 0) And (MdmPosition = -1));
    { MCI : enregistrement (ou son synthetise), sauvegarde, relecture }
    If NoRec Then
    Begin
      { carte sans enregistrement : le son vient de C:\DEMARRE.WAV }
      Check('MCI close (sans enregistrement)', Mci('close son') = 0);
      Check('MCI open C:\DEMARRE.WAV', Mci('open C:\DEMARRE.WAV alias son') = 0);
    End
    Else Check('MCI record to 400', Mci('record son from 0 to 400 wait') = 0);
    Check('MCI status length', (Mci('status son length') = 0) And (Num(RetS) >= 390));
    Check('MCI save', Mci('save son D:\ESSAI.WAV') = 0);
    Check('MCI close', Mci('close son') = 0);
    Check('MCI open fichier WAV', Mci('open D:\ESSAI.WAV alias f wait') = 0);
    Check('MCI status bits per sample (fichier)', (Mci('status f bits per sample') = 0) And (RetS = '16'));
    Check('MCI set time format samples', Mci('set f time format samples') = 0);
    Check('MCI status length en echantillons', (Mci('status f length') = 0) And (Num(RetS) >= 8600));
    Check('MCI play wait', Mci('play f from 0 wait') = 0);
    Check('MCI status position (fin)', (Mci('status f position') = 0) And (Num(RetS) >= 8600));
    Check('MCI seek to start', (Mci('seek f to start') = 0) And (Mci('status f position') = 0) And (RetS = '0'));
    Check('MCI play (sans attendre) et mode', (Mci('play f') = 0) And (Mci('status f mode') = 0) And
          (RetS = 'playing'));
    Dummy0 := DosSleep(150);
    Check('MCI stop', (Mci('stop f') = 0) And (Mci('status f mode') = 0) And (RetS = 'stopped'));
    Check('MCI info product', (Mci('info f product') = 0) And (RetS <> ''));
    Check('MCI close all', Mci('close all') = 0);
  End
  Else Check('MCI close', Mci('close son') = 0);
  Check('DosFreeMem grand bloc', DosFreeMem(Buf) = 0);
  Writeln('TESTMDM : ', Ok, ' reussi(s), ', Bad, ' echec(s).');
END.
