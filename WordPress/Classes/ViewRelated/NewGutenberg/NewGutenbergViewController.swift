import UIKit
import WordPressUI
import AsyncImageKit
import AutomatticTracks
import GutenbergKit
import SafariServices
import WordPressShared

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

    lazy var mediaPickerHelper: GutenbergMediaPickerHelper = {
        return GutenbergMediaPickerHelper(context: self, post: post)
    }()

    // MARK: - PostEditor

    private(set) lazy var postEditorStateContext: PostEditorStateContext = {
        return PostEditorStateContext(post: post, delegate: self)
    }()

    var analyticsEditorSource: String { Analytics.editorSource }
    var editorSession: PostEditorAnalyticsSession
    var onClose: (() -> Void)?

    // MARK: - Set content

    // TODO: reimplement
    func setTitle(_ title: String) {
//        guard gutenberg.isLoaded else {
//            return
//        }
//
//        gutenberg.setTitle(title)
    }

    var post: AbstractPost {
        didSet {
            postEditorStateContext = PostEditorStateContext(post: post, delegate: self)
            refreshInterface()
        }
    }

    let navigationBarManager: PostEditorNavigationBarManager

    // MARK: - Private variables

    // TODO: reimplemet
//    internal private(set) var contentInfo: ContentInfo?
    lazy var editorSettingsService: BlockEditorSettingsService? = {
        BlockEditorSettingsService(blog: post.blog, coreDataStack: ContextManager.sharedInstance())
    }()

    // MARK: - GutenbergKit

    private let editorViewController: GutenbergKit.EditorViewController
    private weak var autosaveTimer: Timer?

    // TODO: remove (none of these APIs are needed for the new editor)
    var autosaver = Autosaver(action: {})
    func prepopulateMediaItems(_ media: [Media]) {}
    var debouncer = WordPressShared.Debouncer(delay: 10)
    var replaceEditor: (EditorViewController, EditorViewController) -> ()
    var verificationPromptHelper: (any VerificationPromptHelper)?
    var isUploadingMedia: Bool { false }
    var wordCount: UInt { 0 }
    var postIsReblogged: Bool = false
    var entryPoint: PostEditorEntryPoint = .unknown
    var postTitle: String {
        get { post.postTitle ?? "" }
        set { post.postTitle = newValue }
    }
    func setHTML(_ html: String) {}
    func getHTML() -> String { post.content ?? "" }

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
        self.editorSession = PostEditorAnalyticsSession(editor: .gutenbergKit, post: post)
        self.navigationBarManager = navigationBarManager ?? PostEditorNavigationBarManager()

        let networkClient = NewGutenbergNetworkClient(blog: post.blog)

        let selfHostedApiUrl = post.blog.url(withPath: "wp-json/")
        let isSelfHosted = !post.blog.isHostedAtWPcom && !post.blog.isAtomic()
        let siteApiRoot = post.blog.isAccessibleThroughWPCom() && !isSelfHosted ? post.blog.wordPressComRestApi()?.baseURL.absoluteString : selfHostedApiUrl
        let siteId = post.blog.dotComID?.stringValue
        let authToken = post.blog.authToken ?? ""
        var authHeader = "Bearer \(authToken)"

        let applicationPassword = try? post.blog.getApplicationToken()

        if let appPassword = applicationPassword, let username = post.blog.username {
            let credentials = "\(username):\(appPassword)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                authHeader = "Basic \(base64Credentials)"
            }
        }

        let siteApiNamespace = post.blog.dotComID != nil && !isSelfHosted && applicationPassword == nil ? "sites/\(siteId ?? "")" : ""
        let postType = post is Page ? "page" : "post"
        let postId: Int? = post.postID?.intValue != -1 ? post.postID?.intValue : nil

        self.editorViewController = GutenbergKit.EditorViewController(
            id: postId,
            type: postType,
            title: post.postTitle ?? "",
            content: post.content ?? "",
            service: GutenbergKit.EditorService(client: networkClient),
            themeStyles: FeatureFlag.newGutenbergThemeStyles.enabled,
            plugins: FeatureFlag.newGutenbergPlugins.enabled && isSelfHosted,
            siteURL: post.blog.url ?? "",
            siteApiRoot: siteApiRoot!,
            siteApiNamespace: siteApiNamespace,
            authHeader: authHeader
        )

        super.init(nibName: nil, bundle: nil)

        self.editorViewController.delegate = self
        self.navigationBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        autosaveTimer?.invalidate()
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

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

        onViewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Handles refreshing controls with state context after options screen is dismissed
        editorContentWasUpdated()
    }

    private func setupEditorView() {
        view.tintColor = UIAppColor.editorPrimary

        addChild(editorViewController)
        view.addSubview(editorViewController.view)
        view.pinSubviewToAllEdges(editorViewController.view)
        editorViewController.didMove(toParent: self)

        if #available(iOS 16.4, *) {
            editorViewController.webView.isInspectable = true // TODO: should be diasble in production
        }

        // Doesn't seem to do anything
        setContentScrollView(editorViewController.webView.scrollView)
    }

    // MARK: - Functions

    private func configureNavigationBar() {
        navigationController?.navigationBar.accessibilityIdentifier = "Gutenberg Editor Navigation Bar"
        navigationItem.leftBarButtonItems = navigationBarManager.leftBarButtonItems

        edgesForExtendedLayout = []
        // TODO: make it work
//        configureDefaultNavigationBarAppearance()

        navigationBarManager.moreButton.menu = makeMoreMenu()
        navigationBarManager.moreButton.showsMenuAsPrimaryAction = true
    }

    private func reloadBlogIconView() {
        let viewModel = SiteIconViewModel(blog: post.blog, size: .small)
        navigationBarManager.siteIconView.imageView.setIcon(with: viewModel)
    }

    // TODO: this should not be called on viewDidLoad
    private func reloadEditorContents() {
        let content = post.content ?? String()

        setTitle(post.postTitle ?? "")
        editorViewController.setContent(content)

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

    func toggleEditingMode() {
        editorViewController.isCodeEditorEnabled.toggle()
    }

    private func performAutoSave() {
        Task {
            await getLatestContent()
        }
    }

    private func getLatestContent() async {
        // TODO: read title as well
        let startTime = CFAbsoluteTimeGetCurrent()
        let editorData = try? await editorViewController.getTitleAndContent()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        print("gutenbergkit-measure_get-latest-content:", duration)

        if let title = editorData?.title,
           let content = editorData?.content,
           title != post.postTitle || content != post.content {
            post.postTitle = title
            post.content = content
            post.managedObjectContext.map(ContextManager.shared.save)

            editorContentWasUpdated()
        }
    }

    func showEditorHelp() {
        guard let url = URL(string: "https://wordpress.com/support/wordpress-editor/") else { return }
        present(SFSafariViewController(url: url), animated: true)
    }

    func showFeedbackView() {
        self.present(SubmitFeedbackViewController(source: "gutenberg_kit", feedbackPrefix: "Editor"), animated: true)
    }

    func logException(_ exception: GutenbergJSException, with callback: @escaping () -> Void) {
        DispatchQueue.main.async {
            WordPressAppDelegate.crashLogging?.logJavaScriptException(exception, callback: callback)
        }
    }
}

extension NewGutenbergViewController: GutenbergKit.EditorViewControllerDelegate {
    func editorDidLoad(_ viewContoller: GutenbergKit.EditorViewController) {
        if !editorSession.started {
            // Note that this method is also used to track startup performance
            // It assumes this is being called when the editor has finished loading
            // If you need to refactor this, please ensure that the startup_time_ms property
            // is still reflecting the actual startup time of the editor
            editorSession.start()
        }
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didDisplayInitialContent content: String) {
        // Do nothing
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didEncounterCriticalError error: any Error) {
        onClose?()
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateContentWithState state: GutenbergKit.EditorState) {
        editorContentWasUpdated()

        // Save the changes on disk (crash protection). Throttle to ensure
        // it doesn't happen too often.
        if autosaveTimer == nil {
            autosaveTimer = .scheduledTimer(withTimeInterval: 7, repeats: false) { [weak self] _ in
                self?.autosaveTimer = nil
                self?.performAutoSave()
            }
        }
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateHistoryState state: GutenbergKit.EditorState) {
        gutenbergDidRequestToggleRedoButton(!state.hasRedo)
        gutenbergDidRequestToggleUndoButton(!state.hasUndo)
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didLogException error: GutenbergKit.GutenbergJSException) {
        logException(error) {
            // Do nothing
        }
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, performRequest: GutenbergKit.EditorNetworkRequest) async throws -> GutenbergKit.EditorNetworkResponse {
        throw URLError(.unknown)
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didRequestMediaFromSiteMediaLibrary config: OpenMediaLibraryAction) {
        let flags = mediaFilterFlags(using: config.allowedTypes ?? [])

        let initialSelectionArray: [Int]
        switch config.value {
        case .single(let id):
            initialSelectionArray = [id]
        case .multiple(let ids):
            initialSelectionArray = ids
        case .none:
            initialSelectionArray = []
        }

        mediaPickerHelper.presentSiteMediaPicker(filter: flags, allowMultipleSelection: config.multiple, initialSelection: initialSelectionArray) { [weak self] assets in
            guard let self, let media = assets as? [Media] else {
                self?.editorViewController.setMediaUploadAttachment("[]")
                return
            }
            let mediaInfos = media.map { item in
                var metadata: [String: String] = [:]
                if let videopressGUID = item.videopressGUID {
                    metadata["videopressGUID"] = videopressGUID
                }
                return MediaInfo(id: item.mediaID?.int32Value, url: item.remoteURL, type: item.mediaTypeString, caption: item.caption, title: item.filename, alt: item.alt, metadata: [:])
            }
            if let jsonString = convertMediaInfoArrayToJSONString(mediaInfos) {
                // Escape the string for JavaScript
                let escapedJsonString = jsonString.replacingOccurrences(of: "'", with: "\\'")
                editorViewController.setMediaUploadAttachment(escapedJsonString)
            }
        }
    }

    private func convertMediaInfoArrayToJSONString(_ mediaInfoArray: [MediaInfo]) -> String? {
        do {
            let jsonData = try JSONEncoder().encode(mediaInfoArray)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("Error encoding MediaInfo array: \(error)")
        }
        return nil
    }

    private func mediaFilterFlags(using filterArray: [OpenMediaLibraryAction.MediaType]) -> WPMediaType {
        var mediaType: Int = 0
        for filter in filterArray {
            switch filter {
            case .image:
                mediaType = mediaType | WPMediaType.image.rawValue
            case .video:
                mediaType = mediaType | WPMediaType.video.rawValue
            case .audio:
                mediaType = mediaType | WPMediaType.audio.rawValue
            case .other:
                mediaType = mediaType | WPMediaType.other.rawValue
            case .any:
                mediaType = mediaType | WPMediaType.all.rawValue
            @unknown default:
                fatalError()
            }
        }

        return WPMediaType(rawValue: mediaType)
    }
}

private struct NewGutenbergNetworkClient: GutenbergKit.EditorNetworkingClient {
    private let api: WordPressOrgRestApi?

    init(blog: Blog) {
        self.api = WordPressOrgRestApi(blog: blog)
    }

    func send(_ request: GutenbergKit.EditorNetworkRequest) async throws -> GutenbergKit.EditorNetworkResponse {
        guard let api else {
            throw URLError(.unknown) // Should never happen
        }
        // TODO: Add support for other requests
        var path = request.url.absoluteString
        guard path.hasPrefix("./wp-json") else {
            throw URLError(.unknown) // Currently unsupported
        }
        path.removePrefix("./wp-json")

        throw URLError(.unknown) // Should never happen
    }
}

// MARK: - GutenbergBridgeDelegate

extension NewGutenbergViewController {
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

    // TODO: are we going to show this natively?
    func gutenbergDidRequestImagePreview(with fullSizeUrl: URL, thumbUrl: URL?) {
        let lightboxVC = LightboxViewController(sourceURL: fullSizeUrl, host: MediaHost(post))
        lightboxVC.configureZoomTransition()
        present(lightboxVC, animated: true)
    }

    // TODO: reimplement
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
            cancelEditing()
        }
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, undoWasPressed sender: UIButton) {
        editorViewController.undo()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, redoWasPressed sender: UIButton) {
        editorViewController.redo()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {
        // Currently unsupported, do nothing.
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {
        // Currently unsupported, do nothing.
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

        let toggleModeTitle = editorViewController.isCodeEditorEnabled ? Strings.visualEditor: Strings.codeEditor
        let toggleModeIconName = editorViewController.isCodeEditorEnabled ? "doc.richtext" : "curlybraces"
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
        actions.append(UIAction(title: Strings.sendFeedback, image: UIImage(systemName: "envelope")) { [weak self] _ in
            self?.showFeedbackView()
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
    static let sendFeedback = NSLocalizedString("postEditor.moreMenu.sendFeedback", value: "Send Feedback", comment: "Post Editor / Button in the 'More' menu")
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
        guard let service = editorSettingsService else {
            return // TODO: when can it happen?
        }
        service.fetchSettings({ [weak self] result in
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

// Extend Gutenberg JavaScript exception struct to conform the protocol defined in the Crash Logging service
extension GutenbergJSException.StacktraceLine: @retroactive AutomatticTracks.JSStacktraceLine {}
extension GutenbergJSException: @retroactive AutomatticTracks.JSException {}
