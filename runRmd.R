# Set working directory
setwd(getwd())

# Load packages
require(knitr)
require(markdown)

# Create .md, .html, and .pdf files
knit("Auto_Chapter_Classification.Rmd")
markdownToHTML('Auto_Chapter_Classification.md', 'report.html', options=c("use_xhml"))
