import Foundation

class FooterTextContent: FormattableTextContent {
    override init(text: String, ranges: [FormattableContentRange], actions: [FormattableContentAction]?) {
        if text == "You replied to this comment." {
            let localizedText = NSLocalizedString(text, comment: "Notification text - below a comment notification detail")

            // FIXME: Now that we have localized the text, the clickable link range for NSAttributedString will be wrong.
            super.init(text: localizedText, ranges: ranges, actions: actions)
        } else {
            super.init(text: text, ranges: ranges, actions: actions)
        }
    }
}
