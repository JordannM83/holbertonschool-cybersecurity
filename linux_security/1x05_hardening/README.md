# Linux Security Automation & System Hardening

## Introduction

L’administration et la sécurisation d’un système Linux ne consistent pas seulement à exécuter manuellement des commandes.

Dans un environnement professionnel, les configurations doivent être :

- reproductibles ;
- vérifiables ;
- sécurisées ;
- automatisables ;
- faciles à maintenir.

Les scripts Bash permettent d’automatiser une grande partie de ces tâches. Cependant, un script de sécurité mal conçu peut lui-même devenir une source de vulnérabilités.

Ce projet permet d’aborder plusieurs concepts essentiels de l’administration et de la sécurité Linux : scripts Bash robustes, idempotence, gestion de configuration, durcissement système, PAM, SSH, conformité, audit, authentification et autorisation.

---

# 1. Scripting & Architecture

## 1.1 Pourquoi utiliser Bash ?

Bash est un shell très utilisé sur les systèmes Linux.

Il permet aussi d'écrire des scripts capables d'enchaîner automatiquement des commandes système.

Un script Bash commence généralement par :

```bash
#!/bin/bash
```

Cette ligne est appelée **shebang**.

Elle indique au système quel interpréteur doit être utilisé pour exécuter le script.

Un script peut par exemple :

```bash
#!/bin/bash

apt-get update
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
```

L'intérêt principal est la reproductibilité : plutôt que d'exécuter manuellement plusieurs commandes sur chaque machine, on peut exécuter le même script.

---

# 2. Écrire des scripts Bash robustes

Un script robuste doit anticiper les erreurs et les situations inattendues.

Une pratique fréquente consiste à utiliser :

```bash
set -euo pipefail
```

Ces options rendent Bash plus strict.

`-e` demande au script de s'arrêter lorsqu'une commande retourne une erreur.

`-u` provoque une erreur lorsqu'une variable inexistante est utilisée.

`pipefail` permet de détecter une erreur dans n'importe quelle commande d'un pipeline.

Par exemple :

```bash
cat fichier.txt | grep "password"
```

Avec `pipefail`, une erreur provenant de `cat` peut également provoquer l'échec du pipeline.

Il est également important de protéger les variables avec des guillemets :

```bash
rm "$file"
```

plutôt que :

```bash
rm $file
```

Cela évite notamment les problèmes avec les espaces et certains caractères spéciaux.

---

# 3. Scripts modulaires

Un script devient rapidement difficile à maintenir lorsque toutes les commandes sont placées les unes après les autres.

Les fonctions permettent de séparer les responsabilités.

Exemple :

```bash
check_service() {
    systemctl is-active --quiet "$1"
}

restart_service() {
    systemctl restart "$1"
}
```

On peut ensuite écrire :

```bash
if check_service "ssh"; then
    echo "SSH fonctionne"
else
    restart_service "ssh"
fi
```

Chaque fonction possède une responsabilité précise.

Cette approche facilite :

- la lecture ;
- les tests ;
- la maintenance ;
- la réutilisation du code.

---

# 4. Variables locales

Dans une fonction Bash, `local` permet de créer une variable limitée à cette fonction.

```bash
check_service() {
    local service="$1"

    systemctl is-active "$service"
}
```

Sans `local`, une variable peut modifier accidentellement une variable portant le même nom ailleurs dans le script.

Par exemple :

```bash
status="UNKNOWN"

check_service() {
    local status="OK"
}
```

Après l'exécution de la fonction, la variable globale `status` contient toujours :

```text
UNKNOWN
```

Les variables locales permettent donc de limiter les effets de bord entre les différentes parties du script.

---

# 5. Idempotence

L'idempotence est un concept fondamental de l'automatisation.

Une opération est **idempotente** lorsque son exécution répétée produit toujours le même état final.

Par exemple :

```bash
mkdir /shared
```

peut échouer si `/shared` existe déjà.

Une meilleure version est :

```bash
mkdir -p /shared
```

La commande fonctionne que le dossier existe déjà ou non.

Autre exemple :

```bash
if ! id "sentinel" >/dev/null 2>&1; then
    useradd sentinel
fi
```

Le script vérifie l'état actuel du système avant de réaliser une modification.

Un script de configuration devrait donc généralement suivre la logique :

```text
Vérifier l'état actuel
        ↓
Est-il conforme ?
   ↓           ↓
  Oui         Non
   ↓           ↓
Ne rien     Corriger
faire
```

Cela permet d'exécuter le script plusieurs fois sans casser ou dupliquer la configuration.

---

# 6. Configuration Management et scripts ad-hoc

Un script **ad-hoc** est généralement créé pour résoudre rapidement un problème particulier.

Par exemple :

```bash
systemctl restart apache2
```

ou :

```bash
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
```

Cela peut fonctionner pour quelques machines mais devient difficile à gérer à grande échelle.

Le **Configuration Management** cherche plutôt à définir l'état souhaité d'un système.

Des outils comme Ansible, Puppet, Chef ou Salt peuvent par exemple définir :

```text
SSH doit être installé
SSH doit être actif
Root Login doit être désactivé
Le port 22 doit être autorisé
```

L'outil compare ensuite l'état actuel avec l'état souhaité et applique les corrections nécessaires.

On peut résumer la différence ainsi :

```text
Ad-hoc scripting
"Exécute cette commande"

Configuration Management
"Assure-toi que le système est dans cet état"
```

---

# 7. Pourquoi éviter les valeurs hardcodées ?

Le hardcoding consiste à écrire directement une valeur dans le code.

Exemple :

```bash
PASSWORD="Admin123!"
SERVER="192.168.1.50"
USER="administrator"
```

Cela pose plusieurs problèmes.

Si le script est envoyé sur GitHub, un mot de passe ou une clé API peut devenir publiquement accessible.

Même après suppression, le secret peut rester présent dans l'historique Git.

Les valeurs hardcodées rendent également les scripts moins réutilisables.

Il est préférable d'utiliser des arguments :

```bash
SERVER="$1"
USER="$2"
```

puis :

```bash
./script.sh 192.168.1.50 administrator
```

Pour les secrets, on peut utiliser des variables d'environnement ou des solutions spécialisées de gestion de secrets.

Principe important :

> Les secrets ne doivent pas être stockés directement dans le code source.

---

# 8. System Hardening

Le **System Hardening**, ou durcissement système, consiste à réduire la surface d'attaque d'un système.

Cela peut inclure :

- désactiver les services inutiles ;
- fermer les ports inutiles ;
- renforcer SSH ;
- appliquer une politique de mot de passe ;
- limiter les privilèges ;
- protéger les fichiers sensibles ;
- installer les mises à jour de sécurité ;
- surveiller les modifications importantes.

L'objectif est de réduire les possibilités disponibles pour un attaquant.

---

# 9. Automatiser les modifications réseau en sécurité

Les modifications réseau sont particulièrement sensibles lorsqu'un serveur est administré à distance.

Une mauvaise règle firewall peut immédiatement couper la connexion SSH de l'administrateur.

Par exemple, appliquer directement :

```bash
ufw default deny incoming
```

sans avoir autorisé SSH peut provoquer un verrouillage.

Il faut donc préparer les accès nécessaires **avant** d'appliquer les restrictions.

Par exemple :

```bash
ufw allow 22/tcp
ufw default deny incoming
ufw enable
```

Mais même cela doit être adapté à l'environnement réel : SSH n'utilise pas nécessairement le port 22.

Une automatisation réseau sûre doit généralement :

1. identifier la configuration actuelle ;
2. sauvegarder la configuration ;
3. autoriser les accès administratifs nécessaires ;
4. valider la nouvelle configuration ;
5. appliquer les restrictions ;
6. vérifier que le service reste accessible.

Il est également préférable de conserver une session administrateur ouverte pendant les tests lorsqu'une configuration distante est modifiée.

---

# 10. PAM

PAM signifie :

**Pluggable Authentication Modules**

PAM fournit une architecture commune permettant aux applications Linux de gérer l'authentification.

Différents services peuvent utiliser PAM :

```text
login
sudo
su
sshd
passwd
```

Les fichiers de configuration se trouvent principalement dans :

```text
/etc/pam.d/
```

Par exemple :

```text
/etc/pam.d/common-password
```

peut intervenir dans la politique de création des mots de passe.

---

# 11. Politique de mot de passe avec PAM

Le module `pam_pwquality` permet d'imposer certaines règles sur les nouveaux mots de passe.

Le paquet correspondant peut être installé avec :

```bash
apt-get install -y libpam-pwquality
```

Une politique peut imposer par exemple :

- une longueur minimale ;
- des majuscules ;
- des minuscules ;
- des chiffres ;
- des caractères spéciaux.

Une configuration peut utiliser :

```text
minlen=12
minclass=3
```

`minlen=12` impose une longueur minimale de 12 caractères.

`minclass=3` demande l'utilisation d'au moins trois catégories de caractères.

Une politique de mot de passe ne suffit cependant pas à sécuriser complètement un système.

Elle doit être accompagnée d'autres contrôles comme la limitation des privilèges, la protection des fichiers sensibles et, lorsque cela est approprié, l'authentification multifacteur.

---

# 12. Sécurisation de SSH

SSH permet d'administrer une machine distante de manière chiffrée.

Sa configuration principale se trouve généralement dans :

```text
/etc/ssh/sshd_config
```

Un serveur SSH exposé doit être correctement sécurisé.

Parmi les contrôles possibles :

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Ces paramètres permettent respectivement de :

- empêcher la connexion directe de `root` ;
- désactiver l'authentification par mot de passe ;
- autoriser l'authentification par clé publique.

---

# 13. Authentification SSH par clé uniquement

Une paire de clés SSH possède deux parties :

```text
Clé privée
Clé publique
```

La clé privée reste sur la machine du client et doit être protégée.

La clé publique peut être installée sur le serveur dans :

```text
~/.ssh/authorized_keys
```

Le serveur peut alors vérifier que le client possède réellement la clé privée correspondante.

Une fois l'authentification par clé correctement testée, on peut envisager de désactiver les mots de passe :

```text
PasswordAuthentication no
```

Il est dangereux de désactiver les mots de passe **avant d'avoir vérifié que l'authentification par clé fonctionne**, car cela peut empêcher toute nouvelle connexion au serveur.

Avant de redémarrer SSH, il faut également vérifier la configuration.

Par exemple :

```bash
sshd -t
```

Si la configuration est valide, le service peut ensuite être rechargé ou redémarré selon le système.

---

# 14. Security Policy et Technical Controls

Une politique de sécurité décrit les règles que l'organisation souhaite faire respecter.

Par exemple :

> Les utilisateurs doivent utiliser des mots de passe d'au moins 12 caractères.

Cette règle humaine doit être transformée en contrôle technique.

Par exemple :

```text
Politique
   ↓
Mot de passe >= 12 caractères
   ↓
Contrôle technique
   ↓
PAM / pam_pwquality
   ↓
minlen=12
```

Autre exemple :

```text
Politique :
Les administrateurs doivent utiliser des clés SSH.

Contrôle :
PasswordAuthentication no
PubkeyAuthentication yes
```

Le travail d'un administrateur ou d'un ingénieur sécurité consiste donc souvent à transformer des exigences de sécurité en configurations techniques vérifiables.

---

# 15. Compliance

La **compliance**, ou conformité, consiste à vérifier qu'un système respecte les règles définies.

Un script peut par exemple vérifier :

```bash
grep "^PasswordAuthentication no" /etc/ssh/sshd_config
```

Mais une bonne vérification de conformité doit produire un résultat compréhensible et exploitable.

Par exemple :

```text
CONTROL: SSH_PASSWORD_AUTH
EXPECTED: disabled
ACTUAL: disabled
STATUS: COMPLIANT
```

Un autre système pourrait produire :

```text
STATUS: NON_COMPLIANT
```

La conformité repose donc sur trois étapes :

```text
Politique
    ↓
Contrôle technique
    ↓
Vérification
    ↓
Preuve
```

---

# 16. Audit Reports

Un audit doit pouvoir prouver l'état d'un système à un instant donné.

Un rapport peut contenir :

- la date du contrôle ;
- la machine concernée ;
- le contrôle effectué ;
- la valeur attendue ;
- la valeur observée ;
- le résultat ;
- les éventuelles corrections réalisées.

Par exemple :

```text
SSH Root Login: DISABLED
Password Authentication: DISABLED
Firewall: ENABLED
Password Minimum Length: 12
```

Pour permettre une exploitation automatique, les résultats peuvent être générés en JSON.

Exemple :

```json
{
  "timestamp": "2026-08-12T13:00:00Z",
  "component": "SERVICE",
  "target": "ssh",
  "status": "OK",
  "details": "Service is running"
}
```

Un système comme Splunk peut ensuite ingérer ces événements et permettre leur recherche, leur corrélation et leur visualisation.

---

# 17. Logs structurés

Les logs texte classiques peuvent être difficiles à analyser automatiquement.

Par exemple :

```text
SSH service restarted successfully
```

Le programme qui analyse cette ligne doit comprendre sa structure.

Un log JSON possède au contraire des champs clairement identifiés :

```json
{
  "component": "SERVICE",
  "target": "ssh",
  "status": "FIXED"
}
```

Chaque information possède une clé.

Une fonction Bash peut centraliser la génération des logs :

```bash
log() {
    local component="$1"
    local target="$2"
    local status="$3"
    local details="$4"
    local timestamp

    timestamp=$(date -u +%FT%TZ)

    echo "{\"timestamp\":\"$timestamp\",\"component\":\"$component\",\"target\":\"$target\",\"status\":\"$status\",\"details\":\"$details\"}" >> "$LOG_FILE"
}
```

Puis être utilisée ainsi :

```bash
log "SERVICE" "ssh" "OK" "Service is running"
```

Centraliser les logs dans une fonction évite de répéter la logique dans tout le script.

---

# 18. Authentication — AuthN

L'**Authentication**, souvent abrégée **AuthN**, répond à la question :

> Qui es-tu ?

Le système cherche à vérifier l'identité de l'utilisateur.

Exemples :

```text
mot de passe
clé SSH
certificat
token
biométrie
MFA
```

Lorsqu'un utilisateur se connecte avec une clé SSH valide, le système réalise une opération d'authentification.

---

# 19. Authorization — AuthZ

L'**Authorization**, abrégée **AuthZ**, répond à une autre question :

> Qu'as-tu le droit de faire ?

L'utilisateur peut être correctement authentifié tout en n'ayant pas les permissions nécessaires pour effectuer une action.

Par exemple :

```bash
alice$ cat /etc/shadow
cat: /etc/shadow: Permission denied
```

Alice est connectée au système.

Son authentification a donc réussi :

```text
AuthN → SUCCESS
```

Mais elle n'a pas le droit de lire `/etc/shadow` :

```text
AuthZ → DENIED
```

---

# 20. AuthN vs AuthZ

La différence peut être résumée simplement :

```text
Authentication (AuthN)
        ↓
"Qui es-tu ?"
        ↓
Vérification de l'identité


Authorization (AuthZ)
        ↓
"Que peux-tu faire ?"
        ↓
Vérification des permissions
```

Exemple avec SSH :

```text
Utilisateur
    ↓
Clé SSH valide
    ↓
AUTHENTICATION réussie
    ↓
Utilisateur connecté
    ↓
sudo systemctl restart apache2
    ↓
Vérification sudoers
    ↓
AUTHORIZATION
```

Un utilisateur peut donc réussir son authentification mais échouer à l'autorisation.

---

# 21. Principe du moindre privilège

L'autorisation est étroitement liée au **Principle of Least Privilege**.

Un utilisateur ne devrait posséder que les permissions nécessaires à son travail.

Une règle comme :

```text
junior ALL=(ALL) NOPASSWD: ALL
```

accorde énormément de privilèges.

Si le compte `junior` est compromis, l'attaquant peut potentiellement obtenir immédiatement les privilèges root.

Il est préférable de limiter les commandes :

```text
junior ALL=(root) /usr/bin/systemctl restart apache2, /usr/bin/journalctl
```

L'utilisateur possède alors uniquement les permissions nécessaires.

---

# 22. Architecture générale d'une automatisation de sécurité

Un bon script de hardening ne devrait pas simplement modifier aveuglément le système.

Une architecture plus robuste est :

```text
        Security Policy
               │
               ▼
        Vérification
               │
        ┌──────┴──────┐
        │             │
    Conforme      Non conforme
        │             │
        │             ▼
        │         Correction
        │             │
        └──────┬──────┘
               ▼
          Vérification
               │
               ▼
             Logs
               │
               ▼
        Rapport d'audit
```

Cette logique rend les scripts plus sûrs, plus faciles à maintenir et plus adaptés à un environnement professionnel.

---

# Conclusion

L'automatisation de la sécurité Linux nécessite plus que la connaissance de quelques commandes Bash.

Un bon script doit être **robuste**, **modulaire** et **idempotent** afin de pouvoir être exécuté plusieurs fois sans provoquer d'effets indésirables.

Le durcissement d'un système nécessite également de comprendre les conséquences des modifications réalisées, particulièrement pour SSH, PAM et les règles réseau.

Une politique de sécurité doit pouvoir être transformée en contrôles techniques mesurables puis vérifiée grâce à des mécanismes d'audit et de journalisation.

Enfin, il est essentiel de distinguer :

```text
AuthN → Qui es-tu ?

AuthZ → Qu'as-tu le droit de faire ?
```

Ces principes constituent les bases nécessaires pour automatiser correctement la configuration, le durcissement et la vérification de systèmes Linux.