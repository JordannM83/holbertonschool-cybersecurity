# Linux Process, Network & Log Analysis

## Introduction

Sous Linux, savoir analyser les **processus**, les **connexions réseau** et les **logs système** est essentiel pour l'administration système et la cybersécurité.

Ces compétences permettent notamment de :

- identifier un processus suspect ;
- déterminer quel utilisateur l'a lancé ;
- comprendre les relations entre processus ;
- arrêter ou suspendre un programme ;
- identifier les services qui écoutent sur le réseau ;
- associer un port réseau à un processus ;
- analyser les événements enregistrés par Linux ;
- corréler plusieurs informations lors d'une investigation.

---

# 1. Process Fundamentals

## 1.1 Qu'est-ce qu'un processus ?

Un **processus** est une instance d'un programme actuellement exécuté par le système.

Par exemple, lorsque l'on lance :

```bash
python3 server.py
```

Linux crée un processus pour exécuter Python.

Chaque processus possède plusieurs informations :

- un PID ;
- un PPID ;
- un propriétaire ;
- un état ;
- une consommation CPU ;
- une consommation mémoire ;
- des fichiers ouverts ;
- éventuellement des connexions réseau.

Pour afficher les processus :

```bash
ps aux
```

ou :

```bash
ps -ef
```

Pour une surveillance en temps réel :

```bash
top
```

---

# 2. PID et PPID

## PID

Le **PID (Process ID)** est un numéro unique attribué par Linux à chaque processus actif.

Exemple :

```text
USER       PID  COMMAND
root         1  systemd
delta     2458  bash
delta     2510  python3
```

Ici :

- `systemd` possède le PID `1`
- `bash` possède le PID `2458`
- `python3` possède le PID `2510`

Le PID permet ensuite de cibler précisément un processus.

Exemple :

```bash
kill 2510
```

---

## PPID

Le **PPID (Parent Process ID)** correspond au PID du processus ayant créé le processus actuel.

Les processus Linux forment donc une hiérarchie.

Exemple :

```text
systemd
└── sshd
    └── bash
        └── python3
```

On peut afficher le PID et le PPID avec :

```bash
ps -eo pid,ppid,user,state,cmd
```

On peut également visualiser l'arbre des processus :

```bash
pstree -p
```

Comprendre cette hiérarchie est particulièrement utile en cybersécurité.

Par exemple, un processus :

```text
apache2
└── bash
    └── nc
```

peut être suspect : un serveur web ne devrait généralement pas lancer spontanément un shell puis un outil réseau.

---

# 3. États des processus

Un processus peut avoir différents états.

## Running — R

Le processus est actuellement exécuté ou prêt à être exécuté par le CPU.

```text
R
```

---

## Sleeping — S

Le processus attend un événement.

Par exemple :

- une entrée utilisateur ;
- une connexion réseau ;
- une donnée provenant d'un fichier ;
- la fin d'un timer.

Un processus en état `S` n'est donc pas nécessairement problématique.

---

## Zombie — Z

Un processus zombie est un processus qui a terminé son exécution, mais dont le processus parent n'a pas encore récupéré son code de retour.

Son état apparaît comme :

```text
Z
```

ou parfois :

```text
<defunct>
```

Exemple :

```bash
ps aux | grep defunct
```

Un zombie ne consomme pratiquement plus de CPU ou de mémoire, mais conserve une entrée dans la table des processus.

Un grand nombre de zombies peut indiquer un programme parent mal conçu.

---

# 4. Le système de fichiers /proc

Linux expose de nombreuses informations sur le système et les processus à travers :

```text
/proc
```

`/proc` est un **pseudo-système de fichiers** : son contenu est principalement généré dynamiquement par le noyau.

Chaque processus possède généralement un dossier correspondant à son PID.

Exemple pour le PID 2458 :

```text
/proc/2458/
```

On peut y trouver différentes informations.

### Ligne de commande

```bash
cat /proc/2458/cmdline
```

### État du processus

```bash
cat /proc/2458/status
```

### Exécutable lancé

```bash
readlink /proc/2458/exe
```

### Répertoire courant

```bash
readlink /proc/2458/cwd
```

### Fichiers ouverts

```bash
ls -l /proc/2458/fd/
```

Les commandes comme `ps` utilisent notamment les informations exposées par le noyau via `/proc`.

Cela signifie que `/proc` peut être utilisé directement lors d'une investigation.

---

# 5. Process Ownership

Chaque processus possède un **propriétaire**.

Pour afficher l'utilisateur associé aux processus :

```bash
ps aux
```

ou plus précisément :

```bash
ps -eo user,pid,ppid,cmd
```

Exemple :

```text
USER       PID   PPID COMMAND
root         1      0 /sbin/init
www-data  1542      1 apache2
delta     2381   2300 python3 script.py
```

Cette information est importante car les permissions d'un processus dépendent généralement de l'utilisateur qui l'exécute.

Un processus exécuté par :

```text
root
```

possède potentiellement beaucoup plus de privilèges qu'un processus exécuté par :

```text
www-data
```

Lors d'une investigation, il faut donc se demander :

> Quel utilisateur exécute ce processus et est-ce normal ?

---

# 6. Signal Management

Linux utilise des **signaux** pour envoyer des instructions aux processus.

La commande principale est :

```bash
kill
```

Contrairement à son nom, `kill` ne signifie pas obligatoirement tuer un processus : elle permet d'envoyer un signal.

Pour afficher les signaux disponibles :

```bash
kill -l
```

---

# 7. SIGTERM vs SIGKILL

## SIGTERM

`SIGTERM` correspond au signal `15`.

```bash
kill -15 PID
```

ou simplement :

```bash
kill PID
```

SIGTERM demande au processus de se terminer proprement.

Le programme peut alors :

- fermer ses fichiers ;
- terminer ses connexions ;
- sauvegarder ses données ;
- libérer ses ressources.

C'est généralement le premier signal à utiliser.

---

## SIGKILL

`SIGKILL` correspond au signal `9`.

```bash
kill -9 PID
```

Le noyau arrête immédiatement le processus.

Le programme n'a pas la possibilité d'effectuer son nettoyage.

On utilise donc généralement :

```bash
kill PID
```

puis seulement si nécessaire :

```bash
kill -9 PID
```

Principe :

> **SIGTERM = demander au processus de s'arrêter.**

> **SIGKILL = forcer son arrêt.**

---

# 8. Signal handling

Un programme peut installer un **signal handler**, c'est-à-dire du code exécuté lorsqu'un signal particulier est reçu.

Un programme peut donc :

- traiter SIGTERM ;
- retarder son arrêt ;
- voire ignorer SIGTERM.

Cela peut également être utilisé par certains programmes malveillants pour rendre leur arrêt plus difficile.

En revanche, un processus ne peut pas intercepter ou ignorer :

```text
SIGKILL
```

Le signal est directement appliqué par le noyau.

C'est pourquoi :

```bash
kill -9 PID
```

peut arrêter un processus qui ignore SIGTERM.

---

# 9. SIGSTOP et SIGCONT

Il n'est pas toujours nécessaire de tuer immédiatement un processus suspect.

`SIGSTOP` permet de suspendre son exécution.

```bash
kill -STOP PID
```

Le processus reste présent mais ne continue plus son exécution.

On peut alors analyser :

- `/proc/PID/`
- ses fichiers ouverts ;
- son propriétaire ;
- son exécutable ;
- ses connexions réseau.

Pour reprendre son exécution :

```bash
kill -CONT PID
```

Cela est utile pendant une investigation lorsque l'on souhaite **geler un processus avant de l'analyser**.

---

# 10. Network Visibility

Un programme peut communiquer avec le réseau grâce à des **sockets**.

Une socket représente un point de communication réseau.

Pour analyser les connexions réseau Linux, on rencontre notamment les états :

```text
LISTEN
ESTABLISHED
TIME_WAIT
```

---

# 11. LISTEN

`LISTEN` signifie qu'un programme attend des connexions entrantes.

Par exemple :

```text
0.0.0.0:22
```

peut correspondre à un serveur SSH attendant des connexions sur le port 22.

Pour afficher les ports en écoute :

```bash
ss -lnt
```

---

# 12. ESTABLISHED

`ESTABLISHED` indique qu'une connexion TCP est actuellement établie entre deux machines.

Exemple :

```text
192.168.1.20:22    192.168.1.50:52144
```

Cela signifie qu'une communication TCP est active entre les deux systèmes.

Pendant une investigation, des connexions établies vers des IP inconnues peuvent nécessiter une analyse supplémentaire.

---

# 13. TIME_WAIT

`TIME_WAIT` apparaît après la fermeture d'une connexion TCP.

Le système conserve temporairement certaines informations afin d'éviter que d'anciens paquets soient confondus avec une nouvelle connexion utilisant les mêmes paramètres.

Voir plusieurs connexions en `TIME_WAIT` est donc généralement normal.

---

# 14. La commande ss

`ss` signifie **Socket Statistics**.

Elle est aujourd'hui couramment utilisée à la place de l'ancienne commande `netstat`.

Afficher les connexions TCP :

```bash
ss -t
```

Afficher les ports TCP en écoute :

```bash
ss -lt
```

Afficher les informations numériques :

```bash
ss -lnt
```

Afficher également les processus :

```bash
sudo ss -lntp
```

Les options importantes sont :

```text
-l    sockets en écoute
-t    TCP
-u    UDP
-n    ne pas résoudre les noms
-p    afficher les processus
```

Une commande très utile lors d'une investigation est donc :

```bash
sudo ss -tulpn
```

---

# 15. Port-to-Process Mapping

Il est important de pouvoir répondre à la question :

> Quel processus utilise ce port ?

Par exemple :

```bash
sudo ss -lntp
```

peut afficher :

```text
LISTEN 0 128 0.0.0.0:8080 users:(("python3",pid=4242,fd=3))
```

On apprend alors que :

```text
Port : 8080
Processus : python3
PID : 4242
```

On peut ensuite poursuivre l'analyse :

```bash
ps -fp 4242
```

puis :

```bash
readlink /proc/4242/exe
```

---

# 16. lsof

`lsof` signifie :

```text
List Open Files
```

Sous Linux, de nombreuses ressources sont représentées comme des fichiers, notamment certaines informations liées aux sockets.

Pour afficher les connexions réseau :

```bash
sudo lsof -i
```

Pour rechercher un port précis :

```bash
sudo lsof -i :8080
```

Exemple :

```text
COMMAND   PID USER   FD TYPE
python3  4242 delta   3u IPv4
```

On peut ainsi identifier rapidement le programme utilisant le port 8080.

---

# 17. Log Analysis

Les logs permettent de comprendre ce qui s'est produit sur un système.

Ils peuvent contenir des informations sur :

- les services ;
- les erreurs ;
- les authentifications ;
- le kernel ;
- les démarrages ;
- les périphériques ;
- certaines activités réseau.

Sous les distributions utilisant systemd, une partie importante des logs est gérée par :

```text
systemd-journald
```

---

# 18. journalctl

La commande principale pour interroger le journal systemd est :

```bash
journalctl
```

Afficher les logs :

```bash
journalctl
```

Afficher les logs récents :

```bash
journalctl -r
```

Afficher les logs d'un service :

```bash
journalctl -u ssh
```

Par exemple :

```bash
journalctl -u apache2
```

permet d'afficher les événements associés au service Apache.

---

# 19. Filtrer les logs par date

Les filtres temporels sont particulièrement importants pendant une investigation.

Exemple :

```bash
journalctl --since "2026-08-10 08:00:00"
```

On peut également utiliser :

```bash
journalctl --since "1 hour ago"
```

Ou définir une période :

```bash
journalctl \
    --since "2026-08-10 08:00:00" \
    --until "2026-08-10 09:00:00"
```

Cela permet de concentrer l'analyse autour de l'heure d'un incident.

---

# 20. Kernel Ring Buffer

Le noyau Linux possède un espace contenant des messages liés aux événements de bas niveau : le **kernel ring buffer**.

On peut notamment y trouver des informations concernant :

- le matériel ;
- les pilotes ;
- les périphériques USB ;
- le réseau ;
- la mémoire ;
- les disques ;
- certaines erreurs du kernel.

La commande historique pour consulter ces messages est :

```bash
dmesg
```

Exemple :

```bash
dmesg | tail
```

Avec systemd, on peut également consulter les messages kernel avec :

```bash
journalctl -k
```

Afficher uniquement ceux du démarrage actuel :

```bash
journalctl -k -b
```

---

# 21. Log Correlation

La **corrélation de logs** consiste à connecter plusieurs événements afin de reconstruire ce qui s'est produit.

Une seule information est rarement suffisante.

Imaginons que l'on découvre une connexion réseau suspecte.

### Étape 1 — Identifier la connexion

```bash
sudo ss -tulpn
```

Résultat :

```text
python3 pid=4242
```

---

### Étape 2 — Examiner le processus

```bash
ps -fp 4242
```

Puis :

```bash
cat /proc/4242/status
```

et :

```bash
readlink /proc/4242/exe
```

---

### Étape 3 — Identifier les fichiers ouverts

```bash
sudo lsof -p 4242
```

---

### Étape 4 — Examiner les logs autour de l'heure suspecte

```bash
journalctl --since "10 minutes ago"
```

---

### Étape 5 — Examiner les événements kernel si nécessaire

```bash
journalctl -k
```

On peut alors construire une chronologie :

```text
08:31 → lancement d'un processus
08:32 → ouverture d'un port
08:33 → connexion réseau
08:34 → erreur ou événement enregistré dans les logs
```

C'est cette mise en relation des événements que l'on appelle **log correlation**.

---

# 22. Méthodologie d'investigation

Lorsqu'un processus suspect est découvert, une méthode simple consiste à procéder dans cet ordre :

```text
Processus suspect
       │
       ▼
Identifier PID / PPID
       │
       ▼
Identifier le propriétaire
       │
       ▼
Examiner /proc/PID
       │
       ▼
Examiner les fichiers ouverts
       │
       ▼
Examiner les connexions réseau
       │
       ▼
Identifier les ports utilisés
       │
       ▼
Analyser les logs
       │
       ▼
Construire une chronologie
```

Quelques commandes particulièrement utiles :

```bash
ps aux
pstree -p
ps -eo pid,ppid,user,state,cmd

cat /proc/PID/status
readlink /proc/PID/exe
ls -l /proc/PID/fd

sudo ss -tulpn
sudo lsof -i
sudo lsof -p PID

journalctl
journalctl -u SERVICE
journalctl --since "1 hour ago"
journalctl -k

kill PID
kill -STOP PID
kill -CONT PID
kill -9 PID
```

---

# 23. Points essentiels à retenir

### Processus

- **PID** : identifiant unique du processus.
- **PPID** : identifiant de son processus parent.
- **R** : Running.
- **S** : Sleeping.
- **Z** : Zombie.
- `/proc/PID/` contient de nombreuses informations sur un processus.

### Signaux

- **SIGTERM (15)** : demande un arrêt propre.
- **SIGKILL (9)** : force l'arrêt.
- **SIGSTOP** : suspend le processus.
- **SIGCONT** : reprend son exécution.
- SIGTERM peut être intercepté ou ignoré.
- SIGKILL ne peut pas être intercepté par le processus.

### Réseau

- **LISTEN** : attente de connexions.
- **ESTABLISHED** : connexion active.
- **TIME_WAIT** : connexion TCP récemment fermée.
- `ss` permet d'inspecter les sockets.
- `lsof` permet notamment d'associer ports, fichiers et processus.

### Logs

- `journalctl` interroge les logs gérés par systemd-journald.
- `journalctl -u` filtre par service.
- `journalctl --since` permet une analyse temporelle.
- `dmesg` et `journalctl -k` donnent accès aux messages du kernel.
- La corrélation consiste à relier processus, réseau et logs pour reconstruire un événement.

---

# Conclusion

L'analyse d'un système Linux repose rarement sur une seule commande.

Un administrateur ou analyste sécurité doit être capable de relier plusieurs sources d'information :

```text
PID / PPID
    ↓
Utilisateur
    ↓
/proc
    ↓
Sockets / Ports
    ↓
ss / lsof
    ↓
journalctl
    ↓
Kernel logs
```

Cette approche permet de passer d'une simple observation — par exemple un port inconnu — à une véritable investigation permettant d'identifier **quel processus est responsable, quel utilisateur l'a lancé, ce qu'il fait et quels événements système lui sont associés**.