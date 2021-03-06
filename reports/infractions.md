---
title: "Investigating the Infraction Columns"
author: "Aaron Jacobs"
date: "January 22, 2017"
output:
  md_document:
    variant: markdown_github
    fig_width: 6
    fig_height: 4
    preserve_yaml: true
---

The [data dictionary](http://opendata.toronto.ca/revenue/parking/ticket/parking_tickets_readme.xls) for the raw parking tickets data sets seems to indicate that there are three columns containing the definition of the particular infraction: `infraction_code`, `infraction_description`, and `set_fine_amount`. It sounds like all three of these columns should be consistent across all tickets, so we can significantly reduce the size of the data by moving the unique infraction entries to their own table, and keeping only a reference to the infraction code for each ticket entry.

However, we need to check that these columns really are that simple before proceeding, so we load the data in the staging table.

``` r
library(dplyr, warn.conflicts = FALSE)

db <- src_sqlite("../tickets.sqlite")
tickets_staging <- tbl(db, "tickets_staging")
```

Now we can compute the frequency of all of unique combinations of these columns in the raw data:

``` r
infractions <- tickets_staging %>%
    select(code = infraction_code, desc = infraction_description,
           fine = set_fine_amount) %>%
    group_by(code, desc, fine) %>%
    summarise(freq = n()) %>%
    ungroup() %>%
    collect()

infractions
```

    ## # A tibble: 767 × 4
    ##     code                           desc  fine   freq
    ##    <int>                          <chr> <int>  <int>
    ## 1      1          PARK AT EXPIRED METER    30  18279
    ## 2      1  PARK FAIL TO DEP FEE IN METER     0      1
    ## 3      1  PARK FAIL TO DEP FEE IN METER    30   2890
    ## 4      1 PARK FAIL TO DEPOSIT FEE METER    30  27335
    ## 5      1 PARK-FAIL TO DEPOSIT FEE METER    30   5345
    ## 6      2     PARK - LONGER THAN 3 HOURS     0     39
    ## 7      2     PARK - LONGER THAN 3 HOURS    15 214482
    ## 8      2       PARK LONGER THAN 3 HOURS    15 488896
    ## 9      2              PARK OVER 3 HOURS    15 185159
    ## 10     2       PARK-LONGER THAN 3 HOURS    15  40534
    ## # ... with 757 more rows

OK, so there are two obvious problems with this from the outset. The first is that it looks like at least some of the codes have multiple descriptions. The second is that some of the codes seem to have different fines for different entries. I'll return to this second problem below, but for now let's focus on the first one.

The first thing to do is check how big a problem this is. What is the set of codes that are "well-defined", in the sense that they have only one definition in the dataset?

``` r
once.mentioned <- infractions %>%
    # Pull out all of the codes that only have one "definition".
    group_by(code) %>%
    summarise(freq = n()) %>%
    ungroup() %>%
    filter(freq == 1) %>%
    select(code)

well.defined <- once.mentioned %>%
    # Semi join on these to get the "well-defined" infractions.
    semi_join(infractions, ., by = "code")

well.defined
```

    ## # A tibble: 113 × 4
    ##     code                           desc  fine  freq
    ##    <int>                          <chr> <int> <int>
    ## 1     43 PARALLEL PARK-METERED SPACE-FR    30     4
    ## 2     45 ANGLE PARK-METERED SPACE-FRONT    30    36
    ## 3     66     STOP-ON ELEVATED STRUCTURE    60     6
    ## 4     76      STOP VEH VEND OVER 10 MIN    60     1
    ## 5     87     PARK MOTORCYCLE - AT ANGLE    30     4
    ## 6     89     PARK MOTORCYCLE - IN SPACE    30     2
    ## 7    106  PARK ON SIDE PROH DAY TO SIGN    30     2
    ## 8    115    PARK METERED SPACE PARK LOT    15     3
    ## 9    122 PARK METERED ZONE NOT CLOSE AS    30     1
    ## 10   129    STOP PROH TIME MAITLAND ST.    60     1
    ## # ... with 103 more rows

Compare the number of rows in the well-defined group against the total number of codes we've got:

``` r
infractions %>%
    summarise(total.codes = n_distinct(code))
```

    ## # A tibble: 1 × 1
    ##   total.codes
    ##         <int>
    ## 1         246

So there are quite a few problematic definitions, although not too many to go over completely manually if necessary. What are possible explanations for the large number of variants we observe?

One possibility is that the descriptions and fines sometimes changed over time. After all, there eight years of data available. To test this, let's look at code `1`, which seems to indicate a failure to pay at a parking meter in a timely fashion. Do the descriptions and fines change over the years?

``` r
code.ones <- tickets_staging %>%
    filter(infraction_code == 1) %>%
    mutate(year = substr(date_of_infraction, 1, 4)) %>%
    group_by(year, infraction_description, set_fine_amount) %>%
    summarise(freq = n()) %>%
    ungroup() %>%
    collect()

code.ones
```

    ## # A tibble: 33 × 4
    ##     year         infraction_description set_fine_amount  freq
    ##    <chr>                          <chr>           <int> <int>
    ## 1   2008          PARK AT EXPIRED METER              30  3991
    ## 2   2008  PARK FAIL TO DEP FEE IN METER              30  1207
    ## 3   2008 PARK FAIL TO DEPOSIT FEE METER              30  5516
    ## 4   2008 PARK-FAIL TO DEPOSIT FEE METER              30  1193
    ## 5   2009          PARK AT EXPIRED METER              30  2923
    ## 6   2009  PARK FAIL TO DEP FEE IN METER              30   286
    ## 7   2009 PARK FAIL TO DEPOSIT FEE METER              30  4355
    ## 8   2009 PARK-FAIL TO DEPOSIT FEE METER              30   750
    ## 9   2010          PARK AT EXPIRED METER              30  3616
    ## 10  2010  PARK FAIL TO DEP FEE IN METER              30   292
    ## # ... with 23 more rows

Well... it's not clear that this is the case. Perhaps there are more general patterns over time in the usage of these descriptions? If, say a new description was phased in over a number of years as individual machines were updated, we'd see the process of a takeover:

``` r
library(ggplot2)

code.ones %>%
    mutate(year = as.integer(year),
           desc = forcats::fct_reorder(infraction_description,
                                       freq, fun = sum)) %>%
    ggplot() +
    scale_fill_brewer(palette = "Spectral",
                      guide = guide_legend(ncol = 2)) +
    scale_y_continuous(labels = scales::percent) +
    geom_col(aes(x = year, y = freq, fill = desc),
             position = position_fill()) +
    labs(fill = NULL, x = NULL, y = NULL,
         title = "Descriptions for Tickets Marked Code 1, 2008-2015") +
    theme_minimal() +
    theme(legend.position = "bottom")
```

![](figures/infractions/more-code-one-1.png)

And yet... that's not quite what we see, at least for code `1`. Sure there's a shift over time, but eight years to implement a new infraction description that is already the most common in 2008 seems implausible. It remains something of a mystery.

Wait -- what about those $0 fines?
----------------------------------

TODO
