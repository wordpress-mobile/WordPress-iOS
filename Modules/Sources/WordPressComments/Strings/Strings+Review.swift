import Foundation

extension Strings {
    enum Review {
        static let review = NSLocalizedString(
            "comments.review.button",
            value: "Review",
            comment: "Button to review loaded pending comments"
        )
        static let reviewAccessibility = NSLocalizedString(
            "comments.review.accessibility",
            value: "Review pending comments",
            comment: "Accessibility label for the Review button"
        )
        static let title = NSLocalizedString(
            "comments.review.title",
            value: "Review Pending",
            comment: "Pending comment review screen title"
        )
        static let position = NSLocalizedString(
            "comments.review.position",
            value: "%1$d of %2$d",
            comment: "Review position. %1$d is the one-based position; %2$d is the fixed batch size"
        )
        static let skip = NSLocalizedString(
            "comments.review.skip",
            value: "Skip",
            comment: "Leave this comment pending and advance"
        )
        static let complete = NSLocalizedString(
            "comments.review.complete",
            value: "Review complete",
            comment: "Heading after all captured comments have been reviewed"
        )
        private static let none = NSLocalizedString(
            "comments.review.none",
            value: "No comments moderated in this session.",
            comment: "Result when all captured comments were already handled or missing"
        )
        private static let moderatedOne = NSLocalizedString(
            "comments.review.moderated.one",
            value: "%1$d comment moderated.",
            comment: "Review result for one confirmed moderation; %1$d is the count"
        )
        private static let moderatedMany = NSLocalizedString(
            "comments.review.moderated.many",
            value: "%1$d comments moderated.",
            comment: "Review result for multiple confirmed moderations; %1$d is the count"
        )
        private static let skippedOne = NSLocalizedString(
            "comments.review.skipped.one",
            value: "%1$d comment skipped.",
            comment: "Review result when only one comment was skipped; %1$d is the count"
        )
        private static let skippedMany = NSLocalizedString(
            "comments.review.skipped.many",
            value: "%1$d comments skipped.",
            comment: "Review result when only comments were skipped; %1$d is the count"
        )
        private static let skippedClause = NSLocalizedString(
            "comments.review.skipped.clause",
            value: "%1$d skipped.",
            comment: "Skipped count following a moderated count; %1$d is the count"
        )
        private static let both = NSLocalizedString(
            "comments.review.summary.both",
            value: "%1$@ %2$@",
            comment: "Combined review result; %1$@ is the moderated sentence, %2$@ is the skipped sentence"
        )

        static func summary(moderated: Int, skipped: Int) -> String {
            guard moderated > 0 else {
                if skipped > 0 {
                    return String.localizedStringWithFormat(skipped == 1 ? skippedOne : skippedMany, skipped)
                }
                return none
            }
            let moderatedText = String.localizedStringWithFormat(
                moderated == 1 ? moderatedOne : moderatedMany,
                moderated
            )
            guard skipped > 0 else { return moderatedText }
            return String.localizedStringWithFormat(
                both,
                moderatedText,
                String.localizedStringWithFormat(skippedClause, skipped)
            )
        }
    }
}
