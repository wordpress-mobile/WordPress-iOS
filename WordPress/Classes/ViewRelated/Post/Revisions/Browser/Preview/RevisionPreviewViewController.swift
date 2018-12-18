import Aztec
import WordPressEditor


class RevisionPreviewViewController: UIViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "Revisions"

    var revision: Revision? {
        didSet {
            showRevision()
        }
    }

    private let textViewManager = RevisionPreviewTextViewManager()
    private var titleInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    private var textViewInsets = UIEdgeInsets(top: 0.0, left: 6.0, bottom: 0.0, right: 6.0)

    private lazy var textView: TextView = {
        let aztext = TextView(defaultFont: WPFontManager.notoRegularFont(ofSize: 16),
                              defaultMissingImage: UIImage())
        aztext.translatesAutoresizingMaskIntoConstraints = false
        aztext.isEditable = false
        aztext.delegate = self
        return aztext
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = WPFontManager.notoBoldFont(ofSize: 24.0)
        label.autoresizingMask = [.flexibleWidth]
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
        refreshTitlePosition()
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

        titleLabel.text = revision.postTitle ?? NSLocalizedString("Untitled", comment: "Label for an untitled post in the revision browser")

        let html = revision.postContent ?? ""
        textView.setHTML(html)

        updateTitleHeight()
        refreshTitlePosition()
    }
}


// Aztec editor implementation for the title Label and text view.
// Like with the post editor content and title are separate views.
//
private extension RevisionPreviewViewController {
    private func addSubviews() {
        view.addSubview(textView)
        view.addSubview(titleLabel)
    }

    private func configureConstraints() {
        updateTitleHeight()

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: textViewInsets.left),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -textViewInsets.right),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }

    private func refreshTitlePosition() {
        titleLabel.frame.origin.y = -(textView.contentOffset.y + textView.contentInset.top) + titleInsets.top
    }

    private func updateTitleHeight() {
        let size = titleLabel.sizeThatFits(CGSize(width: view.frame.width - (titleInsets.left * 2.0), height: CGFloat.greatestFiniteMagnitude))
        titleLabel.frame = CGRect(x: titleInsets.left, y: titleInsets.top, width: size.width, height: size.height)

        var contentInset = textView.contentInset
        contentInset.top = titleLabel.frame.maxY + titleInsets.bottom
        textView.contentInset = contentInset
        textView.setContentOffset(CGPoint(x: 0, y: -textView.contentInset.top), animated: false)

        updateScrollInsets()
    }

    private func updateScrollInsets() {
        var scrollInsets = textView.contentInset
        var rightMargin = (view.frame.maxX - textView.frame.maxX)
        if #available(iOS 11.0, *) {
            rightMargin -= view.safeAreaInsets.right
        }
        scrollInsets.right = -rightMargin
        textView.scrollIndicatorInsets = scrollInsets
    }
}


extension RevisionPreviewViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshTitlePosition()
    }
}
