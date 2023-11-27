import UIKit
import PhotosUI

/// The main Site Media screen.
final class SiteMediaViewController: UIViewController, SiteMediaCollectionViewControllerDelegate {
    private let blog: Blog
    private let coordinator = MediaCoordinator.shared

    private lazy var collectionViewController = SiteMediaCollectionViewController(blog: blog)
    private lazy var buttonAddMedia = SpotlightableButton(type: .custom)
    private lazy var buttonAddMediaMenuController = SiteMediaAddMediaMenuController(blog: blog, coordinator: coordinator)
    private var buttonFilter: UIButton?

    private lazy var toolbarItemDelete = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(buttonDeleteTapped))
    private lazy var toolbarItemTitle = SiteMediaSelectionTitleView()
    private lazy var toolbarItemShare = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(buttonShareTapped))

    private var isPreparingToShare = false
    private var isFirstAppearance = true

    @objc init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)

        hidesBottomBarWhenPushed = true
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
        configureDefaultNavigationBarAppearance()
        configureNavigationTitle()
        refreshNavigationItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isFirstAppearance {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        buttonAddMedia.shouldShowSpotlight = QuickStartTourGuide.shared.isCurrentElement(.mediaUpload)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppearance {
            navigationItem.hidesSearchBarWhenScrolling = true
            isFirstAppearance = false
        }
    }

    // MARK: - Configuration

    private func configureNavigationTitle() {
        let menu = UIMenu(children: [
            UIMenu(options: [.displayInline], children: SiteMediaFilter.allFilters.map { filter in
                UIAction(title: filter.title, image: filter.image) { [weak self] _ in
                    self?.didUpdateFilter(filter)
                }
            }),
            UIDeferredMenuElement.uncached { [weak self] in
                let isAspect = UserDefaults.standard.isMediaAspectRatioModeEnabled
                let action = UIAction(
                    title: isAspect ? Strings.squareGrid : Strings.aspectRatioGrid,
                    image: UIImage(systemName: isAspect ? "rectangle.arrowtriangle.2.outward" : "rectangle.arrowtriangle.2.inward")) { [weak self] _ in
                        self?.collectionViewController.toggleAspectRatioMode()
                    }
                $0([action])
            }
        ])

        let button = UIButton.makeMenu(title: Strings.title, menu: menu)
        self.buttonFilter = button
        if UIDevice.isPad() {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        } else {
            navigationItem.titleView = button
        }
    }

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

    private func didUpdateFilter(_ filter: SiteMediaFilter) {
        buttonFilter?.setTitle(filter.title, for: .normal)
        buttonFilter?.sizeToFit() // Important!
        collectionViewController.setMediaType(filter.mediaType)
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
        updateToolbarItems()
        navigationController?.setToolbarHidden(!isEditing, animated: true)
    }

    private func updateToolbarItems() {
        guard isEditing else { return }

        var toolbarItems: [UIBarButtonItem] = []
        if blog.supports(.mediaDeletion) {
            toolbarItems.append(toolbarItemDelete)
        }
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        toolbarItems.append(UIBarButtonItem(customView: toolbarItemTitle))
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        if isPreparingToShare {
            toolbarItems.append(.activityIndicator)
        } else {
            toolbarItems.append(toolbarItemShare)
        }
        self.toolbarItems = toolbarItems
    }

    private func updateToolbarItemsState(for selection: [Media]) {
        toolbarItemDelete.isEnabled = selection.count > 0
        toolbarItemShare.isEnabled = selection.count > 0

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

            self?.setEditing(false)
        }, failure: {
            SVProgressHUD.showError(withStatus: Strings.deletionFailureMessage)
        })
    }

    // MARK: - Actions (Share)

    private func shareSelectedMedia(_ selection: [Media], barButtonItem: UIBarButtonItem? = nil) {
        guard !selection.isEmpty else {
            return
        }

        func setPreparingToShare(_ isSharing: Bool) {
            isPreparingToShare = isSharing
            updateToolbarItems()
        }

        setPreparingToShare(true)

        WPAnalytics.track(.siteMediaShareTapped, properties: [
            "number_of_items": selection.count
        ])

        Task {
            do {
                let fileURLs = try await Media.downloadRemoteData(for: selection, blog: blog)

                let activityViewController = UIActivityViewController(activityItems: fileURLs, applicationActivities: nil)
                activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
                activityViewController.completionWithItemsHandler = { [weak self] _, isCompleted, _, _ in
                    if isCompleted {
                        self?.setEditing(false)
                    }
                }
                present(activityViewController, animated: true, completion: nil)
            } catch {
                SVProgressHUD.showError(withStatus: Strings.sharingFailureMessage)
            }

            setPreparingToShare(false)
        }
    }

    // MARK: - SiteMediaCollectionViewControllerDelegate

    func siteMediaViewController(_ viewController: SiteMediaCollectionViewController, didUpdateSelection selection: [Media]) {
        updateToolbarItemsState(for: selection)
    }

    func makeAddMediaMenu(for viewController: SiteMediaCollectionViewController) -> UIMenu? {
        buttonAddMediaMenuController.makeMenu(for: self)
    }

    func siteMediaViewController(_ viewController: SiteMediaCollectionViewController, contextMenuFor media: Media) -> UIMenu? {
        var actions: [UIAction] = []

        actions.append(UIAction(title: Strings.buttonShare, image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            self?.shareSelectedMedia([media])
        })
        if blog.supports(.mediaDeletion) {
            actions.append(UIAction(title: Strings.buttonDelete, image: UIImage(systemName: "trash"), attributes: [.destructive]) { [weak self] _ in
                self?.deleteSelectedMedia([media])
            })
        }
        return UIMenu(children: actions)
    }
}

extension SiteMediaViewController {
    static var sharingFailureMessage: String { Strings.sharingFailureMessage }
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
    static let sharingFailureMessage = NSLocalizedString("mediaLibrary.sharingFailureMessage", value: "Unable to share the selected items.", comment: "Text displayed in HUD if there was an error attempting to share a group of media items.")
    static let buttonShare = NSLocalizedString("mediaLibrary.buttonShare", value: "Share", comment: "Context menu button")
    static let buttonDelete = NSLocalizedString("mediaLibrary.buttonDelete", value: "Delete", comment: "Context menu button")
    static let aspectRatioGrid = NSLocalizedString("mediaLibrary.aspectRatioGrid", value: "Aspect Ratio Grid", comment: "Button name in the more menu")
    static let squareGrid = NSLocalizedString("mediaLibrary.squareGrid", value: "Square Grid", comment: "Button name in the more menu")
}
