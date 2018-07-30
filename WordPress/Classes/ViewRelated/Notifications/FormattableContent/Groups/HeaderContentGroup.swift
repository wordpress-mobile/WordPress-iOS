
class HeaderContentGroup: FormattableContentGroup {
    class func createGroup(from header: [[String: AnyObject]], parent: Notification) -> FormattableContentGroup {
        let blocks = NotificationContentFactory.content(from: header, actionsParser: NotificationActionParser(), parent: parent)
        return FormattableContentGroup(blocks: blocks, kind: .header)
    }
}
