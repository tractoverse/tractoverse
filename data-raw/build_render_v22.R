## build_render_v22.R - symmetric butterfly render.
##   * 30/side crown-stratified sampling (crown_strat_30_new.rds)
##   * CST_L is the left wing; the RIGHT wing is the reflection of CST_L across
##     the vertical (X) axis, so the butterfly is EXACTLY left/right symmetric.
##     (CST_R anatomy is discarded; exact symmetry is the priority.)
## Screenshot externally via shothi.py, then compose with compose_logo6.

build_v22 <- function(
  dir = "serve/fiber-v22",
  idx_path = "/tmp/pa-501/logos3/crown_strat_30_new.rds",
  color = "#ffffff",
  linewidth = 1.6,
  opacity = 0.9,
  width = 1200,
  height = 1000,
  bg = "#000000"
) {
  idx <- readRDS(idx_path)
  bL <- cl[idx$iL] # left wing = CST_L crown sample
  bR <- mirror_x(bL, axis = 0) # right wing = reflection of left across X=0
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
  patch_axes(dir) # remove the three.js AxesHelper gizmo at the data origin
  invisible(w)
}
