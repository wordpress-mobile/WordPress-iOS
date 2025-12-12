#!/usr/bin/env python3
"""
Test output extraction from console logs
Extracts base64-encoded JSON from test output markers
"""

import base64
import json
import re
from pathlib import Path
from typing import List, Dict, Any


def extract_test_outputs(test_output_file: Path) -> List[Dict[str, Any]]:
    """
    Extract test outputs from console log file

    Args:
        test_output_file: Path to swift test output file

    Returns:
        List of parsed JSON test outputs
    """
    if not test_output_file.exists():
        raise FileNotFoundError(f"Test output file not found: {test_output_file}")

    outputs = []
    in_block = False
    current_content = []

    # Markers for all test types
    start_markers = [
        "__EXCERPT_OUTPUT_START__",
        "__TAG_OUTPUT_START__",
        "__SUMMARY_OUTPUT_START__",
    ]
    end_markers = [
        "__EXCERPT_OUTPUT_END__",
        "__TAG_OUTPUT_END__",
        "__SUMMARY_OUTPUT_END__",
    ]

    with open(test_output_file, 'r') as f:
        for line in f:
            line = line.rstrip('\n')

            # Check for start markers
            if any(marker in line for marker in start_markers):
                in_block = True
                current_content = []
                continue

            # Check for end markers
            if any(marker in line for marker in end_markers):
                if in_block and current_content:
                    # Join accumulated base64 content and decode
                    base64_content = ''.join(current_content)
                    try:
                        json_bytes = base64.b64decode(base64_content)
                        json_str = json_bytes.decode('utf-8')
                        test_output = json.loads(json_str)
                        outputs.append(test_output)
                    except Exception as e:
                        print(f"Warning: Failed to decode output: {e}")

                in_block = False
                current_content = []
                continue

            # Accumulate base64 content
            if in_block:
                current_content.append(line.strip())

    if not outputs:
        raise ValueError(
            "No test outputs extracted. "
            "This may mean:\n"
            "  - Tests failed before recording outputs\n"
            "  - Output markers weren't found in console\n"
            f"  - Check {test_output_file} for __*_OUTPUT_START__ markers"
        )

    print(f"Extracted {len(outputs)} test outputs")
    return outputs
