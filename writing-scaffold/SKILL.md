---
name: writing-scaffold
description: Break a document outline into bite-sized section files for easier writing, then roll them back up into a single document. Use when the user wants to write a large document (paper, report, essay, policy brief) and needs help structuring it into manageable pieces, or when they have an outline and want individual markdown files per section pre-populated with frontmatter and references. Also use when the user asks to "roll up" or merge section files back into one document. Triggers on "scaffold", "break into sections", "writing scaffold", "roll up sections", "merge sections".
---

# Writing Scaffold

Break large writing projects into bite-sized section files. Each section becomes its own markdown file with frontmatter — easy to focus on one piece at a time, then roll everything back into a single document.

## Workflow

### 1. Scaffold: Outline → Section Files

Given a markdown outline with `##` headers, create individual files:

```bash
scaffold outline.md                     # → sections/ directory next to outline
scaffold outline.md --output ./parts    # → custom output directory
scaffold outline.md --bib refs.bib      # → custom bib path in frontmatter
```

Each `##` heading becomes a file like `01-introduction.md` with:

```yaml
---
title: "Introduction"
section: 1
parent: "Document Title"
bibliography: references.bib
---
```

Subsections (`###`, `####`) stay inside their parent section's file. Any notes or bullet points under a `##` heading in the outline are preserved as starter content.

A `.manifest` file tracks section order for rollup.

### 2. Write: One Section at a Time

The human writes. Each section file is small and focused. When asked for help with a specific section, read only that file — don't load the whole document.

When helping with a section:
- Read the section file and the outline for context
- Suggest structure, transitions, or key points — don't write prose unless asked
- Keep citations in pandoc format: `@smith2023` or `[@jones2021; @smith2023]`

### 3. Rollup: Section Files → Single Document

Merge all sections back into one markdown file:

```bash
rollup sections/                        # → stdout
rollup sections/ -o full-document.md    # → file
```

Reads `.manifest` for ordering (falls back to alphabetical). Strips frontmatter from each section, reconstructs the document title from the `parent` field, and joins sections with horizontal rules.

The output is clean markdown ready for `md2docx`, `md2pdf`, or any other conversion.

## Tips

- Reorder sections by editing `.manifest` (one filename per line)
- Add new sections: create a new numbered `.md` file and add it to `.manifest`
- Split a section that's too big: break it into `03a-` and `03b-` files and update `.manifest`
- The scaffold script only creates files — it never overwrites existing section files
