import Foundation
import UIKit
import WordPressShared
import WordPressComAnalytics

class SettingsViewController: UITableViewController {
    var handler: ImmuTableViewHandler!

    required convenience init() {
        self.init(style: .Grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Settings", comment: "App Settings");

        ImmuTable.registerRows([
            MediaSizeRow.self,
            SwitchRow.self
            ], tableView: self.tableView)
        handler = ImmuTableViewHandler(takeOver: self)

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        buildViewModel()
    }

    func buildViewModel() {
        let uploadSize = MediaSizeRow(
            title: NSLocalizedString("Max Image Upload Size", comment: "Title for the image size settings option."),
            value: Int(MediaService.maxImageSizeSetting().width),
            onChange: mediaSizeChanged())

        let visualEditor = SwitchRow(
            title: NSLocalizedString("Visual Editor", comment: "Option to enable the visual editor"),
            value: WPPostViewController.isNewEditorEnabled(),
            onChange: visualEditorChanged()
        )

        handler.viewModel = ImmuTable(sections: [
            ImmuTableSection(
                headerText: NSLocalizedString("Media", comment: "Title label for the media settings section in the app settings"),
                rows: [
                    uploadSize
                ],
                footerText: nil),
            ImmuTableSection(
                headerText: NSLocalizedString("Editor", comment: "Title label for the editor settings section in the app settings"),
                rows: [
                    visualEditor
                ],
                footerText: nil)
            ])
    }

    func mediaSizeChanged() -> Int -> Void {
        return {
            value in
            let size = CGSize(width: value, height: value)
            MediaService.setMaxImageSizeSetting(size)
        }
    }

    func visualEditorChanged() -> Bool -> Void {
        return {
            enabled in
            if enabled {
                WPAnalytics.track(.EditorToggledOn)
            } else {
                WPAnalytics.track(.EditorToggledOff)
            }
            WPPostViewController.setNewEditorEnabled(enabled)
        }
    }
}

