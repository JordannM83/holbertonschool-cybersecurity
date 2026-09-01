# Stateful Firewalling, WireGuard, Routing & Operational Safety

## Introduction

Ce projet porte sur quatre grands thèmes de sécurité réseau sous Linux :

- le filtrage stateful avec un firewall ;
- le déploiement d’un VPN WireGuard ;
- le routage IP et le NAT ;
- les bonnes pratiques pour éviter de se couper soi-même du serveur.

L’objectif est de comprendre non seulement **quelles commandes utiliser**, mais surtout **pourquoi elles fonctionnent**.

---

# 1. Stateful Firewalling

## 1.1 Qu’est-ce qu’un firewall stateful ?

Un firewall stateful est un pare-feu qui ne regarde pas uniquement :

```text
IP source
IP destination
Port source
Port destination
Protocole
```

Il garde également une trace de l’état des connexions.

C’est ce qu’on appelle :

```text
Connection Tracking
```

ou :

```text
conntrack
```

Sous Linux, le firewall peut s’appuyer sur ces informations pour savoir si un paquet :

- démarre une nouvelle connexion ;
- appartient à une connexion déjà existante ;
- est lié à une autre connexion ;
- ne correspond à aucune connexion connue.

Avec nftables, on utilise :

```text
ct state
```

---

# 2. Connection Tracking

Le noyau Linux maintient une table de connexions.

Par exemple, lorsqu’un client se connecte à un serveur SSH :

```text
Client                  Serveur

SYN        ----------->

           <----------- SYN, ACK

ACK        ----------->
```

Linux comprend alors qu’une connexion TCP existe entre :

```text
192.168.1.10:54321
```

et :

```text
192.168.1.20:22
```

Le firewall n’a donc pas besoin de considérer chaque paquet indépendamment.

Il sait que certains paquets appartiennent à une connexion déjà connue.

---

# 3. Les états NEW, ESTABLISHED et RELATED

## 3.1 NEW

L’état :

```text
NEW
```

correspond généralement à une nouvelle connexion.

Exemple :

```text
Client -> Serveur : SYN vers TCP/22
```

Cette connexion n’existait pas encore.

Une règle peut autoriser uniquement certaines nouvelles connexions.

Exemple :

```bash
nft add rule inet filter input tcp dport 22 ct state new accept
```

Cela signifie :

```text
Autoriser une nouvelle connexion SSH.
```

---

# 4. ESTABLISHED

L’état :

```text
ESTABLISHED
```

correspond à une connexion déjà reconnue par le système de suivi d’état.

Exemple :

```text
Client -> SSH Server
SSH Server -> Client
```

Une fois la connexion créée, les paquets suivants appartiennent à une connexion établie.

Une règle très classique est :

```bash
nft add rule inet filter input ct state established,related accept
```

Cela évite d’avoir à écrire une règle pour chaque paquet retour.

---

# 5. RELATED

L’état :

```text
RELATED
```

correspond à une connexion qui est liée à une autre connexion déjà connue.

L’exemple historique le plus simple est FTP.

FTP peut utiliser :

```text
connexion de contrôle
+
connexion de données
```

La connexion de données peut être considérée comme RELATED à la connexion de contrôle.

Autre exemple fréquent :

```text
ICMP error
```

Un message ICMP signalant une erreur liée à une connexion existante peut être marqué RELATED.

---

# 6. INVALID

Même s’il n’est pas toujours demandé dans les objectifs, il est important de connaître :

```text
INVALID
```

Cela signifie que le paquet ne correspond pas correctement à une connexion connue.

Exemple de règle :

```bash
nft add rule inet filter input ct state invalid drop
```

Ces paquets peuvent être :

- malformés ;
- inattendus ;
- incomplets ;
- liés à un problème réseau ;
- parfois issus d’un trafic malveillant.

---

# 7. Exemple simple de firewall stateful

Une structure classique peut ressembler à :

```bash
table inet filter {
    chain input {
        type filter hook input priority 0;
        policy drop;

        ct state invalid drop

        ct state established,related accept

        iif "lo" accept

        tcp dport 22 ct state new accept
    }
}
```

Ici :

```text
policy drop
```

signifie que tout ce qui n’est pas explicitement autorisé sera bloqué.

---

# 8. Default Deny

Le principe :

```text
Default Deny
```

signifie :

```text
Tout bloquer par défaut.
Autoriser uniquement ce qui est nécessaire.
```

C’est un principe fondamental en cybersécurité.

Une politique opposée serait :

```text
Tout autoriser sauf ce qui est interdit.
```

Cette approche est beaucoup plus dangereuse.

Pourquoi ?

Parce qu’un oubli entraîne une exposition.

Avec Default Deny :

```text
oubli = blocage
```

Avec Default Allow :

```text
oubli = service potentiellement exposé
```

---

# 9. Exemple de politique sécurisée

Avec nftables :

```bash
chain input {
    type filter hook input priority 0;
    policy drop;
}
```

Ici, sans autre règle :

```text
tout trafic entrant est bloqué
```

Puis on ouvre seulement ce qui est nécessaire.

Par exemple :

```bash
tcp dport 22 accept
tcp dport 80 accept
tcp dport 443 accept
```

---

# 10. Pourquoi autoriser ESTABLISHED en premier

Une très grande partie du trafic d’un serveur appartient souvent à des connexions déjà existantes.

Par exemple :

```text
HTTP response
SSH session
DNS response
API traffic
```

Une règle comme :

```bash
ct state established,related accept
```

sera donc utilisée très souvent.

Il est logique de la placer tôt.

---

# 11. Ordre des règles et performance

Les firewalls évaluent généralement les règles dans l’ordre.

Exemple :

```text
Règle 1
Règle 2
Règle 3
Règle 4
```

Le paquet est comparé aux règles jusqu’à ce qu’une règle corresponde.

Donc :

```text
les règles les plus fréquemment utilisées
```

doivent généralement apparaître tôt.

---

# 12. Exemple de mauvais ordre

```text
1. règle très rare
2. règle très rare
3. règle très rare
4. ESTABLISHED
```

Chaque paquet appartenant à une connexion existante doit traverser les trois premières règles inutilement.

---

# 13. Exemple de meilleur ordre

```text
1. drop INVALID
2. accept ESTABLISHED,RELATED
3. accept loopback
4. services nécessaires
5. règles spécifiques
6. drop
```

Cela améliore :

- la lisibilité ;
- les performances ;
- la logique du firewall.

---

# 14. Exemple de ruleset structuré

```bash
table inet filter {

    chain input {
        type filter hook input priority filter;
        policy drop;

        ct state invalid drop

        ct state established,related accept

        iifname "lo" accept

        tcp dport 22 accept
        tcp dport 80 accept
        tcp dport 443 accept
    }

    chain forward {
        type filter hook forward priority filter;
        policy drop;
    }

    chain output {
        type filter hook output priority filter;
        policy accept;
    }
}
```

---

# 15. VPN Deployment

## 15.1 Qu’est-ce que WireGuard ?

WireGuard est un protocole VPN moderne.

Il est conçu pour être :

- simple ;
- rapide ;
- sécurisé ;
- relativement facile à configurer.

Contrairement à certains anciens VPN, WireGuard utilise une configuration basée sur des clés cryptographiques.

---

# 16. Les clés WireGuard

Chaque pair WireGuard possède :

```text
Private Key
Public Key
```

La clé privée doit rester secrète.

La clé publique peut être partagée.

Relation :

```text
Private Key
    ↓
Public Key
```

On ne peut pas raisonnablement retrouver la clé privée depuis la clé publique.

---

# 17. Générer une clé privée

Commande :

```bash
wg genkey
```

Exemple :

```bash
wg genkey > privatekey
```

---

# 18. Générer la clé publique

On peut faire :

```bash
cat privatekey | wg pubkey
```

Ou :

```bash
wg pubkey < privatekey > publickey
```

---

# 19. Concept de Peer

Dans WireGuard, il n’existe pas vraiment de logique rigide :

```text
server / client
```

Techniquement, WireGuard fonctionne avec des :

```text
peers
```

Chaque peer connaît les informations nécessaires pour communiquer avec un autre peer.

Mais en pratique, on parle souvent de :

```text
Serveur WireGuard
Client WireGuard
```

pour simplifier.

---

# 20. Cryptokey Routing

WireGuard utilise un concept très important :

```text
Cryptokey Routing
```

Cela signifie que les clés cryptographiques sont associées à des plages IP.

La directive principale est :

```text
AllowedIPs
```

---

# 21. AllowedIPs côté serveur

Exemple :

```ini
[Peer]
PublicKey = CLIENT_PUBLIC_KEY
AllowedIPs = 10.10.0.2/32
```

Cela signifie en simplifiant :

```text
La clé publique de ce client est associée à 10.10.0.2.
```

Le serveur sait donc que :

```text
10.10.0.2
```

appartient à ce peer.

---

# 22. AllowedIPs comme table de routage

AllowedIPs sert également à décider :

```text
vers quel peer envoyer un paquet
```

Exemple :

```ini
AllowedIPs = 10.10.0.2/32
```

Si WireGuard doit envoyer un paquet à :

```text
10.10.0.2
```

il l’envoie au peer correspondant.

---

# 23. AllowedIPs côté client

Côté client, on peut avoir :

```ini
AllowedIPs = 10.10.0.0/24
```

Cela signifie :

```text
envoyer le trafic destiné au réseau VPN via ce peer.
```

---

# 24. Full Tunnel

Pour envoyer presque tout le trafic IPv4 via le VPN :

```ini
AllowedIPs = 0.0.0.0/0
```

Pour IPv6 :

```ini
AllowedIPs = ::/0
```

On parle de :

```text
Full Tunnel VPN
```

---

# 25. Split Tunnel

Si seulement certains réseaux passent dans le VPN :

```ini
AllowedIPs = 10.10.0.0/24
```

alors le reste du trafic utilise la connexion normale.

On parle de :

```text
Split Tunnel
```

---

# 26. Configuration WireGuard serveur

Exemple :

```ini
[Interface]
Address = 10.10.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY

[Peer]
PublicKey = CLIENT_PUBLIC_KEY
AllowedIPs = 10.10.0.2/32
```

Le serveur possède :

```text
10.10.0.1
```

Le client possède :

```text
10.10.0.2
```

---

# 27. Configuration WireGuard client

```ini
[Interface]
Address = 10.10.0.2/24
PrivateKey = CLIENT_PRIVATE_KEY

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = server.example.com:51820
AllowedIPs = 10.10.0.0/24
PersistentKeepalive = 25
```

---

# 28. Endpoint

La directive :

```ini
Endpoint = server.example.com:51820
```

indique :

```text
où contacter le peer
```

Cela contient :

```text
IP ou domaine
+
port UDP
```

---

# 29. ListenPort

Sur le serveur :

```ini
ListenPort = 51820
```

signifie que WireGuard écoute sur :

```text
UDP/51820
```

---

# 30. PersistentKeepalive

La directive :

```ini
PersistentKeepalive = 25
```

permet d’envoyer périodiquement un petit paquet.

Elle est surtout utile lorsque le client se trouve derrière :

```text
NAT
firewall
box Internet
```

Elle aide à maintenir l’association NAT active.

---

# 31. Pourquoi WireGuard est silencieux aux scanners

WireGuard ne répond pas normalement à un paquet UDP qui ne contient pas un message cryptographiquement valide.

Un scanner peut envoyer :

```text
UDP packet -> port 51820
```

Mais si ce paquet n’est pas un handshake WireGuard valide :

```text
pas de réponse
```

Pour le scanner, le port peut donc sembler :

```text
open|filtered
```

ou simplement silencieux.

---

# 32. Pourquoi ce comportement est intéressant

Un attaquant ne peut pas simplement envoyer n’importe quel paquet et recevoir :

```text
Hello, je suis un serveur WireGuard
```

WireGuard réduit donc les informations exposées.

C’est différent de certains services qui répondent immédiatement avec une bannière.

Exemple :

```text
SSH-2.0-OpenSSH_9.x
```

---

# 33. Vérifier WireGuard

Commande principale :

```bash
wg
```

ou :

```bash
wg show
```

Exemple d’informations :

```text
interface: wg0
public key: ...
listening port: 51820

peer: ...
endpoint: ...
allowed ips: ...
latest handshake: ...
transfer: ...
```

---

# 34. Vérifier l’interface

```bash
ip addr show wg0
```

ou :

```bash
ip a
```

---

# 35. Activer WireGuard

Avec wg-quick :

```bash
wg-quick up wg0
```

Désactiver :

```bash
wg-quick down wg0
```

---

# 36. Démarrage automatique

Avec systemd :

```bash
systemctl enable wg-quick@wg0
```

Puis :

```bash
systemctl start wg-quick@wg0
```

---

# 37. Kernel Routing

## 37.1 Qu’est-ce que le routage ?

Une machine Linux peut agir comme :

```text
Host
```

ou comme :

```text
Router
```

Un routeur reçoit des paquets sur une interface et les transmet vers une autre interface.

Exemple :

```text
VPN Client
    |
    | wg0
    v
Linux Server
    |
    | eth0
    v
Internet
```

---

# 38. ip_forward

Linux possède un paramètre noyau :

```text
net.ipv4.ip_forward
```

Pour vérifier :

```bash
sysctl net.ipv4.ip_forward
```

Résultat possible :

```text
net.ipv4.ip_forward = 0
```

Cela signifie :

```text
routage IPv4 désactivé
```

---

# 39. Activer ip_forward

Temporairement :

```bash
sysctl -w net.ipv4.ip_forward=1
```

Ou :

```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
```

---

# 40. Rendre ip_forward persistant

Par exemple :

```bash
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-forward.conf
```

Puis :

```bash
sysctl --system
```

---

# 41. Pourquoi ip_forward est désactivé par défaut

Une machine classique n’a normalement pas besoin de router du trafic entre différents réseaux.

Activer automatiquement cette fonction pourrait permettre :

```text
transit réseau non désiré
```

Linux préfère donc le comportement :

```text
Host
```

plutôt que :

```text
Router
```

par défaut.

---

# 42. Routage vs NAT

Ce sont deux concepts différents.

## Routage

Le routage décide :

```text
où envoyer le paquet
```

Exemple :

```text
10.10.0.2 -> 8.8.8.8
```

Le serveur choisit une interface de sortie.

---

## NAT

Le NAT modifie certaines informations dans les paquets.

Par exemple :

```text
adresse IP source
```

ou :

```text
adresse IP destination
```

---

# 43. Exemple sans NAT

Client VPN :

```text
10.10.0.2
```

Serveur VPN public :

```text
203.0.113.10
```

Le client veut contacter :

```text
8.8.8.8
```

Sans NAT :

```text
Source      10.10.0.2
Destination 8.8.8.8
```

Le paquet arrive sur Internet.

Mais le serveur distant doit savoir comment retourner vers :

```text
10.10.0.2
```

Or :

```text
10.10.0.2
```

est une adresse privée.

Elle n’est pas routable sur Internet.

---

# 44. Masquerading

On utilise alors souvent :

```text
masquerading
```

Exemple nftables :

```bash
oifname "eth0" masquerade
```

Le serveur modifie :

```text
Source 10.10.0.2
```

en :

```text
Source 203.0.113.10
```

---

# 45. Avant NAT

```text
10.10.0.2 -> 8.8.8.8
```

---

# 46. Après NAT

```text
203.0.113.10 -> 8.8.8.8
```

Le serveur distant répond alors à :

```text
203.0.113.10
```

Le serveur VPN garde une trace de la traduction.

Il sait que la réponse doit finalement être envoyée à :

```text
10.10.0.2
```

---

# 47. Pourquoi le trafic retour a besoin du NAT

Sans NAT :

```text
Internet
   |
   v
10.10.0.2
```

Le réseau distant ne sait généralement pas où envoyer cette réponse.

Avec NAT :

```text
Internet
   |
   v
IP publique du serveur VPN
   |
   v
NAT inverse
   |
   v
10.10.0.2
```

Le serveur peut donc remettre la réponse au client VPN.

---

# 48. Exemple nftables pour NAT

```bash
table ip nat {

    chain postrouting {
        type nat hook postrouting priority srcnat;

        oifname "eth0" ip saddr 10.10.0.0/24 masquerade
    }
}
```

Cela signifie :

```text
Pour les paquets provenant de 10.10.0.0/24
et sortant par eth0
→ masquerade
```

---

# 49. Forwarding dans le firewall

Activer :

```text
ip_forward
```

ne suffit pas forcément.

Le firewall doit également autoriser le trafic dans :

```text
chain forward
```

Exemple :

```bash
iifname "wg0" oifname "eth0" accept
```

Et pour le retour :

```bash
iifname "eth0" oifname "wg0" ct state established,related accept
```

---

# 50. Exemple complet VPN vers Internet

```bash
table inet filter {

    chain forward {
        type filter hook forward priority filter;
        policy drop;

        ct state invalid drop

        ct state established,related accept

        iifname "wg0" oifname "eth0" accept
    }
}
```

Puis NAT :

```bash
table ip nat {

    chain postrouting {
        type nat hook postrouting priority srcnat;

        oifname "eth0" ip saddr 10.10.0.0/24 masquerade
    }
}
```

---

# 51. Chemin complet d’un paquet

Un client WireGuard envoie :

```text
10.10.0.2 -> 1.1.1.1
```

Le paquet arrive sur :

```text
wg0
```

Le noyau regarde la table de routage.

Comme :

```text
ip_forward = 1
```

le paquet peut être transféré.

Le firewall vérifie :

```text
chain forward
```

Puis le NAT applique :

```text
masquerade
```

Le paquet devient :

```text
PUBLIC_IP -> 1.1.1.1
```

Puis part sur :

```text
eth0
```

---

# 52. Operational Safety

Modifier un firewall sur un serveur distant comporte un risque important :

```text
se couper soi-même de SSH
```

Exemple :

```bash
nft flush ruleset
```

puis mauvaise règle.

Résultat :

```text
SSH coupé
```

et potentiellement :

```text
plus aucun accès distant
```

---

# 53. Le Panic Button Pattern

Le principe est de prévoir un mécanisme automatique qui restaure l’accès si la nouvelle configuration bloque le serveur.

Exemple conceptuel :

```text
1. Sauvegarder les règles actuelles
2. Programmer une restauration dans 2 minutes
3. Appliquer les nouvelles règles
4. Tester la connexion
5. Si tout fonctionne : annuler la restauration
```

---

# 54. Exemple avec at

Sauvegarder :

```bash
nft list ruleset > /root/firewall-backup.nft
```

Programmer un rollback :

```bash
echo 'nft -f /root/firewall-backup.nft' | at now + 2 minutes
```

Puis appliquer les nouvelles règles.

Si tout fonctionne :

```bash
atq
```

puis supprimer le job concerné avec :

```bash
atrm JOB_ID
```

---

# 55. Pourquoi cette méthode est utile

Si tu te coupes de SSH :

```text
tu ne peux plus annuler le job
```

Donc après le délai :

```text
ancienne configuration restaurée
```

Cela peut sauver l’accès au serveur.

---

# 56. Sauvegarder un ruleset nftables

Pour afficher les règles :

```bash
nft list ruleset
```

Pour sauvegarder :

```bash
nft list ruleset > /etc/nftables.conf
```

---

# 57. Rendre nftables persistant

Selon la distribution :

```bash
systemctl enable nftables
```

Puis :

```bash
systemctl start nftables
```

Le service peut charger :

```text
/etc/nftables.conf
```

au démarrage.

---

# 58. Tester la configuration

Avant de charger un fichier, on peut vérifier sa syntaxe :

```bash
nft -c -f /etc/nftables.conf
```

L’option :

```text
-c
```

signifie :

```text
check
```

Elle permet de vérifier sans réellement appliquer les règles.

---

# 59. Charger les règles

```bash
nft -f /etc/nftables.conf
```

---

# 60. Binder un service à une interface

Un service peut écouter sur :

```text
0.0.0.0
```

Cela signifie :

```text
toutes les interfaces IPv4
```

Exemple :

```text
0.0.0.0:8080
```

Il peut donc être accessible depuis plusieurs réseaux.

---

# 61. Binder sur localhost

Si un service écoute uniquement sur :

```text
127.0.0.1
```

il est accessible localement seulement.

Exemple :

```text
127.0.0.1:8080
```

---

# 62. Binder sur WireGuard

On peut aussi faire écouter un service uniquement sur l’adresse VPN.

Exemple :

```text
10.10.0.1:8080
```

Le service devient accessible depuis :

```text
le réseau WireGuard
```

mais pas nécessairement depuis Internet.

---

# 63. Pourquoi le binding est important

Le firewall est une couche de sécurité.

Mais il vaut mieux combiner :

```text
service binding
+
firewall
```

Exemple :

```text
Application écoute uniquement sur wg0
+
firewall autorise seulement wg0
```

C’est plus robuste que :

```text
Application écoute partout
+
on compte uniquement sur le firewall
```

---

# 64. Vérifier les ports en écoute

Commande :

```bash
ss -lntup
```

Signification :

```text
-l  listening
-n  numérique
-t  TCP
-u  UDP
-p  process
```

Exemple :

```text
LISTEN 0 128 127.0.0.1:8080
```

Cela indique que le service écoute uniquement sur localhost.

---

# 65. Vérifier WireGuard

```bash
wg show
```

Chercher :

```text
latest handshake
transfer
endpoint
allowed ips
```

Si :

```text
latest handshake
```

se met à jour, le tunnel fonctionne probablement.

---

# 66. Vérifier les routes

```bash
ip route
```

Exemple :

```text
default via 192.168.1.1 dev eth0
10.10.0.0/24 dev wg0
```

Cela signifie :

```text
Internet -> eth0
VPN network -> wg0
```

---

# 67. Vérifier ip_forward

```bash
sysctl net.ipv4.ip_forward
```

Attendu pour un routeur VPN :

```text
net.ipv4.ip_forward = 1
```

---

# 68. Vérifier le NAT

Afficher les règles :

```bash
nft list ruleset
```

Chercher une règle comme :

```text
masquerade
```

---

# 69. Vérifier réellement le trafic

Un firewall ne doit pas être considéré comme correct uniquement parce que :

```text
les règles ont l’air bonnes
```

Il faut tester.

Exemples :

Depuis une machine autorisée :

```bash
ssh server
```

Depuis une machine non autorisée :

```bash
nc -vz server 22
```

Pour tester un service HTTP :

```bash
curl http://server
```

---

# 70. Utiliser tcpdump

Pour vérifier si le trafic arrive réellement :

```bash
tcpdump -i eth0
```

Pour WireGuard :

```bash
tcpdump -i wg0
```

Par exemple :

```bash
tcpdump -ni wg0
```

permet de voir le trafic VPN déchiffré qui passe dans l’interface virtuelle.

---

# 71. Vérifier les compteurs nftables

Les règles peuvent avoir des compteurs :

```bash
counter
```

Exemple :

```bash
ct state established,related counter accept
```

On peut ensuite voir :

```text
packets
bytes
```

Cela permet de vérifier que la règle est réellement utilisée.

---

# 72. Exemple de règle avec compteur

```bash
tcp dport 22 counter accept
```

Après quelques connexions SSH :

```text
counter packets 125 bytes 14320
```

Cela confirme que du trafic correspond à cette règle.

---

# 73. Méthode sûre pour modifier un firewall

Toujours suivre une méthode structurée.

```text
1. Sauvegarder l’existant
2. Vérifier que tu as un accès console si possible
3. Programmer un rollback
4. Vérifier la syntaxe
5. Appliquer
6. Garder la session SSH actuelle ouverte
7. Ouvrir une deuxième session SSH
8. Tester les services
9. Vérifier les logs / compteurs
10. Annuler le rollback
11. Rendre la configuration persistante
```

---

# 74. Ne jamais fermer la première session SSH trop tôt

Lors d’une modification distante :

```text
Session SSH 1
```

doit rester ouverte.

Après application des règles :

```text
ouvrir Session SSH 2
```

Si la deuxième connexion fonctionne :

```text
le firewall autorise bien les nouvelles connexions SSH
```

C’est un test simple mais très important.

---

# 75. Exemple complet de firewall VPN

Exemple conceptuel :

```bash
table inet filter {

    chain input {
        type filter hook input priority filter;
        policy drop;

        ct state invalid drop
        ct state established,related accept

        iifname "lo" accept

        udp dport 51820 accept

        iifname "wg0" tcp dport 22 accept
    }

    chain forward {
        type filter hook forward priority filter;
        policy drop;

        ct state invalid drop
        ct state established,related accept

        iifname "wg0" oifname "eth0" accept
    }

    chain output {
        type filter hook output priority filter;
        policy accept;
    }
}
```

Puis :

```bash
table ip nat {

    chain postrouting {
        type nat hook postrouting priority srcnat;

        oifname "eth0" ip saddr 10.10.0.0/24 masquerade
    }
}
```

---

# 76. Ce que fait cette configuration

Entrée :

```text
Internet -> UDP/51820
```

autorisée pour WireGuard.

SSH :

```text
wg0 -> TCP/22
```

autorisé uniquement depuis le VPN.

Le trafic VPN :

```text
wg0 -> eth0
```

peut être routé.

Le trafic retour :

```text
eth0 -> wg0
```

est autorisé grâce à :

```text
ct state established,related
```

Enfin :

```text
masquerade
```

permet aux clients VPN d’accéder à Internet via l’adresse publique du serveur.

---

# 77. Les erreurs classiques

## Oublier ESTABLISHED,RELATED

Résultat possible :

```text
la connexion initiale passe
mais les réponses sont bloquées
```

---

## Mettre policy drop trop tôt sans règles

Résultat :

```text
SSH coupé
```

---

## Oublier ip_forward

Résultat :

```text
WireGuard fonctionne
mais le client n’accède pas aux autres réseaux
```

---

## Oublier le NAT

Résultat possible :

```text
les paquets sortent
mais les réponses ne reviennent pas
```

---

## AllowedIPs incorrect

Résultat :

```text
le tunnel existe
mais le trafic ne prend pas la bonne route
```

---

## Mauvais Endpoint

Résultat :

```text
aucun handshake
```

---

# 78. Différence importante à retenir

```text
Firewall
```

décide :

```text
autoriser ou bloquer
```

```text
Routing
```

décide :

```text
où envoyer
```

```text
NAT
```

décide :

```text
comment modifier les adresses
```

```text
WireGuard
```

assure :

```text
tunnel chiffré + association clés/IP
```

---

# 79. Résumé Stateful Firewalling

Tu dois savoir expliquer :

```text
ct state
```

et les états :

```text
NEW
ESTABLISHED
RELATED
INVALID
```

Une règle essentielle :

```bash
ct state established,related accept
```

Et le principe principal :

```text
default deny
```

---

# 80. Résumé WireGuard

Chaque peer possède :

```text
private key
public key
```

La clé publique identifie le peer.

```text
AllowedIPs
```

associe :

```text
clé
+
adresses IP
+
routage
```

Le serveur écoute généralement sur un port UDP.

Un client utilise :

```text
Endpoint
```

pour savoir où contacter le serveur.

---

# 81. Résumé Routing

Pour transformer Linux en routeur :

```text
net.ipv4.ip_forward = 1
```

Le routage :

```text
transmet les paquets
```

Le NAT :

```text
modifie leurs adresses
```

Et :

```text
masquerade
```

utilise l’adresse de sortie du serveur comme adresse source.

---

# 82. Résumé Operational Safety

Avant de modifier un firewall distant :

```text
backup
+
rollback automatique
+
session SSH ouverte
+
test depuis une seconde session
```

Pour rendre nftables persistant :

```bash
nft list ruleset > /etc/nftables.conf
systemctl enable nftables
```

Pour vérifier les services :

```bash
ss -lntup
```

Pour vérifier WireGuard :

```bash
wg show
```

Pour vérifier les routes :

```bash
ip route
```

Pour vérifier le forwarding :

```bash
sysctl net.ipv4.ip_forward
```

---

# Cheat Sheet

```bash
# Voir les règles nftables
nft list ruleset

# Vérifier un fichier nftables
nft -c -f /etc/nftables.conf

# Charger les règles
nft -f /etc/nftables.conf

# Sauvegarder
nft list ruleset > /etc/nftables.conf

# Vérifier les connexions en écoute
ss -lntup

# Vérifier ip_forward
sysctl net.ipv4.ip_forward

# Activer temporairement le forwarding
sysctl -w net.ipv4.ip_forward=1

# Voir les routes
ip route

# Voir les interfaces
ip addr

# WireGuard
wg show

# Activer WireGuard
wg-quick up wg0

# Désactiver WireGuard
wg-quick down wg0

# Activer au démarrage
systemctl enable wg-quick@wg0

# Générer une clé privée
wg genkey > privatekey

# Générer une clé publique
wg pubkey < privatekey > publickey

# Observer wg0
tcpdump -ni wg0

# Observer l’interface Internet
tcpdump -ni eth0
```

---

# Schéma global

```text
                       INTERNET
                           |
                           |
                        eth0
                           |
                  +----------------+
                  |  Linux Server  |
                  |                |
                  |    nftables    |
                  |       +        |
                  |    routing     |
                  |       +        |
                  |      NAT       |
                  +----------------+
                           |
                          wg0
                           |
                    WireGuard VPN
                           |
                    10.10.0.0/24
                           |
                     VPN Client
                      10.10.0.2
```

Le chemin logique est :

```text
Client VPN
    ↓
WireGuard
    ↓
wg0
    ↓
Firewall FORWARD
    ↓
Kernel Routing
    ↓
NAT / Masquerade
    ↓
eth0
    ↓
Internet
```

Pour le retour :

```text
Internet
    ↓
eth0
    ↓
Conntrack / NAT inverse
    ↓
Firewall ESTABLISHED
    ↓
wg0
    ↓
WireGuard
    ↓
Client VPN
```

---

# Ce qu’il faut vraiment retenir

Si tu ne devais mémoriser que quelques idées :

```text
1. Un firewall stateful connaît l’état des connexions.
2. NEW démarre une connexion.
3. ESTABLISHED appartient à une connexion existante.
4. RELATED est lié à une autre connexion.
5. Default deny = tout bloquer sauf ce qui est explicitement autorisé.
6. Les règles fréquentes doivent être placées tôt.
7. WireGuard associe clés cryptographiques et AllowedIPs.
8. AllowedIPs sert à la fois au routage et à l’identification des peers.
9. ip_forward permet à Linux de router entre interfaces.
10. Routage et NAT sont deux choses différentes.
11. Masquerade remplace l’IP source par l’IP de sortie du serveur.
12. Sans NAT ou route retour correcte, les réponses peuvent ne jamais revenir.
13. Toujours prévoir un rollback avant de modifier un firewall à distance.
14. Toujours tester les règles après application.
```