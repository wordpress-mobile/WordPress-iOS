import FormattableContentKit
import WordPressData

extension HeaderContentGroup {
    class func createGroup(from header: [[String: AnyObject]], parent: WordPressData.Notification) -> FormattableContentGroup {
        let blocks = NotificationContentFactory.content(from: header, actionsParser: NotificationActionParser(), parent: parent)
        return FormattableContentGroup(blocks: blocks, kind: .header)
    }
}
