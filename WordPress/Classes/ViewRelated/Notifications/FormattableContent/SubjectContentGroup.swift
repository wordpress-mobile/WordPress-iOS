
import Foundation

class SubjectContentGroup: FormattableContentGroup {
    class func createGroup(from subject: [[String: AnyObject]], parent: FormattableContentParent) -> FormattableContentGroup {
        let blocks = FormattableContent.blocksFromArray(subject, actions: [], parent: parent)
        return FormattableContentGroup(blocks: blocks)
    }
}
