# Linux Security – Identity & Authentication

## Introduction

Sous Linux, la gestion des utilisateurs et des privilèges est l'un des piliers de la sécurité. Une mauvaise configuration d'un compte, d'un groupe ou d'un mécanisme d'authentification peut permettre à un attaquant d'obtenir des privilèges élevés sur un système.

L'objectif de ce module est de comprendre comment Linux identifie les utilisateurs, protège les mots de passe, contrôle les privilèges et sécurise l'authentification.

---

# Identity Fundamentals

## Les utilisateurs Linux

Chaque utilisateur possède une identité unique représentée par un **UID (User ID)**.

Linux ne travaille pas réellement avec les noms d'utilisateurs mais avec leur UID.

Exemple :

```
delta
```

peut correspondre à

```
UID = 1000
```

Lorsque tu exécutes :

```bash
id
```

Linux affiche :

- UID
- GID
- Groupes

---

## Le fichier /etc/passwd

Tous les utilisateurs sont enregistrés dans :

```
/etc/passwd
```

Exemple :

```
delta:x:1000:1000:Delta:/home/delta:/bin/bash
```

Chaque champ est séparé par `:`.

| Champ | Description |
|--------|-------------|
| Nom | Nom de l'utilisateur |
| x | Le mot de passe est stocké dans `/etc/shadow` |
| UID | Identifiant utilisateur |
| GID | Groupe principal |
| GECOS | Informations supplémentaires |
| Home | Répertoire personnel |
| Shell | Shell de connexion |

---

## Pourquoi UID 0 est spécial

L'utilisateur root possède :

```
UID = 0
```

Peu importe son nom.

Exemple :

```
admin:x:0:0::/root:/bin/bash
```

Même si l'utilisateur s'appelle **admin**, Linux lui donnera exactement les mêmes privilèges que root.

Il ne faut donc jamais créer un utilisateur avec un UID égal à 0.

---

## Le fichier /etc/shadow

Les mots de passe ne sont jamais stockés dans `/etc/passwd`.

Ils sont enregistrés dans :

```
/etc/shadow
```

Exemple :

```
delta:$6$J4KD.......
```

Ce fichier n'est lisible que par root.

---

## Les formats de hash

Les mots de passe sont stockés sous forme de hash.

Préfixes les plus courants :

```
$1$
```

MD5 (obsolète)

```
$5$
```

SHA-256

```
$6$
```

SHA-512

Aujourd'hui, SHA-512 est le plus courant sur de nombreuses distributions Linux.

Le mot de passe n'est jamais enregistré en clair.

---

## Comptes utilisateurs vs comptes système

Linux distingue deux catégories.

### Comptes humains

Créés pour les utilisateurs.

En général :

```
UID >= 1000
```

Ils disposent :

- d'un répertoire personnel
- d'un shell
- d'un mot de passe

---

### Comptes système

Créés pour les services.

Exemples :

- www-data
- mysql
- postgres
- daemon
- nobody

Ils utilisent généralement :

```
UID < 1000
```

Ils ne doivent pas pouvoir ouvrir une session interactive.

Leur shell est souvent :

```
/usr/sbin/nologin
```

ou

```
/bin/false
```

Cela empêche un attaquant de se connecter directement avec ces comptes.

---

# Privilege Management

## Les groupes Linux

Les permissions sont accordées via les groupes.

Commande :

```bash
groups
```

ou

```bash
id
```

---

## Les groupes dangereux

Certains groupes donnent pratiquement les privilèges root.

### docker

Les membres peuvent lancer un conteneur en montant tout le système.

Ils peuvent donc lire ou modifier n'importe quel fichier.

Être membre de docker revient quasiment à être root.

---

### disk

Autorise l'accès brut aux disques.

Un utilisateur peut :

- lire toutes les partitions
- modifier les données
- contourner les permissions Linux

---

### shadow

Donne accès au fichier :

```
/etc/shadow
```

Un attaquant peut récupérer les hashes des mots de passe et tenter de les casser hors ligne.

---

## Le fichier sudoers

Le comportement de sudo est défini dans :

```
/etc/sudoers
```

Toujours le modifier avec :

```bash
visudo
```

Jamais avec un éditeur classique.

---

## Syntaxe

```
utilisateur hôte=(utilisateur) commande
```

Exemple :

```
alice ALL=(root) /usr/bin/systemctl restart nginx
```

Alice peut uniquement redémarrer Nginx.

Elle ne devient pas administratrice complète.

---

## Principe du moindre privilège

Toujours donner le minimum de permissions nécessaires.

Mauvais exemple :

```
alice ALL=(ALL) ALL
```

Bon exemple :

```
alice ALL=(root) /usr/bin/systemctl restart nginx
```

---

## Le piège de NOPASSWD

Exemple :

```
alice ALL=(ALL) NOPASSWD: ALL
```

L'utilisateur devient root sans saisir de mot de passe.

Très pratique…

Très dangereux.

En cas de compromission du compte, l'attaquant obtient immédiatement les privilèges root.

NOPASSWD ne devrait être utilisé que pour quelques commandes précises.

---

# Authentication Hardening

## Authentification SSH

Par défaut, SSH accepte souvent :

- mot de passe
- clé publique

La méthode la plus sûre consiste à désactiver complètement les mots de passe.

Configuration :

```
/etc/ssh/sshd_config
```

Paramètres recommandés :

```
PasswordAuthentication no

PermitRootLogin no

PubkeyAuthentication yes
```

Puis :

```bash
sudo systemctl restart ssh
```

---

## Pourquoi utiliser les clés SSH

Une clé SSH est beaucoup plus difficile à voler qu'un mot de passe.

Avantages :

- résistance au brute force
- authentification forte
- aucun mot de passe transmis
- automatisation sécurisée

---

# PAM

PAM signifie :

**Pluggable Authentication Modules**

Il contrôle :

- les mots de passe
- les politiques de sécurité
- les limites de connexion
- les verrouillages de comptes

---

## Complexité des mots de passe

PAM peut imposer :

- longueur minimale
- majuscule
- minuscule
- chiffre
- caractère spécial

Exemple :

```
12 caractères minimum

1 chiffre

1 majuscule

1 caractère spécial
```

---

## Verrouillage des comptes

PAM peut bloquer un compte après plusieurs échecs.

Exemple :

```
5 tentatives

verrouillage pendant 15 minutes
```

Cela limite les attaques par force brute.

---

# Passwordless Onboarding

Créer un utilisateur sans mot de passe :

```bash
sudo useradd -m utilisateur
```

Puis :

```bash
sudo passwd -d utilisateur
```

ou ne jamais définir de mot de passe.

L'utilisateur ne peut alors pas se connecter avec un mot de passe.

Il devra utiliser :

- une clé SSH
- une authentification externe
- un autre mécanisme sécurisé

Ainsi, aucun mot de passe ne peut être volé.

---

# Bonnes pratiques

- Utiliser des UIDs uniques.
- Ne jamais créer un utilisateur avec UID 0.
- Les comptes système ne doivent pas avoir de shell interactif.
- Utiliser des clés SSH plutôt que des mots de passe.
- Modifier sudoers uniquement avec `visudo`.
- Respecter le principe du moindre privilège.
- Éviter `NOPASSWD` sauf nécessité absolue.
- Retirer les utilisateurs des groupes sensibles (`docker`, `disk`, `shadow`) lorsqu'ils n'en ont plus besoin.
- Utiliser PAM pour imposer des politiques de mots de passe robustes.
- Verrouiller automatiquement les comptes après plusieurs tentatives d'authentification échouées.
- Effectuer régulièrement un audit des comptes, des groupes et des permissions.

---

# Conclusion

La sécurité d'un système Linux repose en grande partie sur une gestion rigoureuse des identités et des privilèges. Comprendre le rôle des fichiers `/etc/passwd` et `/etc/shadow`, savoir attribuer les permissions avec précision, utiliser SSH de manière sécurisée et appliquer des politiques d'authentification robustes permet de réduire considérablement la surface d'attaque d'un serveur Linux.