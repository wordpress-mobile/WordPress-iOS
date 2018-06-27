
class HeaderContentGroup: FormattableContentGroup {
    class func createGroup(from header: [[String: AnyObject]], parent: FormattableContentParent) -> FormattableContentGroup {
        let blocks = FormattableContent.blocksFromArray(header, parent: parent)
        return FormattableContentGroup(blocks: blocks)
    }
}
