#!/bin/bash

# Default values
JOBNAME="default_job"
OUTPUT="job_log/default_job_%j.out"
NTASKS=1
TIME="48:00:00"
CPU=40

# Parse command-line arguments
while getopts "j:o:n:t:c:a:r:" opt; do
  case $opt in
    j) JOBNAME=$OPTARG ;;
    o) OUTPUT=$OPTARG ;;
    n) NTASKS=$OPTARG ;;
    t) TIME=$OPTARG ;;
    c) CPU=$OPTARG ;;
    a) ARG=$OPTARG ;;
    r) REF=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND -1))  # Remove parsed options from arguments
echo "Remaining arguments: $@"

# Ensure REF is set before using it
if [ -z "$REF" ]; then
  echo "Error: Reference dataset (-r) is required."
  exit 1
fi

# Create a temporary SBATCH script
JOB_SCRIPT=$(mktemp)  # Create a temporary file

export PATH="$HOME/bin:$PATH"

# Ensure all libraries and executables are complete before running ancestry estimation
# Check is admixture is installed in the bin directory
if [[ "$REF" == "1kgenomes" || "$REF" == "hapmap" ]] && ! command -v admixture > /dev/null 2>&1; then
  echo "admixture not found, downloading..."
  mkdir -p $HOME/bin

  # Download admixture (Replace URL with actual download link)
  curl -L -o $HOME/bin/admixture https://dalexander.github.io/admixture/binaries/admixture_linux-1.3.0.tar.gz
  tar -xvzf $HOME/bin/admixture.tar.gz -C $HOME/bin/

  # Make it executable
  chmod +x $HOME/bin/admixture

else
  echo "admixture is already installed."
fi

if [[ "$REF" == "1kgenomes" || "$REF" == "hapmap" ]]; then
  # Load the R module
  module load StdEnv/2023
  module load r/4.4.0

  R_LIB=~/R/library
  mkdir -p "$R_LIB"
  export R_LIBS_USER="$R_LIB"
  export LIBRARY_PATH="$R_LIB"
fi


# Check if grafpop is installed
if [ "$REF" = "grafpop" ] && ! which grafpop > /dev/null 2>&1; then
  echo "grafpop not found, downloading..."
  mkdir -p $HOME/bin

  # Download grafpop
  curl -L -o $HOME/bin/grafpop.tar.gz https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/GetZip.cgi?zip_name=GrafPop1.0.tar.gz
  tar -xvzf $HOME/bin/grafpop.tar.gz -C $HOME/bin/

  # Make it executable
  chmod +x $HOME/bin/grafpop
  chmod +x $HOME/bin/PlotGrafPopResults.pl
  chmod +x $HOME/bin/SaveSamples.pl

else
  echo "grafpop is already installed."
fi

# ensure that shebang lines are correct
if [ "$REF" = "grafpop" ]; then
  PERL_PATH=$(which perl)
    if [ -z "$PERL_PATH" ]; then
        echo "perl not found. Please install perl."
        exit 1
    else
        # Update the shebang line in the perl scripts
        sed -i "1s|^#!.*|#!$PERL_PATH|" "$HOME/bin/SaveSamples.pl"
        sed -i "1s|^#!.*|#!$PERL_PATH|" "$HOME/bin/PlotGrafPopResults.pl"
    fi
fi

# Debugging prints
echo "OUTPUT: $OUTPUT"

cat <<EOF > $JOB_SCRIPT
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --job-name=$JOBNAME
#SBATCH --output=${OUTPUT}
#SBATCH --ntasks=$NTASKS
#SBATCH --time=$TIME
#SBATCH --cpus-per-task=$CPU

export R_LIBS_USER=~/R/library
export PATH=$HOME/bin:$PATH
export PATH=$HOME/plink2:$PATH

# # Environment setup for Narval cluster. Uncomment if needed and comment out the code below.
# module load StdEnv/2020
# module load plink/1.9b_6.21-x86_64
# module load r/4.4.0
# module load gcc/13.3
# module load intel/2024.2.0

# Environment setup for Niagara cluster. Uncomment if needed and comment out the code above.
export R_LIBS_USER=~/R/library
export PATH=$HOME/bin:$PATH
module load NiaEnv
module load plink/1.90b6
module load plink2/2.00a3
module load gcc/8.3.0
module load intel/2019u4
module load r/4.1.2

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Run the actual script with arguments

# Pick which script to run based on the argument
if [[ $REF == "hapmap" ]]; then
  bash ancestry_estimation_hapmap3.sh $ARG
  if [ $? -ne 0 ]; then
    echo "Error: ancestry_estimation_hapmap3.sh failed."
    exit 1
  fi
elif [[ $REF == "grafpop" ]]; then
  bash ancestry_estimation_grafpop.sh $ARG
  if [ $? -ne 0 ]; then
    echo "Error: ancestry_estimation_grafpop.sh failed."
    exit 1
  fi
elif [[ $REF == "1kgenomes" ]]; then
    bash ancestry_estimation_1kgenomes.sh $ARG
    if [ $? -ne 0 ]; then
      echo "Error: 1000Genomes_Reference.sh failed."
      exit 1
    fi
else
    echo "Invalid argument: $ARG"
    exit 1
fi
EOF

# Submit the job
sbatch $JOB_SCRIPT

# Optional: Print the generated job script (for debugging)
cat $JOB_SCRIPT

# Removes script when the script exits
trap "rm -f $JOB_SCRIPT" EXIT
