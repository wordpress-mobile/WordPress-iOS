#!/usr/bin/env python3
"""
Evaluation Pipeline for WordPressIntelligence Tests
Runs xcodebuild tests, extracts outputs, evaluates with Claude, generates reports

Usage:
  ./evaluate.py                                      # Run all excerpt tests (default)
  ./evaluate.py --test-type tags                     # Run all tag tests
  ./evaluate.py --skip-tests                         # Only evaluate existing JSON
  ./evaluate.py --simulator "iPhone 15"              # Use specific simulator
  ./evaluate.py --only-testing "PostExcerptGeneratorTests/spanishHTMLContent()"

  # Legacy mode (for backward compatibility):
  ./evaluate.py --test-output file.txt --output-dir /path
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, UTC
from pathlib import Path
from typing import List, Dict, Any, Optional

from config import TestType, detect_test_type, get_config
from extractors import extract_test_outputs
from claude_client import ClaudeClient
from evaluators import create_evaluator, TestResult


class Colors:
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'


class TestConfig:
    """Test type configuration"""
    def __init__(self, test_class: str, icon: str, name: str):
        self.test_class = test_class
        self.icon = icon
        self.name = name


# Test type configurations
TEST_CONFIGS = {
    'excerpts': TestConfig('PostExcerptGeneratorTests', '🖥️', 'Excerpt Generation'),
    'tags': TestConfig('TagSuggestionGeneratorTests', '🏷️', 'Tag Suggestion'),
    'summary': TestConfig('PostSummaryGeneratorTests', '📝', 'Post Summary'),
}


def print_header(config: TestConfig):
    """Print pipeline header"""
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.BLUE}{config.icon}  {config.name} Evaluation Pipeline{Colors.NC}")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print("")


def print_step(num: int, message: str):
    """Print step message"""
    print(f"{Colors.CYAN}Step {num}: {message}{Colors.NC}")
    print("")


def check_dependencies():
    """Check required dependencies are installed"""
    if not shutil.which('claude'):
        print(f"{Colors.YELLOW}Error: claude CLI not found{Colors.NC}")
        print("Install with: pip install claude-cli && claude configure")
        sys.exit(1)


def run_swift_tests(
    modules_dir: Path,
    xcresult_path: Path,
    output_dir: Path,
    simulator_name: str,
    test_target: str,
    config: TestConfig,
) -> Path:
    """Run Swift tests and return path to test output file"""
    print_step(1, f"Running Swift {config.name} tests...")
    print("")

    # Create output directories
    output_dir.mkdir(parents=True, exist_ok=True)

    # Remove existing xcresult bundle if it exists
    if xcresult_path.exists():
        shutil.rmtree(xcresult_path)

    print("Running tests...")

    # Prepare xcodebuild command
    cmd = [
        'xcodebuild', 'test',
        '-scheme', 'Modules-Package',
        '-destination', f'platform=iOS Simulator,name={simulator_name},OS=26.0',
        '-only-testing', test_target,
        '-resultBundlePath', str(xcresult_path),
    ]

    # Run tests with output capture
    test_output_file = output_dir / 'swift-test-output.txt'
    with open(test_output_file, 'w') as f:
        env = {'NSUnbufferedIO': 'YES', **os.environ.copy()}
        result = subprocess.run(
            cmd,
            cwd=modules_dir,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )

        # Write and display output
        f.write(result.stdout)
        print(result.stdout)

    print("")
    if result.returncode == 0:
        print(f"{Colors.GREEN}✓ Tests passed{Colors.NC}")
    else:
        print(f"{Colors.YELLOW}⚠ Some tests failed - continuing with evaluation{Colors.NC}")

    print("")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print("")

    return test_output_file


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


def generate_html_report(script_dir: Path, eval_run_dir: Path, base_output_dir: Path):
    """Generate HTML report with embedded data"""
    viewer_html = script_dir / 'evaluation-viewer.html'
    results_json = eval_run_dir / 'evaluation-results.json'
    report_html = eval_run_dir / 'evaluation-report.html'

    if not viewer_html.exists() or not results_json.exists():
        return

    cmd = [
        sys.executable,
        str(script_dir / 'inject-report-data.py'),
        str(viewer_html),
        str(results_json),
        str(report_html),
    ]

    result = subprocess.run(cmd, cwd=script_dir, capture_output=True)

    if result.returncode == 0:
        print(f"  ✓ HTML report: {report_html}")
        print("")
        print("  To compare with baselines:")
        print("    1. Open evaluation-report.html in your browser")
        print("    2. Check browser console for baseline folder location")
        print("    3. Click 'Compare with baseline' or drag and drop a baseline JSON file")
        print(f"    4. Baseline directories: {base_output_dir}/evaluation-*/")
    else:
        print("  ✗ HTML report generation failed")


def show_console_summary(script_dir: Path, eval_run_dir: Path, xcresult_path: Path):
    """Display console summary of results"""
    console_reporter = script_dir / 'console_reporter.py'
    results_json = eval_run_dir / 'evaluation-results.json'

    if not console_reporter.exists() or not results_json.exists():
        return

    cmd = [
        sys.executable,
        str(console_reporter),
        str(results_json),
        str(xcresult_path),
    ]

    subprocess.run(cmd, cwd=script_dir)


def main():
    parser = argparse.ArgumentParser(
        description='Evaluation pipeline for WordPressIntelligence tests'
    )

    # New-style arguments (full pipeline)
    parser.add_argument(
        '--test-type',
        default='excerpts',
        choices=['excerpts', 'tags', 'summary'],
        help='Test type to run (default: excerpts)'
    )
    parser.add_argument(
        '--model',
        default='sonnet',
        choices=['sonnet', 'opus', 'haiku'],
        help='Claude model to use (default: sonnet)'
    )
    parser.add_argument(
        '--skip-tests',
        action='store_true',
        help='Skip test execution and use existing output'
    )
    parser.add_argument(
        '--simulator',
        default='iPhone 16 Pro',
        help='Simulator name (default: iPhone 16 Pro)'
    )
    parser.add_argument(
        '--only-testing',
        default='',
        help='Run only specific test (e.g., "PostExcerptGeneratorTests/spanishHTMLContent()")'
    )

    # Legacy arguments (for backward compatibility)
    parser.add_argument(
        '--test-output',
        help='Path to swift test output file (legacy mode)'
    )
    parser.add_argument(
        '--output-dir',
        help='Output directory for results (legacy mode)'
    )

    args = parser.parse_args()

    # Check dependencies
    check_dependencies()

    # Determine if running in legacy mode
    legacy_mode = args.test_output is not None and args.output_dir is not None

    if legacy_mode:
        # Legacy mode: just extract and evaluate
        test_output_file = Path(args.test_output)
        output_dir = Path(args.output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        step_offset = 0
    else:
        # New mode: full pipeline
        script_dir = Path(__file__).parent.resolve()
        project_root = script_dir.parent.parent.parent.parent
        modules_dir = project_root / 'Modules'
        tmp_dir = Path(os.environ.get('TMPDIR', '/tmp'))
        base_output_dir = tmp_dir / 'WordPressIntelligence-Tests'

        # Create timestamped evaluation directory
        timestamp = datetime.now().strftime('%Y-%m-%d-%H%M%S')
        output_dir = base_output_dir / f'evaluation-{timestamp}'

        # Get test configuration
        config = TEST_CONFIGS.get(args.test_type, TEST_CONFIGS['excerpts'])

        # Print header
        print_header(config)
        print(f"Test results:       {base_output_dir}/test-results.xcresult")
        print(f"Evaluation results: {output_dir}")
        print("")

        # Setup paths
        xcresult_path = base_output_dir / 'test-results.xcresult'

        # Step 1: Run Swift tests (unless skipped)
        if not args.skip_tests:
            # Determine test target
            if args.only_testing:
                test_target = f'WordPressIntelligenceTests/{args.only_testing}'
                print(f"  Only testing: {test_target}")
            else:
                test_target = f'WordPressIntelligenceTests/{config.test_class}'

            test_output_file = run_swift_tests(
                modules_dir=modules_dir,
                xcresult_path=xcresult_path,
                output_dir=base_output_dir,
                simulator_name=args.simulator,
                test_target=test_target,
                config=config,
            )
            step_offset = 1
        else:
            print(f"{Colors.YELLOW}Skipping test execution (using existing output){Colors.NC}")
            print("")
            output_dir.mkdir(parents=True, exist_ok=True)
            test_output_file = base_output_dir / 'swift-test-output.txt'
            step_offset = 1

    # Step 2: Extract test outputs
    print_step(step_offset + 1, "Extracting test outputs from console...")
    try:
        test_outputs = extract_test_outputs(test_output_file)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

    print("")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print("")

    # Step 3: Evaluate with Claude
    print_step(step_offset + 2, f"Evaluating with Claude CLI (model: {args.model})...")

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

    # Step 4: Generate JSON report
    print_step(step_offset + 3, "Generating evaluation reports...")

    # Detect test type from first result (all should be same type)
    if all_results:
        test_type_str = all_results[0].test_type
        test_type = detect_test_type(test_type_str)

        json_output = output_dir / "evaluation-results.json"
        generate_json_report(all_results, json_output, test_type, args.model, output_dir)

    print("")

    # Generate HTML report (only in new mode)
    if not legacy_mode:
        generate_html_report(script_dir, output_dir, base_output_dir)

        print("")
        print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
        print("")

        # Display console summary
        show_console_summary(script_dir, output_dir, xcresult_path)

        print("")

    # Return exit code based on failures
    failed_count = sum(1 for r in all_results if r.status == "failed")
    sys.exit(failed_count)


if __name__ == "__main__":
    main()
