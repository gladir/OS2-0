{ GLTEST.PAS - Essai d'OpenGL d'OS/2-0 (OPENGL.DLL, Presentation Manager).

  Compilation : OS2PC GLTEST.PAS GLTEST.EXE

  Le programme d'essai d'OpenGL de Pasdows 95 (EXAMPLES/GLTEST.PAS, sur
  WGL et l'API Win32) reecrit pour Presentation Manager et l'interface
  PGL d'OS/2 : fenetre standard de PM, pglChooseConfig (RGBA, double
  tampon, Z), pglCreateContext, pglMakeCurrent, pglSwapBuffers. Une
  image toutes les 40 ms (minuterie de PM) :
    - cube texture (damier 64 x 64 : glTexImage2D) et eclaire
      (glBegin/glEnd, normales, glColorMaterial) ;
    - pyramide en tableaux de sommets et de couleurs (glVertexPointer,
      glColorPointer, glDrawElements) ;
    - sol dans le brouillard (GL_FOG lineaire) ;
    - carre translucide devant (glBlendFunc, glDepthMask) ;
    - tampon Z et double tampon.
  Echap ou fermeture de la fenetre pour quitter. Le journal (port serie)
  recoit le nom du rendu, puis le nombre d'images et l'erreur GL.

  Les fonctions d'OpenGL qui prennent des flottants sont declarees avec
  des LongInt : FB donne les bits d'un flottant 32 bits, DLo et DHi les
  deux moities d'un flottant 64 bits (glFrustum). }

Program GLTest;

Const
  WM_SIZE = $0007; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20;
  FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  KC_VIRTUALKEY = 2; KC_KEYUP = $40; VK_ESC = $0F;
  { PGL }
  PGL_RGBA = 4; PGL_DOUBLEBUFFER = 5; PGL_DEPTH_SIZE = 12; PGL_RED_SIZE = 8;
  { OpenGL }
  GL_TEXTURE_2D = $0DE1;
  GL_DEPTH_TEST = $0B71;
  GL_CULL_FACE = $0B44;
  GL_LIGHTING = $0B50;
  GL_LIGHT0 = $4000;
  GL_COLOR_MATERIAL = $0B57;
  GL_FOG = $0B60;
  GL_BLEND = $0BE2;
  GL_QUADS = 7;
  GL_TRIANGLES = 4;
  GL_TRIANGLE_STRIP = 5;

  { faces du cube : normale, puis 4 coins }
  CubeN : Array[0..17] Of Single = (0, 0, 1, 0, 0, -1, 1, 0, 0, -1, 0, 0,
    0, 1, 0, 0, -1, 0);
  CubeV : Array[0..71] Of Single = (
    -1, -1, 1, 1, -1, 1, 1, 1, 1, -1, 1, 1,
    1, -1, -1, -1, -1, -1, -1, 1, -1, 1, 1, -1,
    1, -1, 1, 1, -1, -1, 1, 1, -1, 1, 1, 1,
    -1, -1, -1, -1, -1, 1, -1, 1, 1, -1, 1, -1,
    -1, 1, 1, 1, 1, 1, 1, 1, -1, -1, 1, -1,
    -1, -1, -1, 1, -1, -1, 1, -1, 1, -1, -1, 1);
  TC : Array[0..7] Of Single = (0, 0, 1, 0, 1, 1, 0, 1);
  { pyramide : sommets, couleurs (RGBA) et indices }
  PyrV : Array[0..14] Of Single = (0, 1.2, 0, -1, -0.6, 1, 1, -0.6, 1,
    1, -0.6, -1, -1, -0.6, -1);
  PyrC : Array[0..19] Of Byte = (255, 255, 255, 255, 255, 40, 40, 255,
    40, 255, 40, 255, 40, 40, 255, 255, 255, 230, 40, 255);
  PyrI : Array[0..11] Of Word = (0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1);
  LPos : Array[0..3] Of Single = (2, 3, 4, 0);
  LAmb : Array[0..3] Of Single = (0.25, 0.25, 0.3, 1);
  LDif : Array[0..3] Of Single = (1, 1, 0.95, 1);
  FogC : Array[0..3] Of Single = (0.05, 0.07, 0.15, 1);

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';

Function pglChooseConfig(Hab, PList : LongInt) : LongInt; External 'OPENGL' Name 'pglChooseConfig';
Function pglCreateContext(Hab, PVc, Share, Direct : LongInt) : LongInt; External 'OPENGL' Name 'pglCreateContext';
Function pglMakeCurrent(Hab, Hgc, Hwnd : LongInt) : LongInt; External 'OPENGL' Name 'pglMakeCurrent';
Function pglDestroyContext(Hab, Hgc : LongInt) : LongInt; External 'OPENGL' Name 'pglDestroyContext';
Function pglSwapBuffers(Hab, Hwnd : LongInt) : LongInt; External 'OPENGL' Name 'pglSwapBuffers';

Function glGetString(N : LongInt) : LongInt; External 'OPENGL' Name 'glGetString';
Function glGetError : LongInt; External 'OPENGL' Name 'glGetError';
Procedure glGenTextures(N, P : LongInt); External 'OPENGL' Name 'glGenTextures';
Procedure glBindTexture(Tg, T : LongInt); External 'OPENGL' Name 'glBindTexture';
Procedure glTexParameteri(Tg, N, V : LongInt); External 'OPENGL' Name 'glTexParameteri';
Procedure glTexImage2D(Tg, Lv, IFmt, W, H, B, F, T, P : LongInt); External 'OPENGL' Name 'glTexImage2D';
Procedure glTexEnvi(Tg, N, V : LongInt); External 'OPENGL' Name 'glTexEnvi';
Procedure glViewport(X, Y, W, H : LongInt); External 'OPENGL' Name 'glViewport';
Procedure glMatrixMode(M : LongInt); External 'OPENGL' Name 'glMatrixMode';
Procedure glLoadIdentity; External 'OPENGL' Name 'glLoadIdentity';
Procedure glFrustum(LL, LH, RL, RH, BL, BH, TL, TH, NL, NH, FL, FH : LongInt); External 'OPENGL' Name 'glFrustum';
Procedure glEnable(C : LongInt); External 'OPENGL' Name 'glEnable';
Procedure glDisable(C : LongInt); External 'OPENGL' Name 'glDisable';
Procedure glClearColor(R, G, B, A : LongInt); External 'OPENGL' Name 'glClearColor';
Procedure glClear(M : LongInt); External 'OPENGL' Name 'glClear';
Procedure glLightfv(L, N, P : LongInt); External 'OPENGL' Name 'glLightfv';
Procedure glColorMaterial(F, M : LongInt); External 'OPENGL' Name 'glColorMaterial';
Procedure glFogi(N, V : LongInt); External 'OPENGL' Name 'glFogi';
Procedure glFogf(N, V : LongInt); External 'OPENGL' Name 'glFogf';
Procedure glFogfv(N, P : LongInt); External 'OPENGL' Name 'glFogfv';
Procedure glPushMatrix; External 'OPENGL' Name 'glPushMatrix';
Procedure glPopMatrix; External 'OPENGL' Name 'glPopMatrix';
Procedure glTranslatef(X, Y, Z : LongInt); External 'OPENGL' Name 'glTranslatef';
Procedure glRotatef(A, X, Y, Z : LongInt); External 'OPENGL' Name 'glRotatef';
Procedure glBegin(M : LongInt); External 'OPENGL' Name 'glBegin';
Procedure glEnd; External 'OPENGL' Name 'glEnd';
Procedure glColor3f(R, G, B : LongInt); External 'OPENGL' Name 'glColor3f';
Procedure glColor4f(R, G, B, A : LongInt); External 'OPENGL' Name 'glColor4f';
Procedure glNormal3fv(P : LongInt); External 'OPENGL' Name 'glNormal3fv';
Procedure glTexCoord2fv(P : LongInt); External 'OPENGL' Name 'glTexCoord2fv';
Procedure glVertex3fv(P : LongInt); External 'OPENGL' Name 'glVertex3fv';
Procedure glVertex3f(X, Y, Z : LongInt); External 'OPENGL' Name 'glVertex3f';
Procedure glEnableClientState(A : LongInt); External 'OPENGL' Name 'glEnableClientState';
Procedure glDisableClientState(A : LongInt); External 'OPENGL' Name 'glDisableClientState';
Procedure glVertexPointer(Sz, Ty, St, P : LongInt); External 'OPENGL' Name 'glVertexPointer';
Procedure glColorPointer(Sz, Ty, St, P : LongInt); External 'OPENGL' Name 'glColorPointer';
Procedure glDrawElements(M, N, Ty, P : LongInt); External 'OPENGL' Name 'glDrawElements';
Procedure glBlendFunc(S, D : LongInt); External 'OPENGL' Name 'glBlendFunc';
Procedure glDepthMask(F : LongInt); External 'OPENGL' Name 'glDepthMask';

Type
  PByte = ^Byte;

Var
  Hab, Hmq, Frame, Client, Hgc, Vc, Dummy, Frame0 : LongInt;
  Tex : Array[0..64 * 64 * 4 - 1] Of Byte;
  NameZ, NameZ2 : Array[0..255] Of Byte;
  FpuCw : Word;

Function FB(X : Single) : LongInt;
Var L : LongInt;
Begin
  Move(X, L, 4);
  FB := L;
End;

Function DLo(X : Double) : LongInt;
Var A : Array[0..1] Of LongInt;
Begin
  Move(X, A, 8);
  DLo := A[0];
End;

Function DHi(X : Double) : LongInt;
Var A : Array[0..1] Of LongInt;
Begin
  Move(X, A, 8);
  DHi := A[1];
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do NameZ[K - 1] := Ord(S[K]);
  NameZ[Length(S)] := 0;
  Z := LongInt(@NameZ);
End;

Function Z2(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do NameZ2[K - 1] := Ord(S[K]);
  NameZ2[Length(S)] := 0;
  Z2 := LongInt(@NameZ2);
End;

Function GetZ(A : LongInt) : String;
Var S : String; Q : PByte;
Begin
  S := '';
  If A <> 0 Then
  Begin
    Q := Pointer(A);
    While (Q^ <> 0) And (Length(S) < 200) Do
    Begin
      S := S + Chr(Q^);
      Inc(A);
      Q := Pointer(A);
    End;
  End;
  GetZ := S;
End;

{ journal : port serie COM1 }
Procedure Log(S : String);
Var I, C : LongInt;
Begin
  S := S + Chr(13) + Chr(10);
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    asm
      mov dx,3FDh
      mov ecx,100000
    @w:
      in al,dx
      test al,20h
      jnz @ok
      dec ecx
      jnz @w
    @ok:
      mov dx,3F8h
      mov eax,C
      out dx,al
    end;
  End;
End;

{ damier 64 x 64 (RGBA) : bleu et blanc, bord orange }
Procedure MakeTex;
Var X, Y, P : LongInt;
Begin
  For Y := 0 To 63 Do
    For X := 0 To 63 Do
    Begin
      P := (Y * 64 + X) * 4;
      If (X < 3) Or (Y < 3) Or (X > 60) Or (Y > 60) Then
      Begin
        Tex[P] := 255; Tex[P + 1] := 140; Tex[P + 2] := 0;
      End
      Else If (((X Shr 3) Xor (Y Shr 3)) And 1) <> 0 Then
      Begin
        Tex[P] := 30; Tex[P + 1] := 80; Tex[P + 2] := 200;
      End
      Else
      Begin
        Tex[P] := 235; Tex[P + 1] := 235; Tex[P + 2] := 235;
      End;
      Tex[P + 3] := 255;
    End;
End;

Procedure Frustum(W, H : LongInt);
Var A : Double; I : LongInt;
    V : Array[0..5] Of Double; Q : Array[0..11] Of LongInt;
Begin
  If H < 1 Then H := 1;
  A := W / H;
  V[0] := -0.6 * A; V[1] := 0.6 * A; V[2] := -0.6; V[3] := 0.6;
  V[4] := 1; V[5] := 40;
  { chaque double en deux mots, calcules avant l'appel }
  For I := 0 To 5 Do
  Begin
    Q[I * 2] := DLo(V[I]); Q[I * 2 + 1] := DHi(V[I]);
  End;
  glMatrixMode($1701);
  glLoadIdentity;
  glFrustum(Q[0], Q[1], Q[2], Q[3], Q[4], Q[5], Q[6], Q[7], Q[8], Q[9], Q[10], Q[11]);
  glMatrixMode($1700);
End;

Procedure Resize;
Var R : Array[0..3] Of LongInt;
Begin
  If Hgc = 0 Then Exit;
  Dummy := WinQueryWindowRect(Client, LongInt(@R));
  glViewport(0, 0, R[2] - R[0], R[3] - R[1]);
  Frustum(R[2] - R[0], R[3] - R[1]);
End;

Procedure GLInit;
Var Attr : Array[0..7] Of LongInt; TexN : LongInt;
Begin
  Attr[0] := PGL_RGBA; Attr[1] := PGL_DOUBLEBUFFER; Attr[2] := PGL_DEPTH_SIZE; Attr[3] := 16;
  Attr[4] := PGL_RED_SIZE; Attr[5] := 4; Attr[6] := 0;
  Vc := pglChooseConfig(Hab, LongInt(@Attr));
  If Vc = 0 Then Exit;
  Hgc := pglCreateContext(Hab, Vc, 0, 1);
  If Hgc = 0 Then Exit;
  If pglMakeCurrent(Hab, Hgc, Client) = 0 Then
  Begin
    Hgc := 0;
    Exit;
  End;
  Log('GLTEST : ' + GetZ(glGetString($1F01)) + ', OpenGL ' + GetZ(glGetString($1F02)));

  MakeTex;
  TexN := 0;
  glGenTextures(1, LongInt(@TexN));
  glBindTexture(GL_TEXTURE_2D, TexN);
  glTexParameteri(GL_TEXTURE_2D, $2801, $2601);
  glTexParameteri(GL_TEXTURE_2D, $2800, $2601);
  glTexImage2D(GL_TEXTURE_2D, 0, $1908, 64, 64, 0, $1908, $1401, LongInt(@Tex));
  glTexEnvi($2300, $2200, $2100);

  Resize;
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_CULL_FACE);
  glClearColor(FB(FogC[0]), FB(FogC[1]), FB(FogC[2]), FB(1));
  glLightfv(GL_LIGHT0, $1200, LongInt(@LAmb));
  glLightfv(GL_LIGHT0, $1201, LongInt(@LDif));
  glEnable(GL_LIGHT0);
  glEnable(GL_COLOR_MATERIAL);
  glColorMaterial($408, $1602);
  glFogi($0B65, $2601);
  glFogf($0B63, FB(4));
  glFogf($0B64, FB(14));
  glFogfv($0B66, LongInt(@FogC));
  glEnable(GL_FOG);
End;

Procedure Render;
Var F, K : LongInt;
Begin
  If Hgc = 0 Then Exit;
  glClear($4000 Or $100);
  glLoadIdentity;
  glLightfv(GL_LIGHT0, $1203, LongInt(@LPos));

  { cube : texture, eclairage }
  glPushMatrix;
  glTranslatef(FB(-1.3), FB(0.2), FB(-6.5));
  glRotatef(FB(Frame0 * 3.0), FB(0.3), FB(1), FB(0.2));
  glEnable(GL_LIGHTING);
  glEnable(GL_TEXTURE_2D);
  glColor3f(FB(1), FB(1), FB(1));
  glBegin(GL_QUADS);
  For F := 0 To 5 Do
  Begin
    glNormal3fv(LongInt(@CubeN[F * 3]));
    For K := 0 To 3 Do
    Begin
      glTexCoord2fv(LongInt(@TC[K * 2]));
      glVertex3fv(LongInt(@CubeV[(F * 4 + K) * 3]));
    End;
  End;
  glEnd;
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_LIGHTING);
  glPopMatrix;

  { pyramide : tableaux de sommets et de couleurs }
  glPushMatrix;
  glTranslatef(FB(1.5), FB(-0.1), FB(-7.5));
  glRotatef(FB(-Frame0 * 2.0), FB(0), FB(1), FB(0));
  glEnableClientState($8074);
  glEnableClientState($8076);
  glVertexPointer(3, $1406, 0, LongInt(@PyrV));
  glColorPointer(4, $1401, 0, LongInt(@PyrC));
  glDrawElements(GL_TRIANGLES, 12, $1403, LongInt(@PyrI));
  glDisableClientState($8076);
  glDisableClientState($8074);
  glPopMatrix;

  { sol lointain (brouillard) et carre translucide devant }
  glDisable(GL_CULL_FACE);
  glBegin(GL_TRIANGLE_STRIP);
  glColor3f(FB(0.3), FB(0.6), FB(0.3));
  glVertex3f(FB(-8), FB(-1.8), FB(-3));
  glVertex3f(FB(8), FB(-1.8), FB(-3));
  glVertex3f(FB(-8), FB(-1.8), FB(-20));
  glVertex3f(FB(8), FB(-1.8), FB(-20));
  glEnd;
  glEnable(GL_BLEND);
  glBlendFunc($0302, $0303);
  glDepthMask(0);
  glBegin(GL_QUADS);
  glColor4f(FB(1), FB(0.9), FB(0.2), FB(0.35));
  glVertex3f(FB(-0.9), FB(-1.2), FB(-4.2));
  glVertex3f(FB(0.9), FB(-1.2), FB(-4.2));
  glColor4f(FB(1), FB(0.3), FB(0.1), FB(0.6));
  glVertex3f(FB(0.9), FB(0.1), FB(-4.2));
  glVertex3f(FB(-0.9), FB(0.1), FB(-4.2));
  glEnd;
  glDepthMask(1);
  glDisable(GL_BLEND);
  glEnable(GL_CULL_FACE);

  Dummy := pglSwapBuffers(Hab, Client);
  Inc(Frame0);
  If Frame0 = 30 Then Log('GLTEST : 30 images, erreur GL ' + IStr(glGetError));
End;

Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps : LongInt;
Begin
  ClientProc := 0;
  Case Msg Of
    WM_SIZE : Resize;
    WM_PAINT :
    Begin
      Hps := WinBeginPaint(H, 0, 0);
      Dummy := WinEndPaint(Hps);
      If Hgc <> 0 Then Dummy := pglSwapBuffers(Hab, H);
    End;
    WM_TIMER : Render;
    WM_CHAR :
      If ((Mp1 And KC_KEYUP) = 0) And ((Mp1 And KC_VIRTUALKEY) <> 0) And (((Mp2 Shr 16) And $FFFF) = VK_ESC) Then
        Dummy := WinPostMsg(H, WM_CLOSE, 0, 0)
      Else ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Var
  Fl, Sw, Sh, Fw, Fh, X, Y : LongInt;
  Rc : Array[0..3] Of LongInt;
  Qmsg : Array[0..7] Of LongInt;

BEGIN
  FpuCw := $037F;
  asm
    fldcw FpuCw
  end;
  Hgc := 0; Frame0 := 0;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('GLTEST'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('GLTEST'), Z2('Essai OpenGL'), 0, 0, 0,
                              LongInt(@Client));
  Rc[0] := 0; Rc[1] := 0; Rc[2] := 384; Rc[3] := 288;
  Dummy := WinCalcFrameRect(Frame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - Fw) Div 2; Y := (Sh - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := 0;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  GLInit;
  If Hgc = 0 Then
  Begin
    Log('GLTEST : OPENGL.DLL ne cree pas de contexte');
    Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z('OpenGL (OPENGL.DLL) ne peut pas creer de contexte.'),
                           Z2('Essai OpenGL'), 0, $40);
  End
  Else Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinStopTimer(Hab, Client, 1);
  If Hgc <> 0 Then
  Begin
    Dummy := pglMakeCurrent(Hab, 0, 0);
    Dummy := pglDestroyContext(Hab, Hgc);
  End;
  Dummy := WinDestroyWindow(Frame);
END.
