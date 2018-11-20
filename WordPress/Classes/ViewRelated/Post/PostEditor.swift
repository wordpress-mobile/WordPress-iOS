
import UIKit
import Gridicons

/// Common interface to all editors
///
protocol PostEditor: class {
    /// Initialize editor with a post.
    ///
    init(post: AbstractPost)

    /// The post being edited.
    ///
    var post: AbstractPost { get set }

    /// Closure to be executed when the editor gets closed.
    ///
    var onClose: ((_ changesSaved: Bool, _ shouldShowPostPost: Bool) -> Void)? { get set }

    /// Whether the editor should open directly to the media picker.
    ///
    var isOpenedDirectlyForPhotoPost: Bool { get set }
}

protocol PublishablePostEditor: PostEditor {
    /// Boolean indicating whether the post should be removed whenever the changes are discarded, or not.
    ///
    var shouldRemovePostOnDismiss: Bool { get }

    /// Cancels all ongoing uploads
    ///
    ///TODO: We won't need this once media uploading is extracted to PostEditorUtil
    func cancelUploadOfAllMedia(for post: AbstractPost)

    /// Whether the editor has failed media or not
    ///
    //TODO: We won't need this once media uploading is extracted to PostEditorUtil
    var hasFailedMedia: Bool { get }

    //TODO: We won't need this once media uploading is extracted to PostEditorUtil
    var isUploadingMedia: Bool { get }

    //TODO: We won't need this once media uploading is extracted to PostEditorUtil
    //TODO: Otherwise the signature needs refactoring, it is too ambiguous for a protocol method
    func removeFailedMedia()

    /// Verification prompt helper
    var verificationPromptHelper: VerificationPromptHelper? { get }

    /// Post editor state context
    var postEditorStateContext: PostEditorStateContext { get }

    /// Update editor UI with given html
    func setHTML(_ html: String)

    /// Return the current html in the editor
    func getHTML() -> String

    /// Title of the post
    var postTitle: String { get set }

    /// Describes the editor type to be used in analytics reporting
    var analyticsEditorSource: String { get }

    var navigationBarManager: PostEditorNavigationBarManager { get }
}

protocol PostEditorNavigationBarManagerDelegate: class {
    var publishButtonText: String { get }
    var isPublishButtonEnabled: Bool { get }
    var uploadingButtonSize: CGSize { get }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, blogPickerWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton)
}

class PostEditorNavigationBarManager {
    weak var delegate: PostEditorNavigationBarManagerDelegate?

    // MARK: - Buttons

    /// Dismiss Button
    ///
    lazy var closeButton: WPButtonForNavigationBar = {
        let cancelButton = WPStyleGuide.buttonForBar(with: AztecPostViewController.Assets.closeButtonModalImage, target: self, selector: #selector(closeWasPressed))
        cancelButton.leftSpacing = AztecPostViewController.Constants.cancelButtonPadding.left
        cancelButton.rightSpacing = AztecPostViewController.Constants.cancelButtonPadding.right
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        return cancelButton
    }()

    private lazy var moreButton: UIButton = {
        let image = Gridicon.iconOfType(.ellipsis)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.frame = CGRect(origin: .zero, size: image.size)
        button.accessibilityLabel = NSLocalizedString("More", comment: "Action button to display more available options")
        button.addTarget(self, action: #selector(moreWasPressed), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    /// Blog Picker's Button
    ///
    lazy var blogPickerButton: WPBlogSelectorButton = {
        let button = WPBlogSelectorButton(frame: .zero, buttonStyle: .typeSingleLine)
        button.addTarget(self, action: #selector(blogPickerWasPressed), for: .touchUpInside)
        if #available(iOS 11, *) {
            button.translatesAutoresizingMaskIntoConstraints = false
        }
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
        if #available(iOS 11, *) {
            button.translatesAutoresizingMaskIntoConstraints = false
        }
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

    var rightBarButtonItems: [UIBarButtonItem] {
        return [moreBarButtonItem, publishBarButtonItem, separatorButtonItem]
    }

    func reloadPublishButton() {
        publishButton.setTitle(delegate?.publishButtonText ?? "", for: .normal)
        publishButton.isEnabled = delegate?.isPublishButtonEnabled ?? true
    }

    func reloadBlogPickerButton(with title: String, enabled: Bool) {

        let titleText = NSAttributedString(string: title, attributes: [.font: AztecPostViewController.Fonts.blogPicker])

        blogPickerButton.setAttributedTitle(titleText, for: .normal)
        blogPickerButton.buttonMode = enabled ? .multipleSite : .singleSite
        blogPickerButton.isEnabled = enabled
    }
}
