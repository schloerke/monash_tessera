

# Rhipe is loaded when R is loaded


map1 <- expression({
  lapply(seq_along(map.keys), function(r) {
    line = strsplit(map.values[[r]], ",")[[1]]
    outputkey <- line[1:3]
    outputvalue <- data.frame(
      date = as.numeric(line[4]),
      units =  as.numeric(line[5]),
      listing = as.numeric(line[6]),
      selling = as.numeric(line[7]),
      stringsAsFactors = FALSE
    )
  rhcollect(outputkey, outputvalue)
  })
})

reduce1 <- expression(
  pre = {
    reduceoutputvalue <- data.frame()
  },
  reduce = {
    reduceoutputvalue <- rbind(reduceoutputvalue, do.call(rbind, reduce.values))
  },
  post = {
    reduceoutputkey <- reduce.key[1]
    attr(reduceoutputvalue, "location") <- reduce.key[1:3]
    names(attr(reduceoutputvalue, "location")) <- c("FIPS","county","state")
    rhcollect(reduceoutputkey, reduceoutputvalue)
  }
)

mr1 <- rhwatch(
  map      = map1,
  reduce   = reduce1,
  input    = rhfmt("/user/barret/housing/housing.txt", type = "text"),
  output   = rhfmt("/user/barret/housing/byCounty", type = "sequence"),
  readback = FALSE
)



###########################################################################


library(datadr)
conn <- hdfsConn("/user/barret/housing/byCounty")

# addData(conn, housing)
housingDdf <- ddf(conn)
housingDdf
housingDdf <- updateAttributes(housingDdf)

byDate <- divide(
  housingDdf,
  by = "date",
  output = hdfsConn("/user/barret/housing/byDate", autoYes=TRUE),
  update = TRUE
)

# byDate <- ddf(hdfsConn("/user/barret/housing/byDate"))


byDateSummary <- addTransform(byDate, function(x) {
  data.frame(
    unitsMin = min(x$units, na.rm = TRUE),
    unitsMax = max(x$units, na.rm = TRUE),
    listingMedian = median(x$listing, na.rm = TRUE)
  )
})
# compute lm coefficients for each division and rbind them
dateResults <- recombine(byDateSummary, combRbind)

# install.packages("tidyr")
library(dplyr)
dplyr::as_data_frame(dateResults)
# Source: local data frame [66 x 4]
#
#     date unitsMin unitsMax listingMedian
#    (dbl)    (dbl)    (dbl)         (dbl)
# 1     66      Inf     -Inf      86.36968
# 2     65      Inf     -Inf      85.46121
# 3     64      Inf     -Inf      84.94192
# 4     63      Inf     -Inf      85.15570
# 5     62       11    35619      85.31746
# 6     61       11     7946      86.36034
# 7     60       11     6937      86.44231
# 8     59       11     8468      86.27273
# 9     58       11     9184      86.35314
# 10    57       11     8464      86.23297
# ..   ...      ...      ...           ...
