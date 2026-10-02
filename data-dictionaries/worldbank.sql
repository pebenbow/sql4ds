-- Schema for the worldbank database (open-sql-docker): tables only, in dependency order.
-- Generated from the live catalog by scripts/build_schema_sql.py; do not edit by hand.

CREATE TABLE income_groups (
    income_group_id smallint    PRIMARY KEY,
    name            varchar(50) NOT NULL UNIQUE
);

CREATE TABLE lending_types (
    lending_type_id smallint    PRIMARY KEY,
    name            varchar(50) NOT NULL UNIQUE
);

CREATE TABLE regions (
    region_id smallint     PRIMARY KEY,
    name      varchar(100) NOT NULL UNIQUE
);

CREATE TABLE countries (
    id              integer          PRIMARY KEY,
    country_code    varchar(3)       NOT NULL UNIQUE,
    iso2_code       varchar(2),
    short_name      varchar(100),
    region_id       smallint         REFERENCES regions (region_id),
    capital         varchar(100),
    longitude       double precision,
    latitude        double precision,
    income_group_id smallint         REFERENCES income_groups (income_group_id),
    lending_type_id smallint         REFERENCES lending_types (lending_type_id),
    is_aggregate    boolean          NOT NULL DEFAULT false
);

CREATE TABLE indicators (
    id                    integer,
    country_id            integer          REFERENCES countries (id),
    year                  integer,
    pct_agricultural_land double precision,
    pct_arable_land       double precision,
    pct_forest_area       double precision,
    rural_land_area_km2   double precision,
    urban_land_area_km2   double precision,
    land_area_km2         double precision,
    population            bigint,
    gdp_usd               double precision,
    gdp_per_capita_usd    double precision,
    PRIMARY KEY (country_id, year)
);

CREATE TABLE series (
    id             integer      PRIMARY KEY,
    indicator_code varchar(20)  NOT NULL UNIQUE,
    indicator_name varchar(200),
    description    text,
    source         varchar(100),
    source_org     text
);
