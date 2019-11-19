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

    private lazy var stockPhotos: GutenbergStockPhotos = {
        return GutenbergStockPhotos(gutenberg: gutenberg, mediaInserter: mediaInserterHelper)
    }()
    private lazy var filesAppMediaPicker: GutenbergFilesAppMediaSource = {
        return GutenbergFilesAppMediaSource(gutenberg: gutenberg, mediaInserter: mediaInserterHelper)
    }()

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

    var mediaToInsertOnPost = [Media]()

    func prepopulateMediaItems(_ media: [Media]) {
        mediaToInsertOnPost = media
    }

    private func insertPrePopulatedMedia() {
        for media in mediaToInsertOnPost {
            guard
                media.mediaType == .image, // just images for now
                let mediaID = media.mediaID?.int32Value,
                let mediaURLString = media.remoteURL,
                let mediaURL = URL(string: mediaURLString) else {
                    continue
            }
            gutenberg.appendMedia(id: mediaID, url: mediaURL, type: .image)
        }
        mediaToInsertOnPost = []
    }

    private func showMediaSelectionOnStart() {
        isOpenedDirectlyForPhotoPost = false
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       filter: .image,
                                                       dataSourceType: .device,
                                                       allowMultipleSelection: false,
                                                       callback: {(asset) in
                                                        guard let phAsset = asset as? [PHAsset] else {
                                                            return
                                                        }
                                                        self.mediaInserterHelper.insertFromDevice(assets: phAsset, callback: { media in
                                                            guard let media = media,
                                                                let mediaInfo = media.first,
                                                                let mediaID = mediaInfo.id,
                                                                let mediaURLString = mediaInfo.url,
                                                                let mediaURL = URL(string: mediaURLString) else {
                                                                return
                                                            }
                                                            self.gutenberg.appendMedia(id: mediaID, url: mediaURL, type: .image)
                                                        })
        })
    }

    // MARK: - Set content

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
            removeObservers(fromPost: oldValue)
            addObservers(toPost: post)
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

    lazy var autosaver = Autosaver { [weak self] in
        self?.requestHTML(for: .autoSave)
    }

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
    var shouldPresentInformativeDialog = false

    // MARK: - Initializers
    required init(
        post: AbstractPost,
        replaceEditor: @escaping (EditorViewController, EditorViewController) -> (),
        editorSession: PostEditorAnalyticsSession? = nil) {

        self.post = post

        self.replaceEditor = replaceEditor
        verificationPromptHelper = AztecVerificationPromptHelper(account: self.post.blog.account)
        self.editorSession = editorSession ?? PostEditorAnalyticsSession(editor: .gutenberg, post: post)

        super.init(nibName: nil, bundle: nil)

        addObservers(toPost: post)

        PostCoordinator.shared.cancelAnyPendingSaveOf(post: post)
        navigationBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        removeObservers(fromPost: post)
        gutenberg.invalidate()
        attachmentDelegate.cancelAllPendingMediaRequests()
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
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
        guard !post.hasContent() && shouldPresentInformativeDialog == false else {
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
        view.backgroundColor = .white
        gutenberg.rootView.translatesAutoresizingMaskIntoConstraints = false
        gutenberg.rootView.backgroundColor = .basicBackground
        view.addSubview(gutenberg.rootView)

        view.leftAnchor.constraint(equalTo: gutenberg.rootView.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: gutenberg.rootView.rightAnchor).isActive = true
        view.topAnchor.constraint(equalTo: gutenberg.rootView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: gutenberg.rootView.bottomAnchor).isActive = true
    }
}

// MARK: - GutenbergBridgeDelegate

extension GutenbergViewController: GutenbergBridgeDelegate {
    func editorDidAutosave() {
        autosaver.contentDidChange()
    }

    func gutenbergDidRequestMedia(from source: Gutenberg.MediaSource, filter: [Gutenberg.MediaType], allowMultipleSelection: Bool, with callback: @escaping MediaPickerDidPickMediaCallback) {
        let flags = mediaFilterFlags(using: filter)
        switch source {
        case .mediaLibrary:
            gutenbergDidRequestMediaFromSiteMediaLibrary(filter: flags, allowMultipleSelection: allowMultipleSelection, with: callback)
        case .deviceLibrary:
            gutenbergDidRequestMediaFromDevicePicker(filter: flags, allowMultipleSelection: allowMultipleSelection, with: callback)
        case .deviceCamera:
            gutenbergDidRequestMediaFromCameraPicker(filter: flags, with: callback)
        case .stockPhotos:
            stockPhotos.presentPicker(origin: self, post: post, multipleSelection: allowMultipleSelection, callback: callback)
        case .filesApp:
            filesAppMediaPicker.presentPicker(origin: self, filters: filter, multipleSelection: allowMultipleSelection, callback: callback)
        default: break
        }
    }

    func mediaFilterFlags(using filterArray: [Gutenberg.MediaType]) -> WPMediaType {
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
            }
        }
        if mediaType == 0 {
            return WPMediaType.all
        } else {
            return WPMediaType(rawValue: mediaType)
        }
    }

    func gutenbergDidRequestMediaFromSiteMediaLibrary(filter: WPMediaType, allowMultipleSelection: Bool, with callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       filter: filter,
                                                       dataSourceType: .mediaLibrary,
                                                       allowMultipleSelection: allowMultipleSelection,
                                                       callback: {(assets) in
                                                        guard let media = assets as? [Media] else {
                                                            callback(nil)
                                                            return
                                                        }
                                                        self.mediaInserterHelper.insertFromSiteMediaLibrary(media: media, callback: callback)
        })
    }

    func gutenbergDidRequestMediaFromDevicePicker(filter: WPMediaType, allowMultipleSelection: Bool, with callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       filter: filter,
                                                       dataSourceType: .device,
                                                       allowMultipleSelection: allowMultipleSelection,
                                                       callback: {(assets) in
                                                        guard let phAssets = assets as? [PHAsset] else {
                                                            callback(nil)
                                                            return
                                                        }
                                                        self.mediaInserterHelper.insertFromDevice(assets: phAssets, callback: callback)
        })
    }

    func gutenbergDidRequestMediaFromCameraPicker(filter: WPMediaType, with callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentCameraCaptureFullScreen(animated: true,
                                                         filter: filter,
                                                         callback: {(assets) in
                                                            guard let phAsset = assets?.first as? PHAsset else {
                                                                callback(nil)
                                                                return
                                                            }
                                                            self.mediaInserterHelper.insertFromDevice(asset: phAsset, callback: callback)
        })
    }

    func gutenbergDidRequestImport(from url: URL, with callback: @escaping MediaImportCallback) {
        mediaInserterHelper.insertFromDevice(url: url, callback: { media in
            callback(media?.first)
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
            insertPrePopulatedMedia()
            if isOpenedDirectlyForPhotoPost {
                showMediaSelectionOnStart()
            }
            focusTitleIfNeeded()
            mediaInserterHelper.refreshMediaStatus()
        }
    }

    func gutenbergDidMount(unsupportedBlockNames: [String]) {
        if !editorSession.started {
            editorSession.start(unsupportedBlocks: unsupportedBlockNames)
        }
    }

    func gutenbergDidEmitLog(message: String, logLevel: LogLevel) {
        switch logLevel {
        case .trace:
            DDLogDebug(message)
        case .info:
            DDLogInfo(message)
        case .warn:
            DDLogWarn(message)
        case .error, .fatal:
            DDLogError(message)
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

    func gutenbergMediaSources() -> [Gutenberg.MediaSource] {
        return [
            post.blog.supports(.stockPhotos) ? .stockPhotos : nil,
            .filesApp,
        ].compactMap { $0 }
    }
}

// MARK: - PostEditorStateContextDelegate

extension GutenbergViewController: PostEditorStateContextDelegate {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {
            return
        }

        switch keyPath {
        case BasePost.statusKeyPath:
            if let status = post.status {
                postEditorStateContext.updated(postStatus: status)
            }
        case #keyPath(AbstractPost.date_created_gmt):
            let dateCreated = post.dateCreated ?? Date()
            postEditorStateContext.updated(publishDate: dateCreated)
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {
        reloadPublishButton()
    }

    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {
        reloadPublishButton()
    }

    func reloadPublishButton() {
        navigationBarManager.reloadPublishButton()
    }

    internal func addObservers(toPost: AbstractPost) {
        toPost.addObserver(self, forKeyPath: AbstractPost.statusKeyPath, options: [], context: nil)
        toPost.addObserver(self, forKeyPath: #keyPath(AbstractPost.date_created_gmt), options: [], context: nil)
    }

    internal func removeObservers(fromPost: AbstractPost) {
        fromPost.removeObserver(self, forKeyPath: AbstractPost.statusKeyPath)
        fromPost.removeObserver(self, forKeyPath: #keyPath(AbstractPost.date_created_gmt))
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

    var savingDraftButtonSize: CGSize {
        return AztecPostViewController.Constants.savingDraftButtonSize
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

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, reloadLeftNavigationItems items: [UIBarButtonItem]) {
        navigationItem.leftBarButtonItems = items
    }
}

// MARK: - Constants

extension Gutenberg.MediaSource {
    static let stockPhotos = Gutenberg.MediaSource(id: "wpios-stock-photo-library", label: .freePhotosLibrary, types: [.image])
    static let filesApp = Gutenberg.MediaSource(id: "wpios-files-app", label: .files, types: [.image, .video, .audio, .other])
}

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
