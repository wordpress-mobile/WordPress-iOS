import SwiftUI
import SVProgressHUD
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal

struct CustomPostEditor: View {
    let client: WordPressClient
    let post: AnyPostWithEditContext
    let details: PostTypeDetailsWithEditContext
    let blog: Blog

    var body: some View {
        ViewControllerWrapper(client: client, post: post, details: details, blog: blog)
            .ignoresSafeArea()
    }
}

private struct ViewControllerWrapper: UIViewControllerRepresentable {
    let client: WordPressClient
    let post: AnyPostWithEditContext
    let details: PostTypeDetailsWithEditContext
    let blog: Blog

    @Environment(\.dismiss)
    var dismiss: DismissAction

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = CustomPostEditorViewController(blog: blog, client: client, post: post, details: details) {
            dismiss()
        }
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
