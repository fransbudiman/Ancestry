# Ancestry

This repository outlines an end-to-end pipeline utilizing PLINK and Admixture to estimate large-scale ancestry.

## Built With
- PLINK
- Admixture
- R

## Getting Started
### Installation
```
git clone https://github.com/jlelabs/Ancestry
```
### Usage
Preamble for HapMap3 reference dataset
```
./ancestry_hapmap3.sh
```

Download and configure NA12878 sample for ancestry estimation
```
./NA12878.sh
```

Run main ancestry script
```
ancestry.sh -i ${SAMPLEID} -v ${VCF} -o ${OUTPUT_DIRECTORY}
```
