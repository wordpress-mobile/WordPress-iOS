import UIKit
import Aztec
import WordPressEditor
import Gridicons
import WordPressUI
import WordPressShared

class ShareExtensionEditorViewController: ShareExtensionAbstractViewController {

    // MARK: - Private Properties

    /// Cancel Bar Button
    ///
    fileprivate lazy var cancelButton: UIBarButtonItem = {
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel action on share extension editor screen.")
        let button = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelWasPressed))
        button.accessibilityIdentifier = "Cancel Button"
        return button
    }()

    /// Next Bar Button
    ///
    fileprivate lazy var nextButton: UIBarButtonItem = {
        let nextButtonTitle = NSLocalizedString("Next", comment: "Next action on share extension editor screen.")
        let button = UIBarButtonItem(title: nextButtonTitle, style: .plain, target: self, action: #selector(nextWasPressed))
        button.accessibilityIdentifier = "Next Button"
        return button
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

        textView.load(WordPressPlugin())

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        let linkAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                            .foregroundColor: ShareColors.aztecLinkColor]

        textView.delegate = self
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self
        textView.backgroundColor = ShareColors.aztecBackground
        textView.textColor = .text
        textView.tintColor = ShareColors.aztecCursorColor
        textView.blockquoteBackgroundColor = UIColor(light: textView.blockquoteBackgroundColor, dark: .neutral(.shade5))
        textView.blockquoteBorderColor = .listIcon
        textView.linkTextAttributes = linkAttributes
        textView.textAlignment = .natural

        textView.smartDashesType = .no
        textView.smartQuotesType = .no

        return textView
    }()

    /// Aztec's Text Placeholder
    ///
    fileprivate(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Share your story here...", comment: "Share Extension Content Body Text Placeholder")
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

        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.text,
                                                        .font: ShareFonts.title,
                                                        .paragraphStyle: titleParagraphStyle]

        let textView = UITextView()

        textView.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        textView.delegate = self
        textView.font = ShareFonts.title
        textView.returnKeyType = .next
        textView.textColor = .text
        textView.typingAttributes = attributes
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .natural
        textView.isScrollEnabled = false
        textView.tintColor = ShareColors.aztecCursorColor
        textView.backgroundColor = ShareColors.aztecBackground
        textView.spellCheckingType = .default

        return textView
    }()

    /// Placeholder Label
    ///
    fileprivate(set) lazy var titlePlaceholderLabel: UILabel = {
        let placeholderText = NSLocalizedString("Title", comment: "Placeholder for the post title.")
        let titlePlaceholderLabel = UILabel()

        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: ShareColors.title, .font: ShareFonts.title]

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

    /// Current keyboard rect used to help size things
    ///
    fileprivate var currentKeyboardFrame: CGRect = .zero

    /// Original size of keyboard frame *prior to* the options VC displaying
    ///
    fileprivate var originalKeyboardFrame: CGRect = .zero

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

    fileprivate var mediaMessageAttributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        return [.font: ShareFonts.mediaOverlay,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white]
    }

    /// Options
    ///
    fileprivate var optionsViewController: OptionsTableViewController!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // This needs to called first
        configureMediaAppearance()

        // Setup
        WPFontManager.loadNotoFontFamily()
        configureNavigationBar()
        configureView()
        configureSubviews()

        // Setup Autolayout
        view.setNeedsUpdateConstraints()

        // Load everything into the editor from the host app
        loadContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        verifyAuthCredentials {
            self.startListeningToNotifications()
            self.makeRichTextViewFirstResponderAndPlaceCursorAtEnd()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToNotifications()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.updateTitleHeight()
            self.stopEditing()
        })
        dismissOptionsViewControllerIfNecessary()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var safeInsets = self.view.layoutMargins
        safeInsets.top = richTextView.textContainerInset.top
        richTextView.textContainerInset = safeInsets
    }

    /// Manages data transfer when seguing to a new VC
    ///
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let source = segue.source as? ShareExtensionEditorViewController else {
            return
        }

        if let destination = segue.destination as? ShareModularViewController {
            destination.dismissalCompletionBlock = source.dismissalCompletionBlock
            destination.sites = source.sites
            destination.shareData = source.shareData
            destination.originatingExtension = source.originatingExtension
        }
    }

    // MARK: - Title and Title placeholder position methods

    func refreshTitlePosition() {
        let referenceView: UITextView = richTextView
        titleTopConstraint.constant = -(referenceView.contentOffset.y+referenceView.contentInset.top)

        updateContentInset(for: referenceView)

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

        updateContentInset(for: referenceView)

        referenceView.setContentOffset(CGPoint(x: 0, y: -referenceView.contentInset.top), animated: false)
    }

    private func updateContentInset(for referenceView: UITextView) {
        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        contentInset.bottom = Constants.editorBottomInset
        referenceView.contentInset = contentInset
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
        view.backgroundColor = .basicBackground
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
        textView.keyboardDismissMode = .none
        textView.textColor = UIColor.darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
    }

    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(keyboardWillShow),
                       name: UIResponder.keyboardWillShowNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(keyboardDidHide),
                       name: UIResponder.keyboardDidHideNotification,
                       object: nil)
    }

    func stopListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
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

        toolbar.backgroundColor = .filterBarBackground
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

extension ShareExtensionEditorViewController {
    func updateFormatBar() {
        updateFormatBarForVisualMode()
    }

    /// Updates the format bar for visual mode.
    ///
    private func updateFormatBarForVisualMode() {
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
}

// MARK: - FormatBar Actions

extension ShareExtensionEditorViewController {
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
            case .code:
                toggleCode()
            default:
                break
            }

            updateFormatBar()
        }
    }

    @objc func toggleBold() {
        richTextView.toggleBold(range: richTextView.selectedRange)
    }

    @objc func toggleCode() {
        richTextView.toggleCode(range: richTextView.selectedRange)
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
                                action: #selector(ShareExtensionEditorViewController.alertTextFieldDidChange),
                                for: UIControl.Event.editingChanged)
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

        present(alertController, animated: true)
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
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: CGFloat(headerType.fontSize)),
                .foregroundColor: UIColor.neutral(.shade70)
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
                                                   onSelect: OptionsTablePresenter.OnSelectHandler?) {
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
        if currentKeyboardFrame.height > originalKeyboardFrame.height {
            originalKeyboardFrame = currentKeyboardFrame
        }
        self.addChild(viewController)
        changeRichTextInputView(to: viewController.view)
        viewController.didMove(toParent: self)
    }

    private func dismissOptionsViewController() {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            dismiss(animated: true)
        default:
            optionsViewController?.removeFromParent()
            changeRichTextInputView(to: nil)
            resetPresentationViewUsingKeyboardFrame(originalKeyboardFrame)
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

// MARK: - Actions

extension ShareExtensionEditorViewController {
    @objc func cancelWasPressed() {
        dismissOptionsViewControllerIfNecessary()
        stopEditing()
        tracks.trackExtensionCancelled()
        cleanUpSharedContainerAndCache()
        dismiss(animated: true, completion: self.dismissalCompletionBlock)
    }

    @objc func nextWasPressed() {
        dismissOptionsViewControllerIfNecessary()
        stopEditing()
        shareData.title = titleTextField.text ?? ""
        shareData.contentBody = richTextView.getHTML()
        performSegue(withIdentifier: .showModularSitePicker, sender: self)
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

extension ShareExtensionEditorViewController {
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
    }
}

// MARK: - FormatBarDelegate Conformance

extension ShareExtensionEditorViewController: Aztec.FormatBarDelegate {
    func formatBarTouchesBegan(_ formatBar: FormatBar) {
        dismissOptionsViewControllerIfNecessary()
    }

    func formatBar(_ formatBar: FormatBar, didChangeOverflowState overflowState: FormatBarOverflowState) {
        // Not Used
    }
}

// MARK: - UIPopoverPresentationControllerDelegate Conformance

extension ShareExtensionEditorViewController: UIPopoverPresentationControllerDelegate {
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

extension ShareExtensionEditorViewController: UITextViewDelegate {
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

extension ShareExtensionEditorViewController {
    func titleTextFieldDidChange(_ textField: UITextField) {
        // noop
    }
}

// MARK: - TextViewFormattingDelegate Conformance

extension ShareExtensionEditorViewController: Aztec.TextViewFormattingDelegate {
    func textViewCommandToggledAStyle() {
        updateFormatBar()
    }
}

// MARK: - TextViewAttachmentDelegate Conformance

extension ShareExtensionEditorViewController: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        guard let image = UIImage(contentsOfURL: url) else {
            failure()
            return
        }

        if let mediaAttachment = attachment as? MediaAttachment {
            shareData.sharedImageDict.updateValue(mediaAttachment.identifier, forKey: url)
        }
        success(image)
    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return nil
    }

    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
        // Remove the temp media file associated with the deleted attachment
        guard let keys = (shareData.sharedImageDict as NSDictionary).allKeys(for: attachment.identifier) as? [URL], !keys.isEmpty else {
            return
        }
        keys.forEach { tempMediaFileURL in
            if !tempMediaFileURL.pathExtension.isEmpty {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: tempMediaFileURL.lastPathComponent)
                shareData.sharedImageDict.removeValue(forKey: tempMediaFileURL)
            }
        }
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

// MARK: - Private Keyboard Helpers

private extension ShareExtensionEditorViewController {
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

    func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        let referenceView: UIScrollView = richTextView
        let bottomInset = (view.frame.maxY - (keyboardFrame.minY + self.view.layoutMargins.bottom) + Constants.insetBottomPadding)
        let scrollInsets = UIEdgeInsets(top: referenceView.scrollIndicatorInsets.top, left: 0, bottom: bottomInset, right: 0)
        let contentInsets  = UIEdgeInsets(top: referenceView.contentInset.top, left: 0, bottom: bottomInset, right: 0)

        richTextView.scrollIndicatorInsets = scrollInsets
        richTextView.contentInset = contentInsets
    }
}

// MARK: - Misc Private helpers

private extension ShareExtensionEditorViewController {
    func stopEditing() {
        view.endEditing(true)
        resetPresentationViewUsingKeyboardFrame()
        originalKeyboardFrame = .zero
    }

    func makeRichTextViewFirstResponderAndPlaceCursorAtEnd() {
        // Unfortunatly, we need set the first responder and cursor position in this manner otherwise
        // some odd scrolling behavior occurs when inserting images into the share ext editor.
        DispatchQueue.main.async {
            if !self.richTextView.isFirstResponder {
                self.richTextView.becomeFirstResponder()
            }
            let newPosition = self.richTextView.endOfDocument
            self.richTextView.selectedTextRange = self.richTextView.textRange(from: newPosition, to: newPosition)
        }
    }

    func resetPresentationViewUsingKeyboardFrame(_ keyboardFrame: CGRect = .zero) {
        guard let presentationController = navigationController?.presentationController as? ExtensionPresentationController else {
            return
        }

        presentationController.resetViewUsingKeyboardFrame(keyboardFrame)
    }

    func loadContent() {
        guard let extensionContext = context else {
            return
        }

        ShareExtractor(extensionContext: extensionContext)
            .loadShare { [weak self] share in
                self?.setTitleText(share.title)
                self?.richTextView.setHTML(share.combinedContentHTML)

                share.images.forEach({ extractedImage in
                    if extractedImage.insertionState == .requiresInsertion {
                        self?.insertImageAttachment(with: extractedImage.url)
                    } else {
                        self?.shareData.sharedImageDict.updateValue(UUID().uuidString, forKey: extractedImage.url)
                    }
                })

                // Lets an extra <p> at the bottom to make editing a little easier
                if let currentHTML = self?.richTextView.getHTML() {
                    self?.richTextView.setHTML(currentHTML + "<p></p>")
                }

                // Clear out the extension context after loading it once. We don't need it anymore.
                self?.context = nil
        }
    }
}

// MARK: - Constants

fileprivate extension ShareExtensionEditorViewController {
    struct Assets {
        static let defaultMissingImage          = Gridicon.iconOfType(.image)
    }

    struct Constants {
        static let placeholderPadding           = UIEdgeInsets(top: 8, left: 5, bottom: 0, right: 0)
        static let insetBottomPadding           = CGFloat(50.0)
        static let editorBottomInset            = CGFloat(18.0)
        static let headers                      = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let lists                        = [TextList.Style.unordered, .ordered]
        static let toolbarHeight                = CGFloat(44.0)
        static let mediaOverlayBorderWidth      = CGFloat(3.0)
        static let mediaPlaceholderImageSize    = CGSize(width: 128, height: 128)
    }

    struct ShareColors {
        static let title                          = UIColor.text
        static let separator                      = UIColor.divider
        static let placeholder                    = UIColor.textPlaceholder
        static let mediaProgressOverlay           = UIColor.neutral(.shade70).withAlphaComponent(CGFloat(0.6))
        static let mediaOverlayBorderColor        = UIColor.primary
        static let aztecBackground                = UIColor.basicBackground
        static let aztecLinkColor                 = UIColor.primary
        static let aztecFormatBarDisabledColor    = UIColor.neutral(.shade10)
        static let aztecFormatBarDividerColor     = UIColor.divider
        static let aztecCursorColor               = UIColor.primary
        static let aztecFormatBarBackgroundColor  = UIColor.basicBackground
        static let aztecFormatBarInactiveColor    = UIColor.toolbarInactive
        static let aztecFormatBarActiveColor      = UIColor.primary

        static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
            get {
                return (UIDevice.current.userInterfaceIdiom == .pad) ? .listBackground : .neutral(.shade5)
            }
        }

        static var aztecFormatPickerBackgroundColor: UIColor {
            get {
                return (UIDevice.current.userInterfaceIdiom == .pad) ? .white : .listBackground
            }
        }
    }

    struct ShareFonts {
        static let regular      = WPFontManager.notoRegularFont(ofSize: 16)
        static let title        = WPFontManager.notoBoldFont(ofSize: 24.0)
        static let mediaOverlay = WPFontManager.systemSemiBoldFont(ofSize: 15.0)
    }
}
