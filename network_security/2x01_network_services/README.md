# DNS & DHCP Fundamentals

## Introduction

DNS et DHCP sont deux services essentiels au fonctionnement d'un réseau.

- **DNS (Domain Name System)** permet principalement de traduire des noms de domaine en adresses IP.
- **DHCP (Dynamic Host Configuration Protocol)** permet d'attribuer automatiquement une configuration réseau à une machine.

Exemple :

```text
DHCP → "Quelle IP, gateway et DNS dois-je utiliser ?"
DNS  → "Quelle est l'adresse IP de example.com ?"
```

---

# 1. DNS Fundamentals

## Qu'est-ce que DNS ?

DNS signifie **Domain Name System**.

Les ordinateurs communiquent avec des adresses IP, mais les humains utilisent plus facilement des noms de domaine.

Par exemple :

```text
example.com → 93.184.216.34
```

DNS permet donc de faire la correspondance entre un nom et différentes informations, notamment une adresse IP.

On peut effectuer une requête DNS avec :

```bash
dig example.com
```

ou :

```bash
nslookup example.com
```

---

# 2. Recursive vs Iterative DNS Queries

## Recursive Query

Dans une requête récursive, le client demande au serveur DNS de trouver la réponse finale.

```text
Client
  |
  | "Quelle est l'IP de example.com ?"
  v
DNS Resolver
  |
  | effectue les recherches
  v
Réponse finale
```

Le client ne fait donc pas lui-même toutes les requêtes.

Il demande simplement :

```text
"Donne-moi la réponse finale."
```

## Iterative Query

Dans une requête itérative, chaque serveur peut indiquer au demandeur quel autre serveur interroger.

Exemple :

```text
Resolver
   |
   v
Root Server
   |
   | "Demande au serveur .com"
   v
TLD .com
   |
   | "Demande au serveur de example.com"
   v
Authoritative Server
   |
   | "example.com = x.x.x.x"
   v
Resolver
```

À retenir :

```text
Recursive = donne-moi la réponse finale.

Iterative = donne-moi la meilleure information que tu as
            ou indique-moi où continuer.
```

---

# 3. DNS Hierarchy

DNS possède une structure hiérarchique.

Pour :

```text
www.example.com
```

on peut représenter la hiérarchie ainsi :

```text
        Root "."
           |
          com
           |
        example
           |
          www
```

Les trois niveaux importants sont :

```text
Root Servers
     |
TLD Servers
     |
Authoritative Servers
```

---

## Root Servers

Les **Root Servers** sont au sommet de la hiérarchie DNS.

Ils permettent notamment de trouver les serveurs responsables des TLD.

```text
.
├── com
├── fr
├── org
├── net
└── io
```

Un Root Server ne donne pas nécessairement directement l'adresse IP finale.

Il peut répondre :

```text
"Pour .com, demande à ces serveurs."
```

---

## TLD Servers

TLD signifie :

```text
Top-Level Domain
```

Exemples :

```text
.com
.fr
.org
.net
.io
```

Pour rechercher :

```text
example.com
```

les serveurs `.com` permettent de trouver les serveurs DNS autoritaires responsables de `example.com`.

---

## Authoritative DNS Server

Le serveur **Authoritative DNS** possède les informations officielles de la zone DNS dont il est responsable.

Par exemple :

```text
example.com → 192.0.2.10
```

Le processus simplifié est donc :

```text
Client
  |
  v
DNS Resolver
  |
  v
Root Server
  |
  v
TLD Server
  |
  v
Authoritative Server
  |
  v
Réponse
```

---

# 4. DNS Record Types

DNS utilise différents types d'enregistrements.

## A Record

Un record `A` associe un nom de domaine à une adresse **IPv4**.

```text
example.com → 192.0.2.10
```

Commande :

```bash
dig A example.com
```

---

## AAAA Record

Un record `AAAA` associe un nom à une adresse **IPv6**.

```text
example.com → 2001:db8::10
```

Commande :

```bash
dig AAAA example.com
```

---

## CNAME Record

CNAME signifie :

```text
Canonical Name
```

Il permet de créer un alias vers un autre nom.

Exemple :

```text
www.example.com → example.com
```

Commande :

```bash
dig CNAME www.example.com
```

---

## MX Record

MX signifie :

```text
Mail Exchange
```

Il indique quels serveurs reçoivent les emails d'un domaine.

Exemple :

```text
example.com → mail.example.com
```

Commande :

```bash
dig MX example.com
```

Les MX peuvent avoir des priorités :

```text
10 mail1.example.com
20 mail2.example.com
```

Une valeur plus petite représente généralement une priorité plus élevée.

---

## TXT Record

Un record `TXT` permet de stocker du texte dans DNS.

Il est notamment utilisé pour :

- SPF
- validation de domaine
- politiques de sécurité email

Commande :

```bash
dig TXT example.com
```

---

## PTR Record

Un record `PTR` est principalement utilisé pour le **Reverse DNS**.

DNS classique :

```text
Domain → IP
```

Reverse DNS :

```text
IP → Domain
```

Commande :

```bash
dig -x 8.8.8.8
```

---

## SOA Record

SOA signifie :

```text
Start Of Authority
```

Il contient des informations importantes concernant une zone DNS.

Par exemple :

```text
Primary DNS
Responsible contact
Serial
Refresh
Retry
Expire
```

Commande :

```bash
dig SOA example.com
```

---

## NS Record

NS signifie :

```text
Name Server
```

Il indique les serveurs DNS responsables d'un domaine.

Commande :

```bash
dig NS example.com
```

Exemple :

```text
example.com
    |
    ├── ns1.example.net
    └── ns2.example.net
```

---

# 5. DNS TTL

TTL signifie :

```text
Time To Live
```

Le TTL indique pendant combien de temps une information DNS peut rester dans un cache avant d'expirer.

Exemple :

```text
example.com. 3600 IN A 192.0.2.10
```

Ici :

```text
TTL = 3600 secondes
TTL = 1 heure
```

---

# 6. DNS Caching

Sans cache, le resolver devrait régulièrement refaire les différentes recherches DNS.

```text
Client
  |
Resolver
  |
Root
  |
TLD
  |
Authoritative
```

Avec un cache :

```text
Client
  |
Resolver
  |
Cache
  |
Réponse
```

Le cache permet :

- d'accélérer les requêtes ;
- de réduire le trafic réseau ;
- de réduire la charge des serveurs DNS.

Un TTL élevé signifie généralement :

```text
+ Moins de requêtes DNS
+ Cache plus long
- Changements DNS potentiellement plus longs à être observés
```

Un TTL faible signifie :

```text
+ Changements observables plus rapidement
- Plus de requêtes DNS
```

---

# 7. /etc/hosts

Linux possède un fichier local :

```text
/etc/hosts
```

Exemple :

```text
127.0.0.1 localhost
192.168.1.50 server.local
```

Pour le consulter :

```bash
cat /etc/hosts
```

Selon la configuration Linux, `/etc/hosts` peut être consulté avant DNS.

L'ordre peut être défini dans :

```text
/etc/nsswitch.conf
```

Exemple :

```text
hosts: files dns
```

Cela signifie :

```text
1. Chercher dans les fichiers locaux
2. Chercher avec DNS
```

---

# 8. Pourquoi les malwares peuvent modifier /etc/hosts ?

Un malware peut tenter de modifier `/etc/hosts` pour rediriger un domaine.

Exemple :

```text
203.0.113.50 bank.example
```

La machine pourrait alors résoudre :

```text
bank.example
```

vers :

```text
203.0.113.50
```

au lieu d'utiliser la réponse DNS normale.

Cela peut être utilisé pour rediriger un utilisateur vers une machine contrôlée par un attaquant.

---

# 9. SPF

SPF signifie :

```text
Sender Policy Framework
```

SPF permet à un domaine de déclarer quels serveurs sont autorisés à envoyer des emails pour ce domaine.

SPF est généralement publié dans un record DNS `TXT`.

Exemple :

```text
v=spf1 ip4:192.0.2.10 -all
```

Cela signifie conceptuellement :

```text
192.0.2.10 est autorisé à envoyer des emails pour ce domaine.

Les autres serveurs ne sont pas autorisés selon cette politique.
```

Pour rechercher un SPF :

```bash
dig TXT example.com
```

SPF aide à lutter contre l'**email spoofing**.

En pratique, la sécurité email utilise souvent :

```text
SPF
DKIM
DMARC
```

---

# 10. DNS Zone Transfer

Une zone DNS peut contenir de nombreux records :

```text
A
AAAA
CNAME
MX
TXT
NS
PTR
```

Les serveurs DNS utilisent des mécanismes de transfert pour synchroniser certaines zones.

Deux types importants sont :

```text
AXFR = transfert complet
IXFR = transfert incrémental
```

---

## Risque de sécurité

Si un serveur DNS autorise un transfert de zone à n'importe qui, des informations sur l'infrastructure peuvent être exposées.

Par exemple :

```text
vpn.example.com
mail.example.com
dev.example.com
database.example.com
internal.example.com
```

Ces informations peuvent faciliter la phase de reconnaissance d'une attaque.

Les transferts de zone doivent donc être limités aux serveurs autorisés.

---

# 11. dig

`dig` est un outil très utilisé pour effectuer des requêtes DNS.

Requête classique :

```bash
dig example.com
```

Rechercher une IPv4 :

```bash
dig A example.com
```

Rechercher une IPv6 :

```bash
dig AAAA example.com
```

Rechercher les serveurs mail :

```bash
dig MX example.com
```

Rechercher les Name Servers :

```bash
dig NS example.com
```

Rechercher les TXT :

```bash
dig TXT example.com
```

Rechercher le SOA :

```bash
dig SOA example.com
```

---

## dig +short

Pour afficher uniquement une réponse courte :

```bash
dig +short example.com
```

Exemple :

```text
93.184.216.34
```

---

# 12. Query a Specific DNS Server

Par défaut, `dig` utilise le resolver DNS configuré sur la machine.

On peut choisir directement un serveur DNS avec :

```bash
dig @DNS_SERVER DOMAIN
```

Exemple :

```bash
dig @8.8.8.8 example.com
```

On peut également préciser le type :

```bash
dig @8.8.8.8 example.com A
```

Cela permet de comparer les réponses de différents serveurs DNS.

---

# 13. nslookup

`nslookup` permet également de faire des recherches DNS.

Exemple :

```bash
nslookup example.com
```

Avec un serveur spécifique :

```bash
nslookup example.com 8.8.8.8
```

---

## Mode interactif

Lancer :

```bash
nslookup
```

Puis sélectionner un serveur :

```text
server 8.8.8.8
```

Faire une recherche :

```text
example.com
```

Changer le type :

```text
set type=MX
```

Puis :

```text
example.com
```

---

# 14. Reverse DNS Lookup

Une recherche DNS normale fait :

```text
Domain → IP
```

Une recherche Reverse DNS fait :

```text
IP → Domain
```

On utilise principalement les records :

```text
PTR
```

Avec `dig` :

```bash
dig -x 8.8.8.8
```

Pour IPv4, les recherches inverses utilisent :

```text
in-addr.arpa
```

---

# 15. /etc/resolv.conf

Sous Linux, le fichier :

```text
/etc/resolv.conf
```

contient traditionnellement les informations concernant les serveurs DNS utilisés par la machine.

Pour le consulter :

```bash
cat /etc/resolv.conf
```

Exemple :

```text
nameserver 192.168.1.1
nameserver 1.1.1.1
```

On peut également trouver :

```text
search example.local
```

Sur certaines distributions modernes, ce fichier peut être géré automatiquement par :

```text
NetworkManager
systemd-resolved
```

On peut également utiliser :

```bash
resolvectl status
```

pour examiner la configuration DNS sur les systèmes compatibles.

---

# 16. DHCP Fundamentals

DHCP signifie :

```text
Dynamic Host Configuration Protocol
```

DHCP permet d'attribuer automatiquement une configuration réseau aux machines.

Sans DHCP, il faudrait configurer manuellement :

```text
IP Address
Subnet Mask
Default Gateway
DNS Server
```

Avec DHCP :

```text
Client
  |
  v
DHCP Server
  |
  v
Configuration réseau
```

---

# 17. Informations fournies par DHCP

Un serveur DHCP peut fournir :

```text
IP Address
Subnet Mask
Default Gateway
DNS Server
Lease Time
```

Exemple :

```text
IP        : 192.168.1.15
Mask      : 255.255.255.0
Gateway   : 192.168.1.1
DNS       : 192.168.1.1
Lease     : 86400 secondes
```

---

# 18. DHCP DORA

Lorsqu'une machine rejoint un réseau, DHCP utilise généralement le processus :

```text
DORA
```

qui signifie :

```text
D = Discover
O = Offer
R = Request
A = Acknowledge
```

---

## DHCP Discover

Le client recherche un serveur DHCP.

```text
Client
   |
   | DHCP DISCOVER
   v
Network
```

---

## DHCP Offer

Le serveur DHCP propose une configuration.

```text
DHCP Server
     |
     | DHCP OFFER
     v
Client
```

Par exemple :

```text
IP proposée : 192.168.1.15
```

---

## DHCP Request

Le client demande officiellement la configuration proposée.

```text
Client
   |
   | DHCP REQUEST
   v
DHCP Server
```

---

## DHCP Acknowledge

Le serveur confirme l'attribution.

```text
DHCP Server
     |
     | DHCP ACK
     v
Client
```

Le processus complet :

```text
CLIENT                         DHCP SERVER

   | ----- DISCOVER ---------> |
   |                           |
   | <------ OFFER ----------- |
   |                           |
   | ------- REQUEST --------> |
   |                           |
   | <-------- ACK ----------- |
```

À retenir :

```text
Discover → "Y a-t-il un serveur DHCP ?"

Offer    → "Je te propose cette configuration."

Request  → "Je demande cette configuration."

ACK      → "Configuration acceptée."
```

---

# 19. DHCP Lease

Une adresse IP obtenue par DHCP n'est généralement pas attribuée définitivement.

Elle possède une durée appelée :

```text
Lease Time
```

ou :

```text
Bail DHCP
```

Exemple :

```text
Lease Time = 86400 secondes
```

soit :

```text
24 heures
```

Le client doit renouveler son bail selon le fonctionnement de DHCP.

---

# 20. DHCP Lease Files sous Linux

L'emplacement des informations DHCP dépend du système et du client DHCP utilisé.

On peut notamment rencontrer :

```text
/var/lib/dhcp/
```

Par exemple :

```text
/var/lib/dhcp/dhclient.leases
```

Pour chercher des fichiers contenant des leases :

```bash
find /var/lib -iname '*lease*' 2>/dev/null
```

Attention : ce chemin n'est pas universel.

Les distributions modernes peuvent utiliser :

```text
NetworkManager
systemd-networkd
dhclient
```

et stocker les informations à différents endroits.

---

# 21. Rogue DHCP

Un **Rogue DHCP Server** est un serveur DHCP non autorisé présent sur un réseau.

Exemple :

```text
             DHCP légitime
                  |
                  |
Client -------- Network
                  |
                  |
             Rogue DHCP
```

Le Rogue DHCP peut envoyer une configuration malveillante.

Par exemple :

```text
IP      → 192.168.1.50
Gateway → IP de l'attaquant
DNS     → DNS contrôlé par l'attaquant
```

Cela peut permettre :

```text
Redirection du trafic
Man-in-the-Middle
DNS malveillant
Interception
Déni de service
```

Une protection courante sur les switches professionnels est :

```text
DHCP Snooping
```

Elle permet de distinguer les ports autorisés à fournir des réponses DHCP.

---

# 22. Commandes importantes

## DNS classique

```bash
dig example.com
```

## IPv4

```bash
dig A example.com
```

## IPv6

```bash
dig AAAA example.com
```

## Mail

```bash
dig MX example.com
```

## Name Servers

```bash
dig NS example.com
```

## TXT / SPF

```bash
dig TXT example.com
```

## SOA

```bash
dig SOA example.com
```

## Réponse courte

```bash
dig +short example.com
```

## Reverse DNS

```bash
dig -x 8.8.8.8
```

## DNS spécifique

```bash
dig @8.8.8.8 example.com
```

## nslookup

```bash
nslookup example.com
```

## nslookup avec serveur spécifique

```bash
nslookup example.com 8.8.8.8
```

## Voir les DNS configurés

```bash
cat /etc/resolv.conf
```

## Voir /etc/hosts

```bash
cat /etc/hosts
```

## Voir l'ordre de résolution

```bash
grep '^hosts:' /etc/nsswitch.conf
```

## Chercher les leases DHCP

```bash
find /var/lib -iname '*lease*' 2>/dev/null
```

---

# 23. Résumé DNS

```text
DNS
│
├── Recursive Query
│   └── Le resolver cherche la réponse finale
│
├── Iterative Query
│   └── Les serveurs indiquent où continuer
│
├── Hierarchy
│   ├── Root
│   ├── TLD
│   └── Authoritative
│
├── Records
│   ├── A      → IPv4
│   ├── AAAA   → IPv6
│   ├── CNAME  → Alias
│   ├── MX     → Mail
│   ├── TXT    → Texte / SPF
│   ├── PTR    → Reverse DNS
│   ├── SOA    → Informations de zone
│   └── NS     → Name Servers
│
├── TTL
│   └── Durée de conservation en cache
│
├── /etc/hosts
│   └── Résolution locale
│
├── Zone Transfer
│   ├── AXFR → complet
│   └── IXFR → incrémental
│
└── Outils
    ├── dig
    └── nslookup
```

---

# 24. Résumé DHCP

```text
DHCP
│
├── Fournit
│   ├── IP Address
│   ├── Subnet Mask
│   ├── Default Gateway
│   ├── DNS Server
│   └── Lease Time
│
├── DORA
│   ├── Discover
│   ├── Offer
│   ├── Request
│   └── Acknowledge
│
├── Lease
│   └── Attribution temporaire d'une IP
│
└── Rogue DHCP
    └── Serveur DHCP non autorisé
```

---

# 25. Points essentiels à retenir

## DNS

```text
DNS = Domain Name System
```

Il permet principalement de résoudre :

```text
Nom de domaine → Adresse IP
```

## Recursive vs Iterative

```text
Recursive → "Trouve-moi la réponse finale."

Iterative → "Donne-moi la réponse ou indique-moi où chercher."
```

## Hiérarchie DNS

```text
Root → TLD → Authoritative
```

## Records

```text
A      = IPv4
AAAA   = IPv6
CNAME  = Alias
MX     = Mail
TXT    = Texte / SPF
PTR    = Reverse DNS
SOA    = Informations principales de la zone
NS     = Serveurs DNS autoritaires
```

## TTL

```text
TTL = durée pendant laquelle une réponse DNS peut rester en cache.
```

## /etc/hosts

```text
/etc/hosts = résolution locale pouvant être prioritaire sur DNS
             selon la configuration du système.
```

## SPF

```text
SPF = indique quelles sources sont autorisées
      à envoyer des emails pour un domaine.
```

## Zone Transfer

```text
AXFR = transfert complet
IXFR = transfert incrémental
```

Une mauvaise configuration peut exposer des informations sur l'infrastructure DNS.

## DHCP

```text
DHCP = configuration réseau automatique.
```

Il peut fournir :

```text
IP
Mask
Gateway
DNS
Lease Time
```

## DORA

```text
Discover
   ↓
Offer
   ↓
Request
   ↓
Acknowledge
```

## Rogue DHCP

```text
Rogue DHCP = serveur DHCP non autorisé pouvant fournir
             une configuration réseau malveillante.
```

## Reverse DNS

```text
Normal DNS  : Domain → IP
Reverse DNS : IP → Domain
```

Commande :

```bash
dig -x IP
```

## Interroger un DNS spécifique

```bash
dig @DNS_SERVER DOMAIN
```

Exemple :

```bash
dig @8.8.8.8 example.com
```