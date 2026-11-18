# Blank Sicaf and Consulta keep the tree order

**Sections**: 1. Goal · 2. Out of scope · 3. Decisions to confirm · 4. Decided rules · 5. What changes · 6. Stages · 7. Manual tests

- **Status:** ready to code
- **Requested on:** 18/11/2026 · **Deadline or priority:** next after the v0.18.5 tests
- **Planned version:** 0.18.6 (stage 1), 0.18.7, 0.18.8 — a follow-up of the v0.18.5 skip, not a new feature

## 1. Goal (what for)

The CGOC standard order in payment processes is Sicaf → Consulta Simples Nacional → Anexo Instrumento de Cobrança → Folha de Encaminhamento, and SEI 5.0.4 cannot reorder documents. When a site is skipped or fails (v0.18.5), the extension keeps that order with a named document without PDF, and later attaches the PDF to it.

## 2. Out of scope

- Reordering documents (not possible in SEI 5.0.4).
- Making the Folha de Encaminhamento (separate idea in `melhorias-futuras.md`).

## 3. Decisions to confirm

None open (all answered by the user on 18/11/2026; see section 4).

## 4. Decided rules

- R1 – A blank document (no PDF) is created **only for an earlier position, and only when a later document of the same company is really added**. Example: SICAF skipped, Simples OK → blank Sicaf, then Consulta with PDF, then Anexos.
- R2 – SICAF and Simples both skipped or failed for a company → **nothing** is added for it (no blank Sicaf, no Consulta, no Anexo); its invoices stay pending.
- R3 – SICAF OK, Simples skipped or failed → Sicaf with PDF, **blank Consulta**, then the Anexos (the Anexo counts as "a later document").
- R4 – The blank document gets the **full normal name** ("Nome na Árvore" as with PDF: SICAF name or, when the SICAF was skipped, the Simples "Nome Empresarial" or the invoice supplier; Consulta: "Consulta Simples Nacional <nome>"). Only difference: no PDF.
- R5 – Later, a named Sicaf/Consulta without PDF counts as missing: its invoice shows as pending, and when the user chooses to add it, the extension searches and **attaches the PDF to that same document** ("Alterar Documento Externo"), not a new one.
- R6 – Which company a blank Sicaf belongs to: the CNPJ in the **Consulta PDF right after it**; the name is only a backup check. A blank Consulta: the Sicaf PDF right before it (same idea).
- R7 – A Sicaf or Consulta without PDF **before the last Folha** (process going to finance): red notice in the process "Sicaf sem PDF: <empresa>" (or Consulta), still allowing to attach the PDF.
- R8 – Blank document created by **another unit** (the SEI lets only the creating unit change it): warn "O Sicaf em branco foi criado pela unidade X; só ela pode anexar o PDF" and add nothing for that company.
- The confirmation window marks these items: "Sicaf – sem PDF (complete depois)".

## 5. What changes

- Sites and pages: SEI only (process tree, confirmation window, final window after a skip).
- Data written: SEI external documents without file (same fields as today: date, Nato-digital, Público); "Alterar" of an existing named one to attach the PDF.
- Screens: confirmation window labels; red notice in the process (R7); other-unit warning (R8).
- Likely code: `comum/sicaf.js` (`documentosParaIncluir`, `situacaoDoProcesso`, `aproveitarEmBranco`, `trechoPendente`), `sites/sei/sicaf.js`.
- Check first: how the tree shows which unit created a document (R8) — may need a saved page in `ferramentas-de-teste/paginas-sei/`.

## 6. Stages

- [ ] Stage 1 – Rules in `comum/sicaf.js` with tests: R1–R3 (what to create, blank items), R4 (names). Confirmation window labels. Creation without PDF in the SEI.
- [ ] Stage 2 – R5 + R6: detect named Sicaf/Consulta without PDF, link by the neighbour's CNPJ, attach the PDF to it.
- [ ] Stage 3 – R7 (red notice before the last Folha) and R8 (other unit).

## 7. Manual tests

Each stage's tests go to `TESTES-PENDENTES.md` (numbers T…, in Portuguese). Stage 1 writes to the SEI: its test is critical.
