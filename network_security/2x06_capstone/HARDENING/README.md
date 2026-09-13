# HARDENING usage guide

Run the scripts as root, from this directory, in this order:

```bash
bash clean.sh
bash vpn_setup.sh
# Add a real WireGuard peer and verify: ping 10.8.0.1
bash firewall.sh
```

Never run `firewall.sh` until WireGuard is connected and tested. The firewall
script refuses to run if `wg0` is down and schedules `nft flush ruleset` with
`at` before applying its default-deny policy.

## Access plan

| Role | VPN address | Permitted local service |
|---|---:|---|
| Gateway | `10.8.0.1` | WireGuard UDP/51820 |
| IT | `10.8.0.10` | SSH TCP/22 |
| Finance | `10.8.0.20` | Explicit FTPS TCP/21 and TCP/50000-50100 |
| Database client | `10.8.0.30` | MySQL TCP/3306 |

`vpn_setup.sh` creates commented peer templates in `/etc/wireguard/wg0.conf`.
Replace the appropriate public-key placeholder, uncomment that peer, then run:

```bash
wg syncconf wg0 <(wg-quick strip wg0)
```

Client template: `/etc/wireguard/client_template.conf`.

After `firewall.sh`, test IT SSH, Finance FTPS, and database access immediately.
The output prints the panic job number. Cancel it only after all checks pass:

```bash
atq
atrm <job-id>
```

All addresses, ports, delays, and paths are in `config.sh`. An environment value
overrides its default, for example:

```bash
PANIC_DELAY=10 bash firewall.sh
VPN_PORT=1194 bash firewall.sh
VPN_SERVER_IP=192.168.10.1/24 bash vpn_setup.sh
```

`clean.sh` backs up SSH, vsftpd, the persistence cron file, and `/etc/run.sh`
with a `.backup` suffix before changing them. For lockout prevention, it refuses
to disable root/password SSH until at least one non-root account has a populated
`authorized_keys` file.
