# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a [Quarto](https://quarto.org/) book project — "A Data Scientist's Guide to SQL" by Pete Benbow. It is a free, open-source educational textbook targeting beginning learners, data analysts, and data scientists who want to learn SQL and relational databases.

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

The `getting-started.qmd` file is a **part heading** (not a content chapter) — it groups chapters under a section in the TOC.

## Content Conventions

- Prose is written in Quarto Markdown; use `##` for top-level section headings within a chapter (the chapter title uses `#`)
- Code examples should be runnable and demonstrate SQL concepts using PostgreSQL unless otherwise noted
- Bibliography entries go in `references.bib` (BibTeX format); cite with `[@knuth84]`-style keys
- The `index.qmd` serves as the Preface; `intro.qmd` is the Introduction chapter
