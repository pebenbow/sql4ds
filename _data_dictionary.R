# _data_dictionary.R
# Builds a database appendix page from its YAML data dictionary in data-dictionaries/.
# Used by the appendix-*.qmd files:
#
#   ```{r}
#   #| echo: false
#   #| output: asis
#   source("_data_dictionary.R")
#   render_dictionary("nycflights")
#   ```
#
# Page order: summary and source, concepts, ER diagram (all columns / keys only), the data
# dictionary table by table, then links to every chapter that uses the database. Chapters
# are found by scanning the book's .qmd files for a connection to the database (an R
# dbname = "<db>" or a Python postgresql+psycopg2://.../<db> URL); a dictionary's
# extra_chapters adds any others.
# Needs only the yaml package, which knitr and rmarkdown already depend on.

dd_cell <- function(x) {
  # one line, with pipes escaped, so the text fits in a Markdown table cell
  x <- if (is.null(x)) "" else as.character(x)
  x <- gsub("\\s*\n\\s*", " ", trimws(x))
  gsub("|", "\\|", x, fixed = TRUE)
}

dd_svg_desc <- function(path) {
  if (!file.exists(path)) return("")
  svg <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
  m <- regmatches(svg, regexpr('<desc id="desc">[^<]*</desc>', svg))
  if (!length(m)) return("")
  gsub('"', "'", gsub("^<desc id=\"desc\">|</desc>$", "", m))
}

dd_chapters <- function(db, extra = character()) {
  files <- setdiff(list.files(".", pattern = "\\.qmd$"), list.files(".", pattern = "^appendix-.*\\.qmd$"))
  # an R connection (dbname = "db") or a SQLAlchemy URL from Python (postgresql+psycopg2://.../db")
  pattern <- sprintf('dbname\\s*=\\s*"%s"|postgresql[+a-z0-9]*://[^"\' ]*/%s["\']', db, db)
  uses <- Filter(function(f) any(grepl(pattern, readLines(f, warn = FALSE, encoding = "UTF-8"))), files)
  files <- unique(c(uses, unlist(extra)))
  titles <- vapply(files, function(f) {
    lines <- readLines(f, n = 10, warn = FALSE, encoding = "UTF-8")
    t <- grep("^title:", lines, value = TRUE)
    if (length(t)) gsub('^title:\\s*"?|"?\\s*$', "", t[1]) else f
  }, character(1))
  # keep the book's reading order
  book <- readLines("_quarto.yml", warn = FALSE, encoding = "UTF-8")
  pos <- vapply(files, function(f) {
    hit <- grep(paste0("\\b", gsub(".", "\\.", f, fixed = TRUE), "\\b"), book)
    if (length(hit)) hit[1] else Inf
  }, numeric(1))
  data.frame(file = files, title = titles)[order(pos), , drop = FALSE]
}

render_dictionary <- function(db) {
  d <- yaml::read_yaml(file.path("data-dictionaries", paste0(db, ".yml")))
  out <- character()
  add <- function(...) out <<- c(out, ...)

  add(trimws(d$summary), "", trimws(d$source), "")

  add("## Concepts this database illustrates", "")
  for (cpt in d$concepts) add(sprintf("- **%s**: %s", dd_cell(cpt$concept), dd_cell(cpt$example)))
  add("")

  add("## Entity relationship diagram", "")
  add("::: {.panel-tabset}", "")
  for (v in list(c("All columns", ""), c("Keys only", "_keys"))) {
    img <- sprintf("images/er_%s%s.svg", db, v[2])
    if (!file.exists(img)) next
    add(sprintf("### %s", v[1]), "")
    add(sprintf('![](%s){fig-alt="%s" width="100%%"}', img, dd_svg_desc(img)), "")
  }
  add(":::", "")
  add(paste("Underlined columns form each table's primary key. A gold key marks a primary key column,",
            "a green chain link marks a foreign key column, and each line ends in crow's foot notation."), "")

  add("## Data dictionary", "")
  for (t in d$tables) {
    add(sprintf("### `%s` {#sec-%s-%s}", t$name, db, gsub("_", "-", t$name)), "")
    add(trimws(t$description), "")
    # Pandoc sizes the columns of a wide pipe table by the dashes in this separator row
    add("| Column | Type | Key | Nullable | Description |",
        "|--------------|--------------|------------------|--------|------------------------------------------|")
    # same row order as the ER diagrams: primary key columns, then foreign keys, then the rest
    rank <- vapply(t$columns, function(col) {
      k <- if (is.null(col$key)) "" else col$key
      if (grepl("PK", k)) 0 else if (grepl("FK", k)) 1 else 2
    }, numeric(1))
    for (col in t$columns[order(rank)]) {
      key <- if (is.null(col$key)) "" else col$key
      if (!is.null(col$references)) key <- sprintf("%s → `%s`", key, col$references)
      add(sprintf("| `%s` | `%s` | %s | %s | %s |", col$name, col$type, key,
                  if (isTRUE(col$nullable)) "yes" else "no", dd_cell(col$description)))
    }
    add("")
  }

  ch <- dd_chapters(db, d$extra_chapters)
  if (nrow(ch)) {
    add("## Chapters that use this database", "")
    for (i in seq_len(nrow(ch))) add(sprintf("- [%s](%s)", ch$title[i], ch$file[i]))
    add("")
  }
  cat(out, sep = "\n")
}
