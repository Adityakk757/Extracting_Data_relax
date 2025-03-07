#!/bin/bash

#Check if the user provided any numbers
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
    
    # Run the awk command and save the result to the output file
    awk '/ATOMIC_POSITION/{f=1} f && --n>=0' n=20 "$input_file" > "$output_file"
    echo "Processed $input_file and saved output to $output_file"
    
    # Now remove the first line and first column from the output file
    awk 'NR > 1 { $1=""; print $0 }' "$output_file" > "${output_file}_updated"
    echo "Removed first line and column, saved as ${output_file}_updated"
    
  else
    echo "File $input_file does not exist, skipping."
  fi
done

