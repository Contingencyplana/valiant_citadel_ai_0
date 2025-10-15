# Exchange Mirror (Local)

Use `exchange/inbox` and `exchange/outbox` as a local mirror for orders, reports, and alerts if the central exchange is unavailable or as a staging area.

- Inbox: `exchange/inbox` — items to be processed by the safety watcher
- Outbox: `exchange/outbox` — items prepared here to be published upstream
- Templates: `exchange/templates` — message templates for common actions

See `exchange/interfaces.md` for the set of supported message types.

## Wiring to High Command

- Configure `exchange/config.json` based on `exchange/config.example.json`.
- Local path mode (no network): set `upstream.mode` to `local` and `upstream.path` to your checked-out `high_command_exchange`.
- Publish outbox → upstream:
  - `pwsh -NoProfile -File tools/ci/publish_outbox.ps1 -ConfigPath exchange/config.json`
- Pull inbox ← upstream:
  - `pwsh -NoProfile -File tools/ci/pull_inbox.ps1 -ConfigPath exchange/config.json`

When network is enabled, we can add a `git` mode that commits and pushes to the upstream exchange repo.
