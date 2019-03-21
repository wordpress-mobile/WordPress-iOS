import UIKit
import WPMediaPicker
import Gutenberg
import Aztec

class GutenbergViewController: UIViewController, PostEditor {

    let errorDomain: String = "GutenbergViewController.errorDomain"

    enum RequestHTMLReason {
        case publish
        case close
        case more
        case switchToAztec
        case switchBlog
        case autoSave
    }

    // MARK: - UI

    private var containerView = GutenbergContainerView.loadFromNib()

    // MARK: - Aztec

    internal let replaceEditor: (EditorViewController, EditorViewController) -> ()

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

    var onClose: ((Bool, Bool) -> Void)?

    var isOpenedDirectlyForPhotoPost: Bool = false


    var shouldRemovePostOnDismiss: Bool = false

    // MARK: - Editor Media actions

    var isUploadingMedia: Bool {
        return mediaInserterHelper.isUploadingMedia()
    }

    func removeFailedMedia() {
        // TODO: we can only implement this when GB bridge allows removal of blocks
    }

    var hasFailedMedia: Bool {
        return mediaInserterHelper.hasFailedMedia()
    }

    func cancelUploadOfAllMedia(for post: AbstractPost) {
        return mediaInserterHelper.cancelUploadOfAllMedia()
    }

    static let autoSaveInterval: TimeInterval = 5

    var autoSaveTimer: Timer?

    func setTitle(_ title: String) {
        guard gutenberg.isLoaded else {
            return
        }

        gutenberg.setTitle(title)
    }

    func setHTML(_ html: String) {
        guard gutenberg.isLoaded else {
            return
        }

        self.html = html
        gutenberg.updateHtml(html)
    }

    func getHTML() -> String {
        return html
    }

    var post: AbstractPost {
        didSet {
            postEditorStateContext = PostEditorStateContext(post: post, delegate: self)
            attachmentDelegate = AztecAttachmentDelegate(post: post)
            mediaPickerHelper = GutenbergMediaPickerHelper(context: self, post: post)
            mediaInserterHelper = GutenbergMediaInserterHelper(post: post, gutenberg: gutenberg)
            gutenbergImageLoader.post = post
            refreshInterface()
        }
    }

    let navigationBarManager = PostEditorNavigationBarManager()

    lazy var attachmentDelegate = AztecAttachmentDelegate(post: post)

    lazy var mediaPickerHelper: GutenbergMediaPickerHelper = {
        return GutenbergMediaPickerHelper(context: self, post: post)
    }()

    lazy var mediaInserterHelper: GutenbergMediaInserterHelper = {
        return GutenbergMediaInserterHelper(post: post, gutenberg: gutenberg)
    }()

    /// For autosaving - The debouncer will execute local saving every defined number of seconds.
    /// In this case every 0.5 second
    ///
    fileprivate(set) lazy var debouncer: Debouncer = {
        return Debouncer(delay: PostEditorDebouncerConstants.autoSavingDelay, callback: debouncerCallback)
    }()

    /// Media Library Data Source
    ///
    lazy var mediaLibraryDataSource: MediaLibraryPickerDataSource = {
        return MediaLibraryPickerDataSource(post: self.post)
    }()

    // MARK: - Private variables

    private lazy var gutenbergImageLoader: GutenbergImageLoader = {
        return GutenbergImageLoader(post: post)
    }()

    private lazy var gutenberg: Gutenberg = {
        return Gutenberg(dataSource: self, extraModules: [gutenbergImageLoader])
    }()

    private var requestHTMLReason: RequestHTMLReason?
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

    // MARK: - Initializers
    required init(
        post: AbstractPost,
        replaceEditor: @escaping (EditorViewController, EditorViewController) -> (),
        editorSession: PostEditorAnalyticsSession? = nil) {

        self.post = post

        self.replaceEditor = replaceEditor
        verificationPromptHelper = AztecVerificationPromptHelper(account: self.post.blog.account)
        shouldRemovePostOnDismiss = post.hasNeverAttemptedToUpload() && !post.isLocalRevision
        self.editorSession = editorSession ?? PostEditorAnalyticsSession(editor: .gutenberg, post: post)

        super.init(nibName: nil, bundle: nil)

        PostCoordinator.shared.cancelAnyPendingSaveOf(post: post)
        navigationBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        stopAutoSave()
        gutenberg.invalidate()
        attachmentDelegate.cancelAllPendingMediaRequests()
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContainerView()
        setupGutenbergView()
        createRevisionOfPost()
        configureNavigationBar()
        refreshInterface()

        gutenberg.delegate = self
        showInformativeDialogIfNecessary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        verificationPromptHelper?.updateVerificationStatus()
    }

    // MARK: - Functions

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.accessibilityIdentifier = "Gutenberg Editor Navigation Bar"
        navigationItem.leftBarButtonItems = navigationBarManager.leftBarButtonItems
        navigationItem.rightBarButtonItems = navigationBarManager.rightBarButtonItems
    }

    private func reloadBlogPickerButton() {
        var pickerTitle = post.blog.url ?? String()
        if let blogName = post.blog.settings?.name, blogName.isEmpty == false {
            pickerTitle = blogName
        }

        navigationBarManager.reloadBlogPickerButton(with: pickerTitle, enabled: !isSingleSiteMode)
    }

    private func reloadEditorContents() {
        let content = post.content ?? String()

        setTitle(post.postTitle ?? "")
        setHTML(content)
    }

    private func refreshInterface() {
        reloadBlogPickerButton()
        reloadEditorContents()
        reloadPublishButton()
    }

    func contentByStrippingMediaAttachments() -> String {
        return html //TODO: return media attachment stripped version in future
    }

    func toggleEditingMode() {
        gutenberg.toggleHTMLMode()
        mode.toggle()
        editorSession.switch(editor: analyticsEditor)
    }

    func requestHTML(for reason: RequestHTMLReason) {
        requestHTMLReason = reason
        gutenberg.requestHTML()
    }

    func focusTitleIfNeeded() {
        guard !post.hasContent() else {
            return
        }
        gutenberg.setFocusOnTitle()
    }

    // MARK: - Event handlers

    @objc func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return presentationController(forPresented: presented, presenting: presenting)
    }

    // MARK: - Switch to Aztec

    func savePostEditsAndSwitchToAztec() {
        requestHTML(for: .switchToAztec)
    }
}

// MARK: - Views setup

extension GutenbergViewController {
    private func setupGutenbergView() {
        gutenberg.rootView.translatesAutoresizingMaskIntoConstraints = false
        containerView.editorContainerView.addSubview(gutenberg.rootView)
        containerView.editorContainerView.leftAnchor.constraint(equalTo: gutenberg.rootView.leftAnchor).isActive = true
        containerView.editorContainerView.rightAnchor.constraint(equalTo: gutenberg.rootView.rightAnchor).isActive = true
        containerView.editorContainerView.topAnchor.constraint(equalTo: gutenberg.rootView.topAnchor).isActive = true
        containerView.editorContainerView.bottomAnchor.constraint(equalTo: gutenberg.rootView.bottomAnchor).isActive = true
    }

    private func setupContainerView() {
        view.backgroundColor = .white
        view.addSubview(containerView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        if WPDeviceIdentification.isiPad() {
            containerView.leftAnchor.constraint(equalTo: view.readableContentGuide.leftAnchor).isActive = true
            containerView.rightAnchor.constraint(equalTo: view.readableContentGuide.rightAnchor).isActive = true
        } else {
            containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            containerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        }
        containerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

// MARK: - GutenbergBridgeDelegate

extension GutenbergViewController: GutenbergBridgeDelegate {

    func gutenbergDidRequestMedia(from source: MediaPickerSource, with callback: @escaping MediaPickerDidPickMediaCallback) {
        switch source {
        case .mediaLibrary:
            gutenbergDidRequestMediaFromSiteMediaLibrary(with: callback)
        case .deviceLibrary:
            gutenbergDidRequestMediaFromDevicePicker(with: callback)
        case .deviceCamera:
            gutenbergDidRequestMediaFromCameraPicker(with: callback)
        }
    }


    func gutenbergDidRequestMediaFromSiteMediaLibrary(with callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       dataSourceType: .mediaLibrary,
                                                       callback: {(asset) in
                                                        guard let media = asset as? Media else {
                                                            callback(nil, nil)
                                                            return
                                                        }
                                                        self.mediaInserterHelper.insertFromSiteMediaLibrary(media: media, callback: callback)
        })
    }

    func gutenbergDidRequestMediaFromDevicePicker(with callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       dataSourceType: .device,
                                                       callback: {(asset) in
                                                        guard let phAsset = asset as? PHAsset else {
                                                            callback(nil, nil)
                                                            return
                                                        }
                                                        self.mediaInserterHelper.insertFromDevice(asset: phAsset, callback: callback)
        })
    }

    func gutenbergDidRequestMediaFromCameraPicker(with callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentCameraCaptureFullScreen(animated: true,
                                                         callback: {(asset) in
                                                            guard let phAsset = asset as? PHAsset else {
                                                                callback(nil, nil)
                                                                return
                                                            }
                                                            self.mediaInserterHelper.insertFromDevice(asset: phAsset, callback: callback)
        })
    }

    func gutenbergDidRequestMediaUploadSync() {
        self.mediaInserterHelper.syncUploads()
    }

    func gutenbergDidRequestMediaUploadCancelation(for mediaID: Int32) {
        guard let media = mediaInserterHelper.mediaFor(uploadID: mediaID) else {
            return
        }
        mediaInserterHelper.cancelUploadOf(media: media)
    }

    func gutenbergDidRequestMediaUploadActionDialog(for mediaID: Int32) {

        guard let media = mediaInserterHelper.mediaFor(uploadID: mediaID) else {
            return
        }

        let title: String = MediaAttachmentActionSheet.title
        var message: String? = nil
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: MediaAttachmentActionSheet.dismissActionTitle, style: .cancel) { (action) in

        }
        alertController.addAction(dismissAction)

        if media.remoteStatus == .pushing || media.remoteStatus == .processing {
            let cancelUploadAction = UIAlertAction(title: MediaAttachmentActionSheet.stopUploadActionTitle, style: .destructive) { (action) in
                self.mediaInserterHelper.cancelUploadOf(media: media)
            }
            alertController.addAction(cancelUploadAction)
        } else if media.remoteStatus == .failed, let error = media.error {
            message = error.localizedDescription
            let retryUploadAction = UIAlertAction(title: MediaAttachmentActionSheet.retryUploadActionTitle, style: .default) { (action) in
                self.mediaInserterHelper.retryUploadOf(media: media)
            }
            alertController.addAction(retryUploadAction)
        }

        alertController.title = title
        alertController.message = message
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = view.frame
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated: true, completion: nil)
    }

    func gutenbergDidProvideHTML(title: String, html: String, changed: Bool) {
        if changed {
            self.html = html
            self.postTitle = title
        }

        editorContentWasUpdated()
        mapUIContentToPostAndSave(immediate: true)
        if let reason = requestHTMLReason {
            requestHTMLReason = nil // clear the reason
            switch reason {
            case .publish:
                handlePublishButtonTap()
            case .close:
                cancelEditing()
            case .more:
                displayMoreSheet()
            case .switchToAztec:
                editorSession.switch(editor: .classic)
                EditorFactory().switchToAztec(from: self)
            case .switchBlog:
                blogPickerWasPressed()
            case .autoSave:
                break
            }
        }
    }

    func gutenbergDidLayout() {
        defer {
            isFirstGutenbergLayout = false
        }
        if isFirstGutenbergLayout {
            focusTitleIfNeeded()
        }
    }

    func gutenbergDidMount(hasUnsupportedBlocks: Bool) {
        startAutoSave()
        if !editorSession.started {
            editorSession.start(hasUnsupportedBlocks: hasUnsupportedBlocks)
        }
    }
}

// MARK: - GutenbergBridgeDataSource

extension GutenbergViewController: GutenbergBridgeDataSource {

    func gutenbergLocale() -> String? {
        return WordPressComLanguageDatabase().deviceLanguage.slug
    }

    func gutenbergTranslations() -> [String: [String]]? {
        return parseGutenbergTranslations()
    }

    func gutenbergInitialContent() -> String? {
        return post.content ?? ""
    }

    func gutenbergInitialTitle() -> String? {
        return post.postTitle ?? ""
    }

    func aztecAttachmentDelegate() -> TextViewAttachmentDelegate {
        return attachmentDelegate
    }
}

// MARK: - PostEditorStateContextDelegate

extension GutenbergViewController: PostEditorStateContextDelegate {

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

extension GutenbergViewController: PostEditorNavigationBarManagerDelegate {

    var publishButtonText: String {
        return postEditorStateContext.publishButtonText
    }

    var isPublishButtonEnabled: Bool {
        // TODO: return postEditorStateContext.isPublishButtonEnabled when
        // we have the required bridge communication that informs us every change
        return true
    }

    var uploadingButtonSize: CGSize {
        return AztecPostViewController.Constants.uploadingButtonSize
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton) {
        requestHTML(for: .close)
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {
        requestHTML(for: .more)
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, blogPickerWasPressed sender: UIButton) {
        requestHTML(for: .switchBlog)
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        requestHTML(for: .publish)
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {

    }
}

// MARK: - Auto Save

extension GutenbergViewController {

    func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: GutenbergViewController.autoSaveInterval, repeats: true, block: { [weak self](timer) in
            self?.requestHTML(for: .autoSave)
        })
    }

    func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
}

// MARK: - Constants

private extension GutenbergViewController {

    enum Analytics {
        static let editorSource = "gutenberg"
    }

}

private extension GutenbergViewController {
    struct MediaAttachmentActionSheet {
        static let title = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
        static let dismissActionTitle = NSLocalizedString("Dismiss", comment: "User action to dismiss media options.")
        static let stopUploadActionTitle = NSLocalizedString("Stop upload", comment: "User action to stop upload.")
        static let retryUploadActionTitle = NSLocalizedString("Retry", comment: "User action to retry media upload.")
        static let retryAllFailedUploadsActionTitle = NSLocalizedString("Retry all", comment: "User action to retry all failed media uploads.")
    }
}
