import Foundation
import UIKit
import RxSwift
import WordPressComAnalytics

func AccountSettingsViewController(account account: WPAccount) -> ImmuTableViewController {
    let service = AccountSettingsService(userID: account.userID.integerValue, api: account.restApi)
    return AccountSettingsViewController(service: service)
}

func AccountSettingsViewController(service service: AccountSettingsService) -> ImmuTableViewController {
    let controller = AccountSettingsController(service: service)
    let viewController = ImmuTableViewController(controller: controller)
    return viewController
}

private struct AccountSettingsController: SettingsController {
    let title = NSLocalizedString("Account Settings", comment: "Account Settings Title");

    var immuTableRows: [ImmuTableRow.Type] {
        return [
            TextRow.self,
            EditableTextRow.self,
            MediaSizeRow.self,
            SwitchRow.self]
    }

    // MARK: - Initialization

    let service: AccountSettingsService

    init(service: AccountSettingsService) {
        self.service = service
    }
    
    // MARK: - Model mapping

    func mapViewModel(settings: AccountSettings?, presenter: ImmuTablePresenter) -> ImmuTable {
        let username = TextRow(
            title: NSLocalizedString("Username", comment: "Account Settings Username label"),
            value: settings?.username ?? "")

        let email = TextRow(
            title: NSLocalizedString("Email", comment: "Account Settings Email label"),
            value: settings?.email ?? "")

        let webAddress = EditableTextRow(
            title: NSLocalizedString("Web Address", comment: "Account Settings Web Address label"),
            value: settings?.webAddress ?? "",
            action: presenter.push(editWebAddress())
        )

        let uploadSize = MediaSizeRow(
            title: NSLocalizedString("Max Image Upload Size", comment: "Title for the image size settings option."),
            value: Int(MediaSettings().maxImageSizeSetting),
            onChange: mediaSizeChanged())

        let visualEditor = SwitchRow(
            title: NSLocalizedString("Visual Editor", comment: "Option to enable the visual editor"),
            value: WPPostViewController.isNewEditorEnabled(),
            onChange: visualEditorChanged()
        )

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                    username,
                    email,
                    webAddress
                ]),
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

    // MARK: - Actions

    func editWebAddress() -> ImmuTableRowControllerGenerator {
        return editText(AccountSettingsChange.WebAddress, hint: NSLocalizedString("Shown publicly when you comment on blogs.", comment: "Help text when editing web address"))
    }

    func mediaSizeChanged() -> Int -> Void {
        return {
            value in
            MediaSettings().maxImageSizeSetting = value
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

