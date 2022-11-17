import Foundation

extension SupportTableViewController {

    struct Configuration {

        let meHeaderConfiguration: MeHeaderView.Configuration?
    }
}

extension SupportTableViewController.Configuration {

    init() {
        self.init(meHeaderConfiguration: nil)
    }

    static func currentAccountConfiguration() -> Self {
        var meHeaderConfiguration: MeHeaderView.Configuration?
        if let account = Self.makeAccount() {
            meHeaderConfiguration = .init(account: account)
        }
        return .init(meHeaderConfiguration: meHeaderConfiguration)
    }

    private static func makeAccount() -> WPAccount? {
        let context = ContextManager.shared.mainContext
        do {
            return try WPAccount.lookupDefaultWordPressComAccount(in: context)
        } catch {
            DDLogError("Account lookup failed with error: \(error)")
            return nil
        }
    }
}
