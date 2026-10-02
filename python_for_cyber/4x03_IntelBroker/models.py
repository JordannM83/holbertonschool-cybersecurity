"""Data models used by the intelligence broker."""


class TargetDossier:
    """Combined intelligence collected for one target IP address."""

    ip = ""
    vt_data = {}
    abuse_data = {}
    nmap_ports = []

    def __init__(self, ip: str = "", vt_data=None, abuse_data=None,
                 nmap_ports=None):
        self.ip = ip
        self.vt_data = vt_data if isinstance(vt_data, dict) else {}
        self.abuse_data = abuse_data if isinstance(abuse_data, dict) else {}
        self.nmap_ports = list(nmap_ports) if nmap_ports is not None else []

    def summary(self) -> str:
        return (
            f"Target: {self.ip}\n"
            f"VirusTotal: {self.vt_data}\n"
            f"AbuseIPDB: {self.abuse_data}\n"
            f"Open ports: {self.nmap_ports}"
        )
