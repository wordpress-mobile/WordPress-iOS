import Foundation

struct SupportTableViewControllerConfiguration {

    // MARK: Properties

    var meHeaderConfiguration: MeHeaderView.Configuration?
    var showsLogOutButton: Bool = false
    var showsLogsSection: Bool = true

    // MARK: Default Configurations

    static func currentAccountConfiguration() -> Self {
        var config = Self.init()
        if let account = Self.makeAccount() {
            config.meHeaderConfiguration = .init(account: account)
            config.showsLogOutButton = true
            config.showsLogsSection = false
        }
        return config
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

extension SupportTableViewController {

    typealias Configuration = SupportTableViewControllerConfiguration
}
