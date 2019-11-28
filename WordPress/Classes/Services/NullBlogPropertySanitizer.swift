import Foundation

struct NullBlogPropertySanitizer {
    private let store: UserDefaults
    private let key = "null-property-sanitization"

    private let context: NSManagedObjectContext

    init(store: UserDefaults = UserDefaults.standard,
         context: NSManagedObjectContext = ContextManager.shared.mainContext) {

        self.store = store
        self.context = context
    }

    func sanitize() {
        guard appWasUpdated() else {
            return
        }

        context.perform {
            [Post.entityName(),
             Page.entityName(),
             Media.entityName(),
             PostCategory.entityName()].forEach { entityName in
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                let predicate = NSPredicate(format: "blog == NULL")
                request.predicate = predicate

                if let results = try? self.context.fetch(request), !results.isEmpty {
                    results.forEach(self.context.delete)

                    WPAnalytics.track(.debugDeletedOrphanedEntities, withProperties: [
                        "entity_name": entityName,
                        "deleted_count": results.count
                    ])
                }
            }

            try? self.context.save()
        }

        store.set(currentBuildVersion(), forKey: key)
    }

    private func appWasUpdated() -> Bool {
        return store.string(forKey: key) != currentBuildVersion()
    }

    private func currentBuildVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
