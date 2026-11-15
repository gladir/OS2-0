{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMCTLS.DLL de OS/2-0 (dialogues
                standard : fichier, police).
}

Library PMCTLS;

{$IMAGEBASE $00E80000}
{$R-,S-,I-}

{ Compilation : OS2PC PMCTLS.PAS   (produit PMCTLS.DLL)

  PMCTLS.DLL contient, sous OS/2 2.x, les dialogues standard de
  Presentation Manager. Fonctions (ordinaux d'OS/2) :

    2 WinFontDlg(hwndParent, hwndOwner, pfntd) : HWND
    3 WinDefFontDlgProc(hwnd, msg, mp1, mp2)
    4 WinFileDlg(hwndParent, hwndOwner, pfild) : HWND
    5 WinDefFileDlgProc(hwnd, msg, mp1, mp2)
    6 WinFreeFileDlgList(papszFQFilename) : BOOL

  Premiere version : les dialogues rendent DID_CANCEL dans lReturn
  (FILEDLG +12, FONTDLG +72), comme si l'utilisateur avait annule ; les
  procedures par defaut sont celle des dialogues de PMWIN. }

Type
  PLong = ^LongInt;

Function WinDefDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinDefDlgProc';

Const
  DID_CANCEL = 2;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
End;

Function WinFileDlg(HPar, HOwn, PFild : LongInt) : LongInt;
Begin
  WrL(PFild + 12, DID_CANCEL);
  WinFileDlg := 1;
End;

Function WinFontDlg(HPar, HOwn, PFntd : LongInt) : LongInt;
Begin
  WrL(PFntd + 72, DID_CANCEL);
  WinFontDlg := 1;
End;

Function WinDefFileDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinDefFileDlgProc := WinDefDlgProc(H, Msg, Mp1, Mp2);
End;

Function WinDefFontDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinDefFontDlgProc := WinDefDlgProc(H, Msg, Mp1, Mp2);
End;

Function WinFreeFileDlgList(P : LongInt) : LongInt;
Begin
  WinFreeFileDlgList := 1;
End;

exports
  WinFontDlg Index 2 Name 'WinFontDlg',
  WinDefFontDlgProc Index 3 Name 'WinDefFontDlgProc',
  WinFileDlg Index 4 Name 'WinFileDlg',
  WinDefFileDlgProc Index 5 Name 'WinDefFileDlgProc',
  WinFreeFileDlgList Index 6 Name 'WinFreeFileDlgList';

BEGIN
END.
