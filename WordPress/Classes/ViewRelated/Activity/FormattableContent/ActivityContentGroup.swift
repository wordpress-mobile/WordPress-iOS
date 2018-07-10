
class ActivityContentGroup: FormattableContentGroup {
    class func create(with subject: [[String: AnyObject]], parent: FormattableContentParent) -> FormattableContentGroup {
        let blocks = ActivityFormattableContentFactory.content(from: subject, actionsParser: ActivityActionsParser(), parent: parent)
        return FormattableContentGroup(blocks: blocks, kind: .activity)
    }
}

extension FormattableContentGroup.Kind {
    static let activity = FormattableContentGroup.Kind("activity")
}
