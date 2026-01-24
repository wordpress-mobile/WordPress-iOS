import Foundation
import UIKit
import WebKit
import GutenbergKit
import WordPressShared
import WordPressUI

class PostGBKEditorViewController: UIViewController, GutenbergKit.EditorViewControllerDelegate, PostEditorNavigationBarManagerDelegate {

    let blog: Blog
    let navigationBarManager: PostEditorNavigationBarManager

    /* private */ let editorViewController: GutenbergKit.EditorViewController
    private let status: String // TODO: Can be deleted?

    private var isModalDialogOpen = false

    private var keyboardShowObserver: Any?
    private var keyboardHideObserver: Any?
    private var keyboardFrame = CGRect.zero

    private var suggestionViewBottomConstraint: NSLayoutConstraint?
    private var currentSuggestionsController: GutenbergSuggestionsViewController?

    init(
        postId: Int?,
        postType: String,
        title: String?,
        content: String?,
        status: String?,
        blog: Blog
    ) {
        self.status = status ?? "draft"
        self.blog = blog
        self.navigationBarManager = PostEditorNavigationBarManager()

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
        let cachedDependencies = EditorDependencyManager.shared.dependencies(for: blog)

        self.editorViewController = GutenbergKit.EditorViewController(
            configuration: editorConfiguration,
            dependencies: cachedDependencies,
            mediaPicker: MediaPickerController(blog: blog)
        )

        super.init(nibName: nil, bundle: nil)

        self.editorViewController.delegate = self
        self.navigationBarManager.delegate = self
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

        setupKeyboardObservers()
        setupEditorView()
        configureNavigationBar()
        refreshInterface()

        // Load auth cookies if needed (for private sites)
        Task {
            await loadAuthenticationCookiesAsync()
        }

        SiteSuggestionService.shared.prefetchSuggestionsIfNeeded(for: blog) {
            // Do nothing
        }
    }

    func refreshInterface() {
        navigationBarManager.reloadPublishButton()
        navigationItem.rightBarButtonItems = self.status == "trash" ? [] : navigationBarManager.rightBarButtonItems
    }

    func makeMoreMenu() -> UIMenu {
        fatalError("To be implemented by subclasses")
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
        gutenbergDidRequestToggleRedoButton(!state.hasRedo)
        gutenbergDidRequestToggleUndoButton(!state.hasUndo)
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateFeaturedImage mediaID: Int) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didLogException exception: GutenbergKit.GutenbergJSException) {
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
        isModalDialogOpen = true
        setNavigationItemsEnabled(false)
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didCloseModalDialog dialogType: String) {
        isModalDialogOpen = false
        setNavigationItemsEnabled(true)
    }

    func editorDidRequestLatestContent(_ controller: GutenbergKit.EditorViewController) -> (title: String, content: String)? {
        // Do nothing
        return nil
    }

    // MARK: - PostEditorNavigationBarManagerDelegate

    var publishButtonText: String {
        wpAssertionFailure("To be implemented by subclasses")
        return ""
    }

    var isPublishButtonEnabled: Bool {
        wpAssertionFailure("To be implemented by subclasses")
        return false
    }

    var uploadingButtonSize: CGSize {
        wpAssertionFailure("To be implemented by subclasses")
        return .zero
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton) {
        // Do nothing
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, undoWasPressed sender: UIButton) {
        editorViewController.undo()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, redoWasPressed sender: UIButton) {
        editorViewController.redo()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {
        // Do nothing
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        // Do nothing
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {
        // Do nothing
    }
}

private extension PostGBKEditorViewController {
    func gutenbergDidRequestToggleRedoButton(_ isDisabled: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.navigationBarManager.redoButton.isUserInteractionEnabled = isDisabled ? false : true
                self.navigationBarManager.redoButton.alpha = isDisabled ? 0.3 : 1.0
            }
        }
    }

    func gutenbergDidRequestToggleUndoButton(_ isDisabled: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.navigationBarManager.undoButton.isUserInteractionEnabled = isDisabled ? false : true
                self.navigationBarManager.undoButton.alpha = isDisabled ? 0.3 : 1.0
            }
        }
    }

    func setNavigationItemsEnabled(_ enabled: Bool) {
        navigationBarManager.closeButton.isEnabled = enabled
        navigationBarManager.moreButton.isEnabled = enabled
        navigationBarManager.publishButton.isEnabled = enabled
        navigationBarManager.undoButton.isEnabled = enabled
        navigationBarManager.redoButton.isEnabled = enabled
    }

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

    func configureNavigationBar() {
        navigationController?.navigationBar.accessibilityIdentifier = "Gutenberg Editor Navigation Bar"
        navigationItem.leftBarButtonItems = navigationBarManager.leftBarButtonItems

        edgesForExtendedLayout = []
        // TODO: make it work
//        configureDefaultNavigationBarAppearance()

        navigationBarManager.moreButton.menu = makeMoreMenu()
        navigationBarManager.moreButton.showsMenuAsPrimaryAction = true
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
