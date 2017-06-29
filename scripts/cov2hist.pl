#!/usr/bin/perl

use warnings;
use strict;

my %hist;
my $max = 0;
while (my $line = <>) {
    chomp($line);
    my @arr = split("\t", $line);
    $max = $arr[4] if ($arr[4] > $max);
    $hist{$arr[4]}++;
}

for (my $i = 0; $i <= $max; $i++) {
    if (exists($hist{$i})) {
        printf("%i\t%i\n", $i, $hist{$i});
    } else {
        printf("%i\t%i\n", $i, 0);
    }
}
