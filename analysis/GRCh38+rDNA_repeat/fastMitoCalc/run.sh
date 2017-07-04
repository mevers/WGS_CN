#!/bin/bash

perl ~/Programs/fastMitoCalc/fastMitoCalc.pl -f ../../../alignment/GRCh38+rDNA_repeat/TOV.sorted.bam -w . -p ~/Programs/fastMitoCalc/BaseCoverage -n 100000 -s 10000 -g 38
perl ~/Programs/fastMitoCalc/fastMitoCalc.pl -f ../../../alignment/GRCh38+rDNA_repeat/Z38.sorted.bam -w . -p ~/Programs/fastMitoCalc/BaseCoverage -n 100000 -s 10000 -g 38
