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
    }

    // MARK: - UI

    private var titleTextField: UITextField {
        return containerView.titleTextField
    }

    private var containerView = GutenbergContainerView.loadFromNib()

    // MARK: - Aztec

    private let switchToAztec: (EditorViewController) -> ()

    // MARK: - PostEditor

    var html: String {
        set {
            post.content = newValue
        }
        get {
            return post.content ?? ""
        }
    }

    var postTitle: String

    /// Maintainer of state for editor - like for post button
    ///
    private(set) lazy var postEditorStateContext: PostEditorStateContext = {
        return PostEditorStateContext(post: post, delegate: self)
    }()

    var verificationPromptHelper: VerificationPromptHelper?

    var analyticsEditorSource: String {
        return Analytics.editorSource
    }

    var onClose: ((Bool, Bool) -> Void)?

    var isOpenedDirectlyForPhotoPost: Bool = false

    var isUploadingMedia: Bool {
        return false
    }

    func removeFailedMedia() {
        // TODO
    }

    var shouldRemovePostOnDismiss: Bool = false

    func cancelUploadOfAllMedia(for post: AbstractPost) {
        //TODO
    }

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
            refreshInterface()
        }
    }

    let navigationBarManager = PostEditorNavigationBarManager()

    lazy var attachmentDelegate = AztecAttachmentDelegate(post: post)

    lazy var mediaPickerHelper: GutenbergMediaPickerHelper = {
        return GutenbergMediaPickerHelper(context: self, post: post)
    }()

    var hasFailedMedia: Bool {
        return false
    }

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

    private lazy var gutenberg = Gutenberg(dataSource: self)
    private var requestHTMLReason: RequestHTMLReason?
    private(set) var mode: EditMode = .richText
    private var isFirstGutenbergLayout = true

    // MARK: - Initializers
    required init(
        post: AbstractPost,
        switchToAztec: @escaping (EditorViewController) -> ()) {

        self.post = post
        self.postTitle = post.postTitle ?? ""

        self.switchToAztec = switchToAztec
        verificationPromptHelper = AztecVerificationPromptHelper(account: self.post.blog.account)
        shouldRemovePostOnDismiss = post.hasNeverAttemptedToUpload()

        super.init(nibName: nil, bundle: nil)

        PostCoordinator.shared.cancelAnyPendingSaveOf(post: post)
        navigationBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
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
    }

    func requestHTML(for reason: RequestHTMLReason) {
        requestHTMLReason = reason
        gutenberg.requestHTML()
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
    func gutenbergDidRequestMediaPicker(with callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       dataSourceType: .mediaLibrary,
                                                       callback: callback)
    }

    func gutenbergDidProvideHTML(title: String, html: String, changed: Bool) {
        if changed {
            self.html = html
            self.postTitle = title
        }

        editorContentWasUpdated()

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
                switchToAztec(self)
            case .switchBlog:
                blogPickerWasPressed()
            }
        }
    }

    func gutenbergDidLayout() {
    }
}

// MARK: - GutenbergBridgeDataSource

extension GutenbergViewController: GutenbergBridgeDataSource {
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

// MARK: - Constants

private extension GutenbergViewController {

    enum Analytics {
        static let editorSource = "gutenberg"
    }
}
