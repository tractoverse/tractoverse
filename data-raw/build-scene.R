## Logo scene generator: builds a served rtists widget dir for one package.
## Usage: source this in the R console (cl/cr live), then call make_scene(pkg, ...).

PALETTE <- c(
  fiber = "#59aaea",
  master = "#ff9441",
  rtists = "#a980fc",
  riot = "#3ec4b2",
  toad = "#ffcf1b",
  bot = "#3fb950"
)

# deterministic subsample indices for clean, even coverage
set.seed(2847)
.IDX_L <- sort(sample.int(5577, 120))
.IDX_R <- sort(sample.int(2397, 120))

#' Patch the vendored rtists-render.js camera so CST_L fans left, CST_R right.
#'
#' Default places the camera at a (1,1,1) diagonal. For a symmetric left/right
#' logo we look along +Y (so X -> screen-horizontal, Z -> screen-vertical,
#' crown-up). `view` is the unit camera world offset from scene center, `up` the
#' camera up vector, `dist` the offset multiple of scene radius.
patch_camera <- function(dir, view = c(0, 1, 0), up = c(0, 0, 1), dist = 1.2) {
  path <- file.path(dir, "index_files", "threejs-0.186.0", "rtists-render.js")
  js <- readLines(path, warn = FALSE)
  i <- grep("// camera looks at center from a fixed diagonal offset", js)
  if (length(i) == 0 || (i + 3L) > length(js)) {
    stop("camera patch target not found")
  }
  # original block spans lines i..i+3 (4 lines):
  #   i   : comment
  #   i+1 : camera.position.copy(center).add(
  #   i+2 :   new THREE.Vector3(...)...
  #   i+3 : );
  replacement <- c(
    "      // camera looks at center from a fixed diagonal offset (patched)",
    sprintf(
      "      camera.up.copy(new THREE.Vector3(%s, %s, %s));",
      up[1],
      up[2],
      up[3]
    ),
    "      camera.position.copy(center).add(",
    sprintf(
      "        new THREE.Vector3(%s, %s, %s).normalize().multiplyScalar(radius * %s)",
      view[1],
      view[2],
      view[3],
      format(dist, digits = 4)
    ),
    "      );"
  )
  # splice: replace i..i+3 with the (possibly longer) replacement
  before <- if (i > 1) js[seq_len(i - 1)] else character()
  after <- if ((i + 4L) <= length(js)) js[(i + 4L):length(js)] else character()
  js <- c(before, replacement, after)
  writeLines(js, path)
  invisible(path)
}

#' Mirror `x`'s depth coordinate (Y) about its own Y-midpoint so its 3-D
#' front/back curvature mirrors the opposite half, keeping it spatially in place.
#' Used on CST_R so the right half's depth-curvature mirrors CST_L, giving a
#' cleaner symmetric butterfly cone in the crown-up camera view.
mirror_depth <- function(x) {
  pts <- do.call(rbind, lapply(x@streamlines, function(s) s@points))
  ymid <- (max(pts[, 2]) + min(pts[, 2])) / 2
  out <- lapply(x@streamlines, function(s) {
    P <- s@points
    P[, 2] <- 2 * ymid - P[, 2]
    fiber::streamline(
      points = P,
      point_data = s@point_data,
      streamline_data = s@streamline_data
    )
  })
  fiber::bundle(streamlines = out)
}

#' Rotate each streamline of `x` by `ang` degrees about the bundle's crown
#' centre (topmost Z) in the horizontal plane, fanning the stems outward.
splay_bundle <- function(x, ang) {
  if (isTRUE(all.equal(ang, 0))) {
    return(x)
  }
  sls <- x@streamlines
  # per-streamline crown pivot; derive a single pivot from all points
  pts <- do.call(rbind, lapply(sls, function(s) s@points))
  ztop <- max(pts[, 3])
  cx <- mean(pts[pts[, 3] > (ztop - 5), 1])
  a <- ang * pi / 180
  rot <- function(P) {
    xx <- P[, 1] - cx
    zz <- P[, 3] - ztop
    newx <- cx + xx * cos(a) + zz * sin(a)
    newz <- ztop - xx * sin(a) + zz * cos(a)
    P[, 1] <- newx
    P[, 3] <- newz
    P
  }
  out <- lapply(sls, function(s) {
    fiber::streamline(
      points = rot(s@points),
      point_data = s@point_data,
      streamline_data = s@streamline_data
    )
  })
  fiber::bundle(streamlines = out)
}

#' Build a served rtists widget directory for a package's logos scene.
#'
#' Renders CST_L + CST_R merged into a single symmetric two-tract `bundle` scene
#' in `color` (both halves share the package colour), mode `line2` (baseline) or
#' `tube` (rtists). Merging into one bundle keeps the df free of a `BundleName`
#' column so no legend/aesthetic meta is produced and the simple build path runs.
#' Writes a non-self-contained widget dir at `dir` for http.server + screenshot.
#'
#' `splay` (degrees) fans the two halves outward about their crowns so the stems
#' spread left/right instead of converging to a central column, giving the shared
#' "symmetrical pyramidal tract that fans left and right" glyph. `splay = 0` is
#' the raw anatomy (butterfly cone). `nL`/`nR` override sample counts.
#'
#' `mirror_x_side` is the APPROVED v24 mode: instead of merging the two (unequal)
#' anatomy halves, it builds an EXACTLY left/right symmetric butterfly from a
#' SINGLE hemisphere (`"L"` = `cl` crown-sample as the left wing, `"R"` = `cr`
#' as the right wing), with the opposite wing being the reflection of the base
#' across the X = 0 axis. This removes the constant LR mass imbalance of the raw
#' anatomical render. `mirror_x_side` requires `crown_idx`.
#'
#' With `patch = TRUE` (default) the widget is patched in place: the camera is
#' re-aimed (look along +Y so X -> screen-horizontal, Z -> screen-vertical,
#' crown-up) and the three.js AxesHelper gizmo is removed. `cam_dist = 1.9` is
#' the approved v24 camera distance.
make_scene <- function(
  pkg = "fiber",
  dir,
  mode = c("line2", "tube"),
  linewidth = 1.6,
  radius = 3,
  opacity = 0.9,
  bg = "#0d1117",
  color = PALETTE[[pkg]],
  width = 900,
  height = 900,
  splay = 0,
  nL = NULL,
  nR = NULL,
  mirror_r = FALSE,
  crown_idx = NULL,
  mirror_x_side = NULL, # "L" or "R": build exact-symmetric butterfly from one hemisphere
  cam_view = c(0, 1, 0),
  cam_up = c(0, 0, 1),
  cam_dist = 1.9,
  patch = TRUE
) {
  mode <- match.arg(mode)
  if (!is.null(mirror_x_side)) {
    # approved v24: single-hemisphere exact-symmetric butterfly
    if (is.null(crown_idx)) {
      stop("mirror_x_side requires crown_idx (list(iL=, iR=) of crown samples)")
    }
    if (!mirror_x_side %in% c("L", "R")) stop("mirror_x_side must be 'L' or 'R'")
    idx <- readRDS(crown_idx)
    base <- if (mirror_x_side == "L") cl[idx$iL] else cr[idx$iR]
    bL <- base
    bR <- mirror_x(base, axis = 0)
  } else {
    iL <- if (!is.null(nL)) sort(sample.int(5577, nL)) else .IDX_L
    iR <- if (!is.null(nR)) sort(sample.int(2397, nR)) else .IDX_R
    if (!is.null(crown_idx)) {
      # crown-stratified indices (list(iL=, iR=)), the agreed 30/side crown sampling
      idx <- readRDS(crown_idx)
      iL <- idx$iL
      iR <- idx$iR
    }
    bL <- cl[iL]
    bR <- cr[iR]
    # mirror CST_R's depth (Y) so it mirrors CST_L's 3-D curvature (symmetric cone)
    if (isTRUE(mirror_r)) {
      bR <- mirror_depth(bR)
    }
  }
  if (!isTRUE(all.equal(splay, 0))) {
    bL <- splay_bundle(bL, splay)
    bR <- splay_bundle(bR, -splay)
  }
  # merge both bundles' streamlines into a single bundle (one colour).
  # subsetting names both halves' elements "1","2",... -> unname to avoid
  # duplicate S7 object names error in bundle()
  sls <- c(unname(bL@streamlines), unname(bR@streamlines))
  merged <- fiber::bundle(streamlines = sls)
  w <- rtists::plot3d(
    merged,
    color = color,
    backend = "threejs",
    linewidth = linewidth,
    radius = if (mode == "tube") radius else NULL,
    opacity = opacity,
    bg = bg,
    tooltip = FALSE
  )
  # force square widget sizing so the canvas is square for the hexagon
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
  if (patch) {
    patch_camera(dir, view = cam_view, up = cam_up, dist = cam_dist)
    patch_axes(dir)
  }
  invisible(w)
}

#' Reflect `x`'s horizontal coordinate (X) about a fixed vertical axis (default
#' X = 0, the axis between the two hemispheres), producing a mirror wing on the
#' opposite side. Used to build an EXACTLY left/right-symmetric butterfly cone
#' from a single hemisphere (e.g. right wing = mirror_x(left, axis = 0)).
mirror_x <- function(x, axis = 0) {
  out <- lapply(x@streamlines, function(s) {
    P <- s@points
    P[, 1] <- 2 * axis - P[, 1]
    fiber::streamline(
      points = P,
      point_data = s@point_data,
      streamline_data = s@streamline_data
    )
  })
  fiber::bundle(streamlines = out)
}

#' Remove the three.js AxesHelper that rtists::plot3d's threejs backend adds at
#' the data origin. Without this the red/green/blue axes gizmo is drawn into the
#' render; it reads as stray "plot axes" and (being coloured, not white) also
#' survives chroma_key_white and gets composited into the logo as asymmetric
#' mass. The block
#'   // ---- spatial reference (axes at data origin, in tract units) --------
#'   const axes = new THREE.AxesHelper(20);
#'   scene.add(axes);
#' is deleted from rtists-render.js.
patch_axes <- function(dir) {
  path <- file.path(dir, "index_files", "threejs-0.186.0", "rtists-render.js")
  js <- readLines(path, warn = FALSE)
  hit <- grep("spatial reference \\(axes at data origin", js)
  if (length(hit) == 0) {
    return(invisible(FALSE)) # axes block already gone
  }
  # the block is the comment line + 2 code lines (const axes, scene.add(axes))
  rem <- hit[1]:(hit[1] + 2L)
  if (!any(grepl("new THREE.AxesHelper", js[rem][2:3]))) {
    stop("unexpected axes block layout -- inspect rtists-render.js manually")
  }
  writeLines(js[-rem], path)
  invisible(TRUE)
}
