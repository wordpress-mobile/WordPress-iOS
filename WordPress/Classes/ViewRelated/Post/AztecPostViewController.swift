/*import Foundation
import UIKit
import Aztec
import Gridicons
import WordPressShared

class AztecPostViewController: UIViewController {
    func cancelEditingAction(_ sender: AnyObject) {
        cancelEditing()
    }
    var onClose: ((changesSaved: Bool) -> ())?

    static let margin = CGFloat(20)

    fileprivate(set) lazy var richTextView: Aztec.TextView = {
        let defaultFont = WPFontManager.merriweatherRegularFontOfSize(16)
        // TODO: Add a proper defaultMissingImage
        let defaultMissingImage = UIImage()
        let tv = Aztec.TextView(defaultFont: defaultFont, defaultMissingImage: defaultMissingImage)

        tv.font = WPFontManager.merriweatherRegularFontOfSize(16)
        tv.accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        tv.delegate = self
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.formatter = self
        tv.inputAccessoryView = toolbar
        tv.textColor = UIColor.darkTextColor()
        tv.translatesAutoresizingMaskIntoConstraints = false

        return tv
    }()

    fileprivate(set) lazy var htmlTextView: UITextView = {
        let tv = UITextView()

        tv.accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        tv.font = WPFontManager.merriweatherRegularFont(ofSize: 16)
        tv.textColor = UIColor.darkText
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isHidden = true

        return tv
    }()

    fileprivate(set) lazy var titleTextField: UITextField = {
        let placeholderText = NSLocalizedString("Enter title here", comment: "Label for the title of the post field. Should be the same as WP core.")
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

        return tf
    }()

    fileprivate(set) lazy var separatorView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 1))

        v.backgroundColor = WPStyleGuide.greyLighten30()
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()



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

    fileprivate(set) var blog: Blog
    fileprivate(set) var post: AbstractPost

    // MARK: - Lifecycle Methods

    init(post: AbstractPost) {
        self.blog = post.blog
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure("Aztec Post View Controller must be initialized by code")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        WPFontManager.loadMerriweatherFontFamily()

        edgesForExtendedLayout = UIRectEdge()
        navigationController?.navigationBar.isTranslucent = false

        view.addSubview(titleTextField)
        view.addSubview(separatorView)
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)

        createRevisionOfPost()
        titleTextField.text = post.postTitle

        if let content = post.content {
            richTextView.setHTML(content)
        }

        view.setNeedsUpdateConstraints()
        configureNavigationBar()

        title = NSLocalizedString("Aztec Native Editor", comment: "")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Cancel", comment: "Action button to close editor and cancel changes or insertion of post"),
            style: .done,
            target: self,
            action: #selector(AztecPostViewController.cancelEditingAction(_:)))
        view.backgroundColor = UIColor.white
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // TODO: Update toolbars
        //    [self.editorToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];
        //    [self.titleToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];

    }


    // MARK: - Configuration Methods

    override func updateViewConstraints() {

        super.updateViewConstraints()

        NSLayoutConstraint.activate([
            titleTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: type(of: self).margin),
            titleTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -type(of: self).margin),
            titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: type(of: self).margin),
            titleTextField.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
            ])

        NSLayoutConstraint.activate([
            separatorView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: type(of: self).margin),
            separatorView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -type(of: self).margin),
            separatorView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: type(of: self).margin),
            separatorView.heightAnchor.constraint(equalToConstant: separatorView.frame.height)
            ])

        NSLayoutConstraint.activateConstraints([
            richTextView.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: type(of: self).margin),
            richTextView.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -type(of: self).margin),
            richTextView.topAnchor.constraintEqualToAnchor(separatorView.bottomAnchor, constant: type(of: self).margin),
            richTextView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -type(of: self).margin)
            ])

        NSLayoutConstraint.activateConstraints([
            htmlTextView.leftAnchor.constraintEqualToAnchor(richTextView.leftAnchor),
            htmlTextView.rightAnchor.constraintEqualToAnchor(richTextView.rightAnchor),
            htmlTextView.topAnchor.constraintEqualToAnchor(richTextView.topAnchor),
            htmlTextView.bottomAnchor.constraintEqualToAnchor(richTextView.bottomAnchor),
            ])
    }

    func configureNavigationBar() {
        let title = NSLocalizedString("HTML", comment: "HTML!")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: title,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(switchEditionMode))
    }


    // MARK: - Helpers

    @IBAction func switchEditionMode() {
        mode.toggle()
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

        let range = richTextView.selectedRange
        let identifiers = richTextView.formatIdentifiersSpanningRange(range)
        toolbar.selectItemsMatchingIdentifiers(identifiers)
    }


    // MARK: - Sample Content

    func getSampleHTML() -> String {
        let htmlFilePath = Bundle.main.path(forResource: "content", ofType: "html")!
        let fileContents: String

        do {
            fileContents = try String(contentsOfFile: htmlFilePath)
        } catch {
            fatalError("Could not load the sample HTML.  Check the file exists in the target and that it has the correct name.")
        }

        return fileContents
    }
}


// MARK: - UITextViewDelegate methods
extension AztecPostViewController : UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        updateFormatBar()
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let richTextView = textView as? Aztec.TextView else {
            return
        }

        // TODO: This may not be super performant; Instrument and improve if needed and remove this TODO
        post.content = richTextView.getHTML()

        ContextManager.sharedInstance().save(post.managedObjectContext)
    }
}


// MARK: - UITextFieldDelegate methods
extension AztecPostViewController : UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        post.postTitle = textField.text

        ContextManager.sharedInstance().save(post.managedObjectContext)
    }
}

// MARK: - HTML Mode Switch methods
extension AztecPostViewController {
    enum EditionMode {
        case richText
        case html

        mutating func toggle() {
            switch self {
            case .html:
                self = .richText
            case .richText:
                self = .html
            }
        }
    }

    fileprivate func switchToHTML() {
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("Native", comment: "Rich Edition!")

        htmlTextView.text = richTextView.getHTML()

        view.endEditing(true)
        htmlTextView.isHidden = false
        richTextView.hidden = true
    }

    fileprivate func switchToRichText() {
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("HTML", comment: "HTML!")

        richTextView.setHTML(htmlTextView.text)

        view.endEditing(true)
        richTextView.hidden = false
        htmlTextView.isHidden = true
    }
}

// MARK: -
extension AztecPostViewController : Aztec.FormatBarDelegate
{

    func handleActionForIdentifier(_ identifier: String) {
        guard let identifier = Aztec.FormattingIdentifier(rawValue: identifier) else {
            return
        }

        switch identifier {
        case .Bold:
            toggleBold()
        case .Italic:
            toggleItalic()
        case .Underline:
            toggleUnderline()
        case .Strikethrough:
            toggleStrikethrough()
        case .Blockquote:
            toggleBlockquote()
        case .Unorderedlist:
            toggleUnorderedList()
        case .Orderedlist:
            toggleOrderedList()
        case .Link:
            toggleLink()
        case .Media:
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

        linkTitle = richTextView.attributedText.attributedSubstringFromRange(linkRange).string
        showLinkDialog(forURL: linkURL, title: linkTitle, range: linkRange)
    }


    func showLinkDialog(forURL url: URL?, title: String?, range: NSRange) {

        let isInsertingNewLink = (url == nil)
        // TODO: grab link from pasteboard if available

        let insertButtonTitle = isInsertingNewLink ? NSLocalizedString("Insert Link", comment:"Label action for inserting a link on the editor") : NSLocalizedString("Update Link", comment:"Label action for updating a link on the editor")
        let removeButtonTitle = NSLocalizedString("Remove Link", comment:"Label action for removing a link from the editor")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment:"Cancel button")

        let alertController = UIAlertController(title:insertButtonTitle,
                                                message:nil,
                                                preferredStyle:UIAlertControllerStyle.alert)

        alertController.addTextField(configurationHandler: { [weak self]textField in
            textField.clearButtonMode = UITextFieldViewMode.always
            textField.placeholder = NSLocalizedString("URL", comment:"URL text field placeholder")

            textField.text = url?.absoluteString

            textField.addTarget(self,
                action:#selector(AztecPostViewController.alertTextFieldDidChange),
                for:UIControlEvents.editingChanged)
            })

        alertController.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = UITextFieldViewMode.always
            textField.placeholder = NSLocalizedString("Link Name", comment:"Link name field placeholder")
            textField.isSecureTextEntry = false
            textField.autocapitalizationType = UITextAutocapitalizationType.sentences
            textField.autocorrectionType = UITextAutocorrectionType.default
            textField.spellCheckingType = UITextSpellCheckingType.default

            textField.text = title
        })

        let insertAction = UIAlertAction(title:insertButtonTitle,
                                         style:UIAlertActionStyle.default,
                                         handler:{ [weak self]action in

                                            self?.richTextView.becomeFirstResponder()
                                            let linkURLString = alertController.textFields?.first?.text
                                            var linkTitle = alertController.textFields?.last?.text

                                            if  linkTitle == nil  || linkTitle!.isEmpty {
                                                linkTitle = linkURLString
                                            }

                                            guard
                                                let urlString = linkURLString,
                                                let url = URL(string:urlString),
                                                let title = linkTitle
                                                else {
                                                    return
                                            }
                                            self?.richTextView.setLink(url, title:title, inRange: range)
            })

        let removeAction = UIAlertAction(title:removeButtonTitle,
                                         style:UIAlertActionStyle.destructive,
                                         handler:{ [weak self] action in
                                            self?.richTextView.becomeFirstResponder()
                                            self?.richTextView.removeLink(inRange: range)
            })

        let cancelAction = UIAlertAction(title: cancelButtonTitle,
                                         style:UIAlertActionStyle.Cancel,
                                         handler:{ [weak self]action in
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

        self.present(alertController, animated:true, completion:nil)
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
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []
        picker.delegate = self
        picker.allowsEditing = false
        picker.navigationBar.isTranslucent = false
        picker.modalPresentationStyle = .currentContext

        present(picker, animated: true, completion: nil)
    }


    // MARK: -

    func createToolbar() -> Aztec.FormatBar {
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let items = [
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.AddImage), identifier: Aztec.FormattingIdentifier.Media.rawValue),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.Bold), identifier: Aztec.FormattingIdentifier.Bold.rawValue),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.Italic), identifier: Aztec.FormattingIdentifier.Italic.rawValue),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.Underline), identifier: Aztec.FormattingIdentifier.Underline.rawValue),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.Strikethrough), identifier: Aztec.FormattingIdentifier.Strikethrough.rawValue),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.Quote), identifier: Aztec.FormattingIdentifier.Blockquote.rawValue),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.ListUnordered), identifier: Aztec.FormattingIdentifier.Unorderedlist.rawValue),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.ListOrdered), identifier: Aztec.FormattingIdentifier.Orderedlist.rawValue),
            flex,
            Aztec.FormatBarItem(image: Gridicon.iconOfType(.Link), identifier: Aztec.FormattingIdentifier.Link.rawValue),
            flex,
            ]

        let toolbar = Aztec.FormatBar()

        toolbar.barTintColor = UIColor(fromHex: 0xF9FBFC, alpha: 1)
        toolbar.tintColor = WPStyleGuide.greyLighten10()
        toolbar.highlightedTintColor = UIColor.blueColor()
        toolbar.selectedTintColor = UIColor.darkGrayColor()
        toolbar.disabledTintColor = UIColor.lightGrayColor()
        toolbar.items = items
        return toolbar
    }

    func templateImage(named: String) -> UIImage {
        return UIImage(named: named)!.withRenderingMode(.alwaysTemplate)
    }
}


extension AztecPostViewController: UINavigationControllerDelegate {

}


extension AztecPostViewController: UIImagePickerControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)

        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }

        // Insert Image + Reclaim Focus
        insertImage(image)
        richTextView.becomeFirstResponder()
    }
}

// MARK: - Cancel/Dismiss/Persistence Logic
extension AztecPostViewController {
    // TODO: Rip this out and put it into the PostService
    fileprivate func createRevisionOfPost() {
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

    fileprivate func cancelEditing() {
        stopEditing()

        if post.canSave() && post.hasUnsavedChanges() {
            showPostHasChangesAlert()
        } else {
            discardChangesAndUpdateGUI()
        }
    }

    fileprivate func stopEditing() {
        if titleTextField.isFirstResponder {
            titleTextField.resignFirstResponder()
        }

        view.endEditing(true)
    }

    fileprivate func showPostHasChangesAlert() {
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
                    // Save Draft
                }
            } else if post.status == PostStatusDraft {
                // The post was already a draft
                alertController.addDefaultActionWithTitle(NSLocalizedString("Update Draft", comment: "Button shown if there are unsaved changes and the author is trying to move away from an already published/saved post.")) { _ in
                    // Save Draft
                }
            }
        }

        alertController.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
        present(alertController, animated: true, completion: nil)
    }

    fileprivate func discardChanges() {
        guard let context = post.managedObjectContext, let originalPost = post.original else {
            return
        }

        post = originalPost
        post.deleteRevision()
        post.remove()

        ContextManager.sharedInstance().save(context)
    }

    fileprivate func discardChangesAndUpdateGUI() {
        discardChanges()

        onClose?(changesSaved: false)

        if isModal() {
            presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}


private extension AztecPostViewController {
    func insertImage(_ image: UIImage) {
        let index = richTextView.positionForCursor()
        richTextView.insertImage(image, index: index)
    }
}
*/
