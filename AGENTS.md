# Tractoverse — project memory

Working notes for building the tractoverse R package family and its shared
brand. The brand artifacts (final logos + `_brand.yml` + theme) live in this
repo as the single source of truth; each package (`fiber`, `master`, `rtists`,
`riot`, `mascot`, `bot`) consumes them.

## Package palette (single source of truth, matches `inst/brand/_brand.yml`)

| Package | Role | Signature color |
|---------|------|-----------------|
| fiber  | S7 data structures | `#59aaea` |
| master | bundle/microstructure simulation | `#ff9441` |
| rtists | interactive 3D visualization | `#a980fc` |
| riot   | input/output | `#3ec4b2` |
| mascot | curated reference datasets | `#ffcf1b` |
| bot    | bundle optimal transport | `#3fb950` |

## Logo family — approved art direction (light-bg redesign)

The 6 package logos are rebuilt on a common shell:

- **Elements (only 3):** the **package name** (much larger), a **glyph** (a
  transparent **symmetric pyramidal tract** that fans left/right and fills the
  hexagon), and a **FontAwesome icon** emblem.
- **Background:** white / light. **Border:** black hexagon, **pointy-top**,
  `R = 300`, canvas `W = 520` (round(sqrt(3)*R)), `H = 600` (round(2*R)).
- **Cone glyph:** the two-tract render at **`splay 0`** (raw, uncanted anatomy —
  butterfly cone), merged into one symmetric bundle, tinted with the package
  color.
- **Per-package color everywhere:** tract, name, and icon all use the package
  palette color.

Current preferred tract render/layout: `compose_vc` vertical-center placement of
`fiber-cone-w.png` (= the approved `logo-fiber-v18-test.png` layout).

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
| mascot | `book-atlas` |
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
- **Re-implemented and PERSISTED** in `/tmp/pa-501/logos3/crown_sample.R`:
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

### Build pipeline (scratch, currently `/tmp/pa-501/logos3/`)

- `build_scene.R`: `make_scene(pkg, mode, ..., splay=0, nL, nR)` builds a served
  rtists threejs widget of `cl` (left) + `cr` (right) merged into one bundle;
  `patch_camera(view=c(0,1,0), up=c(0,0,1), dist=1.2)` looks along +Y so X →
  screen-horizontal, Z → screen-vertical, crown-up.
- `compose_logo6.R`: light-bg compositor. Key point: horizontal placement
  centers the **content centre-of-mass** (shift `ox` by `-content_cm_x*sc`) so
  the tract axis lands on col 260. `fa_tile()` chroma-keys a FontAwesome icon
  and tints it.
- Renders → `out/*.png`; composed logos → `out/logo-fiber-v*.png`.

## Constraints / process

- The running R 4.6.1 session is the live workspace; the assistant **cannot see
  rendered images**, so correctness is validated by measurable pixel properties
  (blue-profile rows/cols, tract axis = col 260, LR occupancy ratio) plus user
  feedback on the Positron Plots pane.
- **Do not** use any external reference image (license may be incompatible).
- **Do not** edit rtists source. Before shipping anything that vendors/bundles
  third-party code (from `astamm.github.io` / the rtists package, or any other
  project), verify every vendored file's license permits the exact use
  (embedding/minification/re-export) and record provenance. See also the global
  licensing rule in user memory.
- RNG seeds must be a random integer in 1–10,000 (never 123/42/etc.).
