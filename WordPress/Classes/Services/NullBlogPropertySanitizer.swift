import Foundation

struct NullBlogPropertySanitizer {
    private let store: UserDefaults
    private let key = "null-property-sanitization"

    init(store: UserDefaults = UserDefaults.standard) {
        self.store = store
    }

    func sanitize() {
        if appWasUpdated() {
            let context = ContextManager.shared.mainContext
            context.perform {
                [Post.entityName(),
                 Page.entityName(),
                 Media.entityName(),
                 PostCategory.entityName()].forEach { entityName in
                    let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                    let predicate = NSPredicate(format: "blog == NULL")
                    request.predicate = predicate

                    if let results = try? context.fetch(request), !results.isEmpty {
                        results.forEach(context.delete)

                        WPAnalytics.track(.debugDeletedOrphanedEntities, withProperties: [
                            "entity_name": entityName,
                            "deleted_count": results.count
                        ])
                    }
                }
                try? context.save()
            }

            store.set(currentBuildVersion(), forKey: key)
        }
    }

    private func appWasUpdated() -> Bool {
        return store.string(forKey: key) != currentBuildVersion()
    }

    private func currentBuildVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
