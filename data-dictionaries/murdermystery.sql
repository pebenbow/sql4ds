-- Schema for the murdermystery database (open-sql-docker): tables only, in dependency order.
-- Generated from the live catalog by scripts/build_schema_sql.py; do not edit by hand.

CREATE TABLE crime_scene_report (
    id          serial      PRIMARY KEY,
    date        date,
    type        varchar(20),
    description text,
    city        varchar(20)
);

CREATE TABLE drivers_license (
    id           serial      PRIMARY KEY,
    age          integer,
    height       integer,
    eye_color    varchar(10),
    hair_color   varchar(10),
    gender       varchar(10),
    plate_number varchar(10),
    car_make     varchar(20),
    car_model    varchar(20)
);

CREATE TABLE person (
    id                  serial      PRIMARY KEY,
    name                varchar(50),
    license_id          integer     REFERENCES drivers_license (id),
    address_number      integer,
    address_street_name varchar(50),
    ssn                 integer     UNIQUE
);

CREATE TABLE facebook_event_checkin (
    id         serial       PRIMARY KEY,
    person_id  integer      REFERENCES person (id),
    event_id   integer,
    event_name varchar(100),
    date       date
);

CREATE TABLE get_fit_now_member (
    id                    varchar(10) PRIMARY KEY,
    person_id             integer     REFERENCES person (id),
    name                  varchar(50),
    membership_start_date date,
    membership_status     varchar(10)
);

CREATE TABLE get_fit_now_check_in (
    id             serial      PRIMARY KEY,
    membership_id  varchar(10) REFERENCES get_fit_now_member (id),
    check_in_date  date,
    check_in_time  time,
    check_out_time time
);

CREATE TABLE income (
    ssn           integer PRIMARY KEY REFERENCES person (ssn),
    annual_income integer
);

CREATE TABLE interview (
    person_id  integer PRIMARY KEY REFERENCES person (id),
    transcript text
);
