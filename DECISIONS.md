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
- [ ] Rename `{mascot}` to `{toad}` (Tractography Open Atlases Data).
      Meta-package + logo done; mascot repo local package rename + disk
      folder mascot/ -> toad/ done (committed 841efdb); **GitHub repo
      rename tractoverse/mascot -> tractoverse/toad still pending** (after it,
      .git/config origin and the release-download URLs already point to toad and
      will follow the redirect).
- [ ] Install core packages preferably from CRAN if available, else main branch
      of repo -> add `install_core_packages()` (tractoverse should NOT list core
      packages in `Imports:`; export a function that (i) lets the user select
      which package(s) to install, default all 6, and (ii) prefers the CRAN
      version if available, else the main branch).
- [ ] Confirm MIT licensing is appropriate for the pieces involved.
- [ ] Roxygenize/document (now that bot + master are installable), add README +
      `_pkgdown.yml` + brand.
- [ ] Update package roles across AGENTS.md / other files to the agreed role text.

## Decisions log

### Filenames

- **Dashes, not underscores** for file/script/resource names (esp. in
  `data-raw/`); R function/object/variable names and `.R` files outside
  `data-raw/` stay snake_case. (Recorded here and in AGENTS.md for future tasks.)

---

## Logo family (approved art direction, light-bg redesign)

Task-specific logo build decisions — kept here, out of AGENTS.md, because they
are specific to the logo-generation task and its regeneration runs.

The 6 package logos are rebuilt on a common shell:

- **Elements (only 3):** the **package name** (much larger), a **glyph** (a
  transparent **symmetric pyramidal tract** that fans left/right and fills the
  hexagon), and a **FontAwesome icon** emblem.
- **Background:** white / light. **Border:** black hexagon `#111111`,
  **pointy-top**, `R = 300`, canvas `W = 520` (round(sqrt(3)*R)),
  `H = 600` (round(2*R)).
- **Cone glyph (APPROVED v24):** the **exact-symmetric butterfly** built from a
  single hemisphere via `mirror_x_side="L"` in `build-scene.R`:
  `bL = cl[iL]` (30 crown-sampled CST_L streamlines) as the left wing, right
  wing = `mirror_x(bL)` reflected across X = 0. This replaces the old merge of
  the two unequal anatomy halves (which was right-hemisphere-heavier). Rendered
  at `splay 0` (raw, uncanted anatomy), tinted with the package color.
- **Per-package color everywhere:** tract, name, and icon all use the package
  palette color.

### Emblem = FontAwesome icons (hand-drawn polygon emblem REJECTED)

Do NOT hand-draw/draw the emblem with polygons (the earlier class-emblem
polygon was rejected as "super ugly; bundles are super fuzzy"). Use FontAwesome
icons instead, per package (`fontawesome` v0.5.3; `rsvg` renders SVG → 600×600
RGBA PNG with the shape in the alpha channel, which is chroma-keyed into an
alpha mask and tinted with the package color):

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
  top/bottom), as in `logo-fiber-v15.png` / `logo-fiber-v18-test.png`.

### Render parameters (agreed) — RE-BUILD renders with these

- **30 streamlines per side** (`nL = 30`, `nR = 30`), not the old 120/side.
- **Downsampling is done in the densest areas on the top area** (the crown /
  uppermost part of each bundle), so the sparse fan stays even near the apex.
  This replaces the old uniform `sample.int(5577, 120)` / `sample.int(2397, 120)`.
- **Re-implemented and PERSISTED** in `data-raw/crown-sample.R` (canonical;
  supersedes the old scratch `/tmp/pa-501/logos3/crown-sample.R`):
  `crown_sample(bundle, n=30, z_frac=0.25)` selects the crown (points at
  Z >= zmin + 0.25*(zmax-zmin), the uppermost slab), orders streamlines by
  their crown fan position (mean X of their crown points), then takes
  DETERMINISTIC even spacing (~ns/n rank step) for full-width, even-near-apex
  coverage. `make_crown_strat(path, n)` writes the `list(iL=, iR=)` index rds.
  This replaced the earlier interactive algorithm (lost; only its
  `crown_strat_*.rds` outputs survived). The re-implementation matches the
  original's measured span (left crown-X ~[-48.8,-11.1], peak-Z ~[50.4,77.1]).
  The old `crown_strat_*.rds` indices were NOT reproducible (interactive
  density thinning) - visual parity is the goal, validated by pixels + review.

### Build pipeline (canonical: `data-raw/`, driver = `logo-family.R`)

The minimal `data-raw/` set regenerates the full 6-package light-bg family from
scratch. Single entry point: `Rscript data-raw/logo-family.R` (from repo root;
`--pkg fiber` smoke-tests one). Runs the v24-approved exact-symmetric butterfly:

1. `crown-sample.R` — `crown_sample()`, `make_crown_strat()`.
2. `build-scene.R` — `PALETTE`, `make_scene()` (v24 `mirror_x_side="L"`
   single-hemisphere exact-symmetric butterfly: `bL = cl[iL]`, `bR =
   mirror_x(bL)` across X=0; `cam_view=c(0,1,0)`, `cam_up=c(0,0,1)`,
   `cam_dist=1.9`), `mirror_x()`, `patch_camera()`, `patch_axes()`,
   `mirror_depth()`, `splay_bundle()`.
3. `compose-core.R` (low-level raster helpers) + `compose-logo.R`
   (`compose_logo()`, `fa_tile()`), which chroma-keys the white tract from the
   black-bg screenshot and **centers the content centre-of-mass on col 260**.
4. `screenshot.R` — chromote (the webshot2 browser lib) + a Chrome-for-Testing
   build screenshots the served widget (`--use-gl=swiftshader`, 1200x1200
   viewport, DPR=2), replacing the old Playwright `screenshot.py`.
5. Widget is served in-process by **`httpuv::runStaticServer`** (no Python
   subprocess; `srv$getPort()` → `screenshot.R`; `on.exit(httpuv::stopServer)`).
   Replaced the old python3 `http.server` + shell port-finder, whose embedded
   single quotes broke through `sh -c`.

**cl/cr sourcing**: `logo-family.R` loads CST_L/CST_R from the gitignored
`data-raw/.render/` cache (seeded: `HCP1065_CST_L.rds` 3.08MB / `CST_R.rds`
1.26MB). On a cold cache it pulls `toad::HCP1065_CST_L/R()` (GitHub-releases
download, no caching in toad) and caches ~4.3MB. Verified identical to `cl`
(5577) / `cr` (2397). `make_crown_strat` regenerates `.render/crown_strat_30.rds`.

Outputs → `inst/brand/logos/{pkg}.png` + `tractoverse.png` (1290x1680 white,
2x3 grid on a 600x520 canvas at 1-based origins: fiber(30,30), master(30,580),
rtists(30,1130), riot(660,30), toad(660,580), bot(660,1130)).

**Determinism / v24 note**: screenshot, compose, and crown-strat are all
deterministic (two screenshots of one scene are byte-identical; crown indices
reproduce exactly from the cached bundles). Regenerated logos are structurally
identical to the approved v24 (tract axis col 260, same bbox, glyph fills the
hexagon) but NOT byte-identical: the current crown_sample is a re-implementation
aimed at **visual parity**, and v24's original streamline indices were
interactive/non-reproducible and deleted. Confirm with the user whether visual
parity is acceptable before overwriting `inst/brand/logos/` (back up first).
