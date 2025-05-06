#!/bin/bash

# Enable debugging
set -x

# Set arguments
while getopts ":v:d:" flag
do
    case "${flag}" in
        v) VCF_FILE=${OPTARG};;
        d) OUTDIR=${OPTARG};;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :)  echo "Missing argument for -$OPTARG" >&2; exit 1 ;;
    esac
done

{
    # Check if arguments are empty
    if [ -z "$VCF_FILE" ] || [ -z "$OUTDIR" ]; then
        echo "Missing arguments. Please provide VCF file and result directory."
        exit 1
    fi

    mkdir -p $OUTDIR

    # Check if grafpop and PlotGrafPopResults.pl executable exist
# Check if grafpop and PlotGrafPopResults.pl executable exist
    if [ ! -f "$HOME/bin/grafpop" ]; then
        echo "grafpop executable not found. Installing it . . ."
        mkdir -p "$HOME/bin"

        # Check if wget is installed
        if ! command -v wget &> /dev/null; then
            echo "wget is not installed. Please install it."
            exit 1
        fi

        # Set download path
        ZIP_PATH="$HOME/bin/GrafPop1.0.tar.gz"
        wget -O "$ZIP_PATH" "https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/GetZip.cgi?zip_name=GrafPop1.0.tar.gz"
        if [ $? -ne 0 ]; then
            echo "Error downloading GrafPop."
            exit 1
        fi

        # Extract directly into $HOME/bin
        tar -xvzf "$ZIP_PATH" -C "$HOME/bin"
        if [ $? -ne 0 ]; then
            echo "Error extracting the tarball."
            exit 1
        fi
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

    SAMPLE_NAME="${VCF_FILE%%.*}"
    PNG_FILE="${SAMPLE_NAME}_ancestry.png"
    RESULT_FILE="${SAMPLE_NAME}_temp.txt"
    SAVE_FILE="${SAMPLE_NAME}_ancestry.txt"
    
    # Run grafpop and PlotGrafPopResults.pl
    grafpop "$VCF_FILE" "$OUTDIR/$RESULT_FILE"
    PlotGrafPopResults.pl "$OUTDIR/$RESULT_FILE" "$OUTDIR/$PNG_FILE"
    SaveSamples.pl "$OUTDIR/$RESULT_FILE" "$OUTDIR/$SAVE_FILE"

    #remove temporary files
    rm "$OUTDIR/$RESULT_FILE"

} 2>&1 | tee -a grafpop.log
