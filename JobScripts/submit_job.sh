#!/bin/bash

# Default values
JOBNAME="default_job"
OUTPUT="/scratch/j/jle/frans/default_job_%j.out"
NTASKS=1
TIME="24:00:00"
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

# Debugging prints
echo "OUTPUT: $OUTPUT"

cat <<EOF > $JOB_SCRIPT
#!/bin/bash
#SBATCH --nodes=2
#SBATCH --job-name=$JOBNAME
#SBATCH --output=${OUTPUT}
#SBATCH --ntasks=$NTASKS
#SBATCH --time=$TIME
#SBATCH --cpus-per-task=$CPU
export R_LIBS_USER=~/R/library
export PATH=$HOME/bin:$PATH

source $SCRATCH/startup.sh
module load gcc/8.3.0
module load intel/2019u4
module load r/4.1.2

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

