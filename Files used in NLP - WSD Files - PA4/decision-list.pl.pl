# !usr/perl/bin
#**************************************************************************************************************************************************************
#	
#								***************** Programming Assignment 2 (n-gram) - VCU [26/0/2018] *****************
# Author    : Ikram Hamizi
# Class     : Intro. to NLP
# Professor : Bridget McInnes
# 
#**************************************************************************************************************************************************************
#   DESCRIPTION: DECISION_LIST_LIST.pl: A Perl program that implements a DECISION_LISTclassifier (DECISION_LIST_LIST.txt) to perform (WSD) word sense disambiguation,
#	using features from different contexts deemed useful from a training corpus. The program uses the DECISION_LIST_LIST.txt on a test corpus and predicts and assigns
#   senses to the ambiguous word in different contexts (documents).
#   ------------
# - Input : "String.txt" @(input files) { line-train.txt line-test.txt my-DECISION_LIST.txt }
# - Output: "String.txt" @(output file) { my-line-answers.txt }
#
#**************************************************************************************************************************************************************
#   SPECIFICATIONS:
#	---------------
# 1- Bag-of-word features ordered by log-liklihood and assigned the appropriate sense from the training data.
# 2- The log-liklihood value is used to order the features and to remove the non-discriminative features from the DecisionList.
# 3- The DecisionList format: feature (word in context), the log-likelihood score associated with it, the predicted sense.
# 4- The program output the answer tags for each sentence.
#
# 5- Word stems are derived using regex expressions to group as many tokens as possible under a word type.
# 6- Capital Letter words (proper nouns) are not disgarded, since names of companies or businesses could be useful in diffrentiating the contexts and senses.
# 7- A STOPWORDS list is used to remove the usless words from the bag-of-words decision list.
#
# Limitation: (retrieving stems from tokens) - verbs ending in 'ing', words ending in 'al', words ending in one 's' that may be plural are disrigarded.
#**************************************************************************************************************************************************************

use strict;
use experimental 'smartmatch';
use Data::Dumper qw(Dumper);

#1- FINAL VARS
my $lextlt; #word
my $instance_id;

my $line_train; #TRAINING CORPUS name
my $line_test;
my $decision_list; #ARGV[3] = '>'
my $line_key;

 
#2- VARS
my %FEATURE_SENSE_COUNT; #FEATURE_SENSE_COUNT of phone and FEATURE_SENSE_COUNT of product.
my %FEATURE_COUNT; #COUNT of sense phone and product in training corpus.
my %DECISION_LIST; #Feature | Log Liklihood score | sense

my $sense_id; #sence

#3- ARRAYS
	my @DECISION_LIST_ARR;

my @stopwords;
my @toSTEMS = ('sses:ss', 'ies:y', 'ss:ss', 'ied:', 'ed:', 'ational:', 'izer:ize', 'ator:ate', 'able:', 'ate:', 'ics*:', 'ally:al'); #at the end of the word ($ is added later to the regex)

#4- SUBROUTINES
#1- MAIN SUB: tokenizes corpus and adds the important words to the co-occurance feature vector.
sub trainingCorpusTokenizer()
{
	$line_train = $ARGV[0]; #TRAINING CORPUS name
	# $line_test = $ARGV[1];
	# $decision_list = $ARGV[2]; #ARGV[3] = '>'
	# $line_key = $ARGV[4];
	my @line;
	# open(CORPUS, "<", $trainingCorpus) or die "Could Not Open CORPUS file: $trainingCorpus\n";
	open(CORPUS, "<", $line_train) or die "Could Not Open CORPUS file: $line_train\n";
	print "Training start...\n";

	while(<CORPUS>)
	{
		chomp;
		# print; #DEBUG
		# print "\n";
		# print ".END.";
		# print "\n";

		if($_ =~ m/<lexelt item="(\w+)/i)
		{
			$lextlt = $1; #word
			$lextlt = s/-n//;
		}
		if($_ =~ m/<instance id="(.+)/i)
		{
			$instance_id = $1; #number for ID
			$instance_id =~ s/\"*>//;
			# print "IIIIIIIIIIIIIIIIII: instance_id: $instance_id\n";
		}
		if($_ =~ m/senseid="(\w+)/i)
		{
			$sense_id = uc($1); #sense
			# print "SSSSSSSSSSSSSS: sense_id: $sense_id\n";
		}
		if($_ =~ m/<s>/) #CONTEXT
		{
			#Remove tags and the non alphabetical characters
				$_ =~ s/<\/*s>//g;
				$_ =~ s/<\/*@>//g;
				$_ =~ s/<\/*p>//g;
				$_ =~ s/<\/*s>//g;
				$_ =~ s/\w*[^A-Za-z\s]+\w*//g;
				$_ =~ s/<head>$lextlt<\/head>//g;


			#Remove words with capital letters (proper nouns)?
				# $_ =~ s/[A-Z]\w+//g;
			
			#ADD TO FEATURE VECTOR TILL END OF CONTEXT
				&featureVectorGeneratorFromCorpusContext($_);
		}
	}
	close(CORPUS);

	# DEBUG_START**********************
	print "------------FEATURE_SENSE-COUNT------------\n";
	print Dumper \%FEATURE_SENSE_COUNT;
	print "-------------------------------------------\n";
	# DEBUG_END************************
	print "Computer finished learning from WSD Corpus\n\n";

	&decisionListGenerator();
}

sub decisionListGenerator()
{
	print "I am start decision list-- \n\n";

	#Feature | Log Liklihood score | sense
	&logLiklihoodEstimator();
	print "********************************FINISHED LOG\n\n\n";

	# DEBUG_START**********************
	# print "--------DECISION_LIST----------------\n";
	# print Dumper \%DECISION_LIST;
	# print "-------------------------------------\n";
	# DEBUG_END************************

	open(DECISION_LIST_HANDLER, ">", "MYLOLDECISION.txt") or die "Could not write to file $decision_list";

	my $decision_case;
	my $predicted_sense;
	my $log_score;
	my @features = keys %DECISION_LIST;

	#Sort DECISION_LIST_ARR based on log values
	my @SORTED_DLA = sort { ($b =~ /(-*\d+(\.\d*)*)/)[0] <=> ($a =~ /(-*\d+(\.\d*)*)/)[0] } @DECISION_LIST_ARR;


	#????????????????????????????????????????????? SORT on 3rd key
		# foreach my $f(@features)
		foreach my $case(@SORTED_DLA)
		{
			# my @senses = keys %{$DECISION_LIST{$f}};
			# $predicted_sense = @senses[0];
			# my @logscores = keys %{$DECISION_LIST{$f}{$predicted_sense}};
			# $log_score = $logscores[0];			 
			# $decision_case = $f."  ".$predicted_sense."  ".$log_score."\n";
			#print DECISION_LIST $decision_case;

			print DECISION_LIST_HANDLER $case."\n";
		}
	close(DECISION_LIST_HANDLER);	
	# print "finisheu decision list. da geut\n";
}

sub logLiklihoodEstimator()
{
	print "I am log-- \n\n";
	my $logScore;
	my $count_s1_and_fi;
	my $count_s2_and_fi;
	my $lenarray;

	my @FEATURES = keys %FEATURE_SENSE_COUNT; #BINARY SENSES
	for my $f(@FEATURES) #n^2
	{
		my @SENSES = keys %{$FEATURE_SENSE_COUNT{$f}}; #2 possibilities or 1
		$count_s1_and_fi = $FEATURE_SENSE_COUNT{$f}{$SENSES[0]};
		$lenarray = @SENSES;

		# print "\nLOG Liklihood: ALL POSSIBLE SENSES  LENGTH : $lenarray\n";

		if($lenarray == 1)
		{
			# $DECISION_LIST{$f}{$SENSES[0]}{log ($count_s1_and_fi)}++;
			my $log = log($count_s1_and_fi);

			# print "I AM ONLY LENGTH 1 and my LOG: $log\n";
			push (@DECISION_LIST_ARR, $f." ".$SENSES[0]." ".$log); #Discriminative
		}
 		else
		{
			# print "------------> not LENGTH 1\n";
			$count_s2_and_fi = $FEATURE_SENSE_COUNT{$f}{$SENSES[1]};
			if($count_s1_and_fi == 0)
			{
				# $DECISION_LIST{$f}{$SENSES[1]}{-log($count_s2_and_fi)}++;
				my $log = -log($count_s2_and_fi);
				push (@DECISION_LIST_ARR, $f." ".$SENSES[1]." ".$log);
			}
			elsif($count_s2_and_fi == 0)
			{
				my $log = -log($count_s2_and_fi);
				push (@DECISION_LIST_ARR, $f." ".$SENSES[0]." ".$log);
				# $DECISION_LIST{$f}{$SENSES[0]}{log($count_s1_and_fi)}++;
			}	
			else 
			{
				$logScore = log (($count_s1_and_fi)/($count_s2_and_fi));
				if($logScore < 0)
				{
					# $DECISION_LIST{$f}{$SENSES[1]}{$logScore}++;
					push (@DECISION_LIST_ARR, $f." ".$SENSES[1]." ".$logScore);
				}
				elsif($logScore > 0)
				{
					# $DECISION_LIST{$f}{$SENSES[0]}{$logScore}++;
					push (@DECISION_LIST_ARR, $f." ".$SENSES[0]." ".$logScore);
				}
			}
		}
	}
}
my $toBeVerb = ('(am|is|are|was|were|have been|has been|)');

#Helper(1) SUB: for featureVectorGeneratorFromCorpusContext. Uses Array @toSTEMS (Regex Rules) to stem tokens into word-types.
sub normalizerToStem()
{
	my ($context) = @_;
	my @TOKENS;
	my @tuple;

	foreach my $rule(@toSTEMS)
	{
		@tuple = split(":", $rule);
		if($context =~m/$tuple[0]\b/gi)
		{
			# print "FOUND  - $tuple[0] !!\n";
			$context =~ s/$tuple[0]\b/$tuple[1]/gi;
		}
	}			
	if($context =~ m/\w{3,}[^s]s{1}\b/gi) #Remove plural "s"
	{
		$context =~ s/\w{3,}[^s]s{1}\b//gi;
	}
	if($context =~ m/\w{2,}my\b/gi) #If word ends in my: "economy", "taxonomy" - remove y
	{
		$context =~ s/\w{2,}my\b\b/m/gi;
	}

	# my $toBeVerb = ('(am|is|are|was|were|have been|has been)');
	# if($context =~ m/\b$toBeVerb\b\s+(\w+((ing|ed)\b))/gi) #If word ends in my: "economy", "taxonomy" - remove y
	# {
	# 	if($1 =~ m /[aeiou](ing|ed)\b/gi)
	# 	$context =~ s/$2//gi;
	# }

	# print "STEMMING: NOW I AM: \n <s> $context <end>\n";
	return $context;

	#@TOKENS = split(/\s+/, $context);
	# foreach my $token(@TOKENS)
	# for (my $i = 0; $i < scalar @TOKENS; $i++)
	# {
	# 	foreach my $rule(@toSTEMS)
	# 	{
	# 		@tuple = split(":", $rule);
	# 		if($TOKENS[$i] =~m/@tuple[0]$/)
	# 		{
	# 			print "BEFORE: I WAS $TOKENS[$i]\n";
	# 			$TOKENS[$i] =~s/@tuple[0]$/@tuple[1]/;
	# 			print "STEMMING: NOW I AM $TOKENS[$i]\n";
	# 			last;
	# 		}
	# 	}
	# }
}

#Helper(2) SUB: for featureVectorGeneratorFromCorpusContext
sub fillStopWordsArray()
{
	print "stop list\n";
	open(STOPWORDS, "<", "stop-list.txt") or die "Could not open file stop-list.txt";
	while(<STOPWORDS>)
	{
		chomp;
		push (@stopwords, split /\s+/);
	}
	close(STOPWORDS);
}
my $count = 0;
#2~ SUB (HELPER TO trainingCorpusTokenizer): takes a CONTEXT, normalizes the tokens using a STOPWORD list and regex to retrieve word-stems.
sub featureVectorGeneratorFromCorpusContext()
{
	my ($context) = @_; #ARG(STRING): a paragraph <context ..../>
	my @line;
	my @all_context_words;
	# print "$count ";
	# $count++;

	#1- Retrieving stem words from tokens in context.
	#HELPER SUB (1)
	$context = &normalizerToStem($context);


	my $stopWord = 1; #1-true | 0-false
	my @WORDS = (split /\s+/, $context);
	for (my $i=0; $i< scalar @WORDS; $i++)
	{
		# print $word; #DEBUG
		# print "\n";
		$stopWord = 0;
		foreach my $sw(@stopwords)
		{
			if($WORDS[$i] =~ m/\b$sw\b/i)
			{
				$stopWord = 1;
				last;
			}
		}
		if ($stopWord == 0)
		{
			push (@all_context_words, lc($WORDS[$i]));
			$FEATURE_SENSE_COUNT{lc($WORDS[$i])}{$sense_id}++;
		}
	}

	# my $arrlen = @all_context_words;
	# foreach my $word(@all_context_words) #Add words + count + to feature list.
	# {
	# 	$FEATURE_SENSE_COUNT{lc($word)}{$sense_id}++;
	# 	$FEATURE_COUNT{$word}++;
	# }
}
########################################## START OF PROGRAM DECISION_LIST.pl #########################################

#1 Eliminate stopwords (@source of list: below in reference)
#HELPER SUB (2)
&fillStopWordsArray();
&trainingCorpusTokenizer();

#2- TEST
&senseDecision();
########################################################  END  #######################################################

#2- Tag words of TEST FILE using decision list
sub senseDecision()
{
	open(HANDLERTS, "<", "line-test.txt") or die "Could Not Open file: line-test.txt\n";
	open(HANDLER_mynew, ">", "MYANSWER.txt") or die "Could not create/open new file: MYANSWER.txt\n";
	my @FEATURE_VECTOR;
	while(<HANDLERTS>)
	{
		if($_ =~ m/<instance id="(.+)/i)
		{
			$instance_id = $1; #number for ID
			$instance_id =~ s/\"*>//;
			# print "IIIIIIIIIIIIIIIIII: instance_id: $instance_id\n";
			# print "<answer instance=\"$instance_id\" senseid=";
			print HANDLER_mynew "<answer instance=\"$instance_id\" senseid=\"";
		}
		
		if($_ =~ m/<s>/) #CONTEXT
		{
			#Remove tags and the non alphabetical characters
				$_ =~ s/<\/*s>//g;
				$_ =~ s/<\/*@>//g;
				$_ =~ s/<\/*p>//g;
				$_ =~ s/<\/*s>//g;
				$_ =~ s/\w*[^A-Za-z\s]+\w*//g;
				$_ =~ s/<head>$lextlt<\/head>//g;

			$_ = &normalizerToStem($_);

			my $stopWord = 1; #1-true | 0-false
			my @WORDS = (split /\s+/, $_);
			for (my $i=0; $i< scalar @WORDS; $i++)
			{
				# print $word; #DEBUG
				# print "\n";
				$stopWord = 0;
				foreach my $sw(@stopwords)
				{
					if($WORDS[$i] =~ m/\b$sw\b/i)
					{
						$stopWord = 1;
						last;
					}
				}
				if ($stopWord == 0)
				{
					unless ($WORDS[$i] ~~ @FEATURE_VECTOR)
					{push (@FEATURE_VECTOR, lc($WORDS[$i]));}
				}
			}
			$sense_id = lc(&featureVectorTest(\@FEATURE_VECTOR)); #sense
			print HANDLER_mynew $sense_id."\"/>\n";
			@FEATURE_VECTOR = ();
		}
	}
	close(HANDLER_mynew);
	close(HANDLERTS);
}

sub featureVectorTest()
{
	my (@FV) = @{$_[0]};
	my @DL_line;
	my $fDL;
	my $senseDL;

	open (FINALDECISIONLIST, "<", "MYLOLDECISION.txt");

	while(<FINALDECISIONLIST>)
	{
		chomp;
		@DL_line = split /\s+/;
		$fDL = $DL_line[0];
		$senseDL = $DL_line[1];
		if($fDL ~~ @FV)
		{
			close (FINALDECISIONLIST);
			return $senseDL;
		}
	}
	#If loop did not return a sense, it means the sense was not identified
	return "NO SENSE ASSIGNED"; 
	close (FINALDECISIONLIST);
}



#REFERENCE
#Source of stopwords list: https://www.ranks.nl/stopwords