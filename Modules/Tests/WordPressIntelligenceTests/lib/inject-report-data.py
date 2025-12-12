#!/usr/bin/env python3
"""
Inject evaluation results JSON into the HTML viewer template.
"""

import json
import sys
import argparse

def inject_data(template_path, json_path, output_path, baseline_path=None):
    # Read the HTML template
    with open(template_path, 'r') as f:
        html_content = f.read()

    # Read the JSON data
    with open(json_path, 'r') as f:
        json_data = json.load(f)

    # Convert JSON to a compact string
    json_string = json.dumps(json_data, separators=(',', ':'))

    # Replace the EMBEDDED_DATA placeholder
    placeholder = 'const EMBEDDED_DATA = null;'
    replacement = f'const EMBEDDED_DATA = {json_string};'

    if placeholder not in html_content:
        print("ERROR: Could not find EMBEDDED_DATA placeholder in HTML template", file=sys.stderr)
        return False

    html_with_data = html_content.replace(placeholder, replacement)

    # If baseline is provided, inject it as well
    if baseline_path:
        with open(baseline_path, 'r') as f:
            baseline_data = json.load(f)

        baseline_string = json.dumps(baseline_data, separators=(',', ':'))

        # Add EMBEDDED_BASELINE placeholder in the template, just before EMBEDDED_DATA
        baseline_placeholder = '// Note: EMBEDDED_BASELINE may also be injected if comparison is requested'
        if baseline_placeholder in html_with_data:
            # Insert the baseline constant before the note comment
            baseline_line = f'const EMBEDDED_BASELINE = {baseline_string};\n        '
            html_with_data = html_with_data.replace(baseline_placeholder, baseline_line + baseline_placeholder)
            print(f"✓ Injected {len(json_string)} bytes of main data + {len(baseline_string)} bytes of baseline data")
        else:
            print("Warning: Could not find baseline placeholder, baseline not injected", file=sys.stderr)
            print(f"✓ Injected {len(json_string)} bytes of main data (baseline injection failed)")
    else:
        print(f"✓ Injected {len(json_string)} bytes of JSON data into HTML report")

    # Write the output
    with open(output_path, 'w') as f:
        f.write(html_with_data)

    return True

def main():
    parser = argparse.ArgumentParser(description='Inject evaluation data into HTML report')
    parser.add_argument('template', help='HTML template file')
    parser.add_argument('data', help='Main evaluation JSON file')
    parser.add_argument('output', help='Output HTML file')
    parser.add_argument('--baseline', help='Optional baseline JSON file for comparison', default=None)

    args = parser.parse_args()

    success = inject_data(args.template, args.data, args.output, args.baseline)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
