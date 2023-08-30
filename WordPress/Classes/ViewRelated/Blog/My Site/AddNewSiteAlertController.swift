import SwiftUI
import WordPressAuthenticator

struct AddNewSiteAlertController: UIViewControllerRepresentable {
    let canCreateWPComSite: Bool
    let canAddSelfHostedSite: Bool
    let launchSiteCreation: () -> Void
    let launchLoginForSelfHostedSite: () -> Void

    func makeUIViewController(context: Context) -> UIAlertController {
        let addSiteAlert = AddSiteAlertFactory().makeAddSiteAlert(
            source: "my_site_no_sites",
            canCreateWPComSite: canCreateWPComSite,
            createWPComSite: launchSiteCreation,
            canAddSelfHostedSite: canAddSelfHostedSite,
            addSelfHostedSite: launchLoginForSelfHostedSite
        )
        return addSiteAlert
    }

    func updateUIViewController(_ uiViewController: UIAlertController, context: Context) {}
}
