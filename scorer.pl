# !/usr/bin/perl
#********************************************************************************************************************************************************
#	
#								********** Programming Assignment 4 (Decision List Classifier - SCORER) - VCU [26/03/2018] ************
# Author    : Ikram Hamizi
# Class     : Intro. to NLP
# Professor : Bridget McInnes
# 
#********************************************************************************************************************************************************
# Description: 
#
#********************************************************************************************************************************************************
#
# Input:  < NEW SENSE-TAGGED FILE (perl scorer.pl Assigned_Senses.txt line-key.txt) 
# Output: > Accuracy + Confusion Matrix (> sense-tag-report.txt)
#
#********************************************************************************************************************************************************

use strict;
use Data::Dumper qw(Dumper);
use List::Util qw(max); #Module that has the "max" function
use List::MoreUtils qw(first_index);
use experimental 'smartmatch';
use AI::ConfusionMatrix;

my @FEATURE_SENSE_NEW = ();
my $token;
my $instance_id;
my $sense_id;
my $total_tokens;

my $line_new_ans = $ARGV[0];
my $line_key = $ARGV[1];
#1- Read and tokenize the new Tagged file and store in array.
my @arraymynew;
my @EXISTING_SENSES;

open(HANDLERmynew, "<", $line_new_ans) or die "Could Not Open file: $line_new_ans\n";
while(<HANDLERmynew>)
{
	#<answer instance="line-n.w8_059:8174:" senseid="phone"/>
	chomp;
	# print;
	# print "\n\n";
 	if($_ =~m /<answer instance=\"\b(((\w+[-._:]*)+)\b:)\" senseid=\"(\w+)\"\/>/) 
	{
		$instance_id = lc($1);

		$sense_id    = lc($4);
		# print "$instance_id + $sense_id\n";
		unless ($sense_id ~~ @EXISTING_SENSES)
		{
			push @EXISTING_SENSES, $sense_id;
		}
	}

	push @FEATURE_SENSE_NEW, "$instance_id $sense_id";
}
close(HANDLERmynew);
print "----\n";

#2- Compare with KEY
my @arrayKEY;
my $TOTAL_TESTS_COUNT = 0;

my $WRONG_IT_SHOULD_BE_SENSE1 = 0;
my $WRONG_IT_SHOULD_BE_SENSE2 = 0;
my %CONF_HASH;
my $instance_id;
my $sense_id;

open(HANDLERKEY, "<", $line_key) or die "Could Not Open file: $line_key\n";
while(<HANDLERKEY>)
{
	chomp;
	# print;
	# print "\n\n";
	if($_ =~m /<answer instance=\"\b(((\w+[-._:]*)+)\b:)\" senseid=\"(\w+)\"\/>/) 
	{
		$instance_id = lc($1);
		$sense_id    = lc($4);
		$TOTAL_TESTS_COUNT++;
	}
	elsif ($_ =~m /<answer instance=\"\b(((\w+[-._:}\s]*)+)\b:)\" senseid=\"(\w+)\"\/>/)
	{
		$instance_id = lc($1);
		$sense_id    = lc($4);
		$TOTAL_TESTS_COUNT++;
	}
	unless("$instance_id $sense_id" ~~ @FEATURE_SENSE_NEW)
	{
		# print "WRONG :(\n";
		# print "$sense_id - $EXISTING_SENSES[0] + $EXISTING_SENSES[1]\n";
		if($sense_id =~m /$EXISTING_SENSES[0]/i)
		{
			$WRONG_IT_SHOULD_BE_SENSE1++; #it should be SENSES[0]
			$CONF_HASH{$sense_id}{$EXISTING_SENSES[1]}++;
		}
		else
		{
			$WRONG_IT_SHOULD_BE_SENSE2++; #it should be SENSES[1]
			$CONF_HASH{$sense_id}{$EXISTING_SENSES[0]}++;
					   #correct  #wrong
		}
	}
}
close(HANDLERKEY);

print "------------------------\n";
print Dumper \%CONF_HASH;
print "------------------------\n";

# makeConfusionMatrix(\%CONF_HASH, 'output.csv');


#3- Confusion matrix + print
# my $correctly_guessed = 0;
# for (my $i=1; $i<=2; $i++) #$token(@arrayTR)
# {
# 	print "			S$i: $EXISTING_SENSES[0]	";
# 	for (my $j=0; $j<2; $j++) #$token(@arrayTR)
# 	{
# 		if ($j == 0)
# 		{
# 			print "S$i:		";
# 			$correctly_guessed = $TOTAL_TESTS_COUNT - $WRONG_IT_SHOULD_BE_SENSE1;
# 			print "$correctly_guessed				$WRONG_IT_SHOULD_BE_SENSE1";
# 		}
# 		else
# 		{
# 			print "S$i:		";
# 			$correctly_guessed = $TOTAL_TESTS_COUNT - $WRONG_IT_SHOULD_BE_SENSE2;
# 			print "$correctly_guessed				$WRONG_IT_SHOULD_BE_SENSE2";
# 		}
# 	}
# }



#5- CALCULATE ACCURACY
if($TOTAL_TESTS_COUNT ne 0)
{	print $WRONG_IT_SHOULD_BE_SENSE1." ".$WRONG_IT_SHOULD_BE_SENSE2."\n";
	my $ACCURACY = ($TOTAL_TESTS_COUNT-$WRONG_IT_SHOULD_BE_SENSE1-$WRONG_IT_SHOULD_BE_SENSE2)/$TOTAL_TESTS_COUNT * 100;
	print "Accuracy of decision-list.pl = $ACCURACY %\n";
}
else
{
	print "Error: No test or training text was used\n";
}
