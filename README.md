# CN_WGS

# Genome reference

1. Homo_sapiens.GRCh38.dna_rm.toplevel.fa  
    The toplevel assembly includes chromosomes, any unlocalised or unplaced scaffolds, and alternate sequences (alternate loci, fix patches, novel patches). This is the largest continuous sequence for an organism.
2. Homo_sapiens.GRCh38.dna_rm.primary_assembly.fa  
    The primary assembly includes chromosomes,  and any unlocalised or unplaced scaffolds. It does *not* include alternate sequences.

For details, see [here](http://www.ensembl.org/info/website/glossary.html).

We need to make sure to exclude any unlocalised, unplaced, and placed scaffolds, as they may contain (incomplete) sequences of the human rDNA repeat. For example, GL000220.1 seems to contain (parts of) the human rDNA repeat unit U13369.1.

Therefore we manually download all diploid chromosome sequences including X, Y and MT manually, and concatenate all sequence files including one copy of the U13369.1 rDNA sequence.


# Coverage calculation

The general computational problem corresponds to calculating read depth (or coverage) for genomic regions defined in a BED file, based on a BAM read alignment file.

I have explored the four different methods `bedtools genomecov`, `bedtools multicov`, `bedtools coverage`, `samtools bedcov`. Ultimately, I use `samtools bedcov` for estimating rDNA and mtDNA copy numbers.

I find the behaviour of (some of) these tools unexpected, and will therefore briefly summarise their function and output.

1. `bedtools genomecov -d` calculates the coverage (depth) at each genome position with 1-based coordinates. In other words, `bedtools genomecov -d -ibam <BAM> -g <genome>` returns the per-bp coverage of the full genome based on aligned reads from the BAM file. The resulting output file has the three columns chromosome, 1-based position, coverage, and is generally *very* large (around 40 GB for the human reference genome consisting of chromosomes 1-22, X, Y, MT and a single rDNA copy). Since this methods does not automatically consider features from an independent BED file, we would have to manually sum and average per-base coverages for every feature from a BED file. For details on command line options, see [here](http://bedtools.readthedocs.io/en/latest/content/tools/genomecov.html).  

2. `bedtools multicov -bams <BAM> -bed <BED>` calculates the number of aligned reads from the BAM file that overlap with a feature from the BED file. By default, the count for a feature A from the BED file is increased if the overlap between an aligned read and A is ≥1 bp. Duplicate reads and QC-failed reads *are not counted* by default. For details on command line options, see [here](http://bedtools.readthedocs.io/en/latest/content/tools/multicov.html).

3. `bedtools coverage -abam <BAM> -b <BED>` also calculates the number of aligned reads from the BAM file that overlap with a feature from the BED file. The behaviour of `bedtools coverage` has changed between different versions: In older versions (<2.24.0) coverage was computed for the `-b` file, while in newer versions (≥2.24.0) coverage is computed for the `-a`/`-ibam` file. Additionally older versions may or may not accept BAM file inputs. For details on command line options of the most recent version, see [here](http://bedtools.readthedocs.io/en/latest/content/tools/coverage.html). Duplicate reads and QC-failed reads *are counted* by default (see [here](https://www.biostars.org/p/195497/) for an extended disussion on biostars). I find `bedtools coverage` to be the most inconsistent, especially since different versions will break reproducibility of results.

4. `samtools bedcov <BED> <BAM>` calculates the sum of per-base read coverage for every feature from the BED file. There exists [a samtools github issue](https://github.com/samtools/samtools/issues/588), where the original `samtools bedcov` description of "Reports read depth per genomic region, as specified in the supplied BED file" was identified as being misleading. This has been fixed in recent versions. According to a [discussion on SEQanswers](http://seqanswers.com/forums/showthread.php?t=71987), `samtools bedcov` skips marked duplicates, unaligned entries, secondary alignments and alignments marked as QC-failed. This method allows to calculate mean per-base coverage per feature as "mean per-bp coverage of feature A" equals "sum of per-base read coverage of feature A" divided by the "length of feature A", under the assumption of uniform read coverage across a feature A. This is the quantity that I use for comparing read-coverages of autosomal, mitochondrial and ribosomal DNA.
