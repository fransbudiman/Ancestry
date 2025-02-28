#!/bin/bash

set -x

# Paths
CONFIG=${PWD}/Configuration
REFDIR=${CONFIG}/Reference_HapMap3
TEMPDIR=${REFDIR}/TEMP
LOG=${REFDIR}/LOG

mkdir -p ${REFDIR}
mkdir -p ${TEMPDIR}
mkdir -p ${LOG}

cd ${TEMPDIR}

{
  ##### SETUP FOR THE HAPMAP PHASE III DATA #####
  FTP=FTP://FTP.ncbi.nlm.nih.gov/hapmap/genotypes/2009-01_phaseIII/plink_format/
  PREFIX=hapmap3_r2_b36_fwd.consensus.qc.poly

  wget ${FTP}/${PREFIX}.map.bz2
  bunzip2 ${PREFIX}.map.bz2

  wget ${FTP}/${PREFIX}.ped.bz2
  bunzip2 ${PREFIX}.ped.bz2

  wget ${FTP}/relationships_w_pops_121708.txt

  # Convert to Plink binary
  plink --file ${TEMPDIR}/${PREFIX} \
        --make-bed \
        --out ${TEMPDIR}/HapMapIII_NCBI36

  mv ${TEMPDIR}/HapMapIII_NCBI36.log ${LOG}

  awk '{print "chr" $1, $4 -1, $4, $2 }' ${TEMPDIR}/HapMapIII_NCBI36.bim | \
      sed 's/chr23/chrX/' | sed 's/chr24/chrY/' > \
      ${TEMPDIR}/HapMapIII_NCBI36.tolift
      
  # download over chain
  wget https://hgdownload.cse.ucsc.edu/goldenpath/hg18/liftOver/hg18ToHg19.over.chain.gz
  gunzip hg18ToHg19.over.chain.gz

  # download the liftOver tool
  wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver
  
  ./liftOver ${TEMPDIR}/HapMapIII_NCBI36.tolift ${CONFIG}/hg18ToHg19.over.chain \
     ${TEMPDIR}/HapMapIII_CGRCh37 ${TEMPDIR}/HapMapIII_NCBI36.unMapped

  # extract mapped variants
  awk '{print $4}' ${TEMPDIR}/HapMapIII_CGRCh37 > ${TEMPDIR}/HapMapIII_CGRCh37.snps
  # extract updated positions
  awk '{print $4, $3}' ${TEMPDIR}/HapMapIII_CGRCh37 > ${TEMPDIR}/HapMapIII_CGRCh37.pos

  ## Make the binary files with rsIDs
  plink --bfile ${TEMPDIR}/HapMapIII_NCBI36 \
      --extract ${TEMPDIR}/HapMapIII_CGRCh37.snps \
      --update-map ${TEMPDIR}/HapMapIII_CGRCh37.pos \
      --make-bed \
      --out ${TEMPDIR}/HapMapIII_CGRCh37
  mv ${TEMPDIR}/HapMapIII_CGRCh37.LOG ${LOG}

  ## Make the binary files WITHOUT rsIDs
  plink2 --bfile ${TEMPDIR}/HapMapIII_CGRCh37 \
      --make-bed \
      --set-all-var-ids @:\#:\$r:\$a \
      --new-id-max-allele-len 997 \
      --allow-extra-chr \
      --out ${TEMPDIR}/HapMapIII_CGRCh37_replace_var_ids
  mv ${TEMPDIR}/HapMapIII_CGRCh37_replace_var_ids.LOG ${LOG}


  ## Filter reference and study data for non A-T or G-C SNPs and remove duplicates
  awk 'BEGIN {OFS="\t"} ($5$6 == "GC" || $5$6 == "CG" || $5$6 == "AT" || $5$6 == "TA") {print $2}' \
  ${TEMPDIR}/HapMapIII_CGRCh37_replace_var_ids.bim > \
  ${TEMPDIR}/HapMapIII_CGRCh37_replace_var_ids.ac_gt_snps

  plink2 --bfile ${TEMPDIR}/HapMapIII_CGRCh37_replace_var_ids \
  --exclude ${TEMPDIR}/HapMapIII_CGRCh37_replace_var_ids.ac_gt_snps \
  --make-bed \
  --allow-extra-chr \
  --rm-dup force-first \
  --out ${REFDIR}/HapMapIII_CGRCh37.admixture

  mv ${REFDIR}/HapMapIII_CGRCh37.admixture.LOG ${LOG}

  rm -r ${TEMPDIR}
} 2>&1 | tee ${LOG}/HapMap3.log
