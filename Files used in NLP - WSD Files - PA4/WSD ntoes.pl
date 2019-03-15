#a decision list classifier to perform word sense disambiguation.
# (sses:ss, ies:y, ss:ss, s:"", /v+[aeiou]/ing:"", /v/ed:"", ational:ate, izer:ize, ator:ate, al:"", able:"", ate,"")


# Ambigious words:
# *****************
# Binary classifier: period(.) (EndOfSentence/NotEndOfSentence)
# Classifiers: hand-written rules, regexes, machine-learning.

# perl decision-list.pl line-train.txt line-test.txt my-decision-list.txt > my-line-answers.txt


# my-decision-list.txt
# -show each feature
# -the log-likelihood score associated with it
# -the sense it predicts.
# -answer tags should be in the same format as found in line-key.txt.

# Supervised	machine	learning	approach:
# • a	training	corpus of	words	tagged	in	context	with	their	sense
# • used	to	train	a	classifier	that	can	tag	words	in	new	text

# Summary	of	what	we	need:
# • the	tag	set (“sense	inventory”)
# • the	training	corpus
# • A	set	of	features extracted	from	the	training	corpus
# • A	classifier

#Supervised WDS: 
# Training Classifier: (1) word, (2) word in context, (3) hand-labled senses.
# Test    			 : 	   Target words -> labeled.

#Collecting FEATURES for Supervised WSD:
# -In Feature Vectors.
# -2 Types of [] from context: Bag-of-word FV (unordered) and Collocational FV (ordered).

#NAIVE BAYES CLASSIFIER:
# - Choose best sense s (phone, product) for a feature vector.


