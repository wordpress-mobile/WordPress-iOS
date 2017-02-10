import Foundation
import UIKit
import Aztec
import Gridicons
import WordPressShared
import AFNetworking
import WPMediaPicker
import SVProgressHUD

// MARK: - Aztec's Native Editor!
//
class AztecPostViewController: UIViewController {

    /// Closure to be executed when the editor gets closed
    ///
    var onClose: ((_ changesSaved: Bool) -> ())?


    /// Aztec's Awesomeness
    ///
    fileprivate(set) lazy var richTextView: Aztec.TextView = {
        let tv = Aztec.TextView(defaultFont: Assets.defaultRegularFont, defaultMissingImage: Assets.defaultMissingImage)

        tv.font = Assets.defaultRegularFont
        tv.accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        tv.delegate = self
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.formatter = self
        tv.inputAccessoryView = toolbar
        tv.textColor = UIColor.darkText
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.keyboardDismissMode = .interactive
        tv.mediaDelegate = self

        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(richTextViewWasPressed))
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self

        tv.addGestureRecognizer(recognizer)

        return tv
    }()


    /// Raw HTML Editor
    ///
    fileprivate(set) lazy var htmlTextView: UITextView = {
        let tv = UITextView()

        tv.accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        tv.font = Assets.defaultRegularFont
        tv.textColor = UIColor.darkText
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isHidden = true
        tv.keyboardDismissMode = .interactive

        return tv
    }()


    /// Title's TextField
    ///
    fileprivate(set) lazy var titleTextField: UITextField = {
        let placeholderText = NSLocalizedString("Post title", comment: "Placeholder for the post title.")
        let tf = UITextField()

        tf.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        tf.attributedPlaceholder = NSAttributedString(string: placeholderText,
                                                      attributes: [NSForegroundColorAttributeName: WPStyleGuide.greyLighten30()])
        tf.delegate = self
        tf.font = WPFontManager.merriweatherBoldFont(ofSize: 24.0)
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.enabled = false
        tf.inputAccessoryView = toolbar
        tf.returnKeyType = .next
        tf.textColor = UIColor.darkText
        tf.translatesAutoresizingMaskIntoConstraints = false

        tf.addTarget(self, action: #selector(titleTextFieldDidChange), for: [.editingChanged])

        return tf
    }()


    /// Separator View
    ///
    fileprivate(set) lazy var separatorView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 1))

        v.backgroundColor = WPStyleGuide.greyLighten30()
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()


    /// Negative Offset BarButtonItem: Used to fine tune navigationBar Items
    ///
    fileprivate lazy var separatorButtonItem: UIBarButtonItem = {
        let separator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        separator.width = Constants.separatorButtonWidth
        return separator
    }()


    /// NavigationBar's Close Button
    ///
    fileprivate lazy var closeBarButtonItem: UIBarButtonItem = {
        let cancelItem = UIBarButtonItem(customView: self.closeButton)
        cancelItem.accessibilityLabel = NSLocalizedString("Close", comment: "Action button to close edior and cancel changes or insertion of post")
        return cancelItem
    }()


    /// NavigationBar's Blog Picker Button
    ///
    fileprivate lazy var blogPickerBarButtonItem: UIBarButtonItem = {
        let pickerItem = UIBarButtonItem(customView: self.blogPickerButton)
        pickerItem.accessibilityLabel = NSLocalizedString("Switch Blog", comment: "Action button to switch the blog to which you'll be posting")
        return pickerItem
    }()

    /// Publish Button
    fileprivate(set) lazy var publishButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: self.postEditorStateContext.publishButtonText, style: WPStyleGuide.barButtonStyleForDone(), target: self, action: #selector(publishButtonTapped(sender:)))
        button.isEnabled = self.postEditorStateContext.isPublishButtonEnabled

        return button
    }()

    /// NavigationBar's More Button
    ///
    fileprivate lazy var moreBarButtonItem: UIBarButtonItem = {
        let image = Gridicon.iconOfType(.ellipsis)
        let moreItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(moreWasPressed))
        moreItem.accessibilityLabel = NSLocalizedString("More", comment: "Action button to display more available options")
        return moreItem
    }()


    /// Dismiss Button
    ///
    fileprivate lazy var closeButton: WPButtonForNavigationBar = {
        let cancelButton = WPStyleGuide.buttonForBar(with: Assets.closeButtonModalImage, target: self, selector: #selector(closeWasPressed))
        cancelButton.leftSpacing = Constants.cancelButtonPadding.left
        cancelButton.rightSpacing = Constants.cancelButtonPadding.right

        return cancelButton
    }()


    /// Blog Picker's Button
    ///
    fileprivate lazy var blogPickerButton: WPBlogSelectorButton = {
        let button = WPBlogSelectorButton(frame: .zero, buttonStyle: .typeSingleLine)
        button.addTarget(self, action: #selector(blogPickerWasPressed), for: .touchUpInside)
        return button
    }()


    /// Active Editor's Mode
    ///
    fileprivate(set) var mode = EditionMode.richText {
        didSet {
            switch mode {
            case .html:
                switchToHTML()
            case .richText:
                switchToRichText()
            }
        }
    }

    /// Post being currently edited
    ///
    fileprivate(set) var post: AbstractPost {
        didSet {
            removeObservers(fromPost: oldValue)
            addObservers(toPost: post)

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
    fileprivate lazy var mediaLibraryDataSource: WPAndDeviceMediaLibraryDataSource = {
        return WPAndDeviceMediaLibraryDataSource(post: self.post)
    }()

    fileprivate lazy var mediaProgressCoordinator: MediaProgressCoordinator = {
        let coordinator = MediaProgressCoordinator()
        coordinator.delegate = self
        return coordinator
    }()

    fileprivate lazy var mediaProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.backgroundColor = WPStyleGuide.wordPressBlue()
        progressView.progressTintColor = UIColor.white
        progressView.trackTintColor = WPStyleGuide.wordPressBlue()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()

    /// Maintainer of state for editor - like for post button
    ///
    fileprivate(set) lazy var postEditorStateContext: PostEditorStateContext = {
        var originalPostStatus: PostStatus? = nil

        if let originalPost = self.post.original,
            let postStatus = originalPost.status,
            originalPost.hasRemote() {
            originalPostStatus = PostStatus(rawValue: postStatus)
        }

        // TODO: Determine if user can actually publish to site or not
        let context = PostEditorStateContext(originalPostStatus: originalPostStatus, userCanPublish: true, delegate: self)

        return context
    }()


    // MARK: - Lifecycle Methods

    init(post: AbstractPost) {
        self.post = post

        super.init(nibName: nil, bundle: nil)

        self.shouldRemovePostOnDismiss = shouldRemoveOnDismiss(post: post)
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


    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Fix the warnings triggered by this one!
        WPFontManager.loadMerriweatherFontFamily()

        createRevisionOfPost()

        configureNavigationBar()
        configureDismissButton()
        configureView()
        configureSubviews()

        view.setNeedsUpdateConstraints()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startListeningToNotifications()
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopListeningToNotifications()
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.resizeBlogPickerButton()
        })

        // TODO: Update toolbars
        //    [self.editorToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];
        //    [self.titleToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];

    }

    // MARK: - Configuration Methods

    override func updateViewConstraints() {

        super.updateViewConstraints()

        let defaultMargin = Constants.defaultMargin

        NSLayoutConstraint.activate([
            titleTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: defaultMargin),
            titleTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -defaultMargin),
            titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: defaultMargin),
            titleTextField.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
            ])

        NSLayoutConstraint.activate([
            separatorView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: defaultMargin),
            separatorView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -defaultMargin),
            separatorView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: defaultMargin),
            separatorView.heightAnchor.constraint(equalToConstant: separatorView.frame.height)
            ])

        NSLayoutConstraint.activate([
            richTextView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: defaultMargin),
            richTextView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -defaultMargin),
            richTextView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: defaultMargin),
            richTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -defaultMargin)
            ])

        NSLayoutConstraint.activate([
            htmlTextView.leftAnchor.constraint(equalTo: richTextView.leftAnchor),
            htmlTextView.rightAnchor.constraint(equalTo: richTextView.rightAnchor),
            htmlTextView.topAnchor.constraint(equalTo: richTextView.topAnchor),
            htmlTextView.bottomAnchor.constraint(equalTo: richTextView.bottomAnchor),
            ])

        NSLayoutConstraint.activate([
            mediaProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mediaProgressView.widthAnchor.constraint(equalTo: view.widthAnchor),
            mediaProgressView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor)
            ])
    }

    func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false

        navigationItem.leftBarButtonItems = [separatorButtonItem, closeBarButtonItem, blogPickerBarButtonItem]
        navigationItem.rightBarButtonItems = [moreBarButtonItem, publishButton]
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
        view.addSubview(titleTextField)
        view.addSubview(separatorView)
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)
        mediaProgressView.isHidden = true
        view.addSubview(mediaProgressView)
    }

    func startListeningToNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }

    func stopListeningToNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        notificationCenter.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    func refreshInterface() {
        reloadBlogPickerButton()
        reloadEditorContents()
        resizeBlogPickerButton()
    }

    func reloadEditorContents() {
        let content = post.content ?? String()

        titleTextField.text = post.postTitle
        richTextView.setHTML(content)
    }

    func reloadBlogPickerButton() {
        var pickerTitle = post.blog.url ?? String()
        if let blogName = post.blog.settings?.name, blogName.isEmpty == false {
            pickerTitle = blogName
        }

        let titleText = NSAttributedString(string: pickerTitle, attributes: Constants.blogPickerAttributes)
        let shouldEnable = !isSingleSiteMode

        blogPickerButton.setAttributedTitle(titleText, for: .normal)
        blogPickerButton.buttonMode = shouldEnable ? .multipleSite : .singleSite
        blogPickerButton.isEnabled = shouldEnable
    }

    func resizeBlogPickerButton() {
        // Ensure the BlogPicker gets it's maximum possible size
        blogPickerButton.sizeToFit()

        // Cap the size, according to the current traits
        var blogPickerSize = hasHorizontallyCompactView() ? Constants.blogPickerCompactSize : Constants.blogPickerRegularSize
        blogPickerSize.width = min(blogPickerSize.width, blogPickerButton.frame.width)

        blogPickerButton.frame.size = blogPickerSize
    }


    // MARK: - Keyboard Handling

    func keyboardWillShow(_ notification: Foundation.Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    func keyboardWillHide(_ notification: Foundation.Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    fileprivate func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        htmlTextView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)
        htmlTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)

        richTextView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)
        richTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)
    }


    func updateFormatBar() {
        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        let identifiers = richTextView.formatIdentifiersForTypingAttributes()
        toolbar.selectItemsMatchingIdentifiers(identifiers)
    }
}


// MARK: - Actions
extension AztecPostViewController {
    @IBAction func publishButtonTapped(sender: UIBarButtonItem) {
        handlePublishButtonTapped(secondaryPublishTapped: false)
    }

    @IBAction func secondaryPublishButtonTapped() {
        let publishPostClosure = {
            if self.postEditorStateContext.secondaryPublishButtonAction == .save {
                self.post.status = PostStatusDraft
            } else if self.postEditorStateContext.secondaryPublishButtonAction == .publish {
                self.post.status = PostStatusPublish
            }

            self.handlePublishButtonTapped(secondaryPublishTapped: true)
        }

        if presentedViewController != nil {
            dismiss(animated: true, completion: publishPostClosure)
        } else {
            publishPostClosure()
        }
    }

    private func handlePublishButtonTapped(secondaryPublishTapped: Bool) {
        // Cancel publishing if media is currently being uploaded
        if mediaProgressCoordinator.isRunning {
            let alertController = UIAlertController(title: MediaUploadingAlert.title, message: MediaUploadingAlert.message, preferredStyle: .alert)
            alertController.addDefaultActionWithTitle(MediaUploadingAlert.acceptTitle)
            present(alertController, animated: true, completion: nil)

            return
        }

        // If there is any failed media allow it to be removed or cancel publishing
        if mediaProgressCoordinator.hasFailedMedia {
            let alertController = UIAlertController(title: FailedMediaRemovalAlert.title, message: FailedMediaRemovalAlert.message, preferredStyle: .alert)
            alertController.addDefaultActionWithTitle(MediaUploadingAlert.acceptTitle) { alertAction in
                self.removeFailedMedia()
                // Failed media is removed, try again.
                self.handlePublishButtonTapped(secondaryPublishTapped: secondaryPublishTapped)
            }

            alertController.addCancelActionWithTitle(FailedMediaRemovalAlert.cancelTitle)
            present(alertController, animated: true, completion: nil)
        }

        SVProgressHUD.show(withStatus: postEditorStateContext.publishVerbText, maskType: .clear)
        postEditorStateContext.updated(isBeingPublished: true)

        // Finally, publish the post.
        publishPost(secondaryPublishTapped: secondaryPublishTapped) { uploadedPost, error in
            self.postEditorStateContext.updated(isBeingPublished: false)
            SVProgressHUD.dismiss()

            if let error = error {
                DDLogSwift.logError("Error publishing post: \(error.localizedDescription)")

                SVProgressHUD.showError(withStatus: self.postEditorStateContext.publishErrorText)
                WPNotificationFeedbackGenerator.notificationOccurred(.error)
            } else if let uploadedPost = uploadedPost {
                // TODO: Determine if this is necessary; if it is then ensure state machine is updated
                self.post = uploadedPost

                WPNotificationFeedbackGenerator.notificationOccurred(.success)
            }

            // TODO: Switch to posts list if appropriate

            // Don't dismiss - make draft now in secondary publish
            let shouldDismissWindow: Bool
            if let secondaryAction = self.postEditorStateContext.secondaryPublishButtonAction,
                secondaryPublishTapped && secondaryAction == .save {
                shouldDismissWindow = false
            } else {
                shouldDismissWindow = true
            }

            if shouldDismissWindow {
                self.dismissOrPopView(didSave: true)
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
}


// MARK: - Private Helpers
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
            alert.addActionWithTitle(buttonTitle, style: .destructive) { _ in
                self.secondaryPublishButtonTapped()
            }
        }

        let switchModeTitle = (mode == .richText) ? MoreSheetAlert.htmlTitle : MoreSheetAlert.richTitle
        alert.addDefaultActionWithTitle(switchModeTitle) { _ in
            self.mode.toggle()
        }

        alert.addDefaultActionWithTitle(MoreSheetAlert.previewTitle) { _ in
            self.displayPreview()
        }

        alert.addDefaultActionWithTitle(MoreSheetAlert.optionsTitle) { _ in
            self.displayPostOptions()
        }

        alert.addCancelActionWithTitle(MoreSheetAlert.cancelTitle)
        alert.popoverPresentationController?.barButtonItem = moreBarButtonItem

        view.endEditing(true)
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
        let settingsViewController = PostSettingsViewController(post: post)
        settingsViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(settingsViewController, animated: true)
    }

    func displayPreview() {
        let previewController = PostPreviewViewController(post: post)
        previewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(previewController, animated: true)
    }
}



// MARK: - PostEditorStateContextDelegate & support methods
extension AztecPostViewController: PostEditorStateContextDelegate {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AbstractPost.status) {
            if let status = post.status {
                postEditorStateContext.updated(postStatus: PostStatus(rawValue: status) ?? .draft)
            }
            return
        } else if keyPath == #keyPath(AbstractPost.dateCreated) {
            let dateCreated = post.dateCreated ?? Date()
            postEditorStateContext.updated(publishDate: dateCreated)
            return
        } else if keyPath == #keyPath(AbstractPost.content) {
            postEditorStateContext.updated(hasContent: editorHasContent)
            return
        }


        super.observeValue(forKeyPath: keyPath,
                           of: object,
                           change: change,
                           context: context)
    }

    internal func titleTextFieldDidChange(textField: UITextField) {
        postEditorStateContext.updated(hasContent: editorHasContent)
    }

    // TODO: We should be tracking hasContent and isDirty separately for enabling button in the state context
    private var editorHasContent: Bool {
        let contentCharacterCount = post.content?.characters.count ?? 0
        // Title isn't updated on post until editing is done - this looks at realtime changes
        let titleCharacterCount = titleTextField.text?.characters.count ?? 0

        return contentCharacterCount + titleCharacterCount > 0
    }

    internal func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {
        publishButton.title = context.publishButtonText
    }

    internal func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {
        publishButton.isEnabled = context.isPublishButtonEnabled
    }

    internal func addObservers(toPost: AbstractPost) {
        toPost.addObserver(self, forKeyPath: #keyPath(AbstractPost.status), options: [], context: nil)
        toPost.addObserver(self, forKeyPath: #keyPath(AbstractPost.dateCreated), options: [], context: nil)
        toPost.addObserver(self, forKeyPath: #keyPath(AbstractPost.content), options: [], context: nil)
    }

    internal func removeObservers(fromPost: AbstractPost) {
        fromPost.removeObserver(self, forKeyPath: #keyPath(AbstractPost.status))
        fromPost.removeObserver(self, forKeyPath: #keyPath(AbstractPost.dateCreated))
        fromPost.removeObserver(self, forKeyPath: #keyPath(AbstractPost.content))
    }
}


// MARK: - UITextViewDelegate methods
extension AztecPostViewController : UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        updateFormatBar()
    }

    func textViewDidChange(_ textView: UITextView) {
        mapUIContentToPostAndSave()
    }
}


// MARK: - UITextFieldDelegate methods
extension AztecPostViewController : UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        mapUIContentToPostAndSave()
    }
}


// MARK: - HTML Mode Switch methods
extension AztecPostViewController {
    enum EditionMode {
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

    fileprivate func switchToHTML() {
        view.endEditing(true)

        htmlTextView.text = richTextView.getHTML()
        htmlTextView.isHidden = false
        richTextView.isHidden = true
    }

    fileprivate func switchToRichText() {
        view.endEditing(true)

        richTextView.setHTML(htmlTextView.text)
        richTextView.isHidden = false
        htmlTextView.isHidden = true
    }
}

// MARK: - FormatBarDelegate Conformance
extension AztecPostViewController : Aztec.FormatBarDelegate {

    func handleActionForIdentifier(_ identifier: FormattingIdentifier) {

        switch identifier {
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
            case .unorderedlist:
                toggleUnorderedList()
            case .orderedlist:
                toggleOrderedList()
            case .link:
                toggleLink()
            case .media:
                showImagePicker()
        }
        updateFormatBar()
    }

    func toggleBold() {
        richTextView.toggleBold(range: richTextView.selectedRange)
    }


    func toggleItalic() {
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }


    func toggleUnderline() {
        richTextView.toggleUnderline(range: richTextView.selectedRange)
    }


    func toggleStrikethrough() {
        richTextView.toggleStrikethrough(range: richTextView.selectedRange)
    }


    func toggleOrderedList() {
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }


    func toggleUnorderedList() {
        richTextView.toggleUnorderedList(range: richTextView.selectedRange)
    }


    func toggleBlockquote() {
        richTextView.toggleBlockquote(range: richTextView.selectedRange)
    }


    func toggleLink() {
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

        let isInsertingNewLink = (url == nil)
        var urlToUse = url

        if isInsertingNewLink {
            let pasteboard = UIPasteboard.general
            if let pastedURL = pasteboard.value(forPasteboardType:String(kUTTypeURL)) as? URL {
                urlToUse = pastedURL
            }
        }


        let insertButtonTitle = isInsertingNewLink ? NSLocalizedString("Insert Link", comment: "Label action for inserting a link on the editor") : NSLocalizedString("Update Link", comment: "Label action for updating a link on the editor")
        let removeButtonTitle = NSLocalizedString("Remove Link", comment: "Label action for removing a link from the editor")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel button")

        let alertController = UIAlertController(title: insertButtonTitle,
                                                message: nil,
                                                preferredStyle: UIAlertControllerStyle.alert)

        alertController.addTextField(configurationHandler: { [weak self]textField in
            textField.clearButtonMode = UITextFieldViewMode.always
            textField.placeholder = NSLocalizedString("URL", comment: "URL text field placeholder")

            textField.text = urlToUse?.absoluteString

            textField.addTarget(self,
                action: #selector(AztecPostViewController.alertTextFieldDidChange),
                for: UIControlEvents.editingChanged)
            })

        alertController.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = UITextFieldViewMode.always
            textField.placeholder = NSLocalizedString("Link Name", comment: "Link name field placeholder")
            textField.isSecureTextEntry = false
            textField.autocapitalizationType = UITextAutocapitalizationType.sentences
            textField.autocorrectionType = UITextAutocorrectionType.default
            textField.spellCheckingType = UITextSpellCheckingType.default

            textField.text = title
        })

        let insertAction = UIAlertAction(title: insertButtonTitle,
                                         style: UIAlertActionStyle.default,
                                         handler: { [weak self] action in

                                            self?.richTextView.becomeFirstResponder()
                                            let linkURLString = alertController.textFields?.first?.text
                                            var linkTitle = alertController.textFields?.last?.text

                                            if  linkTitle == nil  || linkTitle!.isEmpty {
                                                linkTitle = linkURLString
                                            }

                                            guard
                                                let urlString = linkURLString,
                                                let url = URL(string: urlString),
                                                let title = linkTitle
                                                else {
                                                    return
                                            }
                                            self?.richTextView.setLink(url, title: title, inRange: range)
            })

        let removeAction = UIAlertAction(title: removeButtonTitle,
                                         style: UIAlertActionStyle.destructive,
                                         handler: { [weak self] action in
                                            self?.richTextView.becomeFirstResponder()
                                            self?.richTextView.removeLink(inRange: range)
            })

        let cancelAction = UIAlertAction(title: cancelButtonTitle,
                                         style: UIAlertActionStyle.cancel,
                                         handler: { [weak self]action in
                                            self?.richTextView.becomeFirstResponder()
            })

        alertController.addAction(insertAction)
        if !isInsertingNewLink {
            alertController.addAction(removeAction)
        }
        alertController.addAction(cancelAction)

        // Disabled until url is entered into field
        if let text = alertController.textFields?.first?.text {
            insertAction.isEnabled = !text.isEmpty
        }

        self.present(alertController, animated: true, completion: nil)
    }

    func alertTextFieldDidChange(_ textField: UITextField) {
        guard
            let alertController = presentedViewController as? UIAlertController,
            let urlFieldText = alertController.textFields?.first?.text,
            let insertAction = alertController.actions.first
            else {
                return
        }

        insertAction.isEnabled = !urlFieldText.isEmpty
    }

    func showImagePicker() {

        let picker = WPMediaPickerViewController()
        picker.dataSource = mediaLibraryDataSource
        picker.showMostRecentFirst = true
        picker.filter = WPMediaType.image
        picker.delegate = self
        picker.modalPresentationStyle = .currentContext

        present(picker, animated: true, completion: nil)
    }


    // MARK: -

    func createToolbar() -> Aztec.FormatBar {
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let items = [
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.addImage), identifier: .media),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.bold), identifier: .bold),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.italic), identifier: .italic),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.underline), identifier: .underline),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.strikethrough), identifier: .strikethrough),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.quote), identifier: .blockquote),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.listUnordered), identifier: .unorderedlist),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.listOrdered), identifier: .orderedlist),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.link), identifier: .link),
            flex,
            ]

        let toolbar = Aztec.FormatBar()

        toolbar.barTintColor = UIColor(fromHex: 0xF9FBFC, alpha: 1)
        toolbar.tintColor = WPStyleGuide.greyLighten10()
        toolbar.highlightedTintColor = UIColor.blue
        toolbar.selectedTintColor = UIColor.darkGray
        toolbar.disabledTintColor = UIColor.lightGray
        toolbar.items = items
        return toolbar
    }

    func templateImage(named: String) -> UIImage {
        return UIImage(named: named)!.withRenderingMode(.alwaysTemplate)
    }
}


// MARK: - UINavigationControllerDelegate Conformance
extension AztecPostViewController: UINavigationControllerDelegate {

}

// MARK: - Cancel/Dismiss/Persistence Logic
fileprivate extension AztecPostViewController {
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
        let blogService = BlogService(managedObjectContext: mainContext)
        let postService = PostService(managedObjectContext: mainContext)
        let newPost = postService.createDraftPost(for: blog)

        blogService.flagBlog(asLastUsed: blog)

        //  TODO: Strip Media!
        //  NSString *content = oldPost.content;
        //  for (Media *media in oldPost.media) {
        //      content = [self removeMedia:media fromString:content];
        //  }

        newPost.content = post.content
        newPost.postTitle = post.postTitle
        newPost.password = post.password
        newPost.status = post.status
        newPost.dateCreated = post.dateCreated
        newPost.dateModified = post.dateModified

        if let source = post as? Post {
            newPost.tags = source.tags
        }

        discardChanges()
        post = newPost
        createRevisionOfPost()

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
        if titleTextField.isFirstResponder {
            titleTextField.resignFirstResponder()
        }

        view.endEditing(true)
    }

    func showPostHasChangesAlert() {
        let alertController = UIAlertController(
            title: NSLocalizedString("You have unsaved changes.", comment: "Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post."),
            message: nil,
            preferredStyle: .actionSheet)

        // Button: Keep editing
        alertController.addCancelActionWithTitle(NSLocalizedString("Keep Editing", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post."))

        // Button: Discard
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Discard", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")) { _ in
            self.discardChangesAndUpdateGUI()
        }

        // Button: Save Draft/Update Draft
        if post.hasLocalChanges() {
            if post.hasRemote() {
                // The post is a local draft or an autosaved draft: Discard or Save
                alertController.addDefaultActionWithTitle(NSLocalizedString("Save Draft", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")) { _ in
                    // TODO: Save Draft
                }
            } else if post.status == PostStatusDraft {
                // The post was already a draft
                alertController.addDefaultActionWithTitle(NSLocalizedString("Update Draft", comment: "Button shown if there are unsaved changes and the author is trying to move away from an already published/saved post.")) { _ in
                    // TODO: Save Draft
                }
            }
        }

        alertController.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
        present(alertController, animated: true, completion: nil)
    }

    func discardChanges() {
        guard let context = post.managedObjectContext, let originalPost = post.original else {
            return
        }

        post = originalPost
        post.deleteRevision()

        if shouldRemovePostOnDismiss {
            post.remove()
        }

        ContextManager.sharedInstance().save(context)
    }

    func discardChangesAndUpdateGUI() {
        discardChanges()

        dismissOrPopView(didSave: false)
    }

    func dismissOrPopView(didSave: Bool) {
        onClose?(didSave)

        if isModal() {
            presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }

    func shouldRemoveOnDismiss(post: AbstractPost) -> Bool {
        return post.isRevision() && post.hasLocalChanges() || post.hasNeverAttemptedToUpload()
    }

    fileprivate func mapUIContentToPostAndSave() {
        post.postTitle = richTextView.text
        // TODO: This may not be super performant; Instrument and improve if needed and remove this TODO
        post.content = richTextView.getHTML()

        ContextManager.sharedInstance().save(post.managedObjectContext!)
    }

    fileprivate func publishPost(secondaryPublishTapped: Bool = false, completion: ((_ post: AbstractPost?, _ error: Error?) -> Void)? = nil) {
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
}


// MARK: - Media Support
extension AztecPostViewController: MediaProgressCoordinatorDelegate {
    func mediaProgressCoordinator(_ mediaProgressCoordinator: MediaProgressCoordinator, progressDidChange progress: Float) {
        mediaProgressView.isHidden = !mediaProgressCoordinator.isRunning
        mediaProgressView.progress = progress
        for (attachmentID, progress) in self.mediaProgressCoordinator.mediaUploading {
            guard let attachment = richTextView.attachment(withId: attachmentID) else {
                continue
            }
            if progress.fractionCompleted >= 1 {
                attachment.progress = nil
            } else {
                attachment.progress = progress.fractionCompleted
                attachment.progressColor = WPStyleGuide.wordPressBlue()
            }
            richTextView.refreshLayoutFor(attachment: attachment)
        }
    }

    func mediaProgressCoordinatorDidStartUploading(_ mediaProgressCoordinator: MediaProgressCoordinator) {
        postEditorStateContext.update(isUploadingMedia: true)
    }

    func mediaProgressCoordinatorDidFinishingUpload(_ mediaProgressCoordinator: MediaProgressCoordinator) {
        postEditorStateContext.update(isUploadingMedia: false)
    }

    fileprivate func addDeviceMediaAsset(_ phAsset: PHAsset) {
        let attachment = self.richTextView.insertImage(sourceURL: URL(string:"placeholder://")! , atPosition: self.richTextView.selectedRange.location, placeHolderImage: Assets.defaultMissingImage)
        let mediaService = MediaService(managedObjectContext:ContextManager.sharedInstance().mainContext)
        mediaService.createMedia(with: phAsset, forPost: post.objectID, thumbnailCallback: { (thumbnailURL) in
            DispatchQueue.main.async {
                self.richTextView.update(attachment: attachment, alignment: attachment.alignment, size: attachment.size, url: thumbnailURL)
            }
        }, completion: { [weak self](media, error) in
            guard let strongSelf = self else {
                return
            }
            guard let media = media, error == nil else {
                DispatchQueue.main.async {
                    strongSelf.handleError(error as? NSError, onAttachment: attachment)
                }
                return
            }
            strongSelf.upload(media: media, mediaID: attachment.identifier)
        })
    }

    fileprivate func addSiteMediaAsset(_ media: Media) {
        if media.mediaID.intValue != 0 {
            guard let remoteURL = URL(string: media.remoteURL) else {
                return
            }
            let _ = richTextView.insertImage(sourceURL: remoteURL, atPosition: self.richTextView.selectedRange.location, placeHolderImage: Assets.defaultMissingImage)
            self.mediaProgressCoordinator.finishOneItem()
        } else {
            var tempMediaURL = URL(string:"placeholder://")!
            if let mediaLocalPath = media.absoluteLocalURL,
                let localURL = URL(string: mediaLocalPath) {
                tempMediaURL = localURL
            }
            let attachment = self.richTextView.insertImage(sourceURL:tempMediaURL, atPosition: self.richTextView.selectedRange.location, placeHolderImage: Assets.defaultMissingImage)

            upload(media: media, mediaID: attachment.identifier)
        }
    }

    private func upload(media: Media, mediaID: String) {
        guard let attachment = richTextView.attachment(withId: mediaID) else {
            return
        }
        let mediaService = MediaService(managedObjectContext:ContextManager.sharedInstance().mainContext)
        var uploadProgress: Progress?
        mediaService.uploadMedia(media, progress: &uploadProgress, success: {[weak self]() in
            guard let strongSelf = self, let remoteURL = URL(string:media.remoteURL) else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.richTextView.update(attachment: attachment, alignment: attachment.alignment, size: attachment.size, url: remoteURL)
            }
            }, failure: { [weak self](error) in
                guard let strongSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.handleError(error as NSError, onAttachment: attachment)
                }
        })
        if let progress = uploadProgress {
            mediaProgressCoordinator.track(progress: progress, ofObject: media, withMediaID: mediaID)
        }
    }

    private func handleError(_ error: NSError?, onAttachment attachment: Aztec.TextAttachment) {
        let message = NSLocalizedString("Failed to insert media on your post.\n Please tap to retry.", comment: "Error message to show to use when media insertion on a post fails")
        if let error = error {
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                return
            }
            mediaProgressCoordinator.attach(error: error, toMediaID: attachment.identifier)
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let shadow = NSShadow()
        shadow.shadowColor = UIColor(white: 0, alpha: 0.6)
        let attributes: [String:Any] = [NSFontAttributeName: Assets.defaultSemiBoldFont,
                                        NSParagraphStyleAttributeName: paragraphStyle,
                                        NSForegroundColorAttributeName: UIColor.darkGray,
                                        NSShadowAttributeName: shadow]
        let attributeMessage = NSAttributedString(string: message, attributes: attributes)
        attachment.message = attributeMessage
        richTextView.refreshLayoutFor(attachment: attachment)
    }

    fileprivate func removeFailedMedia() {
        // TODO: Implement this method to remove failed media.
    }

    // TODO: Extract these strings into structs like other items
    fileprivate func displayActions(forAttachment attachment: TextAttachment, position: CGPoint) {
        let mediaID = attachment.identifier
        let title: String = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
        var message: String?
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alertController.addActionWithTitle(NSLocalizedString("Dismiss", comment: "User action to dismiss media options."),
                                           style: .cancel,
                                           handler: { (action) in
        })

        alertController.addActionWithTitle(NSLocalizedString("Details", comment: "User action to edit media details."),
                                           style: .default,
                                           handler: { (action) in
                                            self.displayDetails(forAttachment: attachment)
        })
        // Is upload still going?
        if let mediaProgress = mediaProgressCoordinator.mediaUploading[mediaID],
            mediaProgress.completedUnitCount < mediaProgress.totalUnitCount {
            alertController.addActionWithTitle(NSLocalizedString("Stop Upload", comment: "User action to stop upload."),
                                               style: .destructive,
                                               handler: { (action) in
                                                mediaProgress.cancel()
                                                self.richTextView.remove(attachmentID: mediaID)
            })
        } else {
            alertController.addActionWithTitle(NSLocalizedString("Remove Media", comment: "User action to remove media."),
                                               style: .destructive,
                                               handler: { (action) in
                                                self.richTextView.remove(attachmentID: mediaID)
            })
            if let error = mediaProgressCoordinator.error(forMediaID: mediaID) {
                message = error.localizedDescription
                alertController.addActionWithTitle(NSLocalizedString("Retry Upload", comment: "User action to retry media upload."),
                                                   style: .default,
                                                   handler: { (action) in
                                                    //retry upload
                                                    if let media = self.mediaProgressCoordinator.object(forMediaID: mediaID) as? Media,
                                                        let attachment = self.richTextView.attachment(withId: mediaID) {
                                                        attachment.message = nil
                                                        attachment.progress = 0
                                                        self.richTextView.refreshLayoutFor(attachment: attachment)
                                                        self.mediaProgressCoordinator.track(numberOfItems: 1)
                                                        self.upload(media: media, mediaID: mediaID)
                                                    }
                })
            }
        }

        alertController.title = title
        alertController.message = message
        alertController.popoverPresentationController?.sourceView = richTextView
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: richTextView.center, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .up
        present(alertController, animated:true, completion: nil)
    }

    func displayDetails(forAttachment attachment: TextAttachment) {

        let controller = AztecAttachmentViewController()
        controller.delegate = self
        controller.attachment = attachment
        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true, completion: nil)
    }
}

extension AztecPostViewController: AztecAttachmentViewControllerDelegate {


    func aztecAttachmentViewController(_ viewController: AztecAttachmentViewController, changedAttachment: TextAttachment) {
        richTextView.update(attachment: changedAttachment, alignment: changedAttachment.alignment, size: changedAttachment.size, url: changedAttachment.url!)
    }
}

extension AztecPostViewController: TextViewMediaDelegate {

    func textView(_ textView: TextView, imageAtUrl url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping (Void) -> Void) -> UIImage {
        var requestURL = url
        let imageMaxDimension = max(UIScreen.main.nativeBounds.size.width, UIScreen.main.nativeBounds.size.height)
        let size = CGSize(width: imageMaxDimension, height: imageMaxDimension)
        let request: URLRequest
        if url.isFileURL {
            request = URLRequest(url: url)
        } else if self.post.blog.isPrivate() {
            // private wpcom image needs special handling.
            requestURL = WPImageURLHelper.imageURLWithSize(size, forImageURL: requestURL)
            request = PrivateSiteURLProtocol.requestForPrivateSite(from: requestURL)
        } else {
            requestURL = PhotonImageURLHelper.photonURL(with: size, forImageURL: requestURL)
            request = URLRequest(url: requestURL)
        }

        let imageDownloader = AFImageDownloader.defaultInstance()
        let receipt = imageDownloader.downloadImage(for: request, success: { (request, response, image) in
            DispatchQueue.main.async(execute: {
                success(image)
            })
        }) { (request, response, error) in
            DispatchQueue.main.async(execute: {
                failure()
            })
        }

        if let receipt = receipt {
            activeMediaRequests.append(receipt)
        }

        return Gridicon.iconOfType(.image)
    }

    func textView(_ textView: TextView, urlForImage image: UIImage) -> URL {
        //TODO: add support for saving images that result from a copy/paste to the editor, this should save locally to file, and import to the media library.
        return URL(string:"")!
    }

    func cancelAllPendingMediaRequests() {
        let imageDownloader = AFImageDownloader.defaultInstance()
        for receipt in activeMediaRequests {
            imageDownloader.cancelTask(for: receipt)
        }
    }

    func textView(_ textView: TextView, deletedAttachmentWithID attachmentID: String) {
        if let mediaProgress = mediaProgressCoordinator.mediaUploading[attachmentID],
            mediaProgress.completedUnitCount < mediaProgress.totalUnitCount {
            mediaProgress.cancel()
        }
    }
}

extension AztecPostViewController: WPMediaPickerViewControllerDelegate {

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        dismiss(animated: true, completion: nil)
        richTextView.becomeFirstResponder()
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPickingAssets assets: [Any]) {
        dismiss(animated: true, completion: nil)
        richTextView.becomeFirstResponder()

        if assets.isEmpty {
            return
        }

        mediaProgressCoordinator.track(numberOfItems: assets.count)
        for asset in assets {
            switch asset {
            case let phAsset as PHAsset:
                addDeviceMediaAsset(phAsset)
            case let media as Media:
                addSiteMediaAsset(media)
            default:
                continue
            }
        }

    }
}

extension AztecPostViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func richTextViewWasPressed(_ recognizer: UIGestureRecognizer) {
        guard recognizer.state == .began else {
            return
        }
        let locationInTextView = recognizer.location(in: richTextView)
        guard let attachment = richTextView.attachmentAtPoint(locationInTextView) else {
            return
        }

        displayActions(forAttachment: attachment, position: locationInTextView)
    }
}

// MARK: - Constants
fileprivate extension AztecPostViewController {

    struct Assets {
        static let closeButtonModalImage    = Gridicon.iconOfType(.cross)
        static let closeButtonRegularImage  = UIImage(named: "icon-posts-editor-chevron")
        static let defaultRegularFont       = WPFontManager.merriweatherRegularFont(ofSize: 16)
        static let defaultSemiBoldFont      = WPFontManager.systemSemiBoldFont(ofSize: 16)
        static let defaultMissingImage      = Gridicon.iconOfType(.image)
    }

    struct Constants {
        static let defaultMargin            = CGFloat(20)
        static let separatorButtonWidth     = CGFloat(-12)
        static let cancelButtonPadding      = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        static let blogPickerAttributes     = [NSFontAttributeName: Assets.defaultSemiBoldFont]
        static let blogPickerCompactSize    = CGSize(width: 125, height: 30)
        static let blogPickerRegularSize    = CGSize(width: 300, height: 30)
    }

    struct MoreSheetAlert {
        static let htmlTitle    = NSLocalizedString("Switch to HTML", comment: "Switches the Editor to HTML Mode")
        static let richTitle    = NSLocalizedString("Switch to Rich Text", comment: "Switches the Editor to Rich Text Mode")
        static let previewTitle = NSLocalizedString("Preview", comment: "Displays the Post Preview Interface")
        static let optionsTitle = NSLocalizedString("Options", comment: "Displays the Post's Options")
        static let cancelTitle  = NSLocalizedString("Cancel", comment: "Dismisses the Alert from Screen")
    }

    struct SwitchSiteAlert {
        static let title        = NSLocalizedString("Change Site", comment: "Title of an alert prompting the user that they are about to change the blog they are posting to.")
        static let message      = NSLocalizedString("Choosing a different site will lose edits to site specific content like media and categories. Are you sure?", comment: "And alert message warning the user they will loose blog specific edits like categories, and media if they change the blog being posted to.")

        static let acceptTitle  = NSLocalizedString("OK", comment: "Accept Action")
        static let cancelTitle  = NSLocalizedString("Cancel", comment: "Cancel Action")
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
}

protocol MediaProgressCoordinatorDelegate: class {

    func mediaProgressCoordinator(_ mediaProgressCoordinator: MediaProgressCoordinator, progressDidChange progress: Float)
    func mediaProgressCoordinatorDidStartUploading(_ mediaProgressCoordinator: MediaProgressCoordinator)
    func mediaProgressCoordinatorDidFinishingUpload(_ mediaProgressCoordinator: MediaProgressCoordinator)
}

class MediaProgressCoordinator: NSObject {

    enum ProgressMediaKeys: String {
        case mediaID = "mediaID"
        case error = "mediaError"
        case mediaObject = "mediaObject"
    }

    weak var delegate: MediaProgressCoordinatorDelegate?

    private(set) var mediaUploadingProgress: Progress?

    private(set) lazy var mediaUploading: [String:Progress] = {
        return [String: Progress]()
    }()

    private var mediaUploadingProgressObserverContext: String = "mediaUploadingProgressObserverContext"

    deinit {
        mediaUploadingProgress?.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
    }

    func finishOneItem() {
        guard let mediaUploadingProgress = mediaUploadingProgress else {
            return
        }

        mediaUploadingProgress.completedUnitCount += 1

        if !isRunning {
            delegate?.mediaProgressCoordinatorDidFinishingUpload(self)
        }
    }

    func track(numberOfItems count: Int) {
        if let mediaUploadingProgress = self.mediaUploadingProgress, !isRunning {
            mediaUploadingProgress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
            self.mediaUploadingProgress = nil
        }

        if self.mediaUploadingProgress == nil {
            self.mediaUploadingProgress = Progress.discreteProgress(totalUnitCount: 0)
            self.mediaUploadingProgress?.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options:[.new], context:&mediaUploadingProgressObserverContext)

            delegate?.mediaProgressCoordinatorDidStartUploading(self)
        }

        self.mediaUploadingProgress?.totalUnitCount += count
    }

    func track(progress: Progress, ofObject object: Any, withMediaID mediaID: String) {
        progress.setUserInfoObject(mediaID, forKey: ProgressUserInfoKey(ProgressMediaKeys.mediaID.rawValue))
        progress.setUserInfoObject(object, forKey: ProgressUserInfoKey(ProgressMediaKeys.mediaObject.rawValue))
        mediaUploadingProgress?.addChild(progress, withPendingUnitCount: 1)
        mediaUploading[mediaID] = progress
    }

    func attach(error: NSError, toMediaID mediaID: String) {
        guard let progress = mediaUploading[mediaID] else {
            return
        }
        progress.setUserInfoObject(error, forKey: ProgressUserInfoKey(ProgressMediaKeys.error.rawValue))
    }

    func error(forMediaID mediaID: String) -> NSError? {
        guard let progress = mediaUploading[mediaID],
              let error = progress.userInfo[ProgressUserInfoKey(ProgressMediaKeys.error.rawValue)] as? NSError
        else {
            return nil
        }

        return error
    }

    func object(forMediaID mediaID: String) -> Any? {
        guard let progress = mediaUploading[mediaID],
            let object = progress.userInfo[ProgressUserInfoKey(ProgressMediaKeys.mediaObject.rawValue)]
            else {
                return nil
        }

        return object
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard
            context == &mediaUploadingProgressObserverContext,
            keyPath == #keyPath(Progress.fractionCompleted)
            else {
                super.observeValue(forKeyPath: keyPath,
                                   of: object,
                                   change: change,
                                   context: context)
                return
        }

        DispatchQueue.main.async {
            self.refreshMediaProgress()
        }
    }

    func refreshMediaProgress() {
        var value = Float(0)
        if let progress = mediaUploadingProgress {
            // make sure the progress value reflects the number of upload finished 100%
            let fractionOfUploadsCompleted = Float(Float((progress.completedUnitCount + 1))/Float(progress.totalUnitCount))
            value = min(fractionOfUploadsCompleted, Float(progress.fractionCompleted))
        }
        delegate?.mediaProgressCoordinator(self, progressDidChange: value)
    }

    var isRunning: Bool {
        guard let progress = mediaUploadingProgress else {
            return false
        }

        if progress.isCancelled {
            return false
        }

        if mediaUploading.isEmpty {
            return progress.totalUnitCount != progress.completedUnitCount
        }

        for progress in mediaUploading.values {
            if !progress.isCancelled && (progress.totalUnitCount != progress.completedUnitCount) {
                return true
            }
        }
        return false
    }

    // TODO: Implement this method to return true if there is failed media.
    //       This may not be the right place for the bool.
    var hasFailedMedia: Bool {
        return false
    }
}
