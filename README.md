# CN_WGS

# Genome reference

1. Homo_sapiens.GRCh38.dna_rm.toplevel.fa  
    The toplevel assembly includes chromosomes, any unlocalised or unplaced scaffolds, and alternate sequences (alternate loci, fix patches, novel patches). This is the largest continuous sequence for an organism.
2. Homo_sapiens.GRCh38.dna_rm.primary_assembly.fa  
    The primary assembly includes chromosomes,  and any unlocalised or unplaced scaffolds. It does *not* include alternate sequences.

For details, see [here](http://www.ensembl.org/info/website/glossary.html).

We need to make sure to exclude any unlocalised, unplaced, and placed scaffolds, as they may contain (incomplete) sequences of the human rDNA repeat. For example, GL000220.1 seems to contain (parts of) the human rDNA repeat unit U13369.1.

Therefore we manually download all diploid chromosome sequences including X, Y and MT manually, and concatenate all sequence files including one copy of the U13369.1 rDNA sequence.
