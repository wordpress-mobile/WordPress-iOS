import Foundation

extension AccountService {

    func mergeDuplicatesIfNecessary() {
        guard numberOfAccounts() > 1 else {
            return
        }

        let accounts = allAccounts()
        let accountGroups = Dictionary(grouping: accounts) { $0.userID }
        for group in accountGroups.values where group.count > 1 {
            mergeDuplicateAccounts(accounts: group)
        }

        if managedObjectContext.hasChanges {
            ContextManager.sharedInstance().save(managedObjectContext)
        }
    }

    private func mergeDuplicateAccounts(accounts: [WPAccount]) {
        // For paranoia
        guard accounts.count > 1 else {
            return
        }

        // If one of the accounts is the default account, merge the rest into it.
        // Otherwise just use the first account.
        var destination = accounts.first!
        if let defaultAccount = defaultWordPressComAccount(), accounts.contains(defaultAccount) {
            destination = defaultAccount
        }

        for account in accounts where account != destination {
            mergeAccount(account: account, into: destination)
        }

        let service = BlogService(managedObjectContext: managedObjectContext)
        service.deduplicateBlogs(for: destination)
    }

    private func mergeAccount(account: WPAccount, into destination: WPAccount) {
        // Move all blogs to the destination account
        destination.addBlogs(account.blogs)
        managedObjectContext.delete(account)
    }

}
