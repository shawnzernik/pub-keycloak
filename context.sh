#!/bin/bash

if [ -d net8saml/bin ]; then
    rm -R net8saml/bin
fi
if [ -d net8saml/obj ]; then
    rm -R net8saml/obj
fi
if [ -d reactsaml/dist ]; then
    rm -R reactsaml/dist
fi
if [ -d reactsaml/node_modules ]; then
    rm -R reactsaml/node_modules
fi
if [ -e reactsaml/package-lock.json ]; then
    rm reactsaml/package-lock.json
fi
if [ -e *.pem ]; then
    rm *.pem
fi

if [ -d context ]; then
    rm -R context
fi
mkdir -p context

# Find all UTF-8 and ASCII files while ignoring .git, context folder, and SVG files
find . -type f ! -path "*/.git/*" ! -path "*/context/*" ! -name "*.svg" | while read -r file; do
    # Get the folder name of the current file
    folder_name=$(dirname "$file" | sed 's|\./||' | sed 's|[\\/:\*?"<>| ]|_|g')
    
    # Define the output file for this folder
    output_file="context/$folder_name.txt"
    
    # Initialize the output file if it doesn't exist
    if [ ! -f "$output_file" ]; then
        echo "### Combined Context from Files in $folder_name ###" > "$output_file"
        echo "" >> "$output_file"
        echo "The following files are being provided to build context.  Please provide a list of files names confirming you got them.  For each file, if it interacts with files I've previously provided, please list them as sub-bullets point." >> "$output_file"
        echo "" >> "$output_file"
    fi

    # Check file encoding
    if file --mime "$file" | grep -qE 'charset=(us-ascii|utf-8)'; then
        # Print status update
        echo "Processing: $file"

        # Append file path header to output file
        echo "## File: \`$file\`" >> "$output_file"
        echo "" >> "$output_file"
        echo '```' >> "$output_file"
        
        # Append file content safely
        cat "$file" >> "$output_file"
        
        echo "" >> "$output_file"
        echo '```' >> "$output_file"
        echo "" >> "$output_file"
    fi
done

# Print completion message
echo "All files (excluding SVGs and files in 'context' folder) have been combined into respective folder-based files in 'context'"
