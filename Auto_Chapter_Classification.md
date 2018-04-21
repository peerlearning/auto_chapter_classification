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
## [1] "The locus of a point \\(P(\\alpha,\\beta)\\) moving under the condition that the line \\(y=\\alpha x+\\beta \\) is a tangent to the hyperbola \\(\\frac{x^2}{a^2}-\\frac{y^2}{b^2}=1\\) is an ellipse a circle a parabola a hyperbola We know that if a line \\(y=mx+c\\) is a tangent to the hyperbola \\(\\frac{x^2}{a^2}-\\frac{y^2}{b^2}=1\\), then \\(c=±\\sqrt{(a^2 m^2-b^2 )}\\).Comparing this with the given equation, \\(y=\\alpha x+\\beta \\) is a tangent to \\(\\frac{x^2}{a^2}-\\frac{y^2}{b^2}=1\\)\\(\\Rightarrow\\beta^2=a^2\\alpha^2-b^2\\)\\(\\therefore\\) Locus of \\((\\alpha, \\beta )\\) is \\(y^2=a^2x^2-b^2\\)\\(\\Rightarrow x^2=\\frac{1}{a^2}(y^2+b^2)\\), which is a hyperbola."
## 
## $`3`
## [1] "Let  \\(v ⃗=2i ̂+j ̂-k ̂\\) and  \\(w ⃗=i ̂+3k ̂\\). If \\(u ̂\\) is a unit vector, then the maximum value of the scalar triple product \\([u  v  w]\\) is \\(-1\\) \\(\\sqrt{10}+\\sqrt{16}\\) \\(\\sqrt{59}\\) \\(\\sqrt{60}\\) \\(v ⃗×w ⃗=3i ̂-7j ̂-k ̂\\)Now \\([u ⃗   v ⃗   w ⃗ ]=u ⃗.(3i ̂-7j ̂-k ̂ )=|u ⃗ ||3i ̂-7j ̂-k ̂ |\\cos⁡θ\\)(where \\(θ\\) is the angle between \\(u ⃗\\) and \\(v ⃗×w ⃗\\))Because \\(|u ⃗ |=1\\), hence \\([u ⃗   v ⃗   w ⃗ ]=1.\\sqrt{59}\\cos⁡θ\\)Thus \\([u ⃗   v ⃗   w ⃗]\\) is maximum if \\(\\cos⁡θ=1\\), i.e. \\(θ=0\\).Hence, maximum value of  \\([u ⃗   v ⃗   w ⃗ ]=\\sqrt{59}\\)"
## 
## $`4`
## [1] "Total number of ways in which \\(5\\) balls of different colours can be distributed among three persons so that each person gets at least one ball, is \\(75\\) \\(150\\) \\(210\\) \\(243\\) \\(5\\) balls can be distributed to \\(3\\) persons by giving \\((2, 2, 1)\\) balls or by giving \\((3, 1, 1)\\) balls. Each of the above distribution has three such ways. Thus, the required number of ways. \\(=(3) (^5C_2) (^3C_2) (^1C_1)+3(^5C_3) (^2C_1) (^1C_1)\\)\\(=(3) (10) (3) (1) +(3) (10) (2) (1)=150\\)"
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
## [1] "the locus point alpha beta moving under the condition that the line alpha beta tangent the hyperbola frac frac ellipse circle parabola hyperbola know that line tangent the hyperbola frac frac then sqrt comparing this with the given equation alpha beta tangent frac frac rightarrow beta alpha therefore locus alpha beta rightarrow frac which hyperbola "
## 
## $`3`
## [1] "let and unit vector then the maximum value the scalar triple product sqrt sqrt sqrt sqrt now cos where the angle between and because hence sqrt cos thus maximum cos hence maximum value sqrt "
## 
## $`4`
## [1] "total number ways which balls different colours can distributed among three persons that each person gets least one ball 150 210 243 balls can distributed persons giving balls giving balls each the above distribution has three such ways thus the required number ways 150 "
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
##                             1.93                             3.87 
##                 Binomial Theorem                  Complex Numbers 
##                             4.69                             6.16 
##               Conic Sections - I              Conic Sections - II 
##                             4.14                             6.70 
## Continuity and Differentiability             Definite Integration 
##                             4.31                             3.03 
##           Differential Equations                      Functions 2 
##                             1.09                             2.61 
##      Fundamentals of Mathematics           Indefinite Integration 
##                             5.99                             1.64 
##                     Inequalities            Inverse Trigonometry  
##                             4.01                             1.79 
##                           Limits           Mathematical Reasoning 
##                             2.88                             2.02 
##        Matrices and Determinants    Permutations and Combinations 
##                             2.46                             5.46 
##                      Probability              Quadratic Equations 
##                             2.44                             5.30 
##              Sequence and Series    Sets, Relations and Functions 
##                             5.51                             6.22 
##                       Statistics                   Straight Lines 
##                             2.52                             4.96 
##                     Trigonometry                   Vector Algebra 
##                             5.74                             2.52
```

## Distribution of labels in test set

```r
round(prop.table(table(text_test_labels))*100,2)
```

```
## text_test_labels
##           3 Dimensional Geometry      Applications of Derivatives 
##                             2.59                             3.59 
##                 Binomial Theorem                  Complex Numbers 
##                             4.65                             5.42 
##               Conic Sections - I              Conic Sections - II 
##                             5.49                             6.10 
## Continuity and Differentiability             Definite Integration 
##                             3.89                             2.75 
##           Differential Equations                      Functions 2 
##                             1.75                             1.68 
##      Fundamentals of Mathematics           Indefinite Integration 
##                             5.95                             1.60 
##                     Inequalities            Inverse Trigonometry  
##                             3.13                             1.75 
##                           Limits           Mathematical Reasoning 
##                             3.43                             2.67 
##        Matrices and Determinants    Permutations and Combinations 
##                             1.98                             5.64 
##                      Probability              Quadratic Equations 
##                             2.52                             5.03 
##              Sequence and Series    Sets, Relations and Functions 
##                             4.96                             7.32 
##                       Statistics                   Straight Lines 
##                             2.36                             5.64 
##                     Trigonometry                   Vector Algebra 
##                             5.72                             2.36
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
##     0.69641495     0.68222092     0.67072347     0.72122267     0.07322654 
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
## ['Straight Lines', 'Conic Sections - II', 'Vector Algebra', 'Permutations and Combinations', 'Sets, Relations and Functions', 'Complex Numbers', 'Sets, Relations and Functions', 'Complex Numbers', 'Conic Sections - I', 'Matrices and Determinants', 'Sets, Relations and Functions', 'Definite Integration', 'Complex Numbers', 'Conic Sections - II', 'Conic Sections - I', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Indefinite Integration', 'Straight Lines', 'Limits', 'Conic Sections - II', 'Continuity and Differentiability', 'Permutations and Combinations', 'Complex Numbers', 'Applications of Derivatives', 'Complex Numbers', 'Indefinite Integration', 'Indefinite Integration', 'Indefinite Integration', 'Limits', 'Continuity and Differentiability', 'Functions 2', 'Inequalities', 'Definite Integration', 'Complex Numbers', 'Definite Integration', 'Vector Algebra', 'Trigonometry', 'Continuity and Differentiability', 'Binomial Theorem', 'Conic Sections - I', 'Conic Sections - I', 'Statistics', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Permutations and Combinations', 'Conic Sections - II', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Conic Sections - I', 'Complex Numbers', 'Fundamentals of Mathematics', 'Sequence and Series', 'Trigonometry', 'Inverse Trigonometry ', 'Binomial Theorem', 'Indefinite Integration', 'Quadratic Equations', 'Indefinite Integration', 'Functions 2', 'Fundamentals of Mathematics', 'Probability', 'Conic Sections - II', 'Indefinite Integration', 'Functions 2', 'Quadratic Equations', 'Permutations and Combinations', 'Complex Numbers', 'Complex Numbers', 'Complex Numbers', 'Sets, Relations and Functions', '3 Dimensional Geometry', 'Binomial Theorem', 'Sets, Relations and Functions', 'Mathematical Reasoning', 'Conic Sections - II', 'Applications of Derivatives', 'Limits', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Applications of Derivatives', 'Trigonometry', 'Binomial Theorem', 'Conic Sections - II', 'Straight Lines', 'Inequalities', 'Indefinite Integration', 'Sets, Relations and Functions', 'Conic Sections - I', 'Straight Lines', 'Functions 2', 'Inequalities', 'Definite Integration', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Probability', 'Functions 2', 'Fundamentals of Mathematics', 'Continuity and Differentiability', 'Permutations and Combinations', 'Definite Integration', 'Continuity and Differentiability', 'Inverse Trigonometry ', 'Vector Algebra', 'Matrices and Determinants', 'Differential Equations', 'Sequence and Series', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Quadratic Equations', 'Inequalities', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Trigonometry', 'Indefinite Integration', 'Straight Lines', 'Matrices and Determinants', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Applications of Derivatives', 'Fundamentals of Mathematics', 'Indefinite Integration', 'Continuity and Differentiability', 'Straight Lines', 'Sequence and Series', 'Inverse Trigonometry ', 'Mathematical Reasoning', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Applications of Derivatives', 'Straight Lines', 'Conic Sections - II', 'Fundamentals of Mathematics', 'Inequalities', 'Sequence and Series', 'Binomial Theorem', 'Limits', 'Indefinite Integration', 'Continuity and Differentiability', 'Binomial Theorem', 'Continuity and Differentiability', 'Indefinite Integration', 'Mathematical Reasoning', 'Complex Numbers', 'Straight Lines', 'Indefinite Integration', 'Statistics', 'Conic Sections - II', 'Conic Sections - II', 'Binomial Theorem', 'Limits', 'Quadratic Equations', 'Continuity and Differentiability', 'Limits', 'Statistics', 'Fundamentals of Mathematics', 'Trigonometry', 'Sets, Relations and Functions', 'Applications of Derivatives', 'Quadratic Equations', 'Conic Sections - II', 'Definite Integration', 'Fundamentals of Mathematics', 'Sequence and Series', 'Inverse Trigonometry ', 'Applications of Derivatives', 'Continuity and Differentiability', 'Sequence and Series', 'Indefinite Integration', 'Inequalities', 'Statistics', 'Complex Numbers', 'Conic Sections - I', 'Sequence and Series', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Trigonometry', 'Sequence and Series', 'Binomial Theorem', 'Limits', 'Fundamentals of Mathematics', 'Continuity and Differentiability', 'Binomial Theorem', 'Sequence and Series', 'Applications of Derivatives', 'Straight Lines', '3 Dimensional Geometry', 'Probability', 'Sets, Relations and Functions', 'Permutations and Combinations', 'Quadratic Equations', 'Inequalities', 'Definite Integration', 'Complex Numbers', 'Matrices and Determinants', 'Statistics', 'Conic Sections - II', 'Quadratic Equations', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Inequalities', 'Straight Lines', 'Statistics', '3 Dimensional Geometry', 'Limits', 'Continuity and Differentiability', 'Trigonometry', 'Definite Integration', 'Sequence and Series', 'Trigonometry', 'Conic Sections - II', 'Continuity and Differentiability', 'Inequalities', 'Continuity and Differentiability', 'Mathematical Reasoning', 'Binomial Theorem', 'Limits', 'Conic Sections - I', 'Sets, Relations and Functions', 'Straight Lines', 'Binomial Theorem', 'Sets, Relations and Functions', 'Conic Sections - I', 'Definite Integration', 'Sets, Relations and Functions', 'Straight Lines', 'Trigonometry', 'Fundamentals of Mathematics', 'Trigonometry', 'Indefinite Integration', 'Trigonometry', 'Trigonometry', 'Sequence and Series', 'Complex Numbers', 'Limits', 'Conic Sections - II', 'Quadratic Equations', 'Complex Numbers', 'Sequence and Series', 'Conic Sections - II', 'Inequalities', 'Complex Numbers', 'Applications of Derivatives', 'Fundamentals of Mathematics', 'Trigonometry', 'Quadratic Equations', 'Sets, Relations and Functions', 'Limits', 'Inverse Trigonometry ', 'Sequence and Series', 'Straight Lines', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Inequalities', 'Sets, Relations and Functions', 'Sequence and Series', '3 Dimensional Geometry', 'Permutations and Combinations', 'Limits', 'Limits', 'Conic Sections - II', 'Vector Algebra', '3 Dimensional Geometry', 'Trigonometry', 'Conic Sections - II', 'Vector Algebra', 'Conic Sections - II', 'Binomial Theorem', 'Straight Lines', 'Conic Sections - II', 'Statistics', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sets, Relations and Functions', 'Definite Integration', 'Fundamentals of Mathematics', 'Straight Lines', 'Matrices and Determinants', 'Matrices and Determinants', 'Quadratic Equations', 'Differential Equations', 'Statistics', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Inverse Trigonometry ', 'Indefinite Integration', 'Inverse Trigonometry ', 'Sets, Relations and Functions', 'Straight Lines', 'Sequence and Series', 'Fundamentals of Mathematics', 'Continuity and Differentiability', '3 Dimensional Geometry', 'Conic Sections - II', 'Definite Integration', 'Differential Equations', 'Conic Sections - I', 'Conic Sections - II', '3 Dimensional Geometry', 'Limits', 'Binomial Theorem', 'Sequence and Series', 'Sets, Relations and Functions', 'Indefinite Integration', '3 Dimensional Geometry', 'Sequence and Series', 'Trigonometry', 'Inequalities', 'Sets, Relations and Functions', 'Straight Lines', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Complex Numbers', 'Continuity and Differentiability', 'Matrices and Determinants', 'Matrices and Determinants', 'Limits', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Matrices and Determinants', 'Straight Lines', 'Conic Sections - I', 'Definite Integration', 'Quadratic Equations', 'Limits', 'Permutations and Combinations', 'Permutations and Combinations', '3 Dimensional Geometry', 'Inverse Trigonometry ', 'Differential Equations', 'Inequalities', 'Binomial Theorem', 'Mathematical Reasoning', 'Statistics', 'Inverse Trigonometry ', 'Indefinite Integration', 'Probability', 'Conic Sections - I', 'Fundamentals of Mathematics', '3 Dimensional Geometry', 'Straight Lines', 'Limits', 'Conic Sections - II', 'Binomial Theorem', 'Conic Sections - II', 'Indefinite Integration', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Sequence and Series', 'Straight Lines', 'Sequence and Series', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Quadratic Equations', 'Trigonometry', 'Mathematical Reasoning', 'Vector Algebra', 'Binomial Theorem', 'Applications of Derivatives', 'Straight Lines', 'Inequalities', 'Permutations and Combinations', 'Conic Sections - I', 'Permutations and Combinations', 'Conic Sections - II', 'Fundamentals of Mathematics', 'Straight Lines', 'Permutations and Combinations', 'Indefinite Integration', 'Permutations and Combinations', 'Limits', '3 Dimensional Geometry', 'Conic Sections - II', 'Trigonometry', 'Conic Sections - II', 'Sets, Relations and Functions', 'Indefinite Integration', 'Sequence and Series', 'Indefinite Integration', 'Limits', 'Inverse Trigonometry ', 'Indefinite Integration', 'Statistics', 'Applications of Derivatives', 'Applications of Derivatives', 'Matrices and Determinants', 'Complex Numbers', 'Indefinite Integration', 'Matrices and Determinants', 'Trigonometry', 'Statistics', 'Continuity and Differentiability', 'Sequence and Series', 'Complex Numbers', 'Trigonometry', 'Inverse Trigonometry ', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Applications of Derivatives', 'Conic Sections - I', 'Permutations and Combinations', 'Sequence and Series', 'Conic Sections - I', 'Differential Equations', '3 Dimensional Geometry', 'Inverse Trigonometry ', 'Probability', 'Permutations and Combinations', 'Conic Sections - II', 'Sets, Relations and Functions', 'Permutations and Combinations', 'Definite Integration', 'Complex Numbers', 'Quadratic Equations', 'Trigonometry', 'Sets, Relations and Functions', 'Complex Numbers', 'Conic Sections - II', 'Complex Numbers', 'Binomial Theorem', 'Trigonometry', '3 Dimensional Geometry', 'Continuity and Differentiability', 'Inequalities', 'Straight Lines', '3 Dimensional Geometry', 'Inequalities', 'Probability', 'Statistics', 'Straight Lines', 'Sequence and Series', 'Sets, Relations and Functions', 'Inequalities', 'Fundamentals of Mathematics', 'Trigonometry', 'Straight Lines', 'Applications of Derivatives', 'Complex Numbers', 'Inverse Trigonometry ', 'Continuity and Differentiability', 'Limits', 'Conic Sections - I', 'Complex Numbers', 'Mathematical Reasoning', 'Mathematical Reasoning', 'Indefinite Integration', 'Statistics', 'Limits', 'Limits', 'Statistics', 'Trigonometry', 'Trigonometry', 'Complex Numbers', 'Conic Sections - II', 'Conic Sections - I', 'Definite Integration', 'Complex Numbers', 'Conic Sections - I', 'Binomial Theorem', 'Complex Numbers', 'Continuity and Differentiability', 'Permutations and Combinations', 'Trigonometry', 'Permutations and Combinations', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Trigonometry', 'Binomial Theorem', 'Functions 2', 'Fundamentals of Mathematics', 'Inequalities', 'Quadratic Equations', 'Applications of Derivatives', 'Quadratic Equations', 'Sets, Relations and Functions', 'Straight Lines', 'Straight Lines', 'Fundamentals of Mathematics', 'Functions 2', 'Inverse Trigonometry ', 'Straight Lines', 'Complex Numbers', 'Vector Algebra', 'Trigonometry', 'Sequence and Series', 'Straight Lines', 'Sets, Relations and Functions', '3 Dimensional Geometry', 'Quadratic Equations', 'Conic Sections - II', 'Fundamentals of Mathematics', 'Vector Algebra', 'Conic Sections - II', 'Sequence and Series', 'Applications of Derivatives', 'Indefinite Integration', 'Fundamentals of Mathematics', 'Conic Sections - I', 'Limits', 'Indefinite Integration', 'Sequence and Series', 'Indefinite Integration', 'Sequence and Series', 'Sets, Relations and Functions', 'Mathematical Reasoning', 'Inequalities', 'Applications of Derivatives', 'Fundamentals of Mathematics', 'Binomial Theorem', 'Sets, Relations and Functions', '3 Dimensional Geometry', 'Limits', 'Mathematical Reasoning', 'Complex Numbers', 'Conic Sections - I', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Continuity and Differentiability', 'Binomial Theorem', 'Vector Algebra', 'Sequence and Series', 'Fundamentals of Mathematics', 'Trigonometry', 'Indefinite Integration', 'Indefinite Integration', 'Permutations and Combinations', 'Indefinite Integration', 'Fundamentals of Mathematics', 'Functions 2', 'Sets, Relations and Functions', 'Definite Integration', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Conic Sections - I', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sequence and Series', 'Conic Sections - I', 'Mathematical Reasoning', 'Quadratic Equations', 'Inequalities', 'Straight Lines', 'Quadratic Equations', 'Sequence and Series', 'Complex Numbers', 'Binomial Theorem', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Trigonometry', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Probability', 'Conic Sections - II', 'Inequalities', 'Mathematical Reasoning', 'Binomial Theorem', 'Probability', '3 Dimensional Geometry', 'Permutations and Combinations', 'Matrices and Determinants', 'Vector Algebra', 'Probability', 'Binomial Theorem', 'Conic Sections - II', 'Quadratic Equations', 'Sets, Relations and Functions', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Functions 2', 'Continuity and Differentiability', 'Vector Algebra', 'Differential Equations', 'Limits', '3 Dimensional Geometry', 'Inequalities', 'Trigonometry', 'Sets, Relations and Functions', 'Sequence and Series', 'Sets, Relations and Functions', 'Complex Numbers', 'Conic Sections - II', 'Sets, Relations and Functions', 'Straight Lines', 'Conic Sections - I', 'Inverse Trigonometry ', 'Fundamentals of Mathematics', 'Inequalities', 'Indefinite Integration', 'Sets, Relations and Functions', 'Conic Sections - I', 'Matrices and Determinants', 'Conic Sections - II', 'Mathematical Reasoning', 'Quadratic Equations', 'Complex Numbers', 'Matrices and Determinants', 'Limits', 'Continuity and Differentiability', 'Binomial Theorem', 'Differential Equations', 'Conic Sections - I', 'Mathematical Reasoning', 'Quadratic Equations', 'Probability', 'Definite Integration', 'Fundamentals of Mathematics', 'Applications of Derivatives', 'Binomial Theorem', 'Conic Sections - I', 'Quadratic Equations', 'Complex Numbers', 'Conic Sections - II', 'Quadratic Equations', 'Sets, Relations and Functions', 'Conic Sections - II', 'Straight Lines', 'Sequence and Series', 'Quadratic Equations', 'Straight Lines', 'Sequence and Series', 'Trigonometry', 'Complex Numbers', 'Permutations and Combinations', 'Straight Lines', 'Quadratic Equations', 'Vector Algebra', 'Inequalities', 'Binomial Theorem', 'Sequence and Series', 'Complex Numbers', 'Straight Lines', 'Sets, Relations and Functions', 'Conic Sections - I', 'Indefinite Integration', 'Fundamentals of Mathematics', 'Indefinite Integration', 'Quadratic Equations', 'Complex Numbers', 'Conic Sections - I', 'Indefinite Integration', 'Limits', 'Binomial Theorem', 'Conic Sections - I', 'Sets, Relations and Functions', 'Mathematical Reasoning', 'Conic Sections - II', 'Continuity and Differentiability', 'Binomial Theorem', 'Definite Integration', 'Straight Lines', 'Indefinite Integration', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Matrices and Determinants', 'Trigonometry', 'Trigonometry', 'Indefinite Integration', 'Conic Sections - II', 'Sequence and Series', 'Mathematical Reasoning', 'Quadratic Equations', 'Mathematical Reasoning', 'Indefinite Integration', 'Straight Lines', 'Straight Lines', 'Straight Lines', '3 Dimensional Geometry', 'Conic Sections - II', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Limits', 'Sequence and Series', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Inverse Trigonometry ', 'Definite Integration', 'Quadratic Equations', 'Probability', 'Applications of Derivatives', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Matrices and Determinants', 'Sets, Relations and Functions', 'Inverse Trigonometry ', 'Matrices and Determinants', 'Complex Numbers', 'Indefinite Integration', 'Fundamentals of Mathematics', 'Inequalities', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Indefinite Integration', 'Indefinite Integration', 'Continuity and Differentiability', 'Mathematical Reasoning', 'Matrices and Determinants', 'Sequence and Series', 'Functions 2', 'Sets, Relations and Functions', 'Straight Lines', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Indefinite Integration', 'Sets, Relations and Functions', 'Quadratic Equations', 'Binomial Theorem', 'Binomial Theorem', 'Sequence and Series', 'Vector Algebra', 'Inequalities', 'Conic Sections - I', 'Limits', 'Binomial Theorem', 'Mathematical Reasoning', 'Sets, Relations and Functions', 'Sequence and Series', 'Conic Sections - II', 'Trigonometry', 'Probability', 'Fundamentals of Mathematics', 'Inequalities', 'Conic Sections - I', 'Inverse Trigonometry ', 'Indefinite Integration', 'Straight Lines', 'Trigonometry', 'Fundamentals of Mathematics', 'Sequence and Series', 'Quadratic Equations', 'Quadratic Equations', 'Continuity and Differentiability', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Quadratic Equations', 'Indefinite Integration', 'Straight Lines', 'Limits', 'Trigonometry', 'Inverse Trigonometry ', 'Continuity and Differentiability', 'Sets, Relations and Functions', 'Straight Lines', 'Indefinite Integration', 'Trigonometry', 'Straight Lines', 'Vector Algebra', 'Permutations and Combinations', 'Indefinite Integration', 'Straight Lines', 'Complex Numbers', 'Functions 2', 'Limits', 'Applications of Derivatives', 'Continuity and Differentiability', 'Continuity and Differentiability', 'Limits', 'Conic Sections - I', 'Conic Sections - I', 'Conic Sections - I', '3 Dimensional Geometry', 'Sets, Relations and Functions', 'Quadratic Equations', 'Matrices and Determinants', 'Straight Lines', 'Quadratic Equations', 'Vector Algebra', '3 Dimensional Geometry', 'Straight Lines', 'Conic Sections - I', 'Complex Numbers', 'Matrices and Determinants', 'Quadratic Equations', '3 Dimensional Geometry', 'Conic Sections - II', 'Indefinite Integration', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Continuity and Differentiability', 'Applications of Derivatives', 'Functions 2', 'Sets, Relations and Functions', 'Probability', 'Continuity and Differentiability', 'Matrices and Determinants', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Sequence and Series', 'Continuity and Differentiability', 'Conic Sections - I', 'Complex Numbers', 'Vector Algebra', 'Conic Sections - II', 'Differential Equations', 'Inequalities', 'Functions 2', 'Mathematical Reasoning', 'Limits', 'Functions 2', 'Indefinite Integration', 'Quadratic Equations', 'Conic Sections - I', 'Inverse Trigonometry ', 'Binomial Theorem', 'Straight Lines', 'Trigonometry', 'Permutations and Combinations', 'Straight Lines', 'Sets, Relations and Functions', 'Conic Sections - II', 'Trigonometry', 'Complex Numbers', 'Sequence and Series', 'Vector Algebra', 'Inequalities', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sets, Relations and Functions', 'Sequence and Series', 'Sequence and Series', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Conic Sections - I', 'Trigonometry', 'Trigonometry', 'Sets, Relations and Functions', 'Conic Sections - I', 'Complex Numbers', 'Inverse Trigonometry ', 'Limits', 'Complex Numbers', 'Functions 2', 'Conic Sections - I', 'Differential Equations', 'Applications of Derivatives', 'Sets, Relations and Functions', 'Indefinite Integration', 'Conic Sections - II', 'Straight Lines', 'Applications of Derivatives', '3 Dimensional Geometry', 'Conic Sections - I', 'Sets, Relations and Functions', 'Indefinite Integration', 'Matrices and Determinants', 'Complex Numbers', 'Definite Integration', 'Statistics', 'Conic Sections - I', 'Inverse Trigonometry ', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Indefinite Integration', 'Permutations and Combinations', 'Sequence and Series', 'Conic Sections - II', 'Continuity and Differentiability', 'Straight Lines', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Trigonometry', 'Sets, Relations and Functions', '3 Dimensional Geometry', 'Straight Lines', 'Indefinite Integration', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Conic Sections - II', 'Trigonometry', 'Continuity and Differentiability', 'Statistics', 'Quadratic Equations', 'Straight Lines', 'Conic Sections - II', 'Indefinite Integration', 'Straight Lines', 'Complex Numbers', 'Conic Sections - I', 'Fundamentals of Mathematics', 'Conic Sections - I', 'Fundamentals of Mathematics', 'Continuity and Differentiability', 'Probability', 'Differential Equations', 'Conic Sections - I', 'Vector Algebra', 'Straight Lines', 'Functions 2', 'Applications of Derivatives', 'Continuity and Differentiability', 'Conic Sections - II', 'Statistics', 'Conic Sections - II', 'Permutations and Combinations', 'Permutations and Combinations', 'Quadratic Equations', 'Mathematical Reasoning', 'Applications of Derivatives', 'Functions 2', 'Applications of Derivatives', 'Complex Numbers', 'Sequence and Series', 'Straight Lines', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Sets, Relations and Functions', 'Binomial Theorem', 'Functions 2', 'Conic Sections - II', 'Indefinite Integration', 'Probability', 'Applications of Derivatives', 'Sequence and Series', 'Sets, Relations and Functions', 'Sets, Relations and Functions', 'Complex Numbers', 'Applications of Derivatives', 'Matrices and Determinants', 'Binomial Theorem', 'Indefinite Integration', 'Permutations and Combinations', 'Mathematical Reasoning', 'Inequalities', 'Quadratic Equations', 'Binomial Theorem', 'Statistics', 'Sequence and Series', 'Quadratic Equations', 'Complex Numbers', 'Complex Numbers', 'Trigonometry', 'Conic Sections - I', 'Statistics', 'Conic Sections - II', 'Indefinite Integration', 'Conic Sections - I', 'Indefinite Integration', 'Differential Equations', '3 Dimensional Geometry', 'Permutations and Combinations', '3 Dimensional Geometry', 'Permutations and Combinations', 'Binomial Theorem', 'Probability', 'Binomial Theorem', 'Mathematical Reasoning', 'Conic Sections - I', 'Quadratic Equations', 'Statistics', 'Limits', 'Binomial Theorem', 'Vector Algebra', 'Complex Numbers', 'Permutations and Combinations', 'Straight Lines', 'Indefinite Integration', 'Quadratic Equations', 'Trigonometry', 'Conic Sections - II', 'Inverse Trigonometry ', 'Sequence and Series', 'Continuity and Differentiability', 'Sequence and Series', 'Probability', 'Continuity and Differentiability', 'Mathematical Reasoning', 'Continuity and Differentiability', 'Straight Lines', 'Vector Algebra', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Continuity and Differentiability', 'Statistics', 'Inverse Trigonometry ', '3 Dimensional Geometry', 'Permutations and Combinations', 'Quadratic Equations', 'Inverse Trigonometry ', 'Trigonometry', 'Sets, Relations and Functions', 'Trigonometry', 'Sets, Relations and Functions', 'Inequalities', 'Continuity and Differentiability', 'Functions 2', 'Permutations and Combinations', 'Conic Sections - II', 'Indefinite Integration', 'Inverse Trigonometry ', 'Inverse Trigonometry ', 'Applications of Derivatives', 'Mathematical Reasoning', 'Statistics', 'Quadratic Equations', 'Straight Lines', 'Sets, Relations and Functions', 'Conic Sections - II', 'Conic Sections - I', 'Permutations and Combinations', 'Permutations and Combinations', 'Statistics', 'Definite Integration', 'Straight Lines', 'Trigonometry', 'Applications of Derivatives', 'Binomial Theorem', 'Straight Lines', 'Quadratic Equations', 'Sets, Relations and Functions', 'Mathematical Reasoning', 'Conic Sections - I', 'Straight Lines', 'Indefinite Integration', 'Conic Sections - I', 'Conic Sections - I', 'Permutations and Combinations', 'Fundamentals of Mathematics', 'Permutations and Combinations', 'Conic Sections - I', 'Sets, Relations and Functions', 'Definite Integration', 'Binomial Theorem', 'Complex Numbers', 'Definite Integration', 'Quadratic Equations', 'Continuity and Differentiability', 'Limits', 'Indefinite Integration', 'Continuity and Differentiability', 'Limits', 'Conic Sections - II', 'Straight Lines', 'Inequalities', 'Binomial Theorem', 'Quadratic Equations', 'Inequalities', 'Permutations and Combinations', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Applications of Derivatives', 'Matrices and Determinants', 'Sequence and Series', 'Straight Lines', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Applications of Derivatives', 'Inequalities', 'Permutations and Combinations', 'Limits', 'Applications of Derivatives', 'Conic Sections - I', 'Binomial Theorem', 'Statistics', 'Inverse Trigonometry ', 'Conic Sections - II', 'Fundamentals of Mathematics', 'Straight Lines', 'Matrices and Determinants', 'Limits', 'Mathematical Reasoning', 'Differential Equations', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Inequalities', 'Matrices and Determinants', 'Indefinite Integration', 'Mathematical Reasoning', 'Sequence and Series', 'Sets, Relations and Functions', 'Trigonometry', 'Fundamentals of Mathematics', 'Limits', 'Differential Equations', 'Sets, Relations and Functions', 'Binomial Theorem', 'Permutations and Combinations', 'Binomial Theorem', 'Matrices and Determinants', 'Permutations and Combinations', 'Definite Integration', 'Matrices and Determinants', 'Continuity and Differentiability', 'Indefinite Integration', 'Limits', 'Probability', 'Vector Algebra', 'Binomial Theorem', 'Conic Sections - II', 'Vector Algebra', 'Permutations and Combinations', 'Trigonometry', 'Sequence and Series', 'Fundamentals of Mathematics', 'Applications of Derivatives', 'Conic Sections - II', 'Permutations and Combinations', 'Complex Numbers', 'Functions 2', 'Quadratic Equations', 'Indefinite Integration', 'Conic Sections - II', 'Matrices and Determinants', 'Quadratic Equations', 'Conic Sections - I', 'Conic Sections - I', 'Trigonometry', 'Functions 2', 'Inequalities', 'Straight Lines', 'Continuity and Differentiability', 'Conic Sections - I', 'Straight Lines', 'Conic Sections - I', 'Definite Integration', 'Trigonometry', 'Sets, Relations and Functions', 'Probability', 'Straight Lines', 'Mathematical Reasoning', 'Statistics', 'Inequalities', 'Sequence and Series', 'Limits', 'Conic Sections - II', 'Conic Sections - II', 'Conic Sections - I', 'Quadratic Equations', 'Vector Algebra', 'Straight Lines', 'Vector Algebra', '3 Dimensional Geometry', 'Sequence and Series', 'Matrices and Determinants', 'Differential Equations', 'Sets, Relations and Functions', 'Probability', 'Probability', 'Fundamentals of Mathematics', 'Applications of Derivatives', 'Probability', 'Conic Sections - I', 'Fundamentals of Mathematics', 'Statistics', 'Indefinite Integration', 'Conic Sections - I', 'Straight Lines', 'Probability', 'Straight Lines', 'Trigonometry', 'Conic Sections - I', 'Quadratic Equations', 'Indefinite Integration', 'Sequence and Series', 'Sets, Relations and Functions', 'Straight Lines', 'Binomial Theorem', 'Conic Sections - II', 'Indefinite Integration', 'Inequalities', 'Applications of Derivatives', 'Fundamentals of Mathematics', 'Trigonometry', 'Mathematical Reasoning', 'Trigonometry', 'Sets, Relations and Functions', 'Vector Algebra', 'Limits', 'Applications of Derivatives', 'Quadratic Equations', 'Inequalities', 'Trigonometry', 'Indefinite Integration', 'Straight Lines', 'Limits', 'Complex Numbers', 'Indefinite Integration', 'Conic Sections - I', 'Conic Sections - II', 'Differential Equations', 'Inequalities', 'Quadratic Equations', 'Conic Sections - I', 'Straight Lines', 'Trigonometry', 'Straight Lines', 'Functions 2', 'Definite Integration', 'Straight Lines', 'Mathematical Reasoning', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Continuity and Differentiability', 'Trigonometry', '3 Dimensional Geometry', 'Sets, Relations and Functions', 'Quadratic Equations', 'Permutations and Combinations', 'Trigonometry', 'Inequalities', 'Inverse Trigonometry ', 'Conic Sections - II', 'Sequence and Series', 'Inequalities', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sequence and Series', 'Conic Sections - I', 'Inequalities', 'Permutations and Combinations', 'Sequence and Series', 'Quadratic Equations', 'Complex Numbers', 'Applications of Derivatives', 'Definite Integration', 'Fundamentals of Mathematics', 'Inequalities', 'Conic Sections - II', 'Continuity and Differentiability', 'Permutations and Combinations', 'Indefinite Integration', 'Complex Numbers', 'Straight Lines', 'Sets, Relations and Functions', 'Vector Algebra', 'Complex Numbers', 'Fundamentals of Mathematics', 'Matrices and Determinants', 'Applications of Derivatives', 'Fundamentals of Mathematics', 'Complex Numbers', 'Inverse Trigonometry ', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', 'Complex Numbers', 'Permutations and Combinations', 'Applications of Derivatives', 'Complex Numbers', 'Definite Integration', 'Binomial Theorem', 'Sets, Relations and Functions', 'Sequence and Series', 'Indefinite Integration', 'Conic Sections - II', 'Sequence and Series', 'Indefinite Integration', 'Conic Sections - II', 'Complex Numbers', 'Functions 2', 'Conic Sections - II', 'Conic Sections - II', 'Permutations and Combinations', 'Complex Numbers', 'Straight Lines', 'Probability', 'Sets, Relations and Functions', 'Indefinite Integration', 'Trigonometry', 'Conic Sections - I', 'Indefinite Integration', 'Straight Lines', 'Conic Sections - II', 'Conic Sections - II', 'Conic Sections - I', 'Trigonometry', 'Sequence and Series', 'Continuity and Differentiability', 'Fundamentals of Mathematics', 'Straight Lines', 'Statistics', 'Fundamentals of Mathematics', 'Fundamentals of Mathematics', '3 Dimensional Geometry', 'Statistics', 'Sets, Relations and Functions', 'Permutations and Combinations', 'Quadratic Equations', 'Fundamentals of Mathematics', 'Sequence and Series', 'Differential Equations', 'Permutations and Combinations', 'Quadratic Equations', 'Binomial Theorem', 'Fundamentals of Mathematics', 'Trigonometry', 'Conic Sections - I', 'Limits', 'Applications of Derivatives', 'Sets, Relations and Functions', 'Fundamentals of Mathematics', 'Conic Sections - II', 'Sequence and Series', 'Mathematical Reasoning', 'Binomial Theorem', 'Straight Lines', 'Straight Lines', 'Conic Sections - II', 'Binomial Theorem', 'Statistics', 'Conic Sections - I', 'Fundamentals of Mathematics', 'Trigonometry']
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

