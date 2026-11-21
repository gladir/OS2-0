{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/mystix)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Astromancie, logiciel interactif d'interpretation de
                l'astrologie (clone graphique du logiciel URRIS de 1985),
                pour le Presentation Manager d'OS/2-0 (dossier Loisirs).
}

Program ASTROMAN;

{ Compilation : OS2PC ASTROMAN.PAS   (produit ASTROMAN.EXE)

  Portage vers OS/2-0 d'ASTROMAN.PAS du depot Mystix (Turbo Pascal 7,
  Free Pascal : BGI 640 x 480 en 16 couleurs, souris de l'interruption
  33h). Tout le moteur est conserve tel quel : calcul du theme (planetes,
  maisons, aspects), interpretation d'URRIS (textes integres), theme du
  jour, previsions, tarot astrologique, comparaison de deux themes,
  calepin (ASTROMAN.CAL), exportation de la page (ASTROMAN.TXT), cinq
  langues (LANGUAGE=FR, EN, DE, ES, IT).

  Ce qui change pour OS/2 :
  - fenetre de Presentation Manager : barre de titre (nom de la personne),
    menu systeme, barre de menus d'OS/2 construite a partir des tables
    de menus d'origine ; les choix qui demandent un theme sont grises tant
    qu'aucun horoscope n'est ouvert ;
  - pages de texte sur fond blanc (couleurs foncees), barre d'information
    et barre d'etat grises, boites de dialogue, boutons, zones de saisie
    et barre de defilement dans le style d'OS/2 ;
  - messages et questions par WinMessageBox ;
  - la carte du ciel et la page d'accueil gardent leur ciel etoile. }

{ ================================================================== }
{ Donnees integrees : textes d'interpretation (NATURRIS, DOMURRIS,    }
{ MASURRIS, MAMURRIS, ASPURRIS, SYMURRIS), mots-cles (MOTURRIS),      }
{ villes (VILURRIS), zones horaires (ATLURRIS) et decalages annuels   }
{ (FUSURRIS), messages de l'interface en 5 langues.                   }
{ ================================================================== }

Const
 NTX = 4749;
 NBLK = 1600;
 TXL : Array[1..NTX] Of String[70] = (
  'Le caractŠre est aventureux et ambitieux. Possibilit‚s de coups de',
  'tˆte, alternatives de hauts et de bas. L''ascension se manifeste',
  'par pulsions successives. Courage et volont‚.',
  'L''ambition et l''activit‚ sont immenses, mais peuvent se montrer',
  'brouillonnes et parfois brutales. L''ensemble conduit aux excŠs.',
  'Besoin d''agir d‚bordant. Grande vigueur physique.',
  'Les luttes et les obstacles sont fr‚quents. Il y a de la bont‚ :',
  'le coeur est ouvert … la douleur d''autrui. Sacrifice l''activit‚',
  'et la vitalit‚ sont des gages de r‚sistance.',
  'Malgr‚ une grande r‚sistance physique, les risques d''accidents',
  'sont fr‚quents. Craindre les actes dangereux. La prudence et',
  'l''attention sont conseill‚es dans la vie.',
  'Force physique et vitalit‚. Les passions sont violentes et',
  'tenaces. On accepte difficilement les conseils et la rancune est',
  'longue … s''apaiser. Voyages et d‚placements fr‚quents.',
  'Tendance … agir et penser en circuit ferme. Amour du bien-ˆtre et',
  'possibilit‚ de l''acqu‚rir. Les app‚tits sont violents et les',
  'conceptions sont avant tout utilitaires et positives.',
  'Le sujet est audacieux et parfois mˆme inconscient du danger les',
  'instincts priment et ce qui a ‚t‚ d‚cid‚ doit ˆtre accompli.',
  'Besoin inn‚ de foncer sur l''obstacle.',
  'L''imagination et l''introspection empˆchent souvent de voir les',
  'choses sous un angle exact. L''h‚sitation et le doute alternent',
  'avec la confiance en soi. Fixit‚ dans le d‚sir.',
  'Intelligent et sympathique, on rencontre beaucoup d''appuis.',
  'Tant“t r‚fl‚chi, tant“t impulsif, les d‚cisions sont longues …',
  'prendre. Destin sujet a des hauts et des bas. Voyages.',
  'Belle intelligence, productrice de r‚alisations, apte … choisir et',
  '… r‚ussir dans beaucoup de domaines. Inconstance sentimentale.',
  'Pr‚dispos‚ aux excŠs. Abus de ses forces.',
  'Les tourments ne sont pas toujours des obstacles et les scrupules',
  'poussent aux excŠs. La timidit‚ et l''h‚sitation nuisent aux',
  'bonheur. La moralit‚ est bonne. Optimisme.',
  'Activit‚ puissante, intelligence et bon go–t. L''‚go‹sme est',
  'd‚velopp‚ et les passions nombreuses. Tendance … se disperser',
  'surtout sentimentalement. Tendance … plaire et … flirter.',
  'Le mental et les sentiments sont complexes : l''humeur est',
  'changeante, capricieuse. Vie mobile et mouvement‚e, imaginative et',
  'aventureuse. Grande ind‚pendance et besoin d''‚vasion',
  'Besoin continuel de nouveaut‚s et de sensations inconnues. Le',
  'courage physique n''est pas dominant et l''effort co–te. La',
  'destin‚e semble souvent assez floue en bien comme en mal.',
  'Peu favorable … la paix conjugale : les risques de tromperie sont',
  'nombreux. Se m‚fier des mauvaises fr‚quentations. On saura se',
  'rallier de solides amiti‚s et puissants secours.',
  'Une trop grande franchise nuit aux rapports avec les autres. Les',
  'possibilit‚s de r‚ussir sont grandes malgr‚ une nature violente et',
  'un manque de souplesse et de tact. D‚vouement.',
  'Grande confiance en soi et optimisme. La croyance en sa valeur',
  'repose sur des possibilit‚s r‚elles. Amour du vrai et du beau. Les',
  'inimiti‚s et les amiti‚s sont nombreuses.',
  'L''orgueil et l''ambition dominent. La r‚ussite se manifeste',
  'souvent par des moyens violents. Le sensualisme est ‚lev‚ et',
  'parfois artistique. Grande force vitale. Magn‚tisme.',
  'Le temp‚rament est passionnel et la franchise d‚velopp‚e.',
  'L''esprit de justice est manifeste. Le coeur est sensible et r‚agit',
  'rapidement. Appuis puissants. Ascension rapide.',
  'La pers‚v‚rance permet de triompher des emb–ches de la vie. Le',
  'travail et la confiance en soi permettent de satisfaire',
  'l''ambition. Se m‚fier des jaloux et des curieux.',
  'L''intelligence est claire avec bon sens et logique. Beaucoup',
  'd''intuition et de spiritualit‚. Esprit studieux et appliqu‚.',
  'l‚vation sociale par le mariage ou le m‚rite. Bon jugement',
  'Beaucoup de raison, d''‚quilibre et de propret‚ morale. Tendance …',
  'la m‚lancolie, au pessimisme et … la solitude. L''ambition n''est',
  'pas trŠs puissante. Tact et compr‚hension.',
  'R‚ussite tardive. L''audace, la perverance et une certaine',
  'diplomatie permettent d''abattre les nombreux obstacles. Redouter',
  'les discussions familiales et professionnelles.',
  'Favorise les amours et la chance en g‚n‚ral. Les satisfactions',
  'sentimentales ne sont toutefois pas trŠs intenses. R‚sistance',
  'nerveuse et bon ‚quilibre physique. Pol‚miques.',
  'Les qualit‚s morales sont bonnes malgr‚ certaines dispositions …',
  'l''envie et la jalousie. L''esprit est observateur et appliqu‚.',
  'Ambition limit‚e mais pers‚v‚rance. Diplomatie.',
  'Beaucoup de raison et recherche de l''‚quilibre. Le bon go–t et',
  'l''imagination facilitent la r‚ussite. Tendance … diffuser ses',
  'forces et … s''occuper de trop de choses … la fois.',
  'L''esprit n''est pas toujours dirige vers les choses gaies. Les',
  'embarras sont nombreux, tant sentimentaux que professionnels.',
  'Juste compr‚hension et dispositions conciliantes.',
  'L''esprit est ergoteur, tatillon et jaloux. L''‚go‹sme est sans',
  'm‚chancet‚. Le sensualisme artistique fait aimer tout ce qui est',
  'bon et beau. Se m‚fier de la solitude. Raison.',
  'Nature orgueilleuse et ‚go‹ste, ardente et militante.',
  'L''intelligence est belle, souple, f‚conde et imaginative. Les',
  'facilit‚s pour l''‚tude sont remarquables. Pers‚v‚rance.',
  'Belles possibilit‚s intellectuelles. Le savoir-faire est',
  'd‚velopp‚. La personnalit‚ est peu commune et porte … la critique.',
  'L''ambition est violente et sait se dominer.',
  'L''impatience expose … l''imprudence. La situation g‚n‚rale est',
  'sujette aux alternatives de hauts et de bas. Grande activit‚ : les',
  'besoins sexuels sont puissants. Autodidacte.',
  'Tendance … pr‚sumer de ses possibilit‚s. Les qualit‚s morales ne',
  'sont pas trŠs brillantes mais les possibilit‚s mat‚rielles',
  'satisfaisantes. R‚ussite probable. Filouterie.',
  'Amour de la vie et de tout ce qui est bon et beau. Une tendance …',
  'l''individualisme permet l''ascension rapide. Besoin de personne',
  'pour arriver … ses fins. Esprit aventureux',
  'Favorise par la chance. L''esprit est pose et la logique bonne.',
  'Besoin de d‚penser autant pour soi que pour les autres.',
  'L''exp‚rience vient de bonne heure. Id‚es heureuses.',
  'Les possibilit‚s de r‚ussite sont consid‚rables et doivent se',
  'r‚aliser par le travail, le m‚rite et l''audace. CaractŠre hardi',
  'et inflexible en affaires. La destin‚e est tourment‚e.',
  'Les qualit‚s dominantes sont la logique, la clairvoyance et la',
  'spiritualit‚. Les succŠs sont nombreux. La situation g‚n‚rale',
  'n''est jamais d‚finitive. Bon conseiller pour autrui',
  'Les satisfactions obtenues dans la vie le sont grƒce aux efforts.',
  'Le caractŠre est prudent et r‚fl‚chi. La rancune est tenace et',
  'l''esprit est compliqu‚, voire obtus. Aust‚rit‚',
  'Les qualit‚s intellectuelles sont belles et profonde, pas toujours',
  'bien utilis‚es sentimentalement. Peu de chance en amour. Les',
  'trahisons et les d‚sillusions sont courantes.',
  'Les moindres fautes entraŒnent des catastrophes. L''esprit est',
  'ouvert et le coup d''oeil juste. Une grande force de caractŠre',
  'freine certains ‚lans dangereux. ExcŠs de prudence',
  'Grande r‚sistance physique. L''esprit est entier mais manque de',
  'cl‚mence : on reconnaŒt difficilement ses erreurs. On se fait plus',
  'craindre qu''aimer. Amour de la solitude et orgueil.',
  'Pr‚dispos‚ … la lutte pour maintenir l''‚quilibre physique. Les',
  'qualit‚s morales et intellectuelles sont belles. On est bizarre et',
  'excentrique. Nombreuses blessures d''amour-propre.',
  'Beaucoup d''intuition mais un manque certain de d‚cision et de',
  'volont‚ : on peut difficilement dire non quand il s''agit du coeur.',
  'Le sentiment prime sur la raison. Honnˆtet‚.',
  'Incline … une partialit‚ souvent r‚voltante. Il faut craindre',
  'autant ses amis que ses ennemis. L''esprit est synth‚tique. La vie',
  'sentimentale est troubl‚e par manque de fermet‚.',
  'Tendance … prendre ses d‚sirs pour des r‚alit‚s. Les id‚es',
  'affluent mais restent souvent … l''‚tat de projets. L''esprit est',
  'rˆveur et curieux. Besoin continuel d''apprendre. G‚nie.',
  'L''instinct d''‚conomie est pousse car on craint le lendemain.',
  'Beaucoup d''ambition mais peu de suite dans les id‚es et dans les',
  'actes. Perp‚tuelle h‚sitation dans le choix des moyens.',
  'L''esprit analytique est porte … la critique. L''audace est grande',
  'et souvent inconsciente. Tendance au farniente et manque de',
  'continuit‚ dans l''effort. Rˆve et perte de temps.',
  'L''esprit est vagabond. L''existence n''est pas stable et les',
  'app‚tits puissants, souvent trop puissants par rapport aux',
  'r‚alit‚s. Perte de temps dans la conduite des affaires.',
  'Grande confiance en soi et souvent une opinion surfaite de sa',
  'valeur. On veut trop bien faire et on ne fait rien. Manque',
  'd''adaptation aux circonstances. Crainte de l''‚chec.',
  'L''imagination est grande et le caractŠre vif et mobile. Manque de',
  'confiance en soi. L''esprit est plus capricieux que volontaire.',
  'Dispositions au bluff et au bavardage. Fantaisie',
  'Grosse d‚pens‚ d''‚nergie, souvent sans raison. L''impulsivit‚ est',
  'instinctive et dangereuse. Alternatives de courage et de',
  'laisser-aller. Les voyages sont parfois aventureux. T‚m‚rit‚',
  'Dispose aux accŠs de gaiet‚ suivi de tristesse. Manque de',
  'pond‚ration. Les disput‚s professionnelles et les heurts sont',
  'fr‚quents avec le sexe oppos‚. Retarde le mariage.',
  'On cherche … plaire et y parvient g‚n‚ralement. Le besoin',
  'd''affection est grand et peut conduire … un mariage pr‚coce. Le',
  'destin est capricieux et changeant comme le caractŠre.',
  'D‚note de la sagesse dans la conduite des affaires. Le jugement',
  'est droit, l''esprit vif et le caractŠre doux. D‚sir de plaire.',
  'Puissants appuis venant du sexe oppos‚.',
  'L''imagination est puissante, l''intelligence vive et la m‚moire',
  'docile : on veut tout savoir et tout connaŒtre. La synthŠse domine',
  'et les vues sont amples. Ind‚pendance.',
  'Dispose … l''amour du moindre effort et du plaisir mat‚riel. Le',
  'temp‚rament est sensuel et affectueux. Accroissement des biens par',
  'l''amour : chance pure. Sympathie g‚n‚rale.',
  'On est calme, patient, indulgent et r‚serv‚. La vie offre de',
  'r‚elles possibilit‚s de qui‚tude ou de richesses. Le bonheur vient',
  'souvent de la famille. D‚sillusions sentimentales.',
  'Les qualit‚s de l''intelligence sont excellentes. L''imagination',
  'pratique est aid‚e par l''intuition. Bonne humeur et sociabilit‚.',
  'Le go–t des voyages est trŠs prononce. Vivacit‚',
  'L''impressionnabilite est grande : craindre son imagination. Les',
  'projets sont nombreux, peu se r‚alisent. Manque de volont‚ et de',
  'pers‚v‚rance. Dons naturels d''imitation.',
  'L''‚quilibre nerveux est bon et permet de freiner les excŠs.',
  'Incite aux d‚placements et aux changements fr‚quents. Rencontre',
  'souvent des inimiti‚s puissantes dans la famille.',
  'Laisser-aller dans la mise et la tenue mais cela est loin d''ˆtre',
  'antipathique. Les relations sont utiles et nombreuses r‚el',
  'd‚sint‚ressement pour l''argent car on sait s''adapter.',
  'Belles qualit‚s intellectuelles et nature sup‚rieure, rˆveuse et',
  'po‚tique. L''esprit de tout connaŒtre est aide par une m‚moire',
  'excellente. Tend … la cr‚dulit‚ et … la na‹vet‚.',
  'Le sens pratique est faible, mais la chance et l''initiative',
  'favorisent la cr‚ativit‚. Belles satisfactions d''amour-propre :',
  'appuis nombreux de la part des femmes. Voyages.',
  'La chance aide toujours les projets. Favorise les professions qui',
  'mettent en rapport avec la femme. Rend diplomate et n‚gociateur.',
  'Grande facilite de se contenter de peu.',
  'Bon ‚quilibre physique. Rend amoureux de la vie, sans abus.',
  'L''esprit est philosophique ou religieux : amour de l''‚tude.',
  'Aptitudes litt‚raires et artistiques. Pr‚dispos‚ … ‚crire.',
  'L''esprit est vivace et fantasque. L''intelligence est ample et',
  's''int‚ress‚ … tout. Ascension dans une carriŠre lib‚rale ou',
  'intellectuelle. CaractŠre fier, droit et entier.',
  'Existence empoisonn‚e par de nombreuses obligations morales.',
  'L''imagination est pratique, alli‚e au sens de la mesure. Les',
  'faveurs populaires et les honneurs sont permis. Long‚vit‚',
  'On pr‚sume trop de ses forces et de ses moyens : excŠs physiques',
  'et sentimentaux. L''intelligence est pratique et la sant‚',
  'g‚n‚ralement ‚quilibr‚e. Instabilit‚ mat‚rielle.',
  'Disposition … la violence et … l''emportement : la volont‚ est',
  'faible et ne peut r‚agir contre les passions et instincts. Les',
  'amis sont g‚n‚ralement fidŠles et du sexe oppos‚.',
  'L''intelligence est intuitive et sensible : grande compr‚hension',
  'de l''inconnu. Pr‚dispos‚ aux rˆves et pressentiments l''esprit',
  'est capricieux et fantasque. Manque d''exp‚rience.',
  'Donne de la sympathie, de la r‚serv‚ et de la discr‚tion.',
  'L''effort est facilit‚ par une bonne compr‚hension des faits. Les',
  'd‚sirs sont fixes : on sait ce que l''on veut.',
  'On ne sait pas toujours discerner l''impossible du possible. Bonne',
  'humeur et d‚sir de plaire. Retards fr‚quents dans l''ascension',
  'professionnelle. La sant‚ est ‚quilibr‚e.',
  'Les satisfactions sentimentales ne sont pas nombreuses et le',
  'conjoint ne r‚pond pas toujours aux aspirations. Les id‚es sont',
  'confuses et pr‚disposent aux exp‚riences. Excentrique.',
  'Dispose … l''engouement, au rire et … l''amusement : on a la larme',
  'facile mais les peines sont de courtes dur‚e. L''esprit est droit,',
  'consciencieux et tatillon. Logique et bon sens.',
  'Beaucoup de fantaisie et une certaine coquetterie dans la mise et',
  'la tenue. L''imagination puissante accorde de r‚elles aptitudes',
  'artistiques. Les amours sont souvent myst‚rieuses.',
  'L''imagination va de pair avec l''intelligence : il y a du talent',
  'parfois, du m‚rite toujours. Esprit sensible et opportuniste.',
  'Parfois indice d''une jeunesse difficile.',
  'Facilite les emplois qui touchent … la magistrature et rapports',
  'avec la loi. L''ascension est g‚n‚ralement facilit‚e par les',
  'appuis dans une carriŠre administrative.',
  'La r‚sistance physique est consid‚rable mais l''‚nergie est',
  'd‚pens‚e sans raison. L''impulsion et l''irr‚flexion empˆchent de',
  'freiner les d‚sirs : peut conduire aux actes dangereux.',
  'Le caractŠre est ind‚pendant et capricieux. L''esprit est',
  'indisciplin‚ et parfois r‚volte. CarriŠre ind‚pendante car on',
  'souffre de travailler pour autrui. Situation instable.',
  'Les relations sont souvent dangereuses et la vie d‚r‚gl‚e. Rend',
  'vantard, ‚go‹ste et paresseux, tant“t impulsif, tant“t ind‚cis. On',
  'vit au jour le jour et souvent d''exp‚dients.',
  'Rend imprudent et excessif en tout. Les amours sont souvent',
  'v‚nales et conduisent … une moralit‚ certaine. Rend ‚go‹ste et',
  'paresseux. Dispose … vivre d''exp‚dient. Imprudences.',
  'Le sens pratique est faible et l''esprit est porte vers les choses',
  'merveilleuses. Manque complet d''organisation. Peut conduire … la',
  'pauvret‚, tout au moins … la gˆne. Imagination',
  'TrŠs favorable au moral car le caractŠre est souple et doux,',
  'bienveillant et tol‚rant. La vie sentimentale est troubl‚e. Chance',
  'mat‚rielle malgr‚ un d‚sint‚ressement irr‚fl‚chi.',
  'L''esprit de famille est d‚velopp‚ : on est d‚vou‚ aux siens. Les',
  'risques de tromperie sont fr‚quents malgr‚ les d‚sirs de paix et',
  'd''amour. La vie est souvent mouvement‚e. Contraintes',
  'Sans ˆtre pratique, l''esprit est ordonn‚ et plein de courage de',
  'patience et de pers‚v‚rance. Les conceptions sont fixes et parfois',
  'in‚branlables. Aptitudes … la divination.',
  'Rend lent et ind‚cis, capricieux et inconstant. Tendance …',
  'l''indisciplin‚ et … l''ind‚pendance. Le caractŠre peut s''aigrir',
  'avec le temps. Le c‚r‚bral domine le physique.',
  'Peut disposer … la m‚chancet‚ froide et orienter l''imagination',
  'vers le mal. On paraŒt soumis et aimant. Malgr‚ cela le caractŠre',
  'est int‚gr‚, parfois soup‡onneux et rigide.',
  'La sant‚ peut ne pas ˆtre trŠs bonne. L''esprit est m‚ditatif et',
  'peut ˆtre orient‚ vers les ‚tudes intellectuelles ou abstraites.',
  'Nombreuses d‚sillusions sentimentales. Moralit‚.',
  'Grossit les faits d‚sagr‚able. Inqui‚tude maladive. Risques',
  'd''adultŠre, de tromperies et de manquements aux paroles. Ennuis',
  'par la mŠre ou l''‚pouse. Parfois le vie est indigne.',
  'L''organisme est r‚sistant et nerveux. L''imagination est',
  'puissante et souvent triste, se complaisant dans des rˆves',
  'fantasques et terrifiants. Aide aux conceptions originales.',
  'Nervosit‚ excessive. Grand besoin d''aimer et d''ˆtre aim‚.',
  'Pr‚dispos‚ au d‚vouement et parfois au sacrifice. Les biens',
  'mat‚riels viennent par sp‚culations heureuses et impr‚vues.',
  'Donne une belle intelligence, de l''intuition et un esprit',
  'inventif favorable aux d‚couvertes. Bon ‚quilibre nerveux. Les',
  'id‚es sont souvent bizarres, capricieuses et fantasques.',
  'L''intelligence est ouverte et le m‚rite, parfois le talent, et la',
  'chance aident … la r‚ussite. Les conceptions sont ‚lev‚es et',
  'originales. Sens de l''opportunit‚ et du caprice.',
  'Grand d‚sir de bien-ˆtre, d''indolence et de laisser-aller.',
  'L''imagination est puissante mais la volont‚ est faible. Manque de',
  'sens pratique. On compte souvent sur la providence',
  'Favorable aux d‚placements. L''imagination est f‚conde et faire',
  'aimer la litt‚rature. Pr‚dispos‚ aux amours myst‚rieuses. Besoin',
  'de changement dans la fortune et l''amour.',
  'Le mental est g‚n‚ralement bon : il y a de la sensibilit‚ et de la',
  'compr‚hension. L''esprit inventif et intuitif est favorable …',
  'l''imagination. Chance mat‚rielle et appuis.',
  'Les passions affectives sont puissantes et tenaces, les flirts et',
  'les amourettes nombreuses. Dispositions aux mensonges et …',
  'l''exag‚ration. Le travail est facile. Chance.',
  'Nervosit‚ excessive enlevant souvent tout contr“le de soi. La',
  'susceptibilit‚ est grande et la mauvaise foi, souvent pour avoir',
  'raison ne l''est pas moins. Esprit de r‚volte.',
  'Belle r‚sistance nerveuse. L''esprit est querelleur et vindicatif.',
  'Bavardage, calomnie et mensonge entraŒnent souvent une vie',
  'mouvement‚e. D‚placements fr‚quents.',
  'On sait se cr‚er des amiti‚s et on est toujours prompt … la',
  'riposte. La r‚ussite dans la vie peut ˆtre rapide. Influence les',
  'situations lib‚rales, le commerce et l''‚crit.',
  'La vitalit‚ est faible et les troubles nerveux sont … redouter. On',
  'atteint souvent les buts que l''on s''est fixe. Possibilit‚s de',
  'd‚placements et voyages. D‚pression physique',
  'Le caractŠre est heureux et l''on sait se rendre sympathique.',
  'L''esprit est ing‚nieux et sagace et le savoir-faire grand.',
  'Qualit‚s de t‚nacit‚, de patience et de souplesse. go‹sme.',
  'Dispositions heureuses pour les ‚tudes. Confiance en soi. Les',
  'succŠs mondains facilitent une vie agr‚able. L''esprit est',
  'd‚brouillard et sait se tirer d''un mauvais pas. Arrivisme',
  'La compr‚hension est rapide et l''esprit curieux d‚sir‚ tout',
  'savoir et tout connaŒtre. Prolixe dans les paroles et les ‚crits.',
  'Favorise les avocats autant que les bavards. M‚moire',
  'Indice d''intelligence, de s‚rieux et de savoir. Le caractŠre est',
  'ferme et l''amour des plaisirs est raisonnable. Parfois tristesse,',
  'rancune et m‚lancolie d‚truisent la sociabilit‚.',
  'L''intelligence est remarquable et l''assimilation rapide.',
  'L''esprit devine et per‡oit tout. On pr‚fŠre les chemins de',
  'travers‚. Rend d‚brouillard et ruse. Esprit d''adaptation.',
  'L''esprit est souple, mobile et expansif. Savoir-faire et sens',
  'pratique. Tout en ‚tant ind‚pendant on est fidŠle en amiti‚ comme',
  'en amour. On sait se cr‚er de nombreux appuis.',
  'L''activit‚ mentale est grande. L''esprit d''entreprise permet de',
  'r‚aliser des projets hardis. Souvent trop ‚motif et sensible, on',
  's''inquiŠte du futur. Esprit de tol‚rance.',
  'Le mental est bon et les id‚es nombreuses, parfois g‚niales, ne',
  'sont pas toujours r‚alis‚es. Pr‚dispos‚ … vivre au jour le jour',
  'par amour de l''ind‚pendance. Beaucoup de diplomatie.',
  'Ne donne pas toujours une grande fid‚lit‚ en amour. L''esprit est',
  'volage, primesautier et changeant. L''imagination est pratique,',
  'sachant s''allier le savoir-faire et la chance.',
  'Les id‚es sont nombreuses et productrices. Dou‚ de bon sens et de',
  'jugement, la souplesse et le savoir-faire rendent sympathique.',
  'Grande adaptabilit‚ aux gens et circonstances.',
  'L''intellect aime les r‚parties promptes et les mots justes. Les',
  'conceptions sont pratiques et se r‚alisent facilement.',
  'Dissentiments avec l''entourage, la famille et l''employeur.',
  'Rend logique, actif et confiant : courage moral et sens de',
  'l''opportunit‚. On sait ce que l''on veut et on sait y faire en',
  'amour comme en affaires. Versatilit‚ affective.',
  'Une vitalit‚ nerveuse et un psychisme puissant aident en toutes',
  'choses. L''intellect est mobile et incite … s''occuper de mille',
  'choses … la fois. Esprit d''entreprise. Diplomatie.',
  'L''esprit studieux permet, si l''entourage s''y prˆte, de trŠs',
  'bonnes ‚tudes. volution intellectuelle continuelle. Aptitudes',
  'pour les sciences pratiques. MaŒtrise de l''esprit.',
  'Remarquable ‚quilibre nerveux. Esprit d''ind‚pendance et',
  'intelligence pratique. Souvent m‚moire et go–t de l''‚tude. Sans',
  'ˆtre un chef, on sait imposer ses conceptions. Bavard.',
  'Le savoir-faire permet de sortir des mauvais chemins et de',
  'd''att‚nuer les coups du destin. On sait parler pour les autres,',
  'persuader et convaincre. Facilit‚s financiŠres.',
  'L''esprit est id‚aliste et analytique. La situation mat‚rielle',
  'n''est pas toujours en accord avec les possibilit‚s',
  'intellectuelles : on se complaŒt dans la recherche et les ‚tudes.',
  'L''esprit philosophique ou religieux est alli‚ … une belle',
  'intuition. Curiosit‚ intellectuelle, spiritualit‚, tact et',
  'compr‚hension. Favorise l''union et les collaborations.',
  'Le mental est puissant et les id‚es servent souvent plus les',
  'int‚rˆts d''autrui que les siennes. Beaucoup de bont‚ et parfois',
  'de la na‹vet‚. On est souvent cr‚dule et abus‚.',
  'La r‚ussite mat‚rielle se fait avec l''appui du sexe oppose. La',
  'nature sup‚rieure facilite la rencontre d''un conjoint ais‚ ou',
  'd''amiti‚s fidŠles. Le m‚rite est souvent reconnu.',
  'L''intelligence et le moral sont puissants. Le jugement est sain',
  'et l''esprit sait s''adapter … la r‚alit‚. Les satisfactions',
  'sentimentales sont probantes. Curiosit‚ d''esprit.',
  'L''‚quilibre nerveux donne de l''allant et de l''optimisme. On est',
  'conciliant, sagace et diplomate. Une certaine audace r‚fl‚chie',
  'permet des satisfactions appr‚ciables. Coup d''oeil',
  'On sait maŒtriser ses impulsions. Beaucoup de raison et de',
  'jugement ‚quilibre. L''esprit conciliateur permet d''ˆtre respect‚',
  'et ‚coute. Apporte souvent le don des langues.',
  'Permet la r‚ussite dans la voie suivie. L''esprit est organisateur',
  'et pratique. L''intelligence et le savoir permettent de s''adapter',
  'aux arts comme aux sciences.',
  'On est intelligent, malin et mˆme ruse. Peut aller vers',
  'l''agressivit‚ mentale. Dispose au bavardage et au mensonge. Fait',
  'les politiciens et les diplomates. Amour de l''argent.',
  'L''esprit est intuitif et ruse et l''intelligence claire et',
  'pratique. On aime les choses compliqu‚es et tout ce qui est',
  'excitant pour l''esprit. Nervosit‚, ‚motivit‚ et colŠre.',
  'L''intelligence est active, avec un penchant pour l''‚tude. TrŠs',
  'souvent le don des langues. On est avide de connaissances',
  'nouvelles, pratiques et exp‚rimentales. Long‚vit‚.',
  'Rend nerveux, impatient et capricieux. Un esprit imaginatif et',
  'inventif aide souvent les affaires et l''argent. L''indisci pline',
  'et la jalousie conduisent aux revirements du destin.',
  'N''est pas favorable … la chance mais les efforts lents et',
  'progressifs sont aides par un profond machiav‚lisme. On sait',
  'dissimuler ce que l''on ressent. Volont‚ ferme et r‚fl‚chie.',
  'L''esprit est spirituel, malin et souple : on sait feindre le',
  'plaisir ou la peine. On s''efforce d''ˆtre toujours du bon cote.',
  'La destin‚e est mat‚riellement satisfaisante.',
  'Les sentiments sont superficiels et l''esprit trompeur. Il y a un',
  'r‚el savoir-faire qui permet de s''infiltrer dans tous les',
  'milieux. La prudence et la r‚flexion sont favorises',
  'Beaucoup de retenue et de crainte. L''esprit est m‚fiant,',
  'tatillon, sur le qui-vive. On conserve difficilement ce qui est',
  'gagn‚. Indique parfois la gˆne ou la misŠre. Crainte.',
  'L''intelligence est vive et l''esprit observateur, ind‚pendant et',
  'rebelle mŠne parfois … la tyrannie, … l''‚go‹sme et …',
  'l''ingratitude. On veut y arriver et on y arriv‚ rapidement.',
  'Le travail et la profession sont favorises par le savoir-faire',
  'mais l''activit‚ alterne avec la paresse. Malheureuses',
  'pr‚dispositions pour le jeu et la sp‚culation. go‹sme.',
  'La chance pure n''existe pas et la r‚ussite est due au m‚rite, au',
  'travail et au savoir. Peut ˆtre l''indication de richesses',
  'durables provenant de combinaisons compliqu‚es.',
  'Beaucoup d''‚go‹sme ne favorise pas l''amiti‚ et l''amour.',
  'L''intelligence est active. Besoin d''ind‚pendance et de voyages',
  'impr‚vus. L''existence est remplie de nouveaut‚s.',
  'L''intelligence et la raison sont solides et les pens‚es',
  'originales et profondes. On se laisse difficilement prendre aux',
  'mirages car on h‚sit‚ avant de passer … l''action.',
  'La destin‚e est capricieuse et souvent dangereuse. La r‚volte peut',
  'conduire … la m‚chancet‚ quand les espoirs sont d‚‡us. La',
  'confiance en soi permet des initiatives parfois g‚niales.',
  'Beaucoup de diplomatie dans un esprit souple mais souvent manque',
  'de bont‚ et d''indulgence. Le savoir-faire est un facteur de',
  'r‚ussite. Fait sortir des sentiers battus. Chance',
  'Heureuses dispositions intellectuelles et aptitudes pour les',
  'sciences et la recherche. L''esprit est organisateur, novateur et',
  'r‚alisateur. L''ascension sociale peut ˆtre trŠs rapide.',
  'Esprit mobile, capricieux, impressionnable et inconstant. On peut',
  'ˆtre coquet, imaginatif et menteur. SuccŠs auprŠs du sexe oppos‚.',
  'Sensibilit‚ artistique et dons de m‚moire.',
  'Contraire … l''activit‚ manuelle et … la force morale. On est',
  'optimisme par paresse et souvent bohŠme. Fait souvent vivre au',
  'jour le jour en attendant la fortune. Prodigalit‚.',
  'L''esprit est intuitif et imaginatif mais manque de bon sens. Les',
  'relations sont nombreuses et utiles financiŠrement. Les id‚es et',
  'les d‚sirs sont passagers. Tendance au caprice.',
  'L''intelligence est f‚conde et l''imagination puissante mais le',
  'courage n''est pas la vertu capitale. On s''adapte aux',
  'circonstances et l''on s''accommode. Amiti‚s utiles. Chance.',
  'L''‚quilibre mental n''est pas bon : la tristesse confine souvent',
  '… la m‚lancolie. La volont‚ est faible et l''instabilit‚',
  'manifeste. La d‚sillusion sentimentale est fr‚quente.',
  'Dispose aux abus sexuels : on ne maŒtrise pas ses instincts.',
  'Manque de ressort en pr‚sence de l''adversit‚. On se laisse',
  'facilement entraŒner. Amourettes nombreuses et amour v‚nal',
  'Le mariage correspond rarement au d‚sir. La sensualit‚ est',
  'prononc‚e et accapar‚ g‚n‚ralement les facult‚s. Pr‚dispos‚ au',
  'snobisme et … la paresse. Vie affective malheureuse.',
  'La sensibilit‚ est port‚e vers les choses de l''amour. La',
  'r‚sistance morale et l''optimisme sont affirmes. Indique la',
  's‚paration dans le mariage ou l''union. Conjoint volage.',
  'quilibre physique, charme, sensibilit‚, bonne humeur et d‚sir de',
  'plaire prononce. Sensualisme artistique. Favorable au mariage. Vie',
  'amoureuse intense et succŠs dus … la chance.',
  'Talents inventifs et savoir-faire tant en art qu''en amour.',
  'Propice … l''art et aux m‚tiers de luxe. La diplomatie contribue',
  'souvent … satisfaire les id‚es. ExcŠs sexuels.',
  'quilibre physique, bonne humeur et charme personnel. Les',
  'relations et sympathies sont nombreuses. L''imagination cr‚atrice',
  'est souvent alli‚e … la chance sp‚culatrice.',
  'Accorde la long‚vit‚ et la raison ainsi que d''heureuses',
  'conceptions artistiques et financiŠres. Allie souvent l''amour et',
  'l''argent. Contr“le de soi et domination des sens.',
  'Le d‚sir de plaire et surtout celui de ne pas d‚plaire sont',
  'grands. La sentimentalit‚ conduit souvent … mener une vie',
  'affective complexe. Bonne adaptation aux circonstances.',
  'Insouciance, impatience et caprices. Indique souvent des abus',
  'sexuels dangereux. Ne pr‚dispos‚ pas … la fid‚lit‚ conjugale',
  'surtout pour les hommes. Vie sentimentale active.',
  'La chaleur des affections et les amiti‚s sont profondes. Amour de',
  'la famille. Le mariage ou l''union aident … la vie. Souvent',
  'l''instinct prime sur la raison et on se sent bafou‚.',
  'Influence heureusement les artistes et donne l''amour de la forme.',
  'Les relations sont brillantes et utiles. Contribue au bien-ˆtre en',
  'rendant le travail facile et r‚mun‚rateur.',
  'On re‡oit plus qu''on ne donne : tout semble ˆtre du. Une',
  'sympathie naturelle aide … plaire. On recherche les succŠs',
  'mondains. Le sensualisme est passif. Facteur de chance',
  'Les hommes plaisent aux femmes et les femmes aux femmes. Favorable',
  '… la litt‚rature l‚gŠre et aux frivolit‚s. Amour du plaisir, des',
  'arts et du luxe. Accorde l''appui des femmes.',
  'Grand d‚sir de plaire. Les ‚motions et les emballements sont',
  'nombreux et de courte dur‚e. Les transactions commerciales sont',
  'facilit‚s par le sexe oppos‚. Chance mat‚rielle.',
  'On obtient g‚n‚ralement tout ce que l''on d‚sir‚ de son entourage.',
  'Indice de passivit‚ d‚sarmante. Gains faciles. Satisfactions',
  'd''amour-propre et parfois renomm‚e artistique.',
  'Favorable … l''union qui sera g‚n‚ralement pr‚coce mais on est',
  'plus sentimental et amoureux que sensuel. Les sentiments sont',
  'exagŠres et changeants. Besoin de plaire et de flirter.',
  'galit‚ d''humeur, ‚quilibre physique et bonne assimilation. On',
  'recherche la paix et on s''efforce de la maintenir dans son',
  'entourage. l‚vation morale et artistique. Harmonie.',
  'Marque de fixit‚ et de fid‚lit‚ dans l''union. Grande entente',
  'sensuelle. Favorable … la vie, … la sant‚, … l''amour de la',
  'famille et du foyer. Facilite l''‚ducation des enfants.',
  'De nombreux tracas viennent troubler la vie sentimentale et',
  'familiale. Expose … la jalousie du sexe oppose. Le courage',
  'physique est faible. Puissantes passions mal contr“l‚es.',
  'EntraŒn‚ des amours bizarres parfois lubriques. Provoque souvent',
  'l''inversion sexuelle ou le c‚libat. On se comporte avec charme et',
  'grƒce. Aptitude … l''art. D‚sillusions d''amour',
  'Les sentiments sont exagŠres et l''esprit ne sait pas se fixer :',
  'il est frivole et superficiel. Dispose presque toujours au luxe et',
  'aux plaisirs. L''humeur est ‚gale et fixe',
  'Le manque d''‚nergie rend tributaire du sexe oppos‚ : on se laisse',
  'facilement entraŒner. L''amour de la forme peut contribuer au',
  'succŠs artistique. Indique souvent l''adultŠre.',
  'Dispose aux excŠs sexuels et … l''amour des plaisirs ‚go‹stes le',
  'd‚sordre sentimental et affectif empˆche l''amour vrai.',
  'Possibilit‚ d''un riche mariage de raison. Regrets inutiles.',
  'La sensibilit‚ est grande : l''esprit et le coeur vibre facilement',
  'de concert. Les amiti‚s sont nombreuses, parfois riches et',
  'brillantes. L''humeur est ‚gale et ‚quilibr‚e.',
  'Le caractŠre est heureux et l''‚quilibre g‚n‚ral harmonique. Grand',
  'd‚sir de plaire, passivit‚ et abandon de soi-mˆme. Besoin de',
  'protection et d''affection. Bien-ˆtre au foyer.',
  'Les satisfactions sentimentales et les joies mat‚rielles sont',
  'souvent d''un ordre ‚lev‚. L''amour est un puissant adjuvant …',
  'l''ambition. L''‚quilibre physique s''allie au moral',
  'Marque probante de s‚curit‚ et d''abondance. L''amour de la',
  'famille soutient l''ambition et le mariage aide souvent',
  'l''ascension. R‚ussite dans les affaires publiques. Chance.',
  'La chaleur des affections entraŒn‚ souvent la passion qui n''aide',
  'pas le coeur et les sens … dominer la raison. Les d‚cisions',
  'affectives sont impulsives et brutales.',
  'CaractŠre ‚go‹ste et passionn‚. Fait les femmes collantes. Les',
  'instincts sexuels sont puissants, fertiles et f‚conds. La vie',
  'professionnelle est facilit‚e par le sexe oppos‚.',
  'Les amiti‚s et les amours sont changeantes et capricieuses.',
  'Nombreuses liaisons, tromperies et adultŠres. Les situations sont',
  'aid‚es financiŠrement par l''amour. Amours v‚nales.',
  'Indications d''adultŠre et de discorde pour raisons sexuelles',
  'l''amour est souvent v‚nal et scandaleux. Les questions d''argent',
  'prennent le pas sur l''affection. ExcŠs passionnels.',
  'CaractŠre bienveillant, pacifique, aimable et l‚ger. On aime le',
  'bien-ˆtre, le faste et les honneurs. L''ambition est souvent',
  'satisfaite sans gros efforts. Fortune et bien-ˆtre.',
  'TrŠs favorable aux artistes, … la litt‚rature et au th‚ƒtre.',
  'N''est pas propice … l''union l‚gale qui est souvent retard‚e. Les',
  'hauts et les bas de la fortune proviennent d''imprudences',
  'On rencontre de nombreuses et utiles sympathies et si on ne',
  'connaŒt pas le grand amour, une affection puissante et fidŠle',
  'comblera la vie. Inconstance dans les affections.',
  'L''union est souvent int‚ress‚e et le mariage de raison fr‚quent.',
  'Un grand besoin de jouissance peut conduire … se vendre par peur',
  'du lendemain ou de la pauvret‚. Veuvage.',
  'On est souvent h‚sitant, timide, soup‡onneux et jaloux sous une',
  'apparence calme et sereine. Vie affective raisonn‚e. Les amours',
  'sont parfois marqu‚es par le sceau de la fatalit‚',
  'Les luttes sont peu nombreuses et les richesses faciles.',
  'L''ambition est en g‚n‚ral satisfaite. N''est pas un facteur',
  'd''entente avec le sexe oppos‚. Incompatibilit‚ d''humeur.',
  'Favorable … la richesse et aux biens fonciers. Le mariage peut',
  'ˆtre riche mais la vie sentimentale vide. On se sent seul au',
  'milieu des fˆtes, inquiet et incompris. D‚bauche.',
  'Pr‚dispos‚ … la d‚sillusion sentimentale. Les sentiments exposent',
  '… la tromperie de l''entourage tout en disposant aux go–ts',
  'sensuels bizarres. Satisfactions affectives tardives.',
  'Le caractŠre est doux et parfois teinte de m‚lancolie et de',
  'romantisme. On est d‚vou‚ et soumis tout en conservant une',
  'personnalit‚ originale. TrŠs bonne r‚sistance physique.',
  'La personnalit‚ est artistique, sympathique et franche. Les',
  'conceptions originales favorisent la cr‚ation esth‚tique l''humeur',
  'est instable. Besoin de se faire remarquer. Chance.',
  'Les plaisirs et les joies viennent des autres et en g‚n‚ral du',
  'sexe oppos‚. Dispose … tromper son conjoint et … profiter de lui :',
  'compr‚hension pratique des choses. Talent.',
  'TrŠs favorable … la chance pure et aux appuis venant du sexe',
  'oppose. Les relations sont agr‚ables et utiles et contribuent …',
  'l''‚volution sociale. Recherche de la coquetterie.',
  'Les maux sont imaginaires et troublent le psychisme et le mental.',
  'Tendance … la rˆverie et aux sentiments, … la bienveillance et …',
  'la facilit‚. Imagination f‚conde. rotisme.',
  'Les sentiments sont trŠs ‚lev‚s et les satisfactions affectives',
  'intenses. Augmente la sensibilit‚, l''indulgence, la compr‚hension',
  'et la g‚n‚rosit‚. Philanthropie et sagesse.',
  'Favorable … la fortune malgr‚ une vie mal organis‚e tant',
  'mat‚riellement que sentimentalement. On est bon et g‚n‚reux mais',
  'prodigue et lascif. Fuite devant l''effort et les tracas',
  'Une grande impressionnabilite cause de continuelles appr‚hensions',
  ': on raisonne difficilement ses sentiments. La vie mat‚rielle est',
  'satisfaisante. Vieillesse entour‚e d''affection',
  'Les qualit‚s de courage, d‚vouement, activit‚ et esprit de justice',
  'dominent. Amour du panache, du bruit et de la lumiŠre. On',
  'n''analyse pas : on accepte ou rejette tout d''un bloc.',
  'Le mental est puissant et la r‚sistance physique permet de gros',
  'efforts. L''esprit est trŠs combatif et susceptible. La confiance',
  'en soi favorise les r‚ussites mˆme hasardeuses.',
  'Hardiesse dans les entreprises. Optimisme et confiance. Fait',
  'r‚ussir les choses au-dessus de ses moyens. Aptitudes au',
  'commandement et sens politique. Combat pour la bonne cause',
  'Augmente l''app‚tit sexuel qui peut aider au succŠs social et',
  'professionnel. Nette dominante passionnelle qui entrave parfois',
  'l''ascension. MŠne parfois … des scandales utiles.',
  'La vitalit‚ et le courage moral aident … la r‚ussite. Le',
  'temp‚rament est passionn‚, amoureux et souvent lascif et de ce',
  'fait rarement fidŠle sexuellement. On va droit au but.',
  'Le jugement est sain et l''intelligence vive. On privil‚gi‚ le',
  'c“t‚ pratique et on ne s''encombre pas de d‚tails inutiles on sait',
  'employer la violence pour atteindre ses buts.',
  'L''activit‚ est souvent d‚sordonn‚e et inutile. Comportement',
  't‚m‚raire et violent. Grand besoin de dire et de faire ce que',
  'l''on pense. La jalousie perturbe souvent les sentiments.',
  'La t‚m‚rit‚ s''allie … la prudence et … la r‚flexion. L''ambition',
  'sait attendre son heure. Les d‚cisions sont fermes et l''effort',
  'constant. Tendance … fixer les sentiments',
  'Une souplesse physique et morale s''allie … une vitalit‚ nerveuse',
  'avec force et virilit‚. Les r‚flexes sont rapides. On est',
  'd‚brouillard et habile. Don d''‚locution. Bavardage.',
  'L''activit‚ intellectuelle s''allie … l''esprit d''entreprise. On',
  'veut souvent trop entreprendre … la fois. Impatience. Confiance en',
  'soi, pr‚tention et bluff. Fait les sportifs.',
  'Besoin d''agir et de faire toujours quelque chose. Puissante',
  'vitalit‚ nerveuse et r‚sistance … la maladie. Amour de l''argent',
  'et du pouvoir qu''il procure. Esprit sportif.',
  'Grande r‚sistance physique, vitalit‚ et virilit‚. L''esprit manque',
  'd''ordre et de m‚thode. Go–t pour le jeu et les sp‚culations. On',
  'est entour‚ de bonnes volont‚s. Action.',
  'Les id‚es sont plus nombreuses que les possibilit‚s de les',
  'r‚aliser. Souvent l''esprit s''exalte et prend un h‚ros pour',
  'exemple. Beaucoup de volont‚ mais la pers‚v‚rance manque.',
  'Les sautes d''humeur sont fr‚quentes et il faut lutter pour',
  'vaincre certaines inimiti‚s. L''esprit est bohŠme et incite …',
  'vivre au jour le jour. Enthousiasme et optimisme.',
  'Favorable … l''action. Permet de triompher de l''adversit‚ et des',
  'ennuis qui sont nombreux. Les projets sont hardis et l''esprit',
  'd''entreprise mŠne les choses … bonne fin. Courage.',
  'On est amoureux de la v‚rit‚ et des choses claires. On parle trop',
  'franc et on manque de tact : on se cr‚e des ennemis. Les forces',
  'perdues se r‚cupŠrent rapidement. Hardiesse.',
  'Plus d''aptitude pour le commandement que pour l''ob‚issance. On',
  'se r‚volte facilement … la moindre contrainte. Indication de',
  'triomphe dans les luttes. L''activit‚ est d‚bordante.',
  'On est bon, cl‚ment et parfois magnanime dans la victoire. Un',
  'manque de patience et le d‚sir d''ˆtre ob‚i causent trŠs souvent',
  'des discordes avec l''entourage ou la famille.',
  'On est franc et on a un besoin instinctif de se confier et de',
  'd‚voiler ses projets. Rend bon, serviable et humain et une',
  'tendance … jouer les don quichotte. Extravagance.',
  'Indique le triomphe aprŠs de nombreuses luttes. Le caractŠre est',
  'droit et fort, audacieux et m‚prise le danger. On rend facilement',
  'service. On est plus respect‚ qu''aim‚. Activit‚.',
  'Autant d''activit‚ morale que physique : on se d‚pens‚ dans tous',
  'les domaines. Grand amour de l''argent par go–t pour la d‚pens‚.',
  'TrŠs favorable aux sciences pratiques. Scepticisme.',
  'Possibilit‚ de faire de gros efforts. Le caractŠre est entier et',
  'g‚n‚ralement jaloux. Les luttes sont nombreuses et la ruse',
  's''allie souvent … la force pour vaincre. Querelles.',
  'On est excessif en tout tant dans la joie que dans la peine. Les',
  'sentiments nuisent g‚n‚ralement aux affaires. Les obligations',
  'empoisonnent l''existence. Satisfactions mat‚rielles.',
  'L''esprit d''entreprise est grand et permet de r‚aliser les',
  'conceptions les plus hardies. On va droit au but sans perdre son',
  'temps. Dispose au travail suivi. Amour de la vie.',
  'Dispositions trŠs marqu‚es pour la l‚gislature. Le courage',
  'physique n''est pas consid‚rable. De nombreux d‚sappointements',
  'sentimentaux sont … redouter. Un grand amour est possible.',
  'Les d‚sirs et les passions sont intenses et les instincts se',
  'donnent libre cours. On est impulsif et enthousiaste. Manque de',
  'pers‚v‚rance. La franchise brutale peut nuire.',
  'On est anim‚ d''un grand esprit d''ind‚pendance qui permet de',
  'r‚ussir dans une carriŠre lib‚rale. Les impulsions sont',
  'dangereuses, surtout effectivement. Belle intelligence.',
  'Beaucoup de franchise, de cordialit‚, de courage moral. Le',
  'caractŠre est souvent ombrageux et susceptible. AmŠne souvent la',
  'fortune quand on part d''une condition modeste.',
  'Le temp‚rament est instinctif et passionnel et permet de maŒtriser',
  'ses impulsions. La bravoure est consciente et on connaŒt les',
  'dangers. Qualit‚s de calme et de sang-froid.',
  'La pers‚v‚rance et le m‚rite empˆche de connaŒtre l''insuccŠs',
  'aptitudes pour la chimie et les recherches scientifiques. Les',
  'satisfactions de l''esprit priment sur les joies du coeur',
  'Les plus gros efforts sont permis : grande force morale et esprit',
  'dominateur. On est craint et respecte. La destin‚e peut ˆtre',
  'brillante et les succŠs en amour nombreux. Vitalit‚',
  'Donne sant‚, force physique et virile. Les id‚es sont hardies et',
  'les conceptions se mat‚rialisent ais‚ment. Amour de la v‚rit‚ et',
  'de la logique. Grande curiosit‚ intellectuelle.',
  'On est entreprenant et audacieux, franc et manquant souvent de',
  'tact. La r‚sistance et la force physique sont grandes. Dons',
  'pratiques qui permettent de semer pour r‚colter.',
  'Rend souple et habile. L''‚locution est favoris‚e : orateur.',
  'L''esprit est critique et observateur et sait se montrer r‚serv‚',
  'et discret. La chance s''allie souvent aux r‚alit‚s.',
  'Les colŠres sont violentes mais tombent rapidement. On est d‚vou‚',
  'et reconnaissant, prompt … rendre service. On est sincŠre en',
  'amiti‚ comme en amour. Droit, loyal et probe.',
  'Facteur de maŒtrise et de commandement. Souvent les embarras',
  'financiers sont nombreux. On est ƒpre au gain. Les d‚saccords avec',
  'l''entourage et les associ‚s sont fr‚quents. Politique.',
  'La vitalit‚ est consid‚rable. On est plein d''audace dans la lutte',
  'et on ne recule pas devant les obstacles. Conduit … des actes',
  'imp‚tueux. L''esprit est m‚ditatif mais actif.',
  'La vie est mouvement‚e. Les d‚placements et les changements de',
  'situation sont fr‚quents. La personnalit‚ est puissante et',
  'sympathique. On sait se concilier des appuis puissants.',
  'On est actif et ‚nergique, entreprenant et pratique. Les obstacles',
  'sont ais‚ment renverses et on se complaŒt dans les luttes. Besoin',
  'de satisfaire des d‚sirs violents.',
  'Grande force vitale, sant‚ et r‚sistance physique. Dispose … la',
  'maŒtrise et au commandement. Les succŠs sexuels sont nombreux et',
  'satisfont l''amour-propre. Responsabilit‚ morale.',
  'La nature est bouillante et imp‚tueuse. L''activit‚ est puissante,',
  'd‚sordonn‚e et tumultueuse. L''esprit est occup‚ par mille',
  'projets. L''ambition est d‚vorante. Confiance en soi',
  'Rend fidŠle dans les amiti‚s et moins dans les amours. Tendance …',
  'la r‚volte physique et morale. Les d‚sirs sont passionn‚s et',
  'souvent violents. Amour de la conquˆte.',
  'Les projets les plus hardis sont men‚s … bonne fin avec le maximum',
  'de chances de succŠs. On ne tire pas toujours les b‚n‚fices',
  'espŠres. Se m‚fier d''un entourage jaloux.',
  'Les difficult‚s et les luttes sont plus nombreuses que puissantes.',
  'L''intelligence est brillante mais l''esprit est capricieux et',
  'imprudent. Conduit … entreprendre en grand.',
  'La force physique est parfois prodigieuse. La tˆte et le coeur sont',
  'perp‚tuellement en lutte. On aime et on souffre en silence. Les',
  'qualit‚s excentriques dominent. ExcŠs.',
  'On est d‚vou‚ aux amis et tenace dans ses rancunes. On est en',
  'butte … de nombreuses inimiti‚s et jalousies dont on souffre.',
  'Voyages nombreux et go–t prononce du changement.',
  'Rend sensible et ‚motif, imaginatif et irr‚fl‚chi. Le coeur domine',
  'la tˆte. N''est pas favorable … l''amour qui se r‚v‚l‚ trompeur et',
  'infidŠle. On cherche sa voie pendant longtemps.',
  'L''ascension est lente … se manifester. Permet g‚n‚ralement de',
  'triompher des luttes et d''exercer la profession qui plaŒt la',
  'famille est souvent plus nuisible qu''elle n''est utile.',
  'Une grande confiance en soi favorise la r‚ussite et les',
  'entreprises. L''ambition est puissante, calme et r‚solue,',
  '‚nergique et souple. Bont‚ dans un esprit de justice.',
  'On domine les autres. L''activit‚ est d‚bordante et les vues sont',
  'amples. Donne des ‚lans d''enthousiasme tout en gardant la tˆte',
  'froide. Jugement sain. Triomphe sur l''adversit‚.',
  'Le besoin de se d‚penser conduit … certains abus. Esprit de',
  'synthŠse. L''ambition est noble et la volont‚ est sans …-coup',
  'dispose au commandement, au n‚goce et … l''industrie. Vitalit‚',
  'go‹sme sans m‚chancet‚ et amour des plaisirs. Le sensualisme est',
  'puissant. La vie est aid‚e par la chance et conduit souvent … la',
  'facilit‚ et au calme. Capacit‚s de se d‚fendre.',
  'Bont‚ et indulgence pour soi-mˆme comme pour les autres. Le',
  'jugement est droit et l''intelligence bonne. Beaucoup de bon sens.',
  'On plaŒt aux femmes. Facilite l''ascension. Chance.',
  'Prodigalit‚ ou insouciance. Les succŠs sont dus … la jovialit‚ et',
  '… la bonhomme. La situation est ais‚e : facilite de gagner de',
  'l''argent et d''en d‚penser sans contrainte.',
  'Parfois une trop grande indulgence ressemble … la faiblesse.',
  'Douceur et bienveillance. Indication d''adultŠre, de tromperie et',
  'de discordes entre les conjoints. Facteur de renomm‚e.',
  'On aime les plaisirs et tout ce qui est bon, sans en abuser.',
  'Pr‚dispos‚ … occuper une position en vue. La profession peut',
  'obliger … voyager. L''ascension peut ˆtre difficile.',
  'Fait souvent passer l''argent avant l''amour. On est plaisant,',
  'beau parleur, courtois et sympathique. On est plus aim‚ qu''on',
  'aime soi-mˆme. On sait se cr‚er de nombreuses amiti‚s.',
  'Tendance g‚n‚rale … la mod‚ration allie au sens pratique, …',
  'l''organisation et au savoir-faire. Voyages fr‚quents. N''est pas',
  'toujours propice au mariage. Nombreuses sympathies.',
  'Le travail ou la profession sont facilit‚ par le savoir-faire et',
  'l''intelligence. On rencontre de nombreux appuis utiles et',
  'agr‚ables aidant au bien-ˆtre mat‚riel et affectif',
  'Les d‚cisions sont souvent flottantes car on veut m‚nager la',
  'chŠvre et le chou. Fait souvent manquer les occasions. Les',
  'd‚ceptions affectives sont fr‚quentes. Sant‚ r‚sistante.',
  'Bonne humeur et gaiet‚ dans un esprit accommodant et r‚sign‚. Le',
  'sensualisme est ‚lev‚ mais parfois ‚go‹ste. On n''aim‚ pas',
  'souffrir ni de voir souffrir autour de soi. D‚votion.',
  'Favorable au mariage, … l''amour et … la f‚condit‚. On est',
  'recherche pour sa jovialit‚. Le sens pratique est d‚velopp‚ :',
  'facilit‚s pour l''‚tude malgr‚ un esprit passif. Mod‚ration.',
  'Le sens pratique et l''organisation dispose … s''occuper de',
  'grandes affaires. Le succŠs professionnel est facilit‚ par la',
  'chance. Le mariage ou les associations aident au succŠs.',
  'L''ambition est satisfaite par l''activit‚ et les initiatives. La',
  'volont‚ est puissante, l''esprit vif et les d‚sirs fixes. Il y a',
  'du bon sens et une vue claire des choses pratiques.',
  'La vitalit‚ est remarquable et les maladies peu fr‚quentes. Donne',
  'beaucoup d''ambition, d''intelligence et de sagesse. Le destin est',
  'g‚n‚ralement favorable. Sympathies et faveurs.',
  'L''ambition est puissante mais manque de souplesse.',
  'Lattis-factions mat‚rielles solides. On est respect‚ et considŠre',
  'tant pour sa position que pour ses m‚rites. Mariage pr‚coce.',
  'Accorde les honneurs officiels, les charges et les emplois',
  'responsables. l‚vation continuelle dans la voie suivie. Nette',
  'tendance … avoir une cour autour de soi. Inimiti‚s.',
  'Les luttes sont d''autant plus nombreuses que l''ambition est',
  '‚lev‚e. L''activit‚ est d‚bordante et facilite l''accroissement',
  'des richesses. L''enthousiasme est r‚fl‚chi. Diplomatie',
  'Le caractŠre est bonasse, prudent et ruse. L''esprit entreprend',
  'mille choses qui sont abandonn‚es au fur et … mesure. Ind‚pendance',
  'et amour des plaisirs. Optimisme et ‚go‹sme.',
  'Rend doucereux et aimable : on cherche … plaire mais dans un but',
  'int‚ress‚. Le laisser-aller rend extravagant et autoritaire.',
  'Souvent contraire aux finances : sp‚culations.',
  'La vie mat‚rielle et sentimentale est conduite sans ordre ni',
  'm‚thode. On fait preuve d''une g‚n‚rosit‚ imprudente. On cherche …',
  'plaire et … faire plaisir. On ne refuse rien.',
  'La vie est bien organis‚e et les d‚sirs sont fixes.',
  'Intellectualit‚ et go–t prononce pour l''‚tude. La fortune peut',
  'venir d''un sort heureux : mariage ou h‚ritage. Loyaut‚.',
  'quilibre physique et bonne sant‚. Le caractŠre loyal est expansif',
  ': amour du bien-ˆtre. On s''efforce de faire r‚gner l''entente',
  'autour de soi. Le jugement est bon et logique.',
  'Rend ‚quilibre et prudent, avec mod‚ration et bon sens. On se',
  'laisse difficilement leurrer : on observe et ‚coute avec bont‚.',
  'Qualit‚s d''indulgence, parfois cr‚dule ou na‹f.',
  'Belle intelligence synth‚tique : le jugement est solide. On',
  'comprend et se fait comprendre facilement. L''esprit est porte …',
  'la vulgarisation. Amour du sobre et de la droiture.',
  'Peut ˆtre la marque d''une trŠs belle ascension toujours',
  'satisfaite. L''amour du bien-ˆtre pr‚dispos‚ … certains abus. Les',
  'biens mat‚riels et les honneurs viennent rapidement.',
  'Le caractŠre est autoritaire sous une apparence bon enfant.',
  'Recherche du commandement par les moyens de l''esprit. Pr‚dispos‚',
  'souvent … employer des proc‚d‚s malhonnˆtes.',
  'Les efforts sont souvent couronnes de succŠs. La volont‚ est ferme',
  'et souple … la fois : sens de l''opportunit‚. Permet d''agir … bon',
  'escient et avec habilet‚. D‚sir d''argent',
  'Pr‚dispos‚ souvent aux impulsions dangereuses. On est bas avec les',
  'puissants et tyrannique avec les faibles. Relations souvent',
  'dangereuses ou malhonnˆtes. Extravagance et bluff.',
  'L''adresse manuelle va de pair avec l''habilet‚ intellectuelle on',
  'est d‚brouillard et malin. On inspire confiance sans pour autant',
  'ˆtre tout a fait honnˆte. L''ascension est secrŠte.',
  'Facteur de long‚vit‚ qui dispose … une vie saine. On est',
  'autoritaire et paternel. La parole est facile et chaude. Amoureux',
  'par nature on ne se marie pas pour autant. C‚libat.',
  'Sens pratique et esprit organisateur. Savoir-faire politique ou',
  'commercial. Les voyages sont nombreux et lucratifs. volution',
  'morale et intellectuelle continuelle. Ascension.',
  'Dispose … ˆtre bienveillant et charitable sans ˆtre pour autant',
  'd‚sint‚ress‚. Sensible … la misŠre quand on en est t‚moin on',
  'l''‚vite pour ne pas ˆtre ‚mu. On aime bien vivre.',
  'On tient avant tout a ˆtre considŠre et respect‚. Accessible aux',
  'compliments on aime se mettre en vedette. Pratique et',
  'conservateur. Bonnes aptitudes pour l''argent et sp‚culations',
  'Favorable … la long‚vit‚. L''intelligence pratique porte vers le',
  'profit mat‚riel. Sans ˆtre avare on est int‚ress‚. On sem‚ pour',
  'r‚colter. La volont‚ est ferme et combative.',
  'Dispose … la n‚gligence, au mat‚rialisme et … la superstition les',
  'dissentiments sont fr‚quents avec la famille et avec l''entourage.',
  'Les amours sont souvent contrari‚es. go‹sme.',
  'On ne peut compter que sur soi pour satisfaire ses ambitions les',
  'appuis et la chance font souvent d‚faut. Rend parfois intol‚rant,',
  'orgueilleux ou vaniteux. On aime paraŒtre.',
  'Le mariage ou l''association repose plus sur l''int‚rˆt que sur',
  'l''affection. La vie familiale et le foyer sont troubles. Se',
  'm‚fier de la perte de consid‚ration suite … des procŠs.',
  'Go–t prononce pour les choses exactes et pratiques. Profond',
  'penseur qui s''en tient aux faits qu''il coordonne avec ses id‚es.',
  'L''esprit est tourne vers la po‚sie ou litt‚rature.',
  'Puissant orgueil intellectuel et grande confiance en sa valeur. Le',
  'sens pratique fait souvent d‚faut. Propice aux ‚tudes et au',
  'travail de l''esprit. Libert‚ morale contrari‚e.',
  'La pers‚v‚rance et l''organisation disposent heureusement aux',
  'efforts intellectuels. L''activit‚ c‚r‚brale est intense. La',
  'profession utilise des moyens qui sortent de l''ordinaire.',
  'L''esprit est original et cr‚ateur : on domine son milieu. La',
  'libert‚ morale est grande et les conceptions ‚lev‚es. On n''aim‚',
  'pas la contradiction. On ‚vite les discussions.',
  'On possŠde une bonne sant‚ et l''instinct de conservation est trŠs',
  'd‚velopp‚. Le caractŠre est aimable et facile et l''intelligence',
  'souple. Amour du bien-ˆtre et des plaisirs.',
  'Bon ‚quilibre physique et moral. La venue des richesses est',
  'facilit‚e par la chance. Pr‚dispos‚ … un emploi fixe. Peut',
  'indiquer une source de revenus myst‚rieuse. Mysticisme.',
  'On s''adapte … tous les milieux et … toutes les besognes.',
  'L''argent vient facilement et si fortune il y a, celle-ci fondra',
  'rapidement. On aime bien vivre et d‚penser. Chance.',
  'Puissant facteur de long‚vit‚. La vie est quitt‚ dans son',
  'ensemble. Les amiti‚s puissantes aident … l''avancement.',
  'Satisfactions d''amour-propre, bien-ˆtre et honneurs. Chance.',
  'La personnalit‚ tend … dominer autrui. On est violent, on tranche',
  'toujours et ne d‚noue jamais. La volont‚ est puissante quand il',
  's''agit de se satisfaire. Esprit entier.',
  'La force physique est plus r‚elle qu''apparente. On est fait pour',
  'commander et pour dominer. Duret‚ pour soi comme pour les autres.',
  'L''ambition est patiente et le travail suivi.',
  'Stabilit‚ physique et intelligence. La confiance absolue en soi',
  'rend d‚daigneux et empˆche de suivre de sages conseils.',
  'Alternatives d''optimisme et de pessimisme. CaractŠre ferme.',
  'L''‚quilibre physique est utile … l''habilite en affaires. Mauvais',
  '‚quilibre sensuel : les go–ts peuvent ˆtre d‚prav‚s. Le manque de',
  'ressort fait aller au plus facile. Lƒchet‚.',
  'L''esprit de conservation domine. Le caractŠre est patient,',
  'opiniƒtre et prudent. On ramŠne tout vers soi. Concentration et',
  '‚go‹sme. L''analyse domine. Les d‚tails sont importants.',
  'On gagne … ˆtre connu. L''intelligence est pratique. L''esprit de',
  'm‚thode domine toujours. Un air bourru et peu avenant cache',
  'souvent la timidit‚ et l''horreur des gens inconnus.',
  'L''organisme souffre des excŠs sensuels. La jalousie peut ˆtre',
  'excessive et perturber toute l''existence. Facteur de long‚vit‚',
  'malgr‚ une apparence souvent d‚licate. Opiniƒtre.',
  'Esprit discipline et patient, travailleur et circonspect. Le',
  'caractŠre n''est guŠre enjou‚ : il est s‚rieux et songeur. On ne',
  's''ennuie pas et on s''absorbe dans le travail personnel',
  'Le mental est puissant : il est raisonne, circonspect et prudent.',
  'L''esprit est droit et m‚ticuleux. Grande fixit‚ dans le d‚sir et',
  'besoin de faire mieux. Orgueil et s‚rieux.',
  'Les choses de l''esprit sont favoris‚es : philosophie et sciences.',
  'La situation mat‚rielle peut ˆtre brillante surtout dans la',
  'sp‚culation immobiliŠre. Affections stables.',
  'L''‚nergie est dominatrice et pousse … s''imposer. Intelligence',
  'orient‚e vers ce qui est utilitaire et pratique. L''habilet‚',
  'manuelle permet de r‚aliser ce que l''esprit con‡oit. Bon sens',
  'Donne de la bont‚, du calme et de l''orgueil. On aime entendre',
  'parler de ses travaux. On est susceptible, r‚sign‚ et capable de',
  'souffrir en silence. Indique la stabilit‚ mat‚rielle.',
  'L''intelligence est belle avec volont‚ et entˆtement. Grande',
  'r‚sistance passive. Les id‚es g‚niales s''enchevetrent dans les',
  'utopies. Type de l''inventeur malheureux et sp‚culateur.',
  'CaractŠre renferme, s‚vŠre, grave et lent dans l''expression. On',
  's''ext‚riorise peu et on ramŠne tout vers soi. Les finances sont',
  'd‚savantag‚es et souvent mauvaises. Laisser-aller.',
  'Porte … l''entˆtement dans les conceptions. Tendance … tout',
  'critiquer : on doute et se m‚fie de tout. Rend pessimiste et',
  'misanthrope … la suite d''entreprises avort‚es. ProcŠs.',
  'On est imaginatif et imbu de ses conceptions. Plus de souplesse',
  'morale que physique : ce qui permet de s''adapter aux',
  'circonstances. On se soucie de ceux que l''on aime.',
  'La stabilit‚ physique est grande et l''organisme r‚sistant. Donne',
  'une grande force d''ƒme permettant de surmonter les ‚preuves. Le',
  'jugement est droit et de bon conseil. go‹sme.',
  'L''esprit est discipline, circonspect, patient et fixe dans ses',
  'd‚sirs. Grande ambition … s''imposer intellectuellement.',
  'Dispositions pour les sciences et les math‚matiques. Calme.',
  'On n''aim‚ pas ˆtre d‚range dans ses habitudes. Rend ‚go‹ste et',
  'misanthrope. Conservateur des traditions. Qualit‚s de sobri‚t‚ et',
  'd''ind‚pendance. CaractŠre studieux. C‚libat.',
  'Les projets se r‚alisent avec pratique. L''activit‚ est',
  'utilitaire. On est s‚vŠre mais juste, plus craint qu''aim‚.',
  'Dispose … ˆtre autoritaire et … ne pas faire de concessions.',
  'Le caractŠre n''est pas gai et manque d''expansion. L''esprit est',
  'heureusement influence : raison et prudence. On est pointilleux',
  'sur l''honneur et respectueux des traditions.',
  'La raison est puissante et de bon conseil. Peut marquer',
  'l''ascension dans un m‚tier responsable. La vie priv‚e est calme',
  'et les d‚penses mod‚r‚es. Possibilit‚ de fortune.',
  'Le caractŠre manque de fermet‚ et de d‚cision allant parfois',
  'jusqu''… l''impuissance physique et morale. Pr‚dispos‚ au',
  'mysticisme, … la crainte et la m‚lancolie. Respectabilit‚.',
  'Le caractŠre est grave et l''esprit s‚rieux. Les joies de',
  'l''intellect priment sur les satisfactions mat‚rielles.',
  'L''intelligence est grande et ind‚pendante. Indice de pauvret‚',
  'Le physique et le mental sont ‚quilibr‚s. R‚sistance et force',
  'mŠnent souvent … l''‚go‹sme. La sensibilit‚ intellectuelle est',
  'd‚velopp‚e et les sentiments raffin‚s. Bon sens.',
  'L''esprit est ind‚pendant, indisciplin‚ pour les petites choses et',
  'appliqu‚ pour les grandes. Besoin de commander sans ˆtre',
  'tyrannique. On est fidŠle et sincŠre en amour.',
  'L''intelligence est belle, l''esprit ‚lev‚ et studieux. Une juste',
  'mesure se manifeste dans tous les domaines. Le sens pratique',
  'existe et les conceptions sont r‚alisables.',
  'L''organisme est puissant et ‚quilibre. Les rapports avec',
  'l''entourage sont satisfaisants. Dispositions … la mod‚ration',
  'permet souvent d''atteindre un ƒge avance. Go–t des honneurs.',
  'Donne de la vitalit‚ et de l''endurance sous une apparence parfois',
  'd‚bile. Rend taciturne, un peu ours. La r‚sistance physique et',
  'morale est in‚branlable. Raison dominant le coeur',
  'Besoin de domination. L''activit‚ de l''esprit est d‚bordante mais',
  'on se montre patient et r‚fl‚chi. L''intellect est m‚thodique et',
  'positif. Fait les chefs s‚vŠres et respectes.',
  'Pr‚dispos‚ … peu parler et … agir beaucoup. Les actes sont',
  'pr‚m‚dites. Rend responsable et organise. Le cerveau domine. On ne',
  'demande jamais grƒce. Porte … se venger cruellement.',
  'On est susceptible et on souffre de la critique. CaractŠre inquiet',
  'et ambitieux, fin et adroit. Porte … la timidit‚ envers le sexe',
  'oppos‚. Nombreuses blessures d''amour-propre.',
  'On est conservateur par essence et m‚fiant en pr‚sence de la',
  'nouveaut‚. La maŒtrise de soi est alli‚e … la pr‚voyance et … la',
  'prudence. Ne se laisse pas entraŒner par la passion.',
  'L''esprit est laborieux et la connaissance vient lentement. Manque',
  'de facilit‚s. Peut donner beaucoup de logique pour ‚craser ses',
  'contradicteurs avec des arguments concrets.',
  'Le caractŠre est bon, g‚n‚reux et plein de tact. On fuit les',
  'discussions et le bruit. Observation et respect de la loi. On est',
  'impartial et int‚gr‚ jusqu''au scrupule. Pers‚v‚rance.',
  'Favorise la vie familiale et att‚nue l''adversit‚ affective.',
  'Facilite l''adaptation aux d‚fauts de l''entourage : diminue',
  'parfois la puret‚ morale. G‚n‚ralement heureux d''ˆtre aim‚.',
  'Le caractŠre est grave, s‚rieux et m‚lancolique. Une grande',
  'sensibilit‚ int‚rieure laisse rarement voir ses sentiments.',
  'L''esprit est vif et p‚n‚trant et de bon conseil pour autrui.',
  'CaractŠre discipline, patient et circonspect. La r‚ussite qui',
  'vient de l''effort continu est favorise par le travail. Respect',
  'des traditions et de la famille. Esprit studieux.',
  'L''ambition est puissante et patiente. On conserve toujours le',
  'contr“le de soi-mˆme. Donne de la sagesse et du calme. On est',
  'sobre et organis‚, sobre et r‚fl‚chi. Esprit concret.',
  'La domination sur soi-mˆme et sur autrui est naturelle : on peut',
  's''imposer sans effort. Le travail et l''intelligence facilitent',
  'l''ascension. Joies de l''esprit et d''amour-propre.',
  'Le caractŠre est ferme et ‚nergique mais peut ‚prouver de',
  'profondes tristesse. Quand on prend une d‚cision, c''est en toute',
  'conscience. On a confiance en soi. Pers‚v‚rance.',
  'Peut pr‚sager une belle ascension dans un poste important et',
  'r‚mun‚rateur. Pr‚dispos‚ … la bont‚, au calme, … la r‚serv‚ et …',
  'la prudence. Grande force de persuasion.',
  'Facteur de long‚vit‚ malgr‚ mille maux et soucis de sant‚. Tracas',
  'dans les rapports avec le sexe oppose. Le mariage r‚pond rarement',
  'aux aspirations. Fort esprit d''ind‚pendance.',
  'Grand souci des convenances et du s‚rieux. On est capable d''en',
  'imposer et d''accepter de lourdes responsabilit‚s. L''esprit est',
  'sup‚rieur, original et ind‚pendant. Justice.',
  'Grand instinct de conservation. L''esprit est d‚ductif et',
  'intuitif. Permet de s''occuper avec succŠs de philosophie. Dons',
  'pour les sciences d''observation. Analyse et patience.',
  'Favorise ce qui demande de la discipline, de la patience et du',
  'temps. On aime ses habitudes et ne pas ˆtre d‚range. Les joies et',
  'les plaisirs sont d''ordre intellectuel. Fid‚lit‚',
  'Manque de sens pratique et de d‚cision. On ne sait pas choisir ses',
  'affections. D‚sagr‚ments professionnels et nombreuses inimiti‚s',
  'dans le travail. Retarde le mariage.',
  'Les r‚actions et les r‚flexes sont lents. La pers‚v‚rance dans',
  'l''effort fait d‚faut : manque de ressort et penchant pour la',
  'facilite. La r‚ussite peut ˆtre tardive et brillante',
  'Marque l''ind‚pendance outranciŠre et la volont‚ de ne pas se',
  'plier. L''esprit est ferme et audacieux. Les r‚actions sont avant',
  'tout intellectuelles. Les id‚es sont g‚niales.',
  'La puissance de raisonnement est grande et l''ambition ax‚e vers',
  'un but unique. Les d‚placements sont aventureux et p‚rilleux.',
  'Qualit‚s dominatrices et sens de l''opportunit‚.',
  'On a soif d''autorit‚ dans le but de faire triompher ses id‚es',
  'g‚n‚reuses : celles-ci sortent des sentiers battus et sont',
  'r‚volutionnaires. CaractŠre sincŠre et audacieux.',
  'Les entreprises financiŠres sont heureusement influenc‚es. La',
  'chance et les appuis aident un talent original et inventif. Le',
  'moral est ‚lev‚. Altruisme et d‚sir de plaire.',
  'Conduit aux excŠs dans tous les domaines. L''esprit est entier et',
  'absolu et ne supporte pas la contrainte. La volont‚ est violente',
  'et les passions c‚r‚brales commandent. Ambition.',
  'L''intelligence est active et erratique. Un mauvais ‚quilibre',
  'sexuel dispose aux ennuis sentimentaux ou amiti‚s bizarres. Les',
  'id‚es sont souvent utopiques, les engagements dangereux.',
  'Dispose … agir … contre-sens par esprit de contradiction.',
  'D‚favorable aux amours stables et … la vie domestique.',
  'L''impulsivit‚ est dangereuse. Vie complexe souvent d‚r‚gl‚e.',
  'Le mental est complexe. Les ennuis sentimentaux fr‚quents.',
  'L''‚nergie est dominatrice et permet parfois d''ˆtre un chef.',
  'Expose parfois … la malignit‚ et aux faveurs populaires.',
  'Le mental est puissant et l''intelligence capable de synthŠse et',
  'd''analyse. Les conceptions sont diverses et originales. Facilite',
  'les inventions et d‚couvertes. Force nerveuse.',
  'L''activit‚ mentale et sentimentale s''allie … la force vitale et',
  '… la r‚sistance nerveuse. Les initiatives sont nombreuses sens des',
  'responsabilit‚s. Les ‚v‚nements aident le destin.',
  'Puissant magn‚tisme allie … une grande r‚sistance physique et',
  'nerveuse. Sens de l''initiative et de l''opportunit‚. Audace',
  'besoin de s''imposer par orgueil et amour-propre. Bon sens.',
  'La vitalit‚ est d‚bordante et les conceptions utilitaires. On se',
  'fait admettre par l''entourage grƒce … sa grandeur d''ƒme et',
  'convictions solides. L''esprit ne s''abaisse jamais.',
  'Le caractŠre est jaloux et aigri par des insuccŠs r‚pŠtes. Le',
  'destin est impr‚visible : on cherche longtemps sa voie. Rend',
  'ind‚pendant et capricieux. On n''en fait qu''… sa tˆte.',
  'L''impulsion est dangereuse car longtemps frein‚e. N''est pas',
  'favorable … l''union l‚gale : on promet plus qu''on ne tient.',
  'Contraire … la sp‚culation. Donne des go–ts bizarres.',
  'Puissante activit‚ intellectuelle : les id‚es sont bizarres et',
  'parfois inqui‚tantes. Les id‚es arrˆt‚es et l''entˆtement sont',
  'contraires aux int‚rˆts sentimentaux et … la libert‚.',
  'La sensibilit‚ est souvent maladive. H‚sitation dans la voie que',
  'l''on choisit par manque de pers‚v‚rance. La r‚ussite peut venir',
  'd''une maniŠre inattendue. Professions multiples.',
  'Le besoin de commander est le but de l''ambition. CaractŠre',
  'ind‚pendant, optimiste, fier et g‚n‚reux dans le triomphe. On a',
  'l''‚toffe d''un chef. Id‚es originales et r‚volutionnaires',
  'La personnalit‚ est puissante et l''‚nergie dominatrice.',
  'L''intelligence et la confiance en soi facilitent les luttes.',
  'Continuelle ‚volution mentale : on veut toujours faire mieux',
  'Les dissentiments avec l''entourage sont fr‚quents et la vie',
  'familiale souvent d‚sorganis‚e. Le mariage r‚pond rarement aux',
  'd‚sirs. Difficult‚s professionnelles et sociales.',
  'L''excitation mentale est excessive et les efforts violents. Les',
  'luttes sont nombreuses et l''esprit est r‚volte. Manque de',
  'souplesse et d''adaptation. Les unions pŠsent moralement.',
  'Mauvaises aptitudes pour r‚ussir mat‚riellement mais belle',
  'r‚ussite intellectuelle. Heureuses dispositions pour la recherche',
  'ou la m‚decine. Le sens pratique fait d‚faut.',
  'L''esprit est d‚sint‚ress‚ mat‚riellement. On est ind‚pendant et',
  'original, susceptible et orgueilleux. Les affections sont',
  'intellectuelles et les jeux intellectuels plaisent. Orgueil.',
  'Les id‚es neuves et originales conduisent … la renomm‚e. Talent',
  'inventif certain qui permet de sortir du commun. Des revirements',
  'mat‚riels inattendus sont … craindre.',
  'Les qualit‚s intellectuelles sont remarquables et l''esprit',
  'fournit de grands efforts qui aboutissent … des r‚alisations',
  '‚tonnantes. Le flair est parfois extraordinaire en affaires.',
  'L''intelligence est remarquable et l''imagination d‚bordante.',
  'Marque l''originalit‚ et la nouveaut‚ surtout dans l''art.',
  'L''ascension est subite aprŠs des d‚buts difficiles. rudition',
  'L''esprit est pratique et novateur tant en science qu''en art. On',
  'est compr‚hensif aux besoins d''autrui et on sait se plier aux',
  '‚v‚nements. Sens de l''opportunit‚ et hardiesse. SuccŠs.',
  'La personnalit‚ est puissante et sort souvent de l''ordinaire ce',
  'qui touche … l''argent est naturellement favorise mais les',
  'app‚tits mat‚riels ne sont pas consid‚rables. Harmonie.',
  'Permet de s''‚lever par ses qualit‚s propres et par des coups de',
  'chance heureux. Grande r‚sistance nerveuse. On reste maŒtre de',
  'soi-mˆme et de ses affaires. Opportunisme.',
  'La puissance nerveuse est aussi grande que la force morale.',
  'L''intelligence est remarquable et l''esprit inventif. Porte …',
  '‚tudier les choses bizarres ou la m‚taphysique. Orgueil.',
  'Le raisonnement est puissant et l''ampleur de vue remarquable les',
  'conceptions neuves et hardies bouleversent l''ordre ‚tabli.',
  'Confiance en soi et foi en la puissance de l''esprit.',
  'Grande r‚sistance physique et force nerveuse. Les qualit‚s morales',
  'et intellectuelles sont bonnes : ‚l‚vation des pens‚es et',
  'conceptions id‚alistes. L''‚volution est constante',
  'Les intuitions sont heureuses et les conceptions originales.',
  'Manque de sens pratique et parfois d‚dain de l''argent. Rend',
  'expansif et dispose … fr‚quenter le monde. Aptitude politique',
  'Accorde force et vigueur ainsi qu''une grande agilit‚ mentale on',
  'est prudent, tenace et sobre. Les qualit‚s intellectuelles',
  'permettent d''avoir rapidement une place en vue. Talents.',
  'Favorable aux exploits sportifs : l''habilet‚ intellectuelle va de',
  'pair avec l''agilit‚ physique. Dispose aux voyages. Les',
  'conceptions originales se heurtent … l''esprit de routine',
  'Rend nerveux, inquiet et tourmente. On souffre mais r‚agit',
  'violemment. On agit, on va de l''avant et on r‚ussit. Favorise les',
  'd‚couvertes et inventions. Indice de voyages.',
  'L''esprit cherche, observ‚ et analyse. Dispose aux ‚tudes',
  'religieuses, psychologiques ou occultes. Permet de se mettre en',
  'avant et de cr‚er un groupement intellectuel nouveau.',
  'On veut ˆtre quelque''un : on est un chef. On accepte ses',
  'responsabilit‚s et les initiatives sont remarqu‚es. Rend',
  'individualiste, ind‚pendant et ‚go‹ste. Solitude.',
  'L''esprit est pratique et voit les choses et les gens sous leur',
  'angle v‚ritable. On sait tirer des conceptions les plus abstraites',
  'des rŠgles simples, utiles et applicables.',
  'On connaŒt exactement ses possibilit‚s. Bon jugement et dons',
  'd''observation. L''intuition est agissante. Pers‚v‚rance, r‚alisme',
  'et volont‚ conduisent droit au but. Fait les chefs.',
  'On tient fortement … ses convictions et on les impose au besoin',
  'par la force. L''esprit est original et l''activit‚ d‚bordante.',
  'Confiance en soi. CaractŠre libre. Long‚vit‚.',
  'La volont‚ est puissante et alli‚e … une grande confiance en sa',
  'valeur. L''esprit est porte vers tout ce qui est original et neuf.',
  'On sort des sentiers battus. Innovation.',
  'Permet de r‚ussir dans la voie suivie. On est bon et',
  'l''intelligence est r‚elle, sage et int‚gr‚. Porte plus … l''union',
  'intellectuelle que sentimentale. Nombreux voyages.',
  'Favorise toutes situations ind‚pendantes et intellectuelles.',
  'Profite … l''esprit de collaboration et d''innovation. Dispose …',
  'ˆtre suivi par une ‚quipe jeune et ardente. G‚nialit‚.',
  'Facult‚s d''observation et d''intuition : on est attir‚ par tout',
  'ce qui est bizarre ou inconnu. Dispose … s''occuper des autres et',
  '… les soigner. TrŠs belles qualit‚s morales.',
  'Donne un esprit inventif. Le caractŠre est plus capricieux que',
  'volontaire et plus rˆveur que r‚alisateur. L''ambition est faible',
  'et l''ascension pr‚caire. Donne du g‚nie intuitif.',
  'L''esprit manque de fermet‚ et de courage mais la chance est',
  'favorable : les circonstances aident souvent de maniŠre',
  'impr‚visible. Beaucoup d''intuition. Conseille l''association.',
  'On manque de jugement et la maniŠre de voir est fauss‚e. Le',
  'caractŠre est inconstant et jaloux. Le libre-arbitre est faible et',
  'les initiatives contrari‚es par la destin‚e.',
  'L''imagination conduit … des actes insens‚s et … des pertes',
  'financiŠres et affectives. L''absence de discipline incite …',
  'violer les lois. On se domine et profite de la chance.',
  'L''entˆtement est invincible et se cache sous une r‚signation',
  'apparente : l''orgueil est immense et ne s''ext‚riorise pas. On',
  'marche … fond au risque de se perdre. Vaste imagination.',
  'Rend irritable et met les nerfs … fleur de peau. Longs moments de',
  'passivit‚, suivis d''une activit‚ d‚bordante. L''entˆtement est',
  'n‚faste. Susceptibilit‚ et orgueil.',
  'L''imagination est trŠs active mais l''effort est contrari‚ par la',
  'difficult‚ de suivre une voie unique. Nombreux dissentiments avec',
  'le sexe oppos‚ et les parents.',
  'R‚elle r‚signation, d‚vouement, indulgence pour soi et les autres.',
  'Les sentiments et la sensibilit‚ sont intenses. Les affections',
  'sont absorbantes et g‚n‚ralement profitables.',
  'Grand d‚sir de concorde et de paix, ‚galit‚ d''humeur et d‚sir de',
  'plaire. Le temp‚rament est calme et les sentiments intenses.',
  'Satisfactions mat‚rielles et chance sp‚culative.',
  'TrŠs belles qualit‚s intellectuelles : intuition, m‚moire et',
  'imagination. Le psychisme est puissant. Flair en affaires et',
  'situation mat‚rielle favoris‚e par le mariage. D‚vouement.',
  'Les aspirations sont ‚lev‚es : sentimentalit‚ et sensualit‚.',
  'Favorable … tout ce qui est mat‚riel et sp‚culatif. Rend plus apte',
  '… la d‚fense qu''… l''attaque. Besoin d''appuis.',
  'Amour de l''ancien et de la tradition. Esprit conservateur. TrŠs',
  'favorable aux op‚rations de bourse et aux sp‚culations. On est',
  'meilleur conseil pour autrui que pour soi-mˆme.',
  'Favorable … l''imagination et … la m‚moire et … la',
  'parapsy-chologie. Les d‚cisions sont lentes et les r‚alisations',
  'plus lentes encore : la minutie et la pr‚cision freinent l''action',
  'Une compr‚hension consciente et inconsciente des choses pousse …',
  'un certain mysticisme et besoin de se d‚vouer. On accepte beaucoup',
  'par d‚sir de paix, ou par int‚rˆt.',
  'Inqui‚tude sous une impassibilit‚ apparente. Tendance … exag‚rer',
  'l''importance des ennuis. Superstition et mysticisme souvent',
  'exaltation maladive suivie de sombres abattements.',
  'L''amour de l''ancien, du mystŠre et le sens artistique sont',
  'd‚velopp‚s. Les appuis sont nombreux et viennent surtout des',
  'parents et d''amis ƒges. Le psychisme est puissant.',
  'Une grande force d''inertie et de r‚sistance morale sous une',
  'apparence douce et r‚sign‚e. On s''adapte facilement aux',
  'circonstances. Rend discret et indulgent. Imagination.',
  'La sensibilit‚ excessive peut causer des perturbations nerveuses',
  'mais on cache sa peine et on souffre en silence. Grand besoin',
  'd''affection et de protection. Indulgence.',
  'L''esprit est intuitif et magn‚tique. L''argent est gagn‚',
  'facilement et peut venir d''une profession peu commune ou par des',
  'moyens caches. Favorable au jeu et … la sp‚culation.',
  'On s''abandonne facilement avec une grande sentimentalit‚. Dispose',
  'au rˆve et au romanesque : la force est dans la passivit‚.',
  'Imagination puissante et vie m‚ditative.',
  'Le caractŠre est sobre, prudent et sage. Le mental est bon et le',
  'psychisme puissant. L''esprit est orient‚ vers ce qui est noble et',
  'raffine. Beaucoup de bont‚ et grandeur d''ƒme.',
  'L''esprit est patient, circonspect et discipline. Une belle',
  'intelligence permet de r‚elles possibilit‚s de d‚veloppement',
  'psychique. Aptitude pour l''abstrait. Tradition, conservation',
  'L''esprit est tol‚rant et respectueux des institutions et des',
  'lois. Grande indulgence pour autrui : on fait de nombreuses',
  'concessions. Besoin naturel de se confier.',
  'Les satisfactions financiŠres sont r‚elles. Le travail et les',
  'gains sont aises, parfois mˆme scandaleux. La chance aide souvent',
  'surtout au point de vue sentimental.',
  'Dispose … la paresse ou du moins orient‚ vers la facilit‚ : sujet',
  'aux erreurs grossiŠres. Tendance … s''occuper des affaires des',
  'autres. Les amiti‚s sont int‚ress‚es. Curiosit‚',
  'L''esprit est parfois orient‚ vers le mal et la crainte peut',
  'conduire … des actes irr‚fl‚chis. L''‚go‹sme et le caprice',
  'dominent. Les sp‚culations financiŠres sont … d‚conseiller.',
  'La vie sentimentale est d‚sorganis‚e mais un mariage riche est',
  'possible. Dispose … la lassitude, … l''abattement et …',
  'l''irritation nerveuse. Satisfactions mat‚rielles probables',
  'Le sens pratique fait d‚faut et les erreurs et imprudences en',
  'matiŠre d''argent sont … craindre. Indique souvent une union avec',
  'un conjoint plus ƒge. Difficult‚s familiales.',
  'Grand d‚sir d''‚l‚vation intellectuelle, de concorde et de paix.',
  'Le contr“le du moi permet avec l''ƒge de dominer les passions.',
  'L''union facilite le travail et les finances.',
  'On se sent langoureux, m‚lancolique et fatigue. L''imagination',
  'l''emport‚ sur la raison. Sentimentalement on accepte ce qui est.',
  'On ne voit pas toujours les choses sous un angle exact.',
  'L''esprit passe les pens‚es au crible de la raison pure.',
  'L''imagination est disciplin‚e et on ne prend pas ses rˆves pour',
  'des r‚alit‚s. Donne un certain empire sur soi.',
  'Contribue aux satisfactions mat‚rielles malgr‚ un certain d‚sordre',
  'moral ou manque d''organisation. Grande soumission et parfois',
  'lƒchet‚. Crainte du lendemain et de l''inconnu.',
  'On est habile et souvent l''adresse manuelle permet de r‚ussir',
  'dans de nombreux domaines. L''argent rentre ais‚ment autant par le',
  'm‚rite que par la chance. Sentiments complexes',
  'Sans ˆtre fonciŠrement m‚chant on est insensible … ce qui ne',
  'concerne pas. Continuelle crainte du lendemain. Souvent les',
  'moindres faits prennent l''apparence de catastrophes.',
  'L''imagination est dangereuse. La r‚alisation des conceptions peut',
  'conduire … des r‚sultats mis‚rables. On se croit souvent',
  'incompris. Les troubles sexuels sont fr‚quents.',
  'Dispose … la paresse et l''abattement. Souvent la sexualit‚ est',
  'dangereuse pour l''‚quilibre physique et mentale. D‚sir de paix et',
  'de concorde : passivit‚ en amour. Tromperies.',
  'Le caractŠre est bon et sincŠre, intuitif et imaginatif. L''esprit',
  'est ouvert … la spiritualit‚ avec bon sens et gaiet‚. On est',
  'charitable et d‚vou‚ : on paie de sa personne',
  'Une grande sensibilit‚ fait r‚agir douloureusement … la misŠre des',
  'autres. On accepte son sort car on trouve toujours plus malheureux',
  'que soi. L''ambition est limit‚e.',
  'L''imagination est puissante et l''esprit contemplatif. Peu de',
  'sens pratique. Les id‚es sont lumineuses et mal exploit‚es. La',
  'chance aide le mat‚riel : on vit ses rˆves sans danger.',
  'Les go–ts sont modestes et l''activit‚ physique restreinte. On se',
  'complaŒt dans le rˆve et les ‚tudes abstraites. D‚sir de percer',
  'les mystŠres de l''au-del…. l‚vation spirituelle.',
  'On voit les choses et les gens tels qu''ils sont. L''esprit est',
  'patient, discipline et circonspect. Puissant instinct de',
  'conservation : on fuit tout ce qui peut faire souffrir.',
  'Le caractŠre est discipline et soumis mais la sensibilit‚ peut',
  'conduire … des actes violents et impulsifs. Le mariage augmente',
  'les possibilit‚s d''ascension grƒce au conjoint.',
  'TrŠs favorable … la sant‚ et aux affaires : beaucoup de chance',
  'mat‚rielle. La situation tend toujours vers le mieux. Le',
  'savoir-faire et la finesse facilitent les rapports.',
  'Les conceptions souples et adroites facilitent les rapports avec',
  'autrui. L''esprit est soumis et la chance mat‚rielle bonne. La vie',
  'intime est souvent troubl‚e par les int‚rˆts.',
  'La sensibilit‚, l''intuition et l''imagination rendent l''esprit',
  'inventif et ing‚nieux. TrŠs favorable aux redressements des',
  'situations. Propice au mariage et au bien-ˆtre. Impr‚vus.',
  'On souffre par manque de fermet‚. Le caractŠre est craintif et',
  'pessimiste et se d‚courage facilement. Le destin n''est pas',
  'mauvais mais la libert‚ sentimentale fait souvent d‚faut',
  'Le caractŠre est sensible, intuitif et la m‚moire heureuse.',
  'L''imagination est capable de voyances concrŠtes. Manque de',
  'discernement dans le choix des relations. Adaptabilit‚.',
  'Les aspirations sont ‚lev‚es. Le caractŠre est sensible et',
  'sentimental, sympathique et doux. Le destin est cl‚ment et offre',
  'de r‚elles possibilit‚s sans gros efforts. Chance.',
  'Puissant instinct de conservation. On parvient … maintenir',
  'l''organisme en parfait ‚quilibre. On sent les choses avec',
  'sensitivit‚, intuition et imagination. Intelligence souple.',
  'On voit les choses avec optimisme. Le flair permet de se diriger',
  'vers ce qui est favorable et agr‚able. Les plaisirs sont',
  'raisonnables et on donne plus qu''on ne prend en amour.',
  'TrŠs belles qualit‚s morales. Le caractŠre est ferme et les',
  'sentiments altruistes. On est capable de sacrifices pour venir en',
  'aide … son prochain. La parole vaut l''‚crit.',
  'La situation mat‚rielle tend continuellement vers le mieux.',
  'L''ambition est faible et fortement soumise au destin. La vie est',
  'souvent calme, bourgeoise et monotone. Sagesse.',
  'On peut pas rester inactif : besoin d''agir mais avec prudence et',
  'm‚fiance de soi-mˆme. On est courageux et hardi. Pr‚dispos‚ …',
  'l''h‚ro‹sme et … l''esprit de sacrifice. Violence',
  'Grande r‚sistance physique alli‚e au courage. Pr‚dispos‚ … forcer',
  'les situations qui ne conviennent pas : on n''aim‚ pas que quelque',
  'chose ou quelque''un vous r‚siste ou ‚chapp‚.',
  'Indice de long‚vit‚ et de bonne sant‚. Les d‚placements peuvent',
  'ˆtre nombreux. On aime se faire admirer et on souffre souvent de',
  'ne pas ˆtre aim‚. SuccŠs sentimentaux.',
  'Amour de la v‚rit‚ et de la logique. On sait se taire. Les',
  'connaissances sont parfois dispers‚es et superficielles. Les',
  'luttes sont nombreuses et la vie sentimentale complexe.',
  'La chaleur des affections n''est pas favorable aux amours. Les',
  'engagements sont dangereux et la jalousie empoisonne l''existence.',
  'Nombreuses blessures d''amour-propre. Sacrifice.',
  'Les sentiments sont instables et trompeurs, passifs et souvent',
  'fuyants. L''amour contribu‚ trŠs fr‚quemment … l''ascension. La',
  'sensualit‚ est puissante. Masochisme.',
  'TrŠs grande r‚sistance physique. Aide souvent … la c‚l‚brit‚ les',
  'jeux, les plaisirs et les relations sont favorises. Un deuxiŠme',
  'mariage est souvent meilleur que le premier.',
  'Forte indication d''adultŠre et de discorde dans la sexualit‚ les',
  'passions sont toujours violentes : le don de soi est entier et les',
  'ruptures fr‚quentes. Charme et ‚go‹sme.',
  'On est rarement satisfait de son sort. L''amour pour l''argent est',
  'd‚velopp‚ et le besoin de s''en procurer prime avant tout et les',
  'moyens employ‚s pas toujours honnˆtes. Bavardage.',
  'On aime les choses et les combinaisons compliqu‚es. On sait se',
  'sortir d''embarras et contourner les obstacles, maŒtriser son',
  'impatience et ses impulsions. Souvent don des langues.',
  'Souvent la r‚ussite est rapide dans la voie suivie : le commerce',
  'et les professions lib‚rales sont favorises. Le don des langues',
  'est d‚velopp‚. Grande force mentale.',
  'L''‚quilibre physique est aussi instable que l''humeur. Pr‚dispos‚',
  '… l''envie et … l''ingratitude. Le caractŠre est indisciplin‚ et',
  'recherche souvent les fr‚quentations louches',
  'Les bonnes qualit‚s morales sont souvent d‚ficientes car le besoin',
  'de jouissance ne peut ˆtre contenu. Indique la paresse et',
  'l''indiscipline. La vie est mouvement‚e. S‚duction',
  'On supporte difficilement la contrainte et on tend … se retirer',
  'dans la solitude. L''imagination est trŠs d‚velopp‚e craindre les',
  'pertes financiŠres et d''honorabilit‚. Rancune.',
  'On se soumet difficilement … un travail r‚gulier et on v‚gŠte',
  'longtemps avant de trouver sa voie. On se complaŒt souvent en',
  'mauvaise compagnie. Penchant vers l''introversion.',
  'Les insatisfactions dans la vie viennent g‚n‚ralement … la suite',
  'd''imprudences ou d''excŠs. Les amours sont souvent v‚nales et une',
  'certaine moralit‚ fait vivre d''exp‚dients.',
  'Le caractŠre est prudent, taciturne et discret. On sait plaider le',
  'faux pour savoir le vrai. L''entˆtement et l''obstination sont',
  'alli‚s … l''habilet‚ intellectuelle.',
  'On h‚sit‚ longtemps avant d''agir mais lorqu''une d‚cision est',
  'prise elle est d‚finitive. Quand les buts sont atteints et une',
  'fois dans la place on s''y maintient. Ingratitude.',
  'On cache difficilement ses projets. Les possibilit‚s de naissance',
  'sont r‚elles mais le destin est souvent contraire. Les faits les',
  'plus invraisemblables arrivent dans la vie.',
  'Un manque d''organisation dispose … se laisser fasciner par les',
  'd‚tails sans voir l''ensemble des choses. La morale est assez',
  '‚lastique, tant en affaires qu''en amour. Ennuis l‚gaux',
  'Le caractŠre se montre souvent m‚chant : on cherche querelle …',
  'tout le monde mˆme … soi-mˆme. L''indisciplin‚ et la malice',
  'peuvent causer de graves difficult‚s l‚gales. Intelligence.',
  'Le jugement est bon : on aime les ‚tudes et les sciences. Les',
  'accŠs de colŠre s''att‚nuent avec l''ƒge. On recherche toujours le',
  'pourquoi et le comment des choses. Analyse.',
  'L''esprit est avide de savoir pendant tout le cours de',
  'l''existence. R‚els dons des langues ‚trangŠres. TrŠs bonnes',
  'capacit‚s d''analyse : favorise l''esprit de recherche.',
  'La r‚sistance et l''‚quilibre nerveux sont g‚n‚ralement bons et',
  'donnent le go–t pour le travail et l''‚tude. TrŠs favorable …',
  'l''artisanat. Les fr‚quentations sont … surveiller.',
  'Il y a toujours exag‚ration quand le coeur ou les sens entrent en',
  'action : abandon de soi et esprit de sacrifice. On s''enflamme au',
  'moindre contact amoureux. Chance en argent.',
  'La quˆte du plaisir fait partie des principaux objectifs : on vit',
  'avant tout pour s‚duire. On aime rapprocher les individus et les',
  'aider … vivre en harmonie. Dons artistiques',
  'TrŠs bonne sant‚. L''affectivit‚ est d''un ordre ‚lev‚ et les',
  'finances sont g‚n‚ralement aid‚es par l''amour ou par ce qui en',
  'donne l''illusion. Amour du cr‚atif et de l''in‚dit.',
  'Le caractŠre est amoureux. L''esprit de conservation est trŠs',
  'd‚velopp‚. Facilit‚s … entrer en relation avec les personnes',
  'ƒg‚es. Les ruptures sont fr‚quentes et difficiles.',
  'La vitalit‚ est puissante et le caractŠre violent et aigu. Rend',
  'rude et parfois agressif, peu patient mais fonciŠrement bon et',
  'indulgent aux fautes d''autrui. On pardonne beaucoup.',
  'Le caractŠre est plus militant que militaire et cherche plus …',
  'convaincre qu''… vaincre. On veut faire admettre sa foi mais sans',
  'l''imposer. Rend psychologue, juste et inquisiteur.',
  'L''intelligence est vive et objective : elle s''int‚ress‚ surtout',
  'aux faits. L''esprit est curieux, chercheur et intuitif : on perce',
  'les secrets et d‚chiffr‚ les ‚nigmes.',
  'Le caractŠre est orgueilleux et susceptible et se montre',
  'magnanime. Go–t des r‚formes et des formules nouvelles et',
  'r‚volutionnaires. Nombreuses luttes et inimiti‚s. Aventure.',
  'Dispose au commandement par des moyens d‚tourn‚s. Porte aux abus',
  'dans beaucoup de domaines. Le travail est excessif et les amours',
  'souvent violentes. Propice … l''effort soutenu.',
  'La vitalit‚ et la sant‚ se maintiennent malgr‚ de nombreux abus',
  'des plaisirs. Le besoin d''argent conduit parfois … contourner les',
  'lois et … ne pas s''embarrasser de l''honneur.',
  'Expose souvent aux querelles et aux heurts. Arrogance et lƒchet‚',
  'en affaires comme en amour. La situation est tributaire de',
  'l''effort et du m‚rite. Domination par la diplomatie',
  'Le caractŠre est ruse et ‚loquent, jovial et doucereux : on sait y',
  'faire, on trompe, filouter et truqu‚ avec audace et libert‚.',
  'Grandes aptitudes … la politique. Pouvoir.',
  'Indique la long‚vit‚. On ‚coute plus qu''on ne parle et on est',
  'plus apte … la d‚fense qu''… l''attaque. La sensualit‚ prime sur',
  'le sentimental : les passions sont c‚r‚brales.',
  'Le caractŠre est ‚nergique et sait se contenir quand c''est',
  'n‚cessaire. On est prudent et opiniƒtre. On pŠse ses actes et ses',
  'mots. L''esprit est m‚thodique et s''attache aux faits.',
  'L''activit‚ physique va de pair avec l''activit‚ mentale : le',
  'cerveau domine. Sens des responsabilit‚s. On accepte difficilement',
  'd''ˆtre vaincu. Le sens du pardon fait d‚faut.',
  'Le caractŠre est ing‚nieux : on sait attirer … soi les nombreuses',
  'sympathies utiles … l''ascension. Rend soup‡onneux et jaloux. Peut',
  'ˆtre l''indice d''une situation importante.',
  'L''activit‚ de l''imagination fait qu''on est en continuelle',
  'opposition avec la routine. Dispose aux ‚tudes occultes en ayant',
  'de elles dispositions dans ce sens. R‚volt‚s.',
  'L''entendement est rapide. L''id‚alisme est place bien au-dessus',
  'du mat‚riel : l''esprit doit vaincre la matiŠre. La vitalit‚ est',
  'soutenue par un psychisme puissant. G‚nialit‚',
  'Le caractŠre … soif de libert‚, de libert‚ morale surtout. On sait',
  'se rendre libre : on s''isole mentalement et on fuit le monde.',
  'L''ascension est due au m‚rite. Id‚es g‚niales.',
  'TrŠs bon ‚quilibre physique. L''activit‚ intellectuelle permet une',
  'vision intuitive et totale des r‚alit‚s. Les satisfactions',
  'd''amour-propre priment. Hyper-g‚nialit‚.',
  'Facteur de long‚vit‚ mais manque de r‚sistance physique. La',
  'situation mat‚rielle est g‚n‚ralement en ascension continuelle. La',
  'fid‚lit‚ n''est pas une vertu capitale.',
  'Accorde g‚n‚ralement de la chance et permet de r‚ussir dans les',
  'professions m‚dicales et param‚dicales. Les perceptions sont',
  'intenses et l''univers imagin‚ semble souvent r‚el.',
  'L''imagination est bien canalis‚e et permet d''ˆtre optimiste et',
  'r‚sign‚. L''‚quilibre psychique n''est pas toujours bon. On fait',
  'souvent preuve de passivit‚ ou de n‚gligence.',
  'Les sentiments sont affines. Le moral est bon. Grand amour du',
  'bien-ˆtre et d‚sir de paix et de concorde. Peut marquer un mariage',
  'riche avec un conjoint ƒge. Passivit‚ en amour.',
  'Vous ˆtes entiŠrement domine par des forces centrifuges qui vous',
  'incitent aux actes excentriques. Votre trŠs grande activit‚ vous',
  'oblige … vous ‚loigner de votre centre naturel et il en r‚sulte',
  'des actes impulsifs et irr‚fl‚chis. Les conseils les plus sages',
  'ont peu de prise sur vos d‚cisions. La confiance en vous-mˆme va',
  'de pair avec votre orgueil et votre entˆtement. Vous ˆtes',
  'tranchant et arrogant imp‚rieux et tyrannique, r‚formateur et',
  'contradicteur. Vous ne manquez pas de logique et votre',
  'argumentation est directe et brutale. Vous ˆtes avare ou jaloux de',
  'vos pr‚rogatives : aussi aimez-vous votre conjoint et vos enfants',
  'vous gardez le pouvoir pour vous seul. Vous ˆtes ‚go‹ste.',
  'Vous ˆtes domine par des forces centripŠtes qui incitent … ramener',
  'tout vers vous. Vous ˆtes conduit … rester dans votre sphŠre et de',
  'ne vous en ‚loigner que fort peu. Vous vous arrangez toujours pour',
  'vous procurer le maximum d''avantages et de satisfactions. Une',
  'grande possession de vous-mˆme vous conduit … absorber',
  'l''entourage proche. Vous ˆtes au gain. Votre intelligence ne',
  's''encombre que de choses utiles. Vous ˆtes pers‚v‚rant et',
  'travailleur, savez ‚couter et vous taire, attendre votre heure',
  'sans impatience. Vous ˆtes g‚n‚ralement doux et paisible et savez',
  'contenir longtemps vos colŠres. TrŠs sensuel, votre amour est',
  '‚go‹ste et jaloux. Vous recevez souvent plus que vous ne donnez.',
  'Votre personnalit‚ est double qui sent beaucoup plus qu''elle ne',
  'raisonne. Votre mental est trŠs complexe, et votre intelligence',
  'est remarquable, parfois g‚niale, elle n''est pas de ce fait',
  'exempte de certains creux qui vous oriente dans une voie qui',
  '‚tonn‚. La compr‚hension est rapide et permet de trouver une',
  'solution heureuse aux problŠmes. Votre raisonnement et votre',
  'logique sont excellents. Vous avez une grande confiance en votre',
  'valeur mais votre susceptibilit‚ vous empˆche d''accepter la',
  'critique. Vous n''ˆtes pas au sens propre un travailleur mais',
  'plut“t un touche-…-tout. Vous vivez intens‚ment et n''ˆtes pas',
  'sentimentalement de tout repos. Vous ˆtes indulgent et g‚n‚reux.',
  'Votre caractŠre est changeant : ce qui vous rend amoureux des',
  'd‚placements et de la nouveaut‚. Vous aimez la famille et votre',
  'foyer pour lesquels vous ˆtes capable des plus grands d‚vouement.',
  'Vous ˆtes sociable, intelligent, poŠte, langoureux, craintif et',
  'imaginatif. Mauvais sens pratique. Vous ne voyez pas l''existence',
  'sous son angle r‚el et ˆtes domine par un grand besoin de vous',
  'attacher, d''ˆtre aim‚ et de vous donner. La souffrance physique',
  'vous est intol‚rable vos ‚motions sont fr‚quentes et souvent',
  'superficielles, les tracas laissent peu de traces car votre force',
  'd''inertie vous permet de vous isoler et de continuer … rˆver.',
  'Vous vivez de nombreuses passions mais vous manquez de stabilit‚.',
  'Vous ˆtes prompt … la colŠre et vous vous d‚fendez mieux que vous',
  'n''attaquez. Vous ne pardonnez pas les affronts et pouvez vous',
  'montrer cruel dans vos vengeances. Vous ne manquez pas de',
  'magnanimit‚. Votre m‚rite est ‚vident. L''esprit de justice existe',
  'car le bon sens, la logique et l''impartialit‚ se manifestent',
  'surtout lorsque''il s''agit des affaires des autres. Vous avez',
  'soif d''honneurs et savez vous faire remarquer. Vous manquez',
  'souvent de discr‚tion dans les ‚loges que vous vous d‚cernez. Vous',
  'avez du jugement, de la sagesse, de la discipline et le coup',
  'd''oeil. Votre soif de pouvoir vous octroie les qualit‚s peu',
  'communes qui appartiennent aux chefs. Votre ambition vous profite.',
  'La curiosit‚ et le besoin de connaŒtre et d''apprendre, de tout',
  'analyser et de tout diss‚quer, dominent en vous. Vous avez de',
  'l''ordre et de la m‚thode et savez d‚tailler et critiquer les',
  'choses les plus insignifiantes. Vous amenez … terme les choses que',
  'certains abandonneraient par manque de soin. Vous n''ˆtes pas trŠs',
  'courageux et sans ˆtre paresseux vous n''aimez ni l''effni la',
  'lutte. Vous ˆtes ing‚nieux et d‚brouillard dans les petites',
  'choses. Vous ˆtes un bricoleur soit intellectuel soit manuel. Vous',
  'avez un grand amour de la v‚rit‚ et de l''exp‚rience. Vos',
  'sentiments sont concrets et votre esprit est stable. La',
  'sensualit‚, parfois trŠs ‚lev‚e vous fait aimer ce qui est beau et',
  'bon.',
  'Vous avez un talent inventif et l''amour des formes. Votre',
  'caractŠre est franc, ouvert et communicatif. Votre esprit est',
  'ind‚cis et r‚clame la certitude avant d''agir. Vous vous inclinez',
  'devant la force et acceptez facilement les conceptions d''autrui.',
  'Vous recherchez de bonne heure un appui ou un soutient. Vous ˆtes',
  'voluptueux et porte sur les plaisirs des sens. Votre m‚rite est',
  'r‚el et vous savez vous adapter et vous plier aux circonstances.',
  'Vous avez le go–t du pittoresque, de la musique sentimentale et',
  'sensuelle. Vous n''ˆtes pas fait pour lutter : l''effort physique',
  'vous est insupportable. Vous avez besoin d''un maŒtre que vous',
  'admirez et craignez. Si vous ˆtes bien dirige, vous r‚ussirez.',
  'Vous avez une confiance en vous ou plus exactement vous ne',
  'craignez pas le danger. Vous ˆtes assure dans la lutte et',
  'l''obstacle excit‚ votre courage et votre audace. Vous savez ce',
  'que vous voulez et mettez tout en oeuvre pour satisfaire votre',
  'ambition. Votre esprit est critique, parfois acerbe et toujours',
  'taquin. Vos r‚parties sont promptes et vos paroles parfois',
  'cinglantes. Vous ˆtes intelligent, intuitif et observateur. Vous',
  'avez du doigt‚ et le coup d''oeil : on vous trompe difficilement.',
  'Vous savez vous faire ‚couter et vous commandez sans gestes ni',
  'paroles inutiles. Vos mots sont pŠses et portent juste. Vous ˆtes',
  'discret et r‚serv‚. Vous ne pardonnez pas l''affront et vous',
  'vengerez t“t ou tard',
  'Votre esprit est pacifique mais sait toujours parfaitement se',
  'd‚fendre. Vous avez autant de raison que de prudence, et si dans',
  'votre jeunesse vous avez ‚t‚ une tˆte br–l‚e, vous deviendrez avec',
  'l''ƒge pond‚r‚ et sage. Vous ˆtes amoureux, d‚vou‚ et g‚n‚reux,',
  'vous savez plaire et vous faire aimer. Votre timidit‚ disparaŒtra',
  'avec les ann‚es et vous vous imposerez. Vous avez le go–t du',
  'paradoxe et vous vous d‚vouez avec le plus grand d‚sint‚ressement.',
  'M‚lange d''‚go‹sme et de bont‚, de logique et de sot entˆtement.',
  'Vous aimez la vie et resterez longtemps jeune de coeur et d''ƒme.',
  'Votre intelligence est vive et votre m‚moire heureuse. Votre',
  'm‚rite est grand. Ambition patiente.',
  'Vous ˆtes trŠs complexe : vous pouvez ˆtre ordonn‚ et m‚thodique,',
  'ou anarchique et r‚volte. Votre dominante intellectuelle est',
  'l''analyse. Votre ind‚pendance d''esprit est outranciŠre et vos',
  'id‚es arrˆt‚es peuvent vous conduire aux pires erreurs. Votre',
  'besoin de connaŒtre et d''apprendre est immense. Vous voulez',
  'savoir le fond et le pourquoi des choses. Vous doutez, pensez et',
  'agissez en circuit ferme. Votre orgueil intellectuel et la',
  'confiance en votre savoir vous conduisent au parti-pris et … la',
  'mauvaise foi. Rarement vous admettez vous ˆtre trompe. Vous ˆtes',
  'pers‚v‚rant, patient, laborieux et calme. Votre rancune est',
  'tenace. Vous aimez et souffrez en silence. Vous ˆtes',
  'individualiste.',
  'Votre esprit est curieux et original et votre activit‚ mentale esr',
  'grande. Vous portez en vous le germe pr‚curseur d''une invention',
  'ou d‚couverte g‚niale. Votre nature est complexe et trouble, elle',
  'sent beaucoup plus qu''elle ne raisonne. Vous ˆtes par moments',
  'plein de d‚vouement et de bont‚, et … d''autres ingrat et ‚go‹ste,',
  'capricieux et contradictoire. Vous vous emballez pour toutes les',
  'nouveaut‚s, mais c''est un coup de foudre qui ne dure pas. Vous',
  'avez la sinc‚rit‚ du moment. Vous ˆtes enthousiaste et audacieux',
  'et savez faire le sacrifice de votre vie. Vous savez agir en',
  'pr‚sence du danger. Vous ˆtes souple et ouvert … toutes les',
  'propositions. Utopique et paradoxal.',
  'Vous ˆtes passif et r‚agissez passagŠrement et mollement aux',
  'impressions ext‚rieures. Vous ˆtes d‚termin‚ et les conseils et',
  'l''‚ducation ne vous empˆchent pas de garder vos qualit‚s de',
  'naissance. Votre esprit est versatile, et donn‚ raison … tout le',
  'monde pour avoir la paix. Vous promettez plus que vous ne tenez :',
  'votre mauvaise foi est ‚vidente mais il y a lieu de se demander si',
  'elle est consciente. Vous ˆtes un contemplatif ‚go‹ste et votre',
  'd‚vouement va … la famille et au foyer. Vous ˆtes un conservateur',
  'respectueux de l''autorit‚. Vous ˆtes intuitif et pressentez les',
  '‚v‚nements. Vous avez des dons de m‚dium. Vous ˆtes doux et',
  'charitable par sensiblerie. Indulgence.',
  'Le Soleil expose … la jalousie, … la vengeance, aux inimiti‚s',
  'puissantes et aux troubles familiaux. Par contre il accorde les',
  'honneurs, la renomm‚e, une attraction naturelle qui impose',
  'l''admiration et le respect. Il influence dans l''individu le moi',
  'g‚nial et expansif, la justice, l''application, la colŠre, la',
  'vengeance, l''ambition, l''orgueil, et le besoin de dominer. Dans',
  'la famille il repr‚sente le pŠre, le mari, et le protecteur. Dans',
  'la soci‚t‚ il repr‚sente les sup‚rieurs les officiels et les gens',
  'c‚lŠbres. Le Soleil correspond … tout ce qui ce passe de jour, il',
  'apporte chaleur et rayonnement tant moralement que physiquement.',
  'Dimanche.',
  'La Lune expose aux infortunes, aux inimiti‚s inconnues, … la',
  'discorde, … l''adultŠre, … la crainte, … la veulerie, et aux maux',
  'imaginaires. Par contre, elle accorde la chance pure, la',
  'f‚condit‚, les changements heureux et impr‚vus, la popularit‚ et',
  'les amiti‚s f‚minines. Elle influence dans l''individu le moi',
  'artiste, po‚tique et rˆveur, la passivit‚, l''inconstance,',
  'l''excentricit‚ et la mollesse. Elle commande au d‚but de',
  'l''enfance, … l''arriŠre vieillesse. Dans la famille, elle',
  'repr‚sente la mŠre, l''‚pouse, la maternit‚, les h‚ritages et les',
  'donations. Dans la soci‚t‚ les femmes, les romanciers, les poŠtes',
  'et les voyageurs. Elle montre ce qui se passe de nuit ou cache.',
  'Lundi.',
  'Mercure expose aux d‚ceptions, … l''ind‚cision, … la fourberie, …',
  'la malveillance, aux d‚placements rapides et dangereux. Par contre',
  'il accorde une perception rapide, le bons sens et l''‚loquence, la',
  'facult‚ de d‚nouer les affaires et mener … bien les n‚gociations,',
  'l''adresse. Influence dans l''individu le savoir-faire,',
  'l''activit‚ mentale, la souplesse, la mobilit‚, l''intuition et le',
  'sens de l''opportunit‚. Il repr‚sente dans la famille l''enfant,',
  'les frŠres, l''argent, les biens mobiliers, l''instruction. Dans',
  'la soci‚t‚, les confrŠres, les amis, les collŠgues, les employ‚s,',
  'les commer‡ants et les interm‚diaires. Il correspond … tout ce qui',
  'est mobile et jeune. Mercredi.',
  'V‚nus expose aux d‚sappointements sentimentaux, aux blessures',
  'd''amour-propre, … l''impopularit‚, … l''insouciance, … la',
  'lƒchet‚, … la maladresse et … la passivit‚ sexuelle. Par contre',
  'elle accorde l''amour, l''affection, la sympathie, les',
  'satisfactions de l''ƒme et des sens, les succŠs, l''amiti‚, la',
  'gaiet‚ et les joies. Elle influence la s‚duction, l''amour, la',
  'passion, la passivit‚, la g‚n‚rosit‚, la sympathie, l''harmonie et',
  'la sensibilit‚. Dans la famille, elle repr‚sente l''‚pouse en tant',
  'qu''amant, la fianc‚e, les filles, et le mariage. Dans la soci‚t‚,',
  'les femmes, les esthŠtes, les artistes, les courtisanes, les',
  'repr‚sentants. Repr‚sente ce qui est aimable. Vendredi.',
  'Mars expose … la discorde, … la guerre, aux rixes, au d‚sordre, au',
  'pillage, … la vengeance, … la cruaut‚ et aux blessures morales ou',
  'physiques, aux inimiti‚s, aux accidents. Par contre il accorde la',
  'force, la vitalit‚, le courage, l''activit‚, le respect, travail',
  'et ob‚issance. Il influence dans l''individu la combativit‚, la',
  'tyrannie, l''‚go‹sme brutal, l''‚nergie et les passions',
  'excentriques. Dans la famille il repr‚sente l''‚poux en tant',
  'qu''amant, l''homme, le fianc‚ et les gar‡ons. Dans la soci‚t‚,',
  'les hommes, les concurrents, les rivaux, les arrogants et les',
  'sportifs. Il correspond … tout ce qui est violent, bruyant et qui',
  'use et applique la force. Mardi.',
  'Jupiter expose aux soucis professionnels, … la n‚gligence, … la',
  'prodigalit‚, aux ennuis financiers ou sociaux et aux difficult‚s',
  'familiales. Par contre, il accorde l''organisation, le renom, le',
  'bonheur, l''amour, la richesse, la sant‚ et les honneurs. Il',
  'influence dans l''individu le rayonnement, la satisfaction, la',
  'justice, l''honnˆtet‚, la bont‚, la religion, l''amour-propre et',
  'la jovialit‚. Dans la famille il repr‚sente le pŠre, le tuteur,',
  'les parents, le patrimoine, la richesse, la respectabilit‚, les',
  'legs et le mariage. Dans la soci‚t‚, les protecteurs, les amis',
  'influents, les gens riches et les chefs. Il repr‚sente le pouvoir',
  'temporel et spirituel. Jeudi.',
  'Saturne expose aux chutes morales et physiques, … l''avidit‚, …',
  'l''lentement n‚faste, … la st‚rilit‚, aux ruptures, aux deuils,',
  'aux pertes et aux souffrances. Par contre il accorde la stabilit‚,',
  'la profondeur, la long‚vit‚, la dur‚e, la m‚thode, la',
  'constructivite, la respectabilit‚, la consid‚ration,',
  'l''exp‚rience, la connaissance, le respect de la tradition et la',
  'richesse immobiliŠre. Il influence dans l''individu le penseur et',
  'le taciturne, l''orgueil et l''‚go‹sme. Il entraŒn‚ le soup‡on, la',
  'superstition, le doute, la tristesse et la m‚lancolie. Dans la',
  'famille, il repr‚sente les a‹eux et l''h‚r‚dit‚. Dans la soci‚t‚,',
  'les savants, les travailleurs, les prisonniers. Samedi.',
  'Uranus expose aux revirements inattendus et malheureux, … un',
  'destin brutal, … la privation de libert‚, au manque d''adaptation,',
  '… l''utopie, … la r‚volte et … la solitude. Par contre il accorde',
  'la chance, l''ascension subite et inattendue, les revirements',
  'heureux, le don des d‚couvertes et inventions g‚niales,',
  'l''activit‚ mentale. Il influence dans l''individu',
  'l''ind‚pendance, la r‚volte, le g‚nie, le cr‚ateur ou destructeur.',
  'Dans la famille, il repr‚sente les c‚libataires, les parents',
  'bizarres et l''union ill‚gale. Dans la soci‚t‚, les',
  'individualistes, les inventeurs, les solitaires, les amoureux du',
  'paradoxe et les g‚nies m‚connus, la r‚volution et l''avant-garde.',
  'Samedi.',
  'Neptune expose aux querelles d''id‚es, aux erreurs, … l''moralit‚,',
  '… la r‚probation publique, … la tromperie et … la d‚ch‚ance',
  'physique et morale. Par contre, il accorde la chance pure, des',
  'modifications profondes et heureuses, les b‚n‚fices myst‚rieux, la',
  'f‚condit‚, les sensations intenses, les conceptions g‚niales et',
  'les d‚couvertes. Il influence dans l''individu l''intuition, les',
  'facult‚s sup‚rieures, le g‚nie, l''invention, les proph‚ties, la',
  'religion et le mysticisme. Dans la famille, il repr‚sente les',
  'collat‚raux ƒges, l''union mal assortie et contraire …',
  'l''affection et … la respectabilit‚. Dans la soci‚t‚, les',
  'fraudeurs et les emplois myst‚rieux. Jeudi.',
  'Pluton expose … la luxure, … la lƒchet‚, aux inimiti‚s violentes,',
  '… la mort brutale et … la d‚g‚n‚rescence. Par contre, il accorde',
  'le courage, la r‚alisation, les honneurs m‚rites, l''exaltation,',
  'la passion, le sacrifice et la t‚m‚rit‚. Il influence dans',
  'l''individu le moi guerrier et belliqueux, l''ind‚pendance, la',
  'colŠre, la fougue, le courage et l''inconscience devant le danger.',
  'Dans la famille il repr‚sente les beaux-parents, le guide et le',
  'pr‚cepteur. Dans la soci‚t‚, les belliqueux, les supporters, les',
  'policiers, les souteneurs, les chirurgiens et les savants. Il',
  'correspond aux lieux publics, aux manifestations populaires, aux',
  'monopoles et … la sp‚culation. Mardi.',
  'Pr‚dispos‚ aux qualit‚s excentriques, aux efforts violents et',
  'souvent excessifs. App‚tits voraces. Le caractŠre est entier,',
  'exclusif, imp‚tueux. Dominante passionnelle.',
  'Pr‚dispos‚ … la concentration, … la patience et au travail suivi.',
  'Rend ƒpre au gain, parfois libertin et toujours ‚go‹ste. Avantage',
  'la pers‚v‚rance et la patience. Douceur.',
  'Les qualit‚s sont nombreuses, les passions changeantes et les',
  '‚motions superficielles. Avantage l''activit‚, la mobilit‚,',
  'l''adaptation et la diplomatie. Rend inconstant.',
  'Pr‚dispos‚ au changement, … l''instabilit‚ et … l''imagination la',
  'force d''inertie est grande. La r‚sistance est passive, lente et',
  'apathique. Rend sensible et r‚sign‚. Bien-ˆtre.',
  'Donne de puissants moyens de d‚fense. L''ambition s''allie … une',
  'tendance intellectuelle "en avant". Besoin de r‚gner, d''affirmer',
  'et de convaincre. Rend susceptible et vaniteux.',
  'Pr‚dispos‚ … l''analyse, … la curiosit‚ intellectuelle et parfois',
  'au bavardage. Besoin de compliquer et d''apporter du fini aux',
  'choses. Rend pers‚v‚rant et souvent scrupuleux.',
  'Donne une grande ‚galit‚ d''ƒme et un talent inventif. L''esprit',
  'est souple. Besoin de plaire. L''adaptation aux faits et aux gens',
  'est ais‚e. On s''attache facilement. Appuis',
  'Pr‚dispos‚ … ne pas lƒcher ce qu''on tient et … obtenir ce qu''on',
  'convoite. Beaucoup de cran dans les luttes. L''ambition est',
  'patiente et audacieuse. Esprit railleur et contradictoire',
  'Grande force vitale et courage moral certain. Rend mobile et',
  'extensif. Fait g‚n‚ralement triompher de l''adversit‚. L''esprit',
  'est pacifique. La sagesse vient avec l''ƒge.',
  'Pr‚dispos‚ au doute et au besoin d''exp‚rimenter et de contr“ler.',
  'Marque la discipline ou la r‚volte, la logique ou l''utopie.',
  'Orgueil intellectuel. L''ambition est prudente.',
  'Rend sensible, enthousiaste, intuitif et souple d''esprit. La',
  'diplomatie est adroite et le caractŠre original. Rend inquiet en',
  'dehors de l''action. Besoin de sortir du banal.',
  'Pr‚dispos‚ … la passivit‚ et … l''inqui‚tude. Les entˆtements sont',
  'n‚fastes. Rend soumis en accentuant le besoin de bien-ˆtre. Donne',
  'de la sensibilit‚ et de la m‚diumnit‚.',
  'La fortune acquise l''est par …-coups. Risques de pertes par',
  'impatience, abus et excŠs. On ne sait pas accepter la d‚faite et',
  'on se r‚volte souvent inutilement. Intrigues.',
  'Favorable au travail et … la profession. L''ascension est lente et',
  'r‚guliŠre. L''ambition est patiente et s''allie … l''esprit de',
  'routine. Stabilit‚ financiŠre avec l''ƒge.',
  'La richesse, quand elle existe, est susceptible de prendre',
  'rapidement de l''extension. L''esprit d''entreprise est soutenu',
  'par un r‚el amour de l''argent. Qualit‚ commerciale.',
  'Les revenus proviennent de sources diverses grƒce au m‚rite',
  'personnel et souvent par le talent. L''accroissement des richesses',
  'est facilit‚ par le destin. Accorde s‚curit‚.',
  'Donne un grand d‚sir de bien-ˆtre et de confort. La r‚flexion et',
  'l''audace contribuent … l''ascension. Besoin d''arriver',
  'co–te-que-co–te. On sait semer pour r‚colter.',
  'La situation mat‚rielle est stable et l''accroissement des biens',
  'probable. La richesse provient de l''‚tude et d''une bonne',
  'organisation. Effort continu dans le mˆme sens.',
  'La situation financiŠre est souvent mobile : ‚l‚vation par',
  'l''effort intellectuel. La fortune acquise est difficile …',
  'conserver : on d‚pens‚ plus qu''on gagne. Talent cr‚ateur.',
  'La vie mat‚rielle est aid‚e par la souplesse intellectuelle,',
  'l''habilet‚ et le savoir professionnel. Pr‚dispos‚ … ne rien faire',
  'd''inutile. Les richesses viennent souvent ensembles.',
  'La situation financiŠre trouv‚ rapidement son ‚quilibre. On',
  'accepte difficilement les contraintes et la profession est souvent',
  'lib‚rale. Ind‚pendance mat‚rielle et sociale.',
  'L''ambition mat‚rielle est violente et soutenue par le m‚rite',
  'personnel et un esprit organis‚. T‚nacit‚ dans le travail',
  'favorable … l''effort r‚gulier. Fortune immobiliŠre.',
  'L''activit‚ mat‚rielle est souvent jugul‚e par un manque de',
  'confiance en soi. Rend h‚sitant dans le choix des moyens et les',
  'scrupules parfois excessifs. Il y a besoin d''appuis.',
  'Dans la vie mat‚rielle les inimiti‚s sont nombreuses et les',
  'relations susceptibles de causer mille d‚boires. Peut n‚anmoins',
  'conduire … la r‚ussite par la sp‚culation.',
  'Peu d''entente avec l''entourage. Les relations sont souvent',
  '‚nergiques. La jeunesse est souvent turbulente. Incline vers les',
  'sports, le mouvement, la vie au grand air.',
  'Les jalousies et les tracas sont fr‚quents avec l''entourage rend',
  'susceptible ou arrogant : les blessures d''amour propre',
  'empoisonnent la vie. ducation pratique. Manque d''id‚al.',
  'Tact naturel qui permet de s''adapter … tous les milieux. Donne du',
  'go–t pour la litt‚rature. Les relations sont nombreuses. L''amiti‚',
  'est souvent superficielle. Voyages.',
  'Incline … fuire les gens, le bruit et les querelles. Les',
  'affections sont peu heureuses. Inimiti‚s et jalousies dans',
  'l''entourage. Dispose aux changements de milieux.',
  'On attire … soi de nombreuses sympathies sur lesquelles on domine',
  'et rayonne. Facilite les ‚tudes brillantes. Dispose souvent … la',
  'lutte ouverte avec les sup‚rieurs. Jalousies.',
  'Le savoir et la confiance en soi grandissent avec l''ƒge.',
  'L''activit‚ intellectuelle s''exerce dans de nombreux domaines.',
  'L''amiti‚ ou la confiance s''accordent difficilement',
  'Un tact inn‚ permet de s''adapter … tous les milieux. Pr‚dispos‚ …',
  'se faire un nom dans la voie choisie. Aide les relations',
  'artistiques et mondaines. Amour de la paix.',
  'Souvent les relations sont superficielles et ax‚es sur les gens',
  'dont on a besoin et dont on profite. Cause souvent des querelles',
  'et des dissentiments avec l''entourage. tudes.',
  'L''entourage est nombreux et les fr‚quentations distingu‚es. On',
  's''efforce de plaire … tout le monde. Favorable aux arts. Souvent',
  'la science est au service de l''art. Go–t esth‚tique.',
  'Fait plut“t rechercher le voisinage de personnes ƒg‚es. Les',
  'relations sont utiles. Activit‚ laborieuse et parfois p‚nible :',
  'onse trouve de bonne heure au contact de la vie.',
  'L''entourage est agr‚able et sympathique et on se montre avenant',
  'et conciliant. Les relations s''‚tendent dans tous les domaines.',
  'Se montre trŠs favorable aux d‚placements.',
  'La fortune est probable : il y a plus de chance que de m‚rite. On',
  'soutient difficilement les luttes sans appuis. Pr‚dispos‚ … la',
  'soumission et au d‚vouement dans le couple.',
  'Le foyer est souvent gai ou bruyant : la joie et la gaite peuvent',
  'y r‚gner autant que les cris, la colŠre et la discorde. Les',
  'parents sont parfois s‚vŠres ou tyranniques.',
  'Grand amour de la famille. Le sentiment du devoir est parfois',
  'pousse … l''extrˆme et les scrupules maladifs. L''int‚rieur est',
  'stable : il est fait de travail et routine.',
  'Le foyer mobile, gai et vivant : on y trouve l''esprit d''aventure',
  'et le go–t de l''ind‚pendance. Les changements de r‚sidence sont',
  'fr‚quents. Les d‚penses exc‚dent les recettes',
  'L''int‚rieur est calme et manque souvent de chaleur. Le sentiment',
  'du devoir et le d‚vouement mutuel y est pousse. Sans pr‚sager la',
  'richesse, le foyer est ais‚. Habitudes.',
  'La vie au foyer est mat‚riellement facilit‚e. L''entente conjugale',
  'ou familiale est loin d''ˆtre parfaite mais on sauve les',
  'apparences. Aide … sortir des problŠmes d''argent.',
  'N''apport‚ que trŠs rarement la gaite au foyer qui manque souvent',
  'de jeunesse. Indique la routine au foyer et parfois la monotonie :',
  'chacun y a ses habitudes et ses manies.',
  'Souvent l''int‚rieur est de bon go–t et la vie mat‚rielle',
  'plaisante et facile. Les sentiments familiaux sont ‚lev‚s.',
  'Influence heureusement la descendance au niveau artistique.',
  'L''h‚r‚dit‚ et la descendance sont solides. Facteur de long‚vit‚.',
  'Le foyer est calme et s‚rieux : souvent sans grandes joies.',
  'L''accroissement du patrimoine est lent.',
  'La vie familiale est agr‚able et soucieuse de ses devoirs et de sa',
  'respectabilit‚. Souvent les parents contribuent … faire la',
  'situation de leurs descendants. Solide h‚r‚dit‚.',
  'Le patrimoine est solide et la vie familiale sobre, non par',
  'n‚cessite mais par manque de besoins. Les liens au foyer sont plus',
  'int‚ress‚s qu''affectifs. Manque de chaleur.',
  'L''accroissement du patrimoine est probable car on rencontre',
  'l''appui des parents ou du conjoint. Souvent le foyer est calme :',
  'la compr‚hension y rŠgne plus que l''amour. Luxe.',
  'Le foyer manque de fixit‚ et les obligations professionnelles',
  'obligent … vivre ‚loign‚s les uns des autres. Peut indiquer deux',
  'm‚nages simultan‚s. Indique souvent la fortune.',
  'Les plaisirs sont violents et les passions brutales. Cause des',
  'imprudences sentimentales dangereuses pour les finances et la',
  'r‚putation. Pr‚dispos‚ aux coups de tˆte.',
  'Donne l''amour des plaisirs pond‚r‚s et solides. Sensualisme',
  'puissant et amour de la vie. Parfois les plaisirs amoureux nuisent',
  '… l''ascension. L''int‚rˆt est dicte par l''amour.',
  'Donne autant de facilite … rompre qu''… s''attacher. Les amours',
  'sont nombreuses et ‚loignent souvent du mariage. Grand amour',
  'tardif. Favorise les arts li‚s aux plaisirs.',
  'Pr‚dispos‚ … aimer le bien-ˆtre et les aises. Donne de la sagesse',
  'et de l''imagination en amour. Favorable aux combinaisons',
  'financiŠres. Amour de la famille et des enfants',
  'On est plus aim‚ qu''on aime soi-mˆme. On doit lutter',
  'continuellement contre la jalousie et l''envie. L''ambition',
  'amoureuse est violente. Le bonheur vient souvent par l''art.',
  'Donne souvent un manque d''ampleur dans les plaisirs mais quand',
  'une passion existe, elle est intense et souvent unique l''amour',
  'est souvent contrari‚ par la crainte du lendemain.',
  'Amour des plaisirs : de tous les plaisirs. Donne de la d‚licatesse',
  'et du tact. Parfois le narcissisme conduit … l''ingratitude.',
  'L''amour est tributaire de la sympathie.',
  'Il y a peu de passions, souvent une seule, mais elle sera tenace',
  'et d‚vorante. Rend jaloux, passionn‚, entier et tyrannique dans',
  'les affections. Sentiments difficiles.',
  'L''entourage est nombreux et les fr‚quentations distingu‚es. On',
  's''efforce de plaire … tout le monde. Favorable aux arts. Souvent',
  'la science est au service de l''art. Go–t esth‚tique.',
  'Fait plut“t rechercher le voisinage de personnes ƒg‚es. Les',
  'relations sont utiles. Activit‚ laborieuse et parfois p‚nible : on',
  'se trouve de bonne heure au contact de la vie.',
  'L''entourage est agr‚able et sympathique et on se montre plaire',
  'peuvent conduire … la prodigalit‚. Cause souvent des dissentiments',
  'affectifs, des d‚sillusions et les divorc‚s.',
  'Donne l''amour des enfants et de la famille plus que de la',
  'fid‚lit‚ conjugale. Incline aux amours en dehors du mariage et aux',
  'unions simultan‚es. Indique les amours secrŠtes.',
  'Les rapports entre employeurs et employ‚s manquent d''harmonie :',
  'on se montre susceptible, arrogant et impatient. Pr‚dispos‚ aux',
  'contraintes professionnelles.',
  'Facteur d''entente dans la vie priv‚e et professionnelle.',
  'Peut-ˆtre l''indice de fr‚quents malaises, mais la r‚sistance',
  'physique est bonne. Favorable aux professions artistiques.',
  'Le travail est g‚n‚ralement peu p‚nible et r‚mun‚rateur, souvent',
  'instable dans une profession mal d‚finie. Fr‚quents changements',
  'd''employ‚ ou d''employeur. Maladie des bronches.',
  'Pr‚dispos‚ … mener une vie domestique et professionnelle uniforme.',
  'Fait s''occuper de sa sant‚ et de celle d''autrui.',
  'L''insatisfaction dans le travail est due au laisser-aller.',
  'Les efforts professionnels sont parfois violents et on pr‚sume de',
  'ses forces. Ne facilite pas le travail pour le compte d''autrui',
  'car l''ob‚issance est pesante.',
  'Permet les travaux p‚nibles et la pers‚v‚rance dans l''effort',
  'pr‚dispos‚ aux professions intellectuelles et scientifiques. Le',
  'commerce et les m‚tiers de la m‚decine sont favorises.',
  'Permet de s''adapter ais‚ment … tout travail et aux servitudes.',
  'Avantage heureusement les carriŠres artistiques. Sp‚cialement dans',
  'le domaine musical. quilibre moral.',
  'Fait manquer de discipline et rend imprudent. On se montre entˆt‚',
  'et indisciplin‚ dans la vie professionnelle : on ne fait rien a',
  'moiti‚. Indice de travail solitaire. Science.',
  'Donne g‚n‚ralement du savoir-faire dans les rapports',
  'professionnels : on sait se faire ob‚ir, respecter, et souvent',
  'aimer. Dispose … l''indulgence sans faiblesse.',
  'Permet d''entreprendre et de mener … bonne fin les travaux les',
  'plus rudes et les occupations les plus rebutantes. Recommande de',
  'travailler par soi-mˆme sans collaborations.',
  'La vie professionnelle est avantag‚e par un bon ‚quilibre nerveux',
  ': on sait se m‚nager et aller … l''extrˆme limite de ses forces.',
  'Les proches menacent souvent la profession.',
  'Rend souvent le travail p‚nible, soit par d‚go–t, soit par',
  'impossibilit‚ physique. Avantage la recherche et les professions',
  'qui demandent du flair. Sp‚culation financiŠre.',
  'Les amiti‚s et les inimiti‚s sont puissantes. Les rapports avec',
  'les autres causent des luttes et des heurts. Le mariage ou',
  'l''union se produisent t“t : on est passionn‚.',
  'Pr‚sage souvent deux unions ou le c‚libat. Incline …',
  'l''ind‚pendance et l''individualisme. Les relations sont',
  'tributaires de l''int‚rˆt plus que de l''amiti‚. Solitude.',
  'Grande possibilit‚ d"entente avec autrui : on tent … la',
  'conciliation et les querelles sont sans gravit‚. Permet de',
  's''adapter … tous les milieux. Indique souvent l''adultŠre.',
  'Ne favorise pas le mariage et incline … une union tardive. Se',
  'm‚fier des incompatibilit‚s d''humeur surtout dans les',
  'associations d''int‚rˆt. Pr‚dispos‚ aux ententes secrŠtes.',
  'Les rapports avec autrui sont marques par la compr‚hension et la',
  'tol‚rance. Le mariage est favorise socialement. On subit',
  'difficilement les contraintes. Besoin de dominer.',
  'Les unions et les associations ne sont pas profitables quand on',
  'fait preuve de trop de confiance. Ne dispose pas au mariage qui',
  'n''est g‚n‚ralement pas heureux. Sensiblerie.',
  'Souvent les unions sont troubl‚es par la jalousie. On se montre',
  'passionn‚, entier et inconstant : les rapports sociaux s''en',
  'ressentent. Rapports fr‚quents avec la justice.',
  'Le mariage et l''union sont domin‚s par les sens. Les rapports',
  'sont absorbants et troubles par la jalousie. Expose … l''adultŠre',
  'et aux procŠs dans ce sens. Divorce.',
  'Pr‚dispos‚ aux unions ill‚gales et pr‚coces. N''incit‚ pas au',
  'mariage. TrŠs souvent la soif d''ind‚pendance fait rester',
  'c‚libataire. L''union bas‚e sur l''int‚rˆt est plus durable.',
  'Pr‚sage souvent un conjoint plus ƒge et l''union repose autant sur',
  'l''int‚rˆt que sur la sensualit‚. N''est pas favorable … l''union',
  'l‚gale. Deux mariages sont probables.',
  'Permet les associations favorables … l''ascension, aux aides',
  'appuis et protections. Pr‚sage des unions multiples. Les passions',
  'sont violentes et les luttes nombreuses.',
  'Pr‚sage une union ou un mariage pr‚coces et ne donne pas la',
  'maŒtrise sur les sens. Les rapports avec autrui sont difficiles',
  'par manque de fermet‚. Contraire aux procŠs.',
  'Accorde souvent une dur‚e d''existence d‚passant de beaucoup la',
  'moyenne. Peut causer des crises cardiaques et des congestions',
  'c‚r‚brales. Dissipation ou perte du patrimoine.',
  'D‚velopp‚ l''instinct de conservation qui fait que la dur‚e de',
  'l''existence d‚pass‚ la moyenne. Donne des convictions profondes',
  'et le soucis des convenances. Facteur de veuvage.',
  'Une trop grande activit‚ c‚r‚brale nuit souvent au d‚veloppement',
  'harmonique du corps. Ascension probable par le m‚rite et le',
  'talent. Indice de renomm‚e aprŠs la mort.',
  'Pr‚sage une fin de vie solitaire. Il y a souvent crainte de la',
  'mort, foi religieuse ou mysticisme. La vieillesse est g‚n‚ralement',
  'sujette … des incommodit‚s physiques.',
  'TrŠs souvent la dur‚e de l''existence est en rapport avec celle du',
  'pŠre. Probabilit‚ de richesse provenant d''h‚ritages ou de dons',
  'faits par des protecteurs. Souvent mort glorieuse',
  'Pr‚sage trŠs souvent une mort paisible, loin du monde, … la',
  'campagne. Donne la qui‚tude mat‚rielle dans la seconde partie de',
  'la vie. Parfois une mort transforme la vie.',
  'Rend soumis au destin et aux influences ext‚rieures. Incline',
  'parfois … la superstition ou … l''inqui‚tude exag‚r‚e. Cause de',
  'm‚lancolie. La qui‚tude ne suffit pas au bonheur.',
  'Facteur de long‚vit‚ quand on sait se d‚penser sans ˆtre prodigue',
  'de ses forces. On tient de la mŠre. Les h‚ritages sont rares et',
  'sont faits de biens fonciers. Mort rapide.',
  'Donne de l''habilit‚ et du savoir-faire permettant d''accroŒtre le',
  'patrimoine et de recueillir les h‚ritages. Indice de long‚vit‚ et',
  'd''amour de la vie. Go–t pour la spiritualit‚.',
  'Les h‚ritages paraissent peu avantageux et les successions',
  'entraŒnent souvent de lourdes responsabilit‚s. La long‚vit‚ est',
  'probable et d‚pass‚ souvent de loin les espoirs.',
  'Pr‚sage l''h‚r‚dit‚ intellectuelle ou artistique et permet dans ce',
  'sens une ‚volution continuelle vers le mieux. L''imagination est',
  'puissante et parfois lugubre. Mystique.',
  'L''accroissement du patrimoine est probable : il est du … la',
  'chance, aux h‚ritages et … l''amour. La long‚vit‚ est probable.',
  'Incline … l''occultisme. volution spirituelle.',
  'volution constante dans les d‚placements et les changements de',
  'milieux. Incline … se passionner pour tout ce qu''on ne connaŒt',
  'pas. La satisfaction orient‚ vers un autre but.',
  'Rend l''esprit pratique et r‚aliste. Pr‚dispos‚ … s''orienter vers',
  'les r‚alit‚s. On reste plus attach‚ aux faits qu''aux hypothŠses.',
  'Le go–t du risque et de l''aventure font d‚faut.',
  'Pr‚sage une ‚l‚vation intellectuelle et morale continuelle.',
  'L''esprit s''int‚ress‚ … tout et le caractŠre est tol‚rant. Permet',
  'de s''enrichir dans tous les domaines. Petits voyages.',
  'L''imagination est puissante et … besoin de solitude pour',
  's''‚chapper du r‚el. Favorable aux travaux de laboratoire et aux',
  'inventions. Favorable … la diplomatie silencieuse.',
  'Pr‚sage la fiert‚ et la grandeur d''ƒme : on aspire … faire',
  'toujours mieux. L''ambition est intelligente et souple. Permet de',
  's''adapter aux gens utiles. Amour du grand voyage.',
  'Belles qualit‚s intellectuelles, mais l''esprit confine au doute',
  'et … la crainte du lendemain. Les voyages sont souvent accompagn‚s',
  'de multiples difficult‚s. Aptitude … la critique',
  'Pr‚sage l''‚volution continuelle car on est souvent un model pour',
  'son milieux. L''imagination est f‚conde et les id‚es mystiques.',
  'Les voyages sont g‚n‚ralement agr‚ables.',
  'L''esprit est inventif, m‚ditatif et observateur : on doute de',
  'tout, sauf de soi-mˆme. Donne le go–t des voyages secrets et',
  'aventureux qui sortent de l''ordinaire. Rend m‚fiant.',
  'TrŠs favorable aux ‚tudes, aux recherches et … la religion. Aide',
  'fortement la renomm‚e et rend respectable et respect‚. Favorise',
  'les longs voyages et le commerce avec l''‚tranger.',
  'Rend l''esprit orgueilleux et travailleur. Incline … la solitude',
  'et … vivre par l''int‚rieur. Les voyages sont peu nombreux.',
  'Dispose au doute et l''intol‚rance religieuse.',
  'L''esprit est s‚rieux et dominateur : les conceptions',
  'intellectuelles sont trŠs vastes, parfois sp‚culatives et',
  'dangereuses. Voyages hors du commun, certainement sp‚ciaux.',
  'Donne une imagination f‚conde et une intelligence brillante, mais',
  'rend craintif et inquiet. Favorable aux d‚placements sur l''eau et',
  'aux transactions d''outre-mer. Esprit trouble.',
  'Donne une confiance absolue en sa valeur et ses possibilit‚s fait',
  'aimer la lutte pour la lutte. Pr‚sage orgueil et ambition et le',
  'besoin absolu de se mettre en avant.',
  'La situation se fait jour par un effort constant, personnel et',
  'souvent p‚nible. Conduit … connaŒtre l''aisance ou la richesse et',
  'la consid‚ration que l''argent accord‚.',
  'Activit‚ incessante : l''esprit est d‚brouillard et intuitif. On',
  'comprend tout et on sait tirer le meilleur parti des gens et des',
  '‚v‚nements. Esprit synth‚tique et vulgarisateur.',
  'Pr‚sage un m‚tier dans lequel on peut donner libre cour … sa',
  'fantaisie. La volont‚ est faible mais l''entˆtement invincible.',
  'Indice de renomm‚e grƒce aux dons naturels.',
  'Les efforts professionnels sont parfois violents et on pr‚sume de',
  'ses forces. Ne facilite pas le travail pour le compte d''autrui',
  'car l''ob‚issance est pesante.',
  'Permet les travaux p‚nibles et la pers‚v‚rance dans l''effort',
  'pr‚dispos‚ aux professions intellectuelles et scientifiques. Le',
  'commerce et les m‚tiers de la m‚decine sont favorises.',
  'Permet de s''adapter ais‚ment … tout travail et aux difficiles.',
  'L''amour de la vie aide l''ambition et la stimule. Souvent le',
  'mariage … lieu de bonne heure pour se lib‚rer.',
  'Pr‚sage autant de domination sur soi-mˆme que sur les autres.',
  'L''ascension est lente : elle est due au travail, … la t‚nacit‚ et',
  '… la continuit‚ dans l''effort. R‚sistance.',
  'Facilite l''ascension et permet souvent d''obtenir une situation',
  'en vue. La position met en relation avec le public la chance aide',
  'et l''‚go‹sme est foncier sans m‚chancet‚.',
  'L''ambition est g‚n‚ralement violente, plus intellectuelle que',
  'mat‚rielle. Les buts qu''on se fixe sont longs … ˆtre atteints et',
  'parfois le caractŠre s''aigrit. M‚thode avantag‚e',
  'Grand amour de la vie et beaucoup d''indulgence : on se laisse',
  'bercer de confiance. Le devenir sort des sentiers battus et il',
  'arrive qu''on gagne beaucoup d''argent. G‚n‚reux.',
  'Pr‚dispos‚ … suivre une voie qui ne sorte pas des sentiers battus.',
  'Grand soucis de la respectabilit‚. L''ensemble de la vie ne donne',
  'pas toujours satisfaction. Travail sans joie',
  'Les relations et les amiti‚s sont changeantes. On se passionne',
  'pour ses amis autant qu''on s''en d‚sint‚ress‚ facilement.',
  'Entˆtements regrettables pour les affaires.',
  'Les relations et les amiti‚s sont solides, souvent entiŠres et',
  'jalouses. On accepte ce qui est pour avoir la paix qu''on a pas',
  'pour autant. Amiti‚s compromettantes. Altruisme.',
  'Les relations et amiti‚s sont plus intellectuelles que',
  'sentimentales : elles peuvent devenir trŠs nombreuses. Imprudence',
  'en amour. On sait utiliser sa sympathie. Appuis.',
  'Les relations sont peu nombreuses et on ne les recherche pas : les',
  'amiti‚s sont plus une habitude qu''un ‚lan du coeur incline aux',
  'manoeuvres compliqu‚es et liaisons clandestines.',
  'Les relations s''accroissent sans cesse : possibilit‚ de vie',
  'publique ou mondaine. Favorable … ceux qui font appel … la faveur',
  'du public. D‚sillusions sentimentales fr‚quentes.',
  'Rend ‚go‹ste et int‚ress‚ en dehors du cercle de ses affections.',
  'Rend les relations f‚minines complexes et incline aux intrigues et',
  'amours int‚ress‚s. Complications.',
  'Les relations sont nombreuses et se rencontrent dans tous les',
  'milieux : elles sont souvent int‚ress‚es et jalouses sans ˆtre',
  'pour autant inutiles. Les amours sont passionn‚es.',
  'Les relations sont nombreuses et on y compte plus d''ennemis que',
  'd''amis. On s''engage et on prend parti. Si le destin est couronne',
  'd''effort, les relations survivront par int‚rˆt.',
  'Les relations sont trŠs instables, qu''elles soient mondaines ou',
  'professionnelles. On recherche les relations utiles. L''ascension',
  'ne va pas sans inimiti‚s et jalousies violentes.',
  'Les relations sont peu nombreuses et celles qui existent sont',
  'tri‚es sur le volet. Les appuis sont rares mais on peut compter',
  'sur ceux qui se pr‚sentent. Protection occulte.',
  'Les relations sont trŠs belles et peuvent se rencontrer dans tous',
  'les milieux : on s''adapte … merveille … tous les gens et … toutes',
  'les circonstances. On se donne trop facilement.',
  'Les amis sont versatiles et changeants, parfois int‚ress‚s et',
  'fourbes. Ne contribue pas … la qui‚tude sentimentale. Les amours',
  'secrŠtes causent des tracas. R‚ussite prot‚g‚e.',
  'Le destin est brutal et on doit courber les ‚paules pour amortir',
  'les coups du sort. Les ‚preuves laissent des traces profondes,',
  'disposent aux imprudences sentimentales.',
  'Les app‚tits sont violents et le besoin de jouir de la vie conduit',
  '… des actes irraisonnables, parfois ill‚gaux. Cause de maladies',
  'par abus de travail ou de plaisir.',
  'Les ‚preuves sont nombreuses mais ne laissent que peu de traces',
  'car on est insouciant ou ‚go‹ste : on accepte tout et on tƒche de',
  'tirer son ‚pingle du jeu. Destin m‚diocre.',
  'Les ‚preuves s''‚tendent plus en surface qu''en profondeur et',
  'proviennent de la susceptibilit‚, du caprice et de la sensibilit‚',
  'excessive. Tendance … se croire trŠs malheureux.',
  'Les inimiti‚s, surtout familiales, contribuent souvent …',
  'empoisonner la vie. Il y a contrainte dans l''expression des',
  'sentiments et d‚sirs. On refoule le meilleur de soi-mˆme.',
  'Les ‚preuves proviennent d''un manque de fermet‚ morale et on',
  'accepte mille petits tracas pour ne pas perdre certains avantages.',
  'Les scrupules font croire qu''il est bon de subir.',
  'Rend irritable, capricieux et inquiet. L''orgueil bless‚ empˆche',
  'toute retenue et la m‚sentente s''aggrave. Dispose et expose … la',
  'vengeance, aux menaces et aux coups. Heurts.',
  'Une grande force morale et de l''‚go‹sme, de l''insensibilit‚ et',
  'de l''indiff‚rence aux souffrances d''autrui permettent de ne pas',
  'trop souffrir dans la vie. Les ennemis sont nombreux.',
  'Le moral et le physique se trouvent rapidement affect‚s par les',
  'p‚riodes d''hostilit‚s et de troubles. Tout ce qui est sp‚culatif',
  'est vou‚ … l''‚chec. L''improvisation est n‚faste.',
  'Le libre arbitre est faible et le destin est puissant sans ˆtre',
  'n‚cessairement malheureux. On ne peut rien contre les ‚v‚nements.',
  'La sagesse veut qu''on ne se r‚volte pas.',
  'Les ‚preuves peuvent ˆtre nombreuses mais ne laisseront pas des',
  'traces profondes. On connaŒt des soucis financiers, voire des',
  'pertes de situation, mais jamais la ruin‚ ou la misŠre.',
  'Les ennemis comme les ‚preuves sont g‚n‚ralement inexistants et',
  'quand il y a des soucis, le destin remet g‚n‚ralement les choses',
  'en ordre. On se laisse conduire par les ‚v‚nements.',
  'AccroŒt la vitalit‚ et favorise la sant‚. Dispose … l''optimisme',
  'et … la confiance en soi. Permet de mettre en valeur ses talents',
  'et aptitudes.',
  'Favorise l''ascension sociale et la reconnaissance de ses dons. La',
  'p‚riode marque d''appr‚ciables rentr‚es d''argent. B‚n‚fique aux',
  'entreprises commerciales.',
  'Favorise l''entente avec l''environnement. La p‚riode est marqu‚e',
  'par des voyages, des d‚placements. Facilite l''‚tude, et permet la',
  'r‚ussite aux examens.',
  'Favorise l''entente familiale et permet de trouver l''harmonie',
  'dans ses rapports affectifs. P‚riode excellente pour',
  'l''acquisition ou l''am‚lioration de l''habitation.',
  'Apporte de nombreuses satisfactions, des plaisirs de toutes sortes',
  'et accroŒt la joie de vivre et l''‚nergie. Favorise la',
  'transmission d''un enseignement.',
  'Dispose … des ennuis de sant‚. Souvent, il cause de la lassitude',
  'et une inadaptation au quoditien. Provoque des contrari‚t‚s',
  'mat‚rielles, des retards et des heurts.',
  'La p‚riode est surtout ax‚e sur les rapports humains. Porte …',
  'faire de nombreuses rencontr‚s, … chercher l''accord des autres.',
  'Conseille toutefois de s‚lectionner ses relations.',
  'Provoque des bouleversements dans l''existence. Marque des remises',
  'en cause, des ruptures, des crises. Se m‚fier d''une tendance …',
  'd‚truire ou … s''autodetruire.',
  'Favorise les voyages et les rapports avec l''‚tranger. Indique un',
  'd‚sir de renouveler ses int‚rˆts. Excellente p‚riode pour les',
  '‚tudes et l''intellectualit‚.',
  'Est b‚n‚fique pour l''activit‚ professionnelle. Intensifie',
  'l''ambition, la volont‚ et la force de caractŠre permet de se',
  'distinguer et de progresser … tous niveaux.',
  'Favorise les projets et permet de rencontrer des soutiens, des',
  'collaborations. largit le cercle des amis, des relations. Permet',
  'd''attirer la sympathie d''autrui.',
  'Limite momentan‚ment les possibilit‚s, entrave l''action, retarde',
  'les projets. Fait d‚pendre excessivement d''autrui et des',
  'circonstances. Fatigue, d‚couragement.',
  'Insiste sur les aspects mat‚riels de l''existence. Permet',
  'l''accroissement des gains, le d‚but d''une activit‚ plus',
  'r‚mun‚ratrice. Favorise les achats et placements.',
  'La p‚riode est trŠs favorable aux gains et placements. Fait',
  'financiŠrement agir avec prudence mais habilet‚. P‚riode',
  'excellente pour les achats et le confort.',
  'Permet de recevoir une aide solide de l''entourage favorise les',
  'projets intellectuels, les collaborations. La p‚riode rend les',
  'voyages et les ‚changes fructueux.',
  'Dispose … l''entente et … la conciliation avec la famille, et',
  'particuliŠrement le pŠre ou le mari. Permet l''accroissement du',
  'confort domestique et du bien-ˆtre.',
  'Favorise les sp‚culations et les initiatives financiŠres',
  'audacieuses. AccroŒt la tendance aux d‚penses. Porte souvent …',
  'vivre au-dessus de ses possibilit‚s.',
  'Favorise particuliŠrement les artisans et ceux qui travaillent',
  'chez eux. Marque des d‚saccords financiers avec l''entourage, et',
  'porte … subir l''envie ou la critique.',
  'Dispose aux unions et associations financiŠrement fructueuses.',
  'Permet de se tirer avantageusement de litiges. Fait souvent',
  'recevoir ou donner des cadeaux importants.',
  'Durant cette p‚riode, les h‚ritages, dons, legs, pensions ou',
  'contrats financiers seront places au premier plan. Parfois, un',
  'deuil peut modifier la situation financiŠre.',
  'Favorise les contacts financiers … l''‚tranger ou avec',
  'l''‚tranger. Rend les voyages fructueux. Les projets b‚n‚ficient',
  'd''un maximum de s‚curit‚ et de solidit‚.',
  'Favorise la situation professionnelle qu''il rend stable et',
  'avantageuse. Marque souvent un accroissement des gains et une vie',
  'mat‚rielle plus facile.',
  'Permet de rencontrer des appuis favorables … la situation.',
  'Favorise les activit‚s commerciales. Facteur de renomm‚e et de',
  'popularit‚.',
  'La p‚riode est marqu‚e par des difficult‚s financiŠres. Porte …',
  's''endetter ou … avoir mat‚riellement recours … autrui. Risque',
  'd''incompr‚hension dans la profession.',
  'Dispose … l''abondance d''id‚es, de projets. Favorise l''‚tude les',
  'recherches intellectuelles. Marque un attrait pour un mode de vie',
  'insouciant et mouvement‚.',
  'Facilite les d‚placements, rend les voyages et les ‚changes',
  'fructueux. Permet souvent un accord ou un rapprochement entre',
  'frŠres et soeurs.',
  'Facilite la compr‚hension r‚ciproque dans les rapports humains.',
  'Aspect de complicit‚ avec l''entourage. Favorise les ‚tudes,',
  'l''expression verbale et ‚crite.',
  'Marque un changement de domicile, un ‚loignement d''avec la',
  'famille et le cadre habituel. Favorise les ‚tudes l''‚tranger et',
  'les collaborations intellectuelles.',
  'Dispose aux voyages d''agr‚ment, aux plaisirs, aux distractions.',
  'Favorise l''expression artistique. Promet des joies dans les',
  'contacts avec les enfants.',
  'Est un indice de limitation et de d‚couragement. Peut marquer la',
  'maladie d''un proche. Durant cette p‚riode, les d‚placements sont',
  'difficiles et porteurs de tracas.',
  'Dispose … la m‚sentente avec les parents, le conjoint ou',
  'l''associ‚. Expose aux critiques, aux ragots aux humiliations.',
  'Risque de litige et de procŠs.',
  'Dispose aux d‚placements forces et p‚nibles. Peut marquer un deuil',
  'dans l''entourage. P‚riode de doute, de solitude, de travail',
  'ingrat ou de ch“mage.',
  'AccroŒt l''importance des ‚changes, des ‚crits. Dispose aux',
  'd‚m‚nagements, provoque des d‚placements inattendus, des voyages',
  'en groupe. Multiplie les rencontr‚s.',
  'Lie ‚troitement les activit‚s professionnelles aux rencontr‚s,',
  '‚changes et d‚placements. Facilite l''expression de ses d‚sirs et',
  'de ses ambitions.',
  'Favorise les collaborations, les activit‚s intellectuelles faites',
  '… plusieurs. Permet de trouver des appuis … ses projets. Facilite',
  'la publicit‚.',
  'Dispose aux incidents, retards dans les projets et dans les',
  'd‚placements. Indice d''incompr‚hension avec l''entourage.',
  'Parfois, maladie ou d‚cŠs d''un proche.',
  'Porte … rechercher la s‚curit‚ et la stabilit‚. La p‚riode permet',
  'de reprendre des forces et facilite la gu‚rison des malades.',
  'Dispose aux relations paisibles.',
  'Dispose … la prudence financiŠre et aux achats immobiliers. Pose',
  'des questions financiŠres avec la famille. Favorise les s‚jours …',
  'la campagne.',
  'D‚stabilis‚ les relations familiales. Provoque des ruptures avec',
  'l''entourage habituel. Marque des heurts avec le partenaire',
  'sentimental. loign‚ du foyer.',
  'Favorise la stabilit‚ dans les relations. La p‚riode peut ˆtre',
  'marqu‚e par le mariage ou une liaison importante. Permet',
  'l''‚panouissement affectif.',
  'Dispose aux tensions, querelles et revirements brutaux dans les',
  'relations. Tendance au gaspillage et aux d‚penses excessives.',
  'Indice de placements maladroits.',
  'Restreint la vitalit‚ et expose … la maladie. Un environnement',
  'p‚nible peut influer sur le mental. Dispose … la m‚lancolie et …',
  'la d‚pression.',
  'Favorise les unions et les associations. Permet d''‚tablir avec',
  'l''entourage des relations solides. Dispose … la diplomatie et …',
  'l''amabilit‚.',
  'Dispose au doute et … l''angoisse. La p‚riode est marqu‚e par des',
  'prises de conscience et par des d‚sirs de changements profonds.',
  'Favorable aux h‚ritages.',
  'Favorise les projets li‚s … l''‚tranger. Peut marquer un',
  'd‚m‚nagement ou un s‚jour prolong‚ loin de chez soi. Facilite les',
  '‚tudes et les recherches.',
  'La p‚riode est marqu‚e par l''aboutissement d''une ambition.',
  'L''aspect accord‚ autorit‚, honneurs. Facilite l''expression',
  'devant un public, permet de toucher le plus grand nombre.',
  'Dispose … l''amiti‚ et … la fid‚lit‚. Permet de trouver une aide',
  'dans son entourage et rend soi-mˆme trŠs serviable. Facteur de bon',
  '‚quilibre physique et nerveux.',
  'Marque une tendance … l''isolement. Provoque des difficult‚s pour',
  'communiquer avec l''entourage. La p‚riode est marqu‚e par un',
  'sentiment d''abandon et de solitude.',
  'Augmente la vitalit‚ et le go–t des plaisirs. AccroŒt la confiance',
  'en soi et permet de se valoriser. Aspect de chance pure qui',
  'favorise toutes les audaces.',
  'Dispose aux placements et aux sp‚culations. Favorise',
  'particuliŠrement les activit‚s artistiques et les commerces de',
  'luxe. Tendance … la possessivite en amour.',
  'Dispose … la chaleur et … la g‚n‚rosit‚ dans les rapports avec',
  'l''entourage. Favorise l''entente entre les membres de la famille.',
  'Propice … l''ext‚riorisation.',
  'Favorise l''entente familiale. Marque parfois une naissance dans',
  'l''entourage proche. P‚riode de bonheur affectif, de joies et de',
  'vie facile.',
  'Dispose … l''activit‚ et … la cr‚ativit‚. Permet d''heureuses',
  'surprises dans le domaine financier. AccroŒt la vitalit‚,',
  'l''‚nergie et la confiance en soi.',
  'Favorise la gu‚rison des malades et promet … tous une am‚lioration',
  'dans la vie quotidienne. La p‚riode est marqu‚e par une lib‚ration',
  'de contraintes pesantes.',
  'Dispose … l''entente avec le conjoint. Chez les c‚libataires,',
  'marque l''union ou une liaison importante. Discussions avec les',
  'enfants, ou … leur sujet.',
  'La p‚riode peut ˆtre marqu‚e par le d‚cŠs d''un proche. L''aspect',
  'sape la vitalit‚ et dispose aux id‚es noires. Porte aux ruptures',
  'amoureuses et aux passions violentes.',
  'Apporte de multiples satisfactions par les ‚tudes et par la',
  'pens‚e. Fait voir ses efforts r‚compenses. AccroŒt le prestige et',
  'favorise les voyages.',
  'Favorise l''aboutissement des ambitions et des efforts. Dispose …',
  'd''appr‚ciables rentr‚es d''argent. Augmente le confort mat‚riel',
  'et la confiance en soi.',
  'Dispose … avoir une vie amicale bien remplie et joyeuse. Permet de',
  'donner de soi une image avantageuse. Favorise les sorties,',
  'invitations, distractions, plaisirs.',
  'Dispose … des soucis de toutes sortes qui minent le moral et',
  'causent le d‚couragement. P‚riode marqu‚e par des ennuis de sant‚.',
  'Marque le surmenage et la contrainte.',
  'Est peu propice … la sant‚. Les maladies et les malaises sont',
  'souvent cons‚quences d''excŠs. Pr‚sage des contrari‚t‚s multiples',
  'dans la vie quotidienne.',
  'Limite les possibilit‚s financiŠres. Dispose … des travaux',
  'p‚nibles ou monotones. Peut marquer des ennuis de sant‚ et des',
  'd‚penses impr‚vues en soins, cur‚s, etc.',
  'Provoque des d‚placements forces pour le travail, les ‚tudes ou',
  'des d‚marches p‚nibles. Marque la maladie d''un proche. Rend',
  'sensible … la contagion.',
  'Dispose … la maladie pour soi ou pour un proche. Provoque une',
  'inactivit‚, une immobilit‚ forc‚e. Tendance … rester chez soi et …',
  'se contenter d''un travail quotidien.',
  'Dispose aux excŠs nuisibles … la sant‚. Peut marquer la maladie',
  'd''un enfant. Favorise le travail en rapport avec les jeunes et',
  'avec un public.',
  'Met l''accent sur une inadaptation au mode de vie, au travail',
  'quotidien. Dispose … souffrir de malaises, de d‚pression. AccroŒt',
  'le souci du d‚tail et la m‚ticulosit‚.',
  'Marque un besoin profond de vivre en accord avec l''entourage.',
  'Fait fuir et craindre les heurts, l''agitation favorise le travail',
  'en ‚quipe et la diplomatie.',
  'Dispose aux troubles de sant‚, physiques ou mentaux. Marque une',
  'tendance … la d‚pression, aux humeurs morbides. Rend l''ambiance',
  'du travail tendue et agressive.',
  'Dispose … la fatigu‚ et … la confusion mentale. Fait craindre des',
  'oublis, des gaffes, des maladresses. Marque un voyage pour raison',
  'de travail ou de sant‚.',
  'Mine la force vitale et la volont‚. Dispose aux erreurs',
  'd''appr‚ciation dans le cadre professionnel. Peut marquer un arrˆt',
  'ou un changement d''activit‚.',
  'Dispose aux retards et aux contraintes dans les projets. Provoque',
  'des malentendus avec les amis, peut marquer ‚galement la maladie',
  'd''un ami ou d''un proche.',
  'Marque la fatigue, le surmenage, parfois la n‚cessite d''une',
  'hospitalisation ou d''une op‚ration. Rend vuln‚rable aux',
  'intoxications et aux infections.',
  'Favorise les unions et les associations. Dispose … plaire et …',
  'faire plaisir. Facilite les contacts avec un public ou une',
  'clientŠle. TrŠs favorable aux amours.',
  'Favorise les associations qu''il rend fructueuses. Mais il peut',
  '‚galement provoquer des querelles d''argent avec le conjoint, le',
  'partenaire. Rivalit‚s, litiges.',
  'Expose aux querelles, m‚sententes, ruptures avec l''entourage.',
  'Expose aux critiques, aux ragots. Porte … parler soi-mˆme avec',
  'malveillance des autres.',
  'Dispose au d‚m‚nagement, porte … abandonner un partenaire pour un',
  'autre. Risques de querelles avec les parents. Litiges au sujet',
  'd''une habitation.',
  'Favorise les rencontr‚s amoureuses, les sorties, les plaisirs.',
  'Fait b‚n‚ficier de l''aide et du soutien des relations. Se garder',
  'toutefois de promettre l''impossible.',
  'Dispose aux litiges professionnels. La p‚riode est marqu‚e par des',
  'd‚ceptions affectives ou des soucis au sujet du partenaire :',
  'souvent, la maladie de celui-ci.',
  'La p‚riode est domin‚e par le besoin de communication et de',
  'coop‚ration avec autrui. L''aspect est b‚n‚fique pour les',
  'contrats, les accords, les rencontr‚s, les unions.',
  'Dispose aux litiges, querelles et procŠs. Rend les associations',
  'troubles, susceptibles de fraudes. Peut marquer un divorce ou une',
  'rupture sentimentale.',
  'Favorise les rencontr‚s inhabituelles. AccroŒt la compr‚hension',
  'd''autrui et le d‚sir de communication. Peut marquer une rencontr‚',
  'sentimentale au cours d''un voyage.',
  'Favorise les collaborations professionnelles. Les contrats',
  'avantageux. Les unions et associations sont propices …',
  'l''ascension et … l''enrichissement.',
  'Est favorable au travail en ‚quipe et aux projets communs. Dispose',
  '… une activit‚ au sein d''un groupe, d''une association. AccroŒt',
  'l''importance de la vie amicale.',
  'Provoque l''incompr‚hension et l''incommunicabilit‚ avec le',
  'conjoint ou le partenaire, ou une ‚preuve touchant ce dernier. Les',
  'autres sont causes de soucis, de chagrins.',
  'Provoque dans l''existence d''importantes remises en question.',
  'Marque fr‚quemment une p‚riode de crise, de doute. Tendance au',
  'pessimisme, … l''autodestruction.',
  'Marque traditionnellement un h‚ritage, un legs. Peut ‚galement',
  'symboliser un h‚ritage moral : succession professionnelle.',
  'Bouleversement financier.',
  'Dispose aux incidents, accidents au cours des d‚placements. Marque',
  'une tension, une rupture avec un proche. Porte aux mensonges,',
  'ragots faits ou subis.',
  'Provoque une crise dans les rapports familiaux. Dispose …',
  'connaŒtre un changement ou une ‚preuve au sujet du domicile.',
  'Parfois, mort d''un membre de la famille.',
  'Indique une rentr‚e d''argent inattendue. Dispose aux',
  'sp‚culations, affaires mais attir‚ ‚galement vers des manoeuvres',
  'illicites. Soucis par ou pour les enfants.',
  'Nuit … la vitalit‚ et … la sant‚. Cause stress, id‚es noires,',
  'd‚pression. Peut signifier la perte d''emploi ou de graves',
  'difficult‚s dans le cadre du travail.',
  'Dispose aux crises et … la rupture avec l''associ‚ ou le',
  'partenaire. La p‚riode est ‚galement n‚faste … la sant‚ et la vie',
  'de ceux-ci. Litiges au sujet d''un contrat.',
  'Accorde une grande endurance, tant physique que mentale. Permet',
  'des choix ‚nergiques, des d‚cisions os‚es des remises en cause',
  'totales. AccroŒt le magn‚tisme.',
  'Perturbe les voyages, d‚placements, ‚changes. Risques accidentels.',
  'Trouble les rapports avec l''‚tranger. Marque parfois',
  'l''interruption brutale des ‚tudes.',
  'Introduit une crise dans le cadre professionnel. Marque le',
  'ch“mage, le changement d''orientation. Dispose … l''isolement et …',
  'la perte de cr‚dit. Scandales.',
  'Interrompt brutalement ou introduit d''importants retards dans le',
  'cours des projets. Dispose … s''‚loigner des relations',
  'habituelles. Crise dans les amiti‚s.',
  'Dispose … l''isolement, … la souffrance et … la maladie. Provoque',
  'd‚sarroi et pens‚es morbides. Marque une limitation de la libert‚',
  'morale ou physique.',
  'La p‚riode est favorable aux projets intellectuels, aux ‚tudes,',
  'aux ‚changes, aux activit‚s sportives. Accentue la la vision',
  'optimiste de l''avenir. Dispose aux voyages.',
  'Dispose … un accroissement des gains et de la libert‚ d''action.',
  'Favorise le commerce, les rapports financiers avec l''‚tranger.',
  'tend le champ d''activit‚.',
  'Favorise les projets en commun avec l''entourage. Indique la',
  'fr‚quentation de personnes jeunes, optimistes. Favorise',
  'l''enseignement et les professions ind‚pendantes.',
  'Marque l''int‚rˆt pour de nouveaux domaines, de nouvelles ‚tudes.',
  'Tendance … s''int‚grer … une association, … un groupe. Parfois,',
  's‚jour prolonge … l''‚tranger.',
  'Favorise les activit‚s artistiques, accroŒt la cr‚ativit‚,',
  'l''imagination originale. Dispose aux voyages d''agr‚ment.',
  'Favorise les rapports avec l''‚tranger.',
  'Dispose … des d‚marches dans le cadre du travail ou pour des',
  'raisons de sant‚. Danger de voir un projet de voyage annul‚ ou',
  'retard‚. Marque le d‚couragement.',
  'Favorise les d‚marches, la recherche d''appuis … ses projets.',
  'Dispose … ‚largir son horizon, … fr‚quenter de nouveaux milieux.',
  'Propice au travail en ‚quipe.',
  'Favorise l''exploration de domaines nouveaux, les ‚tudes sortant',
  'du commun, les exp‚riences psychiques. Dispose aux aventures',
  '‚tranges au cours de voyages.',
  'AccroŒt la chaleur et la compr‚hension dans les rapports avec',
  'l''environnement. Accorde l''estime et l''aide de l''entourage.',
  'Permet des voyages trŠs agr‚ables.',
  'AccroŒt la sensibilit‚ … l''opinion des autres. Fait rechercher',
  'les honneurs et l''admiration. La p‚riode promet des chances',
  'inattendues au niveau des rencontr‚s.',
  'Dispose … la collaboration dans les ‚tudes et les projets. Permet',
  'de voyager en compagnie d''amis, d''ˆtre invit‚ ou d''inviter.',
  'Promet des joies avec l''entourage.',
  'Marque des d‚ceptions et des obstacles dans les ‚tudes et les',
  'recherches. Dispose … souffrir de l''incompr‚hension d''autrui.',
  'preuve au cours de voyages.',
  'Accentue l''ambition et le d‚sir de reconnaissance sociale. La',
  'p‚riode permet de briller, d''entreprendre des actions',
  'importantes. l‚ment de chance et de r‚ussite.',
  'La p‚riode est marqu‚e par des problŠmes d''efficacit‚, de',
  'rendement et de production. L''aspect favorise les gains, les',
  'promotions, la stabilit‚ professionnelle.',
  'Favorise l''audace et l''ind‚pendance dans le cadre de la',
  'profession. Permet d''obtenir des appuis et cr‚dits venant de',
  'l''entourage. D‚marches financiŠres.',
  'Marque un tournant important dans les activit‚s professionnelles :',
  'dispose … un changement d''orientation, … la satisfaction de ses',
  'ambitions.',
  'Est excellent dans le domaine professionnel ou il pr‚sage la',
  'r‚ussite, des coups d''‚clats. AccroŒt la confiance en soi et',
  'permet de d‚montrer ses talents.',
  'Introduit des retards et des obstacles dans les activit‚s',
  'professionnelles. Fait commettre des erreurs et maladresses dans',
  'la vie pratique. Limite les ambitions.',
  'Permet de rencontrer une collaboration ou une amiti‚ dans le',
  'milieu professionnel. Favorise les contrats d''affaires. Permet de',
  'recevoir l''accord d''un public.',
  'Provoque des bouleversements dans la profession. Permet d''exercer',
  'une activit‚ plus conforme … ses d‚sirs, favorise l''ind‚pendance',
  'et les initiatives secrŠtes.',
  'Est favorable … la popularit‚. Permet d''‚tendre le champ de ses',
  'activit‚s. Influence heureusement les activit‚s sportives,',
  'l''enseignement, le commerce.',
  'Est porteur d''un courant de chance pure qui aide … l''ascension',
  'et … la r‚ussite des entreprises. P‚riode propice … l''autorit‚,',
  'au prestige et … la renomm‚e.',
  'Favorise surtout les associations et les travaux d''‚quipe. La',
  'p‚riode est excellente et permet de poser les les jalons de futurs',
  'projets. Indice d''optimisme.',
  'Apporte des obstacles dans la profession. Donne l''impression de',
  'se heurter … un mur, an‚antit les efforts. Une maladie peut',
  'contraindre … l''inactivit‚.',
  'Dispose … rechercher et … connaŒtre l''harmonie dans les relations',
  'humaines. Accentue l''affectivit‚ et la s‚duction. Aspect de',
  'd‚sint‚ressement et d''altruisme.',
  'Dispose aux gains dans des associations. Peut marquer une',
  'd‚pendance financiŠre vis-…-vis d''amis ou une aide r‚ciproque.',
  'Favorise les demandes de cr‚dits.',
  'Dispose aux relations faciles et d‚tendues avec l''environnement.',
  'Favorise les rencontr‚s et d‚placements amicaux. Facilite les',
  'conciliation, les accords.',
  'AccroŒt la sociabilit‚, dispose aux sorties, rencontr‚s,',
  'invitations. Peut marquer la cohabitation avec des amis. Favorise',
  'la compr‚hension mutuelle en famille.',
  'Dispose aux sorties nombreuses et distractions parfois co–teuses.',
  'AccroŒt la chaleur et l''enthousiasme dans les rapports amicaux.',
  'Favorise la publicit‚.',
  'Accorde vitalit‚ et souci d''‚quilibre physique et nerveux.',
  'Influence heureusement les convalescence. Permet de trouver un',
  'climat amical dans l''existence quotidienne.',
  'Met l''accent sur la vie conjugale et associative. Marque une',
  'grande exigence de qualit‚ dans les relations affectives. Expose …',
  'connaŒtre la jalousie de tiers.',
  'Rend trŠs s‚lectif dans le domaine des amiti‚s. AccroŒt la',
  'profondeur des liens r‚sistant … cette ‚preuve. Permet de',
  'rencontrer des protections secrŠtes.',
  'Dispose … ˆtre influence pour le meilleur ou pour le pire par les',
  'amiti‚s et les relations. Favorise les voyages … l''‚tranger. Rend',
  'd‚pendant de l''opinion d''autrui',
  'Favorise la rencontre d''aides, d''appuis solides et de',
  'suggestions avis‚es. Permet de recevoir la confiance de',
  'l''entourage. Fait esp‚rer gains et admiration.',
  'Dispose … ‚largir le cercle de ses amiti‚s. Marque un int‚rˆt pour',
  'les activit‚s sociales et pour les sciences humaines. Favorise la',
  'ovation et l''ind‚pendance.',
  'Indique des d‚ceptions affectives, des soucis par ou pour des',
  'amis. Dispose aux trahisons, aux mensonges. Retarde ou an‚antit',
  'les projets les plus attendus.',
  'Dispose aux chagrins et … la solitude. Provoque l''incompr‚hension',
  'des proches et la m‚sentente avec la famille. Expose … la maladie',
  'et … l''immobilit‚ forc‚e.',
  'Met l''accent sur des ‚preuves financiŠres : dettes qui',
  's''accumulent. Vols ou pertes subis. Les difficult‚s',
  'professionnelles obligent … une limitation de confort.',
  'Dispose aux erreurs de jugement. Porte … vivre dans une atmosphŠre',
  'de mensonges et d''illusions. Expose … faire des confidences',
  'inconsid‚r‚ment.',
  'Met l''accent sur des ‚preuves familiales. Signifie ‚galement des',
  'difficult‚s au niveau du logement : pertes mobiliŠres ou',
  'd‚m‚nagement force. Maladie d''un parent.',
  'Limite la joie de vivre et la vitalit‚. Dispose aux d‚ceptions',
  'amoureuses, aux soucis par les enfants. Les cr‚ations ne',
  'rencontrent pas d''‚cho favorable.',
  'Dispose aux ennuis de sant‚, … la fatigue. Les servitudes de la',
  'vie quotidienne se font pesantes. Fait subir la malhonnˆtet‚',
  'd''autrui. Rend timide, d‚pendant',
  'Dispose aux ruptures et au divorce. Marque une ill‚galit‚',
  'quelconque : procŠs, dettes. Les contrats se r‚vŠlent',
  'd‚savantageux, les unions, associations troubles.',
  'Expose aux troubles physiques et aux malaises de de nature',
  'psychique. Dispose … la d‚pression, marque des penchants',
  'suicidaires. Risques d''hospitalisation.',
  'Dispose aux attitudes ‚go‹stes, sectaires. Marque une tendance …',
  'la r‚gression et au d‚sabusŠrent. Un voyage peut ˆtre annul‚ ou',
  'difficile. tudes d‚favoris‚es.',
  'Dispose aux ‚preuves d''ordre professionnel : ch“mage, incapacit‚,',
  'mauvaise ambiance, stagnation. Nuit … la r‚putation. Bride les',
  'ambitions et les efforts.',
  'Dispose … la solitude, … l''‚loignement d''amis et … la',
  'd‚faillance de protections, d''appuis. La communication est',
  'difficile avec l''entourage. Nervosit‚ excessive.',
  'La p‚riode est marqu‚e par la limitation des possibilit‚s',
  'physiques et mentales. Fait connaŒtre l''‚chec dans les projets.',
  'Dispose aux maladies, … l''h“pital, … la solitude',
  'Dispose … la colŠre, … l''imprudence et aux initiatives',
  'irr‚fl‚chies. Augmente le dynamisme, le d‚sir de changement, de',
  'mouvement, mais rend vell‚itaire.',
  'AccroŒt le sens pratique et l''obstination. Augmente la solidit‚,',
  'la stabilit‚, la fid‚lit‚ mais rend possessif, jaloux et',
  'irritable.',
  'Provoque l''h‚sitation devant plusieurs voies. AccroŒt',
  'l''intuition, affine l''intelligence. Facilite les contacts avec',
  'l''entourage, mais augmente la nervosit‚.',
  'Dispose … la passivit‚ et au rˆve. Permet la conception de',
  'nombreux projets mais n''en facilit‚ pas la concr‚tisation.',
  'Accorde la protection de l''entourage.',
  'Augmente la vitalit‚ et l''app‚tit de vivre. Tourne l''existence',
  'vers les plaisirs. AccroŒt l''audace, la g‚n‚rosit‚, l''ambition',
  'et l''orgueil.',
  'Favorise les travaux intellectuels et la minutie. P‚riode',
  'excellente pour les ‚tudes et le perfectionnement. Marque souvent',
  'l''anxi‚t‚, l''appr‚hension devant l''avenir.',
  'Accorde une grande aisance dans les relations. Rend trŠs attirant.',
  'Permet de s‚duire un public, augmente le go–t des plaisirs et',
  'facilite l''expression artistique.',
  'Augmente l''‚nergie, l''ambition, la puissance, la volont‚ de',
  's''imposer. Accentue l''individualisme. Fait vivre dans une',
  'ambiance tendue, agressive.',
  'Fait b‚n‚ficier d''un bon ‚quilibre mental et physique. Augmente',
  'le besoin de mouvement, le dynamisme. Facilite la vie mat‚rielle',
  'en accordant des gains faciles.',
  'AccroŒt la m‚fiance et la tendance … temporiser. Dispose … la',
  'r‚serv‚, … l''‚conomie, voire … l''avarice. Marque un repli vers',
  'le pass‚ et la s‚curit‚.',
  'Provoque l''‚parpillement et la d‚sorganisation. Marque une',
  'tendance excessive … compter sur l''aide des autres. P‚riode ou',
  'l''on vit surtout avec ou par un groupe.',
  'Rend vuln‚rable physiquement et emotionnellement. Augmente les',
  'risques d''illusions, de mensonges, d''erreurs marque une tendance',
  '… la r‚signation, au d‚couragement.',
  'Est facteur d''instabilit‚ mat‚rielle, financiŠre. Dispose aux',
  'pertes par imprudence ou inattention. P‚riode d''alternance entre',
  '‚lan optimiste et d‚couragement.',
  'Favorise plus les employ‚s que les ind‚pendants. Dispose … la',
  'conscience professionnelle et au sens pratique. Permet la',
  'stabilit‚ mat‚rielle et la pr‚voyance.',
  'La p‚riode est marqu‚e par des changements professionnels. Permet',
  'l''adaptation et l''extension de ses activit‚s. Propice au',
  'commerce et aux rapports avec un public.',
  'Favorise l''adaptation passive aux circonstances. Promet de',
  'nombreux petits gains mais non la stabilit‚ financiŠre la vie',
  'mat‚rielle est ‚troitement li‚e au milieu familial.',
  'Favorise l''ambition et l''autorit‚. Permet de prendre des',
  'd‚cisions ‚nergiques en matiŠre financiŠre. Facilite les rentr‚es',
  'd''argent, dispose au confort.',
  'Favorise les travaux de longue haleine, les ‚tudes scientifiques,',
  'la r‚flexion. P‚riode propice aux demandes de prˆts ou de cr‚dits.',
  'Pr‚voyance et ‚conomie.',
  'Les initiatives sont brillantes, remarqu‚es et favorisent la',
  'reconnaissance de soi. La p‚riode est marqu‚e par des invitations',
  'et sorties. Dispose aux d‚penses excessives.',
  'Permet la poursuite des efforts dans le sens des ambitions la',
  'situation financiŠre est souvent difficile et marqu‚e par des',
  'litiges. AccroŒt la t‚nacit‚ et l''autoritarisme.',
  'Favorise les activit‚s ind‚pendantes, le commerce et ceux qui',
  'voyagent pour leur travail. Peut marquer un contact professionnel',
  '… l''‚tranger. Permet l''expansion financiŠre.',
  'Dispose … la pr‚voyance et … l''organisation mat‚rielle. Rend',
  'soucieux de ses possessions et financiŠrement m‚fiant la p‚riode',
  'est marqu‚e par des restrictions ou des pertes',
  'parpill‚ les efforts et rend instable dans les activit‚s',
  'professionnelles. Permet pourtant de rencontrer des appuis',
  'providentiels, dans le milieu amical.',
  'Dispose … d‚pendre financiŠrement des autres, ou, au contraire, …',
  'prˆter ou … donner de l''argent … autrui. Fait manquer',
  'd''organisation mat‚rielle et de pr‚voyance.',
  'L''aspct dispose … de multiples rencontr‚s ‚ph‚mŠres. D‚stabilis‚',
  'les relations d‚j… existantes. Facilite l''‚closion des id‚es,',
  'mais non leur mise en pratique.',
  'Dispose aux conceptions pratiques, aux projets modestes mais',
  'facilement r‚alisables. Favorise les travaux manuels. Provoque des',
  'jalousies, attise les rancunes. Calomnies.',
  'Dispose … rechercher un environnement jeune et optimiste. Facilite',
  'l''expression verbale et ‚crite. Accentue les facult‚s de',
  'raisonnement et la perspicacit‚.',
  'Fait vivre en cercle restreint. Dispose … des heurts avec la',
  'famille. Expose aux attaques, aux insultes. La p‚riode est marqu‚e',
  'par la prudence dans les relations.',
  'Dispose au plaisir, aux rencontr‚s sentimentales nombreuses mais',
  'peu stables. Tendance … ˆtre imprudent dans ses actes et ses',
  'propos., A prendre des d‚cisions hƒtives.',
  'Favorise les travaux intellectuels de recherche, les classements.',
  'Les perfectionnements. Fait accorder de l''importance aux d‚tails.',
  'Marque un repli sur soi.',
  'Favorise les activit‚s artistiques, amplifie l''imagination.',
  'Facilite les conceptions nouvelles. Marque un d‚sir de renouveler',
  'son entourage.',
  'Provoque des crises dans les amiti‚s et rend trŠs s‚lectif dans le',
  'choix de ses relations. Tourne surtout vers la r‚flexion. Marque',
  'des exp‚riences bizarres.',
  'La p‚riode est marqu‚e par de nouvelles amiti‚s. Facilite la',
  'conciliation, l''harmonie, la diplomatie. Permet de rencontrer',
  'dans le travail des appuis spontan‚s.',
  'Permet l''accord de personnes solides … ses projets dispose aux',
  '‚tudes scientifiques, … la pr‚cision. Marque une attirance pour',
  'une vie retir‚e, paisible, solitaire.',
  'Dispose … l''inconstance et … la dispersion. Une tendance … ne pas',
  'savoir dire non peut entraŒner dans des situations tendues.',
  'Multiplie les rencontr‚s.',
  'Dispose … tromper ou … ˆtre trompe. Il introduit de la confusion',
  'dans les ‚changes et les relations. Expose … la m‚disance.',
  'Tendance au pessimisme et aux d‚ceptions.',
  'Dispose … ressentir les liens familiaux comme une entrave. Porte …',
  'la r‚volte et aux ruptures brutales. Rend instable et insatisfait',
  'dans la vie affective.',
  'Dispose … l''enracinement. Marque une tendance … s''accrocher …',
  'l''entourage, … se montrer jaloux. Dans le travail, facilite',
  'l''effort et la pers‚v‚rance.',
  'Dispose … la mobilit‚ et … l''instabilit‚. Indice de sorties, de',
  'detachemement du milieu familial. D‚stabilis‚ les liens affectifs,',
  'porte … l''infid‚lit‚.',
  'Dispose au bien-ˆtre dans la vie familiale. Apporte',
  'l''‚panouissement affectif, fait connaŒtre des liens chaleureux et',
  'solides. D‚penses pour l''habitation.',
  'Dispose aux changements de tous ordres. Rend la vie priv‚e',
  'tributaire de l''impr‚vu. Recommande la mesure dans les actions et',
  'la mod‚ration dans les d‚penses.',
  'Dispose au soup‡on et … l''inqui‚tude. La p‚riode est marqu‚e par',
  'une ambiance familiale pesante. Tendance … tout analyser. Peut',
  'marquer une personne malade au foyer.',
  'Dispose aux conciliation et r‚conciliations. panouit les',
  'aspirations sentimentales. La p‚riode est excellente pour',
  'l''inspiration artistique.',
  'Dispose … l''‚conomie dans la gestion de ses biens. Peut marquer',
  'des discordes familiales au sujet d''h‚ritages, de contrats.',
  'Aspect favorable aux enfants.',
  'Dispose … la d‚pens‚ de ses ‚nergies. Marque une p‚riode agit‚e,',
  'un besoin de sortir du cadre habituel. Se m‚fier toutefois du',
  'surmenage et des excŠs.',
  'La p‚riode est marqu‚e par un climat de frustration et de',
  'solitude. Dispose … l''‚loignement force de sa famille ou …',
  'l''incompr‚hension au sein de celle-ci.',
  'Dispose … l''instabilit‚ dans les d‚sirs. Rend trŠs d‚pendant de',
  'la famille. Marque un manque d''audace et de volont‚. AccroŒt',
  'l''attachement au confort et au mat‚riel.',
  'Introduit dans la famille ou la maison un climat de trouble et',
  'd''incertitude. Marque une tendance … fuir les r‚alit‚s. Augmente',
  'la passivit‚.',
  'Dispose aux excŠs. AccroŒt la mobilit‚ mais disperse l''action.',
  'Accorde de petites chances passagŠres. Conseille de mod‚rer sa',
  'violence et son impulsivit‚.',
  'Favorise l''‚laboration patiente des projets. Dispose … profiter',
  'des plaisirs mat‚riels de l''existence. Porte … la stabilit‚',
  'affective, mais accroŒt la jalousie.',
  'Dispose … l''inconstance et … l''instabilit‚. Les affections sont',
  'changeantes, les liens peu durables. Favorise surtout',
  'l''expression plaisante et les loisirs.',
  'Dispose … la satisfaction des d‚sirs affectifs. Fait connaŒtre des',
  'relations tendres et compr‚hensives. AccroŒt le bien-ˆtre.',
  'Facilite le contact avec les enfants.',
  'AccroŒt l''ext‚riorisation de soi et la vitalit‚. Favorise',
  'l''ambition. Permet de forcer les situations … son avantage.',
  'Marque une tendance aux d‚penses excessives.',
  'Restreint le confort mat‚riel et le budget. Dispose au pessimisme',
  'et … l''inqui‚tude. La p‚riode est marqu‚e par une diminution de',
  'la force vitale.',
  'Marque une liaison, un accord affectif, parfois une union. Dispose',
  'aux conciliation et r‚conciliations. Fait rechercher',
  'l''approbation et l''admiration des autres.',
  'Peut pr‚sager une naissance dans l''entourage. Par contre, il est',
  'n‚faste … la sant‚ des personnes ƒg‚es. Dispose aux excŠs, … la',
  'violence et … la jalousie.',
  'Dispose aux plaisirs et … l''‚panouissement. Favorise les voyages',
  'd''agr‚ment, les s‚jours … l''‚tranger. Peut marquer une liaison',
  'en voyage ou avec un ‚tranger.',
  'Dispose … l''‚conomie, volontaire ou forc‚e. Diminue la joie de',
  'vivre et le go–t des plaisirs. Marque l''isolement et le sentiment',
  'd''abandon affectif.',
  'Dispose … b‚n‚ficier d''avantages sans fournir trop d''efforts.',
  'Permet de susciter la sympathie et l''aide de l''entourage.',
  'Dispose aux flirts et … l''infid‚lit‚.',
  'AccroŒt le flair et l''intuition. Permet des gains inattendus et',
  'favorise les jeux de hasard. Fait chercher les plaisirs les plus',
  'vari‚s. Porte … l''infid‚lit‚.',
  'Dispose … l''imprudence, … la t‚m‚rit‚ et … la maladresse. Risques',
  'de chutes, de coups, d''accidents. Marque une atmosphŠre de',
  'travail agressive et ‚prouvante.',
  'La p‚riode paisible et stable permet de r‚g‚n‚rer son ‚nergie.',
  'Facilite les tƒches quotidiennes, accroŒt le sens de',
  'l''organisation et l''habilet‚ manuelle.',
  'Dispose … accorder sa confiance trop na‹vement. Ne facilite guŠre',
  'le travail suivi, rend les actes confus. Expose aux troubles',
  'nerveux ou aux maladies respiratoires.',
  'Provoque des soucis domestiques et familiaux. Peut signifier',
  'personne malade … sa charge. Favorise le travail chez soi, la',
  'collaboration avec un proche.',
  'Apporte des contraintes, limite la confiance en soi. AccroŒt',
  'l''inqui‚tude au sujet des enfants. Ne rend jamais satisfait de',
  'son travail. Mine la vitalit‚.',
  'Dispose … souffrir d''un mode de vie restrictif. Ne facilite guŠre',
  'l''entente dans le travail. Marque des heurts pour peu de chose.',
  'Risque d''intoxication.',
  'Dispose … la conciliation dans le cadre du travail. D‚velopp‚ la',
  'diplomatie, accroŒt la serviabilit‚. Risques de troubles r‚naux,',
  'd''an‚mie, de refroidissements.',
  'Favorise la psychologie et la strat‚gie dans les rapports de',
  'travail. Dispose … vouloir changer d''orientation. Risques',
  'd''excŠs de plaisirs nuisibles … la sant‚.',
  'Permet d''‚tendre ses activit‚s, marque un voyage pour le travail.',
  'AccroŒt la mobilit‚, le go–t du risque. Risques de troubles du',
  'foie, d''entorses ou de fractures.',
  'AccroŒt le sens des responsabilit‚s et le go–t des d‚tails. Fait',
  'rechercher la difficult‚, rend exigeant dans les rapports de',
  'travail. Risques de surmenage.',
  'Favorise le travail en ‚quipe et l''imagination. Fragilis‚ la',
  'sant‚, particuliŠrement l''‚quilibre nerveux. Peut pr‚sager une',
  'hospitalisation, une op‚ration urgente.',
  'Provoque des difficult‚s dans le travail. Porte … la solitude',
  'physique ou morale, … l''inadaptation. Risques de troubles',
  'psychiques, de confinŠrent. H“pital.',
  'Dispose aux emballements sentimentaux et peut provoquer un mariage',
  'pr‚matur‚, une liaison illusoire. Dispose … ressentir amour,',
  'haine, chagrin intens‚ment.',
  'Dispose … la stabilit‚ dans les liens affectifs. AccroŒt la',
  'tendresse et la sensualit‚., Mais aussi la la jalousie, la',
  'possessivite, les id‚es fixes.',
  'Favorise les rencontr‚s amicales et la complicit‚ dans les',
  'rapports avec le partenaire ou le conjoint. Permet de s''exprimer',
  'avec aisance et d''attirer la sympathie.',
  'AccroŒt la vuln‚rabilit‚ affective et augmente la d‚pendance …',
  'l''‚gard du partenaire. Tendance … employer des moyens mensongers',
  'ou maladroits dans ses activit‚s.',
  'Associe les rapports amoureux et la domination : tyrannie exerc‚e',
  'sur le partenaire ou subie venant de lui. Un orgueil excessif peut',
  'perturber les relations humaines.',
  'Nuit … l''entente entre conjoints et associ‚s. Porte … se laisser',
  'abuser ou entraŒn‚ dans des contraintes inutiles. Risques',
  'd''abandon sentimental ou de soumission.',
  'Favorise les collaborations et associations. Sentimentalement,',
  'marque une tendance … la double vie, … l''infid‚lit‚. Nombreuses',
  'aventures passagŠres.',
  'Dispose aux rapports troubles, tourment‚s avec autrui. Marque des',
  'calomnies, des injures, des abus. Conseille de conserver ses',
  'secrets.',
  'Dispose … l''enthousiasme dans les rapports avec autrui. Permet',
  'd''avoir des relations chaleureuses tout en conservant son',
  'autonomie. Facilite la publicit‚.',
  'Dispose … la m‚fiance dans les rencontr‚s et … la mod‚ration dans',
  'les liens affectifs. Marque une liaison avec une personne plus',
  'ƒg‚e.',
  'Dispose … gagner son entourage … ses projets et … faire des',
  'adeptes. Permet de rencontrer des amis ayant des buts communs.',
  'Dispose aux aventures sentimentales.',
  'AccroŒt les exigences affectives et sensuelles. Porte …',
  's''associer imprudemment, … tromper ou ˆtre trompe. Les liens',
  'nou‚s, … cette ‚poque, sont instables, ‚tranges.',
  'Dispose aux d‚penses excessives et aux efforts physiques abusifs',
  'ou dangereux. Indice de coups, de chute, blessure, br–lure. Danger',
  'pour la vie d''un proche masculin.',
  'Provoque des maux physiques b‚nins mais p‚nibles. Marque un d‚go–t',
  'et un d‚sint‚rˆt pour sa vie quotidienne. Remet en question la',
  's‚curit‚ financiŠre et le confort.',
  'Dispose … la fatigu‚ c‚r‚brale et … l''‚puisement nerveux. Marque',
  'des initiatives d‚sordonn‚es, maladroites. Rend instable',
  'emotionnellement, id‚es fixes, insomnies.',
  'Diminue la r‚sistance physique et ‚motionnelle aux agressions',
  'venant de l''ext‚rieur. Introduit un climat de crise dans les',
  'rapports familiaux.',
  'Dispose … brider ses d‚sirs, … mettre un frein … ses aspirations.',
  'Diminue la r‚sistance nerveuse. Provoque des conflits avec le pŠre',
  'ou la hi‚rarchie.',
  'Provoque des tensions dans la cadre du travail. Dispose … gagner',
  'de l''argent dans des activit‚s originales. Danger d''intoxication',
  'ou d''op‚ration b‚nigne.',
  'Dispose au mal de vivre. Marque une tendance aux excŠs de',
  'nourriture et de boisson. Parfois, penchants autodestructeurs.',
  'galement, dangers de troubles r‚naux.',
  'Introduit des bouleversements dans le domaine financier. Risque',
  'd''ˆtre d‚poss‚d‚. La p‚riode est marqu‚e par des soucis',
  'permanents au sujet de sa sant‚.',
  'Favorise l''accroissement du confort mat‚riel. La p‚riode est',
  'marqu‚e par des rapports tendus avec des ‚trangers ou par des',
  '‚preuves au cours de voyages.',
  'AccroŒt l''ambition, mais marque une tendance … outrepasser ses',
  'forces et ses possibilit‚s. Introduit un d‚sir de changement au',
  'niveau de la profession.',
  'Dispose … l''‚puisement nerveux. Porte … mettre toute son ‚nergie',
  'dans des projets nouveaux mais … se heurter … un mur. Crises,',
  'dissensions dans les amiti‚s.',
  'EntraŒn‚ des initiatives financiŠres os‚es. Introduit un climat de',
  'mensonge, de fraude dans les actes. Risque d''intoxication,',
  'd''infection, de d‚s‚quilibre nerveux.',
  'La p‚riode dispose … l''audace dans les pens‚es, au courage et …',
  'l''enthousiasme dans les convictions. Favorise les projets',
  'originaux. Indice de d‚placements nombreux.',
  'Dispose au bon sens, aux conceptions pratiques. Favorise les',
  'initiatives traditionnelles et patientes. P‚riode propice aux',
  '‚tudes scientifiques et techniques.',
  'Favorise l''expression orale ou ‚crite. AccroŒt l''importance du',
  'courrier, des conversations dans la vie. Indice de voyages pour',
  'les ‚tudes ou les projets.',
  'AccroŒt la sensibilit‚, l''imagination, augmente la m‚moire et',
  'l''intuition. Diminue, en revanche, le sens pratique. Risques',
  'd''incidents bizarres pendant un voyage.',
  'Favorise les initiatives d''envergure. AccroŒt le d‚sir de',
  'voyager, d''exp‚riences inhabituelles. Permet de rencontrer des',
  'appuis solides et l''accord du public.',
  'Dispose … se perdre dans les d‚tails et … p‚cher par excŠs de',
  'prudence. Marque une tendance … l''isolement. Favorise toutefois',
  'les travaux minitueux et la pr‚cision.',
  'Dispose … l''inconstance dans les id‚es et les actions. La p‚riode',
  'd‚stabilis‚ les relations anciennes. Fait commettre des',
  'imprudences au cours de voyages.',
  'Favorise l''‚tude de domaines sortant du commun. Influence',
  'particuliŠrement les recherches occultes, les exp‚riences',
  'psychiques. Fait cultiver le go–t du secret.',
  'Favorise les ‚tudes sup‚rieures, les voyages professionnels,',
  'l''enseignement. AccroŒt la force mentale. Favorise les voyages et',
  'les s‚jours … l''‚tranger.',
  'Favorise l''‚tude solitaire, les entreprises demandant l''appui du',
  'temps, les activit‚s ind‚pendantes. Marque une tendance volontaire',
  '… l''isolement, au silence.',
  'Dispose … rechercher avant tout la compagnie des autres. Permet de',
  'collaborer … des projets originaux et multiplie les occasions de',
  'rencontr‚. AccroŒt l''optimisme.',
  'AccroŒt la puissance de l''imagination. Tendance … poursuivre des',
  'chimŠres. Dispose … de lointains voyages par le corps ou le rˆve.',
  'Recherches spirituelles.',
  'Accorde ‚nergie physique et mentale, dispose au mouvement et … la',
  'combativit‚. Porte … prendre des risques dans la profession.',
  'Propice aux activit‚s ind‚pendantes.',
  'Dispose … l''effort patient et … l''‚conomie. AccroŒt surtout le',
  'sens pratique. Assure la stabilit‚ dans le travail. Rend trŠs',
  'sensible aux flatteries.',
  'Dispose … la curiosit‚, … l''habilet‚, … la ruse. Accentue',
  'consid‚rablement les facult‚s d''adaptation. Permet de mener …',
  'bien plusieurs actions simultan‚ment.',
  'Rend r‚ceptif aux situations ext‚rieures. Cette tendance permet de',
  'profiter d''excellentes opportunit‚s. Introduit de la fantaisie',
  'dans les activit‚s.',
  'Marque une tendance importante … rechercher toutes occasions de',
  'briller. Favorise surtout les m‚tiers en contact avec une',
  'clientŠle, les projets artistiques.',
  'Dispose … la stabilit‚ dans la profession. AccroŒt la pr‚cision,',
  'la conscience. Permet d''augmenter ses qualifications. Crainte de',
  'l''avenir.',
  'Dispose … avoir des id‚es vari‚es et originales. Permet de',
  's''adapter facilement aux circonstances. Dispose … avoir une',
  'liaison avec une personne trŠs jeune.',
  'Favorise la combativit‚ et l''‚nergie dans les activit‚s',
  'professionnelles. La p‚riode est marqu‚e par un climat de violence',
  'et de luttes. Remises en cause.',
  'Fait connaŒtre une certaine instabilit‚ dans le domaine',
  'professionnel. Dispose … rechercher de nouvelles activit‚s.',
  'Favorise la chance dans l''inhabituel.',
  'Ralentit et limite les activit‚s professionnelles favorise',
  'pourtant les recherches patientes, les travaux minutieux. Tendance',
  '… l''isolement et … la r‚serv‚.',
  'Rend le climat professionnel fluctuant et flou. Permet de tirer',
  'son avantage de ce caractŠre incertain. Favorise les rencontr‚s',
  'devenant des appuis. Optimisme.',
  'Dispose … se cantonner dans le quotidien. Marque une tendance … se',
  'fondre dans un groupe, … d‚missionner. Rend d‚pourvu et malhabile',
  'dans les situations impr‚vues.',
  'Rend impulsif et souvent imprudent dans le domaine des nouvelles',
  'amiti‚s. Porte … n‚gliger les liens anciens ou … provoquer',
  'brutalement leur rupture.',
  'Dispose … se laisser accaparer par des affections ‚touffantes, par',
  'des relations tyranniques. AccroŒt la jalousie et la m‚fiance.',
  'Ralentit les projets. Soup‡ons.',
  'Marque une popularit‚ croissante dans le domaine amical. Attire',
  'sympathies et attentions. Introduit dans les projets instabilit‚',
  'et mauvaise organisation.',
  'Dispose au repli sur soi et sur le pass‚. Fait craindre des',
  'promesses non tenues, des projets chim‚riques accroŒt la passivit‚',
  'et diminue le sens pratique.',
  'Dispose … exercer une autorit‚, une emprise sur ses relations et',
  'ses amis. Marque la superficialite dans les rencontr‚s. Favorise',
  'les artistes, la popularit‚.',
  'Limite les relations amicales, les sorties et les distractions.',
  'Fait rechercher le s‚rieux et la pr‚cision dans les activit‚s et',
  'les projets. AccroŒt la m‚fiance.',
  'Dispose … la superficialite dans les amiti‚s. Fait subir la',
  'jalousie dans les relations professionnelles sentimentalement,',
  'rend instable, charmeur et volage.',
  'Introduit des tensions dans les relations et les amiti‚s. Exacerbe',
  'la violence des amours comme des haines. Marque des ruptures ou',
  'des litiges au sujet de projets.',
  'Accentue l''extraversion et marque une tendance aux relations',
  'multiples. Dispose au bavardage et … la na‹vet‚. Porte … faire des',
  'promesses inconsid‚r‚es.',
  'Dispose … la solitude et … l''insociabilite. Seuls les liens',
  '‚prouves par le temps r‚sisteront … un sens critique',
  'intransigeant. Favorise les ‚tudes scientifiques.',
  'Dispose … la confiance et … l''aisance dans les relations',
  'amicales. En revanche, marque l''incompr‚hension dans la famille.',
  'Indice de conceptions originales, neuves.',
  'Dispose aux relations troubles et int‚ress‚es. Porte …',
  's''illusionner au sujet de projets utopiques. Fait souvent subir',
  'des attaques secrŠtes et des calomnies.',
  'Dispose aux coups du sort, revirements n‚fastes, coups de tˆte',
  'dangereux et aux accidents. Provoque des querelles, ruptures et',
  'des violences physiques.',
  'Dispose aux soucis financiers et mat‚riels. Fait supporter des',
  'conditions de travail p‚nibles, de lourdes responsabilit‚s',
  'morales. M‚sentente dans le couple.',
  'Dispose … l''inconscience, aux paroles et aux actes malheureux.',
  'Marque l''inadaptation … la vie pratique. Expose aux initiatives',
  'financiŠres dangereuses, troubles.',
  'AccroŒt la vuln‚rabilit‚ et dispose aux ‚preuves affectives :',
  'frustration, abandon du partenaire, isolement. La famille et le',
  'logement sont sources de problŠmes.',
  'Provoque l''incompr‚hension et l''illusion dans les rapports',
  'sentimentaux ou avec les enfants. Porte … se raidir dans un refus',
  'de l''autre, … craindre des vexations.',
  'Provoque une inadaptation au milieu du travail. La vie quotidienne',
  'est ressentie comme d‚primante. Marque une tendance … perdre pied,',
  '… craindre pour l''avenir.',
  'Provoque la m‚sentente. L''insatisfaction s''enfle et se manifeste',
  'par des paroles aigres. Dispose … l''envie, … la rancune.',
  'Querelles avec le partenaire ou l''associ‚.',
  'Augmente l''esprit de lutte et l''acharnement. Fait connaŒtre des',
  'obstacles ext‚rieurs, des conditions de vie ‚prouvantes. Rend',
  'taciturne, farouche et r‚volte.',
  'Trouble le mental et porte … s''illusionner sur des projets peu',
  'viables. Dispose aux n‚gligences et aux oublis. preuves au cours',
  'd''un voyage ou dans les ‚tudes.',
  'Est source d''‚preuves dans la vie professionnelle et sociale.',
  'Peut signifier le ch“mage ou le manque de qualifications.',
  'D‚conseille toute initiative risqu‚e.',
  'Dispose … la fragilit‚ physique et nerveuse. Dispose au lunatisme',
  'et aux entreprises vell‚itaires. Expose aux abandons amicaux, …',
  'l''incompr‚hension mutuelle.',
  'Affaiblit la volont‚ et dispose … se laisser porter par les',
  '‚v‚nements et influencer n‚gativement. Nuit … la libert‚ morale et',
  'physique. Pessimisme.',
  'Il est prudent de ne pas d‚voiler ses projets durant cette',
  'p‚riode. Pr‚sage des satisfactions d''amour propre.',
  'L''activit‚ mentale est excessive. Il faut faire l''effort de',
  'fixer la pens‚e et attendre une p‚riode plus favorable.',
  'Dispose … la recherche du sexe oppos‚. Peut marquer un mariage ou',
  'une union. Favorable aux arts et … l''argent.',
  'P‚riode de vitalit‚ allant souvent de pair avec une exag‚ration de',
  'ses moyens et possibilit‚s.',
  'Augmente la vitalit‚ et les possibilit‚s mat‚rielles. Peut',
  'concorder avec un avancement professionnel.',
  'Expose … des ennuis dans tous les domaines. Contraire … la sant‚.',
  'Indice de solitude et de restriction sentimentale.',
  'Prendre garde aux mouvements de r‚volte et d''ind‚pendance.',
  'Favorable aux ind‚pendants et … la marginalit‚.',
  'Augmente l''intensit‚ des qualit‚s passives : ‚motivit‚,',
  'intuition, sensitivit‚, imagination et clairvoyance.',
  'Intensifie la sexualit‚ et le go–t de la conquˆte. Rend optimiste,',
  'sur de soi et ‚nergique. On vit sous tension.',
  'Augmente la compr‚hension entre les ‚poux et associ‚s. Favorable',
  'aux d‚placements. Aide … voir clair en soi.',
  'Influence heureusement toutes les petites transactions ainsi que',
  'les rapports entre employeurs et employ‚s.',
  'Dispose … l''indulgence et … la bonne humeur. Incite … plaire et …',
  'se faire remarquer. Satisfactions d''amour-propre.',
  'Fortifie le mental et le physique en am‚liorant la sant‚ des',
  'malades. Donne une vue plus claire des r‚alit‚s. Optimisme.',
  'Am‚lior‚ l''‚tat physique et pr‚dispos‚ … la sympathie. Bonne',
  'humeur, optimisme et indulgence. Confiance en soi.',
  'Dispose … la prudence et … avoir une vue claire des choses.',
  'Propice pour organiser son budget et mettre de l''ordre.',
  'Permet d''imposer ses directives et ses m‚thodes, aussi peu',
  'orthodoxes soient-elles. Activit‚ mentale dans l''abstrait.',
  'Am‚lior‚ la vitalit‚ et favorise la conduite de la vie par des',
  'circonstances myst‚rieuses ou des protections occultes.',
  'Incline … perfectionner et … reformer ce qui est. Propice … la',
  'r‚g‚n‚ration de la sant‚. Bon ‚quilibre psychique.',
  'Rend plus intuitif et compr‚hensif, plus lib‚ral et moins jaloux.',
  'Am‚lior‚ les rapports conjugaux. Aide au succŠs.',
  'Aide … prendre conscience de sa valeur et … se perfectionner tout',
  'en apportant appui et protection de personnes en place.',
  'Fixe les d‚sirs et les r‚alisations. En amour conseille de donner',
  'pour recevoir. Harmonie dans les rapports avec autrui',
  'Donne de la pr‚sence et un magn‚tisme attractif. Aide … arriver',
  'gagnant dans tout genre de comp‚titions. Vitalit‚.',
  'Donne une trŠs grande libert‚ morale et un bon ‚quilibre psychique',
  'et vital. L''ambition est tenace et le but ‚lev‚.',
  'La personnalit‚ s''affirme dans la voie suivie. Indice de maŒtrise',
  'sur soi et sur les autres. Les vues sont optimistes',
  'Donne une grande libert‚ d''esprit. Il y a d‚sir de dominer',
  'intellectuellement. L''esprit domine le coeur et l''ƒme.',
  'Am‚lior‚ le physique et le mental. Aide l''artiste … imposer son',
  'genre et le commer‡ant sa marque. Le m‚rite est reconnu.',
  'Pr‚dispos‚ aux passions tout en ‚tant favorable … la sant‚.',
  'AccroŒt la force nerveuse et la vitalit‚. quilibre physique',
  'Pr‚sage des difficult‚s dans la plupart des domaines. Risques de',
  'd‚sordres professionnels, affectifs et financiers',
  'Les devoirs, les obligations et les contraintes s''accentuent les',
  'hommes et le destin limitent les possibilit‚s d''agir.',
  'Diminue le charme naturel et d‚s‚quilibre les relations',
  'affectives. Expose … la v‚nalit‚ et … la jalousie d''autrui.',
  'Incline … la tyrannie, … l''indisciplin‚ et … l''‚go‹sme. La',
  'combativit‚ est celle du tigre. Dangers d''accidents.',
  'Rend vaniteux, satisfait et ‚go‹ste. Dispose au bluff et aux',
  'difficult‚s financiŠres. Indice de malchance et de maladie.',
  'Dispose aux ennuis graves de sant‚. Contraire … la vie en commun.',
  'Marque la solitude morale. Restrictions mat‚rielles.',
  'Cause des pertes de cr‚dit. Risque de ratage professionnel ou',
  'sentimental. Facteur de s‚paration. Troubles nerveux.',
  'Contraire … la sant‚. Indice de troubles psychiques. On se sent',
  'solitaire et mal aim‚. Se m‚fier de l''ill‚galit‚.',
  'Les passions sont intensifi‚es et la voracit‚ des app‚tits accrue.',
  'Donne le besoin de se faire valoir et de bluffer.',
  'Augmente la fermet‚ et le courage physique. Les conditions de vie',
  's''am‚liorent par un m‚rite plus grand. Chance.',
  'Apporte de la fixit‚ dans les id‚es. Permet de maŒtriser le mental',
  'et d''imposer ses directives. Favorable … la sant‚.',
  'lev‚ la nature des sentiments. Grande maŒtrise du moi et de la',
  'vie affective. Marque le mariage, l''union et l''amour.',
  'Augmente la force nerveuse et la vitalit‚. Marque les succŠs',
  'sociaux, la maŒtrise, l''ambition et le m‚rite. Bonne sant‚.',
  'Permet la r‚ussite des projets en augmentant la force vitale',
  'incline … ˆtre le premier, … dominer et … s''‚lever. Sant‚.',
  'Incite … la droiture en toute chose. Propice … l''esprit de suite',
  'et … l''ambition soutenue. Les d‚sirs sont satisfaits.',
  'AccroŒt la g‚n‚rosit‚ et la confiance. Apporte de la chance dans',
  'tout ce qui est sp‚culatif. Favorable … l''avant-garde.',
  'Donne des conceptions ‚lev‚es, du tact et de la diplomatie',
  'r‚compense le m‚rite et consolide les finances. Bonne sant‚.',
  'Aide … faire de gros efforts pour s''enrichir sur tous les plans.',
  'Recherche de l''argent et du pouvoir. R‚g‚n‚ration.',
  'Dissipe la m‚lancolie et l''inqui‚tude. Aide … voir clair en soi',
  'et … ne pas pr‚sumer de ses forces. Rend charmeur.',
  'Favorise la recherche des distinctions et la faveur des grands.',
  'Am‚lior‚ l''‚quilibre nerveux et rend plus patient.',
  'Donne des dispositions plus optimistes. Aide … se faire remarquer.',
  'La pers‚v‚rance est r‚compens‚e. Faveurs.',
  'Permet d''envisager l''avenir avec un optimisme agissant. Am‚lior‚',
  'le moral des malades et est propice … la sant‚.',
  'Am‚lior‚ l''‚tat physique et fortifie le mental. L''humeur est',
  '‚gale et l''activit‚ r‚guliŠre. Augmente la confiance en soi.',
  'Aide … faire un labeur remarqu‚. Peut marquer le point de d‚part',
  'd''une ascension r‚guliŠre ou d''un choix social.',
  'Donne le souci de ses droits et pr‚rogatives. Apporte des',
  'satisfactions d''amour-propre impr‚vues. Permet de s''imposer.',
  'La conduite de la vie est favoris‚e. S''attendre … des appuis',
  'myst‚rieux. Favorable aux coups de pouce financiers.',
  'Dispose … ne faire aucune concession et … refuser tout genre de',
  'compromissions. Incline … perfectionner et … reformer.',
  'Marque l''aboutissement des projets et des entreprises.',
  'L''ambition est impatiente. Cause l''anxi‚t‚ et la nervosit‚.',
  'Dispose … l''envie, … la rancune et … la vengeance. Contraire …',
  'l''activit‚ mentale. Pr‚sage l''id‚e fixe et l''entˆtement.',
  'Dispose … l''‚go‹sme et … la vanit‚. Facteur de jalousies.',
  'Pr‚disposition au narcissisme et … parler de soi.',
  'Exalte les qualit‚s et les d‚fauts virils. Accentue la combativit‚',
  'et l''instinct. Risques d''accidents. Crises.',
  'Nuit … la sant‚. Incline … l''arrivisme et … jouer des coudes rend',
  'd‚pensier et d‚sordonn‚. Expose au blƒme, … la d‚faite.',
  'D‚favorable … la sant‚. Cause de maladie. Dispose aux revirements',
  'du destin. Rend ‚go‹ste et inflexible. Maladie.',
  'Cause de d‚s‚quilibre physique. Rend insouciant et expose aux',
  'catastrophes. Contraire … l''ascension et … la qui‚tude.',
  'La sant‚ n''est pas brillante et les malaises fr‚quents. Contraire',
  'aux honneurs et aux distinctions. Cause de maladie',
  'Incline aux id‚es arrˆt‚es, au faire-valoir et … la mauvaise foi.',
  'Expose … la violence et aux actes spectaculaires.',
  'L''imagination cr‚atrice est en croissance. Am‚lioration des',
  'rapports conjugaux ou familiaux. R‚‚quilibre les finances.',
  'AccroŒt l''amour de la vie et l''esprit d''entreprise. Les ‚checs',
  'sont peu probables et les d‚placements lucratifs.',
  'Am‚lior‚ l''‚quilibre physique. Propice … la paix, … la',
  'r‚conciliation, … l''amour et … la sympathie. Aide la chance.',
  'AccroŒt la puissance des qualit‚s instinctives. D‚pens‚ d''‚nergie',
  'inutile. Aide … la mise en route des actions.',
  'Aide … r‚tablir l''‚quilibre fonctionnel. Excellent pour se mettre',
  'au vert. Les id‚es sont payantes. Indice de chance.',
  'AccroŒt les difficult‚s. Les moyens de se d‚fendre sont en baisse.',
  'S''attendre … des d‚ceptions. Indice de solitude.',
  'Cause des incompatibilit‚s d''humeur. Expose au blƒme et …',
  'l''excentricit‚. Les rˆves sont souvent pr‚monitoires.',
  'Dispose … la susceptibilit‚ et … la passivit‚. Marque la crainte',
  'de la maladie. Rend nerveux, sensible et sensitif.',
  'Pr‚dispos‚ aux passions ‚go‹stes, mat‚rialistes, sensuelles. On',
  'sent plus qu''on ne pense. Penchant au d‚vouement.',
  'Am‚lioration des affaires priv‚es. Apporte l''appui de',
  'l''entourage f‚minin. P‚riode de calme profitable … la sant‚.',
  'Diminue la nervosit‚ et permet une p‚riode de repos. On conserve',
  'l''espoir de jours meilleurs : ils viendront.',
  'Facteur de r‚sistance passive et non-violente. Permet de faire',
  'contre mauvaise fortune bon coeur. Indice de flirt.',
  'Regain de vitalit‚. Peut marquer la chance dans le travail. Rend',
  'les femmes moins secrŠtes, plus franches et chaudes.',
  'Aide la venue de faveurs et de sympathies nouvelles. Peut',
  'correspondre … un accroissement mat‚riel. Favorise la chance',
  'Rend le travail moins p‚nible ou plus lucratif. Am‚lior‚ la vie',
  'intime et les dispositions de l''esprit. H‚sitations.',
  'Les intuitions sont heureuses. AccroŒt la sympathie et rend plus',
  'diplomate. Favorable aux distinctions et aux faveurs.',
  'Aide … la venue du confort et des petits gains occultes. AccroŒt',
  'l''intensit‚ des qualit‚s passives et intuitives.',
  'Accentue les dons de m‚dium et de gu‚risseur. Favorable …',
  'l''instinct. Peut marquer le besoin de servir.',
  'Apporte d‚vouement et affection. L''activit‚ est croissante et',
  'aide … l''ascension. Rend l''esprit plus ind‚pendant.',
  'Les d‚cisions et les initiatives sont heureuses et sont aid‚es par',
  'la chance. Se montre propice aux ‚crits.',
  'Favorable … la vie, … la sant‚ et au moral. AccroŒt l''optimisme',
  'et am‚lior‚ les conditions de vie. Facteur de chance.',
  'Les rapports amoureux conservent un caractŠre fougueux mais',
  'reposent sur la sinc‚rit‚ et l''amiti‚. Chance au travail.',
  'Permet la diplomatie habile et la r‚solution des litiges. Mod‚r‚',
  'les d‚penses de vitalit‚ et am‚lior‚ l''‚tat physique.',
  'Contribue … l''harmonie domestique. Rend moins solitaire. La',
  'chance grandit et le destin est moins cruel.',
  'Marque l''‚volution intellectuelle. L''imagination est cr‚atrice',
  'et les conceptions originales. Petites chances.',
  'Rend sociable et dispose … faire des concessions. AccroŒt le',
  'besoin affectif. Le destin est favorable. Indice de chance.',
  'Pr‚dispos‚ … se donner totalement … ce qu''on fait et … ceux que',
  'l''on aime. Les actes sont dict‚s par l''amour du prochain',
  'Ne facilite pas la mise en vedette ou la popularit‚. Rend',
  'l''esprit inquiet et soup‡onneux. Augmente les risques.',
  'Diminue la volont‚ et le sens moral. Rend tributaire de',
  'l''entourage. Les chances d''aboutir ne sont que des leurres.',
  'Dispose … la sensiblerie et rend susceptible et craintif.',
  'Contrarie la vie mat‚rielle et pousse au d‚sordre moral.',
  'Diminue le tact et la douceur. Augmente l''‚go‹sme. Incline … la',
  'grossiŠret‚ : la franchise est brutale. Contrari‚t‚s.',
  'La qui‚tude au foyer est troubl‚e. Incline … ˆtre dup‚. Expose aux',
  'malaises. La situation est instable. D‚penses.',
  'La raison est fauss‚e : l''esprit ‚chafaude des hypothŠses. Fait',
  'souffrir moralement en silence. Indice de solitude.',
  'Contraire aux promesses et aux projets. L''esprit est rebelle aux',
  'contraintes. Fait difficilement trouver la bonne voie.',
  'Rend facilement influen‡able et craintif. Cr‚e des id‚es fixes et',
  'des d‚sillusions sentimentales et financiŠres.',
  'Pr‚dispos‚ aux passions et … l''‚go‹sme. La vie est invivable et',
  'on manque de tact et de mesure. Cause l''impopularit‚.',
  'Rend l''esprit plus ind‚pendant et l''imagination plus fantasque.',
  'AccroŒt l''amour de la vie. Am‚lior‚ la vie familiale.',
  'Donne un meilleur ‚quilibre nerveux. Rend l''imagination plus',
  'pratique et l''esprit plus apte … r‚aliser. Indice de chance.',
  'Facteur d''‚quilibre et d''harmonie. Les choses s''arrangent.',
  'Augmente le d‚sir de paix. Favorable … la cr‚ativit‚.',
  'Dispose … tous les d‚vouement pour d‚fendre une cause juste',
  'l''effort est soutenu par la chance. Favorable au risque.',
  'Indice de bonne sant‚. Permet de s''adapter. La chance fait',
  'rarement d‚faut. Facteur d''accroissement et de chance.',
  'Favorable … la vie et … la sant‚. On ne voit pas le mauvais cote',
  'des choses. Favorable … la raison et … la recherche.',
  'Dispose heureusement la recherche, les ‚tudes et la cr‚ation le',
  'savoir-faire, l''imagination et la chance croissent.',
  'Rend plus sensitif, plus imaginatif et rˆveur. Aide les',
  'inspirations heureuses. Incline au mysticisme. Aide la chance',
  'Marque la confiance, l''enthousiasme et la combativit‚. Les actes',
  'sont dict‚s par l''amour d‚sint‚ress‚. Confiance.',
  'Am‚lior‚ les affaires priv‚es et donne plus de compr‚hension dans',
  'la vie conjugale. Apporte l''appui des femmes. Calme.',
  'Incline … la r‚signation devant l''in‚luctable. Les femmes sont',
  'plus calmes et moins capricieuses. Favorable … l''‚tude.',
  'Facteur de foi et de pers‚v‚rance dans le domaine affectif. Marque',
  'la passivit‚ et la non-violence. Aide les amours.',
  'Dispose … la chance dans le travail. Permet de s''imposer aux',
  'autres par son dynamisme. Accorde la rapidit‚ des r‚flexes.',
  'Favorable aux faveurs et aux sympathies. Peut marquer la',
  'croissance des biens mat‚riels et avantages professionnels.',
  'Am‚lior‚ la vie intime et les dispositions de l''esprit. Favorise',
  'les oeuvres de patience, la rigueur et la pr‚cision',
  'Aide … la chance, aux distinctions et aux faveurs. Permet',
  'l''explosion des id‚es et initiatives originales. Chance.',
  'Propice aux gains faciles, au travail lucratif et au repos. Permet',
  'de tirer des avantages d''une p‚riode d''inactivit‚.',
  'Accorde une grande facult‚ de persuasion et permet de nouer avec',
  'les autres des rapports profonds. Indice passionnel.',
  'Pr‚dispos‚ … voir les choses sous un angle r‚tr‚ci. Diminue le',
  'courage physique et moral. Rend instable et nerveux.',
  'Expose … l''ingratitude et aux d‚sillusions. Contraire … la sant‚',
  'et … la vitalit‚. Incline … une passivit‚ utile.',
  'L''imagination est orient‚e vers les choses de l''amour. Cause des',
  'dissentiments et des jalousies. Rend susceptible.',
  'Incline vers le caprice, l''entˆtement et la solitude. N''avantage',
  'pas l''entente avec le conjoint. Risque d''accident',
  'Pr‚sage une attitude mat‚rialiste et ‚go‹ste. On pense … soi les',
  'contraintes sociales freinent les initiatives. Malchance',
  'N''est pas porteur de joie ni de gaiet‚. Pr‚sage l''inqui‚tude et',
  'la m‚lancolie. Incline aux restrictions et … la crainte.',
  'N''est pas facteur de stabilit‚. Peut marquer des revirements',
  'inattendus et fƒcheux. Appelle souvent des petits incidents.',
  'Diminue les qualit‚s activ‚s et pousse … user d''exp‚dients. La',
  'r‚sistance physique est affaiblie. Sensitivit‚ excessive.',
  'Pr‚dispos‚ … l''inconscience et aux entˆtements n‚fastes.',
  'L''imagination cr‚atrice est favoris‚e. La sant‚ est menac‚e.',
  'Favorise l''activit‚ intellectuelle et aide … briller dans le',
  'monde. Les id‚es sont nombreuses. Maintient la forme.',
  'Am‚lior‚ la vie mat‚rielle. On voit clair en soi et en les autres.',
  'Aide … rendre les id‚es abstraites. Favorise l''‚crit.',
  'Am‚lior‚ le mental et apporte du bon sens. Augmente le talent',
  'inventif et rend ing‚nieux. SuccŠs en amour. Chance.',
  'Apporte plus de souplesse et d''adresse dans la vie. Am‚lior‚ la',
  'vie professionnelle et rend les n‚gociations plus rapides',
  'Augmente le sens pratique et incite … sortir des sentiers battus.',
  'Contribue aux rentr‚es d''argent. Marque le mariage.',
  'Apporte de la promptitude dans les id‚es. Rend plus souple et plus',
  'entreprenant. Favorise les contacts s‚rieux.',
  'Apporte des conceptions originales et personnelles. Donne le go–t',
  'du risque. Incline … passer de l''id‚e … l''acte. Chance.',
  'Excite les qualit‚s psychiques et intellectuelles. Permet les',
  'intuitions heureuses; facteur de chance financiŠre.',
  'Donne du go–t pour les travaux qui pr‚sentent un int‚rˆt imm‚diat',
  'et pratique. Rend ing‚nieux et impatient. Sant‚.',
  'Rend les r‚alisations plus rapides et financiŠrement productives.',
  'Promet des succŠs d''estime et d''argent.',
  'Influence heureuse sur ceux qui ont des id‚es … vendre. Donne une',
  'solution rapide aux problŠmes. Petits gains.',
  'Apporte l''appui des confrŠres et des collŠgues. Marque l''amour',
  'platonique ou l''amiti‚. Satisfactions artistiques.',
  'Rend d‚brouillard. Aide le travail qui demande de la dext‚rit‚.',
  'Favorise les entr‚es d''argent. Indice de sant‚.',
  'Rend la profession moins monotone et la vie familiale plus',
  'vivante. Est un facteur de chance et de sant‚.',
  'Permet les conceptions pratiques et les mises au point rapides.',
  'Aide … voir clair en soi. Active la raison.',
  'Permet de sortir des sentiers battus et d''innover. Laisse',
  'pr‚sager des plaisirs nouveaux et des joies intellectuelles.',
  'Rend les projets pratiques et satisfait les d‚sirs. Pr‚sage',
  'l''avancement professionnel. Rend le travail moins p‚nible.',
  'Les choses ne traŒnent pas et tout se fait rapidement. On sait ce',
  'qu''il faut dire et faire.',
  'Dispose … une plus grande souplesse morale et … l''activit‚',
  'physique. Donne du savoir-faire et de la compr‚hension.',
  'Augmente le sens de l''opportunit‚ et aide … ne pas laisser perdre',
  'les bonnes occasions. Apporte de l''activit‚.',
  'Intellectualisme les amours en fortifiant la camaraderie. Favorise',
  'les d‚marches et les transactions. Satisfactions.',
  'Aide … trouver le mot juste et … se donner entiŠrement en temps',
  'opportun. Les efforts sont payants. Indice de sant‚.',
  'Favorise l''accroissement des biens immobiliers. Avantage les',
  '‚crits et la signature des contrats. Insuffle une vie neuve.',
  'L''activit‚ c‚r‚brale grandit et dispose … s''occuper de plusieurs',
  'choses … la fois. Aide les travaux scientifiques.',
  'Favorise l''intelligence et la cr‚ativit‚. Rend plus r‚alisateur',
  'et plus d‚brouillard. Aide … r‚soudre les contraintes.',
  'Aide … vivre avec facilit‚. Apporte des collaborations profitables',
  '… l''accroissement des biens. Intuition heureuse.',
  'Aide … la persuasion habile et intelligente. Bon facteur de',
  'r‚flexion : permet de d‚couvrir les rouages des problŠmes',
  'Cause du d‚sordre dans les id‚es et un manque de pers‚v‚rance dans',
  'les r‚alisations. Marque les dissentiments.',
  'Mauvaise p‚riode financiŠre. La chance est contraire. Le',
  'savoir-faire n''est pas ‚paule par le savoir. Nervosit‚.',
  'Incline … br–ler la chandelle par les deux bouts et … manger son',
  'bl‚ en herbe. Rend les femmes envieuses et m‚disantes.',
  'Donne une plus grande activit‚ mentale et incline … la ruse. Rend',
  'susceptible, hƒbleur et vaniteux. Expose au surmenage.',
  'Incline … manquer de s‚rieux en affaires et … promettre beaucoup',
  'plus qu''on ne peut tenir. Impr‚voyance et malchance',
  'Rend irritable et tyrannique. Expose … la raillerie tout en',
  'disposant … la m‚chancet‚. Contraire … l''intellect.',
  'L''activit‚ mentale est d‚sordonn‚e, il est difficile de suivre',
  'longtemps la mˆme id‚e. D‚conseille les voyages.',
  'Incite … ne pas se montrer scrupuleux en affaires. Expose au',
  'chantage dans la vie priv‚e. Marque les maux de tˆte.',
  'Activit‚ mentale excessive, f‚brile et d‚sordonn‚e. L''humeur est',
  'instable. Esprit de contradiction. Indice de nervosit‚.',
  'Influence heureusement le mental et l''intellect. Rend apte …',
  'supporter la critique. AccroŒt la r‚sistance nerveuse.',
  'Les difficult‚s s''estompent et on se montre intelligent et',
  'd‚brouillard. Apporte de l''activit‚ dans la vie.',
  'Augmente le talent inventif et le savoir-faire. Permet de tirer',
  'profit de la sympathie que l''on d‚gage. Marque l''union.',
  'L''activit‚ augmente dans tous les domaines et s''adapte aux',
  'circonstances. Favorise ce qui demande de l''habilet‚.',
  'Facilite les affaires et les transactions financiŠres. TrŠs',
  'favorable … la sant‚. Diminue la routine. Chance.',
  'AccroŒt le nombre des relations professionnelles. TrŠs favorable',
  'aux travaux de l''esprit et recherches pratiques.',
  'Donne une grande activit‚ c‚r‚brale, de la r‚sistance nerveuse et',
  'un bon ‚quilibre psychique. L''esprit est curieux.',
  'Pr‚sage un bon ‚quilibre nerveux et g‚n‚ralement une bonne sant‚',
  'psychique. D‚velopp‚ les affaires. Chance sp‚culative.',
  'Favorable … la persuasion habile et … la r‚solution des affaires',
  'et combinaisons myst‚rieuses. Propice … l''invention',
  'Rend les r‚alisations plus rapides et financiŠrement plus',
  'productives. SuccŠs d''estime et d''argent. Propice aux ‚tudes',
  'Incite aux d‚placements et aux changements. Apporte de petits',
  'gains et active le roulement des capitaux.',
  'Apporte des satisfactions artistiques et des joies',
  'd''amour-propre. On se sent rajeunir. Appuis de confrŠres ou',
  'collŠgues.',
  'Propice au travail qui demande de la dext‚rit‚ et aux d‚marches',
  'qui demandent autant de fermet‚ que de diplomatie.',
  'Pr‚sage moins de monotonie dans la profession et plus de vie dans',
  'la famille. Donne souplesse au corps et … l''esprit.',
  'Am‚lior‚ les rapports entre vieux et jeunes. Aide … mieux',
  'comprendre les autres. Dispose … la rigueur.',
  'Apporte de l''impr‚vu dans la vie, une plus grande libert‚',
  'd''esprit et des vues plus optimistes. Besoin de parler.',
  'Rend plus enjou‚, plus conciliant et plus vivable. Facilite',
  'l''assimilation et la m‚moire. Peut d‚couvrir des intrigues.',
  'Permet dans les transactions d''obtenir le maximum et de respecter',
  'int‚gralement les bases de n‚gociation.',
  'Rend plus sensible … la critique et accroŒt la vanit‚ et',
  'l''impatience. Les rapports sociaux manquent de franchise.',
  'Incline … vouloir jouer au plus fin, en affaires comme en amour.',
  'Rend bavard et peut causer des troubles nerveux.',
  'Incline … l''impatience, au caprice et … la nervosit‚. Pr‚dispos‚',
  '… l''int‚ressement et … vouloir s''enrichir.',
  'Difficile de rester inactif : on agit et on s''agite sans raisons.',
  'L''esprit est impatient et manque de suite.',
  'Les dispositions de l''esprit sont contraires … la qui‚tude et …',
  'la stabilit‚. Cause de surexcitation. Malchance.',
  'Incline … la m‚fiance, … l''inqui‚tude, … la jalousie et … la',
  'tristesse. Rend irritable. Besoin d''analyser. Maux de tˆte.',
  'Pr‚sage une suractivit‚ nerveuse qui empˆche de masquer ses',
  '‚motions. Manque de maŒtrise sur les nerfs. Suremotivite.',
  'D‚favorable … l''‚quilibre nerveux. L''esprit est inquiet.',
  'Contraire … l''enrichissement. Mauvais indice de sant‚.',
  'Rend impatient, agressif, batailleur et contradicteur. On sait',
  'plaider le faux pour savoir le vrai. Humeur instable.',
  'Incline … la joie de vivre et … profiter des plaisirs.',
  'Satisfactions d''amour propre et succŠs artistiques. Flirt.',
  'L''imagination est orient‚e vers ce qui est bon. Permet de de',
  'profiter d''un passage de chance affective.',
  'Pr‚dispos‚ aux ‚lans altruistes avec plus de sinc‚rit‚ et de',
  'd‚sint‚ressement dans les amours. Aide … la r‚ussite.',
  'Apporte du savoir-faire dans l''amour. Marque les rencontr‚s',
  'amoureuses et intensifie les besoins sexuels. Infid‚lit‚.',
  'Aide … prendre la vie du bon c“t‚. TrŠs b‚n‚fique, favorise tout',
  'ce qui touche … l''amour, au mariage et … la procr‚ation',
  'Apporte un jugement sobre et de la sagesse dans les actes de la',
  'vie. Am‚lior‚ les conditions de travail et la vie priv‚e.',
  'Fait sortir du commun et permet d''ˆtre remarqu‚. On tient …',
  'plaire et … vivre une certaine libert‚ sexuelle. Rencontre.',
  'Am‚lior‚ le physique et le mental en raffinant les sentiments et',
  'les plaisirs de l''amour. Pr‚sage qui‚tude et joies.',
  'L''amour devient le principal mobile de l''existence : il absorbe',
  'toutes les pens‚es et les condense en un seul d‚sir.',
  'Incline … ˆtre content de soi et des autres. Satisfactions',
  'd''amour-propre. Favorable au flirt et … la flatterie.',
  'Apporte de la qui‚tude dans la vie sentimentale et dans le foyer.',
  'Favorable … la politique et … l''art. Satisfactions.',
  'Maintient l''amiti‚ et fait rechercher l''amour. Rend tributaire',
  'de l''amour sans d‚sagr‚ments. Bonne humeur.',
  'Permet d''aller de l''avant avec des chances de succŠs. Peut faire',
  'rencontrer des amiti‚s solides et un amour vrai.',
  'Pr‚sage la qui‚tude et la s‚curit‚. Facteur de satisfaction.',
  'Permet les satisfactions professionnelles. Petites chances.',
  'Am‚lior‚ le jugement en ce qui concerne les finances. Rend plus',
  'charmeur, plus habile ou naturellement plus sympathique',
  'Diminue le nombre ou l''intensit‚ des inimiti‚s. Aide … se faire',
  'mieux comprendre et ‚couter. Permet les sympathies.',
  'Intensifie les sentiments altruistes. Donne le besoin d''aimer et',
  'd''ˆtre aim‚. Satisfactions d''ordre priv‚.',
  'Incline … rechercher le sexe oppose : les d‚sirs sont changeants',
  'et les passions nouvelles ardentes. Flirt pousse.',
  'Incline … rechercher le sexe oppose. Les relations sont plaisantes',
  'et agr‚ables. On sait se rendre sympathique.',
  'Am‚lior‚ le moral et la forme physique. Met les femmes en beaut‚',
  'et rend les hommes plus d‚vou‚s et moins ‚go‹stes.',
  'Am‚lior‚ le go–t du beau et accroŒt la sentimentalit‚. Peut faire',
  'rencontrer l''amour. Aide … trouver des appuis.',
  'Am‚lior‚ les qualit‚s altruistes et l''ascendant sur le sexe',
  'oppos‚. On est aim‚ et respect‚. Joies sentimentales.',
  'Tend … am‚liorer la vie dans le sens des d‚sirs. Am‚lior‚ la vie',
  'professionnelle, familiale et sentimentale. Chance.',
  'Donne du s‚rieux, l''humeur ‚gale, le sens de l''humour et du',
  'tact. Aide les femmes … rencontr‚ un homme s‚rieux.',
  'Facilite l''entente avec l''entourage et donne un ascendant',
  'sympathique sur ceux que l''on fr‚quente. Harmonique.',
  'Rend les conjoints plus compr‚hensifs. Aide … rencontrer l''amour,',
  'la sympathie et les appuis. On pense aux autres.',
  'On sait par son d‚sir faire naŒtre le d‚sir. La confiance en soi',
  'est bonne et on joint l''utile … l''agr‚able. Flirt.',
  'D‚favorable aux rapports affectifs. Peut ˆtre l''indice de la',
  'rencontr‚ fatale. Incline … l''adultŠre et aux flirts.',
  'Marque le chagrin d''amour, les inimiti‚s et la jalousie. Cause',
  'des embarras financiers, disgrƒces et scandales.',
  'Pr‚sage le manque de ressort et de cran, le laisser-aller et la',
  'r‚signation. Expose ou dispose aux abus de confiance.',
  'AccroŒt l''intensit‚ des d‚sirs sexuels. L''esprit se complaŒt',
  'dans les pens‚es lubriques. Pr‚sage l''instabilit‚ sexuelle.',
  'Dispose … l''insouciance : on prend la vie comme elle est. Incline',
  '… l''‚go‹sme sans m‚chancet‚ et au farniente.',
  'Le mental n''est pas orient‚ vers ce qui est beau et gai. Incline',
  'au pessimisme et au scepticisme. Ratage affectif.',
  'Donne de l''originalit‚ aux artistes. Incline … la jalousie et …',
  'l''envie. Les besoins sexuels ne sont pas naturels.',
  'Contraire aux amours et … la vie conjugale. Marque les amours',
  'secrŠtes et anormales, les tromperies et coucheriez.',
  'Rend esclave des passions qui prennent le pas sur la raison.',
  'Incline au mauvais go–t. Le mental manque de hauteur.',
  'Apporte une grande ‚galit‚ d''humeur et harmonise la vie dans le',
  'sens de ses d‚sirs. Aide … rencontrer des sympathies.',
  'AccroŒt le d‚sir de plaire et d''ˆtre aim‚. Aide … devenir',
  'indispensable. Permet de rencontrer le succŠs et les faveurs',
  'Le d‚sir et les possibilit‚s de plaire grandissent. AccroŒt',
  'l''amour et le culte de la beaut‚. Favorise les finances.',
  'Harmonise les passions et ‚lev‚ le d‚sir. Fait rencontrer',
  'l''amour. Accorde les faveurs de la renomm‚e et la fortune.',
  'Resserre les liens du mariage. Il y a communion de go–ts et un',
  'd‚vouement r‚ciproque. Peut marquer le mariage. Chance.',
  'Favorise l''art intellectualisme et fait pr‚f‚rer l''harmonie … la',
  'm‚lodie. Est un facteur de respectabilit‚.',
  'AccroŒt le m‚rite personnel, l''originalit‚ et le talent. Favorise',
  'tout ce qui a trait au plaisir et aux joies.',
  'Favorise les artistes dans leur cr‚ations et les rend plus',
  'compr‚hensifs pour le public. Grandit la renomm‚e. Chance.',
  'Fait aimer avec fantaisie et sensualit‚. La jouissance est',
  '‚clectique. Les conceptions demandent … se mat‚rialiser.',
  'Permet de r‚aliser ses satisfactions d''amour-propre et … les',
  'vivre pleinement. Peut laisser pr‚sager des fian‡ailles.',
  'Favorable … la vie artistique et … la politique. Permet de se',
  'lib‚rer des contraintes sentimentales avec adresse.',
  'Fait rechercher l''amour et porte … faire plaisir pour le plaisir.',
  'Pr‚dispos‚ … la bonne humeur. Esprit conciliant.',
  'Permet d''aller de l''avant avec de r‚elles chances de succŠs.',
  'Freine les excŠs et fait r‚cup‚rer les forces perdues.',
  'Peut accorder des appuis professionnels. Aide … r‚aliser des gains',
  'sans efforts. Marque les satisfactions.',
  'R‚chauffe le coeur et r‚veill‚ les sens. Peut marquer un',
  '‚loignement ou une s‚paration voulue. Am‚lior‚ le jugement.',
  'Les possibilit‚s d''oeuvrer harmonieusement sont en croissance.',
  'Permet de rallier des sympathies.',
  'Peut marquer un amour qui ‚veill‚ ou r‚veill‚ la sensualit‚. Donne',
  'le go–t du romanesque. Tendance aux rˆves.',
  'AccroŒt le magn‚tisme et le charme. Fait aimer la vie avec',
  'fanatisme et sensualit‚.',
  'Affaiblit le dynamisme et les qualit‚s morales. Incline … voir les',
  'choses superficiellement. Manque d''amour.',
  'Cause des blessures d''amour, l''inqui‚tude, la peine et la',
  'jalousie. Donne des complexes d''inf‚riorit‚ en amour.',
  'Incline dans tous les domaines vers l''abandon et la facilit‚',
  'cause des troubles sexuels et nerveux. Mauvais go–t.',
  'Marque l''opposition des sexes et indique des luttes et des',
  'querelles passionnelles. Expose … la trahison. Perte vitale.',
  'EntraŒn‚ des ennuis suite … une mauvaise conduite. Contraire …',
  'l''‚quilibre physique. Pr‚sage un manque … gagner.',
  'Difficult‚ … se rendre sympathique. D‚favorable au mariage. Rend',
  'le caractŠre triste et maladif : on est priv‚ d''amour.',
  'Ne dispose pas … se conduire comme tout le monde, ni … passer',
  'inaper‡u. Permet la fantaisie. Complications sexuelles.',
  'La volont‚ fait d‚faut. Les initiatives sont rares et celles qui',
  'sont prises sont malheureuses. Cause l''abattement.',
  'Rend nerveux et instable. Manque de virilit‚. Cause la d‚bauche,',
  'le caprice, l''inconstance et la v‚nalit‚.',
  'Cause des heurts avec le pouvoir ou les sup‚rieurs. Incite … se',
  'd‚penser et … faire preuve de combativit‚. Blessures.',
  'N''occasionne parfois qu''une tempˆte dans un verre d''eau, mais',
  'd‚chaŒne parfois des ‚v‚nements d''une violence inou‹e.',
  'Apporte du cran dans les activit‚s, des heurts, des discussions et',
  'l''impatience dans les r‚alisations. TrŠs cr‚atif.',
  'Aide au succŠs social et professionnel. Apporte des rapports',
  'violents avec le sexe oppos‚. Amour exclusif et ‚go‹ste.',
  'Conseille de mettre un frein … sa t‚m‚rit‚. Tendance … s''attaquer',
  '… plus fort que soit. Porte … changer ce qui est.',
  'Incline … des actes violents qui ont ‚t‚ longtemps contenus par la',
  'crainte ou la raison. Le mouton enrag‚ et se r‚volte.',
  'L''esprit subit l''attrait pour la nouveaut‚. Enthousiasme.',
  'L''instabilit‚ peut r‚gner en maŒtre. bauche de mille projets',
  'Regain d''activit‚. Apporte une plus grande r‚sistance physique et',
  'morale. Le sens pratique se r‚veill‚. Blessures.',
  'Cause l''exacerbation des passions et instincts, de la volont‚ du',
  'courage physique et moral. Incline au respect de soi.',
  'Permet de faire de plus gros efforts physiques et de s''imposer :',
  'par la force si n‚cessaire.',
  'Aide … vaincre les appr‚hensions et la timidit‚. Dispose … faire',
  'preuve d''une plus grande ‚nergie et fermet‚.',
  'Fortifie le physique et le moral. Incline … la taquinerie et …',
  'l''ironie. Besoin d''agir et de r‚aliser. Entreprises.',
  'Harmonise les sentiments en conservant l''amour et les sentiments.',
  'Am‚lior‚ les conditions de vie et de travail.',
  'Dispose … voir les choses sainement, sans complications. La bonne',
  'voie est suivie instinctivement. Conseils g‚n‚reux.',
  'Rend un peu plus entreprenant. Augmente le d‚sir de vivre. On',
  's''active utilement. Donne plus de chaleur aux sentiments.',
  'Aide … se lib‚rer des contraintes et … s''imposer en sortant de la',
  'passivit‚ et en brusquant les choses. Vitalit‚.',
  'Incline … la g‚n‚rosit‚ et … l''enthousiasme. On se donne',
  'entiŠrement … ses amours, … son travail et … ses id‚es.',
  'Fait naŒtre de nouveaux besoins et de nouvelles luttes. Il y a',
  'autant de force morale que de r‚sistance physique.',
  'Am‚lior‚ la vitalit‚ et rend plus r‚sistant … la maladie. On sait',
  'se battre et on triomphe souvent. Permet de s''imposer',
  'Marque une ‚volution heureuse dans les affaires et celles-ci',
  'prennent de l''ampleur. P‚riode d''activit‚ et de productivit‚',
  'Possibilit‚ d''efforts physiques plus soutenus et plus de fermet‚',
  'dans les d‚cisions. Le d‚sir d''arriver est intense.',
  'Donne plus de force et de v‚rit‚ aux sentiments. Pr‚sage une',
  'libert‚ morale plus grande. Incline … rendre service.',
  'Permet d''atteindre le but qu''on s''est fixe par un effort',
  'continu dans le mˆme sens. Confiance en soi et activit‚.',
  'L''‚nergie domine et il est difficile de se plier aux ordres ou de',
  'supporter les contraintes. Aide la raison … s''imposer.',
  'Donne une grande r‚sistance morale, de la t‚nacit‚ et du cran.',
  'L''ambition grandit. Permet de battre un record.',
  'Contribue … profiter des joies terrestres et les sensations',
  'qu''elles procurent sont intenses. On oeuvre avec optimisme.',
  'Incline … agir avec audace, fougue, franchise, violence et',
  'voracit‚. Les actions sont instinctives et passionnelles.',
  'L''instinct prend le pas sur la raison et les d‚penses d''‚nergie',
  'sont importantes. Rend indisciplin‚. Accidents.',
  'N''inclin‚ pas … se soumettre aux directives des autres. Donne le',
  'besoin d''action. D‚faut de patience. Blessures.',
  'Pr‚dispos‚ … la franchise brutale et souvent … la grossiŠret‚',
  'quand l''amour-propre est bless‚. Maux de tˆte.',
  'Incline … ˆtre domine par les sens. Facteur de n‚gligence.',
  'Contraire … la qui‚tude sentimentale. Caprices violents.',
  'La vie est instable et on manque d''ordre et d''organisation.',
  'Indice de maladresse ou la force prime le droit. Imprudence.',
  'Risque de perdre le contr“le de ses actes quand on est domine par',
  'le d‚sir. Risque de maladresse et de brutalit‚.',
  'L''excitation mentale est excessive et les efforts pour r‚aliser',
  'sont violents. Expose … l''hostilit‚. Accidents.',
  'Contraire au bien-ˆtre. Pr‚dispos‚ … la tyrannie, … la jalousie et',
  'l''infid‚lit‚. Indice d''‚preuves et de blessures.',
  'Conduit … ˆtre excessif et vindicatif. Pr‚dispos‚ … la violence et',
  '… la force brutale. Accidents et blessures.',
  'Facteur de r‚sistance physique, de courage et d''audace. Donne la',
  'franchise, la spontan‚it‚ et la confiance en soi.',
  'Facteur de vitalit‚, de sant‚ et de force. Augmente l''activit‚',
  'dans tous les domaines. Contribue … l''ascension.',
  'TrŠs bon indice de sant‚ et de r‚cup‚ration. Donne l''amour de',
  'l''argent et le besoin de le d‚penser. Confiance en soi.',
  'Dispose … l''enthousiasme et … l''optimisme. Les rapports avec le',
  'sexe oppos‚ sont francs. Favorable … l''art.',
  'Apporte de l''activit‚ et de la force. On est capable de gros',
  'efforts. On voit les choses en grand. Marque l''ascension.',
  'L''ambition devient violente et le d‚sir d''arriver plus',
  'impatient. L''activit‚ est r‚fl‚chie. La vie est un combat.',
  'Pr‚sage la mise en oeuvre de moyens multiples pour sortir du',
  'commun. La volont‚ est r‚fl‚chie. AccroŒt l''autorit‚.',
  'Incline … se montrer moins ‚go‹ste et plus indulgent. Facteur de',
  'chance mat‚rielle et de gains sp‚culatifs.',
  'Permet de bluffer en ayant les moyens de tenir le coup. Pr‚dispos‚',
  '… satisfaire les ambitions et les passions.',
  'Permet de faire de gros efforts physiques et de s''imposer par la',
  'force si n‚cessaire. AccroŒt la t‚m‚rit‚.',
  'Permet si on le veut vraiment, de reprendre les rˆnes, de vaincre',
  'les oppositions et de rompre ses chaŒnes.',
  'Le besoin d''agir et de r‚aliser grandit. On passe de la th‚orie …',
  'la pratique. Permet d''imposer ses vues.',
  'Peut marquer des coups de foudre ou des ruptures. Les sentiments',
  'et l''expression artistique sont dynamises.',
  'Les entreprises t‚m‚raires se r‚vŠlent payantes. Pr‚sage un regain',
  'd''‚nergie et de combativit‚.',
  'Augmente le d‚sir de vivre et de s''activer utilement. Donne plus',
  'de chaleur aux sentiments. Indice d''inflexibilit‚',
  'Aide … se lib‚rer des contraintes en r‚alisant ses id‚es et en',
  'prenant parti, dans le but de changer de camp ou de voie.',
  'Incline … la g‚n‚rosit‚ et … l''enthousiasme. Permet de se donner',
  'entiŠrement … ses amours, au travail et … ses id‚es.',
  'Autant de force morale que de r‚sistance physique. Permet de',
  'satisfaire les ambitions et de se lib‚rer des contraintes',
  'Il y a de la vitalit‚ … revendre. On use et abuse de ses forces.',
  'Attention, les risques d''accident sont s‚rieux.',
  'Incline … exag‚rer. Le sens de la mesure disparaŒt. L''imagination',
  'est excessive et mal orient‚e. Danger.',
  'Incline aux r‚flexes ‚go‹stes. Les app‚tits sont violents et les',
  'moyens utilises pour les satisfaire sont dangereux.',
  'Les besoins sexuels sont tyranniques et passent avant tout.',
  'AccroŒt la violence des d‚sirs et fait faire des excŠs.',
  'Excessivite en tout. Expose aux blessures et aux accidents.',
  'Incline … abuser des autres et de soi-mˆme. D‚sordre.',
  'Pr‚sage la r‚sistance aux inimiti‚s puissantes et violentes. Ne',
  'rend pas les choses faciles. Il y a danger d''accident.',
  'L''activit‚ est f‚brile et l''esprit de suite fait d‚faut. Incline',
  '… la r‚volte. Esprit de contradiction. Accident.',
  'Empˆche de prendre conseil. On n''en fait qu''… sa tˆte. Peut',
  'pr‚sager un coup de tˆte fatal. Danger op‚ratoire. Malchance.',
  'Marque la force brutale subie ou inflig‚e. L''imprudence et la',
  't‚m‚rit‚ obligent au bluff. Facteur d''accidents.',
  'Marque une p‚riode d''ascension et de succŠs. Am‚lior‚ l''‚tat',
  'physique. Promet de l''avancement et la maŒtrise de soi.',
  'Dispose … l''optimisme et apporte une grande confiance en soi',
  '‚quilibre les finances. Propice aux faveurs. Chance.',
  'Facteur d''organisation et de m‚thode. Mod‚r‚ les d‚penses',
  'nerveuses. Apporte appuis et cr‚dits. Aide … la politique.',
  'Favorable aux affections et aux mariages. Aide … la venue du',
  'bien-ˆtre et du confort. Facteur d''‚quilibre. Chance.',
  'Mod‚r‚ l''impatience et freine l''impulsivit‚. Aide … faire des',
  'concessions. Propice … la chirurgie. Permet les risques.',
  'Satisfait les ambitions. Peut marquer la stabilisation d‚finitive',
  'et l''apog‚e de la situation. Propice … l''ƒge.',
  'Aide … d‚velopper les aptitudes sup‚rieures. Am‚lior‚ le sens',
  'pratique. Peut apporter un coup de chance rare.',
  'Am‚lior‚ la sant‚ et peut ˆtre le d‚part d''un gros apport de',
  'chance : h‚ritage ou protection. R‚alis‚ les rˆves.',
  'Ne peut apporter que des satisfactions, mat‚rielles et',
  'spirituelles. Favorable … la politique et au pouvoir.',
  'Facilite la venue de choses agr‚ables. Dispose … moins d''‚go‹sme',
  'et rend sociable. Resserre les liens. Chance.',
  'Incline … un d‚sint‚ressement utile. Les services rendus seront',
  'profitables dans l''avenir. Facteur de chance.',
  'Les chose ‚voluent normalement dans le sens des d‚sirs et des',
  'activit‚s. Promesse de qui‚tude morale et physique.',
  'Favorise la conduite de la vie et fait connaŒtre des joies. Indice',
  'de bonheur et de bonne entente. Petite chance.',
  'R‚gularise l''activit‚ et diminue l''intensit‚ des passions. Rend',
  'plus respectueux des lois. AccroŒt le confort.',
  'Apporte des facilit‚s professionnelles. Rend la vie int‚rieure',
  'paisible et dispose aux honneurs.',
  'Rend moins tributaire de ses nerfs. Organise et r‚gularise ce qui',
  'ne l''est pas. Favorable … la profession. Chance.',
  'Apporte de l''ampleur dans les r‚alisations. Remet les pieds sur',
  'terre et permet de porter un jugement plein de bon-sens.',
  'Pr‚dispos‚ … la loyaut‚ dans les luttes, mais sans indulgence.',
  'Marque le d‚but d''une prise de pouvoir.',
  'Permet de rayonner et d''ˆtre satisfait de son sort. AccroŒt le',
  'sens de l''opportunit‚. Satisfactions d''argent. Chance.',
  'Rend la vie plus gaie et les joies intimes plus grandes. Apporte',
  'des appuis et des protections. Bon indice de sant‚.',
  'Am‚lior‚ la sant‚ et r‚gularise les d‚penses vitales. Rend les',
  'id‚es rentables. Les relations utiles sont profitables.',
  'Satisfactions r‚elles dans la voie choisie. Pr‚sage',
  'l''accroissement des richesses. Facteur de chance.',
  'Dispose … faire des concessions et … ˆtre plus vivable. Facilite',
  'les unions et les associations. Bonne ‚nergie.',
  'Augmente la confiance en soi et l''optimisme. Permet d''aller de',
  'l''avant et de trouver aide et protection. Bonne sant‚.',
  'Met du plomb dans la tˆte de ceux qui l''ont l‚gŠre. On vend mieux',
  'ses efforts. Aide … se faire remarquer avantageusement',
  'Augmente l''ampleur de vue et les app‚tits mat‚riels. Pr‚sage',
  'l''accroissement du patrimoine. Augmente les ressources.',
  'Aide … faire de gros efforts pour s''enrichir. Fait rechercher le',
  'pouvoir et l''argent. Aide … la loyaut‚ dans les luttes.',
  'Expose aux difficult‚s mat‚rielles. Pr‚sage une p‚riode de',
  'conflits, d''ambition. Tendance … l''arrivisme. D‚penses.',
  'Rend la situation instable et les d‚penses d‚sorganisent les',
  'finances. Contraire aux sp‚culations et … la chance.',
  'Tendance … temporiser pour avoir la paix. Il arrive qu''on souffre',
  'd''une situation m‚diocre. La force morale manque.',
  'Pr‚dispos‚ … l''infid‚lit‚, … la dissipation et … la d‚bauche',
  'n''est pas favorable … la chance ni aux sp‚culations.',
  'Donne des dispositions ‚go‹stes et des app‚tits voraces. Rend',
  'jaloux. Manque de pers‚v‚rance dans l''effort.',
  'Incline … mener une vie d‚r‚gl‚e. Comportement ‚go‹ste et manque',
  'de mod‚ration. EntraŒn‚ des difficult‚s l‚gales.',
  'Les obligations empˆchent de vivre selon ses go–ts. Les moyens',
  'financiers sont insuffisants. Contraire … la chance.',
  'Mauvais indice de sant‚. D‚sorganis‚ le psychisme. Conduit …',
  'accepter des contraintes et des humiliations. Difficult‚s.',
  'Marque un grand besoin de jouissance mat‚rielle et donne l''amour',
  'de l''argent. Rend violent et tyrannique.',
  'Permet d''oeuvrer avec le maximum de chances de r‚ussite. On peut',
  'tout tenter et tout mener … bonne fin. Chance.',
  'Incline … se montrer bon vivant et … aimer les satisfactions de la',
  'vie. L''humeur est ‚gale. Facilite les affaires. Sant‚.',
  'Facteur d''accroissement rapide sur le plan mat‚riel. Satisfait',
  'les ambitions et incline au bon sens. Sant‚.',
  'Aide … la venue du bonheur. Augmente les dispositions altruistes',
  'et rend jovial. Influe heureusement les finances.',
  'Apporte de la mod‚ration dans les actes. Incline … la justice',
  '‚quilibr‚e et impartiale. TrŠs bon indice ‚nerg‚tique.',
  'Les app‚tits sont puissants et l''ambition ne manque pas. Facilite',
  'tout genre d''op‚ration immobiliŠre et financiŠre.',
  'Favorise ceux qui travaillent pour leur compte. Aide … faire',
  'admettre ses conceptions et … les imposer. Grande chance.',
  'Apporte des avantages mat‚riels sans gros efforts. La chance et',
  'les appuis utiles ne font pas d‚faut. Chance financiŠre.',
  'Aide … faire de gros efforts pour s''enrichir. Rend conscient de',
  'la valeur des richesses. Recherche du pouvoir. Optimisme.',
  'Rend moins distant dans la vie professionnelle et plus sentimental',
  'dans la vie affective. Permet l''ascension.',
  'AccroŒt les possibilit‚s d''entente dans la vie familiale et',
  'conjugale. Aide … supporter les peines. Facteur de chance',
  'Favorable au commerce. Permet … l''esprit de s''imposer',
  'avantageusement et de r‚soudre les tracas administratifs.',
  'Fait vivre le bonheur sans histoires. Peut favoriser les les',
  'acquisitions immobiliŠres et le commerce.',
  'Marque une ‚volution sereine et accroŒt le confort. Avantage le',
  'courage et la hardiesse. Favorable … la justice.',
  'Peut marquer des distinctions honorifiques. Incline … la r‚flexion',
  'et au bon sens. Rend conscient et prudent.',
  'Permet l''aboutissement de projets originaux. Augmente et affirme',
  'la confiance en soi. Indice de chance.',
  'Les risques de se tromper ou d''ˆtre trompe sont att‚nues.',
  'Amplifie les aspirations religieuses et mystiques.',
  'Marque un grand besoin de jouissances mat‚rielles. L''amour de',
  'l''argent peut inciter … un surmenage excessif. Pouvoir.',
  'Se montre contraire … la qui‚tude et … la libert‚. Conduit … la',
  'r‚volte contre l''autorit‚. Mauvais indice de sant‚.',
  'Un manque d''organisation diminue le bien-ˆtre et peut conduire …',
  'la ruine des espoirs. Fait user d''exp‚dients.',
  'Le sens critique diminue. On risque d''ˆtre submerg‚ par les',
  'difficult‚s. Dispose … la mythomanie et … la mauvaise foi.',
  'Dispose … d‚penser sans compter. Manque d''organisation financiŠre',
  'et complications familiales. Rend imprudent.',
  'Pr‚dispos‚ aux abus, … l''ambition et … l''arrivisme. Fait user',
  'parfois de moyens d‚fendus pour arriver … ses fins.',
  'Rend orgueilleux et protecteur, inflexible et violent. Est',
  'contraire … l''ambition et oblige … la lutte. Ins‚curit‚.',
  'Dispose … l''extravagance et … l''impr‚voyance. Risques de heurts',
  'avec le pouvoir. Pr‚sage des difficult‚s mat‚rielles.',
  'Manque de courage moral et physique. Peut marquer certains',
  'abandons et faire vivre avec ‚go‹sme. Crise mystique.',
  'Peut conduire … user d''exp‚dients plus ou moins l‚gaux. Incline …',
  'la tyrannie et … la prise de pouvoir. Dangereux.',
  'N''est pas un facteur satisfaisant pour la sant‚. Cause des',
  'problŠmes d''ordre professionnel. Diminution du prestige.',
  'Contraire … la sant‚. Diminue le tonus. EntraŒn‚ des pertes de',
  'popularit‚ ou de cr‚dit. Contraire … la chance. Solitude.',
  'Les r‚alisations sont difficiles par manque de confiance.',
  'Scrupules excessifs. Esprit critique. Mauvaise sant‚.',
  'Apporte calme et calcul dans les amours. Stabilise les affections.',
  'Bonnes dispositions financiŠres. Rend sage.',
  'Expose aux blessures morales et physiques. Ralentit les r‚flexes.',
  'Expose … la critique. Risque op‚ratoire. Entˆtement',
  'Incline … moins se d‚penser. Permet d''accepter des',
  'responsabilit‚s et d''y faire face. Indice de stabilit‚ et',
  'sagesse.',
  'Influence restrictive sur l''activit‚ physique. Facteur de',
  'troubles psychiques. Pr‚sage des avatars et rend instable.',
  'Renforce l''‚go‹sme et fixe les passions. Perte de m‚moire.',
  'Diminue le bon-sens. Facteur de fatigu‚ et de paresse.',
  'Renforce l''inflexibilit‚ et tend … cristalliser ce qui est.',
  'Restreint la sexualit‚ et la passion. Rend r‚fl‚chi, s‚rieux.',
  'Donne plus de maŒtrise sur soi-mˆme et augmente le libre-arbitre.',
  'Permet de conserver les acquis et de temporiser.',
  'Indique une stabilisation qui r‚pond aux d‚sirs ou une initiative',
  'qui se r‚v‚lera profitable. Repos salutaire.',
  'Rend moins impressionnable et plus calme. Favorable …',
  'l''intellect. Freine les d‚penses. Valorise la r‚flexion.',
  'Marque une p‚riode de s‚curit‚. Stabilise les bonnes choses et',
  'fixe les qualit‚s. Donne du poids et de la profondeur.',
  'Pr‚dispos‚ … mieux faire ce que l''on fait. Permet d''imposer ses',
  'directives et d''ˆtre ‚coute. Stabilise les choses.',
  'Incline … se comporter avec sagesse et circonspection. Apporte du',
  'calme et de la s‚curit‚ dans la vie. Avancement.',
  'Donne une plus grande libert‚ d''action. Intensifie l''attention,',
  'la pers‚v‚rance et la maŒtrise de soi-mˆme.',
  'Facteur de s‚curit‚ mat‚rielle et de qui‚tude morale. Rend',
  'conscient de ses possibilit‚s et plus raisonnable.',
  'Discipline et calme l''esprit. Permet de garder la tˆte froide et',
  'le coeur sec. On oeuvre avec conscience.',
  'Marque la stabilit‚ dans l''emploi et la continuit‚ dans',
  'l''ascension. R‚conforte l''esprit. Propice … la r‚flexion.',
  'Donne de l''empire sur soi. Permet de voir les choses dans le',
  'temps. Les initiatives sont raisonnables. Sp‚culation.',
  'L''activit‚ c‚r‚brale domine le physique. La prudence grandit et',
  'l''attention se fixe. Conscience des r‚alit‚s. Raison.',
  'Le destin est cl‚ment et ne contrarie pas le libre-arbitre. Les',
  'd‚cisions sont raisonnables. Respect de la parole donn‚e.',
  'Permet d''accepter de lourdes charges morales ou financiŠres. Les',
  'efforts sont m‚ritoires et on peut compter sur soi.',
  'Dispose … bien faire ce que l''on doit. La bonne volont‚ permet de',
  'trouver aide et conseil. Stabilit‚ de l''emploi.',
  'Incline … se montrer plus calme et plus r‚serv‚ dans les rapports',
  'sociaux. Bon ‚quilibre nerveux. La prudence grandit',
  'Les risques de se tromper ou de l''ˆtre diminuent. Am‚lior‚ le',
  'mental et l''‚quilibre nerveux. Favorable … la m‚ditation.',
  'Rend l''esprit calme et discipline. On fait ce que l''on doit et',
  'on fait mieux que d''habitude. Le courage est tranquille.',
  'Diminue consid‚rablement la vitalit‚. Le corps et l''esprit',
  'perdent de leur souplesse. Contraire … la sant‚. Accident.',
  'Les entreprises et les initiatives nouvelles sont destin‚es … des',
  'r‚sultats mis‚rables. Le destin est contraire.',
  'Diminue la confiance en soi. Difficile de faire un choix. Cause',
  'des accidents par maladresse. Rend malhabile.',
  'Rend jaloux et m‚fiant. Expose … la souffrance sentimentale.',
  'Complexe d''inf‚riorit‚ en amour. Pr‚sage des ennuis de coeur.',
  'Permet la r‚flexion, la prudence et la m‚fiance. Pr‚sage des',
  'revers et le d‚couragement. Manque de chaleur. Heurts.',
  'L''activit‚ et le bon sens diminuent. Les projets sont orgueilleux',
  'ou utopiques. Perte de contact avec la chance.',
  'D‚s‚quilibre le moral et affaiblit les moyens. Crainte de l''‚chec',
  'et manque de confiance en soi. On perd du temps.',
  'Pr‚dispos‚ … la paresse et … la fatigu‚. Tendance … s''abandonner',
  '… son destin. Comportement fataliste. go‹sme.',
  'Rend avide et violent, susceptible et jaloux. On peut se montrer',
  'trompeur ou astucieux. Le destin est contraire.',
  'Marque la pl‚nitude des moyens d''action. Permet de faire face …',
  'ses responsabilit‚s. MaŒtrise des ‚motions. S‚rieux.',
  'Apporte de l''ordre et de la m‚thode. AccroŒt la r‚sistance',
  'physique. B‚n‚fique aux exp‚riences et … la recherche.',
  'AccroŒt la valeur et la grandeur de l''intellect. Donne fermet‚ et',
  'sagesse aux r‚alisations. Satisfait la raison.',
  'Aide … la renomm‚e artistique et scientifique. Heureuses',
  'dispositions pour les combinaisons financiŠres. Pr‚voyance.',
  'Rend raisonnable et de bon conseil. Les passions sont c‚r‚brales',
  'et calcul‚es. Aptitudes au commandement. Volont‚.',
  'Apporte sagesse et sobri‚t‚. Marque l''ascension r‚guliŠre. La vie',
  'mat‚rielle est stable. Favorable … l''effort continu.',
  'Apporte plus de logique et de pond‚ration. Sens du r‚el. La',
  'stabilit‚ mentale contribue … ˆtre pris au s‚rieux.',
  'Aide … voir les choses sous un angle plus pratique et moins',
  'abstrait. Les d‚cisions sont compt‚es. Stabilit‚ psychique.',
  'Fait oeuvrer avec patience et conscience. Les ambitions et les',
  'joies sont d''ordre intellectuel. Facteur de richesse.',
  'Augmente le libre-arbitre et la maŒtrise sur soi-mˆme. Favorise la',
  'prudence, la patience et la pr‚cision. Sant‚.',
  'Peut marquer l''aboutissement des recherches ou des ‚tudes. TrŠs',
  'favorable … une journ‚e de repos ou de retraite.',
  'Excellent pour les d‚cisions et le libre-arbitre. Favorable … la',
  'concentration et … la r‚flexion. Augmente la raison.',
  'Favorable au s‚rieux et … la fid‚lit‚. Dispose au calme et … la',
  'r‚serv‚, surtout en ce qui concerne l''affectivit‚.',
  'Stabilise la volont‚, l''endurance et l''obstination. TrŠs bonne',
  'r‚sistance physique et mentale.',
  'Apporte calme et s‚curit‚ dans la vie. Propice aux acquisitions',
  'mat‚rielles. Aide … l''avancement et donne du s‚rieux',
  'Intensifie l''attention, la pers‚v‚rance et la maŒtrise. Permet',
  'd''atteindre les projets ‚labor‚s … long terme.',
  'Rend moins perm‚able aux influences ext‚rieures et plus conscient',
  'de ses possibilit‚s. Raisonne le psychisme.',
  'On sait ce que l''on doit faire quand les choses tournent mal',
  'pr‚sage conscience et patience. Le temps est de bon conseil.',
  'Pr‚dispos‚ … se montrer peu sociable, sinon odieux. Rend l''esprit',
  'pessimiste et peu enjou‚. Cause des rivalit‚s.',
  'Apporte du s‚rieux, de la s‚v‚rit‚ et de la tristesse. L''esprit',
  'est inquiet et soup‡onneux. On souffre en silence.',
  'Se montre contraire … la chance et … la sant‚. Cause de tristesse',
  'et de solitude morale. Ralentit l''activit‚.',
  'Peu favorable aux finances et aux amours. On peut ˆtre craint et',
  'respect‚, mais toujours mal aim‚. M‚lancolie.',
  'On est sans cesse sur la d‚fensive. Manque de confiance et de',
  'souplesse morale. La vie est faite de combats. Faiblesse.',
  'Incline … ˆtre aussi dur avec soi-mˆme qu''avec les autres. Les',
  'passions sont c‚r‚brales. Manque d''indulgence.',
  'Restreint le libre-arbitre. Freine l''activit‚ physique et les',
  'initiatives. Recherche de la solitude. Duret‚ du destin.',
  'Intensifie les dispositions ‚go‹stes. Marque un ralentissement de',
  'la force vitale. Solitude impos‚e par le destin.',
  'Rend avide et violent, susceptible et jaloux, indiscipline. Le',
  'destin est contraire et on r‚agit avec violence.',
  'N''aide pas … supporter les contraintes et incline … se',
  'd‚barrasser de ses chaŒnes. Aide … faire parler de soi.',
  'Cause l''instabilit‚ physique et les sautes d''humeur. Incline …',
  'agir … contre-sens. P‚riode d''ins‚curit‚. Pr‚monition.',
  'Augmente l''originalit‚ des id‚es et les valeurs intellectuelles.',
  'Am‚lior‚ la force nerveuse. Intuitions heureuses.',
  'Fait rechercher les personnes jeunes. Apporte l''originalit‚ dans',
  'les cr‚ations et les amours. Spontan‚it‚ des plaisirs.',
  'N''inclin‚ pas … suivre la foule. Dispose … employer des moyens',
  'violents pour arriver … ses fins. Impulsivit‚.',
  'Apporte des ‚clairs de g‚nie et de la nouveaut‚ dans la vie.',
  'Marque l''avancement, les honneurs et les faveurs. Chance.',
  'Ne permet pas de se plier aux rŠgles de la vie en commun. Peut',
  'd‚truire ce qui paraissait d‚finitif ou solide.',
  'Accentue le go–t de la nouveaut‚ et de l''impr‚vu. Peut faire',
  'lƒcher la proie pour l''ombre. Sensitivit‚ accrue.',
  'Marque la r‚volte spontan‚e. TrŠs forte excitation mentale.',
  'Pr‚dispos‚ aux extrˆmes sans soucis des nuances. Violence.',
  'Peut marquer une ‚volution … la suite d''un fait inattendu.',
  'Apporte une plus grande ind‚pendance. Lib‚r‚ des contraintes',
  'Active l''imagination et donne des intuitions heureuses. Permet de',
  'sortir de l''embarras et d''oeuvrer avec originalit‚',
  'Favorise le mental et aide … trouver une solution aux problŠmes',
  'complexes. Aide … la r‚ussite financiŠre. Chance.',
  'Pr‚sage des satisfactions. La r‚ussite est due aux efforts et au',
  'talent. Lib‚r‚ de l''inqui‚tude de l''incommode. Chance.',
  'Apporte des impr‚vus heureux. Aide … se faire remarquer. Pr‚sage',
  'des succŠs d''estime. Am‚lior‚ l''‚quilibre nerveux.',
  'Active le mental et les conceptions personnelles. Aide … faire',
  'triompher ses id‚es et … aller de l''avant. Chance.',
  'Dispose … faire contre mauvaise fortune bon coeur. Apporte des',
  'petits impr‚vus plus ou moins heureux. Diminue le risque',
  'Rend les efforts moins p‚nibles et plus rentables. Apporte de',
  'petites satisfactions fortuites et des appuis impr‚vus.',
  'Facteur de force nerveuse et d''‚quilibre physique. Rend moins',
  'sensible aux ‚v‚nements ext‚rieurs. Prise de risques.',
  'Apporte des conceptions originales pour sortir d''embarras.',
  'Favorable aux ind‚pendants. Activit‚ d‚bordante. Chance.',
  'Donne des r‚flexes utiles et une intelligence pratique. Permet',
  'l''adaptation. Pr‚sage un changement impr‚vu. Chance.',
  'Favorable aux op‚rations financiŠres. Aide les novateurs, les',
  'inventeurs et les politiciens. Ind‚pendance d''esprit.',
  'Pr‚sage un coup de chance heureux. Bonne entente dans les unions',
  'et communions d''id‚es. AccroŒt les moyens financiers.',
  'Donne une grande maŒtrise sur les nerfs. Rend inventif et',
  'industrieux. Pr‚sage des satisfactions d''un ordre ‚lev‚.',
  'AccroŒt la curiosit‚ intellectuelle. Fait aimer ce que l''on fait',
  'et ne faire que ce que l''on aime. R‚compense les efforts',
  'Le destin se montre cl‚ment et l''ambition se trouve souvent',
  'satisfaite. L''esprit voit les choses avec ampleur. Ambition.',
  'Aide … se lib‚rer des obligations. Permet de ne pas se laisser',
  'absorber. loign‚ les risques. Retour de paix. Chance.',
  'Fait accepter les responsabilit‚s et prendre des risques. Augmente',
  'l''ambition. Les id‚es sont personnelles et ancr‚es.',
  'Cause une surexcitation maladive et une activit‚ intellectuelle',
  'd‚sordonn‚e. Oppose au pouvoir. Destin capricieux.',
  'Expose aux scandales causes par l''incons‚quence. L''esprit est',
  'tourmente par les d‚sirs. Le destin est contraire.',
  'Incite … chercher le pourquoi des choses. Le sens pratique fait',
  'd‚faut. Incline au jeu et aux sp‚culations. Nervosit‚.',
  'Rend excentrique et original. Se m‚fier des faits impr‚vus.',
  'Contraire aux amours r‚guliŠres et unions l‚gales. Scandale.',
  'Pr‚dispos‚ … l''orgueil intellectuel et … la vanit‚. Manque de',
  'sociabilit‚. Arrivisme. Pr‚sage l''imprudence. Violence.',
  'Pr‚dispos‚ … l''indisciplin‚ et … l''anarchie. Peut marquer une',
  'p‚riode de revirements impr‚vus et dangereux. Crises.',
  'Incline … la suractivit‚ nerveuse. Fait tenir des propos',
  'extravagants et g‚n‚ralement subversifs. Actes t‚m‚raires.',
  'Peut modifier soudainement les conditions de vie. Le destin se',
  'montre incl‚ment. Dispose … se montrer licencieux.',
  'Une excitation mentale continuelle rend l''activit‚ f‚brile. Fait',
  'commettre des excŠs qui troublent l''‚quilibre nerveux.',
  'Aide … faire face … toutes les oppositions et … triompher. Permet',
  'de trouver des forces nouvelles. Ind‚pendance d''esprit',
  'Permet d''attirer les faveurs populaires. Apporte des secours',
  'providentiels. Aide … la sp‚culation. Facilite la recherche.',
  'AccroŒt le potentiel nerveux et la rapidit‚ de l''entendement les',
  'd‚sirs sont satisfaits par l''esprit et par la chance.',
  'Donne des conceptions neuves et hardies. lev‚ les pens‚es et les',
  'go–ts. Excite la curiosit‚ et favorise les finances.',
  'Incline … mener sa vie avec ind‚pendance. Fait triompher les id‚es',
  'et apporte des satisfactions d''orgueil. Volont‚.',
  'Apporte des impr‚vus heureux qui brisent la monotonie. Donne le',
  'go–t du risque. Excellent indice de chance.',
  'Aide … faire face … l''adversit‚ et … en triompher. AccroŒt toutes',
  'les qualit‚s qui permettent de conserver sa dignit‚.',
  'Peut marquer un revirement impr‚vu du destin dans le sens d''une',
  'transformation heureuse et lucrative. Chance financiŠre',
  'Tend … accepter des risques et des responsabilit‚s et de se',
  'sacrifier pour cela. Marque la maŒtrise sur soi et autrui.',
  'Apporte une grande ind‚pendance et lib‚r‚ de contraintes morales.',
  'Marque l''aboutissement des projets originaux.',
  'Marque l''aboutissement des intuitions heureuses qui sortent de',
  'l''embarras. quilibre le psychisme. Pr‚monition.',
  'Peut marquer la r‚ussite financiŠre ou l''aboutissement des',
  'recherches ou ‚tudes scientifiques. Favorable au mental.',
  'Lib‚r‚ l''esprit des inqui‚tudes ou des complexes et le corps des',
  'incommodit‚s mal d‚finies. Marque l''amour et l''affection',
  'Marque l''aboutissement heureux de l''effort. Aide … se faire',
  'remarquer et satisfait l''amour-propre. Bonne ‚nergie.',
  'Fait triompher les id‚es et les projets. Permet d''aller de',
  'l''avant en faisant du neuf. Aide … l''innovation. Chance.',
  'Diminue les risques d''‚chec dans les sp‚culations. Permet',
  'd''allier la raison … la spontan‚it‚. Le temps est un atout.',
  'Rend les efforts moins p‚nibles et plus rentables. Propice … la',
  'chance financiŠre et … la sp‚culation.',
  'Marque la maŒtrise de soi et permet d''user du libre-arbitre.',
  'Pr‚sage l''aboutissement de grands projets. Indice d''‚nergie.',
  'Incline au caprice, … l''indisciplin‚ et … l''insouciance.',
  'Contraire … l''‚quilibre nerveux. Peut marquer un accident.',
  'Peut causer des revirements inattendus et malheureux. Incite … se',
  'faire remarquer. Modifie le comportement.',
  'Incline … la t‚m‚rit‚. Fait aimer l''aventure et le risque.',
  'Dispose … se croire incompris et … se r‚volter. Nervosit‚.',
  'Rend indisciplin‚, inconstant et capricieux. Les affections sont',
  'instables. Peut causer des pertes de faveur.',
  'Les app‚tits sont violents. On vise haut avec d‚mesur‚. Peut',
  'marquer un accŠs de violence ou l''accident. ColŠre.',
  'Pr‚sage des crises parfois brutales. Pr‚dispos‚ … la n‚gligence, …',
  'l''impr‚voyance et … l''indisciplin‚. Conflits.',
  'Peut causer des catastrophes ou des accidents. Cause des pertes de',
  'situation et de cr‚dit. Se m‚fier de la violence.',
  'Trouble toujours la qui‚tude et expose … des dommages et des',
  'pertes. Pr‚sage une folle t‚m‚rit‚. F‚brilit‚.',
  'Fait commettre des excŠs qui troublent l''‚quilibre sur tous les',
  'plans. Les efforts sont violents. Indice d''accidents.',
  'Am‚lior‚ la situation, le mental et les dons naturels. Permet de',
  's''imposer ais‚ment. Favorise les grandes affaires.',
  'Tendance … vivre dans l''irr‚el. Expose … la tromperie. Augmente',
  'la sensitivit‚ et la force psychique. Pr‚monition.',
  'Facteur de chance mat‚rielle. Augmente la sensibilit‚ et',
  'l''imagination. Favorable aux travaux occultes. Intuition.',
  'Apporte la qui‚tude mat‚rielle et les jouissances du corps.',
  'Pr‚sage des protections utiles, surtout f‚minines. rotisme.',
  'Donne conscience de ses forces et de ses possibilit‚s. Aide … la',
  'perfection. Favorise la m‚decine et la chirurgie.',
  'Apporte souvent une protection ou un appui de taille. Sin‚cure',
  'lucrative, revenus occultes et profits myst‚rieux.',
  'Incline … l''isolement et … retarder l''‚volution psychique.',
  'Pr‚sage des incommodit‚s. Pr‚dispos‚ au mysticisme.',
  'Cause des faits peu communs et parfois inexplicables. Expose au',
  'scandale et aux contraintes. Hypersensitivite.',
  'Aide … la persuasion et permet de faire partager sa foi. La',
  'confiance en soi grandit. Incline … mener une vie double.',
  'Am‚lior‚ les conditions de vie et aide au contentement de l''ƒme.',
  'Peut signifier la d‚couverte d''une voie mystique.',
  'Donne un besoin d''affection et rend amoureux. Permet de plaire et',
  'de se rendre sympathique. Aide la chance.',
  'Aide … voir clair en soi et … deviner les autres. Am‚lior‚ les',
  'qualit‚s psychiques. Favorise les d‚couvertes et voyages',
  'Apporte des appuis affectueux et la qui‚tude. Rend la vie',
  'mat‚rielle plus facile. Facteur de d‚tente et de relaxation.',
  'Facteur de chance et d''appuis. Facilite la conduite de la vie et',
  'rend les efforts moins p‚nibles. Volont‚ spirituelle.',
  'AccroŒt la sensibilit‚ et rend la vie int‚rieure intense. Aide par',
  'la m‚ditation … trouver une r‚ponse aux problŠmes.',
  'Rend l''esprit compr‚hensif et perm‚able aux influences. Donne des',
  'intuitions raisonn‚es. Calme la vie psychique.',
  'Donne un bon moral, un jugement sain et tol‚rant. Modifie',
  'heureusement la maniŠre de voir et de sentir. Perception.',
  'Peut donner naissance … une nouvelle personnalit‚ qui par',
  'auto-suggestion va r‚aliser ce qui semblait impossible.',
  'Apporte calme et sagesse dans la conduite de la vie. Les',
  'conceptions sont heureuses car le bon sens ne manque pas.',
  'Aide au d‚veloppement des qualit‚s passives et des dons naturels.',
  'Fortifie la m‚moire et l''intuition. Bien-ˆtre.',
  'Peut marquer un changement de situation au travers d''une source',
  'de revenus myst‚rieux. Favorise la recherche d''argent.',
  'Incline … rechercher l''amour et … rencontrer la qui‚tude du coeur.',
  'Favorise la venue de legs ou de dons. Chance pure.',
  'Am‚lior‚ l''‚quilibre nerveux et donne le contr“le sur soi.',
  'Apporte l''aide d''autrui. Favorable aux donations. Volont‚.',
  'Influence heureusement les qualit‚s mentales sup‚rieures. Am‚lior‚',
  'la vie priv‚e et sociale. Chance financiŠre.',
  'L''esprit per‡oit avec intensit‚ et rapidit‚. Rend moins ‚go‹ste,',
  'plus humain et plus affectueux. Aide aux finances.',
  'Modifie heureusement le comportement moral. Favorise',
  'l''ing‚niosit‚ dans la profession. Aide au pressentiment. Chance.',
  'Intensifie la r‚sistance morale et la vitalit‚. Le besoin de vivre',
  'ses rˆves devient vivace. Go–t de l''aventure.',
  'Diminue l''activit‚ physique et la r‚sistance morale. Peut marquer',
  'l''impuissance … r‚aliser. Facteur de mauvaise sant‚.',
  'Contraire … la sant‚. AccroŒt l''‚go‹sme et fait manquer de',
  'libre-arbitre. On devient le jouet des ‚v‚nements. FiŠvre.',
  'Contraire … la sant‚ et … l''‚quilibre nerveux. Expose … des',
  'fr‚quentations louches. Incline aux erreurs de jugement.',
  'Cause de d‚sordres psychique dus … des besoins myst‚rieux. Indice',
  'de mauvais go–t. Incline aux d‚sordres sexuels.',
  'Incline … la jouissance ‚go‹ste. Contribue aux combinaisons',
  'louches ou illicites. Rend craintif. Risque de blessure.',
  'Trouble les sens et met les ‚motions … fleur de peau. Dispose …',
  'l''extravagance et aux d‚penses. Faiblesse morale.',
  'D‚clin du sens pratique, de la fermet‚ et de la logique. Le destin',
  'est souvent contraire. Mauvaise sant‚ psychique.',
  'Cause des d‚pressions nerveuses. Pr‚dispos‚ … l''inqui‚tude. Fait',
  'mentir sans raison et se leurrer soi-mˆme. Nervosit‚.',
  'Parfois l''impossibilit‚ de vivre comme on le d‚sir‚ peut cr‚er',
  'des id‚es fixes qui d‚rŠglent le psychisme.',
  'Permet de voir les choses avec ampleur. Indice de sant‚. Favorise',
  'la chance mat‚rielle. Permet de gouverner et pr‚voir',
  'Dispose aux inspirations ‚lev‚es et conduit parfois … la vision',
  'mystique. Permet le don de soi-mˆme. Sant‚ psychique.',
  'Rend sympathique et aimant. AccroŒt les possibilit‚s de r‚ussite.',
  'Favorable aux soins. Favorable aux ‚crits. Sant‚.',
  'AccroŒt la sensibilit‚ et l''‚motion. Affine les sentiments.',
  'Marque les unions et les amours durables. Besoin d''aimer.',
  'Facteur de sagesse et de prudence. Aide … croire en la providence',
  'et oeuvrer avec confiance. Favorise les chefs.',
  'Facteur de chance mat‚rielle. La fortune est g‚n‚ralement assur‚e',
  'et peut venir en dormant. Dispose au conseil sain.',
  'La chance seconde les efforts. TrŠs bon ‚quilibre psychique. Les',
  'obstacles sont rares et les r‚ussites nombreuses. Sant‚.',
  'Sensibilise les qualit‚s c‚r‚brales. Stimule positivement',
  'l''imagination et l''intuition. AccroŒt la m‚moire. G‚nialit‚.',
  'Grandit la confiance en soi et la persuasion. Rend possible la',
  'communion et le partage de la foi. Conscience totale.',
  'Aide au contentement de l''ƒme et permet la prise de conscience',
  'des facult‚s psychiques. Imagination maximum.',
  'Aide … sentir d''ou vient le vent et … se placer du bon c“t‚ sur',
  'le chemin de la chance. R‚alis‚ les rˆves. Visions.',
  'TrŠs favorable aux ‚tudes herm‚tiques et aux contrats priv‚s.',
  'Influence avantageusement l''esprit.',
  'La fortune vient parfois en dormant. Peut ˆtre le pr‚sage d''une',
  'chance financiŠre exceptionnelle. Exalt‚ la s‚duction.',
  'Rend le travail plus r‚mun‚rateur. Fait b‚n‚ficier de son',
  'exp‚rience ou de celle de l''entourage. Marque la gu‚rison.',
  'Amplifie la sensibilit‚ et rend la vie int‚rieure plus intense.',
  'Peut apporter la richesse. Favorable aux finances.',
  'Donne la raison et le pouvoir de s''en servir. Peut ˆtre favorable',
  'au d‚sint‚ressement. Accorde patience et calme.',
  'Amplifie au plus haut point la puissance psychique. Pr‚sage une',
  'hyper‚motivit‚. Rend r‚ceptif … la fortune.',
  'Dispose … vivre seul avec soi-mˆme et cela mˆme au milieu de la',
  'foule ou l''on trouve la possibilit‚ de s''isoler.',
  'Ne dispose pas … la gaiet‚. Le besoin de paix se fait sentir.',
  'Risque de se laisser entraŒner dans des combinaisons louches',
  'Ne favorise pas l''union et se montre contraire … l''union.',
  'Risques de tromperie. Trouble les sens. Indice de maladie.',
  'D‚s‚quilibre le psychisme. Les efforts physiques sont lassants. La',
  'volont‚ est faible. Sp‚culations malheureuses.',
  'Dispos … la rˆverie et au farniente. Pr‚dispos‚ … l''‚go‹sme et …',
  'la sensiblerie. Facteur de lassitude et d''abattement.',
  'Pr‚sage des pertes de contr“le dans les luttes. Dispose au caprice',
  'et … la vanit‚. Rend inquiet. Danger de blessure.',
  'N''est pas propice … la lutte. Fait les maladies imaginaires.',
  'Incline … la cr‚dulit‚ et … la superstition. D‚sillusions.',
  'Fausse le jugement. Rend inqui‚tant et dangereux. TrŠs mauvais',
  '‚tat psychique. Les soucis empoisonnent l''existence.',
  'Peut rompre l''‚quilibre des facult‚s intellectuelles et troubler',
  'les sensations. On vit ce que l''on rˆve. motivit‚.',
  'Pr‚dispos‚ … perdre tout sens moral et sem‚ le doute dans les',
  'coeurs. Incline … fomenter des troubles et actes vils.',
  'Exacerbe la sensibilit‚ et augmente l''‚motivit‚. Dispose …',
  's''auto-analyser. AccroŒt les facult‚s d''observation.',
  'AccroŒt l''imagination et sensibilise la conscience. Incline au',
  'besoin de protection et de s‚curit‚. Repli sur soi.',
  'Aiguise l''intelligence et la curiosit‚. Favorise les ‚tudes, les',
  'recherches et les travaux d''investigation. Psychanalyse.',
  'Apporte un climat passionnel et parfois douloureux. Fait',
  'rechercher l''absolu en amour. Relations profondes.',
  'Pr‚dispos‚ aux actions rapides et percutantes. On se tient en',
  'permanence sur le pied de guerre. P‚riode ‚nergique.',
  'Pr‚dispos‚ … exercer le pouvoir sur l''entourage. Porte … r‚aliser',
  'ses desseins par la ruse et la manipulation.',
  'Restreint les sentiments et les instincts au profit de la raison.',
  'AccroŒt la m‚fiance et pr‚sage le repli sur soi.',
  'Provoque d''importants bouleversements et des prises de conscience',
  'brutales. Tendance … l''aventure et la r‚bellion.',
  'P‚riode marqu‚e par le secret. Favorise les d‚couvertes et les',
  'r‚v‚lations. Marque les exp‚riences occultes. Mysticisme.',
  'D‚sir de se battre pour ce qui tient … coeur. Peut pr‚sager le',
  'd‚but d''une action de grande envergure. Regain d''‚nergie.',
  'Incline aux d‚sirs ardents et aux projets li‚s au pouvoir. Facteur',
  'd''‚mancipation. Tendance … vouloir manipuler.',
  'Marque les projets et l''intuition. TrŠs favorable … un retour sur',
  'soi et … l''introspection. Combat des id‚es.',
  'Peut marquer le d‚but d''une passion sentimentale. Marque',
  'l''enthousiasme et les d‚sirs profonds.',
  'Marque l''audace, la fougue et le d‚sir. Favorable aux activit‚s',
  'violentes et au d‚but des entreprises difficiles.',
  'AccroŒt la vitalit‚ et la chance. Peut pr‚sager le d‚but d''une',
  'p‚riode d''enrichissement. Favorable au pouvoir.',
  'Marque l''orgueil intellectuel et pr‚dispos‚ aux rapports tendus',
  'avec l''entourage. Peut pr‚sager une d‚couverte.',
  'Permet d''agir avec d‚termination et courage. L''ind‚pendance et',
  'la force de caractŠre se r‚vŠlent propices … l''effort.',
  'Permet de se tirer avantageusement de situations troubles.',
  'Favorable aux r‚flexions mystiques. Besoin d''universalit‚.',
  'Pr‚dispos‚ … perfectionner et … reformer. Indice d''un bon',
  '‚quilibre psychique. Permet de r‚fl‚chir avec raison.',
  'Propice pour se donner … ce que l''on aime et d‚sir‚. Permet la',
  'vision des projets … long terme. Rˆves profonds.',
  'Bonne p‚riode pour l''intuition et l''intelligence. Permet',
  'l''introspection et les d‚couvertes. On fonctionne au radar.',
  'L''imagination sentimentale demande … se concr‚tiser. Permet de',
  'vivre ses passions avec tranquillit‚. Sensualisme.',
  'Favorable pour organiser ses projets et le besoin d''action.',
  'AccroŒt les qualit‚s d‚fensives. Satisfait l''ambition.',
  'AccroŒt et favorise l''ambition. Aide aux efforts pour',
  's''enrichir. Favorise les transactions et les finances.',
  'Fait oublier les sentiments au profit du calcul. Favorise le repli',
  'sur soi. Marque le calme et la discipline.',
  'Permet la satisfaction des id‚es nouvelles. Favorable aux',
  'initiatives audacieuses et aux entreprises impulsives.',
  'AccroŒt la connaissance intuitive de son environnement. Aiguise la',
  'psychologie et le besoin de d‚couverte.',
  'D‚stabilis‚ la situation et tend … culpabiliser. Marque la r‚volte',
  'et les d‚penses. Intensifie les passions. Bluff.',
  'Mauvais contr“le de l''imagination et des d‚sirs. Augmente',
  'l''‚go‹sme, le mat‚rialisme et la sensualit‚. Scandale.',
  'Pr‚dispos‚ … la curiosit‚ et … la violence du verbe. Se m‚fier des',
  'critiques et de la pol‚mique. Maux de tˆte.',
  'Pr‚sage l''insatisfaction affective. Fait rechercher les',
  'sentiments inaccessibles. Pr‚sage la violence passionnelle.',
  'AccroŒt l''activit‚ et l''‚nergie sans r‚sultats satisfaisants',
  'marque des r‚actions agressives et destructrices. Accident.',
  'Marque un grand besoin de jouissance mat‚rielle. Pr‚dispos‚ … la',
  'violence et … la tyrannie et … user d''exp‚dients.',
  'Pr‚dispos‚ aux conflits entre les d‚sirs et les principes. Peut',
  'marquer une p‚riode de solitude douloureuse. Maladie.',
  'Tendance … la brutalit‚ et … la violence. Recommande la prudence',
  'en toute chose. Pr‚cipitation et risque d''accident.',
  'Fait vivre dans un climat trouble et d‚primant. AccroŒt la',
  'tendance au secret et au mensonge. D‚sordre psychique.',
  'Pr‚sage la satisfaction des ambitions et accorde l''‚nergie',
  'n‚cessaire … cela. TrŠs favorable pour s''imposer. Sant‚.',
  'Pr‚dispos‚ … l''imagination de grande envergure. Permet le',
  'd‚vouement et la domination des sentiments et passions.',
  'Pr‚cise la pens‚e et rend apte … d‚couvrir les secrets. Rend',
  'ing‚nieux et habile de ses mains. Aiguise l''intellect.',
  'Harmonise les sentiments et les d‚sirs. Peut marquer',
  'l''‚panouissement des d‚sirs et de la sexualit‚.',
  'Intensifie l''activit‚ et fait maŒtriser l''‚nergie. P‚riode',
  'favorable aux luttes et … l''audace. Fait battre les records.',
  'Aide … s''enrichir sur tous les plans. Augure une bonne dose de',
  'force morale et physique. TrŠs bon indice de sant‚.',
  'Augmente la lucidit‚ et la raison. Permet de garder la tˆte froide',
  'et d''agir avec t‚nacit‚. Favorable … l''effort.',
  'Stimule l''‚nergie et l''audace. Favorable aux prises de d‚cision',
  'fermes et courageuses. Exalt‚ le psychisme.',
  'Accorde une grande force psychique et augmente la profondeur des',
  '‚motions. Exalt‚ la vie int‚rieure. Indice de sant‚.',
  'Permet de modifier en profondeur sa maniŠre de vivre. Favorable …',
  'la domination des sentiments et des pulsions.',
  'Pr‚dispos‚ … donner de l''importance aux passions et de diriger sa',
  'vie dans le sens des besoins. Incline aux abus.',
  'Permet de d‚couvrir le c“t‚ cache des choses. AccroŒt',
  'l''originalit‚ des id‚es et des conceptions. Incline au doute.',
  'Dispose … charmer pour influencer son entourage. Peut accorder des',
  'b‚n‚fices au travers de l''art et du beau.',
  'Permet de lutter avec efficacit‚ et force. Incline … s''opposer',
  'aux contraintes et permet les actions secrŠtes.',
  'Dispose … dominer l''entourage. Accorde autorit‚ et pouvoir.',
  'Favorable … la signature des contrats et … l''expansion.',
  'Fait concentrer ses forces dans un but unique et de r‚sister aux',
  'situations les plus ‚prouvantes. Rend dur et cassant.',
  'Pr‚sage un durcissement dans le refus et la r‚volte. Aide …',
  'maŒtriser les impulsions violentes. Bonne ‚nergie.',
  'Fait rechercher les satisfactions profondes de l''ˆtre. Permet de',
  'r‚aliser le maximum. Propice aux actions ultimes.',
  'Laisse pr‚sager de violents conflits. Augmente la virilit‚ et',
  'incite … la d‚pens‚ d''‚nergie. Expose aux accidents.',
  'Incline aux sautes d''humeur et aux caprices. Marque',
  'l''imagination insatisfaite. Mauvais indice de sant‚.',
  'Donne l''esprit d''analyse et la m‚fiance. Activit‚ f‚brile et',
  'd‚sordonn‚e. Contraire … la raison et … l''intellect.',
  'Incline … souffrir sentimentalement. Marque des d‚ceptions',
  'passionnelles et peut rendre esclave de l''amour. Masochisme.',
  'Les d‚sirs et l''action sont en d‚saccord. Le dynamisme se',
  'transforme en brutalit‚. Risques d''accident. Destructeur.',
  'Marque un grand besoin de jouissance mat‚rielle. Conduit … user',
  'd''exp‚dients plus ou moins l‚gaux. Pouvoir tyrannique.',
  'Pr‚sage la violence et le renoncement. Les int‚rˆts sont ‚go‹stes',
  'et les rages impuissantes. Incline … la vengeance.',
  'Pr‚dispos‚ aux maladresses et aux accidents. Les revirements sont',
  'brutaux et les accidents spectaculaires. Surhumain.',
  'Pr‚dispos‚ aux abus de pouvoir et tend … se complaire dans les',
  'machinations secrŠtes. Pr‚voir des bouleversements.',
  '~Dans un paysage robuste et ƒpre parsem‚ de pics arides',
  '~un chƒteau vigoureux repose sur un roc in‚branlable.',
  '~Id‚e de force et de puissance.',
  '~Un B‚lier d‚gage une impression d''‚nergie,',
  '~de volont‚ aveugle et de violence.',
  '~Un accŠs de colŠre farouche le fait foncer droit devant lui,',
  '~sans soucis des obstacles, au risque de se briser la tˆte.',
  '~Il ne craint pas les difficult‚s de la route,',
  '~car il les aborde de front.',
  '~Cet horoscope pr‚sage orgueil, coup de tˆte et imprudence.',
  '~Il montre peu d''imagination mais se montre trŠs r‚alisateur.',
  '~Il est favorable mat‚riellement.',
  '~La r‚ussite vient par le courage et l''activit‚.',
  '~L''image est masculine, chaude, du domaine de Mars.',
  '~D''une f‚minit‚ d‚licieuse et fiŠre,',
  '~andromede enchaŒn‚e sur son rocher,',
  '~h‚ro‹ne presque divine … la merci d''un monstre marin,',
  '~est prˆte … succomber.',
  '~Dans l''or du ciel apparaŒt sur un cheval aile,',
  '~le secours providentiel et inattendu.',
  '~C''est une volont‚ intelligente et courageuse',
  '~qui anime la bont‚ agissante',
  '~en apportant la d‚livrance et le triomphe compensateur.',
  '~Cet horoscope pr‚sage le triomphe aprŠs le sacrifice,',
  '~l''amiti‚, la bont‚ et le d‚vouement.',
  '~Il pr‚sage une protection au moment le plus critique.',
  '~Il donne le go–t de la d‚pens‚.',
  '~Il est l''indice d''un mariage difficile qui r‚ussira.',
  '~Sous son apparence lourde',
  '~la baleine est dou‚e d''une extrˆme mobilit‚,',
  '~dangereuse pour ce qui l''entour‚,',
  '~car d''un coup de queue brutal et inconscient,',
  '~elle submerge l''imprudent qui cherche … la capturer.',
  '~Ce mastodonte mobile repr‚sente le destin.',
  '~Cet horoscope laisse pr‚voir la catastrophe inattendue,',
  '~un danger de chute ou de blessure.',
  '~Il pr‚sage des alternatives de gains et de pertes.',
  '~Il est mobile et l''on ne peut guŠre se fier … lui.',
  '~Il peut amener la ruine au moment le plus impr‚visible.',
  '~L''infortune et la disgrƒce donnent le go–t du plaisir,',
  '~ainsi qu''une nature ‚go‹ste et ardente.',
  '~L''image est du domaine de V‚nus et de Saturne.',
  '~Arrˆte dans la plaine, paisible,',
  '~les sabots attach‚s … l''herbe tendre qu''il affectionne',
  '~et foule sans vergogne,',
  '~le mufle humide, les yeux ronds, les cornes au vent,',
  '~le col ‚norme, les ‚paules fortes, la queue en bataille,',
  '~le Taureau se tient vaniteux, violent, confiant, puissant,',
  '~peu sensible, tout d''instinct et de d‚sirs physiques.',
  '~Cet horoscope indique la concentration et la timidit‚.',
  '~Il a besoin d''un aiguillon pour agir.',
  '~Il est ƒpre au gain.',
  '~Peut favorable aux choses intellectuelles',
  '~il marque un mat‚rialisme outrancier, l''amour du bien-ˆtre,',
  '~et la possibilit‚ de l''acqu‚rir par le travail.',
  '~L''image est f‚minine, du domaine de V‚nus et de la terre.',
  '~M‚duse, une des trois gorgones,',
  '~repr‚sente la jalousie et la haine.',
  '~Sa chevelure, faite de vivants serpents,',
  '~coiffe un masque hideux et repoussant,',
  '~aux yeux p‚trifiant ce que son regard touche.',
  '~Cet horoscope pr‚sage un excŠs de confiance en soi',
  '~qui finit par vous enliser et fait commettre des fautes.',
  '~C''est la marche inconsciente en avant jusqu''au moment',
  '~ou l''on reste fig‚, incapable d''avancer ni de reculer.',
  '~Il repr‚sente la dualit‚, la rivalit‚ jalouse et m‚chante,',
  '~celle dont on triomphe si l''on est sage.',
  '~C''est la fˆte masqu‚e du vivant',
  '~au grand pouvoir de transformation.',
  '~On pr‚sume souvent de ses moyens et possibilit‚s.',
  '~Ce sont les sept filles d''atlas,',
  '~les sept ƒmes l‚gŠres et tenues qui s''envolent',
  '~vers les cieux constell‚s de points d''or pƒle,',
  '~quittant cette r‚alit‚ douloureuse',
  '~pour un monde plus ‚lev‚.',
  '~Cet horoscope indique une imagination excessive,',
  '~il marque les d‚sirs que l''on prend pour des r‚alit‚s.',
  '~Il pr‚sage l''instabilit‚ physique et intellectuelle,',
  '~la tendance au pessimisme, au chagrin et au tourment.',
  '~Les obstacles sont imaginaires',
  '~et les rˆveries de l''ƒme capables de concr‚tiser l''espoir.',
  '~Il signifie le d‚placement et le voyage favorable.',
  '~Il est charge de sensualisme artistique',
  '~qui fait aimer le bon et le beau.',
  '~Deux ch‚rubins sont harmonieusement unis.',
  '~Dans leur dualit‚ charmante',
  '~ils sourient et devisent de choses subtiles et d‚licates',
  '~en tenant la flŠche de l''ironie narquoise.',
  '~Ils manient la lyre vibrante des arts',
  '~et le bƒton de la science intelligente et sacr‚e.',
  '~Cet horoscope est sous le signe de l''intelligence subtile,',
  '~du bon go–t, des arts, de l''amour pour la musique,',
  '~de la r‚ussite dans les affaires.',
  '~Il pr‚sage peu de constance dans les affections.',
  '~Favorable au savoir-faire',
  '~et aux possibilit‚s de se sortir des mauvaises passes.',
  '~Il marque plus l''amiti‚ et l''affection que l''amour.',
  '~L''image est masculine et chaude, du domaine de Mercure.',
  '~Quelque chose d''humain dans l''expression ou se jouent',
  '~la concentration d''esprit, la pr‚occupation et la crainte,',
  '~avec un air d''intelligence triste et de puissance tˆtue.',
  '~Asmalthee, la chŠvre nourrice de Jupiter,',
  '~ne doit rien craindre du sort :',
  '~une corne d''abondance remplie de fruits d''or est … sa porte',
  '~eaura-t-elle l''audace de s''en saisir?',
  '~Cet horoscope pr‚sage l''inqui‚tude, le tourment imaginaire',
  '~et la crainte de mal faire.',
  '~Une trop grande propret‚ morale nuit … la r‚ussite,',
  '~pourtant le r‚sultat sera bon et le succŠs certain.',
  '~Mais il faut une protection car par lui-mˆme cet horoscope',
  '~ne donne que la timidit‚ et l''orgueil pour qu‚mander.',
  '~Pers‚v‚rance et entˆtement sont favorises.',
  '~A cote de sirius, le chien docile et fidŠle,',
  '~mollement allonge … ses pieds,',
  '~orion, magnifique chasseur … la plastique superbe,',
  '~aux traits fins et gracieux, … la chevelure solaire,',
  '~au regard magn‚tique et ensorceleur,',
  '~exprimant sa puissance faite d''intelligence et d''audace,',
  '~de r‚ussite tranquille et d''orgueil sain.',
  '~Il ne songe pas … la mort ni aux transformations futures,',
  '~tout a la joie de l''action pr‚sente',
  '~et … l''harmonie du moment.',
  '~Cet horoscope pr‚sage l''activit‚, la puissance et la beaut‚.',
  '~Il repr‚sente le chef d''entreprise … qui tout r‚ussit.',
  '~Ainsi que l''homme aux bonnes fortunes,',
  '~ami des fˆtes, des femmes, de la chasse et du confortable.',
  '~Une femme au visage r‚gulier,',
  '~aux cheveux abondants et clairs,',
  '~aux yeux gris-bleu pleins d''une po‚sie douce,',
  '~absorbante et dangereuse,',
  '~qui porte au rˆve, … la m‚lancolie et au spleen.',
  '~Elle tient dans ses mains un voile flou portant',
  '~le signe de l''‚crevisse, cancre marin mobile et changeant,',
  '~subsistant dans l''eau sans grands efforts physiques.',
  '~Cet horoscope est inconstant et parle de changements.',
  '~Il permet de r‚ussir sans gros efforts ni courage.',
  '~Il laisse entrevoir des choses myst‚rieuses et cach‚es.',
  '~Il indique souvent l''adultŠre et la langueur.',
  '~Il fait souvent prendre ses rˆves pour des r‚alit‚s.',
  '~L''image est f‚minine et froide, du domaine de la Lune.',
  '~Dans un ciel d''une harmonieuse puret‚,',
  '~montent soudain des flots bleus et diaprer,',
  '~d''‚pais nuages, signes pr‚curseurs de quelque tourmente.',
  '~Sur un roc, brusquement foudroy‚,',
  '~un bel et noble adolescent dans toute sa puissance succombe.',
  '~Cet horoscope laisse entrevoir la menace d''un accident,',
  '~d''une discorde ou d''une querelle.',
  '~Il laisse pr‚sager un brusque changement',
  '~dans le cours de l''existence,',
  '~accident ou incident venant troubler le cours de la vie.',
  '~Il est un facteur d''ins‚curit‚ et de discorde,',
  '~contraire aux voyages.',
  '~Il conseille le repli sur soi-mˆme et la m‚ditation.',
  '~L''image est du domaine de Saturne et de Neptune.',
  '~Flambeau au point, fendant l''‚paisseur des nuages,',
  '~il descend dans la nuit qu''il dissipe',
  '~de sa vigoureuse ardeur,',
  '~mettant en fuite les puissances troubles des t‚nŠbres.',
  '~Ami affectueux, il accourt loyal, vengeur et violent.',
  '~Cet horoscope est celui de l''amiti‚ et de l''appui',
  '~sur lequel on peut compter en toute circonstance.',
  '~Il apporte l''‚claircissement des choses t‚n‚breuses',
  '~et met la joie dans le coeur.',
  '~Il pr‚sage l''appui, la droiture, la franchise,',
  '~mais aussi la violence.',
  '~Il est favorable aux d‚placements,',
  '~aux prises de d‚cisions courageuses,',
  '~… faire la part du feu et sauver ce qui peut l''ˆtre.',
  '~Alors qu''au levant le Soleil flamboyant rougeoie,',
  '~la noble et altiŠre tˆte du roi des animaux,',
  '~fr‚missante de vie,',
  '~d''orgueilleuse beaut‚ et d''id‚ale vigueur',
  '~‚merge seule, indompt‚e, majestueuse et puissante.',
  '~Cet horoscope est cruel, puissant, mena‡ant et ambitieux.',
  '~Il est un atout pour aller de l''avant et arriver … ses fins.',
  '~Il donne le pouvoir et la richesse par des moyens violents.',
  '~Il fait aimer la table et les plaisirs,',
  '~et vient fortifier tout ce que l''on approche :',
  '~la sant‚, l''intelligence et les affaires.',
  '~Il fait aimer les plaisirs',
  '~permet de les connaŒtre et d''en abuser.',
  '~L''image est masculine et chaude, du domaine du Soleil.',
  '~FidŠle et rampant, l''oeil et l''oreille aux aguets,',
  '~le nez au vent, fureteur, prˆt aux salacites de sa race,',
  '~tenace dans ses d‚sirs, le chien c‚leste s''avance,',
  '~courbant le dos … la voix grondant du maŒtre,',
  '~capable cependant de le d‚fendre de sa force',
  '~et de son affection.',
  '~Cet horoscope donne la puissance, la force,',
  '~une grande bont‚ sous des dehors rustres.',
  '~Il apporte une curiosit‚ malsaine',
  '~faisant se mˆler des affaires des autres,',
  '~et dresser des piŠges qui ne r‚ussissent pas.',
  '~Indice de t‚nacit‚, il peut apporter la richesse.',
  '~Il est mat‚rialiste et peu capable de pens‚es id‚ales.',
  '~La puissance des app‚tits accroŒt la richesse.',
  '~Dans un cloaque immonde, pestilentiel et repoussant,',
  '~l''hydre vit ignoble, venimeuse, horrible et visqueuse,',
  '~avec ses tˆtes multiples et m‚chantes',
  '~sans cesse renaissantes.',
  '~Cet horoscope pr‚sage des difficult‚s sans nombre',
  '~pour le triomphe desquelles il faut de la pers‚v‚rance,',
  '~du courage et de l''esprit de suite',
  '~alli‚s … un labeur incessant.',
  '~Il faut changer d''air et se secouer,',
  '~ne pas se laisser aller … son temp‚rament, … ses manies.',
  '~La routine empˆche l''ascension.',
  '~Il faut agir pour triompher,',
  '~se d‚barrasser de la torpeur, sans h‚siter, d''un seul coup.',
  '~La fuite est avantageuse.',
  '~Un rameau de paix dans une main, et dans l''autre,',
  '~tenant l''hexagramme, symbole de l''‚quilibre parfait,',
  '~m‚lancolique et diaphane,',
  '~une jeune femme au regard triste, seule,',
  '~souffre en silence de la pens‚e des hommes',
  '~et se d‚fend de leurs faiblesses et turpitudes.',
  '~Cet horoscope est m‚lancolique, triste et solitaire,',
  '~‚quilibre et droit.',
  '~Il apporte l''‚claircissement et permet de raisonner juste',
  '~en donnant … tout ce qu''il approche',
  '~une grande propret‚ morale et de la pudeur.',
  '~Il apporte du "fini" dans les entreprises,',
  '~est facteur de perfectionnement et d''am‚lioration.',
  '~L''image est f‚minine et froide, du domaine de Mercure.',
  '~Porte par les flots tumultueux, d‚jouant les obstacles,',
  '~combattant, grƒce aux dieux, les ‚l‚ments d‚chaŒn‚s,',
  '~et le destin implacable, aprŠs mille difficult‚s,',
  '~le vaisseau arrive au port, ses flancs d‚chires,',
  '~ses mƒts brises,',
  '~mais encore capable de r‚sister aux assauts de la vague.',
  '~Cet horoscope est celui des entreprises difficiles',
  '~qui peuvent donner un r‚sultat heureux',
  '~aprŠs de nombreuses pertes ou des ‚preuves incroyables.',
  '~Il marque des discussions entre associ‚s, parents, amis',
  '~ou conjoints. Mais la rupture ne se produira pas.',
  '~La r‚ussite r‚sultera du courage et d''un appui puissant.',
  '~Peu favorable aux voyages qui pourraient ˆtre dangereux.',
  '~Il marque les d‚sillusions que le temps cicatrise.',
  '~Un profil spirituel d''une grande beaut‚',
  '~encadre de cheveux paillet‚s d''‚toiles,',
  '~un visage d''une adorable tendresse f‚minine,',
  '~adouci par l''or blond de l''irr‚elle chevelure,',
  '~offrant le baiser suprˆme de l''amour id‚al et charmeur.',
  '~Cet horoscope est favorable aux amours, … la chance,',
  '~aux affaires, mais le m‚rite personnel est faible,',
  '~n''entrant pas en jeu.',
  '~L''horoscope est tributaire de ce que la nature octroie.',
  '~Il pr‚sage l''amour heureux, un mariage riche et puissant.',
  '~Il est peu favorable aux enfants et parents proches.',
  '~Il fortifie les dons naturels de l''esprit et du corps.',
  '~Si l''horoscope n''est pas contrari‚ par le destin,',
  '~il pr‚sage la r‚alisation des projets sans heurts ni luttes.',
  '~Deux plateaux qui tendent … l''‚quilibre,',
  '~sont tenus par une main ferme',
  '~comme doit l''ˆtre celle de la justice',
  '~et du droit sincŠre et vrai.',
  '~Cet horoscope est celui de la justice et de l''‚quilibre',
  '~il est impr‚gn‚ de fid‚lit‚, de sinc‚rit‚,',
  '~pour donner une grande ‚galit‚ en toute chose.',
  '~Il repr‚sente la juste bont‚, l''imagination et l''art,',
  '~et donne l''intelligence … tout ce qu''il approche.',
  '~Dispose … l''optimisme et … la bonne humeur,',
  '~… la bienveillance et … l''indulgence sans lƒchet‚.',
  '~Il aide … faire ce que l''on doit',
  '~la providence faisant le reste.',
  '~L''image est masculine et chaude, du domaine de V‚nus.',
  '~Un vieux chercheur amoureux de la science',
  '~se penche sur quelque vieux grimoire parchemin‚',
  '~dont il veut extraire la sŠve et le suc bienfaisant',
  '~… l''aide des clefs de son savoir.',
  '~Dans sa chevelure en bataille',
  '~se fluidifient les fleurs de l''esprit',
  '~et les chimŠres de la spiritualit‚ triomphante.',
  '~Cet horoscope apporte la r‚ussite par l''intelligence',
  '~et la compr‚hension de tout ce qui touche au bonheur.',
  '~Il donne l''‚tincelle qui r‚chauffe et permet de se sortir',
  '~des choses les plus embrouill‚es de l''existence.',
  '~Il est le fil que l''on retrouve et qui permet de suivre',
  '~la route de la r‚ussite et la satisfaction des d‚sirs.',
  '~Il s''int‚ress‚ … l''inconnu et … la d‚couverte des mystŠres.',
  '~C''est l''‚pi blond des bl‚s dor‚s,',
  '~‚ternellement renaissant,',
  '~symbole des bienfaits de la f‚conde nature.',
  '~Un arbre vigoureux porteur de fruits d''or,',
  '~r‚compense le travail ‚quilibre de l''homme.',
  '~Cet horoscope pr‚sage l''abondance acquise par le travail',
  '~les efforts continus et le savoir-faire.',
  '~Il donne des possibilit‚s de r‚ussite … la campagne',
  '~et accorde le pouvoir et la domination.',
  '~Il laisse pr‚sager des soucis au sujet des enfants.',
  '~Il indique la fin d''une affaire',
  '~et le commencement d''une autre.',
  '~Permet de go–ter … tous les plaisirs de la vie',
  '~et de triompher des difficult‚s.',
  '~PrŠs d''une eau verdƒtre, un animal essentiellement terrestre',
  '~es''‚loign‚, sournois, prudent et l''air inoffensif,',
  '~luttant lentement et contournant les obstacles.',
  '~Il est … la recherche d''une victime qu''il attaquera',
  '~sans crainte, inopin‚ment, quelle que soit sa force,',
  '~sachant que sa petite taille lui permet de se dissimuler',
  '~facilement et sans risques.',
  '~La facilit‚ qu''il a de feindre est son arme.',
  '~Cet horoscope permet de r‚ussir par la ruse.',
  '~L''effort intellectuel permet d''atteindre les buts fixes.',
  '~Il tend … la raillerie et parfois … la fausse amiti‚.',
  '~Il est ambitieux et sait ce qu''il veut et peut obtenir,',
  '~le savoir faire et l''habilet‚ ‚tant favorises.',
  '~L''image est f‚minine et froide, du domaine de Pluton.',
  '~Un serpent, la tˆte rejoignant la queue,',
  '~ferme ainsi le cercle et forme le symbole sacre',
  '~de ce qui est sans fin ni commencement.',
  '~Mandata dont ne parlent que secrŠtement les initi‚s.',
  '~Cet horoscope permet continuellement de parfaire les oeuvre',
  '~set de ne jamais abandonner ce qui a ‚t‚ commence.',
  '~Il pr‚sage l''‚loquence et la prudence,',
  '~le mensonge et l''astuce.',
  '~Il est le recommencement d''une affaire ‚ternelle',
  '~il est porteur de sant‚ et d''auto-d‚fense.',
  '~Il symbolise la conservation et le renouvellement',
  '~de ce qui est essentiel … la survie.',
  '~Pr‚sage des alternatives de hauts et de bas,',
  '~mais permet toujours d''arriver … ses fins.',
  '~Sur la teinte argent‚e que projette une lune diaphane',
  '~se d‚tach‚ la silhouette svelte et muscl‚e d''un loup',
  '~qui attend de se jeter sur les ˆtres sans d‚fense',
  '~pour les attaquer avec f‚rocit‚,',
  '~ou de fuir avec lƒchet‚',
  '~si le moindre danger se pr‚sente.',
  '~Cet horoscope fait souvent entreprendre des travaux',
  '~au-dessus de ses forces.',
  '~Face aux contraintes des hommes et du destin,',
  '~il permet de fuir',
  '~ou d''user de moyens que la morale r‚prouve.',
  '~Il pr‚sage l''organisation,',
  '~l''attente et la m‚chancet‚.',
  '~Permet la tromperie et parfois le vol.',
  '~Un centaure … la tˆte douce et bonne,',
  '~intelligente et pacifique,',
  '~foule de ses sabots prudents la montagne,',
  '~afin d''y d‚couvrir et observer de son sommet les astres.',
  '~Il est arme d''une flŠche,',
  '~qu''adroitement il enverra … quelque''ˆtre malfaisant.',
  '~Cet horoscope laisse pr‚sager la paix et la qui‚tude,',
  '~le d‚sir de s''‚lever en ayant toutes les possibilit‚s',
  '~pour y parvenir par son adresse et sa prudence.',
  '~Il avantage l''intelligence et la f‚condit‚ des id‚es.',
  '~Avide de libert‚ et d''‚vasion,',
  '~il symbolise la noblesse, le courage et la virilit‚.',
  '~Il pr‚sage commandement et maŒtrise sur soi et les autres.',
  '~L''image est masculine et chaude, du domaine de Jupiter.',
  '~Un vigoureux colosse marque sa puissance et sa force',
  '~en ouvrant la gueule d''un lion.',
  '~Sa r‚sistance et sa t‚nacit‚ doivent ˆtre grandes',
  '~pour ‚viter la r‚action d''un ˆtre indompt‚.',
  '~Cet horoscope laisse pr‚sager la domination et le courage,',
  '~la force et la colŠre.',
  '~Il est de toute premiŠre valeur',
  '~et donne la r‚ussite par le travail et le m‚rite personnel.',
  '~Il peut apporter la gloire et la consid‚ration.',
  '~On est entour‚ d''ennemis dont il faut se d‚barrasser.',
  '~La violence pourrait ˆtre n‚cessaire … la r‚ussite.',
  '~L''horoscope pr‚sage la renomm‚e ou l''‚l‚vation.',
  '~Symbole de la lutte contre le destin contraire',
  '~permet d''imposer sa loi aprŠs le combat ou les difficult‚s.',
  '~Le fabuleux et mythique animal … la queue ophidienne,',
  '~aux ailes d‚moniaques, … la langue ignee,',
  '~aux griffes l‚onines,',
  '~est consacr‚ … minerve, d‚esse de la sagesse.',
  '~Ce dragon veille sans r‚pit, ignorant le repos,',
  '~sur le seuil dont il a la garde.',
  '~Cet horoscope pr‚sage la clairvoyance',
  '~et indique qu''il faut constamment se m‚fier,',
  '~ne pas s''endormir, la s‚curit‚ ‚tant un vain mot.',
  '~Il conseille de poursuivre les id‚es jusqu''au bout,',
  '~une affaire donnant des r‚sultats si l''on s''en occup‚',
  '~avec patience et vigilance, non qu''un p‚ril menace,',
  '~mais pour montrer sa capacit‚ de se d‚fendre.',
  '~Il conseille d''ˆtre attentif … l''entourage.',
  '~Une tˆte de bouc et un corps de chŠvre',
  '~termin‚ par une queue de poisson.',
  '~Le faciŠs, aux instincts inqui‚tants,',
  '~pr‚sente un rictus sardonique et amer',
  '~refl‚tant les pens‚es tristes et mauvaises de l''ƒme.',
  '~Cet horoscope entrevoit une grande tristesse peu raisonnable',
  '~epas toujours ‚quilibr‚e,',
  '~recherchant ou causant la discorde.',
  '~Il est capable de d‚truire ce que l''on approche :',
  '~la beaut‚ et la gaiet‚.',
  '~Il symbolise la dur‚e, la long‚vit‚ et la solitude,',
  '~les d‚sirs ne sont r‚alises que lentement.',
  '~Il est contraire … la paix de l''ƒme.',
  '~L''image est f‚minine et froide, du domaine de Saturne.',
  '~Un rapace aile veille du haut d''un roc inaccessible,',
  '~cherchant dans la plaine,',
  '~de son regard scrutateur et per‡ant,',
  '~une proie sans m‚fiance,',
  '~victime facile de son avidit‚ et de sa couardise.',
  '~Cet horoscope est celui de la perspicacit‚ et du coup d''oei',
  '~lil est parfois l''indice d''une influence mauvaise,',
  '~du tripotage dans les choses louches.',
  '~Il pr‚sage l''attaque ou l''on ne risque aucune d‚fense.',
  '~Il indique que le sort n''attend qu''un moment de faiblesse',
  '~pour agir dans le mauvais sens,',
  '~une n‚gligence pour tomber sur sa proie.',
  '~Il conseille de ne jamais abandonner,',
  '~de tenir co–te que co–te.',
  '~Planant solitaire sur les hauteurs inaccessibles,',
  '~l''aigle, comme la foudre,',
  '~fond brusquement sur l''ˆtre marque par le destin.',
  '~Il s''acharne jusqu''… la mort.',
  '~Il ne fait ni grƒce, ni quartier',
  '~conscient de sa force et de son invuln‚rabilit‚.',
  '~Cet horoscope pr‚sage l''orgueilleuse solitude,',
  '~la force, l''ind‚pendance et la hardiesse,',
  '~la fid‚lit‚ pour ceux que l''on aime.',
  '~Indice de danger ou d''accident dans les voyages.',
  '~Il accorde le courage et fait manquer de cl‚mence.',
  '~Il empˆche souvent de discerner l''ami de l''ennemi,',
  '~et d‚note l''esprit ‚troit et le parti-pris.',
  '~Il manque de souplesse intellectuelle.',
  '~Une conque marine, isol‚e du monde,',
  '~aux volutes gracieuses et ‚quilibr‚es,',
  '~d‚verse une eau limpide et fraŒche portant partout',
  '~la bienfaisante vertu de son irritante et f‚conde action,',
  '~dont les hommes abuseront peut ˆtre',
  '~pour des buts ‚go‹stes et vils.',
  '~Cet horoscope est sous le signe de la bont‚, de la fid‚lit‚,',
  '~de la raison et de l''honnˆtet‚.',
  '~Ces qualit‚s font que l''on peut-ˆtre trompe ou bafou‚.',
  '~Il pr‚sage la solitude et les d‚penses,',
  '~la recherche de l''harmonie et de la g‚n‚rosit‚.',
  '~Il donne une id‚e juste et ‚lev‚e de la vie,',
  '~et conseille l''indulgence et la compr‚hension.',
  '~L''image est masculine et chaude, du domaine d''Uranus.',
  '~Un mammifŠre aquatique, immortalis‚ par la sculpture,',
  '~le corps souple, gliss‚ doucereux sur l''onde amŠre,',
  '~le regard de c“t‚.',
  '~Il est un danger car il trompe par son attitude hypocrite.',
  '~Cet horoscope symbolise la duplicit‚',
  '~qui endort avec de belles histoires.',
  '~Il repr‚sente une personne doucereuse qui fait bonne figure',
  '~et qui commet m‚chancet‚s et m‚disances',
  '~sans s''inqui‚ter outre mesure.',
  '~Il pr‚sage un artiste qui leurre par une belle musique',
  '~et incline … prendre ses d‚sirs pour des r‚alit‚s,',
  '~… pr‚f‚rer les beaux mensonges aux r‚alit‚s d‚plaisantes.',
  '~Une personne connaŒt vos desseins et faiblesses',
  '~et se fait une arme de ses charmes.',
  '~Pegase, ce pur coursier aile, piaffant et renƒclant,',
  '~plein d''une id‚ale ardeur,',
  '~est prˆt … s''envoler vers le s‚jour des immortels,',
  '~offrant ses reins, sa fougue et sa puissance',
  '~aux sages qui ont des luttes sacr‚es et utiles … soutenir.',
  '~Cet horoscope donne le sentiment du beau et du noble.',
  '~Il marque l''imagination, la rˆverie,',
  '~ainsi qu''un besoin de connaŒtre et de savoir,',
  '~d''apprendre constamment du nouveau.',
  '~Il pr‚sage la protection et la sauvegarde',
  '~si le besoin se fait sentir.',
  '~Il met l''imagination au service de la cr‚ation',
  '~et aide … prendre ses responsabilit‚s.',
  '~Il est un facteur de r‚ussite dans la voie suivie.',
  '~Sur un champ d''eau glauque et sombre,',
  '~deux Poissons souples semblent se faire des confidences.',
  '~Leurs paroles sont troubles',
  '~comme l''‚l‚ment dans lequel ils vivent.',
  '~Cet horoscope laisse pr‚sager la tromperie,',
  '~la mauvaise foi et la m‚disance,',
  '~ainsi que beaucoup d''audace pour mal faire.',
  '~Il indique le plaisir de nuire pour faire le mal.',
  '~Il laisse pourtant entrevoir le moyen de d‚couvrir',
  '~et de r‚soudre une situation trouble et cach‚e',
  '~par le biais de la confidence.',
  '~Il expose … la nuisance des hommes et des ‚v‚nements',
  '~et incline … l''‚go‹sme et … la nonchalance.',
  '~L''image est f‚minine et froide, du domaine de Neptune.',
  '~L''oeil trompeur et la d‚marche ondoyante,',
  '~le cygne majestueux s''avance nonchalamment',
  '~vers l''objet de son d‚sir amoureux et passager',
  '~qui ne durera guŠre plus longtemps que la trace',
  '~laiss‚e par son sillage dans le lac qu''il traverse.',
  '~Cet horoscope pr‚sage un manque de stabilit‚,',
  '~le vagabondage au sujet des amours.',
  '~Il marque la duplicit‚ et fait aimer pour l''argent.',
  '~Il annonce la vitalit‚ dans la maladie',
  '~et permet de remonter les mauvais courants.',
  '~Il annonce des choses plaisantes et de courte dur‚e.',
  '~Il fait aimer la vie et les plaisirs',
  '~et les octroie sans grands efforts.',
  '~Il est un facteur de vitalit‚ et de long‚vit‚.',
  '~Une forme d''apparence inerte et puissante,',
  '~un fleuve sortant lentement mais s–rement de son lit,',
  '~renverse tout sur son passage.',
  '~Rien ne peut l''arrˆter avant que le temps ne soit venu,',
  '~une p‚riode de repos devant apparaŒtre aprŠs l''inondation,',
  '~calme et naturelle.',
  '~Cet horoscope pr‚sage la confiance en soi,',
  '~l''inertie, le destin bon ou mauvais,',
  '~force implacable contre laquelle on ne peut rien.',
  '~Il conseille d''attendre et de laisser agir les ‚v‚nements.',
  '~Le temps sera le meilleur atout dans les entreprises.',
  '~Il indique la continuation dans l''effort,',
  '~et la r‚signation dans la souffrance.',
  '~C''est un symbole de fatalit‚ bon ou mauvais.'
 );
 BLK : Array[1..NBLK+1] Of Integer = (
  1,4,7,10,13,16,19,22,25,28,
  31,34,37,40,43,46,49,52,55,58,
  61,64,67,70,73,76,79,82,85,88,
  91,94,97,100,103,106,109,112,115,118,
  121,124,127,130,133,136,139,142,145,148,
  151,154,157,160,163,166,169,172,175,178,
  181,184,187,190,193,196,199,202,205,208,
  211,214,217,220,223,226,229,232,235,238,
  241,244,247,250,253,256,259,262,265,268,
  271,274,277,280,283,286,289,292,295,298,
  301,304,307,310,313,316,319,322,325,328,
  331,334,337,340,343,346,349,352,355,358,
  361,364,367,370,373,376,379,382,385,388,
  391,394,397,400,403,406,409,412,415,418,
  421,424,427,430,433,436,439,442,445,448,
  451,454,457,460,463,466,469,472,475,478,
  481,484,487,490,493,496,499,502,505,508,
  511,514,517,520,523,526,529,532,535,538,
  541,544,547,550,553,556,559,562,565,568,
  571,574,577,580,583,586,589,592,595,598,
  601,604,607,610,613,616,619,622,625,628,
  631,634,637,640,643,646,649,652,655,658,
  661,664,667,670,673,676,679,682,685,688,
  691,694,697,700,703,706,709,712,715,718,
  721,724,727,730,733,736,739,742,745,748,
  751,754,757,760,763,766,769,772,775,778,
  781,784,787,790,793,796,799,802,805,808,
  811,814,817,820,823,826,829,832,835,838,
  841,844,847,850,853,856,859,862,865,868,
  871,874,877,880,883,886,889,892,895,898,
  901,904,907,910,913,916,919,922,925,928,
  931,934,937,940,943,946,949,952,955,958,
  961,964,967,970,973,976,979,982,985,988,
  991,994,997,1000,1003,1006,1009,1012,1015,1018,
  1021,1024,1027,1030,1033,1036,1039,1042,1045,1048,
  1051,1054,1057,1060,1063,1066,1069,1072,1075,1078,
  1081,1084,1087,1090,1093,1096,1099,1102,1105,1108,
  1111,1114,1117,1120,1123,1126,1129,1132,1135,1138,
  1141,1144,1147,1150,1153,1156,1159,1162,1165,1168,
  1171,1174,1177,1180,1183,1186,1189,1192,1195,1198,
  1201,1204,1207,1210,1213,1216,1219,1222,1225,1228,
  1231,1234,1237,1240,1243,1246,1249,1252,1255,1258,
  1261,1264,1267,1270,1273,1276,1279,1282,1285,1288,
  1291,1294,1297,1300,1303,1306,1309,1312,1315,1318,
  1321,1324,1327,1330,1333,1336,1339,1342,1345,1348,
  1351,1354,1357,1360,1363,1366,1369,1372,1375,1378,
  1381,1384,1387,1390,1393,1396,1399,1402,1405,1408,
  1411,1414,1417,1420,1423,1426,1429,1432,1435,1438,
  1441,1452,1463,1474,1485,1496,1508,1519,1531,1542,
  1554,1565,1576,1587,1599,1610,1621,1632,1643,1654,
  1666,1677,1688,1691,1694,1697,1700,1703,1706,1709,
  1712,1715,1718,1721,1724,1727,1730,1733,1736,1739,
  1742,1745,1748,1751,1754,1757,1760,1763,1766,1769,
  1772,1775,1778,1781,1784,1787,1790,1793,1796,1799,
  1802,1805,1808,1811,1814,1817,1820,1823,1826,1829,
  1832,1835,1838,1841,1844,1847,1850,1853,1856,1859,
  1862,1865,1868,1871,1874,1877,1880,1883,1886,1889,
  1892,1895,1898,1901,1904,1907,1910,1913,1916,1919,
  1922,1925,1928,1931,1934,1937,1940,1943,1946,1949,
  1952,1955,1958,1961,1964,1967,1970,1973,1976,1979,
  1982,1985,1988,1991,1994,1997,2000,2003,2006,2009,
  2012,2015,2018,2021,2024,2027,2030,2033,2036,2039,
  2042,2045,2048,2051,2054,2057,2060,2063,2066,2069,
  2072,2075,2078,2081,2084,2087,2090,2093,2096,2099,
  2102,2105,2108,2111,2114,2117,2120,2123,2126,2129,
  2132,2135,2138,2141,2144,2147,2150,2153,2156,2159,
  2162,2165,2168,2171,2174,2177,2180,2183,2186,2189,
  2192,2195,2198,2201,2204,2207,2210,2213,2216,2219,
  2222,2225,2228,2231,2234,2237,2240,2243,2246,2249,
  2252,2255,2258,2261,2264,2267,2270,2273,2276,2279,
  2282,2285,2288,2291,2294,2297,2300,2303,2306,2309,
  2312,2315,2318,2321,2324,2327,2330,2333,2336,2339,
  2342,2345,2348,2351,2354,2357,2360,2363,2366,2369,
  2372,2375,2378,2381,2384,2387,2390,2393,2396,2399,
  2402,2405,2408,2411,2414,2417,2420,2423,2426,2429,
  2432,2435,2438,2441,2444,2447,2450,2453,2456,2459,
  2462,2465,2468,2471,2474,2477,2480,2483,2486,2489,
  2492,2495,2498,2501,2504,2507,2510,2513,2516,2519,
  2522,2525,2528,2531,2534,2537,2540,2543,2546,2549,
  2552,2555,2558,2561,2564,2567,2570,2573,2576,2579,
  2582,2585,2588,2591,2594,2597,2600,2603,2606,2609,
  2612,2615,2618,2621,2624,2627,2630,2633,2636,2639,
  2642,2645,2648,2651,2654,2657,2660,2663,2666,2669,
  2672,2675,2678,2681,2684,2687,2690,2693,2696,2699,
  2702,2705,2708,2711,2714,2717,2720,2723,2726,2729,
  2732,2735,2738,2741,2744,2747,2750,2753,2756,2759,
  2762,2765,2768,2771,2774,2777,2780,2783,2786,2789,
  2792,2795,2798,2801,2804,2807,2810,2813,2816,2819,
  2822,2825,2828,2831,2834,2837,2840,2843,2846,2849,
  2852,2855,2858,2861,2864,2867,2870,2873,2876,2879,
  2882,2885,2888,2891,2894,2897,2900,2903,2906,2909,
  2912,2915,2918,2921,2924,2927,2930,2933,2936,2939,
  2942,2945,2948,2951,2954,2957,2960,2963,2966,2969,
  2972,2975,2978,2981,2984,2986,2988,2990,2992,2994,
  2996,2998,3000,3002,3004,3006,3008,3010,3012,3014,
  3016,3018,3020,3022,3024,3026,3028,3030,3032,3034,
  3036,3038,3040,3042,3044,3046,3048,3050,3052,3054,
  3056,3058,3060,3062,3064,3066,3068,3070,3072,3074,
  3076,3078,3080,3082,3084,3086,3088,3090,3092,3094,
  3096,3098,3100,3102,3104,3106,3108,3110,3112,3114,
  3116,3118,3120,3122,3124,3126,3128,3130,3132,3134,
  3136,3138,3140,3142,3144,3146,3148,3150,3152,3154,
  3156,3158,3160,3162,3164,3166,3168,3170,3172,3174,
  3176,3178,3180,3182,3184,3186,3188,3190,3192,3194,
  3196,3198,3200,3202,3204,3206,3208,3210,3212,3214,
  3216,3218,3220,3222,3224,3226,3228,3230,3232,3234,
  3236,3238,3240,3242,3244,3246,3248,3250,3252,3254,
  3256,3258,3260,3262,3264,3266,3268,3270,3272,3274,
  3276,3278,3280,3282,3284,3286,3288,3290,3292,3294,
  3296,3298,3300,3302,3304,3306,3308,3310,3312,3314,
  3316,3318,3320,3322,3324,3326,3328,3330,3333,3335,
  3337,3339,3341,3343,3345,3347,3349,3351,3353,3355,
  3357,3359,3361,3363,3365,3367,3369,3371,3373,3375,
  3377,3379,3381,3383,3385,3387,3389,3391,3393,3395,
  3397,3399,3401,3403,3405,3407,3409,3411,3413,3415,
  3417,3419,3421,3423,3425,3427,3429,3431,3433,3435,
  3437,3439,3441,3443,3445,3447,3449,3451,3453,3455,
  3457,3459,3461,3463,3465,3467,3469,3471,3473,3475,
  3477,3479,3481,3483,3485,3487,3489,3491,3493,3495,
  3497,3499,3501,3503,3505,3507,3509,3511,3513,3515,
  3517,3519,3521,3523,3525,3527,3529,3531,3533,3535,
  3537,3539,3541,3543,3545,3547,3549,3551,3553,3555,
  3557,3559,3561,3563,3565,3567,3569,3571,3573,3575,
  3577,3579,3581,3583,3585,3587,3589,3591,3593,3595,
  3597,3599,3601,3603,3605,3607,3609,3611,3613,3615,
  3617,3619,3621,3623,3625,3627,3629,3631,3633,3635,
  3637,3639,3641,3643,3645,3647,3649,3651,3653,3655,
  3657,3659,3661,3663,3665,3667,3669,3671,3673,3675,
  3677,3679,3681,3683,3685,3687,3689,3691,3693,3695,
  3697,3699,3701,3703,3705,3707,3709,3711,3713,3715,
  3717,3719,3721,3723,3725,3727,3729,3731,3733,3735,
  3737,3739,3741,3743,3745,3747,3749,3751,3754,3756,
  3758,3760,3762,3764,3766,3768,3770,3772,3774,3776,
  3778,3780,3782,3784,3786,3788,3790,3792,3794,3796,
  3798,3800,3802,3804,3806,3808,3810,3812,3814,3816,
  3818,3820,3822,3824,3826,3828,3830,3832,3834,3836,
  3838,3840,3842,3844,3846,3848,3850,3852,3854,3856,
  3858,3860,3862,3864,3866,3868,3870,3872,3874,3876,
  3878,3880,3882,3884,3886,3888,3890,3892,3894,3896,
  3898,3900,3902,3904,3906,3908,3910,3912,3914,3916,
  3918,3920,3922,3924,3926,3928,3930,3932,3934,3936,
  3938,3940,3942,3944,3946,3948,3950,3952,3954,3956,
  3958,3960,3962,3964,3966,3968,3970,3972,3974,3976,
  3978,3980,3982,3984,3986,3988,3990,3992,3994,3996,
  3998,4000,4002,4004,4006,4008,4010,4012,4014,4016,
  4018,4020,4022,4024,4026,4028,4030,4032,4034,4036,
  4038,4040,4042,4044,4046,4048,4050,4052,4054,4056,
  4058,4060,4062,4064,4066,4068,4070,4072,4074,4076,
  4078,4080,4082,4084,4086,4088,4090,4092,4094,4096,
  4098,4100,4102,4104,4106,4108,4110,4112,4114,4116,
  4118,4120,4122,4124,4126,4128,4130,4132,4134,4136,
  4138,4140,4142,4144,4146,4148,4150,4152,4154,4156,
  4158,4160,4162,4164,4166,4168,4170,4172,4174,4176,
  4178,4180,4182,4184,4186,4188,4190,4192,4194,4196,
  4198,4200,4202,4204,4206,4208,4210,4212,4214,4216,
  4218,4220,4222,4224,4226,4228,4230,4232,4234,4236,
  4238,4240,4242,4244,4246,4260,4274,4288,4302,4316,
  4330,4344,4358,4372,4386,4400,4414,4428,4442,4456,
  4470,4484,4498,4512,4526,4540,4554,4568,4582,4596,
  4610,4624,4638,4652,4666,4680,4694,4708,4722,4736,
  4750
 );
 MOT : Array[1..166, 0..4] Of String[20] = (
  ('Exister','Exist','Existieren','Existir','Esistere'),
  ('Appartenir','Belong','Dazugeh”ren','Pertenecer','Appartenere'),
  ('Penser','Think','Denken','Pensar','Pensare'),
  ('Aimer','Love','Lieben','Amar','Amare'),
  ('Agir','Act','Handeln','Actuar','Agire'),
  ('AccroŒtre','Increase','Vermehren','Acrecentar','Accrescere'),
  ('S‚parer','Separate','Trennen','Separar','Separare'),
  ('Transformer','Transform','Verwandeln','Transformar','Trasformare'),
  ('Imaginer','Imagine','Vorstellen','Imaginar','Immaginare'),
  ('Manipuler','Manipulate','Lenken','Manipular','Manipolare'),
  ('','','','',''),
  ('','','','',''),
  ('La personnalit‚','Personality','Pers”nlichkeit','La personalidad',
   'La personalit…'),
  ('Le mat‚riel','Material goods','Besitz','Lo material','I beni materiali'),
  ('Les proches','Relatives','Nahestehende','Los allegados','I parenti'),
  ('Le foyer','Home','Heim','El hogar','La casa'),
  ('L''amour','Love','Liebe','El amor','L''amore'),
  ('Le travail','Work','Arbeit','El trabajo','Il lavoro'),
  ('Les associations','Partnerships','Partnerschaften','Las asociaciones',
   'Le associazioni'),
  ('L''immat‚riel','The immaterial','Das Immaterielle','Lo inmaterial',
   'L''immateriale'),
  ('Les voyages','Travels','Reisen','Los viajes','I viaggi'),
  ('Le devenir','The future','Werdegang','El porvenir','Il divenire'),
  ('Les amis','Friends','Freunde','Los amigos','Gli amici'),
  ('Les ‚preuves','Trials','Prfungen','Las pruebas','Le prove'),
  ('Ardeur','Ardour','Eifer','Ardor','Ardore'),
  ('Passion','Passion','Leidenschaft','Pasi¢n','Passione'),
  ('Inspiration','Inspiration','Eingebung','Inspiraci¢n','Ispirazione'),
  ('Obstination','Obstinacy','Starrsinn','Obstinaci¢n','Ostinazione'),
  ('Enthousiasme','Enthusiasm','Begeisterung','Entusiasmo','Entusiasmo'),
  ('Impulsion','Impulse','Antrieb','Impulso','Impulso'),
  ('Puissance','Power','Kraft','Poder','Potenza'),
  ('Promptitude','Promptness','Schnelligkeit','Prontitud','Prontezza'),
  ('gocentrisme','Egocentrism','Ichbezogenheit','Egocentrismo',
   'Egocentrismo'),
  ('Vivacit‚','Liveliness','Lebhaftigkeit','Vivacidad','Vivacit…'),
  ('Art','Art','Kunst','Arte','Arte'),
  ('rotisme','Eroticism','Erotik','Erotismo','Erotismo'),
  ('Jouissance','Enjoyment','Genuss','Goce','Godimento'),
  ('Mat‚rialit‚','Materiality','Stofflichkeit','Materialidad','Materialit…'),
  ('Fid‚lit‚','Fidelity','Treue','Fidelidad','Fedelt…'),
  ('Richesse','Wealth','Reichtum','Riqueza','Ricchezza'),
  ('Perception','Perception','Wahrnehmung','Percepci¢n','Percezione'),
  ('Sensualit‚','Sensuality','Sinnlichkeit','Sensualidad','Sensualit…'),
  ('Excitation','Excitement','Erregung','Excitaci¢n','Eccitazione'),
  ('Avarice','Avarice','Geiz','Avaricia','Avarizia'),
  ('Flirt','Flirting','Flirt','Coqueteo','Flirt'),
  ('H‚sitation','Hesitation','Z”gern','Vacilaci¢n','Esitazione'),
  ('Complaisance','Complaisance','Gef„lligkeit','Complacencia','Compiacenza'),
  ('Intuition','Intuition','Intuition','Intuici¢n','Intuizione'),
  ('Imagination','Imagination','Fantasie','Imaginaci¢n','Immaginazione'),
  ('Bavardage','Chatter','Geschw„tz','Charla','Chiacchiera'),
  ('Amertume','Bitterness','Bitterkeit','Amargura','Amarezza'),
  ('Impatience','Impatience','Ungeduld','Impaciencia','Impazienza'),
  ('Raison','Reason','Vernunft','Raz¢n','Ragione'),
  ('Jeunesse','Youth','Jugend','Juventud','Giovinezza'),
  ('Maternit‚','Motherhood','Mutterschaft','Maternidad','Maternit…'),
  ('Protection','Protection','Schutz','Protecci¢n','Protezione'),
  ('Harmonie','Harmony','Harmonie','Armon¡a','Armonia'),
  ('Nutrition','Nourishment','Ern„hrung','Nutrici¢n','Nutrizione'),
  ('M‚moire','Memory','Ged„chtnis','Memoria','Memoria'),
  ('Pr‚monition','Premonition','Vorahnung','Premonici¢n','Premonizione'),
  ('Rancune','Resentment','Groll','Rencor','Rancore'),
  ('Honorabilit‚','Respectability','Ehrbarkeit','Honorabilidad','Onorabilit…'),
  ('D‚n‚gation','Denial','Leugnung','Negaci¢n','Diniego'),
  ('Rˆve','Dream','Traum','Sue¤o','Sogno'),
  ('Dignit‚','Dignity','Wrde','Dignidad','Dignit…'),
  ('Organisation','Organisation','Organisation','Organizaci¢n',
   'Organizzazione'),
  ('G‚n‚rosit‚','Generosity','Groázgigkeit','Generosidad','Generosit…'),
  ('Luxe','Luxury','Luxus','Lujo','Lusso'),
  ('Responsabilit‚','Responsibility','Verantwortung','Responsabilidad',
   'Responsabilit…'),
  ('Optimisme','Optimism','Optimismus','Optimismo','Ottimismo'),
  ('Exag‚ration','Exaggeration','šbertreibung','Exageraci¢n','Esagerazione'),
  ('Autorit‚','Authority','Autorit„t','Autoridad','Autorit…'),
  ('R‚g‚n‚ration','Regeneration','Erneuerung','Regeneraci¢n','Rigenerazione'),
  ('Amabilit‚','Kindness','Liebenswrdigkeit','Amabilidad','Amabilit…'),
  ('Modestie','Modesty','Bescheidenheit','Modestia','Modestia'),
  ('M‚thode','Method','Methode','M‚todo','Metodo'),
  ('Critique','Criticism','Kritik','Cr¡tica','Critica'),
  ('Savoir','Knowledge','Wissen','Saber','Sapere'),
  ('Recherche','Research','Forschung','Investigaci¢n','Ricerca'),
  ('go‹sme','Selfishness','Selbstsucht','Ego¡smo','Egoismo'),
  ('Rigueur','Rigour','Strenge','Rigor','Rigore'),
  ('Habilet‚','Skill','Geschick','Habilidad','Abilit…'),
  ('Analyse','Analysis','Analyse','An lisis','Analisi'),
  ('Chastet‚','Chastity','Keuschheit','Castidad','Castit…'),
  ('Id‚alisme','Idealism','Idealismus','Idealismo','Idealismo'),
  ('Volupt‚','Voluptuousness','Wollust','Voluptuosidad','Volutt…'),
  ('Ajustement','Adjustment','Ausgleich','Ajuste','Adattamento'),
  ('Sociabilit‚','Sociability','Geselligkeit','Sociabilidad','Socievolezza'),
  ('Tol‚rance','Tolerance','Toleranz','Tolerancia','Tolleranza'),
  ('Diplomatie','Diplomacy','Diplomatie','Diplomacia','Diplomazia'),
  ('S‚duction','Seduction','Verfhrung','Seducci¢n','Seduzione'),
  ('motion','Emotion','Gefhl','Emoci¢n','Emozione'),
  ('Justice','Justice','Gerechtigkeit','Justicia','Giustizia'),
  ('Maturit‚','Maturity','Reife','Madurez','Maturit…'),
  ('Volont‚','Will','Wille','Voluntad','Volont…'),
  ('Doute','Doubt','Zweifel','Duda','Dubbio'),
  ('Possession','Possession','Besitz','Posesi¢n','Possesso'),
  ('Explosivit‚','Explosiveness','Sprengkraft','Explosividad','Esplosivit…'),
  ('D‚tachement','Detachment','Losl”sung','Desapego','Distacco'),
  ('Pratique','Practicality','Praxis','Pr ctica','Praticit…'),
  ('Subtilit‚','Subtlety','Feinheit','Sutileza','Sottigliezza'),
  ('Sexualit‚','Sexuality','Sexualit„t','Sexualidad','Sessualit…'),
  ('T‚nacit‚','Tenacity','Z„higkeit','Tenacidad','Tenacia'),
  ('Ambition','Ambition','Ehrgeiz','Ambici¢n','Ambizione'),
  ('Aventure','Adventure','Abenteuer','Aventura','Avventura'),
  ('D‚votion','Devotion','Hingabe','Devoci¢n','Devozione'),
  ('Inaccessibilit‚','Aloofness','Unnahbarkeit','Inaccesibilidad',
   'Inaccessibilit…'),
  ('Libert‚','Freedom','Freiheit','Libertad','Libert…'),
  ('Noblesse','Nobility','Adel','Nobleza','Nobilt…'),
  ('Souhait','Wish','Wunsch','Deseo','Desiderio'),
  ('Franchise','Frankness','Offenheit','Franqueza','Franchezza'),
  ('Aspiration','Aspiration','Streben','Aspiraci¢n','Aspirazione'),
  ('Religion','Religion','Religion','Religi¢n','Religione'),
  ('Enseignement','Teaching','Lehre','Ense¤anza','Insegnamento'),
  ('Inflexibilit‚','Inflexibility','Unbeugsamkeit','Inflexibilidad',
   'Inflessibilit…'),
  ('Absolu','The absolute','Das Absolute','Absoluto','Assoluto'),
  ('Politique','Politics','Politik','Pol¡tica','Politica'),
  ('R‚alisme','Realism','Realismus','Realismo','Realismo'),
  ('M‚ditation','Meditation','Besinnung','Meditaci¢n','Meditazione'),
  ('Concentration','Concentration','Sammlung','Concentraci¢n',
   'Concentrazione'),
  ('Responsabilit‚','Responsibility','Verantwortung','Responsabilidad',
   'Responsabilit…'),
  ('Patience','Patience','Geduld','Paciencia','Pazienza'),
  ('Timidit‚','Shyness','Schchternheit','Timidez','Timidezza'),
  ('Concret','The concrete','Das Konkrete','Lo concreto','Il concreto'),
  ('Invention','Invention','Erfindung','Invenci¢n','Invenzione'),
  ('Proph‚tie','Prophecy','Prophezeiung','Profec¡a','Profezia'),
  ('Stabilit‚','Stability','Best„ndigkeit','Estabilidad','Stabilit…'),
  ('Planification','Planning','Planung','Planificaci¢n','Pianificazione'),
  ('ProgrŠs','Progress','Fortschritt','Progreso','Progresso'),
  ('Popularit‚','Popularity','Beliebtheit','Popularidad','Popolarit…'),
  ('Utopie','Utopia','Utopie','Utop¡a','Utopia'),
  ('Fraternit‚','Brotherhood','Brderlichkeit','Fraternidad','Fraternit…'),
  ('Lib‚ralisme','Liberalism','Freisinn','Liberalismo','Liberalismo'),
  ('Ind‚pendance','Independence','Unabh„ngigkeit','Independencia',
   'Indipendenza'),
  ('Crainte','Fear','Furcht','Temor','Timore'),
  ('Scepticisme','Scepticism','Skepsis','Escepticismo','Scetticismo'),
  ('Occulte','The occult','Das Okkulte','Lo oculto','L''occulto'),
  ('Po‚sie','Poetry','Poesie','Poes¡a','Poesia'),
  ('Confort','Comfort','Bequemlichkeit','Comodidad','Comodit…'),
  ('Vuln‚rabilit‚','Vulnerability','Verletzlichkeit','Vulnerabilidad',
   'Vulnerabilit…'),
  ('Influence','Influence','Einfluss','Influencia','Influenza'),
  ('M‚diumnit‚','Mediumship','Medialit„t','Mediumnidad','Medianit…'),
  ('Charit‚','Charity','N„chstenliebe','Caridad','Carit…'),
  ('Universalit‚','Universality','Universalit„t','Universalidad',
   'Universalit…'),
  ('L''‚nergie','Energy','Energie','La energ¡a','L''energia'),
  ('La possession','Possession','Besitz','La posesi¢n','Il possesso'),
  ('La communication','Communication','Kommunikation','La comunicaci¢n',
   'La comunicazione'),
  ('Le d‚vouement','Devotion','Hingabe','La entrega','La dedizione'),
  ('Le rayonnement','Radiance','Ausstrahlung','El resplandor','Lo splendore'),
  ('L''analyse','Analysis','Analyse','El an lisis','L''analisi'),
  ('Les autres','Others','Die anderen','Los dem s','Gli altri'),
  ('Le d‚sir','Desire','Begierde','El deseo','Il desiderio'),
  ('L''expansion','Expansion','Ausdehnung','La expansi¢n','L''espansione'),
  ('La maŒtrise','Mastery','Beherrschung','El dominio','La padronanza'),
  ('La connaissance','Knowledge','Erkenntnis','El conocimiento',
   'La conoscenza'),
  ('La sensibilit‚','Sensitivity','Empfindsamkeit','La sensibilidad',
   'La sensibilit…'),
  ('L''ext‚riorisation','Outwardness','Entfaltung','La exteriorizaci¢n',
   'L''esteriorizzazione'),
  ('La bont‚','Kindness','Gte','La bondad','La bont…'),
  ('L''intelligence','Intelligence','Intelligenz','La inteligencia',
   'L''intelligenza'),
  ('L''amour','Love','Liebe','El amor','L''amore'),
  ('Le tonus','Vigour','Spannkraft','El vigor','Il tono'),
  ('La chance','Luck','Glck','La suerte','La fortuna'),
  ('La r‚sistance','Endurance','Ausdauer','La resistencia','La resistenza'),
  ('La g‚nialit‚','Genius','Genialit„t','La genialidad','La genialit…'),
  ('La ferveur','Fervour','Inbrunst','El fervor','Il fervore'),
  ('La profondeur','Depth','Tiefe','La profundidad','La profondit…')
 );
 PLN : Array[0..4, 1..12] Of String[14] = (
  ('Soleil','Lune','Mercure','V‚nus','Mars','Jupiter','Saturne','Uranus',
   'Neptune','Pluton','Ascendant','Milieu du ciel'),
  ('Sun','Moon','Mercury','Venus','Mars','Jupiter','Saturn','Uranus',
   'Neptune','Pluto','Ascendant','Midheaven'),
  ('Sonne','Mond','Merkur','Venus','Mars','Jupiter','Saturn','Uranus',
   'Neptun','Pluto','Aszendent','Himmelsmitte'),
  ('Sol','Luna','Mercurio','Venus','Marte','J£piter','Saturno','Urano',
   'Neptuno','Plut¢n','Ascendente','Medio cielo'),
  ('Sole','Luna','Mercurio','Venere','Marte','Giove','Saturno','Urano',
   'Nettuno','Plutone','Ascendente','Medio cielo')
 );
 SGN : Array[0..4, 1..12] Of String[12] = (
  ('B‚lier','Taureau','G‚meaux','Cancer','Lion','Vierge','Balance','Scorpion',
   'Sagittaire','Capricorne','Verseau','Poissons'),
  ('Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio',
   'Sagittarius','Capricorn','Aquarius','Pisces'),
  ('Widder','Stier','Zwillinge','Krebs','L”we','Jungfrau','Waage','Skorpion',
   'Schtze','Steinbock','Wassermann','Fische'),
  ('Aries','Tauro','G‚minis','C ncer','Leo','Virgo','Libra','Escorpio',
   'Sagitario','Capricornio','Acuario','Piscis'),
  ('Ariete','Toro','Gemelli','Cancro','Leone','Vergine','Bilancia',
   'Scorpione','Sagittario','Capricorno','Acquario','Pesci')
 );
 ASPN : Array[0..4, 1..7] Of String[13] = (
  ('Conjonction','Semi-sextile','Sextile','Carr‚','Trigone','Quinconce',
   'Opposition'),
  ('Conjunction','Semi-sextile','Sextile','Square','Trine','Quincunx',
   'Opposition'),
  ('Konjunktion','Halbsextil','Sextil','Quadrat','Trigon','Quincunx',
   'Opposition'),
  ('Conjunci¢n','Semisextil','Sextil','Cuadratura','Tr¡gono','Quincuncio',
   'Oposici¢n'),
  ('Congiunzione','Semisestile','Sestile','Quadratura','Trigono','Quinconce',
   'Opposizione')
 );
 MON : Array[0..4, 1..12] Of String[10] = (
  ('janvier','f‚vrier','mars','avril','mai','juin','juillet','ao–t',
   'septembre','octobre','novembre','d‚cembre'),
  ('January','February','March','April','May','June','July','August',
   'September','October','November','December'),
  ('Januar','Februar','M„rz','April','Mai','Juni','Juli','August','September',
   'Oktober','November','Dezember'),
  ('enero','febrero','marzo','abril','mayo','junio','julio','agosto',
   'septiembre','octubre','noviembre','diciembre'),
  ('gennaio','febbraio','marzo','aprile','maggio','giugno','luglio','agosto',
   'settembre','ottobre','novembre','dicembre')
 );
 WDAY : Array[0..4, 0..6] Of String[10] = (
  ('dimanche','lundi','mardi','mercredi','jeudi','vendredi','samedi'),
  ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'),
  ('Sonntag','Montag','Dienstag','Mittwoch','Donnerstag','Freitag','Samstag'),
  ('domingo','lunes','martes','mi‚rcoles','jueves','viernes','s bado'),
  ('domenica','luned','marted','mercoled','gioved','venerd','sabato')
 );
 M_FILE = 1;
 M_THEME = 2;
 M_DAY = 3;
 M_COMP = 4;
 M_HELP = 5;
 M_NEW = 6;
 M_OPEN = 7;
 M_SAVE = 8;
 M_EXPORT = 9;
 M_QUIT = 10;
 M_PLANETS = 11;
 M_HOUSES = 12;
 M_WHEEL = 13;
 M_PLDET = 14;
 M_HSDET = 15;
 M_DOMIN = 16;
 M_ASCEND = 17;
 M_DATE = 18;
 M_DAYTH = 19;
 M_PREV = 20;
 M_TAROT = 21;
 M_DDOM = 22;
 M_DPDET = 23;
 M_COMPTH = 24;
 M_GUIDE = 25;
 M_ABOUT = 26;
 S_STATUS = 27;
 S_NOPERSON = 28;
 S_BORN = 29;
 S_AT = 30;
 S_DAYOF = 31;
 S_DOMDAY = 32;
 S_FORCE = 33;
 S_POWER = 34;
 T_NATAL = 35;
 T_HOUSES = 36;
 T_WHEEL = 37;
 T_DAY = 38;
 T_PREV = 39;
 T_TAROT = 40;
 T_COMP = 41;
 T_HOUSE = 42;
 T_DOMIN = 43;
 T_ASCEND = 44;
 T_DDOM = 45;
 T_GUIDE = 46;
 H_PLANET = 47;
 H_POS = 48;
 H_SIGN = 49;
 H_HOUSE = 50;
 H_KEY = 51;
 H_MASTER = 52;
 S_AND = 53;
 S_DOMIS = 54;
 S_ASCIS = 55;
 S_GENERAL = 56;
 S_PARTIC = 57;
 S_PERSON = 58;
 S_POSITIF = 59;
 S_NEGATIF = 60;
 S_CARACT = 61;
 S_POTENT = 62;
 S_POSIT = 63;
 S_NEGAT = 64;
 S_VITAL = 65;
 S_SENTIM = 66;
 S_NOASP = 67;
 S_SAMEASP = 68;
 S_DECAN = 69;
 S_CARDOF = 70;
 S_TEXTFR = 71;
 S_KEYSNAT = 72;
 S_KEYSHS = 73;
 S_KEYSDAY = 74;
 S_KEYSWHL = 75;
 S_SCROLL = 76;
 D_PERSON = 77;
 D_NAME = 78;
 D_BDATE = 79;
 D_BTIME = 80;
 D_COUNTRY = 81;
 D_STATE = 82;
 D_CITY = 83;
 D_LAT = 84;
 D_LON = 85;
 D_OFFSET = 86;
 D_SEARCH = 87;
 D_OK = 88;
 D_CANCEL = 89;
 D_YES = 90;
 D_NO = 91;
 D_CLOSE = 92;
 D_DELETE = 93;
 D_HINTDLG = 94;
 D_CITYOK = 95;
 D_CITYNO = 96;
 D_CTRYNO = 97;
 D_OFFOK = 98;
 D_WARNUSA = 99;
 D_WARNFR = 100;
 D_BADNAME = 101;
 D_BADDATE = 102;
 D_BADTIME = 103;
 D_BADCOORD = 104;
 D_BADOFF = 105;
 D_DATE = 106;
 D_CALEPIN = 107;
 D_EMPTY = 108;
 D_SAVED = 109;
 D_ASKSAVE = 110;
 D_ASKDEL = 111;
 D_CHOOSEP = 112;
 D_CHOOSEH = 113;
 D_CHOOSEC = 114;
 D_EXPORTED = 115;
 D_IOERR = 116;
 D_QUITASK = 117;
 D_NOPERS = 118;
 A_TITLE = 119;
 A_SUB = 120;
 A_L1 = 121;
 A_L2 = 122;
 A_L3 = 123;
 A_L4 = 124;
 A_PRESS = 125;
 G_1 = 126;
 G_2 = 127;
 G_2B = 128;
 G_3 = 129;
 G_4 = 130;
 G_5 = 131;
 G_6 = 132;
 NMSG = 132;
 MSG : Array[1..NMSG, 0..4] Of String[250] = (
  ('&Fichier',
   '&File',
   '&Datei',
   '&Archivo',
   '&File'),
  ('&ThŠme',
   '&Chart',
   '&Horoskop',
   '&Carta',
   '&Tema'),
  ('&Jour',
   '&Day',
   '&Tag',
   '&D¡a',
   '&Giorno'),
  ('&Comparer',
   'C&ompare',
   '&Vergleich',
   'C&omparar',
   '&Confronta'),
  ('&Aide',
   '&Help',
   '&Hilfe',
   'A&yuda',
   '&Aiuto'),
  ('&Nouvel horoscope...',
   '&New horoscope...',
   '&Neues Horoskop...',
   '&Nuevo hor¢scopo...',
   '&Nuovo oroscopo...'),
  ('&Ouvrir le calepin...',
   '&Open notebook...',
   'Notizbuch ”&ffnen...',
   '&Abrir la agenda...',
   '&Apri il taccuino...'),
  ('&Enregistrer au calepin',
   '&Save to notebook',
   'Im Notizbuch &speichern',
   '&Guardar en la agenda',
   '&Salva nel taccuino'),
  ('E&xporter la page (texte)',
   'E&xport page (text)',
   'Seite e&xportieren (Text)',
   'E&xportar la p gina (texto)',
   'E&sporta la pagina (testo)'),
  ('&Quitter',
   '&Quit',
   '&Beenden',
   '&Salir',
   '&Esci'),
  ('&PlanŠtes',
   '&Planets',
   '&Planeten',
   '&Planetas',
   '&Pianeti'),
  ('&Maisons',
   '&Houses',
   '&H„user',
   '&Casas',
   '&Case'),
  ('&Carte du ciel',
   'Chart &wheel',
   '&Himmelskarte',
   'Carta del &cielo',
   '&Carta del cielo'),
  ('&D‚tail d''une planŠte...',
   'Planet &detail...',
   'Planeten&detail...',
   '&Detalle de un planeta...',
   '&Dettaglio di un pianeta...'),
  ('D‚tail d''une &maison...',
   '&House detail...',
   '&Hausdetail...',
   'Detalle de una c&asa...',
   'Dettaglio di una c&asa...'),
  ('PlanŠte do&minante',
   'Do&minant planet',
   '&Dominanter Planet',
   'Planeta do&minante',
   'Pianeta do&minante'),
  ('Signe &ascendant',
   '&Ascendant sign',
   '&Aszendent',
   'Signo &ascendente',
   'Segno &ascendente'),
  ('&Choisir la date...',
   '&Choose the date...',
   '&Datum w„hlen...',
   '&Elegir la fecha...',
   '&Scegli la data...'),
  ('&ThŠme du jour',
   '&Chart of the day',
   '&Tageshoroskop',
   '&Carta del d¡a',
   '&Tema del giorno'),
  ('&Pr‚visions',
   '&Forecasts',
   '&Vorhersagen',
   '&Previsiones',
   '&Previsioni'),
  ('T&arot astrologique',
   '&Astrological tarot',
   '&Astrologisches Tarot',
   '&Tarot astrol¢gico',
   'T&arocco astrologico'),
  ('&Dominante du jour',
   '&Dominant of the day',
   'Tages&dominante',
   '&Dominante del d¡a',
   '&Dominante del giorno'),
  ('D‚&tail d''une planŠte du jour...',
   'Day planet d&etail...',
   'Tagesplanet-D&etail...',
   'Detalle de un planeta del &d¡a...',
   'Dettaglio di un pianeta del gi&orno...'),
  ('&ThŠme compar‚...',
   '&Compared chart...',
   '&Vergleichshoroskop...',
   'Carta &comparada...',
   'Tema &confrontato...'),
  ('&Mode d''emploi',
   '&User guide',
   '&Bedienung',
   '&Modo de empleo',
   '&Istruzioni'),
  ('&A propos...',
   '&About...',
   '&šber...',
   '&Acerca de...',
   '&Informazioni...'),
  ('F2 Nouveau F3 Calepin F4 Date F5 Natal F6 Maisons F7 Carte F8 Jour F9'+
    ' Pr‚v.',
   'F2 New F3 Notebook F4 Date F5 Natal F6 Houses F7 Wheel F8 Day F9'+
    ' Forecast',
   'F2 Neu F3 Notizbuch F4 Datum F5 Geburt F6 H„user F7 Karte F8 Tag F9'+
    ' Progn.',
   'F2 Nuevo F3 Agenda F4 Fecha F5 Natal F6 Casas F7 Carta F8 D¡a F9 Previs.',
   'F2 Nuovo F3 Taccuino F4 Data F5 Natale F6 Case F7 Carta F8 Giorno F9'+
    ' Prev.'),
  ('Aucun horoscope : Fichier > Nouvel horoscope (F2) ou Calepin (F3)',
   'No horoscope: File > New horoscope (F2) or Notebook (F3)',
   'Kein Horoskop: Datei > Neues Horoskop (F2) oder Notizbuch (F3)',
   'Ning£n hor¢scopo: Archivo > Nuevo hor¢scopo (F2) o Agenda (F3)',
   'Nessun oroscopo: File > Nuovo oroscopo (F2) o Taccuino (F3)'),
  ('n‚(e) le',
   'born on',
   'geboren am',
   'nacido/a el',
   'nato/a il'),
  ('…',
   'at',
   'um',
   'a las',
   'alle'),
  ('Jour du',
   'Day of',
   'Tag vom',
   'D¡a del',
   'Giorno del'),
  ('Dominante',
   'Dominant',
   'Dominante',
   'Dominante',
   'Dominante'),
  ('force',
   'strength',
   'St„rke',
   'fuerza',
   'forza'),
  ('puissance',
   'power',
   'Macht',
   'potencia',
   'potenza'),
  ('ThŠme natal : les planŠtes',
   'Natal chart: the planets',
   'Geburtshoroskop: die Planeten',
   'Carta natal: los planetas',
   'Tema natale: i pianeti'),
  ('ThŠme natal : les maisons',
   'Natal chart: the houses',
   'Geburtshoroskop: die H„user',
   'Carta natal: las casas',
   'Tema natale: le case'),
  ('Carte du ciel',
   'Chart wheel',
   'Himmelskarte',
   'Carta del cielo',
   'Carta del cielo'),
  ('ThŠme du jour (midi T.U.)',
   'Chart of the day (noon UT)',
   'Tageshoroskop (12 Uhr UT)',
   'Carta del d¡a (mediod¡a TU)',
   'Tema del giorno (mezzogiorno TU)'),
  ('Pr‚visions du jour',
   'Forecasts of the day',
   'Vorhersagen des Tages',
   'Previsiones del d¡a',
   'Previsioni del giorno'),
  ('Tarot pr‚visionnel',
   'Forecast tarot',
   'Vorhersage-Tarot',
   'Tarot de previsi¢n',
   'Tarocco previsionale'),
  ('ThŠme compar‚',
   'Compared chart',
   'Vergleichshoroskop',
   'Carta comparada',
   'Tema confrontato'),
  ('Maison',
   'House',
   'Haus',
   'Casa',
   'Casa'),
  ('PlanŠte dominante',
   'Dominant planet',
   'Dominanter Planet',
   'Planeta dominante',
   'Pianeta dominante'),
  ('Signe ascendant',
   'Ascendant sign',
   'Aszendent',
   'Signo ascendente',
   'Segno ascendente'),
  ('Dominante du jour',
   'Dominant of the day',
   'Tagesdominante',
   'Dominante del d¡a',
   'Dominante del giorno'),
  ('Mode d''emploi',
   'User guide',
   'Bedienung',
   'Modo de empleo',
   'Istruzioni'),
  ('PlanŠte',
   'Planet',
   'Planet',
   'Planeta',
   'Pianeta'),
  ('Position',
   'Position',
   'Position',
   'Posici¢n',
   'Posizione'),
  ('Signe',
   'Sign',
   'Zeichen',
   'Signo',
   'Segno'),
  ('Maison',
   'House',
   'Haus',
   'Casa',
   'Casa'),
  ('Mots-cl‚s',
   'Keywords',
   'Stichworte',
   'Palabras clave',
   'Parole chiave'),
  ('MaŒtre de',
   'Rules',
   'Herrscher von',
   'Rige',
   'Governa'),
  ('et',
   'and',
   'und',
   'y',
   'e'),
  ('PlanŠte dominante',
   'Dominant planet',
   'Dominanter Planet',
   'Planeta dominante',
   'Pianeta dominante'),
  ('Signe ascendant',
   'Ascendant sign',
   'Aszendent',
   'Signo ascendente',
   'Segno ascendente'),
  ('En g‚n‚ral',
   'In general',
   'Im Allgemeinen',
   'En general',
   'In generale'),
  ('En particulier',
   'In particular',
   'Im Besonderen',
   'En particular',
   'In particolare'),
  ('Personnellement',
   'Personally',
   'Pers”nlich',
   'Personalmente',
   'Personalmente'),
  ('Influence positive',
   'Positive influence',
   'Positiver Einfluss',
   'Influencia positiva',
   'Influsso positivo'),
  ('Influence n‚gative',
   'Negative influence',
   'Negativer Einfluss',
   'Influencia negativa',
   'Influsso negativo'),
  ('CaractŠre',
   'Character',
   'Charakter',
   'Car cter',
   'Carattere'),
  ('Potentiel',
   'Potential',
   'Potenzial',
   'Potencial',
   'Potenziale'),
  ('Positif',
   'Positive',
   'Positiv',
   'Positivo',
   'Positivo'),
  ('N‚gatif',
   'Negative',
   'Negativ',
   'Negativo',
   'Negativo'),
  ('Vitalit‚',
   'Vitality',
   'Vitalit„t',
   'Vitalidad',
   'Vitalit…'),
  ('Sentiments',
   'Feelings',
   'Gefhle',
   'Sentimientos',
   'Sentimenti'),
  ('D‚sol‚, mes recherches sur les aspects restent sans r‚sultat pour ce'+
    ' jour.',
   'Sorry, my search for aspects found nothing for this day.',
   'Leider ergab die Suche nach Aspekten fr diesen Tag nichts.',
   'Lo siento, la b£squeda de aspectos no da resultado para este d¡a.',
   'Spiacente, la ricerca degli aspetti non d… risultati per questo giorno.'),
  ('* = mˆme aspect dans le thŠme natal   ** = touche une dominante',
   '* = same aspect in the natal chart   ** = involves a dominant',
   '* = gleicher Aspekt im Geburtshoroskop   ** = betrifft eine Dominante',
   '* = mismo aspecto en la carta natal   ** = afecta a una dominante',
   '* = stesso aspetto nel tema natale   ** = riguarda una dominante'),
  ('d‚can',
   'decan',
   'Dekade',
   'decanato',
   'decade'),
  ('Arcane',
   'Arcanum',
   'Arkanum',
   'Arcano',
   'Arcano'),
  ('(Les textes d''interpr‚tation sont r‚dig‚s en fran‡ais.)',
   '(The interpretation texts are written in French.)',
   '(Die Deutungstexte sind auf Franz”sisch verfasst.)',
   '(Los textos de interpretaci¢n est n en franc‚s.)',
   '(I testi di interpretazione sono in francese.)'),
  ('Touches 1-9, 0 : planŠte   D : dominante   A : ascendant   Clic : d‚tail',
   'Keys 1-9, 0: planet   D: dominant   A: ascendant   Click: detail',
   'Tasten 1-9, 0: Planet   D: Dominante   A: Aszendent   Klick: Detail',
   'Teclas 1-9, 0: planeta   D: dominante   A: ascendente   Clic: detalle',
   'Tasti 1-9, 0: pianeta   D: dominante   A: ascendente   Clic: dettaglio'),
  ('Touches 1-9, 0, -, = : maison I … XII   Clic : d‚tail',
   'Keys 1-9, 0, -, =: house I to XII   Click: detail',
   'Tasten 1-9, 0, -, =: Haus I bis XII   Klick: Detail',
   'Teclas 1-9, 0, -, =: casa I a XII   Clic: detalle',
   'Tasti 1-9, 0, -, =: casa I a XII   Clic: dettaglio'),
  ('Touches 1-9, 0 : planŠte du jour   D : dominante du jour   Clic : d‚tail',
   'Keys 1-9, 0: day planet   D: dominant of the day   Click: detail',
   'Tasten 1-9, 0: Tagesplanet   D: Tagesdominante   Klick: Detail',
   'Teclas 1-9, 0: planeta del d¡a   D: dominante del d¡a   Clic: detalle',
   'Tasti 1-9, 0: pianeta del giorno   D: dominante del giorno   Clic:'+
    ' dettaglio'),
  ('T : afficher ou masquer les planŠtes du jour (anneau ext‚rieur)',
   'T: show or hide the planets of the day (outer ring)',
   'T: Tagesplaneten ein- oder ausblenden („uáerer Ring)',
   'T: mostrar u ocultar los planetas del d¡a (anillo exterior)',
   'T: mostra o nascondi i pianeti del giorno (anello esterno)'),
  ('Haut/Bas, PgPr‚c/PgSuiv : d‚filer   chap : retour',
   'Up/Down, PgUp/PgDn: scroll   Esc: back',
   'Auf/Ab, BildAuf/BildAb: bl„ttern   Esc: zurck',
   'Arriba/Abajo, ReP g/AvP g: desplazar   Esc: volver',
   'Su/Gi—, PagSu/PagGi—: scorrere   Esc: indietro'),
  ('Nouvel horoscope',
   'New horoscope',
   'Neues Horoskop',
   'Nuevo hor¢scopo',
   'Nuovo oroscopo'),
  ('Nom ou pr‚nom',
   'Name',
   'Name',
   'Nombre',
   'Nome'),
  ('Date (JJ/MM/AAAA)',
   'Date (DD/MM/YYYY)',
   'Datum (TT/MM/JJJJ)',
   'Fecha (DD/MM/AAAA)',
   'Data (GG/MM/AAAA)'),
  ('Heure (HH:MM)',
   'Time (HH:MM)',
   'Uhrzeit (HH:MM)',
   'Hora (HH:MM)',
   'Ora (HH:MM)'),
  ('Pays (code)',
   'Country (code)',
   'Land (Kennz.)',
   'Pa¡s (c¢digo)',
   'Paese (sigla)'),
  ('tat (USA, CDN)',
   'State (USA, CDN)',
   'Staat (USA, CDN)',
   'Estado (USA, CDN)',
   'Stato (USA, CDN)'),
  ('Ville',
   'City',
   'Stadt',
   'Ciudad',
   'Citt…'),
  ('Latitude (48N50)',
   'Latitude (48N50)',
   'Breite (48N50)',
   'Latitud (48N50)',
   'Latitudine (48N50)'),
  ('Longitude (2E20)',
   'Longitude (2E20)',
   'L„nge (2E20)',
   'Longitud (2E20)',
   'Longitudine (2E20)'),
  ('D‚calage T.U. (h)',
   'UT offset (h)',
   'UT-Versatz (h)',
   'Desfase TU (h)',
   'Scarto TU (h)'),
  ('Chercher',
   'Search',
   'Suchen',
   'Buscar',
   'Cerca'),
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
   'S¡',
   'S'),
  ('Non',
   'No',
   'Nein',
   'No',
   'No'),
  ('Fermer',
   'Close',
   'Schlieáen',
   'Cerrar',
   'Chiudi'),
  ('Supprimer',
   'Delete',
   'L”schen',
   'Borrar',
   'Elimina'),
  ('Tab : champ suivant   Entr‚e : valider   chap : annuler',
   'Tab: next field   Enter: confirm   Esc: cancel',
   'Tab: n„chstes Feld   Enter: best„tigen   Esc: abbrechen',
   'Tab: campo siguiente   Intro: aceptar   Esc: cancelar',
   'Tab: campo successivo   Invio: conferma   Esc: annulla'),
  ('Ville trouv‚e :',
   'City found:',
   'Stadt gefunden:',
   'Ciudad encontrada:',
   'Citt… trovata:'),
  ('Ville inconnue : saisissez la latitude et la longitude.',
   'Unknown city: enter latitude and longitude.',
   'Unbekannte Stadt: Breite und L„nge eingeben.',
   'Ciudad desconocida: introduzca latitud y longitud.',
   'Citt… sconosciuta: inserire latitudine e longitudine.'),
  ('Code de pays inconnu.',
   'Unknown country code.',
   'Unbekanntes Landeskennzeichen.',
   'C¢digo de pa¡s desconocido.',
   'Sigla del paese sconosciuta.'),
  ('D‚calage T.U. calcul‚ :',
   'Computed UT offset:',
   'Berechneter UT-Versatz:',
   'Desfase TU calculado:',
   'Scarto TU calcolato:'),
  ('Nombreuses exceptions locales : v‚rifiez le d‚calage.',
   'Many local exceptions: check the offset.',
   'Viele lokale Ausnahmen: Versatz prfen.',
   'Muchas excepciones locales: verifique el desfase.',
   'Molte eccezioni locali: verificare lo scarto.'),
  ('France 1940-1942 : zone libre -1, zone occup‚e -2.',
   'France 1940-1942: free zone -1, occupied zone -2.',
   'Frankreich 1940-1942: freie Zone -1, besetzte Zone -2.',
   'Francia 1940-1942: zona libre -1, zona ocupada -2.',
   'Francia 1940-1942: zona libera -1, zona occupata -2.'),
  ('Indiquez un nom ou un pr‚nom.',
   'Enter a name.',
   'Bitte einen Namen eingeben.',
   'Indique un nombre.',
   'Inserire un nome.'),
  ('Date invalide (1800 … 2199).',
   'Invalid date (1800 to 2199).',
   'Ungltiges Datum (1800 bis 2199).',
   'Fecha no v lida (1800 a 2199).',
   'Data non valida (1800-2199).'),
  ('Heure invalide.',
   'Invalid time.',
   'Ungltige Uhrzeit.',
   'Hora no v lida.',
   'Ora non valida.'),
  ('Latitude ou longitude invalide.',
   'Invalid latitude or longitude.',
   'Ungltige Breite oder L„nge.',
   'Latitud o longitud no v lida.',
   'Latitudine o longitudine non valida.'),
  ('D‚calage invalide (-13 … 13 h).',
   'Invalid offset (-13 to 13 h).',
   'Ungltiger Versatz (-13 bis 13 h).',
   'Desfase no v lido (-13 a 13 h).',
   'Scarto non valido (-13 a 13 h).'),
  ('Date du thŠme du jour',
   'Date of the day chart',
   'Datum des Tageshoroskops',
   'Fecha de la carta del d¡a',
   'Data del tema del giorno'),
  ('Calepin',
   'Notebook',
   'Notizbuch',
   'Agenda',
   'Taccuino'),
  ('Le calepin est vide.',
   'The notebook is empty.',
   'Das Notizbuch ist leer.',
   'La agenda est  vac¡a.',
   'Il taccuino Š vuoto.'),
  ('Enregistr‚ dans le calepin.',
   'Saved to the notebook.',
   'Im Notizbuch gespeichert.',
   'Guardado en la agenda.',
   'Salvato nel taccuino.'),
  ('Enregistrer cette personne dans le calepin ?',
   'Save this person to the notebook?',
   'Diese Person im Notizbuch speichern?',
   '¨Guardar esta persona en la agenda?',
   'Salvare questa persona nel taccuino?'),
  ('Supprimer cette personne du calepin ?',
   'Delete this person from the notebook?',
   'Diese Person aus dem Notizbuch l”schen?',
   '¨Borrar esta persona de la agenda?',
   'Eliminare questa persona dal taccuino?'),
  ('Choisir une planŠte',
   'Choose a planet',
   'Planet w„hlen',
   'Elegir un planeta',
   'Scegli un pianeta'),
  ('Choisir une maison',
   'Choose a house',
   'Haus w„hlen',
   'Elegir una casa',
   'Scegli una casa'),
  ('ThŠme compar‚ avec...',
   'Compare with...',
   'Vergleichen mit...',
   'Comparar con...',
   'Confronta con...'),
  ('Page export‚e dans',
   'Page exported to',
   'Seite exportiert nach',
   'P gina exportada en',
   'Pagina esportata in'),
  ('Erreur d''‚criture du fichier.',
   'File write error.',
   'Fehler beim Schreiben der Datei.',
   'Error al escribir el archivo.',
   'Errore di scrittura del file.'),
  ('Quitter Astromancie ?',
   'Quit Astromancie?',
   'Astromancie beenden?',
   '¨Salir de Astromancie?',
   'Uscire da Astromancie?'),
  ('Cr‚ez d''abord un horoscope.',
   'Create a horoscope first.',
   'Erstellen Sie zuerst ein Horoskop.',
   'Cree primero un hor¢scopo.',
   'Creare prima un oroscopo.'),
  ('Astromancie',
   'Astromancie',
   'Astromancie',
   'Astromancie',
   'Astromancie'),
  ('Logiciel interactif d''interpr‚tation de l''astrologie',
   'Interactive astrology interpretation software',
   'Interaktive Software zur Deutung der Astrologie',
   'Programa interactivo de interpretaci¢n astrol¢gica',
   'Programma interattivo di interpretazione astrologica'),
  ('Inspir‚ du logiciel URRIS (1985), reconstitu‚ fidŠlement :',
   'Inspired by the URRIS software (1985), faithfully rebuilt:',
   'Nach der Software URRIS (1985) originalgetreu nachgebaut:',
   'Inspirado en el programa URRIS (1985), reconstruido fielmente:',
   'Ispirato al programma URRIS (1985), ricostruito fedelmente:'),
  ('mˆmes calculs plan‚taires, maisons, aspects, puissances et tarot.',
   'same planetary, house, aspect, power and tarot computations.',
   'gleiche Planeten-, H„user-, Aspekt-, Macht- und Tarotberechnung.',
   'mismos c lculos de planetas, casas, aspectos, potencias y tarot.',
   'stessi calcoli di pianeti, case, aspetti, potenze e tarocchi.'),
  ('Ouvrages de r‚f‚rence : Georges Muchery,',
   'Reference works: Georges Muchery,',
   'Referenzwerke: Georges Muchery,',
   'Obras de referencia: Georges Muchery,',
   'Opere di riferimento: Georges Muchery,'),
  ('Trait‚ pratique d''astrologie judiciaire, Le Tarot astrologique.',
   'Trait‚ pratique d''astrologie judiciaire, Le Tarot astrologique.',
   'Trait‚ pratique d''astrologie judiciaire, Le Tarot astrologique.',
   'Trait‚ pratique d''astrologie judiciaire, Le Tarot astrologique.',
   'Trait‚ pratique d''astrologie judiciaire, Le Tarot astrologique.'),
  ('Appuyez sur une touche ou cliquez...',
   'Press a key or click...',
   'Taste drcken oder klicken...',
   'Pulse una tecla o haga clic...',
   'Premere un tasto o fare clic...'),
  ('Astromancie interprŠte un thŠme astral … partir de la date, de l''heure'+
    ' et du lieu de naissance.',
   'Astromancie interprets a birth chart from the date, time and place of'+
    ' birth.',
   'Astromancie deutet ein Geburtshoroskop aus Datum, Uhrzeit und'+
    ' Geburtsort.',
   'Astromancie interpreta una carta natal a partir de la fecha, la hora y'+
    ' el lugar de nacimiento.',
   'Astromancie interpreta un tema natale a partire da data, ora e luogo di'+
    ' nascita.'),
  ('Fichier > Nouvel horoscope : saisissez le nom, la date et l''heure'+
    ' locale.',
   'File > New horoscope: enter the name, the date and the local time.',
   'Datei > Neues Horoskop: Name, Datum und Ortszeit eingeben.',
   'Archivo > Nuevo hor¢scopo: introduzca el nombre, la fecha y la hora'+
    ' local.',
   'File > Nuovo oroscopo: inserire nome, data e ora locale.'),
  ('Donnez le code international du pays (F, B, CH, CDN, USA...) et la'+
    ' ville, puis ® Chercher ¯ : la latitude, la longitude et le d‚calage'+
    ' horaire de l''‚poque sont propos‚s. Vous pouvez les corriger.',
   'Give the international country code (F, B, CH, CDN, USA...) and the'+
    ' city, then "Search": latitude, longitude and the time offset of that'+
    ' period are proposed. You may correct them.',
   'Internationales L„nderkennzeichen (F, B, CH, D, USA...) und Stadt'+
    ' angeben, dann "Suchen": Breite, L„nge und der damalige Zeitversatz'+
    ' werden vorgeschlagen und k”nnen korrigiert werden.',
   'Indique el c¢digo internacional del pa¡s (F, B, CH, E, USA...) y la'+
    ' ciudad, luego "Buscar": se proponen la latitud, la longitud y el'+
    ' desfase horario de la ‚poca. Puede corregirlos.',
   'Indicare la sigla internazionale del paese (F, B, CH, I, USA...) e la'+
    ' citt…, poi "Cerca": vengono proposti latitudine, longitudine e scarto'+
    ' orario dell''epoca, modificabili.'),
  ('Le d‚calage T.U. est le nombre d''heures … ajouter au temps universel'+
    ' pour obtenir l''heure locale (+1 pour Paris en hiver, -5 pour New'+
    ' York).',
   'The UT offset is the number of hours to add to universal time to get'+
    ' local time (+1 for Paris in winter, -5 for New York).',
   'Der UT-Versatz ist die Stundenzahl, die zur Weltzeit addiert die'+
    ' Ortszeit ergibt (+1 fr Paris im Winter, -5 fr New York).',
   'El desfase TU es el n£mero de horas que se suman al tiempo universal'+
    ' para obtener la hora local (+1 para Par¡s en invierno, -5 para Nueva'+
    ' York).',
   'Lo scarto TU Š il numero di ore da aggiungere al tempo universale per'+
    ' ottenere l''ora locale (+1 per Parigi in inverno, -5 per New York).'),
  ('Le menu ThŠme pr‚sente les planŠtes natales, les maisons, la carte du'+
    ' ciel, la planŠte dominante et l''ascendant. Cliquez sur une ligne pour'+
    ' lire son interpr‚tation.',
   'The Chart menu shows the natal planets, the houses, the chart wheel,'+
    ' the dominant planet and the ascendant. Click a line to read its'+
    ' interpretation.',
   'Das Men Horoskop zeigt Geburtsplaneten, H„user, Himmelskarte,'+
    ' dominanten Planeten und Aszendenten. Eine Zeile anklicken, um ihre'+
    ' Deutung zu lesen.',
   'El men£ Carta muestra los planetas natales, las casas, la carta del'+
    ' cielo, el planeta dominante y el ascendente. Haga clic en una l¡nea'+
    ' para leer su interpretaci¢n.',
   'Il menu Tema mostra i pianeti natali, le case, la carta del cielo, il'+
    ' pianeta dominante e l''ascendente. Fare clic su una riga per leggerne'+
    ' l''interpretazione.'),
  ('Le menu Jour calcule le ciel du jour choisi (midi T.U.) : thŠme du'+
    ' jour, pr‚visions tir‚es des aspects, tarot astrologique et dominante'+
    ' du jour.',
   'The Day menu computes the sky of the chosen day (noon UT): chart of the'+
    ' day, forecasts drawn from the aspects, astrological tarot and dominant'+
    ' of the day.',
   'Das Men Tag berechnet den Himmel des gew„hlten Tages (12 Uhr UT):'+
    ' Tageshoroskop, Vorhersagen aus den Aspekten, astrologisches Tarot und'+
    ' Tagesdominante.',
   'El men£ D¡a calcula el cielo del d¡a elegido (mediod¡a TU): carta del'+
    ' d¡a, previsiones seg£n los aspectos, tarot astrol¢gico y dominante del'+
    ' d¡a.',
   'Il menu Giorno calcola il cielo del giorno scelto (mezzogiorno TU):'+
    ' tema del giorno, previsioni dagli aspetti, tarocco astrologico e'+
    ' dominante del giorno.'),
  ('Le calepin (fichier ASTROMAN.CAL) conserve les personnes ; le thŠme'+
    ' compar‚ combine deux thŠmes du calepin par leurs points m‚dians.',
   'The notebook (file ASTROMAN.CAL) keeps the persons; the compared chart'+
    ' combines two charts of the notebook through their midpoints.',
   'Das Notizbuch (Datei ASTROMAN.CAL) speichert die Personen; das'+
    ' Vergleichshoroskop verbindet zwei Horoskope ber ihre Mittelpunkte.',
   'La agenda (archivo ASTROMAN.CAL) guarda las personas; la carta'+
    ' comparada combina dos cartas de la agenda por sus puntos medios.',
   'Il taccuino (file ASTROMAN.CAL) conserva le persone; il tema'+
    ' confrontato combina due temi del taccuino tramite i punti medi.')
 );
 NCITY = 1831;
 CITY : Array[1..NCITY] Of String[34] = (
  'GB Portsmouth|-106|5048','USAPittsburgh|-8000|4025',
  'USANewport News|-7626|3659','SU Sverdlovsk|6030|5650',
  'SU Novossibirsk|8305|5504','SU Vladivostok|13153|4309',
  'SOUPort Soudan|3708|1938','DY Porto Novo|249|630',
  'RMMTombouctou|-300|1650','RSRSalisbury|3102|-1750',
  'ZRELeopoldville|1518|-418','ZREStanleyville|2515|35',
  'AUSTownsville|14648|-1915','AUSWollongong|15054|-3425',
  'NZ Wellington|17446|-4119','MEXMonterrey|-10020|2540',
  'MS Port Louis|5733|-2017','PNGPort Moresby|14707|-930',
  'WV Kingstown|-6114|1312','GUYSt Laurent|-5403|529','WANOgbomosho|411|805',
  'ZA Germiston|2810|-2611','MEXTorreon|-10325|2533','SN St Louis|-1630|1601',
  'USANew Orleans|-9003|3000','RU Bujumbura|2918|-316',
  'P  Matosinhos|-842|4111','ZA Port Elizabeth|2536|-3358',
  'D  Stuttgart|910|4846','USASacramento|-12130|3832',
  'S  Eskilstuna|1632|5922','MOZQuelimane|3651|-1753',
  'RH Port Au Prince|-7220|1833','USANew York|-7550|4040',
  'RCBBrazzaville|1514|-414','ZREElisabethville|2729|-1141',
  'BOLSanta Cruz|-6314|-1745','USAHouston|-9525|2945',
  'USABaton Rouge|-9105|3030','DOMSt Domingue|-6951|1800',
  'USABridgeport|-7212|4112','PL Bydgoszcz|1800|5310',
  'RSRBulawayo|2832|-2007','USASt Louis|-9015|3840','S  Norrkoping|1611|5837',
  'J  Kitakyushu|13050|3353','SKNBasseterre|-6243|1717',
  'USAJacksonville|-8138|3015','SWAWalvis Bay|1431|-2259',
  'ZRELubumbashi|2729|-1141','DZ Constantine|642|3625',
  'S  Kristianstad|1409|5602','AUSRockhampton|15032|-2322',
  'YV Barquisimeto|-6913|958','GY Georgetown|-5812|650',
  'SOUKhartoum|3235|1533','SGPSingapour|10349|119',
  'RP Quezon City|12100|1438','USACharlotteville|-7830|3801',
  'TT Port Of Spain|-6130|1040','USAWorcester|-7148|4217',
  'Z  Livingstone|2553|-1750','NZ Christchurch|17247|-4333',
  'SOUOmdourman|3228|1537','F  Agde|328|4319','F  Die|522|4447',
  'F  Ham|304|4944','F  Caen|-22|4910','F  Gap|605|4433','F  Albi|209|4356',
  'F  Ay|400|4903','F  Eu|126|5003','F  Agen|38|4212','F  Dax|-103|4343',
  'F  Nice|714|4342','F  Figeac|202|4437','F  Auch|36|4339',
  'F  Gien|238|4742','F  Bellac|104|4607','F  Gex|603|4621',
  'F  Elne|259|4236','F  Dole|530|4706','F  Bauge|-8|4731','F  Apt|524|4353',
  'F  Apt|524|4353','F  Ales|405|4409','F  Delle|702|4730','F  Pau|-22|4318',
  'F  Digne|612|4405','F  Bolbec|30|4930','F  Cancale|-150|4840',
  'F  Blagnac|123|4337','F  Aniche|314|5020','F  Luce|127|4826',
  'F  Nerac|20|4409','F  Mende|330|4431','F  Dinan|-202|4828',
  'F  Ajaccio|840|4155','F  Laon|335|4933','F  Sedan|457|4943',
  'F  Cognac|-20|4541','F  Langeac|330|4506','F  Alger|308|3642',
  'F  Fecamp|22|4945','F  Blaye|-38|4508','F  Gaillac|154|4354',
  'F  Calais|150|5057','F  L''Aigle|38|4846','F  Macon|450|4618',
  'F  Scaer|-370|4804','F  Calvi|845|4234','F  Melle|-10|4614',
  'F  Aubin|215|4433','F  Capdenac|204|4434','F  Cambrai|314|5010',
  'F  Denain|322|5020','F  Creil|229|4916','F  Beaune|450|4702',
  'F  Bandol|546|4308','F  Laval|-47|4804','F  Caudebec en Caux|42|4930',
  'F  Bazas|-13|4427','F  Sete|342|4325','F  Le Blanc|104|4639',
  'F  Baccarat|642|4828','F  Dinard|-206|4838','F  Lille|303|5038',
  'F  Douai|304|5021','F  Lens|250|5026','F  Auchel|228|5030',
  'F  Aubagne|537|4317','F  Gray|535|4727','F  Ceret|242|4230',
  'F  Dijon|500|4720','F  Corbie|230|4954','F  Bastia|930|4240',
  'F  Bannalec|-342|4757','F  Decize|328|4650','F  La Fleche|-4|4742',
  'F  Modane|640|4512','F  N D de Gravenchon|-33|4929','F  Falaise|-12|4854',
  'F  Mably|404|4605','F  Briare|245|4738','F  Forbach|652|4910',
  'F  Vire|-53|4850','F  Segre|-52|4740','F  Foix|138|4258',
  'F  Parame|-159|4839','F  Reze|-134|4710','F  La Baule|-224|4717',
  'F  Arles|438|4341','F  Dieppe|105|4956','F  Deols|143|4650',
  'F  Florac|337|4420','F  Riom|307|4554','F  Riberac|20|4515',
  'F  Cannes|700|4332','F  Redon|-206|4740','F  Lure|630|4740',
  'F  Ugine|625|4545','F  La Crau|604|4309','F  Le Val D''Ajol|630|4755',
  'F  St Die|656|4817','F  Le Gond|11|4540','F  Sens|318|4812',
  'F  Gannat|311|4607','F  Blois|120|4735','F  Fumel|58|4430',
  'F  Nancy|612|4842','F  Joeuf|600|4912','F  Meru|208|4913',
  'F  Arras|246|5017','F  Thann|705|4748','F  Epinal|627|4819',
  'F  Lamballe|-231|4829','F  Albert|238|5000','F  Lomme|259|5039',
  'F  Digoin|358|4629','F  Bergerac|30|4451','F  Lagny|244|4852',
  'F  Ruffec|12|4602','F  Ambert|344|4533','F  Anglet|-131|4329',
  'F  La Grand Combe|-402|4413','F  Orange|447|4408','F  Nimes|423|4350',
  'F  Talence|-36|4449','F  Rehon|546|4930','F  Flers|-33|4847',
  'F  Loudeac|-247|4811','F  Amiens|216|4954','F  Belley|541|4546',
  'F  Corte|909|4218','F  Hayange|602|4920','F  Valence|454|4456',
  'F  Revel|159|4327','F  Loches|100|4708','F  Uckange|609|4918',
  'F  Clamecy|330|4728','F  Seclin|302|5033','F  Hendaye|-147|4323',
  'F  Colmar|720|4805','F  Cognin|554|4533','F  Annecy|608|4555',
  'F  L''Isle Adam|214|4906','F  Le Teil|440|4433','F  Paris|220|4850',
  'F  Paris|220|4850','F  Aubenas|424|4437','F  Givet|449|5008',
  'F  Arcachon|-110|4440','F  Langon|-16|4433','F  Pessac|-38|4449',
  'F  Lodeve|319|4344','F  Chinon|15|4710','F  Cholet|-52|4704',
  'F  Boucau|-129|4332','F  Billere|-24|4319','F  Prades|223|4238',
  'F  Pons|-34|4535','F  Meaux|254|4858','F  Brest|-429|4824',
  'F  Condom|22|4357','F  Mirande|25|4331','F  Lunel|409|4339',
  'F  Amboise|100|4724','F  Cahors|127|4427','F  Angers|-35|4730',
  'F  Reims|400|4915','F  Metz|610|4908','F  Chambly|215|4910',
  'F  Alencon|4|4827','F  Tarare|426|4554','F  Le Mans|12|4800',
  'F  Dol de Bretagne|-145|4833','F  Crest|502|4444','F  Bernay|35|4905',
  'F  Beaucaire|439|4348','F  Ancenis|-110|4721','F  Tarbes|3|4315',
  'F  Melun|239|4832','F  Nangis|300|4833','F  Roye|247|4943',
  'F  Bollene|445|4418','F  Lucon|-110|4628','F  Bar le Duc|510|4847',
  'F  St Lo|-105|4907','F  Mauriac|219|4513','F  Golbey|626|4811',
  'F  Fumay|442|4959','F  Auray|-259|4740','F  La Machine|328|4653',
  'F  Cernay|710|4749','F  Lyon|450|4546','F  Vichy|326|4606',
  'F  Charmes|617|4822','F  Bruz|-146|4801','F  Roanne|404|4603',
  'F  Carvin|257|5030','F  Le Cateau|332|5007','F  Rethel|420|4930',
  'F  Revin|439|4955','F  Rodez|233|4421','F  Millau|304|4408',
  'F  La Reole|-2|4435','F  La Chatre|159|4635','F  Jarny|553|4909',
  'F  Toul|553|4840','F  Rombas|604|4915','F  La Ferte Bernard|40|4811',
  'F  Grasse|656|4338','F  Aytre|-106|4608','F  Jonzac|-28|4527',
  'F  Vienne|453|4531','F  Feurs|414|4545','F  Marmande|10|4430',
  'F  Mamers|22|4821','F  Chateau Chinon|356|4704','F  Tulle|147|4716',
  'F  Evry|227|4838','F  Antibes|706|4334','F  La Chapelle St Luc|403|4820',
  'F  Le Vigan|336|4359','F  Merignac|-39|4451','F  La Mure|547|4453',
  'F  Dieuze|642|4848','F  Rouffac|716|4752','F  Abbeville|149|5007',
  'F  Challans|-152|4650','F  Bellegarde/valserine|550|4604',
  'F  Nantua|535|4610','F  Uzes|426|4401','F  Somain|317|5022',
  'F  Lievin|247|5024','F  Le Havre|7|4929','F  Chenove|500|4716',
  'F  Creteil|228|4847','F  Chauny|312|4937','F  Dreux|123|4844',
  'F  Trignac|-211|4719','F  Caudry|322|5007','F  St Jean D''Angely|-31|4557',
  'F  Marcq en Baroeul|304|5041','F  Aix les Bains|553|4541',
  'F  Murat|253|4507','F  Besancon|602|4709','F  Persan|216|4909',
  'F  Rouen|104|4927','F  Embrun|630|4434','F  Ruelle|14|4540',
  'F  Royan|-102|4537','F  Lombez|55|4329','F  Le Chambon Feugeroll|420|4523',
  'F  Nantes|-133|4712','F  Ciboure|-140|4323','F  Caussade|133|4410',
  'F  Salies de Bearn|-56|4328','F  Plerin|-246|4832','F  Bobigny|227|4855',
  'F  Miramas|502|4333','F  Bonifacio|910|4124','F  Vitre|-112|4808',
  'F  Brioude|323|4518','F  Bailleul|241|5044','F  Sceaux|218|4847',
  'F  Berck Plage|136|5025','F  Argeles Gazost|-6|4234',
  'F  Bagneres de Bigorre|9|4305','F  Arpajon|215|4836',
  'F  Pauillac|-46|4511','F  Rennes|-141|4807','F  Vannes|-244|4740',
  'F  Maubeuge|358|5017','F  Bethune|238|5030','F  Chambery|555|4534',
  'F  Longeau|222|4952','F  Lavaur|149|4342','F  Dammarie les Lys|239|4831',
  'F  Gueret|151|4611','F  Niort|-29|4619','F  Briancon|639|4454',
  'F  Ussel|218|4532','F  La Ricamarie|422|4524','F  Carentan|-115|4919',
  'F  Langres|520|4752','F  Hagondange|609|4915','F  Bayonne|-128|4330',
  'F  Cours|419|4607','F  Brive-La-Gaillarde|132|4510',
  'F  Le Relecq Kerhuon|-424|4824','F  La Ferte/jouarre|308|4856',
  'F  Aurillac|226|4455','F  Avallon|353|4730','F  Muret|120|4330',
  'F  Morez|602|4631','F  Charlieu|410|4610','F  Mayenne|-37|4818',
  'F  La Charite sur Loire|301|4710','F  Orchies|314|5028',
  'F  Autun|417|4658','F  Baume les Dames|621|4721',
  'F  St Jean de Maurienne|628|4516','F  St Jean de Braye|200|4753',
  'F  St Jean de Luz|-139|4323','F  Valreas|459|4422','F  Belfort|650|4738',
  'F  Bayeux|-42|4917','F  Rocroi|430|4955','F  Penmarch|-421|4749',
  'F  Grenoble|542|4512','F  Vendome|103|4747','F  Senlis|235|4903',
  'F  Oignies|259|5028','F  Etaples|139|5030','F  Haguenau|747|4849',
  'F  Malo les Bains|224|5103','F  Rive de Gier|437|4532',
  'F  Doue la Fontaine|-16|4711','F  Amberieu en Bugey|520|4557',
  'F  Chateau Salins|630|4850','F  Henin Beaumont|258|5025',
  'F  Lannion|-328|4844','F  Etampes|210|4826','F  Le Puy|353|4502',
  'F  Avrille|-36|4731','F  Thiers|333|4552','F  Cluses|635|4605',
  'F  Maromme|102|4928','F  Mazamet|222|4329','F  Moissac|105|4407',
  'F  St Malo|-201|4839','F  La Ferte Mace|-22|4835','F  Boussac|213|4622',
  'F  Joigny|324|4759','F  Salbris|203|4725','F  Beauvais|205|4926',
  'F  Argentan|-1|4845','F  Grigny|447|4536','F  Passy|640|4556',
  'F  Hyeres|608|4307','F  Frejus|644|4325','F  Civray|17|4610',
  'F  Limoges|115|4550','F  Blaye les Mines|208|4402',
  'F  La Roche sur Yon|-126|4640','F  Chateau Gontier|-42|4750',
  'F  Mandeure|648|4727','F  La Bresse|654|4800','F  Menton|730|4347',
  'F  Pamiers|136|4307','F  La Ciotat|537|4310','F  Besseges|408|4418',
  'F  Morhange|638|4855','F  Arques|217|5044','F  Mauleon|-35|4657',
  'F  La Roche sur Foron|619|4604','F  Canteleu|101|4926',
  'F  Carmaux|210|4403','F  Pont L''Abbe|-415|4752',
  'F  Chateau Renault|56|4736','F  Paimpol|-304|4848','F  Avignon|450|4357',
  'F  Marignane|512|4325','F  Sartene|858|4138','F  La Teste|-108|4437',
  'F  Altkirch|715|4737','F  La Seyne|553|4311','F  Naintre|29|4647',
  'F  Sancerre|250|4720','F  Les Herbiers|-101|4652','F  Hirson|404|4955',
  'F  Narbonne|300|4311','F  Chatelaillon Plage|-105|4605',
  'F  Beaugency|138|4747','F  Olivet|152|4752','F  Frouard|608|4847',
  'F  Nevers|309|4700','F  Noyon|300|4936','F  Brumath|740|4843',
  'F  Barentin|55|4933','F  Sarlat la Caneda|113|4453',
  'F  Bourg en Bresse|512|4613','F  St Medard en Jalles|-43|4453',
  'F  St Amand les Eaux|325|5027','F  Neufchateau|540|4821',
  'F  Annonay|440|4515','F  Beziers|312|4320','F  Fontaine|541|4511',
  'F  Orleans|152|4754','F  Epernay|356|4903','F  Verdun|523|4909',
  'F  Gourin|-337|4808','F  Saverne|720|4839','F  St Calais|45|4755',
  'F  Chateau du Loir|25|4740','F  Berre L''Etang|510|4327',
  'F  St Amand Mont Rond|230|4643','F  Mont de Marsan|-31|4354',
  'F  Mantes la Jolie|143|4900','F  Mantes la Ville|143|4859',
  'F  St Claude|552|4622','F  Privas|437|4445','F  Palaiseau|215|4843',
  'F  Mimizan|-113|4412','F  Le Trait|49|4929','F  Castres|213|4337',
  'F  Chatellerault|30|4650','F  Zurich|832|4722','F  Raon L''Etape|650|4824',
  'F  Salon de Provence|506|4339','F  La Rochelle|-9|4609',
  'F  Migennes|330|4758','F  Pezenas|324|4328','F  Rixheim|724|4740',
  'F  Tain L''Hermitage|451|4504','F  Evian les Bains|635|4624',
  'F  Bruay en Artois|233|5029','F  Chateau Thierry|324|4903',
  'F  Nyons|510|4422','F  Loudun|5|4701','F  Cusset|328|4608',
  'F  Saintes|-37|4545','F  Bourges|225|4709','F  Montbard|420|4737',
  'F  Compiegne|250|4924','F  Tarnos|-128|4332','F  Trelaze|-30|4726',
  'F  Wassy|458|4830','F  Lillers|228|5035','F  Bourg de Peage|503|4502',
  'F  Ligny en Barrois|520|4836','F  Corbeil Essonnes|229|4836',
  'F  Guingamp|-310|4834','F  Vittel|558|4812','F  Vernon|130|4905',
  'F  Tregunc|-351|4751','F  Chateaubriant|-123|4743',
  'F  Paimboeuf|-202|4717','F  Fourchambault|303|4700','F  Peronne|257|4955',
  'F  Gerardmer|653|4804','F  Barcelonnette|640|4423','F  Marennes|-106|4550',
  'F  Bedarieux|310|4337','F  Aureilhan|6|4315','F  Harfleur|10|4930',
  'F  Cavaillon|502|4350','F  Ste Marie Aux Mines|712|4810',
  'F  St Denis|222|4856','F  Dombasle sur Meurthe|621|4837',
  'F  St Omer|215|5045','F  Istres|459|4331','F  Louhans|512|4638',
  'F  Bordeaux|-30|4452','F  Champagnole|555|4645','F  Beaupreau|-59|4712',
  'F  Mortain|-57|4840','F  Pompey|606|4846','F  Roubaix|310|5040',
  'F  Erstein|738|4825','F  Givors|445|4535','F  Maison Laffitte|209|4857',
  'F  St Pol de Leon|-359|4841','F  Paray le Monial|407|4627',
  'F  Lezignan Corbieres|243|4313','F  Le Pont de Claix|543|4507',
  'F  Chazelles sur Lyon|422|4539','F  Sochaux|651|4731',
  'F  Espalion|247|4432','F  Deauville|-2|4923','F  Cugnaux|120|4332',
  'F  Riorges|402|4602','F  Coueron|-144|4712','F  Avranches|-120|4840',
  'F  Beaumont|305|4544','F  Annemasse|616|4612',
  'F  Nogent le Rotrou|50|4820','F  Carhaix Plouguer|-336|4818',
  'F  Auxerre|332|4748','F  Lavelanet|151|4257','F  Chartres|130|4829',
  'F  Morlaix|-350|4835','F  Desvres|150|5040','F  Orthez|-48|4329',
  'F  Allonnes|10|4758','F  Graulhet|158|4346',
  'F  Chalette sur Loing|244|4800','F  St Avold|643|4906',
  'F  Morteau|635|4703','F  Angouleme|10|4539','F  Tours|40|4722',
  'F  Voiron|535|4522','F  Saumur|-5|4715','F  Lorient|-323|4745',
  'F  Rosendael|225|5102','F  St Fons|452|4542','F  Charolles|416|4627',
  'F  Thaon les Vosges|624|4815','F  Chatillon sur Seine|433|4750',
  'F  St Herblain|-140|4713','F  Mortagne Au Perche|33|4831',
  'F  Auxonne|520|4710','F  Les Sables D''Olonne|-145|4630',
  'F  Lapalisse|338|4615','F  Limoux|212|4304','F  Marseille|522|4318',
  'F  Colombelles|-18|4912','F  Chateaulin|-408|4811','F  Firminy|418|4525',
  'F  Gourdon|123|4444','F  Lanester|-322|4746','F  Issoire|315|4532',
  'F  Port de Bouc|459|4324','F  Tassin la Demi Lune|447|4546',
  'F  Beaulieu sur Mer|720|4342','F  Villard Bonnot|554|4514',
  'F  St Mihiel|532|4848','F  Nanterre|212|4870','F  Evreux|108|4900',
  'F  Concarneau|-356|4752','F  Landerneau|-417|4828','F  Vizille|546|4505',
  'F  Valognes|-128|4930','F  Chaumont|507|4807','F  Commercy|504|4840',
  'F  Lourdes|-3|4306','F  Molsheim|729|4833','F  Semur en Auxois|420|4730',
  'F  St Chely D''Apcher|317|4448','F  Tergnier|317|4940',
  'F  Draguignan|627|4340','F  Guipavas|-429|4826','F  Lesneven|-420|4835',
  'F  Libourne|-14|4455','F  Castelnau|354|4338','F  Fougeres|-114|4821',
  'F  Longwy|545|4930','F  Ploermel|-226|4755','F  Merville|238|5038',
  'F  Jurancon|-23|4317','F  Vesoul|609|4737','F  Trappes|200|4847',
  'F  Lons le Saunier|531|4640','F  Sable sur Sarthe|-20|4750',
  'F  St Brieuc|-246|4830','F  St Chamond|431|4528','F  Rochechouart|49|4550',
  'F  Les Andelys|124|4914','F  Coutras|-8|4503','F  Cherbourg|-140|4939',
  'F  Hennebont|-319|4749','F  Neufchatel en Bray|126|4944',
  'F  Toulon|556|4307','F  Talmont|-136|4628','F  Juan les Pins|706|4334',
  'F  Audun le Tiche|556|4927','F  Fontainebleau|240|4824',
  'F  Chateaudun|120|4803','F  Poligny|543|4650','F  Casteljaloux|6|4419',
  'F  Achicourt|244|5017','F  Conde sur Noireau|-33|4851',
  'F  Conde sur L''Escaut|326|5026','F  Lisieux|12|4910',
  'F  Decazeville|215|4434','F  Honfleur|12|4925','F  Quimper|-409|4800',
  'F  Lectoure|38|4356','F  Valenciennes|334|5020',
  'F  Castelnaudary|158|4320','F  Neuville|107|4956','F  Perpignan|253|4242',
  'F  Yzeure|322|4633','F  Landivisiau|-406|4831','F  Granville|-135|4850',
  'F  Clermont|224|4923','F  Hasparren|-118|4324','F  Schiltigheim|745|4833',
  'F  Bourbon Lancy|345|4637','F  Chamonix Mont Blanc|651|4555',
  'F  Lillebonne|32|4930','F  St Raphael|646|4325','F  Bar sur Aube|440|4814',
  'F  Pont du Chateau|315|4546','F  Tonnay Charente|-55|4556',
  'F  St Egreve|542|4513','F  Brignoles|605|4325','F  Vertou|-128|4710',
  'F  Coutances|-128|4903','F  Outreau|136|5040','F  Selestat|726|4816',
  'F  Ensisheim|721|4752','F  Grand Couronne|101|4921',
  'F  Montauban|121|4400','F  St Cyr L''Ecole|204|4847',
  'F  Aix en Provence|527|4332','F  Illiers Combray|115|4818',
  'F  Villenave D''Ornon|33|4446','F  Villefranche/rouergu|202|4421',
  'F  Doullens|220|5010','F  Villefranche|719|4342',
  'F  Charleville Mezieres|442|4946','F  Troyes|403|4819',
  'F  Guilvinec|-417|4748','F  Villefranche/lauraga|144|4325',
  'F  Bischwiller|750|4841','F  Oullins|449|4543',
  'F  Villefranche/saone|443|4600','F  Thouars|-12|4659',
  'F  Bourg St Andeol|439|4423','F  St Gilles Croix/vie|-155|4641',
  'F  Bar sur Seine|422|4807','F  Aire sur la Lys|222|5037',
  'F  St Marcellin|520|4509','F  St Gilles|426|4340','F  St Pons|245|4330',
  'F  Confolens|40|4601','F  Moulins|319|4635','F  Octeville|-140|4938',
  'F  Biarritz|-133|4329','F  St Mandrier sur Mer|557|4304',
  'F  Nuremberg|1105|4926','F  Ste Menehould|454|4905','F  Sorgues|453|4401',
  'F  Woippy|609|4909','F  Chantilly|229|4912','F  Gueugnon|403|4636',
  'F  Montceau les Mines|423|4640','F  St Genis Laval|448|4542',
  'F  Soyaux|12|4539','F  Taverny|213|4902','F  Manosque|547|4350',
  'F  Maintenon|135|4835','F  Bouligny|544|4918','F  Domfront|-39|4836',
  'F  Lannemezan|23|4308','F  Nemours|240|4816','F  Vincennes|227|4851',
  'F  Bort les Orgues|229|4524','F  St Paul les Dax|-103|4344',
  'F  Clermont Ferrand|305|4547','F  Echirolles|544|4508',
  'F  Fourmies|402|5001','F  St Germain en Laye|206|4854',
  'F  Pont de Roide|645|4723','F  Joue les Tours|40|4721',
  'F  Cagnes sur Mer|709|4340','F  Lesparre Medoc|-57|4518',
  'F  Hombourg Haut|646|4907','F  Grande Synthe|218|5101',
  'F  Carcassonne|220|4313','F  Le Pontet|452|4358','F  Forcalquier|547|4358',
  'F  Lormont|-30|4452','F  Solesmes|330|5010','F  Yvetot|44|4937',
  'F  Arcis sur Aube|410|4832','F  Crepy en Valois|254|4914',
  'F  Bully les Mines|244|5027','F  La Voulte sur Rhone|446|4448',
  'F  St Sever|-35|4345','F  Rochefort|-57|4556','F  Pertuis|530|4342',
  'F  Oyonnax|540|4616','F  Pornichet|-220|4715','F  Armentieres|250|5040',
  'F  Rambouillet|148|4840','F  Parthenay|-16|4638',
  'F  Pont L''Eveque|11|4917','F  St Brevin les Pins|-210|4714',
  'F  Pont Audemer|30|4921','F  Neuves Maisons|605|4836',
  'F  Valentigney|650|4728','F  Tonnerre|359|4751','F  Largentiere|418|4434',
  'F  Vierzon|205|4713','F  Montbeliard|648|4731','F  Vauvert|417|4341',
  'F  Colomiers|121|4326','F  Montmedy|520|4930',
  'F  Beaumont sur Oise|217|4908','F  Bagnols sur Ceze|436|4410',
  'F  St Gaudens|44|4306','F  Gujan Mestras|-104|4438',
  'F  Ste Livrade sur Lot|36|4424','F  St Dizier|456|4838',
  'F  Freyming Merlebach|647|4909','F  Boulogne sur Mer|136|5042',
  'F  Sanvignes les Mines|418|4640','F  Bourganeuf|145|4557',
  'F  Nontron|40|4531','F  Tonneins|20|4424','F  Dieulouard|604|4851',
  'F  Hazebrouck|231|5042','F  Munster|708|4802','F  St Astier|31|4508',
  'F  St Flour|306|4502','F  Bourgoin Jallieu|517|4536',
  'F  St Etienne|424|4527','F  Chalon sur Saone|450|4648',
  'F  Mondeville|-18|4910','F  Poitiers|20|4635','F  Blanquefort|-38|4455',
  'F  Ribeauville|720|4810','F  Montchanin|430|4647','F  Bonneville|624|4604',
  'F  Rumilly|556|4553','F  St Julien/genevois|605|4609',
  'F  Ste Adresse|6|4931','F  St Etienne/rouvray|106|4923',
  'F  St Junien|55|4553','F  Clermont L''Herault|302|4338',
  'F  La Tour du Pin|527|4533','F  Chalons sur Marne|420|4858',
  'F  St Nicolas de Port|618|4838','F  Aubusson|211|4557',
  'F  Rambervillers|638|4820','F  Luneville|630|4836',
  'F  Gravelines|207|5059','F  Hautmont|355|5015','F  Amplepuis|420|4558',
  'F  Montereau Fault Yonn|257|4822','F  Mont St Aignan|104|4929',
  'F  Montdidier|235|4938','F  Fontenay le Comte|-48|4628',
  'F  St Eloy les Mines|250|4609','F  Argenton sur Creuse|130|4636',
  'F  St Nazaire|-212|4717','F  Barbezieux|-8|4528','F  Pontoise|206|4903',
  'F  Martigues|503|4324','F  Chateauroux|142|4649','F  Haubourdin|259|5037',
  'F  Albertville|622|4540','F  Provins|315|4833','F  Chauvigny|40|4634',
  'BD Dacca|9026|2343','F  St Martin D''Heres|545|4509',
  'F  Cosne sur Loire|254|4724','F  Ste Savine|403|4818',
  'F  Margny les Compiegne|248|4925','F  Bouguenais|-137|4710',
  'F  Mulhouse|721|4745','F  Guebwiller|712|4755','F  Labruguiere|216|4331',
  'F  Pont A Mousson|601|4854','F  Noeux les Mines|239|5029',
  'F  St Louis|734|4730','F  Chantonnay|-103|4640','F  Vallauris|703|4335',
  'F  Marvejols|318|4433','F  Les Mureaux|156|4900','F  Carpentras|502|4403',
  'F  L''Isle sur la Sorgue|502|4355','F  Ille sur Tet|238|4240',
  'F  Puget Theniers|654|4357','F  Castelsarrasin|107|4402',
  'F  Quimperle|-333|4753','F  Montargis|243|4800',
  'F  Sarreguemines|704|4905','F  Dunkerque|223|5102',
  'F  Villeurbanne|455|4546','F  Bressuire|-29|4651',
  'F  Dives sur Mer|-6|4917','F  Vitry le Francois|435|4844',
  'F  St Affrique|253|4357','F  Tournon|450|4404','F  Hericourt|646|4732',
  'F  St Servan sur Mer|-200|4838','F  St Juery|212|4557',
  'F  Moelan sur Mer|-338|4749','F  St Vallier|422|4638',
  'F  Frontignan|345|4327','F  Scionzier|633|4603','F  Homecourt|559|4913',
  'F  Wimereux|137|5045','F  Le Creusot|426|4648',
  'F  Aulnoye Aymeries|350|5012','F  Neuville sur Saone|450|4552',
  'F  Longjumeau|218|4842','F  Sisteron|556|4416','F  Bourbourg|212|5056',
  'F  Les Ponts de Ce|-31|4724','F  Gournay en Bray|144|4929',
  'F  Montelimar|445|4433','F  Moutiers|632|4529','F  Ollioules|550|4308',
  'F  Suresnes|213|4851','F  St Girons|108|4259',
  'F  Luxeuil les Bains|624|4749','F  Louviers|110|4912',
  'F  Cornimont|650|4758','F  Montpellier|352|4337','F  Pontivy|-259|4805',
  'F  Pont Ste Maxence|235|4918','F  Thonon les Bains|629|4622',
  'F  Issoudun|200|4657','F  Mirecourt|610|4820','F  Tourcoing|310|5042',
  'F  Versailles|208|4848','F  Aussillon|222|4329','B  Gand|344|5104',
  'F  Douarnenez|-421|4806','F  Longuyon|536|4927','F  Biscarrosse|-112|4424',
  'F  Ars sur Moselle|604|4908','F  Pierrelatte|443|4423',
  'F  Coulommiers|303|4850','F  Coulounieix Chamiers|42|4511',
  'F  Sarrebourg|703|4843','F  Montpon Menesterol|11|4502',
  'F  St Maixent L''Ecole|-12|4624','F  Verneuil sur Avre|55|4845',
  'F  Avesnes sur Helpe|355|5008','F  Faulquemont|636|4903',
  'F  Trevoux|447|4557','CH Bale|736|4733','F  St Priest|457|4542',
  'F  Audincourt|650|4730','F  Wittenheim|720|4749','F  Perigueux|42|4510',
  'F  Thionville|610|4920','F  Petit Couronne|102|4923',
  'F  Montlucon|236|4622','F  Montreuil|146|5028',
  'F  Villeneuve/avignon|449|4357','F  Villeneuve sur Lot|42|4424',
  'F  Pont St Esprit|440|4416','F  Perros Guirec|-337|4849',
  'F  St Avertin|44|4722','F  Pontarlier|620|4654','F  Tournus|454|4635',
  'F  Toulouse|127|4337','F  Plougastel Daoulas|-423|4822',
  'F  Portes les Valence|454|4452','F  St Florentin|345|4800',
  'F  St Florent sur Cher|215|4659','F  St Cyprien|102|4453',
  'F  Montigny les Metz|609|4906','F  St Yrieix la Perche|112|4531',
  'F  Soissons|319|4925','F  Le Treport|121|5003','E  Jaen|-348|3746',
  'F  Rivesaltes|250|4247','F  Montmorency|220|4859',
  'F  Wittelsheim|715|4749','F  Remiremont|636|4800','D  Aachen|604|5047',
  'GE Bata|950|150','F  Moyeuvre Grande|602|4915',
  'F  Six Fours les Plages|550|4305','F  Longuenesse|214|5045',
  'F  Port Vendres|308|4232','E  Elche|-42|3815',
  'F  Nogent sur Seine|330|4830','F  Nogent sur Marne|229|4800',
  'F  Nogent sur Oise|227|4916','F  Oloron Ste Marie|-36|4312',
  'F  Creutzwald|642|4912','D  Hagen|729|5121','F  Trouville sur Mer|5|4921',
  'F  Plouguerneau|-430|4836','B  Liege|535|5038','E  Malaga|-425|3643',
  'F  Vouziers|440|4925','F  Montivilliers|12|4933','F  Pithiviers|213|4810',
  'F  Villerupt|555|4928','D  Kiel|1008|5420','GH Accra|-6|535',
  'F  Equeurdreville Hainn|-140|4940','F  Goussainville|227|4902',
  'R  Arad|2120|4610','F  Romorantin Lanthenay|145|4721','CO Cali|-7631|327',
  'J  Kobe|13512|3440','ADNAden|4500|1250','F  Romans sur Isere|503|4503',
  'F  Basse Yutz|611|4921','MA Fes|-500|3405','F  Neuilly sur Seine|220|4850',
  'F  St Tropez|638|4316','F  St Quentin|316|4950','F  St Quentin|316|4950',
  'F  Sotteville les Rouen|105|4924','F  Montbrison|403|4536',
  'I  Come|905|4548','P  Braga|-832|4135','F  Noirmoutier|-214|4700',
  'F  Noirmoutier en L''Ile|-215|4700','F  St Pol sur Ternoise|220|5023',
  'F  Strasbourg|745|4835','E  Bilbao|-256|4315','E  Cadix|-620|3630',
  'R  Bacau|2655|4635','IL Haifa|3500|3246',
  'F  Mourenx Ville Nouvel|-38|4322','F  Montmorillon|50|4626',
  'D  Breme|847|5304','F  Tourlaville|-133|4938','E  Palma|239|3933',
  'SA Djedda|3916|2129','F  St Cyr sur Mer|543|4311','MA Safi|-917|3220',
  'D  Bonn|706|5043','F  Romilly sur Seine|344|4831','F  Yssingeaux|408|4509',
  'F  Wissembourg|757|4902','CH Basel|736|4733','E  Avila|-443|4039',
  'E  Leon|-534|4235','Q  Duha|5132|2515','A  Wien|1622|4812',
  'E  Cuenca|-210|4005','A  Graz|1527|4704','I  Catane|1504|3731',
  'CI Abidjan|-358|526','MA Agadir|-935|3028','GB Leeds|-135|5350',
  'I  Foggia|1531|4128','E  Lerida|38|4137','E  Madrid|-343|4025',
  'E  Albacete|-150|3900','INDAgra|7758|2217','CH Berne|728|4657',
  'E  Badalona|215|4126','TCHAbeche|2035|1350','EC Cuenca|-7909|-250',
  'D  Hagnau|910|4745','MA Rabat|-651|3402','D  Koln|658|5056',
  'GB Cardiff|-311|5128','I  Roma|1230|4154','PE Lima|-7703|-1206',
  'D  Hagnau|910|4745','DDRGera|1205|5053','BR Belem|-4830|-120',
  'J  Osaka|13530|3440','F  Portet sur Garonne|125|4331','DZ Blida|249|3630',
  'D  Lubeck|1040|5352','I  Pise|1023|4343','I  Milan|910|4528',
  'E  Vigo|-844|4215','I  Genes|856|4424','E  Caceres|-623|3926',
  'E  Grenade|-335|3710','S  Umea|2015|6350','BG Sofia|2318|4240',
  'TR Adana|3516|3700','CH Bienne|714|4708','I  Bergame|940|4542',
  'I  Rome|1230|4154','E  Gijon|-542|4332','E  Lugo|-735|4302',
  'DZ Arak|400|2529','I  Ancone|1330|4337','E  Sabadell|207|4133',
  'R  Braila|2759|4519','ET Imbabah|3112|3005','SD Mbabane|3120|-2610',
  'F  Mitry Mory|239|4859','B  Arlon|549|4942','A  Linz|1418|4819',
  'GB Hull|-20|5345','I  Udine|1314|4605','I  Pavie|910|4510',
  'I  Parme|1020|4450','E  Huesca|-25|4208','R  Oradea|2158|4702',
  'ET Qena|3243|2610','J  Sendai|13017|3150','INDAhmadabad|7240|2300',
  'DZ Annaba|746|3650','B  Mons|328|5027','D  Coblence|726|5021',
  'GB Derby|-128|5255','D  Aix la Chapelle|604|5047','IRQBagdad|4430|3320',
  'PA Panama|-7931|858','ALGAlger|308|3642','D  Bielefeld|831|5202',
  'D  Berlin|1334|5232','E  Badajoz|-659|3850','E  Almeria|-232|3652',
  'H  Debrecen|2142|4733','DDRHalle|1200|5129','R  Cluj|2338|4647',
  'ZA Le Cap|1827|-3356','MA Oujda|-145|3441','D  Krefeld|632|5120',
  'I  Modene|1055|4439','N  Bergen|520|6023','BG Varna|2756|4313',
  'PE Callao|-7700|-1200','INDDelhi|7771|2838','IR Meched|5934|3616',
  'F  Nouzonville|444|4948','DZ Bone|746|3650','D  Essen|659|5128',
  'D  Bochum|712|5128','I  Brescia|1013|4533','E  Tolede|-402|3950',
  'S  Gavle|1713|6041','RCHTalca|-7140|-3528','BR Recife|-3452|-806',
  'BR Maceio|-3544|-940','CDNMtl|-7300|4500','DZ Bechar|218|3138',
  'E  Soria|-228|4146','E  Valence|-23|3927','GH Tamale|-50|926',
  'CI Bouake|-502|740','C  La Havane|-8222|2308','DZ Djelfa|315|3440',
  'TN Gabes|1006|3352','SN Dakar|-1729|1434','B  Namur|452|5027',
  'CH Geneve|609|4612','I  Forli|1202|4414','I  Aoste|720|4543',
  'I  Cagliari|906|3915','E  Gerone|246|4158','E  Marbella|-457|3630',
  'RN Agades|759|1658','WANIbadan|358|722','INDAllahabad|8158|2525',
  'IR Hamadan|4832|3452','BH Belize|-8810|1719','TN Mahdia|1103|3529',
  'D  Mayence|816|5000','A  Vienne|1622|4812','I  Vicence|1131|4532',
  'E  Alicante|-30|3823','E  Palma de Majorque|239|3933','P  Lagos|-840|3705',
  'DK Alborg|956|5703','SA Medine|3935|2430','MA Casablanca|-735|3339',
  'D  Kassel|932|5119','I  Padoue|1152|4524','E  Ciudad Real|-355|3859',
  'CS Brno|1635|4910','J  Niigata|13902|3758','HKJAmman|3552|3200',
  'DZ Adrar|-11|2751','D  Munich|1135|4808','I  Pescara|1413|4228',
  'TG Lome|114|608','RC Changhai|12130|3115','AFGKandahar|6547|3136',
  'I  Carrare|1007|4405','E  Mataro|229|4132','S  Malmo|1300|5535',
  'H  Gyor|1740|4741','J  Nagoya|13653|3508','J  Nagasaki|12950|3247',
  'DZ Alger|308|3642','B  Bruges|313|5113','GB Belfast|-556|5435',
  'CDNQuebec|-7113|4652','E  Murcie|-108|3759','S  Boras|1256|5743',
  'MALIpoh|10102|426','R  Galazi|2802|4527','B  Malines|429|5102',
  'B  Seraing|532|5036','D  Cologne|658|5056','CDNRegina|-10438|5030',
  'I  Terni|1238|4234','E  Oviedo|-550|4321','S  Kalmar|1622|5640',
  'N  Oslo|1045|5955','SF Lahti|2540|6100','SU Riga|2408|5653',
  'ANGLuanda|1315|-850','ET Sohag|3143|2627','J  Hakodate|14044|4145',
  'C  Marianao|-8229|2303','I  Naples|1415|4050','E  Manresa|150|4143',
  'AL Tirana|1949|4118','RCABangui|1835|423','RC Pekin|11625|3955',
  'AFGKaboul|6910|3430','PA Colon|-7954|922','GB Bradford|-145|5347',
  'P  Evora|-757|3833','DK Odense|1023|5522','MC Monaco|723|4346',
  'BG Burgas|2729|4233','TC Douala|942|403','RA Cordoba|-6410|-3125',
  'SA Riyad|4642|2441','BRNManama|5025|2602','ALGAlgerie|311|3510',
  'DZ Oran|-39|3545','NL La Haye|418|5205','A  Bregenz|945|4730',
  'I  Monza|915|4535','R  Sibiu|2409|4545','ET Le Caire|3114|3001',
  'CO Bogota|-7400|434','BOLCochabamba|-6620|-1715','YEMSana|4412|1521',
  'I  Reggio D''Emilie|1038|4442','DZ Ghardaia|337|3231',
  'MA Tanger|-545|3548','L  Diekirch|610|4952','USAOmaha|-9600|4115',
  'I  Prato|1105|4353','I  Bologne|1120|4430',
  'I  Reggio de Calabre|1538|3807','I  Palerme|1323|3808',
  'E  Zamora|-545|4130','WANKano|831|1200','EMIDoubai|5520|2410',
  'C  Camaguey|-7800|2120','PAKKarachi|6700|2453','I  Ferrare|1136|4450',
  'E  Barcelone|210|4121','ETHAddis Abeba|3842|902','EAUEntebbe|3228|4',
  'MA Meknes|-537|3353','B  Anvers|425|5113','D  Mannheim|829|4928',
  'CH Lugano|857|4601','I  Rimini|1233|4403','E  Orense|-752|4219',
  'E  Guadalajara|-312|4037','P  Coimbre|-827|4015','DK Esbjerg|829|5529',
  'DDRDresde|1345|5102','ET Tanta|3100|3048','EAKMombasa|3940|-404',
  'T  Bangkok|10035|1345','I  L''Aquila|1324|4221','CH St Gall|923|4725',
  'D  Munchen|1135|4808','CDNHalifax|-6335|4438','DK Arhus|1011|5608',
  'N  Drammen|1012|5942','ANGHuambo|1544|-1247','EATKigoma|2936|-452',
  'EAUKampala|3235|20','AUSAdelaide|13832|-3455','RA La Plata|-5755|-3452',
  'GB London|-10|5130','GB Sheffield|-128|5323','I  Pesaro|1253|4355',
  'I  Venise|1220|4527','I  Salerne|1446|4040','BG Pleven|2440|4326',
  'EATTabora|3250|-502','VN Hanoi|10555|2105','INDMadras|8018|1305',
  'MALPenang|10029|525','TN Sfax|1043|3445','B  Ostende|250|5115',
  'NL Haarlem|439|5223','I  Novare|836|4527','PL Gdansk|1840|5422',
  'CS Kosice|2115|4842','Z  Chipata|3228|-1338','TR Ankara|3254|4000',
  'NICManagua|-8618|1206','CH La Chaux de Fonds|650|4707',
  'DZ Skikda|654|3653','DZ Tolga|520|3451','NL Arnhem|555|5158',
  'PL Lodz|1928|5149','GUIKindia|-1252|1000','EAKNairobi|3648|-117',
  'RA Santa Fe|-6043|-3138','BOLLa Paz|-6809|-1630','INDBombay|7250|1855',
  'IRQBasra|4750|3030','NAUMakwa|16656|-31','B  Hasselt|521|5056',
  'D  Wiesbaden|817|5007','USAMiami|-8015|2545','E  Cordoue|-446|3753',
  'P  Aveiro|-838|4037','P  Covilha|-731|4017','IRLCork|-830|5154',
  'DDRBerlin|1324|5232','ETHAsmara|3855|1519','MADMadagascar|4600|-1900',
  'NCANoumea|16626|-2216','D  Hanovre|943|5223','USAChicago|-8740|4145',
  'I  Florence|1115|4347','E  Carthagene|-59|3738','DK Kolding|929|5530',
  'R  Craiova|2348|4421','SU Kiev|3028|5030','ET Zifta|3114|3043',
  'RM Mahajanga|4625|-1540','RMMBamako|-755|1234','ZA Durban|3101|-2949',
  'NEPPatan|-8520|2740','PAKLahore|7422|3134','CDNCalgary|-11410|5100',
  'I  Ravenne|1212|4425','I  Verone|1100|4527','DK Viborg|923|5627',
  'CO Cartagena|-7533|1025','RC Canton|11306|2306','MEXLeon|-10142|2110',
  'FJISuva|17825|-1808','CDNGranby|-7300|4500','DZ Setif|524|3611',
  'NL Enschede|653|5213','D  Hambourg|959|5332','CH Lucerne|817|4703',
  'I  Plaisance|942|4502','I  Vicenza|1131|4532','P  Coruche|-830|3857',
  'PL Danzig|1840|5422','ANGBenguela|1325|-1237','GUIKankan|-911|1022',
  'GH Kumasi|-135|645','MOZBeira|3452|-1950','PE Cuzco|-7159|-1331',
  'BR Manaus|-6000|-306','C  Holguin|-7615|2054','DZ Biskra|600|3453',
  'USADallas|-9650|3250','I  Viterbe|1208|4225',
  'E  Jerez de la Frontera|-607|3641','DK Herning|858|5608',
  'CS Prague|1425|5005','SU Bakou|4945|4025','EC Quito|-7830|-15',
  'MO Mascate|5838|2337','CL Colombo|7958|656','RI Jakarta|10649|-609',
  'RI Bandung|10748|-636','DZ Sidi Bel Abbes|-39|3515',
  'B  Charleroi|427|5024','GB Swansea|-357|5137','I  Turin|740|4503',
  'I  Trente|1106|4605','RWAKigali|3005|-159','WAGBanjul|-1640|1328',
  'Z  Lusaka|2820|-1526','BR Brasilia|-4755|-1547','MA Kenitra|-640|3415',
  'MA Marrakech|-800|3149','B  Anderlecht|419|5050','I  Tarente|1715|4030',
  'I  Cosenza|1614|3917','S  Orebro|1513|5917','V  Vatican|1227|4154',
  'FL Vaduz|931|4708','WANLagos|328|627','CO Medellin|-7535|615',
  'MEXMerida|-8939|2059','IR Chiraz|5230|2942','C  Santa Clara|-7958|2225',
  'GCAGuatemala|-9031|1438','TCHN''Djamena|1459|1210',
  'MA Sidi Ifni|-1018|2940','GB Glasgow|-414|5552','I  Messine|1533|3813',
  'I  Brindisi|1755|4039','H  Tatabanya|1825|4732','MW Zomba|3522|-1522',
  'YV Caracas|-6655|1030','C  Santiago de Cuba|-7549|2000',
  'GUAAbymes|-6130|1617','USATacoma|-12230|4715','I  Bolzano|1120|4630',
  'GR Rhodes|2814|3625','DK Randers|1002|5629','SF Oulu|2529|6501',
  'ET El Mahallet Elkoubra|3100|3100','ADNMadinat Al Chaab|4456|1250',
  'BT Punakha|8952|2742','DZ Ain Salah|232|2710','GUAMoule|-6121|1620',
  'I  Sassari|833|4044','I  Agrigente|1333|3719','E  La Corogne|-823|4322',
  'P  Carnaxide|-914|3843','GR Le Piree|2342|3757','CS Plzen|1322|4945',
  'R  Brasov|2539|4507','INDHyderabad|7829|1710','IR Ispahan|5141|3241',
  'GB Londres|-10|5130','GB Blackpool|-303|5348','E  Algesiras|-528|3609',
  'P  Setubal|-855|3830','H  Budapest|1905|4729','ET Suez|3233|2959',
  'ZREMbandaka|1828|3','RA Avellaneda|-5810|-3450',
  'BR Rio de Janeiro|-4317|-2253','J  Tokyo|13945|3540','J  Kyoto|13545|3500',
  'J  Fukuoka|13021|3339','SYRAlep|3715|3610','BS Nassau|-7720|2505',
  'PAKHyderabad|6836|2523','DZ Khenchela|709|3522','USAMobile|-8805|3040',
  'E  Valladolid|-443|4138','GR Athenes|2346|3758','RB Gaborone|2555|-2445',
  'AUSBendigo|14415|-3640','PE Chiclayo|-7950|-642','RA Mendoza|-6852|-3250',
  'SA La Mecque|3949|2126','SALGuadalcanal|16000|-940','B  Brussel|421|5051',
  'CH Lausanne|639|4632','I  Pistoia|1054|4355','I  Mantoue|1047|4510',
  'I  La Spezia|950|4408','CS Karvina|1825|4953','ET Ismailia|3218|3037',
  'SOMBerbera|4502|1030','IR Teheran|5126|3540','SALHoniara|16000|-940',
  'ROKTaegu|12837|3550','RI Palembang|10445|-259','D  Marbourg|844|5049',
  'E  Vitoria|-241|4250','H  Ujpest|1906|4722','RN Niamey|205|1332',
  'CO Bucaramanga|-7310|708','J  Yokohama|13928|3528','MEXPuebla|-9810|1903',
  'CH Neuchatel|655|4700','I  Arezzo|1150|4328','P  Porto|-837|4109',
  'GR Patras|2144|3814','DK Thisted|840|5658','YU Rijeka|1427|4520',
  'YU Belgrade|2037|4450','SU Gorki|4400|5620','ANGMocamedes|1210|-1510',
  'RA Mar Del Plata|-5735|-3801','SYRDamas|3618|3330','RP Manille|12059|1436',
  'CDNOttawa|-7542|4527','I  Reggio Nell''Emilia|1038|4442',
  'E  Santander|-348|4328','E  Aranjuez|-340|4001','IRLDublin|-618|5320',
  'ET Guizeh|3110|3000','VN Saigon|10643|1046','DZ Tlemcen|-121|3452',
  'GB Brighton|-9|5050','I  Alexandrie|837|4454','P  Barreiro|-906|3840',
  'ET Zagazig|3112|3040','ET Damiette|3148|3124','INDBangalore|7740|1259',
  'CY Nicosie|3322|3510','TW T''Ai Pei|12130|2502','D  Saarbrucken|658|4915',
  'GB Birmingham|-155|5230','GB Edimbourg|-312|5557','GR Corfou|1954|3940',
  'SF Tampere|2345|6130','SU Odessa|3045|4630','LARBenghazi|2003|3211',
  'AUSCanberra|14908|-3515','BR Curitiba|-4915|-2525','IR Tabriz|4620|3807',
  'GB Bristol|-235|5126','USABuffalo|-7850|4255','E  Tarragone|117|4105',
  'GR Larissa|2225|3938','PL Cracovie|1957|5004','ET El Minya|3033|2807',
  'DJ Djibouti|4309|1136','RCHLa Serena|-7110|-2955','INDNagpur|7910|2108',
  'MONOurga|10653|4755','CR San Jose|-8404|959',
  'D  Francfort sur Main|233|4854','DZ Ouargla|516|3200',
  'GB Leicester|-105|5238','I  Trieste|1345|4539','S  Uppsala|1738|5953',
  'YU Zagreb|1558|4548','CS Trencin|1804|4852','EATDar Es Salaam|3912|-650',
  'AUSHobart|14721|-4250','RI Semarang|11029|-658',
  'E  Castellon/plana|-3|4000','P  Lisbonne|-908|3844','PL Breslau|1700|5105',
  'PL Zabrze|1850|5024','BG Rousse|2559|4348','SU Minsk|2730|5352',
  'AUSGeelong|14420|-3802','RCHTemuco|-7240|-3845','WD Roseau|-6124|1518',
  'A  Salzburg|1303|4754','GUAMorne A L''Eau|-6131|1620',
  'ANDAndorre la Vieille|132|4231','D  Gelsenkirchen|705|5130',
  'CH Fribourg|709|4649','USASanta Fe|-10557|3541','I  Lucques|1030|4350',
  'I  Trevise|1215|4540','P  Santarem|-842|3912','R  Bucarest|2610|4427',
  'SOUEl Obeid|3010|1308','NZ Auckland|17446|-3652',
  'C  Cienfuegos|-8030|2210','L  Grevenmacher|626|4951',
  'I  Catanzaro|1638|3854','I  Perouse|1224|4306','E  Pampelune|-138|4248',
  'GR Volos|2259|3924','DK Roskilde|1203|5538','S  Goteborg|1159|5743',
  'GUIBissau|-1545|1145','TC Yaounde|1131|351','LS Maseru|2729|-2919',
  'AUSPerth|11550|-3157','AUSBallarat|14350|-3733','BR Santos|-4622|-2356',
  'INDCalcutta|8824|2236','INDKanpur|8023|2626','USADenver|-10500|3945',
  'USAEl Paso|-10629|3145','E  Saragosse|-53|4139','E  Salamanque|-539|4058',
  'BG Plovdiv|2444|4208','PE Arequipa|-7130|-1620',
  'RCHVina Del Mar|-7135|-3300','C  Guantanamo|-7514|2009',
  'MARRobert|-6057|1440','MA Tetouan|-521|3535','GB Middlesbrough|-114|5435',
  'USAAtlanta|-8424|3350','DDRLeipzig|1220|5120','YV Maracaibo|-7137|1044',
  'BR Niteroi|-4306|-2254','J  Sapporo|14121|4305','J  Hiroshima|13230|3430',
  'BD Chittagong|9155|2219','C  Guantanamo|-7514|2009',
  'GB Newcastle Upon Tyne|-137|5459','POLPapeete|-14934|-1732',
  'I  Alessandria|837|4454','I  Benevento|1445|4107',
  'M  La Valette|1431|3554','SU Lvov|2400|4952','SOUKodok|3207|953',
  'AUSBrisbane|15254|-2725','NZ Dunedin|17033|-4550','MEXMexico|-9909|1924',
  'NAUNauru|16656|-31','D  Oberhausen|650|5128','CANLas Palmas|-1528|2810',
  'P  Vila Nova de Gaia|-840|4104','DK Nykobing|1150|5451',
  'SF Helsinki|2503|6015','SF Kuopio|2735|6253',
  'ET Medinet El Fayoum|3050|2919','BR Salvador|-3830|-1258',
  'INDVaranasi|8300|2520','BURMandalay|9604|2157','A  Innsbruck|1113|4716',
  'D  Dortmund|728|5132','CDNHamilton|-7950|4315','I  Campobasso|1440|4134',
  'E  Tortosa|31|4049','DK Horsens|951|5552','GH Sekondi Takoradi|-144|457',
  'TR Izmir|2710|3825','C  Sancti Spiritus|-7928|2155','SKNNevis|-6235|1711',
  'DK Hjorring|959|5729','PL Poznan|1653|5225','DDRPotsdam|1304|5223',
  'DDRErfurt|1102|5058','R  Ploesti|2601|4457','RA Rosario|-6040|-3300',
  'L  Esh sur Alzette|559|4932','DZ Laghouat|258|3349',
  'D  Augsbourg|1054|4822','GB Manchester|-215|5330',
  'USASan Diego|-11710|3245','I  Spolets|1244|4244','PL Katowice|1859|5015',
  'VN Ho Chi Minh Ville|10643|1046','GBJSt Helier|-206|4911',
  'ROKPusan|12900|3505','RI Surabaya|11245|-715','A  Klagenfurt|1420|4638',
  'SF Turku|2215|6027','GABLibreville|925|30','MEXCiudad Juarez|-10629|3144',
  'HK Victoria|11413|2217','NAUYangor|16656|-31','ROKSeoul|12658|3733',
  'MARFrancois|-6054|1436','TN Tunis|1013|3650','D  Karlsruhe|823|4903',
  'USAColumbia|-8103|3400','USABismarck|-10049|4649',
  'MC Monte Carlo|723|4346','SYRHoms|3645|3440','BT Thimphu|8940|2730',
  'ES San Salvador|-8910|1340','MADDiego Suarez|4917|-1219',
  'B  Antwerpen|425|5113','CDNWinnipeg|-9710|4953','CDNVictoria|-12320|4826',
  'DK Frederikshavn|1032|5726','CS Ostrava|1813|4950',
  'ET Alexandrie|3000|3100','CO Manizales|-7532|503',
  'MEXGuadalajara|-10320|2030','DOMSantiago|-7040|1930',
  'E  St Sebastien|-159|4319','DZ Tindouf|810|2742','TN Bizerte|950|3715',
  'USACleveland|-8143|4128','CDNMontreal|-7334|4531','IRLLimerick|-838|5240',
  'DDRMagdebourg|1137|5208','SOUKassala|3630|1524','WANOshogbo|437|748',
  'GUYCayenne|-5220|456','MARLamentin|-6101|1437','B  Bruxelles|421|5051',
  'NL Amsterdam|454|5223','D  Duisbourg|642|5127','D  Sarrebruck|658|4915',
  'GB Newport|-118|5042','USAOklahoma City|-9733|3528',
  'USACheyenne|-10449|4109','I  Syracuse|1517|3704','N  Trondheim|1023|6336',
  'DDRZwickau|1230|5043','ET Damanhour|3030|3100',
  'RA San Miguel/tucuman|-6515|-2647','BR Sao Paulo|-4639|-2333',
  'REUSt Leu|5518|-2109','NL Utrecht|508|5206','D  Ratisbonne|1207|4901',
  'CDNEdmonton|-11328|5333','DK Svendborg|1035|5504','N  Stavanger|545|5858',
  'SU Moskva|3742|5545','ET Beni Souef|3050|2905','LB Monrovia|-1047|618',
  'JA Kingston|-7648|1758','K  Phnom Penh|10455|1133',
  'A  Salzbourg|1303|4754','MARSte Marie|-6100|1447','MA Essaouira|-942|3132',
  'NL Eindhoven|530|5126','A  Salzbourg|1303|4754',
  'USASalt Lake City|-11158|4045','USASpokane|-11725|4740',
  'DK Helsingor|1235|5602','YU Skopje|2128|4201','YU Maribor|1540|4635',
  'YU Split|1626|4331','SU Tachkent|6913|4116','EC Guayaquil|-7954|-213',
  'MEXChihuahua|-10603|2840','IL Tel Aviv Jaffa|3448|3204',
  'D  Flensbourg|928|5446','USASeattle|-12220|4735','PL Wroclaw|1700|5105',
  'R  Timisoara|2115|4543','EATZanzibar|3912|-610',
  'RA Buenos Aires|-5820|-3430','BR Sao Luiz|-4416|-234',
  'BRUBandar Seri Baqawan|11500|450','GBZGibraltar|-521|3609',
  'SP Sao Tome|643|19','MARFort de France|-6102|1436',
  'D  Brunswick|1028|5217','USAMemphis|-9000|3510','S  Vasteras|1632|5936',
  'DDRKarl Marx Stadt|1255|5050','DDRChemnitz|1255|5050',
  'SU Leningrad|3025|5955','GUIConakry|-1349|929',
  'RM Antananarivo|4730|-1852','BR Fortaleza|-3835|-345',
  'HK Kowloon|11410|2218','DOMS.francisco/macoris|-7015|1919',
  'GUAPointe A Pitre|-6132|1614','REUSt Andre|5539|-2057',
  'USAAustin|-9745|3020','USARichmond|-7727|3733','I  Livourne|1018|4333',
  'E  Pontevedra|-840|4226','HV Bobo Dioulasso|-413|1108',
  'IL Jerusalem|3513|3147','BURRangoon|9610|1647','SP Principe|727|137',
  'USASan Francisco|-12230|3735','USABoston|-7100|4220',
  'S  Linkoping|1535|5825','SU Moscou|3742|5545','SU Kharkov|3615|4959',
  'RCHConcepcion|-7303|-3650','INDLucknow|8058|2650',
  'GBGSt Pierre Port|-232|4928','WG St George''S|-6140|1205',
  'D  Dusseldorf|646|5115','USADuluth|-9210|4648','CS Bratislava|1707|4810',
  'DDRRostock|1209|5406','ET Port Said|3218|3116','LAOVientiane|10238|1759',
  'MA Ouezzane|-535|3452','GB Stoke On Trent|-211|5301',
  'S  Helsingborg|1240|5602','SU Moscow|3742|5545','NL Groningen|635|5315',
  'YU Ljubljana|1430|4604','ET Assiout|3104|2711','SOUEl Fasher|2526|1333',
  'ZA Pretoria|2812|-2544','ZA Springs|2825|-2613',
  'BR Porto Alegre|-5110|-3003','RL Tripoli|3550|3427',
  'WL Castries|-6050|1400','USASt Paul|-9310|4500','REULe Port|5518|-2050',
  'GB Nottingham|-110|5257','E  Hospitalet|206|4121','S  Jonkoping|1410|5745',
  'YU Novi Sad|1951|4515','SOUMongalla|3142|512','LARTripoli|1312|3253',
  'NZ Wanganui|17500|-3956','BR Belo Horizonte|-4356|-1955',
  'RM Diego Suarez|4517|-1219','GB Coventry|-131|5225',
  'USALos Angeles|-11810|3400','CDNSudbury|-8100|4630',
  'R  Constanza|2838|4414','ZREKinshasa|1518|-418',
  'CO Barranquilla|-7450|1100','PE Iquitos|-7313|-351',
  'SMEParamaribo|-5514|552','TN Sousse|1038|3550','USAPhoenix|-11203|3330',
  'USAPhiladelphie|-7510|4000','USADetroit|-8305|4220',
  'USANorfolk|-7618|3654','SWAWindhoek|1704|-2235','DY Cotonou|225|620',
  'ZA East London|2755|-3300','NZ Hamilton|17520|-3737',
  'GB Liverpool|-255|5325','USANew Haven|-7254|4120','PL Szczecin|1432|5325',
  'MW Blantyre|3500|-1545','AUSSydney|15110|-3353',
  'RCHAntofagasta|-7030|-2350','NA Willemstad|-6900|1205',
  'REUSt Paul|5517|-2059','REUSt Denis|5527|-2052',
  'RM Fianarantsoa|4700|-1930','ZA Bloemfontein|2614|-2906',
  'ZREKisangani|2515|35','MALKuala Lumpur|10141|309',
  'REUSte Marie|-5533|-2053','USABirmingham|-8650|3331',
  'S  Stockholm|1803|5920','ET Mansourah|3119|3100',
  'AUSFremantle|11547|-3201','BR Joao Pessoa|-3453|-706',
  'NEPKatmandou|8522|2745','GUABasse Terre|-6143|1600',
  'D  Gottinguen|955|5131','D  Wuppertal|708|5115','USABaltimore|-7637|3918',
  'USAIndianapolis|-8610|3945','CDNSaskatoon|-10640|5210',
  'P  Rio Tinto|-834|4111','ZA Johannesburg|2802|-2610',
  'TR Istanbul|2857|4102','USACincinnati|-8426|3910','YU Sarajevo|1826|4352',
  'HV Ouagadougou|-140|1220','PY Asuncion|-5730|-2521','TR Brousse|2905|4015',
  'KWTKoweit|4800|2920','DZ Mostaganem|5|3554','NL Maastricht|542|5051',
  'USAKansas City|-9433|3902','CDNToronto|-7925|4342',
  'RM Antseranana|4920|-1225','PE Trujillo|-7900|-806',
  'HONTegucigalpa|-8714|1405','GB Kingston Upon Hull|-20|5345',
  'GUACapesterre|-6135|1603','TN Tozeur|808|3356','GB Plymouth|-409|5023',
  'PL Varsovie|2100|5215','SU Tbilissi|4448|4143','ANTSt John''S|-6151|1706',
  'REULe Tampon|5532|-2116','NL Rotterdam|430|5155','IS Reykjavik|-2157|6410',
  'MOZMaputo|3235|-2558','RCBPointe Noire|1153|-446',
  'DZ Tamanrasset|530|2250','USAPortland|-12240|4532',
  'USAMilwaukee|-8756|4303','CANSanta Cruz/tenerife|-1745|2441',
  'CANSanta Cruz|-1745|2441','SU Volgograd|4430|4845',
  'TCHFort Lamy|1459|1210','ZA Pietermaritzburg|3025|-2935',
  'MALGeorge Town|10029|525','GB Wolverhampton|-206|5235',
  'CDNVancouver|-12306|4913','SOMMogadiscio|4521|202','WALFreetown|-1317|830',
  'BDSBridgetown|-5930|1300','DZ Hassi Messaoud|620|3202',
  'MARRiviere Pilote|-6054|1430','MONOulan Bator|10653|4755',
  'S  Sundsvall|1720|6222','AUSNewcastle|15146|-3255',
  'RCHValparaiso|-7140|-3305','U  Montevideo|-5610|-3455',
  'RSMSt Marin|1226|4356','RL Beyrouth|3531|3353','SU Stalingrad|4430|4845',
  'ET Heliopolis|3117|3006','LARTarabulus|1312|3253',
  'AUSMelbourne|14458|-3745','NZ Invercargill|16821|-4626',
  'GR Thessalonique|2300|4038','REUSt Benoit|5543|-2102',
  'USAMinneapolis|-9315|4500','L  Luxembourg|609|4937',
  'CH St Moritz|950|4630','DZ Philippeville|654|3653',
  'GB Bournemouth|-153|5043','REUSt Pierre|5528|-2119',
  'USALa Nouvelle Orleans|-9003|3000','REUSt Joseph|5537|-2122',
  'GB Southampton|-123|5024','IRQMossoul|4308|3621','REUSt Louis|5525|-2116',
  'CORPyongyang|12545|3901','SU Kouibychev|5010|5310',
  'SU Dniepropetrovsk|3500|4829','SU Irkoutsk|10417|5215',
  'USASt Petersburg|-8240|2745','RCHPuerto Montt|-7300|-4128',
  'CH Winterthur|844|4730','RIMNouakchott|-1558|1809',
  'SOUOmdourman|3228|1537','USAWashington|-7700|3855',
  'NZ Palmerston Nord|17539|-4021','DZ Touggourt|604|3306',
  'D  Wurtzbourg|955|4946','MOZMozambique|4044|-1500'
 );
 NATL = 260;
 ATL : Array[1..NATL] Of String[40] = (
  'MAS|0|-5|-7300|-7000|4300|4100|1','MIC|0|-5|-9400|-8200|4800|4100|2',
  'SOU|0|2|2100|3900|2400|230|3','A  |0|1|930|1720|4900|4610|4',
  'RSR|0|2|2500|3400|-1500|-2300|3','MIN|0|-6|-9700|-8800|5000|4300|5',
  'MIS|1|-6|-9200|-8800|3500|3000|6','B  |0|1|220|630|5131|4930|7',
  'MIS|2|-6|-9500|-8900|4100|3200|8','MON|1|-7|-11600|-10400|4900|4400|6',
  'NEB|0|-6|-10500|-9500|4300|4000|6','C  |0|-5|-8500|-7230|2400|1900|9',
  'NEV|0|-8|-12000|-11400|4300|3500|10','NEW|1|-5|-7300|-7100|4600|4200|11',
  'NEW|2|-5|-7600|-7400|4200|3800|12','D  |0|1|550|1400|5520|4710|13',
  'NEW|3|-5|-8000|-7300|4500|4000|14','NEW|4|-7|-10900|-10200|3800|3100|6',
  'OHI|0|-5|-8500|-8000|4300|3800|15','E  |1|0|-1900|-1300|3000|2700|16',
  'E  |2|1|-1000|500|4400|3500|17','OKL|0|-6|-10300|-9400|3700|3300|6',
  'ORE|0|-8|-12500|-11700|4600|4200|18','F  |0|1|-600|1000|5200|4100|19',
  'BD |0|6|8800|9300|2700|2020|20','PEN|0|-5|-8100|-7400|4200|3900|21',
  'POR|0|-4|-6800|-6500|1900|1700|3','DC |0|-5|-7700|-7700|3900|3800|6',
  'RHO|0|-5|-7200|-7000|4300|4100|12','TEN|0|-6|-9000|-8100|3700|3500|22',
  'TEX|0|-6|-10700|-9300|3700|2500|6','H  |0|1|1600|2300|4845|4540|23',
  'EC |0|-5|-8200|-7500|250|-500|3','UTA|0|-7|-11800|-11000|4400|3500|24',
  'VER|0|-5|-7400|-7100|4500|4200|25','I  |0|1|630|1845|4715|3630|26',
  'GB |0|0|-830|230|6130|4930|27','BG |0|2|2210|2900|4420|4100|28',
  'VIR|1|-5|-8300|-7500|4000|3600|29','J  |0|9|12200|14515|4600|2315|30',
  'BH |0|-6|-8940|-8600|1900|1530|31','GAB|0|1|730|1500|300|-500|32',
  'VIR|2|-5|-8300|-7800|4100|3600|33','K  |0|7|10130|10830|1500|1000|34',
  'JA |0|-5|-7900|-7600|1900|1730|35','CH |0|1|545|1045|4800|4530|36',
  'GCA|0|-6|-9300|-8800|1830|1325|3','L  |0|1|540|635|5015|4925|37',
  'CI |0|0|-850|-200|1100|400|3','GE |0|1|730|1200|430|30|38',
  'WAS|0|-8|-12500|-11700|4900|4500|39','M  |0|1|1330|1500|3700|3530|40',
  'AL |0|1|1900|2110|4250|3930|41','WIS|0|-6|-9300|-8700|4300|4200|42',
  'FLO|0|-5|-8800|-7800|3200|2300|43','N  |0|1|300|3200|7300|5745|44',
  'DJ |0|3|4100|4410|1330|1100|3','LB |0|0|-1250|-700|900|400|45',
  'MA |0|0|-1700|-30|3610|2200|46','AFG|0|5|6000|7510|3840|2900|47',
  'CL |0|5|7930|8200|1000|550|48','DK |0|1|800|1530|5800|5410|49',
  'GH |0|0|-400|130|1200|400|50','NA |0|-5|-7100|-6700|1400|1100|51',
  'ALB|0|-7|-12000|-11000|6000|4900|52','P  |0|0|-1000|-600|4230|3630|53',
  'LAB|0|-4|-7000|-5500|6000|5000|54','ALA|1|-6|-8800|-8500|3500|3000|55',
  'ALA|2|-11|-16500|-15800|7000|5000|56',
  'ALA|3|-10|-15800|-14100|7000|5000|57','Q  |0|3|5000|5215|2700|2400|58',
  'PA |0|-5|-8400|-7700|1000|600|59','EAK|0|3|3300|4230|515|-500|60',
  'ALA|4|-9|-14100|-12000|7000|5000|57','CAL|0|-8|-12500|-11400|4200|3200|61',
  'R  |0|2|2000|3000|4830|4315|62','CO |0|-5|-7930|-6630|1300|500|60',
  'FL |0|1|920|945|4730|4700|63','NCA|0|11|16300|16900|-1900|-2300|64',
  'DAK|1|-6|-10400|-9600|4800|4500|6','S  |0|1|1000|2500|7000|5500|65',
  'RA |0|-4|-7400|-5300|-2100|-5510|66','HK |0|8|11355|11435|2230|2150|38',
  'AND|0|1|115|155|4250|4230|67','ADN|0|3|4130|4700|1730|1200|68',
  'T  |0|7|9600|10630|2100|500|69','SA |0|3|3400|5610|3230|1500|3',
  'RB |0|2|1955|3000|-1700|-2800|70','BR |1|-3|-5500|-3000|500|-3500|71',
  'BR |2|-4|-7000|-5500|500|-3500|72','U  |0|-3|-5900|-5200|-3000|-3500|73',
  'CR |0|-6|-8630|-8200|1130|730|74','BS |0|-5|7940|-7000|2800|2000|75',
  'IL |0|2|3400|3600|3330|2900|76','PE |0|-5|-8200|-6800|0|-1900|77',
  'BT |0|6|8830|9230|2845|2630|69','CS |0|1|1200|2250|5115|4730|78',
  'ANG|0|1|1030|2500|-500|-1900|3','RCA|0|1|1400|2800|1200|200|3',
  'BR |3|-5|-7500|-7000|0|-1200|79','TC |0|1|800|1700|1400|100|3',
  'SD |0|2|3000|3300|-2500|-2800|70','RCB|0|1|1100|1930|450|-510|3',
  'RC |1|5|7000|8000|5000|3000|80','RC |2|6|8000|9500|4500|2500|81',
  'ES |0|-6|-9030|-8730|1445|1230|3','RC |3|7|9500|11000|4500|2000|3',
  'RC |4|8|11000|12500|5500|2000|3','RC |5|9|12500|13500|5500|2000|82',
  'CAR|1|-5|-9000|-7500|3700|3300|6','CV |0|-2|-2600|-2230|2000|1200|83',
  'ET |0|2|2400|3600|3200|2100|84','SF |0|2|1800|3230|7030|5900|85',
  'GR |0|2|1900|2900|4150|3400|86','BDS|0|-4|-5910|-5950|1330|1300|3',
  'Z  |0|2|2130|3400|-730|-1830|3','RH |0|-5|-7500|-7100|2030|1700|3',
  'NL |0|1|300|730|5350|5040|87','DDR|0|1|940|1510|5450|5000|88',
  'MAL|0|7|9900|12000|900|100|89','IR |0|3|4400|6400|4000|2500|51',
  'ZA |0|2|1600|3400|-2130|-3500|90','TG |0|1|-100|230|1200|530|91',
  'WD |0|-4|-6140|-6100|1540|1500|3','NIC|0|-6|-8900|-8200|1500|1000|92',
  'CY |0|2|3200|3500|3600|3400|3','IS |0|0|-2500|-1300|6700|6300|93',
  'PL |0|1|1400|2430|5500|4900|94','EAT|0|3|2800|4200|-30|-1230|95',
  'IND|1|5|6800|9400|3800|800|96','MO |0|4|5200|6000|2700|1700|3',
  'DY |0|1|30|430|1300|530|97','GUA|0|-4|-6153|-6050|1635|1545|3',
  'EAU|0|3|2900|3500|430|-200|98','EMI|0|4|5000|5700|2700|2200|99',
  'DZ |0|1|-930|1300|3800|1800|100','HV |0|0|-600|300|1530|900|3',
  'RL |0|2|3430|3700|3500|3245|101','WG |0|-4|-6200|-6120|1230|1150|3',
  'LAO|0|7|10000|10800|2230|1330|34','LS |0|2|2700|3000|-2800|-3130|70',
  'RM |0|3|4200|5100|-1100|-2700|3','TCH|0|1|1230|2500|2400|630|3',
  'PAK|0|5|6015|7600|3730|2300|102','BOL|0|-4|-7000|-5700|-930|-2200|103',
  'GY |0|-4|-6200|-5600|900|100|104','RN |0|1|0|1700|2500|1100|105',
  'MAR|1|-4|-6200|-6000|1500|1400|3','RCH|0|-4|-7700|-6500|-1700|-5630|106',
  'HKJ|0|2|3430|3945|3400|2830|107','SN |0|0|-1900|-1100|1730|1100|108',
  'COM|0|3|4130|4630|-1100|-1500|3','WAG|0|0|-1730|-1230|1400|1230|109',
  'LAR|0|1|900|2530|3400|1900|110','DOM|0|-5|-7230|-6730|2000|1700|111',
  'RP |0|8|11500|12800|2130|400|112','TN |0|1|700|1200|3800|3000|113',
  'ETH|0|3|3230|4900|1900|230|114','BRN|0|3|5000|5100|2700|2530|115',
  'FJI|0|12|16500|18100|-1500|-2000|116','SP |0|0|600|800|230|0|117',
  'WL |0|-4|-6115|-6040|1415|1330|3','GBZ|0|1|-530|-515|3615|3605|118',
  'NEP|0|5|8000|8830|3030|2600|51','ANT|0|-5|-6230|-6130|1730|1630|119',
  'MW |0|2|3200|3700|-900|-1800|3','VN |0|7|10300|11000|2400|800|120',
  'COR|0|9|12400|13130|4330|3730|121','WAL|0|0|-1400|-1000|1000|600|122',
  'MS |0|4|5700|5815|-1930|-2100|3','HON|0|-6|-8930|-8230|1700|1230|3',
  'GUI|0|0|-1515|-720|1315|630|108','SME|0|-3|-5900|-5300|700|100|123',
  'SAL|0|11|15400|16500|-500|-1300|3','PNG|0|10|14000|16000|0|-1300|3',
  'TR |0|3|2500|4500|4300|3500|124','WAN|0|1|200|1500|1500|400|125',
  'RI |1|7|9000|11500|1500|-1000|126','RI |2|8|10500|13000|1000|-1000|127',
  'RI |3|9|12500|14000|500|-1000|3','RU |0|2|2800|3200|-200|-500|3',
  'IRL|0|0|1100|500|5530|5100|128','COL|2|-8|-14000|-11400|6000|4900|129',
  'ILE|0|-4|-6500|-6100|4800|4500|130','MAN|0|-6|-10300|-9000|6000|4900|131',
  'TT |0|-4|-6210|-6000|1145|950|3','RIM|0|0|-1800|-400|2800|1400|3',
  'NZ |0|12|16300|18000|-3200|-4900|132','SU |1|3|2000|4000|7000|4000|133',
  'SU |2|4|4000|5300|7500|3500|133','BUR|0|6|9200|10135|2900|930|51',
  'BRU|0|8|11330|11700|600|300|134','PY |0|-4|-6330|-5300|-1830|-3130|135',
  'AUS|1|10|14000|15400|-2800|-4000|136',
  'AUS|2|8|11300|12900|-1300|-3600|136','MON|2|7|8600|12000|5400|4100|3',
  'RWA|0|2|2800|3200|-100|-300|3','SGP|0|7|10300|10400|200|100|137',
  'WS |0|-11|-16900|-17500|-1200|-1500|3',
  'AUS|3|9|12800|13900|-1000|-2600|138','TW |0|8|11900|12230|2700|2100|139',
  'YEM|0|3|4300|5400|1900|1200|3','SWA|0|2|1100|2600|-1600|-3000|140',
  'POL|0|-10|-15600|-13300|-500|-2500|3',
  'AUS|4|10|13800|15400|-1000|-2900|141','ROK|0|9|12500|13000|3900|3200|142',
  'IRQ|0|3|3800|4900|3800|2830|143','RMM|0|0|-1300|500|2500|1000|32',
  'REU|0|4|5500|5600|-2000|-2200|3','SKN|0|4|-6330|-6200|1800|1630|3',
  'WV |0|-4|-6130|-6100|1330|1300|3','AUS|5|9|12900|14100|-2600|-3800|144',
  'AUS|6|10|14400|14900|-4000|-4500|145','SU |3|5|5300|6800|7500|3500|133',
  'SU |4|6|6800|8300|7500|3500|133','YU |0|1|1300|2330|4700|4030|146',
  'SU |5|7|8300|9800|7500|3500|145','SU |6|8|9800|11300|7500|4500|133',
  'SU |7|9|11300|12800|7500|4500|133','SU |8|10|12800|14300|7500|4000|133',
  'SOM|0|3|4000|5200|1240|-230|3','YV |0|-4|-7400|-5900|1300|30|81',
  'SU |9|11|14300|15800|7500|4500|133','SU |10|12|15800|17300|7000|4500|147',
  'SU |11|13|17300|19000|7000|6000|147','MEX|1|-6|-10000|-8500|3000|1500|3',
  'MEX|2|-8|-11800|-11000|3500|2300|148',
  'MEX|3|-6|-11500|-10000|3500|1500|149',
  'MEX|4|-8|-11500|-11000|3200|2000|150',
  'MEX|5|-6|-10000|-9800|2000|1800|151',
  'TON|0|12|-17900|-17000|-1500|-2000|3','NEW|5|-4|-7000|-6000|5000|4300|152',
  'NEW|6|-4|-6700|-5900|4700|4200|153','ONT|0|-5|-9500|-7900|6000|4000|154',
  'QUE|0|-5|-7900|-5800|6500|4000|155','SAS|0|-7|-11000|-10100|6000|4800|156',
  'TER|0|-3|-6800|-5000|6000|4600|157','ARI|0|-7|-11500|-10900|3800|3100|158',
  'ARK|0|-6|-9500|-8900|3700|3200|6','CAR|2|-5|-8400|-7800|3600|3200|6',
  'COL|1|-7|-10400|-10200|4200|3600|21','CON|0|-5|-7400|-7200|4300|4000|159',
  'DAK|2|-6|-10400|-9500|4600|4200|6','DEL|0|-5|-7600|-7500|4000|3800|160',
  'GEO|0|-5|-8600|-8000|3500|3000|6','HAW|0|-10|-15800|-15700|2200|2000|161',
  'IDA|0|-7|-11800|-11000|4900|4200|162','SYR|0|2|3500|4300|3800|3200|163',
  'ILL|0|-6|-9200|-8200|4300|3700|164','IND|2|-5|-8800|-8400|4300|3700|165',
  'IOW|0|-6|-9700|-9000|4900|4000|166','WYO|0|-7|-11100|-10400|4500|4100|6',
  'GUY|0|-4|-5500|-5100|600|130|167','KAN|0|-6|-10300|-9400|4000|3700|6',
  'KEN|0|-6|-9000|-8100|4000|3600|6','LOU|0|-6|-9500|-8900|3400|2900|6',
  'MAI|0|-5|-7200|-6600|4800|4200|25','KWT|0|3|4600|4845|3030|2815|3',
  'MOZ|0|2|3000|4200|-1000|-2800|3','MAR|2|-5|-7800|-7500|4000|3700|168'
 );
 NFUSL = 305;
 NFUST = 168;
 FUS : Array[1..NFUSL] Of String[72] = (
  '1201167C01E9EE7801DFEE7701EBC47701E1C476011DC5750113C57B01FFC47901F5C478',
  '01EBC47701E1C4760113C57B0109C57A01FFC47901F5C47801E1C476011DC5750113C57B',
  '0109C57A01F5C47801EBC47701E1C476011DC5750109C57A01FFC4790401167C0109C57A',
  '01FFC47901EBC47701E1C476011DC5750113C57B01FFC47901F5C47801EBC4770155F17B',
  '0187F179017DF1780173F1770169F1760155F17B0191F17A0187F179017DF1780169F176',
  '015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179',
  '013516BA0183AD7C015FF17C1701167C12FF153E01E7EE3A01DDEE3910FF153E0189AC7C',
  '0501167C010519BA020316BA0137D67C1501167C0191F17A017DF1780173F1770169F176',
  '015FF17C0191F17A0187F179013516BA0183AD7C015FF17C1701167C6401167C1001167C',
  '01E3C75E0191C46E0187C46D0101167C0123C46A1301167C01DBF2BA010316BA0145AF7C',
  '01D5EE610183F05F01B9927001F1F06401A1F0620119F1601F01167C012DC479019FED78',
  '0195ED771101167C1201167C01E9EE7801DFEE771601167C010519BA020316BA0137D67C',
  '0B01167C0109C57A01FFC4790193C765017FC76301BBC76201B1C76101A7C7600193C765',
  '0189C7640101167C0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179',
  '013516BA0183AD7C015FF17C1701167C1201167C01E9EE7801DFEE771601167C010519BA',
  '020316BA0137D67C1501167C0191F17A017DF1780173F1770169F176015FF17C0191F17A',
  '0187F179013516BA0183AD7C015FF17C1701167C0EFF153E0181D27C0101167C0191F15E',
  '0191C46E0187C46D01BBED24018BEB37013DEE3901ABEE270135F12601D3EE24018BF023',
  '010DF12201BDF02101EFF0260135F12501E5F0240121F1230181F02101B5EE2701B3F026',
  '01E7EE250121F123018BF02201BFEE210139F23201AFBA33010316BA0145AF7C01D5EE61',
  '010FC46E0105C46D0197C8641E01167C010FC4760179F05E01FBC37B012DC479019FED78',
  '0195ED771101167C641A00165D0165D07C0101167C01EFCA670B01167C0169C95E',
  '015FC964019BC9630191C962017DC9600173C95F0169C95E015FC9640191C9620187C961',
  '017DC9600173C95F015FC964019BC9630191C9620187C9610173C95F0169C95E015FC964',
  '019BC9630501167C015FC97B01FBC85F0141C467017DC4650173F1770169F176015FF17C',
  '0191F17A0187F179017DF1780173F1770191C9770187C97B017DC9750173C97B015FC979',
  '019BC9780191C9771101167C1201167C01E9EE7801DFEE771601167C010519BA020316BA',
  '0141D67C0201167C01671B7C0101167C011DC5750113C57B01FFC47901F5C47801EBC477',
  '01E1C4760113C57B0109C57A01FFC47901F5C47801E1C476011DC5750187F179017DF178',
  '0169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A',
  '0187F179013516BA0183AD7C015FF17C1701167C1201167C01E9EE7801DFEE771101167C',
  '01EBC47701E1C476011DC5750109C57A01FFC479010519BA020316BA0137D67C0109C57A',
  '01FFC47901EBC47701E1C476011DC5750113C57B01FFC47901F5C47801EBC4770155F17B',
  '0187F179017DF1780173F1770169F1760155F17B0191F17A0187F179017DF1780169F176',
  '015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179',
  '013516BA0183AD7C015FF17C1701167C1201167C01E9EE7801DFEE771601167C010519BA',
  '020316BA0137D67C0109C57A01FFC47901EBC47701E1C476011DC5750113C57B01FFC479',
  '01F5C47801EBC4770155F17B0187F179017DF1780173F1770169F1760155F17B0191F17A',
  '0187F179017DF1780169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176',
  '015FF17C0191F17A0187F179013516BA0183AD7C015FF17C1701167C1001167C0191F15E',
  '0191C46E0187C46D1501167C01DBF2BA010316BA0145AF7C01D5EE610183F05F0105C46D',
  '01F1F06401A1F0620119F16001C9F05F1E01167C012DC47A019FED780195ED771101167C',
  '1201167C01E9EE7801DFEE7701CBEE7C1501167C010519BA020316BA0137D67C0901167C',
  '0155F17B0187F179017DF1780173F1770169F1760155F17B0191F17A0187F179017DF178',
  '0169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A',
  '0187F179013516BA0183AD7C015FF17C1701167C12FF153E01E7EE3A01DDEE392F01167C',
  '0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179013516BA0183AD7C',
  '015FF17C1701167C09FF153E0101167C0AFF153E0203F124030DF124013DF37C019BAC3E',
  '01BDF02101F9F026012BF1250AFF153E01D1915F0101167C01B9C69D0111F19D01FDF0A6',
  '01FDF09C0175C4B9020316BA0193F19D080316BA1001167C01E9F06301EDC7620169C477',
  '010FC4760183F05E0105C47B0137C47901A9ED780195ED771101167C11FF153E0113C826',
  '01E5F02501A9F025050DF1240147F37C019BAC3E01C7F02101F9F0260135F12507FF153E',
  '0133CB2601BFEE210103F12701051C7C0101167C01C1C65F0119F15F01FBF06801FBF05E',
  '01A5C47B0201167C01E3C75F1801167C01F1F06301EDC7620169C477010FC476016FF05E',
  '01FBC37B012DC479019FED780195ED770701167C0AFF153E1201167C01E9EE7801DFEE77',
  '1601167C010519BA020316BA0137D67C0401167C011DC5750113C57B0B01167C017DF178',
  '0169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A',
  '0187F179013516BA0183AD7C015FF17C1701167C0BFF153E01C71B3E04FF153E011FCB21',
  '01ABEE270115EE2601C5ED250195EB370147EE3901B5EE2701E5C82601DDEE240195F023',
  '0117F12201C7F02101F9F0260135F12501E5F0240121F1230181F02101B5EE2701B3F026',
  '01E7EE250121F123018BF02201BFEE21012FF23201ADBA24010BC8630143EF5F01D5EE61',
  '0183F0650105C46D1E01167C0195ED77010FC4760179F05E01FBC37B012DC479019FED78',
  '0195ED770181ED760177ED7B01A9ED7B01A9ED790D01167C2F01167C01F0D29B0302169B',
  '0137D67C3001167C1201167C01E9EE7801DFEE771601167C010519BA020316BA0137D67C',
  '1301167C015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A',
  '0187F179013516BA0183AD7C015FF17C1701167C1201167C01E9EE7801DFEE771601167C',
  '010519BA020316BA0137D67C1501167C0191F17A017DF1780173F1770169F176015FF17C',
  '0191F17A0187F17901C9137801E7EB75015FF17C1701167C1001167C019BF15E0191C46E',
  '1701167C0121F3BA0145AF7C01D5EE610183F05F0161F460011FF06301A1F062018DF060',
  '01C9F05F0401167C01BFC86001BFC85F0173C97A0169C9791601167C012DC479019FED78',
  '0195ED771101167C1201167C01DFEE7801DFEE771601167C010519BA020316BA0137D67C',
  '1501167C0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179013516BA',
  '0183AD7C015FF17C1701167C1201167C01E9EE7801DFEE771601167C010519BA020316BA',
  '0137D67C0901167C0155F17B0187F179017DF1780173F1770169F1760155F17B0191F17A',
  '0187F179017DF1780169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176',
  '015FF17C0191F17A0187F179013516BA0183AD7C015FF17C1701167C1001167C01B3CA5E',
  '0179F05E0117EE6401C7ED62014FED701301167C01CBF8BA010316BA0145AF7C01D5EE61',
  '0183F05F0105C46D015DEE630153EE620123EC601101167C017FC77601BBC77501A7C773',
  '015FC97901D9C7780189C77701F1C85E0173C97B01A7C77A015FC97901CFC777017FC776',
  '01F1C85E01B1C77B012DC479019FED780195ED771101167C1001167C01ABC85E0141C46E',
  '016DED7B01A9ED7A01CBEE760183F06001B7EE6501CDC46D0173C4720123F1610119F160',
  '01C9F05F0141F1640137F16301E7F0620123F161010FF15F01BFF0650141F16401F1F063',
  '0123F1610119F16001C9F05F013BF27001A519BA0197C5A501EFC2A401E5C2AA0107C4AC',
  '017BF0A201F1F0630189EF5F013FEE7C0183F07B0105F17301FBF072012DF1770123F161',
  '01D3F060010FF15F0141F16401F1F063012DF1620123F16101C9F05F01B7EE7A01ADEE79',
  '01E9EE78018FEE760185EE75017BEE740171EE7A015F19BA020316BA01B5AD7C0171EE7A',
  '0167EE79015DEE780153EE770185EE75017BEE740171EE7A0167EE790153EE7701D5EE76',
  '01CBEE751101167C2A01167C030316BA01E5AF7C2101167C01FBC37B01A1F05E0123C478',
  '0119C4771101167C1201167C01E9EE7801DFEE771601167C010519BA020316BA0137D67C',
  '1001167C01CFC76001CFC75F01D9C7630191C9620155F17B0191F17A017DF1780173F177',
  '0169F176015FF17C0191F17A0187F179013516BA0183AD7C015FF17C1701167C3001167C',
  '01B7C667010FC46601E9C66501DFC6643001167C1201167C01BCAC9B0159EB81018BEB7F',
  '0181EB7E0177EB84016DEB830159EB810195EB80018BEB7F0181EB7E016DEB830163EB82',
  '0159EB810195EB800181EB7E0177EB84016DEB830163EB82014FEB80018BEB7F0181EB7E',
  '0177EB840163EB820159EB810195EB80018BEB7F0177EB84016DEB830163EB820159EB81',
  '018BEB7F0181EB7E0177EB84016DEB830159EB810195EB80018BEB7F0181EB7E016DEB83',
  '0163EB820159EB81014FEB800181EB7E0177EB84016DEB830163EB82014FEB80018BEB7F',
  '0181EB7E0121197C0601167C0105ADF80159EBE5018BEBE3012B197C1601167C0C00165D',
  '5801167C1201167C01E9EE7801DFEE771601167C010519BA020316BA0137D67C1101167C',
  '017DF1780169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C',
  '0191F17A0187F179013516BA0183AD7C0169F17C1701167C2B01167C020316BA01E71B7C',
  '0301167C01071CBA070316BA2B01167C4B01167C0227CA721701167C1001167C0121CB5E',
  '1801167C010BC8630101C8622601167C019FED780195ED771101167C0500165D013DF87C',
  '0A01167C016FC85E011DC56E0187C42F01C5ED240195EB360147EE3901B5EE27013FF126',
  '01DDEE24019FF0230117F12201C7F02101F9F0260135F12501E5F0240121F1230181F021',
  '01B5EE2701B3F02601E7EE250121F123018BF02201BFEE210139F23201ADBAA9010316BA',
  '0145AF7C01D5EE61010FC46F0105C46D0197C8641E01167C010FC4760179F05E01FBC37B',
  '012DC479019FED780195ED771101167C2E01167C0199F35E0153F37B01EDC77C0183F07B',
  '0179F07A016FF07901A1F07601CDF15E0185EE7C01B1EF63019DEF6101D9EF6001CFEF5F',
  '01C5EF5E01B1EF6301A7EF62019DEF6101D9EF6001C5EF5E0119F16E010FF16D0105F173',
  '0137F171012DF1700123F16F0119F16E0105F1730141F17201971371012DF1700185F3BA',
  '010316BA1601167C1201167C01E9EE7801DFEE771601167C010519BA020316BA0137D67C',
  '0F01167C011DC5750113C57B017DF1780169F176015FF17C0155F17B0191F17A017DF178',
  '0173F1770169F176015FF17C0191F17A0187F179013516BA0183AD7C015FF17C1701167C',
  '1001167C01B3CA5E0179F05E0117EE6401C7ED62014FED701301167C01CBF8BA040316BA',
  '0137D67C1401167C017FC77601BBC77501A7C773015FC97901D9C7780189C77701F1C85E',
  '0173C97B01B3ED7A01B9C47201A5C4701701167C2801167C01DBF2BA010316BA0145AF7C',
  '01D5EE611C01167C01DFC67B01D5C67A01CBC67901C1C67801ADC67601E9C67501DFC67B',
  '01D5C67A01C1C67801B7C67701ADC6761101167C2A01167C010519BA020316BA0137D67C',
  '0B01167C0109C57A01FFC47901F5C47801E1C476011DC5750113C57B0109C57A01F5C478',
  '015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179',
  '013516BA010316BA015FF17C1701167C1201167C01E9EE7801DFEE771601167C010519BA',
  '020316BA0123E77B1501167C0191F17A017DF1780173F1770169F176015FF17C0191F17A',
  '0187F179013516BA01971377015FF17C1701167C1001167C017FC77B1701167C01C9D2BA',
  '010316BA0145AF7C01D5EE610183F05F0179F05E0D01167C0113ED710145ED6F013BED6E',
  '0131ED6D0127ED6C0113ED7101EBC4700E01167C012DC479019FED780195ED771101167C',
  '4AFF153E1A01167C0D00165D01BDAF7C1901167C0107A97001A519BA040316BA01E5AF7C',
  '0401167C01F9CA7A1001167C01A9CA5E0601167C013BCA5E0101167C0181C55E01ADC679',
  '01F59C6101EB9C601401167C2D02169B06FF153E3100165D2A02169B014CE7BB020416D9',
  '0120AD9B3602169B1001167C0139C77B1701167C01B5F5BA010316BA0145AF7C01FBC861',
  '0183F05F01CFC26C01ADC65E0195C56701C7C5651F01167C012DC479019FED780195ED77',
  '1101167C2001167C0D16D57C078DF57C013E167C0416D57C2B01167C6402169B06FF153E',
  '0115D57C0B01167C01F1F07C015D94761601167C010519BA020316BA0137D67C3601167C',
  '0C00165D0401167C0175CC5E01BDED6201C7ED6C03BDED6C0201167C010FF16C0101167C',
  '0119F160016FF05F01FBF0640137F1630101167C0123F1610183F05F0101167C01B5F064',
  '01E9EE630123F161018DF06001C1EE5F0105F16501FBEB78019FF25F0149EE750119F17C',
  '016B907401B5A57901B5F06301A1F062018DF0600183F05F0179F05E016FF06401A1F062',
  '0197F061018DF0600183F05F016FF06401ABF06301A1F0620197F0610183F05F0179F05E',
  '016FF06401ABF0630197F061018DF06001EFF2BA090316BA010FD67C018BED760179F05E',
  '01FBC37B012DC479019FED780195ED771101167C1201167C01F1F07C1001167C01881C9B',
  '013EC8800134C87F012AC87E0120C87D0152C8820148C88101E8F5D9020416D90138D69B',
  '0502169B0114C59A0100C59801F6C49701ECC49601E2C4950114C59A010AC5990100C598',
  '01F6C4970156F19A0192F1990188F198017EF197016AF1950160F19B0156F19A0192F199',
  '017EF1970174F1960169F176015FF17C0191F17A0187F179017DF1780173F177015FF17C',
  '1701167C1201167C01E9EE7801DFEE771501167C0147CD5E010519BA020316BA0137D67C',
  '1501167C0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179013516BA',
  '0183AD7C015FF17C1701167C2A01167C010519BA020316BA0137D67C0F01167C080316BA',
  '0183AD7C0169F176015FF17C0191F17A0187F179013516BA0183AD7C015FF17C1701167C',
  '2A01167C010519BA020316BA0137D67C1701167C0173F1770169F176015FF17C0191F17A',
  '0187F179013516BA0183AD7C015FF17C1701167C4B0316BA1901167C0800165D01ABF37C',
  '5B01167C2500165D3F01167C1201167C01E9EE7801DFEE771601167C010519BA020316BA',
  '0137D67C0201167C012F1C7C0101167C011DC5750113C57B01FFC47901F5C47801EBC477',
  '01E1C4760113C57B0109C57A01FFC47901F5C47801E1C476011DC5750187F179017DF178',
  '0169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A',
  '0187F179013516BA0183AD7C015FF17C1701167C2001167C01B5C85F0179F05E01B5F064',
  '01ABF0630197F061018DF0600183F05F0179F05E01DBF2BA010316BA0145AF7C01D5EE61',
  '0183F05F0193C7752101167C01B1C77B012DC4790123C4780119C4771101167C5101167C',
  '019FED780195ED771101167C4A01167C0163897C0201167C010DB2BA01C1197C1501167C',
  '1001167C0139C77B3F01167C012DC479019FED780195ED771101167C1E01167C01EFB1BA',
  '01F9C39D01A3F19C0AF1EE9C140316BA0189AC7C0101167C0117ADBA02BBEDAA01E7EEAA',
  '019FF0AA0195F0AA018BF0AA0177F0AA020316BA010DF3BA080316BA1001167C45FF153E',
  '0701167C0169C477010FC4760179F05E01FBC37B012DC479019FED780195ED771101167C',
  '2801167C0A27CA723201167C1401167C01D9F27C1C01167C01071CBA070316BA2B01167C',
  '0300165D01651B7C2701167C01CBD5BA01191C7C3701167C1F01167C019FACBA116DF09E',
  '01D9F27C3201167C1F01167C029FACBA106DF09E01D9F27C3201167C1700165D0193AC7C',
  '026CF05F01D8F25D0600165D01A1AD7C016CF079016CF07801D2EE7601C8EE7C01BEEE7B',
  '01B4EE7A011CF0600112F05F0108F05E01FEEF6401EAEF6201E0EF61011CF0600112F05F',
  '01FEEF6401F4EF6301EAEF621401167C01B7ADBA0131A5B801D9EDB701CFEDB6016F1B7C',
  '01B7ADBA01971B7C1601167C1502169B018D167C4E01167C4601167C01D5F3BA1D0316BA',
  '1102169B1F01167C01E7A57C0191F17C013FC17C01B3ED7A01AFC478015FC46901CDC968',
  '01C3C9670169C97A01FFC4721001167C0179CD6901EBC96C1801167C2501167C010116BA',
  '01F9C3B4017FEDB3014B1C7C0AD7B55E3101167C1001167C011DC57B0191C46E0187C46D',
  '1501167C01DBF2BA010316BA0145AF7C01D5EE610183F05F0179F05E0115C8630179F062',
  '0119F16001C9F05F1D01167C01FBC37B012DC479019FED780195ED771101167C3101167C',
  '01EFB1BA06D9F29C01D9F27C2B01167C4102169B2301167C4100165D2301167C0400165D',
  '1801167C0400165D12FF153E3201167C0B02169B013DF87C3601167C01EFF2BA210316BA',
  '2801167C06FBC37B0B01167C013DC85E01EDC75E11ADC67B1801167C1500165D018BF57C',
  '1401167C016FF05E2601167C0145ED780195ED771101167C1000165D01BFD07C0F01167C',
  '01D3A05E0801167C01EB927B0143AF3E01DDEE2301F7F27C0701167C017DCE5E1601167C',
  '01E7F06301D3F067010FC4760179F05E01FBC37B012DC479019FED780195ED771101167C',
  '08FF153E01C4CF5D0700165D01E2C73F0190C44F01FAC35C0136C45B0122C4590118C458',
  '01B6EE460194CA4501DEEE4301BCCA42016EC841016EC840016EC845016EC844016EC843',
  '016EC84201B4C840016EC846016EC845016EC844016EC84201B4C841016EC840016EC846',
  '0123F6BA010316BA0145AF7C01D5EE610183F05F0105C46D1F01167C010FC4760179F05E',
  '01FBC37B012DC479019FED780195ED771101167C1001167C01E3C75E0191C46E0187C46D',
  '1501167C01DBF2BA010316BA0145AF7C01D5EE610183F05F01AFF16F01F1F06401A1F062',
  '0119F16001C9F05F1E01167C012DC47A019FED780195ED771101167C2101167C1B02169B',
  '0138F99B2702169B0300165D01651B7C2601167C01D5D5BA014DEDAE01191C7C3701167C',
  '64FF153E3701167C0B27CA722201167C08FE151F09FF153E01C7EB38013B182E0131182E',
  '15FF153E01E5BE210121BF2101F7ED3701E3ED3501D9ED3B01CFED3A019FF039018BF037',
  '0181F0360177F03C016DF03B019FF0390195F038018BF0370181F036016DF03B01A9F03A',
  '019FF0390195F0380181F0360177F03C016DF03B01A9F03A0195F038018BF0370181F036',
  '0177F03C0115F37C1F01167C1001167C01E3C75E0191C46E0187C46D01ADD5BA020316BA',
  '013DF87C1101167C01E5F2BA010316BA0145AF7C01D5EE5F0183F06001AFF16F0169C97A',
  '015FC9790191C9770187C97601A9CA5E0173C97B015FC979019BC9780191C9770187C976',
  '0173C97B0169C97A015FC979019BC97801FBC85F01F1C85E01B1C77B01A7C77A01D9C778',
  '0C01167C010FC4760179F05E01FBC37B012DC479019FED780195ED771101167C1E00165D',
  '4601167C1602169B0F0416D90502169B0118D5D9020416D90116AD9B3602169B39FF153E',
  '2B01167C1EFF153E0800165D3E01167C4700165D1D01167C27FF153E010FA93204FF153E',
  '0179F02701FBC32F01A3197C0201167C01C3AC3E03FF153E013FA13A02FF153E0119177C',
  '0601167C0159F33E07FF153E01E9C43905FF153E0115C8640101167C0181AD3E015DF13E',
  '01E1C73D0195133E1101167C1401167C01CBEE760183F06001B7EE6501CDC46D0173C472',
  '0123F1610119F16001C9F05F0141F1640137F16301E7F0620123F161010FF15F01BFF065',
  '0141F16401F1F0630123F1610119F16001C9F05F013BF27001A519BA0197C5A501EFC2A4',
  '01E5C2AA0107C4AC01FBC37B0137C47A012DC4790119C477010FC4760105C4750B01167C',
  '01FBC37B0137C47A0123C4780119C4770901167C02ADC67B1701167C2F02169B01F2D2D9',
  '030416D90137D67C3001167C1F00165D0117ADBA012D1C7C4301167C4B01167C0117D5BA',
  '180316BA3101167C08FF153E2B01167C1CFF153E04F7C35E01D7F23E0EFF153E012BF67C',
  '1401167C0151AFBA0113F0B201D3EEA6013DEEA50129EEAA01E9ECB90115EEA8010BEEA7',
  '013DEEA501DD1B7C1601167C1F02169B4501167C31FF153E3301167C30FF153E3401167C',
  '3A01167C1C0316BA0E01167C2102169B01D9F27C0B01167C0727CA720107F9BA032D1CB0',
  '012D1C7C0A01167C01EFB67B0103B77901DBB67801D1B67701C7B67601EFB67B01E5B67A',
  '01DBB67901D1B6970109EB3F01B3187C1601167C2401167C013DAFBA01B3187C1001167C',
  '01FDC15E2D01167C0BFF153E01B51B7C1B01167C013BF27001FBEB620101167C0139EF5E',
  '01CBEE600179F06501FBC36D1F01167C01ADC6761601167C2400165D01DBF57C3F01167C',
  '4702169B1D01167C2E01167C01B7B2BA022D1CB0012D1C7C3201167C0C00165D01E3AC7C',
  '5701167C22FF153E036DF02003FF153E01DDEE2501D3EE2401C9EE2301BFEE2201ABEE26',
  '01E7EE2501DDEE2401D3EE2301BFEE2101B5EE2001ABEE2601E7EE2501D3EE2301C9EE22',
  '01BFEE2101B5EE2001E7EE2501DDEE242AFF153E0C0316BA016F1B7C5701167C2B01167C',
  '020316BA01E71B7C0301167C01071CBA070316BA0301167C100316BA01691C7C1701167C',
  '0400165D01EDB17C1701167C0400165D4401167C220316BA0188AC5D0281EE3F012B1C3E',
  '03FF153E0116D59B03D7C77D01B7F67C3601167C6400165D0AFF153E0187AC3E05FF153E',
  '016DF02003FF153E01C9EE380181F02201B5EE2711FF153E0145CD2501EDB17C01D9F27C',
  '0201167C01CDAC3E01B1ED3C01A7ED3B0181F0220181F0210177F02001F9C33D01A7ED3B',
  '01D3EE22018BF0220181F02101F9C33D01B1ED3C01A7ED3B0195F0230181F0210177F020',
  '01F9C33D01B1ED3C01D3EE23018BF0220181F0210177F02001B1ED3D01DDEE240195F023',
  '018BF0220177F02001DDCB22011DF02101CDEF20018DEE3E0179EE2F01D9F27C1501167C',
  '1B00165D4901167C2A01167C01DDF2F8020516F801DBAF7C3601167C2A01167C01DBF2BA',
  '020316BA01DBAF7C3601167C1000165D01AAC85E0141C46E016DED7B01A9ED7A01CBEE76',
  '0183F06001B7EE6501CDC46D0173C4720123F1610119F16001C9F05F0141F1640137F163',
  '01E7F0620123F161010FF15F01BFF0650141F16401F1F0630123F1610119F16001C9F05F',
  '01F5F17001A519BA050316BA01BBAC7C0189EF5F0119F17C0183F07B0105F17301FBF072',
  '012DF1770123F16101D3F060010FF15F0141F16401F1F063012DF1620123F16101C9F05F',
  '01B7EE7A01ADEE7901E9EE78018FEE760185EE75017BEE740171EE7A015F19BA020316BA',
  '01B5AD7C0171EE7A0167EE79015DEE780153EE770185EE75017BEE740171EE7A0167EE79',
  '0153EE7701D5EE7601CBEE751101167C1201167C01F1F07C1601167C01A5C979010519BA',
  '020316BA0137D67C0101167C01FFC47901EBC47701E1C476011DC5750113C57B01FFC479',
  '01F5C47801EBC47701E1C4760113C57B0109C57A01FFC47901F5C47801E1C476011DC575',
  '0187F179017DF1780169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176',
  '015FF17C0191F17A0187F179017DF1780173F177015FF17C1701167C1201167C01F1F07C',
  '1701167C010519BA020316BA0137D67C1001167C0187F179017DF1780169F176015FF17C',
  '0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179017DF178',
  '0173F177015FF17C1701167C1201167C01F1F07C1701167C010519BA020316BA0137D67C',
  '1101167C011BC76401F5C46A01EBC4690101167C0191F17A017DF1780173F1770169F176',
  '015FF17C0191F17A0187F179017DF1780173F177015FF17C1701167C1B00165D016EAF9B',
  '01D8ED6B015AEE6A0150EE690146EE680178EE66016EEE650110C55F0106C55E01F2C463',
  '01E8C46201DEC461011AC5600106C55E2101167C0151AFBA0159189D014518A20171197C',
  '1601167C1EFF153E01D3F87C3201167C0295ED771101167C1400165D5001167C4B01167C',
  '018BACBA013DEE9C01E71B7C1601167C1101167C016389761701167C011BB3BA019DEDB6',
  '01C9EE9E015F1C7C1A01167C01B7ADBA010DECB801D9EDB701CFEDB601C5EDB501F7EDBA',
  '01971B7C1601167C2101167C4302169B1101167C010316BA01551C7C1601167C011BB3BA',
  '019DEDB601C9EE9E015F1C7C3701167C3C01167C016FF05E0195CA5E2601167C0300165D',
  '01651B7C2601167C01D5D5BA012D1C7C1D01167C1BFF153E1101167C016389761701167C',
  '011BB3BA019DEDB601C9EE9E015F1C7C3701167C0400165D01EDB17C1701167C0400165D',
  '1601167C012C1C5D0500165D01ACC64B01BDD27C2601167C2D01167C015FC9720327CA72',
  '3301167C1102169B016489951702169B011CB3D9019EEDD501CCEEBD01601C9B1A02169B',
  '01B8ADD90110ECD701DCEDD601D2EDD501C8EDD401FAEDD901981B9B1602169B1001167C',
  '01A3ADBA01D9EDB701791B7C1601167C011BB3BA019DEDB601C9EE9E015F1C7C1601167C',
  '018BACBA01E7EEB6010BEEB50101EEB401F7EDBA010DECB801D9EDB701CFEDB601C5EDB5',
  '01F7EDBA01971B7C1601167C2901167C018FF3BA0145AF7C01CBEE600179F05E01DFC66D',
  '3601167C1EFF153E01D3F87C3201167C019FED780195ED771101167C1402169B0701167C',
  '01A3F8BA020316BA01C7AF7C0B01167C01DBF2BA060316BA0183167C3201167C1BFF153E',
  '01A1F87C0201167C01C5AF3E01EBC72001911C7C4301167C1602169B050316BA01A5F8F8',
  '020516F801C9AFBA01EFC79C01951CF8090516F801DBF2BA060316BA0183167C3201167C',
  '1600165D05FF153E01A1F87C0201167C01C5AF3E01EBC72001911C7C0601167C011DBB76',
  '013FB2BA01D9F27C0101167C0185B2BA018BF57C0501167C0199BC7B3101167C02FF153E',
  '01C9F87C0F01167C01F1F07C1701167C010519BA020316BA0137D67C1401167C0155F17B',
  '0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179017DF1780173F177',
  '015FF17C1701167C1201167C01F1F07C1701167C010519BA020316BA0137D67C3601167C',
  '1201167C01F1F07C1501167C012FD6BA040316BA0137D67C3601167C1201167C01F1F07C',
  '1501167C012FD6BA040316BA0137D67C1601167C017DF1780173F1770169F176015FF17C',
  '0191F17A0187F179017DF1780173F177015FF17C1701167C1201167C01F1F07C1701167C',
  '010519BA020316BA0137D67C0101167C01FFC4790B01167C0169F1760701167C0191F17A',
  '017DF1780173F1770169F176015FF17C0191F17A0187F179017DF1780173F177015FF17C',
  '1701167C1200165D01F0F05D1700165D01F0F59B0202169B0136D65D0500165D0112C55C',
  '01FEC45A01F4C45901EAC45801E0C457014EA75C0108C55B01FEC45A01F4C4590154F15C',
  '0190F15B0186F15A017CF1590168F157015EF15D0154F15C0190F15B017CF1590172F158',
  '0168F157015EF15D0190F15B0186F15A017CF1590172F158015EF15D1700165D0D01167C',
  '01E9EE780501167C01DFEE771601167C010519BA020316BA0137D67C3601167C1201167C',
  '01E9EE7801DFEE771201167C01E1C476011DC5750109C57A01FFC479010519BA020316BA',
  '0137D67C0109C57A01FFC47901EBC47701E1C476011DC5750113C57B01FFC47901F5C478',
  '01EBC4770155F17B0187F179017DF1780173F1770169F1760155F17B0191F17A0187F179',
  '017DF1780169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176015FF17C',
  '0191F17A0187F179013516BA0183AD7C015FF17C1701167C1201167C01E9EE7801DFEE77',
  '1601167C010519BA020316BA0137D67C0901167C01E1C4760187F179017DF1780173F177',
  '0169F1760155F17B0191F17A0187F179017DF1780169F176015FF17C0155F17B0191F17A',
  '017DF1780173F1770169F176015FF17C0191F17A0187F179013516BA0183AD7C015FF17C',
  '1701167C1200165D01E8EE5901DEEE581600165D0104199B0202169B0136D65D0100165D',
  '0183F87C3401167C12FF153E01DDEE3A01DDEE3903FF153E018BF57C1201167C010519BA',
  '020316BA0137D67C1501167C0191F17A017DF1780173F1770169F176015FF17C0191F17A',
  '0187F179013516BA0183AD7C015FF17C1701167C1202169B0201167C01CBEE760183F060',
  '01B7EE6501CDC46D1101167C01ADC67B01ADC67C12ADC67B011DC57B0113C57A0109C579',
  '019FF25E01EBC47601E1C475011DC57B0109C57901FFC47801F5C477018DF5BA020316BA',
  '0123E77B02ADC67B1701167C1201167C01E9EE7801DFEE771601167C010519BA020316BA',
  '0137D67C0D01167C0147CD760155F17B0191F17A0187F179017DF1780169F176015FF17C',
  '0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179013516BA',
  '0183AD7C015FF17C1701167C12FF153E01E7EE3A01DDEE3916FF153E0103197C0201167C',
  '0135D63E09FF153E01DDD57C0101167C0107C53C01FFC47901F5C47801E1C4760191F17A',
  '0187F179017DF1780169F176015FF17C0155F17B0191F17A017DF1781F01167C1201167C',
  '01E9EE7801DFEE771601167C010519BA020316BA0137D67C1201167C0169F176015FF17C',
  '0155F17B0191F17A017DF1780173F1770169F176015FF17C0191F17A0187F179013516BA',
  '0183AD7C015FF17C1701167C0B02169B3601167C230316BA1201167C01E9EE7801DFEE77',
  '1601167C010519BA020316BA0137D67C0C01167C0173F1770169F1760155F17B0191F17A',
  '0187F179017DF1780169F176015FF17C0155F17B0191F17A017DF1780173F1770169F176',
  '015FF17C0191F17A0187F179013516BA0183AD7C015FF17C1701167C'
 );
 FUSIX : Array[1..NFUST+1] Of Integer = (
  0,58,79,80,101,130,149,191,192,237,
  275,319,358,378,410,425,457,492,518,564,
  569,590,609,632,651,682,717,785,794,818,
  824,881,883,906,913,916,925,967,1001,1026,
  1049,1067,1093,1112,1134,1136,1155,1158,1163,1180,
  1186,1187,1197,1256,1297,1317,1332,1346,1348,1351,
  1353,1391,1412,1416,1422,1429,1448,1458,1461,1467,
  1473,1478,1483,1515,1518,1521,1537,1544,1565,1570,
  1572,1574,1579,1584,1591,1599,1620,1661,1681,1685,
  1692,1693,1696,1731,1772,1774,1781,1783,1786,1788,
  1812,1852,1857,1861,1864,1867,1884,1886,1888,1890,
  1893,1913,1919,1932,1935,1937,1942,1945,1967,1970,
  1980,1985,1994,1995,2043,2045,2050,2055,2119,2158,
  2181,2203,2224,2229,2231,2236,2252,2254,2263,2267,
  2274,2282,2292,2296,2312,2334,2341,2347,2357,2364,
  2376,2393,2414,2421,2428,2445,2467,2501,2510,2553,
  2584,2594,2615,2640,2667,2690,2712,2715,2743
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

 B_DOM = 502;
 B_MAS = 646;
 B_MAM = 790;
 B_ASP = 934;
 B_SYM = 1564;

 { Chaine de chiffres de la structure icosidodecaedrique d'URRIS }
 DIG : String[120] =
  '0386579212284015237631387469200323279548521342869331059467'+
  '237921203865523762840146920313877954803232286935213446723310'+
  '59';

 { Equation du temps (minutes) par decades, depuis le 1er janvier }
 { (la 38e valeur est l'orbe lue a la suite par l'original) }
 EOTV : Array[1..38] Of Single = (
  3.3,7.7,11.2,13.4,14.3,13.8,12.4,10,7.2,4.2,1,-1.2,-3,-3.7,-3.5,
  -2.4,-0.5,1.7,3.8,5.4,6.3,6.3,5.1,3,-0.2,-3.5,-7,-10.4,-13.3,
  -15.4,-16.4,-15.9,-14.1,-10.9,-6.6,1.8,3.3,8);
 { Orbes des 13 points }
 ORBS : Array[1..13] Of Integer = (8,13,8,5,5,5,3,3,3,3,5,5,2);
 { Polarite des planetes (1 = masculine) }
 POL : Array[1..10] Of Integer = (1,0,1,0,1,0,1,1,0,0);
 { Domicile de chaque planete }
 DOMI : Array[1..10] Of Integer = (5,4,3,2,1,9,10,11,12,8);
 { Maitre de chaque signe }
 RULER : Array[1..12] Of Integer = (5,4,3,2,1,3,4,10,6,7,8,9);
 ROMAN : Array[1..12] Of String[4] = ('I','II','III','IV','V','VI',
  'VII','VIII','IX','X','XI','XII');
 PLCOL : Array[1..10] Of Integer = (14,15,11,10,12,13,6,9,3,5);

 PI_D : Double = 3.14159265358981;

 { Vues }
 V_WELCOME = 0;
 V_NATAL = 1;
 V_HOUSES = 2;
 V_WHEEL = 3;
 V_PLANET = 4;
 V_HOUSE = 5;
 V_DOMIN = 6;
 V_ASC = 7;
 V_DAY = 8;
 V_DAYPL = 9;
 V_DDOM = 10;
 V_PREV = 11;
 V_TAROT = 12;
 V_COMP = 13;
 V_GUIDE = 14;

 MAXCAL = 200;
 MAXVL = 320;
 CALFILE = 'ASTROMAN.CAL';
 TXTFILE = 'ASTROMAN.TXT';

{ ================================================================== }
{ Types                                                              }
{ ================================================================== }

Type
 TChart = Record
  Pl : Array[1..10] Of Single;          { longitudes ecliptiques }
  Cu : Array[1..12] Of Single;          { cuspides des maisons }
  P  : Array[1..15] Of Integer;         { 13 points en degres entiers }
  H  : Array[1..13] Of Integer;         { cuspides en degres entiers }
  AT : Array[1..15,1..15] Of Byte;      { type d'aspect (0 = aucun) }
  AD : Array[1..15,1..15] Of Byte;      { ecart de l'aspect (0..9) }
 End;

 TPerson = Record
  Name  : String[20];
  D, M, Y, Hh, Mi : Integer;
  Ctry  : String[3];
  State : String[3];
  City  : String[24];
  LatD, LatM : Integer;
  South : Boolean;
  LonD, LonM : Integer;
  West  : Boolean;
  Ofs   : Real;                         { heures a ajouter au T.U. }
 End;

 TInterp = Record
  nS, nD : Array[1..12] Of Integer;     { signes/degres natals }
  dS, dD : Array[1..12] Of Integer;     { signes/degres du jour }
  hS, hD : Array[1..12] Of Integer;     { signes/degres des maisons }
  tHouse, nHouse, Master : Array[1..10] Of Integer;
  Pn, Pd : Array[1..10] Of Double;      { puissances (entieres) }
  Fn, Fd : Array[1..10] Of Integer;     { forces }
  Dom, Puis, DDom, DForce, Asc : Integer;
 End;

 TPrev = Record
  A, B, DType, NType, Idx : Integer;
 End;

 TComp = Record
  cS, cD, hS : Array[1..12] Of Integer;
  F : Array[1..10] Of Integer;
  Dom, Car, Pos, Neg, Sun, Mars, Moon, Ven, Vit, Sen : Integer;
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
 Cur : TPerson;
 HasCur : Boolean;
 NatC, DayC : TChart;
 RI : TInterp;
 DayD, DayM, DayY : Integer;
 View, ViewArg, PrevView : Integer;
 Cal : Array[1..MAXCAL] Of TPerson;
 CalN : Integer;
 VL : Array[1..MAXVL] Of TVLine;
 VLN, VTop : Integer;
 WrapS : String;
 WrapC, WrapI : Integer;
 PrevN : Integer;
 PrevL : Array[1..5] Of TPrev;
 CompP : TPerson;
 CompR : TComp;
 ShowTransit : Boolean;
 MouseOK : Boolean;
 MsX, MsY, MsB : LongInt;
 MsSaved : Boolean;
 MsSaveX, MsSaveY : Integer;
 MsSaveBuf : Pointer;
 ActiveMenu : Integer;
 QuitReq : Boolean;
 StatusMsg : String;

{ ================================================================== }
{ Langues                                                            }
{ ================================================================== }

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

Function PlName(I : Integer) : String;
Begin
 PlName := PLN[Lang, I];
End;

Function SgName(I : Integer) : String;
Begin
 If (I < 1) Or (I > 12) Then SgName := '?' Else SgName := SGN[Lang, I];
End;

Function MotW(I : Integer) : String;
Begin
 If (I < 1) Or (I > 166) Then MotW := '' Else MotW := MOT[I, Lang];
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

Function Pad2(N : Integer) : String;
Begin
 If N < 10 Then Pad2 := '0' + IStr(N) Else Pad2 := IStr(N);
End;

Function PadR(S : String; N : Integer) : String;
Begin
 While Length(S) < N Do S := S + ' ';
 PadR := S;
End;

Function UpStr(S : String) : String;
Var
 I : Integer;
Begin
 For I := 1 To Length(S) Do Begin
  Case S[I] Of
   #130, #136, #137, #138 : S[I] := 'E';
   #131, #132, #133, #134, #160 : S[I] := 'A';
   #135 : S[I] := 'C';
   #139, #140, #141, #161 : S[I] := 'I';
   #147, #148, #149, #162 : S[I] := 'O';
   #129, #150, #151, #163 : S[I] := 'U';
   #164 : S[I] := 'N';
  Else S[I] := UpCase(S[I]);
  End;
 End;
 UpStr := S;
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

Function FloorD(X : Double) : Double;
Var
 T : Double;
Begin
 T := Int(X);
 If (X < 0) And (T <> X) Then T := T - 1;
 FloorD := T;
End;

Function FloorI(X : Double) : LongInt;
Begin
 FloorI := Trunc(FloorD(X));
End;

Function CIntD(X : Double) : LongInt;
Begin
 If X >= 0 Then CIntD := Trunc(FloorD(X + 0.5))
           Else CIntD := -Trunc(FloorD(-X + 0.5));
End;

Function SgnD(X : Double) : Double;
Begin
 If X > 0 Then SgnD := 1 Else If X < 0 Then SgnD := -1 Else SgnD := 0;
End;

{ Arrondi en simple precision (le BASIC d'origine calculait ainsi). }
Function F4(X : Double) : Single;
Begin
 F4 := X;
End;

Function SSin(X : Double) : Single; Begin SSin := F4(Sin(X)); End;
Function SCos(X : Double) : Single; Begin SCos := F4(Cos(X)); End;
Function STan(X : Double) : Single;
Begin
 STan := F4(Sin(X) / Cos(X));
End;
Function SAtn(X : Double) : Single; Begin SAtn := F4(ArcTan(X)); End;
Function SSqr(X : Double) : Single; Begin SSqr := F4(Sqrt(X)); End;

Function SAcos(X : Double) : Single;
Var
 V : Single;
Begin
 V := F4(-SAtn(F4(X / SSqr(F4(F4(-X * X) + 1)))));
 SAcos := F4(V + PI_D * 0.5);
End;

Function SAsin(X : Double) : Single;
Begin
 SAsin := SAtn(F4(X / SSqr(F4(F4(-X * X) + 1))));
End;

{ Jour de la semaine (0 = dimanche) }
Function WeekDay(D, M, Y : Integer) : Integer;
Var
 A, Yy, Mm : LongInt;
Begin
 A := (14 - M) Div 12;
 Yy := Y - A;
 Mm := M + 12 * A - 2;
 WeekDay := (D + Yy + Yy Div 4 - Yy Div 100 + Yy Div 400 +
            (31 * Mm) Div 12) Mod 7;
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

Function LongDate(D, M, Y : Integer) : String;
Var
 S : String;
Begin
 S := WDAY[Lang, WeekDay(D, M, Y)];
 If Lang = 1 Then
  S := S + ', ' + MON[Lang, M] + ' ' + IStr(D) + ', ' + IStr(Y)
 Else If Lang = 2 Then
  S := S + ', ' + IStr(D) + '. ' + MON[Lang, M] + ' ' + IStr(Y)
 Else
  S := S + ' ' + IStr(D) + ' ' + MON[Lang, M] + ' ' + IStr(Y);
 LongDate := S;
End;

Function TimeStr(H, M : Integer) : String;
Begin
 TimeStr := Pad2(H) + 'h' + Pad2(M);
End;

Function OfsStr(X : Real) : String;
Var
 S : String;
 H, Mn : Integer;
 A : Real;
Begin
 A := Abs(X);
 H := Trunc(A + 0.0001);
 Mn := Round((A - H) * 60);
 If X < 0 Then S := '-' Else S := '+';
 S := S + IStr(H);
 If Mn <> 0 Then S := S + ':' + Pad2(Mn);
 OfsStr := S;
End;

Function DegStr(Deg : Integer) : String;
Begin
 DegStr := IStr(Deg) + #248;
End;

{ ================================================================== }
{ Calcul du theme (portage fidele du module ASTURRIS d'URRIS)        }
{ ================================================================== }

Procedure CalcChart(D, M, Y, Hh, Mi : Integer; Ofs : Double;
                    LonD, LonM : Integer; West : Boolean;
                    LatD, LatM : Integer; South : Boolean;
                    Var C : TChart);
Var
 RAD, EPS, PI2, PIH, PI3H : Double;
 Dd, Mm, Yy, S1724, S1728, S172c, T, S1736, S173c, S1740, S1744 : Single;
 S175c, V1, V2, Lat, Ramc, S1774, X, Mc : Single;
 I1730, Idx, DMod, I, J, P : Integer;
 A : Array[1..5] Of Single;
 Kf, S1778, S178e, S1782, S1792 : Single;
 S178a : Integer;
 S1796, S179e, S17a2, S17a6, S17aa, Sun, S17ae, S17b2, Ex, Ey : Single;
 S17be, S17ca, S17ce, S17d2, S17d6, D2, Mo : Single;
 S1806, S17ec, E, Incl, Ax, S1822, S1826, S182a, S1802, S182e, S1832 : Single;
 S1836, E2, E3, E4, C1, C2, MDeg, Mr, Vv, Rr, U, Sb, B, Cb, L, Rp : Single;
 Xx, Yv, Lam : Single;
 I17f4 : LongInt;
 Diff, Typ, Flag, Dist, Orb, Md : Integer;
Begin
 RAD := F4(PI_D / 180);
 PI2 := PI_D * 2;
 PIH := PI_D * 0.5;
 PI3H := PIH * 3;
 EPS := F4(RAD * F4(23.45));
 Dd := D; Mm := M; Yy := Y;
 S1724 := F4(Hh + F4(Mi / 60));
 S1728 := F4(S1724 - F4(Ofs));
 S172c := F4(Yy * 365);
 S172c := F4(F4(F4(F4(Mm * 31) + S172c) + Dd) - 31);
 S172c := FloorD(S172c);
 I1730 := Y;
 If Mm <= 2 Then Dec(I1730)
 Else S172c := F4(S172c - FloorD(F4(F4(Mm * F4(0.4)) + F4(2.3))));
 S172c := F4(F4(F4(S172c - FloorD(F4(I1730 / 100))) +
          FloorD(F4(I1730 * 0.25))) + FloorD(F4(I1730 / 400)));
 T := F4(F4(F4(S1728 / 24) + S172c) - 694325.0);
 { longitude du lieu en degres (est positif) }
 S1736 := F4(LonD + F4(LonM / 60));
 If West Then S1736 := -S1736;
 If S1736 < 0 Then S1736 := F4(S1736 + 360);
 S173c := F4(F4(S1736 / 15) + S1728);
 S1740 := F4(T * 236.555362 + 23750.30078125);
 S1740 := F4(S1740 * F4(1.15740741E-05));
 S1740 := F4(F4(S1740 - FloorD(S1740)) * 24);
 S1744 := F4(S1740 + S173c);
 If S1744 < 0 Then S1744 := F4(S1744 + 24);
 While S1744 > 24 Do S1744 := F4(S1744 - 24);
 { equation du temps, interpolee par decade }
 Idx := CIntD(F4(F4(F4(Mm * 3) + FloorD(F4(Dd / 10))) - 2));
 DMod := D Mod 10;
 If Idx < 1 Then Idx := 1;
 If Idx > 37 Then Idx := 37;
 V1 := EOTV[Idx];
 V2 := EOTV[Idx + 1];
 S175c := F4(F4(F4(Abs(V2) - Abs(V1)) * DMod) / 10);
 S175c := F4(S175c + V1);
 S175c := F4(S175c / 60);
 S1744 := F4(S1744 + S175c);
 { ---- maisons (systeme d'URRIS, bati sur le nombre d'or) ---- }
 If South Then Begin
  S1744 := F4(S1744 + 12);
  If S1744 > 24 Then S1744 := F4(S1744 - 24);
 End;
 Lat := F4(F4(F4(LatM) / 60) + LatD);
 Lat := F4(Lat * RAD);
 Ramc := F4(F4(S1744 * RAD) * 15);
 If Ramc >= PI2 Then Ramc := F4(Ramc - PI2);
 If Ramc < 0 Then Ramc := F4(Ramc + PI2);
 S1774 := F4(SSin(Ramc) * EPS);
 X := F4(SCos(Ramc) * SCos(S1774));
 If (X > F4(0.99995)) Or (X < F4(-0.99995)) Then
  X := F4(X - F4(SgnD(X) * F4(5E-05)));
 Mc := SAcos(X);
 If S1774 < 0 Then Mc := F4(PI2 - Mc);
 If Mc >= PI2 Then Mc := F4(Mc - PI2);
 For I := 1 To 5 Do Begin
  A[I] := F4(F4(F4(30 * I) * RAD) + Ramc);
  If A[I] >= PI2 Then A[I] := F4(A[I] - PI2);
  If Lat = PIH Then S1782 := F4(PI_D)
  Else Begin
   Kf := F4(0.381966);
   If (I = 2) Or (I = 4) Then Kf := F4(0.618034);
   If I = 3 Then Kf := 1;
   S1778 := F4(STan(Lat) * Kf);
   If A[I] = PIH Then A[I] := F4(A[I] - F4(0.001));
   S178a := 0;
   S178e := F4(S1778 / SCos(A[I]));
   S1782 := SAtn(S178e);
   S1792 := F4(SgnD(S1778) * Abs(S1782));
   If (A[I] < PI3H) And (A[I] > PIH) Then Begin
    S1792 := -S1792;
    S178a := 1;
   End;
   If S1792 < 0 Then S1792 := F4(S1792 + PI2);
   If S1792 = PIH - EPS Then S1792 := F4(S1792 - F4(0.001));
   S1778 := F4(F4(STan(A[I]) * SCos(S1792)) / SCos(F4(S1792 + EPS)));
   S1782 := SAtn(S1778);
   S1778 := F4(PIH - EPS);
   If (S1792 >= S1778) And (S1792 < PIH) Then S1782 := F4(S1782 - PI_D);
   If S178a = 1 Then S1782 := F4(S1782 + PI_D);
   If S1782 < 0 Then S1782 := F4(S1782 + PI2);
  End;
  If South Then A[I] := F4(S1782 + PI_D) Else A[I] := S1782;
 End;
 If South Then C.Cu[10] := F4(Mc + PI_D) Else C.Cu[10] := Mc;
 C.Cu[11] := A[1];
 C.Cu[12] := A[2];
 C.Cu[1] := A[3];
 C.Cu[2] := A[4];
 C.Cu[3] := A[5];
 C.Cu[4] := F4(Mc + PI_D);
 For I := 5 To 9 Do C.Cu[I] := F4(A[I - 4] + PI_D);
 For I := 1 To 12 Do Begin
  While C.Cu[I] > PI2 Do C.Cu[I] := F4(C.Cu[I] - PI2);
  C.Cu[I] := F4(C.Cu[I] / RAD);
 End;
 { ---- Soleil ---- }
 S1796 := F4(T * 0.985647342000007 + 278.964996337891);
 S1796 := F4(S1796 - F4(FloorD(F4(S1796 / 360)) * 360));
 S179e := F4(F4(T * F4(4.69E-05)) + F4(281.234985));
 S17a2 := F4(S1796 - S179e);
 S17a6 := F4(S17a2 * RAD);
 S17aa := F4(F4(F4(SSin(S17a6) * F4(1.91934)) +
          F4(SSin(F4(S17a6 * 2)) * F4(0.02))) + S17a2);
 Sun := F4(S17aa + S179e);
 S17ae := F4(F4(0.999721) / F4(F4(SCos(F4(S17aa * RAD)) * F4(0.01675)) + 1));
 S17b2 := F4(Sun * RAD);
 Ex := F4(SCos(S17b2) * S17ae);
 Ey := F4(SSin(S17b2) * S17ae);
 If Sun < 0 Then Sun := F4(Sun + 360);
 If Sun >= 360 Then Sun := F4(Sun - 360);
 C.Pl[1] := Sun;
 { ---- Lune ---- }
 S17be := F4(T * 13.17639653 + 33.2309989929199);
 S17be := F4(S17be - F4(FloorD(F4(S17be / 360)) * 360));
 S17ca := F4(T * 0.052953922 + 239.88200378418);
 S17ce := F4(T * 13.06499245 + 18.2940006256104);
 S17d2 := F4(F4(S17be - S1796) * RAD);
 S17d6 := F4(F4(S17be - S17ca) * RAD);
 S17ce := F4(S17ce * RAD);
 Mo := F4(F4(F4(SSin(S17d2) * F4(-0.0348)) -
       F4(SSin(F4(S17ce + S17a6)) * F4(0.0305))) +
       F4(SSin(F4(S17ce - S17a6)) * F4(0.041)));
 D2 := F4(S17d2 * 2);
 Mo := F4(F4(F4(F4(SSin(F4(D2 - S17a6)) * F4(0.459)) +
       F4(SSin(F4(D2 + S17ce)) * F4(0.0533))) +
       F4(SSin(F4(F4(D2 - S17ce) - S17a6)) * F4(0.0572))) + Mo);
 Mo := F4(F4(F4(Mo - F4(SSin(F4(S17d6 * 2)) * F4(0.1143))) +
       F4(SSin(F4(D2 - F4(S17ce * 2))) * F4(0.588))) +
       F4(SSin(F4(D2 - S17ce)) * F4(1.274)));
 Mo := F4(F4(F4(F4(F4(Mo - F4(SSin(S17a6) * F4(0.1856))) +
       F4(SSin(D2) * F4(0.6583))) + F4(SSin(F4(S17ce * 2)) * F4(0.2136))) +
       F4(SSin(S17ce) * F4(6.28875))) + S17be);
 If Mo >= 360 Then Mo := F4(Mo - 360);
 If Mo < 0 Then Mo := F4(Mo + 360);
 C.Pl[2] := Mo;
 { ---- planetes (elements orbitaux d'URRIS) ---- }
 For P := 3 To 10 Do Begin
  S1806 := 0;
  Case P Of
   3 : Begin
        S1796 := F4(T * 4.09237703 + 229.651000976562);
        S1796 := F4(S1796 - F4(FloorD(F4(S1796 / 360)) * 360));
        S179e := F4(F4(T * F4(4.253E-05)) + F4(75.913002));
        S17ec := F4(F4(T * F4(3.224E-05)) + F4(47.157));
        E := F4(0.205615); Incl := F4(7.003); Ax := F4(0.387098);
       End;
   4 : Begin
        S1796 := F4(T * 1.60216873 + 206.757995605469);
        S179e := F4(F4(T * F4(3.757E-05)) + F4(130.154007));
        S1796 := F4(S1796 - F4(FloorD(F4(S1796 / 360)) * 360));
        S17ec := F4(F4(T * F4(2.502E-05)) + F4(75.796997));
        E := F4(0.006816); Incl := F4(3.39364); Ax := F4(0.72333);
       End;
   5 : Begin
        S1796 := F4(T * 0.52407108 + 124.764999389648);
        S1796 := F4(S1796 - F4(FloorD(F4(S1796 / 360)) * 360));
        S179e := F4(F4(T * F4(5.038E-05)) + F4(334.251007));
        S17ec := F4(F4(T * F4(2.127E-05)) + F4(48.794));
        E := F4(0.093309); Incl := F4(1.8503); Ax := F4(1.52368);
       End;
   6 : Begin
        S1822 := F4(F4(T * F4(0.00115674)) + F4(135.035995));
        S1822 := F4(S1822 * RAD);
        S1826 := SSin(S1822);
        S182a := SCos(S1822);
        S1802 := F4(S1826 * F4(0.3314));
        S182e := F4(F4(S1826 * F4(0.000361)) + F4(S182a * F4(0.000129)));
        S1832 := F4(F4(S1826 * F4(0.007)) - F4(S182a * F4(0.02)));
        S1836 := F4(S182a * F4(0.000263));
        S1796 := F4(F4(T * F4(0.0831234)) + F4(268.596008));
        S1796 := F4(S1796 + S1802);
        S1796 := F4(S1796 - F4(FloorD(F4(S1796 / 360)) * 360));
        E := F4(S182e + F4(0.048294));
        S1832 := F4(S1832 / E);
        S17ec := F4(F4(T * F4(2.767E-05)) + F4(99.453003));
        S179e := F4(F4(F4(T * F4(4.908E-05)) + S1832) + F4(13.114));
        Incl := F4(1.30874);
        Ax := F4(S1836 + F4(5.2028));
       End;
   7 : Begin
        S1796 := F4(F4(T * F4(0.0335089)) + F4(278.266998));
        S1796 := F4(S1796 - F4(FloorD(F4(S1796 / 360)) * 360));
        E := F4(0.054311);
        { l'original multipliait ici par une variable nulle }
        S179e := F4(91.523003);
        S17ec := F4(F4(T * F4(2.391E-05)) + F4(112.790001));
        Incl := F4(2.49252); Ax := F4(9.5521);
       End;
   8 : Begin
        S1806 := F4(-0.0012);
        S1796 := F4(F4(T * F4(0.0117699)) + F4(247.658005));
        S1796 := F4(S1796 - F4(FloorD(F4(S1796 / 360)) * 360));
        E := F4(0.047319);
        S179e := F4(F4(T * F4(1.365E-05)) + F4(169.154999));
        S17ec := F4(F4(T * F4(1.365E-05)) + F4(73.482002));
        Incl := F4(0.772464); Ax := F4(19.2169);
       End;
   9 : Begin
        S1806 := F4(-0.0181);
        S1796 := F4(F4(T * F4(0.00601955)) + F4(87.220001));
        S1796 := F4(S1796 - F4(FloorD(F4(S1796 / 360)) * 360));
        E := F4(0.008562);
        S179e := F4(F4(T * F4(2.25E-05)) + F4(43.756001));
        S17ec := F4(F4(T * F4(3.009E-05)) + F4(130.692993));
        Incl := F4(1.77924); Ax := F4(30.1129112);
       End;
  Else Begin
        S17a2 := F4(F4(T * F4(0.00397943)) + F4(230.669998));
        S17a2 := F4(S17a2 - F4(FloorD(F4(S17a2 / 360)) * 360));
        S17ec := F4(F4(T * F4(3.823E-05)) + F4(109.059998));
        S179e := F4(S17ec + F4(114.269997));
        S1796 := F4(S17a2 + S179e);
        Incl := F4(17.1704693); Ax := F4(39.4387131); E := F4(0.250236);
       End;
  End;
  E2 := F4(E * E);
  E3 := F4(E2 * E);
  E4 := F4(E2 * E2);
  C1 := F4(F4(F4(E * 2) - F4(E3 * F4(0.25))) / RAD);
  C2 := F4(F4(F4(E2 * F4(1.25)) - F4(F4(E4 * 11) / 24)) / RAD);
  MDeg := F4(S1796 - S179e);
  Mr := F4(MDeg * RAD);
  Vv := F4(F4(SSin(Mr) * C1) + F4(SSin(F4(Mr * 2)) * C2));
  Vv := F4(Vv + F4(F4(F4(SSin(F4(Mr * 3)) / F4(RAD * 12)) * E3) * 13));
  Vv := F4(Vv + F4(F4(F4(SSin(F4(Mr * 4)) / F4(RAD * 96)) * E4) * 103));
  Vv := F4(Vv + MDeg);
  Rr := F4(F4(Ax / F4(F4(SCos(F4(Vv * RAD)) * E) + 1)) * F4(1 - E2));
  U := F4(F4(Vv - S17ec) + S179e);
  I17f4 := CIntD(F4(U / 360));
  U := F4(U - F4(360.0 * I17f4));
  U := F4(U * RAD);
  Sb := F4(SSin(F4(Incl * RAD)) * SSin(U));
  If (Sb < F4(-0.999995)) Or (Sb > F4(0.999995)) Then
   Sb := F4(Sb - F4(SgnD(Sb) * F4(5E-06)));
  B := SAsin(Sb);
  Cb := SCos(B);
  If (Cb < F4(1E-06)) And (Cb > F4(-1E-06)) Then
   Cb := F4(SgnD(Cb) * F4(1E-06));
  X := F4(SCos(U) / Cb);
  If (X < F4(-0.999995)) Or (X > F4(0.999995)) Then
   X := F4(X - F4(SgnD(X) * F4(5E-06)));
  L := SAcos(X);
  If B < 0 Then L := F4(PI2 - L);
  Rr := F4(Rr + S1806);
  L := F4(F4(S17ec * RAD) + L);
  Rp := F4(SCos(B) * Rr);
  Xx := F4(SCos(L) * Rp);
  Yv := F4(SSin(L) * Rp);
  Xx := F4(Xx + Ex);
  Yv := F4(Yv + Ey);
  Lam := F4(SAtn(F4(Yv / Xx)) / RAD);
  If Xx < 0 Then Lam := F4(Lam + 180);
  If Lam < 0 Then Lam := F4(Lam + 360);
  If Lam >= 360 Then Lam := F4(Lam - 360);
  C.Pl[P] := Lam;
 End;
 { ---- points entiers ---- }
 For I := 1 To 15 Do C.P[I] := 0;
 For I := 1 To 10 Do C.P[I] := FloorI(C.Pl[I]);
 For I := 1 To 12 Do C.H[I] := FloorI(C.Cu[I]);
 C.H[13] := C.H[1];
 C.P[11] := C.H[1];
 C.P[12] := C.H[10];
 C.P[13] := 102;
 { ---- aspects entre les 13 points ---- }
 For I := 1 To 15 Do
  For J := 1 To 15 Do Begin
   C.AT[I, J] := 0;
   C.AD[I, J] := 0;
  End;
 For I := 1 To 12 Do
  For J := I + 1 To 13 Do Begin
   Diff := Abs(C.P[J] - C.P[I]);
   Typ := Diff Div 30 + 1;
   Flag := 0;
   If Typ > 7 Then Begin
    Typ := 14 - Typ;
    Flag := 1;
   End;
   Dist := Diff Mod 30;
   Orb := FloorI((ORBS[I] + ORBS[J]) * 0.5 + 1);
   Md := 0;
   If (Flag = 0) And (Orb + Dist >= 30) Then Md := 1
   Else If (Flag = 1) And (Orb + Dist >= 30) Then Md := 2;
   If Md = 1 Then Begin Inc(Typ); Dist := 30 - Dist; End;
   If Md = 2 Then Begin Dec(Typ); Dist := 30 - Dist; End;
   If Typ = 8 Then Typ := 6 Else If Typ = 0 Then Typ := 2;
   If Orb >= Dist Then Begin
    C.AT[I, J] := Typ;
    If Dist > 9 Then Dist := 9;
    C.AD[I, J] := Dist;
   End;
  End;
End;

{ Theme du ciel du jour : midi T.U., longitude 0, latitude 0 05' N }
Procedure CalcDay(D, M, Y : Integer; Var C : TChart);
Begin
 CalcChart(D, M, Y, 12, 0, 0, 0, 0, False, 0, 5, False, C);
End;

{ ================================================================== }
{ Interpretation (portage fidele du module BENURRIS d'URRIS)         }
{ ================================================================== }

Function PhiPow(K : Integer) : Single;
Var
 I : Integer;
 R : Double;
Begin
 R := 1;
 For I := 1 To K Do R := R * F4(1.618);
 PhiPow := F4(R);
End;

Function ForceOf(V : Double) : Integer;
Var
 C : Integer;
 X : Single;
Begin
 C := 0;
 X := V;
 While X > 1 Do Begin
  X := F4(X / F4(1.618));
  Inc(C);
 End;
 ForceOf := C;
End;

Procedure SortD(Var A : Array Of Double; N : Integer);
Var
 I, J : Integer;
 T : Double;
Begin
 For I := 0 To N - 2 Do
  For J := 0 To N - 2 - I Do
   If A[J] > A[J + 1] Then Begin
    T := A[J]; A[J] := A[J + 1]; A[J + 1] := T;
   End;
End;

{ Multiplie les puissances selon les rapports de signes entre la      }
{ planete et les references Soleil, Lune, Ascendant et Milieu du ciel }
Procedure SignBoost(S, R : Integer; IsSelf : Boolean; Var P : Single);
Var
 Ph : Single;
Begin
 Ph := F4(1.618);
 If (S = R) And Not IsSelf Then P := F4(P * PhiPow(6));
 If (S = R + 1) Or (S = R - 1) Or (S = R + 5) Or (S = R - 5) Then
  P := F4(P * PhiPow(2));
 If (S = R + 2) Or (S = R - 2) Then P := F4(P * PhiPow(3));
 If (S = R + 3) Or (S = R - 3) Then P := F4(P * PhiPow(4));
 If (S = R + 4) Or (S = R - 4) Then P := F4(P * PhiPow(5));
 If (S = R + 6) Or (S = R - 6) Then P := F4(P * Ph);
End;

Procedure Interpret(Var N, D : TChart; Var R : TInterp);
Var
 I, F, K, Rf, Wrap, Start, Cnt, Kk : Integer;
 Cusp : Array[1..13] Of Integer;
 NLon, DLon : Array[1..12] Of Integer;
 Pn, Pd : Array[1..12] Of Single;
 Sn, Sd : Array[0..9] Of Double;
 Found : Boolean;
 Ph, Ph2 : Single;
 Refs : Array[1..4] Of Integer;
Begin
 Refs[1] := 1; Refs[2] := 2; Refs[3] := 11; Refs[4] := 12;
 For I := 1 To 12 Do Begin
  If I <= 10 Then K := N.P[I] Else If I = 11 Then K := N.H[1]
  Else K := N.H[10];
  R.nS[I] := K Div 30 + 1;
  R.nD[I] := K Mod 30;
  If I <= 10 Then Begin
   R.dS[I] := D.P[I] Div 30 + 1;
   R.dD[I] := D.P[I] Mod 30;
  End Else Begin
   R.dS[I] := 0;
   R.dD[I] := 0;
  End;
  R.hS[I] := N.H[I] Div 30 + 1;
  R.hD[I] := N.H[I] Mod 30;
  Cusp[I] := N.H[I];
 End;
 Cusp[13] := Cusp[1];
 For I := 1 To 12 Do Begin
  NLon[I] := R.nS[I] * 30 + R.nD[I] - 30;
  If I <= 10 Then DLon[I] := R.dS[I] * 30 + R.dD[I] - 30 Else DLon[I] := 0;
 End;
 Wrap := 0;
 For F := 1 To 12 Do
  If (Wrap = 0) And (Cusp[F] > Cusp[F + 1]) Then Wrap := F;
 For I := 1 To 10 Do Begin
  Found := False;
  For F := 1 To 12 Do
   If (Not Found) And (DLon[I] >= Cusp[F]) And (DLon[I] < Cusp[F + 1]) Then
   Begin
    R.tHouse[I] := F;
    Found := True;
   End;
  If Not Found Then R.tHouse[I] := Wrap;
  Found := False;
  For F := 1 To 12 Do
   If (Not Found) And (NLon[I] >= Cusp[F]) And (NLon[I] < Cusp[F + 1]) Then
   Begin
    R.nHouse[I] := F;
    Found := True;
   End;
  If Not Found Then R.nHouse[I] := Wrap;
  R.Master[I] := 0;
  For F := 1 To 12 Do
   If RULER[R.hS[F]] = I Then R.Master[I] := F;
  If R.Master[I] = 0 Then R.Master[I] := R.nHouse[I];
 End;
 { ---- puissances ---- }
 Ph := F4(1.618);
 Ph2 := PhiPow(2);
 For I := 1 To 12 Do Begin
  If I <= 10 Then Begin Pn[I] := Ph; Pd[I] := Ph; End
  Else Begin Pn[I] := 0; Pd[I] := 0; End;
 End;
 For I := 1 To 10 Do
  For K := 1 To 2 Do Begin
   F := K;
   While F <= 12 Do Begin
    If R.nS[I] = R.hS[F] Then
     If K = 1 Then Pn[I] := F4(Pn[I] * Ph2) Else Pn[I] := F4(Pn[I] * Ph);
    If R.dS[I] = R.hS[F] Then
     If K = 1 Then Pd[I] := F4(Pd[I] * Ph2) Else Pd[I] := F4(Pd[I] * Ph);
    F := F + 3;
   End;
  End;
 For I := 1 To 12 Do
  For K := 1 To 4 Do Begin
   Rf := Refs[K];
   SignBoost(R.nS[I], R.nS[Rf], Rf = I, Pn[I]);
   SignBoost(R.dS[I], R.nS[Rf], False, Pd[I]);
  End;
 For I := 1 To 10 Do Begin
  R.Pn[I] := FloorD(Pn[I]);
  R.Pd[I] := FloorD(Pd[I]);
  R.Fn[I] := ForceOf(R.Pn[I]);
  If R.Fn[I] = 0 Then R.Fn[I] := 1;
  R.Fd[I] := ForceOf(R.Pd[I]);
  If R.Fd[I] = 0 Then R.Fd[I] := 1;
  Sn[I - 1] := R.Pn[I];
  Sd[I - 1] := R.Pd[I];
 End;
 SortD(Sn, 10);
 SortD(Sd, 10);
 { dominante natale : plus forte puissance hors Soleil et Lune }
 R.Dom := 0;
 K := 10;
 While (R.Dom = 0) And (K >= 1) Do Begin
  For I := 10 DownTo 3 Do
   If Sn[K - 1] = R.Pn[I] Then R.Dom := I;
  Dec(K);
 End;
 If R.Dom = 0 Then R.Dom := 3;
 R.Puis := ForceOf(R.Pn[R.Dom]);
 { dominante du jour }
 R.DDom := 0;
 K := 10;
 Start := 1;
 Kk := 0;
 Repeat
  Cnt := 0;
  For I := Start To 10 Do
   If (Cnt = 0) And (Sd[K - 1] = R.Pd[I]) Then Begin
    R.DDom := I;
    Cnt := 1;
   End;
  If (R.DDom = 2) And (K >= 2) Then
   If Sd[K - 2] = Sd[K - 1] Then Begin
    R.DDom := 0;
    Inc(Start);
   End;
  If R.DDom = 0 Then Dec(K);
  Inc(Kk);
 Until (R.DDom <> 0) Or (K < 1) Or (Kk > 40);
 If R.DDom = 0 Then R.DDom := 1;
 R.DForce := ForceOf(R.Pd[R.DDom]);
 R.Asc := R.hS[1];
End;

{ Selection des previsions : aspects natals par ordre d'orbe, ceux de }
{ la dominante du jour d'abord, retenus si les memes planetes forment }
{ un aspect dans le ciel du jour.                                     }
Procedure CalcPrev(Var N, D : TChart; Var R : TInterp);
Var
 SelT, SelI, SelJ : Array[1..5] Of Integer;
 Cnt, Thr, I, J, T, O, A, B, X, Dt, J2, Pd, Pa, Pb : Integer;
 Tmp : TPrev;
Begin
 Cnt := 0;
 Thr := 0;
 While (Cnt < 5) And (Thr < 30) Do Begin
  If Thr = 5 Then Thr := 6;
  For I := 1 To 9 Do
   For J := I + 1 To 10 Do
    If Cnt < 5 Then Begin
     If (Thr > 5) And ((J = 2) Or (I = 2)) Then Continue;
     If (Thr > 0) And ((I = R.DDom) Or (J = R.DDom)) Then Continue;
     T := N.AT[I, J];
     O := N.AD[I, J];
     If (Thr <= 0) And ((I = R.DDom) Or (J = R.DDom)) Then Begin
      If (T <> 0) And (O < 5) Then Begin
       Inc(Cnt);
       SelT[Cnt] := T; SelI[Cnt] := I; SelJ[Cnt] := J;
      End;
      Continue;
     End;
     If (O = Thr) And (T <> 0) Then Begin
      Inc(Cnt);
      SelT[Cnt] := T; SelI[Cnt] := I; SelJ[Cnt] := J;
     End;
    End;
  Inc(Thr);
 End;
 PrevN := 0;
 For X := 1 To Cnt Do Begin
  A := SelI[X];
  B := SelJ[X];
  Pd := POL[R.DDom]; Pa := POL[A]; Pb := POL[B];
  If ((Pd = 0) And (Pa = 1) And (Pb = 0)) Or
     ((Pd = 0) And (Pa = Pb) And (Pa = 1)) Or
     ((Pd = 1) And (Pa = 0) And (Pb = 1)) Then Begin
   A := SelJ[X]; B := SelI[X];
  End;
  Dt := D.AT[SelI[X], SelJ[X]];
  If Dt = 0 Then Continue;
  If A <= B Then J2 := B - 1 Else J2 := B;
  Inc(PrevN);
  PrevL[PrevN].A := A;
  PrevL[PrevN].B := B;
  PrevL[PrevN].DType := Dt;
  PrevL[PrevN].NType := SelT[X];
  PrevL[PrevN].Idx := 63 * (A - 1) + 9 * Dt + (J2 - 1) - 9;
 End;
 For I := 1 To PrevN - 1 Do
  For J := 1 To PrevN - I Do
   If PrevL[J].Idx > PrevL[J + 1].Idx Then Begin
    Tmp := PrevL[J]; PrevL[J] := PrevL[J + 1]; PrevL[J + 1] := Tmp;
   End;
End;

{ Theme compare : points medians des deux themes (methode d'URRIS) }
Procedure CalcComp(Var R1 : TInterp; Var N2 : TChart; Var C : TComp);
Var
 I, K, F, Rf, A, B, M, Dm, Ac, Ae, R1u, DgS, DgM, DgL, DgV : Integer;
 S2, D2, H2 : Array[1..12] Of Integer;
 P : Array[1..12] Of Single;
 P2, Srt : Array[0..9] Of Double;
 Ph, Fq : Single;
 Refs : Array[1..4] Of Integer;

 Function Mid(X, Y : Integer) : Integer;
 Var
  Z : Integer;
 Begin
  Z := FloorI((X + Y) * 0.5);
  If Abs(X - Y) > 180 Then Z := Z + 180;
  If Z > 359 Then Z := Z - 360;
  Mid := Z;
 End;

 Function DigOf(Sg, Dg : Integer) : Integer;
 Begin
  DigOf := Ord(DIG[(10 * Sg - 10) + Dg Div 6 + 1]) - 48 + 1;
 End;

 Function Part(Kp, Dd : Integer) : Integer;
 Begin
  Part := (12 * C.cS[Kp] + 144 * Dd - 152) + 3 * (C.cD[Kp] Div 10);
 End;

Begin
 Refs[1] := 1; Refs[2] := 2; Refs[3] := 11; Refs[4] := 12;
 For I := 1 To 12 Do Begin
  If I <= 10 Then K := N2.P[I] Else If I = 11 Then K := N2.H[1]
  Else K := N2.H[10];
  S2[I] := K Div 30 + 1; D2[I] := K Mod 30;
  H2[I] := N2.H[I];
 End;
 For I := 1 To 12 Do Begin
  A := R1.nS[I] * 30 + R1.nD[I] - 30;
  B := S2[I] * 30 + D2[I] - 30;
  M := Mid(A, B);
  C.cS[I] := M Div 30 + 1;
  C.cD[I] := M Mod 30;
  A := R1.hS[I] * 30 + R1.hD[I] - 30;
  B := H2[I] Div 30 * 30 + H2[I] Mod 30;
  M := Mid(A, B);
  C.hS[I] := M Div 30 + 1;
 End;
 Ph := F4(1.618);
 { l'original utilisait ici la force de la dominante du jour au carre }
 Fq := F4(1.0 * R1.DForce * R1.DForce);
 For I := 1 To 12 Do
  If I <= 10 Then P[I] := Ph Else P[I] := 0;
 For I := 1 To 10 Do
  For K := 1 To 2 Do Begin
   F := K;
   While F <= 12 Do Begin
    If C.cS[I] = C.hS[F] Then
     If K = 1 Then P[I] := F4(P[I] * Fq) Else P[I] := F4(P[I] * Ph);
    F := F + 3;
   End;
  End;
 For I := 1 To 12 Do
  For K := 1 To 4 Do Begin
   Rf := Refs[K];
   SignBoost(C.cS[I], C.cS[Rf], Rf = I, P[I]);
  End;
 For I := 1 To 10 Do Begin
  P2[I - 1] := FloorD(P[I]);
  Srt[I - 1] := P2[I - 1];
  C.F[I] := ForceOf(P2[I - 1]);
  If C.F[I] = 0 Then C.F[I] := 1;
 End;
 SortD(Srt, 10);
 Dm := 0;
 K := 10;
 While (Dm = 0) And (K >= 1) Do Begin
  For I := 10 DownTo 3 Do
   If Srt[K - 1] = P2[I - 1] Then Dm := I;
  Dec(K);
 End;
 If Dm = 0 Then Dm := 3;
 C.Dom := Dm;
 R1u := RULER[C.hS[1]];
 C.Car := C.cS[R1u] * 12 + 1;
 Ac := DOMI[Dm];
 If (Dm = 3) And (POL[R1u] = 0) Then Ac := 6;
 If (Dm = 4) And (POL[R1u] = 1) Then Ac := 7;
 If Ac > 6 Then Ae := Ac - 6 Else Ae := Ac + 6;
 C.Pos := 144 * Dm + 12 * Ac - 12 + 3 * (C.cD[Dm] Div 10) - 140;
 C.Neg := 144 * Dm + 12 * Ae - 12 + 3 * (C.cD[Dm] Div 10) - 140;
 DgS := DigOf(C.cS[1], C.cD[1]);
 DgM := DigOf(C.cS[5], C.cD[5]);
 DgL := DigOf(C.cS[2], C.cD[2]);
 DgV := DigOf(C.cS[4], C.cD[4]);
 C.Sun := Part(1, DgS);
 C.Mars := Part(5, DgM);
 C.Moon := Part(2, DgL);
 C.Ven := Part(4, DgV);
 If (C.Moon = C.Ven) Or (C.Mars = C.Ven) Or (C.Sun = C.Ven) Then C.Ven := 0;
 If (C.Mars = C.Moon) Or (C.Sun = C.Moon) Then C.Moon := 0;
 If C.Sun = C.Mars Then C.Mars := 0;
 If C.Moon = 0 Then C.Moon := 12 * C.cS[2] + 144 * DgL - 155;
 C.Vit := (C.F[5] + C.F[1]) Div 2;
 C.Sen := (C.F[4] + C.F[2]) Div 2;
End;

{ Numero de bloc de texte d'un enregistrement de NATURRIS }
Function NatBlk(Rc : Integer) : Integer;
Begin
 If Rc <= 1440 Then NatBlk := (Rc - 1) Div 3 + 1
 Else If Rc <= 1584 Then NatBlk := 481 + (Rc - 1441) Div 12
 Else NatBlk := 493 + (Rc - 1585) Div 12;
End;

{ Chiffre de la structure pour un signe et un degre }
Function DigAt(I : Integer) : Integer;
Begin
 If (I < 1) Or (I > 120) Then DigAt := 1
 Else DigAt := Ord(DIG[I]) - 48 + 1;
End;

{ Enregistrements "en particulier" pour une planete natale }
Procedure NatParts(Sg, Dg : Integer; Var P1, P2 : Integer);
Var
 C, E, Sub : Integer;
Begin
 C := DigAt((Sg * 10 - 10) + Dg Div 6 + 1);
 E := 0;
 If Dg Mod 6 <> 0 Then Begin
  If (Dg Mod 6) + (Dg Div 6) > 5 Then Sub := 5 Else Sub := 0;
  E := DigAt((Sg * 10 + Dg Mod 6 - 5) + Dg Div 6 - Sub);
 End;
 If E = C Then E := 0;
 P1 := 12 * Sg + 144 * C - 152 + 3 * (Dg Div 10);
 If E <> 0 Then P2 := 12 * Sg + 144 * E - 152 + 3 * (Dg Div 10)
 Else P2 := 0;
End;

Function KeyNat(I : Integer) : String;
Var
 A, A2 : Integer;
 S : String;
Begin
 A := (RI.nS[I] * 10 - 10) + RI.nD[I] Div 6 + 25;
 S := MotW(A);
 If RI.nD[I] Mod 6 <> 0 Then Begin
  A2 := (RI.nD[I] Mod 6) + A + 4;
  If (RI.nD[I] Div 6) + (RI.nD[I] Mod 6) + 4 > 10 Then A2 := A2 - 5;
  S := S + ' ' + Tx(S_AND) + ' ' + MotW(A2);
 End;
 KeyNat := S;
End;

Function KeyDay(I : Integer) : String;
Begin
 KeyDay := MotW((RI.dS[I] * 10 - 10) + RI.dD[I] Div 6 + 25);
End;

Function KeyHouse(F : Integer) : String;
Begin
 KeyHouse := MotW(12 + F) + ' : ' + MotW(144 + RI.hS[F]) + ' / ' +
             MotW((RI.hS[F] * 10 - 10) + RI.hD[F] Div 6 + 25);
End;

{ Domicile (influence positive) de la dominante natale }
Procedure DomSigns(Dm, AscS : Integer; Var Pos, Neg : Integer);
Begin
 Pos := DOMI[Dm];
 If (Dm = 3) And (POL[RULER[AscS]] = 0) Then Pos := 6;
 If (Dm = 4) And (POL[RULER[AscS]] = 1) Then Pos := 7;
 If Pos > 6 Then Neg := Pos - 6 Else Neg := Pos + 6;
End;

{ ================================================================== }
{ Fuseaux horaires et villes (portage du module DONURRIS)            }
{ ================================================================== }

Function Field(S : String; N : Integer) : String;
Var
 I, K : Integer;
 R : String;
Begin
 K := 1;
 R := '';
 For I := 1 To Length(S) Do
  If S[I] = '|' Then Inc(K)
  Else If K = N Then R := R + S[I];
 Field := R;
End;

Function ValI(S : String) : LongInt;
Var
 V : LongInt;
 E : Integer;
Begin
 Val(Trim(S), V, E);
 If E <> 0 Then V := 0;
 ValI := V;
End;

{ Recherche d'une ville ; renvoie son nom ou '' }
Function FindCity(Ctry, Name : String; Var Lon, Lat : Integer) : String;
Var
 I, Best : Integer;
 C3, N, U : String;
Begin
 C3 := PadR(UpStr(Ctry), 3);
 N := UpStr(Trim(Name));
 Best := 0;
 FindCity := '';
 If N = '' Then Exit;
 For I := 1 To NCITY Do
  If Copy(CITY[I], 1, 3) = C3 Then Begin
   U := UpStr(Field(Copy(CITY[I], 4, 40), 1));
   If U = N Then Begin Best := I; Break; End;
   If (Best = 0) And (Copy(U, 1, Length(N)) = N) Then Best := I;
  End;
 If Best > 0 Then Begin
  Lon := ValI(Field(CITY[Best], 2));
  Lat := ValI(Field(CITY[Best], 3));
  FindCity := Field(Copy(CITY[Best], 4, 40), 1);
 End;
End;

Function CountryKnown(Ctry : String) : Boolean;
Var
 I : Integer;
 C3 : String;
Begin
 C3 := PadR(UpStr(Ctry), 3);
 CountryKnown := False;
 For I := 1 To NATL Do
  If Copy(ATL[I], 1, 3) = C3 Then CountryKnown := True;
 For I := 1 To NCITY Do
  If Copy(CITY[I], 1, 3) = C3 Then CountryKnown := True;
End;

{ Zone (ligne d'ATL) du pays ou de l'etat, selon la position }
Function FindZone(Key : String; Lon, Lat : Integer) : Integer;
Var
 K3 : String;
 I, J, H, First : Integer;
Begin
 K3 := PadR(UpStr(Key), 3);
 H := 0;
 For I := 1 To 3 Do
  If Ord(K3[I]) > 64 Then H := H + Ord(K3[I]) - 64;
 J := H * 4;
 If (J > 260) Or (J < 1) Then J := 1;
 First := 0;
 FindZone := 0;
 For I := 1 To NATL Do Begin
  If Copy(ATL[J], 1, 3) = K3 Then Begin
   If First = 0 Then First := J;
   If ValI(Field(ATL[J], 2)) = 0 Then Begin FindZone := J; Exit; End;
   If (Lon >= ValI(Field(ATL[J], 4))) And (Lon <= ValI(Field(ATL[J], 5)))
      And (Lat >= ValI(Field(ATL[J], 7))) And
      (Lat <= ValI(Field(ATL[J], 6))) Then Begin
    FindZone := J;
    Exit;
   End;
  End;
  Inc(J);
  If J > 260 Then J := 1;
 End;
 FindZone := First;
End;

Function HexB(S : String; P : Integer) : Integer;
Var
 I, V, C : Integer;
Begin
 V := 0;
 For I := P To P + 1 Do Begin
  C := Ord(S[I]);
  If C >= 65 Then C := C - 55 Else C := C - 48;
  V := V * 16 + C;
 End;
 HexB := V;
End;

{ Entree (3 octets) de l'annee Yr (0..99) de la table T }
Procedure FusEntry(T, Yr : Integer; Var B0, B1, B2 : Integer);
Var
 R, Y, N, Ln, Ps : Integer;
Begin
 R := FUSIX[T];
 Y := 0;
 Repeat
  Ln := R Div 9 + 1;
  Ps := (R Mod 9) * 8 + 1;
  N := HexB(FUS[Ln], Ps);
  If Y + N > Yr Then Begin
   B0 := HexB(FUS[Ln], Ps + 2);
   B1 := HexB(FUS[Ln], Ps + 4);
   B2 := HexB(FUS[Ln], Ps + 6);
   Exit;
  End;
  Y := Y + N;
  Inc(R);
 Until R >= FUSIX[T + 1];
 B0 := 0; B1 := 0; B2 := 0;
End;

Procedure Sub320(Var X, Q : Integer; Lim, Stp : Integer);
Begin
 Q := 0;
 While Lim < X Do Begin
  X := X - Stp;
  Inc(Q);
 End;
End;

{ Decalage T.U. (heures) pour la zone Z a une date donnee }
Function ZoneOffset(Z, D, M, Y : Integer) : Real;
Var
 Yr, T, P0, P1, P2, C0, B0, B1, B2, A6, Ac, M1, D1, Q0, Q2, Q3, Q4 : Integer;
 Eb8, Dt1, Dt2, D2x, Md, X : Integer;
 O1, O2, O3, Off : Real;
 Vl : LongInt;
Begin
 ZoneOffset := 0;
 If Z = 0 Then Exit;
 T := ValI(Field(ATL[Z], 8));
 Yr := Y - 1900;
 If Yr < 0 Then Yr := 0;
 If Yr > 99 Then Yr := 99;
 FusEntry(T, Yr, B0, B1, B2);
 If Yr > 0 Then FusEntry(T, Yr - 1, P0, P1, P2) Else P2 := B2;
 C0 := P2;
 Vl := LongInt(B0) + 256 * LongInt(B1);
 If Vl > 32767 Then Vl := Vl - 65536;
 Vl := Vl + 32000;
 A6 := Vl Div 10;
 Ac := Vl - 10 * A6;
 M1 := A6 Div 100;
 D1 := A6 - 100 * M1;
 X := C0; Sub320(X, Q0, 31, 31);
 Sub320(M1, Q2, 12, 12);
 Sub320(D1, Q3, 31, 31);
 Eb8 := 3 * Q2 + Q3;
 Dt1 := 100 * M1 + D1;
 D2x := B2; Sub320(D2x, Q4, 31, 31);
 Dt2 := (Eb8 + M1) * 100 + D2x;
 O1 := Q0 * 0.5 - 1.5;
 O2 := Ac * 0.5 - 1.5;
 O3 := Q4 * 0.5 - 1.5;
 Md := M * 100 + D;
 Off := 0;
 If Dt1 > Md Then Off := O1;
 If (Dt1 <= Md) And (Dt2 >= Md) Then Off := O2;
 If Dt2 < Md Then Off := O3;
 ZoneOffset := Off + ValI(Field(ATL[Z], 3));
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

Procedure TextAt(X, Y : Integer; S : String; C : Integer);
Begin
 SetColor(C);
 OutTextXY(X, Y, S);
End;

Procedure TextAmp(X, Y : Integer; S : String; C : Integer);
Var
 P : Integer;
 T : String;
Begin
 P := Pos('&', S);
 T := StripAmp(S);
 SetColor(C);
 OutTextXY(X, Y, T);
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
 NMENU = 5;
 A_NEW = 1; A_OPEN = 2; A_SAVE = 3; A_EXPORT = 4; A_QUIT = 5;
 A_NATAL = 6; A_HOUSES = 7; A_WHEEL = 8; A_PLDET = 9; A_HSDET = 10;
 A_DOMIN = 11; A_ASC = 12; A_DATE = 13; A_DAY = 14; A_PREV = 15;
 A_TAROT = 16; A_DDOM = 17; A_DPDET = 18; A_COMP = 19; A_GUIDE = 20;
 A_ABOUT = 21;
 MTitle : Array[1..NMENU] Of Integer = (M_FILE, M_THEME, M_DAY, M_COMP,
  M_HELP);
 MCount : Array[1..NMENU] Of Integer = (6, 8, 7, 1, 2);
 MItem : Array[1..NMENU, 1..8] Of Integer = (
  (M_NEW, M_OPEN, M_SAVE, M_EXPORT, 0, M_QUIT, 0, 0),
  (M_PLANETS, M_HOUSES, M_WHEEL, 0, M_PLDET, M_HSDET, M_DOMIN, M_ASCEND),
  (M_DATE, 0, M_DAYTH, M_PREV, M_TAROT, M_DDOM, M_DPDET, 0),
  (M_COMPTH, 0, 0, 0, 0, 0, 0, 0),
  (M_GUIDE, M_ABOUT, 0, 0, 0, 0, 0, 0));
 MAct : Array[1..NMENU, 1..8] Of Integer = (
  (A_NEW, A_OPEN, A_SAVE, A_EXPORT, 0, A_QUIT, 0, 0),
  (A_NATAL, A_HOUSES, A_WHEEL, 0, A_PLDET, A_HSDET, A_DOMIN, A_ASC),
  (A_DATE, 0, A_DAY, A_PREV, A_TAROT, A_DDOM, A_DPDET, 0),
  (A_COMP, 0, 0, 0, 0, 0, 0, 0),
  (A_GUIDE, A_ABOUT, 0, 0, 0, 0, 0, 0));
 MKey : Array[1..NMENU, 1..8] Of String[6] = (
  ('F2', 'F3', '', '', '', 'Alt+X', '', ''),
  ('F5', 'F6', 'F7', '', '', '', '', ''),
  ('F4', '', 'F8', 'F9', '', '', '', ''),
  ('', '', '', '', '', '', '', ''),
  ('F1', '', '', '', '', '', '', ''));

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
  L := Length(StripAmp(Tx(MItem[M, I]))) * 8 + Length(MKey[M, I]) * 8 + 40;
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

{ ouverture d'un menu : choix grises tant qu'aucun theme n'est ouvert }
Procedure MenuInit(M : LongInt);
Var
 I, A : Integer;
Begin
 M := M - 900;
 If (M < 1) Or (M > NMENU) Then Exit;
 For I := 1 To MCount[M] Do Begin
  A := MAct[M, I];
  If (A <> 0) And (A <> A_NEW) And (A <> A_OPEN) And (A <> A_EXPORT) And
     (A <> A_QUIT) And (A <> A_DATE) And (A <> A_GUIDE) And (A <> A_ABOUT)
  Then MnAttr(100 + A, MIA_DISABLED, Not HasCur);
 End;
End;

{ ================================================================== }
{ Tampon de lignes affichees                                         }
{ ================================================================== }

Procedure VClear;
Begin
 VLN := 0;
 VTop := 0;
 WrapS := '';
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
   If W <> '' Then Begin
    If WrapS = '' Then WrapS := W
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
 If WrapS <> '' Then VAdd(WrapS, WrapC, 0, WrapI, 0);
 WrapS := '';
End;

Procedure VText(S : String; C, Ind : Integer);
Begin
 WrapC := C;
 WrapI := Ind;
 WrapWords(S);
 WrapFlush;
End;

{ Paragraphe d'un bloc de texte integre }
Procedure VBlock(B, C, Ind : Integer);
Var
 I : Integer;
Begin
 If (B < 1) Or (B > NBLK) Then Exit;
 WrapC := C;
 WrapI := Ind;
 For I := BLK[B] To BLK[B + 1] - 1 Do
  If (Length(TXL[I]) > 0) And (TXL[I][1] = '~') Then Begin
   WrapFlush;
   VAdd(Copy(TXL[I], 2, 80), C, 1, 0, 0);
  End Else WrapWords(TXL[I]);
 WrapFlush;
End;

Procedure VTitle(S : String);
Begin
 VAdd(S, Yellow, 2, 0, 0);
 VBlank;
End;

Procedure VSect(S : String);
Begin
 VAdd(S, LightCyan, 0, 1, 0);
End;

{ ================================================================== }
{ Dessin de l'ecran                                                  }
{ ================================================================== }

{ barre d'information (sous la barre de menus) et titre de la fenetre }
Procedure DrawInfo;
Var
 S, R : String;
Begin
 Box(0, INFO_Y, SCREEN_W - 1, INFO_Y + INFO_H - 1, LightGray);
 SetColor(White);
 Line(0, INFO_Y, SCREEN_W - 1, INFO_Y);
 SetColor(DarkGray);
 Line(0, INFO_Y + INFO_H - 1, SCREEN_W - 1, INFO_Y + INFO_H - 1);
 If HasCur Then Begin
  S := Cur.Name + ', ' + Tx(S_BORN) + ' ' + DateStr(Cur.D, Cur.M, Cur.Y) +
       ' ' + Tx(S_AT) + ' ' + TimeStr(Cur.Hh, Cur.Mi);
  If Cur.City <> '' Then S := S + ', ' + Cur.City;
  TextAt(8, INFO_Y + 7, Copy(S, 1, 46), Black);
  R := DateStr(DayD, DayM, DayY) + '  ' + PlName(RI.DDom) + ' ' +
       Tx(S_FORCE) + ' ' + IStr(RI.DForce);
  TextAt(SCREEN_W - 8 - Length(R) * 8, INFO_Y + 7, R, Blue);
  SetTitle('Astromancie - ' + Cur.Name);
 End Else Begin
  TextAt(8, INFO_Y + 7, Copy(Tx(S_NOPERSON), 1, 78), DarkGray);
  SetTitle('Astromancie');
 End;
End;

{ barre d'etat d'OS/2 : zone en creux sur fond gris }
Procedure DrawStatus;
Var
 S : String;
Begin
 Box(0, STAT_Y, SCREEN_W - 1, SCREEN_H - 1, LightGray);
 Bevel(2, STAT_Y + 2, SCREEN_W - 3, SCREEN_H - 2, True);
 If StatusMsg <> '' Then S := StatusMsg Else S := Tx(S_STATUS);
 TextAt(6, STAT_Y + 6, Copy(S, 1, 78), Black);
End;

Procedure DrawStars;
Var
 I : Integer;
 X, Y, Sd : LongInt;
Begin
 Sd := 1985;
 For I := 1 To 220 Do Begin
  Sd := (Sd * 1103515245 + 12345) And $7FFFFFFF;
  X := (Sd Shr 8) Mod SCREEN_W;
  Sd := (Sd * 1103515245 + 12345) And $7FFFFFFF;
  Y := BODY_Y + (Sd Shr 8) Mod (STAT_Y - BODY_Y);
  If I Mod 7 = 0 Then PutPixel(X, Y, White)
  Else If I Mod 3 = 0 Then PutPixel(X, Y, LightGray)
  Else PutPixel(X, Y, DarkGray);
 End;
End;

{ lignes de la page ; sur fond blanc (pages de texte), les couleurs sont
  remplacees par leur version foncee ; barre de defilement d'OS/2 }
Procedure DrawLines;
Var
 I, Y, X, N, C : Integer;
 S : String;
Begin
 N := VLN - VTop;
 If N > VIS_LINES Then N := VIS_LINES;
 For I := 1 To N Do Begin
  Y := BODY_Y + 6 + (I - 1) * LINE_H;
  S := VL[VTop + I].S;
  C := VL[VTop + I].C;
  If View <> V_WELCOME Then C := DocCol(C);
  Case VL[VTop + I].Kind Of
   1 : X := (SCREEN_W - Length(S) * 8) Div 2;
   2 : Begin
        X := 12;
        Box(6, Y - 3, SCREEN_W - 22, Y + 9, Blue);
        C := White;
       End;
  Else X := 12 + VL[VTop + I].Ind * 8;
  End;
  TextAt(X, Y, S, C);
 End;
 If VLN > VIS_LINES Then
  DrawVScroll(SCREEN_W - 15, BODY_Y, SCREEN_W - 1, STAT_Y - 1, VTop, VLN,
              VIS_LINES);
End;

{ ---- carte du ciel ---- }

Procedure WheelPt(Cx, Cy : Integer; Rr : Integer; Lon, AscL : Double;
                  Var X, Y : Integer);
Var
 A : Double;
Begin
 A := (180 + Lon - AscL) * PI_D / 180;
 Rr := Rr * 19 Div 20;
 X := Cx + Round(Rr * Cos(A));
 Y := Cy - Round(Rr * Sin(A));
End;

Procedure DrawWheel;
Var
 Cx, Cy, I, J, X1, Y1, X2, Y2, R, Col, T : Integer;
 AscL, Lon : Double;
 Pos : Array[1..10] Of Double;
 S : String;
Begin
 Cx := 222;
 Cy := 237;
 AscL := NatC.Cu[1];
 SetColor(LightGray);
 Circle(Cx, Cy, 200 * 19 Div 20);
 Circle(Cx, Cy, 174 * 19 Div 20);
 Circle(Cx, Cy, 96 * 19 Div 20);
 SetColor(DarkGray);
 Circle(Cx, Cy, 30 * 19 Div 20);
 Circle(Cx, Cy, 150 * 19 Div 20);
 { signes }
 For I := 1 To 12 Do Begin
  WheelPt(Cx, Cy, 200, (I - 1) * 30, AscL, X1, Y1);
  WheelPt(Cx, Cy, 174, (I - 1) * 30, AscL, X2, Y2);
  SetColor(LightGray);
  Line(X1, Y1, X2, Y2);
  WheelPt(Cx, Cy, 187, (I - 1) * 30 + 15, AscL, X1, Y1);
  Case (I - 1) Mod 4 Of
   0 : Col := LightRed;
   1 : Col := LightGreen;
   2 : Col := Yellow;
  Else Col := LightCyan;
  End;
  S := Copy(SgName(I), 1, 3);
  TextAt(X1 - 12, Y1 - 4, S, Col);
 End;
 { maisons }
 For I := 1 To 12 Do Begin
  WheelPt(Cx, Cy, 174, NatC.Cu[I], AscL, X1, Y1);
  WheelPt(Cx, Cy, 30, NatC.Cu[I], AscL, X2, Y2);
  If (I = 1) Or (I = 10) Then SetColor(White) Else SetColor(DarkGray);
  Line(X1, Y1, X2, Y2);
  Lon := NatC.Cu[I] + 12;
  If I < 12 Then Begin
   J := I + 1;
   Lon := NatC.Cu[J] - NatC.Cu[I];
   If Lon < 0 Then Lon := Lon + 360;
   Lon := NatC.Cu[I] + Lon / 2;
  End Else Begin
   Lon := NatC.Cu[1] - NatC.Cu[12];
   If Lon < 0 Then Lon := Lon + 360;
   Lon := NatC.Cu[12] + Lon / 2;
  End;
  WheelPt(Cx, Cy, 108, Lon, AscL, X1, Y1);
  TextAt(X1 - Length(ROMAN[I]) * 4, Y1 - 4, ROMAN[I], DarkGray);
 End;
 { planetes natales (ecartement des positions trop proches) }
 For I := 1 To 10 Do Pos[I] := NatC.Pl[I];
 For T := 1 To 12 Do
  For I := 1 To 10 Do
   For J := 1 To 10 Do
    If I <> J Then Begin
     Lon := Pos[J] - Pos[I];
     If Lon > 180 Then Lon := Lon - 360;
     If Lon < -180 Then Lon := Lon + 360;
     If (Lon >= 0) And (Lon < 9) Then Begin
      Pos[I] := Pos[I] - 0.6;
      Pos[J] := Pos[J] + 0.6;
     End;
    End;
 { aspects natals }
 For I := 1 To 10 Do
  For J := I + 1 To 10 Do Begin
   T := NatC.AT[I, J];
   If T > 1 Then Begin
    Case T Of
     3, 5 : Col := LightGreen;
     4, 7 : Col := LightRed;
    Else Col := DarkGray;
    End;
    WheelPt(Cx, Cy, 94, NatC.Pl[I], AscL, X1, Y1);
    WheelPt(Cx, Cy, 94, NatC.Pl[J], AscL, X2, Y2);
    SetColor(Col);
    Line(X1, Y1, X2, Y2);
   End;
  End;
 For I := 1 To 10 Do Begin
  WheelPt(Cx, Cy, 96, NatC.Pl[I], AscL, X1, Y1);
  WheelPt(Cx, Cy, 104, NatC.Pl[I], AscL, X2, Y2);
  SetColor(PLCOL[I]);
  Line(X1, Y1, X2, Y2);
  WheelPt(Cx, Cy, 124, Pos[I], AscL, X1, Y1);
  SetFillStyle(SolidFill, PLCOL[I]);
  FillEllipse(X1, Y1, 3, 3);
  WheelPt(Cx, Cy, 140, Pos[I], AscL, X2, Y2);
  TextAt(X2 - 8, Y2 - 4, Copy(PlName(I), 1, 2), PLCOL[I]);
 End;
 { planetes du jour (anneau exterieur interieur au zodiaque) }
 If ShowTransit Then Begin
  For I := 1 To 10 Do Pos[I] := DayC.Pl[I];
  For T := 1 To 12 Do
   For I := 1 To 10 Do
    For J := 1 To 10 Do
     If I <> J Then Begin
      Lon := Pos[J] - Pos[I];
      If Lon > 180 Then Lon := Lon - 360;
      If Lon < -180 Then Lon := Lon + 360;
      If (Lon >= 0) And (Lon < 7) Then Begin
       Pos[I] := Pos[I] - 0.5;
       Pos[J] := Pos[J] + 0.5;
      End;
     End;
  For I := 1 To 10 Do Begin
   WheelPt(Cx, Cy, 174, DayC.Pl[I], AscL, X1, Y1);
   WheelPt(Cx, Cy, 166, DayC.Pl[I], AscL, X2, Y2);
   SetColor(White);
   Line(X1, Y1, X2, Y2);
   WheelPt(Cx, Cy, 159, Pos[I], AscL, X1, Y1);
   TextAt(X1 - 8, Y1 - 4, Copy(PlName(I), 1, 2), LightGray);
  End;
 End;
 { legende }
 R := 456;
 TextAt(R, BODY_Y + 10, Tx(T_WHEEL), Yellow);
 For I := 1 To 10 Do Begin
  S := PadR(PlName(I), 9) + PadR(DegStr(RI.nD[I]), 4) +
       Copy(SgName(RI.nS[I]), 1, 3);
  TextAt(R, BODY_Y + 30 + I * 12, S, PLCOL[I]);
 End;
 S := 'ASC ' + DegStr(RI.nD[11]) + ' ' + Copy(SgName(RI.nS[11]), 1, 3);
 TextAt(R, BODY_Y + 30 + 11 * 12 + 4, S, White);
 S := 'MC  ' + DegStr(RI.nD[12]) + ' ' + Copy(SgName(RI.nS[12]), 1, 3);
 TextAt(R, BODY_Y + 30 + 12 * 12 + 4, S, White);
 TextAt(R, BODY_Y + 30 + 14 * 12 + 8, ASPN[Lang, 3] + '/' +
        Copy(ASPN[Lang, 5], 1, 7), LightGreen);
 TextAt(R, BODY_Y + 30 + 15 * 12 + 8, ASPN[Lang, 4] + '/' +
        Copy(ASPN[Lang, 7], 1, 6), LightRed);
 If ShowTransit Then
  TextAt(R, BODY_Y + 30 + 17 * 12 + 8, Copy(Tx(T_DAY), 1, 22), LightGray);
End;

Procedure DrawBody;
Begin
 If (View = V_WELCOME) Or (View = V_WHEEL) Then Begin
  Box(0, BODY_Y, SCREEN_W - 1, STAT_Y - 1, Black);
  DrawStars;
 End Else Box(0, BODY_Y, SCREEN_W - 1, STAT_Y - 1, White);
 If View = V_WHEEL Then DrawWheel
 Else DrawLines;
End;

Procedure DrawOrnament(Cx, Cy : Integer);
Var
 I, X1, Y1, X2, Y2 : Integer;
 A : Double;
Begin
 SetColor(DarkGray);
 Circle(Cx, Cy, 46);
 Circle(Cx, Cy, 32);
 Circle(Cx, Cy, 8);
 For I := 0 To 11 Do Begin
  A := I * PI_D / 6;
  X1 := Cx + Round(32 * Cos(A)); Y1 := Cy - Round(32 * Sin(A));
  X2 := Cx + Round(46 * Cos(A)); Y2 := Cy - Round(46 * Sin(A));
  Line(X1, Y1, X2, Y2);
  X1 := Cx + Round(12 * Cos(A)); Y1 := Cy - Round(12 * Sin(A));
  X2 := Cx + Round(30 * Cos(A + PI_D / 12));
  Y2 := Cy - Round(30 * Sin(A + PI_D / 12));
  SetColor(Blue);
  Line(X1, Y1, X2, Y2);
  SetColor(DarkGray);
 End;
 SetFillStyle(SolidFill, Yellow);
 FillEllipse(Cx, Cy, 4, 4);
End;

Procedure DrawWelcome;
Var
 Y : Integer;
Begin
 SetTextStyle(DefaultFont, HorizDir, 4);
 SetColor(Yellow);
 OutTextXY((SCREEN_W - 11 * 32) Div 2, BODY_Y + 36, 'Astromancie');
 SetTextStyle(DefaultFont, HorizDir, 1);
 Y := BODY_Y + 84;
 SetColor(LightCyan);
 OutTextXY((SCREEN_W - Length(Tx(A_SUB)) * 8) Div 2, Y, Tx(A_SUB));
 DrawOrnament(SCREEN_W Div 2, BODY_Y + 330);
End;

Procedure RedrawAll;
Begin
 DrawMenuBar;
 DrawInfo;
 DrawBody;
 If View = V_WELCOME Then DrawWelcome;
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
 TWrapArr = Array[0..5] Of String[70];

Procedure WrapInto(S : String; W : Integer; Var L : TWrapArr;
                   Var N : Integer);
Var
 I : Integer;
 Wd, Cur : String;
Begin
 N := 0;
 Cur := '';
 Wd := '';
 S := S + ' ';
 For I := 1 To Length(S) Do
  If S[I] = ' ' Then Begin
   If Wd <> '' Then Begin
    If Cur = '' Then Cur := Wd
    Else If Length(Cur) + 1 + Length(Wd) <= W Then Cur := Cur + ' ' + Wd
    Else Begin
     If N <= 5 Then L[N] := Cur;
     Inc(N);
     Cur := Wd;
    End;
   End;
   Wd := '';
  End Else Wd := Wd + S[I];
 If Cur <> '' Then Begin
  If N <= 5 Then L[N] := Cur;
  Inc(N);
 End;
 If N > 6 Then N := 6;
End;

{ Message ; si YesNo, renvoie True pour Oui }
{ Message ; si YesNo, renvoie True pour Oui (boites de message d'OS/2) }
Function AskBox(Msg : String; YesNo : Boolean) : Boolean;
Begin
 If YesNo Then
  AskBox := PmBox('Astromancie', Msg, MB_YESNO Or MB_ICONQUESTION) = MBID_YES
 Else Begin
  Dummy := PmBox('Astromancie', Msg, MB_OK Or MB_INFORMATION);
  AskBox := False;
 End;
End;

Procedure MsgBox(Msg : String);
Begin
 If AskBox(Msg, False) Then ;
End;

Const
 NFLD = 9;

Type
 TFields = Record
  N : Integer;
  Lab : Array[1..NFLD] Of String[30];
  Val : Array[1..NFLD] Of String[30];
  Max : Array[1..NFLD] Of Integer;
 End;

{ zones de saisie d'OS/2 : fond blanc en creux, curseur au bout du texte }
Procedure DrawFields(Var F : TFields; X1, Y1 : Integer; Foc : Integer);
Var
 I, Y, X2 : Integer;
Begin
 For I := 1 To F.N Do Begin
  Y := Y1 + (I - 1) * 22;
  X2 := X1 + 168 + F.Max[I] * 8 + 8;
  TextAt(X1, Y + 4, F.Lab[I], Black);
  Box(X1 + 168, Y, X2, Y + 15, White);
  Bevel(X1 + 167, Y - 1, X2 + 1, Y + 16, True);
  SetColor(Black);
  Line(X1 + 168, Y, X2, Y);
  Line(X1 + 168, Y, X1 + 168, Y + 15);
  TextAt(X1 + 172, Y + 4, F.Val[I], Black);
  If I = Foc Then Begin
   SetColor(Black);
   Line(X1 + 172 + Length(F.Val[I]) * 8, Y + 2,
        X1 + 172 + Length(F.Val[I]) * 8, Y + 13);
   Frame(X1 + 165, Y - 3, X2 + 3, Y + 18, Blue);
  End;
 End;
End;

{ Saisie dans un champ ; renvoie True si la touche a ete consommee }
Function FieldKey(Var F : TFields; Foc : Integer; K : Word) : Boolean;
Begin
 FieldKey := True;
 If K = 8 Then Begin
  If Length(F.Val[Foc]) > 0 Then Delete(F.Val[Foc], Length(F.Val[Foc]), 1);
 End Else If K = 256 + 83 Then F.Val[Foc] := ''
 Else If (K >= 32) And (K < 256) And (K <> 127) Then Begin
  If Length(F.Val[Foc]) < F.Max[Foc] Then F.Val[Foc] := F.Val[Foc] + Chr(K);
 End Else FieldKey := False;
End;

Function ParseNum(S : String; Var P : Integer; Var V : Real) : Boolean;
Var
 T : String;
 E : Integer;
Begin
 T := '';
 While (P <= Length(S)) And (S[P] = ' ') Do Inc(P);
 If (P <= Length(S)) And ((S[P] = '-') Or (S[P] = '+')) Then Begin
  T := S[P]; Inc(P);
 End;
 While (P <= Length(S)) And (S[P] In ['0'..'9', '.', ',']) Do Begin
  If S[P] = ',' Then T := T + '.' Else T := T + S[P];
  Inc(P);
 End;
 Val(T, V, E);
 ParseNum := (E = 0) And (T <> '') And (T <> '-') And (T <> '+');
End;

Function ParseDate(S : String; Var D, M, Y : Integer) : Boolean;
Var
 P : Integer;
 A, B, C : Real;
Begin
 ParseDate := False;
 P := 1;
 If Not ParseNum(S, P, A) Then Exit;
 Inc(P);
 If Not ParseNum(S, P, B) Then Exit;
 Inc(P);
 If Not ParseNum(S, P, C) Then Exit;
 D := Trunc(A); M := Trunc(B); Y := Trunc(C);
 If Y < 100 Then Y := Y + 1900;
 If (M < 1) Or (M > 12) Or (Y < 1800) Or (Y > 2199) Then Exit;
 If (D < 1) Or (D > DaysInMonth(M, Y)) Then Exit;
 ParseDate := True;
End;

Function ParseTime(S : String; Var H, M : Integer) : Boolean;
Var
 P : Integer;
 A, B : Real;
Begin
 ParseTime := False;
 P := 1;
 If Not ParseNum(S, P, A) Then Exit;
 B := 0;
 If P <= Length(S) Then Begin
  Inc(P);
  If Not ParseNum(S, P, B) Then B := 0;
 End;
 H := Trunc(A); M := Trunc(B);
 If (H < 0) Or (H > 23) Or (M < 0) Or (M > 59) Then Exit;
 ParseTime := True;
End;

{ Coordonnee "48N50", "2E20", "71W13", "-3 06"... }
Function ParseCoord(S : String; Pos, Neg : Char; MaxD : Integer;
                    Var Dg, Mn : Integer; Var IsNeg : Boolean) : Boolean;
Var
 P, I : Integer;
 A, B : Real;
 T : String;
Begin
 ParseCoord := False;
 T := UpStr(S);
 IsNeg := False;
 For I := 1 To Length(T) Do Begin
  If T[I] = Neg Then Begin IsNeg := True; T[I] := ' '; End
  Else If (T[I] = Pos) Or (T[I] = #248) Or (T[I] = '''') Or (T[I] = ':')
   Then T[I] := ' ';
 End;
 P := 1;
 If Not ParseNum(T, P, A) Then Exit;
 If A < 0 Then Begin IsNeg := True; A := -A; End;
 B := 0;
 If Not ParseNum(T, P, B) Then B := 0;
 If Frac(A) <> 0 Then Begin
  B := Round(Frac(A) * 100);
  A := Int(A);
 End;
 Dg := Trunc(A); Mn := Trunc(B);
 If (Dg > MaxD) Or (Mn > 59) Then Exit;
 ParseCoord := True;
End;

Function CoordStr(Dg, Mn : Integer; Ng : Boolean; Pos, Neg : Char) : String;
Begin
 If Ng Then CoordStr := IStr(Dg) + Neg + Pad2(Mn)
 Else CoordStr := IStr(Dg) + Pos + Pad2(Mn);
End;

Function OfsField(X : Real) : String;
Var
 S : String;
Begin
 Str(X : 0 : 1, S);
 If Copy(S, Length(S) - 1, 2) = '.0' Then S := Copy(S, 1, Length(S) - 2);
 OfsField := S;
End;

{ Cherche la ville et calcule le decalage ; renvoie le message }
Function LookupPlace(Var F : TFields) : String;
Var
 Lon, Lat, Z, D, M, Y : Integer;
 Nm, Ctry, Key, Msg : String;
 Ofs : Real;
Begin
 Ctry := UpStr(Trim(F.Val[4]));
 F.Val[4] := Ctry;
 If Not CountryKnown(Ctry) Then Begin
  LookupPlace := Tx(D_CTRYNO);
  Exit;
 End;
 Nm := FindCity(Ctry, F.Val[6], Lon, Lat);
 If Nm <> '' Then Begin
  F.Val[6] := Nm;
  F.Val[7] := CoordStr(Abs(Lat) Div 100, Abs(Lat) Mod 100, Lat < 0, 'N', 'S');
  F.Val[8] := CoordStr(Abs(Lon) Div 100, Abs(Lon) Mod 100, Lon < 0, 'E', 'W');
  Msg := Tx(D_CITYOK) + ' ' + Nm + '. ';
 End Else Begin
  Msg := Tx(D_CITYNO) + ' ';
  Lon := 0; Lat := 0;
  If Trim(F.Val[7]) = '' Then Begin
   LookupPlace := Msg;
   Exit;
  End;
 End;
 Key := Ctry;
 If Trim(F.Val[5]) <> '' Then Key := UpStr(Trim(F.Val[5]));
 If (Key = 'DC') Or (Key = 'D.C.') Then Key := 'DC ';
 If (Key = 'NY') Or (Key = 'N.Y.') Then Key := 'NEW';
 If (Ctry = 'RSM') Or (Ctry = 'V') Then Key := 'I';
 If Ctry = 'MC' Then Key := 'F';
 If (Ctry = 'GBJ') Or (Ctry = 'GBG') Then Key := 'GB';
 Z := FindZone(Copy(Key, 1, 3), Lon, Lat);
 If (Z = 0) And (Key <> Ctry) Then Z := FindZone(Ctry, Lon, Lat);
 If (Z > 0) And ParseDate(F.Val[2], D, M, Y) Then Begin
  Ofs := ZoneOffset(Z, D, M, Y);
  F.Val[9] := OfsField(Ofs);
  Msg := Msg + Tx(D_OFFOK) + ' ' + OfsStr(Ofs) + '. ';
  If (Ctry = 'USA') Or (Ctry = 'CDN') Then Msg := Msg + Tx(D_WARNUSA);
  If (Ctry = 'F') And (LongInt(Y) * 10000 + M * 100 + D > 19400600) And
     (LongInt(Y) * 10000 + M * 100 + D < 19421102) Then
   Msg := Msg + Tx(D_WARNFR);
 End;
 LookupPlace := Msg;
End;

{ Fiche de saisie d'une personne }
Function PersonDialog(Var P : TPerson) : Boolean;
Var
 F : TFields;
 Foc, X1, Y1, X2, Y2, Fy, I, BtnY, N : Integer;
 K : Word;
 Clk, Done, Ok : Boolean;
 Msg : String;
 L : TWrapArr;
 R, R2 : Real;
 D, M, Y, H, Mi, Dg, Mn, Dg2, Mn2 : Integer;
 Ng, Ng2 : Boolean;
Begin
 F.N := 9;
 F.Lab[1] := Tx(D_NAME); F.Max[1] := 20; F.Val[1] := P.Name;
 F.Lab[2] := Tx(D_BDATE); F.Max[2] := 10;
 F.Lab[3] := Tx(D_BTIME); F.Max[3] := 5;
 F.Lab[4] := Tx(D_COUNTRY); F.Max[4] := 3; F.Val[4] := P.Ctry;
 F.Lab[5] := Tx(D_STATE); F.Max[5] := 3; F.Val[5] := P.State;
 F.Lab[6] := Tx(D_CITY); F.Max[6] := 24; F.Val[6] := P.City;
 F.Lab[7] := Tx(D_LAT); F.Max[7] := 7;
 F.Lab[8] := Tx(D_LON); F.Max[8] := 7;
 F.Lab[9] := Tx(D_OFFSET); F.Max[9] := 5;
 If P.Y > 0 Then Begin
  F.Val[2] := DateStr(P.D, P.M, P.Y);
  F.Val[3] := Pad2(P.Hh) + ':' + Pad2(P.Mi);
  F.Val[7] := CoordStr(P.LatD, P.LatM, P.South, 'N', 'S');
  F.Val[8] := CoordStr(P.LonD, P.LonM, P.West, 'E', 'W');
  F.Val[9] := OfsField(P.Ofs);
 End Else Begin
  F.Val[2] := ''; F.Val[3] := '12:00'; F.Val[7] := ''; F.Val[8] := '';
  F.Val[9] := '0';
  If F.Val[4] = '' Then F.Val[4] := 'F';
 End;
 X1 := 70; X2 := SCREEN_W - 70;
 Y1 := 64; Y2 := 404;
 Fy := Y1 + 30;
 BtnY := Y2 - 32;
 Foc := 1;
 Msg := Tx(D_HINTDLG);
 PersonDialog := False;
 Done := False;
 Repeat
  MouseOff;
  DlgFrame(X1, Y1, X2, Y2, Tx(D_PERSON));
  DrawFields(F, X1 + 16, Fy, Foc);
  WrapInto(Msg, 60, L, N);
  For I := 0 To N - 1 Do TextAt(X1 + 16, Fy + 9 * 22 + 4 + I * 11, L[I],
                                 Blue);
  Button3D(X1 + 24, BtnY, X1 + 144, BtnY + 20, Tx(D_SEARCH), False);
  Button3D(X1 + 190, BtnY, X1 + 310, BtnY + 20, Tx(D_OK), False);
  Button3D(X2 - 144, BtnY, X2 - 24, BtnY + 20, Tx(D_CANCEL), False);
  MouseOn;
  Clk := WaitClickOrKey(K);
  Ok := False;
  If Clk Then Begin
   For I := 1 To F.N Do
    If InRect(MsX, MsY, X1 + 16, Fy + (I - 1) * 22, X2 - 16,
              Fy + (I - 1) * 22 + 15) Then Foc := I;
   If InRect(MsX, MsY, X1 + 24, BtnY, X1 + 144, BtnY + 20) Then
    Msg := LookupPlace(F);
   If InRect(MsX, MsY, X1 + 190, BtnY, X1 + 310, BtnY + 20) Then Ok := True;
   If InRect(MsX, MsY, X2 - 144, BtnY, X2 - 24, BtnY + 20) Then Done := True;
  End Else Begin
   Case K Of
    27 : Done := True;
    9, 256 + 80 : Begin
                   If (Foc = 6) Or (Foc = 4) Then Msg := LookupPlace(F);
                   Inc(Foc); If Foc > F.N Then Foc := 1;
                  End;
    256 + 15, 256 + 72 : Begin Dec(Foc); If Foc < 1 Then Foc := F.N; End;
    13 : If Foc = F.N Then Ok := True
         Else Begin
          If (Foc = 6) Or (Foc = 4) Or (Foc = 5) Then Msg := LookupPlace(F);
          Inc(Foc);
         End;
    256 + 60 : Msg := LookupPlace(F);
   Else
    If FieldKey(F, Foc, K) Then ;
   End;
  End;
  If Ok Then Begin
   If Trim(F.Val[1]) = '' Then Begin Msg := Tx(D_BADNAME); Foc := 1; End
   Else If Not ParseDate(F.Val[2], D, M, Y) Then Begin
    Msg := Tx(D_BADDATE); Foc := 2;
   End Else If Not ParseTime(F.Val[3], H, Mi) Then Begin
    Msg := Tx(D_BADTIME); Foc := 3;
   End Else Begin
    If (Trim(F.Val[7]) = '') Or (Trim(F.Val[8]) = '') Then
     Msg := LookupPlace(F);
    If Not ParseCoord(F.Val[7], 'N', 'S', 89, Dg, Mn, Ng) Then Begin
     Msg := Tx(D_BADCOORD); Foc := 7;
    End Else If Not ParseCoord(F.Val[8], 'E', 'W', 180, Dg2, Mn2, Ng2) Then
    Begin
     Msg := Tx(D_BADCOORD); Foc := 8;
    End Else Begin
     I := 1;
     If Not ParseNum(F.Val[9], I, R) Then R := 99;
     If (I <= Length(F.Val[9])) And (F.Val[9][I] = ':') Then Begin
      Inc(I);
      If ParseNum(F.Val[9], I, R2) Then
       If (R < 0) Or (Copy(Trim(F.Val[9]), 1, 1) = '-') Then
        R := R - R2 / 60 Else R := R + R2 / 60;
     End;
     If Abs(R) > 13 Then Begin Msg := Tx(D_BADOFF); Foc := 9; End
     Else Begin
      P.Name := Trim(F.Val[1]);
      P.D := D; P.M := M; P.Y := Y; P.Hh := H; P.Mi := Mi;
      P.Ctry := UpStr(Trim(F.Val[4]));
      P.State := UpStr(Trim(F.Val[5]));
      P.City := Trim(F.Val[6]);
      P.LatD := Dg; P.LatM := Mn; P.South := Ng;
      P.LonD := Dg2; P.LonM := Mn2; P.West := Ng2;
      P.Ofs := R;
      PersonDialog := True;
      Done := True;
     End;
    End;
   End;
  End;
 Until Done;
End;

{ Saisie d'une date seule }
Function DateDialog(Var D, M, Y : Integer) : Boolean;
Var
 F : TFields;
 K : Word;
 Clk, Done, Ok : Boolean;
 X1, Y1, X2, Y2, A, B, C : Integer;
 Msg : String;
Begin
 F.N := 1;
 F.Lab[1] := Tx(D_BDATE); F.Max[1] := 10; F.Val[1] := DateStr(D, M, Y);
 X1 := 120; X2 := SCREEN_W - 120; Y1 := 170; Y2 := 290;
 Msg := '';
 DateDialog := False;
 Done := False;
 Repeat
  MouseOff;
  DlgFrame(X1, Y1, X2, Y2, Tx(D_DATE));
  DrawFields(F, X1 + 20, Y1 + 34, 1);
  TextAt(X1 + 20, Y1 + 62, Msg, Red);
  Button3D(X1 + 60, Y2 - 32, X1 + 160, Y2 - 12, Tx(D_OK), True);
  Button3D(X2 - 160, Y2 - 32, X2 - 60, Y2 - 12, Tx(D_CANCEL), False);
  MouseOn;
  Clk := WaitClickOrKey(K);
  Ok := False;
  If Clk Then Begin
   If InRect(MsX, MsY, X1 + 60, Y2 - 32, X1 + 160, Y2 - 12) Then Ok := True;
   If InRect(MsX, MsY, X2 - 160, Y2 - 32, X2 - 60, Y2 - 12) Then Done := True;
  End Else If K = 27 Then Done := True
  Else If K = 13 Then Ok := True
  Else If FieldKey(F, 1, K) Then ;
  If Ok Then
   If ParseDate(F.Val[1], A, B, C) Then Begin
    D := A; M := B; Y := C;
    DateDialog := True;
    Done := True;
   End Else Msg := Tx(D_BADDATE);
 Until Done;
End;

Var
 LItem : Array[1..MAXCAL] Of String[60];

{ Liste a choix ; renvoie 0 (annule), 1 (choisi) ou 2 (supprimer) }
Function ListDialog(Title : String; N : Integer; Var Sel : Integer;
                    AllowDel : Boolean) : Integer;
Var
 X1, Y1, X2, Y2, Top, I, Y, Vis : Integer;
 K : Word;
 Clk, Done : Boolean;
Begin
 ListDialog := 0;
 X1 := 110; X2 := SCREEN_W - 110; Y1 := 70; Y2 := 420;
 Vis := 20;
 If Sel < 1 Then Sel := 1;
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
     TextAt(X1 + 16, Y + 2, LItem[I], White);
    End Else TextAt(X1 + 16, Y + 2, LItem[I], Black);
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
{ Calepin                                                            }
{ ================================================================== }

Function PersonLine(Var P : TPerson) : String;
Begin
 PersonLine := P.Name + ';' + IStr(P.D) + ';' + IStr(P.M) + ';' + IStr(P.Y) +
  ';' + IStr(P.Hh) + ';' + IStr(P.Mi) + ';' + P.Ctry + ';' + P.State + ';' +
  P.City + ';' + IStr(P.LatD) + ';' + IStr(P.LatM) + ';' + IStr(Ord(P.South))
  + ';' + IStr(P.LonD) + ';' + IStr(P.LonM) + ';' + IStr(Ord(P.West)) + ';' +
  OfsField(P.Ofs);
End;

Function SemiField(S : String; N : Integer) : String;
Var
 I, K : Integer;
 R : String;
Begin
 K := 1;
 R := '';
 For I := 1 To Length(S) Do
  If S[I] = ';' Then Inc(K)
  Else If K = N Then R := R + S[I];
 SemiField := R;
End;

Procedure LoadCal;
Var
 F : Text;
 S : String;
 P : TPerson;
 R : Real;
 E : Integer;
Begin
 CalN := 0;
 Assign(F, CALFILE);
 {$I-}
 Reset(F);
 {$I+}
 If IOResult <> 0 Then Exit;
 While Not Eof(F) And (CalN < MAXCAL) Do Begin
  ReadLn(F, S);
  If SemiField(S, 1) = '' Then Continue;
  P.Name := SemiField(S, 1);
  P.D := ValI(SemiField(S, 2)); P.M := ValI(SemiField(S, 3));
  P.Y := ValI(SemiField(S, 4)); P.Hh := ValI(SemiField(S, 5));
  P.Mi := ValI(SemiField(S, 6)); P.Ctry := SemiField(S, 7);
  P.State := SemiField(S, 8); P.City := SemiField(S, 9);
  P.LatD := ValI(SemiField(S, 10)); P.LatM := ValI(SemiField(S, 11));
  P.South := SemiField(S, 12) = '1';
  P.LonD := ValI(SemiField(S, 13)); P.LonM := ValI(SemiField(S, 14));
  P.West := SemiField(S, 15) = '1';
  Val(SemiField(S, 16), R, E);
  If E <> 0 Then R := 0;
  P.Ofs := R;
  If (P.Y > 0) And (P.M >= 1) And (P.M <= 12) Then Begin
   Inc(CalN);
   Cal[CalN] := P;
  End;
 End;
 Close(F);
End;

Function SaveCal : Boolean;
Var
 F : Text;
 I : Integer;
Begin
 Assign(F, CALFILE);
 {$I-}
 Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Begin SaveCal := False; Exit; End;
 For I := 1 To CalN Do WriteLn(F, PersonLine(Cal[I]));
 Close(F);
 SaveCal := True;
End;

Procedure AddToCal(Var P : TPerson);
Var
 I : Integer;
Begin
 For I := 1 To CalN Do
  If UpStr(Cal[I].Name) = UpStr(P.Name) Then Begin
   Cal[I] := P;
   If Not SaveCal Then MsgBox(Tx(D_IOERR)) Else StatusMsg := Tx(D_SAVED);
   Exit;
  End;
 If CalN < MAXCAL Then Begin
  Inc(CalN);
  Cal[CalN] := P;
 End;
 If Not SaveCal Then MsgBox(Tx(D_IOERR)) Else StatusMsg := Tx(D_SAVED);
End;

Procedure CalItems;
Var
 I : Integer;
Begin
 For I := 1 To CalN Do
  LItem[I] := PadR(Cal[I].Name, 21) + DateStr(Cal[I].D, Cal[I].M, Cal[I].Y) +
   ' ' + TimeStr(Cal[I].Hh, Cal[I].Mi) + ' ' + Copy(Cal[I].City, 1, 14);
End;

{ ================================================================== }
{ Calculs pour la personne courante                                  }
{ ================================================================== }

Procedure ChartOf(Var P : TPerson; Var C : TChart);
Begin
 CalcChart(P.D, P.M, P.Y, P.Hh, P.Mi, P.Ofs, P.LonD, P.LonM, P.West,
           P.LatD, P.LatM, P.South, C);
End;

Procedure Recompute;
Begin
 If Not HasCur Then Exit;
 ChartOf(Cur, NatC);
 CalcDay(DayD, DayM, DayY, DayC);
 Interpret(NatC, DayC, RI);
 CalcPrev(NatC, DayC, RI);
End;

{ ================================================================== }
{ Construction des vues                                              }
{ ================================================================== }

Function NatRow(I : Integer) : String;
Begin
 NatRow := PadR(PlName(I), 10) + PadR(DegStr(RI.nD[I]), 5) +
           PadR(SgName(RI.nS[I]), 12) + PadR(ROMAN[RI.nHouse[I]], 7) +
           MotW(I) + ' : ' + KeyNat(I);
End;

Function HouseRow(F : Integer) : String;
Begin
 HouseRow := PadR(Tx(T_HOUSE) + ' ' + ROMAN[F], 12) +
             PadR(DegStr(RI.hD[F]), 5) + PadR(SgName(RI.hS[F]), 12) +
             KeyHouse(F);
End;

Function DayRow(I : Integer) : String;
Begin
 DayRow := PadR(PlName(I), 10) + PadR(DegStr(RI.dD[I]), 5) +
           PadR(SgName(RI.dS[I]), 12) +
           PadR(Tx(H_MASTER) + ' ' + ROMAN[RI.Master[I]],
                Length(Tx(H_MASTER)) + 6) +
           MotW(12 + RI.Master[I]) + ' / ' + KeyDay(I);
End;

Function DomLine : String;
Begin
 DomLine := Tx(S_DOMIS) + ' : ' + PlName(RI.Dom) + ' >>> ' +
            MotW(RI.Dom + 156) + ' >>> ' + Tx(S_POWER) + ' ' + IStr(RI.Puis);
End;

Function AscLine : String;
Begin
 AscLine := Tx(S_ASCIS) + ' : ' + SgName(RI.Asc) + ' >>> ' +
            MotW(144 + RI.Asc);
End;

Function DDomLine : String;
Begin
 DDomLine := Tx(T_DDOM) + ' : ' + PlName(RI.DDom) + ', ' + Tx(S_FORCE) + ' ' +
             IStr(RI.DForce);
End;

Procedure VTableHead(A, B, C, D, E : String);
Begin
 VAdd(PadR(A, 10) + PadR(B, 5) + PadR(C, 12) + PadR(D, 7) + E, LightGray,
      0, 0, 0);
 VAdd(Copy('------------------------------------------------------------'+
      '------------------', 1, 76), DarkGray, 0, 0, 0);
End;

Procedure BuildNatal;
Var
 I : Integer;
Begin
 VTitle(Tx(T_NATAL) + '  -  ' + Cur.Name);
 VTableHead(Tx(H_PLANET), '', Tx(H_SIGN), Tx(H_HOUSE), Tx(H_KEY));
 For I := 1 To 10 Do VAdd(NatRow(I), PLCOL[I], 0, 0, 100 + I);
 VBlank;
 VAdd(DomLine, Yellow, 0, 0, 120);
 VAdd(AscLine, LightCyan, 0, 0, 121);
 VBlank;
 VAdd(PadR('ASC', 10) + PadR(DegStr(RI.nD[11]), 5) + SgName(RI.nS[11]),
      LightGray, 0, 0, 0);
 VAdd(PadR('MC', 10) + PadR(DegStr(RI.nD[12]), 5) + SgName(RI.nS[12]),
      LightGray, 0, 0, 0);
End;

Procedure BuildHouses;
Var
 F : Integer;
Begin
 VTitle(Tx(T_HOUSES) + '  -  ' + Cur.Name);
 For F := 1 To 12 Do VAdd(HouseRow(F), LightGray + 8 * Ord(F Mod 3 = 1),
                          0, 0, 200 + F);
End;

Procedure BuildPlanet(P : Integer);
Var
 P1, P2 : Integer;
Begin
 VTitle(Tx(T_NATAL) + '  -  ' + PlName(P) + ' (' + Tx(S_FORCE) + ' ' +
        IStr(RI.Fn[P]) + ')');
 VAdd(NatRow(P), PLCOL[P], 0, 0, 0);
 VBlank;
 VSect(Tx(S_GENERAL) + ' :');
 VBlock(NatBlk(144 * (P - 1) + 12 * (RI.nS[P] - 1) + 1), LightGray, 3);
 VBlank;
 VSect(Tx(S_PARTIC) + ' :');
 NatParts(RI.nS[P], RI.nD[P], P1, P2);
 VBlock(NatBlk(P1), LightGray, 3);
 If P2 <> 0 Then VBlock(NatBlk(P2), LightGray, 3);
 VBlank;
 VAdd(Tx(S_TEXTFR), DarkGray, 0, 0, 0);
End;

Procedure BuildHouse(F : Integer);
Var
 P1, P2 : Integer;
Begin
 VTitle(Tx(T_HOUSES) + '  -  ' + Tx(T_HOUSE) + ' ' + ROMAN[F]);
 VAdd(HouseRow(F), White, 0, 0, 0);
 VBlank;
 VSect(Tx(S_GENERAL) + ' :');
 VBlock(B_DOM + (36 * (F - 1) + 3 * (RI.hS[F] - 1)) Div 3 + 1, LightGray, 3);
 VBlank;
 VSect(Tx(S_PARTIC) + ' :');
 NatParts(RI.hS[F], RI.hD[F], P1, P2);
 VBlock(NatBlk(P1), LightGray, 3);
 VBlank;
 VAdd(Tx(S_TEXTFR), DarkGray, 0, 0, 0);
End;

Procedure BuildDomin;
Var
 Ps, Ng : Integer;
Begin
 VTitle(Tx(T_DOMIN) + '  -  ' + Cur.Name);
 VAdd(DomLine, Yellow, 0, 0, 0);
 VBlank;
 DomSigns(RI.Dom, RI.Asc, Ps, Ng);
 VSect(Tx(S_POSITIF) + ' :');
 VBlock(NatBlk(144 * (RI.Dom - 1) + 12 * (Ps - 1) + 1), LightGreen, 3);
 VBlank;
 VSect(Tx(S_NEGATIF) + ' :');
 VBlock(NatBlk(144 * (RI.Dom - 1) + 12 * (Ng - 1) + 1), LightRed, 3);
 VBlank;
 VAdd(Tx(S_TEXTFR), DarkGray, 0, 0, 0);
End;

Procedure BuildAsc;
Begin
 VTitle(Tx(T_ASCEND) + '  -  ' + Cur.Name);
 VAdd(AscLine, LightCyan, 0, 0, 0);
 VBlank;
 VBlock(481 + RI.Asc - 1, LightGray, 3);
 VBlank;
 VAdd(Tx(S_TEXTFR), DarkGray, 0, 0, 0);
End;

Procedure BuildDay;
Var
 I : Integer;
Begin
 VTitle(Tx(T_DAY) + '  -  ' + LongDate(DayD, DayM, DayY));
 VAdd(PadR(Tx(H_PLANET), 10) + PadR('', 5) + PadR(Tx(H_SIGN), 12) +
      PadR(Tx(H_HOUSE), Length(Tx(H_MASTER)) + 6) + Tx(H_KEY), LightGray,
      0, 0, 0);
 VAdd(Copy('------------------------------------------------------------'+
      '------------------', 1, 76), DarkGray, 0, 0, 0);
 For I := 1 To 10 Do VAdd(DayRow(I), PLCOL[I], 0, 0, 300 + I);
 VBlank;
 VAdd(DDomLine, Yellow, 0, 0, 320);
End;

Procedure BuildDayPl(P : Integer);
Var
 Mh : Integer;
Begin
 VTitle(Tx(T_PREV) + '  -  ' + PlName(P) + ' (' + Tx(S_FORCE) + ' ' +
        IStr(RI.Fd[P]) + ')');
 VAdd(DayRow(P), PLCOL[P], 0, 0, 0);
 VBlank;
 Mh := RI.Master[P];
 VSect(Tx(S_GENERAL) + ' :');
 VBlock(B_MAS + (36 * (Mh - 1) + 3 * (RI.dS[P] - 1)) Div 3 + 1, LightGray, 3);
 VBlank;
 VSect(Tx(S_PERSON) + ' :');
 VBlock(B_MAM + (36 * (Mh - 1) + 3 * (RI.tHouse[P] - 1)) Div 3 + 1,
        LightGray, 3);
 VBlank;
 VAdd(Tx(S_TEXTFR), DarkGray, 0, 0, 0);
End;

Procedure BuildDDom;
Begin
 VTitle(Tx(T_DDOM) + '  -  ' + LongDate(DayD, DayM, DayY));
 VAdd(DDomLine, Yellow, 0, 0, 0);
 VBlank;
 VBlock(493 + RI.DDom - 1, LightGray, 3);
 VBlank;
 VAdd(Tx(S_TEXTFR), DarkGray, 0, 0, 0);
End;

Procedure BuildPrev;
Var
 I : Integer;
 S, Mk : String;
Begin
 VTitle(Tx(T_PREV) + '  -  ' + LongDate(DayD, DayM, DayY));
 VAdd(DDomLine, Yellow, 0, 0, 0);
 VBlank;
 If PrevN = 0 Then VText(Tx(S_NOASP), LightGray, 1);
 For I := 1 To PrevN Do Begin
  Mk := '';
  If PrevL[I].DType = PrevL[I].NType Then Mk := '*';
  If (PrevL[I].A = RI.DDom) Or (PrevL[I].B = RI.DDom) Or
     (PrevL[I].A = RI.Dom) Or (PrevL[I].B = RI.Dom) Then Mk := Mk + '**';
  S := PlName(PrevL[I].A) + ' / ' + PlName(PrevL[I].B) + '  -  ' +
       ASPN[Lang, PrevL[I].DType];
  If Mk <> '' Then S := S + '  ' + Mk;
  VAdd(S, LightCyan, 0, 1, 0);
  VBlock(B_ASP + PrevL[I].Idx + 1, LightGray, 3);
  VBlank;
 End;
 VAdd(Tx(S_SAMEASP), DarkGray, 0, 0, 0);
 VAdd(Tx(S_TEXTFR), DarkGray, 0, 0, 0);
End;

Procedure BuildTarot;
Var
 Sg, Dc : Integer;
 S : String;
Begin
 VTitle(Tx(T_TAROT) + '  -  ' + LongDate(DayD, DayM, DayY));
 Sg := RI.dS[RI.DDom];
 Dc := RI.dD[RI.DDom] Div 10 + 1;
 Case Lang Of
  0 : If Dc = 1 Then S := '1er' Else S := IStr(Dc) + 'e';
  1 : Case Dc Of 1 : S := '1st'; 2 : S := '2nd'; Else S := '3rd'; End;
  2 : S := IStr(Dc) + '.';
  3 : S := IStr(Dc) + #167;
 Else S := IStr(Dc) + #248;
 End;
 S := Tx(S_CARDOF) + ' : ' + SgName(Sg) + ', ' + S + ' ' + Tx(S_DECAN) +
      '  (' + PlName(RI.DDom) + ', ' + Tx(S_FORCE) + ' ' + IStr(RI.DForce) +
      ')';
 VAdd(S, Yellow, 1, 0, 0);
 VBlank;
 VBlock(B_SYM + (Sg - 1) * 3 + Dc, White, 0);
 VBlank;
 VAdd(Tx(S_TEXTFR), DarkGray, 1, 0, 0);
End;

Procedure BuildComp;
Var
 S : String;
Begin
 VTitle(Tx(T_COMP) + '  -  ' + Cur.Name + ' / ' + CompP.Name);
 VSect(Tx(S_CARACT) + ' :');
 VBlock(NatBlk(CompR.Car), LightGray, 3);
 VBlank;
 S := Tx(S_POTENT) + ' >>> ' + PlName(CompR.Dom) + ' ' + Tx(S_FORCE) + ' ' +
      IStr(CompR.F[CompR.Dom]);
 VAdd(S, Yellow, 0, 1, 0);
 VSect(Tx(S_POSIT) + ' :');
 VBlock(NatBlk(CompR.Pos), LightGreen, 3);
 VSect(Tx(S_NEGAT) + ' :');
 VBlock(NatBlk(CompR.Neg), LightRed, 3);
 VBlank;
 VAdd(Tx(S_VITAL) + ' >>> ' + Tx(S_FORCE) + ' ' + IStr(CompR.Vit), Yellow,
      0, 1, 0);
 VBlock(NatBlk(CompR.Sun), LightGray, 3);
 If CompR.Mars <> 0 Then VBlock(NatBlk(CompR.Mars), LightGray, 3);
 VBlank;
 VAdd(Tx(S_SENTIM) + ' >>> ' + Tx(S_FORCE) + ' ' + IStr(CompR.Sen), Yellow,
      0, 1, 0);
 VBlock(NatBlk(CompR.Moon), LightGray, 3);
 If CompR.Ven <> 0 Then VBlock(NatBlk(CompR.Ven), LightGray, 3);
 VBlank;
 VAdd(Tx(S_TEXTFR), DarkGray, 0, 0, 0);
End;

Procedure BuildGuide;
Var
 I : Integer;
Begin
 VTitle(Tx(T_GUIDE));
 For I := G_1 To NMSG Do Begin
  VText(Tx(I), LightGray, 1);
  If (I = G_2) Then Else VBlank;
 End;
 VAdd(Tx(S_STATUS), LightCyan, 0, 1, 0);
 VAdd(Tx(S_SCROLL), LightCyan, 0, 1, 0);
End;

Procedure BuildWelcome;
Var
 I : Integer;
Begin
 For I := 1 To 11 Do VBlank;
 VAdd(Tx(A_L1), LightGray, 1, 0, 0);
 VAdd(Tx(A_L2), LightGray, 1, 0, 0);
 VBlank;
 VAdd(Tx(A_L3), DarkGray, 1, 0, 0);
 VAdd(Tx(A_L4), DarkGray, 1, 0, 0);
 VBlank; VBlank; VBlank; VBlank; VBlank;
 If HasCur Then Begin
  VAdd(DomLine, Yellow, 1, 0, 0);
  VAdd(AscLine, LightCyan, 1, 0, 0);
 End Else VAdd(Tx(S_NOPERSON), LightCyan, 1, 0, 0);
End;

Procedure BuildView;
Begin
 VClear;
 If (Not HasCur) And (View <> V_GUIDE) Then View := V_WELCOME;
 Case View Of
  V_WELCOME : BuildWelcome;
  V_NATAL : BuildNatal;
  V_HOUSES : BuildHouses;
  V_PLANET : BuildPlanet(ViewArg);
  V_HOUSE : BuildHouse(ViewArg);
  V_DOMIN : BuildDomin;
  V_ASC : BuildAsc;
  V_DAY : BuildDay;
  V_DAYPL : BuildDayPl(ViewArg);
  V_DDOM : BuildDDom;
  V_PREV : BuildPrev;
  V_TAROT : BuildTarot;
  V_COMP : BuildComp;
  V_GUIDE : BuildGuide;
 End;
 Case View Of
  V_NATAL : StatusMsg := Tx(S_KEYSNAT);
  V_HOUSES : StatusMsg := Tx(S_KEYSHS);
  V_DAY : StatusMsg := Tx(S_KEYSDAY);
  V_WHEEL : StatusMsg := Tx(S_KEYSWHL);
  V_WELCOME : StatusMsg := '';
 Else
  If VLN > VIS_LINES Then StatusMsg := Tx(S_SCROLL) Else StatusMsg := '';
 End;
End;

Procedure SetView(V, Arg : Integer);
Begin
 If (V >= V_PLANET) And (V <> V_DAY) And (V <> V_PREV) And
    (V <> V_TAROT) And (V <> V_GUIDE) Then Begin
  If (View = V_NATAL) Or (View = V_HOUSES) Or (View = V_DAY) Then
   PrevView := View;
 End Else PrevView := V;
 View := V;
 ViewArg := Arg;
 BuildView;
 Refresh;
End;

Procedure ExportPage;
Var
 F : Text;
 I : Integer;
 S : String;
Begin
 Assign(F, TXTFILE);
 {$I-}
 Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Begin MsgBox(Tx(D_IOERR)); Exit; End;
 WriteLn(F, 'Astromancie');
 If HasCur Then
  WriteLn(F, Cur.Name, ' ', DateStr(Cur.D, Cur.M, Cur.Y), ' ',
          TimeStr(Cur.Hh, Cur.Mi), ' ', Cur.City);
 WriteLn(F);
 For I := 1 To VLN Do Begin
  S := VL[I].S;
  If VL[I].Kind = 1 Then S := PadR('', (78 - Length(S)) Div 2) + S
  Else S := PadR('', VL[I].Ind) + S;
  WriteLn(F, S);
 End;
 Close(F);
 MsgBox(Tx(D_EXPORTED) + ' ' + TXTFILE);
End;

{ ================================================================== }
{ Actions                                                            }
{ ================================================================== }

Function NeedPerson : Boolean;
Begin
 NeedPerson := HasCur;
 If Not HasCur Then MsgBox(Tx(D_NOPERS));
End;

Function ChoosePlanet(Title : String; WithMore : Boolean) : Integer;
Var
 I, Sel, N : Integer;
Begin
 For I := 1 To 10 Do LItem[I] := IStr(I Mod 10) + '  ' + PlName(I);
 N := 10;
 If WithMore Then Begin
  LItem[11] := 'D  ' + Tx(T_DOMIN);
  LItem[12] := 'A  ' + Tx(T_ASCEND);
  N := 12;
 End;
 Sel := 1;
 If ListDialog(Title, N, Sel, False) = 1 Then ChoosePlanet := Sel
 Else ChoosePlanet := 0;
End;

Procedure DoAction(A : Integer); Forward;

Procedure OpenPerson(Var P : TPerson);
Begin
 Cur := P;
 HasCur := True;
 Recompute;
 SetView(V_NATAL, 0);
End;

Procedure DoAction(A : Integer);
Var
 P : TPerson;
 I, Sel, R : Integer;
 C2 : TChart;
Begin
 StatusMsg := '';
 Case A Of
  A_NEW : Begin
   FillChar(P, SizeOf(P), 0);
   P.Name := ''; P.Ctry := 'F'; P.State := ''; P.City := '';
   If PersonDialog(P) Then Begin
    OpenPerson(P);
    If AskBox(Tx(D_ASKSAVE), True) Then AddToCal(Cur);
   End;
   BuildView;
   Refresh;
  End;
  A_OPEN : Begin
   CalItems;
   Sel := 1;
   R := ListDialog(Tx(D_CALEPIN), CalN, Sel, True);
   If R = 1 Then OpenPerson(Cal[Sel])
   Else If R = 2 Then Begin
    If AskBox(Tx(D_ASKDEL) + ' ' + Cal[Sel].Name, True) Then Begin
     For I := Sel To CalN - 1 Do Cal[I] := Cal[I + 1];
     Dec(CalN);
     If Not SaveCal Then MsgBox(Tx(D_IOERR));
    End;
   End;
   BuildView;
   Refresh;
  End;
  A_SAVE : If NeedPerson Then Begin AddToCal(Cur); Refresh; End;
  A_EXPORT : Begin ExportPage; Refresh; End;
  A_QUIT : If AskBox(Tx(D_QUITASK), True) Then QuitReq := True
           Else Refresh;
  A_NATAL : If NeedPerson Then SetView(V_NATAL, 0) Else Refresh;
  A_HOUSES : If NeedPerson Then SetView(V_HOUSES, 0) Else Refresh;
  A_WHEEL : If NeedPerson Then SetView(V_WHEEL, 0) Else Refresh;
  A_PLDET : If NeedPerson Then Begin
   I := ChoosePlanet(Tx(D_CHOOSEP), True);
   If I = 11 Then SetView(V_DOMIN, 0)
   Else If I = 12 Then SetView(V_ASC, 0)
   Else If I > 0 Then SetView(V_PLANET, I) Else Refresh;
  End Else Refresh;
  A_HSDET : If NeedPerson Then Begin
   For I := 1 To 12 Do LItem[I] := PadR(Tx(T_HOUSE) + ' ' + ROMAN[I], 14) +
    SgName(RI.hS[I]);
   Sel := 1;
   If ListDialog(Tx(D_CHOOSEH), 12, Sel, False) = 1 Then
    SetView(V_HOUSE, Sel) Else Refresh;
  End Else Refresh;
  A_DOMIN : If NeedPerson Then SetView(V_DOMIN, 0) Else Refresh;
  A_ASC : If NeedPerson Then SetView(V_ASC, 0) Else Refresh;
  A_DATE : Begin
   If DateDialog(DayD, DayM, DayY) Then Recompute;
   BuildView;
   Refresh;
  End;
  A_DAY : If NeedPerson Then SetView(V_DAY, 0) Else Refresh;
  A_PREV : If NeedPerson Then SetView(V_PREV, 0) Else Refresh;
  A_TAROT : If NeedPerson Then SetView(V_TAROT, 0) Else Refresh;
  A_DDOM : If NeedPerson Then SetView(V_DDOM, 0) Else Refresh;
  A_DPDET : If NeedPerson Then Begin
   I := ChoosePlanet(Tx(D_CHOOSEP), False);
   If I > 0 Then SetView(V_DAYPL, I) Else Refresh;
  End Else Refresh;
  A_COMP : If NeedPerson Then Begin
   CalItems;
   Sel := 1;
   If ListDialog(Tx(D_CHOOSEC), CalN, Sel, False) = 1 Then Begin
    CompP := Cal[Sel];
    ChartOf(CompP, C2);
    CalcComp(RI, C2, CompR);
    SetView(V_COMP, 0);
   End Else Refresh;
  End Else Refresh;
  A_GUIDE : SetView(V_GUIDE, 0);
  A_ABOUT : Begin
   MsgBox(Tx(A_TITLE) + ' - ' + Tx(A_SUB) + '. ' + Tx(A_L1) + ' ' +
          Tx(A_L2) + ' ' + Tx(A_L3) + ' ' + Tx(A_L4));
   Refresh;
  End;
 End;
End;

Procedure DoTag(T : Integer);
Begin
 If (T > 100) And (T <= 110) Then SetView(V_PLANET, T - 100)
 Else If T = 120 Then SetView(V_DOMIN, 0)
 Else If T = 121 Then SetView(V_ASC, 0)
 Else If (T > 200) And (T <= 212) Then SetView(V_HOUSE, T - 200)
 Else If (T > 300) And (T <= 310) Then SetView(V_DAYPL, T - 300)
 Else If T = 320 Then SetView(V_DDOM, 0);
End;

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

Procedure HandleKey(K : Word);
Var
 C : Char;
 I, N : Integer;
Begin
 If K >= 256 Then Begin
  Case K - 256 Of
   59 : DoAction(A_GUIDE);
   60 : DoAction(A_NEW);
   61 : DoAction(A_OPEN);
   62 : DoAction(A_DATE);
   63 : DoAction(A_NATAL);
   64 : DoAction(A_HOUSES);
   65 : DoAction(A_WHEEL);
   66 : DoAction(A_DAY);
   67 : DoAction(A_PREV);
   68 : DoAction(RunMenu(1));
   45 : DoAction(A_QUIT);
   72 : Scroll(-1);
   80 : Scroll(1);
   73 : Scroll(-VIS_LINES + 2);
   81 : Scroll(VIS_LINES - 2);
   71 : Scroll(-MAXVL);
   79 : Scroll(MAXVL);
  Else
   C := AltLetter(K - 256);
   If C <> #0 Then
    For I := 1 To NMENU Do
     If AmpChar(Tx(MTitle[I])) = C Then Begin
      DoAction(RunMenu(I));
      Exit;
     End;
  End;
  Exit;
 End;
 C := UpCase(Chr(K));
 If K = 27 Then Begin
  If (View = V_PLANET) Or (View = V_HOUSE) Or (View = V_DOMIN) Or
     (View = V_ASC) Or (View = V_DAYPL) Or (View = V_DDOM) Then
   SetView(PrevView, 0)
  Else If View <> V_WELCOME Then SetView(V_WELCOME, 0);
  Exit;
 End;
 If Not HasCur Then Exit;
 Case View Of
  V_NATAL, V_WHEEL : Begin
   If (C >= '0') And (C <= '9') Then Begin
    N := Ord(C) - 48;
    If N = 0 Then N := 10;
    SetView(V_PLANET, N);
   End Else If C = 'D' Then SetView(V_DOMIN, 0)
   Else If C = 'A' Then SetView(V_ASC, 0)
   Else If (C = 'T') And (View = V_WHEEL) Then Begin
    ShowTransit := Not ShowTransit;
    Refresh;
   End;
  End;
  V_HOUSES : Begin
   N := 0;
   If (C >= '1') And (C <= '9') Then N := Ord(C) - 48;
   If C = '0' Then N := 10;
   If C = '-' Then N := 11;
   If C = '=' Then N := 12;
   If N > 0 Then SetView(V_HOUSE, N);
  End;
  V_DAY : Begin
   If (C >= '0') And (C <= '9') Then Begin
    N := Ord(C) - 48;
    If N = 0 Then N := 10;
    SetView(V_DAYPL, N);
   End Else If C = 'D' Then SetView(V_DDOM, 0);
  End;
 End;
End;

Procedure HandleClick(X, Y : LongInt);
Var
 I : Integer;
Begin
 If (Y >= BODY_Y) And (Y < STAT_Y) And (View <> V_WHEEL) Then Begin
  { barre de defilement : fleches et pages }
  If (VLN > VIS_LINES) And (X >= SCREEN_W - 15) Then Begin
   If Y < BODY_Y + 14 Then Scroll(-1)
   Else If Y > STAT_Y - 15 Then Scroll(1)
   Else If Y < BODY_Y + 14 + (STAT_Y - BODY_Y - 28) * VTop Div VLN Then
    Scroll(-VIS_LINES + 2)
   Else Scroll(VIS_LINES - 2);
   Exit;
  End;
  I := VTop + (Y - BODY_Y - 4) Div LINE_H + 1;
  If (I >= 1) And (I <= VLN) And (VL[I].Tag > 0) Then DoTag(VL[I].Tag);
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
{ Mode texte de verification : ASTROMAN /TEST j m a h mn ofs lond   }
{ lonm ouest latd latm sud jj mj aj                                  }
{ ================================================================== }

Procedure RunTest;
Var
 V : Array[1..15] Of Real;
 I, E : Integer;
 S : String;
Begin
 For I := 1 To 15 Do Begin
  Val(ParamStr(I + 1), V[I], E);
  If E <> 0 Then V[I] := 0;
 End;
 Cur.Name := 'TEST';
 Cur.D := Round(V[1]); Cur.M := Round(V[2]); Cur.Y := Round(V[3]);
 Cur.Hh := Round(V[4]); Cur.Mi := Round(V[5]); Cur.Ofs := V[6];
 Cur.LonD := Round(V[7]); Cur.LonM := Round(V[8]); Cur.West := V[9] <> 0;
 Cur.LatD := Round(V[10]); Cur.LatM := Round(V[11]);
 Cur.South := V[12] <> 0;
 DayD := Round(V[13]); DayM := Round(V[14]); DayY := Round(V[15]);
 HasCur := True;
 Recompute;
 For I := 1 To 10 Do Begin
  Str(NatC.Pl[I] : 0 : 4, S);
  WriteLn('PL ', I, ' ', S, ' ', RI.nS[I], ' ', RI.nD[I], ' ', RI.nHouse[I],
          ' ', RI.Fn[I], ' ', RI.Fd[I], ' ', RI.Master[I], ' ', RI.tHouse[I]);
 End;
 For I := 1 To 12 Do Begin
  Str(NatC.Cu[I] : 0 : 4, S);
  WriteLn('CU ', I, ' ', S);
 End;
 For I := 1 To 10 Do Begin
  Str(DayC.Pl[I] : 0 : 4, S);
  WriteLn('DP ', I, ' ', S);
 End;
 WriteLn('DOM ', RI.Dom, ' ', RI.Puis, ' DDOM ', RI.DDom, ' ', RI.DForce,
         ' ASC ', RI.Asc);
 For I := 1 To PrevN Do
  WriteLn('PREV ', PrevL[I].A, ' ', PrevL[I].B, ' ', PrevL[I].DType, ' ',
          PrevL[I].NType, ' ', PrevL[I].Idx);
 For I := 1 To 10 Do WriteLn('KEY ', I, ' ', KeyNat(I));
End;

Procedure RunZone;
Var
 F : TFields;
Begin
 F.N := 9;
 F.Val[4] := ParamStr(2);
 F.Val[5] := ParamStr(3);
 If F.Val[5] = '-' Then F.Val[5] := '';
 F.Val[6] := ParamStr(4);
 F.Val[2] := ParamStr(5);
 F.Val[7] := ''; F.Val[8] := ''; F.Val[9] := '';
 WriteLn(LookupPlace(F));
 WriteLn('LAT ', F.Val[7], ' LON ', F.Val[8], ' OFS ', F.Val[9]);
End;

{ ================================================================== }
{ Programme principal                                                }
{ ================================================================== }

Var
 Yy, Mm, Dd, Dw : Word;

BEGIN
 InitLanguage;
 If ParamStr(1) = '/TEST' Then Begin
  RunTest;
  Halt;
 End;
 If ParamStr(1) = '/ZONE' Then Begin
  RunZone;
  Halt;
 End;
 GetDate(Yy, Mm, Dd, Dw);
 DayD := Dd; DayM := Mm; DayY := Yy;
 HasCur := False;
 ShowTransit := True;
 ActiveMenu := 0;
 StatusMsg := '';
 MsSaved := False;
 LoadCal;
 InitBmi;
 EvHead := 0; EvTail := 0; OsFrame := 0; OsClient := 0;
 OpenWindow('ASTROMAN', 'Astromancie');
 MouseOK := True;
 MsX := SCREEN_W Div 2;
 MsY := SCREEN_H Div 2;
 MsB := 0;
 View := V_WELCOME;
 PrevView := V_WELCOME;
 BuildView;
 Refresh;
 MainLoop;
 Dummy := WinDestroyWindow(OsFrame);
END.
