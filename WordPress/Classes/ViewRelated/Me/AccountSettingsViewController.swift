import Foundation
import UIKit
import RxSwift
import WordPressComAnalytics

func AccountSettingsViewController(account account: WPAccount?) -> ImmuTableViewController {
    let service = account.map({ account in
        return AccountSettingsService(userID: account.userID.integerValue, api: account.restApi)
    })
    return AccountSettingsViewController(service: service)
}

func AccountSettingsViewController(service service: AccountSettingsService?) -> ImmuTableViewController {
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

    let service: AccountSettingsService?

    init(service: AccountSettingsService?) {
        self.service = service
    }
    
    // MARK: - ImmuTableViewController

    func tableViewModelWithPresenter(presenter: ImmuTablePresenter) -> Observable<ImmuTable> {
        if let service = self.service {
            return service.settings.map({ settings in
                self.mapViewModel(settings, service: service, presenter: presenter)
            })
        } else {
            return Observable.just(self.mapViewModel(nil, service: nil, presenter: presenter))
        }
    }

    var errorMessage: Observable<String?> {
        if let service = self.service {
            return service.refresh
                // replace errors with .Failed status
                .catchErrorJustReturn(.Failed)
                // convert status to string
                .map({ $0.errorMessage })
        } else {
            return Observable.just(nil)
        }
    }

    // MARK: - Model mapping

    func mapViewModel(settings: AccountSettings?, service: AccountSettingsService?, presenter: ImmuTablePresenter) -> ImmuTable {
        let mediaHeader = NSLocalizedString("Media", comment: "Title label for the media settings section in the app settings")
        let uploadSize = MediaSizeRow(
            title: NSLocalizedString("Max Image Upload Size", comment: "Title for the image size settings option."),
            value: Int(MediaSettings().maxImageSizeSetting),
            onChange: mediaSizeChanged())

        let editorHeader = NSLocalizedString("Editor", comment: "Title label for the editor settings section in the app settings")
        let visualEditor = SwitchRow(
            title: NSLocalizedString("Visual Editor", comment: "Option to enable the visual editor"),
            value: WPPostViewController.isNewEditorEnabled(),
            onChange: visualEditorChanged()
        )

        if Feature.enabled(.AccountSettings), let service = service {
            let primarySiteName = settings.flatMap { service.primarySiteNameForSettings($0) }
            
            let username = TextRow(
                title: NSLocalizedString("Username", comment: "Account Settings Username label"),
                value: settings?.username ?? "")
            
            let email = TextRow(
                title: NSLocalizedString("Email", comment: "Account Settings Email label"),
                value: settings?.email ?? "")
            
            let primarySite = EditableTextRow(
                title: NSLocalizedString("Primary Site", comment: "Primary Web Site"),
                value: primarySiteName ?? "",
                action: presenter.push(editPrimarySite(settings, service: service))
            )
            
            let webAddress = EditableTextRow(
                title: NSLocalizedString("Web Address", comment: "Account Settings Web Address label"),
                value: settings?.webAddress ?? "",
                action: presenter.push(editWebAddress(service))
            )
            
            return ImmuTable(sections: [
                ImmuTableSection(
                    rows: [
                        username,
                        email,
                        primarySite,
                        webAddress
                    ]),
                ImmuTableSection(
                    headerText: mediaHeader,
                    rows: [
                        uploadSize
                    ],
                    footerText: nil),
                ImmuTableSection(
                    headerText: editorHeader,
                    rows: [
                        visualEditor
                    ],
                    footerText: nil)
                ])
        } else {
            return ImmuTable(sections: [
                ImmuTableSection(
                    headerText: mediaHeader,
                    rows: [
                        uploadSize
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
    }
    
    
    // MARK: - Actions

    func editWebAddress(service: AccountSettingsService) -> ImmuTableRowControllerGenerator {
        return editText(AccountSettingsChange.WebAddress, hint: NSLocalizedString("Shown publicly when you comment on blogs.", comment: "Help text when editing web address"), service: service)
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
            selectorViewController.displaysCancelButton = false
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

