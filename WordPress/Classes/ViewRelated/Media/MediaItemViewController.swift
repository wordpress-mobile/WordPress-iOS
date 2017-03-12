import UIKit
import Gridicons
import SVProgressHUD
import WordPressShared

/// Displays an image preview and metadata for a single Media asset.
///
class MediaItemViewController: UITableViewController, ImmuTablePresenter {
    let media: Media
    weak var dataSource: MediaLibraryPickerDataSource? = nil

    var viewModel: ImmuTable!

    init(media: Media, dataSource: MediaLibraryPickerDataSource) {
        self.media = media
        self.dataSource = dataSource

        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unregisterChangeObserver()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = media.title

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([TextRow.self, EditableTextRow.self, MediaImageRow.self],
                               tableView: tableView)
        setupViewModel()
        setupNavigationItem()

        registerChangeObserver()
    }

    private func setupViewModel() {
        let presenter = MediaMetadataPresenter(media: media)

        viewModel = ImmuTable(sections: [
            ImmuTableSection(rows: [
                MediaImageRow(media: media, action: { [weak self] row in
                    self?.presentImageViewControllerForMedia()
                }) ]),
            ImmuTableSection(headerText: nil, rows: [
                EditableTextRow(title: NSLocalizedString("Title", comment: "Noun. Label for the title of a media asset (image / video)"), value: media.title, action: nil),
                EditableTextRow(title: NSLocalizedString("Caption", comment: "Noun. Label for the caption for a media asset (image / video)"), value: media.caption, action: nil),
                EditableTextRow(title: NSLocalizedString("Description", comment: "Label for the description for a media asset (image / video)"), value: media.desc, action: nil)
                ], footerText: nil),
            ImmuTableSection(headerText: NSLocalizedString("Metadata", comment: "Title of section containing image / video metadata such as size and file type"), rows: [
                TextRow(title: NSLocalizedString("File name", comment: "Label for the file name for a media asset (image / video)"), value: media.filename),
                TextRow(title: NSLocalizedString("File type", comment: "Label for the file type (.JPG, .PNG, etc) for a media asset (image / video)"), value: presenter.fileType),
                TextRow(title: NSLocalizedString("Dimensions", comment: "Label for the dimensions in pixels for a media asset (image / video)"), value: presenter.dimensions),
                TextRow(title: NSLocalizedString("Uploaded", comment: "Label for the date a media asset (image / video) was uploaded"), value: media.creationDate.mediumString())
                ], footerText: nil)
            ])
    }

    private func setupNavigationItem() {
        let shareItem = UIBarButtonItem(image: Gridicon.iconOfType(.shareIOS),
                                        style: .plain,
                                        target: self,
                                        action: #selector(shareTapped(_:)))

        let trashItem = UIBarButtonItem(image: Gridicon.iconOfType(.trash),
                                        style: .plain,
                                        target: self,
                                        action: #selector(trashTapped(_:)))

        navigationItem.rightBarButtonItems = [ shareItem, trashItem ]
    }

    private func presentImageViewControllerForMedia() {
        if let controller = WPImageViewController(media: self.media) {
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen

            self.present(controller, animated: true, completion: nil)
        }
    }

    // MARK: - Media Library Change Observer

    private var mediaLibraryChangeObserverKey: NSObjectProtocol? = nil

    private func registerChangeObserver() {
        assert(mediaLibraryChangeObserverKey == nil)

        // Listen out for changes to the media library – if the media item we're
        // displaying gets deleted, we'll pop ourselves off the stack.
        if let dataSource = dataSource {
            mediaLibraryChangeObserverKey = dataSource.registerChangeObserverBlock({ [weak self] _, _, _, _, _ in
                if let isDeleted = self?.media.isDeleted, isDeleted == true {
                    _ = self?.navigationController?.popViewController(animated: true)
                }
            })
        }
    }

    private func unregisterChangeObserver() {
        if let mediaLibraryChangeObserverKey = mediaLibraryChangeObserverKey {
            dataSource?.unregisterChangeObserver(mediaLibraryChangeObserverKey)
        }
    }

    // MARK: - Actions

    @objc private func shareTapped(_ sender: UIBarButtonItem) {
        if let url = URL(string: media.remoteURL) {
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
            _ = self.navigationController?.popViewController(animated: true)
        }, failure: { error in
            SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to delete media item.", comment: "Text displayed in HUD if there was an error attempting to delete a media item."))
        })
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
        addSubview(customImageView)
        customImageView.translatesAutoresizingMaskIntoConstraints = false
        customImageView.contentMode = .scaleAspectFit

        NSLayoutConstraint.activate([
            customImageView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            customImageView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            customImageView.topAnchor.constraint(equalTo: topAnchor),
            customImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

        customImageView.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
    }

    private func setupLoadingViews() {
        addSubview(activityMaskView)
        activityMaskView.translatesAutoresizingMaskIntoConstraints = false
        activityMaskView.backgroundColor = .black
        activityMaskView.alpha = 0.5

        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

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
            addPlaceholderImageFor(cell)
            loadImageFor(cell)
        }
    }

    func willDisplay(_ cell: UITableViewCell) {
        if let cell = cell as? ImageTableViewCell {
            cell.customImageView.backgroundColor = .black
        }
    }

    private func setAspectRatioFor(_ cell: ImageTableViewCell) {
        let width = CGFloat(media.width.floatValue)
        let height = CGFloat(media.height.floatValue)
        if (width > 0) {
            cell.targetAspectRatio = height / width
        }
    }

    private func addPlaceholderImageFor(_ cell: ImageTableViewCell) {
        if let url = media.absoluteLocalURL,
            let image = UIImage(contentsOfFile: url) {
            cell.customImageView.image = image
        } else if let url = media.absoluteThumbnailLocalURL,
            let image = UIImage(contentsOfFile: url) {
            cell.customImageView.image = image
        }
    }

    private func loadImageFor(_ cell: ImageTableViewCell) {
        cell.isLoading = true
        media.image(with: .zero,
                    completionHandler: { image, error in
                        DispatchQueue.main.async {
                            if let error = error, image == nil {
                                self.show(error)
                            } else if let image = image {
                                self.animateImageChange(image: image, for: cell)
                            }
                        }
        })
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
    var fileType: String {
        return (media.filename as NSString).pathExtension.uppercased()
    }
}
