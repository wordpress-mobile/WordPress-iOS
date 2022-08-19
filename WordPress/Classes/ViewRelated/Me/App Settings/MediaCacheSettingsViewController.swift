import Foundation

class MediaCacheSettingsViewController: UITableViewController {
    fileprivate var handler: ImmuTableViewHandler?

    override init(style: UITableView.Style) {
        super.init(style: .insetGrouped)
        handler = ImmuTableViewHandler(takeOver: self)
        navigationItem.title = NSLocalizedString("Media Cache", comment: "Media Cache title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .plain)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            TextRow.self,
            BrandedNavigationRow.self
            ], tableView: self.tableView)

        reloadViewModel()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMediaCacheSize()
    }

    // MARK: - Model mapping

    fileprivate func reloadViewModel() {
        handler?.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        let mediaCacheRow = TextRow(
            title: NSLocalizedString("Media Cache Size",
                                     comment: "Label for size of media cache in the app."),
            value: mediaCacheRowDescription)

        let mediaClearCacheRow = BrandedNavigationRow(
            title: NSLocalizedString("Clear Device Media Cache",
                                     comment: "Label for button that clears all media cache."),
            action: { [weak self] row in
                self?.clearMediaCache()
            },
            accessibilityIdentifier: "mediaClearCacheButton")

        return ImmuTable(sections: [
            ImmuTableSection(rows: [
                mediaCacheRow
            ]),
            ImmuTableSection(rows: [
                mediaClearCacheRow
            ]),
        ])
    }

    // MARK: - Media cache methods

    fileprivate enum MediaCacheSettingsStatus {
        case calculatingSize
        case clearingCache
        case unknown
        case empty
    }

    fileprivate var mediaCacheRowDescription = "" {
        didSet {
            reloadViewModel()
        }
    }

    fileprivate func setMediaCacheRowDescription(allocatedSize: Int64?) {
        guard let allocatedSize = allocatedSize else {
            setMediaCacheRowDescription(status: .unknown)
            return
        }
        if allocatedSize == 0 {
            setMediaCacheRowDescription(status: .empty)
            return
        }
        mediaCacheRowDescription = ByteCountFormatter.string(fromByteCount: allocatedSize, countStyle: ByteCountFormatter.CountStyle.file)
    }

    fileprivate func setMediaCacheRowDescription(status: MediaCacheSettingsStatus) {
        switch status {
        case .clearingCache:
            mediaCacheRowDescription = NSLocalizedString("Clearing...", comment: "Label for size of media while it's being cleared.")
        case .calculatingSize:
            mediaCacheRowDescription = NSLocalizedString("Calculating...", comment: "Label for size of media while it's being calculated.")
        case .unknown:
            mediaCacheRowDescription = NSLocalizedString("Unknown", comment: "Label for size of media when it's not possible to calculate it.")
        case .empty:
            mediaCacheRowDescription = NSLocalizedString("Empty", comment: "Label for size of media when the cache is empty.")
        }
    }

    fileprivate func updateMediaCacheSize() {
        setMediaCacheRowDescription(status: .calculatingSize)
        MediaFileManager.calculateSizeOfMediaDirectories { [weak self] (allocatedSize) in
            self?.setMediaCacheRowDescription(allocatedSize: allocatedSize)
        }
    }

    fileprivate func clearMediaCache() {
        WPAnalytics.track(.appSettingsClearMediaCacheTapped)

        setMediaCacheRowDescription(status: .clearingCache)
        MediaFileManager.clearAllMediaCacheFiles(onCompletion: { [weak self] in
            self?.updateMediaCacheSize()
            }, onError: { [weak self] (error) in
                self?.updateMediaCacheSize()
        })
    }
}
