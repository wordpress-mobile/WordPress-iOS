
class HeaderContentGroup: FormattableContentGroup {
    class func createGroup(from header: [[String: AnyObject]], parent: FormattableContentParent) -> FormattableContentGroup {
//        let parser = NotificationActionParser()
//        let actions = parser.parse(header)
        let blocks = FormattableContent.blocksFromArray(header, actions: [], parent: parent)
        return FormattableContentGroup(blocks: blocks)
    }
}
