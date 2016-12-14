import Foundation
import UIKit
import WordPressShared
import WordPressComAnalytics
import SVProgressHUD

class AppSettingsViewController: UITableViewController {

    private var handler: ImmuTableViewHandler!
    // MARK: - Initialization

    override init(style: UITableViewStyle) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("App Settings", comment: "App Settings Title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .Grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            DestructiveButtonRow.self,
            TextRow.self,
            MediaSizeRow.self,
            SwitchRow.self,
            NavigationItemRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        handler.viewModel = tableViewModel()

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.handler.viewModel = self.tableViewModel()
    }

    // MARK: - Model mapping

    func tableViewModel() -> ImmuTable {
        let mediaHeader = NSLocalizedString("Media", comment: "Title label for the media settings section in the app settings")
        let uploadSize = MediaSizeRow(
            title: NSLocalizedString("Max Image Upload Size", comment: "Title for the image size settings option."),
            value: Int(MediaSettings().maxImageSizeSetting),
            onChange: mediaSizeChanged())

        let mediaRemoveLocation = SwitchRow(
            title: NSLocalizedString("Remove Location From Media", comment: "Option to enable the removal of location information/gps from photos and videos"),
            value: Bool(MediaSettings().removeLocationSetting),
            onChange: mediaRemoveLocationChanged()
        )

        var mediaSizeString = NSLocalizedString("Unknown", comment: "Label for size of media when it's not possible to calculate it.")
        let fileManager = NSFileManager()
        if let mediaSize = try? fileManager.allocatedSizeOf(directoryURL: MediaService.urlForMediaDirectory()) {
            if mediaSize == 0 {
                mediaSizeString = NSLocalizedString("Empty", comment: "Label for size of media when the cache is empty.")
            } else {
                mediaSizeString = NSByteCountFormatter.stringFromByteCount(mediaSize, countStyle: NSByteCountFormatterCountStyle.File)
            }
        }
        let mediaSizeRow = TextRow(title: NSLocalizedString("Media Cache Size", comment: "Label for size of media cache in the app."),
                                   value: mediaSizeString)

        let mediaClearCacheRow = DestructiveButtonRow(title: NSLocalizedString("Clear Media Cache", comment: "Label for button that clears all media cache."),
                                                      action: { row in
                                                        MediaService.cleanMediaCacheFolder()
                                                        SVProgressHUD.showSuccessWithStatus(NSLocalizedString("Media Cache cleaned", comment: "Label for message that confirms cleaning of media cache."))
                                                        self.handler.viewModel = self.tableViewModel()
                                                        self.tableView.reloadData()
        })

        let editorSettings = EditorSettings()
        let editorHeader = NSLocalizedString("Editor", comment: "Title label for the editor settings section in the app settings")
        var editorRows = [ImmuTableRow]()
        let visualEditor = SwitchRow(
            title: NSLocalizedString("Visual Editor", comment: "Option to enable the visual editor"),
            value: editorSettings.visualEditorEnabled,
            onChange: visualEditorChanged()
        )
        editorRows.append(visualEditor)

        if FeatureFlag.NativeEditor.enabled && editorSettings.visualEditorEnabled {
            let nativeEditor = SwitchRow(
                title: NSLocalizedString("Native Editor", comment: "Option to enable the native visual editor"),
                value: editorSettings.nativeEditorEnabled,
                onChange: nativeEditorChanged()
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
                    uploadSize,
                    mediaRemoveLocation,
                    mediaSizeRow,
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


    // MARK: - Actions

    func mediaSizeChanged() -> Int -> Void {
        return { value in
            MediaSettings().maxImageSizeSetting = value
            ShareExtensionService.configureShareExtensionMaximumMediaDimension(value)
        }
    }

    func mediaRemoveLocationChanged() -> Bool -> Void {
        return { value in
            MediaSettings().removeLocationSetting = value
        }
    }

    func visualEditorChanged() -> Bool -> Void {
        return { enabled in
            if enabled {
                WPAnalytics.track(.EditorToggledOn)
            } else {
                WPAnalytics.track(.EditorToggledOff)
            }
            EditorSettings().visualEditorEnabled = enabled
            self.handler.viewModel = self.tableViewModel()
        }
    }

    func nativeEditorChanged() -> Bool -> Void {
        return { enabled in
            EditorSettings().nativeEditorEnabled = enabled
        }
    }

    func pushAbout() -> ImmuTableAction {
        return { [unowned self] row in
            let controller = AboutViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func openApplicationSettings() -> ImmuTableAction {
        return { row in
            if let targetURL = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(targetURL)
            } else {
                assertionFailure("Couldn't unwrap Settings URL")
            }

            self.tableView.deselectSelectedRowWithAnimation(true)
        }
    }
}
