{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: HELLO - exemple de Pascal Developer : programme console
                (destination OS/2 Console).
}

Program Hello;

{ Ouvrir dans Pascal Developer (dossier Developer Kit du bureau), choisir
  Compiler, Destination OS/2 Console, puis Ctrl+F9 : le programme
  s'execute dans une fenetre OS/2 et attend une touche a la fin. }

Var
  I : LongInt;

Begin
  WriteLn('Bonjour de Pascal Developer !');
  WriteLn;
  For I := 1 To 10 Do
    WriteLn(I : 3, ' au carre = ', I * I : 4);
End.
