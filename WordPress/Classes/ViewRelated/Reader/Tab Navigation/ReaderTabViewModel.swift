
class ReaderTabViewModel {

    // TODO: - READERNAV - Methods to be implemented. Signature will likely change
    func navigateToTab(at index: Int) { }

    func performSearch() { }

    func presentFilter() { }

    func resetFilter() { }

    func presentSettings() { }
}


// MARK: - Tab Bar
extension ReaderTabViewModel {

    /// Fetch request to extract reader menu topics from Core Data
    private var topicsFetchRequest: NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderAbstractTopic")

        fetchRequest.predicate = NSPredicate(format: "following == %@ AND showInMenu == YES AND type == 'default' OR type == 'list' OR type == 'team'",
                                             NSNumber(value: ReaderHelpers.isLoggedIn()))

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "type", ascending: true)]
        return fetchRequest
    }

    /// Fetches topics from Core Data populates tab bar items accordingly and passes them to the completion closure
    /// - Parameter completion: completion closure: will be passed an array of ReaderTabItem or nil, if the request fails
    private func fetchTabBarItems(completion: @escaping ([ReaderTabItem]?) -> Void) {
        do {
            guard let topics = try ContextManager.sharedInstance().mainContext.fetch(topicsFetchRequest) as? [ReaderAbstractTopic] else {
                return
            }

            let tabItems = topics.map { ReaderTabItem(topic: $0) }
            completion(ReaderHelpers.rearrange(items: tabItems))

        } catch {
            DDLogError("There was a problem fetching topics for the menu." + error.localizedDescription)
            completion(nil)
        }
    }

    /// Fetches the menu from the designated service and passes it to the completion closure
    /// - Parameter completion: completion closure: will be passed an array of ReaderTabItem or nil, if the request fails
    func fetchReaderMenu(completion: @escaping ([ReaderTabItem]?) -> Void) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        service.fetchReaderMenu(success: { [weak self] in
            self?.fetchTabBarItems(completion: completion)
            }, failure: { error in
                DDLogError("Error syncing menu: \(String(describing: error))")
                completion(nil)
        })
    }
}
