
class SubjectContentGroup: FormattableContentGroup {
    class func createGroup(from subject: [[String: AnyObject]], parent: FormattableContentParent) -> FormattableContentGroup {
        let blocks = FormattableContent.blocksFromArray(subject, actionsParser: NotificationActionParser(), parent: parent)
        return FormattableContentGroup(blocks: blocks)
    }
}
