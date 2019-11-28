import Foundation

/// Delete invalid rows in the database whose required blog properties are NULL
///
/// This is born from the investigation of the crash described in #12028 (https://git.io/JePdZ).
/// Unfortunately, we could not find the cause of it. The findings are described in that issue.
///
/// This tries to “fix” the issue by deleting the orphaned entities like `Post` whose `blog` were
/// set to NULL. They are currently inaccessible because they are not attached to any `Blog`. But
/// leaving them in the database would cause a crash if Core Data tries to save new entities.
///
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

        let entityNamesWithRequiredBlogProperties = [
            Post.entityName(),
            Page.entityName(),
            Media.entityName(),
            PostCategory.entityName()
        ]

        context.perform {
            entityNamesWithRequiredBlogProperties.forEach { entityName in
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
