#!/usr/bin/env python3
import os

print("Hardened Shield audit")
print(f"Apache configuration: {'present' if os.path.exists('/etc/apache2') else 'missing'}")
print(f"SSH configuration: {'present' if os.path.exists('/etc/ssh/sshd_config') else 'missing'}")
