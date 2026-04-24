# Templates

Templates for user instruction & administrative documentation (A.K.A. green & white team documentation).

## Usage

CD into the templates directory
```bash
cd Hall-of-Mirrors/templates/
```

Install [Pandoc](https://github.com/jgm/pandoc/) & use it to convert the markdown documents to a PDF/DOCX file.
```bash
# To DOCX
pandoc markdown.md -o document.docx -V geometry:margin=1in -L pagebreak.lua --reference-doc=ref.docx

# To PDF
pandoc markdown.md -o pdf.pdf -V geometry:margin=1in -L pagebreak.lua --reference-doc=ref.docx
```

Optionally, to avoid issues due to variations from system to system, you can install [Docker](https://docs.docker.com/engine/install/) & run the respective command for PDF/DOCX conversions

```bash
# To DOCX
docker run --rm -v "$(pwd):/data" pandoc/latex markdown.md -o document.docx -V geometry:margin=1in -L pagebreak.lua --reference-doc=ref.docx

# To PDF
docker run --rm -v "$(pwd):/data" pandoc/extra markdown.md -o pdf.pdf -V geometry:margin=1in -L pagebreak.lua --reference-doc=ref.docx
```

Adjust the documents as you see fit for your use case.