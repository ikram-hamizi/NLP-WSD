# !usr/perl/bin
#**************************************************************************************************************************************************************
#	
#								***************** Programming Assignment 2 (n-gram) - VCU [26/0/2018] *****************
# Author    : Ikram Hamizi
# Class     : Intro. to NLP
# Professor : Bridget McInnes
# 
#**************************************************************************************************************************************************************
#   DESCRIPTION: description-list.pl: A Perl program that implements a DECISION_LIST classifier (DECISION_LIST.txt) to perform (WSD) word sense disambiguation,
#	using features from different contexts deemed useful from a training corpus. The program uses the DECISION_LIST.txt on a test corpus and predicts and assigns
#   senses to the ambiguous word in different contexts (documents).
#   ------------
# - Input : "String.txt" @(input files) {perl decision-list.pl line-train.txt line-test.txt DECISION-LIST.txt}
# - Output: "String.txt" @(output file) { my-line-answers.txt }
#
#**************************************************************************************************************************************************************
#   SPECIFICATIONS:
#	---------------
# 1- Bag-of-word features ordered by log-liklihood (with Laplace smoothing) to assign the appropriate sense on test files from the training data.
# 2- The log-liklihood value is used to order the features and to remove the non-discriminative features from the DecisionList.
# 3- The DecisionList format: feature (word in context), the log-likelihood score associated with it, the predicted sense.
# 4- The program output the answer tags for each sentence.
#
# 5- Word stems are derived using regex expressions to group as many tokens as possible under a word type.
# 6- Capital Letter words (proper nouns) are not disgarded, since names of companies or businesses could be useful in diffrentiating the contexts and senses.
# 7- A STOPWORDS list is used to remove the usless words from the bag-of-words decision list.
# 8- All tokens are converted to lowercase
#
# Limitation: (retrieving stems from tokens) - verbs ending in 'ing', words ending in 'al', words ending in one 's' that may be plural are disrigarded.ss
#**************************************************************************************************************************************************************
#	#Tested on line-test.txt (Phone vs Product) senses.
#	Accuracy = 	 81% (with laplace smoothing)
#**************************************************************************************************************************************************************
use strict;
use experimental 'smartmatch';
use Data::Dumper qw(Dumper);
use Math::Complex;

#1- FINAL VARS

my $lextlt; #word
my $instance_id;
my $line_train = $ARGV[0]; #TRAINING CORPUS name
my $line_test = $ARGV[1];
my $decision_list = $ARGV[2]; #ARGV[3] = '>'
my $new_ans = "Assigned_Senses.txt";

#2- VARS
my %FEATURE_SENSE_COUNT; #FEATURE_SENSE_COUNT of phone and FEATURE_SENSE_COUNT of product.
my %FEATURE_COUNT; #COUNT of sense phone and product in training corpus.
my %DECISION_LIST; #Feature | Log Liklihood score | sense

my $sense_id; #sence

#3- ARRAYS
	my @DECISION_LIST_ARR;

my @stopwords;

#4- SUBROUTINES
#1- MAIN SUB: tokenizes corpus and adds the important words to the co-occurance feature vector.
sub trainingCorpusTokenizer()
{
	my @line;
	# open(CORPUS, "<", $trainingCorpus) or die "Could Not Open CORPUS file: $trainingCorpus\n";
	open(CORPUS, "<", $line_train) or die "Could Not Open CORPUS file: $line_train\n";
	print "Training start...\n";
	my $countTelephone = 0;

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
			# my removeRegex = $lextlt.'s*';
			$_ = lc($_);
			#Remove tags and the non alphabetical characters
				$_ =~ s/<\/*s>//gi;
				$_ =~ s/<\/*@>//gi;
				$_ =~ s/<\/*p>//gi;
				$_ =~ s/<head>$lextlt\w*<\/head>//gi;
				$_ =~ s/[^\sA-Za-z\']+/ /gi;
								
			#Remove words with capital letters (proper nouns)?
				# $_ =~ s/[A-Z]\w+//g;
			
			#ADD TO FEATURE VECTOR TILL END OF CONTEXT
			&featureVectorGeneratorFromCorpusContext($_); #With the normalizing func
		}
	}
	close(CORPUS);

	# # DEBUG_START**********************
	# print "------------FEATURE_SENSE-COUNT------------\n";
	# print Dumper \%FEATURE_SENSE_COUNT;
	# print "-------------------------------------------\n";
	# # DEBUG_END************************

	print "Computer finished learning from WSD Corpus\n\n";

	&decisionListGenerator();
}

sub decisionListGenerator()
{
	#Feature | Log Liklihood score | sense
	&logLiklihoodEstimator();
	
	# DEBUG_START**********************
	# print "--------DECISION_LIST----------------\n";
	# print Dumper \%DECISION_LIST;
	# print "-------------------------------------\n";
	# DEBUG_END************************

	open(DECISION_LIST_HANDLER, ">", $decision_list) or die "Could not write to file $decision_list";

	my $decision_case;
	my $predicted_sense;
	my @features = keys %DECISION_LIST;

	#Sort DECISION_LIST_ARR based on log values
	my @SORTED_DLA = sort { ($b =~ /(-*\d+(\.\d*)*)/)[0] <=> ($a =~ /(-*\d+(\.\d*)*)/)[0] } @DECISION_LIST_ARR;

		foreach my $case(@SORTED_DLA)
		{
			print DECISION_LIST_HANDLER $case."\n";
		}
	close(DECISION_LIST_HANDLER);	
	# print "finisheu decision list. da geut\n";
}

sub logLiklihoodEstimator()
{
	my $logScore;
	my $count_s1_and_fi;
	my $count_s2_and_fi;
	my $lenarray;

	my @SENSES; #Binary senses
	my @FEATURES = keys %FEATURE_SENSE_COUNT; #features f

	for my $f(@FEATURES) #n^2
	{
		@SENSES = keys %{$FEATURE_SENSE_COUNT{$f}}; #2 possibilities or 1
		$count_s1_and_fi = $FEATURE_SENSE_COUNT{$f}{$SENSES[0]};
		$lenarray = @SENSES;

		if($lenarray == 1) #1 sense
		{
			$logScore = abs log(($count_s1_and_fi+1)/1); #+1 laplace smoothing
			push (@DECISION_LIST_ARR, $f." ".$SENSES[0]." ".$logScore); #Discriminative
		}
 		else
		{
			$count_s2_and_fi = $FEATURE_SENSE_COUNT{$f}{$SENSES[1]};
			# $logScore = log (($count_s1_and_fi)/($count_s2_and_fi));
			$logScore = log (($count_s1_and_fi + 1)/($count_s2_and_fi + 1)); #+1 laplace smoothing
			if($logScore < 0)
			{
				$logScore = abs $logScore;
				push (@DECISION_LIST_ARR, $f." ".$SENSES[1]." ".$logScore);
			}
			elsif($logScore > 0)
			{
				push (@DECISION_LIST_ARR, $f." ".$SENSES[0]." ".$logScore);
			}
			
		}
	}
}
my $toBeVerb = ('(am|is|are|was|were|have been|has been)');
my @toSTEMS = ('sses:ss', 'ies:y', 'izers*:ize', 'ers*:er', 'ics*:ic', '(ally|allies|als):al', '(atory|atories|ators|ations*|ates|ated|atings*):ate', '(bilities|bility|bles):ble', "ly:"); #at the end of the word ($ is added later to the regex)

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
			$context =~ s/$tuple[0]\b/$tuple[1]/gi;
		}
	}			
	# if($context =~ m/(\w{3,}[^s])s{1}\b/gi) #Remove plural "s"
	# {
	# 	$context =~ s/(\w{3,}[^s])s{1}\b/$1/gi;
	# }
	# if($context =~ m/\w{4,}my\b/gi) #If word ends in my: "economy", "taxonomy" - remove y
	# {
	# 	$context =~ s/(\w{4,}m)y\b/$1/gi;
	# }

	if($context =~ m/(\b$toBeVerb\b\s+\w+)((ing|ed|en)\b)/gi) #If word ends in my: "economy", "taxonomy" - remove y
	{
		$context =~ s/(\b$toBeVerb\b\s+\w+)((ing|ed|en)\b)/$1/gi;
	}

	# print "STEMMING: NOW I AM: \n <s> $context <end>\n";
	return $context;
}
my $STOP_WORDS_STR;
#Helper(2) SUB: for featureVectorGeneratorFromCorpusContext
sub fillStopWordsArray()
{
	print "stop list\n";
	open(STOPWORDS, "<", "stop-list.txt") or die "Could not open file stop-list.txt";
	while(<STOPWORDS>)
	{
		chomp;
		my @arr = split /\s+/;
		push (@stopwords, split /\s+/);
		#$STOP_WORDS_STR = join " ", @arr;
	}
	close(STOPWORDS);
}
my $count = 0;
#2~ SUB (HELPER TO trainingCorpusTokenizer): takes a CONTEXT, normalizes the tokens using a STOPWORD list and regex to retrieve word-stems.
sub featureVectorGeneratorFromCorpusContext()
{
	my ($context) = @_; #ARG(STRING): a paragraph <context ..../>
	my @line;
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
			if($WORDS[$i] =~ m/\b[^A-Za-z]*$sw[^A-Za-z]*\b/gi)
			{
				$stopWord = 1;
				last;
			}
		}
		if ($stopWord == 0 && $WORDS[$i] ne '')
		{
			#push (@all_context_words, lc($WORDS[$i]));
			$FEATURE_SENSE_COUNT{lc($WORDS[$i])}{$sense_id}++;
		}
	}
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
	my @NEW_FEATURE_VECTOR;
	open(HANDLER_mynew, ">", $new_ans) or die "Could not create/open new file: $new_ans\n";
	open(HANDLERTS, "<", $line_test) or die "Could Not Open file: $line_test\n";
	
	while(<HANDLERTS>)
	{
		if($_ =~ m/<instance id="(.+)/i)
		{
			$instance_id = $1; #number for ID
			$instance_id =~ s/\"*>//;
			
			print "<answer instance=\"$instance_id\" senseid=\"";
			print HANDLER_mynew "<answer instance=\"$instance_id\" senseid=\"";
		}
		
		if($_ =~ m/<s>/) #CONTEXT
		{
			$_ = lc($_);
			#Remove tags and the non alphabetical characters
				$_ =~ s/<\/*s>//gi;
				$_ =~ s/<\/*@>//gi;
				$_ =~ s/<\/*p>//gi;
				$_ =~ s/<head>$lextlt\w*<\/head>//gi;
				$_ =~ s/[^\sA-Za-z\']+/ /gi;

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
					if($WORDS[$i] =~ m/\b[^A-Za-z]*$sw[^A-Za-z]*\b/gi)
					{
						$stopWord = 1;
						last;
					}
				}
				if ($stopWord == 0)
				{
					unless ($WORDS[$i] ~~ @NEW_FEATURE_VECTOR)
					{push (@NEW_FEATURE_VECTOR, lc($WORDS[$i]));}
				}
			}
			$sense_id = lc(&featureVectorTest(\@NEW_FEATURE_VECTOR)); #sense
			print HANDLER_mynew $sense_id."\"/>\n";
			print $sense_id."\"/>\n";
			@NEW_FEATURE_VECTOR = ();
		}
	}
	close(HANDLER_mynew);
	close(HANDLERTS);
}

#Function: Test for each context's feature vector
#The file "Decision List" is read line by line and each line's first word (feature) is checked if it exists in the feature vector of the context, until one (or more ) is found.
sub featureVectorTest()
{
	my (@FV) = @{$_[0]};
	my @DL_line;
	my $fDL; #Feature in Decision List line
	my $senseDL; #Sense in Decision List line

	my $CountSense1Found = 0;
	my $CountSense2Found = 0;
	my $CountASenseWasFound = 0;

	my $firstSENSE_Winner;
	my $secondSENSE_Prob;

	my $latestWinner  = "No Sense Assigned";

	open (FINALDECISIONLIST, "<", $decision_list) or die "Could not open $decision_list"; #Open Reading

	my $count = 0;
	while(<FINALDECISIONLIST>)
	{
		chomp;
		@DL_line = split /\s+/;
		$fDL = $DL_line[0];
		$senseDL = $DL_line[1];
		if($count > 0 && $count < 20) #80.9523809523809 %
		{
			# print "\nCount = $count\n"; #DEBUG
			$count++;
		}
		if ($count == 20)
		{
			# print "Final count = $count - $latestWinner assigned\n"; #DEBUG
			close (FINALDECISIONLIST);
			return $latestWinner;	
		}
		if($fDL ~~ @FV) #Runs 20 TESTS (of CONSECUTIVE features in the Decision List, having high log-LL scores).
		{
			$CountASenseWasFound++;

			if($CountASenseWasFound == 1)
			{
				$count++;
				$CountSense1Found++;
				$firstSENSE_Winner = $senseDL;
				# print " 1st winner: ($firstSENSE_Winner) because of '$fDL'\n"; #DEBUG
				$latestWinner = $firstSENSE_Winner;
			}
			if ($CountASenseWasFound > 1 && $senseDL eq $firstSENSE_Winner) {
				# print " 1st winner AGAIN!: ($firstSENSE_Winner) because of '$fDL'\n"; #DEBUG
				$CountSense1Found++;
			}
			elsif ($CountASenseWasFound > 1 && $senseDL ne $firstSENSE_Winner)
			{
				$CountSense2Found++;
				$secondSENSE_Prob = $senseDL;
				# print " 2nd probable: ($secondSENSE_Prob) because of '$fDL'\n"; #DEBUG
			}
			####
			if($CountASenseWasFound == 9 || $count == 19) #FINAL TEST
			{	
				# print "\ntested $CountASenseWasFound CONSECUTIVE times: "; #DEBUG
				if ($CountSense1Found >= $CountSense2Found)
				{
					# print " -- 1st sense: ($firstSENSE_Winner) assigned to because of '$fDL'\n"; #DEBUG
					$latestWinner = $firstSENSE_Winner;
					close (FINALDECISIONLIST);
					return $latestWinner;
				}
				else
				{
					# print " -- 2nd sense: ($secondSENSE_Prob) assigned to because of '$fDL'\n\n\n";
					$latestWinner = $secondSENSE_Prob;
					close (FINALDECISIONLIST);
					return $latestWinner;
				}
			}
		}
	}
	#If loop did not return a sense, it means the sense was not identified
	close (FINALDECISIONLIST);
	return $latestWinner;
}



#REFERENCE
#Source of stopwords list: https://www.ranks.nl/stopwords