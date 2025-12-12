#!/usr/bin/env python3
"""
Generate mock baseline data for testing comparison features.
Takes an existing evaluation JSON and creates a modified version with perturbed scores.
"""

import json
import random
import argparse
import sys
from pathlib import Path
from datetime import datetime, timedelta, UTC


def perturb_score(score: float, variation: float = 0.5) -> float:
    """
    Perturb a score by a random amount within +/- variation.
    Ensures result stays within 1.0-10.0 range.
    """
    delta = random.uniform(-variation, variation)
    new_score = score + delta
    return max(1.0, min(10.0, new_score))


def create_mock_baseline(
    current_data: dict,
    score_variation: float = 0.5,
    time_delta_hours: int = 24,
    seed: int = None
) -> dict:
    """
    Create a mock baseline by modifying scores and timestamp.

    Args:
        current_data: Current evaluation data
        score_variation: Maximum variation for score perturbation (+/-)
        time_delta_hours: Hours to subtract from current timestamp
        seed: Random seed for reproducible results

    Returns:
        Modified baseline data
    """
    if seed is not None:
        random.seed(seed)

    # Deep copy the data
    baseline = json.loads(json.dumps(current_data))

    # Update timestamp to be earlier
    if baseline.get('metadata') and baseline['metadata'].get('timestamp'):
        current_time = datetime.fromisoformat(baseline['metadata']['timestamp'].replace('Z', '+00:00'))
        baseline_time = current_time - timedelta(hours=time_delta_hours)
        baseline['metadata']['timestamp'] = baseline_time.strftime('%Y-%m-%dT%H:%M:%SZ')

    # Perturb all scores in results
    for result in baseline.get('results', []):
        # Perturb item scores (excerpts, tags, summary)
        test_type = result.get('testType', 'excerpt-generation')

        if 'excerpt' in test_type:
            for excerpt in result.get('excerpts', []):
                perturb_item_scores(excerpt, score_variation)
        elif 'tag' in test_type:
            for tag in result.get('tags', []):
                perturb_item_scores(tag, score_variation)
        elif 'summary' in test_type:
            summary = result.get('summary')
            if summary:
                perturb_item_scores(summary, score_variation)

        # Perturb diversity score if present
        if result.get('diversity'):
            result['diversity']['score'] = perturb_score(
                result['diversity']['score'],
                score_variation
            )

        # Recalculate aggregate scores
        recalculate_aggregates(result, test_type)

    # Recalculate summary statistics
    recalculate_summary(baseline)

    # Add marker in output directory path if present
    if baseline.get('metadata') and baseline['metadata'].get('outputDirectory'):
        baseline['metadata']['outputDirectory'] = baseline['metadata']['outputDirectory'].replace(
            'evaluation-',
            'baseline-mock-'
        )

    return baseline


def perturb_item_scores(item: dict, variation: float):
    """Perturb all scores in an item (excerpt, tag, or summary)."""
    scores = item.get('scores', {})
    for key in scores:
        if key != 'feedback' and isinstance(scores[key], (int, float)):
            scores[key] = perturb_score(scores[key], variation)

    # Recalculate overall score (weighted average)
    if scores:
        # Use simple average since we don't have weights here
        numeric_scores = [v for v in scores.values() if isinstance(v, (int, float))]
        if numeric_scores:
            item['overall'] = sum(numeric_scores) / len(numeric_scores)


def recalculate_aggregates(result: dict, test_type: str):
    """Recalculate average and lowest scores for a test result."""
    items = []

    if 'excerpt' in test_type:
        items = result.get('excerpts', [])
    elif 'tag' in test_type:
        items = result.get('tags', [])
    elif 'summary' in test_type:
        summary = result.get('summary')
        items = [summary] if summary else []

    if items:
        overall_scores = [item.get('overall', 0) for item in items]
        result['averageScore'] = sum(overall_scores) / len(overall_scores)
        result['lowestScore'] = min(overall_scores)

        # Update status based on new scores
        avg = result['averageScore']
        if avg >= 7.0:
            result['status'] = 'passed'
        elif avg >= 6.0:
            result['status'] = 'needsImprovement'
        else:
            result['status'] = 'failed'


def recalculate_summary(baseline: dict):
    """Recalculate summary statistics."""
    results = baseline.get('results', [])
    if not results:
        return

    total = len(results)
    passed = sum(1 for r in results if r.get('status') == 'passed')
    failed = sum(1 for r in results if r.get('status') == 'failed')
    needs_improvement = sum(1 for r in results if r.get('status') == 'needsImprovement')

    avg_scores = [r.get('averageScore', 0) for r in results]
    avg_overall = sum(avg_scores) / len(avg_scores) if avg_scores else 0

    baseline['summary'] = {
        'total': total,
        'passed': passed,
        'failed': failed,
        'needsImprovement': needs_improvement,
        'averageScore': avg_overall,
        'averageByCategory': baseline.get('summary', {}).get('averageByCategory', {}),
        'passRate': passed / total if total > 0 else 0
    }


def main():
    parser = argparse.ArgumentParser(
        description='Generate mock baseline data for comparison testing'
    )
    parser.add_argument(
        'input',
        help='Input evaluation JSON file (current/recent evaluation)'
    )
    parser.add_argument(
        'output',
        help='Output baseline JSON file'
    )
    parser.add_argument(
        '--variation',
        type=float,
        default=0.5,
        help='Score variation range (+/- value, default: 0.5)'
    )
    parser.add_argument(
        '--hours-ago',
        type=int,
        default=24,
        help='How many hours ago the baseline was run (default: 24)'
    )
    parser.add_argument(
        '--seed',
        type=int,
        help='Random seed for reproducible results'
    )
    parser.add_argument(
        '--improve',
        action='store_true',
        help='Bias towards improvement (current better than baseline)'
    )
    parser.add_argument(
        '--regress',
        action='store_true',
        help='Bias towards regression (current worse than baseline)'
    )

    args = parser.parse_args()

    # Load input
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    with open(input_path) as f:
        current_data = json.load(f)

    # Adjust variation for bias
    variation = args.variation
    if args.improve:
        # Baseline will be worse, so subtract from baseline scores
        variation = -abs(variation)
    elif args.regress:
        # Baseline will be better, so add to baseline scores
        variation = abs(variation)

    # Generate mock baseline
    baseline_data = create_mock_baseline(
        current_data,
        score_variation=variation,
        time_delta_hours=args.hours_ago,
        seed=args.seed
    )

    # Write output
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w') as f:
        json.dump(baseline_data, f, indent=2)

    print(f"✓ Generated mock baseline: {output_path}")
    print(f"  Variation: ±{abs(args.variation)}")
    if args.improve:
        print(f"  Bias: IMPROVED (current better than baseline)")
    elif args.regress:
        print(f"  Bias: REGRESSED (current worse than baseline)")
    print(f"  Time delta: {args.hours_ago} hours ago")

    # Show summary
    current_avg = current_data.get('summary', {}).get('averageScore', 0)
    baseline_avg = baseline_data.get('summary', {}).get('averageScore', 0)
    delta = current_avg - baseline_avg

    print(f"\n  Current avg score:  {current_avg:.2f}")
    print(f"  Baseline avg score: {baseline_avg:.2f}")
    print(f"  Delta: {delta:+.2f}")


if __name__ == '__main__':
    main()
