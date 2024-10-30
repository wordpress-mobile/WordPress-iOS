import UIKit

extension UITextView {
    /// Creates a text view that behaves like a non-editable multiline label
    /// but supports interaction and other text view features.
    public static func makeLabel() -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }
}
