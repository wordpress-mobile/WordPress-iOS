import Foundation
import UIKit
import MobileCoreServices
import CoreData
import Aztec
import Gridicons
import WordPressShared
import WordPressKit

class ShareExtensionViewController: UIViewController {

    // MARK: - Private Properties

    /// WordPress.com Username
    ///
    fileprivate lazy var wpcomUsername: String? = {
        ShareExtensionService.retrieveShareExtensionUsername()
    }()

    /// WordPress.com OAuth Token
    ///
    fileprivate lazy var oauth2Token: String? = {
        ShareExtensionService.retrieveShareExtensionToken()
    }()

    /// Selected Site's ID
    ///
    fileprivate lazy var selectedSiteID: Int? = {
        69078016
        // FIXME: Uncomment this!
        //ShareExtensionService.retrieveShareExtensionDefaultSite()?.siteID
    }()

    /// Selected Site's Name
    ///
    fileprivate lazy var selectedSiteName: String? = {
        ShareExtensionService.retrieveShareExtensionDefaultSite()?.siteName
    }()

    /// Maximum Image Size
    ///
    fileprivate lazy var maximumImageSize: CGSize = {
        let dimension = ShareExtensionService.retrieveShareExtensionMaximumMediaDimension() ?? Constants.defaultMaxDimension
        return CGSize(width: dimension, height: dimension)
    }()

    /// Tracks Instance
    ///
    fileprivate lazy var tracks: Tracks = {
        Tracks(appGroupName: WPAppGroupName)
    }()

    /// Next Bar Button
    ///
    fileprivate lazy var nextButton: UIBarButtonItem = {
        let nextTitle = NSLocalizedString("Post!", comment: "Post action on share extension editor screen")
        return UIBarButtonItem(title: nextTitle, style: .plain, target: self, action: #selector(nextWasPressed))
    }()

    /// Cancel Bar Button
    ///
    fileprivate lazy var cancelButton: UIBarButtonItem = {
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel action on share extension editor screen")
        return UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelWasPressed))
    }()

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

        let textView = Aztec.TextView(defaultFont: ShareFonts.regular, defaultParagraphStyle: paragraphStyle, defaultMissingImage: Assets.defaultMissingImage)

        textView.inputProcessor = PipelineProcessor([CalypsoProcessorIn()])

        textView.outputProcessor = PipelineProcessor([CalypsoProcessorOut()])

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        let linkAttributes: [NSAttributedStringKey: Any] = [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
                                                            .foregroundColor: ShareColors.aztecLinkColor]

        textView.delegate = self
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self
        textView.backgroundColor = ShareColors.aztecBackground
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
        label.textColor = ShareColors.placeholder
        label.font = ShareFonts.regular
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .natural
        return label
    }()

    /// Title's UITextView
    ///
    fileprivate(set) lazy var titleTextField: UITextView = {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .natural

        let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: UIColor.darkText,
                                                        .font: ShareFonts.title,
                                                        .paragraphStyle: titleParagraphStyle]

        let textView = UITextView()

        textView.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        textView.delegate = self
        textView.font = ShareFonts.title
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

        let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: ShareColors.title, .font: ShareFonts.title]

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

    /// Current keyboard rect used to help size the inline media picker
    ///
    fileprivate var currentKeyboardFrame: CGRect = .zero

    /// Separator View
    ///
    fileprivate(set) lazy var separatorView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))

        v.backgroundColor = ShareColors.separator
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()

    /// Selected Text Attachment
    ///
    fileprivate var currentSelectedAttachment: MediaAttachment?

    fileprivate var mediaMessageAttributes: [NSAttributedStringKey: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        return [.font: ShareFonts.mediaOverlay,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white]
    }

    /// Options
    ///
    fileprivate var optionsViewController: OptionsTableViewController!

    /// Dictionary of images and attachments
    ///
    fileprivate var sharedImageDict = [String: URL]()

    /// Post's Status
    ///
    fileprivate var postStatus = "publish"

    /// Unique identifier for background sessions
    ///
    fileprivate lazy var backgroundSessionIdentifier: String = {
        let identifier = WPAppGroupName + "." + UUID().uuidString
        return identifier
    }()

    /// Unique identifier a group of upload operations
    ///
    fileprivate lazy var groupIdentifier: String = {
        let groupIdentifier = UUID().uuidString
        return groupIdentifier
    }()

    /// Core Data stack for application extensions
    ///
    fileprivate lazy var coreDataStack = SharedCoreDataStack()
    fileprivate var managedContext: NSManagedObjectContext!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // This needs to called first
        configureMediaAppearance()

        // Tracker
        tracks.wpcomUsername = wpcomUsername
        title = NSLocalizedString("WordPress", comment: "Application title")

        // Core Data
        managedContext = coreDataStack.managedContext

        // Grab the content from the host app
        loadContent(extensionContext: extensionContext)

        // Setup
        WPFontManager.loadNotoFontFamily()
        configureNavigationBar()
        configureView()
        configureSubviews()

        // Setup Autolayout
        view.setNeedsUpdateConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tracks.trackExtensionLaunched(oauth2Token != nil)
        dismissIfNeeded()
        startListeningToNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        coreDataStack.saveContext()
        stopListeningToNotifications()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var safeInsets = self.view.layoutMargins
        safeInsets.top = richTextView.textContainerInset.top
        richTextView.textContainerInset = safeInsets
    }

    // MARK: - Title and Title placeholder position methods

    func refreshTitlePosition() {
        let referenceView: UITextView = richTextView
        titleTopConstraint.constant = -(referenceView.contentOffset.y+referenceView.contentInset.top)

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset

        textPlaceholderTopConstraint.constant = referenceView.textContainerInset.top + referenceView.contentInset.top
    }

    func updateTitleHeight() {
        let referenceView: UITextView = richTextView
        let layoutMargins = view.layoutMargins
        let insets = titleTextField.textContainerInset

        var titleWidth = titleTextField.bounds.width
        if titleWidth <= 0 {
            // Use the title text field's width if available, otherwise calculate it.
            // View's frame minus left and right margins
            titleWidth = view.frame.width - (insets.left + insets.right + layoutMargins.left + layoutMargins.right)
        }

        let sizeThatShouldFitTheContent = titleTextField.sizeThatFits(CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude))
        titleHeightConstraint.constant = max(sizeThatShouldFitTheContent.height, titleTextField.font!.lineHeight + insets.top + insets.bottom)

        textPlaceholderTopConstraint.constant = referenceView.textContainerInset.top + referenceView.contentInset.top

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset
        referenceView.setContentOffset(CGPoint(x: 0, y: -contentInset.top), animated: false)
    }

    /// Sanitizes an input for insertion in the title text view.
    ///
    /// - Parameters:
    ///     - input: the input for the title text view.
    ///
    /// - Returns: the sanitized string
    ///
    func sanitizeInputForTitle(_ input: String) -> String {
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
    func shouldChangeTitleText(in range: NSRange, replacementText text: String) -> Bool {

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

    func setTitleText(_ text: String) {
        let sanitizedInput = sanitizeInputForTitle(text)
        titleTextField.insertText(sanitizedInput)
    }

    // MARK: - Configuration Methods

    func configureNavigationBar() {
        title = NSLocalizedString("Share to WordPress", comment: "Title for Share Exte nsion")
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton
    }

    func configureMediaAppearance() {
        MediaAttachment.defaultAppearance.overlayColor = ShareColors.mediaProgressOverlay
        MediaAttachment.defaultAppearance.overlayBorderWidth = Constants.mediaOverlayBorderWidth
        MediaAttachment.defaultAppearance.overlayBorderColor = ShareColors.mediaOverlayBorderColor
    }

    func configureView() {
        edgesForExtendedLayout = UIRectEdge()
        view.backgroundColor = .white
    }

    func configureSubviews() {
        view.addSubview(richTextView)
        view.addSubview(titleTextField)
        view.addSubview(titlePlaceholderLabel)
        view.addSubview(separatorView)
        view.addSubview(placeholderLabel)
    }

    override func updateViewConstraints() {

        super.updateViewConstraints()

        titleHeightConstraint = titleTextField.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
        titleTopConstraint = titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: -richTextView.contentOffset.y)
        textPlaceholderTopConstraint = placeholderLabel.topAnchor.constraint(equalTo: richTextView.topAnchor, constant: richTextView.textContainerInset.top + richTextView.contentInset.top)
        updateTitleHeight()
        let layoutGuide = view.layoutMarginsGuide

        NSLayoutConstraint.activate([
            titleTextField.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            titleTextField.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
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

    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidHide), name: .UIKeyboardDidHide, object: nil)
    }

    func stopListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        nc.removeObserver(self, name: .UIKeyboardDidHide, object: nil)
    }

    // MARK: - Toolbar creation

    fileprivate func updateToolbar(_ toolbar: Aztec.FormatBar) {
        toolbar.setDefaultItems(scrollableItemsForToolbar,
                                overflowItems: overflowItemsForToolbar)
    }

    func makeToolbarButton(identifier: FormattingIdentifier) -> FormatBarItem {
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

        toolbar.tintColor = ShareColors.aztecFormatBarInactiveColor
        toolbar.highlightedTintColor = ShareColors.aztecFormatBarActiveColor
        toolbar.selectedTintColor = ShareColors.aztecFormatBarActiveColor
        toolbar.disabledTintColor = ShareColors.aztecFormatBarDisabledColor
        toolbar.dividerTintColor = ShareColors.aztecFormatBarDividerColor
        toolbar.overflowToggleIcon = Gridicon.iconOfType(.ellipsis)
        toolbar.overflowToolbar(expand: false)
        updateToolbar(toolbar)

        toolbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: Constants.toolbarHeight)
        toolbar.formatter = self
        toolbar.barItemHandler = { [weak self] item in
            self?.handleAction(for: item)
        }
        return toolbar
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
        ]
    }
}

// MARK: - Format Bar Updating

extension ShareExtensionViewController {

    func updateFormatBar() {
        updateFormatBarForVisualMode()
    }

    /// Updates the format bar for visual mode.
    ///
    private func updateFormatBarForVisualMode() {
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

// MARK: - FormatBar Actions

extension ShareExtensionViewController {
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
            case .p, .header1, .header2, .header3, .header4, .header5, .header6:
                toggleHeader(fromItem: barItem)
            case .horizontalruler:
                insertHorizontalRuler()
            case .more:
                break // Not used here
            case .media:
                break  // Not used here
            case .sourcecode:
                break // Not used here
            }

            updateFormatBar()
        }
    }

    @objc func toggleBold() {
        richTextView.toggleBold(range: richTextView.selectedRange)
    }

    @objc func toggleItalic() {
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }

    @objc func toggleUnderline() {
        richTextView.toggleUnderline(range: richTextView.selectedRange)
    }

    @objc func toggleStrikethrough() {
        richTextView.toggleStrikethrough(range: richTextView.selectedRange)
    }

    @objc func toggleOrderedList() {
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }

    @objc func toggleUnorderedList() {
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
                                action: #selector(ShareExtensionViewController.alertTextFieldDidChange),
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

    func toggleHeader(fromItem item: FormatBarItem) {
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
                                                    self?.richTextView.toggleHeader(Constants.headers[selected], range: range)
                                                    self?.optionsViewController = nil
                                                    self?.changeRichTextInputView(to: nil)
        })
    }

    func insertHorizontalRuler() {
        richTextView.replaceWithHorizontalRuler(at: richTextView.selectedRange)
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
        optionsViewController.cellDeselectedTintColor = ShareColors.aztecFormatBarInactiveColor
        optionsViewController.cellBackgroundColor = ShareColors.aztecFormatPickerBackgroundColor
        optionsViewController.cellSelectedBackgroundColor = ShareColors.aztecFormatPickerSelectedCellBackgroundColor
        optionsViewController.view.tintColor = ShareColors.aztecFormatBarActiveColor
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
        optionsViewController.popoverPresentationController?.backgroundColor = ShareColors.aztecFormatPickerBackgroundColor
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
}

// MARK: - Media Action Sheet

extension ShareExtensionViewController {

    @objc func cancelWasPressed() {
        tracks.trackExtensionCancelled()
        closeShareExtensionWithoutSaving()
    }

    @objc func nextWasPressed() {
        // TODO: Next screen eventually!
        savePostToRemoteSite()
    }

    func displayActions(forAttachment attachment: MediaAttachment, position: CGPoint) {
        let mediaID = attachment.identifier
        let title: String = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
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
        if attachment is ImageAttachment {
            alertController.addActionWithTitle(NSLocalizedString("Remove", comment: "User action to remove media."),
                                               style: .destructive,
                                               handler: { (action) in
                                                self.richTextView.remove(attachmentID: mediaID)
            })
        }

        alertController.title = title
        alertController.message = nil
        alertController.popoverPresentationController?.sourceView = richTextView
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: position, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated: true, completion: { () in
            UIMenuController.shared.setMenuVisible(false, animated: false)
        })
    }
}

// MARK: - Media Helpers

extension ShareExtensionViewController {
    func resetMediaAttachmentOverlay(_ mediaAttachment: MediaAttachment) {
        if mediaAttachment is ImageAttachment {
            mediaAttachment.overlayImage = nil
        }
        mediaAttachment.message = nil
        mediaAttachment.shouldHideBorder = false
    }

    func insertImageAttachment(with url: URL) {
        let attachment = richTextView.replaceWithImage(at: self.richTextView.selectedRange, sourceURL: url, placeHolderImage: Assets.defaultMissingImage)

        attachment.size = .full
        attachment.uploadID = url.lastPathComponent // Use the filename as the uploadID here.
        richTextView.refresh(attachment)
        sharedImageDict[attachment.identifier] = url
    }

    func saveImageToSharedContainer(_ image: UIImage) -> URL? {
        guard let encodedMedia = image.resizeWithMaximumSize(maximumImageSize).JPEGEncoded(),
            let mediaDirectory = ShareMediaFileManager.shared.mediaUploadDirectoryURL else {
                return nil
        }

        let uniqueString = "image_\(NSDate.timeIntervalSinceReferenceDate)"
        let fileName = uniqueString.components(separatedBy: ["."]).joined() + ".jpg"
        let fullPath = mediaDirectory.appendingPathComponent(fileName)
        do {
            try encodedMedia.write(to: fullPath, options: [.atomic])
        } catch {
            DDLogError("Error saving \(fullPath) to shared container: \(String(describing: error))")
            return nil
        }
        return fullPath
    }
}

// MARK: - FormatBarDelegate Conformance

extension ShareExtensionViewController: Aztec.FormatBarDelegate {
    func formatBarTouchesBegan(_ formatBar: FormatBar) {
        dismissOptionsViewControllerIfNecessary()
    }

    func formatBar(_ formatBar: FormatBar, didChangeOverflowState overflowState: FormatBarOverflowState) {
        // Not Used
    }
}

// MARK: - UIPopoverPresentationControllerDelegate Conformance

extension ShareExtensionViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        if optionsViewController != nil {
            optionsViewController = nil
        }
    }
}

// MARK: - UITextViewDelegate Conformance

extension ShareExtensionViewController: UITextViewDelegate {

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

    func refreshPlaceholderVisibility() {
        placeholderLabel.isHidden = richTextView.isHidden || !richTextView.text.isEmpty
        titlePlaceholderLabel.isHidden = !titleTextField.text.isEmpty
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.textAlignment = .natural

        switch textView {
        case titleTextField:
            formatBar.enabled = false
        case richTextView:
            formatBar.enabled = true
        default:
            break
        }
        textView.inputAccessoryView = formatBar

        return true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshTitlePosition()
    }
}

// MARK: - UITextFieldDelegate Conformance

extension ShareExtensionViewController {
    func titleTextFieldDidChange(_ textField: UITextField) {
        // noop
    }
}

// MARK: - TextViewFormattingDelegate Conformance

extension ShareExtensionViewController: Aztec.TextViewFormattingDelegate {
    func textViewCommandToggledAStyle() {
        updateFormatBar()
    }
}

// MARK: - TextViewAttachmentDelegate Conformance

extension ShareExtensionViewController: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        guard let image = UIImage(contentsOfURL: url) else {
            failure()
            return
        }
        success(image)
    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return nil
    }

    func textView(_ textView: TextView, deletedAttachmentWith attachmentID: String) {
        // Remove the temp media file associated with the deleted attachment
        guard let tempMediaFileURL = sharedImageDict[attachmentID], !tempMediaFileURL.pathExtension.isEmpty else {
            return
        }
        ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: tempMediaFileURL.lastPathComponent)
        sharedImageDict.removeValue(forKey: attachmentID)
    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        if !richTextView.isFirstResponder {
            richTextView.becomeFirstResponder()
        }

        switch attachment {
        case let attachment as MediaAttachment:
            selected(textAttachment: attachment, atPosition: position)
        default:
            break
        }
    }

    func selected(textAttachment attachment: MediaAttachment, atPosition position: CGPoint) {
        // If it's a new attachment tapped let's unmark the previous one...
        if let selectedAttachment = currentSelectedAttachment {
            self.resetMediaAttachmentOverlay(selectedAttachment)
            richTextView.refresh(selectedAttachment)
        }

        // ...and mark the newly tapped attachment
        let message = ""
        attachment.message = NSAttributedString(string: message, attributes: mediaMessageAttributes)
        attachment.shouldHideBorder = false
        richTextView.refresh(attachment)
        currentSelectedAttachment = attachment

        // Display the action sheet right away
        displayActions(forAttachment: attachment, position: position)
    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        currentSelectedAttachment = nil
        if let mediaAttachment = attachment as? MediaAttachment {
            self.resetMediaAttachmentOverlay(mediaAttachment)
            richTextView.refresh(mediaAttachment)
        }
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return Gridicon.iconOfType(.image, withSize: Constants.mediaPlaceholderImageSize)
    }
}

// MARK: - Backend Interaction

private extension ShareExtensionViewController {
    func combinePostWithMediaAndUpload(forPostUploadOpWithObjectID uploadPostOpID: NSManagedObjectID) {
        guard let postUploadOp = coreDataStack.fetchPostUploadOp(withObjectID: uploadPostOpID),
            let groupID = postUploadOp.groupID,
            let mediaUploadOps = coreDataStack.fetchMediaUploadOps(for: groupID) else {
                return
        }

        mediaUploadOps.forEach { mediaUploadOp in
            guard let fileName = mediaUploadOp.fileName,
                let remoteURL = mediaUploadOp.remoteURL else {
                return
            }

            let imgPostUploadProcessor = ImgUploadProcessor(mediaUploadID: fileName,
                                                            remoteURLString: remoteURL,
                                                            width: Int(mediaUploadOp.width),
                                                            height: Int(mediaUploadOp.height))
            let content = postUploadOp.postContent ?? ""
            postUploadOp.postContent = imgPostUploadProcessor.process(content)
        }

        coreDataStack.saveContext()

        self.uploadPost(forUploadOpWithObjectID: uploadPostOpID, requestEnqueued: {})
    }

    func uploadPost(forUploadOpWithObjectID uploadOpObjectID: NSManagedObjectID, requestEnqueued: @escaping () -> ()) {
        guard let postUploadOp = coreDataStack.fetchPostUploadOp(withObjectID: uploadOpObjectID) else {
            DDLogError("Error uploading post in share extension — could not fetch saved post.")
            requestEnqueued()
            return
        }

        let remotePost = postUploadOp.remotePost

        // 15-Nov-2017: Creating a post without media on the PostServiceRemoteREST does not use background uploads so set it false
        let api = WordPressComRestApi(oAuthToken: oauth2Token,
                                      userAgent: nil,
                                      backgroundUploads: false,
                                      backgroundSessionIdentifier: backgroundSessionIdentifier,
                                      sharedContainerIdentifier: WPAppGroupName)
        let remote = PostServiceRemoteREST(wordPressComRestApi: api, siteID: NSNumber(value: postUploadOp.siteID))
        remote.createPost(remotePost, success: { post in
            if let post = post {
                DDLogInfo("Post \(post.postID.stringValue) sucessfully uploaded to site \(post.siteID.stringValue)")
                if let postID = post.postID {
                    self.coreDataStack.updatePostOperation(with: .complete, remotePostID: postID.int64Value, forPostUploadOpWithObjectID: uploadOpObjectID)
                } else {
                    self.coreDataStack.updateStatus(.complete, forUploadOpWithObjectID: uploadOpObjectID)
                }
            }
            requestEnqueued()
        }, failure: { error in
            var errorString = "Error creating post in share extension"
            if let error = error as NSError? {
                errorString += ": \(error.localizedDescription)"
            }
            DDLogError(errorString)
            self.coreDataStack.updateStatus(.error, forUploadOpWithObjectID: uploadOpObjectID)
            requestEnqueued()
        })
    }

    func uploadPostWithMedia(subject: String, body: String, status: String, siteID: Int, requestEnqueued: @escaping () -> ()) {
        let tempMediaFileURLs = sharedImageDict.values
        guard tempMediaFileURLs.count > 0 else {
                DDLogError("No media is attached to this upload request.")
                requestEnqueued()
                return
        }

        // First create the post upload op
        let remotePost: RemotePost = {
            let post = RemotePost()
            post.siteID = NSNumber(value: siteID)
            post.status = status
            post.title = subject
            post.content = body
            return post
        }()
        let uploadPostOpID = coreDataStack.savePostOperation(remotePost, groupIdentifier: groupIdentifier, with: .pending)

        // Now process all of the media items and create their upload ops
        var uploadMediaOpIDs = [NSManagedObjectID]()
        var allRemoteMedia = [RemoteMedia]()
        tempMediaFileURLs.forEach { tempFilePath in
            let remoteMedia = RemoteMedia()
            remoteMedia.file = tempFilePath.lastPathComponent
            remoteMedia.mimeType = Constants.mimeType
            remoteMedia.localURL = tempFilePath
            allRemoteMedia.append(remoteMedia)

            let uploadMediaOpID = coreDataStack.saveMediaOperation(remoteMedia,
                                                                   sessionID: backgroundSessionIdentifier,
                                                                   groupIdentifier: groupIdentifier,
                                                                   siteID: NSNumber(value: siteID),
                                                                   with: .pending)
            uploadMediaOpIDs.append(uploadMediaOpID)
        }

        // Upload the media items
        let api = WordPressComRestApi(oAuthToken: oauth2Token,
                                      userAgent: nil,
                                      backgroundUploads: true,
                                      backgroundSessionIdentifier: backgroundSessionIdentifier,
                                      sharedContainerIdentifier: WPAppGroupName)

        // NOTE: The success and error closures **may** get called here - it’s non-deterministic as to whether WPiOS
        // or the extension gets the "did complete" callback. So unfortunatly, we need to have the logic to complete
        // post share here as well as WPiOS.
        let remote = MediaServiceRemoteREST(wordPressComRestApi: api, siteID: NSNumber(value: siteID))
        remote.uploadMedia(allRemoteMedia, requestEnqueued: { taskID in
            uploadMediaOpIDs.forEach({ uploadMediaOpID in
                self.coreDataStack.updateStatus(.inProgress, forUploadOpWithObjectID: uploadMediaOpID)
                if let taskID = taskID {
                    self.coreDataStack.updateTaskID(taskID, forUploadOpWithObjectID: uploadMediaOpID)
                }
            })
            requestEnqueued()
        }, success: { remoteMedia in
            guard let returnedMedia = remoteMedia as? [RemoteMedia],
                returnedMedia.count > 0,
                let mediaUploadOps = self.coreDataStack.fetchMediaUploadOps(for: self.groupIdentifier) else {
                    DDLogError("Error creating post in share extension. RemoteMedia info not returned from server.")
                    return
            }

            mediaUploadOps.forEach({ mediaUploadOp in
                returnedMedia.forEach({ remoteMedia in
                    if let remoteMediaID = remoteMedia.mediaID?.int64Value,
                        let remoteMediaURLString = remoteMedia.url?.absoluteString,
                        let localFileName = mediaUploadOp.fileName,
                        let remoteFileName = remoteMedia.file {

                        if localFileName.lowercased().trim() == remoteFileName.lowercased().trim() {
                            mediaUploadOp.remoteURL = remoteMediaURLString
                            mediaUploadOp.remoteMediaID = remoteMediaID
                            mediaUploadOp.currentStatus = .complete

                            if let width = remoteMedia.width?.int32Value,
                                let height = remoteMedia.width?.int32Value {
                                mediaUploadOp.width = width
                                mediaUploadOp.height = height
                            }

                            ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: localFileName)
                        }
                    }
                })
            })
            self.coreDataStack.saveContext()

            // Now upload the post
            self.combinePostWithMediaAndUpload(forPostUploadOpWithObjectID: uploadPostOpID)
        }) { error in
            guard let error = error as NSError? else {
                return
            }
            DDLogError("Error creating post in share extension: \(error.localizedDescription)")
            uploadMediaOpIDs.forEach({ uploadMediaOpID in
                self.coreDataStack.updateStatus(.error, forUploadOpWithObjectID: uploadMediaOpID)
            })
            self.tracks.trackExtensionError(error)
        }
    }
}

// MARK: - Private Keyboard Helpers

private extension ShareExtensionViewController {
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

    func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        let referenceView: UIScrollView = richTextView
        let scrollInsets = UIEdgeInsets(top: referenceView.scrollIndicatorInsets.top, left: 0, bottom: view.frame.maxY - (keyboardFrame.minY + self.view.layoutMargins.bottom), right: 0)
        let contentInsets  = UIEdgeInsets(top: referenceView.contentInset.top, left: 0, bottom: view.frame.maxY - (keyboardFrame.minY + self.view.layoutMargins.bottom), right: 0)

        richTextView.scrollIndicatorInsets = scrollInsets
        richTextView.contentInset = contentInsets
    }
}

// MARK: - Misc Private helpers

private extension ShareExtensionViewController {
    func loadContent(extensionContext: NSExtensionContext?) {
        guard let extensionContext = extensionContext else {
            return
        }
        ShareExtractor(extensionContext: extensionContext)
            .loadShare { [weak self] share in
                self?.setTitleText(share.title)
                self?.richTextView.insertText(share.combinedContentFields)

                share.images.forEach({ image in
                    if let fileURL = self?.saveImageToSharedContainer(image) {
                        self?.insertImageAttachment(with: fileURL)
                    }
                })
        }
    }

    func dismissIfNeeded() {
        guard oauth2Token == nil else {
            return
        }

        let title = NSLocalizedString("No WordPress.com Account", comment: "Extension Missing Token Alert Title")
        let message = NSLocalizedString("Launch the WordPress app and log into your WordPress.com or Jetpack site to share.", comment: "Extension Missing Token Alert Title")
        let accept = NSLocalizedString("Cancel Share", comment: "Dismiss Extension and cancel Share OP")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: accept, style: .default) { (action) in
            self.closeShareExtensionWithoutSaving()
        }

        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }

    func closeShareExtensionWithoutSaving() {
        // First, remove the temp media files if needed
        for tempMediaFileURL in sharedImageDict.values {
            if !tempMediaFileURL.pathExtension.isEmpty {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: tempMediaFileURL.lastPathComponent)
            }
        }

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    func savePostToRemoteSite() {
        guard let _ = oauth2Token, let siteID = selectedSiteID else {
            fatalError("The view should have been dismissed on viewDidAppear!")
        }

        // FIXME: Save the last used site
        //        if let siteName = selectedSiteName {
        //            ShareExtensionService.configureShareExtensionLastUsedSiteID(siteID, lastUsedSiteName: siteName)
        //        }

        // Proceed uploading the actual post
        let subject = titleTextField.text ?? ""
        let body = richTextView.getHTML()

        if sharedImageDict.values.count > 0 {
            uploadPostWithMedia(subject: subject,
                                body: body,
                                status: postStatus,
                                siteID: siteID,
                                requestEnqueued: {
                                    self.tracks.trackExtensionPosted(self.postStatus)
                                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        } else {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.siteID = NSNumber(value: siteID)
                post.status = postStatus
                post.title = subject
                post.content = body
                return post
            }()
            let uploadPostOpID = coreDataStack.savePostOperation(remotePost, groupIdentifier: groupIdentifier, with: .inProgress)
            uploadPost(forUploadOpWithObjectID: uploadPostOpID, requestEnqueued: {
                self.tracks.trackExtensionPosted(self.postStatus)
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        }
    }
}

// MARK: - Constants

fileprivate extension ShareExtensionViewController {

    struct Assets {
        static let defaultMissingImage          = Gridicon.iconOfType(.image)
    }

    struct Constants {
        static let defaultMargin                = CGFloat(20)
        static let cancelButtonPadding          = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        static let moreAttachmentText           = "more"
        static let placeholderPadding           = UIEdgeInsets(top: 8, left: 5, bottom: 0, right: 0)
        static let headers                      = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let lists                        = [TextList.Style.unordered, .ordered]
        static let toolbarHeight                = CGFloat(44.0)
        static let mediaOverlayBorderWidth      = CGFloat(3.0)
        static let mediaPlaceholderImageSize    = CGSize(width: 128, height: 128)
        static let placeholderMediaLink         = URL(string: "placeholder://")!
        static let defaultMaxDimension          = 3000
        static let mimeType                     = "image/jpeg"

        static let postStatuses = [
            "draft": NSLocalizedString("Draft", comment: "Draft post status"),
            "publish": NSLocalizedString("Publish", comment: "Publish post status")
        ]
    }

    struct ShareColors {
        static let title                                = WPStyleGuide.grey()
        static let separator                            = WPStyleGuide.greyLighten30()
        static let placeholder                          = WPStyleGuide.grey()
        static let mediaProgressOverlay                 = WPStyleGuide.darkGrey().withAlphaComponent(CGFloat(0.6))
        static let mediaOverlayBorderColor              = WPStyleGuide.wordPressBlue()
        static let aztecBackground                      = UIColor.clear
        static let aztecLinkColor                       = WPStyleGuide.mediumBlue()
        static let aztecFormatBarDisabledColor          = WPStyleGuide.greyLighten20()
        static let aztecFormatBarDividerColor           = WPStyleGuide.greyLighten30()
        static let aztecFormatBarBackgroundColor        = UIColor.white
        static let aztecFormatBarInactiveColor: UIColor = UIColor(hexString: "7B9AB1")
        static let aztecFormatBarActiveColor: UIColor   = UIColor(hexString: "11181D")

        static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
            get {
                return (UIDevice.current.userInterfaceIdiom == .pad) ? WPStyleGuide.lightGrey() : WPStyleGuide.greyLighten30()
            }
        }

        static var aztecFormatPickerBackgroundColor: UIColor {
            get {
                return (UIDevice.current.userInterfaceIdiom == .pad) ? .white : WPStyleGuide.lightGrey()
            }
        }
    }

    struct ShareFonts {
        static let regular      = WPFontManager.notoRegularFont(ofSize: 16)
        static let title        = WPFontManager.notoBoldFont(ofSize: 24.0)
        static let mediaOverlay = WPFontManager.systemSemiBoldFont(ofSize: 15.0)
    }
}
