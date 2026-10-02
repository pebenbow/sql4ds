"""Write data-dictionaries/<db>.sql: tidy CREATE TABLE statements for each database appendix.

The statements are generated from a live open-sql-docker instance's catalog, so they always
match the loaded schema (and the data dictionaries, which come from the same schema). They
are cleaned up for reading rather than copied from pg_dump:

- one CREATE TABLE per table, in dependency order, so the file runs as written
- single-column PRIMARY KEY, UNIQUE, REFERENCES, and CHECK constraints sit on their column;
  multi-column ones go at the end of the table
- integer columns backed by their own sequence are written as serial
- PostgreSQL's normalized expressions are rewritten in the usual form, e.g.
  format = ANY (ARRAY['Hardcover'::text, ...]) becomes format IN ('Hardcover', ...)
- types use their short names (varchar, timestamp, timestamptz)

The appendix pages (_data_dictionary.R) show each table's statement under its data
dictionary and link the whole file for download.

Run from the book's root, with the open-sql-docker container running:
    PGPORT=5499 python scripts/build_schema_sql.py [db ...]
PGHOST, PGPORT, PGUSER, and PGPASSWORD default to localhost, 5432, postgres, postgres.
"""

import os
import re
import sys
from pathlib import Path

import psycopg2

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data-dictionaries"
DATABASES = ["nycflights", "worldbank", "actors", "countries", "murdermystery", "library", "northwind"]
# The same tables the dictionaries and ER diagrams leave out
EXCLUDE = {"worldbank": {"countries_etl", "indicators_etl", "countries_etl_staging"}}

SHORT_TYPES = [("character varying", "varchar"), ("timestamp without time zone", "timestamp"),
               ("timestamp with time zone", "timestamptz"), ("time without time zone", "time"),
               ("character(", "char(")]


def connect(db):
    return psycopg2.connect(host=os.environ.get("PGHOST", "localhost"), port=int(os.environ.get("PGPORT", "5432")),
                            user=os.environ.get("PGUSER", "postgres"),
                            password=os.environ.get("PGPASSWORD", "postgres"), dbname=db)


def short_type(t):
    for long, short in SHORT_TYPES:
        t = t.replace(long, short)
    return t


def tidy_expr(e):
    """Rewrite PostgreSQL's normalized expression text in the form people usually write."""
    # x = ANY (ARRAY['a'::text, 'b'::text])  ->  x IN ('a', 'b')
    e = re.sub(r"\b([\w.]+) = ANY \(ARRAY\[([^\]]*)\]\)", r"\1 IN (\2)", e)
    e = re.sub(r"('(?:[^']|'')*')::(?:text|bpchar|character varying|varchar)", r"\1", e)  # 'x'::text -> 'x'
    e = re.sub(r"\((-?\d+(?:\.\d+)?)\)::numeric", r"\1", e)  # (0)::numeric -> 0
    return e


def strip_outer_parens(e):
    e = e.strip()
    while e.startswith("(") and e.endswith(")"):
        depth = 0
        for i, ch in enumerate(e):
            depth += ch == "("
            depth -= ch == ")"
            if depth == 0 and i < len(e) - 1:
                return e  # the first "(" closes before the end: not a wrapping pair
        e = e[1:-1].strip()
    return e


def table_ddl(cur, table):
    cur.execute("""
        SELECT a.attname, format_type(a.atttypid, a.atttypmod), a.attnotnull,
               pg_get_expr(d.adbin, d.adrelid), pg_get_serial_sequence(%s, a.attname)
        FROM pg_attribute a
        LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
        WHERE a.attrelid = %s::regclass AND a.attnum > 0 AND NOT a.attisdropped
        ORDER BY a.attnum""", (table, table))
    cols = cur.fetchall()
    cur.execute("""
        SELECT con.contype, pg_get_constraintdef(con.oid),
               ARRAY(SELECT att.attname FROM unnest(con.conkey) k JOIN pg_attribute att
                     ON att.attrelid = con.conrelid AND att.attnum = k)
        FROM pg_constraint con
        WHERE con.conrelid = %s::regclass AND con.contype IN ('p', 'u', 'f', 'c')
        ORDER BY CASE con.contype WHEN 'p' THEN 0 WHEN 'u' THEN 1 WHEN 'f' THEN 2 ELSE 3 END, con.conname""",
                (table,))
    cons = cur.fetchall()

    inline = {c[0]: [] for c in cols}
    table_level = []
    pk_cols = set()
    for contype, definition, keycols in cons:
        if contype == "p":
            pk_cols = set(keycols)
        if contype == "c":
            clause = "CHECK (" + tidy_expr(strip_outer_parens(definition[len("CHECK "):])) + ")"
        elif contype == "f":
            m = re.match(r"FOREIGN KEY \(([^)]*)\) REFERENCES (?:public\.)?(\w+)\(([^)]*)\)(.*)", definition)
            clause = f"REFERENCES {m.group(2)} ({m.group(3)}){m.group(4)}"
            if len(keycols) > 1:
                clause = f"FOREIGN KEY ({m.group(1)}) " + clause
        else:
            clause = definition.split(" (")[0]  # PRIMARY KEY or UNIQUE
            if len(keycols) > 1:
                clause = definition
        if len(keycols) == 1 and contype != "c" or contype == "c" and len(keycols) == 1:
            inline[keycols[0]].append(clause)
        else:
            table_level.append(clause)

    lines = []
    name_w = max(len(c[0]) for c in cols)
    type_of = {}
    for name, typ, notnull, default, seq in cols:
        typ = short_type(typ)
        if seq and default and default.startswith("nextval("):
            typ, default = {"integer": "serial", "bigint": "bigserial", "smallint": "smallserial"}.get(typ, typ), None
        type_of[name] = typ
    type_w = max(len(t) for t in type_of.values())
    for name, typ, notnull, default, seq in cols:
        parts = [f"{name:<{name_w}}", f"{type_of[name]:<{type_w}}"]
        extra = []
        if notnull and name not in pk_cols:
            extra.append("NOT NULL")
        if default and not (seq and default.startswith("nextval(")):
            extra.append(f"DEFAULT {tidy_expr(default)}")
        extra += inline[name]
        lines.append("    " + " ".join(parts + extra).rstrip())
    lines += [f"    {c}" for c in table_level]
    body = ",\n".join(lines)
    deps = []
    for contype, definition, _ in cons:
        if contype == "f":
            parent = re.search(r"REFERENCES (?:public\.)?(\w+)\(", definition).group(1)
            if parent != table:
                deps.append(parent)
    return f"CREATE TABLE {table} (\n{body}\n);", deps


def build(db):
    con = connect(db)
    cur = con.cursor()
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' "
                "AND table_type = 'BASE TABLE' ORDER BY table_name")
    tables = [t for (t,) in cur.fetchall() if t not in EXCLUDE.get(db, set())]
    ddl, deps = {}, {}
    for t in tables:
        ddl[t], deps[t] = table_ddl(cur, t)
    con.close()

    # dependency order: a table comes after every table it references
    ordered, done = [], set()

    def visit(t, path=()):
        if t in done or t not in ddl:
            return
        if t in path:
            raise SystemExit(f"{db}: circular foreign keys through {t}")
        for d in deps[t]:
            visit(d, path + (t,))
        done.add(t)
        ordered.append(t)

    for t in tables:
        visit(t)

    header = (f"-- Schema for the {db} database (open-sql-docker): tables only, in dependency order.\n"
              "-- Generated from the live catalog by scripts/build_schema_sql.py; do not edit by hand.\n")
    text = header + "\n" + "\n\n".join(ddl[t] for t in ordered) + "\n"
    OUT.mkdir(exist_ok=True)
    (OUT / f"{db}.sql").write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote data-dictionaries/{db}.sql ({len(ordered)} tables)")


if __name__ == "__main__":
    for db in sys.argv[1:] or DATABASES:
        build(db)
