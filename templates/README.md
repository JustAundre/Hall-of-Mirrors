# Templates

Templates for user manual & administration documentation (better known as green/white team documentation).

## Usage

CD into the templates directory
```bash
cd Hall-of-Mirrors/templates/
```

Install [Pandoc](https://github.com/jgm/pandoc/) & use it to convert the markdown documents to a PDF/DOCX file.
```bash
# To DOCX
pandoc /path/to/file.md --output /path/to/file.docx

# To PDF
pandoc /path/to/file.md --output /path/to/file.pdf
```

Optionally, to avoid issues/bloat, you may install [Docker](https://docs.docker.com/engine/install/) & run the respective command for PDF/DOCX
```bash
# To DOCX
docker run --rm -v "$(pwd):/data" pandoc/latex /path/to/file.md -o /path/to/file.docx

# To PDF
docker run --rm -v "$(pwd):/data" pandoc/latex /path/to/file.md -o /path/to/file.pdf
```

Adjust the documents as you see fit for your use case.