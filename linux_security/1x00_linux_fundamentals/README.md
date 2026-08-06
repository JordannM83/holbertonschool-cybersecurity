# Linux : Système de fichiers, Permissions et Sécurité

## Objectifs

L'objectif de ce projet est de comprendre le fonctionnement du système de fichiers Linux, des permissions, de l'administration à distance et des bonnes pratiques de sécurité. Ces notions sont indispensables en administration système, DevOps et cybersécurité.

---

# La hiérarchie du système de fichiers Linux (Filesystem Hierarchy)

Contrairement à Windows qui utilise plusieurs lecteurs (C:, D:, ...), Linux possède une seule arborescence dont la racine est le répertoire **/**.

Chaque dossier possède un rôle précis.

## /

Le répertoire **/** est la racine du système de fichiers. Tous les autres dossiers se trouvent à l'intérieur de celui-ci.

---

## /home

Le dossier **/home** contient les dossiers personnels des utilisateurs.

Exemple :

```text
/home/alice
/home/bob
```

Chaque utilisateur possède son propre espace de travail dans lequel il peut créer ses fichiers personnels.

---

## /etc

Le dossier **/etc** contient les fichiers de configuration du système et des services.

On y trouve par exemple :

- la configuration SSH
- les utilisateurs (`passwd`)
- les mots de passe chiffrés (`shadow`)
- la configuration réseau
- les services système

Ces fichiers sont essentiels au bon fonctionnement du système et sont généralement modifiables uniquement par l'administrateur.

---

## /var

Le dossier **/var** contient les données qui évoluent constamment.

On y retrouve notamment :

- les journaux (logs)
- les bases de données
- les caches
- les files d'attente des services

Exemples :

```text
/var/log/
/var/cache/
/var/lib/
```

Les fichiers présents dans **/var/log** sont très importants pour diagnostiquer une panne ou analyser une attaque informatique.

---

## /usr

Le dossier **/usr** contient les logiciels installés sur le système.

On y trouve :

- les exécutables
- les bibliothèques
- la documentation
- les ressources des applications

Exemples :

```text
/usr/bin
/usr/lib
/usr/share
```

Contrairement à **/var**, son contenu change rarement après l'installation des logiciels.

---

# Le modèle de permissions Linux

Chaque fichier ou dossier possède trois informations principales :

- un propriétaire (Owner)
- un groupe (Group)
- des permissions

Les permissions définissent qui peut accéder à une ressource et quelles actions sont autorisées.

Linux distingue trois catégories d'utilisateurs :

- **Utilisateur (User / Owner)** : le propriétaire du fichier.
- **Groupe (Group)** : les utilisateurs appartenant au groupe propriétaire.
- **Autres (Others)** : tous les autres utilisateurs du système.

Chaque catégorie peut disposer de trois permissions.

| Permission | Symbole | Description |
|------------|---------|-------------|
| Lecture | r | Lire un fichier ou afficher le contenu d'un dossier |
| Écriture | w | Modifier un fichier ou créer/supprimer des fichiers dans un dossier |
| Exécution | x | Exécuter un programme ou entrer dans un dossier |

Exemple :

```text
-rwxr-x---
```

Le propriétaire peut :

- lire
- écrire
- exécuter

Le groupe peut :

- lire
- exécuter

Les autres utilisateurs n'ont aucun accès.

---

## Les permissions sur un dossier

Pour un dossier, les permissions ne signifient pas exactement la même chose.

- **Lecture (r)** : permet d'afficher le contenu du dossier.
- **Écriture (w)** : permet de créer ou supprimer des fichiers.
- **Exécution (x)** : permet d'entrer dans le dossier.

Sans le droit d'exécution, il est impossible d'accéder aux fichiers contenus dans un dossier même si le droit de lecture est présent.

---

# Les permissions en notation octale

Chaque permission possède une valeur numérique.

| Permission | Valeur |
|------------|--------|
| Lecture | 4 |
| Écriture | 2 |
| Exécution | 1 |

Les valeurs sont additionnées.

Exemples :

| Valeur | Permissions |
|--------|-------------|
| 7 | rwx |
| 6 | rw- |
| 5 | r-x |
| 4 | r-- |
| 0 | --- |

Quelques permissions très utilisées :

```text
755 = rwxr-xr-x
750 = rwxr-x---
700 = rwx------
644 = rw-r--r--
640 = rw-r-----
600 = rw-------
```

On les applique avec la commande :

```bash
chmod 755 fichier
```

---

# Les permissions en notation symbolique

Linux permet également de modifier les permissions avec une notation plus explicite.

Exemples :

```bash
chmod u=rwx,g=rx,o=rx fichier
```

ou

```bash
chmod g+w dossier
```

Cette notation est plus lisible car elle indique directement quel utilisateur reçoit quelle permission.

---

# Les bits spéciaux

Linux possède trois permissions spéciales qui modifient le comportement classique des permissions.

---

## Le bit SUID (Set User ID)

Le bit **SUID** permet d'exécuter un programme avec les droits de son propriétaire plutôt que ceux de l'utilisateur qui le lance.

Exemple :

```text
-rwsr-xr-x
```

La commande **passwd** utilise ce mécanisme afin qu'un utilisateur puisse modifier son mot de passe sans être administrateur.

### Risque de sécurité

Un programme SUID mal configuré peut permettre une élévation de privilèges et donner un accès administrateur à un attaquant.

---

## Le bit SGID (Set Group ID)

Le bit **SGID** possède deux comportements.

### Sur un fichier

Le programme s'exécute avec les droits du groupe propriétaire.

### Sur un dossier

Tous les nouveaux fichiers créés héritent automatiquement du groupe du dossier.

Exemple :

```bash
chmod 2770 /shared/devs
```

Cette fonctionnalité est très utilisée pour les dossiers de travail collaboratifs.

---

## Le Sticky Bit

Le **Sticky Bit** est principalement utilisé sur les dossiers.

Il empêche un utilisateur de supprimer les fichiers appartenant à un autre utilisateur.

Exemple :

```text
drwxrwxrwt
```

Le meilleur exemple est le dossier :

```text
/tmp
```

Tous les utilisateurs peuvent créer des fichiers dans ce dossier mais chacun ne peut supprimer que les siens.

---

# Administration à distance avec SSH et SCP

Les serveurs Linux sont généralement administrés à distance.

## SSH

SSH (Secure Shell) permet d'obtenir un terminal distant sécurisé.

Exemple :

```bash
ssh utilisateur@serveur
```

Toutes les communications sont chiffrées.

---

## SCP

SCP permet de copier des fichiers entre deux machines via SSH.

Envoyer un fichier :

```bash
scp script.sh utilisateur@serveur:/tmp/
```

Récupérer un fichier :

```bash
scp utilisateur@serveur:/tmp/fichier.txt .
```

SSH et SCP remplacent avantageusement Telnet ou FTP car ils protègent les identifiants et les données grâce au chiffrement.

---

# Rechercher des fichiers avec find

La commande **find** permet de rechercher des fichiers selon différents critères.

Quelques exemples :

Rechercher tous les scripts shell :

```bash
find . -name "*.sh"
```

Rechercher uniquement les dossiers :

```bash
find /var -type d
```

Rechercher les fichiers de plus de 100 Mo :

```bash
find / -size +100M
```

Rechercher tous les fichiers SUID :

```bash
find / -perm -4000
```

Cette commande est indispensable lors d'un audit de sécurité.

---

# Rechercher du contenu avec grep

Alors que **find** recherche des fichiers, **grep** recherche du texte à l'intérieur des fichiers.

Exemple :

```bash
grep "password" fichier.conf
```

Recherche récursive :

```bash
grep -r "password" /etc
```

Afficher uniquement les noms des fichiers :

```bash
grep -rl "password" /etc
```

Ignorer les erreurs de permission :

```bash
grep -rl "password" /etc 2>/dev/null
```

Les expressions régulières permettent d'effectuer des recherches beaucoup plus avancées.

---

# Les ACL (Access Control Lists)

Le système de permissions classique est limité à :

- un propriétaire
- un groupe
- les autres utilisateurs

Les **ACL** permettent d'ajouter des permissions spécifiques à plusieurs utilisateurs ou groupes.

Attribuer un droit de lecture :

```bash
setfacl -m u:alice:r fichier.txt
```

Afficher les ACL :

```bash
getfacl fichier.txt
```

Les ACL sont particulièrement utiles lorsqu'un seul utilisateur supplémentaire doit accéder à un fichier sans modifier son propriétaire.

---

# Auditer avant de corriger

Avant de modifier des permissions, il est essentiel d'analyser la situation.

Les commandes les plus utiles sont :

```bash
ls -l
```

```bash
stat fichier
```

```bash
getfacl fichier
```

Modifier des permissions sans comprendre leur rôle peut casser une application ou créer une faille de sécurité.

---

# Le principe du moindre privilège (Least Privilege)

Le principe du moindre privilège consiste à donner uniquement les droits nécessaires à un utilisateur ou à une application.

Par exemple, il vaut mieux utiliser :

```bash
chmod 640 fichier
```

plutôt que :

```bash
chmod 777 fichier
```

Limiter les permissions réduit fortement la surface d'attaque d'un système.

---

# La Défense en Profondeur (Defense in Depth)

Les permissions Linux ne constituent qu'une seule couche de sécurité.

Un système sécurisé repose sur plusieurs mécanismes complémentaires :

- Permissions Linux
- Pare-feu
- Authentification forte
- Mises à jour régulières
- Chiffrement
- ACL
- Sauvegardes
- Supervision des journaux
- Détection d'intrusion

Si une couche de sécurité est contournée, les autres continuent de protéger le système.

Cette stratégie est appelée **Défense en Profondeur** et constitue l'un des principes fondamentaux de la cybersécurité.

---

# Conclusion

La maîtrise du système de fichiers Linux, des permissions et des principes de sécurité est indispensable pour administrer un serveur de manière fiable et sécurisée. Comprendre les répertoires du système, savoir attribuer les bonnes permissions, utiliser les bits spéciaux, les ACL, SSH, SCP, `find` et `grep` permet de gérer efficacement un système Linux tout en appliquant les bonnes pratiques de cybersécurité comme le **principe du moindre privilège**, l'**audit avant modification** et la **défense en profondeur**.