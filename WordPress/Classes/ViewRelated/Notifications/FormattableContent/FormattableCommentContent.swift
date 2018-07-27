
class FormattableCommentContent: NotificationTextContent {

    var metaCommentID: NSNumber? {
        return metaIds?[Constants.MetaKeys.Comment] as? NSNumber
    }

    var isCommentApproved: Bool {
        let identifier = ApproveCommentAction.actionIdentifier()
        return isActionOn(id: identifier) || !isActionEnabled(id: identifier)
    }

    override var kind: FormattableContentKind {
        return .comment
    }

    private var metaIds: [String: AnyObject]? {
        return meta?[Constants.MetaKeys.Ids] as? [String: AnyObject]
    }
}

extension FormattableCommentContent: Equatable {
    static func == (lhs: FormattableCommentContent, rhs: FormattableCommentContent) -> Bool {
        return lhs.isEqual(to: rhs) && lhs.parent.isEqual(to: rhs.parent)
    }

    private func isEqual(to other: FormattableTextContent) -> Bool {
        return text == other.text &&
            ranges.count == other.ranges.count
    }
}

extension FormattableCommentContent: ActionableObject {
    var notificationID: String? {
        return parent.uniqueID
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
