# Proxy Architecture, Squid ACLs, Content Filtering & TLS Inspection

## Introduction

Un proxy est un serveur intermédiaire placé entre un client et une destination réseau.

Dans un environnement d’entreprise, un proxy peut être utilisé pour :

- contrôler l’accès à Internet ;
- filtrer certains domaines ;
- bloquer certains types de fichiers ;
- journaliser les requêtes ;
- appliquer des politiques de sécurité ;
- limiter certains usages ;
- observer les connexions HTTP et HTTPS ;
- compléter un firewall dans une stratégie de défense en profondeur.

Dans ce projet, l’outil principal est :

```text
Squid
```

Squid est un proxy HTTP très utilisé sous Linux.

---

# 1. Proxy Architecture

## 1.1 Qu’est-ce qu’un proxy ?

Sans proxy :

```text
Client
   |
   v
Internet
```

Avec proxy :

```text
Client
   |
   v
Proxy
   |
   v
Internet
```

Le client ne contacte plus directement le serveur distant.

Il contacte d’abord le proxy.

Le proxy reçoit la requête, applique ses règles, puis contacte éventuellement la destination.

---

# 2. Forward Proxy

Un :

```text
Forward Proxy
```

est placé du côté des clients.

Architecture :

```text
Client
   |
   v
Forward Proxy
   |
   v
Internet
```

Le proxy représente les clients auprès d’Internet.

Exemple :

```text
PC utilisateur
      |
      v
Squid
      |
      v
example.com
```

Le serveur `example.com` voit principalement la connexion provenant du proxy.

---

# 3. Reverse Proxy

Un :

```text
Reverse Proxy
```

est placé devant des serveurs.

Architecture :

```text
Internet
   |
   v
Reverse Proxy
   |
   +------> Web Server 1
   |
   +------> Web Server 2
```

Ici, le proxy représente les serveurs auprès des clients.

Exemples de reverse proxies :

```text
Nginx
HAProxy
Traefik
Apache
Cloudflare
```

---

# 4. Forward Proxy vs Reverse Proxy

## Forward Proxy

Protège et contrôle les :

```text
clients
```

Exemple :

```text
Entreprise -> Squid -> Internet
```

---

## Reverse Proxy

Protège et expose les :

```text
serveurs
```

Exemple :

```text
Internet -> Nginx -> Application
```

---

# 5. Comparaison simple

| Forward Proxy | Reverse Proxy |
|---|---|
| Placé côté client | Placé côté serveur |
| Contrôle les sorties | Contrôle les entrées |
| Cache l’identité des clients | Cache l’architecture interne |
| Filtre la navigation | Protège les applications |
| Squid | Nginx / HAProxy |

---

# 6. Pourquoi un proxy fonctionne au Layer 7

Un firewall classique peut souvent filtrer sur :

```text
IP
port
protocole
```

Par exemple :

```text
autoriser TCP 443
```

Mais cela ne dit rien sur :

```text
le domaine demandé
l’URL
le fichier téléchargé
la méthode HTTP
```

Un proxy fonctionne au :

```text
Layer 7
```

c’est-à-dire la couche application.

Il comprend notamment :

```text
HTTP
HTTPS
URL
Host
domaines
chemins
méthodes
```

---

# 7. Exemple Layer 3/4 vs Layer 7

Un firewall peut voir :

```text
192.168.1.20 -> 93.184.216.34:443
```

Le proxy peut comprendre :

```text
https://example.com/download/malware.exe
```

C’est cette compréhension applicative qui permet un filtrage beaucoup plus précis.

---

# 8. Interception d’une connexion HTTP

Pour HTTP, le fonctionnement est relativement simple.

Le client envoie :

```http
GET http://example.com/index.html HTTP/1.1
Host: example.com
```

au proxy.

Le proxy :

```text
1. reçoit la requête
2. analyse les ACL
3. décide ALLOW ou DENY
4. ouvre sa propre connexion vers example.com
5. transmet la requête
6. récupère la réponse
7. renvoie la réponse au client
```

Il y a donc en réalité :

```text
Client <-> Proxy

Proxy <-> Serveur
```

au lieu d’une seule connexion directe.

---

# 9. Reconstruction des connexions

Le client pense parler à travers le proxy.

Mais le proxy gère deux côtés distincts :

```text
Connexion client
        |
      Proxy
        |
Connexion serveur
```

Cette séparation permet au proxy d’appliquer :

```text
ACL
logging
cache
filtrage
authentification
inspection
```

---

# 10. Proxy dans une stratégie Defense in Depth

Le proxy ne remplace pas :

```text
Firewall
EDR
Antivirus
IDS/IPS
DNS filtering
```

Il les complète.

Exemple :

```text
Internet
   |
Firewall
   |
Proxy
   |
Endpoint Security
   |
Client
```

Chaque couche bloque certains types d’attaques.

C’est le principe :

```text
Defense in Depth
```

ou :

```text
Défense en profondeur
```

---

# 11. Pourquoi plusieurs couches ?

Un firewall peut autoriser :

```text
TCP/443
```

car HTTPS est nécessaire.

Mais un proxy peut ensuite bloquer :

```text
malware.example
```

même si le trafic utilise le port 443.

De la même manière :

```text
Firewall = contrôle réseau
Proxy = contrôle applicatif
```

---

# 12. Squid

Squid est principalement configuré via :

```text
/etc/squid/squid.conf
```

Pour vérifier son état :

```bash
systemctl status squid
```

Pour démarrer :

```bash
sudo systemctl start squid
```

Pour l’activer au démarrage :

```bash
sudo systemctl enable squid
```

---

# 13. Port de Squid

Squid utilise souvent :

```text
TCP/3128
```

Vérification :

```bash
ss -lntp
```

On peut obtenir :

```text
LISTEN 0 128 0.0.0.0:3128
```

---

# 14. Tester un proxy

Avec curl :

```bash
curl -x http://PROXY_IP:3128 http://example.com
```

Par exemple :

```bash
curl -x http://10.0.0.10:3128 http://example.com
```

L’option :

```text
-x
```

indique à curl d’utiliser un proxy.

---

# 15. Access Control Lists

Les ACL sont au cœur de Squid.

ACL signifie :

```text
Access Control List
```

Une ACL permet de définir un groupe ou une condition.

Exemple :

```text
acl localnet src 192.168.1.0/24
```

Cette ACL s’appelle :

```text
localnet
```

et correspond aux machines ayant comme IP source :

```text
192.168.1.0/24
```

---

# 16. Structure d’une ACL

Syntaxe générale :

```text
acl NOM TYPE VALEUR
```

Exemple :

```text
acl employees src 10.0.0.0/24
```

Ici :

```text
NOM   = employees
TYPE  = src
VALEUR = 10.0.0.0/24
```

---

# 17. ACL src

La directive :

```text
src
```

correspond à :

```text
source IP
```

Exemple :

```text
acl internal src 192.168.1.0/24
```

Cela signifie :

```text
les clients provenant de 192.168.1.0/24
```

---

# 18. ACL dst

La directive :

```text
dst
```

correspond à :

```text
destination IP
```

Exemple :

```text
acl private_servers dst 10.0.0.0/8
```

Cela représente des destinations situées dans :

```text
10.0.0.0/8
```

---

# 19. src vs dst

Très important :

```text
src = QUI fait la requête
```

```text
dst = OÙ va la requête
```

Exemple :

```text
192.168.1.20 -> 8.8.8.8
```

Alors :

```text
src = 192.168.1.20
dst = 8.8.8.8
```

---

# 20. http_access

Définir une ACL ne bloque ou n’autorise rien à elle seule.

Il faut utiliser :

```text
http_access
```

Exemple :

```text
acl localnet src 192.168.1.0/24

http_access allow localnet
```

Cela signifie :

```text
autoriser les clients du réseau local
```

---

# 21. Bloquer une ACL

Exemple :

```text
acl blocked src 192.168.1.50

http_access deny blocked
```

La machine :

```text
192.168.1.50
```

ne pourra pas utiliser le proxy.

---

# 22. Plusieurs ACL dans une règle

On peut chaîner plusieurs conditions.

Exemple :

```text
acl localnet src 192.168.1.0/24
acl example dstdomain .example.com

http_access allow localnet example
```

Cela signifie :

```text
SI source ∈ localnet
ET destination ∈ example
ALORS allow
```

Les ACL présentes sur la même ligne sont généralement combinées avec une logique :

```text
AND
```

---

# 23. Ordre des règles

C’est une notion fondamentale.

Squid analyse les règles :

```text
de haut en bas
```

La première règle correspondante décide.

On peut résumer par :

```text
First match wins
```

---

# 24. Exemple de mauvais ordre

```text
http_access allow all
http_access deny blocked_sites
```

La première règle autorise tout.

Donc :

```text
deny blocked_sites
```

ne sera jamais atteinte pour les requêtes déjà autorisées.

---

# 25. Bon ordre

```text
http_access deny blocked_sites
http_access allow localnet
http_access deny all
```

Le proxy :

```text
1. bloque les destinations interdites
2. autorise le réseau interne
3. bloque tout le reste
```

---

# 26. Default Deny avec Squid

Comme pour un firewall, une bonne approche consiste souvent à terminer avec :

```text
http_access deny all
```

Ainsi :

```text
tout ce qui n’a pas été explicitement autorisé
```

est bloqué.

---

# 27. Content Filtering

Squid peut filtrer selon :

```text
domaine
URL
chemin
extension
IP
utilisateur
horaire
```

---

# 28. Bloquer un domaine avec dstdomain

La directive :

```text
dstdomain
```

permet de filtrer selon le domaine de destination.

Exemple :

```text
acl blocked_sites dstdomain .facebook.com .tiktok.com
```

Puis :

```text
http_access deny blocked_sites
```

---

# 29. Le point devant le domaine

Exemple :

```text
.facebook.com
```

permet généralement de correspondre à :

```text
facebook.com
www.facebook.com
m.facebook.com
subdomain.facebook.com
```

C’est utile pour couvrir les sous-domaines.

---

# 30. Exemple complet

```text
acl localnet src 192.168.1.0/24

acl blocked_sites dstdomain .example.com .badsite.test

http_access deny blocked_sites
http_access allow localnet
http_access deny all
```

---

# 31. Blacklists dans des fichiers

Au lieu d’écrire tous les domaines dans :

```text
squid.conf
```

on peut utiliser un fichier externe.

Exemple :

```text
/etc/squid/blocked_domains.txt
```

Contenu :

```text
.facebook.com
.tiktok.com
.example.org
```

Puis :

```text
acl blocked_sites dstdomain "/etc/squid/blocked_domains.txt"
```

Et :

```text
http_access deny blocked_sites
```

---

# 32. Avantage des fichiers blacklist

Cela facilite :

```text
maintenance
automatisation
mise à jour
lisibilité
```

On peut modifier la liste sans réécrire toute la configuration.

---

# 33. Bloquer des types de fichiers

La directive :

```text
urlpath_regex
```

permet d’analyser le chemin d’une URL.

Exemple :

```text
acl executables urlpath_regex -i \.exe$
```

Puis :

```text
http_access deny executables
```

Cela bloque les URLs terminant par :

```text
.exe
```

---

# 34. Option -i

Dans :

```text
urlpath_regex -i
```

`-i` signifie :

```text
case insensitive
```

Donc :

```text
.EXE
.exe
.Exe
```

seront traités de la même manière.

---

# 35. Bloquer plusieurs extensions

Exemple :

```text
acl dangerous_files urlpath_regex -i \.(exe|msi|bat|cmd|scr)$
```

Puis :

```text
http_access deny dangerous_files
```

---

# 36. Attention aux limites du filtrage par extension

Une URL peut être :

```text
/download?id=123
```

mais retourner un fichier :

```text
malware.exe
```

Le proxy ne peut donc pas toujours déterminer le type réel uniquement grâce au chemin URL.

De plus, avec HTTPS non déchiffré :

```text
le chemin complet est chiffré
```

Donc `urlpath_regex` ne peut pas inspecter ce chemin sans déchiffrement TLS.

---

# 37. Blacklist

Une :

```text
Blacklist
```

fonctionne ainsi :

```text
tout est autorisé
sauf ce qui est interdit
```

Exemple :

```text
Internet
├── example.com -> allow
├── wikipedia.org -> allow
├── malicious.test -> DENY
└── github.com -> allow
```

---

# 38. Whitelist

Une :

```text
Whitelist
```

fonctionne à l’inverse :

```text
tout est bloqué
sauf ce qui est explicitement autorisé
```

Exemple :

```text
acl allowed_domains dstdomain .company.com .microsoft.com

http_access allow allowed_domains
http_access deny all
```

---

# 39. Blacklist vs Whitelist

## Blacklist

Avantages :

```text
plus simple pour les utilisateurs
moins restrictive
```

Inconvénient :

```text
impossible de connaître tous les sites malveillants
```

---

## Whitelist

Avantage :

```text
beaucoup plus restrictive
surface d’exposition réduite
```

Inconvénient :

```text
beaucoup de maintenance
peut bloquer des usages légitimes
```

---

# 40. Quel modèle est le plus sécurisé ?

En général :

```text
whitelist
```

est plus restrictive et plus sécurisée.

Mais elle est souvent difficile à utiliser dans un environnement où les utilisateurs doivent accéder à de nombreux sites.

Le choix dépend donc du contexte.

---

# 41. HTTPS et le problème du chiffrement

Avec HTTP :

```text
Proxy peut lire :
Host
URL
path
headers
contenu
```

Avec HTTPS :

```text
Client
   |
 TLS chiffré
   |
Serveur
```

Le contenu HTTP est chiffré.

Le proxy ne voit donc pas directement :

```text
GET /secret/file.exe
Cookie
password
contenu
```

---

# 42. TLS Inspection

Pour appliquer certaines politiques à HTTPS, plusieurs techniques existent.

L’une d’entre elles consiste à observer les informations du handshake TLS sans déchiffrer complètement la connexion.

Une information importante est :

```text
SNI
```

---

# 43. Server Name Indication

SNI signifie :

```text
Server Name Indication
```

Lorsqu’un client démarre une connexion TLS, il peut indiquer le nom du serveur auquel il veut parler.

Exemple :

```text
ClientHello
SNI: www.example.com
```

Cela permet notamment à un serveur hébergeant plusieurs sites sur la même IP de savoir quel certificat présenter.

---

# 44. Pourquoi SNI est utile au proxy

Même si le contenu HTTPS est chiffré, le proxy peut souvent identifier :

```text
www.example.com
```

grâce au SNI.

Il peut donc appliquer une règle comme :

```text
bloquer .example.com
```

sans forcément déchiffrer toute la connexion HTTPS.

---

# 45. SNI Peeking

Squid peut examiner le début de la connexion TLS.

Cette opération peut utiliser :

```text
ssl_bump peek
```

L’idée est :

```text
observer suffisamment le handshake TLS
```

pour récupérer certaines informations comme le nom du serveur.

---

# 46. ssl_bump peek

Conceptuellement :

```text
Client
   |
TLS ClientHello
   |
Proxy
   |
   +---- peek
         |
         +---- observe SNI
```

Le proxy inspecte certaines métadonnées TLS.

---

# 47. splice

Après avoir observé les métadonnées, le proxy peut décider de ne pas déchiffrer le reste.

Il utilise alors :

```text
splice
```

Le trafic TLS continue entre :

```text
Client <----------> Serveur
```

à travers le proxy.

Le proxy ne déchiffre pas le contenu applicatif.

---

# 48. Peek + Splice

Le modèle est :

```text
1. Client commence TLS
2. Squid regarde le ClientHello
3. Squid récupère le SNI
4. Squid applique les ACL
5. Si autorisé :
      splice
6. La connexion TLS continue sans inspection complète
```

---

# 49. Exemple conceptuel ssl_bump

Une configuration peut inclure des éléments comme :

```text
acl step1 at_step SslBump1

ssl_bump peek step1
ssl_bump splice all
```

L’objectif ici est surtout de comprendre :

```text
peek = observer
splice = laisser passer sans déchiffrer
```

---

# 50. SSL Bumping complet

Une autre possibilité est que le proxy réalise un véritable :

```text
Man-in-the-Middle contrôlé
```

Le proxy :

```text
1. reçoit TLS du client
2. déchiffre
3. inspecte HTTP
4. crée une deuxième connexion TLS vers le serveur
```

Architecture :

```text
Client
   |
TLS #1
   |
Proxy
   |
TLS #2
   |
Serveur
```

---

# 51. Pourquoi cela nécessite une CA

Le proxy doit pouvoir présenter des certificats acceptés par les clients.

Il faut généralement installer une :

```text
Certificate Authority interne
```

sur les machines de l’organisation.

Le proxy génère ensuite dynamiquement des certificats pour les domaines consultés.

---

# 52. Pourquoi SSL Bump est controversé

Le déchiffrement HTTPS donne potentiellement accès à :

```text
messages
mots de passe
documents
données personnelles
cookies
requêtes
```

Il pose donc des questions :

```text
vie privée
conformité
sécurité
responsabilité
```

---

# 53. Quand éviter SSL Bump

Il peut être préférable de ne pas intercepter certaines catégories sensibles :

```text
banques
santé
services gouvernementaux
authentification sensible
données personnelles
```

Les organisations définissent souvent des règles de bypass.

---

# 54. Autre problème du SSL Bump

Le proxy devient une cible très importante.

S’il est compromis :

```text
trafic déchiffré
+
certificats
+
informations sensibles
```

peuvent être exposés.

Le proxy doit donc être fortement sécurisé.

---

# 55. Defense in Depth et TLS

Une approche équilibrée peut combiner :

```text
DNS filtering
SNI filtering
Firewall
Proxy
EDR
Threat Intelligence
```

sans forcément déchiffrer systématiquement tout HTTPS.

---

# 56. Operational Skills

Une grande partie du travail avec Squid consiste à :

```text
modifier configuration
vérifier syntaxe
recharger
tester
analyser logs
```

---

# 57. Vérifier la configuration Squid

Avant de recharger Squid :

```bash
sudo squid -k parse
```

Cette commande analyse :

```text
/etc/squid/squid.conf
```

et cherche les erreurs.

---

# 58. Pourquoi toujours parser avant reload

Une erreur comme :

```text
ACL mal écrite
directive invalide
fichier blacklist absent
```

peut empêcher Squid de fonctionner correctement.

Workflow :

```text
modifier
  ↓
squid -k parse
  ↓
reload
```

---

# 59. Recharger sans redémarrer

Une fois la configuration correcte :

```bash
sudo squid -k reconfigure
```

ou selon l’environnement :

```bash
sudo systemctl reload squid
```

Cela permet de recharger la configuration sans arrêter complètement le proxy.

---

# 60. Reload vs Restart

## Reload

```text
service reste actif
configuration rechargée
```

Commande :

```bash
sudo systemctl reload squid
```

---

## Restart

```text
service arrêté
puis redémarré
```

Commande :

```bash
sudo systemctl restart squid
```

Pour une modification de configuration, le reload est généralement préférable quand il est suffisant.

---

# 61. Tester avec curl

Tester une URL autorisée :

```bash
curl -x http://PROXY_IP:3128 http://example.com
```

Tester une URL interdite :

```bash
curl -x http://PROXY_IP:3128 http://blocked.example
```

---

# 62. Voir uniquement les headers

```bash
curl -I -x http://PROXY_IP:3128 http://example.com
```

Cela permet de vérifier rapidement la réponse HTTP.

---

# 63. Mode verbose

Très utile :

```bash
curl -v -x http://PROXY_IP:3128 http://example.com
```

`-v` affiche :

```text
connexion au proxy
requête
headers
code HTTP
erreurs
```

---

# 64. Exemple d’un blocage

On peut obtenir quelque chose comme :

```text
HTTP/1.1 403 Forbidden
```

Cela indique que Squid a refusé la requête.

---

# 65. Tester HTTPS

Avec un proxy explicite :

```bash
curl -v -x http://PROXY_IP:3128 https://example.com
```

curl utilise alors généralement :

```text
CONNECT example.com:443
```

pour demander au proxy d’établir un tunnel.

---

# 66. Méthode CONNECT

Pour HTTPS :

```text
Client -> Proxy

CONNECT example.com:443 HTTP/1.1
```

Si le proxy autorise :

```text
HTTP/1.1 200 Connection established
```

puis le client démarre TLS à travers le tunnel.

---

# 67. Logs Squid

Le fichier principal est souvent :

```text
/var/log/squid/access.log
```

Pour suivre en direct :

```bash
sudo tail -f /var/log/squid/access.log
```

---

# 68. Pourquoi les logs sont importants

Ils permettent de voir :

```text
qui
quand
quelle destination
quel résultat
combien de données
```

Ils sont essentiels pour :

```text
troubleshooting
audit
incident response
monitoring
```

---

# 69. Exemple de log

Une ligne peut ressembler conceptuellement à :

```text
1660000000 120 192.168.1.20 TCP_MISS/200 1250 GET http://example.com/ - HIER_DIRECT/93.184.216.34 text/html
```

On peut y retrouver :

```text
timestamp
temps de réponse
IP client
résultat Squid
code HTTP
taille
méthode
URL
destination
```

---

# 70. TCP_MISS

Exemple :

```text
TCP_MISS/200
```

peut signifier que :

```text
objet absent du cache
récupéré depuis le serveur
HTTP 200
```

---

# 71. TCP_DENIED

Exemple :

```text
TCP_DENIED/403
```

indique généralement :

```text
requête bloquée
HTTP 403
```

C’est particulièrement utile pour diagnostiquer une ACL.

---

# 72. Rechercher les refus

```bash
grep TCP_DENIED /var/log/squid/access.log
```

Ou en direct :

```bash
tail -f /var/log/squid/access.log | grep TCP_DENIED
```

---

# 73. Rechercher une IP

```bash
grep '192.168.1.20' /var/log/squid/access.log
```

Cela permet de voir les requêtes d’un client précis.

---

# 74. Rechercher un domaine

```bash
grep 'example.com' /var/log/squid/access.log
```

---

# 75. Troubleshooting d’une requête bloquée

Lorsqu’une requête ne fonctionne pas, ne modifie pas immédiatement toutes les ACL.

Procède méthodiquement.

---

# 76. Étape 1 — Vérifier que Squid fonctionne

```bash
systemctl status squid
```

---

# 77. Étape 2 — Vérifier le port

```bash
ss -lntp | grep 3128
```

---

# 78. Étape 3 — Vérifier la configuration

```bash
sudo squid -k parse
```

---

# 79. Étape 4 — Tester curl

```bash
curl -v -x http://PROXY_IP:3128 http://example.com
```

---

# 80. Étape 5 — Regarder access.log

```bash
sudo tail -f /var/log/squid/access.log
```

Refaire ensuite la requête.

---

# 81. Étape 6 — Chercher TCP_DENIED

Si on voit :

```text
TCP_DENIED/403
```

le problème vient probablement :

```text
d’une ACL
ou
d’un http_access
```

---

# 82. Étape 7 — Vérifier l’ordre

Exemple problématique :

```text
http_access deny all
http_access allow localnet
```

La deuxième règle ne sera jamais utilisée.

Il faut :

```text
http_access allow localnet
http_access deny all
```

---

# 83. Exemple de configuration simple

```text
http_port 3128

acl localnet src 192.168.1.0/24

acl blocked_sites dstdomain "/etc/squid/blocked_domains.txt"

acl dangerous_files urlpath_regex -i \.(exe|msi|bat|cmd)$

http_access deny blocked_sites
http_access deny dangerous_files

http_access allow localnet

http_access deny all
```

---

# 84. Lecture de cette configuration

```text
http_port 3128
```

Squid écoute sur TCP/3128.

---

```text
acl localnet src 192.168.1.0/24
```

Définit le réseau autorisé.

---

```text
acl blocked_sites dstdomain ...
```

Charge la blacklist.

---

```text
acl dangerous_files urlpath_regex ...
```

Détecte certaines extensions.

---

```text
http_access deny blocked_sites
```

Bloque les domaines.

---

```text
http_access deny dangerous_files
```

Bloque les fichiers correspondants.

---

```text
http_access allow localnet
```

Autorise les clients internes.

---

```text
http_access deny all
```

Bloque le reste.

---

# 85. Exemple de blacklist

Fichier :

```text
/etc/squid/blocked_domains.txt
```

Contenu :

```text
.example.com
.badsite.test
.malware.test
```

---

# 86. Ajouter un domaine

```bash
echo '.newblocked.example' | sudo tee -a /etc/squid/blocked_domains.txt
```

Puis :

```bash
sudo squid -k parse
```

Puis :

```bash
sudo systemctl reload squid
```

---

# 87. Workflow après modification

Toujours penser :

```text
Edit
 ↓
Parse
 ↓
Reload
 ↓
Test
 ↓
Logs
```

Commandes :

```bash
sudo squid -k parse
sudo systemctl reload squid
curl -v -x http://PROXY_IP:3128 http://example.com
sudo tail -f /var/log/squid/access.log
```

---

# 88. Workflow de troubleshooting

Si quelque chose est bloqué :

```text
Client
 ↓
Proxy joignable ?
 ↓
Port 3128 ouvert ?
 ↓
Configuration valide ?
 ↓
ACL correspondante ?
 ↓
Ordre http_access ?
 ↓
DNS fonctionne ?
 ↓
Destination accessible ?
 ↓
Logs Squid
```

---

# 89. Proxy vs Firewall

Une question classique est :

```text
Pourquoi utiliser un proxy si on possède déjà un firewall ?
```

Parce qu’ils n’agissent pas au même niveau.

Firewall :

```text
IP
ports
protocoles
état de connexion
```

Proxy :

```text
domaines
URLs
HTTP
méthodes
contenu
politique utilisateur
```

---

# 90. Exemple Defense in Depth

Supposons qu’un poste tente :

```text
https://malware.example/payload.exe
```

Le firewall voit principalement :

```text
Client -> IP externe:443
```

Il doit probablement autoriser HTTPS.

Le proxy peut reconnaître :

```text
malware.example
```

et bloquer cette destination.

Un EDR peut ensuite détecter le fichier s’il arrive malgré tout sur le poste.

---

# 91. Rôle du DNS Filtering

Le DNS filtering peut aussi bloquer :

```text
malware.example
```

avant la connexion.

Mais là encore :

```text
DNS filter
+
Proxy
+
Firewall
+
EDR
```

est plus robuste qu’une seule couche.

---

# 92. SNI et confidentialité

Il faut retenir que SNI traditionnel peut exposer le nom du serveur demandé pendant le handshake TLS.

Mais les technologies TLS évoluent.

Des mécanismes modernes comme :

```text
ECH
Encrypted ClientHello
```

cherchent justement à chiffrer davantage les informations du ClientHello.

Cela peut réduire la visibilité des équipements qui dépendent uniquement du SNI.

---

# 93. Conséquence pour le filtrage

Un filtrage basé uniquement sur SNI :

```text
ne doit pas être considéré comme universel
```

Il dépend :

```text
version TLS
configuration client
configuration serveur
technologies de confidentialité utilisées
```

---

# 94. Ce qu’il faut savoir expliquer sur SNI

Tu dois pouvoir dire :

```text
SNI indique au serveur TLS quel nom de domaine le client souhaite contacter.
```

Et :

```text
Un proxy peut parfois lire ce SNI pour appliquer des règles par domaine sans déchiffrer tout HTTPS.
```

---

# 95. Ce qu’il faut savoir expliquer sur peek

```text
peek
```

signifie essentiellement :

```text
observer les premières informations TLS
```

sans forcément effectuer une interception complète.

---

# 96. Ce qu’il faut savoir expliquer sur splice

```text
splice
```

signifie :

```text
laisser ensuite passer la connexion TLS sans la déchiffrer complètement
```

---

# 97. Commandes importantes

Installer Squid :

```bash
sudo apt update
sudo apt install -y squid
```

Vérifier :

```bash
systemctl status squid
```

Vérifier le port :

```bash
ss -lntp | grep 3128
```

---

# 98. Configuration

Fichier principal :

```text
/etc/squid/squid.conf
```

Parser :

```bash
sudo squid -k parse
```

Recharger :

```bash
sudo systemctl reload squid
```

Afficher l’état :

```bash
systemctl status squid
```

---

# 99. Tests

HTTP :

```bash
curl -v -x http://PROXY_IP:3128 http://example.com
```

HTTPS :

```bash
curl -v -x http://PROXY_IP:3128 https://example.com
```

Headers :

```bash
curl -I -x http://PROXY_IP:3128 http://example.com
```

---

# 100. Logs

Suivre :

```bash
sudo tail -f /var/log/squid/access.log
```

Refus :

```bash
grep TCP_DENIED /var/log/squid/access.log
```

Client précis :

```bash
grep 'CLIENT_IP' /var/log/squid/access.log
```

Domaine précis :

```bash
grep 'example.com' /var/log/squid/access.log
```

---

# Cheat Sheet

```bash
# Installer
sudo apt update
sudo apt install -y squid

# État
systemctl status squid

# Activer au boot
sudo systemctl enable squid

# Ports
ss -lntp

# Vérifier configuration
sudo squid -k parse

# Reload
sudo systemctl reload squid

# Alternative Squid
sudo squid -k reconfigure

# Restart
sudo systemctl restart squid

# Test HTTP
curl -v -x http://PROXY_IP:3128 http://example.com

# Test HTTPS
curl -v -x http://PROXY_IP:3128 https://example.com

# Logs
sudo tail -f /var/log/squid/access.log

# Requêtes bloquées
grep TCP_DENIED /var/log/squid/access.log
```

---

# ACL Cheat Sheet

```text
# Source IP
acl localnet src 192.168.1.0/24

# Destination IP
acl internal dst 10.0.0.0/8

# Domaine
acl blocked dstdomain .example.com

# Liste de domaines
acl blocked dstdomain "/etc/squid/blocked_domains.txt"

# Extensions
acl executables urlpath_regex -i \.(exe|msi|bat|cmd)$

# Autoriser
http_access allow localnet

# Refuser
http_access deny blocked

# Default deny
http_access deny all
```

---

# Architecture générale

```text
                      INTERNET
                          |
                          |
                    Destination
                          |
                          |
                       Squid
                    Layer 7 Proxy
                    /     |      \
                   /      |       \
             ACLs     Filtering    Logs
                 \       |        /
                  \      |       /
                       Client
```

Dans une entreprise :

```text
Client
   |
   v
Firewall
   |
   v
Squid Proxy
   |
   +---- ACL
   +---- Domain Filtering
   +---- URL Filtering
   +---- SNI Inspection
   +---- Logging
   |
   v
Internet
```

---

# Les idées essentielles à mémoriser

## Proxy Architecture

```text
Forward Proxy = représente les clients.
Reverse Proxy = représente les serveurs.
```

Un proxy fonctionne principalement en :

```text
Layer 7
```

car il comprend les protocoles applicatifs.

---

## ACL

```text
src = adresse source
dst = adresse destination
```

Une ACL définit une condition.

```text
http_access
```

décide quoi faire avec cette condition.

Et surtout :

```text
l’ordre des règles est essentiel.
```

---

## Content Filtering

```text
dstdomain
```

sert à filtrer les domaines.

```text
urlpath_regex
```

permet de filtrer certains chemins ou extensions.

```text
Blacklist = tout autoriser sauf les interdits.
Whitelist = tout interdire sauf les autorisés.
```

---

## TLS

```text
SNI
```

peut indiquer le domaine demandé pendant le handshake TLS.

```text
peek
```

permet d’observer certaines informations.

```text
splice
```

laisse ensuite passer le tunnel sans interception complète.

Le SSL bump complet déchiffre le trafic mais pose d’importantes questions de :

```text
confidentialité
sécurité
conformité
```

---

## Operations

Toujours penser :

```text
Modifier
   ↓
squid -k parse
   ↓
reload
   ↓
curl
   ↓
access.log
```

Les commandes les plus importantes sont :

```bash
sudo squid -k parse
sudo systemctl reload squid
curl -v -x http://PROXY_IP:3128 URL
sudo tail -f /var/log/squid/access.log
```

---

# Méthode à retenir

Lorsqu’un utilisateur dit :

```text
“Le proxy bloque mon site”
```

ne modifie pas immédiatement la configuration.

Vérifie dans cet ordre :

```text
1. Squid tourne-t-il ?
        ↓
2. Port 3128 écoute-t-il ?
        ↓
3. La configuration est-elle valide ?
        ↓
4. curl atteint-il le proxy ?
        ↓
5. Quel code retourne Squid ?
        ↓
6. Que dit access.log ?
        ↓
7. Quelle ACL correspond ?
        ↓
8. Quel est l’ordre des http_access ?
        ↓
9. Modifier si nécessaire
        ↓
10. Parse + Reload + Retest
```

Cette méthode permet de diagnostiquer proprement la majorité des problèmes Squid sans modifier les règles au hasard.