import Foundation
import UIKit
import WebKit
import SafariServices
import GutenbergKit
import WordPressShared
import WordPressUI

class PostGBKEditorViewController: UIViewController, GutenbergKit.EditorViewControllerDelegate {

    let blog: Blog

    /* private */ let editorViewController: GutenbergKit.EditorViewController
    private let status: String // TODO: Can be deleted?

    private var keyboardShowObserver: Any?
    private var keyboardHideObserver: Any?
    private var keyboardFrame = CGRect.zero

    private var suggestionViewBottomConstraint: NSLayoutConstraint?
    private var currentSuggestionsController: GutenbergSuggestionsViewController?

    init(
        postId: Int?,
        postType: PostTypeDetails,
        title: String?,
        content: String?,
        status: String?,
        blog: Blog
    ) {
        self.status = status ?? "draft"
        self.blog = blog

        EditorLocalization.localize = { $0.localized }

        // Create configuration with post content
        let editorConfiguration = EditorConfiguration(blog: blog, postType: postType)
            .toBuilder()
            .setTitle(title ?? "")
            .setContent(content ?? "")
            .setPostID(postId)
            .setPostStatus(self.status)
            .setNativeInserterEnabled(FeatureFlag.nativeBlockInserter.enabled)
            .build()

        // Use prefetched dependencies if available (fast path with spinner),
        // otherwise pass nil and GutenbergKit will fetch them (shows progress bar)
        let cachedDependencies = EditorDependencyManager.shared.dependencies(for: blog, postType: postType)

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

    deinit {
        tearDownKeyboardObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        edgesForExtendedLayout = []

        setupKeyboardObservers()
        setupEditorView()

        // Load auth cookies if needed (for private sites)
        Task {
            await loadAuthenticationCookiesAsync()
        }

        SiteSuggestionService.shared.prefetchSuggestionsIfNeeded(for: blog) {
            // Do nothing
        }
    }

    func editorModeToggle() -> UIAction {
        let title = editorViewController.isCodeEditorEnabled ? PostEditorStrings.visualEditor : PostEditorStrings.codeEditor
        let icon = editorViewController.isCodeEditorEnabled ? "doc.richtext" : "curlybraces"
        return UIAction(title: title, image: UIImage(systemName: icon)) { [weak editorViewController] _ in
            editorViewController?.isCodeEditorEnabled.toggle()
        }
    }

    func helpAction() -> UIAction {
        let helpTitle = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() ? PostEditorStrings.helpAndSupport : PostEditorStrings.help
        return UIAction(title: helpTitle, image: UIImage(systemName: "questionmark.circle")) { [weak self] _ in
            guard let url = URL(string: "https://wordpress.com/support/wordpress-editor/") else { return }
            self?.present(SFSafariViewController(url: url), animated: true)
        }
    }

    func feedbackAction() -> UIAction {
        UIAction(title: PostEditorStrings.sendFeedback, image: UIImage(systemName: "envelope")) { [weak self] _ in
            self?.present(SubmitFeedbackViewController(source: "gutenberg_kit", feedbackPrefix: "Editor"), animated: true)
        }
    }

    // MARK: - GutenbergKit.EditorViewControllerDelegate

    func editorDidLoad(_ viewContoller: GutenbergKit.EditorViewController) {
        // Do nothing
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didDisplayInitialContent content: String) {
        // Do nothing
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didEncounterCriticalError error: any Error) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateContentWithState state: GutenbergKit.EditorState) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateHistoryState state: GutenbergKit.EditorState) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateFeaturedImage mediaID: Int) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didLogException exception: GutenbergKit.GutenbergJSException) {
        DDLogError("GBK editor exception:\n\(exception)")

        DispatchQueue.main.async {
            WordPressAppDelegate.crashLogging?.logJavaScriptException(exception) {
                // Do nothing
            }
        }
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didRequestMediaFromSiteMediaLibrary config: OpenMediaLibraryAction) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didTriggerAutocompleter type: String) {
        switch type {
        case "at-symbol":
            showSuggestions(type: .mention) { [weak self] result in
                switch result {
                case .success(let suggestion):
                    // Appended space completes the autocomplete session
                    self?.editorViewController.appendTextAtCursor(suggestion + " ")
                case .failure(let error):
                    DDLogError("Mention selection cancelled or failed: \(error)")
                }
            }
        case "plus-symbol":
            showSuggestions(type: .xpost) { [weak self] result in
                switch result {
                case .success(let suggestion):
                    // Appended space completes the autocomplete session
                    self?.editorViewController.appendTextAtCursor(suggestion + " ")
                case .failure(let error):
                    DDLogError("Xpost selection cancelled or failed: \(error)")
                }
            }
        default:
            DDLogError("Unknown autocompleter type: \(type)")
        }
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didOpenModalDialog dialogType: String) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didCloseModalDialog dialogType: String) {
        // Do nothing
    }

    func editorDidRequestLatestContent(_ controller: GutenbergKit.EditorViewController) -> (title: String, content: String)? {
        // Do nothing
        return nil
    }
}

private extension PostGBKEditorViewController {

    func setupEditorView() {
        view.tintColor = UIAppColor.editorPrimary

        addChild(editorViewController)
        view.addSubview(editorViewController.view)
        view.pinSubviewToAllEdges(editorViewController.view)
        editorViewController.didMove(toParent: self)

#if DEBUG
        editorViewController.webView.isInspectable = true
#endif

        // Doesn't seem to do anything
        setContentScrollView(editorViewController.webView.scrollView)
    }

    func loadAuthenticationCookiesAsync() async -> Bool {
        guard blog.isPrivate() else {
            return true
        }

        guard let authenticator = RequestAuthenticator(blog: blog),
            let blogURL = blog.url,
            let authURL = URL(string: blogURL) else {
            return false
        }

        let cookieJar = WKWebsiteDataStore.default().httpCookieStore

        return await withCheckedContinuation { continuation in
            // Always call authenticator.request() to ensure cookies are properly loaded into WKWebView
            authenticator.request(url: authURL, cookieJar: cookieJar) { _ in
                DDLogInfo("Authentication cookies loaded into shared cookie store for GutenbergKit")
                continuation.resume(returning: true)
            }
        }
    }

    // MARK: - Keyboard Observers

    func setupKeyboardObservers() {
        keyboardShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { [weak self] (notification) in
            if let self, let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardFrame = keyboardRect
                self.updateConstraintsToAvoidKeyboard(frame: keyboardRect)
            }
        }
        keyboardHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: .main) { [weak self] (notification) in
            if let self, let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardFrame = keyboardRect
                self.updateConstraintsToAvoidKeyboard(frame: keyboardRect)
            }
        }
    }

    func tearDownKeyboardObservers() {
        if let keyboardShowObserver {
            NotificationCenter.default.removeObserver(keyboardShowObserver)
        }
        if let keyboardHideObserver {
            NotificationCenter.default.removeObserver(keyboardHideObserver)
        }
    }

    func updateConstraintsToAvoidKeyboard(frame: CGRect) {
        keyboardFrame = frame
        let minimumKeyboardHeight = CGFloat(50)
        guard let suggestionViewBottomConstraint else {
            return
        }

        // There are cases where the keyboard is not visible, but the system instead of returning zero, returns a low number, for example: 0, 3, 69.
        // So in those scenarios, we just need to take in account the safe area and ignore the keyboard all together.
        if keyboardFrame.height < minimumKeyboardHeight {
            suggestionViewBottomConstraint.constant = -self.view.safeAreaInsets.bottom
        }
        else {
            suggestionViewBottomConstraint.constant = -self.keyboardFrame.height
        }
    }

    // MARK: - Suggestions implementation

    func showSuggestions(type: SuggestionType, callback: @escaping (Swift.Result<String, NSError>) -> Void) {
        // Prevent multiple suggestions UI instances - simply ignore if already showing
        guard currentSuggestionsController == nil else {
            return
        }
        guard let siteID = blog.dotComID else {
            callback(.failure(GutenbergSuggestionsViewController.SuggestionError.notAvailable as NSError))
            return
        }

        switch type {
        case .mention:
            guard SuggestionService.shared.shouldShowSuggestions(for: blog) else { return }
        case .xpost:
            guard SiteSuggestionService.shared.shouldShowSuggestions(for: blog) else { return }
        }

        let previousFirstResponder = view.findFirstResponder()
        let suggestionsController = GutenbergSuggestionsViewController(siteID: siteID, suggestionType: type)
        currentSuggestionsController = suggestionsController
        suggestionsController.onCompletion = { [weak self] (result) in
            callback(result)

            if let self {
                // Clear the current controller reference
                self.currentSuggestionsController = nil
                self.suggestionViewBottomConstraint = nil

                // Clean up the UI (should only happen if parent still exists)
                suggestionsController.view.removeFromSuperview()
                suggestionsController.removeFromParent()

                previousFirstResponder?.becomeFirstResponder()
            }

            var analyticsName: String
            switch type {
            case .mention:
                analyticsName = "user"
            case .xpost:
                analyticsName = "xpost"
            }

            var didSelectSuggestion = false
            if case let .success(text) = result, !text.isEmpty {
                didSelectSuggestion = true
            }

            let analyticsProperties: [String: Any] = [
                "suggestion_type": analyticsName,
                "did_select_suggestion": didSelectSuggestion
            ]

            WPAnalytics.track(.gutenbergSuggestionSessionFinished, properties: analyticsProperties)
        }
        addChild(suggestionsController)
        view.addSubview(suggestionsController.view)
        let suggestionsBottomConstraint = suggestionsController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            suggestionsController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            suggestionsController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            suggestionsBottomConstraint,
            suggestionsController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        self.suggestionViewBottomConstraint = suggestionsBottomConstraint
        updateConstraintsToAvoidKeyboard(frame: keyboardFrame)
        suggestionsController.didMove(toParent: self)
    }
}
