
class ActivityContentGroup: FormattableContentGroup {
    class func create(with subject: [[String: AnyObject]]) -> FormattableContentGroup {
        let blocks = ActivityContentFactory.content(from: subject, actionsParser: ActivityActionsParser())
        return FormattableContentGroup(blocks: blocks, kind: .activity)
    }
}

extension FormattableContentGroup.Kind {
    static let activity = FormattableContentGroup.Kind("activity")
}
