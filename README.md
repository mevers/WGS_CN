# CN_WGS

This GitHub repository contains the `snakemake` workflow to estimate mitochondrial and ribosomal DNA copy numbers from whole-genome sequencing data.

Copy numbers are estimated from a comparison of mean coverage across the rDNA/mtDNA and the autosomal DNA. For details see [Qian et al., Bioinformatics 33, 1399 (2017)](https://academic.oup.com/bioinformatics/article-lookup/doi/10.1093/bioinformatics/btw835) and [Ding et al., PLoS Genet. 14, e1005306 (2015)](https://www.ncbi.nlm.nih.gov/pubmed/26172475).

Note that neither raw sequencing nor reference data are provided, and as such the repository does not constitute a self-contained, reproducible analysis workflow. Please contact Maurits Evers [Maurits Evers](mailto:maurits.evers@anu.edu.au) for details.

# Genome reference

[Ensembl](ftp://ftp.ensembl.org/pub/release-89/fasta/homo_sapiens/dna/) provides the following two main genome assembly files.

1. Homo_sapiens.GRCh38.dna_rm.toplevel.fa  
    The *toplevel assembly* includes chromosomes, any unlocalised or unplaced scaffolds, and alternate sequences (alternate loci, fix patches, novel patches). This is the largest continuous sequence for an organism.
2. Homo_sapiens.GRCh38.dna_rm.primary_assembly.fa  
    The *primary assembly* includes chromosomes, and any unlocalised or unplaced scaffolds. It does *not* include alternate sequences.

For details, see [here](http://www.ensembl.org/info/website/glossary.html). All sequences with names KI* and GI* are unplaced scaffolds, see [here](https://github.com/dpryan79/ChromosomeMappings/blob/master/GRCh38_ensembl2UCSC.txt) for mapping their Ensembl names to UCSC names.

In the context of this work, we need to make sure to exclude any unlocalised, unplaced, and placed scaffolds, as they may contain (incomplete) sequences of the human rDNA repeat. For example, unplaced genomic contig/scaffold GL000220.1 seems to contain (parts of) the human rDNA repeat unit U13369.1. If we keep these unplaced scaffolds in the reference genome, read alignment may map rDNA-associated reads to these unplaced contigs instead of to the canonical rDNA copy.  

Therefore we manually download all diploid autosomal chromosome sequences as well as the sequences of chromosomes X, Y, and MT manually, and manually concatenate all FASTA sequence files including one copy of the [U13369.1](https://www.ncbi.nlm.nih.gov/nuccore/555853) rDNA sequence. The resulting reference genome file has filename `GRCh38+rDNA_repeat.fa`, and the following index:
```
1	248956422	59	60	61
2	242193529	253105814	60	61
3	198295559	499335961	60	61
4	190214555	700936505	60	61
5	181538259	894321362	60	61
6	170805979	1078885318	60	61
7	159345973	1252538123	60	61
8	145138636	1414539922	60	61
9	138394717	1562097595	60	61
10	133797422	1702798952	60	61
11	135086622	1838826393	60	61
12	133275309	1976164520	60	61
13	114364328	2111661146	60	61
14	107043718	2227931608	60	61
15	101991189	2336759449	60	61
16	90338345	2440450552	60	61
17	83257441	2532294597	60	61
18	80373285	2616939723	60	61
19	58617616	2698652623	60	61
20	64444167	2758247260	60	61
21	46709983	2823765557	60	61
22	50818468	2871254100	60	61
X	156040895	2922919602	60	61
Y	57227415	3081561243	60	61
MT	16569	3139742506	60	61
rDNA_repeat	42999	3139759365	70	71
```


# Coverage calculation

The general computational problem corresponds to calculating read depth (or coverage) for genomic regions defined in a BED file, based on a BAM read alignment file.

I have explored the four different methods `bedtools genomecov`, `bedtools multicov`, `bedtools coverage`, `samtools bedcov`. Ultimately, I use `samtools bedcov` for estimating rDNA and mtDNA copy numbers.

I find the behaviour of (some of) these tools unexpected, and will therefore briefly summarise their function and output.

1. `bedtools genomecov -d` calculates the coverage (depth) at each genome position with 1-based coordinates. In other words, `bedtools genomecov -d -ibam <BAM> -g <genome>` returns the per-bp coverage of the full genome based on aligned reads from the BAM file. The resulting output file has the three columns chromosome, 1-based position, coverage, and is generally *very* large (around 40 GB for the human reference genome consisting of chromosomes 1-22, X, Y, MT and a single rDNA copy). Since this methods does not automatically consider features from an independent BED file, we would have to manually sum and average per-base coverages for every feature from a BED file. For details on command line options, see [here](http://bedtools.readthedocs.io/en/latest/content/tools/genomecov.html).  

2. `bedtools multicov -bams <BAM> -bed <BED>` calculates the number of aligned reads from the BAM file that overlap with a feature from the BED file. By default, the count for a feature A from the BED file is increased if the overlap between an aligned read and A is ≥1 bp. Duplicate reads and QC-failed reads *are not counted* by default. For details on command line options, see [here](http://bedtools.readthedocs.io/en/latest/content/tools/multicov.html).

3. `bedtools coverage -abam <BAM> -b <BED>` also calculates the number of aligned reads from the BAM file that overlap with a feature from the BED file. The behaviour of `bedtools coverage` has changed between different versions: In older versions (<2.24.0) coverage was computed for the `-b` file, while in newer versions (≥2.24.0) coverage is computed for the `-a`/`-ibam` file. Additionally older versions may or may not accept BAM file inputs. For details on command line options of the most recent version, see [here](http://bedtools.readthedocs.io/en/latest/content/tools/coverage.html). Duplicate reads and QC-failed reads *are counted* by default (see [here](https://www.biostars.org/p/195497/) for an extended disussion on biostars). I find `bedtools coverage` to be the most inconsistent, especially since different versions will break reproducibility of results.

4. `samtools bedcov <BED> <BAM>` calculates the sum of per-base read coverage for every feature from the BED file. There exists [a samtools github issue](https://github.com/samtools/samtools/issues/588), where the original `samtools bedcov` description of "Reports read depth per genomic region, as specified in the supplied BED file" was identified as being misleading. This has been fixed in recent versions. According to a [discussion on SEQanswers](http://seqanswers.com/forums/showthread.php?t=71987), `samtools bedcov` skips marked duplicates, unaligned entries, secondary alignments and alignments marked as QC-failed. This method allows to calculate mean per-base coverage per feature as "mean per-bp coverage of feature A" equals "sum of per-base read coverage of feature A" divided by the "length of feature A", under the assumption of uniform read coverage across a feature A. This is the quantity that I use for comparing read-coverages of autosomal, mitochondrial and ribosomal DNA.
