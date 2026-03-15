# PR: Add project documentation for Perl 5

## Summary

Add comprehensive project documentation tailored to the Perl 5 implementation. All documentation files are written from scratch for the Perl 5 codebase, covering architecture, contribution guidelines, quick start, and agent instructions.

## Changes

### New files (7)

| File | Lines | Description |
|------|------:|-------------|
| `AGENTS.md` | 102 | AI agent guidelines — build/test commands, code style, architecture rules, key paths, common tasks |
| `ARCHITECTURE.md` | 196 | Design decisions, module dependency graph, component layout, key patterns (factory API, Moo roles, labels spec), container lifecycle, testing architecture |
| `CONTRIBUTING.md` | 169 | Contribution guide — setup, code style, module template, commit conventions, testing expectations |
| `IMPLEMENTATION_GUIDE.md` | 155 | Full implementation inventory, directory structure with all modules, architecture decisions, CI pipeline |
| `PROJECT_SUMMARY.md` | 165 | Feature status tables, file structure, implementation statistics, Go ↔ Perl API comparison |
| `QUICKSTART.md` | 282 | 5-minute getting started — installation, basic usage, all 4 modules, wait strategies, Test::More integration, troubleshooting |
| `CODE_OF_CONDUCT.md` | 129 | Contributor Covenant Code of Conduct v2.1 |

### Modified files (2)

| File | Description |
|------|-------------|
| `README.md` | Added CI/language/Docker/PR badges, fixed Perl version to 5.40+, removed WWW::Docker as external requirement (vendored), simplified installation to `Module::Build` |
| `CLAUDE.md` | Added `Labels.pm`, vendored `WWW::Docker` entries, `t/06-basic.t` through `t/12-volumes.t` test references, fixed Perl version to 5.40+ |

## Key documentation highlights

- **Architecture diagram** showing the strict `Testcontainers → WWW::Docker → Docker Engine` dependency direction
- **Factory function pattern** documented: `run()` entry point, `postgres_container()` / `redis_container()` module factories
- **Wait strategy role pattern**: `Moo::Role` base with `check()` contract, composite via `Multi`
- **Labels specification**: `merge_custom_labels()` validation, `_internal_labels` bypass for framework modules
- **Go API comparison table** mapping Go idioms to their Perl equivalents
- **Agent task guides** for adding new modules and wait strategies

## Stats

- **1,198 lines** of new documentation across 7 files
- **0** Swift references remaining (verified with `grep -rni`)
- All **85 unit tests** continue to pass
