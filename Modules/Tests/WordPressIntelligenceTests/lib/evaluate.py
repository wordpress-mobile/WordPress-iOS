#!/usr/bin/env python3
"""
Main evaluation orchestrator
Extracts test outputs, evaluates with Claude, generates reports
"""

import argparse
import json
import sys
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime, UTC

from config import TestType, detect_test_type, get_config
from extractors import extract_test_outputs
from claude_client import ClaudeClient
from evaluators import create_evaluator, TestResult


class Colors:
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'


def print_section(message: str):
    """Print section header"""
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.BLUE}{message}{Colors.NC}")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print("")


def print_step(num: int, message: str):
    """Print step message"""
    print(f"{Colors.CYAN}Step {num}: {message}{Colors.NC}")
    print("")


def convert_result_to_dict(result: TestResult, test_type: TestType) -> Dict[str, Any]:
    """Convert TestResult to JSON-serializable dict"""
    result_dict = {
        "id": result.id,
        "testName": result.test_name,
        "testType": result.test_type,
        "status": result.status,
        "input": result.input_data,
        "averageScore": result.average_score,
        "lowestScore": result.lowest_score,
        "duration": result.duration,
    }

    # Add items based on test type
    if test_type == TestType.EXCERPT:
        result_dict["excerpts"] = [
            {
                "number": item.number,
                "text": item.text,
                "wordCount": item.word_count,
                "status": item.status,
                "failureReason": item.failure_reason,
                "scores": item.scores,
                "overall": item.overall,
            }
            for item in result.items
        ]
        if result.diversity:
            result_dict["diversity"] = result.diversity
    elif test_type == TestType.TAG:
        result_dict["tags"] = [
            {
                "number": item.number,
                "text": item.text,
                "wordCount": item.word_count,
                "status": item.status,
                "failureReason": item.failure_reason,
                "scores": item.scores,
                "overall": item.overall,
            }
            for item in result.items
        ]
    elif test_type == TestType.SUMMARY:
        if result.items:
            item = result.items[0]
            result_dict["summary"] = {
                "text": item.text,
                "wordCount": item.word_count,
                "scores": item.scores,
                "overall": item.overall,
            }

    return result_dict


def calculate_category_averages(results: List[Dict[str, Any]], test_type: TestType) -> Dict[str, float]:
    """Calculate average scores by category"""
    config = get_config(test_type)
    category_sums = {criterion.name: [] for criterion in config.criteria}

    # Extract scores based on test type
    for result in results:
        if test_type == TestType.EXCERPT:
            for excerpt in result.get("excerpts", []):
                scores = excerpt.get("scores", {})
                for criterion in config.criteria:
                    if criterion.name in scores:
                        category_sums[criterion.name].append(scores[criterion.name])
        elif test_type == TestType.TAG:
            for tag in result.get("tags", []):
                scores = tag.get("scores", {})
                for criterion in config.criteria:
                    if criterion.name in scores:
                        category_sums[criterion.name].append(scores[criterion.name])
        elif test_type == TestType.SUMMARY:
            summary = result.get("summary", {})
            scores = summary.get("scores", {})
            for criterion in config.criteria:
                if criterion.name in scores:
                    category_sums[criterion.name].append(scores[criterion.name])

    # Calculate averages
    averages = {}
    for criterion in config.criteria:
        values = category_sums[criterion.name]
        averages[criterion.name] = sum(values) / len(values) if values else 0.0

    # Add diversity for excerpts
    if test_type == TestType.EXCERPT:
        diversity_scores = [
            result.get("diversity", {}).get("score", 0)
            for result in results
            if result.get("diversity") and result["diversity"].get("score", 0) > 0
        ]
        averages["diversity"] = sum(diversity_scores) / len(diversity_scores) if diversity_scores else 0.0

    return averages


def generate_json_report(results: List[TestResult], output_file: Path, test_type: TestType, model: str = "sonnet", output_dir: Path = None):
    """Generate JSON evaluation report"""
    config = get_config(test_type)

    # Convert results to dicts
    result_dicts = [convert_result_to_dict(r, test_type) for r in results]

    # Calculate statistics
    total = len(result_dicts)
    passed = sum(1 for r in result_dicts if r["status"] == "passed")
    failed = sum(1 for r in result_dicts if r["status"] == "failed")
    needs_improvement = sum(1 for r in result_dicts if r["status"] == "needsImprovement")
    pass_rate = passed / total if total > 0 else 0.0

    # Calculate average overall score
    avg_overall = sum(r["averageScore"] for r in result_dicts) / total if total > 0 else 0.0

    # Calculate category averages
    category_averages = calculate_category_averages(result_dicts, test_type)

    # Build thresholds
    thresholds = {
        "pass": {
            "overall": config.pass_threshold,
        },
        "needsImprovement": {
            "overall": config.needs_improvement_threshold,
        },
    }

    # Add critical thresholds
    for criterion in config.criteria:
        if criterion.critical_threshold > 0:
            thresholds["pass"][criterion.name] = criterion.critical_threshold

    # Generate report
    report = {
        "metadata": {
            "suite": config.test_class.replace("Tests", "").lower(),
            "testType": test_type.value,
            "version": "2.0",
            "timestamp": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "duration": sum(r["duration"] for r in result_dicts),
            "claude_model": model,
            "test_platform": "iOS Simulator",
            "outputDirectory": str(output_dir.resolve()) if output_dir else None,
        },
        "summary": {
            "total": total,
            "passed": passed,
            "failed": failed,
            "needsImprovement": needs_improvement,
            "averageScore": avg_overall,
            "averageByCategory": category_averages,
            "passRate": pass_rate,
        },
        "thresholds": thresholds,
        "results": result_dicts,
    }

    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"  ✓ JSON report: {output_file}")


def main():
    parser = argparse.ArgumentParser(description="Evaluate test outputs with Claude")
    parser.add_argument("--test-output", required=True, help="Path to swift test output file")
    parser.add_argument("--output-dir", required=True, help="Output directory for results")
    parser.add_argument("--test-type", default="excerpts", help="Test type (excerpts, tags, summary)")
    parser.add_argument("--model", default="sonnet", help="Claude model to use (sonnet, opus, haiku)")

    args = parser.parse_args()

    test_output_file = Path(args.test_output)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Step 1: Extract test outputs
    print_step(2, "Extracting test outputs from console...")
    try:
        test_outputs = extract_test_outputs(test_output_file)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

    print("")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print("")

    # Step 2: Evaluate with Claude
    print_step(3, f"Evaluating with Claude CLI (model: {args.model})...")

    claude = ClaudeClient(model=args.model)
    all_results: List[TestResult] = []

    for idx, test_data in enumerate(test_outputs, 1):
        # Auto-detect test type
        test_type_str = test_data.get('testType', 'excerpt-generation')
        test_type = detect_test_type(test_type_str)

        # Create evaluator and evaluate
        evaluator = create_evaluator(test_type, claude)
        result = evaluator.evaluate_test(test_data, idx)
        all_results.append(result)

    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print("")

    # Step 3: Generate JSON report
    print_step(4, "Generating evaluation reports...")

    # Detect test type from first result (all should be same type)
    if all_results:
        test_type_str = all_results[0].test_type
        test_type = detect_test_type(test_type_str)

        json_output = output_dir / "evaluation-results.json"
        generate_json_report(all_results, json_output, test_type, args.model, output_dir)

    print("")

    # Return exit code based on failures
    failed_count = sum(1 for r in all_results if r.status == "failed")
    sys.exit(failed_count)


if __name__ == "__main__":
    main()
