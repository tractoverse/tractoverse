# Tractoverse — recorded decisions & running task list

This file holds **task-specific decisions** and the **running to-do list** for
tractoverse. It is git-versioned but excluded from the R build via
`.Rbuildignore`. Durable, cross-task project facts live in
[AGENTS.md](AGENTS.md) (which is prepended to every prompt and should stay lean).

## Running task list

Meta-package build-out (in progress). Status: `[ ]` = open, `[x]` = done,
`[~]` = in progress.

- [x] Clean `data-raw/` to a minimal set regenerating the whole logo family.
- [x] Rename `data-raw/` scripts to representative, dash-prefixed filenames
      (function/object names stay snake_case).
- [x] Split task-specific decisions/todo out of AGENTS.md into this file
      (git-versioned, Rbuildignore'd). **(this file)**
- [x] Replace the Python `screenshot.py` with an R script using webshot2
      (now `screenshot.R`, driven by chromote, the webshot2 browser lib).
- [~] Rename `{mascot}` to `{toad}` (Tractography Open Atlases Data).
      Meta-package + logo done; mascot repo local package rename + disk
      folder mascot/ -> toad/ done (committed 841efdb); **GitHub repo
      rename tractoverse/mascot -> tractoverse/toad still pending** (after it,
      .git/config origin and the release-download URLs already point to toad and
      will follow the redirect).
- [x] Install core packages preferably from CRAN if available, else main branch
      of repo -> add `install_core_packages()` (committed b41c15d). Note: bot's
      default branch is `master` (only family member not on `main`), so a
      `branch="main"` default fails for bot; install via `ref="master"`.
- [x] Confirm MIT licensing is appropriate for the pieces involved. MIT is
      appropriate (see *MIT licensing decision* below). tractoverse ships only
      in-house artwork (logos/theme/palette from the user's own useR! 2026
      talk) plus Font Awesome Free icon glyphs embedded in the logos (CC BY 4.0
      with attribution recorded in inst/brand/NOTICE). No third-party
      JS/CSS/fonts are bundled: three.js stays in rtists (MIT, not
      redistributed here), and Inter/JetBrains Mono are loaded at runtime from
      Google Fonts (SIL OFL 1.1), not vendored.
- [x] Roxygenize/document (bot + master installable), add README +
      `_pkgdown.yml` + brand. `.onAttach()` hook attaches the 6 core packages
      (tidyverse-style). R CMD check: 0 WARNING, 2 deliberate NOTEs (Imports
      unused for meta-package; .onAttach changes search path). pkgdown site
      builds cleanly with the dark brand (see *pkgdown dark theme* note below).
- [x] Update package roles across AGENTS.md / other files to the agreed role text.

**Item 7 — 6-package docs/brand + protection campaign** (one package at a time,
pausing before each `master`→`main` rename for approval):
- [x] Fix CI macOS link error (drop `-Wl,-all_load` on static VTK link) — rvtk
      PR #6 (`fix/macos-all-load`, base `main`).
- [x] Fix CI `bot::optimal_transport` missing-export WARNING — bot PR #1
      (`placeholder/optimal-transport`, base `master`).
- [x] Add mermaid dependency diagram to tractoverse README.qmd + build_readme
      (committed 0824643, pushed to `step6-docs-brand`).
- [x] Decide branch protection: **per-repo, as in toad** (org rulesets blocked
      on free plan) — see *Branch protection* decision below.
- [~] tractoverse: push `cb7c4aa..0824643` to origin/step6-docs-brand (PR #1) —
      **middle commits pushed; final commit pushed; verify PR page**.
- [x] fiber: pkgdown dark brand (committed 5599b11 on
      `fix/bundle-set-methods-and-attributes`); **logo corrected** to authored
      `inst/brand/logos/fiber.png` + favicons regenerated + dropped obsolete
      `data-raw/logo-fiber.R` (committed f3da830). **Renamed `master`→`main`**
      (default branch now `main`; remote `master` deleted; local `main` tracks
      `origin/main`; CI triggers already list `main`) and applied the **toad-model
      protection** to `main` — fiber is protected per toad model (see *Branch
      protection*).
- [x] master (already on `main`): pkgdown dark brand + README (committed
      49d5b10); **logo corrected** to authored `inst/brand/logos/master.png` +
      favicons regenerated (committed 10d1ca2). **Protection applied to `main`**
      matching master's CI (pkgdown.yaml only, no R-CMD-check/test-coverage):
      1 approving review + required `pkgdown` status check (strict), force-push
      block, enforce-admins off — NOT the full toad 6-check model, since master
      does not run those checks.
- [ ] rtists: use_logo (**authored `inst/brand/logos/rtists.png`**), README.qmd +
      build_readme, pkgdown brand (`#a980fc`) — then **pause
      before `master`→`main` rename + protection**.
- [ ] riot: use_logo (**authored `inst/brand/logos/riot.png`**; currently uses a
      non-authored logo), README.qmd + build_readme, pkgdown brand (`#3ec4b2`)
      — then **pause before `master`→`main` rename + protection**.
- [ ] toad (already on `main`): use_logo (**authored
      `inst/brand/logos/toad.png`**; currently uses a non-authored logo),
      README.qmd + build_readme, pkgdown brand (`#ffcf1b`).
- [ ] bot: use_logo (**authored `inst/brand/logos/bot.png`**; no logo yet),
      README.qmd + build_readme, pkgdown brand (`#3fb950`; also needs
      use_pkgdown_github_pages + DESCRIPTION license cleanup) — then **pause
      before `master`→`main` rename + protection**.
- [ ] bot: use_logo, README.qmd + build_readme, pkgdown brand — then **pause
      before `master`→`main` rename + protection**.
- [ ] After rvtk #6 + bot #1 merge, re-run tractoverse CI to confirm green.

## Decisions log

### MIT licensing decision (Step 5, closed)

The meta-package is `MIT + file LICENSE` (Copyright 2026 Aymeric Stamm). This is
appropriate: the package redistributes ONLY in-house artwork (logos, theme SCSS,
palette, all derived from the user's own useR! 2026 talk) plus Font Awesome Free
icon glyphs rasterized into the logos, which is permitted under CC BY 4.0 with
attribution (recorded in `inst/brand/NOTICE`, which also covers the three.js
render-scene provenance even though three.js is NOT redistributed here). No
third-party JS/CSS/fonts are bundled:
- **three.js** stays in rtists (MIT) — tractoverse ships only the PNG renders.
- **Inter / JetBrains Mono** are declared `source: google` and loaded at runtime
  from Google Fonts (both SIL OFL 1.1) — not vendored, so no redistribution
  concern. Switching to self-hosted copies later WOULD require OFL notice +
  rename compliance, so prefer keeping Google-hosted if possible.
- **pkgdown favicons** are rasterized from the in-house tractoverse logo by the
  RealFaviconGenerator service (attribution metadata embedded in
  `pkgdown/favicon/favicon.svg`); the output is the user's own artwork, so no
  third-party copyrightable content is introduced.
Re-check via `inst/brand/NOTICE` before shipping any new bundled asset (per the
global licensing rule).

### Branch protection (Item 7, decided)

- **Org-level repository rulesets require a paid GitHub Team plan** (free orgs
  only get classic per-repo branch protection). Org **Settings → Repository →
  Rulesets** (https://github.com/organizations/<org>/settings/repository/rules)
  is the correct location, but the UI blocks enforcement without the upgrade.
- **Decision: keep free per-repo protection, modeled on toad.** Apply the same
  policy to each remaining package as it completes its `master`→`main` rename
  (rtists, riot, bot). `tractoverse`, `master`, `toad`, `fiber` are already on
  `main`; toad and fiber are protected per the toad model, and master is
  protected matching its pkgdown-only CI (see the master item above for the
  deviation).
- **The toad model** (the template for every repo's default branch):
  - Required PR reviews: **1** approving review (dismiss-stale off, codeowner
    off, last-push-approval off).
  - Required status checks: `macos-latest (release)`, `windows-latest (release)`,
    `ubuntu-latest (devel)`, `ubuntu-latest (release)`,
    `ubuntu-latest (oldrel-1)`, `test-coverage` — with strict = true
    (require branches up to date).
  - Block force-pushes (non-fast-forward): on.
  - Enforce for admins: **off** (matches toad — admin escape hatch).
- **Revisit org-level rulesets if the org ever upgrades to Team** — a draft
  spec lives in the scratch copy of `tractoverse-ruleset.md` (not git-versioned).
- `mascot` → `toad` GitHub rename is still pending (see running task list); the
  `midi` repo is legacy (merged into `master`) and intentionally left unprotected
  unless it needs to be archived.

---

### pkgdown dark theme (pkgdown 2.2.1 architecture)

The dark brand for the pkgdown site is wired via `template.bootstrap: 5` +
`template.bootswatch: darkly` + `template.theme: arrow-dark` +
`pkgdown/extra.scss` in `_pkgdown.yml`.

**There is no separate `pkgdown.css` file in pkgdown 2.2.1 for Bootstrap 5.**
Custom Sass is compiled by bslib directly into
`docs/deps/bootstrap-5.3.8/bootstrap.min.css` (via `build_bslib()`). A "missing
pkgdown.css" therefore does NOT mean the theme failed — the compiled
`bootstrap.min.css` should contain `--bslib-preset-name: darkly`, the
`extra.scss` brand tokens (e.g. `#0d1117` bg, `#58a6ff` accent, `#161b22`
surface), and the `pre code span.*` arrow-dark highlighting rules. Verify by
grepping those markers in the compiled file.

`pkgdown/` being in `.Rbuildignore` is irrelevant: `bs_theme_rules()` reads
`pkg/extra.scss` via `pkg$src_path` from the source directory, not the
temp-installed library. `template.theme` (default `arrow-light`) controls the
syntax-highlight palette independent of the lightswitch toggle; set
`arrow-dark` for a dark shell.

`build_site()` reports an accessibility check for README images missing
alt-text — give the color swatches descriptive alt text (e.g. "fiber signature
color #59aaea").

---

### Filenames

- **Dashes, not underscores** for file/script/resource names (esp. in
  `data-raw/`); R function/object/variable names and `.R` files outside
  `data-raw/` stay snake_case. (Recorded here and in AGENTS.md for future tasks.)

---

## Logo family (approved art direction, light-bg redesign)

Task-specific logo build decisions — kept here, out of AGENTS.md, because they
are specific to the logo-generation task and its regeneration runs.

The 6 package logos share a common shell:

- **Elements (only 3):** the **package name** (much larger), a **glyph** (a
  transparent **symmetric pyramidal tract** that fans left/right and fills the
  hexagon), and a **FontAwesome icon** emblem.
- **Background:** white / light. **Border:** black hexagon `#111111`,
  **pointy-top**, `R = 300`, canvas `W = 520` (round(sqrt(3)*R)),
  `H = 600` (round(2*R)).
- **Cone glyph:** the **exact-symmetric butterfly** built from a single
  hemisphere via `mirror_x_side="L"` in `build-scene.R`: `bL = cl[iL]` (30
  crown-sampled CST_L streamlines) as the left wing, right wing =
  `mirror_x(bL)` reflected across X = 0. This gives a perfectly symmetric cone
  (the two anatomy halves differ and would otherwise render right-hemisphere-
  heavier). Rendered at `splay 0` (raw, uncanted anatomy), tinted with the
  package color.
- **Per-package color everywhere:** tract, name, and icon all use the package
  palette color.

### Emblem = FontAwesome icons

Use FontAwesome icons, per package (`fontawesome` v0.5.3; `rsvg` renders SVG →
600×600 RGBA PNG with the shape in the alpha channel, which is chroma-keyed
into an alpha mask and tinted with the package color):

| Package | FontAwesome icon |
|---------|------------------|
| riot   | `feather-pointed` |
| rtists | `palette` |
| bot    | `magnifying-glass-chart` |
| fiber  | `bezier-curve` |
| toad   | `book-atlas` |
| master | `blender` |

### Shared layout requirements

- **Horizontal centering of the tract is the common layout issue across all 6.**
  It is a *render/scene* rotational asymmetry (the two anatomy halves differ:
  left bundle 5577 streamlines, right 2397; right half comes out consistently
  denser ⇒ right-hemisphere-heavier in every render, e.g. LR occupancy ratio
  ~0.94–0.99). Bbox-centering alone leaves the glyph subtly off the hex's
  vertical axis. Guarantee the tract's **content centre-of-mass lands on the
  hex center (col W/2 = 260)** rather than centering only the bounding box.
- Vertical placement fills the pointy-top hexagon symmetrically (apexes near
  top/bottom).

### Render parameters (agreed)

- **30 streamlines per side** (`nL = 30`, `nR = 30`).
- **Downsampling is done in the densest areas on the top area** (the crown /
  uppermost part of each bundle), so the sparse fan stays even near the apex.
- **Re-implemented and PERSISTED** in `data-raw/crown-sample.R` (canonical):
  `crown_sample(bundle, n=30, z_frac=0.25)` selects the crown (points at
  Z >= zmin + 0.25*(zmax-zmin), the uppermost slab), orders streamlines by
  their crown fan position (mean X of their crown points), then takes
  DETERMINISTIC even spacing (~ns/n rank step) for full-width, even-near-apex
  coverage. `make_crown_strat(path, n)` writes the `list(iL=, iR=)` index rds.
  The selection is validated by measurable pixel properties + user review
  (measured span: left crown-X ~[-48.8,-11.1], peak-Z ~[50.4,77.1]).

### Build pipeline (canonical: `data-raw/`, driver = `logo-family.R`)

The minimal `data-raw/` set regenerates the full 6-package light-bg family from
scratch. Single entry point: `Rscript data-raw/logo-family.R` (from repo root;
`--pkg fiber` smoke-tests one). Runs the exact-symmetric butterfly:

1. `crown-sample.R` — `crown_sample()`, `make_crown_strat()`.
2. `build-scene.R` — `PALETTE`, `make_scene()` (`mirror_x_side="L"`
   single-hemisphere exact-symmetric butterfly: `bL = cl[iL]`, `bR =
   mirror_x(bL)` across X=0; `cam_view=c(0,1,0)`, `cam_up=c(0,0,1)`,
   `cam_dist=1.9`), `mirror_x()`, `patch_camera()`, `patch_axes()`,
   `mirror_depth()`, `splay_bundle()`.
3. `compose-core.R` (low-level raster helpers) + `compose-logo.R`
   (`compose_logo()`, `fa_tile()`), which chroma-keys the white tract from the
   black-bg screenshot and **centers the content centre-of-mass on col 260**.
4. `screenshot.R` — chromote (the webshot2 browser lib) + a Chrome-for-Testing
   build screenshots the served widget (`--use-gl=swiftshader`, 1200x1200
   viewport, DPR=2).
5. Widget is served in-process by **`httpuv::runStaticServer`** (no Python
   subprocess; `srv$getPort()` → `screenshot.R`; `on.exit(httpuv::stopServer)`).

**cl/cr sourcing**: `logo-family.R` loads CST_L/CST_R from the gitignored
`data-raw/.render/` cache (seeded: `HCP1065_CST_L.rds` 3.08MB / `CST_R.rds`
1.26MB). On a cold cache it pulls `toad::HCP1065_CST_L/R()` (GitHub-releases
download, no caching in toad) and caches ~4.3MB. Verified identical to `cl`
(5577) / `cr` (2397). `make_crown_strat` regenerates `.render/crown_strat_30.rds`.

Outputs → `inst/brand/logos/{pkg}.png` + `tractoverse.png` (1290x1680 white,
2x3 grid on a 600x520 canvas at 1-based origins: fiber(30,30), master(30,580),
rtists(30,1130), riot(660,30), toad(660,580), bot(660,1130)).

**Determinism**: screenshot, compose, and crown-strat are all deterministic (two
screenshots of one scene are byte-identical; crown indices reproduce exactly
from the cached bundles). Regenerated logos should be structurally identical to
the shipped ones (tract axis col 260, same bbox, glyph fills the hexagon);
verify visually via the Positron Plots pane before overwriting
`inst/brand/logos/` (back up first).
