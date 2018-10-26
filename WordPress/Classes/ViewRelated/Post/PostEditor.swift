
import UIKit
import Gridicons

/// Common interface to all editors
///
@objc protocol PostEditor: class {
    /// Initialize editor with a post.
    ///
    init(post: AbstractPost)

    /// The post being edited.
    ///
    var post: AbstractPost { get }

    /// Closure to be executed when the editor gets closed.
    ///
    var onClose: ((_ changesSaved: Bool, _ shouldShowPostPost: Bool) -> Void)? { get set }

    /// Whether the editor should open directly to the media picker.
    ///
    var isOpenedDirectlyForPhotoPost: Bool { get set }
}

protocol PostEditorNavigationBarManagerDelegate: class {
    var publishButtonText: String { get }
    var isPublishButtonEnabled: Bool { get }
    var uploadingButtonSize: CGSize { get }

    func closeWasPressed(sender: UIButton)
    func moreWasPressed(sender: UIButton)
    func blogPickerWasPressed(sender: UIButton)
    func publishButtonWasPressed(sender: UIButton)
    func displayCancelMediaUploads(sender: UIButton)
}

class PostEditorNavigationBarManager {
    let navigationItem: UINavigationItem
    weak var delegate: PostEditorNavigationBarManagerDelegate?

    init(navigationItem: UINavigationItem, delegate: PostEditorNavigationBarManagerDelegate) {
        self.navigationItem = navigationItem
        self.delegate = delegate
    }

    // MARK: - Buttons

    /// Dismiss Button
    ///
    private lazy var closeButton: WPButtonForNavigationBar = {
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
    private lazy var blogPickerButton: WPBlogSelectorButton = {
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
    private lazy var closeBarButtonItem: UIBarButtonItem = {
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
    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let moreItem = UIBarButtonItem(customView: self.moreButton)
        return moreItem
    }()

    // MARK: - Selectors

    @objc private func closeWasPressed(sender: UIButton) {
        delegate?.closeWasPressed(sender: sender)
    }

    @objc private func moreWasPressed(sender: UIButton) {
        delegate?.moreWasPressed(sender: sender)
    }

    @objc private func blogPickerWasPressed(sender: UIButton) {
        delegate?.blogPickerWasPressed(sender: sender)
    }

    @objc private func publishButtonTapped(sender: UIButton) {
        delegate?.publishButtonWasPressed(sender: sender)
    }

    @objc private func displayCancelMediaUploads(sender: UIButton) {
        delegate?.displayCancelMediaUploads(sender: sender)
    }

    // MARK: - Public

    var leftBarButtonItems: [UIBarButtonItem] {
        return [separatorButtonItem, closeBarButtonItem, blogPickerBarButtonItem]
    }

    var rightBarButtonItems: [UIBarButtonItem] {
        return [moreBarButtonItem, publishBarButtonItem, separatorButtonItem]
    }
}
