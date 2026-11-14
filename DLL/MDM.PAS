{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 MDM.DLL de OS/2-0 (multimedia, MMPM/2 :
                interface de controle des medias MCI, son numerique).
}

Library MDM;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC MDM.PAS   (produit MDM.DLL)

  MDM.DLL est le "Media Device Manager" de MMPM/2 (Multimedia
  Presentation Manager/2, les extensions multimedia d'OS/2 Warp) : il
  recoit les commandes MCI des programmes et fait jouer ou enregistrer le
  son numerique par la carte son.

  Pilotes : un pilote de carte son est une DLL qui a un point d'entree
  AUDIOSTRATEGY (ordinal 1, paquet de requete : voir SBAUDIO.PAS). Le
  pilote est celui de la variable AUDIODRIVER de CONFIG.SYS
  (SET AUDIODRIVER=SBAUDIO, ICHAUDIO, ESAUDIO ou NONE) ; sans elle, MDM
  essaie ICHAUDIO.DLL (Intel AC'97), ESAUDIO.DLL (Ensoniq AudioPCI) puis
  SBAUDIO.DLL (Sound Blaster ; la variable BLASTER donne ses ressources)
  et garde le premier qui trouve sa carte.

  Flux : la carte lit (ou ecrit) en boucle un tampon circulaire ; un fil
  d'execution de MDM le remplit toutes les 10 ms environ en convertissant
  le son du programme au format de la carte (8 ou 16 bits, mono ou
  stereo, changement de frequence) et en appliquant le volume.

  Interface de chaines MCI (mciSendString), appareil "waveaudio" :
    open <fichier.WAV | waveaudio | new> [type waveaudio] [alias <nom>]
         [shareable] [wait]                 (rend le numero de l'appareil)
    play <a> [from n] [to n] [wait] [notify]
    record <a> [from n] [to n] [insert | overwrite] [wait] [notify]
    stop <a>   pause <a>   resume <a>   seek <a> to start | end | n
    status <a> length | position | mode | ready | volume | time format |
           number of channels | samples per second | bits per sample
    set <a> time format milliseconds | ms | samples | bytes
    set <a> audio volume n   set <a> channels | samplespersec |
           bitspersample n (appareil vide)
    save <a> [fichier]   close <a> | all   info <a> product | file
    capability <a> can play | can record | can save | has audio |
           device type | uses files
    sysinfo waveaudio quantity | name 1 | installname
  Les positions sont en millisecondes (par defaut), en echantillons ou
  en octets. "notify" poste MM_MCINOTIFY (0500h) a la fenetre donnee :
  mp1 = code (1 reussi, 2 remplace, 4 interrompu) + parametre utilisateur
  (mot haut), mp2 = numero de l'appareil + commande (mot haut).
  Codes d'erreur : 0 reussi, MCIERR_BASE (5000) + n (mciGetErrorString
  donne le texte).

  Points d'entree internes d'OS/2-0 (ordinaux 100 a 108), utilises par
  Audio numerique : MDMAUDIOINFO, MDMPLAY, MDMRECORD, MDMSTOP, MDMPAUSE,
  MDMPOSITION, MDMSTATE, MDMVOLUME, MDMCARDFORMAT. }

Const
  MAXDEV = 8;
  MCIERR_BASE = 5000;
  MCIERR_INVALID_DEVICE_ID = 5001;
  MCIERR_MISSING_COMMAND_STRING = 5003;
  MCIERR_UNRECOGNIZED_KEYWORD = 5005;
  MCIERR_UNRECOGNIZED_COMMAND = 5006;
  MCIERR_HARDWARE = 5007;
  MCIERR_INVALID_DEVICE_NAME = 5008;
  MCIERR_OUT_OF_MEMORY = 5009;
  MCIERR_DEVICE_OPEN = 5010;
  MCIERR_FILE_NOT_FOUND = 5012;
  MCIERR_OUTOFRANGE = 5013;
  MCIERR_MISSING_PARAMETER = 5016;
  MCIERR_INVALID_FILE = 5018;
  MCIERR_FILE_NOT_SAVED = 5019;
  MCIERR_DUPLICATE_ALIAS = 5048;
  MCIERR_DEVICE_LOCKED = 5050;
  MCIERR_NO_CARD = 5053;
  MM_MCINOTIFY = $0500;
  MCI_PLAY = 4; MCI_RECORD = 14;
  NEWCAP = 4194304;                 { capacite d'un appareil vide (4 Mo) }

Var
  { pilote }
  DrvTried, DrvFn, DrvH, DrvCaps : LongInt;
  DrvName, CardName : String;
  Req : Array[0..15] Of LongInt;
  { flux en cours }
  State, Paused, StopReq, ThreadOn, Done, Tid, Stall, Failed : LongInt;
  SrcAddr, SrcBytes, SrcRate, SrcBits, SrcCh, SrcFB, SrcFrames : LongInt;
  StartFrame, EndFrame, SrcIdx, SrcFrac, PausePos : LongInt;
  DevRate, DevBits, DevCh, DevFB, RingA, RingSz : LongInt;
  Filled, LastHw, WritePos, DevDone, NeedDev : LongInt;
  RecPos, RecMax, RecAcc : LongInt;
  Volume : LongInt;
  { notification de fin }
  NotHwnd, NotUser, NotDev, NotCmd, PostFn : LongInt;
  { appareils MCI waveaudio }
  DUse, DData, DCap, DBytes, DRate, DBits, DCh, DPos, DTime, DMine : Array[0..MAXDEV - 1] Of LongInt;
  DAlias, DFile : Array[0..MAXDEV - 1] Of String[79];
  NameZ, FailBuf : Array[0..259] Of Byte;
  Hdr : Array[0..63] Of Byte;
  Dummy : LongInt;

Function DosLoadModule(PObj, Cb, PName, PH : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeModule(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeMem(Pb : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function RdB(A : LongInt) : LongInt;
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrB(A, V : LongInt);
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
End;

Function RdW(A : LongInt) : LongInt;
Begin
  RdW := RdB(A) Or (RdB(A + 1) Shl 8);
End;

Function RdSW(A : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := RdB(A) Or (RdB(A + 1) Shl 8);
  If V >= 32768 Then V := V - 65536;
  RdSW := V;
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Function RdL(A : LongInt) : LongInt;
Type PL = ^LongInt;
Var Q : PL;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Procedure WrL(A, V : LongInt);
Type PL = ^LongInt;
Var Q : PL;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@NameZ), S);
  Z := LongInt(@NameZ);
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    K := 0;
    While (K < 255) And (RdB(A + K) <> 0) Do
    Begin
      S := S + Chr(RdB(A + K));
      Inc(K);
    End;
  End;
  GetZ := S;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Env(Name : String) : String;
Var P : LongInt;
Begin
  P := 0;
  If DosScanEnv(Z(Name), LongInt(@P)) = 0 Then Env := GetZ(P) Else Env := '';
End;

{ A * B / C sans depasser 32 bits (A, B, C positifs) }
Function MulDiv(A, B, C : LongInt) : LongInt;
Begin
  If C <= 0 Then
  Begin
    MulDiv := 0;
    Exit;
  End;
  MulDiv := (A Div C) * B + ((A Mod C) * B) Div C;
End;

{ appel d'une fonction par son adresse (un parametre) }
Function CallPtr1(F, A1 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,4
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr1 := R;
End;

{ appel d'une fonction d'une DLL d'OS2PC a quatre parametres (empiles
  dans l'ordre, pile nettoyee par l'appelant) }
Function CallPas4(F, A1, A2, A3, A4 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A1
    push eax
    mov eax,A2
    push eax
    mov eax,A3
    push eax
    mov eax,A4
    push eax
    mov eax,F
    call eax
    add esp,16
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPas4 := R;
End;

{ ==================================================================== }
{ Pilote de la carte son                                                }
{ ==================================================================== }

Function CallDrv(Cmd : LongInt) : LongInt;
Begin
  Req[0] := Cmd; Req[1] := 0;
  If DrvFn = 0 Then
  Begin
    CallDrv := 19;
    Exit;
  End;
  CallDrv := CallPtr1(DrvFn, LongInt(@Req));
End;

Function TryDriver(N : String) : Boolean;
Var H, F, B : LongInt;
Begin
  TryDriver := False;
  H := 0; F := 0;
  If DosLoadModule(LongInt(@FailBuf), 128, Z(N), LongInt(@H)) <> 0 Then Exit;
  If (DosQueryProcAddr(H, 1, 0, LongInt(@F)) <> 0) Or (F = 0) Then
  Begin
    Dummy := DosFreeModule(H);
    Exit;
  End;
  DrvFn := F;
  B := 0;
  If DosScanEnv(Z('BLASTER'), LongInt(@B)) <> 0 Then B := 0;
  Req[2] := B;
  If (CallDrv(1) = 0) And (Req[1] = 0) Then
  Begin
    DrvH := H; DrvCaps := Req[3];
    CardName := GetZ(Req[4]);
    DrvName := UpStr(N);
    TryDriver := True;
  End
  Else
  Begin
    DrvFn := 0;
    Dummy := DosFreeModule(H);
  End;
End;

Function DriverReady : Boolean;
Var S : String;
Begin
  If DrvTried = 0 Then
  Begin
    DrvTried := 1;
    S := UpStr(Env('AUDIODRIVER'));
    If (Pos('.', S) > 0) Then S := Copy(S, 1, Pos('.', S) - 1);
    While (Pos('\', S) > 0) Do S := Copy(S, Pos('\', S) + 1, 255);
    If S = 'NONE' Then
    Else If S <> '' Then Dummy := Ord(TryDriver(S))
    Else If Not TryDriver('ICHAUDIO') Then
      If Not TryDriver('ESAUDIO') Then Dummy := Ord(TryDriver('SBAUDIO'));
  End;
  DriverReady := DrvFn <> 0;
End;

{ ==================================================================== }
{ Conversion des echantillons                                           }
{ ==================================================================== }

Var
  SmpL, SmpR : LongInt;

{ trame I du son du programme -> SmpL, SmpR (16 bits signes) }
Procedure GetSrc(I : LongInt);
Var A : LongInt;
Begin
  A := SrcAddr + I * SrcFB;
  If SrcBits = 8 Then
  Begin
    SmpL := (RdB(A) - 128) * 256;
    If SrcCh = 2 Then SmpR := (RdB(A + 1) - 128) * 256 Else SmpR := SmpL;
  End
  Else
  Begin
    SmpL := RdSW(A);
    If SrcCh = 2 Then SmpR := RdSW(A + 2) Else SmpR := SmpL;
  End;
End;

Function Clip(V : LongInt) : LongInt;
Begin
  If V > 32767 Then V := 32767;
  If V < -32768 Then V := -32768;
  Clip := V;
End;

{ SmpL, SmpR -> une trame de la carte a l'adresse A }
Procedure PutDev(A : LongInt);
Var L, R : LongInt;
Begin
  L := Clip((SmpL * Volume) Div 100); R := Clip((SmpR * Volume) Div 100);
  If DevCh = 1 Then
  Begin
    L := (L + R) Div 2;
    If DevBits = 8 Then WrB(A, (L + 32768) Shr 8) Else WrW(A, L);
  End
  Else If DevBits = 8 Then
  Begin
    WrB(A, (L + 32768) Shr 8); WrB(A + 1, (R + 32768) Shr 8);
  End
  Else
  Begin
    WrW(A, L); WrW(A + 2, R);
  End;
End;

{ trame de la carte a l'adresse A -> SmpL, SmpR }
Procedure GetDev(A : LongInt);
Begin
  If DevBits = 8 Then
  Begin
    SmpL := (RdB(A) - 128) * 256;
    If DevCh = 2 Then SmpR := (RdB(A + 1) - 128) * 256 Else SmpR := SmpL;
  End
  Else
  Begin
    SmpL := RdSW(A);
    If DevCh = 2 Then SmpR := RdSW(A + 2) Else SmpR := SmpL;
  End;
End;

{ SmpL, SmpR -> trame du programme a l'adresse A }
Procedure PutSrc(A : LongInt);
Var L : LongInt;
Begin
  If SrcCh = 1 Then
  Begin
    L := (SmpL + SmpR) Div 2;
    If SrcBits = 8 Then WrB(A, (L + 32768) Shr 8) Else WrW(A, L);
  End
  Else If SrcBits = 8 Then
  Begin
    WrB(A, (SmpL + 32768) Shr 8); WrB(A + 1, (SmpR + 32768) Shr 8);
  End
  Else
  Begin
    WrW(A, SmpL); WrW(A + 2, SmpR);
  End;
End;

{ remplir N octets du tampon circulaire (lecture) }
Procedure FillRing(N : LongInt);
Begin
  While N >= DevFB Do
  Begin
    If SrcIdx < EndFrame Then GetSrc(SrcIdx)
    Else
    Begin
      SmpL := 0; SmpR := 0;
    End;
    PutDev(RingA + WritePos);
    WritePos := WritePos + DevFB;
    If WritePos >= RingSz Then WritePos := 0;
    Filled := Filled + DevFB;
    N := N - DevFB;
    SrcFrac := SrcFrac + SrcRate;
    While SrcFrac >= DevRate Do
    Begin
      SrcFrac := SrcFrac - DevRate;
      Inc(SrcIdx);
    End;
  End;
End;

{ ==================================================================== }
{ Fil du flux                                                           }
{ ==================================================================== }

Function PlayPos : LongInt;
Begin
  If Paused <> 0 Then PlayPos := PausePos
  Else PlayPos := StartFrame + MulDiv(DevDone, SrcRate, DevRate);
End;

Procedure PollPlay;
Var Hw, Delta : LongInt;
Begin
  If CallDrv(4) <> 0 Then Exit;
  Hw := Req[2];
  Delta := (Hw - LastHw + RingSz) Mod RingSz;
  LastHw := Hw;
  { carte arretee (aucune progression pendant 3 s) : fin en erreur }
  If Delta = 0 Then Inc(Stall) Else Stall := 0;
  If Stall > 300 Then
  Begin
    Failed := 1; Done := 1;
    Exit;
  End;
  Filled := Filled - Delta;
  If Filled < 0 Then Filled := 0;
  DevDone := DevDone + Delta Div DevFB;
  If DevDone >= NeedDev Then
  Begin
    Done := 1;
    Exit;
  End;
  FillRing(RingSz - Filled);
End;

Procedure PollRecord;
Var Hw, Avail : LongInt;
Begin
  If CallDrv(4) <> 0 Then Exit;
  Hw := Req[2];
  Avail := (Hw - LastHw + RingSz) Mod RingSz;
  If Avail = 0 Then Inc(Stall) Else Stall := 0;
  If Stall > 300 Then
  Begin
    Failed := 1; Done := 1;
    Exit;
  End;
  While Avail >= DevFB Do
  Begin
    GetDev(RingA + LastHw);
    LastHw := LastHw + DevFB;
    If LastHw >= RingSz Then LastHw := 0;
    Avail := Avail - DevFB;
    RecAcc := RecAcc + SrcRate;
    While RecAcc >= DevRate Do
    Begin
      RecAcc := RecAcc - DevRate;
      If RecPos + SrcFB <= RecMax Then
      Begin
        PutSrc(SrcAddr + RecPos);
        RecPos := RecPos + SrcFB;
      End
      Else Done := 1;
    End;
  End;
End;

Procedure Notify(Code : LongInt);
Var H : LongInt;
Begin
  If NotHwnd = 0 Then Exit;
  If PostFn = 0 Then
  Begin
    H := 0;
    If DosLoadModule(LongInt(@FailBuf), 128, Z('PMWIN'), LongInt(@H)) = 0 Then
      If DosQueryProcAddr(H, 0, Z('WinPostMsg'), LongInt(@PostFn)) <> 0 Then PostFn := 0;
  End;
  If PostFn <> 0 Then
    Dummy := CallPas4(PostFn, NotHwnd, MM_MCINOTIFY, Code Or (NotUser Shl 16), NotDev Or (NotCmd Shl 16));
  NotHwnd := 0;
End;

Function AudioThread(Param : LongInt) : LongInt;
Begin
  While (StopReq = 0) And (Done = 0) Do
  Begin
    If Paused = 0 Then
    Begin
      If State = 1 Then PollPlay Else If State = 2 Then PollRecord;
    End;
    If Done = 0 Then Dummy := DosSleep(10);
  End;
  Dummy := CallDrv(5);
  If Failed <> 0 Then Notify($100)
  Else If (Done <> 0) And (StopReq = 0) Then Notify(1)
  Else If NotHwnd <> 0 Then Notify(4);
  State := 0; Paused := 0;
  ThreadOn := 0;
  AudioThread := 0;
End;

{ arreter le flux en cours (attendre la fin du fil) }
Procedure StopStream;
Var K : LongInt;
Begin
  If ThreadOn = 0 Then
  Begin
    State := 0; Paused := 0;
    Exit;
  End;
  StopReq := 1;
  K := 0;
  While (ThreadOn <> 0) And (K < 300) Do
  Begin
    Dummy := DosSleep(10);
    Inc(K);
  End;
  If ThreadOn <> 0 Then
  Begin
    Dummy := CallDrv(5);
    ThreadOn := 0; State := 0;
  End;
  Paused := 0;
End;

{ ouvrir la carte au format du son et demarrer (lecture : depuis la
  trame StartFrame) }
Function StartDev(Dir : LongInt) : LongInt;
Begin
  StartDev := MCIERR_NO_CARD;
  Req[2] := Dir; Req[3] := SrcRate; Req[4] := SrcBits; Req[5] := SrcCh;
  If (CallDrv(2) <> 0) Or (Req[1] <> 0) Then Exit;
  DevRate := Req[6]; DevBits := Req[7]; DevCh := Req[8]; RingA := Req[9]; RingSz := Req[10];
  If (DevRate <= 0) Or (RingA = 0) Or (RingSz <= 0) Then Exit;
  DevFB := (DevBits Div 8) * DevCh;
  RingSz := RingSz - RingSz Mod DevFB;
  LastHw := 0; WritePos := 0; Filled := 0; DevDone := 0; RecAcc := 0;
  If Dir = 0 Then
  Begin
    SrcIdx := StartFrame; SrcFrac := 0;
    NeedDev := MulDiv(EndFrame - StartFrame, DevRate, SrcRate) + 1;
    FillRing(RingSz);
  End;
  If CallDrv(3) <> 0 Then Exit;
  StartDev := 0;
End;

Function Launch(St : LongInt) : LongInt;
Var R : LongInt;
Begin
  StopReq := 0; Done := 0; Paused := 0; Stall := 0; Failed := 0;
  R := StartDev(St - 1);
  If R <> 0 Then
  Begin
    Launch := R;
    Exit;
  End;
  State := St;
  ThreadOn := 1;
  If DosCreateThread(LongInt(@Tid), LongInt(@AudioThread), 0, 0, 16384) <> 0 Then
  Begin
    ThreadOn := 0; State := 0;
    Dummy := CallDrv(5);
    Launch := MCIERR_HARDWARE;
    Exit;
  End;
  Launch := 0;
End;

Procedure SetFormat(Addr, Bytes, Rate, Bits, Ch : LongInt);
Begin
  If (Bits <> 8) And (Bits <> 16) Then Bits := 16;
  If (Ch <> 1) And (Ch <> 2) Then Ch := 1;
  If Rate < 1000 Then Rate := 1000;
  If Rate > 96000 Then Rate := 96000;
  SrcAddr := Addr; SrcBytes := Bytes; SrcRate := Rate; SrcBits := Bits; SrcCh := Ch;
  SrcFB := (Bits Div 8) * Ch;
  SrcFrames := Bytes Div SrcFB;
End;

{ ==================================================================== }
{ Points d'entree internes (Audio numerique)                            }
{ ==================================================================== }

{ nom de la carte (et du pilote) ; rend les possibilites (0 : aucune
  carte, 1 lecture, 2 enregistrement) }
Function MdmAudioInfo(PBuf, Len : LongInt) : LongInt;
Var S : String;
Begin
  If DriverReady Then S := CardName + ' (' + DrvName + '.DLL)' Else S := 'Aucune carte son';
  If (PBuf <> 0) And (Len > 0) Then
  Begin
    If Length(S) > Len - 1 Then S := Copy(S, 1, Len - 1);
    PutZ(PBuf, S);
  End;
  If DriverReady Then MdmAudioInfo := DrvCaps Or 1 Else MdmAudioInfo := 0;
End;

{ jouer Bytes octets du son en PData (format Rate, Bits, Ch) }
Function MdmPlay(PData, Bytes, Rate, Bits, Ch : LongInt) : LongInt;
Begin
  StopStream;
  If Not DriverReady Then
  Begin
    MdmPlay := MCIERR_NO_CARD;
    Exit;
  End;
  SetFormat(PData, Bytes, Rate, Bits, Ch);
  StartFrame := 0; EndFrame := SrcFrames;
  NotHwnd := 0;
  MdmPlay := Launch(1);
End;

{ enregistrer au plus MaxBytes octets en PData }
Function MdmRecord(PData, MaxBytes, Rate, Bits, Ch : LongInt) : LongInt;
Begin
  StopStream;
  If Not DriverReady Then
  Begin
    MdmRecord := MCIERR_NO_CARD;
    Exit;
  End;
  SetFormat(PData, MaxBytes, Rate, Bits, Ch);
  RecPos := 0; RecMax := MaxBytes - MaxBytes Mod SrcFB;
  NotHwnd := 0;
  MdmRecord := Launch(2);
End;

Function MdmStop : LongInt;
Begin
  StopStream;
  MdmStop := 0;
End;

{ 1 : pause, 0 : reprise }
Function MdmPause(On : LongInt) : LongInt;
Begin
  MdmPause := 0;
  If State = 0 Then Exit;
  If (On <> 0) And (Paused = 0) Then
  Begin
    If State = 1 Then PausePos := PlayPos;
    Paused := 1;
    Dummy := CallDrv(5);
  End
  Else If (On = 0) And (Paused <> 0) Then
  Begin
    If State = 1 Then StartFrame := PausePos;
    Paused := 0; Stall := 0;
    MdmPause := StartDev(State - 1);
  End;
End;

{ le programme qui interroge le flux l'alimente aussi : un programme de
  PM n'est pas preempte, et son fil principal peut priver le fil du flux
  du processeur }
Procedure Service;
Begin
  If (ThreadOn <> 0) And (Paused = 0) And (Done = 0) And (StopReq = 0) Then
  Begin
    If State = 1 Then PollPlay Else If State = 2 Then PollRecord;
  End;
End;

{ position (octets du son) : lecture, enregistrement }
Function MdmPosition : LongInt;
Begin
  Service;
  If State = 1 Then MdmPosition := PlayPos * SrcFB
  Else If State = 2 Then MdmPosition := RecPos
  Else MdmPosition := -1;
End;

{ 0 arret, 1 lecture, 2 enregistrement ; + 2 en pause }
Function MdmState : LongInt;
Begin
  Service;
  If (State <> 0) And (Paused <> 0) Then MdmState := State + 2 Else MdmState := State;
End;

{ volume 0 a 100 (-1 : le demander) }
Function MdmVolume(V : LongInt) : LongInt;
Begin
  If V >= 0 Then
  Begin
    If V > 100 Then V := 100;
    Volume := V;
  End;
  MdmVolume := Volume;
End;

{ format de la carte pendant le flux : frequence, bits, canaux }
Function MdmCardFormat(PRate, PBits, PCh : LongInt) : LongInt;
Begin
  If PRate <> 0 Then WrL(PRate, DevRate);
  If PBits <> 0 Then WrL(PBits, DevBits);
  If PCh <> 0 Then WrL(PCh, DevCh);
  MdmCardFormat := State;
End;

{ ==================================================================== }
{ Fichiers WAV                                                          }
{ ==================================================================== }

{ charger un fichier RIFF WAVE (PCM) dans l'appareil D }
Function LoadWav(D : LongInt; F : String) : LongInt;
Var H, A, N, Id, Sz, Pos0, Fmt, Got, Blk : LongInt; HaveFmt : Boolean;
Begin
  LoadWav := MCIERR_FILE_NOT_FOUND;
  H := 0; A := 0;
  If DosOpen(Z(F), LongInt(@H), LongInt(@A), 0, 0, $01, $40, 0) <> 0 Then Exit;
  LoadWav := MCIERR_INVALID_FILE;
  N := 0;
  If (DosRead(H, LongInt(@Hdr), 12, LongInt(@N)) <> 0) Or (N <> 12) Or (RdL(LongInt(@Hdr)) <> $46464952) Or
     (RdL(LongInt(@Hdr) + 8) <> $45564157) Then
  Begin
    Dummy := DosClose(H);
    Exit;
  End;
  Pos0 := 12; HaveFmt := False;
  Repeat
    N := 0;
    If (DosRead(H, LongInt(@Hdr), 8, LongInt(@N)) <> 0) Or (N <> 8) Then
    Begin
      Dummy := DosClose(H);
      Exit;
    End;
    Id := RdL(LongInt(@Hdr)); Sz := RdL(LongInt(@Hdr) + 4);
    Pos0 := Pos0 + 8;
    If Id = $20746D66 Then
    Begin
      { 'fmt ' : format PCM }
      N := 0;
      Dummy := DosRead(H, LongInt(@Hdr) + 8, 16, LongInt(@N));
      Fmt := RdW(LongInt(@Hdr) + 8);
      DCh[D] := RdW(LongInt(@Hdr) + 10);
      DRate[D] := RdL(LongInt(@Hdr) + 12);
      DBits[D] := RdW(LongInt(@Hdr) + 22);
      If (Fmt <> 1) Or ((DBits[D] <> 8) And (DBits[D] <> 16)) Or (DCh[D] < 1) Or (DCh[D] > 2) Then
      Begin
        Dummy := DosClose(H);
        Exit;
      End;
      HaveFmt := True;
      Pos0 := Pos0 + ((Sz + 1) And Not 1);
      Dummy := DosSetFilePtr(H, Pos0, 0, LongInt(@N));
    End
    Else If Id <> $61746164 Then
    Begin
      Pos0 := Pos0 + ((Sz + 1) And Not 1);
      Dummy := DosSetFilePtr(H, Pos0, 0, LongInt(@N));
    End;
  Until Id = $61746164;
  If Not HaveFmt Then
  Begin
    Dummy := DosClose(H);
    Exit;
  End;
  { 'data' : le son }
  Blk := 0;
  If DosAllocMem(LongInt(@Blk), Sz + 4096, $13) <> 0 Then
  Begin
    Dummy := DosClose(H);
    LoadWav := MCIERR_OUT_OF_MEMORY;
    Exit;
  End;
  Got := 0;
  Dummy := DosRead(H, Blk, Sz, LongInt(@Got));
  Dummy := DosClose(H);
  DData[D] := Blk; DCap[D] := Sz + 4096; DBytes[D] := Got;
  LoadWav := 0;
End;

Function SaveWav(D : LongInt; F : String) : LongInt;
Var H, A, N, FB : LongInt;
Begin
  SaveWav := MCIERR_FILE_NOT_SAVED;
  H := 0; A := 0;
  If DosOpen(Z(F), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0) <> 0 Then Exit;
  FB := (DBits[D] Div 8) * DCh[D];
  WrL(LongInt(@Hdr), $46464952); WrL(LongInt(@Hdr) + 4, 36 + DBytes[D]);
  WrL(LongInt(@Hdr) + 8, $45564157); WrL(LongInt(@Hdr) + 12, $20746D66);
  WrL(LongInt(@Hdr) + 16, 16); WrW(LongInt(@Hdr) + 20, 1); WrW(LongInt(@Hdr) + 22, DCh[D]);
  WrL(LongInt(@Hdr) + 24, DRate[D]); WrL(LongInt(@Hdr) + 28, DRate[D] * FB);
  WrW(LongInt(@Hdr) + 32, FB); WrW(LongInt(@Hdr) + 34, DBits[D]);
  WrL(LongInt(@Hdr) + 36, $61746164); WrL(LongInt(@Hdr) + 40, DBytes[D]);
  N := 0;
  Dummy := DosWrite(H, LongInt(@Hdr), 44, LongInt(@N));
  If DBytes[D] > 0 Then Dummy := DosWrite(H, DData[D], DBytes[D], LongInt(@N));
  Dummy := DosClose(H);
  SaveWav := 0;
End;

{ ==================================================================== }
{ Interface de chaines MCI                                              }
{ ==================================================================== }

Var
  Tok : Array[0..23] Of String[79];
  NTok : LongInt;
  RetS : String;

Procedure Tokenize(S : String);
Var K : LongInt; T : String; Q : Boolean;
Begin
  NTok := 0;
  K := 1;
  While (K <= Length(S)) And (NTok < 24) Do
  Begin
    While (K <= Length(S)) And (S[K] <= ' ') Do Inc(K);
    If K > Length(S) Then Break;
    T := '';
    Q := S[K] = '"';
    If Q Then
    Begin
      Inc(K);
      While (K <= Length(S)) And (S[K] <> '"') Do
      Begin
        T := T + S[K];
        Inc(K);
      End;
      Inc(K);
    End
    Else
      While (K <= Length(S)) And (S[K] > ' ') Do
      Begin
        T := T + S[K];
        Inc(K);
      End;
    Tok[NTok] := T;
    Inc(NTok);
  End;
End;

Function TokU(I : LongInt) : String;
Begin
  If I < NTok Then TokU := UpStr(Tok[I]) Else TokU := '';
End;

{ appareil d'apres son alias ou son numero }
Function FindDev(S : String) : LongInt;
Var K, V, C : LongInt;
Begin
  FindDev := -1;
  S := UpStr(S);
  Val(S, V, C);
  If (C = 0) And (V >= 1) And (V <= MAXDEV) And (DUse[V - 1] <> 0) Then
  Begin
    FindDev := V - 1;
    Exit;
  End;
  For K := 0 To MAXDEV - 1 Do
    If (DUse[K] <> 0) And (DAlias[K] = S) Then FindDev := K;
End;

Function DevFB0(D : LongInt) : LongInt;
Begin
  DevFB0 := (DBits[D] Div 8) * DCh[D];
End;

{ position (en trames) -> unite de l'appareil, et l'inverse }
Function ToUnits(D, Fr : LongInt) : LongInt;
Begin
  Case DTime[D] Of
    1 : ToUnits := Fr;
    2 : ToUnits := Fr * DevFB0(D);
  Else
    ToUnits := MulDiv(Fr, 1000, DRate[D]);
  End;
End;

Function FromUnits(D, U : LongInt) : LongInt;
Begin
  Case DTime[D] Of
    1 : FromUnits := U;
    2 : FromUnits := U Div DevFB0(D);
  Else
    FromUnits := MulDiv(U, DRate[D], 1000);
  End;
End;

{ l'appareil D est-il celui du flux en cours ? }
Function Streaming(D : LongInt) : Boolean;
Begin
  Streaming := (State <> 0) And (NotDev = D + 1) And (SrcAddr = DData[D]);
End;

Procedure SyncPos(D : LongInt);
Begin
  If Streaming(D) Then
  Begin
    If State = 1 Then DPos[D] := PlayPos
    Else DPos[D] := DPos[D] + 0;
  End;
End;

Function NumArg(K : LongInt; Var V : LongInt) : Boolean;
Var C : LongInt;
Begin
  Val(Tok[K], V, C);
  NumArg := (K < NTok) And (C = 0);
End;

Function CmdOpen(PRet : LongInt) : LongInt;
Var D, K : LongInt; Elem, Alias, T : String;
Begin
  CmdOpen := MCIERR_MISSING_PARAMETER;
  If NTok < 2 Then Exit;
  Elem := Tok[1]; Alias := '';
  K := 2;
  While K < NTok Do
  Begin
    T := TokU(K);
    If (T = 'ALIAS') And (K + 1 < NTok) Then
    Begin
      Alias := UpStr(Tok[K + 1]);
      Inc(K);
    End
    Else If (T = 'TYPE') And (K + 1 < NTok) Then
    Begin
      If TokU(K + 1) <> 'WAVEAUDIO' Then
      Begin
        CmdOpen := MCIERR_INVALID_DEVICE_NAME;
        Exit;
      End;
      Inc(K);
    End
    Else If (T <> 'SHAREABLE') And (T <> 'WAIT') And (T <> 'NOTIFY') And (T <> 'READONLY') Then
    Begin
      CmdOpen := MCIERR_UNRECOGNIZED_KEYWORD;
      Exit;
    End;
    Inc(K);
  End;
  If (Alias <> '') And (FindDev(Alias) >= 0) Then
  Begin
    CmdOpen := MCIERR_DUPLICATE_ALIAS;
    Exit;
  End;
  D := -1;
  For K := MAXDEV - 1 DownTo 0 Do
    If DUse[K] = 0 Then D := K;
  If D < 0 Then
  Begin
    CmdOpen := MCIERR_DEVICE_LOCKED;
    Exit;
  End;
  DData[D] := 0; DCap[D] := 0; DBytes[D] := 0; DPos[D] := 0; DTime[D] := 0;
  DRate[D] := 11025; DBits[D] := 8; DCh[D] := 1; DFile[D] := '';
  T := UpStr(Elem);
  If (T = 'WAVEAUDIO') Or (T = 'NEW') Then
  Begin
    K := 0;
    If DosAllocMem(LongInt(@K), NEWCAP, $13) <> 0 Then
    Begin
      CmdOpen := MCIERR_OUT_OF_MEMORY;
      Exit;
    End;
    DData[D] := K; DCap[D] := NEWCAP;
  End
  Else
  Begin
    K := LoadWav(D, Elem);
    If K <> 0 Then
    Begin
      CmdOpen := K;
      Exit;
    End;
    DFile[D] := Elem;
  End;
  If Alias = '' Then Alias := IStr(D + 1);
  DAlias[D] := Alias;
  DUse[D] := 1;
  RetS := IStr(D + 1);
  CmdOpen := 0;
End;

Procedure CloseDev(D : LongInt);
Begin
  If Streaming(D) Then StopStream;
  If DData[D] <> 0 Then Dummy := DosFreeMem(DData[D]);
  DData[D] := 0; DUse[D] := 0;
End;

{ jouer ou enregistrer (Rec) : from, to, wait, notify }
Function CmdPlayRec(D : LongInt; Rec : Boolean; Hwnd, User : LongInt) : LongInt;
Var K, V, Fr, ToF : LongInt; T : String; Wait, Nfy : Boolean;
Begin
  CmdPlayRec := 0;
  SyncPos(D);
  Fr := DPos[D];
  If Rec Then ToF := DCap[D] Div DevFB0(D) Else ToF := DBytes[D] Div DevFB0(D);
  Wait := False; Nfy := False;
  K := 2;
  While K < NTok Do
  Begin
    T := TokU(K);
    If (T = 'FROM') And NumArg(K + 1, V) Then
    Begin
      Fr := FromUnits(D, V);
      Inc(K);
    End
    Else If (T = 'TO') And NumArg(K + 1, V) Then
    Begin
      ToF := FromUnits(D, V);
      Inc(K);
    End
    Else If T = 'WAIT' Then Wait := True
    Else If T = 'NOTIFY' Then Nfy := True
    Else If (T <> 'INSERT') And (T <> 'OVERWRITE') Then
    Begin
      CmdPlayRec := MCIERR_UNRECOGNIZED_KEYWORD;
      Exit;
    End;
    Inc(K);
  End;
  If Not DriverReady Then
  Begin
    CmdPlayRec := MCIERR_NO_CARD;
    Exit;
  End;
  StopStream;
  If Rec Then
  Begin
    If ToF > DCap[D] Div DevFB0(D) Then ToF := DCap[D] Div DevFB0(D);
    If (Fr < 0) Or (Fr >= ToF) Then
    Begin
      CmdPlayRec := MCIERR_OUTOFRANGE;
      Exit;
    End;
    SetFormat(DData[D] + Fr * DevFB0(D), (ToF - Fr) * DevFB0(D), DRate[D], DBits[D], DCh[D]);
    RecPos := 0; RecMax := SrcBytes;
    NotDev := D + 1; NotCmd := MCI_RECORD;
  End
  Else
  Begin
    If ToF > DBytes[D] Div DevFB0(D) Then ToF := DBytes[D] Div DevFB0(D);
    If (Fr < 0) Or (Fr > ToF) Then
    Begin
      CmdPlayRec := MCIERR_OUTOFRANGE;
      Exit;
    End;
    SetFormat(DData[D], DBytes[D], DRate[D], DBits[D], DCh[D]);
    StartFrame := Fr; EndFrame := ToF;
    NotDev := D + 1; NotCmd := MCI_PLAY;
  End;
  If Nfy Then
  Begin
    NotHwnd := Hwnd; NotUser := User;
  End
  Else NotHwnd := 0;
  If Rec Then V := Launch(2) Else V := Launch(1);
  If V <> 0 Then
  Begin
    CmdPlayRec := V;
    Exit;
  End;
  If Rec Then DMine[D] := Fr;
  If Wait Then
  Begin
    While ThreadOn <> 0 Do Dummy := DosSleep(20);
    If Failed <> 0 Then CmdPlayRec := MCIERR_HARDWARE;
    If Rec Then
    Begin
      DPos[D] := Fr + RecPos Div DevFB0(D);
      If DPos[D] * DevFB0(D) > DBytes[D] Then DBytes[D] := DPos[D] * DevFB0(D);
    End
    Else DPos[D] := ToF;
  End;
End;

{ fin d'un enregistrement : la taille du son suit ce qui a ete enregistre }
Procedure EndRecord(D : LongInt);
Begin
  If Streaming(D) And (State = 2) Then
  Begin
    DPos[D] := DMine[D] + RecPos Div DevFB0(D);
    StopStream;
    If DPos[D] * DevFB0(D) > DBytes[D] Then DBytes[D] := DPos[D] * DevFB0(D);
  End;
End;

Function CmdStatus(D : LongInt) : LongInt;
Var T : String;
Begin
  CmdStatus := 0;
  T := '';
  For Dummy := 2 To NTok - 1 Do
  Begin
    If T <> '' Then T := T + ' ';
    T := T + TokU(Dummy);
  End;
  If (State = 0) Or Not Streaming(D) Then
  Else If State = 1 Then DPos[D] := PlayPos
  Else DPos[D] := DMine[D] + RecPos Div DevFB0(D);
  If T = 'LENGTH' Then RetS := IStr(ToUnits(D, DBytes[D] Div DevFB0(D)))
  Else If T = 'POSITION' Then RetS := IStr(ToUnits(D, DPos[D]))
  Else If T = 'MODE' Then
  Begin
    If Not Streaming(D) Then RetS := 'stopped'
    Else If Paused <> 0 Then RetS := 'paused'
    Else If State = 1 Then RetS := 'playing'
    Else RetS := 'recording';
  End
  Else If T = 'READY' Then
  Begin
    If DriverReady Then RetS := 'TRUE' Else RetS := 'FALSE';
  End
  Else If T = 'VOLUME' Then RetS := IStr(Volume) + ':' + IStr(Volume)
  Else If T = 'NUMBER OF CHANNELS' Then RetS := IStr(DCh[D])
  Else If (T = 'SAMPLES PER SECOND') Or (T = 'SAMPLESPERSEC') Then RetS := IStr(DRate[D])
  Else If (T = 'BITS PER SAMPLE') Or (T = 'BITSPERSAMPLE') Then RetS := IStr(DBits[D])
  Else If T = 'TIME FORMAT' Then
  Begin
    Case DTime[D] Of
      1 : RetS := 'samples';
      2 : RetS := 'bytes';
    Else
      RetS := 'milliseconds';
    End;
  End
  Else If T = 'MEDIA PRESENT' Then RetS := 'TRUE'
  Else CmdStatus := MCIERR_UNRECOGNIZED_KEYWORD;
End;

Function CmdSet(D : LongInt) : LongInt;
Var K, V : LongInt; T : String;
Begin
  CmdSet := 0;
  K := 2;
  While K < NTok Do
  Begin
    T := TokU(K);
    If (T = 'TIME') And (TokU(K + 1) = 'FORMAT') Then
    Begin
      T := TokU(K + 2);
      If (T = 'MILLISECONDS') Or (T = 'MS') Then DTime[D] := 0
      Else If T = 'SAMPLES' Then DTime[D] := 1
      Else If T = 'BYTES' Then DTime[D] := 2
      Else
      Begin
        CmdSet := MCIERR_UNRECOGNIZED_KEYWORD;
        Exit;
      End;
      K := K + 3;
    End
    Else If (T = 'AUDIO') And (TokU(K + 1) = 'VOLUME') And NumArg(K + 2, V) Then
    Begin
      Dummy := MdmVolume(V);
      K := K + 3;
    End
    Else If ((T = 'CHANNELS') Or (T = 'SAMPLESPERSEC') Or (T = 'BITSPERSAMPLE')) And NumArg(K + 1, V) Then
    Begin
      If DBytes[D] <> 0 Then
      Begin
        CmdSet := MCIERR_OUTOFRANGE;
        Exit;
      End;
      If (T = 'CHANNELS') And ((V = 1) Or (V = 2)) Then DCh[D] := V
      Else If (T = 'SAMPLESPERSEC') And (V >= 4000) And (V <= 48000) Then DRate[D] := V
      Else If (T = 'BITSPERSAMPLE') And ((V = 8) Or (V = 16)) Then DBits[D] := V
      Else
      Begin
        CmdSet := MCIERR_OUTOFRANGE;
        Exit;
      End;
      K := K + 2;
    End
    Else If (T = 'WAIT') Or (T = 'NOTIFY') Then Inc(K)
    Else
    Begin
      CmdSet := MCIERR_UNRECOGNIZED_KEYWORD;
      Exit;
    End;
  End;
End;

Function MciSendString(PCmd, PRet, RetLen, Hwnd, User : LongInt) : LongInt;
Var Cmd, T : String; D, R, K, V : LongInt;
Begin
  RetS := '';
  R := 0;
  Tokenize(GetZ(PCmd));
  If NTok = 0 Then R := MCIERR_MISSING_COMMAND_STRING
  Else
  Begin
    Cmd := TokU(0);
    If Cmd = 'OPEN' Then R := CmdOpen(PRet)
    Else If Cmd = 'SYSINFO' Then
    Begin
      T := TokU(2);
      If T = 'QUANTITY' Then RetS := '1'
      Else If (T = 'NAME') Or (T = 'INSTALLNAME') Then RetS := 'waveaudio01'
      Else R := MCIERR_UNRECOGNIZED_KEYWORD;
    End
    Else If (Cmd = 'CLOSE') And (TokU(1) = 'ALL') Then
    Begin
      For K := 0 To MAXDEV - 1 Do
        If DUse[K] <> 0 Then CloseDev(K);
    End
    Else If Pos(' ' + Cmd + ' ', ' CLOSE PLAY RECORD STOP PAUSE RESUME SEEK STATUS SET SAVE INFO CAPABILITY ') = 0 Then
      R := MCIERR_UNRECOGNIZED_COMMAND
    Else
    Begin
      If NTok < 2 Then D := -1 Else D := FindDev(Tok[1]);
      If D < 0 Then R := MCIERR_INVALID_DEVICE_ID
      Else If Cmd = 'CLOSE' Then CloseDev(D)
      Else If Cmd = 'PLAY' Then
      Begin
        EndRecord(D);
        R := CmdPlayRec(D, False, Hwnd, User);
      End
      Else If Cmd = 'RECORD' Then R := CmdPlayRec(D, True, Hwnd, User)
      Else If Cmd = 'STOP' Then
      Begin
        If Streaming(D) And (State = 1) Then
        Begin
          DPos[D] := PlayPos;
          StopStream;
        End
        Else EndRecord(D);
      End
      Else If Cmd = 'PAUSE' Then
      Begin
        If Streaming(D) Then Dummy := MdmPause(1);
      End
      Else If Cmd = 'RESUME' Then
      Begin
        If Streaming(D) Then R := MdmPause(0);
      End
      Else If Cmd = 'SEEK' Then
      Begin
        If Streaming(D) Then
        Begin
          EndRecord(D);
          StopStream;
        End;
        T := TokU(3);
        If TokU(2) <> 'TO' Then R := MCIERR_MISSING_PARAMETER
        Else If T = 'START' Then DPos[D] := 0
        Else If T = 'END' Then DPos[D] := DBytes[D] Div DevFB0(D)
        Else If NumArg(3, V) Then
        Begin
          V := FromUnits(D, V);
          If (V < 0) Or (V > DBytes[D] Div DevFB0(D)) Then R := MCIERR_OUTOFRANGE Else DPos[D] := V;
        End
        Else R := MCIERR_MISSING_PARAMETER;
      End
      Else If Cmd = 'STATUS' Then R := CmdStatus(D)
      Else If Cmd = 'SET' Then R := CmdSet(D)
      Else If Cmd = 'SAVE' Then
      Begin
        EndRecord(D);
        If NTok >= 3 Then
        Begin
          T := Tok[2];
          If UpStr(T) = 'WAIT' Then T := DFile[D];
        End
        Else T := DFile[D];
        If T = '' Then R := MCIERR_MISSING_PARAMETER
        Else
        Begin
          R := SaveWav(D, T);
          If R = 0 Then DFile[D] := T;
        End;
      End
      Else If Cmd = 'INFO' Then
      Begin
        T := TokU(2);
        If T = 'PRODUCT' Then
        Begin
          If DriverReady Then RetS := CardName Else RetS := 'Audio numerique (aucune carte)';
        End
        Else If T = 'FILE' Then RetS := DFile[D]
        Else R := MCIERR_UNRECOGNIZED_KEYWORD;
      End
      Else If Cmd = 'CAPABILITY' Then
      Begin
        T := TokU(2) + ' ' + TokU(3);
        If T = 'DEVICE TYPE' Then RetS := 'waveaudio'
        Else If (T = 'CAN PLAY') Or (T = 'HAS AUDIO') Or (T = 'CAN SAVE') Or (T = 'USES FILES') Or
                (T = 'CAN RECORD') Then
        Begin
          If (T = 'CAN RECORD') And ((Not DriverReady) Or ((DrvCaps And 2) = 0)) Then RetS := 'FALSE'
          Else If (T = 'CAN PLAY') And Not DriverReady Then RetS := 'FALSE'
          Else RetS := 'TRUE';
        End
        Else R := MCIERR_UNRECOGNIZED_KEYWORD;
      End
      Else R := MCIERR_UNRECOGNIZED_COMMAND;
    End;
  End;
  If (PRet <> 0) And (RetLen > 0) Then
  Begin
    If Length(RetS) > RetLen - 1 Then RetS := Copy(RetS, 1, RetLen - 1);
    PutZ(PRet, RetS);
  End;
  MciSendString := R;
End;

Function MciGetErrorString(Err, PBuf, Len : LongInt) : LongInt;
Var S : String;
Begin
  Case Err Of
    0 : S := 'Commande reussie.';
    MCIERR_INVALID_DEVICE_ID : S := 'Appareil inconnu (numero ou alias).';
    MCIERR_MISSING_COMMAND_STRING : S := 'Commande vide.';
    MCIERR_UNRECOGNIZED_KEYWORD : S := 'Mot cle inconnu dans la commande.';
    MCIERR_UNRECOGNIZED_COMMAND : S := 'Commande inconnue.';
    MCIERR_HARDWARE : S := 'Erreur de la carte son.';
    MCIERR_INVALID_DEVICE_NAME : S := 'Type d''appareil inconnu (seul waveaudio est pris en charge).';
    MCIERR_OUT_OF_MEMORY : S := 'Memoire insuffisante.';
    MCIERR_FILE_NOT_FOUND : S := 'Fichier introuvable.';
    MCIERR_OUTOFRANGE : S := 'Valeur hors limites.';
    MCIERR_MISSING_PARAMETER : S := 'Parametre manquant.';
    MCIERR_INVALID_FILE : S := 'Ce n''est pas un fichier WAV (PCM 8 ou 16 bits) valable.';
    MCIERR_FILE_NOT_SAVED : S := 'Le fichier n''a pas pu etre enregistre.';
    MCIERR_DUPLICATE_ALIAS : S := 'Cet alias est deja utilise.';
    MCIERR_DEVICE_LOCKED : S := 'Trop d''appareils ouverts.';
    MCIERR_NO_CARD : S := 'Aucune carte son n''a ete trouvee (Sound Blaster, AC''97, AudioPCI).';
  Else
    S := 'Erreur MCI ' + IStr(Err) + '.';
  End;
  If (PBuf <> 0) And (Len > 0) Then
  Begin
    If Length(S) > Len - 1 Then S := Copy(S, 1, Len - 1);
    PutZ(PBuf, S);
  End;
  If (Err = 0) Or ((Err > MCIERR_BASE) And (Err < MCIERR_BASE + 100)) Then MciGetErrorString := 0
  Else MciGetErrorString := MCIERR_OUTOFRANGE;
End;

Exports
  MciSendString Index 2 Name 'mciSendString',
  MciGetErrorString Index 3 Name 'mciGetErrorString',
  MdmAudioInfo Index 100 Name 'MDMAUDIOINFO',
  MdmPlay Index 101 Name 'MDMPLAY',
  MdmRecord Index 102 Name 'MDMRECORD',
  MdmStop Index 103 Name 'MDMSTOP',
  MdmPause Index 104 Name 'MDMPAUSE',
  MdmPosition Index 105 Name 'MDMPOSITION',
  MdmState Index 106 Name 'MDMSTATE',
  MdmVolume Index 107 Name 'MDMVOLUME',
  MdmCardFormat Index 108 Name 'MDMCARDFORMAT';

Var
  InitK : LongInt;

BEGIN
  DrvTried := 0; DrvFn := 0; DrvH := 0; DrvCaps := 0; DrvName := ''; CardName := '';
  State := 0; Paused := 0; StopReq := 0; ThreadOn := 0; Done := 0;
  Volume := 80; NotHwnd := 0; PostFn := 0;
  For InitK := 0 To MAXDEV - 1 Do
  Begin
    DUse[InitK] := 0; DData[InitK] := 0;
  End;
END.
