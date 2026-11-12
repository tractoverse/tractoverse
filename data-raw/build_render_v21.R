## build_render_v21.R - rebuild the tract render with:
##   * 30/side crown-stratified sampling (crown_strat_30_new.rds)
##   * CST_R depth mirror (Y -> -Y) so the right half mirrors CST_L (symmetric cone)
## Screenshot externally via shothi.py, then compose with compose_logo6.
##
## Usage: source build_scene.R then source this; call build_v21("serve/fiber-v21").

build_v21 <- function(
  dir = "serve/fiber-v21",
  idx_path = "/tmp/pa-501/logos3/crown_strat_30_new.rds",
  color = "#ffffff",
  linewidth = 1.6,
  opacity = 0.9,
  width = 1200,
  height = 1000,
  bg = "#000000"
) {
  idx <- readRDS(idx_path)
  bL <- cl[idx$iL]
  bR <- cr[idx$iR]
  bR <- mirror_depth(bR) # CST_R depth mirror
  sls <- c(unname(bL@streamlines), unname(bR@streamlines))
  merged <- fiber::bundle(streamlines = sls)
  w <- rtists::plot3d(
    merged,
    color = color,
    backend = "threejs",
    linewidth = linewidth,
    radius = NULL,
    opacity = opacity,
    bg = bg,
    tooltip = FALSE
  )
  sp <- w$sizingPolicy
  sp$defaultWidth <- width
  sp$defaultHeight <- height
  sp$padding <- 0
  sp$browser$defaultWidth <- width
  sp$browser$defaultHeight <- height
  sp$browser$padding <- 0
  sp$browser$fill <- FALSE
  w$sizingPolicy <- sp
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  htmlwidgets::saveWidget(
    w,
    file.path(dir, "index.html"),
    selfcontained = FALSE,
    libdir = "index_files"
  )
  patch_camera(dir, view = c(0, 1, 0), up = c(0, 0, 1), dist = 1.9)
  invisible(w)
}
