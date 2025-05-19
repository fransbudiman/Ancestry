#!/bin/bash

# This script is used to setup all the required files and load all required modules.
# Note that these will differ from HPC cluster to cluster (ie. Niagara vs Narval).
# Most compute nodes does not have outbound internet access.
# So files downloading should be done on the login node.
# If you are using a different cluster, you will need to modify this script.

# NOTE: Since I have trouble with Rscript in different clusters, I will remove it for now since it is not used in the final result anyways.

# Checklist of required files and modules:
# files:
# - highld.txt
# - REF.csv
# - REF_ID2Pop.txt

# we will use echo to print the loading steps and submit_job.sh will use eval to run the printed commands.

HOSTNAME=$(hostname)
if [[ $HOSTNAME == nia*]]; then
    # Setup for Niagara cluster
    echo "DEBUG: Setting up environment for Niagara cluster"
elif [[ $HOSTNAME == narval*]]; then
    # Setup for Narval cluster
    echo "DEBUG: Setting up environment for Narval cluster"
else
    echo "Unknown cluster. Please set up the environment manually."
    exit 1
fi