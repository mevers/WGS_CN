#!/bin/bash

# Make graphs
snakemake --dag | dot -Tpdf > dag.pdf
snakemake --dag | dot -Tpng > dag.png
snakemake --rulegraph | dot -Tpdf -Gratio=0.5 > rulegraph.pdf
snakemake --rulegraph | dot -Tpng -Gratio=0.5 > rulegraph.png
snakemake --rulegraph > rulegraph.dot

# Run snakemake
snakemake --configfile config.yaml \
	  --snakefile Snakefile \
	  --jobs 10 \
	  --printshellcmds \
	  --cluster "qsub -pe threads {cluster.threads} \
                          -q {cluster.queue} \
                          -l virtual_free={cluster.virtual_free} \
                          -l h_vmem={cluster.h_vmem} \
                          -o {cluster.outstream} \
                          -e {cluster.errorstream}" \
          --cluster-config cluster.yaml
