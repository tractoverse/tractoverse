# =============================================================================
# logo-family.R -- v24 driver: regenerate the whole 6-package logo family.
# =============================================================================
# Regenerates the light-bg logo family (fiber, master, rtists, riot, toad,
# bot) plus the 2x3 montage from scratch. Single entry point; supersedes the
# obsolete ggplot-era dark-shell generator of the same name.
#
# Pipeline (per package):
#   1. crown-stratified 30/side sampling of the CST bundles (exact-symmetric
#      butterfly: one hemisphere crown-sampled, then the opposite wing is its
#      reflection across X=0 via `mirror_x_side="L"`).
#   2. make_scene() -> served threejs widget (patched camera/axes) in a
#      gitignored work dir (`data-raw/.render/`).
#   3. screenshot the widget with screenshot.R (chromote / webshot2, R).
#   4. compose_logo() -> light-bg hex + FontAwesome icon + name -> PNG into
#      `inst/brand/logos/`.
#   5. assemble the 2x3 montage -> `tractoverse.png`.
#
# Sourcing cl/cr: from the `.render/` cache (gitignored). On a cold cache the
# bundles are pulled from `toad::HCP1065_CST_L/R()` (a GitHub-releases
# download) and cached so later runs are fast and offline. cl = 5577 / cr =
# 2397 streamlines are the ground-truth CST source for the glyph.
#
# Requires (R): fiber, rtists, htmlwidgets, png, fontawesome, rsvg; plus
#   chromote (a webshot2 dependency) + a Chrome-for-Testing build for the
#   headless screenshot. Run with `--pkg fiber` to test a single package first;
#   run with no args to build all 6 + montage.
# =============================================================================

suppressMessages({
  library(fiber)
  library(rtists)
  library(htmlwidgets)
  library(png)
  library(httpuv)
})
suppressMessages(library(fontawesome))
suppressMessages(library(rsvg))

# ---- command line: allow a single-package smoke test ------------------------
args <- commandArgs(trailingOnly = TRUE)
only_pkg <- NULL
if ("--pkg" %in% args) only_pkg <- args[which(args == "--pkg") + 1L]

# ---- locations ----------------------------------------------------------------
# Anchor to the package repo root (parent of data-raw) regardless of how the
# script is invoked. The script always lives in data-raw/, so the package root
# is one level up from the script's directory. All of these resolve correctly:
#   * Rscript data-raw/logo-family.R (repo root)        -> --file -> step up
#   * Rscript --file=/abs/.../data-raw/logo-family.R    -> --file -> step up
#   * sourced interactively from repo root (getwd)      -> step up if in data-raw
resolve_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) {
    script <- normalizePath(sub("^--file=", "", file_arg[1]), mustWork = TRUE)
    root <- dirname(dirname(script))
  } else {
    root <- normalizePath(getwd(), mustWork = TRUE)
  }
  # be defensive: if someone points us at data-raw (or a plain repo root),
  # normalize so ROOT is always the parent of data-raw.
  if (basename(root) == "data-raw") root <- dirname(root)
  root
}
ROOT <- resolve_root()
DATA_RAW <- file.path(ROOT, "data-raw")
if (!file.exists(file.path(DATA_RAW, "crown-sample.R"))) {
  stop("could not locate data-raw/ (crown-sample.R missing); run from the repo root")
}
WORK     <- file.path(DATA_RAW, ".render")          # gitignored intermediates
SERVE    <- file.path(WORK, "serve")                # served widget dir (httpuv root)
LOGO_OUT <- file.path(ROOT, "inst", "brand", "logos")
dir.create(WORK,    showWarnings = FALSE, recursive = TRUE)
dir.create(SERVE,   showWarnings = FALSE, recursive = TRUE)
dir.create(LOGO_OUT, showWarnings = FALSE, recursive = TRUE)

# ---- source the shared helpers -------------------------------------------------
source(file.path(DATA_RAW, "crown-sample.R"))       # crown_sample(), make_crown_strat()
source(file.path(DATA_RAW, "build-scene.R"))        # make_scene(), PALETTE, mirror_*, patches
source(file.path(DATA_RAW, "compose-core.R"))       # low-level raster helpers
source(file.path(DATA_RAW, "compose-logo.R"))       # compose_logo(), fa_tile()

# ---- per-package brand config (single source of truth = DECISIONS.md + ground truth)
BG_EXACT <- c(   # light backgrounds = white + ~87% lightened signature color
  fiber  = "#E9F4FC", master = "#FFF1E6", rtists = "#F4EEFF",
  riot   = "#E6F7F5", toad   = "#FFF9E1", bot    = "#E6F6E8"
)
ICONS <- c(      # FontAwesome emblem per package
  fiber  = "bezier-curve",            master = "blender",
  rtists = "palette",                 riot   = "feather-pointed",
  toad   = "book-atlas",              bot    = "magnifying-glass-chart"
)
PKGS <- names(ICONS)
if (!is.null(only_pkg)) {
  if (!only_pkg %in% PKGS) stop("unknown package: ", only_pkg)
  PKGS <- only_pkg
}

# ---- 1. load cl (CST_L) + cr (CST_R) from .render/ cache, else from toad ----
cl_path <- file.path(WORK, "HCP1065_CST_L.rds")
cr_path <- file.path(WORK, "HCP1065_CST_R.rds")
if (!file.exists(cl_path) || !file.exists(cr_path)) {
  message("Cold cache: pulling CST bundles from toad (HCP1065 download)...")
  cl <- toad::HCP1065_CST_L()
  cr <- toad::HCP1065_CST_R()
  saveRDS(cl, cl_path)
  saveRDS(cr, cr_path)
} else {
  cl <- readRDS(cl_path)
  cr <- readRDS(cr_path)
}
stopifnot(length(cl@streamlines) == 5577L,
          length(cr@streamlines) == 2397L)

# ---- 2. crown-stratified indices (30/side), deterministic --------------------
idx <- make_crown_strat(file.path(WORK, "crown_strat_30.rds"), n = 30, z_frac = 0.25)

# ---- helpers: serve the widget dir via httpuv (no subprocess needed) -----------
# httpuv::runStaticServer serves SERVE in the background and reports its own free
# port; the returned server object is stopped via on.exit. This replaces the old
# python3 http.server + shell port-finding (which broke on embedded quotes).

# ---- 3-5. render + screenshot + compose each package ---------------------------
srv <- httpuv::runStaticServer(dir = SERVE, host = "127.0.0.1",
                               port = httpuv::randomPort(), background = TRUE,
                               browse = FALSE)
srv_port <- srv$getPort()
message(sprintf("httpuv static server on port %d (root %s)", srv_port, SERVE))
on.exit(try(httpuv::stopServer(srv), silent = TRUE), add = TRUE)

for (pkg in PKGS) {
  scene_dir <- file.path(SERVE, pkg)
  message(sprintf("\n== %s: building scene", pkg))
  make_scene(
    pkg = pkg,
    dir = scene_dir,
    mode = "line2",
    linewidth = 1.6,
    opacity = 0.9,
    bg  = "#000000",
    color = "white",
    width  = 1200,
    height = 1000,
    splay = 0,
    crown_idx = file.path(WORK, "crown_strat_30.rds"),
    mirror_x_side = "L",
    cam_view = c(0, 1, 0),
    cam_up   = c(0, 0, 1),
    cam_dist = 1.9,
    patch = TRUE
  )

  render_png <- file.path(WORK, sprintf("%s-render.png", pkg))
  message(sprintf("== %s: screenshot", pkg))
  code <- system2(file.path(R.home("bin"), "Rscript"),
                  c(file.path(DATA_RAW, "screenshot.R"), pkg, render_png,
                    as.character(srv_port)),
                  wait = TRUE)
  if (!identical(code, 0L)) {
    stop(sprintf("screenshot.R failed for %s (exit %d)", pkg, code))
  }

  out_png <- file.path(LOGO_OUT, sprintf("%s.png", pkg))
  message(sprintf("== %s: compose -> %s", pkg, out_png))
  compose_logo(
    render_path = render_png,
    pal      = PALETTE[[pkg]],
    name     = pkg,
    bg_color = BG_EXACT[[pkg]],
    icon     = ICONS[[pkg]],
    out_path = out_png
  )
}

# ---- montage: white 1290x1680, 2x3 grid at 1-based origins (oy, ox) ----------
if (length(PKGS) == 6L) {
  message("\n== assembling montage")
  origins <- data.frame(
    pkg = c("fiber", "master", "rtists", "riot", "toad", "bot"),
    oy  = c(30, 30, 30, 660, 660, 660),
    ox  = c(30, 580, 1130, 30, 580, 1130)
  )
  canvas <- array(1, c(1290, 1680, 4))
  for (i in seq_len(nrow(origins))) {
    o <- origins[i, ]
    im <- readPNG(file.path(LOGO_OUT, sprintf("%s.png", o$pkg))) # 600 x 520 x 4
    canvas[o$oy:(o$oy + 599), o$ox:(o$ox + 519), ] <- im[1:600, 1:520, ]
  }
  writePNG(canvas, file.path(LOGO_OUT, "tractoverse.png"))
}
message("logo-family.R done")
