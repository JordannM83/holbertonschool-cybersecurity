# Network Traffic Analysis — Wireshark & tcpdump

## Introduction

L’analyse du trafic réseau consiste à capturer et examiner les paquets qui circulent sur un réseau afin de comprendre les communications entre les machines.

Elle est essentielle en cybersécurité pour :

- comprendre le fonctionnement des protocoles réseau ;
- diagnostiquer des problèmes de communication ;
- détecter des comportements suspects ;
- analyser une attaque ;
- retrouver des machines compromises ;
- identifier des **Indicators of Compromise (IoC)** ;
- reconstruire une chronologie d’incident.

Les deux outils principaux abordés ici sont :

- **Wireshark** : analyse graphique des paquets ;
- **tcpdump** : capture et analyse en ligne de commande.

---

# 1. Modèle OSI et paquets Wireshark

Le modèle **OSI** divise les communications réseau en 7 couches :

| Couche | Nom | Exemples |
|---|---|---|
| 7 | Application | HTTP, DNS, FTP, SMTP |
| 6 | Présentation | TLS, encodage |
| 5 | Session | Gestion des sessions |
| 4 | Transport | TCP, UDP |
| 3 | Réseau | IPv4, IPv6, ICMP |
| 2 | Liaison | Ethernet, ARP |
| 1 | Physique | Câble, fibre, Wi-Fi |

Dans Wireshark, un paquet est généralement présenté comme une succession d’en-têtes correspondant à ces couches.

Exemple d'une requête HTTP :

```text
Ethernet II
└── Internet Protocol Version 4
    └── Transmission Control Protocol
        └── Hypertext Transfer Protocol
```

On peut donc faire la correspondance :

```text
Ethernet → Couche 2
IP       → Couche 3
TCP      → Couche 4
HTTP     → Couche 7
```

Un paquet est construit par **encapsulation** :

```text
[ Ethernet [ IP [ TCP [ HTTP Data ] ] ] ]
```

Chaque protocole ajoute son propre en-tête avant les données provenant de la couche supérieure.

---

# 2. Interface de Wireshark

L'interface principale de Wireshark est divisée en trois panneaux.

## Packet List

Le panneau supérieur affiche la liste des paquets :

```text
No.   Time       Source          Destination     Protocol
1     0.000      192.168.1.10    8.8.8.8         DNS
2     0.024      8.8.8.8         192.168.1.10    DNS
3     0.150      192.168.1.10    142.250.x.x     TCP
```

Il permet d'obtenir rapidement :

- source ;
- destination ;
- protocole ;
- taille ;
- informations principales.

## Packet Details

Le panneau central permet d'examiner les différentes couches du paquet.

```text
Ethernet II
Internet Protocol Version 4
Transmission Control Protocol
Hypertext Transfer Protocol
```

C'est généralement ici que l'on cherche les ports, adresses IP, flags TCP ou champs protocolaires.

## Packet Bytes

Le dernier panneau affiche les données brutes :

```text
0000  00 1a 2b 3c 4d 5e ...
0010  45 00 00 3c ...
```

Elles sont affichées en **hexadécimal** et en ASCII lorsque les octets correspondent à des caractères affichables.

---

# 3. Capture Filters et Display Filters

Wireshark possède deux systèmes de filtrage différents.

## Capture Filters — BPF

Les **Capture Filters** déterminent quels paquets seront enregistrés.

Ils utilisent la syntaxe **BPF — Berkeley Packet Filter**.

Exemple :

```bash
host 192.168.1.10
```

Capture uniquement le trafic concernant cette machine.

```bash
port 80
```

Capture le trafic utilisant le port 80.

```bash
tcp port 443
```

Capture uniquement TCP sur le port 443.

On peut combiner plusieurs conditions :

```bash
host 192.168.1.10 and tcp port 80
```

Les Capture Filters sont appliqués **avant ou pendant la capture**.

---

## Display Filters

Les **Display Filters** sont propres à Wireshark.

Ils servent à filtrer des paquets **déjà capturés**.

Exemple :

```text
ip.addr == 192.168.1.10
```

TCP uniquement :

```text
tcp
```

Port TCP 80 :

```text
tcp.port == 80
```

Trafic HTTP :

```text
http
```

Combinaison :

```text
ip.addr == 192.168.1.10 && tcp.port == 80
```

Différence fondamentale :

```text
Capture Filter
      ↓
Décide ce qui est enregistré

Display Filter
      ↓
Décide ce qui est affiché
```

---

# 4. Filtres Wireshark complexes

Les opérateurs principaux sont :

```text
==    égal
!=    différent
>     supérieur
<     inférieur
&&    AND
||    OR
!     NOT
```

Exemple :

```text
ip.src == 192.168.1.10 && tcp.dstport == 443
```

Cela signifie :

> afficher les paquets provenant de `192.168.1.10` et allant vers le port TCP 443.

Plusieurs IP :

```text
ip.addr == 192.168.1.10 || ip.addr == 192.168.1.20
```

Exclure DNS :

```text
!dns
```

SYN TCP :

```text
tcp.flags.syn == 1
```

SYN sans ACK :

```text
tcp.flags.syn == 1 && tcp.flags.ack == 0
```

Ces filtres deviennent particulièrement importants lorsqu'une capture contient plusieurs centaines de milliers de paquets.

---

# 5. Fonctionnement de TCP

TCP est un protocole **orienté connexion**.

Avant d'échanger les données, les machines établissent une connexion avec le **Three-Way Handshake**.

```text
Client                         Serveur

   -------- SYN -------->
   <----- SYN, ACK -------
   -------- ACK -------->

       Connexion établie
```

### SYN

Le client demande l'ouverture d'une connexion.

### SYN-ACK

Le serveur accepte et répond.

### ACK

Le client confirme.

La communication peut ensuite commencer.

---

# 6. Maintien d'une connexion TCP

TCP garantit notamment :

- l'ordre des données ;
- la détection des pertes ;
- la retransmission ;
- le contrôle de flux.

Les paquets utilisent des **Sequence Numbers** et des **Acknowledgment Numbers**.

Exemple simplifié :

```text
Client → Seq 1000 → Serveur
Client ← Ack 1001 ← Serveur
```

Si un segment n'arrive pas correctement, TCP peut le retransmettre.

Wireshark peut alors afficher des indications telles que :

```text
TCP Retransmission
Duplicate ACK
Out-of-Order
```

Ces informations peuvent être utiles pour diagnostiquer des problèmes réseau.

---

# 7. Fermeture d'une connexion TCP

Une fermeture normale utilise généralement les flags `FIN` et `ACK`.

```text
Client                     Serveur

   ------- FIN ------->
   <------ ACK --------
   <------ FIN --------
   ------- ACK ------->
```

Une connexion peut également être interrompue brutalement avec :

```text
RST
```

RST signifie **Reset**.

---

# 8. UDP

UDP fonctionne différemment de TCP.

Il est **sans connexion**.

Il n'existe donc pas de :

```text
SYN
SYN-ACK
ACK
```

avant l'envoi des données.

Le client envoie directement :

```text
Client -------- UDP --------> Serveur
```

Cela rend UDP :

- rapide ;
- simple ;
- avec moins d'overhead ;
- mais sans garantie de livraison fournie par UDP lui-même.

UDP est notamment utilisé par :

- DNS ;
- DHCP ;
- VoIP ;
- certains jeux ;
- certains services de streaming.

---

# 9. TCP vs UDP pour le scanning

Cette différence change fortement la manière d'identifier un scan.

Pour TCP, l'état d'un port peut souvent être déduit des flags retournés.

Exemple :

```text
Scanner → SYN → Serveur
Scanner ← SYN-ACK ← Serveur
```

Cela indique généralement qu'un service TCP accepte les connexions sur ce port.

Avec UDP, il n'existe pas de handshake équivalent.

Un scanner peut envoyer :

```text
Scanner → UDP → Serveur
```

et ne recevoir aucune réponse.

Cette absence de réponse est ambiguë : elle ne suffit pas toujours à déterminer immédiatement l'état du port.

---

# 10. DNS au niveau paquet

DNS transforme un nom de domaine en information DNS, notamment une adresse IP.

Exemple :

```text
www.example.com
        ↓
93.184.216.34
```

Une résolution classique ressemble à :

```text
Client → DNS Query → DNS Server
Client ← DNS Response ← DNS Server
```

Dans Wireshark :

```text
dns
```

Une requête peut contenir :

```text
Queries
    Name: example.com
    Type: A
```

Une réponse :

```text
Answers
    Name: example.com
    Type: A
    Address: 93.184.216.34
```

Quelques types d'enregistrements importants :

| Type | Fonction |
|---|---|
| A | Adresse IPv4 |
| AAAA | Adresse IPv6 |
| MX | Serveur mail |
| CNAME | Alias |
| NS | Serveur DNS |
| TXT | Texte / informations diverses |

L'analyse DNS est très importante car elle permet notamment d'observer quels domaines une machine cherche à contacter.

---

# 11. ARP

ARP signifie **Address Resolution Protocol**.

Sur un réseau IPv4 local, ARP permet d'associer une adresse IPv4 à une adresse MAC.

Exemple :

```text
Who has 192.168.1.1?
Tell 192.168.1.20
```

Réponse :

```text
192.168.1.1 is at AA:BB:CC:DD:EE:FF
```

Filtre Wireshark :

```text
arp
```

ARP est particulièrement intéressant pour comprendre :

- les communications locales ;
- les passerelles ;
- les changements d'adresse MAC ;
- certains comportements anormaux sur un LAN.

---

# 12. Protocoles non chiffrés et credentials

Certains anciens protocoles transmettent leurs informations sans chiffrement.

Par exemple, selon leur configuration :

```text
HTTP
FTP
Telnet
POP3
```

peuvent exposer des informations sensibles directement dans le trafic.

Dans une capture de laboratoire autorisée, on pourrait donc observer des données applicatives en clair.

Le problème est simple :

```text
Client → username/password → Serveur
```

Une personne capable d'observer le trafic pourrait potentiellement lire ces informations.

---

# 13. Pourquoi le chiffrement protège les données

Avec TLS, les données applicatives sont chiffrées.

Au lieu d'observer directement :

```text
username=alice&password=example
```

la capture contient principalement des données chiffrées :

```text
TLS Application Data
```

C'est notamment ce qui différencie :

```text
HTTP
```

de :

```text
HTTPS = HTTP protégé par TLS
```

Le chiffrement vise à empêcher un observateur réseau de lire directement le contenu des communications.

---

# 14. Wireshark Statistics

Lorsqu'une capture est très grande, analyser les paquets un par un est inefficace.

Wireshark fournit plusieurs vues statistiques.

Dans :

```text
Statistics
```

on trouve notamment :

```text
Protocol Hierarchy
Conversations
Endpoints
I/O Graphs
```

### Protocol Hierarchy

Permet de voir rapidement quels protocoles dominent la capture.

### Endpoints

Permet d'identifier les machines présentes :

```text
192.168.1.10
192.168.1.15
10.10.10.5
```

### Conversations

Montre quelles machines communiquent entre elles.

Cela permet de répondre rapidement à :

> Qui parle avec qui ?

### I/O Graphs

Permet d'observer l'évolution du trafic dans le temps et de repérer des pics ou périodes particulières.

---

# 15. Follow TCP Stream

Une fonctionnalité essentielle de Wireshark est :

```text
Follow → TCP Stream
```

Elle permet de reconstruire une conversation TCP.

Au lieu d'analyser :

```text
Packet 10
Packet 14
Packet 17
Packet 22
```

Wireshark reconstitue les données appartenant à la même communication.

Par exemple, dans un laboratoire HTTP :

```text
GET /index.html HTTP/1.1
Host: example.local
```

puis :

```text
HTTP/1.1 200 OK
Content-Type: text/html
```

Cela permet de comprendre beaucoup plus rapidement ce que les deux machines se sont échangé.

---

# 16. Extraction de données dans une capture

Dans une capture de laboratoire contenant du trafic non chiffré, Wireshark peut permettre de reconstruire certaines données applicatives.

Selon le protocole, on peut utiliser :

```text
File
→ Export Objects
```

Par exemple, pour certains échanges HTTP.

Cette technique est utile en investigation afin de déterminer quels fichiers ont été transférés.

Pour les données textuelles, **Follow TCP Stream** peut également permettre de reconstruire les échanges applicatifs.

Ces manipulations doivent être effectuées uniquement sur des captures et systèmes pour lesquels on dispose d'une autorisation.

---

# 17. tcpdump

`tcpdump` permet de capturer du trafic directement depuis le terminal.

Afficher les interfaces :

```bash
tcpdump -D
```

Capturer sur une interface :

```bash
sudo tcpdump -i eth0
```

Ne pas résoudre les noms :

```bash
sudo tcpdump -n -i eth0
```

Filtrer une machine :

```bash
sudo tcpdump -i eth0 host 192.168.1.10
```

Filtrer TCP :

```bash
sudo tcpdump -i eth0 tcp
```

Filtrer un port :

```bash
sudo tcpdump -i eth0 port 80
```

Combiner :

```bash
sudo tcpdump -i eth0 'host 192.168.1.10 and tcp port 80'
```

---

# 18. Sauvegarder une capture avec tcpdump

Pour enregistrer les paquets dans un fichier :

```bash
sudo tcpdump -i eth0 -w capture.pcap
```

Le fichier pourra ensuite être ouvert avec Wireshark.

Pour lire un fichier :

```bash
tcpdump -r capture.pcap
```

Avec un filtre :

```bash
tcpdump -r capture.pcap 'tcp port 80'
```

Une méthode courante est donc :

```text
Serveur / terminal
       ↓
    tcpdump
       ↓
capture.pcap
       ↓
   Wireshark
       ↓
Analyse approfondie
```

---

# 19. Reconnaître un scan SYN

Un **SYN Scan** repose sur l'observation du début du handshake TCP.

Dans une capture, on peut rechercher les SYN initiaux :

```text
tcp.flags.syn == 1 && tcp.flags.ack == 0
```

Un comportement suspect peut ressembler à :

```text
10.0.0.5 → 10.0.0.20:21 SYN
10.0.0.5 → 10.0.0.20:22 SYN
10.0.0.5 → 10.0.0.20:23 SYN
10.0.0.5 → 10.0.0.20:25 SYN
10.0.0.5 → 10.0.0.20:80 SYN
10.0.0.5 → 10.0.0.20:443 SYN
```

Une même source tente donc rapidement de contacter de nombreux ports.

Ce comportement constitue un indicateur typique d'une activité de reconnaissance, même s'il faut toujours tenir compte du contexte.

---

# 20. SYN Scan vs TCP Connect Scan

Un **SYN Scan** ne complète généralement pas une connexion TCP normale.

Pattern simplifié :

```text
Scanner → SYN
Target  → SYN-ACK
Scanner → RST
```

Un **TCP Connect Scan** effectue au contraire le handshake complet :

```text
Scanner → SYN
Target  → SYN-ACK
Scanner → ACK
```

Puis la connexion est rapidement terminée.

La différence essentielle est donc :

```text
SYN Scan
→ handshake incomplet

Connect Scan
→ handshake complet
```

---

# 21. UDP Scan

Un scan UDP produit un pattern différent puisque UDP ne possède pas de flags SYN/ACK.

On peut observer :

```text
Scanner → UDP port 53
Scanner → UDP port 67
Scanner → UDP port 123
Scanner → UDP port 161
```

Certaines situations peuvent provoquer une réponse ICMP, par exemple lorsqu'un port UDP est inaccessible.

Un grand nombre de paquets UDP envoyés vers différents ports d'une même machine peut donc être un indicateur de scan.

---

# 22. Initial Triage

Lorsqu'un analyste reçoit une capture de plusieurs gigaoctets, il ne commence pas par lire le paquet numéro 1.

Il effectue un **triage initial**.

Une bonne méthodologie est :

```text
1. Identifier la durée de la capture
        ↓
2. Identifier les protocoles
        ↓
3. Identifier les endpoints
        ↓
4. Examiner les conversations
        ↓
5. Chercher les anomalies
        ↓
6. Appliquer des filtres
        ↓
7. Reconstruire les communications intéressantes
```

Commencer notamment par :

```text
Statistics → Protocol Hierarchy
Statistics → Endpoints
Statistics → Conversations
```

Cette approche réduit énormément la quantité de trafic à examiner manuellement.

---

# 23. Trafic légitime ou malveillant ?

Un paquet isolé est rarement suffisant pour déterminer qu'une activité est malveillante.

Il faut analyser le **contexte**.

Par exemple :

```text
192.168.1.20 → TCP 443 → Internet
```

est extrêmement courant.

En revanche :

```text
192.168.1.20
→ centaines d'IP
→ centaines de ports
→ quelques secondes
```

peut nécessiter une investigation.

On recherche donc des anomalies telles que :

- nombre inhabituel de connexions ;
- ports inhabituels ;
- nombreux SYN ;
- communications répétitives ;
- domaines inconnus ;
- volumes anormaux ;
- transferts inhabituels ;
- communications vers des machines inattendues.

Un comportement inhabituel n'est cependant pas automatiquement une attaque.

---

# 24. Construire une timeline d'attaque

Une analyse réseau doit permettre de reconstruire les événements dans l'ordre.

Exemple fictif :

```text
10:31:02 → Résolution DNS d'un domaine
10:31:03 → Connexion TCP
10:31:03 → Requête HTTP
10:31:05 → Téléchargement d'un fichier
10:32:40 → Nouvelle connexion vers une IP externe
10:33:01 → Trafic périodique vers cette IP
```

Cette chronologie permet de comprendre :

```text
Que s'est-il passé ?
        ↓
Quelle machine est impliquée ?
        ↓
Quand l'activité a-t-elle commencé ?
        ↓
Quels systèmes ont été contactés ?
        ↓
Quelles données ont été échangées ?
```

Toujours conserver les timestamps lors d'une investigation.

---

# 25. Indicators of Compromise

Un **Indicator of Compromise (IoC)** est une information exploitable pouvant aider à identifier une activité malveillante.

Exemples :

```text
Adresse IP
Nom de domaine
URL
Hash de fichier
Nom de fichier
Port inhabituel
Adresse MAC dans certains contextes locaux
```

Exemple de rapport :

```text
Source:
192.168.1.42

Destination:
203.0.113.50

Destination Port:
4444/TCP

First Seen:
14:32:17

Domain:
example-malicious.test

Transferred File:
update.bin
```

L'objectif n'est pas seulement de trouver quelque chose de suspect, mais de produire des informations permettant à d'autres outils ou analystes de poursuivre l'investigation.

---

# 26. Méthodologie complète d'analyse

Une analyse Wireshark professionnelle peut suivre cette logique :

```text
CAPTURE
   │
   ▼
Protocol Hierarchy
   │
   ▼
Endpoints
   │
   ▼
Conversations
   │
   ▼
Identifier les anomalies
   │
   ▼
Display Filters
   │
   ▼
Analyse TCP / UDP / DNS / ARP
   │
   ▼
Follow TCP Stream
   │
   ▼
Reconstruction des événements
   │
   ▼
Extraction des IoC
   │
   ▼
TIMELINE + CONCLUSION
```

---

# 27. Filtres Wireshark à connaître

Afficher une IP :

```text
ip.addr == 192.168.1.10
```

Source uniquement :

```text
ip.src == 192.168.1.10
```

Destination :

```text
ip.dst == 192.168.1.10
```

TCP :

```text
tcp
```

UDP :

```text
udp
```

DNS :

```text
dns
```

ARP :

```text
arp
```

HTTP :

```text
http
```

SYN :

```text
tcp.flags.syn == 1
```

SYN sans ACK :

```text
tcp.flags.syn == 1 && tcp.flags.ack == 0
```

RST :

```text
tcp.flags.reset == 1
```

Port :

```text
tcp.port == 443
```

Combinaison :

```text
ip.src == 192.168.1.10 && tcp.dstport == 443
```

---

# 28. Commandes tcpdump à connaître

Capture classique :

```bash
sudo tcpdump -i eth0
```

Sans résolution DNS :

```bash
sudo tcpdump -n -i eth0
```

TCP :

```bash
sudo tcpdump -i eth0 tcp
```

UDP :

```bash
sudo tcpdump -i eth0 udp
```

Une IP :

```bash
sudo tcpdump -i eth0 host 192.168.1.10
```

Une source :

```bash
sudo tcpdump -i eth0 src host 192.168.1.10
```

Une destination :

```bash
sudo tcpdump -i eth0 dst host 192.168.1.10
```

Un port :

```bash
sudo tcpdump -i eth0 port 443
```

Sauvegarder :

```bash
sudo tcpdump -i eth0 -w capture.pcap
```

Lire :

```bash
tcpdump -r capture.pcap
```

---

# 29. Points essentiels à retenir

### OSI

Un paquet Wireshark représente plusieurs couches encapsulées :

```text
Ethernet → IP → TCP/UDP → Application
```

### Capture Filter

Utilise **BPF** et sélectionne les paquets à capturer.

```bash
tcp port 80
```

### Display Filter

Utilise la syntaxe Wireshark et filtre les paquets déjà présents.

```text
tcp.port == 80
```

### TCP

TCP utilise un handshake :

```text
SYN → SYN-ACK → ACK
```

et fournit des mécanismes de suivi, d'ordre et de retransmission.

### UDP

UDP est sans connexion et ne possède pas de handshake TCP.

### DNS

DNS permet notamment de transformer :

```text
Nom de domaine → Adresse IP
```

### ARP

ARP permet sur un LAN IPv4 de faire l'association :

```text
IPv4 → MAC
```

### Wireshark

Pour une première analyse :

```text
Protocol Hierarchy
Endpoints
Conversations
Filters
Follow TCP Stream
```

### Scanning

Patterns typiques :

```text
SYN Scan
SYN → SYN-ACK → RST

TCP Connect
SYN → SYN-ACK → ACK

UDP Scan
UDP → réponse UDP / ICMP / aucune réponse
```

### Investigation

Une analyse efficace suit généralement :

```text
Triage
  ↓
Filtrage
  ↓
Analyse
  ↓
Reconstruction
  ↓
Timeline
  ↓
IoC
```

---

# Conclusion

Wireshark ne consiste pas simplement à regarder des paquets individuellement. Une bonne analyse réseau consiste à comprendre les relations entre les protocoles, les machines et les événements.

Il faut être capable de passer d'une capture contenant potentiellement des milliers ou millions de paquets à une compréhension structurée :

```text
Qui communique ?
        ↓
Avec qui ?
        ↓
Avec quel protocole ?
        ↓
Sur quel port ?
        ↓
À quel moment ?
        ↓
Quel contenu ou comportement est observable ?
        ↓
Est-ce cohérent avec l'activité attendue ?
        ↓
Quels IoC peut-on extraire ?
```

La maîtrise de **TCP, UDP, DNS, ARP, BPF, des Display Filters, des statistiques Wireshark, des TCP Streams et de tcpdump** fournit ainsi les bases nécessaires pour analyser efficacement une capture réseau et commencer une investigation de sécurité.