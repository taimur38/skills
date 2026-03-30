-- growthlabbify.lua
--
-- Features:
--   1. Figure titles placed above images with "Figure Title" style
--   2. Consecutive images (2–3) rendered side-by-side in a borderless table
--   3. "Source:" paragraphs after figures styled as "Figure Source"
--   4. Title + image + source kept together via keepNext styles
--   5. Fenced-div boxes (class "box") → single-cell bordered/shaded tables
--   6. Citeproc bibliography gets a "References" H1 heading

-- Page content width in inches (12240 - 2×1296 DXA) / 1440
local CONTENT_WIDTH_IN = 6.7

--------------------------------------------------------------------------------
-- XML helpers for raw OpenXML output (used by box builder)
--------------------------------------------------------------------------------

local function esc(s)
  return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

-- Convert pandoc inlines to OpenXML w:r elements.
-- `rpr` accumulates nested run properties (bold, italic, etc.)
local function inlines_to_ooxml(inlines, rpr)
  rpr = rpr or ""
  local buf = {}
  for _, il in ipairs(inlines) do
    if il.t == "Str" then
      local rpr_xml = rpr ~= "" and ("<w:rPr>" .. rpr .. "</w:rPr>") or ""
      buf[#buf+1] = "<w:r>" .. rpr_xml
        .. '<w:t xml:space="preserve">' .. esc(il.text) .. "</w:t></w:r>"
    elseif il.t == "Space" or il.t == "SoftBreak" then
      buf[#buf+1] = '<w:r><w:t xml:space="preserve"> </w:t></w:r>'
    elseif il.t == "LineBreak" then
      buf[#buf+1] = "<w:r><w:br/></w:r>"
    elseif il.t == "Strong" then
      buf[#buf+1] = inlines_to_ooxml(il.content, rpr .. "<w:b/>")
    elseif il.t == "Emph" then
      buf[#buf+1] = inlines_to_ooxml(il.content, rpr .. "<w:i/>")
    elseif il.t == "Code" then
      local code_rpr = rpr .. '<w:rFonts w:ascii="Courier New" w:hAnsi="Courier New"/>'
      buf[#buf+1] = "<w:r><w:rPr>" .. code_rpr .. "</w:rPr>"
        .. '<w:t xml:space="preserve">' .. esc(il.text) .. "</w:t></w:r>"
    elseif il.t == "Superscript" then
      buf[#buf+1] = inlines_to_ooxml(il.content, rpr .. '<w:vertAlign w:val="superscript"/>')
    elseif il.t == "Subscript" then
      buf[#buf+1] = inlines_to_ooxml(il.content, rpr .. '<w:vertAlign w:val="subscript"/>')
    end
    -- Other inline types are silently dropped (images, notes, etc.)
  end
  return table.concat(buf)
end

-- Convert a single pandoc Block to OpenXML paragraph(s)
local function block_to_ooxml(block)
  if block.t == "Para" or block.t == "Plain" then
    return "<w:p>" .. inlines_to_ooxml(block.content) .. "</w:p>"
  elseif block.t == "BulletList" then
    local buf = {}
    for _, item in ipairs(block.content) do
      for _, b in ipairs(item) do
        if b.t == "Para" or b.t == "Plain" then
          buf[#buf+1] = '<w:p><w:pPr><w:pStyle w:val="ListBullet"/></w:pPr>'
            .. inlines_to_ooxml(b.content) .. "</w:p>"
        end
      end
    end
    return table.concat(buf)
  elseif block.t == "OrderedList" then
    local buf = {}
    for _, item in ipairs(block.content) do
      for _, b in ipairs(item) do
        if b.t == "Para" or b.t == "Plain" then
          buf[#buf+1] = '<w:p><w:pPr><w:pStyle w:val="ListNumber"/></w:pPr>'
            .. inlines_to_ooxml(b.content) .. "</w:p>"
        end
      end
    end
    return table.concat(buf)
  elseif block.t == "BlockQuote" then
    local buf = {}
    for _, b in ipairs(block.content) do
      buf[#buf+1] = block_to_ooxml(b)
    end
    return table.concat(buf)
  end
  return ""
end

-- Build a box: single-cell table with border, shading, and optional title
local function make_box(title, blocks)
  local buf = {}
  buf[#buf+1] = "<w:tbl>"
  buf[#buf+1] = "<w:tblPr>"
  buf[#buf+1] = '<w:tblW w:w="5000" w:type="pct"/>'
  buf[#buf+1] = "<w:tblBorders>"
  buf[#buf+1] = '<w:top w:val="single" w:sz="6" w:space="0" w:color="808080"/>'
  buf[#buf+1] = '<w:left w:val="single" w:sz="6" w:space="0" w:color="808080"/>'
  buf[#buf+1] = '<w:bottom w:val="single" w:sz="6" w:space="0" w:color="808080"/>'
  buf[#buf+1] = '<w:right w:val="single" w:sz="6" w:space="0" w:color="808080"/>'
  buf[#buf+1] = "</w:tblBorders>"
  buf[#buf+1] = "<w:tblCellMar>"
  buf[#buf+1] = '<w:top w:w="120" w:type="dxa"/>'
  buf[#buf+1] = '<w:left w:w="180" w:type="dxa"/>'
  buf[#buf+1] = '<w:bottom w:w="120" w:type="dxa"/>'
  buf[#buf+1] = '<w:right w:w="180" w:type="dxa"/>'
  buf[#buf+1] = "</w:tblCellMar>"
  buf[#buf+1] = "</w:tblPr>"
  buf[#buf+1] = '<w:tblGrid><w:gridCol w:w="9576"/></w:tblGrid>'
  buf[#buf+1] = "<w:tr><w:tc>"
  buf[#buf+1] = '<w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="F2F2F2"/></w:tcPr>'

  -- Title paragraph (bold)
  if title then
    buf[#buf+1] = "<w:p><w:pPr><w:spacing w:after=\"120\"/></w:pPr>"
      .. '<w:r><w:rPr><w:b/></w:rPr>'
      .. '<w:t xml:space="preserve">' .. esc(title) .. "</w:t></w:r></w:p>"
  end

  -- Content
  for _, block in ipairs(blocks) do
    local xml = block_to_ooxml(block)
    if xml ~= "" then buf[#buf+1] = xml end
  end

  buf[#buf+1] = "</w:tc></w:tr></w:tbl>"
  return pandoc.RawBlock("openxml", table.concat(buf, "\n"))
end

--------------------------------------------------------------------------------
-- Figure helpers
--------------------------------------------------------------------------------

local function is_figure(block)
  return block.t == "Figure"
end

-- A paragraph that contains only images (and whitespace)
local function is_image_para(block)
  if block.t ~= "Para" and block.t ~= "Plain" then return false end
  local has_image = false
  for _, il in ipairs(block.content) do
    if il.t == "Image" then
      has_image = true
    elseif il.t ~= "Space" and il.t ~= "SoftBreak" and il.t ~= "LineBreak" then
      return false
    end
  end
  return has_image
end

local function is_figure_block(block)
  return is_figure(block) or is_image_para(block)
end

local function is_source_para(block)
  if block.t ~= "Para" then return false end
  local text = pandoc.utils.stringify(block)
  return text:match("^%s*[Ss]ources?%s*:")
end

-- Extract caption inlines from a Figure element
local function get_caption_inlines(fig)
  if fig.t ~= "Figure" then return nil end
  local cap = fig.caption.long
  if not cap or #cap == 0 then return nil end
  local inlines = {}
  for _, block in ipairs(cap) do
    if block.t == "Para" or block.t == "Plain" then
      if #inlines > 0 then
        table.insert(inlines, pandoc.Space())
      end
      for _, il in ipairs(block.content) do
        table.insert(inlines, il)
      end
    end
  end
  if #inlines == 0 then return nil end
  return inlines
end

-- Extract all Image elements from a block
local function get_images(block)
  local images = {}
  local children
  if block.t == "Figure" then
    children = block.content
  elseif block.t == "Para" or block.t == "Plain" then
    children = {block}
  else
    return images
  end
  for _, b in ipairs(children) do
    if b.t == "Para" or b.t == "Plain" then
      for _, il in ipairs(b.content) do
        if il.t == "Image" then
          table.insert(images, il)
        end
      end
    end
  end
  return images
end

--------------------------------------------------------------------------------
-- Output builders
--------------------------------------------------------------------------------

local function styled_div(content, style_name)
  return pandoc.Div(content, pandoc.Attr("", {}, {{"custom-style", style_name}}))
end

local function make_title(inlines)
  return styled_div({pandoc.Para(inlines)}, "Figure Title")
end

local function make_source(para)
  return styled_div({para}, "Figure Source")
end

local function make_image_block(img)
  return styled_div({pandoc.Para({img})}, "Figure Image")
end

-- Place images side-by-side in a single paragraph with explicit widths
local function make_side_by_side(images)
  local n = #images
  -- Leave enough gap between images (space char + some breathing room)
  local img_width = string.format("%.1fin", (CONTENT_WIDTH_IN / n) - 0.3)

  local inlines = {}
  for i, img in ipairs(images) do
    -- Set explicit width so images fit side-by-side
    local new_img = pandoc.Image(
      img.caption, img.src, img.title,
      pandoc.Attr(img.identifier, img.classes, {width = img_width})
    )
    if i > 1 then
      table.insert(inlines, pandoc.Space())
    end
    table.insert(inlines, new_img)
  end

  return styled_div({pandoc.Para(inlines)}, "Figure Image")
end

--------------------------------------------------------------------------------
-- Detect the citeproc refs div
local function is_refs_div(block)
  return block.t == "Div" and block.identifier == "refs"
end

--------------------------------------------------------------------------------
-- Main filter: walk blocks and group consecutive figures
--------------------------------------------------------------------------------

function Pandoc(doc)
  local blocks = doc.blocks
  local out = {}
  local i = 1

  while i <= #blocks do
    -- Convert box divs to single-cell bordered tables
    if blocks[i].t == "Div" and blocks[i].classes:includes("box") then
      local div = blocks[i]
      local title = div.attributes["title"]
      table.insert(out, make_box(title, div.content))
      i = i + 1
    -- Insert a "References" heading before the citeproc bibliography div
    elseif is_refs_div(blocks[i]) then
      table.insert(out, pandoc.Header(1, pandoc.Str("References")))
      table.insert(out, blocks[i])
      i = i + 1
    elseif is_figure_block(blocks[i]) then
      -- Collect consecutive figure/image blocks
      local group = {blocks[i]}
      local j = i + 1
      while j <= #blocks and is_figure_block(blocks[j]) do
        table.insert(group, blocks[j])
        j = j + 1
      end

      -- Check for a "Source:" paragraph immediately after
      local source = nil
      if j <= #blocks and is_source_para(blocks[j]) then
        source = blocks[j]
        j = j + 1
      end

      -- Gather all images and captions from the group
      local all_images = {}
      local captions = {}
      for _, item in ipairs(group) do
        for _, img in ipairs(get_images(item)) do
          table.insert(all_images, img)
        end
        local cap = get_caption_inlines(item)
        if cap then table.insert(captions, cap) end
      end

      -- Emit: titles → images → source
      -- Emit: titles → images → source
      for _, cap_inlines in ipairs(captions) do
        table.insert(out, make_title(cap_inlines))
      end

      if #all_images >= 2 and #all_images <= 3 then
        table.insert(out, make_side_by_side(all_images))
      else
        for _, img in ipairs(all_images) do
          table.insert(out, make_image_block(img))
        end
      end

      if source then
        table.insert(out, make_source(source))
      end

      i = j
    else
      table.insert(out, blocks[i])
      i = i + 1
    end
  end

  doc.blocks = out
  return doc
end
