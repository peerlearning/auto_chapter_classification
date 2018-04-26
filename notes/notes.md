# Notes

Just a gathering place for notes.

*  **Removing dummy Qs from the corpus**
       Dummy Qs are present in every chapter and they make up a large portion of the false classification elements
*  **Finding words that are not so useful**: This was the process:
    *  Find top occuring words across each chapter
    *  Find the top occurring words across those top occurring ones
    *  Those are the words that are most confused among chapters
    *  It turns out that a lot of these words are LaTeX words.
*  **Trying to classify without ML**: I tried to do classification directly based on the words of a question. We have the above table where we have the most commonly occurring words per chapter. So we just see the chapter that has the most matching words, and that's our prediction.
    *  Unfortunately, this does not work so well. But, it was worth trying, eh?
*  SVM and kNN don't perform as well as Naive Bayes either, so Naive Bayes it is.
*  The Naive Bayes implementation in R doesn't support multinomial distributions, which is what you need for numerical variables. The python sklearn one does, so can we use that?
    *  We can also use [Bernoulli Naive Bayes]


## Integration with server

* Where do we integrate? 
    * The point of question entering
    * Run the classifier on the repository questions
    * API? Pass the text as parameter and get classification as result
* For integrating with the question entering
    * How fast does the server need to respond?
    * Can we use the same API as for above?
* Separate place to train and run the models -- so just use it as an API? 
    * Beginning of a new service for all of ML?
