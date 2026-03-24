-- figure-title-above.lua
--
-- Features:
--   1. Figure titles placed above images with "Figure Title" style
--   2. Consecutive images (2–3) rendered side-by-side in a borderless table
--   3. "Source:" paragraphs after figures styled as "Figure Source"
--   4. Title + image + source kept together via keepNext styles

-- Page content width in inches (12240 - 2×1296 DXA) / 1440
local CONTENT_WIDTH_IN = 6.7

--------------------------------------------------------------------------------
-- Helpers
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
-- Main filter: walk blocks and group consecutive figures
--------------------------------------------------------------------------------

function Pandoc(doc)
  local blocks = doc.blocks
  local out = {}
  local i = 1

  while i <= #blocks do
    if is_figure_block(blocks[i]) then
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
