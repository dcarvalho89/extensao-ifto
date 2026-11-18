# How to organize a project

**Sections**: CLAUDE.md of the project · docs folder · Writing .md files · Git

Updated on 17/11/2026. Read only when creating or reorganizing a project, or creating a new `.md` file. Model: `/home/berg/Desktop/Sistema Gestão Orçamentária/sistema-orcamento-ifto` (CLAUDE.md, docs/, .claude/).

## CLAUDE.md of the project
- Short (it is loaded in every message). Sections: Language · Economical reading · Documentation · How we work · Who the user is · Reply after changing code · Tests · Version and git · Commands · Conventions (drop the ones that do not apply).
- Programming project: first line after the title `@~/.claude/regras/programacao.md` (imports the programming rules). Project without code: say "no code: do not read `~/.claude/regras/programacao.md`".
- Say exactly what to read at the start (ideally one status file) and where each subject is.

## docs folder
- Programming: `arquitetura.md` (file map) · `regras/` (one file per subject + `LEIA-ME.md`) · `padrao-visual.md` · `melhorias-futuras.md` ("Status" section at the top: done, in progress, pending from the user, planned **[spec]**, not planned; then the ideas, one line each) · `specs/` (`_modelo.md`, one spec per improvement; finished ones in `specs/feitas/`) · `historico.md` (one or two lines per version, with date) · `referencias/`. At the root: `TESTES-PENDENTES.md`.
- Without code: one status file (done, in progress, pending, next steps), one file per subject and a map of the folder's files.

## Writing .md files
- One subject per file; do not repeat in one file what is in another (point to it).
- `##` titles that work as search terms; "**Sections**" index on line 3 (update when creating or renaming a section); short texts.

## Git
All `.md` files in git (except local or unnecessary ones), so another person or computer can continue. Local test and reference files out of git (`.gitignore`).
