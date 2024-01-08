import Gridicons

protocol PostEditorNavigationBarManagerDelegate: AnyObject {
    var publishButtonText: String { get }
    var isPublishButtonEnabled: Bool { get }
    var uploadingButtonSize: CGSize { get }
    var savingDraftButtonSize: CGSize { get }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, undoWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, redoWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, reloadTitleView view: UIView)
}

class ExtendedTouchAreaButton: UIButton {
    private var touchAreaPadding: CGFloat = 24.0

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.alpha = self.isHighlighted ? 0.5 : 1.0
            }
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedArea = bounds.insetBy(dx: -touchAreaPadding, dy: -touchAreaPadding)
        return extendedArea.contains(point)
    }
}

// A class to share the navigation bar UI of the Post Editor.
// Currenly shared between Aztec and Gutenberg
//
class PostEditorNavigationBarManager {
    weak var delegate: PostEditorNavigationBarManagerDelegate?

    // MARK: - Buttons

    /// Dismiss Button
    ///
    let siteIconView: SiteIconView = {
        let siteIconView = SiteIconView(frame: .zero)
        siteIconView.translatesAutoresizingMaskIntoConstraints = false
        siteIconView.imageView.sizeToFit()

        let widthConstraint = siteIconView.widthAnchor.constraint(equalToConstant: 28)
        let heightConstraint = siteIconView.heightAnchor.constraint(equalToConstant: 28)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint])
        siteIconView.isUserInteractionEnabled = false
        siteIconView.removeButtonBorder()
        return siteIconView
    }()

    lazy var closeButton: UIButton = {
        let isRTL = UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft
        let closeImage = UIImage(named: "editor-chevron-left")
        let button = UIButton(type: .system)
        button.setImage(isRTL ? closeImage?.withHorizontallyFlippedOrientation() : closeImage, for: .normal)
        button.sizeToFit()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        button.isUserInteractionEnabled = false
        return button
    }()

    lazy var closeButtonContainer: ExtendedTouchAreaButton = {
        let button = ExtendedTouchAreaButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "editor-close-button"
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Action button to close the editor")

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeWasPressed))
        button.addGestureRecognizer(tapGesture)

        button.addSubview(closeButton)
        button.addSubview(siteIconView)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            siteIconView.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 0),
            siteIconView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            siteIconView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        button.isUserInteractionEnabled = true
        button.frame = CGRect(x: 0, y: 0, width: 70, height: 28)
        return button
    }()

    lazy var undoButton: UIButton = {
        let isRTL = UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft
        let undoImage = UIImage(named: "editor-undo")
        let button = UIButton(type: .system)
        button.setImage(isRTL ? undoImage?.withHorizontallyFlippedOrientation() : undoImage, for: .normal)
        button.accessibilityIdentifier = "editor-undo-button"
        button.accessibilityLabel = NSLocalizedString("Undo", comment: "Action button to undo last change")
        button.addTarget(self, action: #selector(undoWasPressed), for: .touchUpInside)
        button.sizeToFit()
        button.alpha = 0.3
        button.isUserInteractionEnabled = false
        return button
    }()

    lazy var redoButton: UIButton = {
        let isRTL = UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft
        let redoImage = UIImage(named: "editor-redo")
        let button = UIButton(type: .system)
        button.setImage(isRTL ? redoImage?.withHorizontallyFlippedOrientation() : redoImage, for: .normal)
        button.accessibilityIdentifier = "editor-redo-button"
        button.accessibilityLabel = NSLocalizedString("Redo", comment: "Action button to redo last change")
        button.addTarget(self, action: #selector(redoWasPressed), for: .touchUpInside)
        button.sizeToFit()
        button.alpha = 0.3
        button.isUserInteractionEnabled = false
        return button
    }()

    private lazy var moreButton: UIButton = {
        let image = UIImage(named: "editor-more")
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.accessibilityLabel = NSLocalizedString("More Options", comment: "Action button to display more available options")
        button.accessibilityIdentifier = "more_post_options"
        button.addTarget(self, action: #selector(moreWasPressed), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    /// Blog TitleView Label
    lazy var blogTitleViewLabel: UILabel = {
        let label = UILabel()
        label.textColor = .appBarText
        label.font = Fonts.blogTitle
        return label
    }()

    /// Publish Button
    private(set) lazy var publishButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(publishButtonTapped(sender:)), for: .touchUpInside)
        button.setTitle(delegate?.publishButtonText ?? "", for: .normal)
        button.sizeToFit()
        button.isEnabled = delegate?.isPublishButtonEnabled ?? false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.tintColor = .editorActionText
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
        return button
    }()

    /// Media Uploading Button
    ///
    private lazy var mediaUploadingButton: WPUploadStatusButton = {
        let button = WPUploadStatusButton(frame: CGRect(origin: .zero, size: delegate?.uploadingButtonSize ?? .zero))
        button.setTitle(NSLocalizedString("Media Uploading", comment: "Message to indicate progress of uploading media to server"), for: .normal)
        button.addTarget(self, action: #selector(displayCancelMediaUploads), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return button
    }()

    // MARK: - Bar button items

    /// Negative Offset BarButtonItem: Used to fine tune navigationBar Items
    ///
    internal lazy var separatorButtonItem: UIBarButtonItem = {
        let separator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        separator.width = 16
        return separator
    }()


    /// NavigationBar's Close Button
    ///
    lazy var closeBarButtonItem: UIBarButtonItem = {
        let cancelItem = UIBarButtonItem(customView: self.closeButtonContainer)
        cancelItem.accessibilityLabel = NSLocalizedString("Close", comment: "Action button to close edior and cancel changes or insertion of post")
        cancelItem.accessibilityIdentifier = "Close"
        return cancelItem
    }()

    /// Publish Button
    private(set) lazy var publishBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(customView: self.publishButton)

        return button
    }()

    /// NavigationBar's More Button
    ///
    lazy var moreBarButtonItem: UIBarButtonItem = {
        let moreItem = UIBarButtonItem(customView: self.moreButton)
        return moreItem
    }()

    // MARK: - Selectors

    @objc private func closeWasPressed(sender: UIButton) {
        delegate?.navigationBarManager(self, closeWasPressed: sender)
    }

    @objc private func undoWasPressed(sender: UIButton) {
        delegate?.navigationBarManager(self, undoWasPressed: sender)
    }

    @objc private func redoWasPressed(sender: UIButton) {
        delegate?.navigationBarManager(self, redoWasPressed: sender)
    }

    @objc private func moreWasPressed(sender: UIButton) {
        delegate?.navigationBarManager(self, moreWasPressed: sender)
    }

    @objc private func publishButtonTapped(sender: UIButton) {
        delegate?.navigationBarManager(self, publishButtonWasPressed: sender)
    }

    @objc private func displayCancelMediaUploads(sender: UIButton) {
        delegate?.navigationBarManager(self, displayCancelMediaUploads: sender)
    }

    // MARK: - Public

    var leftBarButtonItems: [UIBarButtonItem] {
        return [closeBarButtonItem]
    }

    var uploadingMediaTitleView: UIView {
        mediaUploadingButton
    }

    var rightBarButtonItems: [UIBarButtonItem] {
        let undoButton = UIBarButtonItem(customView: self.undoButton)
        let redoButton = UIBarButtonItem(customView: self.redoButton)
        return [publishBarButtonItem, separatorButtonItem, moreBarButtonItem, separatorButtonItem, redoButton, separatorButtonItem, undoButton]
    }

    var rightBarButtonItemsAztec: [UIBarButtonItem] {
        return [moreBarButtonItem, publishBarButtonItem, separatorButtonItem]
    }

    func reloadPublishButton() {
        publishButton.setTitle(delegate?.publishButtonText ?? "", for: .normal)
        publishButton.sizeToFit()
        publishButton.isEnabled = delegate?.isPublishButtonEnabled ?? true
    }

    func reloadTitleView(_ view: UIView) {
        delegate?.navigationBarManager(self, reloadTitleView: view)
    }
}

extension PostEditorNavigationBarManager {
    private enum Fonts {
        static var blogTitle: UIFont {
            WPStyleGuide.navigationBarStandardFont
        }
    }
}
