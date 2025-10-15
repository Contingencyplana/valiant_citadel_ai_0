# Exchange Mirror (Local)

Use `exchange/inbox` and `exchange/outbox` as a local mirror for orders, reports, and alerts if the central exchange is unavailable or as a staging area.

- Inbox: `exchange/inbox` — items to be processed by the safety watcher
- Outbox: `exchange/outbox` — items prepared here to be published upstream
- Templates: `exchange/templates` — message templates for common actions

See `exchange/interfaces.md` for the set of supported message types.
