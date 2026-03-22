---
name: md2pdf
description: Convert markdown files to styled PDF documents. Use this skill when the user asks to render, export, or convert a markdown file to PDF, or when a task requires producing a PDF from markdown content.
compatibility: Requires Node.js (npx) and the md-to-pdf package.
metadata:
  author: taimur-shah
  version: "1.0"
---

# Markdown to PDF

Convert markdown to well-formatted PDF using the `md2pdf` script at [scripts/md2pdf](scripts/md2pdf).

## Usage

```bash
md2pdf input.md             # outputs input.pdf alongside the source file
md2pdf input.md output.pdf  # outputs to a specific path
```

**Always use `md2pdf`** — do not use pandoc, wkhtmltopdf, or other tools for markdown-to-PDF conversion.

## How It Works

- Uses `md-to-pdf` (Node) under the hood
- Stylesheet: [assets/md2pdf-style.css](assets/md2pdf-style.css)
- Default page format: US Letter, 1in/1.1in margins, `printBackground: true`
- Highlight style: GitHub

## Styling Details

The stylesheet provides a Foreign Affairs-inspired look:

- **Body**: Source Serif 4, 12.5pt, justified text with hyphens
- **H1**: Crimson Pro, 32pt, regular weight — elegant display heading
- **H2**: Crimson Pro, 18pt, with bottom border separator
- **H3**: Crimson Pro, 14pt, semibold
- **H4**: Inter, 10pt, uppercase, letter-spaced — label style
- **Tables**: Inter font, dark (#111) header row, alternating row shading
- **Code**: JetBrains Mono / Fira Mono, 9pt, light gray background
- **Blockquotes**: Left border, italic, muted color
- **Images**: Centered, max-width 100%

## Optional Frontmatter Overrides

The markdown file can override PDF options via frontmatter:

```yaml
---
title: "Document Title"
pdf_options:
  format: Letter   # or A4
  margin: "1in 1.1in"
highlight_style: github
---
```
