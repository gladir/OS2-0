{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/mystix)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Onirologie (interpreteur de reves) : editeur de recit,
                analyse des symboles et des emotions, graphiques,
                classification, archetypes, sens du reve et journal des
                reves, pour le Presentation Manager d'OS/2-0 (dossier
                Loisirs).
}

Program REVES;

{ Compilation : OS2PC REVES.PAS   (produit REVES.EXE)

  Portage vers OS/2-0 de REVES.PAS du depot Mystix (Turbo Pascal 7,
  Free Pascal : BGI 640 x 480 en 16 couleurs, souris de l'interruption
  33h). Tout le moteur est conserve tel quel : editeur du recit (accents
  par Tab), dictionnaire integre des symboles et des mots-cles, analyse
  (symboles, emotions, tonalite, themes, domaines, classification,
  archetypes, sens du reve), rapport, journal des reves (REVES.JNL),
  importation et exportation de textes, cinq langues (LANGUAGE=FR, EN,
  DE, ES, IT).

  Ce qui change pour OS/2 :
  - fenetre de Presentation Manager : barre de titre (titre du reve),
    menu systeme, barre de menus d'OS/2 construite a partir des tables
    de menus d'origine (Surligner : choix coche) ;
  - editeur, pages de texte et graphiques sur fond blanc (couleurs
    foncees), barre d'information et barre d'etat grises, boites de
    dialogue, boutons, zones de saisie et barres de defilement dans le
    style d'OS/2 ;
  - messages et questions par WinMessageBox ;
  - la page d'accueil garde son ciel etoile. }

{ ================================================================== }
{ Donnees integrees : dictionnaire des symboles (noms, categories,    }
{ domaines, polarites, archetypes, sens), lexique multilingue des     }
{ mots-cles et des emotions, textes d'interpretation, recits          }
{ d'exemple et messages de l'interface en 5 langues.                  }
{ ================================================================== }

Const
 NHELP = 7;
 B_SMEAN = 1;
 B_SPOS = 443;
 B_SNEG = 885;
 B_TONE = 1327;
 B_EMOS = 1332;
 B_CATS = 1341;
 B_CATA = 1359;
 B_DOMS = 1377;
 B_TYPD = 1385;
 B_TYPS = 1397;
 B_ARCD = 1409;
 B_EVOL = 1419;
 B_MOOD = 1424;
 B_CONCL = 1427;
 B_NOSYM = 1428;
 B_HELP = 1429;
 NTX = 3872;
 NBLK = 1463;
 { 3872 chaines de TXL regroupees dans des reservoirs de 200 caracteres
   (separateur '|') : voir TxlStr }
 TXLP : Array[1..1200] Of String[255] = (
  'L''eau figure l''inconscient, les Çmotions et la vie qui circule ;|Jung y voyait l''image màme de la psychÇ profonde. Son aspect,|limpide ou trouble, refläte l''Çtat de votre monde intÇrieur.|',
  'Immense et insondable, la mer symbolise l''inconscient collectif,|la märe originelle et l''infini des possibles. Elle Çvoque Ö la|fois l''attrait du lointain, l''abandon de soi et le mouvement|',
  'perpÇtuel de la vie.|La vague traduit le flux des Çmotions et les cycles de la vie : ce|qui monte finit par redescendre. Elle peut annoncer un changement|',
  'qui approche ou un sentiment qui grandit en vous et demande Ö àtre|accueilli.|La riviäre reprÇsente le cours de l''existence et l''Çcoulement du|',
  'temps. Selon son dÇbit, elle montre comment votre vie avance ;|traverser une riviäre marque souvent le passage d''une Çtape Ö une|autre.|Le lac, eau dormante et close, Çvoque la profondeur de l''Éme et|',
  'l''introspection. Miroir naturel, il invite Ö vous regarder en|face ; dans les lÇgendes, il garde des secrets et des trÇsors|enfouis.|La pluie symbolise la purification et la fÇcondation : elle lave,|',
  'apaise et fait germer. Elle peut aussi traduire des larmes|retenues, une mÇlancolie passagäre qui prÇcäde souvent un|renouveau.|L''inondation traduit un trop-plein Çmotionnel : des sentiments|',
  'longtemps contenus dÇbordent et envahissent votre espace. Elle|signale aussi un grand nettoyage, la fin d''un Çtat ancien avant|une reconstruction.|',
  'La glace reprÇsente des Çmotions figÇes, une froideur affective ou|une situation bloquÇe. Elle peut aussi protÇger : ce qui est gelÇ|est conservÇ intact, en attente du dÇgel qui viendra le libÇrer.|',
  'La neige Çvoque la puretÇ, le silence et le repos ; elle recouvre|le paysage comme une page blanche. Elle peut symboliser une mise|en sommeil temporaire, une gestation discräte ou la nostalgie de|',
  'l''enfance.|La cascade unit la force et la grÉce : elle figure une Çnergie|Çmotionnelle puissante qui se libäre. Elle suggäre un|lÉcher-prise, une rÇgÇnÇration ou l''abondance qui jaillit apräs|',
  'une longue retenue.|La source reprÇsente l''origine de la vie, la renaissance et les|ressources intÇrieures inÇpuisables. Pour Jung, elle figure|',
  'l''accäs au Soi et Ö l''inconscient crÇateur, d''oó jaillissent|intuition et Çnergie nouvelle.|La boue màle la terre et l''eau : elle Çvoque une situation|',
  'confuse, un sentiment de souillure ou un enlisement. Elle est|aussi matiäre fertile, d''oó peut naåtre une transformation.|La plage est une frontiäre entre la terre ferme du conscient et la|',
  'mer de l''inconscient. Lieu de dÇtente, elle exprime le besoin de|repos et de vacances ; le sable rappelle aussi le temps qui|s''Çcoule.|L''åle figure un refuge, un monde Ö part oó l''on se retire pour|',
  'se retrouver. Elle peut exprimer un besoin d''indÇpendance et de|recentrage sur le Soi, ou un sentiment d''isolement vis-Ö-vis des|autres.|La montagne symbolise l''ÇlÇvation, l''ambition et la quàte|',
  'spirituelle ; elle relie la terre au ciel. Son ascension|reprÇsente l''effort vers un but ou vers la sagesse, et le sommet,|la rÇalisation de soi.|',
  'La vallÇe, creuse et protÇgÇe, Çvoque l''accueil, la fÇconditÇ et|le repos apräs l''effort. Entre deux sommets, elle figure aussi|une pÇriode d''humilitÇ ou de recueillement, propice Ö la|',
  'maturation intÇrieure.|Le dÇsert Çvoque le dÇpouillement, la solitude et l''Çpreuve : on|y affronte le manque pour revenir Ö l''essentiel. Lieu des ermites|',
  'et des prophätes, il peut aussi annoncer une profonde quàte de|sens.|La foràt reprÇsente l''inconscient et ses mystäres, le territoire|de l''inconnu oó l''on risque de s''Çgarer mais aussi de se|',
  'dÇcouvrir. Dans les contes, c''est le lieu des Çpreuves|initiatiques et des rencontres dÇcisives.|L''arbre est un symbole majeur du Soi et de la croissance :|',
  'enracinÇ dans la terre et tendu vers le ciel, il relie les mondes.|Il reprÇsente votre dÇveloppement personnel, votre lignÇe et votre|vitalitÇ.|',
  'Les racines figurent les origines, l''hÇritage familial et les|fondements de la personnalitÇ. Elles invitent Ö explorer votre|passÇ, vos ancàtres et ce qui vous nourrit en profondeur, souvent|',
  'sans que vous le voyiez.|La feuille suit le rythme des saisons : verte, elle dit la|vitalitÇ et l''espoir ; tombante, elle Çvoque le temps qui passe|',
  'et le dÇtachement. Elle refläte ainsi la phase de vie que vous|traversez.|La fleur symbolise l''Çpanouissement, la beautÇ ÇphÇmäre et|l''amour ; elle est l''Éme qui s''ouvre. Freud y lisait la|',
  'fÇminitÇ et le dÇsir, Jung l''Çclosion du Soi. Sa couleur et son|Çtat nuancent le message.|Reine des fleurs, la rose est l''embläme de l''amour, de la|',
  'passion et du secret. En mystique, elle figure aussi la perfection|spirituelle et le coeur qui s''ouvre ; ses Çpines rappellent le|prix des sentiments.|',
  'Le jardin figure l''espace intÇrieur que vous cultivez : vos|talents, vos relations et votre vie affective. Image du paradis|perdu, il exprime aussi le besoin d''harmonie et le soin apportÇ Ö|',
  'ce qui grandit en vous.|La prairie Çvoque la libertÇ, l''innocence et l''abondance|tranquille de la nature. Espace ouvert et nourricier, elle refläte|',
  'souvent un besoin de simplicitÇ, de retour Ö l''enfance ou|d''insouciance.|La grotte symbolise le ventre maternel, l''inconscient et le lieu|',
  'des renaissances. Y descendre revient Ö explorer vos profondeurs ;|c''est l''espace de l''initiation, oó l''on affronte l''ombre pour|renaåtre.|',
  'La pierre incarne la permanence, la soliditÇ et ce qui rÇsiste au|temps. Pour Jung, elle peut figurer le Soi indestructible ; elle|Çvoque aussi la duretÇ, l''obstacle ou un coeur qui s''est fermÇ.|',
  'Le puits relie la surface Ö la profondeur cachÇe : il symbolise|l''accäs Ö l''inconscient, la sagesse et la vÇritÇ enfouie. Puiser|de l''eau, c''est aller chercher en soi des ressources et des|rÇponses.|',
  'Le volcan reprÇsente des passions et des coläres longtemps|contenues qui menacent d''Çclater. Il Çvoque aussi une Çnergie|crÇatrice brute : apräs l''Çruption, la lave refroidie rend la|',
  'terre particuliärement fertile.|Le brouillard traduit l''incertitude, la confusion et une vision|limitÇe de l''avenir. Il voile ce qui est encore mal compris en|',
  'vous ; mais il finit toujours par se lever, laissant apparaåtre le|chemin.|Le champ symbolise le travail patient et ses fruits : ce que vous|',
  'semez aujourd''hui, vous le rÇcolterez demain. Il refläte l''Çtat|de vos projets, votre fÇconditÇ et votre lien Ö la terre|nourriciäre.|',
  'Les animaux figurent la part instinctive de la psychÇ : besoins du|corps, pulsions et intuitions. Leur attitude envers vous refläte|la relation que vous entretenez avec votre nature profonde.|',
  'Le serpent incarne l''Çnergie vitale et la sexualitÇ ; par sa mue,|il Çvoque la transformation, et le caducÇe en fait un embläme de|guÇrison. Freud y lisait le dÇsir, Jung une force de renouveau.|',
  'Le chat symbolise l''indÇpendance, l''intuition et une fÇminitÇ|secräte. Gracieux et insaisissable, il reprÇsente la part de vous|qui suit son propre chemin et peráoit ce qui reste invisible.|',
  'Le chien reprÇsente la fidÇlitÇ, l''amitiÇ et la protection.|Gardien du seuil dans les mythes, il guide aussi l''Éme ; en ràve,|il refläte souvent vos liens affectifs et votre loyautÇ.|',
  'Le cheval figure l''Çnergie vitale, la puissance du dÇsir et|l''Çlan qui vous porte en avant. Selon Jung, il reprÇsente la|libido maåtrisÇe ; la maniäre dont vous le menez dit comment vous|',
  'dirigez votre vie.|Le loup rÇunit l''instinct sauvage, la solitude et le sens du|clan. Figure de prÇdateur dans les contes, il incarne aussi|l''intelligence de la meute et l''appel d''une libertÇ encore|',
  'indomptÇe.|L''ours Çvoque la force tranquille, la protection maternelle et le|repli de l''hibernation. Il invite Ö l''introspection et rappelle|',
  'la puissance brute qui sommeille sous une apparence placide.|Le lion, roi des animaux, symbolise le courage, l''autoritÇ et la|fiertÇ. AssociÇ au soleil, il reprÇsente la conscience rayonnante|',
  'et la capacitÇ d''affirmer sa place avec noblesse.|Le tigre incarne une Çnergie passionnÇe, la puissance et une|certaine cruautÇ instinctive. Il figure les dÇsirs ardents et la|',
  'coläre, mais aussi la beautÇ souveraine de l''instinct pleinement|assumÇ.|L''oiseau relie la terre et le ciel : il reprÇsente l''Éme, la|',
  'pensÇe libre et les aspirations ÇlevÇes. Dans la tradition, il est|aussi messager et annonce des nouvelles selon son chant et son|vol.|L''aigle symbolise la hauteur de vue, la puissance et la|',
  'clairvoyance. Messager des dieux et embläme des empires, il|reprÇsente l''ambition, l''esprit qui s''Çläve et le regard|capable de voir loin.|',
  'Le corbeau, souvent jugÇ de mauvais augure, est aussi dans les|mythes un oiseau de sagesse et de mÇmoire, messager entre les|mondes. Il signale une transformation et l''intelligence de|l''Ombre.|',
  'Le hibou, oiseau de la nuit et d''AthÇna, symbolise la sagesse, la|perception de ce qui est cachÇ et le savoir intÇrieur. Il voit|dans l''obscuritÇ, comme la conscience qui Çclaire l''inconscient.|',
  'La colombe est l''embläme universel de la paix, de la puretÇ et de|l''esprit. Symbole d''amour fidäle et de rÇconciliation, elle|annonce l''apaisement d''une tension et un souffle d''espoir.|',
  'Le poisson, qui vit dans les profondeurs, figure les contenus de|l''inconscient qui remontent Ö la conscience. Symbole chrÇtien et|signe de fÇconditÇ, il Çvoque aussi la prospÇritÇ et l''intuition.|',
  'Le requin reprÇsente un danger tapi sous la surface : agressivitÇ,|rivalitÇ ou aviditÇ. Il incarne la peur d''àtre dÇvorÇ par plus|fort que soi, dans un milieu professionnel ou affectif.|',
  'La baleine, gÇante des abysses, symbolise la profondeur de|l''inconscient et la puissance maternelle. Comme Jonas avalÇ puis|rendu au monde, elle Çvoque une Çpreuve de retraite qui prÇcäde|',
  'une renaissance.|Le dauphin incarne l''intelligence joyeuse, la sociabilitÇ et la|bienveillance. Guide des naufragÇs dans les lÇgendes antiques, il|',
  'relie la conscience aux profondeurs Çmotionnelles avec lÇgäretÇ.|L''araignÇe tisse sa toile avec patience : elle symbolise la|crÇation, le destin et l''habiletÇ, mais aussi le piäge. Jung y|',
  'voyait parfois la Märe dÇvorante, une emprise affective qui|retient.|Les insectes figurent souvent les petits tracas, les pensÇes|obsÇdantes ou les irritations qui grouillent sous la surface. Leur|',
  'nombre Çvoque ce qui Çchappe au contrìle, leur mÇtamorphose une|Çvolution.|L''abeille symbolise le travail, l''organisation collective et la|',
  'prospÇritÇ. Productrice de miel, elle Çvoque la douceur obtenue|par l''effort ; la ruche reprÇsente la famille ou la communautÇ|harmonieuse.|',
  'La fourmi incarne la patience, la persÇvÇrance et la discipline|collective. Elle rappelle que les grandes oeuvres naissent|d''efforts modestes et rÇpÇtÇs, mais aussi le risque de se perdre|',
  'dans la masse.|La mouche reprÇsente l''agacement, les pensÇes parasites et ce qui|vous harcäle sans relÉche. AssociÇe Ö la dÇcomposition, elle|signale aussi une situation qu''il est temps d''assainir.|',
  'Le papillon est le grand symbole de la mÇtamorphose : de la|chenille Ö l''envol, il reprÇsente l''Éme qui se libäre et la|beautÇ ÇphÇmäre. Les Grecs le nommaient psychÇ, le souffle de|l''Éme.|',
  'Le rat Çvoque la saletÇ, la trahison et ce qui ronge en secret. Il|peut aussi dÇsigner une intelligence dÇbrouillarde et une capacitÇ|de survie ; il pointe ce qui, dans votre vie, mine votre Çnergie.|',
  'La souris symbolise la discrÇtion, la timiditÇ et les petites|choses qui passent inaperáues. Elle peut figurer une part de vous|qui se fait trop petite, ou de lÇgers soucis qui grignotent votre|',
  'tranquillitÇ.|Le lapin est symbole de fÇconditÇ, de vivacitÇ et de chance. LiÇ Ö|la lune et au printemps, il Çvoque l''abondance et la tendresse,|',
  'mais aussi la vulnÇrabilitÇ et la tendance Ö fuir les difficultÇs.|Le cerf, dont les bois repoussent chaque annÇe, symbolise le|renouveau, la noblesse et l''ÇlÇvation spirituelle. Messager sacrÇ|',
  'dans de nombreuses traditions, il incarne la dignitÇ et la grÉce.|Le taureau incarne la force virile, la fÇconditÇ et|l''obstination. Animal sacrÇ des cultes anciens, il reprÇsente une|',
  'puissance instinctive et sexuelle, l''Çnergie crÇatrice et|l''attachement aux biens.|La vache symbolise la maternitÇ nourriciäre, l''abondance et la|',
  'patience. SacrÇe en Inde et figure de la dÇesse Hathor en êgypte,|elle Çvoque la sÇcuritÇ matÇrielle et la douceur du foyer.|Le cochon reprÇsente Ö la fois la prospÇritÇ et les appÇtits|',
  'sensuels. Porte-bonheur dans bien des cultures, il Çvoque|l''abondance matÇrielle, mais aussi la gourmandise, la paresse ou|la crainte de l''excäs.|',
  'Le mouton Çvoque la douceur, l''innocence, mais aussi le|conformisme et la docilitÇ. L''agneau, figure du sacrifice, peut|renvoyer Ö un sentiment de vulnÇrabilitÇ ou au besoin de se fondre|',
  'dans le groupe.|Le singe reprÇsente l''imitation, la malice et la part espiägle de|la personnalitÇ. Figure du Fripon, il moque les conventions et|',
  'peut rÇvÇler l''hypocrisie d''un entourage ou votre propre goñt du|jeu.|L''ÇlÇphant symbolise la sagesse, la mÇmoire et la force paisible.|',
  'Monture des rois et figure du dieu Ganesh, qui läve les obstacles,|il Çvoque la stabilitÇ, la patience et la puissance bienveillante.|Le crocodile, Ö la fois aquatique et terrestre, incarne une force|',
  'primitive tapie dans les eaux de l''inconscient. Il Çvoque la|voracitÇ, l''hypocrisie des larmes feintes et une menace|dissimulÇe.|La grenouille, qui passe du tàtard Ö l''adulte et de l''eau Ö la|',
  'terre, symbolise la mÇtamorphose et la fÇconditÇ. Dans les contes,|le crapaud embrassÇ devient prince : la beautÇ cachÇe finit par se|rÇvÇler.|',
  'La tortue symbolise la longÇvitÇ, la patience et la sagesse.|Portant sa maison sur son dos, elle Çvoque la protection et le|repli ; dans les mythes, elle soutient le monde, image de|stabilitÇ.|',
  'L''escargot Çvoque la lenteur, la prudence et le repli sur soi. Sa|coquille en spirale symbolise le cheminement intÇrieur et le temps|nÇcessaire Ö toute maturation ; il invite Ö respecter votre|',
  'rythme.|Le ver est associÇ Ö la dÇcomposition, Ö ce qui ronge de|l''intÇrieur, mais aussi Ö la fertilitÇ de la terre qu''il|rÇgÇnäre. Il peut Çvoquer un sentiment d''infÇrioritÇ ou un lent|',
  'travail de transformation.|Le scorpion incarne la menace soudaine, la jalousie et la|vengeance, mais aussi la passion et la rÇgÇnÇration. Son dard|',
  'Çvoque des paroles blessantes ou une sexualitÇ vÇcue comme|dangereuse.|Le renard symbolise la ruse, l''intelligence et l''adaptation.|HÇros malicieux du Roman de Renart, il reprÇsente le Fripon qui|',
  'contourne les obstacles, mais aussi la tromperie et la duplicitÇ.|La chauve-souris, crÇature du crÇpuscule qui voit dans le noir,|reprÇsente les peurs nocturnes et l''Ombre, mais aussi|',
  'l''intuition. En Chine, elle est au contraire un porte-bonheur et|un signe de longÇvitÇ.|Le coq, qui chante l''aube, symbolise la vigilance, la fiertÇ et|',
  'le rÇveil ; la poule Çvoque la maternitÇ protectrice et le foyer.|Ensemble, ils parlent de la vie domestique et de l''image que|l''on donne.|',
  'Le cygne symbolise la beautÇ, la grÉce et l''amour fidäle. Figure|de mÇtamorphose, du vilain petit canard au cygne, il Çvoque|l''Anima et la lumiäre ; Zeus prit sa forme pour sÇduire LÇda.|',
  'Le cafard, insecte nocturne et rÇsistant, figure les pensÇes|sombres, la saletÇ et ce que l''on cache. Le mot màme dÇsigne la|mÇlancolie ; il signale un malaise qui revient sans cesse s''il|',
  'n''est pas traitÇ.|Le paon, avec sa roue Çblouissante, symbolise la beautÇ, la fiertÇ|et le dÇsir d''àtre admirÇ. Dans la tradition chrÇtienne, il|',
  'reprÇsente l''immortalitÇ ; il interroge l''image que vous donnez|aux autres.|La chävre Çvoque l''indÇpendance, l''agilitÇ et le caractäre|capricieux. Le bouc, lui, est liÇ Ö la sexualitÇ dÇbridÇe et au|',
  'bouc Çmissaire ; ensemble, ils parlent d''instinct, de libertÇ et|de marginalitÇ.|Le corps ràvÇ refläte la maniäre dont vous habitez votre existence|',
  ': il traduit l''image de soi, l''Çnergie disponible et, selon|Jung, l''enracinement du Soi dans la matiäre.|Les dents expriment la force d''affirmation, l''apparence sociale|',
  'et la capacitÇ Ö Æ mordre Ø dans la vie. Leur chute, ràve träs|rÇpandu, parle souvent d''une transition, d''un Ége qui change ou|d''une crainte de perdre la face.|',
  'Les cheveux symbolisent la force vitale, la sÇduction et les|pensÇes, puisqu''ils poussent de la tàte. Comme Samson, le ràveur|y voit sa puissance ; les couper ou les coiffer Çvoque un|',
  'changement d''identitÇ.|Les yeux sont le miroir de l''Éme et l''organe de la luciditÇ. En|ràve, ils parlent de ce que vous acceptez de voir, de comprendre|',
  'ou de rÇvÇler, et parfois du regard des autres sur vous.|La bouche est le lieu de la parole, de l''oralitÇ et du plaisir.|Freud y lisait les dÇsirs les plus archaãques ; elle questionne|',
  'aussi ce que vous dites, taisez ou avalez sans protester.|La main est l''outil de l''action, du don et du lien. Elle montre|votre capacitÇ Ö saisir, crÇer, protÇger ou recevoir ; tendue ou|',
  'fermÇe, elle dit beaucoup de votre ouverture aux autres.|Les pieds relient Ö la terre et figurent l''enracinement, la|stabilitÇ et la direction prise dans la vie. Ràver de ses pieds|',
  'interroge votre maniäre d''avancer et la soliditÇ de vos appuis.|Les jambes portent le mouvement et l''autonomie : elles disent|votre capacitÇ Ö vous tenir debout et Ö soutenir vos projets. Les|',
  'genoux Çvoquent aussi l''humilitÇ, la priäre ou la soumission.|Les bras incarnent la force d''agir, la protection et l''Çtreinte.|Ils reprÇsentent ceux sur qui l''on s''appuie, mais aussi votre|',
  'propre capacitÇ Ö porter, dÇfendre et accueillir.|La tàte est le siäge de la raison, de l''autoritÇ et des idÇes.|Elle reprÇsente la maåtrise de soi et la place que vous occupez ;|',
  'ràver de sa tàte interroge l''Çquilibre entre pensÇe et instinct.|Le visage est la carte de l''identitÇ et de la relation : c''est|la Persona que vous montrez au monde. Un visage inconnu ou|',
  'changeant rÇväle souvent une facette de vous-màme en train|d''Çmerger.|Le coeur est le centre de la vie affective, du courage et de la|vÇritÇ intime. En ràve, il rÇväle l''Çtat de vos liens et de vos|',
  'Çlans, et la maniäre dont vous Çcoutez ce qui vous anime vraiment.|Le ventre est le lieu de la digestion, de l''intuition et de la|gestation. Il parle de ce que vous assimilez ou ne Æ digÇrez Ø pas|',
  'et, selon Jung, du lien primitif avec la Märe nourriciäre.|La peau est la frontiäre entre soi et le monde, l''enveloppe qui|protäge et qui ressent. Elle traduit votre sensibilitÇ au contact,|',
  'votre image sociale et, quand elle mue, une identitÇ qui se|renouvelle.|La blessure signale une atteinte Ö l''intÇgritÇ, physique ou|morale. Elle dÇsigne souvent une offense ancienne ou rÇcente qui|',
  'demande attention ; dans la tradition, la plaie soignÇe annonce|aussi la guÇrison.|La cicatrice est la mÇmoire d''une Çpreuve traversÇe : elle|',
  'rappelle une ancienne douleur mais prouve aussi votre capacitÇ de|rÇsilience. Elle marque ce qui vous a faáonnÇ et fait partie de|votre histoire.|',
  'La maladie onirique est rarement prÇmonitoire : elle exprime un|dÇsÇquilibre, une fatigue ou un conflit intÇrieur qui cherche Ö se|dire. Elle peut aussi marquer un temps d''arràt nÇcessaire avant|',
  'un renouveau.|La grossesse annonce le plus souvent une gestation symbolique : un|projet, une idÇe ou une part de vous qui mñrit en silence. Chez|',
  'Jung, elle prÇpare la naissance d''un nouvel aspect du Soi.|Vomir en ràve, c''est rejeter ce que l''on ne peut plus garder :|une situation, une relation ou des paroles indigestes. Le ràve est|',
  'souvent libÇrateur, signe d''une purification psychique en cours.|La cÇcitÇ onirique Çvoque ce que vous refusez de voir ou une|situation dans laquelle vous avancez sans repäres. Elle invite|',
  'aussi, Ö la maniäre du devin TirÇsias, Ö dÇvelopper une vision|intÇrieure.|La voix reprÇsente la capacitÇ Ö s''affirmer et Ö faire entendre|',
  'sa vÇritÇ. Une voix entendue sans visage peut porter le message de|l''inconscient, de l''Anima ou d''un guide intÇrieur.|Les oreilles parlent d''Çcoute, de rÇceptivitÇ et d''obÇissance.|',
  'Elles questionnent ce que vous entendez vraiment, les conseils que|vous recevez et les rumeurs qui vous atteignent.|Le nez symbolise le flair, l''intuition et la curiositÇ, mais|',
  'aussi l''orgueil quand on le porte haut. Freud y voyait parfois un|substitut sexuel ; il parle de ce que vous Æ sentez Ø d''une|situation.|',
  'Les ongles reprÇsentent la dÇfense, l''agressivitÇ contenue et le|soin apportÇ Ö l''apparence. Ils rÇvälent la maniäre dont vous|protÇgez votre territoire et dont vous prÇsentez vos Æ griffes Ø.|',
  'Les doigts prolongent finement la main : habiletÇ, prÇcision et|communication par le geste. Chaque doigt a sa tradition, du pouce|de la volontÇ Ö l''annulaire de l''alliance et de l''engagement.|',
  'La barbe symbolise la maturitÇ, la virilitÇ et la sagesse, Ö|l''image des patriarches. Elle parle d''autoritÇ et d''expÇrience|; se raser Çvoque le dÇsir de changer d''apparence ou de rajeunir.|',
  'Le dos porte les charges et les responsabilitÇs ; il reprÇsente|aussi ce qui reste cachÇ derriäre soi, le passÇ et l''Ombre. Ràver|de son dos interroge le poids que vous acceptez de supporter.|',
  'La gorge est le passage entre le coeur et la tàte, entre ce que|l''on ressent et ce que l''on dit. Elle Çvoque l''expression de|soi, la vulnÇrabilitÇ, et tout ce qui reste Æ en travers Ø de la|gorge.|',
  'La langue rÇunit la parole et le goñt : elle parle de|communication, de sensualitÇ et du pouvoir des mots. Une langue|Çtrangäre comprise sans effort peut signaler un message de|l''inconscient.|',
  'La nuditÇ rÇväle le rapport Ö l''authenticitÇ et au regard|d''autrui. Se retrouver nu en public, ràve classique selon Freud,|exprime la crainte d''àtre exposÇ ou le dÇsir de se montrer tel|',
  'que l''on est, sans Persona.|La märe incarne l''origine, la protection et la nourriture|affective ; chez Jung, elle rejoint l''archÇtype de la Grande|',
  'Märe, Ö la fois tendre et dÇvorante. Elle refläte souvent votre|propre maniäre de prendre soin.|Le päre reprÇsente la loi, l''autoritÇ, la protection et|',
  'l''ouverture vers le monde extÇrieur. Selon Freud et Jung, il|figure aussi votre surmoi et votre rapport aux rägles, Ö|l''ambition et Ö la reconnaissance.|',
  'Les parents rÇunis figurent les fondations de votre personnalitÇ :|modäles intÇriorisÇs, valeurs hÇritÇes et premiäres rägles. Le|ràve interroge la place que vous laissez Ö cet hÇritage dans vos|',
  'choix d''adulte.|L''enfant reprÇsente la spontanÇitÇ, l''innocence et l''avenir ;|chez Jung, l''Enfant divin annonce un renouveau de la|personnalitÇ. Il peut aussi àtre l''enfant que vous avez ÇtÇ, avec|',
  'ses besoins encore prÇsents.|Le bÇbÇ symbolise un commencement : idÇe neuve, projet naissant ou|part fragile de vous qui demande soin. Dans la tradition, il|',
  'annonce une nouveautÇ heureuse, Ö condition de l''accueillir et de|la nourrir.|Le fräre incarne la complicitÇ, la rivalitÇ et l''ÇgalitÇ dans le|',
  'lien. Pour une ràveuse, il peut figurer l''Animus ; pour un|ràveur, une part fraternelle de l''Ombre, proche et pourtant|diffÇrente.|La soeur reprÇsente la complicitÇ, la confidence et le miroir|',
  'affectif. Pour un ràveur, elle peut porter l''Anima ; pour une|ràveuse, une facette proche d''elle-màme, alliÇe ou concurrente.|Les grands-parents relient aux racines, Ö la mÇmoire familiale et|',
  'Ö la sagesse des gÇnÇrations. Ils figurent souvent le Vieux Sage|ou la Grande Märe, gardiens de valeurs et de souvenirs qui vous|soutiennent.|',
  'La famille figure le clan intÇrieur, l''appartenance et les rìles|que vous avez appris Ö tenir. Les rÇunions de famille ràvÇes|mettent en scäne les liens, les secrets et les loyautÇs qui|',
  'faáonnent votre identitÇ.|Le mari reprÇsente l''engagement, la protection et le partenariat.|Il peut figurer votre conjoint rÇel, ou l''Animus : la part active|',
  'et dÇcidÇe de la psychÇ qui cherche Ö s''unir Ö vous.|L''Çpouse symbolise l''union, la fidÇlitÇ et la vie partagÇe. Elle|peut reprÇsenter votre compagne rÇelle ou l''Anima, cette part|',
  'sensible et intuitive avec laquelle vous cherchez Ö vous|rÇconcilier.|L''ami reprÇsente la confiance, le partage et souvent un trait de|caractäre que vous admirez ou dÇveloppez. Selon Jung, un ami du|',
  'màme sexe peut aussi incarner votre Ombre, ce double familier qui|vous compläte.|L''inconnu est souvent une part de vous que vous ne connaissez pas|',
  'encore : l''Ombre s''il inquiäte, l''Anima ou l''Animus s''il|fascine. Son attitude indique ce que l''inconscient cherche Ö vous|faire dÇcouvrir.|',
  'La foule reprÇsente la vie sociale, l''opinion collective et la|place que vous occupez parmi les autres. Selon le contexte, elle|exprime l''appartenance joyeuse ou la crainte de se perdre dans|',
  'l''anonymat.|La cÇlÇbritÇ ràvÇe incarne une qualitÇ que vous admirez et|aimeriez dÇvelopper : talent, aisance, rayonnement. Elle traduit|',
  'aussi un dÇsir de reconnaissance, parfaitement lÇgitime, que Freud|rangeait parmi les souhaits.|Le roi symbolise l''autoritÇ supràme, la souverainetÇ sur sa|',
  'propre vie et la figure paternelle idÇalisÇe. Chez Jung, il peut|reprÇsenter le Soi ordonnateur qui gouverne avec justice le|royaume intÇrieur.|',
  'La reine incarne la puissance fÇminine, la dignitÇ et l''autoritÇ|bienveillante. Elle peut figurer la märe idÇalisÇe, l''Anima|souveraine ou votre propre capacitÇ Ö rÇgner avec grÉce sur votre|vie.|',
  'Le prince reprÇsente le hÇros en devenir, la promesse d''un|pouvoir encore jeune et l''idÇal amoureux. Pour une ràveuse, il|incarne souvent l''Animus ; pour un ràveur, ses propres ambitions|',
  'en train de mñrir.|La princesse symbolise la grÉce, la puretÇ et un potentiel fÇminin|encore en Çveil. Elle peut reprÇsenter l''Anima idÇalisÇe d''un|',
  'ràveur ou, pour une ràveuse, le dÇsir d''àtre reconnue et choyÇe.|Le policier reprÇsente la loi, l''ordre et la conscience morale,|ce que Freud nommait le surmoi. Son arrivÇe en ràve interroge|',
  'votre rapport aux rägles, Ö la culpabilitÇ et au besoin d''àtre|protÇgÇ.|Le voleur Çvoque ce qui vous dÇrobe du temps, de l''Çnergie ou de|l''estime : une relation, une habitude, une peur. Il peut aussi|',
  'figurer le Fripon, part de vous qui prend ce qu''elle n''ose pas|demander.|Le soldat incarne la discipline, le devoir et la combativitÇ. Il|',
  'figure l''Çnergie du HÇros pràt Ö dÇfendre ses valeurs, mais aussi|la rigiditÇ d''une obÇissance qui Çtouffe parfois les dÇsirs|personnels.|Le mÇdecin reprÇsente le guÇrisseur intÇrieur, la sagesse qui|',
  'diagnostique et soigne. Sa prÇsence rÇväle un besoin de|rÇparation, physique ou psychique, et la capacitÇ Ö demander ou|accepter de l''aide.|',
  'Le professeur incarne la transmission, l''autoritÇ du savoir et|l''Çvaluation. Il peut figurer le Vieux Sage qui guide, ou la voix|intÇrieure exigeante qui vous juge ; l''enjeu est souvent une|',
  'leáon de vie.|Le clown est la figure du Fripon : il bouscule les conventions,|fait rire de ce qui päse et rÇväle la vÇritÇ sous le masque.|',
  'Derriäre son maquillage, il peut aussi cacher une tristesse ou une|peur.|Le vieillard est l''image du Vieux Sage jungien : expÇrience,|patience et connaissance de soi. Il apparaåt souvent au moment|',
  'd''un choix important pour transmettre un conseil, une mise en|garde ou une consolation.|L''ennemi est souvent une projection de l''Ombre : il incarne ce|',
  'que vous rejetez en vous ou une tension rÇelle avec autrui.|L''affronter en ràve aide Ö reconnaåtre vos propres forces et vos|limites.|Le double ou le jumeau met en scäne la dualitÇ de la personnalitÇ|',
  ': une part de vous qui se dÇtache pour àtre vue. Jung y reconnaåt|l''Ombre ou le Soi en miroir, invitant Ö unir des tendances|opposÇes.|Le voisin reprÇsente l''entourage proche et la frontiäre entre|',
  'intimitÇ et vie sociale. Il figure parfois un trait de caractäre|familier que vous observez chez autrui sans le reconnaåtre en|vous.|La maison figure la psychÇ du ràveur : ses Çtages et ses piäces|',
  'rÇpondent aux diffÇrentes couches de la personnalitÇ. Pour Jung,|l''explorer revient Ö dÇcouvrir des zones encore inconnues de soi.|Revenir dans la maison de l''enfance ramäne aux racines affectives|',
  'et aux schÇmas familiaux qui vous ont faáonnÇ. Freud y voyait le|retour de souvenirs anciens, Jung un appel Ö retrouver l''enfant|intÇrieur.|La chambre est le lieu de l''intimitÇ, du repos et de la vie|',
  'amoureuse. Elle refläte ce que vous gardez pour vous seul : vos|dÇsirs, vos secrets et la qualitÇ de votre relation Ö vous-màme.|Coeur nourricier du foyer, la cuisine est le lieu des|',
  'transformations : on y change le cru en cuit. Elle parle de votre|faáon de nourrir les autres et vous-màme, et de projets qui|mñrissent lentement.|',
  'Lieu de purification, la salle de bain exprime le besoin de vous|laver d''un poids, d''une culpabilitÇ ou d''Çmotions accumulÇes.|Elle accompagne souvent un renouveau intÇrieur et le souci de|',
  'l''image de soi.|Les toilettes parlent d''Çvacuation : ce dont vous devez vous|dÇbarrasser, Çmotions retenues ou contraintes. Freud y reliait le|',
  'rapport au contrìle et Ö l''intimitÇ ; ne pas en trouver dit|souvent un manque d''espace Ö soi.|La cave reprÇsente l''inconscient profond, ce qui a ÇtÇ relÇguÇ|',
  'sous la surface : souvenirs, instincts et peurs anciennes. Pour|Jung, y descendre, c''est rencontrer l''Ombre et les fondations de|la personnalitÇ.|',
  'Le grenier abrite la mÇmoire : objets oubliÇs, hÇritage familial,|idÇes mises de cìtÇ. SituÇ en haut de la maison, il Çvoque aussi|la pensÇe, la rÇflexion et les aspirations spirituelles du ràveur.|',
  'L''escalier relie les niveaux de la conscience : monter Çvoque|l''ÇlÇvation, l''ambition ou la progression spirituelle, descendre|le retour vers l''inconscient. Freud y lisait aussi une image du|dÇsir.|',
  'La porte marque le passage d''un Çtat Ö un autre : une|opportunitÇ, une transition ou l''accäs Ö une part inconnue de|vous. Ouverte, elle invite au changement ; fermÇe, elle pose la|',
  'question de vos limites.|La fenàtre est le regard que vous portez sur le monde et sur|l''avenir. Elle sÇpare l''intÇrieur protÇgÇ de l''extÇrieur Ö|',
  'dÇcouvrir ; regarder au-dehors exprime souvent une attente ou une|ouverture d''esprit.|Le mur incarne Ö la fois la protection et l''obstacle : il|',
  'dÇlimite votre territoire mais peut aussi vous couper des autres.|Il dÇsigne souvent une dÇfense psychique, une barriäre que vous|avez dressÇe.|',
  'Le toit protäge et couronne la maison : il symbolise la sÇcuritÇ,|l''autoritÇ protectrice et la pensÇe qui domine l''ensemble.|Marcher dessus traduit un dÇsir de hauteur, parfois une prise de|risque.|',
  'Le couloir est un espace de transition : il relie deux Çtats sans|en àtre un lui-màme. Il refläte une pÇriode d''attente ou de|passage, oó l''on avance vers une dÇcision encore floue.|',
  'L''ascenseur Çvoque une ascension ou une chute rapide, sur|laquelle vous n''avez qu''une maåtrise partielle. Il renvoie|souvent Ö la carriäre, au statut social et aux changements|soudains de situation.|',
  'DÇcouvrir une piäce inconnue dans sa propre maison est l''un des|ràves les plus fÇconds : il rÇväle un potentiel inexploitÇ, un|talent ou une facette de soi pràte Ö Çclore. Jung y voyait|',
  'l''expansion du Soi.|L''Çcole ramäne au temps de l''apprentissage, des rägles et du|jugement des autres. Elle signale qu''une leáon de vie est en|',
  'cours ou que vous vous sentez ÇvaluÇ dans votre vie actuelle, au|travail comme en famille.|L''hìpital est un lieu de soin et de rÇparation : il apparaåt|',
  'quand une part de vous, physique ou psychique, rÇclame de|l''attention. Il exprime aussi le besoin d''àtre pris en charge et|de vous reposer.|La prison traduit un sentiment d''enfermement : obligations,|',
  'relation Çtouffante, culpabilitÇ ou interdits intÇrieurs. Freud y|lisait l''oeuvre du surmoi ; le ràve invite Ö identifier ce qui|vous retient.|',
  'Le chÉteau unit la grandeur et la protection : il Çvoque vos|idÇaux, vos ambitions et la forteresse intÇrieure que vous|bÉtissez. Dans les contes, il abrite le trÇsor ou la princesse,|',
  'image du Soi Ö conquÇrir.|La ville reprÇsente la vie sociale, la collectivitÇ et la place|que vous y occupez. Ses quartiers figurent les rìles que vous|',
  'jouez ; une ville inconnue annonce souvent un nouveau chapitre de|vie.|La rue est l''espace public, celui oó l''on s''expose au regard|des autres. Elle refläte votre trajectoire sociale et vos choix :|',
  'une avenue large ouvre l''horizon, une ruelle sombre invite Ö la|prudence.|Le labyrinthe figure le cheminement intÇrieur vers le centre de|',
  'soi, avec ses dÇtours et ses impasses. Symbole initiatique, il|exprime une confusion actuelle mais promet une rÇvÇlation Ö qui|persÇväre.|',
  'Le magasin expose l''Çventail des choix qui s''offrent Ö vous et|refläte vos dÇsirs, vos besoins et votre rapport Ö la valeur. Ce|que vous y cherchez rÇväle souvent un manque affectif ou matÇriel.|',
  'Le restaurant associe la nourriture au partage social : il parle|de votre besoin d''àtre nourri, servi et reconnu. Le choix du menu|refläte vos appÇtits affectifs et la faáon dont vous recevez des|',
  'autres.|L''hìtel est un lieu de passage : il Çvoque une situation|transitoire, une identitÇ provisoire ou un besoin de rupture avec|le quotidien. On y est chez soi sans l''àtre, ce qui interroge|',
  'votre sentiment d''appartenance.|Les ruines tÇmoignent d''un passÇ rÇvolu : une relation, une|croyance ou une Çtape de vie qui s''est achevÇe. Elles invitent|',
  'moins au regret qu''au tri, car sur des fondations anciennes on|peut rebÉtir autrement.|La tour relie la terre au ciel : elle exprime l''aspiration Ö|',
  'l''ÇlÇvation, l''ambition et la vigilance. Symbole phallique pour|Freud, elle peut aussi figurer l''isolement de la tour d''ivoire.|La scäne expose la Persona, le rìle social que vous jouez sous le|',
  'regard des autres. Elle parle du besoin de reconnaissance, du trac|de l''Çvaluation et du dÇcalage possible entre l''image montrÇe et|le vrai moi.|',
  'La piscine offre une eau maåtrisÇe, contenue dans un cadre : elle|Çvoque des Çmotions que vous apprivoisez, le loisir et la dÇtente.|Plonger traduit l''envie de vous immerger dans une expÇrience|',
  'nouvelle.|Le palais symbolise le prestige, la richesse intÇrieure et le|dÇsir de reconnaissance. Ses salles somptueuses reflätent la|valeur que vous vous accordez et vos aspirations Ö une vie plus|',
  'noble ou plus vaste.|Le village Çvoque la communautÇ, les racines et une vie Ö taille|humaine oó chacun se connaåt. Il exprime le besoin d''appartenance|',
  'et de simplicitÇ, parfois aussi la pesanteur du regard collectif.|La clÇ ouvre ce qui Çtait fermÇ : elle symbolise la solution d''un|probläme, l''accäs Ö un savoir ou Ö une part secräte de vous.|',
  'Freud y voyait un symbole sexuel ; Jung, la clÇ de la connaissance|intÇrieure.|La serrure reprÇsente une protection, un secret ou un accäs|conditionnÇ : ce qui ne s''ouvre qu''avec la bonne clÇ. Elle|',
  'questionne votre rÇserve, votre pudeur et les verrous que vous|placez sur vos Çmotions.|Le miroir renvoie votre image et pose la question de l''identitÇ :|',
  'comment vous vous voyez et comment vous croyez àtre vu. Pour Jung,|un reflet Çtranger peut rÇvÇler l''Ombre ou une facette mÇconnue|de vous.|',
  'Le tÇlÇphone symbolise la communication et le lien Ö distance : un|message que vous attendez, voulez transmettre ou n''osez pas|exprimer. L''interlocuteur indique souvent la relation qui demande|',
  'Ö àtre renouÇe.|L''ordinateur figure l''intellect, la mÇmoire et la gestion de|l''information. Il refläte votre rapport au contrìle, Ö|l''efficacitÇ et parfois la surcharge mentale propre Ö la vie|',
  'moderne.|Le livre symbolise la connaissance, la sagesse et l''histoire de|votre vie. Un livre ouvert invite Ö apprendre ou Ö comprendre ; un|',
  'livre fermÇ garde un secret qu''il vous appartient de dÇcouvrir.|La lettre annonce un message venu de l''extÇrieur ou de votre|inconscient : une nouvelle, un aveu, une vÇritÇ Ö recevoir. Son|',
  'contenu, lu ou non, Çclaire ce que vous àtes pràt Ö entendre.|La photographie fige un instant : elle renvoie Ö la mÇmoire, Ö la|nostalgie et Ö l''image figÇe que vous gardez de quelqu''un ou de|',
  'vous-màme. Elle invite Ö regarder le passÇ pour mieux comprendre|le prÇsent.|Le sac contient ce que vous portez avec vous : votre identitÇ, vos|',
  'ressources, mais aussi vos fardeaux. Son contenu refläte ce que|vous jugez essentiel ; pour Freud, il peut figurer l''intimitÇ|fÇminine.|',
  'Le parapluie protäge des intempÇries : il symbolise la prudence,|la protection et le soutien face aux Çmotions difficiles. Il peut|aussi trahir une tendance Ö vous abriter un peu trop de la vie.|',
  'La bougie reprÇsente la petite lumiäre qui perce l''obscuritÇ :|espoir, foi, vie intÇrieure. Sa flamme fragile figure l''Éme et la|conscience vigilante ; elle accompagne souvent un moment de|',
  'recueillement.|La lampe Çclaire ce qui Çtait dans l''ombre : elle symbolise la|conscience, l''intelligence et la recherche de la vÇritÇ. Porter|',
  'une lampe signifie que vous explorez activement une question ou|une part de vous.|L''horloge mesure le temps qui passe : elle parle de vos|ÇchÇances, de l''urgence et de la conscience de votre propre|',
  'finitude. Elle invite aussi Ö trouver votre rythme plutìt qu''Ö le|subir.|La bague, cercle sans fin, symbolise l''engagement, la fidÇlitÇ et|',
  'l''union, avec l''autre ou avec soi-màme. Elle signe une promesse|et parfois un lien de pouvoir ou d''appartenance.|Le bijou incarne la valeur personnelle, la beautÇ et ce que vous|',
  'avez de plus prÇcieux. Pour Jung, la pierre prÇcieuse peut figurer|le Soi ; il exprime aussi le dÇsir de plaire et d''àtre reconnu.|La couronne symbolise l''accomplissement, l''autoritÇ et la|',
  'souverainetÇ sur votre propre vie. Elle rÇcompense un effort menÇ|Ö terme et, sur le plan spirituel, l''union rÇussie des forces|intÇrieures.|',
  'Le couteau tranche : il symbolise la sÇparation, la dÇcision nette|et l''agressivitÇ, tournÇe vers l''autre ou vers soi. Freud y|voyait un symbole phallique ; il signale souvent une coupure|nÇcessaire.|',
  'La corde relie et retient : elle Çvoque les liens affectifs, les|engagements et ce qui vous rattache aux autres. Selon le contexte,|elle aide Ö s''Çlever, Ö se sauver, ou au contraire entrave la|',
  'libertÇ.|La chaåne symbolise l''attachement sous sa forme contraignante :|dÇpendance, habitude, devoir ou relation qui retient. Chaque|maillon peut aussi figurer la solidaritÇ et la continuitÇ des|',
  'gÇnÇrations.|Le coffre renferme ce qui est prÇcieux ou cachÇ : souvenirs,|talents, secrets de famille. L''ouvrir, c''est accÇder Ö une|richesse intÇrieure ; Jung y voyait un rÇceptacle du Soi.|',
  'Le cadeau symbolise l''Çchange, la reconnaissance et l''amour|donnÇ ou reáu. Il peut aussi annoncer un talent inattendu que la|vie ou votre inconscient vous offre.|',
  'Le verre brisÇ marque une rupture : illusion qui tombe, Çquilibre|fragile qui cäde ou protection qui se fend. La tradition y voit|aussi la fin d''une situation figÇe, prÇlude Ö un renouvellement.|',
  'L''Çchelle relie le bas et le haut : elle symbolise la progression|par Çtapes, l''ascension sociale ou spirituelle. Comme l''Çchelle|de Jacob, elle met en lien le monde matÇriel et celui des|',
  'aspirations.|Le masque est l''image màme de la Persona : le visage social que|vous prÇsentez pour vous protÇger ou vous adapter. Il interroge|',
  'l''Çcart entre ce que vous montrez et ce que vous àtes vraiment.|La poupÇe renvoie Ö l''enfance, au jeu et aux premiäres|projections affectives. Elle peut aussi figurer un àtre manipulÇ,|',
  'sans volontÇ propre, et questionner votre libertÇ dans une|relation.|Le jouet Çvoque le jeu, l''insouciance et l''enfant intÇrieur. Il|rappelle le besoin de lÇgäretÇ et de crÇativitÇ, ou signale une|',
  'situation que vous ne prenez pas tout Ö fait au sÇrieux.|Le ballon Çvoque le jeu, la lÇgäretÇ et l''Çlan vers le haut.|GonflÇ d''air, il symbolise aussi les espoirs et les projets,|',
  'beaux mais fragiles ; le ballon que l''on se passe parle des|Çchanges avec les autres.|La carte guide et oriente : elle symbolise le projet de vie, la|',
  'direction Ö prendre et la vision d''ensemble. Les cartes Ö jouer|Çvoquent plutìt le hasard, la stratÇgie et les atouts dont vous|disposez.|La boussole indique le nord : elle reprÇsente vos valeurs|',
  'profondes, l''intuition qui vous oriente et le sens que vous|donnez Ö votre vie. Elle invite Ö suivre votre propre direction|plutìt que celle des autres.|',
  'L''ÇpÇe est l''arme du hÇros : elle symbolise le courage, la|justice et la force de discernement qui tranche entre le vrai et|le faux. Pour Jung, elle accompagne la conquàte de soi et la|',
  'victoire sur l''Ombre.|La bouteille contient et conserve : elle Çvoque des Çmotions ou|des dÇsirs gardÇs en rÇserve, une promesse Ö ouvrir au bon moment.|',
  'Vide, elle parle de manque ; jetÇe Ö la mer, d''un appel lancÇ Ö|autrui.|Le lit est le lieu du repos, du ràve et de l''amour : il refläte|votre intimitÇ, votre vie sexuelle et votre besoin de|',
  'rÇgÇnÇration. L''Çtat du lit en dit long sur la qualitÇ de vos|relations proches.|La chaise dÇsigne votre place : dans un groupe, une famille ou une|',
  'hiÇrarchie. S''asseoir Çvoque aussi la pause, l''attente ou le|besoin de stabilitÇ apräs l''effort.|La table rassemble : elle symbolise le partage, la communion|',
  'familiale et la nÇgociation. Ce qui s''y trouve et qui s''y assoit|rÇväle la qualitÇ de vos liens et votre place dans le groupe.|La tÇlÇvision met en scäne une vie observÇe Ö distance : vous àtes|',
  'spectateur plutìt qu''acteur. Le programme diffusÇ peut figurer un|message de l''inconscient, ou le besoin d''Çvasion face au|quotidien.|La cage figure une libertÇ entravÇe : talents ou dÇsirs retenus,|',
  'relation possessive, contraintes acceptÇes par habitude. Ce qui|s''y trouve enfermÇ indique la part de vous qui rÇclame de l''air.|La voiture reprÇsente la maniäre dont vous conduisez votre vie :|',
  'votre autonomie, votre Çnergie et la direction que vous prenez.|Qui tient le volant indique qui, de vous ou d''un autre, dirige|rÇellement votre existence.|',
  'Les freins symbolisent votre capacitÇ Ö ralentir, Ö poser des|limites et Ö garder le contrìle d''une situation. Des freins|dÇfaillants signalent souvent un emballement de votre vie, de vos|',
  'dÇsirs ou de votre rythme.|Le train suit des rails tracÇs d''avance : il Çvoque une|trajectoire collective, un destin balisÇ ou un projet qui avance|',
  'selon un calendrier. Voyager avec d''autres souligne votre place|parmi le groupe.|La gare est un lieu d''attente et de dÇpart : elle annonce un|',
  'tournant, une dÇcision Ö prendre ou un changement en prÇparation.|Les rencontres et les adieux qui s''y jouent touchent souvent la|sphäre affective.|',
  'L''avion porte vos ambitions et vos idÇes vers les hauteurs : il|Çvoque l''Çlan, la libertÇ et les grands projets. Il peut aussi|exprimer le besoin de prendre de la distance ou un changement|',
  'rapide de situation.|L''aÇroport est un seuil entre deux mondes : il annonce un dÇpart,|une transition importante ou le dÇsir de changer de vie. Ses|',
  'contrìles Çvoquent aussi l''examen de ce que vous emportez avec|vous.|Le bateau vous porte sur les eaux de l''Çmotion et de|l''inconscient : il refläte la maniäre dont vous naviguez dans|',
  'votre vie affective. L''Çtat de la mer et du navire dÇcrit votre|traversÇe actuelle.|Le naufrage figure l''effondrement d''un projet, d''une relation|',
  'ou d''un Çquilibre Çmotionnel submergÇ. Il marque pourtant souvent|la fin nÇcessaire d''une ancienne structure avant qu''un nouveau|dÇpart ne devienne possible.|',
  'Le vÇlo demande effort personnel et Çquilibre : il symbolise|l''autonomie, la persÇvÇrance et l''harmonie entre les diffÇrentes|parts de votre vie. Il rappelle qu''on avance en restant en|mouvement.|',
  'Le bus est un transport collectif : il Çvoque votre rapport au|groupe, aux rägles communes et Ö un trajet que vous ne choisissez|pas seul. Il invite Ö vous demander si vous suivez votre voie ou|',
  'celle des autres.|Le mÇtro circule sous la surface : il figure les trajets de|l''inconscient et la routine qui vous emporte. Ses couloirs|souterrains invitent Ö explorer ce qui se joue sous votre vie|',
  'apparente.|La moto associe libertÇ, vitesse et prise de risque : elle exprime|le dÇsir d''indÇpendance et une Çnergie vitale, parfois sexuelle,|',
  'qui veut s''affirmer. Elle demande aussi Çquilibre et maåtrise.|La route est l''image classique du chemin de vie : sa largeur, son|Çtat et ses virages renseignent sur votre parcours actuel. Une|',
  'route qui monte Çvoque l''effort, une route droite la clartÇ de|vos intentions.|Le carrefour annonce un choix dÇcisif entre plusieurs voies :|',
  'professionnelle, affective ou intÇrieure. Lieu de rencontre et|d''hÇsitation dans les traditions, il invite Ö Çcouter votre|intuition plutìt qu''Ö fuir la dÇcision.|',
  'Le pont relie deux rives : il symbolise le passage d''un Çtat Ö un|autre, la rÇconciliation et le lien entre des mondes sÇparÇs. Il|traduit souvent une transition de vie ou un rapprochement avec|',
  'quelqu''un.|Le tunnel est un passage obscur qui mäne vers la lumiäre : il|Çvoque une Çpreuve transitoire, une introspection ou une|renaissance. Freud y voyait un symbole de la naissance ; Jung, une|',
  'descente vers l''inconscient.|La valise contient ce que vous emportez dans votre parcours :|souvenirs, responsabilitÇs, habitudes et blessures anciennes. Elle|',
  'pose la question de ce qu''il faut garder et de ce qu''il est|temps de laisser derriäre vous.|Le billet est un droit de passage : il reprÇsente l''autorisation|',
  'que vous vous donnez d''avancer, les conditions d''un changement|ou une chance Ö saisir. Son Çtat indique votre prÇparation Ö|l''Çtape suivante.|',
  'La frontiäre marque une limite entre le connu et l''inconnu : elle|annonce une transition, un dÇpassement de soi ou la confrontation|Ö vos propres limites. Les contrìles Çvoquent l''autocritique et|',
  'le droit de passer.|Le taxi Çvoque l''aide extÇrieure : vous confiez votre trajet Ö un|inconnu contre rÇtribution. Il interroge votre capacitÇ Ö|',
  'dÇlÇguer, Ö demander du soutien ou, au contraire, Ö vous laisser|trop guider.|L''embouteillage traduit une progression bloquÇe : projets|ralentis, frustration et sentiment que les circonstances ou les|',
  'autres vous freinent. Il invite Ö la patience et Ö revoir votre|itinÇraire.|Rater un train, un avion ou un bus est un ràve frÇquent : il|',
  'traduit la crainte de laisser passer une occasion, le stress des|ÇchÇances ou un conflit intÇrieur sur un changement que vous|n''àtes pas sñr de vouloir.|',
  'Voler en ràve exprime le dÇsir de s''Çlever au-dessus des|contraintes et de prendre de la hauteur. Freud y voyait une|excitation d''enfance ; Jung, l''Çlan de l''esprit vers une vision|plus vaste de soi.|',
  'La chute onirique traduit une perte d''appui : peur d''Çchouer, de|perdre le contrìle ou sa position. Elle survient souvent Ö|l''endormissement et invite Ö vÇrifier sur quoi reposent votre|',
  'sÇcuritÇ et votre estime de vous.|La poursuite est l''un des ràves les plus universels. Le|poursuivant figure souvent une part de vous-màme que vous refusez|',
  'de regarder (l''Ombre de Jung), ou une situation, une Çmotion, une|obligation que vous Çvitez.|Fuir en ràve exprime le besoin de vous soustraire Ö une|',
  'contrainte, une relation ou une responsabilitÇ. Le ràve vous|interroge : de quoi cherchez-vous Ö vous protÇger, et que|gagneriez-vous Ö le regarder en face ?|',
  'Courir traduit l''Çnergie, l''Çlan et la course apräs un but.|Selon le contexte, le ràve parle d''une ambition en marche, d''une|impatience ou d''un rythme de vie qui vous essouffle et vous|',
  'empàche de savourer l''instant.|Nager, c''est Çvoluer dans l''ÇlÇment aquatique, symbole de|l''inconscient et des Çmotions. Le ràve montre votre aisance Ö|',
  'traverser vos Çtats intÇrieurs ; Jung y voyait une plongÇe fÇconde|dans les profondeurs de la psychÇ.|Se noyer exprime le sentiment d''àtre submergÇ par les Çmotions,|',
  'les soucis ou les exigences des autres. Ce ràve n''annonce pas un|malheur : il signale un trop-plein qui demande de l''air, du repos|et du soutien.|',
  'Perdre un objet en ràve renvoie Ö la crainte de perdre ce qu''il|reprÇsente : un lien, un statut, une part de votre identitÇ. Freud|y lisait parfois un dÇsir inavouÇ de se dÇbarrasser de ce qui|',
  'encombre.|Chercher en ràve traduit une quàte : un sens, une rÇponse, une|part de vous-màme ÇgarÇe. Ce que vous cherchez figure souvent un|',
  'besoin rÇel ; la recherche elle-màme dit votre dÇsir d''avancer|vers plus de cohÇrence.|Trouver un objet ou une personne exprime une dÇcouverte intÇrieure|',
  ': une ressource, un talent, une solution qui Çmerge de|l''inconscient. Le ràve rÇcompense souvent une pÇriode de|recherche patiente.|Le retard onirique traduit la peur de manquer une occasion, de|',
  'dÇcevoir ou de ne pas àtre Ö la hauteur. Il refläte souvent une|surcharge d''obligations ou le sentiment de ne pas suivre le|rythme qu''on vous impose.|',
  'L''examen est un ràve classique d''Çvaluation : vous vous sentez|jugÇ, mis Ö l''Çpreuve. Freud remarquait qu''on ràve souvent|d''Çpreuves dÇjÖ rÇussies, comme pour se rassurer devant un dÇfi|prÇsent.|',
  'Crier en ràve libäre une parole longtemps retenue : coläre, appel|Ö l''aide, besoin d''àtre entendu. Le cri muet, si frÇquent,|figure le sentiment que votre voix ne porte pas dans la vie|ÇveillÇe.|',
  'Ne plus pouvoir bouger en ràve correspond souvent Ö l''atonie|musculaire naturelle du sommeil, peráue par la conscience.|Symboliquement, cela exprime un blocage : une dÇcision impossible,|',
  'une situation qui vous fige.|Se cacher exprime le dÇsir de se protÇger du regard d''autrui ou|d''une menace. Le ràve peut rÇvÇler une part de vous que vous|',
  'dissimulez par pudeur ou crainte d''àtre jugÇ, ou un besoin bien|rÇel de retrait.|Se battre en ràve met en scäne un conflit, souvent intÇrieur :|',
  'deux tendances opposÇes, une coläre refoulÇe, une affirmation de|soi qui cherche sa place. L''adversaire peut incarner une facette|de votre propre personnalitÇ.|',
  'Danser exprime l''harmonie entre le corps et l''esprit, la joie de|vivre et l''accord avec les autres. Pour Jung, la danse relie aux|rythmes profonds de la vie ; Ö deux, elle Çvoque souvent la|',
  'relation amoureuse et le dÇsir.|Chanter en ràve traduit l''expression de soi, l''Çlan crÇatif et|l''Çpanchement de l''Éme. Le chant relie souffle et Çmotion ; il|',
  'signale souvent un besoin de faire entendre votre voix intime et|votre sensibilitÇ.|Le rire onirique libäre des tensions et dit la capacitÇ de prendre|',
  'du recul. Freud l''associait Ö une dÇcharge d''Çnergie psychique ;|il peut aussi masquer, par contraste, une inquiÇtude que le ràveur|tient Ö distance.|',
  'Pleurer en ràve est souvent libÇrateur : l''inconscient Çvacue un|chagrin, une fatigue ou une Çmotion retenue. L''onirologie|traditionnelle y voit màme l''annonce d''un soulagement et d''une|',
  'consolation Ö venir.|Se perdre exprime une dÇsorientation : vous ne savez plus quelle|direction prendre dans votre vie, vos choix ou vos relations. Jung|',
  'y voyait aussi l''errance nÇcessaire qui prÇcäde la dÇcouverte|d''un chemin personnel.|Grimper symbolise l''ascension, l''effort vers un but ÇlevÇ,|',
  'qu''il soit professionnel, social ou spirituel. La facilitÇ ou la|difficultÇ de la montÇe refläte la maniäre dont vous vivez vos|ambitions actuelles.|',
  'Descendre Çvoque l''exploration des profondeurs : l''inconscient,|le passÇ, les Çmotions enfouies. Jung voyait dans la descente un|chemin vers l''Ombre et les trÇsors cachÇs de la psychÇ, prÇalable|',
  'Ö toute transformation.|Sauter exprime l''audace, le passage d''un Çtat Ö un autre, la|prise de risque. Le saut figure souvent un choix dÇcisif :|',
  'franchir un obstacle, oser un changement ou se lancer dans|l''inconnu avec confiance.|DÇmÇnager annonce une transition : vous quittez une ancienne|',
  'maniäre d''àtre pour une autre. La maison figurant le moi, changer|de demeure symbolise l''Çvolution de votre identitÇ, de vos|habitudes ou de vos relations.|',
  'Attendre en ràve refläte une situation en suspens : une rÇponse,|un ÇvÇnement, une personne. Le ràve interroge votre rapport au|temps et Ö la patience, et parfois votre tendance Ö espÇrer que|',
  'les choses viennent Ö vous.|L''enfermement exprime le sentiment d''àtre prisonnier d''une|situation, d''une relation, d''un rìle ou de vos propres|',
  'croyances. Le lieu de l''enfermement indique souvent le domaine de|vie oó vous manquez d''espace.|êcrire en ràve traduit le besoin de communiquer, de fixer une|',
  'pensÇe ou de donner forme Ö ce qui vous habite. Les mots tracÇs|sont des messages de l''inconscient qu''il vaut la peine de noter|däs le rÇveil.|',
  'Construire symbolise l''Çdification de votre vie : projets,|relations, personnalitÇ. La soliditÇ de l''ouvrage refläte la|confiance que vous accordez Ö vos fondations ; le chantier|',
  'rappelle que l''on se bÉtit pas Ö pas.|Nettoyer exprime un besoin de purification : se dÇbarrasser de|pensÇes encombrantes, d''une culpabilitÇ ou de relations usÇes. Le|',
  'ràve accompagne souvent une pÇriode de remise en ordre intÇrieure|et de recommencement.|Ouvrir une porte, une boåte ou une lettre symbolise l''accäs Ö une|',
  'possibilitÇ nouvelle et la curiositÇ envers l''inconnu. C''est|aussi le signe d''un esprit qui s''Çlargit ou d''un coeur pràt Ö|accueillir.|',
  'Se rÇveiller dans le ràve, et surtout vivre un faux rÇveil, rÇväle|une conscience qui affleure sous le sommeil. Le symbole parle de|prise de conscience : une rÇalitÇ que vous commencez Ö voir plus|',
  'clairement.|Savoir que l''on ràve pendant le ràve est une expÇrience|remarquable de conscience. Jung y aurait vu un dialogue direct|entre le moi et l''inconscient ; c''est une invitation Ö explorer|',
  'et Ö transformer vos scÇnarios intÇrieurs.|Un ràve qui revient insiste : l''inconscient rÇpäte un message|tant qu''il n''est pas entendu. Freud y voyait un conflit non|',
  'rÇsolu, Jung un thäme de vie en attente d''intÇgration. Ses|variations montrent votre Çvolution.|Le ràve prÇmonitoire fascine depuis l''AntiquitÇ. La psychologie y|',
  'voit surtout l''intuition : l''inconscient assemble des indices|peráus sans attention et anticipe une Çvolution probable, sans|rien fixer d''inÇluctable.|',
  'Le feu est un symbole ambivalent de passion, d''Çnergie et de|transformation. Il rÇchauffe, Çclaire et purifie, mais peut aussi|consumer ; il traduit souvent un dÇsir ardent ou une coläre qui|couve.|',
  'Le soleil figure la conscience, la vitalitÇ et le principe|paternel ; il Çclaire et fait mñrir toute chose. Il annonce|souvent la rÇussite, la clartÇ d''esprit et le rayonnement de|votre personnalitÇ.|',
  'La lune rägne sur la nuit, les ràves et les cycles ; elle|symbolise l''intuition, la fÇminitÇ et l''inconscient. Changeante,|elle rappelle que tout passe par des phases de croissance et de|dÇclin.|',
  'L''Çtoile est un symbole d''espoir, de destinÇe et de guidance :|elle brille màme dans la nuit la plus noire. Elle peut reprÇsenter|un idÇal, une vocation ou la part lumineuse et unique de votre|àtre.|',
  'Le ciel reprÇsente l''esprit, l''idÇal et l''infini des possibles|; il est le domaine des aspirations ÇlevÇes. Son aspect, clair ou|chargÇ, refläte fidälement votre humeur et votre Çtat d''esprit du|',
  'moment.|Les nuages Çvoquent les pensÇes, les ràveries et les Çtats d''Éme|qui passent. LÇgers, ils parlent d''imagination et de dÇtachement|; sombres, ils annoncent des prÇoccupations qui obscurcissent|',
  'votre horizon.|L''orage exprime une tension qui se dÇcharge : conflits, coläre ou|passion trop longtemps retenue. La foudre, arme des dieux, figure|',
  'aussi l''illumination soudaine, une rÇvÇlation qui change tout en|un instant.|La tempàte symbolise un bouleversement intÇrieur ou extÇrieur, une|',
  'pÇriode agitÇe oó les repäres vacillent. Elle exprime aussi|l''Çnergie du changement : apräs son passage, l''air est plus pur|et le paysage renouvelÇ.|',
  'Le vent est le souffle de l''esprit et du changement ; invisible,|il fait bouger ce qui Çtait figÇ. Il annonce des nouvelles, des|influences extÇrieures ou une transformation qui s''amorce dans|',
  'votre vie.|L''arc-en-ciel, pont entre le ciel et la terre, symbolise|l''alliance, la rÇconciliation et l''espoir apräs l''Çpreuve. Ses|couleurs rÇunies Çvoquent l''harmonie de la personnalitÇ et|',
  'l''intÇgration de ses multiples facettes.|La terre reprÇsente la märe nourriciäre, la matiäre, la stabilitÇ|et le retour au concret. Elle invite Ö garder les pieds sur terre|',
  '; on y enfouit les graines comme les secrets, en attendant qu''ils|germent.|Le tremblement de terre signale un bouleversement profond qui|',
  'Çbranle vos fondations : croyances, relations ou situation. S''il|inquiäte, il annonce souvent une restructuration nÇcessaire de|votre existence.|',
  'La nuit symbolise l''inconscient, le mystäre et le temps de la|gestation, oó tout repose avant de renaåtre. L''obscuritÇ peut|Çveiller des craintes, mais elle est aussi le lieu des ràves, de|',
  'l''intimitÇ et de l''intuition.|La lumiäre est symbole de conscience, de vÇritÇ et de connaissance|: elle dissipe l''ignorance et rÇväle ce qui Çtait cachÇ. Une|',
  'lumiäre intense peut figurer une expÇrience spirituelle ou une|prise de conscience dÇcisive.|L''aube marque la fin de la nuit et le retour de la lumiäre : elle|',
  'symbolise les commencements, l''espoir et la renaissance. Elle|annonce souvent un nouveau cycle, une idÇe neuve ou une prise de|conscience qui s''Çveille.|',
  'Le crÇpuscule figure la fin d''un cycle, le dÇclin d''une pÇriode|et le passage vers l''inconnu. Moment de bilan et de sagesse, il|invite Ö accepter ce qui s''achäve pour prÇparer sereinement ce|',
  'qui vient.|L''espace et les planätes symbolisent l''infini, l''inconnu et le|dÇsir de dÇpasser vos limites. Ils traduisent souvent une quàte de|',
  'sens, un besoin de recul ou d''ÇlÇvation, et parfois une distance|prise avec le quotidien.|L''Çclipse reprÇsente un effacement temporaire : une part de vous,|',
  'une relation ou un projet est momentanÇment occultÇe. Elle Çvoque|aussi la rencontre des contraires, conscient et inconscient,|masculin et fÇminin.|',
  'La fumÇe Çvoque ce qui est flou, ÇphÇmäre ou dissimulÇ : elle|voile la vision et s''Çvanouit. Signal d''un feu cachÇ, elle peut|annoncer une situation qui couve, mais aussi l''ÇlÇvation d''une|',
  'priäre ou d''un dÇsir.|La figure divine reprÇsente selon Jung l''image du Soi, centre et|totalitÇ de la psychÇ ; elle traduit une quàte de sens,|',
  'd''autoritÇ intÇrieure ou de rÇconciliation avec vos valeurs|profondes.|L''ange est un messager entre le visible et l''invisible ; il|personnifie l''intuition, la protection et la part lumineuse de|',
  'vous-màme qui cherche Ö vous guider vers un choix juste.|Le dÇmon figure l''Ombre jungienne : pulsions, dÇsirs ou coläres|que vous refusez de reconnaåtre. Le ràve ne vous accuse pas ; il|',
  'vous invite Ö regarder en face ce que vous tenez Ö distance.|Le fantìme Çvoque un passÇ non rÇsolu qui revient hanter le|prÇsent : souvenir, regret, relation inachevÇe. Il matÇrialise ce|',
  'qui demande encore Ö àtre reconnu, dit ou pardonnÇ.|Prier en ràve exprime un besoin de soutien, d''Çcoute ou de|lÉcher-prise face Ö ce qui vous dÇpasse. C''est aussi un dialogue|',
  'avec votre voix intÇrieure et vos aspirations les plus sincäres.|L''Çglise est un lieu de recueillement, de communautÇ et de|tradition. Elle renvoie Ö vos valeurs hÇritÇes, Ö votre rapport Ö|',
  'la rägle et au besoin d''un refuge oó vous ressourcer.|Le temple symbolise l''espace sacrÇ intÇrieur, ce sanctuaire de la|psychÇ oó se rencontrent le conscient et l''inconscient. Il|',
  'appelle Ö honorer ce qui compte vraiment pour vous.|La croix unit la verticale du spirituel et l''horizontale du|terrestre. Elle Çvoque Ö la fois l''Çpreuve que l''on porte et la|',
  'foi qui permet de la traverser, parfois aussi un tournant dÇcisif.|Le pràtre incarne l''autoritÇ spirituelle et morale,|l''intermÇdiaire avec le sacrÇ. Il peut reprÇsenter votre|',
  'conscience, un besoin de conseil ou l''influence d''une figure|paternelle sur vos choix.|Le moine reprÇsente le retrait, la discipline et la recherche|',
  'intÇrieure. Il signale un besoin de silence, de simplicitÇ ou de|solitude choisie pour vous retrouver loin du bruit du monde.|Le paradis exprime la nostalgie d''un Çtat d''harmonie parfaite,|',
  'souvent celui de l''enfance ou de la fusion originelle. Il refläte|vos aspirations Ö la paix et Ö la plÇnitude.|L''enfer met en scäne une souffrance intÇrieure, une culpabilitÇ|',
  'ou un conflit brñlant. Plus qu''un chÉtiment, il dÇsigne une|descente dans les profondeurs dont on peut ressortir transformÇ.|Le miracle traduit l''espoir d''un dÇnouement inespÇrÇ et la|',
  'croyance en des forces qui dÇpassent la raison. Il signale aussi|des ressources intÇrieures insoupáonnÇes, pràtes Ö se manifester.|L''autel est le lieu de l''offrande et de l''engagement. Il|',
  'indique ce que vous àtes pràt Ö consacrer ou Ö sacrifier pour un|idÇal, une relation ou un projet qui vous tient Ö coeur.|MÇditer en ràve signale un besoin d''apaisement, de recentrage et|',
  'd''Çcoute de soi. L''inconscient vous invite Ö ralentir pour mieux|percevoir ce qui se joue en profondeur dans votre vie.|Le guide spirituel est une figure du Vieux Sage jungien : il|',
  'personnifie la sagesse de l''inconscient, qui apparaåt lorsque|vous avez besoin d''orientation. Ses paroles mÇritent d''àtre|notÇes au rÇveil.|',
  'Consulter un voyant refläte le dÇsir de connaåtre l''avenir et de|rÇduire l''incertitude. Le personnage incarne souvent votre propre|intuition, qui peráoit dÇjÖ ce que la raison n''ose formuler.|',
  'Le pälerinage figure un cheminement intÇrieur vers un but qui|donne sens Ö l''existence. Chaque Çtape symbolise un effort, une|purification ou une maturation sur la voie de la connaissance de|soi.|',
  'Le cercle, sans dÇbut ni fin, symbolise la totalitÇ, la perfection|et la protection. Pour Jung, le mandala exprime le Soi et|l''unification de la personnalitÇ, souvent en pÇriode de|',
  'rÇorganisation intÇrieure.|L''Éme reprÇsente votre essence la plus intime, ce qui demeure|au-delÖ des rìles et des apparences. Ràver de son Éme ou d''une|',
  'vie antÇrieure invite Ö interroger le sens profond de votre|existence.|La bÇnÇdiction exprime la reconnaissance, la protection et|l''autorisation d''avancer. La recevoir en ràve, c''est souvent|',
  'obtenir l''accord intÇrieur ou parental qui vous manquait|jusque-lÖ.|En onirologie, la mort annonce rarement une fin rÇelle : elle|marque la clìture d''un cycle, d''une habitude ou d''une Çtape de|',
  'vie. La tradition y voit màme un prÇsage de renouveau et de|longÇvitÇ.|Mourir soi-màme en ràve signifie qu''une partie de vous se|transforme : un ancien rìle, une identitÇ ou une croyance|',
  's''efface pour laisser place Ö une version plus mñre de vous-màme.|Le cadavre reprÇsente ce qui est mort en vous sans avoir ÇtÇ|enterrÇ : relation finie, projet abandonnÇ, Çmotion refoulÇe. Il|',
  'demande Ö àtre reconnu pour que vous puissiez passer Ö autre|chose.|Le cercueil contient ce que l''on enferme pour le laisser derriäre|soi. Il Çvoque la fin d''une pÇriode, mais aussi des sentiments|',
  'mis en boåte que l''on prÇfäre ne plus voir plutìt que de les|vivre.|L''enterrement symbolise un adieu nÇcessaire : vous enterrez une|Çpoque, une illusion ou une relation. C''est un rite de passage|',
  'qui permet au deuil de s''accomplir et Ö une vie nouvelle de|commencer.|Le cimetiäre est le domaine de la mÇmoire et des ancàtres. Il|invite Ö mÇditer sur votre histoire, vos racines et ce que le|',
  'passÇ vous a transmis, sans pour autant y demeurer enfermÇ.|Le tombeau garde ce qui a ÇtÇ scellÇ : souvenirs, secrets ou|potentiels laissÇs en sommeil. Selon qu''il est fermÇ ou ouvert,|',
  'il Çvoque le repos du passÇ ou le retour de ce qui avait ÇtÇ|enfoui.|Le squelette rÇduit l''àtre Ö sa structure essentielle. Il|symbolise ce qui reste quand tout le superflu est tombÇ, mais|',
  'aussi les secrets cachÇs, les fameux Æ squelettes dans le placard|Ø.|La naissance annonce l''Çclosion d''un projet, d''une idÇe ou|d''une nouvelle facette de votre personnalitÇ. C''est l''un des|',
  'symboles les plus favorables du ràve, celui d''un commencement|plein de promesses.|La rÇsurrection exprime la capacitÇ de renaåtre apräs une Çpreuve.|',
  'Elle signale le retour d''une Çnergie, d''un espoir ou d''une part|de vous-màme que vous pensiez dÇfinitivement perdue.|Revoir un proche disparu exprime le lien affectif qui demeure et|',
  'le travail du deuil. Le dÇfunt apporte souvent un message, un|conseil ou l''occasion de dire ce qui n''a pas pu àtre dit.|La vieillesse reprÇsente la sagesse, l''expÇrience et le bilan|',
  'd''une vie. Se voir vieillir en ràve traduit souvent une prise de|maturitÇ, ou une rÇflexion sur le temps qui passe et vos|prioritÇs.|La mÇtamorphose illustre une transformation profonde de|',
  'l''identitÇ, Ö l''image de la chenille devenant papillon. Elle|accompagne les pÇriodes de mue oó l''ancien moi cäde la place Ö un|àtre nouveau.|',
  'Le sang est le symbole de la force vitale, de la passion et des|liens familiaux. Selon le contexte, il Çvoque l''Çnergie et la|vitalitÇ, ou bien une perte de forces et une blessure affective|',
  'encore vive.|L''hÇritage dÇsigne ce que vous transmettent vos parents et|ancàtres : talents, valeurs, mais aussi blessures et schÇmas|familiaux. Le ràve invite Ö trier ce que vous gardez et ce que|',
  'vous laissez.|Manger en ràve renvoie aux besoins fondamentaux : se nourrir, àtre|comblÇ, recevoir de l''affection. Freud y voyait l''expression du|',
  'dÇsir et du plaisir oral ; la nature des aliments prÇcise ce qui|vous manque ou vous satisfait.|Le pain, nourriture essentielle, symbolise la subsistance, le|',
  'travail rÇcompensÇ et le partage. SacrÇ dans de nombreuses|traditions, il Çvoque aussi la communion, la gÇnÇrositÇ et la|sÇcuritÇ du foyer.|',
  'Le fruit est l''aboutissement d''une croissance : il symbolise la|rÇcompense, la fÇconditÇ et les plaisirs des sens. Mñr et sucrÇ,|il Çvoque la sensualitÇ ; selon Freud, il peut aussi figurer le|',
  'dÇsir et la tentation.|La pomme est le fruit de la connaissance et de la tentation,|depuis le jardin d''êden. Elle symbolise le dÇsir, la sÇduction et|',
  'le choix ; ronde et pleine, elle figure aussi la totalitÇ, la|santÇ et l''Çternelle jeunesse.|Le gÉteau est associÇ Ö la fàte, Ö la rÇcompense et Ö la douceur|',
  'de vivre ; il rappelle souvent l''enfance et les anniversaires. Il|exprime le dÇsir d''àtre gÉtÇ, reconnu ou de cÇlÇbrer une Çtape|importante.|',
  'Le chocolat Çvoque la gourmandise, la consolation et le plaisir|sensuel. Il traduit souvent un besoin de rÇconfort et de douceur,|ou un dÇsir de vous accorder une rÇcompense apräs une pÇriode|',
  'd''effort.|Le lait, premier aliment, symbolise la nourriture maternelle, la|tendresse et la sÇcuritÇ affective. Il peut exprimer un besoin|',
  'd''àtre protÇgÇ et choyÇ, ou au contraire votre capacitÇ Ö prendre|soin des autres.|Le vin est symbole de fàte, de convivialitÇ et d''ivresse sacrÇe ;|',
  'dans de nombreuses traditions, il est liÇ Ö la connaissance et Ö|la transformation. L''alcool exprime aussi le dÇsir de lÉcher|prise ou d''oublier.|',
  'La viande renvoie aux instincts, Ö la force physique et aux dÇsirs|charnels. Elle exprime un besoin de vitalitÇ et d''Çnergie, ou une|part brute et animale de vous-màme qui demande Ö àtre reconnue.|',
  'L''oeuf contient la vie en germe : il symbolise la naissance, le|potentiel et la totalitÇ originelle. Il annonce souvent un projet|en gestation, une idÇe qui mñrit ou une part de vous qui attend le|',
  'moment d''Çclore.|Le miel symbolise la douceur, l''abondance et la rÇcompense d''un|travail patient. Nourriture des dieux dans l''AntiquitÇ, il Çvoque|',
  'aussi la sagesse, l''amour tendre et les paroles qui apaisent.|Le banquet et la fàte cÇläbrent l''abondance, la convivialitÇ et|la rÇussite partagÇe. Ils expriment le besoin d''appartenance et|',
  'de reconnaissance sociale, ou l''envie de marquer une victoire et|un passage.|Avoir faim en ràve exprime un manque, un besoin non satisfait sur|',
  'le plan affectif, intellectuel ou matÇriel. Ce dÇsir inassouvi|dÇsigne aussi une ambition, une curiositÇ ou un appÇtit de vivre|en Çveil.|',
  'Les lÇgumes, nÇs de la terre, symbolisent la santÇ, la simplicitÇ|et le travail patient. Ils Çvoquent une vie saine et ÇquilibrÇe,|le retour Ö l''essentiel et parfois un souci de prendre davantage|',
  'soin de votre corps.|Le sel conserve, purifie et donne de la saveur : il symbolise la|sagesse, la fidÇlitÇ et l''essentiel de l''existence. Partager le|',
  'sel scelle l''amitiÇ ; mais en excäs, il Çvoque l''amertume ou les|larmes.|Le cafÇ et les boissons chaudes Çvoquent l''Çveil, la stimulation|intellectuelle et la sociabilitÇ. Partager un cafÇ traduit le|',
  'besoin de dialogue et de chaleur humaine ; boire seul invite Ö une|pause rÇflexive.|Les bonbons rappellent l''enfance, les petites rÇcompenses et les|',
  'plaisirs immÇdiats. Ils traduisent un besoin de douceur et de|lÇgäretÇ, parfois une envie de rÇgresser vers un temps insouciant|et protÇgÇ.|',
  'La nourriture avariÇe signale quelque chose qui a ÇtÇ gardÇ trop|longtemps : un ressentiment, une relation usÇe ou une habitude qui|ne vous nourrit plus. Elle invite Ö faire le tri pour retrouver ce|',
  'qui est sain.|La soif exprime un dÇsir profond, souvent affectif ou spirituel :|soif d''amour, de connaissance ou de sens. Boire en ràve figure|',
  'l''acte de recevoir, d''intÇgrer une Çmotion ou une vÇritÇ dont|vous avez besoin.|L''argent symbolise l''Çnergie, la valeur personnelle et le|pouvoir d''agir. Freud le rapprochait des premiers enjeux de|',
  'rÇtention et de don ; en ràve, il parle souvent de ce que vous|estimez valoir ou de ce que vous Çchangez.|Les piäces Çvoquent les petites valeurs du quotidien, les Çchanges|',
  'modestes mais rÇels. Selon la tradition, des piäces brillantes|promettent des gains ; en psychologie, elles figurent les|ressources accumulÇes pas Ö pas.|',
  'Le trÇsor est l''image du bien le plus prÇcieux, souvent cachÇ ou|difficile Ö atteindre. Pour Jung, il symbolise le Soi : la|richesse intÇrieure dÇcouverte au terme d''une quàte, parfois|',
  'gardÇe par des Çpreuves ou un dragon.|L''or, mÇtal solaire et inaltÇrable, incarne la valeur supràme, la|puretÇ et la rÇussite. Dans l''alchimie chäre Ö Jung, il est le|',
  'but de l''Oeuvre : la transformation du plomb intÇrieur en|conscience lumineuse.|La banque reprÇsente la sÇcuritÇ matÇrielle, l''Çpargne et la|gestion de vos ressources, qu''elles soient financiäres,|',
  'affectives ou ÇnergÇtiques. Elle Çvoque aussi l''autoritÇ, les|rägles et la confiance accordÇe aux institutions.|Ràver de faillite exprime la peur de l''Çchec ou de l''Çpuisement|',
  'de vos ressources, matÇrielles ou intÇrieures. C''est un ràve|d''alerte plutìt qu''un prÇsage : il invite Ö revoir vos prioritÇs|et vos dÇpenses d''Çnergie.|',
  'Le travail en ràve refläte votre rapport Ö l''effort, Ö l''utilitÇ|sociale et Ö l''accomplissement. Il prolonge souvent les|prÇoccupations du jour, mais dit aussi la maniäre dont vous|',
  'trouvez du sens Ö ce que vous faites.|Le bureau est le lieu de votre rìle social et de votre Persona|professionnelle. Son aspect, rangÇ ou encombrÇ, refläte l''ordre|',
  'de vos pensÇes et la place que vous accordez aux obligations dans|votre existence.|Le patron incarne l''autoritÇ, la rägle et le jugement extÇrieur ;|',
  'il rappelle souvent la figure paternelle. Ràver de lui interroge|votre rapport au pouvoir, Ö la hiÇrarchie et Ö votre propre|ambition de diriger.|',
  'Un collägue en ràve reprÇsente votre vie sociale au travail, mais|aussi une qualitÇ qu''il incarne et qui vous concerne. Selon Jung,|il peut figurer un trait que vous admirez ou rejetez chez|',
  'vous-màme.|La rÇunion symbolise la confrontation des points de vue, la|dÇcision collective et votre place dans le groupe. Elle peut aussi|',
  'figurer le dialogue intÇrieur entre les diffÇrentes voix de votre|personnalitÇ.|Se voir licenciÇ en ràve exprime l''insÇcuritÇ, la peur d''àtre|',
  'rejetÇ ou de perdre votre utilitÇ. Le ràve peut aussi rÇvÇler un|dÇsir secret de quitter un rìle qui ne vous convient plus et|d''ouvrir une nouvelle voie.|',
  'L''entretien d''embauche est un ràve d''Çvaluation et de|prÇsentation de soi : vous cherchez Ö prouver votre valeur. Il|interroge l''image que vous donnez et l''Çcart entre votre Persona|',
  'et ce que vous àtes vraiment.|Le contrat symbolise l''engagement, la parole donnÇe et les rägles|d''une relation, professionnelle ou affective. Signer en ràve|',
  'marque un accord avec vous-màme ou avec autrui, et la volontÇ de|vous lier durablement.|Acheter exprime le dÇsir d''acquÇrir ce qui vous manque : un|',
  'objet, une qualitÇ, une reconnaissance. Ce que vous achetez parle|de vos besoins profonds ; le prix payÇ dit l''effort que vous àtes|pràt Ö consentir.|',
  'Vendre symbolise l''Çchange et le dÇtachement : vous cÇdez quelque|chose pour obtenir autre chose. Le ràve peut parler de votre|capacitÇ Ö mettre en valeur vos talents, ou d''un renoncement|',
  'devenu nÇcessaire.|La dette exprime un sentiment d''obligation, matÇrielle ou morale|: quelque chose reste dñ, Ö autrui ou Ö vous-màme. Elle peut|',
  'traduire une culpabilitÇ, une promesse en suspens ou un Çquilibre|relationnel rompu.|La richesse onirique reprÇsente l''abondance, mais surtout la|',
  'plÇnitude intÇrieure : talents, affection, vitalitÇ. Freud y|lisait volontiers un dÇsir de rÇussite et de puissance, Jung|l''accäs aux ressources du Soi.|',
  'La pauvretÇ en ràve exprime un sentiment de manque, matÇriel ou|affectif, et parfois une faible estime de soi. Paradoxalement,|l''onirologie traditionnelle y voit aussi l''annonce d''un|',
  'retournement favorable.|Les vàtements reprÇsentent la Persona, le masque social que l''on|offre aux autres. Leur style, leur Çtat et leur ajustement|',
  'rÇvälent la faáon dont vous vous percevez et souhaitez àtre peráu.|Les chaussures symbolisent votre faáon d''avancer dans la vie,|votre ancrage et votre position sociale. Changer de chaussures|',
  'annonce une nouvelle direction ; en perdre une Çvoque une identitÇ|en question.|La robe Çvoque la fÇminitÇ, la sÇduction et l''image que l''on|',
  'souhaite offrir. Selon sa couleur et sa coupe, elle rÇväle une|faáon d''assumer sa sensualitÇ, son ÇlÇgance ou un rìle social|particulier.|',
  'La robe de mariÇe symbolise l''engagement, la puretÇ et le passage|Ö une nouvelle Çtape de vie. Elle peut exprimer un dÇsir d''union,|mais aussi une alliance intÇrieure entre deux aspects de|vous-màme.|',
  'Le chapeau couvre la tàte : il symbolise les idÇes, l''autoritÇ et|le rìle que l''on endosse. Changer de chapeau, c''est changer de|fonction ou d''opinion ; il protäge aussi les pensÇes du regard|',
  'd''autrui.|Le manteau symbolise la protection, la chaleur et le besoin de se|couvrir face au monde. Il peut aussi cacher ce qu''on ne veut pas|montrer ; dans les contes, le manteau confäre dignitÇ ou|',
  'invisibilitÇ.|L''uniforme reprÇsente l''appartenance Ö un groupe, la discipline|et le rìle social imposÇ. Il interroge l''Çquilibre entre votre|',
  'individualitÇ et les rägles collectives, entre devoir et libertÇ.|Le dÇguisement rÇväle le dÇsir de jouer un autre rìle, d''explorer|une facette cachÇe ou d''Çchapper Ö son identitÇ. Le personnage|',
  'choisi en dit long sur vos aspirations et sur ce que vous|dissimulez.|Les sous-vàtements touchent Ö l''intime : ils rÇvälent ce que|l''on cache d''ordinaire, la sexualitÇ et la vulnÇrabilitÇ. Se|',
  'montrer ainsi en public exprime la peur d''àtre exposÇ ou jugÇ.|Le maquillage symbolise l''image que l''on compose, la sÇduction|et le dÇsir d''embellir ou de dissimuler. Il interroge le rapport|',
  'entre votre apparence et votre vÇritÇ intÇrieure.|Les lunettes reprÇsentent la maniäre dont vous percevez la rÇalitÇ|et votre besoin de clartÇ. Elles signalent une volontÇ de mieux|',
  'comprendre une situation ou, au contraire, un regard qui dÇforme|les choses.|Les vàtements sales ou dÇchirÇs reflätent une image de soi abåmÇe,|',
  'une culpabilitÇ ou la crainte du jugement. Laver son linge sale,|c''est aussi rÇgler des conflits ou des secrets embarrassants.|Le couple ràvÇ refläte l''Çtat de votre vie affective et, plus|',
  'profondÇment, l''union intÇrieure des contraires que Jung voyait|dans l''alliance de l''Anima et de l''Animus. Il parle|d''attachement, de confiance et de partage.|',
  'Le baiser scelle l''union, l''affection et l''Çchange intime ; il|peut aussi signifier une rÇconciliation ou un pacte. Embrasser|quelqu''un d''inattendu rÇväle souvent une qualitÇ de cette|',
  'personne que vous souhaitez intÇgrer.|L''amant incarne la passion, la nouveautÇ et le dÇsir libÇrÇ des|contraintes. Plus qu''une envie d''aventure, il rÇväle souvent un|',
  'besoin de vitalitÇ, de reconnaissance ou de crÇativitÇ dans votre|vie.|Le mariage symbolise l''union des contraires, l''engagement et le|passage Ö une nouvelle Çtape. Pour Jung, il figure les noces|',
  'intÇrieures du conscient et de l''inconscient ; l''engagement|annoncÇ n''est pas forcÇment amoureux.|La rupture ràvÇe parle de sÇparation et de fin de cycle, pas|',
  'forcÇment amoureuse : une habitude, une croyance ou une Çpoque se|termine. Elle exprime aussi la peur de l''abandon et le besoin de|redÇfinir vos liens.|',
  'Ràver d''infidÇlitÇ exprime plus souvent une insÇcuritÇ ou un|sentiment de dÇlaissement qu''une rÇalitÇ. Selon Freud, le ràve|peut aussi accomplir un dÇsir de nouveautÇ ; il signale un besoin|',
  'd''attention dans le lien.|L''ex-partenaire en ràve traduit rarement un dÇsir de retour : il|incarne une pÇriode, une part de vous ou une leáon affective|',
  'encore en cours d''intÇgration, souvent rÇveillÇe par une|situation actuelle.|La sexualitÇ onirique exprime l''Çnergie vitale, le dÇsir d''union|',
  'et la crÇativitÇ. Freud y voyait l''accomplissement de souhaits|refoulÇs, Jung une union des opposÇs ; le partenaire ràvÇ figure|souvent une qualitÇ Ö intÇgrer.|',
  'L''Çtreinte exprime le besoin de sÇcuritÇ, de tendresse et de|rÇconciliation. Elle rappelle les premiers liens avec la märe et|symbolise l''accueil d''une personne, ou d''une part de vous, que|',
  'vous acceptez pleinement.|Le rendez-vous galant traduit l''attente, l''espoir et le dÇsir de|rencontre, mais aussi un rendez-vous avec vous-màme. Sa rÇussite|',
  'ou son Çchec refläte votre confiance face Ö la nouveautÇ et Ö|l''inconnu affectif.|Les fianáailles symbolisent une promesse, un engagement en|',
  'prÇparation et la confiance accordÇe Ö l''avenir. Elles peuvent|concerner l''amour comme un projet, une association ou une|dÇcision qui se dessine.|',
  'Le divorce ràvÇ signale une sÇparation intÇrieure : deux aspects|de vous qui ne s''accordent plus, ou une situation dont vous|souhaitez vous dÇtacher. Il ne prÇdit pas la fin d''un couple rÇel|',
  'mais invite Ö clarifier vos choix.|La sÇduction exprime le dÇsir de plaire, d''àtre reconnu et|d''exercer une influence. Selon le rìle tenu, sÇducteur ou sÇduit,|',
  'elle rÇväle votre confiance en votre charme ou votre rÇceptivitÇ|au dÇsir d''autrui.|Le coup de foudre traduit l''irruption soudaine de l''inconscient|',
  ': une projection de l''Anima ou de l''Animus sur un visage qui|vous saisit. Il annonce souvent un enthousiasme neuf, pour une|personne, une idÇe ou une vocation.|',
  'Le blanc est la couleur de la puretÇ, de l''innocence et des|commencements ; il rÇunit toutes les couleurs de la lumiäre. Dans|certaines cultures, il est aussi celle du deuil, signe d''un|',
  'passage vers un autre Çtat.|Le noir est la couleur de l''inconnu, de l''ombre et du deuil,|mais aussi de la gestation et de la profondeur. Il signale souvent|',
  'un aspect de vous encore inconscient, qui attend d''àtre reconnu|avant de se transformer.|Le rouge est la couleur du sang, de la vie et de la passion : il|',
  'exprime l''Çnergie vitale, le dÇsir amoureux et l''action.|Intense, il peut aussi signaler la coläre, l''alerte ou une|Çmotion Ö fleur de peau.|Le bleu, couleur du ciel et des eaux profondes, Çvoque la|',
  'sÇrÇnitÇ, la spiritualitÇ et la vÇritÇ. Il traduit un besoin de|calme, de recul ou d''ÇlÇvation ; träs sombre, il peut aussi|signaler une mÇlancolie.|',
  'Le vert, couleur de la vÇgÇtation, symbolise la croissance, la|guÇrison et l''espÇrance. Il Çvoque l''Çquilibre retrouvÇ et la|vitalitÇ de la nature ; dans un contexte trouble, il peut aussi|',
  'exprimer l''immaturitÇ ou la jalousie.|Le jaune, couleur du soleil et de l''or, Çvoque l''intelligence,|la joie de vivre et le rayonnement. Il stimule l''esprit et la|',
  'communication ; terne ou criard, il Çtait traditionnellement|associÇ Ö la jalousie ou Ö la trahison.|L''orange, mÇlange du rouge et du jaune, associe l''Çnergie Ö la|',
  'joie : il exprime l''enthousiasme, la crÇativitÇ et la|sociabilitÇ. Couleur chaleureuse, il invite Ö l''ouverture aux|autres et aux plaisirs de la vie.|',
  'Le violet unit le rouge de la passion et le bleu de l''esprit : il|symbolise la spiritualitÇ, l''intuition et la transformation|intÇrieure. Couleur de la tempÇrance et du mystäre, il Çvoque|',
  'aussi la noblesse.|Le gris, entre le blanc et le noir, Çvoque la neutralitÇ,|l''indÇcision et la retenue. Il peut traduire une pÇriode terne ou|',
  'un manque d''Çlan, mais aussi la maturitÇ, la prudence et la|sagesse du juste milieu.|Le dorÇ, reflet de l''or et du soleil, symbolise la valeur, la|',
  'rÇussite et l''illumination spirituelle. En alchimie, il figure|l''aboutissement du Grand Oeuvre : la part la plus prÇcieuse et la|plus accomplie de vous-màme.|',
  'Le un est le nombre de l''unitÇ, de l''origine et de|l''affirmation de soi. Il symbolise le commencement, l''initiative|et l''individualitÇ ; en ràve, il invite Ö oser une premiäre Çtape|',
  'ou Ö vous affirmer.|Le deux exprime la dualitÇ, la rencontre et le couple : il est le|nombre de l''autre, du dialogue et de l''association. Il signale|',
  'aussi les oppositions intÇrieures, un choix Ö faire entre deux|voies ou deux dÇsirs.|Le trois est le nombre de la synthäse et de la crÇation : il|',
  'rÇunit deux opposÇs en un troisiäme terme. AssociÇ Ö la famille et|Ö la trinitÇ, il symbolise l''harmonie, la fÇconditÇ et|l''expression de soi.|',
  'Le quatre Çvoque la stabilitÇ, l''ordre et la matiäre : quatre|ÇlÇments, quatre saisons, quatre points cardinaux. Pour Jung, il|est le nombre de la totalitÇ psychique et de l''Çquilibre entre|',
  'les fonctions de l''esprit.|Le cinq, nombre des sens et des doigts de la main, symbolise|l''àtre humain, le mouvement et la libertÇ. Il annonce souvent un|',
  'changement, une aventure ou le dÇsir d''expÇrimenter la vie avec|tous vos sens.|Le six est le nombre de l''harmonie, de l''amour et de la|',
  'responsabilitÇ envers les autres. Symbole d''union des contraires,|comme l''Çtoile Ö six branches, il Çvoque le foyer, l''entraide et|la beautÇ.|',
  'Le sept est un nombre sacrÇ dans de nombreuses traditions : sept|jours, sept notes, sept couleurs. Il symbolise l''accomplissement|d''un cycle, la sagesse et la quàte spirituelle, et passe pour un|',
  'nombre chanceux.|Le huit, dont la forme Çvoque l''infini, symbolise l''Çquilibre|entre le matÇriel et le spirituel, la puissance et la justice. Il|',
  'est associÇ Ö la rÇussite, Ö la prospÇritÇ et aux cycles de la|vie.|Le neuf, dernier des chiffres, marque l''achävement d''un cycle|avant un renouveau ; il rappelle aussi les neuf mois de la|',
  'gestation. Il symbolise la sagesse, la compassion et|l''aboutissement d''une longue maturation.|Le dix exprime la totalitÇ accomplie et le retour Ö l''unitÇ Ö un|',
  'niveau supÇrieur. Il Çvoque la plÇnitude, la rÇussite et la|perfection d''un ensemble, ainsi que le dÇbut d''un nouveau cycle|plus riche.|',
  'Le douze symbolise l''ordre cosmique et l''accomplissement : douze|mois, douze signes du zodiaque, douze heures. Il Çvoque une|totalitÇ harmonieuse, la fin d''un grand cycle et une organisation|',
  'juste de votre vie.|Le treize, rÇputÇ malchanceux, est surtout le nombre de la rupture|et du renouveau : il dÇpasse l''ordre parfait du douze. Il annonce|',
  'un changement inattendu, la fin d''une situation et l''ouverture|vers autre chose.|La guerre met en scäne un conflit intÇrieur intense entre des|',
  'dÇsirs, des devoirs ou des parts opposÇes de vous-màme. Elle peut|aussi reflÇter des tensions bien rÇelles au travail ou en famille.|L''explosion figure une tension accumulÇe qui finit par Çclater :|',
  'Çmotions longtemps contenues, frustration, coläre. Elle signale|aussi un changement soudain qui bouleverse un Çquilibre trop|rigide.|L''arme Ö feu Çvoque le pouvoir, l''agressivitÇ et la volontÇ de|',
  's''imposer Ö distance. Freud y voyait un symbole viril ; elle|traduit souvent un dÇsir de contrìle ou de dÇfense face Ö une|menace ressentie.|',
  'Subir une attaque en ràve exprime un sentiment d''agression,|rÇelle ou intÇrieure : critiques, pressions, ou pulsions que vous|refusez de reconnaåtre et que vous projetez sur un assaillant.|',
  'Le meurtre symbolise le dÇsir d''en finir avec quelque chose : une|habitude, une relation ou un aspect de vous-màme. Tuer en ràve|n''est pas un souhait rÇel, mais l''expression d''une rupture|',
  'intÇrieure radicale.|La bagarre refläte une confrontation directe, un dÇsaccord que|vous n''osez peut-àtre pas exprimer Ö l''Çtat de veille. Elle met|',
  'en lumiäre une Çnergie combative en quàte d''expression.|L''incendie est une passion ou une coläre qui Çchappe au contrìle|et menace ce qui vous est cher. Mais le feu purifie aussi : il|',
  'dÇtruit l''ancien pour permettre une reconstruction sur des bases|neuves.|L''accident traduit une perte de maåtrise, un choc ou un conflit|',
  'soudain entre deux directions. Il invite Ö ralentir et Ö vÇrifier|si vous menez votre vie Ö un rythme qui vous convient vraiment.|La catastrophe exprime le sentiment d''àtre submergÇ par des|',
  'ÇvÇnements qui dÇpassent votre contrìle. Elle accompagne souvent|les grands bouleversements, qui dÇtruisent l''ordre ancien avant|d''en bÉtir un neuf.|',
  'L''enlävement figure le sentiment d''àtre dÇpossÇdÇ de votre|libertÇ ou de votre volontÇ, emportÇ par une situation, une|personne ou une obligation qui dÇcide Ö votre place.|',
  'La menace exprime une inquiÇtude diffuse, la sensation qu''un|danger plane sans àtre encore nommÇ. Elle peut signaler une|pression extÇrieure, ou une part de vous qui rÇclame d''àtre|entendue.|',
  'Le cambriolage Çvoque une intrusion dans votre intimitÇ :|quelqu''un ou quelque chose empiäte sur votre espace, votre temps|ou votre Çnergie. Il traduit aussi la crainte de perdre ce qui|',
  'vous est prÇcieux.|Le poison symbolise une influence nocive qui agit en secret :|pensÇes nÇgatives, relation toxique, rancune ou mensonge. Le ràve|',
  'vous invite Ö repÇrer ce qui contamine lentement votre bien-àtre.|L''effondrement d''un bÉtiment ou d''un sol figure la remise en|cause des fondations de votre vie : croyances, sÇcuritÇ, situation|',
  'professionnelle. Ce qui s''Çcroule laisse place Ö des bases plus|solides.|L''alarme est un signal d''alerte de l''inconscient : quelque|chose exige votre attention immÇdiate dans votre santÇ, vos|',
  'relations ou votre travail. Il s''agit d''un avertissement, non|d''une fatalitÇ.|Le terroriste incarne une violence aveugle et imprÇvisible,|',
  'souvent le reflet de pulsions refoulÇes ou d''une anxiÇtÇ face Ö|un monde peráu comme instable. Il menace votre sÇcuritÇ|intÇrieure.|Se retrouver pris en otage traduit le sentiment d''àtre prisonnier|',
  'd''une situation, d''une relation ou d''un engagement dont vous ne|pouvez sortir librement. Le ràve interroge ce qui vous retient et|Ö quel prix.|',
  'Le danger en ràve met en scäne une vigilance de l''inconscient|face Ö un risque rÇel ou imaginaire. Il souligne souvent une prise|de risque, une imprudence ou une situation qui vous fragilise.|',
  'Le monstre personnifie une peur ou une pulsion refoulÇe qui a pris|une forme dÇmesurÇe. Selon Jung, c''est l''Ombre : affronter le|monstre ou lui parler permet souvent de rÇcupÇrer une Çnergie|perdue.|',
  'Le dragon garde le trÇsor : il symbolise l''obstacle majeur entre|vous et votre potentiel. En Occident, le hÇros doit le vaincre ;|en Orient, il est une force cÇleste de sagesse et de prospÇritÇ.|',
  'La fÇe incarne le merveilleux, les dons et la capacitÇ d''exaucer|les voeux. Elle figure l''intuition et la part de magie de|l''existence, et parfois l''Anima, guide bienveillante vers vos|',
  'dÇsirs profonds.|La licorne symbolise la puretÇ, l''innocence et l''idÇal. Les|lÇgendes disent que seule une Éme pure peut l''approcher : elle|figure une quàte spirituelle, un ràve prÇcieux ou un amour|',
  'idÇalisÇ.|L''extraterrestre reprÇsente l''Çtranger absolu : ce qui, en vous|ou autour de vous, semble incomprÇhensible. Il traduit souvent un|',
  'sentiment de dÇcalage, ou la rencontre avec des idÇes radicalement|nouvelles.|La sorciäre incarne la Märe nÇgative des contes, mais aussi la|',
  'femme sage, guÇrisseuse et libre. Elle reprÇsente un pouvoir|fÇminin redoutÇ, l''intuition et la connaissance des secrets de la|nature.|Le vampire symbolise ce qui Çpuise votre Çnergie : une relation|',
  'toxique, une dÇpendance, un passÇ qui vous vide. Figure Çrotique|ambiguâ, il màle aussi la sÇduction, la mort et la peur de|l''intimitÇ.|Le zombie reprÇsente une vie vÇcue en automate, sans dÇsir ni|',
  'conscience. Il peut figurer l''Çpuisement, la routine ou un passÇ|mort qui revient hanter le prÇsent, et invite Ö vous rÇveiller Ö|vous-màme.|',
  'Le loup-garou exprime la dualitÇ entre la personne civilisÇe et la|bàte intÇrieure. Il figure une coläre ou un dÇsir qui surgit|malgrÇ vous, cette Ombre jungienne qui se rÇväle aux nuits de|',
  'pleine lune.|Le gÇant Çvoque la puissance dÇmesurÇe et, souvent, le regard de|l''enfant sur les adultes. Il peut figurer une figure parentale,|',
  'un obstacle Çcrasant ou, Ö l''inverse, vos propres capacitÇs|insoupáonnÇes.|Le lutin est un esprit malicieux du foyer et de la nature, Ö la|fois serviable et farceur. Figure du Fripon, il incarne|',
  'l''imprÇvu, l''humour et les petits dÇsordres qui bousculent vos|habitudes.|Le robot symbolise l''automatisme, la froideur et la logique sans|',
  'Çmotion. Il peut rÇvÇler une part de vous qui agit mÇcaniquement,|ou la crainte d''àtre remplacÇ, contrìlÇ ou rÇduit Ö une fonction.|Disposer de superpouvoirs exprime un dÇsir de toute-puissance, de|',
  'reconnaissance ou de rÇparation. C''est aussi l''image de|ressources inexploitÇes : l''inconscient vous montre ce que vous|àtes capable d''accomplir.|',
  'Devenir invisible traduit soit le dÇsir d''Çchapper au regard des|autres, soit la souffrance de ne pas àtre reconnu. Ce ràve|interroge votre place au sein du groupe et votre rapport Ö|',
  'l''attention d''autrui.|Voyager dans le temps rÇväle votre rapport au passÇ et Ö l''avenir|: nostalgie, regret ou dÇsir de rÇparer, ou bien curiositÇ de ce|',
  'qui vient. Freud y aurait vu un retour vers l''enfance et ses|dÇsirs anciens.|La siräne incarne la sÇduction irrÇsistible et dangereuse,|l''Anima dans sa forme ambivalente. Mi-femme mi-poisson, elle|',
  'relie le dÇsir et l''inconscient, et met en garde contre les|illusions de l''attirance.|Le phÇnix, qui renaåt de ses cendres, est le symbole supràme de la|',
  'rÇsurrection et du renouveau. Il annonce qu''une pÇriode de|destruction ou de deuil peut ouvrir sur une renaissance Çclatante.|La magie reprÇsente le pouvoir de transformer la rÇalitÇ par la|',
  'volontÇ ou l''imagination. Elle Çvoque la crÇativitÇ, la pensÇe|magique de l''enfance et le dÇsir de changer une situation sans|effort.|Une crÇature Çtrange ou hybride figure ce qui n''a pas encore de|',
  'forme dans votre psychisme : une Çmotion naissante, un aspect de|vous en gestation. Sa composition rÇväle les forces qui s''y|màlent.|La fin du monde annonce rarement une catastrophe rÇelle : elle|',
  'symbolise la fin d''un cycle de vie, un bouleversement intÇrieur|ou un changement radical. Un monde ancien s''efface pour laisser|place Ö un nouveau.|',
  'Le dinosaure Çvoque le passÇ lointain, les idÇes dÇpassÇes et les|forces archaãques de la psychÇ. Il peut dÇsigner une attitude|dÇmodÇe, une vieille peur d''enfance ou une figure d''autoritÇ|imposante.|',
  'Claire et calme, elle annonce une pÇriode d''apaisement, de|purification et de fÇconditÇ intÇrieure.|Paisible et lumineuse, elle traduit une ouverture d''esprit, un|',
  'Çlan vers la libertÇ et une grande sÇrÇnitÇ intÇrieure.|PortÇe par une belle vague, vous vous laissez aller avec confiance|au mouvement des ÇvÇnements et Ö votre Çlan vital.|',
  'Une eau qui coule paisiblement indique que vos projets suivent|leur cours naturel et que vous àtes en accord avec vous-màme.|Un lac calme et transparent refläte une paix intÇrieure et une|',
  'bonne connaissance de soi.|Une pluie douce et bienfaisante annonce un soulagement, une|libÇration des tensions et une pÇriode fertile.|Si vous restez Ö l''abri, ce ràve indique que vous traverserez un|',
  'bouleversement en gardant votre Çquilibre.|Patiner avec aisance ou contempler un paysage gelÇ exprime la|maåtrise de soi et une belle clartÇ d''esprit.|',
  'Une neige scintillante promet un nouveau dÇpart, une paix|retrouvÇe et la joie simple de l''Çmerveillement.|Admirer ou vous baigner sous une cascade annonce une vitalitÇ|',
  'retrouvÇe et une purification profonde.|Boire Ö une source claire annonce un regain de forces, une|inspiration ou une guÇrison morale.|Jouer dans la boue ou s''en libÇrer sans peine montre un rapport|',
  'dÇtendu Ö vos instincts et votre capacitÇ Ö rebondir.|Une plage ensoleillÇe traduit le dÇsir de libertÇ, de lÇgäretÇ et|un bel Çquilibre entre raison et Çmotions.|',
  'Une åle paradisiaque traduit un besoin de ressourcement et la|dÇcouverte d''un espace intÇrieur bien Ö vous.|Atteindre le sommet et contempler la vue annonce un succäs mÇritÇ|',
  'et une vision plus large de votre vie.|Une vallÇe verdoyante annonce une pÇriode paisible, une vie|affective harmonieuse et un sentiment de sÇcuritÇ.|',
  'Traverser le dÇsert avec sÇrÇnitÇ montre une grande force|intÇrieure et une libertÇ gagnÇe par la simplicitÇ.|Une foràt lumineuse et accueillante annonce un ressourcement et|',
  'une meilleure Çcoute de votre nature profonde.|Un arbre robuste, feuillu ou fleuri annonce une belle croissance|personnelle, de la stabilitÇ et une famille unie.|',
  'Des racines solides et vigoureuses traduisent un bon ancrage, une|confiance en soi et des appuis fiables.|Des feuilles nouvelles et Çclatantes annoncent une renaissance,|',
  'des projets qui bourgeonnent et un regain d''Çnergie.|Cueillir ou recevoir des fleurs annonce une joie affective, une|reconnaissance ou un talent qui s''Çpanouit.|',
  'Une rose Çpanouie ou offerte annonce un amour sincäre, une|dÇclaration ou un bonheur sentimental durable.|Un jardin fleuri et bien entretenu annonce une pÇriode fÇconde, un|',
  'foyer harmonieux et des efforts rÇcompensÇs.|Courir dans une prairie verdoyante traduit une grande vitalitÇ, un|esprit libre et une confiance retrouvÇe.|',
  'Une grotte lumineuse ou protectrice annonce une dÇcouverte|intÇrieure, un refuge ou une rÇvÇlation prÇcieuse.|Une belle pierre ou un rocher solide annonce stabilitÇ, constance|',
  'et fondations durables pour vos projets.|Tirer une eau fraåche d''un puits annonce une dÇcouverte|intÇrieure, une connaissance utile ou une aide inattendue.|',
  'Un volcan contemplÇ Ö distance montre que vous prenez conscience|de votre force intÇrieure et savez la canaliser.|Un brouillard qui se dissipe annonce une clarification prochaine|',
  'et la fin d''une pÇriode de doute.|Un champ de blÇ mñr ou une belle moisson annonce prospÇritÇ,|rÇussite matÇrielle et rÇcompense de vos efforts.|',
  'Un animal paisible ou familier traduit une alliance heureuse entre|votre raison et vos instincts.|Il annonce une guÇrison, un renouveau intÇrieur ou l''Çveil d''une|',
  'Çnergie crÇatrice longtemps endormie.|Un chat cÉlin annonce une pÇriode de douceur, de sensualitÇ et de|confiance en votre intuition.|Un chien joyeux promet une amitiÇ sincäre, un soutien sur lequel|',
  'vous pouvez compter sans rÇserve.|Monter un cheval docile annonce une progression rapide et une|belle harmonie entre volontÇ et instinct.|',
  'Un loup calme vous invite Ö faire confiance Ö votre flair et Ö|assumer une part plus libre de vous-màme.|Un ours paisible suggäre qu''un temps de retraite vous rÇgÇnÇrera|et vous rendra votre force.|',
  'Un lion majestueux annonce une rÇussite, une promotion ou un|regain de confiance en vous.|Apprivoiser un tigre signifie que vous parvenez Ö maåtriser une|passion et Ö en faire une force.|',
  'Un oiseau qui chante annonce de bonnes nouvelles, une libÇration|ou un Çlan d''inspiration.|Un aigle en plein vol annonce le succäs d''un projet ambitieux et|une vision claire de votre avenir.|',
  'Un corbeau paisible vous invite Ö Çcouter une intuition profonde|ou un message de votre inconscient.|Un hibou bienveillant annonce une sage dÇcision ou une|comprÇhension nouvelle d''une situation.|',
  'Une colombe blanche promet une rÇconciliation, un amour sincäre ou|une grande sÇrÇnitÇ intÇrieure.|Attraper un beau poisson annonce une idÇe fÇconde, une rentrÇe|',
  'd''argent ou une dÇcouverte sur vous-màme.|Nager sans crainte präs d''un requin montre que vous savez|dÇsormais tenir tàte aux personnes dures.|',
  'Une baleine paisible annonce une protection puissante et une|sagesse intÇrieure qui grandit.|Nager avec des dauphins annonce une pÇriode de joie partagÇe,|d''harmonie et de libertÇ retrouvÇe.|',
  'Une araignÇe qui tisse annonce un travail patient qui portera ses|fruits et une crÇativitÇ fÇconde.|Observer des insectes avec curiositÇ montre que vous savez pràter|',
  'attention aux petits dÇtails utiles.|Des abeilles butinant annoncent un succäs mÇritÇ, une abondance et|une heureuse coopÇration.|Des fourmis affairÇes annoncent que votre travail rÇgulier sera|',
  'bientìt rÇcompensÇ.|Chasser une mouche annonce que vous vous dÇbarrassez enfin d''un|souci ou d''une personne importune.|Un papillon colorÇ annonce une transformation heureuse, une|',
  'lÇgäretÇ retrouvÇe ou un amour naissant.|Un rat apprivoisÇ montre une ruse et une capacitÇ d''adaptation|prÇcieuses dans une pÇriode difficile.|',
  'Une souris attendrissante invite Ö apprÇcier les petits bonheurs|et la force de la discrÇtion.|Un lapin joyeux annonce une naissance, une chance inespÇrÇe ou une|vie amoureuse Çpanouie.|',
  'Un cerf majestueux annonce un renouveau intÇrieur, une ÇlÇvation|ou une rencontre noble.|Un taureau calme annonce une vitalitÇ solide, une rÇussite|matÇrielle et une sensualitÇ Çpanouie.|',
  'Des vaches grasses annoncent, comme dans le songe de Pharaon, des|annÇes de prospÇritÇ.|Un cochon dodu annonce la chance, une rentrÇe d''argent ou un|plaisir simple et sans culpabilitÇ.|',
  'Un troupeau paisible annonce la paix au foyer, la sÇcuritÇ et une|harmonie avec votre entourage.|Un singe joueur annonce de la gaietÇ, de l''astuce et une habiletÇ|pour rÇsoudre un probläme.|',
  'Un ÇlÇphant paisible annonce une protection solide et la levÇe des|obstacles qui ralentissaient vos projets.|Vaincre un crocodile signifie que vous surmontez une peur|',
  'archaãque ou un adversaire sournois.|Une grenouille qui coasse annonce un changement favorable, une|guÇrison ou une fertilitÇ retrouvÇe.|Une tortue qui avance annonce un succäs lent mais sñr ; la|',
  'persÇvÇrance l''emportera sur la hÉte.|Un escargot qui avance tranquillement vous rassure : votre|progression, bien que lente, est rÇelle.|Des vers de terre dans un sol riche annoncent un renouveau|',
  'discret, une fÇconditÇ qui se prÇpare.|Tenir un scorpion Ö distance montre votre capacitÇ Ö vous protÇger|d''une personne malveillante.|Un renard habile suggäre que votre astuce vous permettra de|',
  'trouver une solution inattendue.|Une chauve-souris qui vole sans vous toucher annonce une intuition|aiguâ pour traverser une pÇriode obscure.|',
  'Un coq qui chante annonce un rÇveil, une bonne nouvelle ; une|poule qui couve promet un foyer serein.|Un cygne blanc annonce un amour harmonieux ou la rÇvÇlation de|votre vraie beautÇ intÇrieure.|',
  'Exterminer des cafards annonce que vous faites le mÇnage dans|votre vie et chassez vos idÇes noires.|Un paon qui fait la roue annonce une reconnaissance publique et|une confiance en votre Çclat.|',
  'Une chävre qui grimpe aisÇment annonce que vous saurez franchir|des obstacles avec agilitÇ.|Un corps vigoureux ou harmonieux annonce un regain de vitalitÇ et|une bonne rÇconciliation avec vous-màme.|',
  'Des dents saines et Çclatantes tÇmoignent d''une belle confiance|en vous et d''une Çnergie pràte Ö saisir les occasions.|Une chevelure abondante et soignÇe refläte vitalitÇ, assurance et|',
  'pouvoir de sÇduction en pleine expansion.|Des yeux clairs et peráants annoncent une prise de conscience, une|intuition juste ou une vÇritÇ enfin comprise.|',
  'Une bouche souriante ou sensuelle annonce une parole libÇrÇe, un|Çchange chaleureux ou un plaisir pleinement accueilli.|Des mains habiles, ouvertes ou tendues annoncent une rÇussite|',
  'concräte, une aide offerte ou une amitiÇ sincäre.|Marcher pieds nus avec aisance annonce un retour Ö l''essentiel,|une humilitÇ fÇconde et un chemin choisi librement.|',
  'Des jambes solides ou une course lÇgäre annoncent une indÇpendance|retrouvÇe et des projets qui avancent bien.|Des bras puissants ou ouverts annoncent un soutien solide, une|',
  'affection offerte ou une Çnergie pràte Ö servir vos projets.|Une tàte haute ou baignÇe de lumiäre annonce une idÇe fÇconde, une|dÇcision juste ou une reconnaissance mÇritÇe.|',
  'Un visage lumineux ou bienveillant annonce une rencontre sincäre,|une rÇconciliation ou une meilleure estime de vous.|Un coeur qui bat fort et rÇguliärement annonce un Çlan sincäre, un|',
  'courage renouvelÇ ou une relation qui s''Çpanouit.|Un ventre rond et apaisÇ annonce une pÇriode fÇconde, un projet|qui mñrit ou une sÇcuritÇ intÇrieure retrouvÇe.|',
  'Une peau douce et Çclatante annonce une bonne santÇ, une confiance|retrouvÇe et des relations plus sereines.|Une blessure qui se referme ou que l''on panse annonce une|',
  'guÇrison intÇrieure, un pardon ou une Çpreuve surmontÇe.|Une cicatrice que l''on regarde sans gàne indique une page tournÇe|et une force acquise grÉce Ö l''expÇrience.|',
  'GuÇrir ou soigner un malade en ràve annonce un rÇtablissement, une|rÇconciliation ou des ressources insoupáonnÇes.|Une grossesse sereine annonce l''aboutissement prochain d''un|',
  'projet cher, une crÇativitÇ fÇconde ou une vie qui se renouvelle.|Se sentir soulagÇ apräs avoir vomi annonce une dÇlivrance, la fin|d''une contrainte ou une dÇcision enfin assumÇe.|',
  'Avancer aveugle mais guidÇ et confiant annonce une intuition sñre|et une foi nouvelle en votre sagesse intÇrieure.|Une voix claire et assurÇe annonce une parole qui porte, une|',
  'reconnaissance ou un conseil intÇrieur Ö suivre.|Des oreilles attentives annoncent un conseil prÇcieux, une|nouvelle favorable ou une meilleure Çcoute de vos besoins.|',
  'Un nez fin ou un parfum agrÇable annoncent une intuition juste et|la capacitÇ de flairer une belle occasion.|Des ongles soignÇs et solides annoncent une bonne confiance en|',
  'vous et une capacitÇ sereine Ö dÇfendre vos intÇràts.|Des doigts agiles annoncent une adresse reconnue, un travail|minutieux couronnÇ de succäs ou un lien qui se resserre.|',
  'Une belle barbe annonce respect, maturitÇ et une sagesse acquise|que votre entourage va reconnaåtre.|Un dos droit et solide annonce une force tranquille, une|',
  'responsabilitÇ bien assumÇe et une belle endurance.|Une gorge libre qui laisse passer le souffle et le chant annonce|une parole affirmÇe et une Çmotion enfin partagÇe.|',
  'Une langue dÇliÇe annonce des Çchanges fluides, une Çloquence|nouvelle et un plaisir de vivre bien savourÇ.|Une nuditÇ vÇcue sans gàne annonce une libÇration, une sincÇritÇ|',
  'assumÇe et une belle acceptation de vous-màme.|Une märe aimante ou souriante annonce sÇcuritÇ, rÇconfort et|rÇconciliation avec votre besoin de tendresse.|',
  'Un päre bienveillant annonce un soutien solide, une autoritÇ juste|et une confiance accrue dans vos dÇcisions.|Des parents unis et apaisÇs annoncent une harmonie familiale, une|',
  'sÇcuritÇ intÇrieure et un hÇritage bien assumÇ.|Un enfant joyeux annonce un projet plein de promesses, un regain|de crÇativitÇ ou une joie de vivre retrouvÇe.|',
  'Un bÇbÇ paisible et souriant annonce une naissance symbolique|rÇussie, un projet viable et une fraåcheur nouvelle.|Un fräre alliÇ et complice annonce un soutien fidäle, une|',
  'rÇconciliation ou une force partagÇe face aux Çpreuves.|Une soeur tendre et complice annonce une amitiÇ prÇcieuse, un|soutien fÇminin ou une harmonie intÇrieure.|',
  'Des grands-parents chaleureux annoncent un conseil avisÇ, un|rÇconfort ou la redÇcouverte de vos racines.|Une famille rÇunie dans la joie annonce une harmonie retrouvÇe,|',
  'des liens resserrÇs et un sentiment d''appartenance.|Un mari attentionnÇ annonce une union solide, une confiance|partagÇe ou une meilleure entente avec votre force intÇrieure.|',
  'Une Çpouse heureuse annonce une harmonie conjugale, une|sensibilitÇ accueillie et des projets communs fructueux.|Retrouver un ami avec joie annonce un soutien prÇcieux, une|',
  'rÇconciliation ou une qualitÇ personnelle qui s''Çpanouit.|Un inconnu bienveillant annonce une rencontre marquante, une idÇe|neuve ou une qualitÇ cachÇe qui se rÇväle.|',
  'Une foule festive qui vous accueille annonce succäs social,|reconnaissance et un sentiment d''appartenance retrouvÇ.|Cìtoyer une cÇlÇbritÇ avec plaisir annonce une valorisation, un|',
  'talent qui s''affirme ou une reconnaissance prochaine.|Rencontrer un roi ou le devenir annonce une rÇussite, une prise de|responsabilitÇ ou une maåtrise de soi accrue.|',
  'Une reine bienveillante annonce protection, ÇlÇvation sociale ou|l''affirmation sereine de votre propre valeur.|Un prince charmant ou valeureux annonce une rencontre prometteuse,|',
  'un idÇal qui se concrÇtise ou un courage nouveau.|Une princesse rayonnante annonce une belle reconnaissance, une|dÇlicatesse apprÇciÇe ou un ràve qui devient possible.|',
  'Un policier protecteur annonce un cadre rassurant, une aide|extÇrieure ou une situation enfin remise en ordre.|DÇmasquer ou arràter un voleur annonce une reprise de contrìle et|',
  'la rÇcupÇration d''un bien, d''un droit ou d''une Çnergie.|Un soldat courageux annonce la force de mener un combat juste, une|discipline fÇconde et une victoire sur vos doutes.|',
  'Un mÇdecin rassurant annonce une guÇrison, un conseil avisÇ ou la|solution Ö un probläme qui vous prÇoccupait.|Un professeur bienveillant annonce un apprentissage fÇcond, un|',
  'mentor qui se prÇsente ou une compÇtence acquise.|Un clown drìle annonce le retour de la lÇgäretÇ, une salutaire|autodÇrision ou une tension qui se dÇnoue.|',
  'Un vieillard bienveillant qui vous parle annonce un conseil|prÇcieux et la maturitÇ nÇcessaire pour dÇcider.|Vaincre un ennemi ou se rÇconcilier avec lui annonce la rÇsolution|',
  'd''un conflit et l''intÇgration d''une part de vous.|Un double complice annonce l''harmonie entre deux aspects de vous|et une meilleure connaissance de vous-màme.|',
  'Un voisin serviable annonce entraide, bon voisinage et une|communautÇ sur laquelle vous pouvez compter.|Une maison accueillante et lumineuse refläte un bon Çquilibre|',
  'intÇrieur et un sentiment de sÇcuritÇ bien installÇ.|Ce retour paisible vous reconnecte Ö vos ressources profondes :|spontanÇitÇ, confiance et goñt de l''Çmerveillement.|',
  'Une chambre douce et ordonnÇe traduit une intimitÇ harmonieuse et|la capacitÇ de vous ressourcer pleinement.|Une cuisine chaleureuse et active annonce une pÇriode fÇconde,|',
  'riche en partages et en projets qui prennent forme.|Un bain agrÇable symbolise une rÇgÇnÇration : vous vous dÇlestez|du passÇ et retrouvez une sensation de fraåcheur.|',
  'Des toilettes propres et accessibles indiquent que vous savez|lÉcher prise et vous libÇrer de ce qui vous encombre.|Explorer une cave sans crainte montre que vous àtes pràt Ö|',
  'affronter vos profondeurs et Ö en rapporter des trÇsors cachÇs.|Fouiller un grenier lumineux promet la redÇcouverte d''un talent,|d''un souvenir prÇcieux ou d''une sagesse hÇritÇe.|',
  'Gravir un escalier avec aisance annonce une progression, une|promotion ou une prise de hauteur sur vos difficultÇs.|Une porte qui s''ouvre facilement annonce une occasion favorable|',
  'et l''entrÇe dans une nouvelle Çtape de vie.|Une fenàtre ouverte sur un paysage clair annonce de nouvelles|perspectives et une vision plus sereine de l''avenir.|',
  'Un mur solide qui vous abrite montre que vous savez poser des|limites saines et protÇger votre Çquilibre.|Un toit solide ou une vue dÇgagÇe depuis les hauteurs signale|',
  'confiance en vous et vision claire de vos objectifs.|Un couloir clair qui mäne Ö une piäce accueillante annonce|l''issue heureuse d''une pÇriode de transition.|',
  'Un ascenseur qui monte en douceur annonce une rÇussite rapide ou|une ÇlÇvation de votre position.|Une piäce secräte lumineuse annonce l''Çveil d''une crÇativitÇ ou|',
  'd''une libertÇ nouvelle que vous pouvez investir.|Une Çcole joyeuse annonce une pÇriode d''apprentissage stimulante|et la curiositÇ retrouvÇe.|',
  'Un hìpital rassurant annonce une guÇrison, une convalescence ou|l''aide bienveillante dont vous avez besoin.|S''Çvader ou àtre libÇrÇ annonce la fin d''une contrainte et le|',
  'retour d''une libertÇ longtemps attendue.|Un chÉteau majestueux annonce la rÇalisation d''un ràve ancien et|une solide confiance en votre valeur.|',
  'Une ville animÇe et accueillante refläte une vie sociale Çpanouie|et l''envie de nouvelles rencontres.|Une rue ensoleillÇe et animÇe indique que vous avancez avec|assurance parmi les autres.|',
  'Trouver la sortie ou le centre du labyrinthe annonce la rÇsolution|d''un probläme complexe et une meilleure connaissance de vous.|Un magasin bien achalandÇ annonce des possibilitÇs nombreuses et|',
  'la capacitÇ de choisir ce qui vous convient.|Un repas savoureux au restaurant annonce des moments de|convivialitÇ et une reconnaissance bienvenue.|',
  'Un hìtel confortable annonce une parenthäse bienfaisante, un|voyage ou un changement agrÇable.|Visiter des ruines avec sÇrÇnitÇ montre que vous avez fait la paix|avec le passÇ et pouvez reconstruire.|',
  'Monter au sommet d''une tour annonce une prise de recul, une|rÇussite ou une comprÇhension nouvelle.|Briller sur scäne annonce une reconnaissance mÇritÇe et l''audace|d''exprimer pleinement vos talents.|',
  'Une piscine limpide annonce la dÇtente, la clartÇ Çmotionnelle et|une pÇriode de plaisir partagÇ.|Une invitation dans un palais annonce une ascension sociale, un|',
  'honneur ou la dÇcouverte de vos qualitÇs royales.|Un village paisible annonce un retour aux sources, la chaleur des|liens et une vie plus simple.|',
  'Trouver ou recevoir une clÇ annonce une solution, une opportunitÇ|ou la comprÇhension soudaine d''une situation.|Une serrure qui cäde sous votre main annonce la levÇe d''un|',
  'blocage et la confiance gagnÇe de quelqu''un.|Un reflet harmonieux traduit une bonne acceptation de soi et une|image intÇrieure apaisÇe.|Une conversation claire au tÇlÇphone annonce des nouvelles|',
  'bienvenues ou une rÇconciliation possible.|Un ordinateur performant annonce clartÇ d''esprit, bonne|organisation et rÇussite intellectuelle.|',
  'Lire un livre passionnant annonce un apprentissage fÇcond ou la|rÇvÇlation d''une vÇritÇ utile.|Recevoir une belle lettre promet de bonnes nouvelles, une|dÇclaration ou un lien qui se renforce.|',
  'Regarder de belles photos annonce la douceur des souvenirs et la|valeur de liens qui durent.|Un sac lÇger et bien rangÇ signale que vous avez l''essentiel avec|vous et que vous avancez libre.|',
  'Un parapluie qui vous abrite annonce une protection fiable ou|l''appui d''une personne bienveillante.|Une bougie qui brille calmement annonce l''espoir retrouvÇ, une|',
  'inspiration ou une prÇsence protectrice.|Une lampe qui illumine la piäce annonce une idÇe lumineuse, une|prise de conscience ou un bon conseil.|',
  'Une horloge au tic-tac paisible annonce que le moment est venu|d''agir, au bon rythme.|Recevoir une bague annonce un engagement sincäre, une alliance|favorable ou une promesse tenue.|',
  'Recevoir ou trouver un bijou annonce la reconnaissance de vos|qualitÇs ou un attachement sincäre.|Porter une couronne annonce une rÇussite, une promotion ou la|pleine reconnaissance de votre valeur.|',
  'Utiliser un couteau avec habiletÇ annonce une dÇcision claire et|la capacitÇ de couper ce qui vous nuit.|Une corde solide Ö laquelle vous vous agrippez annonce une aide|',
  'prÇcieuse et des liens sur lesquels compter.|Briser une chaåne annonce une libÇration, la fin d''une dÇpendance|ou d''une emprise.|Ouvrir un coffre plein annonce la dÇcouverte d''une ressource|',
  'cachÇe ou d''un talent Ö exploiter.|Recevoir un cadeau annonce une surprise heureuse, une gratitude|partagÇe ou un don Ö cultiver.|Ramasser des Çclats sans vous blesser annonce une rÇparation et la|',
  'sagesse tirÇe d''une dÇsillusion.|Gravir une Çchelle stable annonce une progression rÇguliäre et la|rÇussite de vos efforts patients.|Retirer un masque annonce un moment d''authenticitÇ et le|',
  'soulagement d''àtre enfin vous-màme.|Une poupÇe choyÇe Çvoque la tendresse, le dÇsir de protÇger ou un|souvenir d''enfance rÇconfortant.|Jouer avec un jouet annonce un retour de spontanÇitÇ, de plaisir|',
  'simple et de crÇativitÇ.|Un ballon qui s''Çläve annonce une joie lÇgäre, un projet qui|prend son envol ou un esprit d''Çquipe retrouvÇ.|',
  'Lire une carte avec clartÇ annonce un cap bien dÇfini et des choix|ÇclairÇs pour l''avenir.|Une boussole fiable annonce une dÇcision juste et la confiance en|votre guide intÇrieur.|',
  'Brandir une ÇpÇe annonce une victoire, une affirmation de vous et|la dÇfense de ce qui est juste.|Une bouteille pleine qu''on dÇbouche annonce une cÇlÇbration, une|',
  'abondance ou un message enfin entendu.|Un lit douillet annonce un repos rÇparateur, une intimitÇ sereine|et des liens tendres.|Une chaise confortable annonce une position bien acquise et un|',
  'moment de repos mÇritÇ.|Une table bien dressÇe et entourÇe annonce la concorde, la|rÇconciliation ou une rÇunion heureuse.|Une Çmission captivante annonce une inspiration venue de|',
  'l''extÇrieur ou une prise de recul utile.|Ouvrir une cage annonce une libÇration, l''expression d''un talent|ou la fin d''une emprise.|Conduire avec aisance sur une belle route annonce une pÇriode de|',
  'maåtrise, d''Çlan et de dÇcisions assurÇes.|Freiner Ö temps annonce une sage prudence et la capacitÇ de vous|arràter avant l''excäs.|Un voyage paisible en train annonce une Çvolution rÇguliäre et un|',
  'chemin de vie bien engagÇ.|Une gare animÇe annonce un nouveau dÇpart prometteur et l''arrivÇe|de projets ou de personnes bienvenus.|Un vol serein annonce une rÇussite rapide, une ouverture|',
  'd''horizon ou un projet qui dÇcolle enfin.|Embarquer sans encombre annonce un nouveau chapitre ouvert, une|expansion professionnelle ou affective.|',
  'Naviguer sur une eau calme annonce une pÇriode d''harmonie et un|voyage, intÇrieur ou rÇel, rÇussi.|Survivre au naufrage et gagner la rive annonce une rÇsilience|',
  'remarquable et un renouveau apräs la crise.|PÇdaler avec lÇgäretÇ annonce un bel Çquilibre et des progräs|obtenus par vos propres forces.|',
  'Un trajet agrÇable en bus annonce une bonne intÇgration sociale et|des projets menÇs en commun.|Un trajet fluide en mÇtro annonce que vos ressources cachÇes vous|mänent sñrement vers votre but.|',
  'Une balade grisante Ö moto annonce une pÇriode d''audace,|d''autonomie et d''Çlan joyeux.|Une route dÇgagÇe et ensoleillÇe annonce un avenir ouvert et des|choix en accord avec vous-màme.|',
  'Choisir une direction avec confiance au carrefour annonce une|dÇcision juste et une Çtape nouvelle.|Traverser un pont solide annonce un cap franchi avec succäs, une|rÇconciliation ou un lien Çtabli.|',
  'Voir la lumiäre au bout du tunnel annonce la fin prochaine d''une|pÇriode difficile et un renouveau.|Une valise lÇgäre et bien faite annonce un dÇpart rÇussi et la|',
  'libertÇ de qui voyage sans excäs de bagages.|Avoir son billet en main annonce une occasion offerte et la|lÇgitimitÇ de vous lancer.|Franchir une frontiäre sans difficultÇ annonce une expansion, une|',
  'ouverture et un changement rÇussi.|Un taxi qui arrive au bon moment annonce une aide efficace et une|solution rapide Ö vos besoins.|Sortir d''un embouteillage annonce la levÇe d''un blocage et la|',
  'reprise d''un projet ralenti.|Rater un dÇpart sans regret suggäre que ce chemin n''Çtait pas le|vìtre et qu''une meilleure voie se prÇpare.|Un vol aisÇ traduit une confiance retrouvÇe, une libertÇ|',
  'intÇrieure et la capacitÇ de dÇpasser un obstacle avec lÇgäretÇ.|Une chute douce ou un atterrissage sans heurt suggäre un|lÉcher-prise salutaire : vous acceptez de ne plus tout maåtriser.|',
  'Si vous vous retournez pour faire face, le ràve annonce|l''intÇgration d''une force jusque-lÖ redoutÇe et un vrai gain|d''assurance.|Une fuite rÇussie peut marquer une libÇration lÇgitime : vous|',
  'quittez enfin une situation qui vous Çtouffait.|Une course lÇgäre et joyeuse annonce une pÇriode dynamique oó vos|projets avancent avec vigueur et confiance.|',
  'Une nage fluide dans une eau claire rÇväle une harmonie affective|et une belle capacitÇ d''adaptation aux ÇvÇnements.|Se voir sauvÇ ou dÇcouvrir qu''on respire sous l''eau annonce une|',
  'renaissance : vous apprenez Ö vivre vos Çmotions sans sombrer.|Perdre sans regret suggäre un dÇtachement nÇcessaire : vous vous|allÇgez de ce qui ne vous correspond plus.|',
  'Une recherche pleine d''espoir annonce une pÇriode de dÇcouverte|oó vos questions trouvent peu Ö peu leurs rÇponses.|Une trouvaille heureuse annonce une opportunitÇ, une idÇe fÇconde|',
  'ou la redÇcouverte d''une qualitÇ que vous aviez oubliÇe.|Arriver malgrÇ tout, ou constater que le retard importe peu,|montre que vous apprenez Ö relÉcher la pression et le|perfectionnisme.|',
  'RÇussir l''examen ou s''y sentir pràt annonce une Çtape franchie|et une confiance accrue dans vos compÇtences.|Un cri puissant et libÇrateur indique que vous osez enfin exprimer|',
  'vos besoins et affirmer vos limites.|Retrouver peu Ö peu le mouvement montre que vous sortez d''une|impasse et reprenez la main sur votre vie.|',
  'Une cachette sñre et paisible Çvoque un refuge intÇrieur, un temps|de repli fÇcond avant de vous montrer Ö nouveau.|Un combat victorieux annonce que vous trouvez la force de dÇfendre|',
  'vos valeurs et de surmonter une difficultÇ rÇelle.|Une danse fluide annonce une pÇriode d''Çpanouissement, de|complicitÇ affective et de confiance dans votre Çlan vital.|',
  'Un chant clair et juste annonce une harmonie intÇrieure, une|communication rÇussie et une crÇativitÇ qui s''Çpanouit.|Rire avec d''autres annonce des liens chaleureux, une dÇtente|',
  'bienvenue et un regard plus lÇger sur vos soucis.|Des larmes apaisantes annoncent la fin d''une pÇriode difficile et|un renouveau affectif apräs la tempàte.|',
  'Errer avec curiositÇ dans un lieu inconnu suggäre une ouverture Ö|l''imprÇvu et l''exploration de nouveaux possibles.|Atteindre le sommet annonce une rÇussite mÇritÇe et le sentiment|',
  'gratifiant d''avoir dÇpassÇ vos propres limites.|Une descente sereine indique un retour aux sources, une|introspection fructueuse ou un bienfaisant retour sur terre.|',
  'Un saut rÇussi annonce une dÇcision courageuse qui porte ses|fruits et un Çlan nouveau dans votre existence.|Un emmÇnagement joyeux dans un lieu lumineux annonce un nouveau|',
  'dÇpart, une renaissance personnelle ou familiale.|Une attente paisible annonce la maturation d''un projet : ce qui|doit venir prend le temps de se prÇparer.|',
  'Trouver une issue ou une clÇ annonce une libÇration prochaine et|la dÇcouverte de ressources que vous ignoriez.|Une Çcriture fluide annonce une clartÇ nouvelle, une inspiration|',
  'crÇatrice ou un message important enfin formulÇ.|Une construction qui s''Çläve harmonieusement annonce la rÇussite|d''un projet patient et une stabilitÇ bien mÇritÇe.|',
  'Un nettoyage efficace annonce un renouveau, une conscience apaisÇe|et un espace libÇrÇ pour accueillir du neuf.|Ce que vous dÇcouvrez avec plaisir annonce une opportunitÇ, une|',
  'rÇvÇlation heureuse ou un nouveau chapitre de vie.|Un rÇveil lumineux annonce une luciditÇ nouvelle, la fin d''une|illusion et l''envie de prendre votre vie en main.|',
  'Une luciditÇ joyeuse annonce une belle maåtrise de vous-màme et|une crÇativitÇ capable de rÇinventer vos peurs.|Si le ràve rÇcurrent s''adoucit ou se dÇnoue, c''est le signe|',
  'qu''une question ancienne trouve enfin sa rÇsolution.|Une prÇmonition heureuse traduit une confiance intuitive dans|l''avenir et la perception d''opportunitÇs qui se dessinent.|',
  'Un feu de cheminÇe ou une flamme maåtrisÇe annonce chaleur|affective, enthousiasme et regain de vitalitÇ.|Un soleil radieux promet succäs, reconnaissance, santÇ et une|',
  'pÇriode de grande confiance en vous.|Une lune claire et belle annonce une intuition juste, une|sensibilitÇ Çpanouie ou une rencontre romantique.|',
  'Une Çtoile brillante ou une Çtoile filante annonce la rÇalisation|d''un voeu, une chance ou une inspiration.|Un ciel bleu et dÇgagÇ annonce sÇrÇnitÇ, optimisme et horizon|ouvert pour vos projets.|',
  'Des nuages blancs et lÇgers traduisent une crÇativitÇ vagabonde,|un esprit libre et des soucis qui s''envolent.|Un orage contemplÇ Ö l''abri ou suivi d''un ciel clair annonce une|',
  'crise salutaire qui assainit une situation.|Traverser la tempàte sans dommage montre votre rÇsilience et|annonce une issue favorable Ö une pÇriode difficile.|',
  'Une brise lÇgäre et agrÇable annonce un renouveau, de bonnes|nouvelles ou une inspiration bienvenue.|Il annonce la fin d''une pÇriode sombre, une rÇconciliation, une|',
  'promesse tenue ou une joie inattendue.|Une terre riche et fertile annonce une pÇriode fÇconde, un|enracinement solide et une sÇcuritÇ matÇrielle.|',
  'Rester debout pendant la secousse montre une grande soliditÇ|intÇrieure et la capacitÇ de reconstruire sur du neuf.|Une nuit douce et ÇtoilÇe traduit un apaisement, une ràverie|',
  'fÇconde ou une intimitÇ heureuse.|Se sentir baignÇ de lumiäre annonce une rÇvÇlation, une guÇrison|intÇrieure ou une pÇriode de grande clartÇ.|',
  'Assister Ö une belle aurore annonce un nouveau dÇpart heureux, une|guÇrison ou un projet prometteur.|Un coucher de soleil splendide traduit la satisfaction d''une|',
  'Çtape accomplie et une douce sÇrÇnitÇ.|Flotter parmi les Çtoiles et les planätes annonce une expansion de|conscience, une libertÇ et des horizons nouveaux.|',
  'Une Çclipse contemplÇe avec Çmerveillement annonce une union|fÇconde ou une transformation rare et prÇcieuse.|Une fumÇe lÇgäre qui s''Çläve vers le ciel traduit un dÇtachement|',
  'serein ou un voeu qui prend son envol.|Vous recevez un soutien intÇrieur puissant et une confiance|renouvelÇe en votre chemin de vie.|Une aide inattendue ou une intuition salutaire vous accompagne ;|',
  'vous àtes plus protÇgÇ que vous ne le pensez.|Dialoguer avec le dÇmon ou le vaincre montre que vous intÇgrez une|Çnergie refoulÇe et gagnez en force.|',
  'Un fantìme paisible apporte un message de rÇconciliation ; une|vieille histoire peut enfin s''apaiser.|Votre demande est entendue, au moins par vous-màme : une solution|ou un apaisement se prÇpare.|',
  'Vous trouvez un abri moral, une paix retrouvÇe ou le soutien|d''une communautÇ bienveillante.|Vous accÇdez Ö une sagesse profonde et Ö un sentiment d''harmonie|avec vous-màme et le monde.|',
  'Une Çpreuve prend sens : vous trouvez la force et la foi|nÇcessaires pour la dÇpasser.|Un bon conseil ou une parole d''apaisement vous aide Ö faire la|paix avec une dÇcision difficile.|',
  'Une pÇriode de recueillement vous sera bÇnÇfique ; la sagesse naåt|du calme que vous cultivez.|Une pÇriode de sÇrÇnitÇ s''annonce ; vous àtes en accord avec vos|dÇsirs les plus profonds.|',
  'Sortir de l''enfer annonce la fin d''une Çpreuve et une libÇration|durement gagnÇe.|Une issue favorable se dessine lÖ oó vous ne l''attendiez plus ;|gardez confiance.|',
  'Un engagement sincäre se prÇpare ; ce que vous donnez sera reconnu|et porteur de sens.|Vous atteignez une clartÇ et un calme intÇrieurs qui faciliteront|vos prochaines dÇcisions.|',
  'Un conseil prÇcieux vous est donnÇ ; faites confiance Ö votre|intuition pour la suite.|Votre intuition est juste : vous pressentez correctement|l''Çvolution d''une situation.|',
  'Vous avancez avec dÇtermination vers un objectif profond ; la|route elle-màme vous transforme.|Vous retrouvez votre Çquilibre ; les diffÇrentes parts de|vous-màme s''harmonisent.|',
  'Vous ressentez une profonde unitÇ intÇrieure et un lien apaisÇ|avec ce qui vous dÇpasse.|Un projet ou une union reáoit un soutien bienveillant ; vous|pouvez vous engager sereinement.|',
  'Une page se tourne en douceur ; vous àtes pràt Ö laisser partir le|passÇ pour accueillir du nouveau.|Accepter de mourir dans le ràve montre votre capacitÇ Ö lÉcher|prise et Ö renaåtre autrement.|',
  'DÇcouvrir un cadavre sans effroi signale que vous àtes pràt Ö|faire le deuil d''une situation rÇvolue.|Fermer un cercueil avec calme indique que vous avez achevÇ une|Çtape et pouvez avancer librement.|',
  'Vous faites enfin la paix avec le passÇ ; cette sÇparation ouvre|la voie Ö un renouveau.|Une promenade paisible parmi les tombes favorise la sagesse et le|respect de vos origines.|',
  'Un tombeau fleuri ou serein indique que vous honorez votre passÇ|sans en àtre prisonnier.|Vous allez Ö l''essentiel ; une situation se clarifie et rÇväle sa|vÇritable structure.|',
  'Un nouveau dÇpart se concrÇtise ; ce que vous portiez depuis|longtemps voit enfin le jour.|Vous retrouvez force et enthousiasme ; une renaissance personnelle|est en cours.|',
  'Une rencontre apaisÇe avec le dÇfunt apporte rÇconfort et|sentiment de paix retrouvÇe.|Vous gagnez en sÇrÇnitÇ et en sagesse ; vos choix deviennent plus|mñrs et plus sñrs.|',
  'Vous Çvoluez dans la bonne direction ; cette transformation vous|rÇväle Ö vous-màme.|Un sang vif et abondant traduit vitalitÇ, ardeur et renouvellement|de vos Çnergies.|',
  'Vous recevez une ressource prÇcieuse, matÇrielle ou morale, qui|vous aidera Ö construire votre avenir.|Un repas savoureux et partagÇ annonce bien-àtre, abondance et|',
  'satisfaction affective dans votre vie.|Un pain chaud et dorÇ annonce prospÇritÇ, sÇcuritÇ matÇrielle et|chaleur des liens familiaux ou amicaux.|',
  'Des fruits mñrs et abondants annoncent la rÇussite d''un projet,|une union heureuse ou une pÇriode de plaisirs.|Croquer une pomme savoureuse annonce une dÇcouverte, une tentation|',
  'heureuse ou une excellente vitalitÇ.|Partager un beau gÉteau annonce une cÇlÇbration, une rÇussite Ö|fàter ou un moment de tendresse partagÇe.|',
  'Savourer du chocolat annonce un moment de plaisir mÇritÇ, une|tendresse reáue ou une relation complice.|Boire un lait frais et doux annonce rÇconfort, bienveillance reáue|',
  'et une pÇriode de croissance paisible.|Partager un bon vin annonce des retrouvailles joyeuses, une amitiÇ|sincäre ou une inspiration crÇatrice.|',
  'Un plat de viande appÇtissant annonce force, santÇ solide et une|ambition qui se concrÇtise.|Un oeuf intact ou qui Çclot annonce une naissance, un projet|prometteur ou un renouveau bienvenu.|',
  'Goñter du miel annonce une pÇriode douce, une rÇconciliation, des|paroles affectueuses ou des gains mÇritÇs.|Se voir conviÇ Ö un festin joyeux annonce des rÇjouissances, une|',
  'reconnaissance sociale ou une rÇconciliation.|Une faim joyeuse qui va àtre comblÇe annonce un appÇtit de vivre|et un dÇsir qui trouvera satisfaction.|',
  'Cueillir ou cuisiner des lÇgumes frais annonce une bonne santÇ,|une vie domestique harmonieuse et des gains sñrs.|Un peu de sel sur un plat annonce un regain d''intÇràt pour la|',
  'vie, une sagesse acquise ou une amitiÇ durable.|Un cafÇ partagÇ dans la bonne humeur annonce une rencontre|stimulante, une conversation utile ou une idÇe claire.|',
  'Recevoir des friandises annonce une petite joie, un compliment,|une tendresse ou un plaisir simple et mÇritÇ.|Jeter des aliments gÉtÇs montre votre capacitÇ Ö vous dÇbarrasser|',
  'de ce qui vous nuit et Ö repartir sur des bases saines.|Boire avec dÇlice une eau fraåche annonce un soulagement, un|besoin comblÇ ou un renouveau intÇrieur.|',
  'Recevoir ou manier l''argent avec aisance annonce une|reconnaissance de vos mÇrites et une confiance accrue en vos|capacitÇs.|Ramasser des piäces brillantes annonce de petites chances qui|',
  's''additionnent et une prospÇritÇ construite avec patience.|DÇcouvrir un trÇsor annonce la rÇvÇlation d''un talent, d''un|amour ou d''une sagesse longtemps ignorÇs en vous.|',
  'L''or rayonnant annonce une rÇussite Çclatante, une reconnaissance|mÇritÇe ou un accomplissement spirituel profond.|Une visite sereine Ö la banque annonce une situation stable et une|',
  'bonne gestion de vos forces et de vos rÇserves.|Rebondir apräs la faillite annonce un renouveau : un modäle|dÇpassÇ s''effondre pour laisser place Ö un dÇpart plus sain.|',
  'Un travail fluide et gratifiant annonce une pÇriode productive,|une reconnaissance de vos efforts et un rÇel Çpanouissement.|Un bureau clair et ordonnÇ annonce une organisation efficace et un|',
  'projet professionnel qui prend bonne tournure.|Un patron bienveillant ou Çlogieux annonce une reconnaissance|prochaine et une confiance grandissante en votre propre autoritÇ.|',
  'Une collaboration harmonieuse annonce un soutien prÇcieux, un|esprit d''Çquipe renforcÇ et des projets menÇs Ö plusieurs.|Une rÇunion constructive annonce un accord, une Çcoute attentive|',
  'de vos idÇes et une dÇcision importante prise sereinement.|Accueillir le licenciement avec soulagement suggäre qu''une|libÇration est en marche et qu''un projet plus juste vous attend.|',
  'Un entretien rÇussi annonce une opportunitÇ rÇelle et la capacitÇ|de vous prÇsenter avec authenticitÇ et assurance.|Signer un contrat avec confiance annonce un partenariat solide, un|',
  'engagement mñri ou une promesse qui se concrÇtise.|Un achat satisfaisant annonce la rÇalisation d''un souhait et une|juste Çvaluation de ce qui compte vraiment pour vous.|',
  'Une vente rÇussie annonce une reconnaissance de votre valeur et un|Çchange Çquitable, profitable Ö chacun.|Rembourser une dette en ràve annonce un soulagement, un Çquilibre|',
  'retrouvÇ et la fin d''un poids moral.|Une richesse partagÇe avec gÇnÇrositÇ annonce l''Çpanouissement et|une prospÇritÇ qui nourrit aussi votre entourage.|',
  'Une pauvretÇ vÇcue avec sÇrÇnitÇ Çvoque le dÇtachement, la|simplicitÇ retrouvÇe et l''essentiel redÇcouvert.|Porter de beaux vàtements annonce une meilleure estime de soi et|',
  'une image valorisÇe par l''entourage.|Des chaussures neuves et confortables annoncent un nouveau dÇpart|ou un chemin qui vous correspond.|',
  'Une robe magnifique annonce une pÇriode de charme, une invitation|ou une reconnaissance flatteuse.|Porter une robe de mariÇe Çclatante annonce un engagement heureux|',
  'ou une harmonie intÇrieure profonde.|Un chapeau ÇlÇgant annonce une reconnaissance de vos idÇes ou une|nouvelle responsabilitÇ valorisante.|',
  'Un manteau chaud et ample annonce une protection affective et un|sentiment de sÇcuritÇ bienvenu.|Porter fiärement un uniforme annonce une intÇgration rÇussie et la|reconnaissance de vos compÇtences.|',
  'Un dÇguisement amusant annonce une pÇriode de libertÇ, de|crÇativitÇ et d''expÇrimentation joyeuse.|Des sous-vàtements raffinÇs annoncent une sensualitÇ assumÇe et|',
  'une confiance nouvelle dans l''intimitÇ.|Un maquillage rÇussi annonce un regain de confiance, une sÇduction|Çpanouie ou une belle occasion sociale.|',
  'Des lunettes neuves annoncent une comprÇhension plus claire et une|dÇcision prise en connaissance de cause.|Laver des vàtements sales annonce une purification, une|',
  'rÇconciliation ou un nouveau dÇpart.|Un couple complice et serein annonce une relation qui s''Çpanouit,|une rencontre favorable ou une belle harmonie intÇrieure.|',
  'Un baiser tendre annonce une affection partagÇe, une|rÇconciliation ou l''accueil d''une part de vous longtemps|ignorÇe.|Un amant attentionnÇ annonce un regain de dÇsir, une confiance en|',
  'votre pouvoir de sÇduction ou une passion crÇatrice.|Un mariage joyeux annonce une alliance heureuse, un projet scellÇ|ou une rÇconciliation profonde avec vous-màme.|',
  'Une rupture vÇcue avec soulagement annonce une libÇration, un|nouveau dÇpart et la fin d''une relation qui pesait.|Pardonner une infidÇlitÇ en ràve annonce un apaisement, une|',
  'confiance reconstruite ou un lien qui se renouvelle.|Un Çchange paisible avec un ex annonce une page tournÇe, un pardon|accordÇ et une maturitÇ affective acquise.|',
  'Une intimitÇ Çpanouie en ràve annonce un regain d''Çnergie, une|harmonie avec votre corps et une crÇativitÇ libÇrÇe.|Une Çtreinte chaleureuse annonce rÇconfort, rÇconciliation et un|',
  'soutien affectif sur lequel vous pouvez compter.|Un rendez-vous rÇussi annonce une rencontre prometteuse, une|ouverture du coeur ou une occasion Ö saisir.|',
  'Des fianáailles heureuses annoncent une promesse tenue, un|engagement mñri et des perspectives qui s''Çclaircissent.|Un divorce serein annonce une Çmancipation, la fin d''un compromis|',
  'pesant et la libertÇ de choisir votre voie.|SÇduire avec aisance annonce une belle assurance, un charme qui|s''affirme et des relations sociales favorables.|',
  'Un coup de foudre lumineux annonce une rencontre marquante, une|passion naissante ou une rÇvÇlation sur vos dÇsirs.|Un blanc lumineux annonce un renouveau, une clarification, une|',
  'paix retrouvÇe ou un engagement sincäre.|PortÇ avec ÇlÇgance, le noir traduit autoritÇ, mystäre assumÇ et|force intÇrieure tranquille.|',
  'Un rouge vif et chaleureux annonce une passion naissante, un Çlan|d''enthousiasme ou une belle vitalitÇ.|Un bleu limpide annonce apaisement, confiance, communication|sincäre et clartÇ d''esprit.|',
  'Un vert tendre et lumineux annonce une guÇrison, un projet qui|pousse bien ou une espÇrance justifiÇe.|Un jaune Çclatant annonce optimisme, idÇes brillantes, succäs|',
  'intellectuel et sociabilitÇ Çpanouie.|Un orange lumineux annonce une pÇriode dynamique, des rencontres|joyeuses et une crÇativitÇ fÇconde.|',
  'Un violet profond annonce un Çveil spirituel, une intuition sñre|ou une sagesse nouvellement acquise.|Un gris doux et ÇlÇgant traduit la pondÇration, le recul et une|',
  'sÇrÇnitÇ tranquille face aux ÇvÇnements.|Une lumiäre ou un objet dorÇ annonce une rÇussite Çclatante, une|reconnaissance ou un Çpanouissement intÇrieur.|',
  'Il annonce un nouveau dÇpart, une victoire personnelle ou la|capacitÇ de mener seul un projet Ö bien.|Il annonce une union, un partenariat fructueux ou une|',
  'rÇconciliation entre deux parts de vous-màme.|Il annonce une naissance, une rÇalisation crÇative ou la|rÇsolution heureuse d''un conflit.|Il annonce des bases solides, une organisation efficace et une|',
  'sÇcuritÇ matÇrielle bien construite.|Il promet une pÇriode vivante, des voyages, des dÇcouvertes et une|curiositÇ rÇcompensÇe.|Il annonce une harmonie affective, une vie familiale apaisÇe ou|',
  'une dÇcision juste et ÇquilibrÇe.|Il annonce une chance, une intuition juste ou l''aboutissement|heureux d''un cheminement intÇrieur.|Il annonce une rÇussite financiäre, une autoritÇ reconnue ou un|',
  'juste retour de vos efforts.|Il annonce la fin heureuse d''une Çtape, une naissance prochaine|ou la rÇcolte d''un long travail.|Il annonce une rÇussite compläte, la rÇalisation d''un objectif ou|',
  'une excellente nouvelle.|Il annonce un accomplissement, une vie bien ordonnÇe et une|protection bienveillante.|Il peut àtre un porte-bonheur : une chance insolite, un pari|',
  'rÇussi ou une transformation libÇratrice.|Remporter la bataille montre que vous avez la force de surmonter|vos contradictions.|Une libÇration bienvenue survient ; ce qui Çtait bloquÇ se dÇnoue|enfin.|',
  'Tenir l''arme avec calme montre que vous assumez votre force et|savez vous protÇger.|Repousser l''attaque indique que vous savez dÇfendre vos limites|et affirmer votre place.|',
  'Vous vous libÇrez d''une emprise ou d''un comportement ancien ; un|changement dÇcisif s''opäre.|Vous affirmez enfin votre point de vue ; ce conflit ouvert peut|clarifier une relation.|',
  'Apräs l''incendie, un renouveau devient possible ; une situation|dÇpassÇe laisse place au neuf.|Sortir indemne d''un accident montre votre rÇsilience et une|protection face aux imprÇvus.|',
  'Survivre Ö la catastrophe rÇväle des ressources insoupáonnÇes et|la capacitÇ de tout reconstruire.|êchapper Ö vos ravisseurs annonce une reprise en main de votre vie|et de vos dÇcisions.|',
  'Affronter la menace sans flÇchir rÇväle un courage qui vous aidera|Ö rÇsoudre un probläme rÇel.|Surprendre le cambrioleur montre que vous savez protÇger votre|territoire et vos ressources.|',
  'Trouver l''antidote ou refuser le poison annonce une guÇrison et|l''Çloignement d''une influence nÇfaste.|Vous survivez Ö l''effondrement : une structure dÇpassÇe tombe|',
  'pour laisser place Ö une reconstruction.|Vous rÇagissez Ö temps ; votre vigilance vous permet d''Çviter une|difficultÇ.|Neutraliser le terroriste montre que vous reprenez le contrìle|',
  'face Ö un dÇsordre intÇrieur.|Votre libÇration annonce la fin d''une contrainte et la reconquàte|de votre autonomie.|êchapper au danger rÇväle votre luciditÇ et votre capacitÇ Ö faire|',
  'face aux Çpreuves.|Un monstre qui devient amical rÇväle que vous apprivoisez une part|de vous longtemps rejetÇe.|Chevaucher ou apprivoiser un dragon annonce une maåtrise de vos|',
  'forces et une grande rÇussite.|Une bonne fÇe annonce l''aide inattendue d''une personne|bienveillante ou un voeu en passe de se rÇaliser.|',
  'Une licorne qui vient Ö vous annonce la rÇalisation d''un idÇal ou|une pÇriode de grÉce.|Un contact paisible avec des extraterrestres annonce une ouverture|d''esprit et des perspectives inÇdites.|',
  'Une sorciäre bienveillante vous invite Ö faire confiance Ö votre|intuition et Ö vos dons cachÇs.|Repousser un vampire montre que vous apprenez Ö protÇger votre|Çnergie et Ö poser des limites.|',
  'Fuir ou vaincre des zombies annonce que vous sortez d''une routine|Çteinte et retrouvez votre Çlan.|Devenir un loup-garou sans crainte suggäre que vous intÇgrez une|force instinctive jusque-lÖ niÇe.|',
  'Un gÇant bienveillant annonce une protection puissante ou un|projet qui prend une belle ampleur.|Un lutin facÇtieux annonce une heureuse surprise et vous invite Ö|cultiver l''humour et la spontanÇitÇ.|',
  'Un robot serviable annonce une efficacitÇ accrue et une aide|prÇcieuse pour vos tÉches quotidiennes.|Utiliser vos pouvoirs avec aisance annonce une confiance|grandissante et la rÇussite d''un dÇfi.|',
  'Jouir de l''invisibilitÇ exprime un besoin de libertÇ, de recul et|d''observation avant d''agir.|Un voyage dans le temps joyeux annonce la rÇconciliation avec|votre histoire ou un avenir prometteur.|',
  'Une siräne bienveillante annonce une rencontre envoñtante ou un|Çveil de votre sensibilitÇ crÇatrice.|Un phÇnix flamboyant annonce une renaissance apräs l''Çpreuve et|le retour d''une force nouvelle.|',
  'Accomplir un tour de magie rÇussi annonce une transformation|heureuse et une confiance en vos talents.|Une crÇature amicale annonce l''intÇgration d''un talent original|',
  'ou d''une part inÇdite de vous-màme.|Traverser la fin du monde avec calme annonce un renouveau profond|et la naissance d''une autre vie.|Observer un dinosaure paisible invite Ö puiser dans la force|',
  'tranquille de vos racines.|Trouble ou stagnante, elle signale des Çmotions confuses ou|refoulÇes qu''il serait bon de laisser s''exprimer.|',
  'DÇchaånÇe ou menaáante, elle exprime la crainte d''àtre submergÇ|par vos Çmotions ou par une situation trop vaste.|Une vague gÇante rÇväle la peur d''àtre dÇbordÇ par une Çmotion ou|',
  'un bouleversement ; il s''agit d''apprendre Ö composer avec lui.|Un torrent impÇtueux ou une rive inaccessible signale un obstacle|Ö franchir ou une transition qui vous inquiäte.|',
  'Une eau sombre ou vaseuse suggäre des sentiments stagnants ou des|souvenirs que vous hÇsitez Ö explorer.|Une pluie froide et incessante refläte une tristesse diffuse ou|',
  'une lassitude qui demande du rÇconfort.|Se voir emportÇ par les eaux rÇväle un sentiment d''impuissance|face Ö des Çmotions ou des ÇvÇnements qui vous dÇpassent.|',
  'Glisser ou rester prisonnier de la glace rÇväle une relation|refroidie ou des sentiments que vous n''osez plus exprimer.|Une neige qui isole ou une tempàte de neige refläte une solitude,|',
  'un engourdissement affectif ou un projet gelÇ.|Une chute d''eau assourdissante ou dangereuse traduit une Çmotion|trop intense que vous craignez de ne pas contenir.|',
  'Une source tarie ou souillÇe signale une fatigue profonde : il est|temps de revenir Ö ce qui vous nourrit vraiment.|S''enliser dans la boue traduit la sensation d''àtre bloquÇ, de|',
  'piÇtiner ou de porter une culpabilitÇ inutile.|Une plage dÇserte ou envahie par la marÇe Çvoque une solitude ou|la sensation que les choses vous Çchappent.|',
  'Se retrouver naufragÇ sur une åle suggäre que vous vous sentez|coupÇ des autres ou incompris dans votre entourage.|Une pente infranchissable ou une chute depuis une falaise traduit|',
  'un objectif Çcrasant ou la crainte de l''Çchec.|Une vallÇe sombre ou un ravin profond traduit un moment de|dÇcouragement, une baisse de moral qui reste passagäre.|',
  'Errer assoiffÇ dans le dÇsert traduit un vide affectif, un manque|de soutien ou une phase de stÇrilitÇ crÇatrice.|Une foràt obscure et oppressante refläte une confusion, des|',
  'craintes inconscientes ou un chemin de vie incertain.|Un arbre mort, abattu ou malade Çvoque une baisse d''Çnergie ou un|lien familial fragilisÇ qu''il faut soigner.|',
  'Des racines arrachÇes ou pourries suggärent un sentiment de|dÇracinement ou un conflit avec votre histoire familiale.|Des feuilles mortes emportÇes par le vent traduisent une nostalgie|',
  'ou la nÇcessitÇ d''accepter une fin naturelle.|Des fleurs fanÇes traduisent une dÇception, une beautÇ que l''on|sent passer ou une relation qui manque de soins.|',
  'Se piquer Ö ses Çpines ou voir une rose flÇtrie traduit une|blessure amoureuse ou la crainte d''àtre dÇáu.|Un jardin en friche ou envahi de mauvaises herbes invite Ö|',
  'remettre de l''ordre dans vos prioritÇs ou vos relations.|Une prairie dessÇchÇe ou piÇtinÇe suggäre une lassitude, un manque|d''espace personnel ou un besoin de ressourcement.|',
  'Se perdre ou rester piÇgÇ dans une caverne obscure traduit la peur|de vos zones d''ombre ou un repli excessif sur vous-màme.|Une pierre lourde Ö porter ou qui bloque le passage traduit un|',
  'fardeau, un obstacle ou une insensibilitÇ qui vous päse.|Tomber dans un puits ou le trouver Ö sec traduit la crainte de|sombrer dans vos pensÇes ou un Çpuisement moral.|',
  'Une Çruption menaáante signale des tensions accumulÇes : exprimer|ce que vous ressentez Çviterait l''explosion.|Errer dans une brume Çpaisse refläte un manque de repäres, une|',
  'dÇcision difficile ou la peur de vous tromper.|Un champ stÇrile ou ravagÇ invite Ö revoir vos mÇthodes ou Ö|patienter avant de voir vos efforts porter leurs fruits.|',
  'Une bàte menaáante dÇsigne une pulsion refoulÇe qui rÇclame|d''àtre reconnue plutìt que combattue.|Il peut signaler une mÇfiance envers un proche, ou un dÇsir que|vous refoulez et qui vous inquiäte.|',
  'Un chat qui griffe invite Ö vous mÇfier d''une hypocrisie ou Ö|reconnaåtre votre propre besoin d''autonomie.|Un chien qui aboie ou mord signale un conflit avec un proche ou|',
  'une loyautÇ que vous sentez trahie.|Un cheval emballÇ suggäre des passions difficiles Ö canaliser ou|un rythme de vie qui vous dÇpasse.|Un loup menaáant traduit la crainte d''une agression ou une|',
  'aviditÇ intÇrieure que vous redoutez.|Un ours agressif peut figurer une figure parentale Çtouffante ou|une coläre rentrÇe pràte Ö surgir.|',
  'Un lion qui rugit contre vous Çvoque un conflit avec une autoritÇ|ou un orgueil qui vous isole.|Un tigre qui vous traque suggäre une impulsion violente ou un|dÇsir qui vous effraie par son intensitÇ.|',
  'Un oiseau blessÇ ou en cage traduit une aspiration contrariÇe ou|un sentiment d''enfermement.|Un aigle qui fond sur vous peut reflÇter une pression d''en haut|ou une ambition qui devient dÇvorante.|',
  'Un corbeau croassant refläte des pensÇes sombres ou la crainte|d''une mauvaise nouvelle, souvent exagÇrÇe.|Un hibou inquiÇtant peut exprimer une solitude pesante ou des|',
  'secrets que vous redoutez de dÇcouvrir.|Une colombe blessÇe invite Ö protÇger une paix fragile ou une|innocence que vous sentez menacÇe.|',
  'Un poisson mort traduit une intuition nÇgligÇe ou une pÇriode de|stagnation Çmotionnelle.|Un requin qui attaque signale une rivalitÇ fÇroce ou une pulsion|agressive que vous gardez cachÇe.|',
  'Une baleine qui vous engloutit traduit la peur d''àtre submergÇ|par vos Çmotions ou par une figure maternelle.|Un dauphin ÇchouÇ invite Ö prendre soin de votre spontanÇitÇ et de|',
  'votre besoin de liens sincäres.|Une araignÇe inquiÇtante suggäre une situation oó vous vous sentez|piÇgÇ ou une influence possessive.|Une invasion d''insectes refläte des soucis accumulÇs ou un|',
  'malaise physique qu''il serait bon d''Çcouter.|Une piqñre d''abeille signale une petite blessure d''amour-propre|ou une surcharge de travail.|',
  'Des fourmis envahissantes reflätent de petites contrariÇtÇs ou le|sentiment d''àtre un simple rouage.|Un essaim de mouches suggäre des ragots, une nÇgligence ou des|',
  'soucis qui s''accumulent autour de vous.|Un papillon qui ne parvient pas Ö voler traduit une Çvolution|freinÇe ou une inconstance qui vous päse.|',
  'Des rats grouillants signalent une mÇfiance envers l''entourage,|une culpabilitÇ ou une inquiÇtude qui ronge.|Des souris qui envahissent la maison traduisent des tracas|',
  'domestiques ou un manque d''affirmation de soi.|Un lapin apeurÇ refläte une timiditÇ excessive ou le dÇsir de fuir|une situation qui vous dÇpasse.|',
  'Un cerf traquÇ Çvoque une vulnÇrabilitÇ, ou la crainte de voir|votre dignitÇ attaquÇe.|Un taureau qui charge signale une coläre, un rapport de force ou|une passion qui menace de dÇborder.|',
  'Des vaches maigres invitent Ö la prÇvoyance et Ö mÇnager vos|ressources pour quelque temps.|Un cochon qui se vautre suggäre un sentiment de saletÇ, d''excäs|ou un jugement sÇväre sur vos dÇsirs.|',
  'Suivre le troupeau sans rÇflÇchir vous invite Ö affirmer davantage|vos opinions et vos choix propres.|Un singe moqueur signale une flatterie trompeuse ou la crainte de|',
  'paraåtre ridicule aux yeux des autres.|Un ÇlÇphant furieux Çvoque un souvenir lourd qui refait surface ou|un probläme trop longtemps ignorÇ.|',
  'Un crocodile qui guette rÇväle une mÇfiance envers une personne|fausse ou une pulsion dÇvorante.|Un crapaud rÇpugnant refläte un dÇgoñt de soi ou d''une situation|qui demande Ö àtre transformÇe.|',
  'Une tortue renfermÇe dans sa carapace Çvoque une tendance Ö vous|isoler ou une lenteur qui vous frustre.|Un escargot ÇcrasÇ ou baveux refläte l''impatience, l''agacement|',
  'face Ö une situation qui traåne.|Des vers grouillants traduisent un dÇgoñt, une culpabilitÇ ou un|probläme qui ronge en silence.|Une piqñre de scorpion signale une trahison redoutÇe ou une|',
  'rancune qui vous empoisonne.|Un renard qui rìde vous met en garde contre un flatteur ou une|manipulation dans votre entourage.|Des chauves-souris affolÇes traduisent des angoisses diffuses ou|',
  'une relation qui Çpuise votre Çnergie.|Un coq agressif peut signaler une rivalitÇ d''orgueil ; une poule|affolÇe, une inquiÇtude pour les proches.|',
  'Un cygne noir ou blessÇ Çvoque une mÇlancolie amoureuse ou un|ÇvÇnement inattendu Ö apprivoiser.|Des cafards qui grouillent reflätent un sentiment de honte, de|saletÇ ou un dÇcouragement persistant.|',
  'Un paon criard met en garde contre la vanitÇ ou contre une|apparence qui masque vos vrais besoins.|Un bouc menaáant renvoie Ö une pulsion jugÇe honteuse ou Ö la|crainte de servir de bouc Çmissaire.|',
  'Un corps abåmÇ ou Çtranger invite Ö Çcouter une fatigue, un|malaise ou une image de vous que vous jugez trop sÇvärement.|Des dents qui tombent ou se brisent signalent une peur de perdre|',
  'votre pouvoir ou votre image ; c''est une Çtape Ö traverser, non|une fatalitÇ.|Perdre ses cheveux ou les voir coupÇs de force traduit une crainte|',
  'de vieillir, de perdre votre force ou le contrìle de votre image.|Des yeux blessÇs, fermÇs ou menaáants suggärent une rÇalitÇ que|vous Çvitez de regarder, ou la crainte d''àtre jugÇ.|',
  'Une bouche cousue, blessÇe ou incapable de s''ouvrir Çvoque des|mots retenus et un besoin urgent de vous exprimer.|Des mains liÇes, sales ou blessÇes traduisent un sentiment|',
  'd''impuissance, une culpabilitÇ ou une difficultÇ Ö agir.|Des pieds blessÇs ou entravÇs indiquent une hÇsitation Ö avancer,|un manque d''appui ou la crainte de faire fausse route.|',
  'Des jambes qui flanchent ou refusent d''avancer reflätent un|manque de soutien, une fatigue ou la peur de ne pas tenir.|Un bras blessÇ, coupÇ ou paralysÇ Çvoque une perte de moyens,|',
  'l''absence d''un appui ou la crainte de ne plus pouvoir agir.|Une tàte blessÇe, lourde ou perdue signale une surcharge mentale,|un doute sur vos choix ou une perte de repäres.|',
  'Un visage flou, dÇformÇ ou sans traits traduit une incertitude sur|votre identitÇ ou la peur de ne pas àtre reconnu.|Un coeur douloureux ou arràtÇ Çvoque une blessure affective ou un|',
  'Çpuisement ; il vous invite Ö prendre soin de vous.|Des maux de ventre signalent une situation difficile Ö digÇrer,|une inquiÇtude sourde ou une Çmotion longtemps contenue.|',
  'Une peau irritÇe ou couverte de marques rÇväle une susceptibilitÇ|Ö vif, un malaise social ou la peur d''àtre exposÇ.|Une plaie vive ou qui saigne rÇväle une souffrance non reconnue ;|',
  'il est temps de nommer ce qui vous a touchÇ.|Une cicatrice qui se rouvre ou vous fait honte suggäre qu''un|souvenir douloureux demande encore Ö àtre apaisÇ.|',
  'Une maladie qui s''aggrave traduit une inquiÇtude envahissante ou|un Çpuisement ; accordez-vous repos et bienveillance.|Une grossesse inquiÇtante refläte la peur de nouvelles|',
  'responsabilitÇs ou le doute face Ö un changement qui se prÇpare.|Des nausÇes sans fin signalent un dÇgoñt refoulÇ ou une situation|imposÇe que vous peinez Ö refuser.|',
  'Perdre la vue avec effroi signale un aveuglement face Ö une|rÇalitÇ dÇrangeante ou la peur de perdre le contrìle.|Rester sans voix au moment de parler traduit un sentiment|',
  'd''impuissance ou la crainte de ne pas àtre ÇcoutÇ.|Devenir sourd ou souffrir des oreilles Çvoque des paroles que vous|refusez d''entendre ou une rumeur qui vous blesse.|',
  'Un nez qui saigne ou qui grandit, comme celui de Pinocchio, peut|signaler une gàne liÇe Ö un mensonge ou Ö l''orgueil.|Des ongles cassÇs, arrachÇs ou rongÇs traduisent une nervositÇ,|',
  'une vulnÇrabilitÇ passagäre ou une coläre rÇprimÇe.|Un doigt coupÇ ou blessÇ peut Çvoquer la perte d''un savoir-faire,|d''un lien familial ou d''un moyen d''agir.|',
  'Une barbe arrachÇe ou mal rasÇe traduit une autoritÇ contestÇe ou|la crainte de ne pas àtre pris au sÇrieux.|Un dos courbÇ ou douloureux signale un fardeau trop lourd, ou la|',
  'crainte d''une trahison venant de derriäre.|Une sensation d''Çtouffement trahit des mots ravalÇs ou une|situation qui vous oppresse ; exprimez-vous sans tarder.|',
  'Une langue coupÇe, gonflÇe ou paralysÇe Çvoque une parole|censurÇe, un remords ou la peur d''avoir trop parlÇ.|Une nuditÇ honteuse devant une foule traduit la peur d''àtre percÇ|',
  'Ö jour ; vous àtes souvent plus sÇväre que les autres.|Une märe absente ou Çtouffante traduit un besoin d''autonomie ou|une blessure affective ancienne Ö apaiser.|',
  'Un päre sÇväre ou absent Çvoque un conflit avec l''autoritÇ, un|besoin de reconnaissance ou une exigence trop lourde.|Des parents en conflit ou indiffÇrents reflätent un tiraillement|',
  'entre loyautÇ et libertÇ, ou un besoin d''Çmancipation.|Un enfant perdu ou en pleurs Çvoque une part de vous nÇgligÇe qui|rÇclame Çcoute, protection et tendresse.|',
  'Un bÇbÇ oubliÇ ou difficile Ö calmer traduit la crainte de ne pas|àtre Ö la hauteur d''une responsabilitÇ naissante.|Une dispute avec un fräre rÇväle une rivalitÇ ancienne, une|',
  'jalousie mal digÇrÇe ou un besoin de reconnaissance.|Un conflit avec une soeur traduit une comparaison douloureuse ou|un besoin d''affirmer votre place dans la famille.|',
  'Des grands-parents malades ou disparus Çvoquent la crainte de|perdre vos repäres ou un deuil encore sensible.|Une famille dÇchirÇe ou hostile rÇväle des tensions non dites ou|',
  'le besoin de trouver votre place hors du clan.|Un mari distant ou infidäle en ràve traduit davantage une|insÇcuritÇ ou un besoin d''attention qu''un fait rÇel.|',
  'Une Çpouse fÉchÇe ou lointaine refläte une nÇgligence affective ou|une part intuitive de vous trop souvent ignorÇe.|Un ami qui vous tourne le dos signale une crainte de rejet ou une|',
  'valeur que vous dÇlaissez en ce moment.|Un inconnu menaáant figure une part refoulÇe qui demande Ö àtre|reconnue ; l''affronter en ràve dÇsamorce la peur.|',
  'Une foule oppressante traduit la peur du jugement, un besoin de|solitude ou la crainte de perdre votre singularitÇ.|Une cÇlÇbritÇ mÇprisante Çvoque la peur de rester dans l''ombre ou|',
  'une comparaison qui dÇvalorise vos propres atouts.|Un roi tyrannique ou dÇchu refläte un abus d''autoritÇ, la vìtre|ou celle d''autrui, ou une confiance en soi ÇbranlÇe.|',
  'Une reine froide ou cruelle Çvoque une figure fÇminine dominatrice|ou une exigence de perfection qui vous päse.|Un prince arrogant ou dÇcevant invite Ö revoir des attentes trop|',
  'idÇalisÇes envers l''amour ou envers vous-màme.|Une princesse enfermÇe ou capricieuse Çvoque une attente passive,|ou une sensibilitÇ qui se sent prisonniäre.|',
  'Se faire arràter par la police traduit une culpabilitÇ excessive|ou la peur d''àtre pris en faute pour un Çcart minime.|Se faire voler exprime la crainte de perdre ce qui compte ou le|',
  'sentiment qu''on profite de votre gÇnÇrositÇ.|Des soldats menaáants traduisent un conflit intÇrieur, une|pression extÇrieure ou des rägles vÇcues comme oppressantes.|',
  'Un mÇdecin inquiÇtant ou impuissant traduit une anxiÇtÇ pour votre|santÇ ou la crainte de ne pas àtre compris.|Un professeur sÇväre ou humiliant refläte la peur de l''Çchec ou|',
  'un perfectionnisme qui vous empàche d''oser.|Un clown inquiÇtant Çvoque une gaietÇ de faáade, une hypocrisie|autour de vous ou la peur du ridicule.|',
  'Un vieillard malade ou hostile traduit la peur de vieillir, de|stagner ou de suivre des idÇes devenues dÇpassÇes.|Un ennemi invisible ou tout-puissant traduit un sentiment de|',
  'menace diffuse ou une autocritique trop sÇväre.|Un double hostile ou qui prend votre place rÇväle un conflit|intÇrieur ou la peur de perdre votre identitÇ.|',
  'Un voisin envahissant ou hostile traduit un besoin de protÇger|votre intimitÇ ou des limites mal posÇes.|Une maison dÇlabrÇe ou hostile signale une fatigue morale et le|',
  'besoin de remettre de l''ordre dans votre vie intime.|Une maison d''enfance sombre ou mÇconnaissable Çvoque une blessure|ancienne qui demande enfin Ö àtre reconnue et apaisÇe.|',
  'Une chambre envahie ou inquiÇtante suggäre que votre espace intime|est menacÇ ou que vous manquez de vrai repos.|Une cuisine vide ou en dÇsordre rÇväle un manque de soin envers|',
  'vous-màme ou une relation qui ne vous nourrit plus.|Une salle de bain sale ou inutilisable traduit la difficultÇ Ö|vous libÇrer d''un malaise ou d''un sentiment de souillure.|',
  'Des toilettes bouchÇes ou sans porte Çvoquent la gàne de vous|exposer ou des Çmotions retenues trop longtemps.|Une cave obscure et menaáante traduit des pulsions ou des|',
  'souvenirs refoulÇs qui päsent sur vous depuis longtemps.|Un grenier poussiÇreux ou encombrÇ signale des pensÇes ressassÇes|et un passÇ qu''il serait temps de trier.|',
  'Des marches qui cädent ou un escalier sans fin traduisent un doute|sur vos capacitÇs ou un projet qui piÇtine.|Une porte verrouillÇe ou forcÇe exprime un obstacle, une intrusion|',
  'redoutÇe ou une chance que vous n''osez pas saisir.|Une fenàtre condamnÇe ou embuÇe suggäre un manque de recul, un|isolement ou la crainte d''àtre observÇ.|',
  'Se heurter Ö un mur traduit un blocage, une impasse relationnelle|ou une rÇsistance intÇrieure Ö dÇpasser.|Un toit qui fuit ou s''effondre Çvoque une protection qui vous|',
  'fait dÇfaut ou des idÇes qui vous dÇbordent.|Un couloir interminable ou sombre traduit l''impatience,|l''incertitude ou la sensation de tourner en rond.|',
  'Un ascenseur bloquÇ ou en chute libre traduit la crainte de perdre|le contrìle ou de voir votre situation se dÇgrader.|Une piäce cachÇe inquiÇtante dÇsigne un secret, un souvenir ou un|',
  'dÇsir que vous tenez Ö l''Çcart et qui demande attention.|Se perdre dans une Çcole ou retourner en classe adulte exprime la|crainte de ne pas àtre Ö la hauteur.|',
  'Un hìpital oppressant rÇväle une inquiÇtude pour votre santÇ ou|celle d''un proche, ou un Çpuisement Ö ne pas nÇgliger.|Une captivitÇ sans espoir signale une culpabilitÇ ou une situation|',
  'qui vous paralyse et qu''il faut oser remettre en cause.|Un chÉteau assiÇgÇ ou inaccessible suggäre des dÇfenses trop|rigides ou un idÇal qui vous isole des autres.|',
  'Une ville dÇserte ou oó vous vous Çgarez traduit un sentiment|d''anonymat ou la difficultÇ Ö trouver votre place.|Une impasse ou une ruelle inquiÇtante Çvoque un choix difficile ou|',
  'la crainte d''un regard extÇrieur.|Errer sans fin dans un dÇdale traduit l''indÇcision, la confusion|ou la sensation d''àtre piÇgÇ par une situation.|',
  'Des rayons vides ou un magasin fermÇ traduisent un sentiment de|manque ou la peur de passer Ö cìtÇ de quelque chose.|Un service nÇgligent ou une commande impossible exprime un besoin|',
  'affectif inassouvi ou un sentiment d''àtre nÇgligÇ.|Un hìtel oó l''on perd sa chambre traduit l''instabilitÇ, un|manque d''ancrage ou une identitÇ en suspens.|',
  'Des ruines dÇsolantes reflätent la nostalgie d''un projet|abandonnÇ ou la douleur d''une perte encore vive.|Une tour qui vacille ou oó vous àtes enfermÇ signale un orgueil|',
  'fragile ou un retrait excessif hors du monde.|Oublier son texte ou monter sur scäne sans prÇparation traduit la|crainte du jugement ou du manque de lÇgitimitÇ.|',
  'Une piscine vide ou trouble rÇväle une sÇcheresse affective ou des|Çmotions que vous peinez Ö contenir.|Un palais froid ou interdit traduit un idÇal hors d''atteinte ou|',
  'une recherche de prestige qui vous coupe du simple bonheur.|Un village hostile ou fermÇ traduit la peur du qu''en-dira-t-on ou|le sentiment d''àtre exclu d''un groupe.|',
  'Perdre ses clÇs ou en avoir une qui ne tourne pas traduit un|sentiment d''impuissance ou une occasion qui vous Çchappe.|Une serrure grippÇe ou forcÇe exprime la crainte d''une intrusion|',
  'ou un accäs Ö vous-màme encore refusÇ.|Un miroir brisÇ ou un reflet dÇformÇ exprime une crise|d''identitÇ, un doute sur votre valeur ou une image ternie.|',
  'Un tÇlÇphone qui ne fonctionne pas ou un numÇro impossible Ö|composer traduit un dialogue bloquÇ ou un isolement.|Une panne, un virus ou des donnÇes perdues signalent une fatigue|',
  'mentale ou la crainte de perdre la maåtrise.|Un livre illisible ou dont les pages s''effacent traduit une|incomprÇhension ou un savoir qui vous Çchappe encore.|',
  'Une lettre perdue ou illisible traduit un malentendu, une parole|retenue ou une nouvelle que vous redoutez.|Une photo dÇchirÇe ou effacÇe exprime la crainte d''oublier, une|',
  'relation qui s''Çloigne ou une image de soi dÇpassÇe.|Perdre son sac ou le trouver trop lourd traduit une perte de|repäres ou des responsabilitÇs pesantes.|',
  'Un parapluie qui se retourne ou qui manque traduit le sentiment|d''àtre exposÇ et sans dÇfense.|Une bougie qui s''Çteint exprime une lassitude, un espoir qui|vacille ou la crainte de perdre un repäre.|',
  'Une lampe qui grÇsille ou refuse de s''allumer traduit le doute,|la confusion ou le manque de repäres.|Une horloge arràtÇe ou qui s''emballe traduit la pression du|',
  'temps, une ÇchÇance redoutÇe ou un deuil non fait.|Perdre ou briser une bague exprime un doute sur un engagement ou|la peur d''une rupture.|Un bijou volÇ ou faux traduit la crainte d''àtre dÇvalorisÇ,|',
  'trompÇ ou de perdre ce qui vous est cher.|Une couronne trop lourde ou perdue traduit le poids des|responsabilitÇs ou la crainte de perdre votre statut.|',
  'Une lame pointÇe vers vous traduit une hostilitÇ ressentie, des|paroles blessantes ou un conflit intÇrieur aigu.|Des liens qui vous entravent ou une corde qui se rompt traduit une|',
  'dÇpendance pesante ou la peur de perdre un soutien.|Se voir enchaånÇ exprime un sentiment de captivitÇ, une|culpabilitÇ ou une obligation qui vous Çtouffe.|',
  'Un coffre vide ou impossible Ö ouvrir exprime une dÇception, un|secret pesant ou un potentiel inaccessible.|Un cadeau dÇcevant ou refusÇ traduit la crainte de ne pas àtre|',
  'apprÇciÇ ou un Çchange affectif dÇsÇquilibrÇ.|Se couper sur du verre traduit une blessure affective rÇcente ou|la peur qu''une relation fragile ne se brise.|',
  'Une Çchelle branlante ou trop courte exprime la peur de l''Çchec|ou une ambition mal assurÇe.|Un masque qu''on ne peut ìter ou des visages masquÇs traduisent la|',
  'mÇfiance, la dissimulation ou la peur d''àtre dÇmasquÇ.|Une poupÇe inquiÇtante ou une marionnette manipulÇe traduit la|sensation d''àtre instrumentalisÇ ou un malaise ancien.|',
  'Un jouet cassÇ exprime une dÇception d''enfance ou la nostalgie|d''une innocence perdue.|Un ballon qui cräve ou s''Çchappe traduit une dÇsillusion ou un|espoir qui vous file entre les doigts.|',
  'Une carte illisible ou fausse traduit l''indÇcision, la perte de|repäres ou un plan qui ne correspond plus Ö vos dÇsirs.|Une boussole affolÇe traduit la confusion des valeurs,|',
  'l''indÇcision ou l''influence d''autrui sur vos choix.|Une ÇpÇe brisÇe ou retournÇe contre vous traduit un conflit|intÇrieur ou un pouvoir que vous craignez de mal employer.|',
  'Une bouteille vide ou brisÇe traduit un Çpuisement, une attente|dÇáue ou une Çmotion trop longtemps contenue.|Un lit dÇfait ou occupÇ par un inconnu traduit un trouble dans|',
  'l''intimitÇ ou un Çpuisement non reconnu.|Ne pas trouver de chaise ou s''asseoir sur une chaise bancale|traduit le sentiment de ne pas avoir sa place.|',
  'Une table vide ou renversÇe traduit un conflit familial, une|solitude ou un accord rompu.|Une tÇlÇvision qui ne s''Çteint pas traduit une passivitÇ, un|',
  'trop-plein d''informations ou une fuite devant le rÇel.|Se retrouver dans une cage traduit le sentiment d''àtre prisonnier|d''une situation, d''un rìle ou du regard d''autrui.|',
  'Perdre le contrìle de la voiture ou àtre passager malgrÇ vous|traduit le sentiment de subir les ÇvÇnements.|Des freins qui lÉchent traduisent un surmenage, une perte de|',
  'maåtrise ou un engrenage dont vous voulez sortir.|Un train qui dÇraille ou qui part dans la mauvaise direction|traduit le doute sur la voie choisie.|',
  'Une gare dÇserte ou un quai interminable traduit l''indÇcision, la|solitude ou la sensation d''àtre laissÇ de cìtÇ.|Un avion en difficultÇ traduit la peur de l''Çchec apräs une|',
  'ascension trop rapide ou un manque de maåtrise.|Errer dans un aÇroport traduit une dÇcision retardÇe,|l''inquiÇtude face au changement ou l''impression de stagner.|',
  'Un bateau secouÇ par la houle traduit des Çmotions difficiles Ö|maåtriser ou un passage dÇlicat Ö traverser.|Sombrer avec le navire traduit un sentiment d''impuissance face Ö|',
  'des Çmotions envahissantes qu''il faut accueillir.|Tomber de vÇlo ou pÇdaler dans le vide traduit un dÇsÇquilibre ou|des efforts qui semblent ne mener nulle part.|',
  'Un bus bondÇ ou qui ne s''arràte pas traduit le sentiment d''àtre|anonyme ou de manquer une occasion collective.|Se perdre dans le mÇtro ou rester coincÇ sous terre traduit|',
  'l''oppression du quotidien ou une routine Çtouffante.|Une moto incontrìlable traduit une impulsivitÇ dangereuse ou un|besoin de libertÇ qui vous Çchappe.|',
  'Une route barrÇe ou dÇfoncÇe traduit des obstacles, une hÇsitation|sur la voie Ö suivre ou une fatigue du parcours.|Rester figÇ au croisement traduit la peur de se tromper ou un|',
  'tiraillement entre des dÇsirs contradictoires.|Un pont qui s''effondre ou trop Çtroit traduit la peur du|changement ou une communication difficile.|',
  'Un tunnel interminable ou qui s''effondre traduit l''enlisement,|l''oppression ou la peur de ne pas en sortir.|Une valise trop lourde ou perdue traduit le poids du passÇ ou|',
  'l''angoisse de partir sans l''essentiel.|Perdre son billet ou en avoir un mauvais traduit le doute sur|votre droit d''avancer ou une prÇparation insuffisante.|',
  'Se voir refoulÇ Ö la frontiäre traduit une autocensure, un|sentiment d''illÇgitimitÇ ou un obstacle extÇrieur.|Un taxi qui se perd ou ne s''arràte pas traduit la dÇfiance envers|',
  'autrui ou la crainte de dÇpendre des autres.|Rester coincÇ sans issue traduit la frustration, l''impatience ou|un manque de place pour avancer Ö votre rythme.|',
  'Courir en vain apräs le dÇpart traduit la surcharge, la peur|d''àtre en retard sur votre vie ou une occasion manquÇe.|Un vol laborieux ou trop haut peut signaler une fuite hors du rÇel|',
  'ou une ambition qui vous coupe de vos appuis concrets.|Une chute vertigineuse rÇväle une insÇcuritÇ aiguâ, la crainte|d''un revers ou le sentiment que le sol se dÇrobe sous vos pas.|',
  'Une traque interminable signale une pression accumulÇe ou un|conflit intÇrieur que la fuite ne fait qu''entretenir.|Une fuite sans issue montre qu''un probläme esquivÇ vous rattrape|',
  '; il gagnerait Ö àtre affrontÇ Ö votre rythme.|Courir sans avancer, les jambes lourdes, Çvoque un sentiment|d''impuissance ou l''Çpuisement d''un effort qui ne paie pas|encore.|',
  'Nager Ö contre-courant ou dans une eau trouble signale une lutte|Çmotionnelle Çpuisante ou une situation confuse Ö clarifier.|Une noyade angoissante traduit une surcharge affective ou|',
  'professionnelle ; il est temps de poser des limites et de demander|de l''aide.|Une perte affolante rÇväle une insÇcuritÇ, la peur d''un manque ou|',
  'le sentiment de laisser filer quelque chose d''essentiel.|Chercher sans fin ce qu''on ne trouve pas Çvoque une frustration,|un manque diffus ou une attente que vous n''avez pas encore|nommÇe.|',
  'Trouver quelque chose d''inquiÇtant signale une vÇritÇ dÇrangeante|qui remonte ; mieux vaut l''accueillir que l''enfouir de nouveau.|Un retard qui fait tout manquer rÇväle un stress de performance ou|',
  'une dÇcision repoussÇe trop longtemps qui vous prÇoccupe.|Une copie blanche ou un sujet incomprÇhensible traduit la peur|d''àtre pris en dÇfaut et une exigence envers vous-màme trop|sÇväre.|',
  'Un cri qui reste bloquÇ dans la gorge rÇväle une frustration|ÇtouffÇe ou une situation oó vous vous sentez rÇduit au silence.|Une paralysie oppressante traduit l''impuissance ressentie face Ö|',
  'une pression ; respirer calmement aide souvent Ö s''en dÇgager.|Se cacher dans l''angoisse d''àtre dÇcouvert signale un secret|pesant ou la crainte que vos faiblesses soient exposÇes.|',
  'Une lutte Çpuisante et sans fin Çvoque des tensions accumulÇes ou|une agressivitÇ contenue qui demande un exutoire sain.|Danser maladroitement, ou seul sous les regards, traduit une gàne|',
  'sociale ou la peur de ne pas trouver votre place.|Une voix qui se brise ou chante faux rÇväle la crainte du jugement|ou une difficultÇ Ö exprimer sincärement vos sentiments.|',
  'Un rire moqueur ou incontrìlable peut trahir la peur du ridicule|ou une nervositÇ que vous cherchez Ö dissimuler.|Des pleurs inconsolables signalent une peine non reconnue qui|',
  'demande Ö àtre ÇcoutÇe, partagÇe et prise au sÇrieux.|Se sentir perdu et angoissÇ traduit un manque de repäres ou un|doute sur vos dÇcisions ; prenez le temps de redÇfinir vos|prioritÇs.|',
  'Glisser ou stagner pendant l''ascension Çvoque la crainte de|l''Çchec ou des objectifs trop lourds Ö porter seul.|Une descente sans fin ou forcÇe peut reflÇter la crainte d''une|',
  'perte de statut ou une humeur qui s''assombrit ; prenez soin de|vous.|Un saut hÇsitant ou manquÇ traduit la peur de vous engager ou|d''aller trop vite ; laissez mñrir votre choix avant de vous|Çlancer.|',
  'Un dÇmÇnagement chaotique exprime l''inquiÇtude face au changement|ou la difficultÇ Ö tourner une page de votre vie.|Une attente interminable traduit de l''impatience ou de la|',
  'passivitÇ ; peut-àtre est-il temps de provoquer vous-màme le|changement.|Un enfermement Çtouffant rÇväle une contrainte vÇcue comme|inextricable ; nommer ce qui vous retient est un premier pas vers|',
  'la sortie.|Ne pas parvenir Ö Çcrire, ou voir les mots s''effacer, suggäre une|difficultÇ Ö exprimer ce que vous ressentez vraiment.|Un Çdifice bancal ou inachevÇ Çvoque des doutes sur vos bases ou|',
  'un projet lancÇ trop vite qui demande Ö àtre consolidÇ.|Une saletÇ qui rÇsiste Ö tous vos efforts signale un souci tenace|ou un sentiment de faute Ö regarder avec plus d''indulgence.|',
  'Ouvrir avec apprÇhension, ou trouver un contenu menaáant, traduit|la crainte de ce qu''une vÇritÇ pourrait bouleverser.|Des faux rÇveils en sÇrie traduisent une prÇoccupation qui vous|',
  'suit jusque dans le sommeil ou une difficultÇ Ö lÉcher prise.|Une luciditÇ inquiäte, oó rien n''obÇit, suggäre un besoin de|contrìle qui gagnerait Ö laisser place Ö la curiositÇ.|',
  'Un màme cauchemar qui revient sans changer signale une blessure ou|un souci persistant ; en parler ou l''Çcrire aide Ö le dÇnouer.|Une vision funeste exprime surtout une inquiÇtude projetÇe vers|',
  'l''avenir ; elle invite Ö la prudence, non Ö la rÇsignation.|Un feu incontrìlable signale une passion dÇvorante ou une Çmotion|qui vous Çchappe et demande Ö àtre apaisÇe.|',
  'Un soleil brñlant ou voilÇ Çvoque une autoritÇ Çcrasante,|l''Çpuisement ou un doute passager sur votre valeur.|Une lune rouge ou inquiÇtante refläte une humeur instable, des|',
  'illusions ou un trouble liÇ Ö votre monde intime.|Une Çtoile qui s''Çteint traduit un idÇal dÇáu ou le sentiment|d''avoir perdu votre direction, Ö retrouver patiemment.|',
  'Un ciel bas et menaáant traduit des soucis qui päsent sur vous ou|un pessimisme qu''il serait bon de dissiper.|Des nuages noirs et lourds signalent une inquiÇtude qui|',
  's''accumule ou un conflit latent pràt Ö Çclater.|Se voir frappÇ par la foudre ou effrayÇ par le tonnerre traduit la|crainte d''un conflit ou d''une autoritÇ en coläre.|',
  'Se voir emportÇ par l''ouragan traduit un chaos Çmotionnel ou une|situation qui Çchappe Ö votre contrìle pour un temps.|Un vent violent qui vous renverse traduit l''impression d''àtre|',
  'ballottÇ par les ÇvÇnements ou par l''avis des autres.|Un arc-en-ciel qui s''efface ou reste hors d''atteinte suggäre un|espoir encore fragile, Ö nourrir par la patience.|',
  'Une terre aride ou qui se dÇrobe sous vos pas traduit un manque de|stabilitÇ ou l''impression de perdre vos repäres.|Voir tout s''effondrer autour de vous traduit une insÇcuritÇ|',
  'profonde ou la peur d''un changement brutal et imposÇ.|Une obscuritÇ totale ou angoissante rÇväle l''incertitude face Ö|l''inconnu ou la rencontre avec votre part d''ombre.|',
  'Une lumiäre aveuglante ou qui s''Çteint traduit une vÇritÇ|difficile Ö regarder en face ou une perte de repäres.|Une aube qui tarde Ö venir refläte l''impatience de sortir d''une|',
  'Çpreuve dont l''issue approche pourtant.|Un crÇpuscule inquiÇtant Çvoque la nostalgie, la crainte de|vieillir ou la difficultÇ Ö tourner une page.|',
  'DÇriver dans le vide spatial refläte un sentiment d''isolement ou|de dÇtachement excessif vis-Ö-vis des autres.|Elle peut traduire le sentiment d''àtre ÇclipsÇ par quelqu''un, ou|',
  'une baisse de confiance qui ne sera que passagäre.|Une fumÇe Çpaisse et suffocante signale un malaise diffus, des|non-dits ou une illusion qui brouille votre jugement.|',
  'Une morale trop sÇväre vous päse ; vous craignez peut-àtre un|jugement, qui est souvent le vìtre.|Un ange inquiÇtant ou dÇchu signale un idÇal trop ÇlevÇ qui vous|',
  'Çcrase, ou une exigence de perfection.|Vous vous sentez dominÇ par une tentation, une dÇpendance ou une|influence qui vous Çloigne de vous-màme.|',
  'Vous restez prisonnier d''un souvenir ou d''une culpabilitÇ|ancienne qui vous empàche d''avancer librement.|Une priäre dÇsespÇrÇe rÇväle un sentiment d''impuissance ; il est|',
  'temps de demander de l''aide autour de vous.|Une Çglise fermÇe ou dÇlabrÇe traduit une perte de repäres ou un|conflit avec les principes reáus dans l''enfance.|',
  'Un temple profanÇ ou inaccessible indique que vous nÇgligez votre|vie intÇrieure au profit de l''agitation.|Vous portez un fardeau trop lourd, peut-àtre par sens du sacrifice|',
  'ou par culpabilitÇ excessive.|Un pràtre sÇväre refläte un surmoi rigide, un jugement moral qui|vous culpabilise plus que nÇcessaire.|Vous risquez de vous isoler ou de vous priver excessivement, en|',
  'renonáant Ö des plaisirs lÇgitimes.|Un paradis perdu ou interdit rÇväle une idÇalisation qui vous rend|le prÇsent dÇcevant.|Vous vous enfermez dans une situation Çprouvante ou une|',
  'auto-accusation qui mÇrite d''àtre apaisÇe.|Attendre un miracle peut masquer une passivitÇ : la solution|dÇpend aussi de votre action.|Vous vous sacrifiez peut-àtre trop, au dÇtriment de vos propres|',
  'besoins et de votre Çquilibre.|Ne pas parvenir Ö mÇditer trahit une agitation mentale ;|accordez-vous davantage de repos.|Un guide trompeur met en garde contre une influence extÇrieure Ö|',
  'laquelle vous accordez trop de pouvoir.|Une prÇdiction inquiÇtante exprime surtout vos craintes ;|l''avenir reste ouvert et dÇpend de vos choix.|',
  'Un pälerinage interminable signale une quàte Çpuisante ou un but|que vous idÇalisez Ö l''excäs.|Tourner en rond dans un cercle traduit une situation rÇpÇtitive ou|un raisonnement sans issue.|',
  'Une Éme errante ou perdue indique que vous vous àtes ÇloignÇ de|vos vÇritables aspirations.|Une bÇnÇdiction refusÇe rÇväle un besoin d''approbation qui freine|vos initiatives personnelles.|',
  'Vous redoutez un changement ou une perte ; cette crainte mÇrite|d''àtre exprimÇe plutìt que subie.|Lutter contre la mort rÇväle une rÇsistance au changement ou un|Çpuisement qu''il faut Çcouter.|',
  'Un cadavre encombrant traduit un secret, une culpabilitÇ ou un|passÇ que vous refusez de regarder.|Se voir enfermÇ dans un cercueil exprime un sentiment|d''Çtouffement dans une situation figÇe.|',
  'Un enterrement pÇnible montre une difficultÇ Ö renoncer ;|accordez-vous le temps du deuil.|Errer dans un cimetiäre la nuit signale que le passÇ ou la|nostalgie occupent trop de place.|',
  'Un tombeau ouvert rÇväle qu''un souvenir enfoui ressurgit et|demande Ö àtre enfin compris.|Un squelette menaáant signale un secret ancien, un Çpuisement ou|une crainte liÇe au temps qui passe.|',
  'Une naissance difficile traduit les efforts et les doutes qui|accompagnent tout changement important.|Un mort qui revient sans cesse indique un probläme que vous|',
  'croyiez rÇglÇ mais qui rÇclame attention.|Un dÇfunt triste ou fÉchÇ refläte surtout vos propres regrets ; le|pardon, envers vous-màme aussi, est possible.|',
  'Vieillir brusquement exprime la crainte de manquer de temps ou de|laisser passer certaines occasions.|Une mÇtamorphose subie ou monstrueuse traduit la crainte de perdre|',
  'le contrìle de votre propre Çvolution.|Perdre du sang signale une fatigue, un Çpuisement ou une relation|qui vous vide de votre Çnergie.|Un hÇritage disputÇ rÇväle des tensions familiales ou le poids|',
  'd''un passÇ dont vous voulez vous affranchir.|Manger sans fin ou sans plaisir traduit un manque que vous tentez|de combler, souvent sur le plan affectif.|',
  'Un pain rassis ou qui manque traduit une inquiÇtude matÇrielle ou|le sentiment de ne pas recevoir votre juste part.|Des fruits verts ou abåmÇs suggärent une impatience, une occasion|',
  'manquÇe ou un projet encore immature.|Une pomme vÇreuse ou dÇfendue traduit un dÇsir qui vous trouble ou|la crainte d''une consÇquence de vos choix.|',
  'Un gÉteau ratÇ ou refusÇ traduit la crainte d''àtre privÇ de|reconnaissance ou une gourmandise culpabilisÇe.|En manger avec excäs ou culpabilitÇ rÇväle une frustration|',
  'affective ou une difficultÇ Ö vous faire plaisir sans remords.|Un lait renversÇ ou tournÇ traduit un manque de soutien affectif|ou la nostalgie d''une protection perdue.|',
  'L''ivresse ou l''excäs suggäre une fuite face Ö une rÇalitÇ|pesante ou une perte de contrìle que vous redoutez.|Une viande crue ou sanglante traduit une agressivitÇ contenue, une|',
  'pulsion qui vous dÇrange ou une grande fatigue.|Un oeuf brisÇ ou pourri traduit la crainte de voir Çchouer un|projet fragile ou une promesse non tenue.|',
  'Un miel collant ou trop sucrÇ met en garde contre une flatterie ou|une relation dont la douceur cache un piäge.|Se voir exclu de la fàte ou s''y sentir Çtranger traduit un|',
  'sentiment d''isolement ou la crainte de ne pas àtre acceptÇ.|Une faim douloureuse et sans issue traduit une frustration, un|sentiment de privation ou un besoin d''attention.|',
  'Des lÇgumes flÇtris ou imposÇs traduisent une lassitude, une|routine pesante ou des obligations peu gratifiantes.|Un goñt trop salÇ ou du sel renversÇ traduit une amertume, une|',
  'rancoeur ou une parole blessante Ö apaiser.|Un cafÇ amer ou renversÇ suggäre une nervositÇ, une fatigue|accumulÇe ou une discussion qui tourne mal.|',
  'Se gaver de sucreries suggäre une compensation affective, un|manque de rÇconfort ou une tentation trop facile.|En manger ou en àtre dÇgoñtÇ traduit une situation malsaine que|',
  'vous subissez, ou un malaise qu''il faut Çcouter.|Une soif impossible Ö Çtancher traduit une frustration, une|attente dÇáue ou un vide que vous cherchez Ö remplir.|',
  'Perdre ou se faire voler de l''argent rÇväle la crainte d''àtre|dÇvalorisÇ ou de dÇpenser votre Çnergie sans retour.|Des piäces qui glissent entre les doigts suggärent des soucis|',
  'matÇriels mineurs ou le sentiment de gaspiller vos efforts.|Un trÇsor perdu ou inaccessible traduit le sentiment de passer Ö|cìtÇ de votre potentiel ; la quàte mÇrite d''àtre poursuivie.|',
  'Un or terni, faux ou convoitÇ avec aviditÇ met en garde contre les|apparences trompeuses et l''attachement excessif aux biens.|Une banque fermÇe ou hostile traduit une insÇcuritÇ, la peur de|',
  'manquer ou le sentiment que l''on vous refuse ce qui vous revient.|Une faillite vÇcue dans la honte rÇväle un manque de confiance en|vous ou une situation que vous sentez Çchapper Ö votre contrìle.|',
  'Un travail interminable ou absurde signale une surcharge, une|perte de sens ou le besoin de mieux protÇger votre vie privÇe.|Un bureau envahi de dossiers ou un lieu de travail hostile traduit|',
  'une pression excessive ou un manque de reconnaissance.|Un patron menaáant refläte la peur d''àtre jugÇ ou contrìlÇ, ou un|conflit avec l''autoritÇ qu''il serait bon d''apaiser.|',
  'Un conflit avec un collägue rÇväle une rivalitÇ, un malentendu ou|un aspect de vous-màme que vous projetez sur l''autre.|Une rÇunion oó l''on vous ignore ou vous accuse traduit la crainte|',
  'de ne pas àtre entendu ou d''àtre mis en cause.|Un renvoi humiliant traduit un manque de confiance en votre valeur|ou une tension professionnelle qui mÇrite d''àtre exprimÇe.|',
  'Perdre ses moyens face au recruteur traduit la peur d''àtre jugÇ|ou un doute sur votre lÇgitimitÇ Ö prÇtendre Ö mieux.|Un contrat flou ou piÇgÇ met en garde contre un engagement pris|',
  'trop vite ou des conditions qu''il faudrait relire de präs.|Des achats compulsifs ou impossibles rÇvälent un vide que l''on|cherche Ö combler ou la peur de ne pas s''offrir le nÇcessaire.|',
  'Vendre Ö perte ou cÇder un bien prÇcieux Çvoque la sensation de|brader vos qualitÇs ou de renoncer trop vite Ö vos dÇsirs.|Des crÇanciers pressants figurent une culpabilitÇ ou des|',
  'engagements trop lourds ; clarifier ce que vous devez vraiment|vous allÇgera.|Une richesse ostentatoire ou isolante met en garde contre la quàte|de l''avoir au dÇtriment de l''àtre et des liens.|',
  'Une misäre angoissante traduit la peur de manquer ou de ne pas|valoir assez ; elle invite Ö reconnaåtre vos vraies richesses.|Des vàtements mal ajustÇs traduisent un rìle social qui ne vous|',
  'convient plus ou une gàne face aux autres.|Des chaussures perdues ou abåmÇes reflätent une hÇsitation sur|votre route ou un manque de stabilitÇ.|',
  'Une robe dÇchirÇe ou trop Çtroite traduit une gàne vis-Ö-vis de|votre corps ou d''un rìle imposÇ.|Une robe de mariÇe tachÇe ou introuvable traduit des doutes sur un|engagement ou la peur de dÇcevoir.|',
  'Un chapeau emportÇ par le vent Çvoque la crainte de perdre votre|statut ou de rÇvÇler vos pensÇes.|Un manteau trop lourd ou volÇ refläte un besoin de vous cacher ou|une protection qui vous Çtouffe.|',
  'Un uniforme imposÇ traduit le sentiment d''àtre rÇduit Ö une|fonction ou d''Çtouffer sous les rägles.|Un dÇguisement que vous ne pouvez retirer traduit la peur d''àtre|',
  'dÇmasquÇ ou de vous perdre dans un rìle.|Apparaåtre en sous-vàtements devant autrui traduit une crainte du|ridicule ou d''un secret dÇvoilÇ.|',
  'Un maquillage qui coule rÇväle la crainte que votre vraie nature|soit dÇcouverte ou un masque trop lourd.|Des lunettes brisÇes ou perdues traduisent une confusion ou un|',
  'refus de voir une vÇritÇ dÇrangeante.|Porter des haillons traduit un sentiment de honte, de dÇclassement|ou une estime de soi fragile.|',
  'Un couple en tension refläte des besoins non exprimÇs ou une peur|de l''abandon ; le ràve suggäre d''ouvrir le dialogue.|Un baiser forcÇ ou glacÇ traduit une intimitÇ mal vÇcue, une|',
  'mÇfiance ou un lien affectif devenu ambigu.|Un amant qu''il faut cacher Çvoque une culpabilitÇ, une double vie|intÇrieure ou un besoin que vous n''osez pas avouer.|',
  'Un mariage ratÇ ou forcÇ traduit une crainte de l''engagement ou|le sentiment d''àtre liÇ Ö une dÇcision imposÇe.|Une rupture douloureuse traduit une insÇcuritÇ affective ou la|',
  'crainte de perdre l''autre ; elle n''annonce rien de fatal.|DÇcouvrir une trahison amoureuse traduit la peur d''àtre remplacÇ|ou de ne plus compter ; parlez de vos besoins.|',
  'Un ex qui vous hante signale un regret, une blessure mal refermÇe|ou un schÇma relationnel qui se rÇpäte.|Une sexualitÇ gànante ou imposÇe signale un malaise, des limites Ö|',
  'poser ou un dÇsir que vous jugez trop sÇvärement.|Une Çtreinte qui Çtouffe ou que l''on vous refuse traduit un|manque affectif ou une relation devenue trop possessive.|',
  'Un rendez-vous manquÇ ou un lapin traduit la peur d''àtre dÇáu, de|ne pas plaire ou de laisser passer votre chance.|Des fianáailles rompues ou angoissantes traduisent une hÇsitation|',
  'devant un choix ou la peur de vous engager trop vite.|Un divorce conflictuel traduit une inquiÇtude pour votre stabilitÇ|affective ou un tiraillement entre deux loyautÇs.|',
  'Une sÇduction manipulatrice signale la crainte d''àtre utilisÇ ou|l''envie de plaire au prix de votre sincÇritÇ.|Un coup de foudre suivi de dÇception invite Ö distinguer l''idÇal|',
  'projetÇ de la rÇalitÇ, sans renoncer Ö l''Çlan.|Un blanc froid et vide Çvoque une absence d''Çmotion, un|dÇtachement excessif ou un perfectionnisme qui vous isole.|',
  'Un noir oppressant refläte une humeur sombre, un deuil Ö traverser|ou des craintes enfouies Ö apprivoiser.|Un rouge agressif ou envahissant met en garde contre|',
  'l''impulsivitÇ, une coläre latente ou un Çpuisement.|Un bleu froid et triste refläte une distance affective, une|nostalgie ou le besoin d''àtre consolÇ.|',
  'Un vert maladif ou glauque traduit une envie mal vÇcue, un malaise|physique ou un projet encore trop vert.|Un jaune blafard Çvoque la mÇfiance, une jalousie ou une nervositÇ|',
  'qu''il serait bon de comprendre.|Un orange criard suggäre une agitation, un besoin excessif|d''attention ou une dispersion de votre Çnergie.|',
  'Un violet sombre Çvoque une tristesse discräte, un repli sur soi|ou une sensibilitÇ que vous protÇgez trop.|Un monde tout en gris refläte un dÇcouragement, une monotonie ou|',
  'une difficultÇ Ö trancher qui vous päse.|Un dorÇ clinquant ou factice met en garde contre les apparences|trompeuses ou une ambition purement matÇrielle.|',
  'Il peut traduire un sentiment de solitude ou un individualisme qui|vous coupe peu Ö peu des autres.|Il peut reflÇter une hÇsitation, un conflit intÇrieur ou une|',
  'rivalitÇ qui s''installe dans une relation.|Il peut signaler un triangle relationnel dÇlicat ou la sensation|d''àtre de trop dans une situation.|',
  'Il peut traduire une rigiditÇ, un cadre trop Çtroit ou la|sensation d''àtre enfermÇ dans la routine.|Il peut signaler une agitation, une instabilitÇ ou des choix|',
  'prÇcipitÇs sous l''effet de l''impatience.|Il peut traduire un dilemme sentimental ou le poids de|responsabilitÇs que vous portez pour autrui.|',
  'Il peut reflÇter un besoin de solitude excessif ou une recherche|de perfection qui vous Çpuise.|Il peut signaler une ambition excessive, une lutte de pouvoir ou|un souci matÇriel Ö rÇgler.|',
  'Il peut traduire la difficultÇ Ö clore un chapitre ou une|lassitude avant le nouveau dÇpart.|Il peut traduire une exigence de perfection ou la crainte de ne|pas àtre Ö la hauteur des attentes.|',
  'Il peut signaler la pression du temps, une ÇchÇance qui approche|ou un cadre trop strict.|Il traduit une superstition ou la crainte d''un imprÇvu, souvent|bien plus grande que le risque rÇel.|',
  'Vous vous Çpuisez dans une lutte constante ; cherchez un terrain|d''entente plutìt qu''une victoire.|Vous risquez de cÇder Ö un emportement ; exprimez plus tìt ce qui|vous päse pour Çviter le choc.|',
  'Se voir visÇ par une arme rÇväle un sentiment de vulnÇrabilitÇ ou|des paroles blessantes reáues.|Vous vous sentez sans dÇfense face Ö une situation ou Ö une|',
  'personne ; il est temps de poser vos limites.|Assister Ö un meurtre ou en àtre victime rÇväle une culpabilitÇ ou|une partie de vous que l''on Çtouffe.|',
  'Une bagarre confuse traduit une tension latente et des rancoeurs|qu''il vaudrait mieux exprimer calmement.|Une maison en flammes signale un foyer sous tension ou un|surmenage qui consume vos forces.|',
  'Vous allez trop vite ou suivez une voie qui n''est pas la vìtre ;|prudence et rÇflexion s''imposent.|Vous vous sentez dÇpassÇ par une accumulation de soucis ; prenez|les problämes un Ö un.|',
  'Vous subissez une emprise affective ou professionnelle ;|identifiez ce qui vous retient contre votre grÇ.|Une menace persistante traduit un stress chronique ; il serait bon|',
  'd''en identifier la source prÇcise.|Vous vous sentez envahi ou dÇpossÇdÇ ; il est temps de mieux|protÇger votre vie privÇe.|Se sentir empoisonnÇ rÇväle une mÇfiance envers votre entourage ou|',
  'une amertume que vous ruminez.|Vous craignez que votre Çquilibre ne cäde ; un appui extÇrieur ou|du repos vous seraient prÇcieux.|Une alarme qui ne s''arràte pas traduit un Çtat d''alerte|',
  'permanent et un besoin urgent de dÇtente.|Vous vivez dans l''attente d''un coup imprÇvisible ; une source de|stress diffuse mÇrite d''àtre apaisÇe.|',
  'Vous vous laissez manipuler ou culpabiliser ; reprenez votre droit|de dire non Ö ce qui vous enchaåne.|Un danger permanent signale une insÇcuritÇ intÇrieure ; Çvitez les|',
  'situations oó vous vous mettez en pÇril.|Un monstre qui vous poursuit indique un probläme ÇvitÇ qui grossit|Ö mesure qu''on refuse de le regarder.|',
  'Un dragon qui crache le feu Çvoque une coläre dÇvorante ou une|Çpreuve qui vous paraåt insurmontable.|Une fÇe malveillante refläte des attentes dÇáues ou l''illusion|',
  'd''une solution magique Ö vos problämes.|Une licorne qui s''enfuit invite Ö ne pas sacrifier le rÇel Ö un|idÇal trop parfait pour exister.|Un enlävement par des extraterrestres exprime un sentiment|',
  'd''impuissance ou d''àtre incompris par les autres.|Une sorciäre menaáante Çvoque une emprise fÇminine, une|manipulation ou une jalousie dans votre entourage.|',
  'La morsure d''un vampire rÇväle une relation qui vous Çpuise ou un|dÇsir dont vous craignez l''emprise.|Une horde de zombies traduit le sentiment d''àtre englouti par la|',
  'foule ou de perdre votre singularitÇ.|Un loup-garou menaáant rÇväle la peur d''un proche au double|visage ou de vos propres dÇbordements.|',
  'Un gÇant Çcrasant refläte un sentiment d''infÇrioritÇ face Ö une|autoritÇ ou Ö une tÉche immense.|Des lutins qui säment le dÇsordre traduisent de petits tracas ou|une nÇgligence de votre part.|',
  'Devenir un robot ou àtre poursuivi par l''un d''eux refläte une|vie trop programmÇe et des Çmotions muselÇes.|Des pouvoirs qui vous Çchappent traduisent la peur de ne pas àtre|',
  'Ö la hauteur de ce qu''on attend de vous.|Ne pas àtre vu malgrÇ vos efforts rÇväle un manque de|reconnaissance ou un sentiment de solitude.|Rester coincÇ dans une autre Çpoque refläte une difficultÇ Ö|',
  'tourner la page ou Ö vivre le prÇsent.|Le chant d''une siräne qui vous entraåne au fond signale une|passion trompeuse ou une tentation Ö Çviter.|',
  'Un phÇnix qui peine Ö renaåtre vous invite Ö accepter la fin d''un|cycle avant de pouvoir repartir.|Une magie qui Çchoue ou se retourne contre vous met en garde|contre les illusions et les raccourcis.|',
  'Une crÇature effrayante traduit une inquiÇtude mal dÇfinie qui|gagnerait Ö àtre nommÇe pour s''apaiser.|Une apocalypse terrifiante refläte un stress intense ou la crainte|de perdre tous vos repäres.|',
  'Un dinosaure qui vous poursuit signale un probläme ancien qui|refait surface ou une rÇsistance au changement.|Ce ràve est chargÇ de tensions : les images pÇnibles y dominent|',
  'nettement. Loin d''àtre un mauvais prÇsage, il agit comme une|soupape qui permet Ö votre psychisme d''Çvacuer des peurs ou des|contrariÇtÇs accumulÇes.|',
  'Le climat de ce ràve est plutìt sombre. Il met en scäne des|inquiÇtudes ou des conflits que vous ne regardez peut-àtre pas|encore en face pendant la journÇe.|',
  'Ce ràve màle des images agrÇables et des images inquiÇtantes.|Cette ambivalence montre que vous traversez une situation oó|espoirs et craintes cohabitent.|',
  'L''atmosphäre de ce ràve est plutìt favorable. Il refläte une|dynamique intÇrieure constructive et des ressources sur lesquelles|vous pouvez vous appuyer.|',
  'Ce ràve est lumineux et porteur : les images heureuses y dominent.|Il traduit un bel Çquilibre intÇrieur, un dÇsir comblÇ ou|l''annonce d''un Çlan nouveau.|',
  'La joie qui s''en dÇgage exprime la satisfaction d''un besoin|profond et une confiance retrouvÇe en la vie.|La tendresse qui le colore rÇväle un grand besoin d''attachement,|',
  'de chaleur humaine et de reconnaissance affective.|Le calme qui l''habite tÇmoigne d''une rÇconciliation intÇrieure :|une tension s''apaise et un Çquilibre se reconstruit.|',
  'L''Çmerveillement qu''il suscite signale une ouverture : votre|curiositÇ et votre crÇativitÇ cherchent un nouveau terrain|d''expression.|La peur qui le traverse n''annonce pas un danger rÇel : elle met|',
  'en lumiäre une menace intÇrieure, une situation que vous redoutez|ou une part de vous que vous fuyez.|L''anxiÇtÇ qui l''imprägne traduit une pression vÇcue Ö l''Çtat de|',
  'veille : responsabilitÇs, attentes, peur de mal faire ou de ne pas|àtre Ö la hauteur.|La coläre qui s''y exprime rÇväle une frustration ou une injustice|',
  'ressentie, peut-àtre retenue dans la vie ÇveillÇe, qui demande Ö|àtre reconnue.|La tristesse qui le baigne Çvoque un deuil, une sÇparation ou un|',
  'manque ; le ràve vous aide Ö digÇrer cette perte et Ö vous en|dÇtacher peu Ö peu.|Le malaise, la honte ou le dÇgoñt qui s''y glissent signalent une|',
  'crainte du jugement d''autrui ou un aspect de vous-màme que vous|avez du mal Ö accepter.|L''eau et la nature renvoient au monde des Çmotions et Ö|',
  'l''inconscient : leur Çtat (calme, agitÇ, fertile, aride) refläte|fidälement votre climat intÇrieur du moment.|Les animaux incarnent vos instincts et vos Çnergies vitales. Leur|',
  'attitude, docile ou menaáante, indique la faáon dont vous composez|avec vos pulsions et votre nature profonde.|Le corps est au premier plan : le ràve parle de votre vitalitÇ, de|',
  'votre image de vous-màme et de votre capacitÇ Ö agir, parfois|aussi de signaux de fatigue Ö Çcouter.|Les personnages du ràve sont souvent des facettes de vous-màme ou|',
  'le reflet de vos relations. Ce qu''ils font et disent rÇväle ce|que vous attendez des autres ou ce que vous projetez sur eux.|La maison et les lieux reprÇsentent votre espace psychique :|',
  'chaque piäce ou chaque endroit correspond Ö une rÇgion de votre|personnalitÇ, plus ou moins explorÇe, plus ou moins habitÇe.|Les objets ont une valeur de clÇ : ils condensent un souvenir, un|',
  'outil ou une ressource. Ce qui est trouvÇ, perdu, brisÇ ou offert|renseigne sur ce que vous gagnez ou craignez de perdre.|Le voyage et les transports dÇcrivent votre trajectoire de vie :|',
  'la maniäre dont vous avancez, le contrìle que vous exercez sur|votre direction et les obstacles qui ralentissent votre route.|Les actions du ràve mettent en scäne votre maniäre de rÇagir aux|',
  'situations : fuir, affronter, chercher, s''Çlever ou chuter sont|autant de stratÇgies que vous employez aussi ÇveillÇ.|Les ÇlÇments et le cosmos donnent au ràve une dimension vaste : il|',
  'touche aux grands cycles, Ö votre Çnergie fondamentale et Ö votre|place dans un ensemble qui vous dÇpasse.|Le sacrÇ et le mystäre dominent : le ràve exprime une quàte de|',
  'sens, un besoin de guidance ou la rencontre avec une dimension de|vous-màme plus vaste que le moi conscient.|La mort et la renaissance sont au coeur du ràve : il ne s''agit|',
  'presque jamais d''une fin rÇelle, mais de la clìture d''un cycle|et de la naissance d''un Çtat nouveau.|La nourriture parle de ce qui vous nourrit, au propre comme au|',
  'figurÇ : affection, connaissances, plaisirs. Le ràve interroge vos|appÇtits et ce dont vous manquez.|L''argent et le travail renvoient Ö votre valeur personnelle, Ö|',
  'votre sÇcuritÇ et Ö la reconnaissance que vous recevez. Le ràve|Çvalue l''Çnergie que vous investissez et ce qu''elle vous|rapporte.|Les vàtements et l''apparence Çvoquent le rìle social que vous|',
  'jouez et l''image que vous donnez aux autres ; le ràve compare ce|masque Ö ce que vous àtes vraiment.|L''amour et la sexualitÇ occupent la scäne : le ràve exprime vos|',
  'dÇsirs, vos attentes affectives et la qualitÇ du lien que vous|entretenez avec vous-màme et avec l''autre.|Les couleurs et les nombres donnent au ràve une tonalitÇ|',
  'symbolique prÇcise : ils soulignent une Çmotion dominante ou un|rythme, une Çtape Ö franchir, un cycle Ö complÇter.|La violence et le danger traduisent un conflit intÇrieur intense :|',
  'une part de vous se sent menacÇe ou agressÇe, ou une Çnergie|refoulÇe cherche brutalement Ö s''exprimer.|Le fantastique ouvre les portes de l''imaginaire : le ràve libäre|',
  'votre crÇativitÇ et met en scäne, sous des formes extraordinaires,|des forces psychiques puissantes.|Accordez-vous des moments de calme et laissez vos Çmotions|s''exprimer sans les juger.|',
  'êcoutez vos instincts : ils ont souvent raison, Ö condition de ne|pas les laisser dÇcider seuls.|Prenez soin de votre corps et de votre rythme ; le repos fait|partie de l''action.|',
  'Interrogez la qualitÇ de vos liens : qui vous soutient, qui vous|päse, Ö qui avez-vous quelque chose Ö dire ?|Faites un peu de rangement intÇrieur : un espace dÇlaissÇ de votre|',
  'vie mÇrite d''àtre rÇinvesti.|RepÇrez la ressource que vous possÇdez dÇjÖ : la clÇ de la|situation est peut-àtre entre vos mains.|Reprenez le volant de votre existence : choisissez la direction|',
  'plutìt que de la subir.|Observez vos rÇactions face aux difficultÇs et essayez une autre|stratÇgie que l''habituelle.|Reliez-vous aux rythmes naturels : lumiäre, saisons, cycles ; ils|',
  'vous ressourcent.|MÇnagez-vous un temps de silence, de mÇditation ou de rÇflexion|sur ce qui donne du sens Ö votre vie.|Acceptez de laisser partir ce qui est terminÇ : c''est la|',
  'condition d''un vÇritable renouveau.|Demandez-vous de quoi vous avez rÇellement faim en ce moment, et|nourrissez ce besoin.|êvaluez ce que vous donnez et ce que vous recevez ; votre valeur|',
  'ne se mesure pas qu''Ö vos rÇsultats.|Osez vous montrer tel que vous àtes : l''authenticitÇ rassure plus|qu''une image parfaite.|Exprimez vos dÇsirs et vos attentes affectives avec simplicitÇ ;|',
  'le dialogue dÇnoue bien des tensions.|Notez ce chiffre ou cette couleur et observez s''ils reviennent :|ils balisent une Çtape.|Identifiez la coläre ou la peur que vous retenez et trouvez-lui|',
  'une issue paisible.|Donnez une forme Ö votre crÇativitÇ : Çcriture, dessin, projet ;|l''imaginaire demande Ö vivre.|Ce ràve concerne avant tout votre vie affective et amoureuse :|',
  'besoin d''aimer et d''àtre aimÇ, attentes et blessures du coeur.|Ce ràve touche surtout Ö la famille et au foyer : vos racines, vos|liens familiaux et votre besoin de sÇcuritÇ.|',
  'Ce ràve se rapporte principalement Ö votre vie professionnelle et|matÇrielle : ambitions, sÇcuritÇ, reconnaissance et efforts.|Ce ràve parle d''abord de votre corps et de votre santÇ :|',
  'vitalitÇ, fatigue, rapport Ö votre image physique.|Ce ràve porte sur votre vie sociale et l''image que vous donnez :|regard des autres, place dans le groupe, rÇputation.|',
  'Ce ràve explore votre vie intÇrieure : Çmotions profondes, dÇsirs|cachÇs et mouvements de l''inconscient.|Ce ràve s''inscrit dans une dÇmarche spirituelle et d''Çvolution|',
  'personnelle : quàte de sens, croissance, sagesse.|Ce ràve annonce ou accompagne un changement : transition, choix Ö|faire, nouvelle Çtape qui se prÇpare.|',
  'Le cauchemar est un ràve Ö forte charge de peur, souvent suivi|d''un rÇveil brutal. Il dramatise une menace pour mieux attirer|l''attention sur un stress, un traumatisme ou une Çmotion|',
  'refoulÇe. Les cauchemars rÇpÇtÇs invitent Ö identifier la source|de l''angoisse et, au besoin, Ö en parler.|Le ràve d''angoisse met en scäne des situations d''Çchec ou|',
  'd''impuissance : retard, examen, perte, chute, nuditÇ en public.|Il refläte la pression ressentie dans la vie ÇveillÇe et la peur|de ne pas àtre Ö la hauteur des attentes, les vìtres ou celles des|',
  'autres.|Le ràve de dÇsir rÇalise symboliquement un souhait, comme l''a|montrÇ Freud : plaisir, rÇussite, abondance, retrouvailles. Il|rÇväle ce qui vous manque ou ce Ö quoi vous aspirez, et vous|',
  'redonne l''Çlan nÇcessaire pour le poursuivre.|Le ràve affectif est centrÇ sur les liens : amour, amitiÇ,|famille. Il exprime vos attentes relationnelles, vos attachements|',
  'et parfois des tensions non dites avec vos proches.|Le ràve d''aventure est un rÇcit de mouvement : voyages,|explorations, routes et dÇcouvertes. Il traduit votre dÇsir|',
  'd''Çlargir vos horizons et la faáon dont vous abordez les Çtapes|de votre vie.|Le ràve fantastique s''affranchit des lois du rÇel : crÇatures,|',
  'pouvoirs magiques, mÇtamorphoses. Il tÇmoigne d''une imagination|vive et met en scäne des forces psychiques puissantes sous une|forme mythique.|',
  'Le ràve spirituel ou mystique laisse une impression de profondeur|et de sacrÇ : lumiäre, guide, message, sentiment d''unitÇ. Jung|parlait de Æ grands ràves Ø : ils accompagnent les tournants|',
  'intÇrieurs et la quàte de sens.|Le ràve de transformation marque un passage : mort et renaissance,|traversÇe, porte, mue. Il accompagne une Çvolution intÇrieure, la|',
  'fin d''un cycle et l''Çmergence d''une nouvelle maniäre d''àtre.|Le ràve de mÇmoire retraite les ÇvÇnements rÇcents : travail,|conversations, lieux familiers, soucis de la veille. Il participe|',
  'au tri et Ö la consolidation des souvenirs et rÇväle ce qui vous a|marquÇ rÇcemment.|Le ràve prÇmonitoire donne l''impression d''annoncer l''avenir. Le|',
  'plus souvent, il traduit une intuition : l''inconscient a peráu|des signes que la conscience n''a pas encore relevÇs. Notez-le et|datez-le pour le comparer aux ÇvÇnements.|',
  'Le ràve lucide est celui oó l''on sait que l''on ràve, et oó l''on|peut parfois orienter le scÇnario. Il tÇmoigne d''une bonne|conscience de soi et peut àtre cultivÇ pour apprivoiser ses peurs|',
  'ou stimuler sa crÇativitÇ.|Le ràve rÇcurrent revient sous une forme proche, parfois depuis|des annÇes. Il signale un conflit ou un besoin non rÇsolu : il|',
  'cesse gÇnÇralement lorsque la situation qu''il symbolise est|comprise et dÇnouÇe.|il dramatise une menace pour vous obliger Ö regarder en face une|peur ou un stress que vous portez.|',
  'il exprime une pression et la crainte de ne pas àtre Ö la hauteur|de ce que l''on attend de vous.|il rÇalise un souhait et vous rappelle ce Ö quoi vous aspirez|profondÇment.|',
  'il parle de vos liens et de ce que vous attendez de ceux que vous|aimez.|il dÇcrit votre maniäre d''avancer dans la vie et votre envie de|nouveaux horizons.|',
  'il libäre votre imaginaire et donne forme Ö des forces intÇrieures|puissantes.|il vous invite Ö une quàte de sens et Ö l''Çcoute de votre sagesse|intÇrieure.|',
  'il accompagne une mutation intÇrieure : un cycle s''achäve, un|autre commence.|il digäre les ÇvÇnements rÇcents et rÇväle ce qui vous a le plus|marquÇ.|',
  'il traduit une intuition que votre conscience n''a pas encore|formulÇe.|il montre que vous pouvez reprendre la main sur vos scÇnarios|intÇrieurs.|',
  'il insiste sur une question non rÇsolue qui attend votre|attention.|L''Ombre rassemble les aspects de la personnalitÇ que l''on refuse|de voir : dÇfauts, pulsions, coläres, mais aussi talents|',
  'inexploitÇs. Elle apparaåt sous les traits d''inconnus menaáants,|de poursuivants ou de crÇatures sombres. L''intÇgrer, c''est|gagner en force et en luciditÇ.|',
  'L''Anima (chez l''homme) ou l''Animus (chez la femme) personnifie|la part de l''autre sexe en soi. Figure sÇduisante ou guide, elle|relie le conscient Ö l''inconscient et oriente la vie affective et|',
  'crÇatrice.|La Persona est le masque social : le rìle que l''on joue pour àtre|acceptÇ. Vàtements, uniformes, scänes et regards d''autrui la|',
  'mettent en jeu ; le ràve signale un dÇcalage entre ce masque et|votre identitÇ profonde.|Le Soi est le centre et la totalitÇ de la psychÇ. Il se manifeste|',
  'par des images d''unitÇ et de plÇnitude : cercle, mandala,|lumiäre, trÇsor, enfant divin. Sa prÇsence accompagne les grandes|Çtapes d''individuation.|',
  'La Grande Märe incarne la nature nourriciäre et protectrice, mais|aussi Çtouffante. Mer, terre, grotte, märe ou figure maternelle|l''Çvoquent : elle interroge votre besoin de protection et votre|',
  'autonomie.|Le Päre reprÇsente l''autoritÇ, la loi, la structure et la|protection. Roi, patron, policier ou päre rÇel le figurent : le|ràve parle de votre rapport aux rägles, Ö la rÇussite et Ö votre|',
  'propre autoritÇ.|Le Vieux Sage est le guide intÇrieur : vieillard, maåtre, pràtre|ou voyant. Il apparaåt quand vous avez besoin de conseil et|',
  'rappelle que vous possÇdez en vous une sagesse plus grande que|vous ne le pensez.|L''Enfant divin symbolise le renouveau, la spontanÇitÇ et les|',
  'possibles. BÇbÇ, naissance ou enfant lumineux annoncent un|potentiel neuf, un projet ou une part de vous qui demande Ö|grandir.|Le HÇros est la force qui affronte l''Çpreuve : combat, quàte,|',
  'sauvetage. Il exprime votre courage et votre capacitÇ Ö surmonter|les obstacles pour conquÇrir votre autonomie.|Le Fripon, ou trickster, est le farceur qui bouscule l''ordre|',
  'Çtabli : clown, lutin, animal rusÇ. Il dÇsamorce la rigiditÇ,|rÇväle les contradictions et invite Ö plus de souplesse et|d''humour.|Le ràve Çvolue de l''inquiÇtude vers l''apaisement : son|',
  'dÇnouement favorable suggäre que vous possÇdez les ressources pour|sortir de la difficultÇ.|Le ràve commence sous de bons auspices puis se tend : il met en|',
  'garde contre une inquiÇtude qui grandit et mÇrite d''àtre prise en|compte avant qu''elle ne s''installe.|La tonalitÇ reste agrÇable du dÇbut Ö la fin : le ràve confirme un|',
  'Çtat intÇrieur stable et confiant.|La tension demeure tout au long du rÇcit, sans vÇritable issue :|le ràve insiste sur une prÇoccupation encore non rÇsolue.|',
  'Les Çmotions alternent au fil du rÇcit : vous oscillez entre des|forces contraires et cherchez encore votre Çquilibre.|Votre humeur au rÇveil rejoint la tonalitÇ du ràve : l''Çmotion|',
  'nocturne se prolonge dans la journÇe et mÇrite d''àtre accueillie.|MalgrÇ un ràve plutìt agrÇable, votre rÇveil a ÇtÇ maussade : le|ràve compense peut-àtre un manque que la rÇalitÇ rend plus|sensible.|',
  'MalgrÇ les images pÇnibles du ràve, votre rÇveil a ÇtÇ serein : le|ràve a jouÇ son rìle de soupape et a libÇrÇ une tension.|Ces pistes ne sont que des clÇs de lecture : seul le ràveur|',
  'connaåt le contexte de sa vie. Confrontez-les Ö ce que vous vivez|en ce moment et retenez ce qui rÇsonne pour vous.|Aucun symbole connu n''a ÇtÇ reconnu dans ce rÇcit. DÇcrivez|',
  'davantage les lieux, les personnages, les objets et les actions du|ràve, ainsi que ce que vous avez ressenti, puis relancez|l''analyse.|',
  'êcrire le ràve. Le menu Fichier > Nouveau ràve (F2) ouvre la fiche|du ràve : titre, date, ràveur, humeur au rÇveil, langue du rÇcit|et indicateurs Æ rÇcurrent Ø et Æ lucide Ø. Le rÇcit s''Çcrit|',
  'ensuite dans l''Çditeur (F5).|L''Çditeur : fläches, DÇbut, Fin, PgPrÇc, PgSuiv, Ctrl+DÇbut et|Ctrl+Fin pour se dÇplacer, EntrÇe pour un nouveau paragraphe,|',
  'Retour arriäre et Suppr pour effacer, Ctrl+Y pour supprimer une|ligne. Le texte revient Ö la ligne tout seul ; un clic place le|curseur. Tab (ou `) ajoute ou change l''accent de la lettre qui|',
  'prÇcäde le curseur : e, Ç, ä, à, â.|Pendant la frappe, les symboles reconnus sont surlignÇs en jaune,|les Çmotions positives en vert et les nÇgatives en rouge (menu|Ràve > Surligner les symboles).|',
  'L''analyse. Le menu Analyse prÇsente le rapport complet (F6), les|symboles reconnus, la tonalitÇ avec les Çmotions et leur Çvolution|au fil du rÇcit (F7), les thämes et domaines de vie en graphiques|',
  'Ö secteurs (F8), la classification du ràve, les archÇtypes et le|sens du ràve (F9).|Le journal. Fichier > Enregistrer au journal (F4) conserve le ràve|',
  'dans le fichier REVES.JNL ; la liste (F3) permet de le rouvrir ou|de le supprimer, et les statistiques montrent l''Çvolution de vos|ràves, leurs types et vos symboles favoris.|',
  'Le dictionnaire permet de parcourir tous les symboles par|catÇgorie ou d''en rechercher un par un mot. Fichier > Exporter le|rapport enregistre l''analyse compläte dans un fichier texte|',
  '(REVES.TXT par dÇfaut).|Menus : F10 ou Alt+lettre soulignÇe, puis fläches, EntrÇe et|êchap. Alt+X quitte le programme. L''interface suit la variable|',
  'LANGUAGE (EN, GR, SP, IT) ; les interprÇtations sont rÇdigÇes en|franáais.|Writing the dream. File > New dream (F2) opens the dream form:|',
  'title, date, dreamer, mood on waking, language and the "recurring"|and "lucid" flags. The account is then written in the editor (F5).|The editor: arrows, Home, End, PgUp, PgDn, Ctrl+Home and Ctrl+End|',
  'to move, Enter for a new paragraph, Backspace and Del to erase,|Ctrl+Y to delete a line. Text wraps automatically; a click places|the cursor. Tab (or `) adds or changes the accent of the letter|',
  'before the cursor: e, Ç, ä, à, â.|While you type, recognised symbols are highlighted in yellow,|positive emotions in green and negative ones in red (Dream >|Highlight symbols).|',
  'The analysis. The Analysis menu shows the full report (F6), the|recognised symbols, the tone with emotions and their development|(F7), themes and life areas as pie charts (F8), the|',
  'classification, the archetypes and the meaning of the dream (F9).|The journal. File > Save to journal (F4) keeps the dream in the|file REVES.JNL; the list (F3) reopens or deletes it, and the|',
  'statistics show the development of your dreams, their types and|your favourite symbols.|The dictionary lets you browse all symbols by category or search|',
  'for one by a word. File > Export the report saves the complete|analysis in a text file (REVES.TXT by default).|Menus: F10 or Alt+underlined letter, then arrows, Enter and Esc.|',
  'Alt+X quits. The interface follows the LANGUAGE variable (EN, GR,|SP, IT); interpretations are written in French.|Den Traum schreiben. Datei > Neuer Traum (F2) îffnet das|',
  'Traumblatt: Titel, Datum, TrÑumer, Stimmung beim Erwachen, Sprache|und die Merkmale "wiederkehrend" und "Klartraum". Der Bericht wird|dann im Editor geschrieben (F5).|',
  'Der Editor: Pfeile, Pos1, Ende, Bild auf/ab, Strg+Pos1 und|Strg+Ende zum Bewegen, Eingabe fÅr einen neuen Absatz, RÅcktaste|und Entf zum Lîschen, Strg+Y lîscht eine Zeile. Der Text bricht|',
  'automatisch um; ein Klick setzt den Cursor. Tab (oder `) setzt|oder Ñndert den Akzent des Buchstabens vor dem Cursor: u, ó, ñ, Å.|Beim Tippen werden erkannte Symbole gelb, positive GefÅhle grÅn|',
  'und negative rot hervorgehoben (Traum > Symbole hervorheben).|Die Analyse. Das MenÅ Analyse zeigt den vollstÑndigen Bericht|(F6), die erkannten Symbole, die Stimmung mit den GefÅhlen und|',
  'ihrem Verlauf (F7), Themen und Lebensbereiche als Kreisdiagramme|(F8), die Klassifikation, die Archetypen und die Bedeutung des|Traums (F9).|',
  'Das Tagebuch. Datei > Im Tagebuch speichern (F4) bewahrt den Traum|in der Datei REVES.JNL auf; die Liste (F3) îffnet oder lîscht ihn,|und die Statistik zeigt den Verlauf Ihrer TrÑume, ihre Typen und|',
  'Ihre hÑufigsten Symbole.|Im Wîrterbuch lassen sich alle Symbole nach Kategorie durchsehen|oder Åber ein Wort suchen. Datei > Bericht exportieren speichert|',
  'die vollstÑndige Analyse in einer Textdatei (standardmÑ·ig|REVES.TXT).|MenÅs: F10 oder Alt+unterstrichener Buchstabe, dann Pfeile,|Eingabe und Esc. Alt+X beendet. Die OberflÑche folgt der Variablen|',
  'LANGUAGE (EN, GR, SP, IT); die Deutungen sind auf Franzîsisch.|Escribir el sue§o. Archivo > Nuevo sue§o (F2) abre la ficha del|sue§o: t°tulo, fecha, so§ador, humor al despertar, idioma y los|',
  'indicadores "recurrente" y "l£cido". El relato se escribe luego en|el editor (F5).|El editor: flechas, Inicio, Fin, ReP†g, AvP†g, Ctrl+Inicio y|',
  'Ctrl+Fin para moverse, Intro para un nuevo p†rrafo, Retroceso y|Supr para borrar, Ctrl+Y para borrar una l°nea. El texto pasa solo|a la l°nea siguiente; un clic coloca el cursor. Tab (o `) a§ade o|',
  'cambia el acento de la letra anterior al cursor: a, Ö, É, Ñ, †.|Mientras escribe, los s°mbolos reconocidos se resaltan en|amarillo, las emociones positivas en verde y las negativas en rojo|',
  '(Sue§o > Resaltar los s°mbolos).|El an†lisis. El men£ An†lisis presenta el informe completo (F6),|los s°mbolos reconocidos, la tonalidad con las emociones y su|',
  'evoluci¢n (F7), los temas y †mbitos en gr†ficos de sectores (F8),|la clasificaci¢n, los arquetipos y el sentido del sue§o (F9).|El diario. Archivo > Guardar en el diario (F4) conserva el sue§o|',
  'en el archivo REVES.JNL; la lista (F3) permite reabrirlo o|eliminarlo, y las estad°sticas muestran la evoluci¢n de sus|sue§os, sus tipos y sus s°mbolos favoritos.|',
  'El diccionario permite recorrer todos los s°mbolos por categor°a o|buscar uno por una palabra. Archivo > Exportar el informe guarda|el an†lisis completo en un archivo de texto (REVES.TXT por|',
  'defecto).|Men£s: F10 o Alt+letra subrayada, luego flechas, Intro y Esc.|Alt+X sale del programa. La interfaz sigue la variable LANGUAGE|(EN, GR, SP, IT); las interpretaciones est†n en francÇs.|',
  'Scrivere il sogno. File > Nuovo sogno (F2) apre la scheda del|sogno: titolo, data, sognatore, umore al risveglio, lingua e gli|indicatori "ricorrente" e "lucido". Il racconto si scrive poi|',
  'nell''editor (F5).|L''editor: frecce, Inizio, Fine, PagSu, PagGió, Ctrl+Inizio e|Ctrl+Fine per spostarsi, Invio per un nuovo paragrafo, Backspace e|',
  'Canc per cancellare, Ctrl+Y per eliminare una riga. Il testo va a|capo da solo; un clic posiziona il cursore. Tab (o `) aggiunge o|cambia l''accento della lettera prima del cursore: e, Ç, ä, à, â.|',
  'Durante la digitazione i simboli riconosciuti sono evidenziati in|giallo, le emozioni positive in verde e quelle negative in rosso|(Sogno > Evidenzia i simboli).|',
  'L''analisi. Il menu Analisi presenta il rapporto completo (F6), i|simboli riconosciuti, il tono con le emozioni e la loro evoluzione|(F7), temi e ambiti in grafici a torta (F8), la classificazione,|',
  'gli archetipi e il senso del sogno (F9).|Il diario. File > Salva nel diario (F4) conserva il sogno nel file|REVES.JNL; l''elenco (F3) permette di riaprirlo o eliminarlo e le|',
  'statistiche mostrano l''evoluzione dei sogni, i loro tipi e i|simboli preferiti.|Il dizionario permette di sfogliare tutti i simboli per categoria|',
  'o di cercarne uno con una parola. File > Esporta il rapporto salva|l''analisi completa in un file di testo (REVES.TXT per|impostazione predefinita).|',
  'Menu: F10 o Alt+lettera sottolineata, poi frecce, Invio ed Esc.|Alt+X esce dal programma. L''interfaccia segue la variabile|LANGUAGE (EN, GR, SP, IT); le interpretazioni sono in francese.|');
 BLK : Array[1..NBLK+1] Of Integer = (
  1,4,8,12,16,20,24,28,31,35,
  39,43,46,50,54,58,62,66,70,74,
  78,82,86,90,94,98,102,105,109,113,
  117,121,124,127,130,133,137,141,144,147,
  151,155,159,163,166,169,172,175,179,182,
  186,190,194,198,201,205,208,212,215,218,
  222,225,229,233,237,240,244,248,252,256,
  260,264,267,271,275,278,282,286,290,293,
  297,301,304,307,310,313,316,319,322,326,
  329,332,336,340,344,348,351,354,358,361,
  364,368,371,374,377,380,384,388,392,396,
  400,404,408,412,416,419,423,427,430,434,
  438,442,446,450,454,458,462,465,469,473,
  477,481,485,489,493,497,501,505,508,512,
  515,519,523,527,531,534,538,542,546,550,
  554,557,561,565,569,573,577,581,585,589,
  593,596,600,604,608,611,615,619,623,626,
  630,634,638,642,646,649,652,656,660,663,
  667,671,675,678,681,685,689,693,697,700,
  703,706,710,713,717,720,724,728,732,736,
  740,744,747,750,754,757,761,765,769,773,
  777,781,785,789,793,797,801,804,808,812,
  816,820,824,828,832,836,840,844,848,852,
  856,860,864,868,872,876,880,884,888,892,
  896,900,904,908,912,916,920,924,928,932,
  936,940,944,948,952,956,960,964,968,972,
  976,980,984,988,992,996,1000,1004,1008,1012,
  1016,1020,1024,1028,1032,1036,1040,1044,1048,1052,
  1056,1060,1064,1067,1070,1073,1076,1079,1082,1085,
  1089,1092,1095,1098,1101,1104,1107,1111,1114,1118,
  1122,1126,1130,1134,1137,1141,1145,1149,1152,1156,
  1160,1164,1167,1170,1174,1178,1182,1186,1190,1194,
  1198,1202,1206,1210,1214,1218,1221,1225,1228,1232,
  1236,1240,1244,1248,1252,1256,1260,1264,1268,1272,
  1276,1280,1284,1288,1292,1296,1300,1304,1308,1312,
  1316,1320,1324,1328,1332,1336,1339,1343,1347,1351,
  1355,1359,1362,1366,1369,1372,1376,1379,1383,1387,
  1391,1395,1399,1403,1407,1411,1415,1419,1423,1427,
  1431,1435,1439,1443,1447,1451,1455,1459,1463,1467,
  1471,1475,1479,1483,1487,1491,1495,1499,1503,1507,
  1511,1515,1519,1523,1526,1530,1534,1537,1541,1544,
  1548,1551,1555,1558,1562,1566,1569,1573,1577,1581,
  1585,1588,1592,1595,1599,1603,1607,1611,1615,1619,
  1623,1627,1631,1634,1638,1642,1646,1650,1653,1657,
  1661,1665,1669,1671,1673,1675,1677,1679,1681,1683,
  1685,1687,1689,1691,1693,1695,1697,1699,1701,1703,
  1705,1707,1709,1711,1713,1715,1717,1719,1721,1723,
  1725,1727,1729,1731,1733,1735,1737,1739,1741,1743,
  1745,1747,1749,1751,1753,1755,1757,1759,1761,1763,
  1765,1767,1769,1771,1773,1775,1777,1779,1781,1783,
  1785,1787,1789,1791,1793,1795,1797,1799,1801,1803,
  1805,1807,1809,1811,1813,1815,1817,1819,1821,1823,
  1825,1827,1829,1831,1833,1835,1837,1839,1841,1843,
  1845,1847,1849,1851,1853,1855,1857,1859,1861,1863,
  1865,1867,1869,1871,1873,1875,1877,1879,1881,1883,
  1885,1887,1889,1891,1893,1895,1897,1899,1901,1903,
  1905,1907,1909,1911,1913,1915,1917,1919,1921,1923,
  1925,1927,1929,1931,1933,1935,1937,1939,1941,1943,
  1945,1947,1949,1951,1953,1955,1957,1959,1961,1963,
  1965,1967,1969,1971,1973,1975,1977,1979,1981,1983,
  1985,1987,1989,1991,1993,1995,1997,1999,2001,2003,
  2005,2007,2009,2011,2013,2015,2017,2019,2021,2023,
  2025,2027,2029,2031,2033,2035,2037,2039,2041,2043,
  2045,2047,2049,2051,2053,2055,2057,2059,2061,2063,
  2065,2067,2069,2071,2073,2075,2077,2079,2081,2083,
  2085,2087,2089,2091,2093,2095,2097,2099,2101,2103,
  2105,2107,2109,2111,2113,2115,2117,2119,2121,2123,
  2125,2127,2130,2132,2134,2136,2138,2140,2142,2144,
  2147,2149,2151,2153,2155,2157,2159,2161,2163,2165,
  2167,2169,2171,2173,2175,2177,2179,2181,2183,2185,
  2187,2189,2191,2193,2195,2197,2199,2201,2203,2205,
  2207,2209,2211,2213,2215,2217,2219,2221,2223,2225,
  2227,2229,2231,2233,2235,2237,2239,2241,2243,2245,
  2247,2249,2251,2253,2255,2257,2259,2261,2263,2265,
  2267,2269,2271,2273,2275,2277,2279,2281,2283,2285,
  2287,2289,2291,2293,2295,2297,2299,2301,2303,2305,
  2307,2309,2311,2313,2315,2317,2319,2321,2323,2325,
  2327,2329,2331,2333,2335,2337,2339,2341,2343,2346,
  2348,2350,2352,2354,2356,2358,2360,2362,2364,2366,
  2368,2370,2372,2374,2376,2378,2380,2382,2384,2386,
  2388,2390,2392,2394,2396,2398,2400,2402,2404,2406,
  2408,2411,2413,2415,2417,2419,2421,2423,2425,2427,
  2429,2431,2433,2435,2437,2439,2441,2443,2445,2447,
  2449,2451,2453,2455,2457,2459,2461,2463,2465,2467,
  2469,2471,2473,2475,2477,2479,2481,2483,2485,2487,
  2489,2491,2493,2495,2497,2499,2501,2503,2505,2507,
  2509,2511,2513,2515,2517,2519,2521,2523,2525,2527,
  2529,2531,2533,2535,2537,2539,2541,2543,2545,2547,
  2549,2551,2553,2555,2557,2559,2561,2563,2565,2567,
  2569,2571,2573,2575,2577,2579,2581,2583,2585,2587,
  2589,2591,2593,2595,2597,2599,2601,2603,2605,2607,
  2609,2611,2613,2615,2617,2619,2621,2623,2625,2627,
  2629,2631,2633,2635,2637,2639,2641,2643,2645,2647,
  2649,2651,2653,2655,2657,2659,2661,2663,2665,2667,
  2669,2671,2673,2675,2677,2679,2681,2683,2685,2687,
  2689,2691,2693,2695,2697,2699,2701,2703,2705,2707,
  2709,2711,2713,2715,2718,2720,2722,2724,2726,2728,
  2730,2732,2734,2736,2738,2740,2742,2744,2746,2748,
  2750,2752,2754,2756,2758,2760,2762,2764,2766,2768,
  2770,2772,2774,2776,2778,2780,2782,2784,2786,2788,
  2790,2792,2794,2796,2798,2800,2802,2804,2806,2808,
  2810,2812,2814,2816,2818,2820,2822,2824,2826,2828,
  2830,2832,2834,2836,2838,2840,2842,2844,2846,2848,
  2850,2852,2854,2856,2858,2860,2862,2864,2866,2868,
  2870,2872,2874,2876,2878,2880,2882,2884,2886,2888,
  2890,2892,2894,2896,2898,2900,2902,2904,2906,2908,
  2910,2912,2914,2916,2918,2920,2922,2924,2926,2928,
  2930,2932,2934,2936,2938,2940,2942,2944,2946,2948,
  2950,2952,2954,2956,2958,2960,2962,2964,2966,2968,
  2970,2972,2974,2976,2978,2980,2982,2984,2986,2988,
  2990,2992,2994,2996,2998,3000,3002,3004,3006,3008,
  3010,3012,3014,3016,3018,3020,3023,3025,3028,3030,
  3033,3035,3037,3040,3042,3044,3046,3048,3050,3052,
  3054,3056,3059,3061,3064,3067,3069,3072,3075,3077,
  3079,3081,3083,3085,3087,3089,3091,3093,3095,3097,
  3099,3101,3103,3105,3107,3109,3111,3113,3115,3117,
  3119,3121,3123,3125,3127,3129,3131,3133,3135,3137,
  3139,3141,3143,3145,3147,3149,3151,3153,3155,3157,
  3159,3161,3163,3165,3167,3169,3171,3173,3175,3177,
  3179,3181,3183,3185,3187,3189,3191,3193,3195,3197,
  3199,3201,3203,3205,3207,3209,3211,3213,3215,3217,
  3219,3221,3223,3225,3227,3229,3231,3233,3235,3237,
  3239,3241,3243,3245,3247,3249,3251,3253,3255,3257,
  3259,3261,3263,3265,3267,3269,3271,3274,3276,3278,
  3280,3282,3284,3286,3288,3290,3292,3294,3296,3298,
  3300,3302,3304,3306,3308,3310,3312,3314,3316,3318,
  3320,3322,3324,3326,3328,3330,3332,3334,3336,3338,
  3340,3342,3344,3346,3348,3350,3352,3354,3356,3358,
  3360,3362,3364,3366,3368,3370,3372,3374,3376,3378,
  3380,3382,3384,3386,3388,3390,3392,3394,3396,3398,
  3400,3402,3404,3406,3408,3410,3412,3414,3416,3418,
  3420,3422,3424,3426,3428,3430,3432,3434,3436,3438,
  3440,3442,3444,3446,3448,3450,3452,3456,3459,3462,
  3465,3468,3470,3472,3474,3477,3480,3483,3486,3489,
  3492,3495,3498,3501,3504,3507,3510,3513,3516,3519,
  3522,3525,3528,3532,3535,3538,3541,3544,3547,3549,
  3551,3553,3555,3557,3559,3561,3563,3565,3567,3569,
  3571,3573,3575,3577,3579,3581,3583,3585,3587,3589,
  3591,3593,3595,3597,3599,3604,3609,3613,3616,3620,
  3624,3628,3631,3635,3639,3643,3647,3649,3651,3653,
  3655,3657,3659,3661,3663,3665,3667,3669,3671,3676,
  3680,3684,3688,3692,3696,3700,3704,3707,3711,3714,
  3717,3719,3721,3723,3725,3728,3730,3733,3737,3741,
  3747,3750,3755,3759,3763,3767,3770,3775,3778,3782,
  3786,3789,3792,3796,3801,3803,3808,3812,3816,3819,
  3823,3828,3831,3835,3839,3843,3846,3850,3855,3858,
  3862,3866,3870,3873
 );
 NSYM = 442;
 SNAME : Array[1..NSYM] Of String[26] = (
  'Eau','Mer','Vague','Riviäre','Lac','Pluie','Inondation','Glace','Neige',
  'Cascade','Source','Boue','Plage','Ile','Montagne','VallÇe','DÇsert',
  'Foràt','Arbre','Racine','Feuille','Fleur','Rose','Jardin','Prairie',
  'Grotte','Pierre','Puits','Volcan','Brouillard','Champ','Animal','Serpent',
  'Chat','Chien','Cheval','Loup','Ours','Lion','Tigre','Oiseau','Aigle',
  'Corbeau','Hibou','Colombe','Poisson','Requin','Baleine','Dauphin',
  'AraignÇe','Insecte','Abeille','Fourmi','Mouche','Papillon','Rat','Souris',
  'Lapin','Cerf','Taureau','Vache','Cochon','Mouton','Singe','êlÇphant',
  'Crocodile','Grenouille','Tortue','Escargot','Ver','Scorpion','Renard',
  'Chauve-souris','Coq et poule','Cygne','Cafard','Paon','Chävre','Corps',
  'Dents','Cheveux','Yeux','Bouche','Mains','Pieds','Jambes','Bras','Tàte',
  'Visage','Coeur','Ventre','Peau','Blessure','Cicatrice','Maladie',
  'Grossesse','Vomir','Aveugle','Voix','Oreilles','Nez','Ongles','Doigts',
  'Barbe','Dos','Gorge','Langue','NuditÇ','Märe','Päre','Parents','Enfant',
  'BÇbÇ','Fräre','Soeur','Grands-parents','Famille','Mari','êpouse','Ami',
  'Inconnu','Foule','CÇlÇbritÇ','Roi','Reine','Prince','Princesse','Policier',
  'Voleur','Soldat','MÇdecin','Professeur','Clown','Vieillard','Ennemi',
  'Double (jumeau)','Voisin','Maison','Maison d''enfance','Chambre','Cuisine',
  'Salle de bain','Toilettes','Cave','Grenier','Escalier','Porte','Fenàtre',
  'Mur','Toit','Couloir','Ascenseur','Piäce secräte','êcole','Hìpital',
  'Prison','ChÉteau','Ville','Rue','Labyrinthe','Magasin','Restaurant',
  'Hìtel','Ruines','Tour','Scäne de thÇÉtre','Piscine','Palais','Village',
  'ClÇ','Serrure','Miroir','TÇlÇphone','Ordinateur','Livre','Lettre','Photo',
  'Sac','Parapluie','Bougie','Lampe','Horloge','Bague','Bijou','Couronne',
  'Couteau','Corde','Chaåne','Coffre','Cadeau','Verre brisÇ','êchelle',
  'Masque','PoupÇe','Jouet','Ballon','Carte','Boussole','êpÇe','Bouteille',
  'Lit','Chaise','Table','TÇlÇvision','Cage','Voiture','Freins','Train',
  'Gare','Avion','AÇroport','Bateau','Naufrage','VÇlo','Bus','MÇtro','Moto',
  'Route','Carrefour','Pont','Tunnel','Valise','Billet','Frontiäre','Taxi',
  'Embouteillage','Rater un transport','Voler','Tomber','Poursuite','Fuir',
  'Courir','Nager','Se noyer','Perdre','Chercher','Trouver','Retard','Examen',
  'Crier','Paralysie','Se cacher','Se battre','Danser','Chanter','Rire',
  'Pleurer','Se perdre','Grimper','Descendre','Sauter','DÇmÇnager','Attendre',
  'Enfermement','êcrire','Construire','Nettoyer','Ouvrir','RÇveil',
  'Ràve lucide','Ràve rÇcurrent','PrÇmonition','Feu','Soleil','Lune','êtoile',
  'Ciel','Nuage','Orage','Tempàte','Vent','Arc-en-ciel','Terre',
  'Tremblement de terre','Nuit','Lumiäre','Aube','CrÇpuscule','Espace',
  'êclipse','FumÇe','Dieu','Ange','DÇmon','Fantìme','Priäre','êglise',
  'Temple','Croix','Pràtre','Moine','Paradis','Enfer','Miracle','Autel',
  'MÇditation','Guide spirituel','Voyant','Pälerinage','Cercle','L''Éme',
  'BÇnÇdiction','Mort','Mourir','Cadavre','Cercueil','Enterrement',
  'Cimetiäre','Tombeau','Squelette','Naissance','RÇsurrection','DÇfunt',
  'Vieillesse','MÇtamorphose','Sang','HÇritage','Nourriture','Pain','Fruit',
  'Pomme','GÉteau','Chocolat','Lait','Vin','Viande','Oeuf','Miel','Banquet',
  'Faim','LÇgumes','Sel','CafÇ','Bonbons','Nourriture avariÇe','Soif',
  'Argent','Piäces de monnaie','TrÇsor','Or','Banque','Faillite','Travail',
  'Bureau','Patron','Collägue','RÇunion','Licenciement',
  'Entretien d''embauche','Contrat','Acheter','Vendre','Dette','Richesse',
  'PauvretÇ','Vàtements','Chaussures','Robe','Robe de mariÇe','Chapeau',
  'Manteau','Uniforme','DÇguisement','Sous-vàtements','Maquillage','Lunettes',
  'Vàtements sales','Amour (couple)','Baiser','Amant','Mariage','Rupture',
  'InfidÇlitÇ','Ex-partenaire','SexualitÇ','êtreinte','Rendez-vous',
  'Fianáailles','Divorce','SÇduction','Coup de foudre','Blanc','Noir','Rouge',
  'Bleu','Vert','Jaune','Orange','Violet','Gris','DorÇ','Nombre un',
  'Nombre deux','Nombre trois','Nombre quatre','Nombre cinq','Nombre six',
  'Nombre sept','Nombre huit','Nombre neuf','Nombre dix','Nombre douze',
  'Nombre treize','Guerre','Explosion','Arme Ö feu','Attaque','Meurtre',
  'Bagarre','Incendie','Accident','Catastrophe','Enlävement','Menace',
  'Cambriolage','Poison','Effondrement','Alarme','Terroriste','Otage',
  'Danger','Monstre','Dragon','FÇe','Licorne','Extraterrestre','Sorciäre',
  'Vampire','Zombie','Loup-garou','GÇant','Lutin','Robot','Superpouvoir',
  'InvisibilitÇ','Voyage dans le temps','Siräne','PhÇnix','Magie','CrÇature',
  'Fin du monde','Dinosaure'
 );
 SCAT : Array[1..NSYM] Of Byte = (
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
  3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
  4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,
  5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
  10,10,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,
  12,12,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,13,13,13,13,13,13,
  13,13,13,13,13,14,14,14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,
  15,15,15,15,15,15,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,
  16,16,16,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,18,18,18,18,
  18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18,18
 );
 SDOM : Array[1..NSYM] Of Byte = (
  67,67,68,86,67,67,68,61,67,67,76,65,56,61,73,26,67,65,72,27,
  82,17,17,26,62,67,37,67,61,68,32,65,64,16,51,68,65,26,53,61,
  78,73,76,67,71,67,56,67,51,62,46,32,35,46,87,54,65,12,74,13,
  23,34,52,52,72,65,84,76,62,48,51,53,65,25,17,46,53,56,46,45,
  45,67,51,31,78,84,32,63,53,16,42,54,46,68,46,87,46,67,56,56,
  65,45,32,57,43,46,51,56,26,23,26,72,82,25,21,27,25,12,12,51,
  56,56,50,37,51,17,17,53,35,35,47,37,56,76,56,67,52,26,26,16,
  26,46,64,67,67,87,87,68,65,67,86,83,67,53,46,65,67,58,58,67,
  35,51,86,87,75,53,64,57,25,87,61,56,51,36,76,18,26,65,62,74,
  67,86,17,51,57,61,12,61,67,15,86,87,53,26,26,65,87,78,75,61,
  14,53,25,56,65,83,86,83,86,87,85,68,86,84,58,68,84,87,87,81,
  86,86,83,85,38,83,86,67,68,65,68,86,61,64,63,67,87,35,35,61,
  64,65,65,16,67,15,61,68,87,67,86,82,86,68,63,38,62,87,67,76,
  68,87,17,75,61,78,76,68,68,68,87,78,23,86,67,74,87,86,78,65,
  68,76,76,67,62,70,75,70,78,75,76,71,67,78,70,76,76,87,78,76,
  76,72,86,86,68,86,82,62,62,64,87,78,26,48,86,46,23,24,32,13,
  17,12,16,24,15,41,87,17,52,64,42,57,51,62,45,64,35,38,73,73,
  35,36,35,35,35,53,35,38,38,31,36,38,36,35,36,53,85,15,18,53,
  25,35,56,15,51,65,56,12,16,16,18,18,16,16,16,12,18,18,12,15,
  18,76,65,14,67,48,65,51,76,65,73,57,15,72,32,48,12,76,38,87,
  38,78,87,65,68,65,64,68,65,26,84,86,65,65,26,41,83,68,65,65,
  68,65,76,71,71,58,62,14,58,65,26,62,36,57,56,86,16,78,78,65,
  86,63
 );
 SPOL : Array[1..NSYM] Of ShortInt = (
  0,0,0,1,1,0,-1,-1,1,1,2,-1,1,0,1,1,-1,0,1,1,0,2,2,1,1,
  0,0,0,-1,-1,1,0,-1,0,1,1,-1,0,1,0,1,2,-1,1,2,1,-2,1,2,-1,
  -1,2,1,-1,2,-1,0,1,2,0,1,0,0,0,2,-2,1,1,0,-1,-2,0,-1,1,2,
  -2,0,0,0,-1,1,1,0,1,0,0,1,0,0,1,0,0,-1,0,-1,2,-1,-1,0,0,
  0,0,0,1,0,-1,0,0,1,1,1,1,2,0,1,1,1,1,1,1,0,0,1,1,1,
  1,1,0,-1,0,1,1,0,1,-1,0,0,1,1,1,1,1,0,0,1,1,1,1,0,1,
  0,0,2,0,0,-1,1,0,0,-1,0,1,0,-1,1,0,1,1,1,2,0,0,0,0,1,
  1,0,0,1,1,1,0,1,1,2,-1,0,-1,1,2,-1,1,-1,0,1,1,1,1,1,0,
  1,0,1,0,-1,0,-1,0,0,1,0,1,-2,1,0,0,1,1,0,1,0,0,1,0,0,
  -1,-1,1,-1,-1,-1,0,1,-1,-1,0,1,-1,-1,-1,-2,-1,-1,2,1,1,0,-1,1,0,
  1,0,0,-1,1,1,1,1,0,2,0,0,0,2,1,2,1,0,-1,-1,0,2,1,-1,-1,
  2,2,0,1,-1,-1,1,2,-2,-1,1,1,1,0,1,1,2,-2,2,0,1,2,0,1,1,
  1,2,0,-1,-1,-1,0,-1,-1,-1,2,2,0,0,1,0,1,1,2,1,1,2,1,1,0,
  0,2,2,2,-1,1,0,1,1,-2,0,0,0,2,1,0,-1,0,0,0,0,0,-1,0,0,
  0,0,-1,1,-1,0,0,1,1,0,1,0,0,-1,0,1,-1,2,1,0,2,-1,-1,0,1,
  2,1,2,-1,1,2,1,-1,0,1,1,1,1,1,-1,2,1,0,1,1,1,1,2,1,1,
  1,1,0,-2,-1,-1,-2,-2,-1,-1,-1,-2,-2,-1,-1,-2,-1,-1,-2,-2,-1,-2,0,2,2,
  -1,-1,-2,-1,-1,0,1,-1,2,0,0,-1,2,1,-1,-1,-1
 );
 SARC : Array[1..NSYM] Of Byte = (
  5,5,0,0,0,0,1,0,8,0,5,1,0,4,7,5,7,1,4,5,0,2,2,5,8,
  5,4,5,1,0,5,1,1,2,0,9,1,5,6,1,4,9,1,7,4,4,1,5,8,5,
  0,5,0,0,4,1,0,8,4,6,5,0,3,10,7,1,0,7,0,1,1,10,1,0,2,
  1,3,10,4,3,3,4,0,9,0,9,9,6,3,4,5,3,1,9,1,5,1,7,2,0,
  10,0,0,7,6,0,0,3,5,6,0,8,8,1,2,7,0,2,2,0,1,3,3,6,5,
  9,2,6,10,9,7,7,10,7,1,1,0,4,8,2,5,0,1,1,7,0,0,0,1,6,
  0,0,4,0,0,1,4,3,3,4,3,0,0,7,4,3,0,3,5,7,0,3,0,0,7,
  0,0,3,5,7,7,7,2,4,4,1,0,1,4,8,0,9,3,8,8,8,7,7,9,0,
  2,0,5,3,1,9,0,0,0,9,0,0,1,8,0,1,9,0,7,0,1,0,0,0,0,
  0,0,9,1,1,1,9,5,1,1,9,4,3,3,1,1,1,9,2,2,10,2,1,9,1,
  9,0,0,1,7,6,0,0,0,4,1,7,0,6,2,4,4,0,6,0,0,4,5,0,1,
  4,8,7,4,1,0,4,4,1,1,0,5,4,4,6,7,4,1,4,0,4,7,7,9,4,
  4,4,1,1,1,1,1,1,1,1,8,4,7,7,4,1,6,5,5,0,2,8,0,5,10,
  1,8,5,0,0,5,7,0,8,1,0,3,0,4,4,6,1,3,3,6,1,3,1,3,6,
  0,0,1,4,1,3,3,2,2,3,5,3,10,0,3,7,1,2,2,2,4,0,1,1,2,
  5,0,2,0,10,2,4,1,2,7,5,0,0,7,0,4,4,2,8,4,0,0,7,0,7,
  0,4,10,1,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,9,2,4,
  0,5,1,1,1,6,10,3,9,0,0,2,4,7,1,0,1
 );
 STYP : Array[1..NSYM] Of Byte = (
  8,5,2,5,9,8,1,9,9,8,7,2,3,3,5,9,7,5,8,9,8,4,4,9,9,
  8,9,7,1,2,9,9,8,9,9,5,2,9,3,1,7,5,10,7,7,8,1,7,3,2,
  2,9,9,2,8,2,9,3,7,3,9,9,9,9,9,1,8,9,9,8,1,9,1,9,4,
  2,3,9,9,2,8,7,9,9,5,5,9,9,9,4,9,8,2,12,2,8,8,2,9,9,
  9,9,9,9,9,2,9,2,4,4,9,9,8,4,4,9,9,4,4,9,6,2,3,3,3,
  3,3,2,2,5,9,9,6,7,1,6,9,9,9,4,8,8,2,1,9,8,8,9,2,9,
  12,2,8,9,2,1,6,5,9,2,3,3,5,8,7,3,3,3,9,8,2,8,4,9,7,
  10,9,9,9,7,9,2,4,3,3,1,8,2,6,3,8,8,6,9,9,3,5,5,5,3,
  4,9,4,9,2,5,2,5,12,5,5,5,1,5,9,9,3,5,8,8,8,5,5,8,5,
  2,12,3,2,1,2,5,8,1,2,9,3,2,2,1,1,2,1,4,7,3,4,2,5,8,
  5,8,9,1,9,8,8,8,6,11,12,10,8,7,6,7,7,9,1,1,8,7,9,1,2,
  7,8,8,6,10,2,7,7,1,2,7,7,7,7,7,7,3,1,7,8,7,7,10,5,7,
  7,7,8,2,1,2,8,9,9,1,8,8,4,9,8,1,9,3,9,3,3,3,3,4,3,
  3,8,3,3,3,9,9,9,3,1,3,9,9,6,7,9,2,9,9,9,9,9,2,2,9,
  3,8,2,3,2,9,5,4,3,9,9,9,6,2,9,9,2,4,3,3,3,4,2,12,3,
  4,3,3,1,3,3,7,2,4,7,8,9,4,7,9,7,9,4,7,9,5,4,7,9,8,
  9,7,8,1,1,1,1,1,2,1,2,1,1,2,2,2,2,2,1,2,2,1,6,3,7,
  6,1,1,1,8,6,6,9,3,3,5,4,8,6,6,10,6
 );
 NKEY = 17831;
 { 17831 chaines de KEYS regroupees dans des reservoirs de 200 caracteres
   (separateur '|') : voir KeysStr }
 KEYSP : Array[1..810] Of String[255] = (
  '1|10|10E|10EME|12|13|1ER|1RE|2|2E|2EME|3|3E|3EME|4|4E|4EME|5|5E|5EME|6|6E|6EME|7|7E|7EME|8|8E|8EME|9|9E|9EME|A L ABRI|A LA BOURRE|A NOUVEAU CE REVE|A POIL|ABATTU|ABATTUE|ABATTUS|ABBAYE|ABBAYES|ABBE|',
  'ABDOMEN|ABEILLE*|ABRICOT|ABRICOTS|ABSOLUMENT|ACCABL*|ACCIDENT|ACCIDENTE|ACCIDENTEE|ACCIDENTEL|ACCIDENTS|ACCOUCHAIT|ACCOUCHE|ACCOUCHEMENT|ACCOUCHER|ACHAT|ACHATS|ACHETA|ACHETAIENT|ACHETAIS|ACHETAIT|',
  'ACHETE|ACHETEE|ACHETER|ACTEUR|ACTEURS|ACTRICE|ACTRICES|ADMIR*|ADOR*|ADULTERE|ADVERSAIRE|ADVERSAIRES|AEROPORT|AEROPORTS|AFFAME|AFFAMEE|AFFAMES|AFFECTION|AFFECTUEUSE|AFFECTUEUSEMENT|AFFECTUEUX|AFFOL*|',
  'AGAC*|AGENT DE POLICE|AGITATION|AGITE|AGITEE|AGITEES|AGITES|AGNEAU*|AGONIE|AGONISAIT|AGONISANT|AGRESSE|AGRESSEE|AGRESSEUR|AGRESSION|AIEUL|AIEUX|AIGLE|AIGLES|AIGLON*|AIGUILLE AIMANTEE|AIGUILLES|',
  'AIMAIENT|AIMAIS|AIMAIT|AIME|AIMEE|AIMEES|AIMER|AIMES|AISSELLE|AISSELLES|ALARME|ALARME INCENDIE|ALARMES|ALBUM PHOTO|ALCOOL|ALCOOLS|ALCOVE|ALERTE|ALERTES|ALIEN|ALIENS|ALLEGRESSE|ALLIGATOR*|ALTER EGO|',
  'AMANT|AMANTE|AMANTES|AMANTS|AME|AMES|AMI|AMIE|AMIES|AMIS|AMOUR|AMOUREUSE|AMOUREUSES|AMOUREUX|AMPOULE|AMPOULES|AMYGDALES|ANATOMIE|ANCIEN AMANT|ANCIENNE MAISON|ANDROIDE*|ANGE|ANGE GARDIEN|ANGELOT|',
  'ANGELOTS|ANGES|ANGOISS*|ANIMAL|ANIMAUX|ANNEAU|ANNEAUX|ANNULAIRE|ANONYME|ANORAK*|ANTRE|ANXI*|APAIS*|APEURE|APEUREE|APEUREES|APEURES|APHONE|APICULTEUR*|APOCALYPSE|APOCALYPTIQUE|APPAREIL PHOTO|',
  'APPARITION|APPARITIONS|APPARTEMENT|APPARTEMENTS|APPEL TELEPHONIQUE|APPREHENDAIS|APPREHENDAIT|APPREHENSION|AQUARIUM*|AQUATIQUE|AQUATIQUES|ARAIGNEE*|ARBRE|ARBRES|ARBUSTE|ARBUSTES|ARC EN CIEL|ARCHANGE|',
  'ARCHANGES|ARCS EN CIEL|ARGENT|ARGILE|ARIDE|ARIDES|ARLEQUIN|ARMAGEDDON|ARME|ARME A FEU|ARMES A FEU|ARRET DE BUS|ARSENIC|ASCENSEUR|ASCENSEURS|ASPIC|ASPICS|ASSAILLANT|ASSASSIN|ASSASSINAT|ASSASSINE|',
  'ASSASSINEE|ASSEMBLEE|ASSOCIE|ASSOCIEE|ASSOIFFE|ASSOIFFEE|ASSOIFFES|ASTICOT*|ASTIQUER|ASTRE|ASTRES|ASTROLOGUE|ASTRONAUTE|ASTRONAUTES|ATLAS|ATTAQUAIENT|ATTAQUAIT|ATTAQUE|ATTAQUEE|ATTAQUENT|ATTAQUER|',
  'ATTAQUES|ATTEND|ATTENDAIENT|ATTENDAIS|ATTENDAIT|ATTENDANT|ATTENDIT|ATTENDRE|ATTENDRI*|ATTENDS|ATTENDU|ATTENDUE|ATTENTAT|ATTENTAT SUICIDE|ATTENTATS|ATTENTE|ATTERRIR|ATTERRISSAGE|ATTROUPEMENT|',
  'AU BORD DU GOUFFRE|AU VOLANT|AUBE|AUBERGE|AUBERGES|AUBES|AUCUN|AUCUNE|AUMONIER|AURICULAIRE|AURORE|AURORES|AUTEL|AUTELS|AUTOBUS|AUTOCAR|AUTOCARS|AUTOMATE|AUTOMATES|AUTOMOBILE|AUTOMOBILES|AUTOROUTE|',
  'AUTOROUTES|AVARIE|AVARIEE|AVARIEES|AVARIES|AVENUE|AVENUES|AVERSE|AVERSES|AVEUGLE|AVEUGLEE|AVEUGLES|AVION|AVIONS|AZUR|AZURE|BABOUIN*|BAC|BACCALAUREAT|BAGAGE|BAGAGES|BAGARRE|BAGARRES|BAGARREUR|',
  'BAGARREURS|BAGNOLE|BAGUE|BAGUE DE FIANCAILLES|BAGUES|BAGUETTE|BAGUETTE MAGIQUE|BAGUETTES|BAIE VITREE|BAIGNOIRE|BAIGNOIRES|BAIN|BAINS|BAISER|BAISERS|BAL|BAL COSTUME|BAL MASQUE|BALAFRE|BALAFRES|',
  'BALAYAIS|BALAYAIT|BALAYER|BALEINE*|BALLON|BALLON DE BAUDRUCHE|BALLONS|BANANE|BANANES|BANC|BANCAIRE|BANCS|BANDIT|BANDITS|BANLIEUE|BANQUE|BANQUEROUTE|BANQUES|BANQUET|BANQUETS|BANQUIER|BANQUIERE|',
  'BANQUIERS|BANQUISE|BAPTEME|BAPTISE|BAPTISEE|BARBE|BARBE A PAPA|BARBES|BARBU|BARBUE|BARBUS|BARQUE|BARREAUX|BASILIQUE|BASILIQUES|BASKET|BASKETS|BASSE COUR|BASSIN|BASSINS|BASTON|BATAILLE|BATAILLES|',
  'BATEAU|BATEAUX|BATI|BATIE|BATIR|BATISSAIS|BATISSAIT|BEAU FRERE|BEAU PERE|BEAUX PARENTS|BEBE|BEBES|BEDAINE|BEFFROI|BELIER*|BELLE MERE|BELLE SOEUR|BENEDICTION|BENEDICTIONS|BENI|BENIE|BENIR|BENIS|',
  'BENISSAIT|BENIT|BERET*|BERGE|BERGER ALLEMAND|BERGES|BESACE|BESICLES|BESTIOLE*|BETAIL|BETE|BETE ETRANGE|BETE SAUVAGE|BETES|BETES SAUVAGES|BIBLIOTHEQUE|BIBLIOTHEQUES|BICHE|BICHES|BICYCLETTE|BICYCLETTES|',
  'BIEN AIME|BIEN AIMEE|BIEN ETRE|BIENVEILLAN*|BIERE|BIERES|BIFTECK|BIFURCATION|BIJOU|BIJOUX|BILLET|BILLET D AVION|BILLET DE BANQUE|BILLET DE TRAIN|BILLETS DE BANQUE|BILLETS DE TRAIN|BINOCLES|BIQUETTE*|',
  'BISON*|BISOU|BISOUS|BISTROT|BLANC|BLANCHE|BLANCHES|BLANCHEUR|BLANCS|BLATTE*|BLE|BLES|BLESSE|BLESSEE|BLESSEES|BLESSES|BLESSURE|BLESSURES|BLEU|BLEU DE TRAVAIL|BLEUE|BLEUES|BLEUS|BLEUTE|BLEUTEE|BLOTTI|',
  'BLOTTIE|BLOUSE|BLOUSES|BLOUSON*|BOA|BOAS|BOEUF|BOEUFS|BOIRE|BOIS|BOIT|BOITE|BOITE AUX LETTRES|BOITES|BOIVENT|BOMBARDEMENT|BOMBARDEMENTS|BOMBE|BOMBES|BONBON|BONBONS|BONDI|BONDIR|BONDISSAIS|BONDISSAIT|',
  'BONHEUR|BONHEURS|BONHOMME DE NEIGE|BONNE FEE|BONNET|BONNETS|BORD DE MER|BORSALINO*|BOSQUET|BOSQUETS|BOTTE|BOTTES|BOTTINE*|BOUC|BOUCHE|BOUCHERIE|BOUCHES|BOUCHON|BOUCHONS|BOUCLE TEMPORELLE|',
  'BOUCLES D OREILLES|BOUCS|BOUE|BOUES|BOUEUSE|BOUEUSES|BOUEUX|BOUFFON|BOUFFONS|BOUGEOIR|BOUGEOIRS|BOUGIE|BOUGIES|BOULANGER|BOULANGERE|BOULANGERIE|BOULE DE CRISTAL|BOULEVARD|BOULOT|BOUQUET|BOUQUETS|',
  'BOUQUIN|BOUQUINS|BOURBIER|BOURDON|BOURDONS|BOURG|BOURGADE|BOURRASQUE|BOURRASQUES|BOUSCULADE|BOUSSOLE|BOUSSOLES|BOUTEILLE|BOUTEILLE A LA MER|BOUTEILLES|BOUTIQUE|BOUTIQUES|BOYAU|BRACELET|BRACELETS|',
  'BRAISE|BRAISES|BRANCHE|BRANCHES|BRAQUAGE|BRAQUAGES|BRAQUE|BRAS|BRASIER|BRASIERS|BRASSERIE|BREBIS|BRIGAND|BRIGANDS|BRIOCHE|BRIOCHES|BRIS DE VERRE|BRONTOSAURE*|BROUILLARD|BROUILLARDS|BRUINE|BRULAIENT|',
  'BRULAIT|BRULER|BRUME|BRUMES|BRUMEUSE|BRUMEUX|BU|BUFFLE*|BUREAU|BUREAUX|BUS|BUSE|BUSES|BUTIN|BUVAIENT|BUVAIS|BUVAIT|CABAS|CABINE D ASCENSEUR|CABINETS|CACAO|CACHA|CACHAIENT|CACHAIS|CACHAIT|CACHALOT*|',
  'CACHANT|CACHE|CACHE CACHE|CACHEE|CACHER|CACHES|CACHETTE|CACHETTES|CACHOT|CACHOTS|CADAVRE|CADAVRES|CADEAU|CADEAUX|CADENAS|CADENASSE|CADRAN|CAFARD|CAFARDS|CAFE|CAFES|CAFETIERE|CAFETIERES|CAGE|CAGES|',
  'CAGOULE|CAILLOU|CAILLOUX|CAIMAN*|CALAMITE|CALECON*|CALIN|CALINS|CALM*|CALVAIRE|CALVITIE|CAMARADE|CAMARADES|CAMBRIOLAGE|CAMBRIOLAGES|CAMBRIOLAIT|CAMBRIOLE|CAMBRIOLEE|CAMBRIOLER|CAMION DE POMPIERS|',
  'CANAPE|CANARI*|CANCER|CANCRELAT*|CANDIDAT|CANDIDATE|CANDIDATURE|CANICHE*|CANIF|CANINE|CANINES|CANOT|CANTINE|CANYON|CANYONS|CAPE|CAPE D INVISIBILITE|CAPES|CAPITALE|CAPTIF|CAPTIFS|CAPTIVANT|CAPTIVANTE|',
  'CAPTIVE|CAPTIVEE|CAPTIVITE|CAPUCHE*|CARABINE|CARAFE|CARAMBOLAGE|CARAMEL|CARAMELS|CARAPACE|CARAPACES|CARBONISE|CARBONISEE|CARDIAQUE|CARDIAQUES|CARNAVAL*|CAROTTE|CAROTTES|CARPE|CARPES|CARREFOUR|',
  'CARREFOURS|CARRIERE|CARTE|CARTE AU TRESOR|CARTE D EMBARQUEMENT|CARTE ROUTIERE|CARTES|CARTOMANCIEN|CARTOMANCIENNE|CARTONS|CASCADE|CASCADES|CASQUETTE*|CASTAGNE|CATACLYSME|CATACLYSMES|CATACOMBE|',
  'CATACOMBES|CATASTROPHE|CATASTROPHES|CATASTROPHIQUE|CATHEDRALE|CATHEDRALES|CAUCHEMAR|CAUCHEMARDESQUE|CAUCHEMARS|CAVALAIS|CAVALIER|CAVALIERE|CAVE|CAVEAU|CAVEAUX|CAVERNE|CAVERNES|CAVES|CE TRAIN|CECITE|',
  'CELEBRE|CELEBRES|CELEBRITE|CELEBRITES|CELESTE|CELESTES|CELLIER|CELLULE|CENTIME|CENTIMES|CENTRE COMMERCIAL|CENTRE VILLE|CERCLE|CERCLES|CERCUEIL|CERCUEILS|CERF*|CERISE|CERISES|CETTE PORTE|CHAGRIN|',
  'CHAGRINE|CHAGRINEE|CHAGRINS|CHAINE|CHAINES|CHAISE|CHAISES|CHALEUREUSE|CHALEUREUSEMENT|CHALEUREUX|CHAMAN|CHAMANE|CHAMANS|CHAMBRE|CHAMBRE A COUCHER|CHAMBRE D HOTEL|CHAMBRE SECRETE|CHAMBRES|CHAMP|',
  'CHAMP DE BATAILLE|CHAMPAGNE|CHAMPS|CHANDELLE|CHANDELLES|CHANGER DE MAISON|CHANSON|CHANSONS|CHANT|CHANT DES SIRENES|CHANTA|CHANTAGE|CHANTAIENT|CHANTAIS|CHANTAIT|CHANTANT|CHANTE|CHANTER|CHANTEUR|',
  'CHANTEUSE|CHANTIER|CHANTIERS|CHAPEAU*|CHAPELET|CHAPELLE|CHAPELLES|CHAQUE NUIT|CHAR D ASSAUT|CHAROGNE|CHAROGNES|CHARS D ASSAUT|CHASSE AU TRESOR|CHASSE D EAU|CHAT|CHAT HUANT|CHATEAU|CHATEAU FORT|',
  'CHATEAUX|CHATON|CHATONS|CHATS|CHATTE|CHATTES|CHAUFFEUR DE BUS|CHAUFFEUR DE TAXI|CHAUSSURE*|CHAUVE|CHAUVE SOURIS|CHAUVES SOURIS|CHAVIRAIT|CHAVIRER|CHEF|CHEFFE|CHEMIN|CHEMINS|CHEMISE*|CHENE|CHENES|',
  'CHENILLE*|CHERCHA|CHERCHAIENT|CHERCHAIS|CHERCHAIT|CHERCHANT|CHERCHE|CHERCHEE|CHERCHENT|CHERCHER|CHERCHEUR D OR|CHERI|CHERIE|CHERIES|CHERIS|CHERISSAIS|CHERISSAIT|CHERUBIN|CHERUBINS|CHEVAL|CHEVALIERE|',
  'CHEVAUX|CHEVELURE|CHEVEU|CHEVEUX|CHEVEUX BLANCS|CHEVILLE|CHEVILLES|CHEVRE|CHEVREAU|CHEVREAUX|CHEVRES|CHEVREUIL*|CHEZ MOI|CHIEN|CHIENNE|CHIENNES|CHIENS|CHIMERE|CHIMERES|CHIMPANZE*|CHIOT|CHIOTS|',
  'CHIRURGIEN|CHIRURGIENNE|CHIRURGIENS|CHOCOLAT|CHOCOLAT CHAUD|CHOCOLATS|CHOMAGE|CHOMEUR|CHOMEUSE|CHORALE|CHOUCAS|CHOUETTE*|CHRIST|CHRYSALIDE|CHRYSALIDE*|CHUTAIS|CHUTAIT|CHUTE|CHUTE D EAU|CHUTER|CHUTES|',
  'CHUTES D EAU|CICATRICE|CICATRICES|CICATRISE|CICATRISEE|CIEL|CIERGE|CIERGES|CIEUX|CIL|CILS|CIME|CIMES|CIMETIERE|CIMETIERES|CINQ|CINQUIEME|CINQUIEMES|CIRCULAIRE|CITADELLE|CITE|CITERNE|CITERNES|',
  'CLAIR DE LUNE|CLAIRIERE|CLAIRIERES|CLARTE|CLASSE|CLAUSE|CLAUSES|CLAVIER|CLE|CLEBS|CLEF|CLEFS|CLES|CLINIQUE|CLINIQUES|CLOISON|CLOISONS|CLOUE SUR PLACE|CLOUEE SUR PLACE|CLOWN|CLOWNS|COBRA*|COCCINELLE*|',
  'COCHON*|COCON|COCON*|COCORICO|COCU|COCUE|COEQUIPIER|COEQUIPIERE|COEUR|COEURS|COFFRE|COFFRE AU TRESOR|COFFRE FORT|COFFRES|COFFRET|COFFRETS|COHUE|COIFFURE|COINCE|COINCE DANS LA CIRCULATION|COINCEE|',
  'COLERE|COLERES|COLIMACON*|COLLABORATEUR|COLLABORATEURS|COLLABORATRICE|COLLEGE|COLLEGUE|COLLEGUES|COLLIER|COLLIERS|COLLINE|COLLINES|COLLISION|COLOMBE*|COLONNE VERTEBRALE|COLOSSE|COLOSSES|COMBAT*|',
  'COMBLE|COMBLEE|COMBLEES|COMBLES|COMITE|COMMISSAIRE|COMPAGNE|COMPAGNON|COMPASSION|COMPLETEMENT|COMPLICITE|COMPOSTELLE|COMPRIS QUE JE REVAIS|COMPTE EN BANQUE|CONCOURS|CONDUIRE|CONDUISAIS|CONDUISAIT|',
  'CONFERENCE|CONFERENCES|CONFIANCE|CONFIANT|CONFIANTE|CONFISERIE|CONFRERE|CONFUS|CONFUSE|CONFUSES|CONGEDIE|CONJOINT|CONJOINTE|CONSCIENCE DE REVER|CONSCIENT DE REVER|CONSCIENTE DE REVER|',
  'CONSEIL D ADMINISTRATION|CONSOEUR|CONSTELLATION|CONSTELLATIONS|CONSTRU*|CONTAGION|CONTENT|CONTENTE|CONTENTES|CONTENTS|CONTRAT|CONTRATS|CONTROLAIS MON REVE|CONTROLER MON REVE|COPAIN|COPAINS|',
  'COPIE BLANCHE|COPINE|COPINES|COQ|COQS|COQUELICOT|CORBEAU*|CORBILLARD|CORBILLARDS|CORDAGE|CORDE|CORDELETTE|CORDES|CORNE DE LICORNE|CORNEILLE*|CORPOREL|CORPORELLE|CORPS|CORPS SANS VIE|CORRIDA*|CORRIDOR|',
  'CORRIDORS|COSMOS|COSTUME|COU|COUCHAIT AVEC|COUCHER AVEC|COUCHER DE SOLEIL|COUCHER DU SOLEIL|COUCHERS DE SOLEIL|COUDE|COUDES|COUETTE|COULEE DE LAVE|COULEUR D OR|COULEUVRE*|COULISSES|COULOIR|COULOIRS|',
  'COUP DE FEU|COUP DE FIL|COUP DE FOUDRE|COUP DE POING|COUPABLE|COUPABLES|COUPLE|COUPLES|COUPS DE FEU|COUPS DE POING|COUPURE|COUPURES|COUR DE RECREATION|COURAIENT|COURAIS|COURAIT|COURANT D AIR|COURENT|',
  'COURIR|COURONNE|COURONNEE|COURONNEMENT|COURONNES|COURRIER|COURSE|COURU|COURUT|COUSIN|COUSINE|COUSINES|COUSINS|COUTEAU|COUTEAUX|COUVAIT|COUVENT|COUVER|CRACHIN|CRAIGNAIS|CRAIGNAIT|CRAINDRE|CRAINTE|',
  'CRAINTES|CRAINTIF|CRAINTIVE|CRAMOISI|CRAMOISIE|CRANE|CRANES|CRAPAUD*|CRASH|CRATERE|CRATERES|CREANCIER|CREANCIERS|CREATURE|CREATURES|CREME GLACEE|CREPUSCULE|CREPUSCULES|CRI|CRIAIENT|CRIAIS|CRIAIT|',
  'CRIANT|CRIE|CRIER|CRIQUET*|CRIS|CROCO|CROCODILE*|CROCOS|CROISEE DES CHEMINS|CROISEMENT|CROISIERE|CROISSANT|CROISSANTS|CROIX|CROQUE MITAINE|CROTALE*|CRUCIFIE|CRUCIFIEE|CRUCIFIX|CRUCIFIXION|CRYPTE|',
  'CUISINE|CUISINES|CUISINIERE|CUISSE|CUISSES|CULOTTE*|CULPABILI*|CURE|CURES|CURIEUSE|CURIEUSEMENT|CURIEUSES|CURIEUX|CURIOSITE|CUTTER|CUVETTE|CV|CYANURE|CYBORG*|CYCLISTE|CYCLONE|CYCLONES|CYGNE|',
  'CYGNE NOIR|CYGNES|CYGNES NOIRS|D OR|DAIM|DAIMS|DAMNATION|DAMNE|DAMNES|DANGER|DANGEREUSE|DANGEREUSES|DANGEREUX|DANGERS|DANS LE NOIR|DANS SES BRAS|DANSA|DANSAIENT|DANSAIS|DANSAIT|DANSANT|DANSE|DANSER|',
  'DANSES|DANSEUR|DANSEURS|DANSEUSE|DARD|DARDS|DAUPHIN|DAUPHINS|DE L OR|DE NOUVEAU CE REVE|DECEDE|DECEDEE|DECEDEES|DECEDES|DECES|DECOLLAGE|DECOLLER|DECOMBRES|DECORPORATION|DECOUVERT|DECOUVERTE|',
  'DECOUVRAIS|DECOUVRAIT|DECOUVRIR|DECOUVRIT|DEDALE|DEDALES|DEESSE|DEESSES|DEFERLANTE|DEFERLANTES|DEFLAGRATION|DEFUNT|DEFUNTE|DEFUNTES|DEFUNTS|DEGOUT*|DEGRINGOL*|DEGUIS*|DEJA REVE|DEJA VECU|DEJA VU|',
  'DELABRE|DELABREE|DELAISSE|DELAISSEE|DELAISSES|DELIVRANCE|DELIVRE|DELIVREE|DELUGE|DEMANDE EN MARIAGE|DEMENAG*|DEMEURE|DEMEURES|DEMI FRERE|DEMI SOEUR|DEMON|DEMONIAQUE|DEMONS|DENICHE|DENICHER|DENT|',
  'DENTIER|DENTISTE|DENTITION|DENTS|DENUEMENT|DEPECHAIS|DEPECHAIT|DEPECHER|DEPOT DE BILAN|DEPOUILLE|DEPOUILLES|DEPRIM*|DERACINE|DERACINEE|DESARROI|DESASTRE|DESASTRES|DESCEND|DESCENDAIENT|DESCENDAIS|',
  'DESCENDAIT|DESCENDANT|DESCENDIT|DESCENDRE|DESCENDS|DESCENDU|DESCENDUE|DESCENTE|DESEMPARE|DESEMPAREE|DESEMPARES|DESERT|DESERTIQUE|DESERTIQUES|DESERTS|DESESPER*|DESESPOIR|DESHABILLE|DESHABILLEE|',
  'DESOLATION|DESOLE|DESOLEE|DESOLEES|DESOLES|DESORIENTE|DESORIENTEE|DESSERT|DESSERTS|DESTRIER*|DETECTEUR DE FUMEE|DETENDU|DETENDUE|DETENDUES|DETENDUS|DETENTE|DETENU|DETEST*|DETONATION|DETRESSE|DETTE|',
  'DETTES|DEUIL|DEUX|DEUXIEME|DEUXIEMES|DEVALAIS|DEVALAIT|DEVALER|DEVORAIT|DEVORER|DEVOTION|DIABLE|DIABLES|DIABOLIQUE|DIADEME|DIAMANT|DIAMANTS|DIEU|DIEUX|DINER AUX CHANDELLES|DINO|DINOS|DINOSAURE|',
  'DINOSAURES|DIPLODOCUS|DIRECTEUR|DIRECTRICE|DISEUSE DE BONNE AVENTURE|DISTRIBUTEUR DE BILLETS|DIVIN|DIVINE|DIVINITE|DIVINITES|DIVINS|DIVORCAIT|DIVORCE|DIVORCEE|DIVORCEES|DIVORCER|DIVORCES|DIX|DIXIEME|',
  'DIXIEMES|DIZAINE|DJIHADISTE|DJIHADISTES|DOCTEUR|DOCTEURS|DOIGT|DOIGTS|DOLLARS|DOMICILE|DONJON|DONJONS|DORE|DOREE|DOREES|DORES|DORTOIR|DORTOIRS|DORURE|DORURES|DOS|DOUANE|DOUANES|DOUANIER|DOUANIERS|',
  'DOUCEUR|DOUCHE|DOUCHES|DOUDOUNE*|DOUZAINE|DOUZAINES|DOUZE|DOUZIEME|DRACULA|DRAGON|DRAGONNE|DRAGONS|DRAGUAIT|DRAGUE|DRAGUER|DRAPS|DU TRAIN|DUEL|DUNE|DUNES|DYNAMITE|EAU|EAU BENITE|EAU DE SOURCE|EAUX|',
  'EBATS|EBLOUI*|EBOULEMENT|ECARLATE|ECARLATES|ECCHYMOSE|ECHAPPAIS|ECHAPPAIT|ECHAPPER|ECHAUFFOUREE|ECHELLE|ECHELLES|ECHELON|ECHELONS|ECHINE|ECHOGRAPHIE|ECLAIR|ECLAIRE|ECLAIREE|ECLAIRS|ECLAT DE RIRE|',
  'ECLAT DE VERRE|ECLATS DE VERRE|ECLIPSE|ECLIPSEE|ECLIPSES|ECOEUR*|ECOLE|ECOLES|ECOLIER|ECOLIERS|ECRAN|ECRAN D ORDINATEUR|ECRIN|ECRIRE|ECRIS|ECRIT|ECRITE|ECRITS|ECRITURE|ECRIVAIENT|ECRIVAIS|ECRIVAIT|',
  'ECRIVANT|ECRIVIT|ECROULAIT|ECROULE|ECROULEE|ECROULEMENT|ECROULER|ECZEMA|EDEN|EDIFIAIS|EDIFIER|EFFONDRAIT|EFFONDRE|EFFONDREE|EFFONDREMENT|EFFONDRENT|EFFONDRER|EFFRACTION|EFFRAY*|EFFROI|EGARAIS|EGARE|',
  'EGAREE|EGLISE|EGLISES|ELEPHANT|ELEPHANTEAU|ELEPHANTEAUX|ELEPHANTS|ELFE|ELFES|ELLE COURT|EMBALLAGE CADEAU|EMBARQUEMENT|EMBARRASS*|EMBAUCHE|EMBAUCHEE|EMBOURBE|EMBOURBEE|EMBOUTEILLAGE|EMBOUTEILLAGES|',
  'EMBRANCHEMENT|EMBRASEMENT|EMBRASSA|EMBRASSAIENT|EMBRASSAIS|EMBRASSAIT|EMBRASSANT|EMBRASSE|EMBRASSEE|EMBRASSER|EMERAUDE|EMERVEILL*|EMISSION|EMMENAG*|EMMURE|EMMUREE|EMOUV*|EMPLOI|EMPLOYEUR|EMPOISONNAIT|',
  'EMPOISONNE|EMPOISONNEE|EMPOISONNEMENT|EMPOISONNER|EMPRISONNE|EMPRUNT|EMPRUNTE|EMPRUNTER|EMU|EMUE|EMUES|EMUS|EN AVION|EN COURANT|EN DANGER|EN ESPECES|EN FEU|EN FLAMMES|EN OR|EN PETITE TENUE|EN RETARD|',
  'EN SECURITE|ENCEINTE|ENCEINTES|ENCHAINE|ENCHAINEE|ENCHAINES|ENCHANTE|ENCHANTEE|ENCHANTEES|ENCHANTEMENT*|ENCHANTES|ENCORE CE REVE|ENDETTE|ENDETTEE|ENDETTEMENT|ENERV*|ENFANT|ENFANTS|ENFER|ENFERMAIS|',
  'ENFERMAIT|ENFERME|ENFERMEE|ENFERMEES|ENFERMER|ENFERMES|ENFERS|ENFUI|ENFUIR|ENFUIT|ENFUYAIS|ENFUYAIT|ENLACAIT|ENLACE|ENLACEE|ENLACER|ENLACES|ENLEVEMENT|ENLEVEMENTS|ENLISE|ENLISEE|ENNEIGE|ENNEIGEE|',
  'ENNEIGES|ENNEMI|ENNEMIE|ENNEMIES|ENNEMIS|ENRACINE|ENRACINEE|ENRACINES|ENRAGE|ENRAGEE|ENRAGER|ENRAGES|ENSANGLANTE|ENSANGLANTEE|ENSEIGNANT|ENSEIGNANTE|ENSEIGNANTS|ENSOLEILLE|ENSOLEILLEE|ENSORCELE|',
  'ENSORCELEE|ENTAILLE|ENTAILLES|ENTERRAIT|ENTERRE|ENTERREE|ENTERREMENT|ENTERREMENTS|ENTERRER|ENTERRES|ENTHOUSIAS*|ENTRAVES|ENTREPRISE|ENTREPRISES|ENTRETIEN|ENTRETIEN D EMBAUCHE|ENTRETIENS|ENTROUVERT|',
  'ENTROUVERTE|ENVAHISSEURS|ENVELOPPE|ENVELOPPES|ENVOLAIS|ENVOLAIT|ENVOLE|ENVOLEE|ENVOLER|ENVOUT*|ENVOUTEUSE|EPANOUI*|EPAULE|EPAULES|EPAVE|EPAVES|EPEE|EPEES|EPERVIER*|EPI|EPICERIE|EPIDEMIE|EPIDERME|EPIS|',
  'EPOUSAIT|EPOUSE|EPOUSER|EPOUSES|EPOUVANT*|EPOUX|EPREUVE|EPREUVES|ERMITE|ERMITES|EROTIQUE|EROTIQUES|ERRAIS|ERUPTION|ERUPTIONS|ESCABEAU|ESCALAD*|ESCALATOR|ESCALATORS|ESCALIER|ESCALIERS|ESCARGOT*|',
  'ESCARPIN*|ESCRIME|ESCROC|ESCROCS|ESPACE|ESPRESSO|ESPRIT FRAPPEUR|ESPRITS|ESSAIM*|ESSUYER|ESTOMAC|ESTOMACS|ESTRADE|ETAIS PERDU|ETAIS PERDUE|ETALON|ETALONS|ETANG|ETANGS|ETOILE|ETOILE FILANTE|ETOILEE|',
  'ETOILES|ETONN*|ETOUFFAIS|ETOUFFAIT|ETOUFFE|ETOUFFER|ETRANGER|ETRANGERE|ETRANGERES|ETRANGERS|ETRE ETRANGE|ETREIGNAIT|ETREINDRE|ETREINTE|ETREINTES|ETRES ETRANGES|EUPHORI*|EUROS|EVACUATION|EVACUE|',
  'EVACUER|EVACUES|EVEQUE|EVIER|EX|EX COMPAGNE|EX COMPAGNON|EX COPAIN|EX COPINE|EX FEMME|EX MARI|EX PETIT AMI|EX PETITE AMIE|EXALT*|EXAMEN|EXAMENS|EXASPER*|EXPLOSAIT|EXPLOSE|EXPLOSENT|EXPLOSER|EXPLOSIF|',
  'EXPLOSIFS|EXPLOSION|EXPLOSIONS|EXPRESSO|EXTASE|EXTASES|EXTASIE|EXTASIEE|EXTASIES|EXTINCTION DE VOIX|EXTRALUCIDE|EXTRATERRESTRE|EXTRATERRESTRES|EXTREMEMENT|FACIES|FACTEUR|FAILLE TEMPORELLE|FAILLITE|',
  'FAILLITES|FAIM|FAIMS|FAIRE L AMOUR|FAIRE LES COURSES|FAIT L AMOUR|FALAISE|FALAISES|FAMILIAL|FAMILIALE|FAMILLE|FAMILLES|FAMINE|FAMINES|FANGE|FANTOME|FANTOMES|FAON|FAONS|FARD*|FARFADET*|FASCIN*|FAUCHE|',
  'FAUCHEE|FAUCHEUSE|FAUCON*|FAUNE|FAUTEUIL|FAUTEUILS|FAUVE|FAUVES|FAUX REVEIL|FAUX REVEILS|FEBRILE|FEBRILEMENT|FEE|FEE CLOCHETTE|FEERIE|FEERIQUE|FEERIQUES|FEES|FELIN*|FEMME POISSON|FENETRE|FENETRES|',
  'FERRY|FESTIN|FESTINS|FETE|FETER|FETES|FEU|FEU DE CAMP|FEU DE FORET|FEUILLAGE|FEUILLAGES|FEUILLE|FEUILLES|FEUILLU|FEUX|FIANCAILLES|FIANCE|FIANCEE|FIANCEES|FIANCER|FIANCES|FICELLE|FIER|FIERE|FIERES|',
  'FIERS|FIERTE|FIEVRE|FIEVREUSE|FIEVREUX|FIGE|FIGEE|FIGES|FILE DE VOITURES|FILLE|FILLES|FILLETTE|FILS|FIN DES TEMPS|FIN DU MONDE|FIOLE|FIOLES|FIRMAMENT|FLACON|FLACONS|FLAMBEE|FLAMME|FLAMMES|FLAQUE|',
  'FLAQUES|FLEUR|FLEURI|FLEURIE|FLEURIES|FLEURIS|FLEURS|FLEUVE|FLEUVES|FLIC|FLICS|FLIRT|FLIRTAIT|FLIRTER|FLOCON|FLOCONS|FOLLEMENT|FOND DE TEINT|FOND DU PUITS|FONTAINE|FONTAINES|FORCE SURHUMAINE|FORET|',
  'FORETS|FORMULE MAGIQUE|FORTERESSE|FORTUNE|FOU RIRE|FOUDRE|FOUDROYE|FOUILLAIS|FOUILLAIT|FOUILLER|FOULE|FOULES|FOUR|FOURMI|FOURMILIERE|FOURMILIERES|FOURMIS|FOURNEAU|FOURNEAUX|FOURREAU|FRAISE|FRAISES|',
  'FRANGIN|FRANGINE|FRANGINES|FRANGINS|FRAYEUR|FRAYEURS|FREIN|FREINAGE|FREINAIS|FREINAIT|FREINER|FREINS|FRERE|FRERES|FREROT|FREUX|FRIANDISE|FRIANDISES|FRIC|FRIGO|FRINGUES|FRONTIERE|FRONTIERES|FROTTAIS|',
  'FROTTAIT|FROTTER|FRUIT|FRUITS|FRUSTR*|FUIR|FUITE|FUMAIT|FUMANT|FUMANTE|FUMEE|FUMEES|FUMER|FUNERAILLES|FUNERAIRE|FUREUR|FURIEUSE|FURIEUSEMENT|FURIEUSES|FURIEUX|FUSIL|FUSILLADE|FUSILS|FUTURE MAMAN|',
  'FUYAIENT|FUYAIS|FUYAIT|FUYANT|GADOUE|GAI|GAIE|GAIEMENT|GAIES|GAIETE|GAIS|GALAXIE|GALAXIES|GALERIE|GALERIES|GALET|GALETAS|GALETS|GAMIN|GAMINE|GAMINES|GAMINS|GARE|GARE ROUTIERE|GARES|GATEAU|',
  'GATEAU D ANNIVERSAIRE|GATEAUX|GAZON|GEANT|GEANTE|GEANTES|GEANTS|GEHENNE|GELE|GELEE|GENANT|GENANTE|GENDARME|GENDARMES|GENE|GENEE|GENEES|GENES|GENISSE*|GENOU|GENOUX|GEOLE|GEOLIER|GEOLIERS|GESTATION|',
  'GLACE|GLACE MURALE|GLACEE|GLACES|GLACIER|GLACIERS|GLACON|GLACONS|GLAISE|GLAIVE|GNOME|GNOMES|GORET*|GORGE|GORGEE|GORGEES|GORGES|GORILLE*|GOSIER|GOSSE|GOSSES|GOUFFRE|GOUFFRES|GOULOT|GOUPIL|GOUROU|',
  'GOUROUS|GOUTTIERE|GPS|GRAIN DE BEAUTE|GRAND AGE|GRAND DUC|GRAND MAGASIN|GRAND MERE|GRAND PERE|GRAND REPAS|GRANDE FAUCHEUSE|GRANDIOSE|GRANDIOSES|GRANDS MERES|GRANDS PARENTS|GRANDS PERES|GRATITUDE|',
  'GRATTE CIEL|GRAVATS|GRAVIR|GRAVISSAIS|GRAVISSAIT|GRENIER|GRENIERS|GRENOUILLE*|GRIFFONNAIS|GRIMPA|GRIMPAIENT|GRIMPAIS|GRIMPAIT|GRIMPANT|GRIMPE|GRIMPER|GRIPPE|GRIS|GRISAILLE|GRISATRE|GRISE|GRISES|',
  'GRIZZLI*|GRIZZLY|GROSSESSE|GROSSESSES|GROTTE|GROTTES|GUENILLES|GUENON*|GUEPARD*|GUEPE*|GUERE|GUERIDON|GUERRE|GUERRE MONDIALE|GUERRES|GUERRIER|GUERRIERS|GUICHET|GUIDE SPIRITUEL|GURU|HABIT|HABITS|',
  'HABITS DECHIRES|HABITS SALES|HACHOIR|HAILLONS|HAINE|HAINEUSE|HAINEUX|HAIR|HAISSAIS|HAISSAIT|HALO|HAMAC|HAMEAU|HAMEAUX|HAMSTER*|HANTE|HANTEE|HANTEES|HANTES|HARICOT|HARICOTS|HARMONIE|HARMONIEUSE|',
  'HARMONIEUX|HAUT DE FORME|HAUT LE COEUR|HAUTE MER|HAUTE TOUR|HEMORRAGIE|HERBE|HERBES|HERITAGE|HERITAGES|HERITAIT|HERITE|HERITER|HERITIER|HERITIERE|HERITIERS|HEUREUSE|HEUREUSEMENT|HEUREUSES|HEUREUX|',
  'HIBOU|HIBOUX|HIERARCHIE|HIRONDELLE*|HOLD UP|HONTE|HONTES|HONTEU*|HOPITAL|HOPITAUX|HORLOGE|HORLOGES|HORREUR|HORREURS|HORRIBLE|HORRIBLES|HORRIFI*|HORS DE MON CORPS|HOSPITALISE|HOSPITALISEE|HOSTILE|',
  'HOSTILES|HOSTILITE|HOTEL|HOTELS|HOULE|HUBLOT|HUISSIER|HUIT|HUITIEME|HUITIEMES|HUMILI*|HURLAIS|HURLAIT|HURLE|HURLEMENT*|HURLER|HYBRIDE|HYBRIDES|HYDRE|HYDRES|IL COURT|ILE|ILE DESERTE|ILES|ILOT|ILOTS|',
  'IMAM|IMMACULE|IMMACULEE|IMMENSEMENT|IMMOBILISE|IMMOBILISEE|IMPASSE|IMPERATRICE|IMPERMEABLE*|IMPOSSIBLE DE BOUGER|INCANTATION*|INCAPABLE DE BOUGER|INCARCERE|INCENDIAIRE|INCENDIE|INCENDIEE|INCENDIES|',
  'INCISIVE|INCISIVES|INCONNU|INCONNUE|INCONNUES|INCONNUS|INCONSOLABLE|INCONSOLABLES|INCROYABLEMENT|INDIGENT|INDIGN*|INDIVIDU|INDIVIDUS|INFANTE|INFARCTUS|INFECTION|INFERNAL|INFERNALE|INFERNAUX|INFIDELE|',
  'INFIDELES|INFIDELITE|INFIDELITES|INFIRMIER|INFIRMIERE|INFIRMIERES|INFIRMIERS|INHUMATION|INONDATION|INONDATIONS|INONDE|INONDEE|INONDEES|INONDES|INQUIET*|INSECTE*|INSECURITE|INSPECTEUR|INSTITUTEUR|',
  'INSTITUTRICE|INSULAIRE|INTENSEMENT|INTERNET|INTERRO|INTERROGATION|INTERSECTION|INTIMIDATION|INTRIGU*|INTRUSION|INVASION|INVISIBILITE|INVISIBLE|INVISIBLES|IRIS|IRISE|IRISEE|IRRIT*|ISOLEMENT|IVRE|IVRES|',
  'IVRESSE|JAGUAR*|JAILLIR|JAILLISSAIT|JAILLISSANTE|JALOUSE|JALOUSIE|JALOUX|JAMAIS|JAMBE|JAMBES|JAMBON|JARDIN|JARDIN D EDEN|JARDINAGE|JARDINER|JARDINIER|JARDINS|JAUNATRE|JAUNE|JAUNE D OEUF|JAUNES|JAUNI|',
  'JAUNIE|JE COULAIS|JE COURS|JE SAVAIS QUE JE REVAIS|JESUS|JET|JETEUSE DE SORT|JEU DE CARTES|JEUNES MARIES|JOB|JOIE|JOIES|JOUET|JOUETS|JOUJOU|JOYAU|JOYAUX|JOYEUSE|JOYEUSEMENT|JOYEUSES|JOYEUX|JUBIL*|',
  'JUGEMENT DERNIER|JUMEAU|JUMEAUX|JUMELLE|JUMELLES|JUMENT*|JUNGLE|JUNGLES|JUPE|JUPES|KAMIKAZE|KAMIKAZES|KARMA|KHOL|KIDNAPPE|KIDNAPPEE|KIDNAPPER|KIDNAPPEUR|KIDNAPPEURS|KIDNAPPING|KLAXON|KLAXONS|',
  'KORRIGAN*|L AU DELA|L OR|LA MECQUE|LA PORTE|LA TOUR|LA TROMPAIT|LABRADOR*|LABYRINTHE|LABYRINTHES|LABYRINTHIQUE|LAC|LACS|LAGUNE|LAGUNES|LAIT|LAITEUSE|LAITEUX|LAITIER|LAITIERE|LAITS|LAME|LAMPADAIRE|',
  'LAMPADAIRES|LAMPE|LAMPE DE POCHE|LAMPES|LANGUE|LANGUES|LANTERNE|LANTERNES|LAPEREAU*|LAPIN*|LARGUE|LARGUEE|LARME|LARMES|LARVE*|LASSO|LATRINES|LAVABO|LAVAIS|LAVAIT|LAVE|LAVE EN FUSION|LAVER|LE TRAIN|',
  'LE TROMPAIT|LEGERETE|LEGS|LEGUE|LEGUER|LEGUME|LEGUMES|LEOPARD*|LEPRECHAUN*|LETTRE|LETTRES|LEVER DE SOLEIL|LEVER DU SOLEIL|LEVITATION|LEVRE|LEVRES|LIAISON|LIASSE|LIASSES|LIBERATION|LIBERE|LIBEREE|',
  'LIBEREES|LIBERES|LICENCIE|LICENCIEE|LICENCIEMENT|LICENCIER|LICORNE|LICORNES|LIEVRE*|LILAS|LIMACE*|LINGE SALE|LINGERIE|LINGOT*|LION|LIONCEAU*|LIONNE*|LIONS|LIRE|LISAIS|LISAIT|LIT|LIT DEFAIT|LITS|',
  'LITTORAL|LIVRE|LIVRES|LOCAUX|LOCOMOTIVE|LOGIS|LOMBRIC*|LOQUES|LORGNON*|LOTERIE|LOTO|LOUP|LOUP GAROU|LOUPS|LOUPS GAROUS|LOURDES|LOUVE|LOUVES|LOUVETEAU*|LUCARNE|LUCIDE|LUCIDITE|LUCIFER|LUGUBRE|LUGUBRES|',
  'LUMIERE|LUMIERES|LUMINEUSE|LUMINEUSES|LUMINEUX|LUNAIRE|LUNAIRES|LUNE|LUNES|LUNETTES|LUNETTES DE SOLEIL|LUNETTES NOIRES|LUSTRE|LUTIN|LUTINS|LUTTAIENT|LUTTAIS|LUTTAIT|LUTTE|LUTTER|LUXE|LUXUEUSE|LUXUEUX|',
  'LYCANTHROPE*|LYCANTHROPIE|LYCEE|M A QUITTE|M A QUITTEE|M A TROMPE|M A TROMPEE|MA FEMME|MA MONTRE|MACAQUE*|MACCHABEE|MACHINE A REMONTER LE TEMPS|MACHOIRE|MACHOIRES|MAGASIN|MAGASINS|MAGICIEN*|MAGIE|',
  'MAGIQUE|MAGIQUES|MAGMA|MAGNIFIQUE|MAGNIFIQUES|MAGOT|MAILLON|MAILLONS|MAIN|MAINS|MAISON|MAISON D ENFANCE|MAISON DE MES GRANDS PARENTS|MAISON DE MES PARENTS|MAISON DE MON ENFANCE|MAISON FAMILIALE|',
  'MAISON HANTEE|MAISON NATALE|MAISONS|MAITRE D ECOLE|MAITRE SPIRITUEL|MAITRESSE|MAITRESSES|MAJESTE|MAJESTUEUSE|MAJESTUEUX|MAL A L AISE|MAL DE DOS|MAL DE TETE|MALADE|MALADES|MALADIE|MALADIES|MALAISE|',
  'MALAISES|MALFAITEUR|MALHEUR*|MALLE|MALLES|MAMAN|MAMANS|MAMIE|MAMMOUTH|MAMMOUTHS|MAMY|MANAGER|MANDALA|MANDALAS|MANDARINE|MANGE|MANGEAIENT|MANGEAIS|MANGEAIT|MANGEE|MANGENT|MANGER|MANOIR|MANQUE L AVION|',
  'MANQUE LE TRAIN|MANQUER L AVION|MANQUER LE TRAIN|MANSARDE|MANSARDES|MANTEAU*|MANTRA|MANTRAS|MANUCURE|MAPPEMONDE|MAQUILL*|MARCHE D ESCALIER|MARCHES|MARE|MARECAGE|MARECAGES|MAREE|MAREES|MARES|MARGELLE|',
  'MARGELLES|MARGUERITE|MARI|MARIAGE|MARIAGES|MARIEE|MARIEES|MARIER|MARIES|MARIONNETTE|MARIONNETTES|MARIS|MARRAINE FEE|MARSOUIN|MARSOUINS|MARTIEN|MARTIENS|MASCARA*|MASQUE|MASQUEE|MASQUES|MASURE|MATELAS|',
  'MATERNEL|MATOU|MATOUS|MAUSOLEE|MAUSSADE|MAUVE|MAUVES|ME BATTAIS|ME BATTRE|ME PERDAIS|ME PERDIS|ME PERDRE|ME PRESSAIS|ME QUITTAIT|ME REVEILLE|ME REVEILLER|ME TROMPAIT|ME TROMPE|MECHE|MECHES|MEDECIN|',
  'MEDECINS|MEDITAIS|MEDITAIT|MEDITANT|MEDITATION|MEDITE|MEDITER|MEDIUM|MEILLEUR AMI|MEILLEURE AMIE|MELANCOLI*|MEME REVE|MENACAIT|MENACANT|MENACANTE|MENACE|MENACEE|MENACENT|MENACER|MENACES|MENAGE|',
  'MENDIAIS|MENDIANT|MENDIANTE|MENDIER|MENTON|MENTONS|MEPRIS*|MER|MERCENAIRE|MERE|MERES|MERLE|MERLES|MERS|MERVEILL*|MESANGE*|MESSE|METAMORPHOSE|METAMORPHOSEE|METAMORPHOSES|METIER|METRO|METROPOLE|METROS|',
  'MEURENT|MEURS|MEURT|MEURTRE|MEURTRES|MEURTRIER|MEUTE|MEUTES|MICHE|MIEL|MIELLEUSE|MIELLEUX|MIELS|MIGRAINE|MILITAIRE|MILITAIRES|MILLIARDAIRE|MILLIONNAIRE|MINOU|MINOUS|MINUIT|MIRACLE|MIRACLES|',
  'MIRACULEUSE|MIRACULEUSEMENT|MIRACULEUX|MIROIR|MIROIRS|MIS A LA PORTE|MISERABLE|MISERABLES|MISERE|MISSIVE|MITE|MITES|MITRAILLETTE|MITRAILLEUSE|MOBYLETTE|MOCASSIN*|MOINE|MOINEAU*|MOINES|MOISI|MOISIE|',
  'MOISISSURE|MOISSON|MOISSONS|MOLAIRE|MOLAIRES|MOLLET|MOLLETS|MOLOSSE*|MON DOUBLE|MON HOMME|MONARQUE|MONARQUES|MONASTERE|MONASTERES|MONIALE|MONIALES|MONNAIE|MONOCLE|MONOCLES|MONSTRE|MONSTRES|',
  'MONSTRUEUSE|MONSTRUEUX|MONT|MONTAGNE|MONTAGNES|MONTAIS|MONTAIT|MONTE CHARGE|MONTGOLFIERE|MONTRE BRACELET|MONTRES|MONTS|MORCEAUX DE VERRE|MORGUE|MOROSE|MOROSES|MORT|MORT VIVANT|MORTE|MORTE VIVANTE|',
  'MORTEL|MORTELLE|MORTELS|MORTES|MORTIFIE|MORTIFIEE|MORTS|MORTS VIVANTS|MOSQUEE|MOSQUEES|MOTARD|MOTEL|MOTO|MOTOCYCLETTE|MOTOS|MOUCHE|MOUCHERON*|MOUCHES|MOURAIENT|MOURAIS|MOURAIT|MOURANT|MOURANTE|MOURIR|',
  'MOURUT|MOUSTACHE|MOUSTACHES|MOUSTIQUE*|MOUTON*|MUE|MUET|MUETS|MUETTE|MUETTES|MULOT*|MULTITUDE|MUR|MURAILLE|MURAILLES|MURET|MURETS|MURS|MUSARAIGNE*|MUTANT|MUTANTE|MUTANTES|MUTANTS|MUTATION|MYGALE*|N|',
  'NAGE|NAGEA|NAGEAIENT|NAGEAIS|NAGEAIT|NAGEANT|NAGER|NAGEUR|NAGEUSE|NAIN|NAINE|NAINS|NAISSANCE|NAISSANCES|NAIT|NAITRE|NAPPE|NAQUIS|NAQUIT|NARINE|NARINES|NAUFRAGE|NAUFRAGES|NAUSEE|NAUSEES|NAVIGUER|',
  'NAVIRE|NAVIRES|NAVRE|NAVREE|NE|NECROPOLE|NECROPOLES|NECTAR|NEE|NEIGE|NEIGEAIT|NEIGER|NEIGES|NEREIDE*|NERVEUSE|NERVEUSES|NERVEUX|NERVOSITE|NES|NETTOY*|NEUF|NEUVIEME|NEUVIEMES|NEVEU|NEZ|NI|NIECE|',
  'NIRVANA|NOCE|NOCES|NOCTURNE|NOCTURNES|NOEUD|NOEUDS|NOIR|NOIRCEUR|NOIRE|NOIRES|NOIRS|NOMBRIL|NONNE|NONNES|NOSTALGI*|NOTAIRE|NOTRE ANCIENNE MAISON|NOUNOURS|NOURRISSON|NOURRISSONS|NOURRITURE|NOURRITURES|',
  'NOUS BATTIONS|NOUVEAU LOGEMENT|NOUVEAU NE|NOUVEAU NEE|NOUVEAU NES|NOUVEL APPARTEMENT|NOUVELLE PIECE|NOYA|NOYADE|NOYAIENT|NOYAIS|NOYAIT|NOYANT|NOYE|NOYEE|NOYEES|NOYER|NOYES|NU|NUAGE|NUAGES|NUAGEUSE|',
  'NUAGEUX|NUDISTE|NUDITE|NUE|NUEE|NUEES|NUES|NUIT|NUITS|NULLEMENT|NUQUE|NUS|OBSCURITE|OBSEQUES|OCEAN|OCEANIQUE|OCEANS|ODORAT|OEIL|OEUF|OEUFS|OFFERT|OFFRAIT|OFFRANDE|OFFRANDES|OFFRIR|OGRE|OGRES|OGRESSE|',
  'OISEAU|OISEAU DE FEU|OISEAUX|OISILLON*|OMBRELLE|OMBRELLES|OMELETTE|OMELETTES|OMOPLATE|OMOPLATES|ONCLE|ONCLES|ONDINE|ONDINES|ONGLE|ONGLES|OPEN SPACE|OPPOSANT|OPPRESS*|OPULENCE|OR MASSIF|OR PUR|ORAGE|',
  'ORAGES|ORAGEUSE|ORAGEUX|ORANG OUTAN|ORANGE|ORANGEE|ORANGEES|ORANGES|ORDI|ORDINATEUR|ORDINATEUR PORTABLE|ORDINATEURS|OREILLE|OREILLER|OREILLERS|OREILLES|ORGASME|ORQUE|ORQUES|ORTEIL*|OS|OSSEMENTS|',
  'OSSUAIRE|OTAGE|OTAGES|OURAGAN|OURAGANS|OURS|OURSE|OURSES|OURSON*|OUVERT|OUVERTE|OUVERTES|OUVERTS|OUVERTURE|OUVRAIENT|OUVRAIS|OUVRAIT|OUVRANT|OUVRE|OUVRIR|OUVRIT|OVNI|OVNIS|PACTE|PAGODE|PAGODES|PAIN|',
  'PAINS|PAISIBL*|PAIX|PALACE|PALAIS|PALAIS PRESIDENTIEL|PALAIS ROYAL|PALIER|PALPITATIONS|PANIQU*|PANOPLIE*|PANTALON*|PANTHERE*|PANTIN|PANTINS|PANTOUFLE*|PAON|PAONNE|PAONNES|PAONS|PAPA|PAPAS|PAPE|PAPI|',
  'PAPILLE|PAPILLES|PAPILLON*|PAPY|PAQUEBOT|PAQUET CADEAU|PARADIS|PARADISIAQUE|PARALYS*|PARAPLUIE|PARAPLUIES|PARASOL|PARASOLS|PARC|PARCS|PARDESSUS|PARENT|PARENTAL|PARENTALE|PARENTS|PARKA*|PAROI|PAROIS|',
  'PAROISSE|PARTENAIRE|PARTIEL|PARTIELS|PAS|PASSAGE A TABAC|PASSAGE SECRET|PASSE PARTOUT|PASSEPORT|PASSEPORTS|PASSERELLE|PASSERELLES|PASTEUR|PATATE|PATATES|PATERNEL|PATERNELLE|PATIENTAIS|PATIENTER|',
  'PATISSERIE|PATISSERIES|PATRON|PATRONNE|PATRONS|PATURAGE|PATURAGES|PATURE|PAUME|PAUMES|PAUPIERE|PAUPIERES|PAUVRE|PAUVRES|PAUVRETE|PAVILLON|PAYAIS|PAYER|PDG|PEAU|PEAUX|PEDALAIS|PEDALE DE FREIN|PEDALER|',
  'PEDILUVE|PELERIN|PELERINAGE|PELERINAGES|PELERINE|PELERINS|PELOUSE|PELOUSES|PELUCHE|PELUCHES|PENDENTIF|PENDULE|PENDULES|PENSION ALIMENTAIRE|PEPITE*|PERCUTE|PERCUTEE|PERD|PERDAIENT|PERDAIS|PERDAIT|',
  'PERDANT|PERDIT|PERDRE|PERDS|PERDU|PERDU MON CHEMIN|PERDU MON EMPLOI|PERDU MON TRAVAIL|PERDUE|PERDUES|PERDUS|PERE|PERES|PERIL|PERILLEUSE|PERILLEUX|PERILS|PERIME|PERIMEE|PERLE|PERLES|PERROQUET*|',
  'PERRUCHE*|PERRUQUE|PERSIENNE|PERSIENNES|PERSONNE AGEE|PERSONNE NE ME VOYAIT|PERSONNE NE POUVAIT ME VOIR|PERTE|PERTES|PETALE|PETALES|PETIT AMI|PETIT GARCON|PETIT MATIN|PETITE AMIE|PETITE FILLE|',
  'PETITE MONNAIE|PETITE ROBE|PETITE TENUE|PETRIFIE|PETRIFIEE|PETRIFIEES|PETRIFIES|PEUR|PEURS|PHENIX|PHOENIX|PHOTO|PHOTOCOPIEUSE|PHOTOGRAPHIE|PHOTOGRAPHIER|PHOTOGRAPHIES|PHOTOS|PICKPOCKET|PIECE CACHEE|',
  'PIECE DE MONNAIE|PIECE INCONNUE|PIECE OUBLIEE|PIECE SECRETE|PIECES D ARGENT|PIECES D OR|PIECES DE MONNAIE|PIECES JAUNES|PIECES SECRETES|PIECETTE|PIECETTES|PIED*|PIEGE|PIEGEE|PIERRE|PIERRE TOMBALE|',
  'PIERRES|PIERRES TOMBALES|PIGEON*|PIPISTRELLE*|PISCINE|PISCINES|PISTE D ATTERRISSAGE|PISTOLET|PISTOLETS|PITIE|PITRE|PLAGE|PLAGES|PLAIE|PLAIES|PLAISIR|PLAISIRS|PLAN DE LA VILLE|PLANAIS|PLANAIT|PLANCHES|',
  'PLANER|PLANETE|PLANETES|PLANQUE|PLANQUEE|PLEINE LUNE|PLENITUDE|PLEURA|PLEURAIENT|PLEURAIS|PLEURAIT|PLEURANT|PLEURE|PLEURER|PLEURS|PLEUT|PLEUVAIT|PLEUVOIR|PLONGEAIS|PLONGEAIT|PLONGEOIR|PLONGEON|',
  'PLONGER|PLUIE|PLUIES|PLUME DE PAON|PLUS UN SOU|PLUVIEUX|POGNON|POIGNARD|POIGNARDS|POIGNEE DE PORTE|POIGNET|POIGNETS|POING|POINGS|POINT DU JOUR|POINTS CARDINAUX|POIRE|POIRES|POISON|POISONS|',
  'POISSON ROUGE|POISSON*|POISSONS ROUGES|POLICE|POLICIER|POLICIERE|POLICIERS|POLTERGEIST|POMME|POMME DE TERRE|POMMES|POMMES DE TERRE|POMMETTE|POMMETTES|POMMIER|POMMIERS|POMPIER|POMPIERS|PONEY*|PONT|',
  'PONT LEVIS|PONT SUSPENDU|PONTS|PORC|PORCELET*|PORCS|PORTABLE|PORTAIL|PORTAILS|PORTE D EMBARQUEMENT|PORTE D ENTREE|PORTE DEROBEE|PORTE FERMEE|PORTE OUVERTE|PORTEFEUILLE|PORTES|PORTILLON|PORTRAIT|',
  'PORTRAITS|POSEUR DE BOMBE|POSSEDE|POSSEDEE|POSTE DE TRAVAIL|POSTE FRONTIERE|POSTULER|POT DE MIEL|POTAGER|POTAGERS|POTE|POTES|POUCE|POUCES|POUDREUSE|POULAILLER*|POULAIN*|POULE|POULES|POULETTE*|POUPEE|',
  'POUPEES|POUPON|POUPONS|POURCHASS*|POURPRE|POURPRES|POURRI|POURRIE|POURRIES|POURRIS|POURSUIT|POURSUITE|POURSUIVAIENT|POURSUIVAIT|POURSUIVENT|POURSUIVI|POURSUIVIE|POURSUIVIES|POURSUIVIS|POURSUIVRE|',
  'POUSSIN*|POUVAIS PAS BOUGER|POUVAIS PLUS BOUGER|PRAIRIE|PRAIRIES|PRALINE|PRALINES|PRE|PRECIPICE|PREDICTION|PREDICTIONS|PREDIRE|PREMIER|PREMIER RENDEZ VOUS|PREMIERE|PREMIERES|PREMIERS|PREMONIT*|',
  'PRESAGE|PRESAGES|PRESSENTIMENT|PRESSENTIMENTS|PRETRE|PRETRES|PRIA|PRIAIENT|PRIAIS|PRIAIT|PRIANT|PRIE|PRIENT|PRIER|PRIERE|PRIERES|PRINCE|PRINCE CHARMANT|PRINCES|PRINCESSE|PRINCESSES|PRINCIER|',
  'PRIS EN OTAGE|PRISE D OTAGES|PRISE EN OTAGE|PRISON|PRISONNIER|PRISONNIERE|PRISONNIERS|PRISONS|PRODIGE|PRODIGES|PROF|PROFESSEUR|PROFESSEURE|PROFESSEURS|PROFONDEMENT|PROFS|PROJECTEURS|PROPHETIE|',
  'PROPHETIES|PROPHETIQUE|PRUNELLE|PRUNELLES|PSYCHE|PTERODACTYLE*|PUDEUR|PUITS|PULL|PULLS|PUMA|PUMAS|PUNAISE*|PUPILLE|PUPILLES|PYTHON*|QUAI|QUAIS|QUARTIER|QUARTIERS|QUATRE|QUATRIEME|QUATRIEMES|QUIETUDE|',
  'RABBIN|RACINE|RACINES|RADIEUSE|RADIEUSES|RADIEUX|RAFALE|RAFALES|RAGE|RAILS|RAINETTE*|RAISIN|RAISINS|RAMPE|RANCARD|RANCE|RANCOEUR|RANCON|RANCUNE|RAPACE*|RAPIERE|RAPT|RASE|RASOIR|RASSEMBLEMENT|RASSUR*|',
  'RAT|RAT D EGOUT|RATE L AVION|RATE LE BUS|RATE LE TRAIN|RATE MON AVION|RATE MON TRAIN|RATER L AVION|RATER LE BUS|RATER LE TRAIN|RATER MON TRAIN|RATS|RATS D EGOUT|RAVI|RAVIE|RAVIES|RAVIN|RAVINS|RAVIS|',
  'RAVISSANT|RAVISSANTE|RAVISSEMENT|RAVISSEUR|RAVISSEURS|RAYON DE SOLEIL|RAYONNANT|RAYONNANTE|RAYONS DE SOLEIL|RAZ DE MAREE|REALISE QUE JE REVAIS|RECHERCHE|RECOLTE|RECOLTES|RECONFORT*|RECRUTEMENT|',
  'RECRUTEUR|RECRUTEUSE|RECURRENT|REDIGEAIS|REDIGER|REFAIS CE REVE|REFAIT CE REVE|REFLET|REFLETS|REFRIGERATEUR|REGRET|REGRETS|REGRETTAIS|REGRETTAIT|REGRETTER|REINCARNATION|REINCARNE|REINCARNEE|REINE|',
  'REINES|REJOUI*|RELAX*|RELIGIEUSE|RELIGIEUSES|REMBOURSAIS|REMBOURSEMENT|REMBOURSER|REMONTAIS LE TEMPS|REMONTE LE TEMPS|REMONTER LE TEMPS|REMORDS|REMPART|REMPARTS|RENAISSAIT|RENAISSAIT DE SES CENDRES|',
  'RENAISSANCE|RENAIT|RENAITRE|RENAITRE DE SES CENDRES|RENARD|RENARDE|RENARDEAU*|RENARDS|RENCARD|RENDEZ VOUS|RENDRE L AME|RENNE*|RENVOYE|RENVOYEE|REPAS|REPUGN*|REQUIN|REQUINS|RER|RESSUSCITA|RESSUSCITAIT|',
  'RESSUSCITE|RESSUSCITEE|RESSUSCITER|RESTAURANT|RESTAURANTS|RESURRECTION|RETARD|RETARDAIS|RETARDE|RETARDEE|RETARDS|REUNION|REUNIONS|REVE LUCIDE|REVE QUI REVIENT|REVE RECURRENT|REVEIL|REVEILLA|',
  'REVEILLAIENT|REVEILLAIS|REVEILLAIT|REVEILLANT|REVEILLE|REVEILLEE|REVEILLER|REVEILLON|REVEILS|REVENIR A LA VIE|REVENU A LA VIE|REVENUE A LA VIE|REVES LUCIDES|REVES RECURRENTS|REVOLT*|REVOLVER|RIAIENT|',
  'RIAIS|RIAIT|RIANT|RICANAIT|RICHE|RICHES|RICHESSE|RICHESSES|RIDE|RIDEAU DE SCENE|RIDES|RIDICUL*|RIENT|RIGOLAIS|RIGOLAIT|RIGOLER|RIMMEL|RIRE|RIRES|RIT|RIVAGE|RIVAGES|RIVAL|RIVALE|RIVAUX|RIVE|RIVES|',
  'RIVIERE|RIVIERES|RIXE|RIXES|ROBE|ROBE BLANCHE|ROBE D ETE|ROBE DE MARIAGE|ROBE DE MARIEE|ROBE DE SOIREE|ROBE LONGUE|ROBE NUPTIALE|ROBES|ROBES DE MARIEE|ROBOT|ROBOTS|ROCHE|ROCHER|ROCHERS|ROCHES|ROCHEUX|',
  'ROI|ROIS|ROMAN|ROMANS|ROMPAIS|ROMPAIT|ROMPRE|ROMPU|ROND POINT|RONGEUR*|ROSE|ROSERAIE|ROSES|ROSIER|ROSIERS|ROSSIGNOL*|ROTI|ROUGE|ROUGE A LEVRES|ROUGEATRE|ROUGES|ROUSSETTE*|ROUTE|ROUTES|ROYAUTE|RUCHE*|',
  'RUE|RUELLE|RUELLES|RUES|RUINE|RUINEE|RUINES|RUISSEAU|RUISSEAUX|RUPTURE|RUPTURES|S EST REALISE|SA FEMME|SABLE|SABLES|SABLIER|SABRE|SABRES|SAC|SAC A DOS|SAC A MAIN|SAC DE VOYAGE|SACOCHE|SACRIFICE|',
  'SACRIFICES|SACRIFIE|SACRIFIEE|SACRIFIER|SACS|SAHARA|SAIGNAIT|SAIGNE|SAIGNEMENT|SAIGNEMENT DE NEZ|SAIGNEMENTS|SAIGNER|SALADE|SALADES|SALAIRE|SALE|SALEE|SALEES|SALES|SALIERE|SALLE D ATTENTE|',
  'SALLE D OPERATION|SALLE DE BAIN|SALLE DE BAINS|SALLE DE CLASSE|SALLE DE REUNION|SALLE DE SPECTACLE|SALLE DU TRONE|SANCTUAIRE|SANCTUAIRES|SANDALE*|SANG|SANGLANT|SANGLANTE|SANGLANTES|SANGLANTS|',
  'SANGLIER*|SANGLOT*|SANS|SANS ABRI|SANS FREINS|SANS ISSUE|SANS LE SOU|SAOUL|SAPIN|SAPINS|SARCOPHAGE|SARCOPHAGES|SATAN|SAUCISSE|SAUCISSES|SAULE|SAULES|SAUT|SAUTA|SAUTAIENT|SAUTAIS|SAUTAIT|SAUTANT|SAUTE|',
  'SAUTER|SAUTERELLE*|SAUTS|SAVAIS QUE JE REVAIS|SCARABEE*|SCEPTRE|SCOOTER|SCORPION|SCORPIONS|SDF|SE BATTAIENT|SE BATTAIT|SE BATTRE|SE FIANCER|SE TRANSFORMER|SEANCE|SEANCES|SECOND|SECONDE|SEDUCTEUR|',
  'SEDUCTION|SEDUCTRICE|SEDUIRE|SEDUISAIS|SEDUISAIT|SEDUIT|SEDUITE|SEISME|SEISMES|SEL|SELFIE|SELS|SEMINAIRE|SENTIER|SENTIERS|SEPARATION|SEPARATIONS|SEPT|SEPTIEME|SEPTIEMES|SEPULTURE|SEPULTURES|',
  'SEQUESTRATION|SEQUESTRE|SEQUESTREE|SERAPHIN|SERAPHINS|SEREIN|SEREINE|SEREINES|SEREINS|SERENITE|SERGENT|SERPENT|SERPENTS|SERRURE|SERRURES|SERVEUR|SERVEURS|SERVEUSE|SEUIL|SEXE|SEXTANT|SEXUALITE|SEXUEL|',
  'SEXUELLE|SEXUELLES|SEXUELS|SHOPPING|SIEGE SOCIAL|SIGNAIS|SIGNAIT|SIGNAL D ALARME|SIGNATURE|SIGNATURES|SIGNE|SIGNE DE CROIX|SIGNEE|SIGNER|SILHOUETTE|SILHOUETTES|SINGE*|SINISTRE|SINISTRES|SIRENE|',
  'SIRENES|SISMIQUE|SIX|SIXIEME|SIXIEMES|SLIP|SLIPS|SMARTPHONE|SMS|SOEUR|SOEURS|SOFA|SOIF|SOL|SOLDAT|SOLDATS|SOLEIL|SOLEILS|SOLITAIRE|SOLITAIRES|SOLITUDE|SOMBRAIT|SOMBRE|SOMBRER|SOMMET|SOMMETS|',
  'SON DOUBLE|SORCELLERIE|SORCIER|SORCIERE|SORCIERES|SORCIERS|SORTAIS AVEC|SORTIE DE ROUTE|SORTILEGE*|SORTIR AVEC|SOSIE|SOSIES|SOUCHE|SOUCHES|SOUCOUPE VOLANTE|SOUCOUPES VOLANTES|SOUFFLE DU VENT|SOUILLE|',
  'SOUILLEE|SOUILLES|SOUL|SOULAG*|SOULIER*|SOUPENTE|SOURCE|SOURCES|SOURD|SOURDE|SOURDES|SOURDS|SOURICEAU*|SOURIS|SOUS BOIS|SOUS SOL|SOUS SOLS|SOUS VETEMENT|SOUS VETEMENTS|SOUTERRAIN|SOUTERRAINS|',
  'SOUTIEN GORGE*|SOUVERAIN|SOUVERAINE|SPECTRAL|SPECTRE|SPECTRES|SPIRALE|SPIRALES|SPLENDIDE|SPLENDIDES|SPRINT*|SQUALE|SQUALES|SQUELETTE|SQUELETTES|SQUELETTIQUE|STAR|STARS|STATION DE METRO|STEAK|STEAKS|',
  'STELE|STRESS*|STRING|STRINGS|STUPEF*|SUBLIME|SUBLIMES|SUBMERGE|SUBMERGEE|SUCETTE|SUCETTES|SUCRERIE|SUCRERIES|SUIS PERDU|SUIS PERDUE|SUPER HEROINE|SUPER HEROS|SUPER POUVOIR|SUPER POUVOIRS|SUPERHEROINE|',
  'SUPERHEROS|SUPERIEUR HIERARCHIQUE|SUPERMARCHE|SUPERPOUVOIR|SUPERPOUVOIRS|SUR LA SCENE|SUR SCENE|SURDITE|SURMULOT*|SURPRENANT|SURPRENANTE|SURPRIS|SURPRISE|SURPRISES|SYNAGOGUE|SYNAGOGUES|T REX|TABASSE|',
  'TABASSER|TABLE|TABLE A MANGER|TABLEE|TABLES|TABLIER*|TABOURET|TABOURETS|TALONS HAUTS|TANTE|TANTES|TAON|TAONS|TARENTULE*|TAROT|TARTE|TARTES|TAUREAU|TAUREAUX|TAXI|TAXIS|TELE|TELEKINESIE|TELEPHONAIT|',
  'TELEPHONE|TELEPHONER|TELEPHONES|TELEVISEUR|TELEVISION|TELLEMENT|TEMPETE|TEMPETES|TEMPLE|TEMPLES|TENDREMENT|TENDRESSE|TENEBRES|TENUE|TENUE DE TRAVAIL|TENUES|TERMINAL|TERMITE*|TERRE|TERRE TREMBLAIT|',
  'TERRE TREMBLE|TERREAU|TERRES|TERREUR|TERREURS|TERRIBLEMENT|TERRIFI*|TERRORISE|TERRORISEE|TERRORISEES|TERRORISES|TERRORISME|TERRORISTE|TERRORISTES|TESSONS|TESTAMENT|TETARD*|TETE|TETE A TETE|',
  'TETE DE MORT|TETES|TEXTO|TGV|THE|THEATRE|THEATRES|THUNE|THUNES|TIARE|TICKET|TICKETS|TIGRE*|TIRELIRE|TISANE|TISANES|TITAN|TITANS|TITRE DE TRANSPORT|TOCSIN|TOGE|TOGES|TOILE D ARAIGNEE|TOILES D ARAIGNEE|',
  'TOILETTES|TOIT|TOITS|TOITURE|TOITURES|TOMATE|TOMATES|TOMBA|TOMBAIENT|TOMBAIS|TOMBAIS AMOUREUX|TOMBAIT|TOMBAIT AMOUREUX|TOMBANT|TOMBE|TOMBE AMOUREUSE|TOMBE AMOUREUX|TOMBEAU|TOMBEAUX|TOMBEE|',
  'TOMBEE AMOUREUSE|TOMBEE DE LA NUIT|TOMBEE DU JOUR|TOMBER|TOMBER AMOUREUSE|TOMBER AMOUREUX|TONNERRE|TONNERRES|TORNADE|TORNADES|TORRENT|TORRENTS|TORTUE|TORTUE DE MER|TORTUES|TOTALEMENT|TOUBIB|',
  'TOUJOURS LE MEME REVE|TOUPIE|TOUR D IVOIRE|TOUR DE MAGIE|TOUR EIFFEL|TOURELLE|TOURELLES|TOURMENT*|TOURNER EN ROND|TOURTERELLE*|TOUT NU|TOUT PUISSANT|TOUT SEUL|TOUTE NUE|TOUTE SEULE|TOUTOU|TOUTOUS|',
  'TOXIQUE|TOXIQUES|TRAIN PART SANS MOI|TRAINS|TRAMWAY|TRANCHEE|TRANCHEES|TRANQUILL*|TRANSE|TRANSFORMAIT|TRANSFORMATION|TRANSFORME|TRANSFORMEE|TRAQUAIT|TRAQUE|TRAQUEE|TRAVAIL|TRAVAILLAIENT|TRAVAILLAIS|',
  'TRAVAILLAIT|TRAVAILLANT|TRAVAILLE|TRAVAILLER|TRAVESTI|TRAVESTIE|TREILLIS|TREIZE|TREIZIEME|TREMBLAIS|TREMBLANT|TREMBLANTE|TREMBLANTS|TREMBLEMENT DE TERRE|TREMBLEMENTS DE TERRE|TRENCH|TREPAS|TREPASSE|',
  'TREPASSEE|TREPASSES|TRES|TRESOR|TRESOR CACHE|TRESORS|TRESSE|TRESSES|TRICERATOPS|TRIO|TRIOMPH*|TRISTE|TRISTEMENT|TRISTES|TRISTESSE|TROIS|TROISIEME|TROISIEME AGE|TROISIEMES|TRONC|TRONCS|TROP|TROP TARD|',
  'TROTTOIR|TROTTOIRS|TROU DE SERRURE|TROUPEAU*|TROUSSEAU|TROUSSEAU DE CLES|TROUVA|TROUVAI|TROUVE|TROUVEE|TROUVER|TROUVES|TRUIE*|TRUITE*|TSUNAMI|TUAIS|TUAIT|TUE|TUEE|TUER|TUES|TUILE|TUILES|TULIPE|',
  'TULIPES|TUNNEL|TUNNELS|TURQUOISE|TYMPAN|TYRANNOSAURE*|UN TRAIN|UNE MONTRE|UNE PORTE|UNE TOUR|UNIFORME|UNIFORMES|UNIVERS|UNIVERSITE|URGENCES|URINOIR|VACHE|VACHES|VAGUE|VAGUES|VAL|VALISE|VALISES|VALLEE|',
  'VALLEES|VALLON|VALLONS|VALSE|VAMPIRE|VAMPIRES|VAMPIRISE|VAMPIRISEE|VAUTOUR*|VEAU|VEAUX|VEDETTE|VEDETTES|VEILLEE FUNEBRE|VELO|VELOCIRAPTOR*|VELOS|VEND|VENDAIENT|VENDAIS|VENDAIT|VENDANT|VENDEUR|',
  'VENDEUSE|VENDIT|VENDRE|VENDREDI 13|VENDS|VENDU|VENDUE|VENIMEUSE|VENIMEUX|VENIN|VENT|VENTE|VENTES|VENTEUX|VENTRE|VENTRES|VENTS|VER|VER DE TERRE|VERDATRE|VERDOYANT|VERDOYANTE|VERGER|VERGERS|VERGLAS|',
  'VERMILLON|VERMISSEAU*|VERNIS A ONGLES|VERRE BRISE|VERRE CASSE|VERRE DE LAIT|VERROU|VERROUS|VERS DE TERRE|VERT|VERTE|VERTEBRE|VERTEBRES|VERTES|VERTS|VESTE|VESTES|VESTIBULE|VESTIBULES|VESTIGES|VETEMENT|',
  'VETEMENT SALE|VETEMENTS|VETEMENTS DECHIRES|VETEMENTS SALES|VETEMENTS TACHES|VETEMENTS TROUES|VEXE|VEXEE|VEXEES|VEXES|VIADUC|VIANDE|VIANDES|VIE ANTERIEURE|VIEIL HOMME|VIEILLARD|VIEILLARDS|VIEILLE DAME|',
  'VIEILLE FEMME|VIEILLESSE|VIEILLI|VIEILLIE|VIEILLIR|VIEILLIS|VIEILLISSAIT|VIEILLISSEMENT|VIEILLIT|VIES ANTERIEURES|VIEUX MONSIEUR|VILLA|VILLAGE|VILLAGE NATAL|VILLAGES|VILLE|VILLES|VIN|VINS|VIOLET|',
  'VIOLETS|VIOLETTE|VIOLETTES|VIPERE*|VIRE|VIRUS|VISAGE|VISAGES|VISIOCONFERENCE|VITRE|VITRE BRISEE|VITRE CASSEE|VITRES|VITRES BRISEES|VODKA|VOIE FERREE|VOIE LACTEE|VOILE DE LA MARIEE|VOILE DE MARIEE|',
  'VOILIER|VOISIN|VOISINAGE|VOISINE|VOISINES|VOISINS|VOITURE|VOITURE MINIATURE|VOITURES|VOIX|VOL A MAIN ARMEE|VOLA|VOLAIENT|VOLAIS|VOLAIT|VOLCAN|VOLCANIQUE|VOLCANS|VOLER|VOLET|VOLETS|VOLEUR|VOLEURS|',
  'VOLEUSE|VOLEUSES|VOLIERE|VOMI|VOMIE|VOMIR|VOMIS|VOMISSAIENT|VOMISSAIS|VOMISSAIT|VOMISSANT|VOMISSEMENT|VOMISSEMENTS|VOMIT|VOUTE CELESTE|VOYAGE DANS LE TEMPS|VOYAGEAIS DANS LE TEMPS|',
  'VOYAGER DANS LE TEMPS|VOYAGES DANS LE TEMPS|VOYAGEUR TEMPOREL|VOYAIS PLUS|VOYAIS RIEN|VOYANT|VOYANTE|VOYANTES|VRAIMENT|VTC|VTT|WAGON|WAGONS|WC|WHISKY|WYVERNE*|YACHT|YEUX|YOGA|ZEN|ZOMBI|ZOMBIE|ZOMBIES|',
  'ZOMBIS|ZOO|1|10|10TH|12|13|13TH|1ST|2|2ND|3|3RD|4|4TH|5|5TH|6|6TH|7|7TH|8|8TH|9|9TH|A FLY|ABANDONMENT|ABBEY|ABDOMEN|ABDUCT|ABDUCTED|ABDUCTION|ABDUCTOR|ABSOLUTELY|ACCIDENT|ACCIDENTS|ACTOR|ACTORS|',
  'ACTRESS|ADDER|ADDERS|ADMIRATION|ADMIRE|ADMIRED|ADMIRING|ADORABLE|ADORE|ADORED|ADORING|ADULTERY|ADVERSARY|AEROPLANE|AFFAIR|AFFECTION*|AFRAID|AFTERLIFE|AGEING|AGING|AGITATED|AGITATION|AGONY|AGREEMENT|',
  'AIR RAID|AIRCRAFT|AIRPLANE|AIRPLANES|AIRPORT|AIRPORTS|AJAR|ALARM|ALARM BELL|ALARM CLOCK|ALARMS|ALCOHOL|ALERT|ALERTS|ALIEN|ALIENS|ALIMONY|ALL ALONE|ALLEY|ALLEYWAY|ALLIGATOR*|ALMIGHTY|ALTAR|ALTARS|',
  'ALTER EGO|AMAZED|AMAZEMENT|AMAZING|AMAZINGLY|AMBUSH|AMBUSHED|AMEN|ANATOMY|ANDROID|ANDROIDS|ANGEL|ANGELIC|ANGELS|ANGER|ANGERED|ANGRILY|ANGRY|ANIMAL|ANIMALS|ANKLE|ANKLES|ANNOY*|ANORAK*|ANT|ANT COLONY|',
  'ANTHILL*|ANTLER*|ANTS|ANXI*|APARTMENT|APARTMENTS|APE|APES|APOCALYP*|APPARITION|APPLE|APPLE TREE|APPLES|APPLICANT|APPREHENSI*|APRON*|AQUARIUM*|ARCHANGEL|ARCHANGELS|AREN|ARID|ARM|ARMAGEDDON|ARMCHAIR|',
  'ARMS|ARSENIC|ARSON|ASCEND|ASCENDED|ASCENDING|ASCENT|ASHAMED|ASSAILANT|ASSASSIN|ASSASSINATED|ASSAULT|ASSAULTED|ASSEMBLY|ASSOCIATE|ASTONISH*|ASTRAY|ASTROLOGER|ASTRONAUT|ASTRONAUTS|AT EASE|ATE|ATLAS|ATM|',
  'ATTACK|ATTACKED|ATTACKER|ATTACKERS|ATTACKING|ATTACKS|ATTIC|ATTICS|AUCTION|AUNT|AUNTIE|AUNTS|AUTOMATON*|AUTOMOBILE|AUTUMN LEAVES|AVENUE|AWAITED|AWAITING|AWAKENED|AWAKENING|AWARE I WAS DREAMING|',
  'AWARE THAT I WAS DREAMING|AWE|AWED|AWESOME|AWESTRUCK|AWFULLY|AWKWARD*|AWOKE|AZURE|BABIES|BABOON*|BABY|BACK FROM THE DEAD|BACK IN TIME|BACK PAIN|BACKACHE|BACKBONE|BACKPACK|BACKSTAGE|BAG|BAGGAGE|BAGS|',
  'BAGUETTE|BAKER|BAKERY|BALACLAVA|BALD|BALDNESS|BALL|BALLET|BALLOON|BALLOONS|BALLROOM|BANANA|BANANAS|BANDIT|BANDITS|BANK|BANK ACCOUNT|BANK TELLER|BANKER|BANKERS|BANKNOTE*|BANKRUPT|BANKRUPTCY|BANKS|',
  'BANQUET|BANQUETS|BAPTISED|BAPTISM|BAPTIZED|BAR FIGHT|BAREFOOT|BARN OWL|BASEMENT|BASEMENTS|BASILICA|BATH|BATHROOM|BATHROOMS|BATHTUB|BATS|BATTLE|BATTLEFIELD|BATTLES|BATTLING|BEACH|BEACH BALL|BEACHES|',
  'BEAMING|BEANIE*|BEAR|BEAR CUB|BEAR CUBS|BEARD|BEARDED|BEARDS|BEARS|BEAST|BEASTS|BEAT UP|BEATEN UP|BEAUTIFUL|BECAME LUCID|BED|BEDCHAMBER|BEDROOM|BEDROOMS|BEDS|BEDSHEETS|BEE|BEEF|BEEHIVE*|BEEKEEPER*|',
  'BEER|BEERS|BEES|BEETLE*|BEGGAR|BEGGARS|BEGGING|BEHIND SCHEDULE|BELFRY|BELLIES|BELLY|BELOVED|BENCH|BEQUEATHED|BERET*|BEST FRIEND|BICYCLE|BICYCLES|BIKE|BIKER|BIKES|BILLIONAIRE|BILLY GOAT*|BIRD|',
  'BIRD OF PREY|BIRDCAGE|BIRDS|BIRDS OF PREY|BIRTH|BIRTHING|BIRTHS|BISHOP|BISON|BISTRO|BITTER|BITTERNESS|BLACK|BLACK SWAN*|BLACKMAIL|BLACKNESS|BLADE|BLAST|BLAZE|BLED|BLEED|BLEEDING|BLEEDS|BLESS|BLESSED|',
  'BLESSES|BLESSING|BLESSINGS|BLEW UP|BLIND|BLIND DATE|BLINDED|BLINDNESS|BLISS|BLISSFUL|BLIZZARD|BLOOD|BLOODBATH|BLOODSTAIN|BLOODSTAINS|BLOODY|BLOOM|BLOOMING|BLOSSOM|BLOSSOMS|BLOW UP|BLUE|BLUEBOTTLE*|',
  'BLUISH|BOA|BOAR*|BOARD MEETING|BOARDING GATE|BOARDING PASS|BOAT|BOATS|BODIES|BODILY|BODY|BOG|BOGEYMAN|BOGS|BOMB|BOMBING|BOMBINGS|BOMBS|BONE|BONES|BONFIRE|BONNET*|BOOGEYMAN|BOOK|BOOKS|BOOT|BOOTS|BOOTY|',
  'BORDER|BORDER CROSSING|BORDERS|BORN|BORN AGAIN|BOSS|BOSSES|BOTTLE|BOTTLES|BOUGHT|BOULDER|BOULDERS|BOUQUET|BOUTIQUE|BOX|BOXERS|BOXES|BOY|BOYFRIEND|BOYFRIENDS|BOYS|BRA|BRACELET|BRAID|BRAIDS|BRAKE|',
  'BRAKE PEDAL|BRAKES|BRAKING|BRANCH|BRANCHES|BRAS|BRAWL|BRAWLING|BRAWLS|BREAD|BREADS|BREAK IN|BREAK UP|BREAKER|BREAKERS|BREAKING IN|BREAKING UP|BREAKUP|BREAKUPS|BREATHTAKING|BREEZE|BREEZES|BRICK WALL|',
  'BRIDAL DRESS*|BRIDAL GOWN*|BRIDAL VEIL*|BRIDE|BRIDEGROOM|BRIDGE|BRIDGES|BRIEFING|BRIEFS|BRIGHT|BRIGHTNESS|BROKE IN|BROKE UP|BROKEN GLASS|BROKEN WINDOW|BRONTOSAUR*|BROOK|BROOKS|BROTHER|BROTHER IN LAW|',
  'BROTHERS|BROWNIE|BROWNIES|BRUISE|BRUISES|BUDDIES|BUDDY|BUDGIE*|BUFFALO*|BUFFOON|BUG|BUGS|BUILD|BUILDER|BUILDERS|BUILDING|BUILDS|BUILT|BULL|BULLFIGHT*|BULLS|BUMBLEBEE*|BUNNIES|BUNNY|BURGLARIES|',
  'BURGLARIZED|BURGLARY|BURGLED|BURIAL|BURIALS|BURIED|BURIES|BURNED DOWN|BURNING|BURNT DOWN|BURY|BURYING|BUS|BUS DRIVER|BUS STOP|BUSES|BUTCHER|BUTTERFL*|BUY|BUYING|BUYS|CAB|CABBAGE|CABS|CACAO|CADAVER|',
  'CAGE|CAGED|CAGES|CAIMAN*|CAKE|CAKES|CALAMITY|CALF|CALM*|CALVES|CAME ACROSS|CAME BACK TO LIFE|CAME TRUE|CAMERA|CAMINO|CAMPFIRE|CANARIES|CANARY|CANCER|CANDIES|CANDLE|CANDLEHOLDER|CANDLELIGHT|',
  'CANDLELIT DINNER|CANDLES|CANDLESTICK|CANDY|CANOE|CANYON|CANYONS|CAP|CAPE|CAPES|CAPPUCCINO|CAPS|CAPSIZED|CAPTIVE|CAPTIVES|CAPTIVITY|CAPTOR|CAPTORS|CAR|CAR CRASH|CARAMEL|CARCASS|CARCASSES|CARD|CARDIAC|',
  'CARDS|CAREER|CARING|CARP|CARRIAGE|CARROT|CARROTS|CARS|CASCADE|CASCADES|CASH|CASH MACHINE|CASKET|CASKETS|CASTAWAY|CASTLE|CASTLES|CAT|CATACLYSM|CATACOMBS|CATARACT|CATASTROPHE|CATASTROPHES|CATASTROPHIC|',
  'CATERPILLAR*|CATHEDRAL|CATHEDRALS|CATS|CATTLE|CAVE|CAVE IN|CAVED IN|CAVERN|CAVERNS|CAVES|CELEBRATION|CELEBRITIES|CELEBRITY|CELESTIAL|CELLAR|CELLARS|CELLPHONE|CELTIC CROSS|CEMETERIES|CEMETERY|CEO|',
  'CHAIN|CHAIN LINK|CHAINED|CHAINS|CHAIR|CHAIRS|CHAMPAGNE|CHANDELIER|CHAPEL|CHAPELS|CHAPLAIN|CHASE|CHASED|CHASES|CHASING|CHEATED ON|CHEATING ON|CHEATS ON|CHEEK|CHEEKS|CHEER*|CHEETAH*|CHERISH*|CHERRIES|',
  'CHERRY|CHERUB|CHERUBIM|CHERUBS|CHICK|CHICKS|CHIEF|CHILD|CHILDBIRTH|CHILDHOOD HOME|CHILDHOOD HOUSE|CHILDREN|CHIMERA*|CHIMP*|CHIN|CHINS|CHOCOLATE|CHOCOLATES|CHOIR|CHOKE|CHOKED|CHOKING|CHRIST|CHRYSALIS|',
  'CHRYSALIS*|CHUCKLED|CHUCKLING|CHURCH|CHURCH SERVICE|CHURCHES|CHURCHYARD|CIRCLE|CIRCLES|CIRCULAR|CISTERN|CISTERNS|CITADEL|CITIES|CITY|CLAIRVOYANT|CLAMBERED|CLASSROOM|CLAUSE|CLAY|CLEAN|CLEANED|CLEANING|',
  'CLIFF|CLIFFS|CLIMB|CLIMBED|CLIMBED DOWN|CLIMBER|CLIMBING|CLIMBING DOWN|CLIMBS|CLINIC|CLOAK*|CLOCK|CLOCKS|CLOTHES|CLOTHING|CLOUD|CLOUDS|CLOUDY|CLOWN|CLOWNS|CO WORKER|CO WORKERS|COAT|COATS|COBRA*|',
  'COBWEB*|COCKEREL*|COCKROACH*|COCOA|COCOON|COCOON*|COFFEE|COFFEES|COFFER|COFFERS|COFFIN|COFFINS|COIN|COINS|COLLAPSE|COLLAPSED|COLLAPSES|COLLAPSING|COLLEAGUE|COLLEAGUES|COLLEGE|COLLIDED|COLLISION|',
  'COLOSSUS|COMBAT|COME BACK TO LIFE|COMFORT*|COMPANY|COMPASS|COMPASSES|COMPASSION*|COMPLETELY|COMPUTER|COMPUTERS|COMRADE|CONCEALED|CONFERENCE|CONFINED|CONJUR*|CONSTELLATION|CONSTELLATIONS|CONSTRUCTED|',
  'CONSTRUCTING|CONSTRUCTION|CONTACT LENS|CONTACT LENSES|CONTEMPT|CONTENTED|CONTENTMENT|CONTRACT|CONTRACTS|CONTROL MY DREAM|CONTROLLED THE DREAM|CONVENT|COP|COPS|CORD|CORONATION|CORPSE|CORPSES|CORRIDOR|',
  'CORRIDORS|COSMOS|COSPLAY|COSTUME|COSTUMES|COTTAGE|COTTON CANDY|COUCH|COUGAR*|COULD NOT GET OUT|COULD NOT MOVE|COULDN|COULDN T GET OUT|COULDN T MOVE|COULDN T SEE|COUSIN|COUSINS|COVEN*|COW|COWORKER|',
  'COWORKERS|COWS|CRASH|CRASHED|CRASHES|CRASHING|CRATER|CRATERS|CRAWLSPACE|CREATURE|CREATURES|CREDITOR*|CREEK|CREEKS|CREEPY|CRIED|CRIED OUT|CRIES|CRIMSON|CRITTER*|CROC|CROCODILE*|CROISSANT|CROOK|CROOKS|',
  'CROP|CROPS|CROSSROAD|CROSSROADS|CROW|CROWD|CROWDED|CROWDS|CROWN|CROWN PRINCE|CROWNED|CROWNS|CROWS|CRUCIFIED|CRUCIFIX|CRUCIFIXES|CRUCIFIXION|CRUISE|CRUMBLE|CRUMBLED|CRUMBLING|CRUSH ON|CRY|CRYING|CRYPT|',
  'CRYSTAL BALL|CUBICLE|CUDDLE|CUDDLED|CUDDLING|CUPCAKE|CUPCAKES|CURIOSITY|CURIOUS|CURIOUSLY|CURTAIN CALL|CUSTODY|CUSTOMS|CV|CYANIDE|CYBORG*|CYCLING|CYCLONE|CYGNET*|DAD|DADDY|DADS|DAGGER|DAGGERS|DAIRY|',
  'DAISY|DALE|DAMNATION|DAMNED|DANCE|DANCED|DANCER|DANCERS|DANCES|DANCING|DANGER|DANGEROUS|DANGERS|DARK|DARKNESS|DARLING|DATING|DAUGHTER|DAUGHTERS|DAWN|DAWNS|DAYBREAK|DAZZL*|DEAD|DEAD BODIES|DEAD BODY|',
  'DEAD FATHER|DEAD GRANDFATHER|DEAD GRANDMOTHER|DEAD LEAVES|DEAD MOTHER|DEADBOLT|DEADLY|DEAF|DEAFNESS|DEAL|DEATH|DEATHBED|DEATHS|DEBT|DEBTS|DECEASED|DECK OF CARDS|DEEP WELL|DEEPLY|DEER|DEITIES|DEITY|',
  'DEJA VU|DEJECTED|DELAY|DELAYED|DELIGHT*|DELUGE|DEMON|DEMONIC|DEMONS|DENTIST|DENTURES|DEPARTED|DEPARTURE LOUNGE|DEPRESS*|DESCEND|DESCENDED|DESCENDING|DESCENT|DESERT|DESERT ISLAND|DESERTS|DESK|',
  'DESKTOP COMPUTER|DESPAIR|DESPAIRED|DESPERATE|DESPERATELY|DESPERATION|DESSERT|DESSERTS|DESTITUTE|DETECTIVE|DETONATION|DEVASTAT*|DEVIL|DEVILS|DEVOTED|DEVOTION|DIABOLICAL|DIADEM|DIAMOND|DIAMONDS|DIDN|',
  'DIE|DIED|DIES|DINER|DINING TABLE|DINO|DINOS|DINOSAUR*|DIRECTOR|DIRTY CLOTHES|DIRTY LAUNDRY|DISASTER|DISASTERS|DISASTROUS|DISCOMFORT|DISCOVER|DISCOVERED|DISCOVERY|DISEASE|DISEASES|DISGUISE*|DISGUST*|',
  'DISMISSED|DISORIENTED|DISTRESS*|DIVE|DIVED|DIVINE|DIVING|DIVING BOARD|DIVINITY|DIVORCE|DIVORCED|DIVORCES|DIVORCING|DOCTOR|DOCTORS|DOESN|DOG|DOGGIE|DOGGY|DOGS|DOLL|DOLLAR BILLS|DOLLARS|DOLLS|DOLPHIN|',
  'DOLPHINS|DON|DOOMSDAY|DOOR|DOORKNOB|DOORS|DOORWAY|DOPPELGANGER|DORMITORY|DOVE|DOVES|DOWNPOUR|DOWNTOWN|DOZEN|DOZENS|DRACULA|DRAGON|DRAGONS|DRANK|DRAWBRIDGE|DREAD|DREADED|DREADFUL|DREADING|',
  'DREAMED IT AGAIN|DREAMT IT AGAIN|DRESS|DRESSED|DRESSED UP AS|DRESSES|DRINK|DRINKING|DRINKS|DRIVE|DRIVER|DRIVING|DRIZZLE|DROVE|DROWN|DROWNED|DROWNING|DROWNS|DRUNK|DUMPED|DUNE|DUNES|DUNGEON|DUSK|DUVET|',
  'DWARF|DWARFS|DWARVES|DYING|DYNAMITE|EAGLE*|EAR|EARDRUM|EARRINGS|EARS|EARTH|EARTHQUAKE|EARTHQUAKES|EARTHWORM*|EAT|EATEN|EATING|EATS|ECLIPSE|ECLIPSED|ECLIPSES|ECSTASY|ECSTATIC|EDEN|EERIE|EGG|EGG YOLK|',
  'EGGS|EGGSHELL|EIGHT|EIGHTH|ELATED|ELATION|ELBOW|ELBOWS|ELDERLY|ELEPHANT|ELEPHANTS|ELEVATOR|ELEVATOR SHAFT|ELEVATORS|ELF|ELK|ELVES|EMBARRASS*|EMBERS|EMBRACE|EMBRACED|EMBRACING|EMERALD|EMERALDS|',
  'EMERGENCY ROOM|EMPEROR|EMPLOYER|EMPLOYMENT|EMPRESS|ENCHANT*|END OF THE WORLD|END TIMES|ENEMIES|ENEMY|ENGAGED|ENGAGEMENT|ENGAGEMENT RING|ENRAGED|ENVELOPE|ENVELOPES|EPIDEMIC|EROTIC|ERUPTING|ERUPTION|',
  'ERUPTIONS|ESCALATOR|ESCAPE|ESCAPED|ESCAPING|ESPRESSO|EUPHORI*|EUROS|EVACUATE|EVACUATED|EVACUATION|EVENING DRESS|EVERY NIGHT|EVIL SPIRIT|EWE|EWES|EX|EX BOYFRIEND|EX GIRLFRIEND|EX HUSBAND|EX PARTNER|',
  'EX WIFE|EXAM|EXAMINATION|EXAMS|EXASPERAT*|EXCIT*|EXES|EXPECTING A BABY|EXPLODE|EXPLODED|EXPLODES|EXPLODING|EXPLOSION|EXPLOSIONS|EXPLOSIVE|EXTRA ROOM|EXTRATERRESTRIAL*|EXTREMELY|EXTREMIST|EXTREMISTS|',
  'EYE|EYEBALL|EYEBALLS|EYEGLASSES|EYELASH|EYELASHES|EYELID|EYELIDS|EYELINER*|EYES|EYESHADOW*|FACE|FACELESS|FACES|FAIRIES|FAIRY|FAIRY GODMOTHER*|FALCON*|FALL|FALL IN LOVE|FALLEN|FALLEN LEAVES|FALLING|',
  'FALLING APART|FALLING IN LOVE|FALSE AWAKENING|FAMILIES|FAMILY|FAMILY HOME|FAMINE|FAMOUS|FANCY DRESS|FARMLAND|FASCINAT*|FATHER|FATHER IN LAW|FATHERS|FAWN*|FEAR|FEARED|FEARFUL|FEARING|FEARS|FEAST|',
  'FEASTING|FEASTS|FEET|FELINE*|FELL|FELL APART|FELL IN LOVE|FERRY|FETTERS|FEVER|FIANCE|FIANCEE|FIELD|FIELDS|FIFTH|FIGHT|FIGHTING|FILM STAR|FINAL EXAM|FINALS|FINANCIAL RUIN|FIND|FINDING|FINGER|',
  'FINGERNAIL|FINGERNAILS|FINGERS|FINGERTIP|FINGERTIPS|FIRE|FIRE ALARM|FIRE BIRD|FIRE ENGINE|FIRE TRUCK|FIREARM|FIREBIRD*|FIRED|FIREFIGHTER|FIREFIGHTERS|FIREMAN|FIREMEN|FIRES|FIRMAMENT|FIRST|FIRST DATE|',
  'FISH|FISHES|FIST|FIST FIGHT|FISTFIGHT|FISTS|FIVE|FLAME|FLAMES|FLAMING|FLASHLIGHT|FLASK|FLEA|FLEAS|FLED|FLEDGLING*|FLEE|FLEEING|FLEW|FLIGHT OF STAIRS|FLIRT|FLIRTATIOUS|FLIRTED|FLIRTING|FLOCK*|FLOOD|',
  'FLOODED|FLOODING|FLOODS|FLOWER|FLOWERS|FLOWN|FLU|FLUNG OPEN|FLYING|FLYING SAUCER|FLYING SAUCERS|FOAL*|FOE|FOES|FOG|FOGGY|FOLIAGE|FOLLOWED ME|FOLLOWING ME|FOND|FONDNESS|FOOD|FOODS|FOOT|FOOTBALL|',
  'FOOTBRIDGE|FOREBODING|FOREHEAD|FOREHEADS|FORESAW|FOREST|FORESTS|FORK IN THE ROAD|FORLORN|FORMER PARTNER|FORTRESS|FORTUNE|FORTUNE TELLER|FOUGHT|FOUND|FOUNTAIN|FOUNTAINS|FOUR|FOURTH|FOX|FOXES|FRANTIC|',
  'FRANTICALLY|FRECKLES|FREEWAY|FRIAR|FRIARS|FRIDGE|FRIEND|FRIENDS|FRIENDSHIP|FRIGHT|FRIGHTEN*|FRIGHTFUL|FROCK*|FROG*|FRONT DOOR|FRONTIER|FROZEN|FROZEN IN PLACE|FRUIT|FRUIT BAT|FRUIT BATS|FRUITS|',
  'FRUSTRAT*|FULFILLED|FULFILLMENT|FULFILMENT|FULL MOON|FUNERAL|FUNERALS|FURIOUS|FURIOUSLY|FURY|GALAXIES|GALAXY|GARDEN|GARDEN OF EDEN|GARDENER|GARDENING|GARDENS|GARMENT*|GARRET|GASH|GATE|GATES|GATOR|',
  'GATORS|GAVE BIRTH|GEM|GEMS|GET LOST|GETAWAY|GETTING LOST|GETTING OLD|GEYSER|GEYSERS|GHOST|GHOSTLY|GHOSTS|GIANT|GIANTESS*|GIANTS|GIDDY|GIFT|GIFT BOX|GIFTS|GIGGLED|GIGGLING|GILDED|GILT|GIRL|GIRLFRIEND|',
  'GIRLFRIENDS|GIRLS|GIVE BIRTH|GIVES BIRTH|GIVING BIRTH|GLACIER|GLACIERS|GLAD|GLADLY|GLADNESS|GLASS OF MILK|GLASS SHARDS|GLASSES|GLIDED|GLIDING|GLOOM|GLOOMY|GLOW|GLOWING|GNAT*|GNOME|GNOMES|GO OUT WITH|',
  'GOAT*|GOBLIN*|GOD|GODDESS|GODDESSES|GODS|GOGGLES|GOING DOWN|GOING IN CIRCLES|GOING UNDER|GOLD|GOLD BAR|GOLD BARS|GOLD COINS|GOLD COLORED|GOLD COLOURED|GOLD RING|GOLDEN|GOLDEN CROSS|GOLDFISH|GOLDMINE|',
  'GORILLA*|GOT LOST|GOWN|GOWNS|GPS|GRANDAD|GRANDFATHER|GRANDFATHERS|GRANDMA|GRANDMOTHER|GRANDMOTHERS|GRANDPA|GRANDPARENTS|GRANNY|GRAPE|GRAPES|GRASS|GRASSES|GRASSHOPPER*|GRASSY|GRATEFUL|GRATITUDE|GRAVE|',
  'GRAVES|GRAVESTONE|GRAVESTONES|GRAVEYARD|GRAVEYARDS|GRAY|GRAY HAIR|GRAYISH|GREAT WHITE|GREAT WHITE SHARK*|GREEN|GREEN LEAVES|GREENISH|GREW OLD|GREY|GREY HAIR|GREYISH|GRIDLOCK|GRIEF|GRIEVE|GRIEVED|',
  'GRIEVING|GRIM REAPER|GRIZZLY*|GROOM|GROSSED OUT|GROTTO|GROTTOES|GROUND|GROVE|GROVES|GROW OLD|GROWING OLD|GRUB|GRUBS|GUARDIAN ANGEL|GUILT|GUILTILY|GUILTY|GUN|GUNFIRE|GUNS|GUNSHOT|GUNSHOTS|GURU|GURUS|',
  'GUST|GUSTS|HADN|HAEMORRHAGE|HAG|HAIR|HAIRCUT|HAIRDO|HAIRS|HALF BROTHER|HALF HUMAN|HALF MAN|HALF SISTER|HALL|HALLWAY|HALLWAYS|HAM|HAMLET|HAMLETS|HAMSTER*|HAND|HANDBAG|HANDGUN|HANDS|HANDWRITING|HAPPIER|',
  'HAPPIEST|HAPPILY|HAPPINESS|HAPPY|HARDLY|HARE|HARES|HARLEQUIN|HARMONIOUS|HARMONY|HARVEST|HARVESTS|HAT|HATE|HATED|HATEFUL|HATING|HATRED|HATS|HAUNTED|HAUNTING|HAWK|HAWKS|HAZARD|HAZARDOUS|HAZE|HAZY|HEAD|',
  'HEAD OVER HEELS|HEADACHE|HEADMASTER|HEADQUARTERS|HEADS|HEADSTONE|HEARSE|HEART|HEART ATTACK|HEARTBEAT|HEARTBEATS|HEARTBREAK|HEARTBREAKING|HEARTBROKEN|HEARTS|HEAVEN|HEAVENLY|HEIFER*|HEIR|HEIRESS|',
  'HEIRLOOM|HEIRS|HEIST|HELD HOSTAGE|HELL|HELLFIRE|HELPLESS|HELPLESSNESS|HEMORRHAGE|HEN|HENHOUSE*|HENS|HER MAJESTY|HERMIT|HID|HIDDEN|HIDDEN DOOR|HIDDEN ROOM|HIDDEN TREASURE|HIDE|HIDE AND SEEK|HIDEOUT|',
  'HIDES|HIDING|HIDING PLACE|HIGH HEELS|HIGH SCHOOL|HIGHWAY|HILL|HILLS|HIRED|HIRING|HIS BACK|HIS MAJESTY|HIVE|HOARD|HOARSE|HOG|HOGS|HOLY WATER|HOME|HOME INVASION|HOMELESS|HOMESICK|HOMICIDE|HONEY|',
  'HONEYBEE*|HONEYCOMB|HONEYED|HONKING|HOPELESS|HOPELESSNESS|HOPPED|HOPPING|HORRIBLE|HORRIF*|HORROR|HORRORS|HORSE|HORSEFL*|HORSES|HOSPITAL|HOSPITALIZED|HOSPITALS|HOSTAGE|HOSTAGE TAKER|HOSTAGES|HOSTEL|',
  'HOSTILE|HOSTILITY|HOT SPRING|HOTEL|HOTEL ROOM|HOTELS|HOUND*|HOURGLASS|HOUSE|HOUSE FIRE|HOUSE WHERE I GREW UP|HOUSEFL*|HOUSES|HOVERED|HOVERING|HUBBY|HUG|HUGGED|HUGGING|HUGS|HUMILIAT*|HUNGER|HUNGRY|',
  'HUNTED|HURRICANE|HURRICANES|HURRIED|HURRY|HURRYING|HUSBAND|HUSBANDS|HYDRA|ICE|ICE CREAM|ICEBERG|ICEBERGS|ICY|ILL|ILLNESS|ILLNESSES|IMAM|IMMENSELY|IMMOBILE|IMP|IMPRISONED|IMPS|IN DANGER|IN HER ARMS|',
  'IN HIS ARMS|IN LAWS|IN THE DARK|INCISOR|INCISORS|INCREDIBLY|INDEBTED|INDIGN*|INFANT|INFANTA|INFANTS|INFECTION|INFERNAL|INFERNO|INFIDELITY|INGOT*|INHERIT|INHERITANCE|INHERITED|INHERITING|INJURED|',
  'INJURIES|INJURY|INN|INSECT*|INSOLVENCY|INSOLVENT|INTENSELY|INTERCOURSE|INTERMENT|INTERNET|INTERSECTION|INTERVIEW|INTERVIEWER|INTERVIEWS|INTIMIDATED|INTIMIDATION|INTO THE FUTURE|INTRIGU*|INTRUDER|',
  'INTRUDERS|INUNDATED|INVADERS|INVASION|INVISIBILITY|INVISIBLE|IRIDESCENT|IRIS|IRON BARS|IRRITA*|ISLAND|ISLANDS|ISLE|ISLES|ISLET|ISN|ISOLATION|JACKET*|JACKPOT|JAGUAR*|JAIL|JAILED|JAW|JAWS|JEALOUS|',
  'JEALOUSY|JESTER|JESTERS|JESUS|JET|JEWEL|JEWELLERY|JEWELRY|JEWELRY BOX|JEWELS|JIHADIST|JIHADISTS|JOB|JOB APPLICATION|JOB INTERVIEW|JOBS|JOGGING|JOY|JOYFUL|JOYFULLY|JOYOUS|JOYS|JUBILA*|JUDGEMENT DAY|',
  'JUDGMENT DAY|JUMP|JUMPED|JUMPING|JUMPS|JUNCTION|JUNGLE|JUNGLES|KARMA|KEEPS COMING BACK|KEY|KEY RING|KEYBOARD|KEYCHAIN|KEYHOLE|KEYS|KID|KID GOAT*|KIDNAP|KIDNAPPED|KIDNAPPER|KIDNAPPERS|KIDNAPPING|KIDS|',
  'KILL|KILLED|KILLER|KILLER WHALE*|KILLING|KILLS|KINDNESS|KING|KINGS|KISS|KISSED|KISSES|KISSING|KITCHEN|KITCHEN TABLE|KITCHENS|KITTEN*|KITTIES|KITTY|KNEE|KNEES|KNEW I WAS DREAMING|KNICKERS|KNIFE|KNIVES|',
  'KNOT|KNOTS|LAB COAT*|LABYRINTH|LABYRINTHS|LADDER|LADDERS|LADYBIRD*|LADYBUG*|LAGOON|LAGOONS|LAID OFF|LAKE|LAKES|LAMB|LAMBS|LAMP|LAMPS|LANDSLIDE|LANTERN|LANTERNS|LAPTOP|LARVA|LARVAE|LASSO|LATE|',
  'LATE FATHER|LATE GRANDFATHER|LATE GRANDMOTHER|LATE HUSBAND|LATE MOTHER|LATE WIFE|LAUGH|LAUGHED|LAUGHING|LAUGHS|LAUGHTER|LAVA|LAVATORY|LAWN|LAWNS|LAYOFF*|LEAF|LEAP|LEAPED|LEAPING|LEAPT|LEFT ME|LEG|',
  'LEGACY|LEGS|LEOPARD*|LEPRECHAUN*|LET GO|LETTER|LETTERS|LETTUCE|LEVITAT*|LIBERATED|LIBERATION|LIBRARY|LIFELESS|LIFTS|LIGHT|LIGHT BULB|LIGHTBULB|LIGHTNING|LIGHTS|LILAC|LILY|LINGERIE|LION|LION CUB|',
  'LION CUBS|LIONESS*|LIONS|LIP|LIPS|LIPSTICK*|LIQUOR|LIVID|LIVING DEAD|LOAF|LOAFER*|LOAN|LOANS|LOAVES|LOCK|LOCKED IN|LOCKED INSIDE|LOCKED UP|LOCKS|LOCOMOTIVE|LOCUST*|LOFT|LOLLIPOP|LOLLIPOPS|LONELINESS|',
  'LONELY|LONESOME|LOO|LOOKALIKE|LOOKED FOR|LOOKING FOR|LOOKING GLASS|LOOSE CHANGE|LOOT|LOSE|LOSES|LOSING|LOSS|LOST|LOST EVERYTHING|LOST MY JOB|LOST MY WAY|LOTTERY|LOVE|LOVE AT FIRST SIGHT|LOVED|LOVER|',
  'LOVERS|LOVING|LOVINGLY|LUCID|LUCID DREAM|LUCID DREAMING|LUCID DREAMS|LUCIFER|LUGGAGE|LUXURIOUS|LUXURY|LYCANTHROP*|MACHINE GUN|MADE LOVE|MADE REDUNDANT|MAGGOT*|MAGIC|MAGIC WAND|MAGICAL|MAGICIAN*|MAGMA|',
  'MAGNETIC NORTH|MAGNIFICENT|MAIL|MAILBOX|MAKE LOVE|MAKE UP|MAKEUP|MAKING LOVE|MALL|MAMMOTH|MAMMOTHS|MANAGER|MANDALA|MANDALAS|MANICURE|MANOR|MANSION|MANTRA|MAP|MAPS|MARE|MARES|MARIONETTE|MARRIAGE|',
  'MARRIAGE PROPOSAL|MARRIED|MARRY|MARRYING|MARSHMALLOW|MARTIAN|MARTIANS|MARVEL*|MASCARA*|MASK|MASKED|MASKS|MASQUERADE|MASQUERADE*|MASSES|MATTRESS|MAUSOLEUM|MAUVE|MAZE|MAZES|MEADOW|MEADOWS|MEAL|MEALS|',
  'MEAT|MEATS|MECCA|MEDIC|MEDITATE|MEDITATED|MEDITATES|MEDITATING|MEDITATION|MEETING|MEETINGS|MELANCHOL*|MENACE|MENACING|MERFOLK|MERMAID*|MERMAN|MERMEN|MESMERI*|MESSAGE IN A BOTTLE|METAMORPHOSED|',
  'METAMORPHOSIS|METRO|METROPOLIS|MICE|MIDNIGHT|MILITARY|MILK|MILKY|MILKY WAY|MILLIONAIRE|MINDFULNESS|MIRACLE|MIRACLES|MIRACULOUS|MIRACULOUSLY|MIRE|MIRROR|MIRRORS|MISERABLE|MISERY|MISPLACED|',
  'MISS MY FLIGHT|MISS THE PLANE|MISS THE TRAIN|MISSED MY FLIGHT|MISSED MY TRAIN|MISSED THE BOAT|MISSED THE BUS|MISSED THE PLANE|MISSED THE TRAIN|MISSUS|MIST|MISTRESS|MISTRESSES|MISTY|MOB|MOLAR|MOLARS|',
  'MOLD|MOLDY|MOM|MOMMY|MOMS|MONARCH|MONARCHS|MONASTERIES|MONASTERY|MONEY|MONK|MONKEY*|MONKS|MONOCLE*|MONSTER|MONSTERS|MONSTROUS|MOON|MOONLIGHT|MOONLIT|MOONS|MOOSE|MOPPING|MORGUE|MORTAL|MORTGAGE|',
  'MORTIFIED|MOSQUE|MOSQUES|MOSQUITO*|MOTEL|MOTH|MOTHER|MOTHER IN LAW|MOTHERS|MOTHS|MOTORBIKE|MOTORBIKES|MOTORCYCLE|MOTORCYCLES|MOTORWAY|MOULD|MOULDY|MOUNTAIN|MOUNTAINS|MOURNERS|MOURNING|MOUSE|',
  'MOUSETRAP*|MOUSTACHE|MOUTH|MOUTHS|MOVED HOUSE|MOVED IN|MOVED OUT|MOVED TO TEARS|MOVERS|MOVIE STAR|MOVING BOXES|MOVING HOUSE|MOVING IN|MOVING OUT|MOVING VAN|MUD|MUDDY|MUGGED|MULTITUDE|MUM|MUMS|MURDER|',
  'MURDERED|MURDERER|MURDERING|MURDERS|MUSTACHE|MUSTANG*|MUTANT|MUTANTS|MUTATED|MUTATION|MUTE|MUTT|MY BACK|MY DOUBLE|MY PARENTS HOUSE|MY ROOM|MY WATCH|NAIL|NAIL POLISH|NAILS|NAKED|NAKEDNESS|NANNY GOAT*|',
  'NATURAL DISASTER|NAUSEA|NAVEL|NAVY BLUE|NECK|NECKLACE|NECKS|NECROPOLIS|NECTAR|NEIGHBOR|NEIGHBORS|NEIGHBOUR|NEIGHBOURS|NEMESIS|NEPHEW|NERVOUS*|NEVER|NEW ROOM|NEWBORN|NEWBORNS|NEWLYWEDS|NIECE|NIGHT|',
  'NIGHTINGALE*|NIGHTMARE|NIGHTMARES|NIGHTMARISH|NIGHTS|NIGHTTIME|NINE|NINTH|NIRVANA|NO|NO ONE COULD SEE ME|NO WAY OUT|NOBODY COULD SEE ME|NOCTURNAL|NOOSE|NOR|NOSE|NOSEBLEED|NOSES|NOSTALGI*|NOSTRIL|',
  'NOSTRILS|NOT|NOTARY|NOVEL|NOVELS|NUDE|NUDITY|NUGGET*|NUMBER ONE|NUN|NUNS|NURSE|NURSES|OAK|OAKS|OCEAN|OCEANS|OFFERING|OFFERINGS|OFFICE|OFFICES|OGRE|OGRES|OLD AGE|OLD HOUSE|OLD LADY|OLD MAN|OLD MEN|',
  'OLD WELL|OLD WOMAN|OLD WOMEN|OMELET|OMELETTE|OMEN|OMENS|OMINOUS|ON A DATE|ON EDGE|ON FIRE|ONION|ONIONS|ONSTAGE|OPEN|OPEN PLAN|OPEN SEA|OPENED|OPENING|OPENS|OPPONENT|ORAL EXAM|ORANGE|ORANGES|ORANGISH|',
  'ORANGUTAN*|ORCA*|ORCHARD|ORCHARDS|ORCHID|ORGASM|OUT OF BODY|OUTER SPACE|OUTFIT*|OUTRAGE*|OVEN|OVER AND OVER|OVERALLS|OVERCAST|OVERCOAT*|OVERJOYED|OVERWHELMINGLY|OWE|OWED|OWING|OWL|OWLET*|OWLS|OX|OXEN|',
  'PACKING|PACT|PADLOCK|PADLOCKS|PAGODA|PAID|PAIR|PAL|PALACE|PALACES|PALM READER|PALS|PANIC|PANICKED|PANICKING|PANICKY|PANTHER*|PANTIES|PAPA|PARADISE|PARALY*|PARAMOUR|PARASOL|PARASOLS|PARENT|PARENTAL|',
  'PARENTING|PARENTS|PARENTS HOUSE|PARISH|PARK|PARKA*|PARKS|PARROT*|PARTIES|PARTNER|PARTNERS|PARTY|PASS AWAY|PASSAGEWAY|PASSED AWAY|PASSING AWAY|PASSPORT|PASSPORTS|PAST LIFE|PAST LIVES|PASTOR|PASTRIES|',
  'PASTRY|PASTURE|PASTURES|PATH|PATHS|PAVEMENT|PAY|PAYING|PEACE*|PEACH|PEACHES|PEACOCK*|PEAFOWL|PEAHEN*|PEAK|PEAKS|PEAR|PEARL|PEARLS|PEARLY GATES|PEARS|PEBBLE|PEBBLES|PEDALING|PEDALLING|PENDANT|PENNIES|',
  'PENNILESS|PENNY|PERIL|PERILOUS|PERISH|PERISHED|PETAL|PETALS|PETRIFIED|PHANTOM|PHANTOMS|PHOENIX|PHOENIXES|PHONE|PHONE CALL|PHONES|PHOTO|PHOTOCOPIER|PHOTOGRAPH|PHOTOGRAPHS|PHOTOS|PHYSICIAN|PHYSIQUE|',
  'PICKPOCKET|PICTURE|PICTURES|PIE|PIES|PIG|PIGEON*|PIGGY BANK|PIGLET*|PIGS|PILEUP|PILGRIM|PILGRIMAGE|PILGRIMAGES|PILGRIMS|PILLOW|PILLOWS|PINE|PINES|PISTOL|PISTOLS|PITCH BLACK|PIXIE*|PLANE|PLANE TICKET|',
  'PLANES|PLANET|PLANETS|PLATFORM|PLATFORMS|PLAYING CARDS|PLEASED|PLEASURE|PLUMMET*|PLUNGED|PLUNGING|PLUSH TOY|POCKET WATCH|POCKETKNIFE|POISON|POISONED|POISONING|POISONOUS|POISONS|POLICE|POLICE OFFICER|',
  'POLICEMAN|POLICEMEN|POLICEWOMAN|POLTERGEIST|POND|PONDS|PONIES|PONY|POOCH|POOL|POOLS|POOLSIDE|POOR|POPE|POPPED THE QUESTION|PORPOISE|PORPOISES|PORTRAIT|POSSESSED|POSTMAN|POTATO|POTATOES|POVERTY|',
  'PRAIRIE|PRAY|PRAYED|PRAYER|PRAYERS|PRAYING|PRAYS|PRECIPICE|PREDICTED|PREDICTION|PREGNANCIES|PREGNANCY|PREGNANT|PREMONITION*|PREMONITORY|PRESENTATION|PRESENTS|PRIDE|PRIEST|PRIESTS|PRINCE|',
  'PRINCE CHARMING|PRINCES|PRINCESS|PRINCESSES|PRISON|PRISONER|PRISONERS|PRISONS|PROFESSOR|PROFESSORS|PROPHECY|PROPHETIC|PROPOSED TO HER|PROPOSED TO ME|PROUD|PROUDLY|PSYCHIC|PSYCHICS|PTERODACTYL*|PUDDLE|',
  'PUDDLES|PUKE|PUKED|PUMA|PUNCHED|PUP|PUPPET|PUPPETS|PUPPIES|PUPPY|PURCHASE|PURCHASED|PURCHASING|PURPLE|PURSE|PURSUED|PURSUER*|PURSUING|PUSSYCAT*|PYTHON*|QUAGMIRE|QUAKE|QUAKES|QUEEN|QUEENS|QUEUE|',
  'QUEUEING|QUEUING|QUIZ|RABBI|RABBIT*|RACE|RACED|RACING|RADIANT|RAGE|RAGED|RAGGED CLOTHES|RAGING|RAGS|RAILROAD|RAILWAY|RAILWAY STATION|RAIN|RAINBOW|RAINBOWS|RAINCOAT*|RAINDROP|RAINDROPS|RAINED|RAINING|',
  'RAINS|RAINY|RAM|RAMPART|RAMPARTS|RAMS|RAN|RAN AWAY|RANCID|RANSOM|RAPTOR|RAPTORS|RASH|RAT|RATS|RATTLESNAKE*|RAVEN*|RAVINE|RAVINES|READING|REALISED I WAS DREAMING|REALIZED I WAS DREAMING|REALLY|REAPER|',
  'REASSUR*|REBIRTH|REBORN|RECRUITER|RECURRENT|RECURRENT DREAM|RECURRING|RECURRING DREAM|RED|REDDISH|REDS|REDUNDANCY|REFLECTION|REFLECTIONS|REFRIGERATOR|REGRET|REGRETFUL|REGRETS|REGRETTED|REINCARNATED|',
  'REINCARNATION|REINDEER*|RELATIONSHIP|RELATIVES|RELAX*|RELIEF|RELIEVED|RELOCATED|RELOCATING|RELOCATION|REMORSE|REMORSEFUL|RENDEZVOUS|REPAID|REPAY|REPUGNANT|REPULSED|REPULSIVE|RESENT*|RESTAURANT|',
  'RESTAURANTS|RESTLESS|RESTROOM|RESURRECT|RESURRECTED|RESURRECTION|REVEREND|REVOLTING|REVOLVER|REVULSION|RICH|RICHES|RIDICULE|RIDICULED|RIDICULOUS|RIFLE|RIFLES|RING|RINGS|RISING FROM THE ASHES|RISKY|',
  'RIVAL|RIVALS|RIVER|RIVERBANK|RIVERS|ROACH|ROACHES|ROAD|ROADS|ROBBED|ROBBER|ROBBERS|ROBBERY|ROBOT*|ROCK|ROCK STAR|ROCKS|ROCKY|RODENT*|ROMANTIC DINNER|ROOF|ROOF TILES|ROOFS|ROOFTOP|ROOFTOPS|ROOK|ROOKS|',
  'ROOSTER*|ROOT|ROOTED|ROOTED TO THE SPOT|ROOTS|ROPE|ROPES|ROSARY|ROSE|ROSE FROM THE ASHES|ROSE FROM THE DEAD|ROSE GARDEN|ROSEBUSH|ROSEBUSHES|ROSES|ROTTEN|ROTTING|ROUNDABOUT|ROYAL PALACE|RUBBLE|',
  'RUCKSACK|RUIN|RUINED|RUINS|RUMMAGING|RUN|RUN AWAY|RUNG|RUNGS|RUNNING|RUNNING AWAY|RUNNING LATE|RUNS|RUNWAY|RUSH HOUR|SABER|SABRE|SACKED|SACRIFICE|SACRIFICED|SACRIFICIAL|SAD|SADDENED|SADLY|SADNESS|',
  'SAFELY|SAFETY|SAHARA|SAILBOAT|SALARY|SALE|SALESMAN|SALT|SALTED|SALTS|SALTY|SAME DREAM|SANCTUARY|SAND|SANDAL*|SANDS|SANDY|SANG|SARCOPHAGUS|SATAN|SAUSAGE|SAUSAGES|SCAR|SCARE|SCARED|SCARES|SCARLET|',
  'SCARRED|SCARRING|SCARS|SCARY|SCEPTRE|SCHOOL|SCHOOL BUS|SCHOOLS|SCHOOLTEACHER|SCHOOLYARD|SCIMITAR|SCOOTER|SCORPION|SCORPIONS|SCREAM|SCREAMED|SCREAMING|SCREEN|SCRIBBLED|SCRIBBLING|SCRUBBED|SCRUBBING|',
  'SCRUBS|SCUFFLE|SCUFFLES|SEA|SEA NYMPH*|SEABED|SEARCH|SEARCHED|SEARCHING|SEAS|SEASHORE|SEASIDE|SECOND|SECRET PASSAGE|SECRET ROOM|SECURE|SECURITY|SEDUCE|SEDUCED|SEDUCING|SEDUCTION|SEDUCTIVE|SEEK|',
  'SEEKING|SEER|SELF CONSCIOUS|SELL|SELLER|SELLING|SELLS|SEMINAR|SEPARATED|SEPARATION|SEPULCHRE|SERAPH|SERENE|SERENITY|SERGEANT|SERPENT*|SEVEN|SEVENTH|SEWER RAT|SEWER RATS|SEX|SEXTANT|SEXUAL|SEXUALITY|',
  'SEXY|SHACKLES|SHAMAN|SHAMANS|SHAME|SHAMED|SHAMEFUL|SHAPESHIFTING|SHARD|SHARDS|SHARK|SHARKS|SHATTERED GLASS|SHAVE|SHAVED|SHAVING|SHEATH|SHEEP|SHEEPISH|SHERIFF|SHINING|SHIP|SHIPS|SHIPWRECK|SHIPWRECKED|',
  'SHIRT|SHIRTS|SHOE|SHOES|SHOOTING STAR|SHOP|SHOPPING|SHOPS|SHORE|SHORES|SHOTGUN|SHOULDER|SHOULDER BLADE|SHOULDER BLADES|SHOULDERS|SHOUT|SHOUTED|SHOUTING|SHOWER|SHOWERS|SHRIEK*|SHRINE|SHRINES|SHUT IN|',
  'SHUTTERS|SICK|SICKENED|SICKNESS|SIDEWALK|SIGN OF THE CROSS|SIGNATURE|SIGNED|SIGNET RING|SIGNING|SILVER COINS|SING|SINGER|SINGING|SINISTER|SINKING SHIP|SIP|SIPPING|SISTER|SISTER IN LAW|SISTERS|SIX|',
  'SIXTH|SKELETAL|SKELETON|SKELETON KEY|SKELETONS|SKIES|SKIN|SKINS|SKIRT|SKIRTS|SKULL|SKULLS|SKY|SKYLIGHT|SKYSCRAPER|SKYSCRAPERS|SLAUGHTERED|SLEPT WITH|SLIPPER*|SLUDGE|SLUG|SLUGS|SLUM|SLUMS|SMALL CHANGE|',
  'SMALL TOWN|SMARTPHONE|SMASHED WINDOW|SMITTEN|SMOKE|SMOKE DETECTOR|SMOKED|SMOKER|SMOKING|SMOKY|SMOOCH|SNAIL*|SNAKE*|SNEAKER*|SNOW|SNOWED|SNOWFLAKE|SNOWFLAKES|SNOWING|SNOWMAN|SNOWY|SNUGGLED|SO|SOARED|',
  'SOARING|SOBBED|SOBBING|SOCCER BALL|SOFA|SOIL|SOILS|SOLD|SOLDIER|SOLDIERS|SOLID GOLD|SOMBRERO*|SON|SONG|SONGBIRD*|SONGS|SONS|SOOTHE|SOOTHED|SOOTHING|SORCERER*|SORCERESS*|SORCERY|SORROW*|SOUGHT|SOUL|',
  'SOUL MATE|SOULMATE|SOULS|SPACE|SPARROW*|SPECTACLES|SPECTER|SPECTRE|SPEECHLESS|SPELL|SPELLBOUND|SPELLS|SPERM WHALE*|SPIDER*|SPIDERWEB*|SPINE|SPIRAL|SPIRALS|SPIRIT|SPIRIT GUIDE|SPIRITS|SPIRITUAL GUIDE|',
  'SPIRITUAL MASTER|SPLENDID|SPLIT UP|SPOILED|SPOILT|SPOOKED|SPOOKY|SPOTLIGHT|SPOUSE|SPRING WATER|SPRINTED|SPRINTING|STAG*|STAGE|STAINED CLOTHES|STAIRCASE|STAIRS|STAIRWAY|STAIRWELL|STALKED|STALKING|',
  'STALLION*|STAR|STARLIGHT|STARRY|STARS|STARVATION|STARVED|STARVING|STATION|STEAK|STEAKS|STEED*|STEPBROTHER|STEPFATHER|STEPLADDER|STEPS|STEPSISTER|STINGER|STINGERS|STOLEN|STOMACH|STOMACHS|STONE|STONES|',
  'STOOL|STORE|STORES|STORM|STORMS|STORMY|STOVE|STRANGE BEING|STRANGER|STRANGERS|STRAWBERRIES|STRAWBERRY|STREAM|STREAMS|STREET|STREET FIGHT|STREETS|STRESS*|STRING|STRONGBOX|STRUGGLED WITH|',
  'STUCK IN TRAFFIC|STUCK INSIDE|STUFFED ANIMAL|STUMBLED UPON|STUMP|STUMPS|SUBLIME|SUBURB|SUBURBS|SUBWAY|SUBWAY STATION|SUICIDE BOMBER|SUIT|SUITCASE|SUITCASES|SUMMIT|SUMMITS|SUN|SUNDOWN|SUNG|SUNGLASSES|',
  'SUNLIGHT|SUNNY|SUNRISE|SUNRISES|SUNS|SUNSET|SUNSETS|SUNSHINE|SUPER HERO|SUPER POWER|SUPER POWERS|SUPERHERO*|SUPERHUMAN*|SUPERMARKET|SUPERPOWER*|SUPERVISOR|SURGEON|SURGEONS|SURPRIS*|SWAM|SWAMP|SWAMPS|',
  'SWAN|SWANS|SWARM OF FLIES|SWARM*|SWEATER*|SWEEPING|SWEETHEART|SWEETS|SWEPT|SWIM|SWIMMER|SWIMMING|SWIMMING POOL|SWIMS|SWINE|SWORD|SWORDS|SWUM|SWUNG OPEN|SYNAGOGUE|SYNAGOGUES|T REX|TABLE|TABLECLOTH|',
  'TABLES|TADPOLE*|TAKEOFF|TANGERINE|TARANTULA*|TAROT|TART|TARTS|TASTE BUDS|TATTERS|TAXI|TAXI DRIVER|TAXIS|TEA|TEACHER|TEACHERS|TEAMMATE*|TEAPOT|TEARS|TEDDY|TEDDY BEAR|TEETH|TELEKINESIS|TELEPHONE|',
  'TELEVISION|TELLY|TEMPLE|TEMPLES|TEN|TENDERLY|TENDERNESS|TENSE|TENSION|TENTH|TERMINAL|TERMITE*|TERRAPIN*|TERRIBLY|TERRIFI*|TERROR|TERROR ATTACK|TERRORISM|TERRORIST|TERRORIST ATTACK|TERRORISTS|TERRORS|',
  'TEST|TESTAMENT|TESTS|TEXT MESSAGE|THAT DREAM AGAIN|THE FLIES|THE LIFT|THEATER|THEATRE|THIEF|THIEVES|THIGH|THIGHS|THIRD|THIRST|THIRSTY|THIRTEEN|THIRTEENTH|THIS DREAM AGAIN|THONG*|THREAT|THREATEN|',
  'THREATENED|THREATENING|THREATENS|THREATS|THREE|THRESHOLD|THREW UP|THRILL*|THROAT|THROATS|THRONE ROOM|THRONG|THROW UP|THROWING UP|THUMB|THUMBS|THUNDER|THUNDERBOLT|THUNDERSTORM|THUNDERSTORMS|TIARA|',
  'TICKET|TICKETS|TIDAL WAVE|TIDE|TIDES|TIDIED|TIDYING|TIGER*|TIGRESS*|TIME LOOP*|TIME MACHINE*|TIME TRAVEL*|TIME TRAVELER*|TIME TRAVELLER*|TINKERBELL|TITAN|TITANS|TOAD*|TODDLER|TOE|TOENAIL|TOENAILS|',
  'TOES|TOFFEE|TOILET|TOILETS|TOMATO|TOMATOES|TOMB|TOMBS|TOMBSTONE|TOMBSTONES|TOMCAT*|TONGUE|TONGUE TIED|TONGUES|TOO|TOO LATE|TOOTH|TOP HAT|TORCH|TORN CLOTHES|TORNADO|TORNADOES|TORTOISE*|TOTALLY|TOWER|',
  'TOWERS|TOWN|TOWNS|TOXIC|TOXIN|TOXINS|TOY|TOYS|TRAFFIC|TRAFFIC JAM|TRAFFIC JAMS|TRAIL|TRAIN|TRAIN STATION|TRAIN TICKET|TRAINERS|TRAINS|TRAM|TRANCE|TRANQUIL*|TRANSFORM|TRANSFORMATION|TRANSFORMED|',
  'TRANSFORMING|TRAPPED|TREASURE|TREASURE CHEST|TREASURE HUNT|TREASURE MAP|TREASURES|TREE|TREES|TREMBLING|TREMOR|TREMORS|TRENCHES|TRICERATOPS|TRIO|TRIPLE|TRIUMPH*|TROOPS|TROUSERS|TROUT|TRUE NORTH|TRULY|',
  'TRUNK|TSUNAMI|TULIP|TULIPS|TUMBLED|TUMBLING|TUMMY|TUNNEL|TUNNEL EXIT|TUNNELS|TURNED INTO|TURNING INTO|TURQUOISE|TURRET|TURTLE*|TURTLEDOVE*|TUTOR|TV|TV SHOW|TWELFTH|TWELVE|TWICE|TWILIGHT|TWIN|TWINS|',
  'TWO|TYPHOON|TYRANNOSAUR*|UFO|UFOS|ULTRASOUND|UMBRELLA|UMBRELLAS|UNABLE TO MOVE|UNBURDENED|UNCLE|UNCLES|UNCOMFORTABLE|UNDEAD|UNDERGROUND|UNDERPANTS|UNDERPASS|UNDERWATER|UNDERWEAR|UNDERWORLD|UNDRESSED|',
  'UNEARTHED|UNEASE|UNEASINESS|UNEASY|UNEMPLOYED|UNEMPLOYMENT|UNFAITHFUL|UNHAPPINESS|UNHAPPY|UNICORN|UNICORN HORN|UNICORNS|UNIFORM|UNIFORMS|UNIVERSE|UNIVERSITY|UNKNOWN MAN|UNKNOWN PERSON|UNKNOWN ROOM|',
  'UNKNOWN WOMAN|UNSAFE|UPROOTED|UPSET|URINAL|UTTERLY|VALLEY|VALLEYS|VAMPIRE|VAMPIRE BAT|VAMPIRE BATS|VAMPIRES|VAMPYRE|VAULT|VEGETABLE|VEGETABLES|VEGGIES|VELOCIRAPTOR*|VENDOR|VENOM|VENOMOUS|VERY|VIADUCT|',
  'VIAL|VICAR|VILLAGE|VILLAGES|VIOLET|VIOLETS|VIPER*|VIRUS|VIXEN|VODKA|VOICE|VOICELESS|VOICES|VOLCANIC|VOLCANO|VOLCANOES|VOMIT|VOMITED|VOMITING|VOMITS|VULTURE*|WAD OF CASH|WAIT|WAITED|WAITER|WAITING|',
  'WAITING ROOM|WAITRESS|WAITS|WAKE UP|WAKES UP|WAKING|WAKING UP|WALL|WALLET|WALLS|WALTZ|WAR|WARD|WARFARE|WARLOCK*|WARMTH|WARNING|WARRIOR|WARRIORS|WARS|WAS CHEATING|WAS LOST|WASH|WASHBASIN|WASHED|',
  'WASHING|WASN|WASP*|WASTELAND|WATER|WATER WELL|WATERFALL|WATERFALLS|WATERS|WATERY|WAVE|WAVES|WEALTH|WEALTHY|WEDDING|WEDDING DRESS*|WEDDING GOWN*|WEDDINGS|WEEP|WEEPING|WELLSPRING|WENT BROKE|WENT BUST|',
  'WENT DOWN|WENT OUT WITH|WEPT|WEREN|WEREWOLF|WEREWOLVES|WHALE*|WHEAT|WHISKY|WHITE|WHITE DRESS|WHITENESS|WHITISH|WIFE|WIFEY|WIG|WIGS|WILD ANIMAL*|WILDFIRE|WILDFIRES|WILDLIFE|WILLOW|WILLOWS|WIND|WINDOW|',
  'WINDOWPANE|WINDOWS|WINDOWSILL|WINDS|WINDY|WINE|WINES|WISHING WELL|WITCH|WITCHCRAFT|WITCHES|WITHOUT|WIVES|WIZARD*|WOKE|WOKE UP|WOLF|WOLF CUB|WOLF CUBS|WOLF PACK|WOLVES|WONDER|WONDERED|WONDERFUL|',
  'WONDERING|WONDROUS|WOOD|WOODEN CROSS|WOODLAND|WOODLANDS|WOODS|WORK|WORKED|WORKING|WORKMATE*|WORKPLACE|WORLD WAR|WORM|WORMS|WORR*|WOULDN|WOUND|WOUNDED|WOUNDS|WRAPPED GIFT|WRECK|WRESTLED|WRESTLING|',
  'WRINKLE|WRINKLES|WRIST|WRISTS|WRISTWATCH|WRITE|WRITER|WRITES|WRITING|WRITTEN|WROTE|WYVERN*|YACHT|YELL|YELLED|YELLING|YELLOW|YELLOWISH|YELLOWS|YOGA|YOLK|ZEN|ZOMBIE|ZOMBIES|ZOO|1|10|12|13|2|3|4|5|6|7|8|',
  '9|ABENDDAMMERUNG|ABENDKLEID*|ABENDROT|ABFLUG|ABFLUGHALLE|ABGEBRANNT|ABGESTURZT|ABGRUND|ABHEBEN|ABITUR|ABKOMMEN|ABSTIEG|ABSTOSSEND*|ABTEI|ABTEILUNGSLEITER|ABWARTS|ABZWEIGUNG|ACHSEL|ACHT|ACHTE|ACHTER|',
  'ACHTSAMKEIT|ACKER|ADLER*|AFFARE|AFFCHEN|AFFE|AFFEN|ALARM|ALARMANLAGE|ALARMGLOCKE|ALBTRAUM*|ALIEN|ALIENS|ALKOHOL|ALLIGATOR*|ALLMACHTIG|ALLMACHTIGE|ALPTRAUM*|ALT WERDEN|ALTAR|ALTARE|ALTE DAME|ALTE FRAU|',
  'ALTEN HAUS|ALTER MANN|ALTERN|ALTERTE|ALTES HAUS|AMEISE|AMEISEN|AMEISENHAUFEN|AMEISENSTAAT|AMEN|AMSEL*|ANATOMIE|ANDROID|ANDROIDEN|ANGEGRIFFEN|ANGEKETTET|ANGESPANNT*|ANGEWIDERT|ANGEZOGEN|ANGREIFEN|',
  'ANGREIFER|ANGRIFF|ANGRIFFE|ANGST*|ANORAK*|ANRUF|ANRUFEN|ANSCHLAG|ANSCHLAGE|ANSPANNUNG|ANTLITZ|ANZIEHSACHEN|ANZUG|APFEL|APFELBAUM|APFELS|APFELSINE|APFELSINEN|APOKALYP*|AQUARIUM*|ARBEIT|ARBEITE|',
  'ARBEITEN|ARBEITET|ARBEITETE|ARBEITETEN|ARBEITGEBER|ARBEITSKLEIDUNG*|ARBEITSKOLLEGE*|ARBEITSLOS|ARBEITSLOSIGKEIT|ARBEITSPLATZ|ARBEITSZIMMER|ARGER*|ARMBAND|ARMBANDUHR|ARMUT|ARSEN|ARZT|ARZTE|ARZTIN|ASS|',
  'ASSEN|AST|ASTE|ASTROLOGE|ASTRONAUT|ASTRONAUTEN|ATEMBERAUBEND*|ATLAS|ATTACKE|ATTACKIERT|ATTENTATER|AUFBAUEN|AUFERSTAND|AUFERSTANDEN|AUFERSTEHEN|AUFERSTEHUNG|AUFGEBRACHT*|AUFGEMACHT|AUFGEREGT*|',
  'AUFGEWACHT|AUFMACHEN|AUFREGUNG|AUFSTIEG|AUFWACHEN|AUFWACHTE|AUFZUG|AUFZUGE|AUGE|AUGEN|AUGENLID|AUGENLIDER|AUKTION|AUS DER ASCHE|AUSGEHUNGERT|AUSGELASSEN|AUSGERAUBT|AUSSCHLAG|AUSSERIRDISCHE*|',
  'AUSSERIRDISCHER|AUSSERKORPERLICH|AUSSERST|AUTO|AUTOBAHN|AUTOBUS|AUTOFAHREN|AUTOFAHRT|AUTOS|AUTOUNFALL|BABY|BABYPUPPE|BABYS|BACH|BACHE|BACKENZAHN|BACKENZAHNE|BACKER|BACKEREI|BACKOFEN|BAD|BADEWANNE|',
  'BADEZIMMER|BAGUETTE|BAHNHOF|BAHNHOFE|BAHNSTEIG|BALL|BALLE|BALLKLEID*|BALLON|BANANE|BANANEN|BANKER|BANKETT|BANKFILIALE|BANKIER|BANKKONTO|BANKNOTE|BANKNOTEN|BANKRAUB|BANKROTT|BANKSCHALTER|BAR|BARCHEN|',
  'BAREN|BARFUSS|BARGELD|BARIN|BARREN|BART|BARTE|BARTIG|BARTIGE|BASILIKA|BASKENMUTZE*|BAUCH|BAUCHE|BAUCHNABEL|BAUE|BAUEN|BAUM|BAUME|BAUMES|BAUMSTUMPF|BAUSTELLE|BAUT|BAUTE|BAUTEN|BEBEN|BEBTE|BEDROHLICH|',
  'BEDROHT|BEDROHTE|BEDROHUNG|BEDRUCKEND|BEDRUCKT|BEEILEN|BEEILT|BEEILTE|BEERDIGEN|BEERDIGT|BEERDIGTE|BEERDIGUNG|BEERDIGUNGEN|BEFREI*|BEGEISTER*|BEGLUCKT|BEGRABEN|BEGRABNIS|BEGRUB|BEHAGLICH*|BEIN|BEINE|',
  'BEINEN|BEKLEM*|BEKLOMMEN|BERAUBT|BERG|BERGAUF|BERGE|BERUF|BERUFSVERKEHR|BERUHIG*|BERUHMT|BERUHMTE|BERUHMTEN|BERUHMTHEIT|BESCHAMEND*|BESCHAMT*|BESESSEN|BESESSENE|BESORGNIS|BESORGT|BESORGTE|BESORGTEN|',
  'BESPRECHUNG|BESTE FREUNDIN|BESTER FREUND|BESTIE*|BETE|BETEN|BETET|BETETE|BETETEN|BETROG|BETROGEN|BETRUBT*|BETRUNKEN|BETT|BETTDECKE|BETTELN|BETTELTE|BETTEN|BETTLAKEN|BETTLER|BETTLERIN|BEUNRUHIG*|BEUTE|',
  'BEUTEL|BEWEGUNGSUNFAHIG|BEWERBER|BEWERBERIN|BEWERBUNG|BEWERBUNGEN|BEWERBUNGSGESPRACH|BEWOLKT|BEWORBEN|BEWUNDER*|BEWUSST DASS ICH TRAUME|BEWUSST DASS ICH TRAUMTE|BEZAHLEN|BEZAHLT|BEZAHLTE|BEZAUBER*|',
  'BEZIEHUNG|BH|BIBLIOTHEK|BIENE*|BIENENSTOCK*|BIER|BIERE|BILDSCHIRM|BIRNE|BIRNEN|BISCHOF|BISON|BLATT|BLATTER|BLAU|BLAUE|BLAUEN|BLAUER|BLAUES|BLAUWAL*|BLIND|BLINDE|BLINDEN|BLINDHEIT|BLITZ|BLITZE|',
  'BLITZSCHLAG|BLOSSGESTELLT|BLUHEN|BLUHTE|BLUME|BLUMEN|BLUMENSTRAUSS|BLUT|BLUTE|BLUTEN|BLUTEND|BLUTET|BLUTETE|BLUTIG|BLUTIGE|BLUTLACHE|BLUTUNG|BLUTVERSCHMIERT|BODEN|BOE|BOEN|BOMBARDIERUNG|BOMBE|BOMBEN|',
  'BOMBENANGRIFF|BONBON|BONBONS|BOOT|BOOTE|BORDKARTE|BOSS|BOUTIQUE|BOXERSHORTS|BRACH EIN|BRACH ZUSAMMEN|BRAND|BRANDE|BRANDSTIFTUNG|BRANDUNG|BRANNTE|BRATEN|BRAUNBAR*|BRAUT|BRAUTIGAM|BRAUTKLEID*|',
  'BRAUTSCHLEIER*|BRECHREIZ|BREMSE|BREMSEN|BREMSPEDAL|BREMSTE|BRENNEN|BRENNEND|BRICHT ZUSAMMEN|BRIEF|BRIEFE|BRIEFKASTEN|BRIEFTASCHE|BRIEFTRAGER|BRIEFUMSCHLAG|BRILLE|BRILLEN|BRISE|BROT|BROTCHEN|BROTE|',
  'BRUCKE|BRUCKEN|BRUDER|BRUDERS|BRULLEN|BRULLTE|BRUMMER|BRUNNEN|BRUNNENS|BUB|BUCH|BUCHER|BUCKELWAL*|BUFFEL*|BUHNE|BUHNEN|BULLE|BULLEN|BURG|BURGEN|BURGERSTEIG|BURO|BUROS|BUS|BUS VERPASST|BUSHALTESTELLE|',
  'BUSSARD*|BUSSE|BUSTENHALTER|CAPPUCCINO|CENT|CHEF|CHEFIN|CHERUB|CHIMARE*|CHIRURG|CHIRURGIN|CHOR|CHRISTUS|CLOWN|CLOWNS|COMPUTER|COUCH|COUSIN|COUSINE|CRASH|CYBORG*|DACH|DACHBODEN|DACHER|DACHFENSTER|',
  'DACHKAMMER|DACHRINNE|DACHSTUBE|DACHZIEGEL|DACKEL*|DAHINGESCHIEDEN|DAMMERUNG|DAMON|DAMONEN|DAMONISCH|DANKBAR*|DARLEHEN|DATE|DATING|DAUMEN|DEGEN|DEJA VU|DELFIN*|DELPHIN*|DEMUTIGUNG|DEPRESSION|',
  'DEPRIMIER*|DERSELBE TRAUM|DESASTER|DESSERT|DESSOUS|DETONATION|DIADEM|DIAMANT|DIAMANTEN|DIE FLIEGE|DIEB|DIEBE|DIEBIN|DIENSTKLEIDUNG*|DIESEN TRAUM WIEDER|DINO|DINOS|DINOSAURIER|DIREKTOR|DIREKTORIN|',
  'DOHLE*|DOKTOR|DOLCH|DOLCHE|DOLLAR|DOM|DONNER|DONNERTE|DOPPELGANGER|DORF|DORFCHEN|DORFER|DOTTER|DOZENT|DRACHE|DRACHEN|DRACULA|DRECKIGE KLEIDUNG|DREI|DREIZEHN|DREIZEHNTE|DREIZEHNTER|DRITTE|DRITTEN|',
  'DRITTER|DRITTES|DROHT|DROHTE|DROHUNG|DROHUNGEN|DSCHIHADIST|DSCHUNGEL|DUNE|DUNEN|DUNKEL|DUNKELHEIT|DUNST|DUNSTIG|DURCHSUCHEN|DURCHSUCHTE|DURRE|DURST|DURSTIG|DUSCHE|DUSCHEN|DUTZEND|DYNAMIT|EBENBILD|',
  'EBER|EDELSTEIN|EDEN|EHEBRUCH|EHEFRAU|EHEFRAUEN|EHEMANN|EHEMANNER|EHRFURCHT*|EI|EICHE|EICHEN|EIER|EIERN|EIERSCHALE|EIFERSUCHT*|EIGELB|EILAND|EINBRECHEN|EINBRUCH|EINBRUCHE|EINDRINGLING|EINE FLIEGE|',
  'EINGEBROCHEN|EINGESCHLOSSEN|EINGESPERRT|EINGESPERRTE|EINGESTELLT|EINGESTURZT|EINHORN|EINHORNCHEN|EINHORNER|EINKAUF|EINKAUFEN|EINKAUFSZENTRUM|EINS|EINSAM*|EINSAME INSEL|EINSCHUCHTERUNG|EINSIEDLER|',
  'EINSTURZ|EINSTURZEN|EIS|EISBAR*|EISBERG|EISBERGE|EISCREME|EISENBAHN|EISIG|EKEL*|EKLIG*|EKLIPSE|EKSTASE|ELCH*|ELEFANT|ELEFANTEN|ELEFANTENBABY|ELEND|ELFE|ELFEN|ELLBOGEN|ELLENBOGEN|ELTERN|ELTERNHAUS|',
  'ELTERNHAUSES|ELTERNTEIL|EMPORT|EMPORTE|EMPORTEN|EMPORUNG|ENDE DER WELT|ENDZEIT*|ENGEL|ENGELCHEN|ENGELHAFT|ENTBINDUNG|ENTBUNDEN|ENTDECKEN|ENTDECKT|ENTDECKTE|ENTDECKUNG|ENTFUHREN|ENTFUHRER|ENTFUHRT|',
  'ENTFUHRTE|ENTFUHRUNG|ENTKAM|ENTKLEIDET|ENTKOMMEN|ENTLASSEN|ENTLASSUNG|ENTSETZ*|ENTSPANN*|ENTWURZELT|EPIDEMIE|ERBE|ERBEN|ERBIN|ERBLINDET|ERBRACH|ERBRECHEN|ERBROCHEN|ERBSCHAFT|ERBTE|ERDBEBEN|ERDBEERE|',
  'ERDBEEREN|ERDBODEN|ERDE|ERDEN|ERDRUTSCH|EREMIT|ERKLOMM|ERLEICHTER*|ERMORDET|ERMORDETE|ERNTE|ERNTEN|EROTISCH|EROTISCHE|ERPRESST|ERPRESSUNG|ERRICHTEN|ERRICHTETE|ERSCHOSSEN|ERSCHRAK|ERSCHRECK*|',
  'ERSCHROCK*|ERSCHUTTERUNG|ERSTARRT|ERSTARRTE|ERSTAUN*|ERSTE|ERSTEN|ERSTER|ERSTES|ERSTES DATE|ERSTICKEN|ERSTICKT|ERSTICKTE|ERTRANK|ERTRANKEN|ERTRANKT|ERTRINK*|ERTRUNKEN|ERWACHEN|ERWACHT|ERWACHTE|',
  'ERZENGEL|ERZFEIND|ESPRESSO|ESSEN|ESSTISCH|EULE*|EUPHORI*|EURO|EVAKUIERT|EVAKUIERUNG|EX|EX FRAU|EX FREUND|EX FREUNDIN|EX MANN|EXAMEN|EXFRAU|EXFREUND|EXFREUNDIN|EXMANN|EXPLODIEREN|EXPLODIERT|',
  'EXPLODIERTE|EXPLOSION|EXPLOSIONEN|EXTREM|FABELWESEN*|FAHRE|FAHRKARTE|FAHRKARTEN|FAHRRAD|FAHRRADER|FAHRRADFAHREN|FAHRSCHEIN|FAHRSTUHL|FAHRSTUHLE|FALKE*|FALLE|FALLEN|FALLEND|FALLT|FALSCHES ERWACHEN|',
  'FALTER|FAMILIE|FAMILIEN|FAMILIENHAUS|FAND|FANDEN|FASCHING*|FASZIN*|FAULIG|FAUST|FAUSTE|FAUSTSCHLAG|FAUSTSCHLAGE|FEE|FEEN|FEENSTAUB|FEIER|FEIERN|FEIND|FEINDE|FEINDEN|FEINDIN|FEINDSELIG*|FELD|FELDER|',
  'FELS|FELSEN|FELSWAND|FENSTER|FENSTERBANK|FENSTERLADEN|FENSTERSCHEIBE|FERKEL*|FERNSEHEN|FERNSEHER|FERNSEHGERAT|FERNSEHSENDUNG|FESSEL|FESSELN|FESTE FREUNDIN|FESTER FREUND|FESTESSEN|FESTGEHALTEN|',
  'FESTMAHL|FESTUNG|FETZEN|FEUER|FEUERALARM|FEUERSBRUNST|FEUERVOGEL*|FEUERWEHR|FEUERWEHRMANN|FIEBER|FIEL|FIELEN|FILMSTAR|FINDE|FINDEN|FINDET|FINGER|FINGERN|FINGERNAGEL|FINGERRING|FINGERSPITZEN|',
  'FINSTERNIS|FIRMA|FIRMAMENT|FISCH|FISCHE|FISCHLEIN|FLAMME|FLAMMEN|FLASCHCHEN|FLASCHE|FLASCHEN|FLASCHENPOST|FLEDERMAUS|FLEDERMAUSE|FLEISCH|FLIEGEN|FLIEGEND|FLIEGENDE UNTERTASSE|FLIEGENSCHWARM*|FLIEGER|',
  'FLIEGT|FLIEHE|FLIEHEN|FLIEHT|FLIRT|FLIRTEN|FLIRTETE|FLOG|FLOGEN|FLOH|FLOHE|FLOHEN|FLUCHT|FLUCHTEN|FLUCHTETE|FLUG|FLUG VERPASSEN|FLUG VERPASST|FLUGHAFEN|FLUGHUND*|FLUGSAURIER|FLUGTICKET|FLUGZEUG|',
  'FLUGZEUG VERPASST|FLUGZEUGE|FLUR|FLURE|FLUSS|FLUSSE|FLUSSES|FLUT|FLUTWELLE|FOHLEN|FORELLE*|FOTO|FOTOALBUM|FOTOGRAFIE|FOTOGRAFIEREN|FOTOS|FREIBAD|FREMDE|FREMDEN|FREMDER|FREMDGEGANGEN|FREMDGEHEN|FREUD*|',
  'FREUND|FREUNDE|FREUNDEN|FREUNDIN|FREUNDINNEN|FRIEDEN|FRIEDENSTAUBE*|FRIEDHOF|FRIEDHOFE|FRIEDLICH*|FRISUR|FROH|FROHE|FROHEN|FROHLICH*|FROSCH|FROSCHE|FRUCHT|FRUCHTE|FRUHERES LEBEN|FRUST*|FUCHS|FUCHSE|',
  'FUCHSIN|FUNF|FUNFTE|FUNFTEN|FUNFTER|FURCHT*|FURSORG*|FUSS|FUSSBALL|FUSSE|FUSSEN|GALAXIE|GALAXIEN|GANGE|GANSEBLUMCHEN|GANZ|GARTEN|GARTEN EDEN|GARTENS|GARTNER|GASSE|GASSEN|GASTEZIMMER|GASTHOF|',
  'GASTSTATTE|GATTE|GATTIN|GAUL|GEALTERT|GEARBEITET|GEBACK|GEBANNT|GEBAR|GEBAREN|GEBAUT|GEBEINE|GEBET|GEBETE|GEBETET|GEBIERT|GEBIRGE|GEBISS|GEBOREN|GEBORGEN*|GEBURT|GEBURTEN|GEDEMUTIGT|GEDRANGE|GEERBT|',
  'GEFAHR|GEFAHRLICH|GEFAHRLICHE|GEFAHRLICHEN|GEFANGEN|GEFANGENER|GEFANGENSCHAFT|GEFANGNIS|GEFANGNISSE|GEFEUERT|GEFLOGEN|GEFLOHEN|GEFROREN|GEFUNDEN|GEGESSEN|GEGNER|GEGNERIN|GEHALT|GEHEIMES ZIMMER|',
  'GEHEIMGANG|GEHEIMRAUM|GEHEIMTUR|GEHEIMZIMMER|GEHEIRATET|GEHOLZ|GEHORLOS|GEHWEG|GEIER*|GEISEL|GEISELN|GEISELNAHME|GEISELNEHMER|GEISS|GEISSBOCK*|GEIST|GEISTER|GEISTIGER FUHRER|GEISTLICHER|GEJAGT|',
  'GEKAUFT|GEKENTERT|GEKETTET|GEKIDNAPPT|GEKLAUT|GEKLETTERT|GEKREUZIGT|GEKRONT|GEKUNDIGT|GEKUSST|GELACHT|GELACHTER|GELAHMT|GELAHMTE|GELASSENHEIT|GELAUFEN|GELB|GELBE|GELBEN|GELBER|GELBES|GELD|GELDAUTOMAT|',
  'GELDBEUTEL|GELDBORSE|GELDSCHEIN|GELDSCHEINE|GELDSTUCK|GELDSTUCKE|GELIEBTE|GELIEBTEN|GELIEBTER|GEMAHL|GEMAHLIN|GEMUSE|GEMUSEGARTEN|GENERALSCHLUSSEL|GENERVT*|GEOFFNET|GEOPFERT|GEPACK|GEPARD*|GEPUTZT|',
  'GERANNT|GEREINIGT|GEREIZT*|GERUHRT|GERUNGEN|GESALZEN|GESANG|GESCHAFTSFUHRER|GESCHENK|GESCHENKE|GESCHENKT|GESCHIEDEN|GESCHIEDENE|GESCHLECHTSVERKEHR|GESCHMACKSKNOSPEN|GESCHMINKT|GESCHOPF|GESCHOPFE|',
  'GESCHRIEBEN|GESCHRIEN|GESCHWOMMEN|GESEGNET|GESICHT|GESICHTER|GESICHTS|GESPENST|GESPENSTER|GESPENSTISCH|GESPRENGT|GESPRUNGEN|GESTALT|GESTOHLEN|GESTORBEN|GESTRESST|GESTURZT|GESUCHT|GESUNGEN|GETANZT|',
  'GETAUCHT|GETAUFT|GETOTET|GETREIDE|GETRENNT|GETROSTET|GETRUNKEN|GEWARTET|GEWASCHEN|GEWASSER|GEWEHR|GEWEHRE|GEWEIH*|GEWEINT|GEWISSENSBISSE|GEWITTER|GEWITTERN|GEWOLBEKELLER|GEZEITEN|GIFT|GIFTIG|GIFTIGE|',
  'GIFTSTACHEL|GING FREMD|GIPFEL|GITTERSTABE|GLASSCHERBEN|GLATZE|GLAUBIGER|GLEICHEN TRAUM|GLEIS|GLEISE|GLETSCHER|GLOTZE|GLUCK|GLUCKLICH*|GLUCKSGEFUHL*|GLUHBIRNE|GLUT|GNOM|GNOME|GOCKEL*|GOLD|GOLDBARREN|',
  'GOLDEN|GOLDENE|GOLDENEN|GOLDENER|GOLDENES|GOLDFISCH*|GOLDKLUMPEN|GOLDMUNZE|GOLDMUNZEN|GORILLA*|GOTT|GOTTER|GOTTESACKER|GOTTESDIENST|GOTTHEIT|GOTTIN|GOTTLICH|GOTTLICHE|GRAB|GRABER|GRABERFELD|GRABMAL|',
  'GRABSTATTE|GRABSTEIN|GRABSTEINE|GRAS|GRASER|GRASLAND|GRAU|GRAUE|GRAUE HAARE|GRAUEN|GRAUENHAFT*|GRAUENVOLL*|GRAUER|GRAUES|GREIS|GREISENALTER|GREISIN|GRENZE|GRENZEN|GRENZUBERGANG|GRIFF AN|GRIFFEN AN|',
  'GRIPPE|GRIZZLY*|GROLL|GROSCHEN|GROSSELTERN|GROSSMUTTER|GROSSRAUMBURO|GROSSSTADT|GROSSVATER|GROTTE|GROTTEN|GRUFT|GRUN|GRUNDSCHULE|GRUNE|GRUNEN|GRUNER|GRUNES|GRUSEL*|GRUSLIG|GURGEL|GURU|GUTE FEE|',
  'GYMNASIUM|HAAR|HAARE|HAAREN|HAARSCHNITT|HABICHT*|HAFTLING|HAHN|HAHNE|HAI|HAIE|HAIFISCH*|HAIN|HALBBRUDER|HALBSCHWESTER|HALLENBAD|HALS|HALS UBER KOPF VERLIEBT|HALSES|HALSKETTE|HAMSTER*|HAND|HANDE|',
  'HANDEN|HANDFLACHE|HANDGELENK|HANDGEMENGE|HANDSCHRIFT|HANDTASCHE|HANDY|HANGEBRUCKE|HARLEKIN|HARMONIE|HARMONISCH|HASCHEN|HASE|HASEN|HASS|HASSEN|HASSERFULLT*|HASSTE|HASSTEN|HAUS|HAUS MEINER ELTERN|',
  'HAUS MEINER KINDHEIT|HAUSDACH|HAUSE|HAUSER|HAUSFLUR|HAUSSCHLUSSEL|HAUSSCHUH*|HAUSTUR|HAUT|HAUTE|HEILIGTUM|HEIMATDORF|HEIMWEH|HEINZELMANNCHEN|HEIRAT|HEIRATEN|HEIRATETE|HEIRATETEN|HEIRATSANTRAG|HEISER|',
  'HEITER*|HEKTISCH*|HELL|HELLE|HELLSEHER|HELLSEHERIN|HEMD|HEMDEN|HENGST*|HENNE*|HERBERGE|HERBSTLAUB|HERD|HERRLICH*|HERRSCHER|HERRSCHERIN|HERUNTER|HERZ|HERZEN|HERZENS|HERZINFARKT|HERZLICH*|HERZSCHLAG|',
  'HEUSCHRECKE*|HEXE|HEXEN|HEXENHAUS*|HEXENMEISTER*|HEXENSABBAT|HEXEREI|HIMMEL|HIMMELBLAU|HIMMELREICH|HIMMELS|HIMMELSRICHTUNG|HIMMELSRICHTUNGEN|HIMMELSZELT|HINAB|HINABSTEIGEN|HINAUFSTEIGEN|HINGABE|',
  'HINGERISSEN|HINTER MIR HER|HINTERHALT|HINUNTER|HINUNTERGEHEN|HIRSCH*|HOB AB|HOCHGEFUHL|HOCHHAUS|HOCHHAUSER|HOCHSEE|HOCHWASSER|HOCHZEIT|HOCHZEITEN|HOCHZEITSKLEID*|HOCKER|HOFFNUNGSLOS*|HOFNARR|',
  'HOHES ALTER|HOHLE|HOHLEN|HOLLE|HOLLENFEUER|HOLLISCH|HONIG|HONIGSUSS|HONIGWABE|HORROR|HOSE|HOSEN|HOTEL|HOTELS|HOTELZIMMER|HUGEL|HUHN|HUHNER|HUHNERSTALL*|HUMMEL*|HUND|HUNDCHEN|HUNDE|HUNDIN|HUNE|HUNEN|',
  'HUNGER|HUNGERSNOT|HUNGRIG|HUPEN|HUPFEN|HUPFTE|HUT|HUTE|HYDRA|HYPOTHEK|IM KREIS|IMAM|IMKER*|IMMER DERSELBE TRAUM|IMMER WIEDER|IN DER BANK|IN DIE VERGANGENHEIT|IN DIE ZUKUNFT|IN FLAMMEN|IN GEFAHR|',
  'IN IHREN ARMEN|IN SEINEN ARMEN|IN SICHERHEIT|INFEKTION|INNENSTADT|INNIG|INSEKT*|INSEL|INSELCHEN|INSELN|INSOLVENT|INSOLVENZ|INTERNET|INVASION|IRIS|IRRGARTEN|IRRSINNIG|IRRTE|IRRTE UMHER|ISST|JACKE*|',
  'JACKPOT|JAGTE MICH|JAGTEN MICH|JAGUAR*|JAKOBSWEG|JEDE NACHT|JENSEITS|JESUS|JOB|JUBEL*|JUNGSTES GERICHT|JUWEL|JUWELEN|KADAVER|KAFER*|KAFFEE|KAFIG|KAFIGE|KAIMAN*|KAISER|KAISERIN|KAJAL*|KAKAO|KAKERLAKE*|',
  'KALB|KALBER|KAM NICHT HERAUS|KAM NICHT RAUS|KAMERA|KAMPF*|KANALRATTE*|KANARIENVOGEL*|KANINCHEN|KAPELLE|KAPELLEN|KAPLAN|KAPPE*|KAPUZE*|KARAMELL|KARMA|KARNEVAL*|KARNICKEL*|KAROTTE|KAROTTEN|KARPFEN|',
  'KARRIERE|KARTE|KARTEN|KARTENLEGERIN|KARTOFFEL|KARTOFFELN|KASKADE|KASKADEN|KASTCHEN|KATAKLYSMUS|KATAKOMBEN|KATASTROPHAL|KATASTROPHE|KATASTROPHEN|KATER|KATHEDRALE|KATZCHEN|KATZE*|KAUFE|KAUFEN|KAUFHAUS|',
  'KAUFT|KAUFTE|KAUFTEN|KAULQUAPPE*|KAUZ|KAUZCHEN|KEHLE|KEILEREI|KEIN|KEIN AUSWEG|KEINE|KEINEM|KEINEN|KEINER|KEINER SAH MICH|KEINES|KELLER|KELLERRAUM|KELLERS|KELLNER|KELLNERIN|KENTERN|KERKER|KERZE|',
  'KERZEN|KERZENLICHT|KERZENSTANDER|KETTE|KETTEN|KICHERN|KICHERTE|KIDNAPPING|KIESEL|KIESELSTEIN|KIND|KINDER|KINDERZIMMER|KINDES|KINN|KIRCHE|KIRCHEN|KIRSCHE|KIRSCHEN|KISTE|KISTEN|KITTEL*|KLAMOTTEN|',
  'KLAPPERSCHLANGE*|KLARTRAUM|KLARTRAUME|KLARTRAUMEN|KLASSENARBEIT|KLASSENZIMMER|KLAUSEL|KLAUSUR|KLAUSUREN|KLEID|KLEIDCHEN|KLEIDER|KLEIDUNG*|KLEINGELD|KLEINKIND|KLETTER*|KLINGE|KLINIK|KLIPPE|KLIPPEN|KLO|',
  'KLOSCHUSSEL|KLOSPULUNG|KLOSTER|KNABE|KNIE|KNIEN|KNOCHEL|KNOCHEN|KNOTEN|KNUTSCHEN|KOBOLD*|KOBRA*|KOFFER|KOHL|KOKON|KOKON*|KOLLEGE|KOLLEGEN|KOLLEGIN|KOLLEGINNEN|KOLLISION|KOMMISSAR|KOMPASS|KOMPASSE|',
  'KOMPASSNADEL|KONFERENZ|KONIG|KONIGE|KONIGIN|KONIGINNEN|KONIGS|KONIGSPALAST|KONKURS|KONNTE MICH NICHT BEWEGEN|KONSTRUIERTE|KONTAKTLINSE*|KOPF|KOPFE|KOPFES|KOPFKISSEN|KOPFSCHMERZEN|KORPER|KORPERS|',
  'KORRIDOR|KORRIDORE|KOSMOS|KOSTUM*|KOTER*|KOTZEN|KOTZTE|KRAHE*|KRANK|KRANKE|KRANKEN|KRANKENHAUS|KRANKENHAUSER|KRANKENPFLEGER|KRANKENSCHWESTER|KRANKENZIMMER|KRANKER|KRANKHEIT|KRANKHEITEN|KRATER|KREATUR|',
  'KREATUREN|KREBS|KREDIT|KREIS|KREISCHTE|KREISE|KREISFORMIG|KREISVERKEHR|KREUZ|KREUZE|KREUZFAHRT|KREUZIGUNG|KREUZUNG|KREUZUNGEN|KRIEG|KRIEGE|KRIEGER|KRISTALLKUGEL|KRITZELTE|KROKODIL*|KRONE|KRONEN|',
  'KRONLEUCHTER|KRONPRINZ|KRONUNG|KROTE*|KRUZIFIX|KRYPTA|KUCHE|KUCHEN|KUCHENTISCH|KUCKUCKSUHR|KUH|KUHE|KUHLSCHRANK|KUKEN|KULISSEN|KUMMER|KUMPEL|KUNDIGUNG|KUSCHELN|KUSCHELTEN|KUSCHELTIER|KUSS|KUSSE|',
  'KUSSEN|KUSST|KUSSTE|KUSSTEN|KUSTE|KUSTEN|LABYRINTH|LABYRINTHE|LACHE|LACHEN|LACHEND|LACHT|LACHTE|LACHTEN|LADEN|LAGERFEUER|LAHMUNG|LAIB|LAMM|LAMMER|LAMPE|LAMPEN|LANDKARTE|LANDSCHILDKROTE*|LANDSTRASSE|',
  'LANDUNG|LAPTOP|LARVE*|LATERNE|LAUB|LAUBES|LAUBFROSCH*|LAUFEN|LAUFT|LAVA|LEBENDE TOTE|LEBENSABEND|LEBENSGEFAHR|LEBENSGEFAHRTE|LEBENSGEFAHRTIN|LEBENSLAUF|LEBLOS|LEHM|LEHRER|LEHRERIN|LEHRERINNEN|LEHRERN|',
  'LEIB|LEICHE|LEICHEN|LEICHENHALLE|LEICHENWAGEN|LEICHNAM|LEITER|LEITERN|LENKRAD|LEOPARD*|LESEBRILLE*|LESEN|LEUCHTEN|LEUCHTEND|LEUCHTER|LEUCHTETE|LICHT|LICHTER|LICHTUNG|LIEBE|LIEBE AUF DEN ERSTEN BLICK|',
  'LIEBE GEMACHT|LIEBEN|LIEBESPAAR|LIEBEVOLL*|LIEBHABER|LIEBHABERIN|LIEBTE|LIEBTEN|LIED|LIEDER|LIEF|LIEFEN|LIFT|LILA|LILIE|LILIEN|LINDWURM*|LIPPE|LIPPEN|LIPPENSTIFT*|LIVREE|LOCKE|LODERN|LODERTE|',
  'LOKOMOTIVE|LOSEGELD|LOTTERIE|LOTTO|LOWE|LOWEN|LOWENJUNGE*|LOWIN*|LUFTANGRIFF|LUFTBALLON|LUFTBALLONS|LUMPEN|LUTSCHER|LUXURIOS|LUXUS|LUZID*|LUZIFER|MACHTE AUF|MADCHEN|MADE|MADEN|MAGEN|MAGIE|MAGISCH*|',
  'MAGMA|MAHLZEIT|MAHLZEITEN|MAKE UP|MAKEUP|MAMA|MAMI|MAMMUT|MAMMUTS|MANDALA|MANIKURE|MANSARDE|MANTEL|MANTRA|MARCHENHAFT*|MARCHENPRINZ|MARCHENPRINZESSIN|MARIENKAFER*|MARIONETTE|MARSMENSCH*|',
  'MASCHINENGEWEHR|MASCHINENMENSCH*|MASKE|MASKEN|MASKENBALL|MASKENBALL*|MASKIERT|MASKIERTE|MASSENKARAMBOLAGE|MATRATZE|MATRESSE|MATSCH|MATSCHIG|MAUER|MAUERN|MAUS|MAUSCHEN|MAUSE|MAUSEFALLE*|MAUSOLEUM|',
  'MEDITATION|MEDITIERE|MEDITIEREN|MEDITIERT|MEDITIERTE|MEER|MEERE|MEERES|MEERESGRUND|MEERJUNGFRAU*|MEERMANN|MEETING|MEIN MANN|MEINE FRAU|MEKKA|MELANCHOL*|MENSCHENFRESSER|MENSCHENMASSE|MENSCHENMASSEN|',
  'MENSCHENMENGE|MERKTE DASS ICH TRAUME|MERKTE DASS ICH TRAUMTE|MESSER|METAMORPHOSE|METRO|METZGER|METZGEREI|MICH VERLAUFEN|MIEZE*|MILCH|MILCHIG|MILCHSTRASSE|MILCHZAHN|MILCHZAHNE|MILITAR|MILLIARDAR|',
  'MILLIONAR|MILLIONARIN|MISCHWESEN*|MITARBEITER|MITARBEITERIN|MITEINANDER GESCHLAFEN|MITGEFUHL|MITTELLOS|MITTERNACHT|MOFA|MOHRE|MOHREN|MOLKEREI|MONARCH|MONCH|MONCHE|MOND|MONDE|MONDES|MONDFINSTERNIS|',
  'MONDLICHT|MONDSCHEIN|MONOKEL|MONSTER|MOPED|MORAST|MORD|MORDEN|MORDER|MORDERIN|MORGENDAMMERUNG|MORGENGRAUEN|MORGENROTE|MOSCHEE|MOSCHEEN|MOTORRAD|MOTORRADER|MOTORROLLER|MOTTE*|MUCKE*|MULMIG*|MUND|',
  'MUNDER|MUNDES|MUNDWINKEL|MUNZE|MUNZEN|MUTANT|MUTANTEN|MUTATION|MUTIERT|MUTTER|MUTTI|MUTZE*|NABEL|NACHBAR|NACHBARIN|NACHBARN|NACHBARSCHAFT|NACHLASS|NACHT|NACHTE|NACHTIGALL*|NACHTISCH|NACHTS|NACKEN|',
  'NACKT|NACKTE|NACKTEN|NACKTER|NACKTHEIT|NACKTSCHNECKE*|NAGEL|NAGELLACK|NAGELLACK*|NAGETIER*|NAHRUNG|NARBE|NARBEN|NARBIG|NARR|NASE|NASEN|NASENBLUTEN|NASENLOCH|NASENLOCHER|NASS|NATTER*|NATURKATASTROPHE|',
  'NEBEL|NEBELIG|NEBLIG|NEFFE|NEKROPOLE|NEKTAR|NERVOS*|NERVOSITAT|NEUE WOHNUNG|NEUGEBORENE|NEUGEBORENES|NEUGIER*|NEUN|NEUNTE|NEUNTER|NICHT|NICHT BEWEGEN|NICHTE|NICHTS|NIE|NIEDERGEBRANNT|',
  'NIEDERGESCHLAGEN*|NIEDERKUNFT|NIEMALS|NIEMAND KONNTE MICH SEHEN|NIEMAND SAH MICH|NIRWANA|NIXE|NIXEN|NONNE|NONNEN|NOTAR|NOTAUFNAHME|NUGGET|NUGGETS|OBDACHLOS|OBDACHLOSE|OBDACHLOSER|OBERARM|OBERSCHENKEL|',
  'OBST|OBSTGARTEN|OCHSE*|OFFEN|OFFENE|OFFIZIER|OFFIZIERE|OFFNE|OFFNEN|OFFNET|OFFNETE|OFFNETEN|OFFNUNG|OGER|OHNE|OHR|OHREN|OHRLAPPCHEN|OHRRINGE|OHRS|OMA|OMAS|OMELETT|OMEN|ONKEL|OPA|OPAS|OPFERGABE|',
  'OPFERGABEN|OPFERUNG|ORANG UTAN|ORANGE|ORANGEFARBEN|ORANGEN|ORCA*|ORDENSSCHWESTER|ORGASMUS|ORIENTIERUNGSLOS|ORKAN|OSTERHASE*|OZEAN|OZEANE|PACKCHEN|PAGODE|PAKT|PALAIS|PALAST|PALASTE|PANIK|PANISCH*|',
  'PANTHER*|PANTOFFEL*|PAPA|PAPAGEI*|PAPST|PARADIES|PARADIESISCH|PARCHEN|PARK|PARKA*|PARKS|PARTNER|PARTNERIN|PARTY|PASTOR|PAVIAN*|PEINLICH*|PENSION|PERLE|PERLEN|PERSONALCHEF|PERUCKE|PFAD|PFADE|PFARREI|',
  'PFARRER|PFAU|PFAUEN|PFAUENFEDER*|PFAUENRAD|PFENNIG|PFERD*|PFLEGER|PFORTE|PFUTZE|PFUTZEN|PHANTOM|PHIOLE|PHOENIX|PHONIX|PILGER|PILGERFAHRT|PILGERIN|PILGERN|PILGERTE|PISTOLE|PISTOLEN|PLANET|PLANETEN|',
  'PLATZREGEN|PLEITE|POLIZEI|POLIZIST|POLIZISTEN|POLIZISTIN|POLTERGEIST|PONY*|POOL|PORTEMONNAIE|PORTRAT|POTTWAL*|PRACHTIG*|PRALINE|PRALINEN|PRASENTATION|PRELLUNG|PRIESTER|PRINZ|PRINZEN|PRINZESSIN|',
  'PRINZESSINNEN|PROFESSOR|PROFESSORIN|PROMI|PROMINENTE|PROMINENTER|PROPHETISCH|PROPHEZEIUNG|PRUFUNG*|PRUGELEI|PRUGELEIEN|PUBLIKUM|PULLOVER*|PUMA|PUMPS|PUPILLE|PUPILLEN|PUPPE|PUPPEN|PURPUR|PURPURROT|',
  'PUTZE|PUTZEN|PUTZT|PUTZTE|PUTZTEN|PYTHON*|QUALM|QUALMTE|QUELLE|QUELLEN|QUELLWASSER|RABBINER|RABE|RABEN|RABENVOGEL*|RACHEN|RADFAHREN|RADTOUR|RAGE|RAMPENLICHT|RANGEN|RANNTE|RANNTEN|RANZIG|RASEND*|',
  'RASIEREN|RASIERT|RATTE|RATTEN|RAUBER|RAUBTIER*|RAUBUBERFALL|RAUBVOGEL*|RAUCH|RAUCHEN|RAUCHIG|RAUCHMELDER|RAUCHTE|RAUFEREI|RAUPE*|RAUSGEWORFEN|RAUSWURF|RECHNER|REGEN|REGENBOGEN|REGENBOGENFARBEN|',
  'REGENMANTEL*|REGENSCHIRM|REGENSCHIRME|REGENTROPFEN|REGENWURM*|REGNEN|REGNET|REGNETE|REGUNGSLOS|REH|REHE|REHKITZ*|REICH|REICHE|REICHTUM|REICHTUMER|REINIGEN|REINIGTE|REINKARNATION|REINKARNIERT|REISEBUS|',
  'REISEKOFFER|REISEPASS|REISETASCHE|RENDEZVOUS|RENNE|RENNEN|RENNEND|RENNT|RENTIERE|RESTAURANT|RESTAURANTS|REUE|REVOLVER|RIEGEL|RIESE|RIESEN|RIESIN|RIND|RINDER|RING|RINGE|RINGEN|RISKANT|RITTERBURG|',
  'RIVALE|ROBOTER|ROBOTERN|ROCK|ROCKE|ROLLBAHN|ROLLTREPPE|ROMAN|ROMANE|ROSE|ROSEN|ROSENBUSCH|ROSENGARTEN|ROSENKRANZ|ROSENSTRAUCH|ROSS|ROSSER|ROT|ROTE|ROTEN|ROTER|ROTES|ROTWEIN|RUCKEN|RUCKENS|',
  'RUCKENSCHMERZEN|RUCKGRAT|RUCKSACK|RUHE|RUHIG*|RUINE|RUINEN|RUINIERT|RUNTER|RUNZEL|RUNZELN|S BAHN|SABEL|SACKGASSE|SAHARA|SAHNE|SALAT|SALZ|SALZIG|SALZSTREUER|SAMTPFOTE*|SAND|SANDALE*|SANDIG|SANDSTRAND|',
  'SANDUHR|SANG|SANGEN|SANGER|SANGERIN|SARG|SARGE|SARKOPHAG|SASS FEST|SATAN|SAU|SAUBER MACHEN|SAUBERMACHEN|SAUE|SAUGLING|SAUGLINGE|SAURIER|SCHABE|SCHABEN|SCHACHTEL|SCHADEL|SCHAF|SCHAFCHEN|SCHAFE|',
  'SCHAFERHUND*|SCHAFHERDE*|SCHAM|SCHAMANE|SCHAMANEN|SCHAME|SCHAMEN|SCHAMTE|SCHARLACHROT|SCHATULLE|SCHATZ|SCHATZE|SCHATZKARTE|SCHATZKISTE|SCHATZSUCHE|SCHATZTRUHE|SCHAUSPIELER|SCHAUSPIELERIN|',
  'SCHEIDEN LASSEN|SCHEIDEWEG|SCHEIDUNG|SCHEIDUNGEN|SCHEIDUNGSANWALT|SCHENKEN|SCHENKTE|SCHERBE|SCHERBEN|SCHIESSEREI|SCHIFF|SCHIFFBRUCH|SCHIFFBRUCHIG|SCHIFFE|SCHILDKROTE|SCHILDKROTEN|SCHILLERND|SCHIMMEL|',
  'SCHIMMELIG|SCHIMPANSE*|SCHINKEN|SCHIRM|SCHLACHT|SCHLACHTFELD|SCHLAFPARALYSE|SCHLAFRAUM|SCHLAFSAAL|SCHLAFZIMMER|SCHLAGEREI|SCHLAGEREIEN|SCHLAMM|SCHLAMMIG|SCHLANGE*|SCHLOSS|SCHLOSSER|SCHLUCHT|',
  'SCHLUCHTEN|SCHLUCHZEN|SCHLUCHZTE|SCHLUPFER*|SCHLUSS GEMACHT|SCHLUSSEL|SCHLUSSELBUND|SCHLUSSELLOCH|SCHLUSSMACHEN|SCHMEISSFLIEGE*|SCHMETTERLING*|SCHMETTERLINGE IM BAUCH|SCHMINK*|SCHMUCK|',
  'SCHMUTZIGE KLEIDUNG|SCHMUTZIGE WASCHE|SCHNAPS|SCHNECKE*|SCHNECKENHAUS*|SCHNEE|SCHNEEFLOCKE|SCHNEEFLOCKEN|SCHNEEMANN|SCHNEEWEISS|SCHNEIEN|SCHNEIT|SCHNEITE|SCHNUR|SCHNURRBART|SCHOKOLADE|SCHOKOLADEN|',
  'SCHON WIEDER|SCHRECK*|SCHREI|SCHREIBE|SCHREIBEN|SCHREIBEND|SCHREIBT|SCHREIBTISCH|SCHREIE|SCHREIEN|SCHREIEND|SCHREIN|SCHREIT|SCHRIE|SCHRIEB|SCHRIEBEN|SCHRIEN|SCHUH|SCHUHE|SCHULDEN|SCHULDETE|SCHULDETEN|',
  'SCHULDGEFUHL*|SCHULDIG*|SCHULDNER|SCHULE|SCHULEN|SCHULHOF|SCHULTER|SCHULTERBLATT|SCHULTERN|SCHURZE*|SCHUSS|SCHUSSE|SCHUSSWAFFE|SCHUTT|SCHUTZBRILLE*|SCHUTZENGEL|SCHUTZENGRABEN|SCHWAGER|SCHWAGERIN|',
  'SCHWALBE*|SCHWAMM|SCHWAMMEN|SCHWAN|SCHWANE|SCHWANENSEE|SCHWANGER|SCHWANGERE|SCHWANGERSCHAFT|SCHWANGERSCHAFTEN|SCHWARZ|SCHWARZE|SCHWARZEN|SCHWARZER|SCHWARZER SCHWAN|SCHWARZES|SCHWEBE|SCHWEBEN|',
  'SCHWEBEND|SCHWEBT|SCHWEBTE|SCHWEIN*|SCHWERMUT*|SCHWERT|SCHWERTER|SCHWERTKAMPF|SCHWERTWAL*|SCHWESTER|SCHWESTERN|SCHWIEGERELTERN|SCHWIEGERMUTTER|SCHWIEGERVATER|SCHWIMMBAD|SCHWIMMBECKEN|SCHWIMME|',
  'SCHWIMMEN|SCHWIMMEND|SCHWIMMT|SECHS|SECHSTE|SECHSTEN|SECHSTER|SEE|SEELE|SEELEN|SEELENFRIEDEN|SEEN|SEGELBOOT|SEGEN|SEGNEN|SEGNET|SEGNETE|SEHNSUCHT*|SEHR|SEIL|SEILE|SEITENSPRUNG|SEKT|SELBEN TRAUM|',
  'SELBSTMORDATTENTATER|SELIG*|SELIGKEIT|SEMINAR|SENSENMANN|SERAPH|SESSEL|SEUCHE|SEX|SEXUALITAT|SEXUELL|SEXUELLE|SEXUELLEN|SHOPPEN|SIEBEN|SIEBTE|SIEBTEN|SIEBTER|SIEGELRING|SINGE|SINGEN|SINGT|SINTFLUT|',
  'SIRENE|SIRENEN|SITZUNG|SKELETT|SKELETTE|SKORPION|SKORPIONE|SLIP|SLIPS|SMARAGD|SMARAGDGRUN|SO|SOFA|SOHN|SOHNE|SOLDAT|SOLDATEN|SOMMERKLEID*|SOMMERSPROSSEN|SONNE|SONNEN|SONNENAUFGANG|SONNENBRILLE*|',
  'SONNENFINSTERNIS|SONNENLICHT|SONNENSCHEIN|SONNENSCHIRM|SONNENSTRAHL|SONNENSTRAHLEN|SONNENUNTERGANG|SONNIG|SORGE|SORGEN|SORGERECHT|SPARKASSE|SPARSCHWEIN|SPAT|SPATZ*|SPEICHER|SPIEGEL|SPIEGELBILD|',
  'SPIEGELBILDER|SPIELKARTEN|SPIELSACHEN|SPIELZEUG|SPINNE|SPINNEN|SPINNENNETZ*|SPINNWEBEN|SPIRALE|SPIRALEN|SPIRITUELLER FUHRER|SPITAL|SPRANG|SPRANGEN|SPRENGSTOFF|SPRENGUNG|SPRINGBRUNNEN|SPRINGE|SPRINGEN|',
  'SPRINGEND|SPRINGT|SPRINTETE|SPROSSE|SPROSSEN|SPRUDELTE|SPRUNG|SPRUNGBRETT|SPUK|SPUKHAUS|SPUKT|SPUKTE|SPULE|STADT|STADTE|STADTMAUER|STADTPLAN|STADTVIERTEL|STAMM|STANDUHR|STARB|STARBEN|STARR|STARTBAHN|',
  'STAU|STAUN*|STAUS|STEAK|STECHMUCKE*|STECKTE FEST|STEG|STEIN|STEINE|STEINEN|STELLDICHEIN|STERBE|STERBEBETT|STERBEN|STERBEND|STERBENDE|STERN|STERNBILD|STERNE|STERNEN|STERNENHIMMEL|STERNSCHNUPPE|',
  'STIEFBRUDER|STIEFEL*|STIEFELTERN|STIEFMUTTER|STIEFSCHWESTER|STIEFVATER|STIEG HINAB|STIEG HINAUF|STIEG HINUNTER|STIER|STIERE|STIERKAMPF*|STIMME|STIRBT|STIRN|STOCKELSCHUH*|STOFFTIER|STOLLEN|STOLZ|',
  'STOLZE|STOLZER|STOSSVERKEHR|STRAHLEND|STRAND|STRANDE|STRANDES|STRASSE|STRASSEN|STRASSENBAHN|STRESS|STRICK|STRICKLEITER|STROHHUT*|STROM|STUBENFLIEGE*|STUFEN|STUHL|STUHLE|STUMM|STUMME|STURM|STURME|',
  'STURMISCH|STURZ|STURZEN|STURZT|STURZT EIN|STURZTE|STURZTE EIN|STUTE*|SUCHE|SUCHEN|SUCHEND|SUCHT|SUCHTE|SUCHTEN|SUMPF|SUMPFE|SUPERHELD*|SUPERHELDIN*|SUPERKRAFT|SUPERKRAFTE|SUPERMARKT|SUSSIGKEIT|',
  'SUSSIGKEITEN|SYNAGOGE|T REX|TAGESANBRUCH|TAGUNG|TAL|TALER|TALES|TALKESSEL|TANNE|TANNEN|TANTE|TANZ|TANZE|TANZEN|TANZEND|TANZER|TANZERIN|TANZT|TANZTE|TANZTEN|TARANTEL*|TAROT|TASCHE|TASCHEN|TASCHENDIEB|',
  'TASCHENLAMPE|TASCHENMESSER|TASTATUR|TAU|TAUB|TAUBCHEN|TAUBE|TAUBEN|TAUCHEN|TAUCHTE|TAUFE|TAXI|TAXIFAHRER|TAXIFAHRERIN|TAXIS|TEAMKOLLEGE|TEDDYBAR|TEE|TEEKANNE|TEICH|TEICHE|TELEFON|TELEFONE|',
  'TELEFONIEREN|TELEFONIERTE|TELEKINESE|TEMPEL|TERMINAL|TERMITE*|TERRORANSCHLAG|TERRORISMUS|TERRORIST|TERRORISTEN|TERRORISTIN|TEST|TESTAMENT|TEUFEL|TEUFLISCH|THEATER|THEATERSTUCK|THRONSAAL|TIARA|TICKET|',
  'TICKETS|TIER|TIERCHEN|TIERE|TIGER*|TISCH|TISCHDECKE|TISCHE|TITAN|TITANEN|TOCHTER|TOD|TODESANGST|TODESKAMPF|TODLICH|TOILETTE|TOILETTEN|TOMATE|TOMATEN|TONLOS|TOR|TORE|TORNADO|TORTE|TORTEN|TOT|TOTAL|',
  'TOTE|TOTEN|TOTENKOPF|TOTER|TOTER KORPER|TOTET|TOTETE|TOXISCH|TRAM|TRANCE|TRANE|TRANEN|TRANK|TRANSFORMATION|TRAUBE|TRAUBEN|TRAUER*|TRAUERFEIER|TRAURIG*|TRAUUNG|TRENNUNG|TRENNUNGEN|TRENNWAND|TREPPE|',
  'TREPPEN|TREPPENHAUS|TRESOR|TRICERATOPS|TRINKE|TRINKEN|TRINKT|TRITTLEITER|TROLL|TROLLE|TROMMELFELL|TROPFSTEINHOHLE|TROST|TRUHE|TRUHEN|TRUMMER|TSUNAMI|TULPE|TULPEN|TUMMLER*|TUNNEL|TUNNELS|TUR|TUREN|',
  'TURKIS|TURKLINKE|TURM|TURME|TURMS|TURNSCHUH*|TURSCHLOSS|TURSCHWELLE|TURTELTAUBE*|TUTE|TYRANNOSAURUS|U BAHN|UBELKEIT|UBERFALL|UBERFALLEN|UBERFLUTET|UBERGLUCKLICH*|UBERMENSCHLICH*|UBERRASCH*|',
  'UBERSCHWEMMUNG|UBERSCHWEMMUNGEN|UFER|UFO|UFOS|UHR|UHREN|UHU|UHUS|ULTRASCHALL|UMARMEN|UMARMT|UMARMTE|UMARMTEN|UMARMUNG|UMARMUNGEN|UMBRINGEN|UMGEBRACHT|UMGEZOGEN|UMHANG*|UMSCHLAG|UMZIEHEN|UMZUG*|',
  'UNBEHAGEN|UNBEHAGLICH|UNBEKANNTE FRAU|UNBEKANNTER|UNBEKANNTER MANN|UNENDLICH|UNFALL|UNFALLE|UNFALLSTELLE|UNGEHEUER|UNGETUM|UNGETUME|UNGEZIEFER|UNGLAUBLICH|UNGLUCK|UNGLUCKLICH*|UNHEIMLICH*|UNIFORM|',
  'UNIFORMEN|UNIVERSITAT|UNIVERSUM|UNRUH*|UNSICHTBAR*|UNTERARM|UNTERFUHRUNG|UNTERGESCHOSS|UNTERHEMD*|UNTERHOSE*|UNTERNEHMEN|UNTERSCHREIBEN|UNTERSCHRIEB|UNTERSCHRIEBEN|UNTERSCHRIFT|UNTERWASCHE|UNTERWELT|',
  'UNTOTE|UNTOTEN|UNTOTER|UNTREU|UNTREUE|UNTROSTLICH*|UNWETTER|UNWOHL|URWALD|VAMPIR|VAMPIRE|VAMPIRIN|VATER|VATERS|VATI|VELOCIRAPTOR*|VERABREDET|VERABREDUNG|VERABREDUNGEN|VERANGSTIGT*|VERARGERT*|VERARMT|',
  'VERBARG|VERBERGEN|VERBLICHENE|VERBLUFF*|VERBORGEN|VERBORGENEN RAUM|VERBORGENES ZIMMER|VERBUNDENHEIT|VERDAMMNIS|VERDORBEN|VEREINBARUNG|VERFALLEN|VERFAULT|VERFAULTE|VERFINSTERUNG|VERFLOSSENE|',
  'VERFLOSSENER|VERFOLG*|VERFUHREN|VERFUHRER|VERFUHRERIN|VERFUHRERISCH|VERFUHRT|VERFUHRTE|VERFUHRUNG|VERGAMMELT|VERGIFTEN|VERGIFTET|VERGIFTETE|VERGIFTUNG|VERGNUG*|VERGOLDET|VERHEIRATET|VERHUNGERN|',
  'VERHUNGERT|VERIRREN|VERIRRT|VERIRRTE|VERKAUF*|VERKEHRSSTAU|VERKLEID*|VERLEGEN|VERLEGENHEIT|VERLETZT|VERLETZTE|VERLETZUNG|VERLETZUNGEN|VERLIEBE MICH|VERLIEBTE MICH|VERLIEBTE SICH|VERLIEBTEN UNS|',
  'VERLIEF MICH|VERLIERE|VERLIEREN|VERLIERT|VERLOBT|VERLOBTE|VERLOBTEN|VERLOBTER|VERLOBUNG|VERLOBUNGEN|VERLOBUNGSRING|VERLOR|VERLOREN|VERLORENE|VERLUST|VERMACHTNIS|VERMOGEN|VERNARBT|VERPRUGELN|',
  'VERPRUGELT|VERPUPPT|VERSAMMLUNG|VERSCHLAFEN|VERSCHLEPPT|VERSCHLEPPUNG|VERSCHULDET|VERSCHULDETE|VERSPATET|VERSPATETE|VERSPATUNG|VERSTECK*|VERSTEIGERUNG|VERSTORBEN|VERSTORBENE|VERSTORBENEN|VERSTORBENER|',
  'VERTRAG|VERTRAGE|VERUNGLUCKT|VERWANDELN|VERWANDELT|VERWANDELTE|VERWANDLUNG|VERWANDTE|VERWANDTEN|VERWUNDER*|VERWUNDET|VERWURZELT|VERZAUBER*|VERZAUBERT*|VERZWEIF*|VIECH*|VIER|VIERTE|VIERTEN|VIERTER|',
  'VIERTES|VILLA|VIOLETT|VIOLETTE|VIPER*|VIRUS|VOGEL|VOGELCHEN|VOGELKAFIG|VOGELSPINNE*|VOGLEIN|VOLLIG|VOLLMOND|VORAHNUNG|VORAHNUNGEN|VORAUSGESEHEN|VORGESETZTE|VORGESETZTER|VORHANGESCHLOSS|',
  'VORHANGESCHLOSSER|VORHERGESEHEN|VORHERSAGE|VORORT|VORSTADT|VORSTELLUNGSGESPRACH|VORZEICHEN|VULKAN|VULKANAUSBRUCH|VULKANE|WACHE AUF|WACHTE AUF|WACHTMEISTER|WADE|WADEN|WAFFE|WAFFEN|WAGEN|WAGGON|',
  'WAHR GEWORDEN|WAHRSAGER|WAHRSAGERIN|WAL|WALD|WALDBRAND|WALDER|WALDES|WALE|WALFISCH*|WALLFAHRT|WALZER|WAND|WANDE|WANDERRATTE*|WANDSPIEGEL|WANGE|WANGEN|WARNUNG|WARTE|WARTEN|WARTEND|WARTESCHLANGE|WARTET|',
  'WARTETE|WARTETEN|WARTEZIMMER|WASCHBECKEN|WASCHEN|WASSER|WASSERFALL|WASSERFALLE|WASSERFALLS|WASSERNIXE*|WASSERSCHILDKROTE*|WC|WEDER|WEG|WEGE|WEGGABELUNG|WEHMUT*|WEHRTE MICH|WEIDE|WEIDEN|WEIHER|',
  'WEIHWASSER|WEILER|WEIN|WEINE|WEINEN|WEINEND|WEINS|WEINT|WEINTE|WEINTEN|WEISSE|WEISSEN|WEISSER|WEISSER HAI|WEISSES|WEISSES KLEID|WEISSWEIN|WEIZEN|WELLE|WELLEN|WELLENSITTICH*|WELPE*|WELTALL|WELTKRIEG|',
  'WELTRAUM|WELTUNTERGANG*|WENDELTREPPE|WERWOLF|WERWOLFE|WERWOLFS|WESPE*|WICHTEL*|WIDDER|WIDERLICH*|WIDERSACHER|WIEDER DIESEN TRAUM|WIEDERAUFERSTEHUNG|WIEDERBELEBT|WIEDERGEBOREN|WIEDERGEBURT|WIEDERKEHR*|',
  'WIESE|WIESEN|WILDSCHWEIN*|WILDTIER*|WIMPER|WIMPERN|WIMPERNTUSCHE|WIND|WINDE|WINDIG|WINTERMANTEL*|WIRBELSAULE|WIRBELSTURM|WIRKLICH|WIRTSHAUS|WOHLGEFUHL|WOHLSTAND|WOHNUNG|WOHNUNGEN|WOLF|WOLFE|WOLFIN*|',
  'WOLFSRUDEL*|WOLKE|WOLKEN|WOLKENKRATZER|WOLKIG|WONNE|WRACK|WUNDE|WUNDEN|WUNDER|WUNDERBAR*|WUNDERHEILUNG|WUNDERSAM|WUNDERSAME|WUNDERSCHON*|WUNDERVOLL*|WURM|WURMCHEN|WURMER|WURST|WURSTCHEN|WURSTE|WURZEL|',
  'WURZELN|WUSCH|WUSSTE DASS ICH TRAUME|WUSSTE DASS ICH TRAUMTE|WUSTE|WUSTEN|WUSTENSAND|WUT|WUTEND*|YOGA|ZAHLUNGSUNFAHIG|ZAHN|ZAHNARZT|ZAHNE|ZAHNS|ZARTLICH*|ZAUBER|ZAUBEREI|ZAUBERER|ZAUBERIN|',
  'ZAUBERSPRUCH*|ZAUBERSTAB*|ZAUBERTRICK*|ZEH|ZEHE|ZEHEN|ZEHN|ZEHNTE|ZEHNTER|ZEIGEFINGER|ZEITMASCHINE*|ZEITREISE*|ZEITSCHLEIFE*|ZELLE|ZEN|ZEPTER|ZERBROCHENE GLAS|ZERBROCHENEN GLAS|ZERBROCHENES GLAS|',
  'ZERRISSENE KLEIDUNG|ZICKLEIN|ZIEGE|ZIEGEN|ZIEGENBOCK*|ZIEHBRUNNEN|ZIEHE UM|ZIFFERBLATT|ZISTERNE|ZISTERNEN|ZITTER*|ZOG UM|ZOGEN UM|ZOLL|ZOLLNER|ZOMBIE|ZOMBIES|ZOO|ZOPF|ZOPFE|ZORN*|ZU SPAT|ZUCKERWATTE|',
  'ZUG|ZUG VERPASSEN|ZUG VERPASST|ZUGE|ZUGEFROREN|ZUGFAHRT|ZUHAUSE|ZUM LEBEN ERWECKT|ZUNEIGUNG|ZUNGE|ZUNGEN|ZUNGENKUSS|ZUNGENSPITZE|ZUR BANK|ZURUCK IN DER ZEIT|ZURUCKZAHLEN|ZUSAMMENBRUCH|',
  'ZUSAMMENGEBROCHEN|ZUSAMMENPRALL|ZUSAMMENSTOSS|ZUSCHAUER|ZUTIEFST|ZUVERSICHT*|ZWEI|ZWEIG|ZWEIGE|ZWEITE|ZWEITEN|ZWEITER|ZWEITES|ZWERG*|ZWIEBEL|ZWIEBELN|ZWIELICHT|ZWILLING|ZWILLINGE|ZWILLINGSBRUDER|',
  'ZWILLINGSSCHWESTER|ZWOLF|ZWOLFTE|ZYANKALI|ZYLINDER|1|10|12|13|2|3|4|5|6|7|8|9|A SALVO|ABADIA|ABATID*|ABEJA*|ABEJORRO*|ABIERTA|ABIERTAS|ABIERTO|ABIERTOS|ABISMO|ABOCHORNAD*|ABRACE|ABRAZABA|ABRAZABAN|',
  'ABRAZADA|ABRAZADO|ABRAZAR|ABRAZO|ABRAZOS|ABRE|ABRI|ABRIA|ABRIAN|ABRIENDO|ABRIGO*|ABRIO|ABRIR|ABRO|ABUELA|ABUELAS|ABUELITA|ABUELITO|ABUELO|ABUELOS|ACANTILADO|ACANTILADOS|ACCIDENTADO|ACCIDENTE|',
  'ACCIDENTES|ACERA|ACOSABA|ACREEDOR|ACREEDORES|ACTOR|ACTRIZ|ACUATICA|ACUATICO|ACUERDO|ACURRUCADA|ACURRUCADO|ADIVINO|ADMIRACION|ADMIRADA|ADMIRADO|ADORABA|ADORABLE|ADORACION|ADORAR|ADORE|ADUANA|ADUANERO|',
  'ADULTERIO|ADVERSARIA|ADVERSARIO|AERONAVE|AEROPUERTO|AEROPUERTOS|AFECTO|AFECTUOSA|AFECTUOSO|AFEITADO|AFEITAR|AFLICCION|AFLIG*|AFONICA|AFONICO|AGENTE DE POLICIA|AGOBI*|AGONIA|AGONIZABA|AGONIZANTE|',
  'AGRADECIDA|AGRADECIDO|AGREDIDA|AGREDIDO|AGRESION|AGRESOR|AGUA|AGUA BENDITA|AGUACERO|AGUARDABA|AGUAS|AGUILA*|AHOGA*|AHOGO|AHOGUE|ALACRAN|ALACRANES|ALARMA|ALARMA DE INCENDIOS|ALARMAS|ALBA|ALBERCA|ALBUM|',
  'ALCANCIA|ALCAZAR|ALCE*|ALCOBA|ALCOHOL|ALDEA|ALDEAS|ALEGR*|ALERTA|ALERTAS|ALGODON DE AZUCAR|ALIENIGENA*|ALIGATOR*|ALIMANA*|ALIMENTO|ALIMENTOS|ALIVI*|ALJIBE|ALJIBES|ALLANAMIENTO|ALMA|ALMACEN|ALMACENES|',
  'ALMAS|ALMOHADA|ALMOHADAS|ALTA MAR|ALTAR|ALTARES|ALTILLO|AMADA|AMADAS|AMADO|AMADOS|AMANECER|AMANECERES|AMANTE|AMANTES|AMARILLA|AMARILLAS|AMARILLENTO|AMARILLO|AMARILLOS|AMEN|AMENAZA|AMENAZABA|AMENAZADA|',
  'AMENAZADO|AMENAZANTE|AMENAZAR|AMENAZAS|AMETRALLADORA|AMIGA|AMIGAS|AMIGDALAS|AMIGO|AMIGOS|AMISTAD|AMOR|AMOR A PRIMERA VISTA|AMORIO|AMORIOS|ANARANJADA|ANARANJADO|ANATOMIA|ANCIANA|ANCIANAS|ANCIANO|',
  'ANCIANOS|ANDEN|ANDENES|ANDRAJO*|ANDROIDE*|ANGEL|ANGEL DE LA GUARDA|ANGELES|ANGELICAL|ANGUSTI*|ANICOS|ANILLO|ANILLO DE COMPROMISO|ANILLOS|ANIMAL|ANIMALES|ANOCHECER|ANORAK*|ANSIEDAD|ANSIOS*|ANTEOJOS|',
  'ANTIFAZ|ANTIGUA CASA|APACIBLE|APACIBLES|APARICION|APARICIONES|APARTAMENTO|APENADA|APENADO|APERTURA|APICULTOR*|APOCALIPSIS|APOCALIPTICA|APOCALIPTICO|APRENSION|APURADA|APURADO|ARANA|ARANAS|ARANITA*|',
  'ARBOL|ARBOLEDA|ARBOLEDAS|ARBOLES|ARCA|ARCANGEL|ARCANGELES|ARCILLA|ARCO IRIS|ARCOIRIS|ARCOS IRIS|ARENA|ARENAS|ARETES|ARIDA|ARIDO|ARLEQUIN|ARMA DE FUEGO|ARMAGEDON|ARMAS DE FUEGO|ARMONIA|ARRAIGADA|',
  'ARRAIGADO|ARRIESGADO|ARROYO|ARROYOS|ARRUGA|ARRUGAS|ARRUINADA|ARRUINADO|ARSENICO|ASALTO|ASAMBLEA|ASCENSO|ASCENSOR|ASCENSORES|ASCO|ASEO|ASESINA|ASESINADA|ASESINADO|ASESINATO|ASESINATOS|ASESINO|ASOMBR*|',
  'ASQUEAD*|ASQUEROS*|ASTROLOGO|ASTRONAUTA|ASTRONAUTAS|ASUST*|ATACABA|ATACABAN|ATACADA|ATACADO|ATACANTE|ATACAR|ATACO|ATALAYA|ATAQUE|ATAQUES|ATARDECER|ATARDECERES|ATASCO|ATASCOS|ATAUD|ATAUDES|ATENTADO|',
  'ATENTADO TERRORISTA|ATENTADOS|ATERRAD*|ATERRIZAR|ATERRORIZ*|ATICO|ATLAS|ATRACO|ATRACOS|ATRAPADA|ATRAPADO|ATRAPADOS|ATRASADA|ATRASADO|ATROPELLADA|ATROPELLADO|ATUENDO*|AULA|AULLABA|AUREO|AURORA|AURORAS|',
  'AUTO|AUTOBUS|AUTOBUSES|AUTOMATA*|AUTOPISTA|AVE|AVE FENIX|AVE RAPAZ|AVENIDA|AVERGONZAD*|AVERNO|AVES|AVES RAPACES|AVION|AVIONES|AVISPA*|AZOTEA|AZUL|AZULADA|AZULADO|AZULES|BABOSA|BABOSAS|BAGUETTE|',
  'BAILABA|BAILABAN|BAILADO|BAILANDO|BAILAR|BAILARIN|BAILARINA|BAILE|BAILE DE DISFRACES|BAILO|BAJABA|BAJABAN|BAJADA|BAJADO|BAJANDO|BAJAR|BAJE|BAJO|BALAZO|BALLENA*|BALLENATO*|BALON|BALONES|BAMBALINAS|',
  'BANCARROTA|BANCO|BANCOS|BANDIDO|BANDIDOS|BANERA|BANO|BANOS|BANQUERA|BANQUERO|BANQUETE|BANQUETES|BARAJA|BARBA|BARBAS|BARBILLA|BARBUDO|BARCA|BARCO|BARCOS|BARRA DE PAN|BARRANCO|BARRANCOS|BARRER|BARRIA|',
  'BARRIGA|BARRIGAS|BARRIO|BARRIOS|BARRO|BARROTES|BASILICA|BATA|BATALLA|BATALLAS|BATAS|BAUL|BAULES|BAUTISMO|BAUTIZADO|BAUTIZO|BEBE|BEBER|BEBES|BEBIA|BEBIAN|BEBIDA|BEBIDAS|BEBIENDO|BEBIO|BENDECIA|',
  'BENDECIDO|BENDECIR|BENDICION|BENDICIONES|BENDIJO|BENDITA|BENDITO|BESABA|BESABAN|BESADO|BESAMOS|BESAR|BESARNOS|BESE|BESO|BESOS|BESTIA*|BIBLIOTECA|BICHO*|BICI|BICICLETA|BICICLETAS|BIFURCACION|BIGOTE|',
  'BIGOTES|BILLETE|BILLETERA|BILLETES DE BANCO|BISONTE*|BISTEC|BIZCOCHO|BLANCA|BLANCAS|BLANCO|BLANCOS|BLANCURA|BOA|BOAS|BOCA|BOCAS|BODA|BODAS|BODEGA|BOINA*|BOLA DE CRISTAL|BOLETO|BOLETOS|BOLSA|BOLSAS|',
  'BOLSO|BOLSOS|BOMBA|BOMBARDEO|BOMBARDEOS|BOMBAS|BOMBERO|BOMBEROS|BOMBILLA|BOMBON|BOMBONES|BOQUIABIERTA|BOQUIABIERTO|BORRACHA|BORRACHO|BOSQUE|BOSQUES|BOTA|BOTAS|BOTELLA|BOTELLAS|BOTELLIN|BOTIN|BRAGA|',
  'BRAGAS|BRASA|BRASAS|BRAZO|BRAZOS|BRILLANTE|BRINCABA|BRINCAR|BRISA|BRISAS|BRUJA|BRUJAS|BRUJERIA*|BRUJO|BRUJOS|BRUJULA|BRUJULAS|BRUMA|BRUMAS|BUCEABA|BUCEANDO|BUCEAR|BUCLE TEMPORAL|BUEY|BUEYES|BUFALO*|',
  'BUFON|BUHARDILLA|BUHO*|BUITRE*|BUQUE|BUS|BUSCA|BUSCABA|BUSCABAN|BUSCADO|BUSCANDO|BUSCAR|BUSCO|BUSQUE|BUSQUEDA|BUSQUEDA DEL TESORO|BUZON|CABALLO*|CABELLO|CABELLOS|CABEZA|CABEZAS|CABRA|CABRAS|CABRITO*|',
  'CACAO|CACHALOTE*|CACHORRO DE LEON|CACHORRO*|CADA NOCHE|CADAVER|CADAVERES|CADENA|CADENAS|CADUCADO|CAE|CAER|CAFE|CAFES|CAFETERA|CAFETERIA|CAI|CAIA|CAIAN|CAIDA|CAIDAS|CAIDO|CAIGO|CAIMAN*|CAIMANES|CAJA|',
  'CAJA FUERTE|CAJAS|CAJERO|CAJERO AUTOMATICO|CALABOZO|CALAMIDAD|CALAVERA|CALAVERAS|CALDERILLA|CALIDEZ|CALLE|CALLEJON|CALLEJUELA|CALLES|CALM*|CALVA|CALVO|CALZONCILLO*|CALZONES|CAMA|CAMARA|CAMARERA|',
  'CAMARERO|CAMAS|CAMINO|CAMINO DE SANTIAGO|CAMINOS|CAMISA*|CAMORRA|CAMPO|CAMPO DE BATALLA|CAMPOS|CAMPOSANTO|CANARIO*|CANAS|CANCER|CANCION|CANCIONES|CANDADO|CANDADOS|CANDELABRO|CANDIDATA|CANDIDATO|',
  'CANTABA|CANTABAN|CANTADO|CANTANDO|CANTANTE|CANTAR|CANTE|CANTINA|CANTO|CAPA|CAPAS|CAPELLAN|CAPILLA|CAPILLAS|CAPTOR|CAPTORES|CAPUCHA*|CARA|CARACOL|CARACOLES|CARACOLITO|CARAMELO|CARAMELOS|CARAS|',
  'CARCAJADA*|CARCEL|CARCELES|CARETA|CARINO|CARINOSA|CARINOSAMENTE|CARINOSO|CARMESI|CARNAVAL*|CARNE|CARNERO*|CARNES|CARNICERIA|CARNICERO|CARRERA|CARRETERA|CARRETERAS|CARRO|CARRONA|CARTA|CARTAS|CARTERA|',
  'CARTERISTA|CARTERO|CASA|CASA DE LA INFANCIA|CASA DE MI INFANCIA|CASA DE MIS ABUELOS|CASA DE MIS PADRES|CASA EMBRUJADA|CASA FAMILIAR|CASA NATAL|CASABA|CASABAN|CASADA|CASADO|CASADOS|CASARME|CASARSE|',
  'CASAS|CASCADA|CASCADAS|CASCARON|CASTILLO|CASTILLOS|CATACLISMO|CATACUMBAS|CATARATA|CATARATAS|CATASTROFE|CATASTROFES|CATASTROFICO|CATEDRAL|CATEDRALES|CAUTIVA|CAUTIVERIO|CAUTIVO|CAVERNA|CAVERNAS|CAYENDO|',
  'CAYO|CAZADORA*|CEBOLLA|CEBOLLAS|CEGADO|CEGUERA|CELDA|CELEBRACION|CELEBRIDAD|CELEBRIDADES|CELESTE|CELESTIAL|CELOS|CELOSA|CELOSO|CELULAR|CEMENTERIO|CEMENTERIOS|CENTIMO|CENTIMOS|CENTRO COMERCIAL|',
  'CENTRO DE LA CIUDAD|CERDIT*|CERDO*|CEREZA|CEREZAS|CERRADURA|CERRADURAS|CERROJO|CERVATILLO*|CERVEZA|CERVEZAS|CESPED|CHAMAN|CHAMANES|CHAMPAN|CHANCHO*|CHANCLA*|CHANTAJE|CHAQUETA*|CHARCO|CHARCO DE SANGRE|',
  'CHARCOS|CHILLABA|CHILLAR|CHIMPANCE*|CHIQUILLA|CHIQUILLO|CHISTERA*|CHIVO*|CHOCO|CHOCOLATE|CHOCOLATES|CHOCOLATINA|CHOQUE|CHOQUES|CHUBASQUERO*|CHUCHE|CHUCHES|CHUCHO*|CIANURO|CIBORG*|CICATRICES|CICATRIZ|',
  'CICATRIZADA|CICATRIZADO|CICLON|CIEGA|CIEGAS|CIEGO|CIEGOS|CIELO|CIELOS|CIENAGA|CIENAGAS|CIERVO*|CIMA|CINCO|CIRCULAR|CIRCULO|CIRCULOS|CIRIO|CIRIOS|CIRUJANA|CIRUJANO|CISNE|CISNE NEGRO|CISNES|CISTERNA|',
  'CISTERNAS|CITA|CITA A CIEGAS|CITA ROMANTICA|CITAS|CIUDAD|CIUDADELA|CIUDADES|CLARIDAD|CLARIVIDENTE|CLAUSULA|CLAVADA|CLAVADO|CLINICA|COCHE|COCHE FUNEBRE|COCHES|COCHINO*|COCINA|COCINAS|COCODRILO*|CODO|',
  'CODOS|COFRE|COFRE DEL TESORO|COFRES|COLAPSO|COLCHON|COLEGA|COLEGAS|COLEGIO|COLERA|COLINA|COLINAS|COLISION|COLLAR|COLMENA*|COLMILLO|COLMILLOS|COLORETE*|COLOSO|COLOSOS|COLUMNA VERTEBRAL|COMBATE|COMER|',
  'COMIA|COMIAN|COMIDA|COMIDAS|COMIENDO|COMIO|COMISARIO|COMPANERA DE TRABAJO|COMPANERO DE TRABAJO|COMPANEROS DE TRABAJO|COMPAS|COMPASION|COMPINCHE|COMPLETAMENTE|COMPLICIDAD|COMPRA|COMPRABA|COMPRABAN|',
  'COMPRADO|COMPRANDO|COMPRAR|COMPRAS|COMPRE|COMPRO|COMPROMISO|COMPUTADORA|COMPUTADORAS|CON RETRASO|CONCUBINA|CONDENACION|CONDUCIA|CONDUCIR|CONEJIT*|CONEJO*|CONFERENCIA|CONFIANZA|CONGELADA|CONGELADO|',
  'CONGOJA|CONJURO*|CONMOVID*|CONSCIENTE DE ESTAR SONANDO|CONSCIENTE DE QUE SONABA|CONSOLADA|CONSOLADO|CONSTELACION|CONSTRUCCION|CONSTRUI|CONSTRUIA|CONSTRUIAN|CONSTRUIDA|CONSTRUIDO|CONSTRUIR|',
  'CONSTRUYENDO|CONSTRUYO|CONSUELO|CONTENTA|CONTENTAS|CONTENTO|CONTENTOS|CONTRATADA|CONTRATADO|CONTRATO|CONTRATOS|CONTROLABA EL SUENO|CONTROLAR EL SUENO|CONVENTO|CONVERTIRSE EN|CONYUGE|COPA DE VINO|',
  'COPOS DE NIEVE|COQUETEABA|COQUETEAR|COQUETEO|CORAZON|CORAZONES|CORCEL*|CORDEL|CORDERO*|CORNEJA*|CORO|CORONA|CORONACION|CORONADA|CORONADO|CORONAS|CORPORAL|CORRE|CORREDOR|CORREDORES|CORREN|CORREO|',
  'CORRER|CORRI|CORRIA|CORRIAN|CORRIDA*|CORRIDO|CORRIENDO|CORRIO|CORRO|CORZO*|COSECHA|COSECHAS|COSMOS|COSTA|COSTAS|CRANEO|CRATER|CRATERES|CREDITO|CREPUSCULO|CREPUSCULOS|CRIATURA|CRIATURAS|CRIMEN|CRIPTA|',
  'CRISALIDA|CRISALIDA*|CRISTAL ROTO|CRISTALES ROTOS|CRISTO|CRUCE|CRUCERO|CRUCES|CRUCIFICADO|CRUCIFIJO|CRUCIFIXION|CRUZ|CUARTA|CUARTO LUGAR|CUARTO OCULTO|CUARTO SECRETO|CUATRO|CUBICULO|CUCARACHA|',
  'CUCARACHAS|CUCARACHITA|CUCHILLA|CUCHILLO|CUCHILLOS|CUELLO|CUELLOS|CUENTA BANCARIA|CUERDA|CUERDAS|CUERNO DE UNICORNIO|CUERPO|CUERPO SIN VIDA|CUERPOS|CUERVO*|CUEVA|CUEVAS|CULEBRA*|CULPA|CULPABLE|',
  'CULPABLES|CUMBRE|CUMBRES|CUNADA|CUNADO|CURIOSA|CURIOSIDAD|CURIOSO|CURRICULUM|DABA A LUZ|DAGA|DANZA|DAR A LUZ|DAR VUELTAS|DE COMPRAS|DE NUEVO ESTE SUENO|DE ORO|DE SUS CENIZAS|DEBIA DINERO|DECENA|',
  'DECIMA|DECIMO|DECIMOTERCERO|DEDALO|DEDO|DEDOS|DEDOS DE LOS PIES|DEJA VU|DELANTAL*|DELFIN|DELFINES|DEMASIADO|DEMASIADO TARDE|DEMONIACO|DEMONIO|DEMONIOS|DENTADURA|DENTISTA|DEPOSITO DE CADAVERES|',
  'DEPRESION|DEPRIMID*|DERRUIDO|DERRUMBABA|DERRUMBADA|DERRUMBADO|DERRUMBARSE|DERRUMBE|DERRUMBES|DESARRAIGADO|DESASOSIEGO|DESASTRE|DESASTRES|DESCALZA|DESCALZO|DESCENDER|DESCENDI|DESCENDIA|DESCENSO|',
  'DESCONOCIDA|DESCONOCIDAS|DESCONOCIDO|DESCONOCIDOS|DESCONSOLAD*|DESCUBIERTO|DESCUBRI|DESCUBRIO|DESCUBRIR|DESDICH*|DESEMPLEADA|DESEMPLEADO|DESEMPLEO|DESESPER*|DESFILADERO|DESIERTO|DESIERTOS|DESLUMBR*|',
  'DESMORONARSE|DESNUDA|DESNUDAS|DESNUDEZ|DESNUDO|DESNUDOS|DESOLACION|DESOLAD*|DESORIENTADA|DESORIENTADO|DESPACHO|DESPEDIDO|DESPEGAR|DESPEGUE|DESPERTABA|DESPERTADA|DESPERTADO|DESPERTANDO|DESPERTAR|',
  'DESPERTARME|DESPERTE|DESPERTO|DESPIDIERON|DESPIDO|DESPIERTO|DESPLOME|DESVALIJADO|DESVAN|DETECTOR DE HUMO|DETONACION|DEUDA|DEUDAS|DEVOCION|DIABLO|DIABLOS|DIABOLICA|DIABOLICO|DIADEMA|DIAMANTE|DIAMANTES|',
  'DICHOSA|DICHOSAS|DICHOSO|DICHOSOS|DIENTE|DIENTES|DIEZ|DIFUNTA|DIFUNTAS|DIFUNTO|DIFUNTOS|DILUVIO|DINAMITA|DINERO|DINO|DINOSAURIO*|DIO A LUZ|DIOS|DIOSA|DIOSAS|DIOSES|DIRECTOR|DIRECTORA|DISFRACES|',
  'DISFRAZ|DISFRAZAD*|DISFRAZARME|DISFRAZARSE|DISPARO|DISPAROS|DIVINA|DIVINIDAD|DIVINO|DIVORCIADA|DIVORCIADO|DIVORCIADOS|DIVORCIARNOS|DIVORCIARSE|DIVORCIO|DIVORCIOS|DOCE|DOCENA|DOCENAS|DOCTOR|DOCTORA|',
  'DOLARES|DOLOR DE CABEZA|DOLOR DE ESPALDA|DORADA|DORADAS|DORADO|DORADOS|DORMITORIO|DORMITORIOS|DOS|DRACULA|DRAGON|DRAGONCITO|DRAGONES|DUCHA|DUCHAS|DUENDE*|DUNA|DUNAS|DUODECIMO|EBRIO|',
  'ECHARON DEL TRABAJO|ECLIPSADA|ECLIPSADO|ECLIPSE|ECLIPSES|ECOGRAFIA|EDEN|EDIFICABA|EDIFICAR|EFECTIVO|EL MAS ALLA|ELEFANTE|ELEFANTES|ELEFANTITO|ELEVADOR|ELEVADORES|ELFO|ELFOS|EMBARAZADA|EMBARAZADAS|',
  'EMBARAZO|EMBARAZOS|EMBARRADO|EMBELESAD*|EMBOSCADA|EMBOTELLAMIENTO|EMBRUJADA|EMBRUJADO|EMOCIONAD*|EMPERADOR|EMPERATRIZ|EMPLEADOR|EMPLEO|EMPOLLAR|EMPRESA|EN CUEROS|EN EL PARO|EN LLAMAS|EN MAL ESTADO|',
  'EN PELIGRO|EN SUS BRAZOS|ENAMORADA|ENAMORADO|ENAMORADOS|ENAMORARME|ENAMORARSE|ENANO|ENANOS|ENCADENADA|ENCADENADO|ENCANTAD*|ENCANTAMIENTO*|ENCERRABA|ENCERRADA|ENCERRADO|ENCERRADOS|ENCERRAR|ENCINTA|',
  'ENCONTRADA|ENCONTRADO|ENCONTRAR|ENCONTRE|ENCONTRO|ENCRUCIJADA|ENDEUDADA|ENDEUDADO|ENEMIGA|ENEMIGAS|ENEMIGO|ENEMIGOS|ENFAD*|ENFERMA|ENFERMAS|ENFERMEDAD|ENFERMEDADES|ENFERMERA|ENFERMERAS|ENFERMERO|',
  'ENFERMO|ENFERMOS|ENJAMBRE*|ENJAULADO|ENMASCARADO|ENOJ*|ENRAIZADO|ENSANGRENTADA|ENSANGRENTADO|ENTERRADA|ENTERRADO|ENTERRAR|ENTERRO|ENTIERRO|ENTIERROS|ENTRARON A ROBAR|ENTREVISTA|ENTREVISTA DE TRABAJO|',
  'ENTREVISTADOR|ENTREVISTADORA|ENTREVISTAS|ENTUSIASM*|ENVEJECER|ENVEJECIA|ENVEJECIDA|ENVEJECIDO|ENVEJECIMIENTO|ENVENENADA|ENVENENADO|ENVENENAMIENTO|ENVENENAR|EPIDEMIA|EQUIPAJE|ERMITANO|EROTICA|EROTICO|',
  'ERUPCION|ERUPCIONES|ESCALABA|ESCALANDO|ESCALAR|ESCALE|ESCALERA|ESCALERA DE MANO|ESCALERA MECANICA|ESCALERAS|ESCALERILLA|ESCALINATA|ESCALO|ESCALOFRI*|ESCALONES|ESCAPABA|ESCAPANDO|ESCAPAR|ESCAPE|ESCAPO|',
  'ESCARABAJO*|ESCARLATA|ESCENARIO|ESCENARIOS|ESCOMBROS|ESCOND*|ESCOPETA|ESCORPION|ESCORPIONES|ESCRIBE|ESCRIBI|ESCRIBIA|ESCRIBIAN|ESCRIBIENDO|ESCRIBIO|ESCRIBIR|ESCRIBO|ESCRITA|ESCRITO|ESCRITORIO|',
  'ESCRITURA|ESCUALO*|ESCUELA|ESCUELAS|ESLABON|ESMALTE DE UNAS|ESMERALDA|ESPACIO|ESPADA|ESPADAS|ESPALDA|ESPALDAS|ESPANT*|ESPECTRO|ESPECTROS|ESPEJO|ESPEJOS|ESPERA|ESPERABA|ESPERABAN|ESPERADO|ESPERANDO|',
  'ESPERAR|ESPERE|ESPERO|ESPIRAL|ESPIRALES|ESPIRITU|ESPIRITUS|ESPLENDID*|ESPOSA|ESPOSAS|ESPOSO|ESPOSOS|ESPRESSO|ESQUELETO|ESQUELETOS|ESQUIRLAS|ESTABA PERDIDA|ESTABA PERDIDO|ESTACION|ESTACION DE METRO|',
  'ESTACION DE TREN|ESTALLAR|ESTALLO|ESTANQUE|ESTANQUES|ESTOMAGO|ESTOQUE|ESTRELLA|ESTRELLA DE CINE|ESTRELLA FUGAZ|ESTRELLADA|ESTRELLADO|ESTRELLARSE|ESTRELLAS|ESTRES|ESTRESAD*|ESTUFA|ESTUPEFACT*|EUFORI*|',
  'EUROS|EVACUACION|EVACUADO|EVACUAR|EVACUARON|EX|EX ESPOSA|EX ESPOSO|EX MARIDO|EX NOVIA|EX NOVIO|EX PAREJA|EXAMEN|EXAMENES|EXASPERAD*|EXNOVIA|EXNOVIO|EXPLOSION|EXPLOSIONES|EXPLOSIVO|EXPLOSIVOS|',
  'EXPLOTABA|EXPLOTAR|EXPLOTO|EXPRESO|EXTASIS|EXTRATERRESTRE|EXTRATERRESTRES|EXTRAVIADA|EXTRAVIADO|EXTREMADAMENTE|EXULTANTE|FAJO DE BILLETES|FALDA*|FALLECIDA|FALLECIDO|FALLECIDOS|FALSO DESPERTAR|FAMILIA|',
  'FAMILIAS|FAMOSA|FAMOSAS|FAMOSO|FAMOSOS|FANGO|FANTASMA|FANTASMAS|FAROL|FAROLA|FASCIN*|FELICES|FELICIDAD|FELINO*|FELIZ|FENIX|FERETRO|FERETROS|FERROCARRIL|FESTIN|FESTINES|FIEBRE|FIERA*|FIESTA|FIESTAS|',
  'FILETE|FILETES|FIN DE LOS TIEMPOS|FIN DEL MUNDO|FINADA|FINADO|FIRMA|FIRMABA|FIRMADO|FIRMAMENTO|FIRMAR|FIRME|FIRMO|FLECHAZO|FLOR|FLORES|FLORETE|FLORIDA|FLORIDO|FLOTABA EN EL AIRE|FOGATA|FOLLAJE|',
  'FORASTERA|FORASTERO|FORTALEZA|FORTUNA|FOTO|FOTOGRAFIA|FOTOGRAFIAS|FOTOS|FRAILE|FRASCO|FRASCOS|FREGABA|FREGADERO|FRENABA|FRENAR|FRENO|FRENOS|FRESA|FRESAS|FRONTERA|FRONTERAS|FRUSTR*|FRUTA|FRUTAS|FRUTO|',
  'FRUTOS|FUEGO|FUEGOS|FUENTE|FUENTES|FUERA DEL CUERPO|FUERZA SOBREHUMANA|FUGA|FUMAR|FUNERAL|FUNERALES|FURIA|FURIOS*|FUSIL|GABARDINA*|GAFAS|GAFAS DE SOL|GALAPAGO*|GALAXIA|GALAXIAS|GALERIA|GALLINA*|',
  'GALLINERO*|GALLO|GALLOS|GAMO|GAMOS|GARGANTA|GARGANTAS|GARRAFA|GATA|GATAS|GATITA*|GATITO*|GATO|GATOS|GAVILAN*|GAZAPO*|GEMA|GEMELA|GEMELAS|GEMELO|GEMELOS|GENTIO|GERENTE|GIGANTA|GIGANTE|GIGANTES|GLACIAR|',
  'GLACIARES|GLOBO|GLOBOS|GNOMO*|GOLONDRINA*|GOLOSINA|GOLOSINAS|GOLPIZA|GORILA*|GORRA*|GORRION*|GORRO*|GOZABA|GOZO|GOZOSA|GOZOSO|GPS|GRAJO*|GRATITUD|GRILLETES|GRILLO*|GRIPE|GRIS|GRISACEA|GRISACEO|GRISES|',
  'GRITABA|GRITABAN|GRITADO|GRITANDO|GRITAR|GRITE|GRITO|GRITOS|GRIZZLY|GRUTA|GRUTAS|GUARDIA CIVIL|GUEPARDO*|GUERRA|GUERRA MUNDIAL|GUERRAS|GUERRERO|GUERREROS|GUIA ESPIRITUAL|GUIJARRO|GUIJARROS|GURU|',
  'GUSAN*|HABITACION|HABITACION OCULTA|HABITACION SECRETA|HABITACIONES|HACER EL AMOR|HACERSE VIEJO|HACIENDO EL AMOR|HADA|HADA MADRINA|HADAS|HADITA*|HALCON*|HALLAR|HALLAZGO|HALLE|HALLO|HAMBRE|HAMBRIENTA|',
  'HAMBRIENTO|HAMBRUNA|HAMBRUNAS|HAMSTER*|HARAPOS|HECHICERA*|HECHICERO*|HECHIZAD*|HECHIZADA|HECHIZADO|HECHIZO*|HELADA|HELADO|HELADOS|HEMORRAGIA|HEREDADO|HEREDAR|HEREDE|HEREDERA|HEREDERO|HEREDEROS|HEREDO|',
  'HERENCIA|HERENCIAS|HERIDA|HERIDAS|HERIDO|HERIDOS|HERMANA|HERMANAS|HERMANITA|HERMANITO|HERMANO|HERMANOS|HIBRIDO|HIBRIDOS|HICIMOS EL AMOR|HIDRA|HIELO|HIELOS|HIERBA|HIERBAS|HIJA|HIJAS|HIJO|HIJOS|',
  'HIPOTECA|HOGAR|HOGUERA|HOGUERAS|HOJA|HOJARASCA|HOJAS|HOMBRE LOBO|HOMBRES LOBO|HOMBRO|HOMBROS|HOMICIDIO|HORMIGA|HORMIGAS|HORMIGUERO|HORMIGUEROS|HORMIGUITA|HORNO|HORRIBLE|HORRIBLES|HORROR|HORRORES|',
  'HORRORIZ*|HORTALIZA|HORTALIZAS|HOSPITAL|HOSPITALES|HOSPITALIZADA|HOSPITALIZADO|HOSTAL|HOSTIL|HOSTILIDAD|HOTEL|HOTELES|HUCHA|HUERTA|HUERTO|HUERTOS|HUESO|HUESOS|HUEVO|HUEVOS|HUI|HUIA|HUIAN|HUIDA|HUIDO|',
  'HUIR|HUMAREDA|HUMEABA|HUMEANTE|HUMILL*|HUMO|HUMOS|HUNDIMIENTO|HURACAN|HURACANES|HUYENDO|HUYO|ICEBERG|IGLESIA|IGLESIAS|IMPERMEABLE*|INCENDIADA|INCENDIADO|INCENDIO|INCENDIO FORESTAL|INCENDIOS|INCOMOD*|',
  'INCREIBLEMENTE|INDIGENTE|INDIGN*|INFANTA|INFARTO|INFECCION|INFELICES|INFELIZ|INFERNAL|INFIDELIDAD|INFIDELIDADES|INFIEL|INFIELES|INFIERNO|INFIERNOS|INFRAMUNDO|INMOVIL|INODORO|INQUIET*|INSECTO*|',
  'INSEGURIDAD|INSOLVENTE|INSTITUTO|INTERNET|INTERSECCION|INTIMIDACION|INTRANQUIL*|INTRIGAD*|INTRUSO|INUNDACION|INUNDACIONES|INUNDADA|INUNDADO|INVASION|INVASORES|INVISIBILIDAD|INVISIBLE|INVISIBLES|IRA|',
  'IRIDISCENTE|IRIS|IRRIT*|ISLA|ISLA DESIERTA|ISLAS|ISLOTE|ISLOTES|JABALI*|JAGUAR*|JAMAS|JAMON|JAQUECA|JARDIN|JARDIN DEL EDEN|JARDINERO|JARDINES|JAULA|JAULAS|JEFA|JEFE|JEFES|JESUS|JOYA|JOYAS|JUBILO|',
  'JUGUETE|JUGUETES|JUICIO FINAL|JUNGLA|JUNGLAS|JUNTA|KAMIKAZE|KARMA|LA PARCA|LABERINTO|LABERINTOS|LABIO|LABIOS|LACTANTE|LACTEA|LACTEO|LADRON|LADRONA|LADRONES|LAGO|LAGOS|LAGRIMA|LAGRIMAS|LAGUNA|LAGUNAS|',
  'LAMPARA|LAMPARAS|LAPIDA|LAPIDAS|LAPIZ LABIAL|LARVA*|LAS UNAS|LATIDO|LATIDOS|LAVA|LAVABA|LAVABO|LAVAR|LAVE|LAZO|LECHE|LECHERA|LECHERO|LECHES|LECHO DE MUERTE|LECHUGA|LECHUZA*|LEER|LEGADO|LENCERIA|',
  'LENGUA|LENGUAS|LENTES|LENTES DE CONTACTO|LENTILLAS|LEON|LEONA|LEONAS|LEONES|LEOPARDO*|LESION|LESIONES|LETRINA|LEVITABA|LEVITAR|LIBERACION|LIBERADA|LIBERADO|LIBRO|LIBROS|LICANTROPIA|LICANTROPO*|LICOR|',
  'LIEBRE*|LIGABA|LIGAR|LILA|LIMPIABA|LIMPIABAN|LIMPIADO|LIMPIANDO|LIMPIAR|LIMPIE|LIMPIEZA|LIMPIO|LINGOTE|LINGOTES|LINTERNA|LINTERNAS|LIRIO|LITERA|LLAMADA|LLAMADAS|LLAMARADA|LLAMARADAS|LLANTO|LLAVE|',
  'LLAVE MAESTRA|LLAVERO|LLAVES|LLEGABA TARDE|LLEGO TARDE|LLEGUE TARDE|LLORABA|LLORABAN|LLORADO|LLORANDO|LLORAR|LLORE|LLORO|LLOVER|LLOVIA|LLOVIZNA|LLUEVE|LLUVIA|LLUVIAS|LOBA|LOBAS|LOBEZNO*|LOBO|LOBOS|',
  'LOCOMOTORA|LODO|LODOS|LOMBRICES|LOMBRIZ|LORO|LOROS|LOTERIA|LUCERO|LUCES|LUCHABA|LUCHABAN|LUCHAR|LUCHE|LUCHO|LUCIDA|LUCIDO|LUCIFER|LUJO|LUJOSA|LUJOSO|LUMINOSA|LUMINOSO|LUNA|LUNA LLENA|LUNAS|LUTO|LUZ|',
  'LUZ DE LUNA|MACACO*|MACHO CABRIO|MADRASTRA|MADRE|MADRES|MADRUGADA|MAESTRA|MAESTRO|MAESTRO ESPIRITUAL|MAESTROS|MAGIA|MAGICA|MAGICO|MAGMA|MAGNIFIC*|MAGO|MAGOS|MALESTAR|MALETA|MALETAS|MAMA|MAMUT|MAMUTS|',
  'MANADA DE LOBOS|MANANTIAL|MANANTIALES|MANDALA|MANDIBULA|MANEJAR|MANICURA|MANO|MANOS|MANSION|MANTEL|MANTRA|MANZANA|MANZANAS|MANZANO|MANZANOS|MAPA|MAPA DEL TESORO|MAPAS|MAQUILLAD*|MAQUILLAJE*|',
  'MAQUILLARME|MAQUILLARSE|MAQUINA DEL TIEMPO|MAR|MARAVILL*|MARCIANO|MARCIANOS|MAREA|MAREAS|MAREMOTO|MARES|MARGARITA|MARIDO|MARIDOS|MARIONETA|MARIONETAS|MARIPOSA*|MARIQUITA*|MARRANO*|MARSOPA*|MARTES 13|',
  'MASCARA|MASCARAS|MATA|MATABA|MATADO|MATAR|MATO|MATRIMONIO|MAUSOLEO|ME DI CUENTA DE QUE ESTABA SONANDO|ME DI CUENTA DE QUE SONABA|ME ENAMORABA|ME ENAMORE|ME ENGANABA|ME ENGANO|ME MUDABA|ME MUDE|',
  'ME PERDI|ME PERDIA|ME SEGUIA|MECA|MEDIANOCHE|MEDICA|MEDICO|MEDICOS|MEDITA|MEDITABA|MEDITACION|MEDITANDO|MEDITAR|MEDITO|MEJILLA|MEJILLAS|MEJOR AMIGA|MEJOR AMIGO|MELANCOL*|MELENA|MELLIZO|MELLIZOS|',
  'MELOSA|MELOSO|MENDIGA|MENDIGABA|MENDIGAR|MENDIGO|MENIQUE|MESA|MESAS|MESERO|MESITA|METAMORFOSIS|METRO|METROPOLI|MEZQUITA|MEZQUITAS|MI DOBLE|MI MUJER|MIED*|MIEL|MIELES|MILAGRO|MILAGROS|MILAGROSA|',
  'MILAGROSAMENTE|MILAGROSO|MILITAR|MILITARES|MILLONARIA|MILLONARIO|MININO*|MIS UNAS|MISA|MISERIA|MISMO SUENO|MOCHILA|MOCHUELO*|MOHO|MOHOSA|MOHOSO|MOLEST*|MONARCA|MONASTERIO|MONEDA|MONEDAS|',
  'MONEDAS DE ORO|MONEDERO|MONITO*|MONJA|MONJAS|MONJE|MONJES|MONO|MONO DE TRABAJO|MONOCULO*|MONOS|MONSTRUO|MONSTRUOS|MONSTRUOSA|MONSTRUOSO|MONTACARGAS|MONTANA|MONTANAS|MONTE|MONTES|MORADA|MORADO|MORATON|',
  'MORGUE|MORI|MORIA|MORIAN|MORIBUNDO|MORIR|MORTAL|MOSCA|MOSCARDON*|MOSCAS|MOSCON*|MOSQUITO*|MOTEL|MOTO|MOTOCICLETA|MOTOCICLETAS|MOTOS|MOVIL|MUCHEDUMBRE|MUDA|MUDADO|MUDANZA|MUDANZAS|MUDARME|MUDARNOS|',
  'MUDARSE|MUDO|MUDOS|MUELA|MUELAS|MUERE|MUEREN|MUERO|MUERTA|MUERTAS|MUERTE|MUERTES|MUERTO|MUERTO VIVIENTE|MUERTOS|MUERTOS VIVIENTES|MUJER PEZ|MULTITUD|MULTITUDES|MUNECA|MUNECAS|MUNECO|MUNECOS|MURALLA|',
  'MURALLAS|MURCIELAGO|MURCIELAGOS|MURCIELAGUITO|MURIENDO|MURIO|MURO|MUROS|MUSLO|MUSLOS|MUTACION|MUTANTE|MUTANTES|MUY|NACER|NACI|NACIDA|NACIDO|NACIMIENTO|NACIMIENTOS|NACIO|NADABA|NADABAN|NADADO|NADANDO|',
  'NADAR|NADE|NADIE ME VEIA|NADIE PODIA VERME|NADO|NAIPES|NARANJA|NARANJAS|NARICES|NARIZ|NAUFRAGAR|NAUFRAGIO|NAUFRAGO|NAUSEA|NAUSEAS|NAVAJA|NAVAJAS|NAVEGAR|NEBLINA|NECROPOLIS|NECTAR|NEGRA|NEGRAS|NEGRO|',
  'NEGROS|NEGRURA|NENA|NENE|NERVIOS*|NEVABA|NEVADA|NEVADO|NEVAR|NEVERA|NI|NIEBLA|NIEBLAS|NIEVA|NIEVE|NIEVES|NINA|NINAS|NINGUN|NINGUNA|NINGUNO|NINO|NINOS|NIRVANA|NO|NO MUERTO|NO PODIA MOVER|',
  'NO PODIA MOVERME|NO PODIA SALIR|NOCHE|NOCHES|NOS ENAMORAMOS|NOS MUDAMOS|NOSTALGI*|NOTARIO|NOVELA|NOVELAS|NOVENA|NOVENO|NOVIA|NOVIAS|NOVIO|NOVIOS|NUBARRON|NUBARRONES|NUBE|NUBES|NUBLADA|NUBLADO|NUCA|',
  'NUDO|NUDOS|NUEVE|NUMERO UNO|NUNCA|OBISPO|OBSEQUIO|OCASO|OCEANO|OCEANOS|OCHO|OCTAVA|OCTAVO|OCULTABA|OCULTANDOME|OCULTARME|ODIABA|ODIAR|ODIE|ODIO|OFICINA|OFICINAS|OFICIO|OFRENDA|OFRENDAS|OGRO|OGROS|OJO|',
  'OJO DE AGUA|OJO DE LA CERRADURA|OJOS|OLA|OLAS|OLEAJE|OLFATO|OMBLIGO|ONDINA*|OPOSICIONES|ORACION|ORACIONES|ORANGUTAN*|ORAR|ORCA|ORCAS|ORDENADOR|ORDENADORES|OREJA|OREJAS|ORGASMO|ORGULL*|ORILLA|ORILLAS|',
  'ORO|ORO MACIZO|ORQUIDEA|ORUGA*|OSA|OSCURA|OSCURIDAD|OSCURO|OSEZNO*|OSITO DE PELUCHE|OSITO*|OSO|OSOS|OTRA VEZ ESE SUENO|OTRA VEZ ESTE SUENO|OVEJA*|OVNI|OVNIS|PACTO|PADRASTRO|PADRE|PADRE Y MADRE|PADRES|',
  'PAGABA|PAGAR|PAGO|PAGODA|PAGUE|PAJARITO*|PAJARO DE FUEGO|PAJARO*|PALACIO|PALACIO REAL|PALACIOS|PALIZA|PALIZAS|PALMA|PALMAS|PALOMA*|PAN|PANADERIA|PANADERO|PANES|PANICO|PANTALLA|PANTALON*|PANTALONES|',
  'PANTANO|PANTANOS|PANTEON|PANTERA*|PANTORRILLA|PANTUFLA*|PAPA|PAPILAS|PARADA DE AUTOBUS|PARADISIACO|PARAGUAS|PARAISO|PARALISIS|PARALIZ*|PARASOL|PARED|PAREDES|PAREJA|PAREJAS|PARIENTES|PARIR|PARPADO|',
  'PARPADOS|PARQUE|PARQUES|PARROCO|PARROQUIA|PARTO|PASADIZO SECRETO|PASAJE|PASAPORTE|PASAPORTES|PASARELA|PASILLO|PASILLOS|PASMAD*|PASO SUBTERRANEO|PASTEL|PASTELES|PASTO|PASTOR|PASTOS|PATATA|PATATAS|',
  'PATRON|PATRONA|PAVO REAL|PAVOR*|PAVORREAL*|PAVOS REALES|PAYASA|PAYASO|PAYASOS|PAZ|PECA|PECAS|PECECILLO*|PECECITO*|PECES|PECIO|PEDALEABA|PEDALEAR|PEDICURA|PEDIDA DE MANO|PEINADO|PELDANO|PELDANOS|PELEA|',
  'PELEA CALLEJERA|PELEABA|PELEABAN|PELEANDO|PELEAR|PELEAS|PELEE|PELEO|PELIGRO|PELIGROS|PELIGROSA|PELIGROSO|PELIGROSOS|PELO|PELOTA|PELOTAS|PELUCA|PELUCHE|PENA|PENAS|PENASCO|PENDULO|PEPITA|PEPITAS|PERA|',
  'PERAS|PERDER|PERDER EL AUTOBUS|PERDER EL AVION|PERDER EL TREN|PERDERME|PERDI|PERDI EL AUTOBUS|PERDI EL AVION|PERDI EL TREN|PERDI EL VUELO|PERDIA|PERDIA EL TREN|PERDIAN|PERDIDA|PERDIDO|PERDIDOS|',
  'PERDIENDO|PERDIO|PEREGRINA|PEREGRINACION|PEREGRINAJE|PEREGRINO|PEREGRINOS|PERIQUITO*|PERLA|PERLAS|PERR*|PERSECUCION|PERSEGU*|PERSIANA|PERSIG*|PESADILLA|PESADILLAS|PESTANA|PESTANAS|PETALO|PETALOS|',
  'PETRIFICAD*|PETRIFICADA|PETRIFICADO|PEZ|PEZ DE COLORES|PICAPORTE|PICHON*|PIE|PIEDRA|PIEDRAS|PIEL|PIELES|PIERDE|PIERDO|PIERNA|PIERNAS|PIES|PINO|PINOS|PINTALABIOS|PIROMANO|PIRULETA|PISCINA|PISCINAS|',
  'PISTA DE ATERRIZAJE|PISTOLA|PISTOLAS|PITON|PITONES|PITONISA|PLANEABA|PLANEAR|PLANETA|PLANETAS|PLANO|PLATA|PLATANO|PLATANOS|PLATILLO VOLANTE|PLAYA|PLAYAS|PLENITUD|POBRE|POBRES|POBREZA|PODRIDA|PODRIDO|',
  'PODRIDOS|POLICIA|POLICIAL|POLICIAS|POLILLA*|POLLITO*|POLLUELO*|POLTERGEIST|PONI|PONIS|PONTIFICE|PORTAL|PORTATIL|PORTON|POSADA|POSEIDA|POSEIDO|POSTRE|POSTRES|POTRILL*|POTRO*|POZO|POZOS|PRADERA|',
  'PRADERAS|PRADO|PRADOS|PRECIOSA|PRECIOSO|PRECIPICIO|PREDICCION|PREMIO GORDO|PREMONICION|PREMONICIONES|PREMONITORIA|PREMONITORIO|PRENDA*|PREOCUP*|PRESAGIO|PRESAGIOS|PRESENTACION|PRESENTIMIENTO|PRESO|',
  'PRESTAMO|PRESTAMOS|PRIMA|PRIMAS|PRIMERA|PRIMERA CITA|PRIMERAS|PRIMERO|PRIMEROS|PRIMO|PRIMOS|PRINCESA|PRINCESAS|PRINCIPE|PRINCIPE AZUL|PRINCIPES|PRISA|PRISION|PRISIONERO|PRODIGIO|PROFECIA|PROFESOR|',
  'PROFESORA|PROFESORAS|PROFESORES|PROFETICO|PROFUNDAMENTE|PROGENITORES|PROMETIDA|PROMETIDO|PROMETIDOS|PROPUESTA DE MATRIMONIO|PROTEGIDA|PROTEGIDO|PRUEBA|PRUEBAS|PTERODACTILO*|PUDOR|PUEBLECITO|PUEBLO|',
  'PUEBLOS|PUENTE|PUENTES|PUERCO*|PUERTA|PUERTA DE EMBARQUE|PUERTA SECRETA|PUERTAS|PUESTA DE SOL|PULGA*|PULGAR|PULGARES|PULSERA|PUMA|PUNAL|PUNETAZO|PUNETAZOS|PUNO|PUNOS|PUPILA|PUPILAS|PURPURA|QUEBRADA|',
  'QUEBRO|QUERUBIN|QUERUBINES|QUIEBRA|QUIMERA*|QUINTA|QUINTO|QUIQUIRIQUI|RABIA|RABINO|RABIOS*|RADIANTE|RADIANTES|RAFAGA|RAFAGAS|RAICES|RAIZ|RAMA|RAMAS|RAMO DE FLORES|RANA|RANAS|RANCIA|RANCIO|RANITA*|',
  'RAPOSA*|RAPTADA|RAPTADO|RAPTO|RASCACIELOS|RATA|RATA DE ALCANTARILLA|RATAS|RATERO|RATON|RATONCITO*|RATONES|RAYO|RAYOS|RAYOS DE SOL|REALMENTE|REBANO*|RECAMARA|RECIEN NACIDA|RECIEN NACIDO|RECIEN NACIDOS|',
  'RECLUTADOR|RECONFORT*|RECURRENTE|REENCARNACION|REENCARNADO|REFLEJO|REFLEJOS|REFRIGERADOR|REGALAR|REGALO|REGALOS|REGOCIJ*|REHEN|REHENES|REIA|REIAN|REIDO|REINA|REINAS|REIR|RELAJACION|RELAJAD*|RELAMPAGO|',
  'RELAMPAGOS|RELOJ|RELOJ DE ARENA|RELOJES|REMORDIMIENT*|RENACER|RENACER DE LAS CENIZAS|RENACIMIENTO|RENACIO|RENACUAJO*|RENCOR*|RENO|RENOS|REPUGN*|REPULSION|RESENTIDA|RESENTIDO|RESENTIMIENTO|RESPLANDOR|',
  'RESTAURANTE|RESTAURANTES|RESUCITABA|RESUCITADA|RESUCITADO|RESUCITAR|RESUCITO|RESURRECCION|RETENIDA|RETENIDO|RETRASADA|RETRASADO|RETRASO|RETRATO|RETRETE|RETROCEDER EN EL TIEMPO|REUNION|REUNIONES|',
  'REVOLVER|REY|REYERTA|REYERTAS|REYES|REZA|REZABA|REZABAN|REZAN|REZANDO|REZAR|REZO|RIACHUELO|RIADA|RICA|RICO|RICOS|RIDICUL*|RIENDO|RIESGO|RIFLE|RIMEL|RINA|RINAS|RIO|RIOS|RIQUEZA|RIQUEZAS|RISA|RISAS|',
  'RIVAL|RIVALES|ROBADA|ROBADO|ROBARON|ROBLE|ROBLES|ROBO|ROBOS|ROBOT|ROBOTS|ROCA|ROCAS|RODILLA|RODILLAS|ROEDOR*|ROJA|ROJAS|ROJIZO|ROJO|ROJOS|ROMPER CON|ROMPIMOS|ROPA|ROPA INTERIOR|ROPA MANCHADA|',
  'ROPA ROTA|ROPA SUCIA|ROPAS|ROSA|ROSAL|ROSALES|ROSARIO|ROSAS|ROSTRO|ROSTROS|ROTONDA|RUINA|RUINAS|RUISENOR*|RUMBO|RUPTURA|RUPTURAS|SABANAS|SABIA QUE ESTABA SONANDO|SABIA QUE SONABA|SABLE|SACERDOTE|',
  'SACERDOTES|SACRIFICADO|SACRIFICIO|SACRIFICIOS|SAHARA|SAL|SALA DE ESPERA|SALA DEL TRONO|SALADA|SALADO|SALARIO|SALCHICHA|SALCHICHAS|SALERO|SALIA CON|SALIR CON|SALTABA|SALTABAN|SALTADO|SALTAMONTES|',
  'SALTANDO|SALTAR|SALTE|SALTO|SALTO DE AGUA|SALTOS|SANDALIA*|SANGRA|SANGRABA|SANGRANDO|SANGRAR|SANGRE|SANGRIENTA|SANGRIENTO|SANTUARIO|SANTUARIOS|SAPO|SAPOS|SARCOFAGO|SARGENTO|SARPULLIDO|SATANAS|SCOOTER|',
  'SE ACOSTABA CON|SE CONVIRTIO EN|SE CUMPLIO|SE DERRUMBA|SE DERRUMBO|SE DESPLOMO|SE ENAMORO|SE ESTRELLO|SE HIZO REALIDAD|SE VINO ABAJO|SECUESTRADA|SECUESTRADO|SECUESTRADOR|SECUESTRADORES|SECUESTRAR|',
  'SECUESTRO|SECUESTROS|SED|SEDIENTA|SEDIENTO|SEDUCCION|SEDUCIA|SEDUCIDA|SEDUCIDO|SEDUCIR|SEDUCTOR|SEDUCTORA|SEGUNDA|SEGUNDO|SEIS|SEISMO|SELECTIVIDAD|SELVA|SELVAS|SEMBRADO|SEMINARIO|SENDERO|SEPARACION|',
  'SEPARACIONES|SEPARADOS|SEPELIO|SEPTIMA|SEPTIMO|SEPULCRO|SEPULTURA|SER EXTRANO|SERAFIN|SERENA|SERENAMENTE|SERENIDAD|SERENO|SERES EXTRANOS|SERPIENTE*|SEXO|SEXTA|SEXTO|SEXUAL|SEXUALES|SEXUALIDAD|SIETE|',
  'SILLA|SILLAS|SILLON|SILUETA|SIMIO*|SIN|SIN HOGAR|SIN RUMBO|SIN SALIDA|SIN TECHO|SIN UN DURO|SIN VIDA|SINAGOGA|SIRENA|SIRENAS|SISMO|SISMOS|SOBERANA|SOBERANO|SOBRES|SOBRESALT*|SOBRINA|SOBRINO|SOCIA|',
  'SOCIO|SOFA|SOGA|SOL|SOLDADO|SOLDADOS|SOLEADA|SOLEADO|SOLEDAD|SOLES|SOLITARIA|SOLITARIO|SOLLOZABA|SOLLOZOS|SOMBRA DE OJOS|SOMBRERO*|SOMBRILLA|SOMBRILLAS|SORDA|SORDERA|SORDO|SORDOS|SORPREND*|SORPRESA|',
  'SORTIJA|SORTIJAS|SOSEGADA|SOSEGADO|SOSIAS|SOSIEGO|SOSTEN|SOTANO|SOTANOS|SU MUJER|SUBIA|SUBLIME|SUBSUELO|SUBTERRANEO|SUCURSAL BANCARIA|SUEGRA|SUEGRO|SUEGROS|SUELDO|SUELO|SUELOS|SUENO LUCIDO|',
  'SUENO RECURRENTE|SUENOS LUCIDOS|SUENOS RECURRENTES|SUJETADOR*|SUMAMENTE|SUPER PODERES|SUPERHEROE*|SUPERHEROINA*|SUPERMERCADO|SUPERPODER*|SUPERVISOR|SUS UNAS|T REX|TABURETE|TACONES|TAMPOCO|TAN|TANGA*|',
  'TANTA|TANTO|TAPIA|TARANTULA*|TARJETA DE EMBARQUE|TAROT|TARTA|TARTAS|TAXI|TAXIS|TAXISTA|TEATRO|TEATROS|TECHO|TECLADO|TEJA|TEJADO|TEJADOS|TEJAS|TELARANA*|TELE|TELEFONO|TELEFONOS|TELEQUINESIS|TELEVISION|',
  'TELEVISOR|TELON|TEMBLABA|TEMBLANDO|TEMBLE|TEMBLOROSA|TEMBLOROSO|TEMEROSA|TEMEROSO|TEMOR|TEMORES|TEMPESTAD|TEMPESTADES|TEMPLO|TEMPLOS|TENSA|TENSION|TENSO|TERCER|TERCERA|TERCERA EDAD|TERCERO|TERMINAL|',
  'TERMITA*|TERNERA*|TERNERO*|TERNURA|TERREMOTO|TERREMOTOS|TERRIBLEMENTE|TERROR|TERRORISMO|TERRORISTA|TERRORISTAS|TESORO|TESORO ESCONDIDO|TESOROS|TEST|TESTAMENTO|TIA|TIARA|TIAS|TIBURON|TIBURONES|TIENDA|',
  'TIENDAS|TIERNA|TIERNAMENTE|TIERNO|TIERRA|TIERRAS|TIGRE*|TINIEBLAS|TINTORERA*|TIO|TIOS|TIRANOSAURIO*|TIROTEO|TITAN|TITANES|TITERE|TOBILLO|TOBILLOS|TODAS LAS NOCHES|TODOPODEROSO|TOGA|TOGAS|',
  'TOMA DE REHENES|TOMATE|TOMATES|TONINA*|TORERO*|TORMENTA|TORMENTA ELECTRICA|TORMENTAS|TORNADO|TORO|TOROS|TORRE|TORREON|TORRES|TORTA|TORTAS|TORTILLA|TORTOLA*|TORTUGA*|TORTUGUITA*|TOTALMENTE|TOXICA|',
  'TOXICO|TRABAJABA|TRABAJABAN|TRABAJADO|TRABAJANDO|TRABAJAR|TRABAJE|TRABAJO|TRAFICO|TRAJE|TRAJE DE NOVIA|TRAJES|TRAMPOLIN|TRANCE|TRANCON|TRANQUIL*|TRANSFORMABA|TRANSFORMACION|TRANSFORMADA|TRANSFORMADO|',
  'TRANSFORMARSE|TRANVIA|TRAPOS SUCIOS|TRASGO*|TRASTEO|TRAVESANOS|TRECE|TREMENDAMENTE|TREN|TRENES|TRENZA|TRENZAS|TREPABA|TREPABAN|TREPANDO|TREPAR|TREPE|TREPO|TRES|TRICERATOPS|TRIFULCA|TRIGAL|TRIGALES|',
  'TRIGO|TRINCHERA|TRINCHERAS|TRIO|TRIST*|TRITON|TROMPO|TRONCO|TRONCOS|TRUCHA*|TRUENO|TRUENOS|TSUNAMI|TULIPAN|TULIPANES|TUMBA|TUMBAS|TUMULTO|TUNEL|TUNELES|TURQUESA|UMBRAL|UN SOBRE|UNA Y OTRA VEZ|',
  'UNICORNIO|UNICORNIOS|UNIFORME|UNIFORMES|UNIVERSIDAD|UNIVERSO|URGENCIAS|UVA|UVAS|VACA|VACAS|VAGON|VALIJA|VALLE|VALLES|VALS|VAMPIRESA|VAMPIRO|VAMPIROS|VAQUITA*|VARITA MAGICA|VATER|VECINA|VECINAS|',
  'VECINDARIO|VECINO|VECINOS|VEJEZ|VELA|VELAS|VELERO|VELO DE NOVIA|VELOCIRRAPTOR*|VELORIO|VENADO*|VENDE|VENDEDOR|VENDEDORA|VENDER|VENDI|VENDIA|VENDIAN|VENDIDA|VENDIDO|VENDIENDO|VENDIO|VENDO|VENENO|',
  'VENENOS|VENENOSA|VENENOSO|VENTA|VENTANA|VENTANAL|VENTANAS|VENTANILLA|VENTAS|VENTISCA|VENTOSO|VERDADERAMENTE|VERDE|VERDES|VERDOSA|VERDOSO|VERDURA|VERDURAS|VERGUENZA|VERTEBRA|VERTEBRAS|VESTIBULO|',
  'VESTIDITO*|VESTIDO|VESTIDO BLANCO|VESTIDO DE NOCHE|VESTIDO DE NOVIA|VESTIDO LARGO|VESTIDOS|VESTIDOS DE NOVIA|VESTIMENTA*|VIA LACTEA|VIADUCTO|VIAJABA EN EL TIEMPO|VIAJAR EN EL TIEMPO|',
  'VIAJE EN EL TIEMPO|VIAJES EN EL TIEMPO|VIBORA*|VIDA PASADA|VIDAS PASADAS|VIDENTE|VIDENTES|VIDRIO ROTO|VIDRIOS ROTOS|VIENTO|VIENTOS|VIENTRE|VIENTRES|VINO BLANCO|VINO TINTO|VIOLETA|VIOLETAS|VIRUS|',
  'VIVIENDA|VOCES|VODKA|VOLABA|VOLABAN|VOLADO|VOLANDO|VOLAR|VOLCAN|VOLCANES|VOLCANICO|VOLE|VOLO|VOLVER A LA VIDA|VOLVIO A LA VIDA|VOMITABA|VOMITANDO|VOMITAR|VOMITARON|VOMITE|VOMITO|VOZ|WC|WHISKY|YATE|',
  'YEGUA*|YEMA DE HUEVO|YIHADISTA|YIHADISTAS|YOGA|ZANAHORIA|ZANAHORIAS|ZAPATILLA*|ZAPATO*|ZEN|ZOMBI|ZOMBIE|ZOMBIES|ZOMBIS|ZOOLOGICO*|ZORRA|ZORRAS|ZORRO|ZORROS|ZOZOBRA|ZOZOBRAR|1|10|12|13|2|3|4|5|6|7|8|9|',
  'ABBAGLIA*|ABBATTUT*|ABBAZIA|ABBIGLIAMENT*|ABBRACCI|ABBRACCIARE|ABBRACCIATA|ABBRACCIATO|ABBRACCIAVA|ABBRACCIAVO|ABBRACCIO|ABISSO|ABITAZIONE|ABITI|ABITI DA SPOSA|ABITI SPORCHI|ABITINO|ABITO|',
  'ABITO BIANCO|ABITO DA SERA|ABITO DA SPOSA|ACCECATO|ACCORDO|ACQUA|ACQUA SANTA|ACQUARIO*|ACQUATICA|ACQUATICO|ACQUAZZONE|ACQUE|ACQUISTARE|ACQUISTI|ACQUISTO|ADDOLORAT*|ADDOME|ADORARE|ADORATA|ADORATO|',
  'ADORAVA|ADORAVO|ADULTERIO|AEREI|AEREO|AEROPLANO|AEROPORTI|AEROPORTO|AFFAMATA|AFFAMATO|AFFANN*|AFFASCINA*|AFFETTO|AFFETTUOSA|AFFETTUOSAMENTE|AFFETTUOSO|AFFLITT*|AFFOG*|AFFONDARE|AFFONDAVA|AFFRANTA|',
  'AFFRANTI|AFFRANTO|AFFRETTAVO|AFONA|AFONO|AGGHIACCIAN*|AGGREDITA|AGGREDITO|AGGRESSIONE|AGGRESSORE|AGGUATO|AGITATA|AGITATO|AGITAZIONE|AGNELL*|AGO MAGNETICO|AGONIA|AGONIZZANTE|AL SICURO|AL VERDE|ALBA|',
  'ALBE|ALBERGHI|ALBERGO|ALBERI|ALBERO|ALBUM|ALCE|ALCI|ALCOL|ALCOLICI|ALDILA|ALIENI|ALIENO|ALLAGATA|ALLAGATO|ALLARME|ALLARME ANTINCENDIO|ALLARMI|ALLEGR*|ALLERTA|ALLIGATOR*|ALLOCCO*|ALLUCE|ALLUCI|',
  'ALLUVIONE|ALLUVIONI|ALTARE|ALTARI|ALTER EGO|ALTO MARE|ALVEARE*|AMANTE|AMANTI|AMATA|AMATI|AMATO|AMICA|AMICHE|AMICI|AMICIZIA|AMICO|AMMALATA|AMMALATO|AMMAZZARE|AMMAZZATO|AMMIRARE|AMMIRATA|AMMIRATO|',
  'AMMIRAVO|AMMIRAZIONE|AMMUFFITA|AMMUFFITO|AMORE|AMORE A PRIMA VISTA|AMPOLLA|ANATOMIA|ANCORA E ANCORA|ANCORA QUEL SOGNO|ANCORA QUESTO SOGNO|ANDARE A LETTO CON|ANDATO A MALE|ANDROIDE|ANDROIDI|ANDRONE|',
  'ANELLI|ANELLINO|ANELLO|ANELLO DI FIDANZAMENTO|ANGELI|ANGELICO|ANGELO|ANGELO CUSTODE|ANGOSCI*|ANIMA|ANIMALE|ANIMALI|ANNEG*|ANSIA|ANSIE|ANSIOS*|ANTICAMERA|ANTIFURTO|ANTRO|ANZIANA|ANZIANI|ANZIANO|APE|',
  'APERTA|APERTI|APERTO|APERTURA|API|APICOLTOR*|APOCALISSE|APOCALITTIC*|APPAGAT*|APPARIZIONE|APPARIZIONI|APPARTAMENTO|APPRENSIONE|APPUNTAMENTI|APPUNTAMENTO|APPUNTAMENTO AL BUIO|APRE|APRENDO|APRI|APRII|',
  'APRIRE|APRIVA|APRIVANO|APRIVO|APRO|AQUIL*|ARANCE|ARANCIA|ARANCIONE|ARANCIONI|ARCANGELI|ARCANGELO|ARCOBALENI|ARCOBALENO|ARGILLA|ARIDA|ARIDO|ARIETE|ARLECCHINO|ARMA DA FUOCO|ARMAGEDDON|ARMI DA FUOCO|',
  'ARMONIA|ARRABBIAT*|ARRAMPIC*|ARROSTO|ARSENICO|ASCENSORE|ASCENSORI|ASPETTAI|ASPETTANDO|ASPETTARE|ASPETTATO|ASPETTAVA|ASPETTAVANO|ASPETTAVO|ASSAI|ASSASSINATA|ASSASSINATO|ASSASSINIO|ASSASSINO|ASSEMBLEA|',
  'ASSEMBRAMENTO|ASSETATA|ASSETATO|ASSUNTA|ASSUNTO|ASTROLOGO|ASTRONAUTA|ASTRONAUTI|ATLANTE|ATTACCARE|ATTACCATA|ATTACCATO|ATTACCAVA|ATTACCAVANO|ATTACCHI|ATTACCO|ATTENDERE|ATTENDEVO|ATTENTATI|ATTENTATO|',
  'ATTENTATORE|ATTENTATORI|ATTERRAGGIO|ATTERRIT*|ATTESA|ATTORE|ATTRICE|AULA|AUREO|AURORA|AURORE|AUTO|AUTOBUS|AUTOMA|AUTOMI|AUTOMOBILE|AUTOSTRADA|AVARIATA|AVARIATO|AVVELENAMENTO|AVVELENARE|AVVELENATA|',
  'AVVELENATO|AVVERSARI|AVVERSARIO|AVVOLTOI*|AZIENDA|AZZURRA|AZZURRE|AZZURRI|AZZURRO|BABBO|BABBUIN*|BACCHETTA MAGICA|BACETTO|BACI|BACIARE|BACIARSI|BACIATA|BACIATO|BACIAVA|BACIAVANO|BACIAVO|BACIO|BAFFI|',
  'BAFFO|BAGAGLI|BAGAGLIO|BAGLIORE|BAGNI|BAGNO|BAGUETTE|BALENA|BALENE|BALENOTTERA*|BALLANDO|BALLARE|BALLATO|BALLAVA|BALLAVANO|BALLAVO|BALLERINA|BALLERINO|BALLO|BALLO IN MASCHERA|BALZAVO|BALZO|BAMBINA|',
  'BAMBINE|BAMBINI|BAMBINO|BAMBOLA|BAMBOLE|BANANA|BANANE|BANCA|BANCAROTTA|BANCHE|BANCHETTI|BANCHETTO|BANCHIERE|BANCOMAT|BANCONOTA|BANCONOTE|BANDITI|BANDITO|BARA|BARBA|BARBAGIANNI|BARBE|BARBUTO|BARCA|',
  'BARCHE|BARE|BARUFFA|BASILICA|BATTAGLIA|BATTAGLIE|BATTERMI|BATTESIMO|BATTEZZATO|BATTITI|BATTITO|BAULE|BAULI|BEATITUDINE|BEBE|BELVA*|BENEDETTA|BENEDETTO|BENEDICEVA|BENEDIRE|BENEDISSE|BENEDIZIONE|',
  'BENEDIZIONI|BENESSERE|BERE|BERRETTI|BERRETTO*|BESTIA|BESTIE|BESTIOLA*|BEVANDA|BEVE|BEVEVA|BEVEVO|BEVO|BEVUTO|BIANCA|BIANCHE|BIANCHERIA INTIMA|BIANCHI|BIANCO|BIBLIOTECA|BICI|BICICLETTA|BICICLETTE|',
  'BIGLIETTI|BIGLIETTO|BIGLIETTO DEL TRENO|BIMBA|BIMBI|BIMBO|BINARI|BINARIO|BIRRA|BIRRE|BISCE|BISCIA|BISNONNO|BISONTE*|BISTECCA|BISTECCHE|BIVIO|BLATTA|BLATTE|BLOCCATA|BLOCCATA DENTRO|BLOCCATO|',
  'BLOCCATO DENTRO|BLU|BOA|BOCCA|BOCCETTA|BOCCHE|BOMBA|BOMBARDAMENTI|BOMBARDAMENTO|BOMBE|BOMBETTA|BORDO PISCINA|BORGHI|BORGO|BORSA|BORSE|BORSEGGIATORE|BORSETTA|BOSCHI|BOSCO|BOTOLO|BOTTEGA|BOTTIGLIA|',
  'BOTTIGLIE|BOTTINO|BOZZOL*|BOZZOLO|BRACCATA|BRACCATO|BRACCIA|BRACCIALE|BRACCIALETTO|BRACCIO|BRACE|BRACI|BREZZA|BREZZE|BRIVID*|BRUCHI|BRUCO|BRUMA|BUCO DELLA SERRATURA|BUE|BUFAL*|BUFERA|BUFFONE|BUIO|',
  'BUOI|BUONANIMA|BURATTINO|BURRONE|BURRONI|BUS|BUSSOLA|BUSSOLE|BUSTA|BUSTE|CABINA DELL ASCENSORE|CACAO|CACCIA AL TESORO|CACCIATO DAL LAVORO|CADAVERE|CADAVERI|CADDE|CADDI|CADE|CADENDO|CADERE|CADEVA|',
  'CADEVANO|CADEVO|CADO|CADUTA|CADUTO|CAFFE|CAFFETTIERA|CAGNA*|CAGNETTO|CAGNOLIN*|CAIMAN*|CALABRON*|CALAMITA|CALCA|CALM*|CALVA|CALVO|CAMBIARE CASA|CAMBIATO CASA|CAMERA|CAMERA DA LETTO|CAMERA SEGRETA|',
  'CAMERE|CAMERETTA|CAMERIERA|CAMERIERE|CAMICE|CAMICI|CAMICIA|CAMICIE|CAMMINO|CAMMINO DI SANTIAGO|CAMPI|CAMPO|CAMPO DI BATTAGLIA|CAMPOSANTO|CANARINO*|CANCELLI|CANCELLO|CANCRO|CANDELA|CANDELE|CANDELIERE|',
  'CANDIDA|CANDIDATA|CANDIDATO|CANDIDATURA|CANDIDO|CANE|CANI|CANTAI|CANTANDO|CANTANTE|CANTARE|CANTATO|CANTAVA|CANTAVANO|CANTAVO|CANTIERE|CANTIERI|CANTINA|CANTINE|CANTO|CANYON|CANZONE|CANZONI|CAPELLI|',
  'CAPELLI BIANCHI|CAPELLO|CAPI|CAPII CHE STAVO SOGNANDO|CAPO|CAPODOGLIO*|CAPPELLA|CAPPELLANO|CAPPELLE|CAPPELLI|CAPPELLO*|CAPPIO|CAPPOTTI|CAPPOTTO*|CAPPUCCINO|CAPRA|CAPRE|CAPRETTI|CAPRETTO|CAPRIOLO*|',
  'CAPRON*|CARABINIERE|CARABINIERI|CARAMELLA|CARAMELLE|CARCASSA|CARCERE|CARCERIERE|CARDIACO|CARESTIA|CARNE|CARNEVALE|CARNI|CAROGNA|CAROTA|CAROTE|CARPA|CARRIERA|CARRO FUNEBRE|CARTA D IMBARCO|',
  'CARTA GEOGRAFICA|CARTE DA GIOCO|CARTINA|CARTOMANTE|CASA|CASA D INFANZIA|CASA DEI MIEI GENITORI|CASA DEI NONNI|CASA DELLA MIA INFANZIA|CASA DI FAMIGLIA|CASA INFESTATA|CASA NATALE|CASCATA|CASCATE|CASE|',
  'CASSA|CASSAFORTE|CASSETTA DELLA POSTA|CASTELLI|CASTELLO|CATACLISMA|CATACOMBE|CATASTROFE|CATASTROFI|CATASTROFICO|CATENA|CATENACCIO|CATENE|CATERATTA|CATTEDRALE|CATTIVITA|CAVALLA|CAVALLE|CAVALLETTA|',
  'CAVALLETTE|CAVALLI|CAVALLINO|CAVALLO|CAVERNA|CAVERNE|CAVIGLIA|CAVIGLIE|CAZZOTTI|CECITA|CEDIMENTO|CELATA|CELATO|CELEBRITA|CELESTE|CELLA|CELLULARE|CENA|CENA ROMANTICA|CENCI|CENONE|CENTESIMI|CENTESIMO|',
  'CENTRO CITTA|CENTRO COMMERCIALE|CEPPI|CEPPO|CERBIATT*|CERCA|CERCAI|CERCANDO|CERCARE|CERCATO|CERCAVA|CERCAVANO|CERCAVO|CERCHI|CERCHIO|CERCO|CERI|CERO|CERVI|CERVO|CHAMPAGNE|CHERUBINI|CHERUBINO|CHIAMATA|',
  'CHIARO DI LUNA|CHIARORE|CHIAROVEGGENTE|CHIAVE|CHIAVE DI CASA|CHIAVI|CHIAVISTELLO|CHICCHIRICHI|CHIESA|CHIESETTA|CHIMERA|CHIMERE|CHIOCCIOL*|CHIOMA|CHIROTTERI|CHIROTTERO|CHIRURGHI|CHIRURGO|CHIUSA DENTRO|',
  'CHIUSO DENTRO|CI SIAMO LASCIATI|CIABATT*|CIANURO|CIBI|CIBO|CICATRICE|CICATRICI|CICLONE|CIECA|CIECHI|CIECO|CIELI|CIELO|CIGLIA|CIGLIO|CIGNI|CIGNO|CIGNO NERO|CILIEGIA|CILIEGIE|CIMA|CIME|CIMITERI|',
  'CIMITERO|CINGHIAL*|CINQUE|CIOCCOLATA|CIOCCOLATINI|CIOCCOLATINO|CIOCCOLATO|CIOTTOLI|CIOTTOLO|CIPOLLA|CIPOLLE|CIPRIA|CIRCOLARE|CISTERNA|CISTERNE|CITTA|CIVETTA*|CLACSON|CLASSE|CLAUSOLA|CLESSIDRA|CLINICA|',
  'CLOWN|COBRA*|COCCI|COCCINELL*|COCCODRILL*|COCCOLAVA|COCCOLE|CODA DI PAVONE|COFANETTO|COGNATA|COGNATO|COLLABORATORE|COLLABORATRICE|COLLANA|COLLEGA|COLLEGHE|COLLEGHI|COLLERA|COLLINA|COLLINE|COLLISIONE|',
  'COLLO|COLLOQUI|COLLOQUIO|COLLOQUIO DI LAVORO|COLOMB*|COLONNA VERTEBRALE|COLOSSI|COLOSSO|COLPA|COLPEVOL*|COLPO DI FULMINE|COLPO DI PISTOLA|COLTELLI|COLTELLINO|COLTELLO|COMBATTENDO|COMBATTERE|',
  'COMBATTEVA|COMBATTEVO|COMBATTUTO|COMMISSARIO|COMMOSS*|COMPAGNA|COMPAGNO|COMPAGNO DI LAVORO|COMPASSIONE|COMPIANTA|COMPIANTO|COMPITO IN CLASSE|COMPLETAMENTE|COMPLICITA|COMPRAI|COMPRANDO|COMPRARE|',
  'COMPRATO|COMPRAVA|COMPRAVANO|COMPRAVO|COMPRO|COMPUTER|CONCUBINA|CONFERENZA|CONFINE|CONFINI|CONFORT*|CONIGL*|CONIUGE|CONSAPEVOLE DI SOGNARE|CONSIGLIO DI AMMINISTRAZIONE|CONSOLAT*|CONSOLAZIONE|CONSORTE|',
  'CONTANTI|CONTENTA|CONTENTE|CONTENTI|CONTENTO|CONTO BANCARIO|CONTO IN BANCA|CONTRATTI|CONTRATTO|CONTROLLAVO IL SOGNO|CONVENTO|COPPIA|COPPIE|COPPOLA|CORDA|CORDE|CORNACCHI*|CORNO DI UNICORNO|CORO|CORONA|',
  'CORONE|CORPI|CORPO|CORPO SENZA VITA|CORPOREO|CORRE|CORRENDO|CORRERE|CORREVA|CORREVANO|CORREVO|CORRIDA*|CORRIDOI|CORRIDOIO|CORRIERA|CORRO|CORRONO|CORSA|CORTEGGIAMENTO|CORTEGGIARE|CORTEGGIAVA|CORVACCIO|',
  'CORVI|CORVO|COSCE|COSCIA|COSI|COSMO|COSPLAY|COSTELLAZIONE|COSTELLAZIONI|COSTRU*|COSTUME DI CARNEVALE|CRANIO|CRATERE|CRATERI|CREATURA|CREATURE|CREDITORE|CREDITORI|CREMISI|CREPUSCOLI|CREPUSCOLO|',
  'CRICETO*|CRIPTA|CRISALIDE|CRISALIDE*|CRISTO|CROCE|CROCEFISSO|CROCEVIA|CROCI|CROCIERA|CROCIFISSIONE|CROCIFISSO|CROLLARE|CROLLATA|CROLLATO|CROLLAVA|CROLLI|CROLLO|CROSTATA|CROSTATE|CUCCIOL*|CUCINA|',
  'CUCINE|CUGINA|CUGINI|CUGINO|CUORE|CUORI|CURIOS*|CURRICULUM|CUSCINI|CUSCINO|CYBORG|D ORO|DAINO*|DALLE CENERI|DANNATI|DANNATO|DANNAZIONE|DANZA|DARE ALLA LUCE|DATORE DI LAVORO|DAVANZALE|DAVVERO|DEA|',
  'DEBITI|DEBITO|DECEDUTA|DECEDUTI|DECEDUTO|DECESSO|DECIMA|DECIMO|DECINA|DECOLLARE|DECOLLO|DEDALO|DEFUNTA|DEFUNTE|DEFUNTI|DEFUNTO|DEJA VU|DELFINETTO|DELFINI|DELFINO|DEMONE|DEMONI|DEMONIACO|DENARO|DENTE|',
  'DENTI|DENTIERA|DENTISTA|DEPRESS*|DESERTI|DESERTICA|DESERTICO|DESERTO|DESOLAT*|DESOLAZIONE|DESSERT|DETONAZIONE|DEVOZIONE|DI CORSA|DI FRETTA|DI NUOVO QUESTO SOGNO|DIABOLICO|DIADEMA|DIAMANTE|DIAMANTI|',
  'DIAVOLI|DIAVOLO|DIECI|DIEDE ALLA LUCE|DILUVIO|DIMORA|DINAMITE|DINO|DINOSAURI|DINOSAURO|DIO|DIRETTORE|DIRETTRICE|DIRIGENTE|DIRIMPETTAIO|DISAGIO|DISASTRI|DISASTRO|DISCENDERE|DISCESA|DISCHI VOLANTI|',
  'DISCO VOLANTE|DISGUST*|DISOCCUPATA|DISOCCUPATO|DISOCCUPAZIONE|DISORIENTATA|DISORIENTATO|DISPERA*|DITA|DITO|DITTA|DIVA|DIVANO|DIVENTARE VECCHIO|DIVI|DIVINA|DIVINI|DIVINITA|DIVINO|DIVO|DIVORZI|',
  'DIVORZIARE|DIVORZIATA|DIVORZIATI|DIVORZIATO|DIVORZIAVANO|DIVORZIO|DOCCE|DOCCIA|DODICESIMO|DODICI|DOGANA|DOGANIERE|DOLCETTI|DOLCEZZA|DOLCIUMI|DOLLARI|DONI|DONO|DORATA|DORATE|DORATI|DORATO|DORMITORIO|',
  'DOTTORE|DOTTORESSA|DOTTORI|DOVEVO DEI SOLDI|DOZZINA|DOZZINE|DRACULA|DRAGHI|DRAGO|DRAGONE|DRAGONI|DUE|DUNA|DUNE|DUOMO|EBBRO|ECLISSATA|ECLISSATO|ECLISSE|ECLISSI|ECOGRAFIA|EDEN|EDIFICARE|EDIFICAVO|',
  'EFFRAZIONE|ELEFANTE|ELEFANTI|ELEFANTINO|ELFI|ELFO|EMICRANIA|EMORRAGIA|ENTUSIAS*|EPIDEMIA|EPIDERMIDE|ERBA|ERBE|EREDE|EREDI|EREDITA|EREDITARE|EREDITATO|EREDITAVA|EREMITA|ERO PERSA|ERO PERSO|EROTICA|',
  'EROTICO|ERUZIONE|ERUZIONI|ESALTAT*|ESALTAZIONE|ESAME|ESAMI|ESASPERAT*|ESEQUIE|ESPLODERE|ESPLODEVA|ESPLOSA|ESPLOSE|ESPLOSIONE|ESPLOSIONI|ESPLOSIVO|ESPLOSO|ESPRESSO|ESSERE STRANO|ESSERI STRANI|ESTASI|',
  'ESTASIAT*|ESTRANEA|ESTRANEI|ESTRANEO|ESTREMAMENTE|ESULTAN*|EUFORI*|EURO|EVACUARE|EVACUATI|EVACUATO|EVACUAZIONE|EX|EX COMPAGNA|EX COMPAGNO|EX FIDANZATA|EX FIDANZATO|EX MARITO|EX MOGLIE|EX RAGAZZA|',
  'EX RAGAZZO|EX VOTO|EXTRATERRESTRE|EXTRATERRESTRI|FACCE|FACCIA|FACEVAMO L AMORE|FALCHETTO|FALCHI|FALCO|FALENA*|FALLIMENTO|FALLITA|FALLITO|FALO|FALSO RISVEGLIO|FAME|FAMIGLIA|FAMIGLIE|FAMILIARE|FAMOSA|',
  'FAMOSE|FAMOSI|FAMOSO|FANGHI|FANGO|FANGOSA|FANGOSO|FANTASMA|FANTASMI|FARE L AMORE|FARFALL*|FASCINO|FASTIDI*|FATA|FATA MADRINA|FATA TURCHINA|FATE MADRINE|FATINA*|FATTO L AMORE|FATTUCCHIER*|FAVO|FEBBRE|',
  'FELIC*|FELINO*|FENICE|FENICI|FERETRI|FERETRO|FERITA|FERITE|FERITI|FERITO|FERROVIA|FESTA|FESTE|FESTINO|FIAMMA|FIAMME|FIASCO|FIDANZAMENTI|FIDANZAMENTO|FIDANZARSI|FIDANZATA|FIDANZATI|FIDANZATO|FIDUCIA|',
  'FIGLI|FIGLIA|FIGLIE|FIGLIO|FILIALE|FINE DEI TEMPI|FINE DEL MONDO|FINESTRA|FINESTRE|FINESTRINO|FIOCCHI DI NEVE|FIORE|FIORETTO|FIORI|FIORITA|FIORITO|FIRMA|FIRMAMENTO|FIRMARE|FIRMATA|FIRMATO|FIRMAVO|',
  'FIUME|FIUMI|FLACONE|FLIRT|FLIRTARE|FLIRTAVA|FOCENA|FOGLIA|FOGLIAME|FOGLIE|FOLLA|FOLLETTI|FOLLETTO|FONDOTINTA|FONTANA|FONTANE|FONTE|FONTI|FORESTA|FORESTE|FORMICA|FORMICAI|FORMICAIO*|FORMICHE|',
  'FORMICHINA|FORNELLI|FORNELLO|FORNO|FORTEZZA|FORZA SOVRUMANA|FORZIERE|FOSCHIA|FOTO|FOTOGRAFIA|FOTOGRAFIE|FRAGOLA|FRAGOLE|FRANA|FRANATO|FRANTUMI|FRATE|FRATELLI|FRATELLINO|FRATELLO|FRATI|FRENARE|FRENAVA|',
  'FRENAVO|FRENI|FRENO|FRETTA|FRIGORIFERO|FRITTATA|FRONDA|FRONDE|FRONTIERA|FRONTIERE|FRUSTRA*|FRUTTA|FRUTTETI|FRUTTETO|FRUTTI|FRUTTO|FUCILE|FUCILI|FUGA|FUGGENDO|FUGGI|FUGGII|FUGGIRE|FUGGITA|FUGGITO|',
  'FUGGIVA|FUGGIVANO|FUGGIVO|FULMINE|FULMINI|FUMANTE|FUMARE|FUMATA|FUMI|FUMO|FUNE|FUNERALE|FUNERALI|FUNI|FUOCHI|FUOCO|FUORI DAL CORPO|FURIA|FURIBOND*|FURIOS*|FURTI|FURTO|GABBIA|GABBIE|GABINETTO|GALASSIA|',
  'GALASSIE|GALERA|GALLERIA|GALLERIE|GALLI|GALLIN*|GALLO|GAMBA|GAMBE|GATE D IMBARCO|GATTA|GATTE|GATTI|GATTINA*|GATTINO*|GATTO|GELATI|GELATO|GELOS*|GEMELLA|GEMELLE|GEMELLI|GEMELLO|GEMMA|GENITORE|GENITORI|',
  'GESU|GETTONE|GETTONI|GHEPARDO*|GHIACCI|GHIACCIAI|GHIACCIAIO|GHIACCIATA|GHIACCIATO|GHIACCIO|GIACCA|GIACCHE|GIACCONE*|GIAGUAR*|GIALLA|GIALLASTRO|GIALLE|GIALLI|GIALLO|GIARDINI|GIARDINIERE|GIARDINO|',
  'GIARDINO DELL EDEN|GIGANTE|GIGANTESSA|GIGANTI|GIGLIO|GINOCCHI|GINOCCHIA|GINOCCHIO|GIOCATTOLI|GIOCATTOLO|GIOIA|GIOIE|GIOIELLI|GIOIELLO|GIOIOSA|GIOIOSE|GIOIOSI|GIOIOSO|GIOVENCA*|GIRARE IN TONDO|GIRINI|',
  'GIRINO*|GIUBBOTT*|GIUBIL*|GIUDIZIO UNIVERSALE|GIULLARE|GIUMENTA*|GIUNGLA|GIUNGLE|GNOMI|GNOMO|GOFFA|GOFFO|GOLA|GOLE|GOMITI|GOMITO|GONNA|GONNE|GORILLA*|GPS|GRADINI|GRANO|GRATA|GRATITUDINE|GRATO|',
  'GRATTACIELI|GRATTACIELO|GRAVIDA|GRAVIDANZA|GRAVIDANZE|GREGGE*|GREMBIUL*|GRIDANDO|GRIDARE|GRIDATO|GRIDAVA|GRIDAVANO|GRIDAVO|GRIDO|GRIGI|GRIGIA|GRIGIASTRO|GRIGIE|GRIGIO|GRILLI|GRILLO|GRIZZLY|GRONDAIA|',
  'GROTTA|GROTTE|GUANCE|GUANCIA|GUERRA|GUERRA MONDIALE|GUERRE|GUERRIERI|GUERRIERO|GUFI|GUFO|GUIDA SPIRITUALE|GUIDARE|GUIDAVO|GURU|GUSCIO|HO CORSO|HO RISO|HOTEL|IBRIDI|IBRIDO|ICEBERG|IDDIO|IDRA|',
  'IL MIO DOPPIO|IL MIO RAGAZZO|IMAM|IMBARAZZ*|IMBARCO|IMBOTTIGLIATO|IMBRUNIRE|IMMENSAMENTE|IMMOBILE|IMPACCIAT*|IMPAURIT*|IMPERATORE|IMPERATRICE|IMPERMEABIL*|IMPIEGO|IN FIAMME|IN PERICOLO|IN RITARDO|',
  'IN ROVINA|INCANT*|INCANTATA|INCANTATO|INCANTESIM*|INCATENATA|INCATENATO|INCENDI|INCENDIATA|INCENDIATO|INCENDIO|INCENDIO BOSCHIVO|INCIDENTE|INCIDENTI|INCINTA|INCONTRO GALANTE|INCORONATA|INCORONATO|',
  'INCORONAZIONE|INCREDIBILMENTE|INCREDUL*|INCROCI|INCROCIO|INCUBI|INCUBO|INCURIOSIT*|INDEBITATA|INDEBITATO|INDEMONIATO|INDIETRO NEL TEMPO|INDIGENTE|INDIGN*|INDOVINO|INDUMENT*|INFARTO|INFASTIDIT*|',
  'INFEDELE|INFEDELI|INFEDELTA|INFELIC*|INFERI|INFERMIERA|INFERMIERE|INFERMIERI|INFERNALE|INFERNO|INFESTATA|INFESTATO|INFEZIONE|INGABBIATO|INGORGHI|INGORGO|INNAMORARMI|INNAMORARSI|INNAMORATA|INNAMORATI|',
  'INNAMORATO|INNEVATA|INNEVATO|INONDAZIONE|INONDAZIONI|INORRIDIT*|INQUIET*|INSALATA|INSANGUINATA|INSANGUINATO|INSEGNANTE|INSEGNANTI|INSEGU*|INSETT*|INSICUR*|INSOLVENTE|INTERNET|INTERROGAZIONE|',
  'INTIMIDAZIONE|INTIMITA|INTIMO|INTRAPPOLATA|INTRAPPOLATO|INTRUSO|INVASIONE|INVASORI|INVECCHIAMENTO|INVECCHIARE|INVECCHIATA|INVECCHIATO|INVECCHIAVA|INVESTITA|INVESTITO|INVISIBILE|INVISIBILI|',
  'INVISIBILITA|IRA|IRIDATO|IRIDE|IRIDESCENTE|IRREQUIET*|IRRITA*|ISOLA|ISOLA DESERTA|ISOLE|ISOLOTTO|JIHADISTA|JIHADISTI|KAMIKAZE|KARMA|LA MIA RAGAZZA|LA PORTA|LABBRA|LABBRO|LABIRINTI|LABIRINTO|LACRIMA|',
  'LACRIME|LADRA|LADRI|LADRO|LAGHI|LAGO|LAGUNA|LAGUNE|LAMA|LAMPADA|LAMPADARIO|LAMPADE|LAMPADINA|LAMPI|LAMPO|LANTERNA|LAPIDE|LAPIDI|LARVA|LARVE|LASCITO|LATRINA|LATTANTE|LATTE|LATTEA|LATTEO|LATTICINI|',
  'LATTIERO|LAVA|LAVANDINO|LAVARE|LAVAVA|LAVAVO|LAVELLO|LAVORANDO|LAVORARE|LAVORATO|LAVORAVA|LAVORAVANO|LAVORAVO|LAVORO|LECCA LECCA|LEGGERE|LENTI|LENTI A CONTATTO|LENTIGGINI|LENZUOLA|LEONCINO*|LEONE|',
  'LEONESSA*|LEONI|LEOPARDO*|LEPRE|LEPRI|LESIONE|LESIONI|LETTERA|LETTERE|LETTI|LETTO|LEVITARE|LEVITAVO|LIBERATA|LIBERATO|LIBERAZIONE|LIBRARSI|LIBRI|LIBRO|LICANTROP*|LICENZIAMENTO|LICENZIARE|LICENZIATA|',
  'LICENZIATO|LICEO|LIDO|LIETA|LIETE|LIETI|LIETO|LILLA|LINGERIE|LINGOTTI|LINGOTTO|LINGUA|LINGUACCIA|LINGUE|LITORALE|LIVIDI|LIVIDO|LIVORE|LOCANDA|LOCOMOTIVA|LOCULO|LOMBRIC*|LOOP TEMPORALE|LOTTA|LOTTARE|',
  'LOTTATO|LOTTAVA|LOTTAVO|LOTTERIA|LUCCHETTI|LUCCHETTO|LUCE|LUCI|LUCIFERO|LUMACA|LUMACHE|LUMACHINA|LUMACONE|LUMINOSA|LUMINOSO|LUNA|LUNA PIENA|LUNARE|LUNE|LUPA|LUPACCHIOTT*|LUPETTO*|LUPI|LUPI MANNARI|',
  'LUPO|LUPO MANNARO|LUSSO|LUSSUOSA|LUSSUOSO|LUTTO|MACCHINA|MACCHINA DEL TEMPO|MACCHINA FOTOGRAFICA|MACCHINE|MACELLAIO|MACELLERIA|MACERIE|MACIGNO|MADRE|MADRI|MAESTRA|MAESTRO|MAESTRO SPIRITUALE|MAGHI|',
  'MAGIA|MAGICA|MAGICI|MAGICO|MAGIE|MAGLIETT*|MAGLION*|MAGMA|MAGNIFIC*|MAGO|MAI|MAIALE|MAIALI|MAIALIN*|MAL DI SCHIENA|MAL DI TESTA|MALATA|MALATI|MALATO|MALATTIA|MALATTIE|MALINCONI*|MAMMA|MAMMA E PAPA|',
  'MAMME|MAMMUT|MANDALA|MANGIA|MANGIARE|MANGIATO|MANGIAVA|MANGIAVO|MANGIO|MANI|MANICURE|MANIERO|MANO|MANSARDA|MANTELL*|MANTRA|MAPPA|MAPPA DEL TESORO|MAPPE|MARCI|MARCIAPIEDE|MARCIO|MARE|MAREA|MAREE|',
  'MAREMOTO|MARGHERITA|MARI|MARIONETTA|MARITI|MARITO|MARZIANI|MARZIANO|MASCARA|MASCELLA|MASCHERA|MASCHERATO|MASCHERE|MASCHERINA|MATERASSO|MATRIGNA|MATRIMONI|MATRIMONIO|MATURITA|MAUSOLEO|MAZZO DI CHIAVI|',
  'MAZZO DI FIORI|MECCA|MEDICI|MEDICO|MEDITA|MEDITANDO|MEDITARE|MEDITAVA|MEDITAVO|MEDITAZIONE|MEDITO|MELA|MELE|MELI|MELMA|MELO|MENDICANTE|MENDICARE|MENDICAVO|MENTO|MERAVIGLI*|MERLI|MERLO|MESTIERE|',
  'METAMORFOSI|METRO|METROPOLI|METROPOLITANA|MEZZANOTTE|MI ACCORSI DI SOGNARE|MI HA LASCIATA|MI HA LASCIATO|MI INNAMORAI|MI PERDEVO|MI PERSI|MI SEGUIVA|MI SONO ACCORTA DI SOGNARE|',
  'MI SONO ACCORTO DI SOGNARE|MI SONO INNAMORATA|MI SONO INNAMORATO|MI SONO SVEGLIATA|MI SONO SVEGLIATO|MI SVEGLIAI|MI TRADIVA|MIA MOGLIE|MICIA|MICIO*|MIELATO|MIELE|MIELI|MIETITRICE|MIETITURA|',
  'MIGLIORE AMICA|MIGLIORE AMICO|MIGNOLO|MILIARDARIO|MILIONARIA|MILIONARIO|MILITARE|MILITARI|MINACCE|MINACCIA|MINACCIARE|MINACCIATA|MINACCIATO|MINACCIAVA|MINACCIOSA|MINACCIOSO|MIO MARITO|MIRACOLI|',
  'MIRACOLO|MIRACOLOSA|MIRACOLOSAMENTE|MIRACOLOSO|MISERIA|MITRAGLIATRICE|MOGLI|MOGLIE|MOLARE|MOLARI|MOLTITUDINE|MOLTO|MONACI|MONACO|MONARCA|MONASTERO|MONETA|MONETE|MONETE D ORO|MONETINA|MONETINE|',
  'MONOCOLO|MONTACARICHI|MONTAGNA|MONTAGNE|MONTE|MONTI|MONTONE*|MORENDO|MORI|MORIBONDO|MORII|MORIRE|MORIRE DI FAME|MORIVA|MORIVANO|MORIVO|MORTA|MORTALE|MORTALI|MORTE|MORTI|MORTI VIVENTI|MORTIFICAT*|',
  'MORTO|MORTO VIVENTE|MOSCA|MOSCERIN*|MOSCHE|MOSCHEA|MOSCHEE|MOSCONE*|MOSTRI|MOSTRO|MOSTRUOSA|MOSTRUOSO|MOTO|MOTOCICLETTA|MOTORINO|MUCCA|MUCCHE|MUFFA|MUOIO|MUOIONO|MUORE|MURA|MURAGLIA|MURI|MURO|MUTA|',
  'MUTANDE|MUTANDINE|MUTANDONI|MUTANTE|MUTANTI|MUTAZIONE|MUTI|MUTO|MUTUO|NACQUE|NANI|NANO|NARICE|NARICI|NASCE|NASCERE|NASCITA|NASCITE|NASCOND*|NASCOS*|NASI|NASO|NATA|NATI|NATO|NAUFRAGHI|NAUFRAGIO|',
  'NAUFRAGO|NAUSEA|NAUSEE|NAVE|NAVI|NAVIGARE|NE|NEANCHE|NEBBIA|NEBBIE|NEBBIOSA|NEBBIOSO|NECROPOLI|NEGOZI|NEGOZIO|NEMICA|NEMICHE|NEMICI|NEMICO|NEMMENO|NEONATA|NEONATI|NEONATO|NEPPURE|NERA|NERE|NERI|NERO|',
  'NERVOS*|NESSUN|NESSUNA|NESSUNO|NESSUNO MI VEDEVA|NESSUNO POTEVA VEDERMI|NETTARE|NEVE|NEVI|NEVICA|NEVICARE|NEVICATA|NEVICAVA|NIPOTE|NIRVANA|NODI|NODO|NON|NON MORTI|NON MORTO|NON POTEVO MUOVERMI|',
  'NON RIUSCIVO A MUOVERMI|NON RIUSCIVO A USCIRE|NON VEDEVO|NONA|NONNA|NONNI|NONNINA|NONNINO|NONNO|NONO|NOSTALGI*|NOTAIO|NOTTE|NOTTI|NOTTURNO|NOVE|NOZZE|NUBE|NUBI|NUCA|NUDA|NUDE|NUDI|NUDITA|NUDO|',
  'NUMERO DUE|NUMERO SEI|NUMERO UNO|NUOTA|NUOTAI|NUOTANDO|NUOTARE|NUOTATO|NUOTAVA|NUOTAVANO|NUOTAVO|NUOTO|NUVOLA|NUVOLE|NUVOLOSA|NUVOLOSO|OBITORIO|OCCHI|OCCHIALI|OCCHIALI DA SOLE|OCCHIALINI|OCCHIO|',
  'OCEANI|OCEANO|ODIARE|ODIATO|ODIAVA|ODIAVO|ODIO|OGNI NOTTE|OLFATTO|OMBELICO|OMBRELLI|OMBRELLO|OMBRELLONE|OMBRETT*|OMICIDIO|ONDA|ONDATA|ONDATE|ONDE|ONDINA*|ONNIPOTENTE|OPEN SPACE|OPPRESS*|ORANGO*|ORCA|',
  'ORCHE|ORCHI|ORCHIDEA|ORCO|ORECCHI|ORECCHIE|ORECCHINI|ORECCHIO|ORGASMO|ORGOGLI*|ORINATOIO|ORO|ORO MASSICCIO|OROLOGI|OROLOGIO|ORRIBILE|ORRIBILI|ORRORE|ORRORI|ORSA|ORSACCHIOTT*|ORSACCHIOTTO|ORSETT*|ORSI|',
  'ORSO|ORTAGGI|ORTI|ORTO|OSCURITA|OSPEDALE|OSPEDALI|OSSA|OSSARIO|OSSO|OSTAGGI|OSTAGGIO|OSTELLO|OSTERIA|OSTIL*|OTTAVA|OTTAVO|OTTO|PACCHETTO|PACE|PADRE|PADRI|PAESE|PAESINO|PAGARE|PAGATO|PAGAVO|PAGLIACCI|',
  'PAGLIACCIO|PAGNOTTA|PAGODA|PALAZZI|PALAZZO|PALAZZO REALE|PALCO|PALCOSCENICO|PALLA|PALLONCINI|PALLONCINO|PALLONE|PALLONI|PALMA|PALPEBRA|PALPEBRE|PALUDE|PALUDI|PANCE|PANCHINA|PANCIA|PANE|PANETTERIA|',
  'PANETTIERE|PANI|PANICO|PANIFICIO|PANNI|PANNI SPORCHI|PANTALONI|PANTANO|PANTEGAN*|PANTERA*|PANTOFOL*|PAPA|PAPILLE|PAPPAGALL*|PARADISIACO|PARADISO|PARALISI|PARALIZZ*|PARASOLE|PARCHI|PARCO|PARENTI|',
  'PARETE|PARETI|PARROCCHIA|PARROCO|PARRUCCA|PARTNER|PARTORIRE|PARTORITO|PARTORIVA|PASCOLI|PASCOLO|PASSAGGIO SEGRETO|PASSAPORTO|PASSERELLA|PASSERI|PASSERO|PASSEROTTO*|PASTICCERIA|PASTICCINI|PASTICCINO|',
  'PASTO|PATATA|PATATE|PATRIGNO|PATRIMONIO|PATTO|PAUR*|PAVONE|PAVONESSA|PAVONI|PC|PECORA|PECORE|PECORELL*|PEDALARE|PEDALAVO|PELLE|PELLEGRINA|PELLEGRINAGGI|PELLEGRINAGGIO|PELLEGRINI|PELLEGRINO|PELLI|',
  'PELUCHE|PENA|PENDOLO|PENSIONE|PEPITA|PEPITE|PERA|PERDE|PERDENDO|PERDERE|PERDERE IL TRENO|PERDERE L AEREO|PERDERMI|PERDEVA|PERDEVANO|PERDEVO|PERDITA|PERDO|PERDUTO|PERE|PERICOLI|PERICOLO|PERICOLOSA|',
  'PERICOLOSI|PERICOLOSO|PERIFERIA|PERIZOMA*|PERLA|PERLE|PERSA|PERSIANA|PERSO|PERSO IL LAVORO|PERSO IL TRENO|PERSO IL VOLO|PERSO L AEREO|PERSO L AUTOBUS|PESCE|PESCE ROSSO|PESCECANE|PESCECANI|PESCI|',
  'PESCI ROSSI|PESCIOLIN*|PESTAGGIO|PETALI|PETALO|PETTINATURA|PETTIROSSO*|PIANETA|PIANETI|PIANGENDO|PIANGERE|PIANGEVA|PIANGEVANO|PIANGEVO|PIANSE|PIANSI|PIANTO|PICCHIATA|PICCHIATO|PICCION*|PIEDE|PIEDI|',
  'PIENEZZA|PIETRA|PIETRE|PIETRIFICATA|PIETRIFICATO|PINI|PINO|PIOGGE|PIOGGERELLA|PIOGGIA|PIOLI|PIOLO|PIOVE|PIOVERE|PIOVEVA|PIPISTRELLI|PIPISTRELLO|PIROMANE|PISCINA|PISCINE|PISTA|PISTOLA|PISTOLE|PITONE*|',
  'PIUMINO*|PIZZERIA|PLACIDA|PLACIDO|PLANARE|PLANAVO|POLIZIA|POLIZIOTTA|POLIZIOTTI|POLIZIOTTO|POLLAIO|POLLICE|POLLICI|POLPACCIO|POLSI|POLSO|POLTERGEIST|POLTRONA|POMODORI|POMODORO|POMPIERE|POMPIERI|PONTE|',
  'PONTEFICE|PONTI|PONY|POPPANTE|PORCELLIN*|PORCI|PORCO|PORPORA|PORTA SEGRETA|PORTAFOGLIO|PORTATILE|PORTE|PORTONE|PORTONI|POSSEDUTA|POSSEDUTO|POSTINO|POSTO DI LAVORO|POVERA|POVERI|POVERO|POVERTA|',
  'POZZA DI SANGUE|POZZANGHERA|POZZANGHERE|POZZI|POZZO|POZZO DEI DESIDERI|PRANZO|PRATERIA|PRATERIE|PRATI|PRATO|PRECIPITATO|PRECIPITAVO|PRECIPIZIO|PREDIZIONE|PREGA|PREGANDO|PREGANO|PREGARE|PREGATO|',
  'PREGAVA|PREGAVANO|PREGAVO|PREGHIERA|PREGHIERE|PREGO|PREMONITORE|PREMONITORIO|PREMONIZIONE|PREMONIZIONI|PREMUR*|PREOCCUP*|PRESA DI OSTAGGI|PRESAGIO|PRESENTAZIONE|PRESENTIMENTO|PRESTITI|PRESTITO|PRETE|',
  'PRETI|PRIGIONE|PRIGIONI|PRIGIONIA|PRIGIONIERO|PRIMI|PRIMO|PRIMO APPUNTAMENTO|PRINCIPALE|PRINCIPE|PRINCIPE AZZURRO|PRINCIPE EREDITARIO|PRINCIPESSA|PRINCIPESSE|PRINCIPESSINA|PRINCIPINO|PRODIGIO|PROF|',
  'PROFESSORE|PROFESSORESSA|PROFESSORI|PROFETICO|PROFEZIA|PROFONDAMENTE|PROMESSA SPOSA|PROMESSO SPOSO|PRONTO SOCCORSO|PROPOSTA DI MATRIMONIO|PROSCIUTTO|PROVA SCRITTA|PTERODATTIL*|PUGNALE|PUGNI|PUGNO|',
  'PULCE|PULCI|PULCIN*|PULEDR*|PULENDO|PULII|PULIRE|PULITO|PULIVA|PULIVANO|PULIVO|PULIZIA|PULIZIE|PULLMAN|PUMA|PUNGIGLION*|PUNTI CARDINALI|PUPAZZO|PUPILLA|PUPILLE|QUADRANTE|QUARTA|QUARTIERE|QUARTIERI|',
  'QUARTO|QUATTRINI|QUATTRO|QUERCE|QUERCIA|QUIETE|QUINTA|QUINTE|QUINTO|RABBIA|RABBINO|RACCAPRICCIAN*|RACCOLTI|RACCOLTO|RADICATA|RADICATO|RADICE|RADICI|RADIOSA|RADIOSE|RADIOSI|RADIOSO|RADURA|RAFFICA|',
  'RAFFICHE|RAGAZZINA|RAGAZZINO|RAGGI DEL SOLE|RAGGIO DI SOLE|RAGNATEL*|RAGNETTO|RAGNI|RAGNO|RAMI|RAMO|RANA|RANCIDO|RANE|RANOCCHI*|RAPACE*|RAPIMENTI|RAPIMENTO|RAPINA|RAPINATO|RAPINE|RAPIRE|RAPITA|RAPITO|',
  'RAPITORE|RAPITORI|RASATO|RASOIO|RASSICUR*|RATTI|RATTO|RE|REGALARE|REGALATO|REGALI|REGALO|REGGIA|REGGIPETTO|REGGISENO*|REGINA|REGINE|REINCARNATO|REINCARNAZIONE|RELITTO|RENNA*|REPULSIONE|RESSA|',
  'RESURREZIONE|REVOLVER|RIBREZZO|RICATTO|RICCA|RICCHE|RICCHEZZA|RICCHEZZE|RICCHI|RICCO|RICERCA|RICORRENTE|RICOVERATA|RICOVERATO|RIDACCHIAVA|RIDACCHIAVO|RIDENDO|RIDERE|RIDEVA|RIDEVANO|RIDEVO|RIDICOL*|',
  'RIFLESSI|RIFLESSO|RILASS*|RILEVATORE DI FUMO|RIMBORSARE|RIMORS*|RIMPIANT*|RINASCERE|RINASCERE DALLE CENERI|RINASCITA|RINATA|RINATO|RINCHIUDERE|RINCHIUSA|RINCHIUSO|RINCORR*|RIPUGN*|RISATA|RISATE|',
  'RISCATTO|RISCHIO|RISCHIOSO|RISENTIMENT*|RISENTIT*|RISORGERE|RISORGEVA|RISORTA|RISORTO|RISSA|RISSE|RISSOSO|RISTORANTE|RISTORANTI|RISURREZIONE|RISVEGLIO|RITARDATA|RITARDATO|RITARDI|RITARDO|RITRATTO|',
  'RITROVARE|RITROVATO|RIUNIONE|RIUNIONI|RIVA|RIVALE|RIVALI|ROBOT|ROBOTTINO|ROCCA|ROCCE|ROCCIA|RODITOR*|ROGO|ROMANZI|ROMANZO|RONDINE*|ROSA|ROSARIO|ROSE|ROSETI|ROSETO|ROSPO*|ROSSA|ROSSE|ROSSETT*|ROSSI|',
  'ROSSO|ROTATORIA|ROTONDA|ROTTURA|ROTTURE|ROVINA|ROVINATA|ROVINATO|ROVINE|RUBATA|RUBATO|RUDERE|RUDERI|RUGA|RUGHE|RUSCELLI|RUSCELLO|SABBIA|SABBIE|SACCA|SACCHETTO|SACERDOTE|SACERDOTI|SACRIFICATA|',
  'SACRIFICATO|SACRIFICI|SACRIFICIO|SAGOMA|SAHARA|SALA D ATTESA|SALA DEL TRONO|SALATA|SALATO|SALE|SALIERA|SALINA|SALIVO|SALMA|SALME|SALSICCE|SALSICCIA|SALTAI|SALTANDO|SALTARE|SALTATO|SALTAVA|SALTAVANO|',
  'SALTAVO|SALTI|SALTO|SALTO D ACQUA|SALVADANAIO|SANDALI|SANDALO|SANGUE|SANGUINA|SANGUINANTE|SANGUINARE|SANGUINAVA|SANGUINOSO|SANTUARI|SANTUARIO|SAPEVO CHE STAVO SOGNANDO|SAPEVO DI SOGNARE|SARCOFAGO|',
  'SASSI|SASSO|SATANA|SBARRE|SBRIGARMI|SCALA|SCALA A PIOLI|SCALA DI CORDA|SCALA MOBILE|SCALARE|SCALATA|SCALATO|SCALAVA|SCALAVO|SCALE|SCALE MOBILI|SCALETTA|SCALINATA|SCALZA|SCALZO|SCANTINATO|SCAPPARE|',
  'SCAPPATELLA|SCAPPATO|SCAPPAVA|SCAPPAVO|SCARAB*|SCARAFAGG*|SCARLATTO|SCARPA|SCARPE|SCARPETT*|SCASSO|SCATOLA|SCATOLE|SCATOLONI|SCAZZOTTATA|SCENDENDO|SCENDERE|SCENDEVA|SCENDEVANO|SCENDEVO|SCENDO|SCESA|',
  'SCESE|SCESI|SCESO|SCHEGGE DI VETRO|SCHELETRI|SCHELETRO|SCHERMO|SCHIANTATO|SCHIANTO|SCHIENA|SCHIFO|SCHIFOS*|SCIABOLA|SCIAMANI|SCIAMANO|SCIAME*|SCIMITARRA|SCIMMIA|SCIMMIE|SCIMMIETT*|SCIMPANZE*|',
  'SCOGLIERA|SCONFORT*|SCONOSCIUTA|SCONOSCIUTE|SCONOSCIUTI|SCONOSCIUTO|SCONSOLAT*|SCONTRO|SCOOTER|SCOPERTA|SCOPERTO|SCOPRII|SCOPRIRE|SCORPIONE|SCORPIONI|SCOSSA DI TERREMOTO|SCRIGNO|SCRISSE|SCRISSI|',
  'SCRITTA|SCRITTO|SCRITTURA|SCRIVANIA|SCRIVENDO|SCRIVERE|SCRIVEVA|SCRIVEVANO|SCRIVEVO|SCRIVO|SCROFA*|SCUOLA|SCUOLE|SECCATA|SECCATO|SECONDA|SEDIA|SEDIE|SEDOTTA|SEDOTTO|SEDUCEVA|SEDURRE|SEDUTTORE|',
  'SEDUTTRICE|SEDUZIONE|SELEZIONATORE|SELVA|SELVE|SEMINARIO|SEMINTERRATO|SEMPRE LO STESSO|SENTIERI|SENTIERO|SENZA|SENZA USCITA|SENZA VITA|SENZATETTO|SEPARAZIONE|SEPARAZIONI|SEPOLCRO|SEPOLTA|SEPOLTO|',
  'SEPOLTURA|SEPPELLIRE|SEPPELLITA|SEPPELLITO|SEPPELLIVA|SEQUESTRATA|SEQUESTRATO|SEQUESTRO|SERAFINO|SERENA|SERENAMENTE|SERENE|SERENI|SERENITA|SERENO|SERGENTE|SERPENT*|SERRATURA|SERRATURE|',
  'SERVIZI IGIENICI|SESSO|SESSUALE|SESSUALI|SESSUALITA|SESTA|SESTO|SETE|SETTE|SETTIMA|SETTIMO|SFERA DI CRISTALLO|SFREGI|SFREGIO|SGABELLO|SGOMENT*|SGRETOLATO|SI AVVERO|SI E AVVERATO|SI INNAMORO|',
  'SI SCHIANTO|SI SGRETOLAVA|SI TRASFORMO|SINAGOGA|SINGHIOZZAVO|SINGHIOZZI|SIPARIO|SIRENA|SIRENE|SIRENETTA|SISMA|SISMI|SLIP|SMALTO|SMALTO PER UNGHIE|SMARRIRMI|SMARRITA|SMARRITO|SMERALDO|SOCIO|SOFFITTA|',
  'SOFFITTE|SOFFOCARE|SOFFOCATO|SOFFOCAVO|SOGLIA|SOGNI LUCIDI|SOGNI RICORRENTI|SOGNO LUCIDO|SOGNO RICORRENTE|SOLAIO|SOLDATI|SOLDATO|SOLDI|SOLE|SOLEGGIATA|SOLEGGIATO|SOLITARIA|SOLITARIO|SOLITUDINE|',
  'SOLLEVATA|SOLLEVATO|SOLLIEVO|SOMMERSA|SOMMERSO|SONO PERSA|SONO PERSO|SORCI|SORCIO|SORDA|SORDI|SORDITA|SORDO|SORELLA|SORELLE|SORELLINA|SORGENTE|SORGENTI|SORGERE DEL SOLE|SORPRESA|SORPRESI|SORPRESO|',
  'SORTILEGI*|SOSIA|SOTTOPASSAGGIO|SOTTOTETTO|SOVRANA|SOVRANO|SPADA|SPADE|SPAGO|SPALLA|SPALLE|SPARATORIA|SPARI|SPARO|SPARVIERO*|SPASIMANTE|SPAVENT*|SPAZIO|SPAZZARE|SPAZZAVO|SPECCHI|SPECCHIETTO|SPECCHIO|',
  'SPELONCA|SPETTRALE|SPETTRI|SPETTRO|SPIAGGE|SPIAGGIA|SPICCIOLI|SPIGHE|SPINA DORSALE|SPIRALE|SPIRALI|SPIRITI|SPIRITO|SPLENDENTE|SPLENDID*|SPONDA|SPONDE|SPORTELLO|SPOSA|SPOSARE|SPOSARSI|SPOSATA|SPOSATI|',
  'SPOSATO|SPOSAVA|SPOSI|SPOSO|SPUMANTE|SPUNTARE DEL GIORNO|SQUALI|SQUALO|SQUATTRINATA|SQUATTRINATO|SRADICATA|SRADICATO|STAGNI|STAGNO|STALLON*|STANZA DA LETTO|STANZA NASCOSTA|STANZA SCONOSCIUTA|',
  'STANZA SEGRETA|STAZIONE|STAZIONI|STELLA|STELLA CADENTE|STELLATA|STELLATO|STELLE|STESSO SOGNO|STIPENDIO|STIVALE|STIVALI|STIZZ*|STOMACO|STRACCI|STRADA|STRADE|STRADINA|STRADINE|STREGA|STREGHE|STREGONE|',
  'STREGONERIA|STREGONI|STRESS|STRESSAT*|STRUGGIMENT*|STUPEFATT*|STUPITA|STUPITI|STUPITO|STUPORE|SUA MOGLIE|SUBLIME|SUL LASTRICO|SUOCERA|SUOCERI|SUOCERO|SUOLO|SUORA|SUORE|SUPER POTERI|SUPEREROE|',
  'SUPEREROI|SUPEREROINA|SUPERMERCATO|SUPERPOTER*|SUPERVISORE|SVALIGIATA|SVALIGIATO|SVEGLIA|SVEGLIANDOMI|SVEGLIARE|SVEGLIARMI|SVEGLIATA|SVEGLIATO|SVEGLIAVA|SVEGLIAVO|SVESTITA|SVESTITO|T REX|TACCHI ALTI|',
  'TAMPONAMENTO|TANTA|TANTO|TARANTOLA*|TARDI|TAROCCHI|TARTARUGA|TARTARUGHE|TARTARUGHINA|TASSI|TASSISTA|TASTIERA|TAVOLA|TAVOLI|TAVOLINO|TAVOLO|TAXI|TEATRI|TEATRO|TEGOLA|TEGOLE|TELECINESI|TELEFONARE|',
  'TELEFONATA|TELEFONI|TELEFONO|TELEVISIONE|TELEVISORE|TEMPERINO|TEMPESTA|TEMPESTE|TEMPIO|TEMPLI|TEMPORALE|TEMPORALI|TENEBRE|TENERAMENTE|TENEREZZA|TENSIONE|TERMINAL|TERMITE*|TERRA|TERRE|TERREMOTI|',
  'TERREMOTO|TERRENI|TERRENO|TERRIBILMENTE|TERRIFICANT*|TERRORE|TERRORI|TERRORISMO|TERRORISTA|TERRORISTI|TERRORIZZAT*|TERZA|TERZA ETA|TERZO|TESCHI|TESCHIO|TESORI|TESORO|TESORO NASCOSTO|TEST|TESTA|',
  'TESTAMENTO|TESTE|TESTUGGINE|TESTUGGINI|TETTI|TETTO|TIARA|TIFONE|TIGRE|TIGRI|TIGROTT*|TIMORE|TIMORI|TIRANNOSAUR*|TISANA|TITANI|TITANO|TITOLARE|TIVU|TOGA|TOMBA|TOMBE|TONSILLE|TOPI|TOPO|TOPO DI FOGNA|',
  'TOPOLINO*|TORCIA|TORERO*|TORI|TORNADO|TORNARE IN VITA|TORNATA IN VITA|TORNATO IN VITA|TORO|TORRE|TORRENTE|TORRENTI|TORRETTA|TORRI|TORTA|TORTE|TORTORA*|TOSSICA|TOSSICO|TOTALMENTE|TOVAGLIA|',
  'TRA LE SUE BRACCIA|TRADIMENTI|TRADIMENTO|TRADITA|TRADITO|TRAFFICO|TRAFORO|TRAGHETTO|TRAM|TRAMONTI|TRAMONTO|TRAMPOLINO|TRANCE|TRANQUILL*|TRASFORMARSI|TRASFORMATA|TRASFORMATO|TRASFORMAVA|TRASFORMAZIONE|',
  'TRASLO*|TRATTORIA|TRAVESTIMENT*|TRAVESTIRMI|TRAVESTIRSI|TRAVESTITA|TRAVESTITO|TRE|TRECCE|TRECCIA|TREDICESIMA|TREDICESIMO|TREDICI|TREMANTE|TREMANTI|TREMAVA|TREMAVO|TRENI|TRENO|TRESCA|TRICERATOPO|',
  'TRINCEA|TRINCEE|TRIO|TRIST*|TRITONE|TROLL|TROLLEY|TRONCHI|TRONCO|TROPPO|TROPPO TARDI|TROTA*|TROTTOLA|TROVAI|TROVANDO|TROVARE|TROVATA|TROVATO|TROVO|TRUCCARMI|TRUCCARSI|TRUCCAT*|TRUCCHI|TRUCCO|TSUNAMI|',
  'TUFFATO|TUFFAVO|TUFFO|TULIPANI|TULIPANO|TUNNEL|TUONI|TUONO|TUORLO|TURBAMENTO|TURBATA|TURBATO|TURCHESE|TUTA|TUTE|TUTTE LE NOTTI|TV|UBRIACA|UBRIACO|UCCELL*|UCCELLO DI FUOCO|UCCIDE|UCCIDERE|UCCIDEVA|',
  'UCCIDO|UCCISA|UCCISE|UCCISO|UFFICI|UFFICIO|UFO|UMILIA*|UNA PORTA|UNGHIA|UNGHIE|UNICORNI|UNICORNO|UNIFORME|UNIFORMI|UNIVERSITA|UNIVERSO|UOMO NERO|UOVA|UOVO|URAGANI|URAGANO|URLA|URLARE|URLATO|URLAVA|',
  'URLAVO|URLO|USCIO|USCIRE CON|USCIVO CON|USIGNOL*|UVA|VACCA|VACCHE|VAGONE|VALIGIA|VALIGIE|VALLATA|VALLATE|VALLE|VALLI|VALZER|VAMPIRA|VAMPIRI|VAMPIRO|VASCA DA BAGNO|VECCHIA CASA|VECCHIAIA|VECCHIETTA|',
  'VECCHIETTO|VEGGENTE|VEGGENTI|VEGLIA FUNEBRE|VEGLIARDO|VELENI|VELENO|VELENOSA|VELENOSO|VELIERO|VELO DA SPOSA|VELOCIRAPTOR*|VENDE|VENDENDO|VENDERE|VENDEVA|VENDEVANO|VENDEVO|VENDITA|VENDITORE|VENDITRICE|',
  'VENDO|VENDUTA|VENDUTO|VENTO|VENTOSO|VENTRE|VERAMENTE|VERDASTRO|VERDE|VERDI|VERDURA|VERDURE|VERGOGN*|VERIFICA|VERME|VERMETTO|VERMI|VERTEBRA|VERTEBRE|VESCOVO|VESPA|VESPE|VESTITI|VESTITI MACCHIATI|',
  'VESTITI SPORCHI|VESTITI STRAPPATI|VESTITINO*|VESTITO|VESTITO BIANCO|VESTITO DA SERA|VESTITO DA SPOSA|VETRATA|VETRI ROTTI|VETRO ROTTO|VETTA|VETTE|VIA LATTEA|VIADOTTO|VIAGGI NEL TEMPO|',
  'VIAGGIARE NEL TEMPO|VIAGGIAVO NEL TEMPO|VIAGGIO NEL TEMPO|VIALE|VIALI|VICINA DI CASA|VICINATO|VICINI DI CASA|VICINO DI CASA|VICOLI|VICOLO|VIGILE|VIGILI DEL FUOCO|VILLA|VILLAGGI|VILLAGGIO|VINI|VINO|',
  'VIOLA|VIOLE|VIOLETTA|VIOLETTO|VIP|VIPERA*|VIPERE|VIRUS|VISI|VISO|VITA PRECEDENTE|VITE PRECEDENTI|VITELL*|VOCE|VOCI|VODKA|VOGLIO BENE|VOLAI|VOLANDO|VOLANTE|VOLARE|VOLATO|VOLAVA|VOLAVANO|VOLAVO|',
  'VOLEVA BENE|VOLEVO BENE|VOLO|VOLPACCHIOTT*|VOLPE|VOLPI|VOLTA CELESTE|VOLTI|VOLTO|VOMITANDO|VOMITARE|VOMITATO|VOMITAVA|VOMITAVO|VOMITO|VULCANI|VULCANICO|VULCANO|WATER|WC|YOGA|ZAINO|ZAMPILLO|ZANZAR*|',
  'ZEN|ZIA|ZIE|ZII|ZIO|ZOMBI|ZOMBIE|ZOO|ZUCCHERO FILATO|ZUFFA|ZUFFE|');
 KTAR : Array[1..NKEY] Of Integer = (
  392,401,401,401,402,403,392,392,393,393,393,394,
  394,394,395,395,395,396,396,396,397,397,397,398,
  398,398,399,399,399,400,400,400,1029,238,261,108,
  1084,1084,1084,291,291,290,91,52,320,320,2001,1082,
  411,411,411,411,411,311,311,311,311,351,351,351,
  351,351,351,351,351,351,123,123,123,123,1042,1017,
  373,135,135,211,211,330,330,330,1015,1015,1015,1015,
  1058,1068,128,1062,1062,1062,1062,1062,63,304,304,304,
  407,407,407,407,116,116,42,42,42,198,182,1016,
  1016,1016,1016,1016,1016,1016,1016,87,87,418,418,418,
  177,325,325,140,418,418,426,426,1007,66,136,370,
  370,370,370,301,301,120,120,120,120,1013,368,368,
  368,181,181,106,79,374,139,433,283,283,283,283,
  283,1055,32,32,183,183,103,121,361,26,1056,1025,
  1045,1045,1045,1045,99,52,441,441,177,285,285,138,
  138,173,1063,1063,1063,46,1,1,50,19,19,19,
  19,272,283,283,272,337,273,17,17,133,441,406,
  406,406,215,416,152,152,33,33,407,408,408,408,
  408,347,346,346,336,336,336,70,257,266,266,298,
  279,279,197,407,407,407,407,407,407,407,253,253,
  253,253,253,253,253,1019,253,253,253,419,419,419,
  253,210,210,122,421,206,277,163,163,277,2000,2000,
  290,103,277,277,295,295,215,215,215,433,433,206,
  206,218,218,335,335,335,335,159,159,6,6,98,
  98,98,210,210,385,385,64,239,239,222,222,409,
  409,409,409,206,183,378,183,319,439,319,148,142,
  142,142,142,369,369,244,363,193,94,94,257,257,
  257,48,196,196,196,320,320,202,341,202,129,129,
  158,341,342,341,329,329,341,341,341,8,302,302,
  302,104,334,104,104,104,104,212,205,287,287,357,
  357,74,167,167,409,404,404,212,212,256,256,256,
  256,256,114,110,111,113,113,91,165,63,109,115,
  302,302,302,302,302,302,302,302,360,4,35,4,
  178,366,51,61,32,440,32,32,32,175,175,59,
  59,214,214,368,368,1029,1018,325,325,326,219,184,
  184,223,223,337,223,337,223,366,78,60,369,369,
  162,382,382,382,382,382,76,31,31,93,93,93,
  93,93,93,385,362,385,385,385,385,385,376,376,
  362,362,361,33,33,61,61,336,18,336,189,176,
  189,336,404,404,405,405,334,334,251,251,251,251,
  1003,1003,9,424,360,360,13,360,18,18,357,357,
  357,78,83,326,83,226,226,436,184,78,12,12,
  12,12,12,133,133,180,180,180,180,319,319,319,
  298,159,343,22,22,175,175,12,52,52,169,169,
  270,270,122,198,198,200,200,200,161,161,221,184,
  184,263,263,19,19,415,415,415,87,263,263,162,
  63,129,129,319,319,191,442,30,30,6,263,263,
  263,30,30,30,30,336,60,344,344,215,42,42,
  339,336,336,336,178,152,143,323,242,242,242,242,
  48,242,242,242,242,242,242,242,242,156,156,305,
  305,190,190,171,171,182,76,76,333,333,333,333,
  205,205,193,27,27,66,412,364,376,376,1022,289,
  81,120,120,415,415,415,415,415,415,410,202,41,
  95,76,349,349,349,35,186,80,80,212,162,16,
  16,361,435,361,158,420,420,1041,1041,420,1041,420,
  360,406,200,411,334,334,68,68,410,410,90,90,
  363,331,331,46,46,219,219,343,197,197,223,197,
  197,298,298,252,10,10,360,409,412,412,308,308,
  412,412,412,287,287,1051,1051,1051,232,36,36,144,
  309,309,26,26,144,208,98,123,123,123,123,267,
  267,144,156,338,338,161,158,300,300,306,306,59,
  320,320,147,1077,1077,1077,1077,188,188,202,202,1018,
  1018,1018,297,297,297,140,140,163,153,140,31,404,
  325,31,180,180,252,245,245,245,437,245,414,245,
  245,245,245,245,245,123,123,256,256,360,286,287,
  287,261,404,305,305,404,339,143,34,44,157,157,
  157,34,34,34,34,34,215,225,357,81,73,73,
  213,213,345,345,218,218,356,19,19,55,236,236,
  236,236,236,236,236,236,236,340,368,368,1021,1021,
  1021,1021,283,283,36,183,36,81,81,81,314,85,
  85,78,78,78,78,59,138,35,35,35,35,440,
  440,64,35,35,131,131,131,323,323,323,348,348,
  348,245,43,44,282,315,55,229,229,229,10,229,
  229,10,94,94,94,94,267,180,180,267,82,82,
  15,15,308,308,396,396,396,300,157,158,28,28,
  265,18,18,276,154,350,350,174,170,35,170,170,
  170,155,155,149,149,241,241,133,133,33,51,62,
  315,55,74,373,373,346,346,90,90,189,339,189,
  189,189,189,122,81,254,226,254,1065,1065,69,346,
  346,346,154,346,346,184,184,15,15,411,45,105,
  431,431,243,1012,1012,1012,145,347,128,368,368,1018,
  2001,1020,299,260,341,239,206,206,206,347,347,1033,
  1033,1033,334,346,1096,1096,1096,348,118,119,260,260,
  260,347,346,266,266,256,95,1004,1004,1004,1004,350,
  350,260,260,120,120,239,120,120,74,74,22,43,
  306,306,187,187,187,187,425,43,79,79,79,305,
  60,151,151,279,356,106,375,375,278,278,278,87,
  87,201,29,391,33,166,151,151,406,173,381,409,
  1092,1092,368,368,406,409,93,93,154,232,232,232,
  271,232,232,185,185,185,185,176,232,232,232,117,
  117,117,117,186,186,327,291,327,6,1052,1052,1052,
  1052,1052,1052,1052,384,384,310,310,67,411,29,29,
  353,353,440,440,334,278,278,240,240,240,240,240,
  240,240,51,240,66,66,66,219,219,212,319,319,
  289,422,33,289,289,289,289,309,141,141,141,86,
  86,364,1092,290,290,1037,1037,1037,1037,1037,186,143,
  349,416,433,214,270,270,75,75,75,75,340,59,
  59,293,293,293,421,421,421,421,421,275,376,244,
  244,244,244,244,244,244,244,244,244,244,71,71,
  49,49,340,261,313,313,313,313,303,210,210,164,
  301,237,237,237,237,237,237,160,160,282,282,3,
  3,405,313,313,313,313,1091,229,363,261,262,262,
  164,164,1081,1081,1081,1032,1032,1032,7,378,252,138,
  138,114,115,284,284,284,237,237,80,80,80,80,
  80,355,238,238,238,342,305,305,1082,20,20,1064,
  412,412,250,250,250,250,250,250,250,250,250,250,
  250,1064,1064,1064,17,17,17,17,1079,1079,108,108,
  1083,1083,1083,1083,1083,248,248,322,322,36,418,1028,
  1028,1028,1028,1028,156,1071,405,1086,353,353,307,393,
  393,393,250,250,250,318,318,1017,284,284,284,185,
  184,184,282,282,377,442,442,442,442,442,345,345,
  298,341,282,282,282,282,282,379,379,379,379,379,
  379,401,401,401,401,419,419,131,131,103,103,337,
  138,157,157,391,391,391,391,140,140,391,391,105,
  224,224,224,224,1020,142,142,361,402,402,402,402,
  428,423,423,423,380,380,380,201,208,243,13,13,
  405,1,302,11,1,375,1035,417,384,384,93,231,
  231,231,409,192,192,192,192,105,96,269,276,276,
  269,246,191,191,280,280,280,1091,154,154,154,154,
  204,174,189,255,255,255,255,255,255,255,255,255,
  255,255,417,417,417,417,417,92,292,256,256,417,
  417,417,417,417,417,415,1045,1047,248,248,248,287,
  287,65,65,65,65,432,432,232,190,211,1090,349,
  349,12,12,226,226,219,410,369,369,369,369,369,
  369,369,369,386,1034,204,252,254,254,1019,343,345,
  416,416,416,416,416,156,353,353,353,1019,1019,1019,
  1019,210,232,421,337,263,410,340,364,238,1029,96,
  96,188,188,188,439,439,1005,439,1005,261,353,353,
  353,1068,112,112,293,254,254,254,254,254,254,254,
  293,231,231,231,231,231,376,376,376,376,376,413,
  413,12,12,9,9,9,135,135,135,135,20,20,
  20,1067,1067,1067,1067,316,316,132,132,132,264,264,
  439,439,93,93,307,307,307,307,307,307,307,1009,
  188,344,344,349,349,349,258,258,404,176,176,228,
  228,228,228,228,1041,427,1012,87,87,213,213,199,
  199,42,31,161,95,92,31,371,119,371,119,1048,
  118,239,239,297,297,375,375,248,29,29,192,249,
  146,146,146,146,69,357,199,129,129,279,333,285,
  301,52,257,91,91,166,248,248,36,36,5,5,
  266,266,266,266,1038,106,106,106,106,121,121,121,
  121,440,376,376,376,376,440,1008,337,418,418,418,
  418,290,141,374,374,374,374,374,374,374,374,374,
  1008,239,239,1070,405,405,405,405,405,405,405,405,
  333,1008,1008,1008,1008,1008,99,298,426,426,2001,89,
  176,436,342,342,330,330,375,351,375,15,15,117,
  117,117,117,330,330,12,285,285,59,59,365,432,
  1035,342,342,303,42,32,202,202,32,32,259,259,
  1062,1062,424,424,424,424,1040,424,34,437,148,148,
  212,329,329,329,329,329,263,263,410,21,21,21,
  21,21,263,378,378,378,378,378,378,187,1010,1010,
  1010,1010,1010,95,95,95,241,241,241,226,112,112,
  112,112,441,441,200,200,267,200,200,263,263,263,
  1,1,22,22,22,22,22,22,4,4,128,128,
  380,380,380,9,9,2001,365,28,11,11,434,18,
  18,439,157,354,246,269,269,236,236,236,122,122,
  141,53,53,53,53,141,141,199,320,320,114,115,
  115,114,1049,1049,207,207,207,207,207,207,114,114,
  114,43,334,334,337,141,356,224,224,257,257,257,
  320,320,1070,231,231,281,281,281,281,281,281,307,
  307,1066,1066,1066,1066,1066,406,406,406,96,231,231,
  231,231,12,1006,1006,1006,1006,1006,1006,279,279,221,
  221,27,145,27,112,112,112,112,209,209,209,322,
  322,322,25,431,431,431,431,293,8,8,1089,1089,
  128,128,1089,1089,1089,1089,61,86,86,156,420,420,
  96,8,172,8,8,8,8,8,8,273,199,432,
  432,62,106,336,336,106,64,106,112,112,26,26,
  200,72,297,297,150,198,92,314,44,161,116,116,
  329,303,1040,1040,116,116,116,1020,165,164,249,249,
  249,145,145,67,255,249,249,249,249,249,249,249,
  95,390,390,390,390,390,38,38,96,96,26,26,
  367,64,40,51,2000,203,404,404,404,130,130,341,
  297,297,356,356,367,367,186,367,1071,1071,1071,1071,
  1071,1071,276,201,169,169,57,285,285,285,285,331,
  331,1031,1031,1031,360,97,2,165,316,25,25,317,
  317,317,317,317,317,317,317,1003,1033,1003,1003,44,
  44,345,41,415,1087,1087,1087,155,155,182,182,1050,
  1050,1051,1051,1050,301,155,155,1073,1073,1073,163,163,
  3,148,353,399,399,399,1088,240,240,240,240,240,
  440,440,423,423,232,14,14,14,14,14,290,382,
  382,2001,241,241,159,125,361,241,439,241,156,410,
  410,410,410,80,80,121,121,121,121,1086,1086,2001,
  355,1072,121,121,127,90,95,293,293,293,373,373,
  373,373,131,131,131,131,307,7,7,7,7,7,
  7,1057,51,1063,128,132,132,14,2001,174,239,239,
  219,414,1037,415,404,435,435,435,82,272,272,1069,
  1085,325,325,325,40,11,11,11,1073,1073,1073,2000,
  86,86,326,24,292,24,24,24,24,387,387,327,
  387,387,387,234,232,260,282,210,427,197,371,343,
  1001,1001,195,195,195,184,184,1002,1002,1002,1002,1007,
  441,136,136,136,136,36,18,18,356,356,419,419,
  301,365,413,413,413,413,413,413,226,226,432,301,
  340,299,147,165,373,35,160,160,160,5,5,5,
  5,324,324,324,324,324,324,186,181,181,181,181,
  181,107,107,181,181,58,58,372,372,247,247,70,
  187,143,142,257,257,257,29,257,208,373,1033,317,
  317,317,331,331,40,432,176,176,277,277,228,83,
  83,373,337,337,1032,1032,1032,1032,1032,348,348,348,
  348,425,425,58,389,69,367,364,340,39,39,39,
  39,175,175,175,201,201,201,13,175,175,344,208,
  138,70,367,366,354,354,37,430,37,430,299,37,
  37,37,148,260,260,284,1053,1053,276,276,276,276,
  276,265,265,265,265,366,366,366,181,432,432,243,
  243,243,243,243,354,354,354,430,430,154,372,372,
  373,373,119,182,64,305,436,83,83,161,161,439,
  439,439,439,29,1039,1039,339,188,188,84,84,138,
  139,139,139,139,139,285,139,138,132,297,370,370,
  124,1039,1039,1094,105,88,95,95,95,95,1094,1094,
  129,1078,189,189,109,109,116,65,65,116,345,300,
  300,388,318,318,318,318,318,318,318,157,227,227,
  227,227,145,145,361,296,296,102,197,365,146,146,
  5,12,12,3,3,5,28,28,22,118,371,371,
  371,371,371,371,194,194,118,424,49,49,426,426,
  365,193,193,193,164,201,109,34,34,309,1084,389,
  389,243,243,248,248,248,238,372,259,259,373,373,
  81,81,131,131,296,296,296,296,296,296,298,120,
  120,1080,261,414,414,414,414,414,414,414,414,257,
  355,355,355,355,89,89,1074,2,130,109,109,41,
  41,2,1036,41,287,315,315,315,343,216,158,216,
  304,304,304,408,408,408,37,37,319,328,328,328,
  328,88,130,130,354,354,34,34,275,294,294,294,
  294,294,172,172,348,355,355,355,176,55,55,406,
  406,217,357,291,41,291,335,335,335,31,31,80,
  80,86,86,35,136,118,124,124,291,291,291,291,
  338,366,366,422,422,422,422,15,15,15,249,249,
  152,196,182,182,15,191,305,1084,1084,303,429,303,
  429,303,303,303,303,1088,1088,303,429,288,288,217,
  163,217,217,217,54,54,54,304,304,304,304,304,
  304,304,104,104,51,63,315,99,99,99,99,57,
  122,149,149,149,149,149,149,57,440,440,440,440,
  315,50,2000,233,233,233,233,233,233,233,233,233,
  432,432,432,311,311,311,311,203,311,311,101,101,
  213,213,97,97,212,212,212,1083,1083,2000,308,308,
  328,311,9,9,9,9,437,1060,1060,1060,1060,311,
  257,400,400,400,117,101,2000,117,292,371,371,275,
  275,187,187,383,383,383,383,383,91,291,291,1080,
  350,139,195,113,113,318,318,243,252,113,113,113,
  252,153,234,234,234,234,234,234,234,234,234,234,
  234,108,268,268,268,268,108,108,108,268,268,108,
  275,275,2000,88,108,275,307,2,2,2,101,82,
  327,327,190,190,295,295,190,422,422,422,41,438,
  41,41,179,179,327,327,105,105,117,117,437,437,
  102,102,344,135,1061,354,340,340,269,269,269,269,
  64,388,388,388,388,174,174,174,174,100,201,201,
  100,375,48,48,85,310,310,308,420,420,270,270,
  38,38,38,38,258,258,258,258,258,258,258,258,
  258,258,258,258,426,426,350,288,288,319,319,1024,
  1024,163,168,168,168,146,90,1058,363,356,40,194,
  194,357,77,77,77,77,110,110,290,116,107,107,
  55,116,212,190,292,292,241,179,179,179,179,24,
  24,361,111,111,111,111,361,149,149,287,368,239,
  239,2000,409,153,170,224,224,220,220,290,331,331,
  110,110,253,253,322,322,345,345,345,25,25,25,
  84,84,82,82,355,355,355,138,351,351,345,92,
  92,214,207,214,167,299,299,299,299,299,24,24,
  195,195,184,182,182,379,340,411,411,235,235,235,
  235,235,235,235,235,235,248,348,348,235,235,235,
  110,110,421,421,421,421,335,335,184,184,41,41,
  81,148,148,134,435,435,235,235,22,22,368,112,
  277,368,112,338,358,364,241,241,1048,1048,1044,1044,
  438,438,177,344,177,177,177,177,129,153,338,153,
  153,153,338,338,338,338,153,338,338,85,254,254,
  27,309,27,309,45,73,167,167,211,406,406,1083,
  133,13,13,93,93,1004,1004,197,228,228,166,228,
  279,279,242,242,265,1030,247,247,247,247,247,247,
  247,247,6,6,6,233,233,167,233,233,6,6,
  77,342,6,337,186,186,147,84,84,84,84,277,
  198,320,320,416,416,46,46,46,128,128,128,128,
  285,321,331,321,331,89,89,321,321,410,410,36,
  220,157,220,220,62,62,62,173,147,147,211,147,
  153,147,147,337,147,147,177,177,419,284,284,344,
  224,349,328,24,24,120,120,103,103,9,74,36,
  74,74,74,194,194,194,194,230,389,389,335,335,
  335,335,230,230,230,230,230,230,230,230,230,230,
  74,241,241,25,25,323,323,25,421,262,262,262,
  392,377,392,392,392,262,262,262,262,262,290,290,
  286,286,286,286,286,286,286,286,286,286,126,126,
  126,127,127,126,420,420,420,156,156,156,156,156,
  294,294,132,132,132,132,2001,132,166,262,262,262,
  82,82,172,442,1096,28,356,356,40,40,51,82,
  82,33,209,209,158,158,395,395,395,1024,290,20,
  20,1009,1009,1009,271,271,1067,208,67,320,320,146,
  377,335,1075,420,1075,42,199,413,104,104,122,1025,
  56,56,227,227,227,227,227,227,227,227,227,56,
  56,1005,1005,1005,16,16,1005,1043,1043,1043,413,413,
  264,276,276,264,3,260,236,31,31,1031,349,349,
  349,261,255,255,261,261,172,172,141,1085,1085,1085,
  1085,1085,301,301,301,125,125,1011,1027,291,291,353,
  353,353,436,436,436,1093,149,149,312,438,312,312,
  312,438,72,72,72,72,377,377,304,59,348,348,
  318,1091,47,47,216,312,312,312,312,312,162,162,
  312,238,238,238,238,238,347,347,260,261,261,259,
  259,259,259,259,259,259,259,259,329,259,312,312,
  312,260,261,1072,406,246,246,246,246,246,354,354,
  354,354,92,166,92,1094,246,246,246,246,365,246,
  246,246,13,13,135,135,135,4,4,4,4,409,
  409,358,359,358,359,359,358,358,359,358,359,433,
  433,27,27,27,27,27,124,124,175,175,372,372,
  372,372,219,57,23,23,23,23,23,41,326,384,
  365,384,384,73,218,218,124,52,159,159,159,159,
  164,342,164,4,4,372,372,262,119,13,13,182,
  199,199,178,178,178,222,178,295,295,295,295,295,
  178,17,316,316,316,101,316,316,331,331,343,332,
  332,332,332,332,209,155,142,142,154,347,166,168,
  288,288,357,316,316,316,316,316,62,247,2000,355,
  207,160,342,325,19,19,306,306,284,326,326,19,
  19,251,251,251,251,251,251,251,251,51,251,260,
  51,185,217,71,71,355,243,243,243,378,315,347,
  347,393,393,380,380,380,380,380,380,380,380,274,
  274,332,177,332,347,218,218,372,372,398,398,398,
  309,309,413,413,413,283,283,1023,1023,1023,1023,1023,
  130,33,33,171,171,162,162,162,147,375,198,375,
  375,375,375,375,351,344,350,350,418,350,350,350,
  289,350,350,121,121,64,1053,1053,437,437,274,397,
  397,397,364,364,173,173,115,115,202,336,273,130,
  130,264,264,1081,1081,1081,213,275,213,15,15,136,
  427,427,427,427,427,377,411,439,377,136,136,20,
  20,426,426,271,1095,1095,1095,325,1026,357,145,11,
  11,100,100,100,100,57,57,18,144,144,364,364,
  144,144,364,124,125,285,285,285,300,300,1039,1039,
  232,47,47,310,310,310,123,123,216,326,326,309,
  1059,364,364,1036,1040,1040,7,7,334,334,334,334,
  248,248,434,434,434,434,434,434,345,161,434,434,
  166,166,100,56,1038,1038,1038,1038,1038,288,288,442,
  409,409,203,203,203,203,362,202,202,357,117,117,
  54,54,50,298,322,322,60,60,225,225,204,434,
  173,173,173,173,204,204,2001,270,270,288,288,1014,
  1014,275,356,362,356,211,51,273,274,274,273,273,
  1047,1047,2001,1046,1046,1046,1046,1046,419,419,419,191,
  317,67,88,377,310,88,173,208,333,166,166,337,
  337,185,223,223,40,338,333,333,431,431,223,418,
  362,362,50,50,143,150,150,150,150,331,331,229,
  229,229,381,229,381,229,229,381,381,309,309,229,
  381,278,278,229,381,381,269,269,270,270,4,4,
  68,68,68,2001,131,261,195,165,439,165,165,165,
  1061,160,45,108,282,1081,108,1081,35,35,416,416,
  227,208,216,404,404,1027,296,315,315,315,315,230,
  230,230,343,343,343,343,343,343,343,363,363,362,
  403,403,1054,1054,1054,1054,274,274,361,303,313,313,
  313,2001,339,339,339,81,81,442,394,1011,1076,1076,
  1076,1076,394,394,314,394,19,19,2001,238,159,159,
  171,63,170,170,237,237,237,237,237,237,62,46,
  3,408,408,408,408,408,408,150,150,22,22,221,
  221,385,100,442,208,182,147,165,362,362,279,154,
  155,143,61,61,3,3,16,222,222,16,16,16,
  16,244,428,428,428,428,42,61,61,123,123,307,
  214,442,214,352,352,352,352,352,352,352,352,352,
  403,352,352,352,416,416,416,271,352,352,271,91,
  91,271,70,70,386,386,386,24,24,8,384,70,
  102,191,191,324,171,171,70,386,386,105,105,386,
  386,361,361,151,151,164,356,367,356,367,367,367,
  367,1074,1074,1074,1074,220,326,326,301,134,134,134,
  134,134,314,314,314,314,314,314,314,314,301,134,
  138,169,169,169,158,158,325,325,389,389,389,389,
  33,348,95,89,89,347,148,191,191,148,191,325,
  208,279,359,359,212,137,137,137,137,137,206,195,
  206,99,415,228,228,228,228,29,29,29,228,148,
  148,129,129,129,129,205,97,97,97,97,97,97,
  97,97,97,97,97,267,436,436,436,436,436,98,
  98,298,298,298,2001,225,214,208,208,143,325,423,
  212,82,296,296,429,429,429,429,32,392,401,401,
  402,403,403,392,393,393,394,394,395,395,396,396,
  397,397,398,398,399,399,400,400,54,1179,291,91,
  413,413,413,413,2001,411,411,123,123,123,33,33,
  1138,1138,1138,1138,1111,1111,1111,1111,373,135,210,373,
  1110,1141,301,314,314,1157,1157,304,350,404,210,210,
  210,211,211,258,418,418,182,418,325,418,418,426,
  426,379,1175,159,159,66,282,295,295,136,1130,1130,
  1130,1130,407,407,286,79,433,433,283,283,283,1160,
  1160,1160,1160,32,32,85,85,1163,361,53,53,53,
  59,53,1151,138,138,64,64,441,285,321,321,321,
  349,1156,362,46,283,283,2000,17,87,441,202,87,
  416,410,249,249,249,249,1183,407,408,408,407,407,
  347,346,1131,248,298,279,279,1124,318,197,341,407,
  407,407,407,407,407,145,145,352,117,117,117,433,
  206,21,159,253,253,259,259,260,260,1129,1129,1129,
  1129,2001,1189,259,385,113,64,113,312,436,105,105,
  105,178,166,178,222,178,319,319,319,193,81,81,
  196,244,196,196,244,320,320,129,129,341,341,341,
  341,341,337,342,342,341,329,329,302,302,302,409,
  85,44,144,144,287,142,142,142,142,73,243,404,
  404,243,13,196,13,1107,360,38,38,38,104,104,
  104,38,32,32,409,409,1137,260,201,140,140,140,
  201,201,52,326,52,52,325,325,52,51,355,355,
  355,238,165,91,91,368,202,317,360,120,214,214,
  214,217,214,354,78,41,42,205,41,42,311,311,
  311,290,60,162,1169,1169,383,75,414,383,186,405,
  263,316,316,316,316,302,302,302,302,302,405,98,
  377,98,98,1101,1101,9,316,316,316,316,316,22,
  22,22,22,405,385,54,385,33,62,347,211,223,
  212,212,79,79,79,12,422,12,405,404,404,405,
  310,310,263,360,422,175,175,357,357,339,224,224,
  224,311,312,345,345,200,200,351,27,27,22,161,
  189,364,189,112,368,368,112,364,184,81,81,207,
  207,207,207,19,19,364,409,409,409,319,319,415,
  372,3,3,415,372,372,372,1129,271,271,149,359,
  359,359,371,371,220,220,347,364,276,276,415,372,
  191,191,442,4,4,114,114,114,323,323,93,93,
  120,120,41,60,133,51,51,256,256,256,256,256,
  256,60,60,60,52,58,58,415,415,415,415,307,
  307,307,307,410,263,410,307,307,215,215,215,215,
  326,55,351,351,351,225,331,225,323,305,205,205,
  205,66,322,322,412,61,1117,61,237,312,262,177,
  299,263,41,41,95,334,180,180,180,377,180,180,
  334,212,16,16,360,361,361,333,360,213,420,420,
  420,420,420,206,411,334,305,305,197,90,197,343,
  1113,46,208,331,331,206,10,10,337,341,306,306,
  213,157,157,34,412,308,10,412,412,412,55,287,
  287,34,61,26,417,417,26,26,26,329,123,123,
  267,144,144,173,289,308,308,345,188,188,188,188,
  202,202,325,181,287,287,290,230,230,230,230,373,
  373,373,89,89,1102,40,1114,320,320,283,283,283,
  74,74,345,112,311,139,139,112,440,64,89,89,
  323,323,245,106,106,106,282,315,55,246,246,287,
  287,287,308,300,300,300,28,28,157,158,158,298,
  249,154,350,273,257,257,257,15,15,249,249,250,
  249,249,250,249,155,361,182,182,356,356,268,268,
  268,133,133,346,346,361,361,33,50,74,76,323,
  315,55,333,333,189,189,306,306,338,338,417,417,
  417,417,346,346,154,411,411,431,243,312,1124,344,
  198,198,1113,2001,174,174,120,242,347,254,439,266,
  266,256,256,256,366,366,1170,1099,1127,350,350,260,
  260,291,128,128,187,185,305,305,151,151,279,363,
  363,363,138,334,202,40,254,241,2000,254,241,98,
  117,117,427,61,346,346,61,411,411,411,411,29,
  29,144,440,440,353,4,4,1149,247,240,247,384,
  32,66,66,319,129,129,31,31,219,219,43,122,
  122,122,185,126,185,185,43,289,289,289,289,212,
  417,417,164,381,247,247,309,298,344,376,376,376,
  322,322,1133,1133,1133,166,379,224,349,416,433,214,
  270,75,110,110,110,186,186,324,22,16,293,293,
  244,244,244,244,244,244,421,421,421,275,275,368,
  377,112,112,277,277,277,1132,303,305,305,313,313,
  313,21,313,171,303,100,100,350,303,304,303,353,
  353,313,197,28,2001,59,282,282,262,1179,238,238,
  1100,7,284,284,284,80,80,313,211,1178,250,250,
  250,250,17,14,17,344,174,1176,1176,1176,1176,1176,
  322,322,355,128,405,1182,284,284,1114,1114,284,185,
  184,184,2000,304,304,304,162,203,442,442,442,345,
  367,367,412,412,412,1190,237,237,237,95,95,363,
  1187,348,248,1154,233,233,282,233,167,282,379,379,
  379,379,131,131,2000,35,35,35,35,194,337,337,
  194,49,49,2000,441,147,147,147,147,136,140,45,
  45,6,158,402,402,428,423,423,336,157,1147,1147,
  1147,1147,261,261,358,356,363,358,336,336,336,206,
  206,206,6,206,234,234,234,234,325,372,13,13,
  156,278,201,432,432,432,304,405,42,100,100,184,
  100,273,274,274,70,318,318,318,318,280,280,280,
  1101,1101,292,1149,327,327,327,327,399,399,1101,1101,
  87,87,134,65,65,152,152,152,432,59,432,1184,
  263,376,376,376,386,386,155,124,345,343,125,439,
  441,441,135,135,378,378,378,1162,176,176,95,375,
  29,29,29,146,231,231,231,333,1101,337,418,418,
  418,358,261,284,63,63,374,374,374,374,374,374,
  239,239,239,1165,1104,374,96,405,405,405,405,405,
  405,405,153,426,2001,419,419,82,82,82,366,82,
  82,82,82,365,82,365,89,121,89,424,424,424,
  42,229,381,229,21,229,417,381,259,117,117,139,
  330,123,363,31,1132,110,110,110,59,1139,1139,1139,
  1139,1139,329,329,329,85,34,229,417,381,212,188,
  95,378,378,31,31,396,243,243,123,239,239,342,
  237,237,103,102,102,103,103,103,263,418,438,410,
  410,406,438,348,410,410,410,410,263,267,392,377,
  46,46,84,409,409,84,396,263,263,263,181,200,
  51,51,231,41,231,231,228,146,380,380,380,380,
  63,7,7,7,7,22,22,228,95,258,228,426,
  426,36,135,135,30,30,21,230,230,1112,1112,318,
  318,85,196,220,262,88,88,262,18,18,219,1179,
  374,157,354,298,243,237,11,11,395,395,72,72,
  1150,1150,92,218,291,291,141,120,120,120,1146,1146,
  1146,358,67,147,224,8,241,320,73,73,320,1165,
  1127,1127,1127,265,307,307,1161,1161,1161,279,279,24,
  292,24,24,24,356,145,93,147,147,66,66,311,
  184,184,248,231,248,314,11,11,285,285,285,431,
  431,431,1099,190,190,190,246,246,391,391,112,368,
  368,112,311,311,311,8,8,1099,1099,1099,324,191,
  366,228,228,1177,1177,276,276,54,432,432,377,78,
  432,282,282,282,282,366,250,160,234,340,340,340,
  338,391,391,183,340,289,46,340,64,248,358,358,
  198,116,116,116,116,116,116,116,116,116,320,320,
  25,25,51,25,1115,1115,309,309,309,309,308,308,
  390,314,390,47,47,386,21,386,314,390,314,390,
  226,1173,1173,1173,1173,303,38,371,1188,26,26,273,
  18,18,314,314,70,70,283,1186,1186,1186,406,406,
  406,406,406,297,297,271,271,2000,316,427,81,81,
  81,81,114,440,440,115,151,151,151,326,169,169,
  57,84,178,406,84,255,1098,1098,1098,1098,1098,2000,
  58,58,133,1125,1125,31,31,360,1166,1166,1166,1166,
  1166,360,285,285,42,42,421,421,30,30,88,381,
  88,132,344,88,309,306,90,90,90,90,1173,1173,
  1173,90,292,292,61,317,317,317,317,415,420,293,
  293,1159,1159,316,74,74,74,125,297,242,242,153,
  153,339,242,242,242,242,242,242,357,154,218,15,
  15,349,349,105,124,52,339,99,62,62,302,138,
  415,355,1180,408,328,52,328,328,226,1182,1182,251,
  251,1145,1144,1144,1144,36,54,36,155,155,155,420,
  420,420,163,1170,1170,11,163,163,163,35,182,138,
  410,139,54,138,228,228,118,376,376,376,376,1185,
  330,330,230,270,270,238,238,238,118,118,423,8,
  334,8,8,8,95,95,95,290,2001,241,432,156,
  432,421,376,376,111,275,80,80,2001,353,1167,113,
  127,113,95,293,293,373,340,317,317,317,317,93,
  93,93,163,51,342,342,2001,375,307,174,219,349,
  349,349,414,414,436,1136,415,415,7,404,404,435,
  435,272,82,205,1164,14,14,14,14,14,2000,1181,
  361,354,40,156,156,83,83,1169,1169,133,133,282,
  210,184,184,184,189,184,419,419,343,349,349,343,
  232,1097,1097,1097,1097,1097,1103,441,441,251,251,251,
  251,219,18,18,301,261,170,170,174,170,171,170,
  112,78,413,413,413,413,413,112,408,408,408,48,
  408,408,1113,124,124,369,369,369,369,141,203,141,
  34,34,34,86,86,260,364,186,186,187,187,362,
  160,160,192,192,51,51,5,5,348,5,5,63,
  63,181,181,417,181,181,174,70,70,187,238,313,
  313,313,313,313,313,246,246,246,246,246,29,143,
  24,24,348,21,251,251,251,251,372,86,317,86,
  40,432,348,176,176,331,228,1126,1126,175,303,152,
  276,181,181,269,276,389,22,364,39,39,39,39,
  39,83,83,365,325,1168,429,319,357,353,353,319,
  171,254,254,254,171,208,51,145,334,334,1175,1175,
  1175,143,136,236,236,172,338,339,235,235,235,235,
  235,342,348,248,354,1108,381,1108,370,370,1108,1108,
  260,260,260,260,284,222,354,354,430,406,375,348,
  70,439,439,439,439,29,198,1137,176,176,375,365,
  365,375,161,65,65,345,300,300,102,157,138,296,
  197,197,36,36,194,371,378,371,371,371,334,426,
  426,1131,365,193,193,193,193,363,122,201,309,389,
  160,160,25,25,318,318,326,326,299,131,296,296,
  296,296,296,347,347,1177,414,414,437,437,437,437,
  1135,200,315,315,216,158,57,275,130,324,324,279,
  354,296,294,294,294,294,12,172,172,1174,1174,235,
  227,227,227,227,227,227,227,227,227,119,30,370,
  370,30,122,80,80,335,335,109,109,109,124,124,
  291,291,337,291,64,291,366,422,422,422,265,265,
  265,265,59,257,305,303,353,1185,288,288,51,163,
  55,109,109,109,55,217,217,217,217,218,335,335,
  15,15,307,307,57,57,104,83,83,252,252,252,
  1116,252,123,252,252,252,252,252,12,12,407,122,
  109,109,408,408,408,408,408,104,36,440,440,315,
  315,99,35,105,136,139,140,182,102,365,102,108,
  108,78,412,97,91,385,106,184,106,308,328,137,
  137,137,137,135,117,1153,2000,153,113,113,371,117,
  275,41,1148,1148,1148,275,275,400,400,292,2000,435,
  254,435,275,187,2000,101,101,101,1180,101,101,2000,
  350,175,175,108,108,340,392,291,291,131,131,19,
  19,2,2,295,295,344,344,422,422,314,139,134,
  134,134,28,134,134,327,327,262,262,1149,377,1158,
  410,331,331,166,258,344,2,258,258,258,135,239,
  388,388,388,64,48,24,24,22,375,301,279,356,
  1168,141,261,362,268,361,1101,2001,353,353,353,44,
  44,44,61,61,222,350,171,171,288,351,393,120,
  168,168,298,120,1150,1150,1150,1150,40,364,110,292,
  241,370,179,179,111,111,111,111,139,287,24,361,
  24,41,329,368,368,329,304,151,304,304,224,224,
  301,301,290,322,322,25,25,218,218,159,351,351,
  1118,320,320,77,77,77,15,15,320,184,184,292,
  320,27,27,214,214,184,338,355,338,421,421,304,
  304,22,22,241,285,285,438,438,173,173,173,177,
  344,177,177,177,131,79,129,177,177,322,322,62,
  45,338,62,62,411,299,299,299,299,201,201,19,
  19,406,406,383,424,210,223,210,279,279,209,209,
  197,1105,1105,229,229,229,195,182,186,416,416,416,
  416,416,128,128,128,128,128,285,5,5,36,36,
  35,167,167,167,355,290,378,49,49,177,284,176,
  331,331,355,25,286,286,286,286,286,286,421,262,
  262,96,96,96,262,262,347,190,1106,290,290,126,
  126,126,127,127,156,156,156,156,132,132,262,262,
  378,378,1106,1106,298,298,442,1,1,97,97,40,
  409,35,194,194,35,35,351,351,351,389,178,230,
  230,230,34,33,12,274,274,125,125,253,253,253,
  239,290,58,232,232,232,1107,1162,1162,367,1162,367,
  208,208,209,6,272,272,361,6,6,6,6,6,
  6,63,149,149,63,232,231,335,420,442,442,92,
  56,56,33,43,16,16,175,260,260,2001,303,1122,
  312,312,349,261,261,261,261,384,384,384,348,172,
  172,141,1181,1181,1181,1181,301,301,59,368,117,1120,
  1119,1119,252,252,252,1186,1186,377,353,353,1188,1188,
  1188,1167,162,162,1157,143,312,312,312,290,1188,406,
  1188,354,354,1192,1192,1192,406,406,183,183,438,421,
  135,135,4,4,4,76,76,218,218,415,129,129,
  415,433,27,123,27,27,57,377,150,150,150,150,
  150,43,43,74,20,20,241,20,187,187,286,23,
  438,312,23,23,23,23,335,335,219,168,164,178,
  164,164,164,236,232,231,192,192,232,231,238,232,
  211,226,199,199,348,295,295,295,1171,1171,1171,1171,
  1123,1123,17,212,343,352,352,332,332,332,332,261,
  288,13,357,13,13,245,306,284,326,326,94,1140,
  1140,1140,384,94,94,94,1140,185,154,215,154,132,
  154,199,217,71,71,240,240,240,204,255,255,257,
  257,362,409,409,2,437,2,236,236,236,2,13,
  13,393,153,153,1123,1123,380,380,380,380,380,236,
  236,298,1191,352,352,352,352,347,372,372,309,283,
  1118,1118,130,33,398,398,56,56,375,198,375,375,
  375,188,297,297,1183,1183,1183,315,191,191,47,47,
  191,104,104,104,199,63,1191,128,276,212,212,213,
  213,356,356,357,357,266,161,351,161,13,13,406,
  87,105,105,87,240,240,240,142,142,240,288,288,
  254,148,95,1188,95,159,289,350,350,183,350,338,
  245,123,245,1149,213,336,336,115,115,115,397,397,
  310,310,170,310,267,92,92,356,356,310,310,267,
  148,165,165,408,375,357,12,69,69,355,355,338,
  169,173,191,381,281,418,281,281,281,281,369,69,
  33,357,9,9,9,9,9,9,9,376,2001,228,
  228,247,247,196,202,273,273,352,130,130,340,360,
  112,245,41,245,112,1122,1122,1122,427,427,439,1172,
  236,301,368,368,301,279,41,366,285,285,99,439,
  1129,439,48,50,50,105,300,300,301,297,301,297,
  297,1137,372,335,335,1149,1149,166,118,11,232,232,
  59,166,367,146,146,146,146,230,230,36,266,266,
  266,266,330,330,330,209,326,326,36,114,110,192,
  146,115,71,71,129,91,91,27,27,202,161,161,
  270,270,270,141,440,121,121,320,320,4,4,159,
  409,159,1154,187,189,243,226,254,195,237,20,20,
  1137,158,158,216,216,419,356,222,222,15,15,264,
  278,245,366,264,264,277,277,264,278,278,264,434,
  434,434,434,434,161,434,345,131,131,1134,233,12,
  12,75,75,54,52,356,257,368,334,257,233,233,
  233,167,233,62,199,199,233,258,288,288,442,203,
  203,203,67,210,388,50,298,322,322,107,367,225,
  225,225,333,132,132,346,333,247,195,195,80,434,
  173,204,204,288,288,401,1109,1109,1155,1155,401,211,
  51,68,2001,1142,1143,419,419,419,419,419,1143,239,
  317,239,173,261,54,152,166,166,129,129,86,86,
  394,336,336,403,403,261,364,414,414,414,414,414,
  414,394,147,97,1103,106,106,168,122,97,97,103,
  103,269,269,269,269,185,223,223,3,3,3,257,
  257,40,40,436,436,436,436,436,424,431,431,67,
  112,85,102,102,85,334,143,143,331,331,309,309,
  309,309,34,107,107,107,2001,238,80,360,181,367,
  270,270,68,2001,165,165,158,158,416,416,416,195,
  195,226,226,226,218,208,209,223,357,208,216,296,
  1121,315,315,315,315,254,339,339,339,197,339,19,
  19,1149,274,274,404,442,394,394,1103,130,356,46,
  198,2001,19,3,22,22,229,229,91,221,221,221,
  315,315,385,165,68,45,132,204,204,402,402,393,
  278,136,136,393,270,442,426,426,96,179,179,241,
  1126,117,117,1190,429,216,364,221,1,364,293,108,
  237,1158,1158,1158,348,348,373,1174,1174,425,425,425,
  362,362,279,154,121,121,153,121,421,20,1181,143,
  2001,16,16,428,73,73,428,428,341,331,331,331,
  442,352,416,416,2001,220,200,290,169,169,389,389,
  33,95,72,325,99,99,99,29,29,29,97,97,
  97,97,42,337,253,253,162,253,253,162,253,259,
  259,259,259,149,337,149,244,404,155,404,427,1112,
  418,130,130,404,373,248,257,142,257,257,2000,51,
  17,1,28,10,10,1,1,3,3,354,354,371,
  359,359,371,247,247,11,342,342,250,377,247,2000,
  430,430,48,31,325,382,359,382,382,119,119,81,
  81,32,410,410,32,19,19,271,148,148,148,148,
  271,271,325,325,28,427,427,427,2000,119,439,259,
  259,37,37,37,37,37,1128,1128,1128,1128,1128,18,
  289,18,18,18,343,343,343,346,343,404,70,70,
  1152,2000,93,93,93,190,213,243,243,92,92,84,
  84,182,255,255,255,255,255,255,423,212,240,240,
  240,387,387,387,296,327,296,429,429,32,392,401,
  402,403,393,394,395,396,397,398,399,400,278,358,
  278,210,211,410,229,421,228,239,350,250,1295,291,
  345,250,219,87,399,399,399,296,31,42,373,64,
  64,64,418,418,418,1251,426,426,325,66,282,282,
  1251,314,295,295,134,134,139,134,314,314,139,53,
  53,53,53,286,41,79,433,433,407,188,1261,1295,
  356,407,407,407,407,1243,361,173,173,419,419,1261,
  89,356,356,321,321,321,388,388,441,46,343,343,
  343,343,343,343,345,362,346,348,348,343,344,1268,
  184,182,355,416,131,131,131,318,318,19,19,298,
  279,279,1241,197,407,407,419,256,312,312,312,312,
  1276,258,1264,259,258,1264,249,259,259,152,152,82,
  82,82,82,352,438,330,1206,415,92,426,426,301,
  2001,206,218,215,206,206,206,411,113,194,113,4,
  4,80,80,319,319,141,142,142,142,319,209,209,
  209,196,196,358,196,320,320,341,329,341,341,341,
  337,337,415,342,341,38,38,38,85,337,38,340,
  104,104,104,104,287,360,91,91,91,256,256,19,
  19,19,20,256,256,256,256,274,274,414,414,414,
  414,1290,1290,238,238,238,307,307,307,307,307,1226,
  1198,1205,307,307,307,1228,86,86,86,1260,1260,415,
  15,249,15,343,226,1217,123,123,123,123,1292,1292,
  284,284,1256,1256,1256,1256,347,120,120,32,286,286,
  286,286,286,373,373,1290,325,201,201,355,355,201,
  201,355,355,1263,339,178,241,349,349,349,349,349,
  268,349,1239,260,260,351,351,351,1235,368,364,175,
  52,52,325,325,174,320,320,290,60,21,21,385,
  385,385,385,385,48,98,98,98,98,269,269,269,
  1297,22,22,22,22,22,316,22,22,316,316,316,
  316,316,316,316,316,273,271,271,404,405,405,404,
  334,334,212,212,223,345,161,364,415,417,410,410,
  410,3,263,326,38,371,371,359,359,97,207,207,
  207,207,263,263,417,176,176,176,337,176,176,366,
  366,271,319,319,319,220,220,114,114,240,240,54,
  28,28,112,175,175,48,60,166,166,60,60,157,
  157,159,344,344,215,227,215,42,215,364,333,338,
  345,345,283,440,131,131,245,282,133,133,174,202,
  117,117,411,433,150,145,150,148,145,150,145,150,
  35,313,278,284,284,284,1213,353,377,377,103,199,
  262,49,49,1297,1286,1286,261,412,322,364,405,185,
  184,184,54,129,129,129,362,261,442,442,442,345,
  345,43,131,186,186,337,287,269,269,136,169,169,
  169,327,132,423,423,428,367,394,403,403,403,394,
  394,394,394,414,414,414,414,419,18,13,13,275,
  275,30,30,236,236,17,336,336,142,142,402,405,
  136,62,184,292,373,119,119,118,118,1236,327,19,
  19,327,327,327,1274,327,14,415,415,415,415,54,
  415,254,254,254,349,417,425,425,425,351,351,161,
  392,1280,14,414,297,417,417,8,38,8,8,334,
  208,8,1294,1294,280,1197,59,65,65,65,355,424,
  424,87,87,111,139,139,111,1271,1271,1271,1271,441,
  441,283,283,283,311,311,237,237,237,237,413,413,
  413,413,413,231,108,231,348,348,1247,1221,20,95,
  317,317,317,98,97,97,97,317,317,274,320,320,
  273,273,273,417,297,249,1218,408,408,31,31,375,
  375,414,414,256,256,408,1245,1245,1245,274,241,241,
  1229,392,392,392,392,377,106,106,106,234,234,234,
  234,234,259,259,259,283,135,333,318,203,44,1200,
  337,418,418,374,374,374,374,374,239,374,374,374,
  374,405,405,405,405,405,2001,440,212,223,223,214,
  214,214,223,152,152,42,229,229,229,229,259,55,
  117,117,139,237,237,363,1232,335,84,84,409,409,
  424,424,424,329,329,135,135,135,135,1275,31,31,
  27,27,15,148,148,148,148,62,204,204,204,204,
  188,188,368,368,329,420,329,157,367,263,418,410,
  438,410,410,95,229,229,123,237,237,237,103,103,
  102,183,103,275,344,267,46,46,46,263,263,200,
  200,200,200,73,73,326,228,228,426,54,210,228,
  231,231,231,380,380,380,228,228,51,51,231,231,
  231,231,210,227,227,211,73,442,223,210,227,210,
  151,151,4,4,4,7,3,36,46,177,177,177,
  177,177,167,121,121,121,373,373,1193,120,120,120,
  120,120,1219,45,308,308,1219,81,1194,1194,1194,1194,
  67,67,320,320,301,1270,72,72,72,396,396,396,
  396,1244,1215,85,196,85,85,279,279,151,22,2001,
  24,292,24,24,159,159,140,163,162,118,119,36,
  314,343,322,1238,311,311,256,310,286,286,286,311,
  15,80,311,1222,311,311,1297,122,317,421,421,421,
  421,254,156,420,156,156,348,228,231,8,237,318,
  135,135,343,153,153,153,153,153,371,18,100,159,
  42,420,420,420,420,78,78,285,285,297,290,230,
  351,213,188,413,129,249,289,185,348,369,246,246,
  241,241,1220,232,387,387,387,387,387,337,341,337,
  337,337,337,338,338,370,370,370,118,119,331,24,
  170,1272,258,295,222,40,257,232,257,1272,1214,243,
  332,245,345,190,190,190,379,379,375,107,365,440,
  440,255,240,233,302,89,89,89,285,285,285,405,
  251,121,129,304,1259,229,236,245,244,233,302,408,
  31,372,1224,336,253,257,1,406,406,59,247,1296,
  269,269,144,3,416,416,416,71,373,15,205,191,
  81,353,261,209,209,8,204,1195,1195,1196,181,263,
  432,432,74,340,340,340,340,340,340,340,46,340,
  338,338,64,282,282,308,287,282,282,282,282,309,
  309,308,309,309,309,309,25,25,25,390,390,314,
  390,1248,1248,390,390,134,314,134,224,224,224,407,
  407,95,38,1275,338,116,116,344,158,116,26,26,
  309,386,154,386,386,386,386,1249,1249,106,297,424,
  154,81,81,81,81,42,156,74,74,47,47,47,
  18,114,115,167,106,381,106,184,57,84,84,84,
  84,84,409,255,178,173,220,133,1227,1227,58,58,
  58,1269,1269,1269,1269,1269,138,139,139,150,138,138,
  151,170,357,147,92,92,288,169,1284,432,371,371,
  371,371,378,99,1202,1262,276,276,298,298,356,356,
  36,74,163,21,141,1240,124,125,250,90,90,90,
  90,1211,90,51,427,427,427,427,427,427,267,385,
  292,267,198,198,267,250,250,249,1210,1238,230,407,
  250,250,59,228,1196,165,165,2,7,371,371,359,
  202,1288,133,314,26,26,293,293,293,328,328,328,
  1248,356,356,163,163,163,15,74,74,74,52,35,
  35,35,35,431,431,330,330,330,226,251,251,360,
  360,423,353,160,290,52,261,261,341,436,436,410,
  421,376,376,1223,95,158,1210,51,14,14,14,342,
  342,174,404,82,160,2001,248,248,318,361,354,230,
  230,40,299,261,301,282,343,1199,441,184,184,305,
  51,333,205,205,66,124,125,365,323,76,61,61,
  254,254,177,243,56,41,58,287,287,290,360,360,
  334,301,363,58,331,331,46,343,197,197,298,331,
  331,10,10,189,412,308,412,412,412,34,287,34,
  34,351,351,161,351,351,351,67,44,44,106,409,
  2000,254,2000,2000,2000,2000,435,2000,144,144,144,162,
  162,213,156,180,180,180,180,188,188,246,246,413,
  27,27,112,112,140,112,89,287,287,320,320,189,
  189,362,356,33,260,260,260,239,154,350,239,239,
  358,358,356,356,338,112,249,186,155,15,15,143,
  143,143,291,112,86,86,85,310,187,369,432,33,
  222,331,315,55,346,346,346,346,411,128,198,198,
  198,347,124,124,125,125,124,168,342,241,256,366,
  88,88,88,201,88,79,79,151,151,279,363,35,
  97,97,43,95,95,95,155,155,131,131,155,95,
  95,95,29,440,440,95,353,300,240,300,300,219,
  289,289,212,289,219,219,404,404,130,298,255,66,
  185,185,181,126,185,67,289,309,141,141,203,182,
  61,61,141,74,166,1279,120,348,376,376,195,369,
  369,369,369,369,369,13,13,160,160,246,246,246,
  246,246,246,161,263,241,319,63,63,181,181,197,
  68,218,210,174,70,181,21,21,67,232,232,29,
  429,314,421,368,368,349,303,273,132,132,132,132,
  79,305,305,305,306,305,192,192,206,40,366,175,
  276,276,180,276,276,276,18,1207,381,375,1207,368,
  1208,370,370,1207,1207,245,245,232,232,152,389,22,
  22,423,83,83,365,362,81,263,263,208,420,354,
  354,39,39,39,39,404,196,196,367,334,354,354,
  260,284,258,112,70,70,91,439,439,29,318,318,
  365,365,109,109,65,65,300,102,145,361,296,1242,
  126,127,51,194,426,406,433,193,193,193,363,193,
  193,411,201,370,12,12,149,149,57,57,57,57,
  309,296,296,296,296,296,2,2,2,2,437,437,
  347,118,119,299,1283,422,122,122,122,260,260,186,
  315,216,326,326,248,34,324,324,279,80,80,130,
  354,354,354,440,346,346,375,1212,355,275,217,331,
  331,324,124,291,291,265,265,265,280,265,265,366,
  422,217,12,408,408,408,408,277,277,277,288,288,
  217,217,217,55,51,1265,83,83,83,83,338,338,
  440,440,315,315,109,109,360,91,137,137,137,137,
  317,275,275,41,322,275,88,108,108,108,108,108,
  69,102,102,365,57,318,94,94,94,133,101,101,
  101,101,101,1,33,412,30,30,30,117,308,328,
  1258,1258,252,113,113,1231,400,400,400,2000,241,117,
  2000,2000,410,1285,311,2000,435,435,292,437,437,291,
  291,350,155,340,340,355,355,355,87,86,320,24,
  61,258,258,130,130,258,258,258,258,258,258,422,
  2000,100,100,100,184,100,116,116,327,262,117,116,
  116,295,295,295,64,388,388,388,48,291,375,248,
  270,58,2,2,190,288,350,168,168,168,1255,1255,
  40,357,110,41,290,292,292,368,24,361,24,368,
  368,329,290,64,1293,163,184,184,349,81,218,218,
  287,290,77,77,77,77,338,36,131,147,1,1,
  285,200,438,438,299,299,299,299,299,406,406,279,
  279,6,342,128,128,128,128,285,36,167,337,177,
  48,1240,323,323,347,93,290,126,126,127,127,132,
  132,123,123,123,262,262,239,409,409,122,356,40,
  357,82,82,194,194,389,389,257,257,257,257,257,
  33,281,281,11,11,11,290,43,43,43,106,214,
  214,1273,166,243,232,232,335,1273,104,104,56,56,
  129,32,415,42,281,281,281,418,281,409,55,348,
  348,174,6,272,272,361,179,179,6,70,6,6,
  6,241,59,59,59,354,354,354,354,257,257,301,
  301,215,222,224,222,377,232,232,232,232,59,162,
  162,1300,406,171,431,431,431,61,61,183,183,243,
  421,157,135,433,433,356,356,211,146,175,175,23,
  23,23,23,286,23,36,36,384,384,384,384,384,
  325,105,105,105,105,178,1216,1216,164,164,342,250,
  92,92,216,199,159,17,324,331,332,332,332,34,
  13,357,13,13,182,245,245,123,123,306,306,306,
  254,284,62,257,257,62,113,113,442,76,76,189,
  310,63,63,63,35,63,1292,297,297,1292,1292,1292,
  384,189,339,339,339,339,339,339,123,123,379,219,
  379,379,379,190,190,191,191,406,212,213,213,212,
  68,68,272,335,335,64,326,179,404,404,241,140,
  140,140,409,409,12,12,33,157,157,16,16,247,
  247,364,372,170,170,171,372,54,55,381,365,184,
  367,367,325,69,69,9,9,9,9,382,9,9,
  9,187,104,323,323,261,1246,240,255,255,255,255,
  344,240,240,240,288,240,240,255,255,240,357,357,
  353,353,353,1296,1296,353,154,154,154,87,105,87,
  362,406,406,406,164,366,283,404,114,115,41,233,
  233,75,75,75,96,96,96,96,383,383,383,383,
  75,383,228,228,228,228,228,62,1282,199,199,199,
  48,115,115,111,109,110,167,167,233,233,233,233,
  397,397,397,397,5,301,301,1220,5,212,302,302,
  302,302,1284,2001,187,187,373,325,261,419,1201,1201,
  347,303,283,202,95,375,375,375,375,375,351,398,
  398,398,398,183,245,245,245,7,418,418,347,310,
  310,71,71,364,364,386,386,2001,202,112,112,130,
  130,358,92,264,264,277,366,280,264,264,179,264,
  264,278,264,1256,1256,379,341,338,238,41,145,172,
  172,172,197,195,195,50,50,50,50,300,300,297,
  155,251,251,405,405,11,251,251,251,251,232,192,
  192,11,251,167,285,285,285,285,141,158,158,149,
  197,158,19,182,304,304,241,211,226,1229,226,326,
  51,254,220,27,27,27,377,304,304,304,304,304,
  266,266,266,266,266,266,114,357,111,109,115,110,
  250,249,250,60,60,60,99,304,88,357,195,221,
  1204,1204,1204,226,276,13,13,13,159,159,216,1259,
  187,192,360,4,54,146,202,202,99,99,270,270,
  270,229,229,229,417,229,417,36,236,236,236,236,
  236,236,12,12,434,434,434,434,161,334,334,288,
  442,277,347,16,16,16,16,19,19,117,244,244,
  244,244,244,244,244,244,244,50,298,178,178,129,
  181,186,174,187,100,45,45,45,233,233,302,225,
  225,225,225,346,195,333,333,5,5,173,173,173,
  173,434,288,211,51,419,419,419,419,419,239,317,
  284,284,166,166,168,185,223,223,32,32,32,40,
  203,203,203,431,431,112,303,1253,304,303,143,143,
  331,331,99,147,147,270,322,322,303,2001,303,408,
  310,303,305,408,408,416,216,296,247,247,336,315,
  320,320,1278,307,1277,371,372,372,149,146,146,146,
  189,442,336,336,336,192,432,432,100,26,1224,189,
  189,164,3,22,22,49,221,221,147,147,385,147,
  165,165,165,357,171,147,45,178,442,216,97,407,
  407,7,1197,434,1234,7,7,4,426,426,182,182,
  44,44,96,376,376,376,376,376,376,408,408,252,
  361,176,252,252,1265,1298,121,121,121,2001,411,411,
  411,422,422,422,51,2001,412,1287,1250,362,362,154,
  279,1257,435,87,221,144,364,364,344,350,350,350,
  350,364,293,429,429,429,373,373,1291,270,1298,18,
  428,428,428,110,110,110,442,377,377,377,1252,1268,
  355,242,242,313,1233,242,153,153,1212,293,335,350,
  164,335,335,280,374,374,230,380,380,380,380,380,
  380,380,335,416,416,416,416,1203,391,371,330,330,
  248,248,248,352,226,363,1299,1299,93,93,93,93,
  381,381,381,381,248,235,235,235,378,378,378,378,
  378,378,378,235,235,235,235,317,354,94,409,409,
  315,347,238,413,413,353,353,238,238,238,242,352,
  313,313,313,313,350,350,411,315,315,315,315,117,
  117,1230,93,20,1235,439,1281,32,395,395,395,395,
  395,138,389,389,33,95,41,41,205,50,41,2001,
  265,262,262,262,345,345,171,171,262,262,158,158,
  349,262,29,29,29,259,259,128,86,86,406,406,
  206,208,262,298,298,48,18,410,18,18,48,48,
  299,244,149,149,56,172,89,89,418,253,253,253,
  253,253,253,253,253,142,257,1,10,10,10,437,
  68,143,2000,218,218,219,1290,243,25,25,5,302,
  169,325,247,247,247,325,247,247,247,382,382,382,
  47,382,359,325,31,3,3,41,35,279,404,279,
  441,146,430,430,430,51,432,63,1295,135,261,312,
  312,312,312,261,25,25,62,32,82,82,365,271,
  271,271,361,105,270,2001,162,1228,354,138,138,37,
  37,37,37,268,268,165,268,1205,213,93,93,294,
  1237,294,294,294,1237,1237,70,70,70,326,326,326,
  20,20,257,260,260,17,17,17,1266,1266,296,342,
  80,80,80,80,1209,439,439,439,439,439,439,439,
  85,85,85,401,401,401,103,436,436,436,156,296,
  185,191,191,191,367,78,78,78,78,28,252,182,
  28,28,1254,252,252,224,224,429,429,32,81,81,
  1267,238,334,208,227,227,208,8,208,138,312,1210,
  107,107,369,107,341,436,353,417,417,411,411,122,
  2001,1225,393,19,19,393,393,393,393,432,331,331,
  278,136,136,136,136,402,402,416,360,392,401,402,
  403,393,394,395,396,397,398,399,400,1327,291,1378,
  52,52,258,258,258,258,421,1383,376,376,376,376,
  376,376,376,376,258,258,258,258,258,361,258,258,
  258,116,116,116,116,116,116,15,15,411,411,411,
  159,230,353,353,123,123,1,1,350,376,376,298,
  1337,1337,1337,1315,1315,1315,1315,1315,224,224,373,135,
  135,210,211,211,1314,1314,1314,104,104,1381,1381,99,
  99,128,1358,304,304,304,1318,1318,407,407,407,407,
  1,302,6,253,1,42,234,234,234,71,71,418,
  418,418,277,167,177,338,157,59,140,325,169,169,
  1301,418,418,334,426,66,32,318,318,1323,28,28,
  415,301,161,161,301,201,201,2,295,295,145,368,
  1316,368,1316,277,277,370,370,387,387,387,387,387,
  286,414,414,414,414,414,414,414,406,120,120,106,
  120,120,120,1311,381,370,370,388,388,79,134,134,
  134,134,209,209,367,433,283,283,283,283,1354,191,
  183,378,183,32,32,278,361,1353,1353,366,193,139,
  1324,1324,285,285,138,1373,1373,258,52,441,441,441,
  1361,238,238,50,50,50,19,18,18,19,189,283,
  283,273,272,272,272,13,13,184,17,17,133,406,
  441,406,1329,20,20,421,4,4,92,92,342,342,
  416,415,347,249,152,152,1385,143,408,408,408,408,
  408,408,1331,1385,1385,298,279,279,1344,407,407,407,
  407,407,407,407,165,407,407,278,278,226,226,306,
  306,419,419,419,1342,210,1342,145,197,415,415,254,
  254,254,238,238,411,411,356,154,240,391,277,277,
  206,215,215,433,218,41,438,42,159,1383,293,41,
  42,210,210,51,150,385,385,385,385,69,69,319,
  244,244,244,244,244,244,244,244,363,244,250,250,
  250,250,250,250,250,250,406,48,48,196,196,166,
  342,341,341,129,129,142,142,142,341,341,329,329,
  197,104,104,89,104,212,212,212,319,16,16,257,
  257,91,91,158,158,12,205,287,362,404,404,362,
  189,189,302,302,302,113,336,113,336,336,336,336,
  336,336,302,302,302,302,302,302,302,302,369,369,
  369,369,369,369,369,369,369,32,175,51,214,214,
  214,219,104,104,223,337,337,60,326,322,382,382,
  382,382,382,33,33,83,83,371,371,144,360,298,
  223,223,178,178,178,178,405,404,404,405,410,410,
  181,323,323,1338,1338,325,325,18,18,357,357,200,
  200,200,339,364,364,263,263,87,87,276,251,251,
  271,271,427,427,427,427,427,198,198,30,30,233,
  233,233,436,61,61,60,133,145,44,42,212,215,
  236,236,236,236,236,236,236,236,236,339,176,36,
  81,81,88,88,78,78,78,323,48,39,35,261,
  305,305,188,188,335,229,229,333,333,333,333,229,
  229,229,229,229,229,229,66,66,189,189,189,341,
  341,156,412,310,310,338,1317,159,159,159,159,1320,
  81,81,364,364,201,177,162,162,201,218,299,218,
  356,409,31,404,31,308,41,314,95,245,245,171,
  171,180,349,349,245,245,245,245,123,245,245,162,
  245,361,361,290,287,287,420,420,360,89,69,69,
  69,334,334,89,246,156,156,193,1312,1312,1312,1312,
  384,363,326,63,326,326,326,232,218,218,206,305,
  176,176,337,129,176,138,139,139,139,139,285,139,
  139,371,371,371,371,371,371,371,138,10,10,327,
  157,157,412,308,10,10,412,412,412,287,287,420,
  420,420,26,26,229,229,361,331,331,98,98,156,
  329,123,123,385,267,1371,1371,1371,173,308,308,338,
  338,161,158,62,62,320,320,171,171,171,59,325,
  325,24,297,297,325,62,357,414,361,1,316,1,
  240,240,64,112,112,360,78,411,323,323,323,411,
  411,361,334,334,35,416,433,94,94,94,94,270,
  98,98,98,98,267,267,12,12,59,15,396,300,
  300,300,180,180,131,131,75,75,75,28,28,377,
  377,377,377,158,157,158,276,298,350,241,241,155,
  206,306,206,62,141,141,66,87,87,189,339,189,
  417,201,346,346,154,1362,15,15,411,184,52,80,
  80,365,431,431,105,243,318,318,318,318,318,318,
  318,128,346,346,346,198,1317,120,2001,1317,351,351,
  351,351,351,351,351,351,351,378,174,174,238,370,
  293,206,206,58,58,347,1330,8,8,1381,439,1319,
  260,260,1325,1325,266,256,256,256,256,256,256,256,
  256,256,1325,1303,1303,1303,1303,349,349,350,350,260,
  260,291,315,118,325,9,380,380,380,90,90,36,
  187,63,43,245,185,185,185,185,185,79,232,151,
  151,232,176,232,232,232,232,60,232,232,232,232,
  59,31,31,279,13,13,310,29,29,353,278,278,
  440,440,408,309,315,55,191,191,282,219,212,289,
  289,289,289,289,395,395,153,153,395,344,76,76,
  76,186,186,186,106,106,341,187,187,425,79,305,
  79,43,26,26,33,1387,1387,1387,15,15,115,114,
  1334,1334,1334,349,311,186,244,311,160,351,261,340,
  438,353,401,401,401,403,160,103,103,85,262,362,
  49,49,2001,238,284,284,284,80,80,305,1379,1379,
  164,417,417,417,417,417,417,20,1360,412,412,85,
  85,250,250,250,250,121,121,121,121,1376,237,237,
  237,237,1380,348,348,348,1376,16,17,17,1332,417,
  108,108,108,108,108,1377,1377,248,248,344,348,210,
  210,259,259,259,259,259,259,259,259,348,348,259,
  417,415,145,418,405,353,353,1315,284,284,284,284,
  185,184,184,1302,1302,1302,1302,80,80,401,313,313,
  313,313,7,405,337,442,442,311,282,282,282,282,
  345,345,363,363,363,363,363,406,406,282,282,282,
  379,379,379,379,379,379,379,402,402,402,131,131,
  337,88,105,391,391,391,391,140,140,393,428,423,
  423,423,142,142,432,13,13,402,325,348,280,280,
  280,280,96,292,256,256,337,301,65,65,65,152,
  152,432,432,96,96,96,96,12,1336,407,226,285,
  285,1309,124,125,345,343,327,344,108,348,263,335,
  421,376,368,368,368,381,381,432,432,188,188,1308,
  439,254,254,254,254,254,96,237,237,237,237,237,
  219,353,353,135,135,135,135,1364,95,95,95,95,
  131,131,131,95,95,52,205,193,1364,20,316,316,
  307,307,307,307,307,307,415,349,349,349,349,349,
  1305,314,314,314,314,314,416,416,416,416,95,222,
  297,375,375,29,29,249,249,249,249,146,192,146,
  146,192,146,249,1350,146,231,231,231,231,231,51,
  384,166,166,164,242,406,71,71,255,255,255,255,
  255,255,255,255,255,255,344,255,47,154,154,188,
  102,386,279,199,199,105,105,1343,285,285,172,172,
  253,253,253,253,253,253,253,253,300,300,301,301,
  1340,119,119,118,118,333,310,310,191,248,248,209,
  216,209,405,405,5,5,91,199,266,123,266,266,
  266,411,266,1358,1358,141,1331,1304,337,418,418,418,
  418,374,374,374,374,374,374,374,239,239,1366,374,
  374,405,405,405,405,405,405,405,333,1304,426,426,
  248,248,2001,1304,337,356,313,313,313,259,117,117,
  123,123,123,123,12,285,285,181,181,1333,1302,1302,
  34,1302,438,306,306,208,329,329,95,32,329,329,
  326,326,441,441,313,313,350,350,350,267,350,350,
  350,381,22,22,199,22,22,228,263,21,121,121,
  157,354,177,177,177,177,291,200,200,257,141,207,
  207,207,207,320,320,224,224,1366,320,320,320,320,
  263,263,11,11,301,434,231,281,307,307,1363,1363,
  406,361,366,366,68,279,279,221,74,74,74,74,
  59,59,106,106,200,34,34,34,34,34,34,42,
  58,184,136,136,136,136,122,345,431,431,431,8,
  8,196,196,432,41,334,334,409,64,360,41,360,
  1306,1306,1306,1306,198,43,1318,188,51,95,390,390,
  390,390,240,240,240,240,240,240,240,240,38,26,
  26,128,40,404,404,404,130,130,297,27,27,297,
  70,140,153,153,140,375,314,375,424,424,424,424,
  42,237,237,237,237,330,330,330,330,330,57,367,
  427,427,1336,439,439,439,8,334,334,316,317,317,
  317,317,317,317,317,317,317,93,93,93,93,115,
  115,115,114,114,114,440,440,375,423,8,8,25,
  25,112,112,112,112,353,138,263,263,21,21,21,
  430,430,87,87,408,53,53,53,53,53,141,1346,
  1346,1345,1345,1345,331,331,155,155,155,155,163,1371,
  1371,163,163,338,24,24,24,310,310,327,327,231,
  231,231,231,231,231,281,281,281,1384,281,281,213,
  270,270,231,231,8,287,287,361,410,410,410,410,
  410,1389,2001,355,1367,127,90,95,1380,1380,293,373,
  373,373,373,293,293,293,241,143,1356,51,1361,342,
  154,174,219,414,1356,1339,415,7,7,7,7,404,
  404,435,435,435,1362,272,82,1368,14,14,14,14,
  14,62,40,2000,326,88,24,292,24,24,205,205,
  345,345,345,282,184,184,1304,195,195,441,18,18,
  347,419,301,303,160,160,83,83,113,324,324,129,
  129,129,5,5,247,247,5,5,181,181,309,309,
  365,70,102,90,90,29,257,142,257,257,187,324,
  324,324,324,304,331,44,175,317,364,107,107,366,
  366,366,39,39,39,39,40,93,93,143,228,228,
  1329,1329,1329,175,175,430,430,325,58,380,380,389,
  257,257,257,257,257,257,257,257,340,340,181,181,
  22,201,173,173,263,263,247,170,170,170,170,238,
  238,238,247,247,247,247,247,247,247,6,6,6,
  6,6,6,37,37,37,37,37,208,12,12,70,
  70,41,41,354,266,276,243,243,243,243,243,260,
  260,284,354,354,354,276,276,265,265,265,307,276,
  265,64,78,109,109,109,277,132,132,297,132,439,
  439,439,29,1340,439,439,1389,222,222,109,65,65,
  37,11,11,300,83,206,102,84,84,138,203,296,
  321,321,321,321,197,339,197,365,365,365,365,436,
  2,1332,426,426,3,3,3,2,22,118,118,194,
  194,55,51,62,49,403,193,193,408,408,408,408,
  408,371,309,260,260,381,381,373,373,252,252,248,
  248,230,299,275,131,131,131,296,296,296,296,296,
  296,89,89,120,120,1374,81,136,136,328,328,355,
  355,355,355,103,203,203,162,203,315,216,158,288,
  288,136,119,1341,328,328,294,294,294,294,294,130,
  130,354,354,34,102,287,355,261,178,44,335,335,
  335,1369,124,291,338,338,338,338,64,291,291,291,
  291,64,362,366,64,422,422,422,422,152,15,15,
  15,15,389,389,93,305,304,304,304,304,304,303,
  54,54,54,54,51,163,217,217,217,217,173,122,
  99,252,252,252,252,252,252,99,99,80,80,304,
  304,304,303,303,303,303,303,429,303,429,437,122,
  122,194,194,194,194,149,149,73,73,73,304,304,
  149,149,86,86,315,440,440,2001,311,311,311,311,
  311,311,311,233,233,233,233,233,233,435,435,233,
  197,388,388,101,101,213,213,213,97,97,186,186,
  212,30,308,328,383,383,383,383,383,112,112,1357,
  9,9,9,9,141,2000,30,30,9,9,9,112,
  112,2000,2000,2000,112,112,292,2000,429,241,241,254,
  275,275,381,252,1374,350,175,175,400,400,368,368,
  368,368,268,268,268,268,268,268,88,187,187,400,
  392,2000,290,190,278,2,2,399,399,399,242,242,
  242,1365,1365,1365,1365,344,344,343,295,295,422,422,
  82,11,171,82,3,3,3,101,91,437,239,286,
  286,64,286,48,48,174,174,100,100,375,1310,4,
  4,340,340,22,55,38,275,275,275,38,195,38,
  38,38,261,261,63,426,426,350,110,110,111,111,
  351,351,351,288,351,41,438,41,168,168,168,409,
  409,84,84,45,319,319,319,319,1352,204,356,356,
  12,12,309,40,86,357,110,107,215,292,179,292,
  241,241,179,149,149,368,368,117,311,82,82,24,
  24,290,287,311,153,223,224,224,220,151,151,1338,
  221,322,322,25,290,25,331,331,345,345,77,1347,
  77,77,133,133,133,1322,92,92,46,46,46,213,
  214,214,102,378,81,192,192,243,409,243,243,243,
  243,243,243,243,421,421,421,421,421,81,196,196,
  81,195,1373,1373,27,182,340,340,320,320,235,227,
  227,227,248,235,227,227,227,227,235,227,235,235,
  235,235,235,235,299,299,299,299,299,41,184,184,
  35,230,230,148,230,1349,1349,82,82,22,22,1347,
  241,241,46,46,147,45,85,27,27,92,92,235,
  235,86,86,85,19,19,365,410,334,167,167,211,
  406,406,33,33,298,228,228,279,279,197,337,320,
  320,426,13,13,1328,355,355,355,335,335,335,128,
  128,128,55,74,74,285,36,36,290,147,174,147,
  163,284,284,322,322,36,36,28,28,25,25,25,
  25,1340,1340,421,262,354,262,262,262,262,356,1355,
  262,262,347,262,156,353,353,117,117,392,377,392,
  392,392,117,117,127,127,126,126,126,238,156,156,
  294,262,132,132,132,132,262,2001,111,378,378,378,
  378,1327,1327,239,239,442,1389,169,169,169,220,220,
  62,147,211,153,147,278,51,103,103,184,40,186,
  409,409,84,84,82,82,389,16,342,283,283,342,
  440,396,396,74,1363,290,1363,1307,1307,271,271,20,
  20,19,19,22,67,67,335,335,67,72,413,413,
  413,165,56,56,56,129,57,57,57,269,269,264,
  2001,63,140,113,113,113,349,1325,261,301,301,172,
  172,141,190,190,190,1306,420,420,246,246,246,125,
  125,246,1326,1326,269,269,182,182,182,1388,312,438,
  312,312,67,1370,59,59,1386,1386,1370,1370,1370,276,
  162,162,312,312,312,312,312,312,420,420,238,238,
  238,177,143,436,347,347,406,124,409,409,124,286,
  286,286,286,286,286,286,4,7,354,354,354,1390,
  246,421,406,365,409,409,4,4,354,354,246,246,
  135,135,129,129,415,19,19,415,415,433,433,27,
  27,86,86,57,384,384,384,384,384,372,372,356,
  364,367,367,367,356,23,23,23,286,23,89,89,
  219,164,164,41,198,372,372,201,260,260,199,290,
  290,295,295,295,17,332,253,168,332,332,343,326,
  326,332,377,377,251,251,251,51,251,251,251,251,
  10,251,357,316,316,316,316,316,316,316,288,288,
  67,67,306,130,92,284,217,375,315,262,417,417,
  417,381,411,262,417,413,413,413,413,413,413,413,
  336,336,336,380,380,380,380,380,380,380,393,393,
  397,274,239,18,18,31,347,218,372,372,372,307,
  398,398,309,309,440,283,1322,1322,1322,1322,440,33,
  375,397,397,375,375,375,398,202,202,202,121,64,
  2000,355,248,254,355,342,303,288,437,437,274,274,
  125,124,176,1348,117,117,346,346,202,187,264,130,
  130,264,264,1375,264,1375,1375,247,247,365,360,179,
  179,100,100,100,100,1335,1335,183,183,1324,1324,136,
  1324,364,144,144,119,249,1340,144,216,341,109,110,
  111,343,273,273,260,261,260,261,364,2001,434,434,
  434,161,434,345,102,442,202,357,2000,2001,364,2001,
  2001,149,50,223,298,322,322,225,225,225,166,166,
  150,174,150,150,150,150,50,204,173,173,434,204,
  204,166,1351,1351,1351,1351,1351,1348,1348,1348,1348,270,
  270,288,288,1359,1359,1359,394,394,314,394,211,51,
  61,61,1313,274,274,2001,1342,419,419,419,339,339,
  339,239,317,117,185,117,47,47,161,161,1313,1313,
  1313,273,273,40,275,47,117,117,442,406,431,431,
  194,85,85,261,282,362,362,420,331,331,49,60,
  270,269,270,270,60,60,165,165,165,322,322,327,
  45,68,68,2001,416,416,343,343,343,343,343,343,
  343,226,356,359,356,167,296,226,1321,315,315,315,
  315,315,216,367,432,252,192,403,2001,208,208,81,
  81,249,249,249,249,249,249,394,442,409,31,31,
  31,404,404,394,1372,437,195,19,19,46,269,269,
  3,22,22,309,309,122,221,221,385,147,176,261,
  425,425,362,362,154,279,155,320,320,61,61,208,
  222,16,16,244,428,428,428,61,439,143,137,137,
  137,137,137,314,180,180,212,359,442,307,59,352,
  352,352,352,352,352,352,352,352,352,352,352,416,
  416,416,416,352,148,148,148,148,352,9,271,2001,
  386,386,386,386,331,331,1382,105,105,151,358,358,
  359,358,359,358,358,359,356,279,220,436,436,436,
  436,33,301,301,298,298,191,191,271,271,91,91,
  325,325,389,389,95,138,99,325,228,228,228,228,
  228,29,29,29,228,228,312,312,97,97,97,97,
  97,97,99,143,325,212,36,327,419,419,296,331,
  331,357,357,296,429,429,429,429,32,72,72,72,
  72,1360,213,392,401,402,403,393,394,395,396,397,
  398,399,400,1421,1468,291,356,376,376,376,376,376,
  376,376,421,138,358,359,367,358,358,359,358,359,
  98,350,1,302,46,1,1,6,1,351,351,351,
  1470,91,1408,1408,1408,1408,1408,373,210,210,210,211,
  211,330,330,1452,1424,1403,1403,1403,1403,1470,234,213,
  213,1473,1473,1473,238,99,99,1432,407,407,407,407,
  407,1450,1450,1450,63,198,304,304,1420,342,277,277,
  163,163,19,19,177,59,59,325,325,301,426,426,
  7,7,418,418,418,1393,418,66,44,85,85,7,
  7,295,295,136,2,52,370,370,1409,1409,1409,120,
  120,120,120,120,95,95,408,408,1428,1428,1428,1428,
  1428,335,335,1401,381,200,79,261,261,261,375,335,
  433,433,151,183,183,183,378,283,283,283,283,1443,
  301,32,32,234,1444,1444,1444,151,418,26,134,134,
  134,52,258,258,258,258,52,52,441,441,1420,285,
  285,138,1451,377,377,377,258,258,258,258,258,258,
  258,258,258,42,388,388,388,388,283,283,272,272,
  273,17,17,63,133,406,441,406,1417,1453,249,326,
  416,152,152,253,253,253,253,253,253,253,2001,408,
  408,408,408,347,122,336,336,349,349,298,279,279,
  197,407,407,407,407,407,407,407,253,253,419,419,
  419,419,210,1433,253,123,123,154,391,277,277,206,
  215,433,433,206,218,335,335,416,416,416,416,135,
  135,42,344,385,385,385,385,110,64,439,369,369,
  369,369,369,369,369,369,369,369,104,104,222,222,
  276,142,142,319,48,48,48,244,244,244,244,244,
  244,244,244,244,363,251,251,112,112,112,112,194,
  194,320,320,341,342,341,329,329,341,341,337,337,
  129,129,306,104,44,104,104,212,212,306,409,287,
  404,404,243,302,302,90,90,189,189,1397,113,32,
  302,302,302,302,302,302,302,1420,336,360,360,32,
  32,32,336,336,336,336,336,336,382,382,364,382,
  382,175,214,214,214,223,223,223,112,112,112,209,
  209,325,325,33,33,116,60,326,326,219,76,76,
  241,254,241,254,385,33,83,200,83,405,404,404,
  405,360,167,169,169,178,178,129,178,18,18,35,
  161,200,200,339,55,315,230,230,87,184,184,87,
  263,263,271,271,1439,55,55,30,171,61,60,270,
  133,275,61,313,194,16,16,215,198,198,176,176,
  152,323,339,348,305,305,229,229,229,229,229,229,
  229,229,229,229,229,333,333,35,35,35,66,52,
  412,122,1410,81,81,252,252,140,140,153,140,140,
  162,162,362,362,356,356,218,299,31,31,404,308,
  41,147,147,95,180,180,180,382,349,349,349,382,
  35,35,245,245,123,245,245,245,245,245,256,256,
  144,144,245,16,245,245,81,314,81,345,260,345,
  48,287,290,287,360,360,187,361,361,333,78,78,
  78,78,59,78,128,128,334,334,305,156,420,90,
  330,326,363,326,305,331,331,46,343,306,223,197,
  197,197,298,138,139,139,139,139,139,285,139,10,
  10,138,189,189,176,157,157,412,308,412,412,412,
  188,171,188,10,287,420,36,36,51,51,36,36,
  36,26,26,85,85,409,98,417,242,242,123,385,
  156,173,318,377,367,329,338,338,158,161,188,20,
  59,236,236,236,236,236,236,236,236,300,300,236,
  180,180,59,59,325,283,283,173,265,276,298,170,
  170,170,171,74,287,287,440,440,69,81,73,73,
  131,131,254,254,372,357,416,318,318,94,94,270,
  98,98,98,267,267,82,82,75,75,75,320,320,
  15,15,308,308,62,396,323,323,323,323,27,27,
  331,331,365,300,28,28,158,44,226,154,350,182,
  155,133,33,191,51,66,376,376,77,189,115,114,
  346,346,184,346,346,346,1455,15,15,411,106,349,
  349,349,45,105,431,431,1480,1480,381,406,186,186,
  186,243,243,243,243,243,128,1404,368,368,346,1405,
  313,313,239,2001,1407,351,351,351,351,351,351,351,
  351,174,370,347,224,224,1416,58,118,260,347,1418,
  1418,118,337,1394,1394,1394,1394,341,341,350,350,260,
  291,368,368,360,187,187,43,425,245,185,185,79,
  79,305,79,232,232,232,232,232,232,60,151,151,
  215,232,232,232,380,380,380,43,43,43,86,86,
  2001,279,363,266,266,256,363,310,29,29,440,440,
  353,353,384,278,278,57,309,315,55,282,289,289,
  219,289,212,289,289,417,417,417,417,417,417,322,
  322,35,141,141,117,117,117,90,90,1425,349,201,
  201,433,340,59,438,293,293,293,244,311,345,148,
  2001,282,353,353,313,313,313,303,401,401,401,210,
  210,160,313,313,313,313,262,49,49,49,284,284,
  284,337,80,80,80,80,1469,17,17,17,17,1472,
  1472,322,405,1408,232,238,261,284,185,184,184,284,
  284,401,311,7,138,405,442,442,442,282,345,345,
  345,137,1482,412,412,250,250,426,426,1478,348,348,
  348,248,248,1467,103,103,344,123,202,314,123,282,
  282,282,282,123,379,379,379,379,379,379,379,142,
  142,402,402,224,224,334,1407,334,337,190,190,391,
  391,391,391,140,131,131,131,353,402,402,428,423,
  423,423,423,393,13,13,287,325,280,280,280,280,
  96,292,256,256,415,65,65,65,432,432,88,316,
  1395,95,92,25,25,317,317,317,317,317,317,297,
  248,248,375,375,29,29,1400,1400,239,239,1458,307,
  405,405,405,405,405,405,405,405,333,440,440,1396,
  1427,121,121,121,2001,1396,1396,337,418,418,418,418,
  374,374,374,374,374,374,374,374,374,295,426,426,
  89,89,375,42,42,42,55,342,342,342,263,259,
  330,117,117,117,123,123,123,123,12,12,12,12,
  285,285,375,55,1424,1459,424,424,424,424,424,375,
  427,328,95,1392,34,438,438,306,306,93,93,93,
  93,208,329,329,329,263,263,200,378,378,378,368,
  368,368,1419,112,112,112,112,341,441,441,148,148,
  148,9,22,199,22,22,22,350,267,350,350,350,
  350,4,4,200,380,380,380,49,21,21,21,122,
  432,432,365,11,11,11,11,18,18,53,53,53,
  53,53,141,141,141,157,434,339,30,177,177,177,
  320,320,417,417,191,291,114,114,114,291,207,207,
  207,207,207,238,141,327,21,21,224,224,1458,320,
  24,24,320,320,406,406,231,231,231,231,231,231,
  231,231,231,231,269,269,281,281,281,281,281,187,
  307,307,187,263,263,301,1454,1454,1454,415,415,205,
  205,143,279,279,156,221,221,74,74,74,86,86,
  211,34,34,34,34,34,34,334,334,1462,136,136,
  136,136,184,111,111,282,338,338,40,8,8,8,
  8,8,8,361,361,361,40,387,387,387,387,387,
  24,24,24,292,431,431,431,22,86,86,86,195,
  195,1391,1391,184,184,1391,1391,1391,1391,61,160,67,
  67,361,1396,441,133,36,18,18,432,432,1484,1484,
  106,106,87,87,356,356,64,198,146,31,1406,1406,
  1406,165,165,96,96,96,63,362,240,240,240,240,
  240,240,240,390,390,390,390,390,51,51,38,150,
  26,26,89,89,404,404,404,130,130,44,44,297,
  206,206,297,327,232,246,163,440,440,8,282,423,
  136,368,290,1477,211,226,278,2001,241,1484,1434,124,
  125,361,343,263,421,238,342,1423,439,439,439,188,
  188,410,410,410,410,410,411,411,96,377,185,185,
  185,2001,1425,219,219,1437,1437,1425,353,353,284,436,
  355,1460,298,356,90,1459,373,373,373,1470,293,131,
  131,131,293,293,285,285,95,205,226,226,381,381,
  368,368,368,9,9,7,7,1435,1447,331,316,316,
  132,132,230,51,1451,342,174,239,414,1407,364,254,
  254,415,404,404,314,314,314,314,314,411,411,435,
  435,435,1455,272,82,272,1447,1457,14,14,14,14,
  419,419,419,301,368,147,83,83,160,160,247,247,
  129,129,129,5,5,5,5,186,181,181,181,181,
  269,269,181,309,309,70,70,317,143,113,324,324,
  324,324,324,29,142,257,257,257,141,343,343,343,
  343,343,343,343,334,175,366,366,92,201,39,39,
  39,39,40,58,58,93,93,176,176,201,201,228,
  228,1417,1417,1417,228,175,175,430,348,348,348,348,
  154,13,1399,1399,1399,1399,389,364,340,340,107,107,
  107,13,93,93,1463,163,208,309,70,436,243,243,
  243,243,243,354,171,171,276,276,284,69,69,69,
  69,276,276,265,265,265,265,37,37,37,37,430,
  37,430,354,354,354,307,206,436,177,206,326,326,
  164,27,109,109,132,132,297,439,439,439,439,439,
  439,356,356,29,1429,439,2000,62,62,62,105,88,
  95,95,95,95,95,1465,109,111,109,65,300,318,
  318,318,318,318,318,84,102,157,84,145,361,296,
  197,339,197,335,159,335,2,3,3,3,22,2,
  194,118,118,426,426,365,83,193,193,193,193,201,
  109,371,371,239,309,170,22,299,131,131,296,296,
  296,296,296,296,296,321,321,321,12,321,355,355,
  355,89,1421,41,41,343,315,216,158,216,275,260,
  372,372,381,248,248,230,260,260,381,381,259,259,
  259,373,119,34,34,328,328,328,303,31,120,120,
  103,354,354,354,130,130,414,414,414,414,414,414,
  414,414,118,294,294,294,294,294,355,406,119,119,
  80,80,122,2001,291,291,124,291,338,338,338,338,
  338,366,152,15,15,15,15,63,304,304,304,304,
  304,330,304,304,304,303,303,303,303,303,429,1475,
  303,429,54,54,54,288,288,54,422,422,422,422,
  217,217,217,61,61,335,304,304,304,149,149,149,
  149,99,364,364,364,440,440,315,99,99,353,311,
  432,432,101,101,311,311,311,311,242,242,101,101,
  311,311,311,213,213,213,97,97,212,212,212,2000,
  2000,30,30,30,30,308,161,161,135,135,135,135,
  2000,113,113,113,2000,383,383,383,383,1448,2000,2000,
  2000,435,435,328,9,9,9,9,9,9,117,292,
  187,187,2000,429,429,241,241,254,98,400,116,116,
  116,116,116,400,1471,350,275,275,275,400,371,268,
  268,88,108,108,108,108,108,393,397,392,233,233,
  233,233,233,233,233,233,233,268,268,268,268,305,
  82,366,366,366,82,2,2,1456,1456,1456,1456,1456,
  261,101,91,179,179,179,365,408,3,3,3,3,
  437,282,344,1452,64,48,48,422,22,422,100,100,
  184,100,375,1398,143,340,340,182,182,1436,1436,1436,
  1436,38,38,195,38,38,38,331,24,24,275,155,
  155,310,308,310,420,420,163,162,1463,399,399,399,
  190,1411,110,110,169,169,351,351,351,133,133,319,
  288,168,168,168,166,166,196,196,196,196,196,84,
  82,82,12,12,91,202,91,319,319,319,319,1445,
  319,356,367,356,12,56,40,357,110,107,41,292,
  292,241,241,179,24,24,117,149,149,287,290,81,
  368,311,311,311,25,25,153,224,220,41,41,41,
  322,322,322,318,331,331,110,354,350,1431,77,77,
  77,174,63,63,63,214,214,92,299,299,299,299,
  299,92,195,1474,182,163,340,340,320,235,235,235,
  227,227,248,235,235,235,235,235,235,320,421,421,
  421,421,421,158,364,184,184,235,148,235,348,227,
  227,227,227,46,46,47,47,46,46,46,409,22,
  22,81,41,279,279,247,247,247,247,247,247,247,
  247,409,409,45,85,85,1413,27,27,241,241,19,
  19,6,6,6,192,192,6,6,6,73,73,410,
  167,167,211,406,406,33,361,162,1412,1412,228,228,
  128,128,128,128,74,103,103,86,84,84,285,202,
  331,331,410,410,220,290,220,36,113,62,62,62,
  389,153,337,174,147,147,147,284,284,176,343,355,
  355,355,355,316,1,1,28,28,28,318,25,25,
  25,25,229,229,421,262,286,286,286,286,286,286,
  286,286,286,286,286,262,262,262,262,1405,1446,420,
  262,347,262,353,353,290,290,156,156,420,156,392,
  392,377,345,126,126,126,127,127,127,126,294,132,
  132,132,132,262,262,2001,378,378,155,378,326,239,
  442,186,84,84,51,51,74,36,257,257,257,257,
  257,257,257,257,257,215,40,71,198,194,82,82,
  182,395,158,158,395,337,395,19,19,1412,396,166,
  396,1453,290,1442,31,31,20,20,20,20,1397,1397,
  1397,1397,18,271,271,112,112,264,264,50,50,50,
  50,19,19,67,335,67,67,42,413,413,415,415,
  415,413,413,413,413,413,104,104,1414,56,56,124,
  190,190,190,190,168,364,364,125,125,301,301,213,
  59,1479,122,312,406,1479,414,354,354,354,354,354,
  354,236,261,155,155,246,246,246,246,246,246,246,
  1483,172,172,1415,418,353,1481,1471,312,438,312,312,
  312,254,254,254,230,1479,246,246,420,421,421,1461,
  1461,312,312,312,312,409,409,409,162,162,312,259,
  238,238,238,238,177,237,237,347,347,4,135,135,
  433,433,157,27,27,57,410,175,175,41,23,286,
  23,23,23,67,384,384,365,384,384,219,219,372,
  372,164,342,342,164,129,129,164,164,92,92,4,
  4,13,13,178,178,290,290,295,295,295,295,121,
  17,253,168,332,332,332,332,332,249,305,305,326,
  326,251,251,251,251,251,251,251,251,251,10,338,
  357,357,316,316,316,316,316,316,288,288,260,260,
  306,27,27,284,205,238,146,192,192,146,249,249,
  249,249,249,146,146,192,146,85,85,144,231,373,
  231,231,231,51,76,384,357,357,357,415,189,189,
  252,409,250,250,250,250,250,250,250,250,250,250,
  191,310,310,204,411,411,105,1478,1478,199,297,297,
  52,199,64,64,64,64,15,1468,121,121,121,121,
  1473,411,217,237,237,237,237,71,71,274,189,255,
  255,255,255,255,344,255,255,255,255,255,255,62,
  154,154,1459,1459,393,202,202,380,380,380,380,380,
  380,380,349,18,18,347,144,261,218,218,2000,254,
  303,355,372,372,309,307,307,307,307,307,307,307,
  413,413,413,283,1411,1411,1411,1411,1411,1411,130,33,
  171,171,143,375,375,375,375,397,397,336,398,398,
  398,298,94,94,202,1438,417,262,262,381,411,417,
  315,288,247,247,166,437,437,437,274,274,364,102,
  365,248,248,248,386,346,145,145,106,106,106,147,
  260,261,260,261,145,130,130,337,264,264,264,1466,
  1466,1466,1414,1414,1413,234,234,248,248,57,57,100,
  100,100,100,115,115,115,11,11,277,1426,1426,1426,
  439,136,221,145,125,124,199,199,187,87,87,406,
  406,406,42,370,1434,279,257,257,172,172,172,26,
  285,285,285,13,13,338,31,105,300,300,301,301,
  276,1429,4,4,341,371,371,371,371,371,371,371,
  371,371,325,277,47,47,355,355,20,20,5,5,
  36,140,153,153,153,209,209,266,266,266,266,266,
  261,343,357,357,1459,91,367,218,218,159,159,427,
  427,427,427,427,1449,1449,1474,1422,1426,1426,1426,1422,
  119,1430,342,109,111,110,273,291,291,434,434,434,
  434,161,434,345,415,415,259,259,259,259,259,259,
  259,259,108,108,442,357,411,2001,2001,50,238,298,
  68,68,68,225,225,174,203,203,203,203,225,166,
  166,150,150,434,173,173,173,173,204,204,186,270,
  270,288,288,269,269,275,1402,1402,1451,211,51,273,
  273,274,274,273,273,2001,1433,1432,1432,419,419,419,
  1433,394,314,394,310,310,339,339,339,239,88,317,
  88,68,68,150,150,185,270,40,40,40,1440,1440,
  442,333,431,431,345,204,362,309,309,106,57,57,
  56,57,181,60,60,270,312,312,312,60,165,4,
  4,165,165,322,322,45,416,416,2001,203,376,373,
  373,373,373,226,221,212,216,278,278,167,296,1412,
  315,315,315,315,315,252,162,363,363,363,363,363,
  394,81,81,403,403,403,1441,1441,1441,1441,208,208,
  373,442,404,404,394,1464,437,432,222,19,19,2001,
  238,46,195,237,237,237,237,237,237,365,365,365,
  365,365,3,233,233,233,22,22,221,269,269,327,
  1450,1450,1450,385,362,362,261,204,325,325,41,438,
  408,408,408,408,408,408,408,344,344,426,1476,147,
  102,102,425,425,362,362,154,279,422,327,327,270,
  270,240,240,240,240,240,240,147,377,377,41,320,
  61,61,208,222,222,16,16,16,16,244,428,428,
  428,142,139,314,134,134,298,298,307,134,416,416,
  416,416,212,359,442,352,352,352,352,352,352,352,
  352,352,352,352,352,271,271,91,2001,386,386,386,
  331,331,1475,239,70,70,70,105,105,290,51,51,
  356,367,367,367,358,358,359,358,359,148,191,191,
  15,15,279,220,436,436,436,436,159,159,137,137,
  137,137,159,159,128,410,138,169,169,325,325,389,
  389,389,389,123,33,33,95,89,89,301,301,61,
  99,99,325,1409,228,228,206,228,228,228,228,228,
  1409,1409,228,72,72,72,267,89,89,97,97,97,
  97,97,97,29,29,29,143,143,296,178,11,51,
  296,117,117,117,117,429,429,32,334,409,409
 );
 KST : Array[0..4, 0..27] Of Integer = (
  (1,33,295,581,1163,1394,1728,1923,2055,2141,2225,2279,
   2292,2435,2751,2862,2947,3351,3359,3596,3876,4109,4119,4304,
   4309,4309,4312,4318),
  (4318,4341,4506,4806,5151,5349,5467,5650,5804,5976,6049,6089,
   6132,6262,6465,6528,6593,6821,6830,6999,7403,7615,7658,7696,
   7834,7834,7843,7847),
  (7847,7859,8013,8279,8297,8389,8564,8744,9014,9172,9202,9216,
   9452,9555,9692,9762,9809,9914,9919,10035,10453,10606,10681,10830,
   10979,10979,10980,11074),
  (11074,11086,11410,11604,12065,12237,12485,12578,12662,12785,12842,12866,
   12868,13010,13245,13335,13400,13712,13721,13892,14082,14266,14278,14392,
   14394,14394,14400,14416),
  (14416,14428,14708,14893,15327,15464,15541,15720,15857,15860,15985,15987,
   15989,16123,16356,16464,16537,16861,16874,17042,17441,17637,17677,17815,
   17817,17817,17818,17832)
 );
 NEMOE = 484;
 EMOC : Array[1..NEMOE] Of Byte = (
  1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,3,3,3,3,
  3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,
  5,5,5,5,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,
  8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,1,1,1,1,
  1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,
  3,3,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,6,
  6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,
  8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,
  3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,
  5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,
  7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,
  1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,
  3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,
  5,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,8,8,8,8,
  8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,1,1,1,1,1,1,1,1,1,1,
  2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,
  4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,
  6,6,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,9,
  9,9,9,9,9,9,9,9,9
 );
 EMOI : Array[1..NEMOE] Of Byte = (
  2,2,2,1,2,1,3,3,2,1,2,1,2,2,2,2,2,1,1,1,2,2,2,2,2,
  3,1,1,2,3,2,2,1,3,2,2,1,1,1,2,2,1,2,2,2,3,3,3,2,3,
  2,1,1,1,3,2,1,3,2,1,2,1,1,2,2,3,3,1,1,2,2,2,1,1,2,
  2,2,2,3,1,2,2,1,1,1,3,2,3,1,1,2,2,2,1,2,1,2,2,1,2,
  3,1,2,2,1,1,2,2,2,2,2,1,1,2,1,2,2,2,3,1,2,2,1,1,2,
  2,2,2,3,2,2,2,1,1,2,1,1,1,2,2,2,3,3,3,2,2,2,2,1,3,
  2,1,1,2,1,1,1,1,2,2,3,3,1,1,2,2,2,3,1,1,2,2,3,2,2,
  3,1,2,2,1,1,3,2,1,3,2,2,2,1,1,1,1,2,1,2,2,3,2,3,3,
  2,1,1,1,2,1,2,2,2,2,1,1,1,1,1,2,2,3,2,3,1,2,2,2,1,
  2,2,1,2,1,1,2,2,1,2,3,2,2,1,1,3,2,2,2,2,2,3,3,1,1,
  2,2,3,1,3,1,1,1,2,2,1,1,2,1,1,3,2,1,2,2,2,1,3,1,1,
  2,2,2,2,2,3,2,1,1,2,2,2,3,2,1,3,2,1,2,2,2,3,1,1,2,
  2,2,1,3,2,2,2,2,2,1,2,2,2,1,2,2,1,1,1,2,2,2,3,2,2,
  1,2,3,2,1,2,2,2,1,1,2,1,2,1,1,2,3,2,2,3,2,3,1,2,2,
  1,3,2,3,1,1,1,2,1,2,1,3,3,2,2,2,2,1,1,2,1,2,1,1,2,
  3,2,2,2,2,2,2,2,3,2,2,2,2,1,1,2,2,1,1,2,3,2,1,1,2,
  2,2,2,1,1,1,1,2,2,2,2,2,3,2,1,2,2,2,1,2,2,2,2,2,1,
  1,3,1,1,2,2,3,3,2,3,3,2,2,1,1,1,2,3,2,3,1,1,1,2,1,
  1,2,2,3,3,2,1,2,1,2,2,1,1,2,1,2,3,2,2,2,1,2,3,1,2,
  3,1,2,2,2,2,1,1,1
 );
 STOPS : Array[0..4] Of String[255] = (
  '|LE|LES|ET|JE|J|ELLE|ILS|UNE|DES|DU|DANS|ETAIT|ETAIS|AVAIT|AVAIS|ETE|AVE'+
    'C|POUR|MAIS|QUI|NOUS|MON|MES|QU|C|L|D|M|S|EST|SUR|AU|AUX|CE|CETTE|PUIS|V'+
    'ERS|OU|',
  '|THE|AND|I|WAS|WERE|MY|OF|TO|IT|THAT|WITH|HAD|SHE|HE|BUT|FOR|AT|HER|HIS|'+
    'THERE|THIS|FROM|THEY|WE|THEN|INTO|WHICH|WHEN|COULD|WOULD|BEEN|OUT|FELT|T'+
    '|BY|UP|ABOUT|',
  '|DER|DIE|DAS|UND|ICH|WAR|MICH|MIR|MEIN|MEINE|MEINEM|MEINER|EIN|EINE|EINE'+
    'N|EINEM|IST|ZU|MIT|AUF|SICH|ER|SIE|DEM|DEN|VON|WIE|DANN|ALS|AUCH|HATTE|W'+
    'URDE|AUS|NOCH|NACH|UBER|IM|',
  '|EL|LOS|LAS|Y|YO|ESTABA|ESTABAN|HABIA|PERO|POR|PARA|COMO|MIS|SUS|CUANDO|'+
    'HACIA|DESDE|SOBRE|HASTA|ENTONCES|YA|PORQUE|ESTA|ESTE|ESO|TODO|TAMBIEN|MI'+
    'ENTRAS|DONDE|MUY|ALGO|ELLA|PUES|AQUEL|FUE|',
  '|IL|DI|CHE|NEL|NELLA|DELLA|DELLO|DEGLI|DELLE|ERO|MI|MIO|MIA|MIEI|GLI|PER'+
    '|SONO|HO|AVEVO|AVEVA|MA|POI|ANCHE|PERCHE|QUANDO|QUESTO|QUESTA|ANCORA|VER'+
    'SO|TUTTO|MOLTO|SUL|DAL|ALLA|ALLO|AGLI|NON|'
 );
 NSAMP = 90;
 SAMP : Array[1..NSAMP] Of String[76] = (
  '1J''Çtais dans la maison de mon enfance, mais toutes les piäces Çtaient',
  '1plongÇes dans le noir et l''eau montait lentement dans le couloir. Une',
  '1angoisse terrible me serrait la gorge. J''entendais des'+
    ' pas derriäre moi et',
  '0je savais que quelqu''un me poursuivait.',
  '0',
  '1Je suis arrivÇe devant une vieille porte fermÇe Ö clÇ. Un serpent noir',
  '1s''enroulait autour de la poignÇe et j''Çtais paralysÇe'+
    ' par la peur. Dans ma',
  '1poche, j''ai trouvÇ une petite clÇ dorÇe. Quand j''ai'+
    ' ouvert, le sol s''est',
  '0dÇrobÇ et je suis tombÇe dans le vide, terrifiÇe.',
  '0',
  '1Puis ma chute s''est changÇe en vol. Je planais au-dessus'+
    ' d''une riviäre et,',
  '1sur un vieux pont de pierre, ma grand-märe, morte depuis des annÇes,',
  '1m''attendait. Elle souriait et me tendait la main. J''ai ressenti une',
  '0immense tendresse et un profond soulagement.',
  '0',
  '1Une lumiäre douce baignait tout le paysage. Le serpent avait disparu,',
  '1l''eau Çtait redevenue claire. Je me suis rÇveillÇe'+
    ' sereine, le coeur plein',
  '0de joie, avec l''impression d''avoir enfin trouvÇ la paix.',
  '1I was wandering through an old house I didn''t recognise, and dark water',
  '1was seeping under every door. A cold dread gripped my chest. Somewhere',
  '1behind me heavy footsteps followed, and I knew something was chasing me',
  '0through the endless corridors.',
  '0',
  '1At the end of the hallway I reached a locked door. A huge snake lay coiled',
  '1on the threshold, hissing, and I was so terrified I could barely breathe.',
  '1Then I noticed a rusty key in my hand. When I turned it, the floor gave',
  '0way and I was falling into the darkness in a panic.',
  '0',
  '1Suddenly I realised I was flying. I soared over a wide river towards an',
  '1old stone bridge, where my grandmother, who died years ago, was waiting',
  '1for me. She smiled and held me close, and I felt a wave of love and',
  '0warmth.',
  '0',
  '1A golden light spread across the sky. The water below was clear now, and',
  '1the snake had vanished. I woke up feeling peaceful and deeply relieved,',
  '0almost happy, as if a heavy weight had been lifted.',
  '1Ich stand in einem alten Haus, das mir seltsam vertraut vorkam. Aus den',
  '1WÑnden sickerte Wasser, und im Keller stieg es immer hîher. Eine lÑhmende',
  '1Angst packte mich. Hinter mir hîrte ich Schritte, jemand verfolgte mich',
  '0durch endlose, dunkle Flure.',
  '0',
  '1Am Ende des Gangs war eine verschlossene TÅr. Davor lag eine riesige',
  '1Schlange, und ich zitterte vor Entsetzen. Plîtzlich hielt ich einen alten',
  '1SchlÅssel in der Hand. Als ich die TÅr îffnete, gab der Boden nach, und',
  '0ich stÅrzte in die Tiefe, vîllig panisch.',
  '0',
  '1Doch mitten im Fall begann ich zu fliegen. Ich schwebte Åber einen breiten',
  '1Fluss auf eine steinerne BrÅcke zu. Dort wartete meine verstorbene',
  '1Gro·mutter auf mich. Sie lÑchelte und nahm mich in die Arme, und ich',
  '0spÅrte eine tiefe Geborgenheit.',
  '0',
  '1Ein warmes, goldenes Licht erfÅllte den Himmel. Das Wasser war jetzt klar,',
  '1die Schlange war verschwunden. Ich wachte erleichtert und glÅcklich auf,',
  '0mit einem GefÅhl von Frieden.',
  '1Estaba en una casa antigua que parec°a la de mi infancia, pero todo estaba',
  '1a oscuras y el agua sub°a poco a poco por las escaleras. Sent°a una',
  '1angustia terrible y el coraz¢n me lat°a con fuerza. Alguien me persegu°a',
  '0por los pasillos y yo o°a sus pasos cada vez m†s cerca.',
  '0',
  '1LleguÇ a una puerta cerrada con llave. En el umbral hab°a una serpiente',
  '1enorme que me miraba fijamente, y yo temblaba de miedo. De repente',
  '1encontrÇ una llave oxidada en el bolsillo. Al abrir la puerta, el suelo',
  '0desapareci¢ y ca° al vac°o, muerta de p†nico.',
  '0',
  '1Pero en plena ca°da empecÇ a volar. PasÇ sobre un r°o ancho hasta un viejo',
  '1puente de piedra, donde me esperaba mi abuela, que muri¢ hace a§os. Me',
  '0abraz¢ con mucho cari§o y sent° una ternura inmensa.',
  '0',
  '1Una luz dorada iluminaba el cielo. El agua estaba otra vez clara y la',
  '1serpiente se hab°a ido. Me despertÇ aliviada y llena de alegr°a, con una',
  '0paz que hac°a mucho tiempo que no sent°a.',
  '1Mi trovavo in una vecchia casa buia, che somigliava a quella dei miei',
  '1nonni. L''acqua filtrava sotto le porte e saliva lungo le scale. Provavo',
  '1un''angoscia fortissima, perchÇ qualcuno mi stava'+
    ' inseguendo nei corridoi e',
  '0sentivo i suoi passi sempre pió vicini.',
  '0',
  '1Alla fine del corridoio c''era una porta chiusa a chiave. Sulla soglia era',
  '1arrotolato un grosso serpente, e io tremavo di paura. All''improvviso mi',
  '1sono accorta di avere in mano una chiave antica. Quando ho aperto la',
  '1porta, il pavimento ä crollato e sono precipitata nel vuoto, in preda al',
  '0panico.',
  '0',
  '1Poi, mentre cadevo, ho cominciato a volare. Ho sorvolato un fiume fino a',
  '1un ponte di pietra, dove mi aspettava mia nonna, morta da molti anni. Mi',
  '1ha abbracciata con grande tenerezza e mi sono sentita finalmente al',
  '0sicuro.',
  '0',
  '1Una luce dorata illuminava il cielo. L''acqua era di nuovo limpida e il',
  '1serpente era sparito. Mi sono svegliata serena, piena di gioia, con un',
  '0sollievo immenso nel cuore.'
 );
 SAMPIX : Array[0..5] Of Integer = (1,19,37,55,72,91);
 CATN : Array[0..4, 1..18] Of String[28] = (
  ('Eau et nature','Animaux','Corps et santÇ','Personnes','Maison et lieux',
   'Objets','Voyages et transports','Actions et situations',
   'êlÇments et cosmos','SpiritualitÇ et mystäre',
   'Vie, mort et transformation','Nourriture et boisson','Argent et travail',
   'Vàtements et apparence','Amour et sexualitÇ','Couleurs et nombres',
   'Violence et danger','Fantastique et imaginaire'),
  ('Water and nature','Animals','Body and health','People','House and places',
   'Objects','Travel and transport','Actions and situations',
   'Elements and cosmos','Spirituality and mystery','Life, death and change',
   'Food and drink','Money and work','Clothes and appearance',
   'Love and sexuality','Colours and numbers','Violence and danger',
   'Fantasy and imagination'),
  ('Wasser und Natur','Tiere','Kîrper und Gesundheit','Personen',
   'Haus und Orte','GegenstÑnde','Reisen und Verkehr',
   'Handlungen, Situationen','Elemente und Kosmos','SpiritualitÑt, Mysterium',
   'Leben, Tod, Wandlung','Essen und Trinken','Geld und Arbeit',
   'Kleidung und Aussehen','Liebe und SexualitÑt','Farben und Zahlen',
   'Gewalt und Gefahr','Fantastisches'),
  ('Agua y naturaleza','Animales','Cuerpo y salud','Personas',
   'Casa y lugares','Objetos','Viajes y transportes','Acciones y situaciones',
   'Elementos y cosmos','Espiritualidad y misterio','Vida, muerte, cambio',
   'Comida y bebida','Dinero y trabajo','Ropa y apariencia',
   'Amor y sexualidad','Colores y n£meros','Violencia y peligro',
   'Fantas°a e imaginaci¢n'),
  ('Acqua e natura','Animali','Corpo e salute','Persone','Casa e luoghi',
   'Oggetti','Viaggi e trasporti','Azioni e situazioni','Elementi e cosmo',
   'SpiritualitÖ e mistero','Vita, morte, mutamento','Cibo e bevande',
   'Denaro e lavoro','Abiti e aspetto','Amore e sessualitÖ','Colori e numeri',
   'Violenza e pericolo','Fantastico e immaginario')
 );
 DOMN : Array[0..4, 1..8] Of String[26] = (
  ('Affectif et amoureux','Famille et foyer','Professionnel et matÇriel',
   'SantÇ et corps','Social et image de soi','Vie intÇrieure',
   'Spirituel et Çvolution','Changements et avenir'),
  ('Love and affection','Family and home','Work and material life',
   'Health and body','Social life, self-image','Inner life',
   'Spiritual growth','Change and future'),
  ('Liebe und GefÅhle','Familie und Zuhause','Beruf und Materielles',
   'Gesundheit und Kîrper','Soziales, Selbstbild','Innenleben',
   'Spirituelle Entwicklung','Wandel und Zukunft'),
  ('Afectivo y amoroso','Familia y hogar','Profesional y material',
   'Salud y cuerpo','Social e imagen propia','Vida interior',
   'Espiritual y evoluci¢n','Cambios y porvenir'),
  ('Affettivo e amoroso','Famiglia e casa','Professionale e materiale',
   'Salute e corpo','Sociale e immagine di sÇ','Vita interiore',
   'Spirituale ed evoluzione','Cambiamenti e futuro')
 );
 EMON : Array[0..4, 1..9] Of String[20] = (
  ('joie','amour','sÇrÇnitÇ','Çmerveillement','peur','anxiÇtÇ','coläre',
   'tristesse','honte, dÇgoñt'),
  ('joy','love','serenity','wonder','fear','anxiety','anger','sadness',
   'shame, disgust'),
  ('Freude','Liebe','Gelassenheit','Staunen','Angst','Unruhe','Wut','Trauer',
   'Scham, Ekel'),
  ('alegr°a','amor','serenidad','asombro','miedo','ansiedad','ira','tristeza',
   'vergÅenza, asco'),
  ('gioia','amore','serenitÖ','meraviglia','paura','ansia','rabbia',
   'tristezza','vergogna, disgusto')
 );
 TYPN : Array[0..4, 1..12] Of String[26] = (
  ('Cauchemar','Ràve d''angoisse','Ràve de dÇsir','Ràve affectif',
   'Ràve d''aventure','Ràve fantastique','Ràve spirituel',
   'Ràve de transformation','Ràve de mÇmoire','Ràve prÇmonitoire',
   'Ràve lucide','Ràve rÇcurrent'),
  ('Nightmare','Anxiety dream','Wish-fulfilment dream','Emotional dream',
   'Adventure dream','Fantasy dream','Spiritual dream','Transformation dream',
   'Memory dream','Premonitory dream','Lucid dream','Recurring dream'),
  ('Albtraum','Angsttraum','Wunschtraum','GefÅhlstraum','Abenteuertraum',
   'Fantasietraum','Spiritueller Traum','Wandlungstraum','Erinnerungstraum',
   'Vorahnungstraum','Klartraum','Wiederkehrender Traum'),
  ('Pesadilla','Sue§o de angustia','Sue§o de deseo','Sue§o afectivo',
   'Sue§o de aventura','Sue§o fant†stico','Sue§o espiritual',
   'Sue§o de transformaci¢n','Sue§o de memoria','Sue§o premonitorio',
   'Sue§o l£cido','Sue§o recurrente'),
  ('Incubo','Sogno d''angoscia','Sogno di desiderio','Sogno affettivo',
   'Sogno d''avventura','Sogno fantastico','Sogno spirituale',
   'Sogno di trasformazione','Sogno di memoria','Sogno premonitore',
   'Sogno lucido','Sogno ricorrente')
 );
 ARCN : Array[0..4, 1..10] Of String[22] = (
  ('L''Ombre','L''Anima ou l''Animus','La Persona','Le Soi','La Grande Märe',
   'Le Päre','Le Vieux Sage','L''Enfant divin','Le HÇros','Le Fripon'),
  ('The Shadow','Anima or Animus','The Persona','The Self','The Great Mother',
   'The Father','The Wise Old Man','The Divine Child','The Hero',
   'The Trickster'),
  ('Der Schatten','Anima oder Animus','Die Persona','Das Selbst',
   'Die Gro·e Mutter','Der Vater','Der Alte Weise','Das gîttliche Kind',
   'Der Held','Der Schelm'),
  ('La Sombra','El Anima o el Animus','La Persona','El S°-mismo',
   'La Gran Madre','El Padre','El Viejo Sabio','El Ni§o divino','El HÇroe',
   'El Embaucador'),
  ('L''Ombra','L''Anima o l''Animus','La Persona','Il SÇ','La Grande Madre',
   'Il Padre','Il Vecchio Saggio','Il Fanciullo divino','L''Eroe',
   'L''Imbroglione')
 );
 MOODN : Array[0..4, 0..4] Of String[14] = (
  ('Träs mauvaise','Mauvaise','Neutre','Bonne','Träs bonne'),
  ('Very bad','Bad','Neutral','Good','Very good'),
  ('Sehr schlecht','Schlecht','Neutral','Gut','Sehr gut'),
  ('Muy mala','Mala','Neutra','Buena','Muy buena'),
  ('Pessima','Cattiva','Neutra','Buona','Ottima')
 );
 LANGN : Array[0..4, 0..5] Of String[12] = (
  ('Automatique','Franáais','Anglais','Allemand','Espagnol','Italien'),
  ('Automatic','French','English','German','Spanish','Italian'),
  ('Automatisch','Franzîsisch','Englisch','Deutsch','Spanisch','Italienisch'),
  ('Autom†tico','FrancÇs','InglÇs','Alem†n','Espa§ol','Italiano'),
  ('Automatico','Francese','Inglese','Tedesco','Spagnolo','Italiano')
 );
 TONEN : Array[0..4, 1..5] Of String[18] = (
  ('träs nÇgative','plutìt nÇgative','mitigÇe','plutìt positive',
   'träs positive'),
  ('very negative','rather negative','mixed','rather positive',
   'very positive'),
  ('sehr negativ','eher negativ','gemischt','eher positiv','sehr positiv'),
  ('muy negativa','m†s bien negativa','mixta','m†s bien positiva',
   'muy positiva'),
  ('molto negativa','piuttosto negativa','mista','piuttosto positiva',
   'molto positiva')
 );
 M_FILE = 1;
 M_DREAM = 2;
 M_ANAL = 3;
 M_DICT = 4;
 M_JOUR = 5;
 M_HELP = 6;
 M_NEW = 7;
 M_OPEN = 8;
 M_SAVE = 9;
 M_IMPORT = 10;
 M_EXPORT = 11;
 M_QUIT = 12;
 M_EDIT = 13;
 M_PROPS = 14;
 M_HILITE = 15;
 M_CLEAR = 16;
 M_SAMPLE = 17;
 M_REPORT = 18;
 M_SYMS = 19;
 M_TONE = 20;
 M_THEMES = 21;
 M_CLASS = 22;
 M_ARCH = 23;
 M_SENSE = 24;
 M_BROWSE = 25;
 M_SEARCH = 26;
 M_BYCAT = 27;
 M_JLIST = 28;
 M_JSTATS = 29;
 M_GUIDE = 30;
 M_ABOUT = 31;
 S_STATUS = 32;
 S_EDIT = 33;
 S_SCROLL = 34;
 S_CLICK = 35;
 S_GRAPH = 36;
 I_UNTITLED = 37;
 I_WORDS = 38;
 I_SYMS = 39;
 I_TONE = 40;
 W_TITLE = 41;
 W_SUB = 42;
 W_KEYS = 43;
 W_LANGS = 44;
 W_DICT = 45;
 R_TITLE = 46;
 R_DATE = 47;
 R_DREAMER = 48;
 R_LANG = 49;
 R_DETECT = 50;
 R_LEN = 51;
 R_SENTS = 52;
 R_EMOW = 53;
 R_MOOD = 54;
 R_RECUR = 55;
 R_LUCID = 56;
 R_TONE = 57;
 R_SCORE = 58;
 R_POS = 59;
 R_NEG = 60;
 R_NEU = 61;
 R_DOMEMO = 62;
 R_NOEMO = 63;
 R_EVOL = 64;
 R_SYMS = 65;
 R_THEMES = 66;
 R_DOMAINS = 67;
 R_CLASS = 68;
 R_ARCH = 69;
 R_NOARCH = 70;
 R_SENSE = 71;
 R_CATEG = 72;
 R_DOMAIN = 73;
 R_ARCHL = 74;
 R_TYPEL = 75;
 R_POLAR = 76;
 R_KEYS = 77;
 R_IFPOS = 78;
 R_IFNEG = 79;
 R_OCC = 80;
 R_FRONLY = 81;
 G_TONE = 82;
 G_PIE = 83;
 G_EVOL = 84;
 G_EMO = 85;
 G_START = 86;
 G_END = 87;
 G_THEMES = 88;
 G_DOMS = 89;
 G_OTHER = 90;
 G_CLASS = 91;
 G_NODATA = 92;
 G_JOUR = 93;
 G_JTONE = 94;
 G_JTYPES = 95;
 G_JSYMS = 96;
 G_JCOUNT = 97;
 G_JAVG = 98;
 G_JEMPTY = 99;
 X_DICT = 100;
 X_SEARCH = 101;
 X_WORD = 102;
 X_NOTFOUND = 103;
 X_RESULTS = 104;
 X_CHOOSECAT = 105;
 D_OK = 106;
 D_CANCEL = 107;
 D_YES = 108;
 D_NO = 109;
 D_DELETE = 110;
 D_PROPS = 111;
 D_TITLE = 112;
 D_DATE = 113;
 D_DREAMER = 114;
 D_MOOD = 115;
 D_LANG = 116;
 D_RECUR = 117;
 D_LUCID = 118;
 D_HINTDLG = 119;
 D_BADDATE = 120;
 D_JOURNAL = 121;
 D_EMPTY = 122;
 D_CONFDEL = 123;
 D_CONFNEW = 124;
 D_CONFCLR = 125;
 D_CONFQUIT = 126;
 D_SAVED = 127;
 D_IOERR = 128;
 D_IMPORT = 129;
 D_EXPORT = 130;
 D_FILE = 131;
 D_IMPORTED = 132;
 D_EXPORTED = 133;
 D_NOTEXT = 134;
 D_FULL = 135;
 D_DEFTITLE = 136;
 D_ABOUT = 137;
 NMSG = 137;
 MSG : Array[1..NMSG, 0..4] Of String[250] = (
  ('&Fichier',
   '&File',
   '&Datei',
   '&Archivo',
   '&File'),
  ('&Ràve',
   '&Dream',
   '&Traum',
   '&Sue§o',
   '&Sogno'),
  ('&Analyse',
   '&Analysis',
   '&Analyse',
   'A&n†lisis',
   '&Analisi'),
  ('&Dictionnaire',
   'D&ictionary',
   '&Wîrterbuch',
   '&Diccionario',
   '&Dizionario'),
  ('&Journal',
   '&Journal',
   'Ta&gebuch',
   'Dia&rio',
   'D&iario'),
  ('A&ide',
   '&Help',
   '&Hilfe',
   'A&yuda',
   'Ai&uto'),
  ('&Nouveau ràve...',
   '&New dream...',
   '&Neuer Traum...',
   '&Nuevo sue§o...',
   '&Nuovo sogno...'),
  ('&Ouvrir du journal...',
   '&Open from journal...',
   'Aus Tagebuch î&ffnen...',
   '&Abrir del diario...',
   '&Apri dal diario...'),
  ('&Enregistrer au journal',
   '&Save to journal',
   'Im Tagebuch &speichern',
   '&Guardar en el diario',
   '&Salva nel diario'),
  ('&Importer un fichier texte...',
   '&Import a text file...',
   'Textdatei &importieren...',
   '&Importar un archivo de texto...',
   '&Importa un file di testo...'),
  ('E&xporter le rapport...',
   'E&xport the report...',
   'Bericht e&xportieren...',
   'E&xportar el informe...',
   'E&sporta il rapporto...'),
  ('&Quitter',
   '&Quit',
   '&Beenden',
   '&Salir',
   '&Esci'),
  ('ê&crire le rÇcit',
   '&Write the account',
   'Bericht &schreiben',
   '&Escribir el relato',
   'S&crivi il racconto'),
  ('&PropriÇtÇs du ràve...',
   'Dream &properties...',
   'Traum&eigenschaften...',
   '&Propiedades del sue§o...',
   '&ProprietÖ del sogno...'),
  ('&Surligner les symboles',
   '&Highlight symbols',
   'Symbole &hervorheben',
   '&Resaltar los s°mbolos',
   '&Evidenzia i simboli'),
  ('&Effacer le rÇcit',
   '&Clear the account',
   'Bericht &lîschen',
   '&Borrar el relato',
   '&Cancella il racconto'),
  ('E&xemple de ràve',
   'E&xample dream',
   '&Beispieltraum',
   'E&jemplo de sue§o',
   'Ese&mpio di sogno'),
  ('&Rapport complet',
   'Full &report',
   '&VollstÑndiger Bericht',
   '&Informe completo',
   '&Rapporto completo'),
  ('&Symboles reconnus',
   'Recognised &symbols',
   'Erkannte &Symbole',
   '&S°mbolos reconocidos',
   '&Simboli riconosciuti'),
  ('&TonalitÇ et Çmotions',
   '&Tone and emotions',
   '&Stimmung und GefÅhle',
   '&Tonalidad y emociones',
   '&Tono ed emozioni'),
  ('T&hämes et domaines',
   '&Themes and life areas',
   '&Themen und Lebensbereiche',
   'T&emas y †mbitos',
   'T&emi e ambiti'),
  ('&Classification',
   '&Classification',
   '&Klassifikation',
   '&Clasificaci¢n',
   '&Classificazione'),
  ('Arc&hÇtypes',
   '&Archetypes',
   '&Archetypen',
   'Arque&tipos',
   'Arche&tipi'),
  ('Sens du &ràve',
   '&Meaning of the dream',
   '&Bedeutung des Traums',
   'Sentido del s&ue§o',
   'Senso del s&ogno'),
  ('&Parcourir les symboles',
   '&Browse the symbols',
   'Symbole &durchsuchen',
   '&Recorrer los s°mbolos',
   '&Sfoglia i simboli'),
  ('&Rechercher un symbole...',
   '&Search for a symbol...',
   'Symbol &suchen...',
   '&Buscar un s°mbolo...',
   '&Cerca un simbolo...'),
  ('Par &catÇgorie...',
   'By &category...',
   'Nach &Kategorie...',
   'Por &categor°a...',
   'Per &categoria...'),
  ('&Liste des ràves...',
   '&List of dreams...',
   'Traum&liste...',
   '&Lista de sue§os...',
   '&Elenco dei sogni...'),
  ('&Statistiques du journal',
   'Journal &statistics',
   'Tagebuch-&Statistik',
   '&Estad°sticas del diario',
   '&Statistiche del diario'),
  ('&Mode d''emploi',
   '&User guide',
   '&Bedienung',
   '&Modo de empleo',
   '&Istruzioni'),
  ('&A propos...',
   '&About...',
   '&öber...',
   '&Acerca de...',
   '&Informazioni...'),
  ('F2 Nouveau F3 Journal F5 RÇcit F6 Rapport F7 TonalitÇ F8 Thämes F9 Sens',
   'F2 New F3 Journal F5 Account F6 Report F7 Tone F8 Themes F9 Meaning',
   'F2 Neu F3 Tagebuch F5 Bericht F6 Analyse F7 Stimmung F8 Themen F9 Sinn',
   'F2 Nuevo F3 Diario F5 Relato F6 Informe F7 Tono F8 Temas F9 Sentido',
   'F2 Nuovo F3 Diario F5 Racconto F6 Rapporto F7 Tono F8 Temi F9 Senso'),
  ('Ligne %1/%2 Col. %3  Tab accent  F9 Sens  F10 Menus  Ctrl+Y Suppr. ligne',
   'Line %1/%2 Col. %3  Tab accent  F9 Meaning  F10 Menus  Ctrl+Y Delete'+
    ' line',
   'Zeile %1/%2 Sp. %3  Tab Akzent  F9 Sinn  F10 MenÅs  Strg+Y Zeile lîschen',
   'L°n. %1/%2 Col. %3  Tab acento  F9 Sentido  F10 Men£s  Ctrl+Y Borrar'+
    ' l°nea',
   'Riga %1/%2 Col. %3  Tab accento  F9 Senso  F10 Menu  Ctrl+Y Cancella'+
    ' riga'),
  ('Haut, Bas, PgPrÇc, PgSuiv : dÇfiler   êchap : retour au rÇcit',
   'Up, Down, PgUp, PgDn: scroll   Esc: back to the account',
   'Auf, Ab, Bild auf/ab: blÑttern   Esc: zurÅck zum Bericht',
   'Arriba, Abajo, ReP†g, AvP†g: desplazar   Esc: volver al relato',
   'Su, Gió, PagSu, PagGió: scorrere   Esc: torna al racconto'),
  ('Cliquez sur un symbole pour son dÇtail   Haut/Bas : dÇfiler   êchap :'+
    ' retour',
   'Click a symbol for its details   Up/Down: scroll   Esc: back',
   'Symbol anklicken fÅr Details   Auf/Ab: blÑttern   Esc: zurÅck',
   'Pulse un s°mbolo para su detalle   Arriba/Abajo: desplazar   Esc: volver',
   'Clicca su un simbolo per i dettagli   Su/Gió: scorrere   Esc: indietro'),
  ('F6 Rapport  F7 TonalitÇ  F8 Thämes  F9 Sens   êchap : retour au rÇcit',
   'F6 Report  F7 Tone  F8 Themes  F9 Meaning   Esc: back to the account',
   'F6 Analyse  F7 Stimmung  F8 Themen  F9 Sinn   Esc: zurÅck zum Bericht',
   'F6 Informe  F7 Tono  F8 Temas  F9 Sentido   Esc: volver al relato',
   'F6 Rapporto  F7 Tono  F8 Temi  F9 Senso   Esc: torna al racconto'),
  ('Nouveau ràve (sans titre)',
   'New dream (untitled)',
   'Neuer Traum (ohne Titel)',
   'Sue§o nuevo (sin t°tulo)',
   'Nuovo sogno (senza titolo)'),
  ('mots',
   'words',
   'Wîrter',
   'palabras',
   'parole'),
  ('symboles',
   'symbols',
   'Symbole',
   's°mbolos',
   'simboli'),
  ('tonalitÇ',
   'tone',
   'Stimmung',
   'tono',
   'tono'),
  ('InterprÇteur de ràves',
   'Dream interpreter',
   'Traumdeuter',
   'IntÇrprete de sue§os',
   'Interprete dei sogni'),
  ('êcrivez votre ràve : l''analyse en rÇväle les symboles et le sens',
   'Write down your dream: the analysis reveals its symbols and meaning',
   'Schreiben Sie Ihren Traum auf: die Analyse zeigt Symbole und Sinn',
   'Escriba su sue§o: el an†lisis revela sus s°mbolos y su sentido',
   'Scrivete il vostro sogno: l''analisi ne rivela simboli e senso'),
  ('F2 nouveau ràve    F5 Çcrire le rÇcit    F9 sens du ràve',
   'F2 new dream    F5 write the account    F9 meaning of the dream',
   'F2 neuer Traum    F5 Bericht schreiben    F9 Bedeutung',
   'F2 sue§o nuevo    F5 escribir el relato    F9 sentido del sue§o',
   'F2 nuovo sogno    F5 scrivi il racconto    F9 senso del sogno'),
  ('Le rÇcit peut àtre rÇdigÇ en franáais, anglais, allemand, espagnol ou'+
    ' italien.',
   'The account may be written in French, English, German, Spanish or'+
    ' Italian.',
   'Sprachen des Berichts: Franzîsisch, Englisch, Deutsch, Spanisch,'+
    ' Italienisch.',
   'El relato puede escribirse en francÇs, inglÇs, alem†n, espa§ol o'+
    ' italiano.',
   'Il racconto puï essere in francese, inglese, tedesco, spagnolo o'+
    ' italiano.'),
  ('Dictionnaire intÇgrÇ : %1 symboles, %2 mots-clÇs.',
   'Built-in dictionary: %1 symbols, %2 keywords.',
   'Eingebautes Wîrterbuch: %1 Symbole, %2 SchlÅsselwîrter.',
   'Diccionario integrado: %1 s°mbolos, %2 palabras clave.',
   'Dizionario integrato: %1 simboli, %2 parole chiave.'),
  ('Rapport d''analyse du ràve',
   'Dream analysis report',
   'Traumanalyse',
   'Informe de an†lisis del sue§o',
   'Rapporto di analisi del sogno'),
  ('Date',
   'Date',
   'Datum',
   'Fecha',
   'Data'),
  ('Ràveur',
   'Dreamer',
   'TrÑumer',
   'So§ador',
   'Sognatore'),
  ('Langue du rÇcit',
   'Language of the account',
   'Sprache',
   'Idioma del relato',
   'Lingua del racconto'),
  ('(dÇtectÇe)',
   '(detected)',
   '(erkannt)',
   '(detectado)',
   '(rilevata)'),
  ('Longueur',
   'Length',
   'LÑnge',
   'Longitud',
   'Lunghezza'),
  ('phrases',
   'sentences',
   'SÑtze',
   'frases',
   'frasi'),
  ('mots d''Çmotion',
   'emotion words',
   'GefÅhlswîrter',
   'palabras de emoci¢n',
   'parole di emozione'),
  ('Humeur au rÇveil',
   'Mood on waking',
   'Stimmung beim Erwachen',
   'Humor al despertar',
   'Umore al risveglio'),
  ('Ràve rÇcurrent',
   'Recurring dream',
   'Wiederkehrender Traum',
   'Sue§o recurrente',
   'Sogno ricorrente'),
  ('Ràve lucide',
   'Lucid dream',
   'Klartraum',
   'Sue§o l£cido',
   'Sogno lucido'),
  ('TonalitÇ gÇnÇrale',
   'Overall tone',
   'Grundstimmung',
   'Tonalidad general',
   'Tono generale'),
  ('Indice de tonalitÇ',
   'Tone index',
   'Stimmungsindex',
   'Indice de tonalidad',
   'Indice di tono'),
  ('positif',
   'positive',
   'positiv',
   'positivo',
   'positivo'),
  ('nÇgatif',
   'negative',
   'negativ',
   'negativo',
   'negativo'),
  ('neutre',
   'neutral',
   'neutral',
   'neutro',
   'neutro'),
  ('êmotion dominante',
   'Dominant emotion',
   'Vorherrschendes GefÅhl',
   'Emoci¢n dominante',
   'Emozione dominante'),
  ('Aucune Çmotion n''est exprimÇe explicitement.',
   'No emotion is explicitly expressed.',
   'Kein GefÅhl wird ausdrÅcklich genannt.',
   'No se expresa ninguna emoci¢n de forma expl°cita.',
   'Nessuna emozione ä espressa esplicitamente.'),
  ('êvolution',
   'Development',
   'Verlauf',
   'Evoluci¢n',
   'Evoluzione'),
  ('Symboles reconnus',
   'Recognised symbols',
   'Erkannte Symbole',
   'S°mbolos reconocidos',
   'Simboli riconosciuti'),
  ('Thämes dominants',
   'Main themes',
   'Hauptthemen',
   'Temas dominantes',
   'Temi dominanti'),
  ('Domaines de vie',
   'Life areas',
   'Lebensbereiche',
   'Ambitos de la vida',
   'Ambiti di vita'),
  ('Classification',
   'Classification',
   'Klassifikation',
   'Clasificaci¢n',
   'Classificazione'),
  ('ArchÇtypes',
   'Archetypes',
   'Archetypen',
   'Arquetipos',
   'Archetipi'),
  ('Aucun archÇtype marquÇ.',
   'No marked archetype.',
   'Kein ausgeprÑgter Archetyp.',
   'Ning£n arquetipo marcado.',
   'Nessun archetipo marcato.'),
  ('Sens du ràve',
   'Meaning of the dream',
   'Bedeutung des Traums',
   'Sentido del sue§o',
   'Senso del sogno'),
  ('CatÇgorie',
   'Category',
   'Kategorie',
   'Categor°a',
   'Categoria'),
  ('Domaine',
   'Life area',
   'Bereich',
   'Ambito',
   'Ambito'),
  ('ArchÇtype',
   'Archetype',
   'Archetyp',
   'Arquetipo',
   'Archetipo'),
  ('Type de ràve',
   'Dream type',
   'Traumtyp',
   'Tipo de sue§o',
   'Tipo di sogno'),
  ('PolaritÇ',
   'Polarity',
   'PolaritÑt',
   'Polaridad',
   'PolaritÖ'),
  ('Mots reconnus',
   'Recognised words',
   'Erkannte Wîrter',
   'Palabras reconocidas',
   'Parole riconosciute'),
  ('En contexte favorable',
   'In a pleasant context',
   'In angenehmem Zusammenhang',
   'En un contexto favorable',
   'In un contesto favorevole'),
  ('En contexte pÇnible',
   'In an unpleasant context',
   'In belastendem Zusammenhang',
   'En un contexto penoso',
   'In un contesto penoso'),
  ('occurrence(s) dans le rÇcit',
   'occurrence(s) in the account',
   'Vorkommen im Bericht',
   'aparici¢n(es) en el relato',
   'occorrenza/e nel racconto'),
  ('Les interprÇtations sont rÇdigÇes en franáais.',
   'Interpretations are written in French.',
   'Die Deutungen sind auf Franzîsisch verfasst.',
   'Las interpretaciones est†n redactadas en francÇs.',
   'Le interpretazioni sono redatte in francese.'),
  ('TonalitÇ et Çmotions',
   'Tone and emotions',
   'Stimmung und GefÅhle',
   'Tonalidad y emociones',
   'Tono ed emozioni'),
  ('êlÇments positifs et nÇgatifs',
   'Positive and negative elements',
   'Positive und negative Elemente',
   'Elementos positivos y negativos',
   'Elementi positivi e negativi'),
  ('êvolution Çmotionnelle au fil du rÇcit',
   'Emotional development through the account',
   'GefÅhlsverlauf im Bericht',
   'Evoluci¢n emocional a lo largo del relato',
   'Evoluzione emotiva nel corso del racconto'),
  ('êmotions exprimÇes',
   'Emotions expressed',
   'AusgedrÅckte GefÅhle',
   'Emociones expresadas',
   'Emozioni espresse'),
  ('dÇbut',
   'start',
   'Anfang',
   'inicio',
   'inizio'),
  ('fin',
   'end',
   'Ende',
   'final',
   'fine'),
  ('Thämes du ràve',
   'Themes of the dream',
   'Themen des Traums',
   'Temas del sue§o',
   'Temi del sogno'),
  ('Domaines de vie',
   'Life areas',
   'Lebensbereiche',
   'Ambitos de la vida',
   'Ambiti di vita'),
  ('Autres',
   'Others',
   'Andere',
   'Otros',
   'Altri'),
  ('Classification du ràve',
   'Classification of the dream',
   'Klassifikation des Traums',
   'Clasificaci¢n del sue§o',
   'Classificazione del sogno'),
  ('Pas assez d''ÇlÇments pour ce graphique.',
   'Not enough elements for this chart.',
   'Zu wenige Elemente fÅr diese Grafik.',
   'No hay suficientes elementos para este gr†fico.',
   'Elementi insufficienti per questo grafico.'),
  ('Statistiques du journal',
   'Journal statistics',
   'Tagebuch-Statistik',
   'Estad°sticas del diario',
   'Statistiche del diario'),
  ('TonalitÇ des derniers ràves',
   'Tone of the latest dreams',
   'Stimmung der letzten TrÑume',
   'Tonalidad de los £ltimos sue§os',
   'Tono degli ultimi sogni'),
  ('Types de ràves',
   'Dream types',
   'Traumtypen',
   'Tipos de sue§os',
   'Tipi di sogni'),
  ('Symboles frÇquents',
   'Most frequent symbols',
   'HÑufigste Symbole',
   'S°mbolos m†s frecuentes',
   'Simboli pió frequenti'),
  ('ràve(s) dans le journal',
   'dream(s) in the journal',
   'Traum/TrÑume im Tagebuch',
   'sue§o(s) en el diario',
   'sogno/i nel diario'),
  ('tonalitÇ moyenne',
   'average tone',
   'mittlere Stimmung',
   'tonalidad media',
   'tono medio'),
  ('Le journal est vide : enregistrez vos ràves (F4) pour suivre leur'+
    ' Çvolution.',
   'The journal is empty: save your dreams (F4) to follow their development.',
   'Das Tagebuch ist leer: speichern Sie TrÑume (F4), um den Verlauf zu'+
    ' sehen.',
   'El diario est† vac°o: guarde sus sue§os (F4) para seguir su evoluci¢n.',
   'Il diario ä vuoto: salvate i vostri sogni (F4) per seguirne'+
    ' l''evoluzione.'),
  ('Dictionnaire des symboles',
   'Dictionary of symbols',
   'Symbolwîrterbuch',
   'Diccionario de s°mbolos',
   'Dizionario dei simboli'),
  ('Rechercher un symbole',
   'Search for a symbol',
   'Symbol suchen',
   'Buscar un s°mbolo',
   'Cerca un simbolo'),
  ('Mot ou symbole',
   'Word or symbol',
   'Wort oder Symbol',
   'Palabra o s°mbolo',
   'Parola o simbolo'),
  ('Aucun symbole ne correspond Ö ce mot.',
   'No symbol matches this word.',
   'Kein Symbol passt zu diesem Wort.',
   'Ning£n s°mbolo corresponde a esta palabra.',
   'Nessun simbolo corrisponde a questa parola.'),
  ('RÇsultats de la recherche',
   'Search results',
   'Suchergebnisse',
   'Resultados de la b£squeda',
   'Risultati della ricerca'),
  ('Choisir une catÇgorie',
   'Choose a category',
   'Kategorie wÑhlen',
   'Elegir una categor°a',
   'Scegli una categoria'),
  ('OK',
   'OK',
   'OK',
   'Aceptar',
   'OK'),
  ('Annuler',
   'Cancel',
   'Abbrechen',
   'Cancelar',
   'Annulla'),
  ('Oui',
   'Yes',
   'Ja',
   'S°',
   'Sç'),
  ('Non',
   'No',
   'Nein',
   'No',
   'No'),
  ('Supprimer',
   'Delete',
   'Lîschen',
   'Eliminar',
   'Elimina'),
  ('PropriÇtÇs du ràve',
   'Dream properties',
   'Traumeigenschaften',
   'Propiedades del sue§o',
   'ProprietÖ del sogno'),
  ('Titre',
   'Title',
   'Titel',
   'T°tulo',
   'Titolo'),
  ('Date (jj/mm/aaaa)',
   'Date (dd/mm/yyyy)',
   'Datum (TT/MM/JJJJ)',
   'Fecha (dd/mm/aaaa)',
   'Data (gg/mm/aaaa)'),
  ('Ràveur',
   'Dreamer',
   'TrÑumer',
   'So§ador',
   'Sognatore'),
  ('Humeur au rÇveil',
   'Mood on waking',
   'Stimmung beim Erwachen',
   'Humor al despertar',
   'Umore al risveglio'),
  ('Langue du rÇcit',
   'Language',
   'Sprache',
   'Idioma del relato',
   'Lingua del racconto'),
  ('Ràve rÇcurrent',
   'Recurring dream',
   'Wiederkehrend',
   'Sue§o recurrente',
   'Sogno ricorrente'),
  ('Ràve lucide',
   'Lucid dream',
   'Klartraum',
   'Sue§o l£cido',
   'Sogno lucido'),
  ('Tab ou fläches : changer de champ. Espace, Gauche ou Droite : modifier'+
    ' un choix.',
   'Tab or arrows: change field. Space, Left or Right: change a choice.',
   'Tab oder Pfeile: Feld wechseln. Leertaste, Links, Rechts: Auswahl'+
    ' Ñndern.',
   'Tab o flechas: cambiar de campo. Espacio, Izquierda o Derecha: cambiar'+
    ' una opci¢n.',
   'Tab o frecce: cambiare campo. Spazio, Sinistra o Destra: cambiare una'+
    ' scelta.'),
  ('Date invalide.',
   'Invalid date.',
   'UngÅltiges Datum.',
   'Fecha no v†lida.',
   'Data non valida.'),
  ('Journal des ràves',
   'Dream journal',
   'Traumtagebuch',
   'Diario de sue§os',
   'Diario dei sogni'),
  ('Le journal est vide.',
   'The journal is empty.',
   'Das Tagebuch ist leer.',
   'El diario est† vac°o.',
   'Il diario ä vuoto.'),
  ('Supprimer ce ràve du journal ?',
   'Delete this dream from the journal?',
   'Diesen Traum aus dem Tagebuch lîschen?',
   '®Eliminar este sue§o del diario?',
   'Eliminare questo sogno dal diario?'),
  ('Le ràve en cours n''est pas enregistrÇ. Continuer quand màme ?',
   'The current dream is not saved. Continue anyway?',
   'Der aktuelle Traum ist nicht gespeichert. Trotzdem fortfahren?',
   'El sue§o actual no est† guardado. ®Continuar de todos modos?',
   'Il sogno corrente non ä salvato. Continuare comunque?'),
  ('Effacer tout le rÇcit ?',
   'Clear the whole account?',
   'Den ganzen Bericht lîschen?',
   '®Borrar todo el relato?',
   'Cancellare tutto il racconto?'),
  ('Le ràve en cours n''est pas enregistrÇ. Quitter quand màme ?',
   'The current dream is not saved. Quit anyway?',
   'Der aktuelle Traum ist nicht gespeichert. Trotzdem beenden?',
   'El sue§o actual no est† guardado. ®Salir de todos modos?',
   'Il sogno corrente non ä salvato. Uscire comunque?'),
  ('Ràve enregistrÇ dans le journal.',
   'Dream saved in the journal.',
   'Traum im Tagebuch gespeichert.',
   'Sue§o guardado en el diario.',
   'Sogno salvato nel diario.'),
  ('Erreur d''accäs au fichier.',
   'File access error.',
   'Fehler beim Dateizugriff.',
   'Error de acceso al archivo.',
   'Errore di accesso al file.'),
  ('Importer un fichier texte',
   'Import a text file',
   'Textdatei importieren',
   'Importar un archivo de texto',
   'Importa un file di testo'),
  ('Exporter le rapport',
   'Export the report',
   'Bericht exportieren',
   'Exportar el informe',
   'Esporta il rapporto'),
  ('Nom du fichier',
   'File name',
   'Dateiname',
   'Nombre del archivo',
   'Nome del file'),
  ('Fichier importÇ :',
   'File imported:',
   'Datei importiert:',
   'Archivo importado:',
   'File importato:'),
  ('Rapport enregistrÇ dans le fichier',
   'Report saved in the file',
   'Bericht gespeichert in der Datei',
   'Informe guardado en el archivo',
   'Rapporto salvato nel file'),
  ('Le rÇcit est vide : Çcrivez d''abord votre ràve (F5).',
   'The account is empty: first write down your dream (F5).',
   'Der Bericht ist leer: schreiben Sie zuerst Ihren Traum auf (F5).',
   'El relato est† vac°o: escriba primero su sue§o (F5).',
   'Il racconto ä vuoto: scrivete prima il vostro sogno (F5).'),
  ('Le rÇcit a atteint sa longueur maximale.',
   'The account has reached its maximum length.',
   'Der Bericht hat seine HîchstlÑnge erreicht.',
   'El relato ha alcanzado su longitud m†xima.',
   'Il racconto ha raggiunto la lunghezza massima.'),
  ('Ràve du',
   'Dream of',
   'Traum vom',
   'Sue§o del',
   'Sogno del'),
  ('InterprÇteur de ràves 1.0. Dictionnaire de %1 symboles et lexique de %2'+
    ' mots-clÇs en cinq langues ; classification en douze types, archÇtypes'+
    ' de Jung, graphiques et journal.',
   'Dream interpreter 1.0. Dictionary of %1 symbols and lexicon of %2'+
    ' keywords in five languages; twelve dream types, Jungian archetypes,'+
    ' charts and journal.',
   'Traumdeuter 1.0. Wîrterbuch mit %1 Symbolen und %2 SchlÅsselwîrtern in'+
    ' fÅnf Sprachen; zwîlf Traumtypen, Archetypen nach Jung, Grafiken und'+
    ' Tagebuch.',
   'IntÇrprete de sue§os 1.0. Diccionario de %1 s°mbolos y lÇxico de %2'+
    ' palabras clave en cinco idiomas; doce tipos de sue§os, arquetipos de'+
    ' Jung, gr†ficos y diario.',
   'Interprete dei sogni 1.0. Dizionario di %1 simboli e lessico di %2'+
    ' parole chiave in cinque lingue; dodici tipi di sogno, archetipi di'+
    ' Jung, grafici e diario.')
 );

{ ================================================================== }
{ Constantes du moteur                                               }
{ ================================================================== }

 SCREEN_W = 640;
 SCREEN_H = 480;
 MENU_H = 18;
 INFO_Y = 18;
 INFO_H = 22;
 BODY_Y = 42;
 STAT_Y = 431;                         { 462 sous DOS }
 LINE_H = 12;
 VIS_LINES = 32;                       { 34 sous DOS }
 WRAP_W = 74;

 NCAT = 18;
 NDOM = 8;
 NEMO = 9;
 NTYP = 12;
 NARC = 10;

 MAXEL = 400;                          { lignes de l'editeur }
 EW = 74;                              { largeur d'une ligne }
 MAXW = 4000;                          { mots analyses }
 MAXHIT = 250;                         { symboles distincts }
 MAXSENT = 800;                        { phrases }
 NSEG = 10;                            { segments de l'evolution }
 MAXVL = 900;
 MAXJ = 300;                           { reves du journal }

 JNLFILE = 'REVES.JNL';
 TMPFILE = 'REVES.TMP';
 TXTFILE = 'REVES.TXT';

 { Cibles speciales du lexique }
 T_EMO = 1000;
 T_NEG = 2000;
 T_INT = 2001;

 { Marques des mots (surlignage) }
 K_SYM = 1;
 K_POS = 2;
 K_NEG = 3;
 K_TOOL = 4;
 K_NEGATED = 5;

 { Types de reve }
 TY_NIGHT = 1;
 TY_ANX = 2;
 TY_WISH = 3;
 TY_LOVE = 4;
 TY_ADV = 5;
 TY_FANT = 6;
 TY_SPIR = 7;
 TY_TRANS = 8;
 TY_MEM = 9;
 TY_PREM = 10;
 TY_LUCID = 11;
 TY_RECUR = 12;

 { Ponderation : categorie de symbole -> type de reve }
 {  C G D F V X S T M P L R }
 CATTYP : Array[1..NCAT, 1..NTYP] Of Byte = (
  (0,0,0,0,1,0,1,1,1,0,0,0),
  (1,0,0,0,1,1,0,1,0,1,0,0),
  (1,2,1,0,0,0,0,0,1,0,0,0),
  (0,1,1,2,0,0,0,0,1,0,0,0),
  (0,1,0,1,0,0,0,0,1,0,0,0),
  (0,0,1,0,0,0,0,0,1,1,0,0),
  (0,1,0,0,3,0,0,1,0,0,0,0),
  (0,1,0,0,1,1,0,0,0,0,0,0),
  (0,0,0,0,0,1,2,1,0,1,0,0),
  (0,0,0,0,0,0,3,1,0,2,0,0),
  (1,0,0,0,0,0,1,3,0,1,0,0),
  (0,0,3,1,0,0,0,0,1,0,0,0),
  (0,2,1,0,0,0,0,0,2,0,0,0),
  (0,1,1,0,0,0,0,0,1,0,0,0),
  (0,0,2,3,0,0,0,0,0,0,0,0),
  (0,0,0,0,0,1,1,0,0,2,0,0),
  (3,2,0,0,0,0,0,0,0,0,0,0),
  (1,0,0,0,1,3,0,0,0,0,0,0));

 { Ponderation : classe d'emotion -> type de reve }
 EMOTYP : Array[1..NEMO, 1..NTYP] Of Byte = (
  (0,0,2,1,1,0,0,0,0,0,0,0),
  (0,0,1,3,0,0,0,0,0,0,0,0),
  (0,0,0,0,0,0,2,1,0,0,1,0),
  (0,0,0,0,1,2,2,0,0,0,1,0),
  (3,1,0,0,0,0,0,0,0,0,0,0),
  (1,3,0,0,0,0,0,0,0,0,0,0),
  (1,1,0,1,0,0,0,0,1,0,0,0),
  (0,1,0,1,0,0,0,1,1,0,0,0),
  (1,2,0,0,0,0,0,0,0,0,0,0));

 { Couleurs des secteurs, par rang }
 PIECOL : Array[1..9] Of Byte = (9, 10, 14, 12, 11, 13, 6, 3, 7);
 { Couleurs des emotions }
 EMOCOL : Array[1..NEMO] Of Byte = (14, 13, 11, 10, 12, 6, 4, 9, 5);

 { Conversion Latin-1 (C0..FF) vers la page de code 437 }
 LAT2CP : String[64] =
  'AAAA'#142#143#146#128'E'#144'EEIIIID•'+'OOOO'#153'xOUUU'#154'YT'#225+
  #133#160#131'a'#132#134#145#135#138#130#136#137#141#161#140#139+
  'd'#164#149#162#147'o'#148#246'o'#151#163#150#129'yt'#152;

 { Vues }
 V_WELCOME = 0;
 V_EDIT = 1;
 V_REPORT = 2;
 V_SYMS = 3;
 V_TONE = 4;
 V_THEMES = 5;
 V_CLASS = 6;
 V_ARCH = 7;
 V_SENSE = 8;
 V_DICT = 9;
 V_SYMDET = 10;
 V_JOURNAL = 11;
 V_GUIDE = 12;

{ ================================================================== }
{ Types                                                              }
{ ================================================================== }

Type
 TRArr = Array[1..20] Of Real;
 TIArr = Array[1..20] Of Integer;

 TDream = Record
  Title   : String[40];
  D, M, Y : Integer;
  Dreamer : String[24];
  Mood    : Integer;                    { 0 tres mauvaise .. 4 tres bonne }
  LangSel : Integer;                    { 0 automatique, 1..5 }
  Recur, Lucid : Boolean;
 End;

 TWord = Record
  W    : String[24];                    { forme normalisee }
  Ln, Col : Integer;                    { position dans l'editeur }
  Len  : Byte;
  Sent : Integer;                       { numero de phrase }
  Mark : Byte;
  Tar  : Integer;                       { cible du lexique }
 End;

 THit = Record
  Sym, Cnt, FirstW : Integer;
  Ctx : Real;                           { tonalite du contexte }
 End;

 TAnal = Record
  NW, NSent, Lg : Integer;
  NHit, NSymOcc, NEmoW : Integer;
  Hit : Array[1..MAXHIT] Of THit;
  HitO : Array[1..MAXHIT] Of Integer;   { ordre d'importance }
  Emo, Cat, Dom, Typ, Arc : TRArr;
  EmoO, CatO, DomO, TypO, ArcO : TIArr;
  TypP : TIArr;                         { pourcentages des types }
  CatT, DomT, EmoT, ArcT : Real;        { totaux }
  PosS, NegS : Real;
  PosN, NegN, NeuN : Integer;
  Score, ToneC, Evol : Integer;
  Seg : Array[1..NSEG] Of Real;
  SegN : Integer;
 End;

 TVLine = Record
  S    : String[90];
  C    : Byte;
  Kind : Byte;                          { 0 gauche, 1 centre, 2 titre }
  Ind  : Byte;
  Tag  : Integer;
 End;

{ ================================================================== }
{ Variables globales                                                 }
{ ================================================================== }

Var
 Lang : Integer;
 Dream : TDream;
 EL : Array[1..MAXEL] Of String[200];  { lignes du recit }
 ES : Array[1..MAXEL] Of Byte;         { 0 fin de paragraphe, 1 coupure
                                         sur une espace, 2 sans espace }
 EN, ECX, ECY, ETop : Integer;
 EMod, EDirty : Boolean;               { non enregistre / non analyse }
 JIdx : Integer;                       { rang dans le journal (0 = neuf) }
 Wd : Array[1..MAXW] Of TWord;
 NWd, NSentT : Integer;
 SentV : Array[1..MAXSENT] Of Real;
 OccS, OccH : Array[1..MAXW] Of Integer;
 NOcc : Integer;
 An : TAnal;
 Hilite : Boolean;
 View, ViewArg, PrevView : Integer;
 VL : Array[1..MAXVL] Of TVLine;
 VLN, VTop : Integer;
 WrapS, WrapP : String;
 WrapC, WrapI : Integer;
 MouseOK : Boolean;
 MsX, MsY, MsB : LongInt;
 MsSaved : Boolean;
 MsSaveX, MsSaveY : Integer;
 MsSaveBuf : Pointer;
 ActiveMenu : Integer;
 QuitReq : Boolean;
 StatusMsg : String;
 { journal }
 JN : Integer;
 JTitle : Array[1..MAXJ] Of String[40];
 JDate : Array[1..MAXJ] Of String[10];
 JScore, JTyp : Array[1..MAXJ] Of Integer;
 SymTot : Array[1..NSYM] Of Integer;
 TypTot : TRArr;
 JStatOK : Boolean;

{ ================================================================== }
{ Langues                                                            }
{ ================================================================== }

{ ================================================================== }
{ Reservoirs du dictionnaire : mot-cle K = KeysStr(K), ligne I = TxlStr(I) }
{ ================================================================== }

Var
 KPo, KOf : Array[1..NKEY] Of Integer;
 KLn : Array[1..NKEY] Of Byte;
 TPo, TOf : Array[1..NTX] Of Integer;
 TLn : Array[1..NTX] Of Byte;

{ index des reservoirs (au demarrage) }
Procedure InitPools;
Var
 P, I, K, St : Integer;
Begin
 K := 0;
 For P := 1 To 810 Do Begin
  St := 1;
  For I := 1 To Length(KEYSP[P]) Do
   If KEYSP[P][I] = '|' Then Begin
    Inc(K);
    KPo[K] := P; KOf[K] := St; KLn[K] := I - St;
    St := I + 1;
   End;
 End;
 K := 0;
 For P := 1 To 1200 Do Begin
  St := 1;
  For I := 1 To Length(TXLP[P]) Do
   If TXLP[P][I] = '|' Then Begin
    Inc(K);
    TPo[K] := P; TOf[K] := St; TLn[K] := I - St;
    St := I + 1;
   End;
 End;
End;

Function KeysStr(K : Integer) : String;
Begin
 KeysStr := Copy(KEYSP[KPo[K]], KOf[K], KLn[K]);
End;

Function TxlStr(I : Integer) : String;
Begin
 TxlStr := Copy(TXLP[TPo[I]], TOf[I], TLn[I]);
End;

Procedure InitLanguage;
Var
 L : String;
 I : Integer;
Begin
 L := GetEnv('LANGUAGE');
 For I := 1 To Length(L) Do L[I] := UpCase(L[I]);
 L := Copy(L, 1, 2);
 Lang := 0;
 If L = 'EN' Then Lang := 1 Else
 If (L = 'GR') Or (L = 'DE') Then Lang := 2 Else
 If (L = 'SP') Or (L = 'ES') Then Lang := 3 Else
 If L = 'IT' Then Lang := 4;
End;

Function Tx(Id : Integer) : String;
Begin
 Tx := MSG[Id, Lang];
End;

{ ================================================================== }
{ Utilitaires                                                        }
{ ================================================================== }

Function IStr(N : LongInt) : String;
Var
 S : String;
Begin
 Str(N, S);
 IStr := S;
End;

Function SignStr(N : Integer) : String;
Begin
 If N > 0 Then SignStr := '+' + IStr(N) Else SignStr := IStr(N);
End;

Function Pad2(N : Integer) : String;
Begin
 If N < 10 Then Pad2 := '0' + IStr(N) Else Pad2 := IStr(N);
End;

Function PadR(S : String; N : Integer) : String;
Begin
 While Length(S) < N Do S := S + ' ';
 PadR := S;
End;

Function PadL(S : String; N : Integer) : String;
Begin
 While Length(S) < N Do S := ' ' + S;
 PadL := S;
End;

Function UpStr(S : String) : String;
Var
 I : Integer;
Begin
 For I := 1 To Length(S) Do Begin
  Case S[I] Of
   #130, #136, #137, #138, #144 : S[I] := 'E';
   #131, #132, #133, #134, #142, #143, #160 : S[I] := 'A';
   #128, #135 : S[I] := 'C';
   #139, #140, #141, #161 : S[I] := 'I';
   #147, #148, #149, #153, #162 : S[I] := 'O';
   #129, #150, #151, #154, #163 : S[I] := 'U';
   #164, #165 : S[I] := 'N';
  Else S[I] := UpCase(S[I]);
  End;
 End;
 UpStr := S;
End;

Function LoStr(S : String) : String;
Var
 I : Integer;
Begin
 For I := 1 To Length(S) Do
  If (S[I] >= 'A') And (S[I] <= 'Z') Then S[I] := Chr(Ord(S[I]) + 32);
 LoStr := S;
End;

Function Trim(S : String) : String;
Begin
 While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
 While (Length(S) > 0) And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
 Trim := S;
End;

Function StripAmp(S : String) : String;
Var
 P : Integer;
Begin
 P := Pos('&', S);
 If P > 0 Then Delete(S, P, 1);
 StripAmp := S;
End;

Function ValI(S : String) : Integer;
Var
 V, E : Integer;
Begin
 Val(Trim(S), V, E);
 If E <> 0 Then V := 0;
 ValI := V;
End;

{ Remplace %1, %2, %3 }
Function Fmt(S, A, B, C : String) : String;
Var
 P : Integer;
Begin
 P := Pos('%1', S);
 If P > 0 Then Begin Delete(S, P, 2); Insert(A, S, P); End;
 P := Pos('%2', S);
 If P > 0 Then Begin Delete(S, P, 2); Insert(B, S, P); End;
 P := Pos('%3', S);
 If P > 0 Then Begin Delete(S, P, 2); Insert(C, S, P); End;
 Fmt := S;
End;

Function DaysInMonth(M, Y : Integer) : Integer;
Begin
 Case M Of
  4, 6, 9, 11 : DaysInMonth := 30;
  2 : If ((Y Mod 4 = 0) And (Y Mod 100 <> 0)) Or (Y Mod 400 = 0) Then
       DaysInMonth := 29 Else DaysInMonth := 28;
 Else DaysInMonth := 31;
 End;
End;

Function DateStr(D, M, Y : Integer) : String;
Begin
 DateStr := Pad2(D) + '/' + Pad2(M) + '/' + IStr(Y);
End;

Function PctStr(V, T : Real) : String;
Begin
 If T <= 0 Then PctStr := '0 %'
 Else PctStr := IStr(Round(100 * V / T)) + ' %';
End;

{ Tri decroissant stable d'un tableau de reels }
Procedure SortDesc(N : Integer; Var V : TRArr; Var O : TIArr);
Var
 I, J, K : Integer;
Begin
 For I := 1 To N Do O[I] := I;
 For I := 2 To N Do Begin
  K := O[I];
  J := I - 1;
  While (J >= 1) And (V[O[J]] < V[K]) Do Begin
   O[J + 1] := O[J];
   Dec(J);
  End;
  O[J + 1] := K;
 End;
End;

{ Caractere Latin-1 frappe ou lu -> page de code 437 }
Function ToCP(C : Char) : Char;
Begin
 If Ord(C) >= 192 Then ToCP := LAT2CP[Ord(C) - 191]
 Else Case Ord(C) Of
  171 : ToCP := #174;
  187 : ToCP := #175;
  176 : ToCP := #248;
  161 : ToCP := #173;
  191 : ToCP := #168;
 Else ToCP := C;
 End;
End;

{ Ligne UTF-8, Latin-1 ou CP437 -> CP437 }
Function LineToCP(S : String) : String;
Var
 I, B : Integer;
 R : String;
 Utf : Boolean;
Begin
 Utf := False;
 For I := 1 To Length(S) - 1 Do
  If (Ord(S[I]) In [$C2, $C3, $C5, $E2]) And
     (Ord(S[I + 1]) >= $80) And (Ord(S[I + 1]) <= $BF) Then Utf := True;
 R := '';
 I := 1;
 While I <= Length(S) Do Begin
  B := Ord(S[I]);
  If Utf And (B >= $C0) And (I < Length(S)) Then Begin
   If B = $C3 Then R := R + ToCP(Chr(Ord(S[I + 1]) + 64))
   Else If B = $C2 Then R := R + ToCP(S[I + 1])
   Else If (B = $C5) And (Ord(S[I + 1]) = $93) Then R := R + 'oe'
   Else If (B = $C5) And (Ord(S[I + 1]) = $92) Then R := R + 'Oe'
   Else If B = $E2 Then Begin
    If (I + 2 <= Length(S)) And (Ord(S[I + 2]) In [$98, $99]) Then
     R := R + ''''
    Else If (I + 2 <= Length(S)) And (Ord(S[I + 2]) In [$9C, $9D]) Then
     R := R + '"'
    Else If (I + 2 <= Length(S)) And (Ord(S[I + 2]) = $A6) Then
     R := R + '...'
    Else R := R + '-';
    Inc(I);
   End;
   Inc(I, 2);
  End Else Begin
   If (Not Utf) And (B >= 160) And (B <> 225) Then R := R + ToCP(S[I])
   Else If B = 9 Then R := R + ' '
   Else If B >= 32 Then R := R + S[I];
   Inc(I);
  End;
 End;
 LineToCP := R;
End;

{ Accent suivant d'une lettre (touche Tab ou ` de l'editeur) }
Function CycleAccent(C : Char) : Char;
Const
 NSQ = 14;
 SQ : Array[1..NSQ] Of String[6] = (
  'e'#130#138#136#137, 'a'#133#131#132#160, 'i'#140#139#161#141,
  'o'#147#148#162#149, 'u'#151#150#129#163, 'c'#135, 'n'#164,
  'E'#144, 'A'#142, 'O'#153, 'U'#154, 'C'#128, 'N'#165, 's'#225);
Var
 I, P : Integer;
Begin
 CycleAccent := C;
 For I := 1 To NSQ Do Begin
  P := Pos(C, SQ[I]);
  If P > 0 Then Begin
   If P = Length(SQ[I]) Then CycleAccent := SQ[I][1]
   Else CycleAccent := SQ[I][P + 1];
   Exit;
  End;
 End;
End;

{ ================================================================== }
{ Normalisation des mots                                             }
{ ================================================================== }

Function IsWordCh(C : Char) : Boolean;
Begin
 IsWordCh := (C In ['A'..'Z', 'a'..'z', '0'..'9']) Or
             ((Ord(C) >= 128) And (Ord(C) <= 154)) Or
             ((Ord(C) >= 160) And (Ord(C) <= 165)) Or (Ord(C) = 225);
End;

Function BaseUp(C : Char) : String;
Begin
 Case Ord(C) Of
  225 : BaseUp := 'SS';
  145, 146 : BaseUp := 'AE';
  152 : BaseUp := 'Y';
 Else BaseUp := UpStr(C);
 End;
End;

Function NormWord(S : String) : String;
Var
 I : Integer;
 R : String;
Begin
 R := '';
 For I := 1 To Length(S) Do
  If IsWordCh(S[I]) Then R := R + BaseUp(S[I])
  Else If (R <> '') And (R[Length(R)] <> ' ') Then R := R + ' ';
 NormWord := Trim(R);
End;

Function Bucket(C : Char) : Integer;
Begin
 If (C >= 'A') And (C <= 'Z') Then Bucket := Ord(C) - 64 Else Bucket := 0;
End;

{ ================================================================== }
{ Editeur : tampon de lignes avec retour a la ligne automatique      }
{ ================================================================== }

Procedure EdClear;
Begin
 EN := 1;
 EL[1] := '';
 ES[1] := 0;
 ECX := 1;
 ECY := 1;
 ETop := 0;
 EDirty := True;
End;

Function EdEmpty : Boolean;
Var
 I : Integer;
Begin
 EdEmpty := True;
 For I := 1 To EN Do
  If Trim(EL[I]) <> '' Then EdEmpty := False;
End;

Procedure EdInsLine(At : Integer; S : String; Soft : Byte);
Var
 I : Integer;
Begin
 If EN >= MAXEL Then Exit;
 For I := EN DownTo At Do Begin
  EL[I + 1] := EL[I];
  ES[I + 1] := ES[I];
 End;
 EL[At] := S;
 ES[At] := Soft;
 Inc(EN);
End;

Procedure EdDelLine(At : Integer);
Var
 I : Integer;
Begin
 If EN <= 1 Then Begin
  EL[1] := '';
  ES[1] := 0;
  Exit;
 End;
 For I := At To EN - 1 Do Begin
  EL[I] := EL[I + 1];
  ES[I] := ES[I + 1];
 End;
 Dec(EN);
End;

{ Debut du paragraphe d'une ligne }
Function ParaStart(L : Integer) : Integer;
Begin
 While (L > 1) And (ES[L - 1] <> 0) Do Dec(L);
 ParaStart := L;
End;

{ Position du curseur exprimee en decalage dans son paragraphe }
Procedure CurToOff(Var PS, Off : Integer);
Var
 J : Integer;
Begin
 PS := ParaStart(ECY);
 Off := 0;
 For J := PS To ECY - 1 Do Begin
  Off := Off + Length(EL[J]);
  If ES[J] = 1 Then Inc(Off);
 End;
 Off := Off + ECX - 1;
End;

Procedure OffToCur(PS, Off : Integer);
Var
 J : Integer;
Begin
 J := PS;
 While (J < EN) And (ES[J] <> 0) And (Off > Length(EL[J])) Do Begin
  Off := Off - Length(EL[J]);
  If ES[J] = 1 Then Dec(Off);
  Inc(J);
 End;
 ECY := J;
 If Off < 0 Then Off := 0;
 If Off > Length(EL[J]) Then Off := Length(EL[J]);
 ECX := Off + 1;
End;

{ Recompose un paragraphe a partir de sa ligne I }
Procedure ReflowPara(I : Integer);
Var
 P, N : Integer;
 S, Hd, Tl, W : String;
 Sep : Byte;
 Changed : Boolean;
Begin
 While I <= EN Do Begin
  Changed := False;
  If Length(EL[I]) > EW Then Begin
   S := EL[I];
   P := EW + 1;
   While (P > 1) And (S[P] <> ' ') Do Dec(P);
   If P > 1 Then Begin
    Hd := Copy(S, 1, P - 1);
    Tl := Copy(S, P + 1, 255);
    Sep := 1;
   End Else Begin
    Hd := Copy(S, 1, EW);
    Tl := Copy(S, EW + 1, 255);
    Sep := 2;
   End;
   If (ES[I] <> 0) And (I < EN) Then Begin
    If ES[I] = 1 Then EL[I + 1] := Tl + ' ' + EL[I + 1]
    Else EL[I + 1] := Tl + EL[I + 1];
   End Else Begin
    If EN >= MAXEL Then Begin
     EL[I] := Copy(S, 1, EW);
     Exit;
    End;
    EdInsLine(I + 1, Tl, 0);
   End;
   EL[I] := Hd;
   ES[I] := Sep;
   Changed := True;
  End Else If (ES[I] = 1) And (I < EN) Then Begin
   P := Pos(' ', EL[I + 1]);
   If P = 0 Then W := EL[I + 1] Else W := Copy(EL[I + 1], 1, P - 1);
   If Length(EL[I]) + 1 + Length(W) <= EW Then Begin
    EL[I] := EL[I] + ' ' + W;
    If P = 0 Then Begin
     ES[I] := ES[I + 1];
     EdDelLine(I + 1);
    End Else EL[I + 1] := Copy(EL[I + 1], P + 1, 255);
    Changed := True;
   End;
  End Else If (ES[I] = 2) And (I < EN) Then Begin
   N := EW - Length(EL[I]);
   If N > 0 Then Begin
    EL[I] := EL[I] + Copy(EL[I + 1], 1, N);
    Delete(EL[I + 1], 1, N);
    If EL[I + 1] = '' Then Begin
     ES[I] := ES[I + 1];
     EdDelLine(I + 1);
    End;
    Changed := True;
   End;
  End;
  If Not Changed Then Begin
   If (ES[I] = 0) Or (I >= EN) Then Begin
    ES[EN] := 0;
    Exit;
   End;
   Inc(I);
  End;
 End;
 ES[EN] := 0;
End;

{ Recompose le paragraphe du curseur en conservant sa position }
Procedure EdReflow;
Var
 PS, Off : Integer;
Begin
 CurToOff(PS, Off);
 ReflowPara(PS);
 OffToCur(PS, Off);
 EDirty := True;
 EMod := True;
End;

Function EdFull : Boolean;
Begin
 EdFull := EN >= MAXEL - 2;
End;

Procedure EdAccent;
Var
 C : Char;
Begin
 If (ECX < 2) Or (ECX > Length(EL[ECY]) + 1) Then Exit;
 C := CycleAccent(EL[ECY][ECX - 1]);
 If C = EL[ECY][ECX - 1] Then Exit;
 EL[ECY][ECX - 1] := C;
 EDirty := True;
 EMod := True;
End;

Procedure EdChar(C : Char);
Begin
 If EdFull Then Exit;
 If ECX > Length(EL[ECY]) + 1 Then ECX := Length(EL[ECY]) + 1;
 Insert(C, EL[ECY], ECX);
 Inc(ECX);
 EdReflow;
End;

Procedure EdEnter;
Var
 R : String;
Begin
 If EdFull Then Exit;
 R := Copy(EL[ECY], ECX, 255);
 EL[ECY] := Copy(EL[ECY], 1, ECX - 1);
 EdInsLine(ECY + 1, R, ES[ECY]);
 ES[ECY] := 0;
 Inc(ECY);
 ECX := 1;
 EdReflow;
End;

Procedure EdBack;
Var
 P, L : Integer;
Begin
 If ECX > 1 Then Begin
  Delete(EL[ECY], ECX - 1, 1);
  Dec(ECX);
 End Else If ECY > 1 Then Begin
  P := ECY - 1;
  If ES[P] = 2 Then Begin
   Delete(EL[P], Length(EL[P]), 1);
   ECY := P;
   ECX := Length(EL[P]) + 1;
  End Else Begin
   L := Length(EL[P]);
   EL[P] := EL[P] + EL[ECY];
   ES[P] := ES[ECY];
   EdDelLine(ECY);
   ECY := P;
   ECX := L + 1;
  End;
 End Else Exit;
 EdReflow;
End;

Procedure EdDel;
Begin
 If ECX <= Length(EL[ECY]) Then Delete(EL[ECY], ECX, 1)
 Else If ECY < EN Then Begin
  If ES[ECY] = 2 Then Delete(EL[ECY + 1], 1, 1)
  Else Begin
   EL[ECY] := EL[ECY] + EL[ECY + 1];
   ES[ECY] := ES[ECY + 1];
   EdDelLine(ECY + 1);
  End;
 End Else Exit;
 EdReflow;
End;

Procedure EdKillLine;
Var
 S : Byte;
Begin
 S := ES[ECY];
 If (ECY > 1) And (ES[ECY - 1] <> 0) Then ES[ECY - 1] := S;
 EdDelLine(ECY);
 If ECY > EN Then ECY := EN;
 ECX := 1;
 EdReflow;
End;

{ Ajoute un paragraphe complet a la fin du recit }
Procedure EdAppendPara(S : String);
Begin
 If EdFull Then Exit;
 If (EN = 1) And (EL[1] = '') Then EL[1] := S
 Else EdInsLine(EN + 1, S, 0);
 ReflowPara(EN);
End;

{ ================================================================== }
{ Analyse                                                            }
{ ================================================================== }

Procedure AddWord(Var W : String; Ln, Col, Len, Sent : Integer);
Begin
 If W = '' Then Exit;
 If NWd < MAXW Then Begin
  Inc(NWd);
  Wd[NWd].W := Copy(W, 1, 24);
  Wd[NWd].Ln := Ln;
  Wd[NWd].Col := Col;
  Wd[NWd].Len := Len;
  Wd[NWd].Sent := Sent;
  Wd[NWd].Mark := 0;
  Wd[NWd].Tar := 0;
 End;
 W := '';
End;

{ Decoupe le recit en mots normalises et en phrases }
Procedure BuildWords;
Var
 I, J, Sent, WLn, WCol, WLen : Integer;
 W : String;
 C : Char;
 InSent : Boolean;
Begin
 NWd := 0;
 Sent := 1;
 InSent := False;
 W := '';
 WLn := 1; WCol := 1; WLen := 0;
 For I := 1 To EN Do Begin
  For J := 1 To Length(EL[I]) Do Begin
   C := EL[I][J];
   If IsWordCh(C) Then Begin
    If W = '' Then Begin
     WLn := I;
     WCol := J;
     WLen := 0;
    End;
    If Length(W) < 40 Then W := W + BaseUp(C);
    If WLn = I Then Inc(WLen);
   End Else Begin
    If W <> '' Then Begin
     AddWord(W, WLn, WCol, WLen, Sent);
     InSent := True;
    End;
    If (C In ['.', '!', '?', ';']) And InSent Then Begin
     If Sent < MAXSENT Then Inc(Sent);
     InSent := False;
    End;
   End;
  End;
  If ES[I] <> 2 Then Begin
   If W <> '' Then Begin
    AddWord(W, WLn, WCol, WLen, Sent);
    InSent := True;
   End;
   If (ES[I] = 0) And InSent Then Begin
    If Sent < MAXSENT Then Inc(Sent);
    InSent := False;
   End;
  End;
 End;
 If W <> '' Then Begin
  AddWord(W, WLn, WCol, WLen, Sent);
  InSent := True;
 End;
 If InSent Then NSentT := Sent Else NSentT := Sent - 1;
 If NSentT < 0 Then NSentT := 0;
End;

Function DetectLang : Integer;
Var
 Cnt : Array[0..4] Of Integer;
 I, L, Best : Integer;
Begin
 For L := 0 To 4 Do Cnt[L] := 0;
 For I := 1 To NWd Do
  For L := 0 To 4 Do
   If Pos('|' + Wd[I].W + '|', STOPS[L]) > 0 Then Inc(Cnt[L]);
 Best := Lang;
 For L := 0 To 4 Do
  If Cnt[L] > Cnt[Best] Then Best := L;
 DetectLang := Best;
End;

{ Nombre de mots reconnus par la cle a partir du mot I (0 = echec) }
Function MatchKey(Const K : String; I : Integer) : Integer;
Var
 P, Q, J : Integer;
 Part : String;
Begin
 MatchKey := 0;
 J := I;
 P := 1;
 While P <= Length(K) Do Begin
  Q := P;
  While (Q <= Length(K)) And (K[Q] <> ' ') Do Inc(Q);
  Part := Copy(K, P, Q - P);
  If J > NWd Then Exit;
  If Part[Length(Part)] = '*' Then Begin
   Delete(Part, Length(Part), 1);
   If Copy(Wd[J].W, 1, Length(Part)) <> Part Then Exit;
  End Else If Wd[J].W <> Part Then Exit;
  Inc(J);
  P := Q + 1;
 End;
 MatchKey := J - I;
End;

{ Cle la plus specifique reconnue a partir du mot I }
Procedure FindKey(I, Lg : Integer; Var Best, BestN : Integer);
Var
 B, K, N, L, BestL : Integer;
 C2 : Char;
 KW : String;
Begin
 Best := 0;
 BestN := 0;
 BestL := 0;
 B := Bucket(Wd[I].W[1]);
 If Length(Wd[I].W) >= 2 Then C2 := Wd[I].W[2] Else C2 := ' ';
 For K := KST[Lg, B] To KST[Lg, B + 1] - 1 Do Begin
  KW := KeysStr(K);
  If (Length(KW) >= 2) And (KW[2] <> C2) And (KW[2] <> '*')
   Then Continue;
  N := MatchKey(KW, I);
  If N > 0 Then Begin
   L := Length(KW) * 2;
   If KW[Length(KW)] = '*' Then L := L - 3;
   If L > BestL Then Begin
    Best := K;
    BestN := N;
    BestL := L;
   End;
  End;
 End;
End;

Function HitOf(S : Integer) : Integer;
Var
 I : Integer;
Begin
 HitOf := 0;
 For I := 1 To An.NHit Do
  If An.Hit[I].Sym = S Then Begin
   HitOf := I;
   Exit;
  End;
End;

Procedure AddValence(V : Real; I, Sg : Integer);
Begin
 If V > 0 Then Begin
  An.PosS := An.PosS + V;
  Inc(An.PosN);
 End Else If V < 0 Then Begin
  An.NegS := An.NegS - V;
  Inc(An.NegN);
 End Else Inc(An.NeuN);
 SentV[Wd[I].Sent] := SentV[Wd[I].Sent] + V;
 An.Seg[Sg] := An.Seg[Sg] + V;
End;

{ Une negation precede-t-elle le mot I (meme phrase, 3 mots) ? }
Function Negated(I : Integer) : Boolean;
Var
 J : Integer;
Begin
 Negated := False;
 J := I - 1;
 While (J >= 1) And (J >= I - 3) Do Begin
  If Wd[J].Sent <> Wd[I].Sent Then Exit;
  If Wd[J].Tar = T_NEG Then Begin
   Negated := True;
   Exit;
  End;
  Dec(J);
 End;
End;

Procedure ProcessSym(S, I, Sg : Integer);
Var
 H, T, D1, D2 : Integer;
 W, V : Real;
Begin
 H := HitOf(S);
 If H = 0 Then Begin
  If An.NHit >= MAXHIT Then Exit;
  Inc(An.NHit);
  H := An.NHit;
  An.Hit[H].Sym := S;
  An.Hit[H].Cnt := 0;
  An.Hit[H].FirstW := I;
  An.Hit[H].Ctx := 0;
 End;
 Inc(An.Hit[H].Cnt);
 If An.Hit[H].Cnt = 1 Then W := 1 Else W := 0.5;
 If SCAT[S] = 8 Then W := W * 0.6;
 An.Cat[SCAT[S]] := An.Cat[SCAT[S]] + W;
 D1 := SDOM[S] Div 10;
 D2 := SDOM[S] Mod 10;
 An.Dom[D1] := An.Dom[D1] + 2 * W;
 If D2 > 0 Then An.Dom[D2] := An.Dom[D2] + W;
 If SARC[S] > 0 Then An.Arc[SARC[S]] := An.Arc[SARC[S]] + W;
 For T := 1 To NTYP Do
  An.Typ[T] := An.Typ[T] + CATTYP[SCAT[S], T] * W;
 If STYP[S] >= TY_PREM Then An.Typ[STYP[S]] := An.Typ[STYP[S]] + 8 * W
 Else If STYP[S] > 0 Then An.Typ[STYP[S]] := An.Typ[STYP[S]] + 3 * W;
 V := SPOL[S] * 0.5 * W;
 If Negated(I) Then V := -V * 0.5;
 AddValence(V, I, Sg);
 Inc(An.NSymOcc);
 If NOcc < MAXW Then Begin
  Inc(NOcc);
  OccS[NOcc] := Wd[I].Sent;
  OccH[NOcc] := H;
 End;
End;

Function ProcessEmo(E, I, Sg : Integer) : Byte;
Var
 C, J, T, Sign : Integer;
 V, Mul : Real;
 Neg : Boolean;
Begin
 C := EMOC[E];
 V := EMOI[E];
 Mul := 1;
 Neg := False;
 J := I - 1;
 While (J >= 1) And (J >= I - 3) Do Begin
  If Wd[J].Sent <> Wd[I].Sent Then J := 0
  Else Begin
   If Wd[J].Tar = T_NEG Then Neg := True;
   If (Wd[J].Tar = T_INT) And (J >= I - 2) Then Mul := 1.5;
   Dec(J);
  End;
 End;
 If C <= 4 Then Sign := 1 Else Sign := -1;
 If Neg Then Begin
  AddValence(-Sign * V * 0.5, I, Sg);
  ProcessEmo := K_NEGATED;
 End Else Begin
  An.Emo[C] := An.Emo[C] + V * Mul;
  Inc(An.NEmoW);
  For T := 1 To NTYP Do
   An.Typ[T] := An.Typ[T] + EMOTYP[C, T] * V * Mul * 0.5;
  AddValence(Sign * V * Mul, I, Sg);
  If Sign > 0 Then ProcessEmo := K_POS Else ProcessEmo := K_NEG;
 End;
End;

Procedure ClearAnal;
Var
 I : Integer;
Begin
 An.NHit := 0;
 An.NSymOcc := 0;
 An.NEmoW := 0;
 For I := 1 To 20 Do Begin
  An.Emo[I] := 0; An.Cat[I] := 0; An.Dom[I] := 0;
  An.Typ[I] := 0; An.Arc[I] := 0; An.TypP[I] := 0;
 End;
 An.PosS := 0; An.NegS := 0;
 An.PosN := 0; An.NegN := 0; An.NeuN := 0;
 For I := 1 To NSEG Do An.Seg[I] := 0;
 An.Score := 0; An.ToneC := 3; An.Evol := 5;
 NOcc := 0;
End;

Function SignOf(V : Real) : Integer;
Begin
 If V > 0.25 Then SignOf := 1
 Else If V < -0.25 Then SignOf := -1
 Else SignOf := 0;
End;

Procedure Analyze;
Var
 I, J, K, N, T, Sg, Ch, Last : Integer;
 Mk : Byte;
 P, Ng, A1, A2, Tot : Real;
 HKey : Array[1..MAXHIT] Of Real;
Begin
 BuildWords;
 ClearAnal;
 If Dream.LangSel > 0 Then An.Lg := Dream.LangSel - 1
 Else An.Lg := DetectLang;
 An.NW := NWd;
 An.NSent := NSentT;
 If NWd >= 3 * NSEG Then An.SegN := NSEG Else An.SegN := NWd Div 3;
 If An.SegN < 1 Then An.SegN := 1;
 For I := 1 To NSentT + 1 Do
  If I <= MAXSENT Then SentV[I] := 0;
 I := 1;
 While I <= NWd Do Begin
  FindKey(I, An.Lg, K, N);
  If K = 0 Then Inc(I)
  Else Begin
   T := KTAR[K];
   Sg := LongInt(I - 1) * An.SegN Div NWd + 1;
   Mk := K_TOOL;
   If T < T_EMO Then Begin
    ProcessSym(T, I, Sg);
    Mk := K_SYM;
   End Else If T < T_NEG Then Mk := ProcessEmo(T - T_EMO, I, Sg);
   For J := I To I + N - 1 Do Begin
    Wd[J].Mark := Mk;
    Wd[J].Tar := T;
   End;
   I := I + N;
  End;
 End;
 { contexte des symboles : tonalite de la phrase et des voisines }
 For I := 1 To NOcc Do Begin
  J := OccS[I];
  P := SentV[J];
  If J > 1 Then P := P + 0.5 * SentV[J - 1];
  If J < NSentT Then P := P + 0.5 * SentV[J + 1];
  An.Hit[OccH[I]].Ctx := An.Hit[OccH[I]].Ctx + P;
 End;
 { tonalite }
 P := An.PosS;
 Ng := An.NegS;
 An.Score := Round(100 * (P - Ng) / (P + Ng + 2));
 If An.Score <= -45 Then An.ToneC := 1
 Else If An.Score <= -12 Then An.ToneC := 2
 Else If An.Score < 12 Then An.ToneC := 3
 Else If An.Score < 45 Then An.ToneC := 4
 Else An.ToneC := 5;
 { evolution }
 Ch := 0;
 Last := 0;
 A1 := 0;
 A2 := 0;
 For I := 1 To An.SegN Do Begin
  J := SignOf(An.Seg[I]);
  If (J <> 0) And (Last <> 0) And (J <> Last) Then Inc(Ch);
  If J <> 0 Then Last := J;
  If I <= An.SegN Div 2 Then A1 := A1 + An.Seg[I]
  Else A2 := A2 + An.Seg[I];
 End;
 If (A1 < -0.5) And (A2 > A1 + 1) And (A2 > 0) Then An.Evol := 1
 Else If (A1 > 0.5) And (A2 < A1 - 1) And (A2 < 0) Then An.Evol := 2
 Else If Ch >= 3 Then An.Evol := 5
 Else If (P > Ng) And (A1 >= 0) And (A2 >= 0) Then An.Evol := 3
 Else If (Ng > P) And (A1 <= 0) And (A2 <= 0) Then An.Evol := 4
 Else An.Evol := 5;
 { classification }
 If An.Score < 0 Then Begin
  An.Typ[TY_NIGHT] := An.Typ[TY_NIGHT] - An.Score / 15;
  An.Typ[TY_ANX] := An.Typ[TY_ANX] - An.Score / 25;
 End Else Begin
  An.Typ[TY_WISH] := An.Typ[TY_WISH] + An.Score / 20;
  If An.Score > 20 Then An.Typ[TY_NIGHT] := An.Typ[TY_NIGHT] * 0.4;
 End;
 If (An.Emo[5] = 0) And (An.Cat[17] = 0) Then
  An.Typ[TY_NIGHT] := An.Typ[TY_NIGHT] * 0.5;
 If An.Score > 0 Then An.Typ[TY_ANX] := An.Typ[TY_ANX] * 0.7;
 If Dream.Mood <= 1 Then Begin
  An.Typ[TY_NIGHT] := An.Typ[TY_NIGHT] + 2 - Dream.Mood;
  An.Typ[TY_ANX] := An.Typ[TY_ANX] + 2 - Dream.Mood;
 End Else If Dream.Mood >= 3 Then Begin
  An.Typ[TY_WISH] := An.Typ[TY_WISH] + Dream.Mood - 2;
  An.Typ[TY_SPIR] := An.Typ[TY_SPIR] + Dream.Mood - 2;
 End;
 An.Typ[TY_MEM] := An.Typ[TY_MEM] + 0.5;
 Tot := 0;
 For T := 1 To NTYP Do Tot := Tot + An.Typ[T];
 If Dream.Lucid Then An.Typ[TY_LUCID] := An.Typ[TY_LUCID] + 6 + Tot * 0.5;
 If Dream.Recur Then An.Typ[TY_RECUR] := An.Typ[TY_RECUR] + 6 + Tot * 0.5;
 Tot := 0;
 For T := 1 To NTYP Do Tot := Tot + An.Typ[T];
 For T := 1 To NTYP Do
  If Tot > 0 Then An.TypP[T] := Round(100 * An.Typ[T] / Tot);
 SortDesc(NTYP, An.Typ, An.TypO);
 SortDesc(NCAT, An.Cat, An.CatO);
 SortDesc(NDOM, An.Dom, An.DomO);
 SortDesc(NEMO, An.Emo, An.EmoO);
 SortDesc(NARC, An.Arc, An.ArcO);
 An.CatT := 0; An.DomT := 0; An.EmoT := 0; An.ArcT := 0;
 For I := 1 To NCAT Do An.CatT := An.CatT + An.Cat[I];
 For I := 1 To NDOM Do An.DomT := An.DomT + An.Dom[I];
 For I := 1 To NEMO Do An.EmoT := An.EmoT + An.Emo[I];
 For I := 1 To NARC Do An.ArcT := An.ArcT + An.Arc[I];
 { ordre d'importance des symboles }
 For I := 1 To An.NHit Do Begin
  HKey[I] := An.Hit[I].Cnt + 0.3 * Abs(SPOL[An.Hit[I].Sym]) +
             0.2 * Ord(STYP[An.Hit[I].Sym] > 0) -
             An.Hit[I].FirstW / (NWd + 1.0) * 0.1 -
             0.6 * Ord(SCAT[An.Hit[I].Sym] = 8);
  An.HitO[I] := I;
 End;
 For I := 2 To An.NHit Do Begin
  K := An.HitO[I];
  J := I - 1;
  While (J >= 1) And (HKey[An.HitO[J]] < HKey[K]) Do Begin
   An.HitO[J + 1] := An.HitO[J];
   Dec(J);
  End;
  An.HitO[J + 1] := K;
 End;
 EDirty := False;
End;

{ Tonalite du contexte d'un symbole : 1 favorable, -1 penible, 0 neutre }
Function HitTone(H : Integer) : Integer;
Var
 C : Real;
Begin
 C := An.Hit[H].Ctx;
 If C > 0.25 Then HitTone := 1
 Else If C < -0.25 Then HitTone := -1
 Else If An.Score >= 12 Then HitTone := 1
 Else If An.Score <= -12 Then HitTone := -1
 Else HitTone := 0;
End;

Procedure EnsureAnal;
Begin
 If EDirty Then Analyze;
End;


{ ================================================================== }
{ Graphiques                                                         }
{ ================================================================== }

Const
 CanvasTop = MENU_H;
 CanvasBot = STAT_Y + 17;

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
 WM_SIZE = $0007; WM_COMMAND = $0020; WM_SYSCOMMAND = $0021; WM_PAINT = $0023;
 WM_CLOSE = $0029; WM_QUIT = $002A; WM_INITMENU = $0033; WM_MOUSEMOVE = $0070;
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
 ScrW = 640; ScrH = 480;
 EvQMax = 64;
 { evenements : 1 touche, 2 clic, 5 commande de menu (9999 = fermer) }
 EV_KEY = 1; EV_CLICK = 2; EV_CMD = 5; CMD_CLOSE = 9999;

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
 Fb : Array[0..ScrW * ScrH - 1] Of Byte;     { image, lignes de bas en haut }
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
 If X2 > ScrW - 1 Then X2 := ScrW - 1;
 If Y2 > ScrH - 1 Then Y2 := ScrH - 1;
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
 If (X < 0) Or (Y < 0) Or (X >= ScrW) Or (Y >= ScrH) Then Exit;
 A := (ScrH - 1 - Y) * ScrW + X;
 If GWrite = XORPut Then Fb[A] := (Fb[A] Xor C) And 31 Else Fb[A] := C And 31;
End;

Procedure HSpan(X1, X2, Y, C : LongInt);
Var A, X : LongInt;
Begin
 If (Y < 0) Or (Y >= ScrH) Then Exit;
 If X1 < 0 Then X1 := 0;
 If X2 > ScrW - 1 Then X2 := ScrW - 1;
 If X2 < X1 Then Exit;
 A := (ScrH - 1 - Y) * ScrW;
 For X := X1 To X2 Do Fb[A + X] := C And 31;
End;

{ --- Graph : etat --- }

{ sur une page a fond blanc (PaperMode), les traits et le texte prennent
  la version foncee de leur couleur (blanc -> noir) ; les remplissages
  gardent leurs couleurs }
Procedure SetColor(C : Integer);
Begin
 C := C And 31;
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
 GFillColor := Color And 31;
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

Procedure Line(X1, Y1, X2, Y2 : Integer);
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

Procedure Rectangle(X1, Y1, X2, Y2 : Integer);
Begin
 Line(X1, Y1, X2, Y1); Line(X2, Y1, X2, Y2);
 Line(X2, Y2, X1, Y2); Line(X1, Y2, X1, Y1);
End;

Procedure Bar(X1, Y1, X2, Y2 : Integer);
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
 For Y := Y1 To Y2 Do HSpan(X1, X2, Y, GFillColor);
End;

Procedure PutPixel(X, Y : Integer; C : Word);
Begin
 GTouch(X, Y, X, Y);
 Plot(X, Y, C);
End;

Function GetPixel(X, Y : Integer) : Word;
Begin
 If (X < 0) Or (Y < 0) Or (X >= ScrW) Or (Y >= ScrH) Then GetPixel := 0
 Else GetPixel := Fb[(ScrH - 1 - Y) * ScrW + X];
End;

{ --- Graph : ellipses (angles en degres, sens trigonometrique) --- }

Procedure Ellipse(X, Y : Integer; StAngle, EndAngle : Word; XR, YR : Word);
Var A, A2, Steps, K, Px, Py, Qx, Qy : LongInt; T : Double;
Begin
 If (XR = 0) And (YR = 0) Then
 Begin
  PutPixel(X, Y, GColor);
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
   If GThick = 3 Then Line(Px, Py, Qx, Qy) Else LineThin(Px, Py, Qx, Qy);
   Px := Qx; Py := Qy;
  End;
 End;
End;

Procedure FillEllipse(X, Y : Integer; XR, YR : Word);
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
  HSpan(X - W, X + W, Y + Dy, GFillColor);
 End;
 Ellipse(X, Y, 0, 360, XR, YR);
End;

Procedure Arc(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 Ellipse(X, Y, StAngle, EndAngle, Radius, Radius);
End;

Procedure Circle(X, Y : Integer; Radius : Word);
Begin
 Ellipse(X, Y, 0, 360, Radius, Radius);
End;

{ secteur plein de StAngle a EndAngle (degres), puis son contour }
Procedure PieSlice(X, Y : Integer; StAngle, EndAngle, Radius : Word);
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
    If Inside Then Plot(X + Dx, Y + Dy, GFillColor);
   End;
 { contour : couleur du trait ; si c'est la version foncee (page blanche)
   de la couleur de remplissage, la couleur de remplissage (comme le BGI,
   ou le secteur et son contour sont de la meme couleur) }
 If GColor = 16 + GFillColor Then GColor := GFillColor;
 Ellipse(X, Y, StAngle, EndAngle, Radius, Radius);
 Line(X, Y, X + Round(Radius * Cos(A0 * Pi / 180)), Y - Round(Radius * Sin(A0 * Pi / 180)));
 Line(X, Y, X + Round(Radius * Cos(A1 * Pi / 180)), Y - Round(Radius * Sin(A1 * Pi / 180)));
End;

{ --- Graph : texte (police 8 x 8 agrandie GTextSz fois, fond transparent) --- }

Procedure OutTextXY(X, Y : Integer; S : String);
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
 For K := 0 To ScrW * ScrH - 1 Do Fb[K] := GBk;
 GTouch(0, 0, ScrW - 1, ScrH - 1);
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
 WrL(LongInt(@Bmi) + 4, ScrW);
 WrL(LongInt(@Bmi) + 8, ScrH);
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
 DirtyX1 := -1;
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
Procedure Blit(Hps, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
 If Y1 < CanvasTop Then Y1 := CanvasTop;
 If Y2 > CanvasBot Then Y2 := CanvasBot;
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 P[0] := X1; P[1] := CanvasBot - Y2; P[2] := X2 + 1; P[3] := CanvasBot - Y1 + 1;
 P[4] := X1; P[5] := ScrH - 1 - Y2; P[6] := X2 + 1; P[7] := ScrH - Y1;
 Dummy := GpiDrawBits(Hps, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

{ envoyer a l'ecran ce qui a change depuis le dernier appel }
Procedure FlushScreen;
Var Hps : LongInt;
Begin
 If (DirtyX1 < 0) Or (OsClient = 0) Then Exit;
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

{ procedure de la zone client : touches, clics et commandes deviennent
  des evenements de la file }
Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, K, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 ClientProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    Blit(Hps, 0, CanvasTop, ScrW - 1, CanvasBot);
    Dummy := WinEndPaint(Hps);
   End;
  WM_CHAR :
   Begin
    K := KeyCode(Mp1, Mp2);
    If K >= 0 Then
    Begin
     EvPush(EV_KEY, K, EvMX, EvMY);
     ClientProc := 1;
    End
    Else ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_MOUSEMOVE :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
   Begin
    X := S16(Mp1); Y := CanvasBot - S16(Mp1 Shr 16);
    EvMX := X; EvMY := Y;
    Dummy := WinSetFocus(HWND_DESKTOP, H);
    EvPush(EV_CLICK, 0, X, Y);
    ClientProc := 1;
   End;
  WM_COMMAND : EvPush(EV_CMD, Lo16(Mp1), EvMX, EvMY);
  WM_INITMENU : MenuInit(Lo16(Mp1));
  WM_CLOSE : EvPush(EV_CMD, CMD_CLOSE, EvMX, EvMY);
 Else
  ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

{ vider la file de messages de PM dans la file d'evenements }
Procedure PumpMessages;
Begin
 While WinPeekMsg(OsHab, LongInt(@Qmsg), 0, 0, 0, PM_REMOVE) <> 0 Do
 Begin
  If Qmsg[1] = WM_QUIT Then EvPush(EV_CMD, CMD_CLOSE, EvMX, EvMY)
  Else Dummy := WinDispatchMsg(OsHab, LongInt(@Qmsg));
 End;
End;

{ evenement suivant (attente) : renvoie son genre ; K = touche ou commande }
Function NextEvent(Var K, X, Y : LongInt) : LongInt;
Begin
 Repeat
  FlushScreen;
  If EvHead = EvTail Then PumpMessages;
  If EvHead = EvTail Then Dummy := DosSleep(10);
 Until EvHead <> EvTail;
 NextEvent := EvKind[EvHead];
 K := EvKey[EvHead]; X := EvX[EvHead]; Y := EvY[EvHead];
 EvHead := (EvHead + 1) Mod EvQMax;
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
 Rc[0] := 0; Rc[1] := 0; Rc[2] := ScrW; Rc[3] := CanvasBot + 1 - CanvasTop;
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

Procedure MouseOff;
Begin
End;

Procedure MouseOn;
Begin
End;

{ Attend un clic (renvoie True) ou une touche (renvoie False) ; les choix
  de la barre de menus sont ignores pendant une boite de dialogue, la
  fermeture de la fenetre l'annule (Echap) puis termine le programme }
Function WaitClickOrKey(Var K : Word) : Boolean;
Var
 Kd, Kk, X, Y : LongInt;
Begin
 Repeat
  Kd := NextEvent(Kk, X, Y);
  If Kd = EV_KEY Then Begin
   K := Kk; WaitClickOrKey := False; Exit;
  End;
  If Kd = EV_CLICK Then Begin
   MsX := X; MsY := Y; K := 0; WaitClickOrKey := True; Exit;
  End;
  If (Kd = EV_CMD) And (Kk = CMD_CLOSE) Then Begin
   QuitReq := True; K := 27; WaitClickOrKey := False; Exit;
  End;
 Until False;
End;

Procedure Box(X1, Y1, X2, Y2, C : Integer);
Begin
 SetFillStyle(SolidFill, C);
 Bar(X1, Y1, X2, Y2);
End;

Procedure Frame(X1, Y1, X2, Y2, C : Integer);
Begin
 SetColor(C);
 Rectangle(X1, Y1, X2, Y2);
End;

{ Affichage de texte : les glyphes a accent circonflexe de la police
  8x8 collent l'accent a la lettre ; on dessine la lettre de base puis
  l'accent un pixel plus haut. }
Procedure OutFix(X, Y : Integer; S : String; Sz : Integer);
Var
 I, Cx, C : Integer;
 T : String;
 Hat : Array[1..255] Of Boolean;
Begin
 T := S;
 For I := 1 To Length(T) Do Begin
  Hat[I] := True;
  Case T[I] Of
   #131 : T[I] := 'a';
   #136 : T[I] := 'e';
   #140 : T[I] := 'i';
   #147 : T[I] := 'o';
   #150 : T[I] := 'u';
  Else Hat[I] := False;
  End;
 End;
 OutTextXY(X, Y, T);
 C := GetColor;
 SetFillStyle(SolidFill, C);
 For I := 1 To Length(T) Do
  If Hat[I] Then Begin
   Cx := X + (I - 1) * 8 * Sz;
   Bar(Cx + 3 * Sz, Y - Sz, Cx + 5 * Sz - 1, Y - 1);
   Bar(Cx + 2 * Sz, Y, Cx + 3 * Sz - 1, Y + Sz - 1);
   Bar(Cx + 5 * Sz, Y, Cx + 6 * Sz - 1, Y + Sz - 1);
   If T[I] = 'i' Then Bar(Cx + 3 * Sz, Y, Cx + 5 * Sz - 1, Y + Sz - 1);
  End;
End;

Procedure TextAt(X, Y : Integer; S : String; C : Integer);
Begin
 SetColor(C);
 OutFix(X, Y, S, 1);
End;

Procedure TextAmp(X, Y : Integer; S : String; C : Integer);
Var
 P : Integer;
 T : String;
Begin
 P := Pos('&', S);
 T := StripAmp(S);
 SetColor(C);
 OutFix(X, Y, T, 1);
 If P > 0 Then Line(X + (P - 1) * 8, Y + 9, X + P * 8 - 2, Y + 9);
End;

{ bouton poussoir d'OS/2 : contour noir, relief, rectangle pointille
  autour du libelle quand il a le focus }
Procedure Button3D(X1, Y1, X2, Y2 : Integer; S : String; Focus : Boolean);
Var
 Tx0, Ty0 : Integer;
Begin
 Box(X1, Y1, X2, Y2, LightGray);
 Frame(X1, Y1, X2, Y2, Black);
 If Focus Then Frame(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, Black);
 Bevel(X1 + 1 + Ord(Focus), Y1 + 1 + Ord(Focus), X2 - 1 - Ord(Focus),
       Y2 - 1 - Ord(Focus), False);
 Tx0 := X1 + ((X2 - X1) - Length(StripAmp(S)) * 8) Div 2;
 Ty0 := Y1 + (Y2 - Y1 - 8) Div 2;
 TextAmp(Tx0, Ty0, S, Black);
 If Focus Then FocusRect(Tx0 - 3, Ty0 - 3, Tx0 + Length(StripAmp(S)) * 8 + 2,
                         Ty0 + 11);
End;

Function InRect(X, Y, X1, Y1, X2, Y2 : LongInt) : Boolean;
Begin
 InRect := (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2);
End;


{ ================================================================== }
{ Menus deroulants                                                   }
{ ================================================================== }

Const
 NMENU = 6;
 A_NEW = 1; A_OPEN = 2; A_SAVE = 3; A_IMPORT = 4; A_EXPORT = 5;
 A_QUIT = 6; A_EDIT = 7; A_PROPS = 8; A_HILITE = 9; A_CLEAR = 10;
 A_SAMPLE = 11; A_REPORT = 12; A_SYMS = 13; A_TONE = 14; A_THEMES = 15;
 A_CLASS = 16; A_ARCH = 17; A_SENSE = 18; A_BROWSE = 19; A_SEARCH = 20;
 A_BYCAT = 21; A_JLIST = 22; A_JSTATS = 23; A_GUIDE = 24; A_ABOUT = 25;
 MTitle : Array[1..NMENU] Of Integer = (M_FILE, M_DREAM, M_ANAL, M_DICT,
  M_JOUR, M_HELP);
 MCount : Array[1..NMENU] Of Integer = (8, 6, 8, 3, 2, 2);
 MItem : Array[1..NMENU, 1..8] Of Integer = (
  (M_NEW, M_OPEN, M_SAVE, 0, M_IMPORT, M_EXPORT, 0, M_QUIT),
  (M_EDIT, M_PROPS, 0, M_HILITE, M_CLEAR, M_SAMPLE, 0, 0),
  (M_SENSE, M_REPORT, 0, M_SYMS, M_TONE, M_THEMES, M_CLASS, M_ARCH),
  (M_BROWSE, M_SEARCH, M_BYCAT, 0, 0, 0, 0, 0),
  (M_JLIST, M_JSTATS, 0, 0, 0, 0, 0, 0),
  (M_GUIDE, M_ABOUT, 0, 0, 0, 0, 0, 0));
 MAct : Array[1..NMENU, 1..8] Of Integer = (
  (A_NEW, A_OPEN, A_SAVE, 0, A_IMPORT, A_EXPORT, 0, A_QUIT),
  (A_EDIT, A_PROPS, 0, A_HILITE, A_CLEAR, A_SAMPLE, 0, 0),
  (A_SENSE, A_REPORT, 0, A_SYMS, A_TONE, A_THEMES, A_CLASS, A_ARCH),
  (A_BROWSE, A_SEARCH, A_BYCAT, 0, 0, 0, 0, 0),
  (A_JLIST, A_JSTATS, 0, 0, 0, 0, 0, 0),
  (A_GUIDE, A_ABOUT, 0, 0, 0, 0, 0, 0));
 MKey : Array[1..NMENU, 1..8] Of String[6] = (
  ('F2', 'F3', 'F4', '', '', '', '', 'Alt+X'),
  ('F5', '', '', '', '', '', '', ''),
  ('F9', 'F6', '', '', 'F7', 'F8', '', ''),
  ('', '', '', '', '', '', '', ''),
  ('F3', '', '', '', '', '', '', ''),
  ('F1', '', '', '', '', '', '', ''));

Function MenuKey(M, I : Integer) : String;
Begin
 If MAct[M, I] = A_HILITE Then Begin
  If Hilite Then MenuKey := '[x]' Else MenuKey := '[ ]';
 End Else MenuKey := MKey[M, I];
End;

Function MenuX(M : Integer) : Integer;
Var
 I, X : Integer;
Begin
 X := 8;
 For I := 1 To M - 1 Do X := X + Length(StripAmp(Tx(MTitle[I]))) * 8 + 16;
 MenuX := X;
End;

Function MenuW(M : Integer) : Integer;
Var
 I, W, L : Integer;
Begin
 W := 0;
 For I := 1 To MCount[M] Do Begin
  L := Length(StripAmp(Tx(MItem[M, I]))) * 8 + Length(MenuKey(M, I)) * 8 + 40;
  If (MItem[M, I] <> 0) And (L > W) Then W := L;
 End;
 MenuW := W;
End;

{ la barre de menus est celle de PM }
Procedure DrawMenuBar;
Begin
End;

Procedure DrawDropdown(M, Hov : Integer);
Begin
End;

Function AmpChar(S : String) : Char;
Var
 P : Integer;
Begin
 P := Pos('&', S);
 If (P > 0) And (P < Length(S)) Then AmpChar := UpStr(S[P + 1])[1]
 Else AmpChar := #0;
End;

Procedure RedrawAll; Forward;

Function MenuAtX(X : LongInt) : Integer;
Var
 I : Integer;
Begin
 MenuAtX := 0;
 For I := 1 To NMENU Do
  If (X >= MenuX(I) - 6) And
     (X <= MenuX(I) + Length(StripAmp(Tx(MTitle[I]))) * 8 + 5) Then
   MenuAtX := I;
End;

Procedure FirstItem(M : Integer; Var Hov : Integer);
Begin
 Hov := 1;
 While MItem[M, Hov] = 0 Do Inc(Hov);
End;

{ Boucle d'un menu deroulant ; renvoie l'action choisie ou 0 }
{ les menus deroulants sont ceux de PM (F10, Alt + lettre, souris) }
Function RunMenu(M : Integer) : Integer;
Begin
 RunMenu := 0;
End;

{ barre de menus de PM construite a partir des tables ci-dessus : choix
  d'action A = identificateur 100 + A ; sous-menu M = 900 + M }
Procedure BuildMenuBar;
Var
 M, I, H0, H1 : Integer;
 S : String;
Begin
 MenuLen := 0;
 MnemoKeys := '';
 H0 := MnOpen;
 For M := 1 To NMENU Do Begin
  MnemoKeys := MnemoKeys + AmpChar(Tx(MTitle[M]));
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 900 + M, PmLabel(Tx(MTitle[M])));
  H1 := MnOpen;
  For I := 1 To MCount[M] Do
   If MItem[M, I] = 0 Then MnItem(MIS_SEPARATOR, 0, 800 + M * 10 + I, '')
   Else Begin
    S := PmLabel(Tx(MItem[M, I]));
    If MKey[M, I] <> '' Then S := S + #9 + MKey[M, I];
    MnItem(MIS_TEXT, 0, 100 + MAct[M, I], S);
   End;
  MnClose(H1, MCount[M]);
 End;
 MnClose(H0, NMENU);
 OsMenu := WinCreateMenu(OsFrame, LongInt(@MenuT));
End;

{ ouverture d'un menu : Surligner coche selon l'etat }
Procedure MenuInit(M : LongInt);
Begin
 If M = 902 Then MnAttr(100 + A_HILITE, MIA_CHECKED, Hilite);
End;

{ ================================================================== }
{ Tampon de lignes affichees                                         }
{ ================================================================== }

Procedure VClear;
Begin
 VLN := 0;
 VTop := 0;
 WrapS := '';
 WrapP := '';
End;

Procedure VAdd(S : String; C, Kind, Ind : Integer; Tag : Integer);
Begin
 If VLN >= MAXVL Then Exit;
 Inc(VLN);
 VL[VLN].S := Copy(S, 1, 90);
 VL[VLN].C := C;
 VL[VLN].Kind := Kind;
 VL[VLN].Ind := Ind;
 VL[VLN].Tag := Tag;
End;

Procedure VBlank;
Begin
 VAdd('', 7, 0, 0, 0);
End;

{ Ajoute des mots au paragraphe en cours (retour a la ligne auto) }
Procedure WrapWords(S : String);
Var
 W : String;
 I : Integer;
Begin
 S := S + ' ';
 W := '';
 For I := 1 To Length(S) Do
  If S[I] = ' ' Then Begin
   If W = 'Æ' Then Begin
    WrapP := W + ' ';
    W := '';
   End;
   If W <> '' Then Begin
    W := WrapP + W;
    WrapP := '';
    If WrapS = '' Then WrapS := W
    Else If ((W = 'Ø') Or (W = ':') Or (W = ';') Or (W = '!') Or
             (W = '?')) And (Length(WrapS) + 2 <= WRAP_W - WrapI + 2) Then
     WrapS := WrapS + ' ' + W
    Else If Length(WrapS) + 1 + Length(W) <= WRAP_W - WrapI Then
     WrapS := WrapS + ' ' + W
    Else Begin
     VAdd(WrapS, WrapC, 0, WrapI, 0);
     WrapS := W;
    End;
   End;
   W := '';
  End Else W := W + S[I];
End;

Procedure WrapFlush;
Begin
 If WrapP <> '' Then Begin
  If WrapS <> '' Then WrapS := WrapS + ' ';
  WrapS := WrapS + Trim(WrapP);
  WrapP := '';
 End;
 If WrapS <> '' Then VAdd(WrapS, WrapC, 0, WrapI, 0);
 WrapS := '';
End;

Procedure WrapStart(C, Ind : Integer);
Begin
 WrapFlush;
 WrapC := C;
 WrapI := Ind;
End;

Procedure VText(S : String; C, Ind : Integer);
Begin
 WrapStart(C, Ind);
 WrapWords(S);
 WrapFlush;
End;

{ Mots d'un bloc de texte integre, ajoutes au paragraphe en cours }
Procedure WrapBlock(B : Integer);
Var
 I : Integer;
Begin
 If (B < 1) Or (B > NBLK) Then Exit;
 For I := BLK[B] To BLK[B + 1] - 1 Do WrapWords(TxlStr(I));
End;

Procedure VBlock(B, C, Ind : Integer);
Begin
 WrapStart(C, Ind);
 WrapBlock(B);
 WrapFlush;
End;

Procedure VTitle(S : String);
Begin
 VAdd(S, Yellow, 2, 0, 0);
 VBlank;
End;

Procedure VSect(S : String);
Begin
 VBlank;
 VAdd(S, LightCyan, 0, 0, 0);
 SetColor(LightCyan);
End;

{ Texte d'un bloc dans une chaine (blocs courts seulement) }
Function BlockStr(B : Integer) : String;
Var
 I : Integer;
 S : String;
Begin
 S := '';
 If (B >= 1) And (B <= NBLK) Then
  For I := BLK[B] To BLK[B + 1] - 1 Do
   If Length(S) + Length(TxlStr(I)) < 254 Then Begin
    If S <> '' Then S := S + ' ';
    S := S + TxlStr(I);
   End;
 BlockStr := S;
End;

{ ================================================================== }
{ Noms                                                               }
{ ================================================================== }

Function CatName(I : Integer) : String;
Begin
 CatName := CATN[Lang, I];
End;

Function DomName(I : Integer) : String;
Begin
 DomName := DOMN[Lang, I];
End;

Function EmoName(I : Integer) : String;
Begin
 EmoName := EMON[Lang, I];
End;

Function TypName(I : Integer) : String;
Begin
 TypName := TYPN[Lang, I];
End;

Function ArcName(I : Integer) : String;
Begin
 ArcName := ARCN[Lang, I];
End;

Function YesNo(B : Boolean) : String;
Begin
 If B Then YesNo := Tx(D_YES) Else YesNo := Tx(D_NO);
End;

{ ================================================================== }
{ Dessin de l'ecran                                                  }
{ ================================================================== }

{ barre d'information (sous la barre de menus) et titre de la fenetre }
Procedure DrawInfo;
Var
 S, R : String;
Begin
 Box(0, INFO_Y, SCREEN_W - 1, BODY_Y - 1, LightGray);
 SetColor(White);
 Line(0, INFO_Y, SCREEN_W - 1, INFO_Y);
 SetColor(DarkGray);
 Line(0, BODY_Y - 1, SCREEN_W - 1, BODY_Y - 1);
 If Dream.Title <> '' Then S := Dream.Title Else S := Tx(I_UNTITLED);
 SetTitle('Onirologie - ' + S);
 If Dream.Y > 0 Then S := S + ', ' + DateStr(Dream.D, Dream.M, Dream.Y);
 If EMod Then S := S + ' *';
 R := '';
 If Not EdEmpty Then Begin
  EnsureAnal;
  R := IStr(An.NW) + ' ' + Tx(I_WORDS) + '  ' + IStr(An.NHit) + ' ' +
       Tx(I_SYMS) + '  ' + Tx(I_TONE) + ' ' + SignStr(An.Score);
 End;
 TextAt(8, INFO_Y + 7, Copy(S, 1, 76 - Length(R)), Black);
 TextAt(SCREEN_W - 8 - Length(R) * 8, INFO_Y + 7, R, Blue);
End;

{ barre d'etat d'OS/2 : zone en creux sur fond gris }
Procedure DrawStatus;
Var
 S : String;
Begin
 Box(0, STAT_Y, SCREEN_W - 1, SCREEN_H - 1, LightGray);
 Bevel(2, STAT_Y + 2, SCREEN_W - 3, SCREEN_H - 2, True);
 If View = V_EDIT Then
  S := Fmt(Tx(S_EDIT), IStr(ECY), IStr(EN), IStr(ECX))
 Else If StatusMsg <> '' Then S := StatusMsg
 Else S := Tx(S_STATUS);
 TextAt(6, STAT_Y + 6, Copy(S, 1, 78), Black);
End;

Procedure DrawStars;
Var
 I : Integer;
 X, Y, Sd : LongInt;
Begin
 Sd := 1900;
 For I := 1 To 240 Do Begin
  Sd := (Sd * 1103515245 + 12345) And $7FFFFFFF;
  X := (Sd Shr 8) Mod SCREEN_W;
  Sd := (Sd * 1103515245 + 12345) And $7FFFFFFF;
  Y := BODY_Y + (Sd Shr 8) Mod (STAT_Y - BODY_Y);
  If I Mod 7 = 0 Then PutPixel(X, Y, White)
  Else If I Mod 3 = 0 Then PutPixel(X, Y, LightGray)
  Else PutPixel(X, Y, DarkGray);
 End;
End;

Procedure DrawLinesAt(Y0, Vis : Integer);
Var
 I, Y, X, N : Integer;
 S : String;
Begin
 N := VLN - VTop;
 If N > Vis Then N := Vis;
 For I := 1 To N Do Begin
  Y := Y0 + (I - 1) * LINE_H;
  S := VL[VTop + I].S;
  Case VL[VTop + I].Kind Of
   1 : X := (SCREEN_W - Length(S) * 8) Div 2;
   2 : Begin
        X := 12;
        Box(6, Y - 3, SCREEN_W - 22, Y + 9, Blue);
       End;
  Else X := 12 + VL[VTop + I].Ind * 8;
  End;
  If VL[VTop + I].Kind = 2 Then Begin
   PaperMode := False;
   TextAt(X, Y, S, White);
   PaperMode := True;
  End Else TextAt(X, Y, S, VL[VTop + I].C);
 End;
End;

{ barre de defilement verticale d'OS/2 }
Procedure DrawScrollBar(Top, N, Vis : Integer);
Begin
 If N > Vis Then Begin
  PaperMode := False;
  DrawVScroll(SCREEN_W - 15, BODY_Y, SCREEN_W - 1, STAT_Y - 1, Top, N, Vis);
  PaperMode := True;
 End;
End;

Procedure DrawLines;
Begin
 DrawLinesAt(BODY_Y + 6, VIS_LINES);
 DrawScrollBar(VTop, VLN, VIS_LINES);
End;

{ ---- editeur ---- }

Procedure EdShowCursor;
Begin
 If ECY <= ETop Then ETop := ECY - 1;
 If ECY > ETop + VIS_LINES Then ETop := ECY - VIS_LINES;
 If ETop < 0 Then ETop := 0;
End;

Procedure DrawEditor;
Var
 I, L, Y, C : Integer;
Begin
 Box(0, BODY_Y, SCREEN_W - 1, STAT_Y - 1, White);
 SetColor(LightGray);
 Line(8, BODY_Y + 2, 8, STAT_Y - 3);
 For I := 1 To VIS_LINES Do Begin
  L := ETop + I;
  If L <= EN Then Begin
   Y := BODY_Y + 6 + (I - 1) * LINE_H;
   TextAt(12, Y, EL[L], White);
  End;
 End;
 If Hilite And Not EdEmpty Then Begin
  EnsureAnal;
  For I := 1 To NWd Do
   If (Wd[I].Mark > 0) And (Wd[I].Mark <> K_TOOL) And
      (Wd[I].Ln > ETop) And
      (Wd[I].Ln <= ETop + VIS_LINES) Then Begin
    Case Wd[I].Mark Of
     K_SYM : C := Yellow;
     K_POS : C := LightGreen;
     K_NEG : C := LightRed;
    Else C := LightGray;
    End;
    Y := BODY_Y + 6 + (Wd[I].Ln - ETop - 1) * LINE_H;
    TextAt(12 + (Wd[I].Col - 1) * 8, Y,
           Copy(EL[Wd[I].Ln], Wd[I].Col, Wd[I].Len), C);
   End;
 End;
 If (ECY > ETop) And (ECY <= ETop + VIS_LINES) Then Begin
  Y := BODY_Y + 6 + (ECY - ETop - 1) * LINE_H;
  Box(11 + (ECX - 1) * 8, Y - 2, 12 + (ECX - 1) * 8, Y + 9, Black);
 End;
 DrawScrollBar(ETop, EN, VIS_LINES);
End;

{ ---- graphiques ---- }

Procedure Slice(Cx, Cy, A0, A1, R, Col : Integer);
Begin
 If A1 <= A0 Then Exit;
 While A0 < 0 Do Begin
  A0 := A0 + 360;
  A1 := A1 + 360;
 End;
 SetFillStyle(SolidFill, Col);
 SetColor(Col);
 If A1 > 360 Then Begin
  PieSlice(Cx, Cy, A0, 360, R);
  PieSlice(Cx, Cy, 0, A1 - 360, R);
 End Else PieSlice(Cx, Cy, A0, A1, R);
End;

{ Camembert : N valeurs V (deja ordonnees), couleurs par rang }
Procedure DrawPie(Cx, Cy, R, N : Integer; Var V : TRArr; Var Cl : TIArr);
Var
 I, A0, A1, X, Y : Integer;
 T, Cum, Mid : Real;
 S : String;
Begin
 T := 0;
 For I := 1 To N Do T := T + V[I];
 If T <= 0 Then Begin
  SetColor(DarkGray);
  Circle(Cx, Cy, R);
  TextAt(Cx - Length(Tx(G_NODATA)) * 4, Cy - 4, Tx(G_NODATA), LightGray);
  Exit;
 End;
 Cum := 0;
 For I := 1 To N Do
  If V[I] > 0 Then Begin
   A1 := 90 - Round(Cum * 360 / T);
   A0 := 90 - Round((Cum + V[I]) * 360 / T);
   If V[I] >= T - 0.0001 Then Begin
    SetFillStyle(SolidFill, Cl[I]);
    SetColor(Black);
    FillEllipse(Cx, Cy, R, R);
   End Else Slice(Cx, Cy, A0, A1, R, Cl[I]);
   Cum := Cum + V[I];
  End;
 Cum := 0;
 SetColor(Black);
 For I := 1 To N Do
  If (V[I] > 0) And (V[I] < T - 0.0001) Then Begin
   Mid := (90 - Cum * 360 / T) * Pi / 180;
   Line(Cx, Cy, Cx + Round(R * Cos(Mid)), Cy - Round(R * Sin(Mid)));
   Cum := Cum + V[I];
  End;
 Cum := 0;
 For I := 1 To N Do
  If V[I] > 0 Then Begin
   Mid := (90 - (Cum + V[I] / 2) * 360 / T) * Pi / 180;
   Cum := Cum + V[I];
   If V[I] / T >= 0.06 Then Begin
    S := IStr(Round(100 * V[I] / T)) + '%';
    X := Cx + Round(R * 0.62 * Cos(Mid)) - Length(S) * 4;
    Y := Cy - Round(R * 0.62 * Sin(Mid)) - 4;
    TextAt(X, Y, S, Black);
   End;
  End;
 SetColor(LightGray);
 Circle(Cx, Cy, R);
End;

Procedure LegendLine(X, Y, Col : Integer; S : String; V, T : Real);
Begin
 Box(X, Y, X + 9, Y + 8, Col);
 Frame(X, Y, X + 9, Y + 8, DarkGray);
 TextAt(X + 14, Y + 1, S, LightGray);
 TextAt(X + 14 + 29 * 8 - Length(PctStr(V, T)) * 8, Y + 1, PctStr(V, T),
        White);
End;

{ Camembert d'une repartition (categories, domaines...) avec legende }
Procedure PieOf(Kind, Cx, Cy, R, Lx, Ly : Integer);
Var
 Src : TRArr;
 Ord : TIArr;
 V : TRArr;
 Cl : TIArr;
 N, I, M, K : Integer;
 T, Oth : Real;
 S : String;
Begin
 Case Kind Of
  1 : Begin N := NCAT; Src := An.Cat; Ord := An.CatO; End;
  2 : Begin N := NDOM; Src := An.Dom; Ord := An.DomO; End;
 Else
  Begin N := NTYP; Src := TypTot; SortDesc(NTYP, TypTot, Ord); End;
 End;
 T := 0;
 For I := 1 To N Do T := T + Src[I];
 M := 0;
 Oth := 0;
 For I := 1 To N Do
  If Src[Ord[I]] > 0 Then Begin
   If M < 7 Then Begin
    Inc(M);
    V[M] := Src[Ord[I]];
    Cl[M] := PIECOL[M];
   End Else Oth := Oth + Src[Ord[I]];
  End;
 If Oth > 0 Then Begin
  Inc(M);
  V[M] := Oth;
  Cl[M] := PIECOL[9];
 End;
 DrawPie(Cx, Cy, R, M, V, Cl);
 K := 0;
 For I := 1 To N Do
  If (Src[Ord[I]] > 0) And (K < 7) Then Begin
   Inc(K);
   Case Kind Of
    1 : S := CatName(Ord[I]);
    2 : S := DomName(Ord[I]);
   Else S := TypName(Ord[I]);
   End;
   LegendLine(Lx, Ly + (K - 1) * 13, PIECOL[K], Copy(S, 1, 22),
              Src[Ord[I]], T);
  End;
 If Oth > 0 Then
  LegendLine(Lx, Ly + K * 13, PIECOL[9], Tx(G_OTHER), Oth, T);
End;

Procedure HBar(X, Y, W, H : Integer; F : Real; Col : Integer);
Var
 L : Integer;
Begin
 Box(X, Y, X + W, Y + H, DarkGray);
 If F > 1 Then F := 1;
 L := Round(W * F);
 If L > 0 Then Box(X, Y, X + L, Y + H, Col);
End;

Procedure GraphTitle(S : String);
Begin
 Box(6, BODY_Y + 4, SCREEN_W - 7, BODY_Y + 18, Blue);
 PaperMode := False;
 TextAt(14, BODY_Y + 8, S, White);
 PaperMode := True;
End;

Procedure SubTitle(X, Y : Integer; S : String);
Begin
 TextAt(X, Y, S, LightCyan);
 SetColor(DarkGray);
 Line(X, Y + 10, X + Length(S) * 8, Y + 10);
End;

{ Jauge de tonalite de -100 a +100 }
Procedure DrawGauge(X, Y, W : Integer; Score : Integer);
Var
 I, Px, C : Integer;
Begin
 For I := 0 To 19 Do Begin
  If I < 5 Then C := Red
  Else If I < 9 Then C := LightRed
  Else If I < 11 Then C := LightGray
  Else If I < 15 Then C := LightGreen
  Else C := Green;
  Box(X + I * W Div 20, Y, X + (I + 1) * W Div 20 - 1, Y + 12, C);
 End;
 Frame(X - 1, Y - 1, X + W, Y + 13, DarkGray);
 Px := X + LongInt(Score + 100) * W Div 200;
 SetColor(White);
 SetFillStyle(SolidFill, White);
 Line(Px, Y - 4, Px, Y + 16);
 Bar(Px - 3, Y - 7, Px + 3, Y - 4);
 TextAt(X - 4, Y + 18, '-100', LightRed);
 TextAt(X + W Div 2 - 4, Y + 18, '0', LightGray);
 TextAt(X + W - 28, Y + 18, '+100', LightGreen);
End;

Procedure DrawTone;
Var
 V : TRArr;
 Cl : TIArr;
 I, X, Y, Y0, W, H, Px, Py, Qx, Qy : Integer;
 Mx, F : Real;
 S : String;
Begin
 GraphTitle(Tx(G_TONE));
 { elements positifs / negatifs / neutres }
 SubTitle(16, BODY_Y + 28, Tx(G_PIE));
 V[1] := An.PosN; V[2] := An.NegN; V[3] := An.NeuN;
 Cl[1] := LightGreen; Cl[2] := LightRed; Cl[3] := LightGray;
 DrawPie(120, BODY_Y + 122, 74, 3, V, Cl);
 LegendLine(16, BODY_Y + 206, LightGreen, Tx(R_POS) + ' (' + IStr(An.PosN)
            + ')', V[1], V[1] + V[2] + V[3]);
 LegendLine(16, BODY_Y + 219, LightRed, Tx(R_NEG) + ' (' + IStr(An.NegN)
            + ')', V[2], V[1] + V[2] + V[3]);
 LegendLine(16, BODY_Y + 232, LightGray, Tx(R_NEU) + ' (' + IStr(An.NeuN)
            + ')', V[3], V[1] + V[2] + V[3]);
 { jauge }
 SubTitle(276, BODY_Y + 28, Tx(R_SCORE));
 DrawGauge(286, BODY_Y + 54, 320, An.Score);
 S := SignStr(An.Score) + ' : ' + TONEN[Lang, An.ToneC];
 TextAt(286 + 160 - Length(S) * 4, BODY_Y + 86, S, White);
 { emotions }
 SubTitle(276, BODY_Y + 104, Tx(G_EMO));
 Mx := 0;
 For I := 1 To NEMO Do If An.Emo[I] > Mx Then Mx := An.Emo[I];
 For I := 1 To NEMO Do Begin
  Y := BODY_Y + 120 + (I - 1) * 14;
  TextAt(276, Y + 1, Copy(EmoName(I), 1, 16), EMOCOL[I]);
  If Mx > 0 Then F := An.Emo[I] / Mx Else F := 0;
  HBar(412, Y, 160, 9, F, EMOCOL[I]);
  TextAt(580, Y + 1, PadL(PctStr(An.Emo[I], An.EmoT), 5), LightGray);
 End;
 { evolution }
 Y0 := BODY_Y + 252;
 SubTitle(16, Y0, Tx(G_EVOL));
 X := 40; W := 560; H := 100;
 Y := Y0 + 18 + H Div 2;
 SetColor(DarkGray);
 Rectangle(X, Y0 + 18, X + W, Y0 + 18 + H);
 SetLineStyle(DottedLn, 0, 1);
 Line(X, Y, X + W, Y);
 SetLineStyle(SolidLn, 0, 1);
 Mx := 0.5;
 For I := 1 To An.SegN Do If Abs(An.Seg[I]) > Mx Then Mx := Abs(An.Seg[I]);
 For I := 1 To An.SegN Do Begin
  Px := X + (I - 1) * W Div An.SegN + 6;
  Qx := X + I * W Div An.SegN - 6;
  Py := Round(An.Seg[I] / Mx * (H Div 2 - 6));
  If Py > 0 Then Box(Px, Y - Py, Qx, Y - 1, Green)
  Else If Py < 0 Then Box(Px, Y + 1, Qx, Y - Py, Red);
 End;
 SetColor(Yellow);
 For I := 1 To An.SegN - 1 Do Begin
  Px := X + (2 * I - 1) * W Div (2 * An.SegN);
  Py := Y - Round(An.Seg[I] / Mx * (H Div 2 - 6));
  Qx := X + (2 * I + 1) * W Div (2 * An.SegN);
  Qy := Y - Round(An.Seg[I + 1] / Mx * (H Div 2 - 6));
  Line(Px, Py, Qx, Qy);
 End;
 For I := 1 To An.SegN Do Begin
  Px := X + (2 * I - 1) * W Div (2 * An.SegN);
  Py := Y - Round(An.Seg[I] / Mx * (H Div 2 - 6));
  SetFillStyle(SolidFill, Yellow);
  Bar(Px - 2, Py - 2, Px + 2, Py + 2);
 End;
 TextAt(X, Y0 + 18 + H + 4, Tx(G_START), LightGray);
 TextAt(X + W - Length(Tx(G_END)) * 8, Y0 + 18 + H + 4, Tx(G_END), LightGray);
 TextAt(X - 30, Y0 + 22, '+', LightGreen);
 TextAt(X - 30, Y0 + 10 + H, '-', LightRed);
End;

Procedure DrawThemes;
Begin
 GraphTitle(StripAmp(Tx(M_THEMES)));
 SubTitle(16, BODY_Y + 28, Tx(G_THEMES));
 SubTitle(336, BODY_Y + 28, Tx(G_DOMS));
 SetTextJustify(LeftText, TopText);
 PieOf(1, 160, BODY_Y + 146, 96, 12, BODY_Y + 262);
 PieOf(2, 480, BODY_Y + 146, 96, 332, BODY_Y + 262);
End;

Procedure DrawClass;
Var
 I, T, Y : Integer;
 Mx : Integer;
Begin
 GraphTitle(Tx(G_CLASS));
 Mx := 1;
 For I := 1 To NTYP Do If An.TypP[I] > Mx Then Mx := An.TypP[I];
 For I := 1 To NTYP Do Begin
  T := An.TypO[I];
  Y := BODY_Y + 30 + (I - 1) * 16;
  If I <= 3 Then TextAt(16, Y + 1, IStr(I) + '.', Yellow);
  If I <= 3 Then TextAt(40, Y + 1, TypName(T), White)
  Else TextAt(40, Y + 1, TypName(T), LightGray);
  HBar(260, Y, 300, 10, An.TypP[T] / Mx, PIECOL[(I - 1) Mod 8 + 1]);
  TextAt(572, Y + 2, PadL(IStr(An.TypP[T]) + ' %', 5), White);
 End;
 VTop := 0;
 DrawLinesAt(BODY_Y + 232, (STAT_Y - BODY_Y - 238) Div LINE_H);
End;

Procedure DrawJournal;
Var
 I, N, K, X, Y, W, H, Y0, B, Px, Tot : Integer;
 S : String;
 Ord : TIArr;
 Best : Array[1..10] Of Integer;
 J, M : Integer;
Begin
 GraphTitle(Tx(G_JOUR));
 If JN = 0 Then Begin
  TextAt(16, BODY_Y + 40, Tx(G_JEMPTY), LightGray);
  Exit;
 End;
 Tot := 0;
 For I := 1 To JN Do Tot := Tot + JScore[I];
 S := IStr(JN) + ' ' + Tx(G_JCOUNT) + ', ' + Tx(G_JAVG) + ' ' +
      SignStr(Round(Tot / JN));
 TextAt(16, BODY_Y + 28, S, White);
 { tonalite des derniers reves }
 SubTitle(16, BODY_Y + 46, Tx(G_JTONE));
 N := JN;
 If N > 24 Then N := 24;
 X := 40; W := 576; H := 120; Y0 := BODY_Y + 64;
 Y := Y0 + H Div 2;
 SetColor(DarkGray);
 Rectangle(X, Y0, X + W, Y0 + H);
 Line(X, Y, X + W, Y);
 TextAt(8, Y0, '+100', LightGreen);
 TextAt(8, Y0 + H - 8, '-100', LightRed);
 For I := 1 To N Do Begin
  K := JN - N + I;
  Px := X + (I - 1) * W Div N + 3;
  B := Round(JScore[K] / 100 * (H Div 2 - 2));
  If B > 0 Then Box(Px, Y - B, X + I * W Div N - 3, Y - 1, LightGreen)
  Else If B < 0 Then Box(Px, Y + 1, X + I * W Div N - 3, Y - B, LightRed)
  Else Box(Px, Y - 1, X + I * W Div N - 3, Y + 1, LightGray);
 End;
 { types de reves }
 SubTitle(16, BODY_Y + 196, Tx(G_JTYPES));
 PieOf(3, 88, BODY_Y + 296, 72, 168, BODY_Y + 230);
 { symboles favoris }
 SubTitle(424, BODY_Y + 196, Copy(Tx(G_JSYMS), 1, 25));
 For J := 1 To 10 Do Best[J] := 0;
 For I := 1 To NSYM Do
  If SymTot[I] > 0 Then Begin
   J := 1;
   While (J <= 10) And (Best[J] > 0) And (SymTot[Best[J]] >= SymTot[I]) Do
    Inc(J);
   If J <= 10 Then Begin
    For M := 10 DownTo J + 1 Do Best[M] := Best[M - 1];
    Best[J] := I;
   End;
  End;
 For J := 1 To 10 Do
  If Best[J] > 0 Then
   TextAt(424, BODY_Y + 216 + (J - 1) * 13,
          PadR(Copy(SNAME[Best[J]], 1, 18), 19) + PadL(IStr(SymTot[Best[J]]),
          3), LightGray);
End;

Procedure DrawMoon(Cx, Cy, R : Integer);
Begin
 SetFillStyle(SolidFill, Yellow);
 SetColor(Yellow);
 FillEllipse(Cx, Cy, R, R);
 SetFillStyle(SolidFill, Black);
 SetColor(Black);
 FillEllipse(Cx + R Div 2, Cy - R Div 5, R - 2, R - 2);
End;

Procedure DrawStar(X, Y, R : Integer);
Begin
 SetColor(White);
 Line(X - R, Y, X + R, Y);
 Line(X, Y - R, X, Y + R);
 SetColor(LightGray);
 Line(X - R Div 2, Y - R Div 2, X + R Div 2, Y + R Div 2);
 Line(X - R Div 2, Y + R Div 2, X + R Div 2, Y - R Div 2);
End;

Procedure DrawWelcome;
Var
 S : String;
 Y, Sz : Integer;
Begin
 DrawMoon(SCREEN_W Div 2, BODY_Y + 230, 64);
 DrawStar(SCREEN_W Div 2 + 110, BODY_Y + 180, 7);
 DrawStar(SCREEN_W Div 2 - 120, BODY_Y + 210, 5);
 DrawStar(SCREEN_W Div 2 + 70, BODY_Y + 300, 4);
 DrawStar(SCREEN_W Div 2 - 80, BODY_Y + 290, 6);
 DrawStar(SCREEN_W Div 2 + 150, BODY_Y + 250, 3);
 S := Tx(W_TITLE);
 Sz := 3;
 If Length(S) * 32 < SCREEN_W - 40 Then Sz := 4;
 SetTextStyle(DefaultFont, HorizDir, Sz);
 SetColor(Yellow);
 OutFix((SCREEN_W - Length(S) * 8 * Sz) Div 2, BODY_Y + 34, S, Sz);
 SetTextStyle(DefaultFont, HorizDir, 1);
 Y := BODY_Y + 34 + 8 * Sz + 18;
 S := Tx(W_SUB);
 TextAt((SCREEN_W - Length(S) * 8) Div 2, Y, S, LightCyan);
 S := Tx(W_KEYS);
 TextAt((SCREEN_W - Length(S) * 8) Div 2, BODY_Y + 340, S, White);
 S := Tx(W_LANGS);
 TextAt((SCREEN_W - Length(S) * 8) Div 2, BODY_Y + 362, S, LightGray);
 S := Fmt(Tx(W_DICT), IStr(NSYM), IStr(NKEY), '');
 TextAt((SCREEN_W - Length(S) * 8) Div 2, BODY_Y + 380, S, DarkGray);
End;

{ page d'accueil : ciel etoile ; autres pages : fond blanc (mode papier) }
Procedure DrawBody;
Begin
 If View = V_WELCOME Then Begin
  Box(0, BODY_Y, SCREEN_W - 1, STAT_Y - 1, Black);
  DrawStars;
  DrawWelcome;
  Exit;
 End;
 PaperMode := True;
 If View = V_EDIT Then DrawEditor
 Else Begin
  Box(0, BODY_Y, SCREEN_W - 1, STAT_Y - 1, White);
  Case View Of
   V_TONE : DrawTone;
   V_THEMES : DrawThemes;
   V_CLASS : DrawClass;
   V_JOURNAL : DrawJournal;
  Else DrawLines;
  End;
 End;
 PaperMode := False;
End;

Procedure RedrawAll;
Begin
 DrawMenuBar;
 DrawInfo;
 DrawBody;
 DrawStatus;
End;

Procedure Refresh;
Begin
 MouseOff;
 RedrawAll;
 MouseOn;
End;

{ ================================================================== }
{ Boites de dialogue                                                 }
{ ================================================================== }

{ boite de dialogue d'OS/2 : bordure epaisse, barre de titre bleue au
  titre centre, fond gris }
Procedure DlgFrame(X1, Y1, X2, Y2 : Integer; Title : String);
Begin
 Box(X1, Y1, X2, Y2, LightGray);
 Frame(X1, Y1, X2, Y2, Black);
 Bevel(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, False);
 Bevel(X1 + 3, Y1 + 3, X2 - 3, Y2 - 3, True);
 Box(X1 + 4, Y1 + 4, X2 - 4, Y1 + 18, Blue);
 TextAt((X1 + X2 - Length(Title) * 8) Div 2, Y1 + 8, Title, White);
End;

Type
 TWrapArr = Array[0..7] Of String[70];

Procedure WrapInto(S : String; W : Integer; Var L : TWrapArr;
                   Var N : Integer);
Var
 I : Integer;
 Wd2, Cur : String;
Begin
 N := 0;
 Cur := '';
 Wd2 := '';
 S := S + ' ';
 For I := 1 To Length(S) Do
  If S[I] = ' ' Then Begin
   If Wd2 <> '' Then Begin
    If Cur = '' Then Cur := Wd2
    Else If Length(Cur) + 1 + Length(Wd2) <= W Then Cur := Cur + ' ' + Wd2
    Else Begin
     If N <= 7 Then L[N] := Cur;
     Inc(N);
     Cur := Wd2;
    End;
   End;
   Wd2 := '';
  End Else Wd2 := Wd2 + S[I];
 If Cur <> '' Then Begin
  If N <= 7 Then L[N] := Cur;
  Inc(N);
 End;
 If N > 8 Then N := 8;
End;

{ Message ; si YesNo, renvoie True pour Oui }
{ Message ; si YesNo, renvoie True pour Oui (boites de message d'OS/2) }
Function AskBox(Msg : String; YesNo : Boolean) : Boolean;
Begin
 If YesNo Then
  AskBox := PmBox('Onirologie', Msg, MB_YESNO Or MB_ICONQUESTION) = MBID_YES
 Else Begin
  Dummy := PmBox('Onirologie', Msg, MB_OK Or MB_INFORMATION);
  AskBox := False;
 End;
End;

Procedure MsgBox(Msg : String);
Begin
 If AskBox(Msg, False) Then ;
End;

Const
 NFLD = 8;
 LABW = 200;

Type
 TFields = Record
  N : Integer;
  Lab : Array[1..NFLD] Of String[30];
  Val : Array[1..NFLD] Of String[40];
  Max : Array[1..NFLD] Of Integer;
  NCh : Array[1..NFLD] Of Integer;       { 0 = texte, sinon nb de choix }
  Sel : Array[1..NFLD] Of Integer;
  Opt : Array[1..NFLD, 0..5] Of String[16];
 End;

{ zones de saisie d'OS/2 (fond blanc en creux) et choix a fleches }
Procedure DrawFields(Var F : TFields; X1, Y1 : Integer; Foc : Integer);
Var
 I, Y, W : Integer;
 S : String;
Begin
 For I := 1 To F.N Do Begin
  Y := Y1 + (I - 1) * 22;
  TextAt(X1, Y + 4, F.Lab[I], Black);
  If F.NCh[I] > 0 Then Begin
   S := '< ' + F.Opt[I, F.Sel[I]] + ' >';
   W := 22 * 8;
  End Else Begin
   S := F.Val[I];
   W := F.Max[I] * 8 + 8;
  End;
  Box(X1 + LABW, Y, X1 + LABW + W, Y + 15, White);
  Bevel(X1 + LABW - 1, Y - 1, X1 + LABW + W + 1, Y + 16, True);
  SetColor(Black);
  Line(X1 + LABW, Y, X1 + LABW + W, Y);
  Line(X1 + LABW, Y, X1 + LABW, Y + 15);
  If F.NCh[I] > 0 Then
   TextAt(X1 + LABW + (W - Length(S) * 8) Div 2, Y + 4, S, Blue)
  Else TextAt(X1 + LABW + 4, Y + 4, S, Black);
  If I = Foc Then Begin
   If F.NCh[I] = 0 Then Begin
    SetColor(Black);
    Line(X1 + LABW + 4 + Length(S) * 8, Y + 2,
         X1 + LABW + 4 + Length(S) * 8, Y + 13);
   End;
   Frame(X1 + LABW - 3, Y - 3, X1 + LABW + W + 3, Y + 18, Blue);
  End;
 End;
End;

{ Saisie dans un champ ; renvoie True si la touche a ete consommee }
Function FieldKey(Var F : TFields; Foc : Integer; K : Word) : Boolean;
Begin
 FieldKey := True;
 If F.NCh[Foc] > 0 Then Begin
  If (K = 32) Or (K = 256 + 77) Then
   F.Sel[Foc] := (F.Sel[Foc] + 1) Mod F.NCh[Foc]
  Else If K = 256 + 75 Then
   F.Sel[Foc] := (F.Sel[Foc] + F.NCh[Foc] - 1) Mod F.NCh[Foc]
  Else FieldKey := False;
  Exit;
 End;
 If K = 96 Then Begin
  If Length(F.Val[Foc]) > 0 Then
   F.Val[Foc][Length(F.Val[Foc])] :=
    CycleAccent(F.Val[Foc][Length(F.Val[Foc])]);
 End Else If K = 8 Then Begin
  If Length(F.Val[Foc]) > 0 Then Delete(F.Val[Foc], Length(F.Val[Foc]), 1);
 End Else If K = 256 + 83 Then F.Val[Foc] := ''
 Else If (K >= 32) And (K < 256) And (K <> 127) Then Begin
  If Length(F.Val[Foc]) < F.Max[Foc] Then
   F.Val[Foc] := F.Val[Foc] + ToCP(Chr(K));
 End Else FieldKey := False;
End;

Function ParseDate(S : String; Var D, M, Y : Integer) : Boolean;
Var
 P, I, N : Integer;
 V : Array[1..3] Of Integer;
Begin
 ParseDate := False;
 N := 0;
 P := 1;
 While (P <= Length(S)) And (N < 3) Do Begin
  While (P <= Length(S)) And Not (S[P] In ['0'..'9']) Do Inc(P);
  If P > Length(S) Then Break;
  I := 0;
  Inc(N);
  While (P <= Length(S)) And (S[P] In ['0'..'9']) And (I < 10000) Do Begin
   I := I * 10 + Ord(S[P]) - 48;
   Inc(P);
  End;
  V[N] := I;
 End;
 If N < 3 Then Exit;
 D := V[1]; M := V[2]; Y := V[3];
 If Y < 100 Then Y := Y + 2000;
 If (M < 1) Or (M > 12) Or (Y < 1900) Or (Y > 2199) Then Exit;
 If (D < 1) Or (D > DaysInMonth(M, Y)) Then Exit;
 ParseDate := True;
End;

Procedure ChoiceField(Var F : TFields; I, Lab, Cur : Integer);
Begin
 F.Lab[I] := Tx(Lab);
 F.NCh[I] := 2;
 F.Opt[I, 0] := Tx(D_NO);
 F.Opt[I, 1] := Tx(D_YES);
 F.Sel[I] := Cur;
 F.Max[I] := 0;
 F.Val[I] := '';
End;

{ Fiche des proprietes du reve }
Function DreamDialog(Var R : TDream) : Boolean;
Var
 F : TFields;
 Foc, X1, Y1, X2, Y2, Fy, I, BtnY, N, D, M, Y : Integer;
 K : Word;
 Clk, Done, Ok : Boolean;
 Msg : String;
 L : TWrapArr;
Begin
 F.N := 7;
 For I := 1 To F.N Do F.NCh[I] := 0;
 F.Lab[1] := Tx(D_TITLE); F.Max[1] := 30; F.Val[1] := R.Title;
 F.Lab[2] := Tx(D_DATE); F.Max[2] := 10;
 F.Val[2] := DateStr(R.D, R.M, R.Y);
 F.Lab[3] := Tx(D_DREAMER); F.Max[3] := 24; F.Val[3] := R.Dreamer;
 F.Lab[4] := Tx(D_MOOD); F.NCh[4] := 5; F.Sel[4] := R.Mood;
 For I := 0 To 4 Do F.Opt[4, I] := MOODN[Lang, I];
 F.Lab[5] := Tx(D_LANG); F.NCh[5] := 6; F.Sel[5] := R.LangSel;
 For I := 0 To 5 Do F.Opt[5, I] := LANGN[Lang, I];
 ChoiceField(F, 6, D_RECUR, Ord(R.Recur));
 ChoiceField(F, 7, D_LUCID, Ord(R.Lucid));
 X1 := 60; X2 := SCREEN_W - 60;
 Y1 := 80; Y2 := 330;
 Fy := Y1 + 30;
 BtnY := Y2 - 32;
 Foc := 1;
 Msg := Tx(D_HINTDLG);
 DreamDialog := False;
 Done := False;
 Repeat
  MouseOff;
  DlgFrame(X1, Y1, X2, Y2, Tx(D_PROPS));
  DrawFields(F, X1 + 16, Fy, Foc);
  WrapInto(Msg, 62, L, N);
  For I := 0 To N - 1 Do
   TextAt(X1 + 16, Fy + F.N * 22 + 4 + I * 11, L[I], Blue);
  Button3D(X1 + 120, BtnY, X1 + 240, BtnY + 20, Tx(D_OK), False);
  Button3D(X2 - 240, BtnY, X2 - 120, BtnY + 20, Tx(D_CANCEL), False);
  MouseOn;
  Clk := WaitClickOrKey(K);
  Ok := False;
  If Clk Then Begin
   For I := 1 To F.N Do
    If InRect(MsX, MsY, X1 + 16, Fy + (I - 1) * 22, X2 - 16,
              Fy + (I - 1) * 22 + 15) Then Begin
     If (Foc = I) And (F.NCh[I] > 0) Then
      F.Sel[I] := (F.Sel[I] + 1) Mod F.NCh[I];
     Foc := I;
    End;
   If InRect(MsX, MsY, X1 + 120, BtnY, X1 + 240, BtnY + 20) Then Ok := True;
   If InRect(MsX, MsY, X2 - 240, BtnY, X2 - 120, BtnY + 20) Then Done := True;
  End Else Begin
   Case K Of
    27 : Done := True;
    9, 256 + 80 : Begin Inc(Foc); If Foc > F.N Then Foc := 1; End;
    256 + 15, 256 + 72 : Begin Dec(Foc); If Foc < 1 Then Foc := F.N; End;
    13 : If Foc = F.N Then Ok := True Else Inc(Foc);
   Else
    If FieldKey(F, Foc, K) Then ;
   End;
  End;
  If Ok Then Begin
   If Not ParseDate(F.Val[2], D, M, Y) Then Begin
    Msg := Tx(D_BADDATE);
    Foc := 2;
   End Else Begin
    R.Title := Trim(F.Val[1]);
    R.D := D; R.M := M; R.Y := Y;
    R.Dreamer := Trim(F.Val[3]);
    R.Mood := F.Sel[4];
    R.LangSel := F.Sel[5];
    R.Recur := F.Sel[6] = 1;
    R.Lucid := F.Sel[7] = 1;
    DreamDialog := True;
    Done := True;
   End;
  End;
 Until Done;
End;

{ Saisie d'une ligne de texte }
Function InputBox(Title, Lab : String; Var S : String; Max : Integer)
 : Boolean;
Var
 F : TFields;
 K : Word;
 Clk, Done : Boolean;
 X1, Y1, X2, Y2 : Integer;
Begin
 F.N := 1;
 F.NCh[1] := 0;
 F.Lab[1] := Lab; F.Max[1] := Max; F.Val[1] := S;
 X1 := 70; X2 := SCREEN_W - 70; Y1 := 170; Y2 := 270;
 InputBox := False;
 Done := False;
 Repeat
  MouseOff;
  DlgFrame(X1, Y1, X2, Y2, Title);
  DrawFields(F, X1 + 16, Y1 + 32, 1);
  Button3D(X1 + 100, Y2 - 32, X1 + 200, Y2 - 12, Tx(D_OK), True);
  Button3D(X2 - 200, Y2 - 32, X2 - 100, Y2 - 12, Tx(D_CANCEL), False);
  MouseOn;
  Clk := WaitClickOrKey(K);
  If Clk Then Begin
   If InRect(MsX, MsY, X1 + 100, Y2 - 32, X1 + 200, Y2 - 12) Then Begin
    InputBox := True; Done := True;
   End;
   If InRect(MsX, MsY, X2 - 200, Y2 - 32, X2 - 100, Y2 - 12) Then Done := True;
  End Else If K = 27 Then Done := True
  Else If K = 13 Then Begin InputBox := True; Done := True; End
  Else If FieldKey(F, 1, K) Then ;
 Until Done;
 S := Trim(F.Val[1]);
End;

Const
 MAXLI = 500;

Var
 LItem : Array[1..MAXLI] Of String[64];

{ Liste a choix ; renvoie 0 (annule), 1 (choisi) ou 2 (supprimer) }
Function ListDialog(Title : String; N : Integer; Var Sel : Integer;
                    AllowDel : Boolean) : Integer;
Var
 X1, Y1, X2, Y2, Top, I, Y, Vis : Integer;
 K : Word;
 Clk, Done : Boolean;
Begin
 ListDialog := 0;
 X1 := 90; X2 := SCREEN_W - 90; Y1 := 60; Y2 := 430;
 Vis := 22;
 If Sel < 1 Then Sel := 1;
 If Sel > N Then Sel := N;
 Top := 1;
 Done := False;
 If N = 0 Then Begin
  MsgBox(Tx(D_EMPTY));
  Exit;
 End;
 Repeat
  If Sel < Top Then Top := Sel;
  If Sel >= Top + Vis Then Top := Sel - Vis + 1;
  MouseOff;
  DlgFrame(X1, Y1, X2, Y2, Title);
  Box(X1 + 10, Y1 + 24, X2 - 10, Y1 + 24 + Vis * 13 + 4, White);
  Bevel(X1 + 9, Y1 + 23, X2 - 9, Y1 + 25 + Vis * 13 + 4, True);
  For I := Top To Top + Vis - 1 Do
   If I <= N Then Begin
    Y := Y1 + 26 + (I - Top) * 13;
    If I = Sel Then Begin
     Box(X1 + 11, Y, X2 - 11, Y + 12, Blue);
     TextAt(X1 + 16, Y + 2, Copy(LItem[I], 1, 54), White);
    End Else TextAt(X1 + 16, Y + 2, Copy(LItem[I], 1, 54), Black);
   End;
  Button3D(X1 + 20, Y2 - 30, X1 + 120, Y2 - 10, Tx(D_OK), False);
  If AllowDel Then
   Button3D(X1 + 150, Y2 - 30, X1 + 270, Y2 - 10, Tx(D_DELETE), False);
  Button3D(X2 - 120, Y2 - 30, X2 - 20, Y2 - 10, Tx(D_CANCEL), False);
  MouseOn;
  Clk := WaitClickOrKey(K);
  If Clk Then Begin
   If InRect(MsX, MsY, X1 + 10, Y1 + 26, X2 - 10, Y1 + 26 + Vis * 13) Then
   Begin
    I := Top + (MsY - Y1 - 26) Div 13;
    If I <= N Then Begin
     If I = Sel Then Begin ListDialog := 1; Done := True; End;
     Sel := I;
    End;
   End;
   If InRect(MsX, MsY, X1 + 20, Y2 - 30, X1 + 120, Y2 - 10) Then Begin
    ListDialog := 1; Done := True;
   End;
   If AllowDel And InRect(MsX, MsY, X1 + 150, Y2 - 30, X1 + 270, Y2 - 10)
   Then Begin
    ListDialog := 2; Done := True;
   End;
   If InRect(MsX, MsY, X2 - 120, Y2 - 30, X2 - 20, Y2 - 10) Then Done := True;
  End Else
   Case K Of
    27 : Done := True;
    13 : Begin ListDialog := 1; Done := True; End;
    256 + 72 : If Sel > 1 Then Dec(Sel);
    256 + 80 : If Sel < N Then Inc(Sel);
    256 + 73 : Begin Sel := Sel - Vis; If Sel < 1 Then Sel := 1; End;
    256 + 81 : Begin Sel := Sel + Vis; If Sel > N Then Sel := N; End;
    256 + 71 : Sel := 1;
    256 + 79 : Sel := N;
    256 + 83 : If AllowDel Then Begin ListDialog := 2; Done := True; End;
   End;
 Until Done;
End;


{ ================================================================== }
{ Construction des pages                                             }
{ ================================================================== }

Var
 CatLine : Array[1..NCAT] Of Integer;
 PrevTop : Integer;

Function LowFirst(S : String) : String;
Begin
 If (Length(S) > 0) And (S[1] >= 'A') And (S[1] <= 'Z') Then
  S[1] := Chr(Ord(S[1]) + 32);
 LowFirst := S;
End;

Function PolStr(P : Integer) : String;
Begin
 Case P Of
  -2 : PolStr := '--';
  -1 : PolStr := '-';
  1 : PolStr := '+';
  2 : PolStr := '++';
 Else PolStr := '=';
 End;
End;

Function PolCol(P : Integer) : Integer;
Begin
 If P > 0 Then PolCol := LightGreen
 Else If P < 0 Then PolCol := LightRed
 Else PolCol := LightGray;
End;

Function DreamTitle : String;
Begin
 If Dream.Title <> '' Then DreamTitle := Dream.Title
 Else DreamTitle := Tx(I_UNTITLED);
End;

Procedure VLabel(L, V : String; C : Integer);
Begin
 VAdd(PadR(L, 22) + ': ' + V, C, 0, 1, 0);
End;

{ Ligne d'une repartition en pourcentage avec barre textuelle }
Procedure VPctLine(S : String; V, T : Real; C : Integer);
Var
 N : Integer;
 B : String;
Begin
 If T > 0 Then N := Round(30 * V / T) Else N := 0;
 B := '';
 While Length(B) < N Do B := B + #254;
 VAdd(PadR(Copy(S, 1, 28), 29) + PadL(PctStr(V, T), 6) + '  ' + B, C, 0,
      2, 0);
End;

Procedure SenseText;
Var
 C, C2, T, T2, H, I, S, N, A : Integer;
 L : String;
Begin
 If (An.NHit = 0) And (An.NEmoW = 0) Then Begin
  VBlock(B_NOSYM, White, 1);
  Exit;
 End;
 WrapStart(White, 1);
 WrapBlock(B_TONE + An.ToneC - 1);
 If An.EmoT > 0 Then WrapBlock(B_EMOS + An.EmoO[1] - 1);
 WrapFlush;
 If An.CatT > 0 Then Begin
  VBlank;
  C := An.CatO[1];
  C2 := An.CatO[2];
  WrapStart(White, 1);
  WrapWords('Le thäme dominant est Æ ' + CATN[0, C] + ' Ø (' +
            PctStr(An.Cat[C], An.CatT) + ').');
  WrapBlock(B_CATS + C - 1);
  If (An.Cat[C2] > 0) And (An.Cat[C2] >= 0.6 * An.Cat[C]) Then
   WrapWords('Il se double du thäme Æ ' + CATN[0, C2] + ' Ø (' +
             PctStr(An.Cat[C2], An.CatT) + ').');
  WrapBlock(B_DOMS + An.DomO[1] - 1);
  WrapFlush;
 End;
 N := An.NHit;
 If N > 3 Then N := 3;
 If N > 0 Then Begin
  VBlank;
  WrapStart(White, 1);
  If N = 1 Then L := 'Le symbole clÇ est ' Else L := 'Les symboles clÇs sont ';
  For I := 1 To N Do Begin
   S := An.Hit[An.HitO[I]].Sym;
   If I = 1 Then L := L + 'Æ ' + SNAME[S] + ' Ø'
   Else If I = N Then L := L + ' et Æ ' + SNAME[S] + ' Ø'
   Else L := L + ', Æ ' + SNAME[S] + ' Ø';
  End;
  WrapWords(L + '.');
  WrapFlush;
  For I := 1 To N Do Begin
   H := An.HitO[I];
   S := An.Hit[H].Sym;
   WrapStart(LightGray, 3);
   WrapWords('Æ ' + SNAME[S] + ' Ø :');
   WrapBlock(B_SMEAN + S - 1);
   Case HitTone(H) Of
    1 : WrapBlock(B_SPOS + S - 1);
    -1 : WrapBlock(B_SNEG + S - 1);
   End;
   WrapFlush;
  End;
 End;
 VBlank;
 T := An.TypO[1];
 T2 := An.TypO[2];
 WrapStart(White, 1);
 WrapWords('Par sa nature, ce ràve s''apparente Ö un ' +
           LowFirst(TYPN[0, T]) + ' ;');
 WrapBlock(B_TYPS + T - 1);
 If (An.TypP[T2] > 0) And (An.TypP[T2] >= 0.7 * An.TypP[T]) Then
  WrapWords('Il emprunte aussi au ' + LowFirst(TYPN[0, T2]) + '.');
 If An.NW >= 30 Then WrapBlock(B_EVOL + An.Evol - 1);
 WrapFlush;
 If An.ArcT > 0 Then Begin
  VBlank;
  A := An.ArcO[1];
  WrapStart(White, 1);
  WrapWords('ArchÇtype marquant : ' + ARCN[0, A] + '.');
  WrapBlock(B_ARCD + A - 1);
  WrapFlush;
 End;
 I := 0;
 If Dream.Mood <> 2 Then Begin
  If (Dream.Mood <= 1) And (An.Score >= 12) Then I := 2
  Else If (Dream.Mood >= 3) And (An.Score <= -12) Then I := 3
  Else If ((Dream.Mood <= 1) And (An.Score < 0)) Or
          ((Dream.Mood >= 3) And (An.Score > 0)) Then I := 1;
 End;
 If I > 0 Then Begin
  VBlank;
  VBlock(B_MOOD + I - 1, White, 1);
 End;
 If An.CatT > 0 Then Begin
  VBlank;
  WrapStart(LightCyan, 1);
  WrapWords('Conseil :');
  WrapBlock(B_CATA + An.CatO[1] - 1);
  WrapFlush;
 End;
 VBlank;
 VBlock(B_CONCL, DarkGray, 1);
End;

Procedure BuildHeader;
Var
 S : String;
Begin
 S := Tx(R_DATE) + ' : ' + DateStr(Dream.D, Dream.M, Dream.Y);
 If Dream.Dreamer <> '' Then
  S := S + '    ' + Tx(R_DREAMER) + ' : ' + Dream.Dreamer;
 VAdd(S, White, 0, 1, 0);
 S := Tx(R_LANG) + ' : ' + LANGN[Lang, An.Lg + 1];
 If Dream.LangSel = 0 Then S := S + ' ' + Tx(R_DETECT);
 VAdd(S, White, 0, 1, 0);
 VAdd(Tx(R_LEN) + ' : ' + IStr(An.NW) + ' ' + Tx(I_WORDS) + ', ' +
      IStr(An.NSent) + ' ' + Tx(R_SENTS) + ', ' + IStr(An.NHit) + ' ' +
      Tx(I_SYMS) + ', ' + IStr(An.NEmoW) + ' ' + Tx(R_EMOW), White, 0, 1, 0);
 VAdd(Tx(R_MOOD) + ' : ' + MOODN[Lang, Dream.Mood] + '    ' + Tx(R_RECUR) +
      ' : ' + YesNo(Dream.Recur) + '    ' + Tx(R_LUCID) + ' : ' +
      YesNo(Dream.Lucid), White, 0, 1, 0);
End;

Procedure ToneLines;
Var
 S : String;
 I, E : Integer;
 T : Real;
Begin
 T := An.PosN + An.NegN + An.NeuN;
 VAdd(Tx(R_SCORE) + ' : ' + SignStr(An.Score) + ' (' + TONEN[Lang, An.ToneC]
      + ')', PolCol(An.Score), 0, 1, 0);
 VAdd(Tx(R_POS) + ' ' + PctStr(An.PosN, T) + '   ' + Tx(R_NEG) + ' ' +
      PctStr(An.NegN, T) + '   ' + Tx(R_NEU) + ' ' + PctStr(An.NeuN, T),
      LightGray, 0, 1, 0);
 If An.EmoT > 0 Then Begin
  S := Tx(R_DOMEMO) + ' : ';
  For I := 1 To 3 Do Begin
   E := An.EmoO[I];
   If An.Emo[E] > 0 Then Begin
    If I > 1 Then S := S + ', ';
    S := S + EmoName(E) + ' ' + PctStr(An.Emo[E], An.EmoT);
   End;
  End;
  VAdd(S, LightGray, 0, 1, 0);
 End Else VAdd(Tx(R_NOEMO), LightGray, 0, 1, 0);
 If An.NW >= 30 Then Begin
  WrapStart(LightGray, 1);
  WrapWords(Tx(R_EVOL) + ' :');
  WrapBlock(B_EVOL + An.Evol - 1);
  WrapFlush;
 End;
End;

Procedure BuildReport;
Var
 I, H, S, N, A, J : Integer;
 L : String;
Begin
 VTitle(Tx(R_TITLE) + ' : ' + DreamTitle);
 If EdEmpty Then Begin
  VText(Tx(D_NOTEXT), White, 1);
  Exit;
 End;
 EnsureAnal;
 BuildHeader;
 VSect(Tx(R_TONE));
 ToneLines;
 VSect(Tx(R_SYMS));
 N := An.NHit;
 If N > 40 Then N := 40;
 If N = 0 Then VBlock(B_NOSYM, LightGray, 1);
 For I := 1 To N Do Begin
  H := An.HitO[I];
  S := An.Hit[H].Sym;
  VAdd(#16' ' + SNAME[S] + ' (' + IStr(An.Hit[H].Cnt) + 'x) - ' +
       CatName(SCAT[S]) + '  ' + PolStr(SPOL[S]), Yellow, 0, 1, 1000 + S);
  VBlock(B_SMEAN + S - 1, LightGray, 3);
  Case HitTone(H) Of
   1 : VBlock(B_SPOS + S - 1, LightGreen, 3);
   -1 : VBlock(B_SNEG + S - 1, LightRed, 3);
  End;
 End;
 If An.CatT > 0 Then Begin
  VSect(Tx(R_THEMES));
  For I := 1 To 6 Do
   If An.Cat[An.CatO[I]] > 0 Then
    VPctLine(CatName(An.CatO[I]), An.Cat[An.CatO[I]], An.CatT, PIECOL[I]);
  VSect(Tx(R_DOMAINS));
  For I := 1 To 4 Do
   If An.Dom[An.DomO[I]] > 0 Then
    VPctLine(DomName(An.DomO[I]), An.Dom[An.DomO[I]], An.DomT, PIECOL[I]);
 End;
 VSect(Tx(R_CLASS));
 For I := 1 To 3 Do
  VAdd(IStr(I) + '. ' + PadR(TypName(An.TypO[I]), 28) +
       PadL(IStr(An.TypP[An.TypO[I]]) + ' %', 6), White, 0, 2, 0);
 VSect(Tx(R_ARCH));
 If An.ArcT = 0 Then VAdd(Tx(R_NOARCH), LightGray, 0, 2, 0);
 For I := 1 To NARC Do Begin
  A := An.ArcO[I];
  If An.Arc[A] > 0 Then Begin
   L := ArcName(A) + ' :';
   For J := 1 To An.NHit Do
    If SARC[An.Hit[J].Sym] = A Then
     L := L + ' ' + SNAME[An.Hit[J].Sym] + ',';
   If L[Length(L)] = ',' Then Delete(L, Length(L), 1);
   VText(L, LightGray, 2);
  End;
 End;
 VSect(Tx(R_SENSE));
 SenseText;
 If Lang <> 0 Then Begin
  VBlank;
  VText(Tx(R_FRONLY), DarkGray, 1);
 End;
End;

Procedure BuildSyms;
Var
 I, H, S : Integer;
Begin
 VTitle(Tx(R_SYMS) + ' : ' + DreamTitle);
 If An.NHit = 0 Then Begin
  VBlock(B_NOSYM, LightGray, 1);
  Exit;
 End;
 VAdd(PadR(Tx(R_SYMS), 26) + PadR(Tx(R_CATEG), 28) + 'Nb  ' +
      Copy(Tx(R_POLAR), 1, 6), LightCyan, 0, 1, 0);
 For I := 1 To An.NHit Do Begin
  H := An.HitO[I];
  S := An.Hit[H].Sym;
  VAdd(PadR(SNAME[S], 26) + PadR(Copy(CatName(SCAT[S]), 1, 27), 28) +
       PadL(IStr(An.Hit[H].Cnt), 2) + '  ' + PolStr(SPOL[S]),
       PolCol(SPOL[S]), 0, 1, 1000 + S);
 End;
End;

Procedure BuildArch;
Var
 I, J, A : Integer;
 L : String;
Begin
 VTitle(Tx(R_ARCH) + ' : ' + DreamTitle);
 If An.ArcT = 0 Then VAdd(Tx(R_NOARCH), LightGray, 0, 1, 0);
 For I := 1 To NARC Do Begin
  A := An.ArcO[I];
  If An.Arc[A] > 0 Then Begin
   VAdd(ArcName(A) + '  (' + PctStr(An.Arc[A], An.ArcT) + ')', Yellow, 0, 1,
        0);
   L := '';
   For J := 1 To An.NHit Do
    If SARC[An.Hit[J].Sym] = A Then Begin
     If L <> '' Then L := L + ', ';
     L := L + SNAME[An.Hit[J].Sym];
    End;
   VText(L, LightCyan, 3);
   VBlock(B_ARCD + A - 1, LightGray, 3);
   VBlank;
  End;
 End;
End;

Procedure BuildSense;
Begin
 VTitle(Tx(R_SENSE) + ' : ' + DreamTitle);
 If EdEmpty Then Begin
  VText(Tx(D_NOTEXT), White, 1);
  Exit;
 End;
 EnsureAnal;
 SenseText;
 If Lang <> 0 Then Begin
  VBlank;
  VText(Tx(R_FRONLY), DarkGray, 1);
 End;
End;

Procedure BuildClassText;
Var
 T : Integer;
Begin
 T := An.TypO[1];
 VAdd(TypName(T), Yellow, 0, 1, 0);
 VBlock(B_TYPD + T - 1, LightGray, 1);
 T := An.TypO[2];
 If An.TypP[T] > 0 Then Begin
  VAdd(TypName(T), Yellow, 0, 1, 0);
  VBlock(B_TYPD + T - 1, LightGray, 1);
 End;
End;

Procedure BuildDict;
Var
 C, S : Integer;
Begin
 VTitle(Tx(X_DICT) + ' (' + IStr(NSYM) + ')');
 For C := 1 To NCAT Do Begin
  CatLine[C] := VLN + 1;
  VAdd(CatName(C), LightCyan, 0, 0, 0);
  For S := 1 To NSYM Do
   If SCAT[S] = C Then
    VAdd(PadR(SNAME[S], 28) + PolStr(SPOL[S]), PolCol(SPOL[S]), 0, 2,
         1000 + S);
 End;
End;

Function KeysOf(S, L : Integer) : String;
Var
 K : Integer;
 R : String;
Begin
 R := '';
 For K := KST[L, 0] To KST[L, 27] - 1 Do
  If (KTAR[K] = S) And (Length(R) + Length(KeysStr(K)) < 250) Then Begin
   If R <> '' Then R := R + ', ';
   R := R + LoStr(KeysStr(K));
  End;
 KeysOf := R;
End;

Procedure BuildSymDet(S : Integer);
Var
 L, H : Integer;
 D : String;
Begin
 VTitle(SNAME[S]);
 VLabel(Tx(R_CATEG), CatName(SCAT[S]), White);
 D := DomName(SDOM[S] Div 10);
 If SDOM[S] Mod 10 > 0 Then D := D + ', ' + DomName(SDOM[S] Mod 10);
 VLabel(Tx(R_DOMAIN), D, White);
 VLabel(Tx(R_POLAR), SignStr(SPOL[S]) + ' ' + PolStr(SPOL[S]),
        PolCol(SPOL[S]));
 If SARC[S] > 0 Then VLabel(Tx(R_ARCHL), ArcName(SARC[S]), White);
 If STYP[S] > 0 Then VLabel(Tx(R_TYPEL), TypName(STYP[S]), White);
 H := HitOf(S);
 If (Not EDirty) And (H > 0) Then
  VLabel(Tx(R_SYMS), IStr(An.Hit[H].Cnt) + ' ' + Tx(R_OCC), Yellow);
 VBlank;
 VBlock(B_SMEAN + S - 1, White, 1);
 VSect(Tx(R_IFPOS));
 VBlock(B_SPOS + S - 1, LightGreen, 1);
 VSect(Tx(R_IFNEG));
 VBlock(B_SNEG + S - 1, LightRed, 1);
 VSect(Tx(R_KEYS));
 For L := 0 To 4 Do Begin
  WrapStart(LightGray, 1);
  WrapWords(LANGN[Lang, L + 1] + ' :');
  WrapWords(KeysOf(S, L));
  WrapFlush;
 End;
End;

Procedure BuildGuide;
Var
 I : Integer;
Begin
 VTitle(StripAmp(Tx(M_GUIDE)));
 For I := 1 To NHELP Do Begin
  VBlock(B_HELP + Lang * NHELP + I - 1, White, 1);
  VBlank;
 End;
End;

Procedure BuildView;
Begin
 VClear;
 If (View <> V_WELCOME) And (View <> V_EDIT) And (View <> V_DICT) And
    (View <> V_SYMDET) And (View <> V_GUIDE) And (View <> V_JOURNAL) Then
  EnsureAnal;
 Case View Of
  V_REPORT : BuildReport;
  V_SYMS : BuildSyms;
  V_ARCH : BuildArch;
  V_SENSE : BuildSense;
  V_CLASS : BuildClassText;
  V_DICT : BuildDict;
  V_SYMDET : BuildSymDet(ViewArg);
  V_GUIDE : BuildGuide;
 End;
 Case View Of
  V_WELCOME, V_EDIT : StatusMsg := '';
  V_TONE, V_THEMES, V_CLASS, V_JOURNAL : StatusMsg := Tx(S_GRAPH);
  V_REPORT, V_SYMS, V_DICT : StatusMsg := Tx(S_CLICK);
 Else
  StatusMsg := Tx(S_SCROLL);
 End;
End;

Procedure SetView(V, Arg : Integer);
Begin
 If (V = V_SYMDET) And (View <> V_SYMDET) Then Begin
  PrevView := View;
  PrevTop := VTop;
 End;
 View := V;
 ViewArg := Arg;
 BuildView;
 If (V = V_DICT) And (Arg >= 1) And (Arg <= NCAT) Then Begin
  VTop := CatLine[Arg] - 1;
  If VTop > VLN - VIS_LINES Then VTop := VLN - VIS_LINES;
  If VTop < 0 Then VTop := 0;
 End;
 Refresh;
End;

Procedure GoBack;
Var
 T : Integer;
Begin
 If View = V_SYMDET Then Begin
  T := PrevTop;
  View := PrevView;
  BuildView;
  VTop := T;
  Refresh;
 End Else SetView(V_EDIT, 0);
End;

{ ================================================================== }
{ Journal des reves                                                  }
{ ================================================================== }

Var
 EBak : Array[1..MAXEL] Of String[200];
 EBakS : Array[1..MAXEL] Of Byte;
 BakN, BakX, BakY, BakTop : Integer;
 BakDream : TDream;
 BakMod : Boolean;

Procedure DefaultDream;
Var
 Yy, Mm, Dd, Dw : Word;
Begin
 GetDate(Yy, Mm, Dd, Dw);
 Dream.Title := '';
 Dream.D := Dd; Dream.M := Mm; Dream.Y := Yy;
 Dream.Mood := 2;
 Dream.LangSel := 0;
 Dream.Recur := False;
 Dream.Lucid := False;
End;

Procedure SaveState;
Var
 I : Integer;
Begin
 For I := 1 To EN Do Begin
  EBak[I] := EL[I];
  EBakS[I] := ES[I];
 End;
 BakN := EN; BakX := ECX; BakY := ECY; BakTop := ETop;
 BakDream := Dream;
 BakMod := EMod;
End;

Procedure RestoreState;
Var
 I : Integer;
Begin
 For I := 1 To BakN Do Begin
  EL[I] := EBak[I];
  ES[I] := EBakS[I];
 End;
 EN := BakN; ECX := BakX; ECY := BakY; ETop := BakTop;
 Dream := BakDream;
 EMod := BakMod;
 EDirty := True;
End;

Procedure WriteDream(Var F : Text);
Var
 I : Integer;
Begin
 WriteLn(F, '#REVE');
 WriteLn(F, 'T:', Dream.Title);
 WriteLn(F, 'D:', DateStr(Dream.D, Dream.M, Dream.Y));
 WriteLn(F, 'P:', Dream.Dreamer);
 WriteLn(F, 'H:', Dream.Mood);
 WriteLn(F, 'G:', Dream.LangSel);
 WriteLn(F, 'R:', Ord(Dream.Recur));
 WriteLn(F, 'L:', Ord(Dream.Lucid));
 For I := 1 To EN Do WriteLn(F, 'X', ES[I], EL[I]);
 WriteLn(F, '#FIN');
End;

{ Lit un reve ; la ligne #REVE vient d'etre lue }
Procedure ReadDream(Var F : Text);
Var
 S, T : String;
 D, M, Y : Integer;
Begin
 DefaultDream;
 Dream.Dreamer := '';
 EN := 0;
 While Not Eof(F) Do Begin
  ReadLn(F, S);
  If S = '#FIN' Then Break;
  T := Copy(S, 1, 2);
  If T = 'T:' Then Dream.Title := Copy(S, 3, 40)
  Else If T = 'D:' Then Begin
   If ParseDate(Copy(S, 3, 20), D, M, Y) Then Begin
    Dream.D := D; Dream.M := M; Dream.Y := Y;
   End;
  End
  Else If T = 'P:' Then Dream.Dreamer := Copy(S, 3, 24)
  Else If T = 'H:' Then Dream.Mood := ValI(Copy(S, 3, 5)) Mod 5
  Else If T = 'G:' Then Dream.LangSel := ValI(Copy(S, 3, 5)) Mod 6
  Else If T = 'R:' Then Dream.Recur := Copy(S, 3, 1) = '1'
  Else If T = 'L:' Then Dream.Lucid := Copy(S, 3, 1) = '1'
  Else If (Length(S) >= 2) And (S[1] = 'X') And (EN < MAXEL) Then Begin
   Inc(EN);
   ES[EN] := Ord(S[2]) - 48;
   If ES[EN] > 2 Then ES[EN] := 0;
   EL[EN] := Copy(S, 3, 200);
  End;
 End;
 If Dream.Mood < 0 Then Dream.Mood := 2;
 If EN = 0 Then Begin
  EN := 1;
  EL[1] := '';
 End;
 ES[EN] := 0;
 ECX := 1; ECY := 1; ETop := 0;
 EDirty := True;
 EMod := False;
End;

Function OpenJnl(Var F : Text) : Boolean;
Begin
 Assign(F, JNLFILE);
 {$I-}
 Reset(F);
 {$I+}
 OpenJnl := IOResult = 0;
End;

Procedure JScan;
Var
 F : Text;
 S : String;
Begin
 JN := 0;
 If Not OpenJnl(F) Then Exit;
 While Not Eof(F) Do Begin
  ReadLn(F, S);
  If (S = '#REVE') And (JN < MAXJ) Then Begin
   Inc(JN);
   JTitle[JN] := '';
   JDate[JN] := '';
  End Else If JN > 0 Then Begin
   If Copy(S, 1, 2) = 'T:' Then JTitle[JN] := Copy(S, 3, 40)
   Else If Copy(S, 1, 2) = 'D:' Then JDate[JN] := Copy(S, 3, 10);
  End;
 End;
 Close(F);
End;

Function JLoad(K : Integer) : Boolean;
Var
 F : Text;
 S : String;
 N : Integer;
Begin
 JLoad := False;
 If Not OpenJnl(F) Then Exit;
 N := 0;
 While Not Eof(F) Do Begin
  ReadLn(F, S);
  If S = '#REVE' Then Begin
   Inc(N);
   If N = K Then Begin
    ReadDream(F);
    JLoad := True;
    Break;
   End;
  End;
 End;
 Close(F);
End;

{ Mode 0 : remplace le reve K, 1 : supprime K, 2 : ajoute a la fin }
Function JRewrite(K, Mode : Integer) : Boolean;
Var
 Fi, Fo : Text;
 S : String;
 N : Integer;
 Skip, HasIn : Boolean;
Begin
 JRewrite := False;
 HasIn := OpenJnl(Fi);
 Assign(Fo, TMPFILE);
 {$I-}
 Rewrite(Fo);
 {$I+}
 If IOResult <> 0 Then Begin
  If HasIn Then Close(Fi);
  Exit;
 End;
 N := 0;
 Skip := False;
 If HasIn Then Begin
  While Not Eof(Fi) Do Begin
   ReadLn(Fi, S);
   If S = '#REVE' Then Begin
    Inc(N);
    Skip := N = K;
    If Skip And (Mode = 0) Then WriteDream(Fo);
   End;
   If Not Skip Then WriteLn(Fo, S);
   If S = '#FIN' Then Skip := False;
  End;
  Close(Fi);
 End;
 If Mode = 2 Then WriteDream(Fo);
 Close(Fo);
 {$I-}
 If HasIn Then Begin
  Assign(Fi, JNLFILE);
  Erase(Fi);
 End;
 If IOResult <> 0 Then Exit;
 Rename(Fo, JNLFILE);
 {$I+}
 JRewrite := IOResult = 0;
End;

Procedure JItems;
Var
 I : Integer;
Begin
 For I := 1 To JN Do
  If I <= MAXLI Then
   LItem[I] := PadR(JDate[I], 12) + Copy(JTitle[I], 1, 40);
End;

{ Statistiques : analyse de chaque reve du journal }
Procedure JStats;
Var
 F : Text;
 S : String;
 I, K : Integer;
Begin
 SaveState;
 For I := 1 To NSYM Do SymTot[I] := 0;
 For I := 1 To 20 Do TypTot[I] := 0;
 JN := 0;
 If OpenJnl(F) Then Begin
  While Not Eof(F) Do Begin
   ReadLn(F, S);
   If (S = '#REVE') And (JN < MAXJ) Then Begin
    ReadDream(F);
    Analyze;
    Inc(JN);
    JTitle[JN] := Dream.Title;
    JDate[JN] := DateStr(Dream.D, Dream.M, Dream.Y);
    JScore[JN] := An.Score;
    K := An.TypO[1];
    JTyp[JN] := K;
    TypTot[K] := TypTot[K] + 1;
    For I := 1 To An.NHit Do Inc(SymTot[An.Hit[I].Sym]);
   End;
  End;
  Close(F);
 End;
 RestoreState;
End;

Function ConfirmLoss(Id : Integer) : Boolean;
Begin
 If EMod And Not EdEmpty Then ConfirmLoss := AskBox(Tx(Id), True)
 Else ConfirmLoss := True;
End;

Procedure SaveDream;
Begin
 If EdEmpty Then Begin
  MsgBox(Tx(D_NOTEXT));
  Exit;
 End;
 If Dream.Title = '' Then
  Dream.Title := Tx(D_DEFTITLE) + ' ' + DateStr(Dream.D, Dream.M, Dream.Y);
 JScan;
 If (JIdx > 0) And (JIdx <= JN) Then Begin
  If Not JRewrite(JIdx, 0) Then Begin MsgBox(Tx(D_IOERR)); Exit; End;
 End Else Begin
  If Not JRewrite(0, 2) Then Begin MsgBox(Tx(D_IOERR)); Exit; End;
  JIdx := JN + 1;
 End;
 EMod := False;
 StatusMsg := Tx(D_SAVED);
 Refresh;
 MsgBox(Tx(D_SAVED));
End;

Procedure OpenJournal;
Var
 Sel, R : Integer;
Begin
 JScan;
 JItems;
 Sel := JN;
 R := ListDialog(Tx(D_JOURNAL), JN, Sel, True);
 If R = 1 Then Begin
  If Not ConfirmLoss(D_CONFNEW) Then Begin Refresh; Exit; End;
  If JLoad(Sel) Then Begin
   JIdx := Sel;
   SetView(V_EDIT, 0);
  End Else MsgBox(Tx(D_IOERR));
 End Else If R = 2 Then Begin
  If AskBox(Tx(D_CONFDEL), True) Then Begin
   If Not JRewrite(Sel, 1) Then MsgBox(Tx(D_IOERR))
   Else If JIdx = Sel Then Begin JIdx := 0; EMod := True; End
   Else If JIdx > Sel Then Dec(JIdx);
  End;
  Refresh;
 End Else Refresh;
End;

{ ================================================================== }
{ Fichiers texte                                                     }
{ ================================================================== }

{ Ajoute un morceau de texte au paragraphe en cours }
Procedure AddChunk(T : String; Var First, Para, NewLine : Boolean);
Begin
 If Not Para Then Begin
  If First Then EL[1] := T
  Else If EN < MAXEL - 2 Then EdInsLine(EN + 1, T, 0)
  Else Exit;
 End Else If NewLine Then EL[EN] := EL[EN] + ' ' + T
 Else EL[EN] := EL[EN] + T;
 ES[EN] := 0;
 First := False;
 Para := True;
 NewLine := False;
 ReflowPara(ParaStart(EN));
End;

{ Lit un fichier texte (UTF-8, Latin-1 ou CP437) ; les lignes non
  vides consecutives forment un paragraphe }
Function LoadTextFile(Name : String) : Boolean;
Var
 F : Text;
 S : String[100];
 C : Char;
 T : String;
 First, Para, NewLine, Blank : Boolean;
 K, Need : Integer;
Begin
 LoadTextFile := False;
 Assign(F, Name);
 {$I-}
 Reset(F);
 {$I+}
 If IOResult <> 0 Then Exit;
 EdClear;
 First := True;
 Para := False;
 While Not Eof(F) Do Begin
  NewLine := True;
  Blank := True;
  While Not Eoln(F) Do Begin
   Read(F, S);
   { ne pas couper un caractere UTF-8 multi-octets }
   K := Length(S);
   While (K > 0) And (K > Length(S) - 3) And (Ord(S[K]) >= $80) And
         (Ord(S[K]) < $C0) Do Dec(K);
   If (K > 0) And (Ord(S[K]) >= $C0) Then Begin
    If Ord(S[K]) >= $F0 Then Need := 3
    Else If Ord(S[K]) >= $E0 Then Need := 2
    Else Need := 1;
    Need := Need - (Length(S) - K);
    T := S;
    While (Need > 0) And Not Eoln(F) Do Begin
     Read(F, C);
     T := T + C;
     Dec(Need);
    End;
   End Else T := S;
   While (Length(T) > 0) And (T[Length(T)] = #13) Do Delete(T, Length(T), 1);
   T := LineToCP(T);
   If Trim(T) <> '' Then Begin
    If Blank And NewLine Then
     While (Length(T) > 0) And (T[1] = ' ') Do Delete(T, 1, 1);
    Blank := False;
    AddChunk(T, First, Para, NewLine);
   End;
  End;
  ReadLn(F);
  If Blank And Para Then Begin
   { ligne vide : fin de paragraphe }
   If EN < MAXEL - 2 Then EdInsLine(EN + 1, '', 0);
   Para := False;
   First := False;
  End;
 End;
 Close(F);
 While (EN > 1) And (EL[EN] = '') Do Dec(EN);
 ES[EN] := 0;
 ECX := 1; ECY := 1; ETop := 0;
 EDirty := True;
 LoadTextFile := True;
End;

Procedure LoadSample;
Var
 I : Integer;
Begin
 EdClear;
 EN := 0;
 For I := SAMPIX[Lang] To SAMPIX[Lang + 1] - 1 Do Begin
  Inc(EN);
  ES[EN] := Ord(SAMP[I][1]) - 48;
  EL[EN] := Copy(SAMP[I], 2, 200);
 End;
 If EN = 0 Then EdClear;
 ES[EN] := 0;
 DefaultDream;
 Dream.Title := StripAmp(Tx(M_SAMPLE));
 Dream.Mood := 3;
 JIdx := 0;
 EMod := True;
 EDirty := True;
End;

Function ExportReport(Name : String) : Boolean;
Var
 F : Text;
 I : Integer;
 S : String;
Begin
 ExportReport := False;
 Assign(F, Name);
 {$I-}
 Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Exit;
 VClear;
 BuildReport;
 WriteLn(F, Tx(W_TITLE));
 WriteLn(F);
 For I := 1 To VLN Do Begin
  S := VL[I].S;
  If VL[I].Kind = 1 Then S := PadR('', (78 - Length(S)) Div 2) + S
  Else S := PadR('', VL[I].Ind) + S;
  WriteLn(F, S);
  If VL[I].Kind = 2 Then Begin
   S := '';
   While Length(S) < Length(VL[I].S) Do S := S + '=';
   WriteLn(F, S);
  End;
 End;
 WriteLn(F);
 WriteLn(F, Tx(R_SYMS), ' :');
 For I := 1 To An.NHit Do
  WriteLn(F, '  ', PadR(SNAME[An.Hit[An.HitO[I]].Sym], 28),
          An.Hit[An.HitO[I]].Cnt);
 Close(F);
 ExportReport := True;
End;

{ ================================================================== }
{ Recherche dans le dictionnaire                                     }
{ ================================================================== }

Function KeyMatchWord(Const K : String; Q : String) : Boolean;
Begin
 If K[Length(K)] = '*' Then
  KeyMatchWord := Copy(Q, 1, Length(K) - 1) = Copy(K, 1, Length(K) - 1)
 Else KeyMatchWord := K = Q;
End;

Procedure SearchSym(Q : String);
Var
 Res : Array[1..MAXLI] Of Integer;
 N, S, K, I, Sel : Integer;
 Found : Boolean;
Begin
 Q := NormWord(Q);
 If Q = '' Then Begin Refresh; Exit; End;
 N := 0;
 For S := 1 To NSYM Do
  If (Pos(Q, NormWord(SNAME[S])) > 0) And (N < MAXLI) Then Begin
   Inc(N);
   Res[N] := S;
  End;
 For K := 1 To NKEY Do
  If (KTAR[K] < T_EMO) And KeyMatchWord(KeysStr(K), Q) Then Begin
   Found := False;
   For I := 1 To N Do If Res[I] = KTAR[K] Then Found := True;
   If (Not Found) And (N < MAXLI) Then Begin
    Inc(N);
    Res[N] := KTAR[K];
   End;
  End;
 If N = 0 Then Begin
  MsgBox(Tx(X_NOTFOUND));
  Refresh;
 End Else If N = 1 Then SetView(V_SYMDET, Res[1])
 Else Begin
  For I := 1 To N Do
   LItem[I] := PadR(SNAME[Res[I]], 27) + CatName(SCAT[Res[I]]);
  Sel := 1;
  If ListDialog(Tx(X_RESULTS), N, Sel, False) = 1 Then
   SetView(V_SYMDET, Res[Sel])
  Else Refresh;
 End;
End;

{ ================================================================== }
{ Actions                                                            }
{ ================================================================== }

Function NeedText : Boolean;
Begin
 NeedText := Not EdEmpty;
 If EdEmpty Then MsgBox(Tx(D_NOTEXT));
End;

Procedure DoAction(A : Integer);
Var
 S : String;
 R : TDream;
 Sel : Integer;
Begin
 If A <> 0 Then Begin
  MouseOff;
  RedrawAll;
  MouseOn;
 End;
 Case A Of
  0 : Refresh;
  A_NEW : If ConfirmLoss(D_CONFNEW) Then Begin
           R := Dream;
           DefaultDream;
           Dream.Dreamer := R.Dreamer;
           If DreamDialog(Dream) Then Begin
            If Dream.Title = '' Then
             Dream.Title := Tx(D_DEFTITLE) + ' ' +
                            DateStr(Dream.D, Dream.M, Dream.Y);
            EdClear;
            JIdx := 0;
            EMod := False;
            SetView(V_EDIT, 0);
           End Else Begin
            Dream := R;
            Refresh;
           End;
          End Else Refresh;
  A_OPEN, A_JLIST : OpenJournal;
  A_SAVE : SaveDream;
  A_IMPORT : Begin
              S := '';
              If InputBox(Tx(D_IMPORT), Tx(D_FILE), S, 40) And (S <> '') Then
              Begin
               If ConfirmLoss(D_CONFNEW) Then Begin
                R := Dream;
                If LoadTextFile(S) Then Begin
                 DefaultDream;
                 Dream.Dreamer := R.Dreamer;
                 Dream.Title := Copy(S, 1, 40);
                 JIdx := 0;
                 EMod := True;
                 SetView(V_EDIT, 0);
                 MsgBox(Tx(D_IMPORTED) + ' ' + S);
                End Else MsgBox(Tx(D_IOERR));
               End;
              End;
              Refresh;
             End;
  A_EXPORT : If NeedText Then Begin
              S := TXTFILE;
              If InputBox(Tx(D_EXPORT), Tx(D_FILE), S, 40) And (S <> '') Then
              Begin
               If ExportReport(S) Then Begin
                BuildView;
                MsgBox(Tx(D_EXPORTED) + ' ' + S);
               End Else Begin
                BuildView;
                MsgBox(Tx(D_IOERR));
               End;
              End;
              Refresh;
             End Else Refresh;
  A_QUIT : If ConfirmLoss(D_CONFQUIT) Then QuitReq := True Else Refresh;
  A_EDIT : SetView(V_EDIT, 0);
  A_PROPS : Begin
             If DreamDialog(Dream) Then Begin
              EMod := True;
              EDirty := True;
              BuildView;
             End;
             Refresh;
            End;
  A_HILITE : Begin
              Hilite := Not Hilite;
              Refresh;
             End;
  A_CLEAR : If AskBox(Tx(D_CONFCLR), True) Then Begin
             EdClear;
             EMod := True;
             SetView(V_EDIT, 0);
            End Else Refresh;
  A_SAMPLE : If ConfirmLoss(D_CONFNEW) Then Begin
              R := Dream;
              LoadSample;
              Dream.Dreamer := R.Dreamer;
              SetView(V_EDIT, 0);
             End Else Refresh;
  A_REPORT : If NeedText Then SetView(V_REPORT, 0) Else Refresh;
  A_SYMS : If NeedText Then SetView(V_SYMS, 0) Else Refresh;
  A_TONE : If NeedText Then SetView(V_TONE, 0) Else Refresh;
  A_THEMES : If NeedText Then SetView(V_THEMES, 0) Else Refresh;
  A_CLASS : If NeedText Then SetView(V_CLASS, 0) Else Refresh;
  A_ARCH : If NeedText Then SetView(V_ARCH, 0) Else Refresh;
  A_SENSE : If NeedText Then SetView(V_SENSE, 0) Else Refresh;
  A_BROWSE : SetView(V_DICT, 0);
  A_SEARCH : Begin
              S := '';
              If InputBox(Tx(X_SEARCH), Tx(X_WORD), S, 30) Then SearchSym(S)
              Else Refresh;
             End;
  A_BYCAT : Begin
             For Sel := 1 To NCAT Do LItem[Sel] := CatName(Sel);
             Sel := 1;
             If ListDialog(Tx(X_CHOOSECAT), NCAT, Sel, False) = 1 Then
              SetView(V_DICT, Sel)
             Else Refresh;
            End;
  A_JSTATS : Begin
              JStats;
              SetView(V_JOURNAL, 0);
             End;
  A_GUIDE : SetView(V_GUIDE, 0);
  A_ABOUT : Begin
             MsgBox(Fmt(Tx(D_ABOUT), IStr(NSYM), IStr(NKEY), ''));
             Refresh;
            End;
 End;
End;

{ ================================================================== }
{ Clavier et souris                                                  }
{ ================================================================== }

{ Lettre Alt+lettre d'apres le code de balayage }
Function AltLetter(Sc : Integer) : Char;
Const
 R1 : String[10] = 'QWERTYUIOP';
 R2 : String[9] = 'ASDFGHJKL';
 R3 : String[7] = 'ZXCVBNM';
Begin
 AltLetter := #0;
 If (Sc >= 16) And (Sc <= 25) Then AltLetter := R1[Sc - 15];
 If (Sc >= 30) And (Sc <= 38) Then AltLetter := R2[Sc - 29];
 If (Sc >= 44) And (Sc <= 50) Then AltLetter := R3[Sc - 43];
End;

Procedure Scroll(D : Integer);
Var
 Old : Integer;
Begin
 Old := VTop;
 VTop := VTop + D;
 If VTop > VLN - VIS_LINES Then VTop := VLN - VIS_LINES;
 If VTop < 0 Then VTop := 0;
 If VTop <> Old Then Refresh;
End;

Procedure ClampX;
Begin
 If ECX > Length(EL[ECY]) + 1 Then ECX := Length(EL[ECY]) + 1;
 If ECX < 1 Then ECX := 1;
End;

{ Touches de deplacement de l'editeur ; renvoie False si non traitee }
Function EditMove(Sc : Integer) : Boolean;
Begin
 EditMove := True;
 Case Sc Of
  72 : If ECY > 1 Then Dec(ECY);
  80 : If ECY < EN Then Inc(ECY);
  75 : If ECX > 1 Then Dec(ECX)
       Else If ECY > 1 Then Begin
        Dec(ECY);
        ECX := Length(EL[ECY]) + 1;
       End;
  77 : If ECX <= Length(EL[ECY]) Then Inc(ECX)
       Else If ECY < EN Then Begin
        Inc(ECY);
        ECX := 1;
       End;
  71 : ECX := 1;
  79 : ECX := Length(EL[ECY]) + 1;
  73 : Begin ECY := ECY - (VIS_LINES - 1); If ECY < 1 Then ECY := 1; End;
  81 : Begin ECY := ECY + VIS_LINES - 1; If ECY > EN Then ECY := EN; End;
  119 : Begin ECY := 1; ECX := 1; End;
  117 : Begin ECY := EN; ECX := Length(EL[EN]) + 1; End;
  83 : EdDel;
 Else EditMove := False;
 End;
 ClampX;
 EdShowCursor;
End;

Procedure HandleKey(K : Word);
Var
 C : Char;
 I : Integer;
Begin
 If K >= 256 Then Begin
  Case K - 256 Of
   59 : DoAction(A_GUIDE);
   60 : DoAction(A_NEW);
   61 : DoAction(A_OPEN);
   62 : DoAction(A_SAVE);
   63 : DoAction(A_EDIT);
   64 : DoAction(A_REPORT);
   65 : DoAction(A_TONE);
   66 : DoAction(A_THEMES);
   67 : DoAction(A_SENSE);
   68 : DoAction(RunMenu(1));
   45 : DoAction(A_QUIT);
  Else
   C := AltLetter(K - 256);
   If C <> #0 Then Begin
    For I := 1 To NMENU Do
     If AmpChar(Tx(MTitle[I])) = C Then Begin
      DoAction(RunMenu(I));
      Exit;
     End;
   End Else If View = V_EDIT Then Begin
    If EditMove(K - 256) Then Refresh;
   End Else
    Case K - 256 Of
     72 : Scroll(-1);
     80 : Scroll(1);
     73 : Scroll(-VIS_LINES + 2);
     81 : Scroll(VIS_LINES - 2);
     71 : Scroll(-MAXVL);
     79 : Scroll(MAXVL);
    End;
  End;
  Exit;
 End;
 If View = V_EDIT Then Begin
  Case K Of
   8 : EdBack;
   13 : EdEnter;
   19 : Begin DoAction(A_SAVE); Exit; End;
   25 : EdKillLine;
   9, 96 : EdAccent;
   27 : Exit;
  Else
   If K >= 32 Then EdChar(ToCP(Chr(K))) Else Exit;
  End;
  EdShowCursor;
  Refresh;
  Exit;
 End;
 If K = 27 Then Begin
  If View = V_WELCOME Then Exit;
  GoBack;
 End Else If K = 13 Then Begin
  If View = V_WELCOME Then SetView(V_EDIT, 0);
 End;
End;

Procedure HandleClick(X, Y : LongInt);
Var
 M, I : Integer;
Begin
 If Y < MENU_H Then Begin
  M := MenuAtX(X);
  If M > 0 Then DoAction(RunMenu(M));
  Exit;
 End;
 If (Y < BODY_Y) Or (Y >= STAT_Y) Then Exit;
 { barre de defilement : fleches et pages }
 If X >= SCREEN_W - 15 Then Begin
  If View = V_EDIT Then Begin
   If EN > VIS_LINES Then Begin
    If Y < BODY_Y + 14 Then I := 72
    Else If Y > STAT_Y - 15 Then I := 80
    Else If Y < BODY_Y + 14 + (STAT_Y - BODY_Y - 28) * ETop Div EN Then
     I := 73
    Else I := 81;
    If EditMove(I) Then Refresh;
    Exit;
   End;
  End Else If (VLN > VIS_LINES) And (View <> V_TONE) And
     (View <> V_THEMES) And (View <> V_CLASS) And (View <> V_JOURNAL) Then
  Begin
   If Y < BODY_Y + 14 Then Scroll(-1)
   Else If Y > STAT_Y - 15 Then Scroll(1)
   Else If Y < BODY_Y + 14 + (STAT_Y - BODY_Y - 28) * VTop Div VLN Then
    Scroll(-VIS_LINES + 2)
   Else Scroll(VIS_LINES - 2);
   Exit;
  End;
 End;
 If View = V_EDIT Then Begin
  ECY := ETop + (Y - BODY_Y - 4) Div LINE_H + 1;
  If ECY > EN Then ECY := EN;
  If ECY < 1 Then ECY := 1;
  ECX := (X - 12 + 4) Div 8 + 1;
  ClampX;
  Refresh;
 End Else If (View <> V_TONE) And (View <> V_THEMES) And
             (View <> V_CLASS) And (View <> V_JOURNAL) Then Begin
  I := VTop + (Y - BODY_Y - 4) Div LINE_H + 1;
  If (I >= 1) And (I <= VLN) And (VL[I].Tag >= 1000) Then
   SetView(V_SYMDET, VL[I].Tag - 1000);
 End;
End;

{ boucle principale : touches, clics et choix de la barre de menus de PM }
Procedure MainLoop;
Var
 Kd, Kk, X, Y : LongInt;
Begin
 QuitReq := False;
 Repeat
  Kd := NextEvent(Kk, X, Y);
  Case Kd Of
   EV_KEY : HandleKey(Kk);
   EV_CLICK : Begin MsX := X; MsY := Y; HandleClick(X, Y); End;
   EV_CMD : If Kk = CMD_CLOSE Then DoAction(A_QUIT)
            Else If (Kk > 100) And (Kk < 200) Then DoAction(Kk - 100);
  End;
 Until QuitReq;
End;

{ ================================================================== }
{ Mode texte : REVES /TEST fichier (analyse) ou /SENS fichier        }
{ ================================================================== }

Procedure RunTest(Full : Boolean);
Var
 I, H : Integer;
Begin
 DefaultDream;
 If Not LoadTextFile(ParamStr(2)) Then Begin
  WriteLn('Fichier introuvable : ', ParamStr(2));
  Exit;
 End;
 Analyze;
 If Full Then Begin
  VClear;
  BuildReport;
  For I := 1 To VLN Do WriteLn(PadR('', VL[I].Ind), VL[I].S);
  Exit;
 End;
 WriteLn('LANGUE ', An.Lg, ' MOTS ', An.NW, ' PHRASES ', An.NSent,
         ' SYMBOLES ', An.NHit, ' EMOTIONS ', An.NEmoW);
 WriteLn('SCORE ', An.Score, ' TON ', An.ToneC, ' EVOL ', An.Evol,
         ' POS ', An.PosN, ' NEG ', An.NegN, ' NEU ', An.NeuN);
 For I := 1 To An.NHit Do Begin
  H := An.HitO[I];
  WriteLn('SYM ', SNAME[An.Hit[H].Sym], ' x', An.Hit[H].Cnt, ' ctx ',
          An.Hit[H].Ctx : 0 : 2);
 End;
 For I := 1 To NWd Do
  If Wd[I].Mark In [K_POS, K_NEG, K_NEGATED, K_TOOL] Then
   WriteLn('EMO ', Wd[I].W, ' ', Wd[I].Mark);
 For I := 1 To 3 Do
  WriteLn('TYPE ', TYPN[0, An.TypO[I]], ' ', An.TypP[An.TypO[I]]);
 For I := 1 To 3 Do
  WriteLn('CAT ', CATN[0, An.CatO[I]], ' ', An.Cat[An.CatO[I]] : 0 : 1);
End;

{ ================================================================== }
{ Programme principal                                                }
{ ================================================================== }

BEGIN
 InitLanguage;
 InitPools;
 Hilite := True;
 DefaultDream;
 Dream.Dreamer := '';
 EdClear;
 EMod := False;
 JIdx := 0;
 JN := 0;
 If ParamStr(1) = '/TEST' Then Begin
  RunTest(False);
  Halt;
 End;
 If ParamStr(1) = '/RAPPORT' Then Begin
  RunTest(True);
  Halt;
 End;
 ActiveMenu := 0;
 StatusMsg := '';
 MsSaved := False;
 InitBmi;
 EvHead := 0; EvTail := 0; OsFrame := 0; OsClient := 0;
 OpenWindow('REVES', 'Onirologie');
 MouseOK := True;
 MsX := SCREEN_W Div 2;
 MsY := SCREEN_H Div 2;
 MsB := 0;
 View := V_WELCOME;
 PrevView := V_WELCOME;
 BuildView;
 Refresh;
 If (ParamCount >= 1) And (Copy(ParamStr(1), 1, 1) <> '/') Then Begin
  If LoadTextFile(ParamStr(1)) Then Begin
   DefaultDream;
   Dream.Title := Copy(ParamStr(1), 1, 40);
   JIdx := 0;
   EMod := True;
   SetView(V_EDIT, 0);
  End Else MsgBox(Tx(D_IOERR) + ' ' + ParamStr(1));
 End;
 MainLoop;
 Dummy := WinDestroyWindow(OsFrame);
END.
