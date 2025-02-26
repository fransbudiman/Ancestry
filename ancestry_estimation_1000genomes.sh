#!/bin/bash

#enable debugging
set -x

# TO RUN: set -i as sample name, -v as path to VCF file, -o path to desired output location, -c as threads to use.
# The population reference dataset should be in $PWD/Configuration/Reference_1000Genomes/1000Genomes_CGRCh37.admixture.
# the ID to Pop text file should be in $PWD/Configuration//Genomes1000_ID2Pop.txt.
# admixture_pie.R is in current working directory.

#set default values from command line arguments
while getopts ":i:v:o:c:" flag
do
    case "${flag}" in
        i) SAMPLE=${OPTARG};;
        v) VCF=${OPTARG};;
        o) OUTDIR=${OPTARG};;
        c) CPU=${OPTARG};;
        #if an invalid option is entered, the script will exit
        \?) valid=0
            echo "An invalid option has been entered: $OPTARG"
            exit 0
            ;;
        #if an option is entered without an argument, the script will exit
        :)  valid=0
            echo "The additional argument for option $OPTARG was omitted."
            exit 0
            ;;

    esac
done

shift "$(( OPTIND - 1 ))"

#checks if the required arguments are not empty
if [ -z "$SAMPLE" ]; then
        echo 'Missing -i ID' >&2
        exit 1
fi

if [ -z "$VCF" ]; then
        echo 'Missing -v VCF file' >&2
        exit 1
fi

if [ -z "$OUTDIR" ]; then
        echo 'Missing -o output directory' >&2
        exit 1
fi

if [ -z "$CPU" ]; then
      echo 'Missing -c CPU' >&2
      exit 1
fi

echo $SAMPLE
echo $VCF
echo $OUTDIR
echo $CPU

# sample directories
# OUTDIR=
SAMPLEDIR=${OUTDIR}/${SAMPLE}/${SAMPLE}_ANCESTRY_REPORT
SAMPLE_SUP=${OUTDIR}/${SAMPLE}/${SAMPLE}_ANCESTRY_SUPPLEMENTARY
TEMPDIR=${SAMPLE_SUP}/TEMP
LOG=${SAMPLE_SUP}/LOG

mkdir -p ${SAMPLEDIR}
mkdir -p ${SAMPLE_SUP}
mkdir -p ${TEMPDIR}
mkdir -p ${LOG}

# reference files
CONFIG=$PWD/Configuration
REF_1KGENOMES=${CONFIG}/Reference_1000Genomes
REF_BED_1KGENOMES=${REF_1KGENOMES}/1KGenomes.admixture
REF_1KGENOMES_POP=${CONFIG}/Genomes1000_ID2Pop.txt

{
    # Convert VCF to Plink binary
    plink --vcf ${VCF} \
        --make-bed \
        --const-fid 0 \
        --allow-extra-chr \
        --out ${TEMPDIR}/${SAMPLE}_original

    mv ${TEMPDIR}/${SAMPLE}_original.log ${LOG}/Binary_1.log

    # Set rsID to custom format
    plink2 --bfile ${TEMPDIR}/${SAMPLE}_original \
        --make-bed \
        --set-all-var-ids @:\#:\$r:\$a \
        --new-id-max-allele-len 1000 \
        --allow-extra-chr \
        --out ${TEMPDIR}/${SAMPLE}

    mv ${TEMPDIR}/${SAMPLE}.log ${LOG}/Original_2.log

    ## Filter out AC and GT SNPs
    # Extract SNPs with AC and GT
    awk 'BEGIN {OFS="\t"} ($5$6 == "GC" || $5$6 == "CG" || $5$6 == "AT" || $5$6 == "TA") {print $2}' \
    ${TEMPDIR}/${SAMPLE}.bim > \
    ${TEMPDIR}/${SAMPLE}.ac_gt_snps 

    # Exclude SNPs with AC and GT
    plink2 --bfile ${TEMPDIR}/${SAMPLE} \
        --exclude ${TEMPDIR}/${SAMPLE}.ac_gt_snps \
        --make-bed \
        --allow-extra-chr \
        --out ${TEMPDIR}/${SAMPLE}.no_ac_gt_snps
    mv ${TEMPDIR}/${SAMPLE}.no_ac_gt_snps.log ${LOG}/no_ac_gt_snps_3.log

    ## Prune Study Data

    plink --bfile ${TEMPDIR}/${SAMPLE}.no_ac_gt_snps \
        --exclude range ${CONFIG}/highld.txt \
        --indep-pairwise 50 5 0.2 \
        --make-bed \
        --allow-extra-chr \
        --out ${TEMPDIR}/${SAMPLE}.no_ac_gt_snps_prune_pass1
    mv ${TEMPDIR}/${SAMPLE}.no_ac_gt_snps_prune_pass1.log ${LOG}/no_ac_gt_snps_prune_pass1_4.log

    # Extract pruned SNPs from original data (may need fixing)
    plink --bfile ${TEMPDIR}/${SAMPLE}.no_ac_gt_snps \
        --extract ${TEMPDIR}/${SAMPLE}.no_ac_gt_snps_prune_pass1.bim \
        --make-bed \
        --allow-extra-chr \
        --out ${SAMPLE_SUP}/${SAMPLE}.pruned
    mv ${SAMPLE_SUP}/${SAMPLE}.pruned.log ${LOG}/pruned_5.log

    # Filter reference data to match sample data and remove duplicates
    plink2 --bfile ${REF_BED_1KGENOMES} \
        --extract ${SAMPLE_SUP}/${SAMPLE}.pruned.bim \
        --make-bed \
        --allow-extra-chr \
        --rm-dup force-first \
        --memory 7000 \
        --out ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.pruned.no_dups
    mv ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.pruned.no_dups.log ${LOG}/ref_1KGenomes_pruned_no_dups_6.log

    # Check for chromosome mismatches
    # Create list of SNPs with mismatched chromosomes
    awk 'BEGIN {OFS="\t"} FNR==NR {a[$2]=$1; next} ($2 in a && a[$2] != $1) {print a[$2],$2}' \
    ${SAMPLE_SUP}/${SAMPLE}.pruned.bim ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.pruned.no_dups.bim | \
    sed -n '/^[XY]/!p' > ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.toUpdateChr

    # Use the SNP list to update the chromosome number
    # but since we match SNPs by their rsID which uses their chromosome number
    # the only thing this does is update the chromosome number from
    # X to 23 in the reference data.
    plink --bfile ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.pruned.no_dups \
    --update-chr ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.toUpdateChr 1 2 \
    --make-bed \
    --allow-extra-chr \
    --out ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.updateChr

    # Position match
    # If done correctly, this should not output anything
    awk 'BEGIN {OFS="\t"} FNR==NR {a[$2]=$4; next} \
    ($2 in a && a[$2] != $4) {print a[$2],$2}' \
    ${SAMPLE_SUP}/${SAMPLE}.pruned.bim ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.pruned.no_dups.bim > \
    ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.toUpdatePos

    # Possible allele flip
    # Again, if done correctly, this should not output anything
    awk 'BEGIN {OFS="\t"} FNR==NR {a[$1$2$4]=$5$6; next} \
    ($1$2$4 in a && a[$1$2$4] != $5$6 && a[$1$2$4] != $6$5) {print $2}' \
    ${SAMPLE_SUP}/${SAMPLE}.pruned.bim ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.pruned.no_dups.bim > \
    ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.toFlip

    # Update position mismatches and allele flips
    plink --bfile ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.updateChr \
    --update-map ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.toUpdatePos 1 2 \
    --flip ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.toFlip \
    --make-bed \
    --allow-extra-chr \
    --out ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.flipped
    mv ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.flipped.log ${LOG}/_ref_1KGenomes.flipped_8.log

    # Remove mismatches
    # If done correctly, this should output empty file
    awk 'BEGIN {OFS="\t"} FNR==NR {a[$1$2$4]=$5$6; next} \
    ($1$2$4 in a && a[$1$2$4] != $5$6 && a[$1$2$4] != $6$5) {print $2}' \
    ${SAMPLE_SUP}/${SAMPLE}.pruned.bim ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.flipped.bim > \
    ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.flipped.mismatch

    plink --bfile ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.flipped \
    --exclude ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.flipped.mismatch \
    --make-bed \
    --allow-extra-chr \
    --out ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.clean
    mv ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.clean.log  ${LOG}/_ref_1KGenomes.clean_9.log

    # Merge study genotype data with reference data
    plink --bfile ${SAMPLE_SUP}/${SAMPLE}.pruned \
    --bmerge ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.clean.bed ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.clean.bim \
    ${TEMPDIR}/${SAMPLE}_ref_1KGenomes.clean.fam \
    --make-bed \
    --allow-extra-chr \
    --out ${TEMPDIR}/${SAMPLE}.merge_ref_1KGenomes

    mv ${TEMPDIR}/${SAMPLE}.merge_ref_1KGenomes.log ${LOG}/merge_ref_1KGenomes_10.log

    # Prepare for admixture
    # Removes variants that is 99.9% missing in the merged dataset
    plink --bfile ${TEMPDIR}/${SAMPLE}.merge_ref_1KGenomes \
    --geno 0.999 \
    --make-bed \
    --allow-extra-chr \
    --out ${SAMPLE_SUP}/${SAMPLE}.admixture_ref_1KGenomes
    mv ${SAMPLE_SUP}/${SAMPLE}.admixture_ref_1KGenomes.log ${LOG}/admixture_ref_1KGenomes_11.log

    # Create a text file with population information (sampleID, ancestry)
    awk 'FNR==NR{a[$2]=$3;next}{print $0,a[$2]?a[$2]:"-"}' ${REF_1KGENOMES_POP} ${SAMPLE_SUP}/${SAMPLE}.admixture_ref_1KGenomes.fam \
    > ${SAMPLE_SUP}/${SAMPLE}.admixture_ref_1KGenomes.txt

    # Use the text file to create a pop file
    awk '{print $7}' ${SAMPLE_SUP}/${SAMPLE}.admixture_ref_1KGenomes.txt > ${SAMPLE_SUP}/${SAMPLE}.admixture_ref_1KGenomes.pop

    # Run admixture
    admixture ${SAMPLE_SUP}/${SAMPLE}.admixture_ref_1KGenomes.bed 26 --supervised -j${CPU}
    mv ${SAMPLE}.admixture_ref_1KGenomes.26.Q ${SAMPLE_SUP}
    mv ${SAMPLE}.admixture_ref_1KGenomes.26.P ${SAMPLE_SUP}

    # rm -r ${TEMPDIR}
    # run R script to generate pie chart
    Rscript admixture_pie.R ${SAMPLEDIR} ${SAMPLE}_1KGenomes ${SAMPLE_SUP}/${SAMPLE}.admixture_ref_1KGenomes.26.Q \
    ${SAMPLE_SUP}/${SAMPLE}.admixture_ref_1KGenomes.fam ${REF_1KGENOMES_POP} "1000Genomes" ${CONFIG}

} 2>&1 | tee ${LOG}/ancestry.log
