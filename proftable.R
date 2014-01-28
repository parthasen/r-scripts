proftable <- function(x, ...) {
  UseMethod("proftable")
}

proftable.default <- function(filename, lines = 10) {
  con <- file(filename, "rt")
  on.exit(close(con))
  profdata <- readLines(con)
  interval <- as.numeric(strsplit(profdata[1L], "=")[[1L]][2L]) / 1e+06
  filelines <- grep("^#File [0-9]+: ", profdata)
  files <- profdata[filelines]
  filenums <- as.integer(gsub("^#File ([0-9]+): .*", "\\1", files))
  filenames <- gsub("^#File [0-9]+: ", "", files)
  if (length(filelines))
    profdata <- profdata[-1:-filelines]
  total.time <- interval * length(profdata)
  ncalls <- length(profdata)
  profdata <- gsub("\\\"| $", "", profdata)
  calls <- lapply(profdata, function(x) rev(unlist(strsplit(x, " "))))
  calls.len <- range(sapply(calls, length))
  parent.call <- unlist(lapply(seq(calls.len[1]), function(i) Reduce(intersect, lapply(calls,"[[", i))))
  calls <- lapply(calls, function(x) setdiff(x, parent.call))
  stacktable <- as.data.frame(table(sapply(calls, function(x) paste(x, collapse = " > "))) / ncalls * 100, stringsAsFactors = FALSE)
  stacktable <- stacktable[order(stacktable$Freq[], decreasing = TRUE), 2:1]
  colnames(stacktable) <- c("PctTime", "Call")
  rownames(stacktable) <- NULL
    stacktable <- head(stacktable, lines)
  if (length(parent.call) > 0)
    parent.call <- paste(parent.call, collapse = " > ")
  else
    parent.call <- "None"
  frac <- sum(stacktable$PctTime)
  result <- list(calls = calls, stacktable = stacktable, parent.call = parent.call, interval = interval, total.time = total.time, files = filenames, total.pct.time = frac)
  class(result) <- "proftable"
  return(result)
}

print.proftable <- function(x) {
  print(x$stacktable, row.names=FALSE, right=FALSE, digits=3)
  cat("\nFiles:\n")
  cat(paste(x$files, collapse="\n"))
  cat("\n\n")
  cat(paste("Parent Call:", x$parent.call))
  cat("\n\n")
  cat(paste("Total Time:", x$total.time, "seconds"))
  cat("\n")
  cat(paste0("Percent of run time represented: ", format(x$total.pct.time, digits = 3), "%"))
} 