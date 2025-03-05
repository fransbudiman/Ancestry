#!/bin/bash

#enable debugging
set -x

# set arguments
VCF_FILE=$1
RESULT_FILE=$2
PNG_FILE=$3

{
# check if arguments are empty
if [ -z "$VCF_FILE" ] || [ -z "$RESULT_FILE" ] || [ -z "$PNG_FILE" ]; then
    echo "Missing arguments. Please provide VCF file, result file, and PNG file."
    exit 1
fi

# check if grafpop and PlotGrafPopResults.pl executable exist
GRAFPOP_DIR=$(which grafpop)
PLOTGRAFPOP_DIR=$(which PlotGrafPopResults.pl)
if [ -z "$GRAFPOP_DIR" ]; then
    echo "grafpop executable or PlotGrafPopResults.pl not found. Installing them . . ."
    wget https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/GetZip.cgi?zip_name=GrafPop1.0.tar.gz
    tar -xvzf GetZip.cgi?zip_name=GrafPop1.0.tar.gz
    mkdir GrafPop
    mv * GrafPop
    mv GrafPop /opt/
    sudo ln -s /opt/GrafPop/grafpop /usr/local/bin/grafpop
    sudo ln -s /opt/GrafPop/PlotGrafPopResults.pl /usr/local/bin/PlotGrafPopResults.pl
fi

# check perl path and update PlotGrafPopResults.pl shebang
PERL_PATH=$(which perl)
if [ -z "$PERL_PATH" ]; then
    echo "perl not found. Please install perl."
    exit 1
else
    sed -i "1s|^#!.*|#!$PERL_PATH|" /opt/GrafPop/PlotGrafPopResults.pl
    sudo cpan GD::Text
    sudo cpan GD::Graph
fi

# to run: grafpop <vcf_file> <result_file>
grafpop $1 $2

# to plot: PlotGrafPopResults.pl <result_file> <png_file>
PlotGrafPopResults.pl $2 $3

} 2>&1 | tee -a grafpop.log
