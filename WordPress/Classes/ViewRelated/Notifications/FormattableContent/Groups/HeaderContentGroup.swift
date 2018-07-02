
class HeaderContentGroup: FormattableContentGroup {
    class func createGroup(from header: [[String: AnyObject]], parent: FormattableContentParent) -> FormattableContentGroup {
        let blocks = DefaultFormattableContent.blocksFromArray(header, actionsParser: NotificationActionParser(), parent: parent)
        return FormattableContentGroup(blocks: blocks)
    }
}
