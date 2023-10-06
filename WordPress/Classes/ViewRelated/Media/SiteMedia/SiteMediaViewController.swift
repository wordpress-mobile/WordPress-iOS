import UIKit
import PhotosUI

/// The main Site Media screen.
final class SiteMediaViewController: UIViewController, SiteMediaCollectionViewControllerDelegate {
    private let blog: Blog
    private let coordinator = MediaCoordinator.shared

    private lazy var collectionViewController = SiteMediaCollectionViewController(blog: blog)
    private lazy var buttonAddMedia = SpotlightableButton(type: .custom)
    private lazy var buttonAddMediaMenuController = SiteMediaAddMediaMenuController(blog: blog, coordinator: coordinator)

    private lazy var toolbarItemDelete = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(buttonDeleteTapped))
    private lazy var toolbarItemTitle = SiteMediaSelectionTitleView()
    private lazy var toolbarItemShare = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(buttonShareTapped))

    @objc init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)

        hidesBottomBarWhenPushed = true
        title = Strings.title
        extendedLayoutIncludesOpaqueBars = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        QuickStartTourGuide.shared.visited(.mediaScreen)

        collectionViewController.embed(in: self)
        collectionViewController.delegate = self

        configureAddMediaButton()
        configureNavigationBarAppearance()
        refreshNavigationItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        buttonAddMedia.shouldShowSpotlight = QuickStartTourGuide.shared.isCurrentElement(.mediaUpload)
    }

    // MARK: - Configuration

    private func configureAddMediaButton() {
        let button = self.buttonAddMedia

        button.spotlightOffset = UIOffset(horizontal: 20, vertical: -10)
        let config = UIImage.SymbolConfiguration(textStyle: .body, scale: .large)
        let image = UIImage(systemName: "plus", withConfiguration: config) ?? .gridicon(.plus)
        button.setImage(image, for: .normal)
        button.addAction(UIAction { [weak self] _ in
            QuickStartTourGuide.shared.visited(.mediaUpload)
            self?.buttonAddMedia.shouldShowSpotlight = false
        }, for: .menuActionTriggered)
        button.menu = buttonAddMediaMenuController.makeMenu(for: self)
        button.showsMenuAsPrimaryAction = true
        button.accessibilityLabel = Strings.addButtonAccessibilityLabel
        button.accessibilityHint = Strings.addButtonAccessibilityHint
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
    }

    private func refreshNavigationItems() {
        navigationItem.hidesBackButton = isEditing

        navigationItem.rightBarButtonItems = {
            var rightBarButtonItems: [UIBarButtonItem] = []

            if !isEditing, blog.userCanUploadMedia {
                configureAddMediaButton()
                rightBarButtonItems.append(UIBarButtonItem(customView: buttonAddMedia))
            }

            if isEditing {
                let doneButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(buttonDoneTapped))
                rightBarButtonItems.append(doneButton)
            } else {
                let selectButton = UIBarButtonItem(title: Strings.select, style: .plain, target: self, action: #selector(buttonSelectTapped))
                rightBarButtonItems.append(selectButton)
            }
            return rightBarButtonItems
        }()
    }

    // MARK: - Actions

    @objc private func buttonSelectTapped() {
        setEditing(true)
    }

    @objc private func buttonDoneTapped() {
        setEditing(false)
    }

    @objc private func buttonDeleteTapped() {
        deleteSelectedMedia(collectionViewController.selectedMedia)
    }

    @objc private func buttonShareTapped(sender: UIBarButtonItem) {
        shareSelectedMedia(collectionViewController.selectedMedia, barButtonItem: sender)
    }

    // MARK: - Editing

    private func setEditing(_ isEditing: Bool) {
        guard self.isEditing != isEditing else { return }
        self.isEditing = isEditing

        collectionViewController.setEditing(isEditing, allowsMultipleSelection: true)
        refreshNavigationItems()

        if isEditing && toolbarItems == nil {
            var toolbarItems: [UIBarButtonItem] = []
            if blog.supports(.mediaDeletion) {
                toolbarItems.append(toolbarItemDelete)
            }
            toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            toolbarItems.append(UIBarButtonItem(customView: toolbarItemTitle))
            toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            toolbarItems.append(toolbarItemShare)
            self.toolbarItems = toolbarItems
        }

        navigationController?.setToolbarHidden(!isEditing, animated: true)
    }

    private func updateToolbarItemsState(for selection: [Media]) {
        for toolbarItem in toolbarItems ?? [] {
            toolbarItem.isEnabled = selection.count > 0
        }
        toolbarItemTitle.setSelection(selection)
    }

    // MARK: - Actions (Delete)

    private func deleteSelectedMedia(_ selection: [Media]) {
        guard !selection.isEmpty else {
            return
        }
        let alert = UIAlertController(
            title: nil,
            message: selection.count == 1 ? Strings.deleteConfirmationMessageOne : Strings.deleteConfirmationMessageMany,
            preferredStyle: UIDevice.current.userInterfaceIdiom == .phone ? .actionSheet : .alert
        )
        alert.addCancelActionWithTitle(Strings.deleteConfirmationCancel)
        alert.addDestructiveActionWithTitle(Strings.deleteConfirmationConfirm) { _ in
            self.didConfirmDeletion(for: selection)
        }
        present(alert, animated: true)
    }

    private func didConfirmDeletion(for selection: [Media]) {
        let deletedItemsCount = selection.count

        let updateProgress = { (progress: Progress?) in
            let fractionCompleted = progress?.fractionCompleted ?? 0
            SVProgressHUD.showProgress(Float(fractionCompleted), status: Strings.deletionProgressViewTitle)
        }
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)

        updateProgress(nil)
        coordinator.delete(media: selection, onProgress: updateProgress, success: { [weak self] in
            WPAppAnalytics.track(.mediaLibraryDeletedItems, withProperties: ["number_of_items_deleted": deletedItemsCount], with: self?.blog)
            SVProgressHUD.showSuccess(withStatus: Strings.deletionSuccessMessage)
        }, failure: {
            SVProgressHUD.showError(withStatus: Strings.deletionFailureMessage)
        })
    }

    // MARK: - Actions (Share)

    private func shareSelectedMedia(_ selection: [Media], barButtonItem: UIBarButtonItem? = nil) {
        guard !selection.isEmpty else {
            return
        }
        // TODO: Add spinner (cancellable?)
        Task {
            do {
                // TODO: Add analytics
                let fileURLs = try await Media.downloadRemoteData(for: selection, blog: blog)

                let activityViewController = UIActivityViewController(activityItems: fileURLs, applicationActivities: nil)
                activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
                present(activityViewController, animated: true, completion: nil)
            } catch {
                // TODO: Add error handling
            }
        }
    }

    // MARK: - SiteMediaCollectionViewControllerDelegate

    func siteMediaViewController(_ viewController: SiteMediaCollectionViewController, didUpdateSelection selection: [Media]) {
        updateToolbarItemsState(for: selection)
    }

    func makeAddMediaMenu(for viewController: SiteMediaCollectionViewController) -> UIMenu? {
        buttonAddMediaMenuController.makeMenu(for: self)
    }
}

private enum Strings {
    static let title = NSLocalizedString("mediaLibrary.title", value: "Media", comment: "Media screen navigation title")
    static let select = NSLocalizedString("mediaLibrary.buttonSelect", value: "Select", comment: "Media screen navigation bar button Select title")
    static let addButtonAccessibilityLabel = NSLocalizedString("mediaLibrary.addButtonAccessibilityLabel", value: "Add", comment: "Accessibility label for add button to add items to the user's media library")
    static let addButtonAccessibilityHint = NSLocalizedString("mediaLibrary.addButtonAccessibilityHint", value: "Add new media", comment: "Accessibility hint for add button to add items to the user's media library")
    static let deleteConfirmationMessageOne = NSLocalizedString("mediaLibrary.deleteConfirmationMessageOne", value: "Are you sure you want to permanently delete this item?", comment: "Message prompting the user to confirm that they want to permanently delete a media item. Should match Calypso.")
    static let deleteConfirmationMessageMany = NSLocalizedString("mediaLibrary.deleteConfirmationMessageMany", value: "Are you sure you want to permanently delete these items?", comment: "Message prompting the user to confirm that they want to permanently delete a group of media items.")
    static let deleteConfirmationCancel = NSLocalizedString("mediaLibrary.deleteConfirmationCancel", value: "Cancel", comment: "Verb. Button title. Tapping cancels an action.")
    static let deleteConfirmationConfirm = NSLocalizedString("mediaLibrary.deleteConfirmationConfirm", value: "Delete", comment: "Title for button that permanently deletes one or more media items (photos / videos)")
    static let deletionProgressViewTitle = NSLocalizedString("mediaLibrary.deletionProgressViewTitle", value: "Deleting...", comment: "Text displayed in HUD while a media item is being deleted.")
    static let deletionSuccessMessage = NSLocalizedString("mediaLibrary.deletionSuccessMessage", value: "Deleted!", comment: "Text displayed in HUD after successfully deleting a media item")
    static let deletionFailureMessage = NSLocalizedString("mediaLibrary.deletionFailureMessage", value: "Unable to delete all media items.", comment: "Text displayed in HUD if there was an error attempting to delete a group of media items.")
}
