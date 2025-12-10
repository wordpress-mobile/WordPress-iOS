import Foundation
import WordPressShared

@objc extension BasePost {

    public func titleForDisplay() -> String {
        let title = postTitle?.trimmingCharacters(in: .whitespaces)
        guard let title, !title.isEmpty else {
            return NSLocalizedString("(no title)", comment: "Placeholder text for missing post title")
        }
        return title.stringByDecodingXMLCharacters()
    }

    public func contentForDisplay() -> String? {
        return content
    }

}
