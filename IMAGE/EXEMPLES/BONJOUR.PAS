{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BONJOUR - exemple de Pascal Developer : une fenetre du
                Presentation Manager qui affiche un message.
}

Program Bonjour;

{ Ouvrir dans Pascal Developer (dossier Developer Kit du bureau), F9 pour
  compiler (destination OS/2 Presentation Manager), Ctrl+F9 pour executer. }

Const
  WM_PAINT = $0023; WM_CLOSE = $0029; WM_QUIT = $002A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10;
  FCF_MAXBUTTON = $20; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  CLR_WHITE = -2; CLR_DARKBLUE = 9;
  DT_CENTER = $100; DT_VCENTER = $400;

Var
  Hab, Hmq, Frame, Client, Fl, Dummy : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  Txt, Txt2 : Array[0..63] Of Char;

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';

{ chaine Pascal -> chaine terminee par un zero (pour PM) }
Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Txt[K - 1] := S[K];
  Txt[Length(S)] := #0;
  Z := LongInt(@Txt);
End;

Function Z2(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Txt2[K - 1] := S[K];
  Txt2[Length(S)] := #0;
  Z2 := LongInt(@Txt2);
End;

Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  ClientProc := 0;
  Case Msg Of
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_WHITE);
        Dummy := WinDrawText(Hps, -1, Z('Bonjour de Pascal Developer !'), LongInt(@Rc), CLR_DARKBLUE, CLR_WHITE,
                             DT_CENTER Or DT_VCENTER);
        Dummy := WinEndPaint(Hps);
      End;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

BEGIN
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('BONJOUR'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('BONJOUR'), Z2('Bonjour'), 0, 0, 0, LongInt(@Client));
  Dummy := WinSetWindowPos(Frame, HWND_TOP, 120, 140, 400, 200, SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ACTIVATE);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
