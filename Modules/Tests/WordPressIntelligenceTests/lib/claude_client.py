#!/usr/bin/env python3
"""
Claude CLI wrapper for evaluation
"""

import json
import re
import subprocess
from typing import Dict, Any, Optional


class ClaudeClient:
    """Wrapper for Claude CLI subprocess calls"""

    def __init__(self, model: str = "sonnet"):
        self.model = model

    def evaluate(self, prompt: str) -> Optional[Dict[str, Any]]:
        """
        Call Claude CLI with evaluation prompt

        Args:
            prompt: Evaluation prompt

        Returns:
            Parsed JSON response or None if failed
        """
        try:
            result = subprocess.run(
                ["claude", "--print", "--model", self.model],
                input=prompt,
                capture_output=True,
                text=True,
                timeout=60,
            )

            if result.returncode != 0:
                print(f"    ✗ Claude CLI error: {result.stderr}")
                return None

            # Strip markdown code blocks
            response = result.stdout.strip()
            json_match = re.search(r'```json\s*(.*?)\s*```', response, re.DOTALL)
            if json_match:
                response = json_match.group(1)

            # Parse JSON
            try:
                return json.loads(response)
            except json.JSONDecodeError as e:
                print(f"    ✗ Invalid JSON response: {e}")
                # Print first 200 chars for debugging
                print(f"    Response preview: {response[:200]}")
                return None

        except subprocess.TimeoutExpired:
            print("    ✗ Claude CLI timeout")
            return None
        except FileNotFoundError:
            print("    ✗ Claude CLI not found (install: pip install claude-cli)")
            return None
        except Exception as e:
            print(f"    ✗ Unexpected error: {e}")
            return None
