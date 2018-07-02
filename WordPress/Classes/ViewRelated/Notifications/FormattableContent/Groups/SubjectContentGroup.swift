
class SubjectContentGroup: FormattableContentGroup {
    class func createGroup(from subject: [[String: AnyObject]], parent: FormattableContentParent) -> FormattableContentGroup {
        let blocks = DefaultFormattableContent.blocksFromArray(subject, actionsParser: NotificationActionParser(), parent: parent)
        return FormattableContentGroup(blocks: blocks)
    }
}
