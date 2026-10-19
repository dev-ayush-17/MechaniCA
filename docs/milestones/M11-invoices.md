# M11 — Invoices

## 1. Goal

A paid booking gets an immutable GST PDF. FR-INV-001 and FR-INV-002.

## 2. Prerequisites

M10 merged.

## 3. Scope

In: `InvoiceService`, number sequence `MC-YYYYMM-######`, PDF render task, storage path, download on the existing invoice screen by booking id, share via `share_plus` of the downloaded file. Config GSTIN placeholder.

Out: emailing the PDF, credit notes beyond a new version after a bug fix, membership invoices.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `features/invoice/invoice_screen.dart` | Refactor to load by booking id. Remove `mockInvoices.first` | Widget test: missing invoice shows a loading then an error, not someone else's invoice |

## 5. Tasks

1. `test(invoice): number sequence and line items match the payment`.
2. `feat(api): render and store the PDF after paid`.
3. `refactor(invoice): load the booking invoice`.
4. `feat(invoice): download and share the file`.

## 6. Ports

`InvoiceService`, `FileStorage`. Pick one PDF library in this milestone and write the one-line reason in the PR (reportlab or weasyprint). Do not add both.

## 7. Files

`backend/app/adapters/pdf.py`, `features/invoice/`. Add `share_plus` back if M01 removed it, pinned, with the reason "share the invoice file."

## 8. Branch and commits

Branch: `feat/m11-invoices`.

## 9. Tests

- `invoice_total_matches_payment`
- `second_render_keeps_version_one`
- `customer_cannot_read_another_invoice`
- Widget: screen uses the booking id from the route

## 10. Acceptance and manual check

- Given a paid booking, when the task runs, then `GET /v1/invoices/{id}` returns a URL.
- Given the invoice screen, when opened from that booking, then the total matches the payment and not the first mock.
- Given share, when tapped, then the OS share sheet gets a PDF. A snackbar-only share is not done.

Manual: pay with the fake gateway, open the invoice, download it, confirm the registration and the GST lines are visible.

## 11. Definition of done

- [ ] Payment response does not wait on PDF generation.
- [ ] Tests pass.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

PDF libraries and system packages can blow the Docker image. If WeasyPrint needs OS packages you cannot install quickly, use reportlab and move on. Do not block on pixel-perfect layout.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M11 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M11-invoices.md. Branch feat/m11-invoices. Update docs/AGENT_PROGRESS.md and open a PR.
```
