import Foundation

extension AccountService {

    func mergeDuplicatesIfNecessary() {
        let accounts = allAccounts()
        guard accounts.count > 1 else {
            return
        }

        let accountGroups = Dictionary(grouping: accounts) { $0.userID }
        for key in accountGroups.keys {
            guard let group = accountGroups[key], group.count > 1 else {
                continue
            }
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

        for account in accounts {
            if account == destination {
                continue
            }
            mergeAccount(account: account, into: destination)
        }

        let service = BlogService(managedObjectContext: managedObjectContext)
        service.deduplicateBlogs(for: destination)
    }

    private func mergeAccount(account: WPAccount, into destination: WPAccount) {
        // Move all blogs to the destination account
        destination.addBlogs(account.blogs)
        account.removeBlogs(account.blogs)
        managedObjectContext.delete(account)
    }

}
