# !usr/bin/perl
use strict;

my $string = "mystring123456";
$string =~ s/1//;
print "$string\n";

my $text = '<s> The New York plan froze basic rates, offered no protection to Nynex against an economic downturn that sharply cut demand and didn\'t offer flexible pricing. </s> <@> <s> In contrast, the California economy is booming, with 4.5% access <head>line</head> growth in the past year. </s>';
print $text."\n";
 
print "TREAAAAAAAAAANSOFORM: \n\n";
$text =~ s/a/z/g;
$text =~ s/<s>//g;
$text =~ s/<\/s>//g;
$text =~ s/<@>//g;
print $text."\n";