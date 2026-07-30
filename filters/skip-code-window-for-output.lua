--- Opt cell output blocks out of the code-window extension's window chrome.
--- Quarto wraps executed-cell output (stdout, stderr, errors) in a Div
--- carrying the "cell-output" class before pandoc ever sees the document, so
--- this runs ahead of code-window (registered later in the pre-quarto chain)
--- and marks any CodeBlock nested inside such a Div as code-window-enabled:
--- false, so only genuine source code gets the traffic-light window frame.

function Div(div)
  local is_output = false
  for _, class in ipairs(div.classes) do
    if class == 'cell-output' then
      is_output = true
      break
    end
  end

  if not is_output then
    return nil
  end

  return div:walk({
    CodeBlock = function(block)
      block.attributes['code-window-enabled'] = 'false'
      return block
    end
  })
end
