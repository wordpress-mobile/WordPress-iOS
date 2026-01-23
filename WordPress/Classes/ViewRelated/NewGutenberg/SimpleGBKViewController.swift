import UIKit
import GutenbergKit
import CocoaLumberjackSwift
import WordPressData
import BuildSettingsKit
import WebKit
import DesignSystem

class SimpleGBKViewController: UIViewController {

    private let blog: Blog

    private var editorViewController: GutenbergKit.EditorViewController

    init(
        postID: Int,
        postTitle: String?,
        content: String,
        blog: Blog,
        postType: String?
    ) {
        self.blog = blog

        EditorLocalization.localize = { $0.localized }

        let editorConfiguration = EditorConfiguration(blog: blog, postType: postType ?? "post")
            .toBuilder()
            .setPostID(postID)
            .setTitle(postTitle ?? "")
            .setShouldHideTitle(postTitle == nil)
            .setContent(content)
            .setNativeInserterEnabled(FeatureFlag.nativeBlockInserter.enabled)
            .build()

        let cachedDependencies = EditorDependencyManager.shared.dependencies(for: blog)

        self.editorViewController = GutenbergKit.EditorViewController(
            configuration: editorConfiguration,
            dependencies: cachedDependencies,
            mediaPicker: MediaPickerController(blog: blog)
        )

        super.init(nibName: nil, bundle: nil)

        self.editorViewController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupEditorView()

        // Load auth cookies if needed (for private sites)
        Task {
            await loadAuthenticationCookiesAsync()
        }
    }

    private func setupEditorView() {
        view.tintColor = UIAppColor.editorPrimary

        addChild(editorViewController)
        view.addSubview(editorViewController.view)
        view.pinSubviewToAllEdges(editorViewController.view)
        editorViewController.didMove(toParent: self)

#if DEBUG
        editorViewController.webView.isInspectable = true
#endif
    }

    private func loadAuthenticationCookiesAsync() async {
        guard blog.isPrivate() else {
            return
        }

        guard let authenticator = RequestAuthenticator(blog: blog),
            let blogURL = blog.url,
            let authURL = URL(string: blogURL) else {
            return
        }

        let cookieJar = WKWebsiteDataStore.default().httpCookieStore

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            authenticator.request(url: authURL, cookieJar: cookieJar) { _ in
                DDLogInfo("Authentication cookies loaded into shared cookie store for GutenbergKit")
                continuation.resume()
            }
        }
    }

    func getCurrentContent() async throws -> (title: String, content: String) {
        let editorData = try await editorViewController.getTitleAndContent()
        return (editorData.title, editorData.content)
    }
}

extension SimpleGBKViewController: GutenbergKit.EditorViewControllerDelegate {
    func editorDidLoad(_ viewContoller: GutenbergKit.EditorViewController) {
        // Editor loaded successfully - no loading indicator needed with new approach
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didDisplayInitialContent content: String) {
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didEncounterCriticalError error: any Error) {
        DDLogError("Editor critical error: \(error)")
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateContentWithState state: GutenbergKit.EditorState) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateHistoryState state: GutenbergKit.EditorState) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateFeaturedImage mediaID: Int) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didLogException error: GutenbergKit.GutenbergJSException) {
        DDLogError("Gutenberg exception: \(error)")
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didLogNetworkRequest request: GutenbergKit.RecordedNetworkRequest) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didRequestMediaFromSiteMediaLibrary config: GutenbergKit.OpenMediaLibraryAction) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didTriggerAutocompleter type: String) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didOpenModalDialog dialogType: String) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didCloseModalDialog dialogType: String) {
    }

    func editorDidRequestLatestContent(_ controller: GutenbergKit.EditorViewController) -> (title: String, content: String)? {
        return nil
    }
}
