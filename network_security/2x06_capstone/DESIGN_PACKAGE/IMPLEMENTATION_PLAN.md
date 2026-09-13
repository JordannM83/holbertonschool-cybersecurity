# Plan d'implémentation LogiCorp

## 1. Périmètre et source de configuration

Le livrable comprend trois scripts de durcissement, un fichier de configuration
central et un script de validation :

- `HARDENING/config.sh` : valeurs communes et chemins des fichiers ;
- `HARDENING/vpn_setup.sh` : clés, configuration WireGuard et forwarding IPv4 ;
- `HARDENING/clean.sh` : suppression de la persistance non autorisée, arrêt des
  services inutiles, durcissement SSH et configuration FTPS ;
- `HARDENING/firewall.sh` : règles nftables atomiques avec retour d'urgence ;
- `VALIDATION/tests.sh` : contrôles de régression en lecture seule.

Les variables d'environnement sont prioritaires sur les valeurs par défaut de
`config.sh`. Les scripts doivent être exécutés avec les privilèges nécessaires,
depuis `HARDENING/`, sur une vraie passerelle disposant de WireGuard, nftables,
systemd et des capacités réseau. Un conteneur sans `CAP_NET_ADMIN` ne constitue
pas une validation de déploiement.

Les valeurs par défaut importantes sont `wg0`, `10.8.0.0/24`, `10.8.0.1/24`,
UDP/51820, SSH TCP/22, FTPS TCP/21 et TCP/50000-50100, et MySQL TCP/3306.

## 2. Préparation et sauvegardes

Avant toute modification :

1. confirmer l'interface WAN, les routes retour et les zones réellement
   présentes ;
2. confirmer l'adresse du serveur FTP/DB et l'identité des flux autorisés ;
3. conserver une console ou une session indépendante ;
4. vérifier qu'au moins un compte non-root possède une clé dans
   `authorized_keys` ;
5. sauvegarder les configurations SSH, vsftpd, nftables, WireGuard et les
   fichiers de persistance.

Les scripts utilisent les chemins de `config.sh`, notamment `SSHD_CONFIG`,
`VSFTPD_CONFIG`, `NFTABLES_CONFIG`, `STARTUP_SCRIPT` et `BACKDOOR_CRON`.

## 3. Installer et configurer WireGuard

Configurer d'abord les variables nécessaires, puis exécuter :

```bash
sudo bash HARDENING/vpn_setup.sh
```

Le script installe `wireguard-tools` si nécessaire, crée les clés serveur si
elles n'existent pas, écrit `WG_CONFIG` et `WG_CLIENT_TEMPLATE`, configure
`VPN_SERVER_IP` et `VPN_PORT`, active `net.ipv4.ip_forward=1` dans
`SYSCTL_FORWARD_CONFIG`, puis démarre ou resynchronise `VPN_INTERFACE`.
L'unité `wg-quick@wg0` est activée au démarrage.

Les fichiers de clés et de configuration sont protégés. Les pairs réels ne
doivent être ajoutés qu'après attribution d'une adresse unique et vérification
de leur clé publique. Les placeholders dans le fichier WireGuard doivent être
remplacés avant de distribuer un client.

Vérifications minimales :

```bash
sudo wg show "$VPN_INTERFACE"
sudo ip -4 addr show dev "$VPN_INTERFACE"
sudo sysctl net.ipv4.ip_forward
```

## 4. Nettoyer et durcir l'hôte

Exécuter :

```bash
sudo bash HARDENING/clean.sh
```

`clean.sh` sauvegarde puis supprime `BACKDOOR_CRON`, arrête et désactive tous
les services listés dans `UNNECESSARY_SERVICES`, et refuse de continuer si
aucun compte non-root avec clé SSH n'est disponible.

Le bloc SSH ajouté impose `PermitRootLogin no`,
`PasswordAuthentication no`, `KbdInteractiveAuthentication no`,
`PubkeyAuthentication yes` et `AuthenticationMethods publickey`. La syntaxe est
validée avec `sshd -t` avant installation et la sauvegarde est restaurée si le
rechargement échoue.

Le même script configure le service legacy avec `VSFTPD_CONFIG` : accès
anonyme désactivé, TLS obligatoire pour les connexions et les données, et plage
passive définie par `FTP_PASSIVE_MIN`/`FTP_PASSIVE_MAX`. Il génère ou conserve
le certificat FTPS défini par `FTPS_CERT` et `FTPS_KEY`.

## 5. Appliquer le pare-feu

WireGuard doit être opérationnel avant l'application :

```bash
sudo wg show "$VPN_INTERFACE"
sudo bash HARDENING/firewall.sh
```

Le script construit une configuration temporaire, la valide avec `nft -c`,
programme avant l'installation une commande de secours `nft flush ruleset`,
installe `NFTABLES_CONFIG` en mode 600 puis charge la configuration.

La table `inet logicorp` utilise `DROP` par défaut pour `input`, `forward` et
`output`. Les exceptions sont limitées à la boucle locale, aux connexions
établies, à UDP/`VPN_PORT`, au pair IT vers SSH, au pair Finance vers TCP/21
et la plage passive, et au pair DB vers `DATABASE_PORT`. Les paramètres source,
destination et ports viennent de `config.sh`.

Ne pas annuler la tâche de secours avant d'avoir terminé les tests. Après un
résultat validé, identifier le job avec `atq` puis l'annuler avec `atrm JOB_ID`.

## 6. Valider

Exécuter le contrôle sans modifier l'hôte :

```bash
sudo bash VALIDATION/tests.sh
```

Le script contrôle les politiques nftables et les exceptions, SSH, vsftpd,
WireGuard, les services de `UNNECESSARY_SERVICES`, `BACKDOOR_CRON`, les
paramètres FTPS, le forwarding IPv4, l'adresse et la route VPN, ainsi que le
script de démarrage. `EXPECTED_SUDO_USERS` peut être défini dans
l'environnement, par exemple :

```bash
EXPECTED_SUDO_USERS="admin operator" sudo bash VALIDATION/tests.sh
```

Chaque contrôle produit `[PASS]` ou `[FAIL]`. Le résultat final est
`RESULT: X/Y checks passed` et le script retourne un code non nul si un seul
contrôle échoue. Les tests métier restent nécessaires : handshake WireGuard,
connexion SSH IT, transfert FTPS Finance, refus des flux interdits et
transaction DB réversible.

## 7. Limites et travaux de phase 2

Cette implémentation protège le service legacy sur la passerelle. Elle ne crée
pas automatiquement les VLAN, ne déplace pas la base en DMZ, ne configure pas
de NAT, ne crée pas les comptes sudo et ne fournit pas de haute disponibilité.
Les flux vers une base ou un serveur FTP séparé devront recevoir des règles
`forward` explicitement documentées avant déploiement.

La Phase 2 doit traiter la migration SFTP, la segmentation physique/VLAN, la
revue des privilèges sudo, la protection IPv6 équivalente, la supervision et
la redondance active/passive du gateway.
