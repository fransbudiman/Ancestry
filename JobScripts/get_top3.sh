#!/bin/bash

# Default values
SEARCH_DIR="."
TRANSFER_DIR="./transfer"

# Parse command-line arguments
while getopts "s:t:" opt; do
  case $opt in
    s) SEARCH_DIR=$OPTARG ;;
    t) TRANSFER_DIR=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Check if SEARCH_DIR exists
if [ ! -d "$SEARCH_DIR" ]; then
  echo "Error: $SEARCH_DIR does not exist."
  exit
fi

# Check if TRANSFER_DIR exists
if [ ! -d "$TRANSFER_DIR" ]; then
  mkdir -p $TRANSFER_DIR
fi

cd $SEARCH_DIR

echo "Searching for .Q files in $SEARCH_DIR"

# Search for all directory that contains a .Q file
for dir in $(find . -type f -name "*.Q" -exec dirname {} \; | sort -u)
do
    echo "Processing directory: $dir"
    # get name of Q file
    Q_FILE=$(find $dir -type f -name "*.Q" | head -n 1)
    Q_BASENAME=$(basename "$Q_FILE")
    head -1 $Q_FILE > ${Q_BASENAME}_sample_only.txt
    mv ${Q_BASENAME}_sample_only.txt $TRANSFER_DIR
    # merge the pop and Q files together
    paste $dir/*.pop ${Q_FILE} > $dir/${Q_BASENAME}_merged.txt
    # move this merged file to the transfer directory
    mv $dir/${Q_BASENAME}_merged.txt $TRANSFER_DIR
done

cd $TRANSFER_DIR
echo "Processing merged files in $TRANSFER_DIR"

# process each merged file
for file in $(find . -type f -name "*_merged.txt")
do
    echo "Processing file: $file"
    head -2 $file
    # get the name of the file
    FILE_NAME=$(basename $file)
    # find unique populations
    POPULATIONS=$(awk '{gsub(/\r/, ""); if ($1 != "-") print $1}' $file | sort -u)
    echo "$POPULATIONS" | tr " " "\n" > temp_pop.txt
    POP_NO=$(echo $POPULATIONS | wc -w)
    # create empty array of length POP_NO
    declare -a POP_ORDER
    # loops through each population
    for pop in $(cat temp_pop.txt)
    do
    
    clean_pop=$(echo "$pop" | tr -d '\r\n\t ')

    # Now use awk with tab as the field separator and handle carriage returns
    awk -v pop="$clean_pop" -F'\t' '{
        # Remove carriage returns from the first field
        gsub(/\r/, "", $1);
        
        # Now compare the cleaned first field with the population
        if ($1 == pop) {
            for (i=2; i<=NF; i++) 
                printf "%s%s", $i, (i == NF ? "\n" : " ")
        }
    }' "$file" > "${clean_pop}_temp.txt"

    awk '{for (i=1; i<=NF; i++) pop_array[i] += $i} END {for (i=1; i in pop_array; i++) printf "%s%s", pop_array[i], (i<NF ? " " : "\n")}' ${pop}_temp.txt > ${pop}_sum_temp.txt

    echo "Sum of each column for population $pop"
    cat ${pop}_sum_temp.txt
    
    # find the column with the highest sum
    MAX_COL=$(awk '{max=0; col=0;
        for (i=1; i<=NF; i++){
            if ($i > max) {max = $i; col = i;} 
        }} END {print col}' ${pop}_sum_temp.txt)
    # add the population to the array
    POP_ORDER[$MAX_COL]=$pop
    echo "Population $pop has the highest sum in column $MAX_COL"
    done
    
done

# print the order of populations
echo "The order of populations is:"
echo "${POP_ORDER[@]}"
POP_HEADER=$(echo "${POP_ORDER[@]}" | tr " " "\t")

for file in $(find . -type f -name "*_sample_only.txt")
do
    echo "$POP_HEADER" | cat - $file > temp && mv temp $file
done

# Get the top 3 populations
for file in $(find . -type f -name "*_sample_only.txt")
do
    echo "finding top 3 populations for $file"
    awk '
    NR==1 {for (i=1; i<=NF; i++) header[i]=$i}
    NR==2 {for (i=1; i<=NF; i++) data[i]=$i}
    END {
        n = asorti(data, index_sorted, "@val_num_desc")
        for (i=1; i<=3; i++) {
            printf "%s%s", header[index_sorted[i]], (i<3 ? " " : "\n")
        }
        for (i=1; i<=3; i++) {
            printf "%s%s", data[index_sorted[i]], (i<3 ? " " : "\n")
        }
    }' $file > "$(basename "$file" | sed 's/_sample_only.txt/_top3.txt/')"
done


# remove temporary files
rm temp_pop.txt
rm *_temp.txt
rm *_merged.txt
