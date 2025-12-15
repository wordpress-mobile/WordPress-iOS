#!/usr/bin/env python3
"""
Evaluators for WordPressIntelligence test results

This module provides the evaluation framework for assessing AI-generated content
(excerpts, tags, summaries) using Claude as an LLM judge. Each evaluator:
1. Extracts generated items from test output
2. Builds evaluation prompts with criteria
3. Sends to Claude for scoring
4. Determines pass/fail/needs-improvement status

Classes:
    BaseEvaluator: Abstract base with shared evaluation logic
    ExcerptEvaluator: Evaluates post excerpts with diversity checking
    TagEvaluator: Evaluates tag suggestions
    SummaryEvaluator: Evaluates post summaries
"""

from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Dict, Any, List

from config import TestTypeConfig, TestType, get_config
from claude_client import ClaudeClient


# ANSI color codes for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'


@dataclass
class EvaluationResult:
    """Result of evaluating a single generated item

    Attributes:
        number: Item number (1-indexed)
        text: The generated text (excerpt/tag/summary)
        scores: Per-criterion scores (e.g., {"relevance": 8.5, "clarity": 9.0})
        overall: Weighted overall score (0-10)
        status: "passed", "needsImprovement", or "failed"
        failure_reason: Why it failed/needs improvement (empty if passed)
        word_count: Number of words in the text
    """
    number: int
    text: str
    scores: Dict[str, float]
    overall: float
    status: str
    failure_reason: str = ""
    word_count: int = 0


@dataclass
class TestResult:
    """Complete test case result with all evaluated items

    Attributes:
        id: Test identifier (e.g., "test_1")
        test_name: Human-readable test name
        test_type: Type of test (excerpt-generation, tag-suggestion, etc.)
        status: Overall status (worst of all items)
        input_data: Original input metadata (language, content preview, etc.)
        items: All evaluated items (excerpts, tags, or summary)
        average_score: Mean score across all items
        lowest_score: Minimum score across all items
        duration: Test execution time in seconds
        diversity: Diversity evaluation (excerpts only, optional)
    """
    id: str
    test_name: str
    test_type: str
    status: str
    input_data: Dict[str, Any]
    items: List[EvaluationResult]
    average_score: float
    lowest_score: float
    duration: float
    diversity: Dict[str, Any] | None = None


class BaseEvaluator(ABC):
    """Abstract base class for test evaluators

    Subclasses implement extract_items() and build_evaluation_prompt()
    to customize for different test types (excerpts, tags, summaries).
    """

    def __init__(self, config: TestTypeConfig, claude: ClaudeClient):
        """Initialize evaluator with config and Claude client"""
        self.config = config
        self.claude = claude

    @abstractmethod
    def build_evaluation_prompt(self, test_data: Dict[str, Any], item: str) -> str:
        """Build Claude evaluation prompt for a single item

        Args:
            test_data: Full test data including original content and metadata
            item: Single item to evaluate (excerpt/tag/summary text)

        Returns:
            Formatted prompt string requesting JSON scores
        """
        pass

    @abstractmethod
    def extract_items(self, test_data: Dict[str, Any]) -> List[str]:
        """Extract items to evaluate from test output

        Args:
            test_data: Full test data from Swift tests

        Returns:
            List of text items to evaluate (excerpts, tags, or [summary])
        """
        pass

    def evaluate_test(self, test_data: Dict[str, Any], result_id: int) -> TestResult:
        """Evaluate a complete test case with all generated items

        Args:
            test_data: Full test output from Swift tests
            result_id: Sequential test number for identification

        Returns:
            Complete TestResult with all item scores and overall status
        """
        test_name = test_data.get('testName', f'test_{result_id}')
        language = test_data.get('language', 'unknown')
        duration = test_data.get('duration', 0.0)

        print(f"{Colors.CYAN}Evaluating: {test_name}{Colors.NC}")
        print(f"  Type: {self.config.name} | Language: {language}")

        # Extract and validate items
        items = self.extract_items(test_data)
        if not items:
            print(f"  {Colors.RED}No items found{Colors.NC}")
            return self._create_empty_result(test_data, result_id, duration)

        print(f"  Found {len(items)} item(s)")

        # Evaluate each item with Claude
        item_results = [
            result for idx, item in enumerate(items, 1)
            if (result := self.evaluate_item(test_data, item, idx, len(items)))
        ]

        if not item_results:
            return self._create_empty_result(test_data, result_id, duration)

        # Calculate aggregate scores
        avg_score = sum(r.overall for r in item_results) / len(item_results)
        lowest_score = min(r.overall for r in item_results)
        status = self._calculate_overall_status(item_results)

        # Check diversity for excerpts (if enabled and multiple items)
        diversity = None
        if self.config.diversity_check and len(items) >= 2:
            diversity = self.evaluate_diversity(items)
            if diversity and diversity.get('score', 0) < 4.0:
                status = "needsImprovement"

        print(f"  {Colors.CYAN}Overall: {avg_score:.1f}/10 avg, {lowest_score:.1f}/10 min{Colors.NC}")
        print("")

        return TestResult(
            id=f"test_{result_id}",
            test_name=test_name,
            test_type=test_data.get('testType', self.config.name.lower()),
            status=status,
            input_data=self._extract_input_data(test_data),
            items=item_results,
            average_score=avg_score,
            lowest_score=lowest_score,
            duration=duration,
            diversity=diversity,
        )

    def evaluate_item(self, test_data: Dict[str, Any], item: str, num: int, total: int) -> EvaluationResult | None:
        """Evaluate a single item using Claude as judge

        Args:
            test_data: Full test data for context
            item: Text to evaluate
            num: Item number (1-indexed)
            total: Total number of items

        Returns:
            EvaluationResult if successful, None if Claude evaluation fails
        """
        preview = f"{item[:50]}..." if len(item) > 50 else item
        print(f"  {Colors.BLUE}Item {num}/{total}{Colors.NC} ({preview})")

        # Build and send evaluation prompt to Claude
        prompt = self.build_evaluation_prompt(test_data, item)
        scores = self.claude.evaluate(prompt)

        if not scores:
            print(f"    {Colors.RED}✗ Evaluation failed{Colors.NC}")
            return None

        # Calculate weighted score and determine status
        overall = self._calculate_weighted_score(scores)
        status, failure_reason = self._determine_status(scores, overall)
        self._display_status(status, overall, failure_reason)

        return EvaluationResult(
            number=num,
            text=item,
            scores=scores,
            overall=overall,
            status=status,
            failure_reason=failure_reason,
            word_count=len(item.split()),
        )

    def _calculate_weighted_score(self, scores: Dict[str, float]) -> float:
        """Calculate weighted average of criterion scores (0-10)"""
        weighted_sum = sum(
            scores.get(c.name, 0.0) * c.weight
            for c in self.config.criteria
        )
        return weighted_sum / self.config.total_weight

    def _determine_status(self, scores: Dict[str, float], overall: float) -> tuple[str, str]:
        """Determine pass/needsImprovement/failed status

        Returns:
            (status, failure_reason) tuple
            - status: "passed", "needsImprovement", or "failed"
            - failure_reason: Explanation if not passed, empty string if passed
        """
        # Check critical thresholds (any failure = test fails)
        for criterion in self.config.criteria:
            if criterion.critical_threshold > 0:
                score = scores.get(criterion.name, 0.0)
                if score < criterion.critical_threshold:
                    return "failed", f"Low {criterion.name} ({score:.1f}/10)"

        # Check overall score thresholds
        if overall >= self.config.pass_threshold:
            return "passed", ""
        if overall >= self.config.needs_improvement_threshold:
            return "needsImprovement", "Below target score"
        return "failed", f"Low overall score ({overall:.1f}/10)"

    def _display_status(self, status: str, score: float, failure_reason: str):
        """Display colored status message to console"""
        status_icons = {
            "passed": (Colors.GREEN, "✓"),
            "needsImprovement": (Colors.YELLOW, "⚠"),
            "failed": (Colors.RED, "✗"),
        }
        color, icon = status_icons.get(status, (Colors.RED, "✗"))
        reason_text = f" - {failure_reason}" if failure_reason else ""
        print(f"    {color}{icon} {score:.1f}/10{Colors.NC}{reason_text}")

    def _calculate_overall_status(self, item_results: List[EvaluationResult]) -> str:
        """Calculate overall status from item results (worst status wins)"""
        if any(r.status == "failed" for r in item_results):
            return "failed"
        if any(r.status == "needsImprovement" for r in item_results):
            return "needsImprovement"
        return "passed"

    def _extract_input_data(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Extract common input metadata for JSON result

        Subclasses can override to add type-specific fields
        """
        return {
            "language": test_data.get('language', 'unknown'),
            "originalContent": test_data.get('originalContent', ''),
            "originalContentPreview": test_data.get('originalContent', '')[:200],
        }

    def _create_empty_result(self, test_data: Dict[str, Any], result_id: int, duration: float) -> TestResult:
        """Create failed result when no items found or all evaluations failed"""
        return TestResult(
            id=f"test_{result_id}",
            test_name=test_data.get('testName', f'test_{result_id}'),
            test_type=test_data.get('testType', self.config.name.lower()),
            status="failed",
            input_data=self._extract_input_data(test_data),
            items=[],
            average_score=0.0,
            lowest_score=0.0,
            duration=duration,
        )

    def evaluate_diversity(self, items: List[str]) -> Dict[str, Any] | None:
        """Evaluate diversity across multiple generated items

        Used for excerpts to ensure meaningful variation between options.
        Scores structural, angle, length, and lexical diversity.

        Args:
            items: List of generated items (excerpts)

        Returns:
            {"score": float, "feedback": str} or None if evaluation fails
        """
        print(f"  {Colors.BLUE}Checking diversity...{Colors.NC}")

        items_text = "\n".join(f"Item {i+1}: {item}" for i, item in enumerate(items))

        prompt = f"""Evaluate the diversity of these {len(items)} variations. They should offer meaningful choices.

{items_text}

Score diversity across dimensions:
1. Structural Diversity: Different opening styles?
2. Angle Diversity: Different aspects emphasized?
3. Length Diversity: Varied sentence lengths?
4. Lexical Diversity: Different vocabulary?

Good diversity (7-10): Clearly distinct approaches, different hooks, reader can make meaningful choice
Poor diversity (1-6): Too similar, same structure, minor wording changes only

Respond with JSON only:
{{
  "structural": <score>,
  "angle": <score>,
  "length": <score>,
  "lexical": <score>,
  "overall": <score>,
  "feedback": "<brief explanation>"
}}"""

        result = self.claude.evaluate(prompt)
        if result:
            score = result.get('overall', 0)
            print(f"    {Colors.CYAN}Diversity: {score:.1f}/10{Colors.NC}")
            return {"score": score, "feedback": result.get('feedback', 'N/A')}

        return None


class ExcerptEvaluator(BaseEvaluator):
    """Evaluator for post excerpt generation

    Evaluates generated excerpts against criteria like relevance, readability,
    and engagement. Also checks diversity when multiple excerpts are generated.
    """

    def extract_items(self, test_data: Dict[str, Any]) -> List[str]:
        """Extract excerpts array from test data"""
        return test_data.get('excerpts', [])

    def build_evaluation_prompt(self, test_data: Dict[str, Any], excerpt: str) -> str:
        """Build Claude prompt to evaluate a single excerpt"""
        content_preview = test_data.get('originalContent', '')[:500]
        language = test_data.get('language', 'unknown')
        style = test_data.get('style', 'unknown')
        length = test_data.get('length', 'unknown')

        criteria_lines = "\n".join(
            f"- {c.name} (1-10): {c.description}"
            for c in self.config.criteria
        )
        json_fields = ', '.join(f'"{c.name}": <score>' for c in self.config.criteria)

        return f"""Evaluate this excerpt and respond with JSON only:

Original Content (first 500 chars):
{content_preview}...

Generated Excerpt:
{excerpt}

Expected: {language} language, {length} length, {style} style

Rate each criterion 1.0-10.0 (use decimals for precision, e.g., 7.3, 8.6):
- Very few things deserve a perfect 10.0 - reserve this for truly exceptional quality
- Be critical and nuanced in your scoring - use the full range

{criteria_lines}

Respond in this exact JSON format (scores must be numbers with one decimal place):
{{
  {json_fields},
  "feedback": "<brief explanation>"
}}"""

    def _extract_input_data(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Add excerpt-specific metadata (style, length)"""
        data = super()._extract_input_data(test_data)
        data.update({
            "style": test_data.get('style', 'unknown'),
            "length": test_data.get('length', 'unknown'),
        })
        return data


class TagEvaluator(BaseEvaluator):
    """Evaluator for tag suggestions

    Evaluates generated tags for relevance, appropriateness for the site's
    existing taxonomy, and whether they enhance discoverability.
    """

    def extract_items(self, test_data: Dict[str, Any]) -> List[str]:
        """Extract tags array from test data"""
        return test_data.get('tags', [])

    def build_evaluation_prompt(self, test_data: Dict[str, Any], tag: str) -> str:
        """Build Claude prompt to evaluate a single tag"""
        content_preview = test_data.get('originalContent', '')[:500]
        language = test_data.get('language', 'unknown')
        site_tags = ', '.join(test_data.get('siteTags', []))
        existing_tags = ', '.join(test_data.get('existingPostTags', []))

        criteria_lines = "\n".join(
            f"- {c.name} (1-10): {c.description}"
            for c in self.config.criteria
        )
        json_fields = ', '.join(f'"{c.name}": <score>' for c in self.config.criteria)

        return f"""Evaluate this tag suggestion and respond with JSON only:

Original Content (first 500 chars):
{content_preview}...

Site Tags: {site_tags}
Existing Post Tags: {existing_tags}

Generated Tag: {tag}

Expected: {language} language

Rate each criterion 1.0-10.0 (use decimals for precision, e.g., 7.3, 8.6):
- Very few things deserve a perfect 10.0 - reserve this for truly exceptional quality
- Be critical and nuanced in your scoring - use the full range

{criteria_lines}

Respond in this exact JSON format (scores must be numbers with one decimal place):
{{
  {json_fields},
  "feedback": "<brief explanation>"
}}"""

    def _extract_input_data(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Add tag-specific metadata (site tags, existing post tags)"""
        data = super()._extract_input_data(test_data)
        data.update({
            "siteTags": ', '.join(test_data.get('siteTags', [])),
            "existingPostTags": ', '.join(test_data.get('existingPostTags', [])),
        })
        return data


class SummaryEvaluator(BaseEvaluator):
    """Evaluator for post summaries

    Evaluates generated summaries for accuracy, completeness,
    and conciseness in capturing the post's key points.
    """

    def extract_items(self, test_data: Dict[str, Any]) -> List[str]:
        """Extract summary from test data (returns single-item list or empty list)"""
        summary = test_data.get('summary')
        return [summary] if summary else []

    def build_evaluation_prompt(self, test_data: Dict[str, Any], summary: str) -> str:
        """Build Claude prompt to evaluate the summary"""
        content_preview = test_data.get('originalContent', '')[:500]
        language = test_data.get('language', 'unknown')

        criteria_lines = "\n".join(
            f"- {c.name} (1-10): {c.description}"
            for c in self.config.criteria
        )
        json_fields = ', '.join(f'"{c.name}": <score>' for c in self.config.criteria)

        return f"""Evaluate this post summary and respond with JSON only:

Original Content (first 500 chars):
{content_preview}...

Generated Summary:
{summary}

Expected: {language} language

Rate each criterion 1.0-10.0 (use decimals for precision, e.g., 7.3, 8.6):
- Very few things deserve a perfect 10.0 - reserve this for truly exceptional quality
- Be critical and nuanced in your scoring - use the full range

{criteria_lines}

Respond in this exact JSON format (scores must be numbers with one decimal place):
{{
  {json_fields},
  "feedback": "<brief explanation>"
}}"""


def create_evaluator(test_type: TestType, claude: ClaudeClient) -> BaseEvaluator:
    """Factory function to create appropriate evaluator for test type

    Args:
        test_type: Type of test (EXCERPT, TAG, or SUMMARY)
        claude: ClaudeClient instance for LLM evaluation

    Returns:
        Concrete evaluator instance (ExcerptEvaluator, TagEvaluator, or SummaryEvaluator)
    """
    config = get_config(test_type)

    evaluators = {
        TestType.EXCERPT: ExcerptEvaluator,
        TestType.TAG: TagEvaluator,
        TestType.SUMMARY: SummaryEvaluator,
    }

    evaluator_class = evaluators[test_type]
    return evaluator_class(config, claude)
