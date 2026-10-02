-- Schema for the northwind database (open-sql-docker): tables only, in dependency order.
-- Generated from the live catalog by scripts/build_schema_sql.py; do not edit by hand.

CREATE TABLE categories (
    category_id   integer     PRIMARY KEY,
    category_name varchar(15),
    description   text,
    picture       bytea
);

CREATE TABLE customers (
    customer_id   varchar(5)  PRIMARY KEY,
    company_name  varchar(40),
    contact_name  varchar(30),
    contact_title varchar(30),
    address       varchar(60),
    city          varchar(15),
    region        varchar(15),
    postal_code   varchar(10),
    country       varchar(15),
    phone         varchar(24),
    fax           varchar(24)
);

CREATE TABLE customer_demographics (
    customer_type_id varchar(5) PRIMARY KEY,
    customer_desc    text
);

CREATE TABLE customer_customer_demo (
    customer_id      varchar(5) REFERENCES customers (customer_id),
    customer_type_id varchar(5) REFERENCES customer_demographics (customer_type_id),
    PRIMARY KEY (customer_id, customer_type_id)
);

CREATE TABLE employees (
    employee_id       integer      PRIMARY KEY,
    last_name         varchar(20),
    first_name        varchar(10),
    title             varchar(30),
    title_of_courtesy varchar(25),
    birth_date        date,
    hire_date         date,
    address           varchar(60),
    city              varchar(15),
    region            varchar(15),
    postal_code       varchar(10),
    country           varchar(15),
    home_phone        varchar(24),
    extension         varchar(4),
    photo             bytea,
    notes             text,
    reports_to        integer      REFERENCES employees (employee_id),
    photo_path        varchar(255)
);

CREATE TABLE region (
    region_id          integer     PRIMARY KEY,
    region_description varchar(60)
);

CREATE TABLE territories (
    territory_id          varchar(20) PRIMARY KEY,
    territory_description varchar(60),
    region_id             integer     REFERENCES region (region_id)
);

CREATE TABLE employee_territories (
    employee_id  integer     REFERENCES employees (employee_id),
    territory_id varchar(20) REFERENCES territories (territory_id),
    PRIMARY KEY (employee_id, territory_id)
);

CREATE TABLE shippers (
    shipper_id   integer     PRIMARY KEY,
    company_name varchar(40),
    phone        varchar(24)
);

CREATE TABLE orders (
    order_id         integer       PRIMARY KEY,
    customer_id      varchar(5)    REFERENCES customers (customer_id),
    employee_id      integer       REFERENCES employees (employee_id),
    order_date       date,
    required_date    date,
    shipped_date     date,
    ship_via         integer       REFERENCES shippers (shipper_id),
    freight          numeric(10,2),
    ship_name        varchar(40),
    ship_address     varchar(60),
    ship_city        varchar(15),
    ship_region      varchar(15),
    ship_postal_code varchar(10),
    ship_country     varchar(15)
);

CREATE TABLE suppliers (
    supplier_id   integer     PRIMARY KEY,
    company_name  varchar(40),
    contact_name  varchar(30),
    contact_title varchar(30),
    address       varchar(60),
    city          varchar(15),
    region        varchar(15),
    postal_code   varchar(10),
    country       varchar(15),
    phone         varchar(24),
    fax           varchar(24),
    homepage      text
);

CREATE TABLE products (
    product_id        integer       PRIMARY KEY,
    product_name      varchar(40),
    supplier_id       integer       REFERENCES suppliers (supplier_id),
    category_id       integer       REFERENCES categories (category_id),
    quantity_per_unit varchar(20),
    unit_price        numeric(10,2),
    units_in_stock    integer,
    units_on_order    integer,
    reorder_level     integer,
    discontinued      integer
);

CREATE TABLE order_details (
    order_id   integer      REFERENCES orders (order_id),
    product_id integer      REFERENCES products (product_id),
    unit_price numeric(9,2),
    quantity   integer,
    discount   numeric(5,2),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE us_states (
    state_id     integer      PRIMARY KEY,
    state_name   varchar(100),
    state_abbr   varchar(2),
    state_region varchar(50)
);
