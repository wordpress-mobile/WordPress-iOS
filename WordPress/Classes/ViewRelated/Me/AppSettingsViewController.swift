import Foundation
import UIKit
import RxSwift
import WordPressComAnalytics

func AppSettingsViewController(account account: WPAccount?) -> ImmuTableViewController {
    return AppSettingsViewController()
}

func AppSettingsViewController() -> ImmuTableViewController {
    let controller = AppSettingsController()
    let viewController = ImmuTableViewController(controller: controller)
    return viewController
}

private struct AppSettingsController: SettingsController {
    let title = NSLocalizedString("App Settings", comment: "App Settings Title");

    var immuTableRows: [ImmuTableRow.Type] {
        return [
            MediaSizeRow.self,
            SwitchRow.self]
    }

    // MARK: - Initialization

    // MARK: - ImmuTableViewController

    func tableViewModelWithPresenter(presenter: ImmuTablePresenter) -> Observable<ImmuTable> {
        return Observable.just(self.mapViewModel(nil, service: nil, presenter: presenter))
    }

    var errorMessage: Observable<String?> {
        return Observable.just(nil)
    }

    // MARK: - Model mapping

    func mapViewModel(settings: AccountSettings?, service: AccountSettingsService?, presenter: ImmuTablePresenter) -> ImmuTable {
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

        let editorHeader = NSLocalizedString("Editor", comment: "Title label for the editor settings section in the app settings")
        let visualEditor = SwitchRow(
            title: NSLocalizedString("Visual Editor", comment: "Option to enable the visual editor"),
            value: WPPostViewController.isNewEditorEnabled(),
            onChange: visualEditorChanged()
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
                rows: [
                    visualEditor
                ],
                footerText: nil)
            ])
    }
    
    
    // MARK: - Actions

    func mediaSizeChanged() -> Int -> Void {
        return {
            value in
            MediaSettings().maxImageSizeSetting = value
        }
    }

    func mediaRemoveLocationChanged() -> Bool -> Void {
        return {
            value in
            MediaSettings().removeLocationSetting = value
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

