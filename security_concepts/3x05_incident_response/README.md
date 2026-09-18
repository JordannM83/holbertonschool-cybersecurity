Learning Objectives
By the end of this project, you are expected to be able to explain to anyone, without the help of Google:

The IR Lifecycle:

The six phases of the PICERL Incident Response cycle -- what happens in each phase, in what order, and why skipping phases creates cascading failures downstream.

The difference between Isolation (network cut, process paused, OS still running) and Shutdown (power off) as containment strategies -- what each preserves, what each destroys, and which is appropriate for which scenario.

Why Rebooting a compromised system is almost always the wrong first move: what volatile data lives only in RAM, why it matters for forensics, and what is permanently lost the moment power cycles.

Technical Response:

How to identify a malicious process on a live Linux system using ps, netstat, and lsof -- what indicators in the output signal compromise versus legitimate activity.

How Persistence Mechanisms work: specifically how a malicious crontab entry differs from a legitimate one, and how to identify a live-download-and-execute pattern (curl | bash) as an attacker TTP.

How to use iptables to isolate a compromised host at the network layer without shutting down the OS -- and why a SIGSTOP is preferable to SIGKILL during active forensics.

What Chain of Custody means in a digital forensics context: why you hash artifacts before touching them, how that hash validates evidence integrity in a legal proceeding, and what breaks chain of custody.

Professional Practice:

How to write a Post-Mortem (Root Cause Analysis) report: what sections it must contain, how to frame findings without assigning blame, and how recommendations connect back to specific control gaps.

What GDPR's 72-hour notification requirement means in practice: what triggers the clock, who must be notified, and what information must be included in the notification to the Data Protection Authority.

How to write a public-facing incident statement that is transparent, accurate, and legally defensible -- and what language to avoid.
