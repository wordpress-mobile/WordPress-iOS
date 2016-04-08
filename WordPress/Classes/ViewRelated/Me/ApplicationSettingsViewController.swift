import Foundation
import UIKit
import RxSwift
import WordPressComAnalytics

func ApplicationSettingsViewController() -> ImmuTableViewController {
    let controller = ApplicationSettingsController()
    let viewController = ImmuTableViewController(controller: controller)
    return viewController
}

private struct ApplicationSettingsController: SettingsController {
    let title = NSLocalizedString("App Settings", comment: "App Settings Title");

    var immuTableRows: [ImmuTableRow.Type] {
        return [
            TextRow.self,
            EditableTextRow.self,
            MediaSizeRow.self,
            SwitchRow.self]
    }

    // MARK: - Initialization

    init() {}
    
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

    func editEmailAddress(service: AccountSettingsService) -> ImmuTableRowControllerGenerator {
        let hint = NSLocalizedString("Will not be publicly displayed.", comment: "Help text when editing email address")
        return editEmailAddress(AccountSettingsChange.Email, hint: hint, displaysNavigationButtons: true, service: service)
    }
    
    func editWebAddress(service: AccountSettingsService) -> ImmuTableRowControllerGenerator {
        let hint = NSLocalizedString("Shown publicly when you comment on blogs.", comment: "Help text when editing web address")
        return editText(AccountSettingsChange.WebAddress, hint: hint, displaysNavigationButtons: true, service: service)
    }
    
    func editPrimarySite(settings: AccountSettings?, service: AccountSettingsService) -> ImmuTableRowControllerGenerator {
        return {
            row in

            let selectorViewController = BlogSelectorViewController(selectedBlogDotComID: settings?.primarySiteID,
                successHandler: { (dotComID : NSNumber!) in
                    let change = AccountSettingsChange.PrimarySite(dotComID as Int)
                    service.saveChange(change)
                },
                dismissHandler: nil)

            selectorViewController.title = NSLocalizedString("Primary Site", comment: "Primary Site Picker's Title");
            selectorViewController.displaysOnlyDefaultAccountSites = true
            selectorViewController.displaysCancelButton = true
            selectorViewController.dismissOnCompletion = true
            selectorViewController.dismissOnCancellation = true
            
            return selectorViewController
        }
    }

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

