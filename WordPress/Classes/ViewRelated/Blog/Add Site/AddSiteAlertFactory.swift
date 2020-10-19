import Foundation

/// This class takes care of constructing `AddSiteAlertFactory`.  It does not handle any presentation logic and doe
/// not know any external data sources - all of the data is received as parameters.  The intention behind this class design is
/// to keep the scope very tight and avoid it containing unnecessary logic for the class' purpose.
@objc
class AddSiteAlertFactory: NSObject {

    @objc
    func make(
        style: UIAlertController.Style,
        canCreateWPComSite: Bool,
        createWPComSite: @escaping () -> Void,
        addSelfHostedSite: @escaping () -> Void) -> UIAlertController {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: style)

        if canCreateWPComSite {
            alertController.addAction(createWPComSiteAction(handler: createWPComSite))
        }

        alertController.addAction(addSelfHostedSiteAction(handler: addSelfHostedSite))
        alertController.addAction(cancelAction())

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
