import UIKit
//import Gutenberg
//import Aztec
//import WordPressFlux
//import React
import AutomatticTracks
import Combine
import GutenbergKit

class NewGutenbergViewController: UIViewController, PostEditor, PublishingEditor {
    let errorDomain: String = "GutenbergViewController.errorDomain"

    private lazy var service: BlogJetpackSettingsService? = {
        guard
            let settings = post.blog.settings,
            let context = settings.managedObjectContext
        else {
            return nil
        }
        return BlogJetpackSettingsService(coreDataStack: ContextManager.shared)
    }()

    private lazy var coordinator: SupportCoordinator = {
        SupportCoordinator(controllerToShowFrom: topmostPresentedViewController, tag: .editorHelp)
    }()

    // MARK: - PostEditor

    var html: String {
        set {
            post.content = newValue
        }
        get {
            return post.content ?? ""
        }
    }

    var postTitle: String {
        set {
            post.postTitle = newValue
        }

        get {
            return post.postTitle ?? ""
        }
    }

    var entryPoint: PostEditorEntryPoint = .unknown {
        didSet {
            editorSession.entryPoint = entryPoint
        }
    }

    /// Maintainer of state for editor - like for post button
    ///
    private(set) lazy var postEditorStateContext: PostEditorStateContext = {
        return PostEditorStateContext(post: post, delegate: self)
    }()

    var verificationPromptHelper: VerificationPromptHelper?

    var analyticsEditorSource: String {
        return Analytics.editorSource
    }

    var editorSession: PostEditorAnalyticsSession

    var onClose: ((Bool) -> Void)?

    var postIsReblogged: Bool = false

    var isEditorClosing: Bool = false

    // MARK: - Editor Media actions

    // TODO: reimplement
    var isUploadingMedia: Bool {
        return false
    }

    // MARK: - Set content

    // TODO: reimplement
    func setTitle(_ title: String) {
//        guard gutenberg.isLoaded else {
//            return
//        }
//
//        gutenberg.setTitle(title)
    }

    // TODO: reimplement
    func setHTML(_ html: String) {
//        guard gutenberg.isLoaded else {
//            return
//        }

        self.html = html

        // Avoid sending the HTML back to the editor if it's closing.
        // Otherwise, it will cause the editor to recreate all blocks.
//        if !isEditorClosing {
//            gutenberg.updateHtml(html)
//        }
    }

    func getHTML() -> String {
        return html
    }

    var post: AbstractPost {
        didSet {
            postEditorStateContext = PostEditorStateContext(post: post, delegate: self)
            refreshInterface()
        }
    }

    let navigationBarManager: PostEditorNavigationBarManager

    var wordCount: UInt {
        0
//        guard let currentMetrics = contentInfo else {
//            return 0
//        }

//        return UInt(currentMetrics.wordCount)
    }

    // MARK: - Private variables

    private(set) var mode: EditMode = .richText
    private var analyticsEditor: PostEditorAnalyticsSession.Editor {
        switch mode {
        case .richText:
            return .gutenberg
        case .html:
            return .html
        }
    }
    private var isFirstGutenbergLayout = true
    var shouldPresentInformativeDialog = false

    // TODO: reimplemet
//    internal private(set) var contentInfo: ContentInfo?
    lazy var editorSettingsService: BlockEditorSettingsService? = {
        BlockEditorSettingsService(blog: post.blog, coreDataStack: ContextManager.sharedInstance())
    }()

    private var cancellables: [AnyCancellable] = []

    // MARK: - GutenbergKit

    private let editorViewController: GutenbergEditorViewController
    private weak var autosaveTimer: Timer?

    // TODO: remove (unused)
    var autosaver = Autosaver(action: {})
    func prepopulateMediaItems(_ media: [Media]) {}
    var debouncer = WordPressShared.Debouncer(delay: 10)
    var replaceEditor: (EditorViewController, EditorViewController) -> ()

    // MARK: - Initializers
    required convenience init(
        post: AbstractPost,
        replaceEditor: @escaping ReplaceEditorCallback,
        editorSession: PostEditorAnalyticsSession?
    ) {
        self.init(
            post: post,
            replaceEditor: replaceEditor,
            editorSession: editorSession,
            // Notice this parameter.
            // The value is the default set in the required init but we need to set it explicitly,
            // otherwise we'd trigger and infinite loop on this init.
            //
            // The reason we need this init at all even though the other one does the same job is
            // to conform to the PostEditor protocol.
            navigationBarManager: nil
        )
    }

    required init(
        post: AbstractPost,
        replaceEditor: @escaping ReplaceEditorCallback,
        editorSession: PostEditorAnalyticsSession? = nil,
        navigationBarManager: PostEditorNavigationBarManager? = nil
    ) {

        self.post = post

        self.replaceEditor = replaceEditor
        self.editorSession = PostEditorAnalyticsSession(editor: .gutenberg, post: post)
        self.navigationBarManager = navigationBarManager ?? PostEditorNavigationBarManager()
        self.editorViewController = GutenbergEditorViewController(content: post.content ?? "")

        super.init(nibName: nil, bundle: nil)

        self.navigationBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        tearDownKeyboardObservers()
        autosaveTimer?.invalidate()
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupKeyboardObservers()
        createRevisionOfPost(loadAutosaveRevision: false)
        setupEditorView()
        configureNavigationBar()
        refreshInterface()

        fetchBlockSettings()

        // TODO: reimplement
//        service?.syncJetpackSettingsForBlog(post.blog, success: { [weak self] in
////            self?.gutenberg.updateCapabilities()
//        }, failure: { (error) in
//            DDLogError("Error syncing JETPACK: \(String(describing: error))")
//        })

        autosaveTimer = .scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.performAutoSave()
        }

        onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Handles refreshing controls with state context after options screen is dismissed
        editorContentWasUpdated()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Required to work around an issue present in iOS 14 beta 2
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/14460
        if presentedViewController?.view.accessibilityIdentifier == MoreSheetAlert.accessibilityIdentifier {
            dismiss(animated: true)
        }
    }

    private func setupEditorView() {
        view.tintColor = .editorPrimary

        addChild(editorViewController)
        view.addSubview(editorViewController.view)
        view.pinSubviewToAllEdges(editorViewController.view)
        editorViewController.didMove(toParent: self)
    }

    // MARK: - Functions

    private var keyboardShowObserver: Any?
    private var keyboardHideObserver: Any?
    private var keyboardFrame = CGRect.zero
    private var suggestionViewBottomConstraint: NSLayoutConstraint?
    private var previousFirstResponder: UIView?

    private func setupKeyboardObservers() {
        keyboardShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { [weak self] (notification) in
            if let self = self, let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardFrame = keyboardRect
                self.updateConstraintsToAvoidKeyboard(frame: keyboardRect)
            }
        }
        keyboardHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { [weak self] (notification) in
            if let self = self, let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardFrame = keyboardRect
                self.updateConstraintsToAvoidKeyboard(frame: keyboardRect)
            }
        }
    }

    private func tearDownKeyboardObservers() {
        if let keyboardShowObserver = keyboardShowObserver {
            NotificationCenter.default.removeObserver(keyboardShowObserver)
        }
        if let keyboardHideObserver = keyboardHideObserver {
            NotificationCenter.default.removeObserver(keyboardHideObserver)
        }
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.accessibilityIdentifier = "Gutenberg Editor Navigation Bar"
        navigationItem.leftBarButtonItems = navigationBarManager.leftBarButtonItems

        // Add bottom border line
        let screenScale = UIScreen.main.scale
        let borderWidth: CGFloat = 1.0 / screenScale
        let borderColor = UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.36).cgColor

        let borderBottom = UIView()
        borderBottom.backgroundColor = UIColor(cgColor: borderColor)
        borderBottom.frame = CGRect(x: 0, y: navigationController?.navigationBar.frame.size.height ?? 0 - borderWidth, width: navigationController?.navigationBar.frame.size.width ?? 0, height: borderWidth)
        borderBottom.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        navigationController?.navigationBar.addSubview(borderBottom)

        navigationBarManager.moreButton.menu = makeMoreMenu()
        navigationBarManager.moreButton.showsMenuAsPrimaryAction = true
    }

    @objc private func buttonMoreTapped() {

    }

    private func reloadBlogIconView() {
        let blog = post.blog

        if blog.hasIcon == true {
            let size = CGSize(width: 24, height: 24)
            navigationBarManager.siteIconView.imageView.downloadSiteIcon(for: blog, imageSize: size)
        } else if blog.isWPForTeams() {
            navigationBarManager.siteIconView.imageView.tintColor = UIColor.listIcon
            navigationBarManager.siteIconView.imageView.image = UIImage.gridicon(.p2)
        } else {
            navigationBarManager.siteIconView.imageView.image = UIImage.siteIconPlaceholder
        }
    }

    private func reloadEditorContents() {
        let content = post.content ?? String()

        setTitle(post.postTitle ?? "")
        setHTML(content)

        // TODO: reimplement
//        SiteSuggestionService.shared.prefetchSuggestionsIfNeeded(for: post.blog) { [weak self] in
//            self?.gutenberg.updateCapabilities()
//        }
    }

    private func refreshInterface() {
        reloadBlogIconView()
        reloadEditorContents()
        reloadPublishButton()
        navigationItem.rightBarButtonItems = post.status == .trash ? [] : navigationBarManager.rightBarButtonItems
    }

    // TODO: reimplement
    func toggleEditingMode() {
//        gutenberg.toggleHTMLMode()
//        mode.toggle()
//        editorSession.switch(editor: analyticsEditor)
//        presentEditingModeSwitchedNotice()
//
//        navigationBarManager.undoButton.isHidden = mode == .html
//        navigationBarManager.redoButton.isHidden = mode == .html
    }

    private func performAutoSave() {
        Task {
            await getLatestContent()
        }
    }

    private func getLatestContent() async {
        // TODO: read title as well
        let startTime = CFAbsoluteTimeGetCurrent()
        let content = try? await editorViewController.getContent()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        print("gutenbergkit-measure_get-latest-content:", duration)

        if content != post.content {
            post.content = content
            post.managedObjectContext.map(ContextManager.shared.save)

            editorContentWasUpdated()
        }
    }

    // TODO: reimplement
    func focusTitleIfNeeded() {
//        guard !post.hasContent(), shouldPresentInformativeDialog == false, shouldPresentPhase2informativeDialog == false else {
//            return
//        }
//        gutenberg.setFocusOnTitle()
    }

    // TODO: reimplement
    func showEditorHelp() {
        WPAnalytics.track(.gutenbergEditorHelpShown, properties: [:], blog: post.blog)
//        gutenberg.showEditorHelp()
    }

    private func handleMissingBlockAlertButtonPressed() {
        let blog = post.blog
        let JetpackSSOEnabled = (blog.jetpack?.isConnected ?? false) && (blog.settings?.jetpackSSOEnabled ?? false)
        if JetpackSSOEnabled == false {
            let controller = JetpackSettingsViewController(blog: blog)
            controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(jetpackSettingsControllerDoneButtonPressed))
            let navController = UINavigationController(rootViewController: controller)
            present(navController, animated: true)
        }
    }

    // TODO: reimplement
    @objc private func jetpackSettingsControllerDoneButtonPressed() {
//        if presentedViewController != nil {
//            dismiss(animated: true) { [weak self] in
//                self?.gutenberg.updateCapabilities()
//            }
//        }
    }

    // MARK: - Event handlers

    @objc func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return presentationController(forPresented: presented, presenting: presenting)
    }
}

// MARK: - GutenbergBridgeDelegate

/// - warning: the app can't make any assumption about the thread on which `GutenbergBridgeDelegate` gets invoked. In some scenarios, it gets called from the main thread, for example, if being invoked directly from [Gutenberg.swift](https://github.com/WordPress/gutenberg/blob/64f9d9d1ced7a5aa7f3874890306554c5b703ce6/packages/react-native-bridge/ios/Gutenberg.swift). And sometimes, it gets called on a dispatch queue created by the React Native runtime for a native module (see [React Native: Threading](https://reactnative.dev/docs/native-modules-ios#threading). It happens when the methods are invoked directly from JavaScript.
extension NewGutenbergViewController {
    // TODO: reimplement (run local server)
    func gutenbergDidGetRequestFetch(path: String, completion: @escaping (Result<Any, NSError>) -> Void) {
//        guard let context = post.managedObjectContext else {
//            didEncounterMissingContextError()
//            completion(.failure(URLError(.unknown) as NSError))
//            return
//        }
//        context.perform {
//            GutenbergNetworkRequest(path: path, blog: self.post.blog, method: .get).request(completion: completion)
//        }
    }

    // TODO: reimplement (run local server)
    func gutenbergDidPostRequestFetch(path: String, data: [String: AnyObject]?, completion: @escaping (Result<Any, NSError>) -> Void) {
//        guard let context = post.managedObjectContext else {
//            didEncounterMissingContextError()
//            completion(.failure(URLError(.unknown) as NSError))
//            return
//        }
//        context.perform {
//            GutenbergNetworkRequest(path: path, blog: self.post.blog, method: .post, data: data).request(completion: completion)
//        }
    }

    func showAlertForEmptyPostPublish() {

        let title: String = (self.post is Page) ? EmptyPostActionSheet.titlePage : EmptyPostActionSheet.titlePost
        let message: String = EmptyPostActionSheet.message
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: MediaAttachmentActionSheet.dismissActionTitle, style: .cancel) { (action) in

        }
        alertController.addAction(dismissAction)

        alertController.title = title
        alertController.message = message
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = view.frame
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated: true, completion: nil)
    }

    func gutenbergDidRequestImagePreview(with fullSizeUrl: URL, thumbUrl: URL?) {
        navigationController?.definesPresentationContext = true

        let controller: WPImageViewController
        if let image = AnimatedImageCache.shared.cachedStaticImage(url: fullSizeUrl) {
            controller = WPImageViewController(image: image)
        } else {
            controller = WPImageViewController(externalMediaURL: fullSizeUrl)
        }

        controller.post = self.post
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overCurrentContext
        self.present(controller, animated: true)
    }

    // TODO: remove (web view should be able to handle it)
    func updateConstraintsToAvoidKeyboard(frame: CGRect) {
        keyboardFrame = frame
        let minimumKeyboardHeight = CGFloat(50)
        guard let suggestionViewBottomConstraint = suggestionViewBottomConstraint else {
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

    // TODO: remove
//    func gutenbergDidRequestMention(callback: @escaping (Swift.Result<String, NSError>) -> Void) {
//        DispatchQueue.main.async(execute: { [weak self] in
//            self?.showSuggestions(type: .mention, callback: callback)
//        })
//    }
//
//    func gutenbergDidRequestXpost(callback: @escaping (Swift.Result<String, NSError>) -> Void) {
//        DispatchQueue.main.async(execute: { [weak self] in
//            self?.showSuggestions(type: .xpost, callback: callback)
//        })
//    }

    // TODO: reimplement (it it used?)
    func gutenbergDidRequestPreview() {
//        displayPreview()
    }

    // TODO: reimplement (where is it used?)
//    func gutenbergDidRequestBlockTypeImpressions() -> [String: Int] {
//        return gutenbergSettings.blockTypeImpressions
//    }
//
//    func gutenbergDidRequestSetBlockTypeImpressions(_ impressions: [String: Int]) -> Void {
//        gutenbergSettings.blockTypeImpressions = impressions
//    }

    // TODO: reimplement (where is it used?)
    func gutenbergDidRequestContactCustomerSupport() {
        coordinator.showSupport()
    }

    // TODO: reimplement (where is it used?)
    func gutenbergDidRequestGotoCustomerSupportOptions() {
        let controller = SupportTableViewController()
        let navController = UINavigationController(rootViewController: controller)
        self.topmostPresentedViewController.present(navController, animated: true)
    }
}

// MARK: - Suggestions implementation

extension NewGutenbergViewController {

    // TODO: reimplement (is it for user-names?)
    private func showSuggestions(type: SuggestionType, callback: @escaping (Swift.Result<String, NSError>) -> Void) {
        guard let siteID = post.blog.dotComID else {
            callback(.failure(GutenbergSuggestionsViewController.SuggestionError.notAvailable as NSError))
            return
        }

        switch type {
        case .mention:
            guard SuggestionService.shared.shouldShowSuggestions(for: post.blog) else { return }
        case .xpost:
            guard SiteSuggestionService.shared.shouldShowSuggestions(for: post.blog) else { return }
        }

        previousFirstResponder = view.findFirstResponder()
        let suggestionsController = GutenbergSuggestionsViewController(siteID: siteID, suggestionType: type)
        suggestionsController.onCompletion = { (result) in
            callback(result)
            suggestionsController.view.removeFromSuperview()
            suggestionsController.removeFromParent()
            if let previousFirstResponder = self.previousFirstResponder {
                previousFirstResponder.becomeFirstResponder()
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
            suggestionsController.view.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 0),
            suggestionsController.view.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: 0),
            suggestionsBottomConstraint,
            suggestionsController.view.topAnchor.constraint(equalTo: view.safeTopAnchor)
        ])
        self.suggestionViewBottomConstraint = suggestionsBottomConstraint
        updateConstraintsToAvoidKeyboard(frame: keyboardFrame)
        suggestionsController.didMove(toParent: self)
    }
}

// MARK: - GutenbergBridgeDataSource

extension NewGutenbergViewController/*: GutenbergBridgeDataSource*/ {
    // TODO: reimplement
//    func gutenbergCapabilities() -> [Capabilities: Bool] {
//        let isFreeWPCom = post.blog.isHostedAtWPcom && !post.blog.hasPaidPlan
//        let isWPComSite = post.blog.isHostedAtWPcom || post.blog.isAtomic()
//
//        // Disable Jetpack-powered editor features in WordPress app based on Features Removal coordination
//        if !JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() {
//            return [
//                .mentions: false,
//                .xposts: false,
//                .contactInfoBlock: false,
//                .layoutGridBlock: false,
//                .tiledGalleryBlock: false,
//                .videoPressBlock: false,
//                .videoPressV5Support: false,
//                .unsupportedBlockEditor: false,
//                .canEnableUnsupportedBlockEditor: false,
//                .isAudioBlockMediaUploadEnabled: !isFreeWPCom,
//                .reusableBlock: false,
//                .shouldUseFastImage: !post.blog.isPrivate(),
//                .facebookEmbed: false,
//                .instagramEmbed: false,
//                .loomEmbed: false,
//                .smartframeEmbed: false,
//                .supportSection: false,
//                .onlyCoreBlocks: true
//            ]
//        }
//
//        return [
//            .mentions: SuggestionService.shared.shouldShowSuggestions(for: post.blog),
//            .xposts: SiteSuggestionService.shared.shouldShowSuggestions(for: post.blog),
//            .contactInfoBlock: post.blog.supports(.contactInfo),
//            .layoutGridBlock: post.blog.supports(.layoutGrid),
//            .tiledGalleryBlock: post.blog.supports(.tiledGallery),
//            .videoPressBlock: post.blog.supports(.videoPress),
//            .videoPressV5Support:
//                post.blog.supports(.videoPressV5),
//            .unsupportedBlockEditor: isUnsupportedBlockEditorEnabled,
//            .canEnableUnsupportedBlockEditor: (post.blog.jetpack?.isConnected ?? false) && !isJetpackSSOEnabled,
//            .isAudioBlockMediaUploadEnabled: !isFreeWPCom,
//            // Only enable reusable block in WP.com sites until the issue
//            // (https://github.com/wordpress-mobile/gutenberg-mobile/issues/3457) in self-hosted sites is fixed
//            .reusableBlock: isWPComSite,
//            .shouldUseFastImage: !post.blog.isPrivate(),
//            // Jetpack embeds
//            .facebookEmbed: post.blog.supports(.facebookEmbed),
//            .instagramEmbed: post.blog.supports(.instagramEmbed),
//            .loomEmbed: post.blog.supports(.loomEmbed),
//            .smartframeEmbed: post.blog.supports(.smartframeEmbed),
//            .supportSection: true
//        ]
//    }

    private var isJetpackSSOEnabled: Bool {
        let blog = post.blog
        return (blog.jetpack?.isConnected ?? false) && (blog.settings?.jetpackSSOEnabled ?? false)
    }

    private var isUnsupportedBlockEditorEnabled: Bool {
        // The Unsupported Block Editor is disabled for all self-hosted non-jetpack sites.
        // This is because they can have their web editor to be set to classic and then the fallback will not work.

        let blog = post.blog
        return blog.isHostedAtWPcom || isJetpackSSOEnabled
    }
}

// MARK: - PostEditorStateContextDelegate

extension NewGutenbergViewController: PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {
        reloadPublishButton()
    }

    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {
        reloadPublishButton()
    }

    func reloadPublishButton() {
        navigationBarManager.reloadPublishButton()
    }
}

// MARK: - PostEditorNavigationBarManagerDelegate

extension NewGutenbergViewController: PostEditorNavigationBarManagerDelegate {

    var publishButtonText: String {
        return postEditorStateContext.publishButtonText
    }

    var isPublishButtonEnabled: Bool {
         return postEditorStateContext.isPublishButtonEnabled
    }

    var uploadingButtonSize: CGSize {
        return AztecPostViewController.Constants.uploadingButtonSize
    }

    func gutenbergDidRequestToggleUndoButton(_ isDisabled: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.navigationBarManager.undoButton.isUserInteractionEnabled = isDisabled ? false : true
                self.navigationBarManager.undoButton.alpha = isDisabled ? 0.3 : 1.0
            }
        }
    }

    func gutenbergDidRequestToggleRedoButton(_ isDisabled: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.navigationBarManager.redoButton.isUserInteractionEnabled = isDisabled ? false : true
                self.navigationBarManager.redoButton.alpha = isDisabled ? 0.3 : 1.0
            }
        }
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton) {
        performAfterUpdatingContent { [self] in
            isEditorClosing = true
            cancelEditing()
        }
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, undoWasPressed sender: UIButton) {
        // TODO: reimplement
        // self.gutenberg.onUndoPressed()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, redoWasPressed sender: UIButton) {
        // TODO: reimplement
        // self.gutenberg.onRedoPressed()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {
        fatalError("not supported")
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {
        fatalError("not supported")
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        performAfterUpdatingContent { [self] in
            if editorHasContent {
                handlePrimaryActionButtonTap()
            } else {
                showAlertForEmptyPostPublish()
            }
        }
    }

    private func performAfterUpdatingContent(_ closure: @MainActor @escaping () -> Void) {
        navigationController?.view.isUserInteractionEnabled = false
        Task { @MainActor in
            await getLatestContent()
            navigationController?.view.isUserInteractionEnabled = true
            closure()
        }
    }
}

/// This extension handles the "more" actions triggered by the top right
/// navigation bar button of Gutenberg editor.
extension NewGutenbergViewController {

    enum ErrorCode: Int {
        case managedObjectContextMissing = 2
    }

    func makeMoreMenu() -> UIMenu {
        UIMenu(title: "", image: nil, identifier: nil, options: [], children: [
            UIDeferredMenuElement.uncached { [weak self] callback in
                // Common actions at the top so they are always in the same
                // relative place.
                callback(self?.makeMoreMenuMainSections() ?? [])
            },
            UIDeferredMenuElement.uncached { [weak self] callback in
                // Dynamic actions at the bottom. The actions are loaded asynchronously
                // because they need the latest post content from the editor
                // to display the correct state.
                self?.performAfterUpdatingContent {
                    callback(self?.makeMoreMenuAsyncSections() ?? [])
                }
            }
        ])
    }

    private func makeMoreMenuMainSections() -> [UIMenuElement] {
        return  [
            UIMenu(title: "", subtitle: "", options: .displayInline, children: makeMoreMenuActions()),
        ]
    }

    private func makeMoreMenuAsyncSections() -> [UIMenuElement] {
        var sections: [UIMenuElement] = [
            // Dynamic actions at the bottom
            UIMenu(title: "", subtitle: "", options: .displayInline, children: makeMoreMenuSecondaryActions())
        ]
        if let string = makeContextStructureString() {
            sections.append(UIAction(subtitle: string, attributes: [.disabled], handler: { _ in }))
        }
        return sections
    }

    private func makeMoreMenuSecondaryActions() -> [UIAction] {
        var actions: [UIAction] = []
        if post.original().isStatus(in: [.draft, .pending]) {
            actions.append(UIAction(title: Strings.saveDraft, image: UIImage(systemName: "doc"), attributes: (editorHasChanges && editorHasContent) ? [] : [.disabled]) { [weak self] _ in
                self?.buttonSaveDraftTapped()
            })
        }
        return actions
    }

    private func makeMoreMenuActions() -> [UIAction] {
        var actions: [UIAction] = []

        let toggleModeTitle = mode == .richText ? Strings.codeEditor : Strings.visualEditor
        let toggleModeIconName = mode == .richText ? "curlybraces" : "doc.richtext"
        actions.append(UIAction(title: toggleModeTitle, image: UIImage(systemName: toggleModeIconName)) { [weak self] _ in
            self?.toggleEditingMode()
        })

        actions.append(UIAction(title: Strings.preview, image: UIImage(systemName: "safari")) { [weak self] _ in
            self?.displayPreview()
        })

        let revisionCount = (post.revisions ?? []).count
        if revisionCount > 0 {
            actions.append(UIAction(title: Strings.revisions + " (\(revisionCount))", image: UIImage(systemName: "clock.arrow.circlepath")) { [weak self] _ in
                self?.displayRevisionsList()
            })
        }

        let settingsTitle = self.post is Page ? Strings.pageSettings : Strings.postSettings
        actions.append(UIAction(title: settingsTitle, image: UIImage(systemName: "gearshape")) { [weak self] _ in
            self?.displayPostSettings()
        })
        let helpTitle = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() ? Strings.helpAndSupport : Strings.help
        actions.append(UIAction(title: helpTitle, image: UIImage(systemName: "questionmark.circle")) { [weak self] _ in
            self?.showEditorHelp()
        })
        return actions
    }

    // TODO: reimplemnet
    private func makeContextStructureString() -> String? {
//        guard mode == .richText, let contentInfo = contentInfo else {
            return nil
//        }
//        return String(format: Strings.contentStructure, contentInfo.blockCount, contentInfo.wordCount, contentInfo.characterCount)
    }
}

// MARK: - Constants

extension NewGutenbergViewController {
    // - warning: deprecated (kahu-offline-mode)
    struct MoreSheetAlert {
        static let htmlTitle = NSLocalizedString("Switch to HTML Mode", comment: "Switches the Editor to HTML Mode")
        static let richTitle = NSLocalizedString("Switch to Visual Mode", comment: "Switches the Editor to Rich Text Mode")
        static let previewTitle = NSLocalizedString("Preview", comment: "Displays the Post Preview Interface")
        static let historyTitle = NSLocalizedString("History", comment: "Displays the History screen from the editor's alert sheet")
        static let postSettingsTitle = NSLocalizedString("Post Settings", comment: "Name of the button to open the post settings")
        static let pageSettingsTitle = NSLocalizedString("Page Settings", comment: "Name of the button to open the page settings")
        static let keepEditingTitle = NSLocalizedString("Keep Editing", comment: "Goes back to editing the post.")
        static let accessibilityIdentifier = "MoreSheetAccessibilityIdentifier"
        static let editorHelpAndSupportTitle = NSLocalizedString("Help & Support", comment: "Open editor help options")
        static let editorHelpTitle = NSLocalizedString("Help", comment: "Open editor help options")
    }
}

private enum Strings {
    static let codeEditor = NSLocalizedString("postEditor.moreMenu.codeEditor", value: "Code Editor", comment: "Post Editor / Button in the 'More' menu")
    static let visualEditor = NSLocalizedString("postEditor.moreMenu.visualEditor", value: "Visual Editor", comment: "Post Editor / Button in the 'More' menu")
    static let preview = NSLocalizedString("postEditor.moreMenu.preview", value: "Preview", comment: "Post Editor / Button in the 'More' menu")
    static let revisions = NSLocalizedString("postEditor.moreMenu.revisions", value: "Revisions", comment: "Post Editor / Button in the 'More' menu")
    static let pageSettings = NSLocalizedString("postEditor.moreMenu.pageSettings", value: "Page Settings", comment: "Post Editor / Button in the 'More' menu")
    static let postSettings = NSLocalizedString("postEditor.moreMenu.postSettings", value: "Post Settings", comment: "Post Editor / Button in the 'More' menu")
    static let helpAndSupport = NSLocalizedString("postEditor.moreMenu.helpAndSupport", value: "Help & Support", comment: "Post Editor / Button in the 'More' menu")
    static let help = NSLocalizedString("postEditor.moreMenu.help", value: "Help", comment: "Post Editor / Button in the 'More' menu")
    static let saveDraft = NSLocalizedString("postEditor.moreMenu.saveDraft", value: "Save Draft", comment: "Post Editor / Button in the 'More' menu")
    static let contentStructure = NSLocalizedString("postEditor.moreMenu.contentStructure", value: "Blocks: %li, Words: %li, Characters: %li", comment: "Post Editor / 'More' menu details labels with 'Blocks', 'Words' and 'Characters' counts as parameters (in that order)")
}

// MARK: - Constants

private extension NewGutenbergViewController {
    enum Analytics {
        static let editorSource = "new-gutenberg"
    }

}

private extension NewGutenbergViewController {

    struct EmptyPostActionSheet {
        static let titlePost = NSLocalizedString("Can't publish an empty post", comment: "Alert message that is shown when trying to publish empty post")
        static let titlePage = NSLocalizedString("Can't publish an empty page", comment: "Alert message that is shown when trying to publish empty page")
        static let message = NSLocalizedString("Please add some content before trying to publish.", comment: "Suggestion to add content before trying to publish post or page")
    }

    struct MediaAttachmentActionSheet {
        static let title = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
        static let dismissActionTitle = NSLocalizedString(
            "gutenberg.mediaAttachmentActionSheet.dismiss",
            value: "Dismiss",
            comment: "User action to dismiss media options."
        )
        static let stopUploadActionTitle = NSLocalizedString("Stop upload", comment: "User action to stop upload.")
        static let retryUploadActionTitle = NSLocalizedString("Retry", comment: "User action to retry media upload.")
    }
}

// Block Editor Settings
extension NewGutenbergViewController {

    private func fetchBlockSettings() {
        editorSettingsService?.fetchSettings({ [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let response):
                if response.hasChanges {
                    // TODO: inject in hte editor
                    // self.gutenberg.updateEditorSettings(response.blockEditorSettings)
                }
            case .failure(let err):
                DDLogError("Error fetching settings: \(err)")
            }
        })
    }
}
