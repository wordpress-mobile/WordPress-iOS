import CoreData

class BlogToBlogMigration87to88: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)

        let isGutenbergEnabled = UserDefaults.standard.object(forKey: "kUserDefaultsGutenbergEditorEnabled") as? Bool ?? false
        let editor = isGutenbergEnabled ? "gutenberg" : "aztec"

        dInstance.setValue(editor, forKey: "mobileEditor")
    }

    override func end(_ mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        NotificationCenter.default.observeOnce(forName: .applicationLaunchCompleted, object: nil, queue: .main, using: { (_) in
            let context = ContextManager.shared.mainContext
            let service = EditorSettingsService(managedObjectContext: context)
            service.syncEditorSettingsForAllBlogs()
        })
    }
}
