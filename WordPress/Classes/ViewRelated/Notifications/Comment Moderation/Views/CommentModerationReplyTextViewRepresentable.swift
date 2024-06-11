import SwiftUI

struct CommentModerationReplyTextViewRepresentable: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> SelfSizingTextView {
        let view = SelfSizingTextView()
        view.text = text
        view.translatesAutoresizingMaskIntoConstraints = true
        view.scrollsToTop = false
        view.contentInset = .zero
        view.textContainerInset = .init(top: 8, left: 16, bottom: 8, right: 16)
        view.autocorrectionType = .yes
        view.textColor = Style.textColor
        view.font = Style.font
        view.textContainer.lineFragmentPadding = 0
        view.layoutManager.allowsNonContiguousLayout = false
        view.accessibilityIdentifier = "reply-text-view"
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: SelfSizingTextView, context: Context) {
        uiView.text = text
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: CommentModerationReplyTextViewRepresentable

        init(_ parent: CommentModerationReplyTextViewRepresentable) {
            self.parent = parent
            super.init()
        }

        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }
    }

    typealias UIViewType = SelfSizingTextView

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
        static let font = UIFont.DS.font(.bodyMedium(.regular))
        static let textColor = UIColor.DS.Foreground.primary
        static let placeholderTextColor = UIColor.DS.Foreground.secondary
    }
}
