import AVKit
import Combine
import UIKit
import Gridicons
import SVProgressHUD
import WordPressShared
import QuickLook

/// Displays an image preview and metadata for a single Media asset.
///
final class MediaItemViewController: UITableViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
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
    private lazy var headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: 320)

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

        ImmuTable.registerRows([TextRow.self, EditableTextRow.self, MediaDocumentRow.self], tableView: tableView)

        updateViewModel()
        updateNavigationItem()
        updateTitle()
    }

    private func updateTitle() {
        title = mediaMetadata.title
    }

    private func updateViewModel() {
        let titleRow = editableRowIfSupported(title: NSLocalizedString("Title", comment: "Noun. Label for the title of a media asset (image / video)"),
                                              value: mediaMetadata.title,
                                              action: editTitle())
        let captionRow = editableRowIfSupported(title: NSLocalizedString("Caption", comment: "Noun. Label for the caption for a media asset (image / video)"),
                                                value: mediaMetadata.caption,
                                                action: editCaption())
        let descRow = editableRowIfSupported(title: NSLocalizedString("Description", comment: "Label for the description for a media asset (image / video)"),
                                             value: mediaMetadata.desc,
                                             action: editDescription())
        let altRow = editableRowIfSupported(title: NSLocalizedString("Alt Text", comment: "Label for the alt for a media asset (image)"),
                                            value: mediaMetadata.alt,
                                            action: editAlt())

        var mediaInfoRows = [titleRow, captionRow, descRow]
        if media.mediaType == .image {
            mediaInfoRows.append(altRow)
        }

        viewModel = ImmuTable(sections: [
            ImmuTableSection(headerText: nil, rows: mediaInfoRows, footerText: nil),
            ImmuTableSection(headerText: nil, rows: metadataRows, footerText: nil)
        ])

        headerView.configure(with: media)
        headerHeightConstraint.isActive = true
        tableView.tableHeaderView = headerView

        headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapHeaderView)))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        headerHeightConstraint.constant = view.bounds.height * 0.6
        tableView.sizeToFitHeaderView()
    }

    #warning("TODO: remove")

//    private var headerRow: ImmuTableRow {
//        switch media.mediaType {
//        case .image, .video:
//            return MediaImageTableHeaderViewModel(media: media, action: { [weak self] row in
//                guard let media = self?.media else { return }
//
//                switch media.mediaType {
//                case .image:
//                    if self?.isMediaLoaded() == true {
//                        self?.presentImageViewControllerForMedia()
//                    }
//                case .video:
//                    self?.presentVideoViewControllerForMedia()
//                default: break
//                }
//            })
//        default:
//            return MediaDocumentRow(media: media, action: { [weak self] _ in
//                guard let media = self?.media else { return }
//
//                // We're currently not presenting previews for audio until
//                // we can resolve an auth issue. @frosty 2017-05-02
//                if media.mediaType != .audio {
//                    self?.presentDocumentViewControllerForMedia()
//                }
//            })
//        }
//    }

    private var metadataRows: [ImmuTableRow] {
        let presenter = MediaMetadataPresenter(media: media)

        var rows = [ImmuTableRow]()
        rows.append(TextRow(title: NSLocalizedString("File name", comment: "Label for the file name for a media asset (image / video)"), value: media.filename ?? ""))
        rows.append(TextRow(title: NSLocalizedString("File type", comment: "Label for the file type (.JPG, .PNG, etc) for a media asset (image / video)"), value: presenter.fileType ?? ""))

        switch media.mediaType {
        case .image, .video:
            rows.append(TextRow(title: NSLocalizedString("Dimensions", comment: "Label for the dimensions in pixels for a media asset (image / video)"), value: presenter.dimensions))
        default: break
        }

        rows.append(TextRow(title: NSLocalizedString("Uploaded", comment: "Label for the date a media asset (image / video) was uploaded"), value: media.creationDate?.toMediumString() ?? ""))

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
        SVProgressHUD.showError(withStatus: NSLocalizedString("This media item has been deleted.", comment: "Message displayed in Media Library if the user attempts to edit a media asset (image / video) after it has been deleted."))
        navigationController?.popViewController(animated: true)
    }

    private func updateNavigationItem() {
        let shareItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(shareTapped))
        shareItem.accessibilityLabel = NSLocalizedString("Share", comment: "Accessibility label for share buttons in nav bars")

        let trashItem = UIBarButtonItem(image: UIImage(systemName: "trash"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(trashTapped))
        trashItem.accessibilityLabel = NSLocalizedString("Trash", comment: "Accessibility label for trash buttons in nav bars")

        if media.blog.supports(.mediaDeletion) {
            navigationItem.rightBarButtonItems = [ shareItem, trashItem ]
        } else {
            navigationItem.rightBarButtonItems = [ shareItem ]
        }
    }

    private var isLoadingFullscreenImage = false
    private var previewURL: NSURL?

#warning("TODO: reimplemnet / add support for video")
    @objc private func didTapHeaderView() {
        guard !isLoadingFullscreenImage else { return }
        isLoadingFullscreenImage = true
        Task {
            if let data = try? await MediaImageService.shared.imageData(for: media) {
                let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(media.filename ?? "image")

                try? data.write(to: localURL)
                previewURL = localURL as NSURL

                 let appearance = UINavigationBar.appearance(whenContainedInInstancesOf: [QLPreviewController.self])
                appearance.isTranslucent = true // important!

                let preview = QLPreviewController()
                preview.dataSource = self
                preview.delegate = self
//                preview.modalTransitionStyle = .crossDissolve
                present(preview, animated: true)

#warning("TODO: add error handling")
                //
                //            headerView.loadingIndicator.startAnimating()
                //                if let
                //                    let fileURLs = try await Media.downloadRemoteData(for: [media], blog: media.blog)
                //                    self.share(fileURLs, sender: sender)
                //                } catch {
                //                    SVProgressHUD.showError(withStatus: SiteMediaViewController.sharingFailureMessage)
                //                }
            }
            headerView.loadingIndicator.stopAnimating()
            isLoadingFullscreenImage = false
        }
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }

    #warning("TODO: rework WPImageViewController and add nice transition animation instead of using QLPreviewController (?)")
    #warning("TODO: disable editing? or keep?")
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewURL!
    }

    func previewController(_ controller: QLPreviewController, transitionViewFor item: QLPreviewItem) -> UIView? {
        headerView.imageView
    }

    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        .disabled
    }

#warning("TODO: remove or update")
    private func presentVideoViewControllerForMedia() {
        media.videoAsset { [weak self] asset, error in
            if let asset = asset,
                let controller = self?.videoViewControllerForAsset(asset) {

                controller.modalTransitionStyle = .crossDissolve

                self?.present(controller, animated: true, completion: {
                    controller.player?.play()
                })
            } else if let _ = error {
                SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to load video.", comment: "Error shown when the app fails to load a video from the user's media library."))
            }
        }
    }

    private var documentInteractionController: UIDocumentInteractionController?

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
                                                message: NSLocalizedString("Are you sure you want to permanently delete this item?", comment: "Message prompting the user to confirm that they want to permanently delete a media item. Should match Calypso."), preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Verb. Button title. Tapping cancels an action."))
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Delete", comment: "Title for button that permanently deletes a media item (photo / video)"), handler: { action in
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
        SVProgressHUD.show(withStatus: NSLocalizedString("Deleting...", comment: "Text displayed in HUD while a media item is being deleted."))

        let service = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.delete(media, success: { [weak self] in
            WPAppAnalytics.track(.mediaLibraryDeletedItems, withProperties: ["number_of_items_deleted": 1], with: self?.media.blog)
            SVProgressHUD.showSuccess(withStatus: NSLocalizedString("Deleted!", comment: "Text displayed in HUD after successfully deleting a media item"))
        }, failure: { error in
            SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to delete media item.", comment: "Text displayed in HUD if there was an error attempting to delete a media item."))
        })
    }

    private func saveChanges() {
        mediaMetadata.update(media)

        let service = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.update(media, success: { [weak self] in
            WPAppAnalytics.track(.mediaLibraryEditedItemMetadata, with: self?.media.blog)
        }, failure: { _ in
            SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to save media item.", comment: "Text displayed in HUD when a media item's metadata (title, etc) couldn't be saved."))
        })
    }

    private func editTitle() -> ((ImmuTableRow) -> ()) {
        return { [weak self] row in
            let editableRow = row as! EditableTextRow
            self?.pushSettingsController(for: editableRow, hint: NSLocalizedString("Image title", comment: "Hint for image title on image settings."),
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
            self?.pushSettingsController(for: editableRow, hint: NSLocalizedString("Image Caption", comment: "Hint for image caption on image settings."),
                                        onValueChanged: { value in
                self?.mediaMetadata.caption = value
                self?.reloadViewModel()
            })
        }
    }

    private func editDescription() -> ((ImmuTableRow) -> ()) {
        return { [weak self] row in
            let editableRow = row as! EditableTextRow
            self?.pushSettingsController(for: editableRow, hint: NSLocalizedString("Image Description", comment: "Hint for image description on image settings."),
                                        onValueChanged: { value in
                self?.mediaMetadata.desc  = value
                self?.reloadViewModel()
            })
        }
    }

    private func editAlt() -> ((ImmuTableRow) -> ()) {
        return { [weak self] row in
            let editableRow = row as! EditableTextRow
            self?.pushSettingsController(for: editableRow, hint: NSLocalizedString("Image Alt", comment: "Hint for image alt on image settings."),
                                         onValueChanged: { value in
                                            self?.mediaMetadata.alt  = value
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

    private func share(media: Any, sender: UIBarButtonItem) {
        share([media], sender: sender)
    }

    private func share(_ activityItems: [Any], sender: UIBarButtonItem) {
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.modalPresentationStyle = .popover
        activityController.popoverPresentationController?.barButtonItem = sender
        activityController.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            if completed {
                WPAppAnalytics.track(.mediaLibrarySharedItemLink, with: self?.media.blog)
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
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let row = viewModel.rowAtIndexPath(indexPath)
        if row is MediaDocumentRow && media.mediaType == .audio {
            return false
        }

        return true
    }

    #warning("TODO :cleanup")
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = viewModel.rowAtIndexPath(indexPath)
        if let customHeight = type(of: row).customHeight {
            return CGFloat(customHeight)
        } else if row is MediaImageTableHeaderViewModel {
            return UITableView.automaticDimension
        }

        return tableView.rowHeight
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = viewModel.rowAtIndexPath(indexPath)
        if let customHeight = type(of: row).customHeight {
            return CGFloat(customHeight)
        } else if row is MediaImageTableHeaderViewModel {
            return view.readableContentGuide.layoutFrame.width
        }

        return tableView.rowHeight
    }

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
