# Automatic Chapter Classification

**Goal**: Automatically tag Qs to respective chapters on CMS

**Problem Statement**: Currently, to be able to add any Q on CMS, the creator needs to tag its syllabus, chapter, topic etc. This causes a significant delay since tagging a Q to one of the 30 chapters in JEE Chemistry, say, is a non-trivial process, and needs the time of curriulum creator. This process needs to be done 90 times for getting a single JEE Main mock paper typed. 

To speed up our question creation process on CMS, we should be able to automatically classify a Question into any of the given chapters for a particular syllabus, using its text.

**Great reference**: 
A great reference for this problem is [this paper](https://github.com/peerlearning/auto_chapter_classification/blob/master/Useful_Literature/Question%20Topic%20Categorization.pdf) which goes over a lot of the choices that we have to make.

## Running the code

### R Code

You can directly work on the RStudio file and all everything will run **except the python code**. There is an issue with RStudio that somehow doesn't let data be shared between R and python.

### R and Python code


Make all the changes you want, and then:

1. "Source" the runRmd.R from within RStudio
2. Run from the command line:

```
Rscript runRmd.R
```

This will generate a file called `report.html` with a nice output and all that.


## Parameters

These are the choices we have to make while using this:

1. **How to parse the questions**: The questions come from CMS and include:
    1. Question Text
    2. Options
    3. Solutions
    Which combination of the above performs best?
    **Current option**: All of the above. However, maybe we should omit solutions because later, when questions are given as input, they will mostly be entered without solutions (True?)
2. **How to clean the question data**: These are the options we have and decisions need to be made for each of them:
    1. Removing non-UTF8 characters (\u0080-\uffff in [the UTF8 character set](http://www.utf8-chartable.de/)
    2. Trimming all extra whitespace
    3. Removing numbers (*Is this a good idea?*)
    4. Stop words ("is", "of", etc.) (*Is this a good idea?*)
    5. Removing non-alphanumeric characters (*This is probably a good idea*)
3. **Vectorizations**: Options are:
    1. *Bag of words* with or without *n-grams*
4. **Features**: These are our current choices:
    1. [Term Frequency](https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Term_frequency)
    2. [TF-IDF](https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Term_frequency%E2%80%93Inverse_document_frequency)
    3. [Latent Symantic Analysis (LSA)](https://en.wikipedia.org/wiki/Latent_semantic_analysis): [Nice PDF link](lsa.colorado.edu/papers/dp1.LSAintro.pdf)
    4. Other questions we have to ask
        1. How do we include **domain-specific knowledge** (equations, chemical symbols, etc.)
5. **Algorithm used**: These are some popular choices
    1. [Naive Bayes](https://nlp.stanford.edu/IR-book/html/htmledition/naive-bayes-text-classification-1.html)
    2. SVM
    3. Random Forests
    4. kNNs
    5. ...
    6. ...
    7. Some form of **Deep Learning** using TensorFlow
            - [Gluon](https://github.com/dmlc/gluon-nlp) : Deep Learning for NLP
            - Also, see references for glove :
                [7](https://towardsdatascience.com/understanding-feature-engineering-part-4-deep-learning-methods-for-text-data-96c44370bbfa)
                [8](https://github.com/stanfordnlp/GloVe#train-word-vectors-on-a-new-corpus)

8. **Measure of accuracy**: Some choices that we have:
    1. Confusion Matrix: Good because it tells us about the cross category performance. A little bad because it does not deal well with dataset imbalance, which we have a bit of.
    2. Specificity, Sensitivity, Precision, Recall: All the fancy things
    3. F-Score: Major F-score and Minor F-score
    The problem with 2 and 3 above is that they deal only with binary data. In fact, Major and Minor F-scores are solutions to this problem, as far as I understand.
    
9. Hyperparameter Tuning : https://docs.google.com/spreadsheets/d/1wWhhZF8cgr7RbfdTaplosuqtOJAOpwzG-Y_LtEbWgro/edit?usp=sharing

## Useful links: 

[1] [tm, e1071](http://blog.thedigitalgroup.com/rajendras/2015/05/28/supervised-learning-for-text-classification/)

[2] [tm, e1071, wordcloud](https://rstudio-pubs-static.s3.amazonaws.com/194717_4639802819a342eaa274067c9dbb657e.html)

[3] [Python sklearn Naive Bayes](http://scikit-learn.org/stable/modules/generated/sklearn.naive_bayes.MultinomialNB.html)

[4] [Confusion Matrix](http://www.dataschool.io/simple-guide-to-confusion-matrix-terminology/)

[5] [Evaluation of text classification](https://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-text-classification-1.html)

[6] [Nice tutorial on text classification in Python](https://www.analyticsvidhya.com/blog/2018/04/a-comprehensive-guide-to-understand-and-implement-text-classification-in-python/). Includes a lot of methods and the libraries to use.

[5] Evaluation of text classification https://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-text-classification-1.html

[6] Python Implementation - https://www.analyticsvidhya.com/blog/2018/04/a-comprehensive-guide-to-understand-and-implement-text-classification-in-python/

[7] Text Features - https://towardsdatascience.com/understanding-feature-engineering-part-4-deep-learning-methods-for-text-data-96c44370bbfa

[8] Glove on Github - https://github.com/stanfordnlp/GloVe#train-word-vectors-on-a-new-corpus


