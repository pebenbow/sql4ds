-- Schema for the actors database (open-sql-docker): tables only, in dependency order.
-- Generated from the live catalog by scripts/build_schema_sql.py; do not edit by hand.

CREATE TABLE actors (
    actor_id             integer       PRIMARY KEY,
    first_name           varchar(50)   NOT NULL,
    last_name            varchar(50)   NOT NULL,
    birth_name           varchar(100),
    sex                  char(1)       NOT NULL CHECK (sex IN ('M', 'F')),
    birth_date           date          NOT NULL,
    death_date           date,
    birth_country        varchar(50)   NOT NULL,
    height_cm            smallint,
    oscar_nominations    smallint      NOT NULL DEFAULT 0,
    oscar_wins           smallint      NOT NULL DEFAULT 0,
    primary_genre        varchar(20)   NOT NULL,
    has_honorary_oscar   boolean       NOT NULL DEFAULT false,
    notable_role         text,
    total_box_office_usd numeric(12,0),
    CHECK (oscar_wins <= oscar_nominations)
);
