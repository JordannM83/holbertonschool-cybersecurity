# Network Traffic Analysis & Forensics

## Introduction

L’analyse de trafic réseau consiste à observer les communications entre différentes machines afin de comprendre ce qui s’est passé sur un réseau.

Dans un contexte de cybersécurité, elle permet notamment de :

- détecter une phase de reconnaissance ;
- identifier une tentative d’exploitation ;
- retrouver les commandes exécutées par un attaquant ;
- identifier un reverse shell ;
- détecter une exfiltration de données ;
- récupérer des fichiers transférés ;
- extraire des identifiants transmis en clair ;
- reconstruire la chronologie complète d’une attaque.

Les captures réseau sont généralement enregistrées dans des fichiers :

```text
.pcap
.pcapng
```

Les deux outils principalement utilisés sont :

```text
Wireshark
tshark
```

Wireshark fournit une interface graphique.

Tshark correspond essentiellement à la version en ligne de commande de Wireshark et permet d’automatiser beaucoup plus facilement les analyses.

---

# 1. Comprendre une communication réseau

Avant de chercher une attaque, il faut comprendre ce qu’est une connexion normale.

Une communication TCP peut être représentée simplement par :

```text
Client                         Serveur

SYN        ------------------->
           <------------------- SYN, ACK
ACK        ------------------->

           Connexion établie
```

Cette phase est appelée :

```text
TCP Three-Way Handshake
```

Une fois la connexion établie, les deux machines peuvent échanger des données.

Par exemple :

```text
192.168.1.15:54021 -> 192.168.1.20:80
```

signifie que :

```text
192.168.1.15
```

communique avec :

```text
192.168.1.20
```

sur le port :

```text
80
```

Le port 80 correspond généralement à HTTP.

---

# 2. Traffic Identification

## 2.1 Différencier un scan d'une connexion légitime

Une des premières actions réalisées par un attaquant est généralement la reconnaissance.

L'objectif est de découvrir :

- les machines actives ;
- les ports ouverts ;
- les services disponibles ;
- les versions des services ;
- les potentielles vulnérabilités.

Un scan réseau génère un comportement différent d'un utilisateur normal.

Un utilisateur légitime communique généralement avec quelques services précis :

```text
Client -> Serveur Web :80
Client -> Serveur DNS :53
Client -> Serveur HTTPS :443
```

Un scanner peut envoyer des paquets vers des dizaines ou centaines de ports :

```text
10.10.14.25 -> 10.10.10.5:21
10.10.14.25 -> 10.10.10.5:22
10.10.14.25 -> 10.10.10.5:23
10.10.14.25 -> 10.10.10.5:25
10.10.14.25 -> 10.10.10.5:80
10.10.14.25 -> 10.10.10.5:443
10.10.14.25 -> 10.10.10.5:445
```

Ce comportement est caractéristique d'un :

```text
Port Scan
```

---

## 2.2 SYN Scan

Nmap utilise fréquemment le SYN Scan :

```bash
nmap -sS 10.10.10.5
```

Le scanner envoie :

```text
SYN
```

Si le port est ouvert, la cible répond :

```text
SYN, ACK
```

Mais l'attaquant peut ne jamais terminer complètement la connexion.

Dans Wireshark :

```text
tcp.flags.syn == 1 && tcp.flags.ack == 0
```

permet d'afficher les SYN initiaux.

Pour cibler une IP :

```text
ip.src == 10.10.14.25 && tcp.flags.syn == 1 && tcp.flags.ack == 0
```

Un grand nombre de SYN vers plusieurs ports différents peut indiquer un scan.

---

# 3. Trouver les machines principales

Avant d'analyser des milliers de paquets, il faut déterminer quelles machines communiquent le plus.

Avec Tshark :

```bash
tshark -r capture.pcap -q -z conv,ip
```

Cette commande affiche les conversations IP.

Exemple :

```text
10.10.14.25 <-> 10.10.10.5
192.168.1.5 <-> 8.8.8.8
192.168.1.8 <-> 192.168.1.1
```

Une conversation contenant énormément de paquets ou une machine externe inhabituelle mérite une investigation.

---

# 4. Identifier les ports utilisés

Pour observer les connexions TCP :

```bash
tshark -r capture.pcap -q -z conv,tcp
```

On peut obtenir :

```text
10.10.14.25:55234 <-> 10.10.10.5:80
10.10.14.25:55280 <-> 10.10.10.5:22
10.10.10.5:4444  <-> 10.10.14.25:51221
```

La dernière connexion peut être intéressante.

Le port :

```text
4444
```

est souvent utilisé dans les laboratoires pour les reverse shells.

Attention cependant :

```text
port inhabituel != forcément malveillant
```

Il faut toujours regarder le contenu et le contexte de la connexion.

---

# 5. Identifier un exploit HTTP

De nombreuses attaques transitent par HTTP.

Exemple :

```http
GET /index.php?id=1 HTTP/1.1
Host: victim.local
User-Agent: Mozilla/5.0
```

Une requête normale contient généralement des paramètres correspondant au fonctionnement de l'application.

Une requête malveillante peut contenir :

```text
cmd=
exec=
system=
shell=
../
<script>
UNION SELECT
/etc/passwd
/bin/bash
```

Exemple :

```http
GET /vulnerable.php?cmd=id HTTP/1.1
```

Ici :

```text
cmd=id
```

peut indiquer une tentative d'exécution de commandes.

---

# 6. Filtrer HTTP avec Wireshark

Afficher seulement HTTP :

```text
http
```

Afficher les requêtes HTTP :

```text
http.request
```

Afficher uniquement les GET :

```text
http.request.method == "GET"
```

Afficher les POST :

```text
http.request.method == "POST"
```

Afficher les requêtes provenant d'un attaquant suspect :

```text
ip.src == 10.10.14.25 && http.request
```

---

# 7. Inspecter un flux TCP

Une requête peut être répartie sur plusieurs paquets.

Lire chaque paquet individuellement peut donc être trompeur.

Wireshark permet de reconstruire la conversation complète :

```text
Right Click
→ Follow
→ TCP Stream
```

ou :

```text
Follow HTTP Stream
```

Cela permet de visualiser :

```text
Attaquant
   ↓
requête HTTP
   ↓
Serveur
   ↓
réponse HTTP
```

et parfois directement :

```text
commande
résultat
commande
résultat
```

---

# 8. Identifier les payloads d'exploitation

Un payload correspond aux données envoyées afin d'exploiter une vulnérabilité.

Exemple simple :

```text
?cmd=whoami
```

Exemple :

```text
?file=../../../../etc/passwd
```

Cela ressemble à une tentative de :

```text
Directory Traversal
```

Autre exemple :

```text
?id=1 UNION SELECT username,password FROM users
```

Cela peut indiquer :

```text
SQL Injection
```

Ou encore :

```text
; bash -c "..."
```

peut indiquer une :

```text
Command Injection
```

---

# 9. URL Encoding

Les attaques HTTP sont souvent encodées.

Par exemple :

```text
space → %20
/     → %2F
;     → %3B
'     → %27
"     → %22
```

Une requête comme :

```text
cmd=cat%20%2Fetc%2Fpasswd
```

correspond à :

```bash
cat /etc/passwd
```

---

# 10. Décoder une URL

Avec Python :

```bash
python3 -c 'import urllib.parse; print(urllib.parse.unquote("cat%20%2Fetc%2Fpasswd"))'
```

Résultat :

```text
cat /etc/passwd
```

On peut aussi utiliser CyberChef lors d'une analyse manuelle.

Cependant, il est important d'être capable de reconnaître les encodages simples sans dépendre systématiquement d'un outil externe.

---

# 11. Identifier un User-Agent malveillant

Un navigateur envoie généralement un User-Agent.

Exemple :

```text
Mozilla/5.0
```

Certaines attaques utilisent des User-Agent caractéristiques.

Exemples potentiellement intéressants :

```text
sqlmap
nikto
curl
wget
python-requests
Nmap Scripting Engine
masscan
```

Dans Wireshark :

```text
http.user_agent
```

Pour filtrer sqlmap :

```text
http.user_agent contains "sqlmap"
```

Avec Tshark :

```bash
tshark -r capture.pcap \
-Y "http.user_agent" \
-T fields \
-e ip.src \
-e http.host \
-e http.user_agent
```

Exemple :

```text
10.10.14.25 victim.local sqlmap/1.8
```

Cela constitue un indice très fort.

---

# 12. Identifier un reverse shell

Un reverse shell permet à une machine compromise de se connecter vers l'attaquant.

Contrairement à une connexion classique où :

```text
Attacker -> Victim
```

le reverse shell fonctionne généralement comme :

```text
Victim -> Attacker
```

L'attaquant démarre un listener :

```bash
nc -lvnp 4444
```

La victime établit ensuite une connexion sortante.

Schéma :

```text
Attacker
10.10.14.25:4444
      ▲
      |
      |
Victim
10.10.10.5:51234
```

---

# 13. Reconnaître un reverse shell dans un PCAP

Plusieurs indices peuvent être utilisés :

### Connexion sortante inhabituelle

Exemple :

```text
Victim -> Attacker:4444
```

### Connexion apparaissant juste après un exploit

Chronologie :

```text
10:00:00 Scan
10:01:30 HTTP exploit
10:01:31 Victim -> Attacker:4444
```

Cette proximité temporelle est très importante.

### Trafic interactif

Un shell produit souvent beaucoup de petits paquets correspondant à :

```text
commande
réponse
commande
réponse
```

Par exemple :

```bash
whoami
id
uname -a
pwd
ls
```

---

# 14. Reconstruire un shell

Dans Wireshark :

```text
Follow TCP Stream
```

On peut parfois obtenir quelque chose comme :

```text
$ whoami
www-data

$ id
uid=33(www-data) gid=33(www-data)

$ pwd
/var/www/html

$ ls
index.php
uploads
config.php
```

Cela permet de reconstruire l'activité de l'attaquant.

---

# 15. Reconnaître les phases classiques après compromission

Un attaquant suit généralement plusieurs étapes.

## Énumération

```bash
whoami
id
hostname
uname -a
pwd
```

Objectif :

```text
Comprendre l'environnement compromis.
```

---

## Exploration

```bash
ls
ls -la
find /
cd /home
cd /var/www
```

Objectif :

```text
Trouver des fichiers intéressants.
```

---

## Recherche de secrets

```bash
cat config.php
cat .env
grep -R password .
find / -name "*.conf"
```

Objectif :

```text
Récupérer des identifiants ou informations sensibles.
```

---

## Préparation de l'exfiltration

```bash
tar
zip
gzip
base64
```

Exemple :

```bash
tar czf /tmp/data.tar.gz /home/user/documents
```

---

# 16. Identifier une exfiltration de données

L'exfiltration correspond au transfert de données depuis la victime vers l'attaquant.

Elle peut utiliser :

```text
HTTP
HTTPS
FTP
DNS
SSH
SMB
Raw TCP
```

ou des protocoles détournés.

Un indice important est :

```text
un volume important de données sortantes
```

Exemple :

```text
Victim → Attacker
150 MB

Attacker → Victim
15 KB
```

Le trafic est très asymétrique.

---

# 17. Analyser les conversations

Avec Tshark :

```bash
tshark -r capture.pcap -q -z conv,ip
```

ou :

```bash
tshark -r capture.pcap -q -z conv,tcp
```

On peut regarder :

```text
Packets A → B
Bytes A → B

Packets B → A
Bytes B → A
```

Si une machine interne transmet plusieurs centaines de mégaoctets vers une IP externe inconnue, cela mérite une investigation.

---

# 18. Détecter l'exfiltration HTTP

On peut observer les POST :

```text
http.request.method == "POST"
```

Une requête POST anormalement importante peut transporter :

```text
fichier
archive
credentials
base64
dump de base de données
```

Avec Tshark :

```bash
tshark -r capture.pcap \
-Y 'http.request.method == "POST"' \
-T fields \
-e frame.time \
-e ip.src \
-e ip.dst \
-e http.host \
-e http.request.uri
```

---

# 19. Forensic Extraction

La forensic extraction consiste à récupérer des informations ou objets directement depuis le trafic réseau.

On peut notamment extraire :

```text
fichiers
images
documents
archives
identifiants
commandes
cookies
payloads
```

---

# 20. Extraire des fichiers avec Wireshark

Wireshark peut reconstruire certains fichiers automatiquement.

Menu :

```text
File
→ Export Objects
```

On peut ensuite choisir :

```text
HTTP
SMB
TFTP
IMF
DICOM
```

Par exemple :

```text
File
→ Export Objects
→ HTTP
```

permet de récupérer certains fichiers transférés via HTTP.

---

# 21. Extraire des objets avec Tshark

Tshark possède également :

```bash
--export-objects
```

Exemple :

```bash
mkdir extracted
```

Puis :

```bash
tshark -r capture.pcap \
--export-objects http,extracted/
```

Les fichiers HTTP reconstruits seront placés dans :

```text
extracted/
```

---

# 22. File Carving

Lorsque l'export automatique ne fonctionne pas, on peut essayer de reconstruire manuellement un fichier à partir d'un flux réseau.

Cette opération est appelée :

```text
File Carving
```

On recherche notamment les signatures de fichiers.

Exemples :

```text
PDF  → %PDF
ZIP  → PK
PNG  → 89 50 4E 47
JPEG → FF D8 FF
ELF  → 7F 45 4C 46
```

Ces signatures sont appelées :

```text
Magic Bytes
```

---

# 23. Extraire des credentials

Les protocoles non chiffrés peuvent transmettre les identifiants en clair.

Exemples :

```text
HTTP
FTP
Telnet
POP3
IMAP sans TLS
```

FTP est particulièrement intéressant.

Filtre :

```text
ftp
```

On peut voir :

```text
USER admin
PASS password123
```

Dans ce cas, les identifiants sont directement présents dans le PCAP.

---

# 24. Credentials HTTP

Un formulaire HTTP peut contenir :

```http
POST /login HTTP/1.1

username=admin&password=secret123
```

Filtre :

```text
http.request.method == "POST"
```

Puis :

```text
Follow HTTP Stream
```

Attention :

```text
HTTPS
```

chiffre normalement ce contenu.

Sans clés TLS ou mécanisme de déchiffrement approprié, on ne peut pas simplement lire le mot de passe dans le PCAP.

---

# 25. HTTP Basic Authentication

HTTP Basic Auth utilise un en-tête :

```text
Authorization: Basic ...
```

La valeur correspond à :

```text
username:password
```

encodé en Base64.

Exemple conceptuel :

```text
admin:password
        ↓
Base64
        ↓
YWRtaW46cGFzc3dvcmQ=
```

Base64 n'est PAS un chiffrement.

Il s'agit uniquement d'un encodage.

---

# 26. Tshark Mastery

Tshark permet d'analyser un PCAP directement depuis le terminal.

Syntaxe fondamentale :

```bash
tshark -r capture.pcap
```

`-r` signifie :

```text
read
```

---

# 27. Display Filters

L'option :

```bash
-Y
```

permet d'appliquer un display filter.

Exemple :

```bash
tshark -r capture.pcap -Y "http"
```

IP source :

```bash
tshark -r capture.pcap \
-Y "ip.src == 10.10.14.25"
```

IP destination :

```bash
tshark -r capture.pcap \
-Y "ip.dst == 10.10.10.5"
```

Port TCP :

```bash
tshark -r capture.pcap \
-Y "tcp.port == 4444"
```

SYN :

```bash
tshark -r capture.pcap \
-Y "tcp.flags.syn == 1 && tcp.flags.ack == 0"
```

---

# 28. Combiner plusieurs filtres

AND :

```text
&&
```

Exemple :

```bash
tshark -r capture.pcap \
-Y "ip.src == 10.10.14.25 && http"
```

OR :

```text
||
```

Exemple :

```text
tcp.port == 80 || tcp.port == 443
```

NOT :

```text
!
```

Exemple :

```text
!dns
```

---

# 29. Field Extraction

Une des fonctionnalités les plus importantes de Tshark est :

```bash
-T fields
```

Elle permet de sélectionner précisément les informations affichées.

Exemple :

```bash
tshark -r capture.pcap \
-T fields \
-e ip.src \
-e ip.dst
```

Résultat :

```text
10.10.14.25    10.10.10.5
10.10.10.5     10.10.14.25
```

---

# 30. Extraire des requêtes HTTP

```bash
tshark -r capture.pcap \
-Y "http.request" \
-T fields \
-e frame.time \
-e ip.src \
-e ip.dst \
-e http.request.method \
-e http.host \
-e http.request.uri
```

Résultat possible :

```text
10:00:32 10.10.14.25 10.10.10.5 GET victim.local /index.php
```

Cette sortie est beaucoup plus simple à analyser qu'un affichage complet des paquets.

---

# 31. Extraire les User-Agent

```bash
tshark -r capture.pcap \
-Y "http.user_agent" \
-T fields \
-e ip.src \
-e http.host \
-e http.user_agent
```

Cela permet de trouver rapidement :

```text
curl
wget
sqlmap
nikto
python-requests
```

---

# 32. Statistics Modes

Tshark possède plusieurs modes statistiques avec :

```bash
-z
```

Conversations IP :

```bash
tshark -r capture.pcap -q -z conv,ip
```

Conversations TCP :

```bash
tshark -r capture.pcap -q -z conv,tcp
```

Endpoints IP :

```bash
tshark -r capture.pcap -q -z endpoints,ip
```

---

# 33. Compter les paquets

Une méthode simple :

```bash
tshark -r capture.pcap | wc -l
```

Pour compter uniquement certains paquets :

```bash
tshark -r capture.pcap \
-Y "ip.src == 10.10.14.25" | wc -l
```

---

# 34. Afficher les timestamps

Pour reconstruire une attaque, les timestamps sont essentiels.

```bash
tshark -r capture.pcap \
-T fields \
-e frame.time \
-e ip.src \
-e ip.dst
```

On peut aussi utiliser :

```text
frame.time_epoch
```

qui donne le timestamp Unix.

```bash
tshark -r capture.pcap \
-T fields \
-e frame.time_epoch
```

Exemple :

```text
1756212004.143520
```

---

# 35. Attack Correlation

Une analyse forensique ne consiste pas uniquement à trouver des paquets suspects.

Il faut relier les événements entre eux.

Une attaque classique peut ressembler à :

```text
Reconnaissance
      ↓
Service Discovery
      ↓
Exploitation
      ↓
Reverse Shell
      ↓
Enumeration
      ↓
Credential Access
      ↓
Data Collection
      ↓
Exfiltration
      ↓
Command & Control
```

---

# 36. Construire une timeline

Une timeline simple peut être :

```text
10:00:01 Reconnaissance commence
10:00:15 Port 80 découvert
10:00:30 Première requête HTTP
10:01:12 Payload malveillant envoyé
10:01:13 Reverse shell établi
10:01:15 Commande whoami
10:01:18 Commande uname -a
10:02:42 Fichier secret.txt découvert
10:03:10 Archive créée
10:03:20 Exfiltration
10:04:05 Dernier beacon C2
```

Cette timeline permet de raconter l'attaque dans l'ordre.

---

# 37. Identifier le début d'une attaque

Le début correspond souvent à :

```text
premier paquet de reconnaissance malveillant
```

Il faut cependant distinguer :

```text
trafic réseau normal
```

et :

```text
activité de l'attaquant
```

Une fois l'IP attaquante identifiée :

```text
ip.addr == ATTACKER_IP
```

permet d'isoler ses communications.

---

# 38. Identifier la fin de l'attaque

La fin peut correspondre au :

```text
dernier paquet malveillant
```

Il peut s'agir :

- du dernier paquet d'exfiltration ;
- de la fermeture du reverse shell ;
- du dernier beacon C2 ;
- de la dernière connexion avec l'infrastructure de l'attaquant.

Il faut donc suivre l'activité malveillante jusqu'à sa disparition complète.

---

# 39. Calculer la durée de l'attaque

Si :

```text
premier paquet = 10:00:00.250
dernier paquet = 10:04:30.750
```

alors :

```text
durée = 270.5 secondes
```

Avec les timestamps Unix, le calcul est encore plus simple :

```text
duration = last_timestamp - first_timestamp
```

---

# 40. Identifier l'infrastructure de l'attaquant

Il faut rechercher :

```text
IP attaquante
domaines C2
serveurs externes
ports utilisés
User-Agent
DNS requests
HTTP Host headers
```

Un domaine contacté juste après une compromission peut être particulièrement intéressant.

---

# 41. Identifier un domaine C2

Filtre DNS :

```text
dns
```

Requêtes DNS uniquement :

```text
dns.flags.response == 0
```

Avec Tshark :

```bash
tshark -r capture.pcap \
-Y "dns.flags.response == 0" \
-T fields \
-e frame.time \
-e ip.src \
-e dns.qry.name
```

Exemple :

```text
10:01:45 10.10.10.5 update-control.example
10:02:45 10.10.10.5 update-control.example
10:03:45 10.10.10.5 update-control.example
```

Une requête régulière peut correspondre à un mécanisme de :

```text
Command & Control
```

---

# 42. Beaconing

Un malware peut contacter son serveur C2 toutes les :

```text
30 secondes
60 secondes
5 minutes
```

Exemple :

```text
10:01:00 C2
10:02:00 C2
10:03:00 C2
10:04:00 C2
```

Cette régularité est appelée :

```text
Beaconing
```

La périodicité est un indice important lors de l'identification d'un malware ou d'une infrastructure C2.

---

# 43. Méthode complète d'analyse d'un PCAP

Pour éviter de chercher au hasard dans Wireshark, il est préférable d'utiliser une méthodologie.

## Étape 1 — Taille et informations générales

```bash
capinfos capture.pcap
```

Observer :

```text
nombre de paquets
durée
taille
premier paquet
dernier paquet
```

---

## Étape 2 — Identifier les machines

```bash
tshark -r capture.pcap -q -z endpoints,ip
```

Puis :

```bash
tshark -r capture.pcap -q -z conv,ip
```

Chercher :

```text
machines très actives
IP externes
forts volumes
communications inhabituelles
```

---

## Étape 3 — Identifier les protocoles

```bash
tshark -r capture.pcap -q -z io,phs
```

Il peut apparaître :

```text
TCP
UDP
HTTP
DNS
FTP
SMB
TLS
```

---

## Étape 4 — Chercher la reconnaissance

Observer les SYN :

```text
tcp.flags.syn == 1 && tcp.flags.ack == 0
```

Chercher :

```text
une IP
→ plusieurs ports
→ en très peu de temps
```

---

## Étape 5 — Identifier le service ciblé

Une fois le scan terminé, déterminer quelle connexion a réellement été établie.

Par exemple :

```text
Scan ports 1-1000
        ↓
Port 80 ouvert
        ↓
HTTP traffic
```

On peut alors concentrer l'analyse sur HTTP.

---

## Étape 6 — Chercher l'exploitation

Examiner :

```text
URI
POST data
User-Agent
parameters
payloads encodés
commandes
```

Filtres :

```text
http.request
```

et :

```text
ip.src == ATTACKER_IP && http.request
```

---

## Étape 7 — Chercher une connexion secondaire

Après l'exploitation, regarder si la victime initie soudainement une connexion vers l'attaquant.

Exemple :

```text
Victim → Attacker:4444
```

Cela peut correspondre à un reverse shell.

---

## Étape 8 — Follow TCP Stream

Reconstituer la session :

```text
commande
réponse
commande
réponse
```

Compter ensuite les commandes réellement exécutées.

---

## Étape 9 — Chercher les données collectées

Identifier notamment :

```text
cat
find
grep
tar
zip
base64
```

et les fichiers manipulés.

---

## Étape 10 — Identifier l'exfiltration

Regarder les connexions :

```bash
tshark -r capture.pcap -q -z conv,tcp
```

Puis rechercher :

```text
grands volumes sortants
connexions vers l'attaquant
POST inhabituels
transfert de fichiers
```

---

## Étape 11 — Chercher le C2

Examiner :

```text
DNS
HTTP
TLS
IP externes
connexions régulières
```

et identifier un éventuel beaconing.

---

## Étape 12 — Construire la timeline

Pour chaque événement :

```text
timestamp
source
destination
activité
preuve
```

Exemple :

| Temps | Source | Destination | Événement |
|---|---|---|---|
| 10:00:01 | Attacker | Victim | Début du scan |
| 10:00:17 | Attacker | Victim | Port 80 identifié |
| 10:01:04 | Attacker | Victim | Payload HTTP |
| 10:01:05 | Victim | Attacker | Reverse shell |
| 10:01:08 | Attacker | Victim | `whoami` |
| 10:02:14 | Attacker | Victim | Lecture fichier |
| 10:03:30 | Victim | Attacker | Exfiltration |
| 10:04:22 | Victim | C2 | Dernier beacon |

---

# 44. Différence entre Capture Filter et Display Filter

C'est une différence importante dans Wireshark.

## Capture Filter

Utilisé pendant la capture.

Syntaxe BPF :

```text
host 192.168.1.10
```

ou :

```text
tcp port 80
```

Le trafic ne correspondant pas au filtre n'est pas enregistré.

---

## Display Filter

Utilisé après la capture.

Exemple :

```text
ip.addr == 192.168.1.10
```

ou :

```text
tcp.port == 80
```

Les paquets restent présents dans le fichier mais ne sont simplement pas affichés.

Tshark utilise notamment :

```bash
-Y
```

pour appliquer un display filter.

---

# 45. Filtres Wireshark utiles à connaître

## IP

```text
ip.addr == 10.10.10.5
```

```text
ip.src == 10.10.14.25
```

```text
ip.dst == 10.10.10.5
```

---

## TCP

```text
tcp
```

```text
tcp.port == 4444
```

```text
tcp.flags.syn == 1
```

```text
tcp.flags.syn == 1 && tcp.flags.ack == 0
```

---

## HTTP

```text
http
```

```text
http.request
```

```text
http.request.method == "GET"
```

```text
http.request.method == "POST"
```

```text
http.request.uri contains "cmd"
```

---

## DNS

```text
dns
```

```text
dns.flags.response == 0
```

```text
dns.qry.name
```

---

## FTP

```text
ftp
```

```text
ftp.request.command == "USER"
```

```text
ftp.request.command == "PASS"
```

---

# 46. Commandes Tshark essentielles

Lire un PCAP :

```bash
tshark -r capture.pcap
```

Conversations IP :

```bash
tshark -r capture.pcap -q -z conv,ip
```

Endpoints :

```bash
tshark -r capture.pcap -q -z endpoints,ip
```

Protocoles :

```bash
tshark -r capture.pcap -q -z io,phs
```

Filtrer :

```bash
tshark -r capture.pcap -Y "FILTER"
```

Extraire des champs :

```bash
tshark -r capture.pcap \
-T fields \
-e FIELD
```

Export HTTP :

```bash
tshark -r capture.pcap \
--export-objects http,./output
```

---

# 47. Exemple de workflow Tshark

Supposons :

```text
capture.pcap
```

Commencer par :

```bash
capinfos capture.pcap
```

Puis :

```bash
tshark -r capture.pcap -q -z endpoints,ip
```

Ensuite :

```bash
tshark -r capture.pcap -q -z conv,ip
```

Puis chercher les SYN :

```bash
tshark -r capture.pcap \
-Y "tcp.flags.syn == 1 && tcp.flags.ack == 0" \
-T fields \
-e frame.time \
-e ip.src \
-e ip.dst \
-e tcp.dstport
```

Une fois l'attaquant identifié :

```bash
tshark -r capture.pcap \
-Y "ip.addr == 10.10.14.25"
```

Chercher HTTP :

```bash
tshark -r capture.pcap \
-Y "ip.src == 10.10.14.25 && http.request"
```

Extraire les URI :

```bash
tshark -r capture.pcap \
-Y "ip.src == 10.10.14.25 && http.request" \
-T fields \
-e frame.time \
-e http.request.method \
-e http.host \
-e http.request.uri
```

Puis analyser les connexions TCP :

```bash
tshark -r capture.pcap -q -z conv,tcp
```

Enfin, inspecter le stream suspect dans Wireshark.

---

# 48. Comment raisonner pendant une investigation

L'objectif n'est pas seulement de trouver :

```text
un paquet bizarre
```

Il faut répondre à une série de questions.

```text
Qui est l'attaquant ?
```

Puis :

```text
Quelle machine a-t-il ciblée ?
```

Puis :

```text
Comment a-t-il découvert la machine ?
```

Puis :

```text
Quel service a-t-il ciblé ?
```

Puis :

```text
Quelle vulnérabilité ou quel payload a été utilisé ?
```

Puis :

```text
A-t-il obtenu une exécution de commande ?
```

Puis :

```text
A-t-il créé un shell ?
```

Puis :

```text
Quelles commandes a-t-il exécutées ?
```

Puis :

```text
Quelles informations a-t-il trouvées ?
```

Puis :

```text
Quelles données ont quitté la machine ?
```

Puis :

```text
Quelle infrastructure externe a été utilisée ?
```

---

# 49. Corrélation des événements

Un événement isolé n'est pas toujours suffisant.

Exemple :

```text
SYN vers port 80
```

n'est pas forcément malveillant.

Mais :

```text
500 SYN
        ↓
requête HTTP étrange
        ↓
command injection
        ↓
connexion sortante vers port 4444
        ↓
whoami
        ↓
cat /etc/passwd
```

forme une chaîne d'événements cohérente.

C'est cette corrélation qui permet d'affirmer qu'une attaque a probablement eu lieu.

---

# 50. Les quatre grandes phases à retenir

Pour ce type d'exercice, on peut généralement simplifier une attaque réseau en quatre grandes étapes.

```text
1. RECONNAISSANCE
```

L'attaquant cherche la cible et les services.

```text
2. EXPLOITATION
```

L'attaquant exploite une vulnérabilité.

```text
3. POST-EXPLOITATION
```

L'attaquant explore la machine et récupère des informations.

```text
4. EXFILTRATION / C2
```

L'attaquant transfère des données ou maintient une communication avec son infrastructure.

---

# 51. Résumé des objectifs

À la fin de ce projet, il faut être capable d'expliquer sans aide externe comment :

## Traffic Identification

- reconnaître un scan réseau ;
- le différencier d'une connexion normale ;
- identifier une requête HTTP malveillante ;
- reconnaître un payload d'exploitation ;
- détecter la création d'un reverse shell ;
- repérer une potentielle exfiltration.

## Forensic Extraction

- reconstruire un flux réseau ;
- récupérer des fichiers depuis HTTP ou d'autres protocoles ;
- comprendre le principe du file carving ;
- récupérer des credentials transmis en clair ;
- identifier un User-Agent malveillant ;
- décoder un payload URL-encoded.

## Tshark Mastery

- lire un fichier PCAP ;
- utiliser des display filters avec `-Y` ;
- analyser les conversations avec `-z` ;
- sélectionner des champs avec `-T fields` et `-e` ;
- exporter des fichiers avec `--export-objects`.

## Attack Correlation

- trouver le début d'une attaque ;
- trouver la fin de l'activité malveillante ;
- reconstruire une timeline ;
- relier reconnaissance, exploitation et post-exploitation ;
- identifier l'adresse IP de l'attaquant ;
- identifier un éventuel domaine C2 ;
- comprendre les patterns de beaconing ;
- déterminer comment les données ont été exfiltrées.

---

# Cheat Sheet

```bash
# Informations générales
capinfos capture.pcap

# Endpoints IP
tshark -r capture.pcap -q -z endpoints,ip

# Conversations IP
tshark -r capture.pcap -q -z conv,ip

# Conversations TCP
tshark -r capture.pcap -q -z conv,tcp

# Hiérarchie des protocoles
tshark -r capture.pcap -q -z io,phs

# SYN uniquement
tshark -r capture.pcap \
-Y "tcp.flags.syn == 1 && tcp.flags.ack == 0"

# Activité d'une IP
tshark -r capture.pcap \
-Y "ip.addr == 10.10.14.25"

# HTTP requests
tshark -r capture.pcap \
-Y "http.request"

# HTTP requests structurées
tshark -r capture.pcap \
-Y "http.request" \
-T fields \
-e frame.time \
-e ip.src \
-e ip.dst \
-e http.request.method \
-e http.host \
-e http.request.uri

# User Agents
tshark -r capture.pcap \
-Y "http.user_agent" \
-T fields \
-e ip.src \
-e http.host \
-e http.user_agent

# DNS queries
tshark -r capture.pcap \
-Y "dns.flags.response == 0" \
-T fields \
-e frame.time \
-e ip.src \
-e dns.qry.name

# Port suspect
tshark -r capture.pcap \
-Y "tcp.port == 4444"

# Exporter les fichiers HTTP
mkdir extracted

tshark -r capture.pcap \
--export-objects http,extracted/
```

---

# Méthode à mémoriser

Lorsqu'un PCAP est fourni, penser toujours :

```text
1. Qui communique ?
        ↓
2. Quels protocoles ?
        ↓
3. Qui scanne ?
        ↓
4. Quel service est ciblé ?
        ↓
5. Quel exploit est envoyé ?
        ↓
6. Une nouvelle connexion apparaît-elle ?
        ↓
7. Y a-t-il un shell ?
        ↓
8. Quelles commandes sont exécutées ?
        ↓
9. Quelles données sont recherchées ?
        ↓
10. Quelles données sortent ?
        ↓
11. Existe-t-il un C2 ?
        ↓
12. Quelle est la timeline complète ?
```

Cette méthodologie permet de passer d'un fichier contenant potentiellement des milliers ou millions de paquets à une reconstruction structurée de l'attaque.