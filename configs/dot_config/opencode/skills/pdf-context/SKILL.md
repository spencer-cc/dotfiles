---
name: pdf-context
description: PDF text extraction and OCR using pdftotext, pdftoppm, tesseract, and pdfinfo. Load when working with PDF files.
---

## Tools

All tools come from Homebrew: Poppler (`brew "poppler"` in `Brewfile.dev`) and Tesseract (`brew install tesseract tesseract-lang` — installed ad-hoc, not tracked in a Brewfile).

| Tool        | Purpose                                |
| ----------- | -------------------------------------- |
| `pdftotext` | Extract text from text-searchable PDFs |
| `pdftoppm`  | Convert PDF pages to images (for OCR)  |
| `pdfinfo`   | PDF metadata (pages, author, etc.)     |
| `tesseract` | OCR on images/scanned PDFs             |

## Text Extraction

### Full document to stdout

```bash
pdftotext -layout file.pdf -
```

### Specific page range

```bash
pdftotext -f 5 -l 10 -layout file.pdf -
```

### Single page

```bash
pdftotext -f 3 -l 3 -layout file.pdf -
```

### Pipe into grep/head/tail

```bash
pdftotext -layout file.pdf - | grep "search term"
pdftotext -f 2 -l 2 -layout file.pdf - | head -50
```

### Structured output

| Format                  | Flag        | Use case                                    |
| ----------------------- | ----------- | ------------------------------------------- |
| Layout-preserving       | `-layout`   | Default choice, maintains spatial structure |
| HTML with metadata      | `-htmlmeta` | Preserves headings and metadata             |
| TSV with bounding boxes | `-tsv`      | Table extraction, positional data           |
| Raw stream order        | `-raw`      | Debugging, non-standard layouts             |

## Metadata

```bash
pdfinfo file.pdf
```

Returns: page count, page size, author, creation date, PDF version, etc.

## OCR (Scanned/Image PDFs)

Two-step pipeline: render page to image, then OCR.

### Single page OCR

```bash
pdftoppm -png -f 3 -l 3 -r 300 file.pdf /tmp/pdf-page && tesseract /tmp/pdf-page-3.png stdout
```

### Full document OCR

```bash
pdftoppm -png -r 300 file.pdf /tmp/pdf-page && for f in /tmp/pdf-page-*.png; do tesseract "$f" stdout; done
```

### OCR with language support

```bash
tesseract image.png stdout -l eng+tha
```

Available languages: `eng` (English), `tha` (Thai), `eng+tha` (both). Install more with `brew install tesseract-lang`.

## Decision Guide

1. **Is the PDF text-searchable?** Run `pdftotext file.pdf - | head -5`. If you get text, use `pdftotext`.
2. **Scanned/image PDF?** Use the `pdftoppm` + `tesseract` pipeline.
3. **Need page count or metadata?** Use `pdfinfo`.
4. **Need tables or positional data?** Use `pdftotext -tsv`.

## Tips

- Always use `-layout` with `pdftotext` unless you need raw stream order.
- Use `-` as output filename to write to stdout instead of a file.
- For OCR, `-r 300` (300 DPI) is the minimum for good accuracy. Use `-r 600` for difficult scans.
- Clean up temp files: `rm /tmp/pdf-page-*.png` after OCR.
- For large PDFs, extract only the pages you need with `-f`/`-l` to reduce processing time and token usage.
