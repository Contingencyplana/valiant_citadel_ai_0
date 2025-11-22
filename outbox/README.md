Local staging area for Exchange artifacts.

- Stage orders in `outbox/orders/`
- Stage acks in `outbox/acks/`
- Stage reports in `outbox/reports/`

Sync to hub using either:
- Preferred cadence: `python tools/end_of_block.py`
- Fallback: `python tools/exchange_all.py`
