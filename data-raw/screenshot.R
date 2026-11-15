#!/usr/bin/env Rscript
# screenshot.R -- screenshot a served rtists widget's canvas with chromote
# (replaces the old system-python screenshot.py; webshot2 is the browser lib).
#
# Usage:
#     Rscript screenshot.R PATH OUT [PORT]
#
# Renders the headless-chromium canvas of
#     http://127.0.0.1:{PORT}/{PATH}/index.html
# to OUT (a PNG) at 1200x1200 viewport and device-scale-factor 2, clipped to the
# exact canvas bounding box. The widget dir must be reachable under PATH on an
# httpuv static server rooted at the parent of PATH (see logo-family.R, which
# starts the server and passes the relative path + port).
#
# This is the only step in the logo pipeline that needs a real browser. It runs
# headless chromium via chromote (webshot2 0.1.2 / chromote 0.5.1 + a
# Chrome-for-Testing build). WebGL works under swiftshader. The convention kept:
# dash-separated filename (data-raw/), same CLI contract as the old screenshot.py.
#
# Requires (R): webshot2 (or chromote), plus whatever served the widget (httpuv).

args <- commandArgs(trailingOnly = TRUE)
path <- args[1]
out <- args[2]
port <- if (length(args) > 2L) args[3] else "8399"
url <- sprintf("http://127.0.0.1:%s/%s/index.html", port, path)

suppressMessages(library(chromote))

# Headless chromium must draw WebGL for the threejs canvas; force software
# rendering (swiftshader) just like the old playwright flags. Custom launch args
# are set on chromote's global defaults (Chromote$new() reads them).
intended <- c(
  "--headless=new",
  "--use-gl=swiftshader",
  "--enable-unsafe-swiftshader",
  "--enable-webgl",
  "--ignore-gpu-blocklist"
)
current <- chromote::get_chrome_args()
chromote::set_chrome_args(unique(c(current, intended)))
on.exit(chromote::reset_chrome_args(), add = TRUE)

chrome <- chromote::Chromote$new()
on.exit(try(chrome$close(), silent = TRUE), add = TRUE)

s <- chrome$new_session(width = 1200, height = 1200, wait_ = TRUE)

# Navigate to the served widget. The canvas poll below is what actually gates
# production: it returns only once the threejs canvas is on the page.
invisible(s$Page$navigate(url, wait_ = TRUE))

s$Emulation$setDeviceMetricsOverride(
  width = 1200,
  height = 1200,
  deviceScaleFactor = 2,
  mobile = FALSE,
  wait_ = TRUE
)

# Wait for the canvas to appear (poll like playwright's wait_for_selector).
wait_for_canvas <- function(session, timeout = 10000) {
  deadline <- Sys.time() + timeout / 1000
  while (Sys.time() < deadline) {
    res <- session$Runtime$evaluate(
      "document.querySelector('canvas') ? {has:true, box:(function(r){return {x:r.x,y:r.y,width:r.width,height:r.height}})(document.querySelector('canvas').getBoundingClientRect())} : {has:false}",
      returnByValue = TRUE,
      wait_ = TRUE
    )
    has <- isTRUE(res$result$value$has)
    if (has) {
      return(res$result$value$box)
    }
    Sys.sleep(0.1)
  }
  NULL
}
clip <- wait_for_canvas(s)
if (is.null(clip)) {
  message("no canvas found in 10s")
  quit(status = 1)
}
message(sprintf(
  "canvas clip: x=%.0f y=%.0f w=%.0f h=%.0f",
  clip$x,
  clip$y,
  clip$width,
  clip$height
))

Sys.sleep(2.5)

# selector = "canvas" clips to the canvas bounding box; scale = 2 gives the
# hi-res capture (device-scale-factor 2), matching the old screenshot.py.
invisible(s$screenshot(
  filename = out,
  selector = "canvas",
  scale = 2,
  show = FALSE,
  wait_ = TRUE
))
message(sprintf("screenshot.R: wrote %s", out))
