import Foundation
import UIKit
import Aztec
import Gridicons

class AztecPostViewController: UIViewController
{
    func closeAction(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    private var bottomConstraint: NSLayoutConstraint!


    private (set) lazy var editor: AztecVisualEditor = {
        return AztecVisualEditor(textView: self.richTextView)
    }()


    private(set) lazy var richTextView: UITextView = {
        let tv = AztecVisualEditor.createTextView()
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

        tv.accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        tv.delegate = self
        tv.font = font
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.formatter = self
        tv.inputAccessoryView = toolbar
        tv.textColor = UIColor.darkTextColor()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.addSubview(self.titleTextField)
        tv.addSubview(self.separatorView)

        return tv
    }()

    private(set) lazy var htmlTextView: UITextView = {
        let tv = UITextView()
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

        tv.accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        tv.font = font
        tv.textColor = UIColor.darkTextColor()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.hidden = true

        return tv
    }()

    private(set) lazy var titleTextField: UITextField = {
        let placeholderText = NSLocalizedString("Enter title here", comment: "Label for the title of the post field. Should be the same as WP core.")
        let tf = UITextField()

        tf.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        tf.attributedPlaceholder = NSAttributedString(string: placeholderText,
                                                      attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        tf.autoresizingMask = [UIViewAutoresizing.FlexibleWidth]
        tf.delegate = self
        tf.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.enabled = false
        tf.inputAccessoryView = toolbar
        tf.returnKeyType = .Next
        tf.textColor = UIColor.darkTextColor()

        return tf
    }()


    private(set) lazy var separatorView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 1))

        v.autoresizingMask = [.FlexibleWidth]
        v.backgroundColor = UIColor.darkTextColor()

        return v
    }()



    private(set) var mode = EditionMode.RichText {
        didSet {
            switch mode {
            case .HTML:
                switchToHTML()
            case .RichText:
                switchToRichText()
            }
        }
    }

    private(set) var blog: Blog
    private(set) var post: AbstractPost

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
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // lazy load the editor
        _ = editor

        edgesForExtendedLayout = .None
        navigationController?.navigationBar.translucent = false

        view.addSubview(richTextView)
        view.addSubview(htmlTextView)

        editor.setHTML(post.content ?? "")
        titleTextField.text = post.postTitle

        configureConstraints()
        configureNavigationBar()

        layoutTextView()

        title = NSLocalizedString("Aztec Native Editor", comment: "")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done,
                                                                 target: self,
                                                                 action: #selector(AztecPostViewController.closeAction))
        view.backgroundColor = UIColor.whiteColor()
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }


    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }


    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        // TODO: Update toolbars
        //    [self.editorToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];
        //    [self.titleToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];

    }


    // MARK: - Configuration Methods

    func configureConstraints() {
        bottomConstraint = richTextView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)

        NSLayoutConstraint.activateConstraints([
            richTextView.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            richTextView.rightAnchor.constraintEqualToAnchor(view.rightAnchor),
            richTextView.topAnchor.constraintEqualToAnchor(view.topAnchor),
            bottomConstraint!
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
                                                            style: .Plain,
                                                            target: self,
                                                            action: #selector(switchEditionMode))
    }


    // MARK: - Helpers

    @IBAction func switchEditionMode() {
        mode.toggle()
    }



    // MARK: - Layout

    func layoutTextView() {
        let lineHeight = titleTextField.font!.lineHeight
        let offset: CGFloat = 15.0
        let width: CGFloat = richTextView.frame.width - (offset * 2)
        let height: CGFloat = lineHeight * 2.0
        titleTextField.frame = CGRect(x: offset, y: 0, width: width, height: height)

        separatorView.frame = CGRect(x: offset, y: titleTextField.frame.maxY, width: width, height: 1)

        let top: CGFloat = separatorView.frame.maxY + lineHeight
        richTextView.textContainerInset = UIEdgeInsets(top: top, left: offset, bottom: lineHeight, right: offset)
    }


    // MARK: - Keyboard Handling

    func keyboardWillShow(notification: NSNotification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(),
            let duration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
            else {
                return
        }
        bottomConstraint?.constant = -(view.frame.maxY - keyboardFrame.minY)
        UIView.animateWithDuration(duration) {
            self.view.layoutIfNeeded()
        }
    }


    func keyboardWillHide(notification: NSNotification) {
        bottomConstraint?.constant = 0
    }


    func updateFormatBar() {
        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        let range = richTextView.selectedRange
        let identifiers = editor.formatIdentifiersSpanningRange(range)
        toolbar.selectItemsMatchingIdentifiers(identifiers)
    }


    // MARK: - Sample Content

    func getSampleHTML() -> String {
        let htmlFilePath = NSBundle.mainBundle().pathForResource("content", ofType: "html")!
        let fileContents: String

        do {
            fileContents = try String(contentsOfFile: htmlFilePath)
        } catch {
            fatalError("Could not load the sample HTML.  Check the file exists in the target and that it has the correct name.")
        }

        return fileContents
    }
}


extension AztecPostViewController : UITextViewDelegate
{
    func textViewDidChangeSelection(textView: UITextView) {
        updateFormatBar()
    }
}


extension AztecPostViewController : UITextFieldDelegate
{

}

extension AztecPostViewController
{
    enum EditionMode {
        case RichText
        case HTML

        mutating func toggle() {
            switch self {
            case .HTML:
                self = .RichText
            case .RichText:
                self = .HTML
            }
        }
    }

    private func switchToHTML() {
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("Native", comment: "Rich Edition!")

        htmlTextView.text = editor.getHTML()

        view.endEditing(true)
        htmlTextView.hidden = false
        richTextView.hidden = true
    }

    private func switchToRichText() {
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("HTML", comment: "HTML!")

        editor.setHTML(htmlTextView.text)

        view.endEditing(true)
        richTextView.hidden = false
        htmlTextView.hidden = true
    }
}


extension AztecPostViewController : Aztec.FormatBarDelegate
{

    func handleActionForIdentifier(identifier: String) {
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
            insertImage()
        }
        updateFormatBar()
    }

    func toggleBold() {
        editor.toggleBold(range: richTextView.selectedRange)
    }


    func toggleItalic() {
        editor.toggleItalic(range: richTextView.selectedRange)
    }


    func toggleUnderline() {
        editor.toggleUnderline(range: richTextView.selectedRange)
    }


    func toggleStrikethrough() {
        editor.toggleStrikethrough(range: richTextView.selectedRange)
    }


    func toggleOrderedList() {
        editor.toggleOrderedList(range: richTextView.selectedRange)
    }


    func toggleUnorderedList() {
        editor.toggleUnorderedList(range: richTextView.selectedRange)
    }


    func toggleBlockquote() {
        editor.toggleBlockquote(range: richTextView.selectedRange)
    }


    func toggleLink() {
        editor.toggleLink(range: richTextView.selectedRange, params: [String : AnyObject]())
    }


    func insertImage() {
        editor.insertImage(richTextView.selectedRange.location, params: [String : AnyObject]())
    }

    // MARK: -

    func createToolbar() -> Aztec.FormatBar {
        let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
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

    func templateImage(named named: String) -> UIImage {
        return UIImage(named: named)!.imageWithRenderingMode(.AlwaysTemplate)
    }

}
