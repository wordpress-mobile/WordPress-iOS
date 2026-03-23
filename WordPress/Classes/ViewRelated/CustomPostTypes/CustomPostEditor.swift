import SwiftUI
import SVProgressHUD
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal

struct CustomPostEditor: View {
    let wpService: WpService
    let client: WordPressClient
    let post: AnyPostWithEditContext?
    let details: PostTypeDetailsWithEditContext
    let blog: Blog
    let initialParams: PostCreateParams?

    var body: some View {
        ViewControllerWrapper(
            wpService: wpService,
            client: client,
            post: post,
            details: details,
            blog: blog,
            initialParams: initialParams
        )
        .ignoresSafeArea()
    }
}

private struct ViewControllerWrapper: UIViewControllerRepresentable {
    let wpService: WpService
    let client: WordPressClient
    let post: AnyPostWithEditContext?
    let details: PostTypeDetailsWithEditContext
    let blog: Blog
    let initialParams: PostCreateParams?

    @Environment(\.dismiss)
    var dismiss: DismissAction

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = CustomPostEditorViewController(
            blog: blog,
            wpService: wpService,
            client: client,
            post: post,
            details: details,
            initialParams: initialParams
        ) {
            dismiss()
        }
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
