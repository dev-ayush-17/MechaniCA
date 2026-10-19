# ADR-003 — One Flutter package and a Flutter web admin

**Status:** accepted. **Date:** 2026-10-19.

The MVP needs a customer app, a mechanic app, and an admin panel. The team is small and the backend is new to them.

**Decision:** One Flutter package with `main_customer.dart`, `main_mechanic.dart`, and `main_admin.dart`. Admin is Flutter web, desktop width only. All three use the generated API client and the same design tokens.

**Why this and not the alternatives:** Two more codebases would duplicate the client and the theme. A React admin adds a second language before the first API is real. If tables become painful, a later admin can sit on the same endpoints.

**Consequences:** Role is chosen at bootstrap, not by a hidden switch inside one binary's home screen. A customer build must not show mechanic job actions.
