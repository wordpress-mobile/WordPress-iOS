#!/usr/bin/env python3
"""
Configuration for evaluation pipeline
Test types, scoring weights, and thresholds
"""

from dataclasses import dataclass
from typing import Dict, List, Tuple
from enum import Enum


class TestType(str, Enum):
    EXCERPT = "excerpt-generation"
    TAG = "tag-suggestion"
    SUMMARY = "post-summary"


@dataclass
class EvaluationCriteria:
    """Scoring criteria with weights"""
    name: str
    weight: float
    critical_threshold: float = 0.0  # If > 0, score below this = auto-fail
    description: str = ""


@dataclass
class TestTypeConfig:
    """Configuration for a test type"""
    test_class: str
    marker_prefix: str
    icon: str
    name: str
    criteria: List[EvaluationCriteria]
    pass_threshold: float
    needs_improvement_threshold: float
    total_weight: float
    diversity_check: bool = False


# Excerpt Generation Configuration
EXCERPT_CRITERIA = [
    EvaluationCriteria("languageMatch", 3.0, 8.0, "Is excerpt in the correct language?"),
    EvaluationCriteria("grammar", 2.0, 6.0, "Grammatical correctness and fluency"),
    EvaluationCriteria("relevance", 2.0, 0.0, "Captures main message of original?"),
    EvaluationCriteria("hookQuality", 1.5, 0.0, "Entices reader to continue?"),
    EvaluationCriteria("keyInformationPreservation", 1.5, 0.0, "Preserves critical facts?"),
    EvaluationCriteria("standalone", 1.0, 0.0, "Makes sense without context?"),
    EvaluationCriteria("engagement", 1.0, 0.0, "Maintains reader interest?"),
]

# Tag Suggestion Configuration
TAG_CRITERIA = [
    EvaluationCriteria("relevance", 2.0, 6.0, "Tag accurately represents content?"),
    EvaluationCriteria("languageMatch", 1.5, 7.0, "Tag in correct language?"),
    EvaluationCriteria("formatConsistency", 1.5, 0.0, "Matches site tag formatting?"),
    EvaluationCriteria("seoQuality", 1.0, 0.0, "Good for search/discovery?"),
    EvaluationCriteria("uniqueness", 1.0, 0.0, "Not duplicating existing tags?"),
    EvaluationCriteria("specificity", 1.0, 0.0, "Specific vs generic?"),
]

# Summary Generation Configuration
SUMMARY_CRITERIA = [
    EvaluationCriteria("conciseness", 2.0, 6.0, "Is the summary concise and to the point?"),
    EvaluationCriteria("accuracy", 2.0, 6.0, "Does it accurately represent the main points?"),
    EvaluationCriteria("languageMatch", 1.5, 7.0, "Is summary in correct language?"),
    EvaluationCriteria("clarity", 1.5, 0.0, "Is the summary clear and easy to understand?"),
    EvaluationCriteria("completeness", 1.0, 0.0, "Captures all major topics/themes?"),
    EvaluationCriteria("neutralTone", 1.0, 0.0, "Maintains objective, neutral tone?"),
    EvaluationCriteria("coherence", 1.0, 0.0, "Flows logically and makes sense?"),
]

# Test Type Configurations
TEST_CONFIGS: Dict[TestType, TestTypeConfig] = {
    TestType.EXCERPT: TestTypeConfig(
        test_class="PostExcerptGeneratorTests",
        marker_prefix="EXCERPT_OUTPUT",
        icon="🖥️",
        name="Excerpt Generation",
        criteria=EXCERPT_CRITERIA,
        pass_threshold=7.0,
        needs_improvement_threshold=6.0,
        total_weight=12.0,  # Updated: removed lengthAppropriate (1.0) and styleMatch (1.0)
        diversity_check=True,
    ),
    TestType.TAG: TestTypeConfig(
        test_class="TagSuggestionGeneratorTests",
        marker_prefix="TAG_OUTPUT",
        icon="🏷️",
        name="Tag Suggestion",
        criteria=TAG_CRITERIA,
        pass_threshold=7.5,
        needs_improvement_threshold=6.5,
        total_weight=7.5,
        diversity_check=False,
    ),
    TestType.SUMMARY: TestTypeConfig(
        test_class="PostSummaryGeneratorTests",
        marker_prefix="SUMMARY_OUTPUT",
        icon="📝",
        name="Post Summary",
        criteria=SUMMARY_CRITERIA,
        pass_threshold=7.5,
        needs_improvement_threshold=6.5,
        total_weight=10.0,
        diversity_check=False,
    ),
}


def get_config(test_type: TestType) -> TestTypeConfig:
    """Get configuration for test type"""
    return TEST_CONFIGS[test_type]


def detect_test_type(test_type_str: str) -> TestType:
    """Detect test type from JSON testType field"""
    mapping = {
        "excerpt-generation": TestType.EXCERPT,
        "tag-suggestion": TestType.TAG,
        "post-summary": TestType.SUMMARY,
    }
    return mapping.get(test_type_str, TestType.EXCERPT)
