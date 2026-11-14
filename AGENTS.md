# Tractoverse — project memory

Working notes for building the tractoverse R package family and its shared
brand. This file holds **durable, cross-task project facts** only — things that
are useful to a prompt regardless of the specific task. Task-specific decisions
and the running to-do list live in
[DECISIONS.md](DECISIONS.md) (git-versioned, `Rbuildignore`'d).

The brand artifacts (final logos + `_brand.yml` + theme) live in `inst/brand/`
as the single source of truth; each package consumes them.

## Package family (roles)

tractoverse is a curated family of R packages for diffusion MRI tractography,
modeled on the tidyverse. The roles, as decided:

| Package | Role |
|---------|------|
| fiber  | Handles **data structures** to host tractography data (S7: `streamline`, `bundle`, `bundle_set`) |
| master | Handles **simulation** of streamlines/bundles/bundle sets, with possibly microstructural parameters superimposed (merges the current `midi` package, which handles simulation of said microstructure) |
| rtists | Handles **visualization** (interactive 3D) |
| riot   | Handles **data I/O** (through `rvtk`) |
| toad   | **Tractography Open Atlases Data** — companion dataset package (new name for the old `mascot` package, renamed because "mascot" is retained for Matrix Science's mascot software, https://www.matrixscience.com/mascot_support_v2_6.html) |
| bot    | **Bundle Optimal Transport** — implements statistical methods for tractography data |

## Signature palette (single source of truth, matches `inst/brand/_brand.yml`)

| Package | Signature color |
|---------|-----------------|
| fiber  | `#59aaea` |
| master | `#ff9441` |
| rtists | `#a980fc` |
| riot   | `#3ec4b2` |
| toad   | `#ffcf1b` |
| bot    | `#3fb950` |

Each package's logo name, tract glyph, and FontAwesome icon all use the
package's signature color. Per-package background tints and FA icons are
recorded in the logo build notes in DECISIONS.md.

## Working conventions

- **R is the live workspace.** The running R session is the workspace; the
  assistant **cannot see rendered images**, so anything visual is validated by
  measurable pixel properties plus user feedback on the Positron Plots pane.
- **License: MIT** (meta-package, `MIT + file LICENSE`). Before shipping anything
  that vendors/bundles third-party code (from `astamm.github.io` / the rtists
  package, or any other project), verify every vendored file's license permits
  the exact use (embedding/minification/re-export) and record provenance in
  `inst/brand/NOTICE`. See also the global licensing rule in user memory.
- **Do not** use any external reference image (license may be incompatible).
- **Do not** edit rtists source (used as a library, not vendored).
- RNG seeds must be a random integer in 1–10,000 (never 123/42/etc.).
- Prefer `file.exists()` over `dir.exists()` for existence checks.
- **Filename convention: dashes, not underscores** in `data-raw/` scripts (e.g.
  `compose-logo.R`, `crown-sample.R`, `build-scene.R`, `logo-family.R`,
  `screenshot.R`). R **function/object names stay snake_case** (e.g.
  `compose_logo()`, `crown_sample()`), as do variables, fields, and `.R` files
  outside `data-raw/` (e.g. package `R/` files). Apply dashes broadly to future
  multi-word script/resource filenames unless a convention (e.g. an existing
  package layout) mandates underscores.

## Logo pipeline

The full 6-package logo family is regenerated from scratch by a single driver:
`Rscript data-raw/logo-family.R` (from repo root; `--pkg fiber` smoke-tests one).
The canonical pipeline, approved art direction, and build details are recorded
in DECISIONS.md under *Logo family*.
