---
title: "R Notebook"
output: html_notebook
---


```r
library('tidyverse')
library('e1071')
library('SparseM')
library('tm')
library('caret')
#library('SnowballC')
#library('wordcloud')
library('jsonlite')

library(reticulate)
path_to_python <- "/usr/local/bin/python3"
use_python(path_to_python)
knitr::knit_engines$set(python = reticulate::eng_python)
py_available(initialize = TRUE)
```

```
## [1] TRUE
```

## Configuration

```r
# Algorithm. Choices: svm, naiveBayes, etc
algorithm = naiveBayes

# Categorical or not. Choices: TRUE or FALSE
categorical = TRUE

# Weighting function. Choices: weightTf, weightTfIdf
# Whether to normalize terms of Document Matrix. Choices: TRUE, FALSE
weightingFunction = weightTf
normalize = FALSE

# Whether to write to db
writeToDb = TRUE
```


```r
## Reading data from CMS
Qs <- jsonlite::fromJSON('qs_topicwise.json')
Qs <- flatten(Qs)

#Qs <- read_tsv("qs_topicwise_dump.tsv")

head(Qs)
```

```
##         topic_code               chapter
## 1 MTH-12-JEE-18-01 Inverse Trigonometry 
## 2 MTH-12-JEE-18-01 Inverse Trigonometry 
## 3 MTH-12-JEE-18-01 Inverse Trigonometry 
## 4 MTH-12-JEE-18-01 Inverse Trigonometry 
## 5 MTH-12-JEE-18-01 Inverse Trigonometry 
## 6 MTH-12-JEE-18-01 Inverse Trigonometry 
##                                  topic difficulty problem_code
## 1 Introduction to Inverse Trigonometry          1      P000321
## 2 Introduction to Inverse Trigonometry          1      P005928
## 3 Introduction to Inverse Trigonometry          1      P005929
## 4 Introduction to Inverse Trigonometry          1      P005930
## 5 Introduction to Inverse Trigonometry          1      P005931
## 6 Introduction to Inverse Trigonometry          1      P005932
##   problem_status         problem_mongo_id problem_type
## 1          final 554aee4869702d67a97c0200   ConcepTest
## 2          final 56f2348c3562d9749900083a    Spot Test
## 3          final 56f235453562d97499000841    Spot Test
## 4          final 56f235d43562d97499000848    Spot Test
## 5          final 56f242be3562d97499000854    Spot Test
## 6          final 56f243c43562d9749900085b    Spot Test
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           question_text
## 1 Among the statements given below, which one is correct? \\({\\sin ^{ - 1}}x = {\\left( {\\sin x} \\right)^{ - 1}}\\) \\({\\sin ^{ - 1}}x = \\frac{1}{{\\sin x}}\\) \\({\\left( {\\sin x} \\right)^{ - 1}} = \\frac{1}{{\\sin x}}\\) None of the above It is important to understand that \\({\\sin ^{ - 1}}x\\) and \\({\\left( {\\sin x} \\right)^{ - 1}}\\) are two different functions. \\({\\left( {\\sin x} \\right)^{ - 1}}\\) is the reciprocal of \\(\\sin x\\), whereas \\({\\sin ^{ - 1}}x\\) is the inverse of \\(\\sin x\\)For eg. \tWhen \\(\\sin x = \\frac{1}{2}\\),\t\t\\({\\left( {\\sin x} \\right)^{ - 1}} = \\frac{1}{{\\sin x}} = 2\\)\t\t \\(x = {\\sin ^{ - 1}}\\left( {\\frac{1}{2}} \\right) = 30^\\circ \\)
## 2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                \\(\\sin^{−1}\\left(⁡\\frac{1}{√2}\\right)=\\)________ \\(\\frac{\\pi}2\\) \\(\\frac{\\pi}4\\) \\(\\frac{\\pi}3\\) \\(\\frac{\\pi}6\\) 
## 3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              The principal domain of \\(\\cos⁡𝑥\\) is ___________  \\(\\left[0, 2𝜋\\right]\\) \\(\\left[−\\frac{𝜋}2,\\frac{𝜋}2\\right]\\) \\(\\left[0, 𝜋\\right]\\) \\(\\left[0,\\frac{𝜋}2\\right]\\) 
## 4                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             The principal domain of \\(\\tan⁡𝑥\\) is ___________  \\(\\left[0, 2\\pi\\right]\\) \\(\\left[-\\frac{\\pi}2, \\frac{\\pi}2\\right]\\) \\(\\left[0, \\pi\\right]\\) \\(\\left[0, \\frac{\\pi}2\\right]\\) 
## 5                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           \\(\\tan^{-1}\\left(\\sin\\frac{\\pi}2\\right)=\\) \\(\\frac\\pi2\\) \\(\\frac\\pi4\\) \\(\\frac\\pi3\\) \\(\\frac\\pi6\\) 
## 6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           \\(\\sin^{−1}⁡\\left(\\sin⁡𝑥\\right)=𝑥\\) if \\(𝑥∈\\)_________ \\(\\left[0, 2𝜋\\right]\\) \\(\\left[-\\frac \\pi 2, \\frac \\pi 2\\right]\\) \\(\\left[0, 𝜋\\right]\\) \\(\\left[0, \\frac \\pi 2\\right]\\)
```

### Cleaning and adding Grade, Subject, Curriculum and Chapter No 


```r
# Need to clean the overflow of text
Qs_clean <- Qs  %>%
  #dplyr::select(1:9) %>%                    # Keeping only the first 9 columns
  #dplyr::filter(!is.na(difficulty))  %>%    # No need to clean overflow
  dplyr::mutate(Grade = str_sub(topic_code, 5, 6), Subject = str_sub(topic_code, 1, 3), Curriculum = str_sub(topic_code, 8, 10), Ch_No = str_sub(topic_code, 12, 13))
```

### Summarizing Chapter wise # Qs in the entire JEE dataset


```r
repo <- Qs_clean %>% filter(Curriculum =="JEE", Subject =="MTH")

chapters_to_remove = c('Selection Test', 'Repository', 'Bridge Intervention Curriculum', 'M1.1 Scaffold test','Tally Marks')

chapters_with_no_data = c('Principle of Mathematical Induction')

repo <- repo %>% 
  filter(!chapter %in%  chapters_to_remove) %>%
  filter(!chapter %in%  chapters_with_no_data)

repo %>% group_by(chapter) %>% summarize(count_qs =n())
```

```
## # A tibble: 26 x 2
##    chapter                          count_qs
##    <chr>                               <int>
##  1 3 Dimensional Geometry                135
##  2 Applications of Derivatives           250
##  3 Binomial Theorem                      307
##  4 Complex Numbers                       394
##  5 Conic Sections - I                    289
##  6 Conic Sections - II                   431
##  7 Continuity and Differentiability      277
##  8 Definite Integration                  195
##  9 Differential Equations                 80
## 10 Functions 2                           159
## # ... with 16 more rows
```

## Create text corpus


```r
repo<-repo[sample(nrow(repo)),]       ## Randomize row numbers
text_corpus <- VCorpus(VectorSource(repo$question_text)) 
lapply(text_corpus[2:4], as.character)       # Multiple docs
```

```
## $`2`
## [1] "If \\(0&lt;x&lt;\\frac{\\pi}{2}\\), then the value of \\(\\left(\\sin x+\\cos x+\\text{cosec}  x\\right)\\) is \\(\\ge5(\\frac{1}{2})^\\frac{1}{3}\\) \\(\\ge2(\\frac{1}{3})^\\frac{1}{2}\\) \\(\\ge3(\\frac{1}{2})^\\frac{1}{3}\\) None of these Using \\(A.M. \\ge G.M.\\), we have\\(\\frac{\\sin x+\\cos x+cosec2x}{3}\\ge\\left(\\sin x\\:\\cos x\\:cosec\\:2x\\right)^{\\frac{1}{3}}\\)\\(\\Rightarrow\\:\\sin x\\:+\\cos x\\:+cosec\\:2x\\ge3\\left(\\frac{1}{2}\\right)^{\\frac{1}{3}}\\)."
## 
## $`3`
## [1] "A function is said to be an odd function if  \\(f\\left(-x\\right)=-f\\left(x\\right)\\) \\(f\\left(-x\\right)=f\\left(x\\right)\\) \\(f\\left(-x\\right)=2f\\left(x\\right)\\) \\(2f\\left(-x\\right)=f\\left(x\\right)\\) An odd function must satisfy the condition \\(f\\left(-x\\right)=-f\\left(x\\right)\\) for every \\(x\\) belonging to the domain of the function."
## 
## $`4`
## [1] "The logical equivalent of \\(\\left(p\\:\\vee\\sim q\\right)\\wedge\\left(\\sim p\\:\\vee\\sim q\\right)\\) is \\(p\\) \\(\\sim q\\) \\(\\sim p\\) \\(q\\) \\(\\left(p\\:\\vee\\sim q\\right)\\wedge\\left(\\sim p\\:\\vee\\sim q\\right)\\equiv\\left(p\\wedge\\left(\\sim p\\right)\\right)\\vee\\left(\\sim q\\right)\\)\\(\\equiv c\\vee\\left(\\sim q\\right)\\)\\(\\equiv\\:\\sim q\\)"
```

## Cleaning text 
Removing punctuations, numbers and stop words
Converting to lower case
Stemming words - learned, learning, and learns are transformed into the base form, learn
Removing additional white spaces


```r
# Source : [2] Removing non-UTF8 characters
text_corpus_clean <- tm_map(text_corpus, content_transformer(gsub), pattern ="[^[:alnum:]]" , replacement = " ")
text_corpus_clean <- tm_map(text_corpus_clean, content_transformer(gsub), pattern ="[\u0080-\uffff]" , replacement = " ")

## Now non-UTF characters are removed. We can do regular tasks on the clean corpus.

#text_corpus_clean <- tm_map(text_corpus_clean, removeNumbers)
text_corpus_clean <- tm_map(text_corpus_clean, content_transformer(tolower))

# Remove one letter words
text_corpus_clean <- tm_map(text_corpus_clean, content_transformer(gsub), pattern="\\b\\w{1,2}\\b", replacement = "")

## Add stopwords like left, right (frac ?)
#text_corpus_clean <- tm_map(text_corpus_clean, removeWords, c(stopwords(), "left","right"))
text_corpus_clean <- tm_map(text_corpus_clean, removePunctuation)
#text_corpus_clean <- tm_map(text_corpus_clean, stemDocument)
text_corpus_clean <- tm_map(text_corpus_clean, stripWhitespace)

lapply(text_corpus_clean[2:4], as.character)       
```

```
## $`2`
## [1] " frac then the value left sin cos text cosec right ge5 frac frac ge2 frac frac ge3 frac frac none these using have frac sin cos cosec2x left sin cos cosec right frac rightarrow sin cos cosec ge3 left frac right frac "
## 
## $`3`
## [1] " function said odd function left right left right left right left right left right left right left right left right odd function must satisfy the condition left right left right for every belonging the domain the function "
## 
## $`4`
## [1] "the logical equivalent left vee sim right wedge left sim vee sim right sim sim left vee sim right wedge left sim vee sim right equiv left wedge left sim right right vee left sim right equiv vee left sim right equiv sim "
```

## Bag of words - Tokenization

```r
# TF-IDF
text_dtm <- DocumentTermMatrix(text_corpus_clean, control = list(weighting = weightingFunction, normalize = normalize))

# Add a dictionary to DTM ?
```

## Data preparation - Creating training and test datasets

```r
folds <- cut(seq(1,nrow(repo)),breaks=5,labels=FALSE)
test_indices = which(folds==1, arr.ind=TRUE)

text_dtm_train <- text_dtm[-test_indices,  ]
text_dtm_test <- text_dtm[test_indices,  ]
```

## Setting Labels for prediction and checking their sample proportion (%)

```r
text_train_labels <- as.factor(repo[-test_indices,  ]$chapter)
text_test_labels <- as.factor(repo[test_indices,  ]$chapter) 

round(prop.table(table(text_train_labels))*100,2)
```

```
## text_train_labels
##           3 Dimensional Geometry      Applications of Derivatives 
##                             1.93                             3.80 
##                 Binomial Theorem                  Complex Numbers 
##                             4.54                             6.10 
##               Conic Sections - I              Conic Sections - II 
##                             4.41                             6.54 
## Continuity and Differentiability             Definite Integration 
##                             4.25                             2.94 
##           Differential Equations                      Functions 2 
##                             1.30                             2.58 
##      Fundamentals of Mathematics           Indefinite Integration 
##                             5.97                             1.58 
##                     Inequalities            Inverse Trigonometry  
##                             3.87                             1.68 
##                           Limits           Mathematical Reasoning 
##                             2.86                             2.04 
##        Matrices and Determinants    Permutations and Combinations 
##                             2.33                             5.51 
##                      Probability              Quadratic Equations 
##                             2.48                             5.44 
##              Sequence and Series    Sets, Relations and Functions 
##                             5.40                             6.33 
##                       Statistics                   Straight Lines 
##                             2.52                             5.09 
##                     Trigonometry                   Vector Algebra 
##                             5.82                             2.69
```

## Distribution of labels in test set

```r
round(prop.table(table(text_test_labels))*100,2)
```

```
## text_test_labels
##           3 Dimensional Geometry      Applications of Derivatives 
##                             2.59                             3.89 
##                 Binomial Theorem                  Complex Numbers 
##                             5.26                             5.64 
##               Conic Sections - I              Conic Sections - II 
##                             4.42                             6.71 
## Continuity and Differentiability             Definite Integration 
##                             4.12                             3.13 
##           Differential Equations                      Functions 2 
##                             0.92                             1.83 
##      Fundamentals of Mathematics           Indefinite Integration 
##                             6.03                             1.83 
##                     Inequalities            Inverse Trigonometry  
##                             3.66                             2.21 
##                           Limits           Mathematical Reasoning 
##                             3.51                             2.59 
##        Matrices and Determinants    Permutations and Combinations 
##                             2.52                             5.42 
##                      Probability              Quadratic Equations 
##                             2.36                             4.50 
##              Sequence and Series    Sets, Relations and Functions 
##                             5.42                             6.86 
##                       Statistics                   Straight Lines 
##                             2.36                             5.11 
##                     Trigonometry                   Vector Algebra 
##                             5.42                             1.68
```

## Visualizing text data - word clouds
wordcloud(text_corpus_clean, min.freq=10, random.order = FALSE)
wordcloud(text_corpus_clean[repo$chapter == "Applications of Derivatives"], max.words = 40, scale = c(3, 0.5))

## Converting DTM to a categorical data (T/F) for NB e1071 as it only takes categorical input


```r
## Filter features by selecting words appearing at least a specified number of times
text_freq_words <- findFreqTerms(text_dtm, 25)

# tf-idf ?
# Useful to remove words which maybe in training set but not in test set leading to an out of bounds error

text_dtm_freq_train <- text_dtm_train[ , text_freq_words]
text_dtm_freq_test <- text_dtm_test[ , text_freq_words]

convert_counts <- function(x) {
  if(categorical) {
    x <- ifelse(x > 0, "Yes", "No")
  } 
  else {
    x <- x
  }
}

# MARGIN = 1 is used for rows
text_train <- apply(text_dtm_freq_train, MARGIN = 2, convert_counts)
text_test <- apply(text_dtm_freq_test, MARGIN = 2, convert_counts)


# Laplace - This allows words that did not appear earlier to have an indisputable say in the classification process. Just because the word "ringtone" only appeared in the spam messages in the training data, it does not mean that every message with this word should be classified as spam
```

## TRAINING

```r
text_classifier <- algorithm(as.matrix(text_train), text_train_labels)
```

## PREDICTION

```r
rawResults <- predict(text_classifier,as.matrix(text_test), "raw")

results <- as.factor( colnames(rawResults)[apply(rawResults, 1, which.max)] )

true_values <- repo[test_indices, ]$chapter
test_document <- repo[test_indices, ]$question_text

## as.table((test_document,true_values, results)) ??
```

## Confusion Matrix

```r
conf = confusionMatrix(results, text_test_labels)
confusion_table = as.data.frame.matrix( conf$table  )
conf_stats = as.data.frame(conf$byClass)
confusion_table[nrow(confusion_table) + 1, ] <- conf_stats$Sensitivity
q_counts = repo %>% group_by(chapter) %>% summarize(count_qs =n())
confusion_table[nrow(confusion_table) + 1, ] <- t(q_counts[,2])

conf$overall
```

```
##       Accuracy          Kappa  AccuracyLower  AccuracyUpper   AccuracyNull 
##     0.69946606     0.68508882     0.67383874     0.72419583     0.06864989 
## AccuracyPValue  McnemarPValue 
##     0.00000000            NaN
```

```r
#View(conf_stats)
#View(round(confusion_table, 1))
```


```python
x = 1
print(r.results)
```

```
## ['Definite Integration', 'Trigonometry', 'Functions 2', 'Mathematical Reasoning', 'Sets, Relations and Functions', 'Straight Lines', 'Definite Integration', 'Indefinite Integration', 'Complex Numbers', 'Straight Lines', 'Fundamentals of Mathematics', 'Matrices and Determinants', 'Quadratic Equations', 'Binomial Theorem', 'Inequalities', 'Binomial Theorem', 'Binomial Theorem', 'Trigonometry', 'Limits', 'Conic Sections - I', 'Permutations and Combinations', 'Mathematical Reasoning', 'Straight Lines', 'Binomial Theorem', 'Inverse Trigonometry ', 'Statistics', 'Sequence and Series', 'Inequalities', 'Sequence and Series', 'Complex Numbers', 'Inverse Trigonometry ', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Complex Numbers', 'Functions 2', 'Functions 2', 'Fundamentals of Mathematics', 'Binomial Theorem', 'Continuity and Differentiability', 'Limits', 'Conic Sections - I', 'Matrices and Determinants', 'Inverse Trigonometry ', 'Matrices and Determinants', 'Applications of Derivatives', 'Straight Lines', 'Indefinite Integration', 'Fundamentals of Mathematics', 'Quadratic Equations', 'Sets, Relations and Functions', 'Limits', 'Trigonometry', 'Conic Sections - II', 'Complex Numbers', 'Inequalities', 'Quadratic Equations', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Conic Sections - I', 'Straight Lines', 'Indefinite Integration', 'Complex Numbers', 'Inequalities', 'Quadratic Equations', 'Quadratic Equations', 'Indefinite Integration', 'Quadratic Equations', 'Sequence and Series', 'Definite Integration', 'Binomial Theorem', 'Sequence and Series', 'Fundamentals of Mathematics', 'Applications of Derivatives', 'Vector Algebra', 'Conic Sections - II', 'Definite Integration', 'Functions 2', 'Binomial Theorem', 'Applications of Derivatives', 'Sets, Relations and Functions', 'Matrices and Determinants', 'Continuity and Differentiability', 'Permutations and Combinations', 'Permutations and Combinations', 'Definite Integration', 'Functions 2', 'Inverse Trigonometry ', 'Complex Numbers', 'Fundamentals of Mathematics', 'Trigonometry', 'Sequence and Series', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Binomial Theorem', 'Permutations and Combinations', 'Sequence and Series', 'Indefinite Integration', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Binomial Theorem', '3 Dimensional Geometry', 'Sets, Relations and Functions', 'Applications of Derivatives', 'Definite Integration', 'Sets, Relations and Functions', 'Quadratic Equations', 'Functions 2', 'Limits', 'Binomial Theorem', 'Quadratic Equations', 'Limits', 'Inverse Trigonometry ', 'Sets, Relations and Functions', 'Applications of Derivatives', 'Permutations and Combinations', 'Permutations and Combinations', 'Inequalities', 'Conic Sections - I', 'Straight Lines', 'Vector Algebra', 'Applications of Derivatives', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Complex Numbers', 'Functions 2', 'Permutations and Combinations', 'Quadratic Equations', '3 Dimensional Geometry', 'Inequalities', 'Quadratic Equations', 'Limits', 'Conic Sections - II', 'Limits', 'Fundamentals of Mathematics', 'Binomial Theorem', 'Indefinite Integration', 'Applications of Derivatives', 'Conic Sections - I', 'Permutations and Combinations', 'Vector Algebra', 'Conic Sections - II', 'Trigonometry', 'Applications of Derivatives', 'Fundamentals of Mathematics', 'Indefinite Integration', 'Indefinite Integration', 'Sets, Relations and Functions', 'Vector Algebra', 'Indefinite Integration', 'Straight Lines', 'Binomial Theorem', 'Vector Algebra', 'Sequence and Series', 'Straight Lines', 'Trigonometry', 'Complex Numbers', 'Sets, Relations and Functions', 'Permutations and Combinations', 'Complex Numbers', 'Definite Integration', 'Differential Equations', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Continuity and Differentiability', 'Permutations and Combinations', 'Matrices and Determinants', 'Mathematical Reasoning', 'Indefinite Integration', 'Continuity and Differentiability', 'Permutations and Combinations', 'Conic Sections - II', 'Differential Equations', 'Fundamentals of Mathematics', 'Quadratic Equations', 'Limits', 'Fundamentals of Mathematics', 'Limits', 'Complex Numbers', 'Limits', 'Mathematical Reasoning', 'Indefinite Integration', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Probability', 'Conic Sections - II', 'Matrices and Determinants', 'Fundamentals of Mathematics', 'Quadratic Equations', 'Complex Numbers', 'Sets, Relations and Functions', 'Complex Numbers', 'Matrices and Determinants', 'Complex Numbers', 'Statistics', 'Trigonometry', 'Statistics', 'Inequalities', 'Inequalities', 'Continuity and Differentiability', 'Quadratic Equations', 'Mathematical Reasoning', 'Permutations and Combinations', 'Binomial Theorem', 'Conic Sections - II', 'Sequence and Series', 'Complex Numbers', 'Straight Lines', 'Sets, Relations and Functions', 'Statistics', 'Quadratic Equations', 'Binomial Theorem', 'Binomial Theorem', 'Sequence and Series', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sets, Relations and Functions', 'Conic Sections - I', 'Complex Numbers', 'Definite Integration', 'Fundamentals of Mathematics', 'Complex Numbers', 'Permutations and Combinations', 'Binomial Theorem', 'Indefinite Integration', 'Conic Sections - II', 'Permutations and Combinations', 'Inequalities', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Conic Sections - II', 'Sets, Relations and Functions', 'Quadratic Equations', 'Straight Lines', 'Inequalities', 'Trigonometry', 'Continuity and Differentiability', 'Trigonometry', 'Binomial Theorem', 'Conic Sections - II', 'Straight Lines', 'Binomial Theorem', 'Straight Lines', 'Vector Algebra', 'Permutations and Combinations', 'Quadratic Equations', 'Fundamentals of Mathematics', '3 Dimensional Geometry', 'Probability', 'Indefinite Integration', 'Sequence and Series', 'Fundamentals of Mathematics', 'Straight Lines', 'Complex Numbers', 'Quadratic Equations', 'Sequence and Series', 'Statistics', 'Fundamentals of Mathematics', 'Limits', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Inequalities', 'Binomial Theorem', 'Inequalities', 'Straight Lines', 'Conic Sections - II', 'Quadratic Equations', 'Vector Algebra', 'Conic Sections - II', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Sequence and Series', 'Complex Numbers', 'Trigonometry', 'Quadratic Equations', 'Indefinite Integration', 'Matrices and Determinants', 'Fundamentals of Mathematics', 'Limits', 'Vector Algebra', 'Mathematical Reasoning', 'Limits', 'Binomial Theorem', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Inequalities', 'Definite Integration', 'Fundamentals of Mathematics', 'Quadratic Equations', 'Sets, Relations and Functions', 'Indefinite Integration', 'Straight Lines', 'Fundamentals of Mathematics', 'Limits', 'Straight Lines', 'Permutations and Combinations', 'Permutations and Combinations', 'Quadratic Equations', 'Limits', 'Binomial Theorem', 'Quadratic Equations', 'Definite Integration', 'Binomial Theorem', 'Applications of Derivatives', '3 Dimensional Geometry', 'Conic Sections - II', 'Permutations and Combinations', 'Quadratic Equations', 'Sets, Relations and Functions', 'Complex Numbers', 'Sequence and Series', 'Continuity and Differentiability', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Straight Lines', 'Straight Lines', 'Quadratic Equations', 'Straight Lines', 'Binomial Theorem', 'Straight Lines', 'Indefinite Integration', 'Quadratic Equations', 'Vector Algebra', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Binomial Theorem', 'Matrices and Determinants', 'Indefinite Integration', 'Conic Sections - I', 'Conic Sections - I', 'Straight Lines', 'Inverse Trigonometry ', 'Functions 2', 'Permutations and Combinations', 'Limits', 'Continuity and Differentiability', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Vector Algebra', 'Sequence and Series', 'Limits', 'Permutations and Combinations', 'Quadratic Equations', 'Sets, Relations and Functions', 'Inverse Trigonometry ', 'Inequalities', 'Trigonometry', 'Inequalities', 'Definite Integration', 'Straight Lines', 'Continuity and Differentiability', 'Continuity and Differentiability', 'Indefinite Integration', 'Conic Sections - II', 'Permutations and Combinations', 'Matrices and Determinants', 'Quadratic Equations', 'Indefinite Integration', 'Limits', 'Binomial Theorem', 'Sequence and Series', 'Matrices and Determinants', 'Inverse Trigonometry ', 'Definite Integration', 'Limits', 'Limits', 'Trigonometry', 'Binomial Theorem', 'Conic Sections - II', 'Continuity and Differentiability', 'Indefinite Integration', 'Binomial Theorem', 'Sequence and Series', 'Indefinite Integration', 'Differential Equations', 'Sequence and Series', 'Binomial Theorem', 'Vector Algebra', 'Binomial Theorem', 'Binomial Theorem', 'Sequence and Series', '3 Dimensional Geometry', 'Conic Sections - I', 'Complex Numbers', 'Inequalities', 'Complex Numbers', 'Differential Equations', 'Statistics', 'Conic Sections - II', 'Binomial Theorem', 'Sets, Relations and Functions', 'Functions 2', 'Binomial Theorem', 'Limits', 'Vector Algebra', 'Straight Lines', 'Quadratic Equations', 'Sequence and Series', 'Probability', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Conic Sections - I', 'Permutations and Combinations', 'Inverse Trigonometry ', 'Sets, Relations and Functions', 'Vector Algebra', 'Permutations and Combinations', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Conic Sections - II', '3 Dimensional Geometry', 'Indefinite Integration', 'Probability', 'Conic Sections - II', 'Conic Sections - II', 'Conic Sections - I', 'Indefinite Integration', 'Quadratic Equations', 'Functions 2', 'Conic Sections - II', 'Indefinite Integration', 'Mathematical Reasoning', 'Statistics', 'Fundamentals of Mathematics', 'Limits', 'Sets, Relations and Functions', 'Straight Lines', 'Fundamentals of Mathematics', 'Binomial Theorem', 'Conic Sections - II', 'Trigonometry', 'Complex Numbers', 'Conic Sections - II', 'Statistics', 'Conic Sections - II', 'Binomial Theorem', 'Matrices and Determinants', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Quadratic Equations', 'Binomial Theorem', 'Trigonometry', 'Statistics', 'Continuity and Differentiability', 'Sets, Relations and Functions', 'Inequalities', 'Definite Integration', 'Fundamentals of Mathematics', 'Trigonometry', 'Mathematical Reasoning', 'Conic Sections - II', 'Continuity and Differentiability', 'Indefinite Integration', 'Probability', 'Sets, Relations and Functions', 'Continuity and Differentiability', 'Straight Lines', 'Sets, Relations and Functions', 'Complex Numbers', 'Inequalities', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sequence and Series', 'Indefinite Integration', 'Inequalities', '3 Dimensional Geometry', 'Statistics', 'Statistics', 'Inequalities', 'Sequence and Series', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Inverse Trigonometry ', 'Permutations and Combinations', 'Complex Numbers', 'Conic Sections - II', 'Sequence and Series', 'Continuity and Differentiability', 'Quadratic Equations', 'Conic Sections - I', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Binomial Theorem', 'Sets, Relations and Functions', 'Trigonometry', 'Straight Lines', 'Straight Lines', 'Matrices and Determinants', 'Matrices and Determinants', 'Straight Lines', 'Probability', 'Trigonometry', 'Conic Sections - II', 'Trigonometry', 'Sequence and Series', 'Sets, Relations and Functions', 'Mathematical Reasoning', 'Applications of Derivatives', 'Conic Sections - II', 'Limits', 'Complex Numbers', 'Statistics', 'Matrices and Determinants', 'Conic Sections - II', 'Limits', 'Conic Sections - II', 'Permutations and Combinations', 'Conic Sections - I', 'Conic Sections - II', 'Conic Sections - II', 'Trigonometry', 'Inequalities', 'Binomial Theorem', '3 Dimensional Geometry', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Applications of Derivatives', 'Quadratic Equations', 'Sequence and Series', 'Binomial Theorem', 'Straight Lines', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Trigonometry', 'Probability', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Conic Sections - II', 'Matrices and Determinants', 'Sequence and Series', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sets, Relations and Functions', 'Conic Sections - II', 'Fundamentals of Mathematics', 'Indefinite Integration', 'Sets, Relations and Functions', 'Conic Sections - II', 'Trigonometry', '3 Dimensional Geometry', 'Limits', 'Fundamentals of Mathematics', 'Inequalities', 'Straight Lines', 'Sets, Relations and Functions', 'Quadratic Equations', 'Quadratic Equations', 'Probability', 'Sequence and Series', 'Continuity and Differentiability', 'Quadratic Equations', 'Functions 2', 'Applications of Derivatives', 'Indefinite Integration', 'Continuity and Differentiability', 'Sequence and Series', 'Matrices and Determinants', 'Mathematical Reasoning', 'Sets, Relations and Functions', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Complex Numbers', 'Indefinite Integration', 'Quadratic Equations', 'Trigonometry', 'Complex Numbers', 'Quadratic Equations', 'Trigonometry', 'Complex Numbers', 'Inequalities', 'Trigonometry', 'Straight Lines', 'Conic Sections - II', 'Complex Numbers', 'Fundamentals of Mathematics', 'Definite Integration', 'Mathematical Reasoning', 'Conic Sections - II', 'Sets, Relations and Functions', 'Limits', 'Continuity and Differentiability', '3 Dimensional Geometry', 'Indefinite Integration', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Inverse Trigonometry ', 'Trigonometry', 'Conic Sections - II', 'Sequence and Series', 'Fundamentals of Mathematics', 'Matrices and Determinants', 'Fundamentals of Mathematics', 'Limits', 'Fundamentals of Mathematics', 'Sequence and Series', 'Mathematical Reasoning', 'Inequalities', 'Conic Sections - II', 'Fundamentals of Mathematics', 'Inequalities', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Trigonometry', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Probability', 'Sets, Relations and Functions', 'Indefinite Integration', 'Complex Numbers', 'Straight Lines', 'Binomial Theorem', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Limits', 'Applications of Derivatives', 'Conic Sections - II', 'Indefinite Integration', 'Permutations and Combinations', 'Statistics', 'Sets, Relations and Functions', 'Applications of Derivatives', 'Trigonometry', 'Permutations and Combinations', 'Conic Sections - I', 'Conic Sections - II', 'Vector Algebra', 'Complex Numbers', 'Fundamentals of Mathematics', 'Quadratic Equations', 'Trigonometry', 'Indefinite Integration', 'Binomial Theorem', 'Limits', 'Mathematical Reasoning', 'Inequalities', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Probability', 'Mathematical Reasoning', 'Sequence and Series', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Differential Equations', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Binomial Theorem', 'Sequence and Series', 'Continuity and Differentiability', 'Conic Sections - I', 'Complex Numbers', 'Indefinite Integration', 'Straight Lines', 'Limits', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Inverse Trigonometry ', 'Indefinite Integration', 'Straight Lines', 'Mathematical Reasoning', 'Limits', 'Trigonometry', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Indefinite Integration', 'Sets, Relations and Functions', 'Sets, Relations and Functions', '3 Dimensional Geometry', 'Binomial Theorem', 'Applications of Derivatives', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Straight Lines', 'Vector Algebra', 'Trigonometry', 'Conic Sections - I', 'Indefinite Integration', 'Statistics', 'Definite Integration', 'Conic Sections - II', 'Quadratic Equations', 'Straight Lines', 'Sets, Relations and Functions', 'Matrices and Determinants', 'Functions 2', 'Indefinite Integration', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', '3 Dimensional Geometry', 'Limits', 'Trigonometry', 'Sequence and Series', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Limits', 'Straight Lines', 'Conic Sections - II', 'Limits', 'Probability', 'Fundamentals of Mathematics', 'Limits', 'Vector Algebra', 'Quadratic Equations', 'Complex Numbers', 'Continuity and Differentiability', 'Straight Lines', 'Fundamentals of Mathematics', 'Trigonometry', 'Binomial Theorem', 'Continuity and Differentiability', 'Quadratic Equations', 'Trigonometry', 'Sequence and Series', 'Straight Lines', 'Fundamentals of Mathematics', 'Limits', 'Definite Integration', 'Indefinite Integration', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Permutations and Combinations', 'Sets, Relations and Functions', 'Binomial Theorem', 'Indefinite Integration', 'Complex Numbers', 'Sequence and Series', 'Conic Sections - I', 'Vector Algebra', 'Inequalities', 'Trigonometry', 'Indefinite Integration', 'Complex Numbers', 'Continuity and Differentiability', 'Permutations and Combinations', 'Straight Lines', 'Indefinite Integration', 'Fundamentals of Mathematics', '3 Dimensional Geometry', 'Definite Integration', 'Conic Sections - II', 'Conic Sections - I', 'Sets, Relations and Functions', 'Mathematical Reasoning', 'Complex Numbers', 'Complex Numbers', 'Sets, Relations and Functions', 'Straight Lines', 'Definite Integration', 'Fundamentals of Mathematics', 'Trigonometry', 'Conic Sections - I', 'Binomial Theorem', 'Matrices and Determinants', 'Permutations and Combinations', 'Conic Sections - I', 'Permutations and Combinations', 'Conic Sections - II', 'Conic Sections - I', 'Inverse Trigonometry ', 'Permutations and Combinations', 'Conic Sections - I', 'Trigonometry', 'Straight Lines', 'Fundamentals of Mathematics', 'Conic Sections - I', 'Sequence and Series', 'Functions 2', '3 Dimensional Geometry', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Permutations and Combinations', 'Matrices and Determinants', 'Binomial Theorem', 'Sets, Relations and Functions', 'Conic Sections - I', 'Matrices and Determinants', 'Definite Integration', 'Limits', 'Inequalities', 'Trigonometry', 'Limits', 'Trigonometry', 'Permutations and Combinations', 'Limits', 'Straight Lines', 'Functions 2', '3 Dimensional Geometry', 'Sequence and Series', 'Binomial Theorem', 'Applications of Derivatives', 'Straight Lines', 'Indefinite Integration', 'Straight Lines', 'Indefinite Integration', 'Conic Sections - I', 'Sets, Relations and Functions', 'Conic Sections - I', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Inequalities', 'Binomial Theorem', 'Quadratic Equations', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Sequence and Series', 'Quadratic Equations', 'Straight Lines', 'Vector Algebra', 'Conic Sections - II', 'Conic Sections - II', 'Inverse Trigonometry ', 'Conic Sections - I', 'Fundamentals of Mathematics', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Sequence and Series', 'Straight Lines', 'Inequalities', 'Indefinite Integration', 'Trigonometry', 'Complex Numbers', 'Fundamentals of Mathematics', 'Straight Lines', 'Indefinite Integration', 'Differential Equations', 'Conic Sections - II', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Indefinite Integration', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Vector Algebra', 'Statistics', 'Inequalities', 'Inequalities', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Sequence and Series', 'Sets, Relations and Functions', 'Conic Sections - I', 'Fundamentals of Mathematics', 'Matrices and Determinants', 'Sets, Relations and Functions', 'Matrices and Determinants', 'Mathematical Reasoning', 'Conic Sections - II', 'Sequence and Series', 'Inverse Trigonometry ', 'Permutations and Combinations', 'Continuity and Differentiability', 'Binomial Theorem', 'Sets, Relations and Functions', 'Sequence and Series', 'Fundamentals of Mathematics', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Trigonometry', 'Conic Sections - II', 'Trigonometry', 'Complex Numbers', 'Indefinite Integration', 'Sequence and Series', 'Trigonometry', 'Conic Sections - I', 'Complex Numbers', 'Inequalities', 'Trigonometry', 'Fundamentals of Mathematics', 'Conic Sections - I', 'Limits', 'Conic Sections - II', 'Matrices and Determinants', 'Conic Sections - I', 'Conic Sections - II', 'Complex Numbers', 'Applications of Derivatives', 'Conic Sections - I', 'Conic Sections - II', 'Trigonometry', 'Continuity and Differentiability', 'Conic Sections - II', 'Statistics', 'Conic Sections - II', 'Definite Integration', 'Inverse Trigonometry ', 'Inverse Trigonometry ', 'Sets, Relations and Functions', 'Permutations and Combinations', 'Straight Lines', 'Indefinite Integration', 'Quadratic Equations', 'Statistics', 'Indefinite Integration', 'Inequalities', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Complex Numbers', 'Functions 2', 'Sets, Relations and Functions', 'Matrices and Determinants', 'Indefinite Integration', 'Limits', 'Conic Sections - I', 'Fundamentals of Mathematics', 'Indefinite Integration', 'Indefinite Integration', 'Straight Lines', 'Functions 2', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Statistics', 'Sets, Relations and Functions', 'Inverse Trigonometry ', 'Indefinite Integration', 'Conic Sections - I', 'Limits', 'Indefinite Integration', 'Statistics', 'Binomial Theorem', 'Straight Lines', 'Inverse Trigonometry ', 'Indefinite Integration', 'Straight Lines', 'Sets, Relations and Functions', 'Matrices and Determinants', 'Fundamentals of Mathematics', 'Trigonometry', 'Continuity and Differentiability', 'Complex Numbers', 'Sets, Relations and Functions', 'Inequalities', '3 Dimensional Geometry', 'Conic Sections - I', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Statistics', 'Conic Sections - II', 'Indefinite Integration', 'Sets, Relations and Functions', 'Trigonometry', 'Sets, Relations and Functions', 'Continuity and Differentiability', 'Limits', 'Straight Lines', 'Matrices and Determinants', 'Inverse Trigonometry ', 'Trigonometry', 'Conic Sections - II', 'Complex Numbers', 'Mathematical Reasoning', 'Sequence and Series', 'Sequence and Series', 'Conic Sections - I', 'Continuity and Differentiability', '3 Dimensional Geometry', 'Sets, Relations and Functions', 'Statistics', 'Limits', 'Sets, Relations and Functions', 'Conic Sections - I', 'Binomial Theorem', 'Straight Lines', 'Conic Sections - II', 'Quadratic Equations', 'Mathematical Reasoning', 'Sequence and Series', 'Trigonometry', 'Sets, Relations and Functions', 'Vector Algebra', 'Conic Sections - II', 'Matrices and Determinants', 'Conic Sections - II', 'Sequence and Series', 'Quadratic Equations', 'Applications of Derivatives', 'Fundamentals of Mathematics', 'Indefinite Integration', 'Trigonometry', 'Permutations and Combinations', 'Conic Sections - II', 'Sequence and Series', 'Inverse Trigonometry ', 'Conic Sections - II', 'Conic Sections - II', 'Straight Lines', 'Permutations and Combinations', 'Trigonometry', 'Definite Integration', 'Indefinite Integration', 'Straight Lines', 'Applications of Derivatives', 'Indefinite Integration', 'Quadratic Equations', 'Trigonometry', 'Trigonometry', 'Conic Sections - II', 'Sequence and Series', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Complex Numbers', '3 Dimensional Geometry', 'Permutations and Combinations', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Functions 2', 'Quadratic Equations', 'Definite Integration', 'Mathematical Reasoning', 'Conic Sections - I', 'Conic Sections - I', 'Conic Sections - I', 'Inverse Trigonometry ', 'Functions 2', 'Inverse Trigonometry ', 'Conic Sections - II', 'Quadratic Equations', 'Vector Algebra', 'Inverse Trigonometry ', 'Conic Sections - II', 'Matrices and Determinants', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Complex Numbers', 'Indefinite Integration', 'Quadratic Equations', 'Functions 2', 'Inequalities', 'Straight Lines', '3 Dimensional Geometry', 'Indefinite Integration', 'Conic Sections - II', 'Probability', 'Fundamentals of Mathematics', 'Functions 2', 'Conic Sections - II', 'Quadratic Equations', 'Sets, Relations and Functions', 'Binomial Theorem', 'Statistics', 'Trigonometry', 'Fundamentals of Mathematics', 'Sequence and Series', 'Continuity and Differentiability', 'Indefinite Integration', 'Conic Sections - I', 'Conic Sections - II', 'Straight Lines', 'Quadratic Equations', 'Permutations and Combinations', 'Conic Sections - II', 'Conic Sections - II', 'Indefinite Integration', 'Conic Sections - II', 'Binomial Theorem', '3 Dimensional Geometry', 'Inverse Trigonometry ', 'Straight Lines', 'Straight Lines', 'Limits', 'Sets, Relations and Functions', '3 Dimensional Geometry', 'Binomial Theorem', 'Binomial Theorem', 'Conic Sections - II', 'Indefinite Integration', 'Quadratic Equations', 'Conic Sections - II', 'Indefinite Integration', 'Trigonometry', 'Limits', 'Mathematical Reasoning', 'Inequalities', 'Inequalities', 'Quadratic Equations', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Continuity and Differentiability', 'Trigonometry', 'Functions 2', 'Sequence and Series', 'Conic Sections - I', 'Continuity and Differentiability', 'Limits', 'Sequence and Series', 'Conic Sections - II', 'Binomial Theorem', 'Inverse Trigonometry ', 'Straight Lines', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Inverse Trigonometry ', 'Quadratic Equations', 'Applications of Derivatives', 'Matrices and Determinants', 'Conic Sections - II', 'Sequence and Series', 'Sets, Relations and Functions', 'Indefinite Integration', 'Sequence and Series', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Functions 2', 'Fundamentals of Mathematics', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Conic Sections - II', 'Continuity and Differentiability', 'Conic Sections - II', 'Definite Integration', 'Definite Integration', 'Complex Numbers', 'Limits', 'Permutations and Combinations', 'Permutations and Combinations', 'Binomial Theorem', 'Limits', 'Applications of Derivatives', 'Straight Lines', 'Probability', 'Trigonometry', 'Conic Sections - II', 'Straight Lines', 'Quadratic Equations', 'Straight Lines', 'Conic Sections - II', 'Sets, Relations and Functions', 'Definite Integration', 'Binomial Theorem', 'Statistics', 'Mathematical Reasoning', 'Probability', 'Continuity and Differentiability', 'Definite Integration', 'Statistics', 'Conic Sections - I', '3 Dimensional Geometry', 'Matrices and Determinants', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Fundamentals of Mathematics', 'Mathematical Reasoning', 'Conic Sections - II', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Trigonometry', '3 Dimensional Geometry', 'Probability', 'Trigonometry', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Limits', 'Trigonometry', 'Continuity and Differentiability', 'Complex Numbers', 'Sets, Relations and Functions', 'Quadratic Equations', 'Trigonometry', 'Sequence and Series', 'Vector Algebra', 'Sets, Relations and Functions', 'Conic Sections - I', 'Trigonometry', 'Indefinite Integration', 'Complex Numbers', 'Straight Lines', 'Definite Integration', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Definite Integration', 'Continuity and Differentiability', 'Definite Integration', 'Straight Lines', 'Permutations and Combinations', 'Continuity and Differentiability', 'Continuity and Differentiability', 'Indefinite Integration', 'Conic Sections - II', 'Conic Sections - II', 'Matrices and Determinants', 'Statistics', 'Mathematical Reasoning', 'Sets, Relations and Functions', 'Complex Numbers', 'Conic Sections - I', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Applications of Derivatives', 'Fundamentals of Mathematics', '3 Dimensional Geometry', '3 Dimensional Geometry', 'Binomial Theorem', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Straight Lines', 'Fundamentals of Mathematics', 'Mathematical Reasoning', 'Sequence and Series', 'Indefinite Integration', 'Vector Algebra', 'Conic Sections - I', 'Conic Sections - II', 'Probability', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Inequalities', 'Inequalities', 'Continuity and Differentiability', 'Definite Integration', 'Binomial Theorem', 'Indefinite Integration', 'Trigonometry', 'Applications of Derivatives', 'Conic Sections - II', 'Indefinite Integration', 'Functions 2', 'Quadratic Equations', 'Sets, Relations and Functions', 'Complex Numbers', 'Trigonometry', 'Limits', 'Inverse Trigonometry ', 'Inverse Trigonometry ', 'Sequence and Series', 'Complex Numbers', 'Fundamentals of Mathematics', 'Sequence and Series', 'Conic Sections - I', '3 Dimensional Geometry', 'Fundamentals of Mathematics', 'Sequence and Series', 'Fundamentals of Mathematics', 'Limits', 'Continuity and Differentiability', 'Complex Numbers', 'Limits', 'Mathematical Reasoning', 'Permutations and Combinations', 'Conic Sections - I', 'Statistics', 'Indefinite Integration', 'Conic Sections - II', 'Straight Lines', 'Indefinite Integration', 'Binomial Theorem', 'Binomial Theorem', 'Binomial Theorem', 'Permutations and Combinations', '3 Dimensional Geometry', 'Quadratic Equations', 'Indefinite Integration', 'Sets, Relations and Functions', 'Trigonometry', 'Quadratic Equations', 'Straight Lines', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Limits', 'Quadratic Equations', 'Sets, Relations and Functions', 'Definite Integration', 'Inverse Trigonometry ', 'Conic Sections - II', 'Straight Lines', 'Inequalities', 'Indefinite Integration', 'Limits', 'Conic Sections - II', 'Sets, Relations and Functions', 'Functions 2', 'Complex Numbers', 'Complex Numbers', 'Applications of Derivatives', 'Conic Sections - II', 'Binomial Theorem', 'Functions 2', 'Statistics', 'Binomial Theorem', 'Quadratic Equations', 'Matrices and Determinants', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Sequence and Series', 'Statistics', 'Fundamentals of Mathematics', 'Definite Integration', 'Inverse Trigonometry ', 'Probability', 'Limits', 'Fundamentals of Mathematics', 'Sequence and Series', 'Fundamentals of Mathematics', 'Continuity and Differentiability']
```


```r
### Writing to the DB

  for (label in levels(text_test_labels)) {
    
    groundTruth = which(text_test_labels == label)
    predTruth = which(results == label)
    
    falseNegatives = setDiff(groundTruth, predTruth)
    falsePositives = setDiff(predTruth, groundTruth)
    rowData <- c(rowData,)
    data_index = test_indices[i]
    
    problem = repo[data_index]
    
    
    # Get ground truth
    true_value = true_values[i]
    
    # Get top 5 predictions
    predictions = names( head(sort(rawResults[1,], decreasing=TRUE), 5) )
  }
 }

 top_five_stats = df.frame %>% group_by(V2) %>% summarize(n())
 top_five_accuracy = top_five_stats[2,2] / (top_five_stats[1,2] + top_five_stats[2,2])
```

