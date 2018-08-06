
class SubjectContentGroup: FormattableContentGroup {
    class func createGroup(from subject: [[String: AnyObject]], parent: Notification) -> FormattableContentGroup {
        let blocks = NotificationContentFactory.content(from: subject, actionsParser: NotificationActionParser(), parent: parent)
        return FormattableContentGroup(blocks: blocks, kind: .subject)
    }
}
