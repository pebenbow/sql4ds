-- Schema for the nycflights database (open-sql-docker): tables only, in dependency order.
-- Generated from the live catalog by scripts/build_schema_sql.py; do not edit by hand.

CREATE TABLE airlines (
    carrier varchar(2)   PRIMARY KEY,
    name    varchar(100)
);

CREATE TABLE airports (
    faa   varchar(3)       PRIMARY KEY,
    name  varchar(200),
    lat   double precision,
    lon   double precision,
    alt   integer,
    tz    integer,
    dst   varchar(1),
    tzone varchar(50)
);

CREATE TABLE planes (
    tailnum      varchar(10)  PRIMARY KEY,
    year         integer,
    type         varchar(50),
    manufacturer varchar(100),
    model        varchar(100),
    engines      integer,
    seats        integer,
    speed        integer,
    engine       varchar(50)
);

CREATE TABLE flights (
    year           integer,
    month          integer,
    day            integer,
    dep_time       integer,
    sched_dep_time integer,
    dep_delay      integer,
    arr_time       integer,
    sched_arr_time integer,
    arr_delay      integer,
    carrier        varchar(2)  REFERENCES airlines (carrier),
    flight         integer,
    tailnum        varchar(10) REFERENCES planes (tailnum),
    origin         varchar(3)  REFERENCES airports (faa),
    dest           varchar(3)  REFERENCES airports (faa),
    air_time       integer,
    distance       integer,
    hour           integer,
    minute         integer,
    time_hour      timestamp,
    PRIMARY KEY (year, month, day, carrier, flight, origin)
);

CREATE TABLE weather (
    origin     varchar(3)       REFERENCES airports (faa),
    year       integer,
    month      integer,
    day        integer,
    hour       integer,
    temp       double precision,
    dewp       double precision,
    humid      double precision,
    wind_dir   integer,
    wind_speed double precision,
    wind_gust  double precision,
    precip     double precision,
    pressure   double precision,
    visib      double precision,
    time_hour  timestamp,
    PRIMARY KEY (origin, time_hour)
);
