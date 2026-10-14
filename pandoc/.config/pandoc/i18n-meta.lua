-- Flatten multilingual metadata maps (e.g. title: {fr-CA: ..., en-CA: ...})
-- to a single language, so pandoc templates don't render them as "true".
local LANGS = {"fr-CA", "en-CA"}

local function flatten(m)
  for _, k in ipairs({"title", "subtitle", "description"}) do
    local v = m[k]
    if type(v) == "table" and v.t == nil then
      for _, lang in ipairs(LANGS) do
        if v[lang] then
          m[k] = v[lang]
          break
        end
      end
    end
  end
end

function Pandoc(doc)
  local m = doc.meta
  flatten(m)
  -- If the body already starts with an H1, keep the metadata title for the
  -- browser tab only, to avoid rendering two titles.
  local first = doc.blocks[1]
  if m.title and first and first.t == "Header" and first.level == 1 then
    m.pagetitle = m.pagetitle or m.title
    m.title = nil
  end
  doc.meta = m
  return doc
end
