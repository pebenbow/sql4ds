-- Schema for the library database (open-sql-docker): tables only, in dependency order.
-- Generated from the live catalog by scripts/build_schema_sql.py; do not edit by hand.

CREATE TABLE authors (
    author_id  integer  PRIMARY KEY,
    full_name  text     NOT NULL,
    birth_year smallint
);

CREATE TABLE publishers (
    publisher_id integer PRIMARY KEY,
    name         text    NOT NULL UNIQUE
);

CREATE TABLE books (
    book_id          integer  PRIMARY KEY,
    isbn13           text     NOT NULL UNIQUE,
    title            text     NOT NULL,
    publisher_id     integer  REFERENCES publishers (publisher_id),
    publication_year smallint,
    page_count       smallint,
    language         text     NOT NULL DEFAULT 'eng',
    format           text     NOT NULL CHECK (format IN ('Hardcover', 'Paperback', 'eBook', 'Audiobook'))
);

CREATE TABLE book_authors (
    book_id      integer  REFERENCES books (book_id),
    author_id    integer  REFERENCES authors (author_id),
    author_order smallint NOT NULL,
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE genres (
    genre_id integer PRIMARY KEY,
    name     text    NOT NULL UNIQUE
);

CREATE TABLE book_genres (
    book_id  integer REFERENCES books (book_id),
    genre_id integer REFERENCES genres (genre_id),
    PRIMARY KEY (book_id, genre_id)
);

CREATE TABLE patrons (
    patron_id             integer PRIMARY KEY,
    first_name            text    NOT NULL,
    last_name             text    NOT NULL,
    email                 text    NOT NULL UNIQUE,
    phone                 text,
    address               text,
    city                  text,
    state                 text,
    zip_code              text,
    membership_type       text    NOT NULL CHECK (membership_type IN ('Adult', 'Student', 'Senior', 'Child')),
    membership_start_date date    NOT NULL
);

CREATE TABLE catalog_searches (
    search_id   integer     PRIMARY KEY,
    searched_at timestamptz NOT NULL,
    patron_id   integer     REFERENCES patrons (patron_id),
    query_text  text        NOT NULL
);

CREATE TABLE staff (
    staff_id   integer PRIMARY KEY,
    first_name text    NOT NULL,
    last_name  text    NOT NULL,
    role       text    NOT NULL CHECK (role IN ('Librarian', 'Circulation Clerk', 'Library Director')),
    hire_date  date    NOT NULL
);

CREATE TABLE copies (
    copy_id          integer PRIMARY KEY,
    book_id          integer NOT NULL REFERENCES books (book_id),
    barcode          text    NOT NULL UNIQUE,
    acquisition_date date    NOT NULL,
    condition        text    NOT NULL CHECK (condition IN ('New', 'Good', 'Fair', 'Poor')),
    status           text    NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Lost', 'Withdrawn'))
);

CREATE TABLE checkouts (
    checkout_id       integer PRIMARY KEY,
    copy_id           integer NOT NULL REFERENCES copies (copy_id),
    patron_id         integer NOT NULL REFERENCES patrons (patron_id),
    checkout_staff_id integer NOT NULL REFERENCES staff (staff_id),
    checkout_date     date    NOT NULL,
    due_date          date    NOT NULL,
    return_date       date,
    return_staff_id   integer REFERENCES staff (staff_id),
    CHECK (due_date >= checkout_date),
    CHECK ((return_date IS NULL) OR (return_date >= checkout_date))
);

CREATE TABLE circulation_scans (
    scan_id     integer     PRIMARY KEY,
    checkout_id integer     NOT NULL REFERENCES checkouts (checkout_id),
    scan_type   text        NOT NULL CHECK (scan_type IN ('checkout', 'return')),
    scanned_at  timestamptz NOT NULL,
    staff_id    integer     NOT NULL REFERENCES staff (staff_id),
    UNIQUE (checkout_id, scan_type)
);

CREATE TABLE fines (
    fine_id            integer      PRIMARY KEY,
    checkout_id        integer      NOT NULL UNIQUE REFERENCES checkouts (checkout_id),
    amount_assessed    numeric(6,2) NOT NULL CHECK (amount_assessed > 0),
    amount_paid        numeric(6,2) NOT NULL DEFAULT 0,
    status             text         NOT NULL DEFAULT 'Outstanding' CHECK (status IN ('Outstanding', 'Paid', 'Waived')),
    assessed_date      date         NOT NULL,
    paid_date          date,
    waived_by_staff_id integer      REFERENCES staff (staff_id),
    waived_date        date,
    CHECK ((amount_paid >= 0) AND (amount_paid <= amount_assessed))
);

CREATE TABLE legacy_checkouts (
    legacy_id   text,
    barcode     text,
    patron_id   text,
    checked_out text,
    due_back    text,
    returned    text
);

CREATE TABLE study_rooms (
    room_id     integer PRIMARY KEY,
    room_name   text    NOT NULL UNIQUE,
    capacity    integer NOT NULL CHECK (capacity > 0),
    has_display boolean NOT NULL DEFAULT false
);

CREATE TABLE room_reservations (
    reservation_id integer     PRIMARY KEY,
    room_id        integer     NOT NULL REFERENCES study_rooms (room_id),
    patron_id      integer     NOT NULL REFERENCES patrons (patron_id),
    booked_at      timestamptz NOT NULL,
    start_time     timestamp   NOT NULL,
    end_time       timestamp   NOT NULL,
    status         text        NOT NULL CHECK (status IN ('Completed', 'Cancelled', 'No-show')),
    CHECK (end_time > start_time)
);

CREATE TABLE signup_submissions (
    submission_id  integer     PRIMARY KEY,
    submitted_at   timestamptz NOT NULL,
    full_name      text        NOT NULL,
    email          text        NOT NULL,
    phone          text,
    street_address text,
    city_state_zip text,
    patron_id      integer     UNIQUE REFERENCES patrons (patron_id)
);
