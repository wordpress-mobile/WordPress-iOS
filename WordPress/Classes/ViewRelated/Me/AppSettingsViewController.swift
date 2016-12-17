import Foundation
import UIKit
import WordPressShared
import WordPressComAnalytics

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
            MediaSizeRow.self,
            SwitchRow.self,
            NavigationItemRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        handler.viewModel = tableViewModel()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
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

        let editorSettings = EditorSettings()
        let editorHeader = NSLocalizedString("Editor", comment: "Title label for the editor settings section in the app settings")
        var editorRows = [ImmuTableRow]()
        let visualEditor = SwitchRow(
            title: NSLocalizedString("Visual Editor", comment: "Option to enable the visual editor"),
            value: editorSettings.visualEditorEnabled,
            onChange: visualEditorChanged()
        )
        editorRows.append(visualEditor)

        if FeatureFlag.nativeEditor.enabled && editorSettings.visualEditorEnabled {
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
                    mediaRemoveLocation
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
        return { enabled in
            if enabled {
                WPAnalytics.track(.editorToggledOn)
            } else {
                WPAnalytics.track(.editorToggledOff)
            }
            EditorSettings().visualEditorEnabled = enabled
            self.handler.viewModel = self.tableViewModel()
        }
    }

    func nativeEditorChanged() -> (Bool) -> Void {
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
            if let targetURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(targetURL)
            } else {
                assertionFailure("Couldn't unwrap Settings URL")
            }

            self.tableView.deselectSelectedRowWithAnimation(true)
        }
    }
}
