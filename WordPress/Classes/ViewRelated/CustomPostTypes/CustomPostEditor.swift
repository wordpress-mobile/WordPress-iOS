import SwiftUI
import SVProgressHUD
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal

struct CustomPostEditor: UIViewControllerRepresentable {
    let client: WordPressClient
    let post: AnyPostWithEditContext
    let details: PostTypeDetailsWithEditContext
    let blog: Blog
    let success: () -> Void

    @Environment(\.dismiss)
    var dismiss: DismissAction

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = CustomPostEditorViewController(blog: blog, client: client, post: post, details: details) {
            dismiss()
            success()
        }
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
