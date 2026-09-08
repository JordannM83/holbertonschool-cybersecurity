# Consulting, Technical Assessment & Security Architecture

## Introduction

Dans un projet de cybersécurité professionnel, la technique seule ne suffit pas.

Un ingénieur sécurité, un administrateur système ou un consultant doit être capable de :

- comprendre les besoins d'une entreprise ;
- analyser une infrastructure existante ;
- identifier les risques ;
- proposer une architecture réaliste ;
- justifier ses choix ;
- appliquer les changements sans casser la production ;
- prouver que les mesures de sécurité fonctionnent réellement.

Ce type de mission suit généralement une logique proche de :

```text
Business Requirements
        ↓
Current State Assessment
        ↓
Gap Analysis
        ↓
Risk Analysis
        ↓
Target Architecture
        ↓
Implementation
        ↓
Validation
        ↓
Documentation
```

L'objectif de ce cours est de comprendre chacune de ces étapes.

---

# 1. Consulting Skills

## 1.1 Translate Business Requirements into Technical Specifications

Une entreprise exprime rarement ses besoins directement sous forme de règles firewall ou de configuration Linux.

Elle dira plutôt :

```text
Les employés doivent pouvoir accéder au serveur depuis l'extérieur.
```

ou :

```text
Les données financières doivent être protégées.
```

ou encore :

```text
Le serveur FTP existant doit continuer de fonctionner.
```

Le rôle du consultant consiste à transformer ces besoins métiers en exigences techniques.

---

## Exemple

### Besoin métier

```text
Les administrateurs doivent pouvoir gérer les serveurs à distance.
```

Ce besoin doit être précisé.

Questions à poser :

- depuis où ?
- depuis quels appareils ?
- avec quel niveau d'authentification ?
- quels serveurs ?
- quels ports ?
- quels utilisateurs ?
- faut-il conserver des logs ?

Une spécification technique pourrait devenir :

```text
Remote administration must only be accessible through the corporate VPN.

SSH access must only be allowed from the VPN subnet.

Password authentication must be disabled.

SSH authentication must use public keys.

All administrative connections must be logged.
```

---

## Exemple de transformation

| Besoin métier | Spécification technique |
|---|---|
| Accès distant sécurisé | VPN obligatoire |
| Administration serveurs | SSH |
| Réduction des attaques | SSH inaccessible depuis Internet |
| Traçabilité | logs SSH |
| Authentification forte | clés SSH |

---

## Une bonne spécification doit être

### Claire

Éviter :

```text
Secure SSH.
```

Préférer :

```text
Allow TCP/22 only from 10.10.0.0/24.
```

### Mesurable

Une exigence doit pouvoir être vérifiée.

Exemple :

```text
FTP must not be accessible from the public Internet.
```

On pourra ensuite tester :

```bash
nmap -p 21 SERVER_IP
```

### Réaliste

Une solution parfaitement sécurisée mais impossible à utiliser n'est pas une bonne solution.

---

# 2. Gap Analysis

Une **Gap Analysis** consiste à comparer :

```text
Current State
```

avec :

```text
Target State
```

Le but est d'identifier ce qu'il manque pour atteindre l'état souhaité.

---

## Exemple

### Current State

```text
SSH accessible from Internet
FTP accessible from Internet
No firewall
Shared administrator password
No VPN
```

### Target State

```text
Default-deny firewall
SSH accessible only through VPN
FTP isolated
Individual administrator accounts
Centralized logging
```

---

## Gap Analysis

| Control | Current | Target | Gap |
|---|---|---|---|
| Firewall | absent | default deny | firewall required |
| SSH | public | VPN only | restrict source |
| FTP | public | internal only | segmentation |
| Authentication | shared password | individual accounts | IAM changes |
| Logs | local only | centralized | log forwarding |

---

# 3. Prioritiser les écarts

Tous les problèmes ne présentent pas le même niveau de risque.

On peut utiliser :

```text
Risk = Likelihood × Impact
```

Exemple :

| Risque | Probabilité | Impact | Priorité |
|---|---|---|---|
| SSH public | élevée | élevée | critique |
| FTP interne | moyenne | élevée | haute |
| banner disclosure | moyenne | faible | basse |
| logs incomplets | moyenne | moyenne | moyenne |

Une entreprise corrige généralement les risques les plus importants en premier.

---

# 4. Security vs Practical Constraints

Une architecture de sécurité parfaite n'existe pas.

Il faut toujours équilibrer :

```text
Security
Usability
Cost
Performance
Compatibility
Operations
```

---

## Exemple : FTP

D'un point de vue sécurité :

```text
FTP should be removed.
```

Car FTP :

- transmet les identifiants en clair ;
- transmet les données en clair ;
- utilise plusieurs connexions ;
- est difficile à filtrer correctement ;
- est ancien.

Mais l'entreprise peut répondre :

```text
Our production equipment only supports FTP.
```

La suppression immédiate devient alors impossible.

La bonne approche consiste à réduire le risque.

---

## Exemple de compromis

Au lieu de :

```text
Internet → FTP server
```

On peut faire :

```text
Internet
   |
 Firewall
   |
 VPN
   |
 Internal Network
   |
 FTP Server
```

Ainsi :

```text
FTP reste utilisé
```

mais uniquement à l'intérieur d'un tunnel chiffré.

---

# 5. Compensating Controls

Lorsqu'une technologie vulnérable ne peut pas être remplacée, on utilise des **compensating controls**.

Exemple avec FTP :

```text
Legacy FTP required
```

Mesures compensatoires :

- accès uniquement par VPN ;
- filtrage firewall ;
- réseau isolé ;
- comptes dédiés ;
- permissions minimales ;
- monitoring ;
- logs ;
- restrictions IP.

Le risque n'est pas supprimé, mais fortement réduit.

---

# 6. Defending Technical Decisions

Un consultant doit pouvoir expliquer ses choix à des personnes non techniques.

Dire :

```text
We implemented nftables with stateful filtering.
```

n'est pas toujours utile pour un directeur.

Il vaut mieux expliquer l'impact.

---

## Exemple

### Explication technique

```text
Inbound connections are denied by default except TCP/22 from the VPN subnet.
```

### Explication métier

```text
Servers are no longer directly administrable from the Internet.

An attacker must first gain authenticated access to the VPN before reaching the administration interface.
```

---

## Toujours expliquer

```text
Problem
↓
Risk
↓
Decision
↓
Benefit
↓
Trade-off
```

Exemple :

```text
Problem:
SSH was exposed to the Internet.

Risk:
It could be targeted by password spraying and vulnerability scanning.

Decision:
Restrict SSH to VPN clients.

Benefit:
The SSH attack surface disappears from the public Internet.

Trade-off:
Administrators must connect to the VPN before accessing servers.
```

---

# 7. Technical Assessment

Avant de sécuriser une infrastructure, il faut comprendre son état actuel.

Lorsqu'aucune documentation n'est disponible, on parle parfois d'audit **black box**.

On doit découvrir :

```text
Users
Services
Network
Processes
Firewall
Applications
Configurations
Permissions
Logs
```

---

# 8. Auditing a Black Box Linux System

Un audit Linux commence généralement par l'identification du système.

---

## Informations générales

```bash
hostname
```

```bash
uname -a
```

```bash
cat /etc/os-release
```

```bash
uptime
```

Ces commandes permettent de connaître :

- hostname ;
- kernel ;
- distribution ;
- version ;
- durée de fonctionnement.

---

# 9. Users and Privileges

Lister les utilisateurs :

```bash
cat /etc/passwd
```

Utilisateurs connectés :

```bash
who
```

```bash
w
```

Groupes :

```bash
cat /etc/group
```

Droits sudo :

```bash
sudo -l
```

Fichier sudoers :

```bash
sudo cat /etc/sudoers
```

ou :

```bash
sudo ls /etc/sudoers.d/
```

Points à vérifier :

- comptes inutilisés ;
- comptes administrateurs ;
- comptes avec shell ;
- privilèges sudo excessifs ;
- comptes partagés.

---

# 10. Running Services

Voir les services systemd :

```bash
systemctl --type=service --state=running
```

Voir les processus :

```bash
ps aux
```

Voir les ports en écoute :

```bash
ss -tulpn
```

Exemple :

```text
LISTEN 0 128 0.0.0.0:22
LISTEN 0 128 0.0.0.0:21
LISTEN 0 128 127.0.0.1:3306
```

Cela indique potentiellement :

```text
22 → SSH
21 → FTP
3306 → MySQL
```

---

# 11. Network Configuration

Interfaces :

```bash
ip addr
```

Routes :

```bash
ip route
```

Neighbors :

```bash
ip neigh
```

DNS :

```bash
cat /etc/resolv.conf
```

---

# 12. Discovering the Real Network Topology

La documentation peut être incorrecte ou incomplète.

Il faut donc découvrir la topologie réelle.

Exemple :

```text
Internet
   |
Router
   |
10.0.0.1
   |
------------------
|                |
Server A         Server B
10.0.0.10        10.0.0.20
```

---

## Méthodes

### Routes

```bash
ip route
```

Exemple :

```text
default via 192.168.1.1 dev eth0
10.10.0.0/24 dev wg0
192.168.1.0/24 dev eth0
```

Cela permet déjà d'identifier deux réseaux.

---

## ARP / Neighbors

```bash
ip neigh
```

Cela permet d'identifier des hôtes présents sur le réseau local.

---

## Scan réseau

Dans un environnement autorisé :

```bash
nmap -sn 192.168.1.0/24
```

Permet d'identifier les machines actives.

---

## Services

```bash
nmap -sV 192.168.1.10
```

Peut révéler :

```text
21/tcp FTP
22/tcp SSH
80/tcp HTTP
443/tcp HTTPS
```

---

# 13. Attack Surface

L'**attack surface** représente tout ce qu'un attaquant peut potentiellement cibler.

Cela comprend :

- ports ouverts ;
- services ;
- applications web ;
- comptes utilisateurs ;
- API ;
- VPN ;
- services cloud ;
- protocoles legacy ;
- logiciels vulnérables.

---

## Exemple

Serveur :

```text
21 FTP
22 SSH
80 HTTP
443 HTTPS
3306 MySQL
```

Si tout est accessible depuis Internet, l'attack surface est importante.

Une meilleure architecture peut devenir :

```text
Internet
 |
443 HTTPS
51820 WireGuard
```

Puis derrière le VPN :

```text
22 SSH
21 FTP
3306 MySQL
```

L'attack surface publique est fortement réduite.

---

# 14. Security Gaps

Quelques problèmes typiques :

### Exposed services

```text
SSH accessible from anywhere
```

### Weak authentication

```text
PasswordAuthentication yes
```

### No firewall

```text
Default policy ACCEPT
```

### Excessive permissions

```text
chmod 777
```

### Legacy protocols

```text
FTP
Telnet
HTTP
```

### Missing updates

```bash
apt list --upgradable
```

### Poor logging

Absence de logs ou logs non surveillés.

---

# 15. Professional Documentation

Un audit doit produire un rapport exploitable.

Une structure courante :

```text
Executive Summary
Scope
Methodology
Current Architecture
Findings
Risk Analysis
Recommendations
Target Architecture
Implementation Plan
Validation
```

---

# 16. Finding Structure

Chaque finding devrait contenir :

```text
Title
Severity
Description
Evidence
Impact
Recommendation
```

---

## Exemple

### Public SSH Exposure

Severity:

```text
High
```

Description :

```text
SSH is accessible from any Internet source.
```

Evidence :

```bash
nmap SERVER_IP
```

Résultat :

```text
22/tcp open ssh
```

Impact :

```text
Attackers can perform brute-force attacks, password spraying and service fingerprinting.
```

Recommendation :

```text
Restrict SSH access to the VPN subnet.
```

---

# 17. Security Architecture

Une architecture de sécurité cherche à limiter les mouvements d'un attaquant.

Une idée importante est :

```text
Never trust, always verify.
```

C'est le principe du **Zero Trust**.

---

# 18. Zero Trust

Dans une architecture traditionnelle :

```text
Inside network = trusted
Outside network = untrusted
```

Zero Trust considère plutôt :

```text
No network should automatically be trusted.
```

Chaque accès doit être contrôlé selon :

- identité ;
- appareil ;
- source ;
- service ;
- autorisation ;
- contexte.

---

# 19. Network Segmentation

Au lieu d'avoir :

```text
192.168.1.0/24
```

avec tous les systèmes mélangés, on peut créer plusieurs segments.

Exemple :

```text
Users
10.0.10.0/24

Servers
10.0.20.0/24

Management
10.0.30.0/24

VPN
10.0.40.0/24
```

---

## Architecture

```text
                 Internet
                    |
                 Firewall
                    |
            +-------+-------+
            |               |
          DMZ              VPN
      10.0.50.0/24     10.0.40.0/24
            |               |
        Web Server      Administrators
                            |
                       Management
                       10.0.30.0/24
                            |
                         Servers
                       10.0.20.0/24
```

---

# 20. Least Privilege

Chaque réseau ou utilisateur ne doit accéder qu'aux ressources nécessaires.

Exemple :

```text
VPN users
```

ne doivent pas automatiquement avoir accès à tout.

On peut autoriser :

```text
VPN → SSH server
```

mais refuser :

```text
VPN → Database
```

---

# 21. Firewall Defense in Depth

Un firewall moderne doit généralement suivre une politique :

```text
default deny
```

Cela signifie :

```text
Everything is blocked unless explicitly allowed.
```

---

## Exemple nftables

```nft
table inet filter {

    chain input {

        type filter hook input priority 0;
        policy drop;

        ct state established,related accept

        iif lo accept

        ip protocol icmp accept

        ip saddr 10.10.0.0/24 tcp dport 22 accept
    }
}
```

---

# 22. Stateful Firewall

Un firewall stateful connaît l'état des connexions.

États courants :

```text
NEW
ESTABLISHED
RELATED
INVALID
```

Exemple :

```nft
ct state established,related accept
```

Cela autorise le trafic appartenant à une connexion déjà autorisée.

---

## Exemple

Client :

```text
10.0.0.5:50000
```

ouvre une connexion vers :

```text
8.8.8.8:443
```

Le firewall autorise la requête.

La réponse :

```text
8.8.8.8:443
→
10.0.0.5:50000
```

est reconnue comme :

```text
ESTABLISHED
```

---

# 23. Defense in Depth

La sécurité ne doit jamais reposer sur une seule protection.

Exemple :

```text
Internet
   |
Firewall
   |
VPN
   |
Firewall Rules
   |
SSH Keys
   |
sudo
```

Pour compromettre le serveur, l'attaquant doit franchir plusieurs couches.

---

# 24. VPN Integration

Un VPN crée un réseau privé chiffré au-dessus d'un réseau non fiable.

Exemple WireGuard :

```text
Administrator
10.10.0.2
      |
      | encrypted tunnel
      |
Internet
      |
VPN Gateway
10.10.0.1
      |
Internal Network
```

---

# 25. VPN and Firewall

Le VPN ne doit pas automatiquement donner accès à tout.

Exemple :

```nft
ip saddr 10.10.0.0/24 tcp dport 22 accept
```

Autorise SSH depuis le VPN.

Mais :

```nft
ip saddr 10.10.0.0/24 tcp dport 3306 drop
```

peut empêcher l'accès direct à MySQL.

---

# 26. Legacy Protocol Constraints

Certaines entreprises utilisent encore :

```text
FTP
Telnet
SMBv1
HTTP
```

pour des raisons de compatibilité.

Il faut alors réduire leur exposition.

---

## Exemple FTP

Architecture dangereuse :

```text
Internet
   |
FTP Server
```

Architecture plus sûre :

```text
Internet
   |
WireGuard VPN
   |
Firewall
   |
FTP Server
```

FTP reste vulnérable mais le trafic Internet est chiffré par WireGuard.

---

# 27. FTP Active vs Passive

FTP est particulièrement complexe car il utilise plusieurs connexions.

### Control connection

```text
TCP/21
```

### Data connection

Le fonctionnement dépend du mode.

---

## Active FTP

Le serveur ouvre la connexion de données vers le client.

```text
Client → Server:21
Server → Client:data-port
```

Cela pose des problèmes avec les firewalls.

---

## Passive FTP

Le client ouvre les deux connexions.

```text
Client → Server:21
Client → Server:passive-port
```

Il est généralement plus simple à gérer derrière un firewall.

---

# 28. Implementation

Une bonne architecture n'est utile que si son déploiement est fiable.

Les scripts doivent notamment être :

```text
Predictable
Repeatable
Safe
Idempotent
```

---

# 29. Idempotent Scripts

Un script est **idempotent** lorsque son exécution répétée produit toujours le même état final.

Mauvais exemple :

```bash
echo "AllowUsers admin" >> /etc/ssh/sshd_config
```

Si le script est lancé trois fois :

```text
AllowUsers admin
AllowUsers admin
AllowUsers admin
```

Ce n'est pas proprement idempotent.

---

## Meilleure approche

```bash
grep -q '^AllowUsers admin$' /etc/ssh/sshd_config ||
echo 'AllowUsers admin' >> /etc/ssh/sshd_config
```

Encore mieux :

```bash
sed -i '/^AllowUsers /d' /etc/ssh/sshd_config
echo 'AllowUsers admin' >> /etc/ssh/sshd_config
```

Le résultat final reste contrôlé.

---

# 30. Exemple d'installation idempotente

```bash
if ! command -v nft >/dev/null 2>&1; then
    apt update
    apt install -y nftables
fi
```

Si nftables est déjà installé :

```text
aucune réinstallation nécessaire
```

---

# 31. Safe Production Deployment

Modifier un firewall à distance est dangereux.

Une mauvaise règle peut provoquer :

```text
SSH disconnected
```

et rendre le serveur inaccessible.

Il faut donc prévoir un mécanisme de récupération.

---

# 32. Panic Button

Avant d'appliquer une configuration firewall, on peut programmer un rollback automatique.

Exemple :

```bash
sleep 300
nft flush ruleset
```

Le principe :

```text
Deploy configuration
       ↓
Test access
       ↓
If successful → cancel rollback

If failure → automatic recovery
```

---

# 33. Backup Before Changes

Toujours sauvegarder les configurations importantes.

Exemple :

```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
```

Firewall :

```bash
nft list ruleset > /root/firewall-backup.nft
```

---

# 34. Validate Configuration Before Reload

Exemple SSH :

```bash
sshd -t
```

Si aucune erreur n'apparaît :

```text
configuration syntax is valid
```

Pour nftables :

```bash
nft -c -f firewall.nft
```

Le `-c` vérifie la configuration sans l'appliquer.

---

# 35. Automated Compliance Checks

Une mesure de sécurité doit être vérifiable automatiquement.

Exemple :

```bash
ss -tln | grep ':22'
```

Pour vérifier SSH.

---

## Vérification firewall

```bash
nft list ruleset
```

---

## Vérification SSH

```bash
grep '^PasswordAuthentication' /etc/ssh/sshd_config
```

Résultat attendu :

```text
PasswordAuthentication no
```

---

# 36. Exemple de compliance script

```bash
#!/bin/bash

FAIL=0

if grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config; then
    echo "[PASS] SSH password authentication disabled"
else
    echo "[FAIL] SSH password authentication enabled"
    FAIL=1
fi

if systemctl is-active --quiet nftables; then
    echo "[PASS] nftables active"
else
    echo "[FAIL] nftables inactive"
    FAIL=1
fi

exit "$FAIL"
```

---

# 37. PASS / FAIL Testing

Les tests doivent être simples à comprendre.

Exemple :

```text
[PASS] Firewall enabled
[PASS] SSH restricted
[PASS] VPN active
[FAIL] FTP accessible from Internet
```

Cela permet aux équipes techniques mais aussi aux responsables de comprendre rapidement l'état du système.

---

# 38. Proving Security Posture

Dire :

```text
The server is secure.
```

n'est pas une preuve.

Il faut produire des éléments mesurables.

---

## Exemple

### Avant

```bash
nmap SERVER_IP
```

```text
21/tcp open ftp
22/tcp open ssh
80/tcp open http
443/tcp open https
```

### Après

```text
443/tcp open https
51820/udp open wireguard
```

On peut démontrer que l'attack surface publique a diminué.

---

# 39. Security Evidence

Les preuves peuvent inclure :

```text
Firewall configuration
Nmap results
VPN status
System logs
Compliance scripts
Screenshots
Configuration files
Audit reports
```

---

# 40. Validation Matrix

Une matrice de validation est particulièrement utile.

| Requirement | Test | Expected Result | Result |
|---|---|---|---|
| SSH VPN only | nmap Internet | port 22 filtered | PASS |
| VPN operational | wg show | recent handshake | PASS |
| FTP internal only | external scan | port 21 closed | PASS |
| Firewall active | nft list ruleset | rules loaded | PASS |
| Password SSH disabled | sshd config | no | PASS |

---

# 41. Example Full Security Assessment

Supposons l'infrastructure suivante :

```text
Server
192.168.1.20

Services:

21 FTP
22 SSH
80 HTTP
443 HTTPS
3306 MySQL
```

Tout est accessible depuis Internet.

---

## Problems

```text
FTP exposed
SSH exposed
Database exposed
No segmentation
No VPN
No firewall policy
```

---

## Target Architecture

```text
                     Internet
                        |
                +-------+-------+
                |               |
             HTTPS           WireGuard
            TCP/443          UDP/51820
                |               |
                |          VPN Network
                |          10.10.0.0/24
                |               |
                +-------+-------+
                        |
                     Firewall
                        |
             +----------+----------+
             |                     |
          Web Server            Internal
                               Services
                                  |
                              SSH / FTP
```

---

# 42. Firewall Policy Example

Public Internet:

```text
ALLOW TCP/443
ALLOW UDP/51820
DROP everything else
```

VPN:

```text
ALLOW TCP/22
ALLOW TCP/21
```

Database:

```text
ALLOW TCP/3306 only from application server
```

---

# 43. Risk Reduction

Avant :

```text
Internet
→ FTP
→ SSH
→ HTTP
→ HTTPS
→ MySQL
```

Après :

```text
Internet
→ HTTPS
→ VPN
```

Cette réduction de services exposés représente une diminution significative de l'attack surface.

---

# 44. Consulting Workflow

Une mission complète peut suivre cette méthode.

## Phase 1 — Discovery

```text
Understand business requirements
Identify stakeholders
Define scope
```

---

## Phase 2 — Assessment

```text
Inspect systems
Inspect services
Inspect users
Inspect network
Inspect firewall
Inspect configurations
```

---

## Phase 3 — Gap Analysis

Comparer :

```text
Current State
```

avec :

```text
Target Security State
```

---

## Phase 4 — Architecture

Créer :

```text
Network segmentation
VPN architecture
Firewall policy
Access control
```

---

## Phase 5 — Implementation

Créer des scripts :

```text
Hardening
Firewall
VPN
Permissions
Logging
```

---

## Phase 6 — Validation

Tester :

```text
Connectivity
Security controls
External exposure
Authentication
Compliance
```

---

## Phase 7 — Documentation

Produire :

```text
Architecture diagrams
Findings
Risk table
Firewall matrix
Implementation scripts
Compliance results
```

---

# 45. Questions à savoir expliquer

À la fin du projet, vous devez pouvoir répondre clairement aux questions suivantes.

### Pourquoi commencer par les besoins métier ?

Parce qu'une solution technique doit résoudre un problème réel de l'entreprise et respecter ses contraintes.

### Pourquoi effectuer une Gap Analysis ?

Pour identifier la différence entre la sécurité actuelle et l'état de sécurité souhaité.

### Pourquoi utiliser une politique default deny ?

Parce qu'elle n'autorise que les flux explicitement nécessaires.

### Pourquoi segmenter le réseau ?

Pour limiter l'accès aux ressources et réduire les mouvements latéraux d'un attaquant.

### Pourquoi utiliser un VPN ?

Pour protéger les communications à travers un réseau non fiable et réduire l'exposition des services internes.

### Pourquoi FTP pose-t-il problème ?

Parce qu'il ne chiffre ni les identifiants ni les données et utilise un fonctionnement réseau complexe.

### Que faire si FTP ne peut pas être supprimé ?

Utiliser des mesures compensatoires : VPN, segmentation, firewall, monitoring et permissions minimales.

### Qu'est-ce qu'un script idempotent ?

Un script pouvant être exécuté plusieurs fois tout en produisant le même état final.

### Pourquoi automatiser les tests de conformité ?

Pour vérifier rapidement et régulièrement que les contrôles de sécurité sont toujours correctement appliqués.

### Comment prouver qu'un serveur est mieux sécurisé ?

Avec des preuves objectives : scans, règles firewall, configurations, logs et tests automatisés.

---

# 46. Commandes importantes à retenir

## Système

```bash
uname -a
cat /etc/os-release
hostname
uptime
```

## Utilisateurs

```bash
cat /etc/passwd
cat /etc/group
who
w
sudo -l
```

## Processus

```bash
ps aux
```

## Services

```bash
systemctl --type=service --state=running
```

## Réseau

```bash
ip addr
ip route
ip neigh
```

## Ports

```bash
ss -tulpn
```

## Firewall

```bash
nft list ruleset
```

## WireGuard

```bash
wg show
```

## Scan

```bash
nmap -sV IP
```

## Vérification SSH

```bash
sshd -t
```

## Vérification nftables

```bash
nft -c -f firewall.nft
```

---

# 47. Les principes les plus importants

À retenir :

```text
Understand before changing.
```

Il faut comprendre l'infrastructure avant de la modifier.

```text
Reduce attack surface.
```

Moins de services exposés signifie généralement moins d'opportunités d'attaque.

```text
Default deny.
```

Tout bloquer puis autoriser uniquement ce qui est nécessaire.

```text
Least privilege.
```

Chaque utilisateur et chaque système ne doit disposer que des accès nécessaires.

```text
Defense in depth.
```

Ne jamais dépendre d'une seule mesure de sécurité.

```text
Assume breach.
```

Construire l'architecture en supposant qu'un composant peut être compromis.

```text
Verify everything.
```

Une mesure de sécurité doit être testée.

```text
Document everything.
```

Une architecture non documentée devient rapidement difficile à maintenir.

---

# Conclusion

Un projet de sécurisation d'infrastructure ne consiste pas simplement à installer un firewall ou un VPN.

Il faut être capable de passer de :

```text
Business Requirement
```

à :

```text
Technical Requirement
```

puis :

```text
Security Architecture
```

puis :

```text
Implementation
```

et enfin :

```text
Evidence
```

La démarche complète peut être résumée ainsi :

```text
DISCOVER
   ↓
UNDERSTAND
   ↓
ASSESS
   ↓
IDENTIFY GAPS
   ↓
DESIGN
   ↓
IMPLEMENT
   ↓
TEST
   ↓
PROVE
   ↓
DOCUMENT
```

C'est cette combinaison entre **consulting, Linux, réseau, architecture, sécurité et validation** qui permet de transformer une infrastructure existante en environnement réellement défendable.
