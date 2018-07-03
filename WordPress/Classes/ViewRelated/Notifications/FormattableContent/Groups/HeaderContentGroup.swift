
class HeaderContentGroup: FormattableContentGroup {
    class func createGroup(from header: [[String: AnyObject]], parent: FormattableContentParent) -> FormattableContentGroup {
        let blocks = NotificationContentFactory.content(from: header, actionsParser: NotificationActionParser(), parent: parent)
        return FormattableContentGroup(blocks: blocks)
    }
}
