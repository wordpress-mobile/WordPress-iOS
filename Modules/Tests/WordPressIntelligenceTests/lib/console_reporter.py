#!/usr/bin/env python3
"""
Console report generator
Displays formatted evaluation summary in the terminal
"""

import json
import sys
from pathlib import Path
from typing import Dict, Any, List


class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'


def get_score_indicator(score: float) -> str:
    """Get score indicator with emoji"""
    if score >= 9.0:
        return "⭐️ Excellent"
    elif score >= 8.0:
        return "⭐️ Great"
    elif score >= 7.0:
        return "✅ Good"
    elif score >= 6.0:
        return "⚠️  Needs Work"
    else:
        return "❌ Poor"


def display_console_summary(json_file: Path, xcresult_path: str = None):
    """Display evaluation summary to console"""

    if not json_file.exists():
        print(f"{Colors.RED}Error: JSON report not found: {json_file}{Colors.NC}")
        return 1

    # Load JSON report
    with open(json_file) as f:
        report = json.load(f)

    metadata = report.get('metadata', {})
    summary = report.get('summary', {})
    results = report.get('results', [])

    test_type = metadata.get('testType', 'excerpt-generation')
    suite_name = metadata.get('suite', '')

    # Extract summary data
    total = summary.get('total', 0)
    passed = summary.get('passed', 0)
    failed = summary.get('failed', 0)
    needs_improvement = summary.get('needsImprovement', 0)
    avg_score = summary.get('averageScore', 0)
    pass_rate = summary.get('passRate', 0) * 100

    # Display header
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")

    if test_type == 'tag-suggestion':
        print(f"{Colors.BLUE}🏷️  Tag Suggestion Evaluation - Summary{Colors.NC}")
    elif test_type == 'post-summary':
        print(f"{Colors.BLUE}📝 Post Summary Evaluation - Summary{Colors.NC}")
    else:
        print(f"{Colors.BLUE}🖥️  Excerpt Generation Evaluation - Summary{Colors.NC}")

    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print()

    # Overall statistics
    print(f"{Colors.BLUE}📊 Overall Statistics{Colors.NC}")
    print(f"  Total Test Cases:   {total}")
    print(f"  {Colors.GREEN}✅ Passed:          {passed} ({pass_rate:.1f}%){Colors.NC}")

    if failed > 0:
        fail_pct = (failed * 100 / total) if total > 0 else 0
        print(f"  {Colors.RED}❌ Failed:          {failed} ({fail_pct:.1f}%){Colors.NC}")

    if needs_improvement > 0:
        needs_pct = (needs_improvement * 100 / total) if total > 0 else 0
        print(f"  {Colors.YELLOW}⚠️  Needs Work:      {needs_improvement} ({needs_pct:.1f}%){Colors.NC}")

    print(f"  Average Score:      {avg_score:.1f}/10")
    print()

    # Category averages (test type specific)
    avg_by_category = summary.get('averageByCategory', {})

    if test_type == 'tag-suggestion':
        display_tag_categories(avg_by_category)
    elif test_type == 'post-summary':
        display_summary_categories(avg_by_category)
    else:
        display_excerpt_categories(avg_by_category)

    print()

    # Failed tests
    if failed > 0:
        display_failed_tests(results, failed)

    # Needs improvement tests
    if needs_improvement > 0:
        display_needs_improvement_tests(results, needs_improvement)

    # Prompt improvement suggestions
    print(f"{Colors.BLUE}💡 Prompt Improvement Suggestions{Colors.NC}")

    if test_type == 'tag-suggestion':
        display_tag_suggestions(results)
    elif test_type == 'post-summary':
        display_summary_suggestions(results)
    else:
        display_excerpt_suggestions(results)

    # File paths
    print(f"{Colors.BLUE}📁 Detailed Results{Colors.NC}")

    html_file = json_file.parent / "evaluation-report.html"
    if html_file.exists():
        print(f"  HTML:  {html_file}")

    print(f"  JSON:  {json_file}")

    if xcresult_path and Path(xcresult_path).exists():
        print(f"  Tests: {xcresult_path}")

    print()
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")


def display_tag_categories(avg_by_category: Dict[str, float]):
    """Display tag-specific categories"""
    print(f"{Colors.BLUE}📈 Category Averages (across all tags){Colors.NC}")

    categories = [
        ('relevance', 'Relevance'),
        ('languageMatch', 'Language Match'),
        ('formatConsistency', 'Format Consistency'),
        ('seoQuality', 'SEO Quality'),
        ('uniqueness', 'Uniqueness'),
        ('specificity', 'Specificity'),
    ]

    for key, label in categories:
        score = avg_by_category.get(key, 0)
        indicator = get_score_indicator(score)
        print(f"  {label:20} {score:.1f}/10  {indicator}")


def display_summary_categories(avg_by_category: Dict[str, float]):
    """Display summary-specific categories"""
    print(f"{Colors.BLUE}📈 Category Averages (across all summaries){Colors.NC}")

    categories = [
        ('conciseness', 'Conciseness'),
        ('accuracy', 'Accuracy'),
        ('languageMatch', 'Language Match'),
        ('clarity', 'Clarity'),
        ('completeness', 'Completeness'),
        ('neutralTone', 'Neutral Tone'),
        ('coherence', 'Coherence'),
    ]

    for key, label in categories:
        score = avg_by_category.get(key, 0)
        indicator = get_score_indicator(score)
        print(f"  {label:20} {score:.1f}/10  {indicator}")


def display_excerpt_categories(avg_by_category: Dict[str, float]):
    """Display excerpt-specific categories"""
    print(f"{Colors.BLUE}📈 Category Averages (across all excerpts){Colors.NC}")

    categories = [
        ('languageMatch', 'Language Match'),
        ('grammar', 'Grammar'),
        ('relevance', 'Relevance'),
        ('lengthAppropriate', 'Length'),
        ('standalone', 'Standalone'),
        ('styleMatch', 'Style Match'),
        ('engagement', 'Engagement'),
    ]

    for key, label in categories:
        score = avg_by_category.get(key, 0)
        indicator = get_score_indicator(score)
        print(f"  {label:20} {score:.1f}/10  {indicator}")

    # Diversity (if present and > 0)
    diversity = avg_by_category.get('diversity', 0)
    if diversity > 0:
        indicator = get_score_indicator(diversity)
        print(f"  {'Diversity':20} {diversity:.1f}/10  {indicator}")


def display_failed_tests(results: List[Dict], failed_count: int):
    """Display failed tests"""
    print(f"{Colors.RED}❌ Failed Tests ({failed_count}){Colors.NC}")

    for result in results:
        if result.get('status') != 'failed':
            continue

        test_name = result.get('testName', 'Unknown')
        avg_score = result.get('averageScore', 0)
        lowest_score = result.get('lowestScore', 0)
        diversity = result.get('diversity', {}).get('score', 0)

        print(f"  • {test_name}")
        print(f"    Avg: {avg_score:.1f}/10 | Min: {lowest_score:.1f}/10")

        if diversity > 0 and diversity < 4.0:
            print(f"    {Colors.YELLOW}Low Diversity: {diversity:.1f}/10{Colors.NC}")

    print()


def display_needs_improvement_tests(results: List[Dict], needs_count: int):
    """Display tests that need improvement"""
    print(f"{Colors.YELLOW}⚠️  Needs Improvement ({needs_count}){Colors.NC}")

    for result in results:
        if result.get('status') != 'needsImprovement':
            continue

        test_name = result.get('testName', 'Unknown')
        avg_score = result.get('averageScore', 0)
        lowest_score = result.get('lowestScore', 0)
        diversity = result.get('diversity', {}).get('score', 0)

        print(f"  • {test_name}")
        print(f"    Avg: {avg_score:.1f}/10 | Min: {lowest_score:.1f}/10")

        if diversity > 0 and diversity < 5.0:
            print(f"    Low Diversity: {diversity:.1f}/10")

    print()


def display_tag_suggestions(results: List[Dict]):
    """Display tag-specific improvement suggestions"""
    suggestion_count = 0

    # Count low scores across all tags
    low_relevance = sum(
        1 for result in results
        for tag in result.get('tags', [])
        if tag.get('scores', {}).get('relevance', 10) < 6
    )

    low_lang = sum(
        1 for result in results
        for tag in result.get('tags', [])
        if tag.get('scores', {}).get('languageMatch', 10) < 7
    )

    low_format = sum(
        1 for result in results
        for tag in result.get('tags', [])
        if tag.get('scores', {}).get('formatConsistency', 10) < 7
    )

    if low_relevance > 0:
        suggestion_count += 1
        print(f"  {suggestion_count}. Relevance: Generate more relevant tags (affects {low_relevance} tags)")
        print()

    if low_lang > 0:
        suggestion_count += 1
        print(f"  {suggestion_count}. Language Enforcement (affects {low_lang} tags)")
        print()

    if low_format > 0:
        suggestion_count += 1
        print(f"  {suggestion_count}. Format Consistency: Match site tag formatting better (affects {low_format} tags)")
        print()

    if suggestion_count == 0:
        print("  No significant issues found!")
        print()


def display_summary_suggestions(results: List[Dict]):
    """Display summary-specific improvement suggestions"""
    suggestion_count = 0

    low_conciseness = sum(
        1 for result in results
        if result.get('summary', {}).get('scores', {}).get('conciseness', 10) < 6
    )

    low_accuracy = sum(
        1 for result in results
        if result.get('summary', {}).get('scores', {}).get('accuracy', 10) < 6
    )

    low_lang = sum(
        1 for result in results
        if result.get('summary', {}).get('scores', {}).get('languageMatch', 10) < 7
    )

    if low_conciseness > 0:
        suggestion_count += 1
        print(f"  {suggestion_count}. Conciseness: Generate more concise summaries (affects {low_conciseness} summaries)")
        print()

    if low_accuracy > 0:
        suggestion_count += 1
        print(f"  {suggestion_count}. Accuracy: Capture main points more accurately (affects {low_accuracy} summaries)")
        print()

    if low_lang > 0:
        suggestion_count += 1
        print(f"  {suggestion_count}. Language Enforcement (affects {low_lang} summaries)")
        print()

    if suggestion_count == 0:
        print("  No significant issues found!")
        print()


def display_excerpt_suggestions(results: List[Dict]):
    """Display excerpt-specific improvement suggestions"""
    suggestion_count = 0

    low_lang = sum(
        1 for result in results
        for excerpt in result.get('excerpts', [])
        if excerpt.get('scores', {}).get('languageMatch', 10) < 8
    )

    low_diversity = sum(
        1 for result in results
        if 0 < result.get('diversity', {}).get('score', 10) < 5
    )

    if low_lang > 0:
        suggestion_count += 1
        print(f"  {suggestion_count}. Language Enforcement (affects {low_lang} excerpts)")
        print()

    if low_diversity > 0:
        suggestion_count += 1
        print(f"  {suggestion_count}. Diversity: Generate more varied excerpts (affects {low_diversity} test cases)")
        print()

    if suggestion_count == 0:
        print("  No significant issues found!")
        print()


def main():
    if len(sys.argv) < 2:
        print("Usage: console_reporter.py <json_report_path> [xcresult_path]")
        sys.exit(1)

    json_file = Path(sys.argv[1])
    xcresult_path = sys.argv[2] if len(sys.argv) > 2 else None

    display_console_summary(json_file, xcresult_path)


if __name__ == "__main__":
    main()
