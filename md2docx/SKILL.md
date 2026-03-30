---
name: md2docx
description: Convert markdown files to Word (.docx) documents with academic formatting and Zotero/BibTeX citations. Use this skill when the user asks to convert markdown to Word, produce a .docx file from markdown, or needs a Word document with bibliography and cross-references.
compatibility: Requires pandoc, pandoc-crossref, and a references.bib file in the input directory.
metadata:
  author: taimur-shah
  version: "1.0"
---

# Markdown to Word (DOCX)

Convert markdown to formatted Word documents with citations using the `md2docx` script at [scripts/md2docx](scripts/md2docx).

## Usage

```bash
md2docx input.md             # outputs input.docx alongside the source file
md2docx input.md output.docx # outputs to a specific path
```

**Always use `md2docx`** — do not use raw pandoc commands directly.

## Requirements

- A `references.bib` file must exist in the same directory as the input markdown file
- The script will error if no `.bib` file is found

## How It Works

Uses pandoc with all resources bundled in [assets/](assets/):
- **Reference doc**: [assets/template.docx](assets/template.docx) (custom Word template for styles)
- **Citation style**: [assets/citation-style.csl](assets/citation-style.csl) (Harvard author-date)
- **Filters**: `pandoc-crossref` (for figure/table/equation cross-references) and `--citeproc` (for bibliography)
- **Lua filter**: [scripts/growthlabbify.lua](scripts/growthlabbify.lua) (figure titles above images, side-by-side layout, source captions, keep-together, boxes)
- **Sections**: Numbered, with table of contents (depth 3)

## Markdown Citation Syntax

Use standard pandoc citation syntax:

```markdown
As shown by @smith2023, the results indicate...
Several studies [@jones2021; @smith2023] have found...
```

## Cross-Reference Syntax (pandoc-crossref)

```markdown
![Caption text](image.png){#fig:label}

See @fig:label for details.

| Col A | Col B |
|-------|-------|
| 1     | 2     |

: Table caption {#tbl:label}

See @tbl:label for the data.
```

## Boxes

Use pandoc fenced divs with class `box` to create bordered, shaded callout boxes (rendered as single-cell tables in Word):

```markdown
::: {.box title="Box 1: Key Findings"}
First paragraph of the box.

Second paragraph with **bold** and *italic* formatting.

- Bullet lists work too
:::
```

The `title` attribute is optional. Boxes support paragraphs, bold/italic/code formatting, and bullet/numbered lists.
