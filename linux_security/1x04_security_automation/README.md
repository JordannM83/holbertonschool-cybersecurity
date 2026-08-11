# Linux Automation & System Management

## Introduction

L'administration d'un système Linux ne consiste pas seulement à exécuter des commandes manuellement. Lorsqu'une action doit être répétée sur plusieurs machines ou régulièrement, il est préférable de l'automatiser avec des scripts.

Un bon script d'administration doit être :

- lisible ;
- modulaire ;
- réutilisable ;
- sûr à exécuter plusieurs fois ;
- capable de signaler ses erreurs ;
- configurable sans modifier son code ;
- capable de produire des logs exploitables.

Ce projet introduit plusieurs concepts importants : l'architecture des scripts, l'idempotence, les codes de sortie, les fichiers de configuration, `systemd` et les logs structurés.

---

# 1. Scripting Architecture

## Modular Design

Un script simple peut contenir toutes ses instructions les unes après les autres :

```bash
#!/bin/bash

mkdir /backup
cp /etc/ssh/sshd_config /backup/
chmod 600 /backup/sshd_config
```

Cela fonctionne pour un petit script, mais devient difficile à maintenir lorsque le projet grandit.

Une meilleure approche consiste à utiliser des fonctions :

```bash
#!/bin/bash

create_backup_directory() {
    mkdir -p /backup
}

backup_config() {
    cp /etc/ssh/sshd_config /backup/
}

set_permissions() {
    chmod 600 /backup/sshd_config
}

create_backup_directory
backup_config
set_permissions
```

Chaque fonction possède une responsabilité précise.

Cette organisation facilite :

- la lecture ;
- le débogage ;
- les modifications ;
- la réutilisation du code.

On parle de **modular design**.

---

# 2. Separate Configuration Files

Il est préférable de séparer le **code** des **données de configuration**.

Au lieu d'écrire directement :

```bash
BACKUP_DIR="/backup"
LOG_FILE="/var/log/security.log"
```

dans le script, on peut créer :

```text
config.conf
```

contenant :

```bash
BACKUP_DIR="/backup"
LOG_FILE="/var/log/security.log"
```

Puis charger la configuration :

```bash
source config.conf
```

Le script peut ensuite utiliser :

```bash
echo "Backup directory: $BACKUP_DIR"
```

L'avantage est que l'on peut changer la configuration sans modifier le fonctionnement du script.

On sépare donc :

```text
Code
  ↓
script.sh

Configuration
  ↓
config.conf
```

---

# 3. Idempotence

L'**idempotence** signifie qu'un script peut être exécuté plusieurs fois sans provoquer de résultat incorrect ou indésirable.

Par exemple :

```bash
mkdir /backup
```

peut produire une erreur si `/backup` existe déjà.

Une version plus sûre est :

```bash
mkdir -p /backup
```

Avec `-p`, le répertoire est créé uniquement si nécessaire.

Autre exemple :

```bash
echo "admin ALL=(ALL) ALL" >> /etc/sudoers
```

À chaque exécution, la même ligne est ajoutée.

Après trois exécutions :

```text
admin ALL=(ALL) ALL
admin ALL=(ALL) ALL
admin ALL=(ALL) ALL
```

Une approche idempotente vérifie d'abord l'état :

```bash
grep -q "admin ALL=(ALL) ALL" /etc/sudoers ||
echo "admin ALL=(ALL) ALL" >> /etc/sudoers
```

Le principe est donc :

> Vérifier l'état actuel avant d'effectuer une modification.

Les scripts d'administration doivent être idempotents car ils peuvent être exécutés automatiquement ou plusieurs fois.

---

# 4. Exit Codes

Chaque commande Linux retourne un **exit code**.

On peut consulter celui de la dernière commande avec :

```bash
echo $?
```

Par convention :

```text
0       = succès
1-255   = erreur ou situation particulière
```

Exemple :

```bash
grep "root" /etc/passwd

echo $?
```

Si `root` est trouvé :

```text
0
```

Sinon `grep` retourne généralement :

```text
1
```

---

# 5. Exit Codes and Control Flow

Les codes de sortie peuvent contrôler le comportement d'un script.

Exemple :

```bash
if grep -q "root" /etc/passwd; then
    echo "User found"
else
    echo "User not found"
fi
```

`if` vérifie directement le code de sortie de `grep`.

On peut également arrêter volontairement un script :

```bash
if [ ! -f "/etc/myapp.conf" ]; then
    echo "Configuration missing"
    exit 1
fi

exit 0
```

Cela permet également à d'autres programmes de savoir si notre script a réussi.

---

# 6. Configuration Management

La **configuration management** consiste à définir comment un système doit être configuré et à s'assurer qu'il reste dans cet état.

Par exemple, on souhaite :

```text
SSH activé
Port SSH = 22
Permissions = 600
Service ssh = running
```

Le script ne doit pas seulement modifier le système une fois.

Il doit vérifier que l'état actuel correspond à l'état souhaité.

---

# 7. State Enforcement vs One-Time Fix

Un **one-time fix** effectue simplement une modification :

```bash
chmod 600 /etc/ssh/sshd_config
```

Un système de **state enforcement** vérifie l'état et le corrige si nécessaire :

```bash
if [ "$(stat -c %a /etc/ssh/sshd_config)" != "600" ]; then
    chmod 600 /etc/ssh/sshd_config
fi
```

On passe donc de :

```text
Effectuer une action
```

à :

```text
État souhaité
      ↓
Vérifier l'état actuel
      ↓
Correct ?
 /          \
Oui         Non
 |           |
rien      corriger
```

Cette logique est utilisée par des outils de configuration comme Ansible, Puppet ou Chef.

---

# 8. Golden Copies

Une **golden copy** est une copie considérée comme correcte et fiable d'un fichier important.

Par exemple :

```text
/etc/ssh/sshd_config
```

peut avoir une copie de référence :

```text
/opt/golden/sshd_config
```

On peut comparer les fichiers :

```bash
diff /etc/ssh/sshd_config /opt/golden/sshd_config
```

S'ils sont différents, cela peut indiquer :

- une modification administrative ;
- une erreur ;
- une mauvaise configuration ;
- une modification malveillante.

---

# 9. Integrity Verification

Pour vérifier l'intégrité d'un fichier, on peut utiliser un hash.

Par exemple :

```bash
sha256sum /etc/ssh/sshd_config
```

Résultat :

```text
a2c45...  /etc/ssh/sshd_config
```

On peut enregistrer un hash de référence :

```bash
sha256sum /etc/ssh/sshd_config > sshd.sha256
```

Puis vérifier plus tard :

```bash
sha256sum -c sshd.sha256
```

Si le fichier n'a pas changé :

```text
/etc/ssh/sshd_config: OK
```

Une différence de hash indique que le contenu du fichier a changé.

---

# 10. Systemd

`systemd` est le système d'initialisation et de gestion des services utilisé par de nombreuses distributions Linux.

Il permet notamment de :

- démarrer des services ;
- arrêter des services ;
- redémarrer des services ;
- lancer des scripts automatiquement ;
- gérer des dépendances ;
- planifier des tâches ;
- centraliser les logs.

Les configurations systemd sont appelées des **units**.

---

# 11. Service Units

Une unité `.service` indique à systemd **quoi exécuter**.

Exemple :

```ini
[Unit]
Description=Security monitoring script

[Service]
Type=oneshot
ExecStart=/usr/local/bin/security-check.sh
```

Elle peut être enregistrée sous :

```text
/etc/systemd/system/security-check.service
```

Puis exécutée avec :

```bash
systemctl start security-check.service
```

Pour consulter son état :

```bash
systemctl status security-check.service
```

---

# 12. Timer Units

Une unité `.timer` permet de déterminer **quand exécuter** une tâche.

Exemple :

```ini
[Unit]
Description=Run security check every hour

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
```

Le timer peut ensuite être activé :

```bash
systemctl enable --now security-check.timer
```

Pour afficher les timers :

```bash
systemctl list-timers
```

La logique est :

```text
security-check.timer
        |
        | déclenche
        v
security-check.service
        |
        | exécute
        v
security-check.sh
```

Le `.service` définit donc **quoi faire**, tandis que le `.timer` définit **quand le faire**.

---

# 13. Systemd Timer vs Cron

`cron` permet également de planifier des tâches :

```text
0 * * * * /usr/local/bin/security-check.sh
```

Mais systemd offre plusieurs avantages.

Il peut gérer les dépendances :

```ini
After=network.target
```

Il peut également gérer plus facilement les logs grâce au journal systemd.

Par exemple :

```bash
journalctl -u security-check.service
```

On peut suivre les logs en temps réel :

```bash
journalctl -u security-check.service -f
```

Les timers systemd sont donc particulièrement intéressants pour les scripts directement liés à l'administration du système.

---

# 14. Structured Logging

Un script classique peut produire :

```text
SSH attack detected
```

Ce message est lisible par un humain, mais contient peu d'informations structurées.

Un log JSON peut être :

```json
{
  "timestamp": "2026-08-11T09:00:00+02:00",
  "level": "WARNING",
  "event": "ssh_attack",
  "source": "192.168.1.50"
}
```

Chaque information possède un champ clairement identifiable.

C'est ce qu'on appelle du **structured logging**.

---

# 15. JSON and SIEM

Les SIEM (**Security Information and Event Management**) collectent et analysent des événements provenant de nombreux systèmes.

Des outils de sécurité peuvent facilement analyser un log JSON :

```json
{
  "level": "ERROR",
  "service": "sshd",
  "event": "authentication_failure"
}
```

Ils peuvent par exemple rechercher :

```text
level = ERROR
```

ou :

```text
service = sshd
```

Les logs structurés facilitent donc :

- la recherche ;
- le filtrage ;
- les alertes ;
- les statistiques ;
- la corrélation d'événements.

---

# 16. Timestamp Formatting

Les timestamps sont essentiels pour savoir **quand un événement s'est produit**.

Un format très utilisé est ISO 8601 :

```text
2026-08-11T09:15:32+02:00
```

En Bash :

```bash
date --iso-8601=seconds
```

ou, pour un horodatage UTC :

```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Exemple :

```text
2026-08-11T07:15:32Z
```

`Z` signifie ici UTC.

Utiliser des timestamps cohérents permet de corréler des événements provenant de plusieurs machines.

Par exemple :

```text
09:15:01 → Failed SSH login
09:15:03 → sudo attempt
09:15:05 → configuration modified
```

On peut alors reconstruire la chronologie d'une attaque.

---

# 17. Log Levels

Tous les événements n'ont pas la même importance.

On utilise donc des **log levels**.

Les niveaux courants sont :

```text
DEBUG     Informations détaillées pour le débogage
INFO      Fonctionnement normal
WARNING   Situation anormale ou suspecte
ERROR     Une opération a échoué
CRITICAL  Problème grave nécessitant une intervention
```

Exemple :

```json
{"level":"INFO","message":"Security scan started"}
```

```json
{"level":"WARNING","message":"Multiple SSH failures detected"}
```

```json
{"level":"CRITICAL","message":"System file integrity compromised"}
```

Cela permet à un SIEM ou à un administrateur de prioriser les événements.

---

# 18. Categorization

En plus du niveau, les logs peuvent être classés par catégorie.

Exemple :

```json
{
  "timestamp": "2026-08-11T07:30:00Z",
  "level": "WARNING",
  "category": "authentication",
  "event": "ssh_failed_login",
  "user": "root"
}
```

La catégorie pourrait être :

```text
authentication
network
filesystem
process
malware
configuration
```

On distingue donc :

```text
level    → gravité
category → type d'événement
```

Par exemple :

```text
WARNING + authentication
CRITICAL + filesystem
INFO + network
```

---

# 19. Complete Architecture

Tous les concepts peuvent être combinés dans une architecture d'automatisation :

```text
config.conf
     |
     v
security-check.sh
     |
     +---- functions
     |
     +---- state enforcement
     |
     +---- integrity verification
     |
     +---- exit codes
     |
     v
JSON logs
     |
     v
SIEM


systemd timer
     |
     v
systemd service
     |
     v
security-check.sh
```

Le fichier de configuration contient les paramètres.

Le script applique l'état souhaité et vérifie l'intégrité du système.

Le service systemd définit comment exécuter le script.

Le timer systemd définit quand l'exécuter.

Les résultats sont produits sous forme de logs structurés pouvant être analysés par un SIEM.

---

# Conclusion

Les scripts d'administration doivent être conçus comme de véritables outils et pas simplement comme une