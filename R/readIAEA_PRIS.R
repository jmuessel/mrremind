#' read IAEA Power Reactor Information System
#'
#' read Nuclear capacities and near-term outlook from data scraped from
#' https://pris.iaea.org/PRIS/CountryStatistics/CountryStatisticsLandingPage.aspx
#'
#' @author Pascal Weigmann
#' @importFrom readxl read_xlsx
#'
#' @export
readIAEA_PRIS <- function() {
  # only information given is what is currently operating and what is under
  # construction (without start date). all calculations are about 2030 estimates
  x <- readxl::read_xlsx("nuclear_capacities_20240716.xlsx") %>%
    mutate("operational"  = .data$operational,
           "construction" = .data$construction,
           "inactive"     = .data$inactive,  # only relevant for Japan
           variable = "Cap|Electricity|Nuclear") %>%
    mutate(year = "y2020") %>%  # technically, its 2024
    tidyr::pivot_longer(cols = c("operational", "construction", "inactive"),
                        names_to = "status") %>%
    select("country", "year", "variable", "status", "unit", "value") %>%
    as.magpie(spatial = "country", temporal = "year") %>%
    add_dimension(dim = 3.1, add = "model", nm = "IAEA_PRIS")

  # move "construction" and "inactive" values to year 2030
  x <- add_columns(x, addnm = c("y2030"), dim = 2, fill = NA)
  x[, 2030, "inactive"]     <- x[, 2020, "inactive"]
  x[, 2030, "construction"] <- x[, 2020, "construction"]
  x[, 2020, c("construction", "inactive")] <- 0

  # assume no retirement (for now)
  x[, 2030, "operational"] <- x[, 2020, "operational"]

  return(x)
}
