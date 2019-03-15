# !/usr/bin/perl

use strict;
my @x = (14.9, 3, -12, 2,28828282, -23.3);


my @y = sort { ($a =~ /(-*\d+\.*\d*)/)[0] <=> ($b =~ /(-*\d+\.*\d+)/)[0] } @x;
print join " ", @y;

# -*\d+\.*\d+