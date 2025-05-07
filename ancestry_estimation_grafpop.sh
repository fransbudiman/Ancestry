#!/bin/bash

# Enable debugging
set -x

# Set arguments
while getopts ":v:d:" flag
do
    case "${flag}" in
        v) VCF_PATH=${OPTARG};;
        d) OUTDIR=${OPTARG};;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :)  echo "Missing argument for -$OPTARG" >&2; exit 1 ;;
    esac
done

{
    # Check if arguments are empty
    if [ -z "$VCF_PATH" ] || [ -z "$OUTDIR" ]; then
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

    # Add grafpop, PlotGrafPopResults.pl, and SaveSamples.pl to PATH
    export PATH="$HOME/bin:$PATH"
    export PATH="$HOME/perl5/bin:$PATH"
    export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB"

    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8

    PERL_PATH=$(which perl)
    if [ -z "$PERL_PATH" ]; then
        echo "perl not found. Please install perl."
        exit 1
    else
        # Update the shebang line in the perl scripts
        sed -i "1s|^#!.*|#!$PERL_PATH|" "$HOME/bin/SaveSamples.pl"
        sed -i "1s|^#!.*|#!$PERL_PATH|" "$HOME/bin/PlotGrafPopResults.pl"
    fi

    # install GD::Text and GD::Graph if not already installed
    if ! command -v cpanm &> /dev/null; then
        echo "cpanm not found. Installing App::cpanminus locally . . ."
        curl -L https://cpanmin.us | perl - --self-upgrade --local-lib=$HOME/perl5 App::cpanminus
    fi

    # gcc is required for installing GD modules
    module load gcc/13.2.0

    if ! perl -MGD -e 1 2>/dev/null; then
    echo "GD module not found. Installing it . . ."
    cpanm --local-lib="$HOME/perl5" GD
    fi
    if ! perl -MGD::Text -e '1' 2>/dev/null; then
        echo "GD::Text not found. Installing it . . ."
        cpanm --local-lib="$HOME/perl5" "GD::Text"
    fi
    if ! perl -MGD::Graph -e '1' 2>/dev/null; then
        echo "GD::Graph not found. Installing it . . ."
        # somehow this is needed because otherwise MakeMaker does not work
        cpanm --local-lib=~/perl5 --force ExtUtils::MakeMaker
        cpanm --local-lib="$HOME/perl5" "GD::Graph"
    fi

    chmod +x "$HOME/bin/SaveSamples.pl"

    VCF_FILE="${VCF_PATH##*/}"
    SAMPLE_NAME="${VCF_FILE%%.*}"
    PNG_FILE="${SAMPLE_NAME}_ancestry.png"
    RESULT_FILE="${SAMPLE_NAME}_temp.txt"
    SAVE_FILE="${SAMPLE_NAME}_ancestry.txt"
    
    grafpop "$VCF_PATH" "$OUTDIR/$RESULT_FILE"
    # PlotGrafPopResults.pl "$OUTDIR/$RESULT_FILE" "$OUTDIR/$PNG_FILE"
    SaveSamples.pl "$OUTDIR/$RESULT_FILE" "$OUTDIR/$SAVE_FILE"

    #remove temporary files
    rm "$OUTDIR/$RESULT_FILE"

} 2>&1 | tee -a grafpop.log
