import UIKit
import WPMediaPicker
import Gutenberg
import Aztec
import WordPressFlux
import Kanvas

class GutenbergViewController: UIViewController, PostEditor, FeaturedImageDelegate {

    let errorDomain: String = "GutenbergViewController.errorDomain"

    enum RequestHTMLReason {
        case publish
        case close
        case more
        case switchBlog
        case autoSave
    }

    private lazy var stockPhotos: GutenbergStockPhotos = {
        return GutenbergStockPhotos(gutenberg: gutenberg, mediaInserter: mediaInserterHelper)
    }()
    private lazy var filesAppMediaPicker: GutenbergFilesAppMediaSource = {
        return GutenbergFilesAppMediaSource(gutenberg: gutenberg, mediaInserter: mediaInserterHelper)
    }()
    private lazy var tenorMediaPicker: GutenbergTenorMediaPicker = {
        return GutenbergTenorMediaPicker(gutenberg: gutenberg, mediaInserter: mediaInserterHelper)
    }()

    lazy var gutenbergSettings: GutenbergSettings = {
        return GutenbergSettings()
    }()

    let ghostView = GutenGhostView()

    private var storyEditor: StoryEditor?

    private lazy var service: BlogJetpackSettingsService? = {
        guard
            let settings = post.blog.settings,
            let context = settings.managedObjectContext
        else {
            return nil
        }
        return BlogJetpackSettingsService(managedObjectContext: context)
    }()

    // MARK: - Aztec

    var replaceEditor: (EditorViewController, EditorViewController) -> ()

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

    var postIsReblogged: Bool = false

    // MARK: - Editor Media actions

    var isUploadingMedia: Bool {
        return mediaInserterHelper.isUploadingMedia()
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

    private func editMedia(with mediaUrl: URL, callback: @escaping MediaPickerDidPickMediaCallback) {

        let image = GutenbergMediaEditorImage(url: mediaUrl, post: post)

        let mediaEditor = WPMediaEditor(image)
        mediaEditor.editingAlreadyPublishedImage = true

        mediaEditor.edit(from: self,
                         onFinishEditing: { [weak self] images, actions in
                            guard let image = images.first?.editedImage else {
                                // If the image wasn't edited, do nothing
                                return
                            }

                            self?.mediaInserterHelper.insertFromImage(image: image, callback: callback, source: .mediaEditor)
        })
    }

    private func confirmEditingGIF(with mediaUrl: URL, callback: @escaping MediaPickerDidPickMediaCallback) {
        let alertController = UIAlertController(title: GIFAlertStrings.title,
                                                message: GIFAlertStrings.message,
                                                preferredStyle: .alert)

        alertController.addCancelActionWithTitle(GIFAlertStrings.cancel)

        alertController.addActionWithTitle(GIFAlertStrings.edit, style: .destructive) { _ in
            self.editMedia(with: mediaUrl, callback: callback)
        }

        present(alertController, animated: true)
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
            featuredImageHelper = GutenbergFeaturedImageHelper(post: post, gutenberg: gutenberg)
            stockPhotos = GutenbergStockPhotos(gutenberg: gutenberg, mediaInserter: mediaInserterHelper)
            filesAppMediaPicker = GutenbergFilesAppMediaSource(gutenberg: gutenberg, mediaInserter: mediaInserterHelper)
            tenorMediaPicker = GutenbergTenorMediaPicker(gutenberg: gutenberg, mediaInserter: mediaInserterHelper)
            gutenbergImageLoader.post = post
            refreshInterface()
        }
    }

    /// If true, apply autosave content when the editor creates a revision.
    ///
    var loadAutosaveRevision: Bool

    let navigationBarManager = PostEditorNavigationBarManager()

    lazy var attachmentDelegate = AztecAttachmentDelegate(post: post)

    lazy var mediaPickerHelper: GutenbergMediaPickerHelper = {
        return GutenbergMediaPickerHelper(context: self, post: post)
    }()

    lazy var mediaInserterHelper: GutenbergMediaInserterHelper = {
        return GutenbergMediaInserterHelper(post: post, gutenberg: gutenberg)
    }()

    lazy var featuredImageHelper: GutenbergFeaturedImageHelper = {
        return GutenbergFeaturedImageHelper(post: post, gutenberg: gutenberg)
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

    var wordCount: UInt {
        guard let currentMetrics = contentInfo else {
            return 0
        }

        return UInt(currentMetrics.wordCount)
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
    lazy var shouldPresentPhase2informativeDialog: Bool = {
        return gutenbergSettings.shouldPresentInformativeDialog(for: post.blog)
    }()

    internal private(set) var contentInfo: ContentInfo?
    lazy var editorSettingsService: BlockEditorSettingsService? = {
        let blog = post.blog
        guard let context = blog.managedObjectContext else { return nil }

        return BlockEditorSettingsService(blog: blog, context: context)
    }()

    // MARK: - Initializers
    required init(
        post: AbstractPost,
        loadAutosaveRevision: Bool = false,
        replaceEditor: @escaping (EditorViewController, EditorViewController) -> (),
        editorSession: PostEditorAnalyticsSession? = nil) {

        self.post = post
        self.loadAutosaveRevision = loadAutosaveRevision

        self.replaceEditor = replaceEditor
        verificationPromptHelper = AztecVerificationPromptHelper(account: self.post.blog.account)
        self.editorSession = PostEditorAnalyticsSession(editor: .gutenberg, post: post)

        super.init(nibName: nil, bundle: nil)

        addObservers(toPost: post)

        PostCoordinator.shared.cancelAnyPendingSaveOf(post: post)
        navigationBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        tearDownKeyboardObservers()
        removeObservers(fromPost: post)
        gutenberg.invalidate()
        attachmentDelegate.cancelAllPendingMediaRequests()
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardObservers()
        WPFontManager.loadNotoFontFamily()
        createRevisionOfPost(loadAutosaveRevision: loadAutosaveRevision)
        setupGutenbergView()
        configureNavigationBar()
        refreshInterface()

        gutenberg.delegate = self
        fetchBlockSettings()
        presentNewPageNoticeIfNeeded()

        service?.syncJetpackSettingsForBlog(post.blog, success: { [weak self] in
            self?.gutenberg.updateCapabilities()
        }, failure: { (error) in
            DDLogError("Error syncing JETPACK: \(String(describing: error))")
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        verificationPromptHelper?.updateVerificationStatus()
        ghostView.startAnimation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Handles refreshing controls with state context after options screen is dismissed
        storyEditor = nil
        editorContentWasUpdated()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()
        ghostView.frame = view.frame
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        ghostView.frame = view.frame
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Required to work around an issue present in iOS 14 beta 2
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/14460
        if #available(iOS 14.0, *),
            presentedViewController?.view.accessibilityIdentifier == MoreSheetAlert.accessibilityIdentifier {
            dismiss(animated: true)
        }
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
        navigationItem.rightBarButtonItems = navigationBarManager.rightBarButtonItems
        navigationItem.titleView = navigationBarManager.blogTitleViewLabel
    }

    private func reloadBlogTitleView() {
        var blogTitle = post.blog.url ?? String()
        if let blogName = post.blog.settings?.name, blogName.isEmpty == false {
            blogTitle = blogName
        }

        navigationBarManager.reloadBlogTitleView(text: blogTitle)
    }

    private func reloadEditorContents() {
        let content = post.content ?? String()

        setTitle(post.postTitle ?? "")
        setHTML(content)

        SiteSuggestionService.shared.prefetchSuggestionsIfNeeded(for: post.blog) { [weak self] in
            self?.gutenberg.updateCapabilities()
        }
    }

    private func refreshInterface() {
        reloadBlogTitleView()
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
        presentEditingModeSwitchedNotice()
    }

    private func presentEditingModeSwitchedNotice() {
        let message = mode == .html
            ? NSLocalizedString("Switched to HTML mode", comment: "Message of the notice shown when toggling the HTML editor mode")
            : NSLocalizedString("Switched to Visual mode", comment: "Message of the notice shown when toggling the Visual editor mode")
        gutenberg.showNotice(message)
    }

    func requestHTML(for reason: RequestHTMLReason) {
        requestHTMLReason = reason
        gutenberg.requestHTML()
    }

    func focusTitleIfNeeded() {
        guard !post.hasContent(), shouldPresentInformativeDialog == false, shouldPresentPhase2informativeDialog == false else {
            return
        }
        gutenberg.setFocusOnTitle()
    }

    func showEditorHelp() {
        WPAnalytics.track(.gutenbergEditorHelpShown, properties: [:], blog: post.blog)
        gutenberg.showEditorHelp()
    }

    private func presentNewPageNoticeIfNeeded() {
        // Validate if the post is a newly created page or not.
        guard post is Page,
            post.isDraft(),
            post.remoteStatus == AbstractPostRemoteStatus.local else { return }

        let message = post.hasContent() ? NSLocalizedString("Page created", comment: "Notice that a page with content has been created") : NSLocalizedString("Blank page created", comment: "Notice that a page without content has been created")
        gutenberg.showNotice(message)
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

    @objc private func jetpackSettingsControllerDoneButtonPressed() {
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in
                self?.gutenberg.updateCapabilities()
            }
        }
    }

    func gutenbergDidRequestFeaturedImageId(_ mediaID: NSNumber) {
        gutenberg.featuredImageIdNativeUpdated(mediaId: Int32(truncating: mediaID))
    }

    // MARK: - Event handlers

    @objc func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return presentationController(forPresented: presented, presenting: presenting)
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

    func gutenbergDidRequestFetch(path: String, completion: @escaping (Result<Any, NSError>) -> Void) {
        GutenbergNetworkRequest(path: path, blog: post.blog).request(completion: completion)
    }

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
        case .tenor:
            tenorMediaPicker.presentPicker(origin: self,
                                           post: post,
                                           multipleSelection: allowMultipleSelection,
                                           callback: callback)
        case .otherApps, .allFiles:
            filesAppMediaPicker.presentPicker(origin: self, filters: filter, allowedTypesOnBlog: post.blog.allowedTypeIdentifiers, multipleSelection: allowMultipleSelection, callback: callback)
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
            case .any:
                mediaType = mediaType | WPMediaType.all.rawValue
            }
        }

        return WPMediaType(rawValue: mediaType)
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

    func gutenbergDidRequestMediaEditor(with mediaUrl: URL, callback: @escaping MediaPickerDidPickMediaCallback) {

        guard !mediaUrl.isGif else {
            confirmEditingGIF(with: mediaUrl, callback: callback)
            return
        }

        editMedia(with: mediaUrl, callback: callback)
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

    func gutenbergDidRequestToSetFeaturedImage(for mediaID: Int32) {
        let featuredImageId = post.featuredImage?.mediaID

        let presentAlert = { [weak self] in
            guard let `self` = self else { return }

            guard featuredImageId as? Int32 != mediaID else {
                // nothing special to do, trying to set the image that's already set as featured
                return
            }

            guard mediaID != GutenbergFeaturedImageHelper.mediaIdNoFeaturedImageSet else {
                // user tries to clear the featured image setting
                self.featuredImageHelper.setFeaturedImage(mediaID: mediaID)
                return
            }

            guard featuredImageId != nil else {
                // current featured image is not set so, go ahead and set it to the provided one
                self.featuredImageHelper.setFeaturedImage(mediaID: mediaID)
                return
            }

            // ask the user to confirm changing the featured image since there's already one set
            self.showAlertForReplacingFeaturedImage(mediaID: mediaID)
        }

        if presentedViewController != nil {
            dismiss(animated: false, completion: presentAlert)
        } else {
            presentAlert()
        }
    }

    func showAlertForReplacingFeaturedImage(mediaID: Int32) {
        let alertController = UIAlertController(title: NSLocalizedString("Featured Image Already Set", comment: "Title message on dialog that prompts user to confirm or cancel the replacement of a featured image."),
                                                message: NSLocalizedString("You already have a featured image set. Do you want to replace it?", comment: "Main message on dialog that prompts user to confirm or cancel the replacement of a featured image."),
                                                preferredStyle: .actionSheet)

        let replaceAction = UIAlertAction(title: NSLocalizedString("Replace", comment: "Button to confirm the replacement of a featured image."), style: .default) { (action) in
            self.featuredImageHelper.setFeaturedImage(mediaID: mediaID)
        }

        alertController.addAction(replaceAction)
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Button to cancel the replacement of a featured image."))

        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = view.bounds
        alertController.popoverPresentationController?.permittedArrowDirections = []

        present(alertController, animated: true, completion: nil)
    }

    struct AnyEncodable: Encodable {

        let value: Encodable
        init(value: Encodable) {
            self.value = value
        }

        func encode(to encoder: Encoder) throws {
            try value.encode(to: encoder)
        }

    }

    func gutenbergDidRequestMediaFilesEditorLoad(_ mediaFiles: [[String: Any]], blockId: String) {

        if mediaFiles.isEmpty {
            WPAnalytics.track(.storyBlockAddMediaTapped)
        }

        let files = mediaFiles.compactMap({ content -> MediaFile? in
            return MediaFile.file(from: content)
        })

        // If the story editor is already shown, ignore this new load request
        guard presentedViewController is StoryEditor == false else {
            return
        }

        do {
            try showEditor(files: files, blockID: blockId)
        } catch let error {
            switch error {
            case StoryEditor.EditorCreationError.unsupportedDevice:
                let title = NSLocalizedString("Unsupported Device", comment: "Title for stories unsupported device error.")
                let message = NSLocalizedString("The Stories editor is not currently available for your iPad. Please try Stories on your iPhone.", comment: "Message for stories unsupported device error.")
                let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
                let dismiss = UIAlertAction(title: "Dismiss", style: .default) { _ in
                    controller.dismiss(animated: true, completion: nil)
                }
                controller.addAction(dismiss)
                present(controller, animated: true, completion: nil)
            default:
                let title = NSLocalizedString("Unable to Create Stories Editor", comment: "Title for stories unknown error.")
                let message = NSLocalizedString("There was a problem with the Stories editor.  If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Message for stories unknown error.")
                let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
                let dismiss = UIAlertAction(title: "Dismiss", style: .default) { _ in
                    controller.dismiss(animated: true, completion: nil)
                }
                controller.addAction(dismiss)
                present(controller, animated: true, completion: nil)
            }
        }
    }

    func showEditor(files: [MediaFile], blockID: String) throws {
        storyEditor = try StoryEditor.editor(post: post, mediaFiles: files, publishOnCompletion: false, updated: { [weak self] result in
            switch result {
            case .success(let content):
                self?.gutenberg.replace(blockID: blockID, content: content)
                self?.dismiss(animated: true, completion: nil)
            case .failure(let error):
                self?.dismiss(animated: true, completion: nil)
                DDLogError("Failed to update story: \(error)")
            }
        })

        storyEditor?.trackOpen()
        storyEditor?.present(on: self, with: files)
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

    func editorHasContent(title: String, content: String) -> Bool {
        let hasTitle = !title.isEmpty
        var hasContent = !content.isEmpty
        if let contentInfo = contentInfo {
            let isEmpty = contentInfo.blockCount == 0
            let isOneEmptyParagraph = (contentInfo.blockCount == 1 && contentInfo.paragraphCount == 1 && contentInfo.characterCount == 0)
            hasContent = !(isEmpty || isOneEmptyParagraph)
        }
        return hasTitle || hasContent
    }

    func gutenbergDidProvideHTML(title: String, html: String, changed: Bool, contentInfo: ContentInfo?) {
        if changed {
            self.html = html
            self.postTitle = title
        }
        self.contentInfo = contentInfo
        editorContentWasUpdated()
        mapUIContentToPostAndSave(immediate: true)
        if let reason = requestHTMLReason {
            requestHTMLReason = nil // clear the reason
            switch reason {
            case .publish:
                if editorHasContent(title: title, content: html) {
                    handlePublishButtonTap()
                } else {
                    showAlertForEmptyPostPublish()
                }
            case .close:
                cancelEditing()
            case .more:
                displayMoreSheet()
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
            let galleryWithImageBlocks = gutenbergEditorSettings()?.galleryWithImageBlocks

            // Note that this method is also used to track startup performance
            // It assumes this is being called when the editor has finished loading
            // If you need to refactor this, please ensure that the startup_time_ms property
            // is still reflecting the actual startup time of the editor
            editorSession.start(unsupportedBlocks: unsupportedBlockNames, galleryWithImageBlocks: galleryWithImageBlocks)
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

    func gutenbergDidRequestUnsupportedBlockFallback(for block: Block) {
        do {
            let controller = try GutenbergWebNavigationController(with: post, block: block)
            showGutenbergWeb(controller)
        } catch {
            DDLogError("Error loading Gutenberg Web with unsupported block: \(error)")
            return showUnsupportedBlockUnexpectedErrorAlert()
        }
    }

    func showGutenbergWeb(_ controller: GutenbergWebNavigationController) {
        controller.onSave = { [weak self] newBlock in
            self?.gutenberg.replace(block: newBlock)
        }
        present(controller, animated: true)
    }

    func showUnsupportedBlockUnexpectedErrorAlert() {
        WPError.showAlert(
            withTitle: NSLocalizedString("Error", comment: "Generic error alert title"),
            message: NSLocalizedString("There has been an unexpected error.", comment: "Generic error alert message"),
            withSupportButton: false
        )
    }

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

    func gutenbergDidRequestMention(callback: @escaping (Swift.Result<String, NSError>) -> Void) {
        DispatchQueue.main.async(execute: { [weak self] in
            self?.showSuggestions(type: .mention, callback: callback)
        })
    }

    func gutenbergDidRequestXpost(callback: @escaping (Swift.Result<String, NSError>) -> Void) {
        DispatchQueue.main.async(execute: { [weak self] in
            self?.showSuggestions(type: .xpost, callback: callback)
        })
    }

    func gutenbergDidRequestFocalPointPickerTooltipShown() -> Bool {
        return gutenbergSettings.focalPointPickerTooltipShown
    }

    func gutenbergDidRequestSetFocalPointPickerTooltipShown(_ tooltipShown: Bool) {
        gutenbergSettings.focalPointPickerTooltipShown = tooltipShown
    }

    func gutenbergDidSendButtonPressedAction(_ buttonType: Gutenberg.ActionButtonType) {
        switch buttonType {
            case .missingBlockAlertActionButton:
                handleMissingBlockAlertButtonPressed()
        }
    }

    func gutenbergDidRequestPreview() {
        displayPreview()
    }

    func gutenbergDidRequestBlockTypeImpressions() -> [String: Int] {
        return gutenbergSettings.blockTypeImpressions
    }

    func gutenbergDidRequestSetBlockTypeImpressions(_ impressions: [String: Int]) -> Void {
        gutenbergSettings.blockTypeImpressions = impressions
    }

    func gutenbergDidRequestContactCustomerSupport() {
        ZendeskUtils.sharedInstance.showNewRequestIfPossible(from: self.topmostPresentedViewController, with: .editorHelp )
    }

    func gutenbergDidRequestGotoCustomerSupportOptions() {
        let controller = SupportTableViewController()
        let navController = UINavigationController(rootViewController: controller)
        self.topmostPresentedViewController.present(navController, animated: true)
    }

    func gutenbergDidRequestSendEventToHost(_ eventName: String, properties: [AnyHashable: Any]) -> Void {
        WPAnalytics.trackBlockEditorEvent(eventName, properties: properties, blog: post.blog)
    }
}

// MARK: - Suggestions implementation

extension GutenbergViewController {

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

extension GutenbergViewController: GutenbergBridgeDataSource {
    var isPreview: Bool {
        return false
    }

    var loadingView: UIView? {
        return ghostView
    }

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

    func gutenbergFeaturedImageId() -> NSNumber? {
        return post.featuredImage?.mediaID
    }

    func gutenbergPostType() -> String {
        return post is Page ? "page" : "post"
    }

    func aztecAttachmentDelegate() -> TextViewAttachmentDelegate {
        return attachmentDelegate
    }

    func gutenbergMediaSources() -> [Gutenberg.MediaSource] {
        return [
            post.blog.supports(.stockPhotos) ? .stockPhotos : nil,
            .tenor,
            .otherApps,
            .allFiles,
        ].compactMap { $0 }
    }

    func gutenbergCapabilities() -> [Capabilities: Bool] {
        let isFreeWPCom = post.blog.isHostedAtWPcom && !post.blog.hasPaidPlan
        let isWPComSite = post.blog.isHostedAtWPcom || post.blog.isAtomic()
        return [
            .mentions: SuggestionService.shared.shouldShowSuggestions(for: post.blog),
            .xposts: SiteSuggestionService.shared.shouldShowSuggestions(for: post.blog),
            .contactInfoBlock: post.blog.supports(.contactInfo),
            .layoutGridBlock: post.blog.supports(.layoutGrid),
            .unsupportedBlockEditor: isUnsupportedBlockEditorEnabled,
            .canEnableUnsupportedBlockEditor: post.blog.jetpack?.isConnected ?? false,
            .isAudioBlockMediaUploadEnabled: !isFreeWPCom,
            .mediaFilesCollectionBlock: post.blog.supports(.stories) && !UIDevice.isPad(),
            // Only enable reusable block in WP.com sites until the issue
            // (https://github.com/wordpress-mobile/gutenberg-mobile/issues/3457) in self-hosted sites is fixed
            .reusableBlock: isWPComSite,
            // Jetpack embeds
            .facebookEmbed: post.blog.supports(.facebookEmbed),
            .instagramEmbed: post.blog.supports(.instagramEmbed),
            .loomEmbed: post.blog.supports(.loomEmbed),
            .smartframeEmbed: post.blog.supports(.smartframeEmbed)
        ]
    }

    private var isUnsupportedBlockEditorEnabled: Bool {
        // The Unsupported Block Editor is disabled for all self-hosted non-jetpack sites.
        // This is because they can have their web editor to be set to classic and then the fallback will not work.

        let blog = post.blog
        let isJetpackSSOEnabled = (blog.jetpack?.isConnected ?? false) && (blog.settings?.jetpackSSOEnabled ?? false)

        return blog.isHostedAtWPcom || isJetpackSSOEnabled
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
         return postEditorStateContext.isPublishButtonEnabled
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

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, reloadTitleView view: UIView) {
        navigationItem.titleView = view
    }
}

// MARK: - Constants

extension Gutenberg.MediaSource {
    static let stockPhotos = Gutenberg.MediaSource(id: "wpios-stock-photo-library", label: .freePhotosLibrary, types: [.image])
    static let otherApps = Gutenberg.MediaSource(id: "wpios-other-files", label: .otherApps, types: [.image, .video, .audio, .other])
    static let allFiles = Gutenberg.MediaSource(id: "wpios-all-files", label: .otherApps, types: [.any])
    static let tenor = Gutenberg.MediaSource(id: "wpios-tenor", label: .tenor, types: [.image])
}

private extension GutenbergViewController {
    enum Analytics {
        static let editorSource = "gutenberg"
    }

}

private extension GutenbergViewController {

    struct EmptyPostActionSheet {
        static let titlePost = NSLocalizedString("Can't publish an empty post", comment: "Alert message that is shown when trying to publish empty post")
        static let titlePage = NSLocalizedString("Can't publish an empty page", comment: "Alert message that is shown when trying to publish empty page")
        static let message = NSLocalizedString("Please add some content before trying to publish.", comment: "Suggestion to add content before trying to publish post or page")
    }

    struct MediaAttachmentActionSheet {
        static let title = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
        static let dismissActionTitle = NSLocalizedString("Dismiss", comment: "User action to dismiss media options.")
        static let stopUploadActionTitle = NSLocalizedString("Stop upload", comment: "User action to stop upload.")
        static let retryUploadActionTitle = NSLocalizedString("Retry", comment: "User action to retry media upload.")
        static let retryAllFailedUploadsActionTitle = NSLocalizedString("Retry all", comment: "User action to retry all failed media uploads.")
    }
}

// Block Editor Settings
extension GutenbergViewController {

    // GutenbergBridgeDataSource
    func gutenbergEditorSettings() -> GutenbergEditorSettings? {
        return editorSettingsService?.cachedSettings
    }

    private func fetchBlockSettings() {
        editorSettingsService?.fetchSettings({ [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let response):
                if response.hasChanges {
                    self.gutenberg.updateEditorSettings(response.blockEditorSettings)
                }
            case .failure(let err):
                DDLogError("Error fetching settings: \(err)")
            }
        })
    }
}
