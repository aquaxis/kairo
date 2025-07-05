#!/bin/bash

# Script to combine GPIO sample hex files with padding
# - Reads sample_gpio0 hex files, pads to 8192 lines, then appends sample_gpio1
# - Creates imem_data.hex and dmem_data.hex

# Set directories
GPIO0_DIR="sample_gpio0"
GPIO1_DIR="sample_gpio1"
OUTPUT_DIR="."

# Function to process and combine hex files
combine_hex_files() {
    local input1="$1"
    local input2="$2"
    local output="$3"
    local pad_lines=8192
    
    echo "Processing: $input1 + $input2 -> $output"
    
    # Check if input files exist
    if [ ! -f "$input1" ]; then
        echo "Error: $input1 not found"
        return 1
    fi
    if [ ! -f "$input2" ]; then
        echo "Error: $input2 not found"
        return 1
    fi
    
    # Count lines in first file
    lines1=$(wc -l < "$input1")
    echo "  $input1 has $lines1 lines"
    
    # Copy first file
    cp "$input1" "$output"
    
    # Calculate padding needed
    if [ $lines1 -lt $pad_lines ]; then
        padding=$((pad_lines - lines1))
        echo "  Adding $padding lines of padding (00000000)"
        
        # Add padding
        for ((i=0; i<padding; i++)); do
            echo "00000000" >> "$output"
        done
    else
        echo "  Warning: $input1 has $lines1 lines, which is >= $pad_lines"
    fi
    
    # Append second file
    lines2=$(wc -l < "$input2")
    echo "  Appending $input2 ($lines2 lines)"
    cat "$input2" >> "$output"
    
    # Show final size
    total_lines=$(wc -l < "$output")
    echo "  Created $output with $total_lines lines"
    echo ""
}

# Main execution
echo "=== Combining hex files for dual GPIO sample ==="
echo ""

# Process instruction memory files
combine_hex_files \
    "${GPIO0_DIR}/sample_gpio_i.hex" \
    "${GPIO1_DIR}/sample_gpio_i.hex" \
    "${OUTPUT_DIR}/imem_data.hex"

# Process data memory files  
combine_hex_files \
    "${GPIO0_DIR}/sample_gpio_d.hex" \
    "${GPIO1_DIR}/sample_gpio_d.hex" \
    "${OUTPUT_DIR}/dmem_data.hex"

echo "=== Complete ==="
echo "Generated files:"
echo "  - imem_data.hex (instruction memory)"
echo "  - dmem_data.hex (data memory)"
echo ""
echo "These files can be used with the testbench:"
echo "  vsim tb_kairo_soc +imem=imem_data.hex +dmem=dmem_data.hex"