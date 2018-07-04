
class FormattableCommentContent: NotificationTextContent {

    var metaCommentID: NSNumber? {
        return metaIds?[Constants.MetaKeys.Comment] as? NSNumber
    }

    var isCommentApproved: Bool {
        let identifier = ApproveComment.actionIdentifier()
        return isActionOn(id: identifier) || !isActionEnabled(id: identifier)
    }

    override var kind: FormattableContentKind {
        return .comment
    }

    private var metaIds: [String: AnyObject]? {
        return meta?[Constants.MetaKeys.Ids] as? [String: AnyObject]
    }

    func formattableContentRangeWithCommentId(_ commentID: NSNumber) -> FormattableContentRange? {
        for range in ranges {
            if let rangeCommentID = range.commentID, rangeCommentID.isEqual(commentID) {
                return range
            }
        }

        return nil
    }
}

extension FormattableCommentContent: Equatable {
    static func == (lhs: FormattableCommentContent, rhs: FormattableCommentContent) -> Bool {
        if lhs.parent == nil && rhs.parent == nil {
            return lhs.isEqual(to: rhs)
        }
        guard let lhsParent = lhs.parent, let rhsParent = rhs.parent else {
            return false
        }
        return lhs.isEqual(to: rhs) && lhsParent.isEqual(to: rhsParent)
    }

    private func isEqual(to other: FormattableTextContent) -> Bool {
        return text == other.text &&
            ranges.count == other.ranges.count
    }
}

extension FormattableCommentContent: ActionableObject {
    var notificationID: String? {
        return parent?.uniqueID
    }

    var metaSiteID: NSNumber? {
        return metaIds?[Constants.MetaKeys.Site] as? NSNumber
    }
}

private enum Constants {
    fileprivate enum MetaKeys {
        static let Ids          = "ids"
        static let Site         = "site"
        static let Comment      = "comment"
    }
}
