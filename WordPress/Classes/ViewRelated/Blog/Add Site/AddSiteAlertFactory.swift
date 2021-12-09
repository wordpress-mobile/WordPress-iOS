import Foundation

/// This class takes care of constructing our "Add Site" action sheets.  It does not handle any presentation logic and does
/// not know any external data sources - all of the data is received as parameters.
@objc
class AddSiteAlertFactory: NSObject {

    @objc
    func makeAddSiteAlert(
        source: String?,
        canCreateWPComSite: Bool,
        createWPComSite: @escaping () -> Void,
        addSelfHostedSite: @escaping () -> Void) -> UIAlertController {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if canCreateWPComSite {
            alertController.addAction(createWPComSiteAction(handler: createWPComSite))
        }

        alertController.addAction(addSelfHostedSiteAction(handler: addSelfHostedSite))
        alertController.addAction(cancelAction())

        WPAnalytics.track(.addSiteAlertDisplayed, properties: ["source": source ?? "unknown"])

        return alertController
    }

    // MARK: - Alert Action Definitions

    private func addSelfHostedSiteAction(handler: @escaping () -> Void) -> UIAlertAction {
        return UIAlertAction(
            title: NSLocalizedString("Add self-hosted site", comment: "Add self-hosted site button"),
            style: .default,
            handler: { _ in
                handler()
            })
    }

    private func cancelAction() -> UIAlertAction {
        return UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel button"),
            style: .cancel)
    }

    private func createWPComSiteAction(handler: @escaping () -> Void) -> UIAlertAction {
        return UIAlertAction(
            title: NSLocalizedString("Create WordPress.com site", comment: "Create WordPress.com site button"),
            style: .default,
            handler: { _ in
                handler()
            })
    }
}
