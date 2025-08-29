import UIKit
import Gridicons
import WordPressUI

protocol PostEditorNavigationBarManagerDelegate: AnyObject {
    var publishButtonText: String { get }
    var isPublishButtonEnabled: Bool { get }
    var uploadingButtonSize: CGSize { get }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, undoWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, redoWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton)
    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton)
}

// A class to share the navigation bar UI of the Post Editor.
// Currenly shared between Aztec and Gutenberg
//
class PostEditorNavigationBarManager {
    weak var delegate: PostEditorNavigationBarManagerDelegate?

    // MARK: - Buttons

    private(set) lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeWasPressed))
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Action button to close the editor")
        button.accessibilityIdentifier = "editor-close-button"
        return button
    }()

    private(set) lazy var undoButton: UIButton = {
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

    private(set)lazy var redoButton: UIButton = {
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

    private(set)lazy var moreButton: UIButton = {
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
    private(set) lazy var blogTitleViewLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIAppColor.appBarText
        label.font = Fonts.blogTitle
        return label
    }()

    /// Publish Button
    private(set) lazy var publishButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: delegate?.publishButtonText, style: .plain, target: self, action: #selector(publishButtonTapped))
        button.isEnabled = delegate?.isPublishButtonEnabled ?? false
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
        return [closeButton]
    }

    var uploadingMediaTitleView: UIView {
        mediaUploadingButton
    }

    var rightBarButtonItems: [UIBarButtonItem] {
        let undoButton = UIBarButtonItem(customView: self.undoButton)
        let redoButton = UIBarButtonItem(customView: self.redoButton)
        if #available(iOS 26, *) {
            return [publishButton, separatorButtonItem, moreBarButtonItem, redoButton, undoButton]
        } else {
            return [publishButton, separatorButtonItem, moreBarButtonItem, separatorButtonItem, redoButton, separatorButtonItem, undoButton]
        }
    }

    var rightBarButtonItemsAztec: [UIBarButtonItem] {
        return [moreBarButtonItem, publishButton, separatorButtonItem]
    }

    func reloadPublishButton() {
        publishButton.title = delegate?.publishButtonText
        publishButton.isEnabled = delegate?.isPublishButtonEnabled ?? true
    }
}

extension PostEditorNavigationBarManager {
    private enum Fonts {
        static var blogTitle: UIFont {
            WPStyleGuide.navigationBarStandardFont
        }
    }
}
