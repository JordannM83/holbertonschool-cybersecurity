# Case 3: The Overreach

## 1. What happened

InnovateTech requested a “red team assessment,” but Apex Security Partners did not clarify what the CEO actually expected. Apex interpreted the phrase as a full adversary simulation covering network exploitation, social engineering, physical intrusion, and evasion of detection. A consultant dressed as a courier, tailgated into the headquarters, and entered a server room without a physical-testing addendum, approved locations, or a law-enforcement authorization letter. Security called the police, and the CEO said he had expected website testing and possibly phishing, not a building intrusion. The engagement ended, the incident became local news, and Apex lost reputation and prospective business.

## 2. What rule(s), law(s), or professional standard(s) were violated

- Apex failed its professional duty to clarify ambiguous client requirements and obtain informed, specific consent for high-risk physical and social-engineering activities.
- The physical entry may constitute trespass or another unauthorized-entry offense under applicable local law, even though the consultant believed the engagement authorized it. The absence of a law-enforcement letter increased the operational and legal risk.
- The engagement was inconsistent with NIST SP 800-115, PTES, and standard red-team rules-of-engagement practice requiring precisely defined objectives, targets, methods, personnel, timing, emergency contacts, and stop conditions.
- Apex also failed to exercise due care by allowing a high-impact tactic to proceed without confirming authorized buildings, access areas, safety constraints, and the client's notification/escalation plan.

## 3. What the correct professional behavior would have been

Apex should have translated the CEO's goal into a written test plan and explained the difference between a web application test, phishing exercise, penetration test, and full red-team operation. It should have obtained explicit, informed, written approval for each physical tactic, named every permitted building and room, coordinated with facilities and law enforcement as appropriate, and issued an authorization letter for personnel to carry. Until those approvals existed, the team should have limited testing to the expressly agreed web and phishing activities. If the scope remained ambiguous, the team should have paused and asked for clarification rather than relying on the term “red team.”

## 4. What specific clause(s) in a pre-engagement document would have prevented this outcome

- **Defined objectives and methods:** state exactly whether the engagement covers the website, phishing, social engineering, physical intrusion, network exploitation, or detection-evasion activities; define “red team” rather than relying on the label.
- **Physical-testing addendum:** list authorized buildings, entrances, floors, rooms, dates, hours, disguises, props, tailgating rules, prohibited areas, and safety restrictions.
- **Named authorization and emergency contacts:** identify the executive signatory, facilities/security lead, 24-hour contact, and the person who can order an immediate stop.
- **Law-enforcement and guard notification:** require a signed “get out of jail”/authorization letter, provide consultant identification and a verification phone number, and define whether local police, guards, or monitoring providers receive advance notice.
- **Rules of engagement and stop conditions:** prohibit entry into locations not listed in the addendum; require an immediate stop if confronted, detained, injured, or if a safety or legal concern arises.
- **Change-control and client acknowledgment:** require written approval for any new tactic, location, impersonation, or objective, with the client acknowledging the foreseeable business, legal, and safety risks.
