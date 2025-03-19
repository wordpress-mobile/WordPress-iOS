import Foundation

public class FormattableCommentContent: NotificationTextContent {

    public var metaCommentID: NSNumber? {
        return metaIds?[Constants.MetaKeys.Comment] as? NSNumber
    }

    public var isCommentApproved: Bool {
        let identifier = ApproveCommentAction.actionIdentifier()
        return isActionOn(id: identifier) || !isActionEnabled(id: identifier)
    }

    public override var kind: FormattableContentKind {
        return .comment
    }

    private var metaIds: [String: AnyObject]? {
        return meta?[Constants.MetaKeys.Ids] as? [String: AnyObject]
    }

    public var metaSiteID: NSNumber? {
        return metaIds?[Constants.MetaKeys.Site] as? NSNumber
    }

    public var notificationID: String? {
        return parent.notificationIdentifier
    }
}

extension FormattableCommentContent: Equatable {
    public static func == (lhs: FormattableCommentContent, rhs: FormattableCommentContent) -> Bool {
        return lhs.isEqual(to: rhs) &&
            lhs.parent.notificationIdentifier == rhs.parent.notificationIdentifier
    }

    private func isEqual(to other: FormattableTextContent) -> Bool {
        return text == other.text &&
            ranges.count == other.ranges.count
    }
}

private enum Constants {
    fileprivate enum MetaKeys {
        static let Ids = "ids"
        static let Site = "site"
        static let Comment = "comment"
    }
}
