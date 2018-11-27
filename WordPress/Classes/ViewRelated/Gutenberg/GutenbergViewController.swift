import UIKit
import React
import WPMediaPicker

class GutenbergViewController: UIViewController, PostEditor {

    let errorDomain: String = "GutenbergViewController.errorDomain"

    enum RequestHTMLReason {
        case publish
        case close
        case more
    }

    // MARK: - UI

    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.heightAnchor.constraint(equalToConstant: Size.titleTextFieldHeight).isActive = true
        textField.font = Fonts.title
        textField.textColor = Colors.title
        textField.backgroundColor = Colors.background
        textField.placeholder = NSLocalizedString("Title", comment: "Placeholder for the post title.")
        let leftView = UIView()
        leftView.translatesAutoresizingMaskIntoConstraints = false
        leftView.heightAnchor.constraint(equalToConstant: Size.titleTextFieldHeight).isActive = true
        leftView.widthAnchor.constraint(equalToConstant: Size.titleTextFieldLeftPadding).isActive = true
        leftView.backgroundColor = Colors.background
        textField.leftView = leftView
        textField.leftViewMode = .always
        return textField
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: Size.titleTextFieldBottomSeparatorHeight).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.separator
        return view
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
        get {
            return titleTextField.text ?? ""
        }
        set {
            titleTextField.text = newValue
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

    func setHTML(_ html: String) {
        self.html = html
        //TODO: Update Gutenberg UI
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

    let navigationBarManager = PostEditorNavigationBarManager()

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

    private let gutenberg: Gutenberg
    private var requestHTMLReason: RequestHTMLReason?
    private(set) var mode: EditMode = .richText

    // MARK: - Initializers
    required init(post: AbstractPost) {
        self.post = post
        self.gutenberg = Gutenberg(props: ["initialData": self.post.content ?? ""])
        self.verificationPromptHelper = AztecVerificationPromptHelper(account: self.post.blog.account)
        self.shouldRemovePostOnDismiss = post.hasNeverAttemptedToUpload()

        super.init(nibName: nil, bundle: nil)
        self.postTitle = post.postTitle ?? ""
        PostCoordinator.shared.cancelAnyPendingSaveOf(post: post)
        navigationBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        gutenberg.invalidate()
    }

    // MARK: - Lifecycle methods
    override func loadView() {
        let stackView = UIStackView(arrangedSubviews: [titleTextField,
                                                       separatorView,
                                                       gutenberg.rootView])
        stackView.axis = .vertical
        stackView.backgroundColor = Colors.background
        view = stackView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createRevisionOfPost()
        configureNavigationBar()
        refreshInterface()
        titleTextField.becomeFirstResponder()

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

        titleTextField.text = post.postTitle
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

    @objc func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return presentationController(forPresented: presented, presenting: presenting)
    }

    func toggleEditingMode() {
        gutenberg.toggleHTMLMode()
        mode.toggle()
    }
}

// MARK: - GutenbergBridgeDelegate

extension GutenbergViewController: GutenbergBridgeDelegate {

    func gutenbergDidRequestMediaPicker(callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       dataSourceType: .mediaLibrary,
                                                       callback: callback)
    }

    func gutenbergDidProvideHTML(_ html: String, changed: Bool) {
        self.html = html
        postEditorStateContext.updated(hasContent: editorHasContent)

        // TODO: currently we don't need to set this because Update button is always active
        // but in the future we might need this
        // postEditorStateContext.updated(hasChanges: changed)

        if let reason = requestHTMLReason {
            requestHTMLReason = nil // clear the reason
            switch reason {
            case .publish:
                handlePublishButtonTap()
            case .close:
                cancelEditing()
            case .more:
                displayMoreSheet()
            }
        }
    }
}

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
        requestHTMLReason = .close
        gutenberg.requestHTML()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {
        requestHTMLReason = .more
        gutenberg.requestHTML()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, blogPickerWasPressed sender: UIButton) {
        blogPickerWasPressed()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        requestHTMLReason = .publish
        gutenberg.requestHTML()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {

    }
}

// MARK: - Constants

private extension GutenbergViewController {

    enum Analytics {
        static let editorSource = "gutenberg"
    }

    enum Colors {
        static let title = UIColor.darkText
        static let separator = WPStyleGuide.greyLighten30()
        static let background = UIColor.white
    }

    enum Fonts {
        static let title = WPFontManager.notoBoldFont(ofSize: 24.0)
    }

    enum Size {
        static let titleTextFieldHeight: CGFloat = 50.0
        static let titleTextFieldLeftPadding: CGFloat = 10.0
        static let titleTextFieldBottomSeparatorHeight: CGFloat = 1.0
    }
}
