import Aztec
import WordPressEditor

// View Controller for the Revision Visual preview
//
class RevisionPreviewViewController: UIViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "Revisions"

    var revision: Revision? {
        didSet {
            showRevision()
        }
    }

    private let mainContext = ContextManager.sharedInstance().mainContext
    private let textViewManager = RevisionPreviewTextViewManager()
    private var titleInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    private var textViewInsets = UIEdgeInsets(top: 0.0, left: 6.0, bottom: 0.0, right: 6.0)

    private lazy var textView: TextView = {
        let aztext = TextView(defaultFont: WPFontManager.notoRegularFont(ofSize: 16),
                              defaultMissingImage: UIImage())
        aztext.translatesAutoresizingMaskIntoConstraints = false
        aztext.isEditable = false
        return aztext
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = WPFontManager.notoBoldFont(ofSize: 24.0)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .natural
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviews()
        configureConstraints()
        setupAztec()
    }

    override func updateViewConstraints() {
        updateTitleHeight()
        super.updateViewConstraints()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.updateTitleHeight()
        })
    }
}


private extension RevisionPreviewViewController {
    private func setupAztec() {
        textView.load(WordPressPlugin())
        textView.textAttachmentDelegate = textViewManager

        let providers: [TextViewAttachmentImageProvider] = [
            SpecialTagAttachmentRenderer(),
            CommentAttachmentRenderer(font: AztecPostViewController.Fonts.regular),
            HTMLAttachmentRenderer(font: AztecPostViewController.Fonts.regular),
            GutenpackAttachmentRenderer()
        ]

        providers.forEach {
            textView.registerAttachmentImageProvider($0)
        }
    }

    private func showRevision() {
        guard let revision = revision else {
            return
        }

        let predicate = NSPredicate(format: "(blog.blogID == %@ AND postID == %@)", revision.siteId, revision.postId)
        textViewManager.post = mainContext.firstObject(ofType: AbstractPost.self, matching: predicate)

        titleLabel.text = revision.postTitle ?? NSLocalizedString("Untitled", comment: "Label for an untitled post in the revision browser")

        let html = revision.postContent ?? ""
        textView.setHTML(html)

        updateTitleHeight()
    }
}


// Aztec editor implementation for the title Label and text view.
// Like the post editor, title and content are separate views.
//
private extension RevisionPreviewViewController {
    private func addSubviews() {
        view.backgroundColor = .basicBackground
        view.addSubview(textView)
        textView.addSubview(titleLabel)
    }

    private func configureConstraints() {
        updateTitleHeight()

        let guide = view.readableContentGuide
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }

    private func updateTitleHeight() {
        let size = titleLabel.sizeThatFits(CGSize(width: textView.frame.width,
                                                  height: CGFloat.greatestFiniteMagnitude))
        titleLabel.frame = CGRect(x: 0, y: -(titleInsets.top + size.height), width: size.width, height: size.height)

        var contentInset = textView.contentInset
        contentInset.top = titleInsets.top + size.height + titleInsets.bottom
        textView.contentInset = contentInset
        textView.setContentOffset(CGPoint(x: 0, y: -textView.contentInset.top), animated: false)

        updateScrollInsets()
    }

    private func updateScrollInsets() {
        var scrollInsets = textView.contentInset
        var rightMargin = (view.frame.maxX - textView.frame.maxX)
        rightMargin -= view.safeAreaInsets.right
        scrollInsets.right = -rightMargin
        textView.scrollIndicatorInsets = scrollInsets
    }
}
