import UIKit
import Gridicons
import SVProgressHUD
import WordPressShared

/// Displays an image preview and metadata for a single Media asset.
///
class MediaItemViewController: UITableViewController {
    let media: Media


    fileprivate var viewModel: ImmuTable!
    fileprivate var mediaMetadata: MediaMetadata {
        didSet {
            updateNavigationItem()
        }
    }

    init(media: Media) {
        self.media = media

        self.mediaMetadata = MediaMetadata(media: media)

        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([TextRow.self, EditableTextRow.self, MediaImageRow.self],
                               tableView: tableView)

        updateViewModel()
        updateNavigationItem()
        updateTitle()
    }

    private func updateTitle() {
        title = mediaMetadata.title
    }

    private func updateViewModel() {
        let presenter = MediaMetadataPresenter(media: media)

        viewModel = ImmuTable(sections: [
            ImmuTableSection(rows: [
                MediaImageRow(media: media, action: { [weak self] row in
                    self?.presentImageViewControllerForMedia()
                }) ]),
            ImmuTableSection(headerText: nil, rows: [
                editableRowIfSupported(title: NSLocalizedString("Title", comment: "Noun. Label for the title of a media asset (image / video)"), value: mediaMetadata.title, action: editTitle()),
                editableRowIfSupported(title: NSLocalizedString("Caption", comment: "Noun. Label for the caption for a media asset (image / video)"), value: mediaMetadata.caption, action: editCaption()),
                editableRowIfSupported(title: NSLocalizedString("Description", comment: "Label for the description for a media asset (image / video)"), value: mediaMetadata.desc, action: editDescription())
                ], footerText: nil),
            ImmuTableSection(headerText: NSLocalizedString("Metadata", comment: "Title of section containing image / video metadata such as size and file type"), rows: [
                TextRow(title: NSLocalizedString("File name", comment: "Label for the file name for a media asset (image / video)"), value: media.filename ?? ""),
                TextRow(title: NSLocalizedString("File type", comment: "Label for the file type (.JPG, .PNG, etc) for a media asset (image / video)"), value: presenter.fileType ?? ""),
                TextRow(title: NSLocalizedString("Dimensions", comment: "Label for the dimensions in pixels for a media asset (image / video)"), value: presenter.dimensions),
                TextRow(title: NSLocalizedString("Uploaded", comment: "Label for the date a media asset (image / video) was uploaded"), value: media.creationDate.mediumString())
                ], footerText: nil)
            ])
    }

    private func editableRowIfSupported(title: String, value: String, action: @escaping ((ImmuTableRow) -> ())) -> ImmuTableRow {
        if media.blog.supports(BlogFeature.mediaMetadataEditing) {
            return EditableTextRow(title: title, value: value, action: action)
        } else {
            return TextRow(title: title, value: value)
        }
    }

    private func reloadViewModel() {
        updateViewModel()
        tableView.reloadData()
    }

    private func updateNavigationItem() {
        if mediaMetadata.matches(media) {
            navigationItem.leftBarButtonItem = nil
            let shareItem = UIBarButtonItem(image: Gridicon.iconOfType(.shareIOS),
                                            style: .plain,
                                            target: self,
                                            action: #selector(shareTapped(_:)))

            let trashItem = UIBarButtonItem(image: Gridicon.iconOfType(.trash),
                                            style: .plain,
                                            target: self,
                                            action: #selector(trashTapped(_:)))

            if media.blog.supports(.mediaDeletion) {
                navigationItem.rightBarButtonItems = [ shareItem, trashItem ]
            } else {
                navigationItem.rightBarButtonItems = [ shareItem ]
            }
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
            navigationItem.rightBarButtonItems = [ UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped)) ]
        }
    }

    private func presentImageViewControllerForMedia() {
        if let controller = WPImageViewController(media: self.media) {
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen

            self.present(controller, animated: true, completion: nil)
        }
    }

    // MARK: - Actions

    @objc private func shareTapped(_ sender: UIBarButtonItem) {
        if let remoteURLStr = media.remoteURL, let url = URL(string: remoteURLStr) {
            let activityController = UIActivityViewController(activityItems: [ url ], applicationActivities: nil)
                activityController.modalPresentationStyle = .popover
                activityController.popoverPresentationController?.barButtonItem = sender
                present(activityController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: nil, message: NSLocalizedString("Unable to get URL for media item.", comment: "Error message displayed when we were unable to copy the URL for an item in the user's media library."), preferredStyle: .alert)
            alertController.addCancelActionWithTitle(NSLocalizedString("Dismiss", comment: "Verb. User action to dismiss error alert when failing to share media."))
            present(alertController, animated: true, completion: nil)
        }
    }

    @objc private func trashTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil,
                                                message: NSLocalizedString("Are you sure you want to permanently delete this item?", comment: "Message prompting the user to confirm that they want to permanently delete a media item. Should match Calypso."), preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: ""))
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Delete", comment: "Title for button that permanently deletes a media item (photo / video)"), handler: { action in
            self.deleteMediaItem()
        })

        present(alertController, animated: true, completion: nil)
    }

    private func deleteMediaItem() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)
        SVProgressHUD.show(withStatus: NSLocalizedString("Deleting...", comment: "Text displayed in HUD while a media item is being deleted."))

        let service = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.delete(media, success: {
            SVProgressHUD.showSuccess(withStatus: NSLocalizedString("Deleted!", comment: "Text displayed in HUD after successfully deleting a media item"))
        }, failure: { error in
            SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to delete media item.", comment: "Text displayed in HUD if there was an error attempting to delete a media item."))
        })
    }

    @objc private func cancelTapped() {
        mediaMetadata = MediaMetadata(media: media)
        reloadViewModel()
        updateTitle()
    }

    @objc private func saveTapped() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)
        SVProgressHUD.show(withStatus: NSLocalizedString("Saving...", comment: "Text displayed in HUD while a media item's metadata (title, etc) is being saved."))

        mediaMetadata.update(media)

        let service = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.update(media, success: {
            SVProgressHUD.showSuccess(withStatus: NSLocalizedString("Saved!", comment: "Text displayed in HUD when a media item's metadata (title, etc) is saved successfully."))
            self.updateNavigationItem()
        }, failure: { error in
            SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to save media item.", comment: "Text displayed in HUD when a media item's metadata (title, etc) couldn't be saved."))
            self.updateNavigationItem()
        })
    }

    private func editTitle() -> ((ImmuTableRow) -> ()) {
        return { row in
            let editableRow = row as! EditableTextRow
            self.pushSettingsController(for: editableRow, hint: NSLocalizedString("Image title", comment: "Hint for image title on image settings."),
                                        onValueChanged: { value in
                self.title = value
                self.mediaMetadata.title = value
                self.reloadViewModel()
            })
        }
    }

    private func editCaption() -> ((ImmuTableRow) -> ()) {
        return { row in
            let editableRow = row as! EditableTextRow
            self.pushSettingsController(for: editableRow, hint: NSLocalizedString("Image Caption", comment: "Hint for image caption on image settings."),
                                        onValueChanged: { value in
                self.mediaMetadata.caption = value
                self.reloadViewModel()
            })
        }
    }

    private func editDescription() -> ((ImmuTableRow) -> ()) {
        return { row in
            let editableRow = row as! EditableTextRow
            self.pushSettingsController(for: editableRow, hint: NSLocalizedString("Image Description", comment: "Hint for image description on image settings."),
                                        onValueChanged: { value in
                self.mediaMetadata.desc  = value
                self.reloadViewModel()
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
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = viewModel.rowAtIndexPath(indexPath)
        if let customHeight = type(of: row).customHeight {
            return CGFloat(customHeight)
        } else if row is MediaImageRow {
            return UITableViewAutomaticDimension
        }

        return tableView.rowHeight
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = viewModel.rowAtIndexPath(indexPath)
        if row is MediaImageRow {
            return view.readableContentGuide.layoutFrame.width
        }

        return tableView.rowHeight
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let row = viewModel.rowAtIndexPath(indexPath) as? MediaImageRow {
            row.willDisplay(cell)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = viewModel.rowAtIndexPath(indexPath)
        row.action?(row)
    }
}

open class ImageTableViewCell: WPTableViewCell {
    let customImageView = UIImageView()
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
    let activityMaskView = UIView()

    // MARK: - Initializers
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    public convenience init() {
        self.init(style: .default, reuseIdentifier: nil)
    }

    func commonInit() {
        setupImageView()
        setupLoadingViews()
    }

    private func setupImageView() {
        contentView.addSubview(customImageView)
        customImageView.translatesAutoresizingMaskIntoConstraints = false
        customImageView.contentMode = .scaleAspectFit

        NSLayoutConstraint.activate([
            customImageView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            customImageView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            customImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            customImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

        customImageView.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
    }

    private func setupLoadingViews() {
        contentView.addSubview(activityMaskView)
        activityMaskView.translatesAutoresizingMaskIntoConstraints = false
        activityMaskView.backgroundColor = .black
        activityMaskView.alpha = 0.5

        contentView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            activityMaskView.leadingAnchor.constraint(equalTo: customImageView.leadingAnchor),
            activityMaskView.trailingAnchor.constraint(equalTo: customImageView.trailingAnchor),
            activityMaskView.topAnchor.constraint(equalTo: customImageView.topAnchor),
            activityMaskView.bottomAnchor.constraint(equalTo: customImageView.bottomAnchor)
        ])
    }

    private var aspectRatioConstraint: NSLayoutConstraint? = nil

    var targetAspectRatio: CGFloat {
        set {
            if let aspectRatioConstraint = aspectRatioConstraint {
                customImageView.removeConstraint(aspectRatioConstraint)
            }

            aspectRatioConstraint = customImageView.heightAnchor.constraint(equalTo: customImageView.widthAnchor, multiplier: newValue, constant: 1.0)
            aspectRatioConstraint?.priority = UILayoutPriorityDefaultHigh
            aspectRatioConstraint?.isActive = true
        }
        get {
            return aspectRatioConstraint?.multiplier ?? 0
        }
    }

    // MARK: - Loading

    var isLoading: Bool = false {
        didSet {
            if isLoading {
                activityMaskView.alpha = 0.5
                activityIndicator.startAnimating()
            } else {
                activityMaskView.alpha = 0
                activityIndicator.stopAnimating()
            }
        }
    }
}

struct MediaImageRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(ImageTableViewCell.self)

    let media: Media
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)

        if let cell = cell as? ImageTableViewCell {
            setAspectRatioFor(cell)
            loadImageFor(cell)
        }
    }

    func willDisplay(_ cell: UITableViewCell) {
        if let cell = cell as? ImageTableViewCell {
            cell.customImageView.backgroundColor = .black
        }
    }

    private func setAspectRatioFor(_ cell: ImageTableViewCell) {
        guard let width = media.width, let height = media.height, width.floatValue > 0 else {
            return
        }
        cell.targetAspectRatio = CGFloat(height.floatValue) / CGFloat(width.floatValue)
    }

    private func addPlaceholderImageFor(_ cell: ImageTableViewCell) {
        if let url = media.absoluteLocalURL,
            let image = UIImage(contentsOfFile: url.path) {
            cell.customImageView.image = image
        } else if let url = media.absoluteThumbnailLocalURL,
            let image = UIImage(contentsOfFile: url.path) {
            cell.customImageView.image = image
        }
    }

    private func loadImageFor(_ cell: ImageTableViewCell) {
        if !cell.isLoading && cell.customImageView.image == nil {
            addPlaceholderImageFor(cell)

            cell.isLoading = true
            media.image(with: .zero,
                        completionHandler: { image, error in
                            DispatchQueue.main.async {
                                if let error = error, image == nil {
                                    cell.isLoading = false
                                    self.show(error)
                                } else if let image = image {
                                    self.animateImageChange(image: image, for: cell)
                                }
                            }
            })
        }
    }

    private func show(_ error: Error) {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("There was a problem loading the media item.",
                                                                                       comment: "Error message displayed when the Media Library is unable to load a full sized preview of an item."), preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("Dismiss", comment: "Verb. User action to dismiss error alert when failing to load media ite,."))
        alertController.presentFromRootViewController()
    }

    private func animateImageChange(image: UIImage, for cell: ImageTableViewCell) {
        UIView.transition(with: cell.customImageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            cell.isLoading = false
            cell.customImageView.image = image
        }, completion: nil)
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

        return "\(width) ✕ \(height)"
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

    init(media: Media) {
        title = media.title ?? ""
        caption = media.caption ?? ""
        desc = media.desc ?? ""
    }

    /// - returns: True if this metadata's fields match those
    /// of the specified Media object.
    func matches(_ media: Media) -> Bool {
        return title == media.title
            && caption == media.caption
            && desc == media.desc
    }

    /// Update the metadata fields of the specified Media object
    /// to match this metadata's fields.
    func update(_ media: Media) {
        media.title = title
        media.caption = caption
        media.desc = desc
    }
}
