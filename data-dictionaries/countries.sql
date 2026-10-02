-- Schema for the countries database (open-sql-docker): tables only, in dependency order.
-- Generated from the live catalog by scripts/build_schema_sql.py; do not edit by hand.

CREATE TABLE countries (
    country     varchar(200),
    iso2c       varchar(2),
    iso3c       varchar(3),
    yr          integer,
    population  bigint,
    area        numeric,
    lastupdated date,
    region      varchar(200),
    capital     varchar(200),
    longitude   real,
    latitude    real
);
