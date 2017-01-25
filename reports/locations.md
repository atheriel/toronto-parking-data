---
title: "Investigating the Location Columns"
author: "Aaron Jacobs"
date: "January 24, 2017"
output:
  md_document:
    variant: markdown_github
    fig_width: 6
    fig_height: 4
    preserve_yaml: true
---

The [data dictionary](http://opendata.toronto.ca/revenue/parking/ticket/parking_tickets_readme.xls) for the raw parking tickets data sets points to a complex encoding of the location the ticket was given at. It looks as though there can be two street addresses, along with a description of the "proximity" of each. What does this mean in practice? And is it possible to map this location encoding to, say, longitude and latitude?

To get a sense of what is going on, we can load the data in the staging table

``` r
library(dplyr, warn.conflicts = FALSE)

db <- src_sqlite("../tickets.sqlite")
tickets_staging <- tbl(db, "tickets_staging")
```

And take a peek at the location rows:

``` r
tickets_staging %>%
    select(location1:location4) %>%
    print(n = 20)
```

    ## Source:   query [?? x 4]
    ## Database: sqlite 3.11.1 [../tickets.sqlite]
    ## 
    ##    location1              location2 location3      location4
    ##        <chr>                  <chr>     <chr>          <chr>
    ## 1         NR        355 PARKSIDE DR      <NA>           <NA>
    ## 2         NR          220 KING ST W      <NA>           <NA>
    ## 3        N/S                 ELM ST       W/O   ELIZABETH ST
    ## 4        N/S              WALTON ST       E/O         BAY ST
    ## 5        S/S         SHEPPARD AVE E       E/O    NEILSON AVE
    ## 6        N/S              WALTON ST       E/O         BAY ST
    ## 7        S/S         SHEPPARD AVE E       E/O    NEILSON AVE
    ## 8         NR 35 THORNCLIFFE PARK DR      <NA>           <NA>
    ## 9        N/S                 ELM ST       E/O UNIVERSITY AVE
    ## 10       S/S         SHEPPARD AVE E       E/O    NEILSON AVE
    ## 11       S/S         SHEPPARD AVE E       E/O    NEILSON AVE
    ## 12        NR         968 QUEEN ST W      <NA>           <NA>
    ## 13       N/S                 ELM ST       E/O UNIVERSITY AVE
    ## 14       S/S         SHEPPARD AVE E       E/O    NEILSON AVE
    ## 15        NR        193 PARKSIDE DR      <NA>           <NA>
    ## 16        NR        193 PARKSIDE DR      <NA>           <NA>
    ## 17        NR        193 PARKSIDE DR      <NA>           <NA>
    ## 18       S/S         SHEPPARD AVE E       E/O    NEILSON AVE
    ## 19       OPP        86 GERRARD ST E      <NA>           <NA>
    ## 20       OPP        86 GERRARD ST E      <NA>           <NA>
    ## # ... with more rows

From this particular sample, this data doesn't look so bad. The answer to why there are sometimes one and sometimes two street addresses seems to be that some entries point to an intersection.

How complete is the location data? And how often is an intersection -- as opposed to a single address -- assigned to a ticket?

``` r
location.counts <- tickets_staging %>%
    summarise(total = n(),
              one = sum(!is.na(location2)),
              two = sum(!is.na(location4))) %>%
    collect()

location.counts %>%
    mutate(one = one / total, two = two / total)
```

    ## # A tibble: 1 × 3
    ##      total       one        two
    ##      <int>     <dbl>      <dbl>
    ## 1 20723102 0.9996146 0.04723776

So these intersections are less common than one might have thought, looking at the sample above. The overwhelmingly more common case is that of a single address. It's also clear that the location data is pretty complete. More than 99 percent of tickets have non-missing data.
