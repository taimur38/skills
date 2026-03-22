---
name: md2slides
description: Convert markdown files to PDF slide decks. Use this skill when the user asks to create slides, a presentation, or a slide deck from markdown, or when rendering markdown as a PDF deck.
compatibility: Requires Node.js and the Marp CLI (marp).
metadata:
  author: taimur-shah
  version: "1.0"
---

# Markdown to Slides

Convert markdown to 16:9 PDF slide decks using the `md2slides` script at [scripts/md2slides](scripts/md2slides) and Marp.

## Usage

```bash
md2slides input.md             # outputs input.pdf alongside the source file
md2slides input.md output.pdf  # outputs to a specific path
```

**Always use `md2slides`** — do not use other slide tools (reveal.js, Beamer, etc.) unless explicitly requested.

The theme CSS is bundled at [assets/marp-theme.css](assets/marp-theme.css) and resolved automatically by the script.

## Required Frontmatter

Every slide markdown file must begin with:

```yaml
---
marp: true
theme: growth-lab
size: 16:9
paginate: true
---
```

## Slide Separators

Use `---` between slides (standard Marp separator).

## Slide Classes

Set with `<!-- _class: type -->` at the start of a slide:

| Class | Purpose | Notes |
|-------|---------|-------|
| `title` | Dark (#111) title slide | Text anchored to bottom. H1 = white 62px, H2 = gray 26px, H3 = muted label above |
| `break` | Dark blue (#1c3a5e) section divider | H1 = white 48px, body text = blue-gray |
| `img-slide` | Image-left layout | Use with `![bg left:55%](img.png)` for side-by-side |
| `closing` | Light (#f7f4f0) closing slide | H1 = italic 42px centered, body = uppercase label |
| `map-slide` | Tight-padding map layout | For side-by-side maps in `.cols` |
| `img-full` | Full image slide | Image gets max 62vh height |

## Two-Column Layout

Wrap content in a `.cols` div:

```html
<div class="cols">
<div>

Left column content

</div>
<div>

Right column content

</div>
</div>
```

## Theme Details (growth-lab)

- **Body**: Source Serif 4, 21px
- **H1**: Crimson Pro, 54px, regular weight
- **H2**: Crimson Pro, 36px, with bottom border
- **H3**: Inter, 13px, uppercase, letter-spaced — used as labels/subtitles
- **Tables**: Dark blue (#1c3a5e) header, Inter font, alternating rows
- **Images**: Centered, max 75% width / 50vh height (larger in special classes)
- **Page numbers**: Inter 12px, light gray
