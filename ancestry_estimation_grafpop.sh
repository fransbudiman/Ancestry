#!/bin/bash

# Enable debugging
set -x

# Set arguments
VCF_FILE=$1
RESULT_FILE=$2
PNG_FILE=$3

{
    # Check if arguments are empty
    if [ -z "$VCF_FILE" ] || [ -z "$RESULT_FILE" ] || [ -z "$PNG_FILE" ]; then
        echo "Missing arguments. Please provide VCF file, result file, and PNG file."
        exit 1
    fi

    # Check if grafpop and PlotGrafPopResults.pl executable exist
    if [ ! -f "/usr/local/bin/grafpop" ]; then
        echo "grafpop executable not found. Installing it . . ."
        mkdir GrafPop
        cd GrafPop
        # Download and extract GrafPop
        if ! command -v wget &> /dev/null; then
            echo "wget is not installed. Please install it."
            exit 1
        fi
        
        wget https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/GetZip.cgi?zip_name=GrafPop1.0.tar.gz
        if [ $? -ne 0 ]; then
            echo "Error downloading GrafPop."
            exit 1
        fi

        tar -xvzf GetZip.cgi?zip_name=GrafPop1.0.tar.gz
        if [ $? -ne 0 ]; then
            echo "Error extracting the tarball."
            exit 1
        fi
        
        mv GrafPop /opt/
        sudo ln -s /opt/GrafPop/grafpop /usr/local/bin/grafpop
        sudo ln -s /opt/GrafPop/PlotGrafPopResults.pl /usr/local/bin/PlotGrafPopResults.pl
    fi

    # Check perl path and update PlotGrafPopResults.pl shebang
    PERL_PATH=$(which perl)
    if [ -z "$PERL_PATH" ]; then
        echo "perl not found. Please install perl."
        exit 1
    else
        sed -i "1s|^#!.*|#!$PERL_PATH|" /opt/GrafPop/PlotGrafPopResults.pl
        sudo cpan GD::Text
        sudo cpan GD::Graph
    fi

    # Run grafpop and PlotGrafPopResults.pl
    grafpop "$VCF_FILE" "$RESULT_FILE"
    PlotGrafPopResults.pl "$RESULT_FILE" "$PNG_FILE"

} 2>&1 | tee -a grafpop.log
