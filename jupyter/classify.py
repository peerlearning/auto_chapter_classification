# Sklearn module
from sklearn import model_selection, preprocessing, linear_model, naive_bayes, metrics, svm
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn import decomposition, ensemble

import pandas as pd, xgboost, numpy, textblob, string

# Keras stuff
from keras.preprocessing import text, sequence
from keras import layers, models, optimizers

import json

from pylatexenc.latex2text import LatexNodes2Text

## ----- DATA PREPARATION -----

subject_to_check = 'MTH'
# Load the dataset
labels, texts = [], []
with open('../data/qs_topicwise.json') as json_data:
    all_questions = json.load(json_data)

words_to_remove = ["rightarrow", "hence", "frac", "text", "sqrt", "times", "value", "amp", "statement", "will", "equal", "number", "tan", "now", "can", "two", "get", "true", "lambda"]

data_df = pd.DataFrame(columns=['curriculum', 'subject', 'question_text', 'chapter'])
questions = []
i = 0
for question in all_questions:
    topic_code = question['topic_code']
    try: 
        question_text = question['question_text'].lower()
        question_text = " ".join(question_text.split())
        for word in words_to_remove:
            question_text.replace(word, "")
        splits = topic_code.split("-")
        subject = splits[0]
        curriculum = splits[2]
        grade = splits[1]
        curr_question = {}
        if("JEE" in curriculum and grade in ["11", "12"] and subject in subject_to_check and "dummy" not in question_text):
            data_df.loc[i] = [curriculum, subject, question_text, question['chapter']]
            i += 1
    except:
            pass

trainDF = pd.DataFrame(columns=['text', 'label'])

# trainDF.replace(words_to_replace, "")
trainDF['text'] = data_df['question_text']
trainDF['label'] = data_df['chapter']

# Split data into training and testing folds

train_x, valid_x, train_y, valid_y = model_selection.train_test_split(trainDF['text'], trainDF['label'], test_size=0.2)

print(len(train_x), len(train_y) )

# Label encode the target variable 
encoder = preprocessing.LabelEncoder()
train_y = encoder.fit_transform(train_y)
valid_y = encoder.fit_transform(valid_y)

## ----- END DATA PREPARATION -----


## ----- FEATURE ENGINEERING -----
# create a count vectorizer object 
count_vect = CountVectorizer(analyzer='word', token_pattern=r'\w{1,}')
count_vect.fit(trainDF['text'])

# transform the training and validation data using count vectorizer object
xtrain_count =  count_vect.transform(train_x)
xtrain_count[xtrain_count != 0] = 1
print(xtrain_count)

xvalid_count =  count_vect.transform(valid_x)
xvalid_count[xvalid_count != 0] = 1

# word level tf-idf
tfidf_vect = TfidfVectorizer(analyzer='word', token_pattern=r'\w{1,}', max_features=5000)
tfidf_vect.fit(trainDF['text'])
xtrain_tfidf =  tfidf_vect.transform(train_x)
xvalid_tfidf =  tfidf_vect.transform(valid_x)

# ngram level tf-idf 
tfidf_vect_ngram = TfidfVectorizer(analyzer='word', token_pattern=r'\w{1,}', ngram_range=(2,3), max_features=5000)
tfidf_vect_ngram.fit(trainDF['text'])
xtrain_tfidf_ngram =  tfidf_vect_ngram.transform(train_x)
xvalid_tfidf_ngram =  tfidf_vect_ngram.transform(valid_x)

# characters level tf-idf
tfidf_vect_ngram_chars = TfidfVectorizer(analyzer='char', token_pattern=r'\w{1,}', ngram_range=(2,3), max_features=5000)
tfidf_vect_ngram_chars.fit(trainDF['text'])
xtrain_tfidf_ngram_chars =  tfidf_vect_ngram_chars.transform(train_x) 
xvalid_tfidf_ngram_chars =  tfidf_vect_ngram_chars.transform(valid_x) 

## ----- END FEATURE ENGINEERING -----

## MODEL BUILDING AND PREDICTION

def train_model(classifier, feature_vector_train, label, feature_vector_valid, is_neural_net=False):
    # fit the training dataset on the classifier
    classifier.fit(feature_vector_train, label)
    
    # predict the labels on validation dataset
    predictions = classifier.predict(feature_vector_valid)
    
    if is_neural_net:
        predictions = predictions.argmax(axis=-1)

    return metrics.accuracy_score(predictions, valid_y)

# Naive Bayes on Count Vectors
accuracy = train_model(naive_bayes.GaussianNB(), xtrain_count.toarray(), train_y, xvalid_count.toarray())
print("NB, Count Vectors: ", accuracy)

# Naive Bayes on Word Level TF IDF Vectors
accuracy = train_model(naive_bayes.MultinomialNB(), xtrain_tfidf, train_y, xvalid_tfidf)
print("NB, WordLevel TF-IDF: ", accuracy)

# Naive Bayes on Ngram Level TF IDF Vectors
accuracy = train_model(naive_bayes.MultinomialNB(), xtrain_tfidf_ngram, train_y, xvalid_tfidf_ngram)
print("NB, N-Gram Vectors: ", accuracy)

# Naive Bayes on Character Level TF IDF Vectors
accuracy = train_model(naive_bayes.MultinomialNB(), xtrain_tfidf_ngram_chars, train_y, xvalid_tfidf_ngram_chars)
print("NB, CharLevel Vectors: ", accuracy)
## END MODEL BUILDING AND PREDICTION
