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
            EditableTextRow.self
        ]
    }

    // MARK: - Initialization

    let service: AccountSettingsService

    init(service: AccountSettingsService) {
        self.service = service
    }
    
    // MARK: - ImmuTableViewController

    func tableViewModelWithPresenter(presenter: ImmuTablePresenter) -> Observable<ImmuTable> {
        return service.settings.map({ settings in
            self.mapViewModel(settings, service: self.service, presenter: presenter)
        })
    }

    var errorMessage: Observable<String?> {
        return service.refresh
            // replace errors with .Failed status
            .catchErrorJustReturn(.Failed)
            // convert status to string
            .map({ $0.errorMessage })
    }

    // MARK: - Model mapping

    func mapViewModel(settings: AccountSettings?, service: AccountSettingsService, presenter: ImmuTablePresenter) -> ImmuTable {
        let primarySiteName = settings.flatMap { service.primarySiteNameForSettings($0) }
        
        let username = TextRow(
            title: NSLocalizedString("Username", comment: "Account Settings Username label"),
            value: settings?.username ?? "")
        
        let email = EditableTextRow(
            title: NSLocalizedString("Email", comment: "Account Settings Email label"),
            value: settings?.email ?? "",
            action: presenter.present(insideNavigationController(editEmailAddress(service)))
        )
        
        let primarySite = EditableTextRow(
            title: NSLocalizedString("Primary Site", comment: "Primary Web Site"),
            value: primarySiteName ?? "",
            action: presenter.present(insideNavigationController(editPrimarySite(settings, service: service)))
        )
        
        let webAddress = EditableTextRow(
            title: NSLocalizedString("Web Address", comment: "Account Settings Web Address label"),
            value: settings?.webAddress ?? "",
            action: presenter.present(insideNavigationController(editWebAddress(service)))
        )
        
        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                    username,
                    email,
                    primarySite,
                    webAddress
                ])
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
}

