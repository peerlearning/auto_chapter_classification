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
