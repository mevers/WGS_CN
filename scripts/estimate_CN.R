#!/usr/bin/env Rscript

# The R command line script estimates copy numbers of
# ribosomal and mitochondrial DNA from a comparison of read coverages.
#
# Author: Maurits Evers (maurits.evers@anu.edu.au)
# Original date: 04/07/2017
# Last change: 04/07/2017


## ------------------------------------------------------------------------
## Start clock
t0 <- Sys.time();


## ------------------------------------------------------------------------
## Load libraries
suppressMessages(library(optparse));    # Python-style command line args
suppressMessages(library(ggplot2));     # Plotting
suppressMessages(library(reshape2));    # Reshaping dataframes


## ------------------------------------------------------------------------
## Parse command line arguments
option_list <- list(
    make_option(
        c("-i", "--input"),
        type = "character",
        default = NULL,
        help = "(Comma-separated list of) input file(s)",
        metavar = "character"),
    make_option(
        c("-o", "--outdir"),
        type = "character",
        default = ".",
        help = "Output directory [default %default]",
        metavar = "character"),
    make_option(
        c("--skipZeros"),
        action = "store_true",
        type = "logical",
        default = FALSE,
        help = "Skip regions with zero coverage [default %default]"),
    make_option(
        c("--plotCoverage"),
        action = "store_true",
        type = "logical",
        default = FALSE,
        help = "Make coverage plots per sample [default %default]"),
    make_option(
        c("--saveRData"),
        action = "store_true",
        type = "logical",
        default = FALSE,
        help = "Save results in RData file [default %default]")
);
opt_parser <- OptionParser(option_list = option_list);
args <- parse_args(opt_parser);
if (is.null(args$input)) {
    print_help(opt_parser);
    stop("At least one coverage file must be supplied.\n", call. = FALSE);
}


## ------------------------------------------------------------------------
## Timestamp function
ts <- function() {
    return(format(Sys.time(), "[%a %b %d %Y %H:%M:%S]"));
}


## ------------------------------------------------------------------------
## Custom function
calculateCN <- function(
    fn,
    skipZeros = TRUE,
    saveRData = TRUE,
    plotCoverage = TRUE,
    outdir = ".") {
    bname <- basename(fn);
    d <- read.table(fn, stringsAsFactors = FALSE);
    flagZeros <- ifelse(isTRUE(skipZeros), "noZeros", "withZeros");
    if (isTRUE(skipZeros)) {
        # Filter null entries
        d <- d[which(d[, 5] > 0), ];
    }
    # Skip incomplete windows
    #wsize <- as.numeric(gsub("(cov_genome_w|_s\\d+.*)", "", bname));
    #d <- d[which(d[, 3] - d[, 2] == wsize), ];
    d[, 5] <- d[, 5] / (d[, 3] - d[, 2]);
    # Split genome data based on pleudity/CN
    lst <- list(
        diploid = d[which(d[, 1] %in% seq(1, 22)), ],
        X = d[which(d[, 1] == "X"), ],
        Y = d[which(d[, 1] == "Y"), ],
        MT = d[which(d[, 1] == "MT"), ],
        rDNA = d[which(d[, 1] == "rDNA_repeat"), ]);
    # Calculate summary statistics
    # (1) Lower and higher 95% CI for the mean are given by
    #     mean +- t_{alpha/2, n-1} * SD / sqrt(n)
    # (2) Lower and higher 95% CI for the median are given by
    #     median +- 1.253 * 1.96 * (n/(n-0.8)) * MAD / sqrt(n)
    # http://scialert.net/fulltext/?doi=jas.2009.2835.2840
    sumstat <- do.call(rbind, lapply(lst, function(x) {
        cbind.data.frame(
            median = median(x$V5),
            mad = mad(x$V5),
            CI.l.median = median(x$V5) - 1.253 * 1.96 * (length(x$V5) / (length(x$V5) - 0.8)) * mad(x$V5) / sqrt(length(x$V5)),
            CI.h.median = median(x$V5) + 1.253 * 1.96 * (length(x$V5) / (length(x$V5) - 0.8)) * mad(x$V5) / sqrt(length(x$V5)),
            mean = mean(x$V5),
            sd = sd(x$V5),
            sem = sd(x$V5) / sqrt(length(x$V5)),
            CI.l.mean = mean(x$V5) - 1.96 * sd(x$V5) / sqrt(length(x$V5)),
            CI.h.mean = mean(x$V5) + 1.96 * sd(x$V5) / sqrt(length(x$V5)));
    }))
    # Plot coverage distribution
    if (isTRUE(plotCoverage)) {
        df <- d;
        df$pleudity <- df[, 1];
        df$pleudity <- gsub(
            paste("(", paste(seq(1, 22), collapse = "|"), ")", sep = ""),
            "diploid",
            df$pleudity);
        df$pleudity <- gsub(
            "rDNA_repeat",
            "rDNA",
            df$pleudity);
        gg <- ggplot(df, aes(x = pleudity, y = V5));
        gg <- gg + geom_boxplot();
        gg <- gg + theme_bw();
        gg <- gg + scale_y_log10();
        gg <- gg + labs(x = "Reference", y = "Coverage");
        ggsave(
            sprintf("%s/boxplot_%s_%s.pdf",
                outdir,
                gsub(".bed", "", bname),
                flagZeros),
            gg,
            width = 7,
            height = 5);
        cat(sprintf(
            "%s Generated coverage plot %s.\n",
            ts(),
            sprintf("%s/boxplot_%s_%s.pdf",
                outdir,
                gsub(".bed", "", bname),
                flagZeros)));
    }
    # Infer copy numbers
    CN <- cbind.data.frame(
        what = c("MT", "rDNA"),
        mean = c(
            2 * sumstat["MT", "mean"] / (sumstat["diploid", "mean"]),
            2 * sumstat["rDNA", "mean"] / (sumstat["diploid", "mean"])),
        se = c(
            2 * sumstat["MT", "mean"] / (sumstat["diploid", "mean"]) *
                sqrt((sumstat["MT", "sem"]/sumstat["MT", "mean"])^2 +
                    (sumstat["diploid", "sem"]/sumstat["diploid", "mean"])^2),
            2 * sumstat["rDNA", "mean"] / (sumstat["diploid", "mean"]) *
                sqrt((sumstat["rDNA", "sem"]/sumstat["rDNA", "mean"])^2 +
                    (sumstat["diploid", "sem"]/sumstat["diploid", "mean"])^2)));
    ret <- list(
        src = gsub(".bed", "", bname),
        skipZeros = skipZeros,
        cov = sumstat,
        CN = CN);
    if (isTRUE(saveRData)) {
        save(
            ret,
            file = sprintf(
                "%s/CN_%s_%s.RData",
                    outdir,
                    gsub(".bed", "", bname),
                    flagZeros));
        cat(sprintf(
            "%s Saved results in %s.\n",
            ts(),
            sprintf("%s/CN_%s_%s.RData",
                outdir,
                gsub(".bed", "", bname),
                flagZeros)));
    }
    return(ret);
}


## ------------------------------------------------------------------------
## Global variables
fn <- unlist(strsplit(args$input, ","));
outdir <- gsub("/$", "", args$outdir);
skipZeros <- args$skipZeros;
plotCoverage <- args$plotCoverage;
saveRData <- args$saveRData;
cat(sprintf("%s Parameter summary\n", ts()));
for (i in 1:length(fn)) {
    cat(sprintf(" Input          = %s\n", fn[i]));
}
cat(sprintf(" outdir         = %s\n", outdir));
cat(sprintf(
    " skipZeros      = %s\n",
    ifelse(isTRUE(skipZeros), "TRUE", "FALSE")));
cat(sprintf(
    " plotCoverage   = %s\n",
    ifelse(isTRUE(plotCoverage), "TRUE", "FALSE")));
cat(sprintf(
    " saveRData      = %s\n",
    ifelse(isTRUE(saveRData), "TRUE", "FALSE")));


## ------------------------------------------------------------------------
# Check if input files and output directory exists
for (i in 1:length(fn)) {
    if (!file.exists(fn[i])) {
        stop(
            sprintf("Input file %s does not exists.\n", fn[i]),
            call. = FALSE);
    }
}
if (!file.exists(outdir)) {
    stop(
        sprintf("Output directory %s does not exists.\n", outdir),
        call. = FALSE);
}


## ------------------------------------------------------------------------
# Determine coverage distribution and estimate CN
cat(sprintf(
    "%s Calculating mean coverage and estimating copy numbers.\n",
    ts()));
flagZeros <- ifelse(isTRUE(skipZeros), "noZeros", "withZeros");
CN <- lapply(fn, function(x) {
    calculateCN(
        x,
        skipZeros = skipZeros,
        saveRData = saveRData,
        plotCoverage = plotCoverage,
        outdir = outdir)
});
names(CN) <- gsub("(cov_genome_w\\d+_s\\d+_|.bed)", "", basename(fn));


## ------------------------------------------------------------------------
# Prepare for plotting
cat(sprintf(
    "%s Producing final plots.\n",
    ts()));
meanCN <- lapply(CN, function(x) x$CN);
df <- melt(meanCN, id.vars = c("what", "mean", "se"));


## ------------------------------------------------------------------------
# Plot
gg <- ggplot(df, aes(x = L1, y = mean));
gg <- gg + geom_bar(stat = "identity");
gg <- gg + geom_errorbar(
    aes(ymin = mean - se, ymax = mean + se),
    width = 0.1);
gg <- gg + geom_text(
    aes(x = L1, y = mean/2, label = paste(round(mean), "\u00B1", round(se))),
    colour = "white");
gg <- gg + facet_wrap(~ what);
gg <- gg + theme_bw();
gg <- gg + labs(x = "Sample", y = "CN");
gg <- gg + theme(
    strip.background = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    rect = element_rect(fill = "transparent"),
    panel.background = element_rect(fill = "transparent"),
    plot.background = element_rect(fill = "transparent", colour = NA),
    legend.position = "bottom");
ggsave(
    sprintf("%s/CN_%s.pdf", outdir, flagZeros),
    gg,
    width = 8,
    height = 6);
