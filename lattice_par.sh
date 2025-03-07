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
    output_file="coordinates${num}_diagonal_scaled"
    
    # Find the last occurrence of CELL_PARAMETERS
    line_number=$(grep -n "CELL_PARAMETERS" "$input_file" | tail -n 1 | cut -d: -f1)

    # Find the last occurrence of "alat=" and extract the number (after '=')
    alat_value=$(grep -n "alat=" "$input_file" | tail -n 1 | sed 's/.*alat=[[:space:]]*\([0-9]*\.[0-9]*\).*/\1/' | xargs)

    # Remove any trailing non-numeric characters (e.g., ')' or extra spaces)
    alat_value=$(echo "$alat_value" | sed 's/[^0-9.]//g')

    # Ensure alat_value is a valid number and format it to 8 decimal places
    if [[ ! "$alat_value" =~ ^[0-9]+\.[0-9]+$ ]]; then
      echo "Error: Invalid alat value '$alat_value' found in $input_file" >> "$output_file"
      continue
    fi

    # Format the alat value to 8 decimal places
    alat_value=$(printf "%.8f" "$alat_value")

    # If the "alat" value is found, extract the matrix and process it
    if [[ -n "$alat_value" ]]; then
      # Extract the 3x3 matrix (next 3 lines after CELL_PARAMETERS)
      matrix=$(sed -n "$((line_number + 1)),$((line_number + 3))p" "$input_file")
      
      # Extract the diagonal elements from the 3x3 matrix
      diagonal=$(echo "$matrix" | awk '{print $1, $2, $3}' | awk 'NR==1{print $1} NR==2{print $2} NR==3{print $3}')

      # Multiply each diagonal element by the "alat" value and 0.529177249
      alat_scaled=$(echo "$alat_value * 0.529177249" | bc -l)

      # Create a new array to hold the scaled diagonal values
      scaled_diagonal=""
      
      # Scale each diagonal value and store it in the array, ensuring 7 decimal places
      counter=0
      for value in $diagonal; do
        # Calculate scaled value and format to 7 decimal places
        scaled_value=$(echo "$value * $alat_scaled" | bc -l)
        
        # Format to 7 decimal places
        formatted_value=$(printf "%.7f" "$scaled_value")
        
        # Append formatted value with "a = ", "b = ", and "c = " based on the counter
        if [ $counter -eq 0 ]; then
          scaled_diagonal="a = $formatted_value"
        elif [ $counter -eq 1 ]; then
          scaled_diagonal="$scaled_diagonal\nb = $formatted_value"
        elif [ $counter -eq 2 ]; then
          scaled_diagonal="$scaled_diagonal\nc = $formatted_value"
        fi
        counter=$((counter + 1))
      done

      # Save the scaled diagonal to the output file in 3x1 matrix form (one value per line)
      echo -e "$scaled_diagonal" > "$output_file"
    else
      echo "'alat=' not found in $input_file." >> "$output_file"
    fi
  else
    echo "File $input_file does not exist, skipping." >> "$output_file"
  fi
done
