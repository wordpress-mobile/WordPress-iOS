import Gridicons

protocol PostEditorNavigationBarManagerDelegate: class {
    var publishButtonText: String { get }
    var isPublishButtonEnabled: Bool { get }
    var uploadingButtonSize: CGSize { get }
    var savingDraftButtonSize: CGSize { get }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, blogPickerWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, reloadLeftNavigationItems items: [UIBarButtonItem])
}

// A class to share the navigation bar UI of the Post Editor.
// Currenly shared between Aztec and Gutenberg
//
class PostEditorNavigationBarManager {
    weak var delegate: PostEditorNavigationBarManagerDelegate?

    // MARK: - Buttons

    /// Dismiss Button
    ///
    lazy var closeButton: WPButtonForNavigationBar = {
        let cancelButton = WPStyleGuide.buttonForBar(with: Assets.closeButtonModalImage, target: self, selector: #selector(closeWasPressed))
        cancelButton.leftSpacing = Constants.cancelButtonPadding.left
        cancelButton.rightSpacing = Constants.cancelButtonPadding.right
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.accessibilityIdentifier = "editor-close-button"
        return cancelButton
    }()

    private lazy var moreButton: UIButton = {
        let image = UIImage.gridicon(.ellipsis)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.frame = CGRect(origin: .zero, size: image.size)
        button.accessibilityLabel = NSLocalizedString("More Options", comment: "Action button to display more available options")
        button.accessibilityIdentifier = "more_post_options"
        button.addTarget(self, action: #selector(moreWasPressed), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    /// Blog Picker's Button
    ///
    lazy var blogPickerButton: WPBlogSelectorButton = {
        let button = WPBlogSelectorButton(frame: .zero, buttonStyle: .typeSingleLine)
        button.addTarget(self, action: #selector(blogPickerWasPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return button
    }()

    /// Publish Button
    private(set) lazy var publishButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(publishButtonTapped(sender:)), for: .touchUpInside)
        button.setTitle(delegate?.publishButtonText ?? "", for: .normal)
        button.sizeToFit()
        button.isEnabled = delegate?.isPublishButtonEnabled ?? false
        button.setContentHuggingPriority(.required, for: .horizontal)
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

    /// Preview Generating Button
    ///
    private lazy var previewGeneratingView: LoadingStatusView = {
        let view = LoadingStatusView(title: NSLocalizedString("Generating Preview", comment: "Message to indicate progress of generating preview"))
        return view
    }()

    /// Draft Saving Button
    ///
    private lazy var savingDraftButton: WPUploadStatusButton = {
        let button = WPUploadStatusButton(frame: CGRect(origin: .zero, size: delegate?.savingDraftButtonSize ?? .zero))
        button.setTitle(NSLocalizedString("Saving Draft", comment: "Message to indicate progress of saving draft"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return button
    }()

    // MARK: - Bar button items

    /// Negative Offset BarButtonItem: Used to fine tune navigationBar Items
    ///
    private lazy var separatorButtonItem: UIBarButtonItem = {
        let separator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        return separator
    }()


    /// NavigationBar's Close Button
    ///
    lazy var closeBarButtonItem: UIBarButtonItem = {
        let cancelItem = UIBarButtonItem(customView: self.closeButton)
        cancelItem.accessibilityLabel = NSLocalizedString("Close", comment: "Action button to close edior and cancel changes or insertion of post")
        cancelItem.accessibilityIdentifier = "Close"
        return cancelItem
    }()


    /// NavigationBar's Blog Picker Button
    ///
    private lazy var blogPickerBarButtonItem: UIBarButtonItem = {
        let pickerItem = UIBarButtonItem(customView: self.blogPickerButton)
        pickerItem.accessibilityLabel = NSLocalizedString("Switch Blog", comment: "Action button to switch the blog to which you'll be posting")
        return pickerItem
    }()

    /// Media Uploading Status Button
    ///
    private lazy var mediaUploadingBarButtonItem: UIBarButtonItem = {
        let barButton = UIBarButtonItem(customView: self.mediaUploadingButton)
        barButton.accessibilityLabel = NSLocalizedString("Media Uploading", comment: "Message to indicate progress of uploading media to server")
        return barButton
    }()

    /// Preview Generating Status Button
    ///
    private lazy var previewGeneratingBarButtonItem: UIBarButtonItem = {
        let barButton = UIBarButtonItem(customView: self.previewGeneratingView)
        barButton.accessibilityLabel = NSLocalizedString("Generating Preview", comment: "Message to indicate progress of generating preview")
        return barButton
    }()

    /// Saving draft Status Button
    ///
    private lazy var savingDraftBarButtonItem: UIBarButtonItem = {
        let barButton = UIBarButtonItem(customView: self.savingDraftButton)
        barButton.accessibilityLabel = NSLocalizedString("Saving Draft", comment: "Message to indicate progress of saving draft")
        return barButton
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

    @objc private func moreWasPressed(sender: UIButton) {
        delegate?.navigationBarManager(self, moreWasPressed: sender)
    }

    @objc private func blogPickerWasPressed(sender: UIButton) {
        delegate?.navigationBarManager(self, blogPickerWasPressed: sender)
    }

    @objc private func publishButtonTapped(sender: UIButton) {
        delegate?.navigationBarManager(self, publishButtonWasPressed: sender)
    }

    @objc private func displayCancelMediaUploads(sender: UIButton) {
        delegate?.navigationBarManager(self, displayCancelMediaUploads: sender)
    }

    // MARK: - Public

    var leftBarButtonItems: [UIBarButtonItem] {
        return [separatorButtonItem, closeBarButtonItem, blogPickerBarButtonItem]
    }

    var uploadingMediaLeftBarButtonItems: [UIBarButtonItem] {
        return [separatorButtonItem, closeBarButtonItem, mediaUploadingBarButtonItem]
    }

    var generatingPreviewLeftBarButtonItems: [UIBarButtonItem] {
        return [separatorButtonItem, closeBarButtonItem, previewGeneratingBarButtonItem]
    }

    var savingDraftLeftBarButtonItems: [UIBarButtonItem] {
        return [separatorButtonItem, closeBarButtonItem, savingDraftBarButtonItem]
    }

    var rightBarButtonItems: [UIBarButtonItem] {
        return [moreBarButtonItem, publishBarButtonItem, separatorButtonItem]
    }

    func reloadPublishButton() {
        publishButton.setTitle(delegate?.publishButtonText ?? "", for: .normal)
        publishButton.sizeToFit()
        publishButton.isEnabled = delegate?.isPublishButtonEnabled ?? true
    }

    func reloadBlogPickerButton(with title: String, enabled: Bool) {

        let titleText = NSAttributedString(string: title, attributes: [.font: Fonts.blogPicker])

        blogPickerButton.setAttributedTitle(titleText, for: .normal)
        blogPickerButton.buttonMode = enabled ? .multipleSite : .singleSite
        blogPickerButton.isEnabled = enabled
    }

    func reloadLeftBarButtonItems(_ items: [UIBarButtonItem]) {
        delegate?.navigationBarManager(self, reloadLeftNavigationItems: items)
    }
}

extension PostEditorNavigationBarManager {
    private enum Constants {
        static let cancelButtonPadding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
    }

    private enum Fonts {
        static let semiBold = WPFontManager.systemSemiBoldFont(ofSize: 16)
        static var blogPicker: UIFont {
            if FeatureFlag.newNavBarAppearance.enabled {
                return WPStyleGuide.navigationBarStandardFont
            } else {
                return semiBold
            }
        }
    }

    private enum Assets {
        static let closeButtonModalImage    = UIImage.gridicon(.cross)
    }
}
