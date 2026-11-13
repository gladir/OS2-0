{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de PMWIN.DLL sous OS/2-0.
}

Program TESTWIN;

{$R-,S-,I-}

{ Compilation : OS2PC TESTWIN.PAS   (produit TESTWIN.EXE)

  TESTWIN verifie PMWIN.DLL : ses 649 ordinaux (et WINSYSCLASSPROC),
  ancre et file de messages, classes, fenetre standard, mots reserves,
  envoi et postage, minuteries, dessin (WM_PAINT, WinDrawText), crochet
  HK_INPUT, rectangles, atomes, tas, presse-papiers, valeurs et couleurs
  du systeme, pages de codes, erreurs, controles (liste, champ de
  saisie, barre de defilement), parametres de presentation, puis les
  entrees du clavier et de la souris. Avec QEMU, apres le lancement :
    ctrl-s                   accelerateur (WM_COMMAND 101)
    alt-f puis o             menu Fichier, Ouvrir (WM_COMMAND 201)
    mouse_button 1 puis 0    clic sur le bouton (WM_COMMAND 300)
    a b c tab spc ret        dialogue : texte, case a cocher, OK
    n                        boite de message : Non }

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function WinQueryScreenText(Row, Col, N, P : LongInt) : LongInt; External 'PMWIN' Name 'WINQUERYSCREENTEXT';

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinTerminate(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyMsgQueue(Hmq : LongInt) : LongInt; External 'PMWIN';
Function WinQueryVersion(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClassInfo(Hab, PName, PInfo : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClassName(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindow(H, Cmd : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindow(Hab, H : LongInt) : LongInt; External 'PMWIN';
Function WinIsChild(H, HPar : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindowVisible(H : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindowEnabled(H : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowTextLength(H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowPos(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowULong(H, I : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowULong(H, I, V : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowUShort(H, I : LongInt) : LongInt; External 'PMWIN';
Function WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromPoint(HPar, P, Ch : LongInt) : LongInt; External 'PMWIN';
Function WinBeginEnumWindows(H : LongInt) : LongInt; External 'PMWIN';
Function WinGetNextWindow(He : LongInt) : LongInt; External 'PMWIN';
Function WinEndEnumWindows(He : LongInt) : LongInt; External 'PMWIN';
Function WinQueryDesktopWindow(Hab, Hdc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryActiveWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(H : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, M, P1, P2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, M, P1, P2 : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, F, L : LongInt) : LongInt; External 'PMWIN';
Function WinPeekMsg(Hab, P, HF, F, L, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinBroadcastMsg(H, M, P1, P2, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinQueryQueueStatus(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, M, P1, P2 : LongInt) : LongInt; External 'PMWIN';
Function WinDefDlgProc(H, M, P1, P2 : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinGetCurrentTime(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinUpdateWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinSetHook(Hab, Hmq, T, Pfn, Hmod : LongInt) : LongInt; External 'PMWIN';
Function WinReleaseHook(Hab, Hmq, T, Pfn, Hmod : LongInt) : LongInt; External 'PMWIN';
Function WinSetRect(Hab, P, X1, Y1, X2, Y2 : LongInt) : LongInt; External 'PMWIN';
Function WinIntersectRect(Hab, PD, P1, P2 : LongInt) : LongInt; External 'PMWIN';
Function WinUnionRect(Hab, PD, P1, P2 : LongInt) : LongInt; External 'PMWIN';
Function WinPtInRect(Hab, P, PPt : LongInt) : LongInt; External 'PMWIN';
Function WinOffsetRect(Hab, P, Dx, Dy : LongInt) : LongInt; External 'PMWIN';
Function WinInflateRect(Hab, P, Dx, Dy : LongInt) : LongInt; External 'PMWIN';
Function WinEqualRect(Hab, P1, P2 : LongInt) : LongInt; External 'PMWIN';
Function WinIsRectEmpty(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinSubtractRect(Hab, PD, P1, P2 : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySystemAtomTable : LongInt; External 'PMWIN';
Function WinCreateAtomTable(Cb, N : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyAtomTable(H : LongInt) : LongInt; External 'PMWIN';
Function WinAddAtom(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinFindAtom(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinDeleteAtom(H, A : LongInt) : LongInt; External 'PMWIN';
Function WinQueryAtomUsage(H, A : LongInt) : LongInt; External 'PMWIN';
Function WinQueryAtomLength(H, A : LongInt) : LongInt; External 'PMWIN';
Function WinQueryAtomName(H, A, P, Cch : LongInt) : LongInt; External 'PMWIN';
Function WinCreateHeap(Sel, Cb, Gr, Mn, Mx, Op : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyHeap(H : LongInt) : LongInt; External 'PMWIN';
Function WinAllocMem(H, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinReallocMem(H, P, CbO, CbN : LongInt) : LongInt; External 'PMWIN';
Function WinFreeMem(H, P, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinAvailMem(H, F, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, D, F, I : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClipbrdData(Hab, F : LongInt) : LongInt; External 'PMWIN';
Function WinEnumClipbrdFmts(Hab, F : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, I : LongInt) : LongInt; External 'PMWIN';
Function WinSetSysValue(HD, I, V : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysColor(HD, C, R : LongInt) : LongInt; External 'PMWIN';
Function WinSetSysColors(HD, O, F, C1, N, P : LongInt) : LongInt; External 'PMWIN';
Function WinUpper(Hab, Cp, Cc, P : LongInt) : LongInt; External 'PMWIN';
Function WinUpperChar(Hab, Cp, Cc, C : LongInt) : LongInt; External 'PMWIN';
Function WinCompareStrings(Hab, Cp, Cc, P1, P2, R : LongInt) : LongInt; External 'PMWIN';
Function WinCpTranslateString(Hab, CpS, PS, CpD, Cch, PD : LongInt) : LongInt; External 'PMWIN';
Function WinQueryCp(Hmq : LongInt) : LongInt; External 'PMWIN';
Function WinSetCp(Hmq, Cp : LongInt) : LongInt; External 'PMWIN';
Function WinGetLastError(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinGetErrorInfo(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinFreeErrorInfo(P : LongInt) : LongInt; External 'PMWIN';
Function WinLoadString(Hab, Hmod, Id, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinCreateAccelTable(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetAccelTable(Hab, H, HF : LongInt) : LongInt; External 'PMWIN';
Function WinQueryAccelTable(Hab, HF : LongInt) : LongInt; External 'PMWIN';
Function WinCopyAccelTable(H, P, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinCreateDlg(HPar, HOwn, Proc, P, PCr : LongInt) : LongInt; External 'PMWIN';
Function WinProcessDlg(H : LongInt) : LongInt; External 'PMWIN';
Function WinSendDlgItemMsg(H, Id, M, P1, P2 : LongInt) : LongInt; External 'PMWIN';
Function WinSetDlgItemText(H, Id, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryDlgItemText(H, Id, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetDlgItemShort(H, Id, V, S : LongInt) : LongInt; External 'PMWIN';
Function WinQueryDlgItemShort(H, Id, P, S : LongInt) : LongInt; External 'PMWIN';
Function WinEnumDlgItem(H, Hi, C : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HP, HO, PT, PC, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryPresParam(H, I1, I2, PId, Cb, P, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinRemovePresParam(H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinSetPointerPos(HD, X, Y : LongInt) : LongInt; External 'PMWIN';
Function WinQueryPointerPos(HD, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryMsgTime(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSubstituteStrings(H, PS, Cch, PD : LongInt) : LongInt; External 'PMWIN';
Function WinCatch(P : LongInt) : LongInt; External 'PMWIN';
Function WinThrow(P, V : LongInt) : LongInt; External 'PMWIN';
Function WinQueryMsgPos(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, F : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowUShort(H, I, V : LongInt) : LongInt; External 'PMWIN';
Function WinSetErrorInfo(E, F : LongInt) : LongInt; External 'PMWIN';
Function WinDestoryFarHeap(H : LongInt) : LongInt; External 'PMWIN';
Function WinCreateFarHeap(Hab, Cb : LongInt) : LongInt; External 'PMWIN';

Const
  WM_CREATE = 1; WM_SIZE = 7; WM_COMMAND = $20; WM_PAINT = $23; WM_TIMER = $24; WM_CLOSE = $29;
  WM_QUIT = $2A; WM_CONTROL = $30; WM_INITDLG = $3B; WM_CHAR = $7A; WM_USER = $1000;
  WM_SUBSTITUTESTRING = $3C;
  WS_VISIBLE = $80000000; WS_TABSTOP = $20000; WS_GROUP = $10000;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20; FCF_SIZEBORDER = 8;
  FCF_VERTSCROLL = $40; FCF_SHELLPOSITION = $400; FCF_DLGBORDER = $100;
  FID_TITLEBAR = $8003; FID_SYSMENU = $8002; FID_MINMAX = $8004; FID_MENU = $8005; FID_VERTSCROLL = $8006;
  FID_CLIENT = $8008;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  QW_PARENT = 5; QW_OWNER = 4;
  SWP_SIZE = 1; SWP_MOVE = 2;
  LM_QUERYITEMCOUNT = $0160; LM_INSERTITEM = $0161; LM_DELETEITEM = $0163; LM_SELECTITEM = $0164;
  LM_QUERYSELECTION = $0165; LM_QUERYITEMTEXT = $0168; LM_SEARCHSTRING = $016B;
  EM_SETSEL = $0142; EM_SETTEXTLIMIT = $0143; EM_COPY = $0145; EM_PASTE = $0147; EM_QUERYSEL = $0141;
  BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
  SBM_SETSCROLLBAR = $01A0; SBM_QUERYPOS = $01A2; SBM_QUERYRANGE = $01A3; SBM_SETPOS = $01A1;
  MM_QUERYITEMCOUNT = $0184; MM_QUERYITEMTEXT = $018B; MM_SETITEMATTR = $0192; MM_QUERYITEMATTR = $0191;
  MIS_TEXT = 1; MIS_SUBMENU = $10; MIA_DISABLED = $4000;
  BS_PUSHBUTTON = 0; BS_AUTOCHECKBOX = 2; BS_DEFAULT = $400;
  SS_TEXT = 1; ES_AUTOSCROLL = $4;
  MB_YESNO = 4; MBID_YES = 6; MBID_NO = 7;
  SV_CXSCREEN = 20; SV_CYSCREEN = 21; SV_CYTITLEBAR = 30; SV_CXDBLCLK = 2;
  SYSCLR_WINDOW = -20;
  PMERR_INVALID_HWND = $1001; PMERR_RESOURCE_NOT_FOUND = $100A;
  HK_INPUT = 1;
  AF_CHAR = 1; AF_CONTROL = $10;
  PP_FOREGROUNDCOLOR = 1;
  NOrd = 649;
  Ords : Array[0..648] Of Word = (
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
    33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
    49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 63, 64, 65,
    66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81,
    82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97,
    98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113,
    114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129,
    132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 146, 147, 149,
    150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165,
    166, 167, 168, 169, 170, 171, 172, 173, 174, 177, 178, 179, 197, 198, 199, 200,
    201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216,
    217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 233,
    234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249,
    250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265,
    266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 281, 282,
    283, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299,
    300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314, 315,
    316, 317, 318, 319, 320, 321, 322, 325, 326, 327, 328, 329, 330, 331, 332, 333,
    334, 400, 401, 495, 496, 497, 498, 499, 500, 508, 509, 510, 511, 512, 513, 514,
    515, 590, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611, 612, 613,
    614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 626, 627, 628, 629,
    630, 631, 632, 633, 634, 635, 636, 637, 639, 640, 700, 701, 702, 703, 704, 705,
    707, 708, 709, 710, 711, 712, 713, 714, 715, 716, 717, 718, 719, 720, 721, 722,
    723, 724, 725, 726, 727, 728, 729, 730, 731, 732, 733, 734, 735, 736, 737, 738,
    739, 740, 741, 742, 743, 744, 745, 746, 748, 749, 750, 751, 752, 753, 754, 755,
    756, 757, 758, 759, 760, 761, 762, 763, 764, 765, 766, 767, 768, 769, 770, 771,
    772, 773, 774, 775, 776, 777, 778, 779, 780, 781, 782, 784, 785, 786, 787, 788,
    789, 790, 791, 792, 793, 794, 795, 796, 797, 798, 799, 800, 801, 802, 803, 804,
    805, 806, 807, 808, 809, 810, 811, 812, 813, 814, 815, 816, 817, 818, 819, 820,
    821, 822, 823, 824, 825, 826, 827, 828, 829, 830, 831, 832, 833, 834, 835, 837,
    838, 839, 840, 841, 842, 843, 844, 845, 846, 848, 849, 850, 851, 852, 853, 854,
    855, 856, 857, 858, 859, 860, 861, 862, 863, 864, 865, 866, 867, 868, 869, 870,
    871, 872, 873, 874, 875, 876, 877, 878, 879, 880, 881, 882, 883, 884, 885, 886,
    887, 888, 890, 891, 892, 893, 894, 895, 896, 897, 898, 899, 900, 901, 902, 903,
    904, 905, 906, 907, 908, 909, 910, 911, 912, 913, 914, 915, 916, 917, 918, 919,
    920, 921, 922, 923, 924, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935,
    936, 937, 938, 939, 940, 941, 942, 943, 947, 948, 949, 950, 951, 952, 953, 954,
    955, 956, 957, 958, 959, 960, 961, 962, 963, 964, 965, 966, 967, 968, 969, 970,
    971, 972, 973, 974, 975, 976, 977, 978, 979, 980, 981, 982, 983, 984, 985, 986,
    987, 988, 990, 991, 992, 993, 994, 995, 996);

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, A, B, C, P, X, Hab, Hmq, Frame, Client, Btn, Lb, Ef, Sb, Mnu, Dlg, Hk, Hmod, T0 : LongInt;
  Name, Name2, Buf : Array[0..255] Of Byte;
  Fl : LongInt;
  Gr, Seen : Boolean;                    { ecran graphique de PM ; texte vu a l'ecran }
  MgL, MgB, MgR, MgT : LongInt;          { marges du cadre d'essai }
  Rc1, Rc2, Rc3 : Array[0..3] Of LongInt;
  Pt : Array[0..1] Of LongInt;
  Swp : Array[0..8] Of LongInt;
  Qm : Array[0..7] Of LongInt;
  Acc : Array[0..9] Of Byte;
  Mt : Array[0..255] Of Byte;
  MtLen : LongInt;
  Dt : Array[0..1023] Of Byte;
  NCreate, NSize, NPaint, NTimer, NPosted, NHook, NChar, LastSize, NInit, DlgCheck, NSubst : LongInt;
  CmdLog, DlgTxt : String;
  OutBuf : Array[0..16383] Of Byte;
  OutLen, DtOff : LongInt;

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
  For K := 7 DownTo 0 Do
  Begin
    D := (V Shr (K * 4)) And 15;
    If D < 10 Then S := S + Chr(48 + D) Else S := S + Chr(55 + D);
  End;
  HStr := S;
End;

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  P := Pointer(A);
  P^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  K := 0;
  While (RdB(A + K) <> 0) And (K < 250) Do
  Begin
    S := S + Chr(RdB(A + K));
    Inc(K);
  End;
  GetZ := S;
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name), S);
  Z := LongInt(@Name);
End;

Function Z2(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name2), S);
  Z2 := LongInt(@Name2);
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

{ texte de l'ecran (ligne, colonne, longueur) : caracteres dessines par
  PMWIN (WINQUERYSCREENTEXT, ordinal interne 1002 : cellules de l'ecran
  texte ou caracteres de 8 x 16 pels de l'ecran graphique) }
Function Scr(Row, Col, N : LongInt) : String;
Var S : String; K : LongInt; SB : Array[0..79] Of Byte;
Begin
  S := '';
  K := WinQueryScreenText(Row, Col, N, LongInt(@SB));
  For K := 0 To N - 1 Do S := S + Chr(SB[K]);
  Scr := S;
End;

{ l'ecran contient-il T ? }
Function ScrHas(T : String) : Boolean;
Var Row : LongInt; F : Boolean;
Begin
  F := False;
  For Row := 0 To 29 Do
    If Pos(T, Scr(Row, 0, 80)) > 0 Then F := True;
  ScrHas := F;
End;

Function Lo16(V : LongInt) : LongInt;
Begin
  Lo16 := V And $FFFF;
End;

Function Hi16(V : LongInt) : LongInt;
Begin
  Hi16 := (V Shr 16) And $FFFF;
End;

{ --- procedures (convention Pascal) --- }
Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  ClientProc := 0;
  If Msg = WM_CREATE Then Inc(NCreate)
  Else If Msg = WM_SIZE Then
  Begin
    Inc(NSize);
    LastSize := Mp2;
  End
  Else If Msg = WM_PAINT Then
  Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    R := WinFillRect(Hps, LongInt(@Rc), SYSCLR_WINDOW);
    R := WinQueryWindowRect(H, LongInt(@Rc));
    R := WinDrawText(Hps, -1, Z2('Bonjour PM'), LongInt(@Rc), -1, SYSCLR_WINDOW, 0);
    R := WinEndPaint(Hps);
    Inc(NPaint);
  End
  Else If Msg = WM_TIMER Then Inc(NTimer)
  Else If Msg = WM_COMMAND Then CmdLog := CmdLog + '[' + IStr(Lo16(Mp1)) + ']'
  Else If Msg = WM_USER Then ClientProc := Mp1 + Mp2
  Else If Msg = WM_USER + 1 Then Inc(NPosted)
  Else If Msg = WM_SUBSTITUTESTRING Then
  Begin
    Inc(NSubst);
    If Mp1 = 1 Then ClientProc := Z2('monde') Else ClientProc := Z2('?');
  End
  Else If Msg = WM_CLOSE Then ClientProc := 0
  Else
  Begin
    If Msg = WM_CHAR Then Inc(NChar);
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Function InputHook(Hb, PQ, Fs : LongInt) : LongInt;
Begin
  Inc(NHook);
  InputHook := 0;
End;

Function DlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  If Msg = WM_INITDLG Then
  Begin
    Inc(NInit);
    R := WinSetDlgItemText(H, 102, Z2(''));
    DlgProc := 0;
  End
  Else If (Msg = WM_COMMAND) And (Lo16(Mp1) = 1) Then
  Begin
    R := WinQueryDlgItemText(H, 102, 64, LongInt(@Buf));
    DlgTxt := GetZ(LongInt(@Buf));
    DlgCheck := WinSendDlgItemMsg(H, 103, BM_QUERYCHECK, 0, 0);
    DlgProc := WinDefDlgProc(H, Msg, Mp1, Mp2);
  End
  Else DlgProc := WinDefDlgProc(H, Msg, Mp1, Mp2);
End;

{ traiter les messages jusqu'a ce que Cond devienne vrai (au plus Ms) }
Function Pump(Ms : LongInt) : LongInt;
Var T : LongInt;
Begin
  T := WinGetCurrentTime(Hab);
  N := 0;
  While (WinGetCurrentTime(Hab) - T < Ms) Do
  Begin
    If WinPeekMsg(Hab, LongInt(@Qm), 0, 0, 0, 1) <> 0 Then
    Begin
      R := WinDispatchMsg(Hab, LongInt(@Qm));
      Inc(N);
    End;
  End;
  Pump := N;
End;

Function WaitFor(What : String; Ms : LongInt) : Boolean;
Var T : LongInt;
Begin
  T := WinGetCurrentTime(Hab);
  While (Pos(What, CmdLog) = 0) And (WinGetCurrentTime(Hab) - T < Ms) Do
    If WinPeekMsg(Hab, LongInt(@Qm), 0, 0, 0, 1) <> 0 Then R := WinDispatchMsg(Hab, LongInt(@Qm));
  WaitFor := Pos(What, CmdLog) > 0;
End;

{ --- modeles --- }
Procedure MB(V : LongInt);
Begin
  Mt[MtLen] := V And 255;
  Inc(MtLen);
End;

Procedure MW(V : LongInt);
Begin
  MB(V); MB(V Shr 8);
End;

Procedure MS(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do MB(Ord(S[K]));
  MB(0);
End;

{ element de dialogue numero K (30 octets a 14 + K * 30) }
Procedure DItem(K, NCh, Cls, TxtOff, TxtLen : LongInt; St : LongInt; X, Y, Cx, Cy, Id, CtlOff : LongInt);
Var A : LongInt;
Begin
  A := LongInt(@Dt) + 14 + K * 30;
  WrW(A, 0); WrW(A + 2, NCh); WrW(A + 4, 0); WrW(A + 6, Cls); WrW(A + 8, TxtLen); WrW(A + 10, TxtOff);
  WrL(A + 12, St); WrW(A + 16, X); WrW(A + 18, Y); WrW(A + 20, Cx); WrW(A + 22, Cy); WrW(A + 24, Id);
  WrW(A + 26, $FFFF); WrW(A + 28, CtlOff);
End;

{ chaine du modele de dialogue ; rend son decalage }
Function DStr(S : String) : LongInt;
Begin
  DStr := DtOff;
  PutZ(LongInt(@Dt) + DtOff, S);
  DtOff := DtOff + Length(S) + 1;
End;

Procedure BuildDlg;
Var T1, T2, T3, T4, T5, T6, Fc, Ec : LongInt;
Begin
  For I := 0 To 1023 Do Dt[I] := 0;
  DtOff := 14 + 6 * 30;
  T1 := DStr('Dialogue'); T2 := DStr('~Nom :'); T3 := DStr(''); T4 := DStr('~Option');
  T5 := DStr('OK'); T6 := DStr('Annuler');
  Fc := DtOff;
  WrW(LongInt(@Dt) + Fc, 10); WrL(LongInt(@Dt) + Fc + 2, FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER);
  DtOff := DtOff + 10;
  Ec := DtOff;
  WrW(LongInt(@Dt) + Ec, 8); WrW(LongInt(@Dt) + Ec + 2, 20);
  DtOff := DtOff + 8;
  WrW(LongInt(@Dt), DtOff); WrW(LongInt(@Dt) + 2, 0); WrW(LongInt(@Dt) + 4, 850); WrW(LongInt(@Dt) + 6, 14);
  WrW(LongInt(@Dt) + 8, 1); WrW(LongInt(@Dt) + 10, $FFFF); WrW(LongInt(@Dt) + 12, 0);
  DItem(0, 5, 1, T1, 8, WS_VISIBLE Or $80, 40, 40, 160, 80, 100, Fc);
  DItem(1, 0, 5, T2, 6, WS_VISIBLE Or WS_GROUP Or SS_TEXT, 8, 56, 40, 8, 101, $FFFF);
  DItem(2, 0, 6, T3, 0, WS_VISIBLE Or WS_TABSTOP, 50, 56, 80, 8, 102, Ec);
  DItem(3, 0, 3, T4, 7, WS_VISIBLE Or WS_TABSTOP Or WS_GROUP Or BS_AUTOCHECKBOX, 8, 36, 80, 8, 103, $FFFF);
  DItem(4, 0, 3, T5, 2, WS_VISIBLE Or WS_TABSTOP Or WS_GROUP Or BS_DEFAULT, 16, 8, 40, 8, 1, $FFFF);
  DItem(5, 0, 3, T6, 7, WS_VISIBLE Or WS_TABSTOP, 80, 8, 50, 8, 2, $FFFF);
End;

{ menu : ~Fichier (~Ouvrir 201, ~Quitter 202), ~Aide 203 }
Procedure BuildMenu;
Var S0, S1 : LongInt;
Begin
  MtLen := 0;
  MW(0); MW(0); MW(2);
  MW(MIS_TEXT Or MIS_SUBMENU); MW(0); MW(200); MS('~Fichier');
  S1 := MtLen;
  MW(0); MW(0); MW(2);
  MW(MIS_TEXT); MW(0); MW(201); MS('~Ouvrir');
  MW(MIS_TEXT); MW(0); MW(202); MS('~Quitter');
  Mt[S1] := (MtLen - S1) And 255; Mt[S1 + 1] := (MtLen - S1) Shr 8;
  MW(MIS_TEXT); MW(0); MW(203); MS('~Aide');
  Mt[0] := MtLen And 255; Mt[1] := MtLen Shr 8;
  S0 := 0;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0; CmdLog := '';
  NCreate := 0; NSize := 0; NPaint := 0; NTimer := 0; NPosted := 0; NHook := 0; NChar := 0; NInit := 0;
  NSubst := 0;
  WriteLn('TESTWIN : essai de PMWIN.DLL');

  { --- ordinaux --- }
  Hmod := 0;
  R := DosQueryModuleHandle(Z('PMWIN'), LongInt(@Hmod));
  N := 0;
  For I := 0 To NOrd - 1 Do
  Begin
    P := 0;
    If DosQueryProcAddr(Hmod, Ords[I], 0, LongInt(@P)) = 0 Then
      If P <> 0 Then Inc(N);
  End;
  Check('649 ordinaux de PMWIN (' + IStr(N) + ')', N = 649);
  P := 0; A := 0; B := 0; C := 0; X := 0;
  R := DosQueryProcAddr(Hmod, 1000, 0, LongInt(@P));
  R := DosQueryProcAddr(Hmod, 0, Z('_WinSetErrorInfo'), LongInt(@A));
  R := DosQueryProcAddr(Hmod, 0, Z('WinDestoryFarHeap'), LongInt(@B));
  R := DosQueryProcAddr(Hmod, 0, Z('DEBUG32INPUT'), LongInt(@C));
  R := DosQueryProcAddr(Hmod, 0, Z('WINSETCLASSTHUNKPROC'), LongInt(@X));
  Check('WINSYSCLASSPROC, _WinSetErrorInfo, WinDestoryFarHeap, DEBUG32INPUT, WINSETCLASSTHUNKPROC',
        (P <> 0) And (A <> 0) And (B <> 0) And (C <> 0) And (X <> 0));

  { --- ancre et file --- }
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  R := WinCreateMsgQueue(Hab, 0);
  Check('WinInitialize, WinCreateMsgQueue (deuxieme : erreur)', (Hab <> 0) And (Hmq <> 0) And (R = 0) And
        (Lo16(WinGetLastError(Hab)) = $1052));
  R := WinQueryVersion(Hab);
  Check('WinQueryVersion : 20.40', R = $2814);

  { --- classe et fenetre standard --- }
  R := WinRegisterClass(Hab, Z('EssaiClient'), LongInt(@ClientProc), 0, 8);
  R2 := WinQueryClassInfo(Hab, Z('EssaiClient'), LongInt(@Rc1));
  Check('WinRegisterClass, WinQueryClassInfo', (R = 1) And (R2 = 1) And (Rc1[1] = LongInt(@ClientProc)) And (Rc1[2] = 8));
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_SIZEBORDER Or FCF_VERTSCROLL Or FCF_SHELLPOSITION;
  Frame := WinCreateStdWindow(HWND_DESKTOP, WS_VISIBLE, LongInt(@Fl), Z('EssaiClient'), Z2('Essai PMWIN'), 0, 0, 1,
                              LongInt(@Client));
  Check('WinCreateStdWindow : cadre et client (WM_CREATE, WM_SIZE ' + HStr(LastSize) + ')',
        (Frame <> 0) And (Client <> 0) And (NCreate = 1) And (NSize >= 1));
  Check('controles du cadre (FID_TITLEBAR, FID_SYSMENU, FID_MINMAX, FID_VERTSCROLL, FID_CLIENT)',
        (WinWindowFromID(Frame, FID_TITLEBAR) <> 0) And (WinWindowFromID(Frame, FID_SYSMENU) <> 0) And
        (WinWindowFromID(Frame, FID_MINMAX) <> 0) And (WinWindowFromID(Frame, FID_VERTSCROLL) <> 0) And
        (WinWindowFromID(Frame, FID_CLIENT) = Client));
  R := WinQueryClassName(Frame, 64, LongInt(@Buf));
  Check('WinQueryClassName : #1 (' + GetZ(LongInt(@Buf)) + ')', GetZ(LongInt(@Buf)) = '#1');
  R := WinQueryWindowText(Frame, 64, LongInt(@Buf));
  Check('WinQueryWindowText, WinQueryWindowTextLength', (GetZ(LongInt(@Buf)) = 'Essai PMWIN') And
        (WinQueryWindowTextLength(Frame) = 11));
  Check('WinQueryWindow (QW_PARENT, QW_OWNER), WinIsChild, WinIsWindow, WinIsWindowVisible',
        (WinQueryWindow(Client, QW_PARENT) = Frame) And (WinQueryWindow(Client, QW_OWNER) = Frame) And
        (WinIsChild(Client, Frame) = 1) And (WinIsWindow(Hab, Client) = 1) And (WinIsWindowVisible(Frame) = 1));
  Check('WinQueryActiveWindow, WinQueryFocus', (WinQueryActiveWindow(HWND_DESKTOP) = Frame) And
        (WinQueryFocus(HWND_DESKTOP) = Client));
  R := WinSetWindowPos(Frame, 0, 80, 48, 480, 288, SWP_MOVE Or SWP_SIZE);
  R2 := WinQueryWindowPos(Frame, LongInt(@Swp));
  Check('WinSetWindowPos, WinQueryWindowPos', (R = 1) And (Swp[1] = 288) And (Swp[2] = 480) And (Swp[3] = 48) And
        (Swp[4] = 80));
  { marges du cadre : ecran graphique (bordure 4, titre 20, barre de
    defilement 16) ou ecran texte (cellules de 8 x 16) }
  Gr := WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN) >= 480;
  If Gr Then
  Begin
    MgL := 4; MgB := 4; MgR := 4 + 16; MgT := 4 + 20;
  End
  Else
  Begin
    MgL := 8; MgB := 16; MgR := 8 + 8; MgT := 16;
  End;
  R := WinQueryWindowRect(Client, LongInt(@Rc1));
  Check('WinQueryWindowRect du client (' + IStr(Rc1[2]) + 'x' + IStr(Rc1[3]) + ')', (Rc1[0] = 0) And
        (Rc1[2] = 480 - MgL - MgR) And (Rc1[3] = 288 - MgB - MgT));
  Rc2[0] := 80; Rc2[1] := 48; Rc2[2] := 560; Rc2[3] := 336;
  R := WinCalcFrameRect(Frame, LongInt(@Rc2), 1);
  Check('WinCalcFrameRect', (Rc2[0] = 80 + MgL) And (Rc2[1] = 48 + MgB) And (Rc2[2] = 560 - MgR) And (Rc2[3] = 336 - MgT));
  R := WinSetWindowULong(Client, 4, $12345678);
  Check('WinSetWindowULong, WinQueryWindowULong, WinQueryWindowUShort (QWS_ID)',
        (WinQueryWindowULong(Client, 4) = $12345678) And (WinQueryWindowUShort(Client, -1) = FID_CLIENT));
  Pt[0] := 0; Pt[1] := 0;
  R := WinMapWindowPoints(Client, HWND_DESKTOP, LongInt(@Pt), 1);
  Check('WinMapWindowPoints (' + IStr(Pt[0]) + ', ' + IStr(Pt[1]) + ')', (Pt[0] = 80 + MgL) And (Pt[1] = 48 + MgB));
  Pt[0] := 200; Pt[1] := 200;
  Check('WinWindowFromPoint : client', WinWindowFromPoint(HWND_DESKTOP, LongInt(@Pt), 1) = Client);
  A := WinBeginEnumWindows(Frame);
  N := 0;
  While WinGetNextWindow(A) <> 0 Do Inc(N);
  R := WinEndEnumWindows(A);
  Check('WinBeginEnumWindows, WinGetNextWindow (' + IStr(N) + ' enfants)', N = 5);

  { --- messages --- }
  R := WinSendMsg(Client, WM_USER, 40, 2);
  Check('WinSendMsg : procedure OS2PC (40 + 2)', R = 42);
  A := WinPostMsg(Client, WM_USER + 1, 0, 0);
  R2 := WinQueryQueueStatus(HWND_DESKTOP);
  N := Pump(300);
  R := A;
  Check('WinPostMsg, WinPeekMsg, WinDispatchMsg, WinQueryQueueStatus', (R = 1) And (NPosted = 1) And
        ((R2 And $20) <> 0));
  Seen := ScrHas('Bonjour PM');
  Check('WM_PAINT et WinDrawText (ecran : "Bonjour PM")', (NPaint >= 1) And Seen);
  Seen := ScrHas('Essai PMWIN');
  Check('barre de titre a l''ecran ("Essai PMWIN")', Seen);
  R := WinBroadcastMsg(Frame, WM_USER + 1, 0, 0, 1);
  Check('WinBroadcastMsg (envoi aux enfants)', (R = 1) And (NPosted = 2));
  R := WinSendMsg(12345, WM_USER, 0, 0);
  R2 := WinGetLastError(Hab);
  Check('fenetre invalide : PMERR_INVALID_HWND (' + HStr(R2) + ')', R2 = $41001);
  R := WinStartTimer(Hab, Client, 1, 100);
  T0 := WinGetCurrentTime(Hab);
  While (NTimer < 2) And (WinGetCurrentTime(Hab) - T0 < 3000) Do
    If WinGetMsg(Hab, LongInt(@Qm), 0, 0, 0) <> 0 Then R2 := WinDispatchMsg(Hab, LongInt(@Qm));
  R2 := WinStopTimer(Hab, Client, 1);
  Check('WinStartTimer, WM_TIMER, WinStopTimer (' + IStr(NTimer) + ')', (R = 1) And (NTimer >= 2) And (R2 = 1));
  Check('WinQueryMsgTime, WinQueryMsgPos', (WinQueryMsgTime(Hab) <> 0) And (WinQueryMsgPos(Hab, LongInt(@Pt)) = 1));
  R := WinSubstituteStrings(Client, Z('Bonjour %1 !'), 64, LongInt(@Buf));
  Check('WinSubstituteStrings : ' + GetZ(LongInt(@Buf)), (GetZ(LongInt(@Buf)) = 'Bonjour monde !') And (NSubst = 1));

  { --- rectangles --- }
  R := WinSetRect(Hab, LongInt(@Rc1), 0, 0, 100, 50);
  R := WinSetRect(Hab, LongInt(@Rc2), 50, 20, 200, 80);
  R := WinIntersectRect(Hab, LongInt(@Rc3), LongInt(@Rc1), LongInt(@Rc2));
  Check('WinSetRect, WinIntersectRect', (R = 1) And (Rc3[0] = 50) And (Rc3[1] = 20) And (Rc3[2] = 100) And (Rc3[3] = 50));
  R := WinUnionRect(Hab, LongInt(@Rc3), LongInt(@Rc1), LongInt(@Rc2));
  Check('WinUnionRect', (Rc3[0] = 0) And (Rc3[1] = 0) And (Rc3[2] = 200) And (Rc3[3] = 80));
  Pt[0] := 10; Pt[1] := 10;
  Check('WinPtInRect, WinIsRectEmpty, WinEqualRect', (WinPtInRect(Hab, LongInt(@Rc1), LongInt(@Pt)) = 1) And
        (WinIsRectEmpty(Hab, LongInt(@Rc1)) = 0) And (WinEqualRect(Hab, LongInt(@Rc1), LongInt(@Rc1)) = 1) And
        (WinEqualRect(Hab, LongInt(@Rc1), LongInt(@Rc2)) = 0));
  R := WinOffsetRect(Hab, LongInt(@Rc1), 10, 5);
  R := WinInflateRect(Hab, LongInt(@Rc1), 2, 3);
  Check('WinOffsetRect, WinInflateRect', (Rc1[0] = 8) And (Rc1[1] = 2) And (Rc1[2] = 112) And (Rc1[3] = 58));
  R := WinSetRect(Hab, LongInt(@Rc1), 0, 0, 100, 50);
  R := WinSetRect(Hab, LongInt(@Rc2), 50, 0, 100, 50);
  R := WinSubtractRect(Hab, LongInt(@Rc3), LongInt(@Rc1), LongInt(@Rc2));
  Check('WinSubtractRect', (R = 1) And (Rc3[0] = 0) And (Rc3[2] = 50));

  { --- atomes --- }
  A := WinQuerySystemAtomTable;
  B := WinAddAtom(A, Z('EssaiAtome'));
  C := WinAddAtom(A, Z('ESSAIATOME'));
  Check('WinAddAtom (deux fois), WinFindAtom', (B >= $C000) And (C = B) And (WinFindAtom(A, Z('essaiatome')) = B));
  R := WinQueryAtomName(A, B, LongInt(@Buf), 64);
  Check('WinQueryAtomName, WinQueryAtomLength, WinQueryAtomUsage', (GetZ(LongInt(@Buf)) = 'EssaiAtome') And
        (WinQueryAtomLength(A, B) = 10) And (WinQueryAtomUsage(A, B) = 2));
  R := WinDeleteAtom(A, B);
  R2 := WinDeleteAtom(A, B);
  Check('WinDeleteAtom (compte), atome entier #123', (R = 0) And (R2 = 0) And (WinFindAtom(A, Z('EssaiAtome')) = 0) And
        (WinAddAtom(A, Z('#123')) = 123));
  C := WinCreateAtomTable(0, 0);
  B := WinAddAtom(C, Z('Local'));
  Check('WinCreateAtomTable, WinDestroyAtomTable', (C <> 0) And (B <> 0) And (WinFindAtom(A, Z('Local')) = 0) And
        (WinDestroyAtomTable(C) = 0));

  { --- tas --- }
  A := WinCreateHeap(0, 4096, 0, 0, 0, 0);
  B := WinAllocMem(A, 100);
  R := WinAvailMem(A, 0, 0);
  PutZ(B, 'tas');
  C := WinReallocMem(A, B, 100, 1000);
  Check('WinCreateHeap, WinAllocMem, WinReallocMem, WinAvailMem', (A <> 0) And (B <> 0) And (C <> 0) And
        (GetZ(C) = 'tas') And (R > 3000) And (R < 4096));
  Check('WinFreeMem, WinDestroyHeap', (WinFreeMem(A, C, 1000) = 0) And (WinDestroyHeap(A) = 0));
  A := WinCreateFarHeap(Hab, 2048);
  Check('WinCreateFarHeap, WinDestoryFarHeap', (A <> 0) And (WinDestoryFarHeap(A) = 1));

  { --- presse-papiers --- }
  R := WinOpenClipbrd(Hab);
  R2 := WinEmptyClipbrd(Hab);
  A := WinSetClipbrdData(Hab, Z('Texte copie'), 1, $400);
  B := WinCloseClipbrd(Hab);
  Check('WinOpenClipbrd, WinEmptyClipbrd, WinSetClipbrdData, WinCloseClipbrd', (R = 1) And (R2 = 1) And (A = 1) And (B = 1));
  P := WinQueryClipbrdData(Hab, 1);
  Check('WinQueryClipbrdData, WinEnumClipbrdFmts', (P <> 0) And (P <> LongInt(@Name)) And (GetZ(P) = 'Texte copie') And
        (WinEnumClipbrdFmts(Hab, 0) = 1) And (WinEnumClipbrdFmts(Hab, 1) = 0));

  { --- systeme --- }
  If Gr Then
    Check('WinQuerySysValue : ecran graphique ' + IStr(WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN)) + ' x ' +
          IStr(WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN)) + ', titre 20',
          (WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN) >= 640) And
          (WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN) >= 480) And (WinQuerySysValue(HWND_DESKTOP, SV_CYTITLEBAR) = 20))
  Else
    Check('WinQuerySysValue : ecran 640 x 400, titre 16', (WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN) = 640) And
          (WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN) = 400) And (WinQuerySysValue(HWND_DESKTOP, SV_CYTITLEBAR) = 16));
  R := WinSetSysValue(HWND_DESKTOP, SV_CXDBLCLK, 12);
  Check('WinSetSysValue', (R = 1) And (WinQuerySysValue(HWND_DESKTOP, SV_CXDBLCLK) = 12));
  R := WinSetSysValue(HWND_DESKTOP, SV_CXDBLCLK, 8);
  A := WinQuerySysColor(HWND_DESKTOP, SYSCLR_WINDOW, 0);
  Rc1[0] := SYSCLR_WINDOW; Rc1[1] := $FFFFFF;
  R := WinSetSysColors(HWND_DESKTOP, 0, 1, 0, 2, LongInt(@Rc1));
  Check('WinQuerySysColor, WinSetSysColors (' + HStr(A) + ')', (A = $FFFFFF) And (R = 1));

  { --- pages de codes --- }
  PutZ(LongInt(@Buf), 'ecole ' + Chr($82) + 't' + Chr($82));
  R := WinUpper(Hab, 850, 0, LongInt(@Buf));
  Check('WinUpper (850) : ECOLE ' + Chr($90) + 'T' + Chr($90), (R = 9) And (GetZ(LongInt(@Buf)) = 'ECOLE ' + Chr($90) + 'T' + Chr($90)));
  Check('WinUpperChar, WinCompareStrings', (WinUpperChar(Hab, 850, 0, $87) = $80) And
        (WinCompareStrings(Hab, 0, 0, Z('abc'), Z2('ABC'), 0) = 1) And
        (WinCompareStrings(Hab, 0, 0, Z('abc'), Z2('abd'), 0) = 2));
  PutZ(LongInt(@Name), Chr($9B));
  R := WinCpTranslateString(Hab, 437, LongInt(@Name), 850, 16, LongInt(@Buf));
  Check('WinCpTranslateString 437 -> 850', (R = 1) And (RdB(LongInt(@Buf)) = $BD));
  Check('WinQueryCp, WinSetCp', (WinQueryCp(Hmq) = 850) And (WinSetCp(Hmq, 437) = 1) And (WinQueryCp(Hmq) = 437) And
        (WinSetCp(Hmq, 850) = 1));

  { --- erreurs --- }
  R := WinLoadString(Hab, 0, 999, 64, LongInt(@Buf));
  P := WinGetErrorInfo(Hab);
  Check('WinLoadString absente, WinGetErrorInfo (PMERR_RESOURCE_NOT_FOUND)', (R = 0) And (P <> 0) And
        (Lo16(RdL(P + 4)) = PMERR_RESOURCE_NOT_FOUND) And (WinFreeErrorInfo(P) = 1));
  R := WinGetLastError(Hab);
  R2 := WinSetErrorInfo($41234, 0);
  Check('WinGetLastError, WinSetErrorInfo', (R = $40000 + PMERR_RESOURCE_NOT_FOUND) And (WinGetLastError(Hab) = $41234) And
        (WinGetLastError(Hab) = 0));
  R := WinCatch(LongInt(@Rc1));
  Check('WinCatch : 0, WinThrow : FALSE', (R = 0) And (WinThrow(LongInt(@Rc1), 5) = 0));

  { --- controles --- }
  Lb := WinCreateWindow(Client, $FFFF0007, 0, 0, 8, 8, 120, 64, Client, HWND_TOP, 301, 0, 0);
  R := WinSendMsg(Lb, LM_INSERTITEM, -2, Z('poire'));
  R := WinSendMsg(Lb, LM_INSERTITEM, -2, Z('abricot'));
  R := WinSendMsg(Lb, LM_INSERTITEM, -2, Z('melon'));
  R := WinSendMsg(Lb, LM_QUERYITEMTEXT, 1 Or (64 Shl 16), LongInt(@Buf));
  Check('liste : LM_INSERTITEM trie, LM_QUERYITEMCOUNT, LM_QUERYITEMTEXT (' + GetZ(LongInt(@Buf)) + ')',
        (WinSendMsg(Lb, LM_QUERYITEMCOUNT, 0, 0) = 3) And (GetZ(LongInt(@Buf)) = 'melon'));
  R := WinSendMsg(Lb, LM_SEARCHSTRING, 2 Or ($FFFF Shl 16), Z('PO'));
  R2 := WinSendMsg(Lb, LM_SELECTITEM, 2, 1);
  Check('LM_SEARCHSTRING (prefixe), LM_SELECTITEM, LM_QUERYSELECTION', (R = 2) And
        (WinSendMsg(Lb, LM_QUERYSELECTION, $FFFF, 0) = 2));
  R := WinSendMsg(Lb, LM_DELETEITEM, 0, 0);
  Check('LM_DELETEITEM', R = 2);
  Ef := WinCreateWindow(Client, $FFFF0006, Z('Saisie'), 0, 8, 80, 160, 16, Client, HWND_TOP, 302, 0, 0);
  R := WinSendMsg(Ef, EM_SETSEL, 0 Or (3 Shl 16), 0);
  R2 := WinSendMsg(Ef, EM_QUERYSEL, 0, 0);
  R := WinSendMsg(Ef, EM_COPY, 0, 0);
  P := WinQueryClipbrdData(Hab, 1);
  Check('champ de saisie : EM_SETSEL, EM_QUERYSEL, EM_COPY (' + GetZ(P) + ')', (R2 = 3 Shl 16) And (GetZ(P) = 'Sai'));
  R := WinSendMsg(Ef, EM_SETSEL, 6 Or (6 Shl 16), 0);
  R := WinSendMsg(Ef, EM_PASTE, 0, 0);
  R := WinQueryWindowText(Ef, 64, LongInt(@Buf));
  Check('EM_PASTE (' + GetZ(LongInt(@Buf)) + ')', GetZ(LongInt(@Buf)) = 'SaisieSai');
  Sb := WinWindowFromID(Frame, FID_VERTSCROLL);
  R := WinSendMsg(Sb, SBM_SETSCROLLBAR, 30, 10 Or (90 Shl 16));
  Check('barre de defilement : SBM_SETSCROLLBAR, SBM_QUERYPOS, SBM_QUERYRANGE', (WinSendMsg(Sb, SBM_QUERYPOS, 0, 0) = 30) And
        (WinSendMsg(Sb, SBM_QUERYRANGE, 0, 0) = 10 Or (90 Shl 16)));
  R := WinDestroyWindow(Lb);
  R2 := WinDestroyWindow(Ef);
  Check('WinDestroyWindow, WinIsWindow', (R = 1) And (R2 = 1) And (WinIsWindow(Hab, Lb) = 0));
  A := $FF0000;
  R := WinSetPresParam(Client, PP_FOREGROUNDCOLOR, 4, LongInt(@A));
  R2 := WinQueryPresParam(Client, PP_FOREGROUNDCOLOR, 0, LongInt(@B), 4, LongInt(@C), 0);
  Check('WinSetPresParam, WinQueryPresParam, WinRemovePresParam', (R = 1) And (R2 = 4) And (B = 1) And (C = $FF0000) And
        (WinRemovePresParam(Client, PP_FOREGROUNDCOLOR) = 1) And
        (WinQueryPresParam(Client, PP_FOREGROUNDCOLOR, 0, 0, 4, LongInt(@C), 0) = 0));

  { --- menu et accelerateur --- }
  BuildMenu;
  Mnu := WinCreateMenu(Frame, LongInt(@Mt));
  R := WinSendMsg(Mnu, MM_QUERYITEMTEXT, 201 Or (64 Shl 16), LongInt(@Buf));
  Check('WinCreateMenu (barre), MM_QUERYITEMCOUNT, MM_QUERYITEMTEXT (' + GetZ(LongInt(@Buf)) + ')',
        (Mnu <> 0) And (WinWindowFromID(Frame, FID_MENU) = Mnu) And (WinSendMsg(Mnu, MM_QUERYITEMCOUNT, 0, 0) = 2) And
        (GetZ(LongInt(@Buf)) = '~Ouvrir'));
  R := WinSendMsg(Mnu, MM_SETITEMATTR, 202 Or (1 Shl 16), MIA_DISABLED Or (MIA_DISABLED Shl 16));
  Check('MM_SETITEMATTR, MM_QUERYITEMATTR', (R = 1) And (WinSendMsg(Mnu, MM_QUERYITEMATTR, 202 Or (1 Shl 16), MIA_DISABLED) = MIA_DISABLED));
  WrW(LongInt(@Acc), 1); WrW(LongInt(@Acc) + 2, 850);
  WrW(LongInt(@Acc) + 4, AF_CHAR Or AF_CONTROL); WrW(LongInt(@Acc) + 6, Ord('s')); WrW(LongInt(@Acc) + 8, 101);
  A := WinCreateAccelTable(Hab, LongInt(@Acc));
  R := WinSetAccelTable(Hab, A, Frame);
  Check('WinCreateAccelTable, WinSetAccelTable, WinQueryAccelTable, WinCopyAccelTable', (A <> 0) And (R = 1) And
        (WinQueryAccelTable(Hab, Frame) = A) And (WinCopyAccelTable(A, 0, 0) = 10));
  Hk := WinSetHook(Hab, Hmq, HK_INPUT, LongInt(@InputHook), 0);
  Btn := WinCreateWindow(Client, $FFFF0003, Z('~Cliquer'), WS_VISIBLE Or WS_TABSTOP, 240, 112, 96, 16, Client, HWND_TOP,
                         300, 0, 0);
  Pt[0] := 48; Pt[1] := 8;
  R := WinMapWindowPoints(Btn, HWND_DESKTOP, LongInt(@Pt), 1);
  R := WinSetPointerPos(HWND_DESKTOP, Pt[0], Pt[1]);
  R := WinQueryPointerPos(HWND_DESKTOP, LongInt(@Rc1));
  Check('WinSetPointerPos, WinQueryPointerPos (' + IStr(Rc1[0]) + ', ' + IStr(Rc1[1]) + ')',
        (Rc1[0] Div 8 = Pt[0] Div 8) And (Rc1[1] Div 16 = Pt[1] Div 16));
  R := WinSetFocus(HWND_DESKTOP, Client);
  OutStr('Clavier : ctrl-s ; alt-f, o ; souris : bouton 1' + Chr(13) + Chr(10));
  Check('accelerateur ctrl-s : WM_COMMAND 101 (' + CmdLog + ')', WaitFor('[101]', 20000));
  Check('crochet HK_INPUT (' + IStr(NHook) + ')', NHook >= 1);
  Check('menu alt-f, o : WM_COMMAND 201 (' + CmdLog + ')', WaitFor('[201]', 10000));
  Check('clic de la souris sur le bouton : WM_COMMAND 300 (' + CmdLog + ')', WaitFor('[300]', 10000));
  R := WinReleaseHook(Hab, Hmq, HK_INPUT, LongInt(@InputHook), 0);
  Check('WinSetHook, WinReleaseHook', (Hk = 1) And (R = 1));

  { --- dialogue --- }
  BuildDlg;
  Dlg := WinCreateDlg(HWND_DESKTOP, Frame, LongInt(@DlgProc), LongInt(@Dt), 0);
  Check('WinCreateDlg : WM_INITDLG, elements', (Dlg <> 0) And (NInit = 1) And (WinWindowFromID(Dlg, 102) <> 0) And
        (WinWindowFromID(Dlg, FID_TITLEBAR) <> 0));
  R := WinSetDlgItemShort(Dlg, 102, -12, 1);
  R2 := 0;
  A := WinQueryDlgItemShort(Dlg, 102, LongInt(@R2), 1);
  Check('WinSetDlgItemShort, WinQueryDlgItemShort (' + IStr(R2) + ')', (R = 1) And (A = 1) And ((R2 And $FFFF) = $FFF4));
  R := WinSetDlgItemText(Dlg, 102, Z(''));
  Check('WinEnumDlgItem (premier, suivant)', (WinEnumDlgItem(Dlg, 0, 0) = WinWindowFromID(Dlg, 102)) And
        (WinEnumDlgItem(Dlg, WinWindowFromID(Dlg, 102), 2) = WinWindowFromID(Dlg, 103)));
  OutStr('Clavier : a b c tab espace entree' + Chr(13) + Chr(10));
  R := WinProcessDlg(Dlg);
  Check('WinProcessDlg : DID_OK, texte "abc" (' + DlgTxt + '), case cochee', (R = 1) And (DlgTxt = 'abc') And (DlgCheck = 1));
  R := WinDestroyWindow(Dlg);
  OutStr('Clavier : n' + Chr(13) + Chr(10));
  R := WinMessageBox(HWND_DESKTOP, Frame, Z('Continuer l''essai ?'), Z2('Question'), 0, MB_YESNO);
  Check('WinMessageBox : touche n -> MBID_NO', R = MBID_NO);

  { --- fin --- }
  R := WinDestroyWindow(Frame);
  Check('WinDestroyWindow du cadre', (R = 1) And (WinIsWindow(Hab, Client) = 0));
  R := WinDestroyMsgQueue(Hmq);
  R2 := WinTerminate(Hab);
  Check('WinDestroyMsgQueue, WinTerminate', (R = 1) And (R2 = 1));

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTWIN : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
