The original CSV files have a column named "province" which seemed contain a two-character code, perhaps for the province of the license plate the ticket is being issued for. We want to verify that this is the case.

To do this, we load the SQLite table containing all of the raw, newly-imported data. This works seemlessly with the dplyr package.

``` r
library(dplyr, warn.conflicts = FALSE)

db <- src_sqlite("../tickets.sqlite")
tickets_staging <- tbl(db, "tickets_staging")

select(tickets_staging, province)
```

    ## Source:   query [?? x 1]
    ## Database: sqlite 3.11.1 [../tickets.sqlite]
    ## 
    ##    province
    ##       <chr>
    ## 1        ON
    ## 2        ON
    ## 3        ON
    ## 4        ON
    ## 5        ON
    ## 6        ON
    ## 7        ON
    ## 8        NJ
    ## 9        ON
    ## 10       ON
    ## # ... with more rows

The first ten rows contain a large number of "ON" entries, which is exactly what you'd expect in Toronto, Ontario. To get a more exact picture of these entries, we can count the number of occurences of each code (note that this query may take a little while).

``` r
prov.counts <- tickets_staging %>%
    group_by(province) %>%
    summarise(count = n()) %>%
    ungroup() %>%
    arrange(desc(count)) %>%
    collect()

prov.counts
```

    ## # A tibble: 74 × 2
    ##    province    count
    ##       <chr>    <int>
    ## 1        ON 19755734
    ## 2        QC   259335
    ## 3        AB    93616
    ## 4        NY    79045
    ## 5        BC    50804
    ## 6        NS    41683
    ## 7        MI    38292
    ## 8        FL    38024
    ## 9        AZ    27698
    ## 10       MB    26286
    ## # ... with 64 more rows

This gives us our first little surprise: from those two-letter codes, it looks like New York, Michigan, Florida, and Arizona plates make the top-ten most ticketed list -- and therefore this column must regularly contain plates from the United States.

To formalize this observation, we want to check if all of the entries in the column map to province or state abbreviations. After some web surfing, it seems like Canadian [province](https://en.wikipedia.org/wiki/ISO_3166-2:CA) and [US state](https://en.wikipedia.org/wiki/ISO_3166-2:US) abbreviations are codified in the ISO 3166-2 standard. I've put together a simple CSV file collating province and state abbreviations together, which we can load into R and combine with the summary above.

``` r
iso3166 <- readr::read_csv("../data/iso-3166-2.csv")
```

    ## Parsed with column specification:
    ## cols(
    ##   code = col_character(),
    ##   place = col_character(),
    ##   country = col_character()
    ## )

``` r
semi_join(prov.counts, iso3166, by = c("province" = "code")) %>%
    arrange(desc(count))
```

    ## # A tibble: 67 × 2
    ##    province    count
    ##       <chr>    <int>
    ## 1        ON 19755734
    ## 2        QC   259335
    ## 3        AB    93616
    ## 4        NY    79045
    ## 5        BC    50804
    ## 6        NS    41683
    ## 7        MI    38292
    ## 8        FL    38024
    ## 9        AZ    27698
    ## 10       MB    26286
    ## # ... with 57 more rows

It looks like this catches most of the entires. What doesn't get matched?

``` r
anti_join(prov.counts, iso3166, by = c("province" = "code"))
```

    ## # A tibble: 7 × 2
    ##   province count
    ##      <chr> <int>
    ## 1       PW     1
    ## 2       MH     1
    ## 3       GO     2
    ## 4     <NA>    19
    ## 5       XX   794
    ## 6       NF  7229
    ## 7       PQ 16980

There are several interesting things here. First of all, there are a large number of entries labelled `PQ` and `NF`. If I had to hazzard a guess, I'd say that these are likely erroneous entries for Quebec (otherwise abbreviated `QC`) and Newfoundland and Labrador (otherwise abbreviated `NL`). "PQ" (for "province de Quebec") is a widely-used abbreviation for that province, and `NF` would be a pretty understandable error as well.

Secondly, there are the one-off (or two-off) entries `PW`, `MH`, and `GO`. I suspect that these are literal "fat-fingered" data entry mistakes, since W is next to Q on a keyboard (making `PW` plausibly `PQ`) and H is next to N (making `MH` plausibly `MN`, for Minnesota). I'm less confident about `GO` along these lines, though.

Last, there are missing values `<NA>` and the mysterious `XX`. I strongly suspect that `XX` was used during data entry for placeholder/don't know/can't remember.

So what is the strategy for dealing with these errors? For `PQ`, `NF`, and `XX` I believe that re-encoding entries is justified. For the remaining likely-erroneous entries, I'm not confident enough in my re-encoding to justify changing them. Thankfully there are few enough that these entries won't affect any subsequent analysis much. To this end:

-   The `fix-province-entries.sql` file in the root directory re-encodes the `PQ`, `NF`, and `XX` entries in the staging table.
-   There is a `import-iso-3166-2-table.sh` script that will populate an `iso3166` table in the database containing these codes and the associated places and countries.
