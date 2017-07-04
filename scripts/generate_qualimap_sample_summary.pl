#!/usr/bin/perl

use warnings;
use strict;

my $version = 0.9;

usage() if (scalar(@ARGV) != 3);

my $cfg = $ARGV[0];
my $dir = $ARGV[1];
my $out = $ARGV[2];

my $fh;
open($fh, $cfg) or die(sprintf("[ERROR] Could not find %s.\n", $cfg));
my @units = ();
my $line = "";
while ($line = <$fh>) {
    if ($line =~ /units:/) {
	while ($line !~ /^\s*$/) {
	    $line = <$fh>;
	    chomp($line);
	    if ($line =~ /\s*(\w+):$/) {
		push(@units, $1);
	    }
	}
	last;
    }
}
close($fh);

if (scalar(@units) == 0) {
    die(sprintf("[ERROR] Can't find units in file %s.\n", $cfg));
} else {
    printf("Found %i samples in %s.\n", scalar(@units), $cfg);
}

open($fh, ">", $out) or die(sprintf("[ERROR] Could not open %s.\n", $out));
for (my $i = 0; $i < scalar(@units); $i++) {
    my $id = $units[$i];
    my $sample = join("/", $dir, sprintf("%s.sorted.bam", $id));
    (my $group = $id) =~ s/_rep\d+//;
    printf($fh "%s\n", join("\t", $id, $sample, $group));
}
close($fh);
printf("QualiMap sample summary written to %s.\n", $out);
printf("[DONE]\n");


sub usage {
    printf("generate_qualimap_sample_summary.pl version %s by Maurits Evers (maurits.evers\@anu.edu.au)\n", $version);
    printf("Generate a three column sample summary based on units in a snakemake config.yaml.\n");
    printf("Usage:\n");
    printf("  generate_qualimap_sample_summary.pl <in> <out>\n");
    printf("\n");
    printf("  <in>     Snakemake config.yaml file.\n");
    printf("  <dir>    QualiMap sample summary output file.\n");
    printf("  <out>    QualiMap sample summary output file.\n");
    exit; 
}
