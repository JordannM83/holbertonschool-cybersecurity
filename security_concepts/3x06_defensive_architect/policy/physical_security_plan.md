# Nexus Financial Physical Security Plan

**Owner:** Office Manager, with oversight from the Interim CISO
**Scope:** Co-working office, Core/server area, employees, visitors, contractors, laptops, and network equipment
**Objective:** Reduce unauthorized entry, equipment tampering, credential exposure, and unsafe human behavior using practical layered controls.

Nexus does not need armed guards or an expensive biometric deployment to establish a
credible physical perimeter. The first layer is disciplined behavior and accountability;
the second is inexpensive access control and monitoring; the final layer is a properly
secured room and managed building service. The co-working provider remains responsible for
building-wide controls, but Nexus is responsible for its people, equipment, and access
decisions.

## 1. Immediate actions — zero cost (today)

These actions use existing staff and equipment and must be completed before the next
working day.

### Secure the Core

- Remove the fire extinguisher and any other door prop. Keep the door closed and locked.
- If cooling is unsafe, shut down or move non-essential equipment using an approved change
  plan; never defeat the lock to solve an availability problem.
- Restrict entry to named infrastructure personnel. The Office Manager maintains the list
  and confirms it with the CTO.
- Stop all deliveries, visitors, filming, and unapproved work inside the Core. Record the
  date, time, person, host, and purpose for every exception.
- Photograph the current racks and cabling, then inspect for unknown devices, changed
  cables, or removable media. Preserve suspicious findings and escalate them to the CISO.

### Control the office perimeter

- Assign a rotating employee as a temporary “door host” during office hours until the
  building's reception/check-in process is restored.
- Ask the co-working operator to repair or replace the visitor iPad immediately. Until
  then, use a paper or shared controlled visitor register containing name, company, host,
  arrival/departure time, and badge number.
- Challenge unknown people politely: “Can I help you find your host?” Do not allow tailgating.
- Require every visitor to have a Nexus host and remain escorted. Visitors may not roam,
  photograph, plug into equipment, or access employee desks.
- Stop sharing generic keycards. Collect and count all spare cards; place them in a
  locked, named inventory under Office Manager control. Revoke cards for former employees.

### Remove exposed information and secure people

- Erase all passwords and other secrets from the whiteboard immediately. Assume exposed
  credentials are compromised and rotate them through the appropriate owners.
- Require employees to lock their MacBook before leaving their desk, even for lunch or
  ping-pong. Until device controls are deployed, managers perform a daily spot check.
- Keep laptops, paper records, badges, and removable media out of visitor sight and away
  from shared meeting areas. Report lost badges or devices immediately.
- Publish one emergency contact path for building incidents, suspicious people, lost
  cards, and Core access failures. Never bypass a safety or security control silently.

## 2. Short term — low cost (within 30 days)

### Access and visitor management

- Replace generic cards with individually assigned cards where the building supports it.
  Maintain an access register with cardholder, areas, issue date, return date, and approver.
- Create a joiner/mover/leaver checklist: access is approved by the manager, issued by the
  Office Manager, reviewed monthly, and revoked on the last working day or immediately
  when risk requires it.
- Use inexpensive temporary visitor badges marked **VISITOR**, a date, and host name.
  Collect badges at departure and reconcile the visitor register each day.
- Require contractors and delivery personnel to show identification, state their task,
  and wait for an employee escort. Deliveries are received at a designated point, never
  in the Core.
- Ask the co-working provider for its incident, access-log, CCTV-retention, emergency,
  and after-hours access procedures. Record the provider contact and escalation number.

### Core, equipment, and workspace controls

- Repair the door sensor and cooling problem through the co-working provider. Configure an
  alert for a door held open and test it monthly.
- Add a low-cost door contact/alarm or camera covering the Core entrance, subject to the
  building's privacy rules. Do not point cameras at screens or record sensitive content.
- Lock network racks and patch panels. Label approved cables, disable unused switch ports,
  and keep a simple rack/cabling diagram under controlled access.
- Mark a clean zone around the Core. No food, filming, personal devices, or unapproved
  storage in that zone.
- Enable automatic screen lock and full-disk encryption through existing Mac settings or
  MDM. Target a short idle timeout and verify compliance weekly.
- Provide lockable drawers or cable locks for laptops when desks are unattended. Store
  paper records and spare keys in locked cabinets.

### Accountability and assurance

- Hold a 15-minute weekly physical-security check: door closed, visitor register complete,
  cards reconciled, whiteboards clean, ports/racks intact, and laptops locked.
- Run a monthly access review with the Office Manager, CTO, and CISO. Compare active staff,
  contractors, cards, and Core permissions.
- Report and investigate tailgating, lost cards, unattended unlocked devices, unauthorized
  photography, and door alarms as security incidents—not as harmless etiquette issues.
- Track evidence for the auditor: visitor logs, card inventory, access reviews, Core checks,
  training attendance, and remediation tickets.

## 3. Long term — planned investment (30–180 days)

These controls should be funded after the immediate risks are contained and the co-working
provider's capabilities are confirmed.

- Move production equipment out of the glass meeting room and into a dedicated, climate-
  controlled data-center or managed cloud environment. The preferred physical control is
  to eliminate local production equipment, not to build a private guarded room.
- Contract with a co-working provider that supplies staffed reception, CCTV, visitor
  management, access logs, secure loading procedures, and documented incident response.
- Integrate named badge access with HR joiner/mover/leaver events and quarterly entitlement
  recertification. Retain access records according to legal and audit requirements.
- Deploy centrally managed MDM/EDR for every MacBook, enforcing encryption, automatic lock,
  firewall, updates, screen privacy, remote lock/wipe, and compliance reporting.
- Add a monitored access-control system for the Core with door-held-open and forced-open
  alerts, backed by a documented fail-safe/fail-secure decision and fire-safety review.
- Establish redundant environmental monitoring for temperature, smoke, water, and power,
  with tested alerts and a maintenance contract.
- Perform an annual physical risk assessment and an unannounced access-control exercise.
  Update the plan after office moves, major staffing changes, or a security incident.

## 4. Training and the “Delivery Guy TikTok” incident

### Required behavior

At onboarding and quarterly thereafter, every employee receives a short, scenario-based
briefing covering:

- Do not hold doors or lend badges. Challenge or report unknown people without confrontation.
- Visitors, couriers, cleaners, and contractors remain in the reception/delivery area unless
  an employee escorts them for a documented reason.
- No photography, video, livestreaming, or social-media posting in the Core or near screens,
  racks, badges, whiteboards, cables, or customer information.
- Lock screens, clear whiteboards, secure devices, and report lost cards immediately.
- Report suspicious activity to the Office Manager/CISO, preserve evidence, and do not post
  incident details publicly.

### Response to this specific event

1. **Intervene safely:** The host or nearest employee stops the filming and escorts the
   delivery person out of the Core. Do not seize a phone or physically confront the person.
2. **Notify:** Tell the Office Manager and CISO immediately; notify the co-working provider
   and the delivery company if the person was a contractor.
3. **Record:** Document identity/company if available, time, route, host, what was visible,
   whether equipment or cables were touched, and witnesses. Preserve relevant access/CCTV
   records and the public post URL or screenshot through approved evidence handling.
4. **Contain:** Rotate any credentials, tokens, or secrets visible in the video. Inspect the
   rack and network connections for tampering and review logs for access during the visit.
5. **Assess and escalate:** Treat visible customer data, credentials, or equipment changes
   as a potential security incident. The CISO determines notification, legal, privacy, and
   contractual escalation requirements.
6. **Close the gap:** Re-brief the delivery process, require escorted delivery access, and
   record corrective actions. Do not punish an employee for reporting the event in good
   faith; use the incident to improve the process.

## 5. Roles and success measures

| Role | Responsibility |
|---|---|
| Office Manager | Visitor register, badge inventory, building-provider relationship, weekly checks |
| CTO / Infrastructure owner | Core access list, rack/cabling integrity, cooling, and equipment moves |
| CISO | Policy, risk acceptance, incident escalation, evidence, and audit reporting |
| People managers | Staff training, screen-lock compliance, joiner/mover/leaver notifications |
| All employees | Challenge/report, escort visitors, protect devices, and follow clean-desk rules |
| Co-working provider | Building access, reception, CCTV, emergency response, and facility maintenance |

Success is measured by: 100% named card ownership; 100% visitor entries with host and
departure time; zero unescorted visitors in the Core; 100% managed laptops locked and
encrypted; monthly access reviews completed; and all physical incidents reported and
closed with evidence.
