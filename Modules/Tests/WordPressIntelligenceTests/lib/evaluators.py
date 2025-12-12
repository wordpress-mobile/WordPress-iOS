#!/usr/bin/env python3
"""
Evaluation logic for different test types
Base class + concrete implementations for excerpts, tags, and summaries
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional
import time

from config import TestTypeConfig, TestType, get_config
from claude_client import ClaudeClient


# ANSI color codes
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'


@dataclass
class EvaluationResult:
    """Result of evaluating a single item (excerpt/tag/summary)"""
    number: int
    text: str
    scores: Dict[str, float]
    overall: float
    status: str
    failure_reason: str = ""
    word_count: int = 0


@dataclass
class TestResult:
    """Complete test case result"""
    id: str
    test_name: str
    test_type: str
    status: str
    input_data: Dict[str, Any]
    items: List[EvaluationResult]  # excerpts, tags, or summary
    average_score: float
    lowest_score: float
    duration: float
    diversity: Optional[Dict[str, Any]] = None


class BaseEvaluator(ABC):
    """Base class for all evaluators"""

    def __init__(self, config: TestTypeConfig, claude: ClaudeClient):
        self.config = config
        self.claude = claude

    @abstractmethod
    def build_evaluation_prompt(self, test_data: Dict[str, Any], item: str) -> str:
        """Build evaluation prompt for a single item"""
        pass

    @abstractmethod
    def extract_items(self, test_data: Dict[str, Any]) -> List[str]:
        """Extract items to evaluate (excerpts, tags, or summary)"""
        pass

    def evaluate_test(self, test_data: Dict[str, Any], result_id: int) -> TestResult:
        """Evaluate a complete test case"""
        test_name = test_data.get('testName', f'test_{result_id}')
        language = test_data.get('language', 'unknown')
        duration = test_data.get('duration', 0.0)

        print(f"{Colors.CYAN}Evaluating: {test_name}{Colors.NC}")
        print(f"  Type: {self.config.name} | Language: {language}")

        # Extract items to evaluate
        items = self.extract_items(test_data)
        if not items:
            print(f"  {Colors.RED}No items found{Colors.NC}")
            return self._create_empty_result(test_data, result_id, duration)

        print(f"  Found {len(items)} item(s)")

        # Evaluate each item
        item_results = []
        for idx, item in enumerate(items, 1):
            result = self.evaluate_item(test_data, item, idx, len(items))
            if result:
                item_results.append(result)

        # Calculate aggregate scores
        if not item_results:
            return self._create_empty_result(test_data, result_id, duration)

        avg_score = sum(r.overall for r in item_results) / len(item_results)
        lowest_score = min(r.overall for r in item_results)

        # Determine overall status
        status = self._calculate_overall_status(item_results)

        # Check diversity if enabled
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

    def evaluate_item(self, test_data: Dict[str, Any], item: str, num: int, total: int) -> Optional[EvaluationResult]:
        """Evaluate a single item"""
        preview = (item[:50] + "...") if len(item) > 50 else item
        print(f"  {Colors.BLUE}Item {num}/{total}{Colors.NC} ({preview})")

        # Build and send evaluation prompt
        prompt = self.build_evaluation_prompt(test_data, item)
        scores = self.claude.evaluate(prompt)

        if not scores:
            print(f"    {Colors.RED}✗ Evaluation failed{Colors.NC}")
            return None

        # Calculate weighted overall score
        overall = self._calculate_weighted_score(scores)

        # Determine status and failure reason
        status, failure_reason = self._determine_status(scores, overall)

        # Display status
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
        """Calculate weighted overall score"""
        total = 0.0
        for criterion in self.config.criteria:
            score = scores.get(criterion.name, 0.0)
            total += score * criterion.weight
        return total / self.config.total_weight

    def _determine_status(self, scores: Dict[str, float], overall: float) -> tuple[str, str]:
        """Determine pass/fail/needs improvement status"""
        # Check critical thresholds
        for criterion in self.config.criteria:
            if criterion.critical_threshold > 0:
                score = scores.get(criterion.name, 0.0)
                if score < criterion.critical_threshold:
                    return "failed", f"Low {criterion.name} ({score:.1f}/10)"

        # Check overall thresholds
        if overall >= self.config.pass_threshold:
            return "passed", ""
        elif overall >= self.config.needs_improvement_threshold:
            return "needsImprovement", "Below target score"
        else:
            return "failed", f"Low overall score ({overall:.1f}/10)"

    def _display_status(self, status: str, score: float, failure_reason: str):
        """Display colored status message"""
        if status == "passed":
            print(f"    {Colors.GREEN}✓ {score:.1f}/10{Colors.NC}")
        elif status == "needsImprovement":
            print(f"    {Colors.YELLOW}⚠ {score:.1f}/10{Colors.NC} - {failure_reason}")
        else:
            print(f"    {Colors.RED}✗ {score:.1f}/10{Colors.NC} - {failure_reason}")

    def _calculate_overall_status(self, item_results: List[EvaluationResult]) -> str:
        """Calculate overall status from item results"""
        passed = sum(1 for r in item_results if r.status == "passed")
        failed = sum(1 for r in item_results if r.status == "failed")

        if failed > 0:
            return "failed"
        elif passed < len(item_results):
            return "needsImprovement"
        else:
            return "passed"

    def _extract_input_data(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Extract input metadata for result"""
        return {
            "language": test_data.get('language', 'unknown'),
            "originalContent": test_data.get('originalContent', ''),
            "originalContentPreview": test_data.get('originalContent', '')[:200],
        }

    def _create_empty_result(self, test_data: Dict[str, Any], result_id: int, duration: float) -> TestResult:
        """Create empty result for failed test"""
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

    def evaluate_diversity(self, items: List[str]) -> Optional[Dict[str, Any]]:
        """Evaluate diversity of multiple items (for excerpts)"""
        print(f"  {Colors.BLUE}Checking diversity...{Colors.NC}")

        prompt = f"""Evaluate the diversity of these {len(items)} variations. They should offer meaningful choices.

{chr(10).join(f"Item {i+1}: {item}" for i, item in enumerate(items))}

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
    """Evaluator for excerpt generation"""

    def extract_items(self, test_data: Dict[str, Any]) -> List[str]:
        return test_data.get('excerpts', [])

    def build_evaluation_prompt(self, test_data: Dict[str, Any], excerpt: str) -> str:
        content = test_data.get('originalContent', '')[:500]
        language = test_data.get('language', 'unknown')
        style = test_data.get('style', 'unknown')
        length = test_data.get('length', 'unknown')

        criteria_desc = []
        for criterion in self.config.criteria:
            criteria_desc.append(f"- {criterion.name} (1-10): {criterion.description}")

        return f"""Evaluate this excerpt and respond with JSON only:

Original Content (first 500 chars):
{content}...

Generated Excerpt:
{excerpt}

Expected: {language} language, {length} length, {style} style

Rate each criterion 1.0-10.0 (use decimals for precision, e.g., 7.3, 8.6):
- Very few things deserve a perfect 10.0 - reserve this for truly exceptional quality
- Be critical and nuanced in your scoring - use the full range

{chr(10).join(criteria_desc)}

Respond in this exact JSON format (scores must be numbers with one decimal place):
{{
  {', '.join(f'"{c.name}": <score>' for c in self.config.criteria)},
  "feedback": "<brief explanation>"
}}"""

    def _extract_input_data(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        data = super()._extract_input_data(test_data)
        data.update({
            "style": test_data.get('style', 'unknown'),
            "length": test_data.get('length', 'unknown'),
        })
        return data


class TagEvaluator(BaseEvaluator):
    """Evaluator for tag suggestions"""

    def extract_items(self, test_data: Dict[str, Any]) -> List[str]:
        return test_data.get('tags', [])

    def build_evaluation_prompt(self, test_data: Dict[str, Any], tag: str) -> str:
        content = test_data.get('originalContent', '')[:500]
        language = test_data.get('language', 'unknown')
        site_tags = ', '.join(test_data.get('siteTags', []))
        existing_tags = ', '.join(test_data.get('existingPostTags', []))

        criteria_desc = []
        for criterion in self.config.criteria:
            criteria_desc.append(f"- {criterion.name} (1-10): {criterion.description}")

        return f"""Evaluate this tag suggestion and respond with JSON only:

Original Content (first 500 chars):
{content}...

Site Tags: {site_tags}
Existing Post Tags: {existing_tags}

Generated Tag: {tag}

Expected: {language} language

Rate each criterion 1.0-10.0 (use decimals for precision, e.g., 7.3, 8.6):
- Very few things deserve a perfect 10.0 - reserve this for truly exceptional quality
- Be critical and nuanced in your scoring - use the full range

{chr(10).join(criteria_desc)}

Respond in this exact JSON format (scores must be numbers with one decimal place):
{{
  {', '.join(f'"{c.name}": <score>' for c in self.config.criteria)},
  "feedback": "<brief explanation>"
}}"""

    def _extract_input_data(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        data = super()._extract_input_data(test_data)
        data.update({
            "siteTags": ', '.join(test_data.get('siteTags', [])),
            "existingPostTags": ', '.join(test_data.get('existingPostTags', [])),
        })
        return data


class SummaryEvaluator(BaseEvaluator):
    """Evaluator for post summaries"""

    def extract_items(self, test_data: Dict[str, Any]) -> List[str]:
        summary = test_data.get('summary')
        return [summary] if summary else []

    def build_evaluation_prompt(self, test_data: Dict[str, Any], summary: str) -> str:
        content = test_data.get('originalContent', '')[:500]
        language = test_data.get('language', 'unknown')

        criteria_desc = []
        for criterion in self.config.criteria:
            criteria_desc.append(f"- {criterion.name} (1-10): {criterion.description}")

        return f"""Evaluate this post summary and respond with JSON only:

Original Content (first 500 chars):
{content}...

Generated Summary:
{summary}

Expected: {language} language

Rate each criterion 1.0-10.0 (use decimals for precision, e.g., 7.3, 8.6):
- Very few things deserve a perfect 10.0 - reserve this for truly exceptional quality
- Be critical and nuanced in your scoring - use the full range

{chr(10).join(criteria_desc)}

Respond in this exact JSON format (scores must be numbers with one decimal place):
{{
  {', '.join(f'"{c.name}": <score>' for c in self.config.criteria)},
  "feedback": "<brief explanation>"
}}"""


def create_evaluator(test_type: TestType, claude: ClaudeClient) -> BaseEvaluator:
    """Factory function to create appropriate evaluator"""
    config = get_config(test_type)

    evaluators = {
        TestType.EXCERPT: ExcerptEvaluator,
        TestType.TAG: TagEvaluator,
        TestType.SUMMARY: SummaryEvaluator,
    }

    evaluator_class = evaluators[test_type]
    return evaluator_class(config, claude)
