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
