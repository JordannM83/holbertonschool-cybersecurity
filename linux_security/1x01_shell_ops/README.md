# Linux Streams, Pipelines et Traitement de Texte

## Objectifs

L'objectif de ce projet est de comprendre comment Linux gère les flux d'entrée et de sortie, comment manipuler efficacement des données textuelles avec les outils en ligne de commande, et comment utiliser ces compétences pour automatiser des tâches d'administration système et d'analyse en cybersécurité.

---

# Les flux standards (Standard Streams)

Sous Linux, chaque programme communique avec son environnement grâce à trois flux standards. Ces flux permettent de recevoir des données, d'afficher des résultats et de signaler des erreurs.

| Flux | Descripteur | Description |
|------|-------------|-------------|
| stdin | 0 | Entrée standard (données reçues par le programme) |
| stdout | 1 | Sortie standard (résultat normal du programme) |
| stderr | 2 | Sortie d'erreur |

Par défaut :

- **stdin** correspond au clavier.
- **stdout** correspond au terminal.
- **stderr** correspond également au terminal, mais est utilisé uniquement pour les messages d'erreur.

Exemple :

```bash
cat fichier.txt
```

Le contenu du fichier est envoyé sur **stdout**.

Si le fichier n'existe pas :

```bash
cat inconnu.txt
```

Le message d'erreur est envoyé sur **stderr**.

---

# La redirection des flux

Linux permet de rediriger les flux vers un fichier ou vers une autre commande.

Rediriger la sortie standard :

```bash
ls > fichiers.txt
```

Le résultat est enregistré dans `fichiers.txt`.

Ajouter à la fin d'un fichier :

```bash
ls >> fichiers.txt
```

Rediriger uniquement les erreurs :

```bash
find / -name "*.conf" 2> erreurs.log
```

Rediriger à la fois la sortie standard et les erreurs :

```bash
commande > sortie.log 2>&1
```

Ignorer complètement les erreurs :

```bash
commande 2>/dev/null
```

La maîtrise des redirections est indispensable pour automatiser des scripts et analyser de grandes quantités de données.

---

# Les descripteurs de fichiers (File Descriptors)

Sous Linux, tout est considéré comme un fichier.

Cela inclut :

- les fichiers classiques ;
- les dossiers ;
- les périphériques ;
- les sockets réseau ;
- les tubes (pipes) ;
- les flux d'entrée et de sortie.

Chaque processus manipule ces ressources grâce à des **descripteurs de fichiers**, qui sont simplement des numéros.

Les trois premiers sont toujours réservés :

- 0 → stdin
- 1 → stdout
- 2 → stderr

Lorsqu'un programme ouvre un nouveau fichier, Linux lui attribue automatiquement un nouveau descripteur.

Cette approche unifie la gestion des ressources et simplifie énormément la programmation sous Linux.

---

# Les pipelines (Pipes)

Un pipeline permet d'envoyer directement la sortie d'une commande vers l'entrée d'une autre.

Exemple :

```bash
cat access.log | grep "404"
```

Ici :

- `cat` produit des données.
- `grep` les reçoit immédiatement.

Le symbole `|` évite la création de fichiers temporaires.

Un pipeline est généralement :

- plus rapide ;
- moins gourmand en espace disque ;
- plus simple à automatiser.

Les pipelines constituent l'un des principes fondamentaux de la philosophie Unix : **chaque programme réalise une tâche simple, puis transmet son résultat au programme suivant.**

---

# La substitution de processus (Process Substitution)

La substitution de processus permet d'utiliser la sortie d'une commande comme s'il s'agissait d'un fichier.

Elle utilise :

```bash
<()
```

ou

```bash
>()
```

Exemple :

```bash
diff <(sort fichier1.txt) <(sort fichier2.txt)
```

Ici, les deux commandes `sort` sont exécutées avant `diff`, sans créer de fichiers temporaires.

Cette technique est très pratique lorsqu'une commande attend des fichiers en entrée alors que l'on souhaite lui fournir le résultat d'autres commandes.

---

# grep : rechercher du texte

`grep` est l'outil principal pour rechercher des motifs dans un texte.

Exemple :

```bash
grep "error" logs.txt
```

Recherche récursive :

```bash
grep -r "password" /etc
```

Afficher uniquement le nom des fichiers :

```bash
grep -rl "TODO" .
```

Utiliser les expressions régulières étendues :

```bash
grep -E "404|500"
```

`grep` est largement utilisé pour l'analyse de journaux, les audits de configuration et la recherche d'informations sensibles.

---

# sed : modifier du texte

`sed` est un éditeur de flux.

Contrairement à un éditeur classique, il modifie le texte sans ouvrir le fichier.

Remplacer un mot :

```bash
sed 's/http/https/'
```

Remplacer toutes les occurrences :

```bash
sed 's/error/warning/g'
```

Modifier directement un fichier :

```bash
sed -i 's/localhost/server/g' config.conf
```

`sed` est très utilisé pour automatiser les modifications de fichiers de configuration.

---

# awk : traiter des colonnes

`awk` est spécialisé dans le traitement des fichiers structurés.

Il découpe automatiquement chaque ligne en colonnes.

Afficher la première colonne :

```bash
awk '{print $1}'
```

Afficher la troisième colonne :

```bash
awk '{print $3}'
```

Compter les lignes :

```bash
awk 'END {print NR}'
```

`awk` est particulièrement adapté aux logs, fichiers CSV et tableaux.

---

# xargs : transformer une liste en arguments

Certaines commandes produisent une liste alors que d'autres attendent des arguments.

`xargs` fait le lien entre les deux.

Exemple :

```bash
find . -name "*.tmp" | xargs rm
```

Chaque fichier trouvé devient un argument de la commande `rm`.

Il est également très utile pour lancer des commandes sur un grand nombre de fichiers.

---

# Les outils complémentaires

## sort

Trie les lignes.

```bash
sort fichier.txt
```

---

## uniq

Supprime les doublons successifs.

```bash
sort fichier.txt | uniq
```

Compter les occurrences :

```bash
sort fichier.txt | uniq -c
```

---

## cut

Extrait une colonne.

```bash
cut -d: -f1 /etc/passwd
```

---

## tr

Transforme des caractères.

Mettre tout en majuscules :

```bash
tr 'a-z' 'A-Z'
```

Supprimer les espaces :

```bash
tr -d ' '
```

---

## tee

Affiche la sortie tout en l'enregistrant dans un fichier.

```bash
commande | tee resultat.txt
```

Très pratique pour conserver une trace d'un pipeline.

---

# Analyse de journaux (Log Analysis)

Les fichiers de logs contiennent des informations précieuses sur le fonctionnement d'un système.

Grâce aux commandes précédentes, il est possible d'extraire rapidement :

- les adresses IP ;
- les horodatages ;
- les codes HTTP ;
- les erreurs ;
- les utilisateurs connectés.

Exemple :

```bash
grep "404" access.log
```

ou

```bash
awk '{print $1}' access.log
```

Ces techniques sont largement utilisées lors des audits et des investigations.

---

# Extraction des IoC (Indicators of Compromise)

Les IoC sont des indicateurs permettant de détecter une compromission.

Il peut s'agir :

- d'adresses IP malveillantes ;
- de domaines ;
- d'empreintes de fichiers (hash) ;
- de noms de processus ;
- de chemins suspects.

Les outils comme `grep`, `awk`, `cut` ou `sort` permettent d'extraire automatiquement ces informations à partir de fichiers volumineux.

---

# Opérations en masse (Bulk Operations)

Les pipelines permettent de traiter des milliers de fichiers automatiquement.

Exemple :

```bash
find . -name "*.conf" | xargs sed -i 's/http/https/g'
```

En une seule commande, tous les fichiers de configuration sont modifiés.

Cette automatisation évite les erreurs humaines et fait gagner un temps considérable.

---

# Détection d'anomalies

L'analyse de grands volumes de données permet d'identifier des comportements inhabituels.

Par exemple :

- une adresse IP apparaissant des milliers de fois ;
- un nombre anormal d'erreurs 500 ;
- un utilisateur se connectant à des heures inhabituelles ;
- une augmentation soudaine du trafic réseau.

Les commandes `sort`, `uniq`, `awk` et `grep` permettent de faire ressortir rapidement ces anomalies et constituent la base de nombreuses analyses de sécurité.

---

# Conclusion

Les flux standards, les pipelines et les outils de traitement de texte sont au cœur de l'écosystème Linux. En les maîtrisant, il devient possible d'automatiser des tâches complexes, de manipuler efficacement de grands volumes de données et de réaliser des analyses de sécurité performantes. Ces outils sont quotidiennement utilisés par les administrateurs système, les ingénieurs DevOps et les analystes en cybersécurité pour surveiller, maintenir et sécuriser les infrastructures Linux.