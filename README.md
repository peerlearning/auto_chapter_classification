# auto_chapter_classification
Automatically tag Qs to respective chapters on CMS

Problem Statement : Currently, to be able to add any Q on CMS, the creator needs to tag its syllabus, chapter, topic etc. This causes a significant delay since tagging a Q to one of the 30 chapters in JEE Chemistry, say, is a non-trivial process, and needs the time of curriulum creator. This process needs to be done 90 times for getting a single JEE Main mock paper typed. 

To speed up our question creation process on CMS, we should be able to automatically classify a Question into any of the given chapters for a particular syllabus, using its text.

In this script, we are using the Naive Bayes algorithm for multi-class classification. Naive Bayes is particulary very effective in text classification problems and generally shows high accuracy even with small training set. Naive Bayes constructs tables of probabilities that are used to estimate the likelihood that new examples belong to various classes. The probabilities are calculated using a formula known as Bayes' theorem, which specifies how dependent events are related. Although Bayes' theorem can be computationally expensive, a simplified version that makes so-called "naive" assumptions about the independence of features is capable of handling extremely large datasets.

Sources: 

[1] tm, e1071 - http://blog.thedigitalgroup.com/rajendras/2015/05/28/supervised-learning-for-text-classification/

[2] tm, e1071, wordcloud - https://rstudio-pubs-static.s3.amazonaws.com/194717_4639802819a342eaa274067c9dbb657e.html

[3] Python - http://scikit-learn.org/stable/modules/generated/sklearn.naive_bayes.MultinomialNB.html

[4] Confusion Matrix - http://www.dataschool.io/simple-guide-to-confusion-matrix-terminology/
