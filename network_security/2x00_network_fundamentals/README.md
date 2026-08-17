# Networking Fundamentals — Binary, Subnetting, Routing & OSI

## Learning Objectives

À la fin de ce projet, vous devez être capable d'expliquer sans l'aide de Google :

### Binary & Addressing
- Convertir du décimal en binaire et du binaire en décimal
- Comprendre pourquoi une adresse IPv4 contient 32 bits
- Comprendre le rôle des 4 octets d'une adresse IPv4
- Comprendre le fonctionnement d'un masque au niveau binaire
- Comprendre la relation entre CIDR et les masques décimaux

### Subnetting
- Calculer le Network ID
- Calculer l'adresse Broadcast
- Déterminer la plage d'hôtes utilisables
- Utiliser VLSM

### Routing Decisions
- Déterminer si une destination est locale ou distante
- Comprendre pourquoi ARP est utilisé localement
- Comprendre le fonctionnement d'une table de routage
- Comprendre le rôle du TTL

### OSI Model
- Comprendre le rôle de la couche 2
- Comprendre le rôle de la couche 3
- Comprendre pourquoi la MAC de la gateway est nécessaire
- Comprendre les notions On-link et Off-link

---

# 1. Binaire

Les ordinateurs travaillent avec des **bits**.

Un bit possède seulement deux valeurs possibles :

```text
0
1
```

Un groupe de 8 bits est appelé un **octet**.

```text
1 octet = 8 bits
```

Chaque position d'un octet possède une valeur :

```text
128  64  32  16  8  4  2  1
```

---

# 2. Conversion décimal vers binaire

Prenons le nombre :

```text
192
```

On cherche quelles puissances de 2 permettent d'obtenir 192 :

```text
128 + 64 = 192
```

On place donc les bits :

```text
128 64 32 16 8 4 2 1
 1   1  0  0 0 0 0 0
```

Résultat :

```text
192 = 11000000
```

Autre exemple :

```text
168 = 128 + 32 + 8
```

Donc :

```text
128 64 32 16 8 4 2 1
 1   0  1  0 1 0 0 0
```

Résultat :

```text
168 = 10101000
```

---

# 3. Conversion binaire vers décimal

Prenons :

```text
11001010
```

On associe chaque bit à sa valeur :

```text
128 64 32 16 8 4 2 1
 1   1  0  0 1 0 1 0
```

On additionne les valeurs correspondant aux `1` :

```text
128 + 64 + 8 + 2 = 202
```

Donc :

```text
11001010 = 202
```

---

# 4. Adresse IPv4

Une adresse IPv4 contient **32 bits**.

Elle est divisée en quatre octets :

```text
192.168.1.10
```

Chaque partie contient 8 bits :

```text
192       168       1         10
 ↓         ↓        ↓          ↓
8 bits   8 bits   8 bits     8 bits
```

Donc :

```text
8 + 8 + 8 + 8 = 32 bits
```

Une adresse IPv4 peut donc être représentée en binaire :

```text
192.168.1.10

11000000.10101000.00000001.00001010
```

Comme un octet contient 8 bits, sa valeur peut aller de :

```text
00000000 = 0
```

à :

```text
11111111 = 255
```

C'est pourquoi chaque octet d'une IPv4 est compris entre `0` et `255`.

---

# 5. Masque de sous-réseau

Une adresse IP seule ne permet pas de savoir quelle partie représente le réseau.

On utilise pour cela un **masque de sous-réseau**.

Exemple :

```text
IP      : 192.168.1.42
Masque  : 255.255.255.0
```

En binaire :

```text
11111111.11111111.11111111.00000000
```

Les bits à `1` représentent la partie réseau.

Les bits à `0` représentent la partie hôte.

```text
11111111.11111111.11111111 | 00000000
           NETWORK          |    HOST
```

---

# 6. Notation CIDR

CIDR permet d'écrire un masque plus simplement.

Par exemple :

```text
255.255.255.0
```

en binaire :

```text
11111111.11111111.11111111.00000000
```

Il possède 24 bits à `1`.

On écrit donc :

```text
/24
```

Quelques masques importants :

| CIDR | Masque | Bits hôtes |
|------|--------|------------|
| /8 | 255.0.0.0 | 24 |
| /16 | 255.255.0.0 | 16 |
| /24 | 255.255.255.0 | 8 |
| /25 | 255.255.255.128 | 7 |
| /26 | 255.255.255.192 | 6 |
| /27 | 255.255.255.224 | 5 |
| /28 | 255.255.255.240 | 4 |
| /29 | 255.255.255.248 | 3 |
| /30 | 255.255.255.252 | 2 |

La formule pour connaître le nombre de bits hôtes est :

```text
32 - CIDR
```

Exemple :

```text
/26

32 - 26 = 6 bits hôtes
```

---

# 7. Network ID

Le **Network ID** représente le réseau auquel appartient une adresse.

Prenons :

```text
IP     : 192.168.1.70
Masque : 255.255.255.192
CIDR   : /26
```

Pour trouver le Network ID, on effectue un **AND binaire** entre l'IP et le masque.

Les règles du AND sont :

```text
0 AND 0 = 0
0 AND 1 = 0
1 AND 0 = 0
1 AND 1 = 1
```

Regardons le dernier octet.

```text
70  = 01000110
192 = 11000000
```

AND :

```text
01000110
11000000
--------
01000000
```

`01000000` correspond à :

```text
64
```

Le Network ID est donc :

```text
192.168.1.64
```

---

# 8. Adresse Broadcast

Le broadcast correspond à la dernière adresse du sous-réseau.

Pour le trouver, on place tous les bits hôtes à `1`.

Avec :

```text
192.168.1.70/26
```

nous avons :

```text
Network = 192.168.1.64
```

Un `/26` possède :

```text
32 - 26 = 6 bits hôtes
```

Six bits à `1` donnent :

```text
00111111
```

En décimal :

```text
32 + 16 + 8 + 4 + 2 + 1 = 63
```

Donc :

```text
64 + 63 = 127
```

Broadcast :

```text
192.168.1.127
```

---

# 9. Plage d'hôtes

Nous avons maintenant :

```text
Network   : 192.168.1.64
Broadcast : 192.168.1.127
```

Dans un sous-réseau IPv4 classique :

```text
Premier hôte = Network + 1
Dernier hôte = Broadcast - 1
```

Donc :

```text
Network       : 192.168.1.64
Premier hôte  : 192.168.1.65
Dernier hôte  : 192.168.1.126
Broadcast     : 192.168.1.127
```

---

# 10. Nombre d'hôtes

La formule classique est :

```text
2^(bits hôtes) - 2
```

Le `-2` correspond traditionnellement au :

```text
Network ID
Broadcast
```

Exemple avec `/24` :

```text
32 - 24 = 8 bits

2^8 - 2
= 256 - 2
= 254 hôtes
```

Avec `/26` :

```text
32 - 26 = 6

2^6 - 2
= 64 - 2
= 62 hôtes
```

---

# 11. Méthode rapide de subnetting

Prenons :

```text
172.16.5.140/26
```

Le masque `/26` est :

```text
255.255.255.192
```

Le dernier octet vaut :

```text
192
```

La taille d'un bloc peut être calculée avec :

```text
256 - 192 = 64
```

Les sous-réseaux commencent donc tous les 64 :

```text
0
64
128
192
```

L'adresse `140` se trouve entre :

```text
128 et 191
```

Donc :

```text
Network   : 172.16.5.128
Broadcast : 172.16.5.191
```

Les hôtes utilisables sont :

```text
172.16.5.129
       ↓
172.16.5.190
```

---

# 12. VLSM

VLSM signifie :

```text
Variable Length Subnet Mask
```

VLSM permet d'utiliser différentes tailles de sous-réseaux afin d'éviter de gaspiller les adresses IP.

Imaginons :

```text
192.168.1.0/24
```

Nous devons créer trois réseaux :

```text
Développement : 100 machines
RH            : 40 machines
Direction     : 10 machines
```

Pour 100 machines :

```text
2^7 - 2 = 126
```

Il faut donc 7 bits hôtes :

```text
/25
```

Pour 40 machines :

```text
2^6 - 2 = 62
```

Donc :

```text
/26
```

Pour 10 machines :

```text
2^4 - 2 = 14
```

Donc :

```text
/28
```

Avec VLSM, on attribue donc uniquement la quantité d'adresses nécessaire.

Une bonne pratique est de commencer par le réseau ayant besoin du plus grand nombre d'adresses.

---

# 13. Destination locale ou distante

Une machine doit déterminer si la destination est :

```text
LOCAL
```

ou :

```text
REMOTE
```

Prenons :

```text
PC :

IP      : 192.168.1.10
Masque  : /24
Gateway : 192.168.1.1
```

Le réseau du PC est :

```text
192.168.1.0/24
```

Si le PC veut contacter :

```text
192.168.1.50
```

la destination appartient également à :

```text
192.168.1.0/24
```

La destination est donc locale.

On dit également :

```text
ON-LINK
```

---

# 14. Destination distante

Si le PC veut contacter :

```text
8.8.8.8
```

cette adresse n'appartient pas à :

```text
192.168.1.0/24
```

Elle est donc distante :

```text
OFF-LINK
```

Le PC doit utiliser sa table de routage pour savoir où envoyer le paquet.

Généralement, il utilisera sa **default gateway**.

```text
PC
192.168.1.10
      |
      v
Gateway
192.168.1.1
      |
      v
Internet
      |
      v
8.8.8.8
```

---

# 15. ARP

ARP signifie :

```text
Address Resolution Protocol
```

ARP permet principalement de faire la correspondance entre :

```text
Adresse IPv4
     ↓
Adresse MAC
```

Prenons deux machines locales :

```text
PC A
192.168.1.10

PC B
192.168.1.20
```

PC A veut envoyer une trame Ethernet à PC B.

Il connaît :

```text
192.168.1.20
```

mais il lui faut l'adresse MAC correspondante.

ARP permet essentiellement de demander :

```text
Qui possède 192.168.1.20 ?
```

La machine concernée répond avec son adresse MAC.

---

# 16. Pourquoi ARP est local

ARP fonctionne sur le lien local.

Si ton ordinateur veut contacter :

```text
8.8.8.8
```

il ne cherche pas directement :

```text
MAC de 8.8.8.8
```

La destination est distante.

Il cherche plutôt la MAC de son prochain saut local :

```text
MAC de la gateway
```

Par exemple :

```text
Destination IP :
8.8.8.8

Next Hop :
192.168.1.1

ARP :
Quelle est la MAC de 192.168.1.1 ?
```

---

# 17. Table de routage

Une machine utilise sa table de routage pour décider où envoyer un paquet.

Sous Linux :

```bash
ip route
```

Exemple :

```text
192.168.1.0/24 dev eth0
default via 192.168.1.1
```

Cela signifie :

```text
192.168.1.0/24
→ directement accessible via eth0
```

et :

```text
default
→ utiliser 192.168.1.1
```

La route `default` est utilisée lorsqu'aucune route plus spécifique ne correspond.

---

# 18. Next Hop

Le **Next Hop** représente le prochain équipement réseau auquel envoyer le paquet.

Exemple :

```text
PC
 |
 v
Router A
 |
 v
Router B
 |
 v
Router C
 |
 v
Serveur
```

Pour le PC, le Next Hop est :

```text
Router A
```

Router A consulte ensuite sa propre table de routage.

Son Next Hop peut être :

```text
Router B
```

Et ainsi de suite.

---

# 19. Longest Prefix Match

Un routeur peut avoir plusieurs routes correspondant à une destination.

Exemple :

```text
10.0.0.0/8
10.10.0.0/16
10.10.20.0/24
```

Destination :

```text
10.10.20.50
```

Les trois réseaux correspondent.

Mais :

```text
/24
```

est plus précis que :

```text
/16
```

et `/16` est plus précis que `/8`.

Le routeur choisit donc :

```text
10.10.20.0/24
```

Ce mécanisme s'appelle :

```text
Longest Prefix Match
```

---

# 20. TTL

TTL signifie :

```text
Time To Live
```

Chaque paquet IPv4 possède un TTL.

Exemple :

```text
TTL = 64
```

Chaque routeur traversé décrémente cette valeur.

```text
PC
TTL 64
 |
 v
Router 1
TTL 63
 |
 v
Router 2
TTL 62
 |
 v
Router 3
TTL 61
```

Lorsque le TTL atteint :

```text
0
```

le paquet est supprimé.

---

# 21. Pourquoi le TTL existe

Le TTL évite qu'un paquet circule indéfiniment à cause d'une boucle de routage.

Sans TTL :

```text
Router A
   ↓
Router B
   ↓
Router C
   ↓
Router A
   ↓
Router B
   ↓
...
```

Avec TTL :

```text
4
↓
3
↓
2
↓
1
↓
0
↓
DROP
```

Le paquet finit donc obligatoirement par disparaître.

---

# 22. Modèle OSI pratique

Deux couches sont particulièrement importantes pour comprendre le routage :

```text
Layer 2 → Data Link
Layer 3 → Network
```

---

## Layer 2 — Data Link

La couche 2 travaille notamment avec Ethernet et les adresses MAC.

Une trame Ethernet contient :

```text
MAC source
MAC destination
```

Elle permet la communication avec un équipement présent sur le lien local.

---

## Layer 3 — Network

La couche 3 travaille avec les adresses IP.

Un paquet IP contient notamment :

```text
IP source
IP destination
TTL
```

Les routeurs utilisent l'adresse IP de destination pour décider vers quel réseau transmettre le paquet.

---

# 23. MAC de la gateway

Prenons :

```text
PC

IP  : 192.168.1.10
MAC : AA:AA:AA:AA:AA:AA
```

Gateway :

```text
IP  : 192.168.1.1
MAC : BB:BB:BB:BB:BB:BB
```

Destination Internet :

```text
8.8.8.8
```

Le paquet IP contient :

```text
IP source      : 192.168.1.10
IP destination : 8.8.8.8
```

Mais la première trame Ethernet contient :

```text
MAC source      : AA:AA:AA:AA:AA:AA
MAC destination : BB:BB:BB:BB:BB:BB
```

La destination MAC est donc celle de la gateway.

La destination IP reste celle du serveur final.

C'est une distinction essentielle :

```text
IP destination
=
destination finale

MAC destination
=
prochain équipement sur le lien local
```

---

# 24. On-link et Off-link

## On-link

Une destination est **On-link** lorsqu'elle est directement accessible sur un réseau connecté à la machine.

Exemple :

```text
PC          : 192.168.1.10/24
Destination : 192.168.1.50
```

Les deux appartiennent à :

```text
192.168.1.0/24
```

Donc :

```text
ON-LINK
```

La machine peut communiquer directement avec la destination sur le réseau local.

---

## Off-link

Prenons :

```text
PC          : 192.168.1.10/24
Destination : 10.20.30.40
```

`10.20.30.40` n'appartient pas à :

```text
192.168.1.0/24
```

La destination est :

```text
OFF-LINK
```

Une route est nécessaire.

Généralement :

```text
PC
 ↓
Default Gateway
 ↓
Routeurs
 ↓
Destination
```

---

# 25. Exemple complet

Configuration :

```text
PC

IP      : 192.168.10.25
Masque  : /24
Gateway : 192.168.10.1
```

Le PC veut contacter :

```text
8.8.8.8
```

## Étape 1 — Calcul du réseau local

Avec `/24` :

```text
Network = 192.168.10.0
```

---

## Étape 2 — Vérification de la destination

Destination :

```text
8.8.8.8
```

Elle n'appartient pas à :

```text
192.168.10.0/24
```

Donc :

```text
OFF-LINK
```

---

## Étape 3 — Table de routage

Le PC cherche une route vers `8.8.8.8`.

S'il n'existe aucune route plus précise, il utilise :

```text
default via 192.168.10.1
```

---

## Étape 4 — ARP

Le prochain saut est :

```text
192.168.10.1
```

Le PC doit connaître sa MAC.

Il peut donc utiliser ARP pour résoudre :

```text
192.168.10.1
        ↓
adresse MAC de la gateway
```

---

## Étape 5 — Création de la trame

La couche 2 utilise :

```text
MAC source      = MAC du PC
MAC destination = MAC de la gateway
```

La couche 3 utilise :

```text
IP source      = 192.168.10.25
IP destination = 8.8.8.8
```

---

## Étape 6 — Routage

La gateway reçoit la trame.

Elle récupère le paquet IP et regarde :

```text
IP destination = 8.8.8.8
```

Elle consulte sa propre table de routage.

Elle détermine ensuite son prochain saut.

Le TTL est décrémenté.

Le processus continue jusqu'à atteindre la destination.

---

# 26. Méthode pour résoudre un subnetting

Lorsqu'on vous donne :

```text
IP : X.X.X.X/YY
```

vous pouvez suivre cette méthode :

```text
1. Trouver le masque correspondant au CIDR

2. Identifier les bits réseau

3. Identifier les bits hôtes

4. Effectuer :
   IP AND MASK

5. Trouver le Network ID

6. Mettre tous les bits hôtes à 1

7. Trouver le Broadcast

8. Calculer :
   Network + 1

9. Calculer :
   Broadcast - 1
```

Vous obtenez alors :

```text
Network ID
Broadcast
Premier hôte
Dernier hôte
Nombre d'hôtes
```

---

# 27. Commandes Linux utiles

Afficher les interfaces et adresses :

```bash
ip addr
```

Afficher la table de routage :

```bash
ip route
```

Afficher les voisins connus :

```bash
ip neigh
```

Tester une destination :

```bash
ping <IP>
```

Observer les routeurs traversés :

```bash
traceroute <IP>
```

---

# 28. Résumé

## IPv4

```text
IPv4 = 32 bits
```

```text
1 octet = 8 bits
```

```text
IPv4 = 4 octets
```

---

## Masque

Les `1` représentent la partie réseau :

```text
11111111.11111111.11111111.00000000
```

Les `0` représentent la partie hôte.

---

## CIDR

```text
/24
```

signifie :

```text
24 bits réseau
8 bits hôtes
```

---

## Network ID

Le Network ID est obtenu avec :

```text
IP AND MASK
```

---

## Broadcast

Le Broadcast est obtenu en mettant :

```text
tous les bits hôtes à 1
```

---

## Hosts

Dans un sous-réseau IPv4 classique :

```text
Premier hôte = Network + 1
Dernier hôte = Broadcast - 1
```

---

## Routage

La machine commence par déterminer :

```text
La destination est-elle locale ?
```

Puis :

```text
                 Destination
                     |
             Même réseau ?
               /         \
             OUI         NON
              |           |
          ON-LINK     OFF-LINK
              |           |
             ARP      Table routage
                          |
                       Gateway
                          |
                         ARP
                          |
                      Next Hop
```

---

## OSI

```text
Layer 2
→ Ethernet
→ MAC
→ Trames
→ Communication sur le lien
```

```text
Layer 3
→ IP
→ Routage
→ Paquets
→ TTL
→ Network ID
```

---

# Conclusion

Pour comprendre le routage IP, il faut toujours se poser trois questions :

```text
1. À quel réseau appartient mon adresse IP ?

2. La destination appartient-elle à un réseau directement accessible ?

3. Si non, quel est le prochain saut indiqué par ma table de routage ?
```

Le chemin général est alors :

```text
Application
     |
     v
Destination IP
     |
     v
Calcul réseau
     |
     +---- ON-LINK ----> ARP destination
     |
     +---- OFF-LINK ---> Table de routage
                              |
                              v
                           Gateway
                              |
                              v
                         ARP gateway
                              |
                              v
                         Trame Ethernet
                              |
                              v
                            Router
                              |
                              v
                         Next Hop...
```

La couche 3 détermine **où le paquet doit aller**, tandis que la couche 2 permet de l'envoyer **au prochain équipement sur le lien local**.