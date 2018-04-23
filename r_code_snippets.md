# Some useful R things (maybe specific to this problem)

## Finding top `n` counts of words in a chapter/all chapters

```
tail( sort(slam::row_sums(t(subdtm))), 50)
```

For a particular chapter you would do:

```{r}
chapterName = "NameOfChapter"
subdtm = text_dtm[ which(repo$chapter == chapterName), ]
tail(sort(row_sums(t(subdtm))), 50)
```
