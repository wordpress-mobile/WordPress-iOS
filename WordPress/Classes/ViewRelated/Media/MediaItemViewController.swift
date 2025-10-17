import AVKit
import Combine
import UIKit
import Gridicons
import SVProgressHUD
import WordPressData
import WordPressShared

/// Displays an image preview and metadata for a single Media asset.
///
final class MediaItemViewController: UITableViewController {
    let media: Media

    private var viewModel: ImmuTable!
    private var mediaMetadata: MediaMetadata {
        didSet {
            if !mediaMetadata.matches(media) {
                saveChanges()
            }
        }
    }

    private let headerView = MediaItemHeaderView()
    private lazy var headerMaxHeightConstraint = headerView.heightAnchor.constraint(lessThanOrEqualToConstant: 320)

    init(media: Media) {
        self.media = media

        self.mediaMetadata = MediaMetadata(media: media)

        super.init(style: .insetGrouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.showsVerticalScrollIndicator = false
        tableView.cellLayoutMarginsFollowReadableWidth = true

        ImmuTable.registerRows([TextRow.self, EditableTextRow.self, TextViewRow.self], tableView: tableView)

        updateViewModel()
        updateNavigationItem()
        updateTitle()

        if let mediaID = media.mediaID, mediaID.intValue > 0 {
            tableView.tableFooterView = EntityMetadataTableFooterView.make(id: mediaID)
        }
    }

    private func updateTitle() {
        title = mediaMetadata.title
    }

    private func updateViewModel() {
        let titleRow = editableRowIfSupported(title: Strings.title,
                                              value: mediaMetadata.title,
                                              action: editTitle())
        let captionRow = editableRowIfSupported(title: Strings.caption,
                                                value: mediaMetadata.caption,
                                                action: editCaption())
        let descRow = editableRowIfSupported(title: Strings.description,
                                             value: mediaMetadata.desc,
                                             action: editDescription())
        let altRow = editableRowIfSupported(title: Strings.altText,
                                            value: mediaMetadata.alt,
                                            action: editAlt())

        var mediaInfoRows = [titleRow, captionRow, descRow]
        if media.mediaType == .image && media.blog.supports(BlogFeature.mediaAltEditing) {
            mediaInfoRows.append(altRow)
        }

        viewModel = ImmuTable(sections: [
            ImmuTableSection(headerText: nil, rows: mediaInfoRows, footerText: nil),
            ImmuTableSection(headerText: nil, rows: metadataRows, footerText: nil)
        ])

        headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 280).isActive = true
        headerMaxHeightConstraint.isActive = true
        headerView.configure(with: media)
        tableView.tableHeaderView = headerView

        headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapHeaderView)))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Using a constant instead of a `multiplier` because the multiplier-based
        // constraint doesn't seem to go into effect until after `viewDidLayoutSubviews`.
        headerMaxHeightConstraint.constant = view.bounds.height * 0.75
        tableView.sizeToFitHeaderView()
        tableView.sizeToFitFooterView()
    }

    private var metadataRows: [ImmuTableRow] {
        let presenter = MediaMetadataPresenter(media: media)

        var rows = [ImmuTableRow]()
        rows.append(TextViewRow(title: Strings.url, details: media.remoteURL ?? ""))
        rows.append(TextRow(title: Strings.fileName, value: media.filename ?? ""))
        rows.append(TextRow(title: Strings.fileType, value: presenter.fileType ?? ""))
        if let size = media.formattedSize {
            rows.append(TextRow(title: Strings.fileSize, value: size))
        }

        switch media.mediaType {
        case .image, .video:
            rows.append(TextRow(title: Strings.dimensions, value: presenter.dimensions))
        default: break
        }

        rows.append(TextRow(title: Strings.uploaded, value: media.creationDate?.toMediumString() ?? ""))

        return rows
    }

    private func editableRowIfSupported(title: String, value: String, action: @escaping ((ImmuTableRow) -> ())) -> ImmuTableRow {
        if media.blog.supports(BlogFeature.mediaMetadataEditing) {
            return EditableTextRow(title: title, value: value, action: action)
        } else {
            return TextRow(title: title, value: value)
        }
    }

    private func reloadViewModel() {
        guard !isMediaDeleted else {
            handleDeletedMedia()
            return
        }

        updateViewModel()
        tableView.reloadData()
    }

    private var isMediaDeleted: Bool {
        return media.isDeleted || media.managedObjectContext == nil
    }

    private func handleDeletedMedia() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)
        SVProgressHUD.showError(withStatus: Strings.mediaDeleted)
        navigationController?.popViewController(animated: true)
    }

    private func updateNavigationItem() {
        let shareItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(shareTapped))
        shareItem.accessibilityLabel = SharedStrings.Button.share

        let trashItem = UIBarButtonItem(image: UIImage(systemName: "trash"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(trashTapped))
        trashItem.accessibilityLabel = Strings.trash

        if media.blog.supports(.mediaDeletion) {
            navigationItem.rightBarButtonItems = [ shareItem, trashItem ]
        } else {
            navigationItem.rightBarButtonItems = [ shareItem ]
        }
    }

    @objc private func didTapHeaderView() {
        switch media.mediaType {
        case .image:
            presentImageViewControllerForMedia()
        case .video:
            presentVideoViewControllerForMedia()
        case .document:
            presentDocumentViewControllerForMedia()
        default:
            break
        }
    }

    private func presentImageViewControllerForMedia() {
        let controller = LightboxViewController(media: media)
        controller.thumbnail = headerView.imageView.image
        controller.configureZoomTransition(sourceView: headerView.imageView)
        present(controller, animated: true)
    }

    private func presentVideoViewControllerForMedia() {
        media.videoAsset { [weak self] asset, error in
            if let asset,
                let controller = self?.videoViewControllerForAsset(asset) {

                controller.modalTransitionStyle = .crossDissolve

                self?.present(controller, animated: true, completion: {
                    controller.player?.play()
                })
            } else if let _ = error {
                SVProgressHUD.showError(withStatus: Strings.unableToLoadVideo)
            }
        }
    }

    private func presentDocumentViewControllerForMedia() {
        guard let remoteURL = media.remoteURL,
            let url = URL(string: remoteURL) else { return }

        let controller = WebViewControllerFactory.controller(url: url, blog: media.blog, source: "media_item")
        controller.loadViewIfNeeded()
        controller.navigationItem.titleView = nil
        controller.title = media.title ?? ""

        navigationController?.pushViewController(controller, animated: true)
    }

    private func videoViewControllerForAsset(_ asset: AVAsset) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        controller.showsPlaybackControls = true
        controller.updatesNowPlayingInfoCenter = false
        controller.player = player

        return controller
    }

    // MARK: - Actions

    @objc private func shareTapped(_ sender: UIBarButtonItem) {
        func setPreparingToShare(_ isSharing: Bool) {
            if isSharing {
                let indicator = UIActivityIndicatorView()
                indicator.startAnimating()
                indicator.frame = CGRect(origin: .zero, size: CGSize(width: 43, height: 44))
                sender.customView = indicator
            } else {
                sender.customView = nil
            }
            sender.isEnabled = !isSharing
        }

        setPreparingToShare(true)

        WPAnalytics.track(.siteMediaShareTapped, properties: ["number_of_items": 1])

        Task {
            do {
                let fileURLs = try await Media.downloadRemoteData(for: [media], blog: media.blog)
                self.share(fileURLs, sender: sender)
            } catch {
                SVProgressHUD.showError(withStatus: SiteMediaViewController.sharingFailureMessage)
            }

            setPreparingToShare(false)
        }
    }

    @objc private func trashTapped(_ sender: UIBarButtonItem) {
        guard !isMediaDeleted else {
            handleDeletedMedia()
            return
        }

        let alertController = UIAlertController(title: nil,
                                                message: Strings.deleteConfirmation, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(Strings.cancel)
        alertController.addDestructiveActionWithTitle(Strings.delete, handler: { action in
            self.deleteMediaItem()
        })

        present(alertController, animated: true)
    }

    private func deleteMediaItem() {
        guard !isMediaDeleted else {
            handleDeletedMedia()
            return
        }

        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)
        SVProgressHUD.show(withStatus: Strings.deleting)

        let repository = MediaRepository(coreDataStack: ContextManager.shared)
        let mediaID = TaggedManagedObjectID(media)
        Task { @MainActor in
            do {
                try await repository.delete(mediaID)

                WPAppAnalytics.track(.mediaLibraryDeletedItems, properties: ["number_of_items_deleted": 1], blog: self.media.blog)
                SVProgressHUD.showSuccess(withStatus: Strings.deleted)
            } catch {
                SVProgressHUD.showError(withStatus: Strings.unableToDeleteMedia)
            }
        }
    }

    private func saveChanges() {
        mediaMetadata.update(media)

        let service = MediaService(managedObjectContext: ContextManager.shared.mainContext)
        service.update(media, success: { [weak self] in
            guard let blog = self?.media.blog else { return }
            WPAppAnalytics.track(.mediaLibraryEditedItemMetadata, blog: blog)
        }, failure: { _ in
            SVProgressHUD.showError(withStatus: Strings.unableToSaveMedia)
        })
    }

    private func editTitle() -> ((ImmuTableRow) -> ()) {
        return { [weak self] row in
            let editableRow = row as! EditableTextRow
            self?.pushSettingsController(for: editableRow, hint: Strings.Hints.imageTitle,
                                        onValueChanged: { value in
                self?.title = value
                (self?.parent as? SiteMediaPageViewController)?.title = value
                self?.mediaMetadata.title = value
                self?.reloadViewModel()
            })
        }
    }

    private func editCaption() -> ((ImmuTableRow) -> ()) {
        return { [weak self] row in
            let editableRow = row as! EditableTextRow
            self?.pushSettingsController(for: editableRow, hint: Strings.Hints.imageCaption,
                                        onValueChanged: { value in
                self?.mediaMetadata.caption = value
                self?.reloadViewModel()
            })
        }
    }

    private func editDescription() -> ((ImmuTableRow) -> ()) {
        return { [weak self] row in
            let editableRow = row as! EditableTextRow
            self?.pushSettingsController(for: editableRow, hint: Strings.Hints.imageDescription,
                                        onValueChanged: { value in
                self?.mediaMetadata.desc = value
                self?.reloadViewModel()
            })
        }
    }

    private func editAlt() -> ((ImmuTableRow) -> ()) {
        return { [weak self] row in
            let editableRow = row as! EditableTextRow
            self?.pushSettingsController(for: editableRow, hint: Strings.Hints.imageAlt,
                                         onValueChanged: { value in
                                            self?.mediaMetadata.alt = value
                                            self?.reloadViewModel()
            })
        }
    }

    private func pushSettingsController(for row: EditableTextRow, hint: String? = nil, onValueChanged: @escaping SettingsTextChanged) {
        let title = row.title
        let value = row.value
        let controller = SettingsTextViewController(text: value, placeholder: "\(title)...", hint: hint)

        controller.title = title
        controller.onValueChanged = onValueChanged

        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Sharing Logic

    private func share(_ activityItems: [Any], sender: UIBarButtonItem) {
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.modalPresentationStyle = .popover
        activityController.popoverPresentationController?.barButtonItem = sender
        activityController.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            if completed, let blog = self?.media.blog {
                WPAppAnalytics.track(.mediaLibrarySharedItemLink, blog: blog)
            }
        }
        present(activityController, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension MediaItemViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reusableIdentifier, for: indexPath)
        row.configureCell(cell)

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].headerText
    }
}

// MARK: - UITableViewDelegate
extension MediaItemViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = viewModel.rowAtIndexPath(indexPath)
        row.action?(row)
    }
}

/// Provides some extra formatting for a Media asset's metadata, used
/// to present it in the MediaItemViewController
///
private struct MediaMetadataPresenter {
    let media: Media

    /// A String containing the pixel size of the asset (width X height)
    var dimensions: String {
        let width = media.width ?? 0
        let height = media.height ?? 0

        return "\(width) × \(height)"
    }

    /// A String containing the uppercased file extension of the asset (.JPG, .PNG, etc)
    var fileType: String? {
        guard let filename = media.filename else {
            return nil
        }

        return (filename as NSString).pathExtension.uppercased()
    }
}

/// Used to store media metadata and provide the ability to undo changes to
/// the MediaItemViewController's media property.
private struct MediaMetadata {
    var title: String
    var caption: String
    var desc: String
    var alt: String

    init(media: Media) {
        title = media.title ?? ""
        caption = media.caption ?? ""
        desc = media.desc ?? ""
        alt = media.alt ?? ""
    }

    /// - returns: True if this metadata's fields match those
    /// of the specified Media object.
    func matches(_ media: Media) -> Bool {
        return title == media.title
            && caption == media.caption
            && desc == media.desc
            && alt == media.alt
    }

    /// Update the metadata fields of the specified Media object
    /// to match this metadata's fields.
    func update(_ media: Media) {
        media.title = title
        media.caption = caption
        media.desc = desc
        media.alt = alt
    }
}

private enum Strings {
    static let url = NSLocalizedString("siteMedia.details.url", value: "URL", comment: "Title for the URL field")
    static let title = NSLocalizedString("siteMedia.details.title", value: "Title", comment: "Noun. Label for the title of a media asset (image / video)")
    static let caption = NSLocalizedString("siteMedia.details.caption", value: "Caption", comment: "Noun. Label for the caption for a media asset (image / video)")
    static let description = NSLocalizedString("siteMedia.details.description", value: "Description", comment: "Label for the description for a media asset (image / video)")
    static let altText = NSLocalizedString("siteMedia.details.altText", value: "Alt Text", comment: "Label for the alt for a media asset (image)")
    static let fileName = NSLocalizedString("siteMedia.details.fileName", value: "File Name", comment: "Label for the file name for a media asset (image / video)")
    static let fileType = NSLocalizedString("siteMedia.details.fileType", value: "File Type", comment: "Label for the file type (.JPG, .PNG, etc) for a media asset (image / video)")
    static let fileSize = NSLocalizedString("siteMedia.details.fileSize", value: "File Size", comment: "Label for the file size for a media asset (image / video)")
    static let dimensions = NSLocalizedString("siteMedia.details.dimensions", value: "Dimensions", comment: "Label for the dimensions in pixels for a media asset (image / video)")
    static let uploaded = NSLocalizedString("siteMedia.details.uploaded", value: "Uploaded", comment: "Label for the date a media asset (image / video) was uploaded")
    static let trash = NSLocalizedString("siteMedia.details.trash", value: "Trash", comment: "Accessibility label for trash buttons in nav bars")
    static let mediaDeleted = NSLocalizedString("siteMedia.details.mediaDeleted", value: "This media item has been deleted.", comment: "Message displayed in Media Library if the user attempts to edit a media asset (image / video) after it has been deleted.")
    static let unableToLoadVideo = NSLocalizedString("siteMedia.details.unableToLoadVideo", value: "Unable to load video.", comment: "Error shown when the app fails to load a video from the user's media library.")
    static let deleteConfirmation = NSLocalizedString("siteMedia.details.deleteConfirmation", value: "Are you sure you want to permanently delete this item?", comment: "Message prompting the user to confirm that they want to permanently delete a media item. Should match Calypso.")
    static let cancel = NSLocalizedString("siteMedia.details.cancel", value: "Cancel", comment: "Verb. Button title. Tapping cancels an action.")
    static let delete = NSLocalizedString("siteMedia.details.delete", value: "Delete", comment: "Title for button that permanently deletes a media item (photo / video)")
    static let deleting = NSLocalizedString("siteMedia.details.deleting", value: "Deleting...", comment: "Text displayed in HUD while a media item is being deleted.")
    static let deleted = NSLocalizedString("siteMedia.details.deleted", value: "Deleted!", comment: "Text displayed in HUD after successfully deleting a media item")
    static let unableToDeleteMedia = NSLocalizedString("siteMedia.details.unableToDeleteMedia", value: "Unable to delete media item.", comment: "Text displayed in HUD if there was an error attempting to delete a media item.")
    static let unableToSaveMedia = NSLocalizedString("siteMedia.details.unableToSaveMedia", value: "Unable to save media item.", comment: "Text displayed in HUD when a media item's metadata (title, etc) couldn't be saved.")

    enum Hints {
        static let imageTitle = NSLocalizedString("siteMedia.hints.imageTitle", value: "Image title", comment: "Hint for image title on image settings.")
        static let imageCaption = NSLocalizedString("siteMedia.hints.imageCaption", value: "Image Caption", comment: "Hint for image caption on image settings.")
        static let imageDescription = NSLocalizedString("siteMedia.hints.imageDescription", value: "Image Description", comment: "Hint for image description on image settings.")
        static let imageAlt = NSLocalizedString("siteMedia.hints.imageAlt", value: "Image Alt", comment: "Hint for image alt on image settings.")
    }
}
