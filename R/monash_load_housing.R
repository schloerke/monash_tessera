

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



##########################################################################


map2 <- expression({
  lapply(seq_along(map.keys), function(r) {
    outputvalue <- data.frame(
      FIPS = map.keys[[r]],
      county = attr(map.values[[r]], "location")["county"],
      min = min(map.values[[r]]$listing, na.rm = TRUE),
      median = median(map.values[[r]]$listing, na.rm = TRUE),
      max = max(map.values[[r]]$listing, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
    outputkey <- attr(map.values[[r]], "location")["state"]
    rhcollect(outputkey, outputvalue)
  })
})

reduce2 <- expression(
  pre = {
    reduceoutputvalue <- data.frame()
  },
  reduce = {
    reduceoutputvalue <- rbind(reduceoutputvalue, do.call(rbind, reduce.values))
  },
  post = {
    rhcollect(reduce.key, reduceoutputvalue)
  }
)

CountyStats <- rhwatch(
  map      = map2,
  reduce   = reduce2,
  input    = 2^20,
  output   = rhfmt("/user/barret/housing/countyStats", type = "sequence"),
  readback = TRUE
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

byDate <- ddf(hdfsConn("/user/barret/housing/byDate"))
byDate <- fileDisk


byDateSummary <- addTransform(byDate, function(x) {
  data.frame(
    unitsMin = min(x$units, na.rm = TRUE),
    unitsMax = max(x$units, na.rm = TRUE),
    listingMedian = median(x$listing, na.rm = TRUE)
  )
})
# compute lm coefficients for each division and rbind them
recombine(byDateSummary, combRbind)
