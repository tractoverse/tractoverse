# crown_sample.R - re-implementation of the "densest-top" crown-stratified
# downsampling (persisted this time; the v18-test-era algorithm was interactive
# only and lost). Goal (per tractoverse AGENTS.md): select `n` streamlines per
# side, with the downsampling concentrated in the densest areas at the top
# ("the crown" = uppermost part of each bundle), so the sparse fan stays even
# near the apex.
#
# Geometry: the scene camera looks along +Y, so X = screen-horizontal and
# Z = screen-vertical with the crown pointing UP (high Z). The tract fans from
# the medial apex (X ~ 0, high Z) out to the lateral rim (X ~ -50, low Z).
#
#  * crown  = points with Z >= zmin + z_frac*(zmax-zmin)  (uppermost slab =
#    the "dense top" where all streamlines converge).
#  * fanpos = per-streamline crown anchor: the mean X of its crown points.
#    Orders streamlines left-to-right across the crown fan.
#  * Selection: DETERMINISTIC EVEN SPACING along the crown fan order
#    (one per ~ns/n rank step), giving even, full-width fan coverage that is
#    "even near the apex" while keeping all picks inside the dense crown.
#    This reproduces the approved render's span (measured):
#      crown-X span ~ [-48.8, -11.1], peak-Z span ~ [50.4, 77.1] (left bundle).
#
# Intentionally simple and fully reproducible; the exact interactive index set
# from the lost session is not a target - visual parity is what counts
# (validated by measurable pixel properties + user review).

# bundle: a fiber::bundle. n: target count. z_frac: top slab fraction of the Z
# range treated as "crown". Returns the integer indices (into bundle@streamlines)
# of the `n` selected streams, sorted.
crown_sample <- function(bundle, n = 30, z_frac = 0.25) {
  sls <- bundle@streamlines
  ns <- length(sls)
  # Roll up all points with the streamline index as col 1
  pts <- do.call(
    rbind,
    lapply(seq_len(ns), function(i) {
      p <- sls[[i]]@points
      cbind(i, p[, 1, drop = TRUE], p[, 3, drop = TRUE])
    })
  )
  colnames(pts) <- c("sl", "X", "Z")
  zmin <- min(pts[, "Z"])
  zmax <- max(pts[, "Z"])
  zlo <- zmin + z_frac * (zmax - zmin)
  cr <- pts[pts[, "Z"] >= zlo, , drop = FALSE]
  # per-streamline crown fan position = mean X over its crown points
  fanpos <- tapply(cr[, "X"], cr[, "sl"], mean)
  if (length(fanpos) < ns) {
    # streamlines with no crown point: sent to the end (no crown footprint)
    miss <- setdiff(seq_len(ns), as.integer(names(fanpos)))
    missv <- rep(Inf, length(miss))
    names(missv) <- miss
    fanpos <- c(fanpos, missv)
  }
  fanpos <- fanpos[as.character(seq_len(ns))]
  ord <- order(fanpos)
  pos <- round(seq(1, ns, length.out = n))
  sel <- sort(ord[pos])
  as.integer(names(fanpos)[sel])
}

# Write a crown_strat-style index set (list(iL=, iR=)) with .X-named element
# names matching the old crown_strat_NN.rds convention, and save to RDS.
make_crown_strat <- function(path_out, n = 30, z_frac = 0.25) {
  iL <- crown_sample(cl, n, z_frac)
  iR <- crown_sample(cr, n, z_frac)
  names(iL) <- paste0(iL, ".X")
  names(iR) <- paste0(iR, ".X")
  res <- list(iL = iL, iR = iR)
  saveRDS(res, path_out)
  res
}
