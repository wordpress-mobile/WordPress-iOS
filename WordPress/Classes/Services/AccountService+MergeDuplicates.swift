import Foundation

extension AccountService {

    func mergeDuplicatesIfNecessary() {
        coreDataStack.performAndSave { context in
            guard let count = try? WPAccount.lookupNumberOfAccounts(in: context), count > 1 else {
                return
            }

            let accounts = (try? WPAccount.lookupAllAccounts(in: context)) ?? []
            let accountGroups = Dictionary(grouping: accounts) { $0.userID }
            for group in accountGroups.values where group.count > 1 {
                self.mergeDuplicateAccounts(accounts: group, in: context)
            }
        }
    }

    private func mergeDuplicateAccounts(accounts: [WPAccount], in context: NSManagedObjectContext) {
        // For paranoia
        guard accounts.count > 1 else {
            return
        }

        // If one of the accounts is the default account, merge the rest into it.
        // Otherwise just use the first account.
        var destination = accounts.first!
        if let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: context), accounts.contains(defaultAccount) {
            destination = defaultAccount
        }

        for account in accounts where account != destination {
            mergeAccount(account: account, into: destination, in: context)
        }

        let service = BlogService(managedObjectContext: context)
        service.deduplicateBlogs(for: destination)
    }

    private func mergeAccount(account: WPAccount, into destination: WPAccount, in context: NSManagedObjectContext) {
        // Move all blogs to the destination account
        destination.addBlogs(account.blogs)
        context.deleteObject(account)
    }

}
