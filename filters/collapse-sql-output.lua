--- Wrap paginated SQL/data-frame result tables in a collapsible <details>
--- element. knitr's sql engine (via the sql.print hook set in each chapter's
--- setup chunk) emits the pagedtable widget as a raw <div data-pagedtable="...">,
--- which Quarto's markdown reader parses as a genuine pandoc Div (its
--- "data-pagedtable" attribute survives intact) rather than a raw HTML
--- blob, so detection keys off that Div attribute directly.

function Div(div)
  if div.attributes['data-pagedtable'] == nil then
    return nil
  end

  return {
    pandoc.RawBlock('html', '<details class="sql-output-accordion"><summary>Query Results</summary>'),
    div,
    pandoc.RawBlock('html', '</details>'),
  }
end
