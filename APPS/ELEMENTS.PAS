{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/qchimie)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Table des elements : tableau periodique des elements
                chimiques, pour le Presentation Manager d'OS/2-0 (dossier
                Science).
}

Program Elements;

{ Compilation : OS2PC ELEMENTS.PAS   (produit ELEMENTS.EXE)

  Portage vers OS/2-0 d'ELEMENTS.PAS du depot QCHIMIE (Turbo Pascal, Free
  Pascal, mode texte de Crt). Les donnees des 118 elements (groupe,
  periode, nom, numero et masse atomiques, symbole, categorie, etat) sont
  celles de la version DOS. L'affichage en mode texte devient un tableau
  periodique graphique dans une fenetre de Presentation Manager : cases
  colorees par categorie (symbole colore selon l'etat), fiche de l'element
  choisi, legende, liste des elements (vue /GUI de la version DOS),
  recherche par nom, symbole ou numero, barre de menus d'OS/2 ; choix au
  clavier (fleches) ou a la souris. ELEMENTS nom choisit l'element. }

Type
 Element=Record
  Groupe,Periode:Byte;
  ElementName:String[20];
  NumeroAtomique:Byte;
  SymboleChimique:String[2];
  MasseAtomique:Real;
  Categorie:(NonClasses,Alcalins,Alcalinoterreux,Lanthanides,
  Actinides,MetauxDeTransition,MetauxPauvres,Metalloides,
  AutresNonMetaux,Halogenes,GazNobles);
  Etat:(Gaz,Liquide,Solide);
 End;

Const
 ElementsChimiques:Array[0..117]of Element=(
  (Groupe:1;
   Periode:1;
   ElementName:'Hydrogäne';
   NumeroAtomique:1;
   SymboleChimique:'H';
   MasseAtomique:1.007975;
   Categorie:AutresNonMetaux;
   Etat:Gaz),
  (Groupe:18;
   Periode:1;
   ElementName:'HÇlium';
   NumeroAtomique:2;
   SymboleChimique:'He';
   MasseAtomique:4.002602;
   Categorie:GazNobles;
   Etat:Gaz),
  (Groupe:1;
   Periode:2;
   ElementName:'Lithium';
   NumeroAtomique:3;
   SymboleChimique:'Li';
   MasseAtomique:6.9395;
   Categorie:Alcalins;
   Etat:Solide),
  (Groupe:2;
   Periode:2;
   ElementName:'BÇryllium';
   NumeroAtomique:4;
   SymboleChimique:'Be';
   MasseAtomique:9.0121831;
   Categorie:Alcalinoterreux;
   Etat:Solide),
  (Groupe:13;
   Periode:2;
   ElementName:'Bore';
   NumeroAtomique:5;
   SymboleChimique:'B';
   MasseAtomique:10.8135;
   Categorie:Metalloides;
   Etat:Solide),
  (Groupe:14;
   Periode:2;
   ElementName:'Carbone';
   NumeroAtomique:6;
   SymboleChimique:'C';
   MasseAtomique:12.0106;
   Categorie:AutresNonMetaux;
   Etat:Solide),
  (Groupe:15;
   Periode:2;
   ElementName:'Azote';
   NumeroAtomique:7;
   SymboleChimique:'N';
   MasseAtomique:14.006855;
   Categorie:AutresNonMetaux;
   Etat:Gaz),
  (Groupe:16;
   Periode:2;
   ElementName:'Oxygäne';
   NumeroAtomique:8;
   SymboleChimique:'O';
   MasseAtomique:15.99940;
   Categorie:AutresNonMetaux;
   Etat:Gaz),
  (Groupe:17;
   Periode:2;
   ElementName:'Fluor';
   NumeroAtomique:9;
   SymboleChimique:'F';
   MasseAtomique:18.99840316;
   Categorie:Halogenes;
   Etat:Gaz),
  (Groupe:18;
   Periode:2;
   ElementName:'NÇon';
   NumeroAtomique:10;
   SymboleChimique:'Ne';
   MasseAtomique:20.1797;
   Categorie:GazNobles;
   Etat:Gaz),
  (Groupe:1;
   Periode:3;
   ElementName:'Sodium';
   NumeroAtomique:11;
   SymboleChimique:'Na';
   MasseAtomique:22.98976928;
   Categorie:Alcalins;
   Etat:Solide),
  (Groupe:2;
   Periode:3;
   ElementName:'MagnÇsium';
   NumeroAtomique:12;
   SymboleChimique:'Mg';
   MasseAtomique:24.3055;
   Categorie:Alcalinoterreux;
   Etat:Solide),
  (Groupe:13;
   Periode:3;
   ElementName:'Aluminium';
   NumeroAtomique:13;
   SymboleChimique:'Al';
   MasseAtomique:24.3055;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:14;
   Periode:3;
   ElementName:'Silicium';
   NumeroAtomique:14;
   SymboleChimique:'Si';
   MasseAtomique:28.085;
   Categorie:Metalloides;
   Etat:Solide),
  (Groupe:15;
   Periode:3;
   ElementName:'Phosphore';
   NumeroAtomique:15;
   SymboleChimique:'P';
   MasseAtomique:30.9737620;
   Categorie:AutresNonMetaux;
   Etat:Solide),
  (Groupe:16;
   Periode:3;
   ElementName:'Soufre';
   NumeroAtomique:16;
   SymboleChimique:'S';
   MasseAtomique:32.0675;
   Categorie:AutresNonMetaux;
   Etat:Solide),
  (Groupe:17;
   Periode:3;
   ElementName:'Chlore';
   NumeroAtomique:17;
   SymboleChimique:'Cl';
   MasseAtomique:35.4515;
   Categorie:Halogenes;
   Etat:Gaz),
  (Groupe:18;
   Periode:3;
   ElementName:'Argon';
   NumeroAtomique:18;
   SymboleChimique:'Ar';
   MasseAtomique:39.948;
   Categorie:GazNobles;
   Etat:Gaz),
  (Groupe:1;
   Periode:4;
   ElementName:'Potassium';
   NumeroAtomique:19;
   SymboleChimique:'K';
   MasseAtomique:39.0983;
   Categorie:Alcalins;
   Etat:Solide),
  (Groupe:2;
   Periode:4;
   ElementName:'Calcium';
   NumeroAtomique:20;
   SymboleChimique:'Ca';
   MasseAtomique:40.078;
   Categorie:Alcalinoterreux;
   Etat:Solide),
  (Groupe:3;
   Periode:4;
   ElementName:'Scandium';
   NumeroAtomique:21;
   SymboleChimique:'Sc';
   MasseAtomique:44.955908;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:4;
   Periode:4;
   ElementName:'Titane';
   NumeroAtomique:22;
   SymboleChimique:'Ti';
   MasseAtomique:47.867;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:5;
   Periode:4;
   ElementName:'Vanadium';
   NumeroAtomique:23;
   SymboleChimique:'V';
   MasseAtomique:50.9415;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:6;
   Periode:4;
   ElementName:'Chrome';
   NumeroAtomique:24;
   SymboleChimique:'Cr';
   MasseAtomique:51.9961;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:7;
   Periode:4;
   ElementName:'Manganäse';
   NumeroAtomique:25;
   SymboleChimique:'Mn';
   MasseAtomique:54.938044;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:8;
   Periode:4;
   ElementName:'Fer';
   NumeroAtomique:26;
   SymboleChimique:'Fe';
   MasseAtomique:55.845;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:9;
   Periode:4;
   ElementName:'Cobalt';
   NumeroAtomique:27;
   SymboleChimique:'Co';
   MasseAtomique:58.933194;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:10;
   Periode:4;
   ElementName:'Nickel';
   NumeroAtomique:28;
   SymboleChimique:'Ni';
   MasseAtomique:58.6934;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:11;
   Periode:4;
   ElementName:'Cuivre';
   NumeroAtomique:29;
   SymboleChimique:'Cu';
   MasseAtomique:63.546;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:12;
   Periode:4;
   ElementName:'Zinc';
   NumeroAtomique:30;
   SymboleChimique:'Zn';
   MasseAtomique:63.38;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:13;
   Periode:4;
   ElementName:'Gallium';
   NumeroAtomique:31;
   SymboleChimique:'Ga';
   MasseAtomique:69.723;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:14;
   Periode:4;
   ElementName:'Germanium';
   NumeroAtomique:32;
   SymboleChimique:'Ge';
   MasseAtomique:72.630;
   Categorie:Metalloides;
   Etat:Solide),
  (Groupe:15;
   Periode:4;
   ElementName:'Arsenic';
   NumeroAtomique:33;
   SymboleChimique:'As';
   MasseAtomique:74.921595;
   Categorie:Metalloides;
   Etat:Solide),
  (Groupe:16;
   Periode:4;
   ElementName:'SÇlÇmium';
   NumeroAtomique:34;
   SymboleChimique:'Se';
   MasseAtomique:78.971;
   Categorie:AutresNonMetaux;
   Etat:Solide),
  (Groupe:17;
   Periode:4;
   ElementName:'Brome';
   NumeroAtomique:35;
   SymboleChimique:'Br';
   MasseAtomique:79.904;
   Categorie:Halogenes;
   Etat:Liquide),
  (Groupe:18;
   Periode:4;
   ElementName:'Krypton';
   NumeroAtomique:36;
   SymboleChimique:'Kr';
   MasseAtomique:83.798;
   Categorie:GazNobles;
   Etat:Gaz),
  (Groupe:1;
   Periode:5;
   ElementName:'Rubidium';
   NumeroAtomique:37;
   SymboleChimique:'Rb';
   MasseAtomique:85.4678;
   Categorie:Alcalins;
   Etat:Solide),
  (Groupe:2;
   Periode:5;
   ElementName:'Strontium';
   NumeroAtomique:38;
   SymboleChimique:'Sr';
   MasseAtomique:87.62;
   Categorie:Alcalinoterreux;
   Etat:Solide),
  (Groupe:3;
   Periode:5;
   ElementName:'Yttrium';
   NumeroAtomique:39;
   SymboleChimique:'Y';
   MasseAtomique:88.90584;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:4;
   Periode:5;
   ElementName:'Zirconium';
   NumeroAtomique:40;
   SymboleChimique:'Zr';
   MasseAtomique:91.224;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:5;
   Periode:5;
   ElementName:'Niobium';
   NumeroAtomique:41;
   SymboleChimique:'Nb';
   MasseAtomique:92.90637;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:6;
   Periode:5;
   ElementName:'Molybdäne';
   NumeroAtomique:42;
   SymboleChimique:'Mo';
   MasseAtomique:95.95;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:7;
   Periode:5;
   ElementName:'TechnÇtium';
   NumeroAtomique:43;
   SymboleChimique:'Tc';
   MasseAtomique:98.0;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:8;
   Periode:5;
   ElementName:'RuthÇnium';
   NumeroAtomique:44;
   SymboleChimique:'Ru';
   MasseAtomique:101.07;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:9;
   Periode:5;
   ElementName:'Rhodium';
   NumeroAtomique:45;
   SymboleChimique:'Rh';
   MasseAtomique:102.90550;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:10;
   Periode:5;
   ElementName:'Palladium';
   NumeroAtomique:46;
   SymboleChimique:'Pd';
   MasseAtomique:106.42;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:11;
   Periode:5;
   ElementName:'Argent';
   NumeroAtomique:47;
   SymboleChimique:'Ag';
   MasseAtomique:107.8682;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:12;
   Periode:5;
   ElementName:'Cadmium';
   NumeroAtomique:48;
   SymboleChimique:'Cd';
   MasseAtomique:112.414;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:13;
   Periode:5;
   ElementName:'Indium';
   NumeroAtomique:49;
   SymboleChimique:'In';
   MasseAtomique:114.818;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:14;
   Periode:5;
   ElementName:'êtain';
   NumeroAtomique:50;
   SymboleChimique:'Sn';
   MasseAtomique:118.710;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:15;
   Periode:5;
   ElementName:'Antimoine';
   NumeroAtomique:51;
   SymboleChimique:'Sb';
   MasseAtomique:121.760;
   Categorie:Metalloides;
   Etat:Solide),
  (Groupe:16;
   Periode:5;
   ElementName:'Tellure';
   NumeroAtomique:52;
   SymboleChimique:'Te';
   MasseAtomique:127.60;
   Categorie:Metalloides;
   Etat:Solide),
  (Groupe:17;
   Periode:5;
   ElementName:'Iode';
   NumeroAtomique:53;
   SymboleChimique:'I';
   MasseAtomique:126.90447;
   Categorie:Halogenes;
   Etat:Solide),
  (Groupe:18;
   Periode:5;
   ElementName:'XÇnon';
   NumeroAtomique:54;
   SymboleChimique:'Xe';
   MasseAtomique:131.293;
   Categorie:GazNobles;
   Etat:Gaz),
  (Groupe:1;
   Periode:6;
   ElementName:'CÇsium';
   NumeroAtomique:55;
   SymboleChimique:'Cs';
   MasseAtomique:132.905452;
   Categorie:Alcalins;
   Etat:Solide),
  (Groupe:2;
   Periode:6;
   ElementName:'Baryum';
   NumeroAtomique:56;
   SymboleChimique:'Ba';
   MasseAtomique:137.327;
   Categorie:Alcalinoterreux;
   Etat:Solide),

    { Lanthanides }
  (Groupe:3;
   Periode:6;
   ElementName:'Lanthane';
   NumeroAtomique:57;
   SymboleChimique:'La';
   MasseAtomique:138.90547;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'CÇrium';
   NumeroAtomique:58;
   SymboleChimique:'Ce';
   MasseAtomique:140.116;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'PrasÇodyme';
   NumeroAtomique:59;
   SymboleChimique:'Pr';
   MasseAtomique:140.90766;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'NÇodyme';
   NumeroAtomique:60;
   SymboleChimique:'Nd';
   MasseAtomique:144.242;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'PromÇthium';
   NumeroAtomique:61;
   SymboleChimique:'Pm';
   MasseAtomique:145.0;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'Samarium';
   NumeroAtomique:62;
   SymboleChimique:'Sm';
   MasseAtomique:150.36;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'Europium';
   NumeroAtomique:63;
   SymboleChimique:'Eu';
   MasseAtomique:151.964;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'Gadolinium';
   NumeroAtomique:64;
   SymboleChimique:'Gd';
   MasseAtomique:157.25;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'Terbium';
   NumeroAtomique:65;
   SymboleChimique:'Tb';
   MasseAtomique:158.92535;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'Dysprosium';
   NumeroAtomique:66;
   SymboleChimique:'Dy';
   MasseAtomique:162.500;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'Holmium';
   NumeroAtomique:67;
   SymboleChimique:'Ho';
   MasseAtomique:164.93033;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'Erbium';
   NumeroAtomique:68;
   SymboleChimique:'Er';
   MasseAtomique:167.259;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'Thulium';
   NumeroAtomique:69;
   SymboleChimique:'Tm';
   MasseAtomique:168.93422;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'Ytterbium';
   NumeroAtomique:70;
   SymboleChimique:'Yb';
   MasseAtomique:173.045;
   Categorie:Lanthanides;
   Etat:Solide),
  (Groupe:3;
   Periode:6;
   ElementName:'LutÇcium';
   NumeroAtomique:71;
   SymboleChimique:'Lu';
   MasseAtomique:174.9668;
   Categorie:Lanthanides;
   Etat:Solide),
    { Fin des Lanthanides }

  (Groupe:4;
   Periode:6;
   ElementName:'Hafnium';
   NumeroAtomique:72;
   SymboleChimique:'Hf';
   MasseAtomique:178.49;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:5;
   Periode:6;
   ElementName:'Tantale';
   NumeroAtomique:73;
   SymboleChimique:'Ta';
   MasseAtomique:180.94788;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:6;
   Periode:6;
   ElementName:'Tungstäne';
   NumeroAtomique:74;
   SymboleChimique:'W';
   MasseAtomique:183.84;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:7;
   Periode:6;
   ElementName:'RhÇnium';
   NumeroAtomique:75;
   SymboleChimique:'Re';
   MasseAtomique:186.207;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:8;
   Periode:6;
   ElementName:'Osmium';
   NumeroAtomique:76;
   SymboleChimique:'Os';
   MasseAtomique:190.23;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:9;
   Periode:6;
   ElementName:'Iridium';
   NumeroAtomique:77;
   SymboleChimique:'Ir';
   MasseAtomique:192.217;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:10;
   Periode:6;
   ElementName:'Platine';
   NumeroAtomique:78;
   SymboleChimique:'Pt';
   MasseAtomique:195.084;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:11;
   Periode:6;
   ElementName:'Or';
   NumeroAtomique:79;
   SymboleChimique:'Au';
   MasseAtomique:196.966569;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:12;
   Periode:6;
   ElementName:'Mercure';
   NumeroAtomique:80;
   SymboleChimique:'Hg';
   MasseAtomique:200.592;
   Categorie:MetauxPauvres;
   Etat:Liquide),
  (Groupe:13;
   Periode:6;
   ElementName:'Thallium';
   NumeroAtomique:81;
   SymboleChimique:'Tl';
   MasseAtomique:204.3835;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:14;
   Periode:6;
   ElementName:'Plomb';
   NumeroAtomique:82;
   SymboleChimique:'Pb';
   MasseAtomique:207.2;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:15;
   Periode:6;
   ElementName:'Bismuth';
   NumeroAtomique:83;
   SymboleChimique:'Bi';
   MasseAtomique:208.98040;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:16;
   Periode:6;
   ElementName:'Polonium';
   NumeroAtomique:84;
   SymboleChimique:'Po';
   MasseAtomique:209.0;
   Categorie:MetauxPauvres;
   Etat:Solide),
  (Groupe:17;
   Periode:6;
   ElementName:'Astate';
   NumeroAtomique:85;
   SymboleChimique:'At';
   MasseAtomique:210.0;
   Categorie:Metalloides;
   Etat:Solide),
  (Groupe:18;
   Periode:6;
   ElementName:'Radon';
   NumeroAtomique:86;
   SymboleChimique:'Rn';
   MasseAtomique:222.0;
   Categorie:GazNobles;
   Etat:Gaz),
  (Groupe:1;
   Periode:7;
   ElementName:'Francium';
   NumeroAtomique:87;
   SymboleChimique:'Fr';
   MasseAtomique:223.0;
   Categorie:Alcalins;
   Etat:Solide),
  (Groupe:2;
   Periode:7;
   ElementName:'Radium';
   NumeroAtomique:88;
   SymboleChimique:'Ra';
   MasseAtomique:226.0;
   Categorie:Alcalinoterreux;
   Etat:Solide),

    { Actinides }
  (Groupe:3;
   Periode:7;
   ElementName:'Actinium';
   NumeroAtomique:89;
   SymboleChimique:'Ac';
   MasseAtomique:227.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Thorium';
   NumeroAtomique:90;
   SymboleChimique:'Th';
   MasseAtomique:232.0377;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Protactinium';
   NumeroAtomique:91;
   SymboleChimique:'Pa';
   MasseAtomique:231.03588;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Uranium';
   NumeroAtomique:92;
   SymboleChimique:'U';
   MasseAtomique:238.02891;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Neptunium';
   NumeroAtomique:93;
   SymboleChimique:'Np';
   MasseAtomique:237.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Plutonium';
   NumeroAtomique:94;
   SymboleChimique:'Pu';
   MasseAtomique:244.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'AmÇricium';
   NumeroAtomique:95;
   SymboleChimique:'Am';
   MasseAtomique:243.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Curium';
   NumeroAtomique:96;
   SymboleChimique:'Cm';
   MasseAtomique:247.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'BerkÇlium';
   NumeroAtomique:97;
   SymboleChimique:'Bk';
   MasseAtomique:247.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Californium';
   NumeroAtomique:98;
   SymboleChimique:'Cf';
   MasseAtomique:251.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Einsteinium';
   NumeroAtomique:99;
   SymboleChimique:'Es';
   MasseAtomique:252.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Fermium';
   NumeroAtomique:100;
   SymboleChimique:'Fm';
   MasseAtomique:257.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'MendÇlÇvium';
   NumeroAtomique:101;
   SymboleChimique:'Md';
   MasseAtomique:258.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'NobÇlium';
   NumeroAtomique:102;
   SymboleChimique:'No';
   MasseAtomique:259.0;
   Categorie:Actinides;
   Etat:Solide),
  (Groupe:3;
   Periode:7;
   ElementName:'Lawrencium';
   NumeroAtomique:103;
   SymboleChimique:'Lr';
   MasseAtomique:266.0;
   Categorie:Actinides;
   Etat:Solide),
    { Fin du Actinides }

  (Groupe:4;
   Periode:7;
   ElementName:'Rutherfordium';
   NumeroAtomique:104;
   SymboleChimique:'Rf';
   MasseAtomique:267.0;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:5;
   Periode:7;
   ElementName:'Dubnium';
   NumeroAtomique:105;
   SymboleChimique:'Db';
   MasseAtomique:268.0;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:6;
   Periode:7;
   ElementName:'Seaborgium';
   NumeroAtomique:106;
   SymboleChimique:'Sg';
   MasseAtomique:269.0;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:7;
   Periode:7;
   ElementName:'Bohrium';
   NumeroAtomique:107;
   SymboleChimique:'Bh';
   MasseAtomique:270.0;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:8;
   Periode:7;
   ElementName:'Hassium';
   NumeroAtomique:108;
   SymboleChimique:'Hs';
   MasseAtomique:277.0;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:9;
   Periode:7;
   ElementName:'MeitnÇrium';
   NumeroAtomique:109;
   SymboleChimique:'Mt';
   MasseAtomique:278.0;
   Categorie:NonClasses;
   Etat:Solide),
  (Groupe:10;
   Periode:7;
   ElementName:'Darmstaditium';
   NumeroAtomique:110;
   SymboleChimique:'Ds';
   MasseAtomique:281.0;
   Categorie:NonClasses;
   Etat:Solide),
  (Groupe:11;
   Periode:7;
   ElementName:'Roentgenium';
   NumeroAtomique:111;
   SymboleChimique:'Rg';
   MasseAtomique:282.0;
   Categorie:NonClasses;
   Etat:Solide),
  (Groupe:12;
   Periode:7;
   ElementName:'Copernicium';
   NumeroAtomique:112;
   SymboleChimique:'Cn';
   MasseAtomique:285.0;
   Categorie:MetauxDeTransition;
   Etat:Solide),
  (Groupe:13;
   Periode:7;
   ElementName:'Nihonium';
   NumeroAtomique:113;
   SymboleChimique:'Nh';
   MasseAtomique:286.0;
   Categorie:NonClasses;
   Etat:Solide),
  (Groupe:14;
   Periode:7;
   ElementName:'FlÇrovium';
   NumeroAtomique:114;
   SymboleChimique:'Fl';
   MasseAtomique:289.0;
   Categorie:NonClasses;
   Etat:Solide),
  (Groupe:15;
   Periode:7;
   ElementName:'Moscovium';
   NumeroAtomique:115;
   SymboleChimique:'Mc';
   MasseAtomique:289.0;
   Categorie:NonClasses;
   Etat:Solide),
  (Groupe:16;
   Periode:7;
   ElementName:'Livermorium';
   NumeroAtomique:116;
   SymboleChimique:'Lv';
   MasseAtomique:293.0;
   Categorie:NonClasses;
   Etat:Solide),
  (Groupe:17;
   Periode:7;
   ElementName:'Tennesse';
   NumeroAtomique:117;
   SymboleChimique:'Ts';
   MasseAtomique:294.0;
   Categorie:NonClasses;
   Etat:Solide),
  (Groupe:18;
   Periode:7;
   ElementName:'Oganesson';
   NumeroAtomique:118;
   SymboleChimique:'Og';
   MasseAtomique:294.0;
   Categorie:NonClasses;
   Etat:Solide)

 );

Var
 I:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Const
 CanvasTop = 0;
 CanvasBot = 430;

{ ================================================================== }
{ OS/2-0 : PRESENTATION MANAGER, GRAPH ET CRT EMULES                  }
{ ================================================================== }
{ La version DOS dessine avec l'unite Graph du BGI (640 x 480, 16     }
{ couleurs) et lit le clavier et la souris dans sa propre boucle.     }
{ Ici :                                                               }
{  - le dessin va dans une image en memoire de 640 x 480 (un octet    }
{    par point), montree dans la zone client d'une fenetre de PM par  }
{    GpiDrawBits (seules les zones modifiees sont recopiees) ;        }
{  - les lignes 0 a MENU_H - 1 de la version DOS (barre de menus      }
{    dessinee par le programme) sont remplacees par la barre de       }
{    titre et la barre de menus de PM, construites a partir des       }
{    tables de menus d'origine (dans la langue choisie) ;             }
{  - les routines de Graph utilisees (Line, Rectangle, Bar, Circle,   }
{    Arc, FillEllipse, PieSlice, PutPixel, OutTextXY agrandi par      }
{    SetTextStyle, styles de trait et de remplissage) sont ecrites    }
{    ici ;                                                            }
{  - la file de messages de PM (WinPeekMsg) est videe dans une file   }
{    d'evenements : touches (WM_CHAR, en codes du BIOS de la version  }
{    DOS), clics (WM_BUTTON1DOWN), commandes des menus (WM_COMMAND) ; }
{  - les messages et les questions passent par WinMessageBox.         }
{ Palette de l'image : couleurs 0 a 15 du BGI, puis 16 a 31 : memes   }
{ couleurs foncees, lisibles sur le fond blanc des pages de texte.    }

Const
 NormalPut = 0;
 ClipOn = True; ClipOff = False;
 WM_SIZE = $0007; WM_COMMAND = $0020; WM_SYSCOMMAND = $0021; WM_PAINT = $0023;
 WM_CLOSE = $0029; WM_MENUEND = $0035; WM_QUIT = $002A; WM_INITMENU = $0033; WM_MOUSEMOVE = $0070;
 WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
 WM_BUTTON2DOWN = $0074; WM_CHAR = $007A;
 FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100;
 FCF_TASKLIST = $800;
 HWND_DESKTOP = 1; HWND_TOP = 3;
 SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
 MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
 MIA_DISABLED = $4000; MM_SETITEMATTR = $0192;
 MB_OK = 0; MB_YESNO = 4; MB_ICONQUESTION = $10; MB_ICONEXCLAMATION = $20;
 MB_INFORMATION = $30; MB_MOVEABLE = $4000; MBID_YES = 6;
 KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SCANCODE = 4; KC_SHIFT = 8; KC_CTRL = $10;
 KC_ALT = $20; KC_KEYUP = $40;
 VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08;
 VK_ESC = $0F; VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14;
 VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_INSERT = $1A;
 VK_DELETE = $1B; VK_ENTER = $1E; VK_F1 = $20;
 SC_APPMENU = $8006; CMDSRC_ACCELERATOR = 3;
 PM_REMOVE = 1;
 FbW = 640; FbH = 480;
 EvQMax = 64;
 { evenements : 1 touche, 2 clic, 5 commande de menu (9999 = fermer) }
 EV_KEY = 1; EV_CLICK = 2; EV_CMD = 5; CMD_CLOSE = 9999;

Type
 PointType = Record
  X, Y : Integer;
 End;
 FillPatternType = Array[1..8] Of Byte;

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinPeekMsg(Hab, P, HF, First, Last, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSysClassProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WINSYSCLASSPROC';
Function WinSubclassWindow(H, Proc : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryCapture(HD : LongInt) : LongInt; External 'PMWIN';
Function WinQueryActiveWindow(HD : LongInt) : LongInt; External 'PMWIN';
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';

{ police 8 x 8 (256 caracteres, page de codes 437) : police du BGI }
Const
  Font8 : Array[0..2047] Of Byte = (
    $00,$00,$00,$00,$00,$00,$00,$00,$7E,$81,$A5,$81,$BD,$99,$81,$7E,
    $7E,$FF,$DB,$FF,$C3,$E7,$FF,$7E,$6C,$FE,$FE,$FE,$7C,$38,$10,$00,
    $10,$38,$7C,$FE,$7C,$38,$10,$00,$38,$7C,$38,$FE,$FE,$7C,$38,$7C,
    $10,$10,$38,$7C,$FE,$7C,$38,$7C,$00,$00,$18,$3C,$3C,$18,$00,$00,
    $FF,$FF,$E7,$C3,$C3,$E7,$FF,$FF,$00,$3C,$66,$42,$42,$66,$3C,$00,
    $FF,$C3,$99,$BD,$BD,$99,$C3,$FF,$0F,$07,$0F,$7D,$CC,$CC,$CC,$78,
    $3C,$66,$66,$66,$3C,$18,$7E,$18,$3F,$33,$3F,$30,$30,$70,$F0,$E0,
    $7F,$63,$7F,$63,$63,$67,$E6,$C0,$99,$5A,$3C,$E7,$E7,$3C,$5A,$99,
    $80,$E0,$F8,$FE,$F8,$E0,$80,$00,$02,$0E,$3E,$FE,$3E,$0E,$02,$00,
    $18,$3C,$7E,$18,$18,$7E,$3C,$18,$66,$66,$66,$66,$66,$00,$66,$00,
    $7F,$DB,$DB,$7B,$1B,$1B,$1B,$00,$3E,$63,$38,$6C,$6C,$38,$CC,$78,
    $00,$00,$00,$00,$7E,$7E,$7E,$00,$18,$3C,$7E,$18,$7E,$3C,$18,$FF,
    $18,$3C,$7E,$18,$18,$18,$18,$00,$18,$18,$18,$18,$7E,$3C,$18,$00,
    $00,$18,$0C,$FE,$0C,$18,$00,$00,$00,$30,$60,$FE,$60,$30,$00,$00,
    $00,$00,$C0,$C0,$C0,$FE,$00,$00,$00,$24,$66,$FF,$66,$24,$00,$00,
    $00,$18,$3C,$7E,$FF,$FF,$00,$00,$00,$FF,$FF,$7E,$3C,$18,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$30,$78,$78,$78,$30,$00,$30,$00,
    $6C,$6C,$6C,$00,$00,$00,$00,$00,$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00,
    $30,$7C,$C0,$78,$0C,$F8,$30,$00,$00,$C6,$CC,$18,$30,$66,$C6,$00,
    $38,$6C,$38,$76,$DC,$CC,$76,$00,$60,$60,$C0,$00,$00,$00,$00,$00,
    $18,$30,$60,$60,$60,$30,$18,$00,$60,$30,$18,$18,$18,$30,$60,$00,
    $00,$66,$3C,$FF,$3C,$66,$00,$00,$00,$30,$30,$FC,$30,$30,$00,$00,
    $00,$00,$00,$00,$00,$30,$30,$60,$00,$00,$00,$FC,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$30,$30,$00,$06,$0C,$18,$30,$60,$C0,$80,$00,
    $7C,$C6,$C6,$C6,$C6,$C6,$7C,$00,$30,$70,$30,$30,$30,$30,$FC,$00,
    $78,$CC,$0C,$38,$60,$CC,$FC,$00,$78,$CC,$0C,$38,$0C,$CC,$78,$00,
    $1C,$3C,$6C,$CC,$FE,$0C,$1E,$00,$FC,$C0,$F8,$0C,$0C,$CC,$78,$00,
    $38,$60,$C0,$F8,$CC,$CC,$78,$00,$FC,$CC,$0C,$18,$30,$30,$30,$00,
    $78,$CC,$CC,$78,$CC,$CC,$78,$00,$78,$CC,$CC,$7C,$0C,$18,$70,$00,
    $00,$30,$30,$00,$00,$30,$30,$00,$00,$30,$30,$00,$00,$30,$30,$60,
    $18,$30,$60,$C0,$60,$30,$18,$00,$00,$00,$FC,$00,$00,$FC,$00,$00,
    $60,$30,$18,$0C,$18,$30,$60,$00,$78,$CC,$0C,$18,$30,$00,$30,$00,
    $7C,$C6,$DE,$DE,$DE,$C0,$78,$00,$38,$6C,$C6,$C6,$FE,$C6,$C6,$00,
    $FC,$C6,$C6,$FC,$C6,$C6,$FC,$00,$7C,$C6,$C6,$C0,$C0,$C6,$7C,$00,
    $F8,$CC,$C6,$C6,$C6,$CC,$F8,$00,$FE,$C0,$C0,$FC,$C0,$C0,$FE,$00,
    $FE,$C0,$C0,$FC,$C0,$C0,$C0,$00,$7C,$C6,$C0,$CE,$C6,$C6,$7E,$00,
    $C6,$C6,$C6,$FE,$C6,$C6,$C6,$00,$78,$30,$30,$30,$30,$30,$78,$00,
    $1E,$06,$06,$06,$C6,$C6,$7C,$00,$C6,$CC,$D8,$F0,$D8,$CC,$C6,$00,
    $C0,$C0,$C0,$C0,$C0,$C0,$FE,$00,$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00,
    $C6,$E6,$F6,$DE,$CE,$C6,$C6,$00,$7C,$C6,$C6,$C6,$C6,$C6,$7C,$00,
    $FC,$C6,$C6,$FC,$C0,$C0,$C0,$00,$7C,$C6,$C6,$C6,$C6,$C6,$7C,$06,
    $FC,$C6,$C6,$FC,$C6,$C6,$C6,$00,$78,$CC,$60,$30,$18,$CC,$78,$00,
    $FC,$30,$30,$30,$30,$30,$30,$00,$C6,$C6,$C6,$C6,$C6,$C6,$7C,$00,
    $C6,$C6,$C6,$C6,$C6,$6C,$38,$00,$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00,
    $C6,$C6,$6C,$38,$6C,$C6,$C6,$00,$C3,$C3,$66,$3C,$18,$18,$18,$00,
    $FE,$0C,$18,$30,$60,$C0,$FE,$00,$3C,$30,$30,$30,$30,$30,$3C,$00,
    $C0,$60,$30,$18,$0C,$06,$03,$00,$3C,$0C,$0C,$0C,$0C,$0C,$3C,$00,
    $00,$38,$6C,$C6,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,
    $30,$30,$18,$00,$00,$00,$00,$00,$00,$00,$7C,$06,$7E,$C6,$7E,$00,
    $C0,$C0,$FC,$C6,$C6,$E6,$DC,$00,$00,$00,$7C,$C6,$C0,$C0,$7E,$00,
    $06,$06,$7E,$C6,$C6,$CE,$76,$00,$00,$00,$7C,$C6,$FE,$C0,$7E,$00,
    $1E,$30,$7C,$30,$30,$30,$30,$00,$00,$00,$7E,$C6,$CE,$76,$06,$7C,
    $C0,$C0,$FC,$C6,$C6,$C6,$C6,$00,$18,$00,$38,$18,$18,$18,$3C,$00,
    $18,$00,$38,$18,$18,$18,$18,$F0,$C0,$C0,$CC,$D8,$F0,$D8,$CC,$00,
    $38,$18,$18,$18,$18,$18,$3C,$00,$00,$00,$CC,$FE,$D6,$C6,$C6,$00,
    $00,$00,$FC,$C6,$C6,$C6,$C6,$00,$00,$00,$7C,$C6,$C6,$C6,$7C,$00,
    $00,$00,$FC,$C6,$C6,$E6,$DC,$C0,$00,$00,$7E,$C6,$C6,$CE,$76,$06,
    $00,$00,$6E,$70,$60,$60,$60,$00,$00,$00,$7C,$C0,$7C,$06,$FC,$00,
    $30,$30,$7C,$30,$30,$30,$1C,$00,$00,$00,$C6,$C6,$C6,$C6,$7E,$00,
    $00,$00,$C6,$C6,$C6,$6C,$38,$00,$00,$00,$C6,$C6,$D6,$FE,$6C,$00,
    $00,$00,$C6,$6C,$38,$6C,$C6,$00,$00,$00,$C6,$C6,$CE,$76,$06,$7C,
    $00,$00,$FC,$18,$30,$60,$FC,$00,$1C,$30,$30,$E0,$30,$30,$1C,$00,
    $18,$18,$18,$00,$18,$18,$18,$00,$E0,$30,$30,$1C,$30,$30,$E0,$00,
    $76,$DC,$00,$00,$00,$00,$00,$00,$00,$10,$38,$6C,$C6,$C6,$FE,$00,
    $78,$CC,$C0,$CC,$78,$18,$0C,$78,$00,$CC,$00,$CC,$CC,$CC,$7E,$00,
    $1C,$00,$78,$CC,$FC,$C0,$78,$00,$7E,$C3,$3C,$06,$3E,$66,$3F,$00,
    $CC,$00,$78,$0C,$7C,$CC,$7E,$00,$E0,$00,$78,$0C,$7C,$CC,$7E,$00,
    $30,$30,$78,$0C,$7C,$CC,$7E,$00,$00,$00,$78,$C0,$C0,$78,$0C,$38,
    $7E,$C3,$3C,$66,$7E,$60,$3C,$00,$CC,$00,$78,$CC,$FC,$C0,$78,$00,
    $E0,$00,$78,$CC,$FC,$C0,$78,$00,$CC,$00,$70,$30,$30,$30,$78,$00,
    $7C,$C6,$38,$18,$18,$18,$3C,$00,$E0,$00,$70,$30,$30,$30,$78,$00,
    $C6,$38,$6C,$C6,$FE,$C6,$C6,$00,$30,$30,$00,$78,$CC,$FC,$CC,$00,
    $1C,$00,$FC,$60,$78,$60,$FC,$00,$00,$00,$7F,$0C,$7F,$CC,$7F,$00,
    $3E,$6C,$CC,$FE,$CC,$CC,$CE,$00,$78,$CC,$00,$78,$CC,$CC,$78,$00,
    $00,$CC,$00,$78,$CC,$CC,$78,$00,$00,$E0,$00,$78,$CC,$CC,$78,$00,
    $78,$CC,$00,$CC,$CC,$CC,$7E,$00,$00,$E0,$00,$CC,$CC,$CC,$7E,$00,
    $00,$CC,$00,$CC,$CC,$7C,$0C,$F8,$C3,$18,$3C,$66,$66,$3C,$18,$00,
    $CC,$00,$CC,$CC,$CC,$CC,$78,$00,$18,$18,$7E,$C0,$C0,$7E,$18,$18,
    $38,$6C,$64,$F0,$60,$E6,$FC,$00,$CC,$CC,$78,$FC,$30,$FC,$30,$30,
    $F8,$CC,$CC,$FA,$C6,$CF,$C6,$C7,$0E,$1B,$18,$3C,$18,$18,$D8,$70,
    $1C,$00,$78,$0C,$7C,$CC,$7E,$00,$38,$00,$70,$30,$30,$30,$78,$00,
    $00,$1C,$00,$78,$CC,$CC,$78,$00,$00,$1C,$00,$CC,$CC,$CC,$7E,$00,
    $00,$F8,$00,$F8,$CC,$CC,$CC,$00,$FC,$00,$CC,$EC,$FC,$DC,$CC,$00,
    $3C,$6C,$6C,$3E,$00,$7E,$00,$00,$38,$6C,$6C,$38,$00,$7C,$00,$00,
    $30,$00,$30,$60,$C0,$CC,$78,$00,$00,$00,$00,$FC,$C0,$C0,$00,$00,
    $00,$00,$00,$FC,$0C,$0C,$00,$00,$C3,$C6,$CC,$DE,$33,$66,$CC,$0F,
    $C3,$C6,$CC,$DB,$37,$6F,$CF,$03,$18,$18,$00,$18,$18,$18,$18,$00,
    $00,$33,$66,$CC,$66,$33,$00,$00,$00,$CC,$66,$33,$66,$CC,$00,$00,
    $22,$88,$22,$88,$22,$88,$22,$88,$55,$AA,$55,$AA,$55,$AA,$55,$AA,
    $DB,$77,$DB,$EE,$DB,$77,$DB,$EE,$18,$18,$18,$18,$18,$18,$18,$18,
    $18,$18,$18,$18,$F8,$18,$18,$18,$18,$18,$F8,$18,$F8,$18,$18,$18,
    $36,$36,$36,$36,$F6,$36,$36,$36,$00,$00,$00,$00,$FE,$36,$36,$36,
    $00,$00,$F8,$18,$F8,$18,$18,$18,$36,$36,$F6,$06,$F6,$36,$36,$36,
    $36,$36,$36,$36,$36,$36,$36,$36,$00,$00,$FE,$06,$F6,$36,$36,$36,
    $36,$36,$F6,$06,$FE,$00,$00,$00,$36,$36,$36,$36,$FE,$00,$00,$00,
    $18,$18,$F8,$18,$F8,$00,$00,$00,$00,$00,$00,$00,$F8,$18,$18,$18,
    $18,$18,$18,$18,$1F,$00,$00,$00,$18,$18,$18,$18,$FF,$00,$00,$00,
    $00,$00,$00,$00,$FF,$18,$18,$18,$18,$18,$18,$18,$1F,$18,$18,$18,
    $00,$00,$00,$00,$FF,$00,$00,$00,$18,$18,$18,$18,$FF,$18,$18,$18,
    $18,$18,$1F,$18,$1F,$18,$18,$18,$36,$36,$36,$36,$37,$36,$36,$36,
    $36,$36,$37,$30,$3F,$00,$00,$00,$00,$00,$3F,$30,$37,$36,$36,$36,
    $36,$36,$F7,$00,$FF,$00,$00,$00,$00,$00,$FF,$00,$F7,$36,$36,$36,
    $36,$36,$37,$30,$37,$36,$36,$36,$00,$00,$FF,$00,$FF,$00,$00,$00,
    $36,$36,$F7,$00,$F7,$36,$36,$36,$18,$18,$FF,$00,$FF,$00,$00,$00,
    $36,$36,$36,$36,$FF,$00,$00,$00,$00,$00,$FF,$00,$FF,$18,$18,$18,
    $00,$00,$00,$00,$FF,$36,$36,$36,$36,$36,$36,$36,$3F,$00,$00,$00,
    $18,$18,$1F,$18,$1F,$00,$00,$00,$00,$00,$1F,$18,$1F,$18,$18,$18,
    $00,$00,$00,$00,$3F,$36,$36,$36,$36,$36,$36,$36,$FF,$36,$36,$36,
    $18,$18,$FF,$18,$FF,$18,$18,$18,$18,$18,$18,$18,$F8,$00,$00,$00,
    $00,$00,$00,$00,$1F,$18,$18,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
    $00,$00,$00,$00,$FF,$FF,$FF,$FF,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,
    $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$FF,$FF,$FF,$FF,$00,$00,$00,$00,
    $00,$00,$76,$DC,$C8,$DC,$76,$00,$00,$78,$CC,$F8,$CC,$F8,$C0,$C0,
    $00,$FC,$CC,$C0,$C0,$C0,$C0,$00,$00,$FE,$6C,$6C,$6C,$6C,$6C,$00,
    $FC,$CC,$60,$30,$60,$CC,$FC,$00,$00,$00,$7E,$D8,$D8,$D8,$70,$00,
    $00,$66,$66,$66,$66,$7C,$60,$C0,$00,$76,$DC,$18,$18,$18,$18,$00,
    $FC,$30,$78,$CC,$CC,$78,$30,$FC,$38,$6C,$C6,$FE,$C6,$6C,$38,$00,
    $38,$6C,$C6,$C6,$6C,$6C,$EE,$00,$1C,$30,$18,$7C,$CC,$CC,$78,$00,
    $00,$00,$7E,$DB,$DB,$7E,$00,$00,$06,$0C,$7E,$DB,$DB,$7E,$60,$C0,
    $38,$60,$C0,$F8,$C0,$60,$38,$00,$78,$CC,$CC,$CC,$CC,$CC,$CC,$00,
    $00,$FC,$00,$FC,$00,$FC,$00,$00,$30,$30,$FC,$30,$30,$00,$FC,$00,
    $60,$30,$18,$30,$60,$00,$FC,$00,$18,$30,$60,$30,$18,$00,$FC,$00,
    $0E,$1B,$1B,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$D8,$D8,$70,
    $30,$30,$00,$FC,$00,$30,$30,$00,$00,$76,$DC,$00,$76,$DC,$00,$00,
    $38,$6C,$6C,$38,$00,$00,$00,$00,$00,$00,$00,$18,$18,$00,$00,$00,
    $00,$00,$00,$00,$18,$00,$00,$00,$0F,$0C,$0C,$0C,$EC,$6C,$3C,$1C,
    $78,$6C,$6C,$6C,$6C,$00,$00,$00,$70,$18,$30,$60,$78,$00,$00,$00,
    $00,$00,$3C,$3C,$3C,$3C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);

Var
 OsHab, OsHmq, OsFrame, OsClient, Dummy, OsMenu : LongInt;
 Fb : Array[0..FbW * FbH - 1] Of Byte;     { image, lignes de bas en haut }
 Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;   { BITMAPINFO2 et palette }
 DirtyX1, DirtyY1, DirtyX2, DirtyY2 : LongInt;
 GColor, GBk, GFillStyle, GFillColor, GLineStyle, GThick, GWrite : LongInt;
 GLinePat, GTextSz, GJustH, GJustV : LongInt;
 EvMX, EvMY, EvMB : LongInt;
 EvKind, EvKey, EvX, EvY : Array[0..EvQMax - 1] Of LongInt;
 EvHead, EvTail : LongInt;
 NameZ, NameZ2 : Array[0..1023] Of Byte;
 TxtBuf : Array[0..4095] Of Byte;
 MenuT : Array[0..16383] Of Byte;
 MenuLen : LongInt;
 Qmsg : Array[0..7] Of LongInt;
 OsTitle : String;
 MnemoKeys : String;                         { lettres des titres de menus }
 PaperMode : Boolean;                        { page sur fond blanc }
 { fenetre de Graph (SetViewPort) : origine et rectangle de decoupe }
 VOX, VOY, ClipX1, ClipY1, ClipX2, ClipY2 : LongInt;
 GFillPat : Array[1..8] Of Byte;
 { Crt emule : touches (codes du BIOS), commandes des menus, souris }
 KeyQ : Array[0..127] Of LongInt;
 KeyH, KeyT, PendScan : LongInt;
 CmdQ : Array[0..31] Of LongInt;
 CmdH, CmdT : LongInt;
 MBtn, MLatch : LongInt;
 MenuUp, MenuStale, WasActive : LongInt;

{ --- utilitaires --- }

Procedure WrB(A, V : LongInt);
Type PByte1 = ^Byte;
Var Q : PByte1;
Begin
 Q := Pointer(A);
 Q^ := V;
End;

Procedure WrW(A, V : LongInt);
Begin
 WrB(A, V And 255);
 WrB(A + 1, (V Shr 8) And 255);
End;

Procedure WrL(A, V : LongInt);
Begin
 WrW(A, V And $FFFF);
 WrW(A + 2, (V Shr 16) And $FFFF);
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
 For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
 WrB(A + Length(S), 0);
End;

Function OsZ(S : String) : LongInt;
Begin
 PutZ(LongInt(@NameZ), S);
 OsZ := LongInt(@NameZ);
End;

Function OsZ2(S : String) : LongInt;
Begin
 PutZ(LongInt(@NameZ2), S);
 OsZ2 := LongInt(@NameZ2);
End;

Function Lo16(V : LongInt) : LongInt;
Begin
 Lo16 := V And $FFFF;
End;

Function Hi16(V : LongInt) : LongInt;
Begin
 Hi16 := (V Shr 16) And $FFFF;
End;

Function S16(V : LongInt) : LongInt;
Begin
 V := V And $FFFF;
 If V >= $8000 Then V := V - $10000;
 S16 := V;
End;

Function Min2(A, B : LongInt) : LongInt;
Begin
 If A < B Then Min2 := A Else Min2 := B;
End;

Function Max2(A, B : LongInt) : LongInt;
Begin
 If A > B Then Max2 := A Else Max2 := B;
End;

{ --- image et zones modifiees --- }

Procedure GTouch(X1, Y1, X2, Y2 : LongInt);
Begin
 If X1 < 0 Then X1 := 0;
 If Y1 < 0 Then Y1 := 0;
 If X2 > FbW - 1 Then X2 := FbW - 1;
 If Y2 > FbH - 1 Then Y2 := FbH - 1;
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 If DirtyX1 < 0 Then
 Begin
  DirtyX1 := X1; DirtyY1 := Y1; DirtyX2 := X2; DirtyY2 := Y2;
 End
 Else
 Begin
  If X1 < DirtyX1 Then DirtyX1 := X1;
  If Y1 < DirtyY1 Then DirtyY1 := Y1;
  If X2 > DirtyX2 Then DirtyX2 := X2;
  If Y2 > DirtyY2 Then DirtyY2 := Y2;
 End;
End;

Procedure Plot(X, Y, C : LongInt);
Var A : LongInt;
Begin
 If (X < ClipX1) Or (Y < ClipY1) Or (X > ClipX2) Or (Y > ClipY2) Then Exit;
 A := (FbH - 1 - Y) * FbW + X;
 If GWrite = XORPut Then Fb[A] := (Fb[A] Xor C) And 255 Else Fb[A] := C And 255;
End;

Procedure HSpan(X1, X2, Y, C : LongInt);
Var A, X : LongInt;
Begin
 If (Y < ClipY1) Or (Y > ClipY2) Then Exit;
 If X1 < ClipX1 Then X1 := ClipX1;
 If X2 > ClipX2 Then X2 := ClipX2;
 If X2 < X1 Then Exit;
 A := (FbH - 1 - Y) * FbW;
 If GWrite = XORPut Then
  For X := X1 To X2 Do Fb[A + X] := (Fb[A + X] Xor C) And 255
 Else
  For X := X1 To X2 Do Fb[A + X] := C And 255;
End;

{ motif de remplissage : bit du point (X, Y) }
Function FillBit(X, Y : LongInt) : Boolean;
Var B : LongInt;
Begin
 Case GFillStyle Of
  EmptyFill : B := 0;
  SolidFill : B := $FF;
  LineFill : If (Y And 7) < 2 Then B := $FF Else B := 0;
  LtSlashFill, SlashFill : B := $80 Shr ((X + Y) And 7);
  BkSlashFill, LtBkSlashFill : B := $01 Shl ((X + Y) And 7);
  HatchFill : If (Y And 7) = 0 Then B := $FF Else B := $80;
  XHatchFill : B := ($80 Shr ((X + Y) And 7)) Or ($01 Shl ((X + Y) And 7));
  InterleaveFill : If (Y And 1) = 0 Then B := $CC Else B := $33;
  WideDotFill : If (Y And 7) = 0 Then B := $80 Else B := 0;
  CloseDotFill : If (Y And 1) = 0 Then B := $88 Else B := 0;
  UserFill : B := GFillPat[(Y And 7) + 1];
 Else
  B := $FF;
 End;
 FillBit := (B And ($80 Shr (X And 7))) <> 0;
End;

{ ligne horizontale remplie selon le motif (bits a 0 : couleur de fond) }
Procedure FillSpan(X1, X2, Y : LongInt);
Var X : LongInt;
Begin
 If GFillStyle = SolidFill Then
 Begin
  HSpan(X1, X2, Y, GFillColor);
  Exit;
 End;
 For X := X1 To X2 Do
  If FillBit(X, Y) Then Plot(X, Y, GFillColor) Else Plot(X, Y, GBk);
End;

{ --- Graph : etat --- }

{ sur une page a fond blanc (PaperMode), les traits et le texte prennent
  la version foncee de leur couleur (blanc -> noir) ; les remplissages
  gardent leurs couleurs }
Procedure SetColor(C : Integer);
Begin
 C := C And 255;
 If PaperMode And (C > 0) And (C < 16) Then C := 16 + C;
 GColor := C;
End;

Function GetColor : Integer;
Begin
 GetColor := GColor;
End;

Procedure SetLineStyle(Style : Integer; Pattern : Word; Thick : Integer);
Begin
 GLineStyle := Style;
 Case Style Of
  DottedLn : GLinePat := $CCCC;
  CenterLn : GLinePat := $FC78;
  DashedLn : GLinePat := $F8F8;
  UserBitLn : GLinePat := Pattern;
 Else
  GLinePat := $FFFF;
 End;
 If Thick >= 3 Then GThick := 3 Else GThick := 1;
End;

Procedure SetFillStyle(Pattern : Integer; Color : Integer);
Begin
 GFillStyle := Pattern;
 GFillColor := Color And 255;
End;

Procedure SetTextStyle(Font, Dir, Size : Integer);
Begin
 If Size < 1 Then Size := 1;
 If Size > 10 Then Size := 10;
 GTextSz := Size;
End;

Procedure SetTextJustify(H, V : Integer);
Begin
 GJustH := H;
 GJustV := V;
End;

{ --- Graph : traits --- }

Procedure LineThin(X1, Y1, X2, Y2 : LongInt);
Var Dx, Dy, Sx, Sy, E, E2, N : LongInt;
Begin
 Dx := Abs(X2 - X1); Dy := -Abs(Y2 - Y1);
 If X1 < X2 Then Sx := 1 Else Sx := -1;
 If Y1 < Y2 Then Sy := 1 Else Sy := -1;
 E := Dx + Dy; N := 0;
 While True Do
 Begin
  If (GLinePat And ($8000 Shr (N And 15))) <> 0 Then Plot(X1, Y1, GColor);
  Inc(N);
  If (X1 = X2) And (Y1 = Y2) Then Exit;
  E2 := 2 * E;
  If E2 >= Dy Then
  Begin
   E := E + Dy; X1 := X1 + Sx;
  End;
  If E2 <= Dx Then
  Begin
   E := E + Dx; Y1 := Y1 + Sy;
  End;
 End;
End;

Procedure LineA(X1, Y1, X2, Y2 : Integer);
Begin
 GTouch(Min2(X1, X2) - 1, Min2(Y1, Y2) - 1, Max2(X1, X2) + 1, Max2(Y1, Y2) + 1);
 If GThick = 3 Then
 Begin
  If Abs(X2 - X1) >= Abs(Y2 - Y1) Then
  Begin
   LineThin(X1, Y1 - 1, X2, Y2 - 1); LineThin(X1, Y1, X2, Y2); LineThin(X1, Y1 + 1, X2, Y2 + 1);
  End
  Else
  Begin
   LineThin(X1 - 1, Y1, X2 - 1, Y2); LineThin(X1, Y1, X2, Y2); LineThin(X1 + 1, Y1, X2 + 1, Y2);
  End;
 End
 Else LineThin(X1, Y1, X2, Y2);
End;

Procedure RectangleA(X1, Y1, X2, Y2 : Integer);
Begin
 LineA(X1, Y1, X2, Y1); LineA(X2, Y1, X2, Y2);
 LineA(X2, Y2, X1, Y2); LineA(X1, Y2, X1, Y1);
End;

Procedure BarA(X1, Y1, X2, Y2 : Integer);
Var Y, T : LongInt;
Begin
 If X1 > X2 Then
 Begin
  T := X1; X1 := X2; X2 := T;
 End;
 If Y1 > Y2 Then
 Begin
  T := Y1; Y1 := Y2; Y2 := T;
 End;
 GTouch(X1, Y1, X2, Y2);
 For Y := Y1 To Y2 Do FillSpan(X1, X2, Y);
End;

Procedure PutPixelA(X, Y : Integer; C : Word);
Begin
 GTouch(X, Y, X, Y);
 Plot(X, Y, C);
End;

Function GetPixelA(X, Y : Integer) : Word;
Begin
 If (X < 0) Or (Y < 0) Or (X >= FbW) Or (Y >= FbH) Then GetPixelA := 0
 Else GetPixelA := Fb[(FbH - 1 - Y) * FbW + X];
End;

{ --- Graph : ellipses (angles en degres, sens trigonometrique) --- }

Procedure EllipseA(X, Y : Integer; StAngle, EndAngle : Word; XR, YR : Word);
Var A, A2, Steps, K, Px, Py, Qx, Qy : LongInt; T : Double;
Begin
 If (XR = 0) And (YR = 0) Then
 Begin
  PutPixelA(X, Y, GColor);
  Exit;
 End;
 A := StAngle; A2 := EndAngle;
 If A2 <= A Then A2 := A2 + 360;
 If (StAngle = 0) And (EndAngle = 360) Then A2 := 360;
 Steps := ((A2 - A) * (XR + YR)) Div 60 + 8;
 If Steps > 720 Then Steps := 720;
 GTouch(X - XR - 2, Y - YR - 2, X + XR + 2, Y + YR + 2);
 T := A * Pi / 180;
 Px := X + Round(XR * Cos(T)); Py := Y - Round(YR * Sin(T));
 For K := 1 To Steps Do
 Begin
  T := (A + (A2 - A) * K / Steps) * Pi / 180;
  Qx := X + Round(XR * Cos(T)); Qy := Y - Round(YR * Sin(T));
  If (Qx <> Px) Or (Qy <> Py) Then
  Begin
   If GThick = 3 Then LineA(Px, Py, Qx, Qy) Else LineThin(Px, Py, Qx, Qy);
   Px := Qx; Py := Qy;
  End;
 End;
End;

Procedure FillEllipseA(X, Y : Integer; XR, YR : Word);
Var Dy, W : LongInt; T : Double;
Begin
 GTouch(X - XR - 1, Y - YR - 1, X + XR + 1, Y + YR + 1);
 For Dy := -YR To YR Do
 Begin
  If YR = 0 Then W := XR
  Else
  Begin
   T := 1 - (Dy * Dy) / (YR * 1.0 * YR);
   If T < 0 Then T := 0;
   W := Round(XR * Sqrt(T));
  End;
  FillSpan(X - W, X + W, Y + Dy);
 End;
 EllipseA(X, Y, 0, 360, XR, YR);
End;

Procedure ArcA(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 EllipseA(X, Y, StAngle, EndAngle, Radius, Radius);
End;

Procedure CircleA(X, Y : Integer; Radius : Word);
Begin
 EllipseA(X, Y, 0, 360, Radius, Radius);
End;

{ secteur plein de StAngle a EndAngle (degres), puis son contour }
Procedure PieSliceA(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Var Dx, Dy, R2, A0, A1 : LongInt; Ang : Double; Inside : Boolean;
Begin
 A0 := StAngle; A1 := EndAngle;
 If A1 < A0 Then A1 := A1 + 360;
 R2 := LongInt(Radius) * Radius;
 GTouch(X - Radius - 1, Y - Radius - 1, X + Radius + 1, Y + Radius + 1);
 For Dy := -Radius To Radius Do
  For Dx := -Radius To Radius Do
   If Dx * Dx + Dy * Dy <= R2 Then
   Begin
    If (Dx = 0) And (Dy = 0) Then Ang := 0
    Else
    Begin
     If Dx = 0 Then
     Begin
      If Dy < 0 Then Ang := 90 Else Ang := 270;
     End
     Else
     Begin
      Ang := ArcTan(-Dy / Dx) * 180 / Pi;
      If Dx < 0 Then Ang := Ang + 180
      Else If -Dy < 0 Then Ang := Ang + 360;
     End;
    End;
    Inside := (Ang >= A0) And (Ang <= A1);
    If (Not Inside) And (A1 > 360) Then Inside := Ang + 360 <= A1;
    If Inside Then
    Begin
     If FillBit(X + Dx, Y + Dy) Then Plot(X + Dx, Y + Dy, GFillColor)
     Else Plot(X + Dx, Y + Dy, GBk);
    End;
   End;
 { contour : couleur du trait ; si c'est la version foncee (page blanche)
   de la couleur de remplissage, la couleur de remplissage (comme le BGI,
   ou le secteur et son contour sont de la meme couleur) }
 If GColor = 16 + GFillColor Then GColor := GFillColor;
 EllipseA(X, Y, StAngle, EndAngle, Radius, Radius);
 LineA(X, Y, X + Round(Radius * Cos(A0 * Pi / 180)), Y - Round(Radius * Sin(A0 * Pi / 180)));
 LineA(X, Y, X + Round(Radius * Cos(A1 * Pi / 180)), Y - Round(Radius * Sin(A1 * Pi / 180)));
End;

{ --- Graph : texte (police 8 x 8 agrandie GTextSz fois, fond transparent) --- }

Procedure OutTextXYA(X, Y : Integer; S : String);
Var I, R, K, B, C, Sz, W, Cx, R0 : LongInt; Hat : Boolean;
Begin
 If S = '' Then Exit;
 Sz := GTextSz;
 W := Length(S) * 8 * Sz;
 If GJustH = CenterText Then X := X - W Div 2
 Else If GJustH = RightText Then X := X - W;
 If GJustV = CenterText Then Y := Y - 4 * Sz
 Else If GJustV = BottomText Then Y := Y - 8 * Sz;
 GTouch(X, Y - Sz, X + W - 1, Y + 8 * Sz - 1);
 For I := 1 To Length(S) Do
 Begin
  C := Ord(S[I]);
  { a, e, i, o, u circonflexes : dans la police 8 x 8, l'accent colle a
    la lettre ; on dessine la lettre de base puis l'accent au-dessus }
  Hat := True;
  Case C Of
   131 : C := Ord('a');
   136 : C := Ord('e');
   140 : C := Ord('i');
   147 : C := Ord('o');
   150 : C := Ord('u');
  Else Hat := False;
  End;
  If Hat Then R0 := 2 Else R0 := 0;
  Cx := X + (I - 1) * 8 * Sz;
  For R := R0 To 7 Do
  Begin
   B := Font8[C * 8 + R];
   If B <> 0 Then
    For K := 0 To 7 Do
     If (B And ($80 Shr K)) <> 0 Then
     Begin
      If Sz = 1 Then Plot(Cx + K, Y + R, GColor)
      Else For W := 0 To Sz - 1 Do
       HSpan(Cx + K * Sz, Cx + (K + 1) * Sz - 1, Y + R * Sz + W, GColor);
     End;
  End;
  If Hat Then
   For W := 0 To Sz - 1 Do
   Begin
    HSpan(Cx + 3 * Sz, Cx + 5 * Sz - 1, Y - Sz + W, GColor);
    HSpan(Cx + 2 * Sz, Cx + 3 * Sz - 1, Y + W, GColor);
    HSpan(Cx + 5 * Sz, Cx + 6 * Sz - 1, Y + W, GColor);
   End;
 End;
End;

Procedure ClearDevice;
Var K : LongInt;
Begin
 For K := 0 To FbW * FbH - 1 Do Fb[K] := GBk;
 GTouch(0, 0, FbW - 1, FbH - 1);
End;

{ --- Graph : fenetre (SetViewPort), fonctions publiques (coordonnees
  relatives a la fenetre courante) --- }

Procedure SetViewPort(X1, Y1, X2, Y2 : Integer; Clip : Boolean);
Begin
 VOX := X1; VOY := Y1;
 If Clip Then
 Begin
  ClipX1 := Max2(X1, 0); ClipY1 := Max2(Y1, 0);
  ClipX2 := Min2(X2, FbW - 1); ClipY2 := Min2(Y2, FbH - 1);
 End
 Else
 Begin
  ClipX1 := 0; ClipY1 := 0; ClipX2 := FbW - 1; ClipY2 := FbH - 1;
 End;
End;

Procedure ClearViewPort;
Var Y : LongInt;
Begin
 GTouch(ClipX1, ClipY1, ClipX2, ClipY2);
 For Y := ClipY1 To ClipY2 Do HSpan(ClipX1, ClipX2, Y, GBk);
End;

Function GetMaxX : Integer;
Begin
 GetMaxX := FbW - 1;
End;

Function GetMaxY : Integer;
Begin
 GetMaxY := CanvasBot;
End;

Function GraphResult : Integer;
Begin
 GraphResult := 0;
End;

Procedure SetBkColor(C : Integer);
Begin
 GBk := C And 255;
End;

Procedure SetWriteMode(M : Integer);
Begin
 If M = XORPut Then GWrite := XORPut Else GWrite := NormalPut;
End;

Procedure SetFillPattern(Pat : FillPatternType; Color : Integer);
Var I : Integer;
Begin
 For I := 1 To 8 Do GFillPat[I] := Pat[I];
 GFillStyle := UserFill;
 GFillColor := Color And 255;
End;

Function TextWidth(S : String) : Integer;
Begin
 TextWidth := Length(S) * 8 * GTextSz;
End;

Function TextHeight(S : String) : Integer;
Begin
 TextHeight := 8 * GTextSz;
End;

Procedure Line(X1, Y1, X2, Y2 : Integer);
Begin
 LineA(X1 + VOX, Y1 + VOY, X2 + VOX, Y2 + VOY);
End;

Procedure Rectangle(X1, Y1, X2, Y2 : Integer);
Begin
 RectangleA(X1 + VOX, Y1 + VOY, X2 + VOX, Y2 + VOY);
End;

Procedure Bar(X1, Y1, X2, Y2 : Integer);
Begin
 BarA(X1 + VOX, Y1 + VOY, X2 + VOX, Y2 + VOY);
End;

Procedure PutPixel(X, Y : Integer; C : Word);
Begin
 PutPixelA(X + VOX, Y + VOY, C);
End;

Function GetPixel(X, Y : Integer) : Word;
Begin
 GetPixel := GetPixelA(X + VOX, Y + VOY);
End;

Procedure Ellipse(X, Y : Integer; StAngle, EndAngle : Word; XR, YR : Word);
Begin
 EllipseA(X + VOX, Y + VOY, StAngle, EndAngle, XR, YR);
End;

Procedure FillEllipse(X, Y : Integer; XR, YR : Word);
Begin
 FillEllipseA(X + VOX, Y + VOY, XR, YR);
End;

Procedure Arc(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 ArcA(X + VOX, Y + VOY, StAngle, EndAngle, Radius);
End;

Procedure Circle(X, Y : Integer; Radius : Word);
Begin
 CircleA(X + VOX, Y + VOY, Radius);
End;

Procedure PieSlice(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 PieSliceA(X + VOX, Y + VOY, StAngle, EndAngle, Radius);
End;

Procedure OutTextXY(X, Y : Integer; S : String);
Begin
 OutTextXYA(X + VOX, Y + VOY, S);
End;

{ polygone plein (regle pair-impair), puis son contour }
Procedure FillPoly(N : Integer; Var Pts);
Type TPts = Array[1..512] Of PointType;
Var P : ^TPts; I, J, Y, Y1, Y2, K, Cnt, T, Xa, Ya, Xb, Yb : LongInt; Xs : Array[0..127] Of LongInt;
Begin
 P := @Pts;
 If (N < 2) Or (N > 512) Then Exit;
 Y1 := P^[1].Y; Y2 := P^[1].Y;
 For I := 2 To N Do
 Begin
  If P^[I].Y < Y1 Then Y1 := P^[I].Y;
  If P^[I].Y > Y2 Then Y2 := P^[I].Y;
 End;
 For Y := Y1 To Y2 Do
 Begin
  Cnt := 0;
  For I := 1 To N Do
  Begin
   J := I + 1;
   If J > N Then J := 1;
   Xa := P^[I].X; Ya := P^[I].Y; Xb := P^[J].X; Yb := P^[J].Y;
   If ((Ya <= Y) And (Yb > Y)) Or ((Yb <= Y) And (Ya > Y)) Then
    If Cnt < 128 Then
    Begin
     Xs[Cnt] := Xa + ((Y - Ya) * (Xb - Xa)) Div (Yb - Ya);
     Inc(Cnt);
    End;
  End;
  For I := 1 To Cnt - 1 Do
  Begin
   T := Xs[I]; K := I - 1;
   While (K >= 0) And (Xs[K] > T) Do
   Begin
    Xs[K + 1] := Xs[K];
    Dec(K);
   End;
   Xs[K + 1] := T;
  End;
  I := 0;
  While I + 1 < Cnt Do
  Begin
   GTouch(Xs[I] + VOX, Y + VOY, Xs[I + 1] + VOX, Y + VOY);
   FillSpan(Xs[I] + VOX, Xs[I + 1] + VOX, Y + VOY);
   I := I + 2;
  End;
 End;
 For I := 1 To N Do
 Begin
  J := I + 1;
  If J > N Then J := 1;
  Line(P^[I].X, P^[I].Y, P^[J].X, P^[J].Y);
 End;
End;

Procedure DrawPoly(N : Integer; Var Pts);
Type TPtsD = Array[1..512] Of PointType;
Var P : ^TPtsD; I : LongInt;
Begin
 P := @Pts;
 For I := 1 To N - 1 Do Line(P^[I].X, P^[I].Y, P^[I + 1].X, P^[I + 1].Y);
End;

{ images : largeur, hauteur (2 mots) puis un octet par point }
Function ImageSize(X1, Y1, X2, Y2 : Integer) : Word;
Begin
 ImageSize := (Abs(X2 - X1) + 1) * (Abs(Y2 - Y1) + 1) + 4;
End;

Procedure GetImage(X1, Y1, X2, Y2 : Integer; Var BitMap);
Type TB = Array[0..65535] Of Byte;
Var P : ^TB; X, Y, W, H, K : LongInt;
Begin
 P := @BitMap;
 W := X2 - X1 + 1; H := Y2 - Y1 + 1;
 P^[0] := W And 255; P^[1] := W Shr 8; P^[2] := H And 255; P^[3] := H Shr 8;
 K := 4;
 For Y := Y1 To Y2 Do
  For X := X1 To X2 Do
  Begin
   P^[K] := GetPixel(X, Y);
   Inc(K);
  End;
End;

Procedure PutImage(X1, Y1 : Integer; Var BitMap; Op : Word);
Type TBP = Array[0..65535] Of Byte;
Var P : ^TBP; X, Y, W, H, K, Old : LongInt;
Begin
 P := @BitMap;
 W := P^[0] + P^[1] * 256; H := P^[2] + P^[3] * 256;
 Old := GWrite;
 If Op = XORPut Then GWrite := XORPut Else GWrite := NormalPut;
 GTouch(X1 + VOX, Y1 + VOY, X1 + VOX + W - 1, Y1 + VOY + H - 1);
 K := 4;
 For Y := 0 To H - 1 Do
  For X := 0 To W - 1 Do
  Begin
   Plot(X1 + VOX + X, Y1 + VOY + Y, P^[K]);
   Inc(K);
  End;
 GWrite := Old;
End;

{ --- palette de l'image (BITMAPINFO2 de 8 bits) --- }

Procedure InitBmi;
Const
 Pal : Array[0..31] Of LongInt = (
  $000000, $0000AA, $00AA00, $00AAAA, $AA0000, $AA00AA, $AA5500, $AAAAAA,
  $555555, $5555FF, $55FF55, $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF,
  { couleurs foncees pour le fond blanc (16 + couleur du BGI) }
  $000000, $00008C, $00782A, $006E78, $A00000, $820082, $8C4600, $505050,
  $969696, $1E46C8, $00963C, $0082A0, $D21E1E, $B400B4, $A07800, $000000);
Var I, A : LongInt;
Begin
 FillChar(Bmi, SizeOf(Bmi), 0);
 WrL(LongInt(@Bmi), 16);
 WrL(LongInt(@Bmi) + 4, FbW);
 WrL(LongInt(@Bmi) + 8, FbH);
 WrW(LongInt(@Bmi) + 12, 1);
 WrW(LongInt(@Bmi) + 14, 8);
 For I := 0 To 31 Do
 Begin
  A := LongInt(@Bmi) + 16 + I * 4;
  WrB(A, Pal[I] And 255);
  WrB(A + 1, (Pal[I] Shr 8) And 255);
  WrB(A + 2, (Pal[I] Shr 16) And 255);
 End;
 GColor := White; GBk := Black; GFillStyle := SolidFill; GFillColor := White;
 GLineStyle := SolidLn; GLinePat := $FFFF; GThick := 1; GWrite := NormalPut;
 GTextSz := 1; GJustH := LeftText; GJustV := TopText; PaperMode := False;
 VOX := 0; VOY := 0; ClipX1 := 0; ClipY1 := 0; ClipX2 := FbW - 1; ClipY2 := FbH - 1;
 KeyH := 0; KeyT := 0; PendScan := -1; MenuUp := 0; MenuStale := 0; WasActive := 1; CmdH := 0; CmdT := 0; MBtn := 0; MLatch := 0;
 DirtyX1 := -1;
End;

{ couleur I de la palette de l'image (32 a 255 : couleurs du programme),
  RGB = $RRGGBB }
Procedure SetPalEntry(I, RGB : LongInt);
Var A : LongInt;
Begin
 A := LongInt(@Bmi) + 16 + I * 4;
 WrB(A, RGB And 255);
 WrB(A + 1, (RGB Shr 8) And 255);
 WrB(A + 2, (RGB Shr 16) And 255);
End;

{ couleur foncee (lisible sur fond blanc) d'une couleur du BGI }
Function DocCol(C : Integer) : Integer;
Begin
 DocCol := 16 + (C And 15);
End;

{ --- affichage dans la zone client --- }

{ montrer la zone X1..X2, Y1..Y2 de l'image (Y vers le bas) dans la zone
  client : seules les lignes CanvasTop a CanvasBot de l'image sont
  montrees ; la ligne Y de l'image est la ligne CanvasBot - Y du client }
{ fenetre secondaire de PM (vue graphique dans sa propre fenetre) : elle
  montre le rectangle CatX0, CatY0, CatW x CatH de l'image, sauf les
  rectangles de ses controles (PMWIN ne decoupe pas le dessin du parent
  autour de ses fenetres filles) }
Var
 CatFr, CatCl, CatX0, CatY0, CatW, CatH, CatNEx : LongInt;
 CatSave : Pointer;                  { image de la fenetre principale figee }
 CatEx : Array[0..15, 0..3] Of LongInt;

Procedure CatBlitK(Hps, X1, Y1, X2, Y2, K : LongInt);
Var P : Array[0..7] Of LongInt; A1, B1, A2, B2 : LongInt;
Begin
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 If K < CatNEx Then
 Begin
  A1 := CatEx[K, 0]; B1 := CatEx[K, 1]; A2 := CatEx[K, 2]; B2 := CatEx[K, 3];
  If (A1 > X2) Or (A2 < X1) Or (B1 > Y2) Or (B2 < Y1) Then
   CatBlitK(Hps, X1, Y1, X2, Y2, K + 1)
  Else
  Begin
   If B1 > Y1 Then CatBlitK(Hps, X1, Y1, X2, B1 - 1, K + 1);
   If B2 < Y2 Then CatBlitK(Hps, X1, B2 + 1, X2, Y2, K + 1);
   If B1 > Y1 Then Y1 := B1;
   If B2 < Y2 Then Y2 := B2;
   If A1 > X1 Then CatBlitK(Hps, X1, Y1, A1 - 1, Y2, K + 1);
   If A2 < X2 Then CatBlitK(Hps, A2 + 1, Y1, X2, Y2, K + 1);
  End;
  Exit;
 End;
 P[0] := X1 - CatX0; P[1] := CatY0 + CatH - 1 - Y2;
 P[2] := X2 + 1 - CatX0; P[3] := CatY0 + CatH - Y1;
 P[4] := X1; P[5] := FbH - 1 - Y2; P[6] := X2 + 1; P[7] := FbH - Y1;
 Dummy := GpiDrawBits(Hps, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

Procedure CatBlit(Hps, X1, Y1, X2, Y2 : LongInt);
Begin
 If X1 < CatX0 Then X1 := CatX0;
 If Y1 < CatY0 Then Y1 := CatY0;
 If X2 > CatX0 + CatW - 1 Then X2 := CatX0 + CatW - 1;
 If Y2 > CatY0 + CatH - 1 Then Y2 := CatY0 + CatH - 1;
 CatBlitK(Hps, X1, Y1, X2, Y2, 0);
End;

Procedure Blit(Hps, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt; Src : LongInt;
Begin
 Src := LongInt(@Fb);
 If (CatCl <> 0) And (CatSave <> Nil) Then Src := LongInt(CatSave);
 If Y1 < CanvasTop Then Y1 := CanvasTop;
 If Y2 > CanvasBot Then Y2 := CanvasBot;
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 P[0] := X1; P[1] := CanvasBot - Y2; P[2] := X2 + 1; P[3] := CanvasBot - Y1 + 1;
 P[4] := X1; P[5] := FbH - 1 - Y2; P[6] := X2 + 1; P[7] := FbH - Y1;
 Dummy := GpiDrawBits(Hps, Src, LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

{ envoyer a l'ecran ce qui a change depuis le dernier appel }
Procedure FlushScreen;
Var Hps, Cap : LongInt;
Begin
 If OsClient = 0 Then Exit;
 { PM ne decoupe pas le dessin par les fenetres qui recouvrent celle-ci :
   rien n'est montre hors de WM_PAINT quand un menu est ouvert ou que la
   fenetre n'est pas active ; tout est remontre au retour }
 Cap := WinQueryCapture(HWND_DESKTOP);
 If (MenuUp <> 0) And (Cap = 0) Then
 Begin
  Inc(MenuStale);
  If MenuStale > 5 Then MenuUp := 0;
 End
 Else MenuStale := 0;
 { vue graphique dans une fenetre a part : seule celle-ci est mise a jour }
 If CatCl <> 0 Then
 Begin
  WasActive := 0;
  If (MenuUp = 0) And (DirtyX1 >= 0) And (WinQueryActiveWindow(HWND_DESKTOP) = CatFr) Then
  Begin
   Hps := WinGetPS(CatCl);
   If Hps <> 0 Then
   Begin
    CatBlit(Hps, DirtyX1, DirtyY1, DirtyX2, DirtyY2);
    Dummy := WinReleasePS(Hps);
   End;
   DirtyX1 := -1;
  End;
  Exit;
 End;
 If (MenuUp <> 0) Or ((Cap <> 0) And (Cap <> OsClient)) Or
    (WinQueryActiveWindow(HWND_DESKTOP) <> OsFrame) Then
 Begin
  WasActive := 0;
  Exit;
 End;
 If WasActive = 0 Then
 Begin
  GTouch(0, 0, FbW - 1, FbH - 1);
  WasActive := 1;
 End;
 If DirtyX1 < 0 Then Exit;
 Hps := WinGetPS(OsClient);
 If Hps <> 0 Then
 Begin
  Blit(Hps, DirtyX1, DirtyY1, DirtyX2, DirtyY2);
  Dummy := WinReleasePS(Hps);
 End;
 DirtyX1 := -1;
End;

{ --- file d'evenements (remplie par la procedure de fenetre) --- }

Procedure EvPush(K, Key, X, Y : LongInt);
Var N : LongInt;
Begin
 N := (EvTail + 1) Mod EvQMax;
 If N = EvHead Then Exit;
 EvKind[EvTail] := K; EvKey[EvTail] := Key; EvX[EvTail] := X; EvY[EvTail] := Y;
 EvTail := N;
End;

{ Alt + lettre -> code de balayage du clavier du PC }
Function AltScan(C : Char) : LongInt;
Const
 R1 : String[10] = 'QWERTYUIOP';
 R2 : String[9] = 'ASDFGHJKL';
 R3 : String[7] = 'ZXCVBNM';
Begin
 AltScan := 0;
 C := UpCase(C);
 If Pos(C, R1) > 0 Then AltScan := 15 + Pos(C, R1);
 If Pos(C, R2) > 0 Then AltScan := 29 + Pos(C, R2);
 If Pos(C, R3) > 0 Then AltScan := 43 + Pos(C, R3);
End;

{ touche de PM (WM_CHAR) -> code de la version DOS : caractere = Ord,
  touche etendue = 256 + code de balayage du BIOS }
Function KeyCode(Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Ch, Vk, K : LongInt;
Begin
 KeyCode := -1;
 Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
 If (Fl And KC_KEYUP) <> 0 Then Exit;
 K := -1;
 If (Fl And KC_VIRTUALKEY) <> 0 Then
 Begin
  Case Vk Of
   VK_ESC : K := 27;
   VK_NEWLINE, VK_ENTER : K := 13;
   VK_BACKSPACE : K := 8;
   VK_TAB : If (Fl And KC_SHIFT) <> 0 Then K := 271 Else K := 9;
   VK_BACKTAB : K := 271;
   VK_UP : K := 328;
   VK_DOWN : K := 336;
   VK_LEFT : If (Fl And KC_CTRL) <> 0 Then K := 371 Else K := 331;
   VK_RIGHT : If (Fl And KC_CTRL) <> 0 Then K := 372 Else K := 333;
   VK_HOME : If (Fl And KC_CTRL) <> 0 Then K := 375 Else K := 327;
   VK_END : If (Fl And KC_CTRL) <> 0 Then K := 373 Else K := 335;
   VK_PAGEUP : If (Fl And KC_CTRL) <> 0 Then K := 388 Else K := 329;
   VK_PAGEDOWN : If (Fl And KC_CTRL) <> 0 Then K := 374 Else K := 337;
   VK_INSERT : K := 338;
   VK_DELETE : K := 339;
  End;
  If (Vk >= VK_F1) And (Vk <= VK_F1 + 9) And ((Fl And (KC_ALT Or KC_CTRL Or KC_SHIFT)) = 0) Then
   K := 315 + Vk - VK_F1;
 End;
 If (K < 0) And ((Fl And KC_ALT) <> 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  { Alt + lettre d'un titre de menu : laissee a la barre de menus de PM }
  If (AltScan(Chr(Ch)) > 0) And (Pos(UpCase(Chr(Ch)), MnemoKeys) = 0) Then
   K := 256 + AltScan(Chr(Ch));
 End
 Else If (K < 0) And ((Fl And KC_CHAR) <> 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  K := Ch;
  If ((Fl And KC_CTRL) <> 0) And (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then
   K := Ord(UpCase(Chr(Ch))) - 64;
 End;
 { Ctrl + lettre sans KC_CHAR }
 If (K < 0) And ((Fl And KC_CTRL) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
  If (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then K := Ord(UpCase(Chr(Ch))) - 64;
 KeyCode := K;
End;

Procedure MenuInit(M : LongInt); Forward;
Procedure BuildMenuBar; Forward;

Procedure KeyPush(K : LongInt);
Var N : LongInt;
Begin
 N := (KeyT + 1) And 127;
 If N = KeyH Then Exit;
 KeyQ[KeyT] := K;
 KeyT := N;
End;

Procedure CmdPush(C : LongInt);
Var N : LongInt;
Begin
 N := (CmdT + 1) And 31;
 If N = CmdH Then Exit;
 CmdQ[CmdT] := C;
 CmdT := N;
End;

{ procedure de la zone client : touches (file des touches, codes du BIOS),
  souris (position, boutons ; un clic bref reste vu une fois par
  GetMouseState) et commandes des menus (file des commandes) }
Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, K, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 ClientProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    Blit(Hps, 0, CanvasTop, FbW - 1, CanvasBot);
    Dummy := WinEndPaint(Hps);
   End;
  WM_CHAR :
   Begin
    K := KeyCode(Mp1, Mp2);
    If K >= 0 Then
    Begin
     KeyPush(K);
     ClientProc := 1;
    End
    Else ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_MOUSEMOVE :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_BUTTON1DOWN, WM_BUTTON1DBLCLK, WM_BUTTON2DOWN, $0076 :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    Dummy := WinSetFocus(HWND_DESKTOP, H);
    Dummy := WinSetCapture(HWND_DESKTOP, H);
    If (Msg = WM_BUTTON1DOWN) Or (Msg = WM_BUTTON1DBLCLK) Then K := 1 Else K := 2;
    MBtn := MBtn Or K; MLatch := MLatch Or K;
    EvPush(EV_CLICK, K, EvMX, EvMY);
    ClientProc := 1;
   End;
  WM_BUTTON1UP, $0075 :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    If Msg = WM_BUTTON1UP Then MBtn := MBtn And Not 1 Else MBtn := MBtn And Not 2;
    If MBtn = 0 Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
    ClientProc := 1;
   End;
  WM_COMMAND : CmdPush(Lo16(Mp1));
  WM_INITMENU : Begin MenuUp := 1; MenuInit(Lo16(Mp1)); End;
  WM_MENUEND : MenuUp := 0;
  WM_CLOSE : CmdPush(CMD_CLOSE);
 Else
  ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

Procedure PumpMessages;
Begin
 While WinPeekMsg(OsHab, LongInt(@Qmsg), 0, 0, 0, PM_REMOVE) <> 0 Do
 Begin
  If Qmsg[1] = WM_QUIT Then CmdPush(CMD_CLOSE)
  Else Dummy := WinDispatchMsg(OsHab, LongInt(@Qmsg));
 End;
End;

{ --- Crt et souris emules --- }

Function KeyPressed : Boolean;
Begin
 FlushScreen;
 PumpMessages;
 If (KeyH = KeyT) And (PendScan < 0) Then Dummy := DosSleep(1);
 KeyPressed := (KeyH <> KeyT) Or (PendScan >= 0);
End;

{ touche etendue (code >= 256) : #0 puis le code de balayage }
Function ReadKey : Char;
Var K : LongInt;
Begin
 If PendScan >= 0 Then
 Begin
  ReadKey := Chr(PendScan);
  PendScan := -1;
  Exit;
 End;
 While KeyH = KeyT Do
 Begin
  FlushScreen;
  PumpMessages;
  If KeyH = KeyT Then Dummy := DosSleep(10);
 End;
 K := KeyQ[KeyH];
 KeyH := (KeyH + 1) And 127;
 If K >= 256 Then
 Begin
  PendScan := K - 256;
  ReadKey := #0;
 End
 Else ReadKey := Chr(K);
End;

Procedure Delay(Ms : Word);
Begin
 FlushScreen;
 PumpMessages;
 Dummy := DosSleep(Ms);
End;

Procedure GetMouseState(Var X, Y, Button : LongInt);
Begin
 FlushScreen;
 PumpMessages;
 X := EvMX; Y := EvMY;
 Button := MBtn Or MLatch;
 MLatch := 0;
End;

{ commande de la barre de menus en attente (CMD_CLOSE : fermeture) }
Function PollCmd(Var C : LongInt) : Boolean;
Begin
 PumpMessages;
 PollCmd := CmdH <> CmdT;
 If CmdH <> CmdT Then
 Begin
  C := CmdQ[CmdH];
  CmdH := (CmdH + 1) And 31;
 End;
End;

{ --- gabarit de la barre de menus (MENUTEMPLATE) --- }

Procedure MnB(V : LongInt);
Begin
 MenuT[MenuLen] := V And 255;
 Inc(MenuLen);
End;

Procedure MnW(V : LongInt);
Begin
 MnB(V And 255);
 MnB((V Shr 8) And 255);
End;

Function MnOpen : LongInt;
Begin
 MnOpen := MenuLen;
 MnW(0); MnW(0); MnW(0);
End;

Procedure MnClose(H, Count : LongInt);
Begin
 WrW(LongInt(@MenuT) + H, MenuLen - H);
 WrW(LongInt(@MenuT) + H + 4, Count);
End;

Procedure MnItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
 MnW(Style); MnW(Attr); MnW(Id);
 If (Style And MIS_SEPARATOR) = 0 Then
 Begin
  For K := 1 To Length(S) Do MnB(Ord(S[K]));
  MnB(0);
 End;
End;

Procedure MnAttr(Id, Attr : LongInt; On : Boolean);
Var V : LongInt;
Begin
 If On Then V := Attr Else V := 0;
 Dummy := WinSendMsg(OsMenu, MM_SETITEMATTR, Id Or $10000, Attr Or (V Shl 16));
End;

{ libelle de la version DOS ('&Fichier') -> libelle de PM ('~Fichier') }
Function PmLabel(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do If S[I] = '&' Then S[I] := '~';
 PmLabel := S;
End;

{ --- boites de message d'OS/2 --- }

Function PmBox(Title, Txt : String; Fl : LongInt) : LongInt;
Begin
 FlushScreen;
 PutZ(LongInt(@TxtBuf), Txt);
 PmBox := WinMessageBox(HWND_DESKTOP, OsFrame, LongInt(@TxtBuf), OsZ(Title), 0, Fl Or MB_MOVEABLE);
End;

{ titre de la fenetre (change seulement s'il differe) }
Procedure SetTitle(S : String);
Begin
 If (S = OsTitle) Or (OsFrame = 0) Then Exit;
 OsTitle := S;
 Dummy := WinSetWindowText(OsFrame, OsZ(S));
End;

{ fenetre principale : zone client de 640 x (CanvasBot + 1 - CanvasTop) }
Procedure OpenWindow(Cls, Title : String);
Var Fl, W, H, X, Y, Sw, Sh : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 OsHab := WinInitialize(0);
 OsHmq := WinCreateMsgQueue(OsHab, 64);
 Dummy := WinRegisterClass(OsHab, OsZ(Cls), LongInt(@ClientProc), 0, 0);
 Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST Or FCF_DLGBORDER;
 OsClient := 0;
 OsFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), OsZ(Cls),
   OsZ2(Title), 0, 0, 0, LongInt(@OsClient));
 OsTitle := Title;
 BuildMenuBar;
 Rc[0] := 0; Rc[1] := 0; Rc[2] := FbW; Rc[3] := CanvasBot + 1 - CanvasTop;
 Dummy := WinCalcFrameRect(OsFrame, LongInt(@Rc), 0);
 W := Rc[2] - Rc[0]; H := Rc[3] - Rc[1];
 Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
 X := (Sw - W) Div 2; Y := (Sh - H) Div 2;
 If X < 0 Then X := 0;
 { ecran trop petit : barre de titre en haut de l'ecran }
 If Y < 0 Then Y := Sh - H;
 Dummy := WinSetWindowPos(OsFrame, HWND_TOP, X, Y, W, H,
   SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
 Dummy := WinSetFocus(HWND_DESKTOP, OsClient);
End;

{ --- elements d'interface dessines dans le style d'OS/2 --- }

{ relief : clair en haut a gauche, sombre en bas a droite (ou l'inverse) }
Procedure Bevel(X1, Y1, X2, Y2 : Integer; Sunken : Boolean);
Begin
 If Sunken Then SetColor(DarkGray) Else SetColor(White);
 Line(X1, Y1, X2, Y1);
 Line(X1, Y1, X1, Y2);
 If Sunken Then SetColor(White) Else SetColor(DarkGray);
 Line(X1, Y2, X2, Y2);
 Line(X2, Y1, X2, Y2);
End;

{ rectangle pointille (focus d'OS/2) }
Procedure FocusRect(X1, Y1, X2, Y2 : Integer);
Begin
 SetLineStyle(DottedLn, 0, 1);
 SetColor(Black);
 Rectangle(X1, Y1, X2, Y2);
 SetLineStyle(SolidLn, 0, 1);
End;

{ barre de defilement verticale d'OS/2 (fleches, glissiere, curseur) }
Procedure DrawVScroll(X1, Y1, X2, Y2 : Integer; Top, N, Vis : LongInt);
Var Ty, Th, Cx, R : LongInt;
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(X1, Y1, X2, Y2);
 For Ty := Y1 + 14 To Y2 - 14 Do
  For Cx := X1 To X2 Do
   If ((Cx + Ty) And 1) = 0 Then Plot(Cx, Ty, White);
 Bar(X1, Y1, X2, Y1 + 13);
 Bevel(X1, Y1, X2, Y1 + 13, False);
 Bar(X1, Y2 - 13, X2, Y2);
 Bevel(X1, Y2 - 13, X2, Y2, False);
 Cx := (X1 + X2) Div 2;
 SetColor(Black);
 For R := 0 To 3 Do
 Begin
  Line(Cx - R, Y1 + 5 + R, Cx + R, Y1 + 5 + R);
  Line(Cx - R, Y2 - 5 - R, Cx + R, Y2 - 5 - R);
 End;
 If (N <= Vis) Or (N <= 0) Then Exit;
 Th := (Y2 - Y1 - 28) * Vis Div N;
 If Th < 12 Then Th := 12;
 Ty := Y1 + 14 + (Y2 - Y1 - 28 - Th) * Top Div (N - Vis);
 Bar(X1, Ty, X2, Ty + Th);
 Bevel(X1, Ty, X2, Ty + Th, False);
End;


{ ================================================================== }
{ Tableau periodique graphique (Presentation Manager)                }
{ ================================================================== }

Const
 CellW = 34; CellH = 28;                     { case d'un element }
 TX0 = 14; TY0 = 8;                    { coin du tableau }
 FY = 220;                             { lanthanides (actinides : +CellH) }
 PY = 284;                             { panneau du bas }
 STAT_Y = 413;
 { couleurs de la palette de l'image }
 PC_BASE = 32;                         { 32 + categorie }
 CMD_QUIT = 1; CMD_FIND = 2; CMD_NEXT = 3; CMD_PREV = 4; CMD_FIRST = 5; CMD_LAST = 6;
 CMD_TABLE = 10; CMD_LIST = 11; CMD_LEGEND = 20; CMD_ABOUT = 21;

Var
 Cur : Integer;                        { indice 0..117 de l'element choisi }
 ListMode, QuitReq : Boolean;
 LTop : Integer;
 CellX, CellY : Array[0..117] Of Integer;
 StatusMsg : String;

Function CatName(C : Integer) : String;
Begin
 Case C Of
  0 : CatName := 'Non class'#130's';
  1 : CatName := 'Alcalins';
  2 : CatName := 'Alcalino-terreux';
  3 : CatName := 'Lanthanides';
  4 : CatName := 'Actinides';
  5 : CatName := 'M'#130'taux de transition';
  6 : CatName := 'M'#130'taux pauvres';
  7 : CatName := 'M'#130'tallo'#139'des';
  8 : CatName := 'Autres non-m'#130'taux';
  9 : CatName := 'Halog'#138'nes';
 Else CatName := 'Gaz nobles';
 End;
End;

Function ShortCat(C : Integer) : String;
Begin
 Case C Of
  2 : ShortCat := 'Alc.-terreux';
  5 : ShortCat := 'Transition';
  6 : ShortCat := 'M'#130't. pauvres';
  8 : ShortCat := 'Non-m'#130'taux';
 Else ShortCat := CatName(C);
 End;
End;

Function EtatName(E : Integer) : String;
Begin
 Case E Of
  0 : EtatName := 'Gaz';
  1 : EtatName := 'Liquide';
 Else EtatName := 'Solide';
 End;
End;

Function EtatCol(E : Integer) : Integer;
Begin
 Case E Of
  0 : EtatCol := Red;
  1 : EtatCol := Blue;
 Else EtatCol := Black;
 End;
End;

Function CatOf(I : Integer) : Integer;
Begin
 CatOf := Ord(ElementsChimiques[I].Categorie);
End;

Function MassStr(I, D : Integer) : String;
Var S : String;
Begin
 Str(ElementsChimiques[I].MasseAtomique : 1 : D, S);
 MassStr := S;
End;

Function IStr(N : LongInt) : String;
Var S : String;
Begin
 Str(N, S);
 IStr := S;
End;

{ position de chaque element : groupe et periode ; lanthanides (57-71) et
  actinides (89-103) sur deux lignes sous le tableau }
Procedure Layout;
Var I, N : Integer;
Begin
 For I := 0 To 117 Do Begin
  N := ElementsChimiques[I].NumeroAtomique;
  If (N >= 57) And (N <= 71) Then Begin
   CellX[I] := TX0 + (N - 57 + 2) * CellW; CellY[I] := FY;
  End Else If (N >= 89) And (N <= 103) Then Begin
   CellX[I] := TX0 + (N - 89 + 2) * CellW; CellY[I] := FY + CellH;
  End Else Begin
   CellX[I] := TX0 + (ElementsChimiques[I].Groupe - 1) * CellW;
   CellY[I] := TY0 + (ElementsChimiques[I].Periode - 1) * CellH;
  End;
 End;
End;

Procedure InitPalette;
Begin
 SetPalEntry(PC_BASE + 0, $E4E4E4);    { non classes }
 SetPalEntry(PC_BASE + 1, $FF7B7B);    { alcalins }
 SetPalEntry(PC_BASE + 2, $FFD69C);    { alcalino-terreux }
 SetPalEntry(PC_BASE + 3, $FFB8F0);    { lanthanides }
 SetPalEntry(PC_BASE + 4, $F59AC8);    { actinides }
 SetPalEntry(PC_BASE + 5, $FFC8C8);    { metaux de transition }
 SetPalEntry(PC_BASE + 6, $CCD2DC);    { metaux pauvres }
 SetPalEntry(PC_BASE + 7, $D6D69A);    { metalloides }
 SetPalEntry(PC_BASE + 8, $A6F0A6);    { autres non-metaux }
 SetPalEntry(PC_BASE + 9, $FFFF96);    { halogenes }
 SetPalEntry(PC_BASE + 10, $B4EEFF);   { gaz nobles }
End;

Procedure Cell(I : Integer; Sel : Boolean);
Var X, Y : Integer; S : String;
Begin
 X := CellX[I]; Y := CellY[I];
 SetFillStyle(SolidFill, PC_BASE + CatOf(I));
 Bar(X, Y, X + CellW - 2, Y + CellH - 2);
 SetColor(DarkGray);
 Rectangle(X, Y, X + CellW - 2, Y + CellH - 2);
 SetColor(Black);
 OutTextXY(X + 2, Y + 2, IStr(ElementsChimiques[I].NumeroAtomique));
 S := ElementsChimiques[I].SymboleChimique;
 SetColor(EtatCol(Ord(ElementsChimiques[I].Etat)));
 OutTextXY(X + (CellW - 2 - Length(S) * 8) Div 2 + 1, Y + 14, S);
 OutTextXY(X + (CellW - 2 - Length(S) * 8) Div 2, Y + 14, S);
 If Sel Then Begin
  SetColor(Blue);
  Rectangle(X - 1, Y - 1, X + CellW - 1, Y + CellH - 1);
  Rectangle(X - 2, Y - 2, X + CellW, Y + CellH);
 End;
End;

{ renvoi des lanthanides et des actinides dans le tableau }
Procedure Placeholders;
Var X : Integer;
Begin
 X := TX0 + 2 * CellW;
 SetFillStyle(SolidFill, PC_BASE + 3);
 Bar(X, TY0 + 5 * CellH, X + CellW - 2, TY0 + 6 * CellH - 2);
 SetFillStyle(SolidFill, PC_BASE + 4);
 Bar(X, TY0 + 6 * CellH, X + CellW - 2, TY0 + 7 * CellH - 2);
 SetColor(DarkGray);
 Rectangle(X, TY0 + 5 * CellH, X + CellW - 2, TY0 + 6 * CellH - 2);
 Rectangle(X, TY0 + 6 * CellH, X + CellW - 2, TY0 + 7 * CellH - 2);
 SetColor(Black);
 OutTextXY(X + 1, TY0 + 5 * CellH + 4, '57-');
 OutTextXY(X + 9, TY0 + 5 * CellH + 14, '71');
 OutTextXY(X + 1, TY0 + 6 * CellH + 4, '89-');
 OutTextXY(X + 1, TY0 + 6 * CellH + 14, '103');
 { numeros des groupes et des periodes }
 SetColor(DarkGray);
 For X := 1 To 7 Do OutTextXY(4, TY0 + (X - 1) * CellH + 10, IStr(X));
End;

Procedure DrawStatus;
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(0, STAT_Y, 639, 430);
 Bevel(2, STAT_Y + 2, 637, 429, True);
 SetColor(Black);
 If StatusMsg <> '' Then OutTextXY(8, STAT_Y + 6, StatusMsg)
 Else If ListMode Then
  OutTextXY(8, STAT_Y + 6, 'Haut, Bas, Pg.pr'#130'c., Pg.suiv. : choisir   F3 : rechercher   F5 : tableau')
 Else
  OutTextXY(8, STAT_Y + 6, 'Fl'#138'ches ou clic : choisir   F3 : rechercher   F5 : liste des '#130'l'#130'ments');
End;

{ panneau du bas : fiche de l'element et legende }
Procedure DrawPanel;
Var I, Y, X : Integer; S : String;
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(0, PY - 6, 639, STAT_Y - 1);
 SetColor(DarkGray);
 Line(0, PY - 6, 639, PY - 6);
 SetColor(White);
 Line(0, PY - 5, 639, PY - 5);
 { fiche }
 Bevel(8, PY, 398, STAT_Y - 6, True);
 SetFillStyle(SolidFill, White);
 Bar(9, PY + 1, 397, STAT_Y - 7);
 I := Cur;
 SetFillStyle(SolidFill, PC_BASE + CatOf(I));
 Bar(18, PY + 12, 108, PY + 112);
 SetColor(Black);
 Rectangle(18, PY + 12, 108, PY + 112);
 OutTextXY(24, PY + 18, IStr(ElementsChimiques[I].NumeroAtomique));
 S := ElementsChimiques[I].SymboleChimique;
 SetTextStyle(DefaultFont, HorizDir, 4);
 SetColor(EtatCol(Ord(ElementsChimiques[I].Etat)));
 OutTextXY(63 - Length(S) * 16, PY + 46, S);
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(Black);
 OutTextXY(24, PY + 98, MassStr(I, 3));
 X := 122; Y := PY + 12;
 SetColor(Blue);
 SetTextStyle(DefaultFont, HorizDir, 2);
 OutTextXY(X, Y, Copy(ElementsChimiques[I].ElementName, 1, 16));
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(Black);
 Y := Y + 24;
 OutTextXY(X, Y, 'Num'#130'ro atomique : ' + IStr(ElementsChimiques[I].NumeroAtomique)); Y := Y + 12;
 OutTextXY(X, Y, 'Symbole chimique : ' + ElementsChimiques[I].SymboleChimique); Y := Y + 12;
 OutTextXY(X, Y, 'Masse atomique : ' + MassStr(I, 4)); Y := Y + 12;
 OutTextXY(X, Y, 'Groupe ' + IStr(ElementsChimiques[I].Groupe) + ', p'#130'riode ' +
           IStr(ElementsChimiques[I].Periode)); Y := Y + 12;
 OutTextXY(X, Y, 'Cat'#130'gorie : ' + CatName(CatOf(I))); Y := Y + 12;
 OutTextXY(X, Y, #144'tat (0 '#248'C, 101,3 kPa) : ');
 SetColor(EtatCol(Ord(ElementsChimiques[I].Etat)));
 OutTextXY(X + 28 * 8, Y, EtatName(Ord(ElementsChimiques[I].Etat)));
 { legende }
 Bevel(406, PY, 632, STAT_Y - 6, True);
 SetColor(Black);
 For I := 0 To 10 Do Begin
  X := 414 + (I Div 6) * 112; Y := PY + 8 + (I Mod 6) * 13;
  SetFillStyle(SolidFill, PC_BASE + I);
  Bar(X, Y, X + 9, Y + 9);
  SetColor(DarkGray); Rectangle(X, Y, X + 9, Y + 9);
  SetColor(Black);
  OutTextXY(X + 14, Y + 1, ShortCat(I));
 End;
 Y := PY + 90;
 SetColor(Black); OutTextXY(414, Y, 'Solide');
 SetColor(Blue); OutTextXY(478, Y, 'Liquide');
 SetColor(Red); OutTextXY(550, Y, 'Gaz');
End;

Procedure DrawTable;
Var I : Integer;
Begin
 SetFillStyle(SolidFill, White);
 Bar(0, 0, 639, PY - 7);
 Placeholders;
 For I := 0 To 117 Do Cell(I, False);
 Cell(Cur, True);
End;

{ liste des elements (la vue /GUI de la version DOS) }
Const
 LVIS = 21;

Procedure DrawList;
Var I, Y, K : Integer; S : String;
Begin
 SetFillStyle(SolidFill, White);
 Bar(0, 0, 639, PY - 7);
 SetFillStyle(SolidFill, LightGray);
 Bar(4, 4, 620, 16);
 Bevel(4, 4, 620, 16, False);
 SetColor(Black);
 OutTextXY(10, 7, 'N'#248'   Symbole  Nom                   Masse     Cat'#130'gorie');
 If Cur < LTop Then LTop := Cur;
 If Cur >= LTop + LVIS Then LTop := Cur - LVIS + 1;
 For K := 0 To LVIS - 1 Do Begin
  I := LTop + K;
  If I > 117 Then Break;
  Y := 20 + K * 12;
  If I = Cur Then Begin
   SetFillStyle(SolidFill, Blue);
   Bar(4, Y - 1, 620, Y + 9);
   SetColor(White);
  End Else Begin
   SetFillStyle(SolidFill, PC_BASE + CatOf(I));
   Bar(4, Y - 1, 12, Y + 9);
   SetColor(Black);
  End;
  S := IStr(ElementsChimiques[I].NumeroAtomique);
  While Length(S) < 4 Do S := S + ' ';
  S := ' ' + S + PadRight(ElementsChimiques[I].SymboleChimique, 9) +
       PadRight(ElementsChimiques[I].ElementName, 22) + PadRight(MassStr(I, 4), 10) + CatName(CatOf(I));
  OutTextXY(14, Y, S);
 End;
 DrawVScroll(623, 4, 637, PY - 10, LTop, 118, LVIS);
End;

Procedure Redraw;
Begin
 If ListMode Then DrawList Else DrawTable;
 DrawPanel;
 DrawStatus;
End;

{ element voisin dans le tableau (fleches) }
Function Neighbour(Dx, Dy : Integer) : Integer;
Var I, Best, X, Y, D, BD : Integer;
Begin
 Best := Cur; BD := 32000;
 X := CellX[Cur] + Dx * CellW; Y := CellY[Cur] + Dy * CellH;
 For I := 0 To 117 Do
  If I <> Cur Then Begin
   If (Dx <> 0) And ((CellY[I] <> CellY[Cur]) Or ((CellX[I] - CellX[Cur]) * Dx <= 0)) Then Continue;
   If (Dy <> 0) And ((CellY[I] - CellY[Cur]) * Dy <= 0) Then Continue;
   D := Abs(CellX[I] - X) + Abs(CellY[I] - Y) * 2;
   If D < BD Then Begin BD := D; Best := I; End;
  End;
 Neighbour := Best;
End;

{ saisie d'un texte dans une boite de dialogue d'OS/2 }
{ ================================================================== }
{ OS/2-0 : BOITES DE DIALOGUE NATIVES DE PRESENTATION MANAGER         }
{ ================================================================== }
{ La version DOS dessinait elle-meme ses boites (cadre, champ de      }
{ saisie, boutons, barres de defilement) et lisait clavier et souris  }
{ dans sa propre boucle. Ici ce sont de vraies fenetres de PM :       }
{  - saisie : boite modale avec un champ de saisie (WC_ENTRYFIELD) et }
{    les boutons OK / Annuler (WC_BUTTON) ;                           }
{  - resultats : fenetre modale dont le texte defile avec deux barres }
{    de defilement de PM (WC_SCROLLBAR), boutons Enregistrer et       }
{    Fermer ;                                                         }
{  - messages et questions : WinMessageBox.                           }
{ Pendant une boite modale, la fenetre qui l'a ouverte est desactivee }
{ (WinEnableWindow) et les messages sont distribues par WinGetMsg.    }

Const
 WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006;
 WC_LISTBOX = $FFFF0007; WC_SCROLLBAR = $FFFF0008;
 WS_VISIBLE = $80000000; WS_TABSTOP = $00020000; WS_GROUP = $00010000;
 BS_PUSHBUTTON = 0; BS_DEFAULT = $0400;
 ES_AUTOSCROLL = 4; ES_MARGIN = 8;
 SBS_HORZ = 0; SBS_VERT = 1;
 EM_SETTEXTLIMIT = $0143; EM_SETSEL = $0142;
 SBM_SETSCROLLBAR = $01A0; SBM_SETPOS = $01A1; SBM_SETTHUMBSIZE = $01A6;
 LM_QUERYITEMCOUNT = $0160; LM_INSERTITEM = $0161; LM_SETTOPINDEX = $0162;
 LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165; LM_QUERYTOPINDEX = $016D;
 LM_DELETEALL = $016E;
 LN_SELECT = 1; LN_ENTER = 5;
 WM_CREATE = $0001; WM_CONTROL = $0030; WM_VSCROLL = $0031; WM_HSCROLL = $0032;
 SB_LINEUP = 1; SB_LINEDOWN = 2; SB_PAGEUP = 3; SB_PAGEDOWN = 4;
 SB_SLIDERTRACK = 5; SB_SLIDERPOSITION = 6;
 CLR_PMWHITE = -2; CLR_PMBLACK = -1; CLR_PMBLUE = 1; CLR_PMDARKBLUE = 9;
 CLR_PALEGRAY = 15;
 ID_POK = 1; ID_PCANCEL = 2; ID_PSAVE = 3; ID_PEF = 20; ID_PVSB = 21; ID_PHSB = 22;
 PmChW = 8; PmChH = 16;

Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';

Var
 PmTopFr : LongInt;                       { fenetre qui recoit la saisie }
 PmLevel : LongInt;                       { profondeur des boites modales }
 PmEnd : Array[0..7] Of LongInt;          { 0 : ouverte, 1 : OK, 2 : annulee }
 PmClsDone, RsClsDone : Boolean;
 { boite de saisie }
 InFr, InCl, InEf : LongInt;
 InP1, InP2, InVal : String;
 InMax : LongInt;
 { fenetre des resultats }
 RsFr, RsCl, RsVsb, RsHsb : LongInt;
 RsTop, RsLeft, RsRows, RsCols, RsMaxLen : LongInt;

Function PmLo(V : LongInt) : LongInt;
Begin
 PmLo := V And $FFFF;
End;

Function PmHi(V : LongInt) : LongInt;
Begin
 PmHi := (V Shr 16) And $FFFF;
End;

Function PmS16(V : LongInt) : LongInt;
Begin
 V := V And $FFFF;
 If V >= $8000 Then V := V - $10000;
 PmS16 := V;
End;

{ texte d'une ligne dans une zone de dessin (Y compte depuis le haut) }
Procedure PmText(Hps, Hh, X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
 If S = '' Then Exit;
 PutZ(LongInt(@TxtBuf), S);
 Rc[0] := X; Rc[1] := Hh - Y - PmChH; Rc[2] := X + Length(S) * PmChW; Rc[3] := Hh - Y;
 Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ cadre de fenetre de dialogue de la taille de zone client W x H, centre
  sur la fenetre principale }
Function PmOpenBox(Cls, Title : String; W, H : LongInt; Var Cl : LongInt) : LongInt;
Var Fl, Fr, Sw, Sh, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
 Cl := 0;
 Fr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), OsZ(Cls), OsZ2(Title), 0, 0, 0, LongInt(@Cl));
 If Fr <> 0 Then
 Begin
  Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
  Dummy := WinCalcFrameRect(Fr, LongInt(@Rc), 0);
  W := Rc[2] - Rc[0]; H := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - W) Div 2; Y := (Sh - H) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := 0;
  Dummy := WinSetWindowPos(Fr, HWND_TOP, X, Y, W, H,
    SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Fr);
 End;
 PmOpenBox := Fr;
End;

{ boucle modale : la fenetre Fr recoit la saisie jusqu'a PmEnd[niveau] }
Function PmModal(Fr, Focus, Ef : LongInt) : LongInt;
Var Prev, Lv, N : LongInt; Buf : Array[0..259] Of Byte;
Begin
 FlushScreen;
 If PmTopFr = 0 Then PmTopFr := OsFrame;
 Prev := PmTopFr;
 Inc(PmLevel); Lv := PmLevel;
 PmEnd[Lv] := 0;
 { la fenetre qui avait la souris (clic en cours) la rend }
 Dummy := WinSetCapture(HWND_DESKTOP, 0);
 MBtn := 0; MLatch := 0;
 Dummy := WinEnableWindow(Prev, 0);
 PmTopFr := Fr;
 If Focus <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Focus);
 While PmEnd[Lv] = 0 Do
 Begin
  If WinGetMsg(OsHab, LongInt(@Qmsg), 0, 0, 0) = 0 Then
  Begin
   CmdPush(CMD_CLOSE);
   PmEnd[Lv] := 2;
  End
  Else Dummy := WinDispatchMsg(OsHab, LongInt(@Qmsg));
 End;
 PmModal := PmEnd[Lv];
 { texte du champ de saisie, lu avant la destruction de la boite }
 If (Ef <> 0) And (PmEnd[Lv] = 1) Then
 Begin
  N := WinQueryWindowText(Ef, 252, LongInt(@Buf));
  If N < 0 Then N := 0;
  InVal := '';
  While (Length(InVal) < N) And (Buf[Length(InVal)] <> 0) Do InVal := InVal + Chr(Buf[Length(InVal)]);
 End;
 Dec(PmLevel);
 Dummy := WinEnableWindow(Prev, 1);
 PmTopFr := Prev;
 { la fenetre d'origine redevient active (barre de titre) avant que la
   boite disparaisse }
 Dummy := WinSetActiveWindow(HWND_DESKTOP, Prev);
 If Prev = OsFrame Then Dummy := WinSetFocus(HWND_DESKTOP, OsClient);
 Dummy := WinDestroyWindow(Fr);
End;

Procedure PmDone(V : LongInt);
Begin
 If PmLevel > 0 Then PmEnd[PmLevel] := V;
End;

{ Entree et Echap remontes par les controles de la boite }
Function PmDlgKey(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk : LongInt;
Begin
 Fl := PmLo(Mp1); Vk := PmHi(Mp2);
 PmDlgKey := 1;
 If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And
    ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then PmDone(1)
 Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then PmDone(2)
 Else PmDlgKey := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

{ --- boite de saisie --- }

Function InputProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, W, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 InputProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, 0);
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
    Y := 8;
    PmText(Hps, Rc[3], 12, Y, InP1, CLR_PMBLACK, CLR_PALEGRAY);
    If InP2 <> '' Then PmText(Hps, Rc[3], 12, Y + PmChH, InP2, CLR_PMBLACK, CLR_PALEGRAY);
    Dummy := WinEndPaint(Hps);
   End;
  WM_COMMAND :
   If PmLo(Mp1) = ID_POK Then PmDone(1) Else If PmLo(Mp1) = ID_PCANCEL Then PmDone(2);
  WM_CHAR : InputProc := PmDlgKey(H, Msg, Mp1, Mp2);
  WM_CLOSE : PmDone(2);
 Else
  InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

{ controles de la boite de saisie (zone client W de large) }
Procedure InControls(H, W : LongInt);
Begin
 InEf := WinCreateWindow(H, WC_ENTRYFIELD, 0, WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
   12, 44, W - 24, 20, H, HWND_TOP, ID_PEF, 0, 0);
 Dummy := WinSendMsg(InEf, EM_SETTEXTLIMIT, InMax, 0);
 Dummy := WinCreateWindow(H, WC_BUTTON, OsZ('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
   W - 196, 8, 88, 26, H, HWND_TOP, ID_POK, 0, 0);
 Dummy := WinCreateWindow(H, WC_BUTTON, OsZ('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
   W - 100, 8, 88, 26, H, HWND_TOP, ID_PCANCEL, 0, 0);
End;

Procedure PmRegister;
Begin
 If PmClsDone Then Exit;
 PmClsDone := True;
 Dummy := WinRegisterClass(OsHab, OsZ('ASTROIN'), LongInt(@InputProc), 0, 0);
End;

{ coupe un texte trop long en deux lignes (a un espace) }
Procedure PmSplit(S : String; Max : LongInt; Var A, B : String);
Var K : LongInt;
Begin
 A := S; B := '';
 If Length(S) <= Max Then Exit;
 K := Max;
 While (K > 1) And (S[K] <> ' ') Do Dec(K);
 If K <= 1 Then K := Max;
 A := Copy(S, 1, K);
 B := Copy(S, K + 1, 255);
 While (B <> '') And (B[1] = ' ') Do Delete(B, 1, 1);
 If Length(B) > Max Then B := Copy(B, 1, Max);
End;

Function PmInput(Title, Prompt : String; Var S : String; MaxLen : LongInt) : Boolean;
Var W, H, L, R : LongInt;
Begin
 PmRegister;
 PmSplit(Prompt, 70, InP1, InP2);
 L := Length(InP1);
 If Length(InP2) > L Then L := Length(InP2);
 W := L * PmChW + 24;
 If W < 380 Then W := 380;
 If W < Length(Title) * PmChW + 80 Then W := Length(Title) * PmChW + 80;
 If W > 600 Then W := 600;
 H := 96;
 If InP2 <> '' Then H := H + PmChH;
 If MaxLen < 1 Then MaxLen := 1;
 If MaxLen > 250 Then MaxLen := 250;
 InMax := MaxLen;
 InFr := PmOpenBox('ASTROIN', Title, W, H, InCl);
 If InFr = 0 Then
 Begin
  PmInput := False;
  Exit;
 End;
 InControls(InCl, W);
 Dummy := WinSetWindowText(InEf, OsZ(S));
 Dummy := WinSendMsg(InEf, EM_SETSEL, Length(S) Shl 16, 0);
 R := PmModal(InFr, InEf, InEf);
 If R = 1 Then S := InVal;
 PmInput := R = 1;
End;


Function InputDlg(Title, Prompt : String; Var S : String) : Boolean;
{ boite de dialogue de PM : champ de saisie, boutons OK et Annuler }
Begin
 InputDlg := PmInput(Title, Prompt, S, 250);
End;

{ recherche par nom (debut du nom, sans accents), symbole ou numero }
Function FindElement(Q : String) : Integer;
Var I, N, E : Integer; U : String;

 Function Plain(S : String) : String;
 Var K : Integer;
 Begin
  For K := 1 To Length(S) Do
   Case S[K] Of
    #130, #136, #137, #138 : S[K] := 'E';
    #131, #132, #133 : S[K] := 'A';
    #139, #140 : S[K] := 'I';
    #147, #148 : S[K] := 'O';
    #150, #151, #129 : S[K] := 'U';
    #135 : S[K] := 'C';
   End;
  Plain := StrToUpper(S);
 End;

Begin
 FindElement := -1;
 U := Plain(Q);
 If U = '' Then Exit;
 Val(U, N, E);
 For I := 0 To 117 Do Begin
  If (E = 0) And (ElementsChimiques[I].NumeroAtomique = N) Then Begin FindElement := I; Exit; End;
  If StrToUpper(ElementsChimiques[I].SymboleChimique) = U Then Begin FindElement := I; Exit; End;
 End;
 For I := 0 To 117 Do
  If Copy(Plain(ElementsChimiques[I].ElementName), 1, Length(U)) = U Then Begin
   FindElement := I; Exit;
  End;
End;

Procedure DoFind;
Var Q : String; I : Integer;
Begin
 Q := '';
 If InputDlg('Rechercher un '#130'l'#130'ment', 'Nom, symbole ou num'#130'ro atomique :', Q) Then Begin
  I := FindElement(Q);
  If I >= 0 Then Begin Cur := I; StatusMsg := ''; End
  Else StatusMsg := #144'l'#130'ment introuvable : ' + Q;
 End;
End;

{ barre de menus de PM }
Procedure BuildMenuBar;
Var H0, H1 : LongInt;
Begin
 MenuLen := 0;
 MnemoKeys := 'F'#144'AI';
 H0 := MnOpen;
 MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 901, '~Fichier');
 H1 := MnOpen;
 MnItem(MIS_TEXT, 0, 100 + CMD_QUIT, 'Quitter'#9'Alt+X');
 MnClose(H1, 1);
 MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 902, '~'#144'l'#130'ment');
 H1 := MnOpen;
 MnItem(MIS_TEXT, 0, 100 + CMD_FIND, 'Rechercher...'#9'F3');
 MnItem(MIS_SEPARATOR, 0, 801, '');
 MnItem(MIS_TEXT, 0, 100 + CMD_PREV, 'Pr'#130'c'#130'dent (num'#130'ro)'#9'-');
 MnItem(MIS_TEXT, 0, 100 + CMD_NEXT, 'Suivant (num'#130'ro)'#9'+');
 MnItem(MIS_TEXT, 0, 100 + CMD_FIRST, 'Premier (hydrog'#138'ne)'#9'D'#130'but');
 MnItem(MIS_TEXT, 0, 100 + CMD_LAST, 'Dernier (oganesson)'#9'Fin');
 MnClose(H1, 6);
 MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 903, '~Affichage');
 H1 := MnOpen;
 MnItem(MIS_TEXT, 0, 100 + CMD_TABLE, 'Tableau p'#130'riodique'#9'F5');
 MnItem(MIS_TEXT, 0, 100 + CMD_LIST, 'Liste des '#130'l'#130'ments'#9'F6');
 MnClose(H1, 2);
 MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 904, 'A~ide');
 H1 := MnOpen;
 MnItem(MIS_TEXT, 0, 100 + CMD_LEGEND, 'Couleurs du tableau'#9'F1');
 MnItem(MIS_TEXT, 0, 100 + CMD_ABOUT, 'A propos de la Table des '#130'l'#130'ments');
 MnClose(H1, 2);
 MnClose(H0, 4);
 OsMenu := WinCreateMenu(OsFrame, LongInt(@MenuT));
 MnemoKeys := 'FEAI';
End;

Procedure MenuInit(M : LongInt);
Begin
 If M = 903 Then Begin
  MnAttr(100 + CMD_TABLE, MIA_CHECKED, Not ListMode);
  MnAttr(100 + CMD_LIST, MIA_CHECKED, ListMode);
 End;
End;

Function ByNumber(N : Integer) : Integer;
Var I : Integer;
Begin
 ByNumber := Cur;
 For I := 0 To 117 Do If ElementsChimiques[I].NumeroAtomique = N Then ByNumber := I;
End;

Procedure DoCmd(C : Integer);
Begin
 StatusMsg := '';
 Case C Of
  CMD_QUIT : QuitReq := True;
  CMD_FIND : DoFind;
  CMD_NEXT : If ElementsChimiques[Cur].NumeroAtomique < 118 Then
              Cur := ByNumber(ElementsChimiques[Cur].NumeroAtomique + 1);
  CMD_PREV : If ElementsChimiques[Cur].NumeroAtomique > 1 Then
              Cur := ByNumber(ElementsChimiques[Cur].NumeroAtomique - 1);
  CMD_FIRST : Cur := ByNumber(1);
  CMD_LAST : Cur := ByNumber(118);
  CMD_TABLE : ListMode := False;
  CMD_LIST : ListMode := True;
  CMD_LEGEND : Dummy := PmBox('Table des '#130'l'#130'ments',
   'La couleur de chaque case indique la cat'#130'gorie de l'''#130'l'#130'ment (l'#130'gende '+
   'en bas '#133' droite) ; la couleur du symbole, son '#130'tat '#133' 0 '#248'C et 101,3 kPa : noir '+
   'pour un solide, bleu pour un liquide, rouge pour un gaz. Lanthanides et actinides sont '+
   'sous le tableau.', MB_OK Or MB_INFORMATION);
  CMD_ABOUT : Dummy := PmBox('Table des '#130'l'#130'ments',
   'Table des '#130'l'#130'ments (ELEMENTS) : tableau p'#130'riodique des 118 '#130'l'#130'ments chimiques. '+
   'Port'#130' du d'#130'p'#244't QCHIMIE pour OS/2-0. https://www.gladir.com/qchimie',
   MB_OK Or MB_INFORMATION);
 End;
End;

Procedure Click(X, Y : LongInt);
Var I : Integer;
Begin
 If ListMode Then Begin
  If (Y >= 20) And (Y < 20 + LVIS * 12) And (X < 620) Then Begin
   I := LTop + (Y - 20) Div 12;
   If I <= 117 Then Cur := I;
  End Else If X >= 620 Then Begin
   If Y < PY Div 2 Then LTop := LTop - LVIS Else LTop := LTop + LVIS;
   If LTop > 118 - LVIS Then LTop := 118 - LVIS;
   If LTop < 0 Then LTop := 0;
   If Cur < LTop Then Cur := LTop;
   If Cur >= LTop + LVIS Then Cur := LTop + LVIS - 1;
  End;
  Exit;
 End;
 For I := 0 To 117 Do
  If (X >= CellX[I]) And (X < CellX[I] + CellW - 1) And (Y >= CellY[I]) And (Y < CellY[I] + CellH - 1) Then
   Cur := I;
End;

Var
 Ch : Char;
 C, Mx, My, Mb, PrevB : LongInt;
 Q : String;

BEGIN
 If (ParamStr(1) = '/?') Or (ParamStr(1) = '--help') Or (ParamStr(1) = '-h') Or
    (ParamStr(1) = '/h') Or (ParamStr(1) = '/H') Then Begin
  WriteLn('ELEMENTS : Cette commande permet d''afficher le tableau periodique des elements chimiques.');
  WriteLn;
  WriteLn('Syntaxe : ELEMENTS [nomelement | symbole | numero] [/LIST]');
  Halt;
 End;
 Layout;
 Cur := 0; LTop := 0; ListMode := False; QuitReq := False; StatusMsg := '';
 For I := 1 To ParamCount Do Begin
  Q := ParamStr(I);
  If (StrToUpper(Q) = '/LIST') Or (StrToUpper(Q) = '/GUI') Then ListMode := True
  Else If FindElement(Q) >= 0 Then Cur := FindElement(Q);
 End;
 InitBmi;
 InitPalette;
 OsFrame := 0; OsClient := 0;
 OpenWindow('ELEMENTS', 'Table des '#130'l'#130'ments');
 PrevB := 0;
 Redraw;
 Repeat
  While KeyPressed Do Begin
   Ch := ReadKey;
   StatusMsg := '';
   If Ch = #0 Then Begin
    Ch := ReadKey;
    Case Ord(Ch) Of
     45 : QuitReq := True;
     59 : DoCmd(CMD_LEGEND);
     61 : DoCmd(CMD_FIND);
     63 : DoCmd(CMD_TABLE);
     64 : DoCmd(CMD_LIST);
     71 : DoCmd(CMD_FIRST);
     79 : DoCmd(CMD_LAST);
     72 : If ListMode Then DoCmd(CMD_PREV) Else Cur := Neighbour(0, -1);
     80 : If ListMode Then DoCmd(CMD_NEXT) Else Cur := Neighbour(0, 1);
     75 : If ListMode Then DoCmd(CMD_PREV) Else Cur := Neighbour(-1, 0);
     77 : If ListMode Then DoCmd(CMD_NEXT) Else Cur := Neighbour(1, 0);
     73 : If ListMode Then Begin Cur := Cur - LVIS; If Cur < 0 Then Cur := 0; End;
     81 : If ListMode Then Begin Cur := Cur + LVIS; If Cur > 117 Then Cur := 117; End;
    End;
   End Else Case Ch Of
    '+', '=' : DoCmd(CMD_NEXT);
    '-' : DoCmd(CMD_PREV);
    #13 : ListMode := Not ListMode;
   End;
   Redraw;
  End;
  While PollCmd(C) Do Begin
   If C = CMD_CLOSE Then QuitReq := True
   Else If (C > 100) And (C < 200) Then DoCmd(C - 100);
   Redraw;
  End;
  GetMouseState(Mx, My, Mb);
  If ((Mb And 1) <> 0) And ((PrevB And 1) = 0) Then Begin
   Click(Mx, My);
   Redraw;
  End;
  PrevB := Mb;
  Delay(10);
 Until QuitReq;
 Dummy := WinDestroyWindow(OsFrame);
END.
