{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 LIBUNI.DLL de OS/2-0 (services Unicode
                et locales : ULS, Universal Language Support).
}

Library LIBUNI;

{$IMAGEBASE $00900000}
{$R-,S-,I-}

{ Compilation : OS2PC LIBUNI.PAS   (produit LIBUNI.DLL)

  LIBUNI.DLL est la bibliotheque Unicode d'OS/2 (ULS) : objets locales
  (conventions d'un pays et d'une langue), attributs des caracteres
  Unicode (UniQueryAlpha...), majuscules et minuscules, chaines UniChar
  (UniStrcpy...), collation (UniStrcoll, UniStrxfrm), conversions de
  nombres, de dates et de montants (UniStrtol, UniStrftime, UniStrfmon...),
  objets de transformation (UniTransformStr) et locales de l'utilisateur.

  Convention _System : valeurs de 32 bits (un UniChar est passe dans un
  double mot), pointeurs lineaires. Un UniChar est un mot (UCS-2) ; les
  chaines UniChar se terminent par 0. Les objets (LocaleObject,
  AttrObject, XformObject) sont des handles propres a LIBUNI ; la memoire
  rendue par UniQueryLocaleObject, UniQueryLocaleItem, UniLocaleTokenToStr,
  UniQueryLanguageName... se libere par UniFreeMem, celle de
  UniQueryLocaleInfo par UniFreeLocaleInfo (blocs de 512 octets de la
  DLL ; ceux d'un processus termine sont recuperes).

  Codes de retour (ULS_*) : 0 SUCCESS, 1 OTHER, 2 ILLEGALSEQUENCE,
  8 BADHANDLE, 12 NOTIMPLEMENTED, 13 NOMEMORY, 14 INVALID, 15 BADOBJECT,
  16 NOTOKEN, 17 NOMATCH, 18 BUFFERFULL, 19 RANGE, 20 UNSUPPORTED.
  Categories : LC_ALL -1, LC_COLLATE 0, LC_CTYPE 1, LC_NUMERIC 2,
  LC_MONETARY 3, LC_TIME 4, LC_MESSAGES 5. Specifications de locale :
  UNI_TOKEN_POINTER 1, UNI_MBS_STRING_POINTER 2, UNI_UCS_STRING_POINTER 3.

  Locales du systeme : C, POSIX, UNIVERSAL, en_US, en_GB, fr_FR, fr_CA,
  de_DE, es_ES, it_IT, nl_NL, pt_BR (nom complet, avec ou sans .codeset
  ou @modificateur, ou code de langue seul : fr -> fr_FR). Le nom vide
  designe la locale par defaut de chaque categorie : variables LC_ALL,
  LC_COLLATE..., LANG, puis la locale choisie par Locale, puis en_US.
  Jeton d'une locale (LocaleToken) : son rang + 1.

  Attributs des caracteres (CT_*, UniQueryChar, UniCreateAttrObject) :
    upper 0001h  lower 0002h  digit 0004h  space 0008h  punct 0010h
    cntrl 0020h  blank 0040h  xdigit 0080h alpha 0100h  alnum 0200h
    graph 0400h  print 0800h  number 1000h symbol 2000h ascii 8000h
  (noms separes par des espaces : le caractere doit avoir l'un d'eux).
  Les tables (attributs, majuscules et minuscules, valeurs numeriques,
  classes bidirectionnelles, decompositions canoniques) couvrent le plan
  multilingue de base ; elles sont generees de la base Unicode 15.1 et la
  classification est la meme dans toutes les locales.

  UNICTYPE (UniQueryCharType, UniQueryCharTypeTable), 8 octets :
    itype (mot : bits C1_* = CT_* 0001h a 0100h), bidi (octet : 1 L,
    2 R, 3 EN, 4 ES, 5 ET, 6 AN, 7 CS, 8 B, 9 S, 10 WS, 11 ON),
    charset (octet : CHS_* ci-dessous), extend (mot : C3_* 0001h
    nonspacing, 0002h diacritic, 0004h vowelmark, 0008h symbol, 0010h
    katakana, 0020h hiragana, 0040h halfwidth, 0080h fullwidth, 0100h
    ideograph, 0200h kashida, 8000h alpha), codepage (mot : bit 0 page
    437, bit 1 page 850, bit 2 ISO 8859-1).
  CHS_* : 0 none, 1 other, 2 latin, 3 cyrillic, 4 arabic, 5 greek,
  6 hebrew, 7 thai, 8 katakana, 9 hiragana, 10 hangul, 11 bopomofo,
  12 devanagari, 13 indic, 14 armenian, 15 hanzi, 16 punct, 17 symbol,
  18 digit, 19 control, 20 space.
  UniQueryStringType : CT_ITYPE 1, CT_BIDI 2, CT_CHARSET 3, CT_EXTENDED 4,
  CT_CODEPAGE 5, CT_INDEX 6 (rang dans la table des types), CT_CTYPE1 7,
  CT_CTYPE2 8 (bidi), CT_CTYPE3 9 (extend).

  Objets de transformation : upper, lower, compose, decompose (formes
  canoniques), hiragana, katakana, fullwidth, halfwidth (ASCII et
  katakana).

  Collation (locales autres que C, POSIX) : niveau 1 lettre de base sans
  accent ni casse (chiffres de toutes les ecritures par leur valeur),
  niveau 2 accent, niveau 3 casse. UniStrxfrm et UniMakeKey produisent une
  clef dont UniStrcmp donne le meme ordre que UniStrcoll.

  Elements des locales (LocaleItem, UniQueryLocaleItem et
  UniQueryLocaleValue) : 1 sDateTime, 2 sShortDate, 3 sTimeFormat,
  4 s1159, 5 s2359, 6-12 sAbbrevDayName7, 1..6 (dimanche, lundi..samedi),
  13-19 sDayName7, 1..6, 20-31 sAbbrevMonthName1..12, 32-43 sMonthName1..12,
  44 sDecimal, 45 sThousand, 46 sYesString, 47 sNoString, 48 sCurrency,
  49 sCodeSet, 50 xLocaleToken, 51 xWinLocale, 52 iLocaleResnum,
  53 sNativeDigits, 54 iMaxItem, 55 sTimeMark, 56 sEra, 57 sAltShortDate,
  58 sAltDateTime, 59 sAltTimeFormat, 60 sAltDigits, 61 sYesExpr,
  62 sNoExpr, 63 sDate, 64 sTime, 65 sList, 66 sMonDecimalSep,
  67 sMonThousandSep, 68 sGrouping, 69 sMonGrouping, 70 iMeasure,
  71 iPaper, 72 iDigits, 73 iTime, 74 iDate, 75 iCurrency, 76 iCurrDigits,
  77 iLzero, 78 iNegNumber, 79 iLDate, 80 iCalendarType, 81 iFirstDayOfWeek,
  82 iFirstWeekOfYear, 83 iNegCurr, 84 iTLzero, 85 iTimePrefix,
  86 iOptionalCalendar, 87 sIntlSymbol, 88 sAbbrevLangName, 89 sCollate,
  90 iUpperType, 91 iUpperMissing, 92 sPositiveSign, 93 sNegativeSign,
  94 sLeftNegative, 95 sRightNegative, 96 sLongDate, 97 sAltLongDate,
  98 sMonthName13, 99 sAbbrevMonthName13, 100 sName, 101 sLanguageID,
  102 sCountryID, 103 sEngLanguage, 104 sLanguage, 105 sEngCountry,
  106 sCountry, 107 sNativeCtryName, 108 iCountry, 109 sISOCodepage,
  110 iAnsiCodepage, 111 iCodepage, 112 iAltCodepage, 113 iMacCodepage,
  114 iEbcdicCodepage, 115 sOtherCodepages, 116 sSetCodepage,
  117 sKeyboard, 118 sAltKeyboard, 119 sSetKeyboard, 120 sDebit,
  121 sCredit, 122 sLatin1Locale, 123 wTimeFormat, 124 wShortDate,
  125 wLongDate, 126 jISO3CountryName, 127 jPercentPattern,
  128 jPercentSign, 129 jExponent, 130 jFullTimeFormat,
  131 jLongTimeFormat, 132 jShortTimeFormat, 133 jFullDateFormat,
  134 jMediumDateFormat, 135 jDateTimePattern, 136 jEraStrings.
  Les elements i* et x* sont des entiers (UniQueryLocaleValue) ;
  UniQueryLocaleItem les rend en decimal (x* : hexadecimal).

  UniLconv (UniQueryLocaleInfo), 76 octets : decimal_point,
  thousands_sep, grouping (short[], 0 a la fin), int_curr_symbol,
  currency_symbol, mon_decimal_point, mon_thousands_sep, mon_grouping,
  positive_sign, negative_sign (pointeurs), int_frac_digits, frac_digits,
  p_cs_precedes, p_sep_by_space, n_cs_precedes, n_sep_by_space,
  p_sign_posn, n_sign_posn, os2_mondecpt (short), debit_sign,
  credit_sign, left_parenthesis, right_parenthesis (pointeurs).
  struct tm : tm_sec, tm_min, tm_hour, tm_mday, tm_mon, tm_year (depuis
  1900), tm_wday, tm_yday, tm_isdst (int).

  Locales de l'utilisateur : UniMakeUserLocale cree une locale a partir
  d'une autre, UniSetUserLocaleItem remplace un element (type 1 : chaine
  UniChar, type 2 : entier) d'une locale de l'utilisateur ou du systeme,
  UniDeleteUserLocale retire une locale de l'utilisateur (ou les
  remplacements d'une locale du systeme), UniCompleteUserLocale les ecrit
  dans C:\USERLOC.INI (relu au chargement). UniGetOverride rend le
  remplacement d'un element.

  Points d'entree propres a OS/2-0 (non documentes par IBM) :
    UniMakeKey(lo, ucs, key, n)          clef de collation (= UniStrxfrm)
    UniGetColval(lo, uc)                 poids de collation d'un caractere
    UniGetOverride(pszLocale, item, ppsz)  remplacement d'un element
    UniProcessUconv(lo, psz, ucs, n)     chaine de la page de codes de la
                                         locale (LC_CTYPE) -> UniChar
    Locale(categorie, ucsNom)            locale par defaut (nom vide :
                                         revenir aux variables) ; rend son
                                         nom (UniChar), 0 si inconnu
    UniStrfmon(lo, ucs, max, fmt, ...)   valeurs double (8 octets) a la
                                         suite du format (8 au plus)

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Tables Unicode (generees)
    Partie 3 - Services de DOSCALLS et utilitaires
    Partie 4 - Caracteres Unicode
    Partie 5 - Locales (donnees, objets, elements)
    Partie 6 - Fonctions : objets locales et elements
    Partie 7 - Fonctions : attributs et types des caracteres
    Partie 8 - Fonctions : chaines UniChar
    Partie 9 - Fonctions : collation, transformations
    Partie 10 - Fonctions : nombres, dates, montants
    Partie 11 - Fonctions : locales de l'utilisateur, noms
    Exportations et initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  ULS_SUCCESS         = 0;
  ULS_OTHER           = 1;
  ULS_ILLEGALSEQUENCE = 2;
  ULS_BADHANDLE       = 8;
  ULS_NOTIMPLEMENTED  = 12;
  ULS_NOMEMORY        = 13;
  ULS_INVALID         = 14;
  ULS_BADOBJECT       = 15;
  ULS_NOTOKEN         = 16;
  ULS_NOMATCH         = 17;
  ULS_BUFFERFULL      = 18;
  ULS_RANGE           = 19;
  ULS_UNSUPPORTED     = 20;

  UNI_TOKEN_POINTER      = 1;
  UNI_MBS_STRING_POINTER = 2;
  UNI_UCS_STRING_POINTER = 3;

  LC_ALL      = -1;
  LC_COLLATE  = 0;
  LC_CTYPE    = 1;
  LC_NUMERIC  = 2;
  LC_MONETARY = 3;
  LC_TIME     = 4;
  LC_MESSAGES = 5;

  CT_UPPER  = $0001;
  CT_LOWER  = $0002;
  CT_DIGIT  = $0004;
  CT_SPACE  = $0008;
  CT_PUNCT  = $0010;
  CT_CNTRL  = $0020;
  CT_BLANK  = $0040;
  CT_XDIGIT = $0080;
  CT_ALPHA  = $0100;
  CT_ALNUM  = $0200;
  CT_GRAPH  = $0400;
  CT_PRINT  = $0800;
  CT_NUMBER = $1000;
  CT_SYMBOL = $2000;
  CT_MARK   = $4000;          { interne : marque (Mn, Mc, Me) }
  CT_ASCII  = $8000;

  NSysLoc  = 12;              { locales du systeme }
  NLang    = 7;
  NCtry    = 9;
  MaxUser  = 8;               { locales de l'utilisateur }
  MaxLoc   = 20;
  NF       = 53;              { champs d'une locale }
  NLF      = 41;              { champs d'une langue }
  MaxItem  = 136;
  MaxOv    = 64;              { elements remplaces }
  MaxLObj  = 32;              { objets locales }
  MaxAObj  = 32;              { objets attributs }
  MaxXObj  = 16;              { objets de transformation }
  PoolBlk  = 512;
  PoolN    = 128;
  MaxTT    = 1024;            { types de caracteres (UNICTYPE) }
  UserFile = 'C:\USERLOC.INI';

  { champs des locales }
  FName = 0;  FLang = 1;  FCtry = 2;  FCtryCode = 3;  FCodeset = 4;
  FDateTime = 5;  FDate = 6;  FTime = 7;  FAm = 8;  FPm = 9;
  FDec = 10;  FThou = 11;  FGroup = 12;  FCurr = 13;  FIntl = 14;
  FMonDec = 15;  FMonThou = 16;  FMonGroup = 17;  FPos = 18;  FNeg = 19;
  FFrac = 20;  FPcs = 21;  FPsep = 22;  FNcs = 23;  FNsep = 24;
  FPsign = 25;  FNsign = 26;  FYes = 27;  FNo = 28;  FDateSep = 29;
  FList = 30;  FLongDate = 31;  FAbbrLang = 32;  FKbd = 33;  FWin = 34;
  FCp = 35;  FEbcdic = 36;  FMeasure = 37;  FPaper = 38;  FFirstDay = 39;
  FFirstWeek = 40;  FIso3 = 41;  FWTime = 42;  FWShort = 43;  FWLong = 44;
  FNegCurr = 45;  FITime = 46;  FIDate = 47;  FYesExpr = 48;  FNoExpr = 49;
  FIntFrac = 50;  FDebit = 51;  FCredit = 52;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { locales : champs (latin-1, octet 80h = euro) }
  LBuf     : Array[0..MaxLoc * NF * 64 - 1] Of Byte;   { champs : cases de 64 octets }
  LUsed    : Array[0..MaxLoc - 1] Of Boolean;
  LangCode : Array[0..NLang - 1] Of String[3];
  LangBuf  : Array[0..NLang * NLF * 32 - 1] Of Byte;
  CtryBuf  : Array[0..NCtry * 5 * 32 - 1] Of Byte;
  { remplacements d'elements }
  OvLoc, OvItem : Array[0..MaxOv - 1] Of LongInt;
  OvBuf    : Array[0..MaxOv * 128 - 1] Of Byte;
  { locale par defaut par categorie (Locale) }
  GDef     : Array[0..5] Of String[31];
  GLocRet  : Array[0..63] Of Word;
  { objets }
  LOOwn, LOGen : Array[0..MaxLObj - 1] Of LongInt;
  LOCat    : Array[0..MaxLObj * 6 - 1] Of LongInt;
  AOOwn, AOGen, AOMask : Array[0..MaxAObj - 1] Of LongInt;
  XOOwn, XOGen, XOKind : Array[0..MaxXObj - 1] Of LongInt;
  { memoire rendue aux applications }
  PoolMem  : Array[0..PoolN * PoolBlk - 1] Of Byte;
  PoolOwn  : Array[0..PoolN - 1] Of LongInt;
  { types de caracteres }
  TTab     : Array[0..MaxTT * 8 - 1] Of Byte;
  TTKey1, TTKey2 : Array[0..MaxTT - 1] Of LongInt;
  TTN, TTLast : LongInt;
  TTFull   : Boolean;
  GCharType : Array[0..7] Of Byte;
  { UniStrtok }
  GTokPos  : LongInt;
  { struct tm en cours }
  TmSec, TmMin, TmHour, TmMday, TmMon, TmYear, TmWday, TmYday : LongInt;
  { conversion des reels }
  GDbl, GDbl2 : Double;
  GArg     : Array[0..15] Of LongInt;
  { tampons }
  NameZ    : Array[0..259] Of Byte;
  IoBuf    : Array[0..8191] Of Byte;
  IoLen    : LongInt;
  GCur     : LongInt;                 { analyse d'une chaine UniChar }
  PtPm, PtHas12 : LongInt;            { UniStrptime : AM/PM, %I }
  GQ, GD, GMV : Double;
  Dummy    : LongInt;

{ ==================================================================== }
{ Partie 2 - Tables Unicode (generees)                                 }
{ ==================================================================== }

{ Tables generees a partir de la base Unicode 15.1.0 (UnicodeData) : plan
  multilingue de base (0000h-FFFFh) }

Const
  NMaskRun = 2472;
  NBidiRun = 1150;
  NUpRun = 184;
  NLowRun = 171;
  NNumRun = 181;
  NDecomp = 1486;

  { attributs : debut de chaque suite de caracteres de memes attributs (CT_*) }
  MaskStart : Array[0..2471] Of Word = (
    $0000, $0009, $000A, $000E, $0020, $0021, $0024, $0025, $002B, $002C, $0030, $003A,
    $003C, $003F, $0041, $0047, $005B, $005E, $005F, $0060, $0061, $0067, $007B, $007C,
    $007D, $007E, $007F, $0080, $0085, $0086, $00A0, $00A1, $00A2, $00A7, $00A8, $00AA,
    $00AB, $00AC, $00AD, $00AE, $00B2, $00B4, $00B5, $00B6, $00B8, $00B9, $00BA, $00BB,
    $00BC, $00BF, $00C0, $00D7, $00D8, $00DF, $00F7, $00F8, $0100, $0101, $0102, $0103,
    $0104, $0105, $0106, $0107, $0108, $0109, $010A, $010B, $010C, $010D, $010E, $010F,
    $0110, $0111, $0112, $0113, $0114, $0115, $0116, $0117, $0118, $0119, $011A, $011B,
    $011C, $011D, $011E, $011F, $0120, $0121, $0122, $0123, $0124, $0125, $0126, $0127,
    $0128, $0129, $012A, $012B, $012C, $012D, $012E, $012F, $0130, $0131, $0132, $0133,
    $0134, $0135, $0136, $0137, $0139, $013A, $013B, $013C, $013D, $013E, $013F, $0140,
    $0141, $0142, $0143, $0144, $0145, $0146, $0147, $0148, $014A, $014B, $014C, $014D,
    $014E, $014F, $0150, $0151, $0152, $0153, $0154, $0155, $0156, $0157, $0158, $0159,
    $015A, $015B, $015C, $015D, $015E, $015F, $0160, $0161, $0162, $0163, $0164, $0165,
    $0166, $0167, $0168, $0169, $016A, $016B, $016C, $016D, $016E, $016F, $0170, $0171,
    $0172, $0173, $0174, $0175, $0176, $0177, $0178, $017A, $017B, $017C, $017D, $017E,
    $0181, $0183, $0184, $0185, $0186, $0188, $0189, $018C, $018E, $0192, $0193, $0195,
    $0196, $0199, $019C, $019E, $019F, $01A1, $01A2, $01A3, $01A4, $01A5, $01A6, $01A8,
    $01A9, $01AA, $01AC, $01AD, $01AE, $01B0, $01B1, $01B4, $01B5, $01B6, $01B7, $01B9,
    $01BB, $01BC, $01BD, $01C0, $01C4, $01C6, $01C7, $01C9, $01CA, $01CC, $01CD, $01CE,
    $01CF, $01D0, $01D1, $01D2, $01D3, $01D4, $01D5, $01D6, $01D7, $01D8, $01D9, $01DA,
    $01DB, $01DC, $01DE, $01DF, $01E0, $01E1, $01E2, $01E3, $01E4, $01E5, $01E6, $01E7,
    $01E8, $01E9, $01EA, $01EB, $01EC, $01ED, $01EE, $01EF, $01F1, $01F3, $01F4, $01F5,
    $01F6, $01F9, $01FA, $01FB, $01FC, $01FD, $01FE, $01FF, $0200, $0201, $0202, $0203,
    $0204, $0205, $0206, $0207, $0208, $0209, $020A, $020B, $020C, $020D, $020E, $020F,
    $0210, $0211, $0212, $0213, $0214, $0215, $0216, $0217, $0218, $0219, $021A, $021B,
    $021C, $021D, $021E, $021F, $0220, $0221, $0222, $0223, $0224, $0225, $0226, $0227,
    $0228, $0229, $022A, $022B, $022C, $022D, $022E, $022F, $0230, $0231, $0232, $0233,
    $023A, $023C, $023D, $023F, $0241, $0242, $0243, $0247, $0248, $0249, $024A, $024B,
    $024C, $024D, $024E, $024F, $0294, $0295, $02B0, $02C2, $02C6, $02D2, $02E0, $02E5,
    $02EC, $02ED, $02EE, $02EF, $0300, $0345, $0346, $0370, $0371, $0372, $0373, $0374,
    $0375, $0376, $0377, $0378, $037A, $037B, $037E, $037F, $0380, $0384, $0386, $0387,
    $0388, $038B, $038C, $038D, $038E, $0390, $0391, $03A2, $03A3, $03AC, $03CF, $03D0,
    $03D2, $03D5, $03D8, $03D9, $03DA, $03DB, $03DC, $03DD, $03DE, $03DF, $03E0, $03E1,
    $03E2, $03E3, $03E4, $03E5, $03E6, $03E7, $03E8, $03E9, $03EA, $03EB, $03EC, $03ED,
    $03EE, $03EF, $03F4, $03F5, $03F6, $03F7, $03F8, $03F9, $03FB, $03FD, $0430, $0460,
    $0461, $0462, $0463, $0464, $0465, $0466, $0467, $0468, $0469, $046A, $046B, $046C,
    $046D, $046E, $046F, $0470, $0471, $0472, $0473, $0474, $0475, $0476, $0477, $0478,
    $0479, $047A, $047B, $047C, $047D, $047E, $047F, $0480, $0481, $0482, $0483, $048A,
    $048B, $048C, $048D, $048E, $048F, $0490, $0491, $0492, $0493, $0494, $0495, $0496,
    $0497, $0498, $0499, $049A, $049B, $049C, $049D, $049E, $049F, $04A0, $04A1, $04A2,
    $04A3, $04A4, $04A5, $04A6, $04A7, $04A8, $04A9, $04AA, $04AB, $04AC, $04AD, $04AE,
    $04AF, $04B0, $04B1, $04B2, $04B3, $04B4, $04B5, $04B6, $04B7, $04B8, $04B9, $04BA,
    $04BB, $04BC, $04BD, $04BE, $04BF, $04C0, $04C2, $04C3, $04C4, $04C5, $04C6, $04C7,
    $04C8, $04C9, $04CA, $04CB, $04CC, $04CD, $04CE, $04D0, $04D1, $04D2, $04D3, $04D4,
    $04D5, $04D6, $04D7, $04D8, $04D9, $04DA, $04DB, $04DC, $04DD, $04DE, $04DF, $04E0,
    $04E1, $04E2, $04E3, $04E4, $04E5, $04E6, $04E7, $04E8, $04E9, $04EA, $04EB, $04EC,
    $04ED, $04EE, $04EF, $04F0, $04F1, $04F2, $04F3, $04F4, $04F5, $04F6, $04F7, $04F8,
    $04F9, $04FA, $04FB, $04FC, $04FD, $04FE, $04FF, $0500, $0501, $0502, $0503, $0504,
    $0505, $0506, $0507, $0508, $0509, $050A, $050B, $050C, $050D, $050E, $050F, $0510,
    $0511, $0512, $0513, $0514, $0515, $0516, $0517, $0518, $0519, $051A, $051B, $051C,
    $051D, $051E, $051F, $0520, $0521, $0522, $0523, $0524, $0525, $0526, $0527, $0528,
    $0529, $052A, $052B, $052C, $052D, $052E, $052F, $0530, $0531, $0557, $0559, $055A,
    $0560, $0589, $058B, $058D, $0590, $0591, $05BE, $05BF, $05C0, $05C1, $05C3, $05C4,
    $05C6, $05C7, $05C8, $05D0, $05EB, $05EF, $05F3, $05F5, $0600, $0606, $0609, $060B,
    $060C, $060E, $0610, $061B, $061C, $061D, $0620, $064B, $0660, $066A, $066E, $0670,
    $0671, $06D4, $06D5, $06D6, $06DD, $06DE, $06DF, $06E5, $06E7, $06E9, $06EA, $06EE,
    $06F0, $06FA, $06FD, $06FF, $0700, $070E, $070F, $0710, $0711, $0712, $0730, $074B,
    $074D, $07A6, $07B1, $07B2, $07C0, $07CA, $07EB, $07F4, $07F6, $07F7, $07FA, $07FB,
    $07FD, $07FE, $0800, $0816, $081A, $081B, $0824, $0825, $0828, $0829, $082E, $0830,
    $083F, $0840, $0859, $085C, $085E, $085F, $0860, $086B, $0870, $0888, $0889, $088F,
    $0890, $0892, $0898, $08A0, $08CA, $08E2, $08E3, $0904, $093A, $093D, $093E, $0950,
    $0951, $0958, $0962, $0964, $0966, $0970, $0971, $0981, $0984, $0985, $098D, $098F,
    $0991, $0993, $09A9, $09AA, $09B1, $09B2, $09B3, $09B6, $09BA, $09BC, $09BD, $09BE,
    $09C5, $09C7, $09C9, $09CB, $09CE, $09CF, $09D7, $09D8, $09DC, $09DE, $09DF, $09E2,
    $09E4, $09E6, $09F0, $09F2, $09F4, $09FA, $09FC, $09FD, $09FE, $09FF, $0A01, $0A04,
    $0A05, $0A0B, $0A0F, $0A11, $0A13, $0A29, $0A2A, $0A31, $0A32, $0A34, $0A35, $0A37,
    $0A38, $0A3A, $0A3C, $0A3D, $0A3E, $0A43, $0A47, $0A49, $0A4B, $0A4E, $0A51, $0A52,
    $0A59, $0A5D, $0A5E, $0A5F, $0A66, $0A70, $0A72, $0A75, $0A76, $0A77, $0A81, $0A84,
    $0A85, $0A8E, $0A8F, $0A92, $0A93, $0AA9, $0AAA, $0AB1, $0AB2, $0AB4, $0AB5, $0ABA,
    $0ABC, $0ABD, $0ABE, $0AC6, $0AC7, $0ACA, $0ACB, $0ACE, $0AD0, $0AD1, $0AE0, $0AE2,
    $0AE4, $0AE6, $0AF0, $0AF1, $0AF2, $0AF9, $0AFA, $0B00, $0B01, $0B04, $0B05, $0B0D,
    $0B0F, $0B11, $0B13, $0B29, $0B2A, $0B31, $0B32, $0B34, $0B35, $0B3A, $0B3C, $0B3D,
    $0B3E, $0B45, $0B47, $0B49, $0B4B, $0B4E, $0B55, $0B58, $0B5C, $0B5E, $0B5F, $0B62,
    $0B64, $0B66, $0B70, $0B71, $0B72, $0B78, $0B82, $0B83, $0B84, $0B85, $0B8B, $0B8E,
    $0B91, $0B92, $0B96, $0B99, $0B9B, $0B9C, $0B9D, $0B9E, $0BA0, $0BA3, $0BA5, $0BA8,
    $0BAB, $0BAE, $0BBA, $0BBE, $0BC3, $0BC6, $0BC9, $0BCA, $0BCE, $0BD0, $0BD1, $0BD7,
    $0BD8, $0BE6, $0BF0, $0BF3, $0BFB, $0C00, $0C05, $0C0D, $0C0E, $0C11, $0C12, $0C29,
    $0C2A, $0C3A, $0C3C, $0C3D, $0C3E, $0C45, $0C46, $0C49, $0C4A, $0C4E, $0C55, $0C57,
    $0C58, $0C5B, $0C5D, $0C5E, $0C60, $0C62, $0C64, $0C66, $0C70, $0C77, $0C78, $0C7F,
    $0C80, $0C81, $0C84, $0C85, $0C8D, $0C8E, $0C91, $0C92, $0CA9, $0CAA, $0CB4, $0CB5,
    $0CBA, $0CBC, $0CBD, $0CBE, $0CC5, $0CC6, $0CC9, $0CCA, $0CCE, $0CD5, $0CD7, $0CDD,
    $0CDF, $0CE0, $0CE2, $0CE4, $0CE6, $0CF0, $0CF1, $0CF3, $0CF4, $0D00, $0D04, $0D0D,
    $0D0E, $0D11, $0D12, $0D3B, $0D3D, $0D3E, $0D45, $0D46, $0D49, $0D4A, $0D4E, $0D4F,
    $0D50, $0D54, $0D57, $0D58, $0D5F, $0D62, $0D64, $0D66, $0D70, $0D79, $0D7A, $0D80,
    $0D81, $0D84, $0D85, $0D97, $0D9A, $0DB2, $0DB3, $0DBC, $0DBD, $0DBE, $0DC0, $0DC7,
    $0DCA, $0DCB, $0DCF, $0DD5, $0DD6, $0DD7, $0DD8, $0DE0, $0DE6, $0DF0, $0DF2, $0DF4,
    $0DF5, $0E01, $0E31, $0E32, $0E34, $0E3B, $0E3F, $0E40, $0E47, $0E4F, $0E50, $0E5A,
    $0E5C, $0E81, $0E83, $0E84, $0E85, $0E86, $0E8B, $0E8C, $0EA4, $0EA5, $0EA6, $0EA7,
    $0EB1, $0EB2, $0EB4, $0EBD, $0EBE, $0EC0, $0EC5, $0EC6, $0EC7, $0EC8, $0ECF, $0ED0,
    $0EDA, $0EDC, $0EE0, $0F00, $0F01, $0F04, $0F13, $0F14, $0F15, $0F18, $0F1A, $0F20,
    $0F2A, $0F34, $0F35, $0F36, $0F37, $0F38, $0F39, $0F3A, $0F3E, $0F40, $0F48, $0F49,
    $0F6D, $0F71, $0F85, $0F86, $0F88, $0F8D, $0F98, $0F99, $0FBD, $0FBE, $0FC6, $0FC7,
    $0FCD, $0FCE, $0FD0, $0FD5, $0FD9, $0FDB, $1000, $102B, $103F, $1040, $104A, $1050,
    $1056, $105A, $105E, $1061, $1062, $1065, $1067, $106E, $1071, $1075, $1082, $108E,
    $108F, $1090, $109A, $109E, $10A0, $10C6, $10C7, $10C8, $10CD, $10CE, $10D0, $10FB,
    $10FC, $10FD, $1100, $1249, $124A, $124E, $1250, $1257, $1258, $1259, $125A, $125E,
    $1260, $1289, $128A, $128E, $1290, $12B1, $12B2, $12B6, $12B8, $12BF, $12C0, $12C1,
    $12C2, $12C6, $12C8, $12D7, $12D8, $1311, $1312, $1316, $1318, $135B, $135D, $1360,
    $1369, $137D, $1380, $1390, $139A, $13A0, $13F6, $13F8, $13FE, $1400, $1401, $166D,
    $166E, $166F, $1680, $1681, $169B, $169D, $16A0, $16EB, $16EE, $16F1, $16F9, $1700,
    $1712, $1716, $171F, $1732, $1735, $1737, $1740, $1752, $1754, $1760, $176D, $176E,
    $1771, $1772, $1774, $1780, $17B4, $17D4, $17D7, $17D8, $17DB, $17DC, $17DD, $17DE,
    $17E0, $17EA, $17F0, $17FA, $1800, $180B, $180E, $180F, $1810, $181A, $1820, $1879,
    $1880, $1885, $1887, $18A9, $18AA, $18AB, $18B0, $18F6, $1900, $191F, $1920, $192C,
    $1930, $193C, $1940, $1941, $1944, $1946, $1950, $196E, $1970, $1975, $1980, $19AC,
    $19B0, $19CA, $19D0, $19DA, $19DB, $19DE, $1A00, $1A17, $1A1C, $1A1E, $1A20, $1A55,
    $1A5F, $1A60, $1A7D, $1A7F, $1A80, $1A8A, $1A90, $1A9A, $1AA0, $1AA7, $1AA8, $1AAE,
    $1AB0, $1ACF, $1B00, $1B05, $1B34, $1B45, $1B4D, $1B50, $1B5A, $1B61, $1B6B, $1B74,
    $1B7D, $1B7F, $1B80, $1B83, $1BA1, $1BAE, $1BB0, $1BBA, $1BE6, $1BF4, $1BFC, $1C00,
    $1C24, $1C38, $1C3B, $1C40, $1C4A, $1C4D, $1C50, $1C5A, $1C7E, $1C80, $1C89, $1C90,
    $1CBB, $1CBD, $1CC0, $1CC8, $1CD0, $1CD3, $1CD4, $1CE9, $1CED, $1CEE, $1CF4, $1CF5,
    $1CF7, $1CFA, $1CFB, $1D00, $1D2C, $1D6B, $1D78, $1D79, $1D9B, $1DC0, $1E00, $1E01,
    $1E02, $1E03, $1E04, $1E05, $1E06, $1E07, $1E08, $1E09, $1E0A, $1E0B, $1E0C, $1E0D,
    $1E0E, $1E0F, $1E10, $1E11, $1E12, $1E13, $1E14, $1E15, $1E16, $1E17, $1E18, $1E19,
    $1E1A, $1E1B, $1E1C, $1E1D, $1E1E, $1E1F, $1E20, $1E21, $1E22, $1E23, $1E24, $1E25,
    $1E26, $1E27, $1E28, $1E29, $1E2A, $1E2B, $1E2C, $1E2D, $1E2E, $1E2F, $1E30, $1E31,
    $1E32, $1E33, $1E34, $1E35, $1E36, $1E37, $1E38, $1E39, $1E3A, $1E3B, $1E3C, $1E3D,
    $1E3E, $1E3F, $1E40, $1E41, $1E42, $1E43, $1E44, $1E45, $1E46, $1E47, $1E48, $1E49,
    $1E4A, $1E4B, $1E4C, $1E4D, $1E4E, $1E4F, $1E50, $1E51, $1E52, $1E53, $1E54, $1E55,
    $1E56, $1E57, $1E58, $1E59, $1E5A, $1E5B, $1E5C, $1E5D, $1E5E, $1E5F, $1E60, $1E61,
    $1E62, $1E63, $1E64, $1E65, $1E66, $1E67, $1E68, $1E69, $1E6A, $1E6B, $1E6C, $1E6D,
    $1E6E, $1E6F, $1E70, $1E71, $1E72, $1E73, $1E74, $1E75, $1E76, $1E77, $1E78, $1E79,
    $1E7A, $1E7B, $1E7C, $1E7D, $1E7E, $1E7F, $1E80, $1E81, $1E82, $1E83, $1E84, $1E85,
    $1E86, $1E87, $1E88, $1E89, $1E8A, $1E8B, $1E8C, $1E8D, $1E8E, $1E8F, $1E90, $1E91,
    $1E92, $1E93, $1E94, $1E95, $1E9E, $1E9F, $1EA0, $1EA1, $1EA2, $1EA3, $1EA4, $1EA5,
    $1EA6, $1EA7, $1EA8, $1EA9, $1EAA, $1EAB, $1EAC, $1EAD, $1EAE, $1EAF, $1EB0, $1EB1,
    $1EB2, $1EB3, $1EB4, $1EB5, $1EB6, $1EB7, $1EB8, $1EB9, $1EBA, $1EBB, $1EBC, $1EBD,
    $1EBE, $1EBF, $1EC0, $1EC1, $1EC2, $1EC3, $1EC4, $1EC5, $1EC6, $1EC7, $1EC8, $1EC9,
    $1ECA, $1ECB, $1ECC, $1ECD, $1ECE, $1ECF, $1ED0, $1ED1, $1ED2, $1ED3, $1ED4, $1ED5,
    $1ED6, $1ED7, $1ED8, $1ED9, $1EDA, $1EDB, $1EDC, $1EDD, $1EDE, $1EDF, $1EE0, $1EE1,
    $1EE2, $1EE3, $1EE4, $1EE5, $1EE6, $1EE7, $1EE8, $1EE9, $1EEA, $1EEB, $1EEC, $1EED,
    $1EEE, $1EEF, $1EF0, $1EF1, $1EF2, $1EF3, $1EF4, $1EF5, $1EF6, $1EF7, $1EF8, $1EF9,
    $1EFA, $1EFB, $1EFC, $1EFD, $1EFE, $1EFF, $1F08, $1F10, $1F16, $1F18, $1F1E, $1F20,
    $1F28, $1F30, $1F38, $1F40, $1F46, $1F48, $1F4E, $1F50, $1F58, $1F59, $1F5A, $1F5B,
    $1F5C, $1F5D, $1F5E, $1F5F, $1F60, $1F68, $1F70, $1F7E, $1F80, $1F88, $1F90, $1F98,
    $1FA0, $1FA8, $1FB0, $1FB5, $1FB6, $1FB8, $1FBD, $1FBE, $1FBF, $1FC2, $1FC5, $1FC6,
    $1FC8, $1FCD, $1FD0, $1FD4, $1FD6, $1FD8, $1FDC, $1FDD, $1FE0, $1FE8, $1FED, $1FF0,
    $1FF2, $1FF5, $1FF6, $1FF8, $1FFD, $1FFF, $2000, $200B, $2010, $2028, $202A, $202F,
    $2030, $2044, $2045, $2052, $2053, $205F, $2060, $2065, $2066, $2070, $2071, $2072,
    $2074, $207A, $207D, $207F, $2080, $208A, $208D, $208F, $2090, $209D, $20A0, $20C1,
    $20D0, $20F1, $2100, $2102, $2103, $2107, $2108, $210A, $210B, $210E, $2110, $2113,
    $2114, $2115, $2116, $2119, $211E, $2124, $2125, $2126, $2127, $2128, $2129, $212A,
    $212E, $212F, $2130, $2134, $2135, $2139, $213A, $213C, $213E, $2140, $2145, $2146,
    $214A, $214E, $214F, $2150, $2160, $2170, $2180, $2183, $2184, $2185, $2189, $218A,
    $218C, $2190, $2308, $230C, $2329, $232B, $2427, $2440, $244B, $2460, $249C, $24B6,
    $24D0, $24EA, $2500, $2768, $2776, $2794, $27C5, $27C7, $27E6, $27F0, $2983, $2999,
    $29D8, $29DC, $29FC, $29FE, $2B74, $2B76, $2B96, $2B97, $2C00, $2C30, $2C60, $2C61,
    $2C62, $2C65, $2C67, $2C68, $2C69, $2C6A, $2C6B, $2C6C, $2C6D, $2C71, $2C72, $2C73,
    $2C75, $2C76, $2C7C, $2C7E, $2C81, $2C82, $2C83, $2C84, $2C85, $2C86, $2C87, $2C88,
    $2C89, $2C8A, $2C8B, $2C8C, $2C8D, $2C8E, $2C8F, $2C90, $2C91, $2C92, $2C93, $2C94,
    $2C95, $2C96, $2C97, $2C98, $2C99, $2C9A, $2C9B, $2C9C, $2C9D, $2C9E, $2C9F, $2CA0,
    $2CA1, $2CA2, $2CA3, $2CA4, $2CA5, $2CA6, $2CA7, $2CA8, $2CA9, $2CAA, $2CAB, $2CAC,
    $2CAD, $2CAE, $2CAF, $2CB0, $2CB1, $2CB2, $2CB3, $2CB4, $2CB5, $2CB6, $2CB7, $2CB8,
    $2CB9, $2CBA, $2CBB, $2CBC, $2CBD, $2CBE, $2CBF, $2CC0, $2CC1, $2CC2, $2CC3, $2CC4,
    $2CC5, $2CC6, $2CC7, $2CC8, $2CC9, $2CCA, $2CCB, $2CCC, $2CCD, $2CCE, $2CCF, $2CD0,
    $2CD1, $2CD2, $2CD3, $2CD4, $2CD5, $2CD6, $2CD7, $2CD8, $2CD9, $2CDA, $2CDB, $2CDC,
    $2CDD, $2CDE, $2CDF, $2CE0, $2CE1, $2CE2, $2CE3, $2CE5, $2CEB, $2CEC, $2CED, $2CEE,
    $2CEF, $2CF2, $2CF3, $2CF4, $2CF9, $2CFD, $2CFE, $2D00, $2D26, $2D27, $2D28, $2D2D,
    $2D2E, $2D30, $2D68, $2D6F, $2D70, $2D71, $2D7F, $2D80, $2D97, $2DA0, $2DA7, $2DA8,
    $2DAF, $2DB0, $2DB7, $2DB8, $2DBF, $2DC0, $2DC7, $2DC8, $2DCF, $2DD0, $2DD7, $2DD8,
    $2DDF, $2DE0, $2E00, $2E2F, $2E30, $2E50, $2E52, $2E5E, $2E80, $2E9A, $2E9B, $2EF4,
    $2F00, $2FD6, $2FF0, $3000, $3001, $3004, $3005, $3007, $3008, $3012, $3014, $3020,
    $3021, $302A, $3030, $3031, $3036, $3038, $303B, $303D, $303E, $3040, $3041, $3097,
    $3099, $309B, $309D, $30A0, $30A1, $30FB, $30FC, $3100, $3105, $3130, $3131, $318F,
    $3190, $3192, $3196, $31A0, $31C0, $31E4, $31EF, $31F0, $3200, $321F, $3220, $322A,
    $3248, $3250, $3251, $3260, $3280, $328A, $32B1, $32C0, $3400, $4DC0, $4E00, $A48D,
    $A490, $A4C7, $A4D0, $A4FE, $A500, $A60D, $A610, $A620, $A62A, $A62C, $A640, $A641,
    $A642, $A643, $A644, $A645, $A646, $A647, $A648, $A649, $A64A, $A64B, $A64C, $A64D,
    $A64E, $A64F, $A650, $A651, $A652, $A653, $A654, $A655, $A656, $A657, $A658, $A659,
    $A65A, $A65B, $A65C, $A65D, $A65E, $A65F, $A660, $A661, $A662, $A663, $A664, $A665,
    $A666, $A667, $A668, $A669, $A66A, $A66B, $A66C, $A66D, $A66E, $A66F, $A673, $A674,
    $A67E, $A67F, $A680, $A681, $A682, $A683, $A684, $A685, $A686, $A687, $A688, $A689,
    $A68A, $A68B, $A68C, $A68D, $A68E, $A68F, $A690, $A691, $A692, $A693, $A694, $A695,
    $A696, $A697, $A698, $A699, $A69A, $A69B, $A69C, $A69E, $A6A0, $A6E6, $A6F0, $A6F2,
    $A6F8, $A700, $A717, $A720, $A722, $A723, $A724, $A725, $A726, $A727, $A728, $A729,
    $A72A, $A72B, $A72C, $A72D, $A72E, $A72F, $A732, $A733, $A734, $A735, $A736, $A737,
    $A738, $A739, $A73A, $A73B, $A73C, $A73D, $A73E, $A73F, $A740, $A741, $A742, $A743,
    $A744, $A745, $A746, $A747, $A748, $A749, $A74A, $A74B, $A74C, $A74D, $A74E, $A74F,
    $A750, $A751, $A752, $A753, $A754, $A755, $A756, $A757, $A758, $A759, $A75A, $A75B,
    $A75C, $A75D, $A75E, $A75F, $A760, $A761, $A762, $A763, $A764, $A765, $A766, $A767,
    $A768, $A769, $A76A, $A76B, $A76C, $A76D, $A76E, $A76F, $A770, $A771, $A779, $A77A,
    $A77B, $A77C, $A77D, $A77F, $A780, $A781, $A782, $A783, $A784, $A785, $A786, $A787,
    $A788, $A789, $A78B, $A78C, $A78D, $A78E, $A78F, $A790, $A791, $A792, $A793, $A796,
    $A797, $A798, $A799, $A79A, $A79B, $A79C, $A79D, $A79E, $A79F, $A7A0, $A7A1, $A7A2,
    $A7A3, $A7A4, $A7A5, $A7A6, $A7A7, $A7A8, $A7A9, $A7AA, $A7AF, $A7B0, $A7B5, $A7B6,
    $A7B7, $A7B8, $A7B9, $A7BA, $A7BB, $A7BC, $A7BD, $A7BE, $A7BF, $A7C0, $A7C1, $A7C2,
    $A7C3, $A7C4, $A7C8, $A7C9, $A7CA, $A7CB, $A7D0, $A7D1, $A7D2, $A7D3, $A7D4, $A7D5,
    $A7D6, $A7D7, $A7D8, $A7D9, $A7DA, $A7F2, $A7F5, $A7F6, $A7F7, $A7FA, $A7FB, $A802,
    $A803, $A806, $A807, $A80B, $A80C, $A823, $A828, $A82C, $A82D, $A830, $A836, $A83A,
    $A840, $A874, $A878, $A880, $A882, $A8B4, $A8C6, $A8CE, $A8D0, $A8DA, $A8E0, $A8F2,
    $A8F8, $A8FB, $A8FC, $A8FD, $A8FF, $A900, $A90A, $A926, $A92E, $A930, $A947, $A954,
    $A95F, $A960, $A97D, $A980, $A984, $A9B3, $A9C1, $A9CE, $A9CF, $A9D0, $A9DA, $A9DE,
    $A9E0, $A9E5, $A9E6, $A9F0, $A9FA, $A9FF, $AA00, $AA29, $AA37, $AA40, $AA43, $AA44,
    $AA4C, $AA4E, $AA50, $AA5A, $AA5C, $AA60, $AA77, $AA7A, $AA7B, $AA7E, $AAB0, $AAB1,
    $AAB2, $AAB5, $AAB7, $AAB9, $AABE, $AAC0, $AAC1, $AAC2, $AAC3, $AADB, $AADE, $AAE0,
    $AAEB, $AAF0, $AAF2, $AAF5, $AAF7, $AB01, $AB07, $AB09, $AB0F, $AB11, $AB17, $AB20,
    $AB27, $AB28, $AB2F, $AB30, $AB5B, $AB5C, $AB60, $AB69, $AB6A, $AB6C, $AB70, $ABC0,
    $ABE3, $ABEB, $ABEC, $ABEE, $ABF0, $ABFA, $AC00, $D7A4, $D7B0, $D7C7, $D7CB, $D7FC,
    $F900, $FA6E, $FA70, $FADA, $FB00, $FB07, $FB13, $FB18, $FB1D, $FB1E, $FB1F, $FB29,
    $FB2A, $FB37, $FB38, $FB3D, $FB3E, $FB3F, $FB40, $FB42, $FB43, $FB45, $FB46, $FBB2,
    $FBC3, $FBD3, $FD3E, $FD40, $FD50, $FD90, $FD92, $FDC8, $FDCF, $FDD0, $FDF0, $FDFC,
    $FE00, $FE10, $FE1A, $FE20, $FE30, $FE53, $FE54, $FE62, $FE63, $FE64, $FE67, $FE68,
    $FE69, $FE6A, $FE6C, $FE70, $FE75, $FE76, $FEFD, $FEFF, $FF00, $FF01, $FF04, $FF05,
    $FF0B, $FF0C, $FF10, $FF1A, $FF1C, $FF1F, $FF21, $FF27, $FF3B, $FF3E, $FF3F, $FF40,
    $FF41, $FF47, $FF5B, $FF5C, $FF5D, $FF5E, $FF5F, $FF66, $FFBF, $FFC2, $FFC8, $FFCA,
    $FFD0, $FFD2, $FFD8, $FFDA, $FFDD, $FFE0, $FFE7, $FFE8, $FFEF, $FFF9, $FFFC, $FFFE);
  MaskVal : Array[0..2471] Of Word = (
    $8020, $8068, $8028, $8020, $8848, $8C10, $AC10, $8C10, $AC10, $8C10, $9E84, $8C10,
    $AC10, $8C10, $8F81, $8F01, $8C10, $AC10, $8C10, $AC10, $8F82, $8F02, $8C10, $AC10,
    $8C10, $AC10, $8020, $0020, $0028, $0020, $0848, $0C10, $2C10, $0C10, $2C10, $0F00,
    $0C10, $2C10, $0020, $2C10, $1C10, $2C10, $0F02, $0C10, $2C10, $1C10, $0F00, $0C10,
    $1C10, $0C10, $0F01, $2C10, $0F01, $0F02, $2C10, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F00, $0F01, $0F02, $0F00, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F00, $0F02, $0F00, $2C10, $0F00, $2C10, $0F00, $2C10,
    $0F00, $2C10, $0F00, $2C10, $4C10, $4F02, $4C10, $0F01, $0F02, $0F01, $0F02, $0F00,
    $2C10, $0F01, $0F02, $0000, $0F00, $0F02, $0C10, $0F01, $0000, $2C10, $0F01, $0C10,
    $0F01, $0000, $0F01, $0000, $0F01, $0F02, $0F01, $0000, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $2C10, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $2C10, $4C10, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0000, $0F01, $0000, $0F00, $0C10,
    $0F02, $0C10, $0000, $2C10, $0000, $4C10, $0C10, $4C10, $0C10, $4C10, $0C10, $4C10,
    $0C10, $4C10, $0000, $0F00, $0000, $0F00, $0C10, $0000, $0020, $2C10, $0C10, $2C10,
    $0C10, $2C10, $4C10, $0C10, $0020, $0C10, $0F00, $4C10, $1E04, $0C10, $0F00, $4C10,
    $0F00, $0C10, $0F00, $4C10, $0020, $2C10, $4C10, $0F00, $4C10, $2C10, $4C10, $0F00,
    $1E04, $0F00, $2C10, $0F00, $0C10, $0000, $0020, $0F00, $4C10, $0F00, $4C10, $0000,
    $0F00, $4C10, $0F00, $0000, $1E04, $0F00, $4C10, $0F00, $2C10, $0C10, $0F00, $0000,
    $4C10, $2C10, $0F00, $4C10, $0F00, $4C10, $0F00, $4C10, $0F00, $4C10, $0000, $0C10,
    $0000, $0F00, $4C10, $0000, $0C10, $0000, $0F00, $0000, $0F00, $2C10, $0F00, $0000,
    $0020, $0000, $4C10, $0F00, $4C10, $0020, $4C10, $0F00, $4C10, $0F00, $4C10, $0F00,
    $4C10, $0F00, $4C10, $0C10, $1E04, $0C10, $0F00, $4C10, $0000, $0F00, $0000, $0F00,
    $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $4C10, $0F00, $4C10,
    $0000, $4C10, $0000, $4C10, $0F00, $0000, $4C10, $0000, $0F00, $0000, $0F00, $4C10,
    $0000, $1E04, $0F00, $2C10, $1C10, $2C10, $0F00, $0C10, $4C10, $0000, $4C10, $0000,
    $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000,
    $0F00, $0000, $4C10, $0000, $4C10, $0000, $4C10, $0000, $4C10, $0000, $4C10, $0000,
    $0F00, $0000, $0F00, $0000, $1E04, $4C10, $0F00, $4C10, $0C10, $0000, $4C10, $0000,
    $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000,
    $4C10, $0F00, $4C10, $0000, $4C10, $0000, $4C10, $0000, $0F00, $0000, $0F00, $4C10,
    $0000, $1E04, $0C10, $2C10, $0000, $0F00, $4C10, $0000, $4C10, $0000, $0F00, $0000,
    $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $4C10, $0F00,
    $4C10, $0000, $4C10, $0000, $4C10, $0000, $4C10, $0000, $0F00, $0000, $0F00, $4C10,
    $0000, $1E04, $2C10, $0F00, $1C10, $0000, $4C10, $0F00, $0000, $0F00, $0000, $0F00,
    $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00,
    $0000, $0F00, $0000, $4C10, $0000, $4C10, $0000, $4C10, $0000, $0F00, $0000, $4C10,
    $0000, $1E04, $1C10, $2C10, $0000, $4C10, $0F00, $0000, $0F00, $0000, $0F00, $0000,
    $0F00, $0000, $4C10, $0F00, $4C10, $0000, $4C10, $0000, $4C10, $0000, $4C10, $0000,
    $0F00, $0000, $0F00, $0000, $0F00, $4C10, $0000, $1E04, $0000, $0C10, $1C10, $2C10,
    $0F00, $4C10, $0C10, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00,
    $0000, $4C10, $0F00, $4C10, $0000, $4C10, $0000, $4C10, $0000, $4C10, $0000, $0F00,
    $0000, $0F00, $4C10, $0000, $1E04, $0000, $0F00, $4C10, $0000, $4C10, $0F00, $0000,
    $0F00, $0000, $0F00, $4C10, $0F00, $4C10, $0000, $4C10, $0000, $4C10, $0F00, $2C10,
    $0000, $0F00, $4C10, $1C10, $0F00, $4C10, $0000, $1E04, $1C10, $2C10, $0F00, $0000,
    $4C10, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000,
    $4C10, $0000, $4C10, $0000, $4C10, $0000, $4C10, $0000, $1E04, $0000, $4C10, $0C10,
    $0000, $0F00, $4C10, $0F00, $4C10, $0000, $2C10, $0F00, $4C10, $0C10, $1E04, $0C10,
    $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00,
    $4C10, $0F00, $4C10, $0F00, $0000, $0F00, $0000, $0F00, $0000, $4C10, $0000, $1E04,
    $0000, $0F00, $0000, $0F00, $2C10, $0C10, $2C10, $0C10, $2C10, $4C10, $2C10, $1E04,
    $1C10, $2C10, $4C10, $2C10, $4C10, $2C10, $4C10, $0C10, $4C10, $0F00, $0000, $0F00,
    $0000, $4C10, $0C10, $4C10, $0F00, $4C10, $0000, $4C10, $0000, $2C10, $4C10, $2C10,
    $0000, $2C10, $0C10, $2C10, $0C10, $0000, $0F00, $4C10, $0F00, $1E04, $0C10, $0F00,
    $4C10, $0F00, $4C10, $0F00, $4C10, $0F00, $4C10, $0F00, $4C10, $0F00, $4C10, $0F00,
    $4C10, $1E04, $4C10, $2C10, $0F01, $0000, $0F01, $0000, $0F01, $0000, $0F02, $0C10,
    $0F00, $0F02, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000,
    $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000,
    $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $4C10, $0C10,
    $1C10, $0000, $0F00, $2C10, $0000, $0F01, $0000, $0F02, $0000, $0C10, $0F00, $2C10,
    $0C10, $0F00, $0848, $0F00, $0C10, $0000, $0F00, $0C10, $1F00, $0F00, $0000, $0F00,
    $4C10, $0000, $0F00, $4C10, $0C10, $0000, $0F00, $4C10, $0000, $0F00, $0000, $0F00,
    $0000, $4C10, $0000, $0F00, $4C10, $0C10, $0F00, $0C10, $2C10, $0F00, $4C10, $0000,
    $1E04, $0000, $1C10, $0000, $0C10, $4C10, $0020, $4C10, $1E04, $0000, $0F00, $0000,
    $0F00, $4C10, $0F00, $4C10, $0F00, $0000, $0F00, $0000, $0F00, $0000, $4C10, $0000,
    $4C10, $0000, $2C10, $0000, $0C10, $1E04, $0F00, $0000, $0F00, $0000, $0F00, $0000,
    $0F00, $0000, $1E04, $1C10, $0000, $2C10, $0F00, $4C10, $0000, $0C10, $0F00, $4C10,
    $0000, $4C10, $0000, $4C10, $1E04, $0000, $1E04, $0000, $0C10, $0F00, $0C10, $0000,
    $4C10, $0000, $4C10, $0F00, $4C10, $0F00, $0000, $1E04, $0C10, $2C10, $4C10, $2C10,
    $0C10, $0000, $4C10, $0F00, $4C10, $0F00, $1E04, $0F00, $4C10, $0000, $0C10, $0F00,
    $4C10, $0000, $0C10, $1E04, $0000, $0F00, $1E04, $0F00, $0C10, $0F02, $0000, $0F01,
    $0000, $0F01, $0C10, $0000, $4C10, $0C10, $4C10, $0F00, $4C10, $0F00, $4C10, $0F00,
    $4C10, $0F00, $0000, $0F02, $0F00, $0F02, $0F00, $0F02, $0F00, $4C10, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0000, $0F01, $0000, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0000, $0F01, $0000, $0F02, $0000, $0F01, $0000, $0F01,
    $0000, $0F01, $0000, $0F01, $0F02, $0F01, $0F02, $0000, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0000, $0F02, $0F01, $2C10, $0F02, $2C10, $0F02, $0000, $0F02,
    $0F01, $2C10, $0F02, $0000, $0F02, $0F01, $0000, $2C10, $0F02, $0F01, $2C10, $0000,
    $0F02, $0000, $0F02, $0F01, $2C10, $0000, $0848, $0020, $0C10, $0028, $0020, $0848,
    $0C10, $2C10, $0C10, $2C10, $0C10, $0848, $0020, $0000, $0020, $1C10, $0F00, $0000,
    $1C10, $2C10, $0C10, $0F00, $1C10, $2C10, $0C10, $0000, $0F00, $0000, $2C10, $0000,
    $4C10, $0000, $2C10, $0F01, $2C10, $0F01, $2C10, $0F02, $0F01, $0F02, $0F01, $0F02,
    $2C10, $0F01, $2C10, $0F01, $2C10, $0F01, $2C10, $0F01, $2C10, $0F01, $2C10, $0F01,
    $2C10, $0F02, $0F01, $0F02, $0F00, $0F02, $2C10, $0F02, $0F01, $2C10, $0F01, $0F02,
    $2C10, $0F02, $2C10, $1C10, $1F01, $1F02, $1F00, $0F01, $0F02, $1F00, $1C10, $2C10,
    $0000, $2C10, $0C10, $2C10, $0C10, $2C10, $0000, $2C10, $0000, $1C10, $2C10, $2F01,
    $2F02, $1C10, $2C10, $0C10, $1C10, $2C10, $0C10, $2C10, $0C10, $2C10, $0C10, $2C10,
    $0C10, $2C10, $0C10, $2C10, $0000, $2C10, $0000, $2C10, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F00, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $2C10, $0F01, $0F02, $0F01, $0F02,
    $4C10, $0F01, $0F02, $0000, $0C10, $1C10, $0C10, $0F02, $0000, $0F02, $0000, $0F02,
    $0000, $0F00, $0000, $0F00, $0C10, $0000, $4C10, $0F00, $0000, $0F00, $0000, $0F00,
    $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00,
    $0000, $4C10, $0C10, $0F00, $0C10, $2C10, $0C10, $0000, $2C10, $0000, $2C10, $0000,
    $2C10, $0000, $2C10, $0848, $0C10, $2C10, $0F00, $1F00, $0C10, $2C10, $0C10, $2C10,
    $1F00, $4C10, $0C10, $0F00, $2C10, $1F00, $0F00, $0C10, $2C10, $0000, $0F00, $0000,
    $4C10, $2C10, $0F00, $0C10, $0F00, $0C10, $0F00, $0000, $0F00, $0000, $0F00, $0000,
    $2C10, $1C10, $2C10, $0F00, $2C10, $0000, $2C10, $0F00, $2C10, $0000, $1C10, $2C10,
    $1C10, $2C10, $1C10, $2C10, $1C10, $2C10, $1C10, $2C10, $0F00, $2C10, $0F00, $0000,
    $2C10, $0000, $0F00, $0C10, $0F00, $0C10, $0F00, $1E04, $0F00, $0000, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F00, $4C10, $0C10, $4C10,
    $0C10, $0F00, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F00, $4C10, $0F00, $1F00, $4C10, $0C10,
    $0000, $2C10, $0F00, $2C10, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F00, $0F02, $0F01, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02,
    $0F00, $2C10, $0F01, $0F02, $0F01, $0F02, $0F00, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01, $0F02, $0F01,
    $0F02, $0F01, $0F02, $0F01, $0F02, $0000, $0F01, $0F02, $0000, $0F02, $0000, $0F02,
    $0F01, $0F02, $0F01, $0F02, $0000, $0F00, $0F01, $0F02, $0F00, $0F02, $0F00, $4C10,
    $0F00, $4C10, $0F00, $4C10, $0F00, $4C10, $2C10, $4C10, $0000, $1C10, $2C10, $0000,
    $0F00, $0C10, $0000, $4C10, $0F00, $4C10, $0000, $0C10, $1E04, $0000, $4C10, $0F00,
    $0C10, $0F00, $0C10, $0F00, $4C10, $1E04, $0F00, $4C10, $0C10, $0F00, $4C10, $0000,
    $0C10, $0F00, $0000, $4C10, $0F00, $4C10, $0C10, $0000, $0F00, $1E04, $0000, $0C10,
    $0F00, $4C10, $0F00, $1E04, $0F00, $0000, $0F00, $4C10, $0000, $0F00, $4C10, $0F00,
    $4C10, $0000, $1E04, $0000, $0C10, $0F00, $2C10, $0F00, $4C10, $0F00, $4C10, $0F00,
    $4C10, $0F00, $4C10, $0F00, $4C10, $0F00, $4C10, $0F00, $0000, $0F00, $0C10, $0F00,
    $4C10, $0C10, $0F00, $4C10, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00,
    $0000, $0F00, $0000, $0F02, $2C10, $0F00, $0F02, $0F00, $2C10, $0000, $0F02, $0F00,
    $4C10, $0C10, $4C10, $0000, $1E04, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000,
    $0F00, $0000, $0F00, $0000, $0F02, $0000, $0F02, $0000, $0F00, $4C10, $0F00, $2C10,
    $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $0000, $0F00, $2C10,
    $0000, $0F00, $0C10, $2C10, $0F00, $0000, $0F00, $0000, $2C10, $0000, $0F00, $2C10,
    $4C10, $0C10, $0000, $4C10, $0C10, $0000, $0C10, $2C10, $0C10, $2C10, $0000, $0C10,
    $2C10, $0C10, $0000, $0F00, $0000, $0F00, $0000, $0020, $0000, $0C10, $2C10, $0C10,
    $2C10, $0C10, $1E84, $0C10, $2C10, $0C10, $0F81, $0F01, $0C10, $2C10, $0C10, $2C10,
    $0F82, $0F02, $0C10, $2C10, $0C10, $2C10, $0C10, $0F00, $0000, $0F00, $0000, $0F00,
    $0000, $0F00, $0000, $0F00, $0000, $2C10, $0000, $2C10, $0000, $0020, $2C10, $0000);
  { classes bidirectionnelles (1 L, 2 R/AL, 3 EN, 4 ES, 5 ET, 6 AN, 7 CS, 8 B, 9 S, 10 WS, 11 ON, 0 autre) }
  BidiStart : Array[0..1149] Of Word = (
    $0000, $0009, $000A, $000B, $000C, $000D, $000E, $001C, $001F, $0020, $0021, $0023,
    $0026, $002B, $002C, $002D, $002E, $0030, $003A, $003B, $0041, $005B, $0061, $007B,
    $007F, $0085, $0086, $00A0, $00A1, $00A2, $00A6, $00AA, $00AB, $00AD, $00AE, $00B0,
    $00B2, $00B4, $00B5, $00B6, $00B9, $00BA, $00BB, $00C0, $00D7, $00D8, $00F7, $00F8,
    $02B9, $02BB, $02C2, $02D0, $02D2, $02E0, $02E5, $02EE, $02EF, $0300, $0370, $0374,
    $0376, $0378, $037A, $037E, $037F, $0380, $0384, $0386, $0387, $0388, $038B, $038C,
    $038D, $038E, $03A2, $03A3, $03F6, $03F7, $0483, $048A, $0530, $0531, $0557, $0559,
    $058A, $058B, $058D, $058F, $0590, $05BE, $05BF, $05C0, $05C1, $05C3, $05C4, $05C6,
    $05C7, $05D0, $05EB, $05EF, $05F5, $0600, $0606, $0608, $0609, $060B, $060C, $060D,
    $060E, $0610, $061B, $064B, $0660, $066A, $066B, $066D, $0670, $0671, $06D6, $06DD,
    $06DE, $06DF, $06E5, $06E7, $06E9, $06EA, $06EE, $06F0, $06FA, $070E, $070F, $0711,
    $0712, $0730, $074D, $07A6, $07B1, $07B2, $07C0, $07EB, $07F4, $07F6, $07FA, $07FB,
    $07FE, $0816, $081A, $081B, $0824, $0825, $0828, $0829, $0830, $083F, $0840, $0859,
    $085E, $085F, $0860, $086B, $0870, $088F, $0890, $0892, $08A0, $08CA, $08E2, $08E3,
    $0903, $093A, $093B, $093C, $093D, $0941, $0949, $094D, $094E, $0951, $0958, $0962,
    $0964, $0981, $0982, $0984, $0985, $098D, $098F, $0991, $0993, $09A9, $09AA, $09B1,
    $09B2, $09B3, $09B6, $09BA, $09BD, $09C1, $09C7, $09C9, $09CB, $09CD, $09CE, $09CF,
    $09D7, $09D8, $09DC, $09DE, $09DF, $09E2, $09E6, $09F2, $09F4, $09FB, $09FC, $09FE,
    $0A03, $0A04, $0A05, $0A0B, $0A0F, $0A11, $0A13, $0A29, $0A2A, $0A31, $0A32, $0A34,
    $0A35, $0A37, $0A38, $0A3A, $0A3E, $0A41, $0A59, $0A5D, $0A5E, $0A5F, $0A66, $0A70,
    $0A72, $0A75, $0A76, $0A77, $0A83, $0A84, $0A85, $0A8E, $0A8F, $0A92, $0A93, $0AA9,
    $0AAA, $0AB1, $0AB2, $0AB4, $0AB5, $0ABA, $0ABD, $0AC1, $0AC9, $0ACA, $0ACB, $0ACD,
    $0AD0, $0AD1, $0AE0, $0AE2, $0AE6, $0AF1, $0AF2, $0AF9, $0AFA, $0B02, $0B04, $0B05,
    $0B0D, $0B0F, $0B11, $0B13, $0B29, $0B2A, $0B31, $0B32, $0B34, $0B35, $0B3A, $0B3D,
    $0B3F, $0B40, $0B41, $0B47, $0B49, $0B4B, $0B4D, $0B57, $0B58, $0B5C, $0B5E, $0B5F,
    $0B62, $0B66, $0B78, $0B83, $0B84, $0B85, $0B8B, $0B8E, $0B91, $0B92, $0B96, $0B99,
    $0B9B, $0B9C, $0B9D, $0B9E, $0BA0, $0BA3, $0BA5, $0BA8, $0BAB, $0BAE, $0BBA, $0BBE,
    $0BC0, $0BC1, $0BC3, $0BC6, $0BC9, $0BCA, $0BCD, $0BD0, $0BD1, $0BD7, $0BD8, $0BE6,
    $0BF3, $0BF9, $0BFA, $0BFB, $0C01, $0C04, $0C05, $0C0D, $0C0E, $0C11, $0C12, $0C29,
    $0C2A, $0C3A, $0C3D, $0C3E, $0C41, $0C45, $0C58, $0C5B, $0C5D, $0C5E, $0C60, $0C62,
    $0C66, $0C70, $0C77, $0C78, $0C7F, $0C81, $0C82, $0C8D, $0C8E, $0C91, $0C92, $0CA9,
    $0CAA, $0CB4, $0CB5, $0CBA, $0CBD, $0CC5, $0CC6, $0CC9, $0CCA, $0CCC, $0CD5, $0CD7,
    $0CDD, $0CDF, $0CE0, $0CE2, $0CE6, $0CF0, $0CF1, $0CF4, $0D02, $0D0D, $0D0E, $0D11,
    $0D12, $0D3B, $0D3D, $0D41, $0D46, $0D49, $0D4A, $0D4D, $0D4E, $0D50, $0D54, $0D62,
    $0D66, $0D80, $0D82, $0D84, $0D85, $0D97, $0D9A, $0DB2, $0DB3, $0DBC, $0DBD, $0DBE,
    $0DC0, $0DC7, $0DCF, $0DD2, $0DD8, $0DE0, $0DE6, $0DF0, $0DF2, $0DF5, $0E01, $0E31,
    $0E32, $0E34, $0E3F, $0E40, $0E47, $0E4F, $0E5C, $0E81, $0E83, $0E84, $0E85, $0E86,
    $0E8B, $0E8C, $0EA4, $0EA5, $0EA6, $0EA7, $0EB1, $0EB2, $0EB4, $0EBD, $0EBE, $0EC0,
    $0EC5, $0EC6, $0EC7, $0ED0, $0EDA, $0EDC, $0EE0, $0F00, $0F18, $0F1A, $0F35, $0F36,
    $0F37, $0F38, $0F39, $0F3A, $0F3E, $0F48, $0F49, $0F6D, $0F7F, $0F80, $0F85, $0F86,
    $0F88, $0F8D, $0FBE, $0FC6, $0FC7, $0FCD, $0FCE, $0FDB, $1000, $102D, $1031, $1032,
    $1038, $1039, $103B, $103D, $103F, $1058, $105A, $105E, $1061, $1071, $1075, $1082,
    $1083, $1085, $1087, $108D, $108E, $109D, $109E, $10C6, $10C7, $10C8, $10CD, $10CE,
    $10D0, $1249, $124A, $124E, $1250, $1257, $1258, $1259, $125A, $125E, $1260, $1289,
    $128A, $128E, $1290, $12B1, $12B2, $12B6, $12B8, $12BF, $12C0, $12C1, $12C2, $12C6,
    $12C8, $12D7, $12D8, $1311, $1312, $1316, $1318, $135B, $1360, $137D, $1380, $1390,
    $139A, $13A0, $13F6, $13F8, $13FE, $1400, $1401, $1680, $1681, $169B, $169D, $16A0,
    $16F9, $1700, $1712, $1715, $1716, $171F, $1732, $1734, $1737, $1740, $1752, $1760,
    $176D, $176E, $1771, $1780, $17B4, $17B6, $17B7, $17BE, $17C6, $17C7, $17C9, $17D4,
    $17DB, $17DC, $17DD, $17E0, $17EA, $17F0, $17FA, $1800, $180B, $1810, $181A, $1820,
    $1879, $1880, $1885, $1887, $18A9, $18AA, $18AB, $18B0, $18F6, $1900, $191F, $1923,
    $1927, $1929, $192C, $1930, $1932, $1933, $1939, $1940, $1941, $1944, $1946, $196E,
    $1970, $1975, $1980, $19AC, $19B0, $19CA, $19D0, $19DB, $19DE, $1A00, $1A17, $1A19,
    $1A1B, $1A1E, $1A56, $1A57, $1A58, $1A61, $1A62, $1A63, $1A65, $1A6D, $1A73, $1A80,
    $1A8A, $1A90, $1A9A, $1AA0, $1AAE, $1B04, $1B34, $1B35, $1B36, $1B3B, $1B3C, $1B3D,
    $1B42, $1B43, $1B4D, $1B50, $1B6B, $1B74, $1B7F, $1B82, $1BA2, $1BA6, $1BA8, $1BAA,
    $1BAB, $1BAE, $1BE6, $1BE7, $1BE8, $1BEA, $1BED, $1BEE, $1BEF, $1BF2, $1BF4, $1BFC,
    $1C2C, $1C34, $1C36, $1C3B, $1C4A, $1C4D, $1C89, $1C90, $1CBB, $1CBD, $1CC8, $1CD3,
    $1CD4, $1CE1, $1CE2, $1CE9, $1CED, $1CEE, $1CF4, $1CF5, $1CF8, $1CFA, $1CFB, $1D00,
    $1DC0, $1E00, $1F16, $1F18, $1F1E, $1F20, $1F46, $1F48, $1F4E, $1F50, $1F58, $1F59,
    $1F5A, $1F5B, $1F5C, $1F5D, $1F5E, $1F5F, $1F7E, $1F80, $1FB5, $1FB6, $1FBD, $1FBE,
    $1FBF, $1FC2, $1FC5, $1FC6, $1FCD, $1FD0, $1FD4, $1FD6, $1FDC, $1FDD, $1FE0, $1FED,
    $1FF0, $1FF2, $1FF5, $1FF6, $1FFD, $1FFF, $2000, $200B, $200E, $200F, $2010, $2028,
    $2029, $202A, $202F, $2030, $2035, $2044, $2045, $205F, $2060, $2070, $2071, $2072,
    $2074, $207A, $207C, $207F, $2080, $208A, $208C, $208F, $2090, $209D, $20A0, $20C1,
    $2100, $2102, $2103, $2107, $2108, $210A, $2114, $2115, $2116, $2119, $211E, $2124,
    $2125, $2126, $2127, $2128, $2129, $212A, $212E, $212F, $213A, $213C, $2140, $2145,
    $214A, $214E, $2150, $2160, $2189, $218C, $2190, $2212, $2213, $2214, $2336, $237B,
    $2395, $2396, $2427, $2440, $244B, $2460, $2488, $249C, $24EA, $26AC, $26AD, $2800,
    $2900, $2B74, $2B76, $2B96, $2B97, $2C00, $2CE5, $2CEB, $2CEF, $2CF2, $2CF4, $2CF9,
    $2D00, $2D26, $2D27, $2D28, $2D2D, $2D2E, $2D30, $2D68, $2D6F, $2D71, $2D80, $2D97,
    $2DA0, $2DA7, $2DA8, $2DAF, $2DB0, $2DB7, $2DB8, $2DBF, $2DC0, $2DC7, $2DC8, $2DCF,
    $2DD0, $2DD7, $2DD8, $2DDF, $2E00, $2E5E, $2E80, $2E9A, $2E9B, $2EF4, $2F00, $2FD6,
    $2FF0, $3000, $3001, $3005, $3008, $3021, $302A, $302E, $3030, $3031, $3036, $3038,
    $303D, $3040, $3041, $3097, $309B, $309D, $30A0, $30A1, $30FB, $30FC, $3100, $3105,
    $3130, $3131, $318F, $3190, $31C0, $31E4, $31EF, $31F0, $321D, $321F, $3220, $3250,
    $3260, $327C, $327F, $32B1, $32C0, $32CC, $32D0, $3377, $337B, $33DE, $33E0, $33FF,
    $3400, $4DC0, $4E00, $A48D, $A490, $A4C7, $A4D0, $A60D, $A610, $A62C, $A640, $A66F,
    $A673, $A674, $A67E, $A680, $A69E, $A6A0, $A6F0, $A6F2, $A6F8, $A700, $A722, $A788,
    $A789, $A7CB, $A7D0, $A7D2, $A7D3, $A7D4, $A7D5, $A7DA, $A7F2, $A802, $A803, $A806,
    $A807, $A80B, $A80C, $A825, $A827, $A828, $A82C, $A830, $A838, $A83A, $A840, $A874,
    $A878, $A880, $A8C4, $A8CE, $A8DA, $A8F2, $A8FF, $A900, $A926, $A92E, $A947, $A952,
    $A954, $A95F, $A97D, $A983, $A9B3, $A9B4, $A9B6, $A9BA, $A9BC, $A9BE, $A9CE, $A9CF,
    $A9DA, $A9DE, $A9E5, $A9E6, $A9FF, $AA00, $AA29, $AA2F, $AA31, $AA33, $AA35, $AA40,
    $AA43, $AA44, $AA4C, $AA4D, $AA4E, $AA50, $AA5A, $AA5C, $AA7C, $AA7D, $AAB0, $AAB1,
    $AAB2, $AAB5, $AAB7, $AAB9, $AABE, $AAC0, $AAC1, $AAC2, $AAC3, $AADB, $AAEC, $AAEE,
    $AAF6, $AB01, $AB07, $AB09, $AB0F, $AB11, $AB17, $AB20, $AB27, $AB28, $AB2F, $AB30,
    $AB6A, $AB6C, $AB70, $ABE5, $ABE6, $ABE8, $ABE9, $ABED, $ABF0, $ABFA, $AC00, $D7A4,
    $D7B0, $D7C7, $D7CB, $D7FC, $E000, $FA6E, $FA70, $FADA, $FB00, $FB07, $FB13, $FB18,
    $FB1D, $FB1E, $FB1F, $FB29, $FB2A, $FB37, $FB38, $FB3D, $FB3E, $FB3F, $FB40, $FB42,
    $FB43, $FB45, $FB46, $FBC3, $FBD3, $FD3E, $FD50, $FD90, $FD92, $FDC8, $FDCF, $FDD0,
    $FDF0, $FDFD, $FE00, $FE10, $FE1A, $FE30, $FE50, $FE51, $FE52, $FE53, $FE54, $FE55,
    $FE56, $FE5F, $FE60, $FE62, $FE64, $FE67, $FE68, $FE69, $FE6B, $FE6C, $FE70, $FE75,
    $FE76, $FEFD, $FF01, $FF03, $FF06, $FF0B, $FF0C, $FF0D, $FF0E, $FF10, $FF1A, $FF1B,
    $FF21, $FF3B, $FF41, $FF5B, $FF66, $FFBF, $FFC2, $FFC8, $FFCA, $FFD0, $FFD2, $FFD8,
    $FFDA, $FFDD, $FFE0, $FFE2, $FFE5, $FFE7, $FFE8, $FFEF, $FFF9, $FFFE);
  BidiVal : Array[0..1149] Of Word = (
    $0000, $0009, $0008, $0009, $000A, $0008, $0000, $0008, $0009, $000A, $000B, $0005,
    $000B, $0004, $0007, $0004, $0007, $0003, $0007, $000B, $0001, $000B, $0001, $000B,
    $0000, $0008, $0000, $0007, $000B, $0005, $000B, $0001, $000B, $0000, $000B, $0005,
    $0003, $000B, $0001, $000B, $0003, $0001, $000B, $0001, $000B, $0001, $000B, $0001,
    $000B, $0001, $000B, $0001, $000B, $0001, $000B, $0001, $000B, $0000, $0001, $000B,
    $0001, $0000, $0001, $000B, $0001, $0000, $000B, $0001, $000B, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $000B, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $000B, $0000, $000B, $0005, $0000, $0002, $0000, $0002, $0000, $0002, $0000, $0002,
    $0000, $0002, $0000, $0002, $0000, $0006, $000B, $0002, $0005, $0002, $0007, $0002,
    $000B, $0000, $0002, $0000, $0006, $0005, $0006, $0002, $0000, $0002, $0000, $0006,
    $000B, $0000, $0002, $0000, $000B, $0000, $0002, $0003, $0002, $0000, $0002, $0000,
    $0002, $0000, $0002, $0000, $0002, $0000, $0002, $0000, $0002, $000B, $0002, $0000,
    $0002, $0000, $0002, $0000, $0002, $0000, $0002, $0000, $0002, $0000, $0002, $0000,
    $0002, $0000, $0002, $0000, $0002, $0000, $0006, $0000, $0002, $0000, $0006, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0005, $0001, $0005, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0005, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $000B, $0005, $000B, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $000B, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0005, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $000B, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $000B,
    $0000, $0001, $0000, $0001, $0000, $000B, $0001, $000A, $0001, $000B, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0005, $0001, $0000, $0001, $0000, $000B, $0000, $000B, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $000B, $0000, $000B, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $000B, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $000B, $0001,
    $000B, $0001, $0000, $0001, $000B, $0001, $0000, $0001, $0000, $000B, $0001, $000B,
    $0000, $0001, $0000, $0001, $000B, $0000, $000A, $0000, $0001, $0002, $000B, $000A,
    $0008, $0000, $0007, $0005, $000B, $0007, $000B, $000A, $0000, $0003, $0001, $0000,
    $0003, $0004, $000B, $0001, $0003, $0004, $000B, $0000, $0001, $0000, $0005, $0000,
    $000B, $0001, $000B, $0001, $000B, $0001, $000B, $0001, $000B, $0001, $000B, $0001,
    $000B, $0001, $000B, $0001, $000B, $0001, $0005, $0001, $000B, $0001, $000B, $0001,
    $000B, $0001, $000B, $0001, $000B, $0000, $000B, $0004, $0005, $000B, $0001, $000B,
    $0001, $000B, $0000, $000B, $0000, $000B, $0003, $0001, $000B, $0001, $000B, $0001,
    $000B, $0000, $000B, $0000, $000B, $0001, $000B, $0001, $0000, $0001, $0000, $000B,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $000B, $0000, $000B, $0000, $000B, $0000, $000B, $0000,
    $000B, $000A, $000B, $0001, $000B, $0001, $0000, $0001, $000B, $0001, $000B, $0001,
    $000B, $0000, $0001, $0000, $000B, $0001, $000B, $0001, $000B, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $000B, $0000, $000B, $0001, $000B, $0000, $0001, $000B,
    $0001, $000B, $0001, $000B, $0001, $000B, $0001, $000B, $0001, $000B, $0001, $000B,
    $0001, $000B, $0001, $0000, $000B, $0000, $0001, $000B, $0001, $0000, $0001, $0000,
    $000B, $0000, $000B, $0001, $0000, $0001, $0000, $0001, $0000, $000B, $0001, $000B,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $000B, $0000, $0001, $0005, $0000, $0001, $000B,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001,
    $000B, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0002, $0000, $0002, $0004, $0002, $0000, $0002, $0000, $0002, $0000, $0002, $0000,
    $0002, $0000, $0002, $0000, $0002, $000B, $0002, $0000, $0002, $0000, $000B, $0000,
    $0002, $000B, $0000, $000B, $0000, $000B, $0007, $000B, $0007, $0000, $000B, $0007,
    $000B, $0005, $000B, $0004, $000B, $0000, $000B, $0005, $000B, $0000, $0002, $0000,
    $0002, $0000, $000B, $0005, $000B, $0004, $0007, $0004, $0007, $0003, $0007, $000B,
    $0001, $000B, $0001, $000B, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0005, $000B, $0005, $0000, $000B, $0000, $000B, $0000);
  { majuscules : caracteres Debut..Fin (de Pas en Pas) -> caractere + Ecart }
  UpFirst : Array[0..183] Of Word = (
    $0061, $00B5, $00E0, $00F8, $00FF, $0101, $0131, $0133, $013A, $014B, $017A, $017F,
    $0180, $0183, $0188, $018C, $0192, $0195, $0199, $019A, $019E, $01A1, $01A8, $01AD,
    $01B0, $01B4, $01B9, $01BD, $01BF, $01C5, $01C6, $01C8, $01C9, $01CB, $01CC, $01CE,
    $01DD, $01DF, $01F2, $01F3, $01F5, $01F9, $0223, $023C, $023F, $0242, $0247, $0250,
    $0251, $0252, $0253, $0254, $0256, $0259, $025B, $025C, $0260, $0261, $0263, $0265,
    $0266, $0268, $0269, $026A, $026B, $026C, $026F, $0271, $0272, $0275, $027D, $0280,
    $0282, $0283, $0287, $0288, $0289, $028A, $028C, $0292, $029D, $029E, $0345, $0371,
    $0377, $037B, $03AC, $03AD, $03B1, $03C2, $03C3, $03CC, $03CD, $03D0, $03D1, $03D5,
    $03D6, $03D7, $03D9, $03F0, $03F1, $03F2, $03F3, $03F5, $03F8, $03FB, $0430, $0450,
    $0461, $048B, $04C2, $04CF, $04D1, $0561, $10D0, $10FD, $13F8, $1C80, $1C81, $1C82,
    $1C83, $1C85, $1C86, $1C87, $1C88, $1D79, $1D7D, $1D8E, $1E01, $1E9B, $1EA1, $1F00,
    $1F10, $1F20, $1F30, $1F40, $1F51, $1F60, $1F70, $1F72, $1F76, $1F78, $1F7A, $1F7C,
    $1FB0, $1FBE, $1FD0, $1FE0, $1FE5, $214E, $2170, $2184, $24D0, $2C30, $2C61, $2C65,
    $2C66, $2C68, $2C73, $2C76, $2C81, $2CEC, $2CF3, $2D00, $2D27, $2D2D, $A641, $A681,
    $A723, $A733, $A77A, $A77F, $A78C, $A791, $A794, $A797, $A7B5, $A7C8, $A7D1, $A7D7,
    $A7F6, $AB53, $AB70, $FF41);
  UpLast : Array[0..183] Of Word = (
    $007A, $00B5, $00F6, $00FE, $00FF, $012F, $0131, $0137, $0148, $0177, $017E, $017F,
    $0180, $0185, $0188, $018C, $0192, $0195, $0199, $019A, $019E, $01A5, $01A8, $01AD,
    $01B0, $01B6, $01B9, $01BD, $01BF, $01C5, $01C6, $01C8, $01C9, $01CB, $01CC, $01DC,
    $01DD, $01EF, $01F2, $01F3, $01F5, $021F, $0233, $023C, $0240, $0242, $024F, $0250,
    $0251, $0252, $0253, $0254, $0257, $0259, $025B, $025C, $0260, $0261, $0263, $0265,
    $0266, $0268, $0269, $026A, $026B, $026C, $026F, $0271, $0272, $0275, $027D, $0280,
    $0282, $0283, $0287, $0288, $0289, $028B, $028C, $0292, $029D, $029E, $0345, $0373,
    $0377, $037D, $03AC, $03AF, $03C1, $03C2, $03CB, $03CC, $03CE, $03D0, $03D1, $03D5,
    $03D6, $03D7, $03EF, $03F0, $03F1, $03F2, $03F3, $03F5, $03F8, $03FB, $044F, $045F,
    $0481, $04BF, $04CE, $04CF, $052F, $0586, $10FA, $10FF, $13FD, $1C80, $1C81, $1C82,
    $1C84, $1C85, $1C86, $1C87, $1C88, $1D79, $1D7D, $1D8E, $1E95, $1E9B, $1EFF, $1F07,
    $1F15, $1F27, $1F37, $1F45, $1F57, $1F67, $1F71, $1F75, $1F77, $1F79, $1F7B, $1F7D,
    $1FB1, $1FBE, $1FD1, $1FE1, $1FE5, $214E, $217F, $2184, $24E9, $2C5F, $2C61, $2C65,
    $2C66, $2C6C, $2C73, $2C76, $2CE3, $2CEE, $2CF3, $2D25, $2D27, $2D2D, $A66D, $A69B,
    $A72F, $A76F, $A77C, $A787, $A78C, $A793, $A794, $A7A9, $A7C3, $A7CA, $A7D1, $A7D9,
    $A7F6, $AB53, $ABBF, $FF5A);
  UpDelta : Array[0..183] Of LongInt = (
    -32, 743, -32, -32, 121, -1, -232, -1, -1, -1, -1, -300,
    195, -1, -1, -1, -1, 97, -1, 163, 130, -1, -1, -1,
    -1, -1, -1, -1, 56, -1, -2, -1, -2, -1, -2, -1,
    -79, -1, -1, -2, -1, -1, -1, -1, 10815, -1, -1, 10783,
    10780, 10782, -210, -206, -205, -202, -203, 42319, -205, 42315, -207, 42280,
    42308, -209, -211, 42308, 10743, 42305, -211, 10749, -213, -214, 10727, -218,
    42307, -218, 42282, -218, -69, -217, -71, -219, 42261, 42258, 84, -1,
    -1, 130, -38, -37, -32, -31, -32, -64, -63, -62, -57, -47,
    -54, -8, -1, -86, -80, 7, -116, -96, -1, -1, -32, -80,
    -1, -1, -1, -15, -1, -48, 3008, 3008, -8, -6254, -6253, -6244,
    -6242, -6243, -6236, -6181, 35266, 35332, 3814, 35384, -1, -59, -1, 8,
    8, 8, 8, 8, 8, 8, 74, 86, 100, 128, 112, 126,
    8, -7205, 8, 8, 7, -28, -16, -1, -26, -48, -1, -10795,
    -10792, -1, -1, -1, -1, -1, -1, -7264, -7264, -7264, -1, -1,
    -1, -1, -1, -1, -1, -1, 48, -1, -1, -1, -1, -1,
    -1, -928, -38864, -32);
  UpStep : Array[0..183] Of Word = (
    $0001, $0001, $0001, $0001, $0001, $0002, $0001, $0002, $0002, $0002, $0002, $0001,
    $0001, $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002, $0001, $0001,
    $0001, $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002,
    $0001, $0002, $0001, $0001, $0001, $0002, $0002, $0001, $0001, $0001, $0002, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0002, $0002, $0002, $0001, $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002, $0001, $0002, $0001,
    $0001, $0001, $0001, $0001, $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0002, $0001, $0001, $0002, $0002, $0001, $0001, $0001, $0001, $0002, $0002,
    $0002, $0002, $0002, $0002, $0001, $0002, $0001, $0002, $0002, $0002, $0001, $0002,
    $0001, $0001, $0001, $0001);
  { minuscules }
  LowFirst : Array[0..170] Of Word = (
    $0041, $00C0, $00D8, $0100, $0132, $0139, $014A, $0178, $0179, $0181, $0182, $0186,
    $0187, $0189, $018B, $018E, $018F, $0190, $0191, $0193, $0194, $0196, $0197, $0198,
    $019C, $019D, $019F, $01A0, $01A6, $01A7, $01A9, $01AC, $01AE, $01AF, $01B1, $01B3,
    $01B7, $01B8, $01BC, $01C4, $01C5, $01C7, $01C8, $01CA, $01CB, $01DE, $01F1, $01F2,
    $01F6, $01F7, $01F8, $0220, $0222, $023A, $023B, $023D, $023E, $0241, $0243, $0244,
    $0245, $0246, $0370, $0376, $037F, $0386, $0388, $038C, $038E, $0391, $03A3, $03CF,
    $03D8, $03F4, $03F7, $03F9, $03FA, $03FD, $0400, $0410, $0460, $048A, $04C0, $04C1,
    $04D0, $0531, $10A0, $10C7, $10CD, $13A0, $13F0, $1C90, $1CBD, $1E00, $1E9E, $1EA0,
    $1F08, $1F18, $1F28, $1F38, $1F48, $1F59, $1F68, $1F88, $1F98, $1FA8, $1FB8, $1FBA,
    $1FBC, $1FC8, $1FCC, $1FD8, $1FDA, $1FE8, $1FEA, $1FEC, $1FF8, $1FFA, $1FFC, $2126,
    $212A, $212B, $2132, $2160, $2183, $24B6, $2C00, $2C60, $2C62, $2C63, $2C64, $2C67,
    $2C6D, $2C6E, $2C6F, $2C70, $2C72, $2C75, $2C7E, $2C80, $2CEB, $2CF2, $A640, $A680,
    $A722, $A732, $A779, $A77D, $A77E, $A78B, $A78D, $A790, $A796, $A7AA, $A7AB, $A7AC,
    $A7AD, $A7AE, $A7B0, $A7B1, $A7B2, $A7B3, $A7B4, $A7C4, $A7C5, $A7C6, $A7C7, $A7D0,
    $A7D6, $A7F5, $FF21);
  LowLast : Array[0..170] Of Word = (
    $005A, $00D6, $00DE, $012E, $0136, $0147, $0176, $0178, $017D, $0181, $0184, $0186,
    $0187, $018A, $018B, $018E, $018F, $0190, $0191, $0193, $0194, $0196, $0197, $0198,
    $019C, $019D, $019F, $01A4, $01A6, $01A7, $01A9, $01AC, $01AE, $01AF, $01B2, $01B5,
    $01B7, $01B8, $01BC, $01C4, $01C5, $01C7, $01C8, $01CA, $01DB, $01EE, $01F1, $01F4,
    $01F6, $01F7, $021E, $0220, $0232, $023A, $023B, $023D, $023E, $0241, $0243, $0244,
    $0245, $024E, $0372, $0376, $037F, $0386, $038A, $038C, $038F, $03A1, $03AB, $03CF,
    $03EE, $03F4, $03F7, $03F9, $03FA, $03FF, $040F, $042F, $0480, $04BE, $04C0, $04CD,
    $052E, $0556, $10C5, $10C7, $10CD, $13EF, $13F5, $1CBA, $1CBF, $1E94, $1E9E, $1EFE,
    $1F0F, $1F1D, $1F2F, $1F3F, $1F4D, $1F5F, $1F6F, $1F8F, $1F9F, $1FAF, $1FB9, $1FBB,
    $1FBC, $1FCB, $1FCC, $1FD9, $1FDB, $1FE9, $1FEB, $1FEC, $1FF9, $1FFB, $1FFC, $2126,
    $212A, $212B, $2132, $216F, $2183, $24CF, $2C2F, $2C60, $2C62, $2C63, $2C64, $2C6B,
    $2C6D, $2C6E, $2C6F, $2C70, $2C72, $2C75, $2C7F, $2CE2, $2CED, $2CF2, $A66C, $A69A,
    $A72E, $A76E, $A77B, $A77D, $A786, $A78B, $A78D, $A792, $A7A8, $A7AA, $A7AB, $A7AC,
    $A7AD, $A7AE, $A7B0, $A7B1, $A7B2, $A7B3, $A7C2, $A7C4, $A7C5, $A7C6, $A7C9, $A7D0,
    $A7D8, $A7F5, $FF3A);
  LowDelta : Array[0..170] Of LongInt = (
    32, 32, 32, 1, 1, 1, 1, -121, 1, 210, 1, 206,
    1, 205, 1, 79, 202, 203, 1, 205, 207, 211, 209, 1,
    211, 213, 214, 1, 218, 1, 218, 1, 218, 1, 217, 1,
    219, 1, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1,
    -97, -56, 1, -130, 1, 10795, 1, -163, 10792, 1, -195, 69,
    71, 1, 1, 1, 116, 38, 37, 64, 63, 32, 32, 8,
    1, -60, 1, -7, 1, -130, 80, 32, 1, 1, 15, 1,
    1, 48, 7264, 7264, 7264, 38864, 8, -3008, -3008, 1, -7615, 1,
    -8, -8, -8, -8, -8, -8, -8, -8, -8, -8, -8, -74,
    -9, -86, -9, -8, -100, -8, -112, -7, -128, -126, -9, -7517,
    -8383, -8262, 28, 16, 1, 26, 48, 1, -10743, -3814, -10727, 1,
    -10780, -10749, -10783, -10782, 1, 1, -10815, 1, 1, 1, 1, 1,
    1, 1, 1, -35332, 1, 1, -42280, 1, 1, -42308, -42319, -42315,
    -42305, -42308, -42258, -42282, -42261, 928, 1, -48, -42307, -35384, 1, 1,
    1, 1, 32);
  LowStep : Array[0..170] Of Word = (
    $0001, $0001, $0001, $0002, $0002, $0002, $0002, $0001, $0002, $0001, $0002, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002, $0002, $0001, $0002,
    $0001, $0001, $0002, $0001, $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0002, $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002, $0002, $0001, $0002,
    $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002, $0001, $0002,
    $0001, $0001, $0001, $0001, $0001, $0002, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002, $0002, $0001, $0002, $0002,
    $0002, $0002, $0002, $0001, $0002, $0001, $0001, $0002, $0002, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0002, $0001, $0001, $0001, $0002, $0001,
    $0002, $0001, $0001);
  { valeurs numeriques entieres : Debut..Fin -> Valeur, Valeur + 1, ... }
  NumFirst : Array[0..180] Of Word = (
    $0030, $00B2, $00B9, $0660, $06F0, $07C0, $0966, $09E6, $09F9, $0A66, $0AE6, $0B66,
    $0BE6, $0BF1, $0BF2, $0C66, $0C78, $0C7C, $0CE6, $0D66, $0D71, $0D72, $0DE6, $0E50,
    $0ED0, $0F20, $1040, $1090, $1369, $1373, $1374, $1375, $1376, $1377, $1378, $1379,
    $137A, $137B, $137C, $16EE, $17E0, $17F0, $1810, $1946, $19D0, $19DA, $1A80, $1A90,
    $1B50, $1BB0, $1C40, $1C50, $2070, $2074, $2080, $215F, $2160, $216C, $216D, $216E,
    $216F, $2170, $217C, $217D, $217E, $217F, $2180, $2181, $2182, $2185, $2186, $2187,
    $2188, $2189, $2460, $2474, $2488, $24EA, $24EB, $24F5, $24FF, $2776, $2780, $278A,
    $3007, $3021, $3038, $3039, $303A, $3192, $3220, $3248, $3249, $324A, $324B, $324C,
    $324D, $324E, $324F, $3251, $3280, $32B1, $3405, $3483, $382A, $3B4D, $4E00, $4E03,
    $4E07, $4E09, $4E24, $4E5D, $4E8C, $4E94, $4E96, $4EC0, $4EDF, $4EE8, $4F0D, $4F70,
    $4FE9, $5006, $5146, $5169, $516B, $516D, $5341, $5343, $5344, $5345, $534C, $53C1,
    $53C2, $53C3, $53C4, $56DB, $58F1, $58F9, $5E7A, $5EFE, $5EFF, $5F0C, $5F10, $62D0,
    $62FE, $634C, $67D2, $6D1E, $6F06, $7396, $767E, $7695, $8086, $842C, $8CAE, $8CB3,
    $8D30, $920E, $94A9, $9621, $9646, $964C, $9678, $96F6, $A620, $A6E6, $A6EF, $A8D0,
    $A900, $A9D0, $A9F0, $AA50, $ABF0, $F96B, $F973, $F978, $F9B2, $F9D1, $F9D3, $F9FD,
    $FF10);
  NumLast : Array[0..180] Of Word = (
    $0039, $00B3, $00B9, $0669, $06F9, $07C9, $096F, $09EF, $09F9, $0A6F, $0AEF, $0B6F,
    $0BF0, $0BF1, $0BF2, $0C6F, $0C7B, $0C7E, $0CEF, $0D70, $0D71, $0D72, $0DEF, $0E59,
    $0ED9, $0F29, $1049, $1099, $1372, $1373, $1374, $1375, $1376, $1377, $1378, $1379,
    $137A, $137B, $137C, $16F0, $17E9, $17F9, $1819, $194F, $19D9, $19DA, $1A89, $1A99,
    $1B59, $1BB9, $1C49, $1C59, $2070, $2079, $2089, $215F, $216B, $216C, $216D, $216E,
    $216F, $217B, $217C, $217D, $217E, $217F, $2180, $2181, $2182, $2185, $2186, $2187,
    $2188, $2189, $2473, $2487, $249B, $24EA, $24F4, $24FE, $24FF, $277F, $2789, $2793,
    $3007, $3029, $3038, $3039, $303A, $3195, $3229, $3248, $3249, $324A, $324B, $324C,
    $324D, $324E, $324F, $325F, $3289, $32BF, $3405, $3483, $382A, $3B4D, $4E00, $4E03,
    $4E07, $4E09, $4E24, $4E5D, $4E8C, $4E94, $4E96, $4EC0, $4EDF, $4EE8, $4F0D, $4F70,
    $4FE9, $5006, $5146, $5169, $516B, $516D, $5341, $5343, $5344, $5345, $534C, $53C1,
    $53C2, $53C3, $53C4, $56DB, $58F1, $58F9, $5E7A, $5EFE, $5EFF, $5F0E, $5F10, $62D0,
    $62FE, $634C, $67D2, $6D1E, $6F06, $7396, $767E, $7695, $8086, $842C, $8CAE, $8CB3,
    $8D30, $920E, $94A9, $9621, $9646, $964C, $9678, $96F6, $A629, $A6EE, $A6EF, $A8D9,
    $A909, $A9D9, $A9F9, $AA59, $ABF9, $F96B, $F973, $F978, $F9B2, $F9D1, $F9D3, $F9FD,
    $FF19);
  NumVal : Array[0..180] Of LongInt = (
    0, 2, 1, 0, 0, 0, 0, 0, 16, 0, 0, 0,
    0, 100, 1000, 0, 0, 1, 0, 0, 100, 1000, 0, 0,
    0, 0, 0, 0, 1, 20, 30, 40, 50, 60, 70, 80,
    90, 100, 10000, 17, 0, 0, 0, 0, 0, 1, 0, 0,
    0, 0, 0, 0, 0, 4, 0, 1, 1, 50, 100, 500,
    1000, 1, 50, 100, 500, 1000, 1000, 5000, 10000, 6, 50, 50000,
    100000, 0, 1, 1, 1, 0, 11, 1, 0, 1, 1, 1,
    0, 1, 10, 20, 30, 1, 1, 10, 20, 30, 40, 50,
    60, 70, 80, 21, 1, 36, 5, 2, 5, 7, 1, 7,
    10000, 3, 2, 9, 2, 5, 4, 10, 1000, 3, 5, 100,
    2, 2, 1000000, 2, 8, 6, 10, 1000, 20, 30, 40, 3,
    3, 3, 3, 4, 1, 1, 1, 9, 20, 1, 2, 7,
    10, 8, 7, 0, 7, 9, 100, 200, 4, 10000, 2, 2,
    2, 9, 9, 1000, 6, 100, 6, 0, 0, 1, 0, 0,
    0, 0, 0, 0, 0, 3, 10, 2, 0, 6, 6, 10,
    0);
  { decompositions canoniques (un niveau) : caractere -> base + marque ;
    DecComp = 1 si la paire se recompose (NFC) }
  DecChar : Array[0..1485] Of Word = (
    $00C0, $00C1, $00C2, $00C3, $00C4, $00C5, $00C7, $00C8, $00C9, $00CA, $00CB, $00CC,
    $00CD, $00CE, $00CF, $00D1, $00D2, $00D3, $00D4, $00D5, $00D6, $00D9, $00DA, $00DB,
    $00DC, $00DD, $00E0, $00E1, $00E2, $00E3, $00E4, $00E5, $00E7, $00E8, $00E9, $00EA,
    $00EB, $00EC, $00ED, $00EE, $00EF, $00F1, $00F2, $00F3, $00F4, $00F5, $00F6, $00F9,
    $00FA, $00FB, $00FC, $00FD, $00FF, $0100, $0101, $0102, $0103, $0104, $0105, $0106,
    $0107, $0108, $0109, $010A, $010B, $010C, $010D, $010E, $010F, $0112, $0113, $0114,
    $0115, $0116, $0117, $0118, $0119, $011A, $011B, $011C, $011D, $011E, $011F, $0120,
    $0121, $0122, $0123, $0124, $0125, $0128, $0129, $012A, $012B, $012C, $012D, $012E,
    $012F, $0130, $0134, $0135, $0136, $0137, $0139, $013A, $013B, $013C, $013D, $013E,
    $0143, $0144, $0145, $0146, $0147, $0148, $014C, $014D, $014E, $014F, $0150, $0151,
    $0154, $0155, $0156, $0157, $0158, $0159, $015A, $015B, $015C, $015D, $015E, $015F,
    $0160, $0161, $0162, $0163, $0164, $0165, $0168, $0169, $016A, $016B, $016C, $016D,
    $016E, $016F, $0170, $0171, $0172, $0173, $0174, $0175, $0176, $0177, $0178, $0179,
    $017A, $017B, $017C, $017D, $017E, $01A0, $01A1, $01AF, $01B0, $01CD, $01CE, $01CF,
    $01D0, $01D1, $01D2, $01D3, $01D4, $01D5, $01D6, $01D7, $01D8, $01D9, $01DA, $01DB,
    $01DC, $01DE, $01DF, $01E0, $01E1, $01E2, $01E3, $01E6, $01E7, $01E8, $01E9, $01EA,
    $01EB, $01EC, $01ED, $01EE, $01EF, $01F0, $01F4, $01F5, $01F8, $01F9, $01FA, $01FB,
    $01FC, $01FD, $01FE, $01FF, $0200, $0201, $0202, $0203, $0204, $0205, $0206, $0207,
    $0208, $0209, $020A, $020B, $020C, $020D, $020E, $020F, $0210, $0211, $0212, $0213,
    $0214, $0215, $0216, $0217, $0218, $0219, $021A, $021B, $021E, $021F, $0226, $0227,
    $0228, $0229, $022A, $022B, $022C, $022D, $022E, $022F, $0230, $0231, $0232, $0233,
    $0340, $0341, $0343, $0344, $0374, $037E, $0385, $0386, $0387, $0388, $0389, $038A,
    $038C, $038E, $038F, $0390, $03AA, $03AB, $03AC, $03AD, $03AE, $03AF, $03B0, $03CA,
    $03CB, $03CC, $03CD, $03CE, $03D3, $03D4, $0400, $0401, $0403, $0407, $040C, $040D,
    $040E, $0419, $0439, $0450, $0451, $0453, $0457, $045C, $045D, $045E, $0476, $0477,
    $04C1, $04C2, $04D0, $04D1, $04D2, $04D3, $04D6, $04D7, $04DA, $04DB, $04DC, $04DD,
    $04DE, $04DF, $04E2, $04E3, $04E4, $04E5, $04E6, $04E7, $04EA, $04EB, $04EC, $04ED,
    $04EE, $04EF, $04F0, $04F1, $04F2, $04F3, $04F4, $04F5, $04F8, $04F9, $0622, $0623,
    $0624, $0625, $0626, $06C0, $06C2, $06D3, $0929, $0931, $0934, $0958, $0959, $095A,
    $095B, $095C, $095D, $095E, $095F, $09CB, $09CC, $09DC, $09DD, $09DF, $0A33, $0A36,
    $0A59, $0A5A, $0A5B, $0A5E, $0B48, $0B4B, $0B4C, $0B5C, $0B5D, $0B94, $0BCA, $0BCB,
    $0BCC, $0C48, $0CC0, $0CC7, $0CC8, $0CCA, $0CCB, $0D4A, $0D4B, $0D4C, $0DDA, $0DDC,
    $0DDD, $0DDE, $0F43, $0F4D, $0F52, $0F57, $0F5C, $0F69, $0F73, $0F75, $0F76, $0F78,
    $0F81, $0F93, $0F9D, $0FA2, $0FA7, $0FAC, $0FB9, $1026, $1B06, $1B08, $1B0A, $1B0C,
    $1B0E, $1B12, $1B3B, $1B3D, $1B40, $1B41, $1B43, $1E00, $1E01, $1E02, $1E03, $1E04,
    $1E05, $1E06, $1E07, $1E08, $1E09, $1E0A, $1E0B, $1E0C, $1E0D, $1E0E, $1E0F, $1E10,
    $1E11, $1E12, $1E13, $1E14, $1E15, $1E16, $1E17, $1E18, $1E19, $1E1A, $1E1B, $1E1C,
    $1E1D, $1E1E, $1E1F, $1E20, $1E21, $1E22, $1E23, $1E24, $1E25, $1E26, $1E27, $1E28,
    $1E29, $1E2A, $1E2B, $1E2C, $1E2D, $1E2E, $1E2F, $1E30, $1E31, $1E32, $1E33, $1E34,
    $1E35, $1E36, $1E37, $1E38, $1E39, $1E3A, $1E3B, $1E3C, $1E3D, $1E3E, $1E3F, $1E40,
    $1E41, $1E42, $1E43, $1E44, $1E45, $1E46, $1E47, $1E48, $1E49, $1E4A, $1E4B, $1E4C,
    $1E4D, $1E4E, $1E4F, $1E50, $1E51, $1E52, $1E53, $1E54, $1E55, $1E56, $1E57, $1E58,
    $1E59, $1E5A, $1E5B, $1E5C, $1E5D, $1E5E, $1E5F, $1E60, $1E61, $1E62, $1E63, $1E64,
    $1E65, $1E66, $1E67, $1E68, $1E69, $1E6A, $1E6B, $1E6C, $1E6D, $1E6E, $1E6F, $1E70,
    $1E71, $1E72, $1E73, $1E74, $1E75, $1E76, $1E77, $1E78, $1E79, $1E7A, $1E7B, $1E7C,
    $1E7D, $1E7E, $1E7F, $1E80, $1E81, $1E82, $1E83, $1E84, $1E85, $1E86, $1E87, $1E88,
    $1E89, $1E8A, $1E8B, $1E8C, $1E8D, $1E8E, $1E8F, $1E90, $1E91, $1E92, $1E93, $1E94,
    $1E95, $1E96, $1E97, $1E98, $1E99, $1E9B, $1EA0, $1EA1, $1EA2, $1EA3, $1EA4, $1EA5,
    $1EA6, $1EA7, $1EA8, $1EA9, $1EAA, $1EAB, $1EAC, $1EAD, $1EAE, $1EAF, $1EB0, $1EB1,
    $1EB2, $1EB3, $1EB4, $1EB5, $1EB6, $1EB7, $1EB8, $1EB9, $1EBA, $1EBB, $1EBC, $1EBD,
    $1EBE, $1EBF, $1EC0, $1EC1, $1EC2, $1EC3, $1EC4, $1EC5, $1EC6, $1EC7, $1EC8, $1EC9,
    $1ECA, $1ECB, $1ECC, $1ECD, $1ECE, $1ECF, $1ED0, $1ED1, $1ED2, $1ED3, $1ED4, $1ED5,
    $1ED6, $1ED7, $1ED8, $1ED9, $1EDA, $1EDB, $1EDC, $1EDD, $1EDE, $1EDF, $1EE0, $1EE1,
    $1EE2, $1EE3, $1EE4, $1EE5, $1EE6, $1EE7, $1EE8, $1EE9, $1EEA, $1EEB, $1EEC, $1EED,
    $1EEE, $1EEF, $1EF0, $1EF1, $1EF2, $1EF3, $1EF4, $1EF5, $1EF6, $1EF7, $1EF8, $1EF9,
    $1F00, $1F01, $1F02, $1F03, $1F04, $1F05, $1F06, $1F07, $1F08, $1F09, $1F0A, $1F0B,
    $1F0C, $1F0D, $1F0E, $1F0F, $1F10, $1F11, $1F12, $1F13, $1F14, $1F15, $1F18, $1F19,
    $1F1A, $1F1B, $1F1C, $1F1D, $1F20, $1F21, $1F22, $1F23, $1F24, $1F25, $1F26, $1F27,
    $1F28, $1F29, $1F2A, $1F2B, $1F2C, $1F2D, $1F2E, $1F2F, $1F30, $1F31, $1F32, $1F33,
    $1F34, $1F35, $1F36, $1F37, $1F38, $1F39, $1F3A, $1F3B, $1F3C, $1F3D, $1F3E, $1F3F,
    $1F40, $1F41, $1F42, $1F43, $1F44, $1F45, $1F48, $1F49, $1F4A, $1F4B, $1F4C, $1F4D,
    $1F50, $1F51, $1F52, $1F53, $1F54, $1F55, $1F56, $1F57, $1F59, $1F5B, $1F5D, $1F5F,
    $1F60, $1F61, $1F62, $1F63, $1F64, $1F65, $1F66, $1F67, $1F68, $1F69, $1F6A, $1F6B,
    $1F6C, $1F6D, $1F6E, $1F6F, $1F70, $1F71, $1F72, $1F73, $1F74, $1F75, $1F76, $1F77,
    $1F78, $1F79, $1F7A, $1F7B, $1F7C, $1F7D, $1F80, $1F81, $1F82, $1F83, $1F84, $1F85,
    $1F86, $1F87, $1F88, $1F89, $1F8A, $1F8B, $1F8C, $1F8D, $1F8E, $1F8F, $1F90, $1F91,
    $1F92, $1F93, $1F94, $1F95, $1F96, $1F97, $1F98, $1F99, $1F9A, $1F9B, $1F9C, $1F9D,
    $1F9E, $1F9F, $1FA0, $1FA1, $1FA2, $1FA3, $1FA4, $1FA5, $1FA6, $1FA7, $1FA8, $1FA9,
    $1FAA, $1FAB, $1FAC, $1FAD, $1FAE, $1FAF, $1FB0, $1FB1, $1FB2, $1FB3, $1FB4, $1FB6,
    $1FB7, $1FB8, $1FB9, $1FBA, $1FBB, $1FBC, $1FBE, $1FC1, $1FC2, $1FC3, $1FC4, $1FC6,
    $1FC7, $1FC8, $1FC9, $1FCA, $1FCB, $1FCC, $1FCD, $1FCE, $1FCF, $1FD0, $1FD1, $1FD2,
    $1FD3, $1FD6, $1FD7, $1FD8, $1FD9, $1FDA, $1FDB, $1FDD, $1FDE, $1FDF, $1FE0, $1FE1,
    $1FE2, $1FE3, $1FE4, $1FE5, $1FE6, $1FE7, $1FE8, $1FE9, $1FEA, $1FEB, $1FEC, $1FED,
    $1FEE, $1FEF, $1FF2, $1FF3, $1FF4, $1FF6, $1FF7, $1FF8, $1FF9, $1FFA, $1FFB, $1FFC,
    $1FFD, $2000, $2001, $2126, $212A, $212B, $219A, $219B, $21AE, $21CD, $21CE, $21CF,
    $2204, $2209, $220C, $2224, $2226, $2241, $2244, $2247, $2249, $2260, $2262, $226D,
    $226E, $226F, $2270, $2271, $2274, $2275, $2278, $2279, $2280, $2281, $2284, $2285,
    $2288, $2289, $22AC, $22AD, $22AE, $22AF, $22E0, $22E1, $22E2, $22E3, $22EA, $22EB,
    $22EC, $22ED, $2329, $232A, $2ADC, $304C, $304E, $3050, $3052, $3054, $3056, $3058,
    $305A, $305C, $305E, $3060, $3062, $3065, $3067, $3069, $3070, $3071, $3073, $3074,
    $3076, $3077, $3079, $307A, $307C, $307D, $3094, $309E, $30AC, $30AE, $30B0, $30B2,
    $30B4, $30B6, $30B8, $30BA, $30BC, $30BE, $30C0, $30C2, $30C5, $30C7, $30C9, $30D0,
    $30D1, $30D3, $30D4, $30D6, $30D7, $30D9, $30DA, $30DC, $30DD, $30F4, $30F7, $30F8,
    $30F9, $30FA, $30FE, $F900, $F901, $F902, $F903, $F904, $F905, $F906, $F907, $F908,
    $F909, $F90A, $F90B, $F90C, $F90D, $F90E, $F90F, $F910, $F911, $F912, $F913, $F914,
    $F915, $F916, $F917, $F918, $F919, $F91A, $F91B, $F91C, $F91D, $F91E, $F91F, $F920,
    $F921, $F922, $F923, $F924, $F925, $F926, $F927, $F928, $F929, $F92A, $F92B, $F92C,
    $F92D, $F92E, $F92F, $F930, $F931, $F932, $F933, $F934, $F935, $F936, $F937, $F938,
    $F939, $F93A, $F93B, $F93C, $F93D, $F93E, $F93F, $F940, $F941, $F942, $F943, $F944,
    $F945, $F946, $F947, $F948, $F949, $F94A, $F94B, $F94C, $F94D, $F94E, $F94F, $F950,
    $F951, $F952, $F953, $F954, $F955, $F956, $F957, $F958, $F959, $F95A, $F95B, $F95C,
    $F95D, $F95E, $F95F, $F960, $F961, $F962, $F963, $F964, $F965, $F966, $F967, $F968,
    $F969, $F96A, $F96B, $F96C, $F96D, $F96E, $F96F, $F970, $F971, $F972, $F973, $F974,
    $F975, $F976, $F977, $F978, $F979, $F97A, $F97B, $F97C, $F97D, $F97E, $F97F, $F980,
    $F981, $F982, $F983, $F984, $F985, $F986, $F987, $F988, $F989, $F98A, $F98B, $F98C,
    $F98D, $F98E, $F98F, $F990, $F991, $F992, $F993, $F994, $F995, $F996, $F997, $F998,
    $F999, $F99A, $F99B, $F99C, $F99D, $F99E, $F99F, $F9A0, $F9A1, $F9A2, $F9A3, $F9A4,
    $F9A5, $F9A6, $F9A7, $F9A8, $F9A9, $F9AA, $F9AB, $F9AC, $F9AD, $F9AE, $F9AF, $F9B0,
    $F9B1, $F9B2, $F9B3, $F9B4, $F9B5, $F9B6, $F9B7, $F9B8, $F9B9, $F9BA, $F9BB, $F9BC,
    $F9BD, $F9BE, $F9BF, $F9C0, $F9C1, $F9C2, $F9C3, $F9C4, $F9C5, $F9C6, $F9C7, $F9C8,
    $F9C9, $F9CA, $F9CB, $F9CC, $F9CD, $F9CE, $F9CF, $F9D0, $F9D1, $F9D2, $F9D3, $F9D4,
    $F9D5, $F9D6, $F9D7, $F9D8, $F9D9, $F9DA, $F9DB, $F9DC, $F9DD, $F9DE, $F9DF, $F9E0,
    $F9E1, $F9E2, $F9E3, $F9E4, $F9E5, $F9E6, $F9E7, $F9E8, $F9E9, $F9EA, $F9EB, $F9EC,
    $F9ED, $F9EE, $F9EF, $F9F0, $F9F1, $F9F2, $F9F3, $F9F4, $F9F5, $F9F6, $F9F7, $F9F8,
    $F9F9, $F9FA, $F9FB, $F9FC, $F9FD, $F9FE, $F9FF, $FA00, $FA01, $FA02, $FA03, $FA04,
    $FA05, $FA06, $FA07, $FA08, $FA09, $FA0A, $FA0B, $FA0C, $FA0D, $FA10, $FA12, $FA15,
    $FA16, $FA17, $FA18, $FA19, $FA1A, $FA1B, $FA1C, $FA1D, $FA1E, $FA20, $FA22, $FA25,
    $FA26, $FA2A, $FA2B, $FA2C, $FA2D, $FA2E, $FA2F, $FA30, $FA31, $FA32, $FA33, $FA34,
    $FA35, $FA36, $FA37, $FA38, $FA39, $FA3A, $FA3B, $FA3C, $FA3D, $FA3E, $FA3F, $FA40,
    $FA41, $FA42, $FA43, $FA44, $FA45, $FA46, $FA47, $FA48, $FA49, $FA4A, $FA4B, $FA4C,
    $FA4D, $FA4E, $FA4F, $FA50, $FA51, $FA52, $FA53, $FA54, $FA55, $FA56, $FA57, $FA58,
    $FA59, $FA5A, $FA5B, $FA5C, $FA5D, $FA5E, $FA5F, $FA60, $FA61, $FA62, $FA63, $FA64,
    $FA65, $FA66, $FA67, $FA68, $FA69, $FA6A, $FA6B, $FA6D, $FA70, $FA71, $FA72, $FA73,
    $FA74, $FA75, $FA76, $FA77, $FA78, $FA79, $FA7A, $FA7B, $FA7C, $FA7D, $FA7E, $FA7F,
    $FA80, $FA81, $FA82, $FA83, $FA84, $FA85, $FA86, $FA87, $FA88, $FA89, $FA8A, $FA8B,
    $FA8C, $FA8D, $FA8E, $FA8F, $FA90, $FA91, $FA92, $FA93, $FA94, $FA95, $FA96, $FA97,
    $FA98, $FA99, $FA9A, $FA9B, $FA9C, $FA9D, $FA9E, $FA9F, $FAA0, $FAA1, $FAA2, $FAA3,
    $FAA4, $FAA5, $FAA6, $FAA7, $FAA8, $FAA9, $FAAA, $FAAB, $FAAC, $FAAD, $FAAE, $FAAF,
    $FAB0, $FAB1, $FAB2, $FAB3, $FAB4, $FAB5, $FAB6, $FAB7, $FAB8, $FAB9, $FABA, $FABB,
    $FABC, $FABD, $FABE, $FABF, $FAC0, $FAC1, $FAC2, $FAC3, $FAC4, $FAC5, $FAC6, $FAC7,
    $FAC8, $FAC9, $FACA, $FACB, $FACC, $FACD, $FACE, $FAD2, $FAD3, $FAD4, $FAD8, $FAD9,
    $FB1D, $FB1F, $FB2A, $FB2B, $FB2C, $FB2D, $FB2E, $FB2F, $FB30, $FB31, $FB32, $FB33,
    $FB34, $FB35, $FB36, $FB38, $FB39, $FB3A, $FB3B, $FB3C, $FB3E, $FB40, $FB41, $FB43,
    $FB44, $FB46, $FB47, $FB48, $FB49, $FB4A, $FB4B, $FB4C, $FB4D, $FB4E);
  DecBase : Array[0..1485] Of Word = (
    $0041, $0041, $0041, $0041, $0041, $0041, $0043, $0045, $0045, $0045, $0045, $0049,
    $0049, $0049, $0049, $004E, $004F, $004F, $004F, $004F, $004F, $0055, $0055, $0055,
    $0055, $0059, $0061, $0061, $0061, $0061, $0061, $0061, $0063, $0065, $0065, $0065,
    $0065, $0069, $0069, $0069, $0069, $006E, $006F, $006F, $006F, $006F, $006F, $0075,
    $0075, $0075, $0075, $0079, $0079, $0041, $0061, $0041, $0061, $0041, $0061, $0043,
    $0063, $0043, $0063, $0043, $0063, $0043, $0063, $0044, $0064, $0045, $0065, $0045,
    $0065, $0045, $0065, $0045, $0065, $0045, $0065, $0047, $0067, $0047, $0067, $0047,
    $0067, $0047, $0067, $0048, $0068, $0049, $0069, $0049, $0069, $0049, $0069, $0049,
    $0069, $0049, $004A, $006A, $004B, $006B, $004C, $006C, $004C, $006C, $004C, $006C,
    $004E, $006E, $004E, $006E, $004E, $006E, $004F, $006F, $004F, $006F, $004F, $006F,
    $0052, $0072, $0052, $0072, $0052, $0072, $0053, $0073, $0053, $0073, $0053, $0073,
    $0053, $0073, $0054, $0074, $0054, $0074, $0055, $0075, $0055, $0075, $0055, $0075,
    $0055, $0075, $0055, $0075, $0055, $0075, $0057, $0077, $0059, $0079, $0059, $005A,
    $007A, $005A, $007A, $005A, $007A, $004F, $006F, $0055, $0075, $0041, $0061, $0049,
    $0069, $004F, $006F, $0055, $0075, $00DC, $00FC, $00DC, $00FC, $00DC, $00FC, $00DC,
    $00FC, $00C4, $00E4, $0226, $0227, $00C6, $00E6, $0047, $0067, $004B, $006B, $004F,
    $006F, $01EA, $01EB, $01B7, $0292, $006A, $0047, $0067, $004E, $006E, $00C5, $00E5,
    $00C6, $00E6, $00D8, $00F8, $0041, $0061, $0041, $0061, $0045, $0065, $0045, $0065,
    $0049, $0069, $0049, $0069, $004F, $006F, $004F, $006F, $0052, $0072, $0052, $0072,
    $0055, $0075, $0055, $0075, $0053, $0073, $0054, $0074, $0048, $0068, $0041, $0061,
    $0045, $0065, $00D6, $00F6, $00D5, $00F5, $004F, $006F, $022E, $022F, $0059, $0079,
    $0300, $0301, $0313, $0308, $02B9, $003B, $00A8, $0391, $00B7, $0395, $0397, $0399,
    $039F, $03A5, $03A9, $03CA, $0399, $03A5, $03B1, $03B5, $03B7, $03B9, $03CB, $03B9,
    $03C5, $03BF, $03C5, $03C9, $03D2, $03D2, $0415, $0415, $0413, $0406, $041A, $0418,
    $0423, $0418, $0438, $0435, $0435, $0433, $0456, $043A, $0438, $0443, $0474, $0475,
    $0416, $0436, $0410, $0430, $0410, $0430, $0415, $0435, $04D8, $04D9, $0416, $0436,
    $0417, $0437, $0418, $0438, $0418, $0438, $041E, $043E, $04E8, $04E9, $042D, $044D,
    $0423, $0443, $0423, $0443, $0423, $0443, $0427, $0447, $042B, $044B, $0627, $0627,
    $0648, $0627, $064A, $06D5, $06C1, $06D2, $0928, $0930, $0933, $0915, $0916, $0917,
    $091C, $0921, $0922, $092B, $092F, $09C7, $09C7, $09A1, $09A2, $09AF, $0A32, $0A38,
    $0A16, $0A17, $0A1C, $0A2B, $0B47, $0B47, $0B47, $0B21, $0B22, $0B92, $0BC6, $0BC7,
    $0BC6, $0C46, $0CBF, $0CC6, $0CC6, $0CC6, $0CCA, $0D46, $0D47, $0D46, $0DD9, $0DD9,
    $0DDC, $0DD9, $0F42, $0F4C, $0F51, $0F56, $0F5B, $0F40, $0F71, $0F71, $0FB2, $0FB3,
    $0F71, $0F92, $0F9C, $0FA1, $0FA6, $0FAB, $0F90, $1025, $1B05, $1B07, $1B09, $1B0B,
    $1B0D, $1B11, $1B3A, $1B3C, $1B3E, $1B3F, $1B42, $0041, $0061, $0042, $0062, $0042,
    $0062, $0042, $0062, $00C7, $00E7, $0044, $0064, $0044, $0064, $0044, $0064, $0044,
    $0064, $0044, $0064, $0112, $0113, $0112, $0113, $0045, $0065, $0045, $0065, $0228,
    $0229, $0046, $0066, $0047, $0067, $0048, $0068, $0048, $0068, $0048, $0068, $0048,
    $0068, $0048, $0068, $0049, $0069, $00CF, $00EF, $004B, $006B, $004B, $006B, $004B,
    $006B, $004C, $006C, $1E36, $1E37, $004C, $006C, $004C, $006C, $004D, $006D, $004D,
    $006D, $004D, $006D, $004E, $006E, $004E, $006E, $004E, $006E, $004E, $006E, $00D5,
    $00F5, $00D5, $00F5, $014C, $014D, $014C, $014D, $0050, $0070, $0050, $0070, $0052,
    $0072, $0052, $0072, $1E5A, $1E5B, $0052, $0072, $0053, $0073, $0053, $0073, $015A,
    $015B, $0160, $0161, $1E62, $1E63, $0054, $0074, $0054, $0074, $0054, $0074, $0054,
    $0074, $0055, $0075, $0055, $0075, $0055, $0075, $0168, $0169, $016A, $016B, $0056,
    $0076, $0056, $0076, $0057, $0077, $0057, $0077, $0057, $0077, $0057, $0077, $0057,
    $0077, $0058, $0078, $0058, $0078, $0059, $0079, $005A, $007A, $005A, $007A, $005A,
    $007A, $0068, $0074, $0077, $0079, $017F, $0041, $0061, $0041, $0061, $00C2, $00E2,
    $00C2, $00E2, $00C2, $00E2, $00C2, $00E2, $1EA0, $1EA1, $0102, $0103, $0102, $0103,
    $0102, $0103, $0102, $0103, $1EA0, $1EA1, $0045, $0065, $0045, $0065, $0045, $0065,
    $00CA, $00EA, $00CA, $00EA, $00CA, $00EA, $00CA, $00EA, $1EB8, $1EB9, $0049, $0069,
    $0049, $0069, $004F, $006F, $004F, $006F, $00D4, $00F4, $00D4, $00F4, $00D4, $00F4,
    $00D4, $00F4, $1ECC, $1ECD, $01A0, $01A1, $01A0, $01A1, $01A0, $01A1, $01A0, $01A1,
    $01A0, $01A1, $0055, $0075, $0055, $0075, $01AF, $01B0, $01AF, $01B0, $01AF, $01B0,
    $01AF, $01B0, $01AF, $01B0, $0059, $0079, $0059, $0079, $0059, $0079, $0059, $0079,
    $03B1, $03B1, $1F00, $1F01, $1F00, $1F01, $1F00, $1F01, $0391, $0391, $1F08, $1F09,
    $1F08, $1F09, $1F08, $1F09, $03B5, $03B5, $1F10, $1F11, $1F10, $1F11, $0395, $0395,
    $1F18, $1F19, $1F18, $1F19, $03B7, $03B7, $1F20, $1F21, $1F20, $1F21, $1F20, $1F21,
    $0397, $0397, $1F28, $1F29, $1F28, $1F29, $1F28, $1F29, $03B9, $03B9, $1F30, $1F31,
    $1F30, $1F31, $1F30, $1F31, $0399, $0399, $1F38, $1F39, $1F38, $1F39, $1F38, $1F39,
    $03BF, $03BF, $1F40, $1F41, $1F40, $1F41, $039F, $039F, $1F48, $1F49, $1F48, $1F49,
    $03C5, $03C5, $1F50, $1F51, $1F50, $1F51, $1F50, $1F51, $03A5, $1F59, $1F59, $1F59,
    $03C9, $03C9, $1F60, $1F61, $1F60, $1F61, $1F60, $1F61, $03A9, $03A9, $1F68, $1F69,
    $1F68, $1F69, $1F68, $1F69, $03B1, $03AC, $03B5, $03AD, $03B7, $03AE, $03B9, $03AF,
    $03BF, $03CC, $03C5, $03CD, $03C9, $03CE, $1F00, $1F01, $1F02, $1F03, $1F04, $1F05,
    $1F06, $1F07, $1F08, $1F09, $1F0A, $1F0B, $1F0C, $1F0D, $1F0E, $1F0F, $1F20, $1F21,
    $1F22, $1F23, $1F24, $1F25, $1F26, $1F27, $1F28, $1F29, $1F2A, $1F2B, $1F2C, $1F2D,
    $1F2E, $1F2F, $1F60, $1F61, $1F62, $1F63, $1F64, $1F65, $1F66, $1F67, $1F68, $1F69,
    $1F6A, $1F6B, $1F6C, $1F6D, $1F6E, $1F6F, $03B1, $03B1, $1F70, $03B1, $03AC, $03B1,
    $1FB6, $0391, $0391, $0391, $0386, $0391, $03B9, $00A8, $1F74, $03B7, $03AE, $03B7,
    $1FC6, $0395, $0388, $0397, $0389, $0397, $1FBF, $1FBF, $1FBF, $03B9, $03B9, $03CA,
    $0390, $03B9, $03CA, $0399, $0399, $0399, $038A, $1FFE, $1FFE, $1FFE, $03C5, $03C5,
    $03CB, $03B0, $03C1, $03C1, $03C5, $03CB, $03A5, $03A5, $03A5, $038E, $03A1, $00A8,
    $0385, $0060, $1F7C, $03C9, $03CE, $03C9, $1FF6, $039F, $038C, $03A9, $038F, $03A9,
    $00B4, $2002, $2003, $03A9, $004B, $00C5, $2190, $2192, $2194, $21D0, $21D4, $21D2,
    $2203, $2208, $220B, $2223, $2225, $223C, $2243, $2245, $2248, $003D, $2261, $224D,
    $003C, $003E, $2264, $2265, $2272, $2273, $2276, $2277, $227A, $227B, $2282, $2283,
    $2286, $2287, $22A2, $22A8, $22A9, $22AB, $227C, $227D, $2291, $2292, $22B2, $22B3,
    $22B4, $22B5, $3008, $3009, $2ADD, $304B, $304D, $304F, $3051, $3053, $3055, $3057,
    $3059, $305B, $305D, $305F, $3061, $3064, $3066, $3068, $306F, $306F, $3072, $3072,
    $3075, $3075, $3078, $3078, $307B, $307B, $3046, $309D, $30AB, $30AD, $30AF, $30B1,
    $30B3, $30B5, $30B7, $30B9, $30BB, $30BD, $30BF, $30C1, $30C4, $30C6, $30C8, $30CF,
    $30CF, $30D2, $30D2, $30D5, $30D5, $30D8, $30D8, $30DB, $30DB, $30A6, $30EF, $30F0,
    $30F1, $30F2, $30FD, $8C48, $66F4, $8ECA, $8CC8, $6ED1, $4E32, $53E5, $9F9C, $9F9C,
    $5951, $91D1, $5587, $5948, $61F6, $7669, $7F85, $863F, $87BA, $88F8, $908F, $6A02,
    $6D1B, $70D9, $73DE, $843D, $916A, $99F1, $4E82, $5375, $6B04, $721B, $862D, $9E1E,
    $5D50, $6FEB, $85CD, $8964, $62C9, $81D8, $881F, $5ECA, $6717, $6D6A, $72FC, $90CE,
    $4F86, $51B7, $52DE, $64C4, $6AD3, $7210, $76E7, $8001, $8606, $865C, $8DEF, $9732,
    $9B6F, $9DFA, $788C, $797F, $7DA0, $83C9, $9304, $9E7F, $8AD6, $58DF, $5F04, $7C60,
    $807E, $7262, $78CA, $8CC2, $96F7, $58D8, $5C62, $6A13, $6DDA, $6F0F, $7D2F, $7E37,
    $964B, $52D2, $808B, $51DC, $51CC, $7A1C, $7DBE, $83F1, $9675, $8B80, $62CF, $6A02,
    $8AFE, $4E39, $5BE7, $6012, $7387, $7570, $5317, $78FB, $4FBF, $5FA9, $4E0D, $6CCC,
    $6578, $7D22, $53C3, $585E, $7701, $8449, $8AAA, $6BBA, $8FB0, $6C88, $62FE, $82E5,
    $63A0, $7565, $4EAE, $5169, $51C9, $6881, $7CE7, $826F, $8AD2, $91CF, $52F5, $5442,
    $5973, $5EEC, $65C5, $6FFE, $792A, $95AD, $9A6A, $9E97, $9ECE, $529B, $66C6, $6B77,
    $8F62, $5E74, $6190, $6200, $649A, $6F23, $7149, $7489, $79CA, $7DF4, $806F, $8F26,
    $84EE, $9023, $934A, $5217, $52A3, $54BD, $70C8, $88C2, $8AAA, $5EC9, $5FF5, $637B,
    $6BAE, $7C3E, $7375, $4EE4, $56F9, $5BE7, $5DBA, $601C, $73B2, $7469, $7F9A, $8046,
    $9234, $96F6, $9748, $9818, $4F8B, $79AE, $91B4, $96B8, $60E1, $4E86, $50DA, $5BEE,
    $5C3F, $6599, $6A02, $71CE, $7642, $84FC, $907C, $9F8D, $6688, $962E, $5289, $677B,
    $67F3, $6D41, $6E9C, $7409, $7559, $786B, $7D10, $985E, $516D, $622E, $9678, $502B,
    $5D19, $6DEA, $8F2A, $5F8B, $6144, $6817, $7387, $9686, $5229, $540F, $5C65, $6613,
    $674E, $68A8, $6CE5, $7406, $75E2, $7F79, $88CF, $88E1, $91CC, $96E2, $533F, $6EBA,
    $541D, $71D0, $7498, $85FA, $96A3, $9C57, $9E9F, $6797, $6DCB, $81E8, $7ACB, $7B20,
    $7C92, $72C0, $7099, $8B58, $4EC0, $8336, $523A, $5207, $5EA6, $62D3, $7CD6, $5B85,
    $6D1E, $66B4, $8F3B, $884C, $964D, $898B, $5ED3, $5140, $55C0, $585A, $6674, $51DE,
    $732A, $76CA, $793C, $795E, $7965, $798F, $9756, $7CBE, $7FBD, $8612, $8AF8, $9038,
    $90FD, $98EF, $98FC, $9928, $9DB4, $90DE, $96B7, $4FAE, $50E7, $514D, $52C9, $52E4,
    $5351, $559D, $5606, $5668, $5840, $58A8, $5C64, $5C6E, $6094, $6168, $618E, $61F2,
    $654F, $65E2, $6691, $6885, $6D77, $6E1A, $6F22, $716E, $722B, $7422, $7891, $793E,
    $7949, $7948, $7950, $7956, $795D, $798D, $798E, $7A40, $7A81, $7BC0, $7DF4, $7E09,
    $7E41, $7F72, $8005, $81ED, $8279, $8279, $8457, $8910, $8996, $8B01, $8B39, $8CD3,
    $8D08, $8FB6, $9038, $96E3, $97FF, $983B, $6075, $8218, $4E26, $51B5, $5168, $4F80,
    $5145, $5180, $52C7, $52FA, $559D, $5555, $5599, $55E2, $585A, $58B3, $5944, $5954,
    $5A62, $5B28, $5ED2, $5ED9, $5F69, $5FAD, $60D8, $614E, $6108, $618E, $6160, $61F2,
    $6234, $63C4, $641C, $6452, $6556, $6674, $6717, $671B, $6756, $6B79, $6BBA, $6D41,
    $6EDB, $6ECB, $6F22, $701E, $716E, $77A7, $7235, $72AF, $732A, $7471, $7506, $753B,
    $761D, $761F, $76CA, $76DB, $76F4, $774A, $7740, $78CC, $7AB1, $7BC0, $7C7B, $7D5B,
    $7DF4, $7F3E, $8005, $8352, $83EF, $8779, $8941, $8986, $8996, $8ABF, $8AF8, $8ACB,
    $8B01, $8AFE, $8AED, $8B39, $8B8A, $8D08, $8F38, $9072, $9199, $9276, $967C, $96E3,
    $9756, $97DB, $97FF, $980B, $983B, $9B12, $9F9C, $3B9D, $4018, $4039, $9F43, $9F8E,
    $05D9, $05F2, $05E9, $05E9, $FB49, $FB49, $05D0, $05D0, $05D0, $05D1, $05D2, $05D3,
    $05D4, $05D5, $05D6, $05D8, $05D9, $05DA, $05DB, $05DC, $05DE, $05E0, $05E1, $05E3,
    $05E4, $05E6, $05E7, $05E8, $05E9, $05EA, $05D5, $05D1, $05DB, $05E4);
  DecMark : Array[0..1485] Of Word = (
    $0300, $0301, $0302, $0303, $0308, $030A, $0327, $0300, $0301, $0302, $0308, $0300,
    $0301, $0302, $0308, $0303, $0300, $0301, $0302, $0303, $0308, $0300, $0301, $0302,
    $0308, $0301, $0300, $0301, $0302, $0303, $0308, $030A, $0327, $0300, $0301, $0302,
    $0308, $0300, $0301, $0302, $0308, $0303, $0300, $0301, $0302, $0303, $0308, $0300,
    $0301, $0302, $0308, $0301, $0308, $0304, $0304, $0306, $0306, $0328, $0328, $0301,
    $0301, $0302, $0302, $0307, $0307, $030C, $030C, $030C, $030C, $0304, $0304, $0306,
    $0306, $0307, $0307, $0328, $0328, $030C, $030C, $0302, $0302, $0306, $0306, $0307,
    $0307, $0327, $0327, $0302, $0302, $0303, $0303, $0304, $0304, $0306, $0306, $0328,
    $0328, $0307, $0302, $0302, $0327, $0327, $0301, $0301, $0327, $0327, $030C, $030C,
    $0301, $0301, $0327, $0327, $030C, $030C, $0304, $0304, $0306, $0306, $030B, $030B,
    $0301, $0301, $0327, $0327, $030C, $030C, $0301, $0301, $0302, $0302, $0327, $0327,
    $030C, $030C, $0327, $0327, $030C, $030C, $0303, $0303, $0304, $0304, $0306, $0306,
    $030A, $030A, $030B, $030B, $0328, $0328, $0302, $0302, $0302, $0302, $0308, $0301,
    $0301, $0307, $0307, $030C, $030C, $031B, $031B, $031B, $031B, $030C, $030C, $030C,
    $030C, $030C, $030C, $030C, $030C, $0304, $0304, $0301, $0301, $030C, $030C, $0300,
    $0300, $0304, $0304, $0304, $0304, $0304, $0304, $030C, $030C, $030C, $030C, $0328,
    $0328, $0304, $0304, $030C, $030C, $030C, $0301, $0301, $0300, $0300, $0301, $0301,
    $0301, $0301, $0301, $0301, $030F, $030F, $0311, $0311, $030F, $030F, $0311, $0311,
    $030F, $030F, $0311, $0311, $030F, $030F, $0311, $0311, $030F, $030F, $0311, $0311,
    $030F, $030F, $0311, $0311, $0326, $0326, $0326, $0326, $030C, $030C, $0307, $0307,
    $0327, $0327, $0304, $0304, $0304, $0304, $0307, $0307, $0304, $0304, $0304, $0304,
    $0000, $0000, $0000, $0301, $0000, $0000, $0301, $0301, $0000, $0301, $0301, $0301,
    $0301, $0301, $0301, $0301, $0308, $0308, $0301, $0301, $0301, $0301, $0301, $0308,
    $0308, $0301, $0301, $0301, $0301, $0308, $0300, $0308, $0301, $0308, $0301, $0300,
    $0306, $0306, $0306, $0300, $0308, $0301, $0308, $0301, $0300, $0306, $030F, $030F,
    $0306, $0306, $0306, $0306, $0308, $0308, $0306, $0306, $0308, $0308, $0308, $0308,
    $0308, $0308, $0304, $0304, $0308, $0308, $0308, $0308, $0308, $0308, $0308, $0308,
    $0304, $0304, $0308, $0308, $030B, $030B, $0308, $0308, $0308, $0308, $0653, $0654,
    $0654, $0655, $0654, $0654, $0654, $0654, $093C, $093C, $093C, $093C, $093C, $093C,
    $093C, $093C, $093C, $093C, $093C, $09BE, $09D7, $09BC, $09BC, $09BC, $0A3C, $0A3C,
    $0A3C, $0A3C, $0A3C, $0A3C, $0B56, $0B3E, $0B57, $0B3C, $0B3C, $0BD7, $0BBE, $0BBE,
    $0BD7, $0C56, $0CD5, $0CD5, $0CD6, $0CC2, $0CD5, $0D3E, $0D3E, $0D57, $0DCA, $0DCF,
    $0DCA, $0DDF, $0FB7, $0FB7, $0FB7, $0FB7, $0FB7, $0FB5, $0F72, $0F74, $0F80, $0F80,
    $0F80, $0FB7, $0FB7, $0FB7, $0FB7, $0FB7, $0FB5, $102E, $1B35, $1B35, $1B35, $1B35,
    $1B35, $1B35, $1B35, $1B35, $1B35, $1B35, $1B35, $0325, $0325, $0307, $0307, $0323,
    $0323, $0331, $0331, $0301, $0301, $0307, $0307, $0323, $0323, $0331, $0331, $0327,
    $0327, $032D, $032D, $0300, $0300, $0301, $0301, $032D, $032D, $0330, $0330, $0306,
    $0306, $0307, $0307, $0304, $0304, $0307, $0307, $0323, $0323, $0308, $0308, $0327,
    $0327, $032E, $032E, $0330, $0330, $0301, $0301, $0301, $0301, $0323, $0323, $0331,
    $0331, $0323, $0323, $0304, $0304, $0331, $0331, $032D, $032D, $0301, $0301, $0307,
    $0307, $0323, $0323, $0307, $0307, $0323, $0323, $0331, $0331, $032D, $032D, $0301,
    $0301, $0308, $0308, $0300, $0300, $0301, $0301, $0301, $0301, $0307, $0307, $0307,
    $0307, $0323, $0323, $0304, $0304, $0331, $0331, $0307, $0307, $0323, $0323, $0307,
    $0307, $0307, $0307, $0307, $0307, $0307, $0307, $0323, $0323, $0331, $0331, $032D,
    $032D, $0324, $0324, $0330, $0330, $032D, $032D, $0301, $0301, $0308, $0308, $0303,
    $0303, $0323, $0323, $0300, $0300, $0301, $0301, $0308, $0308, $0307, $0307, $0323,
    $0323, $0307, $0307, $0308, $0308, $0307, $0307, $0302, $0302, $0323, $0323, $0331,
    $0331, $0331, $0308, $030A, $030A, $0307, $0323, $0323, $0309, $0309, $0301, $0301,
    $0300, $0300, $0309, $0309, $0303, $0303, $0302, $0302, $0301, $0301, $0300, $0300,
    $0309, $0309, $0303, $0303, $0306, $0306, $0323, $0323, $0309, $0309, $0303, $0303,
    $0301, $0301, $0300, $0300, $0309, $0309, $0303, $0303, $0302, $0302, $0309, $0309,
    $0323, $0323, $0323, $0323, $0309, $0309, $0301, $0301, $0300, $0300, $0309, $0309,
    $0303, $0303, $0302, $0302, $0301, $0301, $0300, $0300, $0309, $0309, $0303, $0303,
    $0323, $0323, $0323, $0323, $0309, $0309, $0301, $0301, $0300, $0300, $0309, $0309,
    $0303, $0303, $0323, $0323, $0300, $0300, $0323, $0323, $0309, $0309, $0303, $0303,
    $0313, $0314, $0300, $0300, $0301, $0301, $0342, $0342, $0313, $0314, $0300, $0300,
    $0301, $0301, $0342, $0342, $0313, $0314, $0300, $0300, $0301, $0301, $0313, $0314,
    $0300, $0300, $0301, $0301, $0313, $0314, $0300, $0300, $0301, $0301, $0342, $0342,
    $0313, $0314, $0300, $0300, $0301, $0301, $0342, $0342, $0313, $0314, $0300, $0300,
    $0301, $0301, $0342, $0342, $0313, $0314, $0300, $0300, $0301, $0301, $0342, $0342,
    $0313, $0314, $0300, $0300, $0301, $0301, $0313, $0314, $0300, $0300, $0301, $0301,
    $0313, $0314, $0300, $0300, $0301, $0301, $0342, $0342, $0314, $0300, $0301, $0342,
    $0313, $0314, $0300, $0300, $0301, $0301, $0342, $0342, $0313, $0314, $0300, $0300,
    $0301, $0301, $0342, $0342, $0300, $0000, $0300, $0000, $0300, $0000, $0300, $0000,
    $0300, $0000, $0300, $0000, $0300, $0000, $0345, $0345, $0345, $0345, $0345, $0345,
    $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345,
    $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345,
    $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345, $0345,
    $0345, $0345, $0345, $0345, $0345, $0345, $0306, $0304, $0345, $0345, $0345, $0342,
    $0345, $0306, $0304, $0300, $0000, $0345, $0000, $0342, $0345, $0345, $0345, $0342,
    $0345, $0300, $0000, $0300, $0000, $0345, $0300, $0301, $0342, $0306, $0304, $0300,
    $0000, $0342, $0342, $0306, $0304, $0300, $0000, $0300, $0301, $0342, $0306, $0304,
    $0300, $0000, $0313, $0314, $0342, $0342, $0306, $0304, $0300, $0000, $0314, $0300,
    $0000, $0000, $0345, $0345, $0345, $0342, $0345, $0300, $0000, $0300, $0000, $0345,
    $0000, $0000, $0000, $0000, $0000, $0000, $0338, $0338, $0338, $0338, $0338, $0338,
    $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338,
    $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338,
    $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338, $0338,
    $0338, $0338, $0000, $0000, $0338, $3099, $3099, $3099, $3099, $3099, $3099, $3099,
    $3099, $3099, $3099, $3099, $3099, $3099, $3099, $3099, $3099, $309A, $3099, $309A,
    $3099, $309A, $3099, $309A, $3099, $309A, $3099, $3099, $3099, $3099, $3099, $3099,
    $3099, $3099, $3099, $3099, $3099, $3099, $3099, $3099, $3099, $3099, $3099, $3099,
    $309A, $3099, $309A, $3099, $309A, $3099, $309A, $3099, $309A, $3099, $3099, $3099,
    $3099, $3099, $3099, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $05B4, $05B7, $05C1, $05C2, $05C1, $05C2, $05B7, $05B8, $05BC, $05BC, $05BC, $05BC,
    $05BC, $05BC, $05BC, $05BC, $05BC, $05BC, $05BC, $05BC, $05BC, $05BC, $05BC, $05BC,
    $05BC, $05BC, $05BC, $05BC, $05BC, $05BC, $05B9, $05BF, $05BF, $05BF);
  DecComp : Array[0..1485] Of Word = (
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0000, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0000, $0000, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0000,
    $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0000, $0001, $0000, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0000, $0001, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0000, $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0001, $0001, $0001, $0001,
    $0001, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0001,
    $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0000, $0001,
    $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000);
  { katakana demi-chasse FF61h..FF9Fh -> pleine chasse }
  HalfKana : Array[0..62] Of Word = (
    $3002, $300C, $300D, $3001, $30FB, $30F2, $30A1, $30A3, $30A5, $30A7, $30A9, $30E3,
    $30E5, $30E7, $30C3, $30FC, $30A2, $30A4, $30A6, $30A8, $30AA, $30AB, $30AD, $30AF,
    $30B1, $30B3, $30B5, $30B7, $30B9, $30BB, $30BD, $30BF, $30C1, $30C4, $30C6, $30C8,
    $30CA, $30CB, $30CC, $30CD, $30CE, $30CF, $30D2, $30D5, $30D8, $30DB, $30DE, $30DF,
    $30E0, $30E1, $30E2, $30E4, $30E6, $30E8, $30E9, $30EA, $30EB, $30EC, $30ED, $30EF,
    $30F3, $3099, $309A);
  { pages de codes : caracteres 80h..FFh }
  Cp437Hi : Array[0..127] Of Word = (
    $00C7, $00FC, $00E9, $00E2, $00E4, $00E0, $00E5, $00E7, $00EA, $00EB, $00E8, $00EF,
    $00EE, $00EC, $00C4, $00C5, $00C9, $00E6, $00C6, $00F4, $00F6, $00F2, $00FB, $00F9,
    $00FF, $00D6, $00DC, $00A2, $00A3, $00A5, $20A7, $0192, $00E1, $00ED, $00F3, $00FA,
    $00F1, $00D1, $00AA, $00BA, $00BF, $2310, $00AC, $00BD, $00BC, $00A1, $00AB, $00BB,
    $2591, $2592, $2593, $2502, $2524, $2561, $2562, $2556, $2555, $2563, $2551, $2557,
    $255D, $255C, $255B, $2510, $2514, $2534, $252C, $251C, $2500, $253C, $255E, $255F,
    $255A, $2554, $2569, $2566, $2560, $2550, $256C, $2567, $2568, $2564, $2565, $2559,
    $2558, $2552, $2553, $256B, $256A, $2518, $250C, $2588, $2584, $258C, $2590, $2580,
    $03B1, $00DF, $0393, $03C0, $03A3, $03C3, $00B5, $03C4, $03A6, $0398, $03A9, $03B4,
    $221E, $03C6, $03B5, $2229, $2261, $00B1, $2265, $2264, $2320, $2321, $00F7, $2248,
    $00B0, $2219, $00B7, $221A, $207F, $00B2, $25A0, $00A0);
  Cp850Hi : Array[0..127] Of Word = (
    $00C7, $00FC, $00E9, $00E2, $00E4, $00E0, $00E5, $00E7, $00EA, $00EB, $00E8, $00EF,
    $00EE, $00EC, $00C4, $00C5, $00C9, $00E6, $00C6, $00F4, $00F6, $00F2, $00FB, $00F9,
    $00FF, $00D6, $00DC, $00F8, $00A3, $00D8, $00D7, $0192, $00E1, $00ED, $00F3, $00FA,
    $00F1, $00D1, $00AA, $00BA, $00BF, $00AE, $00AC, $00BD, $00BC, $00A1, $00AB, $00BB,
    $2591, $2592, $2593, $2502, $2524, $00C1, $00C2, $00C0, $00A9, $2563, $2551, $2557,
    $255D, $00A2, $00A5, $2510, $2514, $2534, $252C, $251C, $2500, $253C, $00E3, $00C3,
    $255A, $2554, $2569, $2566, $2560, $2550, $256C, $00A4, $00F0, $00D0, $00CA, $00CB,
    $00C8, $0131, $00CD, $00CE, $00CF, $2518, $250C, $2588, $2584, $00A6, $00CC, $2580,
    $00D3, $00DF, $00D4, $00D2, $00F5, $00D5, $00B5, $00FE, $00DE, $00DA, $00DB, $00D9,
    $00FD, $00DD, $00AF, $00B4, $00AD, $00B1, $2017, $00BE, $00B6, $00A7, $00F7, $00B8,
    $00B0, $00A8, $00B7, $00B9, $00B3, $00B2, $25A0, $00A0);


{ ==================================================================== }
{ Partie 3 - Services de DOSCALLS et utilitaires                       }
{ ==================================================================== }

Function DcScanEnv(PName, PValue : LongInt) : LongInt; External 'DOSCALLS' Name 'DosScanEnv';
Function DcOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
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
  P^ := V And $FFFF;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  P := Pointer(A);
  P^ := V And $FF;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

Function Alive(Pid : LongInt) : Boolean;
Begin
  Alive := (Pid = MyPid) Or (KrnMonIo(0, 4, Pid) <> 0);
End;

Function IntStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IntStr := S;
End;

Function HexStr(V : LongInt) : String;
Var S : String; D : LongInt;
Begin
  S := '';
  Repeat
    D := V And 15;
    If D < 10 Then S := Chr(48 + D) + S Else S := Chr(55 + D) + S;
    V := (V Shr 4) And $0FFFFFFF;
  Until V = 0;
  While Length(S) < 4 Do S := '0' + S;
  HexStr := S;
End;

Function StrInt(S : String) : LongInt;
Var V, K, Sg : LongInt;
Begin
  V := 0; Sg := 1; K := 1;
  If (Length(S) > 0) And (Ord(S[1]) = 45) Then
  Begin
    Sg := -1; K := 2;
  End;
  While (K <= Length(S)) And (Ord(S[K]) >= 48) And (Ord(S[K]) <= 57) Do
  Begin
    V := V * 10 + Ord(S[K]) - 48;
    Inc(K);
  End;
  StrInt := V * Sg;
End;

Function HexInt(S : String) : LongInt;
Var V, K, C : LongInt;
Begin
  V := 0;
  For K := 1 To Length(S) Do
  Begin
    C := Ord(UpCase(S[K]));
    If (C >= 48) And (C <= 57) Then V := V * 16 + C - 48
    Else If (C >= 65) And (C <= 70) Then V := V * 16 + C - 55;
  End;
  HexInt := V;
End;

Function LowStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (Ord(S[K]) >= 65) And (Ord(S[K]) <= 90) Then S[K] := Chr(Ord(S[K]) + 32);
  LowStr := S;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

{ '#xx' -> caractere xx (donnees des locales) }
Function Unesc(S : String) : String;
Var R : String; K : LongInt;
Begin
  R := '';
  K := 1;
  While K <= Length(S) Do
  Begin
    If (Ord(S[K]) = 35) And (K + 2 <= Length(S)) Then
    Begin
      R := R + Chr(HexInt(Copy(S, K + 1, 2)));
      K := K + 3;
    End
    Else
    Begin
      R := R + S[K];
      Inc(K);
    End;
  End;
  Unesc := R;
End;

{ caractere de 8 bits (latin-1, 80h = euro) <-> UniChar }
Function ByteUni(B : LongInt) : LongInt;
Begin
  If B = $80 Then ByteUni := $20AC Else ByteUni := B;
End;

Function UniByte(C : LongInt) : LongInt;
Begin
  If C = $20AC Then UniByte := $80
  Else If (C < 256) And (C <> $80) Then UniByte := C
  Else UniByte := 63;
End;

{ chaine ASCIIZ <-> String }
Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (RdB(A + N) <> 0) And (N < 255) Do
    Begin
      S := S + Chr(RdB(A + N));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

{ chaine UniChar <-> String (255 caracteres au plus) }
Function GetU(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (RdW(A + N * 2) <> 0) And (N < 255) Do
    Begin
      S := S + Chr(UniByte(RdW(A + N * 2)));
      Inc(N);
    End;
  End;
  GetU := S;
End;

Procedure PutU(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrW(A + (K - 1) * 2, ByteUni(Ord(S[K])));
  WrW(A + Length(S) * 2, 0);
End;

Function UStrLen(A : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  If A <> 0 Then
    While RdW(A + N * 2) <> 0 Do Inc(N);
  UStrLen := N;
End;

{ --- memoire rendue aux applications --- }
Function PoolAlloc : LongInt;
Var I, F, K : LongInt;
Begin
  F := -1;
  For I := PoolN - 1 DownTo 0 Do
    If PoolOwn[I] = 0 Then F := I;
  If F < 0 Then
  Begin
    { blocs des processus termines }
    For I := 0 To PoolN - 1 Do
      If Not Alive(PoolOwn[I]) Then PoolOwn[I] := 0;
    For I := PoolN - 1 DownTo 0 Do
      If PoolOwn[I] = 0 Then F := I;
  End;
  If F < 0 Then PoolAlloc := 0
  Else
  Begin
    PoolOwn[F] := MyPid;
    For K := 0 To PoolBlk - 1 Do PoolMem[F * PoolBlk + K] := 0;
    PoolAlloc := LongInt(@PoolMem) + F * PoolBlk;
  End;
End;

Function PoolFree(A : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := A - LongInt(@PoolMem);
  If (I < 0) Or (I >= PoolN * PoolBlk) Or ((I Mod PoolBlk) <> 0) Then PoolFree := ULS_BADOBJECT
  Else If PoolOwn[I Div PoolBlk] = 0 Then PoolFree := ULS_BADOBJECT
  Else
  Begin
    PoolOwn[I Div PoolBlk] := 0;
    PoolFree := ULS_SUCCESS;
  End;
End;

{ Bloc contenant la chaine S (UniChar ou ASCIIZ) ; 0 si memoire epuisee }
Function AllocU(S : String) : LongInt;
Var A : LongInt;
Begin
  A := PoolAlloc;
  If A <> 0 Then PutU(A, S);
  AllocU := A;
End;

Function AllocZ(S : String) : LongInt;
Var A : LongInt;
Begin
  A := PoolAlloc;
  If A <> 0 Then PutZ(A, S);
  AllocZ := A;
End;

{ ==================================================================== }
{ Partie 4 - Caracteres Unicode                                        }
{ ==================================================================== }

{ Attributs CT_* du caractere C }
Function CharMask(C : LongInt) : LongInt;
Var Lo, Hi, Mid : LongInt;
Begin
  C := C And $FFFF;
  Lo := 0; Hi := NMaskRun - 1;
  While Lo < Hi Do
  Begin
    Mid := (Lo + Hi + 1) Div 2;
    If MaskStart[Mid] <= C Then Lo := Mid Else Hi := Mid - 1;
  End;
  CharMask := MaskVal[Lo];
End;

Function BidiOf(C : LongInt) : LongInt;
Var Lo, Hi, Mid : LongInt;
Begin
  C := C And $FFFF;
  Lo := 0; Hi := NBidiRun - 1;
  While Lo < Hi Do
  Begin
    Mid := (Lo + Hi + 1) Div 2;
    If BidiStart[Mid] <= C Then Lo := Mid Else Hi := Mid - 1;
  End;
  BidiOf := BidiVal[Lo];
End;

Function UToUpper(C : LongInt) : LongInt;
Var Lo, Hi, Mid, R : LongInt;
Begin
  C := C And $FFFF;
  R := C;
  Lo := 0; Hi := NUpRun - 1;
  While Lo < Hi Do
  Begin
    Mid := (Lo + Hi + 1) Div 2;
    If UpFirst[Mid] <= C Then Lo := Mid Else Hi := Mid - 1;
  End;
  If (C >= UpFirst[Lo]) And (C <= UpLast[Lo]) Then
    If ((C - UpFirst[Lo]) Mod UpStep[Lo]) = 0 Then R := (C + UpDelta[Lo]) And $FFFF;
  UToUpper := R;
End;

Function UToLower(C : LongInt) : LongInt;
Var Lo, Hi, Mid, R : LongInt;
Begin
  C := C And $FFFF;
  R := C;
  Lo := 0; Hi := NLowRun - 1;
  While Lo < Hi Do
  Begin
    Mid := (Lo + Hi + 1) Div 2;
    If LowFirst[Mid] <= C Then Lo := Mid Else Hi := Mid - 1;
  End;
  If (C >= LowFirst[Lo]) And (C <= LowLast[Lo]) Then
    If ((C - LowFirst[Lo]) Mod LowStep[Lo]) = 0 Then R := (C + LowDelta[Lo]) And $FFFF;
  UToLower := R;
End;

{ Valeur numerique entiere ; -1 si aucune }
Function NumValue(C : LongInt) : LongInt;
Var Lo, Hi, Mid, R : LongInt;
Begin
  C := C And $FFFF;
  R := -1;
  Lo := 0; Hi := NNumRun - 1;
  While Lo < Hi Do
  Begin
    Mid := (Lo + Hi + 1) Div 2;
    If NumFirst[Mid] <= C Then Lo := Mid Else Hi := Mid - 1;
  End;
  If (C >= NumFirst[Lo]) And (C <= NumLast[Lo]) Then R := NumVal[Lo] + C - NumFirst[Lo];
  NumValue := R;
End;

{ Rang de la decomposition canonique de C ; -1 si aucune }
Function DecIdx(C : LongInt) : LongInt;
Var Lo, Hi, Mid : LongInt;
Begin
  C := C And $FFFF;
  Lo := 0; Hi := NDecomp - 1;
  While Lo < Hi Do
  Begin
    Mid := (Lo + Hi + 1) Div 2;
    If DecChar[Mid] <= C Then Lo := Mid Else Hi := Mid - 1;
  End;
  If DecChar[Lo] = C Then DecIdx := Lo Else DecIdx := -1;
End;

{ Lettre de base (decomposition complete) ; Mk <- premiere marque }
Function FullBase(C : LongInt; Var Mk : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  Mk := 0;
  N := 0;
  K := DecIdx(C);
  While (K >= 0) And (N < 6) Do
  Begin
    If DecMark[K] <> 0 Then Mk := DecMark[K];
    C := DecBase[K];
    K := DecIdx(C);
    Inc(N);
  End;
  FullBase := C;
End;

{ Composition canonique de A + B ; 0 si aucune }
Function ComposeOf(A, B : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := 0;
  For K := 0 To NDecomp - 1 Do
    If (R = 0) And (DecComp[K] = 1) And (DecBase[K] = A) And (DecMark[K] = B) Then R := DecChar[K];
  ComposeOf := R;
End;

{ Ecriture (CHS_*) d'une lettre ou d'une marque }
Function ScriptOf(C : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 1;
  If C <= $036F Then R := 2
  Else If C <= $03FF Then R := 5
  Else If C <= $052F Then R := 3
  Else If C <= $058F Then R := 14
  Else If C <= $05FF Then R := 6
  Else If C <= $06FF Then R := 4
  Else If (C >= $0750) And (C <= $077F) Then R := 4
  Else If (C >= $08A0) And (C <= $08FF) Then R := 4
  Else If (C >= $0900) And (C <= $097F) Then R := 12
  Else If (C >= $0980) And (C <= $0DFF) Then R := 13
  Else If (C >= $0E00) And (C <= $0E7F) Then R := 7
  Else If (C >= $1100) And (C <= $11FF) Then R := 10
  Else If (C >= $1C80) And (C <= $1C8F) Then R := 3
  Else If (C >= $1D00) And (C <= $1DBF) Then R := 2
  Else If (C >= $1E00) And (C <= $1EFF) Then R := 2
  Else If (C >= $1F00) And (C <= $1FFF) Then R := 5
  Else If (C >= $2C60) And (C <= $2C7F) Then R := 2
  Else If (C >= $2DE0) And (C <= $2DFF) Then R := 3
  Else If (C >= $3005) And (C <= $3007) Then R := 15
  Else If (C >= $3021) And (C <= $3029) Then R := 15
  Else If (C >= $3040) And (C <= $309F) Then R := 9
  Else If (C >= $30A0) And (C <= $30FF) Then R := 8
  Else If (C >= $3100) And (C <= $312F) Then R := 11
  Else If (C >= $3130) And (C <= $318F) Then R := 10
  Else If (C >= $31A0) And (C <= $31BF) Then R := 11
  Else If (C >= $31F0) And (C <= $31FF) Then R := 8
  Else If (C >= $3400) And (C <= $4DBF) Then R := 15
  Else If (C >= $4E00) And (C <= $9FFF) Then R := 15
  Else If (C >= $A640) And (C <= $A69F) Then R := 3
  Else If (C >= $A720) And (C <= $A7FF) Then R := 2
  Else If (C >= $AB30) And (C <= $AB6F) Then R := 2
  Else If (C >= $AC00) And (C <= $D7AF) Then R := 10
  Else If (C >= $F900) And (C <= $FAFF) Then R := 15
  Else If (C >= $FB00) And (C <= $FB06) Then R := 2
  Else If (C >= $FB13) And (C <= $FB17) Then R := 14
  Else If (C >= $FB1D) And (C <= $FB4F) Then R := 6
  Else If (C >= $FB50) And (C <= $FDFF) Then R := 4
  Else If (C >= $FE70) And (C <= $FEFF) Then R := 4
  Else If (C >= $FF21) And (C <= $FF5A) Then R := 2
  Else If (C >= $FF66) And (C <= $FF9F) Then R := 8
  Else If (C >= $FFA0) And (C <= $FFDC) Then R := 10;
  ScriptOf := R;
End;

{ Le caractere est-il dans la page de codes (moitie haute Hi) ? }
Function InCp437(C : LongInt) : Boolean;
Var K : LongInt; Ok : Boolean;
Begin
  Ok := C < $80;
  If (Not Ok) And (C < $2600) Then
    For K := 0 To 127 Do
      If Cp437Hi[K] = C Then Ok := True;
  InCp437 := Ok;
End;

Function InCp850(C : LongInt) : Boolean;
Var K : LongInt; Ok : Boolean;
Begin
  Ok := C < $80;
  If (Not Ok) And (C < $2600) Then
    For K := 0 To 127 Do
      If Cp850Hi[K] = C Then Ok := True;
  InCp850 := Ok;
End;

{ Type UNICTYPE de C : Key1 = itype + bidi shl 16 + charset shl 24,
  Key2 = extend + codepage shl 16 }
Procedure CharType(C : LongInt; Var Key1, Key2 : LongInt);
Var M, Cs, Ex, Cp : LongInt;
Begin
  C := C And $FFFF;
  M := CharMask(C);
  If M = 0 Then Cs := 0
  Else If (M And CT_CNTRL) <> 0 Then Cs := 19
  Else If (M And CT_SPACE) <> 0 Then Cs := 20
  Else If (M And CT_DIGIT) <> 0 Then Cs := 18
  Else If (M And (CT_ALPHA Or CT_MARK)) <> 0 Then Cs := ScriptOf(C)
  Else If (M And CT_SYMBOL) <> 0 Then Cs := 17
  Else If (M And CT_PUNCT) <> 0 Then Cs := 16
  Else Cs := 1;
  Ex := 0;
  If (M And CT_MARK) <> 0 Then
  Begin
    Ex := Ex Or 1;
    If (C >= $0300) And (C <= $036F) Then Ex := Ex Or 2;
    If (C >= $0900) And (C <= $0DFF) Then Ex := Ex Or 4;
  End;
  If (M And CT_SYMBOL) <> 0 Then Ex := Ex Or 8;
  If (Cs = 8) Then Ex := Ex Or $10;
  If (Cs = 9) Then Ex := Ex Or $20;
  If ((C >= $20) And (C <= $7E)) Or ((C >= $FF61) And (C <= $FFDC)) Or ((C >= $FFE8) And (C <= $FFEE)) Then Ex := Ex Or $40;
  If ((C >= $FF01) And (C <= $FF60)) Or ((C >= $FFE0) And (C <= $FFE6)) Or (C = $3000) Then Ex := Ex Or $80;
  If (Cs = 15) Then Ex := Ex Or $100;
  If C = $0640 Then Ex := Ex Or $200;
  If (M And CT_ALPHA) <> 0 Then Ex := Ex Or $8000;
  Cp := 0;
  If InCp437(C) Then Cp := Cp Or 1;
  If InCp850(C) Then Cp := Cp Or 2;
  If C <= $FF Then Cp := Cp Or 4;
  Key1 := (M And $1FF) Or (BidiOf(C) Shl 16) Or (Cs Shl 24);
  Key2 := Ex Or (Cp Shl 16);
End;

{ Rang du type de C dans la table des types (ajoute au besoin) }
Function TypeIndex(C : LongInt) : LongInt;
Var K1, K2, I, R : LongInt;
Begin
  CharType(C, K1, K2);
  R := -1;
  If (TTLast >= 0) And (TTLast < TTN) Then
    If (TTKey1[TTLast] = K1) And (TTKey2[TTLast] = K2) Then R := TTLast;
  I := 0;
  While (R < 0) And (I < TTN) Do
  Begin
    If (TTKey1[I] = K1) And (TTKey2[I] = K2) Then R := I;
    Inc(I);
  End;
  If (R < 0) And (TTN < MaxTT) Then
  Begin
    R := TTN;
    TTKey1[R] := K1;
    TTKey2[R] := K2;
    I := LongInt(@TTab) + R * 8;
    WrW(I, K1 And $FFFF);
    WrB(I + 2, (K1 Shr 16) And $FF);
    WrB(I + 3, (K1 Shr 24) And $FF);
    WrW(I + 4, K2 And $FFFF);
    WrW(I + 6, (K2 Shr 16) And $FFFF);
    Inc(TTN);
  End;
  If R < 0 Then R := 0;
  TTLast := R;
  TypeIndex := R;
End;

{ Nom d'attribut -> bit CT_* (0 : inconnu) }
Function AttrBit(N : String) : LongInt;
Var R : LongInt;
Begin
  N := LowStr(N);
  R := 0;
  If N = 'upper' Then R := CT_UPPER
  Else If N = 'lower' Then R := CT_LOWER
  Else If N = 'digit' Then R := CT_DIGIT
  Else If N = 'space' Then R := CT_SPACE
  Else If N = 'punct' Then R := CT_PUNCT
  Else If N = 'cntrl' Then R := CT_CNTRL
  Else If N = 'blank' Then R := CT_BLANK
  Else If N = 'xdigit' Then R := CT_XDIGIT
  Else If N = 'alpha' Then R := CT_ALPHA
  Else If N = 'alnum' Then R := CT_ALNUM
  Else If N = 'graph' Then R := CT_GRAPH
  Else If N = 'print' Then R := CT_PRINT
  Else If N = 'number' Then R := CT_NUMBER
  Else If N = 'symbol' Then R := CT_SYMBOL
  Else If N = 'ascii' Then R := CT_ASCII;
  AttrBit := R;
End;

{ Liste de noms separes par des espaces -> masque ; -1 si un nom est
  inconnu }
Function AttrMaskOf(S : String) : LongInt;
Var M, K, B : LongInt; W : String;
Begin
  M := 0;
  S := S + ' ';
  W := '';
  For K := 1 To Length(S) Do
    If Ord(S[K]) = 32 Then
    Begin
      If W <> '' Then
      Begin
        B := AttrBit(W);
        If B = 0 Then M := -1 Else If M >= 0 Then M := M Or B;
      End;
      W := '';
    End
    Else W := W + S[K];
  If M = 0 Then M := -1;
  AttrMaskOf := M;
End;

{ ==================================================================== }
{ Partie 5 - Locales (donnees, objets, elements)                       }
{ ==================================================================== }

{ --- cases de chaines (longueur, caracteres) --- }
Function SlotGet(A, Size : LongInt) : String;
Var S : String; K, N : LongInt;
Begin
  S := '';
  N := RdB(A);
  If N > Size - 1 Then N := Size - 1;
  For K := 1 To N Do S := S + Chr(RdB(A + K));
  SlotGet := S;
End;

Procedure SlotSet(A, Size : LongInt; S : String);
Var K : LongInt;
Begin
  If Length(S) > Size - 1 Then S := Copy(S, 1, Size - 1);
  WrB(A, Length(S));
  For K := 1 To Length(S) Do WrB(A + K, Ord(S[K]));
End;

Function LGet(I : LongInt) : String;
Begin
  LGet := SlotGet(LongInt(@LBuf) + I * 64, 64);
End;

Procedure LSet(I : LongInt; S : String);
Begin
  SlotSet(LongInt(@LBuf) + I * 64, 64, S);
End;

Function LangGet(I : LongInt) : String;
Begin
  LangGet := SlotGet(LongInt(@LangBuf) + I * 32, 32);
End;

Procedure LangSet(I : LongInt; S : String);
Begin
  SlotSet(LongInt(@LangBuf) + I * 32, 32, S);
End;

Function CtryGet(I : LongInt) : String;
Begin
  CtryGet := SlotGet(LongInt(@CtryBuf) + I * 32, 32);
End;

Procedure CtrySet(I : LongInt; S : String);
Begin
  SlotSet(LongInt(@CtryBuf) + I * 32, 32, S);
End;

Function OvGet(I : LongInt) : String;
Begin
  OvGet := SlotGet(LongInt(@OvBuf) + I * 128, 128);
End;

Procedure OvSet(I : LongInt; S : String);
Begin
  SlotSet(LongInt(@OvBuf) + I * 128, 128, S);
End;

Procedure SetF(L, F : LongInt; S : String);
Begin
  LSet(L * NF + F, Unesc(S));
End;

Procedure SetL(L, F : LongInt; S : String);
Begin
  LangSet(L * NLF + F, Unesc(S));
End;

Procedure SetC(L, F : LongInt; S : String);
Begin
  CtrySet(L * 5 + F, Unesc(S));
End;

Procedure InitLocData;
Begin
  SetF(0, 0, 'C');
  SetF(0, 1, 'en');
  SetF(0, 3, '0');
  SetF(0, 4, 'IBM-437');
  SetF(0, 5, '%a %b %e %H:%M:%S %Y');
  SetF(0, 6, '%m/%d/%y');
  SetF(0, 7, '%H:%M:%S');
  SetF(0, 8, 'AM');
  SetF(0, 9, 'PM');
  SetF(0, 10, '.');
  SetF(0, 20, '-1');
  SetF(0, 21, '-1');
  SetF(0, 22, '-1');
  SetF(0, 23, '-1');
  SetF(0, 24, '-1');
  SetF(0, 25, '-1');
  SetF(0, 26, '-1');
  SetF(0, 27, 'yes');
  SetF(0, 28, 'no');
  SetF(0, 29, '/');
  SetF(0, 30, ',');
  SetF(0, 31, '%A, %B %d, %Y');
  SetF(0, 32, 'ENU');
  SetF(0, 33, 'US');
  SetF(0, 34, '0409');
  SetF(0, 35, '437');
  SetF(0, 36, '37');
  SetF(0, 37, '1');
  SetF(0, 38, '9');
  SetF(0, 39, '6');
  SetF(0, 40, '0');
  SetF(0, 42, 'HH:mm:ss');
  SetF(0, 43, 'MM/dd/yy');
  SetF(0, 44, 'dddd, MMMM dd, yyyy');
  SetF(0, 45, '0');
  SetF(0, 46, '1');
  SetF(0, 47, '0');
  SetF(0, 48, '^[yY]');
  SetF(0, 49, '^[nN]');
  SetF(0, 50, '-1');
  SetF(1, 0, 'POSIX');
  SetF(1, 1, 'en');
  SetF(1, 3, '0');
  SetF(1, 4, 'IBM-437');
  SetF(1, 5, '%a %b %e %H:%M:%S %Y');
  SetF(1, 6, '%m/%d/%y');
  SetF(1, 7, '%H:%M:%S');
  SetF(1, 8, 'AM');
  SetF(1, 9, 'PM');
  SetF(1, 10, '.');
  SetF(1, 20, '-1');
  SetF(1, 21, '-1');
  SetF(1, 22, '-1');
  SetF(1, 23, '-1');
  SetF(1, 24, '-1');
  SetF(1, 25, '-1');
  SetF(1, 26, '-1');
  SetF(1, 27, 'yes');
  SetF(1, 28, 'no');
  SetF(1, 29, '/');
  SetF(1, 30, ',');
  SetF(1, 31, '%A, %B %d, %Y');
  SetF(1, 32, 'ENU');
  SetF(1, 33, 'US');
  SetF(1, 34, '0409');
  SetF(1, 35, '437');
  SetF(1, 36, '37');
  SetF(1, 37, '1');
  SetF(1, 38, '9');
  SetF(1, 39, '6');
  SetF(1, 40, '0');
  SetF(1, 42, 'HH:mm:ss');
  SetF(1, 43, 'MM/dd/yy');
  SetF(1, 44, 'dddd, MMMM dd, yyyy');
  SetF(1, 45, '0');
  SetF(1, 46, '1');
  SetF(1, 47, '0');
  SetF(1, 48, '^[yY]');
  SetF(1, 49, '^[nN]');
  SetF(1, 50, '-1');
  SetF(2, 0, 'UNIVERSAL');
  SetF(2, 1, 'en');
  SetF(2, 3, '0');
  SetF(2, 4, 'UCS-2');
  SetF(2, 5, '%Y-%m-%d %H:%M:%S');
  SetF(2, 6, '%Y-%m-%d');
  SetF(2, 7, '%H:%M:%S');
  SetF(2, 8, 'AM');
  SetF(2, 9, 'PM');
  SetF(2, 10, '.');
  SetF(2, 20, '-1');
  SetF(2, 21, '-1');
  SetF(2, 22, '-1');
  SetF(2, 23, '-1');
  SetF(2, 24, '-1');
  SetF(2, 25, '-1');
  SetF(2, 26, '-1');
  SetF(2, 27, 'yes');
  SetF(2, 28, 'no');
  SetF(2, 29, '-');
  SetF(2, 30, ',');
  SetF(2, 31, '%A %d %B %Y');
  SetF(2, 32, 'ENU');
  SetF(2, 33, 'US');
  SetF(2, 34, '0409');
  SetF(2, 35, '437');
  SetF(2, 36, '37');
  SetF(2, 37, '1');
  SetF(2, 38, '9');
  SetF(2, 39, '6');
  SetF(2, 40, '0');
  SetF(2, 42, 'HH:mm:ss');
  SetF(2, 43, 'yyyy-MM-dd');
  SetF(2, 44, 'dddd, MMMM dd, yyyy');
  SetF(2, 45, '0');
  SetF(2, 46, '1');
  SetF(2, 47, '2');
  SetF(2, 48, '^[yY]');
  SetF(2, 49, '^[nN]');
  SetF(2, 50, '-1');
  SetF(3, 0, 'en_US');
  SetF(3, 1, 'en');
  SetF(3, 2, 'US');
  SetF(3, 3, '1');
  SetF(3, 4, 'IBM-437');
  SetF(3, 5, '%a %d %b %Y %I:%M:%S %p');
  SetF(3, 6, '%m/%d/%Y');
  SetF(3, 7, '%I:%M:%S %p');
  SetF(3, 8, 'AM');
  SetF(3, 9, 'PM');
  SetF(3, 10, '.');
  SetF(3, 11, ',');
  SetF(3, 12, '3');
  SetF(3, 13, '$');
  SetF(3, 14, 'USD ');
  SetF(3, 15, '.');
  SetF(3, 16, ',');
  SetF(3, 17, '3');
  SetF(3, 19, '-');
  SetF(3, 20, '2');
  SetF(3, 21, '1');
  SetF(3, 22, '0');
  SetF(3, 23, '1');
  SetF(3, 24, '0');
  SetF(3, 25, '1');
  SetF(3, 26, '1');
  SetF(3, 27, 'yes');
  SetF(3, 28, 'no');
  SetF(3, 29, '/');
  SetF(3, 30, ',');
  SetF(3, 31, '%A, %B %d, %Y');
  SetF(3, 32, 'ENU');
  SetF(3, 33, 'US');
  SetF(3, 34, '0409');
  SetF(3, 35, '437');
  SetF(3, 36, '37');
  SetF(3, 37, '2');
  SetF(3, 38, '1');
  SetF(3, 39, '6');
  SetF(3, 40, '0');
  SetF(3, 41, 'USA');
  SetF(3, 42, 'h:mm:ss tt');
  SetF(3, 43, 'M/d/yyyy');
  SetF(3, 44, 'dddd, MMMM dd, yyyy');
  SetF(3, 45, '0');
  SetF(3, 46, '0');
  SetF(3, 47, '0');
  SetF(3, 48, '^[yY]');
  SetF(3, 49, '^[nN]');
  SetF(3, 50, '2');
  SetF(3, 51, 'DB');
  SetF(3, 52, 'CR');
  SetF(4, 0, 'en_GB');
  SetF(4, 1, 'en');
  SetF(4, 2, 'GB');
  SetF(4, 3, '44');
  SetF(4, 4, 'IBM-850');
  SetF(4, 5, '%a %d %b %Y %H:%M:%S');
  SetF(4, 6, '%d/%m/%Y');
  SetF(4, 7, '%H:%M:%S');
  SetF(4, 8, 'am');
  SetF(4, 9, 'pm');
  SetF(4, 10, '.');
  SetF(4, 11, ',');
  SetF(4, 12, '3');
  SetF(4, 13, '#A3');
  SetF(4, 14, 'GBP ');
  SetF(4, 15, '.');
  SetF(4, 16, ',');
  SetF(4, 17, '3');
  SetF(4, 19, '-');
  SetF(4, 20, '2');
  SetF(4, 21, '1');
  SetF(4, 22, '0');
  SetF(4, 23, '1');
  SetF(4, 24, '0');
  SetF(4, 25, '1');
  SetF(4, 26, '1');
  SetF(4, 27, 'yes');
  SetF(4, 28, 'no');
  SetF(4, 29, '/');
  SetF(4, 30, ',');
  SetF(4, 31, '%A, %d %B %Y');
  SetF(4, 32, 'ENG');
  SetF(4, 33, 'UK');
  SetF(4, 34, '0809');
  SetF(4, 35, '850');
  SetF(4, 36, '285');
  SetF(4, 37, '1');
  SetF(4, 38, '9');
  SetF(4, 39, '0');
  SetF(4, 40, '2');
  SetF(4, 41, 'GBR');
  SetF(4, 42, 'HH:mm:ss');
  SetF(4, 43, 'dd/MM/yyyy');
  SetF(4, 44, 'dd MMMM yyyy');
  SetF(4, 45, '1');
  SetF(4, 46, '1');
  SetF(4, 47, '1');
  SetF(4, 48, '^[yY]');
  SetF(4, 49, '^[nN]');
  SetF(4, 50, '2');
  SetF(4, 51, 'DB');
  SetF(4, 52, 'CR');
  SetF(5, 0, 'fr_FR');
  SetF(5, 1, 'fr');
  SetF(5, 2, 'FR');
  SetF(5, 3, '33');
  SetF(5, 4, 'IBM-850');
  SetF(5, 5, '%a %d %b %Y %H:%M:%S');
  SetF(5, 6, '%d/%m/%Y');
  SetF(5, 7, '%H:%M:%S');
  SetF(5, 10, ',');
  SetF(5, 11, ' ');
  SetF(5, 12, '3');
  SetF(5, 13, '#80');
  SetF(5, 14, 'EUR ');
  SetF(5, 15, ',');
  SetF(5, 16, ' ');
  SetF(5, 17, '3');
  SetF(5, 19, '-');
  SetF(5, 20, '2');
  SetF(5, 21, '0');
  SetF(5, 22, '1');
  SetF(5, 23, '0');
  SetF(5, 24, '1');
  SetF(5, 25, '1');
  SetF(5, 26, '1');
  SetF(5, 27, 'oui');
  SetF(5, 28, 'non');
  SetF(5, 29, '/');
  SetF(5, 30, ';');
  SetF(5, 31, '%A %d %B %Y');
  SetF(5, 32, 'FRA');
  SetF(5, 33, 'FR');
  SetF(5, 34, '040C');
  SetF(5, 35, '850');
  SetF(5, 36, '297');
  SetF(5, 37, '1');
  SetF(5, 38, '9');
  SetF(5, 39, '0');
  SetF(5, 40, '2');
  SetF(5, 41, 'FRA');
  SetF(5, 42, 'HH:mm:ss');
  SetF(5, 43, 'dd/MM/yyyy');
  SetF(5, 44, 'dddd d MMMM yyyy');
  SetF(5, 45, '8');
  SetF(5, 46, '1');
  SetF(5, 47, '1');
  SetF(5, 48, '^[oOyY]');
  SetF(5, 49, '^[nN]');
  SetF(5, 50, '2');
  SetF(5, 51, 'DB');
  SetF(5, 52, 'CR');
  SetF(6, 0, 'fr_CA');
  SetF(6, 1, 'fr');
  SetF(6, 2, 'CA');
  SetF(6, 3, '2');
  SetF(6, 4, 'IBM-850');
  SetF(6, 5, '%a %d %b %Y %H:%M:%S');
  SetF(6, 6, '%Y-%m-%d');
  SetF(6, 7, '%H:%M:%S');
  SetF(6, 10, ',');
  SetF(6, 11, ' ');
  SetF(6, 12, '3');
  SetF(6, 13, '$');
  SetF(6, 14, 'CAD ');
  SetF(6, 15, ',');
  SetF(6, 16, ' ');
  SetF(6, 17, '3');
  SetF(6, 19, '-');
  SetF(6, 20, '2');
  SetF(6, 21, '0');
  SetF(6, 22, '1');
  SetF(6, 23, '0');
  SetF(6, 24, '1');
  SetF(6, 25, '1');
  SetF(6, 26, '1');
  SetF(6, 27, 'oui');
  SetF(6, 28, 'non');
  SetF(6, 29, '-');
  SetF(6, 30, ';');
  SetF(6, 31, '%A %d %B %Y');
  SetF(6, 32, 'FRC');
  SetF(6, 33, 'CF');
  SetF(6, 34, '0C0C');
  SetF(6, 35, '863');
  SetF(6, 36, '37');
  SetF(6, 37, '1');
  SetF(6, 38, '1');
  SetF(6, 39, '6');
  SetF(6, 40, '0');
  SetF(6, 41, 'CAN');
  SetF(6, 42, 'HH:mm:ss');
  SetF(6, 43, 'yyyy-MM-dd');
  SetF(6, 44, 'd MMMM yyyy');
  SetF(6, 45, '15');
  SetF(6, 46, '1');
  SetF(6, 47, '2');
  SetF(6, 48, '^[oOyY]');
  SetF(6, 49, '^[nN]');
  SetF(6, 50, '2');
  SetF(6, 51, 'DB');
  SetF(6, 52, 'CR');
  SetF(7, 0, 'de_DE');
  SetF(7, 1, 'de');
  SetF(7, 2, 'DE');
  SetF(7, 3, '49');
  SetF(7, 4, 'IBM-850');
  SetF(7, 5, '%a %d %b %Y %H:%M:%S');
  SetF(7, 6, '%d.%m.%Y');
  SetF(7, 7, '%H:%M:%S');
  SetF(7, 10, ',');
  SetF(7, 11, '.');
  SetF(7, 12, '3');
  SetF(7, 13, '#80');
  SetF(7, 14, 'EUR ');
  SetF(7, 15, ',');
  SetF(7, 16, '.');
  SetF(7, 17, '3');
  SetF(7, 19, '-');
  SetF(7, 20, '2');
  SetF(7, 21, '0');
  SetF(7, 22, '1');
  SetF(7, 23, '0');
  SetF(7, 24, '1');
  SetF(7, 25, '1');
  SetF(7, 26, '1');
  SetF(7, 27, 'ja');
  SetF(7, 28, 'nein');
  SetF(7, 29, '.');
  SetF(7, 30, ';');
  SetF(7, 31, '%A, %d. %B %Y');
  SetF(7, 32, 'DEU');
  SetF(7, 33, 'GR');
  SetF(7, 34, '0407');
  SetF(7, 35, '850');
  SetF(7, 36, '273');
  SetF(7, 37, '1');
  SetF(7, 38, '9');
  SetF(7, 39, '0');
  SetF(7, 40, '2');
  SetF(7, 41, 'DEU');
  SetF(7, 42, 'HH:mm:ss');
  SetF(7, 43, 'dd.MM.yyyy');
  SetF(7, 44, 'dddd, d. MMMM yyyy');
  SetF(7, 45, '8');
  SetF(7, 46, '1');
  SetF(7, 47, '1');
  SetF(7, 48, '^[jJyY]');
  SetF(7, 49, '^[nN]');
  SetF(7, 50, '2');
  SetF(7, 51, 'DB');
  SetF(7, 52, 'CR');
  SetF(8, 0, 'es_ES');
  SetF(8, 1, 'es');
  SetF(8, 2, 'ES');
  SetF(8, 3, '34');
  SetF(8, 4, 'IBM-850');
  SetF(8, 5, '%a %d %b %Y %H:%M:%S');
  SetF(8, 6, '%d/%m/%Y');
  SetF(8, 7, '%H:%M:%S');
  SetF(8, 10, ',');
  SetF(8, 11, '.');
  SetF(8, 12, '3');
  SetF(8, 13, '#80');
  SetF(8, 14, 'EUR ');
  SetF(8, 15, ',');
  SetF(8, 16, '.');
  SetF(8, 17, '3');
  SetF(8, 19, '-');
  SetF(8, 20, '2');
  SetF(8, 21, '0');
  SetF(8, 22, '1');
  SetF(8, 23, '0');
  SetF(8, 24, '1');
  SetF(8, 25, '1');
  SetF(8, 26, '1');
  SetF(8, 27, 's#ED');
  SetF(8, 28, 'no');
  SetF(8, 29, '/');
  SetF(8, 30, ';');
  SetF(8, 31, '%A, %d de %B de %Y');
  SetF(8, 32, 'ESP');
  SetF(8, 33, 'SP');
  SetF(8, 34, '0C0A');
  SetF(8, 35, '850');
  SetF(8, 36, '284');
  SetF(8, 37, '1');
  SetF(8, 38, '9');
  SetF(8, 39, '0');
  SetF(8, 40, '2');
  SetF(8, 41, 'ESP');
  SetF(8, 42, 'H:mm:ss');
  SetF(8, 43, 'dd/MM/yyyy');
  SetF(8, 44, 'dddd d MMMM yyyy');
  SetF(8, 45, '8');
  SetF(8, 46, '1');
  SetF(8, 47, '1');
  SetF(8, 48, '^[sSyY]');
  SetF(8, 49, '^[nN]');
  SetF(8, 50, '2');
  SetF(8, 51, 'DB');
  SetF(8, 52, 'CR');
  SetF(9, 0, 'it_IT');
  SetF(9, 1, 'it');
  SetF(9, 2, 'IT');
  SetF(9, 3, '39');
  SetF(9, 4, 'IBM-850');
  SetF(9, 5, '%a %d %b %Y %H:%M:%S');
  SetF(9, 6, '%d/%m/%Y');
  SetF(9, 7, '%H:%M:%S');
  SetF(9, 10, ',');
  SetF(9, 11, '.');
  SetF(9, 12, '3');
  SetF(9, 13, '#80');
  SetF(9, 14, 'EUR ');
  SetF(9, 15, ',');
  SetF(9, 16, '.');
  SetF(9, 17, '3');
  SetF(9, 19, '-');
  SetF(9, 20, '2');
  SetF(9, 21, '1');
  SetF(9, 22, '1');
  SetF(9, 23, '1');
  SetF(9, 24, '1');
  SetF(9, 25, '1');
  SetF(9, 26, '1');
  SetF(9, 27, 's#EC');
  SetF(9, 28, 'no');
  SetF(9, 29, '/');
  SetF(9, 30, ';');
  SetF(9, 31, '%A %d %B %Y');
  SetF(9, 32, 'ITA');
  SetF(9, 33, 'IT');
  SetF(9, 34, '0410');
  SetF(9, 35, '850');
  SetF(9, 36, '280');
  SetF(9, 37, '1');
  SetF(9, 38, '9');
  SetF(9, 39, '0');
  SetF(9, 40, '2');
  SetF(9, 41, 'ITA');
  SetF(9, 42, 'HH:mm:ss');
  SetF(9, 43, 'dd/MM/yyyy');
  SetF(9, 44, 'dddd d MMMM yyyy');
  SetF(9, 45, '9');
  SetF(9, 46, '1');
  SetF(9, 47, '1');
  SetF(9, 48, '^[sSyY]');
  SetF(9, 49, '^[nN]');
  SetF(9, 50, '2');
  SetF(9, 51, 'DB');
  SetF(9, 52, 'CR');
  SetF(10, 0, 'nl_NL');
  SetF(10, 1, 'nl');
  SetF(10, 2, 'NL');
  SetF(10, 3, '31');
  SetF(10, 4, 'IBM-850');
  SetF(10, 5, '%a %d %b %Y %H:%M:%S');
  SetF(10, 6, '%d-%m-%Y');
  SetF(10, 7, '%H:%M:%S');
  SetF(10, 10, ',');
  SetF(10, 11, '.');
  SetF(10, 12, '3');
  SetF(10, 13, '#80');
  SetF(10, 14, 'EUR ');
  SetF(10, 15, ',');
  SetF(10, 16, '.');
  SetF(10, 17, '3');
  SetF(10, 19, '-');
  SetF(10, 20, '2');
  SetF(10, 21, '1');
  SetF(10, 22, '1');
  SetF(10, 23, '1');
  SetF(10, 24, '1');
  SetF(10, 25, '1');
  SetF(10, 26, '1');
  SetF(10, 27, 'ja');
  SetF(10, 28, 'nee');
  SetF(10, 29, '-');
  SetF(10, 30, ';');
  SetF(10, 31, '%A %d %B %Y');
  SetF(10, 32, 'NLD');
  SetF(10, 33, 'NL');
  SetF(10, 34, '0413');
  SetF(10, 35, '850');
  SetF(10, 36, '37');
  SetF(10, 37, '1');
  SetF(10, 38, '9');
  SetF(10, 39, '0');
  SetF(10, 40, '2');
  SetF(10, 41, 'NLD');
  SetF(10, 42, 'H:mm:ss');
  SetF(10, 43, 'd-M-yyyy');
  SetF(10, 44, 'dddd d MMMM yyyy');
  SetF(10, 45, '11');
  SetF(10, 46, '1');
  SetF(10, 47, '1');
  SetF(10, 48, '^[jJyY]');
  SetF(10, 49, '^[nN]');
  SetF(10, 50, '2');
  SetF(10, 51, 'DB');
  SetF(10, 52, 'CR');
  SetF(11, 0, 'pt_BR');
  SetF(11, 1, 'pt');
  SetF(11, 2, 'BR');
  SetF(11, 3, '55');
  SetF(11, 4, 'IBM-850');
  SetF(11, 5, '%a %d %b %Y %H:%M:%S');
  SetF(11, 6, '%d/%m/%Y');
  SetF(11, 7, '%H:%M:%S');
  SetF(11, 10, ',');
  SetF(11, 11, '.');
  SetF(11, 12, '3');
  SetF(11, 13, 'R$');
  SetF(11, 14, 'BRL ');
  SetF(11, 15, ',');
  SetF(11, 16, '.');
  SetF(11, 17, '3');
  SetF(11, 19, '-');
  SetF(11, 20, '2');
  SetF(11, 21, '1');
  SetF(11, 22, '1');
  SetF(11, 23, '1');
  SetF(11, 24, '1');
  SetF(11, 25, '1');
  SetF(11, 26, '1');
  SetF(11, 27, 'sim');
  SetF(11, 28, 'n#E3o');
  SetF(11, 29, '/');
  SetF(11, 30, ';');
  SetF(11, 31, '%A, %d de %B de %Y');
  SetF(11, 32, 'PTB');
  SetF(11, 33, 'BR');
  SetF(11, 34, '0416');
  SetF(11, 35, '850');
  SetF(11, 36, '37');
  SetF(11, 37, '1');
  SetF(11, 38, '9');
  SetF(11, 39, '6');
  SetF(11, 40, '0');
  SetF(11, 41, 'BRA');
  SetF(11, 42, 'HH:mm:ss');
  SetF(11, 43, 'dd/MM/yyyy');
  SetF(11, 44, 'dddd d MMMM yyyy');
  SetF(11, 45, '9');
  SetF(11, 46, '1');
  SetF(11, 47, '1');
  SetF(11, 48, '^[sSyY]');
  SetF(11, 49, '^[nN]');
  SetF(11, 50, '2');
  SetF(11, 51, 'DB');
  SetF(11, 52, 'CR');
End;

Procedure InitLangData;
Begin
  LangCode[0] := 'en';
  SetL(0, 0, 'Sunday');
  SetL(0, 1, 'Monday');
  SetL(0, 2, 'Tuesday');
  SetL(0, 3, 'Wednesday');
  SetL(0, 4, 'Thursday');
  SetL(0, 5, 'Friday');
  SetL(0, 6, 'Saturday');
  SetL(0, 7, 'Sun');
  SetL(0, 8, 'Mon');
  SetL(0, 9, 'Tue');
  SetL(0, 10, 'Wed');
  SetL(0, 11, 'Thu');
  SetL(0, 12, 'Fri');
  SetL(0, 13, 'Sat');
  SetL(0, 14, 'January');
  SetL(0, 15, 'February');
  SetL(0, 16, 'March');
  SetL(0, 17, 'April');
  SetL(0, 18, 'May');
  SetL(0, 19, 'June');
  SetL(0, 20, 'July');
  SetL(0, 21, 'August');
  SetL(0, 22, 'September');
  SetL(0, 23, 'October');
  SetL(0, 24, 'November');
  SetL(0, 25, 'December');
  SetL(0, 26, 'Jan');
  SetL(0, 27, 'Feb');
  SetL(0, 28, 'Mar');
  SetL(0, 29, 'Apr');
  SetL(0, 30, 'May');
  SetL(0, 31, 'Jun');
  SetL(0, 32, 'Jul');
  SetL(0, 33, 'Aug');
  SetL(0, 34, 'Sep');
  SetL(0, 35, 'Oct');
  SetL(0, 36, 'Nov');
  SetL(0, 37, 'Dec');
  SetL(0, 38, 'English');
  SetL(0, 39, 'anglais');
  SetL(0, 40, 'English');
  LangCode[1] := 'fr';
  SetL(1, 0, 'dimanche');
  SetL(1, 1, 'lundi');
  SetL(1, 2, 'mardi');
  SetL(1, 3, 'mercredi');
  SetL(1, 4, 'jeudi');
  SetL(1, 5, 'vendredi');
  SetL(1, 6, 'samedi');
  SetL(1, 7, 'dim.');
  SetL(1, 8, 'lun.');
  SetL(1, 9, 'mar.');
  SetL(1, 10, 'mer.');
  SetL(1, 11, 'jeu.');
  SetL(1, 12, 'ven.');
  SetL(1, 13, 'sam.');
  SetL(1, 14, 'janvier');
  SetL(1, 15, 'f#E9vrier');
  SetL(1, 16, 'mars');
  SetL(1, 17, 'avril');
  SetL(1, 18, 'mai');
  SetL(1, 19, 'juin');
  SetL(1, 20, 'juillet');
  SetL(1, 21, 'ao#FBt');
  SetL(1, 22, 'septembre');
  SetL(1, 23, 'octobre');
  SetL(1, 24, 'novembre');
  SetL(1, 25, 'd#E9cembre');
  SetL(1, 26, 'janv.');
  SetL(1, 27, 'f#E9vr.');
  SetL(1, 28, 'mars');
  SetL(1, 29, 'avr.');
  SetL(1, 30, 'mai');
  SetL(1, 31, 'juin');
  SetL(1, 32, 'juil.');
  SetL(1, 33, 'ao#FBt');
  SetL(1, 34, 'sept.');
  SetL(1, 35, 'oct.');
  SetL(1, 36, 'nov.');
  SetL(1, 37, 'd#E9c.');
  SetL(1, 38, 'French');
  SetL(1, 39, 'fran#E7ais');
  SetL(1, 40, 'fran#E7ais');
  LangCode[2] := 'de';
  SetL(2, 0, 'Sonntag');
  SetL(2, 1, 'Montag');
  SetL(2, 2, 'Dienstag');
  SetL(2, 3, 'Mittwoch');
  SetL(2, 4, 'Donnerstag');
  SetL(2, 5, 'Freitag');
  SetL(2, 6, 'Samstag');
  SetL(2, 7, 'So');
  SetL(2, 8, 'Mo');
  SetL(2, 9, 'Di');
  SetL(2, 10, 'Mi');
  SetL(2, 11, 'Do');
  SetL(2, 12, 'Fr');
  SetL(2, 13, 'Sa');
  SetL(2, 14, 'Januar');
  SetL(2, 15, 'Februar');
  SetL(2, 16, 'M#E4rz');
  SetL(2, 17, 'April');
  SetL(2, 18, 'Mai');
  SetL(2, 19, 'Juni');
  SetL(2, 20, 'Juli');
  SetL(2, 21, 'August');
  SetL(2, 22, 'September');
  SetL(2, 23, 'Oktober');
  SetL(2, 24, 'November');
  SetL(2, 25, 'Dezember');
  SetL(2, 26, 'Jan');
  SetL(2, 27, 'Feb');
  SetL(2, 28, 'M#E4r');
  SetL(2, 29, 'Apr');
  SetL(2, 30, 'Mai');
  SetL(2, 31, 'Jun');
  SetL(2, 32, 'Jul');
  SetL(2, 33, 'Aug');
  SetL(2, 34, 'Sep');
  SetL(2, 35, 'Okt');
  SetL(2, 36, 'Nov');
  SetL(2, 37, 'Dez');
  SetL(2, 38, 'German');
  SetL(2, 39, 'allemand');
  SetL(2, 40, 'Deutsch');
  LangCode[3] := 'es';
  SetL(3, 0, 'domingo');
  SetL(3, 1, 'lunes');
  SetL(3, 2, 'martes');
  SetL(3, 3, 'mi#E9rcoles');
  SetL(3, 4, 'jueves');
  SetL(3, 5, 'viernes');
  SetL(3, 6, 's#E1bado');
  SetL(3, 7, 'dom');
  SetL(3, 8, 'lun');
  SetL(3, 9, 'mar');
  SetL(3, 10, 'mi#E9');
  SetL(3, 11, 'jue');
  SetL(3, 12, 'vie');
  SetL(3, 13, 's#E1b');
  SetL(3, 14, 'enero');
  SetL(3, 15, 'febrero');
  SetL(3, 16, 'marzo');
  SetL(3, 17, 'abril');
  SetL(3, 18, 'mayo');
  SetL(3, 19, 'junio');
  SetL(3, 20, 'julio');
  SetL(3, 21, 'agosto');
  SetL(3, 22, 'septiembre');
  SetL(3, 23, 'octubre');
  SetL(3, 24, 'noviembre');
  SetL(3, 25, 'diciembre');
  SetL(3, 26, 'ene');
  SetL(3, 27, 'feb');
  SetL(3, 28, 'mar');
  SetL(3, 29, 'abr');
  SetL(3, 30, 'may');
  SetL(3, 31, 'jun');
  SetL(3, 32, 'jul');
  SetL(3, 33, 'ago');
  SetL(3, 34, 'sep');
  SetL(3, 35, 'oct');
  SetL(3, 36, 'nov');
  SetL(3, 37, 'dic');
  SetL(3, 38, 'Spanish');
  SetL(3, 39, 'espagnol');
  SetL(3, 40, 'espa#F1ol');
  LangCode[4] := 'it';
  SetL(4, 0, 'domenica');
  SetL(4, 1, 'luned#EC');
  SetL(4, 2, 'marted#EC');
  SetL(4, 3, 'mercoled#EC');
  SetL(4, 4, 'gioved#EC');
  SetL(4, 5, 'venerd#EC');
  SetL(4, 6, 'sabato');
  SetL(4, 7, 'dom');
  SetL(4, 8, 'lun');
  SetL(4, 9, 'mar');
  SetL(4, 10, 'mer');
  SetL(4, 11, 'gio');
  SetL(4, 12, 'ven');
  SetL(4, 13, 'sab');
  SetL(4, 14, 'gennaio');
  SetL(4, 15, 'febbraio');
  SetL(4, 16, 'marzo');
  SetL(4, 17, 'aprile');
  SetL(4, 18, 'maggio');
  SetL(4, 19, 'giugno');
  SetL(4, 20, 'luglio');
  SetL(4, 21, 'agosto');
  SetL(4, 22, 'settembre');
  SetL(4, 23, 'ottobre');
  SetL(4, 24, 'novembre');
  SetL(4, 25, 'dicembre');
  SetL(4, 26, 'gen');
  SetL(4, 27, 'feb');
  SetL(4, 28, 'mar');
  SetL(4, 29, 'apr');
  SetL(4, 30, 'mag');
  SetL(4, 31, 'giu');
  SetL(4, 32, 'lug');
  SetL(4, 33, 'ago');
  SetL(4, 34, 'set');
  SetL(4, 35, 'ott');
  SetL(4, 36, 'nov');
  SetL(4, 37, 'dic');
  SetL(4, 38, 'Italian');
  SetL(4, 39, 'italien');
  SetL(4, 40, 'italiano');
  LangCode[5] := 'nl';
  SetL(5, 0, 'zondag');
  SetL(5, 1, 'maandag');
  SetL(5, 2, 'dinsdag');
  SetL(5, 3, 'woensdag');
  SetL(5, 4, 'donderdag');
  SetL(5, 5, 'vrijdag');
  SetL(5, 6, 'zaterdag');
  SetL(5, 7, 'zo');
  SetL(5, 8, 'ma');
  SetL(5, 9, 'di');
  SetL(5, 10, 'wo');
  SetL(5, 11, 'do');
  SetL(5, 12, 'vr');
  SetL(5, 13, 'za');
  SetL(5, 14, 'januari');
  SetL(5, 15, 'februari');
  SetL(5, 16, 'maart');
  SetL(5, 17, 'april');
  SetL(5, 18, 'mei');
  SetL(5, 19, 'juni');
  SetL(5, 20, 'juli');
  SetL(5, 21, 'augustus');
  SetL(5, 22, 'september');
  SetL(5, 23, 'oktober');
  SetL(5, 24, 'november');
  SetL(5, 25, 'december');
  SetL(5, 26, 'jan');
  SetL(5, 27, 'feb');
  SetL(5, 28, 'mrt');
  SetL(5, 29, 'apr');
  SetL(5, 30, 'mei');
  SetL(5, 31, 'jun');
  SetL(5, 32, 'jul');
  SetL(5, 33, 'aug');
  SetL(5, 34, 'sep');
  SetL(5, 35, 'okt');
  SetL(5, 36, 'nov');
  SetL(5, 37, 'dec');
  SetL(5, 38, 'Dutch');
  SetL(5, 39, 'n#E9erlandais');
  SetL(5, 40, 'Nederlands');
  LangCode[6] := 'pt';
  SetL(6, 0, 'domingo');
  SetL(6, 1, 'segunda-feira');
  SetL(6, 2, 'ter#E7a-feira');
  SetL(6, 3, 'quarta-feira');
  SetL(6, 4, 'quinta-feira');
  SetL(6, 5, 'sexta-feira');
  SetL(6, 6, 's#E1bado');
  SetL(6, 7, 'dom');
  SetL(6, 8, 'seg');
  SetL(6, 9, 'ter');
  SetL(6, 10, 'qua');
  SetL(6, 11, 'qui');
  SetL(6, 12, 'sex');
  SetL(6, 13, 's#E1b');
  SetL(6, 14, 'janeiro');
  SetL(6, 15, 'fevereiro');
  SetL(6, 16, 'mar#E7o');
  SetL(6, 17, 'abril');
  SetL(6, 18, 'maio');
  SetL(6, 19, 'junho');
  SetL(6, 20, 'julho');
  SetL(6, 21, 'agosto');
  SetL(6, 22, 'setembro');
  SetL(6, 23, 'outubro');
  SetL(6, 24, 'novembro');
  SetL(6, 25, 'dezembro');
  SetL(6, 26, 'jan');
  SetL(6, 27, 'fev');
  SetL(6, 28, 'mar');
  SetL(6, 29, 'abr');
  SetL(6, 30, 'mai');
  SetL(6, 31, 'jun');
  SetL(6, 32, 'jul');
  SetL(6, 33, 'ago');
  SetL(6, 34, 'set');
  SetL(6, 35, 'out');
  SetL(6, 36, 'nov');
  SetL(6, 37, 'dez');
  SetL(6, 38, 'Portuguese');
  SetL(6, 39, 'portugais');
  SetL(6, 40, 'portugu#EAs');
  SetC(0, 0, 'US');
  SetC(0, 1, 'United States');
  SetC(0, 2, '#C9tats-Unis');
  SetC(0, 3, 'United States');
  SetC(0, 4, 'en');
  SetC(1, 0, 'GB');
  SetC(1, 1, 'United Kingdom');
  SetC(1, 2, 'Royaume-Uni');
  SetC(1, 3, 'United Kingdom');
  SetC(1, 4, 'en');
  SetC(2, 0, 'FR');
  SetC(2, 1, 'France');
  SetC(2, 2, 'France');
  SetC(2, 3, 'France');
  SetC(2, 4, 'fr');
  SetC(3, 0, 'CA');
  SetC(3, 1, 'Canada');
  SetC(3, 2, 'Canada');
  SetC(3, 3, 'Canada');
  SetC(3, 4, 'fr');
  SetC(4, 0, 'DE');
  SetC(4, 1, 'Germany');
  SetC(4, 2, 'Allemagne');
  SetC(4, 3, 'Deutschland');
  SetC(4, 4, 'de');
  SetC(5, 0, 'ES');
  SetC(5, 1, 'Spain');
  SetC(5, 2, 'Espagne');
  SetC(5, 3, 'Espa#F1a');
  SetC(5, 4, 'es');
  SetC(6, 0, 'IT');
  SetC(6, 1, 'Italy');
  SetC(6, 2, 'Italie');
  SetC(6, 3, 'Italia');
  SetC(6, 4, 'it');
  SetC(7, 0, 'NL');
  SetC(7, 1, 'Netherlands');
  SetC(7, 2, 'Pays-Bas');
  SetC(7, 3, 'Nederland');
  SetC(7, 4, 'nl');
  SetC(8, 0, 'BR');
  SetC(8, 1, 'Brazil');
  SetC(8, 2, 'Br#E9sil');
  SetC(8, 3, 'Brasil');
  SetC(8, 4, 'pt');
End;


Function LocF(L, F : LongInt) : String;
Begin
  If (L < 0) Or (L >= MaxLoc) Then LocF := '' Else LocF := LGet(L * NF + F);
End;

Function LocI(L, F : LongInt) : LongInt;
Begin
  LocI := StrInt(LocF(L, F));
End;

{ Locale d'apres son nom (sans .codeset ni @modificateur ; tiret ou
  soulignement ; code de langue seul) ; -1 si inconnue }
Function FindLoc(S : String) : LongInt;
Var K, R : LongInt; U : String;
Begin
  K := Pos('.', S);
  If K > 0 Then S := Copy(S, 1, K - 1);
  K := Pos('@', S);
  If K > 0 Then S := Copy(S, 1, K - 1);
  For K := 1 To Length(S) Do
    If Ord(S[K]) = 45 Then S[K] := '_';
  U := UpStr(S);
  R := -1;
  For K := MaxLoc - 1 DownTo 0 Do
    If LUsed[K] And (UpStr(LGet(K * NF + FName)) = U) Then R := K;
  If (R < 0) And (Length(S) = 2) Then
    For K := MaxLoc - 1 DownTo 3 Do
      If LUsed[K] And (UpStr(LGet(K * NF + FLang)) = U) Then R := K;
  If U = '' Then R := -1;
  FindLoc := R;
End;

Function CatName(Cat : LongInt) : String;
Begin
  Case Cat Of
    0 : CatName := 'LC_COLLATE';
    1 : CatName := 'LC_CTYPE';
    2 : CatName := 'LC_NUMERIC';
    3 : CatName := 'LC_MONETARY';
    4 : CatName := 'LC_TIME';
    5 : CatName := 'LC_MESSAGES';
  Else
    CatName := 'LC_ALL';
  End;
End;

Function EnvStr(N : String) : String;
Var V : LongInt;
Begin
  PutZ(LongInt(@NameZ), N);
  V := 0;
  If DcScanEnv(LongInt(@NameZ), LongInt(@V)) = 0 Then EnvStr := GetZ(V) Else EnvStr := '';
End;

{ Locale par defaut d'une categorie : LC_ALL, LC_xxx, LANG, Locale,
  en_US }
Function DefLoc(Cat : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := FindLoc(EnvStr('LC_ALL'));
  If R < 0 Then R := FindLoc(EnvStr(CatName(Cat)));
  If R < 0 Then R := FindLoc(EnvStr('LANG'));
  If R < 0 Then R := FindLoc(GDef[Cat]);
  If R < 0 Then R := FindLoc('en_US');
  DefLoc := R;
End;

Function LangIdx(L : LongInt) : LongInt;
Var K, R : LongInt; C : String;
Begin
  C := LowStr(LocF(L, FLang));
  R := 0;
  For K := NLang - 1 DownTo 0 Do
    If LangCode[K] = C Then R := K;
  LangIdx := R;
End;

Function LangF(Li, F : LongInt) : String;
Begin
  LangF := LangGet(Li * NLF + F);
End;

Function CtryIdx(C : String) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  C := UpStr(C);
  For K := NCtry - 1 DownTo 0 Do
    If CtryGet(K * 5) = C Then R := K;
  CtryIdx := R;
End;

{ --- objets locales --- }
Function LOHandle(I : LongInt) : LongInt;
Begin
  LOHandle := $4C000000 + ((LOGen[I] And $FFFF) Shl 8) + I + 1;
End;

Function LOIdx(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  I := (H And $FF) - 1;
  If (I >= 0) And (I < MaxLObj) Then
    If (LOOwn[I] <> 0) And (LOHandle(I) = H) Then R := I;
  LOIdx := R;
End;

{ Locale d'une categorie d'un objet (objet nul ou invalide : C) }
Function LocOf(H, Cat : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := LOIdx(H);
  If (Cat < 0) Or (Cat > 5) Then Cat := LC_CTYPE;
  If I < 0 Then LocOf := 0 Else LocOf := LOCat[I * 6 + Cat];
End;

Function NewLObj : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxLObj - 1 DownTo 0 Do
    If (LOOwn[I] = 0) Or Not Alive(LOOwn[I]) Then F := I;
  If F >= 0 Then
  Begin
    LOOwn[F] := MyPid;
    Inc(LOGen[F]);
  End;
  NewLObj := F;
End;

{ Categorie d'un element de locale }
Function ItemCat(Item : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := LC_CTYPE;
  If ((Item >= 1) And (Item <= 43)) Or ((Item >= 55) And (Item <= 59)) Or (Item = 63) Or (Item = 64) Or
     (Item = 73) Or (Item = 74) Or ((Item >= 79) And (Item <= 82)) Or ((Item >= 84) And (Item <= 86)) Or
     ((Item >= 96) And (Item <= 99)) Or ((Item >= 123) And (Item <= 125)) Or (Item >= 130) Then R := LC_TIME
  Else If (Item = 44) Or (Item = 45) Or (Item = 53) Or (Item = 60) Or (Item = 68) Or (Item = 72) Or
          (Item = 77) Or (Item = 78) Or (Item = 127) Or (Item = 128) Or (Item = 129) Then R := LC_NUMERIC
  Else If (Item = 48) Or (Item = 66) Or (Item = 67) Or (Item = 69) Or (Item = 75) Or (Item = 76) Or
          (Item = 83) Or (Item = 87) Or ((Item >= 92) And (Item <= 95)) Or (Item = 120) Or (Item = 121) Then R := LC_MONETARY
  Else If (Item = 46) Or (Item = 47) Or (Item = 61) Or (Item = 62) Then R := LC_MESSAGES
  Else If Item = 89 Then R := LC_COLLATE;
  ItemCat := R;
End;

Function IsIntItem(Item : LongInt) : Boolean;
Begin
  IsIntItem := (Item = 50) Or (Item = 51) Or (Item = 52) Or (Item = 54) Or ((Item >= 70) And (Item <= 86)) Or
               (Item = 90) Or (Item = 91) Or (Item = 108) Or ((Item >= 110) And (Item <= 114));
End;

Function OvFind(L, Item : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := MaxOv - 1 DownTo 0 Do
    If (OvItem[K] = Item) And (OvLoc[K] = L) Then R := K;
  OvFind := R;
End;

{ Nom de la langue ou du pays (en anglais, en francais ou dans sa langue) }
Function CtryName(Ci : LongInt; Lang : String) : String;
Begin
  If Ci < 0 Then CtryName := ''
  Else If Lang = 'fr' Then CtryName := CtryGet(Ci * 5 + 2)
  Else If Lang = CtryGet(Ci * 5 + 4) Then CtryName := CtryGet(Ci * 5 + 3)
  Else CtryName := CtryGet(Ci * 5 + 1);
End;

{ Element Item de la locale L : chaine, ou entier si IsInt (rend un code
  ULS_*) }
Function ItemOf(L, Item : LongInt; Var S : String; Var IsInt : Boolean; Var IV : LongInt) : LongInt;
Var K, Li, P, N : LongInt;
Begin
  ItemOf := ULS_SUCCESS;
  S := ''; IV := 0;
  IsInt := IsIntItem(Item);
  If (Item < 1) Or (Item > MaxItem) Then
  Begin
    ItemOf := ULS_INVALID;
    Exit;
  End;
  K := OvFind(L, Item);
  If K >= 0 Then
  Begin
    S := OvGet(K);
    If IsInt Then
    Begin
      If (Item = 50) Or (Item = 51) Then IV := HexInt(S) Else IV := StrInt(S);
    End;
    Exit;
  End;
  Li := LangIdx(L);
  If (Item >= 6) And (Item <= 12) Then S := LangF(Li, 7 + ((Item - 6 + 0) Mod 7))
  Else If (Item >= 13) And (Item <= 19) Then S := LangF(Li, (Item - 13) Mod 7)
  Else If (Item >= 20) And (Item <= 31) Then S := LangF(Li, 26 + Item - 20)
  Else If (Item >= 32) And (Item <= 43) Then S := LangF(Li, 14 + Item - 32)
  Else
    Case Item Of
      1 : S := LocF(L, FDateTime);
      2 : S := LocF(L, FDate);
      3 : S := LocF(L, FTime);
      4 : S := LocF(L, FAm);
      5 : S := LocF(L, FPm);
      44 : S := LocF(L, FDec);
      45 : S := LocF(L, FThou);
      46 : S := LocF(L, FYes);
      47 : S := LocF(L, FNo);
      48 : S := LocF(L, FCurr);
      49 : S := LocF(L, FCodeset);
      50 : IV := L + 1;
      51 : IV := HexInt(LocF(L, FWin));
      52 : IV := 0;
      53 : S := '0123456789';
      54 : IV := MaxItem;
      57 : S := LocF(L, FDate);
      58 : S := LocF(L, FDateTime);
      59 : S := LocF(L, FTime);
      61 : S := LocF(L, FYesExpr);
      62 : S := LocF(L, FNoExpr);
      63 : S := LocF(L, FDateSep);
      64 : S := ':';
      65 : S := LocF(L, FList);
      66 : S := LocF(L, FMonDec);
      67 : S := LocF(L, FMonThou);
      68 : S := LocF(L, FGroup);
      69 : S := LocF(L, FMonGroup);
      70 : IV := LocI(L, FMeasure);
      71 : IV := LocI(L, FPaper);
      72 : IV := 2;
      73 : IV := LocI(L, FITime);
      74, 79 : IV := LocI(L, FIDate);
      75 : Begin
             P := LocI(L, FPcs); N := LocI(L, FPsep);
             If (P = 1) And (N <= 0) Then IV := 0
             Else If (P = 0) And (N <= 0) Then IV := 1
             Else If P = 1 Then IV := 2
             Else IV := 3;
           End;
      76 : IV := LocI(L, FFrac);
      77, 78, 80, 84 : IV := 1;
      81 : IV := LocI(L, FFirstDay);
      82 : IV := LocI(L, FFirstWeek);
      83 : IV := LocI(L, FNegCurr);
      87 : S := LocF(L, FIntl);
      88 : S := LocF(L, FAbbrLang);
      89, 100, 122 : S := LocF(L, FName);
      92 : S := LocF(L, FPos);
      93 : S := LocF(L, FNeg);
      94 : Begin
             N := LocI(L, FNsign);
             If N = 0 Then S := '(' Else If (N = 1) Or (N = 3) Then S := LocF(L, FNeg);
           End;
      95 : Begin
             N := LocI(L, FNsign);
             If N = 0 Then S := ')' Else If (N = 2) Or (N = 4) Then S := LocF(L, FNeg);
           End;
      96, 97, 133 : S := LocF(L, FLongDate);
      101 : S := LocF(L, FLang);
      102 : S := LocF(L, FCtry);
      103 : S := LangF(Li, 38);
      104 : S := LangF(Li, 40);
      105 : S := CtryName(CtryIdx(LocF(L, FCtry)), 'en');
      106 : S := CtryName(CtryIdx(LocF(L, FCtry)), LocF(L, FLang));
      107 : Begin
              N := CtryIdx(LocF(L, FCtry));
              If N >= 0 Then S := CtryGet(N * 5 + 3);
            End;
      108 : IV := LocI(L, FCtryCode);
      109 : S := 'ISO8859-1';
      110 : IV := 1252;
      111 : IV := LocI(L, FCp);
      112 : If LocI(L, FCp) = 437 Then IV := 850 Else IV := 437;
      113 : IV := 10000;
      114 : IV := LocI(L, FEbcdic);
      116 : If LocI(L, FCp) = 437 Then S := '437,850' Else S := LocF(L, FCp) + ',437';
      117, 119 : S := LocF(L, FKbd);
      120 : S := LocF(L, FDebit);
      121 : S := LocF(L, FCredit);
      123 : S := LocF(L, FWTime);
      124 : S := LocF(L, FWShort);
      125 : S := LocF(L, FWLong);
      126 : S := LocF(L, FIso3);
      127 : S := '#,##0%';
      128 : S := '%';
      129 : S := 'E';
      130, 131, 135 : If Item = 135 Then S := LocF(L, FDateTime) Else S := LocF(L, FTime);
      132 : If LocI(L, FITime) = 0 Then S := '%I:%M %p' Else S := '%H:%M';
      134 : S := '%d %b %Y';
      136 : S := 'BC;AD';
    End;
End;

{ Element en chaine (entiers en decimal, x* en hexadecimal) }
Function ItemStr(L, Item : LongInt; Var S : String) : LongInt;
Var R, IV : LongInt; IsI : Boolean;
Begin
  R := ItemOf(L, Item, S, IsI, IV);
  If (R = ULS_SUCCESS) And IsI And (OvFind(L, Item) < 0) Then
  Begin
    If (Item = 50) Or (Item = 51) Then S := HexStr(IV) Else S := IntStr(IV);
  End;
  ItemStr := R;
End;

{ Champ d'une locale (avec les remplacements de l'element equivalent) }
Function LocItem(L, Item : LongInt) : String;
Var S : String;
Begin
  S := '';
  Dummy := ItemStr(L, Item, S);
  LocItem := S;
End;

{ ==================================================================== }
{ Partie 6 - Fonctions : objets locales et elements                    }
{ ==================================================================== }

{ Nom d'apres une specification (type, pointeur) ; Tok <- jeton ; rend
  un code ULS_* }
Function SpecName(Typ, Spec : LongInt; Var N : String) : LongInt;
Var T : LongInt;
Begin
  SpecName := ULS_SUCCESS;
  N := '';
  If Spec = 0 Then
  Begin
    N := 'C';
    Exit;
  End;
  If Typ = UNI_TOKEN_POINTER Then
  Begin
    T := RdL(Spec) - 1;
    If (T >= 0) And (T < MaxLoc) Then
    Begin
      If LUsed[T] Then N := LGet(T * NF + FName) Else SpecName := ULS_NOTOKEN;
    End
    Else SpecName := ULS_NOTOKEN;
  End
  Else If Typ = UNI_MBS_STRING_POINTER Then N := GetZ(Spec)
  Else If Typ = UNI_UCS_STRING_POINTER Then N := GetU(Spec)
  Else SpecName := ULS_INVALID;
End;

{ ---------------------------------------------------------------------
  UniCreateLocaleObject(type, spec, plo) : objet locale (spec nulle : C ;
  nom vide : locales par defaut des categories) }
Function UniCreateLocaleObject(Typ, Spec, PLo : LongInt) : LongInt;
Var R, I, K, L : LongInt; N : String;
Begin
  If PLo = 0 Then
  Begin
    UniCreateLocaleObject := ULS_INVALID;
    Exit;
  End;
  WrL(PLo, 0);
  R := SpecName(Typ, Spec, N);
  If R <> ULS_SUCCESS Then
  Begin
    UniCreateLocaleObject := R;
    Exit;
  End;
  L := -1;
  If N <> '' Then
  Begin
    L := FindLoc(N);
    If L < 0 Then
    Begin
      UniCreateLocaleObject := ULS_UNSUPPORTED;
      Exit;
    End;
  End;
  I := NewLObj;
  If I < 0 Then
  Begin
    UniCreateLocaleObject := ULS_NOMEMORY;
    Exit;
  End;
  For K := 0 To 5 Do
    If L >= 0 Then LOCat[I * 6 + K] := L Else LOCat[I * 6 + K] := DefLoc(K);
  WrL(PLo, LOHandle(I));
  UniCreateLocaleObject := ULS_SUCCESS;
End;

{ ---------------------------------------------------------------------
  UniFreeLocaleObject(lo) }
Function UniFreeLocaleObject(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := LOIdx(H);
  If I < 0 Then UniFreeLocaleObject := ULS_BADOBJECT
  Else
  Begin
    LOOwn[I] := 0;
    UniFreeLocaleObject := ULS_SUCCESS;
  End;
End;

{ Rendre une chaine : type 1 jeton (4 octets), 2 ASCIIZ, 3 UniChar }
Function RetSpec(Typ : LongInt; N : String; Tok, PP : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := 0;
  If Typ = UNI_TOKEN_POINTER Then
  Begin
    A := PoolAlloc;
    If A <> 0 Then WrL(A, Tok);
  End
  Else If Typ = UNI_MBS_STRING_POINTER Then A := AllocZ(N)
  Else If Typ = UNI_UCS_STRING_POINTER Then A := AllocU(N)
  Else
  Begin
    RetSpec := ULS_INVALID;
    Exit;
  End;
  WrL(PP, A);
  If A = 0 Then RetSpec := ULS_NOMEMORY Else RetSpec := ULS_SUCCESS;
End;

{ ---------------------------------------------------------------------
  UniQueryLocaleObject(lo, categorie, type, pp) : nom (ou jeton) de la
  locale d'une categorie ; LC_ALL : le nom commun, ou
  LC_COLLATE=nom;LC_CTYPE=nom;... (memoire liberee par UniFreeMem) }
Function UniQueryLocaleObject(H, Cat, Typ, PP : LongInt) : LongInt;
Var I, K, L : LongInt; Same : Boolean; N : String;
Begin
  I := LOIdx(H);
  If PP = 0 Then
  Begin
    UniQueryLocaleObject := ULS_INVALID;
    Exit;
  End;
  WrL(PP, 0);
  If I < 0 Then
  Begin
    UniQueryLocaleObject := ULS_BADOBJECT;
    Exit;
  End;
  If (Cat < LC_ALL) Or (Cat > LC_MESSAGES) Then
  Begin
    UniQueryLocaleObject := ULS_INVALID;
    Exit;
  End;
  If Cat >= 0 Then L := LOCat[I * 6 + Cat]
  Else
  Begin
    L := LOCat[I * 6];
    Same := True;
    For K := 1 To 5 Do
      If LOCat[I * 6 + K] <> L Then Same := False;
    If Not Same Then
    Begin
      If Typ = UNI_TOKEN_POINTER Then
      Begin
        UniQueryLocaleObject := ULS_UNSUPPORTED;
        Exit;
      End;
      N := '';
      For K := 0 To 5 Do
      Begin
        If K > 0 Then N := N + ';';
        N := N + CatName(K) + '=' + LocF(LOCat[I * 6 + K], FName);
      End;
      UniQueryLocaleObject := RetSpec(Typ, N, 0, PP);
      Exit;
    End;
  End;
  UniQueryLocaleObject := RetSpec(Typ, LocF(L, FName), L + 1, PP);
End;

{ ---------------------------------------------------------------------
  UniFreeMem(p) : memoire rendue par LIBUNI }
Function UniFreeMem(P : LongInt) : LongInt;
Begin
  If P = 0 Then UniFreeMem := ULS_SUCCESS Else UniFreeMem := PoolFree(P);
End;

{ ---------------------------------------------------------------------
  UniLocaleStrToToken(type, nom, ptok), UniLocaleTokenToStr(tok, type,
  pp) }
Function UniLocaleStrToToken(Typ, PStr, PTok : LongInt) : LongInt;
Var L : LongInt; N : String;
Begin
  If PTok = 0 Then
  Begin
    UniLocaleStrToToken := ULS_INVALID;
    Exit;
  End;
  WrL(PTok, 0);
  If (Typ = UNI_MBS_STRING_POINTER) Then N := GetZ(PStr)
  Else If (Typ = UNI_UCS_STRING_POINTER) Then N := GetU(PStr)
  Else
  Begin
    UniLocaleStrToToken := ULS_INVALID;
    Exit;
  End;
  L := FindLoc(N);
  If L < 0 Then UniLocaleStrToToken := ULS_UNSUPPORTED
  Else
  Begin
    WrL(PTok, L + 1);
    UniLocaleStrToToken := ULS_SUCCESS;
  End;
End;

Function UniLocaleTokenToStr(Tok, Typ, PP : LongInt) : LongInt;
Var L : LongInt;
Begin
  L := Tok - 1;
  If PP <> 0 Then WrL(PP, 0);
  If (PP = 0) Or ((Typ <> UNI_MBS_STRING_POINTER) And (Typ <> UNI_UCS_STRING_POINTER)) Then
    UniLocaleTokenToStr := ULS_INVALID
  Else If (L < 0) Or (L >= MaxLoc) Then UniLocaleTokenToStr := ULS_NOTOKEN
  Else If Not LUsed[L] Then UniLocaleTokenToStr := ULS_NOTOKEN
  Else UniLocaleTokenToStr := RetSpec(Typ, LocF(L, FName), 0, PP);
End;

{ ---------------------------------------------------------------------
  UniQueryLocaleItem(lo, item, pp) : element en chaine UniChar (UniFreeMem)
  UniQueryLocaleValue(lo, item, pint) : element entier }
Function UniQueryLocaleItem(H, Item, PP : LongInt) : LongInt;
Var R, L, A : LongInt; S : String;
Begin
  If PP = 0 Then
  Begin
    UniQueryLocaleItem := ULS_INVALID;
    Exit;
  End;
  WrL(PP, 0);
  If LOIdx(H) < 0 Then
  Begin
    UniQueryLocaleItem := ULS_BADOBJECT;
    Exit;
  End;
  L := LocOf(H, ItemCat(Item));
  R := ItemStr(L, Item, S);
  If R = ULS_SUCCESS Then
  Begin
    A := AllocU(S);
    If A = 0 Then R := ULS_NOMEMORY;
    WrL(PP, A);
  End;
  UniQueryLocaleItem := R;
End;

Function UniQueryLocaleValue(H, Item, PInt : LongInt) : LongInt;
Var R, L, IV : LongInt; S : String; IsI : Boolean;
Begin
  If PInt = 0 Then
  Begin
    UniQueryLocaleValue := ULS_INVALID;
    Exit;
  End;
  If LOIdx(H) < 0 Then
  Begin
    UniQueryLocaleValue := ULS_BADOBJECT;
    Exit;
  End;
  L := LocOf(H, ItemCat(Item));
  R := ItemOf(L, Item, S, IsI, IV);
  If (R = ULS_SUCCESS) And Not IsI Then R := ULS_INVALID;
  If R = ULS_SUCCESS Then WrL(PInt, IV);
  UniQueryLocaleValue := R;
End;

{ ---------------------------------------------------------------------
  UniQueryLocaleInfo(lo, pplconv) : structure UniLconv (UniFreeLocaleInfo) }
Function PutLStr(Var Cur : LongInt; S : String) : LongInt;
Begin
  PutU(Cur, S);
  PutLStr := Cur;
  Cur := Cur + (Length(S) + 1) * 2;
End;

Function PutGroup(Var Cur : LongInt; S : String) : LongInt;
Var K, V, A : LongInt;
Begin
  A := Cur;
  V := 0;
  S := S + ';';
  For K := 1 To Length(S) Do
    If Ord(S[K]) = 59 Then
    Begin
      If V > 0 Then
      Begin
        WrW(Cur, V);
        Cur := Cur + 2;
      End;
      V := 0;
    End
    Else If (Ord(S[K]) >= 48) And (Ord(S[K]) <= 57) Then V := V * 10 + Ord(S[K]) - 48;
  WrW(Cur, 0);
  Cur := Cur + 2;
  PutGroup := A;
End;

Function UniQueryLocaleInfo(H, PP : LongInt) : LongInt;
Var A, Cur, N, M : LongInt;
Begin
  If PP = 0 Then
  Begin
    UniQueryLocaleInfo := ULS_INVALID;
    Exit;
  End;
  WrL(PP, 0);
  If LOIdx(H) < 0 Then
  Begin
    UniQueryLocaleInfo := ULS_BADOBJECT;
    Exit;
  End;
  A := PoolAlloc;
  If A = 0 Then
  Begin
    UniQueryLocaleInfo := ULS_NOMEMORY;
    Exit;
  End;
  N := LocOf(H, LC_NUMERIC);
  M := LocOf(H, LC_MONETARY);
  Cur := A + 80;
  WrL(A, PutLStr(Cur, LocItem(N, 44)));
  WrL(A + 4, PutLStr(Cur, LocItem(N, 45)));
  WrL(A + 8, PutGroup(Cur, LocItem(N, 68)));
  WrL(A + 12, PutLStr(Cur, LocItem(M, 87)));
  WrL(A + 16, PutLStr(Cur, LocItem(M, 48)));
  WrL(A + 20, PutLStr(Cur, LocItem(M, 66)));
  WrL(A + 24, PutLStr(Cur, LocItem(M, 67)));
  WrL(A + 28, PutGroup(Cur, LocItem(M, 69)));
  WrL(A + 32, PutLStr(Cur, LocItem(M, 92)));
  WrL(A + 36, PutLStr(Cur, LocItem(M, 93)));
  WrW(A + 40, LocI(M, FIntFrac));
  WrW(A + 42, LocI(M, FFrac));
  WrW(A + 44, LocI(M, FPcs));
  WrW(A + 46, LocI(M, FPsep));
  WrW(A + 48, LocI(M, FNcs));
  WrW(A + 50, LocI(M, FNsep));
  WrW(A + 52, LocI(M, FPsign));
  WrW(A + 54, LocI(M, FNsign));
  WrW(A + 56, LocI(M, FFrac));
  WrL(A + 60, PutLStr(Cur, LocItem(M, 120)));
  WrL(A + 64, PutLStr(Cur, LocItem(M, 121)));
  WrL(A + 68, PutLStr(Cur, '('));
  WrL(A + 72, PutLStr(Cur, ')'));
  WrL(PP, A);
  UniQueryLocaleInfo := ULS_SUCCESS;
End;

Function UniFreeLocaleInfo(P : LongInt) : LongInt;
Begin
  If P = 0 Then UniFreeLocaleInfo := ULS_SUCCESS Else UniFreeLocaleInfo := PoolFree(P);
End;

{ ---------------------------------------------------------------------
  UniMapCtryToLocale(pays, ucs, n) : nom de la locale du code de pays
  (0 : locale par defaut) }
Function UniMapCtryToLocale(Code, PBuf, N : LongInt) : LongInt;
Var K, L : LongInt; S : String;
Begin
  L := -1;
  If Code = 0 Then L := DefLoc(LC_CTYPE)
  Else
    For K := NSysLoc - 1 DownTo 3 Do
      If LocI(K, FCtryCode) = Code Then L := K;
  If L < 0 Then UniMapCtryToLocale := ULS_INVALID
  Else If PBuf = 0 Then UniMapCtryToLocale := ULS_INVALID
  Else
  Begin
    S := LocF(L, FName);
    If Length(S) + 1 > N Then UniMapCtryToLocale := ULS_BUFFERFULL
    Else
    Begin
      PutU(PBuf, S);
      UniMapCtryToLocale := ULS_SUCCESS;
    End;
  End;
End;

{ ---------------------------------------------------------------------
  Locale(categorie, ucsNom) (OS/2-0) : locale par defaut d'une categorie
  (LC_ALL : toutes) ; nom vide : revenir aux variables d'environnement ;
  nom nul : interroger. Rend le nom (UniChar) de la locale par defaut de
  la categorie (LC_ALL : LC_CTYPE), 0 si le nom ou la categorie est
  inconnu. }
Function Locale(Cat, PName : LongInt) : LongInt;
Var K, L : LongInt; N : String;
Begin
  Locale := 0;
  If (Cat < LC_ALL) Or (Cat > LC_MESSAGES) Then Exit;
  If PName <> 0 Then
  Begin
    N := GetU(PName);
    If N <> '' Then
    Begin
      L := FindLoc(N);
      If L < 0 Then Exit;
      N := LocF(L, FName);
    End;
    For K := 0 To 5 Do
      If (Cat = LC_ALL) Or (Cat = K) Then GDef[K] := N;
  End;
  If Cat = LC_ALL Then Cat := LC_CTYPE;
  PutU(LongInt(@GLocRet), LocF(DefLoc(Cat), FName));
  Locale := LongInt(@GLocRet);
End;

{ ==================================================================== }
{ Partie 7 - Fonctions : attributs et types des caracteres             }
{ ==================================================================== }

Function HasAttr(C, M : LongInt) : LongInt;
Begin
  If (CharMask(C) And M) <> 0 Then HasAttr := 1 Else HasAttr := 0;
End;

{ UniQueryXxx(lo, uc) : 1 si le caractere a l'attribut }
Function UniQueryXdigit(H, C : LongInt) : LongInt;
Begin
  UniQueryXdigit := HasAttr(C, CT_XDIGIT);
End;

Function UniQuerySpace(H, C : LongInt) : LongInt;
Begin
  UniQuerySpace := HasAttr(C, CT_SPACE);
End;

Function UniQueryPrint(H, C : LongInt) : LongInt;
Begin
  UniQueryPrint := HasAttr(C, CT_PRINT);
End;

Function UniQueryGraph(H, C : LongInt) : LongInt;
Begin
  UniQueryGraph := HasAttr(C, CT_GRAPH);
End;

Function UniQueryCntrl(H, C : LongInt) : LongInt;
Begin
  UniQueryCntrl := HasAttr(C, CT_CNTRL);
End;

Function UniQueryAlpha(H, C : LongInt) : LongInt;
Begin
  UniQueryAlpha := HasAttr(C, CT_ALPHA);
End;

Function UniQueryUpper(H, C : LongInt) : LongInt;
Begin
  UniQueryUpper := HasAttr(C, CT_UPPER);
End;

Function UniQueryPunct(H, C : LongInt) : LongInt;
Begin
  UniQueryPunct := HasAttr(C, CT_PUNCT);
End;

Function UniQueryLower(H, C : LongInt) : LongInt;
Begin
  UniQueryLower := HasAttr(C, CT_LOWER);
End;

Function UniQueryDigit(H, C : LongInt) : LongInt;
Begin
  UniQueryDigit := HasAttr(C, CT_DIGIT);
End;

Function UniQueryBlank(H, C : LongInt) : LongInt;
Begin
  UniQueryBlank := HasAttr(C, CT_BLANK);
End;

Function UniQueryAlnum(H, C : LongInt) : LongInt;
Begin
  UniQueryAlnum := HasAttr(C, CT_ALNUM);
End;

{ UniQueryChar(uc, attr) : 1 si le caractere a l'un des attributs }
Function UniQueryChar(C, M : LongInt) : LongInt;
Begin
  UniQueryChar := HasAttr(C, M);
End;

{ UniQueryAttr(ucsNom) : masque des attributs nommes (0 : inconnu) }
Function UniQueryAttr(PName : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := AttrMaskOf(GetU(PName));
  If M < 0 Then M := 0;
  UniQueryAttr := M;
End;

{ --- objets attributs --- }
Function AOHandle(I : LongInt) : LongInt;
Begin
  AOHandle := $41000000 + ((AOGen[I] And $FFFF) Shl 8) + I + 1;
End;

Function AOIdx(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  I := (H And $FF) - 1;
  If (I >= 0) And (I < MaxAObj) Then
    If (AOOwn[I] <> 0) And (AOHandle(I) = H) Then R := I;
  AOIdx := R;
End;

{ UniCreateAttrObject(lo, ucsNoms, pao) }
Function UniCreateAttrObject(H, PName, PAo : LongInt) : LongInt;
Var M, I, F : LongInt;
Begin
  If PAo = 0 Then
  Begin
    UniCreateAttrObject := ULS_INVALID;
    Exit;
  End;
  WrL(PAo, 0);
  If (H <> 0) And (LOIdx(H) < 0) Then
  Begin
    UniCreateAttrObject := ULS_BADOBJECT;
    Exit;
  End;
  M := AttrMaskOf(GetU(PName));
  If M < 0 Then
  Begin
    UniCreateAttrObject := ULS_UNSUPPORTED;
    Exit;
  End;
  F := -1;
  For I := MaxAObj - 1 DownTo 0 Do
    If (AOOwn[I] = 0) Or Not Alive(AOOwn[I]) Then F := I;
  If F < 0 Then
  Begin
    UniCreateAttrObject := ULS_NOMEMORY;
    Exit;
  End;
  AOOwn[F] := MyPid;
  Inc(AOGen[F]);
  AOMask[F] := M;
  WrL(PAo, AOHandle(F));
  UniCreateAttrObject := ULS_SUCCESS;
End;

Function UniFreeAttrObject(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := AOIdx(H);
  If I < 0 Then UniFreeAttrObject := ULS_BADOBJECT
  Else
  Begin
    AOOwn[I] := 0;
    UniFreeAttrObject := ULS_SUCCESS;
  End;
End;

{ UniQueryCharAttr(ao, uc) : 1 si le caractere a l'un des attributs }
Function UniQueryCharAttr(H, C : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := AOIdx(H);
  If I < 0 Then UniQueryCharAttr := 0 Else UniQueryCharAttr := HasAttr(C, AOMask[I]);
End;

{ UniScanForAttr(ao, ucs, n, inverse, poffset) : premier caractere ayant
  (inverse : n'ayant pas) les attributs ; ULS_NOMATCH si aucun }
Function UniScanForAttr(H, PStr, N, Inv, POfs : LongInt) : LongInt;
Var I, K, F, Has : LongInt;
Begin
  I := AOIdx(H);
  If I < 0 Then
  Begin
    UniScanForAttr := ULS_BADOBJECT;
    Exit;
  End;
  F := -1;
  K := 0;
  While (F < 0) And (K < N) Do
  Begin
    Has := HasAttr(RdW(PStr + K * 2), AOMask[I]);
    If ((Has = 1) And (Inv = 0)) Or ((Has = 0) And (Inv <> 0)) Then F := K;
    Inc(K);
  End;
  If F < 0 Then UniScanForAttr := ULS_NOMATCH
  Else
  Begin
    WrL(POfs, F);
    UniScanForAttr := ULS_SUCCESS;
  End;
End;

{ UniQueryCharType(uc) : pointeur sur le type UNICTYPE du caractere }
Function UniQueryCharType(C : LongInt) : LongInt;
Begin
  UniQueryCharType := LongInt(@TTab) + TypeIndex(C) * 8;
End;

{ UniQueryCharTypeTable(pcount, pptr) : table de tous les types }
Function UniQueryCharTypeTable(PCount, PPtr : LongInt) : LongInt;
Var C : LongInt;
Begin
  If Not TTFull Then
  Begin
    For C := 0 To $FFFF Do Dummy := TypeIndex(C);
    TTFull := True;
  End;
  WrL(PCount, TTN);
  WrL(PPtr, LongInt(@TTab));
  UniQueryCharTypeTable := ULS_SUCCESS;
End;

{ UniQueryStringType(ucs, n, pmots, genre) : un mot par caractere (n = -1 :
  jusqu'au zero) }
Function UniQueryStringType(PStr, N, POut, Kind : LongInt) : LongInt;
Var K, C, I, V, A : LongInt;
Begin
  If (Kind < 1) Or (Kind > 9) Or (PStr = 0) Or (POut = 0) Then
  Begin
    UniQueryStringType := ULS_INVALID;
    Exit;
  End;
  If N < 0 Then N := UStrLen(PStr);
  For K := 0 To N - 1 Do
  Begin
    C := RdW(PStr + K * 2);
    I := TypeIndex(C);
    A := LongInt(@TTab) + I * 8;
    Case Kind Of
      1, 7 : V := RdW(A);
      2, 8 : V := RdB(A + 2);
      3 : V := RdB(A + 3);
      4, 9 : V := RdW(A + 4);
      5 : V := RdW(A + 6);
    Else
      V := I;
    End;
    WrW(POut + K * 2, V);
  End;
  UniQueryStringType := ULS_SUCCESS;
End;

{ UniQueryNumericValue(uc) : valeur entiere du caractere ; -1 si aucune }
Function UniQueryNumericValue(C : LongInt) : LongInt;
Begin
  UniQueryNumericValue := NumValue(C);
End;

{ ==================================================================== }
{ Partie 8 - Fonctions : chaines UniChar                               }
{ ==================================================================== }

Function UniStrlen(S : LongInt) : LongInt;
Begin
  UniStrlen := UStrLen(S);
End;

Function UniStrcpy(D, S : LongInt) : LongInt;
Var K, C : LongInt;
Begin
  K := 0;
  Repeat
    C := RdW(S + K * 2);
    WrW(D + K * 2, C);
    Inc(K);
  Until C = 0;
  UniStrcpy := D;
End;

Function UniStrncpy(D, S, N : LongInt) : LongInt;
Var K, C : LongInt;
Begin
  C := 1;
  For K := 0 To N - 1 Do
  Begin
    If C <> 0 Then C := RdW(S + K * 2);
    WrW(D + K * 2, C);
  End;
  UniStrncpy := D;
End;

Function UniStrcat(D, S : LongInt) : LongInt;
Begin
  Dummy := UniStrcpy(D + UStrLen(D) * 2, S);
  UniStrcat := D;
End;

Function UniStrncat(D, S, N : LongInt) : LongInt;
Var K, L, C : LongInt;
Begin
  L := UStrLen(D);
  K := 0;
  C := 1;
  While (K < N) And (C <> 0) Do
  Begin
    C := RdW(S + K * 2);
    If C <> 0 Then
    Begin
      WrW(D + (L + K) * 2, C);
      Inc(K);
    End;
  End;
  WrW(D + (L + K) * 2, 0);
  UniStrncat := D;
End;

Function UniStrcmp(S1, S2 : LongInt) : LongInt;
Var K, A, B : LongInt;
Begin
  K := 0;
  Repeat
    A := RdW(S1 + K * 2);
    B := RdW(S2 + K * 2);
    Inc(K);
  Until (A <> B) Or (A = 0);
  UniStrcmp := A - B;
End;

Function UniStrncmp(S1, S2, N : LongInt) : LongInt;
Var K, A, B : LongInt;
Begin
  A := 0; B := 0;
  K := 0;
  While (K < N) And (A = B) Do
  Begin
    A := RdW(S1 + K * 2);
    B := RdW(S2 + K * 2);
    If A = 0 Then K := N Else Inc(K);
  End;
  UniStrncmp := A - B;
End;

Function UniStrncmpi(H, S1, S2, N : LongInt) : LongInt;
Var K, A, B : LongInt;
Begin
  A := 0; B := 0;
  K := 0;
  While (K < N) And (A = B) Do
  Begin
    A := UToLower(RdW(S1 + K * 2));
    B := UToLower(RdW(S2 + K * 2));
    If A = 0 Then K := N Else Inc(K);
  End;
  UniStrncmpi := A - B;
End;

Function UniStrcmpi(H, S1, S2 : LongInt) : LongInt;
Begin
  UniStrcmpi := UniStrncmpi(H, S1, S2, $7FFFFFFF);
End;

Function UniStrchr(S, C : LongInt) : LongInt;
Var K, R, X : LongInt;
Begin
  C := C And $FFFF;
  K := 0; R := 0;
  Repeat
    X := RdW(S + K * 2);
    If X = C Then R := S + K * 2;
    Inc(K);
  Until (R <> 0) Or (X = 0);
  UniStrchr := R;
End;

Function UniStrrchr(S, C : LongInt) : LongInt;
Var K, R, X : LongInt;
Begin
  C := C And $FFFF;
  K := 0; R := 0;
  Repeat
    X := RdW(S + K * 2);
    If X = C Then R := S + K * 2;
    Inc(K);
  Until X = 0;
  UniStrrchr := R;
End;

{ Le caractere C est-il dans la chaine Set ? }
Function InSet(C, PSet : LongInt) : Boolean;
Var K, X : LongInt; F : Boolean;
Begin
  F := False;
  K := 0;
  X := RdW(PSet);
  While (X <> 0) And Not F Do
  Begin
    If X = C Then F := True;
    Inc(K);
    X := RdW(PSet + K * 2);
  End;
  InSet := F;
End;

Function UniStrspn(S1, S2 : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := 0;
  While (RdW(S1 + K * 2) <> 0) And InSet(RdW(S1 + K * 2), S2) Do Inc(K);
  UniStrspn := K;
End;

Function UniStrcspn(S1, S2 : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := 0;
  While (RdW(S1 + K * 2) <> 0) And Not InSet(RdW(S1 + K * 2), S2) Do Inc(K);
  UniStrcspn := K;
End;

Function UniStrpbrk(S1, S2 : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := UniStrcspn(S1, S2);
  If RdW(S1 + K * 2) = 0 Then UniStrpbrk := 0 Else UniStrpbrk := S1 + K * 2;
End;

Function UniStrstr(S1, S2 : LongInt) : LongInt;
Var K, J, L1, L2, R : LongInt; Ok : Boolean;
Begin
  L1 := UStrLen(S1);
  L2 := UStrLen(S2);
  R := 0;
  If L2 = 0 Then R := S1;
  K := 0;
  While (R = 0) And (K + L2 <= L1) Do
  Begin
    Ok := True;
    J := 0;
    While Ok And (J < L2) Do
    Begin
      If RdW(S1 + (K + J) * 2) <> RdW(S2 + J * 2) Then Ok := False;
      Inc(J);
    End;
    If Ok Then R := S1 + K * 2;
    Inc(K);
  End;
  UniStrstr := R;
End;

{ UniStrtok(ucs, separateurs) : jeton suivant (ucs nul : suite de la
  chaine precedente) }
Function UniStrtok(S1, S2 : LongInt) : LongInt;
Var P, R : LongInt;
Begin
  If S1 <> 0 Then GTokPos := S1;
  R := 0;
  If GTokPos <> 0 Then
  Begin
    P := GTokPos;
    While (RdW(P) <> 0) And InSet(RdW(P), S2) Do P := P + 2;
    If RdW(P) = 0 Then GTokPos := 0
    Else
    Begin
      R := P;
      While (RdW(P) <> 0) And Not InSet(RdW(P), S2) Do P := P + 2;
      If RdW(P) = 0 Then GTokPos := 0
      Else
      Begin
        WrW(P, 0);
        GTokPos := P + 2;
      End;
    End;
  End;
  UniStrtok := R;
End;

Function UniToupper(C : LongInt) : LongInt;
Begin
  UniToupper := UToUpper(C);
End;

Function UniTolower(C : LongInt) : LongInt;
Begin
  UniTolower := UToLower(C);
End;

Function UniTransUpper(H, C : LongInt) : LongInt;
Begin
  UniTransUpper := UToUpper(C);
End;

Function UniTransLower(H, C : LongInt) : LongInt;
Begin
  UniTransLower := UToLower(C);
End;

Function UniStrupr(S : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := 0;
  While RdW(S + K * 2) <> 0 Do
  Begin
    WrW(S + K * 2, UToUpper(RdW(S + K * 2)));
    Inc(K);
  End;
  UniStrupr := S;
End;

Function UniStrlwr(S : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := 0;
  While RdW(S + K * 2) <> 0 Do
  Begin
    WrW(S + K * 2, UToLower(RdW(S + K * 2)));
    Inc(K);
  End;
  UniStrlwr := S;
End;

{ ==================================================================== }
{ Partie 9 - Fonctions : collation, transformations                    }
{ ==================================================================== }

{ Poids de collation de C dans la locale L : classe (2 autre, 3 chiffre,
  4 lettre), valeur, accent (niveau 2), casse (niveau 3) }
Procedure CollW(L, C : LongInt; Var Cls, V, Sec, Ter : LongInt);
Var M, B, Mk : LongInt;
Begin
  C := C And $FFFF;
  If L <= 1 Then
  Begin
    { C et POSIX : ordre des codes }
    Cls := 2; V := C; Sec := 2; Ter := 2;
    Exit;
  End;
  M := CharMask(C);
  B := FullBase(C, Mk);
  If (M And CT_DIGIT) <> 0 Then
  Begin
    Cls := 3; V := NumValue(C) + 1;
  End
  Else If (M And CT_ALPHA) <> 0 Then
  Begin
    Cls := 4; V := UToLower(B);
  End
  Else
  Begin
    Cls := 2; V := C;
  End;
  If Mk = 0 Then Sec := 2
  Else If (Mk >= $0300) And (Mk <= $036F) Then Sec := 3 + Mk - $0300
  Else Sec := $80;
  If (M And CT_UPPER) <> 0 Then Ter := 3 Else Ter := 2;
End;

Function SignOf(V : LongInt) : LongInt;
Begin
  If V < 0 Then SignOf := -1 Else If V > 0 Then SignOf := 1 Else SignOf := 0;
End;

{ UniStrcoll(lo, ucs1, ucs2) : comparaison selon la collation (LC_COLLATE) }
Function UniStrcoll(H, S1, S2 : LongInt) : LongInt;
Var L, Lev, K, A, B, R, C1, V1, S1w, T1, C2, V2, S2w, T2 : LongInt;
Begin
  L := LocOf(H, LC_COLLATE);
  If L <= 1 Then
  Begin
    UniStrcoll := SignOf(UniStrcmp(S1, S2));
    Exit;
  End;
  R := 0;
  Lev := 1;
  While (R = 0) And (Lev <= 3) Do
  Begin
    K := 0;
    Repeat
      A := RdW(S1 + K * 2);
      B := RdW(S2 + K * 2);
      If (A = 0) And (B <> 0) Then R := -1
      Else If (A <> 0) And (B = 0) Then R := 1
      Else If A <> 0 Then
      Begin
        CollW(L, A, C1, V1, S1w, T1);
        CollW(L, B, C2, V2, S2w, T2);
        If Lev = 1 Then
        Begin
          If C1 <> C2 Then R := SignOf(C1 - C2) Else R := SignOf(V1 - V2);
        End
        Else If Lev = 2 Then R := SignOf(S1w - S2w)
        Else R := SignOf(T1 - T2);
      End;
      Inc(K);
    Until (R <> 0) Or (A = 0) Or (B = 0);
    Inc(Lev);
  End;
  UniStrcoll := R;
End;

{ Clef de collation de Src dans Dst (N mots au plus) ; rend sa longueur }
Function MakeKey(H, Dst, Src, N : LongInt) : LongInt;
Var L, K, Lev, Cnt, C, Cls, V, Sec, Ter, Len : LongInt;
Begin
  L := LocOf(H, LC_COLLATE);
  Len := UStrLen(Src);
  Cnt := 0;
  If L <= 1 Then
  Begin
    For K := 0 To Len - 1 Do
    Begin
      If Cnt < N Then WrW(Dst + Cnt * 2, RdW(Src + K * 2));
      Inc(Cnt);
    End;
  End
  Else
    For Lev := 1 To 3 Do
    Begin
      If Lev > 1 Then
      Begin
        If Cnt < N Then WrW(Dst + Cnt * 2, 1);
        Inc(Cnt);
      End;
      For K := 0 To Len - 1 Do
      Begin
        C := RdW(Src + K * 2);
        CollW(L, C, Cls, V, Sec, Ter);
        If Lev = 1 Then
        Begin
          If Cnt < N Then WrW(Dst + Cnt * 2, Cls);
          If Cnt + 1 < N Then WrW(Dst + Cnt * 2 + 2, V);
          Cnt := Cnt + 2;
        End
        Else
        Begin
          If Lev = 2 Then V := Sec Else V := Ter;
          If Cnt < N Then WrW(Dst + Cnt * 2, V);
          Inc(Cnt);
        End;
      End;
    End;
  If Cnt < N Then WrW(Dst + Cnt * 2, 0)
  Else If N > 0 Then WrW(Dst + (N - 1) * 2, 0);
  MakeKey := Cnt;
End;

{ UniStrxfrm(lo, ucsDst, ucsSrc, n) }
Function UniStrxfrm(H, Dst, Src, N : LongInt) : LongInt;
Begin
  UniStrxfrm := MakeKey(H, Dst, Src, N);
End;

{ UniMakeKey(lo, ucsSrc, ucsClef, n) (OS/2-0) : comme UniStrxfrm }
Function UniMakeKey(H, Src, Dst, N : LongInt) : LongInt;
Begin
  UniMakeKey := MakeKey(H, Dst, Src, N);
End;

{ UniGetColval(lo, uc) (OS/2-0) : poids de collation du caractere :
  classe shl 26 + valeur shl 10 + accent shl 2 + casse }
Function UniGetColval(H, C : LongInt) : LongInt;
Var Cls, V, Sec, Ter : LongInt;
Begin
  CollW(LocOf(H, LC_COLLATE), C, Cls, V, Sec, Ter);
  UniGetColval := (Cls Shl 26) Or ((V And $FFFF) Shl 10) Or ((Sec And $FF) Shl 2) Or (Ter - 2);
End;

{ --- objets de transformation --- }
Function XOHandle(I : LongInt) : LongInt;
Begin
  XOHandle := $58000000 + ((XOGen[I] And $FFFF) Shl 8) + I + 1;
End;

Function XOIdx(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  I := (H And $FF) - 1;
  If (I >= 0) And (I < MaxXObj) Then
    If (XOOwn[I] <> 0) And (XOHandle(I) = H) Then R := I;
  XOIdx := R;
End;

Function XformKind(S : String) : LongInt;
Var R : LongInt;
Begin
  S := LowStr(S);
  R := 0;
  If S = 'upper' Then R := 1
  Else If S = 'lower' Then R := 2
  Else If S = 'compose' Then R := 3
  Else If S = 'decompose' Then R := 4
  Else If S = 'hiragana' Then R := 5
  Else If S = 'katakana' Then R := 6
  Else If S = 'fullwidth' Then R := 7
  Else If S = 'halfwidth' Then R := 8;
  XformKind := R;
End;

{ UniCreateTransformObject(lo, ucsType, pxo) }
Function UniCreateTransformObject(H, PType, PXo : LongInt) : LongInt;
Var I, F, K : LongInt;
Begin
  If PXo = 0 Then
  Begin
    UniCreateTransformObject := ULS_INVALID;
    Exit;
  End;
  WrL(PXo, 0);
  If (H <> 0) And (LOIdx(H) < 0) Then
  Begin
    UniCreateTransformObject := ULS_BADOBJECT;
    Exit;
  End;
  K := XformKind(GetU(PType));
  If K = 0 Then
  Begin
    UniCreateTransformObject := ULS_UNSUPPORTED;
    Exit;
  End;
  F := -1;
  For I := MaxXObj - 1 DownTo 0 Do
    If (XOOwn[I] = 0) Or Not Alive(XOOwn[I]) Then F := I;
  If F < 0 Then
  Begin
    UniCreateTransformObject := ULS_NOMEMORY;
    Exit;
  End;
  XOOwn[F] := MyPid;
  Inc(XOGen[F]);
  XOKind[F] := K;
  WrL(PXo, XOHandle(F));
  UniCreateTransformObject := ULS_SUCCESS;
End;

Function UniFreeTransformObject(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := XOIdx(H);
  If I < 0 Then UniFreeTransformObject := ULS_BADOBJECT
  Else
  Begin
    XOOwn[I] := 0;
    UniFreeTransformObject := ULS_SUCCESS;
  End;
End;

{ Sortie d'une transformation : GCur mots ecrits sur Max }
Function XPut(POut, Max, C : LongInt) : Boolean;
Begin
  If GCur < Max Then
  Begin
    WrW(POut + GCur * 2, C);
    Inc(GCur);
    XPut := True;
  End
  Else XPut := False;
End;

{ Decomposition complete de C en sortie }
Function XDecomp(POut, Max, C, Depth : LongInt) : Boolean;
Var K : LongInt; Ok : Boolean;
Begin
  K := DecIdx(C);
  If (K < 0) Or (Depth > 4) Then XDecomp := XPut(POut, Max, C)
  Else
  Begin
    Ok := XDecomp(POut, Max, DecBase[K], Depth + 1);
    If Ok And (DecMark[K] <> 0) Then Ok := XPut(POut, Max, DecMark[K]);
    XDecomp := Ok;
  End;
End;

{ Katakana pleine chasse -> demi-chasse (0 si aucun) }
Function HalfOf(C : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := 0;
  For K := 0 To 62 Do
    If (R = 0) And (HalfKana[K] = C) Then R := $FF61 + K;
  HalfOf := R;
End;

{ UniTransformStr(xo, ucsIn, pnIn, ucsOut, pnOut) : *pnIn caracteres
  (-1 : jusqu'au zero) -> *pnOut au plus ; en retour, caracteres lus et
  ecrits }
Function UniTransformStr(H, PIn, PInN, POut, POutN : LongInt) : LongInt;
Var I, Kind, N, Max, K, C, D, B, Mk : LongInt; Ok : Boolean;
Begin
  I := XOIdx(H);
  If I < 0 Then
  Begin
    UniTransformStr := ULS_BADOBJECT;
    Exit;
  End;
  If (PIn = 0) Or (PInN = 0) Or (POut = 0) Or (POutN = 0) Then
  Begin
    UniTransformStr := ULS_INVALID;
    Exit;
  End;
  Kind := XOKind[I];
  N := RdL(PInN);
  If N < 0 Then N := UStrLen(PIn);
  Max := RdL(POutN);
  GCur := 0;
  K := 0;
  Ok := True;
  While Ok And (K < N) Do
  Begin
    C := RdW(PIn + K * 2);
    Case Kind Of
      1 : Ok := XPut(POut, Max, UToUpper(C));
      2 : Ok := XPut(POut, Max, UToLower(C));
      3 : Begin
            { composition : C + marques suivantes }
            If K + 1 < N Then D := ComposeOf(C, RdW(PIn + K * 2 + 2)) Else D := 0;
            While D <> 0 Do
            Begin
              C := D;
              Inc(K);
              If K + 1 < N Then D := ComposeOf(C, RdW(PIn + K * 2 + 2)) Else D := 0;
            End;
            Ok := XPut(POut, Max, C);
          End;
      4 : Ok := XDecomp(POut, Max, C, 0);
      5 : If ((C >= $30A1) And (C <= $30F6)) Or (C = $30FD) Or (C = $30FE) Then Ok := XPut(POut, Max, C - $60)
          Else Ok := XPut(POut, Max, C);
      6 : If ((C >= $3041) And (C <= $3096)) Or (C = $309D) Or (C = $309E) Then Ok := XPut(POut, Max, C + $60)
          Else Ok := XPut(POut, Max, C);
      7 : Begin
            If (C >= $21) And (C <= $7E) Then Ok := XPut(POut, Max, C + $FEE0)
            Else If C = $20 Then Ok := XPut(POut, Max, $3000)
            Else If (C >= $FF61) And (C <= $FF9F) Then
            Begin
              D := HalfKana[C - $FF61];
              { marque de voisement demi-chasse suivante }
              If (K + 1 < N) And ((RdW(PIn + K * 2 + 2) = $FF9E) Or (RdW(PIn + K * 2 + 2) = $FF9F)) Then
              Begin
                If RdW(PIn + K * 2 + 2) = $FF9E Then B := ComposeOf(D, $3099) Else B := ComposeOf(D, $309A);
                If B <> 0 Then
                Begin
                  D := B;
                  Inc(K);
                End;
              End;
              Ok := XPut(POut, Max, D);
            End
            Else Ok := XPut(POut, Max, C);
          End;
      8 : Begin
            If (C >= $FF01) And (C <= $FF5E) Then Ok := XPut(POut, Max, C - $FEE0)
            Else If C = $3000 Then Ok := XPut(POut, Max, $20)
            Else
            Begin
              B := FullBase(C, Mk);
              D := HalfOf(B);
              If (D <> 0) And ((B = C) Or (Mk = $3099) Or (Mk = $309A)) Then
              Begin
                Ok := XPut(POut, Max, D);
                If Ok And (Mk = $3099) Then Ok := XPut(POut, Max, $FF9E);
                If Ok And (Mk = $309A) Then Ok := XPut(POut, Max, $FF9F);
              End
              Else
              Begin
                D := HalfOf(C);
                If D <> 0 Then Ok := XPut(POut, Max, D) Else Ok := XPut(POut, Max, C);
              End;
            End;
          End;
    End;
    If Ok Then Inc(K);
  End;
  WrL(PInN, K);
  WrL(POutN, GCur);
  If Ok Then UniTransformStr := ULS_SUCCESS Else UniTransformStr := ULS_BUFFERFULL;
End;

{ UniProcessUconv(lo, psz, ucs, n) (OS/2-0) : chaine de la page de codes
  de la locale (IBM-437, IBM-850, sinon ISO 8859-1) -> UniChar (n mots
  avec le zero) }
Function UniProcessUconv(H, PMbs, PUcs, N : LongInt) : LongInt;
Var Cs : String; K, B, C, Cp : LongInt;
Begin
  If (PMbs = 0) Or (PUcs = 0) Or (N <= 0) Then
  Begin
    UniProcessUconv := ULS_INVALID;
    Exit;
  End;
  If (H <> 0) And (LOIdx(H) < 0) Then
  Begin
    UniProcessUconv := ULS_BADOBJECT;
    Exit;
  End;
  Cs := UpStr(LocF(LocOf(H, LC_CTYPE), FCodeset));
  If Cs = 'IBM-437' Then Cp := 437 Else If Cs = 'IBM-850' Then Cp := 850 Else Cp := 0;
  K := 0;
  B := RdB(PMbs);
  While (B <> 0) And (K < N - 1) Do
  Begin
    If B < $80 Then C := B
    Else If Cp = 437 Then C := Cp437Hi[B - $80]
    Else If Cp = 850 Then C := Cp850Hi[B - $80]
    Else C := B;
    WrW(PUcs + K * 2, C);
    Inc(K);
    B := RdB(PMbs + K);
  End;
  WrW(PUcs + K * 2, 0);
  If B <> 0 Then UniProcessUconv := ULS_BUFFERFULL Else UniProcessUconv := ULS_SUCCESS;
End;

{ ==================================================================== }
{ Partie 10 - Fonctions : nombres, dates, montants                     }
{ ==================================================================== }

Function IsSpaceU(C : LongInt) : Boolean;
Begin
  IsSpaceU := (CharMask(C) And CT_SPACE) <> 0;
End;

{ Valeur d'un chiffre (decimal de toute ecriture, ou lettre) ; -1 }
Function DigitVal(C : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := -1;
  If (CharMask(C) And CT_DIGIT) <> 0 Then R := NumValue(C)
  Else If (C >= 65) And (C <= 90) Then R := C - 55
  Else If (C >= 97) And (C <= 122) Then R := C - 87
  Else If (C >= $FF21) And (C <= $FF3A) Then R := C - $FF21 + 10
  Else If (C >= $FF41) And (C <= $FF5A) Then R := C - $FF41 + 10;
  DigitVal := R;
End;

{ Conversion commune a UniStrtol et UniStrtoul : GDbl <- valeur absolue,
  Neg <- signe ; rend le nombre de caracteres lus (0 : aucun chiffre) }
Function ParseInt(P, Base : LongInt; Var Neg : Boolean) : LongInt;
Var K, C, D, Start : LongInt; Any : Boolean;
Begin
  K := 0;
  Neg := False;
  While IsSpaceU(RdW(P + K * 2)) Do Inc(K);
  C := RdW(P + K * 2);
  If (C = 43) Or (C = 45) Then
  Begin
    Neg := C = 45;
    Inc(K);
  End;
  If ((Base = 0) Or (Base = 16)) And (RdW(P + K * 2) = 48) And
     ((RdW(P + K * 2 + 2) = 120) Or (RdW(P + K * 2 + 2) = 88)) And (DigitVal(RdW(P + K * 2 + 4)) >= 0) And
     (DigitVal(RdW(P + K * 2 + 4)) < 16) Then
  Begin
    Base := 16;
    K := K + 2;
  End
  Else If (Base = 0) And (RdW(P + K * 2) = 48) Then Base := 8
  Else If Base = 0 Then Base := 10;
  GDbl := 0;
  Any := False;
  Start := K;
  D := DigitVal(RdW(P + K * 2));
  While (D >= 0) And (D < Base) Do
  Begin
    GDbl := GDbl * Base + D;
    Any := True;
    Inc(K);
    D := DigitVal(RdW(P + K * 2));
  End;
  If Any Then ParseInt := K Else ParseInt := 0;
End;

{ UniStrtol(lo, ucs, pfin, base, plong) }
Function UniStrtol(H, P, PEnd, Base, PRes : LongInt) : LongInt;
Var K, V, R : LongInt; Neg : Boolean;
Begin
  If (P = 0) Or (PRes = 0) Or (Base < 0) Or (Base = 1) Or (Base > 36) Then
  Begin
    UniStrtol := ULS_INVALID;
    Exit;
  End;
  K := ParseInt(P, Base, Neg);
  R := ULS_SUCCESS;
  If K = 0 Then
  Begin
    V := 0;
    R := ULS_INVALID;
  End
  Else If Neg Then
  Begin
    If GDbl > 2147483648.0 Then
    Begin
      V := (-2147483647 - 1);
      R := ULS_RANGE;
    End
    Else If GDbl = 2147483648.0 Then V := (-2147483647 - 1)
    Else V := -Trunc(GDbl);
  End
  Else If GDbl > 2147483647.0 Then
  Begin
    V := $7FFFFFFF;
    R := ULS_RANGE;
  End
  Else V := Trunc(GDbl);
  WrL(PRes, V);
  WrL(PEnd, P + K * 2);
  UniStrtol := R;
End;

{ UniStrtoul(lo, ucs, pfin, base, pulong) }
Function UniStrtoul(H, P, PEnd, Base, PRes : LongInt) : LongInt;
Var K, V, R : LongInt; Neg : Boolean;
Begin
  If (P = 0) Or (PRes = 0) Or (Base < 0) Or (Base = 1) Or (Base > 36) Then
  Begin
    UniStrtoul := ULS_INVALID;
    Exit;
  End;
  K := ParseInt(P, Base, Neg);
  R := ULS_SUCCESS;
  V := 0;
  If K = 0 Then R := ULS_INVALID
  Else If GDbl > 4294967295.0 Then
  Begin
    V := -1;
    R := ULS_RANGE;
  End
  Else
  Begin
    If GDbl >= 2147483648.0 Then V := Trunc(GDbl - 4294967296.0) Else V := Trunc(GDbl);
    If Neg Then V := -V;
  End;
  WrL(PRes, V);
  WrL(PEnd, P + K * 2);
  UniStrtoul := R;
End;

{ Copier GDbl (8 octets) a l'adresse A ; et l'inverse }
Procedure DblOut(A : LongInt);
Begin
  WrL(A, RdL(LongInt(@GDbl)));
  WrL(A + 4, RdL(LongInt(@GDbl) + 4));
End;

Procedure DblIn(Lo, Hi : LongInt);
Begin
  WrL(LongInt(@GDbl), Lo);
  WrL(LongInt(@GDbl) + 4, Hi);
End;

{ UniStrtod(lo, ucs, pfin, pdouble) : separateur decimal de la locale
  (LC_NUMERIC) ou point }
Function UniStrtod(H, P, PEnd, PRes : LongInt) : LongInt;
Var K, C, D, Ex, ExV, Dig, DecC, R : LongInt; Neg, ENeg, Any : Boolean; S : String;
Begin
  If (P = 0) Or (PRes = 0) Then
  Begin
    UniStrtod := ULS_INVALID;
    Exit;
  End;
  S := LocItem(LocOf(H, LC_NUMERIC), 44);
  If S = '' Then DecC := 46 Else DecC := ByteUni(Ord(S[1]));
  K := 0;
  While IsSpaceU(RdW(P + K * 2)) Do Inc(K);
  Neg := False;
  C := RdW(P + K * 2);
  If (C = 43) Or (C = 45) Then
  Begin
    Neg := C = 45;
    Inc(K);
  End;
  GDbl := 0;
  Ex := 0;
  Dig := 0;
  Any := False;
  D := RdW(P + K * 2);
  While (CharMask(D) And CT_DIGIT) <> 0 Do
  Begin
    If Dig < 18 Then
    Begin
      GDbl := GDbl * 10 + NumValue(D);
      If GDbl <> 0 Then Inc(Dig);
    End
    Else Inc(Ex);
    Any := True;
    Inc(K);
    D := RdW(P + K * 2);
  End;
  If (D = DecC) Or (D = 46) Then
  Begin
    Inc(K);
    D := RdW(P + K * 2);
    While (CharMask(D) And CT_DIGIT) <> 0 Do
    Begin
      If Dig < 18 Then
      Begin
        GDbl := GDbl * 10 + NumValue(D);
        Dec(Ex);
        If GDbl <> 0 Then Inc(Dig);
      End;
      Any := True;
      Inc(K);
      D := RdW(P + K * 2);
    End;
  End;
  R := ULS_SUCCESS;
  If Not Any Then
  Begin
    GDbl := 0;
    K := 0;
    R := ULS_INVALID;
  End
  Else
  Begin
    If (D = 101) Or (D = 69) Then
    Begin
      C := K + 1;
      ENeg := False;
      If (RdW(P + C * 2) = 43) Or (RdW(P + C * 2) = 45) Then
      Begin
        ENeg := RdW(P + C * 2) = 45;
        Inc(C);
      End;
      If (CharMask(RdW(P + C * 2)) And CT_DIGIT) <> 0 Then
      Begin
        ExV := 0;
        While (CharMask(RdW(P + C * 2)) And CT_DIGIT) <> 0 Do
        Begin
          If ExV < 10000 Then ExV := ExV * 10 + NumValue(RdW(P + C * 2));
          Inc(C);
        End;
        If ENeg Then Ex := Ex - ExV Else Ex := Ex + ExV;
        K := C;
      End;
    End;
    While (Ex > 0) And (GDbl < 1.0E308) Do
    Begin
      GDbl := GDbl * 10;
      Dec(Ex);
    End;
    While (Ex < 0) And (GDbl <> 0) Do
    Begin
      GDbl := GDbl / 10;
      Inc(Ex);
    End;
    If (Ex > 0) Or ((RdL(LongInt(@GDbl) + 4) And $7FF00000) = $7FF00000) Then
    Begin
      { depassement : HUGE_VAL }
      WrL(LongInt(@GDbl), 0);
      WrL(LongInt(@GDbl) + 4, $7FF00000);
      R := ULS_RANGE;
    End;
    If Neg Then GDbl := -GDbl;
  End;
  DblOut(PRes);
  WrL(PEnd, P + K * 2);
  UniStrtod := R;
End;

{ --- dates --- }
Function Pad(V, W : LongInt; C : String) : String;
Var S : String;
Begin
  S := IntStr(V);
  While Length(S) < W Do S := C + S;
  Pad := S;
End;

Function IsLeap(Y : LongInt) : Boolean;
Begin
  IsLeap := ((Y Mod 4 = 0) And (Y Mod 100 <> 0)) Or (Y Mod 400 = 0);
End;

{ Jour de la semaine (0 dimanche) et jour de l'annee (0..365) }
Procedure DateInfo(Y, M, D : LongInt; Var Wd, Yd : LongInt);
Var K, T : LongInt;
Begin
  Yd := D - 1;
  For K := 1 To M - 1 Do
  Begin
    Case K Of
      2 : If IsLeap(Y) Then T := 29 Else T := 28;
      4, 6, 9, 11 : T := 30;
    Else
      T := 31;
    End;
    Yd := Yd + T;
  End;
  { jours depuis le 1er janvier 1601 (lundi) }
  T := (Y - 1601) * 365 + (Y - 1601) Div 4 - (Y - 1601) Div 100 + (Y - 1601) Div 400 + Yd;
  Wd := (T + 1) Mod 7;
  If Wd < 0 Then Wd := Wd + 7;
End;

{ Conversion simple (sans %c, %x, %X) d'un element de date }
Function TimeBasic(L, Spec : LongInt) : String;
Var S : String; H : LongInt;
Begin
  S := '';
  Case Spec Of
    97 : S := LocItem(L, 6 + TmWday);                      { a }
    65 : S := LocItem(L, 13 + TmWday);                     { A }
    98, 104 : S := LocItem(L, 20 + TmMon);                 { b h }
    66 : S := LocItem(L, 32 + TmMon);                      { B }
    67 : S := Pad((TmYear + 1900) Div 100, 2, '0');        { C }
    100 : S := Pad(TmMday, 2, '0');                        { d }
    68 : S := Pad(TmMon + 1, 2, '0') + '/' + Pad(TmMday, 2, '0') + '/' + Pad((TmYear + 1900) Mod 100, 2, '0');
    101 : S := Pad(TmMday, 2, ' ');                        { e }
    70 : S := Pad(TmYear + 1900, 4, '0') + '-' + Pad(TmMon + 1, 2, '0') + '-' + Pad(TmMday, 2, '0');
    72 : S := Pad(TmHour, 2, '0');                         { H }
    73 : Begin                                              { I }
           H := TmHour Mod 12;
           If H = 0 Then H := 12;
           S := Pad(H, 2, '0');
         End;
    106 : S := Pad(TmYday + 1, 3, '0');                    { j }
    109 : S := Pad(TmMon + 1, 2, '0');                     { m }
    77 : S := Pad(TmMin, 2, '0');                          { M }
    110 : S := Chr(10);                                    { n }
    112 : If TmHour < 12 Then S := LocItem(L, 4) Else S := LocItem(L, 5);
    114 : Begin                                             { r }
            H := TmHour Mod 12;
            If H = 0 Then H := 12;
            S := Pad(H, 2, '0') + ':' + Pad(TmMin, 2, '0') + ':' + Pad(TmSec, 2, '0') + ' ';
            If TmHour < 12 Then S := S + LocItem(L, 4) Else S := S + LocItem(L, 5);
          End;
    82 : S := Pad(TmHour, 2, '0') + ':' + Pad(TmMin, 2, '0');
    83 : S := Pad(TmSec, 2, '0');                          { S }
    116 : S := Chr(9);                                     { t }
    84 : S := Pad(TmHour, 2, '0') + ':' + Pad(TmMin, 2, '0') + ':' + Pad(TmSec, 2, '0');
    117 : If TmWday = 0 Then S := '7' Else S := IntStr(TmWday);   { u }
    85 : S := Pad((TmYday + 7 - TmWday) Div 7, 2, '0');    { U }
    119 : S := IntStr(TmWday);                             { w }
    87 : S := Pad((TmYday + 7 - ((TmWday + 6) Mod 7)) Div 7, 2, '0');   { W }
    121 : S := Pad((TmYear + 1900) Mod 100, 2, '0');       { y }
    89 : S := IntStr(TmYear + 1900);                       { Y }
    90 : S := '';                                          { Z }
    37 : S := '%';
  End;
  TimeBasic := S;
End;

{ Motif de la locale (sans %c, %x, %X) -> chaine }
Function TimePat(L : LongInt; P : String) : String;
Var K : LongInt; S : String;
Begin
  S := '';
  K := 1;
  While K <= Length(P) Do
  Begin
    If (Ord(P[K]) = 37) And (K < Length(P)) Then
    Begin
      Inc(K);
      If ((Ord(P[K]) = 69) Or (Ord(P[K]) = 79)) And (K < Length(P)) Then Inc(K);
      S := S + TimeBasic(L, Ord(P[K]));
    End
    Else S := S + P[K];
    Inc(K);
  End;
  TimePat := S;
End;

Function TimeField(L, Spec : LongInt) : String;
Begin
  If Spec = 99 Then TimeField := TimePat(L, LocItem(L, 1))
  Else If Spec = 120 Then TimeField := TimePat(L, LocItem(L, 2))
  Else If Spec = 88 Then TimeField := TimePat(L, LocItem(L, 3))
  Else TimeField := TimeBasic(L, Spec);
End;

Procedure ReadTm(PTm : LongInt);
Begin
  TmSec := RdL(PTm);
  TmMin := RdL(PTm + 4);
  TmHour := RdL(PTm + 8);
  TmMday := RdL(PTm + 12);
  TmMon := RdL(PTm + 16);
  TmYear := RdL(PTm + 20);
  TmWday := RdL(PTm + 24);
  TmYday := RdL(PTm + 28);
  If (TmMon < 0) Or (TmMon > 11) Then TmMon := 0;
  If (TmWday < 0) Or (TmWday > 6) Then TmWday := 0;
End;

{ UniStrftime(lo, ucs, max, fmt, ptm) : rend le nombre de caracteres
  ecrits (0 si le tampon est trop petit) }
Function UniStrftime(H, PBuf, Max, PFmt, PTm : LongInt) : LongInt;
Var L, K, C, N, J : LongInt; S : String; Ok : Boolean;
Begin
  If (PBuf = 0) Or (PFmt = 0) Or (PTm = 0) Or (Max <= 0) Then
  Begin
    UniStrftime := 0;
    Exit;
  End;
  L := LocOf(H, LC_TIME);
  ReadTm(PTm);
  N := 0;
  K := 0;
  Ok := True;
  C := RdW(PFmt);
  While Ok And (C <> 0) Do
  Begin
    If (C = 37) And (RdW(PFmt + K * 2 + 2) <> 0) Then
    Begin
      Inc(K);
      C := RdW(PFmt + K * 2);
      If ((C = 69) Or (C = 79)) And (RdW(PFmt + K * 2 + 2) <> 0) Then
      Begin
        Inc(K);
        C := RdW(PFmt + K * 2);
      End;
      S := TimeField(L, C);
      For J := 1 To Length(S) Do
        If N < Max - 1 Then
        Begin
          WrW(PBuf + N * 2, ByteUni(Ord(S[J])));
          Inc(N);
        End
        Else Ok := False;
    End
    Else If N < Max - 1 Then
    Begin
      WrW(PBuf + N * 2, C);
      Inc(N);
    End
    Else Ok := False;
    Inc(K);
    C := RdW(PFmt + K * 2);
  End;
  WrW(PBuf + N * 2, 0);
  If Ok Then UniStrftime := N Else UniStrftime := 0;
End;

{ --- UniStrptime : analyse de l'entree (GCur : position, en mots) --- }
Function PNum(PIn, MaxD : LongInt; Var V : LongInt) : Boolean;
Var D, N : LongInt;
Begin
  While IsSpaceU(RdW(PIn + GCur * 2)) Do Inc(GCur);
  V := 0; N := 0;
  D := RdW(PIn + GCur * 2);
  While (N < MaxD) And (D >= 48) And (D <= 57) Do
  Begin
    V := V * 10 + D - 48;
    Inc(N);
    Inc(GCur);
    D := RdW(PIn + GCur * 2);
  End;
  PNum := N > 0;
End;

{ Le texte S (sans casse) est-il a la position courante ? }
Function PMatch(PIn : LongInt; S : String) : Boolean;
Var K : LongInt; Ok : Boolean;
Begin
  Ok := S <> '';
  K := 0;
  While Ok And (K < Length(S)) Do
  Begin
    If UToLower(RdW(PIn + (GCur + K) * 2)) <> UToLower(ByteUni(Ord(S[K + 1]))) Then Ok := False;
    Inc(K);
  End;
  If Ok Then GCur := GCur + Length(S);
  PMatch := Ok;
End;

{ Nom parmi les elements First..First+Cnt-1 (et les abreges AFirst) ;
  V <- rang ; le plus long nom correspondant l'emporte }
Function PNames(PIn, L, First, AFirst, Cnt : LongInt; Var V : LongInt) : Boolean;
Var K, Save, Best, BestLen : LongInt; S : String;
Begin
  While IsSpaceU(RdW(PIn + GCur * 2)) Do Inc(GCur);
  Save := GCur;
  Best := -1; BestLen := 0;
  For K := 0 To Cnt - 1 Do
  Begin
    S := LocItem(L, First + K);
    GCur := Save;
    If PMatch(PIn, S) And (Length(S) > BestLen) Then
    Begin
      Best := K; BestLen := Length(S);
    End;
    S := LocItem(L, AFirst + K);
    GCur := Save;
    If PMatch(PIn, S) And (Length(S) > BestLen) Then
    Begin
      Best := K; BestLen := Length(S);
    End;
  End;
  GCur := Save + BestLen;
  V := Best;
  PNames := Best >= 0;
End;

Function ParseSpec(PIn, L, Spec : LongInt) : Boolean; Forward;

{ Analyse d'un motif (chaine latin-1) }
Function ParsePat(PIn, L : LongInt; P : String) : Boolean;
Var K : LongInt; Ok : Boolean;
Begin
  Ok := True;
  K := 1;
  While Ok And (K <= Length(P)) Do
  Begin
    If (Ord(P[K]) = 37) And (K < Length(P)) Then
    Begin
      Inc(K);
      If ((Ord(P[K]) = 69) Or (Ord(P[K]) = 79)) And (K < Length(P)) Then Inc(K);
      Ok := ParseSpec(PIn, L, Ord(P[K]));
    End
    Else If Ord(P[K]) = 32 Then
    Begin
      While IsSpaceU(RdW(PIn + GCur * 2)) Do Inc(GCur);
    End
    Else
    Begin
      If UToLower(RdW(PIn + GCur * 2)) = UToLower(ByteUni(Ord(P[K]))) Then Inc(GCur) Else Ok := False;
    End;
    Inc(K);
  End;
  ParsePat := Ok;
End;

Function ParseSpec(PIn, L, Spec : LongInt) : Boolean;
Var V : LongInt; Ok : Boolean;
Begin
  Ok := True;
  Case Spec Of
    97, 65 : Begin
               Ok := PNames(PIn, L, 13, 6, 7, V);
               If Ok Then TmWday := V;
             End;
    98, 66, 104 : Begin
                    Ok := PNames(PIn, L, 32, 20, 12, V);
                    If Ok Then TmMon := V;
                  End;
    99 : Ok := ParsePat(PIn, L, LocItem(L, 1));
    120 : Ok := ParsePat(PIn, L, LocItem(L, 2));
    88 : Ok := ParsePat(PIn, L, LocItem(L, 3));
    67 : Begin
           Ok := PNum(PIn, 2, V);
           If Ok Then TmYear := V * 100 - 1900 + (TmYear + 1900) Mod 100;
         End;
    100, 101 : Begin
                 Ok := PNum(PIn, 2, V) And (V >= 1) And (V <= 31);
                 If Ok Then TmMday := V;
               End;
    68 : Ok := ParsePat(PIn, L, '%m/%d/%y');
    70 : Ok := ParsePat(PIn, L, '%Y-%m-%d');
    72 : Begin
           Ok := PNum(PIn, 2, V) And (V <= 23);
           If Ok Then TmHour := V;
         End;
    73 : Begin
           Ok := PNum(PIn, 2, V) And (V >= 1) And (V <= 12);
           If Ok Then
           Begin
             TmHour := V Mod 12;
             PtHas12 := 1;
           End;
         End;
    106 : Begin
            Ok := PNum(PIn, 3, V) And (V >= 1) And (V <= 366);
            If Ok Then TmYday := V - 1;
          End;
    109 : Begin
            Ok := PNum(PIn, 2, V) And (V >= 1) And (V <= 12);
            If Ok Then TmMon := V - 1;
          End;
    77 : Begin
           Ok := PNum(PIn, 2, V) And (V <= 59);
           If Ok Then TmMin := V;
         End;
    110, 116 : While IsSpaceU(RdW(PIn + GCur * 2)) Do Inc(GCur);
    112 : Begin
            While IsSpaceU(RdW(PIn + GCur * 2)) Do Inc(GCur);
            If PMatch(PIn, LocItem(L, 4)) Then PtPm := 0
            Else If PMatch(PIn, LocItem(L, 5)) Then PtPm := 1
            Else Ok := False;
          End;
    114 : Ok := ParsePat(PIn, L, '%I:%M:%S %p');
    82 : Ok := ParsePat(PIn, L, '%H:%M');
    83 : Begin
           Ok := PNum(PIn, 2, V) And (V <= 61);
           If Ok Then TmSec := V;
         End;
    84 : Ok := ParsePat(PIn, L, '%H:%M:%S');
    119 : Begin
            Ok := PNum(PIn, 1, V) And (V <= 6);
            If Ok Then TmWday := V;
          End;
    121 : Begin
            Ok := PNum(PIn, 2, V);
            If Ok Then
            Begin
              If V < 69 Then TmYear := V + 100 Else TmYear := V;
            End;
          End;
    89 : Begin
           Ok := PNum(PIn, 4, V);
           If Ok Then TmYear := V - 1900;
         End;
    37 : If RdW(PIn + GCur * 2) = 37 Then Inc(GCur) Else Ok := False;
  Else
    Ok := False;
  End;
  ParseSpec := Ok;
End;

{ UniStrptime(lo, ucs, fmt, ptm) : rend l'adresse qui suit la date
  analysee, 0 si elle ne correspond pas au format }
Function UniStrptime(H, PIn, PFmt, PTm : LongInt) : LongInt;
Var L, K, C, Wd, Yd : LongInt; Ok : Boolean;
Begin
  If (PIn = 0) Or (PFmt = 0) Or (PTm = 0) Then
  Begin
    UniStrptime := 0;
    Exit;
  End;
  L := LocOf(H, LC_TIME);
  ReadTm(PTm);
  PtPm := -1; PtHas12 := 0;
  GCur := 0;
  K := 0;
  Ok := True;
  C := RdW(PFmt);
  While Ok And (C <> 0) Do
  Begin
    If (C = 37) And (RdW(PFmt + K * 2 + 2) <> 0) Then
    Begin
      Inc(K);
      C := RdW(PFmt + K * 2);
      If ((C = 69) Or (C = 79)) And (RdW(PFmt + K * 2 + 2) <> 0) Then
      Begin
        Inc(K);
        C := RdW(PFmt + K * 2);
      End;
      Ok := ParseSpec(PIn, L, C);
    End
    Else If IsSpaceU(C) Then
    Begin
      While IsSpaceU(RdW(PIn + GCur * 2)) Do Inc(GCur);
    End
    Else If UToLower(RdW(PIn + GCur * 2)) = UToLower(C) Then Inc(GCur)
    Else Ok := False;
    Inc(K);
    C := RdW(PFmt + K * 2);
  End;
  If Not Ok Then
  Begin
    UniStrptime := 0;
    Exit;
  End;
  If (PtPm = 1) And (TmHour < 12) Then TmHour := TmHour + 12;
  If (PtPm = 0) And (PtHas12 = 0) And (TmHour = 12) Then TmHour := 0;
  If (TmMday >= 1) And (TmMday <= 31) Then
  Begin
    DateInfo(TmYear + 1900, TmMon + 1, TmMday, Wd, Yd);
    TmWday := Wd;
    TmYday := Yd;
  End;
  WrL(PTm, TmSec);
  WrL(PTm + 4, TmMin);
  WrL(PTm + 8, TmHour);
  WrL(PTm + 12, TmMday);
  WrL(PTm + 16, TmMon);
  WrL(PTm + 20, TmYear);
  WrL(PTm + 24, TmWday);
  WrL(PTm + 28, TmYday);
  UniStrptime := PIn + GCur * 2;
End;

{ --- UniStrfmon --- }

{ Chiffres de la partie entiere de GDbl2 (entier >= 0) }
Function DblDigits : String;
Var S : String; N : LongInt;
Begin
  S := '';
  N := 0;
  Repeat
    GQ := Int(GDbl2 / 10);
    GD := GDbl2 - GQ * 10;
    S := Chr(48 + Round(GD)) + S;
    GDbl2 := GQ;
    Inc(N);
  Until (GDbl2 < 1) Or (N > 300);
  DblDigits := S;
End;

{ Separateurs de milliers (groupes G : '3' ou '3;2') }
Function Grouped(S, Sep, G : String) : String;
Var R : String; Gs, K, N : LongInt;
Begin
  Gs := StrInt(G);
  If (Gs <= 0) Or (Sep = '') Then
  Begin
    Grouped := S;
    Exit;
  End;
  R := '';
  N := 0;
  For K := Length(S) DownTo 1 Do
  Begin
    If (N > 0) And ((N Mod Gs) = 0) Then R := Sep + R;
    R := S[K] + R;
    Inc(N);
  End;
  Grouped := R;
End;

{ Formater GDbl selon une conversion de UniStrfmon (Intl : %i) }
Function MonFmt(L : LongInt; Intl, NoGroup, Paren, NoSym, Left : Boolean; Fill : String;
                Width, LeftP, RightP : LongInt) : String;
Var Neg : Boolean; IntS, FracS, Num, Sym, Sg, S : String; K, Pcs, Sep, Posn, P10 : LongInt;
Begin
  GMV := GDbl;
  Neg := GMV < 0;
  If Neg Then GMV := -GMV;
  If RightP < 0 Then
  Begin
    If Intl Then RightP := LocI(L, FIntFrac) Else RightP := LocI(L, FFrac);
    If RightP < 0 Then RightP := 2;
  End;
  P10 := 1;
  For K := 1 To RightP Do P10 := P10 * 10;
  GMV := Int(GMV * P10 + 0.5);
  GDbl2 := Int(GMV / P10);
  IntS := DblDigits;
  GDbl2 := GMV - Int(GMV / P10) * P10;
  FracS := DblDigits;
  While Length(FracS) < RightP Do FracS := '0' + FracS;
  K := Length(IntS);
  If Not NoGroup Then IntS := Grouped(IntS, LocItem(L, 67), LocItem(L, 69));
  { precision a gauche : remplissage (sans separateurs) }
  While K < LeftP Do
  Begin
    IntS := Fill + IntS;
    Inc(K);
  End;
  Num := IntS;
  If RightP > 0 Then
  Begin
    S := LocItem(L, 66);
    If S = '' Then S := LocItem(L, 44);
    If S = '' Then S := '.';
    Num := Num + S + FracS;
  End;
  If Intl Then Sym := LocItem(L, 87) Else Sym := LocItem(L, 48);
  If Neg Then
  Begin
    Pcs := LocI(L, FNcs); Sep := LocI(L, FNsep); Posn := LocI(L, FNsign);
    Sg := LocItem(L, 93);
    If Sg = '' Then Sg := '-';
  End
  Else
  Begin
    Pcs := LocI(L, FPcs); Sep := LocI(L, FPsep); Posn := LocI(L, FPsign);
    Sg := LocItem(L, 92);
  End;
  If Paren Then Posn := 0;
  If Intl Then
  Begin
    { le symbole international contient son espace }
    While (Length(Sym) > 0) And (Ord(Sym[Length(Sym)]) = 32) Do Sym := Copy(Sym, 1, Length(Sym) - 1);
    If Sym <> '' Then Sep := 1;
  End;
  If NoSym Or (Sym = '') Then S := Num
  Else If Pcs = 1 Then
  Begin
    If Posn = 3 Then Sym := Sg + Sym Else If Posn = 4 Then Sym := Sym + Sg;
    If Sep = 1 Then S := Sym + ' ' + Num Else S := Sym + Num;
  End
  Else
  Begin
    If Posn = 3 Then Sym := Sg + Sym Else If Posn = 4 Then Sym := Sym + Sg;
    If Sep = 1 Then S := Num + ' ' + Sym Else S := Num + Sym;
  End;
  If Neg Or Paren Then
  Begin
    If Posn = 0 Then
    Begin
      If Neg Then S := '(' + S + ')' Else S := ' ' + S + ' ';
    End
    Else If (Posn = 1) Or (NoSym And ((Posn = 3) Or (Posn = 4))) Then S := Sg + S
    Else If Posn = 2 Then S := S + Sg;
  End
  Else If (Posn = 1) Or (Posn < 0) Then S := Sg + S
  Else If Posn = 2 Then S := S + Sg;
  While Length(S) < Width Do
    If Left Then S := S + ' ' Else S := ' ' + S;
  MonFmt := S;
End;

{ UniStrfmon(lo, ucs, max, fmt, ...) : valeurs double a la suite du
  format ; rend le nombre de caracteres ecrits, -1 si le tampon est trop
  petit }
Function UniStrfmon(H, PBuf, Max, PFmt, V0, V1, V2, V3, V4, V5, V6, V7, V8, V9, V10, V11, V12, V13, V14, V15 : LongInt) : LongInt;
Var L, K, C, N, J, Ai, Width, LeftP, RightP : LongInt; S, Fill : String;
    Ok, Intl, NoGroup, Paren, NoSym, Left, Flags : Boolean;
Begin
  GArg[0] := V0; GArg[1] := V1; GArg[2] := V2; GArg[3] := V3;
  GArg[4] := V4; GArg[5] := V5; GArg[6] := V6; GArg[7] := V7;
  GArg[8] := V8; GArg[9] := V9; GArg[10] := V10; GArg[11] := V11;
  GArg[12] := V12; GArg[13] := V13; GArg[14] := V14; GArg[15] := V15;
  If (PBuf = 0) Or (PFmt = 0) Or (Max <= 0) Then
  Begin
    UniStrfmon := -1;
    Exit;
  End;
  L := LocOf(H, LC_MONETARY);
  N := 0; K := 0; Ai := 0;
  Ok := True;
  C := RdW(PFmt);
  While Ok And (C <> 0) Do
  Begin
    S := '';
    If (C = 37) And (RdW(PFmt + K * 2 + 2) = 37) Then
    Begin
      Inc(K);
      S := '%';
    End
    Else If C = 37 Then
    Begin
      Fill := ' ';
      NoGroup := False; Paren := False; NoSym := False; Left := False;
      Flags := True;
      While Flags Do
      Begin
        Inc(K);
        C := RdW(PFmt + K * 2);
        If C = 61 Then
        Begin
          Inc(K);
          Fill := Chr(UniByte(RdW(PFmt + K * 2)));
        End
        Else If C = 94 Then NoGroup := True
        Else If C = 40 Then Paren := True
        Else If C = 43 Then Paren := False
        Else If C = 33 Then NoSym := True
        Else If C = 45 Then Left := True
        Else Flags := False;
      End;
      Width := 0;
      While (C >= 48) And (C <= 57) Do
      Begin
        Width := Width * 10 + C - 48;
        Inc(K);
        C := RdW(PFmt + K * 2);
      End;
      LeftP := 0;
      If C = 35 Then
      Begin
        Inc(K);
        C := RdW(PFmt + K * 2);
        While (C >= 48) And (C <= 57) Do
        Begin
          LeftP := LeftP * 10 + C - 48;
          Inc(K);
          C := RdW(PFmt + K * 2);
        End;
      End;
      RightP := -1;
      If C = 46 Then
      Begin
        RightP := 0;
        Inc(K);
        C := RdW(PFmt + K * 2);
        While (C >= 48) And (C <= 57) Do
        Begin
          RightP := RightP * 10 + C - 48;
          Inc(K);
          C := RdW(PFmt + K * 2);
        End;
      End;
      If ((C = 110) Or (C = 105)) And (Ai < 8) Then
      Begin
        Intl := C = 105;
        DblIn(GArg[Ai * 2], GArg[Ai * 2 + 1]);
        Inc(Ai);
        S := MonFmt(L, Intl, NoGroup, Paren, NoSym, Left, Fill, Width, LeftP, RightP);
      End
      Else Ok := False;
    End
    Else
    Begin
      If N < Max - 1 Then
      Begin
        WrW(PBuf + N * 2, C);
        Inc(N);
      End
      Else Ok := False;
    End;
    For J := 1 To Length(S) Do
      If N < Max - 1 Then
      Begin
        WrW(PBuf + N * 2, ByteUni(Ord(S[J])));
        Inc(N);
      End
      Else Ok := False;
    Inc(K);
    C := RdW(PFmt + K * 2);
  End;
  WrW(PBuf + N * 2, 0);
  If Ok Then UniStrfmon := N Else UniStrfmon := -1;
End;

{ ==================================================================== }
{ Partie 11 - Fonctions : locales de l'utilisateur, noms               }
{ ==================================================================== }

{ Ecrire les locales de l'utilisateur et les remplacements }
Function EscStr(S : String) : String;
Var R : String; K, C : LongInt;
Begin
  R := '';
  For K := 1 To Length(S) Do
  Begin
    C := Ord(S[K]);
    If (C < 32) Or (C >= 128) Or (C = 35) Then R := R + '#' + Copy(HexStr(C), 3, 2) Else R := R + S[K];
  End;
  EscStr := R;
End;

Procedure OutLine(S : String);
Var K : LongInt;
Begin
  S := S + Chr(13) + Chr(10);
  For K := 1 To Length(S) Do
    If IoLen < 8190 Then
    Begin
      IoBuf[IoLen] := Ord(S[K]);
      Inc(IoLen);
    End;
End;

{ UniMakeUserLocale(ucsNom, ucsBase) : nouvelle locale de l'utilisateur,
  copie de la locale de base }
Function UniMakeUserLocale(PName, PBase : LongInt) : LongInt;
Var N : String; B, I, K, F : LongInt;
Begin
  N := GetU(PName);
  If (N = '') Or (Length(N) > 31) Or (Pos(' ', N) > 0) Then
  Begin
    UniMakeUserLocale := ULS_INVALID;
    Exit;
  End;
  If FindLoc(N) >= 0 Then
  Begin
    UniMakeUserLocale := ULS_INVALID;
    Exit;
  End;
  B := FindLoc(GetU(PBase));
  If B < 0 Then
  Begin
    UniMakeUserLocale := ULS_UNSUPPORTED;
    Exit;
  End;
  F := -1;
  For I := MaxLoc - 1 DownTo NSysLoc Do
    If Not LUsed[I] Then F := I;
  If F < 0 Then
  Begin
    UniMakeUserLocale := ULS_NOMEMORY;
    Exit;
  End;
  For K := 0 To NF - 1 Do LSet(F * NF + K, LGet(B * NF + K));
  LSet(F * NF + FName, N);
  { anciens remplacements de cette place retires }
  For K := 0 To MaxOv - 1 Do
    If (OvLoc[K] = F) Then OvItem[K] := 0;
  LUsed[F] := True;
  UniMakeUserLocale := ULS_SUCCESS;
End;

{ UniSetUserLocaleItem(ucsNom, item, type, valeur) : type 1 chaine
  UniChar, type 2 entier }
Function UniSetUserLocaleItem(PName, Item, Typ, Value : LongInt) : LongInt;
Var L, K, F : LongInt; S : String;
Begin
  L := FindLoc(GetU(PName));
  If L < 0 Then
  Begin
    UniSetUserLocaleItem := ULS_UNSUPPORTED;
    Exit;
  End;
  If (Item < 1) Or (Item > MaxItem) Then
  Begin
    UniSetUserLocaleItem := ULS_INVALID;
    Exit;
  End;
  If Typ = 1 Then S := GetU(Value)
  Else If Typ = 2 Then
  Begin
    If (Item = 50) Or (Item = 51) Then S := HexStr(Value) Else S := IntStr(Value);
  End
  Else
  Begin
    UniSetUserLocaleItem := ULS_INVALID;
    Exit;
  End;
  F := OvFind(L, Item);
  If F < 0 Then
    For K := MaxOv - 1 DownTo 0 Do
      If OvItem[K] = 0 Then F := K;
  If F < 0 Then
  Begin
    UniSetUserLocaleItem := ULS_NOMEMORY;
    Exit;
  End;
  OvLoc[F] := L;
  OvItem[F] := Item;
  OvSet(F, Copy(S, 1, 127));
  UniSetUserLocaleItem := ULS_SUCCESS;
End;

{ UniDeleteUserLocale(ucsNom) : retirer une locale de l'utilisateur (et
  ses remplacements) ou les remplacements d'une locale du systeme }
Function UniDeleteUserLocale(PName : LongInt) : LongInt;
Var L, K : LongInt;
Begin
  L := FindLoc(GetU(PName));
  If L < 0 Then
  Begin
    UniDeleteUserLocale := ULS_UNSUPPORTED;
    Exit;
  End;
  For K := 0 To MaxOv - 1 Do
    If OvLoc[K] = L Then OvItem[K] := 0;
  If L >= NSysLoc Then LUsed[L] := False;
  UniDeleteUserLocale := ULS_SUCCESS;
End;

{ UniCompleteUserLocale : ecrire les locales de l'utilisateur et les
  remplacements dans C:\USERLOC.INI }
Function UniCompleteUserLocale : LongInt;
Var K, H, Act, W, R : LongInt;
Begin
  IoLen := 0;
  OutLine('; Locales de l''utilisateur (LIBUNI.DLL)');
  For K := NSysLoc To MaxLoc - 1 Do
    If LUsed[K] Then
      OutLine('USER ' + LGet(K * NF + FName));
  For K := NSysLoc To MaxLoc - 1 Do
    If LUsed[K] Then
      For W := 0 To NF - 1 Do
        OutLine('FIELD ' + LGet(K * NF + FName) + ' ' + IntStr(W) + ' ' + EscStr(LGet(K * NF + W)));
  For K := 0 To MaxOv - 1 Do
    If (OvItem[K] <> 0) And LUsed[OvLoc[K]] Then
      OutLine('ITEM ' + LGet(OvLoc[K] * NF + FName) + ' ' + IntStr(OvItem[K]) + ' ' + EscStr(OvGet(K)));
  PutZ(LongInt(@NameZ), UserFile);
  R := DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, $12, $41, 0);
  If R = 0 Then
  Begin
    R := DcWrite(H, LongInt(@IoBuf), IoLen, LongInt(@W));
    Dummy := DcClose(H);
  End;
  If R = 0 Then UniCompleteUserLocale := ULS_SUCCESS Else UniCompleteUserLocale := ULS_OTHER;
End;

{ Relire C:\USERLOC.INI au chargement }
Procedure LoadUser;
Var H, Act, P, K, L, Sp, It, F : LongInt; S, A, B : String;
Begin
  PutZ(LongInt(@NameZ), UserFile);
  IoLen := 0;
  If DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> 0 Then Exit;
  Dummy := DcRead(H, LongInt(@IoBuf), 8190, LongInt(@IoLen));
  Dummy := DcClose(H);
  P := 0;
  While P < IoLen Do
  Begin
    S := '';
    While (P < IoLen) And (IoBuf[P] <> 10) Do
    Begin
      If (IoBuf[P] <> 13) And (Length(S) < 250) Then S := S + Chr(IoBuf[P]);
      Inc(P);
    End;
    Inc(P);
    Sp := Pos(' ', S);
    If Sp > 0 Then
    Begin
      A := Copy(S, 1, Sp - 1);
      S := Copy(S, Sp + 1, 255);
      Sp := Pos(' ', S);
      If Sp = 0 Then Sp := Length(S) + 1;
      B := Copy(S, 1, Sp - 1);
      S := Copy(S, Sp + 1, 255);
      If A = 'USER' Then
      Begin
        If FindLoc(B) < 0 Then
        Begin
          L := -1;
          For K := MaxLoc - 1 DownTo NSysLoc Do
            If Not LUsed[K] Then L := K;
          If L >= 0 Then
          Begin
            For K := 0 To NF - 1 Do LSet(L * NF + K, '');
            LSet(L * NF + FName, B);
            LUsed[L] := True;
          End;
        End;
      End
      Else If (A = 'FIELD') Or (A = 'ITEM') Then
      Begin
        L := FindLoc(B);
        Sp := Pos(' ', S);
        If Sp = 0 Then Sp := Length(S) + 1;
        It := StrInt(Copy(S, 1, Sp - 1));
        S := Unesc(Copy(S, Sp + 1, 255));
        If (L >= NSysLoc) And (A = 'FIELD') And (It > 0) And (It < NF) Then LSet(L * NF + It, S);
        If (L >= 0) And (A = 'ITEM') And (It >= 1) And (It <= MaxItem) Then
        Begin
          F := -1;
          For K := MaxOv - 1 DownTo 0 Do
            If OvItem[K] = 0 Then F := K;
          If F >= 0 Then
          Begin
            OvLoc[F] := L;
            OvItem[F] := It;
            OvSet(F, Copy(S, 1, 127));
          End;
        End;
      End;
    End;
  End;
End;

{ UniGetOverride(ucsNom, item, pp) (OS/2-0) : remplacement d'un element
  (UniFreeMem) ; ULS_NOMATCH s'il n'y en a pas }
Function UniGetOverride(PName, Item, PP : LongInt) : LongInt;
Var L, K, A : LongInt;
Begin
  If PP <> 0 Then WrL(PP, 0);
  L := FindLoc(GetU(PName));
  If L < 0 Then UniGetOverride := ULS_UNSUPPORTED
  Else If PP = 0 Then UniGetOverride := ULS_INVALID
  Else
  Begin
    K := OvFind(L, Item);
    If K < 0 Then UniGetOverride := ULS_NOMATCH
    Else
    Begin
      A := AllocU(OvGet(K));
      WrL(PP, A);
      If A = 0 Then UniGetOverride := ULS_NOMEMORY Else UniGetOverride := ULS_SUCCESS;
    End;
  End;
End;

{ UniQueryLocaleList(drapeaux, ucs, n) : noms separes par des espaces
  (1 : locales du systeme, 2 : de l'utilisateur) }
Function UniQueryLocaleList(Flags, PBuf, N : LongInt) : LongInt;
Var K, Cur, J : LongInt; S : String; Ok : Boolean;
Begin
  If (PBuf = 0) Or (N <= 0) Or ((Flags And 3) = 0) Then
  Begin
    UniQueryLocaleList := ULS_INVALID;
    Exit;
  End;
  Cur := 0;
  Ok := True;
  For K := 0 To MaxLoc - 1 Do
    If LUsed[K] And ((((Flags And 1) <> 0) And (K < NSysLoc)) Or (((Flags And 2) <> 0) And (K >= NSysLoc))) Then
    Begin
      S := LGet(K * NF + FName);
      If Cur > 0 Then S := ' ' + S;
      For J := 1 To Length(S) Do
        If Cur < N - 1 Then
        Begin
          WrW(PBuf + Cur * 2, Ord(S[J]));
          Inc(Cur);
        End
        Else Ok := False;
    End;
  WrW(PBuf + Cur * 2, 0);
  If Ok Then UniQueryLocaleList := ULS_SUCCESS Else UniQueryLocaleList := ULS_BUFFERFULL;
End;

{ Code de langue (2 lettres) ou de pays d'un nom de locale }
Function Code2(S : String; Ctry : Boolean) : String;
Var K : LongInt;
Begin
  K := Pos('_', S);
  If K = 0 Then K := Pos('-', S);
  If Ctry And (K > 0) Then S := Copy(S, K + 1, 2)
  Else If K > 0 Then S := Copy(S, 1, K - 1);
  If Ctry Then Code2 := UpStr(Copy(S, 1, 2)) Else Code2 := LowStr(Copy(S, 1, 2));
End;

{ UniQueryLanguageName(ucsLangue, ucsLangueNom, pp) : nom de la langue
  en anglais (defaut), en francais ou dans la langue elle-meme }
Function UniQueryLanguageName(PLang, PIso, PP : LongInt) : LongInt;
Var Li, K, A : LongInt; Lg, Iso, S : String;
Begin
  If PP = 0 Then
  Begin
    UniQueryLanguageName := ULS_INVALID;
    Exit;
  End;
  WrL(PP, 0);
  Lg := Code2(GetU(PLang), False);
  Iso := Code2(GetU(PIso), False);
  Li := -1;
  For K := NLang - 1 DownTo 0 Do
    If LangCode[K] = Lg Then Li := K;
  If Li < 0 Then
  Begin
    UniQueryLanguageName := ULS_UNSUPPORTED;
    Exit;
  End;
  If Iso = 'fr' Then S := LangF(Li, 39)
  Else If Iso = Lg Then S := LangF(Li, 40)
  Else S := LangF(Li, 38);
  A := AllocU(S);
  WrL(PP, A);
  If A = 0 Then UniQueryLanguageName := ULS_NOMEMORY Else UniQueryLanguageName := ULS_SUCCESS;
End;

{ UniQueryCountryName(ucsPays, ucsLangue, pp) : nom du pays en anglais
  (defaut), en francais ou dans sa langue }
Function UniQueryCountryName(PCtry, PIso, PP : LongInt) : LongInt;
Var Ci, A : LongInt; C, Iso : String;
Begin
  If PP = 0 Then
  Begin
    UniQueryCountryName := ULS_INVALID;
    Exit;
  End;
  WrL(PP, 0);
  C := Code2(GetU(PCtry), Pos('_', GetU(PCtry)) > 0);
  If Pos('_', GetU(PCtry)) = 0 Then C := UpStr(Copy(GetU(PCtry), 1, 2));
  Iso := Code2(GetU(PIso), False);
  Ci := CtryIdx(C);
  If Ci < 0 Then
  Begin
    UniQueryCountryName := ULS_UNSUPPORTED;
    Exit;
  End;
  A := AllocU(CtryName(Ci, Iso));
  WrL(PP, A);
  If A = 0 Then UniQueryCountryName := ULS_NOMEMORY Else UniQueryCountryName := ULS_SUCCESS;
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  UniQueryXdigit Index 1 Name 'UniQueryXdigit',
  UniQuerySpace Index 2 Name 'UniQuerySpace',
  UniQueryPrint Index 3 Name 'UniQueryPrint',
  UniQueryGraph Index 4 Name 'UniQueryGraph',
  UniQueryCntrl Index 5 Name 'UniQueryCntrl',
  UniQueryAlpha Index 6 Name 'UniQueryAlpha',
  UniFreeAttrObject Index 7 Name 'UniFreeAttrObject',
  UniQueryCharAttr Index 8 Name 'UniQueryCharAttr',
  UniQueryUpper Index 9 Name 'UniQueryUpper',
  UniQueryPunct Index 10 Name 'UniQueryPunct',
  UniQueryLower Index 11 Name 'UniQueryLower',
  UniQueryDigit Index 12 Name 'UniQueryDigit',
  UniQueryBlank Index 13 Name 'UniQueryBlank',
  UniQueryAlnum Index 14 Name 'UniQueryAlnum',
  UniScanForAttr Index 15 Name 'UniScanForAttr',
  UniCreateAttrObject Index 16 Name 'UniCreateAttrObject',
  UniCreateTransformObject Index 17 Name 'UniCreateTransformObject',
  UniFreeTransformObject Index 18 Name 'UniFreeTransformObject',
  UniQueryLocaleObject Index 19 Name 'UniQueryLocaleObject',
  UniCreateLocaleObject Index 20 Name 'UniCreateLocaleObject',
  UniFreeLocaleObject Index 21 Name 'UniFreeLocaleObject',
  UniFreeMem Index 22 Name 'UniFreeMem',
  UniFreeLocaleInfo Index 28 Name 'UniFreeLocaleInfo',
  UniQueryLocaleInfo Index 29 Name 'UniQueryLocaleInfo',
  UniQueryLocaleItem Index 30 Name 'UniQueryLocaleItem',
  UniStrcat Index 31 Name 'UniStrcat',
  UniStrchr Index 32 Name 'UniStrchr',
  UniStrcmp Index 33 Name 'UniStrcmp',
  UniStrcmpi Index 34 Name 'UniStrcmpi',
  UniStrcoll Index 35 Name 'UniStrcoll',
  UniStrcpy Index 36 Name 'UniStrcpy',
  UniStrcspn Index 37 Name 'UniStrcspn',
  UniStrfmon Index 38 Name 'UniStrfmon',
  UniStrftime Index 39 Name 'UniStrftime',
  UniStrlen Index 40 Name 'UniStrlen',
  UniStrncat Index 41 Name 'UniStrncat',
  UniStrncmp Index 42 Name 'UniStrncmp',
  UniStrncmpi Index 43 Name 'UniStrncmpi',
  UniStrncpy Index 44 Name 'UniStrncpy',
  UniStrpbrk Index 45 Name 'UniStrpbrk',
  UniStrptime Index 46 Name 'UniStrptime',
  UniStrrchr Index 47 Name 'UniStrrchr',
  UniStrspn Index 48 Name 'UniStrspn',
  UniStrstr Index 49 Name 'UniStrstr',
  UniStrtod Index 50 Name 'UniStrtod',
  UniStrtol Index 51 Name 'UniStrtol',
  UniStrtoul Index 52 Name 'UniStrtoul',
  UniStrxfrm Index 53 Name 'UniStrxfrm',
  UniLocaleStrToToken Index 54 Name 'UniLocaleStrToToken',
  UniLocaleTokenToStr Index 55 Name 'UniLocaleTokenToStr',
  UniTransformStr Index 56 Name 'UniTransformStr',
  UniTransLower Index 57 Name 'UniTransLower',
  UniTransUpper Index 58 Name 'UniTransUpper',
  UniTolower Index 59 Name 'UniTolower',
  UniToupper Index 60 Name 'UniToupper',
  UniStrupr Index 61 Name 'UniStrupr',
  UniStrlwr Index 62 Name 'UniStrlwr',
  UniStrtok Index 63 Name 'UniStrtok',
  UniMapCtryToLocale Index 67 Name 'UniMapCtryToLocale',
  UniMakeKey Index 70 Name 'UniMakeKey',
  UniQueryChar Index 71 Name 'UniQueryChar',
  UniGetOverride Index 72 Name 'UniGetOverride',
  UniGetColval Index 73 Name 'UniGetColval',
  UniQueryAttr Index 74 Name 'UniQueryAttr',
  UniQueryStringType Index 75 Name 'UniQueryStringType',
  UniQueryCharType Index 76 Name 'UniQueryCharType',
  UniQueryNumericValue Index 77 Name 'UniQueryNumericValue',
  UniQueryCharTypeTable Index 78 Name 'UniQueryCharTypeTable',
  UniProcessUconv Index 80 Name 'UniProcessUconv',
  Locale Index 151 Name 'Locale',
  UniMakeUserLocale Index 152 Name 'UniMakeUserLocale',
  UniSetUserLocaleItem Index 153 Name 'UniSetUserLocaleItem',
  UniDeleteUserLocale Index 154 Name 'UniDeleteUserLocale',
  UniCompleteUserLocale Index 155 Name 'UniCompleteUserLocale',
  UniQueryLocaleValue Index 156 Name 'UniQueryLocaleValue',
  UniQueryLocaleList Index 157 Name 'UniQueryLocaleList',
  UniQueryLanguageName Index 158 Name 'UniQueryLanguageName',
  UniQueryCountryName Index 159 Name 'UniQueryCountryName';

Var
  InitI : LongInt;

BEGIN
  For InitI := 0 To MaxLoc - 1 Do LUsed[InitI] := InitI < NSysLoc;
  For InitI := 0 To MaxOv - 1 Do
  Begin
    OvItem[InitI] := 0;
    OvLoc[InitI] := -1;
  End;
  For InitI := 0 To 5 Do GDef[InitI] := '';
  For InitI := 0 To MaxLObj - 1 Do
  Begin
    LOOwn[InitI] := 0;
    LOGen[InitI] := 0;
  End;
  For InitI := 0 To MaxAObj - 1 Do
  Begin
    AOOwn[InitI] := 0;
    AOGen[InitI] := 0;
  End;
  For InitI := 0 To MaxXObj - 1 Do
  Begin
    XOOwn[InitI] := 0;
    XOGen[InitI] := 0;
  End;
  For InitI := 0 To PoolN - 1 Do PoolOwn[InitI] := 0;
  TTN := 0;
  TTLast := -1;
  TTFull := False;
  GTokPos := 0;
  InitLocData;
  InitLangData;
  LoadUser;
END.
