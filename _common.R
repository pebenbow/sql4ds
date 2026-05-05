# _common.R
# Shared setup sourced at the top of each chapter that contains SQL code blocks.
# Establishes a DBI connection to the course PostgreSQL container.
#
# Prerequisites:
#   install.packages(c("DBI", "RPostgres"))
#
# The container must be running before rendering:
#   docker start open-sql

library(DBI)
library(RPostgres)

options(knitr.kable.NA = "NULL")

# Adjust PGPORT if you mapped the container to an alternate host port (e.g., 5433).
PGPORT <- Sys.getenv("PGPORT", unset = "5432")
PGPASS <- Sys.getenv("PGPASS", unset = "postgres")

con <- dbConnect(
  Postgres(),
  host     = "localhost",
  port     = as.integer(PGPORT),
  dbname   = "postgres",
  user     = "postgres",
  password = PGPASS
)
