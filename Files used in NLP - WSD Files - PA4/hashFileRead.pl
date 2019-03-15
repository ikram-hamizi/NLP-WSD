# !usr/bin/perl

use strict;
use Data::Dumper qw(Dumper);


# open(DECISION, "<", "decision-list.txt") or die "Could not open to file decision-list.txt";
# my @line;
# while(<DECISION>)
# {
# 	chomp;
# 	$_ =~ s/([^A-Za-z]|VAR)//gi;
# 	@line = split /\s+/;
# 	# @array = grep { $_ =~m// } @array;

# 	foreach my $word(@line)
# 	{
# 		print $word;
# 		print "\n";
# 	}
	
# }
# close(DECISION);
my $data = {
  'Gaur 3' => {
        'Max' => '85',
        'Type' => 'text',
        'Position' => '10',
        'IsAdditional' => 'Y',
        'Required' => 'Y',
        'Mandatory' => 'Y',
        'Min' => '40'
  },
  'Gaur 2' => {
        'Max' => '90',
        'Type' => 'text',
        'Position' => '11',
        'IsAdditional' => 'Y',
        'Required' => 'Y',
        'Mandatory' => 'Y',
        'Min' => '60'
  },
  'Gaur 1' => {
        'Max' => '80',
        'Type' => 'text',
        'Position' => '10',
        'IsAdditional' => 'Y',
        'Required' => 'Y',
        'Mandatory' => 'Y',
        'Min' => '40'
   },
};

my @positioned = sort { $data->{$a}{Position} <=> $data->{$b}{Position} }  keys %$data;
 
foreach my $k (@positioned) {
    say $k;
}
# print $ARGV[0];
# print "HI";
# print log(10);
# print " ".log(2.71);
	# 		my @hashline;
	# my $bool_VARFound = 0; #1-true | 0-false
	# my $CURRENT_SENSE;
		# #remove all nonalphabetical chars.
		# $_ =~ s/([^A-Za-z])//gi;
		# if ($_ =~m/VAR/i)
		# {
		# 	#First iteration 'VAR' is found (sense is in next iteration).
		# 	$_ =~ s/(VAR)//;
		# 	$bool_VARFound = 1;
		# }
		# elsif($bool_VARFound == 1)
		# {
		# 	#Second iteration after token 'VAR' is found:
		# 	$CURRENT_SENSE = $_; 	# -catch SENSE
		# 	$_ =~ s/$SENSE1//;		# -and remove it from DECISION_LIST.

		# 	$bool_VARFound = 0;
		# }