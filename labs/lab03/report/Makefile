all: pdf docx

pdf:
	quarto render simulation-modeling--lab03--report.qmd --to pdf --no-execute

docx:
	quarto render simulation-modeling--lab03--report.qmd --to docx --no-execute

clean:
	rm -rf _output .quarto

.PHONY: all pdf docx clean
