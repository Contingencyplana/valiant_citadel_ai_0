# Red-Team Scenario: Infinite Farm

Purpose
- Identify and close loops that allow unbounded resource accumulation.

Test Cases
- Vendor/loot duplication via timing exploits
- AFK macro farming bypassing activity checks
- Economy price exploits (buyback loops)

Acceptance
- Exploit attempts flagged; resources rolled back or quarantined
- Economy metrics remain within baseline band
- Rollback drill executed within SLO if exploit hits canary
