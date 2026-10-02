"""Create or refresh the YAML data dictionaries in data-dictionaries/.

Each database's dictionary mixes two kinds of fields:

- Generated from the schema: every table and column, plus each column's type, key role,
  nullability, and the column it references. These come from the DBML files in
  open-sql-docker/dbml/, which that repo's scripts/generate_dbml.py builds from a live
  PostgreSQL instance.
- Hand-written: the database summary, its source, the concepts it illustrates, and the
  description of every table and column.

Re-running this script after a schema change updates the generated fields and keeps every
hand-written field. New tables and columns get a "TODO" description; tables or columns
that no longer exist in the schema are dropped (and reported).

Run from the book's root:  python scripts/build_data_dictionaries.py [db ...]
Set OPEN_SQL_DOCKER to point somewhere other than ../open-sql-docker.
"""

import os
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data-dictionaries"
DBML_DIR = Path(os.environ.get("OPEN_SQL_DOCKER", ROOT.parent / "open-sql-docker")) / "dbml"

DATABASES = ["nycflights", "worldbank", "actors", "countries", "murdermystery", "library", "northwind"]
# Tables left out on purpose (the same ones the ER diagrams leave out)
EXCLUDE = {"worldbank": {"countries_etl", "indicators_etl", "countries_etl_staging"}}
TODO = "TODO"


def short_type(t):
    t = t.strip('"')
    return {"timestamp without time zone": "timestamp", "timestamp with time zone": "timestamptz",
            "time without time zone": "time"}.get(t, t)


def parse_dbml(path):
    """Tables (name -> {cols: [(name, type)], pk, unique, notnull}) and refs, from generate_dbml.py output."""
    tables, refs, cur, in_indexes = {}, [], None, False
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("//"):
            continue
        if m := re.match(r"Table (\w+) \{", line):
            cur = {"cols": [], "pk": set(), "unique": set(), "notnull": set()}
            tables[m.group(1)] = cur
        elif line.startswith("Indexes {"):
            in_indexes = True
        elif line == "}":
            if in_indexes:
                in_indexes = False
            else:
                cur = None
        elif in_indexes and (m := re.match(r"\(([^)]*)\) \[([^\]]*)\]", line)):
            if "pk" in m.group(2):
                cur["pk"].update(c.strip() for c in m.group(1).split(","))
        elif cur is not None and (m := re.match(r'(\w+) ("[^"]+"|\S+)(?: \[([^\]]*)\])?', line)):
            name, typ, attrs = m.group(1), short_type(m.group(2)), m.group(3) or ""
            cur["cols"].append((name, typ))
            flags = {a.strip().split(":")[0] for a in attrs.split(",")}
            if "pk" in flags:
                cur["pk"].add(name)
            if "unique" in flags:
                cur["unique"].add(name)
            if "not null" in flags or "pk" in flags:
                cur["notnull"].add(name)
        elif m := re.match(r"Ref: (\w+)\.(\w+) > (\w+)\.(\w+)", line):
            refs.append(m.groups())
    return tables, refs


class Block(str):
    """A string written as a YAML literal block (|), for readable multi-line prose."""


yaml.SafeDumper.add_representer(
    Block, lambda d, s: d.represent_scalar("tag:yaml.org,2002:str", s, style="|"))


def block(s):
    s = (s or TODO).strip()
    return Block(s + "\n") if "\n" in s else s


def build(db):
    tables, refs = parse_dbml(DBML_DIR / f"{db}.dbml")
    skip = EXCLUDE.get(db, set())
    tables = {n: t for n, t in tables.items() if n not in skip}
    fk = {(ct, cc): f"{pt}.{pc}" for ct, cc, pt, pc in refs if ct not in skip and pt not in skip}

    path = OUT / f"{db}.yml"
    old = yaml.safe_load(path.read_text(encoding="utf-8")) if path.exists() else {}
    old_tables = {t["name"]: t for t in old.get("tables", [])}
    # keep the hand-chosen table order; new tables go at the end in schema order
    order = [n for n in old_tables if n in tables] + [n for n in tables if n not in old_tables]
    for gone in set(old_tables) - set(tables):
        print(f"  {db}: table {gone} is no longer in the schema; dropped")

    out_tables = []
    for name in order:
        t, prev = tables[name], old_tables.get(name, {})
        prev_cols = {c["name"]: c for c in prev.get("columns", [])}
        for gone in set(prev_cols) - {c for c, _ in t["cols"]}:
            print(f"  {db}: column {name}.{gone} is no longer in the schema; dropped")
        cols = []
        for col, typ in t["cols"]:
            roles = [r for r, on in (("PK", col in t["pk"]), ("FK", (name, col) in fk),
                                     ("UQ", col in t["unique"] and col not in t["pk"])) if on]
            entry = {"name": col, "type": typ}
            if roles:
                entry["key"] = ", ".join(roles)
            entry["nullable"] = col not in t["notnull"]
            if (name, col) in fk:
                entry["references"] = fk[(name, col)]
            entry["description"] = block(prev_cols.get(col, {}).get("description"))
            cols.append(entry)
        out_tables.append({"name": name, "description": block(prev.get("description")), "columns": cols})

    doc = {
        "database": db,
        "summary": block(old.get("summary")),
        "source": block(old.get("source")),
        "concepts": [{"concept": c.get("concept", TODO), "example": block(c.get("example"))}
                     for c in old.get("concepts") or [{}]],
        "extra_chapters": old.get("extra_chapters") or [],
        "tables": out_tables,
    }
    header = (
        f"# Data dictionary for the {db} database (open-sql-docker).\n"
        "# Generated by scripts/build_data_dictionaries.py: tables, columns, type, key, nullable,\n"
        "# and references come from the schema; re-run the script after a schema change.\n"
        "# Hand-written: summary, source, concepts, extra_chapters, and every description.\n"
        "# extra_chapters lists .qmd files to back-link beyond those that connect to this\n"
        "# database (which are found automatically).\n"
    )
    OUT.mkdir(exist_ok=True)
    body = yaml.safe_dump(doc, sort_keys=False, allow_unicode=True, width=10000)
    path.write_text(header + body, encoding="utf-8", newline="\n")
    todo = body.count(TODO)
    print(f"wrote {path.relative_to(ROOT)} ({len(out_tables)} tables, {todo} TODO)")


if __name__ == "__main__":
    for db in sys.argv[1:] or DATABASES:
        build(db)
