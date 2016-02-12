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

    let context: NSManagedObjectContext
    
    
    init(service: AccountSettingsService) {
        self.service = service
        self.context = ContextManager.sharedInstance().mainContext
    }
    
    // MARK: - Model mapping

    func mapViewModel(settings: AccountSettings?, presenter: ImmuTablePresenter) -> ImmuTable {
        let mainBlog = blogWithBlogId(settings?.primarySiteID)
        
        let username = TextRow(
            title: NSLocalizedString("Username", comment: "Account Settings Username label"),
            value: settings?.username ?? "")

        let email = TextRow(
            title: NSLocalizedString("Email", comment: "Account Settings Email label"),
            value: settings?.email ?? "")
        
        let primarySite = EditableTextRow(
            title: NSLocalizedString("Primary Site", comment: "Primary Web Site"),
            value: mainBlog?.settings?.name ?? String(),
            action: presenter.push(editPrimarySite(mainBlog))
        )

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
                    primarySite,
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

    
    // MARK: - Helpers
    
    func blogWithBlogId(blogId: Int?) -> Blog? {
        let service = BlogService(managedObjectContext: context)
        return service.blogByBlogId(blogId)
    }
    
    func updatePrimarySite(primarySiteObjectId: NSManagedObjectID) {
        guard let newPrimarySite = try! context.existingObjectWithID(primarySiteObjectId) as? Blog else {
            return
        }
        let change = AccountSettingsChange.PrimarySite(newPrimarySite.dotComID as Int)
        self.service.saveChange(change)
    }
    
    
    // MARK: - Actions

    func editWebAddress() -> ImmuTableRowControllerGenerator {
        return editText(AccountSettingsChange.WebAddress, hint: NSLocalizedString("Shown publicly when you comment on blogs.", comment: "Help text when editing web address"))
    }
    
    func editPrimarySite(primarySite: Blog?) -> ImmuTableRowControllerGenerator {
        return {
            row in

            let selectorViewController = BlogSelectorViewController(selectedBlogObjectID: primarySite?.objectID,
                selectedCompletion: { self.updatePrimarySite($0) },
                cancelCompletion: nil)

            selectorViewController.title = NSLocalizedString("Primary Site", comment: "Primary Site Picker's Title");
            selectorViewController.displaysCancelButton = false
            selectorViewController.dismissOnCompletion = true
            
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

