import Foundation
import UIKit

/// This class takes care of constructing our "Add Site" action sheets.  It does not handle any presentation logic and does
/// not know any external data sources - all of the data is received as parameters.
@objc
class AddSiteAlertFactory: NSObject {

    @objc
    func makeAddSiteAlert(
        source: String?,
        canCreateWPComSite: Bool,
        createWPComSite: @escaping () -> Void,
        canAddSelfHostedSite: Bool,
        addSelfHostedSite: @escaping () -> Void) -> UIAlertController {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if canCreateWPComSite {
            alertController.addAction(createWPComSiteAction(handler: createWPComSite))
        }

        if canAddSelfHostedSite {
            alertController.addAction(addSelfHostedSiteAction(handler: addSelfHostedSite))
        }

        alertController.addAction(cancelAction())

        WPAnalytics.track(.addSiteAlertDisplayed, properties: ["source": source ?? "unknown"])

        return alertController
    }

    // MARK: - Alert Action Definitions

    private func addSelfHostedSiteAction(handler: @escaping () -> Void) -> UIAlertAction {
        return UIAlertAction(
            title: Strings.addSelfHostedSite,
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
            title: Strings.createDotComSite,
            style: .default,
            handler: { _ in
                handler()
            })
    }
}

struct AddSiteAlertViewModel {
    let actions: [Action]

    enum Selection: String {
        case dotCom
        case selfHosted
    }

    struct Action: Identifiable {
        let id = UUID()
        let title: String
        let handler: () -> Void
    }

    init(context: ContextManager = .shared, onSelection: @escaping (Selection) -> Void) {
        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: context.mainContext)
        let canAddSelfHostedSite = AppConfiguration.showAddSelfHostedSiteButton

        var actions: [Action] = []
        if defaultAccount != nil {
            actions.append(Action(title: Strings.createDotComSite) {
                onSelection(.dotCom)
            })
        }

        if canAddSelfHostedSite {
            actions.append(Action(title: Strings.addSelfHostedSite) {
                onSelection(.selfHosted)
            })
        }

        self.actions = actions
    }
}

private enum Strings {
    static let createDotComSite = NSLocalizedString("button.createDotCoSite", value: "Create WordPress.com site", comment: "Create WordPress.com site button")
    static let addSelfHostedSite = NSLocalizedString("button.addSelfHostedSite", value: "Add self-hosted site", comment: "Add self-hosted site button")
}
