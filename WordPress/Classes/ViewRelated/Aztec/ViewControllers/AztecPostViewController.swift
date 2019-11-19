import Foundation
import UIKit
import PDFKit
import Aztec
import CocoaLumberjack
import Gridicons
import WordPressShared
import MobileCoreServices
import WordPressEditor
import WPMediaPicker
import AVKit
import MobileCoreServices
import AutomatticTracks

// MARK: - Aztec's Native Editor!
//
class AztecPostViewController: UIViewController, PostEditor {

    // MARK: - PostEditor conformance

    /// Closure to be executed when the editor gets closed.
    /// Pass `false` for `showPostEpilogue` to prevent the post epilogue
    /// (PostPost) flow being displayed after the editor is closed.
    ///
    var onClose: ((_ changesSaved: Bool, _ showPostEpilogue: Bool) -> ())?

    /// Verification Prompt Helper
    ///
    /// - Returns: `nil` when there's no need for showing the verification prompt.
    var verificationPromptHelper: VerificationPromptHelper? {
        return aztecVerificationPromptHelper
    }

    fileprivate lazy var aztecVerificationPromptHelper: AztecVerificationPromptHelper? = {
        return AztecVerificationPromptHelper(account: self.post.blog.account)
    }()

    var postTitle: String {
        get {
            return titleTextField.text
        }
        set {
            titleTextField.text = newValue
        }
    }

    var isUploadingMedia: Bool {
        return mediaCoordinator.isUploadingMedia(for: post)
    }

    var analyticsEditorSource: String {
        return Analytics.editorSource
    }

    var editorSession: PostEditorAnalyticsSession

    /// Indicates if Aztec was launched for Photo Posting
    ///
    var isOpenedDirectlyForPhotoPost = false

    let navigationBarManager = PostEditorNavigationBarManager()

    let mediaUtility = EditorMediaUtility()

    func cancelUploadOfAllMedia(for post: AbstractPost) {
        mediaCoordinator.cancelUploadOfAllMedia(for: post)
    }

    /// For autosaving - The debouncer will execute local saving every defined number of seconds.
    /// In this case every 0.5 second
    ///
    fileprivate(set) lazy var debouncer: Debouncer = {
        return Debouncer(delay: PostEditorDebouncerConstants.autoSavingDelay, callback: debouncerCallback)
    }()

    lazy var autosaver = Autosaver { [weak self] in
        self?.mapUIContentToPostAndSave(immediate: true)
    }

    // MARK: - Styling Options

    private lazy var optionsTablePresenter = OptionsTablePresenter(presentingViewController: self, presentingTextView: editorView.richTextView)

    // MARK: - Editor Replacing Support

    internal let replaceEditor: (EditorViewController, EditorViewController) -> ()

    // MARK: - fileprivate & private variables

    /// Format Bar
    ///
    fileprivate(set) lazy var formatBar: Aztec.FormatBar = {
        return self.createToolbar()
    }()

    let errorDomain = "AztecPostViewController.errorDomain"

    private enum ErrorCode: Int {
        case expectedSecondaryAction = 1
    }

    /// The editor view.
    ///
    fileprivate(set) lazy var editorView: Aztec.EditorView = {

        let paragraphStyle = ParagraphStyle.default

        // Paragraph style customizations will go here.
        paragraphStyle.lineSpacing = 4

        let editorView = Aztec.EditorView(
            defaultFont: Fonts.regular,
            defaultHTMLFont: Fonts.monospace,
            defaultParagraphStyle: paragraphStyle,
            defaultMissingImage: Assets.defaultMissingImage)

        editorView.clipsToBounds = false
        editorView.htmlStorage.textColor = .text
        setupHTMLTextView(editorView.htmlTextView)
        setupRichTextView(editorView.richTextView)

        return editorView
    }()

    private var analyticsEditor: PostEditorAnalyticsSession.Editor {
        switch editorView.editingMode {
        case .richText:
            return .classic
        case .html:
            return .html
        }
    }

    /// Aztec's Awesomeness
    ///
    private var richTextView: Aztec.TextView {
        get {
            return editorView.richTextView
        }
    }

    private func setupRichTextView(_ textView: TextView) {
        textView.load(WordPressPlugin())

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        let linkAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                             .foregroundColor: Colors.aztecLinkColor]

        textView.delegate = self
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self

        textView.backgroundColor = Colors.aztecBackground
        textView.blockquoteBackgroundColor = .neutral(.shade5)
        textView.blockquoteBorderColor = .listIcon
        textView.preBackgroundColor = .neutral(.shade5)

        textView.linkTextAttributes = linkAttributes

        // We need this false to be able to set negative `scrollInset` values.
        textView.clipsToBounds = false

        textView.smartDashesType = .no
        textView.smartQuotesType = .no

        // Set up the editor for screenshot generation, if needed
        if UIApplication.shared.isCreatingScreenshots() {
            textView.autocorrectionType = .no
        }

        disableLinkTapRecognizer(from: textView)
    }

    /**
    This handles a bug introduced by iOS 13.0 (tested up to 13.2) where link interactions don't respect what the documentation says.
    The documenatation for textView(_:shouldInteractWith:in:interaction:) says:
    > Links in text views are interactive only if the text view is selectable but noneditable.
    Our Aztec Text views are selectable and editable, and yet iOS was opening links on Safari when tapped.
    */
    fileprivate func disableLinkTapRecognizer(from textView: UITextView) {
        guard let recognizer = textView.gestureRecognizers?.first(where: { $0.name == "UITextInteractionNameLinkTap" }) else {
            return
        }
        recognizer.isEnabled = false
    }

    /// Aztec's Text Placeholder
    ///
    fileprivate(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Share your story here...", comment: "Aztec's Text Placeholder")
        label.textColor = Colors.placeholder
        label.font = Fonts.regular
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .natural
        label.accessibilityIdentifier = "aztec-content-placeholder"
        return label
    }()


    /// Raw HTML Editor
    ///
    private var htmlTextView: UITextView {
        get {
            return editorView.htmlTextView
        }
    }

    private func setupHTMLTextView(_ textView: UITextView) {
        let accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        textView.isHidden = true
        textView.delegate = self
        textView.accessibilityIdentifier = "HTMLContentView"
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none

        // We need this false to be able to set negative `scrollInset` values.
        textView.clipsToBounds = false

        textView.adjustsFontForContentSizeCategory = true
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }


    /// Title's UITextView
    ///
    fileprivate(set) lazy var titleTextField: UITextView = {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .natural

        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.text,
                                                        .font: Fonts.title,
                                                        .paragraphStyle: titleParagraphStyle]

        let textView = UITextView()

        textView.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        textView.delegate = self
        textView.font = Fonts.title
        textView.returnKeyType = .next
        textView.textColor = .text
        textView.typingAttributes = attributes
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .natural
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.spellCheckingType = .default

        return textView
    }()


    /// Placeholder Label
    ///
    fileprivate(set) lazy var titlePlaceholderLabel: UILabel = {
        let placeholderText = NSLocalizedString("Title", comment: "Placeholder for the post title.")
        let titlePlaceholderLabel = UILabel()

        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: Colors.placeholder, .font: Fonts.title]

        titlePlaceholderLabel.attributedText = NSAttributedString(string: placeholderText, attributes: attributes)
        titlePlaceholderLabel.sizeToFit()
        titlePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        titlePlaceholderLabel.textAlignment = .natural

        return titlePlaceholderLabel
    }()


    /// Title's Height Constraint
    ///
    fileprivate var titleHeightConstraint: NSLayoutConstraint!


    /// Title's Top Constraint
    ///
    fileprivate var titleTopConstraint: NSLayoutConstraint!


    /// Placeholder's Top Constraint
    ///
    fileprivate var textPlaceholderTopConstraint: NSLayoutConstraint!


    /// Separator View
    ///
    fileprivate(set) lazy var separatorView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))

        v.backgroundColor = Colors.separator
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()

    /// Active Editor's Mode
    ///
    /*
    fileprivate(set) var mode = EditMode.richText {
        willSet {
            switch mode {
            case .html:
                setHTML(getHTML(), for: .richText)
            case .richText:
                setHTML(getHTML(), for: .html)
            }
        }

        didSet {
            switch mode {
            case .html:
                htmlTextView.becomeFirstResponder()
            case .richText:
                richTextView.becomeFirstResponder()
            }

            updateFormatBar()

            refreshPlaceholderVisibility()
            refreshTitlePosition()
        }
    }*/


    /// Post being currently edited
    ///
    var post: AbstractPost {
        didSet {
            removeObservers(fromPost: oldValue)
            addObservers(toPost: post)
            unregisterMediaObserver()
            registerMediaObserver()
            postEditorStateContext = createEditorStateContext(for: post)
            refreshInterface()
        }
    }

    /// Active Downloads
    ///
    fileprivate var activeMediaRequests = [ImageDownloader.Task]()

    /// Media Library Data Source
    ///
    lazy var mediaLibraryDataSource: MediaLibraryPickerDataSource = {
        return MediaLibraryPickerDataSource(post: self.post)
    }()

    /// Device Photo Library Data Source
    ///
    fileprivate lazy var devicePhotoLibraryDataSource = WPPHAssetDataSource()

    fileprivate let mediaCoordinator = MediaCoordinator.shared

    /// Media Progress View
    ///
    fileprivate lazy var mediaProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.backgroundColor = Colors.progressBackground
        progressView.progressTintColor = Colors.progressTint
        progressView.trackTintColor = Colors.progressTrack
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        return progressView
    }()

    fileprivate var mediaObserverReceipt: UUID?

    /// Selected Text Attachment
    ///
    fileprivate var currentSelectedAttachment: MediaAttachment?


    /// Last Interface Element that was a First Responder
    ///
    fileprivate var lastFirstResponder: UIView?


    /// Maintainer of state for editor - like for post button
    ///
    fileprivate(set) lazy var postEditorStateContext: PostEditorStateContext = {
        return self.createEditorStateContext(for: self.post)
    }()

    /// Current keyboard rect used to help size the inline media picker
    ///
    fileprivate var currentKeyboardFrame: CGRect = .zero


    /// Method of selecting media for upload, used for analytics
    ///
    fileprivate var mediaSelectionMethod: MediaSelectionMethod = .none

    /// Media Picker
    ///
    fileprivate lazy var insertToolbarItem: UIButton = {
        let insertItem = UIButton(type: .custom)
        insertItem.titleLabel?.font = Fonts.mediaPickerInsert
        insertItem.tintColor = .primary
        insertItem.setTitleColor(.primary, for: .normal)

        return insertItem
    }()

    fileprivate var mediaPickerInputViewController: WPInputMediaPickerViewController?

    fileprivate var originalLeadingBarButtonGroup = [UIBarButtonItemGroup]()

    fileprivate var originalTrailingBarButtonGroup = [UIBarButtonItemGroup]()

    /// The view to show when media picker has no assets to show.
    ///
    fileprivate let noResultsView = NoResultsViewController.controller()

    fileprivate var mediaLibraryChangeObserverKey: NSObjectProtocol? = nil


    /// Presents whatever happens when FormatBar's more button is selected
    ///
    fileprivate lazy var moreCoordinator: AztecMediaPickingCoordinator = {
        return AztecMediaPickingCoordinator(delegate: self)
    }()


    /// Helps choosing the correct view controller for previewing a media asset
    ///
    private var mediaPreviewHelper: MediaPreviewHelper? = nil

    // MARK: - Initializers

    /// Initializer
    ///
    /// - Parameters:
    ///     - post: the post to edit in this VC.  Must be already assigned to a `ManagedObjectContext`
    ///             since that's necessary for the edits to be saved.
    ///
    required init(
        post: AbstractPost,
        replaceEditor: @escaping (EditorViewController, EditorViewController) -> (),
        editorSession: PostEditorAnalyticsSession? = nil) {

        precondition(post.managedObjectContext != nil)

        self.post = post
        self.replaceEditor = replaceEditor
        self.editorSession = editorSession ?? PostEditorAnalyticsSession(editor: .classic, post: post)

        super.init(nibName: nil, bundle: nil)

        PostCoordinator.shared.cancelAnyPendingSaveOf(post: post)
        addObservers(toPost: post)
        registerMediaObserver()
    }

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure("Aztec Post View Controller must be initialized by code")
    }

    deinit {
        removeObservers(fromPost: post)
        unregisterMediaObserver()
        cancelAllPendingMediaRequests()
    }


    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBarManager.delegate = self

        richTextView.isScrollEnabled = false
        htmlTextView.isScrollEnabled = false
        // This needs to called first
        configureMediaAppearance()

        // TODO: Fix the warnings triggered by this one!
        WPFontManager.loadNotoFontFamily()

        registerAttachmentImageProviders()
        createRevisionOfPost()

        // Setup
        configureNavigationBar()
        configureView()
        configureSubviews()
        noResultsView.configureForNoAssets(userCanUploadMedia: false)

        // UI elements might get their properties reset when the view is effectively loaded. Refresh it all!
        refreshInterface()

        // Setup Autolayout
        configureConstraints()
        view.setNeedsUpdateConstraints()

        if isOpenedDirectlyForPhotoPost {
            presentMediaPickerFullScreen(animated: false)
        }

        if !editorSession.started {
            editorSession.start()
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resetNavigationColors()
        configureDismissButton()
        startListeningToNotifications()
        verificationPromptHelper?.updateVerificationStatus()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        restoreFirstResponder()

        // Handles refreshing controls with state context after options screen is dismissed
        editorContentWasUpdated()

        richTextView.isScrollEnabled = true
        htmlTextView.isScrollEnabled = true
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopListeningToNotifications()
        rememberFirstResponder()
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.updateTitleHeight()
        })

        optionsTablePresenter.dismiss()
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        guard let navigationController = parent as? UINavigationController else {
            return
        }

        /// Wire AztecNavigationControllerDelegate
        ///
        navigationController.delegate = self
        configureMediaProgressView(in: navigationController.navigationBar)
    }


    // MARK: - Title and Title placeholder position methods

    func refreshTitlePosition() {
        let referenceView = editorView.activeView

        titleTopConstraint.constant = -(referenceView.contentOffset.y + referenceView.contentInset.top)

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset

        textPlaceholderTopConstraint.constant = referenceView.textContainerInset.top + referenceView.contentInset.top
    }

    func updateTitleHeight() {
        let referenceView = editorView.activeView
        let layoutMargins = view.layoutMargins
        let insets = titleTextField.textContainerInset

        var titleWidth = titleTextField.bounds.width
        if titleWidth <= 0 {
            // Use the title text field's width if available, otherwise calculate it.
            titleWidth = view.frame.width - (insets.left + insets.right + layoutMargins.left + layoutMargins.right)
        }

        let sizeThatShouldFitTheContent = titleTextField.sizeThatFits(CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude))
        titleHeightConstraint.constant = max(sizeThatShouldFitTheContent.height, titleTextField.font!.lineHeight + insets.top + insets.bottom)

        textPlaceholderTopConstraint.constant = referenceView.textContainerInset.top + referenceView.contentInset.top

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset
        referenceView.setContentOffset(CGPoint(x: 0, y: -contentInset.top), animated: false)

        updateScrollInsets()
    }

    func updateScrollInsets() {
        let referenceView = editorView.activeView
        var scrollInsets = referenceView.contentInset
        var rightMargin = (view.frame.maxX - referenceView.frame.maxX)
        rightMargin -= view.safeAreaInsets.right
        scrollInsets.right = -rightMargin
        referenceView.scrollIndicatorInsets = scrollInsets
    }


    // MARK: - Construction Helpers

    /// Returns a new Editor Context for a given Post instance.
    ///
    private func createEditorStateContext(for post: AbstractPost) -> PostEditorStateContext {
        return PostEditorStateContext(post: post, delegate: self)
    }

    // MARK: - Configuration Methods

    override func updateViewConstraints() {
        refreshTitlePosition()
        updateTitleHeight()
        super.updateViewConstraints()
    }

    func configureConstraints() {

        titleHeightConstraint = titleTextField.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
        titleTopConstraint = titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: -richTextView.contentOffset.y)
        textPlaceholderTopConstraint = placeholderLabel.topAnchor.constraint(equalTo: richTextView.topAnchor, constant: richTextView.textContainerInset.top + richTextView.contentInset.top)
        updateTitleHeight()

        NSLayoutConstraint.activate([
            titleTextField.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            titleTextField.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            titleTopConstraint,
            titleHeightConstraint
            ])

        let insets = titleTextField.textContainerInset

        NSLayoutConstraint.activate([
            titlePlaceholderLabel.leftAnchor.constraint(equalTo: titleTextField.leftAnchor, constant: insets.left + titleTextField.textContainer.lineFragmentPadding),
            titlePlaceholderLabel.rightAnchor.constraint(equalTo: titleTextField.rightAnchor, constant: -insets.right - titleTextField.textContainer.lineFragmentPadding),
            titlePlaceholderLabel.topAnchor.constraint(equalTo: titleTextField.topAnchor, constant: insets.top),
            titlePlaceholderLabel.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
            ])

        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: separatorView.frame.height)
            ])

        NSLayoutConstraint.activate([
            richTextView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            richTextView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            richTextView.topAnchor.constraint(equalTo: view.topAnchor),
            richTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            htmlTextView.leftAnchor.constraint(equalTo: richTextView.leftAnchor),
            htmlTextView.rightAnchor.constraint(equalTo: richTextView.rightAnchor),
            htmlTextView.topAnchor.constraint(equalTo: richTextView.topAnchor),
            htmlTextView.bottomAnchor.constraint(equalTo: richTextView.bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            placeholderLabel.leftAnchor.constraint(equalTo: richTextView.leftAnchor, constant: insets.left + richTextView.textContainer.lineFragmentPadding),
            placeholderLabel.rightAnchor.constraint(equalTo: richTextView.rightAnchor, constant: -insets.right - richTextView.textContainer.lineFragmentPadding),
            textPlaceholderTopConstraint,
            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: richTextView.bottomAnchor, constant: Constants.placeholderPadding.bottom)
            ])
    }

    private func configureDefaultProperties(for textView: UITextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.keyboardDismissMode = .interactive
        textView.textColor = .text
        textView.translatesAutoresizingMaskIntoConstraints = false
    }

    func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.accessibilityIdentifier = "Azctec Editor Navigation Bar"
        navigationItem.leftBarButtonItems = navigationBarManager.leftBarButtonItems
        navigationItem.rightBarButtonItems = navigationBarManager.rightBarButtonItems
    }

    /// This is to restore the navigation bar colors after the UIDocumentPickerViewController has been dismissed,
    /// either by uploading media or canceling. Doing this in the UIDocumentPickerDelegate methods either did
    /// nothing or the resetting wasn't permanent.
    ///
    fileprivate func resetNavigationColors() {
        WPStyleGuide.configureNavigationAppearance()
    }

    func configureDismissButton() {
        let image = isModal() ? Assets.closeButtonModalImage : Assets.closeButtonRegularImage
        navigationBarManager.closeButton.setImage(image, for: .normal)
    }

    func configureView() {
        edgesForExtendedLayout = UIRectEdge()
        view.backgroundColor = Colors.aztecBackground
    }

    func configureSubviews() {
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)
        view.addSubview(titleTextField)
        view.addSubview(titlePlaceholderLabel)
        view.addSubview(separatorView)
        view.addSubview(placeholderLabel)
    }

    func configureMediaProgressView(in navigationBar: UINavigationBar) {
        guard mediaProgressView.superview == nil else {
            return
        }

        navigationBar.addSubview(mediaProgressView)

        NSLayoutConstraint.activate([
            mediaProgressView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            mediaProgressView.widthAnchor.constraint(equalTo: navigationBar.widthAnchor),
            mediaProgressView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -mediaProgressView.frame.height)
            ])
    }

    func registerAttachmentImageProviders() {
        let providers: [TextViewAttachmentImageProvider] = [
            SpecialTagAttachmentRenderer(),
            CommentAttachmentRenderer(font: Fonts.regular),
            HTMLAttachmentRenderer(font: Fonts.regular),
            GutenpackAttachmentRenderer()
        ]

        for provider in providers {
            richTextView.registerAttachmentImageProvider(provider)
        }
    }

    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(didUndoRedo), name: .NSUndoManagerDidUndoChange, object: nil)
        nc.addObserver(self, selector: #selector(didUndoRedo), name: .NSUndoManagerDidRedoChange, object: nil)
    }

    func stopListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        nc.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        nc.removeObserver(self, name: .NSUndoManagerDidUndoChange, object: nil)
        nc.removeObserver(self, name: .NSUndoManagerDidRedoChange, object: nil)
    }

    func rememberFirstResponder() {
        lastFirstResponder = view.findFirstResponder() ?? lastFirstResponder
        lastFirstResponder?.resignFirstResponder()
    }

    func restoreFirstResponder() {
        let nextFirstResponder = lastFirstResponder ?? titleTextField
        nextFirstResponder.becomeFirstResponder()
        lastFirstResponder = nil
    }

    func refreshInterface() {
        reloadBlogPickerButton()
        reloadEditorContents()
        reloadPublishButton()
        refreshNavigationBar()
    }

    func refreshNavigationBar() {
        if postEditorStateContext.isUploadingMedia {
            navigationItem.leftBarButtonItems = navigationBarManager.uploadingMediaLeftBarButtonItems
        } else {
            navigationItem.leftBarButtonItems = navigationBarManager.leftBarButtonItems
        }
    }

    func setHTML(_ html: String) {
        editorView.setHTML(html)

        if editorView.editingMode == .richText {
            processMediaAttachments()
        }
    }
/*
    private func setHTML(_ html: String, for mode: EditMode) {
        switch mode {
        case .html:
            htmlTextView.text = html
        case .richText:
            richTextView.setHTML(html)

            processMediaAttachments()
        }
    }*/

    func getHTML() -> String {
        return editorView.getHTML()
/*
        let html: String

        switch mode {
        case .html:
            html = htmlTextView.text
        case .richText:
            html = richTextView.getHTML()
        }

        return html*/
    }

    func reloadEditorContents() {
        let content = post.content ?? String()

        titleTextField.text = post.postTitle
        setHTML(content)
    }

    func reloadBlogPickerButton() {
        var pickerTitle = post.blog.url ?? String()
        if let blogName = post.blog.settings?.name, blogName.isEmpty == false {
            pickerTitle = blogName
        }

        navigationBarManager.reloadBlogPickerButton(with: pickerTitle, enabled: !isSingleSiteMode)
    }

    func reloadPublishButton() {
        navigationBarManager.reloadPublishButton()
    }

    fileprivate func updateSearchBar(mediaPicker: WPMediaPickerViewController) {
        let isSearching = mediaLibraryDataSource.searchQuery?.count ?? 0 != 0
        let hasAssets = mediaLibraryDataSource.totalAssetCount > 0

        if isSearching || hasAssets {
            mediaPicker.showSearchBar()
            if let searchBar = mediaPicker.searchBar {
                WPStyleGuide.configureSearchBar(searchBar)
            }
        } else {
            mediaPicker.hideSearchBar()
        }
    }

    fileprivate func registerChangeObserver(forPicker picker: WPMediaPickerViewController) {
        assert(mediaLibraryChangeObserverKey == nil)
        mediaLibraryChangeObserverKey = mediaLibraryDataSource.registerChangeObserverBlock({ [weak self] _, _, _, _, _ in

            self?.updateSearchBar(mediaPicker: picker)

            let isNotSearching = self?.mediaLibraryDataSource.searchQuery?.count ?? 0 == 0
            let hasNoAssets = self?.mediaLibraryDataSource.numberOfAssets() == 0

            if isNotSearching && hasNoAssets {
                self?.noResultsView.removeFromView()
                self?.noResultsView.configureForNoAssets(userCanUploadMedia: false)
            }
        })
    }

    fileprivate func unregisterChangeObserver() {
        if let mediaLibraryChangeObserverKey = mediaLibraryChangeObserverKey {
            mediaLibraryDataSource.unregisterChangeObserver(mediaLibraryChangeObserverKey)
        }
        mediaLibraryChangeObserverKey = nil
    }


    // MARK: - Keyboard Handling

    override var keyCommands: [UIKeyCommand] {
        if titleTextField.isFirstResponder {
            return [
                UIKeyCommand(input: "\t", modifierFlags: [], action: #selector(tabOnTitle))
            ]
        }

        if richTextView.isFirstResponder {
            return [
                UIKeyCommand(input: "B", modifierFlags: .command, action: #selector(toggleBold), discoverabilityTitle: NSLocalizedString("Bold", comment: "Discoverability title for bold formatting keyboard shortcut.")),
                UIKeyCommand(input: "I", modifierFlags: .command, action: #selector(toggleItalic), discoverabilityTitle: NSLocalizedString("Italic", comment: "Discoverability title for italic formatting keyboard shortcut.")),
                UIKeyCommand(input: "S", modifierFlags: [.command], action: #selector(toggleStrikethrough), discoverabilityTitle: NSLocalizedString("Strikethrough", comment: "Discoverability title for strikethrough formatting keyboard shortcut.")),
                UIKeyCommand(input: "U", modifierFlags: .command, action: #selector(toggleUnderline(_:)), discoverabilityTitle: NSLocalizedString("Underline", comment: "Discoverability title for underline formatting keyboard shortcut.")),
                UIKeyCommand(input: "Q", modifierFlags: [.command, .alternate], action: #selector(toggleBlockquote), discoverabilityTitle: NSLocalizedString("Block Quote", comment: "Discoverability title for block quote keyboard shortcut.")),
                UIKeyCommand(input: "K", modifierFlags: .command, action: #selector(toggleLink), discoverabilityTitle: NSLocalizedString("Insert Link", comment: "Discoverability title for insert link keyboard shortcut.")),
                UIKeyCommand(input: "M", modifierFlags: [.command, .alternate], action: #selector(presentMediaPickerWasPressed), discoverabilityTitle: NSLocalizedString("Insert Media", comment: "Discoverability title for insert media keyboard shortcut.")),
                UIKeyCommand(input: "U", modifierFlags: [.command, .alternate], action: #selector(toggleUnorderedList), discoverabilityTitle: NSLocalizedString("Bullet List", comment: "Discoverability title for bullet list keyboard shortcut.")),
                UIKeyCommand(input: "O", modifierFlags: [.command, .alternate], action: #selector(toggleOrderedList), discoverabilityTitle: NSLocalizedString("Numbered List", comment: "Discoverability title for numbered list keyboard shortcut.")),
                UIKeyCommand(input: "H", modifierFlags: [.command, .shift], action: #selector(toggleEditingMode), discoverabilityTitle: NSLocalizedString("Toggle HTML Source ", comment: "Discoverability title for HTML keyboard shortcut."))
            ]
        }

        if htmlTextView.isFirstResponder {
            return [
                UIKeyCommand(input: "H", modifierFlags: [.command, .shift], action: #selector(toggleEditingMode), discoverabilityTitle: NSLocalizedString("Toggle HTML Source ", comment: "Discoverability title for HTML keyboard shortcut."))
            ]
        }

        return []
    }

    @objc func keyboardWillShow(_ notification: Foundation.Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }
        // Convert the keyboard frame from window base coordinate
        currentKeyboardFrame = view.convert(keyboardFrame, from: nil)
        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    @objc func keyboardDidHide(_ notification: Foundation.Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        currentKeyboardFrame = .zero
        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    fileprivate func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        let referenceView = editorView.activeView

        let contentInsets  = UIEdgeInsets(top: referenceView.contentInset.top, left: 0, bottom: view.frame.maxY - (keyboardFrame.minY + self.view.layoutMargins.bottom), right: 0)

        htmlTextView.contentInset = contentInsets
        richTextView.contentInset = contentInsets

        updateScrollInsets()
    }

    @objc func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return presentationController(forPresented: presented, presenting: presenting)
    }

    @objc func didUndoRedo(_ notification: Foundation.Notification) {
        guard
            let undoManager = notification.object as? UndoManager,
            undoManager === richTextView.undoManager || undoManager === htmlTextView.undoManager
        else {
            return
        }

        switch notification.name {
        case .NSUndoManagerDidUndoChange:
            trackFormatBarAnalytics(stat: .editorTappedUndo)
        case .NSUndoManagerDidRedoChange:
            trackFormatBarAnalytics(stat: .editorTappedRedo)
        default: break
        }
    }
}


// MARK: - Format Bar Updating

extension AztecPostViewController {

    func updateFormatBar() {
        switch editorView.editingMode {
        case .html:
            updateFormatBarForHTMLMode()
        case .richText:
            updateFormatBarForVisualMode()
        }
    }

    /// Updates the format bar for HTML mode.
    ///
    private func updateFormatBarForHTMLMode() {
        assert(editorView.editingMode == .html)

        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        toolbar.selectItemsMatchingIdentifiers([FormattingIdentifier.sourcecode.rawValue])
    }

    /// Updates the format bar for visual mode.
    ///
    private func updateFormatBarForVisualMode() {
        assert(editorView.editingMode == .richText)

        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        var identifiers = Set<FormattingIdentifier>()

        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }

        toolbar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
    }

    private func mediaFor(uploadID: String) -> Media? {
        for media in post.media {
            if media.uploadID == uploadID {
                return media
            }
        }
        return nil
    }
}


// MARK: - SDK Workarounds!
//
extension AztecPostViewController {

    /// Note:
    /// When presenting an UIAlertController using a navigationBarButton as a source, the entire navigationBar
    /// gets set as a passthru view, allowing invalid scenarios, such as: pressing the Dismiss Button, while there's
    /// an ActionSheet onscreen.
    ///
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        // Preventing `UIViewControllerHierarchyInconsistency`
        // Ref.: https://github.com/wordpress-mobile/WordPress-iOS/issues/8995
        //
        if viewControllerToPresent is UIAlertController {
            rememberFirstResponder()
        }

        /// Ref.: https://github.com/wordpress-mobile/WordPress-iOS/pull/6666
        ///
        super.present(viewControllerToPresent, animated: flag) {
            if let alert = viewControllerToPresent as? UIAlertController, alert.preferredStyle == .actionSheet {
                alert.popoverPresentationController?.passthroughViews = nil
            }

            completion?()
        }
    }
}


// MARK: - AztecNavigationControllerDelegate Conformance

extension AztecPostViewController: AztecNavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, didDismiss alertController: UIAlertController) {
        // Preventing `UIViewControllerHierarchyInconsistency`
        // Ref.: https://github.com/wordpress-mobile/WordPress-iOS/issues/8995
        //
        restoreFirstResponder()
    }
}


// MARK: - Actions
//
extension AztecPostViewController {
    @IBAction func publishButtonTapped(sender: UIButton) {
        handlePublishButtonTap()
    }

    @IBAction func secondaryPublishButtonTapped() {
        guard let action = self.postEditorStateContext.secondaryPublishButtonAction else {
            // If the user tapped on the secondary publish action button, it means we should have a secondary publish action.
            let error = NSError(domain: errorDomain, code: ErrorCode.expectedSecondaryAction.rawValue, userInfo: nil)
            CrashLogging.logError(error)
            return
        }

        let secondaryStat = self.postEditorStateContext.secondaryPublishActionAnalyticsStat

        let publishPostClosure = { [unowned self] in
            self.publishPost(
                action: action,
                dismissWhenDone: action.dismissesEditor,
                analyticsStat: secondaryStat)
        }

        if presentedViewController != nil {
            dismiss(animated: true, completion: publishPostClosure)
        } else {
            publishPostClosure()
        }
    }

    @IBAction func closeWasPressed() {
        cancelEditing()
    }

    @IBAction func moreWasPressed() {
        displayMoreSheet()
    }
}


// MARK: - Private Helpers
//
private extension AztecPostViewController {

    /// Presents an alert controller, allowing the user to insert a link to either:
    ///
    /// - Insert a link to the document
    /// - Insert the content of the text document into the post
    ///
    /// - Parameter documentURL: the document URL to act upon
    func displayInsertionOpensAlertIfNeeded(for documentURL: URL) {
        let documentType = documentURL.pathExtension
        guard
            let uti = String.typeIdentifier(for: documentType),
            uti == String(kUTTypePDF) || uti == String(kUTTypePlainText)
        else {
            insertExternalMediaWithURL(documentURL)
            return
        }

        let title = NSLocalizedString("What do you want to do with this file: upload it and add a link to the file into your post, or add the contents of the file directly to the post?", comment: "Title displayed via UIAlertController when a user inserts a document into a post.")

        let style: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: style)

        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancels an alert.")
        alertController.addCancelActionWithTitle(cancelTitle)

        let attachAsLinkTitle = NSLocalizedString("Attach File as Link", comment: "Alert option to embed a doc link into a blog post.")
        alertController.addDefaultActionWithTitle(attachAsLinkTitle) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.insertExternalMediaWithURL(documentURL)
        }

        let addContentsToPostTitle = NSLocalizedString("Add Contents to Post", comment: "Alert option to add document contents into a blog post.")

        let addContentsActionHandler: (() -> Void)
        if uti == String(kUTTypePDF) {
            addContentsActionHandler = { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                var text = ""
                if let document = PDFDocument(url: documentURL) {
                    text = document.string ?? ""
                }

                strongSelf.editorView.insertText(text)
            }
        } else {
            addContentsActionHandler = { [weak self] in
                guard let strongSelf = self else { return }

                let text: String
                do {
                    text = try String(contentsOf: documentURL)
                }
                catch {
                    text = ""
                }

                strongSelf.editorView.insertText(text)
            }
        }
        alertController.addDefaultActionWithTitle(addContentsToPostTitle) { _ in
            addContentsActionHandler()
        }

        present(alertController, animated: true)
    }

    func displayMoreSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if editorView.editingMode == .richText {
            // NB : This is a candidate for plurality via .stringsdict, but is limited by https://github.com/wordpress-mobile/WordPress-iOS/issues/6327
            let textCounterTitle = String(format: NSLocalizedString("%li words, %li characters", comment: "Displays the number of words and characters in text"), richTextView.wordCount, richTextView.characterCount)

            alert.title = textCounterTitle
        }

        if postEditorStateContext.isSecondaryPublishButtonShown,
            let buttonTitle = postEditorStateContext.secondaryPublishButtonText {

            alert.addDefaultActionWithTitle(buttonTitle) { _ in
                self.secondaryPublishButtonTapped()
            }
        }

        if post.blog.isGutenbergEnabled,
            let postContent = post.content,
            postContent.count > 0 && post.containsGutenbergBlocks() {

            alert.addDefaultActionWithTitle(MoreSheetAlert.gutenbergTitle) { [unowned self] _ in
                self.editorSession.switch(editor: .gutenberg)
                EditorFactory().switchToGutenberg(from: self)
            }
        }

        let toggleModeTitle: String = {
            if editorView.editingMode == .richText {
                return MoreSheetAlert.htmlTitle
            } else {
                return MoreSheetAlert.richTitle
            }
        }()

        alert.addDefaultActionWithTitle(toggleModeTitle) { [unowned self] _ in
            self.toggleEditingMode()
        }

        alert.addDefaultActionWithTitle(MoreSheetAlert.previewTitle) { [unowned self] _ in
            self.displayPreview()
        }

        if (post.revisions ?? []).count > 0 {
            alert.addDefaultActionWithTitle(MoreSheetAlert.historyTitle) { [unowned self] _ in
                self.displayHistory()
            }
        }

        alert.addDefaultActionWithTitle(MoreSheetAlert.postSettingsTitle) { [unowned self] _ in
            self.displayPostSettings()
        }

        alert.addCancelActionWithTitle(MoreSheetAlert.keepEditingTitle)

        alert.popoverPresentationController?.barButtonItem = navigationBarManager.moreBarButtonItem

        present(alert, animated: true)
    }

    @IBAction func displayCancelMediaUploads() {
        let alertController = UIAlertController(title: MediaUploadingCancelAlert.title, message: MediaUploadingCancelAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(MediaUploadingCancelAlert.acceptTitle) { alertAction in
            self.mediaCoordinator.cancelUploadOfAllMedia(for: self.post)
        }
        alertController.addCancelActionWithTitle(MediaUploadingCancelAlert.cancelTitle)
        present(alertController, animated: true)
        return
    }
}


// MARK: - PostEditorStateContextDelegate & support methods
//
extension AztecPostViewController: PostEditorStateContextDelegate {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {
            return
        }

        switch keyPath {
        case BasePost.statusKeyPath:
            if let status = post.status {
                postEditorStateContext.updated(postStatus: status)
                editorContentWasUpdated()
            }
        case #keyPath(AbstractPost.date_created_gmt):
            let dateCreated = post.dateCreated ?? Date()
            postEditorStateContext.updated(publishDate: dateCreated)
            editorContentWasUpdated()
        case #keyPath(AbstractPost.content):
            editorContentWasUpdated()
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    internal func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {
        reloadPublishButton()
    }

    internal func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {
        reloadPublishButton()
    }

    internal func addObservers(toPost: AbstractPost) {
        toPost.addObserver(self, forKeyPath: AbstractPost.statusKeyPath, options: [], context: nil)
        toPost.addObserver(self, forKeyPath: #keyPath(AbstractPost.date_created_gmt), options: [], context: nil)
        toPost.addObserver(self, forKeyPath: #keyPath(AbstractPost.content), options: [], context: nil)
    }

    internal func removeObservers(fromPost: AbstractPost) {
        fromPost.removeObserver(self, forKeyPath: AbstractPost.statusKeyPath)
        fromPost.removeObserver(self, forKeyPath: #keyPath(AbstractPost.date_created_gmt))
        fromPost.removeObserver(self, forKeyPath: #keyPath(AbstractPost.content))
    }
}


// MARK: - UITextViewDelegate methods
//
extension AztecPostViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        switch textView {
        case titleTextField:
            return shouldChangeTitleText(in: range, replacementText: text)

        default:
            return true
        }
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        updateFormatBar()
    }

    func textViewDidChange(_ textView: UITextView) {
        autosaver.contentDidChange()
        refreshPlaceholderVisibility()

        switch textView {
        case titleTextField:
            updateTitleHeight()
        case richTextView:
            updateFormatBar()
        default:
            break
        }
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.textAlignment = .natural

        let htmlButton = formatBar.items.first(where: { $0.identifier == FormattingIdentifier.sourcecode.rawValue })

        switch textView {
        case titleTextField:
            formatBar.enabled = false
        case richTextView:
            formatBar.enabled = true
        case htmlTextView:
            formatBar.enabled = false
        default:
            break
        }

        htmlButton?.isEnabled = true

        if mediaPickerInputViewController == nil {
            textView.inputAccessoryView = formatBar
        }

        return true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshTitlePosition()
    }

    // MARK: - Title Input Sanitization

    /// Sanitizes an input for insertion in the title text view.
    ///
    /// - Parameters:
    ///     - input: the input for the title text view.
    ///
    /// - Returns: the sanitized string
    ///
    private func sanitizeInputForTitle(_ input: String) -> String {
        var sanitizedText = input

        while let range = sanitizedText.rangeOfCharacter(from: CharacterSet.newlines, options: [], range: nil) {
            sanitizedText = sanitizedText.replacingCharacters(in: range, with: " ")
        }

        return sanitizedText
    }

    /// This method performs all necessary checks to verify if the title text can be changed,
    /// or if some other action should be performed instead.
    ///
    /// - Important: this method sanitizes newlines, since they're not allowed in the title.
    ///
    /// - Parameters:
    ///     - range: the range that would be modified.
    ///     - text: the new text for the specified range.
    ///
    /// - Returns: `true` if the modification can take place, `false` otherwise.
    ///
    private func shouldChangeTitleText(in range: NSRange, replacementText text: String) -> Bool {

        guard text.count > 1 else {
            guard text.rangeOfCharacter(from: CharacterSet.newlines, options: [], range: nil) == nil else {
                richTextView.becomeFirstResponder()
                richTextView.selectedRange = NSRange(location: 0, length: 0)
                return false
            }

            return true
        }

        let sanitizedInput = sanitizeInputForTitle(text)
        let newlinesWereRemoved = sanitizedInput != text

        guard !newlinesWereRemoved else {
            titleTextField.insertText(sanitizedInput)

            return false
        }

        return true
    }
}


// MARK: - UITextFieldDelegate methods
//
extension AztecPostViewController {
    func titleTextFieldDidChange(_ textField: UITextField) {
        mapUIContentToPostAndSave()
        editorContentWasUpdated()
    }
}


// MARK: - TextViewFormattingDelegate methods
//
extension AztecPostViewController: Aztec.TextViewFormattingDelegate {
    func textViewCommandToggledAStyle() {
        updateFormatBar()
    }
}


// MARK: - HTML Mode Switch methods
//
extension AztecPostViewController {

    func refreshPlaceholderVisibility() {
        placeholderLabel.isHidden = richTextView.isHidden || !richTextView.text.isEmpty
        titlePlaceholderLabel.isHidden = !titleTextField.text.isEmpty
    }
}


// MARK: - FormatBarDelegate Conformance
//
extension AztecPostViewController: Aztec.FormatBarDelegate {
    func formatBarTouchesBegan(_ formatBar: FormatBar) {
    }

    /// Called when the overflow items in the format bar are either shown or hidden
    /// as a result of the user tapping the toggle button.
    ///
    func formatBar(_ formatBar: FormatBar, didChangeOverflowState overflowState: FormatBarOverflowState) {
        let action = overflowState == .visible ? "made_visible" : "made_hidden"
        trackFormatBarAnalytics(stat: .editorTappedMoreItems, action: action)
    }
}

// MARK: FormatBar Actions
//
extension AztecPostViewController {
    func handleAction(for barItem: FormatBarItem) {
        guard let identifier = barItem.identifier else { return }

        if let formattingIdentifier = FormattingIdentifier(rawValue: identifier) {
            switch formattingIdentifier {
            case .bold:
                toggleBold()
            case .italic:
                toggleItalic()
            case .underline:
                toggleUnderline()
            case .strikethrough:
                toggleStrikethrough()
            case .blockquote:
                toggleBlockquote()
            case .unorderedlist, .orderedlist:
                toggleList(fromItem: barItem)
            case .link:
                toggleLink()
            case .media:
                break
            case .sourcecode:
                toggleEditingMode()
            case .p, .header1, .header2, .header3, .header4, .header5, .header6:
                toggleHeader(fromItem: barItem)
            case .horizontalruler:
                insertHorizontalRuler()
            case .more:
                insertMore()
            case .code:
                toggleCode()
            default:
                break
            }

            updateFormatBar()
        }
        if let mediaIdentifier = FormatBarMediaIdentifier(rawValue: identifier) {
            switch mediaIdentifier {
            case .deviceLibrary:
                trackFormatBarAnalytics(stat: .editorMediaPickerTappedDevicePhotos)
                presentMediaPickerFullScreen(animated: true, dataSourceType: .device)
            case .camera:
                trackFormatBarAnalytics(stat: .editorMediaPickerTappedCamera)
                mediaPickerInputViewController?.showCapture()
            case .mediaLibrary:
                trackFormatBarAnalytics(stat: .editorMediaPickerTappedMediaLibrary)
                presentMediaPickerFullScreen(animated: true, dataSourceType: .mediaLibrary)
            case .otherApplications:
                trackFormatBarAnalytics(stat: .editorMediaPickerTappedOtherApps)
                showMore(from: barItem)
            }
        }
    }

    func handleFormatBarLeadingItem(_ item: UIButton) {
        toggleMediaPicker(fromButton: item)
    }

    func handleFormatBarTrailingItem(_ item: UIButton) {
        guard let mediaPicker = mediaPickerInputViewController else {
            return
        }

        mediaPickerController(mediaPicker.mediaPicker, didFinishPicking: mediaPicker.mediaPicker.selectedAssets)
    }

    @objc func toggleBold() {
        trackFormatBarAnalytics(stat: .editorTappedBold)
        richTextView.toggleBold(range: richTextView.selectedRange)
    }

    @objc func toggleCode() {
        richTextView.toggleCode(range: richTextView.selectedRange)
    }

    @objc func toggleItalic() {
        trackFormatBarAnalytics(stat: .editorTappedItalic)
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }


    @objc func toggleUnderline() {
        trackFormatBarAnalytics(stat: .editorTappedUnderline)
        richTextView.toggleUnderline(range: richTextView.selectedRange)
    }


    @objc func toggleStrikethrough() {
        trackFormatBarAnalytics(stat: .editorTappedStrikethrough)
        richTextView.toggleStrikethrough(range: richTextView.selectedRange)
    }

    @objc func toggleOrderedList() {
        trackFormatBarAnalytics(stat: .editorTappedOrderedList)
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }

    @objc func toggleUnorderedList() {
        trackFormatBarAnalytics(stat: .editorTappedUnorderedList)
        richTextView.toggleUnorderedList(range: richTextView.selectedRange)
    }

    func toggleList(fromItem item: FormatBarItem) {
        trackFormatBarAnalytics(stat: .editorTappedList)
        let listOptions = Constants.lists.map { listType -> OptionsTableViewOption in
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.text
            ]

            let title = NSAttributedString(string: listType.description, attributes: attributes)

            return OptionsTableViewOption(image: listType.iconImage,
                                          title: title,
                                          accessibilityLabel: listType.accessibilityLabel)
        }

        var index: Int? = nil
        if let listType = listTypeForSelectedText() {
            index = Constants.lists.index(of: listType)
        }

        let optionsTableViewController = OptionsTableViewController(options: listOptions)

        optionsTableViewController.cellDeselectedTintColor = WPStyleGuide.aztecFormatBarInactiveColor
        optionsTableViewController.cellBackgroundColor = WPStyleGuide.aztecFormatPickerBackgroundColor
        optionsTableViewController.cellSelectedBackgroundColor = WPStyleGuide.aztecFormatPickerSelectedCellBackgroundColor
        optionsTableViewController.view.tintColor = WPStyleGuide.aztecFormatBarActiveColor

        optionsTablePresenter.present(
            optionsTableViewController,
            fromBarItem: item,
            selectedRowIndex: index,
            onSelect: { [weak self] selected in
                let listType = Constants.lists[selected]

                switch listType {
                case .unordered:
                    self?.toggleUnorderedList()
                case .ordered:
                    self?.toggleOrderedList()
                }
        })
    }


    @objc func toggleBlockquote() {
        trackFormatBarAnalytics(stat: .editorTappedBlockquote)
        richTextView.toggleBlockquote(range: richTextView.selectedRange)
    }


    func listTypeForSelectedText() -> TextList.Style? {
        var identifiers = Set<FormattingIdentifier>()
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: TextList.Style] = [
            .orderedlist: .ordered,
            .unorderedlist: .unordered
        ]
        for (key, value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }

        return nil
    }

    // MARK: Link Actions

    @objc func toggleLink() {
        trackFormatBarAnalytics(stat: .editorTappedLink)

        var linkTitle = ""
        var linkURL: URL? = nil
        var linkTarget: String?
        var linkRange = richTextView.selectedRange
        // Let's check if the current range already has a link assigned to it.
        if let expandedRange = richTextView.linkFullRange(forRange: richTextView.selectedRange) {
            linkRange = expandedRange
            linkURL = richTextView.linkURL(forRange: expandedRange)
            linkTarget = richTextView.linkTarget(forRange: expandedRange)
        }

        linkTitle = richTextView.attributedText.attributedSubstring(from: linkRange).string
        showLinkDialog(forURL: linkURL, title: linkTitle, target: linkTarget, range: linkRange)
    }

    func showLinkDialog(forURL url: URL?, title: String?, target: String?, range: NSRange) {

        let isInsertingNewLink = (url == nil)
        var urlToUse = url

        if isInsertingNewLink {
            if UIPasteboard.general.hasURLs,
                let pastedURL = UIPasteboard.general.url {
                urlToUse = pastedURL
            }
        }

        let linkSettings = LinkSettings(url: urlToUse?.absoluteString ?? "", text: title ?? "", openInNewWindow: target != nil, isNewLink: isInsertingNewLink)
        let linkController = LinkSettingsViewController(settings: linkSettings, callback: { [weak self](action, settings) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dismiss(animated: true, completion: {
                strongSelf.richTextView.becomeFirstResponder()
                switch action {
                case .insert, .update:
                    strongSelf.insertLink(url: settings.url, text: settings.text, target: settings.openInNewWindow ? "_blank" : nil, range: range)
                case .remove:
                    strongSelf.removeLink(in: range)
                case .cancel:
                    break
                }
            })
        })
        linkController.blog = self.post.blog

        let navigationController = UINavigationController(rootViewController: linkController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.permittedArrowDirections = [.any]
        navigationController.popoverPresentationController?.sourceView = richTextView
        navigationController.popoverPresentationController?.backgroundColor = WPStyleGuide.aztecFormatPickerBackgroundColor
        if richTextView.selectedRange.length > 0, let textRange = richTextView.selectedTextRange, let selectionRect = richTextView.selectionRects(for: textRange).first {
            navigationController.popoverPresentationController?.sourceRect = selectionRect.rect
        } else if let textRange = richTextView.selectedTextRange {
            let caretRect = richTextView.caretRect(for: textRange.start)
            navigationController.popoverPresentationController?.sourceRect = caretRect
        }
        present(navigationController, animated: true)
        richTextView.resignFirstResponder()
    }

    func insertLink(url: String, text: String?, target: String?, range: NSRange) {
        let linkURLString = url
        var linkText = text

        if linkText == nil || linkText!.isEmpty {
            linkText = linkURLString
        }

        guard let url = URL(string: linkURLString), let title = linkText else {
            return
        }

        richTextView.setLink(url.normalizedURLForWordPressLink(), title: title, target: target, inRange: range)
    }

    func removeLink(in range: NSRange) {
        trackFormatBarAnalytics(stat: .editorTappedUnlink)
        richTextView.removeLink(inRange: range)
    }

    private var mediaInputToolbar: UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: Constants.toolbarHeight))
        toolbar.barTintColor = WPStyleGuide.aztecFormatBarBackgroundColor
        toolbar.tintColor = WPStyleGuide.aztecFormatBarActiveColor
        let gridButton = UIBarButtonItem(image: Gridicon.iconOfType(.grid), style: .plain, target: self, action: #selector(mediaAddShowFullScreen))
        gridButton.accessibilityLabel = NSLocalizedString("Open full media picker", comment: "Editor button to swich the media picker from quick mode to full picker")
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(mediaAddInputCancelled)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            gridButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(mediaAddInputDone))
        ]

        for item in toolbar.items! {
            item.tintColor = WPStyleGuide.aztecFormatBarActiveColor
            item.setTitleTextAttributes([.foregroundColor: WPStyleGuide.aztecFormatBarActiveColor], for: .normal)
        }

        return toolbar

    }

    // MARK: - Media Input toolbar button actions

    /// Method to be called when the grid icon is pressed on the media input toolbar.
    ///
    /// - Parameter sender: the button that was pressed.
    ///
    @objc func mediaAddShowFullScreen(_ sender: UIBarButtonItem) {
        presentMediaPickerFullScreen(animated: true)
        restoreInputAssistantItems()
    }

    /// Method to be called when canceled is pressed.
    ///
    /// - Parameter sender: the button that was pressed.
    @objc func mediaAddInputCancelled(_ sender: UIBarButtonItem) {

        guard let mediaPicker = mediaPickerInputViewController?.mediaPicker else {
            return
        }
        mediaPickerControllerDidCancel(mediaPicker)
        restoreInputAssistantItems()
    }

    /// Method to be called when done is pressed on the media input toolbar.
    ///
    /// - Parameter sender: the button that was pressed.
    @objc func mediaAddInputDone(_ sender: UIBarButtonItem) {

        guard let mediaPicker = mediaPickerInputViewController?.mediaPicker
        else {
            return
        }
        let selectedAssets = mediaPicker.selectedAssets
        mediaPickerController(mediaPicker, didFinishPicking: selectedAssets)
        restoreInputAssistantItems()
    }

    func restoreInputAssistantItems() {

        richTextView.inputAssistantItem.leadingBarButtonGroups = originalLeadingBarButtonGroup
        richTextView.inputAssistantItem.trailingBarButtonGroups = originalTrailingBarButtonGroup
        richTextView.autocorrectionType = .yes
        richTextView.reloadInputViews()
    }

    @objc func tabOnTitle() {
        let activeTextView: UITextView = {
            switch editorView.editingMode {
            case .html:
                return htmlTextView
            case .richText:
                return richTextView
            }
        }()

        activeTextView.becomeFirstResponder()
        activeTextView.selectedTextRange = activeTextView.textRange(from: activeTextView.endOfDocument, to: activeTextView.endOfDocument)
    }

    @IBAction @objc func presentMediaPickerWasPressed() {
        if let item = formatBar.leadingItem {
            presentMediaPicker(fromButton: item, animated: true)
        }
    }

    fileprivate func presentMediaPickerFullScreen(animated: Bool, dataSourceType: MediaPickerDataSourceType = .device) {

        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowCaptureOfMedia = false
        options.showSearchBar = true
        options.badgedUTTypes = [String(kUTTypeGIF)]
        options.preferredStatusBarStyle = .lightContent

        let picker = WPNavigationMediaPickerViewController()

        switch dataSourceType {
        case .device:
            picker.dataSource = devicePhotoLibraryDataSource
        case .mediaLibrary:
            picker.startOnGroupSelector = false
            picker.showGroupSelector = false
            picker.dataSource = mediaLibraryDataSource
            registerChangeObserver(forPicker: picker.mediaPicker)
        }

        picker.selectionActionTitle = Constants.mediaPickerInsertText
        picker.mediaPicker.options = options
        picker.delegate = self
        picker.modalPresentationStyle = .currentContext
        if let previousPicker = mediaPickerInputViewController?.mediaPicker {
            picker.mediaPicker.selectedAssets = previousPicker.selectedAssets
        }

        present(picker, animated: true)
    }

    private func toggleMediaPicker(fromButton button: UIButton) {
        if mediaPickerInputViewController != nil {
            closeMediaPickerInputViewController()
            trackFormatBarAnalytics(stat: .editorMediaPickerTappedDismiss)
        } else {
            presentMediaPicker(fromButton: button, animated: true)
        }
    }

    private func presentMediaPicker(fromButton button: UIButton, animated: Bool = true) {
        trackFormatBarAnalytics(stat: .editorTappedImage)

        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [WPMediaType.image, WPMediaType.video]
        options.allowMultipleSelection = true
        options.allowCaptureOfMedia = false
        options.scrollVertically = true
        options.badgedUTTypes = [String(kUTTypeGIF)]
        options.preferredStatusBarStyle = .lightContent

        let picker = WPInputMediaPickerViewController(options: options)
        mediaPickerInputViewController = picker
        updateToolbar(formatBar, forMode: .media)

        originalLeadingBarButtonGroup = richTextView.inputAssistantItem.leadingBarButtonGroups
        originalTrailingBarButtonGroup = richTextView.inputAssistantItem.trailingBarButtonGroups

        richTextView.inputAssistantItem.leadingBarButtonGroups = []
        richTextView.inputAssistantItem.trailingBarButtonGroups = []

        richTextView.autocorrectionType = .no

        picker.mediaPicker.viewControllerToUseToPresent = self
        picker.dataSource = WPPHAssetDataSource.sharedInstance()
        picker.mediaPicker.mediaPickerDelegate = self

        if currentKeyboardFrame != .zero {
            // iOS is not adjusting the media picker's height to match the default keyboard's height when autoresizingMask
            // is set to UIViewAutoresizingFlexibleHeight (even though the docs claim it should). Need to manually
            // set the picker's frame to the current keyboard's frame.
            picker.view.autoresizingMask = []
            picker.view.frame = CGRect(x: 0, y: 0, width: currentKeyboardFrame.width, height: mediaKeyboardHeight)
        }

        presentToolbarViewControllerAsInputView(picker)
    }

    @objc func toggleEditingMode() {
        trackFormatBarAnalytics(stat: .editorTappedHTML)
        formatBar.overflowToolbar(expand: true)

        editorView.toggleEditingMode()
        editorSession.switch(editor: analyticsEditor)
        if editorView.editingMode == .richText {
            processMediaAttachments()
        }
    }

    func toggleHeader(fromItem item: FormatBarItem) {
        guard !optionsTablePresenter.isOnScreen() else {
            optionsTablePresenter.dismiss()
            return
        }

        trackFormatBarAnalytics(stat: .editorTappedHeader)

        let headerOptions = Constants.headers.map { headerType -> OptionsTableViewOption in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: CGFloat(headerType.fontSize)),
                .foregroundColor: UIColor.text
            ]

            let title = NSAttributedString(string: headerType.description, attributes: attributes)

            return OptionsTableViewOption(image: headerType.iconImage,
                                          title: title,
                                          accessibilityLabel: headerType.accessibilityLabel)
        }

        let selectedIndex = Constants.headers.index(of: self.headerLevelForSelectedText())

        let optionsTableViewController = OptionsTableViewController(options: headerOptions)

        optionsTableViewController.cellDeselectedTintColor = WPStyleGuide.aztecFormatBarInactiveColor
        optionsTableViewController.cellBackgroundColor = WPStyleGuide.aztecFormatPickerBackgroundColor
        optionsTableViewController.cellSelectedBackgroundColor = WPStyleGuide.aztecFormatPickerSelectedCellBackgroundColor
        optionsTableViewController.view.tintColor = WPStyleGuide.aztecFormatBarActiveColor

        optionsTablePresenter.present(
            optionsTableViewController,
            fromBarItem: item,
            selectedRowIndex: selectedIndex,
            onSelect: { [weak self] selected in
                guard let range = self?.richTextView.selectedRange else { return }

                let selectedStyle = Analytics.headerStyleValues[selected]
                self?.trackFormatBarAnalytics(stat: .editorTappedHeaderSelection, headingStyle: selectedStyle)

                self?.richTextView.toggleHeader(Constants.headers[selected], range: range)
                self?.optionsTablePresenter.dismiss()
        })
    }

    func insertHorizontalRuler() {
        trackFormatBarAnalytics(stat: .editorTappedHorizontalRule)
        richTextView.replaceWithHorizontalRuler(at: richTextView.selectedRange)
    }

    func insertMore() {
        trackFormatBarAnalytics(stat: .editorTappedMore)
        richTextView.replace(richTextView.selectedRange, withComment: Constants.moreAttachmentText)
    }

    func headerLevelForSelectedText() -> Header.HeaderType {
        var identifiers = Set<FormattingIdentifier>()
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: Header.HeaderType] = [
            .header1: .h1,
            .header2: .h2,
            .header3: .h3,
            .header4: .h4,
            .header5: .h5,
            .header6: .h6,
        ]
        for (key, value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }
        return .none
    }

    private func showMore(from: FormatBarItem) {
        let moreCoordinatorContext = MediaPickingContext(origin: self, view: view, blog: post.blog)
        moreCoordinator.present(context: moreCoordinatorContext)
    }

    private func presentToolbarViewControllerAsInputView(_ viewController: UIViewController) {
        self.addChild(viewController)
        changeRichTextInputView(to: viewController.view)
        viewController.didMove(toParent: self)
    }

    func changeRichTextInputView(to: UIView?) {
        guard richTextView.inputView != to else {
            return
        }

        richTextView.inputView = to
        richTextView.reloadInputViews()
    }

    fileprivate func trackFormatBarAnalytics(stat: WPAnalyticsStat, action: String? = nil, headingStyle: String? = nil) {
        var properties = [WPAppAnalyticsKeyEditorSource: Analytics.editorSource]

        if let action = action {
            properties["action"] = action
        }

        if let headingStyle = headingStyle {
            properties["heading_style"] = headingStyle
        }
        WPAppAnalytics.track(stat, withProperties: properties, with: post)
    }

    // MARK: - Toolbar creation

    // Used to determine which icons to show on the format bar
    fileprivate enum FormatBarMode {
        case text
        case media
    }

    fileprivate func updateToolbar(_ toolbar: Aztec.FormatBar, forMode mode: FormatBarMode) {
        if let leadingItem = toolbar.leadingItem {
            rotateMediaToolbarItem(leadingItem, forMode: mode)
        }

        toolbar.trailingItem = nil

        switch mode {
        case .text:
            toolbar.setDefaultItems(scrollableItemsForToolbar,
                                    overflowItems: overflowItemsForToolbar)
        case .media:
            toolbar.setDefaultItems(mediaItemsForToolbar,
                                    overflowItems: [])
        }
    }

    private func rotateMediaToolbarItem(_ item: UIButton, forMode mode: FormatBarMode) {
        let transform: CGAffineTransform
        let accessibilityIdentifier: String
        let accessibilityLabel: String

        switch mode {
        case .text:
            accessibilityIdentifier = FormattingIdentifier.media.accessibilityIdentifier
            accessibilityLabel = FormattingIdentifier.media.accessibilityLabel

            transform = .identity
        case .media:
            accessibilityIdentifier = "format_toolbar_close_media"
            accessibilityLabel = NSLocalizedString("Close Media Picker", comment: "Accessibility label for button that closes the media picker on formatting toolbar")

            transform = CGAffineTransform(rotationAngle: Constants.Animations.formatBarMediaButtonRotationAngle)
        }

        let animator = UIViewPropertyAnimator(duration: Constants.Animations.formatBarMediaButtonRotationDuration,
                                              curve: .easeInOut) {
                                                item.transform = transform
        }

        animator.addCompletion({ position in
            if position == .end {
                item.accessibilityIdentifier = accessibilityIdentifier
                item.accessibilityLabel = accessibilityLabel
            }
        })

        animator.startAnimation()
    }

    func makeToolbarButton(identifier: FormattingIdentifier) -> FormatBarItem {
        return makeToolbarButton(identifier: identifier.rawValue, provider: identifier)
    }

    func makeToolbarButton(identifier: FormatBarMediaIdentifier) -> FormatBarItem {
        return makeToolbarButton(identifier: identifier.rawValue, provider: identifier)
    }

    func makeToolbarButton(identifier: String, provider: FormatBarItemProvider) -> FormatBarItem {
        let button = FormatBarItem(image: provider.iconImage, identifier: identifier)
        button.accessibilityLabel = provider.accessibilityLabel
        button.accessibilityIdentifier = provider.accessibilityIdentifier
        return button
    }

    func createToolbar() -> Aztec.FormatBar {
        let toolbar = Aztec.FormatBar()

        toolbar.backgroundColor = .filterBarBackground
        toolbar.tintColor = WPStyleGuide.aztecFormatBarInactiveColor
        toolbar.highlightedTintColor = WPStyleGuide.aztecFormatBarActiveColor
        toolbar.selectedTintColor = WPStyleGuide.aztecFormatBarActiveColor
        toolbar.disabledTintColor = WPStyleGuide.aztecFormatBarDisabledColor
        toolbar.dividerTintColor = WPStyleGuide.aztecFormatBarDividerColor
        toolbar.overflowToggleIcon = Gridicon.iconOfType(.ellipsis)

        let mediaButton = makeToolbarButton(identifier: .media)
        mediaButton.normalTintColor = .primary
        toolbar.leadingItem = mediaButton

        updateToolbar(toolbar, forMode: .text)

        toolbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: Constants.toolbarHeight)
        toolbar.formatter = self

        toolbar.barItemHandler = { [weak self] item in
            self?.handleAction(for: item)
        }

        toolbar.leadingItemHandler = { [weak self] item in
            self?.handleFormatBarLeadingItem(item)
        }

        toolbar.trailingItemHandler = { [weak self] item in
            self?.handleFormatBarTrailingItem(item)
        }

        return toolbar
    }

    var mediaItemsForToolbar: [FormatBarItem] {
        var toolbarButtons = [makeToolbarButton(identifier: .deviceLibrary)]

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            toolbarButtons.append(makeToolbarButton(identifier: .camera))
        }

        toolbarButtons.append(makeToolbarButton(identifier: .mediaLibrary))

        toolbarButtons.append(makeToolbarButton(identifier: .otherApplications))

        return toolbarButtons
    }

    var scrollableItemsForToolbar: [FormatBarItem] {
        let headerButton = makeToolbarButton(identifier: .p)

        var alternativeIcons = [String: UIImage]()
        let headings = Constants.headers.suffix(from: 1) // Remove paragraph style
        for heading in headings {
            alternativeIcons[heading.formattingIdentifier.rawValue] = heading.iconImage
        }

        headerButton.alternativeIcons = alternativeIcons


        let listButton = makeToolbarButton(identifier: .unorderedlist)
        var listIcons = [String: UIImage]()
        for list in Constants.lists {
            listIcons[list.formattingIdentifier.rawValue] = list.iconImage
        }

        listButton.alternativeIcons = listIcons

        return [
            headerButton,
            listButton,
            makeToolbarButton(identifier: .blockquote),
            makeToolbarButton(identifier: .bold),
            makeToolbarButton(identifier: .italic),
            makeToolbarButton(identifier: .link)
        ]
    }

    var overflowItemsForToolbar: [FormatBarItem] {
        return [
            makeToolbarButton(identifier: .underline),
            makeToolbarButton(identifier: .strikethrough),
            makeToolbarButton(identifier: .horizontalruler),
            makeToolbarButton(identifier: .more),
            makeToolbarButton(identifier: .sourcecode)
        ]
    }
}


// MARK: - UINavigationControllerDelegate Conformance
//
extension AztecPostViewController: UINavigationControllerDelegate {

}


// MARK: - UIPopoverPresentationControllerDelegate
//
extension AztecPostViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
    }
}

// MARK: - Unknown HTML
//
private extension AztecPostViewController {

    func displayUnknownHtmlEditor(for attachment: HTMLAttachment) {
        let targetVC = UnknownEditorViewController(attachment: attachment)
        targetVC.onDidSave = { [weak self] html in
            self?.richTextView.edit(attachment) { htmlAttachment in
                htmlAttachment.rawHTML = html
            }
            self?.dismiss(animated: true)
        }

        targetVC.onDidCancel = { [weak self] in
            self?.dismiss(animated: true)
        }

        let navigationController = UINavigationController(rootViewController: targetVC)
        displayAsPopover(viewController: navigationController)
    }

    func displayAsPopover(viewController: UIViewController) {
        viewController.modalPresentationStyle = .popover
        viewController.preferredContentSize = view.frame.size

        let presentationController = viewController.popoverPresentationController
        presentationController?.sourceView = view
        presentationController?.delegate = self

        present(viewController, animated: true)
    }
}

extension AztecPostViewController {

    private func stopEditing() {
        view.endEditing(true)
    }

    func contentByStrippingMediaAttachments() -> String {
        if editorView.editingMode == .html {
            setHTML(htmlTextView.text)
        }

        richTextView.removeMediaAttachments()
        let strippedHTML = getHTML()

        if editorView.editingMode == .html {
            setHTML(strippedHTML)
        }

        return strippedHTML
    }
}

// MARK: - Computed Properties

extension AztecPostViewController {

    /// Height to use for the inline media picker based on iOS version and screen orientation.
    ///
    private var mediaKeyboardHeight: CGFloat {
        var keyboardHeight: CGFloat

        // Let's assume a sensible default for the keyboard height based on orientation
        let keyboardFrameRatioDefault = UIApplication.shared.statusBarOrientation.isPortrait ? Constants.mediaPickerKeyboardHeightRatioPortrait : Constants.mediaPickerKeyboardHeightRatioLandscape
        let keyboardHeightDefault = (keyboardFrameRatioDefault * UIScreen.main.bounds.height)

        // we need to make an assumption the hardware keyboard is attached based on
        // the height of the current keyboard frame being less than our sensible default. If it is
        // "attached", let's just use our default.
        if currentKeyboardFrame.height < keyboardHeightDefault {
            keyboardHeight = keyboardHeightDefault
        } else {
            keyboardHeight = (currentKeyboardFrame.height - Constants.toolbarHeight)
        }

        // Sanity check
        keyboardHeight = max(keyboardHeight, keyboardHeightDefault)

        return keyboardHeight
    }
}

// MARK: - Media Support
//
extension AztecPostViewController {

    func registerMediaObserver() {
        mediaObserverReceipt =  mediaCoordinator.addObserver({ [weak self](media, state) in
            self?.mediaObserver(media: media, state: state)
            }, forMediaFor: post)
    }

    func unregisterMediaObserver() {
        if let receipt = mediaObserverReceipt {
            mediaCoordinator.removeObserver(withUUID: receipt)
        }
    }

    func mediaObserver(media: Media, state: MediaCoordinator.MediaState) {
        refreshGlobalProgress()
        guard let attachment = findAttachment(withUploadID: media.uploadID) else {
            return
        }
        switch state {
        case .processing:
            DDLogInfo("Creating media")
        case .thumbnailReady(let url):
            handleThumbnailURL(url, attachment: attachment, savePostContent: true)
        case .uploading:
            handleUploadStarted(attachment: attachment)
        case .ended:
            handleUploaded(media: media, mediaUploadID: media.uploadID)
        case .failed(let error):
            handleError(error, onAttachment: attachment)
        case .progress(let value):
            handleProgress(value, forMedia: media, onAttachment: attachment)
        }
    }

    func configureMediaAppearance() {
        MediaAttachment.defaultAppearance.progressBackgroundColor = Colors.mediaProgressBarBackground
        MediaAttachment.defaultAppearance.progressColor = Colors.mediaProgressBarTrack
        MediaAttachment.defaultAppearance.overlayColor = Colors.mediaProgressOverlay
        MediaAttachment.defaultAppearance.overlayBorderWidth = Constants.mediaOverlayBorderWidth
        MediaAttachment.defaultAppearance.overlayBorderColor = Colors.mediaOverlayBorderColor
    }

    func findAttachment(withUploadID uploadID: String) -> MediaAttachment? {
        var result: MediaAttachment?
        self.richTextView.textStorage.enumerateAttachments { (attachment, range) in
            if let mediaAttachment = attachment as? MediaAttachment, mediaAttachment.uploadID == uploadID {
                result = mediaAttachment
            }
        }
        return result
    }

    func refreshGlobalProgress() {
        mediaProgressView.isHidden = !mediaCoordinator.isUploadingMedia(for: post)
        mediaProgressView.progress = Float(mediaCoordinator.totalProgress(for: post))
        postEditorStateContext.update(isUploadingMedia: mediaCoordinator.isUploadingMedia(for: post))
        refreshNavigationBar()
    }

    fileprivate func insert(exportableAsset: ExportableAsset, source: MediaSource, attachment: MediaAttachment? = nil) {
        var attachment = attachment
        if attachment == nil {
            switch exportableAsset.assetMediaType {
            case .image:
                attachment = insertImageAttachment()

                if let attachment = attachment {
                    setGifBadgeIfNecessary(for: attachment, asset: exportableAsset, source: source)
                }
            case .video:
                attachment = insertVideoAttachmentWithPlaceholder()
            default:
                attachment = insertDocumentLinkPlaceholder()
            }
        }

        let info = MediaAnalyticsInfo(origin: .editor(source), selectionMethod: mediaSelectionMethod)
        guard let media = mediaCoordinator.addMedia(from: exportableAsset, to: self.post, analyticsInfo: info) else {
            return
        }
        attachment?.uploadID = media.uploadID
    }

    /// Sets the badge title of `attachment` to "GIF" if either the media is being imported from Giphy,
    /// or if it's a PHAsset with an animated playback style.
    private func setGifBadgeIfNecessary(for attachment: MediaAttachment, asset: ExportableAsset, source: MediaSource) {
        var isGif = (source == .giphy)

        if let asset = asset as? PHAsset,
            asset.playbackStyle == .imageAnimated {
            isGif = true
        }

        if isGif {
            attachment.badgeTitle = Constants.mediaGIFBadgeTitle
        }
    }

    fileprivate func insertExternalMediaWithURL(_ url: URL) {
        insert(exportableAsset: url as NSURL, source: .otherApps)
    }

    fileprivate func insertDeviceMedia(phAsset: PHAsset) {
        insert(exportableAsset: phAsset, source: .deviceLibrary)
    }

    private func insertStockPhotosMedia(_ media: StockPhotosMedia) {
        insert(exportableAsset: media, source: .stockPhotos)
    }

    /// Insert media to the post from the site's media library.
    ///
    func prepopulateMediaItems(_ media: [Media]) {
        mediaSelectionMethod = .mediaUploadWritePost

        media.forEach({ insertSiteMediaLibrary(media: $0) })
    }

    private func insertSiteMediaLibrary(media: Media) {
        if media.hasRemote {
            insertRemoteSiteMediaLibrary(media: media)
        } else {
            insertLocalSiteMediaLibrary(media: media)
        }
    }

    private func insertImageAttachment(with url: URL = Constants.placeholderMediaLink) -> ImageAttachment {
        let attachment = richTextView.replaceWithImage(at: self.richTextView.selectedRange, sourceURL: url, placeHolderImage: Assets.defaultMissingImage)
        attachment.size = .full

        if url.isGif {
            attachment.badgeTitle = Constants.mediaGIFBadgeTitle
        }

        return attachment
    }


    /// Returns an `ImageAttachment` for use as a placeholder until the related document has been
    /// uploaded.
    ///
    /// NB: Use of an `ImageAttachment` here was influenced by visibility of some functions in
    /// `TextView`. See: `storage` & `replace(at:with:)`
    ///
    /// - Returns: `ImageAttachment` configured with an attachment placeholder image
    private func insertDocumentLinkPlaceholder() -> ImageAttachment? {
        let attachment = richTextView.replaceWithImage(at: self.richTextView.selectedRange, sourceURL: Constants.placeholderDocumentLink, placeHolderImage: Assets.linkPlaceholderImage)
        attachment.size = .thumbnail
        return attachment
    }

    /// Replaces the `ImageAttachment` placeholder with the link to the actual uploaded document.
    ///
    /// - Parameters:
    ///   - attachment: the attachment to replact
    ///   - urlString: the URL string for the uploaded document
    private func replacePlaceholder(attachment: ImageAttachment, with urlString: String) {
        let attachmentID = attachment.identifier

        guard
            // NB: TextStorage unwrapping on TextView is internal
            let textViewStorage = richTextView.textStorage as? TextStorage,
            let placeholderRange = textViewStorage.rangeFor(attachmentID: attachmentID),
            let documentURL = URL(string: urlString)
        else {
            return
        }

        richTextView.remove(attachmentID: attachmentID)

        let linkTitle = documentURL.lastPathComponent
        let linkRange = NSMakeRange(placeholderRange.location, 0)
        richTextView.setLink(documentURL, title: linkTitle, inRange: linkRange)
        richTextView.insertText(String(Character(.carriageReturn)))
    }

    private func insertVideoAttachmentWithPlaceholder() -> VideoAttachment {
        let videoAttachment = richTextView.replaceWithVideo(at: richTextView.selectedRange, sourceURL: Constants.placeholderMediaLink, posterURL: Constants.placeholderMediaLink, placeHolderImage: Assets.defaultMissingImage)
        videoAttachment.isShortcode = true
        return videoAttachment
    }

    private func handleThumbnailURL(_ thumbnailURL: URL, attachment: MediaAttachment,
                                    savePostContent: Bool = false) {
        DispatchQueue.main.async {
            if let attachment = attachment as? ImageAttachment {
                attachment.updateURL(thumbnailURL)
                self.richTextView.refresh(attachment)
            }
            else if let attachment = attachment as? VideoAttachment {
                attachment.posterURL = thumbnailURL
                self.richTextView.refresh(attachment)
            }

            if savePostContent {
                self.mapUIContentToPostAndSave(immediate: true)
            }
        }
    }

    fileprivate func insertRemoteSiteMediaLibrary(media: Media) {

        guard let remoteURLStr = media.remoteURL, let remoteURL = URL(string: remoteURLStr) else {
            return
        }
        switch media.mediaType {
        case .image:
            let attachment = insertImageAttachment(with: remoteURL)
            attachment.alt = media.alt
            WPAppAnalytics.track(.editorAddedPhotoViaWPMediaLibrary, withProperties: WPAppAnalytics.properties(for: media, selectionMethod: mediaSelectionMethod), with: post)
        case .video:
            var posterURL: URL?
            if let posterURLString = media.remoteThumbnailURL {
                posterURL = URL(string: posterURLString)
            }
            let attachment = richTextView.replaceWithVideo(at: richTextView.selectedRange, sourceURL: remoteURL, posterURL: posterURL, placeHolderImage: Assets.defaultMissingImage)
            if let videoPressGUID = media.videopressGUID, !videoPressGUID.isEmpty {
                attachment.videoPressID = videoPressGUID
                richTextView.refresh(attachment)
            }
            WPAppAnalytics.track(.editorAddedVideoViaWPMediaLibrary, withProperties: WPAppAnalytics.properties(for: media, selectionMethod: mediaSelectionMethod), with: post)
        default:
            // If we drop in here, let's just insert a link the the remote media
            let linkTitle = media.title?.nonEmptyString() ?? remoteURLStr
            richTextView.setLink(remoteURL, title: linkTitle, inRange: richTextView.selectedRange)
            WPAppAnalytics.track(.editorAddedOtherMediaViaWPMediaLibrary, withProperties: WPAppAnalytics.properties(for: media, selectionMethod: mediaSelectionMethod), with: post)
        }
    }

    fileprivate func insertLocalSiteMediaLibrary(media: Media) {

        var tempMediaURL = Constants.placeholderMediaLink
        if let absoluteURL = media.absoluteLocalURL {
            tempMediaURL = absoluteURL
        }
        var attachment: MediaAttachment?
        if media.mediaType == .image {
            attachment = insertImageAttachment(with: tempMediaURL)
        } else if media.mediaType == .video,
            let remoteURLStr = media.remoteURL,
            let remoteURL = URL(string: remoteURLStr) {
            attachment = richTextView.replaceWithVideo(at: richTextView.selectedRange, sourceURL: remoteURL, posterURL: media.absoluteThumbnailLocalURL, placeHolderImage: Assets.defaultMissingImage)
        }
        if let attachment = attachment {
            attachment.uploadID = media.uploadID
            let info = MediaAnalyticsInfo(origin: .editor(.wpMediaLibrary), selectionMethod: mediaSelectionMethod)
            mediaCoordinator.addMedia(media, to: post, analyticsInfo: info)
        }
    }

    fileprivate func saveToMedia(attachment: MediaAttachment) {
        guard let image = attachment.image else {
            return
        }
        insert(exportableAsset: image, source: .otherApps, attachment: attachment)
    }

    private func handleUploadStarted(attachment: MediaAttachment) {
        attachment.overlayImage = nil
        attachment.message = nil
        attachment.shouldHideBorder = false
        attachment.progress = 0
        richTextView.refresh(attachment, overlayUpdateOnly: true)
    }

    private func handleUploaded(media: Media, mediaUploadID: String) {
        guard let remoteURLStr = media.remoteURL,
              let remoteURL = URL(string: remoteURLStr)
        else {
            return
        }

        switch editorView.editingMode {
        case .richText:
            guard let attachment = self.findAttachment(withUploadID: mediaUploadID) else {
                return
            }
            attachment.uploadID = nil
            attachment.progress = nil
            if let imageAttachment = attachment as? ImageAttachment {
                if media.mediaType == .image {
                    if let width = media.width?.intValue {
                        imageAttachment.width = width
                    }
                    if let height = media.height?.intValue {
                        imageAttachment.height = height
                    }
                    if let mediaID = media.mediaID?.intValue {
                        imageAttachment.imageID = mediaID
                    }
                    imageAttachment.updateURL(remoteURL, refreshAsset: false)
                    richTextView.refresh(attachment, overlayUpdateOnly: true)
                } else {
                    guard let documentURLString = media.remoteURL else { return }
                    replacePlaceholder(attachment: imageAttachment, with: documentURLString)
                }
            } else if let videoAttachment = attachment as? VideoAttachment, let videoURLString = media.remoteURL {
                videoAttachment.updateURL(URL(string: videoURLString))
                var posterChange = false
                if let videoPosterURLString = media.remoteThumbnailURL {
                    videoAttachment.posterURL = URL(string: videoPosterURLString)
                    posterChange = true
                }
                if let videoPressGUID = media.videopressGUID, !videoPressGUID.isEmpty {
                    videoAttachment.videoPressID = videoPressGUID
                } else {
                    videoAttachment.isShortcode = true
                }
                richTextView.refresh(attachment, overlayUpdateOnly: !posterChange)
            }
        case .html:
            if media.mediaType == .image {
                let imgPostUploadProcessor = ImgUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, width: media.width?.intValue, height: media.height?.intValue)
                htmlTextView.text = imgPostUploadProcessor.process(htmlTextView.text)
            } else if media.mediaType == .video {
                let videoPostUploadProcessor = VideoUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, videoPressID: media.videopressGUID)
                htmlTextView.text = videoPostUploadProcessor.process(htmlTextView.text)
            } else {
                let documentTitle = remoteURL.lastPathComponent
                let documentUploadProcessor = DocumentUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, title: documentTitle)
                htmlTextView.text = documentUploadProcessor.process(htmlTextView.text)
            }
        }
    }

    private func handleError(_ error: Error?, onAttachment attachment: Aztec.MediaAttachment) {
        if let nserror = error as NSError?, nserror.domain == NSURLErrorDomain && nserror.code == NSURLErrorCancelled {
            self.richTextView.remove(attachmentID: attachment.identifier)
            return
        }
        if let videoExportError = error as? MediaVideoExporter.VideoExportError, videoExportError == MediaVideoExporter.VideoExportError.videoExportSessionCancelled {
            self.richTextView.remove(attachmentID: attachment.identifier)
            return
        }

        WPAppAnalytics.track(.editorUploadMediaFailed, withProperties: [WPAppAnalyticsKeyEditorSource: Analytics.editorSource], with: self.post.blog)

        let message = MediaAttachmentActionSheet.failedMediaActionTitle

        let attributeMessage = NSAttributedString(string: message, attributes: Constants.mediaMessageAttributes)
        attachment.message = attributeMessage
        attachment.overlayImage = Gridicon.iconOfType(.refresh, withSize: Constants.mediaOverlayIconSize)
        attachment.shouldHideBorder = true
        attachment.progress = nil
        richTextView.refresh(attachment, overlayUpdateOnly: true)
    }

    private func handleProgress(_ value: Double, forMedia media: Media, onAttachment attachment: Aztec.MediaAttachment) {
        guard media.remoteStatus == .processing || media.remoteStatus == .pushing else {
            return
        }
        if value >= 1 {
            attachment.progress = nil
        } else {
            attachment.progress = value
        }
        richTextView.refresh(attachment, overlayUpdateOnly: true)
    }

    fileprivate var failedMediaIDs: [String] {
        var failedIDs = [String]()
        richTextView.textStorage.enumerateAttachments { (attachment, range) in
            guard let mediaAttachment = attachment as? MediaAttachment,
                let mediaUploadID = mediaAttachment.uploadID,
                let media = self.mediaCoordinator.media(withObjectID: mediaUploadID),
                media.error != nil
                else {
                    return
            }
            failedIDs.append(mediaUploadID)
        }
        return failedIDs
    }

    var hasFailedMedia: Bool {
        return !failedMediaIDs.isEmpty
    }

    func removeFailedMedia() {
        for mediaID in failedMediaIDs {
            if let attachment = self.findAttachment(withUploadID: mediaID) {
                richTextView.remove(attachmentID: attachment.identifier)
            }
            if let media = mediaCoordinator.media(withObjectID: mediaID) {
                mediaCoordinator.delete(media)
            }
        }
    }

    fileprivate func retryAllFailedMediaUploads() {
        for mediaID in failedMediaIDs {
            guard let attachment = self.findAttachment(withUploadID: mediaID),
                let media = mediaCoordinator.media(withObjectID: mediaID) else {
                continue
            }
            retryFailedMediaUpload(media: media, attachment: attachment)
        }
    }

    fileprivate func retryFailedMediaUpload(media: Media, attachment: MediaAttachment) {
        resetMediaAttachmentOverlay(attachment)
        attachment.progress = 0
        richTextView.refresh(attachment)

        let info = MediaAnalyticsInfo(origin: .editor(.none), selectionMethod: mediaSelectionMethod)
        mediaCoordinator.retryMedia(media, analyticsInfo: info)
    }

    fileprivate func processMediaAttachments() {
        refreshGlobalProgress()
        richTextView.textStorage.enumerateAttachments { (attachment, range) in
            guard let mediaAttachment = attachment as? MediaAttachment else {
                return
            }
            // Check if media is uploading and we have a media object for it
            if let mediaUploadID = mediaAttachment.uploadID,
               let media = self.mediaCoordinator.media(withObjectID: mediaUploadID) {
                if let thumbnailURL = media.absoluteThumbnailLocalURL {
                    self.handleThumbnailURL(thumbnailURL, attachment: mediaAttachment)
                }

                if let error = media.error {
                    self.handleError(error, onAttachment: mediaAttachment)
                }

                if let progress = self.mediaCoordinator.progress(for: media) {
                    self.handleProgress(progress.fractionCompleted, forMedia: media, onAttachment: mediaAttachment)
                }
            } else {
                if let videoAttachment = mediaAttachment as? VideoAttachment {
                    self.process(videoAttachment: videoAttachment)
                }
            }

            if let imageAttachment = mediaAttachment as? ImageAttachment,
                let url = imageAttachment.url {
                if url.isGif {
                    imageAttachment.badgeTitle = Constants.mediaGIFBadgeTitle
                }
            }
        }
    }

    fileprivate func process(videoAttachment: VideoAttachment) {
        // Use a placeholder for video while trying to generate a thumbnail
        DispatchQueue.main.async {
            videoAttachment.image = Gridicon.iconOfType(.video, withSize: Constants.mediaPlaceholderImageSize)
            self.richTextView.refresh(videoAttachment)
        }
        if let videoSrcURL = videoAttachment.url,
           videoSrcURL.scheme == VideoShortcodeProcessor.videoPressScheme,
           let videoPressID = videoSrcURL.host {
            // It's videoPress video so let's fetch the information for the video
            let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            mediaService.getMediaURL(fromVideoPressID: videoPressID, in: self.post.blog, success: { (videoURLString, posterURLString) in
                videoAttachment.updateURL(URL(string: videoURLString))
                if let validPosterURLString = posterURLString, let posterURL = URL(string: validPosterURLString) {
                    videoAttachment.posterURL = posterURL
                }
                self.richTextView.refresh(videoAttachment)
            }, failure: { (error) in
                DDLogError("Unable to find information for VideoPress video with ID = \(videoPressID). Details: \(error.localizedDescription)")
            })
        }
    }

    fileprivate func displayActions(forAttachment attachment: MediaAttachment, position: CGPoint) {
        let attachmentID = attachment.identifier
        let title: String = MediaAttachmentActionSheet.title
        var message: String?
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: MediaAttachmentActionSheet.dismissActionTitle, style: .cancel) { (action) in
            if attachment == self.currentSelectedAttachment {
                self.currentSelectedAttachment = nil
                self.resetMediaAttachmentOverlay(attachment)
                self.richTextView.refresh(attachment)
            }
        }
        alertController.addAction(dismissAction)

        var showDefaultActions = true
        if let mediaUploadID = attachment.uploadID,
            let media = mediaCoordinator.media(withIdentifier: mediaUploadID, for: post) {
            // Is upload still going?
            if media.remoteStatus == .pushing || media.remoteStatus == .processing {
                showDefaultActions = false
                alertController.addActionWithTitle(MediaAttachmentActionSheet.stopUploadActionTitle,
                                                   style: .destructive,
                                                   handler: { (action) in
                                                    self.mediaCoordinator.cancelUpload(of: media)
                })
            }
        } else {
            alertController.addActionWithTitle(attachment is ImageAttachment ? MediaAttachmentActionSheet.removeImageActionTitle : MediaAttachmentActionSheet.removeVideoActionTitle,
                style: .destructive,
                handler: { (action) in
                    self.richTextView.remove(attachmentID: attachmentID)
            })
        }
        if let mediaUploadID = attachment.uploadID,
           let media = mediaCoordinator.media(withObjectID: mediaUploadID),
           let error = media.error {
            showDefaultActions = false
            message = error.localizedDescription
            // only show retry options if we at least have a local file to try to upload again.
            if media.absoluteLocalURL != nil {
                if failedMediaIDs.count > 1 {
                    alertController.addActionWithTitle(MediaAttachmentActionSheet.retryAllFailedUploadsActionTitle,
                                                       style: .default,
                                                       handler: { [weak self] (action) in
                                                        self?.retryAllFailedMediaUploads()
                    })
                }

                alertController.addActionWithTitle(MediaAttachmentActionSheet.retryUploadActionTitle,
                                                   style: .default,
                                                   handler: { [weak self] (action) in
                                                    guard let strongSelf = self,
                                                        let attachment = strongSelf.richTextView.attachment(withId: attachmentID) else {
                                                            return
                                                    }
                                                    strongSelf.retryFailedMediaUpload(media: media, attachment: attachment)
                })
            }
        }

        if showDefaultActions {
            if let imageAttachment = attachment as? ImageAttachment {
                alertController.preferredAction = alertController.addActionWithTitle(MediaAttachmentActionSheet.editActionTitle,
                                                                                     style: .default,
                                                                                     handler: { (action) in
                                                                                        self.displayDetails(forAttachment: imageAttachment)
                })
            } else if let videoAttachment = attachment as? VideoAttachment {
                alertController.preferredAction = alertController.addActionWithTitle(MediaAttachmentActionSheet.playVideoActionTitle,
                                                                                     style: .default,
                                                                                     handler: { (action) in
                                                                                        self.displayPlayerFor(videoAttachment: videoAttachment, atPosition: position)
                })
            }
        }

        alertController.title = title
        alertController.message = message
        alertController.popoverPresentationController?.sourceView = richTextView
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: position, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated: true, completion: { () in
            UIMenuController.shared.setMenuVisible(false, animated: false)
        })
    }

    func displayDetails(forAttachment attachment: ImageAttachment) {
        guard let attachmentRange = richTextView.textStorage.ranges(forAttachment: attachment).first else {
            return
        }

        let caption = richTextView.caption(for: attachment)

        let controller = AztecAttachmentViewController()
        controller.attachment = attachment
        controller.caption = caption
        var oldURL: URL?

        if let linkRange = richTextView.linkFullRange(forRange: attachmentRange),
            let url = richTextView.linkURL(forRange: attachmentRange),
            NSIntersectionRange(attachmentRange, linkRange) == attachmentRange {
            oldURL = url
            controller.linkURL = url
        }

        controller.onUpdate = { [weak self] (alignment, size, linkURL, alt, caption) in

            guard let `self` = self else {
                return
            }

            let attachment = self.richTextView.edit(attachment) { attachment in
                attachment.alignment = alignment
                attachment.size = size
                attachment.alt = alt
            }

            if let caption = caption, caption.length > 0 {
                self.richTextView.replaceCaption(for: attachment, with: caption)
            } else {
                self.richTextView.removeCaption(for: attachment)
            }

            // Update associated link
            if let updatedURL = linkURL {
                self.richTextView.setLink(updatedURL, inRange: attachmentRange)
            } else if oldURL != nil && linkURL == nil {
                self.richTextView.removeLink(inRange: attachmentRange)
            }
        }

        controller.onCancel = { [weak self] in
            if attachment == self?.currentSelectedAttachment {
                self?.currentSelectedAttachment = nil
                self?.resetMediaAttachmentOverlay(attachment)
                self?.richTextView.refresh(attachment)
            }
        }

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)

        WPAppAnalytics.track(.editorEditedImage, withProperties: [WPAppAnalyticsKeyEditorSource: Analytics.editorSource], with: post)
    }

    func displayPlayerFor(videoAttachment: VideoAttachment, atPosition position: CGPoint) {
        guard let videoURL = videoAttachment.mediaURL else {
            return
        }
        guard let videoPressID = videoAttachment.videoPressID else {
            displayVideoPlayer(for: videoURL)
            return
        }
        // It's videoPress video so let's fetch the information for the video
        let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        mediaService.getMediaURL(fromVideoPressID: videoPressID, in: self.post.blog, success: { [weak self] (videoURLString, posterURLString) in
            guard let `self` = self else {
                return
            }
            guard let videoURL = URL(string: videoURLString) else {
                self.displayUnableToPlayVideoAlert()
                return
            }
            videoAttachment.updateURL(videoURL)
            if let validPosterURLString = posterURLString, let posterURL = URL(string: validPosterURLString) {
                videoAttachment.posterURL = posterURL
            }
            self.richTextView.refresh(videoAttachment)
            self.displayVideoPlayer(for: videoURL)
        }, failure: { [weak self] (error) in
            self?.displayUnableToPlayVideoAlert()
            DDLogError("Unable to find information for VideoPress video with ID = \(videoPressID). Details: \(error.localizedDescription)")
        })
    }

    func displayVideoPlayer(for videoURL: URL) {
        let asset = AVURLAsset(url: videoURL)
        let controller = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        controller.showsPlaybackControls = true
        controller.player = player
        player.play()
        present(controller, animated: true)
    }

    func displayUnableToPlayVideoAlert() {
        let alertController = UIAlertController(title: MediaUnableToPlayVideoAlert.title, message: MediaUnableToPlayVideoAlert.message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: nil))
        present(alertController, animated: true)
        return
    }

    func fetchPosterImageFor(videoAttachment: VideoAttachment, onSuccess: @escaping (UIImage) -> (), onFailure: @escaping () -> ()) {
        guard let videoSrcURL = videoAttachment.mediaURL, videoSrcURL != Constants.placeholderMediaLink, videoAttachment.posterURL == nil else {
            onFailure()
            return
        }
        mediaUtility.fetchPosterImage(for: videoSrcURL, onSuccess: onSuccess, onFailure: onFailure)
    }

    func downloadImage(from url: URL, success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        let receipt = mediaUtility.downloadImage(from: url, post: post, success: success, onFailure: { (_) in failure()})
        activeMediaRequests.append(receipt)
    }

    @objc func applicationWillResignActive(_ notification: Foundation.Notification) {

        // [2018-03-05] Need to close the options VC on backgrounding to prevent view hierarchy inconsistency crasher.
        optionsTablePresenter.dismiss()

        // [2017-08-30] We need to auto-close the input media picker when multitasking panes are resized - iOS
        // is dropping the input picker's view from the view hierarchy. Not an ideal solution, but prevents
        // the user from seeing an empty grey rect as a keyboard. Issue affects the 7.9", 9.7", and 10.5"
        // iPads only...not the 12.9"
        // See http://www.openradar.me/radar?id=4972612522344448 for more details.
        //
        if UIDevice.isPad() {
            closeMediaPickerInputViewController()
        }
    }

    func closeMediaPickerInputViewController() {
        guard mediaPickerInputViewController != nil else {
            return
        }
        mediaPickerInputViewController = nil
        changeRichTextInputView(to: nil)
        updateToolbar(formatBar, forMode: .text)
        restoreInputAssistantItems()
    }

    fileprivate func resetMediaAttachmentOverlay(_ mediaAttachment: MediaAttachment) {
        // having an uploadID means we are uploading or just finished uplading (successfully or not). In this case, we remove the overlay only if no error
        if let uploadID = mediaAttachment.uploadID,
            let media = self.mediaFor(uploadID: uploadID) {
            if media.error == nil {
                mediaAttachment.overlayImage = nil
                mediaAttachment.message = nil
                mediaAttachment.shouldHideBorder = false
            }
        // For an existing media we set it's message to nil so the glyphImage will be removed.
        } else {
            mediaAttachment.message = nil
        }
    }
}


// MARK: - TextViewAttachmentDelegate Conformance
//
extension AztecPostViewController: TextViewAttachmentDelegate {

    public func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        if !richTextView.isFirstResponder {
            richTextView.becomeFirstResponder()
        }

        switch attachment {
        case let attachment as HTMLAttachment:
            displayUnknownHtmlEditor(for: attachment)
        case let attachment as MediaAttachment:
            selected(textAttachment: attachment, atPosition: position)
        default:
            break
        }
    }

    func selected(textAttachment attachment: MediaAttachment, atPosition position: CGPoint) {
        // Check to see if there is an error associated to the attachment
        var errorAssociatedToAttachment = false
        if let uploadID = attachment.uploadID,
            let media = mediaFor(uploadID: uploadID),
            media.error != nil {
            errorAssociatedToAttachment = true
        }

        if !errorAssociatedToAttachment {
            // If it's a new attachment tapped let's unmark the previous one...
            if let selectedAttachment = currentSelectedAttachment {
                resetMediaAttachmentOverlay(selectedAttachment)
                richTextView.refresh(selectedAttachment)
            }

            // ...and mark the newly tapped attachment
            let message = ""
            attachment.message = NSAttributedString(string: message, attributes: Constants.mediaMessageAttributes)
            richTextView.refresh(attachment)
            currentSelectedAttachment = attachment
        }

        // Display the action sheet right away
        displayActions(forAttachment: attachment, position: position)
    }

    public func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        deselected(textAttachment: attachment, atPosition: position)
    }

    func deselected(textAttachment attachment: NSTextAttachment, atPosition position: CGPoint) {
        currentSelectedAttachment = nil
        if let mediaAttachment = attachment as? MediaAttachment {
            self.resetMediaAttachmentOverlay(mediaAttachment)
            richTextView.refresh(mediaAttachment)
            processMediaAttachments()
        }
    }

    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        switch attachment {
        case let videoAttachment as VideoAttachment:
            guard let posterURL = videoAttachment.posterURL else {
                // Let's get a frame from the video directly
                fetchPosterImageFor(videoAttachment: videoAttachment, onSuccess: success, onFailure: failure)
                return
            }
            downloadImage(from: posterURL, success: success, onFailure: failure)
        case is ImageAttachment:
            downloadImage(from: url, success: success, onFailure: failure)
        default:
            failure()
        }

    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        saveToMedia(attachment: imageAttachment)
        return nil
    }

    func cancelAllPendingMediaRequests() {
        for receipt in activeMediaRequests {
            receipt.cancel()
        }
        activeMediaRequests.removeAll()
    }

    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
        guard let uploadID = attachment.uploadID,
            let media = mediaCoordinator.media(withIdentifier: uploadID, for: post),
            (media.remoteStatus == .pushing || media.remoteStatus == .processing)
        else {
            return
        }
        mediaCoordinator.delete(media)
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return mediaUtility.placeholderImage(for: attachment, size: Constants.mediaPlaceholderImageSize)
    }
}


// MARK: - MediaPickerViewController Delegate Conformance
//
extension AztecPostViewController: WPMediaPickerViewControllerDelegate {

    func emptyViewController(forMediaPickerController picker: WPMediaPickerViewController) -> UIViewController? {
        if picker != mediaPickerInputViewController?.mediaPicker {
            return noResultsView
        }
        return nil
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didUpdateSearchWithAssetCount assetCount: Int) {
        noResultsView.removeFromView()

        if (mediaLibraryDataSource.searchQuery?.count ?? 0) > 0 {
            noResultsView.configureForNoSearchResult()
        }
    }

    func mediaPickerControllerWillBeginLoadingData(_ picker: WPMediaPickerViewController) {
        updateSearchBar(mediaPicker: picker)
        noResultsView.configureForFetching()
    }

    func mediaPickerControllerDidEndLoadingData(_ picker: WPMediaPickerViewController) {
        updateSearchBar(mediaPicker: picker)
        noResultsView.removeFromView()
        noResultsView.configureForNoAssets(userCanUploadMedia: false)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        if picker != mediaPickerInputViewController?.mediaPicker {
            unregisterChangeObserver()
            mediaLibraryDataSource.searchCancelled()
            dismiss(animated: true)
        }
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        if picker != mediaPickerInputViewController?.mediaPicker {
            unregisterChangeObserver()
            mediaLibraryDataSource.searchCancelled()
            dismiss(animated: true)
            mediaSelectionMethod = .fullScreenPicker
        } else {
            mediaSelectionMethod = .inlinePicker
        }

        closeMediaPickerInputViewController()

        if assets.isEmpty {
            return
        }

        for asset in assets {
            switch asset {
            case let phAsset as PHAsset:
                insertDeviceMedia(phAsset: phAsset)
            case let media as Media:
                insertSiteMediaLibrary(media: media)
            default:
                continue
            }
        }
    }


    func mediaPickerController(_ picker: WPMediaPickerViewController, selectionChanged assets: [WPMediaAsset]) {
        updateFormatBarInsertAssetCount()
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didSelect asset: WPMediaAsset) {
        updateFormatBarInsertAssetCount()
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didDeselect asset: WPMediaAsset) {
        updateFormatBarInsertAssetCount()
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, previewViewControllerFor assets: [WPMediaAsset], selectedIndex selected: Int) -> UIViewController? {
        mediaPreviewHelper = MediaPreviewHelper(assets: assets)
        return mediaPreviewHelper?.previewViewController(selectedIndex: selected)
    }

    private func updateFormatBarInsertAssetCount() {
        guard let assetCount = mediaPickerInputViewController?.mediaPicker.selectedAssets.count else {
            return
        }

        if assetCount == 0 {
            formatBar.trailingItem = nil
        } else {
            insertToolbarItem.setTitle(String(format: Constants.mediaPickerInsertText, NSNumber(value: assetCount)), for: .normal)
            insertToolbarItem.accessibilityIdentifier = "insert_media_button"

            if formatBar.trailingItem != insertToolbarItem {
                formatBar.trailingItem = insertToolbarItem
            }
        }
    }
}

// MARK: - Accessibility Helpers
//
extension UIImage {
    func addAccessibilityForAttachment(_ attachment: NSTextAttachment) {
        if let attachment = attachment as? ImageAttachment,
            let accessibilityLabel = attachment.alt {
            self.accessibilityLabel = accessibilityLabel
        }
    }
}

// MARK: - UIDocumentPickerDelegate

extension AztecPostViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        mediaSelectionMethod = .documentPicker

        guard urls.count == 1 else {
            for documentURL in urls {
                insertExternalMediaWithURL(documentURL)
            }
            return
        }

        if let documentURL = urls.first {
            displayInsertionOpensAlertIfNeeded(for: documentURL)
        }
    }
}

extension AztecPostViewController: StockPhotosPickerDelegate {
    func stockPhotosPicker(_ picker: StockPhotosPicker, didFinishPicking assets: [StockPhotosMedia]) {
        assets.forEach {
            insert(exportableAsset: $0, source: .stockPhotos)
        }
    }
}

extension AztecPostViewController: GiphyPickerDelegate {
    func giphyPicker(_ picker: GiphyPicker, didFinishPicking assets: [GiphyMedia]) {
        assets.forEach {
            insert(exportableAsset: $0, source: .giphy)
        }
    }
}

// MARK: - Constants
//
extension AztecPostViewController {

    struct Analytics {
        static let editorSource             = "aztec"
        static let headerStyleValues = ["none", "h1", "h2", "h3", "h4", "h5", "h6"]
    }

    struct Assets {
        static let closeButtonModalImage    = Gridicon.iconOfType(.cross)
        static let closeButtonRegularImage  = UIImage(named: "icon-posts-editor-chevron")
        static let defaultMissingImage      = Gridicon.iconOfType(.image)
        static let linkPlaceholderImage     = Gridicon.iconOfType(.pages)
    }

    struct Constants {
        static let defaultMargin            = CGFloat(20)
        static let blogPickerCompactSize    = CGSize(width: 125, height: 30)
        static let blogPickerRegularSize    = CGSize(width: 300, height: 30)
        static let savingDraftButtonSize    = CGSize(width: 130, height: 30)
        static let uploadingButtonSize      = CGSize(width: 150, height: 30)
        static let moreAttachmentText       = "more"
        static let placeholderPadding       = UIEdgeInsets(top: 8, left: 5, bottom: 0, right: 0)
        static let headers                  = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let lists                    = [TextList.Style.unordered, .ordered]
        static let toolbarHeight            = CGFloat(44.0)
        static let mediaPickerInsertText    = NSLocalizedString("Insert %@", comment: "Button title used in media picker to insert media (photos / videos) into a post. Placeholder will be the number of items that will be inserted.")
        static let mediaPickerKeyboardHeightRatioPortrait   = CGFloat(0.20)
        static let mediaPickerKeyboardHeightRatioLandscape  = CGFloat(0.30)
        static let mediaOverlayBorderWidth  = CGFloat(3.0)
        static let mediaOverlayIconSize     = CGSize(width: 32, height: 32)
        static let mediaGIFBadgeTitle       = NSLocalizedString("GIF", comment: "Badge title displayed on GIF images in the editor.")
        static let mediaPlaceholderImageSize = CGSize(width: 128, height: 128)
        static let mediaMessageAttributes: [NSAttributedString.Key: Any] = {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            return [.font: Fonts.mediaOverlay,
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: UIColor.white]
        }()
        static let placeholderMediaLink = URL(string: "placeholder://")!
        static let placeholderDocumentLink = URL(string: "documentUploading://")!

        struct Animations {
            static let formatBarMediaButtonRotationDuration: TimeInterval = 0.3
            static let formatBarMediaButtonRotationAngle: CGFloat = .pi / 4.0
        }
    }

    struct MoreSheetAlert {
        static let gutenbergTitle = NSLocalizedString(
            "Switch to block editor",
            comment: "Switches from the classic editor to block editor."
        )
        static let htmlTitle = NSLocalizedString("Switch to HTML Mode", comment: "Switches the Editor to HTML Mode")
        static let richTitle = NSLocalizedString("Switch to Visual Mode", comment: "Switches the Editor to Rich Text Mode")
        static let previewTitle = NSLocalizedString("Preview", comment: "Displays the Post Preview Interface")
        static let historyTitle = NSLocalizedString("History", comment: "Displays the History screen from the editor's alert sheet")
        static let postSettingsTitle = NSLocalizedString("Post Settings", comment: "Name of the button to open the post settings")
        static let keepEditingTitle = NSLocalizedString("Keep Editing", comment: "Goes back to editing the post.")
    }

    struct MediaAttachmentActionSheet {
        static let title = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
        static let dismissActionTitle = NSLocalizedString("Dismiss", comment: "User action to dismiss media options.")
        static let stopUploadActionTitle = NSLocalizedString("Stop upload", comment: "User action to stop upload.")
        static let retryUploadActionTitle = NSLocalizedString("Retry", comment: "User action to retry media upload.")
        static let retryAllFailedUploadsActionTitle = NSLocalizedString("Retry all", comment: "User action to retry all failed media uploads.")
        static let editActionTitle = NSLocalizedString("Edit", comment: "User action to edit media details.")
        static let playVideoActionTitle = NSLocalizedString("Play video", comment: "User action to play a video on the editor.")
        static let removeImageActionTitle = NSLocalizedString("Remove image", comment: "User action to remove image.")
        static let removeVideoActionTitle = NSLocalizedString("Remove video", comment: "User action to remove video.")
        static let failedMediaActionTitle = NSLocalizedString("Failed to insert media.\n Please tap for options.", comment: "Error message to show to use when media insertion on a post fails")
    }

    struct Colors {
        static let aztecBackground              = UIColor.basicBackground
        static let title                        = UIColor.text
        static let separator                    = UIColor.divider
        static let placeholder                  = UIColor.textPlaceholder
        static let progressBackground           = UIColor.primary
        static let progressTint                 = UIColor.white
        static let progressTrack                = UIColor.primary
        static let mediaProgressOverlay         = UIColor.neutral(.shade70).withAlphaComponent(CGFloat(0.6))
        static let mediaProgressBarBackground   = UIColor.neutral(.shade0)
        static let mediaProgressBarTrack        = UIColor.primary
        static let aztecLinkColor               = UIColor.primary
        static let mediaOverlayBorderColor      = UIColor.primary
    }

    struct Fonts {
        static let regular                  = WPFontManager.notoRegularFont(ofSize: 16)
        static let title                    = WPFontManager.notoBoldFont(ofSize: 24.0)
        static let mediaPickerInsert        = WPFontManager.systemMediumFont(ofSize: 15.0)
        static let mediaOverlay             = WPFontManager.systemSemiBoldFont(ofSize: 15.0)
        static let monospace                = UIFont(name: "Menlo-Regular", size: 16.0)!
    }

    struct Restoration {
        static let restorationIdentifier    = "AztecPostViewController"
        static let postIdentifierKey        = AbstractPost.classNameWithoutNamespaces()
    }

    struct MediaUploadingCancelAlert {
        static let title = NSLocalizedString("Cancel media uploads", comment: "Dialog box title for when the user is canceling an upload.")
        static let message = NSLocalizedString("You are currently uploading media. This action will cancel uploads in progress.\n\nAre you sure?", comment: "This prompt is displayed when the user attempts to stop media uploads in the post editor.")
        static let acceptTitle  = NSLocalizedString("Yes", comment: "Yes")
        static let cancelTitle  = NSLocalizedString("Not Now", comment: "Nicer dialog answer for \"No\".")
    }

    struct MediaUnableToPlayVideoAlert {
        static let title = NSLocalizedString("Unable to play video", comment: "Dialog box title for when the user is canceling an upload.")
        static let message = NSLocalizedString("Something went wrong. Please check your connectivity and try again.", comment: "This prompt is displayed when the user attempts to play a video in the editor but for some reason we are unable to retrieve from the server.")
    }

}

extension AztecPostViewController: PostEditorNavigationBarManagerDelegate {
    var publishButtonText: String {
        return self.postEditorStateContext.publishButtonText
    }

    var isPublishButtonEnabled: Bool {
        return self.postEditorStateContext.isPublishButtonEnabled
    }

    var uploadingButtonSize: CGSize {
        return Constants.uploadingButtonSize
    }

    var savingDraftButtonSize: CGSize {
        return Constants.savingDraftButtonSize
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton) {
        closeWasPressed()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {
        moreWasPressed()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, blogPickerWasPressed sender: UIButton) {
        blogPickerWasPressed()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        publishButtonTapped(sender: sender)
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {
        displayCancelMediaUploads()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, reloadLeftNavigationItems items: [UIBarButtonItem]) {
        navigationItem.leftBarButtonItems = items
    }
}
