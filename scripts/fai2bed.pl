#!/usr/bin/perl

# Generates a BED file from a FA.FAI index file.
# Author: Maurits Evers (maurits.evers.anu.edu.au)

while (my $line = <>) {
    my @arr = split("\t", $line);
    printf("%s\n", join("\t", $arr[0], 0, $arr[1] - 1, $arr[0], 0, "."));
}
