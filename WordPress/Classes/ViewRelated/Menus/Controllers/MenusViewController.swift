import Foundation

extension MenusViewController {

    /// Fetch all pages from the site.
    ///
    /// - Returns: A block that can be used to cancel the fetching.
    @objc func fetchAllPages(success: @escaping ([MenuItem]) -> Void, failure: @escaping (Error) -> Void) -> () -> Void {
        let coreDataStack = ContextManager.shared
        let repository = PostRepository(coreDataStack: coreDataStack)
        let fetchAllPagesTask = repository.fetchAllPages(statuses: [.publish], in: TaggedManagedObjectID(blog))

        // Wait for the fetching all pages task to complete and pass its result to the success or failure block.
        Task { [weak self] in
            let allPages: [TaggedManagedObjectID<Page>]
            do {
                allPages = try await fetchAllPagesTask.value
            } catch {
                failure(error)
                return
            }

            guard let menusService = self?.menusService else { return }

            await menusService.managedObjectContext.perform {
                let items = allPages.compactMap {
                    menusService.createItem(withPageID: $0.objectID, in: menusService.managedObjectContext)
                }
                success(items)
            }
        }

        return fetchAllPagesTask.cancel
    }

}
