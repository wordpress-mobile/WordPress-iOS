import Foundation
import UIKit
import Aztec
import CocoaLumberjack
import Gridicons
import WordPressShared
import AFNetworking
import WPMediaPicker
import SVProgressHUD
import AVKit


// MARK: - Aztec's Native Editor!
//
class AztecPostViewController: UIViewController, PostEditor {

    /// Closure to be executed when the editor gets closed
    ///
    var onClose: ((_ changesSaved: Bool) -> ())?


    /// Indicates if Aztec was launched for Photo Posting
    ///
    var isOpenedDirectlyForPhotoPost = false


    /// Format Bar
    ///
    fileprivate(set) lazy var formatBar: Aztec.FormatBar = {
        return self.createToolbar()
    }()


    /// Aztec's Awesomeness
    ///
    fileprivate(set) lazy var richTextView: Aztec.TextView = {

        let paragraphStyle = ParagraphStyle.default

        // Paragraph style customizations will go here.
        paragraphStyle.lineSpacing = 4

        let textView = Aztec.TextView(defaultFont: Fonts.regular, defaultParagraphStyle: paragraphStyle, defaultMissingImage: Assets.defaultMissingImage)

        textView.inputProcessor = PipelineProcessor([VideoShortcodeProcessor.videoPressPreProcessor,
                                                     VideoShortcodeProcessor.wordPressVideoPreProcessor,
                                                     CalypsoProcessorIn()])

        textView.outputProcessor = PipelineProcessor([VideoShortcodeProcessor.videoPressPostProcessor,
                                                      VideoShortcodeProcessor.wordPressVideoPostProcessor,
                                                      CalypsoProcessorOut()])

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        let linkAttributes: [NSAttributedStringKey: Any] = [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
                                                            .foregroundColor: Colors.aztecLinkColor]

        textView.delegate = self
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self
        textView.backgroundColor = Colors.aztecBackground
        textView.linkTextAttributes = NSAttributedStringKey.convertToRaw(attributes: linkAttributes)
        textView.textAlignment = .natural

        if #available(iOS 11, *) {
            textView.smartDashesType = .no
            textView.smartQuotesType = .no
        }

        return textView
    }()


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
        return label
    }()


    /// Raw HTML Editor
    ///
    fileprivate(set) lazy var htmlTextView: UITextView = {
        let storage = HTMLStorage(defaultFont: Fonts.monospace)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)

        let textView = UITextView(frame: .zero, textContainer: container)

        let accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        textView.isHidden = true
        textView.delegate = self
        textView.accessibilityIdentifier = "HTMLContentView"
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none

        if #available(iOS 11, *) {
            textView.smartDashesType = .no
            textView.smartQuotesType = .no
        }

        return textView

    }()


    /// Title's UITextView
    ///
    fileprivate(set) lazy var titleTextField: UITextView = {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .natural

        let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: UIColor.darkText,
                                                        .font: Fonts.title,
                                                        .paragraphStyle: titleParagraphStyle]

        let textView = UITextView()

        textView.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        textView.delegate = self
        textView.font = Fonts.title
        textView.returnKeyType = .next
        textView.textColor = UIColor.darkText
        textView.typingAttributes = NSAttributedStringKey.convertToRaw(attributes: attributes)
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

        let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: Colors.title, .font: Fonts.title]

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


    /// Negative Offset BarButtonItem: Used to fine tune navigationBar Items
    ///
    fileprivate lazy var separatorButtonItem: UIBarButtonItem = {
        let separator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        return separator
    }()


    /// NavigationBar's Close Button
    ///
    fileprivate lazy var closeBarButtonItem: UIBarButtonItem = {
        let cancelItem = UIBarButtonItem(customView: self.closeButton)
        cancelItem.accessibilityLabel = NSLocalizedString("Close", comment: "Action button to close edior and cancel changes or insertion of post")
        cancelItem.accessibilityIdentifier = "Close"
        return cancelItem
    }()


    /// NavigationBar's Blog Picker Button
    ///
    fileprivate lazy var blogPickerBarButtonItem: UIBarButtonItem = {
        let pickerItem = UIBarButtonItem(customView: self.blogPickerButton)
        pickerItem.accessibilityLabel = NSLocalizedString("Switch Blog", comment: "Action button to switch the blog to which you'll be posting")
        return pickerItem
    }()

    /// Media Uploading Status Button
    ///
    fileprivate lazy var mediaUploadingBarButtonItem: UIBarButtonItem = {
        let barButton = UIBarButtonItem(customView: self.mediaUploadingButton)
        barButton.accessibilityLabel = NSLocalizedString("Media Uploading", comment: "Message to indicate progress of uploading media to server")
        return barButton
    }()


    /// Publish Button
    fileprivate(set) lazy var publishButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(publishButtonTapped(sender:)), for: .touchUpInside)
        button.setTitle(self.postEditorStateContext.publishButtonText, for: .normal)
        button.sizeToFit()
        button.isEnabled = self.postEditorStateContext.isPublishButtonEnabled
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    /// Publish Button
    fileprivate(set) lazy var publishBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(customView: self.publishButton)

        return button
    }()


    fileprivate lazy var moreButton: UIButton = {
        let image = Gridicon.iconOfType(.ellipsis)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.frame = CGRect(origin: .zero, size: image.size)
        button.accessibilityLabel = NSLocalizedString("More", comment: "Action button to display more available options")
        button.addTarget(self, action: #selector(moreWasPressed), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()


    /// NavigationBar's More Button
    ///
    fileprivate lazy var moreBarButtonItem: UIBarButtonItem = {
        let moreItem = UIBarButtonItem(customView: self.moreButton)
        return moreItem
    }()


    /// Dismiss Button
    ///
    fileprivate lazy var closeButton: WPButtonForNavigationBar = {
        let cancelButton = WPStyleGuide.buttonForBar(with: Assets.closeButtonModalImage, target: self, selector: #selector(closeWasPressed))
        cancelButton.leftSpacing = Constants.cancelButtonPadding.left
        cancelButton.rightSpacing = Constants.cancelButtonPadding.right
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        return cancelButton
    }()


    /// Blog Picker's Button
    ///
    fileprivate lazy var blogPickerButton: WPBlogSelectorButton = {
        let button = WPBlogSelectorButton(frame: .zero, buttonStyle: .typeSingleLine)
        button.addTarget(self, action: #selector(blogPickerWasPressed), for: .touchUpInside)
        if #available(iOS 11, *) {
            button.translatesAutoresizingMaskIntoConstraints = false
        }
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return button
    }()

    /// Media Uploading Button
    ///
    fileprivate lazy var mediaUploadingButton: WPUploadStatusButton = {
        let button = WPUploadStatusButton(frame: CGRect(origin: .zero, size: Constants.uploadingButtonSize))
        button.setTitle(NSLocalizedString("Media Uploading", comment: "Message to indicate progress of uploading media to server"), for: .normal)
        button.addTarget(self, action: #selector(displayCancelMediaUploads), for: .touchUpInside)
        if #available(iOS 11, *) {
            button.translatesAutoresizingMaskIntoConstraints = false
        }
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return button
    }()


    /// Beta Tag Button
    ///
    fileprivate lazy var betaButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        WPStyleGuide.configureBetaButton(button)

        button.setContentHuggingPriority(.required, for: .horizontal)
        button.isEnabled = true
        button.addTarget(self, action: #selector(betaButtonTapped), for: .touchUpInside)

        return button
    }()

    /// Active Editor's Mode
    ///
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

            refreshEditorVisibility()
            refreshPlaceholderVisibility()
            refreshTitlePosition()
        }
    }


    /// Post being currently edited
    ///
    fileprivate(set) var post: AbstractPost {
        didSet {
            removeObservers(fromPost: oldValue)
            addObservers(toPost: post)

            postEditorStateContext = createEditorStateContext(for: post)
            refreshInterface()
        }
    }


    /// Active Downloads
    ///
    fileprivate var activeMediaRequests = [AFImageDownloadReceipt]()


    /// Boolean indicating whether the post should be removed whenever the changes are discarded, or not.
    ///
    fileprivate var shouldRemovePostOnDismiss = false


    /// Media Library Data Source
    ///
    fileprivate lazy var mediaLibraryDataSource: MediaLibraryPickerDataSource = {
        return MediaLibraryPickerDataSource(post: self.post)
    }()

    /// Device Photo Library Data Source
    ///
    fileprivate lazy var devicePhotoLibraryDataSource = WPPHAssetDataSource()

    fileprivate lazy var mediaCoordinator: MediaCoordinator = {
        let coordinator = MediaCoordinator()
        return coordinator
    }()

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


    /// Selected Text Attachment
    ///
    fileprivate var currentSelectedAttachment: MediaAttachment?


    /// Last Interface Element that was a First Responder
    ///
    fileprivate var lastFirstResponder: UIView?


    /// Maintainer of state for editor - like for post button
    ///
    fileprivate lazy var postEditorStateContext: PostEditorStateContext = {
        return self.createEditorStateContext(for: self.post)
    }()

    /// Current keyboard rect used to help size the inline media picker
    ///
    fileprivate var currentKeyboardFrame: CGRect = .zero


    /// Origin of selected media, used for analytics
    ///
    fileprivate var selectedMediaOrigin: WPAppAnalytics.SelectedMediaOrigin = .none


    /// Options
    ///
    fileprivate var optionsViewController: OptionsTableViewController!

    /// Media Picker
    ///
    fileprivate lazy var insertToolbarItem: UIButton = {
        let insertItem = UIButton(type: .custom)
        insertItem.titleLabel?.font = Fonts.mediaPickerInsert
        insertItem.tintColor = WPStyleGuide.wordPressBlue()
        insertItem.setTitleColor(WPStyleGuide.wordPressBlue(), for: .normal)

        return insertItem
    }()

    fileprivate var mediaPickerInputViewController: WPInputMediaPickerViewController?

    fileprivate var originalLeadingBarButtonGroup = [UIBarButtonItemGroup]()

    fileprivate var originalTrailingBarButtonGroup = [UIBarButtonItemGroup]()

    /// Verification Prompt Helper
    ///
    /// - Returns: `nil` when there's no need for showing the verification prompt.
    fileprivate lazy var verificationPromptHelper: AztecVerificationPromptHelper? = {
        return AztecVerificationPromptHelper(account: self.post.blog.account)
    }()

    /// The view to show when media picker has no assets to show.
    ///
    fileprivate let noResultsView = MediaNoResultsView()

    fileprivate var mediaLibraryChangeObserverKey: NSObjectProtocol? = nil


    // MARK: - Initializers

    required init(post: AbstractPost) {
        self.post = post

        super.init(nibName: nil, bundle: nil)

        self.restorationIdentifier = Restoration.restorationIdentifier
        self.restorationClass = type(of: self)
        self.shouldRemovePostOnDismiss = post.shouldRemoveOnDismiss

        addObservers(toPost: post)
    }

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure("Aztec Post View Controller must be initialized by code")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObservers(fromPost: post)

        cancelAllPendingMediaRequests()
    }


    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

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

        // Register HTML Processors for WordPress shortcodes

        // UI elements might get their properties reset when the view is effectively loaded. Refresh it all!
        refreshInterface()

        // Setup Autolayout
        view.setNeedsUpdateConstraints()

        if isOpenedDirectlyForPhotoPost {
            presentMediaPickerFullScreen(animated: false)
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
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopListeningToNotifications()
        rememberFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var safeInsets = self.view.layoutMargins
        safeInsets.top = richTextView.textContainerInset.top
        richTextView.textContainerInset = safeInsets
        htmlTextView.textContainerInset = safeInsets
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.resizeBlogPickerButton()
            self.updateTitleHeight()
        })

        dismissOptionsViewControllerIfNecessary()
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)

        guard let navigationController = parent as? UINavigationController else {
            return
        }

        configureMediaProgressView(in: navigationController.navigationBar)
    }


    // MARK: - Title and Title placeholder position methods

    func refreshTitlePosition() {
        let referenceView: UITextView = mode == .richText ? richTextView : htmlTextView
        titleTopConstraint.constant = -(referenceView.contentOffset.y+referenceView.contentInset.top)

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset

        textPlaceholderTopConstraint.constant = referenceView.textContainerInset.top + referenceView.contentInset.top
    }

    func updateTitleHeight() {
        let referenceView: UITextView = mode == .richText ? richTextView : htmlTextView
        let layoutMargins = view.layoutMargins
        let insets = titleTextField.textContainerInset

        var titleWidth = titleTextField.bounds.width
        if titleWidth <= 0 {
            // Use the title text field's width if available, otherwise calculate it.
            // View's frame minus left and right margins as well as margin between title and beta button
            titleWidth = view.frame.width - (insets.left + insets.right + layoutMargins.left + layoutMargins.right) - betaButton.frame.width
        }

        let sizeThatShouldFitTheContent = titleTextField.sizeThatFits(CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude))
        titleHeightConstraint.constant = max(sizeThatShouldFitTheContent.height, titleTextField.font!.lineHeight + insets.top + insets.bottom)

        textPlaceholderTopConstraint.constant = referenceView.textContainerInset.top + referenceView.contentInset.top

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset
        referenceView.setContentOffset(CGPoint(x: 0, y: -contentInset.top), animated: false)
    }


    // MARK: - Construction Helpers

    /// Returns a new Editor Context for a given Post instance.
    ///
    private func createEditorStateContext(for post: AbstractPost) -> PostEditorStateContext {
        var originalPostStatus: BasePost.Status? = nil

        if let originalPost = post.original, let postStatus = originalPost.status, originalPost.hasRemote() {
            originalPostStatus = postStatus
        }

        // Self-hosted non-Jetpack blogs have no capabilities, so we'll default
        // to showing Publish Now instead of Submit for Review.
        //
        let userCanPublish = post.blog.capabilities != nil ? post.blog.isPublishingPostsAllowed() : true

        return PostEditorStateContext(originalPostStatus: originalPostStatus,
                                      userCanPublish: userCanPublish,
                                      publishDate: post.dateCreated,
                                      delegate: self)
    }


    // MARK: - Configuration Methods

    override func updateViewConstraints() {

        super.updateViewConstraints()

        titleHeightConstraint = titleTextField.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
        titleTopConstraint = titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: -richTextView.contentOffset.y)
        textPlaceholderTopConstraint = placeholderLabel.topAnchor.constraint(equalTo: richTextView.topAnchor, constant: richTextView.textContainerInset.top + richTextView.contentInset.top)
        updateTitleHeight()
        let layoutGuide = view.layoutMarginsGuide

        NSLayoutConstraint.activate([
            titleTextField.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            titleTopConstraint,
            titleHeightConstraint
            ])

        NSLayoutConstraint.activate([
            betaButton.centerYAnchor.constraint(equalTo: titlePlaceholderLabel.centerYAnchor),
            betaButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            titleTextField.trailingAnchor.constraint(equalTo: betaButton.leadingAnchor, constant: -titleTextField.textContainerInset.right)
            ])

        let insets = titleTextField.textContainerInset

        NSLayoutConstraint.activate([
            titlePlaceholderLabel.leftAnchor.constraint(equalTo: titleTextField.leftAnchor, constant: insets.left + titleTextField.textContainer.lineFragmentPadding),
            titlePlaceholderLabel.rightAnchor.constraint(equalTo: titleTextField.rightAnchor, constant: -insets.right - titleTextField.textContainer.lineFragmentPadding),
            titlePlaceholderLabel.topAnchor.constraint(equalTo: titleTextField.topAnchor, constant: insets.top),
            titlePlaceholderLabel.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
            ])

        NSLayoutConstraint.activate([
            separatorView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor),
            separatorView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor),
            separatorView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: separatorView.frame.height)
            ])

        NSLayoutConstraint.activate([
            richTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            richTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
            placeholderLabel.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: Constants.placeholderPadding.left),
            placeholderLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -(Constants.placeholderPadding.right + richTextView.textContainer.lineFragmentPadding)),
            textPlaceholderTopConstraint,
            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: richTextView.bottomAnchor, constant: Constants.placeholderPadding.bottom)
            ])
    }

    private func configureDefaultProperties(for textView: UITextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.keyboardDismissMode = .interactive
        textView.textColor = UIColor.darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
    }

    func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.accessibilityIdentifier = "Azctec Editor Navigation Bar"
        navigationItem.leftBarButtonItems = [separatorButtonItem, closeBarButtonItem, blogPickerBarButtonItem]
        navigationItem.rightBarButtonItems = [moreBarButtonItem, publishBarButtonItem, separatorButtonItem]
    }

    /// This is to restore the navigation bar colors after the UIDocumentPickerViewController has been dismissed,
    /// either by uploading media or cancelling. Doing this in the UIDocumentPickerDelegate methods either did
    /// nothing or the resetting wasn't permanent.
    ///
    fileprivate func resetNavigationColors() {
        WPStyleGuide.configureNavigationBarAppearance()
    }

    func configureDismissButton() {
        let image = isModal() ? Assets.closeButtonModalImage : Assets.closeButtonRegularImage
        closeButton.setImage(image, for: .normal)
    }

    func configureView() {
        edgesForExtendedLayout = UIRectEdge()
        view.backgroundColor = .white
    }

    func configureSubviews() {
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)
        view.addSubview(titleTextField)
        view.addSubview(titlePlaceholderLabel)
        view.addSubview(separatorView)
        view.addSubview(placeholderLabel)
        view.addSubview(betaButton)
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
            HTMLAttachmentRenderer(font: Fonts.regular)
        ]

        for provider in providers {
            richTextView.registerAttachmentImageProvider(provider)
        }
    }

    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidHide), name: .UIKeyboardDidHide, object: nil)
        nc.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: .UIApplicationWillResignActive, object: nil)
    }

    func stopListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        nc.removeObserver(self, name: .UIKeyboardDidHide, object: nil)
        nc.removeObserver(self, name: .UIApplicationWillResignActive, object: nil)
    }

    func rememberFirstResponder() {
        lastFirstResponder = view.findFirstResponder()
        lastFirstResponder?.resignFirstResponder()
    }

    func restoreFirstResponder() {
        let nextFirstResponder = lastFirstResponder ?? titleTextField
        nextFirstResponder.becomeFirstResponder()
    }

    func refreshInterface() {
        reloadBlogPickerButton()
        reloadEditorContents()
        resizeBlogPickerButton()
        reloadPublishButton()
        refreshNavigationBar()
    }

    func refreshNavigationBar() {
        if postEditorStateContext.isUploadingMedia {
            navigationItem.leftBarButtonItems = [separatorButtonItem, closeBarButtonItem, mediaUploadingBarButtonItem]
        } else {
            navigationItem.leftBarButtonItems = [separatorButtonItem, closeBarButtonItem, blogPickerBarButtonItem]
        }
    }

    func setHTML(_ html: String) {
        setHTML(html, for: mode)
    }

    private func setHTML(_ html: String, for mode: EditMode) {
        switch mode {
        case .html:
            htmlTextView.text = html
        case .richText:
            richTextView.setHTML(html)

            processMediaAttachments()
        }
    }

    func getHTML() -> String {

        let html: String

        switch mode {
        case .html:
            html = htmlTextView.text
        case .richText:
            html = richTextView.getHTML()
        }

        return html
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

        let titleText = NSAttributedString(string: pickerTitle, attributes: [.font: Fonts.blogPicker])
        let shouldEnable = !isSingleSiteMode

        blogPickerButton.setAttributedTitle(titleText, for: .normal)
        blogPickerButton.buttonMode = shouldEnable ? .multipleSite : .singleSite
        blogPickerButton.isEnabled = shouldEnable
    }

    func reloadPublishButton() {
        publishButton.setTitle(postEditorStateContext.publishButtonText, for: .normal)
        publishButton.isEnabled = postEditorStateContext.isPublishButtonEnabled
    }

    func resizeBlogPickerButton() {
        // On iOS 11 no resize is needed because the StackView on the navigation bar will do the work
        if #available(iOS 11, *) {
            return
        }
        // On iOS 10 and before we still need to manually resize the button.
        // Ensure the BlogPicker gets it's maximum possible size
        blogPickerButton.sizeToFit()
        // Cap the size, according to the current traits
        var blogPickerSize = hasHorizontallyCompactView() ? Constants.blogPickerCompactSize : Constants.blogPickerRegularSize
        blogPickerSize.width = min(blogPickerSize.width, blogPickerButton.frame.width)
        blogPickerButton.frame.size = blogPickerSize
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
                self?.noResultsView.updateForNoAssets(userCanUploadMedia: false)
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
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
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
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        currentKeyboardFrame = .zero
        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    fileprivate func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        let referenceView: UIScrollView = mode == .richText ? richTextView : htmlTextView

        let scrollInsets = UIEdgeInsets(top: referenceView.scrollIndicatorInsets.top, left: 0, bottom: view.frame.maxY - (keyboardFrame.minY + self.view.layoutMargins.bottom), right: 0)
        let contentInsets  = UIEdgeInsets(top: referenceView.contentInset.top, left: 0, bottom: view.frame.maxY - (keyboardFrame.minY + self.view.layoutMargins.bottom), right: 0)

        htmlTextView.scrollIndicatorInsets = scrollInsets
        htmlTextView.contentInset = contentInsets

        richTextView.scrollIndicatorInsets = scrollInsets
        richTextView.contentInset = contentInsets
    }
}

// MARK: - Format Bar Updating

extension AztecPostViewController {

    func updateFormatBar() {
        switch mode {
        case .html:
            updateFormatBarForHTMLMode()
        case .richText:
            updateFormatBarForVisualMode()
        }
    }

    /// Updates the format bar for HTML mode.
    ///
    private func updateFormatBarForHTMLMode() {
        assert(mode == .html)

        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        toolbar.selectItemsMatchingIdentifiers([FormattingIdentifier.sourcecode.rawValue])
    }

    /// Updates the format bar for visual mode.
    ///
    private func updateFormatBarForVisualMode() {
        assert(mode == .richText)

        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        var identifiers = [FormattingIdentifier]()

        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
        }

        toolbar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
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
        super.present(viewControllerToPresent, animated: flag) {
            if let alert = viewControllerToPresent as? UIAlertController, alert.preferredStyle == .actionSheet {
                alert.popoverPresentationController?.passthroughViews = nil
            }

            completion?()
        }
    }
}


// MARK: - Actions
//
extension AztecPostViewController {
    @IBAction func publishButtonTapped(sender: UIBarButtonItem) {
        trackPostSave(stat: postEditorStateContext.publishActionAnalyticsStat)

        publishTapped(dismissWhenDone: postEditorStateContext.publishActionDismissesEditor)
    }

    @IBAction func secondaryPublishButtonTapped(dismissWhenDone: Bool = true) {
        let publishPostClosure = {
            if self.postEditorStateContext.secondaryPublishButtonAction == .save {
                self.post.status = .draft
            } else if self.postEditorStateContext.secondaryPublishButtonAction == .publish {
                self.post.date_created_gmt = Date()
                self.post.status = .publish
            }

            if let stat = self.postEditorStateContext.secondaryPublishActionAnalyticsStat {
                self.trackPostSave(stat: stat)
            }

            self.publishTapped(dismissWhenDone: dismissWhenDone)
        }

        if presentedViewController != nil {
            dismiss(animated: true, completion: publishPostClosure)
        } else {
            publishPostClosure()
        }
    }

    func showPostHasChangesAlert() {
        let title = NSLocalizedString("You have unsaved changes.", comment: "Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
        let cancelTitle = NSLocalizedString("Keep Editing", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")
        let saveTitle = NSLocalizedString("Save Draft", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")
        let updateTitle = NSLocalizedString("Update Draft", comment: "Button shown if there are unsaved changes and the author is trying to move away from an already published/saved post.")
        let discardTitle = NSLocalizedString("Discard", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")

        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        // Button: Keep editing
        alertController.addCancelActionWithTitle(cancelTitle)

        // Button: Save Draft/Update Draft
        if post.hasLocalChanges() {
            if !post.hasRemote() {
                // The post is a local draft or an autosaved draft: Discard or Save
                alertController.addDefaultActionWithTitle(saveTitle) { _ in
                    self.post.status = .draft
                    self.trackPostSave(stat: self.postEditorStateContext.publishActionAnalyticsStat)
                    self.publishTapped(dismissWhenDone: true)
                }
            } else if post.status == .draft {
                // The post was already a draft
                alertController.addDefaultActionWithTitle(updateTitle) { _ in
                    self.trackPostSave(stat: self.postEditorStateContext.publishActionAnalyticsStat)
                    self.publishTapped(dismissWhenDone: true)
                }
            }
        }

        // Button: Discard
        alertController.addDestructiveActionWithTitle(discardTitle) { _ in
            self.discardChangesAndUpdateGUI()
        }

        alertController.popoverPresentationController?.barButtonItem = closeBarButtonItem
        present(alertController, animated: true, completion: nil)
    }

    private func publishTapped(dismissWhenDone: Bool) {
        // Cancel publishing if media is currently being uploaded
        if mediaCoordinator.isUploading {
            displayMediaIsUploadingAlert()
            return
        }

        // If there is any failed media allow it to be removed or cancel publishing
        if mediaCoordinator.hasFailedMedia {
            displayHasFailedMediaAlert(then: {
                // Failed media is removed, try again.
                // Note: Intentionally not tracking another analytics stat here (no appropriate one exists yet)
                self.publishTapped(dismissWhenDone: dismissWhenDone)
            })
            return
        }

        // If the user is trying to publish to WP.com and they haven't verified their account, prompt them to do so.
        if let verificationHelper = verificationPromptHelper, verificationHelper.neeedsVerification(before: postEditorStateContext.action) {
            verificationHelper.displayVerificationPrompt(from: self) { [weak self] verifiedInBackground in
                // User could've been plausibly silently verified in the background.
                // If so, proceed to publishing the post as normal, otherwise save it as a draft.
                if !verifiedInBackground {
                    self?.post.status = .draft
                }

                self?.publishTapped(dismissWhenDone: dismissWhenDone)
            }
            return
        }

        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: postEditorStateContext.publishVerbText)
        postEditorStateContext.updated(isBeingPublished: true)

        // Finally, publish the post.
        publishPost() { uploadedPost, error in
            self.postEditorStateContext.updated(isBeingPublished: false)
            SVProgressHUD.dismiss()

            let generator = UINotificationFeedbackGenerator()
            generator.prepare()

            if let error = error {
                DDLogError("Error publishing post: \(error.localizedDescription)")

                SVProgressHUD.showDismissibleError(withStatus: self.postEditorStateContext.publishErrorText)
                generator.notificationOccurred(.error)
            } else if let uploadedPost = uploadedPost {
                self.post = uploadedPost

                generator.notificationOccurred(.success)
            }

            if dismissWhenDone {
                self.dismissOrPopView(didSave: true)
            } else {
                self.createRevisionOfPost()
            }
        }
    }

    @IBAction func closeWasPressed() {
        cancelEditing()
    }

    @IBAction func blogPickerWasPressed() {
        assert(isSingleSiteMode == false)
        guard post.hasSiteSpecificChanges() else {
            displayBlogSelector()
            return
        }

        displaySwitchSiteAlert()
    }

    @IBAction func moreWasPressed() {
        displayMoreSheet()
    }

    @IBAction func betaButtonTapped() {
        WPAppAnalytics.track(.editorAztecBetaLink)

        FancyAlertViewController.presentWhatsNewWebView(from: self)
    }

    private func trackPostSave(stat: WPAnalyticsStat) {
        guard stat != .editorSavedDraft && stat != .editorQuickSavedDraft else {
            WPAppAnalytics.track(stat, withProperties: [WPAppAnalyticsKeyEditorSource: Analytics.editorSource], with: post.blog)
            return
        }

        let originalWordCount = post.original?.content?.wordCount() ?? 0
        let wordCount = post.content?.wordCount() ?? 0
        var properties: [String: Any] = ["word_count": wordCount, WPAppAnalyticsKeyEditorSource: Analytics.editorSource]
        if post.hasRemote() {
            properties["word_diff_count"] = originalWordCount
        }

        if stat == .editorPublishedPost {
            properties[WPAnalyticsStatEditorPublishedPostPropertyCategory] = post.hasCategories()
            properties[WPAnalyticsStatEditorPublishedPostPropertyPhoto] = post.hasPhoto()
            properties[WPAnalyticsStatEditorPublishedPostPropertyTag] = post.hasTags()
            properties[WPAnalyticsStatEditorPublishedPostPropertyVideo] = post.hasVideo()
        }

        WPAppAnalytics.track(stat, withProperties: properties, with: post)
    }
}


// MARK: - Private Helpers
//
private extension AztecPostViewController {

    func displayBlogSelector() {
        guard let sourceView = blogPickerButton.imageView else {
            fatalError()
        }

        // Setup Handlers
        let successHandler: BlogSelectorSuccessHandler = { selectedObjectID in
            self.dismiss(animated: true, completion: nil)

            guard let blog = self.mainContext.object(with: selectedObjectID) as? Blog else {
                return
            }
            self.recreatePostRevision(in: blog)
            self.mediaLibraryDataSource = MediaLibraryPickerDataSource(post: self.post)
        }

        let dismissHandler: BlogSelectorDismissHandler = {
            self.dismiss(animated: true, completion: nil)
        }

        // Setup Picker
        let selectorViewController = BlogSelectorViewController(selectedBlogObjectID: post.blog.objectID,
                                                                successHandler: successHandler,
                                                                dismissHandler: dismissHandler)
        selectorViewController.title = NSLocalizedString("Select Site", comment: "Blog Picker's Title")
        selectorViewController.displaysPrimaryBlogOnTop = true

        // Note:
        // On iPad Devices, we'll disable the Picker's SearchController's "Autohide Navbar Feature", since
        // upon dismissal, it may force the NavigationBar to show up, even when it was initially hidden.
        selectorViewController.displaysNavigationBarWhenSearching = WPDeviceIdentification.isiPad()

        // Setup Navigation
        let navigationController = AdaptiveNavigationController(rootViewController: selectorViewController)
        navigationController.configurePopoverPresentationStyle(from: sourceView)

        // Done!
        present(navigationController, animated: true, completion: nil)
    }

    func displayMoreSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if postEditorStateContext.isSecondaryPublishButtonShown,
            let buttonTitle = postEditorStateContext.secondaryPublishButtonText {
            let dismissWhenDone = postEditorStateContext.secondaryPublishButtonAction == .publish
            alert.addActionWithTitle(buttonTitle, style: dismissWhenDone ? .destructive : .default ) { _ in
                self.secondaryPublishButtonTapped(dismissWhenDone: dismissWhenDone)
            }
        }

        alert.addDefaultActionWithTitle(MoreSheetAlert.previewTitle) { _ in
            self.displayPreview()
        }

        alert.addDefaultActionWithTitle(MoreSheetAlert.optionsTitle) { _ in
            self.displayPostOptions()
        }

        alert.addCancelActionWithTitle(MoreSheetAlert.cancelTitle)
        alert.popoverPresentationController?.barButtonItem = moreBarButtonItem

        present(alert, animated: true, completion: nil)
    }

    func displaySwitchSiteAlert() {
        let alert = UIAlertController(title: SwitchSiteAlert.title, message: SwitchSiteAlert.message, preferredStyle: .alert)

        alert.addDefaultActionWithTitle(SwitchSiteAlert.acceptTitle) { _ in
            self.displayBlogSelector()
        }

        alert.addCancelActionWithTitle(SwitchSiteAlert.cancelTitle)

        present(alert, animated: true, completion: nil)
    }

    func displayPostOptions() {
        let settingsViewController: PostSettingsViewController
        if post is Page {
            settingsViewController = PageSettingsViewController(post: post)
        } else {
            settingsViewController = PostSettingsViewController(post: post)
        }
        settingsViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(settingsViewController, animated: true)
    }

    func displayPreview() {
        let previewController = PostPreviewViewController(post: post)
        previewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(previewController, animated: true)
    }

    func displayMediaIsUploadingAlert() {
        let alertController = UIAlertController(title: MediaUploadingAlert.title, message: MediaUploadingAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(MediaUploadingAlert.acceptTitle)
        present(alertController, animated: true, completion: nil)
    }

    func displayHasFailedMediaAlert(then: @escaping () -> ()) {
        let alertController = UIAlertController(title: FailedMediaRemovalAlert.title, message: FailedMediaRemovalAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(MediaUploadingAlert.acceptTitle) { alertAction in
            self.removeFailedMedia()
            then()
        }

        alertController.addCancelActionWithTitle(FailedMediaRemovalAlert.cancelTitle)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func displayCancelMediaUploads() {
        let alertController = UIAlertController(title: MediaUploadingCancelAlert.title, message: MediaUploadingCancelAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(MediaUploadingCancelAlert.acceptTitle) { alertAction in
            self.mediaCoordinator.cancelUploadOfAllMedia()
        }
        alertController.addCancelActionWithTitle(MediaUploadingCancelAlert.cancelTitle)
        present(alertController, animated: true, completion: nil)
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
        case #keyPath(AbstractPost.dateCreated):
            let dateCreated = post.dateCreated ?? Date()
            postEditorStateContext.updated(publishDate: dateCreated)
            editorContentWasUpdated()
        case #keyPath(AbstractPost.content):
            editorContentWasUpdated()
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private var editorHasContent: Bool {
        let titleIsEmpty = post.postTitle?.isEmpty ?? true
        let contentIsEmpty = post.content?.isEmpty ?? true

        return !titleIsEmpty || !contentIsEmpty
    }

    private var editorHasChanges: Bool {
        return post.hasUnsavedChanges()
    }

    internal func editorContentWasUpdated() {
        postEditorStateContext.updated(hasContent: editorHasContent)
        postEditorStateContext.updated(hasChanges: editorHasChanges)
    }

    internal func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {
        reloadPublishButton()
    }

    internal func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {
        reloadPublishButton()
    }

    internal func addObservers(toPost: AbstractPost) {
        toPost.addObserver(self, forKeyPath: AbstractPost.statusKeyPath, options: [], context: nil)
        toPost.addObserver(self, forKeyPath: #keyPath(AbstractPost.dateCreated), options: [], context: nil)
        toPost.addObserver(self, forKeyPath: #keyPath(AbstractPost.content), options: [], context: nil)
    }

    internal func removeObservers(fromPost: AbstractPost) {
        fromPost.removeObserver(self, forKeyPath: AbstractPost.statusKeyPath)
        fromPost.removeObserver(self, forKeyPath: #keyPath(AbstractPost.dateCreated))
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
        mapUIContentToPostAndSave()
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
    enum EditMode {
        case richText
        case html

        mutating func toggle() {
            switch self {
            case .richText:
                self = .html
            case .html:
                self = .richText
            }
        }
    }

    func refreshEditorVisibility() {
        let isRichEnabled = mode == .richText

        htmlTextView.isHidden = isRichEnabled
        richTextView.isHidden = !isRichEnabled
    }

    func refreshPlaceholderVisibility() {
        placeholderLabel.isHidden = richTextView.isHidden || !richTextView.text.isEmpty
        titlePlaceholderLabel.isHidden = !titleTextField.text.isEmpty
    }
}


// MARK: - FormatBarDelegate Conformance
//
extension AztecPostViewController: Aztec.FormatBarDelegate {
    func formatBarTouchesBegan(_ formatBar: FormatBar) {
        dismissOptionsViewControllerIfNecessary()
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
            }

            updateFormatBar()
        }
        else if let mediaIdentifier = FormatBarMediaIdentifier(rawValue: identifier) {
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
                showDocumentPicker()
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
        let listOptions = Constants.lists.map { listType -> OptionsTableViewOption in
            let title = NSAttributedString(string: listType.description, attributes: [:])
            return OptionsTableViewOption(image: listType.iconImage,
                                          title: title,
                                          accessibilityLabel: listType.accessibilityLabel)
        }

        var index: Int? = nil
        if let listType = listTypeForSelectedText() {
            index = Constants.lists.index(of: listType)
        }

        showOptionsTableViewControllerWithOptions(listOptions,
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
        var identifiers = [FormattingIdentifier]()
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
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


    @objc func toggleLink() {
        trackFormatBarAnalytics(stat: .editorTappedLink)

        var linkTitle = ""
        var linkURL: URL? = nil
        var linkRange = richTextView.selectedRange
        // Let's check if the current range already has a link assigned to it.
        if let expandedRange = richTextView.linkFullRange(forRange: richTextView.selectedRange) {
            linkRange = expandedRange
            linkURL = richTextView.linkURL(forRange: expandedRange)
        }

        linkTitle = richTextView.attributedText.attributedSubstring(from: linkRange).string
        showLinkDialog(forURL: linkURL, title: linkTitle, range: linkRange)
    }


    func showLinkDialog(forURL url: URL?, title: String?, range: NSRange) {
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel button")
        let removeTitle = NSLocalizedString("Remove Link", comment: "Label action for removing a link from the editor")
        let insertTitle = NSLocalizedString("Insert Link", comment: "Label action for inserting a link on the editor")
        let updateTitle = NSLocalizedString("Update Link", comment: "Label action for updating a link on the editor")

        let isInsertingNewLink = (url == nil)
        var urlToUse = url

        if isInsertingNewLink {
            if UIPasteboard.general.hasURLs,
                let pastedURL = UIPasteboard.general.url {
                urlToUse = pastedURL
            }
        }

        let insertButtonTitle = isInsertingNewLink ? insertTitle : updateTitle

        let alertController = UIAlertController(title: insertButtonTitle, message: nil, preferredStyle: .alert)

        // TextField: URL
        alertController.addTextField(configurationHandler: { [weak self] textField in
            textField.clearButtonMode = .always
            textField.placeholder = NSLocalizedString("URL", comment: "URL text field placeholder")
            textField.text = urlToUse?.absoluteString

            textField.addTarget(self,
                action: #selector(AztecPostViewController.alertTextFieldDidChange),
                for: UIControlEvents.editingChanged)
            })

        // TextField: Link Name
        alertController.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = .always
            textField.placeholder = NSLocalizedString("Link Name", comment: "Link name field placeholder")
            textField.isSecureTextEntry = false
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .default
            textField.spellCheckingType = .default
            textField.text = title
        })


        // Action: Insert
        let insertAction = alertController.addDefaultActionWithTitle(insertButtonTitle) { [weak self] action in
            self?.richTextView.becomeFirstResponder()
            let linkURLString = alertController.textFields?.first?.text
            var linkTitle = alertController.textFields?.last?.text

            if linkTitle == nil || linkTitle!.isEmpty {
                linkTitle = linkURLString
            }

            guard let urlString = linkURLString, let url = URL(string: urlString), let title = linkTitle else {
                return
            }

            self?.richTextView.setLink(url, title: title, inRange: range)
        }

        // Disabled until url is entered into field
        insertAction.isEnabled = urlToUse?.absoluteString.isEmpty == false

        // Action: Remove
        if !isInsertingNewLink {
            alertController.addDestructiveActionWithTitle(removeTitle) { [weak self] action in
                self?.trackFormatBarAnalytics(stat: .editorTappedUnlink)
                self?.richTextView.becomeFirstResponder()
                self?.richTextView.removeLink(inRange: range)
            }
        }

        // Action: Cancel
        alertController.addCancelActionWithTitle(cancelTitle) { [weak self] _ in
            self?.richTextView.becomeFirstResponder()
        }

        present(alertController, animated: true, completion: nil)
    }

    @objc func alertTextFieldDidChange(_ textField: UITextField) {
        guard
            let alertController = presentedViewController as? UIAlertController,
            let urlFieldText = alertController.textFields?.first?.text,
            let insertAction = alertController.actions.first
            else {
                return
        }

        insertAction.isEnabled = !urlFieldText.isEmpty
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

        mode.toggle()
    }

    func toggleHeader(fromItem item: FormatBarItem) {
        trackFormatBarAnalytics(stat: .editorTappedHeader)

        let headerOptions = Constants.headers.map { headerType -> OptionsTableViewOption in
            let attributes: [NSAttributedStringKey: Any] = [
                .font: UIFont.systemFont(ofSize: CGFloat(headerType.fontSize)),
                .foregroundColor: WPStyleGuide.darkGrey()
            ]

            let title = NSAttributedString(string: headerType.description, attributes: attributes)

            return OptionsTableViewOption(image: headerType.iconImage,
                                          title: title,
                                          accessibilityLabel: headerType.accessibilityLabel)
        }

        let selectedIndex = Constants.headers.index(of: self.headerLevelForSelectedText())

        showOptionsTableViewControllerWithOptions(headerOptions,
                                                  fromBarItem: item,
                                                  selectedRowIndex: selectedIndex,
                                                  onSelect: { [weak self] selected in
                                                    guard let range = self?.richTextView.selectedRange else { return }

                                                    let selectedStyle = Analytics.headerStyleValues[selected]
                                                    self?.trackFormatBarAnalytics(stat: .editorTappedHeaderSelection, headingStyle: selectedStyle)

                                                    self?.richTextView.toggleHeader(Constants.headers[selected], range: range)
                                                    self?.optionsViewController = nil
                                                    self?.changeRichTextInputView(to: nil)
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
        var identifiers = [FormattingIdentifier]()
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
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

    private func showDocumentPicker() {
        let docTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = self
        WPStyleGuide.configureDocumentPickerNavBarAppearance()
        present(docPicker, animated: true, completion: nil)
    }

    // MARK: - Present Toolbar related VC

    fileprivate func dismissOptionsViewControllerIfNecessary() {
        guard optionsViewController != nil else {
            return
        }

        dismissOptionsViewController()
    }

    func showOptionsTableViewControllerWithOptions(_ options: [OptionsTableViewOption],
                                                   fromBarItem barItem: FormatBarItem,
                                                   selectedRowIndex index: Int?,
                                                   onSelect: OptionsTableViewController.OnSelectHandler?) {
        // Hide the input view if we're already showing these options
        if let optionsViewController = optionsViewController ?? (presentedViewController as? OptionsTableViewController), optionsViewController.options == options {
            self.optionsViewController = nil
            changeRichTextInputView(to: nil)
            return
        }

        optionsViewController = OptionsTableViewController(options: options)
        optionsViewController.cellDeselectedTintColor = WPStyleGuide.aztecFormatBarInactiveColor
        optionsViewController.cellBackgroundColor = WPStyleGuide.aztecFormatPickerBackgroundColor
        optionsViewController.cellSelectedBackgroundColor = WPStyleGuide.aztecFormatPickerSelectedCellBackgroundColor
        optionsViewController.view.tintColor = WPStyleGuide.aztecFormatBarActiveColor
        optionsViewController.onSelect = { [weak self] selected in
            onSelect?(selected)
            self?.dismissOptionsViewController()
        }

        let selectRow = {
            guard let index = index else {
                return
            }

            self.optionsViewController?.selectRow(at: index)
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            presentToolbarViewController(optionsViewController, asPopoverFromBarItem: barItem, completion: selectRow)
        } else {
            presentToolbarViewControllerAsInputView(optionsViewController)
            selectRow()
        }
    }

    private func presentToolbarViewController(_ viewController: UIViewController,
                                              asPopoverFromBarItem barItem: FormatBarItem,
                                              completion: (() -> Void)? = nil) {
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.permittedArrowDirections = [.down]
        viewController.popoverPresentationController?.sourceView = view

        let frame = barItem.superview?.convert(barItem.frame, to: UIScreen.main.coordinateSpace)

        optionsViewController.popoverPresentationController?.sourceRect = view.convert(frame!, from: UIScreen.main.coordinateSpace)
        optionsViewController.popoverPresentationController?.backgroundColor = WPStyleGuide.aztecFormatPickerBackgroundColor
        optionsViewController.popoverPresentationController?.delegate = self

        present(viewController, animated: true, completion: completion)
    }

    private func presentToolbarViewControllerAsInputView(_ viewController: UIViewController) {
        self.addChildViewController(viewController)
        changeRichTextInputView(to: viewController.view)
        viewController.didMove(toParentViewController: self)
    }

    private func dismissOptionsViewController() {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            dismiss(animated: true, completion: nil)
        default:
            optionsViewController?.removeFromParentViewController()
            changeRichTextInputView(to: nil)
        }

        optionsViewController = nil
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

        toolbar.tintColor = WPStyleGuide.aztecFormatBarInactiveColor
        toolbar.highlightedTintColor = WPStyleGuide.aztecFormatBarActiveColor
        toolbar.selectedTintColor = WPStyleGuide.aztecFormatBarActiveColor
        toolbar.disabledTintColor = WPStyleGuide.aztecFormatBarDisabledColor
        toolbar.dividerTintColor = WPStyleGuide.aztecFormatBarDividerColor
        toolbar.overflowToggleIcon = Gridicon.iconOfType(.ellipsis)

        toolbar.leadingItem = makeToolbarButton(identifier: .media)
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

        if #available(iOS 11, *) {
            toolbarButtons.append(makeToolbarButton(identifier: .otherApplications))
        }

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
        if optionsViewController != nil {
            optionsViewController = nil
        }
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
            self?.dismiss(animated: true, completion: nil)
        }

        targetVC.onDidCancel = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
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

        present(viewController, animated: true, completion: nil)
    }
}


// MARK: - Cancel/Dismiss/Persistence Logic
//
private extension AztecPostViewController {

    // TODO: Rip this out and put it into the PostService
    func createRevisionOfPost() {
        guard let context = post.managedObjectContext else {
            return
        }

        // Using performBlock: with the AbstractPost on the main context:
        // Prevents a hang on opening this view on slow and fast devices
        // by deferring the cloning and UI update.
        // Slower devices have the effect of the content appearing after
        // a short delay

        context.performAndWait {
            self.post = self.post.createRevision()
            ContextManager.sharedInstance().save(context)
        }
    }

    // TODO: Rip this and put it into PostService, as well
    func recreatePostRevision(in blog: Blog) {
        let shouldCreatePage = post is Page
        let postService = PostService(managedObjectContext: mainContext)
        let newPost = shouldCreatePage ? postService.createDraftPage(for: blog) : postService.createDraftPost(for: blog)

        newPost.content = contentByStrippingMediaAttachments()
        newPost.postTitle = post.postTitle
        newPost.password = post.password
        newPost.status = post.status
        newPost.dateCreated = post.dateCreated
        newPost.dateModified = post.dateModified

        if let source = post as? Post, let target = newPost as? Post {
            target.tags = source.tags
        }

        discardChanges()
        post = newPost
        createRevisionOfPost()
        RecentSitesService().touch(blog: blog)

        // TODO: Add this snippet, if needed, once we've relocated this helper to PostService
        //[self syncOptionsIfNecessaryForBlog:blog afterBlogChanged:YES];
    }

    func cancelEditing() {
        stopEditing()

        if post.canSave() && post.hasUnsavedChanges() {
            showPostHasChangesAlert()
        } else {
            discardChangesAndUpdateGUI()
        }
    }

    func stopEditing() {
        view.endEditing(true)
    }

    func discardChanges() {
        guard let context = post.managedObjectContext, let originalPost = post.original else {
            return
        }

        WPAppAnalytics.track(.editorDiscardedChanges, withProperties: [WPAppAnalyticsKeyEditorSource: Analytics.editorSource], with: post)

        post = originalPost
        post.deleteRevision()

        if shouldRemovePostOnDismiss {
            post.remove()
        }

        mediaCoordinator.cancelUploadOfAllMedia()
        ContextManager.sharedInstance().save(context)
    }

    func discardChangesAndUpdateGUI() {
        discardChanges()

        dismissOrPopView(didSave: false)
    }

    func dismissOrPopView(didSave: Bool) {
        stopEditing()

        WPAppAnalytics.track(.editorClosed, withProperties: [WPAppAnalyticsKeyEditorSource: Analytics.editorSource], with: post)

        if let onClose = onClose {
            onClose(didSave)
        } else if isModal() {
            presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }

    func contentByStrippingMediaAttachments() -> String {
        if mode == .html {
            setHTML(htmlTextView.text)
        }

        richTextView.removeMediaAttachments()
        let strippedHTML = getHTML()

        if mode == .html {
            setHTML(strippedHTML)
        }

        return strippedHTML
    }

    func mapUIContentToPostAndSave() {
        post.postTitle = titleTextField.text
        post.content = getHTML()

        ContextManager.sharedInstance().save(post.managedObjectContext!)
    }

    func publishPost(completion: ((_ post: AbstractPost?, _ error: Error?) -> Void)? = nil) {
        mapUIContentToPostAndSave()

        let managedObjectContext = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: managedObjectContext)
        postService.uploadPost(post, success: { uploadedPost in
            completion?(uploadedPost, nil)
        }) { error in
            completion?(nil, error)
        }
    }
}


// MARK: - Computed Properties
//
private extension AztecPostViewController {
    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var currentBlogCount: Int {
        let service = BlogService(managedObjectContext: mainContext)
        return service.blogCountForAllAccounts()
    }

    var isSingleSiteMode: Bool {
        return currentBlogCount <= 1 || post.hasRemote()
    }

    /// Height to use for the inline media picker based on iOS version and screen orientation.
    ///
    var mediaKeyboardHeight: CGFloat {
        var keyboardHeight: CGFloat

        // Let's assume a sensible default for the keyboard height based on orientation
        let keyboardFrameRatioDefault = UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) ? Constants.mediaPickerKeyboardHeightRatioPortrait : Constants.mediaPickerKeyboardHeightRatioLandscape
        let keyboardHeightDefault = (keyboardFrameRatioDefault * UIScreen.main.bounds.height)

        if #available(iOS 11, *) {
            // On iOS 11, we need to make an assumption the hardware keyboard is attached based on
            // the height of the current keyboard frame being less than our sensible default. If it is
            // "attached", let's just use our default.
            if currentKeyboardFrame.height < keyboardHeightDefault {
                keyboardHeight = keyboardHeightDefault
            } else {
                keyboardHeight = (currentKeyboardFrame.height - Constants.toolbarHeight)
            }
        } else {
            // On iOS 10, when the soft keyboard is visible, the keyboard's frame is within the dimensions of the screen.
            // However, when an external keyboard is present, the keyboard's frame is located offscreen. Test to see if
            // that is true and adjust the keyboard height as necessary.
            if (currentKeyboardFrame.origin.y + currentKeyboardFrame.height) > view.frame.height {
                keyboardHeight = (currentKeyboardFrame.maxY - view.frame.height)
            } else {
                keyboardHeight = (currentKeyboardFrame.height - Constants.toolbarHeight)
            }
        }

        // Sanity check
        keyboardHeight = max(keyboardHeight, keyboardHeightDefault)

        return keyboardHeight
    }
}

// MARK: - Media Support
//
extension AztecPostViewController {

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
        mediaProgressView.isHidden = !mediaCoordinator.isUploading
        mediaProgressView.progress = Float(mediaCoordinator.totalProgress)
        postEditorStateContext.update(isUploadingMedia: mediaCoordinator.isUploading)
        refreshNavigationBar()
    }

    enum MediaSource {
        case localLibrary
        case otherApps
        case wpMediaLibrary

        func statType(for exportableAsset: ExportableAsset) -> WPAnalyticsStat? {
            switch self {
            case .localLibrary:
                switch exportableAsset.assetMediaType {
                case .image:
                    return .editorAddedPhotoViaLocalLibrary
                case .video:
                    return .editorAddedVideoViaLocalLibrary
                default:
                    return nil
                }
            case .otherApps:
                switch exportableAsset.assetMediaType {
                case .image:
                    return .editorAddedPhotoViaOtherApps
                case .video:
                    return .editorAddedVideoViaOtherApps
                default:
                    return nil
                }
            case .wpMediaLibrary:
                switch exportableAsset.assetMediaType {
                case .image:
                    return .editorAddedPhotoViaWPMediaLibrary
                case .video:
                    return .editorAddedVideoViaWPMediaLibrary
                default:
                    return nil
                }
            }
        }
    }

    fileprivate func observe(media: Media, statType: WPAnalyticsStat?) {
        let _ = mediaCoordinator.addObserver({ [weak self](media, state) in
            guard let strongSelf = self,
                let attachment = strongSelf.findAttachment(withUploadID: media.uploadID) else {
                    return
            }
            switch state {
            case .processing:
                DDLogInfo("Creating media")
            case .thumbnailReady(let url):
                strongSelf.handleThumbnailURL(url, attachment: attachment)
            case .uploading:
                if let statType = statType {
                    WPAppAnalytics.track(statType, withProperties: WPAppAnalytics.properties(for: media, mediaOrigin: strongSelf.selectedMediaOrigin), with: strongSelf.post.blog)
                }
            case .ended:
                strongSelf.handleUploaded(media: media, mediaUploadID: media.uploadID)
            case .failed(let error):
                strongSelf.handleError(error as NSError, onAttachment: attachment)
            case .progress(let value):
                if value >= 1 {
                    attachment.progress = nil
                } else {
                    attachment.progress = value
                }
                strongSelf.richTextView.refresh(attachment)
            }
            strongSelf.refreshGlobalProgress()
            }, for: media)
    }

    fileprivate func insert(exportableAsset: ExportableAsset, source: MediaSource) {
        let attachment: MediaAttachment
        switch exportableAsset.assetMediaType {
        case .image:
            attachment = insertImageAttachment()
        case .video:
            attachment = insertVideoAttachmentWithPlaceholder()
        default:
            return
        }

        let media = mediaCoordinator.addMedia(from: exportableAsset, to: self.post)
        attachment.uploadID = media.uploadID
        observe(media: media, statType: source.statType(for: exportableAsset))
    }

    fileprivate func insertExternalMediaWithURL(_ url: URL) {
        insert(exportableAsset: url as NSURL, source: .otherApps)
    }

    fileprivate func insertDeviceMedia(phAsset: PHAsset) {
        insert(exportableAsset: phAsset, source: .localLibrary)
    }

    fileprivate func insertSiteMediaLibrary(media: Media) {
        if media.hasRemote {
            insertRemoteSiteMediaLibrary(media: media)
        } else {
            insertLocalSiteMediaLibrary(media: media)
        }
    }

    private func insertImageAttachment(with url: URL = Constants.placeholderMediaLink) -> ImageAttachment {
        let attachment = richTextView.replaceWithImage(at: self.richTextView.selectedRange, sourceURL: url, placeHolderImage: Assets.defaultMissingImage)
        attachment.size = .full
        return attachment
    }

    private func insertVideoAttachmentWithPlaceholder() -> VideoAttachment {
        return richTextView.replaceWithVideo(at: richTextView.selectedRange, sourceURL: Constants.placeholderMediaLink, posterURL: Constants.placeholderMediaLink, placeHolderImage: Assets.defaultMissingImage)
    }

    private func handleThumbnailURL(_ thumbnailURL: URL, attachment: MediaAttachment) {
        DispatchQueue.main.async {
            if let attachment = attachment as? ImageAttachment {
                attachment.updateURL(thumbnailURL)
                self.richTextView.refresh(attachment)
            }
            else if let attachment = attachment as? VideoAttachment {
                attachment.posterURL = thumbnailURL
                self.richTextView.refresh(attachment)
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
            WPAppAnalytics.track(.editorAddedPhotoViaWPMediaLibrary, withProperties: WPAppAnalytics.properties(for: media, mediaOrigin: selectedMediaOrigin), with: post)
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
            WPAppAnalytics.track(.editorAddedVideoViaWPMediaLibrary, withProperties: WPAppAnalytics.properties(for: media, mediaOrigin: selectedMediaOrigin), with: post)
        default:
            // If we drop in here, let's just insert a link the the remote media
            let linkTitle = media.title?.nonEmptyString() ?? remoteURLStr
            richTextView.setLink(remoteURL, title: linkTitle, inRange: richTextView.selectedRange)
            WPAppAnalytics.track(.editorAddedOtherMediaViaWPMediaLibrary, withProperties: WPAppAnalytics.properties(for: media, mediaOrigin: selectedMediaOrigin), with: post)
        }
    }

    fileprivate func insertLocalSiteMediaLibrary(media: Media) {

        var tempMediaURL = Constants.placeholderMediaLink
        if let absoluteURL = media.absoluteLocalURL {
            tempMediaURL = absoluteURL
        }
        var attachment: MediaAttachment?
        var statType: WPAnalyticsStat?
        if media.mediaType == .image {
            attachment = insertImageAttachment(with: tempMediaURL)
            statType = .editorAddedPhotoViaWPMediaLibrary
        } else if media.mediaType == .video,
            let remoteURLStr = media.remoteURL,
            let remoteURL = URL(string: remoteURLStr) {
            attachment = richTextView.replaceWithVideo(at: richTextView.selectedRange, sourceURL: remoteURL, posterURL: media.absoluteThumbnailLocalURL, placeHolderImage: Assets.defaultMissingImage)
            statType = .editorAddedVideoViaWPMediaLibrary
        }
        if let attachment = attachment {
            attachment.uploadID = media.uploadID
            mediaCoordinator.addMedia(media)
            observe(media: media, statType: statType)
        }
    }

    fileprivate func saveToMedia(attachment: MediaAttachment) {
        guard let image = attachment.image else {
            return
        }
        insert(exportableAsset: image, source: .localLibrary)
    }

    private func handleUploaded(media: Media, mediaUploadID: String) {
        guard let remoteURLStr = media.remoteURL,
              let remoteURL = URL(string: remoteURLStr)
        else {
            return
        }

        switch self.mode {
        case .richText:
            guard let attachment = self.findAttachment(withUploadID: mediaUploadID) else {
                return
            }
            attachment.uploadID = nil
            if let imageAttachment = attachment as? ImageAttachment {
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
            } else if let videoAttachment = attachment as? VideoAttachment, let videoURLString = media.remoteURL {
                videoAttachment.srcURL = URL(string: videoURLString)
                if let videoPosterURLString = media.remoteThumbnailURL {
                    videoAttachment.posterURL = URL(string: videoPosterURLString)
                }
                if let videoPressGUID = media.videopressGUID, !videoPressGUID.isEmpty {
                    videoAttachment.videoPressID = videoPressGUID
                }
            }
            richTextView.refresh(attachment)
        case .html:
            if media.mediaType == .image {
                let imgPostUploadProcessor = ImgUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, width: media.width?.intValue, height: media.height?.intValue)
                htmlTextView.text = imgPostUploadProcessor.process(htmlTextView.text)
            } else if media.mediaType == .video {
                let videoPostUploadProcessor = VideoUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, videoPressID: media.videopressGUID)
                htmlTextView.text = videoPostUploadProcessor.process(htmlTextView.text)
            }
        }
    }

    private func handleError(_ error: NSError?, onAttachment attachment: Aztec.MediaAttachment) {
        if let error = error {
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                self.richTextView.remove(attachmentID: attachment.identifier)
                return
            }
        }
        WPAppAnalytics.track(.editorUploadMediaFailed, withProperties: [WPAppAnalyticsKeyEditorSource: Analytics.editorSource], with: self.post.blog)

        let message = NSLocalizedString("Failed to insert media.\n Please tap for options.", comment: "Error message to show to use when media insertion on a post fails")

        let attributeMessage = NSAttributedString(string: message, attributes: mediaMessageAttributes)
        attachment.message = attributeMessage
        attachment.overlayImage = Gridicon.iconOfType(.refresh, withSize: Constants.mediaOverlayIconSize)
        attachment.shouldHideBorder = true
        richTextView.refresh(attachment)
    }

    fileprivate func removeFailedMedia() {
        let failedMediaIDs = mediaCoordinator.failedMediaIDs
        for mediaID in failedMediaIDs {
            if let attachment = self.findAttachment(withUploadID: mediaID) {
                richTextView.remove(attachmentID: attachment.identifier)
            }
            if let media = mediaCoordinator.media(withIdentifier: mediaID) {
                mediaCoordinator.cancelUploadAndDeleteMedia(media)
            }
        }
    }

    fileprivate func processMediaAttachments() {
        processMediaWithErrorAttachments()
        processVideoPressAttachments()
    }

    fileprivate func processMediaWithErrorAttachments() {
        richTextView.textStorage.enumerateAttachments { (attachment, range) in
            guard let mediaAttachment = attachment as? MediaAttachment, let mediaUploadID = mediaAttachment.uploadID, let media = self.mediaCoordinator.media(withIdentifier: mediaUploadID) else {
                return
            }
            if let error = self.mediaCoordinator.error(for: media) {
                self.handleError(error, onAttachment: mediaAttachment)
            }
        }
    }

    fileprivate func processVideoPressAttachments() {
        richTextView.textStorage.enumerateAttachments { (attachment, range) in
            guard let videoAttachment = attachment as? VideoAttachment else {
                return
            }
            // Use a placeholder for video while trying to generate a thumbnail
            DispatchQueue.main.async {
                videoAttachment.image = Gridicon.iconOfType(.video, withSize: Constants.mediaPlaceholderImageSize)
                self.richTextView.refresh(videoAttachment)
            }
            if let videoSrcURL = videoAttachment.srcURL,
               videoSrcURL.scheme == VideoShortcodeProcessor.videoPressScheme,
               let videoPressID = videoSrcURL.host {
                // It's videoPress video so let's fetch the information for the video
                let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                mediaService.getMediaURL(fromVideoPressID: videoPressID, in: self.post.blog, success: { (videoURLString, posterURLString) in
                    videoAttachment.srcURL = URL(string: videoURLString)
                    if let validPosterURLString = posterURLString, let posterURL = URL(string: validPosterURLString) {
                        videoAttachment.posterURL = posterURL
                    }
                    self.richTextView.refresh(videoAttachment)
                }, failure: { (error) in
                    DDLogError("Unable to find information for VideoPress video with ID = \(videoPressID). Details: \(error.localizedDescription)")
                })
            } else if let videoSrcURL = videoAttachment.srcURL, videoAttachment.posterURL == nil {
                let asset = AVURLAsset(url: videoSrcURL as URL, options: nil)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                imgGenerator.maximumSize = .zero
                imgGenerator.appliesPreferredTrackTransform = true
                let timeToCapture = NSValue(time: CMTimeMake(0, 1))
                imgGenerator.generateCGImagesAsynchronously(forTimes: [timeToCapture],
                                                            completionHandler: { (time, cgImage, actualTime, result, error) in
                    guard let cgImage = cgImage else {
                        return
                    }
                    let uiImage = UIImage(cgImage: cgImage)
                    let url = self.URLForTemporaryFileWithFileExtension(".jpg")
                    do {
                        try uiImage.writeJPEGToURL(url)
                        DispatchQueue.main.async {
                            videoAttachment.posterURL = url
                            self.richTextView.refresh(videoAttachment)
                        }
                    } catch {
                        DDLogError("Unable to grab frame from video = \(videoSrcURL). Details: \(error.localizedDescription)")
                    }
                })
            }
        }
    }

    private func URLForTemporaryFileWithFileExtension(_ fileExtension: String) -> URL {
        assert(!fileExtension.isEmpty, "file Extension cannot be empty")
        let fileName = "\(ProcessInfo.processInfo.globallyUniqueString)_file.\(fileExtension)"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        return fileURL
    }

    // TODO: Extract these strings into structs like other items
    fileprivate func displayActions(forAttachment attachment: MediaAttachment, position: CGPoint) {
        let attachmentID = attachment.identifier
        let title: String = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
        var message: String?
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alertController.addActionWithTitle(NSLocalizedString("Dismiss", comment: "User action to dismiss media options."),
                                           style: .cancel,
                                           handler: { (action) in
                                            if attachment == self.currentSelectedAttachment {
                                                self.currentSelectedAttachment = nil
                                                self.resetMediaAttachmentOverlay(attachment)
                                                self.richTextView.refresh(attachment)
                                            }
        })
        var showDefaultActions = true
        if let mediaUploadID = attachment.uploadID, let media = mediaCoordinator.media(withIdentifier: mediaUploadID) {
            // Is upload still going?
            if media.remoteStatus == .pushing || media.remoteStatus == .processing {
                showDefaultActions = false
                alertController.addActionWithTitle(NSLocalizedString("Stop Upload", comment: "User action to stop upload."),
                                                   style: .destructive,
                                                   handler: { (action) in
                                                    self.mediaCoordinator.cancelUpload(of: media)
                })
            } else {
                if let error = mediaCoordinator.error(for: media) {
                    message = error.localizedDescription
                    alertController.addActionWithTitle(NSLocalizedString("Retry Upload", comment: "User action to retry media upload."),
                                                       style: .default,
                                                       handler: { (action) in
                                                        //retry upload
                                                        if let attachment = self.richTextView.attachment(withId: attachmentID) {
                                                            self.resetMediaAttachmentOverlay(attachment)
                                                            attachment.progress = 0
                                                            self.richTextView.refresh(attachment)

                                                            WPAppAnalytics.track(.editorUploadMediaRetried, withProperties: [WPAppAnalyticsKeyEditorSource: Analytics.editorSource], with: self.post.blog)

                                                            self.mediaCoordinator.retryMedia(media)
                                                        }
                    })
                }
            }
        }

        if showDefaultActions {
            if let imageAttachment = attachment as? ImageAttachment {
                alertController.preferredAction = alertController.addActionWithTitle(NSLocalizedString("Edit", comment: "User action to edit media details."),
                                                                                     style: .default,
                                                                                     handler: { (action) in
                                                                                        self.displayDetails(forAttachment: imageAttachment)
                })
            } else if let videoAttachment = attachment as? VideoAttachment {
                alertController.preferredAction = alertController.addActionWithTitle(NSLocalizedString("Play Video", comment: "User action to play a video on the editor."),
                                                                                     style: .default,
                                                                                     handler: { (action) in
                                                                                        self.displayPlayerFor(videoAttachment: videoAttachment, atPosition: position)
                })
            }
            alertController.addActionWithTitle(NSLocalizedString("Remove", comment: "User action to remove media."),
                                               style: .destructive,
                                               handler: { (action) in
                                                self.richTextView.remove(attachmentID: attachmentID)
            })
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
        let controller = AztecAttachmentViewController()
        controller.attachment = attachment
        var oldURL: URL?

        if let linkRange = richTextView.linkFullRange(forRange: attachmentRange),
            let url = richTextView.linkURL(forRange: attachmentRange),
            NSIntersectionRange(attachmentRange, linkRange) == attachmentRange {
            oldURL = url
            controller.linkURL = url
        }

        controller.onUpdate = { [weak self] (alignment, size, linkURL, alt) in
            self?.richTextView.edit(attachment) { updated in
                updated.alignment = alignment
                updated.size = size
                updated.alt = alt
            }
            // Update associated link
            if let updatedURL = linkURL {
                self?.richTextView.setLink(updatedURL, inRange: attachmentRange)
            } else if oldURL != nil && linkURL == nil {
                self?.richTextView.removeLink(inRange: attachmentRange)
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
        present(navController, animated: true, completion: nil)

        WPAppAnalytics.track(.editorEditedImage, withProperties: [WPAppAnalyticsKeyEditorSource: Analytics.editorSource], with: post)
    }

    var mediaMessageAttributes: [NSAttributedStringKey: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        return [.font: Fonts.mediaOverlay,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white]
    }

    func placeholderImage(for attachment: NSTextAttachment) -> UIImage {
        let icon: UIImage
        switch attachment {
        case _ as ImageAttachment:
            icon = Gridicon.iconOfType(.image, withSize: Constants.mediaPlaceholderImageSize)
        case _ as VideoAttachment:
            icon = Gridicon.iconOfType(.video, withSize: Constants.mediaPlaceholderImageSize)
        default:
            icon = Gridicon.iconOfType(.attachment, withSize: Constants.mediaPlaceholderImageSize)
        }

        icon.addAccessibilityForAttachment(attachment)
        return icon
    }

    // [2017-08-30] We need to auto-close the input media picker when multitasking panes are resized - iOS
    // is dropping the input picker's view from the view hierarchy. Not an ideal solution, but prevents
    // the user from seeing an empty grey rect as a keyboard. Issue affects the 7.9", 9.7", and 10.5"
    // iPads only...not the 12.9"
    // See http://www.openradar.me/radar?id=4972612522344448 for more details.
    //
    @objc func applicationWillResignActive(_ notification: Foundation.Notification) {
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
        if mediaAttachment is ImageAttachment {
            mediaAttachment.overlayImage = nil
        }
        mediaAttachment.message = nil
        mediaAttachment.shouldHideBorder = false
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
        if let uploadID = attachment.uploadID, let media = mediaCoordinator.media(withIdentifier: uploadID), mediaCoordinator.error(for: media) != nil {
            errorAssociatedToAttachment = true
        }
        if !errorAssociatedToAttachment {
            // If it's a new attachment tapped let's unmark the previous one...
            if let selectedAttachment = currentSelectedAttachment {
                self.resetMediaAttachmentOverlay(selectedAttachment)
                richTextView.refresh(selectedAttachment)
            }

            // ...and mark the newly tapped attachment
            let message = ""
            attachment.message = NSAttributedString(string: message, attributes: mediaMessageAttributes)
            richTextView.refresh(attachment)
            currentSelectedAttachment = attachment
        }

        // Display the action sheet right away
        displayActions(forAttachment: attachment, position: position)
    }

    func displayPlayerFor(videoAttachment: VideoAttachment, atPosition position: CGPoint) {
        guard let videoURL = videoAttachment.srcURL else {
            return
        }
        if let videoPressID = videoAttachment.videoPressID {
            // It's videoPress video so let's fetch the information for the video
            let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            mediaService.getMediaURL(fromVideoPressID: videoPressID, in: self.post.blog, success: { (videoURLString, posterURLString) in
                guard let videoURL = URL(string: videoURLString) else {
                    return
                }
                videoAttachment.srcURL = videoURL
                if let validPosterURLString = posterURLString, let posterURL = URL(string: validPosterURLString) {
                    videoAttachment.posterURL = posterURL
                }
                self.richTextView.refresh(videoAttachment)
                self.displayVideoPlayer(for: videoURL)
            }, failure: { (error) in
                DDLogError("Unable to find information for VideoPress video with ID = \(videoPressID). Details: \(error.localizedDescription)")
            })
        } else {
            displayVideoPlayer(for: videoURL)
        }
    }

    func displayVideoPlayer(for videoURL: URL) {
        let asset = AVURLAsset(url: videoURL)
        let controller = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        controller.showsPlaybackControls = true
        controller.player = player
        player.play()
        present(controller, animated: true, completion: nil)
    }

    public func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        deselected(textAttachment: attachment, atPosition: position)
    }

    func deselected(textAttachment attachment: NSTextAttachment, atPosition position: CGPoint) {
        currentSelectedAttachment = nil
        if let mediaAttachment = attachment as? MediaAttachment {
            self.resetMediaAttachmentOverlay(mediaAttachment)
            richTextView.refresh(mediaAttachment)
        }
    }

    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        var requestURL = url
        let imageMaxDimension = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
        //use height zero to maintain the aspect ratio when fetching
        var size = CGSize(width: imageMaxDimension, height: 0)
        let request: URLRequest
        if url.isFileURL {
            request = URLRequest(url: url)
        } else if self.post.blog.isPrivate() {
            // private wpcom image needs special handling.
            // the size that WPImageHelper expects is pixel size
            size.width = size.width * UIScreen.main.scale
            requestURL = WPImageURLHelper.imageURLWithSize(size, forImageURL: requestURL)
            request = PrivateSiteURLProtocol.requestForPrivateSite(from: requestURL)
        } else if !self.post.blog.isHostedAtWPcom && self.post.blog.isBasicAuthCredentialStored() {
            size.width = size.width * UIScreen.main.scale
            requestURL = WPImageURLHelper.imageURLWithSize(size, forImageURL: requestURL)
            request = URLRequest(url: requestURL)
        } else {
            // the size that PhotonImageURLHelper expects is points size
            requestURL = PhotonImageURLHelper.photonURL(with: size, forImageURL: requestURL)
            request = URLRequest(url: requestURL)
        }

        let imageDownloader = AFImageDownloader.defaultInstance()
        let receipt = imageDownloader.downloadImage(for: request, success: { [weak self](request, response, image) in
            guard self != nil else {
                return
            }
            DispatchQueue.main.async(execute: {
                success(image)
            })
        }) { [weak self](request, response, error) in
            guard self != nil else {
                return
            }
            DispatchQueue.main.async(execute: {
                failure()
            })
        }

        if let receipt = receipt {
            activeMediaRequests.append(receipt)
        }
    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        saveToMedia(attachment: imageAttachment)
        return nil
    }

    func cancelAllPendingMediaRequests() {
        let imageDownloader = AFImageDownloader.defaultInstance()
        for receipt in activeMediaRequests {
            imageDownloader.cancelTask(for: receipt)
        }
        activeMediaRequests.removeAll()
    }

    func textView(_ textView: TextView, deletedAttachmentWith attachmentID: String) {

    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return placeholderImage(for: attachment)
    }
}


// MARK: - MediaPickerViewController Delegate Conformance
//
extension AztecPostViewController: WPMediaPickerViewControllerDelegate {

    func emptyView(forMediaPickerController picker: WPMediaPickerViewController) -> UIView? {
        if picker != mediaPickerInputViewController?.mediaPicker {
            return noResultsView
        }
        return nil
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didUpdateSearchWithAssetCount assetCount: Int) {
        if let searchQuery = mediaLibraryDataSource.searchQuery {
            noResultsView.updateForNoSearchResult(with: searchQuery)
        }
    }

    func mediaPickerControllerWillBeginLoadingData(_ picker: WPMediaPickerViewController) {
        updateSearchBar(mediaPicker: picker)
        noResultsView.updateForFetching()
    }

    func mediaPickerControllerDidEndLoadingData(_ picker: WPMediaPickerViewController) {
        updateSearchBar(mediaPicker: picker)
        noResultsView.updateForNoAssets(userCanUploadMedia: false)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        if picker != mediaPickerInputViewController?.mediaPicker {
            unregisterChangeObserver()
            mediaLibraryDataSource.searchCancelled()
            dismiss(animated: true, completion: nil)
        }
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        if picker != mediaPickerInputViewController?.mediaPicker {
            unregisterChangeObserver()
            mediaLibraryDataSource.searchCancelled()
            dismiss(animated: true, completion: nil)
            selectedMediaOrigin = .fullScreenPicker
        } else {
            selectedMediaOrigin = .inlinePicker
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

    private func updateFormatBarInsertAssetCount() {
        guard let assetCount = mediaPickerInputViewController?.mediaPicker.selectedAssets.count else {
            return
        }

        if assetCount == 0 {
            formatBar.trailingItem = nil
        } else {
            insertToolbarItem.setTitle(String(format: Constants.mediaPickerInsertText, NSNumber(value: assetCount)), for: .normal)

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


// MARK: - State Restoration
//
extension AztecPostViewController: UIViewControllerRestoration {
    class func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        return restoreAztec(withCoder: coder)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(post.objectID.uriRepresentation(), forKey: Restoration.postIdentifierKey)
        coder.encode(shouldRemovePostOnDismiss, forKey: Restoration.shouldRemovePostKey)
    }

    class func restoreAztec(withCoder coder: NSCoder) -> AztecPostViewController? {
        let context = ContextManager.sharedInstance().mainContext
        guard let postURI = coder.decodeObject(forKey: Restoration.postIdentifierKey) as? URL,
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: postURI) else {
                return nil
        }

        let post = try? context.existingObject(with: objectID)
        guard let restoredPost = post as? AbstractPost else {
            return nil
        }

        let aztecViewController = AztecPostViewController(post: restoredPost)
        aztecViewController.shouldRemovePostOnDismiss = coder.decodeBool(forKey: Restoration.shouldRemovePostKey)

        return aztecViewController
    }
}

// MARK: - UIDocumentPickerDelegate

extension AztecPostViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        selectedMediaOrigin = .documentPicker
        for documentURL in urls {
            insertExternalMediaWithURL(documentURL)
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
    }

    struct Constants {
        static let defaultMargin            = CGFloat(20)
        static let cancelButtonPadding      = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        static let blogPickerCompactSize    = CGSize(width: 125, height: 30)
        static let blogPickerRegularSize    = CGSize(width: 300, height: 30)
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
        static let mediaPlaceholderImageSize = CGSize(width: 128, height: 128)
        static let placeholderMediaLink = URL(string: "placeholder://")!

        struct Animations {
            static let formatBarMediaButtonRotationDuration: TimeInterval = 0.3
            static let formatBarMediaButtonRotationAngle: CGFloat = .pi / 4.0
        }
    }

    struct MoreSheetAlert {
        static let htmlTitle                = NSLocalizedString("Switch to HTML", comment: "Switches the Editor to HTML Mode")
        static let richTitle                = NSLocalizedString("Switch to Rich Text", comment: "Switches the Editor to Rich Text Mode")
        static let previewTitle             = NSLocalizedString("Preview", comment: "Displays the Post Preview Interface")
        static let optionsTitle             = NSLocalizedString("Options", comment: "Displays the Post's Options")
        static let cancelTitle              = NSLocalizedString("Cancel", comment: "Dismisses the Alert from Screen")
    }

    struct Colors {
        static let aztecBackground          = UIColor.clear
        static let title                    = WPStyleGuide.grey()
        static let separator                = WPStyleGuide.greyLighten30()
        static let placeholder              = WPStyleGuide.grey()
        static let progressBackground       = WPStyleGuide.wordPressBlue()
        static let progressTint             = UIColor.white
        static let progressTrack            = WPStyleGuide.wordPressBlue()
        static let mediaProgressOverlay     = WPStyleGuide.darkGrey().withAlphaComponent(CGFloat(0.6))
        static let mediaProgressBarBackground = WPStyleGuide.lightGrey()
        static let mediaProgressBarTrack    = WPStyleGuide.wordPressBlue()
        static let aztecLinkColor           = WPStyleGuide.mediumBlue()
        static let mediaOverlayBorderColor  = WPStyleGuide.wordPressBlue()
    }

    struct Fonts {
        static let regular                  = WPFontManager.notoRegularFont(ofSize: 16)
        static let semiBold                 = WPFontManager.systemSemiBoldFont(ofSize: 16)
        static let title                    = WPFontManager.notoBoldFont(ofSize: 24.0)
        static let blogPicker               = Fonts.semiBold
        static let mediaPickerInsert        = WPFontManager.systemMediumFont(ofSize: 15.0)
        static let mediaOverlay             = WPFontManager.systemSemiBoldFont(ofSize: 15.0)
        static let monospace                = UIFont(name: "Menlo-Regular", size: 16.0)!
    }

    struct Restoration {
        static let restorationIdentifier    = "AztecPostViewController"
        static let postIdentifierKey        = AbstractPost.classNameWithoutNamespaces()
        static let shouldRemovePostKey      = "shouldRemovePostOnDismiss"
    }

    struct SwitchSiteAlert {
        static let title                    = NSLocalizedString("Change Site", comment: "Title of an alert prompting the user that they are about to change the blog they are posting to.")
        static let message                  = NSLocalizedString("Choosing a different site will lose edits to site specific content like media and categories. Are you sure?", comment: "And alert message warning the user they will loose blog specific edits like categories, and media if they change the blog being posted to.")

        static let acceptTitle              = NSLocalizedString("OK", comment: "Accept Action")
        static let cancelTitle              = NSLocalizedString("Cancel", comment: "Cancel Action")
    }

    struct MediaUploadingAlert {
        static let title = NSLocalizedString("Uploading media", comment: "Title for alert when trying to save/exit a post before media upload process is complete.")
        static let message = NSLocalizedString("You are currently uploading media. Please wait until this completes.", comment: "This is a notification the user receives if they are trying to save a post (or exit) before the media upload process is complete.")
        static let acceptTitle  = NSLocalizedString("OK", comment: "Accept Action")
    }

    struct FailedMediaRemovalAlert {
        static let title = NSLocalizedString("Uploads failed", comment: "Title for alert when trying to save post with failed media items")
        static let message = NSLocalizedString("Some media uploads failed. This action will remove all failed media from the post.\nSave anyway?", comment: "Confirms with the user if they save the post all media that failed to upload will be removed from it.")
        static let acceptTitle  = NSLocalizedString("Yes", comment: "Accept Action")
        static let cancelTitle  = NSLocalizedString("Not Now", comment: "Nicer dialog answer for \"No\".")
    }

    struct MediaUploadingCancelAlert {
        static let title = NSLocalizedString("Cancel media uploads", comment: "Dialog box title for when the user is cancelling an upload.")
        static let message = NSLocalizedString("You are currently uploading media. This action will cancel uploads in progress.\n\nAre you sure?", comment: "This prompt is displayed when the user attempts to stop media uploads in the post editor.")
        static let acceptTitle  = NSLocalizedString("Yes", comment: "Yes")
        static let cancelTitle  = NSLocalizedString("Not Now", comment: "Nicer dialog answer for \"No\".")
    }
}
