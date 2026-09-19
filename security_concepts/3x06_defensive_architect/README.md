Introduction
"The only truly secure system is one that is powered off, cast in a block of concrete and sealed in a lead-lined room with armed guards, and even then I have my doubts." — Gene Spafford

You have reached the summit. This is not a drill.

This is a simulation of a real-world engagement. In previous projects, you learned discrete skills. Now, you must deal with the messy reality of a company that viewed security as an afterthought.

Why this matters
In the real world, clients rarely give you a clean list of requirements. They give you a messy office, a stressed team, and a deadline. Your ability to walk into a chaotic environment, identify the "Burning Fires" (Critical Risks), and implement a coherent strategy without killing the business is what makes you a Senior professional.

Context
The Client: Nexus Financial. A FinTech startup preparing for its IPO.

The Vibe: "Move Fast, Break Things, Get Rich."

The Deadline: The External Auditor arrives in 5 Days. If they fail, the IPO is dead.

You are the Interim CISO. You arrived this morning. Here are your raw notes from your first 4 hours on site. You must analyze this mess to build your plan.

1. Physical Walkthrough (The Office)
The office is in a trendy co-working space in San Francisco (WeWork style).

Front Desk: There is no receptionist. The iPad for visitor check-in is broken. You walked straight in.

The "Server Room": It's actually a glass-walled meeting room renamed "The Core".

The door has a biometric lock, but it is propped open with a fire extinguisher because "the AC is broken and servers overheat".

A delivery guy was seen inside creating a TikTok video next to the rack.

Network cables are spaghetti. Several unused switch ports are live.

Workspace: Open space plan.

The Whiteboard: A huge whiteboard in the middle of the room has the Wi-Fi Guest password, the staging DB password, and the CEO's Netflix login written in permanent marker.

Workstations: Everyone uses MacBooks. When they go for lunch/ping-pong, 80% of laptops are left unlocked on desks.

Access: Developers enter the building using a generic keycard. The Office Manager keeps a box of "Spare Cards" under her desk, unlabeled.

2. Interview with the CTO ("Dave")
You: "What is your Security Policy ?"

Dave: "We trust our people. Policies slow us down. We are a family here."

You: "How do you manage SSH keys ?"

Dave: "We have a nexus_master.pem key. It's pinned in the Slack channel #dev-ops so everyone can access Prod if it crashes at night. Efficiency first!"

You: "What about the Database ?"

Dave: "It's Postgres. We opened port 5432 to the internet (0.0.0.0/0) because the remote frontend team in Bali couldn't connect via VPN. It was lagging."

You: "Backups ?"

Dave: "I think the intern, Kevin, wrote a script to dump the DB to an S3 bucket. But Kevin left 3 months ago. I haven't checked since."

3. Interview with the Lead Developer ("Sarah")
"I hate the current setup. I have root access to everything, and it terrifies me. If I type rm -rf by mistake, the company dies."

"We have no logs. Last week the site was down for 2 hours. Dave said it was a DDoS. I think it was a memory leak. We have no way to know."

"The CEO demands to use his birthdate (1975) as the PIN code for the admin panel because he forgets complex passwords."

Your Mission: You have 5 days. You cannot fix everything (culture takes years to change), but you must stop the bleeding. You must deliver a Holistic Security Program that covers:

Governance: Define the rules (Policy) to stop the madness.

Prevention: Lock the doors (Hardening, RBAC, MAC, Physical).

Detection: Install the cameras (Logging, IDS).

Response: Prepare for the breach (IR Plan).

Learning Objectives
By the end of this project, you are expected to be able to explain to anyone, without the help of Google:

How to translate a high-level Risk Assessment into low-level technical controls.

How to design and implement a comprehensive RBAC (Role-Based Access Control) model on Linux.

The practical implementation of Defense in Depth (Network + Host + App + Data + Physical).

How to build a Centralized Logging Architecture that survives a local compromise.

How to draft professional Security Policies and Incident Response Playbooks.

3x06_defensive_architect/
├── policy/                 # Governance Documents
│   ├── threat_model.md
│   ├── access_control_policy.md
│   ├── physical_security_plan.md
│   └── incident_response_plan.md
├── technical/              # Implementation Scripts & Configs
│   ├── hardening.sh
│   ├── rbac_setup.sh
│   ├── network_defense.sh
│   └── logging_setup.sh
└── audit/                  # Proof of Compliance
│  └── final_report.md
└─ README.md
