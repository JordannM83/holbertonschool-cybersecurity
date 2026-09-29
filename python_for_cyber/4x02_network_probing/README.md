# Network Probing avec Python

Ce projet présente les bases d'un scanner réseau TCP/UDP écrit en Python. Il permet d'identifier les ports ouverts, de récupérer les bannières des services, de repérer quelques versions vulnérables et de produire un rapport JSON.

> Utilisez un scanner uniquement sur des machines et des réseaux pour lesquels vous avez une autorisation explicite.

## Objectifs pédagogiques

À la fin de ce projet, vous devez pouvoir expliquer, sans utiliser Google :

- le lien entre le three-way handshake TCP et la programmation avec les sockets (`connect` contre `SYN`) ;
- la différence entre un socket bloquant et un socket non bloquant ;
- pourquoi le multithreading accélère fortement un scan de ports ;
- ce qu'est le banner grabbing et son intérêt en reconnaissance ;
- comment gérer proprement les timeouts et les exceptions réseau.

## 1. Les sockets et le modèle client-serveur

Un socket est un point de communication entre deux programmes. En IPv4, on utilise généralement :

```python
socket.socket(socket.AF_INET, socket.SOCK_STREAM)  # TCP
socket.socket(socket.AF_INET, socket.SOCK_DGRAM)   # UDP
```

Un serveur écoute sur une adresse IP et un port. Un client tente de joindre ce port. Dans ce projet, `scanner.py` crée les sockets, fixe un délai d'attente, puis effectue les probes.

### TCP : le three-way handshake

TCP est orienté connexion. Avant d'échanger des données, il établit une connexion en trois étapes :

1. le client envoie `SYN` ;
2. le serveur répond `SYN-ACK` ;
3. le client répond `ACK`.

L'appel Python `sock.connect((ip, port))` déclenche ce mécanisme au niveau du système d'exploitation. Un port qui accepte la connexion est considéré comme ouvert. Une absence de réponse ou une erreur indique généralement qu'il est fermé, filtré ou inaccessible.

### UDP : pas de handshake

UDP est sans connexion. `scan_udp()` crée un socket `SOCK_DGRAM`, envoie un datagramme vide avec `sendto()` et attend une réponse. Un timeout UDP est ambigu : il peut signifier que le port est ouvert mais silencieux, ou qu'un pare-feu filtre le trafic. C'est pourquoi le projet le signale comme `open/filtered` (`True`), tandis qu'une erreur explicite peut indiquer un port inaccessible.

## 2. Sockets bloquants, timeouts et exceptions

Par défaut, un appel réseau peut attendre indéfiniment. Un scanner ne doit pas rester bloqué sur un seul port :

```python
sock.settimeout(1)
```

Le socket attend au maximum le nombre de secondes indiqué. Le projet intercepte les erreurs avec `try/except OSError` et traite séparément `socket.timeout` pour les probes UDP.

Un socket bloquant attend la fin de l'opération avant de rendre la main. Un socket non bloquant retourne immédiatement et demande au programme de vérifier l'état de l'opération plus tard. Ici, les sockets restent bloquants mais leurs timeouts limitent la durée d'attente ; le parallélisme est obtenu avec des threads.

## 3. Scanner plusieurs ports avec des threads

Scanner les ports un par un est lent : chaque port fermé peut consommer le timeout complet. `scan_ports()` utilise `ThreadPoolExecutor` pour lancer plusieurs tentatives en parallèle :

```python
with ThreadPoolExecutor(max_workers=50) as executor:
    futures = [executor.submit(scan_port, port) for port in ports]
```

`as_completed()` récupère les résultats dès qu'ils arrivent. Le scan est donc plus rapide, sans attendre que les ports précédents terminent. Les résultats finaux sont ensuite triés par numéro de port afin de fournir un rapport stable.

## 4. Banner grabbing et inspection HTTP

Le banner grabbing consiste à envoyer une requête minimale à un service et à lire sa réponse. Une bannière peut révéler le logiciel et sa version, par exemple `vsftpd 2.3.4` ou `nginx/1.18.0`.

Pour le port 80, le projet envoie :

```http
GET / HTTP/1.1
Host: 192.0.2.10
```

Puis il recherche l'en-tête `Server`. Une réponse comme `Server: nginx/1.18.0` est présentée sous la forme `HTTP (nginx/1.18.0)`. Les autres ports reçoivent une requête de bannière générique et les réponses vides ou invalides sont signalées comme `Unknown`.

## 5. Détection élémentaire de vulnérabilités

`check_vulnerability()` compare la bannière à une liste de signatures connues :

- `vsftpd 2.3.4` ;
- `Apache 2.2.8`.

La comparaison est insensible à la casse. Lorsqu'une signature correspond, le terminal affiche `[VULNERABLE]` et le rapport JSON contient `"vulnerability": "YES"`.

Cette logique est volontairement simple : elle signale une version connue, mais ne remplace ni une validation de configuration ni un audit de sécurité complet.

## 6. Options de discrétion et contrôle de la source

Les firewalls et IDS peuvent repérer un grand nombre de probes rapprochées ou séquentielles. Le programme propose :

- `--delay` / `-d` : attend un nombre de secondes avant chaque tentative ;
- `--random` / `-r` : mélange la liste des ports avant le scan ;
- `--interface` / `-i` : fait un `bind((IP, 0))` pour choisir l'adresse IP source.

Ces options ne rendent pas un scan invisible et doivent être utilisées dans un cadre autorisé.

## 7. Résolution DNS inverse

`resolve_hostname()` utilise `socket.gethostbyaddr(ip)` pour rechercher le nom associé à une adresse IP via un enregistrement PTR. Le résultat est affiché dans l'en-tête :

```text
Target: 8.8.8.8 (dns.google)
```

Une adresse peut ne pas avoir de PTR ; dans ce cas, le programme affiche `Unknown` et continue le scan.

## 8. Rapport JSON et séparation du code

Les résultats d'un port ouvert contiennent notamment :

```json
{
  "port": 21,
  "state": "open",
  "service": "vsftpd 2.3.4",
  "vulnerability": "YES"
}
```

Le code est organisé par responsabilité :

- `net_probe.py` : arguments CLI et orchestration ;
- `scanner.py` : sockets, probes TCP/UDP, bannières et scan parallèle ;
- `utils.py` : délai, mélange des ports, validation et helpers ;
- `reporter.py` : écriture du rapport JSON.

Cette séparation facilite les tests, la maintenance et la réutilisation des fonctions sans exécuter automatiquement le scanner.

## Utilisation

Depuis ce dossier :

```bash
python3 net_probe.py -t 127.0.0.1 -p 1-1000
```

Avec délai, ordre aléatoire, interface source et rapport JSON :

```bash
python3 net_probe.py \
  --target 192.168.1.10 \
  --ports 1-1000 \
  --delay 0.5 \
  --random \
  --interface 192.168.1.50 \
  --output scan_results.json
```

Le format d'un intervalle est `START-END`, avec des ports compris entre 1 et 65535.
