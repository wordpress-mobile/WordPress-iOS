import SwiftUI
import UIKit
import WordPressUI
import FormattableContentKit

struct ActivityFormattableContentView: UIViewRepresentable {
    let formattableActivity: FormattableActivity
    let blog: Blog

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.linkTextAttributes = [
            .foregroundColor: UIAppColor.primary
        ]
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        let styles = ActivityContentStyles()
        let formattedContent = formattableActivity.formattedContent(using: styles)
        textView.attributedText = formattedContent

        // Force layout to update intrinsic content size
        textView.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }

        // Calculate the size that fits within the proposed width
        let targetSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let size = uiView.sizeThatFits(targetSize)

        return CGSize(width: width, height: size.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(formattableActivity: formattableActivity, blog: blog)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        let formattableActivity: FormattableActivity
        let blog: Blog

        init(formattableActivity: FormattableActivity, blog: Blog) {
            self.formattableActivity = formattableActivity
            self.blog = blog
            super.init()
        }

        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            guard interaction == .invokeDefaultAction else {
                return false
            }

            // Get the top view controller to create content coordinator
            guard let viewController = UIViewController.topViewController else {
                return false
            }

            let contentCoordinator = DefaultContentCoordinator(
                controller: viewController,
                context: ContextManager.shared.mainContext
            )

            let router = ActivityContentRouter(
                activity: formattableActivity,
                coordinator: contentCoordinator
            )

            router.routeTo(URL)

            return false
        }
    }
}
