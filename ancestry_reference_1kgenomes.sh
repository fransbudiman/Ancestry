#!/bin/bash

set -x

# TEMPDIR is temporary and everythin inside will be deleted at the end of the script
# The final data will be in REFDIR under the name of 1KGenomes.admixture
# Paths
CONFIG=${PWD}/Configuration
REFDIR=${CONFIG}/Reference_1KGenomes
TEMPDIR=${REFDIR}/TEMP
LOG=${REFDIR}/LOG

mkdir -p ${REFDIR}
mkdir -p ${TEMPDIR}
mkdir -p ${LOG}

cd ${TEMPDIR}

{
    ##### SETUP FOR 1000Genomes phase 3 DATA #####
    # Note that these links may be outdated.
    # Visit  https://www.cog-genomics.org/plink/2.0/resources#1kg_phase3 for the most recent links
    pgen="https://www.dropbox.com/s/j72j6uciq5zuzii/all_hg38.pgen.zst?dl=1"
    pvar="https://www.dropbox.com/scl/fi/fn0bcm5oseyuawxfvkcpb/all_hg38_rs.pvar.zst?rlkey=przncwb78rhz4g4ukovocdxaz&dl=1"
    sample="https://www.dropbox.com/s/gyobtdi904m9bir/hg38_orig.psam?dl=1"

    wget $pgen
    mv 'all_hg38.pgen.zst?dl=1' all_phase3.pgen.zst
    plink2 --zst-decompress all_phase3.pgen.zst > all_phase3.pgen

    wget $pvar
    mv 'all_hg38_rs.pvar.zst?rlkey=przncwb78rhz4g4ukovocdxaz&dl=1' all_phase3.pvar.zst
    plink2 --zst-decompress all_phase3.pvar.zst > all_phase3.pvar

    wget $sample
    mv 'hg38_orig.psam?dl=1' all_phase3.psam

    # Convert to Plink binary
    plink2 --pfile ${TEMPDIR}/all_phase3 \
        --max-alleles 2 \
        --make-bed \
        --allow-extra-chr \
        --out ${TEMPDIR}/all_phase3
    mv ${TEMPDIR}/plink2.log ${REFDIR}/log

    ## Make the binary files WITHOUT rsIDs
    plink2 --bfile ${TEMPDIR}/all_phase3 \
        --make-bed \
        --set-all-var-ids @:\#:\$r:\$a \
        --new-id-max-allele-len 997 \
        --allow-extra-chr \
        --out ${TEMPDIR}/all_phase3_replace_var_ids
    mv ${TEMPDIR}/all_phase3_replace_var_ids.LOG ${LOG}


    ## Filter reference and study data for non A-T or G-C SNPs and remove duplicates
    awk 'BEGIN {OFS="\t"} ($5$6 == "GC" || $5$6 == "CG" || $5$6 == "AT" || $5$6 == "TA") {print $2}' \
    ${TEMPDIR}/all_phase3_replace_var_ids.bim > \
    ${TEMPDIR}/all_phase3_replace_var_ids.ac_gt_snps

    plink2 --bfile ${TEMPDIR}/all_phase3_replace_var_ids \
    --exclude ${TEMPDIR}/all_phase3_replace_var_ids.ac_gt_snps \
    --make-bed \
    --allow-extra-chr \
    --rm-dup force-first \
    --out ${REFDIR}/1KGenomes.admixture

    mv ${REFDIR}/1KGenomes.admixture.LOG ${LOG}
    rm -r ${TEMPDIR}

} 2>&1 | tee ${LOG}/1KGenomes.log
