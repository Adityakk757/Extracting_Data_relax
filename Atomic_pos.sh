#!/bin/bash

# Check if the user provided any numbers
if [ $# -eq 0 ]; then
  echo "Please provide a list of numbers (e.g., 1 11 2 21) corresponding to relax#.out files."
  exit 1
fi

# Loop through each number provided as input
for num in "$@"
do
  # Define the input file based on the number
  input_file="relax${num}.out"
  
  # Check if the file exists
  if [ -f "$input_file" ]; then
    # Define the output file based on the input file
    output_file="relax${num}_positions"
    
    # Use awk to find the last occurrence of ATOMIC_POSITION and print 20 lines after it
    awk '/ATOMIC_POSITION/{f=NR} END{if(f) print f}' "$input_file" | \
    while read last_occurrence; do
      # Print 20 lines starting from the line after the last occurrence of ATOMIC_POSITION
      tail -n +$((last_occurrence + 1)) "$input_file" | head -n 20 > "$output_file"
    done
    
    # Check if the output file is empty
    if [ -s "$output_file" ]; then
      echo "Processed $input_file and saved output to $output_file"
    else
      echo "No ATOMIC_POSITION found in $input_file or not enough lines after it."
    fi
  else
    echo "File $input_file does not exist, skipping."
  fi
done
