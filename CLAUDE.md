# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a [Quarto](https://quarto.org/) book project titled _SQL for Data Science_ or _SQL4DS_ for short. It is a free, open-source educational textbook targeting beginning learners, data analysts, and data scientists who want to learn SQL and relational databases.

## Build Commands

```bash
# Render the full book to _book/
quarto render

# Render and serve locally with live preview
quarto preview

# Render a single chapter
quarto render 01-why-learn-sql.qmd
```

Output is written to `_book/` as a static HTML site.

## Architecture

The book structure is defined in `_quarto.yml`. Adding or reordering chapters requires updating the `chapters:` list there — Quarto uses that order for navigation and numbering.

Each chapter is a `.qmd` (Quarto Markdown) file that can contain:
- Standard Markdown prose
- Executable R or Python code blocks (fenced with ```` ```{r} ```` or ```` ```{python} ````)
- Citations referencing `references.bib` using `[@key]` syntax

Chapter files are numbered by convention (`01-`, `02-`, etc.) and must be listed under their part in `_quarto.yml` to appear in the book.

Chapters and the parts they belong to have a numbering convention that should be followed:
- `index.qmd` is exempt from all of the following rules because it is the homepage.
- All chapters have two-digit numbers. Sections are denoted by the first digit, and chapters are denoted by the second digit. Section "headers" have a second digit of zero, such as `20-design.qmd`, `30-secure.qmd`, etc.
- All chapters under a given section header should use an incremental numbering pattern. For example, with chapters underneath `30-secure.qmd`, they should be numbered as `31-roles.qmd`, `32-privileges.qmd`, etc.
- 0x chapters are introductory in nature.
- 1x chapters are about how to query data from databases, primarily focused on SELECT statements.
- 2x chapters are about analytical query techniques like subqueries, window functions, statistics, etc.
- 3x chapters are about database design, including DDL statements, normalization, etc.
- 4x chapters are about database optimization, including query plans, indexes, and optimization patterns.
- 5x chapters are about database security, including roles and privileges.
- 6x chapters are about ETL with Python (Polars).
- 7x chapters are about deployment and migrations with Supabase.
- 9x chapters are the tail end of the book, where we would include appendices, references, etc.

The numbering convention I just described for the files within this repo is decoupled from the chapter numbering of the final product. That numbering is handled by Quarto itself at the time of rendering. This numbering convention is designed to make the repo easier to navigate when viewing it in GitHub or an IDE like Zed or VS Code.

Section header chapters should have a brief (2-5 paragraph) narrative that recaps what was learned in the previous section, introduces the primary learning objectives for the current section, and discusses how the current section relates to the previous section and the overall topic of using SQL for data science. These chapters should include the `{.unnumbered}` class as part of the main heading at the top of the document so they do not get numbered in the table of contents when the book is rendered.

## Database Connection Pattern

The book executes live SQL against a PostgreSQL 17 Docker container (`pebenbow/open-sql-docker`). The connection is managed via `_common.R`, which must be sourced at the top of every chapter that contains SQL code blocks:

````r
```{r}
#| include: false
source("_common.R")   # opens `con`, a DBI connection to the container
```
````

SQL chunks then reference that connection:

````sql
```{sql}
#| connection: con
SELECT * FROM some_table LIMIT 5;
```
````

The container must be running before `quarto render` or `quarto preview`:

```bash
docker start open-sql
```

If the container has not been created yet, see `02-setup.qmd` for the full `docker run` command. Students who mapped the container to a non-default port set `PGPORT=5433` (or their chosen port) in their environment before rendering.

## Content Conventions

- Avoid em dashes entirely. Use a comma, period, parentheses, or a semicolon depending on the grammatical context. Em dashes read as a hallmark of AI-generated text and should not appear anywhere in the book.
- Prose is written in Quarto Markdown; use `##` for top-level section headings within a chapter (the chapter title uses `#`)
- Code examples should be runnable and demonstrate SQL concepts using PostgreSQL unless otherwise noted
- Bibliography entries go in `references.bib` (BibTeX format); cite with `[@knuth84]`-style keys
- The `index.qmd` serves as the Preface; `intro.qmd` is the Introduction chapter
