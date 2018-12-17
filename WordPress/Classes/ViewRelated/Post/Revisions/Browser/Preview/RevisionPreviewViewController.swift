import Aztec
import WordPressEditor


class RevisionPreviewViewController: UIViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "Revisions"

    var revision: Revision? {
        didSet {
            showRevision()
        }
    }

    private var titleHeightConstraint: NSLayoutConstraint!
    private var titleTopConstraint: NSLayoutConstraint!
    private let textViewManager = RevisionPreviewTextViewManager()
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
        label.translatesAutoresizingMaskIntoConstraints = false
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
        refreshTitlePosition()
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

        titleLabel.text = revision.postTitle ?? NSLocalizedString("Untitled", comment: "Label for an untitled post in the revision browser")

        let html = revision.postContent ?? ""
        textView.setHTML(html)

        refreshTitlePosition()
        updateTitleHeight()
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
        titleHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font?.lineHeight ?? 0)
        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8.0)
        updateTitleHeight()

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 8.0),
            titleTopConstraint,
            titleHeightConstraint
            ])

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6.0),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6.0),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }

    private func refreshTitlePosition() {
        titleTopConstraint.constant = -(textView.contentOffset.y + textView.contentInset.top - 8.0)

        var contentInset = textView.contentInset
        contentInset.top = titleHeightConstraint.constant + 8.0
        textView.contentInset = contentInset
    }

    private func updateTitleHeight() {
        let layoutMargins = view.layoutMargins

        var titleWidth = titleLabel.bounds.width
        if titleWidth <= 0 {
            // Use the title text field's width if available, otherwise calculate it.
            titleWidth = view.frame.width - (layoutMargins.left + layoutMargins.right)
        }

        let sizeThatShouldFitTheContent = titleLabel.sizeThatFits(CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude))
        titleHeightConstraint.constant = max(sizeThatShouldFitTheContent.height, titleLabel.font!.lineHeight)

        var contentInset = textView.contentInset
        contentInset.top = titleHeightConstraint.constant + 8.0
        textView.contentInset = contentInset
        textView.setContentOffset(CGPoint(x: 0, y: -contentInset.top), animated: false)

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
