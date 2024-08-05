import Foundation
import UIKit

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
