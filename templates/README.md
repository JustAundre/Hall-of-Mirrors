# Templates

Templates for user manual and administration documentation (better known as green/white team documentation).

## Usage

CD into the templates directory
```bash
cd ./Hall-of-Mirrors/templates/
```

| File | Purpose |
| --- | --- |
| `./admin-doc.md` | White team documentation: document changes to the system software, firmware and/or configuration here. |
| `./user-doc.md` | Green team documentation: document how to use the system or services offered by the system with detailed instructions here. Although, usually you aim to have such good UX/UI that even the most grandma of grandmas can figure out how to change their password or account info, which is somehow notoriously difficult with big companies... |
| `./admin-doc.pdf` | Example rendering of the `./admin-doc.md` file |
| `./user-doc.pdf` | Example rendering of the `./user-doc.md` file |

Modify the above files as you see fit

Install [Pandoc](https://github.com/jgm/pandoc/) and use it to convert to PDF/DOCX
```bash
# To DOCX
pandoc /path/to/md/file.md --output /path/to/docx/file.docx

# To PDF
pandoc /path/to/md/file.md --output /path/to/pdf/file.pdf
```