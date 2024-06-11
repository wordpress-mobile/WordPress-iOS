import SwiftUI

struct CommentModerationReplyTextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            isFirstResponder: $isFirstResponder
        )
    }

    func makeUIView(context: Context) -> SelfSizingTextView {
        return context.coordinator.textView
    }

    func updateUIView(_ uiView: SelfSizingTextView, context: Context) {
        // Update text
        uiView.text = text
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()

        // Become or resign first responder
        DispatchQueue.main.async {
            if uiView.isFirstResponder != isFirstResponder {
                _ = isFirstResponder ? uiView.becomeFirstResponder() : uiView.resignFirstResponder()
            }
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let text: Binding<String>
        private let isFirstResponder: Binding<Bool>

        init(text: Binding<String>, isFirstResponder: Binding<Bool>) {
            self.text = text
            self.isFirstResponder = isFirstResponder
        }

        private(set) lazy var textView: SelfSizingTextView = {
            let view = SelfSizingTextView()
            view.translatesAutoresizingMaskIntoConstraints = true
            view.scrollsToTop = false
            view.contentInset = .zero
            view.textContainerInset = Style.textContainerInset
            view.autocorrectionType = .yes
            view.textColor = Style.textColor
            view.font = Style.font
            view.textContainer.lineFragmentPadding = 0
            view.layoutManager.allowsNonContiguousLayout = false
            view.accessibilityIdentifier = "reply-text-view"
            view.delegate = self
            return view
        }()

        func textViewDidChange(_ textView: UITextView) {
            self.text.wrappedValue = textView.text
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            self.updateIsFirstResponder(textView: textView)
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            self.updateIsFirstResponder(textView: textView)
        }

        private func updateIsFirstResponder(textView: UITextView) {
            if self.isFirstResponder.wrappedValue != textView.isFirstResponder {
                self.isFirstResponder.wrappedValue = textView.isFirstResponder
            }
        }
    }

    class SelfSizingTextView: UITextView {
        open override func sizeToFit() {
            super.sizeToFit()
            self.invalidateIntrinsicContentSize()
        }

        open override var intrinsicContentSize: CGSize {
            return .init(width: UIView.noIntrinsicMetric, height: contentSize.height)
        }

        override func layoutSubviews() {
            self.invalidateIntrinsicContentSize()
            super.layoutSubviews()
        }
    }

    private struct Style {
        static let font = UIFont.DS.font(.bodyLarge(.regular))
        static let textColor = UIColor.DS.Foreground.primary
        static let placeholderTextColor = UIColor.DS.Foreground.secondary
        static let textContainerInset = UIEdgeInsets.zero
    }
}
