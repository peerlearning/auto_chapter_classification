# auto_chapter_classification
Automatically tag Qs to respective chapters on CMS

Problem Statement : Currently, to be able to add any Q on CMS, the creator needs to tag its syllabus, chapter, topic etc. This causes a significant delay since tagging a Q to one of the 30 chapters in JEE Chemistry, say, is a non-trivial process, and needs the time of curriulum creator. This process needs to be done 90 times for getting a single JEE Main mock paper typed. 

To speed up our question creation process on CMS, we should be able to automatically classify a Question into any of the given chapters for a particular syllabus, using its text.

In this script, we are using the Naive Bayes algorithm for multi-class classification. Naive Bayes is particulary very effective in text classification problems and generally shows high accuracy even with small training set.
