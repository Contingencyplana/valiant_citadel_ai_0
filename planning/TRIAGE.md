# Planning Triage

Purpose: Decide which inherited planning docs to adapt for safety scope.

Disposition Legend
- Keep: directly relevant; minimal edits
- Adapt: refocus to safety gates/runbooks/policy
- Defer: keep for reference; not in current scope

Items
- ai_agents_and_safety.md — Keep (map to policies/agent_registry.md)
- operational_thresholds_and_safety.md — Keep (feed into policy_engine.md)
- command_exchange_protocol.md — Adapt (extract safety message gates)
- field_workspaces.md — Adapt (clarify safety shard usage)
- high_command.md / high_command_triumvirate.md — Defer (link references only)
- battlefields_and_battlegrids.md — Defer
- daylands_and_nightlands.md — Defer
- forge_automation_spec.md — Adapt (ensure change-as-order gates)
- human_players_and_ai_players.md — Adapt (governance rules)
- internal_alfa_architecture.md — Defer (architectural reference only)
- micro_play_and_macro_play.md — Defer
- mindscapes_and_dreamscapes.md — Defer
- morningate_reflection_layer.md — Defer
- playing_in_each_others_minds.md — Defer
- rank_structure.md — Adapt (approval chains, authority caps)
- strategists_and_strategy.md — Defer
- tacticians_and_tactics.md — Defer
- war_rooms_and_war_tables.md — Adapt (incident comms and control room)
- toyfoundry/* — Defer (non-safety; keep references)

Next Actions
- For each “Keep/Adapt”, open a short PR to add a “Safety Notes” section and link to the concrete gate/runbook/policy it informs.
