{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de PMMERGE.DLL sous OS/2-0.
}

Program TESTMRG;

{$R-,S-,I-}

{ Compilation : OS2PC TESTMRG.PAS   (produit TESTMRG.EXE)

  TESTMRG verifie PMMERGE.DLL : ses 1039 ordinaux, les profils (fichier
  INI au format binaire d'OS/2 : chaines, entiers, donnees, listes des
  applications et des cles, suppression, relecture apres fermeture, profil
  de l'utilisateur), la liste des programmes et des groupes, les relais
  vers PMWIN.DLL (rectangles, atomes, version, file de messages, fenetres)
  et les fonctions de Warp 4 (proprietes, champ de saisie Edit*, couleurs
  des controles, zone de travail du bureau, curseur DAX, tas WinXX,
  memoire SS*, semaphores en memoire, pages de codes, entrees internes).
  Pendant l'essai des fenetres, l'ecran passe brievement en mode
  graphique (PMWIN.DLL). }

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';

Function PrfOpenProfile(Hab, P : LongInt) : LongInt; External 'PMMERGE';
Function PrfCloseProfile(H : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProfileInt(H, A, K, Df : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProfileSize(H, A, K, P : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProfileData(H, A, K, B, P : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteProfileData(H, A, K, D, C : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProfile(Hab, P : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteToDisk(H : LongInt) : LongInt; External 'PMMERGE';
Function PrfSuspendWriteToDisk(H, F : LongInt) : LongInt; External 'PMMERGE';
Function Prf32QueryProfileInt(H, A, K, Df : LongInt) : LongInt; External 'PMMERGE';
Function WinWriteProfileString(Hab, A, K, D : LongInt) : LongInt; External 'PMMERGE';
Function WinQueryProfileString(Hab, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfCreateGroup(H, T, V : LongInt) : LongInt; External 'PMMERGE';
Function PrfDestroyGroup(H, G : LongInt) : LongInt; External 'PMMERGE';
Function PrfAddProgram(H, D, G : LongInt) : LongInt; External 'PMMERGE';
Function PrfChangeProgram(H, P, D : LongInt) : LongInt; External 'PMMERGE';
Function PrfRemoveProgram(H, P : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryDefinition(H, P, D, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProgramTitles(H, G, B, M, PC : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProgramHandle(H, E, B, M, PC : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProgramCategory(H, E : LongInt) : LongInt; External 'PMMERGE';

Function WinInitialize(F : LongInt) : LongInt; External 'PMMERGE';
Function Win32Terminate(Hab : LongInt) : LongInt; External 'PMMERGE';
Function WinQueryVersion(Hab : LongInt) : LongInt; External 'PMMERGE';
Function Win32CreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMMERGE';
Function WinDestroyMsgQueue(H : LongInt) : LongInt; External 'PMMERGE';
Function WinSetRect(Hab, P, A, B, C, D : LongInt) : LongInt; External 'PMMERGE';
Function Win32UnionRect(Hab, PD, P1, P2 : LongInt) : LongInt; External 'PMMERGE';
Function WinIntersectRect(Hab, PD, P1, P2 : LongInt) : LongInt; External 'PMMERGE';
Function WinCreateAtomTable(A, B : LongInt) : LongInt; External 'PMMERGE';
Function Win32AddAtom(H, P : LongInt) : LongInt; External 'PMMERGE';
Function WinQueryAtomUsage(H, A : LongInt) : LongInt; External 'PMMERGE';
Function Win32IncrementAtomUsage(H, A : LongInt) : LongInt; External 'PMMERGE';
Function LookupAtom(H, P : LongInt) : LongInt; External 'PMMERGE';
Function WinDestroyAtomTable(H : LongInt) : LongInt; External 'PMMERGE';
Function Win32CreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMMERGE';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMMERGE';
Function Win32QueryWindowText(H, C, P : LongInt) : LongInt; External 'PMMERGE';
Function WinGetLastError(Hab : LongInt) : LongInt; External 'PMMERGE';
Function Win32QuerySysValue(H, I : LongInt) : LongInt; External 'PMMERGE';
Function WinSetProperty(H, P, V, F : LongInt) : LongInt; External 'PMMERGE';
Function WinQueryProperty(H, P : LongInt) : LongInt; External 'PMMERGE';
Function WinRemoveProperty(H, P : LongInt) : LongInt; External 'PMMERGE';
Function WinEnumProperties(H, F, P : LongInt) : LongInt; External 'PMMERGE';
Function WinSetClassProperty(Hab, C, P, V : LongInt) : LongInt; External 'PMMERGE';
Function WinQueryClassProperty(Hab, C, P : LongInt) : LongInt; External 'PMMERGE';
Function EditCreate(HPar, X, Y, Cx, Cy, Id : LongInt) : LongInt; External 'PMMERGE';
Function EditSetText(H, P : LongInt) : LongInt; External 'PMMERGE';
Function EditSetSelection(H, S, E : LongInt) : LongInt; External 'PMMERGE';
Function EditReplace(H, P : LongInt) : LongInt; External 'PMMERGE';
Function EditGetFlags(H : LongInt) : LongInt; External 'PMMERGE';
Function EditCXFromICH(H, I : LongInt) : LongInt; External 'PMMERGE';
Function Win32IsWindowOfClass(H, C : LongInt) : LongInt; External 'PMMERGE';
Function WinSetControlColors(H, T, F, N, P : LongInt) : LongInt; External 'PMMERGE';
Function WinQueryControlColors(H, T, F, N, P : LongInt) : LongInt; External 'PMMERGE';
Function WinSetDesktopWorkArea(H, P : LongInt) : LongInt; External 'PMMERGE';
Function WinQueryDesktopWorkArea(H, P : LongInt) : LongInt; External 'PMMERGE';
Function DaxGetCaretBlinkTime : LongInt; External 'PMMERGE';
Function DaxSwapMouseButton(F : LongInt) : LongInt; External 'PMMERGE';
Function WinXXCreateHeap(S, C, G, A, B, O : LongInt) : LongInt; External 'PMMERGE';
Function WinXXAllocMem(H, C : LongInt) : LongInt; External 'PMMERGE';
Function WinXXIsMemInHeap(H, P : LongInt) : LongInt; External 'PMMERGE';
Function WinXXQueryMemSize(H, P : LongInt) : LongInt; External 'PMMERGE';
Function WinXXReallocMem(H, P, A, B : LongInt) : LongInt; External 'PMMERGE';
Function WinXXFreeMem(H, P, C : LongInt) : LongInt; External 'PMMERGE';
Function WinXXDestroyHeap(H : LongInt) : LongInt; External 'PMMERGE';
Function SSAllocMem(PP, C, F : LongInt) : LongInt; External 'PMMERGE';
Function SSFreeMem(P : LongInt) : LongInt; External 'PMMERGE';
Function RamSemRequest32(P, T : LongInt) : LongInt; External 'PMMERGE';
Function RamSemClear16(P : LongInt) : LongInt; External 'PMMERGE';
Function WinQueryCpType(Cp : LongInt) : LongInt; External 'PMMERGE';
Function GreEntry3(A, B, F : LongInt) : LongInt; External 'PMMERGE';
Function TidCurrent : LongInt; External 'PMMERGE';
Function ValidateDCHandle(H : LongInt) : LongInt; External 'PMMERGE';
Function SetDriverInfo(H, I, V, F : LongInt) : LongInt; External 'PMMERGE';
Function GetDriverInfo32(H, I, F : LongInt) : LongInt; External 'PMMERGE';
Function ShellWindow : LongInt; External 'PMMERGE';
Function WinUpper(Hab, Cp, Cc, P : LongInt) : LongInt; External 'PMMERGE';

Const
  HINI_PROFILE = 0; HINI_USERPROFILE = -1; SGH_ROOT = -1;
  NOrd = 1039;
  Ords : Array[0..1038] Of Word = (
    2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015,
    2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031,
    2032, 2033, 2034, 2035, 2036, 2037, 2038, 2039, 2040, 2041, 2042, 2043, 2044, 2045, 2046, 2047,
    2048, 2049, 2050, 2051, 2052, 2053, 2054, 2055, 2056, 2057, 2058, 2059, 2060, 2061, 2062, 2063,
    2064, 2065, 2066, 2067, 2068, 2069, 2070, 2071, 2072, 2073, 2074, 2075, 2076, 2077, 2078, 2079,
    2080, 2081, 2082, 2083, 2084, 2085, 2086, 2087, 2088, 2089, 2090, 2091, 2092, 2093, 2094, 2095,
    2096, 2097, 2098, 2099, 2100, 2101, 2102, 2103, 2104, 2105, 2106, 2107, 2108, 2109, 2110, 2111,
    2112, 2113, 2114, 2115, 2116, 2117, 2118, 2119, 2120, 2121, 2122, 2123, 2124, 2125, 2126, 2127,
    2128, 2129, 2130, 2131, 2132, 2133, 2134, 2135, 2136, 2137, 2138, 2139, 2140, 2141, 2142, 2143,
    2144, 2145, 2146, 2147, 2148, 2149, 2150, 2151, 2152, 2153, 2154, 2155, 2156, 2157, 2158, 2159,
    2160, 2161, 2162, 2163, 2164, 2165, 2166, 2167, 2168, 2169, 2170, 2171, 2172, 2173, 2174, 2175,
    2176, 2177, 2178, 2179, 2180, 2181, 2182, 2183, 3000, 3001, 3002, 3003, 3004, 3005, 3006, 3007,
    3008, 3009, 3010, 3011, 3012, 3013, 3014, 3015, 3016, 3017, 3018, 3019, 3020, 3021, 3022, 3023,
    3024, 3025, 3026, 3027, 3028, 3029, 3030, 3031, 3032, 3033, 3034, 3035, 3036, 3037, 3038, 3039,
    3040, 3041, 3042, 3043, 3044, 3045, 3046, 3047, 3048, 3049, 3050, 3051, 3052, 3053, 3054, 3055,
    3056, 3057, 3058, 3059, 3060, 3061, 3062, 3063, 3064, 3065, 3066, 3067, 3068, 3069, 3070, 3071,
    3072, 3073, 3074, 3075, 3076, 3077, 3078, 3079, 3080, 3081, 3082, 3083, 3084, 3085, 3086, 3087,
    3088, 3089, 3090, 3091, 3092, 3093, 3094, 3095, 3096, 3097, 3098, 3099, 3100, 3101, 3102, 3103,
    3104, 3105, 3106, 3107, 3108, 3109, 3110, 3111, 3112, 3113, 3114, 3115, 3116, 3117, 3118, 3119,
    3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127, 3128, 3129, 3130, 3131, 3132, 3133, 3134, 3135,
    3136, 3137, 3138, 3139, 3140, 3141, 3142, 3143, 3144, 3145, 3146, 3147, 3148, 3149, 3150, 3151,
    3152, 3153, 3154, 3155, 3156, 3157, 3158, 3159, 3160, 3161, 3162, 3163, 3164, 3165, 3166, 3167,
    3168, 3169, 3170, 3171, 3172, 3173, 3174, 3175, 3176, 3177, 3178, 3179, 3180, 3181, 3182, 3183,
    3184, 3185, 3186, 3187, 3188, 3189, 3190, 3191, 3192, 3193, 3194, 3195, 3196, 3197, 3198, 3199,
    3200, 3201, 3202, 3203, 3204, 3205, 3206, 3207, 3208, 3209, 3210, 3211, 3212, 3213, 3214, 3215,
    3216, 3217, 3218, 3219, 3220, 3221, 3222, 3223, 3224, 3225, 3226, 3227, 3228, 3229, 3230, 3231,
    3232, 3233, 3234, 3235, 3236, 3237, 3238, 3239, 3240, 3241, 3242, 3243, 3244, 3245, 3246, 3247,
    3248, 3249, 3250, 3251, 3252, 3253, 3254, 3255, 3256, 3257, 3258, 3259, 3260, 3261, 3262, 3263,
    3264, 3265, 3266, 3267, 3268, 3269, 3270, 3271, 3272, 3273, 3274, 3275, 3276, 3277, 3278, 3279,
    3280, 3281, 3282, 3283, 3284, 3285, 3286, 3287, 3288, 3289, 3290, 3291, 3292, 3293, 3294, 3295,
    3296, 3297, 3298, 3299, 3300, 3301, 3302, 3303, 3304, 3305, 3306, 3307, 3308, 3309, 3310, 3500,
    3501, 3502, 3503, 3504, 3505, 3600, 3601, 3602, 4000, 4001, 4002, 4003, 4004, 4005, 4006, 4007,
    4008, 4009, 4010, 4011, 4012, 4013, 4014, 4015, 4016, 4017, 4018, 4019, 4020, 4021, 4022, 4023,
    4024, 4025, 4026, 4027, 5000, 5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008, 5009, 5010, 5011,
    5012, 5013, 5014, 5015, 5016, 5017, 5018, 5019, 5020, 5021, 5022, 5023, 5024, 5025, 5026, 5027,
    5028, 5029, 5030, 5031, 5032, 5033, 5034, 5035, 5036, 5037, 5038, 5039, 5040, 5041, 5042, 5043,
    5044, 5045, 5046, 5047, 5048, 5049, 5050, 5051, 5052, 5053, 5054, 5055, 5056, 5057, 5058, 5059,
    5060, 5061, 5062, 5063, 5064, 5065, 5066, 5067, 5068, 5069, 5070, 5071, 5072, 5073, 5074, 5075,
    5076, 5077, 5078, 5079, 5080, 5081, 5082, 5083, 5084, 5085, 5086, 5087, 5088, 5089, 5090, 5091,
    5092, 5093, 5094, 5095, 5096, 5097, 5098, 5099, 5100, 5101, 5102, 5103, 5104, 5105, 5106, 5107,
    5108, 5109, 5110, 5111, 5112, 5113, 5114, 5115, 5116, 5117, 5118, 5119, 5120, 5121, 5122, 5123,
    5124, 5125, 5126, 5127, 5128, 5129, 5130, 5131, 5132, 5133, 5134, 5135, 5136, 5137, 5138, 5139,
    5140, 5141, 5142, 5143, 5144, 5145, 5146, 5147, 5148, 5149, 5150, 5151, 5152, 5153, 5154, 5155,
    5156, 5157, 5158, 5159, 5160, 5161, 5162, 5163, 5164, 5165, 5166, 5167, 5168, 5169, 5170, 5171,
    5172, 5173, 5174, 5175, 5176, 5177, 5178, 5179, 5180, 5181, 5182, 5183, 5184, 5185, 5186, 5187,
    5188, 5189, 5190, 5191, 5192, 5193, 5194, 5195, 5196, 5197, 5198, 5199, 5200, 5201, 5202, 5203,
    5204, 5205, 5206, 5207, 5208, 5209, 5210, 5211, 5212, 5213, 5214, 5215, 5216, 5217, 5218, 5219,
    5220, 5221, 5222, 5223, 5224, 5225, 5226, 5227, 5228, 5229, 5230, 5231, 5232, 5233, 5234, 5235,
    5236, 5237, 5238, 5239, 5240, 5241, 5242, 5243, 5244, 5245, 5246, 5247, 5248, 5249, 5250, 5251,
    5252, 5253, 5254, 5255, 5256, 5257, 5258, 5259, 5260, 5261, 5262, 5263, 5264, 5265, 5266, 5267,
    5268, 5269, 5270, 5271, 5272, 5273, 5274, 5275, 5276, 5277, 5278, 5279, 5280, 5281, 5282, 5283,
    5284, 5285, 5286, 5287, 5288, 5289, 5290, 5291, 5292, 5293, 5294, 5295, 5296, 5297, 5298, 5299,
    5300, 5301, 5302, 5303, 5304, 5305, 5306, 5307, 5308, 5309, 5310, 5311, 5312, 5313, 5314, 5315,
    5316, 5317, 5318, 5319, 5320, 5321, 5322, 5323, 5324, 5325, 5326, 5327, 5328, 5329, 5330, 5331,
    5332, 5333, 5334, 5335, 5336, 5337, 5338, 5339, 5340, 5341, 5342, 5343, 5344, 5345, 5346, 5347,
    5348, 5349, 5350, 5351, 5352, 5353, 5354, 5355, 5356, 5357, 5358, 5359, 5360, 5361, 5362, 5363,
    5364, 5365, 5366, 5367, 5368, 5369, 5370, 5371, 5372, 5373, 5374, 5375, 5376, 5377, 5378, 5379,
    5380, 5381, 5382, 5383, 5384, 5385, 5386, 5387, 5388, 5389, 5390, 5391, 5392, 5393, 5394, 5395,
    5396, 5397, 5398, 5399, 5400, 5401, 5402, 5403, 5404, 5405, 5406, 5407, 5408, 5409, 5410, 5411,
    5412, 5413, 5414, 5415, 5416, 5417, 5418, 5419, 5420, 5421, 5422, 5423, 5424, 5425, 5426, 5427,
    5428, 5429, 5430, 5431, 5432, 5433, 5434, 5436, 5437, 5438, 5439, 5440, 5441, 5442, 5443, 5444,
    5445, 5446, 5447, 5448, 5449, 5450, 5451, 5452, 5453, 5454, 5455, 5456, 5457, 5458, 5459, 5460,
    5461, 5462, 5463, 5464, 5465, 5466, 5467, 5468, 5469, 5470, 5471, 5472, 5473, 5474, 5475, 5476,
    5477, 5478, 5479, 5480, 5481, 6000, 6099, 6100, 6194, 6195, 6196, 6197, 6198, 6199, 6200, 6201,
    6202, 6203, 6204, 6205, 6206, 10000, 10001, 10002, 10004, 10005, 10007, 10018, 10019, 10020, 10021);

Var
  Ok, Fail, R, R2, I, N, A, B, P, H, Hmod, Hab, Hmq, Obj, Ef, Grp, Prg, Hh, Ini, NEnum : LongInt;
  Name, Name2, Buf : Array[0..1023] Of Byte;
  Det : Array[0..17] Of LongInt;
  Rc1, Rc2, Rc3 : Array[0..3] Of LongInt;
  Clr : Array[0..3] Of LongInt;
  Seen : Boolean;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function RdL(A : LongInt) : LongInt;
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Function RdB(A : LongInt) : LongInt;
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrB(A, V : LongInt);
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := ''; K := 0;
  While (K < 255) And (RdB(A + K) <> 0) Do
  Begin
    S := S + Chr(RdB(A + K));
    Inc(K);
  End;
  GetZ := S;
End;

{ chaine terminee par un nul dans Name (Z) ou Name2 (Z2) }
Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name[K - 1] := Ord(S[K]);
  Name[Length(S)] := 0;
  Z := LongInt(@Name);
End;

Function Z2(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name2[K - 1] := Ord(S[K]);
  Name2[Length(S)] := 0;
  Z2 := LongInt(@Name2);
End;

{ chaine dans Buf a partir de l'octet Ofs }
Function Zb(Ofs : LongInt; S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Buf[Ofs + K - 1] := Ord(S[K]);
  Buf[Ofs + Length(S)] := 0;
  Zb := LongInt(@Buf) + Ofs;
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

{ procedure d'enumeration des proprietes (programme OS2PC : Pascal) }
Function EnumProc(Hw, PName, V, Prm : LongInt) : LongInt;
Begin
  Inc(NEnum);
  EnumProc := 1;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTMRG : essai de PMMERGE.DLL');

  { --- ordinaux --- }
  Hmod := 0;
  R := DosQueryModuleHandle(Z('PMMERGE'), LongInt(@Hmod));
  N := 0;
  For I := 0 To NOrd - 1 Do
  Begin
    P := 0;
    If DosQueryProcAddr(Hmod, Ords[I], 0, LongInt(@P)) = 0 Then
      If P <> 0 Then Inc(N);
  End;
  Check('1039 ordinaux de PMMERGE (' + IStr(N) + ')', N = 1039);
  P := 0; A := 0; B := 0;
  R := DosQueryProcAddr(Hmod, 0, Z('Win32CalcFrameRect'), LongInt(@P));
  R := DosQueryProcAddr(Hmod, 0, Z('WIN32CALCFRAMERECT'), LongInt(@A));
  R := DosQueryProcAddr(Hmod, 0, Z('DaxOpenClipbrd'), LongInt(@B));
  Check('noms Win32CalcFrameRect (5117 et 5118), DaxOpenClipbrd', (P <> 0) And (A <> 0) And (B <> 0));

  { --- profil : fichier D:\ESSAI.INI --- }
  R := DosDelete(Z('D:\ESSAI.INI'));
  Ini := PrfOpenProfile(0, Z('D:\ESSAI.INI'));
  Check('PrfOpenProfile (HINI 494E00xxh)', (Ini Shr 16) = $494E);
  R := PrfWriteProfileString(Ini, Z('Couleurs'), Z2('Fond'), Zb(0, 'Bleu'));
  R2 := PrfWriteProfileString(Ini, Z('Couleurs'), Z2('Largeur'), Zb(0, '-42'));
  Check('PrfWriteProfileString (deux cles)', (R = 1) And (R2 = 1));
  For I := 0 To 4 Do Buf[I] := I * 3 + 1;
  R := PrfWriteProfileData(Ini, Z('Donnees'), Z2('Bloc'), LongInt(@Buf), 5);
  Check('PrfWriteProfileData (5 octets)', R = 1);
  R := PrfQueryProfileString(Ini, Z('Couleurs'), Z2('Fond'), 0, LongInt(@Buf), 100);
  Check('PrfQueryProfileString (' + GetZ(LongInt(@Buf)) + ', ' + IStr(R) + ')', (R = 5) And (GetZ(LongInt(@Buf)) = 'Bleu'));
  R := PrfQueryProfileString(Ini, Z('Couleurs'), Z2('Absente'), Zb(200, 'Rouge'), LongInt(@Buf), 100);
  Check('PrfQueryProfileString : valeur par defaut', GetZ(LongInt(@Buf)) = 'Rouge');
  R := PrfQueryProfileInt(Ini, Z('Couleurs'), Z2('Largeur'), 7);
  R2 := Prf32QueryProfileInt(Ini, Z('Couleurs'), Z2('Absente'), 7);
  Check('PrfQueryProfileInt (-42), Prf32QueryProfileInt (defaut 7)', (R = -42) And (R2 = 7));
  N := 0;
  R := PrfQueryProfileSize(Ini, Z('Donnees'), Z2('Bloc'), LongInt(@N));
  Check('PrfQueryProfileSize (' + IStr(N) + ')', (R = 1) And (N = 5));
  For I := 0 To 9 Do Buf[I] := 0;
  N := 10;
  R := PrfQueryProfileData(Ini, Z('Donnees'), Z2('Bloc'), LongInt(@Buf), LongInt(@N));
  Check('PrfQueryProfileData', (R = 1) And (N = 5) And (Buf[0] = 1) And (Buf[4] = 13));
  R := PrfQueryProfileString(Ini, 0, 0, 0, LongInt(@Buf), 100);
  Check('liste des applications (Couleurs, Donnees : ' + IStr(R) + ' octets)', (R = 18) And
        (GetZ(LongInt(@Buf)) = 'Couleurs') And (GetZ(LongInt(@Buf) + 9) = 'Donnees') And (Buf[17] = 0));
  R := PrfQueryProfileString(Ini, Z('Couleurs'), 0, 0, LongInt(@Buf), 100);
  Check('liste des cles (Fond, Largeur)', (GetZ(LongInt(@Buf)) = 'Fond') And (GetZ(LongInt(@Buf) + 5) = 'Largeur'));
  R := PrfWriteProfileString(Ini, Z('Couleurs'), Z2('Fond'), 0);
  R2 := PrfQueryProfileString(Ini, Z('Couleurs'), Z2('Fond'), 0, LongInt(@Buf), 100);
  Check('suppression d''une cle (pszData nul)', (R = 1) And (R2 = 0));
  R := PrfCloseProfile(Ini);
  Ini := PrfOpenProfile(0, Z('D:\ESSAI.INI'));
  R2 := PrfQueryProfileInt(Ini, Z('Couleurs'), Z2('Largeur'), 7);
  N := 10;
  R := PrfQueryProfileData(Ini, Z('Donnees'), Z2('Bloc'), LongInt(@Buf), LongInt(@N));
  Check('PrfCloseProfile, relecture du fichier', (R2 = -42) And (R = 1) And (Buf[2] = 7));
  R := PrfWriteProfileData(Ini, Z('Donnees'), 0, 0, 0);
  R2 := PrfQueryProfileString(Ini, 0, 0, 0, LongInt(@Buf), 100);
  Check('suppression d''une application (pszKey nul)', (R = 1) And (R2 = 10) And (GetZ(LongInt(@Buf)) = 'Couleurs'));
  R := PrfCloseProfile(Ini);
  { format binaire d'OS/2 : en-tete FFFFFFFFh, premiere application,
    taille }
  H := 0; A := 0; N := 0;
  R := DosOpen(Z('D:\ESSAI.INI'), LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0);
  R2 := DosRead(H, LongInt(@Buf), 1024, LongInt(@N));
  R := DosClose(H);
  A := RdL(LongInt(@Buf) + 4);
  Check('format INI d''OS/2 (' + IStr(N) + ' octets)', (RdL(LongInt(@Buf)) = -1) And (A = 20) And
        (RdL(LongInt(@Buf) + 8) = N) And (GetZ(LongInt(@Buf) + RdL(LongInt(@Buf) + A + 16)) = 'Couleurs') And
        (GetZ(LongInt(@Buf) + RdL(LongInt(@Buf) + RdL(LongInt(@Buf) + A + 4) + 12)) = 'Largeur'));
  R := WinWriteProfileString(0, Z('TESTMRG'), Z2('Essai'), Zb(0, 'oui'));
  R2 := WinQueryProfileString(0, Z('TESTMRG'), Z2('Essai'), 0, LongInt(@Buf), 100);
  Check('WinWriteProfileString, WinQueryProfileString (profil de l''utilisateur)', (R = 1) And
        (GetZ(LongInt(@Buf)) = 'oui'));
  R := WinWriteProfileString(0, Z('TESTMRG'), 0, 0);
  For I := 0 To 3 Do Det[I] := 0;
  Det[0] := 100; Det[1] := LongInt(@Buf); Det[2] := 100; Det[3] := LongInt(@Buf) + 100;
  R := PrfQueryProfile(0, LongInt(@Det));
  Check('PrfQueryProfile (' + GetZ(LongInt(@Buf)) + ', ' + GetZ(LongInt(@Buf) + 100) + ')', (R = 1) And
        (Pos('OS2.INI', GetZ(LongInt(@Buf))) > 0) And (Pos('OS2SYS.INI', GetZ(LongInt(@Buf) + 100)) > 0));

  { --- liste des programmes et groupes --- }
  Ini := PrfOpenProfile(0, Z('D:\PROG.INI'));
  Grp := PrfCreateGroup(Ini, Z('Utilitaires'), 0);
  For I := 0 To 17 Do Det[I] := 0;
  Det[0] := 72; Det[1] := 2; Det[3] := Zb(0, 'Editeur'); Det[4] := Zb(20, 'C:\EDLIN.EXE'); Det[5] := Zb(40, '/Q');
  Prg := PrfAddProgram(Ini, LongInt(@Det), Grp);
  Check('PrfCreateGroup, PrfAddProgram', (Grp <> 0) And (Prg <> 0) And (Prg <> Grp));
  N := 0;
  R := PrfQueryProgramTitles(Ini, Grp, LongInt(@Buf), 1024, LongInt(@N));
  Check('PrfQueryProgramTitles (' + IStr(N) + ' : ' + GetZ(RdL(LongInt(@Buf) + 12)) + ')', (N = 1) And
        (RdL(LongInt(@Buf)) = Prg) And (GetZ(RdL(LongInt(@Buf) + 12)) = 'Editeur'));
  R := PrfQueryProgramTitles(Ini, SGH_ROOT, LongInt(@Buf), 1024, LongInt(@N));
  Check('PrfQueryProgramTitles (SGH_ROOT : groupes)', (N = 1) And (GetZ(RdL(LongInt(@Buf) + 12)) = 'Utilitaires'));
  R := PrfQueryDefinition(Ini, Prg, LongInt(@Buf), 1024);
  Check('PrfQueryDefinition (' + IStr(R) + ' octets)', (R > 72) And (GetZ(RdL(LongInt(@Buf) + 16)) = 'C:\EDLIN.EXE') And
        (GetZ(RdL(LongInt(@Buf) + 20)) = '/Q') And (RdL(LongInt(@Buf) + 4) = 2));
  N := 0;
  R := PrfQueryProgramHandle(Ini, Z('c:\edlin.exe'), LongInt(@Rc1), 16, LongInt(@N));
  Check('PrfQueryProgramHandle, PrfQueryProgramCategory', (R = 1) And (N = 1) And (Rc1[0] = Prg) And
        (PrfQueryProgramCategory(Ini, Z('C:\EDLIN.EXE')) = 2));
  Det[3] := Zb(0, 'Edlin');
  R := PrfChangeProgram(Ini, Prg, LongInt(@Det));
  R2 := PrfQueryDefinition(Ini, Prg, LongInt(@Buf), 1024);
  Check('PrfChangeProgram', (R = 1) And (GetZ(RdL(LongInt(@Buf) + 12)) = 'Edlin'));
  R := PrfRemoveProgram(Ini, Prg);
  R2 := PrfQueryProgramTitles(Ini, Grp, 0, 0, LongInt(@N));
  Check('PrfRemoveProgram', (R = 1) And (N = 0));
  R := PrfDestroyGroup(Ini, Grp);
  R2 := PrfQueryProgramTitles(Ini, SGH_ROOT, 0, 0, LongInt(@N));
  Check('PrfDestroyGroup', (R = 1) And (N = 0));
  R := PrfCloseProfile(Ini);

  { --- relais vers PMWIN.DLL --- }
  Hab := WinInitialize(0);
  R := WinQueryVersion(Hab);
  Check('WinInitialize, WinQueryVersion (PMWIN)', (Hab <> 0) And (R <> 0));
  R := WinSetRect(Hab, LongInt(@Rc1), 0, 0, 10, 10);
  R := WinSetRect(Hab, LongInt(@Rc2), 5, 5, 20, 20);
  R := Win32UnionRect(Hab, LongInt(@Rc3), LongInt(@Rc1), LongInt(@Rc2));
  R2 := WinIntersectRect(Hab, LongInt(@Rc1), LongInt(@Rc1), LongInt(@Rc2));
  Check('WinSetRect, Win32UnionRect, WinIntersectRect', (Rc3[2] = 20) And (Rc1[0] = 5) And (Rc1[2] = 10));
  H := WinCreateAtomTable(0, 0);
  A := Win32AddAtom(H, Z('Atome'));
  R := Win32IncrementAtomUsage(H, A);
  Check('WinCreateAtomTable, Win32AddAtom, Win32IncrementAtomUsage, LookupAtom', (A <> 0) And (R = A) And
        (WinQueryAtomUsage(H, A) = 2) And (LookupAtom(H, Z('Atome')) = A));
  R := WinDestroyAtomTable(H);
  Hmq := Win32CreateMsgQueue(Hab, 0);
  Obj := Win32CreateWindow(2, $FFFF0005, Z('Objet'), 0, 0, 0, 100, 100, 0, 3, 7, 0, 0);
  Check('Win32CreateMsgQueue, Win32CreateWindow (HWND_OBJECT)', (Hmq <> 0) And (Obj <> 0));

  { --- proprietes --- }
  R := WinSetProperty(Obj, Z('Taille'), 1234, 0);
  R2 := WinSetProperty(Obj, Z('Couleur'), 5, 0);
  NEnum := 0;
  A := WinEnumProperties(Obj, LongInt(@EnumProc), 0);
  Check('WinSetProperty, WinQueryProperty, WinEnumProperties (' + IStr(NEnum) + ')', (R = 1) And
        (WinQueryProperty(Obj, Z('Taille')) = 1234) And (NEnum = 2));
  R := WinRemoveProperty(Obj, Z('Taille'));
  Check('WinRemoveProperty', (R = 1234) And (WinQueryProperty(Obj, Z('Taille')) = 0));
  R := WinSetClassProperty(Hab, Z('EssaiClasse'), Z2('Info'), 77);
  Check('WinSetClassProperty, WinQueryClassProperty', (R = 1) And (WinQueryClassProperty(Hab, Z('ESSAICLASSE'), Z2('Info')) = 77));

  { --- champ de saisie (Edit*) --- }
  Ef := EditCreate(Obj, 0, 0, 160, 16, 8);
  R := EditSetText(Ef, Z('Bonjour monde'));
  R := EditSetSelection(Ef, 8, 13);
  R := EditReplace(Ef, Z('PM'));
  R2 := Win32QueryWindowText(Ef, 100, LongInt(@Buf));
  Check('EditCreate, EditSetText, EditSetSelection, EditReplace (' + GetZ(LongInt(@Buf)) + ')', (Ef <> 0) And
        (GetZ(LongInt(@Buf)) = 'Bonjour PM'));
  Check('Win32IsWindowOfClass (WC_ENTRYFIELD), EditCXFromICH', (Win32IsWindowOfClass(Ef, $FFFF0006) = 1) And
        (Win32IsWindowOfClass(Ef, $FFFF0003) = 0) And (EditCXFromICH(Ef, 3) = 24));
  Clr[0] := 1; Clr[1] := $FF0000; Clr[2] := 2; Clr[3] := 0;
  R := WinSetControlColors(Ef, 0, 0, 1, LongInt(@Clr));
  Clr[1] := 0;
  R2 := WinQueryControlColors(Ef, 0, 0, 1, LongInt(@Clr));
  Check('WinSetControlColors, WinQueryControlColors (premier plan)', (R = 1) And (Clr[1] = $FF0000));

  { --- bureau, curseur, souris --- }
  R := WinQueryDesktopWorkArea(1, LongInt(@Rc1));
  Rc2[0] := 0; Rc2[1] := 20; Rc2[2] := 640; Rc2[3] := 480;
  R2 := WinSetDesktopWorkArea(1, LongInt(@Rc2));
  R2 := WinQueryDesktopWorkArea(1, LongInt(@Rc3));
  Check('WinQueryDesktopWorkArea (' + IStr(Rc1[2]) + ' x ' + IStr(Rc1[3]) + '), WinSetDesktopWorkArea',
        (R = 1) And (Rc1[2] = Win32QuerySysValue(1, 20)) And (Rc3[1] = 20));
  R := DaxSwapMouseButton(1);
  R2 := DaxSwapMouseButton(R);
  Check('DaxGetCaretBlinkTime, DaxSwapMouseButton', (DaxGetCaretBlinkTime > 0) And (R2 = 1));
  R := WinDestroyWindow(Obj);
  R := WinDestroyMsgQueue(Hmq);
  R := Win32Terminate(Hab);

  { --- memoire, tas, semaphores --- }
  Hh := WinXXCreateHeap(0, 8192, 0, 0, 0, 0);
  A := WinXXAllocMem(Hh, 100);
  B := WinXXReallocMem(Hh, A, 100, 3000);
  Check('WinXXCreateHeap, WinXXAllocMem, WinXXReallocMem, WinXXIsMemInHeap, WinXXQueryMemSize', (Hh <> 0) And
        (A <> 0) And (B <> 0) And (WinXXIsMemInHeap(Hh, B) = 1) And (WinXXIsMemInHeap(Hh, LongInt(@Buf)) = 0) And
        (WinXXQueryMemSize(Hh, B) >= 3000));
  Check('WinXXFreeMem, WinXXDestroyHeap', (WinXXFreeMem(Hh, B, 3000) = 0) And (WinXXDestroyHeap(Hh) = 0));
  P := 0;
  R := SSAllocMem(LongInt(@P), 4096, 0);
  If P <> 0 Then WrB(P + 4095, 9);
  Check('SSAllocMem, SSFreeMem', (R = 0) And (P <> 0) And (RdB(P + 4095) = 9) And (SSFreeMem(P) = 0));
  A := 0;
  R := RamSemRequest32(LongInt(@A), 0);
  R2 := RamSemRequest32(LongInt(@A), 0);
  Check('RamSemRequest32 (deux fois), RamSemClear16', (R = 0) And (R2 = 0) And (A <> 0) And
        (RamSemClear16(LongInt(@A)) = 0) And (A = 0));

  { --- divers --- }
  Check('WinQueryCpType (932 : DBCS, 850)', (WinQueryCpType(932) = 1) And (WinQueryCpType(850) = 0));
  Check('GreEntry3 (fonction inconnue : 0), TidCurrent, ValidateDCHandle', (GreEntry3(0, 0, $1234) = 0) And
        (TidCurrent = 1) And (ValidateDCHandle($44470001) = 1) And (ValidateDCHandle(5) = 0));
  R := SetDriverInfo($44470001, 3, 99, 0);
  Check('SetDriverInfo, GetDriverInfo32', (R = 1) And (GetDriverInfo32($44470001, 3, 0) = 99));
  P := ShellWindow;
  Check('ShellWindow (adresse de la donnee)', (P <> 0) And (RdL(P) = $00010001));
  R := WinUpper(0, 850, 7, Z('pmmerge'));
  Check('WinUpper (PMWIN) : ' + GetZ(LongInt(@Name)), GetZ(LongInt(@Name)) = 'PMMERGE');

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTMRG : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
