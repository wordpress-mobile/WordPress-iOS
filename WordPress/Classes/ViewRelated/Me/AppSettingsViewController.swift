import Foundation
import UIKit
import WordPressShared
import WordPressComAnalytics
import SVProgressHUD

class AppSettingsViewController: UITableViewController {

    fileprivate var handler: ImmuTableViewHandler!

    // MARK: - Initialization

    override init(style: UITableViewStyle) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("App Settings", comment: "App Settings Title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            DestructiveButtonRow.self,
            TextRow.self,
            MediaSizingRow.self,
            SwitchRow.self,
            NavigationItemRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMediaCacheSize()
    }

    // MARK: - Model mapping

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        let mediaHeader = NSLocalizedString("Media", comment: "Title label for the media settings section in the app settings")
        let mediaSizingRow = MediaSizingRow(
            title: NSLocalizedString("Max Image Upload Size", comment: "Title for the image size settings option."),
            value: Int(MediaSettings().maxImageSizeSetting),
            onChange: mediaSizeChanged())

        let mediaRemoveLocation = SwitchRow(
            title: NSLocalizedString("Remove Location From Media", comment: "Option to enable the removal of location information/gps from photos and videos"),
            value: Bool(MediaSettings().removeLocationSetting),
            onChange: mediaRemoveLocationChanged(),
            accessibilityIdentifier: "removeLocationFromMediaToggle"
        )

        let mediaCacheRow = TextRow(title: NSLocalizedString("Media Cache Size", comment: "Label for size of media cache in the app."),
                                    value: mediaCacheRowDescription)

        let mediaClearCacheRow = DestructiveButtonRow(
            title: NSLocalizedString("Clear Media Cache", comment: "Label for button that clears all media cache."),
            action: { [weak self] row in
                self?.clearMediaCache()
            },
            accessibilityIdentifier: "mediaClearCacheButton")

        let editorSettings = EditorSettings()
        let editorHeader = NSLocalizedString("Editor", comment: "Title label for the editor settings section in the app settings")
        var editorRows = [ImmuTableRow]()
        let visualEditor = SwitchRow(
            title: NSLocalizedString("Visual Editor", comment: "Option to enable the visual editor"),
            value: editorSettings.visualEditorEnabled,
            onChange: visualEditorChanged(),
            accessibilityIdentifier: "visualEditorToggle"
        )
        editorRows.append(visualEditor)

        if editorSettings.nativeEditorAvailable && editorSettings.visualEditorEnabled {
            let nativeEditor = SwitchRow(
                title: NSLocalizedString("Native Editor", comment: "Option to enable the native visual editor"),
                value: editorSettings.nativeEditorEnabled,
                onChange: nativeEditorChanged(),
                accessibilityIdentifier: "nativeEditorToggle"
            )
            editorRows.append(nativeEditor)
        }

        let aboutHeader = NSLocalizedString("Other", comment: "Link to About section (contains info about the app)")
        let settingsRow = NavigationItemRow(
            title: NSLocalizedString("Open Device Settings", comment: "Opens iOS's Device Settings for WordPress App"),
            action: openApplicationSettings()
        )

        let aboutRow = NavigationItemRow(
            title: NSLocalizedString("About WordPress for iOS", comment: "Link to About screen for WordPress for iOS"),
            action: pushAbout()
        )

        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: mediaHeader,
                rows: [
                    mediaSizingRow,
                    mediaRemoveLocation,
                    mediaCacheRow,
                    mediaClearCacheRow
                ],
                footerText: nil),
            ImmuTableSection(
                headerText: editorHeader,
                rows: editorRows,
                footerText: nil),
            ImmuTableSection(
                headerText: aboutHeader,
                rows: [
                    settingsRow,
                    aboutRow
                ],
                footerText: nil)
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
        MediaService.calculateSizeOfLocalMediaDirectory { [weak self] (allocatedSize) in
            self?.setMediaCacheRowDescription(allocatedSize: allocatedSize)
        }
    }

    fileprivate func clearMediaCache() {
        setMediaCacheRowDescription(status: .clearingCache)
        MediaService.clearCachedFilesFromLocalMediaDirectory(onCompletion: { [weak self] in
            self?.updateMediaCacheSize()
            }, onError: { [weak self] (error) in
                self?.updateMediaCacheSize()
        })
    }

    // MARK: - Actions

    func mediaSizeChanged() -> (Int) -> Void {
        return { value in
            MediaSettings().maxImageSizeSetting = value
            ShareExtensionService.configureShareExtensionMaximumMediaDimension(value)
        }
    }

    func mediaRemoveLocationChanged() -> (Bool) -> Void {
        return { value in
            MediaSettings().removeLocationSetting = value
        }
    }

    func visualEditorChanged() -> (Bool) -> Void {
        return { [weak self] enabled in
            if enabled {
                WPAnalytics.track(.editorToggledOn)
            } else {
                WPAnalytics.track(.editorToggledOff)
            }
            EditorSettings().visualEditorEnabled = enabled
            self?.reloadViewModel()
        }
    }

    func nativeEditorChanged() -> (Bool) -> Void {
        return { enabled in
            EditorSettings().nativeEditorEnabled = enabled
        }
    }

    func pushAbout() -> ImmuTableAction {
        return { [weak self] row in
            let controller = AboutViewController()
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func openApplicationSettings() -> ImmuTableAction {
        return { [weak self] row in
            if let targetURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(targetURL)

            } else {
                assertionFailure("Couldn't unwrap Settings URL")
            }

            self?.tableView.deselectSelectedRowWithAnimation(true)
        }
    }
}

fileprivate struct MediaSizingRow: ImmuTableRow {
    typealias CellType = MediaSizeSliderCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "MediaSizeSliderCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()
    static let customHeight: Float? = CellType.height

    let title: String
    let value: Int
    let onChange: (Int) -> Void

    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.title = title
        cell.value = value
        cell.onChange = onChange
        cell.selectionStyle = .none

        (cell.minValue, cell.maxValue) = MediaSettings().allowedImageSizeRange
    }
}
