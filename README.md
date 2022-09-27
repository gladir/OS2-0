# OS2-0
Clone d'OS/2 en Pascal

![image](https://user-images.githubusercontent.com/11842176/146266141-ea1e72bd-4bb4-4132-93f9-2f753ed5cf58.png)

<h2>Liste des fichiers</h2>

Voici la liste des différents fichiers proposés dans OS2-0 :

<table>
		<tr>
			<th>Nom</th>
			<th>Description</th>	
		</tr>
		<tr>
		 	<td><b>APPEND.PAS</b></td>
			<td>Cette commande permet d'ouvrir des fichiers quelconque se trouvant dans les répertoires spécifiés comme s'il s'agissait du répertoire courant.</td>
		</tr>
		<tr>
			<td><b>ATTRIB.PAS</b></td>
			<td>Cette commande permet de demander ou de changer les attributs d'un fichier.</td>
		</tr>
		<tr>
			<td><b>CMD.PAS</b></td>
			<td>Cette commande permet de lancer l'interpréteur de commande OS/2. Il s'agit d'un équivalent du CMD de OS/2.</td>
		</tr>  
		<tr>
			<td><b>COMMAND.PAS</b></td>
			<td>Logiciel clone d'un <i>COMMAND.COM</i> du système d'exploitation <a href="https://www.gladir.com/OS/DOS/intro.htm"><i>DOS</i></a>.</td>
		</tr>
		<tr>
			<td><b>COMP.PAS</b></td>
			<td>Cette commande permet de comparer deux fichiers. Cette commande est un equivalent du <a href="https://www.gladir.com/OS/PCDOS/intro.htm">PC-DOS</a> ou <a href="https://www.gladir.com/OS/MSDOS/intro.htm">MS-DOS</a>.</td>
		</tr>
		<tr>
			 <td><b>DEBUG.PAS</b></td>
			 <td>Cette commande permet de deboguer un programme.</td>
		</tr>
		<tr>
			<td><b>DISKCOMP.PAS</b></td>
			<td>Cette commande permet de comparer des disquettes ou des images.</td>
		</tr>		
		<tr>
		    	<td><b>DISKCOPY.PAS</b></td>
		    	<td>Cette commande permet de copier des disquettes ou des images.</td>
		</tr>	
		<tr>
			<td><b>DOSKEY.PAS</b></td>
			<td>Cette commande permet de charger le programme DOSKEY.</td>
		</tr>
		<tr>
			<td><b>EDLIN.PAS</b></td>
			<td>Cette commande permet de lancer l'éditeur en ligne de commande.</td>
		</tr>
		<tr>
			<td><b>EXE2BIN.PAS</b></td>
			<td>Cette commande permet de convertir un fichier EXE en binaire (COM).</td>
		</tr>
		<tr>
			<td><b>FIND.PAS</b></td>
			<td>Cette commande permet de rechercher une chaine de caractères dans des fichiers. Cette commande est un équivalent du DOS.</td>
		</tr>
		<tr>
			<td><b>FORMAT.PAS</b></td>
			<td>Cette commande permet de formater un unite de disquette.</td>
		</tr>
		<tr>
			<td><b>GRAFTABL.PAS</b></td>
			<td>Cette commande permet d'effectuer le chargement en mémoire conventionnelle d'une table de police de caractères pour les modes graphiques.</td>
		</tr>
		<tr>
			<td><b>MORE.PAS</b></td>
			<td>Cette commande permet de recevoir l'entrée puis l'affichage sur un périphérique un écran à la fois.</td>
    		</tr>	
    		<tr>
			<td><b>MOVE.PAS</td>
			<td>Cette commande permet de déplacer un fichier.</td>
		</tr>
		<tr>
			<td><b>SORT.PAS</b></td>
			<td>Cette commande permet de trier une fichier texte ASCII et de retourner le résultat. Cette commande est un équivalent de la commande du DOS.</td>
		</tr>
		<tr>
			<td><b>TREE.PAS</b></td>
			<td>Cette commande permet d'afficher un arbre de répertoire.</td>
		</tr>
		<tr>
			<td><b>XCOPY.PAS</b></td>
			<td>Cette commande permet d'effectuer la copie étendue avec sous-répertoire de fichier(s) vers un nouvel emplacement.</td>
		</tr>
	</table>

<h2>Compilation</h2>
	
Les fichiers Pascal n'ont aucune dépendances, il suffit de télécharger le fichier désiré et de le compiler avec Free Pascal avec la syntaxe de commande  :

<pre><b>fpc</b> <i>LEFICHIER.PAS</i></pre>
	
Sinon, vous pouvez également le compiler avec le Turbo Pascal à l'aide de la syntaxe de commande suivante :	

<pre><b>tpc</b> <i>LEFICHIER.PAS</i></pre>
	
Par exemple, si vous voulez compiler CMD.PAS, vous devrez tapez la commande suivante :

<pre><b>fpc</b> CMD.PAS</pre>

<h2>Licence</h2>
<ul>
 <li>Le code source est publié sous la licence <a href="https://github.com/gladir/OS2-0/blob/main/LICENSE">MIT</a>.</li>
 <li>Le paquet original est publié sous la licence <a href="https://github.com/gladir/OS2-0/blob/main/LICENSE">MIT</a>.</li>
</ul>
